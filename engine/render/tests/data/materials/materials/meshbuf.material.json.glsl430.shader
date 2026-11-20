{
  "format": "factoria.shader/1",
  "engine": "0.32.0",
  "template": "5f457c7d0bc8edbcdea422ba00c093c613745eefd8db6d8c8f93fc5e235db1e8",
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
      "fs": "#version 430\n\nstruct SurfaceInput\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 vertex_color;\n    vec3 view_dir;\n    bool front_facing;\n};\n\nstruct LightSample\n{\n    vec3 direction;\n    vec3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct Surface\n{\n    vec3 albedo;\n    float alpha;\n    vec3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    vec3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    vec3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    vec3 specular_color;\n};\n\nstruct FaLayers\n{\n    bool on;\n    float f90;\n    float keep;\n    float base_scale;\n    float coat;\n    float coat_rough;\n    float coat_alpha;\n    float coat_a2;\n    vec3 nc;\n    float coat_ndv;\n    bool sheen_on;\n    vec3 sheen;\n    float sheen_rough;\n    float sheen_alpha;\n    float sheen_scale;\n    float sheen_e;\n    float aniso;\n    vec3 t;\n    vec3 b;\n    float at;\n    float ab;\n};\n\nconst float _3645[63] = float[](1.0, 1.0, 1.0, 0.4790000021457672119140625, 0.11699999868869781494140625, 0.01200000010430812835693359375, 0.0, 0.0, 0.0, 1.0, 1.0, 1.0, 0.578000009059906005859375, 0.19300000369548797607421875, 0.0350000001490116119384765625, 0.0030000000260770320892333984375, 0.0, 0.0, 1.0, 1.0, 1.0, 0.6740000247955322265625, 0.3459999859333038330078125, 0.1319999992847442626953125, 0.032999999821186065673828125, 0.0040000001899898052215576171875, 0.0, 0.971000015735626220703125, 0.954999983310699462890625, 0.828999996185302734375, 0.63999998569488525390625, 0.42599999904632568359375, 0.24500000476837158203125, 0.115000002086162567138671875, 0.037000000476837158203125, 0.0030000000260770320892333984375, 0.7469999790191650390625, 0.737999975681304931640625, 0.670000016689300537109375, 0.563000023365020751953125, 0.4309999942779541015625, 0.3039999902248382568359375, 0.1940000057220458984375, 0.1019999980926513671875, 0.0309999994933605194091796875, 0.614000022411346435546875, 0.609000027179718017578125, 0.566999971866607666015625, 0.499000012874603271484375, 0.412000000476837158203125, 0.32400000095367431640625, 0.240999996662139892578125, 0.162000000476837158203125, 0.087999999523162841796875, 0.538999974727630615234375, 0.535000026226043701171875, 0.505999982357025146484375, 0.4569999873638153076171875, 0.393999993801116943359375, 0.328999996185302734375, 0.2660000026226043701171875, 0.203999996185302734375, 0.14200000464916229248046875);\n\nstruct points_item\n{\n    vec4 pos;\n    vec4 tint;\n};\n\nuniform vec4 fa_mesh_fs_params[24];\nuniform vec4 fa_shadows[30];\nlayout(binding = 1, std430) readonly buffer fa_points_buf\n{\n    points_item data[];\n} points;\n\nlayout(binding = 0) uniform sampler2D fa_light_tex_fa_shadow_smp;\nlayout(binding = 1) uniform sampler2D fa_tex_fa_smp;\nlayout(binding = 2) uniform sampler2D fa_normal_tex_fa_smp;\nlayout(binding = 3) uniform sampler2D fa_mr_tex_fa_smp;\nlayout(binding = 4) uniform sampler2D fa_occlusion_tex_fa_smp;\nlayout(binding = 5) uniform sampler2D fa_emissive_tex_fa_smp;\nlayout(binding = 6) uniform sampler2D fa_decal_tex_fa_env_smp;\nlayout(binding = 7) uniform sampler2D fa_lightmap_fa_env_smp;\nlayout(binding = 8) uniform samplerCube fa_env_tex_fa_env_smp;\nlayout(binding = 9) uniform sampler2D fa_light_atlas_fa_env_smp;\nlayout(binding = 10) uniform sampler2D fa_shadow_tex_fa_shadow_smp;\n\nlayout(location = 0) in vec3 fa_world_pos;\nlayout(location = 5) in vec3 fa_lm;\nlayout(location = 1) in vec3 fa_world_normal;\nlayout(location = 2) in vec4 fa_world_tangent;\nlayout(location = 3) in vec2 fa_uv;\nlayout(location = 4) in vec4 fa_vertex_color;\nlayout(location = 0) out vec4 fa_frag_color;\nvec3 fa_light_tint;\nbool fa_light_is_area;\nint fa_cl_ndir;\nint fa_cl_slot;\nint fa_cl_local;\n\nvoid fa_inst_load()\n{\n}\n\nvec4 fa_light_texel(int t)\n{\n    return texelFetch(fa_light_tex_fa_shadow_smp, ivec2(t & 1023, t >> 10), 0);\n}\n\nvec4 fa_cluster_texel(vec3 world_pos)\n{\n    bool _1486 = fa_mesh_fs_params[19].x < 0.0;\n    bool _1493;\n    if (!_1486)\n    {\n        _1493 = fa_mesh_fs_params[19].w < 1.0;\n    }\n    else\n    {\n        _1493 = _1486;\n    }\n    bool _1501;\n    if (!_1493)\n    {\n        _1501 = fa_mesh_fs_params[18].x < 1.0;\n    }\n    else\n    {\n        _1501 = _1493;\n    }\n    bool _1508;\n    if (!_1501)\n    {\n        _1508 = fa_mesh_fs_params[18].y < 1.0;\n    }\n    else\n    {\n        _1508 = _1501;\n    }\n    bool _1515;\n    if (!_1508)\n    {\n        _1515 = fa_mesh_fs_params[19].y < 1.0;\n    }\n    else\n    {\n        _1515 = _1508;\n    }\n    if (_1515)\n    {\n        return vec4(0.0);\n    }\n    vec4 _1525 = vec4(world_pos, 1.0);\n    float _1531 = dot(fa_mesh_fs_params[16], _1525);\n    if (!(_1531 > 9.9999999747524270787835121154785e-07))\n    {\n        return vec4(0.0);\n    }\n    vec2 _1553 = vec2(dot(fa_mesh_fs_params[14], _1525), dot(fa_mesh_fs_params[15], _1525)) / vec2(_1531);\n    int _1557 = int(fa_mesh_fs_params[18].x);\n    int _1561 = int(fa_mesh_fs_params[18].y);\n    int param = (int(fa_mesh_fs_params[19].x) + (((clamp(int(floor(log2(max(dot(fa_mesh_fs_params[17].xyz, world_pos) + fa_mesh_fs_params[17].w, fa_mesh_fs_params[18].w) / fa_mesh_fs_params[18].w) * fa_mesh_fs_params[18].z)), 0, int(fa_mesh_fs_params[19].y) - 1) * _1561) + clamp(int(floor(((_1553.y * 0.5) + 0.5) * fa_mesh_fs_params[18].y)), 0, _1561 - 1)) * _1557)) + clamp(int(floor(((_1553.x * 0.5) + 0.5) * fa_mesh_fs_params[18].x)), 0, _1557 - 1);\n    return fa_light_texel(param);\n}\n\nivec2 fa_cluster_lookup(vec3 world_pos)\n{\n    vec3 param = world_pos;\n    vec4 _1637 = fa_cluster_texel(param);\n    return ivec2(int(_1637.x), int(_1637.y));\n}\n\nvoid fa_cluster_begin(vec3 world_pos)\n{\n    fa_cl_ndir = int(fa_mesh_fs_params[19].z);\n    vec3 param = world_pos;\n    ivec2 _4464 = fa_cluster_lookup(param);\n    fa_cl_slot = _4464.x;\n    fa_cl_local = _4464.y;\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nvec3 fa_linear_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_tex_fix(inout vec3 c, float mode)\n{\n    if (mode > 1.5)\n    {\n        vec3 param = c;\n        vec3 _5564 = fa_linear_to_srgb(param);\n        c = _5564;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            vec3 param_1 = c;\n            vec3 _5572 = fa_srgb_to_linear(param_1);\n            c = _5572;\n        }\n    }\n    return c;\n}\n\nvec3 fa_tangent_normal(SurfaceInput i, vec3 m)\n{\n    vec3 _431;\n    if (i.front_facing)\n    {\n        _431 = i.world_normal;\n    }\n    else\n    {\n        _431 = -i.world_normal;\n    }\n    vec3 _455 = normalize(i.world_tangent.xyz - (_431 * dot(_431, i.world_tangent.xyz)));\n    vec3 _482 = normalize(((_455 * m.x) + ((cross(_431, _455) * i.world_tangent.w) * m.y)) + (_431 * m.z));\n    vec3 _485;\n    if (i.front_facing)\n    {\n        _485 = _482;\n    }\n    else\n    {\n        _485 = -_482;\n    }\n    return _485;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    vec4 base_t = texture(fa_tex_fa_smp, i.uv);\n    float param = fa_mesh_fs_params[6].w;\n    float param_1 = 1.0;\n    vec3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    vec3 _5603 = fa_tex_fix(param_2, param_3);\n    vec4 _7018 = base_t;\n    _7018.x = _5603.x;\n    _7018.y = _5603.y;\n    _7018.z = _5603.z;\n    base_t = _7018;\n    vec4 _5617 = (_7018 * fa_mesh_fs_params[2]) * i.vertex_color;\n    vec3 _6856 = i.world_normal;\n    if (fa_mesh_fs_params[6].z > 0.5)\n    {\n        float param_4 = fa_mesh_fs_params[6].w;\n        float param_5 = 16.0;\n        vec3 param_6 = texture(fa_normal_tex_fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        vec3 _5649 = fa_tex_fix(param_6, param_7);\n        vec3 _5652 = (_5649 * 2.0) - vec3(1.0);\n        vec2 _5657 = _5652.xy * fa_mesh_fs_params[6].x;\n        vec3 _7026 = _5652;\n        _7026.x = _5657.x;\n        _7026.y = _5657.y;\n        SurfaceInput param_8 = i;\n        vec3 param_9 = _7026;\n        _6856 = fa_tangent_normal(param_8, param_9);\n    }\n    vec4 mrt = texture(fa_mr_tex_fa_smp, i.uv);\n    float param_10 = fa_mesh_fs_params[6].w;\n    float param_11 = 64.0;\n    vec3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    vec3 _5685 = fa_tex_fix(param_12, param_13);\n    vec4 _7029 = mrt;\n    _7029.x = _5685.x;\n    _7029.y = _5685.y;\n    _7029.z = _5685.z;\n    mrt = _7029;\n    vec4 _5713 = texture(fa_occlusion_tex_fa_smp, i.uv);\n    float param_14 = fa_mesh_fs_params[6].w;\n    float param_15 = 256.0;\n    vec3 param_16 = _5713.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    vec3 _5724 = fa_tex_fix(param_16, param_17);\n    float param_18 = fa_mesh_fs_params[6].w;\n    float param_19 = 4.0;\n    vec3 param_20 = texture(fa_emissive_tex_fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    vec3 _5754 = fa_tex_fix(param_20, param_21);\n    float _6861 = fa_mesh_fs_params[20].x;\n    float _6862 = fa_mesh_fs_params[20].y;\n    float _6865 = fa_mesh_fs_params[20].z;\n    float _6864 = fa_mesh_fs_params[21].w;\n    float _6867 = fa_mesh_fs_params[22].x;\n    if (fa_mesh_fs_params[22].z > 0.5)\n    {\n        if (mod(fa_mesh_fs_params[22].z, 2.0) > 0.5)\n        {\n            _6861 *= _5724.y;\n            _6862 *= _5724.z;\n            _6864 *= _5713.w;\n        }\n        if (fa_mesh_fs_params[22].z > 1.5)\n        {\n            _6865 *= mrt.x;\n            _6867 *= mrt.w;\n        }\n    }\n    return Surface(_5617.xyz, _5617.w, _6856, clamp(fa_mesh_fs_params[5].x * _5685.z, 0.0, 1.0), clamp(fa_mesh_fs_params[5].y * _5685.y, 0.0500000007450580596923828125, 1.0), 1.0 + (fa_mesh_fs_params[6].y * (_5724.x - 1.0)), fa_mesh_fs_params[3].xyz + (fa_mesh_fs_params[4].xyz * _5754), _6861, _6862, fa_mesh_fs_params[21].xyz, _6864, _6865, fa_mesh_fs_params[20].w, _6867, fa_mesh_fs_params[22].y, fa_mesh_fs_params[23].xyz);\n}\n\nvoid surface(SurfaceInput i, inout Surface s)\n{\n    s.emission += (i.vertex_color.xyz * points.data[0].tint.w);\n}\n\nvec4 fa_decal_tile(vec4 rect, vec2 uv, vec2 atlas, vec2 ddx, vec2 ddy)\n{\n    vec2 _1717 = rect.zw - rect.xy;\n    vec2 _1721 = _1717 * atlas;\n    vec2 _1725 = ddx * _1721;\n    vec2 _1729 = ddy * _1721;\n    return textureLod(fa_decal_tex_fa_env_smp, rect.xy + (clamp(uv, vec2(0.0), vec2(1.0)) * _1717), clamp(0.5 * log2(max(max(dot(_1725, _1725), dot(_1729, _1729)), 9.9999999392252902907785028219223e-09)), 0.0, 4.0));\n}\n\nvec3 fa_dc_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_dc_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvoid fa_apply_decals(vec3 world_pos, vec3 geo_normal, inout vec3 albedo, inout vec3 normal)\n{\n    bool _1762 = fa_mesh_fs_params[10].y < 0.5;\n    bool _1769;\n    if (!_1762)\n    {\n        _1769 = fa_mesh_fs_params[10].w < 0.5;\n    }\n    else\n    {\n        _1769 = _1762;\n    }\n    if (_1769)\n    {\n        return;\n    }\n    vec3 _1775 = dFdx(world_pos);\n    vec3 _1778 = dFdy(world_pos);\n    vec3 param = world_pos;\n    vec4 _1782 = fa_cluster_texel(param);\n    int _1786 = int(_1782.w);\n    if (_1786 < 1)\n    {\n        return;\n    }\n    int _1796 = int(fa_mesh_fs_params[10].y + 0.5);\n    int param_1 = _1796;\n    vec4 _1800 = fa_light_texel(param_1);\n    vec2 _1803 = _1800.yz;\n    int _1807 = int(_1800.w);\n    int param_2 = _1796 + 1;\n    vec4 _1812 = fa_light_texel(param_2);\n    float _1813 = _1812.x;\n    int _1819 = int(fa_mesh_fs_params[10].w + 0.5) - 1;\n    int _1823 = int(_1782.z);\n    vec3 _2088;\n    for (int k = 0; k < _1786; k++)\n    {\n        int _1836 = _1823 + k;\n        int param_3 = _1807 + (_1836 >> 2);\n        int _1853 = (_1796 + 2) + (int(fa_light_texel(param_3)[_1836 & 3]) * 7);\n        int param_4 = _1853 + 6;\n        vec4 _1858 = fa_light_texel(param_4);\n        if (((int(_1858.w + 0.5) >> _1819) & 1) == 0)\n        {\n            continue;\n        }\n        int param_5 = _1853;\n        vec4 _1873 = fa_light_texel(param_5);\n        int param_6 = _1853 + 1;\n        vec4 _1878 = fa_light_texel(param_6);\n        int param_7 = _1853 + 2;\n        vec4 _1883 = fa_light_texel(param_7);\n        vec3 _1886 = _1873.xyz;\n        float _1891 = dot(_1886, world_pos) + _1873.w;\n        vec3 _1893 = _1878.xyz;\n        float _1898 = dot(_1893, world_pos) + _1878.w;\n        vec3 _1900 = _1883.xyz;\n        float _1905 = dot(_1900, world_pos) + _1883.w;\n        bool _1910 = abs(_1891) > 0.5;\n        bool _1918;\n        if (!_1910)\n        {\n            _1918 = abs(_1898) > 0.5;\n        }\n        else\n        {\n            _1918 = _1910;\n        }\n        bool _1926;\n        if (!_1918)\n        {\n            _1926 = abs(_1905) > 0.5;\n        }\n        else\n        {\n            _1926 = _1918;\n        }\n        if (_1926)\n        {\n            continue;\n        }\n        float _1941 = clamp(dot(geo_normal, normalize(_1900)) * _1858.z, 0.0, 1.0);\n        if (_1941 <= 0.0)\n        {\n            continue;\n        }\n        float _1961 = (clamp((0.5 - abs(_1905)) * 10.0, 0.0, 1.0) * _1941) * _1858.x;\n        vec2 _1969 = vec2(_1891 + 0.5, 0.5 - _1898);\n        vec2 _1979 = vec2(dot(_1886, _1775), dot(_1893, _1775));\n        vec2 _1989 = vec2(dot(_1886, _1778), dot(_1893, _1778));\n        int param_8 = _1853 + 5;\n        vec4 _1994 = fa_light_texel(param_8);\n        int param_9 = _1853 + 3;\n        vec4 _1999 = fa_light_texel(param_9);\n        int param_10 = _1853 + 4;\n        vec4 _2004 = fa_light_texel(param_10);\n        float tex_a = 1.0;\n        vec3 col = _1994.xyz;\n        bool _2014 = _1999.z > _1999.x;\n        if (_2014)\n        {\n            vec4 param_11 = _1999;\n            vec2 param_12 = _1969;\n            vec2 param_13 = _1803;\n            vec2 param_14 = _1979;\n            vec2 param_15 = _1989;\n            vec4 tx = fa_decal_tile(param_11, param_12, param_13, param_14, param_15);\n            if ((_1813 > 0.5) && (_1813 < 1.5))\n            {\n                vec3 param_16 = tx.xyz;\n                vec3 _2040 = fa_dc_to_linear(param_16);\n                vec4 _6936 = tx;\n                _6936.x = _2040.x;\n                _6936.y = _2040.y;\n                _6936.z = _2040.z;\n                tx = _6936;\n            }\n            col *= tx.xyz;\n            tex_a = tx.w;\n        }\n        albedo = mix(albedo, col, vec3(clamp((_1961 * tex_a) * _1994.w, 0.0, 1.0)));\n        if (_2004.z > _2004.x)\n        {\n            vec4 param_17 = _2004;\n            vec2 param_18 = _1969;\n            vec2 param_19 = _1803;\n            vec2 param_20 = _1979;\n            vec2 param_21 = _1989;\n            vec4 _2084 = fa_decal_tile(param_17, param_18, param_19, param_20, param_21);\n            if (_1813 > 1.5)\n            {\n                vec3 param_22 = _2084.xyz;\n                vec3 _2094 = fa_dc_to_srgb(param_22);\n                _2088 = _2094;\n            }\n            else\n            {\n                _2088 = _2084.xyz;\n            }\n            vec3 _2103 = (_2088 * 2.0) - vec3(1.0);\n            vec2 _2108 = _2103.xy * _1858.y;\n            vec3 _2130 = (normalize(_1886) * _2108.x) + (normalize(_1893) * _2108.y);\n            vec3 _2133 = normalize(normal);\n            normal = normalize(mix(_2133, normalize((_2133 * max(_2103.z, 0.0500000007450580596923828125)) + (_2130 - (_2133 * dot(_2133, _2130)))), vec3(clamp(_1961 * (_2014 ? tex_a : 1.0), 0.0, 1.0))));\n        }\n    }\n}\n\nfloat fa_sheen_albedo(float ndv, float rough)\n{\n    float _3571 = min(sqrt(max(rough - 0.100000001490116119384765625, 0.0) * 1.111111164093017578125) * 6.0, 5.999000072479248046875);\n    float _3578 = min(sqrt(clamp(ndv, 0.0, 1.0)) * 8.0, 7.999000072479248046875);\n    int _3581 = int(_3571);\n    int _3584 = int(_3578);\n    float _3594 = _3578 - float(_3584);\n    int _3649 = (_3581 * 9) + _3584;\n    int _3669 = ((_3581 + 1) * 9) + _3584;\n    return mix(mix(_3645[_3649], _3645[_3649 + 1], _3594), mix(_3645[_3669], _3645[_3669 + 1], _3594), _3571 - float(_3581));\n}\n\nFaLayers fa_layers_setup(SurfaceInput i, Surface s, vec3 n, vec3 v, float metallic, float roughness, inout vec3 f0)\n{\n    bool _6779 = false;\n    float _6780 = 1.0;\n    float _6781 = 1.0;\n    float _6782 = 1.0;\n    float _6783 = 0.0;\n    float _6784 = 0.0;\n    float _6785 = 0.0;\n    float _6786 = 0.0;\n    float _6788 = 1.0;\n    bool _6789 = false;\n    vec3 _6790 = vec3(0.0);\n    float _6791 = 1.0;\n    float _6792 = 1.0;\n    float _6793 = 1.0;\n    float _6794 = 0.0;\n    float _6795 = 0.0;\n    vec3 _6796 = vec3(1.0, 0.0, 0.0);\n    vec3 _6797 = vec3(0.0, 0.0, 1.0);\n    float _6798 = 1.0;\n    float _6799 = 1.0;\n    float _3720 = clamp(s.specular, 0.0, 1.0);\n    float _3724 = clamp(s.ior, 1.0, 3.0);\n    bool _3729 = (_3720 != 1.0) || (_3724 != 1.5);\n    bool _3738;\n    if (!_3729)\n    {\n        _3738 = any(notEqual(s.specular_color, vec3(1.0)));\n    }\n    else\n    {\n        _3738 = _3729;\n    }\n    if (_3738)\n    {\n        float _3746 = (_3724 - 1.0) / (_3724 + 1.0);\n        f0 = mix(min(vec3(_3746 * _3746) * max(s.specular_color, vec3(0.0)), vec3(1.0)) * _3720, s.albedo, vec3(metallic));\n        _6780 = mix(_3720, 1.0, metallic);\n        _6779 = true;\n    }\n    float _3773 = clamp(s.clearcoat, 0.0, 1.0);\n    if (_3773 > 0.0)\n    {\n        float _3781 = clamp(s.clearcoat_roughness, 0.0500000007450580596923828125, 1.0);\n        _6783 = _3773;\n        _6784 = _3781;\n        float _3788 = _3781 * _3781;\n        _6785 = _3788;\n        _6786 = _3788 * _3788;\n        float _3800 = max(dot(i.world_normal, v), 9.9999997473787516355514526367188e-05);\n        _6788 = _3800;\n        _6781 = 1.0 - (_3773 * (0.039999999105930328369140625 + (0.959999978542327880859375 * pow(clamp(1.0 - _3800, 0.0, 1.0), 5.0))));\n        _6779 = true;\n    }\n    vec3 _3819 = max(s.sheen_color, vec3(0.0));\n    float _3828 = max(_3819.x, max(_3819.y, _3819.z));\n    if (_3828 > 0.0)\n    {\n        float _3836 = clamp(s.sheen_roughness, 0.100000001490116119384765625, 1.0);\n        _6789 = true;\n        _6790 = _3819;\n        _6791 = _3836;\n        _6792 = _3836 * _3836;\n        float param = max(dot(n, v), 9.9999997473787516355514526367188e-05);\n        float param_1 = _3836;\n        float _3853 = fa_sheen_albedo(param, param_1);\n        _6794 = _3853;\n        _6793 = 1.0 - min(_3828 * _3853, 1.0);\n        _6779 = true;\n    }\n    _6782 = _6781 * _6793;\n    float _3872 = clamp(s.anisotropy, -1.0, 1.0);\n    if (_3872 != 0.0)\n    {\n        vec3 _3887 = i.world_tangent.xyz - (n * dot(n, i.world_tangent.xyz));\n        vec3 t = _3887;\n        if (dot(_3887, _3887) < 9.9999999392252902907785028219223e-09)\n        {\n            bvec3 _3899 = bvec3(abs(n.y) < 0.9900000095367431640625);\n            t = cross(vec3(_3899.x ? vec3(0.0, 1.0, 0.0).x : vec3(1.0, 0.0, 0.0).x, _3899.y ? vec3(0.0, 1.0, 0.0).y : vec3(1.0, 0.0, 0.0).y, _3899.z ? vec3(0.0, 1.0, 0.0).z : vec3(1.0, 0.0, 0.0).z), n);\n        }\n        vec3 _3903 = t;\n        vec3 _3904 = normalize(_3903);\n        t = _3904;\n        vec3 _3929 = normalize((_3904 * cos(s.anisotropy_rotation)) + ((cross(n, _3904) * ((i.world_tangent.w < 0.0) ? (-1.0) : 1.0)) * sin(s.anisotropy_rotation)));\n        _6796 = _3929;\n        _6797 = cross(n, _3929);\n        float _3939 = roughness * roughness;\n        float _3945 = mix(_3939, 1.0, _3872 * _3872);\n        bool _3947 = _3872 > 0.0;\n        _6798 = _3947 ? _3945 : _3939;\n        _6799 = _3947 ? _3939 : _3945;\n        _6795 = _3872;\n        _6779 = true;\n    }\n    return FaLayers(_6779, _6780, _6781, _6782, _6783, _6784, _6785, _6786, i.world_normal, _6788, _6789, _6790, _6791, _6792, _6793, _6794, _6795, _6796, _6797, _6798, _6799);\n}\n\nvec3 fa_sky_sh_coef(int k)\n{\n    vec3 v = textureLod(fa_env_tex_fa_env_smp, vec3(1.0, 1.0 - (float((2 * (k >> 2)) + 1) * 0.25), 1.0 - (float((2 * (k & 3)) + 1) * 0.25)), 5.0).xyz;\n    if (fa_mesh_fs_params[11].w > 1.5)\n    {\n        v = (v - vec3(0.5)) * 8.0;\n    }\n    return v;\n}\n\nvec3 fa_sh_eval(vec3 c[9], vec3 n)\n{\n    vec3 _3328 = max((((c[0] * 0.2820948064327239990234375) + (((c[1] * (0.3257350027561187744140625 * n.y)) + (c[2] * (0.3257350027561187744140625 * n.z))) + (c[3] * (0.3257350027561187744140625 * n.x)))) + (((c[4] * ((0.2731371223926544189453125 * n.x) * n.y)) + (c[5] * ((0.2731371223926544189453125 * n.y) * n.z))) + (c[6] * (0.078847892582416534423828125 * (((3.0 * n.z) * n.z) - 1.0))))) + ((c[7] * ((0.2731371223926544189453125 * n.x) * n.z)) + (c[8] * (0.13656856119632720947265625 * ((n.x * n.x) - (n.y * n.y))))), vec3(0.0));\n    return _3328;\n}\n\nvec3 fa_ambient_light(vec3 n)\n{\n    if (fa_mesh_fs_params[11].w > 0.5)\n    {\n        vec3 c[9];\n        for (int k = 0; k < 9; k++)\n        {\n            int param = k;\n            c[k] = fa_sky_sh_coef(param);\n        }\n        vec3 param_1[9] = c;\n        vec3 param_2 = n;\n        return fa_sh_eval(param_1, param_2);\n    }\n    return fa_mesh_fs_params[1].xyz;\n}\n\nvec3 fa_indirect_diffuse(vec3 n)\n{\n    if (fa_lm.z > 0.5)\n    {\n        return textureLod(fa_lightmap_fa_env_smp, fa_lm.xy, 0.0).xyz;\n    }\n    vec3 param = n;\n    return fa_ambient_light(param);\n}\n\nint fa_cluster_index(int slot, int n)\n{\n    int param = (int(fa_mesh_fs_params[19].x) + int(fa_mesh_fs_params[19].w)) + ((slot + n) >> 2);\n    vec4 t = fa_light_texel(param);\n    return int(t[(slot + n) & 3]);\n}\n\nint fa_cl_light(int n)\n{\n    if (n < fa_cl_ndir)\n    {\n        return n;\n    }\n    int param = fa_cl_slot;\n    int param_1 = n - fa_cl_ndir;\n    return fa_cluster_index(param, param_1);\n}\n\nint fa_light_base(int li)\n{\n    return li * ((fa_mesh_fs_params[1].w > 4.5) ? 8 : 4);\n}\n\nbool fa_light_baked(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 3;\n    return fa_light_texel(param_1).w > 0.5;\n}\n\nfloat fa_light_type(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 1;\n    return fa_light_texel(param_1).w;\n}\n\nvec4 fa_atlas_fetch(vec2 texel)\n{\n    return textureLod(fa_light_atlas_fa_env_smp, texel / vec2(textureSize(fa_light_atlas_fa_env_smp, 0)), 0.0);\n}\n\nvec3 fa_cookie_sample(vec2 tile_origin, vec2 uv)\n{\n    vec2 param = (tile_origin + vec2(1.0)) + (clamp(uv, vec2(0.0), vec2(1.0)) * 254.0);\n    return fa_atlas_fetch(param).xyz;\n}\n\nvec3 fa_area_point(vec3 c, vec3 axis, vec3 ru, vec3 uu, float hx, float hy, float shape, vec3 p, vec3 r)\n{\n    bool _735 = dot(r, r) > 0.5;\n    if (shape > 1.5)\n    {\n        vec3 _748 = (c - (ru * hx)) - p;\n        vec3 _754 = ru * (2.0 * hx);\n        float _760 = max(dot(_754, _754), 9.9999999392252902907785028219223e-09);\n        float _764 = dot(_748, _754);\n        float t = clamp((-_764) / _760, 0.0, 1.0);\n        if (_735)\n        {\n            float _779 = dot(r, _754);\n            float _785 = _760 - (_779 * _779);\n            if (abs(_785) > (9.9999997473787516355514526367188e-06 * _760))\n            {\n                t = clamp(((dot(r, _748) * _779) - _764) / _785, 0.0, 1.0);\n            }\n        }\n        return (p + _748) + (_754 * t);\n    }\n    vec3 q = p;\n    float _817 = dot(r, axis);\n    bool _825;\n    if (_735)\n    {\n        _825 = abs(_817) > 9.9999997473787516355514526367188e-05;\n    }\n    else\n    {\n        _825 = _735;\n    }\n    if (_825)\n    {\n        float _835 = dot(c - p, axis) / _817;\n        if (_835 > 0.0)\n        {\n            q = p + (r * _835);\n        }\n    }\n    vec3 _848 = q - c;\n    vec2 xy = vec2(dot(_848, ru), dot(_848, uu));\n    if (shape > 0.5)\n    {\n        float _863 = length(xy);\n        if (_863 > hx)\n        {\n            xy *= (hx / _863);\n        }\n    }\n    else\n    {\n        xy = clamp(xy, vec2(-hx, -hy), vec2(hx, hy));\n    }\n    return (c + (ru * xy.x)) + (uu * xy.y);\n}\n\nint fa_cube_face(vec3 d)\n{\n    vec3 _497 = abs(d);\n    float _499 = _497.x;\n    float _501 = _497.y;\n    bool _502 = _499 >= _501;\n    bool _510;\n    if (_502)\n    {\n        _510 = _499 >= _497.z;\n    }\n    else\n    {\n        _510 = _502;\n    }\n    int _511;\n    if (_510)\n    {\n        _511 = (d.x > 0.0) ? 0 : 1;\n    }\n    else\n    {\n        int _526;\n        if (_501 >= _497.z)\n        {\n            _526 = (d.y > 0.0) ? 2 : 3;\n        }\n        else\n        {\n            _526 = (d.z > 0.0) ? 4 : 5;\n        }\n        _511 = _526;\n    }\n    return _511;\n}\n\nvoid fa_cube_face_basis(int f, out vec3 fwd, out vec3 up)\n{\n    if (f == 0)\n    {\n        fwd = vec3(1.0, 0.0, 0.0);\n        up = vec3(0.0, 1.0, 0.0);\n    }\n    else\n    {\n        if (f == 1)\n        {\n            fwd = vec3(-1.0, 0.0, 0.0);\n            up = vec3(0.0, 1.0, 0.0);\n        }\n        else\n        {\n            if (f == 2)\n            {\n                fwd = vec3(0.0, 1.0, 0.0);\n                up = vec3(0.0, 0.0, 1.0);\n            }\n            else\n            {\n                if (f == 3)\n                {\n                    fwd = vec3(0.0, -1.0, 0.0);\n                    up = vec3(0.0, 0.0, -1.0);\n                }\n                else\n                {\n                    if (f == 4)\n                    {\n                        fwd = vec3(0.0, 0.0, 1.0);\n                        up = vec3(0.0, 1.0, 0.0);\n                    }\n                    else\n                    {\n                        fwd = vec3(0.0, 0.0, -1.0);\n                        up = vec3(0.0, 1.0, 0.0);\n                    }\n                }\n            }\n        }\n    }\n}\n\nfloat fa_ies_sample(vec2 tile_origin, vec3 d, vec3 axis, vec3 right, vec3 up)\n{\n    float _655 = dot(d, right);\n    float _659 = dot(d, up);\n    float _670;\n    if (((_655 * _655) + (_659 * _659)) > 1.0000000133514319600180897396058e-10)\n    {\n        _670 = atan(_659, _655) * 0.15915493667125701904296875;\n    }\n    else\n    {\n        _670 = 0.0;\n    }\n    vec2 param = tile_origin + vec2(1.0 + ((_670 - floor(_670)) * 64.0), 1.0 + (acos(clamp(dot(d, axis), -1.0, 1.0)) * 10.18591594696044921875));\n    return fa_atlas_fetch(param).x;\n}\n\nLightSample fa_light_sample_n(int li, vec3 world_pos, vec3 n)\n{\n    int param = li;\n    int _901 = fa_light_base(param);\n    bool _905 = fa_mesh_fs_params[1].w > 4.5;\n    int param_1 = _901;\n    vec4 _909 = fa_light_texel(param_1);\n    int param_2 = _901 + 1;\n    vec4 _914 = fa_light_texel(param_2);\n    float _917 = _914.w;\n    float atten = 1.0;\n    float dist = 0.0;\n    fa_light_tint = vec3(1.0);\n    bool _929 = _905 && (_917 > 2.5);\n    fa_light_is_area = _929;\n    bool _931 = _917 < 0.5;\n    vec3 l;\n    if (_931)\n    {\n        l = normalize(_909.xyz);\n        if (_905)\n        {\n            int param_3 = _901 + 6;\n            vec4 _945 = fa_light_texel(param_3);\n            if (_945.z > 0.5)\n            {\n                int param_4 = _901 + 4;\n                vec4 _955 = fa_light_texel(param_4);\n                int param_5 = _901 + 5;\n                vec4 _960 = fa_light_texel(param_5);\n                vec2 param_6 = _945.xy;\n                vec2 param_7 = fract(vec2(dot(world_pos, _955.xyz) * _955.w, (-dot(world_pos, _960.xyz)) * _960.w) + vec2(0.5));\n                fa_light_tint = fa_cookie_sample(param_6, param_7);\n            }\n        }\n    }\n    else\n    {\n        vec3 _990 = _909.xyz;\n        vec3 _992 = _990 - world_pos;\n        vec3 to_light = _992;\n        float _995 = length(_992);\n        float reach = _995;\n        bool front = true;\n        if (_929)\n        {\n            int param_8 = _901 + 7;\n            reach = max(_995 - fa_light_texel(param_8).w, 0.0);\n            int param_9 = _901 + 4;\n            vec4 _1019 = fa_light_texel(param_9);\n            int param_10 = _901 + 5;\n            vec4 _1024 = fa_light_texel(param_10);\n            int param_11 = _901 + 6;\n            vec4 _1029 = fa_light_texel(param_11);\n            float _1030 = _1029.w;\n            int param_12 = _901 + 2;\n            vec3 _1037 = normalize(fa_light_texel(param_12).xyz);\n            bool _1039 = _1030 > 1.5;\n            bool _1047;\n            if (!_1039)\n            {\n                _1047 = dot(_1037, to_light) < 0.0;\n            }\n            else\n            {\n                _1047 = _1039;\n            }\n            front = _1047;\n            vec3 r = vec3(0.0);\n            vec3 _1056 = fa_mesh_fs_params[0].xyz - world_pos;\n            bool _1060 = dot(n, n) > 0.5;\n            bool _1068;\n            if (_1060)\n            {\n                _1068 = dot(_1056, _1056) > 9.9999999600419720025001879548654e-13;\n            }\n            else\n            {\n                _1068 = _1060;\n            }\n            if (_1068)\n            {\n                r = reflect(-normalize(_1056), normalize(n));\n            }\n            vec3 param_13 = _990;\n            vec3 param_14 = _1037;\n            vec3 param_15 = _1019.xyz;\n            vec3 param_16 = _1024.xyz;\n            float param_17 = _1019.w;\n            float param_18 = _1024.w;\n            float param_19 = _1030;\n            vec3 param_20 = world_pos;\n            vec3 param_21 = r;\n            to_light = fa_area_point(param_13, param_14, param_15, param_16, param_17, param_18, param_19, param_20, param_21) - world_pos;\n        }\n        float _1104 = length(to_light);\n        dist = _1104;\n        l = to_light / vec3(max(_1104, 9.9999997473787516355514526367188e-05));\n        float _1118 = reach / max(_909.w, 0.001000000047497451305389404296875);\n        float _1124 = clamp(1.0 - (_1118 * _1118), 0.0, 1.0);\n        float _1126;\n        if (front)\n        {\n            _1126 = _1124 * _1124;\n        }\n        else\n        {\n            _1126 = 0.0;\n        }\n        atten = _1126;\n        bool _1137 = _917 < 2.5;\n        if ((_917 > 1.5) && _1137)\n        {\n            int param_22 = _901 + 2;\n            vec4 _1145 = fa_light_texel(param_22);\n            float _1155 = _1145.w;\n            int param_23 = _901 + 3;\n            vec4 _1160 = fa_light_texel(param_23);\n            float _1161 = _1160.x;\n            float cos_inner = _1161;\n            if (_1161 > 1.5)\n            {\n                cos_inner = mix(_1155, 1.0, 0.25);\n            }\n            atten *= smoothstep(_1155, cos_inner, dot(-l, normalize(_1145.xyz)));\n        }\n        if (_905 && (_917 < 1.5))\n        {\n            int param_24 = _901 + 6;\n            vec4 _1185 = fa_light_texel(param_24);\n            if (_1185.z > 0.5)\n            {\n                vec3 _1193 = -to_light;\n                int param_25 = _901 + 4;\n                int param_26 = _901 + 5;\n                vec3 _1207 = fa_light_texel(param_25).xyz;\n                vec3 _1211 = fa_light_texel(param_26).xyz;\n                vec3 _1220 = vec3(dot(_1193, _1207), dot(_1193, _1211), dot(_1193, cross(_1207, _1211)));\n                vec3 param_27 = _1220;\n                int _1224 = fa_cube_face(param_27);\n                int param_28 = _1224;\n                vec3 param_29;\n                vec3 param_30;\n                fa_cube_face_basis(param_28, param_29, param_30);\n                vec2 _1251 = vec2(dot(_1220, cross(param_29, param_30)), dot(_1220, param_30)) / vec2(max(dot(_1220, param_29), 9.9999997473787516355514526367188e-05));\n                int _1255 = _1224 / 3;\n                vec2 param_31 = _1185.xy + (vec2(float(_1224 - (_1255 * 3)), float(_1255)) * 256.0);\n                vec2 param_32 = vec2(0.5 + (0.5 * _1251.x), 0.5 - (0.5 * _1251.y));\n                fa_light_tint = fa_cookie_sample(param_31, param_32);\n            }\n            int param_33 = _901 + 7;\n            vec4 _1285 = fa_light_texel(param_33);\n            if (_1285.z > 0.5)\n            {\n                int param_34 = _901 + 2;\n                int param_35 = _901 + 4;\n                int param_36 = _901 + 5;\n                vec2 param_37 = _1285.xy;\n                vec3 param_38 = -l;\n                vec3 param_39 = normalize(fa_light_texel(param_34).xyz);\n                vec3 param_40 = fa_light_texel(param_35).xyz;\n                vec3 param_41 = fa_light_texel(param_36).xyz;\n                atten *= fa_ies_sample(param_37, param_38, param_39, param_40, param_41);\n            }\n        }\n        else\n        {\n            if (_905 && _1137)\n            {\n                int param_42 = _901 + 6;\n                vec4 _1332 = fa_light_texel(param_42);\n                int param_43 = _901 + 7;\n                vec4 _1337 = fa_light_texel(param_43);\n                bool _1340 = _1332.z > 0.5;\n                bool _1347;\n                if (!_1340)\n                {\n                    _1347 = _1337.z > 0.5;\n                }\n                else\n                {\n                    _1347 = _1340;\n                }\n                if (_1347)\n                {\n                    int param_44 = _901 + 2;\n                    vec4 _1354 = fa_light_texel(param_44);\n                    vec3 _1358 = normalize(_1354.xyz);\n                    int param_45 = _901 + 4;\n                    vec4 _1363 = fa_light_texel(param_45);\n                    int param_46 = _901 + 5;\n                    vec4 _1368 = fa_light_texel(param_46);\n                    if (_1340)\n                    {\n                        vec3 _1376 = -to_light;\n                        float _1383 = _1354.w;\n                        float _1399 = 0.5 / max(dot(_1376, _1358) * (sqrt(max(1.0 - (_1383 * _1383), 0.0)) / max(_1383, 0.001000000047497451305389404296875)), 9.9999997473787516355514526367188e-05);\n                        vec2 param_47 = _1332.xy;\n                        vec2 param_48 = vec2(0.5 + (dot(_1376, _1363.xyz) * _1399), 0.5 - (dot(_1376, _1368.xyz) * _1399));\n                        fa_light_tint = fa_cookie_sample(param_47, param_48);\n                    }\n                    if (_1337.z > 0.5)\n                    {\n                        vec2 param_49 = _1337.xy;\n                        vec3 param_50 = -l;\n                        vec3 param_51 = _1358;\n                        vec3 param_52 = _1363.xyz;\n                        vec3 param_53 = _1368.xyz;\n                        atten *= fa_ies_sample(param_49, param_50, param_51, param_52, param_53);\n                    }\n                }\n            }\n        }\n    }\n    vec3 _6767 = _914.xyz * atten;\n    if (_905)\n    {\n        _6767 *= fa_light_tint;\n    }\n    int _1468;\n    if (_931)\n    {\n        _1468 = 0;\n    }\n    else\n    {\n        _1468 = ((_917 > 1.5) && (_917 < 2.5)) ? 2 : 1;\n    }\n    return LightSample(l, _6767, atten, 1.0, dist, _1468);\n}\n\nfloat fa_shadow_split_at(int i)\n{\n    float _2205;\n    if (i == 0)\n    {\n        _2205 = fa_shadows[24].x;\n    }\n    else\n    {\n        float _2221;\n        if (i == 1)\n        {\n            _2221 = fa_shadows[24].y;\n        }\n        else\n        {\n            float _2229;\n            if (i == 2)\n            {\n                _2229 = fa_shadows[24].z;\n            }\n            else\n            {\n                _2229 = fa_shadows[24].w;\n            }\n            _2221 = _2229;\n        }\n        _2205 = _2221;\n    }\n    return _2205;\n}\n\nfloat fa_shadow_depth(inout vec2 uv, vec4 rect)\n{\n    uv = clamp(uv, rect.xy, rect.zw);\n    return textureLod(fa_shadow_tex_fa_shadow_smp, uv, 0.0).x;\n}\n\nfloat fa_shadow_fetch(vec2 uv, vec4 rect, vec3 conv)\n{\n    vec2 param = uv;\n    vec4 param_1 = rect;\n    float _2262 = fa_shadow_depth(param, param_1);\n    float _2266;\n    if (conv.x < 0.5)\n    {\n        _2266 = _2262;\n    }\n    else\n    {\n        _2266 = (conv.y * conv.z) / (conv.z - (_2262 * (conv.z - conv.y)));\n    }\n    return _2266;\n}\n\nfloat fa_shadow_noise()\n{\n    return fract(52.98291778564453125 * fract(dot(gl_FragCoord.xy, vec2(0.067110560834407806396484375, 0.005837149918079376220703125))));\n}\n\nvec2 fa_shadow_vogel(int k, int n, float phi)\n{\n    float _2193 = (float(k) * 2.3999631404876708984375) + phi;\n    return vec2(cos(_2193), sin(_2193)) * sqrt((float(k) + 0.5) / float(n));\n}\n\nfloat fa_shadow_filter(vec2 uv, vec4 rect, float zr, float texel_m, float unit, float reach, float plane, vec3 conv, int mode, float k)\n{\n    if (mode == 1)\n    {\n        vec2 param = uv;\n        vec4 param_1 = rect;\n        vec3 param_2 = conv;\n        return float(zr <= fa_shadow_fetch(param, param_1, param_2));\n    }\n    float _2312 = fa_shadow_noise() * 6.283185482025146484375;\n    float radius = 1.5;\n    if (mode == 2)\n    {\n        float _2321;\n        if (k < 0.0)\n        {\n            _2321 = (-k) / max(zr, 0.100000001490116119384765625);\n        }\n        else\n        {\n            _2321 = k;\n        }\n        float _2341 = clamp((_2321 * reach) / texel_m, 3.0, 12.0);\n        float sum = 0.0;\n        float cnt = 0.0;\n        for (int i = 0; i < 16; i++)\n        {\n            int param_3 = i;\n            int param_4 = 16;\n            float param_5 = _2312;\n            vec2 _2360 = fa_shadow_vogel(param_3, param_4, param_5) * _2341;\n            vec2 param_6 = uv + (_2360 * fa_shadows[26].zw);\n            vec4 param_7 = rect;\n            vec3 param_8 = conv;\n            float _2372 = fa_shadow_fetch(param_6, param_7, param_8);\n            if (_2372 < (zr - (length(_2360) * plane)))\n            {\n                sum += _2372;\n                cnt += 1.0;\n            }\n        }\n        if (cnt < 0.5)\n        {\n            return 1.0;\n        }\n        float _2398 = sum / cnt;\n        float _2408;\n        if (k < 0.0)\n        {\n            _2408 = (-k) / max(_2398, 0.0500000007450580596923828125);\n        }\n        else\n        {\n            _2408 = k;\n        }\n        radius = clamp(((max(zr - _2398, 0.0) * unit) * _2408) / texel_m, 1.5, 16.0);\n    }\n    float lit = 0.0;\n    int _2430 = (mode == 2) ? 24 : 16;\n    for (int i_1 = 0; i_1 < _2430; i_1++)\n    {\n        int param_9 = i_1;\n        int param_10 = _2430;\n        float param_11 = _2312;\n        vec2 _2449 = fa_shadow_vogel(param_9, param_10, param_11) * radius;\n        vec2 param_12 = uv + (_2449 * fa_shadows[26].zw);\n        vec4 param_13 = rect;\n        vec3 param_14 = conv;\n        lit += float((zr - (length(_2449) * plane)) <= fa_shadow_fetch(param_12, param_13, param_14));\n    }\n    return lit / float(_2430);\n}\n\nfloat fa_shadow_cascade(int ci, vec3 world, vec3 n, vec3 l)\n{\n    float _2491 = max(fa_shadows[ci * 1 + 20].y, 0.001000000047497451305389404296875);\n    float _2496 = clamp(dot(n, l), 0.0, 1.0);\n    float _2502 = sqrt(1.0 - (_2496 * _2496));\n    float _2509 = min(_2502 / max(_2496, 0.20000000298023223876953125), 4.0);\n    float _2514;\n    if (fa_shadows[26].y > 0.0)\n    {\n        _2514 = fa_shadows[26].y;\n    }\n    else\n    {\n        _2514 = 1.5 * fa_shadows[ci * 1 + 20].x;\n    }\n    vec4 _2539 = mat4(fa_shadows[ci * 4 + 0], fa_shadows[ci * 4 + 1], fa_shadows[ci * 4 + 2], fa_shadows[ci * 4 + 3]) * vec4(world + (n * (_2514 * _2502)), 1.0);\n    float _2546 = _2539.x;\n    bool _2549 = _2546 < fa_shadows[ci * 1 + 16].x;\n    bool _2558;\n    if (!_2549)\n    {\n        _2558 = _2546 > fa_shadows[ci * 1 + 16].z;\n    }\n    else\n    {\n        _2558 = _2549;\n    }\n    bool _2567;\n    if (!_2558)\n    {\n        _2567 = _2539.y < fa_shadows[ci * 1 + 16].y;\n    }\n    else\n    {\n        _2567 = _2558;\n    }\n    bool _2576;\n    if (!_2567)\n    {\n        _2576 = _2539.y > fa_shadows[ci * 1 + 16].w;\n    }\n    else\n    {\n        _2576 = _2567;\n    }\n    bool _2583;\n    if (!_2576)\n    {\n        _2583 = _2539.z > 1.0;\n    }\n    else\n    {\n        _2583 = _2576;\n    }\n    if (_2583)\n    {\n        return -1.0;\n    }\n    float _2591;\n    if (fa_shadows[26].x > 0.0)\n    {\n        _2591 = fa_shadows[26].x;\n    }\n    else\n    {\n        _2591 = 1.5 * fa_shadows[ci * 1 + 20].x;\n    }\n    vec2 param = _2539.xy;\n    vec4 param_1 = fa_shadows[ci * 1 + 16];\n    float param_2 = _2539.z - ((_2591 * (1.0 + (0.5 * _2509))) / _2491);\n    float param_3 = fa_shadows[ci * 1 + 20].x;\n    float param_4 = _2491;\n    float param_5 = _2491 * 0.25;\n    float param_6 = ((fa_shadows[ci * 1 + 20].x * min(_2509, 3.0)) * 0.5) / _2491;\n    vec3 param_7 = vec3(0.0);\n    int param_8 = int(fa_shadows[25].z + 0.5);\n    float param_9 = fa_shadows[25].w;\n    return fa_shadow_filter(param, param_1, param_2, param_3, param_4, param_5, param_6, param_7, param_8, param_9);\n}\n\nfloat fa_shadow_sun(vec3 world, vec3 n, vec3 l)\n{\n    if (fa_mesh_fs_params[5].z < 0.5)\n    {\n        return 1.0;\n    }\n    int _2969 = int(fa_shadows[25].x + 0.5);\n    if (_2969 < 1)\n    {\n        return 1.0;\n    }\n    float _2984 = dot(world - fa_shadows[27].xyz, fa_shadows[28].xyz);\n    int param = _2969 - 1;\n    if (_2984 > fa_shadow_split_at(param))\n    {\n        return 1.0;\n    }\n    int ci = 0;\n    bool _2996 = _2969 > 1;\n    bool _3003;\n    if (_2996)\n    {\n        _3003 = _2984 > fa_shadows[24].x;\n    }\n    else\n    {\n        _3003 = _2996;\n    }\n    if (_3003)\n    {\n        ci = 1;\n    }\n    bool _3007 = _2969 > 2;\n    bool _3014;\n    if (_3007)\n    {\n        _3014 = _2984 > fa_shadows[24].y;\n    }\n    else\n    {\n        _3014 = _3007;\n    }\n    if (_3014)\n    {\n        ci = 2;\n    }\n    bool _3018 = _2969 > 3;\n    bool _3025;\n    if (_3018)\n    {\n        _3025 = _2984 > fa_shadows[24].z;\n    }\n    else\n    {\n        _3025 = _3018;\n    }\n    if (_3025)\n    {\n        ci = 3;\n    }\n    float s = -1.0;\n    for (int k = 0; k < 4; k++)\n    {\n        if (ci >= _2969)\n        {\n            break;\n        }\n        int param_1 = ci;\n        vec3 param_2 = world;\n        vec3 param_3 = n;\n        vec3 param_4 = l;\n        float _3051 = fa_shadow_cascade(param_1, param_2, param_3, param_4);\n        s = _3051;\n        if (_3051 >= 0.0)\n        {\n            break;\n        }\n        ci++;\n    }\n    if (s < 0.0)\n    {\n        return 1.0;\n    }\n    if (fa_shadows[25].y > 0.0)\n    {\n        float _3076;\n        if (ci > 0)\n        {\n            int param_5 = ci - 1;\n            _3076 = fa_shadow_split_at(param_5);\n        }\n        else\n        {\n            _3076 = fa_shadows[28].w;\n        }\n        int param_6 = ci;\n        float _3095 = fa_shadows[25].y * max(fa_shadow_split_at(param_6) - _3076, 9.9999997473787516355514526367188e-05);\n        int param_7 = ci;\n        float _3106 = clamp((_2984 - (fa_shadow_split_at(param_7) - _3095)) / _3095, 0.0, 1.0);\n        if (_3106 > 0.0)\n        {\n            float s2 = 1.0;\n            if ((ci + 1) < _2969)\n            {\n                int param_8 = ci + 1;\n                vec3 param_9 = world;\n                vec3 param_10 = n;\n                vec3 param_11 = l;\n                float _3127 = fa_shadow_cascade(param_8, param_9, param_10, param_11);\n                s2 = _3127;\n                if (_3127 < 0.0)\n                {\n                    s2 = s;\n                }\n            }\n            s = mix(s, s2, _3106);\n        }\n    }\n    return s;\n}\n\nfloat fa_shadow_factor(vec3 n, vec3 l)\n{\n    vec3 param = fa_world_pos;\n    vec3 param_1 = n;\n    vec3 param_2 = l;\n    return fa_shadow_sun(param, param_1, param_2);\n}\n\nfloat fa_shadow_local(int li, vec3 lpos, vec3 world, vec3 n, vec3 l)\n{\n    bool _2649 = fa_mesh_fs_params[5].z < 0.5;\n    bool _2656;\n    if (!_2649)\n    {\n        _2656 = fa_shadows[29].x < 0.5;\n    }\n    else\n    {\n        _2656 = _2649;\n    }\n    if (_2656)\n    {\n        return 1.0;\n    }\n    int param = (int(fa_shadows[29].x + 0.5) - 1) + li;\n    vec4 _2669 = fa_light_texel(param);\n    float _2670 = _2669.x;\n    if (_2670 < 0.0)\n    {\n        return 1.0;\n    }\n    int _2679 = int(_2670 + 0.5);\n    int param_1 = _2679;\n    vec4 _2683 = fa_light_texel(param_1);\n    int param_2 = _2679 + 1;\n    vec4 _2688 = fa_light_texel(param_2);\n    float fade = 1.0;\n    float _2691 = _2683.y;\n    if (_2691 > 0.0)\n    {\n        float _2708 = 1.0 - smoothstep(0.75 * _2691, _2691, length(world - fa_shadows[27].xyz));\n        fade = _2708;\n        if (_2708 <= 0.0)\n        {\n            return 1.0;\n        }\n    }\n    int face = 0;\n    if (_2683.x > 1.5)\n    {\n        vec3 param_3 = world - lpos;\n        face = fa_cube_face(param_3);\n    }\n    int _2732 = (_2679 + 2) + (face * 6);\n    int param_4 = _2732;\n    int param_5 = _2732 + 1;\n    int param_6 = _2732 + 3;\n    vec4 _2746 = fa_light_texel(param_6);\n    int param_7 = _2732 + 4;\n    vec4 _2751 = fa_light_texel(param_7);\n    int param_8 = _2732 + 5;\n    vec4 _2756 = fa_light_texel(param_8);\n    float _2768 = _2756.x * max(dot(_2746, vec4(world, 1.0)), 0.001000000047497451305389404296875);\n    float _2773 = clamp(dot(n, l), 0.0, 1.0);\n    float _2796 = clamp(dot(n, _2746.xyz), -1.0, 1.0);\n    float _2815 = min(sqrt(1.0 - (_2796 * _2796)) / max(abs(dot(n, world - lpos)) / max(dot(_2746, vec4(world, 1.0)), 0.001000000047497451305389404296875), 0.20000000298023223876953125), 4.0);\n    float _2818 = _2688.y;\n    float _2820;\n    if (_2818 > 0.0)\n    {\n        _2820 = _2818;\n    }\n    else\n    {\n        _2820 = 1.5 * _2768;\n    }\n    vec4 _2840 = vec4(world + (n * (_2820 * sqrt(1.0 - (_2773 * _2773)))), 1.0);\n    float _2844 = dot(_2746, _2840);\n    float _2847 = _2756.y;\n    if (_2844 < _2847)\n    {\n        return 1.0;\n    }\n    vec2 _2862 = vec2(dot(fa_light_texel(param_4), _2840), dot(fa_light_texel(param_5), _2840)) / vec2(_2844);\n    float _2864 = _2862.x;\n    bool _2867 = _2864 < _2751.x;\n    bool _2876;\n    if (!_2867)\n    {\n        _2876 = _2864 > _2751.z;\n    }\n    else\n    {\n        _2876 = _2867;\n    }\n    bool _2885;\n    if (!_2876)\n    {\n        _2885 = _2862.y < _2751.y;\n    }\n    else\n    {\n        _2885 = _2876;\n    }\n    bool _2894;\n    if (!_2885)\n    {\n        _2894 = _2862.y > _2751.w;\n    }\n    else\n    {\n        _2894 = _2885;\n    }\n    if (_2894)\n    {\n        return 1.0;\n    }\n    float _2900 = _2688.x;\n    float _2902;\n    if (_2900 > 0.0)\n    {\n        _2902 = _2900;\n    }\n    else\n    {\n        _2902 = 1.5 * _2768;\n    }\n    vec2 param_9 = _2862;\n    vec4 param_10 = _2751;\n    float param_11 = _2844 - (_2902 * (1.0 + (0.5 * _2815)));\n    float param_12 = _2768;\n    float param_13 = 1.0;\n    float param_14 = _2756.z * 0.25;\n    float param_15 = (_2768 * min(_2815, 3.0)) * 0.5;\n    vec3 param_16 = vec3(1.0, _2847, _2756.z);\n    int param_17 = int(_2683.z + 0.5);\n    float param_18 = _2683.w;\n    return mix(1.0, fa_shadow_filter(param_9, param_10, param_11, param_12, param_13, param_14, param_15, param_16, param_17, param_18), fade);\n}\n\nLightSample fa_light_shadowed(int li, vec3 world_pos, vec3 gn)\n{\n    bool _4491 = fa_lm.z > 0.5;\n    bool _4497;\n    if (_4491)\n    {\n        int param = li;\n        _4497 = fa_light_baked(param);\n    }\n    else\n    {\n        _4497 = _4491;\n    }\n    if (_4497)\n    {\n        int param_1 = li;\n        return LightSample(vec3(0.0, 1.0, 0.0), vec3(0.0), 0.0, 1.0, 0.0, int(fa_light_type(param_1) + 0.5));\n    }\n    int param_2 = li;\n    vec3 param_3 = world_pos;\n    vec3 param_4 = gn;\n    LightSample _4521 = fa_light_sample_n(param_2, param_3, param_4);\n    vec3 _6836 = _4521.color;\n    float _6838 = _4521.shadow;\n    if ((_4521.type == 0) && (li == 0))\n    {\n        vec3 param_5 = gn;\n        vec3 param_6 = _4521.direction;\n        float _4535 = fa_shadow_factor(param_5, param_6);\n        _6838 = _4535;\n        _6836 *= _4535;\n    }\n    else\n    {\n        bool _4546 = _4521.type != 0;\n        bool _4552;\n        if (_4546)\n        {\n            _4552 = _4521.attenuation > 0.0;\n        }\n        else\n        {\n            _4552 = _4546;\n        }\n        if (_4552)\n        {\n            int param_7 = li;\n            int param_8 = fa_light_base(param_7);\n            int param_9 = li;\n            vec3 param_10 = fa_light_texel(param_8).xyz;\n            vec3 param_11 = world_pos;\n            vec3 param_12 = gn;\n            vec3 param_13 = _4521.direction;\n            float _4571 = fa_shadow_local(param_9, param_10, param_11, param_12, param_13);\n            _6838 = _4571;\n            _6836 *= _4571;\n        }\n    }\n    return LightSample(_4521.direction, _6836, _4521.attenuation, _6838, _4521._distance, _4521.type);\n}\n\nvec3 fa_ltc_tangent(vec3 n, vec3 v)\n{\n    vec3 _4611 = v - (n * dot(v, n));\n    vec3 t = _4611;\n    float _4615 = dot(_4611, _4611);\n    float l2 = _4615;\n    if (_4615 < 1.0000000133514319600180897396058e-10)\n    {\n        vec3 _4625;\n        if (abs(n.z) < 0.999000012874603271484375)\n        {\n            _4625 = cross(n, vec3(0.0, 0.0, 1.0));\n        }\n        else\n        {\n            _4625 = cross(n, vec3(1.0, 0.0, 0.0));\n        }\n        t = _4625;\n        l2 = dot(_4625, _4625);\n    }\n    return t * inversesqrt(l2);\n}\n\nvec3 fa_ltc_local(vec3 t1, vec3 n, vec3 p)\n{\n    return vec3(dot(t1, p), dot(cross(n, t1), p), dot(n, p));\n}\n\nvec3 fa_ltc_edge_vector(vec3 a, vec3 b)\n{\n    float _4660 = dot(a, a);\n    float _4664 = dot(b, b);\n    if ((_4660 < 1.0000000195414813782625560981111e-24) || (_4664 < 1.0000000195414813782625560981111e-24))\n    {\n        return vec3(0.0);\n    }\n    vec3 _4678 = a * inversesqrt(_4660);\n    vec3 _4683 = b * inversesqrt(_4664);\n    float _4687 = dot(_4678, _4683);\n    float _4690 = abs(_4687);\n    float g = (((((((((((0.0416471660137176513671875 * _4690) - 0.1924748718738555908203125) * _4690) + 0.4179156124591827392578125) * _4690) - 0.616057217121124267578125) * _4690) + 0.777722418308258056640625) * _4690) - 0.999542415142059326171875) * _4690) + 1.570791721343994140625;\n    if (_4687 < 0.0)\n    {\n        g = (3.1415927410125732421875 * inversesqrt(max(1.0 - (_4687 * _4687), 1.0000000116860974230803549289703e-07))) - g;\n    }\n    return cross(_4678, _4683) * g;\n}\n\nvoid fa_ltc_clip_edge(vec3 a, vec3 b, inout vec3 sum, inout vec3 leave, inout vec3 enter, inout vec2 seen)\n{\n    bool _4747 = a.z > 0.0;\n    bool _4751 = b.z > 0.0;\n    if (_4747 && _4751)\n    {\n        vec3 param = a;\n        vec3 param_1 = b;\n        sum += fa_ltc_edge_vector(param, param_1);\n    }\n    else\n    {\n        if (_4747 != _4751)\n        {\n            vec3 _4786 = a + ((b - a) * (a.z / (a.z - b.z)));\n            _4786.z = 0.0;\n            if (_4747)\n            {\n                vec3 param_2 = a;\n                vec3 param_3 = _4786;\n                sum += fa_ltc_edge_vector(param_2, param_3);\n                leave = _4786;\n                seen.x = 1.0;\n            }\n            else\n            {\n                vec3 param_4 = _4786;\n                vec3 param_5 = b;\n                sum += fa_ltc_edge_vector(param_4, param_5);\n                enter = _4786;\n                seen.y = 1.0;\n            }\n        }\n    }\n}\n\nfloat fa_ltc_quad(vec4 abcd, vec3 p0, vec3 p1, vec3 p2, vec3 p3)\n{\n    vec3 _4835 = vec3((abcd.x * p0.x) + (abcd.y * p0.z), p0.y, (abcd.z * p0.x) + (abcd.w * p0.z));\n    vec3 _4861 = vec3((abcd.x * p1.x) + (abcd.y * p1.z), p1.y, (abcd.z * p1.x) + (abcd.w * p1.z));\n    vec3 _4887 = vec3((abcd.x * p2.x) + (abcd.y * p2.z), p2.y, (abcd.z * p2.x) + (abcd.w * p2.z));\n    vec3 _4913 = vec3((abcd.x * p3.x) + (abcd.y * p3.z), p3.y, (abcd.z * p3.x) + (abcd.w * p3.z));\n    vec3 sum = vec3(0.0);\n    vec3 leave = vec3(0.0);\n    vec3 enter = vec3(0.0);\n    vec3 param = _4835;\n    vec3 param_1 = _4861;\n    vec3 param_2 = vec3(0.0);\n    vec3 param_3 = vec3(0.0);\n    vec3 param_4 = vec3(0.0);\n    vec2 param_5 = vec2(0.0);\n    fa_ltc_clip_edge(param, param_1, param_2, param_3, param_4, param_5);\n    sum = param_2;\n    leave = param_3;\n    enter = param_4;\n    vec3 param_6 = _4861;\n    vec3 param_7 = _4887;\n    vec3 param_8 = param_2;\n    vec3 param_9 = param_3;\n    vec3 param_10 = param_4;\n    vec2 param_11 = param_5;\n    fa_ltc_clip_edge(param_6, param_7, param_8, param_9, param_10, param_11);\n    sum = param_8;\n    leave = param_9;\n    enter = param_10;\n    vec3 param_12 = _4887;\n    vec3 param_13 = _4913;\n    vec3 param_14 = param_8;\n    vec3 param_15 = param_9;\n    vec3 param_16 = param_10;\n    vec2 param_17 = param_11;\n    fa_ltc_clip_edge(param_12, param_13, param_14, param_15, param_16, param_17);\n    sum = param_14;\n    leave = param_15;\n    enter = param_16;\n    vec3 param_18 = _4913;\n    vec3 param_19 = _4835;\n    vec3 param_20 = param_14;\n    vec3 param_21 = param_15;\n    vec3 param_22 = param_16;\n    vec2 param_23 = param_17;\n    fa_ltc_clip_edge(param_18, param_19, param_20, param_21, param_22, param_23);\n    sum = param_20;\n    leave = param_21;\n    enter = param_22;\n    if ((param_23.x * param_23.y) > 0.5)\n    {\n        vec3 param_24 = leave;\n        vec3 param_25 = enter;\n        sum += fa_ltc_edge_vector(param_24, param_25);\n    }\n    return sum.z * 0.15915493667125701904296875;\n}\n\nfloat fa_ltc_rect(vec4 abcd, vec3 center, vec3 ex, vec3 ey)\n{\n    vec4 param = abcd;\n    vec3 param_1 = (center - ex) - ey;\n    vec3 param_2 = (center + ex) - ey;\n    vec3 param_3 = (center + ex) + ey;\n    vec3 param_4 = (center - ex) + ey;\n    return abs(fa_ltc_quad(param, param_1, param_2, param_3, param_4));\n}\n\nfloat fa_area_form(vec4 m, float shape, vec3 pc, vec3 ex, vec3 ey)\n{\n    if ((shape < 0.5) || (shape > 1.5))\n    {\n        vec4 param = m;\n        vec3 param_1 = pc;\n        vec3 param_2 = ex;\n        vec3 param_3 = ey;\n        return fa_ltc_rect(param, param_1, param_2, param_3);\n    }\n    vec3 _5063 = (pc + (ex * 0.92387950420379638671875)) + (ey * 0.3826834261417388916015625);\n    vec3 _5087 = (pc - (ex * 0.92387950420379638671875)) + (ey * 0.3826834261417388916015625);\n    vec3 _5103 = (pc - (ex * 0.3826834261417388916015625)) - (ey * 0.92387950420379638671875);\n    vec4 param_4 = m;\n    vec3 param_5 = _5063;\n    vec3 param_6 = (pc + (ex * 0.3826834261417388916015625)) + (ey * 0.92387950420379638671875);\n    vec3 param_7 = (pc - (ex * 0.3826834261417388916015625)) + (ey * 0.92387950420379638671875);\n    vec3 param_8 = _5087;\n    vec4 param_9 = m;\n    vec3 param_10 = _5063;\n    vec3 param_11 = _5087;\n    vec3 param_12 = (pc - (ex * 0.92387950420379638671875)) - (ey * 0.3826834261417388916015625);\n    vec3 param_13 = _5103;\n    vec4 param_14 = m;\n    vec3 param_15 = _5063;\n    vec3 param_16 = _5103;\n    vec3 param_17 = (pc + (ex * 0.3826834261417388916015625)) - (ey * 0.92387950420379638671875);\n    vec3 param_18 = (pc + (ex * 0.92387950420379638671875)) - (ey * 0.3826834261417388916015625);\n    return abs((fa_ltc_quad(param_4, param_5, param_6, param_7, param_8) + fa_ltc_quad(param_9, param_10, param_11, param_12, param_13)) + fa_ltc_quad(param_14, param_15, param_16, param_17, param_18));\n}\n\nvec2 fa_ltc_uv(float roughness, float ndv)\n{\n    return ((vec2(clamp((roughness - 0.0500000007450580596923828125) * 1.0526316165924072265625, 0.0, 1.0), sqrt(clamp(1.0 - ndv, 0.0, 1.0))) * 63.0) + vec2(0.5)) * vec2(0.015625);\n}\n\nvec3 fa_area_shade(int li, vec3 world_pos, vec3 n, vec3 v, vec3 diffuse_color, vec3 f0, float f90, float roughness, float ndv, float window)\n{\n    int param = li;\n    int _5161 = fa_light_base(param);\n    int param_1 = _5161;\n    int param_2 = _5161 + 1;\n    int param_3 = _5161 + 2;\n    int param_4 = _5161 + 4;\n    vec4 _5183 = fa_light_texel(param_4);\n    int param_5 = _5161 + 5;\n    vec4 _5188 = fa_light_texel(param_5);\n    int param_6 = _5161 + 6;\n    vec4 _5193 = fa_light_texel(param_6);\n    float _5194 = _5193.w;\n    vec3 _5199 = fa_light_texel(param_1).xyz - world_pos;\n    bool _5201 = _5194 < 1.5;\n    bool _5208;\n    if (_5201)\n    {\n        _5208 = dot(normalize(fa_light_texel(param_3).xyz), _5199) >= 0.0;\n    }\n    else\n    {\n        _5208 = _5201;\n    }\n    if (_5208)\n    {\n        return vec3(0.0);\n    }\n    bool _5217 = (_5194 > 0.5) && _5201;\n    float _5221 = _5217 ? 1.0539000034332275390625 : 1.0;\n    vec3 _5224 = _5183.xyz;\n    float _5226 = _5183.w;\n    vec3 _5232 = _5188.xyz;\n    float _5234 = _5188.w;\n    vec3 up = _5232 * (_5234 * _5221);\n    float _5240;\n    if (_5217)\n    {\n        _5240 = (3.1415927410125732421875 * _5226) * _5226;\n    }\n    else\n    {\n        _5240 = (4.0 * _5226) * _5234;\n    }\n    if (_5194 > 1.5)\n    {\n        vec3 _5266 = cross(_5224, -_5199);\n        vec3 perp = _5266;\n        float _5270 = dot(_5266, _5266);\n        vec3 _5273;\n        if (_5270 > 1.0000000133514319600180897396058e-10)\n        {\n            _5273 = perp * inversesqrt(_5270);\n        }\n        else\n        {\n            _5273 = _5232;\n        }\n        perp = _5273;\n        up = _5273 * _5234;\n    }\n    float _5294 = max(_5240, 9.9999999747524270787835121154785e-07);\n    vec3 param_7 = n;\n    vec3 param_8 = v;\n    vec3 _5304 = fa_ltc_tangent(param_7, param_8);\n    vec3 param_9 = _5304;\n    vec3 param_10 = n;\n    vec3 param_11 = _5199;\n    vec3 _5312 = fa_ltc_local(param_9, param_10, param_11);\n    vec3 param_12 = _5304;\n    vec3 param_13 = n;\n    vec3 param_14 = _5224 * (_5226 * _5221);\n    vec3 _5320 = fa_ltc_local(param_12, param_13, param_14);\n    vec3 param_15 = _5304;\n    vec3 param_16 = n;\n    vec3 param_17 = up;\n    vec3 _5328 = fa_ltc_local(param_15, param_16, param_17);\n    vec4 param_18 = vec4(1.0, 0.0, 0.0, 1.0);\n    float param_19 = _5194;\n    vec3 param_20 = _5312;\n    vec3 param_21 = _5320;\n    vec3 param_22 = _5328;\n    float param_23 = roughness;\n    float param_24 = ndv;\n    vec2 _5347 = fa_ltc_uv(param_23, param_24) * 64.0;\n    vec2 param_25 = _5347;\n    vec2 param_26 = _5347 + vec2(64.0, 0.0);\n    vec4 _5357 = fa_atlas_fetch(param_26);\n    vec4 param_27 = fa_atlas_fetch(param_25);\n    float param_28 = _5194;\n    vec3 param_29 = _5312;\n    vec3 param_30 = _5320;\n    vec3 param_31 = _5328;\n    return (((diffuse_color * fa_area_form(param_18, param_19, param_20, param_21, param_22)) + (((f0 * _5357.x) + ((vec3(f90) - f0) * _5357.y)) * fa_area_form(param_27, param_28, param_29, param_30, param_31))) * fa_light_texel(param_2).xyz) * ((((3.1415927410125732421875 * dot(_5199, _5199)) + _5294) / _5294) * window);\n}\n\nvec3 fa_light_rgb(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 1;\n    return fa_light_texel(param_1).xyz;\n}\n\nfloat fa_d_charlie(float alpha, float ndh)\n{\n    float _4194 = 1.0 / alpha;\n    return ((2.0 + _4194) * pow(sqrt(max(1.0 - (ndh * ndh), 9.9999997473787516355514526367188e-05)), _4194)) * 0.15915493667125701904296875;\n}\n\nfloat fa_v_ashikhmin(float ndl, float ndv)\n{\n    return clamp(0.25 / max((ndl + ndv) - (ndl * ndv), 9.9999997473787516355514526367188e-05), 0.0, 1.0);\n}\n\nfloat fa_layers_coat(FaLayers L, vec3 l, vec3 h, float vdh)\n{\n    float _4229 = max(dot(L.nc, l), 0.0);\n    float _4235 = max(dot(L.nc, h), 0.0);\n    float _4244 = ((_4235 * _4235) * (L.coat_a2 - 1.0)) + 1.0;\n    return (((L.coat * (0.039999999105930328369140625 + (0.959999978542327880859375 * pow(clamp(1.0 - vdh, 0.0, 1.0), 5.0)))) * (((L.coat_a2 / ((3.1415927410125732421875 * _4244) * _4244)) * (0.5 / max(mix((2.0 * _4229) * L.coat_ndv, _4229 + L.coat_ndv, L.coat_alpha), 9.9999997473787516355514526367188e-05))) * 3.1415927410125732421875)) * step(9.9999997473787516355514526367188e-05, _4229)) * _4229;\n}\n\nvec3 fa_area_layers(FaLayers L, int li, vec3 world_pos, vec3 n, vec3 v, vec3 l, vec3 diffuse_color, vec3 f0, float roughness, float ndv, float window)\n{\n    int param = li;\n    vec3 param_1 = world_pos;\n    vec3 param_2 = n;\n    vec3 param_3 = v;\n    vec3 param_4 = diffuse_color;\n    vec3 param_5 = f0;\n    float param_6 = L.f90;\n    float param_7 = roughness;\n    float param_8 = ndv;\n    float param_9 = window;\n    float _5425;\n    if (L.sheen_on)\n    {\n        _5425 = L.sheen_scale;\n    }\n    else\n    {\n        _5425 = 1.0;\n    }\n    vec3 result = fa_area_shade(param, param_1, param_2, param_3, param_4, param_5, param_6, param_7, param_8, param_9) * (L.keep * _5425);\n    vec3 _5438 = normalize(l + v);\n    int param_10 = li;\n    vec3 _5449 = fa_light_rgb(param_10) * window;\n    if (L.sheen_on)\n    {\n        float _5458 = max(dot(n, l), 0.0);\n        float param_11 = L.sheen_alpha;\n        float param_12 = max(dot(n, _5438), 0.0);\n        float param_13 = _5458;\n        float param_14 = ndv;\n        result += ((L.sheen * _5449) * (((((fa_d_charlie(param_11, param_12) * fa_v_ashikhmin(param_13, param_14)) * 3.1415927410125732421875) * step(9.9999997473787516355514526367188e-05, _5458)) * _5458) * L.keep));\n    }\n    if (L.coat > 0.0)\n    {\n        FaLayers param_15 = L;\n        vec3 param_16 = l;\n        vec3 param_17 = _5438;\n        float param_18 = max(dot(v, _5438), 0.0);\n        result += (_5449 * fa_layers_coat(param_15, param_16, param_17, param_18));\n    }\n    return result;\n}\n\nfloat fa_d_ggx_aniso(float ndh, float tdh, float bdh, float at, float ab)\n{\n    float _4097 = tdh / at;\n    float _4101 = bdh / ab;\n    float _4113 = ((_4097 * _4097) + (_4101 * _4101)) + (ndh * ndh);\n    return 1.0 / ((((3.1415927410125732421875 * at) * ab) * _4113) * _4113);\n}\n\nfloat fa_lambda_ggx_aniso(float n, float t, float b, float at, float ab)\n{\n    return 0.5 * (sqrt(1.0 + (((((at * at) * t) * t) + (((ab * ab) * b) * b)) / max(n * n, 9.9999999392252902907785028219223e-09))) - 1.0);\n}\n\nfloat fa_v_ggx_aniso(float ndl, float ndv, float tdv, float bdv, float tdl, float bdl, float at, float ab)\n{\n    float param = ndv;\n    float param_1 = tdv;\n    float param_2 = bdv;\n    float param_3 = at;\n    float param_4 = ab;\n    float param_5 = ndl;\n    float param_6 = tdl;\n    float param_7 = bdl;\n    float param_8 = at;\n    float param_9 = ab;\n    return clamp(1.0 / ((4.0 * max(ndl * ndv, 9.9999997473787516355514526367188e-05)) * ((1.0 + fa_lambda_ggx_aniso(param, param_1, param_2, param_3, param_4)) + fa_lambda_ggx_aniso(param_5, param_6, param_7, param_8, param_9))), 0.0, 1.0);\n}\n\nvec3 fa_layers_light(FaLayers L, vec3 diffuse_color, vec3 f0, vec3 n, vec3 v, vec3 l, vec3 h, float ndl, float ndv, float ndh, float vdh, float alpha, float a2)\n{\n    float _4293 = step(9.9999997473787516355514526367188e-05, ndl);\n    float d_ggx;\n    float vis;\n    if (L.aniso != 0.0)\n    {\n        float param = ndh;\n        float param_1 = dot(L.t, h);\n        float param_2 = dot(L.b, h);\n        float param_3 = L.at;\n        float param_4 = L.ab;\n        d_ggx = fa_d_ggx_aniso(param, param_1, param_2, param_3, param_4);\n        float param_5 = ndl;\n        float param_6 = ndv;\n        float param_7 = dot(L.t, v);\n        float param_8 = dot(L.b, v);\n        float param_9 = dot(L.t, l);\n        float param_10 = dot(L.b, l);\n        float param_11 = L.at;\n        float param_12 = L.ab;\n        vis = fa_v_ggx_aniso(param_5, param_6, param_7, param_8, param_9, param_10, param_11, param_12);\n    }\n    else\n    {\n        float _4372 = ((ndh * ndh) * (a2 - 1.0)) + 1.0;\n        d_ggx = a2 / ((3.1415927410125732421875 * _4372) * _4372);\n        vis = 0.5 / max(mix((2.0 * ndl) * ndv, ndl + ndv, alpha), 9.9999997473787516355514526367188e-05);\n    }\n    vec3 base = diffuse_color + (((f0 + ((vec3(L.f90) - f0) * pow(clamp(1.0 - vdh, 0.0, 1.0), 5.0))) * ((d_ggx * vis) * 3.1415927410125732421875)) * _4293);\n    if (L.sheen_on)\n    {\n        float param_13 = L.sheen_alpha;\n        float param_14 = ndh;\n        float param_15 = ndl;\n        float param_16 = ndv;\n        base = (base * L.sheen_scale) + (L.sheen * (((fa_d_charlie(param_13, param_14) * fa_v_ashikhmin(param_15, param_16)) * 3.1415927410125732421875) * _4293));\n    }\n    vec3 result = base * (L.keep * ndl);\n    if (L.coat > 0.0)\n    {\n        FaLayers param_17 = L;\n        vec3 param_18 = l;\n        vec3 param_19 = h;\n        float param_20 = vdh;\n        result += vec3(fa_layers_coat(param_17, param_18, param_19, param_20));\n    }\n    return result;\n}\n\nvec2 fa_env_brdf(float rough, float ndv)\n{\n    vec4 _3503 = (vec4(-1.0, -0.0274999998509883880615234375, -0.572000026702880859375, 0.02199999988079071044921875) * rough) + vec4(1.0, 0.0425000004470348358154296875, 1.03999996185302734375, -0.039999999105930328369140625);\n    float _3506 = _3503.x;\n    return (vec2(-1.03999996185302734375, 1.03999996185302734375) * ((min(_3506 * _3506, exp2((-9.27999973297119140625) * ndv)) * _3506) + _3503.y)) + _3503.zw;\n}\n\nvec3 fa_environment(vec3 d, float rough)\n{\n    if (fa_mesh_fs_params[11].w > 0.5)\n    {\n        return textureLod(fa_env_tex_fa_env_smp, d, clamp(rough, 0.0, 1.0) * fa_mesh_fs_params[12].w).xyz;\n    }\n    float _3357 = rough * rough;\n    float _3387 = 0.60000002384185791015625 * _3357;\n    return mix(mix(fa_mesh_fs_params[12].xyz * 0.550000011920928955078125, mix(fa_mesh_fs_params[12].xyz, fa_mesh_fs_params[11].xyz, vec3(pow(clamp(d.y * (1.0 - (0.699999988079071044921875 * _3357)), 0.0, 1.0), 0.550000011920928955078125))), vec3(smoothstep((-0.0500000007450580596923828125) - _3387, 0.0500000007450580596923828125 + _3387, d.y))), ((fa_mesh_fs_params[11].xyz + fa_mesh_fs_params[12].xyz) * 0.5) * 0.800000011920928955078125, vec3(_3357 * 0.60000002384185791015625));\n}\n\nvec3 fa_layers_ibl(FaLayers L, vec3 n, vec3 v, vec3 f0, float roughness)\n{\n    vec3 rn = n;\n    if (L.aniso != 0.0)\n    {\n        vec3 _3980;\n        if (L.aniso >= 0.0)\n        {\n            _3980 = L.b;\n        }\n        else\n        {\n            _3980 = L.t;\n        }\n        rn = normalize(mix(n, cross(cross(_3980, v), _3980), vec3(abs(L.aniso))));\n    }\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05);\n    vec2 _4013 = fa_env_brdf(param, param_1);\n    vec3 param_2 = reflect(-v, rn);\n    float param_3 = roughness;\n    vec3 result = (fa_environment(param_2, param_3) * ((f0 * _4013.x) + (vec3(L.f90) * _4013.y))) * L.base_scale;\n    if (L.sheen_on)\n    {\n        vec3 param_4 = n;\n        float param_5 = L.sheen_rough;\n        result += ((L.sheen * (L.sheen_e * L.keep)) * fa_environment(param_4, param_5));\n    }\n    if (L.coat > 0.0)\n    {\n        float param_6 = L.coat_rough;\n        float param_7 = L.coat_ndv;\n        vec2 _4068 = fa_env_brdf(param_6, param_7);\n        vec3 param_8 = reflect(-v, L.nc);\n        float param_9 = L.coat_rough;\n        result += (fa_environment(param_8, param_9) * (L.coat * ((0.039999999105930328369140625 * _4068.x) + _4068.y)));\n    }\n    return result;\n}\n\nvec3 fa_sky_reflection(vec3 n, vec3 v, vec3 f0, float roughness)\n{\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05);\n    vec2 _3545 = fa_env_brdf(param, param_1);\n    vec3 param_2 = reflect(-v, n);\n    float param_3 = roughness;\n    return fa_environment(param_2, param_3) * ((f0 * _3545.x) + vec3(_3545.y));\n}\n\nvec3 fa_shadow_debug(vec3 color, vec3 world)\n{\n    if (fa_shadows[27].w < 0.5)\n    {\n        return color;\n    }\n    int _3151 = int(fa_shadows[25].x + 0.5);\n    float _3161 = dot(world - fa_shadows[27].xyz, fa_shadows[28].xyz);\n    vec3 tint = vec3(0.3499999940395355224609375);\n    bool _3166 = _3151 > 0;\n    bool _3175;\n    if (_3166)\n    {\n        int param = _3151 - 1;\n        _3175 = _3161 <= fa_shadow_split_at(param);\n    }\n    else\n    {\n        _3175 = _3166;\n    }\n    if (_3175)\n    {\n        tint = vec3(1.0, 0.1500000059604644775390625, 0.100000001490116119384765625);\n        bool _3181 = _3151 > 1;\n        bool _3188;\n        if (_3181)\n        {\n            _3188 = _3161 > fa_shadows[24].x;\n        }\n        else\n        {\n            _3188 = _3181;\n        }\n        if (_3188)\n        {\n            tint = vec3(0.100000001490116119384765625, 0.89999997615814208984375, 0.20000000298023223876953125);\n        }\n        bool _3194 = _3151 > 2;\n        bool _3201;\n        if (_3194)\n        {\n            _3201 = _3161 > fa_shadows[24].y;\n        }\n        else\n        {\n            _3201 = _3194;\n        }\n        if (_3201)\n        {\n            tint = vec3(0.1500000059604644775390625, 0.300000011920928955078125, 1.0);\n        }\n        bool _3207 = _3151 > 3;\n        bool _3214;\n        if (_3207)\n        {\n            _3214 = _3161 > fa_shadows[24].z;\n        }\n        else\n        {\n            _3214 = _3207;\n        }\n        if (_3214)\n        {\n            tint = vec3(1.0, 0.89999997615814208984375, 0.100000001490116119384765625);\n        }\n    }\n    return mix(color, tint, vec3(0.550000011920928955078125));\n}\n\nvoid main()\n{\n    fa_inst_load();\n    vec3 _6536 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _6536 = -_6536;\n    }\n    vec3 _5894 = normalize(fa_mesh_fs_params[0].xyz - fa_world_pos);\n    vec3 param = fa_world_pos;\n    fa_cluster_begin(param);\n    SurfaceInput param_1 = SurfaceInput(fa_world_pos, _6536, fa_world_tangent, fa_uv, fa_vertex_color, _5894, gl_FrontFacing);\n    Surface _5902 = fa_standard_surface(param_1);\n    vec3 _6567 = _5902.albedo;\n    float _6568 = _5902.alpha;\n    vec3 _6569 = _5902.normal;\n    float _6570 = _5902.metallic;\n    float _6571 = _5902.roughness;\n    float _6572 = _5902.occlusion;\n    vec3 _6573 = _5902.emission;\n    float _6574 = _5902.clearcoat;\n    float _6575 = _5902.clearcoat_roughness;\n    vec3 _6576 = _5902.sheen_color;\n    float _6577 = _5902.sheen_roughness;\n    float _6578 = _5902.anisotropy;\n    float _6579 = _5902.anisotropy_rotation;\n    float _6580 = _5902.specular;\n    float _6581 = _5902.ior;\n    vec3 _6582 = _5902.specular_color;\n    SurfaceInput param_2 = SurfaceInput(fa_world_pos, _6536, fa_world_tangent, fa_uv, fa_vertex_color, _5894, gl_FrontFacing);\n    Surface param_3 = _5902;\n    surface(param_2, param_3);\n    _6567 = param_3.albedo;\n    _6568 = param_3.alpha;\n    _6569 = param_3.normal;\n    _6570 = param_3.metallic;\n    _6571 = param_3.roughness;\n    _6572 = param_3.occlusion;\n    _6573 = param_3.emission;\n    _6574 = param_3.clearcoat;\n    _6575 = param_3.clearcoat_roughness;\n    _6576 = param_3.sheen_color;\n    _6577 = param_3.sheen_roughness;\n    _6578 = param_3.anisotropy;\n    _6579 = param_3.anisotropy_rotation;\n    _6580 = param_3.specular;\n    _6581 = param_3.ior;\n    _6582 = param_3.specular_color;\n    vec3 param_4 = fa_world_pos;\n    vec3 param_5 = _6536;\n    vec3 param_6 = param_3.albedo;\n    vec3 param_7 = param_3.normal;\n    fa_apply_decals(param_4, param_5, param_6, param_7);\n    _6567 = param_6;\n    _6569 = param_7;\n    vec3 result;\n    if (fa_mesh_fs_params[3].w > 0.5)\n    {\n        result = _6567;\n    }\n    else\n    {\n        vec3 _5941 = normalize(_6569);\n        float _5948 = clamp(_6570, 0.0, 1.0);\n        float _5952 = clamp(_6571, 0.0500000007450580596923828125, 1.0);\n        float _5956 = _5952 * _5952;\n        float _5960 = _5956 * _5956;\n        float _5965 = max(dot(_5941, _5894), 9.9999997473787516355514526367188e-05);\n        vec3 _5971 = _6567 * (1.0 - _5948);\n        vec3 _5978 = mix(vec3(0.039999999105930328369140625), _6567, vec3(_5948));\n        vec3 f0 = _5978;\n        SurfaceInput param_8 = SurfaceInput(fa_world_pos, _6536, fa_world_tangent, fa_uv, fa_vertex_color, _5894, gl_FrontFacing);\n        Surface param_9 = Surface(_6567, _6568, _6569, _6570, _6571, _6572, _6573, _6574, _6575, _6576, _6577, _6578, _6579, _6580, _6581, _6582);\n        vec3 param_10 = _5941;\n        vec3 param_11 = _5894;\n        float param_12 = _5948;\n        float param_13 = _5952;\n        vec3 param_14 = _5978;\n        FaLayers _5994 = fa_layers_setup(param_8, param_9, param_10, param_11, param_12, param_13, param_14);\n        f0 = param_14;\n        vec3 param_15 = _5941;\n        vec3 lit = (fa_indirect_diffuse(param_15) * _5971) * _6572;\n        if (_5994.on)\n        {\n            lit *= _5994.base_scale;\n        }\n        int _6016 = fa_cl_ndir + fa_cl_local;\n        for (int ln = 0; ln < _6016; ln++)\n        {\n            int param_16 = ln;\n            int _6029 = fa_cl_light(param_16);\n            bool _6032 = fa_lm.z > 0.5;\n            bool _6038;\n            if (_6032)\n            {\n                int param_17 = _6029;\n                _6038 = fa_light_baked(param_17);\n            }\n            else\n            {\n                _6038 = _6032;\n            }\n            if (_6038)\n            {\n                continue;\n            }\n            int param_18 = _6029;\n            vec3 param_19 = fa_world_pos;\n            vec3 param_20 = _6536;\n            LightSample _6050 = fa_light_shadowed(param_18, param_19, param_20);\n            float _6058 = max(dot(_5941, _6050.direction), 0.0);\n            float _6064 = _6050.attenuation * _6050.shadow;\n            vec3 _6069 = normalize(_6050.direction + _5894);\n            float _6074 = max(dot(_5941, _6069), 0.0);\n            float _6079 = max(dot(_5894, _6069), 0.0);\n            bool _6086;\n            if (fa_light_is_area)\n            {\n                _6086 = !_5994.on;\n            }\n            else\n            {\n                _6086 = fa_light_is_area;\n            }\n            if (_6086)\n            {\n                int param_21 = _6029;\n                vec3 param_22 = fa_world_pos;\n                vec3 param_23 = _5941;\n                vec3 param_24 = _5894;\n                vec3 param_25 = _5971;\n                vec3 param_26 = f0;\n                float param_27 = 1.0;\n                float param_28 = _5952;\n                float param_29 = _5965;\n                float param_30 = _6064;\n                lit += fa_area_shade(param_21, param_22, param_23, param_24, param_25, param_26, param_27, param_28, param_29, param_30);\n            }\n            else\n            {\n                if (fa_light_is_area)\n                {\n                    FaLayers param_31 = _5994;\n                    int param_32 = _6029;\n                    vec3 param_33 = fa_world_pos;\n                    vec3 param_34 = _5941;\n                    vec3 param_35 = _5894;\n                    vec3 param_36 = _6050.direction;\n                    vec3 param_37 = _5971;\n                    vec3 param_38 = f0;\n                    float param_39 = _5952;\n                    float param_40 = _5965;\n                    float param_41 = _6064;\n                    lit += fa_area_layers(param_31, param_32, param_33, param_34, param_35, param_36, param_37, param_38, param_39, param_40, param_41);\n                }\n                else\n                {\n                    if (_5994.on)\n                    {\n                        FaLayers param_42 = _5994;\n                        vec3 param_43 = _5971;\n                        vec3 param_44 = f0;\n                        vec3 param_45 = _5941;\n                        vec3 param_46 = _5894;\n                        vec3 param_47 = _6050.direction;\n                        vec3 param_48 = _6069;\n                        float param_49 = _6058;\n                        float param_50 = _5965;\n                        float param_51 = _6074;\n                        float param_52 = _6079;\n                        float param_53 = _5956;\n                        float param_54 = _5960;\n                        int param_55 = _6029;\n                        lit += (fa_layers_light(param_42, param_43, param_44, param_45, param_46, param_47, param_48, param_49, param_50, param_51, param_52, param_53, param_54) * ((fa_light_rgb(param_55) * fa_light_tint) * _6064));\n                    }\n                    else\n                    {\n                        float _6192 = ((_6074 * _6074) * (_5960 - 1.0)) + 1.0;\n                        int param_56 = _6029;\n                        lit += (((_5971 + (((f0 + ((vec3(1.0) - f0) * pow(1.0 - _6079, 5.0))) * (((_5960 / ((3.1415927410125732421875 * _6192) * _6192)) * (0.5 / max(mix((2.0 * _6058) * _5965, _6058 + _5965, _5956), 9.9999997473787516355514526367188e-05))) * 3.1415927410125732421875)) * step(9.9999997473787516355514526367188e-05, _6058))) * (fa_light_rgb(param_56) * fa_light_tint)) * (_6058 * _6064));\n                    }\n                }\n            }\n        }\n        if (_5994.on)\n        {\n            FaLayers param_57 = _5994;\n            vec3 param_58 = _5941;\n            vec3 param_59 = _5894;\n            vec3 param_60 = f0;\n            float param_61 = _5952;\n            lit += (fa_layers_ibl(param_57, param_58, param_59, param_60, param_61) * _6572);\n        }\n        else\n        {\n            vec3 param_62 = _5941;\n            vec3 param_63 = _5894;\n            vec3 param_64 = f0;\n            float param_65 = _5952;\n            lit += (fa_sky_reflection(param_62, param_63, param_64, param_65) * _6572);\n        }\n        result = lit;\n    }\n    vec3 _6287 = result;\n    vec3 _6288 = _6287 + _6573;\n    result = _6288;\n    vec3 param_66 = _6288;\n    vec3 param_67 = fa_world_pos;\n    result = fa_shadow_debug(param_66, param_67);\n    bool _6297 = fa_mesh_fs_params[7].w > 0.0;\n    bool _6304;\n    if (!_6297)\n    {\n        _6304 = fa_mesh_fs_params[8].y > 0.0;\n    }\n    else\n    {\n        _6304 = _6297;\n    }\n    if (_6304)\n    {\n        vec3 _6313 = fa_world_pos - fa_mesh_fs_params[0].xyz;\n        float _6319 = dot(_6313, fa_mesh_fs_params[9].xyz);\n        bool _6323 = fa_mesh_fs_params[9].w > 0.5;\n        float _6324;\n        if (_6323)\n        {\n            _6324 = _6319;\n        }\n        else\n        {\n            _6324 = length(_6313);\n        }\n        float _6336 = _6324 - fa_mesh_fs_params[8].x;\n        if (_6336 > 0.0)\n        {\n            float _6345 = fa_mesh_fs_params[7].w * _6336;\n            float tau = _6345 * _6345;\n            if (fa_mesh_fs_params[8].y > 0.0)\n            {\n                float _6361;\n                if (_6323)\n                {\n                    _6361 = fa_world_pos.y - (fa_mesh_fs_params[9].y * _6319);\n                }\n                else\n                {\n                    _6361 = fa_mesh_fs_params[0].y;\n                }\n                float _6382 = mix(_6361, fa_world_pos.y, clamp(fa_mesh_fs_params[8].x / _6324, 0.0, 1.0));\n                float _6386 = fa_world_pos.y - _6382;\n                float _6391 = _6382 - fa_mesh_fs_params[8].z;\n                float _6396 = fa_world_pos.y - fa_mesh_fs_params[8].z;\n                bool _6399 = _6391 <= 0.0;\n                bool _6400 = !_6399;\n                bool _6406;\n                if (_6400)\n                {\n                    _6406 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _6406 = _6399;\n                }\n                float _6407;\n                if (_6406)\n                {\n                    _6407 = fa_mesh_fs_params[8].y;\n                }\n                else\n                {\n                    _6407 = fa_mesh_fs_params[8].y * exp(-min(fa_mesh_fs_params[8].w * _6391, 80.0));\n                }\n                bool _6434;\n                if (_6400)\n                {\n                    _6434 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _6434 = _6399;\n                }\n                float _6435;\n                if (_6434)\n                {\n                    _6435 = fa_mesh_fs_params[8].y * _6391;\n                }\n                else\n                {\n                    _6435 = (fa_mesh_fs_params[8].y * (1.0 - exp(-min(fa_mesh_fs_params[8].w * _6391, 80.0)))) / fa_mesh_fs_params[8].w;\n                }\n                bool _6460 = _6396 <= 0.0;\n                bool _6467;\n                if (!_6460)\n                {\n                    _6467 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _6467 = _6460;\n                }\n                float _6468;\n                if (_6467)\n                {\n                    _6468 = fa_mesh_fs_params[8].y * _6396;\n                }\n                else\n                {\n                    _6468 = (fa_mesh_fs_params[8].y * (1.0 - exp(-min(fa_mesh_fs_params[8].w * _6396, 80.0)))) / fa_mesh_fs_params[8].w;\n                }\n                float _6495;\n                if (abs(_6386) < 0.001000000047497451305389404296875)\n                {\n                    _6495 = _6407;\n                }\n                else\n                {\n                    _6495 = (_6468 - _6435) / _6386;\n                }\n                tau += (_6336 * max(_6495, 0.0));\n            }\n            result = mix(result, fa_mesh_fs_params[7].xyz, vec3(clamp(1.0 - exp(-clamp(tau, 0.0, 80.0)), 0.0, 1.0)));\n        }\n    }\n    fa_frag_color = vec4(result, _6568);\n}\n\n",
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
            "inst_name": "_548",
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
            "inst_name": "_2215",
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
          }
        ]
      }
    },
    "mesh_skin": {
      "vs": "#version 430\n\nstruct VertexData\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 color;\n    vec3 object_pos;\n};\n\nstruct points_item\n{\n    vec4 pos;\n    vec4 tint;\n};\n\nlayout(binding = 0, std430) readonly buffer fa_vs_points_buf\n{\n    points_item data[];\n} fa_vs_points;\n\nuniform vec4 fa_mesh_vs_params[11];\nuniform vec4 fa_skin[192];\nuniform vec4 fa_inst_base[4];\nlayout(location = 0) out vec3 fa_world_pos;\nlayout(location = 1) out vec3 fa_world_normal;\nlayout(location = 2) out vec4 fa_world_tangent;\nlayout(location = 3) out vec2 fa_uv;\nlayout(location = 4) out vec4 fa_vertex_color;\nlayout(location = 9) in vec4 fa_joints;\nlayout(location = 10) in vec4 fa_weights;\nlayout(location = 0) in vec3 fa_position;\nlayout(location = 1) in vec3 fa_normal;\nlayout(location = 3) in vec4 fa_tangent;\nlayout(location = 2) in vec2 fa_texcoord0;\nlayout(location = 4) in vec4 fa_color;\nlayout(location = 5) out vec3 fa_lm;\nlayout(location = 5) in vec4 fa_inst_m0;\nlayout(location = 6) in vec4 fa_inst_m1;\nlayout(location = 7) in vec4 fa_inst_m2;\nlayout(location = 8) in vec4 fa_inst_m3;\n\nvoid fa_inst_begin()\n{\n}\n\nmat4 fa_skin_matrix(vec4 joints, vec4 weights)\n{\n    vec4 r0 = vec4(0.0);\n    vec4 r1 = vec4(0.0);\n    vec4 r2 = vec4(0.0);\n    for (int i = 0; i < 4; i++)\n    {\n        int _208 = int((joints[i] * 255.0) + 0.5) * 3;\n        r0 += (fa_skin[_208 * 1 + 0] * weights[i]);\n        r1 += (fa_skin[(_208 + 1) * 1 + 0] * weights[i]);\n        r2 += (fa_skin[(_208 + 2) * 1 + 0] * weights[i]);\n    }\n    return mat4(vec4(r0.x, r1.x, r2.x, 0.0), vec4(r0.y, r1.y, r2.y, 0.0), vec4(r0.z, r1.z, r2.z, 0.0), vec4(r0.w, r1.w, r2.w, 1.0));\n}\n\nVertexData fa_vertex_data(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    vec3 _114 = cross(model[1].xyz, model[2].xyz);\n    float _119 = (dot(model[0].xyz, _114) < 0.0) ? (-1.0) : 1.0;\n    return VertexData((model * vec4(position, 1.0)).xyz, (((_114 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _119, vec4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _119), texcoord0 * fa_mesh_vs_params[8].xy, color, position);\n}\n\nvoid vertex(inout VertexData v)\n{\n    if (fa_vs_points.data[gl_InstanceID].pos.w < 0.5)\n    {\n        v.world_pos = vec3(1000000000.0);\n        return;\n    }\n    v.world_pos += fa_vs_points.data[gl_InstanceID].pos.xyz;\n    v.color = fa_vs_points.data[gl_InstanceID].tint;\n}\n\nvoid fa_shade_vertex(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    mat4 param = model;\n    vec3 param_1 = position;\n    vec3 param_2 = normal;\n    vec4 param_3 = tangent;\n    vec2 param_4 = texcoord0;\n    vec4 param_5 = color;\n    VertexData param_6 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    vertex(param_6);\n    fa_world_pos = param_6.world_pos;\n    fa_world_normal = param_6.world_normal;\n    fa_world_tangent = param_6.world_tangent;\n    fa_uv = param_6.uv;\n    fa_vertex_color = param_6.color;\n    gl_Position = mat4(fa_mesh_vs_params[0], fa_mesh_vs_params[1], fa_mesh_vs_params[2], fa_mesh_vs_params[3]) * vec4(param_6.world_pos, 1.0);\n}\n\nvoid main()\n{\n    fa_inst_begin();\n    vec4 param = fa_joints;\n    vec4 param_1 = fa_weights;\n    mat4 param_2 = mat4(fa_inst_base[0], fa_inst_base[1], fa_inst_base[2], fa_inst_base[3]) * fa_skin_matrix(param, param_1);\n    vec3 param_3 = fa_position;\n    vec3 param_4 = fa_normal;\n    vec4 param_5 = fa_tangent;\n    vec2 param_6 = fa_texcoord0;\n    vec4 param_7 = fa_color;\n    fa_shade_vertex(param_2, param_3, param_4, param_5, param_6, param_7);\n    fa_lm = vec3(0.0);\n}\n\n",
      "fs": "#version 430\n\nstruct SurfaceInput\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 vertex_color;\n    vec3 view_dir;\n    bool front_facing;\n};\n\nstruct LightSample\n{\n    vec3 direction;\n    vec3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct Surface\n{\n    vec3 albedo;\n    float alpha;\n    vec3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    vec3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    vec3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    vec3 specular_color;\n};\n\nstruct FaLayers\n{\n    bool on;\n    float f90;\n    float keep;\n    float base_scale;\n    float coat;\n    float coat_rough;\n    float coat_alpha;\n    float coat_a2;\n    vec3 nc;\n    float coat_ndv;\n    bool sheen_on;\n    vec3 sheen;\n    float sheen_rough;\n    float sheen_alpha;\n    float sheen_scale;\n    float sheen_e;\n    float aniso;\n    vec3 t;\n    vec3 b;\n    float at;\n    float ab;\n};\n\nconst float _3645[63] = float[](1.0, 1.0, 1.0, 0.4790000021457672119140625, 0.11699999868869781494140625, 0.01200000010430812835693359375, 0.0, 0.0, 0.0, 1.0, 1.0, 1.0, 0.578000009059906005859375, 0.19300000369548797607421875, 0.0350000001490116119384765625, 0.0030000000260770320892333984375, 0.0, 0.0, 1.0, 1.0, 1.0, 0.6740000247955322265625, 0.3459999859333038330078125, 0.1319999992847442626953125, 0.032999999821186065673828125, 0.0040000001899898052215576171875, 0.0, 0.971000015735626220703125, 0.954999983310699462890625, 0.828999996185302734375, 0.63999998569488525390625, 0.42599999904632568359375, 0.24500000476837158203125, 0.115000002086162567138671875, 0.037000000476837158203125, 0.0030000000260770320892333984375, 0.7469999790191650390625, 0.737999975681304931640625, 0.670000016689300537109375, 0.563000023365020751953125, 0.4309999942779541015625, 0.3039999902248382568359375, 0.1940000057220458984375, 0.1019999980926513671875, 0.0309999994933605194091796875, 0.614000022411346435546875, 0.609000027179718017578125, 0.566999971866607666015625, 0.499000012874603271484375, 0.412000000476837158203125, 0.32400000095367431640625, 0.240999996662139892578125, 0.162000000476837158203125, 0.087999999523162841796875, 0.538999974727630615234375, 0.535000026226043701171875, 0.505999982357025146484375, 0.4569999873638153076171875, 0.393999993801116943359375, 0.328999996185302734375, 0.2660000026226043701171875, 0.203999996185302734375, 0.14200000464916229248046875);\n\nstruct points_item\n{\n    vec4 pos;\n    vec4 tint;\n};\n\nuniform vec4 fa_mesh_fs_params[24];\nuniform vec4 fa_shadows[30];\nlayout(binding = 1, std430) readonly buffer fa_points_buf\n{\n    points_item data[];\n} points;\n\nlayout(binding = 0) uniform sampler2D fa_light_tex_fa_shadow_smp;\nlayout(binding = 1) uniform sampler2D fa_tex_fa_smp;\nlayout(binding = 2) uniform sampler2D fa_normal_tex_fa_smp;\nlayout(binding = 3) uniform sampler2D fa_mr_tex_fa_smp;\nlayout(binding = 4) uniform sampler2D fa_occlusion_tex_fa_smp;\nlayout(binding = 5) uniform sampler2D fa_emissive_tex_fa_smp;\nlayout(binding = 6) uniform sampler2D fa_decal_tex_fa_env_smp;\nlayout(binding = 7) uniform sampler2D fa_lightmap_fa_env_smp;\nlayout(binding = 8) uniform samplerCube fa_env_tex_fa_env_smp;\nlayout(binding = 9) uniform sampler2D fa_light_atlas_fa_env_smp;\nlayout(binding = 10) uniform sampler2D fa_shadow_tex_fa_shadow_smp;\n\nlayout(location = 0) in vec3 fa_world_pos;\nlayout(location = 5) in vec3 fa_lm;\nlayout(location = 1) in vec3 fa_world_normal;\nlayout(location = 2) in vec4 fa_world_tangent;\nlayout(location = 3) in vec2 fa_uv;\nlayout(location = 4) in vec4 fa_vertex_color;\nlayout(location = 0) out vec4 fa_frag_color;\nvec3 fa_light_tint;\nbool fa_light_is_area;\nint fa_cl_ndir;\nint fa_cl_slot;\nint fa_cl_local;\n\nvoid fa_inst_load()\n{\n}\n\nvec4 fa_light_texel(int t)\n{\n    return texelFetch(fa_light_tex_fa_shadow_smp, ivec2(t & 1023, t >> 10), 0);\n}\n\nvec4 fa_cluster_texel(vec3 world_pos)\n{\n    bool _1486 = fa_mesh_fs_params[19].x < 0.0;\n    bool _1493;\n    if (!_1486)\n    {\n        _1493 = fa_mesh_fs_params[19].w < 1.0;\n    }\n    else\n    {\n        _1493 = _1486;\n    }\n    bool _1501;\n    if (!_1493)\n    {\n        _1501 = fa_mesh_fs_params[18].x < 1.0;\n    }\n    else\n    {\n        _1501 = _1493;\n    }\n    bool _1508;\n    if (!_1501)\n    {\n        _1508 = fa_mesh_fs_params[18].y < 1.0;\n    }\n    else\n    {\n        _1508 = _1501;\n    }\n    bool _1515;\n    if (!_1508)\n    {\n        _1515 = fa_mesh_fs_params[19].y < 1.0;\n    }\n    else\n    {\n        _1515 = _1508;\n    }\n    if (_1515)\n    {\n        return vec4(0.0);\n    }\n    vec4 _1525 = vec4(world_pos, 1.0);\n    float _1531 = dot(fa_mesh_fs_params[16], _1525);\n    if (!(_1531 > 9.9999999747524270787835121154785e-07))\n    {\n        return vec4(0.0);\n    }\n    vec2 _1553 = vec2(dot(fa_mesh_fs_params[14], _1525), dot(fa_mesh_fs_params[15], _1525)) / vec2(_1531);\n    int _1557 = int(fa_mesh_fs_params[18].x);\n    int _1561 = int(fa_mesh_fs_params[18].y);\n    int param = (int(fa_mesh_fs_params[19].x) + (((clamp(int(floor(log2(max(dot(fa_mesh_fs_params[17].xyz, world_pos) + fa_mesh_fs_params[17].w, fa_mesh_fs_params[18].w) / fa_mesh_fs_params[18].w) * fa_mesh_fs_params[18].z)), 0, int(fa_mesh_fs_params[19].y) - 1) * _1561) + clamp(int(floor(((_1553.y * 0.5) + 0.5) * fa_mesh_fs_params[18].y)), 0, _1561 - 1)) * _1557)) + clamp(int(floor(((_1553.x * 0.5) + 0.5) * fa_mesh_fs_params[18].x)), 0, _1557 - 1);\n    return fa_light_texel(param);\n}\n\nivec2 fa_cluster_lookup(vec3 world_pos)\n{\n    vec3 param = world_pos;\n    vec4 _1637 = fa_cluster_texel(param);\n    return ivec2(int(_1637.x), int(_1637.y));\n}\n\nvoid fa_cluster_begin(vec3 world_pos)\n{\n    fa_cl_ndir = int(fa_mesh_fs_params[19].z);\n    vec3 param = world_pos;\n    ivec2 _4464 = fa_cluster_lookup(param);\n    fa_cl_slot = _4464.x;\n    fa_cl_local = _4464.y;\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nvec3 fa_linear_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_tex_fix(inout vec3 c, float mode)\n{\n    if (mode > 1.5)\n    {\n        vec3 param = c;\n        vec3 _5564 = fa_linear_to_srgb(param);\n        c = _5564;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            vec3 param_1 = c;\n            vec3 _5572 = fa_srgb_to_linear(param_1);\n            c = _5572;\n        }\n    }\n    return c;\n}\n\nvec3 fa_tangent_normal(SurfaceInput i, vec3 m)\n{\n    vec3 _431;\n    if (i.front_facing)\n    {\n        _431 = i.world_normal;\n    }\n    else\n    {\n        _431 = -i.world_normal;\n    }\n    vec3 _455 = normalize(i.world_tangent.xyz - (_431 * dot(_431, i.world_tangent.xyz)));\n    vec3 _482 = normalize(((_455 * m.x) + ((cross(_431, _455) * i.world_tangent.w) * m.y)) + (_431 * m.z));\n    vec3 _485;\n    if (i.front_facing)\n    {\n        _485 = _482;\n    }\n    else\n    {\n        _485 = -_482;\n    }\n    return _485;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    vec4 base_t = texture(fa_tex_fa_smp, i.uv);\n    float param = fa_mesh_fs_params[6].w;\n    float param_1 = 1.0;\n    vec3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    vec3 _5603 = fa_tex_fix(param_2, param_3);\n    vec4 _7018 = base_t;\n    _7018.x = _5603.x;\n    _7018.y = _5603.y;\n    _7018.z = _5603.z;\n    base_t = _7018;\n    vec4 _5617 = (_7018 * fa_mesh_fs_params[2]) * i.vertex_color;\n    vec3 _6856 = i.world_normal;\n    if (fa_mesh_fs_params[6].z > 0.5)\n    {\n        float param_4 = fa_mesh_fs_params[6].w;\n        float param_5 = 16.0;\n        vec3 param_6 = texture(fa_normal_tex_fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        vec3 _5649 = fa_tex_fix(param_6, param_7);\n        vec3 _5652 = (_5649 * 2.0) - vec3(1.0);\n        vec2 _5657 = _5652.xy * fa_mesh_fs_params[6].x;\n        vec3 _7026 = _5652;\n        _7026.x = _5657.x;\n        _7026.y = _5657.y;\n        SurfaceInput param_8 = i;\n        vec3 param_9 = _7026;\n        _6856 = fa_tangent_normal(param_8, param_9);\n    }\n    vec4 mrt = texture(fa_mr_tex_fa_smp, i.uv);\n    float param_10 = fa_mesh_fs_params[6].w;\n    float param_11 = 64.0;\n    vec3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    vec3 _5685 = fa_tex_fix(param_12, param_13);\n    vec4 _7029 = mrt;\n    _7029.x = _5685.x;\n    _7029.y = _5685.y;\n    _7029.z = _5685.z;\n    mrt = _7029;\n    vec4 _5713 = texture(fa_occlusion_tex_fa_smp, i.uv);\n    float param_14 = fa_mesh_fs_params[6].w;\n    float param_15 = 256.0;\n    vec3 param_16 = _5713.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    vec3 _5724 = fa_tex_fix(param_16, param_17);\n    float param_18 = fa_mesh_fs_params[6].w;\n    float param_19 = 4.0;\n    vec3 param_20 = texture(fa_emissive_tex_fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    vec3 _5754 = fa_tex_fix(param_20, param_21);\n    float _6861 = fa_mesh_fs_params[20].x;\n    float _6862 = fa_mesh_fs_params[20].y;\n    float _6865 = fa_mesh_fs_params[20].z;\n    float _6864 = fa_mesh_fs_params[21].w;\n    float _6867 = fa_mesh_fs_params[22].x;\n    if (fa_mesh_fs_params[22].z > 0.5)\n    {\n        if (mod(fa_mesh_fs_params[22].z, 2.0) > 0.5)\n        {\n            _6861 *= _5724.y;\n            _6862 *= _5724.z;\n            _6864 *= _5713.w;\n        }\n        if (fa_mesh_fs_params[22].z > 1.5)\n        {\n            _6865 *= mrt.x;\n            _6867 *= mrt.w;\n        }\n    }\n    return Surface(_5617.xyz, _5617.w, _6856, clamp(fa_mesh_fs_params[5].x * _5685.z, 0.0, 1.0), clamp(fa_mesh_fs_params[5].y * _5685.y, 0.0500000007450580596923828125, 1.0), 1.0 + (fa_mesh_fs_params[6].y * (_5724.x - 1.0)), fa_mesh_fs_params[3].xyz + (fa_mesh_fs_params[4].xyz * _5754), _6861, _6862, fa_mesh_fs_params[21].xyz, _6864, _6865, fa_mesh_fs_params[20].w, _6867, fa_mesh_fs_params[22].y, fa_mesh_fs_params[23].xyz);\n}\n\nvoid surface(SurfaceInput i, inout Surface s)\n{\n    s.emission += (i.vertex_color.xyz * points.data[0].tint.w);\n}\n\nvec4 fa_decal_tile(vec4 rect, vec2 uv, vec2 atlas, vec2 ddx, vec2 ddy)\n{\n    vec2 _1717 = rect.zw - rect.xy;\n    vec2 _1721 = _1717 * atlas;\n    vec2 _1725 = ddx * _1721;\n    vec2 _1729 = ddy * _1721;\n    return textureLod(fa_decal_tex_fa_env_smp, rect.xy + (clamp(uv, vec2(0.0), vec2(1.0)) * _1717), clamp(0.5 * log2(max(max(dot(_1725, _1725), dot(_1729, _1729)), 9.9999999392252902907785028219223e-09)), 0.0, 4.0));\n}\n\nvec3 fa_dc_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_dc_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvoid fa_apply_decals(vec3 world_pos, vec3 geo_normal, inout vec3 albedo, inout vec3 normal)\n{\n    bool _1762 = fa_mesh_fs_params[10].y < 0.5;\n    bool _1769;\n    if (!_1762)\n    {\n        _1769 = fa_mesh_fs_params[10].w < 0.5;\n    }\n    else\n    {\n        _1769 = _1762;\n    }\n    if (_1769)\n    {\n        return;\n    }\n    vec3 _1775 = dFdx(world_pos);\n    vec3 _1778 = dFdy(world_pos);\n    vec3 param = world_pos;\n    vec4 _1782 = fa_cluster_texel(param);\n    int _1786 = int(_1782.w);\n    if (_1786 < 1)\n    {\n        return;\n    }\n    int _1796 = int(fa_mesh_fs_params[10].y + 0.5);\n    int param_1 = _1796;\n    vec4 _1800 = fa_light_texel(param_1);\n    vec2 _1803 = _1800.yz;\n    int _1807 = int(_1800.w);\n    int param_2 = _1796 + 1;\n    vec4 _1812 = fa_light_texel(param_2);\n    float _1813 = _1812.x;\n    int _1819 = int(fa_mesh_fs_params[10].w + 0.5) - 1;\n    int _1823 = int(_1782.z);\n    vec3 _2088;\n    for (int k = 0; k < _1786; k++)\n    {\n        int _1836 = _1823 + k;\n        int param_3 = _1807 + (_1836 >> 2);\n        int _1853 = (_1796 + 2) + (int(fa_light_texel(param_3)[_1836 & 3]) * 7);\n        int param_4 = _1853 + 6;\n        vec4 _1858 = fa_light_texel(param_4);\n        if (((int(_1858.w + 0.5) >> _1819) & 1) == 0)\n        {\n            continue;\n        }\n        int param_5 = _1853;\n        vec4 _1873 = fa_light_texel(param_5);\n        int param_6 = _1853 + 1;\n        vec4 _1878 = fa_light_texel(param_6);\n        int param_7 = _1853 + 2;\n        vec4 _1883 = fa_light_texel(param_7);\n        vec3 _1886 = _1873.xyz;\n        float _1891 = dot(_1886, world_pos) + _1873.w;\n        vec3 _1893 = _1878.xyz;\n        float _1898 = dot(_1893, world_pos) + _1878.w;\n        vec3 _1900 = _1883.xyz;\n        float _1905 = dot(_1900, world_pos) + _1883.w;\n        bool _1910 = abs(_1891) > 0.5;\n        bool _1918;\n        if (!_1910)\n        {\n            _1918 = abs(_1898) > 0.5;\n        }\n        else\n        {\n            _1918 = _1910;\n        }\n        bool _1926;\n        if (!_1918)\n        {\n            _1926 = abs(_1905) > 0.5;\n        }\n        else\n        {\n            _1926 = _1918;\n        }\n        if (_1926)\n        {\n            continue;\n        }\n        float _1941 = clamp(dot(geo_normal, normalize(_1900)) * _1858.z, 0.0, 1.0);\n        if (_1941 <= 0.0)\n        {\n            continue;\n        }\n        float _1961 = (clamp((0.5 - abs(_1905)) * 10.0, 0.0, 1.0) * _1941) * _1858.x;\n        vec2 _1969 = vec2(_1891 + 0.5, 0.5 - _1898);\n        vec2 _1979 = vec2(dot(_1886, _1775), dot(_1893, _1775));\n        vec2 _1989 = vec2(dot(_1886, _1778), dot(_1893, _1778));\n        int param_8 = _1853 + 5;\n        vec4 _1994 = fa_light_texel(param_8);\n        int param_9 = _1853 + 3;\n        vec4 _1999 = fa_light_texel(param_9);\n        int param_10 = _1853 + 4;\n        vec4 _2004 = fa_light_texel(param_10);\n        float tex_a = 1.0;\n        vec3 col = _1994.xyz;\n        bool _2014 = _1999.z > _1999.x;\n        if (_2014)\n        {\n            vec4 param_11 = _1999;\n            vec2 param_12 = _1969;\n            vec2 param_13 = _1803;\n            vec2 param_14 = _1979;\n            vec2 param_15 = _1989;\n            vec4 tx = fa_decal_tile(param_11, param_12, param_13, param_14, param_15);\n            if ((_1813 > 0.5) && (_1813 < 1.5))\n            {\n                vec3 param_16 = tx.xyz;\n                vec3 _2040 = fa_dc_to_linear(param_16);\n                vec4 _6936 = tx;\n                _6936.x = _2040.x;\n                _6936.y = _2040.y;\n                _6936.z = _2040.z;\n                tx = _6936;\n            }\n            col *= tx.xyz;\n            tex_a = tx.w;\n        }\n        albedo = mix(albedo, col, vec3(clamp((_1961 * tex_a) * _1994.w, 0.0, 1.0)));\n        if (_2004.z > _2004.x)\n        {\n            vec4 param_17 = _2004;\n            vec2 param_18 = _1969;\n            vec2 param_19 = _1803;\n            vec2 param_20 = _1979;\n            vec2 param_21 = _1989;\n            vec4 _2084 = fa_decal_tile(param_17, param_18, param_19, param_20, param_21);\n            if (_1813 > 1.5)\n            {\n                vec3 param_22 = _2084.xyz;\n                vec3 _2094 = fa_dc_to_srgb(param_22);\n                _2088 = _2094;\n            }\n            else\n            {\n                _2088 = _2084.xyz;\n            }\n            vec3 _2103 = (_2088 * 2.0) - vec3(1.0);\n            vec2 _2108 = _2103.xy * _1858.y;\n            vec3 _2130 = (normalize(_1886) * _2108.x) + (normalize(_1893) * _2108.y);\n            vec3 _2133 = normalize(normal);\n            normal = normalize(mix(_2133, normalize((_2133 * max(_2103.z, 0.0500000007450580596923828125)) + (_2130 - (_2133 * dot(_2133, _2130)))), vec3(clamp(_1961 * (_2014 ? tex_a : 1.0), 0.0, 1.0))));\n        }\n    }\n}\n\nfloat fa_sheen_albedo(float ndv, float rough)\n{\n    float _3571 = min(sqrt(max(rough - 0.100000001490116119384765625, 0.0) * 1.111111164093017578125) * 6.0, 5.999000072479248046875);\n    float _3578 = min(sqrt(clamp(ndv, 0.0, 1.0)) * 8.0, 7.999000072479248046875);\n    int _3581 = int(_3571);\n    int _3584 = int(_3578);\n    float _3594 = _3578 - float(_3584);\n    int _3649 = (_3581 * 9) + _3584;\n    int _3669 = ((_3581 + 1) * 9) + _3584;\n    return mix(mix(_3645[_3649], _3645[_3649 + 1], _3594), mix(_3645[_3669], _3645[_3669 + 1], _3594), _3571 - float(_3581));\n}\n\nFaLayers fa_layers_setup(SurfaceInput i, Surface s, vec3 n, vec3 v, float metallic, float roughness, inout vec3 f0)\n{\n    bool _6779 = false;\n    float _6780 = 1.0;\n    float _6781 = 1.0;\n    float _6782 = 1.0;\n    float _6783 = 0.0;\n    float _6784 = 0.0;\n    float _6785 = 0.0;\n    float _6786 = 0.0;\n    float _6788 = 1.0;\n    bool _6789 = false;\n    vec3 _6790 = vec3(0.0);\n    float _6791 = 1.0;\n    float _6792 = 1.0;\n    float _6793 = 1.0;\n    float _6794 = 0.0;\n    float _6795 = 0.0;\n    vec3 _6796 = vec3(1.0, 0.0, 0.0);\n    vec3 _6797 = vec3(0.0, 0.0, 1.0);\n    float _6798 = 1.0;\n    float _6799 = 1.0;\n    float _3720 = clamp(s.specular, 0.0, 1.0);\n    float _3724 = clamp(s.ior, 1.0, 3.0);\n    bool _3729 = (_3720 != 1.0) || (_3724 != 1.5);\n    bool _3738;\n    if (!_3729)\n    {\n        _3738 = any(notEqual(s.specular_color, vec3(1.0)));\n    }\n    else\n    {\n        _3738 = _3729;\n    }\n    if (_3738)\n    {\n        float _3746 = (_3724 - 1.0) / (_3724 + 1.0);\n        f0 = mix(min(vec3(_3746 * _3746) * max(s.specular_color, vec3(0.0)), vec3(1.0)) * _3720, s.albedo, vec3(metallic));\n        _6780 = mix(_3720, 1.0, metallic);\n        _6779 = true;\n    }\n    float _3773 = clamp(s.clearcoat, 0.0, 1.0);\n    if (_3773 > 0.0)\n    {\n        float _3781 = clamp(s.clearcoat_roughness, 0.0500000007450580596923828125, 1.0);\n        _6783 = _3773;\n        _6784 = _3781;\n        float _3788 = _3781 * _3781;\n        _6785 = _3788;\n        _6786 = _3788 * _3788;\n        float _3800 = max(dot(i.world_normal, v), 9.9999997473787516355514526367188e-05);\n        _6788 = _3800;\n        _6781 = 1.0 - (_3773 * (0.039999999105930328369140625 + (0.959999978542327880859375 * pow(clamp(1.0 - _3800, 0.0, 1.0), 5.0))));\n        _6779 = true;\n    }\n    vec3 _3819 = max(s.sheen_color, vec3(0.0));\n    float _3828 = max(_3819.x, max(_3819.y, _3819.z));\n    if (_3828 > 0.0)\n    {\n        float _3836 = clamp(s.sheen_roughness, 0.100000001490116119384765625, 1.0);\n        _6789 = true;\n        _6790 = _3819;\n        _6791 = _3836;\n        _6792 = _3836 * _3836;\n        float param = max(dot(n, v), 9.9999997473787516355514526367188e-05);\n        float param_1 = _3836;\n        float _3853 = fa_sheen_albedo(param, param_1);\n        _6794 = _3853;\n        _6793 = 1.0 - min(_3828 * _3853, 1.0);\n        _6779 = true;\n    }\n    _6782 = _6781 * _6793;\n    float _3872 = clamp(s.anisotropy, -1.0, 1.0);\n    if (_3872 != 0.0)\n    {\n        vec3 _3887 = i.world_tangent.xyz - (n * dot(n, i.world_tangent.xyz));\n        vec3 t = _3887;\n        if (dot(_3887, _3887) < 9.9999999392252902907785028219223e-09)\n        {\n            bvec3 _3899 = bvec3(abs(n.y) < 0.9900000095367431640625);\n            t = cross(vec3(_3899.x ? vec3(0.0, 1.0, 0.0).x : vec3(1.0, 0.0, 0.0).x, _3899.y ? vec3(0.0, 1.0, 0.0).y : vec3(1.0, 0.0, 0.0).y, _3899.z ? vec3(0.0, 1.0, 0.0).z : vec3(1.0, 0.0, 0.0).z), n);\n        }\n        vec3 _3903 = t;\n        vec3 _3904 = normalize(_3903);\n        t = _3904;\n        vec3 _3929 = normalize((_3904 * cos(s.anisotropy_rotation)) + ((cross(n, _3904) * ((i.world_tangent.w < 0.0) ? (-1.0) : 1.0)) * sin(s.anisotropy_rotation)));\n        _6796 = _3929;\n        _6797 = cross(n, _3929);\n        float _3939 = roughness * roughness;\n        float _3945 = mix(_3939, 1.0, _3872 * _3872);\n        bool _3947 = _3872 > 0.0;\n        _6798 = _3947 ? _3945 : _3939;\n        _6799 = _3947 ? _3939 : _3945;\n        _6795 = _3872;\n        _6779 = true;\n    }\n    return FaLayers(_6779, _6780, _6781, _6782, _6783, _6784, _6785, _6786, i.world_normal, _6788, _6789, _6790, _6791, _6792, _6793, _6794, _6795, _6796, _6797, _6798, _6799);\n}\n\nvec3 fa_sky_sh_coef(int k)\n{\n    vec3 v = textureLod(fa_env_tex_fa_env_smp, vec3(1.0, 1.0 - (float((2 * (k >> 2)) + 1) * 0.25), 1.0 - (float((2 * (k & 3)) + 1) * 0.25)), 5.0).xyz;\n    if (fa_mesh_fs_params[11].w > 1.5)\n    {\n        v = (v - vec3(0.5)) * 8.0;\n    }\n    return v;\n}\n\nvec3 fa_sh_eval(vec3 c[9], vec3 n)\n{\n    vec3 _3328 = max((((c[0] * 0.2820948064327239990234375) + (((c[1] * (0.3257350027561187744140625 * n.y)) + (c[2] * (0.3257350027561187744140625 * n.z))) + (c[3] * (0.3257350027561187744140625 * n.x)))) + (((c[4] * ((0.2731371223926544189453125 * n.x) * n.y)) + (c[5] * ((0.2731371223926544189453125 * n.y) * n.z))) + (c[6] * (0.078847892582416534423828125 * (((3.0 * n.z) * n.z) - 1.0))))) + ((c[7] * ((0.2731371223926544189453125 * n.x) * n.z)) + (c[8] * (0.13656856119632720947265625 * ((n.x * n.x) - (n.y * n.y))))), vec3(0.0));\n    return _3328;\n}\n\nvec3 fa_ambient_light(vec3 n)\n{\n    if (fa_mesh_fs_params[11].w > 0.5)\n    {\n        vec3 c[9];\n        for (int k = 0; k < 9; k++)\n        {\n            int param = k;\n            c[k] = fa_sky_sh_coef(param);\n        }\n        vec3 param_1[9] = c;\n        vec3 param_2 = n;\n        return fa_sh_eval(param_1, param_2);\n    }\n    return fa_mesh_fs_params[1].xyz;\n}\n\nvec3 fa_indirect_diffuse(vec3 n)\n{\n    if (fa_lm.z > 0.5)\n    {\n        return textureLod(fa_lightmap_fa_env_smp, fa_lm.xy, 0.0).xyz;\n    }\n    vec3 param = n;\n    return fa_ambient_light(param);\n}\n\nint fa_cluster_index(int slot, int n)\n{\n    int param = (int(fa_mesh_fs_params[19].x) + int(fa_mesh_fs_params[19].w)) + ((slot + n) >> 2);\n    vec4 t = fa_light_texel(param);\n    return int(t[(slot + n) & 3]);\n}\n\nint fa_cl_light(int n)\n{\n    if (n < fa_cl_ndir)\n    {\n        return n;\n    }\n    int param = fa_cl_slot;\n    int param_1 = n - fa_cl_ndir;\n    return fa_cluster_index(param, param_1);\n}\n\nint fa_light_base(int li)\n{\n    return li * ((fa_mesh_fs_params[1].w > 4.5) ? 8 : 4);\n}\n\nbool fa_light_baked(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 3;\n    return fa_light_texel(param_1).w > 0.5;\n}\n\nfloat fa_light_type(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 1;\n    return fa_light_texel(param_1).w;\n}\n\nvec4 fa_atlas_fetch(vec2 texel)\n{\n    return textureLod(fa_light_atlas_fa_env_smp, texel / vec2(textureSize(fa_light_atlas_fa_env_smp, 0)), 0.0);\n}\n\nvec3 fa_cookie_sample(vec2 tile_origin, vec2 uv)\n{\n    vec2 param = (tile_origin + vec2(1.0)) + (clamp(uv, vec2(0.0), vec2(1.0)) * 254.0);\n    return fa_atlas_fetch(param).xyz;\n}\n\nvec3 fa_area_point(vec3 c, vec3 axis, vec3 ru, vec3 uu, float hx, float hy, float shape, vec3 p, vec3 r)\n{\n    bool _735 = dot(r, r) > 0.5;\n    if (shape > 1.5)\n    {\n        vec3 _748 = (c - (ru * hx)) - p;\n        vec3 _754 = ru * (2.0 * hx);\n        float _760 = max(dot(_754, _754), 9.9999999392252902907785028219223e-09);\n        float _764 = dot(_748, _754);\n        float t = clamp((-_764) / _760, 0.0, 1.0);\n        if (_735)\n        {\n            float _779 = dot(r, _754);\n            float _785 = _760 - (_779 * _779);\n            if (abs(_785) > (9.9999997473787516355514526367188e-06 * _760))\n            {\n                t = clamp(((dot(r, _748) * _779) - _764) / _785, 0.0, 1.0);\n            }\n        }\n        return (p + _748) + (_754 * t);\n    }\n    vec3 q = p;\n    float _817 = dot(r, axis);\n    bool _825;\n    if (_735)\n    {\n        _825 = abs(_817) > 9.9999997473787516355514526367188e-05;\n    }\n    else\n    {\n        _825 = _735;\n    }\n    if (_825)\n    {\n        float _835 = dot(c - p, axis) / _817;\n        if (_835 > 0.0)\n        {\n            q = p + (r * _835);\n        }\n    }\n    vec3 _848 = q - c;\n    vec2 xy = vec2(dot(_848, ru), dot(_848, uu));\n    if (shape > 0.5)\n    {\n        float _863 = length(xy);\n        if (_863 > hx)\n        {\n            xy *= (hx / _863);\n        }\n    }\n    else\n    {\n        xy = clamp(xy, vec2(-hx, -hy), vec2(hx, hy));\n    }\n    return (c + (ru * xy.x)) + (uu * xy.y);\n}\n\nint fa_cube_face(vec3 d)\n{\n    vec3 _497 = abs(d);\n    float _499 = _497.x;\n    float _501 = _497.y;\n    bool _502 = _499 >= _501;\n    bool _510;\n    if (_502)\n    {\n        _510 = _499 >= _497.z;\n    }\n    else\n    {\n        _510 = _502;\n    }\n    int _511;\n    if (_510)\n    {\n        _511 = (d.x > 0.0) ? 0 : 1;\n    }\n    else\n    {\n        int _526;\n        if (_501 >= _497.z)\n        {\n            _526 = (d.y > 0.0) ? 2 : 3;\n        }\n        else\n        {\n            _526 = (d.z > 0.0) ? 4 : 5;\n        }\n        _511 = _526;\n    }\n    return _511;\n}\n\nvoid fa_cube_face_basis(int f, out vec3 fwd, out vec3 up)\n{\n    if (f == 0)\n    {\n        fwd = vec3(1.0, 0.0, 0.0);\n        up = vec3(0.0, 1.0, 0.0);\n    }\n    else\n    {\n        if (f == 1)\n        {\n            fwd = vec3(-1.0, 0.0, 0.0);\n            up = vec3(0.0, 1.0, 0.0);\n        }\n        else\n        {\n            if (f == 2)\n            {\n                fwd = vec3(0.0, 1.0, 0.0);\n                up = vec3(0.0, 0.0, 1.0);\n            }\n            else\n            {\n                if (f == 3)\n                {\n                    fwd = vec3(0.0, -1.0, 0.0);\n                    up = vec3(0.0, 0.0, -1.0);\n                }\n                else\n                {\n                    if (f == 4)\n                    {\n                        fwd = vec3(0.0, 0.0, 1.0);\n                        up = vec3(0.0, 1.0, 0.0);\n                    }\n                    else\n                    {\n                        fwd = vec3(0.0, 0.0, -1.0);\n                        up = vec3(0.0, 1.0, 0.0);\n                    }\n                }\n            }\n        }\n    }\n}\n\nfloat fa_ies_sample(vec2 tile_origin, vec3 d, vec3 axis, vec3 right, vec3 up)\n{\n    float _655 = dot(d, right);\n    float _659 = dot(d, up);\n    float _670;\n    if (((_655 * _655) + (_659 * _659)) > 1.0000000133514319600180897396058e-10)\n    {\n        _670 = atan(_659, _655) * 0.15915493667125701904296875;\n    }\n    else\n    {\n        _670 = 0.0;\n    }\n    vec2 param = tile_origin + vec2(1.0 + ((_670 - floor(_670)) * 64.0), 1.0 + (acos(clamp(dot(d, axis), -1.0, 1.0)) * 10.18591594696044921875));\n    return fa_atlas_fetch(param).x;\n}\n\nLightSample fa_light_sample_n(int li, vec3 world_pos, vec3 n)\n{\n    int param = li;\n    int _901 = fa_light_base(param);\n    bool _905 = fa_mesh_fs_params[1].w > 4.5;\n    int param_1 = _901;\n    vec4 _909 = fa_light_texel(param_1);\n    int param_2 = _901 + 1;\n    vec4 _914 = fa_light_texel(param_2);\n    float _917 = _914.w;\n    float atten = 1.0;\n    float dist = 0.0;\n    fa_light_tint = vec3(1.0);\n    bool _929 = _905 && (_917 > 2.5);\n    fa_light_is_area = _929;\n    bool _931 = _917 < 0.5;\n    vec3 l;\n    if (_931)\n    {\n        l = normalize(_909.xyz);\n        if (_905)\n        {\n            int param_3 = _901 + 6;\n            vec4 _945 = fa_light_texel(param_3);\n            if (_945.z > 0.5)\n            {\n                int param_4 = _901 + 4;\n                vec4 _955 = fa_light_texel(param_4);\n                int param_5 = _901 + 5;\n                vec4 _960 = fa_light_texel(param_5);\n                vec2 param_6 = _945.xy;\n                vec2 param_7 = fract(vec2(dot(world_pos, _955.xyz) * _955.w, (-dot(world_pos, _960.xyz)) * _960.w) + vec2(0.5));\n                fa_light_tint = fa_cookie_sample(param_6, param_7);\n            }\n        }\n    }\n    else\n    {\n        vec3 _990 = _909.xyz;\n        vec3 _992 = _990 - world_pos;\n        vec3 to_light = _992;\n        float _995 = length(_992);\n        float reach = _995;\n        bool front = true;\n        if (_929)\n        {\n            int param_8 = _901 + 7;\n            reach = max(_995 - fa_light_texel(param_8).w, 0.0);\n            int param_9 = _901 + 4;\n            vec4 _1019 = fa_light_texel(param_9);\n            int param_10 = _901 + 5;\n            vec4 _1024 = fa_light_texel(param_10);\n            int param_11 = _901 + 6;\n            vec4 _1029 = fa_light_texel(param_11);\n            float _1030 = _1029.w;\n            int param_12 = _901 + 2;\n            vec3 _1037 = normalize(fa_light_texel(param_12).xyz);\n            bool _1039 = _1030 > 1.5;\n            bool _1047;\n            if (!_1039)\n            {\n                _1047 = dot(_1037, to_light) < 0.0;\n            }\n            else\n            {\n                _1047 = _1039;\n            }\n            front = _1047;\n            vec3 r = vec3(0.0);\n            vec3 _1056 = fa_mesh_fs_params[0].xyz - world_pos;\n            bool _1060 = dot(n, n) > 0.5;\n            bool _1068;\n            if (_1060)\n            {\n                _1068 = dot(_1056, _1056) > 9.9999999600419720025001879548654e-13;\n            }\n            else\n            {\n                _1068 = _1060;\n            }\n            if (_1068)\n            {\n                r = reflect(-normalize(_1056), normalize(n));\n            }\n            vec3 param_13 = _990;\n            vec3 param_14 = _1037;\n            vec3 param_15 = _1019.xyz;\n            vec3 param_16 = _1024.xyz;\n            float param_17 = _1019.w;\n            float param_18 = _1024.w;\n            float param_19 = _1030;\n            vec3 param_20 = world_pos;\n            vec3 param_21 = r;\n            to_light = fa_area_point(param_13, param_14, param_15, param_16, param_17, param_18, param_19, param_20, param_21) - world_pos;\n        }\n        float _1104 = length(to_light);\n        dist = _1104;\n        l = to_light / vec3(max(_1104, 9.9999997473787516355514526367188e-05));\n        float _1118 = reach / max(_909.w, 0.001000000047497451305389404296875);\n        float _1124 = clamp(1.0 - (_1118 * _1118), 0.0, 1.0);\n        float _1126;\n        if (front)\n        {\n            _1126 = _1124 * _1124;\n        }\n        else\n        {\n            _1126 = 0.0;\n        }\n        atten = _1126;\n        bool _1137 = _917 < 2.5;\n        if ((_917 > 1.5) && _1137)\n        {\n            int param_22 = _901 + 2;\n            vec4 _1145 = fa_light_texel(param_22);\n            float _1155 = _1145.w;\n            int param_23 = _901 + 3;\n            vec4 _1160 = fa_light_texel(param_23);\n            float _1161 = _1160.x;\n            float cos_inner = _1161;\n            if (_1161 > 1.5)\n            {\n                cos_inner = mix(_1155, 1.0, 0.25);\n            }\n            atten *= smoothstep(_1155, cos_inner, dot(-l, normalize(_1145.xyz)));\n        }\n        if (_905 && (_917 < 1.5))\n        {\n            int param_24 = _901 + 6;\n            vec4 _1185 = fa_light_texel(param_24);\n            if (_1185.z > 0.5)\n            {\n                vec3 _1193 = -to_light;\n                int param_25 = _901 + 4;\n                int param_26 = _901 + 5;\n                vec3 _1207 = fa_light_texel(param_25).xyz;\n                vec3 _1211 = fa_light_texel(param_26).xyz;\n                vec3 _1220 = vec3(dot(_1193, _1207), dot(_1193, _1211), dot(_1193, cross(_1207, _1211)));\n                vec3 param_27 = _1220;\n                int _1224 = fa_cube_face(param_27);\n                int param_28 = _1224;\n                vec3 param_29;\n                vec3 param_30;\n                fa_cube_face_basis(param_28, param_29, param_30);\n                vec2 _1251 = vec2(dot(_1220, cross(param_29, param_30)), dot(_1220, param_30)) / vec2(max(dot(_1220, param_29), 9.9999997473787516355514526367188e-05));\n                int _1255 = _1224 / 3;\n                vec2 param_31 = _1185.xy + (vec2(float(_1224 - (_1255 * 3)), float(_1255)) * 256.0);\n                vec2 param_32 = vec2(0.5 + (0.5 * _1251.x), 0.5 - (0.5 * _1251.y));\n                fa_light_tint = fa_cookie_sample(param_31, param_32);\n            }\n            int param_33 = _901 + 7;\n            vec4 _1285 = fa_light_texel(param_33);\n            if (_1285.z > 0.5)\n            {\n                int param_34 = _901 + 2;\n                int param_35 = _901 + 4;\n                int param_36 = _901 + 5;\n                vec2 param_37 = _1285.xy;\n                vec3 param_38 = -l;\n                vec3 param_39 = normalize(fa_light_texel(param_34).xyz);\n                vec3 param_40 = fa_light_texel(param_35).xyz;\n                vec3 param_41 = fa_light_texel(param_36).xyz;\n                atten *= fa_ies_sample(param_37, param_38, param_39, param_40, param_41);\n            }\n        }\n        else\n        {\n            if (_905 && _1137)\n            {\n                int param_42 = _901 + 6;\n                vec4 _1332 = fa_light_texel(param_42);\n                int param_43 = _901 + 7;\n                vec4 _1337 = fa_light_texel(param_43);\n                bool _1340 = _1332.z > 0.5;\n                bool _1347;\n                if (!_1340)\n                {\n                    _1347 = _1337.z > 0.5;\n                }\n                else\n                {\n                    _1347 = _1340;\n                }\n                if (_1347)\n                {\n                    int param_44 = _901 + 2;\n                    vec4 _1354 = fa_light_texel(param_44);\n                    vec3 _1358 = normalize(_1354.xyz);\n                    int param_45 = _901 + 4;\n                    vec4 _1363 = fa_light_texel(param_45);\n                    int param_46 = _901 + 5;\n                    vec4 _1368 = fa_light_texel(param_46);\n                    if (_1340)\n                    {\n                        vec3 _1376 = -to_light;\n                        float _1383 = _1354.w;\n                        float _1399 = 0.5 / max(dot(_1376, _1358) * (sqrt(max(1.0 - (_1383 * _1383), 0.0)) / max(_1383, 0.001000000047497451305389404296875)), 9.9999997473787516355514526367188e-05);\n                        vec2 param_47 = _1332.xy;\n                        vec2 param_48 = vec2(0.5 + (dot(_1376, _1363.xyz) * _1399), 0.5 - (dot(_1376, _1368.xyz) * _1399));\n                        fa_light_tint = fa_cookie_sample(param_47, param_48);\n                    }\n                    if (_1337.z > 0.5)\n                    {\n                        vec2 param_49 = _1337.xy;\n                        vec3 param_50 = -l;\n                        vec3 param_51 = _1358;\n                        vec3 param_52 = _1363.xyz;\n                        vec3 param_53 = _1368.xyz;\n                        atten *= fa_ies_sample(param_49, param_50, param_51, param_52, param_53);\n                    }\n                }\n            }\n        }\n    }\n    vec3 _6767 = _914.xyz * atten;\n    if (_905)\n    {\n        _6767 *= fa_light_tint;\n    }\n    int _1468;\n    if (_931)\n    {\n        _1468 = 0;\n    }\n    else\n    {\n        _1468 = ((_917 > 1.5) && (_917 < 2.5)) ? 2 : 1;\n    }\n    return LightSample(l, _6767, atten, 1.0, dist, _1468);\n}\n\nfloat fa_shadow_split_at(int i)\n{\n    float _2205;\n    if (i == 0)\n    {\n        _2205 = fa_shadows[24].x;\n    }\n    else\n    {\n        float _2221;\n        if (i == 1)\n        {\n            _2221 = fa_shadows[24].y;\n        }\n        else\n        {\n            float _2229;\n            if (i == 2)\n            {\n                _2229 = fa_shadows[24].z;\n            }\n            else\n            {\n                _2229 = fa_shadows[24].w;\n            }\n            _2221 = _2229;\n        }\n        _2205 = _2221;\n    }\n    return _2205;\n}\n\nfloat fa_shadow_depth(inout vec2 uv, vec4 rect)\n{\n    uv = clamp(uv, rect.xy, rect.zw);\n    return textureLod(fa_shadow_tex_fa_shadow_smp, uv, 0.0).x;\n}\n\nfloat fa_shadow_fetch(vec2 uv, vec4 rect, vec3 conv)\n{\n    vec2 param = uv;\n    vec4 param_1 = rect;\n    float _2262 = fa_shadow_depth(param, param_1);\n    float _2266;\n    if (conv.x < 0.5)\n    {\n        _2266 = _2262;\n    }\n    else\n    {\n        _2266 = (conv.y * conv.z) / (conv.z - (_2262 * (conv.z - conv.y)));\n    }\n    return _2266;\n}\n\nfloat fa_shadow_noise()\n{\n    return fract(52.98291778564453125 * fract(dot(gl_FragCoord.xy, vec2(0.067110560834407806396484375, 0.005837149918079376220703125))));\n}\n\nvec2 fa_shadow_vogel(int k, int n, float phi)\n{\n    float _2193 = (float(k) * 2.3999631404876708984375) + phi;\n    return vec2(cos(_2193), sin(_2193)) * sqrt((float(k) + 0.5) / float(n));\n}\n\nfloat fa_shadow_filter(vec2 uv, vec4 rect, float zr, float texel_m, float unit, float reach, float plane, vec3 conv, int mode, float k)\n{\n    if (mode == 1)\n    {\n        vec2 param = uv;\n        vec4 param_1 = rect;\n        vec3 param_2 = conv;\n        return float(zr <= fa_shadow_fetch(param, param_1, param_2));\n    }\n    float _2312 = fa_shadow_noise() * 6.283185482025146484375;\n    float radius = 1.5;\n    if (mode == 2)\n    {\n        float _2321;\n        if (k < 0.0)\n        {\n            _2321 = (-k) / max(zr, 0.100000001490116119384765625);\n        }\n        else\n        {\n            _2321 = k;\n        }\n        float _2341 = clamp((_2321 * reach) / texel_m, 3.0, 12.0);\n        float sum = 0.0;\n        float cnt = 0.0;\n        for (int i = 0; i < 16; i++)\n        {\n            int param_3 = i;\n            int param_4 = 16;\n            float param_5 = _2312;\n            vec2 _2360 = fa_shadow_vogel(param_3, param_4, param_5) * _2341;\n            vec2 param_6 = uv + (_2360 * fa_shadows[26].zw);\n            vec4 param_7 = rect;\n            vec3 param_8 = conv;\n            float _2372 = fa_shadow_fetch(param_6, param_7, param_8);\n            if (_2372 < (zr - (length(_2360) * plane)))\n            {\n                sum += _2372;\n                cnt += 1.0;\n            }\n        }\n        if (cnt < 0.5)\n        {\n            return 1.0;\n        }\n        float _2398 = sum / cnt;\n        float _2408;\n        if (k < 0.0)\n        {\n            _2408 = (-k) / max(_2398, 0.0500000007450580596923828125);\n        }\n        else\n        {\n            _2408 = k;\n        }\n        radius = clamp(((max(zr - _2398, 0.0) * unit) * _2408) / texel_m, 1.5, 16.0);\n    }\n    float lit = 0.0;\n    int _2430 = (mode == 2) ? 24 : 16;\n    for (int i_1 = 0; i_1 < _2430; i_1++)\n    {\n        int param_9 = i_1;\n        int param_10 = _2430;\n        float param_11 = _2312;\n        vec2 _2449 = fa_shadow_vogel(param_9, param_10, param_11) * radius;\n        vec2 param_12 = uv + (_2449 * fa_shadows[26].zw);\n        vec4 param_13 = rect;\n        vec3 param_14 = conv;\n        lit += float((zr - (length(_2449) * plane)) <= fa_shadow_fetch(param_12, param_13, param_14));\n    }\n    return lit / float(_2430);\n}\n\nfloat fa_shadow_cascade(int ci, vec3 world, vec3 n, vec3 l)\n{\n    float _2491 = max(fa_shadows[ci * 1 + 20].y, 0.001000000047497451305389404296875);\n    float _2496 = clamp(dot(n, l), 0.0, 1.0);\n    float _2502 = sqrt(1.0 - (_2496 * _2496));\n    float _2509 = min(_2502 / max(_2496, 0.20000000298023223876953125), 4.0);\n    float _2514;\n    if (fa_shadows[26].y > 0.0)\n    {\n        _2514 = fa_shadows[26].y;\n    }\n    else\n    {\n        _2514 = 1.5 * fa_shadows[ci * 1 + 20].x;\n    }\n    vec4 _2539 = mat4(fa_shadows[ci * 4 + 0], fa_shadows[ci * 4 + 1], fa_shadows[ci * 4 + 2], fa_shadows[ci * 4 + 3]) * vec4(world + (n * (_2514 * _2502)), 1.0);\n    float _2546 = _2539.x;\n    bool _2549 = _2546 < fa_shadows[ci * 1 + 16].x;\n    bool _2558;\n    if (!_2549)\n    {\n        _2558 = _2546 > fa_shadows[ci * 1 + 16].z;\n    }\n    else\n    {\n        _2558 = _2549;\n    }\n    bool _2567;\n    if (!_2558)\n    {\n        _2567 = _2539.y < fa_shadows[ci * 1 + 16].y;\n    }\n    else\n    {\n        _2567 = _2558;\n    }\n    bool _2576;\n    if (!_2567)\n    {\n        _2576 = _2539.y > fa_shadows[ci * 1 + 16].w;\n    }\n    else\n    {\n        _2576 = _2567;\n    }\n    bool _2583;\n    if (!_2576)\n    {\n        _2583 = _2539.z > 1.0;\n    }\n    else\n    {\n        _2583 = _2576;\n    }\n    if (_2583)\n    {\n        return -1.0;\n    }\n    float _2591;\n    if (fa_shadows[26].x > 0.0)\n    {\n        _2591 = fa_shadows[26].x;\n    }\n    else\n    {\n        _2591 = 1.5 * fa_shadows[ci * 1 + 20].x;\n    }\n    vec2 param = _2539.xy;\n    vec4 param_1 = fa_shadows[ci * 1 + 16];\n    float param_2 = _2539.z - ((_2591 * (1.0 + (0.5 * _2509))) / _2491);\n    float param_3 = fa_shadows[ci * 1 + 20].x;\n    float param_4 = _2491;\n    float param_5 = _2491 * 0.25;\n    float param_6 = ((fa_shadows[ci * 1 + 20].x * min(_2509, 3.0)) * 0.5) / _2491;\n    vec3 param_7 = vec3(0.0);\n    int param_8 = int(fa_shadows[25].z + 0.5);\n    float param_9 = fa_shadows[25].w;\n    return fa_shadow_filter(param, param_1, param_2, param_3, param_4, param_5, param_6, param_7, param_8, param_9);\n}\n\nfloat fa_shadow_sun(vec3 world, vec3 n, vec3 l)\n{\n    if (fa_mesh_fs_params[5].z < 0.5)\n    {\n        return 1.0;\n    }\n    int _2969 = int(fa_shadows[25].x + 0.5);\n    if (_2969 < 1)\n    {\n        return 1.0;\n    }\n    float _2984 = dot(world - fa_shadows[27].xyz, fa_shadows[28].xyz);\n    int param = _2969 - 1;\n    if (_2984 > fa_shadow_split_at(param))\n    {\n        return 1.0;\n    }\n    int ci = 0;\n    bool _2996 = _2969 > 1;\n    bool _3003;\n    if (_2996)\n    {\n        _3003 = _2984 > fa_shadows[24].x;\n    }\n    else\n    {\n        _3003 = _2996;\n    }\n    if (_3003)\n    {\n        ci = 1;\n    }\n    bool _3007 = _2969 > 2;\n    bool _3014;\n    if (_3007)\n    {\n        _3014 = _2984 > fa_shadows[24].y;\n    }\n    else\n    {\n        _3014 = _3007;\n    }\n    if (_3014)\n    {\n        ci = 2;\n    }\n    bool _3018 = _2969 > 3;\n    bool _3025;\n    if (_3018)\n    {\n        _3025 = _2984 > fa_shadows[24].z;\n    }\n    else\n    {\n        _3025 = _3018;\n    }\n    if (_3025)\n    {\n        ci = 3;\n    }\n    float s = -1.0;\n    for (int k = 0; k < 4; k++)\n    {\n        if (ci >= _2969)\n        {\n            break;\n        }\n        int param_1 = ci;\n        vec3 param_2 = world;\n        vec3 param_3 = n;\n        vec3 param_4 = l;\n        float _3051 = fa_shadow_cascade(param_1, param_2, param_3, param_4);\n        s = _3051;\n        if (_3051 >= 0.0)\n        {\n            break;\n        }\n        ci++;\n    }\n    if (s < 0.0)\n    {\n        return 1.0;\n    }\n    if (fa_shadows[25].y > 0.0)\n    {\n        float _3076;\n        if (ci > 0)\n        {\n            int param_5 = ci - 1;\n            _3076 = fa_shadow_split_at(param_5);\n        }\n        else\n        {\n            _3076 = fa_shadows[28].w;\n        }\n        int param_6 = ci;\n        float _3095 = fa_shadows[25].y * max(fa_shadow_split_at(param_6) - _3076, 9.9999997473787516355514526367188e-05);\n        int param_7 = ci;\n        float _3106 = clamp((_2984 - (fa_shadow_split_at(param_7) - _3095)) / _3095, 0.0, 1.0);\n        if (_3106 > 0.0)\n        {\n            float s2 = 1.0;\n            if ((ci + 1) < _2969)\n            {\n                int param_8 = ci + 1;\n                vec3 param_9 = world;\n                vec3 param_10 = n;\n                vec3 param_11 = l;\n                float _3127 = fa_shadow_cascade(param_8, param_9, param_10, param_11);\n                s2 = _3127;\n                if (_3127 < 0.0)\n                {\n                    s2 = s;\n                }\n            }\n            s = mix(s, s2, _3106);\n        }\n    }\n    return s;\n}\n\nfloat fa_shadow_factor(vec3 n, vec3 l)\n{\n    vec3 param = fa_world_pos;\n    vec3 param_1 = n;\n    vec3 param_2 = l;\n    return fa_shadow_sun(param, param_1, param_2);\n}\n\nfloat fa_shadow_local(int li, vec3 lpos, vec3 world, vec3 n, vec3 l)\n{\n    bool _2649 = fa_mesh_fs_params[5].z < 0.5;\n    bool _2656;\n    if (!_2649)\n    {\n        _2656 = fa_shadows[29].x < 0.5;\n    }\n    else\n    {\n        _2656 = _2649;\n    }\n    if (_2656)\n    {\n        return 1.0;\n    }\n    int param = (int(fa_shadows[29].x + 0.5) - 1) + li;\n    vec4 _2669 = fa_light_texel(param);\n    float _2670 = _2669.x;\n    if (_2670 < 0.0)\n    {\n        return 1.0;\n    }\n    int _2679 = int(_2670 + 0.5);\n    int param_1 = _2679;\n    vec4 _2683 = fa_light_texel(param_1);\n    int param_2 = _2679 + 1;\n    vec4 _2688 = fa_light_texel(param_2);\n    float fade = 1.0;\n    float _2691 = _2683.y;\n    if (_2691 > 0.0)\n    {\n        float _2708 = 1.0 - smoothstep(0.75 * _2691, _2691, length(world - fa_shadows[27].xyz));\n        fade = _2708;\n        if (_2708 <= 0.0)\n        {\n            return 1.0;\n        }\n    }\n    int face = 0;\n    if (_2683.x > 1.5)\n    {\n        vec3 param_3 = world - lpos;\n        face = fa_cube_face(param_3);\n    }\n    int _2732 = (_2679 + 2) + (face * 6);\n    int param_4 = _2732;\n    int param_5 = _2732 + 1;\n    int param_6 = _2732 + 3;\n    vec4 _2746 = fa_light_texel(param_6);\n    int param_7 = _2732 + 4;\n    vec4 _2751 = fa_light_texel(param_7);\n    int param_8 = _2732 + 5;\n    vec4 _2756 = fa_light_texel(param_8);\n    float _2768 = _2756.x * max(dot(_2746, vec4(world, 1.0)), 0.001000000047497451305389404296875);\n    float _2773 = clamp(dot(n, l), 0.0, 1.0);\n    float _2796 = clamp(dot(n, _2746.xyz), -1.0, 1.0);\n    float _2815 = min(sqrt(1.0 - (_2796 * _2796)) / max(abs(dot(n, world - lpos)) / max(dot(_2746, vec4(world, 1.0)), 0.001000000047497451305389404296875), 0.20000000298023223876953125), 4.0);\n    float _2818 = _2688.y;\n    float _2820;\n    if (_2818 > 0.0)\n    {\n        _2820 = _2818;\n    }\n    else\n    {\n        _2820 = 1.5 * _2768;\n    }\n    vec4 _2840 = vec4(world + (n * (_2820 * sqrt(1.0 - (_2773 * _2773)))), 1.0);\n    float _2844 = dot(_2746, _2840);\n    float _2847 = _2756.y;\n    if (_2844 < _2847)\n    {\n        return 1.0;\n    }\n    vec2 _2862 = vec2(dot(fa_light_texel(param_4), _2840), dot(fa_light_texel(param_5), _2840)) / vec2(_2844);\n    float _2864 = _2862.x;\n    bool _2867 = _2864 < _2751.x;\n    bool _2876;\n    if (!_2867)\n    {\n        _2876 = _2864 > _2751.z;\n    }\n    else\n    {\n        _2876 = _2867;\n    }\n    bool _2885;\n    if (!_2876)\n    {\n        _2885 = _2862.y < _2751.y;\n    }\n    else\n    {\n        _2885 = _2876;\n    }\n    bool _2894;\n    if (!_2885)\n    {\n        _2894 = _2862.y > _2751.w;\n    }\n    else\n    {\n        _2894 = _2885;\n    }\n    if (_2894)\n    {\n        return 1.0;\n    }\n    float _2900 = _2688.x;\n    float _2902;\n    if (_2900 > 0.0)\n    {\n        _2902 = _2900;\n    }\n    else\n    {\n        _2902 = 1.5 * _2768;\n    }\n    vec2 param_9 = _2862;\n    vec4 param_10 = _2751;\n    float param_11 = _2844 - (_2902 * (1.0 + (0.5 * _2815)));\n    float param_12 = _2768;\n    float param_13 = 1.0;\n    float param_14 = _2756.z * 0.25;\n    float param_15 = (_2768 * min(_2815, 3.0)) * 0.5;\n    vec3 param_16 = vec3(1.0, _2847, _2756.z);\n    int param_17 = int(_2683.z + 0.5);\n    float param_18 = _2683.w;\n    return mix(1.0, fa_shadow_filter(param_9, param_10, param_11, param_12, param_13, param_14, param_15, param_16, param_17, param_18), fade);\n}\n\nLightSample fa_light_shadowed(int li, vec3 world_pos, vec3 gn)\n{\n    bool _4491 = fa_lm.z > 0.5;\n    bool _4497;\n    if (_4491)\n    {\n        int param = li;\n        _4497 = fa_light_baked(param);\n    }\n    else\n    {\n        _4497 = _4491;\n    }\n    if (_4497)\n    {\n        int param_1 = li;\n        return LightSample(vec3(0.0, 1.0, 0.0), vec3(0.0), 0.0, 1.0, 0.0, int(fa_light_type(param_1) + 0.5));\n    }\n    int param_2 = li;\n    vec3 param_3 = world_pos;\n    vec3 param_4 = gn;\n    LightSample _4521 = fa_light_sample_n(param_2, param_3, param_4);\n    vec3 _6836 = _4521.color;\n    float _6838 = _4521.shadow;\n    if ((_4521.type == 0) && (li == 0))\n    {\n        vec3 param_5 = gn;\n        vec3 param_6 = _4521.direction;\n        float _4535 = fa_shadow_factor(param_5, param_6);\n        _6838 = _4535;\n        _6836 *= _4535;\n    }\n    else\n    {\n        bool _4546 = _4521.type != 0;\n        bool _4552;\n        if (_4546)\n        {\n            _4552 = _4521.attenuation > 0.0;\n        }\n        else\n        {\n            _4552 = _4546;\n        }\n        if (_4552)\n        {\n            int param_7 = li;\n            int param_8 = fa_light_base(param_7);\n            int param_9 = li;\n            vec3 param_10 = fa_light_texel(param_8).xyz;\n            vec3 param_11 = world_pos;\n            vec3 param_12 = gn;\n            vec3 param_13 = _4521.direction;\n            float _4571 = fa_shadow_local(param_9, param_10, param_11, param_12, param_13);\n            _6838 = _4571;\n            _6836 *= _4571;\n        }\n    }\n    return LightSample(_4521.direction, _6836, _4521.attenuation, _6838, _4521._distance, _4521.type);\n}\n\nvec3 fa_ltc_tangent(vec3 n, vec3 v)\n{\n    vec3 _4611 = v - (n * dot(v, n));\n    vec3 t = _4611;\n    float _4615 = dot(_4611, _4611);\n    float l2 = _4615;\n    if (_4615 < 1.0000000133514319600180897396058e-10)\n    {\n        vec3 _4625;\n        if (abs(n.z) < 0.999000012874603271484375)\n        {\n            _4625 = cross(n, vec3(0.0, 0.0, 1.0));\n        }\n        else\n        {\n            _4625 = cross(n, vec3(1.0, 0.0, 0.0));\n        }\n        t = _4625;\n        l2 = dot(_4625, _4625);\n    }\n    return t * inversesqrt(l2);\n}\n\nvec3 fa_ltc_local(vec3 t1, vec3 n, vec3 p)\n{\n    return vec3(dot(t1, p), dot(cross(n, t1), p), dot(n, p));\n}\n\nvec3 fa_ltc_edge_vector(vec3 a, vec3 b)\n{\n    float _4660 = dot(a, a);\n    float _4664 = dot(b, b);\n    if ((_4660 < 1.0000000195414813782625560981111e-24) || (_4664 < 1.0000000195414813782625560981111e-24))\n    {\n        return vec3(0.0);\n    }\n    vec3 _4678 = a * inversesqrt(_4660);\n    vec3 _4683 = b * inversesqrt(_4664);\n    float _4687 = dot(_4678, _4683);\n    float _4690 = abs(_4687);\n    float g = (((((((((((0.0416471660137176513671875 * _4690) - 0.1924748718738555908203125) * _4690) + 0.4179156124591827392578125) * _4690) - 0.616057217121124267578125) * _4690) + 0.777722418308258056640625) * _4690) - 0.999542415142059326171875) * _4690) + 1.570791721343994140625;\n    if (_4687 < 0.0)\n    {\n        g = (3.1415927410125732421875 * inversesqrt(max(1.0 - (_4687 * _4687), 1.0000000116860974230803549289703e-07))) - g;\n    }\n    return cross(_4678, _4683) * g;\n}\n\nvoid fa_ltc_clip_edge(vec3 a, vec3 b, inout vec3 sum, inout vec3 leave, inout vec3 enter, inout vec2 seen)\n{\n    bool _4747 = a.z > 0.0;\n    bool _4751 = b.z > 0.0;\n    if (_4747 && _4751)\n    {\n        vec3 param = a;\n        vec3 param_1 = b;\n        sum += fa_ltc_edge_vector(param, param_1);\n    }\n    else\n    {\n        if (_4747 != _4751)\n        {\n            vec3 _4786 = a + ((b - a) * (a.z / (a.z - b.z)));\n            _4786.z = 0.0;\n            if (_4747)\n            {\n                vec3 param_2 = a;\n                vec3 param_3 = _4786;\n                sum += fa_ltc_edge_vector(param_2, param_3);\n                leave = _4786;\n                seen.x = 1.0;\n            }\n            else\n            {\n                vec3 param_4 = _4786;\n                vec3 param_5 = b;\n                sum += fa_ltc_edge_vector(param_4, param_5);\n                enter = _4786;\n                seen.y = 1.0;\n            }\n        }\n    }\n}\n\nfloat fa_ltc_quad(vec4 abcd, vec3 p0, vec3 p1, vec3 p2, vec3 p3)\n{\n    vec3 _4835 = vec3((abcd.x * p0.x) + (abcd.y * p0.z), p0.y, (abcd.z * p0.x) + (abcd.w * p0.z));\n    vec3 _4861 = vec3((abcd.x * p1.x) + (abcd.y * p1.z), p1.y, (abcd.z * p1.x) + (abcd.w * p1.z));\n    vec3 _4887 = vec3((abcd.x * p2.x) + (abcd.y * p2.z), p2.y, (abcd.z * p2.x) + (abcd.w * p2.z));\n    vec3 _4913 = vec3((abcd.x * p3.x) + (abcd.y * p3.z), p3.y, (abcd.z * p3.x) + (abcd.w * p3.z));\n    vec3 sum = vec3(0.0);\n    vec3 leave = vec3(0.0);\n    vec3 enter = vec3(0.0);\n    vec3 param = _4835;\n    vec3 param_1 = _4861;\n    vec3 param_2 = vec3(0.0);\n    vec3 param_3 = vec3(0.0);\n    vec3 param_4 = vec3(0.0);\n    vec2 param_5 = vec2(0.0);\n    fa_ltc_clip_edge(param, param_1, param_2, param_3, param_4, param_5);\n    sum = param_2;\n    leave = param_3;\n    enter = param_4;\n    vec3 param_6 = _4861;\n    vec3 param_7 = _4887;\n    vec3 param_8 = param_2;\n    vec3 param_9 = param_3;\n    vec3 param_10 = param_4;\n    vec2 param_11 = param_5;\n    fa_ltc_clip_edge(param_6, param_7, param_8, param_9, param_10, param_11);\n    sum = param_8;\n    leave = param_9;\n    enter = param_10;\n    vec3 param_12 = _4887;\n    vec3 param_13 = _4913;\n    vec3 param_14 = param_8;\n    vec3 param_15 = param_9;\n    vec3 param_16 = param_10;\n    vec2 param_17 = param_11;\n    fa_ltc_clip_edge(param_12, param_13, param_14, param_15, param_16, param_17);\n    sum = param_14;\n    leave = param_15;\n    enter = param_16;\n    vec3 param_18 = _4913;\n    vec3 param_19 = _4835;\n    vec3 param_20 = param_14;\n    vec3 param_21 = param_15;\n    vec3 param_22 = param_16;\n    vec2 param_23 = param_17;\n    fa_ltc_clip_edge(param_18, param_19, param_20, param_21, param_22, param_23);\n    sum = param_20;\n    leave = param_21;\n    enter = param_22;\n    if ((param_23.x * param_23.y) > 0.5)\n    {\n        vec3 param_24 = leave;\n        vec3 param_25 = enter;\n        sum += fa_ltc_edge_vector(param_24, param_25);\n    }\n    return sum.z * 0.15915493667125701904296875;\n}\n\nfloat fa_ltc_rect(vec4 abcd, vec3 center, vec3 ex, vec3 ey)\n{\n    vec4 param = abcd;\n    vec3 param_1 = (center - ex) - ey;\n    vec3 param_2 = (center + ex) - ey;\n    vec3 param_3 = (center + ex) + ey;\n    vec3 param_4 = (center - ex) + ey;\n    return abs(fa_ltc_quad(param, param_1, param_2, param_3, param_4));\n}\n\nfloat fa_area_form(vec4 m, float shape, vec3 pc, vec3 ex, vec3 ey)\n{\n    if ((shape < 0.5) || (shape > 1.5))\n    {\n        vec4 param = m;\n        vec3 param_1 = pc;\n        vec3 param_2 = ex;\n        vec3 param_3 = ey;\n        return fa_ltc_rect(param, param_1, param_2, param_3);\n    }\n    vec3 _5063 = (pc + (ex * 0.92387950420379638671875)) + (ey * 0.3826834261417388916015625);\n    vec3 _5087 = (pc - (ex * 0.92387950420379638671875)) + (ey * 0.3826834261417388916015625);\n    vec3 _5103 = (pc - (ex * 0.3826834261417388916015625)) - (ey * 0.92387950420379638671875);\n    vec4 param_4 = m;\n    vec3 param_5 = _5063;\n    vec3 param_6 = (pc + (ex * 0.3826834261417388916015625)) + (ey * 0.92387950420379638671875);\n    vec3 param_7 = (pc - (ex * 0.3826834261417388916015625)) + (ey * 0.92387950420379638671875);\n    vec3 param_8 = _5087;\n    vec4 param_9 = m;\n    vec3 param_10 = _5063;\n    vec3 param_11 = _5087;\n    vec3 param_12 = (pc - (ex * 0.92387950420379638671875)) - (ey * 0.3826834261417388916015625);\n    vec3 param_13 = _5103;\n    vec4 param_14 = m;\n    vec3 param_15 = _5063;\n    vec3 param_16 = _5103;\n    vec3 param_17 = (pc + (ex * 0.3826834261417388916015625)) - (ey * 0.92387950420379638671875);\n    vec3 param_18 = (pc + (ex * 0.92387950420379638671875)) - (ey * 0.3826834261417388916015625);\n    return abs((fa_ltc_quad(param_4, param_5, param_6, param_7, param_8) + fa_ltc_quad(param_9, param_10, param_11, param_12, param_13)) + fa_ltc_quad(param_14, param_15, param_16, param_17, param_18));\n}\n\nvec2 fa_ltc_uv(float roughness, float ndv)\n{\n    return ((vec2(clamp((roughness - 0.0500000007450580596923828125) * 1.0526316165924072265625, 0.0, 1.0), sqrt(clamp(1.0 - ndv, 0.0, 1.0))) * 63.0) + vec2(0.5)) * vec2(0.015625);\n}\n\nvec3 fa_area_shade(int li, vec3 world_pos, vec3 n, vec3 v, vec3 diffuse_color, vec3 f0, float f90, float roughness, float ndv, float window)\n{\n    int param = li;\n    int _5161 = fa_light_base(param);\n    int param_1 = _5161;\n    int param_2 = _5161 + 1;\n    int param_3 = _5161 + 2;\n    int param_4 = _5161 + 4;\n    vec4 _5183 = fa_light_texel(param_4);\n    int param_5 = _5161 + 5;\n    vec4 _5188 = fa_light_texel(param_5);\n    int param_6 = _5161 + 6;\n    vec4 _5193 = fa_light_texel(param_6);\n    float _5194 = _5193.w;\n    vec3 _5199 = fa_light_texel(param_1).xyz - world_pos;\n    bool _5201 = _5194 < 1.5;\n    bool _5208;\n    if (_5201)\n    {\n        _5208 = dot(normalize(fa_light_texel(param_3).xyz), _5199) >= 0.0;\n    }\n    else\n    {\n        _5208 = _5201;\n    }\n    if (_5208)\n    {\n        return vec3(0.0);\n    }\n    bool _5217 = (_5194 > 0.5) && _5201;\n    float _5221 = _5217 ? 1.0539000034332275390625 : 1.0;\n    vec3 _5224 = _5183.xyz;\n    float _5226 = _5183.w;\n    vec3 _5232 = _5188.xyz;\n    float _5234 = _5188.w;\n    vec3 up = _5232 * (_5234 * _5221);\n    float _5240;\n    if (_5217)\n    {\n        _5240 = (3.1415927410125732421875 * _5226) * _5226;\n    }\n    else\n    {\n        _5240 = (4.0 * _5226) * _5234;\n    }\n    if (_5194 > 1.5)\n    {\n        vec3 _5266 = cross(_5224, -_5199);\n        vec3 perp = _5266;\n        float _5270 = dot(_5266, _5266);\n        vec3 _5273;\n        if (_5270 > 1.0000000133514319600180897396058e-10)\n        {\n            _5273 = perp * inversesqrt(_5270);\n        }\n        else\n        {\n            _5273 = _5232;\n        }\n        perp = _5273;\n        up = _5273 * _5234;\n    }\n    float _5294 = max(_5240, 9.9999999747524270787835121154785e-07);\n    vec3 param_7 = n;\n    vec3 param_8 = v;\n    vec3 _5304 = fa_ltc_tangent(param_7, param_8);\n    vec3 param_9 = _5304;\n    vec3 param_10 = n;\n    vec3 param_11 = _5199;\n    vec3 _5312 = fa_ltc_local(param_9, param_10, param_11);\n    vec3 param_12 = _5304;\n    vec3 param_13 = n;\n    vec3 param_14 = _5224 * (_5226 * _5221);\n    vec3 _5320 = fa_ltc_local(param_12, param_13, param_14);\n    vec3 param_15 = _5304;\n    vec3 param_16 = n;\n    vec3 param_17 = up;\n    vec3 _5328 = fa_ltc_local(param_15, param_16, param_17);\n    vec4 param_18 = vec4(1.0, 0.0, 0.0, 1.0);\n    float param_19 = _5194;\n    vec3 param_20 = _5312;\n    vec3 param_21 = _5320;\n    vec3 param_22 = _5328;\n    float param_23 = roughness;\n    float param_24 = ndv;\n    vec2 _5347 = fa_ltc_uv(param_23, param_24) * 64.0;\n    vec2 param_25 = _5347;\n    vec2 param_26 = _5347 + vec2(64.0, 0.0);\n    vec4 _5357 = fa_atlas_fetch(param_26);\n    vec4 param_27 = fa_atlas_fetch(param_25);\n    float param_28 = _5194;\n    vec3 param_29 = _5312;\n    vec3 param_30 = _5320;\n    vec3 param_31 = _5328;\n    return (((diffuse_color * fa_area_form(param_18, param_19, param_20, param_21, param_22)) + (((f0 * _5357.x) + ((vec3(f90) - f0) * _5357.y)) * fa_area_form(param_27, param_28, param_29, param_30, param_31))) * fa_light_texel(param_2).xyz) * ((((3.1415927410125732421875 * dot(_5199, _5199)) + _5294) / _5294) * window);\n}\n\nvec3 fa_light_rgb(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 1;\n    return fa_light_texel(param_1).xyz;\n}\n\nfloat fa_d_charlie(float alpha, float ndh)\n{\n    float _4194 = 1.0 / alpha;\n    return ((2.0 + _4194) * pow(sqrt(max(1.0 - (ndh * ndh), 9.9999997473787516355514526367188e-05)), _4194)) * 0.15915493667125701904296875;\n}\n\nfloat fa_v_ashikhmin(float ndl, float ndv)\n{\n    return clamp(0.25 / max((ndl + ndv) - (ndl * ndv), 9.9999997473787516355514526367188e-05), 0.0, 1.0);\n}\n\nfloat fa_layers_coat(FaLayers L, vec3 l, vec3 h, float vdh)\n{\n    float _4229 = max(dot(L.nc, l), 0.0);\n    float _4235 = max(dot(L.nc, h), 0.0);\n    float _4244 = ((_4235 * _4235) * (L.coat_a2 - 1.0)) + 1.0;\n    return (((L.coat * (0.039999999105930328369140625 + (0.959999978542327880859375 * pow(clamp(1.0 - vdh, 0.0, 1.0), 5.0)))) * (((L.coat_a2 / ((3.1415927410125732421875 * _4244) * _4244)) * (0.5 / max(mix((2.0 * _4229) * L.coat_ndv, _4229 + L.coat_ndv, L.coat_alpha), 9.9999997473787516355514526367188e-05))) * 3.1415927410125732421875)) * step(9.9999997473787516355514526367188e-05, _4229)) * _4229;\n}\n\nvec3 fa_area_layers(FaLayers L, int li, vec3 world_pos, vec3 n, vec3 v, vec3 l, vec3 diffuse_color, vec3 f0, float roughness, float ndv, float window)\n{\n    int param = li;\n    vec3 param_1 = world_pos;\n    vec3 param_2 = n;\n    vec3 param_3 = v;\n    vec3 param_4 = diffuse_color;\n    vec3 param_5 = f0;\n    float param_6 = L.f90;\n    float param_7 = roughness;\n    float param_8 = ndv;\n    float param_9 = window;\n    float _5425;\n    if (L.sheen_on)\n    {\n        _5425 = L.sheen_scale;\n    }\n    else\n    {\n        _5425 = 1.0;\n    }\n    vec3 result = fa_area_shade(param, param_1, param_2, param_3, param_4, param_5, param_6, param_7, param_8, param_9) * (L.keep * _5425);\n    vec3 _5438 = normalize(l + v);\n    int param_10 = li;\n    vec3 _5449 = fa_light_rgb(param_10) * window;\n    if (L.sheen_on)\n    {\n        float _5458 = max(dot(n, l), 0.0);\n        float param_11 = L.sheen_alpha;\n        float param_12 = max(dot(n, _5438), 0.0);\n        float param_13 = _5458;\n        float param_14 = ndv;\n        result += ((L.sheen * _5449) * (((((fa_d_charlie(param_11, param_12) * fa_v_ashikhmin(param_13, param_14)) * 3.1415927410125732421875) * step(9.9999997473787516355514526367188e-05, _5458)) * _5458) * L.keep));\n    }\n    if (L.coat > 0.0)\n    {\n        FaLayers param_15 = L;\n        vec3 param_16 = l;\n        vec3 param_17 = _5438;\n        float param_18 = max(dot(v, _5438), 0.0);\n        result += (_5449 * fa_layers_coat(param_15, param_16, param_17, param_18));\n    }\n    return result;\n}\n\nfloat fa_d_ggx_aniso(float ndh, float tdh, float bdh, float at, float ab)\n{\n    float _4097 = tdh / at;\n    float _4101 = bdh / ab;\n    float _4113 = ((_4097 * _4097) + (_4101 * _4101)) + (ndh * ndh);\n    return 1.0 / ((((3.1415927410125732421875 * at) * ab) * _4113) * _4113);\n}\n\nfloat fa_lambda_ggx_aniso(float n, float t, float b, float at, float ab)\n{\n    return 0.5 * (sqrt(1.0 + (((((at * at) * t) * t) + (((ab * ab) * b) * b)) / max(n * n, 9.9999999392252902907785028219223e-09))) - 1.0);\n}\n\nfloat fa_v_ggx_aniso(float ndl, float ndv, float tdv, float bdv, float tdl, float bdl, float at, float ab)\n{\n    float param = ndv;\n    float param_1 = tdv;\n    float param_2 = bdv;\n    float param_3 = at;\n    float param_4 = ab;\n    float param_5 = ndl;\n    float param_6 = tdl;\n    float param_7 = bdl;\n    float param_8 = at;\n    float param_9 = ab;\n    return clamp(1.0 / ((4.0 * max(ndl * ndv, 9.9999997473787516355514526367188e-05)) * ((1.0 + fa_lambda_ggx_aniso(param, param_1, param_2, param_3, param_4)) + fa_lambda_ggx_aniso(param_5, param_6, param_7, param_8, param_9))), 0.0, 1.0);\n}\n\nvec3 fa_layers_light(FaLayers L, vec3 diffuse_color, vec3 f0, vec3 n, vec3 v, vec3 l, vec3 h, float ndl, float ndv, float ndh, float vdh, float alpha, float a2)\n{\n    float _4293 = step(9.9999997473787516355514526367188e-05, ndl);\n    float d_ggx;\n    float vis;\n    if (L.aniso != 0.0)\n    {\n        float param = ndh;\n        float param_1 = dot(L.t, h);\n        float param_2 = dot(L.b, h);\n        float param_3 = L.at;\n        float param_4 = L.ab;\n        d_ggx = fa_d_ggx_aniso(param, param_1, param_2, param_3, param_4);\n        float param_5 = ndl;\n        float param_6 = ndv;\n        float param_7 = dot(L.t, v);\n        float param_8 = dot(L.b, v);\n        float param_9 = dot(L.t, l);\n        float param_10 = dot(L.b, l);\n        float param_11 = L.at;\n        float param_12 = L.ab;\n        vis = fa_v_ggx_aniso(param_5, param_6, param_7, param_8, param_9, param_10, param_11, param_12);\n    }\n    else\n    {\n        float _4372 = ((ndh * ndh) * (a2 - 1.0)) + 1.0;\n        d_ggx = a2 / ((3.1415927410125732421875 * _4372) * _4372);\n        vis = 0.5 / max(mix((2.0 * ndl) * ndv, ndl + ndv, alpha), 9.9999997473787516355514526367188e-05);\n    }\n    vec3 base = diffuse_color + (((f0 + ((vec3(L.f90) - f0) * pow(clamp(1.0 - vdh, 0.0, 1.0), 5.0))) * ((d_ggx * vis) * 3.1415927410125732421875)) * _4293);\n    if (L.sheen_on)\n    {\n        float param_13 = L.sheen_alpha;\n        float param_14 = ndh;\n        float param_15 = ndl;\n        float param_16 = ndv;\n        base = (base * L.sheen_scale) + (L.sheen * (((fa_d_charlie(param_13, param_14) * fa_v_ashikhmin(param_15, param_16)) * 3.1415927410125732421875) * _4293));\n    }\n    vec3 result = base * (L.keep * ndl);\n    if (L.coat > 0.0)\n    {\n        FaLayers param_17 = L;\n        vec3 param_18 = l;\n        vec3 param_19 = h;\n        float param_20 = vdh;\n        result += vec3(fa_layers_coat(param_17, param_18, param_19, param_20));\n    }\n    return result;\n}\n\nvec2 fa_env_brdf(float rough, float ndv)\n{\n    vec4 _3503 = (vec4(-1.0, -0.0274999998509883880615234375, -0.572000026702880859375, 0.02199999988079071044921875) * rough) + vec4(1.0, 0.0425000004470348358154296875, 1.03999996185302734375, -0.039999999105930328369140625);\n    float _3506 = _3503.x;\n    return (vec2(-1.03999996185302734375, 1.03999996185302734375) * ((min(_3506 * _3506, exp2((-9.27999973297119140625) * ndv)) * _3506) + _3503.y)) + _3503.zw;\n}\n\nvec3 fa_environment(vec3 d, float rough)\n{\n    if (fa_mesh_fs_params[11].w > 0.5)\n    {\n        return textureLod(fa_env_tex_fa_env_smp, d, clamp(rough, 0.0, 1.0) * fa_mesh_fs_params[12].w).xyz;\n    }\n    float _3357 = rough * rough;\n    float _3387 = 0.60000002384185791015625 * _3357;\n    return mix(mix(fa_mesh_fs_params[12].xyz * 0.550000011920928955078125, mix(fa_mesh_fs_params[12].xyz, fa_mesh_fs_params[11].xyz, vec3(pow(clamp(d.y * (1.0 - (0.699999988079071044921875 * _3357)), 0.0, 1.0), 0.550000011920928955078125))), vec3(smoothstep((-0.0500000007450580596923828125) - _3387, 0.0500000007450580596923828125 + _3387, d.y))), ((fa_mesh_fs_params[11].xyz + fa_mesh_fs_params[12].xyz) * 0.5) * 0.800000011920928955078125, vec3(_3357 * 0.60000002384185791015625));\n}\n\nvec3 fa_layers_ibl(FaLayers L, vec3 n, vec3 v, vec3 f0, float roughness)\n{\n    vec3 rn = n;\n    if (L.aniso != 0.0)\n    {\n        vec3 _3980;\n        if (L.aniso >= 0.0)\n        {\n            _3980 = L.b;\n        }\n        else\n        {\n            _3980 = L.t;\n        }\n        rn = normalize(mix(n, cross(cross(_3980, v), _3980), vec3(abs(L.aniso))));\n    }\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05);\n    vec2 _4013 = fa_env_brdf(param, param_1);\n    vec3 param_2 = reflect(-v, rn);\n    float param_3 = roughness;\n    vec3 result = (fa_environment(param_2, param_3) * ((f0 * _4013.x) + (vec3(L.f90) * _4013.y))) * L.base_scale;\n    if (L.sheen_on)\n    {\n        vec3 param_4 = n;\n        float param_5 = L.sheen_rough;\n        result += ((L.sheen * (L.sheen_e * L.keep)) * fa_environment(param_4, param_5));\n    }\n    if (L.coat > 0.0)\n    {\n        float param_6 = L.coat_rough;\n        float param_7 = L.coat_ndv;\n        vec2 _4068 = fa_env_brdf(param_6, param_7);\n        vec3 param_8 = reflect(-v, L.nc);\n        float param_9 = L.coat_rough;\n        result += (fa_environment(param_8, param_9) * (L.coat * ((0.039999999105930328369140625 * _4068.x) + _4068.y)));\n    }\n    return result;\n}\n\nvec3 fa_sky_reflection(vec3 n, vec3 v, vec3 f0, float roughness)\n{\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05);\n    vec2 _3545 = fa_env_brdf(param, param_1);\n    vec3 param_2 = reflect(-v, n);\n    float param_3 = roughness;\n    return fa_environment(param_2, param_3) * ((f0 * _3545.x) + vec3(_3545.y));\n}\n\nvec3 fa_shadow_debug(vec3 color, vec3 world)\n{\n    if (fa_shadows[27].w < 0.5)\n    {\n        return color;\n    }\n    int _3151 = int(fa_shadows[25].x + 0.5);\n    float _3161 = dot(world - fa_shadows[27].xyz, fa_shadows[28].xyz);\n    vec3 tint = vec3(0.3499999940395355224609375);\n    bool _3166 = _3151 > 0;\n    bool _3175;\n    if (_3166)\n    {\n        int param = _3151 - 1;\n        _3175 = _3161 <= fa_shadow_split_at(param);\n    }\n    else\n    {\n        _3175 = _3166;\n    }\n    if (_3175)\n    {\n        tint = vec3(1.0, 0.1500000059604644775390625, 0.100000001490116119384765625);\n        bool _3181 = _3151 > 1;\n        bool _3188;\n        if (_3181)\n        {\n            _3188 = _3161 > fa_shadows[24].x;\n        }\n        else\n        {\n            _3188 = _3181;\n        }\n        if (_3188)\n        {\n            tint = vec3(0.100000001490116119384765625, 0.89999997615814208984375, 0.20000000298023223876953125);\n        }\n        bool _3194 = _3151 > 2;\n        bool _3201;\n        if (_3194)\n        {\n            _3201 = _3161 > fa_shadows[24].y;\n        }\n        else\n        {\n            _3201 = _3194;\n        }\n        if (_3201)\n        {\n            tint = vec3(0.1500000059604644775390625, 0.300000011920928955078125, 1.0);\n        }\n        bool _3207 = _3151 > 3;\n        bool _3214;\n        if (_3207)\n        {\n            _3214 = _3161 > fa_shadows[24].z;\n        }\n        else\n        {\n            _3214 = _3207;\n        }\n        if (_3214)\n        {\n            tint = vec3(1.0, 0.89999997615814208984375, 0.100000001490116119384765625);\n        }\n    }\n    return mix(color, tint, vec3(0.550000011920928955078125));\n}\n\nvoid main()\n{\n    fa_inst_load();\n    vec3 _6536 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _6536 = -_6536;\n    }\n    vec3 _5894 = normalize(fa_mesh_fs_params[0].xyz - fa_world_pos);\n    vec3 param = fa_world_pos;\n    fa_cluster_begin(param);\n    SurfaceInput param_1 = SurfaceInput(fa_world_pos, _6536, fa_world_tangent, fa_uv, fa_vertex_color, _5894, gl_FrontFacing);\n    Surface _5902 = fa_standard_surface(param_1);\n    vec3 _6567 = _5902.albedo;\n    float _6568 = _5902.alpha;\n    vec3 _6569 = _5902.normal;\n    float _6570 = _5902.metallic;\n    float _6571 = _5902.roughness;\n    float _6572 = _5902.occlusion;\n    vec3 _6573 = _5902.emission;\n    float _6574 = _5902.clearcoat;\n    float _6575 = _5902.clearcoat_roughness;\n    vec3 _6576 = _5902.sheen_color;\n    float _6577 = _5902.sheen_roughness;\n    float _6578 = _5902.anisotropy;\n    float _6579 = _5902.anisotropy_rotation;\n    float _6580 = _5902.specular;\n    float _6581 = _5902.ior;\n    vec3 _6582 = _5902.specular_color;\n    SurfaceInput param_2 = SurfaceInput(fa_world_pos, _6536, fa_world_tangent, fa_uv, fa_vertex_color, _5894, gl_FrontFacing);\n    Surface param_3 = _5902;\n    surface(param_2, param_3);\n    _6567 = param_3.albedo;\n    _6568 = param_3.alpha;\n    _6569 = param_3.normal;\n    _6570 = param_3.metallic;\n    _6571 = param_3.roughness;\n    _6572 = param_3.occlusion;\n    _6573 = param_3.emission;\n    _6574 = param_3.clearcoat;\n    _6575 = param_3.clearcoat_roughness;\n    _6576 = param_3.sheen_color;\n    _6577 = param_3.sheen_roughness;\n    _6578 = param_3.anisotropy;\n    _6579 = param_3.anisotropy_rotation;\n    _6580 = param_3.specular;\n    _6581 = param_3.ior;\n    _6582 = param_3.specular_color;\n    vec3 param_4 = fa_world_pos;\n    vec3 param_5 = _6536;\n    vec3 param_6 = param_3.albedo;\n    vec3 param_7 = param_3.normal;\n    fa_apply_decals(param_4, param_5, param_6, param_7);\n    _6567 = param_6;\n    _6569 = param_7;\n    vec3 result;\n    if (fa_mesh_fs_params[3].w > 0.5)\n    {\n        result = _6567;\n    }\n    else\n    {\n        vec3 _5941 = normalize(_6569);\n        float _5948 = clamp(_6570, 0.0, 1.0);\n        float _5952 = clamp(_6571, 0.0500000007450580596923828125, 1.0);\n        float _5956 = _5952 * _5952;\n        float _5960 = _5956 * _5956;\n        float _5965 = max(dot(_5941, _5894), 9.9999997473787516355514526367188e-05);\n        vec3 _5971 = _6567 * (1.0 - _5948);\n        vec3 _5978 = mix(vec3(0.039999999105930328369140625), _6567, vec3(_5948));\n        vec3 f0 = _5978;\n        SurfaceInput param_8 = SurfaceInput(fa_world_pos, _6536, fa_world_tangent, fa_uv, fa_vertex_color, _5894, gl_FrontFacing);\n        Surface param_9 = Surface(_6567, _6568, _6569, _6570, _6571, _6572, _6573, _6574, _6575, _6576, _6577, _6578, _6579, _6580, _6581, _6582);\n        vec3 param_10 = _5941;\n        vec3 param_11 = _5894;\n        float param_12 = _5948;\n        float param_13 = _5952;\n        vec3 param_14 = _5978;\n        FaLayers _5994 = fa_layers_setup(param_8, param_9, param_10, param_11, param_12, param_13, param_14);\n        f0 = param_14;\n        vec3 param_15 = _5941;\n        vec3 lit = (fa_indirect_diffuse(param_15) * _5971) * _6572;\n        if (_5994.on)\n        {\n            lit *= _5994.base_scale;\n        }\n        int _6016 = fa_cl_ndir + fa_cl_local;\n        for (int ln = 0; ln < _6016; ln++)\n        {\n            int param_16 = ln;\n            int _6029 = fa_cl_light(param_16);\n            bool _6032 = fa_lm.z > 0.5;\n            bool _6038;\n            if (_6032)\n            {\n                int param_17 = _6029;\n                _6038 = fa_light_baked(param_17);\n            }\n            else\n            {\n                _6038 = _6032;\n            }\n            if (_6038)\n            {\n                continue;\n            }\n            int param_18 = _6029;\n            vec3 param_19 = fa_world_pos;\n            vec3 param_20 = _6536;\n            LightSample _6050 = fa_light_shadowed(param_18, param_19, param_20);\n            float _6058 = max(dot(_5941, _6050.direction), 0.0);\n            float _6064 = _6050.attenuation * _6050.shadow;\n            vec3 _6069 = normalize(_6050.direction + _5894);\n            float _6074 = max(dot(_5941, _6069), 0.0);\n            float _6079 = max(dot(_5894, _6069), 0.0);\n            bool _6086;\n            if (fa_light_is_area)\n            {\n                _6086 = !_5994.on;\n            }\n            else\n            {\n                _6086 = fa_light_is_area;\n            }\n            if (_6086)\n            {\n                int param_21 = _6029;\n                vec3 param_22 = fa_world_pos;\n                vec3 param_23 = _5941;\n                vec3 param_24 = _5894;\n                vec3 param_25 = _5971;\n                vec3 param_26 = f0;\n                float param_27 = 1.0;\n                float param_28 = _5952;\n                float param_29 = _5965;\n                float param_30 = _6064;\n                lit += fa_area_shade(param_21, param_22, param_23, param_24, param_25, param_26, param_27, param_28, param_29, param_30);\n            }\n            else\n            {\n                if (fa_light_is_area)\n                {\n                    FaLayers param_31 = _5994;\n                    int param_32 = _6029;\n                    vec3 param_33 = fa_world_pos;\n                    vec3 param_34 = _5941;\n                    vec3 param_35 = _5894;\n                    vec3 param_36 = _6050.direction;\n                    vec3 param_37 = _5971;\n                    vec3 param_38 = f0;\n                    float param_39 = _5952;\n                    float param_40 = _5965;\n                    float param_41 = _6064;\n                    lit += fa_area_layers(param_31, param_32, param_33, param_34, param_35, param_36, param_37, param_38, param_39, param_40, param_41);\n                }\n                else\n                {\n                    if (_5994.on)\n                    {\n                        FaLayers param_42 = _5994;\n                        vec3 param_43 = _5971;\n                        vec3 param_44 = f0;\n                        vec3 param_45 = _5941;\n                        vec3 param_46 = _5894;\n                        vec3 param_47 = _6050.direction;\n                        vec3 param_48 = _6069;\n                        float param_49 = _6058;\n                        float param_50 = _5965;\n                        float param_51 = _6074;\n                        float param_52 = _6079;\n                        float param_53 = _5956;\n                        float param_54 = _5960;\n                        int param_55 = _6029;\n                        lit += (fa_layers_light(param_42, param_43, param_44, param_45, param_46, param_47, param_48, param_49, param_50, param_51, param_52, param_53, param_54) * ((fa_light_rgb(param_55) * fa_light_tint) * _6064));\n                    }\n                    else\n                    {\n                        float _6192 = ((_6074 * _6074) * (_5960 - 1.0)) + 1.0;\n                        int param_56 = _6029;\n                        lit += (((_5971 + (((f0 + ((vec3(1.0) - f0) * pow(1.0 - _6079, 5.0))) * (((_5960 / ((3.1415927410125732421875 * _6192) * _6192)) * (0.5 / max(mix((2.0 * _6058) * _5965, _6058 + _5965, _5956), 9.9999997473787516355514526367188e-05))) * 3.1415927410125732421875)) * step(9.9999997473787516355514526367188e-05, _6058))) * (fa_light_rgb(param_56) * fa_light_tint)) * (_6058 * _6064));\n                    }\n                }\n            }\n        }\n        if (_5994.on)\n        {\n            FaLayers param_57 = _5994;\n            vec3 param_58 = _5941;\n            vec3 param_59 = _5894;\n            vec3 param_60 = f0;\n            float param_61 = _5952;\n            lit += (fa_layers_ibl(param_57, param_58, param_59, param_60, param_61) * _6572);\n        }\n        else\n        {\n            vec3 param_62 = _5941;\n            vec3 param_63 = _5894;\n            vec3 param_64 = f0;\n            float param_65 = _5952;\n            lit += (fa_sky_reflection(param_62, param_63, param_64, param_65) * _6572);\n        }\n        result = lit;\n    }\n    vec3 _6287 = result;\n    vec3 _6288 = _6287 + _6573;\n    result = _6288;\n    vec3 param_66 = _6288;\n    vec3 param_67 = fa_world_pos;\n    result = fa_shadow_debug(param_66, param_67);\n    bool _6297 = fa_mesh_fs_params[7].w > 0.0;\n    bool _6304;\n    if (!_6297)\n    {\n        _6304 = fa_mesh_fs_params[8].y > 0.0;\n    }\n    else\n    {\n        _6304 = _6297;\n    }\n    if (_6304)\n    {\n        vec3 _6313 = fa_world_pos - fa_mesh_fs_params[0].xyz;\n        float _6319 = dot(_6313, fa_mesh_fs_params[9].xyz);\n        bool _6323 = fa_mesh_fs_params[9].w > 0.5;\n        float _6324;\n        if (_6323)\n        {\n            _6324 = _6319;\n        }\n        else\n        {\n            _6324 = length(_6313);\n        }\n        float _6336 = _6324 - fa_mesh_fs_params[8].x;\n        if (_6336 > 0.0)\n        {\n            float _6345 = fa_mesh_fs_params[7].w * _6336;\n            float tau = _6345 * _6345;\n            if (fa_mesh_fs_params[8].y > 0.0)\n            {\n                float _6361;\n                if (_6323)\n                {\n                    _6361 = fa_world_pos.y - (fa_mesh_fs_params[9].y * _6319);\n                }\n                else\n                {\n                    _6361 = fa_mesh_fs_params[0].y;\n                }\n                float _6382 = mix(_6361, fa_world_pos.y, clamp(fa_mesh_fs_params[8].x / _6324, 0.0, 1.0));\n                float _6386 = fa_world_pos.y - _6382;\n                float _6391 = _6382 - fa_mesh_fs_params[8].z;\n                float _6396 = fa_world_pos.y - fa_mesh_fs_params[8].z;\n                bool _6399 = _6391 <= 0.0;\n                bool _6400 = !_6399;\n                bool _6406;\n                if (_6400)\n                {\n                    _6406 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _6406 = _6399;\n                }\n                float _6407;\n                if (_6406)\n                {\n                    _6407 = fa_mesh_fs_params[8].y;\n                }\n                else\n                {\n                    _6407 = fa_mesh_fs_params[8].y * exp(-min(fa_mesh_fs_params[8].w * _6391, 80.0));\n                }\n                bool _6434;\n                if (_6400)\n                {\n                    _6434 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _6434 = _6399;\n                }\n                float _6435;\n                if (_6434)\n                {\n                    _6435 = fa_mesh_fs_params[8].y * _6391;\n                }\n                else\n                {\n                    _6435 = (fa_mesh_fs_params[8].y * (1.0 - exp(-min(fa_mesh_fs_params[8].w * _6391, 80.0)))) / fa_mesh_fs_params[8].w;\n                }\n                bool _6460 = _6396 <= 0.0;\n                bool _6467;\n                if (!_6460)\n                {\n                    _6467 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _6467 = _6460;\n                }\n                float _6468;\n                if (_6467)\n                {\n                    _6468 = fa_mesh_fs_params[8].y * _6396;\n                }\n                else\n                {\n                    _6468 = (fa_mesh_fs_params[8].y * (1.0 - exp(-min(fa_mesh_fs_params[8].w * _6396, 80.0)))) / fa_mesh_fs_params[8].w;\n                }\n                float _6495;\n                if (abs(_6386) < 0.001000000047497451305389404296875)\n                {\n                    _6495 = _6407;\n                }\n                else\n                {\n                    _6495 = (_6468 - _6435) / _6386;\n                }\n                tau += (_6336 * max(_6495, 0.0));\n            }\n            result = mix(result, fa_mesh_fs_params[7].xyz, vec3(clamp(1.0 - exp(-clamp(tau, 0.0, 80.0)), 0.0, 1.0)));\n        }\n    }\n    fa_frag_color = vec4(result, _6568);\n}\n\n",
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
            "inst_name": "_548",
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
            "inst_name": "_2215",
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
          }
        ]
      }
    },
    "prepass": {
      "vs": "#version 430\n\nstruct VertexData\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 color;\n    vec3 object_pos;\n};\n\nstruct points_item\n{\n    vec4 pos;\n    vec4 tint;\n};\n\nlayout(binding = 0, std430) readonly buffer fa_vs_points_buf\n{\n    points_item data[];\n} fa_vs_points;\n\nuniform vec4 fa_mesh_vs_params[11];\nuniform vec4 fa_inst_base[4];\nlayout(location = 0) out vec3 fa_world_pos;\nlayout(location = 1) out vec3 fa_world_normal;\nlayout(location = 2) out vec4 fa_world_tangent;\nlayout(location = 3) out vec2 fa_uv;\nlayout(location = 4) out vec4 fa_vertex_color;\nlayout(location = 5) out float fa_pre_depth;\nlayout(location = 6) out vec3 fa_pre_r0;\nlayout(location = 7) out vec3 fa_pre_r1;\nlayout(location = 8) out vec3 fa_pre_r2;\nlayout(location = 0) in vec3 fa_position;\nlayout(location = 1) in vec3 fa_normal;\nlayout(location = 3) in vec4 fa_tangent;\nlayout(location = 2) in vec2 fa_texcoord0;\nlayout(location = 4) in vec4 fa_color;\nlayout(location = 5) in vec4 fa_inst_m0;\nlayout(location = 6) in vec4 fa_inst_m1;\nlayout(location = 7) in vec4 fa_inst_m2;\nlayout(location = 8) in vec4 fa_inst_m3;\n\nvoid fa_inst_begin()\n{\n}\n\nVertexData fa_vertex_data(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    vec3 _109 = cross(model[1].xyz, model[2].xyz);\n    float _114 = (dot(model[0].xyz, _109) < 0.0) ? (-1.0) : 1.0;\n    return VertexData((model * vec4(position, 1.0)).xyz, (((_109 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _114, vec4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _114), texcoord0 * fa_mesh_vs_params[8].xy, color, position);\n}\n\nvoid vertex(inout VertexData v)\n{\n    if (fa_vs_points.data[gl_InstanceID].pos.w < 0.5)\n    {\n        v.world_pos = vec3(1000000000.0);\n        return;\n    }\n    v.world_pos += fa_vs_points.data[gl_InstanceID].pos.xyz;\n    v.color = fa_vs_points.data[gl_InstanceID].tint;\n}\n\nvoid fa_prepass_vertex(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    mat4 param = model;\n    vec3 param_1 = position;\n    vec3 param_2 = normal;\n    vec4 param_3 = tangent;\n    vec2 param_4 = texcoord0;\n    vec4 param_5 = color;\n    VertexData param_6 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    vertex(param_6);\n    mat4 _203 = mat4(fa_mesh_vs_params[4], fa_mesh_vs_params[5], fa_mesh_vs_params[6], fa_mesh_vs_params[7]);\n    vec4 _210 = vec4(param_6.world_pos, 1.0);\n    fa_world_pos = param_6.world_pos;\n    fa_world_normal = param_6.world_normal;\n    fa_world_tangent = param_6.world_tangent;\n    fa_uv = param_6.uv;\n    fa_vertex_color = param_6.color;\n    fa_pre_depth = -(_203 * _210).z;\n    fa_pre_r0 = vec3(_203[0].x, _203[1].x, _203[2].x);\n    fa_pre_r1 = vec3(_203[0].y, _203[1].y, _203[2].y);\n    fa_pre_r2 = vec3(_203[0].z, _203[1].z, _203[2].z);\n    gl_Position = mat4(fa_mesh_vs_params[0], fa_mesh_vs_params[1], fa_mesh_vs_params[2], fa_mesh_vs_params[3]) * _210;\n}\n\nvoid main()\n{\n    fa_inst_begin();\n    mat4 param = mat4(fa_inst_base[0], fa_inst_base[1], fa_inst_base[2], fa_inst_base[3]);\n    vec3 param_1 = fa_position;\n    vec3 param_2 = fa_normal;\n    vec4 param_3 = fa_tangent;\n    vec2 param_4 = fa_texcoord0;\n    vec4 param_5 = fa_color;\n    fa_prepass_vertex(param, param_1, param_2, param_3, param_4, param_5);\n}\n\n",
      "fs": "#version 430\n\nstruct SurfaceInput\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 vertex_color;\n    vec3 view_dir;\n    bool front_facing;\n};\n\nstruct Surface\n{\n    vec3 albedo;\n    float alpha;\n    vec3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    vec3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    vec3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    vec3 specular_color;\n};\n\nstruct points_item\n{\n    vec4 pos;\n    vec4 tint;\n};\n\nlayout(binding = 1, std430) readonly buffer fa_points_buf\n{\n    points_item data[];\n} points;\n\nuniform vec4 fa_mesh_fs_params[24];\nlayout(binding = 0) uniform sampler2D fa_tex_fa_smp;\nlayout(binding = 1) uniform sampler2D fa_normal_tex_fa_smp;\nlayout(binding = 2) uniform sampler2D fa_mr_tex_fa_smp;\nlayout(binding = 3) uniform sampler2D fa_occlusion_tex_fa_smp;\nlayout(binding = 4) uniform sampler2D fa_emissive_tex_fa_smp;\n\nlayout(location = 0) in vec3 fa_world_pos;\nlayout(location = 1) in vec3 fa_world_normal;\nlayout(location = 2) in vec4 fa_world_tangent;\nlayout(location = 3) in vec2 fa_uv;\nlayout(location = 4) in vec4 fa_vertex_color;\nlayout(location = 6) in vec3 fa_pre_r0;\nlayout(location = 7) in vec3 fa_pre_r1;\nlayout(location = 8) in vec3 fa_pre_r2;\nlayout(location = 0) out vec4 fa_frag_color;\nlayout(location = 5) in float fa_pre_depth;\n\nvoid fa_inst_load()\n{\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nvec3 fa_linear_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_tex_fix(inout vec3 c, float mode)\n{\n    if (mode > 1.5)\n    {\n        vec3 param = c;\n        vec3 _190 = fa_linear_to_srgb(param);\n        c = _190;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            vec3 param_1 = c;\n            vec3 _199 = fa_srgb_to_linear(param_1);\n            c = _199;\n        }\n    }\n    return c;\n}\n\nvec3 fa_tangent_normal(SurfaceInput i, vec3 m)\n{\n    vec3 _56;\n    if (i.front_facing)\n    {\n        _56 = i.world_normal;\n    }\n    else\n    {\n        _56 = -i.world_normal;\n    }\n    vec3 _81 = normalize(i.world_tangent.xyz - (_56 * dot(_56, i.world_tangent.xyz)));\n    vec3 _109 = normalize(((_81 * m.x) + ((cross(_56, _81) * i.world_tangent.w) * m.y)) + (_56 * m.z));\n    vec3 _112;\n    if (i.front_facing)\n    {\n        _112 = _109;\n    }\n    else\n    {\n        _112 = -_109;\n    }\n    return _112;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    vec4 base_t = texture(fa_tex_fa_smp, i.uv);\n    float param = fa_mesh_fs_params[6].w;\n    float param_1 = 1.0;\n    vec3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    vec3 _242 = fa_tex_fix(param_2, param_3);\n    vec4 _749 = base_t;\n    _749.x = _242.x;\n    _749.y = _242.y;\n    _749.z = _242.z;\n    base_t = _749;\n    vec4 _257 = (_749 * fa_mesh_fs_params[2]) * i.vertex_color;\n    vec3 _712 = i.world_normal;\n    if (fa_mesh_fs_params[6].z > 0.5)\n    {\n        float param_4 = fa_mesh_fs_params[6].w;\n        float param_5 = 16.0;\n        vec3 param_6 = texture(fa_normal_tex_fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        vec3 _290 = fa_tex_fix(param_6, param_7);\n        vec3 _294 = (_290 * 2.0) - vec3(1.0);\n        vec2 _299 = _294.xy * fa_mesh_fs_params[6].x;\n        vec3 _757 = _294;\n        _757.x = _299.x;\n        _757.y = _299.y;\n        SurfaceInput param_8 = i;\n        vec3 param_9 = _757;\n        _712 = fa_tangent_normal(param_8, param_9);\n    }\n    vec4 mrt = texture(fa_mr_tex_fa_smp, i.uv);\n    float param_10 = fa_mesh_fs_params[6].w;\n    float param_11 = 64.0;\n    vec3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    vec3 _328 = fa_tex_fix(param_12, param_13);\n    vec4 _760 = mrt;\n    _760.x = _328.x;\n    _760.y = _328.y;\n    _760.z = _328.z;\n    mrt = _760;\n    vec4 _358 = texture(fa_occlusion_tex_fa_smp, i.uv);\n    float param_14 = fa_mesh_fs_params[6].w;\n    float param_15 = 256.0;\n    vec3 param_16 = _358.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    vec3 _370 = fa_tex_fix(param_16, param_17);\n    float param_18 = fa_mesh_fs_params[6].w;\n    float param_19 = 4.0;\n    vec3 param_20 = texture(fa_emissive_tex_fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    vec3 _400 = fa_tex_fix(param_20, param_21);\n    float _717 = fa_mesh_fs_params[20].x;\n    float _718 = fa_mesh_fs_params[20].y;\n    float _721 = fa_mesh_fs_params[20].z;\n    float _720 = fa_mesh_fs_params[21].w;\n    float _723 = fa_mesh_fs_params[22].x;\n    if (fa_mesh_fs_params[22].z > 0.5)\n    {\n        if (mod(fa_mesh_fs_params[22].z, 2.0) > 0.5)\n        {\n            _717 *= _370.y;\n            _718 *= _370.z;\n            _720 *= _358.w;\n        }\n        if (fa_mesh_fs_params[22].z > 1.5)\n        {\n            _721 *= mrt.x;\n            _723 *= mrt.w;\n        }\n    }\n    return Surface(_257.xyz, _257.w, _712, clamp(fa_mesh_fs_params[5].x * _328.z, 0.0, 1.0), clamp(fa_mesh_fs_params[5].y * _328.y, 0.0500000007450580596923828125, 1.0), 1.0 + (fa_mesh_fs_params[6].y * (_370.x - 1.0)), fa_mesh_fs_params[3].xyz + (fa_mesh_fs_params[4].xyz * _400), _717, _718, fa_mesh_fs_params[21].xyz, _720, _721, fa_mesh_fs_params[20].w, _723, fa_mesh_fs_params[22].y, fa_mesh_fs_params[23].xyz);\n}\n\nvoid surface(SurfaceInput i, inout Surface s)\n{\n    s.emission += (i.vertex_color.xyz * points.data[0].tint.w);\n}\n\nvoid main()\n{\n    fa_inst_load();\n    vec3 _623 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _623 = -_623;\n    }\n    vec3 _534 = normalize(fa_mesh_fs_params[0].xyz - fa_world_pos);\n    SurfaceInput param = SurfaceInput(fa_world_pos, _623, fa_world_tangent, fa_uv, fa_vertex_color, _534, gl_FrontFacing);\n    SurfaceInput param_1 = SurfaceInput(fa_world_pos, _623, fa_world_tangent, fa_uv, fa_vertex_color, _534, gl_FrontFacing);\n    Surface param_2 = fa_standard_surface(param);\n    surface(param_1, param_2);\n    vec3 _549 = normalize(param_2.normal);\n    vec3 _564 = normalize(vec3(dot(fa_pre_r0, _549), dot(fa_pre_r1, _549), dot(fa_pre_r2, _549)));\n    float _576 = _564.z;\n    vec2 e = _564.xy / vec2((abs(_564.x) + abs(_564.y)) + abs(_576));\n    if (_576 < 0.0)\n    {\n        e = (vec2(1.0) - abs(e.yx)) * vec2((e.x >= 0.0) ? 1.0 : (-1.0), (e.y >= 0.0) ? 1.0 : (-1.0));\n    }\n    fa_frag_color = vec4(min(fa_pre_depth, 60000.0), e, 1.0);\n}\n\n",
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
      "fs": "#version 430\n\nstruct SurfaceInput\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 vertex_color;\n    vec3 view_dir;\n    bool front_facing;\n};\n\nstruct Surface\n{\n    vec3 albedo;\n    float alpha;\n    vec3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    vec3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    vec3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    vec3 specular_color;\n};\n\nstruct points_item\n{\n    vec4 pos;\n    vec4 tint;\n};\n\nlayout(binding = 1, std430) readonly buffer fa_points_buf\n{\n    points_item data[];\n} points;\n\nuniform vec4 fa_mesh_fs_params[24];\nlayout(binding = 0) uniform sampler2D fa_tex_fa_smp;\nlayout(binding = 1) uniform sampler2D fa_normal_tex_fa_smp;\nlayout(binding = 2) uniform sampler2D fa_mr_tex_fa_smp;\nlayout(binding = 3) uniform sampler2D fa_occlusion_tex_fa_smp;\nlayout(binding = 4) uniform sampler2D fa_emissive_tex_fa_smp;\n\nlayout(location = 0) in vec3 fa_world_pos;\nlayout(location = 1) in vec3 fa_world_normal;\nlayout(location = 2) in vec4 fa_world_tangent;\nlayout(location = 3) in vec2 fa_uv;\nlayout(location = 4) in vec4 fa_vertex_color;\nlayout(location = 6) in vec3 fa_pre_r0;\nlayout(location = 7) in vec3 fa_pre_r1;\nlayout(location = 8) in vec3 fa_pre_r2;\nlayout(location = 0) out vec4 fa_frag_color;\nlayout(location = 5) in float fa_pre_depth;\n\nvoid fa_inst_load()\n{\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nvec3 fa_linear_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_tex_fix(inout vec3 c, float mode)\n{\n    if (mode > 1.5)\n    {\n        vec3 param = c;\n        vec3 _190 = fa_linear_to_srgb(param);\n        c = _190;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            vec3 param_1 = c;\n            vec3 _199 = fa_srgb_to_linear(param_1);\n            c = _199;\n        }\n    }\n    return c;\n}\n\nvec3 fa_tangent_normal(SurfaceInput i, vec3 m)\n{\n    vec3 _56;\n    if (i.front_facing)\n    {\n        _56 = i.world_normal;\n    }\n    else\n    {\n        _56 = -i.world_normal;\n    }\n    vec3 _81 = normalize(i.world_tangent.xyz - (_56 * dot(_56, i.world_tangent.xyz)));\n    vec3 _109 = normalize(((_81 * m.x) + ((cross(_56, _81) * i.world_tangent.w) * m.y)) + (_56 * m.z));\n    vec3 _112;\n    if (i.front_facing)\n    {\n        _112 = _109;\n    }\n    else\n    {\n        _112 = -_109;\n    }\n    return _112;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    vec4 base_t = texture(fa_tex_fa_smp, i.uv);\n    float param = fa_mesh_fs_params[6].w;\n    float param_1 = 1.0;\n    vec3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    vec3 _242 = fa_tex_fix(param_2, param_3);\n    vec4 _749 = base_t;\n    _749.x = _242.x;\n    _749.y = _242.y;\n    _749.z = _242.z;\n    base_t = _749;\n    vec4 _257 = (_749 * fa_mesh_fs_params[2]) * i.vertex_color;\n    vec3 _712 = i.world_normal;\n    if (fa_mesh_fs_params[6].z > 0.5)\n    {\n        float param_4 = fa_mesh_fs_params[6].w;\n        float param_5 = 16.0;\n        vec3 param_6 = texture(fa_normal_tex_fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        vec3 _290 = fa_tex_fix(param_6, param_7);\n        vec3 _294 = (_290 * 2.0) - vec3(1.0);\n        vec2 _299 = _294.xy * fa_mesh_fs_params[6].x;\n        vec3 _757 = _294;\n        _757.x = _299.x;\n        _757.y = _299.y;\n        SurfaceInput param_8 = i;\n        vec3 param_9 = _757;\n        _712 = fa_tangent_normal(param_8, param_9);\n    }\n    vec4 mrt = texture(fa_mr_tex_fa_smp, i.uv);\n    float param_10 = fa_mesh_fs_params[6].w;\n    float param_11 = 64.0;\n    vec3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    vec3 _328 = fa_tex_fix(param_12, param_13);\n    vec4 _760 = mrt;\n    _760.x = _328.x;\n    _760.y = _328.y;\n    _760.z = _328.z;\n    mrt = _760;\n    vec4 _358 = texture(fa_occlusion_tex_fa_smp, i.uv);\n    float param_14 = fa_mesh_fs_params[6].w;\n    float param_15 = 256.0;\n    vec3 param_16 = _358.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    vec3 _370 = fa_tex_fix(param_16, param_17);\n    float param_18 = fa_mesh_fs_params[6].w;\n    float param_19 = 4.0;\n    vec3 param_20 = texture(fa_emissive_tex_fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    vec3 _400 = fa_tex_fix(param_20, param_21);\n    float _717 = fa_mesh_fs_params[20].x;\n    float _718 = fa_mesh_fs_params[20].y;\n    float _721 = fa_mesh_fs_params[20].z;\n    float _720 = fa_mesh_fs_params[21].w;\n    float _723 = fa_mesh_fs_params[22].x;\n    if (fa_mesh_fs_params[22].z > 0.5)\n    {\n        if (mod(fa_mesh_fs_params[22].z, 2.0) > 0.5)\n        {\n            _717 *= _370.y;\n            _718 *= _370.z;\n            _720 *= _358.w;\n        }\n        if (fa_mesh_fs_params[22].z > 1.5)\n        {\n            _721 *= mrt.x;\n            _723 *= mrt.w;\n        }\n    }\n    return Surface(_257.xyz, _257.w, _712, clamp(fa_mesh_fs_params[5].x * _328.z, 0.0, 1.0), clamp(fa_mesh_fs_params[5].y * _328.y, 0.0500000007450580596923828125, 1.0), 1.0 + (fa_mesh_fs_params[6].y * (_370.x - 1.0)), fa_mesh_fs_params[3].xyz + (fa_mesh_fs_params[4].xyz * _400), _717, _718, fa_mesh_fs_params[21].xyz, _720, _721, fa_mesh_fs_params[20].w, _723, fa_mesh_fs_params[22].y, fa_mesh_fs_params[23].xyz);\n}\n\nvoid surface(SurfaceInput i, inout Surface s)\n{\n    s.emission += (i.vertex_color.xyz * points.data[0].tint.w);\n}\n\nvoid main()\n{\n    fa_inst_load();\n    vec3 _623 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _623 = -_623;\n    }\n    vec3 _534 = normalize(fa_mesh_fs_params[0].xyz - fa_world_pos);\n    SurfaceInput param = SurfaceInput(fa_world_pos, _623, fa_world_tangent, fa_uv, fa_vertex_color, _534, gl_FrontFacing);\n    SurfaceInput param_1 = SurfaceInput(fa_world_pos, _623, fa_world_tangent, fa_uv, fa_vertex_color, _534, gl_FrontFacing);\n    Surface param_2 = fa_standard_surface(param);\n    surface(param_1, param_2);\n    vec3 _549 = normalize(param_2.normal);\n    vec3 _564 = normalize(vec3(dot(fa_pre_r0, _549), dot(fa_pre_r1, _549), dot(fa_pre_r2, _549)));\n    float _576 = _564.z;\n    vec2 e = _564.xy / vec2((abs(_564.x) + abs(_564.y)) + abs(_576));\n    if (_576 < 0.0)\n    {\n        e = (vec2(1.0) - abs(e.yx)) * vec2((e.x >= 0.0) ? 1.0 : (-1.0), (e.y >= 0.0) ? 1.0 : (-1.0));\n    }\n    fa_frag_color = vec4(min(fa_pre_depth, 60000.0), e, 1.0);\n}\n\n",
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
