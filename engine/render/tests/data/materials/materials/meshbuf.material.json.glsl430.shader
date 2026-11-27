{
  "format": "factoria.shader/1",
  "engine": "0.38.0",
  "template": "4f7d190a643df7eea422f9bce37d2bb8920145f92f7e586baf62c54f579868ea",
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
      "fs": "#version 430\n\nstruct SurfaceInput\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 vertex_color;\n    vec3 view_dir;\n    bool front_facing;\n};\n\nstruct LightSample\n{\n    vec3 direction;\n    vec3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct Surface\n{\n    vec3 albedo;\n    float alpha;\n    vec3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    vec3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    vec3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    vec3 specular_color;\n    float transmission;\n    float thickness;\n    vec3 attenuation_color;\n    float attenuation_distance;\n};\n\nstruct FaLayers\n{\n    bool on;\n    float f90;\n    float keep;\n    float base_scale;\n    float coat;\n    float coat_rough;\n    float coat_alpha;\n    float coat_a2;\n    vec3 nc;\n    float coat_ndv;\n    bool sheen_on;\n    vec3 sheen;\n    float sheen_rough;\n    float sheen_alpha;\n    float sheen_scale;\n    float sheen_e;\n    float aniso;\n    vec3 t;\n    vec3 b;\n    float at;\n    float ab;\n};\n\nconst float _4816[63] = float[](1.0, 1.0, 1.0, 0.4790000021457672119140625, 0.11699999868869781494140625, 0.01200000010430812835693359375, 0.0, 0.0, 0.0, 1.0, 1.0, 1.0, 0.578000009059906005859375, 0.19300000369548797607421875, 0.0350000001490116119384765625, 0.0030000000260770320892333984375, 0.0, 0.0, 1.0, 1.0, 1.0, 0.6740000247955322265625, 0.3459999859333038330078125, 0.1319999992847442626953125, 0.032999999821186065673828125, 0.0040000001899898052215576171875, 0.0, 0.971000015735626220703125, 0.954999983310699462890625, 0.828999996185302734375, 0.63999998569488525390625, 0.42599999904632568359375, 0.24500000476837158203125, 0.115000002086162567138671875, 0.037000000476837158203125, 0.0030000000260770320892333984375, 0.7469999790191650390625, 0.737999975681304931640625, 0.670000016689300537109375, 0.563000023365020751953125, 0.4309999942779541015625, 0.3039999902248382568359375, 0.1940000057220458984375, 0.1019999980926513671875, 0.0309999994933605194091796875, 0.614000022411346435546875, 0.609000027179718017578125, 0.566999971866607666015625, 0.499000012874603271484375, 0.412000000476837158203125, 0.32400000095367431640625, 0.240999996662139892578125, 0.162000000476837158203125, 0.087999999523162841796875, 0.538999974727630615234375, 0.535000026226043701171875, 0.505999982357025146484375, 0.4569999873638153076171875, 0.393999993801116943359375, 0.328999996185302734375, 0.2660000026226043701171875, 0.203999996185302734375, 0.14200000464916229248046875);\n\nstruct points_item\n{\n    vec4 pos;\n    vec4 tint;\n};\n\nuniform vec4 fa_mesh_fs_params[54];\nuniform vec4 fa_shadows[30];\nlayout(binding = 1, std430) readonly buffer fa_points_buf\n{\n    points_item data[];\n} points;\n\nlayout(binding = 0) uniform sampler2D fa_light_tex_fa_shadow_smp;\nlayout(binding = 1) uniform sampler2D fa_tex_fa_smp;\nlayout(binding = 2) uniform sampler2D fa_normal_tex_fa_smp;\nlayout(binding = 3) uniform sampler2D fa_mr_tex_fa_smp;\nlayout(binding = 4) uniform sampler2D fa_occlusion_tex_fa_smp;\nlayout(binding = 5) uniform sampler2D fa_emissive_tex_fa_smp;\nlayout(binding = 6) uniform sampler2D fa_decal_tex_fa_env_smp;\nlayout(binding = 7) uniform sampler2D fa_lightmap_fa_env_smp;\nlayout(binding = 8) uniform sampler2D fa_probe_atlas_fa_env_smp;\nlayout(binding = 9) uniform sampler2D fa_light_atlas_fa_env_smp;\nlayout(binding = 10) uniform sampler2D fa_screen_tex_fa_shadow_smp;\nlayout(binding = 11) uniform sampler2D fa_shadow_tex_fa_shadow_smp;\n\nlayout(location = 0) in vec3 fa_world_pos;\nlayout(location = 5) in vec3 fa_lm;\nlayout(location = 1) in vec3 fa_world_normal;\nlayout(location = 2) in vec4 fa_world_tangent;\nlayout(location = 3) in vec2 fa_uv;\nlayout(location = 4) in vec4 fa_vertex_color;\nlayout(location = 0) out vec4 fa_frag_color;\nfloat fa_rt_slope;\nvec3 fa_light_tint;\nbool fa_light_is_area;\nint fa_cl_ndir;\nint fa_cl_slot;\nint fa_cl_local;\n\nvoid fa_inst_load()\n{\n}\n\nvec4 fa_light_texel(int t)\n{\n    return texelFetch(fa_light_tex_fa_shadow_smp, ivec2(t & 1023, t >> 10), 0);\n}\n\nvec4 fa_cluster_texel(vec3 world_pos)\n{\n    bool _1597 = fa_mesh_fs_params[19].x < 0.0;\n    bool _1604;\n    if (!_1597)\n    {\n        _1604 = fa_mesh_fs_params[19].w < 1.0;\n    }\n    else\n    {\n        _1604 = _1597;\n    }\n    bool _1612;\n    if (!_1604)\n    {\n        _1612 = fa_mesh_fs_params[18].x < 1.0;\n    }\n    else\n    {\n        _1612 = _1604;\n    }\n    bool _1619;\n    if (!_1612)\n    {\n        _1619 = fa_mesh_fs_params[18].y < 1.0;\n    }\n    else\n    {\n        _1619 = _1612;\n    }\n    bool _1626;\n    if (!_1619)\n    {\n        _1626 = fa_mesh_fs_params[19].y < 1.0;\n    }\n    else\n    {\n        _1626 = _1619;\n    }\n    if (_1626)\n    {\n        return vec4(0.0);\n    }\n    vec4 _1636 = vec4(world_pos, 1.0);\n    float _1642 = dot(fa_mesh_fs_params[16], _1636);\n    if (!(_1642 > 9.9999999747524270787835121154785e-07))\n    {\n        return vec4(0.0);\n    }\n    vec2 _1664 = vec2(dot(fa_mesh_fs_params[14], _1636), dot(fa_mesh_fs_params[15], _1636)) / vec2(_1642);\n    int _1668 = int(fa_mesh_fs_params[18].x);\n    int _1672 = int(fa_mesh_fs_params[18].y);\n    int param = (int(fa_mesh_fs_params[19].x) + (((clamp(int(floor(log2(max(dot(fa_mesh_fs_params[17].xyz, world_pos) + fa_mesh_fs_params[17].w, fa_mesh_fs_params[18].w) / fa_mesh_fs_params[18].w) * fa_mesh_fs_params[18].z)), 0, int(fa_mesh_fs_params[19].y) - 1) * _1672) + clamp(int(floor(((_1664.y * 0.5) + 0.5) * fa_mesh_fs_params[18].y)), 0, _1672 - 1)) * _1668)) + clamp(int(floor(((_1664.x * 0.5) + 0.5) * fa_mesh_fs_params[18].x)), 0, _1668 - 1);\n    return fa_light_texel(param);\n}\n\nivec2 fa_cluster_lookup(vec3 world_pos)\n{\n    vec3 param = world_pos;\n    vec4 _1748 = fa_cluster_texel(param);\n    return ivec2(int(_1748.x), int(_1748.y));\n}\n\nvoid fa_cluster_begin(vec3 world_pos)\n{\n    float _6450 = dot(fa_mesh_fs_params[29].xyz, world_pos) + fa_mesh_fs_params[29].w;\n    float _6453 = fwidth(_6450);\n    bool _6456 = fa_mesh_fs_params[25].y > 0.5;\n    bool _6463;\n    if (!_6456)\n    {\n        _6463 = fa_mesh_fs_params[25].w > 0.5;\n    }\n    else\n    {\n        _6463 = _6456;\n    }\n    if (_6463)\n    {\n        fa_rt_slope = min(1.5 * _6453, 0.100000001490116119384765625 * _6450);\n    }\n    fa_cl_ndir = int(fa_mesh_fs_params[19].z);\n    vec3 param = world_pos;\n    ivec2 _6479 = fa_cluster_lookup(param);\n    fa_cl_slot = _6479.x;\n    fa_cl_local = _6479.y;\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nvec3 fa_linear_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_tex_fix(inout vec3 c, float mode)\n{\n    if (mode > 1.5)\n    {\n        vec3 param = c;\n        vec3 _7653 = fa_linear_to_srgb(param);\n        c = _7653;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            vec3 param_1 = c;\n            vec3 _7661 = fa_srgb_to_linear(param_1);\n            c = _7661;\n        }\n    }\n    return c;\n}\n\nvec3 fa_tangent_normal(SurfaceInput i, vec3 m)\n{\n    vec3 _542;\n    if (i.front_facing)\n    {\n        _542 = i.world_normal;\n    }\n    else\n    {\n        _542 = -i.world_normal;\n    }\n    vec3 _566 = normalize(i.world_tangent.xyz - (_542 * dot(_542, i.world_tangent.xyz)));\n    vec3 _593 = normalize(((_566 * m.x) + ((cross(_542, _566) * i.world_tangent.w) * m.y)) + (_542 * m.z));\n    vec3 _596;\n    if (i.front_facing)\n    {\n        _596 = _593;\n    }\n    else\n    {\n        _596 = -_593;\n    }\n    return _596;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    vec4 base_t = texture(fa_tex_fa_smp, i.uv, fa_mesh_fs_params[12].w);\n    float param = fa_mesh_fs_params[6].w;\n    float param_1 = 1.0;\n    vec3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    vec3 _7693 = fa_tex_fix(param_2, param_3);\n    vec4 _10064 = base_t;\n    _10064.x = _7693.x;\n    _10064.y = _7693.y;\n    _10064.z = _7693.z;\n    base_t = _10064;\n    vec4 _7707 = (_10064 * fa_mesh_fs_params[2]) * i.vertex_color;\n    vec3 _9814 = i.world_normal;\n    if (fa_mesh_fs_params[6].z > 0.5)\n    {\n        float param_4 = fa_mesh_fs_params[6].w;\n        float param_5 = 16.0;\n        vec3 param_6 = texture(fa_normal_tex_fa_smp, i.uv, fa_mesh_fs_params[12].w).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        vec3 _7741 = fa_tex_fix(param_6, param_7);\n        vec3 _7744 = (_7741 * 2.0) - vec3(1.0);\n        vec2 _7749 = _7744.xy * fa_mesh_fs_params[6].x;\n        vec3 _10072 = _7744;\n        _10072.x = _7749.x;\n        _10072.y = _7749.y;\n        SurfaceInput param_8 = i;\n        vec3 param_9 = _10072;\n        _9814 = fa_tangent_normal(param_8, param_9);\n    }\n    vec4 mrt = texture(fa_mr_tex_fa_smp, i.uv, fa_mesh_fs_params[12].w);\n    float param_10 = fa_mesh_fs_params[6].w;\n    float param_11 = 64.0;\n    vec3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    vec3 _7779 = fa_tex_fix(param_12, param_13);\n    vec4 _10075 = mrt;\n    _10075.x = _7779.x;\n    _10075.y = _7779.y;\n    _10075.z = _7779.z;\n    mrt = _10075;\n    vec4 _7809 = texture(fa_occlusion_tex_fa_smp, i.uv, fa_mesh_fs_params[12].w);\n    float param_14 = fa_mesh_fs_params[6].w;\n    float param_15 = 256.0;\n    vec3 param_16 = _7809.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    vec3 _7820 = fa_tex_fix(param_16, param_17);\n    float param_18 = fa_mesh_fs_params[6].w;\n    float param_19 = 4.0;\n    vec3 param_20 = texture(fa_emissive_tex_fa_smp, i.uv, fa_mesh_fs_params[12].w).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    vec3 _7852 = fa_tex_fix(param_20, param_21);\n    float _9819 = fa_mesh_fs_params[20].x;\n    float _9820 = fa_mesh_fs_params[20].y;\n    float _9823 = fa_mesh_fs_params[20].z;\n    float _9822 = fa_mesh_fs_params[21].w;\n    float _9825 = fa_mesh_fs_params[22].x;\n    if (fa_mesh_fs_params[22].z > 0.5)\n    {\n        if (mod(fa_mesh_fs_params[22].z, 2.0) > 0.5)\n        {\n            _9819 *= _7820.y;\n            _9820 *= _7820.z;\n            _9822 *= _7809.w;\n        }\n        if (fa_mesh_fs_params[22].z > 1.5)\n        {\n            _9823 *= mrt.x;\n            _9825 *= mrt.w;\n        }\n    }\n    return Surface(_7707.xyz, _7707.w, _9814, clamp(fa_mesh_fs_params[5].x * _7779.z, 0.0, 1.0), clamp(fa_mesh_fs_params[5].y * _7779.y, 0.0500000007450580596923828125, 1.0), 1.0 + (fa_mesh_fs_params[6].y * (_7820.x - 1.0)), fa_mesh_fs_params[3].xyz + (fa_mesh_fs_params[4].xyz * _7852), _9819, _9820, fa_mesh_fs_params[21].xyz, _9822, _9823, fa_mesh_fs_params[20].w, _9825, fa_mesh_fs_params[22].y, fa_mesh_fs_params[23].xyz, fa_mesh_fs_params[30].x, fa_mesh_fs_params[30].y, fa_mesh_fs_params[31].xyz, fa_mesh_fs_params[30].z);\n}\n\nvoid surface(SurfaceInput i, inout Surface s)\n{\n    s.emission += (i.vertex_color.xyz * points.data[0].tint.w);\n}\n\nvec4 fa_decal_tile(vec4 rect, vec2 uv, vec2 atlas, vec2 ddx, vec2 ddy)\n{\n    vec2 _1828 = rect.zw - rect.xy;\n    vec2 _1832 = _1828 * atlas;\n    vec2 _1836 = ddx * _1832;\n    vec2 _1840 = ddy * _1832;\n    return textureLod(fa_decal_tex_fa_env_smp, rect.xy + (clamp(uv, vec2(0.0), vec2(1.0)) * _1828), clamp(0.5 * log2(max(max(dot(_1836, _1836), dot(_1840, _1840)), 9.9999999392252902907785028219223e-09)), 0.0, 3.0));\n}\n\nvec3 fa_dc_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_dc_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvoid fa_apply_decals(vec3 world_pos, vec3 geo_normal, inout vec3 albedo, inout vec3 normal)\n{\n    bool _1873 = fa_mesh_fs_params[10].y < 0.5;\n    bool _1880;\n    if (!_1873)\n    {\n        _1880 = fa_mesh_fs_params[10].w < 0.5;\n    }\n    else\n    {\n        _1880 = _1873;\n    }\n    if (_1880)\n    {\n        return;\n    }\n    vec3 _1886 = dFdx(world_pos);\n    vec3 _1889 = dFdy(world_pos);\n    vec3 param = world_pos;\n    vec4 _1893 = fa_cluster_texel(param);\n    int _1897 = int(_1893.w);\n    if (_1897 < 1)\n    {\n        return;\n    }\n    int _1907 = int(fa_mesh_fs_params[10].y + 0.5);\n    int param_1 = _1907;\n    vec4 _1911 = fa_light_texel(param_1);\n    vec2 _1914 = _1911.yz;\n    int _1918 = int(_1911.w);\n    int param_2 = _1907 + 1;\n    vec4 _1923 = fa_light_texel(param_2);\n    float _1924 = _1923.x;\n    int _1930 = int(fa_mesh_fs_params[10].w + 0.5) - 1;\n    int _1934 = int(_1893.z);\n    vec3 _2199;\n    for (int k = 0; k < _1897; k++)\n    {\n        int _1947 = _1934 + k;\n        int param_3 = _1918 + (_1947 >> 2);\n        int _1964 = (_1907 + 2) + (int(fa_light_texel(param_3)[_1947 & 3]) * 7);\n        int param_4 = _1964 + 6;\n        vec4 _1969 = fa_light_texel(param_4);\n        if (((int(_1969.w + 0.5) >> _1930) & 1) == 0)\n        {\n            continue;\n        }\n        int param_5 = _1964;\n        vec4 _1984 = fa_light_texel(param_5);\n        int param_6 = _1964 + 1;\n        vec4 _1989 = fa_light_texel(param_6);\n        int param_7 = _1964 + 2;\n        vec4 _1994 = fa_light_texel(param_7);\n        vec3 _1997 = _1984.xyz;\n        float _2002 = dot(_1997, world_pos) + _1984.w;\n        vec3 _2004 = _1989.xyz;\n        float _2009 = dot(_2004, world_pos) + _1989.w;\n        vec3 _2011 = _1994.xyz;\n        float _2016 = dot(_2011, world_pos) + _1994.w;\n        bool _2021 = abs(_2002) > 0.5;\n        bool _2029;\n        if (!_2021)\n        {\n            _2029 = abs(_2009) > 0.5;\n        }\n        else\n        {\n            _2029 = _2021;\n        }\n        bool _2037;\n        if (!_2029)\n        {\n            _2037 = abs(_2016) > 0.5;\n        }\n        else\n        {\n            _2037 = _2029;\n        }\n        if (_2037)\n        {\n            continue;\n        }\n        float _2052 = clamp(dot(geo_normal, normalize(_2011)) * _1969.z, 0.0, 1.0);\n        if (_2052 <= 0.0)\n        {\n            continue;\n        }\n        float _2072 = (clamp((0.5 - abs(_2016)) * 10.0, 0.0, 1.0) * _2052) * _1969.x;\n        vec2 _2080 = vec2(_2002 + 0.5, 0.5 - _2009);\n        vec2 _2090 = vec2(dot(_1997, _1886), dot(_2004, _1886));\n        vec2 _2100 = vec2(dot(_1997, _1889), dot(_2004, _1889));\n        int param_8 = _1964 + 5;\n        vec4 _2105 = fa_light_texel(param_8);\n        int param_9 = _1964 + 3;\n        vec4 _2110 = fa_light_texel(param_9);\n        int param_10 = _1964 + 4;\n        vec4 _2115 = fa_light_texel(param_10);\n        float tex_a = 1.0;\n        vec3 col = _2105.xyz;\n        bool _2125 = _2110.z > _2110.x;\n        if (_2125)\n        {\n            vec4 param_11 = _2110;\n            vec2 param_12 = _2080;\n            vec2 param_13 = _1914;\n            vec2 param_14 = _2090;\n            vec2 param_15 = _2100;\n            vec4 tx = fa_decal_tile(param_11, param_12, param_13, param_14, param_15);\n            if ((_1924 > 0.5) && (_1924 < 1.5))\n            {\n                vec3 param_16 = tx.xyz;\n                vec3 _2151 = fa_dc_to_linear(param_16);\n                vec4 _9902 = tx;\n                _9902.x = _2151.x;\n                _9902.y = _2151.y;\n                _9902.z = _2151.z;\n                tx = _9902;\n            }\n            col *= tx.xyz;\n            tex_a = tx.w;\n        }\n        albedo = mix(albedo, col, vec3(clamp((_2072 * tex_a) * _2105.w, 0.0, 1.0)));\n        if (_2115.z > _2115.x)\n        {\n            vec4 param_17 = _2115;\n            vec2 param_18 = _2080;\n            vec2 param_19 = _1914;\n            vec2 param_20 = _2090;\n            vec2 param_21 = _2100;\n            vec4 _2195 = fa_decal_tile(param_17, param_18, param_19, param_20, param_21);\n            if (_1924 > 1.5)\n            {\n                vec3 param_22 = _2195.xyz;\n                vec3 _2205 = fa_dc_to_srgb(param_22);\n                _2199 = _2205;\n            }\n            else\n            {\n                _2199 = _2195.xyz;\n            }\n            vec3 _2214 = (_2199 * 2.0) - vec3(1.0);\n            vec2 _2219 = _2214.xy * _1969.y;\n            vec3 _2241 = (normalize(_1997) * _2219.x) + (normalize(_2004) * _2219.y);\n            vec3 _2244 = normalize(normal);\n            normal = normalize(mix(_2244, normalize((_2244 * max(_2214.z, 0.0500000007450580596923828125)) + (_2241 - (_2244 * dot(_2244, _2241)))), vec3(clamp(_2072 * (_2125 ? tex_a : 1.0), 0.0, 1.0))));\n        }\n    }\n}\n\nfloat fa_sheen_albedo(float ndv, float rough)\n{\n    float _4741 = min(sqrt(max(rough - 0.100000001490116119384765625, 0.0) * 1.111111164093017578125) * 6.0, 5.999000072479248046875);\n    float _4749 = min(sqrt(clamp(ndv, 0.0, 1.0)) * 8.0, 7.999000072479248046875);\n    int _4752 = int(_4741);\n    int _4755 = int(_4749);\n    float _4765 = _4749 - float(_4755);\n    int _4820 = (_4752 * 9) + _4755;\n    int _4840 = ((_4752 + 1) * 9) + _4755;\n    return mix(mix(_4816[_4820], _4816[_4820 + 1], _4765), mix(_4816[_4840], _4816[_4840 + 1], _4765), _4741 - float(_4752));\n}\n\nFaLayers fa_layers_setup(SurfaceInput i, Surface s, vec3 n, vec3 v, float metallic, float roughness, inout vec3 f0)\n{\n    bool _9737 = false;\n    float _9738 = 1.0;\n    float _9739 = 1.0;\n    float _9740 = 1.0;\n    float _9741 = 0.0;\n    float _9742 = 0.0;\n    float _9743 = 0.0;\n    float _9744 = 0.0;\n    float _9746 = 1.0;\n    bool _9747 = false;\n    vec3 _9748 = vec3(0.0);\n    float _9749 = 1.0;\n    float _9750 = 1.0;\n    float _9751 = 1.0;\n    float _9752 = 0.0;\n    float _9753 = 0.0;\n    vec3 _9754 = vec3(1.0, 0.0, 0.0);\n    vec3 _9755 = vec3(0.0, 0.0, 1.0);\n    float _9756 = 1.0;\n    float _9757 = 1.0;\n    float _4891 = clamp(s.specular, 0.0, 1.0);\n    float _4895 = clamp(s.ior, 1.0, 3.0);\n    bool _4900 = (_4891 != 1.0) || (_4895 != 1.5);\n    bool _4909;\n    if (!_4900)\n    {\n        _4909 = any(notEqual(s.specular_color, vec3(1.0)));\n    }\n    else\n    {\n        _4909 = _4900;\n    }\n    if (_4909)\n    {\n        float _4917 = (_4895 - 1.0) / (_4895 + 1.0);\n        f0 = mix(min(vec3(_4917 * _4917) * max(s.specular_color, vec3(0.0)), vec3(1.0)) * _4891, s.albedo, vec3(metallic));\n        _9738 = mix(_4891, 1.0, metallic);\n        _9737 = true;\n    }\n    float _4944 = clamp(s.clearcoat, 0.0, 1.0);\n    if (_4944 > 0.0)\n    {\n        float _4952 = clamp(s.clearcoat_roughness, 0.0500000007450580596923828125, 1.0);\n        _9741 = _4944;\n        _9742 = _4952;\n        float _4959 = _4952 * _4952;\n        _9743 = _4959;\n        _9744 = _4959 * _4959;\n        float _4971 = max(dot(i.world_normal, v), 9.9999997473787516355514526367188e-05);\n        _9746 = _4971;\n        _9739 = 1.0 - (_4944 * (0.039999999105930328369140625 + (0.959999978542327880859375 * pow(clamp(1.0 - _4971, 0.0, 1.0), 5.0))));\n        _9737 = true;\n    }\n    vec3 _4990 = max(s.sheen_color, vec3(0.0));\n    float _4999 = max(_4990.x, max(_4990.y, _4990.z));\n    if (_4999 > 0.0)\n    {\n        float _5007 = clamp(s.sheen_roughness, 0.100000001490116119384765625, 1.0);\n        _9747 = true;\n        _9748 = _4990;\n        _9749 = _5007;\n        _9750 = _5007 * _5007;\n        float param = max(dot(n, v), 9.9999997473787516355514526367188e-05);\n        float param_1 = _5007;\n        float _5024 = fa_sheen_albedo(param, param_1);\n        _9752 = _5024;\n        _9751 = 1.0 - min(_4999 * _5024, 1.0);\n        _9737 = true;\n    }\n    _9740 = _9739 * _9751;\n    float _5043 = clamp(s.anisotropy, -1.0, 1.0);\n    if (_5043 != 0.0)\n    {\n        vec3 _5058 = i.world_tangent.xyz - (n * dot(n, i.world_tangent.xyz));\n        vec3 t = _5058;\n        if (dot(_5058, _5058) < 9.9999999392252902907785028219223e-09)\n        {\n            bvec3 _5070 = bvec3(abs(n.y) < 0.9900000095367431640625);\n            t = cross(vec3(_5070.x ? vec3(0.0, 1.0, 0.0).x : vec3(1.0, 0.0, 0.0).x, _5070.y ? vec3(0.0, 1.0, 0.0).y : vec3(1.0, 0.0, 0.0).y, _5070.z ? vec3(0.0, 1.0, 0.0).z : vec3(1.0, 0.0, 0.0).z), n);\n        }\n        vec3 _5074 = t;\n        vec3 _5075 = normalize(_5074);\n        t = _5075;\n        vec3 _5100 = normalize((_5075 * cos(s.anisotropy_rotation)) + ((cross(n, _5075) * ((i.world_tangent.w < 0.0) ? (-1.0) : 1.0)) * sin(s.anisotropy_rotation)));\n        _9754 = _5100;\n        _9755 = cross(n, _5100);\n        float _5110 = roughness * roughness;\n        float _5116 = mix(_5110, 1.0, _5043 * _5043);\n        bool _5118 = _5043 > 0.0;\n        _9756 = _5118 ? _5116 : _5110;\n        _9757 = _5118 ? _5110 : _5116;\n        _9753 = _5043;\n        _9737 = true;\n    }\n    return FaLayers(_9737, _9738, _9739, _9740, _9741, _9742, _9743, _9744, i.world_normal, _9746, _9747, _9748, _9749, _9750, _9751, _9752, _9753, _9754, _9755, _9756, _9757);\n}\n\nvec2 fa_atlas_size()\n{\n    return vec2(textureSize(fa_probe_atlas_fa_env_smp, 0));\n}\n\nvec3 fa_probe_sh_coef(vec2 origin, float res, int k)\n{\n    vec3 v = textureLod(fa_probe_atlas_fa_env_smp, (origin + vec2(float(k) + 0.5, res + 2.5)) / fa_atlas_size(), 0.0).xyz;\n    if (fa_mesh_fs_params[41].y > 0.5)\n    {\n        v = ((v * 255.0) - vec3(128.0)) * 0.03149606287479400634765625;\n    }\n    return v;\n}\n\nvec3 fa_sh_eval(vec3 c[9], vec3 n)\n{\n    vec3 _3912 = max((((c[0] * 0.2820948064327239990234375) + (((c[1] * (0.3257350027561187744140625 * n.y)) + (c[2] * (0.3257350027561187744140625 * n.z))) + (c[3] * (0.3257350027561187744140625 * n.x)))) + (((c[4] * ((0.2731371223926544189453125 * n.x) * n.y)) + (c[5] * ((0.2731371223926544189453125 * n.y) * n.z))) + (c[6] * (0.078847892582416534423828125 * (((3.0 * n.z) * n.z) - 1.0))))) + ((c[7] * ((0.2731371223926544189453125 * n.x) * n.z)) + (c[8] * (0.13656856119632720947265625 * ((n.x * n.x) - (n.y * n.y))))), vec3(0.0));\n    return _3912;\n}\n\nvec3 fa_ambient_light(vec3 n)\n{\n    float _4523 = (1.0 - fa_mesh_fs_params[42].w) - fa_mesh_fs_params[47].w;\n    vec3 amb = vec3(0.0);\n    bool _4528 = fa_mesh_fs_params[11].w > 0.5;\n    vec3 c[9];\n    for (int k = 0; k < 9; k++)\n    {\n        c[k] = vec3(0.0);\n    }\n    if (_4523 > 0.0005000000237487256526947021484375)\n    {\n        if (_4528)\n        {\n            for (int k_1 = 0; k_1 < 9; k_1++)\n            {\n                vec2 param = fa_mesh_fs_params[41].zw;\n                float param_1 = 128.0;\n                int param_2 = k_1;\n                c[k_1] = fa_probe_sh_coef(param, param_1, param_2) * _4523;\n            }\n        }\n        else\n        {\n            amb = fa_mesh_fs_params[1].xyz * _4523;\n        }\n    }\n    bool _4578 = fa_mesh_fs_params[42].w > 0.0;\n    if (_4578)\n    {\n        for (int k_2 = 0; k_2 < 9; k_2++)\n        {\n            vec2 param_3 = fa_mesh_fs_params[42].xy;\n            float param_4 = fa_mesh_fs_params[42].z;\n            int param_5 = k_2;\n            c[k_2] += (fa_probe_sh_coef(param_3, param_4, param_5) * fa_mesh_fs_params[42].w);\n        }\n    }\n    bool _4609 = fa_mesh_fs_params[47].w > 0.0;\n    if (_4609)\n    {\n        for (int k_3 = 0; k_3 < 9; k_3++)\n        {\n            vec2 param_6 = fa_mesh_fs_params[47].xy;\n            float param_7 = fa_mesh_fs_params[47].z;\n            int param_8 = k_3;\n            c[k_3] += (fa_probe_sh_coef(param_6, param_7, param_8) * fa_mesh_fs_params[47].w);\n        }\n    }\n    if ((_4528 || _4578) || _4609)\n    {\n        vec3 param_9[9] = c;\n        vec3 param_10 = n;\n        amb += fa_sh_eval(param_9, param_10);\n    }\n    return amb;\n}\n\nvec4 fa_gi_fetch(vec2 texel)\n{\n    return textureLod(fa_probe_atlas_fa_env_smp, texel / fa_atlas_size(), 0.0);\n}\n\nvec2 fa_oct_encode(vec3 d)\n{\n    vec3 _3932 = d / vec3(max((abs(d.x) + abs(d.y)) + abs(d.z), 9.9999999600419720025001879548654e-13));\n    float _3935 = _3932.x;\n    float _3937 = _3932.z;\n    vec2 e = vec2(_3935, _3937);\n    if (_3932.y < 0.0)\n    {\n        e = vec2((1.0 - abs(_3937)) * ((_3935 < 0.0) ? (-1.0) : 1.0), (1.0 - abs(_3935)) * ((_3937 < 0.0) ? (-1.0) : 1.0));\n    }\n    return e;\n}\n\nvec3 fa_gi_grid(int rec, vec3 n, vec3 v, out float cover)\n{\n    cover = 0.0;\n    int param = rec;\n    vec4 _7962 = fa_light_texel(param);\n    int param_1 = rec + 1;\n    vec4 _7967 = fa_light_texel(param_1);\n    int param_2 = rec + 2;\n    vec4 _7972 = fa_light_texel(param_2);\n    int param_3 = rec + 3;\n    vec4 _7977 = fa_light_texel(param_3);\n    bool _7980 = _7977.z < 0.5;\n    bool _7988;\n    if (!_7980)\n    {\n        _7988 = fa_atlas_size().y < 1155.0;\n    }\n    else\n    {\n        _7988 = _7980;\n    }\n    if (_7988)\n    {\n        return vec3(0.0);\n    }\n    float _7995 = max(_7962.w, 9.9999997473787516355514526367188e-05);\n    vec3 _7998 = _7967.xyz;\n    vec3 _8002 = _7962.xyz;\n    vec3 _8006 = (fa_world_pos - _8002) / vec3(_7995);\n    vec3 _8015 = min(_8006 + vec3(0.5), (_7998 - vec3(0.5)) - _8006);\n    float _8024 = min(_8015.x, min(_8015.y, _8015.z));\n    if (!(_8024 > 0.0))\n    {\n        return vec3(0.0);\n    }\n    vec3 _8039 = _7998 - vec3(1.0);\n    vec3 _8040 = clamp(_8006, vec3(0.0), _8039);\n    vec3 _8048 = min(floor(_8040), max(_7998 - vec3(2.0), vec3(0.0)));\n    vec3 _8052 = _8040 - _8048;\n    vec3 _8063 = fa_world_pos + (((n * 0.800000011920928955078125) + (v * 0.20000000298023223876953125)) * (0.20000000298023223876953125 * _7995));\n    int _8068 = int(_7972.y + 0.5);\n    float _8073 = 0.3257350027561187744140625 * n.y;\n    float _8077 = 0.3257350027561187744140625 * n.z;\n    float _8081 = 0.3257350027561187744140625 * n.x;\n    float _8088 = (0.2731371223926544189453125 * n.x) * n.y;\n    float _8095 = (0.2731371223926544189453125 * n.y) * n.z;\n    float _8104 = 0.078847892582416534423828125 * (((3.0 * n.z) * n.z) - 1.0);\n    float _8111 = (0.2731371223926544189453125 * n.x) * n.z;\n    float _8124 = 0.13656856119632720947265625 * ((n.x * n.x) - (n.y * n.y));\n    vec3 acc = vec3(0.0);\n    float wsum = 0.0;\n    int _8131 = 8 + int(_7977.w);\n    float _8158;\n    float _8171;\n    float _8185;\n    for (int k = 0; k < _8131; k++)\n    {\n        float _8144 = float(k & 1);\n        float _8148 = float((k >> 1) & 1);\n        float _8152 = float((k >> 2) & 1);\n        if (_8144 > 0.5)\n        {\n            _8158 = _8052.x;\n        }\n        else\n        {\n            _8158 = 1.0 - _8052.x;\n        }\n        if (_8148 > 0.5)\n        {\n            _8171 = _8052.y;\n        }\n        else\n        {\n            _8171 = 1.0 - _8052.y;\n        }\n        if (_8152 > 0.5)\n        {\n            _8185 = _8052.z;\n        }\n        else\n        {\n            _8185 = 1.0 - _8052.z;\n        }\n        float _8195 = (_8158 * _8171) * _8185;\n        if (!(_8195 > 0.0))\n        {\n            continue;\n        }\n        vec3 _8208 = min(_8048 + vec3(_8144, _8148, _8152), _8039);\n        int _8228 = int(((_7972.x + _8208.x) + (_7967.x * (_8208.y + (_7967.y * _8208.z)))) + 0.5);\n        vec2 _8243 = vec2(float(_8228 % _8068) * 10.0, 1024.0 + (float(_8228 / _8068) * 11.0));\n        vec2 param_4 = _8243 + vec2(9.5, 10.5);\n        vec4 _8251 = fa_gi_fetch(param_4);\n        bool _8254 = _8251.y < 0.5;\n        bool _8263;\n        if (!_8254)\n        {\n            _8263 = _8251.x > _7977.y;\n        }\n        else\n        {\n            _8263 = _8254;\n        }\n        if (_8263)\n        {\n            continue;\n        }\n        vec3 _8275 = _8063 - (_8002 + (_8208 * _7995));\n        float _8278 = length(_8275);\n        vec3 _8284 = _8275 / vec3(max(_8278, 9.9999997473787516355514526367188e-05));\n        float _8294 = max(9.9999997473787516355514526367188e-05, (dot(-_8284, n) + 1.0) * 0.5);\n        float w = _8195 * (_8294 * _8294);\n        vec3 param_5 = _8284;\n        vec2 param_6 = (_8243 + vec2(1.0)) + (((fa_oct_encode(param_5) * 0.5) + vec2(0.5)) * 8.0);\n        vec4 _8313 = fa_gi_fetch(param_6);\n        float _8320 = _8278 / max(_7972.z, 9.9999997473787516355514526367188e-05);\n        float _8323 = _8313.x;\n        if (_8320 > _8323)\n        {\n            float _8336 = max(_8313.y - (_8323 * _8323), 0.0);\n            float _8341 = _8320 - _8323;\n            float _8350 = _8336 / max(_8336 + (_8341 * _8341), 9.9999999600419720025001879548654e-13);\n            w *= ((_8350 * _8350) * _8350);\n        }\n        if (!(w > 0.0))\n        {\n            continue;\n        }\n        vec2 param_7 = _8243 + vec2(0.5, 10.5);\n        vec2 param_8 = _8243 + vec2(1.5, 10.5);\n        vec2 param_9 = _8243 + vec2(2.5, 10.5);\n        vec2 param_10 = _8243 + vec2(3.5, 10.5);\n        vec2 param_11 = _8243 + vec2(4.5, 10.5);\n        vec2 param_12 = _8243 + vec2(5.5, 10.5);\n        vec2 param_13 = _8243 + vec2(6.5, 10.5);\n        vec2 param_14 = _8243 + vec2(7.5, 10.5);\n        vec2 param_15 = _8243 + vec2(8.5, 10.5);\n        acc += ((((((((((fa_gi_fetch(param_7).xyz * 0.2820948064327239990234375) + (fa_gi_fetch(param_8).xyz * _8073)) + (fa_gi_fetch(param_9).xyz * _8077)) + (fa_gi_fetch(param_10).xyz * _8081)) + (fa_gi_fetch(param_11).xyz * _8088)) + (fa_gi_fetch(param_12).xyz * _8095)) + (fa_gi_fetch(param_13).xyz * _8104)) + (fa_gi_fetch(param_14).xyz * _8111)) + (fa_gi_fetch(param_15).xyz * _8124)) * w);\n        wsum += w;\n    }\n    if (!(wsum > 9.9999997473787516355514526367188e-06))\n    {\n        return vec3(0.0);\n    }\n    cover = smoothstep(0.0, 1.0, clamp(_8024 * 2.0, 0.0, 1.0)) * smoothstep(0.0, 0.0199999995529651641845703125, wsum);\n    float _8475;\n    if (fa_mesh_fs_params[52].z > 0.5)\n    {\n        _8475 = _7977.x;\n    }\n    else\n    {\n        _8475 = 1.0;\n    }\n    return max(acc / vec3(wsum), vec3(0.0)) * (_7972.w * _8475);\n}\n\nvec3 fa_gi_light(vec3 n, inout float left)\n{\n    left = 1.0;\n    vec3 acc = vec3(0.0);\n    vec3 _8499 = normalize(fa_mesh_fs_params[0].xyz - fa_world_pos);\n    int _8504 = int(fa_mesh_fs_params[52].x + 0.5);\n    int _8509 = int(fa_mesh_fs_params[52].y + 0.5);\n    float param_3;\n    for (int k = 0; (k < _8509) && (k < 8); k++)\n    {\n        int param = _8504 + (4 * k);\n        vec3 param_1 = n;\n        vec3 param_2 = _8499;\n        vec3 _8534 = fa_gi_grid(param, param_1, param_2, param_3);\n        float _8539 = param_3 * left;\n        acc += (_8534 * _8539);\n        left -= _8539;\n        if (left < 0.001000000047497451305389404296875)\n        {\n            left = 0.0;\n            break;\n        }\n    }\n    return acc;\n}\n\nvec3 fa_realtime_or_ambient(vec3 n)\n{\n    vec3 gi = vec3(0.0);\n    float left = 1.0;\n    if (fa_mesh_fs_params[52].y > 0.5)\n    {\n        vec3 param = n;\n        float param_1;\n        vec3 _8568 = fa_gi_light(param, param_1);\n        left = param_1;\n        gi = _8568;\n    }\n    if (left <= 0.0)\n    {\n        return gi;\n    }\n    vec3 param_2 = n;\n    return gi + (fa_ambient_light(param_2) * left);\n}\n\nvec3 fa_indirect_diffuse(vec3 n)\n{\n    if (fa_lm.z > 0.5)\n    {\n        return textureLod(fa_lightmap_fa_env_smp, fa_lm.xy, 0.0).xyz;\n    }\n    if (fa_mesh_fs_params[53].x > 0.5)\n    {\n        vec4 _8610 = vec4(fa_world_pos, 1.0);\n        vec2 _8629 = vec2(dot(fa_mesh_fs_params[26], _8610), dot(fa_mesh_fs_params[27], _8610)) / vec2(max(dot(fa_mesh_fs_params[28], _8610), 9.9999997473787516355514526367188e-05));\n        float _8638;\n        if (fa_mesh_fs_params[24].y > 0.5)\n        {\n            _8638 = (_8629.y * 0.5) + 0.5;\n        }\n        else\n        {\n            _8638 = 0.5 - (_8629.y * 0.5);\n        }\n        return texelFetch(fa_lightmap_fa_env_smp, clamp(ivec2(vec2((_8629.x * 0.5) + 0.5, _8638) * fa_mesh_fs_params[24].zw), ivec2(0), ivec2(fa_mesh_fs_params[24].zw) - ivec2(1)), 0).xyz;\n    }\n    if (fa_mesh_fs_params[32].w > 0.0)\n    {\n        vec3 c[9];\n        for (int k = 0; k < 9; k++)\n        {\n            c[k] = fa_mesh_fs_params[k * 1 + 32].xyz;\n        }\n        vec3 param = n;\n        vec3 param_1[9] = c;\n        vec3 param_2 = n;\n        return mix(fa_ambient_light(param), fa_sh_eval(param_1, param_2), vec3(clamp(fa_mesh_fs_params[32].w, 0.0, 1.0)));\n    }\n    vec3 param_3 = n;\n    return fa_realtime_or_ambient(param_3);\n}\n\nint fa_cluster_index(int slot, int n)\n{\n    int param = (int(fa_mesh_fs_params[19].x) + int(fa_mesh_fs_params[19].w)) + ((slot + n) >> 2);\n    vec4 t = fa_light_texel(param);\n    return int(t[(slot + n) & 3]);\n}\n\nint fa_cl_light(int n)\n{\n    if (n < fa_cl_ndir)\n    {\n        return n;\n    }\n    int param = fa_cl_slot;\n    int param_1 = n - fa_cl_ndir;\n    return fa_cluster_index(param, param_1);\n}\n\nint fa_light_base(int li)\n{\n    return li * ((fa_mesh_fs_params[1].w > 4.5) ? 8 : 4);\n}\n\nbool fa_light_baked(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 3;\n    return fa_light_texel(param_1).w > 0.5;\n}\n\nfloat fa_baked_keep(int li)\n{\n    float _6420;\n    if (fa_lm.z > 0.5)\n    {\n        _6420 = 0.0;\n    }\n    else\n    {\n        _6420 = 1.0 - clamp(fa_mesh_fs_params[32].w, 0.0, 1.0);\n    }\n    bool _6431 = _6420 < 1.0;\n    bool _6437;\n    if (_6431)\n    {\n        int param = li;\n        _6437 = fa_light_baked(param);\n    }\n    else\n    {\n        _6437 = _6431;\n    }\n    return _6437 ? _6420 : 1.0;\n}\n\nfloat fa_light_type(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 1;\n    return fa_light_texel(param_1).w;\n}\n\nvec4 fa_atlas_fetch(vec2 texel)\n{\n    return textureLod(fa_light_atlas_fa_env_smp, texel / vec2(textureSize(fa_light_atlas_fa_env_smp, 0)), 0.0);\n}\n\nvec3 fa_cookie_sample(vec2 tile_origin, vec2 uv)\n{\n    vec2 param = (tile_origin + vec2(1.0)) + (clamp(uv, vec2(0.0), vec2(1.0)) * 254.0);\n    return fa_atlas_fetch(param).xyz;\n}\n\nvec3 fa_area_point(vec3 c, vec3 axis, vec3 ru, vec3 uu, float hx, float hy, float shape, vec3 p, vec3 r)\n{\n    bool _846 = dot(r, r) > 0.5;\n    if (shape > 1.5)\n    {\n        vec3 _859 = (c - (ru * hx)) - p;\n        vec3 _865 = ru * (2.0 * hx);\n        float _871 = max(dot(_865, _865), 9.9999999392252902907785028219223e-09);\n        float _875 = dot(_859, _865);\n        float t = clamp((-_875) / _871, 0.0, 1.0);\n        if (_846)\n        {\n            float _890 = dot(r, _865);\n            float _896 = _871 - (_890 * _890);\n            if (abs(_896) > (9.9999997473787516355514526367188e-06 * _871))\n            {\n                t = clamp(((dot(r, _859) * _890) - _875) / _896, 0.0, 1.0);\n            }\n        }\n        return (p + _859) + (_865 * t);\n    }\n    vec3 q = p;\n    float _928 = dot(r, axis);\n    bool _936;\n    if (_846)\n    {\n        _936 = abs(_928) > 9.9999997473787516355514526367188e-05;\n    }\n    else\n    {\n        _936 = _846;\n    }\n    if (_936)\n    {\n        float _946 = dot(c - p, axis) / _928;\n        if (_946 > 0.0)\n        {\n            q = p + (r * _946);\n        }\n    }\n    vec3 _959 = q - c;\n    vec2 xy = vec2(dot(_959, ru), dot(_959, uu));\n    if (shape > 0.5)\n    {\n        float _974 = length(xy);\n        if (_974 > hx)\n        {\n            xy *= (hx / _974);\n        }\n    }\n    else\n    {\n        xy = clamp(xy, vec2(-hx, -hy), vec2(hx, hy));\n    }\n    return (c + (ru * xy.x)) + (uu * xy.y);\n}\n\nint fa_cube_face(vec3 d)\n{\n    vec3 _608 = abs(d);\n    float _610 = _608.x;\n    float _612 = _608.y;\n    bool _613 = _610 >= _612;\n    bool _621;\n    if (_613)\n    {\n        _621 = _610 >= _608.z;\n    }\n    else\n    {\n        _621 = _613;\n    }\n    int _622;\n    if (_621)\n    {\n        _622 = (d.x > 0.0) ? 0 : 1;\n    }\n    else\n    {\n        int _636;\n        if (_612 >= _608.z)\n        {\n            _636 = (d.y > 0.0) ? 2 : 3;\n        }\n        else\n        {\n            _636 = (d.z > 0.0) ? 4 : 5;\n        }\n        _622 = _636;\n    }\n    return _622;\n}\n\nvoid fa_cube_face_basis(int f, out vec3 fwd, out vec3 up)\n{\n    if (f == 0)\n    {\n        fwd = vec3(1.0, 0.0, 0.0);\n        up = vec3(0.0, 1.0, 0.0);\n    }\n    else\n    {\n        if (f == 1)\n        {\n            fwd = vec3(-1.0, 0.0, 0.0);\n            up = vec3(0.0, 1.0, 0.0);\n        }\n        else\n        {\n            if (f == 2)\n            {\n                fwd = vec3(0.0, 1.0, 0.0);\n                up = vec3(0.0, 0.0, 1.0);\n            }\n            else\n            {\n                if (f == 3)\n                {\n                    fwd = vec3(0.0, -1.0, 0.0);\n                    up = vec3(0.0, 0.0, -1.0);\n                }\n                else\n                {\n                    if (f == 4)\n                    {\n                        fwd = vec3(0.0, 0.0, 1.0);\n                        up = vec3(0.0, 1.0, 0.0);\n                    }\n                    else\n                    {\n                        fwd = vec3(0.0, 0.0, -1.0);\n                        up = vec3(0.0, 1.0, 0.0);\n                    }\n                }\n            }\n        }\n    }\n}\n\nfloat fa_ies_sample(vec2 tile_origin, vec3 d, vec3 axis, vec3 right, vec3 up)\n{\n    float _766 = dot(d, right);\n    float _770 = dot(d, up);\n    float _781;\n    if (((_766 * _766) + (_770 * _770)) > 1.0000000133514319600180897396058e-10)\n    {\n        _781 = atan(_770, _766) * 0.15915493667125701904296875;\n    }\n    else\n    {\n        _781 = 0.0;\n    }\n    vec2 param = tile_origin + vec2(1.0 + ((_781 - floor(_781)) * 64.0), 1.0 + (acos(clamp(dot(d, axis), -1.0, 1.0)) * 10.18591594696044921875));\n    return fa_atlas_fetch(param).x;\n}\n\nLightSample fa_light_sample_n(int li, vec3 world_pos, vec3 n)\n{\n    int param = li;\n    int _1012 = fa_light_base(param);\n    bool _1016 = fa_mesh_fs_params[1].w > 4.5;\n    int param_1 = _1012;\n    vec4 _1020 = fa_light_texel(param_1);\n    int param_2 = _1012 + 1;\n    vec4 _1025 = fa_light_texel(param_2);\n    float _1028 = _1025.w;\n    float atten = 1.0;\n    float dist = 0.0;\n    fa_light_tint = vec3(1.0);\n    bool _1040 = _1016 && (_1028 > 2.5);\n    fa_light_is_area = _1040;\n    bool _1042 = _1028 < 0.5;\n    vec3 l;\n    if (_1042)\n    {\n        l = normalize(_1020.xyz);\n        if (_1016)\n        {\n            int param_3 = _1012 + 6;\n            vec4 _1056 = fa_light_texel(param_3);\n            if (_1056.z > 0.5)\n            {\n                int param_4 = _1012 + 4;\n                vec4 _1066 = fa_light_texel(param_4);\n                int param_5 = _1012 + 5;\n                vec4 _1071 = fa_light_texel(param_5);\n                vec2 param_6 = _1056.xy;\n                vec2 param_7 = fract(vec2(dot(world_pos, _1066.xyz) * _1066.w, (-dot(world_pos, _1071.xyz)) * _1071.w) + vec2(0.5));\n                fa_light_tint = fa_cookie_sample(param_6, param_7);\n            }\n        }\n    }\n    else\n    {\n        vec3 _1101 = _1020.xyz;\n        vec3 _1103 = _1101 - world_pos;\n        vec3 to_light = _1103;\n        float _1106 = length(_1103);\n        float reach = _1106;\n        bool front = true;\n        if (_1040)\n        {\n            int param_8 = _1012 + 7;\n            reach = max(_1106 - fa_light_texel(param_8).w, 0.0);\n            int param_9 = _1012 + 4;\n            vec4 _1130 = fa_light_texel(param_9);\n            int param_10 = _1012 + 5;\n            vec4 _1135 = fa_light_texel(param_10);\n            int param_11 = _1012 + 6;\n            vec4 _1140 = fa_light_texel(param_11);\n            float _1141 = _1140.w;\n            int param_12 = _1012 + 2;\n            vec3 _1148 = normalize(fa_light_texel(param_12).xyz);\n            bool _1150 = _1141 > 1.5;\n            bool _1158;\n            if (!_1150)\n            {\n                _1158 = dot(_1148, to_light) < 0.0;\n            }\n            else\n            {\n                _1158 = _1150;\n            }\n            front = _1158;\n            vec3 r = vec3(0.0);\n            vec3 _1167 = fa_mesh_fs_params[0].xyz - world_pos;\n            bool _1171 = dot(n, n) > 0.5;\n            bool _1179;\n            if (_1171)\n            {\n                _1179 = dot(_1167, _1167) > 9.9999999600419720025001879548654e-13;\n            }\n            else\n            {\n                _1179 = _1171;\n            }\n            if (_1179)\n            {\n                r = reflect(-normalize(_1167), normalize(n));\n            }\n            vec3 param_13 = _1101;\n            vec3 param_14 = _1148;\n            vec3 param_15 = _1130.xyz;\n            vec3 param_16 = _1135.xyz;\n            float param_17 = _1130.w;\n            float param_18 = _1135.w;\n            float param_19 = _1141;\n            vec3 param_20 = world_pos;\n            vec3 param_21 = r;\n            to_light = fa_area_point(param_13, param_14, param_15, param_16, param_17, param_18, param_19, param_20, param_21) - world_pos;\n        }\n        float _1215 = length(to_light);\n        dist = _1215;\n        l = to_light / vec3(max(_1215, 9.9999997473787516355514526367188e-05));\n        float _1229 = reach / max(_1020.w, 0.001000000047497451305389404296875);\n        float _1235 = clamp(1.0 - (_1229 * _1229), 0.0, 1.0);\n        float _1237;\n        if (front)\n        {\n            _1237 = _1235 * _1235;\n        }\n        else\n        {\n            _1237 = 0.0;\n        }\n        atten = _1237;\n        bool _1248 = _1028 < 2.5;\n        if ((_1028 > 1.5) && _1248)\n        {\n            int param_22 = _1012 + 2;\n            vec4 _1256 = fa_light_texel(param_22);\n            float _1266 = _1256.w;\n            int param_23 = _1012 + 3;\n            vec4 _1271 = fa_light_texel(param_23);\n            float _1272 = _1271.x;\n            float cos_inner = _1272;\n            if (_1272 > 1.5)\n            {\n                cos_inner = mix(_1266, 1.0, 0.25);\n            }\n            atten *= smoothstep(_1266, cos_inner, dot(-l, normalize(_1256.xyz)));\n        }\n        if (_1016 && (_1028 < 1.5))\n        {\n            int param_24 = _1012 + 6;\n            vec4 _1296 = fa_light_texel(param_24);\n            if (_1296.z > 0.5)\n            {\n                vec3 _1304 = -to_light;\n                int param_25 = _1012 + 4;\n                int param_26 = _1012 + 5;\n                vec3 _1318 = fa_light_texel(param_25).xyz;\n                vec3 _1322 = fa_light_texel(param_26).xyz;\n                vec3 _1331 = vec3(dot(_1304, _1318), dot(_1304, _1322), dot(_1304, cross(_1318, _1322)));\n                vec3 param_27 = _1331;\n                int _1335 = fa_cube_face(param_27);\n                int param_28 = _1335;\n                vec3 param_29;\n                vec3 param_30;\n                fa_cube_face_basis(param_28, param_29, param_30);\n                vec2 _1362 = vec2(dot(_1331, cross(param_29, param_30)), dot(_1331, param_30)) / vec2(max(dot(_1331, param_29), 9.9999997473787516355514526367188e-05));\n                int _1366 = _1335 / 3;\n                vec2 param_31 = _1296.xy + (vec2(float(_1335 - (_1366 * 3)), float(_1366)) * 256.0);\n                vec2 param_32 = vec2(0.5 + (0.5 * _1362.x), 0.5 - (0.5 * _1362.y));\n                fa_light_tint = fa_cookie_sample(param_31, param_32);\n            }\n            int param_33 = _1012 + 7;\n            vec4 _1396 = fa_light_texel(param_33);\n            if (_1396.z > 0.5)\n            {\n                int param_34 = _1012 + 2;\n                int param_35 = _1012 + 4;\n                int param_36 = _1012 + 5;\n                vec2 param_37 = _1396.xy;\n                vec3 param_38 = -l;\n                vec3 param_39 = normalize(fa_light_texel(param_34).xyz);\n                vec3 param_40 = fa_light_texel(param_35).xyz;\n                vec3 param_41 = fa_light_texel(param_36).xyz;\n                atten *= fa_ies_sample(param_37, param_38, param_39, param_40, param_41);\n            }\n        }\n        else\n        {\n            if (_1016 && _1248)\n            {\n                int param_42 = _1012 + 6;\n                vec4 _1443 = fa_light_texel(param_42);\n                int param_43 = _1012 + 7;\n                vec4 _1448 = fa_light_texel(param_43);\n                bool _1451 = _1443.z > 0.5;\n                bool _1458;\n                if (!_1451)\n                {\n                    _1458 = _1448.z > 0.5;\n                }\n                else\n                {\n                    _1458 = _1451;\n                }\n                if (_1458)\n                {\n                    int param_44 = _1012 + 2;\n                    vec4 _1465 = fa_light_texel(param_44);\n                    vec3 _1469 = normalize(_1465.xyz);\n                    int param_45 = _1012 + 4;\n                    vec4 _1474 = fa_light_texel(param_45);\n                    int param_46 = _1012 + 5;\n                    vec4 _1479 = fa_light_texel(param_46);\n                    if (_1451)\n                    {\n                        vec3 _1487 = -to_light;\n                        float _1494 = _1465.w;\n                        float _1510 = 0.5 / max(dot(_1487, _1469) * (sqrt(max(1.0 - (_1494 * _1494), 0.0)) / max(_1494, 0.001000000047497451305389404296875)), 9.9999997473787516355514526367188e-05);\n                        vec2 param_47 = _1443.xy;\n                        vec2 param_48 = vec2(0.5 + (dot(_1487, _1474.xyz) * _1510), 0.5 - (dot(_1487, _1479.xyz) * _1510));\n                        fa_light_tint = fa_cookie_sample(param_47, param_48);\n                    }\n                    if (_1448.z > 0.5)\n                    {\n                        vec2 param_49 = _1448.xy;\n                        vec3 param_50 = -l;\n                        vec3 param_51 = _1469;\n                        vec3 param_52 = _1474.xyz;\n                        vec3 param_53 = _1479.xyz;\n                        atten *= fa_ies_sample(param_49, param_50, param_51, param_52, param_53);\n                    }\n                }\n            }\n        }\n    }\n    vec3 _9725 = _1025.xyz * atten;\n    if (_1016)\n    {\n        _9725 *= fa_light_tint;\n    }\n    int _1579;\n    if (_1042)\n    {\n        _1579 = 0;\n    }\n    else\n    {\n        _1579 = ((_1028 > 1.5) && (_1028 < 2.5)) ? 2 : 1;\n    }\n    return LightSample(l, _9725, atten, 1.0, dist, _1579);\n}\n\nfloat fa_shadow_split_at(int i)\n{\n    float _2311;\n    if (i == 0)\n    {\n        _2311 = fa_shadows[24].x;\n    }\n    else\n    {\n        float _2327;\n        if (i == 1)\n        {\n            _2327 = fa_shadows[24].y;\n        }\n        else\n        {\n            float _2335;\n            if (i == 2)\n            {\n                _2335 = fa_shadows[24].z;\n            }\n            else\n            {\n                _2335 = fa_shadows[24].w;\n            }\n            _2327 = _2335;\n        }\n        _2311 = _2327;\n    }\n    return _2311;\n}\n\nfloat fa_shadow_depth(inout vec2 uv, vec4 rect)\n{\n    uv = clamp(uv, rect.xy, rect.zw);\n    return textureLod(fa_shadow_tex_fa_shadow_smp, uv, 0.0).x;\n}\n\nfloat fa_shadow_fetch(vec2 uv, vec4 rect, vec3 conv)\n{\n    vec2 param = uv;\n    vec4 param_1 = rect;\n    float _2368 = fa_shadow_depth(param, param_1);\n    float _2372;\n    if (conv.x < 0.5)\n    {\n        _2372 = _2368;\n    }\n    else\n    {\n        _2372 = (conv.y * conv.z) / (conv.z - (_2368 * (conv.z - conv.y)));\n    }\n    return _2372;\n}\n\nfloat fa_shadow_noise()\n{\n    return fract(52.98291778564453125 * fract(dot(gl_FragCoord.xy, vec2(0.067110560834407806396484375, 0.005837149918079376220703125))));\n}\n\nvec2 fa_shadow_vogel_turn(vec2 d)\n{\n    return vec2((d.x * (-0.737368881702423095703125)) - (d.y * 0.675490319728851318359375), (d.y * (-0.737368881702423095703125)) + (d.x * 0.675490319728851318359375));\n}\n\nfloat fa_shadow_filter(vec2 uv, vec4 rect, float zr, float texel_m, float unit, float reach, float plane, vec3 conv, int mode, float k)\n{\n    if (mode == 1)\n    {\n        vec2 param = uv;\n        vec4 param_1 = rect;\n        vec3 param_2 = conv;\n        return float(zr <= fa_shadow_fetch(param, param_1, param_2));\n    }\n    float _2418 = fa_shadow_noise() * 6.283185482025146484375;\n    vec2 _2424 = vec2(cos(_2418), sin(_2418));\n    vec2 dir = _2424;\n    float radius = 1.5;\n    if (mode == 2)\n    {\n        float _2433;\n        if (k < 0.0)\n        {\n            _2433 = (-k) / max(zr, 0.100000001490116119384765625);\n        }\n        else\n        {\n            _2433 = k;\n        }\n        float _2452 = clamp((_2433 * reach) / texel_m, 3.0, 12.0);\n        float sum = 0.0;\n        float cnt = 0.0;\n        for (int i = 0; i < 16; i++)\n        {\n            float _2471 = sqrt((float(i) + 0.5) * 0.0625) * _2452;\n            vec2 param_3 = uv + (dir * (fa_shadows[26].zw * _2471));\n            vec4 param_4 = rect;\n            vec3 param_5 = conv;\n            float _2485 = fa_shadow_fetch(param_3, param_4, param_5);\n            if (_2485 < (zr - (_2471 * plane)))\n            {\n                sum += _2485;\n                cnt += 1.0;\n            }\n            vec2 param_6 = dir;\n            dir = fa_shadow_vogel_turn(param_6);\n        }\n        if (cnt < 0.5)\n        {\n            return 1.0;\n        }\n        float _2513 = sum / cnt;\n        float _2523;\n        if (k < 0.0)\n        {\n            _2523 = (-k) / max(_2513, 0.0500000007450580596923828125);\n        }\n        else\n        {\n            _2523 = k;\n        }\n        radius = clamp(((max(zr - _2513, 0.0) * unit) * _2523) / texel_m, 1.5, 16.0);\n        dir = _2424;\n    }\n    float lit = 0.0;\n    int _2549 = (mode == 2) ? 24 : 16;\n    for (int i_1 = 0; i_1 < _2549; i_1++)\n    {\n        float _2568 = sqrt((float(i_1) + 0.5) / float(_2549)) * radius;\n        vec2 param_7 = uv + (dir * (fa_shadows[26].zw * _2568));\n        vec4 param_8 = rect;\n        vec3 param_9 = conv;\n        lit += float((zr - (_2568 * plane)) <= fa_shadow_fetch(param_7, param_8, param_9));\n        vec2 param_10 = dir;\n        dir = fa_shadow_vogel_turn(param_10);\n    }\n    return lit / float(_2549);\n}\n\nfloat fa_shadow_cascade(int ci, vec3 world, vec3 n, vec3 l)\n{\n    float _2614 = max(fa_shadows[ci * 1 + 20].y, 0.001000000047497451305389404296875);\n    float _2619 = clamp(dot(n, l), 0.0, 1.0);\n    float _2625 = sqrt(1.0 - (_2619 * _2619));\n    float _2633 = min(_2625 / max(_2619, 0.20000000298023223876953125), 4.0);\n    float _2638;\n    if (fa_shadows[26].y > 0.0)\n    {\n        _2638 = fa_shadows[26].y;\n    }\n    else\n    {\n        _2638 = 1.5 * fa_shadows[ci * 1 + 20].x;\n    }\n    vec4 _2663 = mat4(fa_shadows[ci * 4 + 0], fa_shadows[ci * 4 + 1], fa_shadows[ci * 4 + 2], fa_shadows[ci * 4 + 3]) * vec4(world + (n * (_2638 * _2625)), 1.0);\n    float _2670 = _2663.x;\n    bool _2673 = _2670 < fa_shadows[ci * 1 + 16].x;\n    bool _2682;\n    if (!_2673)\n    {\n        _2682 = _2670 > fa_shadows[ci * 1 + 16].z;\n    }\n    else\n    {\n        _2682 = _2673;\n    }\n    bool _2691;\n    if (!_2682)\n    {\n        _2691 = _2663.y < fa_shadows[ci * 1 + 16].y;\n    }\n    else\n    {\n        _2691 = _2682;\n    }\n    bool _2700;\n    if (!_2691)\n    {\n        _2700 = _2663.y > fa_shadows[ci * 1 + 16].w;\n    }\n    else\n    {\n        _2700 = _2691;\n    }\n    bool _2707;\n    if (!_2700)\n    {\n        _2707 = _2663.z > 1.0;\n    }\n    else\n    {\n        _2707 = _2700;\n    }\n    if (_2707)\n    {\n        return -1.0;\n    }\n    float _2715;\n    if (fa_shadows[26].x > 0.0)\n    {\n        _2715 = fa_shadows[26].x;\n    }\n    else\n    {\n        _2715 = 1.5 * fa_shadows[ci * 1 + 20].x;\n    }\n    vec2 param = _2663.xy;\n    vec4 param_1 = fa_shadows[ci * 1 + 16];\n    float param_2 = _2663.z - ((_2715 * (1.0 + (0.5 * _2633))) / _2614);\n    float param_3 = fa_shadows[ci * 1 + 20].x;\n    float param_4 = _2614;\n    float param_5 = _2614 * 0.25;\n    float param_6 = ((fa_shadows[ci * 1 + 20].x * min(_2633, 3.0)) * 0.5) / _2614;\n    vec3 param_7 = vec3(0.0);\n    int param_8 = int(fa_shadows[25].z + 0.5);\n    float param_9 = fa_shadows[25].w;\n    return fa_shadow_filter(param, param_1, param_2, param_3, param_4, param_5, param_6, param_7, param_8, param_9);\n}\n\nfloat fa_shadow_sun(vec3 world, vec3 n, vec3 l)\n{\n    if (fa_mesh_fs_params[5].z < 0.5)\n    {\n        return 1.0;\n    }\n    int _3093 = int(fa_shadows[25].x + 0.5);\n    if (_3093 < 1)\n    {\n        return 1.0;\n    }\n    float _3108 = dot(world - fa_shadows[27].xyz, fa_shadows[28].xyz);\n    int param = _3093 - 1;\n    if (_3108 > fa_shadow_split_at(param))\n    {\n        return 1.0;\n    }\n    int ci = 0;\n    bool _3120 = _3093 > 1;\n    bool _3127;\n    if (_3120)\n    {\n        _3127 = _3108 > fa_shadows[24].x;\n    }\n    else\n    {\n        _3127 = _3120;\n    }\n    if (_3127)\n    {\n        ci = 1;\n    }\n    bool _3131 = _3093 > 2;\n    bool _3138;\n    if (_3131)\n    {\n        _3138 = _3108 > fa_shadows[24].y;\n    }\n    else\n    {\n        _3138 = _3131;\n    }\n    if (_3138)\n    {\n        ci = 2;\n    }\n    bool _3142 = _3093 > 3;\n    bool _3149;\n    if (_3142)\n    {\n        _3149 = _3108 > fa_shadows[24].z;\n    }\n    else\n    {\n        _3149 = _3142;\n    }\n    if (_3149)\n    {\n        ci = 3;\n    }\n    float s = -1.0;\n    float s2 = -1.0;\n    float t = 0.0;\n    int _3160 = min(_3093, 4);\n    float _3201;\n    for (int c = ci; c < _3160; c++)\n    {\n        int param_1 = c;\n        vec3 param_2 = world;\n        vec3 param_3 = n;\n        vec3 param_4 = l;\n        float _3180 = fa_shadow_cascade(param_1, param_2, param_3, param_4);\n        if (s >= 0.0)\n        {\n            s2 = _3180;\n            break;\n        }\n        if (_3180 < 0.0)\n        {\n            continue;\n        }\n        s = _3180;\n        ci = c;\n        if (fa_shadows[25].y > 0.0)\n        {\n            if (ci > 0)\n            {\n                int param_5 = ci - 1;\n                _3201 = fa_shadow_split_at(param_5);\n            }\n            else\n            {\n                _3201 = fa_shadows[28].w;\n            }\n            int param_6 = ci;\n            float _3220 = fa_shadows[25].y * max(fa_shadow_split_at(param_6) - _3201, 9.9999997473787516355514526367188e-05);\n            int param_7 = ci;\n            t = clamp((_3108 - (fa_shadow_split_at(param_7) - _3220)) / _3220, 0.0, 1.0);\n        }\n        if (t <= 0.0)\n        {\n            break;\n        }\n    }\n    if (s < 0.0)\n    {\n        return 1.0;\n    }\n    if (t > 0.0)\n    {\n        float _3252;\n        if ((ci + 1) < _3093)\n        {\n            _3252 = (s2 < 0.0) ? s : s2;\n        }\n        else\n        {\n            _3252 = 1.0;\n        }\n        s = mix(s, _3252, t);\n    }\n    return s;\n}\n\nfloat fa_shadow_factor(vec3 n, vec3 l)\n{\n    bool _3357 = fa_mesh_fs_params[25].y > 0.5;\n    bool _3363;\n    if (_3357)\n    {\n        _3363 = fa_mesh_fs_params[5].z > 0.5;\n    }\n    else\n    {\n        _3363 = _3357;\n    }\n    if (_3363)\n    {\n        float _3377 = dot(fa_mesh_fs_params[29].xyz, fa_world_pos) + fa_mesh_fs_params[29].w;\n        vec4 _3385 = vec4(fa_world_pos, 1.0);\n        float _3391 = dot(fa_mesh_fs_params[28], _3385);\n        if (_3391 > 9.9999997473787516355514526367188e-05)\n        {\n            vec2 _3410 = vec2(dot(fa_mesh_fs_params[26], _3385), dot(fa_mesh_fs_params[27], _3385)) / vec2(_3391);\n            float _3415 = (_3410.x * 0.5) + 0.5;\n            float _3419;\n            if (fa_mesh_fs_params[24].y > 0.5)\n            {\n                _3419 = (_3410.y * 0.5) + 0.5;\n            }\n            else\n            {\n                _3419 = 0.5 - (_3410.y * 0.5);\n            }\n            bool _3435 = _3415 >= 0.0;\n            bool _3441;\n            if (_3435)\n            {\n                _3441 = _3415 < 1.0;\n            }\n            else\n            {\n                _3441 = _3435;\n            }\n            bool _3447;\n            if (_3441)\n            {\n                _3447 = _3419 >= 0.0;\n            }\n            else\n            {\n                _3447 = _3441;\n            }\n            bool _3453;\n            if (_3447)\n            {\n                _3453 = _3419 < 1.0;\n            }\n            else\n            {\n                _3453 = _3447;\n            }\n            if (_3453)\n            {\n                vec4 _3479 = texelFetch(fa_screen_tex_fa_shadow_smp, clamp(ivec2(vec2(_3415, _3419) * fa_mesh_fs_params[24].zw), ivec2(0), ivec2(fa_mesh_fs_params[24].zw) - ivec2(1)), 0);\n                bool _3482 = _3479.w > 0.5;\n                bool _3498;\n                if (_3482)\n                {\n                    _3498 = abs(_3377 - _3479.x) <= (((0.00200000009499490261077880859375 * _3377) + 0.00999999977648258209228515625) + fa_rt_slope);\n                }\n                else\n                {\n                    _3498 = _3482;\n                }\n                if (_3498)\n                {\n                    float _3504;\n                    if (fa_mesh_fs_params[25].z > 0.5)\n                    {\n                        vec3 param = fa_world_pos;\n                        vec3 param_1 = n;\n                        vec3 param_2 = l;\n                        _3504 = min(_3479.y, fa_shadow_sun(param, param_1, param_2));\n                    }\n                    else\n                    {\n                        _3504 = _3479.y;\n                    }\n                    return _3504;\n                }\n            }\n        }\n    }\n    vec3 param_3 = fa_world_pos;\n    vec3 param_4 = n;\n    vec3 param_5 = l;\n    return fa_shadow_sun(param_3, param_4, param_5);\n}\n\nfloat fa_shadow_local(int li, vec3 lpos, vec3 world, vec3 n, vec3 l)\n{\n    bool _2773 = fa_mesh_fs_params[5].z < 0.5;\n    bool _2780;\n    if (!_2773)\n    {\n        _2780 = fa_shadows[29].x < 0.5;\n    }\n    else\n    {\n        _2780 = _2773;\n    }\n    if (_2780)\n    {\n        return 1.0;\n    }\n    int param = (int(fa_shadows[29].x + 0.5) - 1) + li;\n    vec4 _2793 = fa_light_texel(param);\n    float _2794 = _2793.x;\n    if (_2794 < 0.0)\n    {\n        return 1.0;\n    }\n    int _2803 = int(_2794 + 0.5);\n    int param_1 = _2803;\n    vec4 _2807 = fa_light_texel(param_1);\n    int param_2 = _2803 + 1;\n    vec4 _2812 = fa_light_texel(param_2);\n    float fade = 1.0;\n    float _2815 = _2807.y;\n    if (_2815 > 0.0)\n    {\n        float _2832 = 1.0 - smoothstep(0.75 * _2815, _2815, length(world - fa_shadows[27].xyz));\n        fade = _2832;\n        if (_2832 <= 0.0)\n        {\n            return 1.0;\n        }\n    }\n    int face = 0;\n    if (_2807.x > 1.5)\n    {\n        vec3 param_3 = world - lpos;\n        face = fa_cube_face(param_3);\n    }\n    int _2856 = (_2803 + 2) + (face * 6);\n    int param_4 = _2856;\n    int param_5 = _2856 + 1;\n    int param_6 = _2856 + 3;\n    vec4 _2870 = fa_light_texel(param_6);\n    int param_7 = _2856 + 4;\n    vec4 _2875 = fa_light_texel(param_7);\n    int param_8 = _2856 + 5;\n    vec4 _2880 = fa_light_texel(param_8);\n    float _2892 = _2880.x * max(dot(_2870, vec4(world, 1.0)), 0.001000000047497451305389404296875);\n    float _2897 = clamp(dot(n, l), 0.0, 1.0);\n    float _2920 = clamp(dot(n, _2870.xyz), -1.0, 1.0);\n    float _2939 = min(sqrt(1.0 - (_2920 * _2920)) / max(abs(dot(n, world - lpos)) / max(dot(_2870, vec4(world, 1.0)), 0.001000000047497451305389404296875), 0.20000000298023223876953125), 4.0);\n    float _2942 = _2812.y;\n    float _2944;\n    if (_2942 > 0.0)\n    {\n        _2944 = _2942;\n    }\n    else\n    {\n        _2944 = 1.5 * _2892;\n    }\n    vec4 _2964 = vec4(world + (n * (_2944 * sqrt(1.0 - (_2897 * _2897)))), 1.0);\n    float _2968 = dot(_2870, _2964);\n    float _2971 = _2880.y;\n    if (_2968 < _2971)\n    {\n        return 1.0;\n    }\n    vec2 _2986 = vec2(dot(fa_light_texel(param_4), _2964), dot(fa_light_texel(param_5), _2964)) / vec2(_2968);\n    float _2988 = _2986.x;\n    bool _2991 = _2988 < _2875.x;\n    bool _3000;\n    if (!_2991)\n    {\n        _3000 = _2988 > _2875.z;\n    }\n    else\n    {\n        _3000 = _2991;\n    }\n    bool _3009;\n    if (!_3000)\n    {\n        _3009 = _2986.y < _2875.y;\n    }\n    else\n    {\n        _3009 = _3000;\n    }\n    bool _3018;\n    if (!_3009)\n    {\n        _3018 = _2986.y > _2875.w;\n    }\n    else\n    {\n        _3018 = _3009;\n    }\n    if (_3018)\n    {\n        return 1.0;\n    }\n    float _3024 = _2812.x;\n    float _3026;\n    if (_3024 > 0.0)\n    {\n        _3026 = _3024;\n    }\n    else\n    {\n        _3026 = 1.5 * _2892;\n    }\n    vec2 param_9 = _2986;\n    vec4 param_10 = _2875;\n    float param_11 = _2968 - (_3026 * (1.0 + (0.5 * _2939)));\n    float param_12 = _2892;\n    float param_13 = 1.0;\n    float param_14 = _2880.z * 0.25;\n    float param_15 = (_2892 * min(_2939, 3.0)) * 0.5;\n    vec3 param_16 = vec3(1.0, _2971, _2880.z);\n    int param_17 = int(_2807.z + 0.5);\n    float param_18 = _2807.w;\n    return mix(1.0, fa_shadow_filter(param_9, param_10, param_11, param_12, param_13, param_14, param_15, param_16, param_17, param_18), fade);\n}\n\nfloat fa_shadow_local_rt(int li, vec3 lpos, vec3 world, vec3 n, vec3 l)\n{\n    bool _3533 = fa_mesh_fs_params[25].w > 0.5;\n    bool _3539;\n    if (_3533)\n    {\n        _3539 = fa_mesh_fs_params[5].z > 0.5;\n    }\n    else\n    {\n        _3539 = _3533;\n    }\n    bool _3545;\n    if (_3539)\n    {\n        _3545 = fa_shadows[29].x > 0.5;\n    }\n    else\n    {\n        _3545 = _3539;\n    }\n    if (_3545)\n    {\n        int param = (int(fa_shadows[29].x + 0.5) - 1) + li;\n        vec4 _3557 = fa_light_texel(param);\n        float _3558 = _3557.z;\n        if (_3558 > 0.5)\n        {\n            float _3571 = dot(fa_mesh_fs_params[29].xyz, world) + fa_mesh_fs_params[29].w;\n            float _3577 = ((0.00200000009499490261077880859375 * _3571) + 0.00999999977648258209228515625) + fa_rt_slope;\n            vec4 _3583 = vec4(world, 1.0);\n            float _3588 = dot(fa_mesh_fs_params[28], _3583);\n            if (_3588 > 9.9999997473787516355514526367188e-05)\n            {\n                vec2 _3605 = vec2(dot(fa_mesh_fs_params[26], _3583), dot(fa_mesh_fs_params[27], _3583)) / vec2(_3588);\n                float _3610 = (_3605.x * 0.5) + 0.5;\n                float _3614;\n                if (fa_mesh_fs_params[24].y > 0.5)\n                {\n                    _3614 = (_3605.y * 0.5) + 0.5;\n                }\n                else\n                {\n                    _3614 = 0.5 - (_3605.y * 0.5);\n                }\n                bool _3630 = _3610 >= 0.0;\n                bool _3636;\n                if (_3630)\n                {\n                    _3636 = _3610 < 1.0;\n                }\n                else\n                {\n                    _3636 = _3630;\n                }\n                bool _3642;\n                if (_3636)\n                {\n                    _3642 = _3614 >= 0.0;\n                }\n                else\n                {\n                    _3642 = _3636;\n                }\n                bool _3648;\n                if (_3642)\n                {\n                    _3648 = _3614 < 1.0;\n                }\n                else\n                {\n                    _3648 = _3642;\n                }\n                if (_3648)\n                {\n                    ivec2 _3665 = ivec2(fa_mesh_fs_params[24].zw) - ivec2(1);\n                    ivec2 _3666 = clamp(ivec2(vec2(_3610, _3614) * fa_mesh_fs_params[24].zw), ivec2(0), _3665);\n                    float _3670;\n                    if (_3558 < 1.5)\n                    {\n                        _3670 = 1.0;\n                    }\n                    else\n                    {\n                        _3670 = (_3558 < 2.5) ? 256.0 : 65536.0;\n                    }\n                    float best = 2.0;\n                    int _3692;\n                    int _3698;\n                    for (int k = 0; k < 9; k++)\n                    {\n                        if (k == 0)\n                        {\n                            _3692 = 4;\n                        }\n                        else\n                        {\n                            if (k <= 4)\n                            {\n                                _3698 = k - 1;\n                            }\n                            else\n                            {\n                                _3698 = k;\n                            }\n                            _3692 = _3698;\n                        }\n                        vec4 _3727 = texelFetch(fa_screen_tex_fa_shadow_smp, clamp(_3666 + ivec2((_3692 % 3) - 1, (_3692 / 3) - 1), ivec2(0), _3665), 0);\n                        bool _3730 = _3727.w > 0.5;\n                        bool _3740;\n                        if (_3730)\n                        {\n                            _3740 = abs(_3571 - _3727.x) <= _3577;\n                        }\n                        else\n                        {\n                            _3740 = _3730;\n                        }\n                        if (_3740)\n                        {\n                            best = min(best, mod(floor(_3727.z / _3670), 256.0) * 0.0039215688593685626983642578125);\n                            if (k == 0)\n                            {\n                                break;\n                            }\n                        }\n                    }\n                    if (best <= 1.0)\n                    {\n                        float _3767;\n                        if (fa_mesh_fs_params[25].z > 0.5)\n                        {\n                            int param_1 = li;\n                            vec3 param_2 = lpos;\n                            vec3 param_3 = world;\n                            vec3 param_4 = n;\n                            vec3 param_5 = l;\n                            _3767 = min(best, fa_shadow_local(param_1, param_2, param_3, param_4, param_5));\n                        }\n                        else\n                        {\n                            _3767 = best;\n                        }\n                        return _3767;\n                    }\n                }\n            }\n            float _3790;\n            if (fa_mesh_fs_params[25].z > 0.5)\n            {\n                int param_6 = li;\n                vec3 param_7 = lpos;\n                vec3 param_8 = world;\n                vec3 param_9 = n;\n                vec3 param_10 = l;\n                _3790 = fa_shadow_local(param_6, param_7, param_8, param_9, param_10);\n            }\n            else\n            {\n                _3790 = 1.0;\n            }\n            return _3790;\n        }\n    }\n    int param_11 = li;\n    vec3 param_12 = lpos;\n    vec3 param_13 = world;\n    vec3 param_14 = n;\n    vec3 param_15 = l;\n    return fa_shadow_local(param_11, param_12, param_13, param_14, param_15);\n}\n\nfloat fa_contact_shadow(int li, vec3 world, vec3 gn, vec3 l, float dist)\n{\n    bool _5634 = fa_mesh_fs_params[24].x < 0.5;\n    bool _5641;\n    if (!_5634)\n    {\n        _5641 = fa_shadows[29].x < 0.5;\n    }\n    else\n    {\n        _5641 = _5634;\n    }\n    if (_5641)\n    {\n        return 1.0;\n    }\n    int param = (int(fa_shadows[29].x + 0.5) - 1) + li;\n    vec4 _5654 = fa_light_texel(param);\n    float _5655 = _5654.y;\n    float len = _5655;\n    if (_5655 <= 0.0)\n    {\n        return 1.0;\n    }\n    float _5667 = length(world - fa_mesh_fs_params[0].xyz);\n    float _5676 = 1.0 - smoothstep(0.5 * fa_mesh_fs_params[25].x, fa_mesh_fs_params[25].x, _5667);\n    if (_5676 <= 0.0)\n    {\n        return 1.0;\n    }\n    float _5682 = len;\n    float _5685 = min(_5682, 0.89999997615814208984375 * dist);\n    len = _5685;\n    float _5690 = 0.004999999888241291046142578125 + (0.0030000000260770320892333984375 * _5667);\n    float _5695 = _5690 + (0.5 * _5685);\n    vec3 _5701 = world + (gn * _5690);\n    float _5703 = fa_shadow_noise();\n    float occ = 0.0;\n    float _5764;\n    for (int k = 0; k < 12; k++)\n    {\n        float _5718 = (float(k) + _5703) * 0.083333335816860198974609375;\n        vec3 _5726 = _5701 + (l * (_5718 * len));\n        vec4 _5732 = vec4(_5726, 1.0);\n        float _5737 = dot(fa_mesh_fs_params[28], _5732);\n        if (_5737 < 9.9999997473787516355514526367188e-05)\n        {\n            break;\n        }\n        vec2 _5755 = vec2(dot(fa_mesh_fs_params[26], _5732), dot(fa_mesh_fs_params[27], _5732)) / vec2(_5737);\n        float _5759 = _5755.x * 0.5;\n        float _5760 = _5759 + 0.5;\n        if (fa_mesh_fs_params[24].y > 0.5)\n        {\n            _5764 = (_5755.y * 0.5) + 0.5;\n        }\n        else\n        {\n            _5764 = 0.5 - (_5755.y * 0.5);\n        }\n        bool _5780 = _5760 < 0.0;\n        bool _5787;\n        if (!_5780)\n        {\n            _5787 = _5760 >= 1.0;\n        }\n        else\n        {\n            _5787 = _5780;\n        }\n        bool _5794;\n        if (!_5787)\n        {\n            _5794 = _5764 < 0.0;\n        }\n        else\n        {\n            _5794 = _5787;\n        }\n        bool _5801;\n        if (!_5794)\n        {\n            _5801 = _5764 >= 1.0;\n        }\n        else\n        {\n            _5801 = _5794;\n        }\n        if (_5801)\n        {\n            break;\n        }\n        vec4 _5825 = texelFetch(fa_screen_tex_fa_shadow_smp, clamp(ivec2(vec2(_5760, _5764) * fa_mesh_fs_params[24].zw), ivec2(0), ivec2(fa_mesh_fs_params[24].zw) - ivec2(1)), 0);\n        if (_5825.w < 0.5)\n        {\n            continue;\n        }\n        float _5843 = (dot(fa_mesh_fs_params[29].xyz, _5726) + fa_mesh_fs_params[29].w) - _5825.x;\n        if ((_5843 > _5690) && (_5843 < _5695))\n        {\n            occ = max(occ, (1.0 - (_5718 * _5718)) * smoothstep(0.0, 0.0500000007450580596923828125, min(min(_5760, 0.5 - _5759), min(_5764, 1.0 - _5764))));\n        }\n    }\n    return 1.0 - (occ * _5676);\n}\n\nLightSample fa_light_shadowed(int li, vec3 world_pos, vec3 gn)\n{\n    int param = li;\n    float _6505 = fa_baked_keep(param);\n    if (_6505 <= 0.0)\n    {\n        int param_1 = li;\n        return LightSample(vec3(0.0, 1.0, 0.0), vec3(0.0), 0.0, 1.0, 0.0, int(fa_light_type(param_1) + 0.5));\n    }\n    int param_2 = li;\n    vec3 param_3 = world_pos;\n    vec3 param_4 = gn;\n    LightSample _6531 = fa_light_sample_n(param_2, param_3, param_4);\n    vec3 _9794 = _6531.color;\n    float _9795 = _6531.attenuation;\n    float _9796 = _6531.shadow;\n    bool _6534 = _6531.type == 0;\n    if (_6534 && (li == 0))\n    {\n        vec3 param_5 = gn;\n        vec3 param_6 = _6531.direction;\n        float _6545 = fa_shadow_factor(param_5, param_6);\n        _9796 = _6545;\n        _9794 *= _6545;\n    }\n    else\n    {\n        bool _6556 = _6531.type != 0;\n        bool _6562;\n        if (_6556)\n        {\n            _6562 = _9795 > 0.0;\n        }\n        else\n        {\n            _6562 = _6556;\n        }\n        if (_6562)\n        {\n            int param_7 = li;\n            int param_8 = fa_light_base(param_7);\n            int param_9 = li;\n            vec3 param_10 = fa_light_texel(param_8).xyz;\n            vec3 param_11 = world_pos;\n            vec3 param_12 = gn;\n            vec3 param_13 = _6531.direction;\n            float _6581 = fa_shadow_local_rt(param_9, param_10, param_11, param_12, param_13);\n            _9796 = _6581;\n            _9794 *= _6581;\n        }\n    }\n    bool _6591 = fa_mesh_fs_params[24].x > 0.5;\n    bool _6597;\n    if (_6591)\n    {\n        _6597 = _9795 > 0.0;\n    }\n    else\n    {\n        _6597 = _6591;\n    }\n    if (_6597)\n    {\n        float _6604;\n        if (_6534)\n        {\n            _6604 = 1000000000.0;\n        }\n        else\n        {\n            _6604 = _6531._distance;\n        }\n        int param_14 = li;\n        vec3 param_15 = world_pos;\n        vec3 param_16 = gn;\n        vec3 param_17 = _6531.direction;\n        float param_18 = _6604;\n        float _6622 = fa_contact_shadow(param_14, param_15, param_16, param_17, param_18);\n        _9796 *= _6622;\n        _9794 *= _6622;\n    }\n    float _6635 = _9795;\n    float _6636 = _6635 * _6505;\n    _9795 = _6636;\n    vec3 _6640 = _9794;\n    vec3 _6641 = _6640 * _6505;\n    _9794 = _6641;\n    return LightSample(_6531.direction, _6641, _6636, _9796, _6531._distance, _6531.type);\n}\n\nvec3 fa_ltc_tangent(vec3 n, vec3 v)\n{\n    vec3 _6675 = v - (n * dot(v, n));\n    vec3 t = _6675;\n    float _6679 = dot(_6675, _6675);\n    float l2 = _6679;\n    if (_6679 < 1.0000000133514319600180897396058e-10)\n    {\n        vec3 _6689;\n        if (abs(n.z) < 0.999000012874603271484375)\n        {\n            _6689 = cross(n, vec3(0.0, 0.0, 1.0));\n        }\n        else\n        {\n            _6689 = cross(n, vec3(1.0, 0.0, 0.0));\n        }\n        t = _6689;\n        l2 = dot(_6689, _6689);\n    }\n    return t * inversesqrt(l2);\n}\n\nvec3 fa_ltc_local(vec3 t1, vec3 n, vec3 p)\n{\n    return vec3(dot(t1, p), dot(cross(n, t1), p), dot(n, p));\n}\n\nvec2 fa_ltc_uv(float roughness, float ndv)\n{\n    return ((vec2(clamp((roughness - 0.0500000007450580596923828125) * 1.0526316165924072265625, 0.0, 1.0), sqrt(clamp(1.0 - ndv, 0.0, 1.0))) * 63.0) + vec2(0.5)) * vec2(0.015625);\n}\n\nvec3 fa_oct_vertex(int j, vec3 pc, vec3 ex, vec3 ey)\n{\n    float _7076;\n    if ((j == 0) || (j == 7))\n    {\n        _7076 = 0.92387950420379638671875;\n    }\n    else\n    {\n        float _7086;\n        if ((j == 3) || (j == 4))\n        {\n            _7086 = -0.92387950420379638671875;\n        }\n        else\n        {\n            _7086 = ((j == 1) || (j == 6)) ? 0.3826834261417388916015625 : (-0.3826834261417388916015625);\n        }\n        _7076 = _7086;\n    }\n    float _7107;\n    if ((j == 1) || (j == 2))\n    {\n        _7107 = 0.92387950420379638671875;\n    }\n    else\n    {\n        float _7116;\n        if ((j == 5) || (j == 6))\n        {\n            _7116 = -0.92387950420379638671875;\n        }\n        else\n        {\n            _7116 = ((j == 0) || (j == 3)) ? 0.3826834261417388916015625 : (-0.3826834261417388916015625);\n        }\n        _7107 = _7116;\n    }\n    return (pc + (ex * _7076)) + (ey * _7107);\n}\n\nvec3 fa_ltc_edge_vector(vec3 a, vec3 b)\n{\n    float _6724 = dot(a, a);\n    float _6728 = dot(b, b);\n    if ((_6724 < 1.0000000195414813782625560981111e-24) || (_6728 < 1.0000000195414813782625560981111e-24))\n    {\n        return vec3(0.0);\n    }\n    vec3 _6742 = a * inversesqrt(_6724);\n    vec3 _6747 = b * inversesqrt(_6728);\n    float _6751 = dot(_6742, _6747);\n    float _6754 = abs(_6751);\n    float g = (((((((((((0.0416471660137176513671875 * _6754) - 0.1924748718738555908203125) * _6754) + 0.4179156124591827392578125) * _6754) - 0.616057217121124267578125) * _6754) + 0.777722418308258056640625) * _6754) - 0.999542415142059326171875) * _6754) + 1.570791721343994140625;\n    if (_6751 < 0.0)\n    {\n        g = (3.1415927410125732421875 * inversesqrt(max(1.0 - (_6751 * _6751), 1.0000000116860974230803549289703e-07))) - g;\n    }\n    return cross(_6742, _6747) * g;\n}\n\nvoid fa_ltc_clip_edge(vec3 a, vec3 b, inout vec3 sum, inout vec3 leave, inout vec3 enter, inout vec2 seen)\n{\n    bool _6811 = a.z > 0.0;\n    bool _6815 = b.z > 0.0;\n    if (_6811 && _6815)\n    {\n        vec3 param = a;\n        vec3 param_1 = b;\n        sum += fa_ltc_edge_vector(param, param_1);\n    }\n    else\n    {\n        if (_6811 != _6815)\n        {\n            vec3 _6850 = a + ((b - a) * (a.z / (a.z - b.z)));\n            _6850.z = 0.0;\n            if (_6811)\n            {\n                vec3 param_2 = a;\n                vec3 param_3 = _6850;\n                sum += fa_ltc_edge_vector(param_2, param_3);\n                leave = _6850;\n                seen.x = 1.0;\n            }\n            else\n            {\n                vec3 param_4 = _6850;\n                vec3 param_5 = b;\n                sum += fa_ltc_edge_vector(param_4, param_5);\n                enter = _6850;\n                seen.y = 1.0;\n            }\n        }\n    }\n}\n\nfloat fa_ltc_quad(vec4 abcd, vec3 p0, vec3 p1, vec3 p2, vec3 p3)\n{\n    vec3 _6899 = vec3((abcd.x * p0.x) + (abcd.y * p0.z), p0.y, (abcd.z * p0.x) + (abcd.w * p0.z));\n    vec3 _6925 = vec3((abcd.x * p1.x) + (abcd.y * p1.z), p1.y, (abcd.z * p1.x) + (abcd.w * p1.z));\n    vec3 _6951 = vec3((abcd.x * p2.x) + (abcd.y * p2.z), p2.y, (abcd.z * p2.x) + (abcd.w * p2.z));\n    vec3 _6977 = vec3((abcd.x * p3.x) + (abcd.y * p3.z), p3.y, (abcd.z * p3.x) + (abcd.w * p3.z));\n    vec3 sum = vec3(0.0);\n    vec3 leave = vec3(0.0);\n    vec3 enter = vec3(0.0);\n    vec3 param = _6899;\n    vec3 param_1 = _6925;\n    vec3 param_2 = vec3(0.0);\n    vec3 param_3 = vec3(0.0);\n    vec3 param_4 = vec3(0.0);\n    vec2 param_5 = vec2(0.0);\n    fa_ltc_clip_edge(param, param_1, param_2, param_3, param_4, param_5);\n    sum = param_2;\n    leave = param_3;\n    enter = param_4;\n    vec3 param_6 = _6925;\n    vec3 param_7 = _6951;\n    vec3 param_8 = param_2;\n    vec3 param_9 = param_3;\n    vec3 param_10 = param_4;\n    vec2 param_11 = param_5;\n    fa_ltc_clip_edge(param_6, param_7, param_8, param_9, param_10, param_11);\n    sum = param_8;\n    leave = param_9;\n    enter = param_10;\n    vec3 param_12 = _6951;\n    vec3 param_13 = _6977;\n    vec3 param_14 = param_8;\n    vec3 param_15 = param_9;\n    vec3 param_16 = param_10;\n    vec2 param_17 = param_11;\n    fa_ltc_clip_edge(param_12, param_13, param_14, param_15, param_16, param_17);\n    sum = param_14;\n    leave = param_15;\n    enter = param_16;\n    vec3 param_18 = _6977;\n    vec3 param_19 = _6899;\n    vec3 param_20 = param_14;\n    vec3 param_21 = param_15;\n    vec3 param_22 = param_16;\n    vec2 param_23 = param_17;\n    fa_ltc_clip_edge(param_18, param_19, param_20, param_21, param_22, param_23);\n    sum = param_20;\n    leave = param_21;\n    enter = param_22;\n    if ((param_23.x * param_23.y) > 0.5)\n    {\n        vec3 param_24 = leave;\n        vec3 param_25 = enter;\n        sum += fa_ltc_edge_vector(param_24, param_25);\n    }\n    return sum.z * 0.15915493667125701904296875;\n}\n\nvec2 fa_area_forms(vec4 m, float shape, vec3 pc, vec3 ex, vec3 ey)\n{\n    int _7145 = ((shape < 0.5) || (shape > 1.5)) ? 1 : 3;\n    vec2 sum = vec2(0.0);\n    int _7163;\n    for (int k = 0; k < (2 * _7145); k++)\n    {\n        bool _7160 = k >= _7145;\n        if (_7160)\n        {\n            _7163 = k - _7145;\n        }\n        else\n        {\n            _7163 = k;\n        }\n        vec3 p0 = (pc - ex) - ey;\n        vec3 p1 = (pc + ex) - ey;\n        vec3 p2 = (pc + ex) + ey;\n        vec3 p3 = (pc - ex) + ey;\n        if (_7145 == 3)\n        {\n            int param = 0;\n            vec3 param_1 = pc;\n            vec3 param_2 = ex;\n            vec3 param_3 = ey;\n            p0 = fa_oct_vertex(param, param_1, param_2, param_3);\n            int _7209 = 2 * _7163;\n            int param_4 = _7209 + 1;\n            vec3 param_5 = pc;\n            vec3 param_6 = ex;\n            vec3 param_7 = ey;\n            p1 = fa_oct_vertex(param_4, param_5, param_6, param_7);\n            int param_8 = _7209 + 2;\n            vec3 param_9 = pc;\n            vec3 param_10 = ex;\n            vec3 param_11 = ey;\n            p2 = fa_oct_vertex(param_8, param_9, param_10, param_11);\n            int param_12 = _7209 + 3;\n            vec3 param_13 = pc;\n            vec3 param_14 = ex;\n            vec3 param_15 = ey;\n            p3 = fa_oct_vertex(param_12, param_13, param_14, param_15);\n        }\n        bvec4 _7246 = bvec4(_7160);\n        vec4 param_16 = vec4(_7246.x ? m.x : vec4(1.0, 0.0, 0.0, 1.0).x, _7246.y ? m.y : vec4(1.0, 0.0, 0.0, 1.0).y, _7246.z ? m.z : vec4(1.0, 0.0, 0.0, 1.0).z, _7246.w ? m.w : vec4(1.0, 0.0, 0.0, 1.0).w);\n        vec3 param_17 = p0;\n        vec3 param_18 = p1;\n        vec3 param_19 = p2;\n        vec3 param_20 = p3;\n        float _7257 = fa_ltc_quad(param_16, param_17, param_18, param_19, param_20);\n        if (_7160)\n        {\n            vec2 _10047 = sum;\n            _10047.y = _10047.y + _7257;\n            sum = _10047;\n        }\n        else\n        {\n            vec2 _10050 = sum;\n            _10050.x = _10050.x + _7257;\n            sum = _10050;\n        }\n    }\n    return abs(sum);\n}\n\nvec3 fa_area_shade(int li, vec3 world_pos, vec3 n, vec3 v, vec3 diffuse_color, vec3 f0, float f90, float roughness, float ndv, float window)\n{\n    int param = li;\n    int _7281 = fa_light_base(param);\n    int param_1 = _7281;\n    int param_2 = _7281 + 1;\n    int param_3 = _7281 + 2;\n    int param_4 = _7281 + 4;\n    vec4 _7303 = fa_light_texel(param_4);\n    int param_5 = _7281 + 5;\n    vec4 _7308 = fa_light_texel(param_5);\n    int param_6 = _7281 + 6;\n    vec4 _7313 = fa_light_texel(param_6);\n    float _7314 = _7313.w;\n    vec3 _7319 = fa_light_texel(param_1).xyz - world_pos;\n    bool _7321 = _7314 < 1.5;\n    bool _7328;\n    if (_7321)\n    {\n        _7328 = dot(normalize(fa_light_texel(param_3).xyz), _7319) >= 0.0;\n    }\n    else\n    {\n        _7328 = _7321;\n    }\n    if (_7328)\n    {\n        return vec3(0.0);\n    }\n    bool _7337 = (_7314 > 0.5) && _7321;\n    float _7341 = _7337 ? 1.0539000034332275390625 : 1.0;\n    vec3 _7344 = _7303.xyz;\n    float _7346 = _7303.w;\n    vec3 _7352 = _7308.xyz;\n    float _7354 = _7308.w;\n    vec3 up = _7352 * (_7354 * _7341);\n    float _7360;\n    if (_7337)\n    {\n        _7360 = (3.1415927410125732421875 * _7346) * _7346;\n    }\n    else\n    {\n        _7360 = (4.0 * _7346) * _7354;\n    }\n    if (_7314 > 1.5)\n    {\n        vec3 _7386 = cross(_7344, -_7319);\n        vec3 perp = _7386;\n        float _7390 = dot(_7386, _7386);\n        vec3 _7393;\n        if (_7390 > 1.0000000133514319600180897396058e-10)\n        {\n            _7393 = perp * inversesqrt(_7390);\n        }\n        else\n        {\n            _7393 = _7352;\n        }\n        perp = _7393;\n        up = _7393 * _7354;\n    }\n    float _7414 = max(_7360, 9.9999999747524270787835121154785e-07);\n    vec3 param_7 = n;\n    vec3 param_8 = v;\n    vec3 _7424 = fa_ltc_tangent(param_7, param_8);\n    vec3 param_9 = _7424;\n    vec3 param_10 = n;\n    vec3 param_11 = _7319;\n    vec3 param_12 = _7424;\n    vec3 param_13 = n;\n    vec3 param_14 = _7344 * (_7346 * _7341);\n    vec3 param_15 = _7424;\n    vec3 param_16 = n;\n    vec3 param_17 = up;\n    float param_18 = roughness;\n    float param_19 = ndv;\n    vec2 _7455 = fa_ltc_uv(param_18, param_19) * 64.0;\n    vec2 param_20 = _7455;\n    vec2 param_21 = _7455 + vec2(64.0, 0.0);\n    vec4 _7465 = fa_atlas_fetch(param_21);\n    vec4 param_22 = fa_atlas_fetch(param_20);\n    float param_23 = _7314;\n    vec3 param_24 = fa_ltc_local(param_9, param_10, param_11);\n    vec3 param_25 = fa_ltc_local(param_12, param_13, param_14);\n    vec3 param_26 = fa_ltc_local(param_15, param_16, param_17);\n    vec2 _7477 = fa_area_forms(param_22, param_23, param_24, param_25, param_26);\n    return (((diffuse_color * _7477.x) + (((f0 * _7465.x) + ((vec3(f90) - f0) * _7465.y)) * _7477.y)) * fa_light_texel(param_2).xyz) * ((((3.1415927410125732421875 * dot(_7319, _7319)) + _7414) / _7414) * window);\n}\n\nvec3 fa_light_rgb(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 1;\n    return fa_light_texel(param_1).xyz;\n}\n\nfloat fa_d_charlie(float alpha, float ndh)\n{\n    float _5371 = 1.0 / alpha;\n    return ((2.0 + _5371) * pow(sqrt(max(1.0 - (ndh * ndh), 9.9999997473787516355514526367188e-05)), _5371)) * 0.15915493667125701904296875;\n}\n\nfloat fa_v_ashikhmin(float ndl, float ndv)\n{\n    return clamp(0.25 / max((ndl + ndv) - (ndl * ndv), 9.9999997473787516355514526367188e-05), 0.0, 1.0);\n}\n\nfloat fa_layers_coat(FaLayers L, vec3 l, vec3 h, float vdh)\n{\n    float _5406 = max(dot(L.nc, l), 0.0);\n    float _5412 = max(dot(L.nc, h), 0.0);\n    float _5421 = ((_5412 * _5412) * (L.coat_a2 - 1.0)) + 1.0;\n    return (((L.coat * (0.039999999105930328369140625 + (0.959999978542327880859375 * pow(clamp(1.0 - vdh, 0.0, 1.0), 5.0)))) * (((L.coat_a2 / ((3.1415927410125732421875 * _5421) * _5421)) * (0.5 / max(mix((2.0 * _5406) * L.coat_ndv, _5406 + L.coat_ndv, L.coat_alpha), 9.9999997473787516355514526367188e-05))) * 3.1415927410125732421875)) * step(9.9999997473787516355514526367188e-05, _5406)) * _5406;\n}\n\nvec3 fa_area_layers(FaLayers L, vec3 base, int li, vec3 n, vec3 v, vec3 l, float ndv, float window)\n{\n    float _7514;\n    if (L.sheen_on)\n    {\n        _7514 = L.sheen_scale;\n    }\n    else\n    {\n        _7514 = 1.0;\n    }\n    vec3 result = base * (L.keep * _7514);\n    vec3 _7527 = normalize(l + v);\n    int param = li;\n    vec3 _7538 = fa_light_rgb(param) * window;\n    if (L.sheen_on)\n    {\n        float _7547 = max(dot(n, l), 0.0);\n        float param_1 = L.sheen_alpha;\n        float param_2 = max(dot(n, _7527), 0.0);\n        float param_3 = _7547;\n        float param_4 = ndv;\n        result += ((L.sheen * _7538) * (((((fa_d_charlie(param_1, param_2) * fa_v_ashikhmin(param_3, param_4)) * 3.1415927410125732421875) * step(9.9999997473787516355514526367188e-05, _7547)) * _7547) * L.keep));\n    }\n    if (L.coat > 0.0)\n    {\n        FaLayers param_5 = L;\n        vec3 param_6 = l;\n        vec3 param_7 = _7527;\n        float param_8 = max(dot(v, _7527), 0.0);\n        result += (_7538 * fa_layers_coat(param_5, param_6, param_7, param_8));\n    }\n    return result;\n}\n\nfloat fa_d_ggx_aniso(float ndh, float tdh, float bdh, float at, float ab)\n{\n    float _5274 = tdh / at;\n    float _5278 = bdh / ab;\n    float _5290 = ((_5274 * _5274) + (_5278 * _5278)) + (ndh * ndh);\n    return 1.0 / ((((3.1415927410125732421875 * at) * ab) * _5290) * _5290);\n}\n\nfloat fa_lambda_ggx_aniso(float n, float t, float b, float at, float ab)\n{\n    return 0.5 * (sqrt(1.0 + (((((at * at) * t) * t) + (((ab * ab) * b) * b)) / max(n * n, 9.9999999392252902907785028219223e-09))) - 1.0);\n}\n\nfloat fa_v_ggx_aniso(float ndl, float ndv, float tdv, float bdv, float tdl, float bdl, float at, float ab)\n{\n    float param = ndv;\n    float param_1 = tdv;\n    float param_2 = bdv;\n    float param_3 = at;\n    float param_4 = ab;\n    float param_5 = ndl;\n    float param_6 = tdl;\n    float param_7 = bdl;\n    float param_8 = at;\n    float param_9 = ab;\n    return clamp(1.0 / ((4.0 * max(ndl * ndv, 9.9999997473787516355514526367188e-05)) * ((1.0 + fa_lambda_ggx_aniso(param, param_1, param_2, param_3, param_4)) + fa_lambda_ggx_aniso(param_5, param_6, param_7, param_8, param_9))), 0.0, 1.0);\n}\n\nvec3 fa_layers_light(FaLayers L, vec3 diffuse_color, vec3 f0, vec3 n, vec3 v, vec3 l, vec3 h, float ndl, float ndv, float ndh, float vdh, float alpha, float a2)\n{\n    float _5470 = step(9.9999997473787516355514526367188e-05, ndl);\n    float d_ggx;\n    float vis;\n    if (L.aniso != 0.0)\n    {\n        float param = ndh;\n        float param_1 = dot(L.t, h);\n        float param_2 = dot(L.b, h);\n        float param_3 = L.at;\n        float param_4 = L.ab;\n        d_ggx = fa_d_ggx_aniso(param, param_1, param_2, param_3, param_4);\n        float param_5 = ndl;\n        float param_6 = ndv;\n        float param_7 = dot(L.t, v);\n        float param_8 = dot(L.b, v);\n        float param_9 = dot(L.t, l);\n        float param_10 = dot(L.b, l);\n        float param_11 = L.at;\n        float param_12 = L.ab;\n        vis = fa_v_ggx_aniso(param_5, param_6, param_7, param_8, param_9, param_10, param_11, param_12);\n    }\n    else\n    {\n        float _5549 = ((ndh * ndh) * (a2 - 1.0)) + 1.0;\n        d_ggx = a2 / ((3.1415927410125732421875 * _5549) * _5549);\n        vis = 0.5 / max(mix((2.0 * ndl) * ndv, ndl + ndv, alpha), 9.9999997473787516355514526367188e-05);\n    }\n    vec3 base = diffuse_color + (((f0 + ((vec3(L.f90) - f0) * pow(clamp(1.0 - vdh, 0.0, 1.0), 5.0))) * ((d_ggx * vis) * 3.1415927410125732421875)) * _5470);\n    if (L.sheen_on)\n    {\n        float param_13 = L.sheen_alpha;\n        float param_14 = ndh;\n        float param_15 = ndl;\n        float param_16 = ndv;\n        base = (base * L.sheen_scale) + (L.sheen * (((fa_d_charlie(param_13, param_14) * fa_v_ashikhmin(param_15, param_16)) * 3.1415927410125732421875) * _5470));\n    }\n    vec3 result = base * (L.keep * ndl);\n    if (L.coat > 0.0)\n    {\n        FaLayers param_17 = L;\n        vec3 param_18 = l;\n        vec3 param_19 = h;\n        float param_20 = vdh;\n        result += vec3(fa_layers_coat(param_17, param_18, param_19, param_20));\n    }\n    return result;\n}\n\nvec2 fa_env_brdf(float rough, float ndv)\n{\n    vec4 _4673 = (vec4(-1.0, -0.0274999998509883880615234375, -0.572000026702880859375, 0.02199999988079071044921875) * rough) + vec4(1.0, 0.0425000004470348358154296875, 1.03999996185302734375, -0.039999999105930328369140625);\n    float _4676 = _4673.x;\n    return (vec2(-1.03999996185302734375, 1.03999996185302734375) * ((min(_4676 * _4676, exp2((-9.27999973297119140625) * ndv)) * _4676) + _4673.y)) + _4673.zw;\n}\n\nvec3 fa_probe_level(vec2 origin, float res, int lv, vec2 e)\n{\n    float _3984;\n    if (lv == 0)\n    {\n        _3984 = 0.0;\n    }\n    else\n    {\n        _3984 = res + 2.0;\n    }\n    float _3994;\n    if (lv == 0)\n    {\n        _3994 = 0.0;\n    }\n    else\n    {\n        _3994 = (res - (res / float(1 << max((lv - 1), 0)))) + (2.0 * float(lv - 1));\n    }\n    return textureLod(fa_probe_atlas_fa_env_smp, (((origin + vec2(_3984, _3994)) + vec2(1.0)) + (((e * 0.5) + vec2(0.5)) * (res / float(1 << lv)))) / fa_atlas_size(), 0.0).xyz;\n}\n\nvec3 fa_probe_radiance(vec2 origin, float res, vec3 d, float rough)\n{\n    float _4040;\n    if (res > 64.5)\n    {\n        _4040 = 5.0;\n    }\n    else\n    {\n        _4040 = (res > 32.5) ? 4.0 : 3.0;\n    }\n    float _4055 = clamp(rough, 0.0, 1.0) * (_4040 - 1.0);\n    int _4062 = int(min(floor(_4055), _4040 - 2.0));\n    float _4067 = _4055 - float(_4062);\n    vec3 param = d;\n    vec2 _4071 = fa_oct_encode(param);\n    vec2 param_1 = origin;\n    float param_2 = res;\n    int param_3 = _4062;\n    vec2 param_4 = _4071;\n    vec3 _4081 = fa_probe_level(param_1, param_2, param_3, param_4);\n    if (_4067 < 0.00200000009499490261077880859375)\n    {\n        return _4081;\n    }\n    vec2 param_5 = origin;\n    float param_6 = res;\n    int param_7 = _4062 + 1;\n    vec2 param_8 = _4071;\n    return mix(_4081, fa_probe_level(param_5, param_6, param_7, param_8), vec3(_4067));\n}\n\nvec3 fa_probe_box_dir(vec3 d, vec4 posw, vec4 bx, vec4 by, vec4 bz)\n{\n    if (posw.w < 0.5)\n    {\n        return d;\n    }\n    float _4152 = dot(bx.xyz, fa_world_pos) + bx.w;\n    float _4159 = dot(by.xyz, fa_world_pos) + by.w;\n    float _4166 = dot(bz.xyz, fa_world_pos) + bz.w;\n    float _4172 = dot(bx.xyz, d);\n    float _4176 = dot(by.xyz, d);\n    float _4180 = dot(bz.xyz, d);\n    float _4186;\n    if (_4172 > 9.9999999747524270787835121154785e-07)\n    {\n        _4186 = (1.0 - _4152) / _4172;\n    }\n    else\n    {\n        float _4200;\n        if (_4172 < (-9.9999999747524270787835121154785e-07))\n        {\n            _4200 = ((-1.0) - _4152) / _4172;\n        }\n        else\n        {\n            _4200 = 1000000015047466219876688855040.0;\n        }\n        _4186 = _4200;\n    }\n    float tx = _4186;\n    float _4217;\n    if (_4176 > 9.9999999747524270787835121154785e-07)\n    {\n        _4217 = (1.0 - _4159) / _4176;\n    }\n    else\n    {\n        float _4230;\n        if (_4176 < (-9.9999999747524270787835121154785e-07))\n        {\n            _4230 = ((-1.0) - _4159) / _4176;\n        }\n        else\n        {\n            _4230 = 1000000015047466219876688855040.0;\n        }\n        _4217 = _4230;\n    }\n    float ty = _4217;\n    float _4246;\n    if (_4180 > 9.9999999747524270787835121154785e-07)\n    {\n        _4246 = (1.0 - _4166) / _4180;\n    }\n    else\n    {\n        float _4259;\n        if (_4180 < (-9.9999999747524270787835121154785e-07))\n        {\n            _4259 = ((-1.0) - _4166) / _4180;\n        }\n        else\n        {\n            _4259 = 1000000015047466219876688855040.0;\n        }\n        _4246 = _4259;\n    }\n    float _4271 = tx;\n    float _4274 = (_4271 > 0.0) ? _4271 : 1000000015047466219876688855040.0;\n    tx = _4274;\n    float _4275 = ty;\n    float _4278 = (_4275 > 0.0) ? _4275 : 1000000015047466219876688855040.0;\n    ty = _4278;\n    float _4288 = min(_4274, min(_4278, (_4246 > 0.0) ? _4246 : 1000000015047466219876688855040.0));\n    if (_4288 > 100000001504746621987668885504.0)\n    {\n        return d;\n    }\n    vec3 _4304 = (fa_world_pos + (d * _4288)) - posw.xyz;\n    vec3 _4309;\n    if (dot(_4304, _4304) > 1.0000000133514319600180897396058e-10)\n    {\n        _4309 = normalize(_4304);\n    }\n    else\n    {\n        _4309 = d;\n    }\n    return _4309;\n}\n\nvec3 fa_probe_environment(vec4 tile, vec4 posw, vec4 bx, vec4 by, vec4 bz, inout vec3 d, float rough)\n{\n    vec3 param = d;\n    vec4 param_1 = posw;\n    vec4 param_2 = bx;\n    vec4 param_3 = by;\n    vec4 param_4 = bz;\n    d = fa_probe_box_dir(param, param_1, param_2, param_3, param_4);\n    vec2 param_5 = tile.xy;\n    float param_6 = tile.z;\n    vec3 param_7 = d;\n    float param_8 = rough;\n    return fa_probe_radiance(param_5, param_6, param_7, param_8);\n}\n\nvec3 fa_environment(vec3 d, float rough)\n{\n    float _4355 = (1.0 - fa_mesh_fs_params[42].w) - fa_mesh_fs_params[47].w;\n    vec3 outc = vec3(0.0);\n    if (_4355 > 0.0005000000237487256526947021484375)\n    {\n        vec3 base;\n        if (fa_mesh_fs_params[11].w > 0.5)\n        {\n            vec2 param = fa_mesh_fs_params[41].zw;\n            float param_1 = 128.0;\n            vec3 param_2 = d;\n            float param_3 = rough;\n            base = fa_probe_radiance(param, param_1, param_2, param_3);\n        }\n        else\n        {\n            float _4383 = rough * rough;\n            float _4414 = 0.60000002384185791015625 * _4383;\n            base = mix(mix(fa_mesh_fs_params[12].xyz * 0.550000011920928955078125, mix(fa_mesh_fs_params[12].xyz, fa_mesh_fs_params[11].xyz, vec3(pow(clamp(d.y * (1.0 - (0.699999988079071044921875 * _4383)), 0.0, 1.0), 0.550000011920928955078125))), vec3(smoothstep((-0.0500000007450580596923828125) - _4414, 0.0500000007450580596923828125 + _4414, d.y))), ((fa_mesh_fs_params[11].xyz + fa_mesh_fs_params[12].xyz) * 0.5) * 0.800000011920928955078125, vec3(_4383 * 0.60000002384185791015625));\n        }\n        outc = base * _4355;\n    }\n    if (fa_mesh_fs_params[42].w > 0.0)\n    {\n        vec4 param_4 = fa_mesh_fs_params[42];\n        vec4 param_5 = fa_mesh_fs_params[43];\n        vec4 param_6 = fa_mesh_fs_params[44];\n        vec4 param_7 = fa_mesh_fs_params[45];\n        vec4 param_8 = fa_mesh_fs_params[46];\n        vec3 param_9 = d;\n        float param_10 = rough;\n        vec3 _4473 = fa_probe_environment(param_4, param_5, param_6, param_7, param_8, param_9, param_10);\n        outc += (_4473 * fa_mesh_fs_params[42].w);\n    }\n    if (fa_mesh_fs_params[47].w > 0.0)\n    {\n        vec4 param_11 = fa_mesh_fs_params[47];\n        vec4 param_12 = fa_mesh_fs_params[48];\n        vec4 param_13 = fa_mesh_fs_params[49];\n        vec4 param_14 = fa_mesh_fs_params[50];\n        vec4 param_15 = fa_mesh_fs_params[51];\n        vec3 param_16 = d;\n        float param_17 = rough;\n        vec3 _4505 = fa_probe_environment(param_11, param_12, param_13, param_14, param_15, param_16, param_17);\n        outc += (_4505 * fa_mesh_fs_params[47].w);\n    }\n    return outc;\n}\n\nvec3 fa_layers_ibl(FaLayers L, vec3 n, vec3 v, vec3 f0, float roughness, float occlusion)\n{\n    vec3 rn = n;\n    if (L.aniso != 0.0)\n    {\n        vec3 _5151;\n        if (L.aniso >= 0.0)\n        {\n            _5151 = L.b;\n        }\n        else\n        {\n            _5151 = L.t;\n        }\n        rn = normalize(mix(n, cross(cross(_5151, v), _5151), vec3(abs(L.aniso) * smoothstep(0.0, 0.25, roughness))));\n    }\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05);\n    vec2 _5187 = fa_env_brdf(param, param_1);\n    vec3 param_2 = reflect(-v, rn);\n    float param_3 = roughness;\n    vec3 result = (fa_environment(param_2, param_3) * ((f0 * _5187.x) + (vec3(L.f90) * _5187.y))) * L.base_scale;\n    if (L.sheen_on)\n    {\n        vec3 param_4 = n;\n        float param_5 = L.sheen_rough;\n        result += ((L.sheen * (L.sheen_e * L.keep)) * fa_environment(param_4, param_5));\n    }\n    result *= occlusion;\n    if (L.coat > 0.0)\n    {\n        float param_6 = L.coat_rough;\n        float param_7 = L.coat_ndv;\n        vec2 _5245 = fa_env_brdf(param_6, param_7);\n        vec3 param_8 = reflect(-v, L.nc);\n        float param_9 = L.coat_rough;\n        result += (fa_environment(param_8, param_9) * (L.coat * ((0.039999999105930328369140625 * _5245.x) + _5245.y)));\n    }\n    return result;\n}\n\nvec3 fa_sky_reflection(vec3 n, vec3 v, vec3 f0, float roughness)\n{\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05);\n    vec2 _4715 = fa_env_brdf(param, param_1);\n    vec3 param_2 = reflect(-v, n);\n    float param_3 = roughness;\n    return fa_environment(param_2, param_3) * ((f0 * _4715.x) + vec3(_4715.y));\n}\n\nvec2 fa_xm_size(int k)\n{\n    return max(floor(fa_mesh_fs_params[24].zw / vec2(float(1 << k))), vec2(1.0));\n}\n\nvec2 fa_xm_origin(int k)\n{\n    if (k == 0)\n    {\n        return vec2(0.0);\n    }\n    float y = 0.0;\n    for (int j = 1; j < k; j++)\n    {\n        int param = j;\n        y += fa_xm_size(param).y;\n    }\n    return vec2(fa_mesh_fs_params[24].z, y);\n}\n\nvec3 fa_xm_texel(vec2 size, vec2 origin, vec2 p)\n{\n    return texelFetch(fa_screen_tex_fa_shadow_smp, ivec2(origin + clamp(p, vec2(0.0), size - vec2(1.0))), 0).xyz;\n}\n\nvec3 fa_xm_level(int k, vec2 uv)\n{\n    int param = k;\n    vec2 _5947 = fa_xm_size(param);\n    int param_1 = k;\n    vec2 _5951 = fa_xm_origin(param_1);\n    vec2 _5957 = (uv * _5947) - vec2(0.5);\n    vec2 _5960 = fract(_5957);\n    vec2 _5963 = floor(_5957);\n    vec2 param_2 = _5947;\n    vec2 param_3 = _5951;\n    vec2 param_4 = _5963;\n    vec2 param_5 = _5947;\n    vec2 param_6 = _5951;\n    vec2 param_7 = _5963 + vec2(1.0, 0.0);\n    vec2 param_8 = _5947;\n    vec2 param_9 = _5951;\n    vec2 param_10 = _5963 + vec2(0.0, 1.0);\n    vec2 param_11 = _5947;\n    vec2 param_12 = _5951;\n    vec2 param_13 = _5963 + vec2(1.0);\n    vec3 _6005 = vec3(_5960.x);\n    return mix(mix(fa_xm_texel(param_2, param_3, param_4), fa_xm_texel(param_5, param_6, param_7), _6005), mix(fa_xm_texel(param_8, param_9, param_10), fa_xm_texel(param_11, param_12, param_13), _6005), vec3(_5960.y));\n}\n\nvec3 fa_xm_sample(vec2 uv, float lod)\n{\n    float _6024 = max(fa_mesh_fs_params[31].w - 1.0, 0.0);\n    float _6028 = clamp(lod, 0.0, _6024);\n    int _6032 = int(floor(_6028));\n    int param = _6032;\n    vec2 param_1 = uv;\n    vec3 c = fa_xm_level(param, param_1);\n    float _6042 = float(_6032);\n    float _6043 = _6028 - _6042;\n    bool _6045 = _6043 > 0.001000000047497451305389404296875;\n    bool _6052;\n    if (_6045)\n    {\n        _6052 = _6042 < _6024;\n    }\n    else\n    {\n        _6052 = _6045;\n    }\n    if (_6052)\n    {\n        int param_2 = _6032 + 1;\n        vec2 param_3 = uv;\n        c = mix(c, fa_xm_level(param_2, param_3), vec3(_6043));\n    }\n    return c;\n}\n\nvec3 fa_transmitted(Surface s, vec3 n, vec3 v, float roughness, vec3 f0, float f90, float keep, float tr, inout float blend)\n{\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05);\n    vec2 _6078 = fa_env_brdf(param, param_1);\n    vec3 _6102 = ((vec3(1.0) - clamp((f0 * _6078.x) + (vec3(f90) * _6078.y), vec3(0.0), vec3(1.0))) * s.albedo) * (tr * keep);\n    vec3 through = _6102;\n    float _6108 = max(s.thickness, 0.0);\n    bool _6113 = _6108 > 0.0;\n    if ((s.attenuation_distance > 0.0) && _6113)\n    {\n        through *= exp((-((-log(clamp(s.attenuation_color, vec3(9.9999997473787516355514526367188e-05), vec3(1.0)))) / vec3(s.attenuation_distance))) * _6108);\n    }\n    bool _6138 = fa_mesh_fs_params[30].w > 1.5;\n    bool _6144;\n    if (_6138)\n    {\n        _6144 = fa_mesh_fs_params[30].w < 2.5;\n    }\n    else\n    {\n        _6144 = _6138;\n    }\n    bool _6151;\n    if (!_6144)\n    {\n        _6151 = fa_mesh_fs_params[30].w < 0.5;\n    }\n    else\n    {\n        _6151 = _6144;\n    }\n    if (_6151)\n    {\n        blend = clamp(dot(through, vec3(0.3333333432674407958984375)), 0.0, 0.980000019073486328125);\n        return vec3(0.0);\n    }\n    vec4 _6166 = vec4(fa_world_pos, 1.0);\n    float _6171 = dot(fa_mesh_fs_params[28], _6166);\n    vec2 uv0 = vec2(0.5);\n    if (_6171 > 9.9999997473787516355514526367188e-05)\n    {\n        vec2 _6189 = vec2(dot(fa_mesh_fs_params[26], _6166), dot(fa_mesh_fs_params[27], _6166)) / vec2(_6171);\n        float _6197;\n        if (fa_mesh_fs_params[24].y > 0.5)\n        {\n            _6197 = (_6189.y * 0.5) + 0.5;\n        }\n        else\n        {\n            _6197 = 0.5 - (_6189.y * 0.5);\n        }\n        uv0 = vec2((_6189.x * 0.5) + 0.5, _6197);\n    }\n    if (fa_mesh_fs_params[30].w > 2.5)\n    {\n        int param_2 = 0;\n        vec2 _6218 = fa_xm_size(param_2);\n        vec2 _6226 = floor(clamp(uv0, vec2(0.0), vec2(0.99989998340606689453125)) * _6218);\n        if (texelFetch(fa_screen_tex_fa_shadow_smp, ivec2(_6226), 0).w > 0.5)\n        {\n            int _6246 = int(floor((clamp(roughness, 0.0, 1.0) * 2.0) + 0.5));\n            vec3 acc = vec3(0.0);\n            float cnt = 0.0;\n            for (int dy = -2; dy <= 2; dy++)\n            {\n                for (int dx = -2; dx <= 2; dx++)\n                {\n                    bool _6269 = abs(dx) > _6246;\n                    bool _6277;\n                    if (!_6269)\n                    {\n                        _6277 = abs(dy) > _6246;\n                    }\n                    else\n                    {\n                        _6277 = _6269;\n                    }\n                    if (_6277)\n                    {\n                        continue;\n                    }\n                    vec4 _6298 = texelFetch(fa_screen_tex_fa_shadow_smp, ivec2(clamp(_6226 + vec2(float(dx), float(dy)), vec2(0.0), _6218 - vec2(1.0))), 0);\n                    if (_6298.w > 0.5)\n                    {\n                        acc += _6298.xyz;\n                        cnt += 1.0;\n                    }\n                }\n            }\n            return _6102 * (acc / vec3(max(cnt, 1.0)));\n        }\n    }\n    vec2 uv = uv0;\n    if (_6113)\n    {\n        vec4 _6346 = vec4(fa_world_pos + (refract(-v, n, 1.0 / max(s.ior, 1.0)) * _6108), 1.0);\n        float _6351 = dot(fa_mesh_fs_params[28], _6346);\n        uv = vec2(0.5);\n        if (_6351 > 9.9999997473787516355514526367188e-05)\n        {\n            vec2 _6368 = vec2(dot(fa_mesh_fs_params[26], _6346), dot(fa_mesh_fs_params[27], _6346)) / vec2(_6351);\n            float _6376;\n            if (fa_mesh_fs_params[24].y > 0.5)\n            {\n                _6376 = (_6368.y * 0.5) + 0.5;\n            }\n            else\n            {\n                _6376 = 0.5 - (_6368.y * 0.5);\n            }\n            uv = vec2((_6368.x * 0.5) + 0.5, _6376);\n        }\n    }\n    vec2 param_3 = clamp(uv, vec2(0.0), vec2(1.0));\n    float param_4 = (clamp(roughness, 0.0, 1.0) * clamp((2.0 * s.ior) - 2.0, 0.0, 1.0)) * max(fa_mesh_fs_params[31].w - 1.0, 0.0);\n    return through * fa_xm_sample(param_3, param_4);\n}\n\nvec3 fa_shadow_debug(vec3 color, vec3 world)\n{\n    if (fa_shadows[27].w < 0.5)\n    {\n        return color;\n    }\n    int _3280 = int(fa_shadows[25].x + 0.5);\n    float _3290 = dot(world - fa_shadows[27].xyz, fa_shadows[28].xyz);\n    vec3 tint = vec3(0.3499999940395355224609375);\n    bool _3295 = _3280 > 0;\n    bool _3304;\n    if (_3295)\n    {\n        int param = _3280 - 1;\n        _3304 = _3290 <= fa_shadow_split_at(param);\n    }\n    else\n    {\n        _3304 = _3295;\n    }\n    if (_3304)\n    {\n        tint = vec3(1.0, 0.1500000059604644775390625, 0.100000001490116119384765625);\n        bool _3310 = _3280 > 1;\n        bool _3317;\n        if (_3310)\n        {\n            _3317 = _3290 > fa_shadows[24].x;\n        }\n        else\n        {\n            _3317 = _3310;\n        }\n        if (_3317)\n        {\n            tint = vec3(0.100000001490116119384765625, 0.89999997615814208984375, 0.20000000298023223876953125);\n        }\n        bool _3323 = _3280 > 2;\n        bool _3330;\n        if (_3323)\n        {\n            _3330 = _3290 > fa_shadows[24].y;\n        }\n        else\n        {\n            _3330 = _3323;\n        }\n        if (_3330)\n        {\n            tint = vec3(0.1500000059604644775390625, 0.300000011920928955078125, 1.0);\n        }\n        bool _3336 = _3280 > 3;\n        bool _3343;\n        if (_3336)\n        {\n            _3343 = _3290 > fa_shadows[24].z;\n        }\n        else\n        {\n            _3343 = _3336;\n        }\n        if (_3343)\n        {\n            tint = vec3(1.0, 0.89999997615814208984375, 0.100000001490116119384765625);\n        }\n    }\n    return mix(color, tint, vec3(0.550000011920928955078125));\n}\n\nvoid main()\n{\n    fa_rt_slope = 0.0;\n    fa_inst_load();\n    vec3 _9453 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _9453 = -_9453;\n    }\n    vec3 _8751 = normalize(fa_mesh_fs_params[0].xyz - fa_world_pos);\n    vec3 param = fa_world_pos;\n    fa_cluster_begin(param);\n    SurfaceInput param_1 = SurfaceInput(fa_world_pos, _9453, fa_world_tangent, fa_uv, fa_vertex_color, _8751, gl_FrontFacing);\n    Surface _8759 = fa_standard_surface(param_1);\n    vec3 _9484 = _8759.albedo;\n    float _9485 = _8759.alpha;\n    vec3 _9486 = _8759.normal;\n    float _9487 = _8759.metallic;\n    float _9488 = _8759.roughness;\n    float _9489 = _8759.occlusion;\n    vec3 _9490 = _8759.emission;\n    float _9491 = _8759.clearcoat;\n    float _9492 = _8759.clearcoat_roughness;\n    vec3 _9493 = _8759.sheen_color;\n    float _9494 = _8759.sheen_roughness;\n    float _9495 = _8759.anisotropy;\n    float _9496 = _8759.anisotropy_rotation;\n    float _9497 = _8759.specular;\n    float _9498 = _8759.ior;\n    vec3 _9499 = _8759.specular_color;\n    float _9500 = _8759.transmission;\n    float _9501 = _8759.thickness;\n    vec3 _9502 = _8759.attenuation_color;\n    float _9503 = _8759.attenuation_distance;\n    SurfaceInput param_2 = SurfaceInput(fa_world_pos, _9453, fa_world_tangent, fa_uv, fa_vertex_color, _8751, gl_FrontFacing);\n    Surface param_3 = _8759;\n    surface(param_2, param_3);\n    _9484 = param_3.albedo;\n    _9485 = param_3.alpha;\n    _9486 = param_3.normal;\n    _9487 = param_3.metallic;\n    _9488 = param_3.roughness;\n    _9489 = param_3.occlusion;\n    _9490 = param_3.emission;\n    _9491 = param_3.clearcoat;\n    _9492 = param_3.clearcoat_roughness;\n    _9493 = param_3.sheen_color;\n    _9494 = param_3.sheen_roughness;\n    _9495 = param_3.anisotropy;\n    _9496 = param_3.anisotropy_rotation;\n    _9497 = param_3.specular;\n    _9498 = param_3.ior;\n    _9499 = param_3.specular_color;\n    _9500 = param_3.transmission;\n    _9501 = param_3.thickness;\n    _9502 = param_3.attenuation_color;\n    _9503 = param_3.attenuation_distance;\n    vec3 param_4 = fa_world_pos;\n    vec3 param_5 = _9453;\n    vec3 param_6 = param_3.albedo;\n    vec3 param_7 = param_3.normal;\n    fa_apply_decals(param_4, param_5, param_6, param_7);\n    _9484 = param_6;\n    _9486 = param_7;\n    float fa_tr_blend = 0.0;\n    vec3 result;\n    if (fa_mesh_fs_params[3].w > 0.5)\n    {\n        result = _9484;\n    }\n    else\n    {\n        vec3 _8799 = normalize(_9486);\n        float _8806 = clamp(_9487, 0.0, 1.0);\n        float _8810 = clamp(_9488, 0.0500000007450580596923828125, 1.0);\n        float _8814 = _8810 * _8810;\n        float _8818 = _8814 * _8814;\n        float _8823 = max(dot(_8799, _8751), 9.9999997473787516355514526367188e-05);\n        float _8829 = 1.0 - _8806;\n        float _8830 = clamp(_9500, 0.0, 1.0) * _8829;\n        vec3 _8839 = (_9484 * _8829) * (1.0 - _8830);\n        vec3 _8846 = mix(vec3(0.039999999105930328369140625), _9484, vec3(_8806));\n        vec3 f0 = _8846;\n        SurfaceInput param_8 = SurfaceInput(fa_world_pos, _9453, fa_world_tangent, fa_uv, fa_vertex_color, _8751, gl_FrontFacing);\n        Surface param_9 = Surface(_9484, _9485, _9486, _9487, _9488, _9489, _9490, _9491, _9492, _9493, _9494, _9495, _9496, _9497, _9498, _9499, _9500, _9501, _9502, _9503);\n        vec3 param_10 = _8799;\n        vec3 param_11 = _8751;\n        float param_12 = _8806;\n        float param_13 = _8810;\n        vec3 param_14 = _8846;\n        FaLayers _8862 = fa_layers_setup(param_8, param_9, param_10, param_11, param_12, param_13, param_14);\n        f0 = param_14;\n        vec3 param_15 = _8799;\n        vec3 lit = (fa_indirect_diffuse(param_15) * _8839) * _9489;\n        if (_8862.on)\n        {\n            lit *= _8862.base_scale;\n        }\n        int _8884 = fa_cl_ndir + fa_cl_local;\n        float _8949;\n        for (int ln = 0; ln < _8884; ln++)\n        {\n            int param_16 = ln;\n            int _8897 = fa_cl_light(param_16);\n            int param_17 = _8897;\n            if (fa_baked_keep(param_17) <= 0.0)\n            {\n                continue;\n            }\n            int param_18 = _8897;\n            vec3 param_19 = fa_world_pos;\n            vec3 param_20 = _9453;\n            LightSample _8913 = fa_light_shadowed(param_18, param_19, param_20);\n            float _8921 = max(dot(_8799, _8913.direction), 0.0);\n            float _8927 = _8913.attenuation * _8913.shadow;\n            vec3 _8932 = normalize(_8913.direction + _8751);\n            float _8937 = max(dot(_8799, _8932), 0.0);\n            float _8942 = max(dot(_8751, _8932), 0.0);\n            if (fa_light_is_area)\n            {\n                if (_8862.on)\n                {\n                    _8949 = _8862.f90;\n                }\n                else\n                {\n                    _8949 = 1.0;\n                }\n                int param_21 = _8897;\n                vec3 param_22 = fa_world_pos;\n                vec3 param_23 = _8799;\n                vec3 param_24 = _8751;\n                vec3 param_25 = _8839;\n                vec3 param_26 = f0;\n                float param_27 = _8949;\n                float param_28 = _8810;\n                float param_29 = _8823;\n                float param_30 = _8927;\n                vec3 area = fa_area_shade(param_21, param_22, param_23, param_24, param_25, param_26, param_27, param_28, param_29, param_30);\n                if (_8862.on)\n                {\n                    FaLayers param_31 = _8862;\n                    vec3 param_32 = area;\n                    int param_33 = _8897;\n                    vec3 param_34 = _8799;\n                    vec3 param_35 = _8751;\n                    vec3 param_36 = _8913.direction;\n                    float param_37 = _8823;\n                    float param_38 = _8927;\n                    area = fa_area_layers(param_31, param_32, param_33, param_34, param_35, param_36, param_37, param_38);\n                }\n                lit += area;\n            }\n            else\n            {\n                if (_8862.on)\n                {\n                    FaLayers param_39 = _8862;\n                    vec3 param_40 = _8839;\n                    vec3 param_41 = f0;\n                    vec3 param_42 = _8799;\n                    vec3 param_43 = _8751;\n                    vec3 param_44 = _8913.direction;\n                    vec3 param_45 = _8932;\n                    float param_46 = _8921;\n                    float param_47 = _8823;\n                    float param_48 = _8937;\n                    float param_49 = _8942;\n                    float param_50 = _8814;\n                    float param_51 = _8818;\n                    int param_52 = _8897;\n                    lit += (fa_layers_light(param_39, param_40, param_41, param_42, param_43, param_44, param_45, param_46, param_47, param_48, param_49, param_50, param_51) * ((fa_light_rgb(param_52) * fa_light_tint) * _8927));\n                }\n                else\n                {\n                    float _9051 = ((_8937 * _8937) * (_8818 - 1.0)) + 1.0;\n                    int param_53 = _8897;\n                    lit += (((_8839 + (((f0 + ((vec3(1.0) - f0) * pow(1.0 - _8942, 5.0))) * (((_8818 / ((3.1415927410125732421875 * _9051) * _9051)) * (0.5 / max(mix((2.0 * _8921) * _8823, _8921 + _8823, _8814), 9.9999997473787516355514526367188e-05))) * 3.1415927410125732421875)) * step(9.9999997473787516355514526367188e-05, _8921))) * (fa_light_rgb(param_53) * fa_light_tint)) * (_8921 * _8927));\n                }\n            }\n        }\n        if (_8862.on)\n        {\n            FaLayers param_54 = _8862;\n            vec3 param_55 = _8799;\n            vec3 param_56 = _8751;\n            vec3 param_57 = f0;\n            float param_58 = _8810;\n            float param_59 = _9489;\n            lit += fa_layers_ibl(param_54, param_55, param_56, param_57, param_58, param_59);\n        }\n        else\n        {\n            vec3 param_60 = _8799;\n            vec3 param_61 = _8751;\n            vec3 param_62 = f0;\n            float param_63 = _8810;\n            lit += (fa_sky_reflection(param_60, param_61, param_62, param_63) * _9489);\n        }\n        if (_8830 > 0.0)\n        {\n            float _9149;\n            if (_8862.on)\n            {\n                _9149 = _8862.f90;\n            }\n            else\n            {\n                _9149 = 1.0;\n            }\n            float _9157;\n            if (_8862.on)\n            {\n                _9157 = _8862.base_scale;\n            }\n            else\n            {\n                _9157 = 1.0;\n            }\n            Surface param_64 = Surface(_9484, _9485, _9486, _9487, _9488, _9489, _9490, _9491, _9492, _9493, _9494, _9495, _9496, _9497, _9498, _9499, _9500, _9501, _9502, _9503);\n            vec3 param_65 = _8799;\n            vec3 param_66 = _8751;\n            float param_67 = _8810;\n            vec3 param_68 = f0;\n            float param_69 = _9149;\n            float param_70 = _9157;\n            float param_71 = _8830;\n            float param_72 = fa_tr_blend;\n            vec3 _9181 = fa_transmitted(param_64, param_65, param_66, param_67, param_68, param_69, param_70, param_71, param_72);\n            fa_tr_blend = param_72;\n            lit += _9181;\n        }\n        result = lit;\n    }\n    vec3 _9188 = result;\n    vec3 _9189 = _9188 + _9490;\n    result = _9189;\n    vec3 param_73 = _9189;\n    vec3 param_74 = fa_world_pos;\n    result = fa_shadow_debug(param_73, param_74);\n    bool _9198 = fa_mesh_fs_params[7].w > 0.0;\n    bool _9205;\n    if (!_9198)\n    {\n        _9205 = fa_mesh_fs_params[8].y > 0.0;\n    }\n    else\n    {\n        _9205 = _9198;\n    }\n    if (_9205)\n    {\n        vec3 _9214 = fa_world_pos - fa_mesh_fs_params[0].xyz;\n        float _9220 = dot(_9214, fa_mesh_fs_params[9].xyz);\n        bool _9224 = fa_mesh_fs_params[9].w > 0.5;\n        float _9225;\n        if (_9224)\n        {\n            _9225 = _9220;\n        }\n        else\n        {\n            _9225 = length(_9214);\n        }\n        float _9237 = _9225 - fa_mesh_fs_params[8].x;\n        if (_9237 > 0.0)\n        {\n            float _9246 = fa_mesh_fs_params[7].w * _9237;\n            float tau = _9246 * _9246;\n            if (fa_mesh_fs_params[8].y > 0.0)\n            {\n                float _9262;\n                if (_9224)\n                {\n                    _9262 = fa_world_pos.y - (fa_mesh_fs_params[9].y * _9220);\n                }\n                else\n                {\n                    _9262 = fa_mesh_fs_params[0].y;\n                }\n                float _9283 = mix(_9262, fa_world_pos.y, clamp(fa_mesh_fs_params[8].x / _9225, 0.0, 1.0));\n                float _9287 = fa_world_pos.y - _9283;\n                float _9292 = _9283 - fa_mesh_fs_params[8].z;\n                float _9297 = fa_world_pos.y - fa_mesh_fs_params[8].z;\n                bool _9300 = _9292 <= 0.0;\n                bool _9301 = !_9300;\n                bool _9307;\n                if (_9301)\n                {\n                    _9307 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _9307 = _9300;\n                }\n                float _9308;\n                if (_9307)\n                {\n                    _9308 = fa_mesh_fs_params[8].y;\n                }\n                else\n                {\n                    _9308 = fa_mesh_fs_params[8].y * exp(-min(fa_mesh_fs_params[8].w * _9292, 80.0));\n                }\n                bool _9335;\n                if (_9301)\n                {\n                    _9335 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _9335 = _9300;\n                }\n                float _9336;\n                if (_9335)\n                {\n                    _9336 = fa_mesh_fs_params[8].y * _9292;\n                }\n                else\n                {\n                    _9336 = (fa_mesh_fs_params[8].y * (1.0 - exp(-min(fa_mesh_fs_params[8].w * _9292, 80.0)))) / fa_mesh_fs_params[8].w;\n                }\n                bool _9361 = _9297 <= 0.0;\n                bool _9368;\n                if (!_9361)\n                {\n                    _9368 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _9368 = _9361;\n                }\n                float _9369;\n                if (_9368)\n                {\n                    _9369 = fa_mesh_fs_params[8].y * _9297;\n                }\n                else\n                {\n                    _9369 = (fa_mesh_fs_params[8].y * (1.0 - exp(-min(fa_mesh_fs_params[8].w * _9297, 80.0)))) / fa_mesh_fs_params[8].w;\n                }\n                float _9396;\n                if (abs(_9287) < 0.001000000047497451305389404296875)\n                {\n                    _9396 = _9308;\n                }\n                else\n                {\n                    _9396 = (_9369 - _9336) / _9287;\n                }\n                tau += (_9237 * max(_9396, 0.0));\n            }\n            result = mix(result, fa_mesh_fs_params[7].xyz, vec3(clamp(1.0 - exp(-clamp(tau, 0.0, 80.0)), 0.0, 1.0)));\n        }\n    }\n    if (fa_tr_blend > 0.0)\n    {\n        float _9432 = 1.0 - fa_tr_blend;\n        result /= vec3(_9432);\n        _9485 *= _9432;\n    }\n    fa_frag_color = vec4(result, _9485);\n}\n\n",
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
            "size": 864,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_659",
            "glsl_uniforms": [
              {
                "type": "vec4",
                "array_count": 54,
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
            "inst_name": "_2321",
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
              "name": "fa_probe_atlas",
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
            "name": "fa_probe_atlas_fa_env_smp",
            "view_name": "fa_probe_atlas",
            "sampler_name": "fa_env_smp",
            "view_slot": 14,
            "sampler_slot": 10,
            "glsl_name": "fa_probe_atlas_fa_env_smp"
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
            "name": "fa_screen_tex_fa_shadow_smp",
            "view_name": "fa_screen_tex",
            "sampler_name": "fa_shadow_smp",
            "view_slot": 28,
            "sampler_slot": 1,
            "glsl_name": "fa_screen_tex_fa_shadow_smp"
          },
          {
            "slot": 11,
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
      "fs": "#version 430\n\nstruct SurfaceInput\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 vertex_color;\n    vec3 view_dir;\n    bool front_facing;\n};\n\nstruct LightSample\n{\n    vec3 direction;\n    vec3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct Surface\n{\n    vec3 albedo;\n    float alpha;\n    vec3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    vec3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    vec3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    vec3 specular_color;\n    float transmission;\n    float thickness;\n    vec3 attenuation_color;\n    float attenuation_distance;\n};\n\nstruct FaLayers\n{\n    bool on;\n    float f90;\n    float keep;\n    float base_scale;\n    float coat;\n    float coat_rough;\n    float coat_alpha;\n    float coat_a2;\n    vec3 nc;\n    float coat_ndv;\n    bool sheen_on;\n    vec3 sheen;\n    float sheen_rough;\n    float sheen_alpha;\n    float sheen_scale;\n    float sheen_e;\n    float aniso;\n    vec3 t;\n    vec3 b;\n    float at;\n    float ab;\n};\n\nconst float _4816[63] = float[](1.0, 1.0, 1.0, 0.4790000021457672119140625, 0.11699999868869781494140625, 0.01200000010430812835693359375, 0.0, 0.0, 0.0, 1.0, 1.0, 1.0, 0.578000009059906005859375, 0.19300000369548797607421875, 0.0350000001490116119384765625, 0.0030000000260770320892333984375, 0.0, 0.0, 1.0, 1.0, 1.0, 0.6740000247955322265625, 0.3459999859333038330078125, 0.1319999992847442626953125, 0.032999999821186065673828125, 0.0040000001899898052215576171875, 0.0, 0.971000015735626220703125, 0.954999983310699462890625, 0.828999996185302734375, 0.63999998569488525390625, 0.42599999904632568359375, 0.24500000476837158203125, 0.115000002086162567138671875, 0.037000000476837158203125, 0.0030000000260770320892333984375, 0.7469999790191650390625, 0.737999975681304931640625, 0.670000016689300537109375, 0.563000023365020751953125, 0.4309999942779541015625, 0.3039999902248382568359375, 0.1940000057220458984375, 0.1019999980926513671875, 0.0309999994933605194091796875, 0.614000022411346435546875, 0.609000027179718017578125, 0.566999971866607666015625, 0.499000012874603271484375, 0.412000000476837158203125, 0.32400000095367431640625, 0.240999996662139892578125, 0.162000000476837158203125, 0.087999999523162841796875, 0.538999974727630615234375, 0.535000026226043701171875, 0.505999982357025146484375, 0.4569999873638153076171875, 0.393999993801116943359375, 0.328999996185302734375, 0.2660000026226043701171875, 0.203999996185302734375, 0.14200000464916229248046875);\n\nstruct points_item\n{\n    vec4 pos;\n    vec4 tint;\n};\n\nuniform vec4 fa_mesh_fs_params[54];\nuniform vec4 fa_shadows[30];\nlayout(binding = 1, std430) readonly buffer fa_points_buf\n{\n    points_item data[];\n} points;\n\nlayout(binding = 0) uniform sampler2D fa_light_tex_fa_shadow_smp;\nlayout(binding = 1) uniform sampler2D fa_tex_fa_smp;\nlayout(binding = 2) uniform sampler2D fa_normal_tex_fa_smp;\nlayout(binding = 3) uniform sampler2D fa_mr_tex_fa_smp;\nlayout(binding = 4) uniform sampler2D fa_occlusion_tex_fa_smp;\nlayout(binding = 5) uniform sampler2D fa_emissive_tex_fa_smp;\nlayout(binding = 6) uniform sampler2D fa_decal_tex_fa_env_smp;\nlayout(binding = 7) uniform sampler2D fa_lightmap_fa_env_smp;\nlayout(binding = 8) uniform sampler2D fa_probe_atlas_fa_env_smp;\nlayout(binding = 9) uniform sampler2D fa_light_atlas_fa_env_smp;\nlayout(binding = 10) uniform sampler2D fa_screen_tex_fa_shadow_smp;\nlayout(binding = 11) uniform sampler2D fa_shadow_tex_fa_shadow_smp;\n\nlayout(location = 0) in vec3 fa_world_pos;\nlayout(location = 5) in vec3 fa_lm;\nlayout(location = 1) in vec3 fa_world_normal;\nlayout(location = 2) in vec4 fa_world_tangent;\nlayout(location = 3) in vec2 fa_uv;\nlayout(location = 4) in vec4 fa_vertex_color;\nlayout(location = 0) out vec4 fa_frag_color;\nfloat fa_rt_slope;\nvec3 fa_light_tint;\nbool fa_light_is_area;\nint fa_cl_ndir;\nint fa_cl_slot;\nint fa_cl_local;\n\nvoid fa_inst_load()\n{\n}\n\nvec4 fa_light_texel(int t)\n{\n    return texelFetch(fa_light_tex_fa_shadow_smp, ivec2(t & 1023, t >> 10), 0);\n}\n\nvec4 fa_cluster_texel(vec3 world_pos)\n{\n    bool _1597 = fa_mesh_fs_params[19].x < 0.0;\n    bool _1604;\n    if (!_1597)\n    {\n        _1604 = fa_mesh_fs_params[19].w < 1.0;\n    }\n    else\n    {\n        _1604 = _1597;\n    }\n    bool _1612;\n    if (!_1604)\n    {\n        _1612 = fa_mesh_fs_params[18].x < 1.0;\n    }\n    else\n    {\n        _1612 = _1604;\n    }\n    bool _1619;\n    if (!_1612)\n    {\n        _1619 = fa_mesh_fs_params[18].y < 1.0;\n    }\n    else\n    {\n        _1619 = _1612;\n    }\n    bool _1626;\n    if (!_1619)\n    {\n        _1626 = fa_mesh_fs_params[19].y < 1.0;\n    }\n    else\n    {\n        _1626 = _1619;\n    }\n    if (_1626)\n    {\n        return vec4(0.0);\n    }\n    vec4 _1636 = vec4(world_pos, 1.0);\n    float _1642 = dot(fa_mesh_fs_params[16], _1636);\n    if (!(_1642 > 9.9999999747524270787835121154785e-07))\n    {\n        return vec4(0.0);\n    }\n    vec2 _1664 = vec2(dot(fa_mesh_fs_params[14], _1636), dot(fa_mesh_fs_params[15], _1636)) / vec2(_1642);\n    int _1668 = int(fa_mesh_fs_params[18].x);\n    int _1672 = int(fa_mesh_fs_params[18].y);\n    int param = (int(fa_mesh_fs_params[19].x) + (((clamp(int(floor(log2(max(dot(fa_mesh_fs_params[17].xyz, world_pos) + fa_mesh_fs_params[17].w, fa_mesh_fs_params[18].w) / fa_mesh_fs_params[18].w) * fa_mesh_fs_params[18].z)), 0, int(fa_mesh_fs_params[19].y) - 1) * _1672) + clamp(int(floor(((_1664.y * 0.5) + 0.5) * fa_mesh_fs_params[18].y)), 0, _1672 - 1)) * _1668)) + clamp(int(floor(((_1664.x * 0.5) + 0.5) * fa_mesh_fs_params[18].x)), 0, _1668 - 1);\n    return fa_light_texel(param);\n}\n\nivec2 fa_cluster_lookup(vec3 world_pos)\n{\n    vec3 param = world_pos;\n    vec4 _1748 = fa_cluster_texel(param);\n    return ivec2(int(_1748.x), int(_1748.y));\n}\n\nvoid fa_cluster_begin(vec3 world_pos)\n{\n    float _6450 = dot(fa_mesh_fs_params[29].xyz, world_pos) + fa_mesh_fs_params[29].w;\n    float _6453 = fwidth(_6450);\n    bool _6456 = fa_mesh_fs_params[25].y > 0.5;\n    bool _6463;\n    if (!_6456)\n    {\n        _6463 = fa_mesh_fs_params[25].w > 0.5;\n    }\n    else\n    {\n        _6463 = _6456;\n    }\n    if (_6463)\n    {\n        fa_rt_slope = min(1.5 * _6453, 0.100000001490116119384765625 * _6450);\n    }\n    fa_cl_ndir = int(fa_mesh_fs_params[19].z);\n    vec3 param = world_pos;\n    ivec2 _6479 = fa_cluster_lookup(param);\n    fa_cl_slot = _6479.x;\n    fa_cl_local = _6479.y;\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nvec3 fa_linear_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_tex_fix(inout vec3 c, float mode)\n{\n    if (mode > 1.5)\n    {\n        vec3 param = c;\n        vec3 _7653 = fa_linear_to_srgb(param);\n        c = _7653;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            vec3 param_1 = c;\n            vec3 _7661 = fa_srgb_to_linear(param_1);\n            c = _7661;\n        }\n    }\n    return c;\n}\n\nvec3 fa_tangent_normal(SurfaceInput i, vec3 m)\n{\n    vec3 _542;\n    if (i.front_facing)\n    {\n        _542 = i.world_normal;\n    }\n    else\n    {\n        _542 = -i.world_normal;\n    }\n    vec3 _566 = normalize(i.world_tangent.xyz - (_542 * dot(_542, i.world_tangent.xyz)));\n    vec3 _593 = normalize(((_566 * m.x) + ((cross(_542, _566) * i.world_tangent.w) * m.y)) + (_542 * m.z));\n    vec3 _596;\n    if (i.front_facing)\n    {\n        _596 = _593;\n    }\n    else\n    {\n        _596 = -_593;\n    }\n    return _596;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    vec4 base_t = texture(fa_tex_fa_smp, i.uv, fa_mesh_fs_params[12].w);\n    float param = fa_mesh_fs_params[6].w;\n    float param_1 = 1.0;\n    vec3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    vec3 _7693 = fa_tex_fix(param_2, param_3);\n    vec4 _10064 = base_t;\n    _10064.x = _7693.x;\n    _10064.y = _7693.y;\n    _10064.z = _7693.z;\n    base_t = _10064;\n    vec4 _7707 = (_10064 * fa_mesh_fs_params[2]) * i.vertex_color;\n    vec3 _9814 = i.world_normal;\n    if (fa_mesh_fs_params[6].z > 0.5)\n    {\n        float param_4 = fa_mesh_fs_params[6].w;\n        float param_5 = 16.0;\n        vec3 param_6 = texture(fa_normal_tex_fa_smp, i.uv, fa_mesh_fs_params[12].w).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        vec3 _7741 = fa_tex_fix(param_6, param_7);\n        vec3 _7744 = (_7741 * 2.0) - vec3(1.0);\n        vec2 _7749 = _7744.xy * fa_mesh_fs_params[6].x;\n        vec3 _10072 = _7744;\n        _10072.x = _7749.x;\n        _10072.y = _7749.y;\n        SurfaceInput param_8 = i;\n        vec3 param_9 = _10072;\n        _9814 = fa_tangent_normal(param_8, param_9);\n    }\n    vec4 mrt = texture(fa_mr_tex_fa_smp, i.uv, fa_mesh_fs_params[12].w);\n    float param_10 = fa_mesh_fs_params[6].w;\n    float param_11 = 64.0;\n    vec3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    vec3 _7779 = fa_tex_fix(param_12, param_13);\n    vec4 _10075 = mrt;\n    _10075.x = _7779.x;\n    _10075.y = _7779.y;\n    _10075.z = _7779.z;\n    mrt = _10075;\n    vec4 _7809 = texture(fa_occlusion_tex_fa_smp, i.uv, fa_mesh_fs_params[12].w);\n    float param_14 = fa_mesh_fs_params[6].w;\n    float param_15 = 256.0;\n    vec3 param_16 = _7809.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    vec3 _7820 = fa_tex_fix(param_16, param_17);\n    float param_18 = fa_mesh_fs_params[6].w;\n    float param_19 = 4.0;\n    vec3 param_20 = texture(fa_emissive_tex_fa_smp, i.uv, fa_mesh_fs_params[12].w).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    vec3 _7852 = fa_tex_fix(param_20, param_21);\n    float _9819 = fa_mesh_fs_params[20].x;\n    float _9820 = fa_mesh_fs_params[20].y;\n    float _9823 = fa_mesh_fs_params[20].z;\n    float _9822 = fa_mesh_fs_params[21].w;\n    float _9825 = fa_mesh_fs_params[22].x;\n    if (fa_mesh_fs_params[22].z > 0.5)\n    {\n        if (mod(fa_mesh_fs_params[22].z, 2.0) > 0.5)\n        {\n            _9819 *= _7820.y;\n            _9820 *= _7820.z;\n            _9822 *= _7809.w;\n        }\n        if (fa_mesh_fs_params[22].z > 1.5)\n        {\n            _9823 *= mrt.x;\n            _9825 *= mrt.w;\n        }\n    }\n    return Surface(_7707.xyz, _7707.w, _9814, clamp(fa_mesh_fs_params[5].x * _7779.z, 0.0, 1.0), clamp(fa_mesh_fs_params[5].y * _7779.y, 0.0500000007450580596923828125, 1.0), 1.0 + (fa_mesh_fs_params[6].y * (_7820.x - 1.0)), fa_mesh_fs_params[3].xyz + (fa_mesh_fs_params[4].xyz * _7852), _9819, _9820, fa_mesh_fs_params[21].xyz, _9822, _9823, fa_mesh_fs_params[20].w, _9825, fa_mesh_fs_params[22].y, fa_mesh_fs_params[23].xyz, fa_mesh_fs_params[30].x, fa_mesh_fs_params[30].y, fa_mesh_fs_params[31].xyz, fa_mesh_fs_params[30].z);\n}\n\nvoid surface(SurfaceInput i, inout Surface s)\n{\n    s.emission += (i.vertex_color.xyz * points.data[0].tint.w);\n}\n\nvec4 fa_decal_tile(vec4 rect, vec2 uv, vec2 atlas, vec2 ddx, vec2 ddy)\n{\n    vec2 _1828 = rect.zw - rect.xy;\n    vec2 _1832 = _1828 * atlas;\n    vec2 _1836 = ddx * _1832;\n    vec2 _1840 = ddy * _1832;\n    return textureLod(fa_decal_tex_fa_env_smp, rect.xy + (clamp(uv, vec2(0.0), vec2(1.0)) * _1828), clamp(0.5 * log2(max(max(dot(_1836, _1836), dot(_1840, _1840)), 9.9999999392252902907785028219223e-09)), 0.0, 3.0));\n}\n\nvec3 fa_dc_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_dc_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvoid fa_apply_decals(vec3 world_pos, vec3 geo_normal, inout vec3 albedo, inout vec3 normal)\n{\n    bool _1873 = fa_mesh_fs_params[10].y < 0.5;\n    bool _1880;\n    if (!_1873)\n    {\n        _1880 = fa_mesh_fs_params[10].w < 0.5;\n    }\n    else\n    {\n        _1880 = _1873;\n    }\n    if (_1880)\n    {\n        return;\n    }\n    vec3 _1886 = dFdx(world_pos);\n    vec3 _1889 = dFdy(world_pos);\n    vec3 param = world_pos;\n    vec4 _1893 = fa_cluster_texel(param);\n    int _1897 = int(_1893.w);\n    if (_1897 < 1)\n    {\n        return;\n    }\n    int _1907 = int(fa_mesh_fs_params[10].y + 0.5);\n    int param_1 = _1907;\n    vec4 _1911 = fa_light_texel(param_1);\n    vec2 _1914 = _1911.yz;\n    int _1918 = int(_1911.w);\n    int param_2 = _1907 + 1;\n    vec4 _1923 = fa_light_texel(param_2);\n    float _1924 = _1923.x;\n    int _1930 = int(fa_mesh_fs_params[10].w + 0.5) - 1;\n    int _1934 = int(_1893.z);\n    vec3 _2199;\n    for (int k = 0; k < _1897; k++)\n    {\n        int _1947 = _1934 + k;\n        int param_3 = _1918 + (_1947 >> 2);\n        int _1964 = (_1907 + 2) + (int(fa_light_texel(param_3)[_1947 & 3]) * 7);\n        int param_4 = _1964 + 6;\n        vec4 _1969 = fa_light_texel(param_4);\n        if (((int(_1969.w + 0.5) >> _1930) & 1) == 0)\n        {\n            continue;\n        }\n        int param_5 = _1964;\n        vec4 _1984 = fa_light_texel(param_5);\n        int param_6 = _1964 + 1;\n        vec4 _1989 = fa_light_texel(param_6);\n        int param_7 = _1964 + 2;\n        vec4 _1994 = fa_light_texel(param_7);\n        vec3 _1997 = _1984.xyz;\n        float _2002 = dot(_1997, world_pos) + _1984.w;\n        vec3 _2004 = _1989.xyz;\n        float _2009 = dot(_2004, world_pos) + _1989.w;\n        vec3 _2011 = _1994.xyz;\n        float _2016 = dot(_2011, world_pos) + _1994.w;\n        bool _2021 = abs(_2002) > 0.5;\n        bool _2029;\n        if (!_2021)\n        {\n            _2029 = abs(_2009) > 0.5;\n        }\n        else\n        {\n            _2029 = _2021;\n        }\n        bool _2037;\n        if (!_2029)\n        {\n            _2037 = abs(_2016) > 0.5;\n        }\n        else\n        {\n            _2037 = _2029;\n        }\n        if (_2037)\n        {\n            continue;\n        }\n        float _2052 = clamp(dot(geo_normal, normalize(_2011)) * _1969.z, 0.0, 1.0);\n        if (_2052 <= 0.0)\n        {\n            continue;\n        }\n        float _2072 = (clamp((0.5 - abs(_2016)) * 10.0, 0.0, 1.0) * _2052) * _1969.x;\n        vec2 _2080 = vec2(_2002 + 0.5, 0.5 - _2009);\n        vec2 _2090 = vec2(dot(_1997, _1886), dot(_2004, _1886));\n        vec2 _2100 = vec2(dot(_1997, _1889), dot(_2004, _1889));\n        int param_8 = _1964 + 5;\n        vec4 _2105 = fa_light_texel(param_8);\n        int param_9 = _1964 + 3;\n        vec4 _2110 = fa_light_texel(param_9);\n        int param_10 = _1964 + 4;\n        vec4 _2115 = fa_light_texel(param_10);\n        float tex_a = 1.0;\n        vec3 col = _2105.xyz;\n        bool _2125 = _2110.z > _2110.x;\n        if (_2125)\n        {\n            vec4 param_11 = _2110;\n            vec2 param_12 = _2080;\n            vec2 param_13 = _1914;\n            vec2 param_14 = _2090;\n            vec2 param_15 = _2100;\n            vec4 tx = fa_decal_tile(param_11, param_12, param_13, param_14, param_15);\n            if ((_1924 > 0.5) && (_1924 < 1.5))\n            {\n                vec3 param_16 = tx.xyz;\n                vec3 _2151 = fa_dc_to_linear(param_16);\n                vec4 _9902 = tx;\n                _9902.x = _2151.x;\n                _9902.y = _2151.y;\n                _9902.z = _2151.z;\n                tx = _9902;\n            }\n            col *= tx.xyz;\n            tex_a = tx.w;\n        }\n        albedo = mix(albedo, col, vec3(clamp((_2072 * tex_a) * _2105.w, 0.0, 1.0)));\n        if (_2115.z > _2115.x)\n        {\n            vec4 param_17 = _2115;\n            vec2 param_18 = _2080;\n            vec2 param_19 = _1914;\n            vec2 param_20 = _2090;\n            vec2 param_21 = _2100;\n            vec4 _2195 = fa_decal_tile(param_17, param_18, param_19, param_20, param_21);\n            if (_1924 > 1.5)\n            {\n                vec3 param_22 = _2195.xyz;\n                vec3 _2205 = fa_dc_to_srgb(param_22);\n                _2199 = _2205;\n            }\n            else\n            {\n                _2199 = _2195.xyz;\n            }\n            vec3 _2214 = (_2199 * 2.0) - vec3(1.0);\n            vec2 _2219 = _2214.xy * _1969.y;\n            vec3 _2241 = (normalize(_1997) * _2219.x) + (normalize(_2004) * _2219.y);\n            vec3 _2244 = normalize(normal);\n            normal = normalize(mix(_2244, normalize((_2244 * max(_2214.z, 0.0500000007450580596923828125)) + (_2241 - (_2244 * dot(_2244, _2241)))), vec3(clamp(_2072 * (_2125 ? tex_a : 1.0), 0.0, 1.0))));\n        }\n    }\n}\n\nfloat fa_sheen_albedo(float ndv, float rough)\n{\n    float _4741 = min(sqrt(max(rough - 0.100000001490116119384765625, 0.0) * 1.111111164093017578125) * 6.0, 5.999000072479248046875);\n    float _4749 = min(sqrt(clamp(ndv, 0.0, 1.0)) * 8.0, 7.999000072479248046875);\n    int _4752 = int(_4741);\n    int _4755 = int(_4749);\n    float _4765 = _4749 - float(_4755);\n    int _4820 = (_4752 * 9) + _4755;\n    int _4840 = ((_4752 + 1) * 9) + _4755;\n    return mix(mix(_4816[_4820], _4816[_4820 + 1], _4765), mix(_4816[_4840], _4816[_4840 + 1], _4765), _4741 - float(_4752));\n}\n\nFaLayers fa_layers_setup(SurfaceInput i, Surface s, vec3 n, vec3 v, float metallic, float roughness, inout vec3 f0)\n{\n    bool _9737 = false;\n    float _9738 = 1.0;\n    float _9739 = 1.0;\n    float _9740 = 1.0;\n    float _9741 = 0.0;\n    float _9742 = 0.0;\n    float _9743 = 0.0;\n    float _9744 = 0.0;\n    float _9746 = 1.0;\n    bool _9747 = false;\n    vec3 _9748 = vec3(0.0);\n    float _9749 = 1.0;\n    float _9750 = 1.0;\n    float _9751 = 1.0;\n    float _9752 = 0.0;\n    float _9753 = 0.0;\n    vec3 _9754 = vec3(1.0, 0.0, 0.0);\n    vec3 _9755 = vec3(0.0, 0.0, 1.0);\n    float _9756 = 1.0;\n    float _9757 = 1.0;\n    float _4891 = clamp(s.specular, 0.0, 1.0);\n    float _4895 = clamp(s.ior, 1.0, 3.0);\n    bool _4900 = (_4891 != 1.0) || (_4895 != 1.5);\n    bool _4909;\n    if (!_4900)\n    {\n        _4909 = any(notEqual(s.specular_color, vec3(1.0)));\n    }\n    else\n    {\n        _4909 = _4900;\n    }\n    if (_4909)\n    {\n        float _4917 = (_4895 - 1.0) / (_4895 + 1.0);\n        f0 = mix(min(vec3(_4917 * _4917) * max(s.specular_color, vec3(0.0)), vec3(1.0)) * _4891, s.albedo, vec3(metallic));\n        _9738 = mix(_4891, 1.0, metallic);\n        _9737 = true;\n    }\n    float _4944 = clamp(s.clearcoat, 0.0, 1.0);\n    if (_4944 > 0.0)\n    {\n        float _4952 = clamp(s.clearcoat_roughness, 0.0500000007450580596923828125, 1.0);\n        _9741 = _4944;\n        _9742 = _4952;\n        float _4959 = _4952 * _4952;\n        _9743 = _4959;\n        _9744 = _4959 * _4959;\n        float _4971 = max(dot(i.world_normal, v), 9.9999997473787516355514526367188e-05);\n        _9746 = _4971;\n        _9739 = 1.0 - (_4944 * (0.039999999105930328369140625 + (0.959999978542327880859375 * pow(clamp(1.0 - _4971, 0.0, 1.0), 5.0))));\n        _9737 = true;\n    }\n    vec3 _4990 = max(s.sheen_color, vec3(0.0));\n    float _4999 = max(_4990.x, max(_4990.y, _4990.z));\n    if (_4999 > 0.0)\n    {\n        float _5007 = clamp(s.sheen_roughness, 0.100000001490116119384765625, 1.0);\n        _9747 = true;\n        _9748 = _4990;\n        _9749 = _5007;\n        _9750 = _5007 * _5007;\n        float param = max(dot(n, v), 9.9999997473787516355514526367188e-05);\n        float param_1 = _5007;\n        float _5024 = fa_sheen_albedo(param, param_1);\n        _9752 = _5024;\n        _9751 = 1.0 - min(_4999 * _5024, 1.0);\n        _9737 = true;\n    }\n    _9740 = _9739 * _9751;\n    float _5043 = clamp(s.anisotropy, -1.0, 1.0);\n    if (_5043 != 0.0)\n    {\n        vec3 _5058 = i.world_tangent.xyz - (n * dot(n, i.world_tangent.xyz));\n        vec3 t = _5058;\n        if (dot(_5058, _5058) < 9.9999999392252902907785028219223e-09)\n        {\n            bvec3 _5070 = bvec3(abs(n.y) < 0.9900000095367431640625);\n            t = cross(vec3(_5070.x ? vec3(0.0, 1.0, 0.0).x : vec3(1.0, 0.0, 0.0).x, _5070.y ? vec3(0.0, 1.0, 0.0).y : vec3(1.0, 0.0, 0.0).y, _5070.z ? vec3(0.0, 1.0, 0.0).z : vec3(1.0, 0.0, 0.0).z), n);\n        }\n        vec3 _5074 = t;\n        vec3 _5075 = normalize(_5074);\n        t = _5075;\n        vec3 _5100 = normalize((_5075 * cos(s.anisotropy_rotation)) + ((cross(n, _5075) * ((i.world_tangent.w < 0.0) ? (-1.0) : 1.0)) * sin(s.anisotropy_rotation)));\n        _9754 = _5100;\n        _9755 = cross(n, _5100);\n        float _5110 = roughness * roughness;\n        float _5116 = mix(_5110, 1.0, _5043 * _5043);\n        bool _5118 = _5043 > 0.0;\n        _9756 = _5118 ? _5116 : _5110;\n        _9757 = _5118 ? _5110 : _5116;\n        _9753 = _5043;\n        _9737 = true;\n    }\n    return FaLayers(_9737, _9738, _9739, _9740, _9741, _9742, _9743, _9744, i.world_normal, _9746, _9747, _9748, _9749, _9750, _9751, _9752, _9753, _9754, _9755, _9756, _9757);\n}\n\nvec2 fa_atlas_size()\n{\n    return vec2(textureSize(fa_probe_atlas_fa_env_smp, 0));\n}\n\nvec3 fa_probe_sh_coef(vec2 origin, float res, int k)\n{\n    vec3 v = textureLod(fa_probe_atlas_fa_env_smp, (origin + vec2(float(k) + 0.5, res + 2.5)) / fa_atlas_size(), 0.0).xyz;\n    if (fa_mesh_fs_params[41].y > 0.5)\n    {\n        v = ((v * 255.0) - vec3(128.0)) * 0.03149606287479400634765625;\n    }\n    return v;\n}\n\nvec3 fa_sh_eval(vec3 c[9], vec3 n)\n{\n    vec3 _3912 = max((((c[0] * 0.2820948064327239990234375) + (((c[1] * (0.3257350027561187744140625 * n.y)) + (c[2] * (0.3257350027561187744140625 * n.z))) + (c[3] * (0.3257350027561187744140625 * n.x)))) + (((c[4] * ((0.2731371223926544189453125 * n.x) * n.y)) + (c[5] * ((0.2731371223926544189453125 * n.y) * n.z))) + (c[6] * (0.078847892582416534423828125 * (((3.0 * n.z) * n.z) - 1.0))))) + ((c[7] * ((0.2731371223926544189453125 * n.x) * n.z)) + (c[8] * (0.13656856119632720947265625 * ((n.x * n.x) - (n.y * n.y))))), vec3(0.0));\n    return _3912;\n}\n\nvec3 fa_ambient_light(vec3 n)\n{\n    float _4523 = (1.0 - fa_mesh_fs_params[42].w) - fa_mesh_fs_params[47].w;\n    vec3 amb = vec3(0.0);\n    bool _4528 = fa_mesh_fs_params[11].w > 0.5;\n    vec3 c[9];\n    for (int k = 0; k < 9; k++)\n    {\n        c[k] = vec3(0.0);\n    }\n    if (_4523 > 0.0005000000237487256526947021484375)\n    {\n        if (_4528)\n        {\n            for (int k_1 = 0; k_1 < 9; k_1++)\n            {\n                vec2 param = fa_mesh_fs_params[41].zw;\n                float param_1 = 128.0;\n                int param_2 = k_1;\n                c[k_1] = fa_probe_sh_coef(param, param_1, param_2) * _4523;\n            }\n        }\n        else\n        {\n            amb = fa_mesh_fs_params[1].xyz * _4523;\n        }\n    }\n    bool _4578 = fa_mesh_fs_params[42].w > 0.0;\n    if (_4578)\n    {\n        for (int k_2 = 0; k_2 < 9; k_2++)\n        {\n            vec2 param_3 = fa_mesh_fs_params[42].xy;\n            float param_4 = fa_mesh_fs_params[42].z;\n            int param_5 = k_2;\n            c[k_2] += (fa_probe_sh_coef(param_3, param_4, param_5) * fa_mesh_fs_params[42].w);\n        }\n    }\n    bool _4609 = fa_mesh_fs_params[47].w > 0.0;\n    if (_4609)\n    {\n        for (int k_3 = 0; k_3 < 9; k_3++)\n        {\n            vec2 param_6 = fa_mesh_fs_params[47].xy;\n            float param_7 = fa_mesh_fs_params[47].z;\n            int param_8 = k_3;\n            c[k_3] += (fa_probe_sh_coef(param_6, param_7, param_8) * fa_mesh_fs_params[47].w);\n        }\n    }\n    if ((_4528 || _4578) || _4609)\n    {\n        vec3 param_9[9] = c;\n        vec3 param_10 = n;\n        amb += fa_sh_eval(param_9, param_10);\n    }\n    return amb;\n}\n\nvec4 fa_gi_fetch(vec2 texel)\n{\n    return textureLod(fa_probe_atlas_fa_env_smp, texel / fa_atlas_size(), 0.0);\n}\n\nvec2 fa_oct_encode(vec3 d)\n{\n    vec3 _3932 = d / vec3(max((abs(d.x) + abs(d.y)) + abs(d.z), 9.9999999600419720025001879548654e-13));\n    float _3935 = _3932.x;\n    float _3937 = _3932.z;\n    vec2 e = vec2(_3935, _3937);\n    if (_3932.y < 0.0)\n    {\n        e = vec2((1.0 - abs(_3937)) * ((_3935 < 0.0) ? (-1.0) : 1.0), (1.0 - abs(_3935)) * ((_3937 < 0.0) ? (-1.0) : 1.0));\n    }\n    return e;\n}\n\nvec3 fa_gi_grid(int rec, vec3 n, vec3 v, out float cover)\n{\n    cover = 0.0;\n    int param = rec;\n    vec4 _7962 = fa_light_texel(param);\n    int param_1 = rec + 1;\n    vec4 _7967 = fa_light_texel(param_1);\n    int param_2 = rec + 2;\n    vec4 _7972 = fa_light_texel(param_2);\n    int param_3 = rec + 3;\n    vec4 _7977 = fa_light_texel(param_3);\n    bool _7980 = _7977.z < 0.5;\n    bool _7988;\n    if (!_7980)\n    {\n        _7988 = fa_atlas_size().y < 1155.0;\n    }\n    else\n    {\n        _7988 = _7980;\n    }\n    if (_7988)\n    {\n        return vec3(0.0);\n    }\n    float _7995 = max(_7962.w, 9.9999997473787516355514526367188e-05);\n    vec3 _7998 = _7967.xyz;\n    vec3 _8002 = _7962.xyz;\n    vec3 _8006 = (fa_world_pos - _8002) / vec3(_7995);\n    vec3 _8015 = min(_8006 + vec3(0.5), (_7998 - vec3(0.5)) - _8006);\n    float _8024 = min(_8015.x, min(_8015.y, _8015.z));\n    if (!(_8024 > 0.0))\n    {\n        return vec3(0.0);\n    }\n    vec3 _8039 = _7998 - vec3(1.0);\n    vec3 _8040 = clamp(_8006, vec3(0.0), _8039);\n    vec3 _8048 = min(floor(_8040), max(_7998 - vec3(2.0), vec3(0.0)));\n    vec3 _8052 = _8040 - _8048;\n    vec3 _8063 = fa_world_pos + (((n * 0.800000011920928955078125) + (v * 0.20000000298023223876953125)) * (0.20000000298023223876953125 * _7995));\n    int _8068 = int(_7972.y + 0.5);\n    float _8073 = 0.3257350027561187744140625 * n.y;\n    float _8077 = 0.3257350027561187744140625 * n.z;\n    float _8081 = 0.3257350027561187744140625 * n.x;\n    float _8088 = (0.2731371223926544189453125 * n.x) * n.y;\n    float _8095 = (0.2731371223926544189453125 * n.y) * n.z;\n    float _8104 = 0.078847892582416534423828125 * (((3.0 * n.z) * n.z) - 1.0);\n    float _8111 = (0.2731371223926544189453125 * n.x) * n.z;\n    float _8124 = 0.13656856119632720947265625 * ((n.x * n.x) - (n.y * n.y));\n    vec3 acc = vec3(0.0);\n    float wsum = 0.0;\n    int _8131 = 8 + int(_7977.w);\n    float _8158;\n    float _8171;\n    float _8185;\n    for (int k = 0; k < _8131; k++)\n    {\n        float _8144 = float(k & 1);\n        float _8148 = float((k >> 1) & 1);\n        float _8152 = float((k >> 2) & 1);\n        if (_8144 > 0.5)\n        {\n            _8158 = _8052.x;\n        }\n        else\n        {\n            _8158 = 1.0 - _8052.x;\n        }\n        if (_8148 > 0.5)\n        {\n            _8171 = _8052.y;\n        }\n        else\n        {\n            _8171 = 1.0 - _8052.y;\n        }\n        if (_8152 > 0.5)\n        {\n            _8185 = _8052.z;\n        }\n        else\n        {\n            _8185 = 1.0 - _8052.z;\n        }\n        float _8195 = (_8158 * _8171) * _8185;\n        if (!(_8195 > 0.0))\n        {\n            continue;\n        }\n        vec3 _8208 = min(_8048 + vec3(_8144, _8148, _8152), _8039);\n        int _8228 = int(((_7972.x + _8208.x) + (_7967.x * (_8208.y + (_7967.y * _8208.z)))) + 0.5);\n        vec2 _8243 = vec2(float(_8228 % _8068) * 10.0, 1024.0 + (float(_8228 / _8068) * 11.0));\n        vec2 param_4 = _8243 + vec2(9.5, 10.5);\n        vec4 _8251 = fa_gi_fetch(param_4);\n        bool _8254 = _8251.y < 0.5;\n        bool _8263;\n        if (!_8254)\n        {\n            _8263 = _8251.x > _7977.y;\n        }\n        else\n        {\n            _8263 = _8254;\n        }\n        if (_8263)\n        {\n            continue;\n        }\n        vec3 _8275 = _8063 - (_8002 + (_8208 * _7995));\n        float _8278 = length(_8275);\n        vec3 _8284 = _8275 / vec3(max(_8278, 9.9999997473787516355514526367188e-05));\n        float _8294 = max(9.9999997473787516355514526367188e-05, (dot(-_8284, n) + 1.0) * 0.5);\n        float w = _8195 * (_8294 * _8294);\n        vec3 param_5 = _8284;\n        vec2 param_6 = (_8243 + vec2(1.0)) + (((fa_oct_encode(param_5) * 0.5) + vec2(0.5)) * 8.0);\n        vec4 _8313 = fa_gi_fetch(param_6);\n        float _8320 = _8278 / max(_7972.z, 9.9999997473787516355514526367188e-05);\n        float _8323 = _8313.x;\n        if (_8320 > _8323)\n        {\n            float _8336 = max(_8313.y - (_8323 * _8323), 0.0);\n            float _8341 = _8320 - _8323;\n            float _8350 = _8336 / max(_8336 + (_8341 * _8341), 9.9999999600419720025001879548654e-13);\n            w *= ((_8350 * _8350) * _8350);\n        }\n        if (!(w > 0.0))\n        {\n            continue;\n        }\n        vec2 param_7 = _8243 + vec2(0.5, 10.5);\n        vec2 param_8 = _8243 + vec2(1.5, 10.5);\n        vec2 param_9 = _8243 + vec2(2.5, 10.5);\n        vec2 param_10 = _8243 + vec2(3.5, 10.5);\n        vec2 param_11 = _8243 + vec2(4.5, 10.5);\n        vec2 param_12 = _8243 + vec2(5.5, 10.5);\n        vec2 param_13 = _8243 + vec2(6.5, 10.5);\n        vec2 param_14 = _8243 + vec2(7.5, 10.5);\n        vec2 param_15 = _8243 + vec2(8.5, 10.5);\n        acc += ((((((((((fa_gi_fetch(param_7).xyz * 0.2820948064327239990234375) + (fa_gi_fetch(param_8).xyz * _8073)) + (fa_gi_fetch(param_9).xyz * _8077)) + (fa_gi_fetch(param_10).xyz * _8081)) + (fa_gi_fetch(param_11).xyz * _8088)) + (fa_gi_fetch(param_12).xyz * _8095)) + (fa_gi_fetch(param_13).xyz * _8104)) + (fa_gi_fetch(param_14).xyz * _8111)) + (fa_gi_fetch(param_15).xyz * _8124)) * w);\n        wsum += w;\n    }\n    if (!(wsum > 9.9999997473787516355514526367188e-06))\n    {\n        return vec3(0.0);\n    }\n    cover = smoothstep(0.0, 1.0, clamp(_8024 * 2.0, 0.0, 1.0)) * smoothstep(0.0, 0.0199999995529651641845703125, wsum);\n    float _8475;\n    if (fa_mesh_fs_params[52].z > 0.5)\n    {\n        _8475 = _7977.x;\n    }\n    else\n    {\n        _8475 = 1.0;\n    }\n    return max(acc / vec3(wsum), vec3(0.0)) * (_7972.w * _8475);\n}\n\nvec3 fa_gi_light(vec3 n, inout float left)\n{\n    left = 1.0;\n    vec3 acc = vec3(0.0);\n    vec3 _8499 = normalize(fa_mesh_fs_params[0].xyz - fa_world_pos);\n    int _8504 = int(fa_mesh_fs_params[52].x + 0.5);\n    int _8509 = int(fa_mesh_fs_params[52].y + 0.5);\n    float param_3;\n    for (int k = 0; (k < _8509) && (k < 8); k++)\n    {\n        int param = _8504 + (4 * k);\n        vec3 param_1 = n;\n        vec3 param_2 = _8499;\n        vec3 _8534 = fa_gi_grid(param, param_1, param_2, param_3);\n        float _8539 = param_3 * left;\n        acc += (_8534 * _8539);\n        left -= _8539;\n        if (left < 0.001000000047497451305389404296875)\n        {\n            left = 0.0;\n            break;\n        }\n    }\n    return acc;\n}\n\nvec3 fa_realtime_or_ambient(vec3 n)\n{\n    vec3 gi = vec3(0.0);\n    float left = 1.0;\n    if (fa_mesh_fs_params[52].y > 0.5)\n    {\n        vec3 param = n;\n        float param_1;\n        vec3 _8568 = fa_gi_light(param, param_1);\n        left = param_1;\n        gi = _8568;\n    }\n    if (left <= 0.0)\n    {\n        return gi;\n    }\n    vec3 param_2 = n;\n    return gi + (fa_ambient_light(param_2) * left);\n}\n\nvec3 fa_indirect_diffuse(vec3 n)\n{\n    if (fa_lm.z > 0.5)\n    {\n        return textureLod(fa_lightmap_fa_env_smp, fa_lm.xy, 0.0).xyz;\n    }\n    if (fa_mesh_fs_params[53].x > 0.5)\n    {\n        vec4 _8610 = vec4(fa_world_pos, 1.0);\n        vec2 _8629 = vec2(dot(fa_mesh_fs_params[26], _8610), dot(fa_mesh_fs_params[27], _8610)) / vec2(max(dot(fa_mesh_fs_params[28], _8610), 9.9999997473787516355514526367188e-05));\n        float _8638;\n        if (fa_mesh_fs_params[24].y > 0.5)\n        {\n            _8638 = (_8629.y * 0.5) + 0.5;\n        }\n        else\n        {\n            _8638 = 0.5 - (_8629.y * 0.5);\n        }\n        return texelFetch(fa_lightmap_fa_env_smp, clamp(ivec2(vec2((_8629.x * 0.5) + 0.5, _8638) * fa_mesh_fs_params[24].zw), ivec2(0), ivec2(fa_mesh_fs_params[24].zw) - ivec2(1)), 0).xyz;\n    }\n    if (fa_mesh_fs_params[32].w > 0.0)\n    {\n        vec3 c[9];\n        for (int k = 0; k < 9; k++)\n        {\n            c[k] = fa_mesh_fs_params[k * 1 + 32].xyz;\n        }\n        vec3 param = n;\n        vec3 param_1[9] = c;\n        vec3 param_2 = n;\n        return mix(fa_ambient_light(param), fa_sh_eval(param_1, param_2), vec3(clamp(fa_mesh_fs_params[32].w, 0.0, 1.0)));\n    }\n    vec3 param_3 = n;\n    return fa_realtime_or_ambient(param_3);\n}\n\nint fa_cluster_index(int slot, int n)\n{\n    int param = (int(fa_mesh_fs_params[19].x) + int(fa_mesh_fs_params[19].w)) + ((slot + n) >> 2);\n    vec4 t = fa_light_texel(param);\n    return int(t[(slot + n) & 3]);\n}\n\nint fa_cl_light(int n)\n{\n    if (n < fa_cl_ndir)\n    {\n        return n;\n    }\n    int param = fa_cl_slot;\n    int param_1 = n - fa_cl_ndir;\n    return fa_cluster_index(param, param_1);\n}\n\nint fa_light_base(int li)\n{\n    return li * ((fa_mesh_fs_params[1].w > 4.5) ? 8 : 4);\n}\n\nbool fa_light_baked(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 3;\n    return fa_light_texel(param_1).w > 0.5;\n}\n\nfloat fa_baked_keep(int li)\n{\n    float _6420;\n    if (fa_lm.z > 0.5)\n    {\n        _6420 = 0.0;\n    }\n    else\n    {\n        _6420 = 1.0 - clamp(fa_mesh_fs_params[32].w, 0.0, 1.0);\n    }\n    bool _6431 = _6420 < 1.0;\n    bool _6437;\n    if (_6431)\n    {\n        int param = li;\n        _6437 = fa_light_baked(param);\n    }\n    else\n    {\n        _6437 = _6431;\n    }\n    return _6437 ? _6420 : 1.0;\n}\n\nfloat fa_light_type(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 1;\n    return fa_light_texel(param_1).w;\n}\n\nvec4 fa_atlas_fetch(vec2 texel)\n{\n    return textureLod(fa_light_atlas_fa_env_smp, texel / vec2(textureSize(fa_light_atlas_fa_env_smp, 0)), 0.0);\n}\n\nvec3 fa_cookie_sample(vec2 tile_origin, vec2 uv)\n{\n    vec2 param = (tile_origin + vec2(1.0)) + (clamp(uv, vec2(0.0), vec2(1.0)) * 254.0);\n    return fa_atlas_fetch(param).xyz;\n}\n\nvec3 fa_area_point(vec3 c, vec3 axis, vec3 ru, vec3 uu, float hx, float hy, float shape, vec3 p, vec3 r)\n{\n    bool _846 = dot(r, r) > 0.5;\n    if (shape > 1.5)\n    {\n        vec3 _859 = (c - (ru * hx)) - p;\n        vec3 _865 = ru * (2.0 * hx);\n        float _871 = max(dot(_865, _865), 9.9999999392252902907785028219223e-09);\n        float _875 = dot(_859, _865);\n        float t = clamp((-_875) / _871, 0.0, 1.0);\n        if (_846)\n        {\n            float _890 = dot(r, _865);\n            float _896 = _871 - (_890 * _890);\n            if (abs(_896) > (9.9999997473787516355514526367188e-06 * _871))\n            {\n                t = clamp(((dot(r, _859) * _890) - _875) / _896, 0.0, 1.0);\n            }\n        }\n        return (p + _859) + (_865 * t);\n    }\n    vec3 q = p;\n    float _928 = dot(r, axis);\n    bool _936;\n    if (_846)\n    {\n        _936 = abs(_928) > 9.9999997473787516355514526367188e-05;\n    }\n    else\n    {\n        _936 = _846;\n    }\n    if (_936)\n    {\n        float _946 = dot(c - p, axis) / _928;\n        if (_946 > 0.0)\n        {\n            q = p + (r * _946);\n        }\n    }\n    vec3 _959 = q - c;\n    vec2 xy = vec2(dot(_959, ru), dot(_959, uu));\n    if (shape > 0.5)\n    {\n        float _974 = length(xy);\n        if (_974 > hx)\n        {\n            xy *= (hx / _974);\n        }\n    }\n    else\n    {\n        xy = clamp(xy, vec2(-hx, -hy), vec2(hx, hy));\n    }\n    return (c + (ru * xy.x)) + (uu * xy.y);\n}\n\nint fa_cube_face(vec3 d)\n{\n    vec3 _608 = abs(d);\n    float _610 = _608.x;\n    float _612 = _608.y;\n    bool _613 = _610 >= _612;\n    bool _621;\n    if (_613)\n    {\n        _621 = _610 >= _608.z;\n    }\n    else\n    {\n        _621 = _613;\n    }\n    int _622;\n    if (_621)\n    {\n        _622 = (d.x > 0.0) ? 0 : 1;\n    }\n    else\n    {\n        int _636;\n        if (_612 >= _608.z)\n        {\n            _636 = (d.y > 0.0) ? 2 : 3;\n        }\n        else\n        {\n            _636 = (d.z > 0.0) ? 4 : 5;\n        }\n        _622 = _636;\n    }\n    return _622;\n}\n\nvoid fa_cube_face_basis(int f, out vec3 fwd, out vec3 up)\n{\n    if (f == 0)\n    {\n        fwd = vec3(1.0, 0.0, 0.0);\n        up = vec3(0.0, 1.0, 0.0);\n    }\n    else\n    {\n        if (f == 1)\n        {\n            fwd = vec3(-1.0, 0.0, 0.0);\n            up = vec3(0.0, 1.0, 0.0);\n        }\n        else\n        {\n            if (f == 2)\n            {\n                fwd = vec3(0.0, 1.0, 0.0);\n                up = vec3(0.0, 0.0, 1.0);\n            }\n            else\n            {\n                if (f == 3)\n                {\n                    fwd = vec3(0.0, -1.0, 0.0);\n                    up = vec3(0.0, 0.0, -1.0);\n                }\n                else\n                {\n                    if (f == 4)\n                    {\n                        fwd = vec3(0.0, 0.0, 1.0);\n                        up = vec3(0.0, 1.0, 0.0);\n                    }\n                    else\n                    {\n                        fwd = vec3(0.0, 0.0, -1.0);\n                        up = vec3(0.0, 1.0, 0.0);\n                    }\n                }\n            }\n        }\n    }\n}\n\nfloat fa_ies_sample(vec2 tile_origin, vec3 d, vec3 axis, vec3 right, vec3 up)\n{\n    float _766 = dot(d, right);\n    float _770 = dot(d, up);\n    float _781;\n    if (((_766 * _766) + (_770 * _770)) > 1.0000000133514319600180897396058e-10)\n    {\n        _781 = atan(_770, _766) * 0.15915493667125701904296875;\n    }\n    else\n    {\n        _781 = 0.0;\n    }\n    vec2 param = tile_origin + vec2(1.0 + ((_781 - floor(_781)) * 64.0), 1.0 + (acos(clamp(dot(d, axis), -1.0, 1.0)) * 10.18591594696044921875));\n    return fa_atlas_fetch(param).x;\n}\n\nLightSample fa_light_sample_n(int li, vec3 world_pos, vec3 n)\n{\n    int param = li;\n    int _1012 = fa_light_base(param);\n    bool _1016 = fa_mesh_fs_params[1].w > 4.5;\n    int param_1 = _1012;\n    vec4 _1020 = fa_light_texel(param_1);\n    int param_2 = _1012 + 1;\n    vec4 _1025 = fa_light_texel(param_2);\n    float _1028 = _1025.w;\n    float atten = 1.0;\n    float dist = 0.0;\n    fa_light_tint = vec3(1.0);\n    bool _1040 = _1016 && (_1028 > 2.5);\n    fa_light_is_area = _1040;\n    bool _1042 = _1028 < 0.5;\n    vec3 l;\n    if (_1042)\n    {\n        l = normalize(_1020.xyz);\n        if (_1016)\n        {\n            int param_3 = _1012 + 6;\n            vec4 _1056 = fa_light_texel(param_3);\n            if (_1056.z > 0.5)\n            {\n                int param_4 = _1012 + 4;\n                vec4 _1066 = fa_light_texel(param_4);\n                int param_5 = _1012 + 5;\n                vec4 _1071 = fa_light_texel(param_5);\n                vec2 param_6 = _1056.xy;\n                vec2 param_7 = fract(vec2(dot(world_pos, _1066.xyz) * _1066.w, (-dot(world_pos, _1071.xyz)) * _1071.w) + vec2(0.5));\n                fa_light_tint = fa_cookie_sample(param_6, param_7);\n            }\n        }\n    }\n    else\n    {\n        vec3 _1101 = _1020.xyz;\n        vec3 _1103 = _1101 - world_pos;\n        vec3 to_light = _1103;\n        float _1106 = length(_1103);\n        float reach = _1106;\n        bool front = true;\n        if (_1040)\n        {\n            int param_8 = _1012 + 7;\n            reach = max(_1106 - fa_light_texel(param_8).w, 0.0);\n            int param_9 = _1012 + 4;\n            vec4 _1130 = fa_light_texel(param_9);\n            int param_10 = _1012 + 5;\n            vec4 _1135 = fa_light_texel(param_10);\n            int param_11 = _1012 + 6;\n            vec4 _1140 = fa_light_texel(param_11);\n            float _1141 = _1140.w;\n            int param_12 = _1012 + 2;\n            vec3 _1148 = normalize(fa_light_texel(param_12).xyz);\n            bool _1150 = _1141 > 1.5;\n            bool _1158;\n            if (!_1150)\n            {\n                _1158 = dot(_1148, to_light) < 0.0;\n            }\n            else\n            {\n                _1158 = _1150;\n            }\n            front = _1158;\n            vec3 r = vec3(0.0);\n            vec3 _1167 = fa_mesh_fs_params[0].xyz - world_pos;\n            bool _1171 = dot(n, n) > 0.5;\n            bool _1179;\n            if (_1171)\n            {\n                _1179 = dot(_1167, _1167) > 9.9999999600419720025001879548654e-13;\n            }\n            else\n            {\n                _1179 = _1171;\n            }\n            if (_1179)\n            {\n                r = reflect(-normalize(_1167), normalize(n));\n            }\n            vec3 param_13 = _1101;\n            vec3 param_14 = _1148;\n            vec3 param_15 = _1130.xyz;\n            vec3 param_16 = _1135.xyz;\n            float param_17 = _1130.w;\n            float param_18 = _1135.w;\n            float param_19 = _1141;\n            vec3 param_20 = world_pos;\n            vec3 param_21 = r;\n            to_light = fa_area_point(param_13, param_14, param_15, param_16, param_17, param_18, param_19, param_20, param_21) - world_pos;\n        }\n        float _1215 = length(to_light);\n        dist = _1215;\n        l = to_light / vec3(max(_1215, 9.9999997473787516355514526367188e-05));\n        float _1229 = reach / max(_1020.w, 0.001000000047497451305389404296875);\n        float _1235 = clamp(1.0 - (_1229 * _1229), 0.0, 1.0);\n        float _1237;\n        if (front)\n        {\n            _1237 = _1235 * _1235;\n        }\n        else\n        {\n            _1237 = 0.0;\n        }\n        atten = _1237;\n        bool _1248 = _1028 < 2.5;\n        if ((_1028 > 1.5) && _1248)\n        {\n            int param_22 = _1012 + 2;\n            vec4 _1256 = fa_light_texel(param_22);\n            float _1266 = _1256.w;\n            int param_23 = _1012 + 3;\n            vec4 _1271 = fa_light_texel(param_23);\n            float _1272 = _1271.x;\n            float cos_inner = _1272;\n            if (_1272 > 1.5)\n            {\n                cos_inner = mix(_1266, 1.0, 0.25);\n            }\n            atten *= smoothstep(_1266, cos_inner, dot(-l, normalize(_1256.xyz)));\n        }\n        if (_1016 && (_1028 < 1.5))\n        {\n            int param_24 = _1012 + 6;\n            vec4 _1296 = fa_light_texel(param_24);\n            if (_1296.z > 0.5)\n            {\n                vec3 _1304 = -to_light;\n                int param_25 = _1012 + 4;\n                int param_26 = _1012 + 5;\n                vec3 _1318 = fa_light_texel(param_25).xyz;\n                vec3 _1322 = fa_light_texel(param_26).xyz;\n                vec3 _1331 = vec3(dot(_1304, _1318), dot(_1304, _1322), dot(_1304, cross(_1318, _1322)));\n                vec3 param_27 = _1331;\n                int _1335 = fa_cube_face(param_27);\n                int param_28 = _1335;\n                vec3 param_29;\n                vec3 param_30;\n                fa_cube_face_basis(param_28, param_29, param_30);\n                vec2 _1362 = vec2(dot(_1331, cross(param_29, param_30)), dot(_1331, param_30)) / vec2(max(dot(_1331, param_29), 9.9999997473787516355514526367188e-05));\n                int _1366 = _1335 / 3;\n                vec2 param_31 = _1296.xy + (vec2(float(_1335 - (_1366 * 3)), float(_1366)) * 256.0);\n                vec2 param_32 = vec2(0.5 + (0.5 * _1362.x), 0.5 - (0.5 * _1362.y));\n                fa_light_tint = fa_cookie_sample(param_31, param_32);\n            }\n            int param_33 = _1012 + 7;\n            vec4 _1396 = fa_light_texel(param_33);\n            if (_1396.z > 0.5)\n            {\n                int param_34 = _1012 + 2;\n                int param_35 = _1012 + 4;\n                int param_36 = _1012 + 5;\n                vec2 param_37 = _1396.xy;\n                vec3 param_38 = -l;\n                vec3 param_39 = normalize(fa_light_texel(param_34).xyz);\n                vec3 param_40 = fa_light_texel(param_35).xyz;\n                vec3 param_41 = fa_light_texel(param_36).xyz;\n                atten *= fa_ies_sample(param_37, param_38, param_39, param_40, param_41);\n            }\n        }\n        else\n        {\n            if (_1016 && _1248)\n            {\n                int param_42 = _1012 + 6;\n                vec4 _1443 = fa_light_texel(param_42);\n                int param_43 = _1012 + 7;\n                vec4 _1448 = fa_light_texel(param_43);\n                bool _1451 = _1443.z > 0.5;\n                bool _1458;\n                if (!_1451)\n                {\n                    _1458 = _1448.z > 0.5;\n                }\n                else\n                {\n                    _1458 = _1451;\n                }\n                if (_1458)\n                {\n                    int param_44 = _1012 + 2;\n                    vec4 _1465 = fa_light_texel(param_44);\n                    vec3 _1469 = normalize(_1465.xyz);\n                    int param_45 = _1012 + 4;\n                    vec4 _1474 = fa_light_texel(param_45);\n                    int param_46 = _1012 + 5;\n                    vec4 _1479 = fa_light_texel(param_46);\n                    if (_1451)\n                    {\n                        vec3 _1487 = -to_light;\n                        float _1494 = _1465.w;\n                        float _1510 = 0.5 / max(dot(_1487, _1469) * (sqrt(max(1.0 - (_1494 * _1494), 0.0)) / max(_1494, 0.001000000047497451305389404296875)), 9.9999997473787516355514526367188e-05);\n                        vec2 param_47 = _1443.xy;\n                        vec2 param_48 = vec2(0.5 + (dot(_1487, _1474.xyz) * _1510), 0.5 - (dot(_1487, _1479.xyz) * _1510));\n                        fa_light_tint = fa_cookie_sample(param_47, param_48);\n                    }\n                    if (_1448.z > 0.5)\n                    {\n                        vec2 param_49 = _1448.xy;\n                        vec3 param_50 = -l;\n                        vec3 param_51 = _1469;\n                        vec3 param_52 = _1474.xyz;\n                        vec3 param_53 = _1479.xyz;\n                        atten *= fa_ies_sample(param_49, param_50, param_51, param_52, param_53);\n                    }\n                }\n            }\n        }\n    }\n    vec3 _9725 = _1025.xyz * atten;\n    if (_1016)\n    {\n        _9725 *= fa_light_tint;\n    }\n    int _1579;\n    if (_1042)\n    {\n        _1579 = 0;\n    }\n    else\n    {\n        _1579 = ((_1028 > 1.5) && (_1028 < 2.5)) ? 2 : 1;\n    }\n    return LightSample(l, _9725, atten, 1.0, dist, _1579);\n}\n\nfloat fa_shadow_split_at(int i)\n{\n    float _2311;\n    if (i == 0)\n    {\n        _2311 = fa_shadows[24].x;\n    }\n    else\n    {\n        float _2327;\n        if (i == 1)\n        {\n            _2327 = fa_shadows[24].y;\n        }\n        else\n        {\n            float _2335;\n            if (i == 2)\n            {\n                _2335 = fa_shadows[24].z;\n            }\n            else\n            {\n                _2335 = fa_shadows[24].w;\n            }\n            _2327 = _2335;\n        }\n        _2311 = _2327;\n    }\n    return _2311;\n}\n\nfloat fa_shadow_depth(inout vec2 uv, vec4 rect)\n{\n    uv = clamp(uv, rect.xy, rect.zw);\n    return textureLod(fa_shadow_tex_fa_shadow_smp, uv, 0.0).x;\n}\n\nfloat fa_shadow_fetch(vec2 uv, vec4 rect, vec3 conv)\n{\n    vec2 param = uv;\n    vec4 param_1 = rect;\n    float _2368 = fa_shadow_depth(param, param_1);\n    float _2372;\n    if (conv.x < 0.5)\n    {\n        _2372 = _2368;\n    }\n    else\n    {\n        _2372 = (conv.y * conv.z) / (conv.z - (_2368 * (conv.z - conv.y)));\n    }\n    return _2372;\n}\n\nfloat fa_shadow_noise()\n{\n    return fract(52.98291778564453125 * fract(dot(gl_FragCoord.xy, vec2(0.067110560834407806396484375, 0.005837149918079376220703125))));\n}\n\nvec2 fa_shadow_vogel_turn(vec2 d)\n{\n    return vec2((d.x * (-0.737368881702423095703125)) - (d.y * 0.675490319728851318359375), (d.y * (-0.737368881702423095703125)) + (d.x * 0.675490319728851318359375));\n}\n\nfloat fa_shadow_filter(vec2 uv, vec4 rect, float zr, float texel_m, float unit, float reach, float plane, vec3 conv, int mode, float k)\n{\n    if (mode == 1)\n    {\n        vec2 param = uv;\n        vec4 param_1 = rect;\n        vec3 param_2 = conv;\n        return float(zr <= fa_shadow_fetch(param, param_1, param_2));\n    }\n    float _2418 = fa_shadow_noise() * 6.283185482025146484375;\n    vec2 _2424 = vec2(cos(_2418), sin(_2418));\n    vec2 dir = _2424;\n    float radius = 1.5;\n    if (mode == 2)\n    {\n        float _2433;\n        if (k < 0.0)\n        {\n            _2433 = (-k) / max(zr, 0.100000001490116119384765625);\n        }\n        else\n        {\n            _2433 = k;\n        }\n        float _2452 = clamp((_2433 * reach) / texel_m, 3.0, 12.0);\n        float sum = 0.0;\n        float cnt = 0.0;\n        for (int i = 0; i < 16; i++)\n        {\n            float _2471 = sqrt((float(i) + 0.5) * 0.0625) * _2452;\n            vec2 param_3 = uv + (dir * (fa_shadows[26].zw * _2471));\n            vec4 param_4 = rect;\n            vec3 param_5 = conv;\n            float _2485 = fa_shadow_fetch(param_3, param_4, param_5);\n            if (_2485 < (zr - (_2471 * plane)))\n            {\n                sum += _2485;\n                cnt += 1.0;\n            }\n            vec2 param_6 = dir;\n            dir = fa_shadow_vogel_turn(param_6);\n        }\n        if (cnt < 0.5)\n        {\n            return 1.0;\n        }\n        float _2513 = sum / cnt;\n        float _2523;\n        if (k < 0.0)\n        {\n            _2523 = (-k) / max(_2513, 0.0500000007450580596923828125);\n        }\n        else\n        {\n            _2523 = k;\n        }\n        radius = clamp(((max(zr - _2513, 0.0) * unit) * _2523) / texel_m, 1.5, 16.0);\n        dir = _2424;\n    }\n    float lit = 0.0;\n    int _2549 = (mode == 2) ? 24 : 16;\n    for (int i_1 = 0; i_1 < _2549; i_1++)\n    {\n        float _2568 = sqrt((float(i_1) + 0.5) / float(_2549)) * radius;\n        vec2 param_7 = uv + (dir * (fa_shadows[26].zw * _2568));\n        vec4 param_8 = rect;\n        vec3 param_9 = conv;\n        lit += float((zr - (_2568 * plane)) <= fa_shadow_fetch(param_7, param_8, param_9));\n        vec2 param_10 = dir;\n        dir = fa_shadow_vogel_turn(param_10);\n    }\n    return lit / float(_2549);\n}\n\nfloat fa_shadow_cascade(int ci, vec3 world, vec3 n, vec3 l)\n{\n    float _2614 = max(fa_shadows[ci * 1 + 20].y, 0.001000000047497451305389404296875);\n    float _2619 = clamp(dot(n, l), 0.0, 1.0);\n    float _2625 = sqrt(1.0 - (_2619 * _2619));\n    float _2633 = min(_2625 / max(_2619, 0.20000000298023223876953125), 4.0);\n    float _2638;\n    if (fa_shadows[26].y > 0.0)\n    {\n        _2638 = fa_shadows[26].y;\n    }\n    else\n    {\n        _2638 = 1.5 * fa_shadows[ci * 1 + 20].x;\n    }\n    vec4 _2663 = mat4(fa_shadows[ci * 4 + 0], fa_shadows[ci * 4 + 1], fa_shadows[ci * 4 + 2], fa_shadows[ci * 4 + 3]) * vec4(world + (n * (_2638 * _2625)), 1.0);\n    float _2670 = _2663.x;\n    bool _2673 = _2670 < fa_shadows[ci * 1 + 16].x;\n    bool _2682;\n    if (!_2673)\n    {\n        _2682 = _2670 > fa_shadows[ci * 1 + 16].z;\n    }\n    else\n    {\n        _2682 = _2673;\n    }\n    bool _2691;\n    if (!_2682)\n    {\n        _2691 = _2663.y < fa_shadows[ci * 1 + 16].y;\n    }\n    else\n    {\n        _2691 = _2682;\n    }\n    bool _2700;\n    if (!_2691)\n    {\n        _2700 = _2663.y > fa_shadows[ci * 1 + 16].w;\n    }\n    else\n    {\n        _2700 = _2691;\n    }\n    bool _2707;\n    if (!_2700)\n    {\n        _2707 = _2663.z > 1.0;\n    }\n    else\n    {\n        _2707 = _2700;\n    }\n    if (_2707)\n    {\n        return -1.0;\n    }\n    float _2715;\n    if (fa_shadows[26].x > 0.0)\n    {\n        _2715 = fa_shadows[26].x;\n    }\n    else\n    {\n        _2715 = 1.5 * fa_shadows[ci * 1 + 20].x;\n    }\n    vec2 param = _2663.xy;\n    vec4 param_1 = fa_shadows[ci * 1 + 16];\n    float param_2 = _2663.z - ((_2715 * (1.0 + (0.5 * _2633))) / _2614);\n    float param_3 = fa_shadows[ci * 1 + 20].x;\n    float param_4 = _2614;\n    float param_5 = _2614 * 0.25;\n    float param_6 = ((fa_shadows[ci * 1 + 20].x * min(_2633, 3.0)) * 0.5) / _2614;\n    vec3 param_7 = vec3(0.0);\n    int param_8 = int(fa_shadows[25].z + 0.5);\n    float param_9 = fa_shadows[25].w;\n    return fa_shadow_filter(param, param_1, param_2, param_3, param_4, param_5, param_6, param_7, param_8, param_9);\n}\n\nfloat fa_shadow_sun(vec3 world, vec3 n, vec3 l)\n{\n    if (fa_mesh_fs_params[5].z < 0.5)\n    {\n        return 1.0;\n    }\n    int _3093 = int(fa_shadows[25].x + 0.5);\n    if (_3093 < 1)\n    {\n        return 1.0;\n    }\n    float _3108 = dot(world - fa_shadows[27].xyz, fa_shadows[28].xyz);\n    int param = _3093 - 1;\n    if (_3108 > fa_shadow_split_at(param))\n    {\n        return 1.0;\n    }\n    int ci = 0;\n    bool _3120 = _3093 > 1;\n    bool _3127;\n    if (_3120)\n    {\n        _3127 = _3108 > fa_shadows[24].x;\n    }\n    else\n    {\n        _3127 = _3120;\n    }\n    if (_3127)\n    {\n        ci = 1;\n    }\n    bool _3131 = _3093 > 2;\n    bool _3138;\n    if (_3131)\n    {\n        _3138 = _3108 > fa_shadows[24].y;\n    }\n    else\n    {\n        _3138 = _3131;\n    }\n    if (_3138)\n    {\n        ci = 2;\n    }\n    bool _3142 = _3093 > 3;\n    bool _3149;\n    if (_3142)\n    {\n        _3149 = _3108 > fa_shadows[24].z;\n    }\n    else\n    {\n        _3149 = _3142;\n    }\n    if (_3149)\n    {\n        ci = 3;\n    }\n    float s = -1.0;\n    float s2 = -1.0;\n    float t = 0.0;\n    int _3160 = min(_3093, 4);\n    float _3201;\n    for (int c = ci; c < _3160; c++)\n    {\n        int param_1 = c;\n        vec3 param_2 = world;\n        vec3 param_3 = n;\n        vec3 param_4 = l;\n        float _3180 = fa_shadow_cascade(param_1, param_2, param_3, param_4);\n        if (s >= 0.0)\n        {\n            s2 = _3180;\n            break;\n        }\n        if (_3180 < 0.0)\n        {\n            continue;\n        }\n        s = _3180;\n        ci = c;\n        if (fa_shadows[25].y > 0.0)\n        {\n            if (ci > 0)\n            {\n                int param_5 = ci - 1;\n                _3201 = fa_shadow_split_at(param_5);\n            }\n            else\n            {\n                _3201 = fa_shadows[28].w;\n            }\n            int param_6 = ci;\n            float _3220 = fa_shadows[25].y * max(fa_shadow_split_at(param_6) - _3201, 9.9999997473787516355514526367188e-05);\n            int param_7 = ci;\n            t = clamp((_3108 - (fa_shadow_split_at(param_7) - _3220)) / _3220, 0.0, 1.0);\n        }\n        if (t <= 0.0)\n        {\n            break;\n        }\n    }\n    if (s < 0.0)\n    {\n        return 1.0;\n    }\n    if (t > 0.0)\n    {\n        float _3252;\n        if ((ci + 1) < _3093)\n        {\n            _3252 = (s2 < 0.0) ? s : s2;\n        }\n        else\n        {\n            _3252 = 1.0;\n        }\n        s = mix(s, _3252, t);\n    }\n    return s;\n}\n\nfloat fa_shadow_factor(vec3 n, vec3 l)\n{\n    bool _3357 = fa_mesh_fs_params[25].y > 0.5;\n    bool _3363;\n    if (_3357)\n    {\n        _3363 = fa_mesh_fs_params[5].z > 0.5;\n    }\n    else\n    {\n        _3363 = _3357;\n    }\n    if (_3363)\n    {\n        float _3377 = dot(fa_mesh_fs_params[29].xyz, fa_world_pos) + fa_mesh_fs_params[29].w;\n        vec4 _3385 = vec4(fa_world_pos, 1.0);\n        float _3391 = dot(fa_mesh_fs_params[28], _3385);\n        if (_3391 > 9.9999997473787516355514526367188e-05)\n        {\n            vec2 _3410 = vec2(dot(fa_mesh_fs_params[26], _3385), dot(fa_mesh_fs_params[27], _3385)) / vec2(_3391);\n            float _3415 = (_3410.x * 0.5) + 0.5;\n            float _3419;\n            if (fa_mesh_fs_params[24].y > 0.5)\n            {\n                _3419 = (_3410.y * 0.5) + 0.5;\n            }\n            else\n            {\n                _3419 = 0.5 - (_3410.y * 0.5);\n            }\n            bool _3435 = _3415 >= 0.0;\n            bool _3441;\n            if (_3435)\n            {\n                _3441 = _3415 < 1.0;\n            }\n            else\n            {\n                _3441 = _3435;\n            }\n            bool _3447;\n            if (_3441)\n            {\n                _3447 = _3419 >= 0.0;\n            }\n            else\n            {\n                _3447 = _3441;\n            }\n            bool _3453;\n            if (_3447)\n            {\n                _3453 = _3419 < 1.0;\n            }\n            else\n            {\n                _3453 = _3447;\n            }\n            if (_3453)\n            {\n                vec4 _3479 = texelFetch(fa_screen_tex_fa_shadow_smp, clamp(ivec2(vec2(_3415, _3419) * fa_mesh_fs_params[24].zw), ivec2(0), ivec2(fa_mesh_fs_params[24].zw) - ivec2(1)), 0);\n                bool _3482 = _3479.w > 0.5;\n                bool _3498;\n                if (_3482)\n                {\n                    _3498 = abs(_3377 - _3479.x) <= (((0.00200000009499490261077880859375 * _3377) + 0.00999999977648258209228515625) + fa_rt_slope);\n                }\n                else\n                {\n                    _3498 = _3482;\n                }\n                if (_3498)\n                {\n                    float _3504;\n                    if (fa_mesh_fs_params[25].z > 0.5)\n                    {\n                        vec3 param = fa_world_pos;\n                        vec3 param_1 = n;\n                        vec3 param_2 = l;\n                        _3504 = min(_3479.y, fa_shadow_sun(param, param_1, param_2));\n                    }\n                    else\n                    {\n                        _3504 = _3479.y;\n                    }\n                    return _3504;\n                }\n            }\n        }\n    }\n    vec3 param_3 = fa_world_pos;\n    vec3 param_4 = n;\n    vec3 param_5 = l;\n    return fa_shadow_sun(param_3, param_4, param_5);\n}\n\nfloat fa_shadow_local(int li, vec3 lpos, vec3 world, vec3 n, vec3 l)\n{\n    bool _2773 = fa_mesh_fs_params[5].z < 0.5;\n    bool _2780;\n    if (!_2773)\n    {\n        _2780 = fa_shadows[29].x < 0.5;\n    }\n    else\n    {\n        _2780 = _2773;\n    }\n    if (_2780)\n    {\n        return 1.0;\n    }\n    int param = (int(fa_shadows[29].x + 0.5) - 1) + li;\n    vec4 _2793 = fa_light_texel(param);\n    float _2794 = _2793.x;\n    if (_2794 < 0.0)\n    {\n        return 1.0;\n    }\n    int _2803 = int(_2794 + 0.5);\n    int param_1 = _2803;\n    vec4 _2807 = fa_light_texel(param_1);\n    int param_2 = _2803 + 1;\n    vec4 _2812 = fa_light_texel(param_2);\n    float fade = 1.0;\n    float _2815 = _2807.y;\n    if (_2815 > 0.0)\n    {\n        float _2832 = 1.0 - smoothstep(0.75 * _2815, _2815, length(world - fa_shadows[27].xyz));\n        fade = _2832;\n        if (_2832 <= 0.0)\n        {\n            return 1.0;\n        }\n    }\n    int face = 0;\n    if (_2807.x > 1.5)\n    {\n        vec3 param_3 = world - lpos;\n        face = fa_cube_face(param_3);\n    }\n    int _2856 = (_2803 + 2) + (face * 6);\n    int param_4 = _2856;\n    int param_5 = _2856 + 1;\n    int param_6 = _2856 + 3;\n    vec4 _2870 = fa_light_texel(param_6);\n    int param_7 = _2856 + 4;\n    vec4 _2875 = fa_light_texel(param_7);\n    int param_8 = _2856 + 5;\n    vec4 _2880 = fa_light_texel(param_8);\n    float _2892 = _2880.x * max(dot(_2870, vec4(world, 1.0)), 0.001000000047497451305389404296875);\n    float _2897 = clamp(dot(n, l), 0.0, 1.0);\n    float _2920 = clamp(dot(n, _2870.xyz), -1.0, 1.0);\n    float _2939 = min(sqrt(1.0 - (_2920 * _2920)) / max(abs(dot(n, world - lpos)) / max(dot(_2870, vec4(world, 1.0)), 0.001000000047497451305389404296875), 0.20000000298023223876953125), 4.0);\n    float _2942 = _2812.y;\n    float _2944;\n    if (_2942 > 0.0)\n    {\n        _2944 = _2942;\n    }\n    else\n    {\n        _2944 = 1.5 * _2892;\n    }\n    vec4 _2964 = vec4(world + (n * (_2944 * sqrt(1.0 - (_2897 * _2897)))), 1.0);\n    float _2968 = dot(_2870, _2964);\n    float _2971 = _2880.y;\n    if (_2968 < _2971)\n    {\n        return 1.0;\n    }\n    vec2 _2986 = vec2(dot(fa_light_texel(param_4), _2964), dot(fa_light_texel(param_5), _2964)) / vec2(_2968);\n    float _2988 = _2986.x;\n    bool _2991 = _2988 < _2875.x;\n    bool _3000;\n    if (!_2991)\n    {\n        _3000 = _2988 > _2875.z;\n    }\n    else\n    {\n        _3000 = _2991;\n    }\n    bool _3009;\n    if (!_3000)\n    {\n        _3009 = _2986.y < _2875.y;\n    }\n    else\n    {\n        _3009 = _3000;\n    }\n    bool _3018;\n    if (!_3009)\n    {\n        _3018 = _2986.y > _2875.w;\n    }\n    else\n    {\n        _3018 = _3009;\n    }\n    if (_3018)\n    {\n        return 1.0;\n    }\n    float _3024 = _2812.x;\n    float _3026;\n    if (_3024 > 0.0)\n    {\n        _3026 = _3024;\n    }\n    else\n    {\n        _3026 = 1.5 * _2892;\n    }\n    vec2 param_9 = _2986;\n    vec4 param_10 = _2875;\n    float param_11 = _2968 - (_3026 * (1.0 + (0.5 * _2939)));\n    float param_12 = _2892;\n    float param_13 = 1.0;\n    float param_14 = _2880.z * 0.25;\n    float param_15 = (_2892 * min(_2939, 3.0)) * 0.5;\n    vec3 param_16 = vec3(1.0, _2971, _2880.z);\n    int param_17 = int(_2807.z + 0.5);\n    float param_18 = _2807.w;\n    return mix(1.0, fa_shadow_filter(param_9, param_10, param_11, param_12, param_13, param_14, param_15, param_16, param_17, param_18), fade);\n}\n\nfloat fa_shadow_local_rt(int li, vec3 lpos, vec3 world, vec3 n, vec3 l)\n{\n    bool _3533 = fa_mesh_fs_params[25].w > 0.5;\n    bool _3539;\n    if (_3533)\n    {\n        _3539 = fa_mesh_fs_params[5].z > 0.5;\n    }\n    else\n    {\n        _3539 = _3533;\n    }\n    bool _3545;\n    if (_3539)\n    {\n        _3545 = fa_shadows[29].x > 0.5;\n    }\n    else\n    {\n        _3545 = _3539;\n    }\n    if (_3545)\n    {\n        int param = (int(fa_shadows[29].x + 0.5) - 1) + li;\n        vec4 _3557 = fa_light_texel(param);\n        float _3558 = _3557.z;\n        if (_3558 > 0.5)\n        {\n            float _3571 = dot(fa_mesh_fs_params[29].xyz, world) + fa_mesh_fs_params[29].w;\n            float _3577 = ((0.00200000009499490261077880859375 * _3571) + 0.00999999977648258209228515625) + fa_rt_slope;\n            vec4 _3583 = vec4(world, 1.0);\n            float _3588 = dot(fa_mesh_fs_params[28], _3583);\n            if (_3588 > 9.9999997473787516355514526367188e-05)\n            {\n                vec2 _3605 = vec2(dot(fa_mesh_fs_params[26], _3583), dot(fa_mesh_fs_params[27], _3583)) / vec2(_3588);\n                float _3610 = (_3605.x * 0.5) + 0.5;\n                float _3614;\n                if (fa_mesh_fs_params[24].y > 0.5)\n                {\n                    _3614 = (_3605.y * 0.5) + 0.5;\n                }\n                else\n                {\n                    _3614 = 0.5 - (_3605.y * 0.5);\n                }\n                bool _3630 = _3610 >= 0.0;\n                bool _3636;\n                if (_3630)\n                {\n                    _3636 = _3610 < 1.0;\n                }\n                else\n                {\n                    _3636 = _3630;\n                }\n                bool _3642;\n                if (_3636)\n                {\n                    _3642 = _3614 >= 0.0;\n                }\n                else\n                {\n                    _3642 = _3636;\n                }\n                bool _3648;\n                if (_3642)\n                {\n                    _3648 = _3614 < 1.0;\n                }\n                else\n                {\n                    _3648 = _3642;\n                }\n                if (_3648)\n                {\n                    ivec2 _3665 = ivec2(fa_mesh_fs_params[24].zw) - ivec2(1);\n                    ivec2 _3666 = clamp(ivec2(vec2(_3610, _3614) * fa_mesh_fs_params[24].zw), ivec2(0), _3665);\n                    float _3670;\n                    if (_3558 < 1.5)\n                    {\n                        _3670 = 1.0;\n                    }\n                    else\n                    {\n                        _3670 = (_3558 < 2.5) ? 256.0 : 65536.0;\n                    }\n                    float best = 2.0;\n                    int _3692;\n                    int _3698;\n                    for (int k = 0; k < 9; k++)\n                    {\n                        if (k == 0)\n                        {\n                            _3692 = 4;\n                        }\n                        else\n                        {\n                            if (k <= 4)\n                            {\n                                _3698 = k - 1;\n                            }\n                            else\n                            {\n                                _3698 = k;\n                            }\n                            _3692 = _3698;\n                        }\n                        vec4 _3727 = texelFetch(fa_screen_tex_fa_shadow_smp, clamp(_3666 + ivec2((_3692 % 3) - 1, (_3692 / 3) - 1), ivec2(0), _3665), 0);\n                        bool _3730 = _3727.w > 0.5;\n                        bool _3740;\n                        if (_3730)\n                        {\n                            _3740 = abs(_3571 - _3727.x) <= _3577;\n                        }\n                        else\n                        {\n                            _3740 = _3730;\n                        }\n                        if (_3740)\n                        {\n                            best = min(best, mod(floor(_3727.z / _3670), 256.0) * 0.0039215688593685626983642578125);\n                            if (k == 0)\n                            {\n                                break;\n                            }\n                        }\n                    }\n                    if (best <= 1.0)\n                    {\n                        float _3767;\n                        if (fa_mesh_fs_params[25].z > 0.5)\n                        {\n                            int param_1 = li;\n                            vec3 param_2 = lpos;\n                            vec3 param_3 = world;\n                            vec3 param_4 = n;\n                            vec3 param_5 = l;\n                            _3767 = min(best, fa_shadow_local(param_1, param_2, param_3, param_4, param_5));\n                        }\n                        else\n                        {\n                            _3767 = best;\n                        }\n                        return _3767;\n                    }\n                }\n            }\n            float _3790;\n            if (fa_mesh_fs_params[25].z > 0.5)\n            {\n                int param_6 = li;\n                vec3 param_7 = lpos;\n                vec3 param_8 = world;\n                vec3 param_9 = n;\n                vec3 param_10 = l;\n                _3790 = fa_shadow_local(param_6, param_7, param_8, param_9, param_10);\n            }\n            else\n            {\n                _3790 = 1.0;\n            }\n            return _3790;\n        }\n    }\n    int param_11 = li;\n    vec3 param_12 = lpos;\n    vec3 param_13 = world;\n    vec3 param_14 = n;\n    vec3 param_15 = l;\n    return fa_shadow_local(param_11, param_12, param_13, param_14, param_15);\n}\n\nfloat fa_contact_shadow(int li, vec3 world, vec3 gn, vec3 l, float dist)\n{\n    bool _5634 = fa_mesh_fs_params[24].x < 0.5;\n    bool _5641;\n    if (!_5634)\n    {\n        _5641 = fa_shadows[29].x < 0.5;\n    }\n    else\n    {\n        _5641 = _5634;\n    }\n    if (_5641)\n    {\n        return 1.0;\n    }\n    int param = (int(fa_shadows[29].x + 0.5) - 1) + li;\n    vec4 _5654 = fa_light_texel(param);\n    float _5655 = _5654.y;\n    float len = _5655;\n    if (_5655 <= 0.0)\n    {\n        return 1.0;\n    }\n    float _5667 = length(world - fa_mesh_fs_params[0].xyz);\n    float _5676 = 1.0 - smoothstep(0.5 * fa_mesh_fs_params[25].x, fa_mesh_fs_params[25].x, _5667);\n    if (_5676 <= 0.0)\n    {\n        return 1.0;\n    }\n    float _5682 = len;\n    float _5685 = min(_5682, 0.89999997615814208984375 * dist);\n    len = _5685;\n    float _5690 = 0.004999999888241291046142578125 + (0.0030000000260770320892333984375 * _5667);\n    float _5695 = _5690 + (0.5 * _5685);\n    vec3 _5701 = world + (gn * _5690);\n    float _5703 = fa_shadow_noise();\n    float occ = 0.0;\n    float _5764;\n    for (int k = 0; k < 12; k++)\n    {\n        float _5718 = (float(k) + _5703) * 0.083333335816860198974609375;\n        vec3 _5726 = _5701 + (l * (_5718 * len));\n        vec4 _5732 = vec4(_5726, 1.0);\n        float _5737 = dot(fa_mesh_fs_params[28], _5732);\n        if (_5737 < 9.9999997473787516355514526367188e-05)\n        {\n            break;\n        }\n        vec2 _5755 = vec2(dot(fa_mesh_fs_params[26], _5732), dot(fa_mesh_fs_params[27], _5732)) / vec2(_5737);\n        float _5759 = _5755.x * 0.5;\n        float _5760 = _5759 + 0.5;\n        if (fa_mesh_fs_params[24].y > 0.5)\n        {\n            _5764 = (_5755.y * 0.5) + 0.5;\n        }\n        else\n        {\n            _5764 = 0.5 - (_5755.y * 0.5);\n        }\n        bool _5780 = _5760 < 0.0;\n        bool _5787;\n        if (!_5780)\n        {\n            _5787 = _5760 >= 1.0;\n        }\n        else\n        {\n            _5787 = _5780;\n        }\n        bool _5794;\n        if (!_5787)\n        {\n            _5794 = _5764 < 0.0;\n        }\n        else\n        {\n            _5794 = _5787;\n        }\n        bool _5801;\n        if (!_5794)\n        {\n            _5801 = _5764 >= 1.0;\n        }\n        else\n        {\n            _5801 = _5794;\n        }\n        if (_5801)\n        {\n            break;\n        }\n        vec4 _5825 = texelFetch(fa_screen_tex_fa_shadow_smp, clamp(ivec2(vec2(_5760, _5764) * fa_mesh_fs_params[24].zw), ivec2(0), ivec2(fa_mesh_fs_params[24].zw) - ivec2(1)), 0);\n        if (_5825.w < 0.5)\n        {\n            continue;\n        }\n        float _5843 = (dot(fa_mesh_fs_params[29].xyz, _5726) + fa_mesh_fs_params[29].w) - _5825.x;\n        if ((_5843 > _5690) && (_5843 < _5695))\n        {\n            occ = max(occ, (1.0 - (_5718 * _5718)) * smoothstep(0.0, 0.0500000007450580596923828125, min(min(_5760, 0.5 - _5759), min(_5764, 1.0 - _5764))));\n        }\n    }\n    return 1.0 - (occ * _5676);\n}\n\nLightSample fa_light_shadowed(int li, vec3 world_pos, vec3 gn)\n{\n    int param = li;\n    float _6505 = fa_baked_keep(param);\n    if (_6505 <= 0.0)\n    {\n        int param_1 = li;\n        return LightSample(vec3(0.0, 1.0, 0.0), vec3(0.0), 0.0, 1.0, 0.0, int(fa_light_type(param_1) + 0.5));\n    }\n    int param_2 = li;\n    vec3 param_3 = world_pos;\n    vec3 param_4 = gn;\n    LightSample _6531 = fa_light_sample_n(param_2, param_3, param_4);\n    vec3 _9794 = _6531.color;\n    float _9795 = _6531.attenuation;\n    float _9796 = _6531.shadow;\n    bool _6534 = _6531.type == 0;\n    if (_6534 && (li == 0))\n    {\n        vec3 param_5 = gn;\n        vec3 param_6 = _6531.direction;\n        float _6545 = fa_shadow_factor(param_5, param_6);\n        _9796 = _6545;\n        _9794 *= _6545;\n    }\n    else\n    {\n        bool _6556 = _6531.type != 0;\n        bool _6562;\n        if (_6556)\n        {\n            _6562 = _9795 > 0.0;\n        }\n        else\n        {\n            _6562 = _6556;\n        }\n        if (_6562)\n        {\n            int param_7 = li;\n            int param_8 = fa_light_base(param_7);\n            int param_9 = li;\n            vec3 param_10 = fa_light_texel(param_8).xyz;\n            vec3 param_11 = world_pos;\n            vec3 param_12 = gn;\n            vec3 param_13 = _6531.direction;\n            float _6581 = fa_shadow_local_rt(param_9, param_10, param_11, param_12, param_13);\n            _9796 = _6581;\n            _9794 *= _6581;\n        }\n    }\n    bool _6591 = fa_mesh_fs_params[24].x > 0.5;\n    bool _6597;\n    if (_6591)\n    {\n        _6597 = _9795 > 0.0;\n    }\n    else\n    {\n        _6597 = _6591;\n    }\n    if (_6597)\n    {\n        float _6604;\n        if (_6534)\n        {\n            _6604 = 1000000000.0;\n        }\n        else\n        {\n            _6604 = _6531._distance;\n        }\n        int param_14 = li;\n        vec3 param_15 = world_pos;\n        vec3 param_16 = gn;\n        vec3 param_17 = _6531.direction;\n        float param_18 = _6604;\n        float _6622 = fa_contact_shadow(param_14, param_15, param_16, param_17, param_18);\n        _9796 *= _6622;\n        _9794 *= _6622;\n    }\n    float _6635 = _9795;\n    float _6636 = _6635 * _6505;\n    _9795 = _6636;\n    vec3 _6640 = _9794;\n    vec3 _6641 = _6640 * _6505;\n    _9794 = _6641;\n    return LightSample(_6531.direction, _6641, _6636, _9796, _6531._distance, _6531.type);\n}\n\nvec3 fa_ltc_tangent(vec3 n, vec3 v)\n{\n    vec3 _6675 = v - (n * dot(v, n));\n    vec3 t = _6675;\n    float _6679 = dot(_6675, _6675);\n    float l2 = _6679;\n    if (_6679 < 1.0000000133514319600180897396058e-10)\n    {\n        vec3 _6689;\n        if (abs(n.z) < 0.999000012874603271484375)\n        {\n            _6689 = cross(n, vec3(0.0, 0.0, 1.0));\n        }\n        else\n        {\n            _6689 = cross(n, vec3(1.0, 0.0, 0.0));\n        }\n        t = _6689;\n        l2 = dot(_6689, _6689);\n    }\n    return t * inversesqrt(l2);\n}\n\nvec3 fa_ltc_local(vec3 t1, vec3 n, vec3 p)\n{\n    return vec3(dot(t1, p), dot(cross(n, t1), p), dot(n, p));\n}\n\nvec2 fa_ltc_uv(float roughness, float ndv)\n{\n    return ((vec2(clamp((roughness - 0.0500000007450580596923828125) * 1.0526316165924072265625, 0.0, 1.0), sqrt(clamp(1.0 - ndv, 0.0, 1.0))) * 63.0) + vec2(0.5)) * vec2(0.015625);\n}\n\nvec3 fa_oct_vertex(int j, vec3 pc, vec3 ex, vec3 ey)\n{\n    float _7076;\n    if ((j == 0) || (j == 7))\n    {\n        _7076 = 0.92387950420379638671875;\n    }\n    else\n    {\n        float _7086;\n        if ((j == 3) || (j == 4))\n        {\n            _7086 = -0.92387950420379638671875;\n        }\n        else\n        {\n            _7086 = ((j == 1) || (j == 6)) ? 0.3826834261417388916015625 : (-0.3826834261417388916015625);\n        }\n        _7076 = _7086;\n    }\n    float _7107;\n    if ((j == 1) || (j == 2))\n    {\n        _7107 = 0.92387950420379638671875;\n    }\n    else\n    {\n        float _7116;\n        if ((j == 5) || (j == 6))\n        {\n            _7116 = -0.92387950420379638671875;\n        }\n        else\n        {\n            _7116 = ((j == 0) || (j == 3)) ? 0.3826834261417388916015625 : (-0.3826834261417388916015625);\n        }\n        _7107 = _7116;\n    }\n    return (pc + (ex * _7076)) + (ey * _7107);\n}\n\nvec3 fa_ltc_edge_vector(vec3 a, vec3 b)\n{\n    float _6724 = dot(a, a);\n    float _6728 = dot(b, b);\n    if ((_6724 < 1.0000000195414813782625560981111e-24) || (_6728 < 1.0000000195414813782625560981111e-24))\n    {\n        return vec3(0.0);\n    }\n    vec3 _6742 = a * inversesqrt(_6724);\n    vec3 _6747 = b * inversesqrt(_6728);\n    float _6751 = dot(_6742, _6747);\n    float _6754 = abs(_6751);\n    float g = (((((((((((0.0416471660137176513671875 * _6754) - 0.1924748718738555908203125) * _6754) + 0.4179156124591827392578125) * _6754) - 0.616057217121124267578125) * _6754) + 0.777722418308258056640625) * _6754) - 0.999542415142059326171875) * _6754) + 1.570791721343994140625;\n    if (_6751 < 0.0)\n    {\n        g = (3.1415927410125732421875 * inversesqrt(max(1.0 - (_6751 * _6751), 1.0000000116860974230803549289703e-07))) - g;\n    }\n    return cross(_6742, _6747) * g;\n}\n\nvoid fa_ltc_clip_edge(vec3 a, vec3 b, inout vec3 sum, inout vec3 leave, inout vec3 enter, inout vec2 seen)\n{\n    bool _6811 = a.z > 0.0;\n    bool _6815 = b.z > 0.0;\n    if (_6811 && _6815)\n    {\n        vec3 param = a;\n        vec3 param_1 = b;\n        sum += fa_ltc_edge_vector(param, param_1);\n    }\n    else\n    {\n        if (_6811 != _6815)\n        {\n            vec3 _6850 = a + ((b - a) * (a.z / (a.z - b.z)));\n            _6850.z = 0.0;\n            if (_6811)\n            {\n                vec3 param_2 = a;\n                vec3 param_3 = _6850;\n                sum += fa_ltc_edge_vector(param_2, param_3);\n                leave = _6850;\n                seen.x = 1.0;\n            }\n            else\n            {\n                vec3 param_4 = _6850;\n                vec3 param_5 = b;\n                sum += fa_ltc_edge_vector(param_4, param_5);\n                enter = _6850;\n                seen.y = 1.0;\n            }\n        }\n    }\n}\n\nfloat fa_ltc_quad(vec4 abcd, vec3 p0, vec3 p1, vec3 p2, vec3 p3)\n{\n    vec3 _6899 = vec3((abcd.x * p0.x) + (abcd.y * p0.z), p0.y, (abcd.z * p0.x) + (abcd.w * p0.z));\n    vec3 _6925 = vec3((abcd.x * p1.x) + (abcd.y * p1.z), p1.y, (abcd.z * p1.x) + (abcd.w * p1.z));\n    vec3 _6951 = vec3((abcd.x * p2.x) + (abcd.y * p2.z), p2.y, (abcd.z * p2.x) + (abcd.w * p2.z));\n    vec3 _6977 = vec3((abcd.x * p3.x) + (abcd.y * p3.z), p3.y, (abcd.z * p3.x) + (abcd.w * p3.z));\n    vec3 sum = vec3(0.0);\n    vec3 leave = vec3(0.0);\n    vec3 enter = vec3(0.0);\n    vec3 param = _6899;\n    vec3 param_1 = _6925;\n    vec3 param_2 = vec3(0.0);\n    vec3 param_3 = vec3(0.0);\n    vec3 param_4 = vec3(0.0);\n    vec2 param_5 = vec2(0.0);\n    fa_ltc_clip_edge(param, param_1, param_2, param_3, param_4, param_5);\n    sum = param_2;\n    leave = param_3;\n    enter = param_4;\n    vec3 param_6 = _6925;\n    vec3 param_7 = _6951;\n    vec3 param_8 = param_2;\n    vec3 param_9 = param_3;\n    vec3 param_10 = param_4;\n    vec2 param_11 = param_5;\n    fa_ltc_clip_edge(param_6, param_7, param_8, param_9, param_10, param_11);\n    sum = param_8;\n    leave = param_9;\n    enter = param_10;\n    vec3 param_12 = _6951;\n    vec3 param_13 = _6977;\n    vec3 param_14 = param_8;\n    vec3 param_15 = param_9;\n    vec3 param_16 = param_10;\n    vec2 param_17 = param_11;\n    fa_ltc_clip_edge(param_12, param_13, param_14, param_15, param_16, param_17);\n    sum = param_14;\n    leave = param_15;\n    enter = param_16;\n    vec3 param_18 = _6977;\n    vec3 param_19 = _6899;\n    vec3 param_20 = param_14;\n    vec3 param_21 = param_15;\n    vec3 param_22 = param_16;\n    vec2 param_23 = param_17;\n    fa_ltc_clip_edge(param_18, param_19, param_20, param_21, param_22, param_23);\n    sum = param_20;\n    leave = param_21;\n    enter = param_22;\n    if ((param_23.x * param_23.y) > 0.5)\n    {\n        vec3 param_24 = leave;\n        vec3 param_25 = enter;\n        sum += fa_ltc_edge_vector(param_24, param_25);\n    }\n    return sum.z * 0.15915493667125701904296875;\n}\n\nvec2 fa_area_forms(vec4 m, float shape, vec3 pc, vec3 ex, vec3 ey)\n{\n    int _7145 = ((shape < 0.5) || (shape > 1.5)) ? 1 : 3;\n    vec2 sum = vec2(0.0);\n    int _7163;\n    for (int k = 0; k < (2 * _7145); k++)\n    {\n        bool _7160 = k >= _7145;\n        if (_7160)\n        {\n            _7163 = k - _7145;\n        }\n        else\n        {\n            _7163 = k;\n        }\n        vec3 p0 = (pc - ex) - ey;\n        vec3 p1 = (pc + ex) - ey;\n        vec3 p2 = (pc + ex) + ey;\n        vec3 p3 = (pc - ex) + ey;\n        if (_7145 == 3)\n        {\n            int param = 0;\n            vec3 param_1 = pc;\n            vec3 param_2 = ex;\n            vec3 param_3 = ey;\n            p0 = fa_oct_vertex(param, param_1, param_2, param_3);\n            int _7209 = 2 * _7163;\n            int param_4 = _7209 + 1;\n            vec3 param_5 = pc;\n            vec3 param_6 = ex;\n            vec3 param_7 = ey;\n            p1 = fa_oct_vertex(param_4, param_5, param_6, param_7);\n            int param_8 = _7209 + 2;\n            vec3 param_9 = pc;\n            vec3 param_10 = ex;\n            vec3 param_11 = ey;\n            p2 = fa_oct_vertex(param_8, param_9, param_10, param_11);\n            int param_12 = _7209 + 3;\n            vec3 param_13 = pc;\n            vec3 param_14 = ex;\n            vec3 param_15 = ey;\n            p3 = fa_oct_vertex(param_12, param_13, param_14, param_15);\n        }\n        bvec4 _7246 = bvec4(_7160);\n        vec4 param_16 = vec4(_7246.x ? m.x : vec4(1.0, 0.0, 0.0, 1.0).x, _7246.y ? m.y : vec4(1.0, 0.0, 0.0, 1.0).y, _7246.z ? m.z : vec4(1.0, 0.0, 0.0, 1.0).z, _7246.w ? m.w : vec4(1.0, 0.0, 0.0, 1.0).w);\n        vec3 param_17 = p0;\n        vec3 param_18 = p1;\n        vec3 param_19 = p2;\n        vec3 param_20 = p3;\n        float _7257 = fa_ltc_quad(param_16, param_17, param_18, param_19, param_20);\n        if (_7160)\n        {\n            vec2 _10047 = sum;\n            _10047.y = _10047.y + _7257;\n            sum = _10047;\n        }\n        else\n        {\n            vec2 _10050 = sum;\n            _10050.x = _10050.x + _7257;\n            sum = _10050;\n        }\n    }\n    return abs(sum);\n}\n\nvec3 fa_area_shade(int li, vec3 world_pos, vec3 n, vec3 v, vec3 diffuse_color, vec3 f0, float f90, float roughness, float ndv, float window)\n{\n    int param = li;\n    int _7281 = fa_light_base(param);\n    int param_1 = _7281;\n    int param_2 = _7281 + 1;\n    int param_3 = _7281 + 2;\n    int param_4 = _7281 + 4;\n    vec4 _7303 = fa_light_texel(param_4);\n    int param_5 = _7281 + 5;\n    vec4 _7308 = fa_light_texel(param_5);\n    int param_6 = _7281 + 6;\n    vec4 _7313 = fa_light_texel(param_6);\n    float _7314 = _7313.w;\n    vec3 _7319 = fa_light_texel(param_1).xyz - world_pos;\n    bool _7321 = _7314 < 1.5;\n    bool _7328;\n    if (_7321)\n    {\n        _7328 = dot(normalize(fa_light_texel(param_3).xyz), _7319) >= 0.0;\n    }\n    else\n    {\n        _7328 = _7321;\n    }\n    if (_7328)\n    {\n        return vec3(0.0);\n    }\n    bool _7337 = (_7314 > 0.5) && _7321;\n    float _7341 = _7337 ? 1.0539000034332275390625 : 1.0;\n    vec3 _7344 = _7303.xyz;\n    float _7346 = _7303.w;\n    vec3 _7352 = _7308.xyz;\n    float _7354 = _7308.w;\n    vec3 up = _7352 * (_7354 * _7341);\n    float _7360;\n    if (_7337)\n    {\n        _7360 = (3.1415927410125732421875 * _7346) * _7346;\n    }\n    else\n    {\n        _7360 = (4.0 * _7346) * _7354;\n    }\n    if (_7314 > 1.5)\n    {\n        vec3 _7386 = cross(_7344, -_7319);\n        vec3 perp = _7386;\n        float _7390 = dot(_7386, _7386);\n        vec3 _7393;\n        if (_7390 > 1.0000000133514319600180897396058e-10)\n        {\n            _7393 = perp * inversesqrt(_7390);\n        }\n        else\n        {\n            _7393 = _7352;\n        }\n        perp = _7393;\n        up = _7393 * _7354;\n    }\n    float _7414 = max(_7360, 9.9999999747524270787835121154785e-07);\n    vec3 param_7 = n;\n    vec3 param_8 = v;\n    vec3 _7424 = fa_ltc_tangent(param_7, param_8);\n    vec3 param_9 = _7424;\n    vec3 param_10 = n;\n    vec3 param_11 = _7319;\n    vec3 param_12 = _7424;\n    vec3 param_13 = n;\n    vec3 param_14 = _7344 * (_7346 * _7341);\n    vec3 param_15 = _7424;\n    vec3 param_16 = n;\n    vec3 param_17 = up;\n    float param_18 = roughness;\n    float param_19 = ndv;\n    vec2 _7455 = fa_ltc_uv(param_18, param_19) * 64.0;\n    vec2 param_20 = _7455;\n    vec2 param_21 = _7455 + vec2(64.0, 0.0);\n    vec4 _7465 = fa_atlas_fetch(param_21);\n    vec4 param_22 = fa_atlas_fetch(param_20);\n    float param_23 = _7314;\n    vec3 param_24 = fa_ltc_local(param_9, param_10, param_11);\n    vec3 param_25 = fa_ltc_local(param_12, param_13, param_14);\n    vec3 param_26 = fa_ltc_local(param_15, param_16, param_17);\n    vec2 _7477 = fa_area_forms(param_22, param_23, param_24, param_25, param_26);\n    return (((diffuse_color * _7477.x) + (((f0 * _7465.x) + ((vec3(f90) - f0) * _7465.y)) * _7477.y)) * fa_light_texel(param_2).xyz) * ((((3.1415927410125732421875 * dot(_7319, _7319)) + _7414) / _7414) * window);\n}\n\nvec3 fa_light_rgb(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 1;\n    return fa_light_texel(param_1).xyz;\n}\n\nfloat fa_d_charlie(float alpha, float ndh)\n{\n    float _5371 = 1.0 / alpha;\n    return ((2.0 + _5371) * pow(sqrt(max(1.0 - (ndh * ndh), 9.9999997473787516355514526367188e-05)), _5371)) * 0.15915493667125701904296875;\n}\n\nfloat fa_v_ashikhmin(float ndl, float ndv)\n{\n    return clamp(0.25 / max((ndl + ndv) - (ndl * ndv), 9.9999997473787516355514526367188e-05), 0.0, 1.0);\n}\n\nfloat fa_layers_coat(FaLayers L, vec3 l, vec3 h, float vdh)\n{\n    float _5406 = max(dot(L.nc, l), 0.0);\n    float _5412 = max(dot(L.nc, h), 0.0);\n    float _5421 = ((_5412 * _5412) * (L.coat_a2 - 1.0)) + 1.0;\n    return (((L.coat * (0.039999999105930328369140625 + (0.959999978542327880859375 * pow(clamp(1.0 - vdh, 0.0, 1.0), 5.0)))) * (((L.coat_a2 / ((3.1415927410125732421875 * _5421) * _5421)) * (0.5 / max(mix((2.0 * _5406) * L.coat_ndv, _5406 + L.coat_ndv, L.coat_alpha), 9.9999997473787516355514526367188e-05))) * 3.1415927410125732421875)) * step(9.9999997473787516355514526367188e-05, _5406)) * _5406;\n}\n\nvec3 fa_area_layers(FaLayers L, vec3 base, int li, vec3 n, vec3 v, vec3 l, float ndv, float window)\n{\n    float _7514;\n    if (L.sheen_on)\n    {\n        _7514 = L.sheen_scale;\n    }\n    else\n    {\n        _7514 = 1.0;\n    }\n    vec3 result = base * (L.keep * _7514);\n    vec3 _7527 = normalize(l + v);\n    int param = li;\n    vec3 _7538 = fa_light_rgb(param) * window;\n    if (L.sheen_on)\n    {\n        float _7547 = max(dot(n, l), 0.0);\n        float param_1 = L.sheen_alpha;\n        float param_2 = max(dot(n, _7527), 0.0);\n        float param_3 = _7547;\n        float param_4 = ndv;\n        result += ((L.sheen * _7538) * (((((fa_d_charlie(param_1, param_2) * fa_v_ashikhmin(param_3, param_4)) * 3.1415927410125732421875) * step(9.9999997473787516355514526367188e-05, _7547)) * _7547) * L.keep));\n    }\n    if (L.coat > 0.0)\n    {\n        FaLayers param_5 = L;\n        vec3 param_6 = l;\n        vec3 param_7 = _7527;\n        float param_8 = max(dot(v, _7527), 0.0);\n        result += (_7538 * fa_layers_coat(param_5, param_6, param_7, param_8));\n    }\n    return result;\n}\n\nfloat fa_d_ggx_aniso(float ndh, float tdh, float bdh, float at, float ab)\n{\n    float _5274 = tdh / at;\n    float _5278 = bdh / ab;\n    float _5290 = ((_5274 * _5274) + (_5278 * _5278)) + (ndh * ndh);\n    return 1.0 / ((((3.1415927410125732421875 * at) * ab) * _5290) * _5290);\n}\n\nfloat fa_lambda_ggx_aniso(float n, float t, float b, float at, float ab)\n{\n    return 0.5 * (sqrt(1.0 + (((((at * at) * t) * t) + (((ab * ab) * b) * b)) / max(n * n, 9.9999999392252902907785028219223e-09))) - 1.0);\n}\n\nfloat fa_v_ggx_aniso(float ndl, float ndv, float tdv, float bdv, float tdl, float bdl, float at, float ab)\n{\n    float param = ndv;\n    float param_1 = tdv;\n    float param_2 = bdv;\n    float param_3 = at;\n    float param_4 = ab;\n    float param_5 = ndl;\n    float param_6 = tdl;\n    float param_7 = bdl;\n    float param_8 = at;\n    float param_9 = ab;\n    return clamp(1.0 / ((4.0 * max(ndl * ndv, 9.9999997473787516355514526367188e-05)) * ((1.0 + fa_lambda_ggx_aniso(param, param_1, param_2, param_3, param_4)) + fa_lambda_ggx_aniso(param_5, param_6, param_7, param_8, param_9))), 0.0, 1.0);\n}\n\nvec3 fa_layers_light(FaLayers L, vec3 diffuse_color, vec3 f0, vec3 n, vec3 v, vec3 l, vec3 h, float ndl, float ndv, float ndh, float vdh, float alpha, float a2)\n{\n    float _5470 = step(9.9999997473787516355514526367188e-05, ndl);\n    float d_ggx;\n    float vis;\n    if (L.aniso != 0.0)\n    {\n        float param = ndh;\n        float param_1 = dot(L.t, h);\n        float param_2 = dot(L.b, h);\n        float param_3 = L.at;\n        float param_4 = L.ab;\n        d_ggx = fa_d_ggx_aniso(param, param_1, param_2, param_3, param_4);\n        float param_5 = ndl;\n        float param_6 = ndv;\n        float param_7 = dot(L.t, v);\n        float param_8 = dot(L.b, v);\n        float param_9 = dot(L.t, l);\n        float param_10 = dot(L.b, l);\n        float param_11 = L.at;\n        float param_12 = L.ab;\n        vis = fa_v_ggx_aniso(param_5, param_6, param_7, param_8, param_9, param_10, param_11, param_12);\n    }\n    else\n    {\n        float _5549 = ((ndh * ndh) * (a2 - 1.0)) + 1.0;\n        d_ggx = a2 / ((3.1415927410125732421875 * _5549) * _5549);\n        vis = 0.5 / max(mix((2.0 * ndl) * ndv, ndl + ndv, alpha), 9.9999997473787516355514526367188e-05);\n    }\n    vec3 base = diffuse_color + (((f0 + ((vec3(L.f90) - f0) * pow(clamp(1.0 - vdh, 0.0, 1.0), 5.0))) * ((d_ggx * vis) * 3.1415927410125732421875)) * _5470);\n    if (L.sheen_on)\n    {\n        float param_13 = L.sheen_alpha;\n        float param_14 = ndh;\n        float param_15 = ndl;\n        float param_16 = ndv;\n        base = (base * L.sheen_scale) + (L.sheen * (((fa_d_charlie(param_13, param_14) * fa_v_ashikhmin(param_15, param_16)) * 3.1415927410125732421875) * _5470));\n    }\n    vec3 result = base * (L.keep * ndl);\n    if (L.coat > 0.0)\n    {\n        FaLayers param_17 = L;\n        vec3 param_18 = l;\n        vec3 param_19 = h;\n        float param_20 = vdh;\n        result += vec3(fa_layers_coat(param_17, param_18, param_19, param_20));\n    }\n    return result;\n}\n\nvec2 fa_env_brdf(float rough, float ndv)\n{\n    vec4 _4673 = (vec4(-1.0, -0.0274999998509883880615234375, -0.572000026702880859375, 0.02199999988079071044921875) * rough) + vec4(1.0, 0.0425000004470348358154296875, 1.03999996185302734375, -0.039999999105930328369140625);\n    float _4676 = _4673.x;\n    return (vec2(-1.03999996185302734375, 1.03999996185302734375) * ((min(_4676 * _4676, exp2((-9.27999973297119140625) * ndv)) * _4676) + _4673.y)) + _4673.zw;\n}\n\nvec3 fa_probe_level(vec2 origin, float res, int lv, vec2 e)\n{\n    float _3984;\n    if (lv == 0)\n    {\n        _3984 = 0.0;\n    }\n    else\n    {\n        _3984 = res + 2.0;\n    }\n    float _3994;\n    if (lv == 0)\n    {\n        _3994 = 0.0;\n    }\n    else\n    {\n        _3994 = (res - (res / float(1 << max((lv - 1), 0)))) + (2.0 * float(lv - 1));\n    }\n    return textureLod(fa_probe_atlas_fa_env_smp, (((origin + vec2(_3984, _3994)) + vec2(1.0)) + (((e * 0.5) + vec2(0.5)) * (res / float(1 << lv)))) / fa_atlas_size(), 0.0).xyz;\n}\n\nvec3 fa_probe_radiance(vec2 origin, float res, vec3 d, float rough)\n{\n    float _4040;\n    if (res > 64.5)\n    {\n        _4040 = 5.0;\n    }\n    else\n    {\n        _4040 = (res > 32.5) ? 4.0 : 3.0;\n    }\n    float _4055 = clamp(rough, 0.0, 1.0) * (_4040 - 1.0);\n    int _4062 = int(min(floor(_4055), _4040 - 2.0));\n    float _4067 = _4055 - float(_4062);\n    vec3 param = d;\n    vec2 _4071 = fa_oct_encode(param);\n    vec2 param_1 = origin;\n    float param_2 = res;\n    int param_3 = _4062;\n    vec2 param_4 = _4071;\n    vec3 _4081 = fa_probe_level(param_1, param_2, param_3, param_4);\n    if (_4067 < 0.00200000009499490261077880859375)\n    {\n        return _4081;\n    }\n    vec2 param_5 = origin;\n    float param_6 = res;\n    int param_7 = _4062 + 1;\n    vec2 param_8 = _4071;\n    return mix(_4081, fa_probe_level(param_5, param_6, param_7, param_8), vec3(_4067));\n}\n\nvec3 fa_probe_box_dir(vec3 d, vec4 posw, vec4 bx, vec4 by, vec4 bz)\n{\n    if (posw.w < 0.5)\n    {\n        return d;\n    }\n    float _4152 = dot(bx.xyz, fa_world_pos) + bx.w;\n    float _4159 = dot(by.xyz, fa_world_pos) + by.w;\n    float _4166 = dot(bz.xyz, fa_world_pos) + bz.w;\n    float _4172 = dot(bx.xyz, d);\n    float _4176 = dot(by.xyz, d);\n    float _4180 = dot(bz.xyz, d);\n    float _4186;\n    if (_4172 > 9.9999999747524270787835121154785e-07)\n    {\n        _4186 = (1.0 - _4152) / _4172;\n    }\n    else\n    {\n        float _4200;\n        if (_4172 < (-9.9999999747524270787835121154785e-07))\n        {\n            _4200 = ((-1.0) - _4152) / _4172;\n        }\n        else\n        {\n            _4200 = 1000000015047466219876688855040.0;\n        }\n        _4186 = _4200;\n    }\n    float tx = _4186;\n    float _4217;\n    if (_4176 > 9.9999999747524270787835121154785e-07)\n    {\n        _4217 = (1.0 - _4159) / _4176;\n    }\n    else\n    {\n        float _4230;\n        if (_4176 < (-9.9999999747524270787835121154785e-07))\n        {\n            _4230 = ((-1.0) - _4159) / _4176;\n        }\n        else\n        {\n            _4230 = 1000000015047466219876688855040.0;\n        }\n        _4217 = _4230;\n    }\n    float ty = _4217;\n    float _4246;\n    if (_4180 > 9.9999999747524270787835121154785e-07)\n    {\n        _4246 = (1.0 - _4166) / _4180;\n    }\n    else\n    {\n        float _4259;\n        if (_4180 < (-9.9999999747524270787835121154785e-07))\n        {\n            _4259 = ((-1.0) - _4166) / _4180;\n        }\n        else\n        {\n            _4259 = 1000000015047466219876688855040.0;\n        }\n        _4246 = _4259;\n    }\n    float _4271 = tx;\n    float _4274 = (_4271 > 0.0) ? _4271 : 1000000015047466219876688855040.0;\n    tx = _4274;\n    float _4275 = ty;\n    float _4278 = (_4275 > 0.0) ? _4275 : 1000000015047466219876688855040.0;\n    ty = _4278;\n    float _4288 = min(_4274, min(_4278, (_4246 > 0.0) ? _4246 : 1000000015047466219876688855040.0));\n    if (_4288 > 100000001504746621987668885504.0)\n    {\n        return d;\n    }\n    vec3 _4304 = (fa_world_pos + (d * _4288)) - posw.xyz;\n    vec3 _4309;\n    if (dot(_4304, _4304) > 1.0000000133514319600180897396058e-10)\n    {\n        _4309 = normalize(_4304);\n    }\n    else\n    {\n        _4309 = d;\n    }\n    return _4309;\n}\n\nvec3 fa_probe_environment(vec4 tile, vec4 posw, vec4 bx, vec4 by, vec4 bz, inout vec3 d, float rough)\n{\n    vec3 param = d;\n    vec4 param_1 = posw;\n    vec4 param_2 = bx;\n    vec4 param_3 = by;\n    vec4 param_4 = bz;\n    d = fa_probe_box_dir(param, param_1, param_2, param_3, param_4);\n    vec2 param_5 = tile.xy;\n    float param_6 = tile.z;\n    vec3 param_7 = d;\n    float param_8 = rough;\n    return fa_probe_radiance(param_5, param_6, param_7, param_8);\n}\n\nvec3 fa_environment(vec3 d, float rough)\n{\n    float _4355 = (1.0 - fa_mesh_fs_params[42].w) - fa_mesh_fs_params[47].w;\n    vec3 outc = vec3(0.0);\n    if (_4355 > 0.0005000000237487256526947021484375)\n    {\n        vec3 base;\n        if (fa_mesh_fs_params[11].w > 0.5)\n        {\n            vec2 param = fa_mesh_fs_params[41].zw;\n            float param_1 = 128.0;\n            vec3 param_2 = d;\n            float param_3 = rough;\n            base = fa_probe_radiance(param, param_1, param_2, param_3);\n        }\n        else\n        {\n            float _4383 = rough * rough;\n            float _4414 = 0.60000002384185791015625 * _4383;\n            base = mix(mix(fa_mesh_fs_params[12].xyz * 0.550000011920928955078125, mix(fa_mesh_fs_params[12].xyz, fa_mesh_fs_params[11].xyz, vec3(pow(clamp(d.y * (1.0 - (0.699999988079071044921875 * _4383)), 0.0, 1.0), 0.550000011920928955078125))), vec3(smoothstep((-0.0500000007450580596923828125) - _4414, 0.0500000007450580596923828125 + _4414, d.y))), ((fa_mesh_fs_params[11].xyz + fa_mesh_fs_params[12].xyz) * 0.5) * 0.800000011920928955078125, vec3(_4383 * 0.60000002384185791015625));\n        }\n        outc = base * _4355;\n    }\n    if (fa_mesh_fs_params[42].w > 0.0)\n    {\n        vec4 param_4 = fa_mesh_fs_params[42];\n        vec4 param_5 = fa_mesh_fs_params[43];\n        vec4 param_6 = fa_mesh_fs_params[44];\n        vec4 param_7 = fa_mesh_fs_params[45];\n        vec4 param_8 = fa_mesh_fs_params[46];\n        vec3 param_9 = d;\n        float param_10 = rough;\n        vec3 _4473 = fa_probe_environment(param_4, param_5, param_6, param_7, param_8, param_9, param_10);\n        outc += (_4473 * fa_mesh_fs_params[42].w);\n    }\n    if (fa_mesh_fs_params[47].w > 0.0)\n    {\n        vec4 param_11 = fa_mesh_fs_params[47];\n        vec4 param_12 = fa_mesh_fs_params[48];\n        vec4 param_13 = fa_mesh_fs_params[49];\n        vec4 param_14 = fa_mesh_fs_params[50];\n        vec4 param_15 = fa_mesh_fs_params[51];\n        vec3 param_16 = d;\n        float param_17 = rough;\n        vec3 _4505 = fa_probe_environment(param_11, param_12, param_13, param_14, param_15, param_16, param_17);\n        outc += (_4505 * fa_mesh_fs_params[47].w);\n    }\n    return outc;\n}\n\nvec3 fa_layers_ibl(FaLayers L, vec3 n, vec3 v, vec3 f0, float roughness, float occlusion)\n{\n    vec3 rn = n;\n    if (L.aniso != 0.0)\n    {\n        vec3 _5151;\n        if (L.aniso >= 0.0)\n        {\n            _5151 = L.b;\n        }\n        else\n        {\n            _5151 = L.t;\n        }\n        rn = normalize(mix(n, cross(cross(_5151, v), _5151), vec3(abs(L.aniso) * smoothstep(0.0, 0.25, roughness))));\n    }\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05);\n    vec2 _5187 = fa_env_brdf(param, param_1);\n    vec3 param_2 = reflect(-v, rn);\n    float param_3 = roughness;\n    vec3 result = (fa_environment(param_2, param_3) * ((f0 * _5187.x) + (vec3(L.f90) * _5187.y))) * L.base_scale;\n    if (L.sheen_on)\n    {\n        vec3 param_4 = n;\n        float param_5 = L.sheen_rough;\n        result += ((L.sheen * (L.sheen_e * L.keep)) * fa_environment(param_4, param_5));\n    }\n    result *= occlusion;\n    if (L.coat > 0.0)\n    {\n        float param_6 = L.coat_rough;\n        float param_7 = L.coat_ndv;\n        vec2 _5245 = fa_env_brdf(param_6, param_7);\n        vec3 param_8 = reflect(-v, L.nc);\n        float param_9 = L.coat_rough;\n        result += (fa_environment(param_8, param_9) * (L.coat * ((0.039999999105930328369140625 * _5245.x) + _5245.y)));\n    }\n    return result;\n}\n\nvec3 fa_sky_reflection(vec3 n, vec3 v, vec3 f0, float roughness)\n{\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05);\n    vec2 _4715 = fa_env_brdf(param, param_1);\n    vec3 param_2 = reflect(-v, n);\n    float param_3 = roughness;\n    return fa_environment(param_2, param_3) * ((f0 * _4715.x) + vec3(_4715.y));\n}\n\nvec2 fa_xm_size(int k)\n{\n    return max(floor(fa_mesh_fs_params[24].zw / vec2(float(1 << k))), vec2(1.0));\n}\n\nvec2 fa_xm_origin(int k)\n{\n    if (k == 0)\n    {\n        return vec2(0.0);\n    }\n    float y = 0.0;\n    for (int j = 1; j < k; j++)\n    {\n        int param = j;\n        y += fa_xm_size(param).y;\n    }\n    return vec2(fa_mesh_fs_params[24].z, y);\n}\n\nvec3 fa_xm_texel(vec2 size, vec2 origin, vec2 p)\n{\n    return texelFetch(fa_screen_tex_fa_shadow_smp, ivec2(origin + clamp(p, vec2(0.0), size - vec2(1.0))), 0).xyz;\n}\n\nvec3 fa_xm_level(int k, vec2 uv)\n{\n    int param = k;\n    vec2 _5947 = fa_xm_size(param);\n    int param_1 = k;\n    vec2 _5951 = fa_xm_origin(param_1);\n    vec2 _5957 = (uv * _5947) - vec2(0.5);\n    vec2 _5960 = fract(_5957);\n    vec2 _5963 = floor(_5957);\n    vec2 param_2 = _5947;\n    vec2 param_3 = _5951;\n    vec2 param_4 = _5963;\n    vec2 param_5 = _5947;\n    vec2 param_6 = _5951;\n    vec2 param_7 = _5963 + vec2(1.0, 0.0);\n    vec2 param_8 = _5947;\n    vec2 param_9 = _5951;\n    vec2 param_10 = _5963 + vec2(0.0, 1.0);\n    vec2 param_11 = _5947;\n    vec2 param_12 = _5951;\n    vec2 param_13 = _5963 + vec2(1.0);\n    vec3 _6005 = vec3(_5960.x);\n    return mix(mix(fa_xm_texel(param_2, param_3, param_4), fa_xm_texel(param_5, param_6, param_7), _6005), mix(fa_xm_texel(param_8, param_9, param_10), fa_xm_texel(param_11, param_12, param_13), _6005), vec3(_5960.y));\n}\n\nvec3 fa_xm_sample(vec2 uv, float lod)\n{\n    float _6024 = max(fa_mesh_fs_params[31].w - 1.0, 0.0);\n    float _6028 = clamp(lod, 0.0, _6024);\n    int _6032 = int(floor(_6028));\n    int param = _6032;\n    vec2 param_1 = uv;\n    vec3 c = fa_xm_level(param, param_1);\n    float _6042 = float(_6032);\n    float _6043 = _6028 - _6042;\n    bool _6045 = _6043 > 0.001000000047497451305389404296875;\n    bool _6052;\n    if (_6045)\n    {\n        _6052 = _6042 < _6024;\n    }\n    else\n    {\n        _6052 = _6045;\n    }\n    if (_6052)\n    {\n        int param_2 = _6032 + 1;\n        vec2 param_3 = uv;\n        c = mix(c, fa_xm_level(param_2, param_3), vec3(_6043));\n    }\n    return c;\n}\n\nvec3 fa_transmitted(Surface s, vec3 n, vec3 v, float roughness, vec3 f0, float f90, float keep, float tr, inout float blend)\n{\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05);\n    vec2 _6078 = fa_env_brdf(param, param_1);\n    vec3 _6102 = ((vec3(1.0) - clamp((f0 * _6078.x) + (vec3(f90) * _6078.y), vec3(0.0), vec3(1.0))) * s.albedo) * (tr * keep);\n    vec3 through = _6102;\n    float _6108 = max(s.thickness, 0.0);\n    bool _6113 = _6108 > 0.0;\n    if ((s.attenuation_distance > 0.0) && _6113)\n    {\n        through *= exp((-((-log(clamp(s.attenuation_color, vec3(9.9999997473787516355514526367188e-05), vec3(1.0)))) / vec3(s.attenuation_distance))) * _6108);\n    }\n    bool _6138 = fa_mesh_fs_params[30].w > 1.5;\n    bool _6144;\n    if (_6138)\n    {\n        _6144 = fa_mesh_fs_params[30].w < 2.5;\n    }\n    else\n    {\n        _6144 = _6138;\n    }\n    bool _6151;\n    if (!_6144)\n    {\n        _6151 = fa_mesh_fs_params[30].w < 0.5;\n    }\n    else\n    {\n        _6151 = _6144;\n    }\n    if (_6151)\n    {\n        blend = clamp(dot(through, vec3(0.3333333432674407958984375)), 0.0, 0.980000019073486328125);\n        return vec3(0.0);\n    }\n    vec4 _6166 = vec4(fa_world_pos, 1.0);\n    float _6171 = dot(fa_mesh_fs_params[28], _6166);\n    vec2 uv0 = vec2(0.5);\n    if (_6171 > 9.9999997473787516355514526367188e-05)\n    {\n        vec2 _6189 = vec2(dot(fa_mesh_fs_params[26], _6166), dot(fa_mesh_fs_params[27], _6166)) / vec2(_6171);\n        float _6197;\n        if (fa_mesh_fs_params[24].y > 0.5)\n        {\n            _6197 = (_6189.y * 0.5) + 0.5;\n        }\n        else\n        {\n            _6197 = 0.5 - (_6189.y * 0.5);\n        }\n        uv0 = vec2((_6189.x * 0.5) + 0.5, _6197);\n    }\n    if (fa_mesh_fs_params[30].w > 2.5)\n    {\n        int param_2 = 0;\n        vec2 _6218 = fa_xm_size(param_2);\n        vec2 _6226 = floor(clamp(uv0, vec2(0.0), vec2(0.99989998340606689453125)) * _6218);\n        if (texelFetch(fa_screen_tex_fa_shadow_smp, ivec2(_6226), 0).w > 0.5)\n        {\n            int _6246 = int(floor((clamp(roughness, 0.0, 1.0) * 2.0) + 0.5));\n            vec3 acc = vec3(0.0);\n            float cnt = 0.0;\n            for (int dy = -2; dy <= 2; dy++)\n            {\n                for (int dx = -2; dx <= 2; dx++)\n                {\n                    bool _6269 = abs(dx) > _6246;\n                    bool _6277;\n                    if (!_6269)\n                    {\n                        _6277 = abs(dy) > _6246;\n                    }\n                    else\n                    {\n                        _6277 = _6269;\n                    }\n                    if (_6277)\n                    {\n                        continue;\n                    }\n                    vec4 _6298 = texelFetch(fa_screen_tex_fa_shadow_smp, ivec2(clamp(_6226 + vec2(float(dx), float(dy)), vec2(0.0), _6218 - vec2(1.0))), 0);\n                    if (_6298.w > 0.5)\n                    {\n                        acc += _6298.xyz;\n                        cnt += 1.0;\n                    }\n                }\n            }\n            return _6102 * (acc / vec3(max(cnt, 1.0)));\n        }\n    }\n    vec2 uv = uv0;\n    if (_6113)\n    {\n        vec4 _6346 = vec4(fa_world_pos + (refract(-v, n, 1.0 / max(s.ior, 1.0)) * _6108), 1.0);\n        float _6351 = dot(fa_mesh_fs_params[28], _6346);\n        uv = vec2(0.5);\n        if (_6351 > 9.9999997473787516355514526367188e-05)\n        {\n            vec2 _6368 = vec2(dot(fa_mesh_fs_params[26], _6346), dot(fa_mesh_fs_params[27], _6346)) / vec2(_6351);\n            float _6376;\n            if (fa_mesh_fs_params[24].y > 0.5)\n            {\n                _6376 = (_6368.y * 0.5) + 0.5;\n            }\n            else\n            {\n                _6376 = 0.5 - (_6368.y * 0.5);\n            }\n            uv = vec2((_6368.x * 0.5) + 0.5, _6376);\n        }\n    }\n    vec2 param_3 = clamp(uv, vec2(0.0), vec2(1.0));\n    float param_4 = (clamp(roughness, 0.0, 1.0) * clamp((2.0 * s.ior) - 2.0, 0.0, 1.0)) * max(fa_mesh_fs_params[31].w - 1.0, 0.0);\n    return through * fa_xm_sample(param_3, param_4);\n}\n\nvec3 fa_shadow_debug(vec3 color, vec3 world)\n{\n    if (fa_shadows[27].w < 0.5)\n    {\n        return color;\n    }\n    int _3280 = int(fa_shadows[25].x + 0.5);\n    float _3290 = dot(world - fa_shadows[27].xyz, fa_shadows[28].xyz);\n    vec3 tint = vec3(0.3499999940395355224609375);\n    bool _3295 = _3280 > 0;\n    bool _3304;\n    if (_3295)\n    {\n        int param = _3280 - 1;\n        _3304 = _3290 <= fa_shadow_split_at(param);\n    }\n    else\n    {\n        _3304 = _3295;\n    }\n    if (_3304)\n    {\n        tint = vec3(1.0, 0.1500000059604644775390625, 0.100000001490116119384765625);\n        bool _3310 = _3280 > 1;\n        bool _3317;\n        if (_3310)\n        {\n            _3317 = _3290 > fa_shadows[24].x;\n        }\n        else\n        {\n            _3317 = _3310;\n        }\n        if (_3317)\n        {\n            tint = vec3(0.100000001490116119384765625, 0.89999997615814208984375, 0.20000000298023223876953125);\n        }\n        bool _3323 = _3280 > 2;\n        bool _3330;\n        if (_3323)\n        {\n            _3330 = _3290 > fa_shadows[24].y;\n        }\n        else\n        {\n            _3330 = _3323;\n        }\n        if (_3330)\n        {\n            tint = vec3(0.1500000059604644775390625, 0.300000011920928955078125, 1.0);\n        }\n        bool _3336 = _3280 > 3;\n        bool _3343;\n        if (_3336)\n        {\n            _3343 = _3290 > fa_shadows[24].z;\n        }\n        else\n        {\n            _3343 = _3336;\n        }\n        if (_3343)\n        {\n            tint = vec3(1.0, 0.89999997615814208984375, 0.100000001490116119384765625);\n        }\n    }\n    return mix(color, tint, vec3(0.550000011920928955078125));\n}\n\nvoid main()\n{\n    fa_rt_slope = 0.0;\n    fa_inst_load();\n    vec3 _9453 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _9453 = -_9453;\n    }\n    vec3 _8751 = normalize(fa_mesh_fs_params[0].xyz - fa_world_pos);\n    vec3 param = fa_world_pos;\n    fa_cluster_begin(param);\n    SurfaceInput param_1 = SurfaceInput(fa_world_pos, _9453, fa_world_tangent, fa_uv, fa_vertex_color, _8751, gl_FrontFacing);\n    Surface _8759 = fa_standard_surface(param_1);\n    vec3 _9484 = _8759.albedo;\n    float _9485 = _8759.alpha;\n    vec3 _9486 = _8759.normal;\n    float _9487 = _8759.metallic;\n    float _9488 = _8759.roughness;\n    float _9489 = _8759.occlusion;\n    vec3 _9490 = _8759.emission;\n    float _9491 = _8759.clearcoat;\n    float _9492 = _8759.clearcoat_roughness;\n    vec3 _9493 = _8759.sheen_color;\n    float _9494 = _8759.sheen_roughness;\n    float _9495 = _8759.anisotropy;\n    float _9496 = _8759.anisotropy_rotation;\n    float _9497 = _8759.specular;\n    float _9498 = _8759.ior;\n    vec3 _9499 = _8759.specular_color;\n    float _9500 = _8759.transmission;\n    float _9501 = _8759.thickness;\n    vec3 _9502 = _8759.attenuation_color;\n    float _9503 = _8759.attenuation_distance;\n    SurfaceInput param_2 = SurfaceInput(fa_world_pos, _9453, fa_world_tangent, fa_uv, fa_vertex_color, _8751, gl_FrontFacing);\n    Surface param_3 = _8759;\n    surface(param_2, param_3);\n    _9484 = param_3.albedo;\n    _9485 = param_3.alpha;\n    _9486 = param_3.normal;\n    _9487 = param_3.metallic;\n    _9488 = param_3.roughness;\n    _9489 = param_3.occlusion;\n    _9490 = param_3.emission;\n    _9491 = param_3.clearcoat;\n    _9492 = param_3.clearcoat_roughness;\n    _9493 = param_3.sheen_color;\n    _9494 = param_3.sheen_roughness;\n    _9495 = param_3.anisotropy;\n    _9496 = param_3.anisotropy_rotation;\n    _9497 = param_3.specular;\n    _9498 = param_3.ior;\n    _9499 = param_3.specular_color;\n    _9500 = param_3.transmission;\n    _9501 = param_3.thickness;\n    _9502 = param_3.attenuation_color;\n    _9503 = param_3.attenuation_distance;\n    vec3 param_4 = fa_world_pos;\n    vec3 param_5 = _9453;\n    vec3 param_6 = param_3.albedo;\n    vec3 param_7 = param_3.normal;\n    fa_apply_decals(param_4, param_5, param_6, param_7);\n    _9484 = param_6;\n    _9486 = param_7;\n    float fa_tr_blend = 0.0;\n    vec3 result;\n    if (fa_mesh_fs_params[3].w > 0.5)\n    {\n        result = _9484;\n    }\n    else\n    {\n        vec3 _8799 = normalize(_9486);\n        float _8806 = clamp(_9487, 0.0, 1.0);\n        float _8810 = clamp(_9488, 0.0500000007450580596923828125, 1.0);\n        float _8814 = _8810 * _8810;\n        float _8818 = _8814 * _8814;\n        float _8823 = max(dot(_8799, _8751), 9.9999997473787516355514526367188e-05);\n        float _8829 = 1.0 - _8806;\n        float _8830 = clamp(_9500, 0.0, 1.0) * _8829;\n        vec3 _8839 = (_9484 * _8829) * (1.0 - _8830);\n        vec3 _8846 = mix(vec3(0.039999999105930328369140625), _9484, vec3(_8806));\n        vec3 f0 = _8846;\n        SurfaceInput param_8 = SurfaceInput(fa_world_pos, _9453, fa_world_tangent, fa_uv, fa_vertex_color, _8751, gl_FrontFacing);\n        Surface param_9 = Surface(_9484, _9485, _9486, _9487, _9488, _9489, _9490, _9491, _9492, _9493, _9494, _9495, _9496, _9497, _9498, _9499, _9500, _9501, _9502, _9503);\n        vec3 param_10 = _8799;\n        vec3 param_11 = _8751;\n        float param_12 = _8806;\n        float param_13 = _8810;\n        vec3 param_14 = _8846;\n        FaLayers _8862 = fa_layers_setup(param_8, param_9, param_10, param_11, param_12, param_13, param_14);\n        f0 = param_14;\n        vec3 param_15 = _8799;\n        vec3 lit = (fa_indirect_diffuse(param_15) * _8839) * _9489;\n        if (_8862.on)\n        {\n            lit *= _8862.base_scale;\n        }\n        int _8884 = fa_cl_ndir + fa_cl_local;\n        float _8949;\n        for (int ln = 0; ln < _8884; ln++)\n        {\n            int param_16 = ln;\n            int _8897 = fa_cl_light(param_16);\n            int param_17 = _8897;\n            if (fa_baked_keep(param_17) <= 0.0)\n            {\n                continue;\n            }\n            int param_18 = _8897;\n            vec3 param_19 = fa_world_pos;\n            vec3 param_20 = _9453;\n            LightSample _8913 = fa_light_shadowed(param_18, param_19, param_20);\n            float _8921 = max(dot(_8799, _8913.direction), 0.0);\n            float _8927 = _8913.attenuation * _8913.shadow;\n            vec3 _8932 = normalize(_8913.direction + _8751);\n            float _8937 = max(dot(_8799, _8932), 0.0);\n            float _8942 = max(dot(_8751, _8932), 0.0);\n            if (fa_light_is_area)\n            {\n                if (_8862.on)\n                {\n                    _8949 = _8862.f90;\n                }\n                else\n                {\n                    _8949 = 1.0;\n                }\n                int param_21 = _8897;\n                vec3 param_22 = fa_world_pos;\n                vec3 param_23 = _8799;\n                vec3 param_24 = _8751;\n                vec3 param_25 = _8839;\n                vec3 param_26 = f0;\n                float param_27 = _8949;\n                float param_28 = _8810;\n                float param_29 = _8823;\n                float param_30 = _8927;\n                vec3 area = fa_area_shade(param_21, param_22, param_23, param_24, param_25, param_26, param_27, param_28, param_29, param_30);\n                if (_8862.on)\n                {\n                    FaLayers param_31 = _8862;\n                    vec3 param_32 = area;\n                    int param_33 = _8897;\n                    vec3 param_34 = _8799;\n                    vec3 param_35 = _8751;\n                    vec3 param_36 = _8913.direction;\n                    float param_37 = _8823;\n                    float param_38 = _8927;\n                    area = fa_area_layers(param_31, param_32, param_33, param_34, param_35, param_36, param_37, param_38);\n                }\n                lit += area;\n            }\n            else\n            {\n                if (_8862.on)\n                {\n                    FaLayers param_39 = _8862;\n                    vec3 param_40 = _8839;\n                    vec3 param_41 = f0;\n                    vec3 param_42 = _8799;\n                    vec3 param_43 = _8751;\n                    vec3 param_44 = _8913.direction;\n                    vec3 param_45 = _8932;\n                    float param_46 = _8921;\n                    float param_47 = _8823;\n                    float param_48 = _8937;\n                    float param_49 = _8942;\n                    float param_50 = _8814;\n                    float param_51 = _8818;\n                    int param_52 = _8897;\n                    lit += (fa_layers_light(param_39, param_40, param_41, param_42, param_43, param_44, param_45, param_46, param_47, param_48, param_49, param_50, param_51) * ((fa_light_rgb(param_52) * fa_light_tint) * _8927));\n                }\n                else\n                {\n                    float _9051 = ((_8937 * _8937) * (_8818 - 1.0)) + 1.0;\n                    int param_53 = _8897;\n                    lit += (((_8839 + (((f0 + ((vec3(1.0) - f0) * pow(1.0 - _8942, 5.0))) * (((_8818 / ((3.1415927410125732421875 * _9051) * _9051)) * (0.5 / max(mix((2.0 * _8921) * _8823, _8921 + _8823, _8814), 9.9999997473787516355514526367188e-05))) * 3.1415927410125732421875)) * step(9.9999997473787516355514526367188e-05, _8921))) * (fa_light_rgb(param_53) * fa_light_tint)) * (_8921 * _8927));\n                }\n            }\n        }\n        if (_8862.on)\n        {\n            FaLayers param_54 = _8862;\n            vec3 param_55 = _8799;\n            vec3 param_56 = _8751;\n            vec3 param_57 = f0;\n            float param_58 = _8810;\n            float param_59 = _9489;\n            lit += fa_layers_ibl(param_54, param_55, param_56, param_57, param_58, param_59);\n        }\n        else\n        {\n            vec3 param_60 = _8799;\n            vec3 param_61 = _8751;\n            vec3 param_62 = f0;\n            float param_63 = _8810;\n            lit += (fa_sky_reflection(param_60, param_61, param_62, param_63) * _9489);\n        }\n        if (_8830 > 0.0)\n        {\n            float _9149;\n            if (_8862.on)\n            {\n                _9149 = _8862.f90;\n            }\n            else\n            {\n                _9149 = 1.0;\n            }\n            float _9157;\n            if (_8862.on)\n            {\n                _9157 = _8862.base_scale;\n            }\n            else\n            {\n                _9157 = 1.0;\n            }\n            Surface param_64 = Surface(_9484, _9485, _9486, _9487, _9488, _9489, _9490, _9491, _9492, _9493, _9494, _9495, _9496, _9497, _9498, _9499, _9500, _9501, _9502, _9503);\n            vec3 param_65 = _8799;\n            vec3 param_66 = _8751;\n            float param_67 = _8810;\n            vec3 param_68 = f0;\n            float param_69 = _9149;\n            float param_70 = _9157;\n            float param_71 = _8830;\n            float param_72 = fa_tr_blend;\n            vec3 _9181 = fa_transmitted(param_64, param_65, param_66, param_67, param_68, param_69, param_70, param_71, param_72);\n            fa_tr_blend = param_72;\n            lit += _9181;\n        }\n        result = lit;\n    }\n    vec3 _9188 = result;\n    vec3 _9189 = _9188 + _9490;\n    result = _9189;\n    vec3 param_73 = _9189;\n    vec3 param_74 = fa_world_pos;\n    result = fa_shadow_debug(param_73, param_74);\n    bool _9198 = fa_mesh_fs_params[7].w > 0.0;\n    bool _9205;\n    if (!_9198)\n    {\n        _9205 = fa_mesh_fs_params[8].y > 0.0;\n    }\n    else\n    {\n        _9205 = _9198;\n    }\n    if (_9205)\n    {\n        vec3 _9214 = fa_world_pos - fa_mesh_fs_params[0].xyz;\n        float _9220 = dot(_9214, fa_mesh_fs_params[9].xyz);\n        bool _9224 = fa_mesh_fs_params[9].w > 0.5;\n        float _9225;\n        if (_9224)\n        {\n            _9225 = _9220;\n        }\n        else\n        {\n            _9225 = length(_9214);\n        }\n        float _9237 = _9225 - fa_mesh_fs_params[8].x;\n        if (_9237 > 0.0)\n        {\n            float _9246 = fa_mesh_fs_params[7].w * _9237;\n            float tau = _9246 * _9246;\n            if (fa_mesh_fs_params[8].y > 0.0)\n            {\n                float _9262;\n                if (_9224)\n                {\n                    _9262 = fa_world_pos.y - (fa_mesh_fs_params[9].y * _9220);\n                }\n                else\n                {\n                    _9262 = fa_mesh_fs_params[0].y;\n                }\n                float _9283 = mix(_9262, fa_world_pos.y, clamp(fa_mesh_fs_params[8].x / _9225, 0.0, 1.0));\n                float _9287 = fa_world_pos.y - _9283;\n                float _9292 = _9283 - fa_mesh_fs_params[8].z;\n                float _9297 = fa_world_pos.y - fa_mesh_fs_params[8].z;\n                bool _9300 = _9292 <= 0.0;\n                bool _9301 = !_9300;\n                bool _9307;\n                if (_9301)\n                {\n                    _9307 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _9307 = _9300;\n                }\n                float _9308;\n                if (_9307)\n                {\n                    _9308 = fa_mesh_fs_params[8].y;\n                }\n                else\n                {\n                    _9308 = fa_mesh_fs_params[8].y * exp(-min(fa_mesh_fs_params[8].w * _9292, 80.0));\n                }\n                bool _9335;\n                if (_9301)\n                {\n                    _9335 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _9335 = _9300;\n                }\n                float _9336;\n                if (_9335)\n                {\n                    _9336 = fa_mesh_fs_params[8].y * _9292;\n                }\n                else\n                {\n                    _9336 = (fa_mesh_fs_params[8].y * (1.0 - exp(-min(fa_mesh_fs_params[8].w * _9292, 80.0)))) / fa_mesh_fs_params[8].w;\n                }\n                bool _9361 = _9297 <= 0.0;\n                bool _9368;\n                if (!_9361)\n                {\n                    _9368 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _9368 = _9361;\n                }\n                float _9369;\n                if (_9368)\n                {\n                    _9369 = fa_mesh_fs_params[8].y * _9297;\n                }\n                else\n                {\n                    _9369 = (fa_mesh_fs_params[8].y * (1.0 - exp(-min(fa_mesh_fs_params[8].w * _9297, 80.0)))) / fa_mesh_fs_params[8].w;\n                }\n                float _9396;\n                if (abs(_9287) < 0.001000000047497451305389404296875)\n                {\n                    _9396 = _9308;\n                }\n                else\n                {\n                    _9396 = (_9369 - _9336) / _9287;\n                }\n                tau += (_9237 * max(_9396, 0.0));\n            }\n            result = mix(result, fa_mesh_fs_params[7].xyz, vec3(clamp(1.0 - exp(-clamp(tau, 0.0, 80.0)), 0.0, 1.0)));\n        }\n    }\n    if (fa_tr_blend > 0.0)\n    {\n        float _9432 = 1.0 - fa_tr_blend;\n        result /= vec3(_9432);\n        _9485 *= _9432;\n    }\n    fa_frag_color = vec4(result, _9485);\n}\n\n",
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
            "size": 864,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_659",
            "glsl_uniforms": [
              {
                "type": "vec4",
                "array_count": 54,
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
            "inst_name": "_2321",
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
              "name": "fa_probe_atlas",
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
            "name": "fa_probe_atlas_fa_env_smp",
            "view_name": "fa_probe_atlas",
            "sampler_name": "fa_env_smp",
            "view_slot": 14,
            "sampler_slot": 10,
            "glsl_name": "fa_probe_atlas_fa_env_smp"
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
            "name": "fa_screen_tex_fa_shadow_smp",
            "view_name": "fa_screen_tex",
            "sampler_name": "fa_shadow_smp",
            "view_slot": 28,
            "sampler_slot": 1,
            "glsl_name": "fa_screen_tex_fa_shadow_smp"
          },
          {
            "slot": 11,
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
      "vs": "#version 430\n\nstruct VertexData\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 color;\n    vec3 object_pos;\n};\n\nstruct points_item\n{\n    vec4 pos;\n    vec4 tint;\n};\n\nuniform vec4 fa_mesh_vs_params[11];\nlayout(binding = 0, std430) readonly buffer fa_vs_points_buf\n{\n    points_item data[];\n} fa_vs_points;\n\nuniform vec4 fa_vel_params[9];\nuniform vec4 fa_inst_base[4];\nlayout(location = 0) out vec3 fa_world_pos;\nlayout(location = 1) out vec3 fa_world_normal;\nlayout(location = 2) out vec4 fa_world_tangent;\nlayout(location = 3) out vec2 fa_uv;\nlayout(location = 4) out vec4 fa_vertex_color;\nlayout(location = 5) out float fa_pre_depth;\nlayout(location = 6) out vec3 fa_pre_r0;\nlayout(location = 7) out vec3 fa_pre_r1;\nlayout(location = 8) out vec3 fa_pre_r2;\nlayout(location = 9) out vec3 fa_vel_cur;\nlayout(location = 10) out vec3 fa_vel_prev;\nlayout(location = 0) in vec3 fa_position;\nlayout(location = 1) in vec3 fa_normal;\nlayout(location = 3) in vec4 fa_tangent;\nlayout(location = 2) in vec2 fa_texcoord0;\nlayout(location = 4) in vec4 fa_color;\nlayout(location = 5) in vec4 fa_inst_m0;\nlayout(location = 6) in vec4 fa_inst_m1;\nlayout(location = 7) in vec4 fa_inst_m2;\nlayout(location = 8) in vec4 fa_inst_m3;\nvec4 fa_vtime;\n\nvoid fa_inst_begin()\n{\n}\n\nvec4 fa_time_now()\n{\n    return fa_mesh_vs_params[9];\n}\n\nVertexData fa_vertex_data(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    vec3 _129 = cross(model[1].xyz, model[2].xyz);\n    float _133 = (dot(model[0].xyz, _129) < 0.0) ? (-1.0) : 1.0;\n    return VertexData((model * vec4(position, 1.0)).xyz, (((_129 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _133, vec4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _133), texcoord0 * fa_mesh_vs_params[8].xy, color, position);\n}\n\nvoid vertex(inout VertexData v)\n{\n    if (fa_vs_points.data[gl_InstanceID].pos.w < 0.5)\n    {\n        v.world_pos = vec3(1000000000.0);\n        return;\n    }\n    v.world_pos += fa_vs_points.data[gl_InstanceID].pos.xyz;\n    v.color = fa_vs_points.data[gl_InstanceID].tint;\n}\n\nmat4 fa_prev_model()\n{\n    return mat4(vec4(1.0, 0.0, 0.0, 0.0), vec4(0.0, 1.0, 0.0, 0.0), vec4(0.0, 0.0, 1.0, 0.0), vec4(0.0, 0.0, 0.0, 1.0));\n}\n\nvoid fa_prepass_vertex(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color, bool has_prev)\n{\n    bool _208;\n    if (has_prev)\n    {\n        _208 = fa_vel_params[8].x > 0.5;\n    }\n    else\n    {\n        _208 = has_prev;\n    }\n    fa_vtime = fa_time_now();\n    mat4 param = model;\n    vec3 param_1 = position;\n    vec3 param_2 = normal;\n    vec4 param_3 = tangent;\n    vec2 param_4 = texcoord0;\n    vec4 param_5 = color;\n    VertexData param_6 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    vertex(param_6);\n    mat4 _231 = mat4(fa_mesh_vs_params[4], fa_mesh_vs_params[5], fa_mesh_vs_params[6], fa_mesh_vs_params[7]);\n    vec4 _238 = vec4(param_6.world_pos, 1.0);\n    fa_world_pos = param_6.world_pos;\n    fa_world_normal = param_6.world_normal;\n    fa_world_tangent = param_6.world_tangent;\n    fa_uv = param_6.uv;\n    fa_vertex_color = param_6.color;\n    fa_pre_depth = -(_231 * _238).z;\n    fa_pre_r0 = vec3(_231[0].x, _231[1].x, _231[2].x);\n    fa_pre_r1 = vec3(_231[0].y, _231[1].y, _231[2].y);\n    fa_pre_r2 = vec3(_231[0].z, _231[1].z, _231[2].z);\n    gl_Position = mat4(fa_mesh_vs_params[0], fa_mesh_vs_params[1], fa_mesh_vs_params[2], fa_mesh_vs_params[3]) * _238;\n    fa_vel_cur = vec3(0.0, 0.0, 1.0);\n    fa_vel_prev = vec3(0.0);\n    if (_208)\n    {\n        fa_vtime.x = fa_vel_params[8].y;\n        mat4 param_7 = fa_prev_model();\n        vec3 param_8 = position;\n        vec3 param_9 = normal;\n        vec4 param_10 = tangent;\n        vec2 param_11 = texcoord0;\n        vec4 param_12 = color;\n        VertexData param_13 = fa_vertex_data(param_7, param_8, param_9, param_10, param_11, param_12);\n        vertex(param_13);\n        fa_vel_cur = vec3((mat4(fa_vel_params[0], fa_vel_params[1], fa_vel_params[2], fa_vel_params[3]) * _238).xyw);\n        fa_vel_prev = vec3((mat4(fa_vel_params[4], fa_vel_params[5], fa_vel_params[6], fa_vel_params[7]) * vec4(param_13.world_pos, 1.0)).xyw);\n    }\n}\n\nvoid main()\n{\n    fa_vtime = vec4(0.0);\n    fa_inst_begin();\n    mat4 param = mat4(fa_inst_base[0], fa_inst_base[1], fa_inst_base[2], fa_inst_base[3]);\n    vec3 param_1 = fa_position;\n    vec3 param_2 = fa_normal;\n    vec4 param_3 = fa_tangent;\n    vec2 param_4 = fa_texcoord0;\n    vec4 param_5 = fa_color;\n    bool param_6 = false;\n    fa_prepass_vertex(param, param_1, param_2, param_3, param_4, param_5, param_6);\n}\n\n",
      "fs": "#version 430\n\nstruct SurfaceInput\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 vertex_color;\n    vec3 view_dir;\n    bool front_facing;\n};\n\nstruct Surface\n{\n    vec3 albedo;\n    float alpha;\n    vec3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    vec3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    vec3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    vec3 specular_color;\n    float transmission;\n    float thickness;\n    vec3 attenuation_color;\n    float attenuation_distance;\n};\n\nstruct points_item\n{\n    vec4 pos;\n    vec4 tint;\n};\n\nlayout(binding = 1, std430) readonly buffer fa_points_buf\n{\n    points_item data[];\n} points;\n\nuniform vec4 fa_mesh_fs_params[54];\nlayout(binding = 0) uniform sampler2D fa_tex_fa_smp;\nlayout(binding = 1) uniform sampler2D fa_normal_tex_fa_smp;\nlayout(binding = 2) uniform sampler2D fa_mr_tex_fa_smp;\nlayout(binding = 3) uniform sampler2D fa_occlusion_tex_fa_smp;\nlayout(binding = 4) uniform sampler2D fa_emissive_tex_fa_smp;\n\nlayout(location = 0) in vec3 fa_world_pos;\nlayout(location = 1) in vec3 fa_world_normal;\nlayout(location = 2) in vec4 fa_world_tangent;\nlayout(location = 3) in vec2 fa_uv;\nlayout(location = 4) in vec4 fa_vertex_color;\nlayout(location = 6) in vec3 fa_pre_r0;\nlayout(location = 7) in vec3 fa_pre_r1;\nlayout(location = 8) in vec3 fa_pre_r2;\nlayout(location = 0) out vec4 fa_frag_color;\nlayout(location = 5) in float fa_pre_depth;\nlayout(location = 9) in vec3 fa_vel_cur;\nlayout(location = 10) in vec3 fa_vel_prev;\nlayout(location = 1) out vec2 fa_frag_velocity;\n\nvoid fa_inst_load()\n{\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nvec3 fa_linear_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_tex_fix(inout vec3 c, float mode)\n{\n    if (mode > 1.5)\n    {\n        vec3 param = c;\n        vec3 _190 = fa_linear_to_srgb(param);\n        c = _190;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            vec3 param_1 = c;\n            vec3 _199 = fa_srgb_to_linear(param_1);\n            c = _199;\n        }\n    }\n    return c;\n}\n\nvec3 fa_tangent_normal(SurfaceInput i, vec3 m)\n{\n    vec3 _56;\n    if (i.front_facing)\n    {\n        _56 = i.world_normal;\n    }\n    else\n    {\n        _56 = -i.world_normal;\n    }\n    vec3 _81 = normalize(i.world_tangent.xyz - (_56 * dot(_56, i.world_tangent.xyz)));\n    vec3 _109 = normalize(((_81 * m.x) + ((cross(_56, _81) * i.world_tangent.w) * m.y)) + (_56 * m.z));\n    vec3 _112;\n    if (i.front_facing)\n    {\n        _112 = _109;\n    }\n    else\n    {\n        _112 = -_109;\n    }\n    return _112;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    vec4 base_t = texture(fa_tex_fa_smp, i.uv, fa_mesh_fs_params[12].w);\n    float param = fa_mesh_fs_params[6].w;\n    float param_1 = 1.0;\n    vec3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    vec3 _247 = fa_tex_fix(param_2, param_3);\n    vec4 _854 = base_t;\n    _854.x = _247.x;\n    _854.y = _247.y;\n    _854.z = _247.z;\n    base_t = _854;\n    vec4 _262 = (_854 * fa_mesh_fs_params[2]) * i.vertex_color;\n    vec3 _809 = i.world_normal;\n    if (fa_mesh_fs_params[6].z > 0.5)\n    {\n        float param_4 = fa_mesh_fs_params[6].w;\n        float param_5 = 16.0;\n        vec3 param_6 = texture(fa_normal_tex_fa_smp, i.uv, fa_mesh_fs_params[12].w).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        vec3 _297 = fa_tex_fix(param_6, param_7);\n        vec3 _301 = (_297 * 2.0) - vec3(1.0);\n        vec2 _306 = _301.xy * fa_mesh_fs_params[6].x;\n        vec3 _862 = _301;\n        _862.x = _306.x;\n        _862.y = _306.y;\n        SurfaceInput param_8 = i;\n        vec3 param_9 = _862;\n        _809 = fa_tangent_normal(param_8, param_9);\n    }\n    vec4 mrt = texture(fa_mr_tex_fa_smp, i.uv, fa_mesh_fs_params[12].w);\n    float param_10 = fa_mesh_fs_params[6].w;\n    float param_11 = 64.0;\n    vec3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    vec3 _337 = fa_tex_fix(param_12, param_13);\n    vec4 _865 = mrt;\n    _865.x = _337.x;\n    _865.y = _337.y;\n    _865.z = _337.z;\n    mrt = _865;\n    vec4 _369 = texture(fa_occlusion_tex_fa_smp, i.uv, fa_mesh_fs_params[12].w);\n    float param_14 = fa_mesh_fs_params[6].w;\n    float param_15 = 256.0;\n    vec3 param_16 = _369.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    vec3 _381 = fa_tex_fix(param_16, param_17);\n    float param_18 = fa_mesh_fs_params[6].w;\n    float param_19 = 4.0;\n    vec3 param_20 = texture(fa_emissive_tex_fa_smp, i.uv, fa_mesh_fs_params[12].w).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    vec3 _413 = fa_tex_fix(param_20, param_21);\n    float _814 = fa_mesh_fs_params[20].x;\n    float _815 = fa_mesh_fs_params[20].y;\n    float _818 = fa_mesh_fs_params[20].z;\n    float _817 = fa_mesh_fs_params[21].w;\n    float _820 = fa_mesh_fs_params[22].x;\n    if (fa_mesh_fs_params[22].z > 0.5)\n    {\n        if (mod(fa_mesh_fs_params[22].z, 2.0) > 0.5)\n        {\n            _814 *= _381.y;\n            _815 *= _381.z;\n            _817 *= _369.w;\n        }\n        if (fa_mesh_fs_params[22].z > 1.5)\n        {\n            _818 *= mrt.x;\n            _820 *= mrt.w;\n        }\n    }\n    return Surface(_262.xyz, _262.w, _809, clamp(fa_mesh_fs_params[5].x * _337.z, 0.0, 1.0), clamp(fa_mesh_fs_params[5].y * _337.y, 0.0500000007450580596923828125, 1.0), 1.0 + (fa_mesh_fs_params[6].y * (_381.x - 1.0)), fa_mesh_fs_params[3].xyz + (fa_mesh_fs_params[4].xyz * _413), _814, _815, fa_mesh_fs_params[21].xyz, _817, _818, fa_mesh_fs_params[20].w, _820, fa_mesh_fs_params[22].y, fa_mesh_fs_params[23].xyz, fa_mesh_fs_params[30].x, fa_mesh_fs_params[30].y, fa_mesh_fs_params[31].xyz, fa_mesh_fs_params[30].z);\n}\n\nvoid surface(SurfaceInput i, inout Surface s)\n{\n    s.emission += (i.vertex_color.xyz * points.data[0].tint.w);\n}\n\nvoid main()\n{\n    fa_inst_load();\n    vec3 _704 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _704 = -_704;\n    }\n    vec3 _565 = normalize(fa_mesh_fs_params[0].xyz - fa_world_pos);\n    SurfaceInput param = SurfaceInput(fa_world_pos, _704, fa_world_tangent, fa_uv, fa_vertex_color, _565, gl_FrontFacing);\n    SurfaceInput param_1 = SurfaceInput(fa_world_pos, _704, fa_world_tangent, fa_uv, fa_vertex_color, _565, gl_FrontFacing);\n    Surface param_2 = fa_standard_surface(param);\n    surface(param_1, param_2);\n    vec3 _580 = normalize(param_2.normal);\n    vec3 _595 = normalize(vec3(dot(fa_pre_r0, _580), dot(fa_pre_r1, _580), dot(fa_pre_r2, _580)));\n    float _607 = _595.z;\n    vec2 e = _595.xy / vec2((abs(_595.x) + abs(_595.y)) + abs(_607));\n    if (_607 < 0.0)\n    {\n        e = (vec2(1.0) - abs(e.yx)) * vec2((e.x >= 0.0) ? 1.0 : (-1.0), (e.y >= 0.0) ? 1.0 : (-1.0));\n    }\n    fa_frag_color = vec4(min(fa_pre_depth, 60000.0), e, 1.0);\n    vec2 motion = vec2(1024.0);\n    bool _651 = fa_vel_cur.z > 9.9999997473787516355514526367188e-06;\n    bool _658;\n    if (_651)\n    {\n        _658 = fa_vel_prev.z > 9.9999997473787516355514526367188e-06;\n    }\n    else\n    {\n        _658 = _651;\n    }\n    if (_658)\n    {\n        motion = clamp(((vec2(fa_vel_prev.x, -fa_vel_prev.y) / vec2(fa_vel_prev.z)) * 0.5) - ((vec2(fa_vel_cur.x, -fa_vel_cur.y) / vec2(fa_vel_cur.z)) * 0.5), vec2(-4.0), vec2(4.0));\n    }\n    fa_frag_velocity = motion;\n}\n\n",
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
            "inst_name": "_56",
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
            "slot": 2,
            "stage": "vertex",
            "size": 144,
            "struct_name": "fa_vel_params",
            "inst_name": "_203",
            "glsl_uniforms": [
              {
                "type": "vec4",
                "array_count": 9,
                "offset": 0,
                "glsl_name": "fa_vel_params"
              }
            ]
          },
          {
            "slot": 6,
            "stage": "vertex",
            "size": 64,
            "struct_name": "fa_inst_base",
            "inst_name": "_369",
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
            "size": 864,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_232",
            "glsl_uniforms": [
              {
                "type": "vec4",
                "array_count": 54,
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
      "vs": "#version 430\n\nstruct VertexData\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 color;\n    vec3 object_pos;\n};\n\nstruct points_item\n{\n    vec4 pos;\n    vec4 tint;\n};\n\nuniform vec4 fa_mesh_vs_params[11];\nlayout(binding = 0, std430) readonly buffer fa_vs_points_buf\n{\n    points_item data[];\n} fa_vs_points;\n\nuniform vec4 fa_skin[192];\nuniform vec4 fa_vel_params[9];\nuniform vec4 fa_inst_base[4];\nlayout(location = 0) out vec3 fa_world_pos;\nlayout(location = 1) out vec3 fa_world_normal;\nlayout(location = 2) out vec4 fa_world_tangent;\nlayout(location = 3) out vec2 fa_uv;\nlayout(location = 4) out vec4 fa_vertex_color;\nlayout(location = 5) out float fa_pre_depth;\nlayout(location = 6) out vec3 fa_pre_r0;\nlayout(location = 7) out vec3 fa_pre_r1;\nlayout(location = 8) out vec3 fa_pre_r2;\nlayout(location = 9) out vec3 fa_vel_cur;\nlayout(location = 10) out vec3 fa_vel_prev;\nlayout(location = 9) in vec4 fa_joints;\nlayout(location = 10) in vec4 fa_weights;\nlayout(location = 0) in vec3 fa_position;\nlayout(location = 1) in vec3 fa_normal;\nlayout(location = 3) in vec4 fa_tangent;\nlayout(location = 2) in vec2 fa_texcoord0;\nlayout(location = 4) in vec4 fa_color;\nlayout(location = 5) in vec4 fa_inst_m0;\nlayout(location = 6) in vec4 fa_inst_m1;\nlayout(location = 7) in vec4 fa_inst_m2;\nlayout(location = 8) in vec4 fa_inst_m3;\nvec4 fa_vtime;\n\nvoid fa_inst_begin()\n{\n}\n\nmat4 fa_skin_matrix(vec4 joints, vec4 weights)\n{\n    vec4 r0 = vec4(0.0);\n    vec4 r1 = vec4(0.0);\n    vec4 r2 = vec4(0.0);\n    for (int i = 0; i < 4; i++)\n    {\n        int _222 = int((joints[i] * 255.0) + 0.5) * 3;\n        r0 += (fa_skin[_222 * 1 + 0] * weights[i]);\n        r1 += (fa_skin[(_222 + 1) * 1 + 0] * weights[i]);\n        r2 += (fa_skin[(_222 + 2) * 1 + 0] * weights[i]);\n    }\n    return mat4(vec4(r0.x, r1.x, r2.x, 0.0), vec4(r0.y, r1.y, r2.y, 0.0), vec4(r0.z, r1.z, r2.z, 0.0), vec4(r0.w, r1.w, r2.w, 1.0));\n}\n\nvec4 fa_time_now()\n{\n    return fa_mesh_vs_params[9];\n}\n\nVertexData fa_vertex_data(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    vec3 _134 = cross(model[1].xyz, model[2].xyz);\n    float _138 = (dot(model[0].xyz, _134) < 0.0) ? (-1.0) : 1.0;\n    return VertexData((model * vec4(position, 1.0)).xyz, (((_134 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _138, vec4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _138), texcoord0 * fa_mesh_vs_params[8].xy, color, position);\n}\n\nvoid vertex(inout VertexData v)\n{\n    if (fa_vs_points.data[gl_InstanceID].pos.w < 0.5)\n    {\n        v.world_pos = vec3(1000000000.0);\n        return;\n    }\n    v.world_pos += fa_vs_points.data[gl_InstanceID].pos.xyz;\n    v.color = fa_vs_points.data[gl_InstanceID].tint;\n}\n\nmat4 fa_prev_model()\n{\n    return mat4(vec4(1.0, 0.0, 0.0, 0.0), vec4(0.0, 1.0, 0.0, 0.0), vec4(0.0, 0.0, 1.0, 0.0), vec4(0.0, 0.0, 0.0, 1.0));\n}\n\nvoid fa_prepass_vertex(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color, bool has_prev)\n{\n    bool _319;\n    if (has_prev)\n    {\n        _319 = fa_vel_params[8].x > 0.5;\n    }\n    else\n    {\n        _319 = has_prev;\n    }\n    fa_vtime = fa_time_now();\n    mat4 param = model;\n    vec3 param_1 = position;\n    vec3 param_2 = normal;\n    vec4 param_3 = tangent;\n    vec2 param_4 = texcoord0;\n    vec4 param_5 = color;\n    VertexData param_6 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    vertex(param_6);\n    mat4 _342 = mat4(fa_mesh_vs_params[4], fa_mesh_vs_params[5], fa_mesh_vs_params[6], fa_mesh_vs_params[7]);\n    vec4 _349 = vec4(param_6.world_pos, 1.0);\n    fa_world_pos = param_6.world_pos;\n    fa_world_normal = param_6.world_normal;\n    fa_world_tangent = param_6.world_tangent;\n    fa_uv = param_6.uv;\n    fa_vertex_color = param_6.color;\n    fa_pre_depth = -(_342 * _349).z;\n    fa_pre_r0 = vec3(_342[0].x, _342[1].x, _342[2].x);\n    fa_pre_r1 = vec3(_342[0].y, _342[1].y, _342[2].y);\n    fa_pre_r2 = vec3(_342[0].z, _342[1].z, _342[2].z);\n    gl_Position = mat4(fa_mesh_vs_params[0], fa_mesh_vs_params[1], fa_mesh_vs_params[2], fa_mesh_vs_params[3]) * _349;\n    fa_vel_cur = vec3(0.0, 0.0, 1.0);\n    fa_vel_prev = vec3(0.0);\n    if (_319)\n    {\n        fa_vtime.x = fa_vel_params[8].y;\n        mat4 param_7 = fa_prev_model();\n        vec3 param_8 = position;\n        vec3 param_9 = normal;\n        vec4 param_10 = tangent;\n        vec2 param_11 = texcoord0;\n        vec4 param_12 = color;\n        VertexData param_13 = fa_vertex_data(param_7, param_8, param_9, param_10, param_11, param_12);\n        vertex(param_13);\n        fa_vel_cur = vec3((mat4(fa_vel_params[0], fa_vel_params[1], fa_vel_params[2], fa_vel_params[3]) * _349).xyw);\n        fa_vel_prev = vec3((mat4(fa_vel_params[4], fa_vel_params[5], fa_vel_params[6], fa_vel_params[7]) * vec4(param_13.world_pos, 1.0)).xyw);\n    }\n}\n\nvoid main()\n{\n    fa_vtime = vec4(0.0);\n    fa_inst_begin();\n    vec4 param = fa_joints;\n    vec4 param_1 = fa_weights;\n    mat4 param_2 = mat4(fa_inst_base[0], fa_inst_base[1], fa_inst_base[2], fa_inst_base[3]) * fa_skin_matrix(param, param_1);\n    vec3 param_3 = fa_position;\n    vec3 param_4 = fa_normal;\n    vec4 param_5 = fa_tangent;\n    vec2 param_6 = fa_texcoord0;\n    vec4 param_7 = fa_color;\n    bool param_8 = false;\n    fa_prepass_vertex(param_2, param_3, param_4, param_5, param_6, param_7, param_8);\n}\n\n",
      "fs": "#version 430\n\nstruct SurfaceInput\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 vertex_color;\n    vec3 view_dir;\n    bool front_facing;\n};\n\nstruct Surface\n{\n    vec3 albedo;\n    float alpha;\n    vec3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    vec3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    vec3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    vec3 specular_color;\n    float transmission;\n    float thickness;\n    vec3 attenuation_color;\n    float attenuation_distance;\n};\n\nstruct points_item\n{\n    vec4 pos;\n    vec4 tint;\n};\n\nlayout(binding = 1, std430) readonly buffer fa_points_buf\n{\n    points_item data[];\n} points;\n\nuniform vec4 fa_mesh_fs_params[54];\nlayout(binding = 0) uniform sampler2D fa_tex_fa_smp;\nlayout(binding = 1) uniform sampler2D fa_normal_tex_fa_smp;\nlayout(binding = 2) uniform sampler2D fa_mr_tex_fa_smp;\nlayout(binding = 3) uniform sampler2D fa_occlusion_tex_fa_smp;\nlayout(binding = 4) uniform sampler2D fa_emissive_tex_fa_smp;\n\nlayout(location = 0) in vec3 fa_world_pos;\nlayout(location = 1) in vec3 fa_world_normal;\nlayout(location = 2) in vec4 fa_world_tangent;\nlayout(location = 3) in vec2 fa_uv;\nlayout(location = 4) in vec4 fa_vertex_color;\nlayout(location = 6) in vec3 fa_pre_r0;\nlayout(location = 7) in vec3 fa_pre_r1;\nlayout(location = 8) in vec3 fa_pre_r2;\nlayout(location = 0) out vec4 fa_frag_color;\nlayout(location = 5) in float fa_pre_depth;\nlayout(location = 9) in vec3 fa_vel_cur;\nlayout(location = 10) in vec3 fa_vel_prev;\nlayout(location = 1) out vec2 fa_frag_velocity;\n\nvoid fa_inst_load()\n{\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nvec3 fa_linear_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_tex_fix(inout vec3 c, float mode)\n{\n    if (mode > 1.5)\n    {\n        vec3 param = c;\n        vec3 _190 = fa_linear_to_srgb(param);\n        c = _190;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            vec3 param_1 = c;\n            vec3 _199 = fa_srgb_to_linear(param_1);\n            c = _199;\n        }\n    }\n    return c;\n}\n\nvec3 fa_tangent_normal(SurfaceInput i, vec3 m)\n{\n    vec3 _56;\n    if (i.front_facing)\n    {\n        _56 = i.world_normal;\n    }\n    else\n    {\n        _56 = -i.world_normal;\n    }\n    vec3 _81 = normalize(i.world_tangent.xyz - (_56 * dot(_56, i.world_tangent.xyz)));\n    vec3 _109 = normalize(((_81 * m.x) + ((cross(_56, _81) * i.world_tangent.w) * m.y)) + (_56 * m.z));\n    vec3 _112;\n    if (i.front_facing)\n    {\n        _112 = _109;\n    }\n    else\n    {\n        _112 = -_109;\n    }\n    return _112;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    vec4 base_t = texture(fa_tex_fa_smp, i.uv, fa_mesh_fs_params[12].w);\n    float param = fa_mesh_fs_params[6].w;\n    float param_1 = 1.0;\n    vec3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    vec3 _247 = fa_tex_fix(param_2, param_3);\n    vec4 _854 = base_t;\n    _854.x = _247.x;\n    _854.y = _247.y;\n    _854.z = _247.z;\n    base_t = _854;\n    vec4 _262 = (_854 * fa_mesh_fs_params[2]) * i.vertex_color;\n    vec3 _809 = i.world_normal;\n    if (fa_mesh_fs_params[6].z > 0.5)\n    {\n        float param_4 = fa_mesh_fs_params[6].w;\n        float param_5 = 16.0;\n        vec3 param_6 = texture(fa_normal_tex_fa_smp, i.uv, fa_mesh_fs_params[12].w).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        vec3 _297 = fa_tex_fix(param_6, param_7);\n        vec3 _301 = (_297 * 2.0) - vec3(1.0);\n        vec2 _306 = _301.xy * fa_mesh_fs_params[6].x;\n        vec3 _862 = _301;\n        _862.x = _306.x;\n        _862.y = _306.y;\n        SurfaceInput param_8 = i;\n        vec3 param_9 = _862;\n        _809 = fa_tangent_normal(param_8, param_9);\n    }\n    vec4 mrt = texture(fa_mr_tex_fa_smp, i.uv, fa_mesh_fs_params[12].w);\n    float param_10 = fa_mesh_fs_params[6].w;\n    float param_11 = 64.0;\n    vec3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    vec3 _337 = fa_tex_fix(param_12, param_13);\n    vec4 _865 = mrt;\n    _865.x = _337.x;\n    _865.y = _337.y;\n    _865.z = _337.z;\n    mrt = _865;\n    vec4 _369 = texture(fa_occlusion_tex_fa_smp, i.uv, fa_mesh_fs_params[12].w);\n    float param_14 = fa_mesh_fs_params[6].w;\n    float param_15 = 256.0;\n    vec3 param_16 = _369.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    vec3 _381 = fa_tex_fix(param_16, param_17);\n    float param_18 = fa_mesh_fs_params[6].w;\n    float param_19 = 4.0;\n    vec3 param_20 = texture(fa_emissive_tex_fa_smp, i.uv, fa_mesh_fs_params[12].w).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    vec3 _413 = fa_tex_fix(param_20, param_21);\n    float _814 = fa_mesh_fs_params[20].x;\n    float _815 = fa_mesh_fs_params[20].y;\n    float _818 = fa_mesh_fs_params[20].z;\n    float _817 = fa_mesh_fs_params[21].w;\n    float _820 = fa_mesh_fs_params[22].x;\n    if (fa_mesh_fs_params[22].z > 0.5)\n    {\n        if (mod(fa_mesh_fs_params[22].z, 2.0) > 0.5)\n        {\n            _814 *= _381.y;\n            _815 *= _381.z;\n            _817 *= _369.w;\n        }\n        if (fa_mesh_fs_params[22].z > 1.5)\n        {\n            _818 *= mrt.x;\n            _820 *= mrt.w;\n        }\n    }\n    return Surface(_262.xyz, _262.w, _809, clamp(fa_mesh_fs_params[5].x * _337.z, 0.0, 1.0), clamp(fa_mesh_fs_params[5].y * _337.y, 0.0500000007450580596923828125, 1.0), 1.0 + (fa_mesh_fs_params[6].y * (_381.x - 1.0)), fa_mesh_fs_params[3].xyz + (fa_mesh_fs_params[4].xyz * _413), _814, _815, fa_mesh_fs_params[21].xyz, _817, _818, fa_mesh_fs_params[20].w, _820, fa_mesh_fs_params[22].y, fa_mesh_fs_params[23].xyz, fa_mesh_fs_params[30].x, fa_mesh_fs_params[30].y, fa_mesh_fs_params[31].xyz, fa_mesh_fs_params[30].z);\n}\n\nvoid surface(SurfaceInput i, inout Surface s)\n{\n    s.emission += (i.vertex_color.xyz * points.data[0].tint.w);\n}\n\nvoid main()\n{\n    fa_inst_load();\n    vec3 _704 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _704 = -_704;\n    }\n    vec3 _565 = normalize(fa_mesh_fs_params[0].xyz - fa_world_pos);\n    SurfaceInput param = SurfaceInput(fa_world_pos, _704, fa_world_tangent, fa_uv, fa_vertex_color, _565, gl_FrontFacing);\n    SurfaceInput param_1 = SurfaceInput(fa_world_pos, _704, fa_world_tangent, fa_uv, fa_vertex_color, _565, gl_FrontFacing);\n    Surface param_2 = fa_standard_surface(param);\n    surface(param_1, param_2);\n    vec3 _580 = normalize(param_2.normal);\n    vec3 _595 = normalize(vec3(dot(fa_pre_r0, _580), dot(fa_pre_r1, _580), dot(fa_pre_r2, _580)));\n    float _607 = _595.z;\n    vec2 e = _595.xy / vec2((abs(_595.x) + abs(_595.y)) + abs(_607));\n    if (_607 < 0.0)\n    {\n        e = (vec2(1.0) - abs(e.yx)) * vec2((e.x >= 0.0) ? 1.0 : (-1.0), (e.y >= 0.0) ? 1.0 : (-1.0));\n    }\n    fa_frag_color = vec4(min(fa_pre_depth, 60000.0), e, 1.0);\n    vec2 motion = vec2(1024.0);\n    bool _651 = fa_vel_cur.z > 9.9999997473787516355514526367188e-06;\n    bool _658;\n    if (_651)\n    {\n        _658 = fa_vel_prev.z > 9.9999997473787516355514526367188e-06;\n    }\n    else\n    {\n        _658 = _651;\n    }\n    if (_658)\n    {\n        motion = clamp(((vec2(fa_vel_prev.x, -fa_vel_prev.y) / vec2(fa_vel_prev.z)) * 0.5) - ((vec2(fa_vel_cur.x, -fa_vel_cur.y) / vec2(fa_vel_cur.z)) * 0.5), vec2(-4.0), vec2(4.0));\n    }\n    fa_frag_velocity = motion;\n}\n\n",
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
            "inst_name": "_61",
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
            "slot": 2,
            "stage": "vertex",
            "size": 144,
            "struct_name": "fa_vel_params",
            "inst_name": "_314",
            "glsl_uniforms": [
              {
                "type": "vec4",
                "array_count": 9,
                "offset": 0,
                "glsl_name": "fa_vel_params"
              }
            ]
          },
          {
            "slot": 6,
            "stage": "vertex",
            "size": 64,
            "struct_name": "fa_inst_base",
            "inst_name": "_480",
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
            "size": 864,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_232",
            "glsl_uniforms": [
              {
                "type": "vec4",
                "array_count": 54,
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
