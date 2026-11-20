{
  "format": "factoria.shader/1",
  "engine": "0.32.0",
  "template": "70ec7addbf81ecb38af52c4a5f6d5b8f2213a6d2ef6305cbd78b3ce14189ad63",
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
      "fs": "#version 430\n\nstruct SurfaceInput\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 vertex_color;\n    vec3 view_dir;\n    bool front_facing;\n};\n\nstruct LightSample\n{\n    vec3 direction;\n    vec3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct Surface\n{\n    vec3 albedo;\n    float alpha;\n    vec3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    vec3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    vec3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    vec3 specular_color;\n    float transmission;\n    float thickness;\n    vec3 attenuation_color;\n    float attenuation_distance;\n};\n\nstruct FaLayers\n{\n    bool on;\n    float f90;\n    float keep;\n    float base_scale;\n    float coat;\n    float coat_rough;\n    float coat_alpha;\n    float coat_a2;\n    vec3 nc;\n    float coat_ndv;\n    bool sheen_on;\n    vec3 sheen;\n    float sheen_rough;\n    float sheen_alpha;\n    float sheen_scale;\n    float sheen_e;\n    float aniso;\n    vec3 t;\n    vec3 b;\n    float at;\n    float ab;\n};\n\nconst float _3688[63] = float[](1.0, 1.0, 1.0, 0.4790000021457672119140625, 0.11699999868869781494140625, 0.01200000010430812835693359375, 0.0, 0.0, 0.0, 1.0, 1.0, 1.0, 0.578000009059906005859375, 0.19300000369548797607421875, 0.0350000001490116119384765625, 0.0030000000260770320892333984375, 0.0, 0.0, 1.0, 1.0, 1.0, 0.6740000247955322265625, 0.3459999859333038330078125, 0.1319999992847442626953125, 0.032999999821186065673828125, 0.0040000001899898052215576171875, 0.0, 0.971000015735626220703125, 0.954999983310699462890625, 0.828999996185302734375, 0.63999998569488525390625, 0.42599999904632568359375, 0.24500000476837158203125, 0.115000002086162567138671875, 0.037000000476837158203125, 0.0030000000260770320892333984375, 0.7469999790191650390625, 0.737999975681304931640625, 0.670000016689300537109375, 0.563000023365020751953125, 0.4309999942779541015625, 0.3039999902248382568359375, 0.1940000057220458984375, 0.1019999980926513671875, 0.0309999994933605194091796875, 0.614000022411346435546875, 0.609000027179718017578125, 0.566999971866607666015625, 0.499000012874603271484375, 0.412000000476837158203125, 0.32400000095367431640625, 0.240999996662139892578125, 0.162000000476837158203125, 0.087999999523162841796875, 0.538999974727630615234375, 0.535000026226043701171875, 0.505999982357025146484375, 0.4569999873638153076171875, 0.393999993801116943359375, 0.328999996185302734375, 0.2660000026226043701171875, 0.203999996185302734375, 0.14200000464916229248046875);\n\nstruct points_item\n{\n    vec4 pos;\n    vec4 tint;\n};\n\nuniform vec4 fa_mesh_fs_params[32];\nuniform vec4 fa_shadows[30];\nlayout(binding = 1, std430) readonly buffer fa_points_buf\n{\n    points_item data[];\n} points;\n\nlayout(binding = 0) uniform sampler2D fa_light_tex_fa_shadow_smp;\nlayout(binding = 1) uniform sampler2D fa_tex_fa_smp;\nlayout(binding = 2) uniform sampler2D fa_normal_tex_fa_smp;\nlayout(binding = 3) uniform sampler2D fa_mr_tex_fa_smp;\nlayout(binding = 4) uniform sampler2D fa_occlusion_tex_fa_smp;\nlayout(binding = 5) uniform sampler2D fa_emissive_tex_fa_smp;\nlayout(binding = 6) uniform sampler2D fa_decal_tex_fa_env_smp;\nlayout(binding = 7) uniform sampler2D fa_lightmap_fa_env_smp;\nlayout(binding = 8) uniform samplerCube fa_env_tex_fa_env_smp;\nlayout(binding = 9) uniform sampler2D fa_light_atlas_fa_env_smp;\nlayout(binding = 10) uniform sampler2D fa_shadow_tex_fa_shadow_smp;\nlayout(binding = 11) uniform sampler2D fa_screen_tex_fa_shadow_smp;\n\nlayout(location = 0) in vec3 fa_world_pos;\nlayout(location = 5) in vec3 fa_lm;\nlayout(location = 1) in vec3 fa_world_normal;\nlayout(location = 2) in vec4 fa_world_tangent;\nlayout(location = 3) in vec2 fa_uv;\nlayout(location = 4) in vec4 fa_vertex_color;\nlayout(location = 0) out vec4 fa_frag_color;\nvec3 fa_light_tint;\nbool fa_light_is_area;\nint fa_cl_ndir;\nint fa_cl_slot;\nint fa_cl_local;\n\nvoid fa_inst_load()\n{\n}\n\nvec4 fa_light_texel(int t)\n{\n    return texelFetch(fa_light_tex_fa_shadow_smp, ivec2(t & 1023, t >> 10), 0);\n}\n\nvec4 fa_cluster_texel(vec3 world_pos)\n{\n    bool _1529 = fa_mesh_fs_params[19].x < 0.0;\n    bool _1536;\n    if (!_1529)\n    {\n        _1536 = fa_mesh_fs_params[19].w < 1.0;\n    }\n    else\n    {\n        _1536 = _1529;\n    }\n    bool _1544;\n    if (!_1536)\n    {\n        _1544 = fa_mesh_fs_params[18].x < 1.0;\n    }\n    else\n    {\n        _1544 = _1536;\n    }\n    bool _1551;\n    if (!_1544)\n    {\n        _1551 = fa_mesh_fs_params[18].y < 1.0;\n    }\n    else\n    {\n        _1551 = _1544;\n    }\n    bool _1558;\n    if (!_1551)\n    {\n        _1558 = fa_mesh_fs_params[19].y < 1.0;\n    }\n    else\n    {\n        _1558 = _1551;\n    }\n    if (_1558)\n    {\n        return vec4(0.0);\n    }\n    vec4 _1568 = vec4(world_pos, 1.0);\n    float _1574 = dot(fa_mesh_fs_params[16], _1568);\n    if (!(_1574 > 9.9999999747524270787835121154785e-07))\n    {\n        return vec4(0.0);\n    }\n    vec2 _1596 = vec2(dot(fa_mesh_fs_params[14], _1568), dot(fa_mesh_fs_params[15], _1568)) / vec2(_1574);\n    int _1600 = int(fa_mesh_fs_params[18].x);\n    int _1604 = int(fa_mesh_fs_params[18].y);\n    int param = (int(fa_mesh_fs_params[19].x) + (((clamp(int(floor(log2(max(dot(fa_mesh_fs_params[17].xyz, world_pos) + fa_mesh_fs_params[17].w, fa_mesh_fs_params[18].w) / fa_mesh_fs_params[18].w) * fa_mesh_fs_params[18].z)), 0, int(fa_mesh_fs_params[19].y) - 1) * _1604) + clamp(int(floor(((_1596.y * 0.5) + 0.5) * fa_mesh_fs_params[18].y)), 0, _1604 - 1)) * _1600)) + clamp(int(floor(((_1596.x * 0.5) + 0.5) * fa_mesh_fs_params[18].x)), 0, _1600 - 1);\n    return fa_light_texel(param);\n}\n\nivec2 fa_cluster_lookup(vec3 world_pos)\n{\n    vec3 param = world_pos;\n    vec4 _1680 = fa_cluster_texel(param);\n    return ivec2(int(_1680.x), int(_1680.y));\n}\n\nvoid fa_cluster_begin(vec3 world_pos)\n{\n    fa_cl_ndir = int(fa_mesh_fs_params[19].z);\n    vec3 param = world_pos;\n    ivec2 _5121 = fa_cluster_lookup(param);\n    fa_cl_slot = _5121.x;\n    fa_cl_local = _5121.y;\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nvec3 fa_linear_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_tex_fix(inout vec3 c, float mode)\n{\n    if (mode > 1.5)\n    {\n        vec3 param = c;\n        vec3 _6264 = fa_linear_to_srgb(param);\n        c = _6264;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            vec3 param_1 = c;\n            vec3 _6272 = fa_srgb_to_linear(param_1);\n            c = _6272;\n        }\n    }\n    return c;\n}\n\nvec3 fa_tangent_normal(SurfaceInput i, vec3 m)\n{\n    vec3 _474;\n    if (i.front_facing)\n    {\n        _474 = i.world_normal;\n    }\n    else\n    {\n        _474 = -i.world_normal;\n    }\n    vec3 _498 = normalize(i.world_tangent.xyz - (_474 * dot(_474, i.world_tangent.xyz)));\n    vec3 _525 = normalize(((_498 * m.x) + ((cross(_474, _498) * i.world_tangent.w) * m.y)) + (_474 * m.z));\n    vec3 _528;\n    if (i.front_facing)\n    {\n        _528 = _525;\n    }\n    else\n    {\n        _528 = -_525;\n    }\n    return _528;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    vec4 base_t = texture(fa_tex_fa_smp, i.uv);\n    float param = fa_mesh_fs_params[6].w;\n    float param_1 = 1.0;\n    vec3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    vec3 _6303 = fa_tex_fix(param_2, param_3);\n    vec4 _7869 = base_t;\n    _7869.x = _6303.x;\n    _7869.y = _6303.y;\n    _7869.z = _6303.z;\n    base_t = _7869;\n    vec4 _6317 = (_7869 * fa_mesh_fs_params[2]) * i.vertex_color;\n    vec3 _7678 = i.world_normal;\n    if (fa_mesh_fs_params[6].z > 0.5)\n    {\n        float param_4 = fa_mesh_fs_params[6].w;\n        float param_5 = 16.0;\n        vec3 param_6 = texture(fa_normal_tex_fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        vec3 _6349 = fa_tex_fix(param_6, param_7);\n        vec3 _6352 = (_6349 * 2.0) - vec3(1.0);\n        vec2 _6357 = _6352.xy * fa_mesh_fs_params[6].x;\n        vec3 _7877 = _6352;\n        _7877.x = _6357.x;\n        _7877.y = _6357.y;\n        SurfaceInput param_8 = i;\n        vec3 param_9 = _7877;\n        _7678 = fa_tangent_normal(param_8, param_9);\n    }\n    vec4 mrt = texture(fa_mr_tex_fa_smp, i.uv);\n    float param_10 = fa_mesh_fs_params[6].w;\n    float param_11 = 64.0;\n    vec3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    vec3 _6385 = fa_tex_fix(param_12, param_13);\n    vec4 _7880 = mrt;\n    _7880.x = _6385.x;\n    _7880.y = _6385.y;\n    _7880.z = _6385.z;\n    mrt = _7880;\n    vec4 _6413 = texture(fa_occlusion_tex_fa_smp, i.uv);\n    float param_14 = fa_mesh_fs_params[6].w;\n    float param_15 = 256.0;\n    vec3 param_16 = _6413.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    vec3 _6424 = fa_tex_fix(param_16, param_17);\n    float param_18 = fa_mesh_fs_params[6].w;\n    float param_19 = 4.0;\n    vec3 param_20 = texture(fa_emissive_tex_fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    vec3 _6454 = fa_tex_fix(param_20, param_21);\n    float _7683 = fa_mesh_fs_params[20].x;\n    float _7684 = fa_mesh_fs_params[20].y;\n    float _7687 = fa_mesh_fs_params[20].z;\n    float _7686 = fa_mesh_fs_params[21].w;\n    float _7689 = fa_mesh_fs_params[22].x;\n    if (fa_mesh_fs_params[22].z > 0.5)\n    {\n        if (mod(fa_mesh_fs_params[22].z, 2.0) > 0.5)\n        {\n            _7683 *= _6424.y;\n            _7684 *= _6424.z;\n            _7686 *= _6413.w;\n        }\n        if (fa_mesh_fs_params[22].z > 1.5)\n        {\n            _7687 *= mrt.x;\n            _7689 *= mrt.w;\n        }\n    }\n    return Surface(_6317.xyz, _6317.w, _7678, clamp(fa_mesh_fs_params[5].x * _6385.z, 0.0, 1.0), clamp(fa_mesh_fs_params[5].y * _6385.y, 0.0500000007450580596923828125, 1.0), 1.0 + (fa_mesh_fs_params[6].y * (_6424.x - 1.0)), fa_mesh_fs_params[3].xyz + (fa_mesh_fs_params[4].xyz * _6454), _7683, _7684, fa_mesh_fs_params[21].xyz, _7686, _7687, fa_mesh_fs_params[20].w, _7689, fa_mesh_fs_params[22].y, fa_mesh_fs_params[23].xyz, fa_mesh_fs_params[30].x, fa_mesh_fs_params[30].y, fa_mesh_fs_params[31].xyz, fa_mesh_fs_params[30].z);\n}\n\nvoid surface(SurfaceInput i, inout Surface s)\n{\n    s.emission += (i.vertex_color.xyz * points.data[0].tint.w);\n}\n\nvec4 fa_decal_tile(vec4 rect, vec2 uv, vec2 atlas, vec2 ddx, vec2 ddy)\n{\n    vec2 _1760 = rect.zw - rect.xy;\n    vec2 _1764 = _1760 * atlas;\n    vec2 _1768 = ddx * _1764;\n    vec2 _1772 = ddy * _1764;\n    return textureLod(fa_decal_tex_fa_env_smp, rect.xy + (clamp(uv, vec2(0.0), vec2(1.0)) * _1760), clamp(0.5 * log2(max(max(dot(_1768, _1768), dot(_1772, _1772)), 9.9999999392252902907785028219223e-09)), 0.0, 4.0));\n}\n\nvec3 fa_dc_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_dc_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvoid fa_apply_decals(vec3 world_pos, vec3 geo_normal, inout vec3 albedo, inout vec3 normal)\n{\n    bool _1805 = fa_mesh_fs_params[10].y < 0.5;\n    bool _1812;\n    if (!_1805)\n    {\n        _1812 = fa_mesh_fs_params[10].w < 0.5;\n    }\n    else\n    {\n        _1812 = _1805;\n    }\n    if (_1812)\n    {\n        return;\n    }\n    vec3 _1818 = dFdx(world_pos);\n    vec3 _1821 = dFdy(world_pos);\n    vec3 param = world_pos;\n    vec4 _1825 = fa_cluster_texel(param);\n    int _1829 = int(_1825.w);\n    if (_1829 < 1)\n    {\n        return;\n    }\n    int _1839 = int(fa_mesh_fs_params[10].y + 0.5);\n    int param_1 = _1839;\n    vec4 _1843 = fa_light_texel(param_1);\n    vec2 _1846 = _1843.yz;\n    int _1850 = int(_1843.w);\n    int param_2 = _1839 + 1;\n    vec4 _1855 = fa_light_texel(param_2);\n    float _1856 = _1855.x;\n    int _1862 = int(fa_mesh_fs_params[10].w + 0.5) - 1;\n    int _1866 = int(_1825.z);\n    vec3 _2131;\n    for (int k = 0; k < _1829; k++)\n    {\n        int _1879 = _1866 + k;\n        int param_3 = _1850 + (_1879 >> 2);\n        int _1896 = (_1839 + 2) + (int(fa_light_texel(param_3)[_1879 & 3]) * 7);\n        int param_4 = _1896 + 6;\n        vec4 _1901 = fa_light_texel(param_4);\n        if (((int(_1901.w + 0.5) >> _1862) & 1) == 0)\n        {\n            continue;\n        }\n        int param_5 = _1896;\n        vec4 _1916 = fa_light_texel(param_5);\n        int param_6 = _1896 + 1;\n        vec4 _1921 = fa_light_texel(param_6);\n        int param_7 = _1896 + 2;\n        vec4 _1926 = fa_light_texel(param_7);\n        vec3 _1929 = _1916.xyz;\n        float _1934 = dot(_1929, world_pos) + _1916.w;\n        vec3 _1936 = _1921.xyz;\n        float _1941 = dot(_1936, world_pos) + _1921.w;\n        vec3 _1943 = _1926.xyz;\n        float _1948 = dot(_1943, world_pos) + _1926.w;\n        bool _1953 = abs(_1934) > 0.5;\n        bool _1961;\n        if (!_1953)\n        {\n            _1961 = abs(_1941) > 0.5;\n        }\n        else\n        {\n            _1961 = _1953;\n        }\n        bool _1969;\n        if (!_1961)\n        {\n            _1969 = abs(_1948) > 0.5;\n        }\n        else\n        {\n            _1969 = _1961;\n        }\n        if (_1969)\n        {\n            continue;\n        }\n        float _1984 = clamp(dot(geo_normal, normalize(_1943)) * _1901.z, 0.0, 1.0);\n        if (_1984 <= 0.0)\n        {\n            continue;\n        }\n        float _2004 = (clamp((0.5 - abs(_1948)) * 10.0, 0.0, 1.0) * _1984) * _1901.x;\n        vec2 _2012 = vec2(_1934 + 0.5, 0.5 - _1941);\n        vec2 _2022 = vec2(dot(_1929, _1818), dot(_1936, _1818));\n        vec2 _2032 = vec2(dot(_1929, _1821), dot(_1936, _1821));\n        int param_8 = _1896 + 5;\n        vec4 _2037 = fa_light_texel(param_8);\n        int param_9 = _1896 + 3;\n        vec4 _2042 = fa_light_texel(param_9);\n        int param_10 = _1896 + 4;\n        vec4 _2047 = fa_light_texel(param_10);\n        float tex_a = 1.0;\n        vec3 col = _2037.xyz;\n        bool _2057 = _2042.z > _2042.x;\n        if (_2057)\n        {\n            vec4 param_11 = _2042;\n            vec2 param_12 = _2012;\n            vec2 param_13 = _1846;\n            vec2 param_14 = _2022;\n            vec2 param_15 = _2032;\n            vec4 tx = fa_decal_tile(param_11, param_12, param_13, param_14, param_15);\n            if ((_1856 > 0.5) && (_1856 < 1.5))\n            {\n                vec3 param_16 = tx.xyz;\n                vec3 _2083 = fa_dc_to_linear(param_16);\n                vec4 _7766 = tx;\n                _7766.x = _2083.x;\n                _7766.y = _2083.y;\n                _7766.z = _2083.z;\n                tx = _7766;\n            }\n            col *= tx.xyz;\n            tex_a = tx.w;\n        }\n        albedo = mix(albedo, col, vec3(clamp((_2004 * tex_a) * _2037.w, 0.0, 1.0)));\n        if (_2047.z > _2047.x)\n        {\n            vec4 param_17 = _2047;\n            vec2 param_18 = _2012;\n            vec2 param_19 = _1846;\n            vec2 param_20 = _2022;\n            vec2 param_21 = _2032;\n            vec4 _2127 = fa_decal_tile(param_17, param_18, param_19, param_20, param_21);\n            if (_1856 > 1.5)\n            {\n                vec3 param_22 = _2127.xyz;\n                vec3 _2137 = fa_dc_to_srgb(param_22);\n                _2131 = _2137;\n            }\n            else\n            {\n                _2131 = _2127.xyz;\n            }\n            vec3 _2146 = (_2131 * 2.0) - vec3(1.0);\n            vec2 _2151 = _2146.xy * _1901.y;\n            vec3 _2173 = (normalize(_1929) * _2151.x) + (normalize(_1936) * _2151.y);\n            vec3 _2176 = normalize(normal);\n            normal = normalize(mix(_2176, normalize((_2176 * max(_2146.z, 0.0500000007450580596923828125)) + (_2173 - (_2176 * dot(_2176, _2173)))), vec3(clamp(_2004 * (_2057 ? tex_a : 1.0), 0.0, 1.0))));\n        }\n    }\n}\n\nfloat fa_sheen_albedo(float ndv, float rough)\n{\n    float _3614 = min(sqrt(max(rough - 0.100000001490116119384765625, 0.0) * 1.111111164093017578125) * 6.0, 5.999000072479248046875);\n    float _3621 = min(sqrt(clamp(ndv, 0.0, 1.0)) * 8.0, 7.999000072479248046875);\n    int _3624 = int(_3614);\n    int _3627 = int(_3621);\n    float _3637 = _3621 - float(_3627);\n    int _3692 = (_3624 * 9) + _3627;\n    int _3712 = ((_3624 + 1) * 9) + _3627;\n    return mix(mix(_3688[_3692], _3688[_3692 + 1], _3637), mix(_3688[_3712], _3688[_3712 + 1], _3637), _3614 - float(_3624));\n}\n\nFaLayers fa_layers_setup(SurfaceInput i, Surface s, vec3 n, vec3 v, float metallic, float roughness, inout vec3 f0)\n{\n    bool _7601 = false;\n    float _7602 = 1.0;\n    float _7603 = 1.0;\n    float _7604 = 1.0;\n    float _7605 = 0.0;\n    float _7606 = 0.0;\n    float _7607 = 0.0;\n    float _7608 = 0.0;\n    float _7610 = 1.0;\n    bool _7611 = false;\n    vec3 _7612 = vec3(0.0);\n    float _7613 = 1.0;\n    float _7614 = 1.0;\n    float _7615 = 1.0;\n    float _7616 = 0.0;\n    float _7617 = 0.0;\n    vec3 _7618 = vec3(1.0, 0.0, 0.0);\n    vec3 _7619 = vec3(0.0, 0.0, 1.0);\n    float _7620 = 1.0;\n    float _7621 = 1.0;\n    float _3763 = clamp(s.specular, 0.0, 1.0);\n    float _3767 = clamp(s.ior, 1.0, 3.0);\n    bool _3772 = (_3763 != 1.0) || (_3767 != 1.5);\n    bool _3781;\n    if (!_3772)\n    {\n        _3781 = any(notEqual(s.specular_color, vec3(1.0)));\n    }\n    else\n    {\n        _3781 = _3772;\n    }\n    if (_3781)\n    {\n        float _3789 = (_3767 - 1.0) / (_3767 + 1.0);\n        f0 = mix(min(vec3(_3789 * _3789) * max(s.specular_color, vec3(0.0)), vec3(1.0)) * _3763, s.albedo, vec3(metallic));\n        _7602 = mix(_3763, 1.0, metallic);\n        _7601 = true;\n    }\n    float _3816 = clamp(s.clearcoat, 0.0, 1.0);\n    if (_3816 > 0.0)\n    {\n        float _3824 = clamp(s.clearcoat_roughness, 0.0500000007450580596923828125, 1.0);\n        _7605 = _3816;\n        _7606 = _3824;\n        float _3831 = _3824 * _3824;\n        _7607 = _3831;\n        _7608 = _3831 * _3831;\n        float _3843 = max(dot(i.world_normal, v), 9.9999997473787516355514526367188e-05);\n        _7610 = _3843;\n        _7603 = 1.0 - (_3816 * (0.039999999105930328369140625 + (0.959999978542327880859375 * pow(clamp(1.0 - _3843, 0.0, 1.0), 5.0))));\n        _7601 = true;\n    }\n    vec3 _3862 = max(s.sheen_color, vec3(0.0));\n    float _3871 = max(_3862.x, max(_3862.y, _3862.z));\n    if (_3871 > 0.0)\n    {\n        float _3879 = clamp(s.sheen_roughness, 0.100000001490116119384765625, 1.0);\n        _7611 = true;\n        _7612 = _3862;\n        _7613 = _3879;\n        _7614 = _3879 * _3879;\n        float param = max(dot(n, v), 9.9999997473787516355514526367188e-05);\n        float param_1 = _3879;\n        float _3896 = fa_sheen_albedo(param, param_1);\n        _7616 = _3896;\n        _7615 = 1.0 - min(_3871 * _3896, 1.0);\n        _7601 = true;\n    }\n    _7604 = _7603 * _7615;\n    float _3915 = clamp(s.anisotropy, -1.0, 1.0);\n    if (_3915 != 0.0)\n    {\n        vec3 _3930 = i.world_tangent.xyz - (n * dot(n, i.world_tangent.xyz));\n        vec3 t = _3930;\n        if (dot(_3930, _3930) < 9.9999999392252902907785028219223e-09)\n        {\n            bvec3 _3942 = bvec3(abs(n.y) < 0.9900000095367431640625);\n            t = cross(vec3(_3942.x ? vec3(0.0, 1.0, 0.0).x : vec3(1.0, 0.0, 0.0).x, _3942.y ? vec3(0.0, 1.0, 0.0).y : vec3(1.0, 0.0, 0.0).y, _3942.z ? vec3(0.0, 1.0, 0.0).z : vec3(1.0, 0.0, 0.0).z), n);\n        }\n        vec3 _3946 = t;\n        vec3 _3947 = normalize(_3946);\n        t = _3947;\n        vec3 _3972 = normalize((_3947 * cos(s.anisotropy_rotation)) + ((cross(n, _3947) * ((i.world_tangent.w < 0.0) ? (-1.0) : 1.0)) * sin(s.anisotropy_rotation)));\n        _7618 = _3972;\n        _7619 = cross(n, _3972);\n        float _3982 = roughness * roughness;\n        float _3988 = mix(_3982, 1.0, _3915 * _3915);\n        bool _3990 = _3915 > 0.0;\n        _7620 = _3990 ? _3988 : _3982;\n        _7621 = _3990 ? _3982 : _3988;\n        _7617 = _3915;\n        _7601 = true;\n    }\n    return FaLayers(_7601, _7602, _7603, _7604, _7605, _7606, _7607, _7608, i.world_normal, _7610, _7611, _7612, _7613, _7614, _7615, _7616, _7617, _7618, _7619, _7620, _7621);\n}\n\nvec3 fa_sky_sh_coef(int k)\n{\n    vec3 v = textureLod(fa_env_tex_fa_env_smp, vec3(1.0, 1.0 - (float((2 * (k >> 2)) + 1) * 0.25), 1.0 - (float((2 * (k & 3)) + 1) * 0.25)), 5.0).xyz;\n    if (fa_mesh_fs_params[11].w > 1.5)\n    {\n        v = (v - vec3(0.5)) * 8.0;\n    }\n    return v;\n}\n\nvec3 fa_sh_eval(vec3 c[9], vec3 n)\n{\n    vec3 _3371 = max((((c[0] * 0.2820948064327239990234375) + (((c[1] * (0.3257350027561187744140625 * n.y)) + (c[2] * (0.3257350027561187744140625 * n.z))) + (c[3] * (0.3257350027561187744140625 * n.x)))) + (((c[4] * ((0.2731371223926544189453125 * n.x) * n.y)) + (c[5] * ((0.2731371223926544189453125 * n.y) * n.z))) + (c[6] * (0.078847892582416534423828125 * (((3.0 * n.z) * n.z) - 1.0))))) + ((c[7] * ((0.2731371223926544189453125 * n.x) * n.z)) + (c[8] * (0.13656856119632720947265625 * ((n.x * n.x) - (n.y * n.y))))), vec3(0.0));\n    return _3371;\n}\n\nvec3 fa_ambient_light(vec3 n)\n{\n    if (fa_mesh_fs_params[11].w > 0.5)\n    {\n        vec3 c[9];\n        for (int k = 0; k < 9; k++)\n        {\n            int param = k;\n            c[k] = fa_sky_sh_coef(param);\n        }\n        vec3 param_1[9] = c;\n        vec3 param_2 = n;\n        return fa_sh_eval(param_1, param_2);\n    }\n    return fa_mesh_fs_params[1].xyz;\n}\n\nvec3 fa_indirect_diffuse(vec3 n)\n{\n    if (fa_lm.z > 0.5)\n    {\n        return textureLod(fa_lightmap_fa_env_smp, fa_lm.xy, 0.0).xyz;\n    }\n    vec3 param = n;\n    return fa_ambient_light(param);\n}\n\nint fa_cluster_index(int slot, int n)\n{\n    int param = (int(fa_mesh_fs_params[19].x) + int(fa_mesh_fs_params[19].w)) + ((slot + n) >> 2);\n    vec4 t = fa_light_texel(param);\n    return int(t[(slot + n) & 3]);\n}\n\nint fa_cl_light(int n)\n{\n    if (n < fa_cl_ndir)\n    {\n        return n;\n    }\n    int param = fa_cl_slot;\n    int param_1 = n - fa_cl_ndir;\n    return fa_cluster_index(param, param_1);\n}\n\nint fa_light_base(int li)\n{\n    return li * ((fa_mesh_fs_params[1].w > 4.5) ? 8 : 4);\n}\n\nbool fa_light_baked(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 3;\n    return fa_light_texel(param_1).w > 0.5;\n}\n\nfloat fa_light_type(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 1;\n    return fa_light_texel(param_1).w;\n}\n\nvec4 fa_atlas_fetch(vec2 texel)\n{\n    return textureLod(fa_light_atlas_fa_env_smp, texel / vec2(textureSize(fa_light_atlas_fa_env_smp, 0)), 0.0);\n}\n\nvec3 fa_cookie_sample(vec2 tile_origin, vec2 uv)\n{\n    vec2 param = (tile_origin + vec2(1.0)) + (clamp(uv, vec2(0.0), vec2(1.0)) * 254.0);\n    return fa_atlas_fetch(param).xyz;\n}\n\nvec3 fa_area_point(vec3 c, vec3 axis, vec3 ru, vec3 uu, float hx, float hy, float shape, vec3 p, vec3 r)\n{\n    bool _778 = dot(r, r) > 0.5;\n    if (shape > 1.5)\n    {\n        vec3 _791 = (c - (ru * hx)) - p;\n        vec3 _797 = ru * (2.0 * hx);\n        float _803 = max(dot(_797, _797), 9.9999999392252902907785028219223e-09);\n        float _807 = dot(_791, _797);\n        float t = clamp((-_807) / _803, 0.0, 1.0);\n        if (_778)\n        {\n            float _822 = dot(r, _797);\n            float _828 = _803 - (_822 * _822);\n            if (abs(_828) > (9.9999997473787516355514526367188e-06 * _803))\n            {\n                t = clamp(((dot(r, _791) * _822) - _807) / _828, 0.0, 1.0);\n            }\n        }\n        return (p + _791) + (_797 * t);\n    }\n    vec3 q = p;\n    float _860 = dot(r, axis);\n    bool _868;\n    if (_778)\n    {\n        _868 = abs(_860) > 9.9999997473787516355514526367188e-05;\n    }\n    else\n    {\n        _868 = _778;\n    }\n    if (_868)\n    {\n        float _878 = dot(c - p, axis) / _860;\n        if (_878 > 0.0)\n        {\n            q = p + (r * _878);\n        }\n    }\n    vec3 _891 = q - c;\n    vec2 xy = vec2(dot(_891, ru), dot(_891, uu));\n    if (shape > 0.5)\n    {\n        float _906 = length(xy);\n        if (_906 > hx)\n        {\n            xy *= (hx / _906);\n        }\n    }\n    else\n    {\n        xy = clamp(xy, vec2(-hx, -hy), vec2(hx, hy));\n    }\n    return (c + (ru * xy.x)) + (uu * xy.y);\n}\n\nint fa_cube_face(vec3 d)\n{\n    vec3 _540 = abs(d);\n    float _542 = _540.x;\n    float _544 = _540.y;\n    bool _545 = _542 >= _544;\n    bool _553;\n    if (_545)\n    {\n        _553 = _542 >= _540.z;\n    }\n    else\n    {\n        _553 = _545;\n    }\n    int _554;\n    if (_553)\n    {\n        _554 = (d.x > 0.0) ? 0 : 1;\n    }\n    else\n    {\n        int _569;\n        if (_544 >= _540.z)\n        {\n            _569 = (d.y > 0.0) ? 2 : 3;\n        }\n        else\n        {\n            _569 = (d.z > 0.0) ? 4 : 5;\n        }\n        _554 = _569;\n    }\n    return _554;\n}\n\nvoid fa_cube_face_basis(int f, out vec3 fwd, out vec3 up)\n{\n    if (f == 0)\n    {\n        fwd = vec3(1.0, 0.0, 0.0);\n        up = vec3(0.0, 1.0, 0.0);\n    }\n    else\n    {\n        if (f == 1)\n        {\n            fwd = vec3(-1.0, 0.0, 0.0);\n            up = vec3(0.0, 1.0, 0.0);\n        }\n        else\n        {\n            if (f == 2)\n            {\n                fwd = vec3(0.0, 1.0, 0.0);\n                up = vec3(0.0, 0.0, 1.0);\n            }\n            else\n            {\n                if (f == 3)\n                {\n                    fwd = vec3(0.0, -1.0, 0.0);\n                    up = vec3(0.0, 0.0, -1.0);\n                }\n                else\n                {\n                    if (f == 4)\n                    {\n                        fwd = vec3(0.0, 0.0, 1.0);\n                        up = vec3(0.0, 1.0, 0.0);\n                    }\n                    else\n                    {\n                        fwd = vec3(0.0, 0.0, -1.0);\n                        up = vec3(0.0, 1.0, 0.0);\n                    }\n                }\n            }\n        }\n    }\n}\n\nfloat fa_ies_sample(vec2 tile_origin, vec3 d, vec3 axis, vec3 right, vec3 up)\n{\n    float _698 = dot(d, right);\n    float _702 = dot(d, up);\n    float _713;\n    if (((_698 * _698) + (_702 * _702)) > 1.0000000133514319600180897396058e-10)\n    {\n        _713 = atan(_702, _698) * 0.15915493667125701904296875;\n    }\n    else\n    {\n        _713 = 0.0;\n    }\n    vec2 param = tile_origin + vec2(1.0 + ((_713 - floor(_713)) * 64.0), 1.0 + (acos(clamp(dot(d, axis), -1.0, 1.0)) * 10.18591594696044921875));\n    return fa_atlas_fetch(param).x;\n}\n\nLightSample fa_light_sample_n(int li, vec3 world_pos, vec3 n)\n{\n    int param = li;\n    int _944 = fa_light_base(param);\n    bool _948 = fa_mesh_fs_params[1].w > 4.5;\n    int param_1 = _944;\n    vec4 _952 = fa_light_texel(param_1);\n    int param_2 = _944 + 1;\n    vec4 _957 = fa_light_texel(param_2);\n    float _960 = _957.w;\n    float atten = 1.0;\n    float dist = 0.0;\n    fa_light_tint = vec3(1.0);\n    bool _972 = _948 && (_960 > 2.5);\n    fa_light_is_area = _972;\n    bool _974 = _960 < 0.5;\n    vec3 l;\n    if (_974)\n    {\n        l = normalize(_952.xyz);\n        if (_948)\n        {\n            int param_3 = _944 + 6;\n            vec4 _988 = fa_light_texel(param_3);\n            if (_988.z > 0.5)\n            {\n                int param_4 = _944 + 4;\n                vec4 _998 = fa_light_texel(param_4);\n                int param_5 = _944 + 5;\n                vec4 _1003 = fa_light_texel(param_5);\n                vec2 param_6 = _988.xy;\n                vec2 param_7 = fract(vec2(dot(world_pos, _998.xyz) * _998.w, (-dot(world_pos, _1003.xyz)) * _1003.w) + vec2(0.5));\n                fa_light_tint = fa_cookie_sample(param_6, param_7);\n            }\n        }\n    }\n    else\n    {\n        vec3 _1033 = _952.xyz;\n        vec3 _1035 = _1033 - world_pos;\n        vec3 to_light = _1035;\n        float _1038 = length(_1035);\n        float reach = _1038;\n        bool front = true;\n        if (_972)\n        {\n            int param_8 = _944 + 7;\n            reach = max(_1038 - fa_light_texel(param_8).w, 0.0);\n            int param_9 = _944 + 4;\n            vec4 _1062 = fa_light_texel(param_9);\n            int param_10 = _944 + 5;\n            vec4 _1067 = fa_light_texel(param_10);\n            int param_11 = _944 + 6;\n            vec4 _1072 = fa_light_texel(param_11);\n            float _1073 = _1072.w;\n            int param_12 = _944 + 2;\n            vec3 _1080 = normalize(fa_light_texel(param_12).xyz);\n            bool _1082 = _1073 > 1.5;\n            bool _1090;\n            if (!_1082)\n            {\n                _1090 = dot(_1080, to_light) < 0.0;\n            }\n            else\n            {\n                _1090 = _1082;\n            }\n            front = _1090;\n            vec3 r = vec3(0.0);\n            vec3 _1099 = fa_mesh_fs_params[0].xyz - world_pos;\n            bool _1103 = dot(n, n) > 0.5;\n            bool _1111;\n            if (_1103)\n            {\n                _1111 = dot(_1099, _1099) > 9.9999999600419720025001879548654e-13;\n            }\n            else\n            {\n                _1111 = _1103;\n            }\n            if (_1111)\n            {\n                r = reflect(-normalize(_1099), normalize(n));\n            }\n            vec3 param_13 = _1033;\n            vec3 param_14 = _1080;\n            vec3 param_15 = _1062.xyz;\n            vec3 param_16 = _1067.xyz;\n            float param_17 = _1062.w;\n            float param_18 = _1067.w;\n            float param_19 = _1073;\n            vec3 param_20 = world_pos;\n            vec3 param_21 = r;\n            to_light = fa_area_point(param_13, param_14, param_15, param_16, param_17, param_18, param_19, param_20, param_21) - world_pos;\n        }\n        float _1147 = length(to_light);\n        dist = _1147;\n        l = to_light / vec3(max(_1147, 9.9999997473787516355514526367188e-05));\n        float _1161 = reach / max(_952.w, 0.001000000047497451305389404296875);\n        float _1167 = clamp(1.0 - (_1161 * _1161), 0.0, 1.0);\n        float _1169;\n        if (front)\n        {\n            _1169 = _1167 * _1167;\n        }\n        else\n        {\n            _1169 = 0.0;\n        }\n        atten = _1169;\n        bool _1180 = _960 < 2.5;\n        if ((_960 > 1.5) && _1180)\n        {\n            int param_22 = _944 + 2;\n            vec4 _1188 = fa_light_texel(param_22);\n            float _1198 = _1188.w;\n            int param_23 = _944 + 3;\n            vec4 _1203 = fa_light_texel(param_23);\n            float _1204 = _1203.x;\n            float cos_inner = _1204;\n            if (_1204 > 1.5)\n            {\n                cos_inner = mix(_1198, 1.0, 0.25);\n            }\n            atten *= smoothstep(_1198, cos_inner, dot(-l, normalize(_1188.xyz)));\n        }\n        if (_948 && (_960 < 1.5))\n        {\n            int param_24 = _944 + 6;\n            vec4 _1228 = fa_light_texel(param_24);\n            if (_1228.z > 0.5)\n            {\n                vec3 _1236 = -to_light;\n                int param_25 = _944 + 4;\n                int param_26 = _944 + 5;\n                vec3 _1250 = fa_light_texel(param_25).xyz;\n                vec3 _1254 = fa_light_texel(param_26).xyz;\n                vec3 _1263 = vec3(dot(_1236, _1250), dot(_1236, _1254), dot(_1236, cross(_1250, _1254)));\n                vec3 param_27 = _1263;\n                int _1267 = fa_cube_face(param_27);\n                int param_28 = _1267;\n                vec3 param_29;\n                vec3 param_30;\n                fa_cube_face_basis(param_28, param_29, param_30);\n                vec2 _1294 = vec2(dot(_1263, cross(param_29, param_30)), dot(_1263, param_30)) / vec2(max(dot(_1263, param_29), 9.9999997473787516355514526367188e-05));\n                int _1298 = _1267 / 3;\n                vec2 param_31 = _1228.xy + (vec2(float(_1267 - (_1298 * 3)), float(_1298)) * 256.0);\n                vec2 param_32 = vec2(0.5 + (0.5 * _1294.x), 0.5 - (0.5 * _1294.y));\n                fa_light_tint = fa_cookie_sample(param_31, param_32);\n            }\n            int param_33 = _944 + 7;\n            vec4 _1328 = fa_light_texel(param_33);\n            if (_1328.z > 0.5)\n            {\n                int param_34 = _944 + 2;\n                int param_35 = _944 + 4;\n                int param_36 = _944 + 5;\n                vec2 param_37 = _1328.xy;\n                vec3 param_38 = -l;\n                vec3 param_39 = normalize(fa_light_texel(param_34).xyz);\n                vec3 param_40 = fa_light_texel(param_35).xyz;\n                vec3 param_41 = fa_light_texel(param_36).xyz;\n                atten *= fa_ies_sample(param_37, param_38, param_39, param_40, param_41);\n            }\n        }\n        else\n        {\n            if (_948 && _1180)\n            {\n                int param_42 = _944 + 6;\n                vec4 _1375 = fa_light_texel(param_42);\n                int param_43 = _944 + 7;\n                vec4 _1380 = fa_light_texel(param_43);\n                bool _1383 = _1375.z > 0.5;\n                bool _1390;\n                if (!_1383)\n                {\n                    _1390 = _1380.z > 0.5;\n                }\n                else\n                {\n                    _1390 = _1383;\n                }\n                if (_1390)\n                {\n                    int param_44 = _944 + 2;\n                    vec4 _1397 = fa_light_texel(param_44);\n                    vec3 _1401 = normalize(_1397.xyz);\n                    int param_45 = _944 + 4;\n                    vec4 _1406 = fa_light_texel(param_45);\n                    int param_46 = _944 + 5;\n                    vec4 _1411 = fa_light_texel(param_46);\n                    if (_1383)\n                    {\n                        vec3 _1419 = -to_light;\n                        float _1426 = _1397.w;\n                        float _1442 = 0.5 / max(dot(_1419, _1401) * (sqrt(max(1.0 - (_1426 * _1426), 0.0)) / max(_1426, 0.001000000047497451305389404296875)), 9.9999997473787516355514526367188e-05);\n                        vec2 param_47 = _1375.xy;\n                        vec2 param_48 = vec2(0.5 + (dot(_1419, _1406.xyz) * _1442), 0.5 - (dot(_1419, _1411.xyz) * _1442));\n                        fa_light_tint = fa_cookie_sample(param_47, param_48);\n                    }\n                    if (_1380.z > 0.5)\n                    {\n                        vec2 param_49 = _1380.xy;\n                        vec3 param_50 = -l;\n                        vec3 param_51 = _1401;\n                        vec3 param_52 = _1406.xyz;\n                        vec3 param_53 = _1411.xyz;\n                        atten *= fa_ies_sample(param_49, param_50, param_51, param_52, param_53);\n                    }\n                }\n            }\n        }\n    }\n    vec3 _7589 = _957.xyz * atten;\n    if (_948)\n    {\n        _7589 *= fa_light_tint;\n    }\n    int _1511;\n    if (_974)\n    {\n        _1511 = 0;\n    }\n    else\n    {\n        _1511 = ((_960 > 1.5) && (_960 < 2.5)) ? 2 : 1;\n    }\n    return LightSample(l, _7589, atten, 1.0, dist, _1511);\n}\n\nfloat fa_shadow_split_at(int i)\n{\n    float _2248;\n    if (i == 0)\n    {\n        _2248 = fa_shadows[24].x;\n    }\n    else\n    {\n        float _2264;\n        if (i == 1)\n        {\n            _2264 = fa_shadows[24].y;\n        }\n        else\n        {\n            float _2272;\n            if (i == 2)\n            {\n                _2272 = fa_shadows[24].z;\n            }\n            else\n            {\n                _2272 = fa_shadows[24].w;\n            }\n            _2264 = _2272;\n        }\n        _2248 = _2264;\n    }\n    return _2248;\n}\n\nfloat fa_shadow_depth(inout vec2 uv, vec4 rect)\n{\n    uv = clamp(uv, rect.xy, rect.zw);\n    return textureLod(fa_shadow_tex_fa_shadow_smp, uv, 0.0).x;\n}\n\nfloat fa_shadow_fetch(vec2 uv, vec4 rect, vec3 conv)\n{\n    vec2 param = uv;\n    vec4 param_1 = rect;\n    float _2305 = fa_shadow_depth(param, param_1);\n    float _2309;\n    if (conv.x < 0.5)\n    {\n        _2309 = _2305;\n    }\n    else\n    {\n        _2309 = (conv.y * conv.z) / (conv.z - (_2305 * (conv.z - conv.y)));\n    }\n    return _2309;\n}\n\nfloat fa_shadow_noise()\n{\n    return fract(52.98291778564453125 * fract(dot(gl_FragCoord.xy, vec2(0.067110560834407806396484375, 0.005837149918079376220703125))));\n}\n\nvec2 fa_shadow_vogel(int k, int n, float phi)\n{\n    float _2236 = (float(k) * 2.3999631404876708984375) + phi;\n    return vec2(cos(_2236), sin(_2236)) * sqrt((float(k) + 0.5) / float(n));\n}\n\nfloat fa_shadow_filter(vec2 uv, vec4 rect, float zr, float texel_m, float unit, float reach, float plane, vec3 conv, int mode, float k)\n{\n    if (mode == 1)\n    {\n        vec2 param = uv;\n        vec4 param_1 = rect;\n        vec3 param_2 = conv;\n        return float(zr <= fa_shadow_fetch(param, param_1, param_2));\n    }\n    float _2355 = fa_shadow_noise() * 6.283185482025146484375;\n    float radius = 1.5;\n    if (mode == 2)\n    {\n        float _2364;\n        if (k < 0.0)\n        {\n            _2364 = (-k) / max(zr, 0.100000001490116119384765625);\n        }\n        else\n        {\n            _2364 = k;\n        }\n        float _2384 = clamp((_2364 * reach) / texel_m, 3.0, 12.0);\n        float sum = 0.0;\n        float cnt = 0.0;\n        for (int i = 0; i < 16; i++)\n        {\n            int param_3 = i;\n            int param_4 = 16;\n            float param_5 = _2355;\n            vec2 _2403 = fa_shadow_vogel(param_3, param_4, param_5) * _2384;\n            vec2 param_6 = uv + (_2403 * fa_shadows[26].zw);\n            vec4 param_7 = rect;\n            vec3 param_8 = conv;\n            float _2415 = fa_shadow_fetch(param_6, param_7, param_8);\n            if (_2415 < (zr - (length(_2403) * plane)))\n            {\n                sum += _2415;\n                cnt += 1.0;\n            }\n        }\n        if (cnt < 0.5)\n        {\n            return 1.0;\n        }\n        float _2441 = sum / cnt;\n        float _2451;\n        if (k < 0.0)\n        {\n            _2451 = (-k) / max(_2441, 0.0500000007450580596923828125);\n        }\n        else\n        {\n            _2451 = k;\n        }\n        radius = clamp(((max(zr - _2441, 0.0) * unit) * _2451) / texel_m, 1.5, 16.0);\n    }\n    float lit = 0.0;\n    int _2473 = (mode == 2) ? 24 : 16;\n    for (int i_1 = 0; i_1 < _2473; i_1++)\n    {\n        int param_9 = i_1;\n        int param_10 = _2473;\n        float param_11 = _2355;\n        vec2 _2492 = fa_shadow_vogel(param_9, param_10, param_11) * radius;\n        vec2 param_12 = uv + (_2492 * fa_shadows[26].zw);\n        vec4 param_13 = rect;\n        vec3 param_14 = conv;\n        lit += float((zr - (length(_2492) * plane)) <= fa_shadow_fetch(param_12, param_13, param_14));\n    }\n    return lit / float(_2473);\n}\n\nfloat fa_shadow_cascade(int ci, vec3 world, vec3 n, vec3 l)\n{\n    float _2534 = max(fa_shadows[ci * 1 + 20].y, 0.001000000047497451305389404296875);\n    float _2539 = clamp(dot(n, l), 0.0, 1.0);\n    float _2545 = sqrt(1.0 - (_2539 * _2539));\n    float _2552 = min(_2545 / max(_2539, 0.20000000298023223876953125), 4.0);\n    float _2557;\n    if (fa_shadows[26].y > 0.0)\n    {\n        _2557 = fa_shadows[26].y;\n    }\n    else\n    {\n        _2557 = 1.5 * fa_shadows[ci * 1 + 20].x;\n    }\n    vec4 _2582 = mat4(fa_shadows[ci * 4 + 0], fa_shadows[ci * 4 + 1], fa_shadows[ci * 4 + 2], fa_shadows[ci * 4 + 3]) * vec4(world + (n * (_2557 * _2545)), 1.0);\n    float _2589 = _2582.x;\n    bool _2592 = _2589 < fa_shadows[ci * 1 + 16].x;\n    bool _2601;\n    if (!_2592)\n    {\n        _2601 = _2589 > fa_shadows[ci * 1 + 16].z;\n    }\n    else\n    {\n        _2601 = _2592;\n    }\n    bool _2610;\n    if (!_2601)\n    {\n        _2610 = _2582.y < fa_shadows[ci * 1 + 16].y;\n    }\n    else\n    {\n        _2610 = _2601;\n    }\n    bool _2619;\n    if (!_2610)\n    {\n        _2619 = _2582.y > fa_shadows[ci * 1 + 16].w;\n    }\n    else\n    {\n        _2619 = _2610;\n    }\n    bool _2626;\n    if (!_2619)\n    {\n        _2626 = _2582.z > 1.0;\n    }\n    else\n    {\n        _2626 = _2619;\n    }\n    if (_2626)\n    {\n        return -1.0;\n    }\n    float _2634;\n    if (fa_shadows[26].x > 0.0)\n    {\n        _2634 = fa_shadows[26].x;\n    }\n    else\n    {\n        _2634 = 1.5 * fa_shadows[ci * 1 + 20].x;\n    }\n    vec2 param = _2582.xy;\n    vec4 param_1 = fa_shadows[ci * 1 + 16];\n    float param_2 = _2582.z - ((_2634 * (1.0 + (0.5 * _2552))) / _2534);\n    float param_3 = fa_shadows[ci * 1 + 20].x;\n    float param_4 = _2534;\n    float param_5 = _2534 * 0.25;\n    float param_6 = ((fa_shadows[ci * 1 + 20].x * min(_2552, 3.0)) * 0.5) / _2534;\n    vec3 param_7 = vec3(0.0);\n    int param_8 = int(fa_shadows[25].z + 0.5);\n    float param_9 = fa_shadows[25].w;\n    return fa_shadow_filter(param, param_1, param_2, param_3, param_4, param_5, param_6, param_7, param_8, param_9);\n}\n\nfloat fa_shadow_sun(vec3 world, vec3 n, vec3 l)\n{\n    if (fa_mesh_fs_params[5].z < 0.5)\n    {\n        return 1.0;\n    }\n    int _3012 = int(fa_shadows[25].x + 0.5);\n    if (_3012 < 1)\n    {\n        return 1.0;\n    }\n    float _3027 = dot(world - fa_shadows[27].xyz, fa_shadows[28].xyz);\n    int param = _3012 - 1;\n    if (_3027 > fa_shadow_split_at(param))\n    {\n        return 1.0;\n    }\n    int ci = 0;\n    bool _3039 = _3012 > 1;\n    bool _3046;\n    if (_3039)\n    {\n        _3046 = _3027 > fa_shadows[24].x;\n    }\n    else\n    {\n        _3046 = _3039;\n    }\n    if (_3046)\n    {\n        ci = 1;\n    }\n    bool _3050 = _3012 > 2;\n    bool _3057;\n    if (_3050)\n    {\n        _3057 = _3027 > fa_shadows[24].y;\n    }\n    else\n    {\n        _3057 = _3050;\n    }\n    if (_3057)\n    {\n        ci = 2;\n    }\n    bool _3061 = _3012 > 3;\n    bool _3068;\n    if (_3061)\n    {\n        _3068 = _3027 > fa_shadows[24].z;\n    }\n    else\n    {\n        _3068 = _3061;\n    }\n    if (_3068)\n    {\n        ci = 3;\n    }\n    float s = -1.0;\n    for (int k = 0; k < 4; k++)\n    {\n        if (ci >= _3012)\n        {\n            break;\n        }\n        int param_1 = ci;\n        vec3 param_2 = world;\n        vec3 param_3 = n;\n        vec3 param_4 = l;\n        float _3094 = fa_shadow_cascade(param_1, param_2, param_3, param_4);\n        s = _3094;\n        if (_3094 >= 0.0)\n        {\n            break;\n        }\n        ci++;\n    }\n    if (s < 0.0)\n    {\n        return 1.0;\n    }\n    if (fa_shadows[25].y > 0.0)\n    {\n        float _3119;\n        if (ci > 0)\n        {\n            int param_5 = ci - 1;\n            _3119 = fa_shadow_split_at(param_5);\n        }\n        else\n        {\n            _3119 = fa_shadows[28].w;\n        }\n        int param_6 = ci;\n        float _3138 = fa_shadows[25].y * max(fa_shadow_split_at(param_6) - _3119, 9.9999997473787516355514526367188e-05);\n        int param_7 = ci;\n        float _3149 = clamp((_3027 - (fa_shadow_split_at(param_7) - _3138)) / _3138, 0.0, 1.0);\n        if (_3149 > 0.0)\n        {\n            float s2 = 1.0;\n            if ((ci + 1) < _3012)\n            {\n                int param_8 = ci + 1;\n                vec3 param_9 = world;\n                vec3 param_10 = n;\n                vec3 param_11 = l;\n                float _3170 = fa_shadow_cascade(param_8, param_9, param_10, param_11);\n                s2 = _3170;\n                if (_3170 < 0.0)\n                {\n                    s2 = s;\n                }\n            }\n            s = mix(s, s2, _3149);\n        }\n    }\n    return s;\n}\n\nfloat fa_shadow_factor(vec3 n, vec3 l)\n{\n    vec3 param = fa_world_pos;\n    vec3 param_1 = n;\n    vec3 param_2 = l;\n    return fa_shadow_sun(param, param_1, param_2);\n}\n\nfloat fa_shadow_local(int li, vec3 lpos, vec3 world, vec3 n, vec3 l)\n{\n    bool _2692 = fa_mesh_fs_params[5].z < 0.5;\n    bool _2699;\n    if (!_2692)\n    {\n        _2699 = fa_shadows[29].x < 0.5;\n    }\n    else\n    {\n        _2699 = _2692;\n    }\n    if (_2699)\n    {\n        return 1.0;\n    }\n    int param = (int(fa_shadows[29].x + 0.5) - 1) + li;\n    vec4 _2712 = fa_light_texel(param);\n    float _2713 = _2712.x;\n    if (_2713 < 0.0)\n    {\n        return 1.0;\n    }\n    int _2722 = int(_2713 + 0.5);\n    int param_1 = _2722;\n    vec4 _2726 = fa_light_texel(param_1);\n    int param_2 = _2722 + 1;\n    vec4 _2731 = fa_light_texel(param_2);\n    float fade = 1.0;\n    float _2734 = _2726.y;\n    if (_2734 > 0.0)\n    {\n        float _2751 = 1.0 - smoothstep(0.75 * _2734, _2734, length(world - fa_shadows[27].xyz));\n        fade = _2751;\n        if (_2751 <= 0.0)\n        {\n            return 1.0;\n        }\n    }\n    int face = 0;\n    if (_2726.x > 1.5)\n    {\n        vec3 param_3 = world - lpos;\n        face = fa_cube_face(param_3);\n    }\n    int _2775 = (_2722 + 2) + (face * 6);\n    int param_4 = _2775;\n    int param_5 = _2775 + 1;\n    int param_6 = _2775 + 3;\n    vec4 _2789 = fa_light_texel(param_6);\n    int param_7 = _2775 + 4;\n    vec4 _2794 = fa_light_texel(param_7);\n    int param_8 = _2775 + 5;\n    vec4 _2799 = fa_light_texel(param_8);\n    float _2811 = _2799.x * max(dot(_2789, vec4(world, 1.0)), 0.001000000047497451305389404296875);\n    float _2816 = clamp(dot(n, l), 0.0, 1.0);\n    float _2839 = clamp(dot(n, _2789.xyz), -1.0, 1.0);\n    float _2858 = min(sqrt(1.0 - (_2839 * _2839)) / max(abs(dot(n, world - lpos)) / max(dot(_2789, vec4(world, 1.0)), 0.001000000047497451305389404296875), 0.20000000298023223876953125), 4.0);\n    float _2861 = _2731.y;\n    float _2863;\n    if (_2861 > 0.0)\n    {\n        _2863 = _2861;\n    }\n    else\n    {\n        _2863 = 1.5 * _2811;\n    }\n    vec4 _2883 = vec4(world + (n * (_2863 * sqrt(1.0 - (_2816 * _2816)))), 1.0);\n    float _2887 = dot(_2789, _2883);\n    float _2890 = _2799.y;\n    if (_2887 < _2890)\n    {\n        return 1.0;\n    }\n    vec2 _2905 = vec2(dot(fa_light_texel(param_4), _2883), dot(fa_light_texel(param_5), _2883)) / vec2(_2887);\n    float _2907 = _2905.x;\n    bool _2910 = _2907 < _2794.x;\n    bool _2919;\n    if (!_2910)\n    {\n        _2919 = _2907 > _2794.z;\n    }\n    else\n    {\n        _2919 = _2910;\n    }\n    bool _2928;\n    if (!_2919)\n    {\n        _2928 = _2905.y < _2794.y;\n    }\n    else\n    {\n        _2928 = _2919;\n    }\n    bool _2937;\n    if (!_2928)\n    {\n        _2937 = _2905.y > _2794.w;\n    }\n    else\n    {\n        _2937 = _2928;\n    }\n    if (_2937)\n    {\n        return 1.0;\n    }\n    float _2943 = _2731.x;\n    float _2945;\n    if (_2943 > 0.0)\n    {\n        _2945 = _2943;\n    }\n    else\n    {\n        _2945 = 1.5 * _2811;\n    }\n    vec2 param_9 = _2905;\n    vec4 param_10 = _2794;\n    float param_11 = _2887 - (_2945 * (1.0 + (0.5 * _2858)));\n    float param_12 = _2811;\n    float param_13 = 1.0;\n    float param_14 = _2799.z * 0.25;\n    float param_15 = (_2811 * min(_2858, 3.0)) * 0.5;\n    vec3 param_16 = vec3(1.0, _2890, _2799.z);\n    int param_17 = int(_2726.z + 0.5);\n    float param_18 = _2726.w;\n    return mix(1.0, fa_shadow_filter(param_9, param_10, param_11, param_12, param_13, param_14, param_15, param_16, param_17, param_18), fade);\n}\n\nfloat fa_contact_shadow(int li, vec3 world, vec3 gn, vec3 l, float dist)\n{\n    bool _4500 = fa_mesh_fs_params[24].x < 0.5;\n    bool _4507;\n    if (!_4500)\n    {\n        _4507 = fa_shadows[29].x < 0.5;\n    }\n    else\n    {\n        _4507 = _4500;\n    }\n    if (_4507)\n    {\n        return 1.0;\n    }\n    int param = (int(fa_shadows[29].x + 0.5) - 1) + li;\n    vec4 _4520 = fa_light_texel(param);\n    float _4521 = _4520.y;\n    float len = _4521;\n    if (_4521 <= 0.0)\n    {\n        return 1.0;\n    }\n    float _4533 = length(world - fa_mesh_fs_params[0].xyz);\n    float _4543 = 1.0 - smoothstep(0.5 * fa_mesh_fs_params[25].x, fa_mesh_fs_params[25].x, _4533);\n    if (_4543 <= 0.0)\n    {\n        return 1.0;\n    }\n    float _4549 = len;\n    float _4552 = min(_4549, 0.89999997615814208984375 * dist);\n    len = _4552;\n    float _4557 = 0.004999999888241291046142578125 + (0.0030000000260770320892333984375 * _4533);\n    float _4562 = _4557 + (0.5 * _4552);\n    vec3 _4568 = world + (gn * _4557);\n    float _4570 = fa_shadow_noise();\n    float occ = 0.0;\n    float _4634;\n    for (int k = 0; k < 12; k++)\n    {\n        float _4585 = (float(k) + _4570) * 0.083333335816860198974609375;\n        vec3 _4593 = _4568 + (l * (_4585 * len));\n        vec4 _4599 = vec4(_4593, 1.0);\n        float _4605 = dot(fa_mesh_fs_params[28], _4599);\n        if (_4605 < 9.9999997473787516355514526367188e-05)\n        {\n            break;\n        }\n        vec2 _4625 = vec2(dot(fa_mesh_fs_params[26], _4599), dot(fa_mesh_fs_params[27], _4599)) / vec2(_4605);\n        float _4629 = _4625.x * 0.5;\n        float _4630 = _4629 + 0.5;\n        if (fa_mesh_fs_params[24].y > 0.5)\n        {\n            _4634 = (_4625.y * 0.5) + 0.5;\n        }\n        else\n        {\n            _4634 = 0.5 - (_4625.y * 0.5);\n        }\n        bool _4650 = _4630 < 0.0;\n        bool _4657;\n        if (!_4650)\n        {\n            _4657 = _4630 >= 1.0;\n        }\n        else\n        {\n            _4657 = _4650;\n        }\n        bool _4664;\n        if (!_4657)\n        {\n            _4664 = _4634 < 0.0;\n        }\n        else\n        {\n            _4664 = _4657;\n        }\n        bool _4671;\n        if (!_4664)\n        {\n            _4671 = _4634 >= 1.0;\n        }\n        else\n        {\n            _4671 = _4664;\n        }\n        if (_4671)\n        {\n            break;\n        }\n        vec4 _4690 = texelFetch(fa_screen_tex_fa_shadow_smp, ivec2(vec2(_4630, _4634) * fa_mesh_fs_params[24].zw), 0);\n        if (_4690.w < 0.5)\n        {\n            continue;\n        }\n        float _4709 = (dot(fa_mesh_fs_params[29].xyz, _4593) + fa_mesh_fs_params[29].w) - _4690.x;\n        if ((_4709 > _4557) && (_4709 < _4562))\n        {\n            occ = max(occ, (1.0 - (_4585 * _4585)) * smoothstep(0.0, 0.0500000007450580596923828125, min(min(_4630, 0.5 - _4629), min(_4634, 1.0 - _4634))));\n        }\n    }\n    return 1.0 - (occ * _4543);\n}\n\nLightSample fa_light_shadowed(int li, vec3 world_pos, vec3 gn)\n{\n    bool _5148 = fa_lm.z > 0.5;\n    bool _5154;\n    if (_5148)\n    {\n        int param = li;\n        _5154 = fa_light_baked(param);\n    }\n    else\n    {\n        _5154 = _5148;\n    }\n    if (_5154)\n    {\n        int param_1 = li;\n        return LightSample(vec3(0.0, 1.0, 0.0), vec3(0.0), 0.0, 1.0, 0.0, int(fa_light_type(param_1) + 0.5));\n    }\n    int param_2 = li;\n    vec3 param_3 = world_pos;\n    vec3 param_4 = gn;\n    LightSample _5178 = fa_light_sample_n(param_2, param_3, param_4);\n    vec3 _7658 = _5178.color;\n    float _7660 = _5178.shadow;\n    bool _5181 = _5178.type == 0;\n    if (_5181 && (li == 0))\n    {\n        vec3 param_5 = gn;\n        vec3 param_6 = _5178.direction;\n        float _5192 = fa_shadow_factor(param_5, param_6);\n        _7660 = _5192;\n        _7658 *= _5192;\n    }\n    else\n    {\n        bool _5203 = _5178.type != 0;\n        bool _5209;\n        if (_5203)\n        {\n            _5209 = _5178.attenuation > 0.0;\n        }\n        else\n        {\n            _5209 = _5203;\n        }\n        if (_5209)\n        {\n            int param_7 = li;\n            int param_8 = fa_light_base(param_7);\n            int param_9 = li;\n            vec3 param_10 = fa_light_texel(param_8).xyz;\n            vec3 param_11 = world_pos;\n            vec3 param_12 = gn;\n            vec3 param_13 = _5178.direction;\n            float _5228 = fa_shadow_local(param_9, param_10, param_11, param_12, param_13);\n            _7660 = _5228;\n            _7658 *= _5228;\n        }\n    }\n    bool _5238 = fa_mesh_fs_params[24].x > 0.5;\n    bool _5244;\n    if (_5238)\n    {\n        _5244 = _5178.attenuation > 0.0;\n    }\n    else\n    {\n        _5244 = _5238;\n    }\n    if (_5244)\n    {\n        float _5251;\n        if (_5181)\n        {\n            _5251 = 1000000000.0;\n        }\n        else\n        {\n            _5251 = _5178._distance;\n        }\n        int param_14 = li;\n        vec3 param_15 = world_pos;\n        vec3 param_16 = gn;\n        vec3 param_17 = _5178.direction;\n        float param_18 = _5251;\n        float _5269 = fa_contact_shadow(param_14, param_15, param_16, param_17, param_18);\n        _7660 *= _5269;\n        _7658 *= _5269;\n    }\n    return LightSample(_5178.direction, _7658, _5178.attenuation, _7660, _5178._distance, _5178.type);\n}\n\nvec3 fa_ltc_tangent(vec3 n, vec3 v)\n{\n    vec3 _5312 = v - (n * dot(v, n));\n    vec3 t = _5312;\n    float _5316 = dot(_5312, _5312);\n    float l2 = _5316;\n    if (_5316 < 1.0000000133514319600180897396058e-10)\n    {\n        vec3 _5326;\n        if (abs(n.z) < 0.999000012874603271484375)\n        {\n            _5326 = cross(n, vec3(0.0, 0.0, 1.0));\n        }\n        else\n        {\n            _5326 = cross(n, vec3(1.0, 0.0, 0.0));\n        }\n        t = _5326;\n        l2 = dot(_5326, _5326);\n    }\n    return t * inversesqrt(l2);\n}\n\nvec3 fa_ltc_local(vec3 t1, vec3 n, vec3 p)\n{\n    return vec3(dot(t1, p), dot(cross(n, t1), p), dot(n, p));\n}\n\nvec3 fa_ltc_edge_vector(vec3 a, vec3 b)\n{\n    float _5361 = dot(a, a);\n    float _5365 = dot(b, b);\n    if ((_5361 < 1.0000000195414813782625560981111e-24) || (_5365 < 1.0000000195414813782625560981111e-24))\n    {\n        return vec3(0.0);\n    }\n    vec3 _5379 = a * inversesqrt(_5361);\n    vec3 _5384 = b * inversesqrt(_5365);\n    float _5388 = dot(_5379, _5384);\n    float _5391 = abs(_5388);\n    float g = (((((((((((0.0416471660137176513671875 * _5391) - 0.1924748718738555908203125) * _5391) + 0.4179156124591827392578125) * _5391) - 0.616057217121124267578125) * _5391) + 0.777722418308258056640625) * _5391) - 0.999542415142059326171875) * _5391) + 1.570791721343994140625;\n    if (_5388 < 0.0)\n    {\n        g = (3.1415927410125732421875 * inversesqrt(max(1.0 - (_5388 * _5388), 1.0000000116860974230803549289703e-07))) - g;\n    }\n    return cross(_5379, _5384) * g;\n}\n\nvoid fa_ltc_clip_edge(vec3 a, vec3 b, inout vec3 sum, inout vec3 leave, inout vec3 enter, inout vec2 seen)\n{\n    bool _5448 = a.z > 0.0;\n    bool _5452 = b.z > 0.0;\n    if (_5448 && _5452)\n    {\n        vec3 param = a;\n        vec3 param_1 = b;\n        sum += fa_ltc_edge_vector(param, param_1);\n    }\n    else\n    {\n        if (_5448 != _5452)\n        {\n            vec3 _5487 = a + ((b - a) * (a.z / (a.z - b.z)));\n            _5487.z = 0.0;\n            if (_5448)\n            {\n                vec3 param_2 = a;\n                vec3 param_3 = _5487;\n                sum += fa_ltc_edge_vector(param_2, param_3);\n                leave = _5487;\n                seen.x = 1.0;\n            }\n            else\n            {\n                vec3 param_4 = _5487;\n                vec3 param_5 = b;\n                sum += fa_ltc_edge_vector(param_4, param_5);\n                enter = _5487;\n                seen.y = 1.0;\n            }\n        }\n    }\n}\n\nfloat fa_ltc_quad(vec4 abcd, vec3 p0, vec3 p1, vec3 p2, vec3 p3)\n{\n    vec3 _5536 = vec3((abcd.x * p0.x) + (abcd.y * p0.z), p0.y, (abcd.z * p0.x) + (abcd.w * p0.z));\n    vec3 _5562 = vec3((abcd.x * p1.x) + (abcd.y * p1.z), p1.y, (abcd.z * p1.x) + (abcd.w * p1.z));\n    vec3 _5588 = vec3((abcd.x * p2.x) + (abcd.y * p2.z), p2.y, (abcd.z * p2.x) + (abcd.w * p2.z));\n    vec3 _5614 = vec3((abcd.x * p3.x) + (abcd.y * p3.z), p3.y, (abcd.z * p3.x) + (abcd.w * p3.z));\n    vec3 sum = vec3(0.0);\n    vec3 leave = vec3(0.0);\n    vec3 enter = vec3(0.0);\n    vec3 param = _5536;\n    vec3 param_1 = _5562;\n    vec3 param_2 = vec3(0.0);\n    vec3 param_3 = vec3(0.0);\n    vec3 param_4 = vec3(0.0);\n    vec2 param_5 = vec2(0.0);\n    fa_ltc_clip_edge(param, param_1, param_2, param_3, param_4, param_5);\n    sum = param_2;\n    leave = param_3;\n    enter = param_4;\n    vec3 param_6 = _5562;\n    vec3 param_7 = _5588;\n    vec3 param_8 = param_2;\n    vec3 param_9 = param_3;\n    vec3 param_10 = param_4;\n    vec2 param_11 = param_5;\n    fa_ltc_clip_edge(param_6, param_7, param_8, param_9, param_10, param_11);\n    sum = param_8;\n    leave = param_9;\n    enter = param_10;\n    vec3 param_12 = _5588;\n    vec3 param_13 = _5614;\n    vec3 param_14 = param_8;\n    vec3 param_15 = param_9;\n    vec3 param_16 = param_10;\n    vec2 param_17 = param_11;\n    fa_ltc_clip_edge(param_12, param_13, param_14, param_15, param_16, param_17);\n    sum = param_14;\n    leave = param_15;\n    enter = param_16;\n    vec3 param_18 = _5614;\n    vec3 param_19 = _5536;\n    vec3 param_20 = param_14;\n    vec3 param_21 = param_15;\n    vec3 param_22 = param_16;\n    vec2 param_23 = param_17;\n    fa_ltc_clip_edge(param_18, param_19, param_20, param_21, param_22, param_23);\n    sum = param_20;\n    leave = param_21;\n    enter = param_22;\n    if ((param_23.x * param_23.y) > 0.5)\n    {\n        vec3 param_24 = leave;\n        vec3 param_25 = enter;\n        sum += fa_ltc_edge_vector(param_24, param_25);\n    }\n    return sum.z * 0.15915493667125701904296875;\n}\n\nfloat fa_ltc_rect(vec4 abcd, vec3 center, vec3 ex, vec3 ey)\n{\n    vec4 param = abcd;\n    vec3 param_1 = (center - ex) - ey;\n    vec3 param_2 = (center + ex) - ey;\n    vec3 param_3 = (center + ex) + ey;\n    vec3 param_4 = (center - ex) + ey;\n    return abs(fa_ltc_quad(param, param_1, param_2, param_3, param_4));\n}\n\nfloat fa_area_form(vec4 m, float shape, vec3 pc, vec3 ex, vec3 ey)\n{\n    if ((shape < 0.5) || (shape > 1.5))\n    {\n        vec4 param = m;\n        vec3 param_1 = pc;\n        vec3 param_2 = ex;\n        vec3 param_3 = ey;\n        return fa_ltc_rect(param, param_1, param_2, param_3);\n    }\n    vec3 _5763 = (pc + (ex * 0.92387950420379638671875)) + (ey * 0.3826834261417388916015625);\n    vec3 _5787 = (pc - (ex * 0.92387950420379638671875)) + (ey * 0.3826834261417388916015625);\n    vec3 _5803 = (pc - (ex * 0.3826834261417388916015625)) - (ey * 0.92387950420379638671875);\n    vec4 param_4 = m;\n    vec3 param_5 = _5763;\n    vec3 param_6 = (pc + (ex * 0.3826834261417388916015625)) + (ey * 0.92387950420379638671875);\n    vec3 param_7 = (pc - (ex * 0.3826834261417388916015625)) + (ey * 0.92387950420379638671875);\n    vec3 param_8 = _5787;\n    vec4 param_9 = m;\n    vec3 param_10 = _5763;\n    vec3 param_11 = _5787;\n    vec3 param_12 = (pc - (ex * 0.92387950420379638671875)) - (ey * 0.3826834261417388916015625);\n    vec3 param_13 = _5803;\n    vec4 param_14 = m;\n    vec3 param_15 = _5763;\n    vec3 param_16 = _5803;\n    vec3 param_17 = (pc + (ex * 0.3826834261417388916015625)) - (ey * 0.92387950420379638671875);\n    vec3 param_18 = (pc + (ex * 0.92387950420379638671875)) - (ey * 0.3826834261417388916015625);\n    return abs((fa_ltc_quad(param_4, param_5, param_6, param_7, param_8) + fa_ltc_quad(param_9, param_10, param_11, param_12, param_13)) + fa_ltc_quad(param_14, param_15, param_16, param_17, param_18));\n}\n\nvec2 fa_ltc_uv(float roughness, float ndv)\n{\n    return ((vec2(clamp((roughness - 0.0500000007450580596923828125) * 1.0526316165924072265625, 0.0, 1.0), sqrt(clamp(1.0 - ndv, 0.0, 1.0))) * 63.0) + vec2(0.5)) * vec2(0.015625);\n}\n\nvec3 fa_area_shade(int li, vec3 world_pos, vec3 n, vec3 v, vec3 diffuse_color, vec3 f0, float f90, float roughness, float ndv, float window)\n{\n    int param = li;\n    int _5861 = fa_light_base(param);\n    int param_1 = _5861;\n    int param_2 = _5861 + 1;\n    int param_3 = _5861 + 2;\n    int param_4 = _5861 + 4;\n    vec4 _5883 = fa_light_texel(param_4);\n    int param_5 = _5861 + 5;\n    vec4 _5888 = fa_light_texel(param_5);\n    int param_6 = _5861 + 6;\n    vec4 _5893 = fa_light_texel(param_6);\n    float _5894 = _5893.w;\n    vec3 _5899 = fa_light_texel(param_1).xyz - world_pos;\n    bool _5901 = _5894 < 1.5;\n    bool _5908;\n    if (_5901)\n    {\n        _5908 = dot(normalize(fa_light_texel(param_3).xyz), _5899) >= 0.0;\n    }\n    else\n    {\n        _5908 = _5901;\n    }\n    if (_5908)\n    {\n        return vec3(0.0);\n    }\n    bool _5917 = (_5894 > 0.5) && _5901;\n    float _5921 = _5917 ? 1.0539000034332275390625 : 1.0;\n    vec3 _5924 = _5883.xyz;\n    float _5926 = _5883.w;\n    vec3 _5932 = _5888.xyz;\n    float _5934 = _5888.w;\n    vec3 up = _5932 * (_5934 * _5921);\n    float _5940;\n    if (_5917)\n    {\n        _5940 = (3.1415927410125732421875 * _5926) * _5926;\n    }\n    else\n    {\n        _5940 = (4.0 * _5926) * _5934;\n    }\n    if (_5894 > 1.5)\n    {\n        vec3 _5966 = cross(_5924, -_5899);\n        vec3 perp = _5966;\n        float _5970 = dot(_5966, _5966);\n        vec3 _5973;\n        if (_5970 > 1.0000000133514319600180897396058e-10)\n        {\n            _5973 = perp * inversesqrt(_5970);\n        }\n        else\n        {\n            _5973 = _5932;\n        }\n        perp = _5973;\n        up = _5973 * _5934;\n    }\n    float _5994 = max(_5940, 9.9999999747524270787835121154785e-07);\n    vec3 param_7 = n;\n    vec3 param_8 = v;\n    vec3 _6004 = fa_ltc_tangent(param_7, param_8);\n    vec3 param_9 = _6004;\n    vec3 param_10 = n;\n    vec3 param_11 = _5899;\n    vec3 _6012 = fa_ltc_local(param_9, param_10, param_11);\n    vec3 param_12 = _6004;\n    vec3 param_13 = n;\n    vec3 param_14 = _5924 * (_5926 * _5921);\n    vec3 _6020 = fa_ltc_local(param_12, param_13, param_14);\n    vec3 param_15 = _6004;\n    vec3 param_16 = n;\n    vec3 param_17 = up;\n    vec3 _6028 = fa_ltc_local(param_15, param_16, param_17);\n    vec4 param_18 = vec4(1.0, 0.0, 0.0, 1.0);\n    float param_19 = _5894;\n    vec3 param_20 = _6012;\n    vec3 param_21 = _6020;\n    vec3 param_22 = _6028;\n    float param_23 = roughness;\n    float param_24 = ndv;\n    vec2 _6047 = fa_ltc_uv(param_23, param_24) * 64.0;\n    vec2 param_25 = _6047;\n    vec2 param_26 = _6047 + vec2(64.0, 0.0);\n    vec4 _6057 = fa_atlas_fetch(param_26);\n    vec4 param_27 = fa_atlas_fetch(param_25);\n    float param_28 = _5894;\n    vec3 param_29 = _6012;\n    vec3 param_30 = _6020;\n    vec3 param_31 = _6028;\n    return (((diffuse_color * fa_area_form(param_18, param_19, param_20, param_21, param_22)) + (((f0 * _6057.x) + ((vec3(f90) - f0) * _6057.y)) * fa_area_form(param_27, param_28, param_29, param_30, param_31))) * fa_light_texel(param_2).xyz) * ((((3.1415927410125732421875 * dot(_5899, _5899)) + _5994) / _5994) * window);\n}\n\nvec3 fa_light_rgb(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 1;\n    return fa_light_texel(param_1).xyz;\n}\n\nfloat fa_d_charlie(float alpha, float ndh)\n{\n    float _4237 = 1.0 / alpha;\n    return ((2.0 + _4237) * pow(sqrt(max(1.0 - (ndh * ndh), 9.9999997473787516355514526367188e-05)), _4237)) * 0.15915493667125701904296875;\n}\n\nfloat fa_v_ashikhmin(float ndl, float ndv)\n{\n    return clamp(0.25 / max((ndl + ndv) - (ndl * ndv), 9.9999997473787516355514526367188e-05), 0.0, 1.0);\n}\n\nfloat fa_layers_coat(FaLayers L, vec3 l, vec3 h, float vdh)\n{\n    float _4272 = max(dot(L.nc, l), 0.0);\n    float _4278 = max(dot(L.nc, h), 0.0);\n    float _4287 = ((_4278 * _4278) * (L.coat_a2 - 1.0)) + 1.0;\n    return (((L.coat * (0.039999999105930328369140625 + (0.959999978542327880859375 * pow(clamp(1.0 - vdh, 0.0, 1.0), 5.0)))) * (((L.coat_a2 / ((3.1415927410125732421875 * _4287) * _4287)) * (0.5 / max(mix((2.0 * _4272) * L.coat_ndv, _4272 + L.coat_ndv, L.coat_alpha), 9.9999997473787516355514526367188e-05))) * 3.1415927410125732421875)) * step(9.9999997473787516355514526367188e-05, _4272)) * _4272;\n}\n\nvec3 fa_area_layers(FaLayers L, int li, vec3 world_pos, vec3 n, vec3 v, vec3 l, vec3 diffuse_color, vec3 f0, float roughness, float ndv, float window)\n{\n    int param = li;\n    vec3 param_1 = world_pos;\n    vec3 param_2 = n;\n    vec3 param_3 = v;\n    vec3 param_4 = diffuse_color;\n    vec3 param_5 = f0;\n    float param_6 = L.f90;\n    float param_7 = roughness;\n    float param_8 = ndv;\n    float param_9 = window;\n    float _6125;\n    if (L.sheen_on)\n    {\n        _6125 = L.sheen_scale;\n    }\n    else\n    {\n        _6125 = 1.0;\n    }\n    vec3 result = fa_area_shade(param, param_1, param_2, param_3, param_4, param_5, param_6, param_7, param_8, param_9) * (L.keep * _6125);\n    vec3 _6138 = normalize(l + v);\n    int param_10 = li;\n    vec3 _6149 = fa_light_rgb(param_10) * window;\n    if (L.sheen_on)\n    {\n        float _6158 = max(dot(n, l), 0.0);\n        float param_11 = L.sheen_alpha;\n        float param_12 = max(dot(n, _6138), 0.0);\n        float param_13 = _6158;\n        float param_14 = ndv;\n        result += ((L.sheen * _6149) * (((((fa_d_charlie(param_11, param_12) * fa_v_ashikhmin(param_13, param_14)) * 3.1415927410125732421875) * step(9.9999997473787516355514526367188e-05, _6158)) * _6158) * L.keep));\n    }\n    if (L.coat > 0.0)\n    {\n        FaLayers param_15 = L;\n        vec3 param_16 = l;\n        vec3 param_17 = _6138;\n        float param_18 = max(dot(v, _6138), 0.0);\n        result += (_6149 * fa_layers_coat(param_15, param_16, param_17, param_18));\n    }\n    return result;\n}\n\nfloat fa_d_ggx_aniso(float ndh, float tdh, float bdh, float at, float ab)\n{\n    float _4140 = tdh / at;\n    float _4144 = bdh / ab;\n    float _4156 = ((_4140 * _4140) + (_4144 * _4144)) + (ndh * ndh);\n    return 1.0 / ((((3.1415927410125732421875 * at) * ab) * _4156) * _4156);\n}\n\nfloat fa_lambda_ggx_aniso(float n, float t, float b, float at, float ab)\n{\n    return 0.5 * (sqrt(1.0 + (((((at * at) * t) * t) + (((ab * ab) * b) * b)) / max(n * n, 9.9999999392252902907785028219223e-09))) - 1.0);\n}\n\nfloat fa_v_ggx_aniso(float ndl, float ndv, float tdv, float bdv, float tdl, float bdl, float at, float ab)\n{\n    float param = ndv;\n    float param_1 = tdv;\n    float param_2 = bdv;\n    float param_3 = at;\n    float param_4 = ab;\n    float param_5 = ndl;\n    float param_6 = tdl;\n    float param_7 = bdl;\n    float param_8 = at;\n    float param_9 = ab;\n    return clamp(1.0 / ((4.0 * max(ndl * ndv, 9.9999997473787516355514526367188e-05)) * ((1.0 + fa_lambda_ggx_aniso(param, param_1, param_2, param_3, param_4)) + fa_lambda_ggx_aniso(param_5, param_6, param_7, param_8, param_9))), 0.0, 1.0);\n}\n\nvec3 fa_layers_light(FaLayers L, vec3 diffuse_color, vec3 f0, vec3 n, vec3 v, vec3 l, vec3 h, float ndl, float ndv, float ndh, float vdh, float alpha, float a2)\n{\n    float _4336 = step(9.9999997473787516355514526367188e-05, ndl);\n    float d_ggx;\n    float vis;\n    if (L.aniso != 0.0)\n    {\n        float param = ndh;\n        float param_1 = dot(L.t, h);\n        float param_2 = dot(L.b, h);\n        float param_3 = L.at;\n        float param_4 = L.ab;\n        d_ggx = fa_d_ggx_aniso(param, param_1, param_2, param_3, param_4);\n        float param_5 = ndl;\n        float param_6 = ndv;\n        float param_7 = dot(L.t, v);\n        float param_8 = dot(L.b, v);\n        float param_9 = dot(L.t, l);\n        float param_10 = dot(L.b, l);\n        float param_11 = L.at;\n        float param_12 = L.ab;\n        vis = fa_v_ggx_aniso(param_5, param_6, param_7, param_8, param_9, param_10, param_11, param_12);\n    }\n    else\n    {\n        float _4415 = ((ndh * ndh) * (a2 - 1.0)) + 1.0;\n        d_ggx = a2 / ((3.1415927410125732421875 * _4415) * _4415);\n        vis = 0.5 / max(mix((2.0 * ndl) * ndv, ndl + ndv, alpha), 9.9999997473787516355514526367188e-05);\n    }\n    vec3 base = diffuse_color + (((f0 + ((vec3(L.f90) - f0) * pow(clamp(1.0 - vdh, 0.0, 1.0), 5.0))) * ((d_ggx * vis) * 3.1415927410125732421875)) * _4336);\n    if (L.sheen_on)\n    {\n        float param_13 = L.sheen_alpha;\n        float param_14 = ndh;\n        float param_15 = ndl;\n        float param_16 = ndv;\n        base = (base * L.sheen_scale) + (L.sheen * (((fa_d_charlie(param_13, param_14) * fa_v_ashikhmin(param_15, param_16)) * 3.1415927410125732421875) * _4336));\n    }\n    vec3 result = base * (L.keep * ndl);\n    if (L.coat > 0.0)\n    {\n        FaLayers param_17 = L;\n        vec3 param_18 = l;\n        vec3 param_19 = h;\n        float param_20 = vdh;\n        result += vec3(fa_layers_coat(param_17, param_18, param_19, param_20));\n    }\n    return result;\n}\n\nvec2 fa_env_brdf(float rough, float ndv)\n{\n    vec4 _3546 = (vec4(-1.0, -0.0274999998509883880615234375, -0.572000026702880859375, 0.02199999988079071044921875) * rough) + vec4(1.0, 0.0425000004470348358154296875, 1.03999996185302734375, -0.039999999105930328369140625);\n    float _3549 = _3546.x;\n    return (vec2(-1.03999996185302734375, 1.03999996185302734375) * ((min(_3549 * _3549, exp2((-9.27999973297119140625) * ndv)) * _3549) + _3546.y)) + _3546.zw;\n}\n\nvec3 fa_environment(vec3 d, float rough)\n{\n    if (fa_mesh_fs_params[11].w > 0.5)\n    {\n        return textureLod(fa_env_tex_fa_env_smp, d, clamp(rough, 0.0, 1.0) * fa_mesh_fs_params[12].w).xyz;\n    }\n    float _3400 = rough * rough;\n    float _3430 = 0.60000002384185791015625 * _3400;\n    return mix(mix(fa_mesh_fs_params[12].xyz * 0.550000011920928955078125, mix(fa_mesh_fs_params[12].xyz, fa_mesh_fs_params[11].xyz, vec3(pow(clamp(d.y * (1.0 - (0.699999988079071044921875 * _3400)), 0.0, 1.0), 0.550000011920928955078125))), vec3(smoothstep((-0.0500000007450580596923828125) - _3430, 0.0500000007450580596923828125 + _3430, d.y))), ((fa_mesh_fs_params[11].xyz + fa_mesh_fs_params[12].xyz) * 0.5) * 0.800000011920928955078125, vec3(_3400 * 0.60000002384185791015625));\n}\n\nvec3 fa_layers_ibl(FaLayers L, vec3 n, vec3 v, vec3 f0, float roughness)\n{\n    vec3 rn = n;\n    if (L.aniso != 0.0)\n    {\n        vec3 _4023;\n        if (L.aniso >= 0.0)\n        {\n            _4023 = L.b;\n        }\n        else\n        {\n            _4023 = L.t;\n        }\n        rn = normalize(mix(n, cross(cross(_4023, v), _4023), vec3(abs(L.aniso))));\n    }\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05);\n    vec2 _4056 = fa_env_brdf(param, param_1);\n    vec3 param_2 = reflect(-v, rn);\n    float param_3 = roughness;\n    vec3 result = (fa_environment(param_2, param_3) * ((f0 * _4056.x) + (vec3(L.f90) * _4056.y))) * L.base_scale;\n    if (L.sheen_on)\n    {\n        vec3 param_4 = n;\n        float param_5 = L.sheen_rough;\n        result += ((L.sheen * (L.sheen_e * L.keep)) * fa_environment(param_4, param_5));\n    }\n    if (L.coat > 0.0)\n    {\n        float param_6 = L.coat_rough;\n        float param_7 = L.coat_ndv;\n        vec2 _4111 = fa_env_brdf(param_6, param_7);\n        vec3 param_8 = reflect(-v, L.nc);\n        float param_9 = L.coat_rough;\n        result += (fa_environment(param_8, param_9) * (L.coat * ((0.039999999105930328369140625 * _4111.x) + _4111.y)));\n    }\n    return result;\n}\n\nvec3 fa_sky_reflection(vec3 n, vec3 v, vec3 f0, float roughness)\n{\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05);\n    vec2 _3588 = fa_env_brdf(param, param_1);\n    vec3 param_2 = reflect(-v, n);\n    float param_3 = roughness;\n    return fa_environment(param_2, param_3) * ((f0 * _3588.x) + vec3(_3588.y));\n}\n\nvec2 fa_xm_size(int k)\n{\n    return max(floor(fa_mesh_fs_params[24].zw / vec2(exp2(float(k)))), vec2(1.0));\n}\n\nvec2 fa_xm_origin(int k)\n{\n    if (k == 0)\n    {\n        return vec2(0.0);\n    }\n    float y = 0.0;\n    for (int j = 1; j < k; j++)\n    {\n        int param = j;\n        y += fa_xm_size(param).y;\n    }\n    return vec2(fa_mesh_fs_params[24].z, y);\n}\n\nvec3 fa_xm_texel(vec2 size, vec2 origin, vec2 p)\n{\n    return texelFetch(fa_screen_tex_fa_shadow_smp, ivec2(origin + clamp(p, vec2(0.0), size - vec2(1.0))), 0).xyz;\n}\n\nvec3 fa_xm_level(int k, vec2 uv)\n{\n    int param = k;\n    vec2 _4813 = fa_xm_size(param);\n    int param_1 = k;\n    vec2 _4817 = fa_xm_origin(param_1);\n    vec2 _4823 = (uv * _4813) - vec2(0.5);\n    vec2 _4826 = fract(_4823);\n    vec2 _4829 = floor(_4823);\n    vec2 param_2 = _4813;\n    vec2 param_3 = _4817;\n    vec2 param_4 = _4829;\n    vec2 param_5 = _4813;\n    vec2 param_6 = _4817;\n    vec2 param_7 = _4829 + vec2(1.0, 0.0);\n    vec2 param_8 = _4813;\n    vec2 param_9 = _4817;\n    vec2 param_10 = _4829 + vec2(0.0, 1.0);\n    vec2 param_11 = _4813;\n    vec2 param_12 = _4817;\n    vec2 param_13 = _4829 + vec2(1.0);\n    vec3 _4871 = vec3(_4826.x);\n    return mix(mix(fa_xm_texel(param_2, param_3, param_4), fa_xm_texel(param_5, param_6, param_7), _4871), mix(fa_xm_texel(param_8, param_9, param_10), fa_xm_texel(param_11, param_12, param_13), _4871), vec3(_4826.y));\n}\n\nvec3 fa_xm_sample(vec2 uv, float lod)\n{\n    float _4890 = max(fa_mesh_fs_params[31].w - 1.0, 0.0);\n    float _4894 = clamp(lod, 0.0, _4890);\n    int _4898 = int(floor(_4894));\n    int param = _4898;\n    vec2 param_1 = uv;\n    vec3 c = fa_xm_level(param, param_1);\n    float _4908 = float(_4898);\n    float _4909 = _4894 - _4908;\n    bool _4911 = _4909 > 0.001000000047497451305389404296875;\n    bool _4918;\n    if (_4911)\n    {\n        _4918 = _4908 < _4890;\n    }\n    else\n    {\n        _4918 = _4911;\n    }\n    if (_4918)\n    {\n        int param_2 = _4898 + 1;\n        vec2 param_3 = uv;\n        c = mix(c, fa_xm_level(param_2, param_3), vec3(_4909));\n    }\n    return c;\n}\n\nvec3 fa_transmitted(Surface s, vec3 n, vec3 v, float roughness, vec3 f0, float f90, float keep, float tr, inout float blend)\n{\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05);\n    vec2 _4944 = fa_env_brdf(param, param_1);\n    vec3 through = ((vec3(1.0) - clamp((f0 * _4944.x) + (vec3(f90) * _4944.y), vec3(0.0), vec3(1.0))) * s.albedo) * (tr * keep);\n    float _4972 = max(s.thickness, 0.0);\n    bool _4977 = _4972 > 0.0;\n    if ((s.attenuation_distance > 0.0) && _4977)\n    {\n        through *= exp((-((-log(clamp(s.attenuation_color, vec3(9.9999997473787516355514526367188e-05), vec3(1.0)))) / vec3(s.attenuation_distance))) * _4972);\n    }\n    bool _5002 = fa_mesh_fs_params[30].w > 1.5;\n    bool _5009;\n    if (!_5002)\n    {\n        _5009 = fa_mesh_fs_params[30].w < 0.5;\n    }\n    else\n    {\n        _5009 = _5002;\n    }\n    if (_5009)\n    {\n        blend = clamp(dot(through, vec3(0.3333333432674407958984375)), 0.0, 0.980000019073486328125);\n        return vec3(0.0);\n    }\n    vec3 world = fa_world_pos;\n    if (_4977)\n    {\n        world += (refract(-v, n, 1.0 / max(s.ior, 1.0)) * _4972);\n    }\n    vec4 _5044 = vec4(world, 1.0);\n    float _5049 = dot(fa_mesh_fs_params[28], _5044);\n    vec2 uv = vec2(0.5);\n    if (_5049 > 9.9999997473787516355514526367188e-05)\n    {\n        vec2 _5067 = vec2(dot(fa_mesh_fs_params[26], _5044), dot(fa_mesh_fs_params[27], _5044)) / vec2(_5049);\n        float _5075;\n        if (fa_mesh_fs_params[24].y > 0.5)\n        {\n            _5075 = (_5067.y * 0.5) + 0.5;\n        }\n        else\n        {\n            _5075 = 0.5 - (_5067.y * 0.5);\n        }\n        uv = vec2((_5067.x * 0.5) + 0.5, _5075);\n    }\n    vec2 param_2 = clamp(uv, vec2(0.0), vec2(1.0));\n    float param_3 = (clamp(roughness, 0.0, 1.0) * clamp((2.0 * s.ior) - 2.0, 0.0, 1.0)) * max(fa_mesh_fs_params[31].w - 1.0, 0.0);\n    return through * fa_xm_sample(param_2, param_3);\n}\n\nvec3 fa_shadow_debug(vec3 color, vec3 world)\n{\n    if (fa_shadows[27].w < 0.5)\n    {\n        return color;\n    }\n    int _3194 = int(fa_shadows[25].x + 0.5);\n    float _3204 = dot(world - fa_shadows[27].xyz, fa_shadows[28].xyz);\n    vec3 tint = vec3(0.3499999940395355224609375);\n    bool _3209 = _3194 > 0;\n    bool _3218;\n    if (_3209)\n    {\n        int param = _3194 - 1;\n        _3218 = _3204 <= fa_shadow_split_at(param);\n    }\n    else\n    {\n        _3218 = _3209;\n    }\n    if (_3218)\n    {\n        tint = vec3(1.0, 0.1500000059604644775390625, 0.100000001490116119384765625);\n        bool _3224 = _3194 > 1;\n        bool _3231;\n        if (_3224)\n        {\n            _3231 = _3204 > fa_shadows[24].x;\n        }\n        else\n        {\n            _3231 = _3224;\n        }\n        if (_3231)\n        {\n            tint = vec3(0.100000001490116119384765625, 0.89999997615814208984375, 0.20000000298023223876953125);\n        }\n        bool _3237 = _3194 > 2;\n        bool _3244;\n        if (_3237)\n        {\n            _3244 = _3204 > fa_shadows[24].y;\n        }\n        else\n        {\n            _3244 = _3237;\n        }\n        if (_3244)\n        {\n            tint = vec3(0.1500000059604644775390625, 0.300000011920928955078125, 1.0);\n        }\n        bool _3250 = _3194 > 3;\n        bool _3257;\n        if (_3250)\n        {\n            _3257 = _3204 > fa_shadows[24].z;\n        }\n        else\n        {\n            _3257 = _3250;\n        }\n        if (_3257)\n        {\n            tint = vec3(1.0, 0.89999997615814208984375, 0.100000001490116119384765625);\n        }\n    }\n    return mix(color, tint, vec3(0.550000011920928955078125));\n}\n\nvoid main()\n{\n    fa_inst_load();\n    vec3 _7317 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _7317 = -_7317;\n    }\n    vec3 _6607 = normalize(fa_mesh_fs_params[0].xyz - fa_world_pos);\n    vec3 param = fa_world_pos;\n    fa_cluster_begin(param);\n    SurfaceInput param_1 = SurfaceInput(fa_world_pos, _7317, fa_world_tangent, fa_uv, fa_vertex_color, _6607, gl_FrontFacing);\n    Surface _6615 = fa_standard_surface(param_1);\n    vec3 _7348 = _6615.albedo;\n    float _7349 = _6615.alpha;\n    vec3 _7350 = _6615.normal;\n    float _7351 = _6615.metallic;\n    float _7352 = _6615.roughness;\n    float _7353 = _6615.occlusion;\n    vec3 _7354 = _6615.emission;\n    float _7355 = _6615.clearcoat;\n    float _7356 = _6615.clearcoat_roughness;\n    vec3 _7357 = _6615.sheen_color;\n    float _7358 = _6615.sheen_roughness;\n    float _7359 = _6615.anisotropy;\n    float _7360 = _6615.anisotropy_rotation;\n    float _7361 = _6615.specular;\n    float _7362 = _6615.ior;\n    vec3 _7363 = _6615.specular_color;\n    float _7364 = _6615.transmission;\n    float _7365 = _6615.thickness;\n    vec3 _7366 = _6615.attenuation_color;\n    float _7367 = _6615.attenuation_distance;\n    SurfaceInput param_2 = SurfaceInput(fa_world_pos, _7317, fa_world_tangent, fa_uv, fa_vertex_color, _6607, gl_FrontFacing);\n    Surface param_3 = _6615;\n    surface(param_2, param_3);\n    _7348 = param_3.albedo;\n    _7349 = param_3.alpha;\n    _7350 = param_3.normal;\n    _7351 = param_3.metallic;\n    _7352 = param_3.roughness;\n    _7353 = param_3.occlusion;\n    _7354 = param_3.emission;\n    _7355 = param_3.clearcoat;\n    _7356 = param_3.clearcoat_roughness;\n    _7357 = param_3.sheen_color;\n    _7358 = param_3.sheen_roughness;\n    _7359 = param_3.anisotropy;\n    _7360 = param_3.anisotropy_rotation;\n    _7361 = param_3.specular;\n    _7362 = param_3.ior;\n    _7363 = param_3.specular_color;\n    _7364 = param_3.transmission;\n    _7365 = param_3.thickness;\n    _7366 = param_3.attenuation_color;\n    _7367 = param_3.attenuation_distance;\n    vec3 param_4 = fa_world_pos;\n    vec3 param_5 = _7317;\n    vec3 param_6 = param_3.albedo;\n    vec3 param_7 = param_3.normal;\n    fa_apply_decals(param_4, param_5, param_6, param_7);\n    _7348 = param_6;\n    _7350 = param_7;\n    float fa_tr_blend = 0.0;\n    vec3 result;\n    if (fa_mesh_fs_params[3].w > 0.5)\n    {\n        result = _7348;\n    }\n    else\n    {\n        vec3 _6655 = normalize(_7350);\n        float _6662 = clamp(_7351, 0.0, 1.0);\n        float _6666 = clamp(_7352, 0.0500000007450580596923828125, 1.0);\n        float _6670 = _6666 * _6666;\n        float _6674 = _6670 * _6670;\n        float _6679 = max(dot(_6655, _6607), 9.9999997473787516355514526367188e-05);\n        float _6685 = 1.0 - _6662;\n        float _6686 = clamp(_7364, 0.0, 1.0) * _6685;\n        vec3 _6695 = (_7348 * _6685) * (1.0 - _6686);\n        vec3 _6702 = mix(vec3(0.039999999105930328369140625), _7348, vec3(_6662));\n        vec3 f0 = _6702;\n        SurfaceInput param_8 = SurfaceInput(fa_world_pos, _7317, fa_world_tangent, fa_uv, fa_vertex_color, _6607, gl_FrontFacing);\n        Surface param_9 = Surface(_7348, _7349, _7350, _7351, _7352, _7353, _7354, _7355, _7356, _7357, _7358, _7359, _7360, _7361, _7362, _7363, _7364, _7365, _7366, _7367);\n        vec3 param_10 = _6655;\n        vec3 param_11 = _6607;\n        float param_12 = _6662;\n        float param_13 = _6666;\n        vec3 param_14 = _6702;\n        FaLayers _6718 = fa_layers_setup(param_8, param_9, param_10, param_11, param_12, param_13, param_14);\n        f0 = param_14;\n        vec3 param_15 = _6655;\n        vec3 lit = (fa_indirect_diffuse(param_15) * _6695) * _7353;\n        if (_6718.on)\n        {\n            lit *= _6718.base_scale;\n        }\n        int _6740 = fa_cl_ndir + fa_cl_local;\n        for (int ln = 0; ln < _6740; ln++)\n        {\n            int param_16 = ln;\n            int _6753 = fa_cl_light(param_16);\n            bool _6756 = fa_lm.z > 0.5;\n            bool _6762;\n            if (_6756)\n            {\n                int param_17 = _6753;\n                _6762 = fa_light_baked(param_17);\n            }\n            else\n            {\n                _6762 = _6756;\n            }\n            if (_6762)\n            {\n                continue;\n            }\n            int param_18 = _6753;\n            vec3 param_19 = fa_world_pos;\n            vec3 param_20 = _7317;\n            LightSample _6774 = fa_light_shadowed(param_18, param_19, param_20);\n            float _6782 = max(dot(_6655, _6774.direction), 0.0);\n            float _6788 = _6774.attenuation * _6774.shadow;\n            vec3 _6793 = normalize(_6774.direction + _6607);\n            float _6798 = max(dot(_6655, _6793), 0.0);\n            float _6803 = max(dot(_6607, _6793), 0.0);\n            bool _6810;\n            if (fa_light_is_area)\n            {\n                _6810 = !_6718.on;\n            }\n            else\n            {\n                _6810 = fa_light_is_area;\n            }\n            if (_6810)\n            {\n                int param_21 = _6753;\n                vec3 param_22 = fa_world_pos;\n                vec3 param_23 = _6655;\n                vec3 param_24 = _6607;\n                vec3 param_25 = _6695;\n                vec3 param_26 = f0;\n                float param_27 = 1.0;\n                float param_28 = _6666;\n                float param_29 = _6679;\n                float param_30 = _6788;\n                lit += fa_area_shade(param_21, param_22, param_23, param_24, param_25, param_26, param_27, param_28, param_29, param_30);\n            }\n            else\n            {\n                if (fa_light_is_area)\n                {\n                    FaLayers param_31 = _6718;\n                    int param_32 = _6753;\n                    vec3 param_33 = fa_world_pos;\n                    vec3 param_34 = _6655;\n                    vec3 param_35 = _6607;\n                    vec3 param_36 = _6774.direction;\n                    vec3 param_37 = _6695;\n                    vec3 param_38 = f0;\n                    float param_39 = _6666;\n                    float param_40 = _6679;\n                    float param_41 = _6788;\n                    lit += fa_area_layers(param_31, param_32, param_33, param_34, param_35, param_36, param_37, param_38, param_39, param_40, param_41);\n                }\n                else\n                {\n                    if (_6718.on)\n                    {\n                        FaLayers param_42 = _6718;\n                        vec3 param_43 = _6695;\n                        vec3 param_44 = f0;\n                        vec3 param_45 = _6655;\n                        vec3 param_46 = _6607;\n                        vec3 param_47 = _6774.direction;\n                        vec3 param_48 = _6793;\n                        float param_49 = _6782;\n                        float param_50 = _6679;\n                        float param_51 = _6798;\n                        float param_52 = _6803;\n                        float param_53 = _6670;\n                        float param_54 = _6674;\n                        int param_55 = _6753;\n                        lit += (fa_layers_light(param_42, param_43, param_44, param_45, param_46, param_47, param_48, param_49, param_50, param_51, param_52, param_53, param_54) * ((fa_light_rgb(param_55) * fa_light_tint) * _6788));\n                    }\n                    else\n                    {\n                        float _6916 = ((_6798 * _6798) * (_6674 - 1.0)) + 1.0;\n                        int param_56 = _6753;\n                        lit += (((_6695 + (((f0 + ((vec3(1.0) - f0) * pow(1.0 - _6803, 5.0))) * (((_6674 / ((3.1415927410125732421875 * _6916) * _6916)) * (0.5 / max(mix((2.0 * _6782) * _6679, _6782 + _6679, _6670), 9.9999997473787516355514526367188e-05))) * 3.1415927410125732421875)) * step(9.9999997473787516355514526367188e-05, _6782))) * (fa_light_rgb(param_56) * fa_light_tint)) * (_6782 * _6788));\n                    }\n                }\n            }\n        }\n        if (_6718.on)\n        {\n            FaLayers param_57 = _6718;\n            vec3 param_58 = _6655;\n            vec3 param_59 = _6607;\n            vec3 param_60 = f0;\n            float param_61 = _6666;\n            lit += (fa_layers_ibl(param_57, param_58, param_59, param_60, param_61) * _7353);\n        }\n        else\n        {\n            vec3 param_62 = _6655;\n            vec3 param_63 = _6607;\n            vec3 param_64 = f0;\n            float param_65 = _6666;\n            lit += (fa_sky_reflection(param_62, param_63, param_64, param_65) * _7353);\n        }\n        if (_6686 > 0.0)\n        {\n            float _7014;\n            if (_6718.on)\n            {\n                _7014 = _6718.f90;\n            }\n            else\n            {\n                _7014 = 1.0;\n            }\n            float _7022;\n            if (_6718.on)\n            {\n                _7022 = _6718.base_scale;\n            }\n            else\n            {\n                _7022 = 1.0;\n            }\n            Surface param_66 = Surface(_7348, _7349, _7350, _7351, _7352, _7353, _7354, _7355, _7356, _7357, _7358, _7359, _7360, _7361, _7362, _7363, _7364, _7365, _7366, _7367);\n            vec3 param_67 = _6655;\n            vec3 param_68 = _6607;\n            float param_69 = _6666;\n            vec3 param_70 = f0;\n            float param_71 = _7014;\n            float param_72 = _7022;\n            float param_73 = _6686;\n            float param_74 = fa_tr_blend;\n            vec3 _7046 = fa_transmitted(param_66, param_67, param_68, param_69, param_70, param_71, param_72, param_73, param_74);\n            fa_tr_blend = param_74;\n            lit += _7046;\n        }\n        result = lit;\n    }\n    vec3 _7053 = result;\n    vec3 _7054 = _7053 + _7354;\n    result = _7054;\n    vec3 param_75 = _7054;\n    vec3 param_76 = fa_world_pos;\n    result = fa_shadow_debug(param_75, param_76);\n    bool _7063 = fa_mesh_fs_params[7].w > 0.0;\n    bool _7070;\n    if (!_7063)\n    {\n        _7070 = fa_mesh_fs_params[8].y > 0.0;\n    }\n    else\n    {\n        _7070 = _7063;\n    }\n    if (_7070)\n    {\n        vec3 _7079 = fa_world_pos - fa_mesh_fs_params[0].xyz;\n        float _7085 = dot(_7079, fa_mesh_fs_params[9].xyz);\n        bool _7089 = fa_mesh_fs_params[9].w > 0.5;\n        float _7090;\n        if (_7089)\n        {\n            _7090 = _7085;\n        }\n        else\n        {\n            _7090 = length(_7079);\n        }\n        float _7102 = _7090 - fa_mesh_fs_params[8].x;\n        if (_7102 > 0.0)\n        {\n            float _7111 = fa_mesh_fs_params[7].w * _7102;\n            float tau = _7111 * _7111;\n            if (fa_mesh_fs_params[8].y > 0.0)\n            {\n                float _7127;\n                if (_7089)\n                {\n                    _7127 = fa_world_pos.y - (fa_mesh_fs_params[9].y * _7085);\n                }\n                else\n                {\n                    _7127 = fa_mesh_fs_params[0].y;\n                }\n                float _7148 = mix(_7127, fa_world_pos.y, clamp(fa_mesh_fs_params[8].x / _7090, 0.0, 1.0));\n                float _7152 = fa_world_pos.y - _7148;\n                float _7157 = _7148 - fa_mesh_fs_params[8].z;\n                float _7162 = fa_world_pos.y - fa_mesh_fs_params[8].z;\n                bool _7165 = _7157 <= 0.0;\n                bool _7166 = !_7165;\n                bool _7172;\n                if (_7166)\n                {\n                    _7172 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _7172 = _7165;\n                }\n                float _7173;\n                if (_7172)\n                {\n                    _7173 = fa_mesh_fs_params[8].y;\n                }\n                else\n                {\n                    _7173 = fa_mesh_fs_params[8].y * exp(-min(fa_mesh_fs_params[8].w * _7157, 80.0));\n                }\n                bool _7200;\n                if (_7166)\n                {\n                    _7200 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _7200 = _7165;\n                }\n                float _7201;\n                if (_7200)\n                {\n                    _7201 = fa_mesh_fs_params[8].y * _7157;\n                }\n                else\n                {\n                    _7201 = (fa_mesh_fs_params[8].y * (1.0 - exp(-min(fa_mesh_fs_params[8].w * _7157, 80.0)))) / fa_mesh_fs_params[8].w;\n                }\n                bool _7226 = _7162 <= 0.0;\n                bool _7233;\n                if (!_7226)\n                {\n                    _7233 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _7233 = _7226;\n                }\n                float _7234;\n                if (_7233)\n                {\n                    _7234 = fa_mesh_fs_params[8].y * _7162;\n                }\n                else\n                {\n                    _7234 = (fa_mesh_fs_params[8].y * (1.0 - exp(-min(fa_mesh_fs_params[8].w * _7162, 80.0)))) / fa_mesh_fs_params[8].w;\n                }\n                float _7261;\n                if (abs(_7152) < 0.001000000047497451305389404296875)\n                {\n                    _7261 = _7173;\n                }\n                else\n                {\n                    _7261 = (_7234 - _7201) / _7152;\n                }\n                tau += (_7102 * max(_7261, 0.0));\n            }\n            result = mix(result, fa_mesh_fs_params[7].xyz, vec3(clamp(1.0 - exp(-clamp(tau, 0.0, 80.0)), 0.0, 1.0)));\n        }\n    }\n    if (fa_tr_blend > 0.0)\n    {\n        float _7297 = 1.0 - fa_tr_blend;\n        result /= vec3(_7297);\n        _7349 *= _7297;\n    }\n    fa_frag_color = vec4(result, _7349);\n}\n\n",
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
            "size": 512,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_591",
            "glsl_uniforms": [
              {
                "type": "vec4",
                "array_count": 32,
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
            "inst_name": "_2258",
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
      "vs": "#version 430\n\nstruct VertexData\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 color;\n    vec3 object_pos;\n};\n\nstruct points_item\n{\n    vec4 pos;\n    vec4 tint;\n};\n\nlayout(binding = 0, std430) readonly buffer fa_vs_points_buf\n{\n    points_item data[];\n} fa_vs_points;\n\nuniform vec4 fa_mesh_vs_params[11];\nuniform vec4 fa_skin[192];\nuniform vec4 fa_inst_base[4];\nlayout(location = 0) out vec3 fa_world_pos;\nlayout(location = 1) out vec3 fa_world_normal;\nlayout(location = 2) out vec4 fa_world_tangent;\nlayout(location = 3) out vec2 fa_uv;\nlayout(location = 4) out vec4 fa_vertex_color;\nlayout(location = 9) in vec4 fa_joints;\nlayout(location = 10) in vec4 fa_weights;\nlayout(location = 0) in vec3 fa_position;\nlayout(location = 1) in vec3 fa_normal;\nlayout(location = 3) in vec4 fa_tangent;\nlayout(location = 2) in vec2 fa_texcoord0;\nlayout(location = 4) in vec4 fa_color;\nlayout(location = 5) out vec3 fa_lm;\nlayout(location = 5) in vec4 fa_inst_m0;\nlayout(location = 6) in vec4 fa_inst_m1;\nlayout(location = 7) in vec4 fa_inst_m2;\nlayout(location = 8) in vec4 fa_inst_m3;\n\nvoid fa_inst_begin()\n{\n}\n\nmat4 fa_skin_matrix(vec4 joints, vec4 weights)\n{\n    vec4 r0 = vec4(0.0);\n    vec4 r1 = vec4(0.0);\n    vec4 r2 = vec4(0.0);\n    for (int i = 0; i < 4; i++)\n    {\n        int _208 = int((joints[i] * 255.0) + 0.5) * 3;\n        r0 += (fa_skin[_208 * 1 + 0] * weights[i]);\n        r1 += (fa_skin[(_208 + 1) * 1 + 0] * weights[i]);\n        r2 += (fa_skin[(_208 + 2) * 1 + 0] * weights[i]);\n    }\n    return mat4(vec4(r0.x, r1.x, r2.x, 0.0), vec4(r0.y, r1.y, r2.y, 0.0), vec4(r0.z, r1.z, r2.z, 0.0), vec4(r0.w, r1.w, r2.w, 1.0));\n}\n\nVertexData fa_vertex_data(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    vec3 _114 = cross(model[1].xyz, model[2].xyz);\n    float _119 = (dot(model[0].xyz, _114) < 0.0) ? (-1.0) : 1.0;\n    return VertexData((model * vec4(position, 1.0)).xyz, (((_114 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _119, vec4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _119), texcoord0 * fa_mesh_vs_params[8].xy, color, position);\n}\n\nvoid vertex(inout VertexData v)\n{\n    if (fa_vs_points.data[gl_InstanceID].pos.w < 0.5)\n    {\n        v.world_pos = vec3(1000000000.0);\n        return;\n    }\n    v.world_pos += fa_vs_points.data[gl_InstanceID].pos.xyz;\n    v.color = fa_vs_points.data[gl_InstanceID].tint;\n}\n\nvoid fa_shade_vertex(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    mat4 param = model;\n    vec3 param_1 = position;\n    vec3 param_2 = normal;\n    vec4 param_3 = tangent;\n    vec2 param_4 = texcoord0;\n    vec4 param_5 = color;\n    VertexData param_6 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    vertex(param_6);\n    fa_world_pos = param_6.world_pos;\n    fa_world_normal = param_6.world_normal;\n    fa_world_tangent = param_6.world_tangent;\n    fa_uv = param_6.uv;\n    fa_vertex_color = param_6.color;\n    gl_Position = mat4(fa_mesh_vs_params[0], fa_mesh_vs_params[1], fa_mesh_vs_params[2], fa_mesh_vs_params[3]) * vec4(param_6.world_pos, 1.0);\n}\n\nvoid main()\n{\n    fa_inst_begin();\n    vec4 param = fa_joints;\n    vec4 param_1 = fa_weights;\n    mat4 param_2 = mat4(fa_inst_base[0], fa_inst_base[1], fa_inst_base[2], fa_inst_base[3]) * fa_skin_matrix(param, param_1);\n    vec3 param_3 = fa_position;\n    vec3 param_4 = fa_normal;\n    vec4 param_5 = fa_tangent;\n    vec2 param_6 = fa_texcoord0;\n    vec4 param_7 = fa_color;\n    fa_shade_vertex(param_2, param_3, param_4, param_5, param_6, param_7);\n    fa_lm = vec3(0.0);\n}\n\n",
      "fs": "#version 430\n\nstruct SurfaceInput\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 vertex_color;\n    vec3 view_dir;\n    bool front_facing;\n};\n\nstruct LightSample\n{\n    vec3 direction;\n    vec3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct Surface\n{\n    vec3 albedo;\n    float alpha;\n    vec3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    vec3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    vec3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    vec3 specular_color;\n    float transmission;\n    float thickness;\n    vec3 attenuation_color;\n    float attenuation_distance;\n};\n\nstruct FaLayers\n{\n    bool on;\n    float f90;\n    float keep;\n    float base_scale;\n    float coat;\n    float coat_rough;\n    float coat_alpha;\n    float coat_a2;\n    vec3 nc;\n    float coat_ndv;\n    bool sheen_on;\n    vec3 sheen;\n    float sheen_rough;\n    float sheen_alpha;\n    float sheen_scale;\n    float sheen_e;\n    float aniso;\n    vec3 t;\n    vec3 b;\n    float at;\n    float ab;\n};\n\nconst float _3688[63] = float[](1.0, 1.0, 1.0, 0.4790000021457672119140625, 0.11699999868869781494140625, 0.01200000010430812835693359375, 0.0, 0.0, 0.0, 1.0, 1.0, 1.0, 0.578000009059906005859375, 0.19300000369548797607421875, 0.0350000001490116119384765625, 0.0030000000260770320892333984375, 0.0, 0.0, 1.0, 1.0, 1.0, 0.6740000247955322265625, 0.3459999859333038330078125, 0.1319999992847442626953125, 0.032999999821186065673828125, 0.0040000001899898052215576171875, 0.0, 0.971000015735626220703125, 0.954999983310699462890625, 0.828999996185302734375, 0.63999998569488525390625, 0.42599999904632568359375, 0.24500000476837158203125, 0.115000002086162567138671875, 0.037000000476837158203125, 0.0030000000260770320892333984375, 0.7469999790191650390625, 0.737999975681304931640625, 0.670000016689300537109375, 0.563000023365020751953125, 0.4309999942779541015625, 0.3039999902248382568359375, 0.1940000057220458984375, 0.1019999980926513671875, 0.0309999994933605194091796875, 0.614000022411346435546875, 0.609000027179718017578125, 0.566999971866607666015625, 0.499000012874603271484375, 0.412000000476837158203125, 0.32400000095367431640625, 0.240999996662139892578125, 0.162000000476837158203125, 0.087999999523162841796875, 0.538999974727630615234375, 0.535000026226043701171875, 0.505999982357025146484375, 0.4569999873638153076171875, 0.393999993801116943359375, 0.328999996185302734375, 0.2660000026226043701171875, 0.203999996185302734375, 0.14200000464916229248046875);\n\nstruct points_item\n{\n    vec4 pos;\n    vec4 tint;\n};\n\nuniform vec4 fa_mesh_fs_params[32];\nuniform vec4 fa_shadows[30];\nlayout(binding = 1, std430) readonly buffer fa_points_buf\n{\n    points_item data[];\n} points;\n\nlayout(binding = 0) uniform sampler2D fa_light_tex_fa_shadow_smp;\nlayout(binding = 1) uniform sampler2D fa_tex_fa_smp;\nlayout(binding = 2) uniform sampler2D fa_normal_tex_fa_smp;\nlayout(binding = 3) uniform sampler2D fa_mr_tex_fa_smp;\nlayout(binding = 4) uniform sampler2D fa_occlusion_tex_fa_smp;\nlayout(binding = 5) uniform sampler2D fa_emissive_tex_fa_smp;\nlayout(binding = 6) uniform sampler2D fa_decal_tex_fa_env_smp;\nlayout(binding = 7) uniform sampler2D fa_lightmap_fa_env_smp;\nlayout(binding = 8) uniform samplerCube fa_env_tex_fa_env_smp;\nlayout(binding = 9) uniform sampler2D fa_light_atlas_fa_env_smp;\nlayout(binding = 10) uniform sampler2D fa_shadow_tex_fa_shadow_smp;\nlayout(binding = 11) uniform sampler2D fa_screen_tex_fa_shadow_smp;\n\nlayout(location = 0) in vec3 fa_world_pos;\nlayout(location = 5) in vec3 fa_lm;\nlayout(location = 1) in vec3 fa_world_normal;\nlayout(location = 2) in vec4 fa_world_tangent;\nlayout(location = 3) in vec2 fa_uv;\nlayout(location = 4) in vec4 fa_vertex_color;\nlayout(location = 0) out vec4 fa_frag_color;\nvec3 fa_light_tint;\nbool fa_light_is_area;\nint fa_cl_ndir;\nint fa_cl_slot;\nint fa_cl_local;\n\nvoid fa_inst_load()\n{\n}\n\nvec4 fa_light_texel(int t)\n{\n    return texelFetch(fa_light_tex_fa_shadow_smp, ivec2(t & 1023, t >> 10), 0);\n}\n\nvec4 fa_cluster_texel(vec3 world_pos)\n{\n    bool _1529 = fa_mesh_fs_params[19].x < 0.0;\n    bool _1536;\n    if (!_1529)\n    {\n        _1536 = fa_mesh_fs_params[19].w < 1.0;\n    }\n    else\n    {\n        _1536 = _1529;\n    }\n    bool _1544;\n    if (!_1536)\n    {\n        _1544 = fa_mesh_fs_params[18].x < 1.0;\n    }\n    else\n    {\n        _1544 = _1536;\n    }\n    bool _1551;\n    if (!_1544)\n    {\n        _1551 = fa_mesh_fs_params[18].y < 1.0;\n    }\n    else\n    {\n        _1551 = _1544;\n    }\n    bool _1558;\n    if (!_1551)\n    {\n        _1558 = fa_mesh_fs_params[19].y < 1.0;\n    }\n    else\n    {\n        _1558 = _1551;\n    }\n    if (_1558)\n    {\n        return vec4(0.0);\n    }\n    vec4 _1568 = vec4(world_pos, 1.0);\n    float _1574 = dot(fa_mesh_fs_params[16], _1568);\n    if (!(_1574 > 9.9999999747524270787835121154785e-07))\n    {\n        return vec4(0.0);\n    }\n    vec2 _1596 = vec2(dot(fa_mesh_fs_params[14], _1568), dot(fa_mesh_fs_params[15], _1568)) / vec2(_1574);\n    int _1600 = int(fa_mesh_fs_params[18].x);\n    int _1604 = int(fa_mesh_fs_params[18].y);\n    int param = (int(fa_mesh_fs_params[19].x) + (((clamp(int(floor(log2(max(dot(fa_mesh_fs_params[17].xyz, world_pos) + fa_mesh_fs_params[17].w, fa_mesh_fs_params[18].w) / fa_mesh_fs_params[18].w) * fa_mesh_fs_params[18].z)), 0, int(fa_mesh_fs_params[19].y) - 1) * _1604) + clamp(int(floor(((_1596.y * 0.5) + 0.5) * fa_mesh_fs_params[18].y)), 0, _1604 - 1)) * _1600)) + clamp(int(floor(((_1596.x * 0.5) + 0.5) * fa_mesh_fs_params[18].x)), 0, _1600 - 1);\n    return fa_light_texel(param);\n}\n\nivec2 fa_cluster_lookup(vec3 world_pos)\n{\n    vec3 param = world_pos;\n    vec4 _1680 = fa_cluster_texel(param);\n    return ivec2(int(_1680.x), int(_1680.y));\n}\n\nvoid fa_cluster_begin(vec3 world_pos)\n{\n    fa_cl_ndir = int(fa_mesh_fs_params[19].z);\n    vec3 param = world_pos;\n    ivec2 _5121 = fa_cluster_lookup(param);\n    fa_cl_slot = _5121.x;\n    fa_cl_local = _5121.y;\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nvec3 fa_linear_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_tex_fix(inout vec3 c, float mode)\n{\n    if (mode > 1.5)\n    {\n        vec3 param = c;\n        vec3 _6264 = fa_linear_to_srgb(param);\n        c = _6264;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            vec3 param_1 = c;\n            vec3 _6272 = fa_srgb_to_linear(param_1);\n            c = _6272;\n        }\n    }\n    return c;\n}\n\nvec3 fa_tangent_normal(SurfaceInput i, vec3 m)\n{\n    vec3 _474;\n    if (i.front_facing)\n    {\n        _474 = i.world_normal;\n    }\n    else\n    {\n        _474 = -i.world_normal;\n    }\n    vec3 _498 = normalize(i.world_tangent.xyz - (_474 * dot(_474, i.world_tangent.xyz)));\n    vec3 _525 = normalize(((_498 * m.x) + ((cross(_474, _498) * i.world_tangent.w) * m.y)) + (_474 * m.z));\n    vec3 _528;\n    if (i.front_facing)\n    {\n        _528 = _525;\n    }\n    else\n    {\n        _528 = -_525;\n    }\n    return _528;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    vec4 base_t = texture(fa_tex_fa_smp, i.uv);\n    float param = fa_mesh_fs_params[6].w;\n    float param_1 = 1.0;\n    vec3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    vec3 _6303 = fa_tex_fix(param_2, param_3);\n    vec4 _7869 = base_t;\n    _7869.x = _6303.x;\n    _7869.y = _6303.y;\n    _7869.z = _6303.z;\n    base_t = _7869;\n    vec4 _6317 = (_7869 * fa_mesh_fs_params[2]) * i.vertex_color;\n    vec3 _7678 = i.world_normal;\n    if (fa_mesh_fs_params[6].z > 0.5)\n    {\n        float param_4 = fa_mesh_fs_params[6].w;\n        float param_5 = 16.0;\n        vec3 param_6 = texture(fa_normal_tex_fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        vec3 _6349 = fa_tex_fix(param_6, param_7);\n        vec3 _6352 = (_6349 * 2.0) - vec3(1.0);\n        vec2 _6357 = _6352.xy * fa_mesh_fs_params[6].x;\n        vec3 _7877 = _6352;\n        _7877.x = _6357.x;\n        _7877.y = _6357.y;\n        SurfaceInput param_8 = i;\n        vec3 param_9 = _7877;\n        _7678 = fa_tangent_normal(param_8, param_9);\n    }\n    vec4 mrt = texture(fa_mr_tex_fa_smp, i.uv);\n    float param_10 = fa_mesh_fs_params[6].w;\n    float param_11 = 64.0;\n    vec3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    vec3 _6385 = fa_tex_fix(param_12, param_13);\n    vec4 _7880 = mrt;\n    _7880.x = _6385.x;\n    _7880.y = _6385.y;\n    _7880.z = _6385.z;\n    mrt = _7880;\n    vec4 _6413 = texture(fa_occlusion_tex_fa_smp, i.uv);\n    float param_14 = fa_mesh_fs_params[6].w;\n    float param_15 = 256.0;\n    vec3 param_16 = _6413.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    vec3 _6424 = fa_tex_fix(param_16, param_17);\n    float param_18 = fa_mesh_fs_params[6].w;\n    float param_19 = 4.0;\n    vec3 param_20 = texture(fa_emissive_tex_fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    vec3 _6454 = fa_tex_fix(param_20, param_21);\n    float _7683 = fa_mesh_fs_params[20].x;\n    float _7684 = fa_mesh_fs_params[20].y;\n    float _7687 = fa_mesh_fs_params[20].z;\n    float _7686 = fa_mesh_fs_params[21].w;\n    float _7689 = fa_mesh_fs_params[22].x;\n    if (fa_mesh_fs_params[22].z > 0.5)\n    {\n        if (mod(fa_mesh_fs_params[22].z, 2.0) > 0.5)\n        {\n            _7683 *= _6424.y;\n            _7684 *= _6424.z;\n            _7686 *= _6413.w;\n        }\n        if (fa_mesh_fs_params[22].z > 1.5)\n        {\n            _7687 *= mrt.x;\n            _7689 *= mrt.w;\n        }\n    }\n    return Surface(_6317.xyz, _6317.w, _7678, clamp(fa_mesh_fs_params[5].x * _6385.z, 0.0, 1.0), clamp(fa_mesh_fs_params[5].y * _6385.y, 0.0500000007450580596923828125, 1.0), 1.0 + (fa_mesh_fs_params[6].y * (_6424.x - 1.0)), fa_mesh_fs_params[3].xyz + (fa_mesh_fs_params[4].xyz * _6454), _7683, _7684, fa_mesh_fs_params[21].xyz, _7686, _7687, fa_mesh_fs_params[20].w, _7689, fa_mesh_fs_params[22].y, fa_mesh_fs_params[23].xyz, fa_mesh_fs_params[30].x, fa_mesh_fs_params[30].y, fa_mesh_fs_params[31].xyz, fa_mesh_fs_params[30].z);\n}\n\nvoid surface(SurfaceInput i, inout Surface s)\n{\n    s.emission += (i.vertex_color.xyz * points.data[0].tint.w);\n}\n\nvec4 fa_decal_tile(vec4 rect, vec2 uv, vec2 atlas, vec2 ddx, vec2 ddy)\n{\n    vec2 _1760 = rect.zw - rect.xy;\n    vec2 _1764 = _1760 * atlas;\n    vec2 _1768 = ddx * _1764;\n    vec2 _1772 = ddy * _1764;\n    return textureLod(fa_decal_tex_fa_env_smp, rect.xy + (clamp(uv, vec2(0.0), vec2(1.0)) * _1760), clamp(0.5 * log2(max(max(dot(_1768, _1768), dot(_1772, _1772)), 9.9999999392252902907785028219223e-09)), 0.0, 4.0));\n}\n\nvec3 fa_dc_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_dc_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvoid fa_apply_decals(vec3 world_pos, vec3 geo_normal, inout vec3 albedo, inout vec3 normal)\n{\n    bool _1805 = fa_mesh_fs_params[10].y < 0.5;\n    bool _1812;\n    if (!_1805)\n    {\n        _1812 = fa_mesh_fs_params[10].w < 0.5;\n    }\n    else\n    {\n        _1812 = _1805;\n    }\n    if (_1812)\n    {\n        return;\n    }\n    vec3 _1818 = dFdx(world_pos);\n    vec3 _1821 = dFdy(world_pos);\n    vec3 param = world_pos;\n    vec4 _1825 = fa_cluster_texel(param);\n    int _1829 = int(_1825.w);\n    if (_1829 < 1)\n    {\n        return;\n    }\n    int _1839 = int(fa_mesh_fs_params[10].y + 0.5);\n    int param_1 = _1839;\n    vec4 _1843 = fa_light_texel(param_1);\n    vec2 _1846 = _1843.yz;\n    int _1850 = int(_1843.w);\n    int param_2 = _1839 + 1;\n    vec4 _1855 = fa_light_texel(param_2);\n    float _1856 = _1855.x;\n    int _1862 = int(fa_mesh_fs_params[10].w + 0.5) - 1;\n    int _1866 = int(_1825.z);\n    vec3 _2131;\n    for (int k = 0; k < _1829; k++)\n    {\n        int _1879 = _1866 + k;\n        int param_3 = _1850 + (_1879 >> 2);\n        int _1896 = (_1839 + 2) + (int(fa_light_texel(param_3)[_1879 & 3]) * 7);\n        int param_4 = _1896 + 6;\n        vec4 _1901 = fa_light_texel(param_4);\n        if (((int(_1901.w + 0.5) >> _1862) & 1) == 0)\n        {\n            continue;\n        }\n        int param_5 = _1896;\n        vec4 _1916 = fa_light_texel(param_5);\n        int param_6 = _1896 + 1;\n        vec4 _1921 = fa_light_texel(param_6);\n        int param_7 = _1896 + 2;\n        vec4 _1926 = fa_light_texel(param_7);\n        vec3 _1929 = _1916.xyz;\n        float _1934 = dot(_1929, world_pos) + _1916.w;\n        vec3 _1936 = _1921.xyz;\n        float _1941 = dot(_1936, world_pos) + _1921.w;\n        vec3 _1943 = _1926.xyz;\n        float _1948 = dot(_1943, world_pos) + _1926.w;\n        bool _1953 = abs(_1934) > 0.5;\n        bool _1961;\n        if (!_1953)\n        {\n            _1961 = abs(_1941) > 0.5;\n        }\n        else\n        {\n            _1961 = _1953;\n        }\n        bool _1969;\n        if (!_1961)\n        {\n            _1969 = abs(_1948) > 0.5;\n        }\n        else\n        {\n            _1969 = _1961;\n        }\n        if (_1969)\n        {\n            continue;\n        }\n        float _1984 = clamp(dot(geo_normal, normalize(_1943)) * _1901.z, 0.0, 1.0);\n        if (_1984 <= 0.0)\n        {\n            continue;\n        }\n        float _2004 = (clamp((0.5 - abs(_1948)) * 10.0, 0.0, 1.0) * _1984) * _1901.x;\n        vec2 _2012 = vec2(_1934 + 0.5, 0.5 - _1941);\n        vec2 _2022 = vec2(dot(_1929, _1818), dot(_1936, _1818));\n        vec2 _2032 = vec2(dot(_1929, _1821), dot(_1936, _1821));\n        int param_8 = _1896 + 5;\n        vec4 _2037 = fa_light_texel(param_8);\n        int param_9 = _1896 + 3;\n        vec4 _2042 = fa_light_texel(param_9);\n        int param_10 = _1896 + 4;\n        vec4 _2047 = fa_light_texel(param_10);\n        float tex_a = 1.0;\n        vec3 col = _2037.xyz;\n        bool _2057 = _2042.z > _2042.x;\n        if (_2057)\n        {\n            vec4 param_11 = _2042;\n            vec2 param_12 = _2012;\n            vec2 param_13 = _1846;\n            vec2 param_14 = _2022;\n            vec2 param_15 = _2032;\n            vec4 tx = fa_decal_tile(param_11, param_12, param_13, param_14, param_15);\n            if ((_1856 > 0.5) && (_1856 < 1.5))\n            {\n                vec3 param_16 = tx.xyz;\n                vec3 _2083 = fa_dc_to_linear(param_16);\n                vec4 _7766 = tx;\n                _7766.x = _2083.x;\n                _7766.y = _2083.y;\n                _7766.z = _2083.z;\n                tx = _7766;\n            }\n            col *= tx.xyz;\n            tex_a = tx.w;\n        }\n        albedo = mix(albedo, col, vec3(clamp((_2004 * tex_a) * _2037.w, 0.0, 1.0)));\n        if (_2047.z > _2047.x)\n        {\n            vec4 param_17 = _2047;\n            vec2 param_18 = _2012;\n            vec2 param_19 = _1846;\n            vec2 param_20 = _2022;\n            vec2 param_21 = _2032;\n            vec4 _2127 = fa_decal_tile(param_17, param_18, param_19, param_20, param_21);\n            if (_1856 > 1.5)\n            {\n                vec3 param_22 = _2127.xyz;\n                vec3 _2137 = fa_dc_to_srgb(param_22);\n                _2131 = _2137;\n            }\n            else\n            {\n                _2131 = _2127.xyz;\n            }\n            vec3 _2146 = (_2131 * 2.0) - vec3(1.0);\n            vec2 _2151 = _2146.xy * _1901.y;\n            vec3 _2173 = (normalize(_1929) * _2151.x) + (normalize(_1936) * _2151.y);\n            vec3 _2176 = normalize(normal);\n            normal = normalize(mix(_2176, normalize((_2176 * max(_2146.z, 0.0500000007450580596923828125)) + (_2173 - (_2176 * dot(_2176, _2173)))), vec3(clamp(_2004 * (_2057 ? tex_a : 1.0), 0.0, 1.0))));\n        }\n    }\n}\n\nfloat fa_sheen_albedo(float ndv, float rough)\n{\n    float _3614 = min(sqrt(max(rough - 0.100000001490116119384765625, 0.0) * 1.111111164093017578125) * 6.0, 5.999000072479248046875);\n    float _3621 = min(sqrt(clamp(ndv, 0.0, 1.0)) * 8.0, 7.999000072479248046875);\n    int _3624 = int(_3614);\n    int _3627 = int(_3621);\n    float _3637 = _3621 - float(_3627);\n    int _3692 = (_3624 * 9) + _3627;\n    int _3712 = ((_3624 + 1) * 9) + _3627;\n    return mix(mix(_3688[_3692], _3688[_3692 + 1], _3637), mix(_3688[_3712], _3688[_3712 + 1], _3637), _3614 - float(_3624));\n}\n\nFaLayers fa_layers_setup(SurfaceInput i, Surface s, vec3 n, vec3 v, float metallic, float roughness, inout vec3 f0)\n{\n    bool _7601 = false;\n    float _7602 = 1.0;\n    float _7603 = 1.0;\n    float _7604 = 1.0;\n    float _7605 = 0.0;\n    float _7606 = 0.0;\n    float _7607 = 0.0;\n    float _7608 = 0.0;\n    float _7610 = 1.0;\n    bool _7611 = false;\n    vec3 _7612 = vec3(0.0);\n    float _7613 = 1.0;\n    float _7614 = 1.0;\n    float _7615 = 1.0;\n    float _7616 = 0.0;\n    float _7617 = 0.0;\n    vec3 _7618 = vec3(1.0, 0.0, 0.0);\n    vec3 _7619 = vec3(0.0, 0.0, 1.0);\n    float _7620 = 1.0;\n    float _7621 = 1.0;\n    float _3763 = clamp(s.specular, 0.0, 1.0);\n    float _3767 = clamp(s.ior, 1.0, 3.0);\n    bool _3772 = (_3763 != 1.0) || (_3767 != 1.5);\n    bool _3781;\n    if (!_3772)\n    {\n        _3781 = any(notEqual(s.specular_color, vec3(1.0)));\n    }\n    else\n    {\n        _3781 = _3772;\n    }\n    if (_3781)\n    {\n        float _3789 = (_3767 - 1.0) / (_3767 + 1.0);\n        f0 = mix(min(vec3(_3789 * _3789) * max(s.specular_color, vec3(0.0)), vec3(1.0)) * _3763, s.albedo, vec3(metallic));\n        _7602 = mix(_3763, 1.0, metallic);\n        _7601 = true;\n    }\n    float _3816 = clamp(s.clearcoat, 0.0, 1.0);\n    if (_3816 > 0.0)\n    {\n        float _3824 = clamp(s.clearcoat_roughness, 0.0500000007450580596923828125, 1.0);\n        _7605 = _3816;\n        _7606 = _3824;\n        float _3831 = _3824 * _3824;\n        _7607 = _3831;\n        _7608 = _3831 * _3831;\n        float _3843 = max(dot(i.world_normal, v), 9.9999997473787516355514526367188e-05);\n        _7610 = _3843;\n        _7603 = 1.0 - (_3816 * (0.039999999105930328369140625 + (0.959999978542327880859375 * pow(clamp(1.0 - _3843, 0.0, 1.0), 5.0))));\n        _7601 = true;\n    }\n    vec3 _3862 = max(s.sheen_color, vec3(0.0));\n    float _3871 = max(_3862.x, max(_3862.y, _3862.z));\n    if (_3871 > 0.0)\n    {\n        float _3879 = clamp(s.sheen_roughness, 0.100000001490116119384765625, 1.0);\n        _7611 = true;\n        _7612 = _3862;\n        _7613 = _3879;\n        _7614 = _3879 * _3879;\n        float param = max(dot(n, v), 9.9999997473787516355514526367188e-05);\n        float param_1 = _3879;\n        float _3896 = fa_sheen_albedo(param, param_1);\n        _7616 = _3896;\n        _7615 = 1.0 - min(_3871 * _3896, 1.0);\n        _7601 = true;\n    }\n    _7604 = _7603 * _7615;\n    float _3915 = clamp(s.anisotropy, -1.0, 1.0);\n    if (_3915 != 0.0)\n    {\n        vec3 _3930 = i.world_tangent.xyz - (n * dot(n, i.world_tangent.xyz));\n        vec3 t = _3930;\n        if (dot(_3930, _3930) < 9.9999999392252902907785028219223e-09)\n        {\n            bvec3 _3942 = bvec3(abs(n.y) < 0.9900000095367431640625);\n            t = cross(vec3(_3942.x ? vec3(0.0, 1.0, 0.0).x : vec3(1.0, 0.0, 0.0).x, _3942.y ? vec3(0.0, 1.0, 0.0).y : vec3(1.0, 0.0, 0.0).y, _3942.z ? vec3(0.0, 1.0, 0.0).z : vec3(1.0, 0.0, 0.0).z), n);\n        }\n        vec3 _3946 = t;\n        vec3 _3947 = normalize(_3946);\n        t = _3947;\n        vec3 _3972 = normalize((_3947 * cos(s.anisotropy_rotation)) + ((cross(n, _3947) * ((i.world_tangent.w < 0.0) ? (-1.0) : 1.0)) * sin(s.anisotropy_rotation)));\n        _7618 = _3972;\n        _7619 = cross(n, _3972);\n        float _3982 = roughness * roughness;\n        float _3988 = mix(_3982, 1.0, _3915 * _3915);\n        bool _3990 = _3915 > 0.0;\n        _7620 = _3990 ? _3988 : _3982;\n        _7621 = _3990 ? _3982 : _3988;\n        _7617 = _3915;\n        _7601 = true;\n    }\n    return FaLayers(_7601, _7602, _7603, _7604, _7605, _7606, _7607, _7608, i.world_normal, _7610, _7611, _7612, _7613, _7614, _7615, _7616, _7617, _7618, _7619, _7620, _7621);\n}\n\nvec3 fa_sky_sh_coef(int k)\n{\n    vec3 v = textureLod(fa_env_tex_fa_env_smp, vec3(1.0, 1.0 - (float((2 * (k >> 2)) + 1) * 0.25), 1.0 - (float((2 * (k & 3)) + 1) * 0.25)), 5.0).xyz;\n    if (fa_mesh_fs_params[11].w > 1.5)\n    {\n        v = (v - vec3(0.5)) * 8.0;\n    }\n    return v;\n}\n\nvec3 fa_sh_eval(vec3 c[9], vec3 n)\n{\n    vec3 _3371 = max((((c[0] * 0.2820948064327239990234375) + (((c[1] * (0.3257350027561187744140625 * n.y)) + (c[2] * (0.3257350027561187744140625 * n.z))) + (c[3] * (0.3257350027561187744140625 * n.x)))) + (((c[4] * ((0.2731371223926544189453125 * n.x) * n.y)) + (c[5] * ((0.2731371223926544189453125 * n.y) * n.z))) + (c[6] * (0.078847892582416534423828125 * (((3.0 * n.z) * n.z) - 1.0))))) + ((c[7] * ((0.2731371223926544189453125 * n.x) * n.z)) + (c[8] * (0.13656856119632720947265625 * ((n.x * n.x) - (n.y * n.y))))), vec3(0.0));\n    return _3371;\n}\n\nvec3 fa_ambient_light(vec3 n)\n{\n    if (fa_mesh_fs_params[11].w > 0.5)\n    {\n        vec3 c[9];\n        for (int k = 0; k < 9; k++)\n        {\n            int param = k;\n            c[k] = fa_sky_sh_coef(param);\n        }\n        vec3 param_1[9] = c;\n        vec3 param_2 = n;\n        return fa_sh_eval(param_1, param_2);\n    }\n    return fa_mesh_fs_params[1].xyz;\n}\n\nvec3 fa_indirect_diffuse(vec3 n)\n{\n    if (fa_lm.z > 0.5)\n    {\n        return textureLod(fa_lightmap_fa_env_smp, fa_lm.xy, 0.0).xyz;\n    }\n    vec3 param = n;\n    return fa_ambient_light(param);\n}\n\nint fa_cluster_index(int slot, int n)\n{\n    int param = (int(fa_mesh_fs_params[19].x) + int(fa_mesh_fs_params[19].w)) + ((slot + n) >> 2);\n    vec4 t = fa_light_texel(param);\n    return int(t[(slot + n) & 3]);\n}\n\nint fa_cl_light(int n)\n{\n    if (n < fa_cl_ndir)\n    {\n        return n;\n    }\n    int param = fa_cl_slot;\n    int param_1 = n - fa_cl_ndir;\n    return fa_cluster_index(param, param_1);\n}\n\nint fa_light_base(int li)\n{\n    return li * ((fa_mesh_fs_params[1].w > 4.5) ? 8 : 4);\n}\n\nbool fa_light_baked(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 3;\n    return fa_light_texel(param_1).w > 0.5;\n}\n\nfloat fa_light_type(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 1;\n    return fa_light_texel(param_1).w;\n}\n\nvec4 fa_atlas_fetch(vec2 texel)\n{\n    return textureLod(fa_light_atlas_fa_env_smp, texel / vec2(textureSize(fa_light_atlas_fa_env_smp, 0)), 0.0);\n}\n\nvec3 fa_cookie_sample(vec2 tile_origin, vec2 uv)\n{\n    vec2 param = (tile_origin + vec2(1.0)) + (clamp(uv, vec2(0.0), vec2(1.0)) * 254.0);\n    return fa_atlas_fetch(param).xyz;\n}\n\nvec3 fa_area_point(vec3 c, vec3 axis, vec3 ru, vec3 uu, float hx, float hy, float shape, vec3 p, vec3 r)\n{\n    bool _778 = dot(r, r) > 0.5;\n    if (shape > 1.5)\n    {\n        vec3 _791 = (c - (ru * hx)) - p;\n        vec3 _797 = ru * (2.0 * hx);\n        float _803 = max(dot(_797, _797), 9.9999999392252902907785028219223e-09);\n        float _807 = dot(_791, _797);\n        float t = clamp((-_807) / _803, 0.0, 1.0);\n        if (_778)\n        {\n            float _822 = dot(r, _797);\n            float _828 = _803 - (_822 * _822);\n            if (abs(_828) > (9.9999997473787516355514526367188e-06 * _803))\n            {\n                t = clamp(((dot(r, _791) * _822) - _807) / _828, 0.0, 1.0);\n            }\n        }\n        return (p + _791) + (_797 * t);\n    }\n    vec3 q = p;\n    float _860 = dot(r, axis);\n    bool _868;\n    if (_778)\n    {\n        _868 = abs(_860) > 9.9999997473787516355514526367188e-05;\n    }\n    else\n    {\n        _868 = _778;\n    }\n    if (_868)\n    {\n        float _878 = dot(c - p, axis) / _860;\n        if (_878 > 0.0)\n        {\n            q = p + (r * _878);\n        }\n    }\n    vec3 _891 = q - c;\n    vec2 xy = vec2(dot(_891, ru), dot(_891, uu));\n    if (shape > 0.5)\n    {\n        float _906 = length(xy);\n        if (_906 > hx)\n        {\n            xy *= (hx / _906);\n        }\n    }\n    else\n    {\n        xy = clamp(xy, vec2(-hx, -hy), vec2(hx, hy));\n    }\n    return (c + (ru * xy.x)) + (uu * xy.y);\n}\n\nint fa_cube_face(vec3 d)\n{\n    vec3 _540 = abs(d);\n    float _542 = _540.x;\n    float _544 = _540.y;\n    bool _545 = _542 >= _544;\n    bool _553;\n    if (_545)\n    {\n        _553 = _542 >= _540.z;\n    }\n    else\n    {\n        _553 = _545;\n    }\n    int _554;\n    if (_553)\n    {\n        _554 = (d.x > 0.0) ? 0 : 1;\n    }\n    else\n    {\n        int _569;\n        if (_544 >= _540.z)\n        {\n            _569 = (d.y > 0.0) ? 2 : 3;\n        }\n        else\n        {\n            _569 = (d.z > 0.0) ? 4 : 5;\n        }\n        _554 = _569;\n    }\n    return _554;\n}\n\nvoid fa_cube_face_basis(int f, out vec3 fwd, out vec3 up)\n{\n    if (f == 0)\n    {\n        fwd = vec3(1.0, 0.0, 0.0);\n        up = vec3(0.0, 1.0, 0.0);\n    }\n    else\n    {\n        if (f == 1)\n        {\n            fwd = vec3(-1.0, 0.0, 0.0);\n            up = vec3(0.0, 1.0, 0.0);\n        }\n        else\n        {\n            if (f == 2)\n            {\n                fwd = vec3(0.0, 1.0, 0.0);\n                up = vec3(0.0, 0.0, 1.0);\n            }\n            else\n            {\n                if (f == 3)\n                {\n                    fwd = vec3(0.0, -1.0, 0.0);\n                    up = vec3(0.0, 0.0, -1.0);\n                }\n                else\n                {\n                    if (f == 4)\n                    {\n                        fwd = vec3(0.0, 0.0, 1.0);\n                        up = vec3(0.0, 1.0, 0.0);\n                    }\n                    else\n                    {\n                        fwd = vec3(0.0, 0.0, -1.0);\n                        up = vec3(0.0, 1.0, 0.0);\n                    }\n                }\n            }\n        }\n    }\n}\n\nfloat fa_ies_sample(vec2 tile_origin, vec3 d, vec3 axis, vec3 right, vec3 up)\n{\n    float _698 = dot(d, right);\n    float _702 = dot(d, up);\n    float _713;\n    if (((_698 * _698) + (_702 * _702)) > 1.0000000133514319600180897396058e-10)\n    {\n        _713 = atan(_702, _698) * 0.15915493667125701904296875;\n    }\n    else\n    {\n        _713 = 0.0;\n    }\n    vec2 param = tile_origin + vec2(1.0 + ((_713 - floor(_713)) * 64.0), 1.0 + (acos(clamp(dot(d, axis), -1.0, 1.0)) * 10.18591594696044921875));\n    return fa_atlas_fetch(param).x;\n}\n\nLightSample fa_light_sample_n(int li, vec3 world_pos, vec3 n)\n{\n    int param = li;\n    int _944 = fa_light_base(param);\n    bool _948 = fa_mesh_fs_params[1].w > 4.5;\n    int param_1 = _944;\n    vec4 _952 = fa_light_texel(param_1);\n    int param_2 = _944 + 1;\n    vec4 _957 = fa_light_texel(param_2);\n    float _960 = _957.w;\n    float atten = 1.0;\n    float dist = 0.0;\n    fa_light_tint = vec3(1.0);\n    bool _972 = _948 && (_960 > 2.5);\n    fa_light_is_area = _972;\n    bool _974 = _960 < 0.5;\n    vec3 l;\n    if (_974)\n    {\n        l = normalize(_952.xyz);\n        if (_948)\n        {\n            int param_3 = _944 + 6;\n            vec4 _988 = fa_light_texel(param_3);\n            if (_988.z > 0.5)\n            {\n                int param_4 = _944 + 4;\n                vec4 _998 = fa_light_texel(param_4);\n                int param_5 = _944 + 5;\n                vec4 _1003 = fa_light_texel(param_5);\n                vec2 param_6 = _988.xy;\n                vec2 param_7 = fract(vec2(dot(world_pos, _998.xyz) * _998.w, (-dot(world_pos, _1003.xyz)) * _1003.w) + vec2(0.5));\n                fa_light_tint = fa_cookie_sample(param_6, param_7);\n            }\n        }\n    }\n    else\n    {\n        vec3 _1033 = _952.xyz;\n        vec3 _1035 = _1033 - world_pos;\n        vec3 to_light = _1035;\n        float _1038 = length(_1035);\n        float reach = _1038;\n        bool front = true;\n        if (_972)\n        {\n            int param_8 = _944 + 7;\n            reach = max(_1038 - fa_light_texel(param_8).w, 0.0);\n            int param_9 = _944 + 4;\n            vec4 _1062 = fa_light_texel(param_9);\n            int param_10 = _944 + 5;\n            vec4 _1067 = fa_light_texel(param_10);\n            int param_11 = _944 + 6;\n            vec4 _1072 = fa_light_texel(param_11);\n            float _1073 = _1072.w;\n            int param_12 = _944 + 2;\n            vec3 _1080 = normalize(fa_light_texel(param_12).xyz);\n            bool _1082 = _1073 > 1.5;\n            bool _1090;\n            if (!_1082)\n            {\n                _1090 = dot(_1080, to_light) < 0.0;\n            }\n            else\n            {\n                _1090 = _1082;\n            }\n            front = _1090;\n            vec3 r = vec3(0.0);\n            vec3 _1099 = fa_mesh_fs_params[0].xyz - world_pos;\n            bool _1103 = dot(n, n) > 0.5;\n            bool _1111;\n            if (_1103)\n            {\n                _1111 = dot(_1099, _1099) > 9.9999999600419720025001879548654e-13;\n            }\n            else\n            {\n                _1111 = _1103;\n            }\n            if (_1111)\n            {\n                r = reflect(-normalize(_1099), normalize(n));\n            }\n            vec3 param_13 = _1033;\n            vec3 param_14 = _1080;\n            vec3 param_15 = _1062.xyz;\n            vec3 param_16 = _1067.xyz;\n            float param_17 = _1062.w;\n            float param_18 = _1067.w;\n            float param_19 = _1073;\n            vec3 param_20 = world_pos;\n            vec3 param_21 = r;\n            to_light = fa_area_point(param_13, param_14, param_15, param_16, param_17, param_18, param_19, param_20, param_21) - world_pos;\n        }\n        float _1147 = length(to_light);\n        dist = _1147;\n        l = to_light / vec3(max(_1147, 9.9999997473787516355514526367188e-05));\n        float _1161 = reach / max(_952.w, 0.001000000047497451305389404296875);\n        float _1167 = clamp(1.0 - (_1161 * _1161), 0.0, 1.0);\n        float _1169;\n        if (front)\n        {\n            _1169 = _1167 * _1167;\n        }\n        else\n        {\n            _1169 = 0.0;\n        }\n        atten = _1169;\n        bool _1180 = _960 < 2.5;\n        if ((_960 > 1.5) && _1180)\n        {\n            int param_22 = _944 + 2;\n            vec4 _1188 = fa_light_texel(param_22);\n            float _1198 = _1188.w;\n            int param_23 = _944 + 3;\n            vec4 _1203 = fa_light_texel(param_23);\n            float _1204 = _1203.x;\n            float cos_inner = _1204;\n            if (_1204 > 1.5)\n            {\n                cos_inner = mix(_1198, 1.0, 0.25);\n            }\n            atten *= smoothstep(_1198, cos_inner, dot(-l, normalize(_1188.xyz)));\n        }\n        if (_948 && (_960 < 1.5))\n        {\n            int param_24 = _944 + 6;\n            vec4 _1228 = fa_light_texel(param_24);\n            if (_1228.z > 0.5)\n            {\n                vec3 _1236 = -to_light;\n                int param_25 = _944 + 4;\n                int param_26 = _944 + 5;\n                vec3 _1250 = fa_light_texel(param_25).xyz;\n                vec3 _1254 = fa_light_texel(param_26).xyz;\n                vec3 _1263 = vec3(dot(_1236, _1250), dot(_1236, _1254), dot(_1236, cross(_1250, _1254)));\n                vec3 param_27 = _1263;\n                int _1267 = fa_cube_face(param_27);\n                int param_28 = _1267;\n                vec3 param_29;\n                vec3 param_30;\n                fa_cube_face_basis(param_28, param_29, param_30);\n                vec2 _1294 = vec2(dot(_1263, cross(param_29, param_30)), dot(_1263, param_30)) / vec2(max(dot(_1263, param_29), 9.9999997473787516355514526367188e-05));\n                int _1298 = _1267 / 3;\n                vec2 param_31 = _1228.xy + (vec2(float(_1267 - (_1298 * 3)), float(_1298)) * 256.0);\n                vec2 param_32 = vec2(0.5 + (0.5 * _1294.x), 0.5 - (0.5 * _1294.y));\n                fa_light_tint = fa_cookie_sample(param_31, param_32);\n            }\n            int param_33 = _944 + 7;\n            vec4 _1328 = fa_light_texel(param_33);\n            if (_1328.z > 0.5)\n            {\n                int param_34 = _944 + 2;\n                int param_35 = _944 + 4;\n                int param_36 = _944 + 5;\n                vec2 param_37 = _1328.xy;\n                vec3 param_38 = -l;\n                vec3 param_39 = normalize(fa_light_texel(param_34).xyz);\n                vec3 param_40 = fa_light_texel(param_35).xyz;\n                vec3 param_41 = fa_light_texel(param_36).xyz;\n                atten *= fa_ies_sample(param_37, param_38, param_39, param_40, param_41);\n            }\n        }\n        else\n        {\n            if (_948 && _1180)\n            {\n                int param_42 = _944 + 6;\n                vec4 _1375 = fa_light_texel(param_42);\n                int param_43 = _944 + 7;\n                vec4 _1380 = fa_light_texel(param_43);\n                bool _1383 = _1375.z > 0.5;\n                bool _1390;\n                if (!_1383)\n                {\n                    _1390 = _1380.z > 0.5;\n                }\n                else\n                {\n                    _1390 = _1383;\n                }\n                if (_1390)\n                {\n                    int param_44 = _944 + 2;\n                    vec4 _1397 = fa_light_texel(param_44);\n                    vec3 _1401 = normalize(_1397.xyz);\n                    int param_45 = _944 + 4;\n                    vec4 _1406 = fa_light_texel(param_45);\n                    int param_46 = _944 + 5;\n                    vec4 _1411 = fa_light_texel(param_46);\n                    if (_1383)\n                    {\n                        vec3 _1419 = -to_light;\n                        float _1426 = _1397.w;\n                        float _1442 = 0.5 / max(dot(_1419, _1401) * (sqrt(max(1.0 - (_1426 * _1426), 0.0)) / max(_1426, 0.001000000047497451305389404296875)), 9.9999997473787516355514526367188e-05);\n                        vec2 param_47 = _1375.xy;\n                        vec2 param_48 = vec2(0.5 + (dot(_1419, _1406.xyz) * _1442), 0.5 - (dot(_1419, _1411.xyz) * _1442));\n                        fa_light_tint = fa_cookie_sample(param_47, param_48);\n                    }\n                    if (_1380.z > 0.5)\n                    {\n                        vec2 param_49 = _1380.xy;\n                        vec3 param_50 = -l;\n                        vec3 param_51 = _1401;\n                        vec3 param_52 = _1406.xyz;\n                        vec3 param_53 = _1411.xyz;\n                        atten *= fa_ies_sample(param_49, param_50, param_51, param_52, param_53);\n                    }\n                }\n            }\n        }\n    }\n    vec3 _7589 = _957.xyz * atten;\n    if (_948)\n    {\n        _7589 *= fa_light_tint;\n    }\n    int _1511;\n    if (_974)\n    {\n        _1511 = 0;\n    }\n    else\n    {\n        _1511 = ((_960 > 1.5) && (_960 < 2.5)) ? 2 : 1;\n    }\n    return LightSample(l, _7589, atten, 1.0, dist, _1511);\n}\n\nfloat fa_shadow_split_at(int i)\n{\n    float _2248;\n    if (i == 0)\n    {\n        _2248 = fa_shadows[24].x;\n    }\n    else\n    {\n        float _2264;\n        if (i == 1)\n        {\n            _2264 = fa_shadows[24].y;\n        }\n        else\n        {\n            float _2272;\n            if (i == 2)\n            {\n                _2272 = fa_shadows[24].z;\n            }\n            else\n            {\n                _2272 = fa_shadows[24].w;\n            }\n            _2264 = _2272;\n        }\n        _2248 = _2264;\n    }\n    return _2248;\n}\n\nfloat fa_shadow_depth(inout vec2 uv, vec4 rect)\n{\n    uv = clamp(uv, rect.xy, rect.zw);\n    return textureLod(fa_shadow_tex_fa_shadow_smp, uv, 0.0).x;\n}\n\nfloat fa_shadow_fetch(vec2 uv, vec4 rect, vec3 conv)\n{\n    vec2 param = uv;\n    vec4 param_1 = rect;\n    float _2305 = fa_shadow_depth(param, param_1);\n    float _2309;\n    if (conv.x < 0.5)\n    {\n        _2309 = _2305;\n    }\n    else\n    {\n        _2309 = (conv.y * conv.z) / (conv.z - (_2305 * (conv.z - conv.y)));\n    }\n    return _2309;\n}\n\nfloat fa_shadow_noise()\n{\n    return fract(52.98291778564453125 * fract(dot(gl_FragCoord.xy, vec2(0.067110560834407806396484375, 0.005837149918079376220703125))));\n}\n\nvec2 fa_shadow_vogel(int k, int n, float phi)\n{\n    float _2236 = (float(k) * 2.3999631404876708984375) + phi;\n    return vec2(cos(_2236), sin(_2236)) * sqrt((float(k) + 0.5) / float(n));\n}\n\nfloat fa_shadow_filter(vec2 uv, vec4 rect, float zr, float texel_m, float unit, float reach, float plane, vec3 conv, int mode, float k)\n{\n    if (mode == 1)\n    {\n        vec2 param = uv;\n        vec4 param_1 = rect;\n        vec3 param_2 = conv;\n        return float(zr <= fa_shadow_fetch(param, param_1, param_2));\n    }\n    float _2355 = fa_shadow_noise() * 6.283185482025146484375;\n    float radius = 1.5;\n    if (mode == 2)\n    {\n        float _2364;\n        if (k < 0.0)\n        {\n            _2364 = (-k) / max(zr, 0.100000001490116119384765625);\n        }\n        else\n        {\n            _2364 = k;\n        }\n        float _2384 = clamp((_2364 * reach) / texel_m, 3.0, 12.0);\n        float sum = 0.0;\n        float cnt = 0.0;\n        for (int i = 0; i < 16; i++)\n        {\n            int param_3 = i;\n            int param_4 = 16;\n            float param_5 = _2355;\n            vec2 _2403 = fa_shadow_vogel(param_3, param_4, param_5) * _2384;\n            vec2 param_6 = uv + (_2403 * fa_shadows[26].zw);\n            vec4 param_7 = rect;\n            vec3 param_8 = conv;\n            float _2415 = fa_shadow_fetch(param_6, param_7, param_8);\n            if (_2415 < (zr - (length(_2403) * plane)))\n            {\n                sum += _2415;\n                cnt += 1.0;\n            }\n        }\n        if (cnt < 0.5)\n        {\n            return 1.0;\n        }\n        float _2441 = sum / cnt;\n        float _2451;\n        if (k < 0.0)\n        {\n            _2451 = (-k) / max(_2441, 0.0500000007450580596923828125);\n        }\n        else\n        {\n            _2451 = k;\n        }\n        radius = clamp(((max(zr - _2441, 0.0) * unit) * _2451) / texel_m, 1.5, 16.0);\n    }\n    float lit = 0.0;\n    int _2473 = (mode == 2) ? 24 : 16;\n    for (int i_1 = 0; i_1 < _2473; i_1++)\n    {\n        int param_9 = i_1;\n        int param_10 = _2473;\n        float param_11 = _2355;\n        vec2 _2492 = fa_shadow_vogel(param_9, param_10, param_11) * radius;\n        vec2 param_12 = uv + (_2492 * fa_shadows[26].zw);\n        vec4 param_13 = rect;\n        vec3 param_14 = conv;\n        lit += float((zr - (length(_2492) * plane)) <= fa_shadow_fetch(param_12, param_13, param_14));\n    }\n    return lit / float(_2473);\n}\n\nfloat fa_shadow_cascade(int ci, vec3 world, vec3 n, vec3 l)\n{\n    float _2534 = max(fa_shadows[ci * 1 + 20].y, 0.001000000047497451305389404296875);\n    float _2539 = clamp(dot(n, l), 0.0, 1.0);\n    float _2545 = sqrt(1.0 - (_2539 * _2539));\n    float _2552 = min(_2545 / max(_2539, 0.20000000298023223876953125), 4.0);\n    float _2557;\n    if (fa_shadows[26].y > 0.0)\n    {\n        _2557 = fa_shadows[26].y;\n    }\n    else\n    {\n        _2557 = 1.5 * fa_shadows[ci * 1 + 20].x;\n    }\n    vec4 _2582 = mat4(fa_shadows[ci * 4 + 0], fa_shadows[ci * 4 + 1], fa_shadows[ci * 4 + 2], fa_shadows[ci * 4 + 3]) * vec4(world + (n * (_2557 * _2545)), 1.0);\n    float _2589 = _2582.x;\n    bool _2592 = _2589 < fa_shadows[ci * 1 + 16].x;\n    bool _2601;\n    if (!_2592)\n    {\n        _2601 = _2589 > fa_shadows[ci * 1 + 16].z;\n    }\n    else\n    {\n        _2601 = _2592;\n    }\n    bool _2610;\n    if (!_2601)\n    {\n        _2610 = _2582.y < fa_shadows[ci * 1 + 16].y;\n    }\n    else\n    {\n        _2610 = _2601;\n    }\n    bool _2619;\n    if (!_2610)\n    {\n        _2619 = _2582.y > fa_shadows[ci * 1 + 16].w;\n    }\n    else\n    {\n        _2619 = _2610;\n    }\n    bool _2626;\n    if (!_2619)\n    {\n        _2626 = _2582.z > 1.0;\n    }\n    else\n    {\n        _2626 = _2619;\n    }\n    if (_2626)\n    {\n        return -1.0;\n    }\n    float _2634;\n    if (fa_shadows[26].x > 0.0)\n    {\n        _2634 = fa_shadows[26].x;\n    }\n    else\n    {\n        _2634 = 1.5 * fa_shadows[ci * 1 + 20].x;\n    }\n    vec2 param = _2582.xy;\n    vec4 param_1 = fa_shadows[ci * 1 + 16];\n    float param_2 = _2582.z - ((_2634 * (1.0 + (0.5 * _2552))) / _2534);\n    float param_3 = fa_shadows[ci * 1 + 20].x;\n    float param_4 = _2534;\n    float param_5 = _2534 * 0.25;\n    float param_6 = ((fa_shadows[ci * 1 + 20].x * min(_2552, 3.0)) * 0.5) / _2534;\n    vec3 param_7 = vec3(0.0);\n    int param_8 = int(fa_shadows[25].z + 0.5);\n    float param_9 = fa_shadows[25].w;\n    return fa_shadow_filter(param, param_1, param_2, param_3, param_4, param_5, param_6, param_7, param_8, param_9);\n}\n\nfloat fa_shadow_sun(vec3 world, vec3 n, vec3 l)\n{\n    if (fa_mesh_fs_params[5].z < 0.5)\n    {\n        return 1.0;\n    }\n    int _3012 = int(fa_shadows[25].x + 0.5);\n    if (_3012 < 1)\n    {\n        return 1.0;\n    }\n    float _3027 = dot(world - fa_shadows[27].xyz, fa_shadows[28].xyz);\n    int param = _3012 - 1;\n    if (_3027 > fa_shadow_split_at(param))\n    {\n        return 1.0;\n    }\n    int ci = 0;\n    bool _3039 = _3012 > 1;\n    bool _3046;\n    if (_3039)\n    {\n        _3046 = _3027 > fa_shadows[24].x;\n    }\n    else\n    {\n        _3046 = _3039;\n    }\n    if (_3046)\n    {\n        ci = 1;\n    }\n    bool _3050 = _3012 > 2;\n    bool _3057;\n    if (_3050)\n    {\n        _3057 = _3027 > fa_shadows[24].y;\n    }\n    else\n    {\n        _3057 = _3050;\n    }\n    if (_3057)\n    {\n        ci = 2;\n    }\n    bool _3061 = _3012 > 3;\n    bool _3068;\n    if (_3061)\n    {\n        _3068 = _3027 > fa_shadows[24].z;\n    }\n    else\n    {\n        _3068 = _3061;\n    }\n    if (_3068)\n    {\n        ci = 3;\n    }\n    float s = -1.0;\n    for (int k = 0; k < 4; k++)\n    {\n        if (ci >= _3012)\n        {\n            break;\n        }\n        int param_1 = ci;\n        vec3 param_2 = world;\n        vec3 param_3 = n;\n        vec3 param_4 = l;\n        float _3094 = fa_shadow_cascade(param_1, param_2, param_3, param_4);\n        s = _3094;\n        if (_3094 >= 0.0)\n        {\n            break;\n        }\n        ci++;\n    }\n    if (s < 0.0)\n    {\n        return 1.0;\n    }\n    if (fa_shadows[25].y > 0.0)\n    {\n        float _3119;\n        if (ci > 0)\n        {\n            int param_5 = ci - 1;\n            _3119 = fa_shadow_split_at(param_5);\n        }\n        else\n        {\n            _3119 = fa_shadows[28].w;\n        }\n        int param_6 = ci;\n        float _3138 = fa_shadows[25].y * max(fa_shadow_split_at(param_6) - _3119, 9.9999997473787516355514526367188e-05);\n        int param_7 = ci;\n        float _3149 = clamp((_3027 - (fa_shadow_split_at(param_7) - _3138)) / _3138, 0.0, 1.0);\n        if (_3149 > 0.0)\n        {\n            float s2 = 1.0;\n            if ((ci + 1) < _3012)\n            {\n                int param_8 = ci + 1;\n                vec3 param_9 = world;\n                vec3 param_10 = n;\n                vec3 param_11 = l;\n                float _3170 = fa_shadow_cascade(param_8, param_9, param_10, param_11);\n                s2 = _3170;\n                if (_3170 < 0.0)\n                {\n                    s2 = s;\n                }\n            }\n            s = mix(s, s2, _3149);\n        }\n    }\n    return s;\n}\n\nfloat fa_shadow_factor(vec3 n, vec3 l)\n{\n    vec3 param = fa_world_pos;\n    vec3 param_1 = n;\n    vec3 param_2 = l;\n    return fa_shadow_sun(param, param_1, param_2);\n}\n\nfloat fa_shadow_local(int li, vec3 lpos, vec3 world, vec3 n, vec3 l)\n{\n    bool _2692 = fa_mesh_fs_params[5].z < 0.5;\n    bool _2699;\n    if (!_2692)\n    {\n        _2699 = fa_shadows[29].x < 0.5;\n    }\n    else\n    {\n        _2699 = _2692;\n    }\n    if (_2699)\n    {\n        return 1.0;\n    }\n    int param = (int(fa_shadows[29].x + 0.5) - 1) + li;\n    vec4 _2712 = fa_light_texel(param);\n    float _2713 = _2712.x;\n    if (_2713 < 0.0)\n    {\n        return 1.0;\n    }\n    int _2722 = int(_2713 + 0.5);\n    int param_1 = _2722;\n    vec4 _2726 = fa_light_texel(param_1);\n    int param_2 = _2722 + 1;\n    vec4 _2731 = fa_light_texel(param_2);\n    float fade = 1.0;\n    float _2734 = _2726.y;\n    if (_2734 > 0.0)\n    {\n        float _2751 = 1.0 - smoothstep(0.75 * _2734, _2734, length(world - fa_shadows[27].xyz));\n        fade = _2751;\n        if (_2751 <= 0.0)\n        {\n            return 1.0;\n        }\n    }\n    int face = 0;\n    if (_2726.x > 1.5)\n    {\n        vec3 param_3 = world - lpos;\n        face = fa_cube_face(param_3);\n    }\n    int _2775 = (_2722 + 2) + (face * 6);\n    int param_4 = _2775;\n    int param_5 = _2775 + 1;\n    int param_6 = _2775 + 3;\n    vec4 _2789 = fa_light_texel(param_6);\n    int param_7 = _2775 + 4;\n    vec4 _2794 = fa_light_texel(param_7);\n    int param_8 = _2775 + 5;\n    vec4 _2799 = fa_light_texel(param_8);\n    float _2811 = _2799.x * max(dot(_2789, vec4(world, 1.0)), 0.001000000047497451305389404296875);\n    float _2816 = clamp(dot(n, l), 0.0, 1.0);\n    float _2839 = clamp(dot(n, _2789.xyz), -1.0, 1.0);\n    float _2858 = min(sqrt(1.0 - (_2839 * _2839)) / max(abs(dot(n, world - lpos)) / max(dot(_2789, vec4(world, 1.0)), 0.001000000047497451305389404296875), 0.20000000298023223876953125), 4.0);\n    float _2861 = _2731.y;\n    float _2863;\n    if (_2861 > 0.0)\n    {\n        _2863 = _2861;\n    }\n    else\n    {\n        _2863 = 1.5 * _2811;\n    }\n    vec4 _2883 = vec4(world + (n * (_2863 * sqrt(1.0 - (_2816 * _2816)))), 1.0);\n    float _2887 = dot(_2789, _2883);\n    float _2890 = _2799.y;\n    if (_2887 < _2890)\n    {\n        return 1.0;\n    }\n    vec2 _2905 = vec2(dot(fa_light_texel(param_4), _2883), dot(fa_light_texel(param_5), _2883)) / vec2(_2887);\n    float _2907 = _2905.x;\n    bool _2910 = _2907 < _2794.x;\n    bool _2919;\n    if (!_2910)\n    {\n        _2919 = _2907 > _2794.z;\n    }\n    else\n    {\n        _2919 = _2910;\n    }\n    bool _2928;\n    if (!_2919)\n    {\n        _2928 = _2905.y < _2794.y;\n    }\n    else\n    {\n        _2928 = _2919;\n    }\n    bool _2937;\n    if (!_2928)\n    {\n        _2937 = _2905.y > _2794.w;\n    }\n    else\n    {\n        _2937 = _2928;\n    }\n    if (_2937)\n    {\n        return 1.0;\n    }\n    float _2943 = _2731.x;\n    float _2945;\n    if (_2943 > 0.0)\n    {\n        _2945 = _2943;\n    }\n    else\n    {\n        _2945 = 1.5 * _2811;\n    }\n    vec2 param_9 = _2905;\n    vec4 param_10 = _2794;\n    float param_11 = _2887 - (_2945 * (1.0 + (0.5 * _2858)));\n    float param_12 = _2811;\n    float param_13 = 1.0;\n    float param_14 = _2799.z * 0.25;\n    float param_15 = (_2811 * min(_2858, 3.0)) * 0.5;\n    vec3 param_16 = vec3(1.0, _2890, _2799.z);\n    int param_17 = int(_2726.z + 0.5);\n    float param_18 = _2726.w;\n    return mix(1.0, fa_shadow_filter(param_9, param_10, param_11, param_12, param_13, param_14, param_15, param_16, param_17, param_18), fade);\n}\n\nfloat fa_contact_shadow(int li, vec3 world, vec3 gn, vec3 l, float dist)\n{\n    bool _4500 = fa_mesh_fs_params[24].x < 0.5;\n    bool _4507;\n    if (!_4500)\n    {\n        _4507 = fa_shadows[29].x < 0.5;\n    }\n    else\n    {\n        _4507 = _4500;\n    }\n    if (_4507)\n    {\n        return 1.0;\n    }\n    int param = (int(fa_shadows[29].x + 0.5) - 1) + li;\n    vec4 _4520 = fa_light_texel(param);\n    float _4521 = _4520.y;\n    float len = _4521;\n    if (_4521 <= 0.0)\n    {\n        return 1.0;\n    }\n    float _4533 = length(world - fa_mesh_fs_params[0].xyz);\n    float _4543 = 1.0 - smoothstep(0.5 * fa_mesh_fs_params[25].x, fa_mesh_fs_params[25].x, _4533);\n    if (_4543 <= 0.0)\n    {\n        return 1.0;\n    }\n    float _4549 = len;\n    float _4552 = min(_4549, 0.89999997615814208984375 * dist);\n    len = _4552;\n    float _4557 = 0.004999999888241291046142578125 + (0.0030000000260770320892333984375 * _4533);\n    float _4562 = _4557 + (0.5 * _4552);\n    vec3 _4568 = world + (gn * _4557);\n    float _4570 = fa_shadow_noise();\n    float occ = 0.0;\n    float _4634;\n    for (int k = 0; k < 12; k++)\n    {\n        float _4585 = (float(k) + _4570) * 0.083333335816860198974609375;\n        vec3 _4593 = _4568 + (l * (_4585 * len));\n        vec4 _4599 = vec4(_4593, 1.0);\n        float _4605 = dot(fa_mesh_fs_params[28], _4599);\n        if (_4605 < 9.9999997473787516355514526367188e-05)\n        {\n            break;\n        }\n        vec2 _4625 = vec2(dot(fa_mesh_fs_params[26], _4599), dot(fa_mesh_fs_params[27], _4599)) / vec2(_4605);\n        float _4629 = _4625.x * 0.5;\n        float _4630 = _4629 + 0.5;\n        if (fa_mesh_fs_params[24].y > 0.5)\n        {\n            _4634 = (_4625.y * 0.5) + 0.5;\n        }\n        else\n        {\n            _4634 = 0.5 - (_4625.y * 0.5);\n        }\n        bool _4650 = _4630 < 0.0;\n        bool _4657;\n        if (!_4650)\n        {\n            _4657 = _4630 >= 1.0;\n        }\n        else\n        {\n            _4657 = _4650;\n        }\n        bool _4664;\n        if (!_4657)\n        {\n            _4664 = _4634 < 0.0;\n        }\n        else\n        {\n            _4664 = _4657;\n        }\n        bool _4671;\n        if (!_4664)\n        {\n            _4671 = _4634 >= 1.0;\n        }\n        else\n        {\n            _4671 = _4664;\n        }\n        if (_4671)\n        {\n            break;\n        }\n        vec4 _4690 = texelFetch(fa_screen_tex_fa_shadow_smp, ivec2(vec2(_4630, _4634) * fa_mesh_fs_params[24].zw), 0);\n        if (_4690.w < 0.5)\n        {\n            continue;\n        }\n        float _4709 = (dot(fa_mesh_fs_params[29].xyz, _4593) + fa_mesh_fs_params[29].w) - _4690.x;\n        if ((_4709 > _4557) && (_4709 < _4562))\n        {\n            occ = max(occ, (1.0 - (_4585 * _4585)) * smoothstep(0.0, 0.0500000007450580596923828125, min(min(_4630, 0.5 - _4629), min(_4634, 1.0 - _4634))));\n        }\n    }\n    return 1.0 - (occ * _4543);\n}\n\nLightSample fa_light_shadowed(int li, vec3 world_pos, vec3 gn)\n{\n    bool _5148 = fa_lm.z > 0.5;\n    bool _5154;\n    if (_5148)\n    {\n        int param = li;\n        _5154 = fa_light_baked(param);\n    }\n    else\n    {\n        _5154 = _5148;\n    }\n    if (_5154)\n    {\n        int param_1 = li;\n        return LightSample(vec3(0.0, 1.0, 0.0), vec3(0.0), 0.0, 1.0, 0.0, int(fa_light_type(param_1) + 0.5));\n    }\n    int param_2 = li;\n    vec3 param_3 = world_pos;\n    vec3 param_4 = gn;\n    LightSample _5178 = fa_light_sample_n(param_2, param_3, param_4);\n    vec3 _7658 = _5178.color;\n    float _7660 = _5178.shadow;\n    bool _5181 = _5178.type == 0;\n    if (_5181 && (li == 0))\n    {\n        vec3 param_5 = gn;\n        vec3 param_6 = _5178.direction;\n        float _5192 = fa_shadow_factor(param_5, param_6);\n        _7660 = _5192;\n        _7658 *= _5192;\n    }\n    else\n    {\n        bool _5203 = _5178.type != 0;\n        bool _5209;\n        if (_5203)\n        {\n            _5209 = _5178.attenuation > 0.0;\n        }\n        else\n        {\n            _5209 = _5203;\n        }\n        if (_5209)\n        {\n            int param_7 = li;\n            int param_8 = fa_light_base(param_7);\n            int param_9 = li;\n            vec3 param_10 = fa_light_texel(param_8).xyz;\n            vec3 param_11 = world_pos;\n            vec3 param_12 = gn;\n            vec3 param_13 = _5178.direction;\n            float _5228 = fa_shadow_local(param_9, param_10, param_11, param_12, param_13);\n            _7660 = _5228;\n            _7658 *= _5228;\n        }\n    }\n    bool _5238 = fa_mesh_fs_params[24].x > 0.5;\n    bool _5244;\n    if (_5238)\n    {\n        _5244 = _5178.attenuation > 0.0;\n    }\n    else\n    {\n        _5244 = _5238;\n    }\n    if (_5244)\n    {\n        float _5251;\n        if (_5181)\n        {\n            _5251 = 1000000000.0;\n        }\n        else\n        {\n            _5251 = _5178._distance;\n        }\n        int param_14 = li;\n        vec3 param_15 = world_pos;\n        vec3 param_16 = gn;\n        vec3 param_17 = _5178.direction;\n        float param_18 = _5251;\n        float _5269 = fa_contact_shadow(param_14, param_15, param_16, param_17, param_18);\n        _7660 *= _5269;\n        _7658 *= _5269;\n    }\n    return LightSample(_5178.direction, _7658, _5178.attenuation, _7660, _5178._distance, _5178.type);\n}\n\nvec3 fa_ltc_tangent(vec3 n, vec3 v)\n{\n    vec3 _5312 = v - (n * dot(v, n));\n    vec3 t = _5312;\n    float _5316 = dot(_5312, _5312);\n    float l2 = _5316;\n    if (_5316 < 1.0000000133514319600180897396058e-10)\n    {\n        vec3 _5326;\n        if (abs(n.z) < 0.999000012874603271484375)\n        {\n            _5326 = cross(n, vec3(0.0, 0.0, 1.0));\n        }\n        else\n        {\n            _5326 = cross(n, vec3(1.0, 0.0, 0.0));\n        }\n        t = _5326;\n        l2 = dot(_5326, _5326);\n    }\n    return t * inversesqrt(l2);\n}\n\nvec3 fa_ltc_local(vec3 t1, vec3 n, vec3 p)\n{\n    return vec3(dot(t1, p), dot(cross(n, t1), p), dot(n, p));\n}\n\nvec3 fa_ltc_edge_vector(vec3 a, vec3 b)\n{\n    float _5361 = dot(a, a);\n    float _5365 = dot(b, b);\n    if ((_5361 < 1.0000000195414813782625560981111e-24) || (_5365 < 1.0000000195414813782625560981111e-24))\n    {\n        return vec3(0.0);\n    }\n    vec3 _5379 = a * inversesqrt(_5361);\n    vec3 _5384 = b * inversesqrt(_5365);\n    float _5388 = dot(_5379, _5384);\n    float _5391 = abs(_5388);\n    float g = (((((((((((0.0416471660137176513671875 * _5391) - 0.1924748718738555908203125) * _5391) + 0.4179156124591827392578125) * _5391) - 0.616057217121124267578125) * _5391) + 0.777722418308258056640625) * _5391) - 0.999542415142059326171875) * _5391) + 1.570791721343994140625;\n    if (_5388 < 0.0)\n    {\n        g = (3.1415927410125732421875 * inversesqrt(max(1.0 - (_5388 * _5388), 1.0000000116860974230803549289703e-07))) - g;\n    }\n    return cross(_5379, _5384) * g;\n}\n\nvoid fa_ltc_clip_edge(vec3 a, vec3 b, inout vec3 sum, inout vec3 leave, inout vec3 enter, inout vec2 seen)\n{\n    bool _5448 = a.z > 0.0;\n    bool _5452 = b.z > 0.0;\n    if (_5448 && _5452)\n    {\n        vec3 param = a;\n        vec3 param_1 = b;\n        sum += fa_ltc_edge_vector(param, param_1);\n    }\n    else\n    {\n        if (_5448 != _5452)\n        {\n            vec3 _5487 = a + ((b - a) * (a.z / (a.z - b.z)));\n            _5487.z = 0.0;\n            if (_5448)\n            {\n                vec3 param_2 = a;\n                vec3 param_3 = _5487;\n                sum += fa_ltc_edge_vector(param_2, param_3);\n                leave = _5487;\n                seen.x = 1.0;\n            }\n            else\n            {\n                vec3 param_4 = _5487;\n                vec3 param_5 = b;\n                sum += fa_ltc_edge_vector(param_4, param_5);\n                enter = _5487;\n                seen.y = 1.0;\n            }\n        }\n    }\n}\n\nfloat fa_ltc_quad(vec4 abcd, vec3 p0, vec3 p1, vec3 p2, vec3 p3)\n{\n    vec3 _5536 = vec3((abcd.x * p0.x) + (abcd.y * p0.z), p0.y, (abcd.z * p0.x) + (abcd.w * p0.z));\n    vec3 _5562 = vec3((abcd.x * p1.x) + (abcd.y * p1.z), p1.y, (abcd.z * p1.x) + (abcd.w * p1.z));\n    vec3 _5588 = vec3((abcd.x * p2.x) + (abcd.y * p2.z), p2.y, (abcd.z * p2.x) + (abcd.w * p2.z));\n    vec3 _5614 = vec3((abcd.x * p3.x) + (abcd.y * p3.z), p3.y, (abcd.z * p3.x) + (abcd.w * p3.z));\n    vec3 sum = vec3(0.0);\n    vec3 leave = vec3(0.0);\n    vec3 enter = vec3(0.0);\n    vec3 param = _5536;\n    vec3 param_1 = _5562;\n    vec3 param_2 = vec3(0.0);\n    vec3 param_3 = vec3(0.0);\n    vec3 param_4 = vec3(0.0);\n    vec2 param_5 = vec2(0.0);\n    fa_ltc_clip_edge(param, param_1, param_2, param_3, param_4, param_5);\n    sum = param_2;\n    leave = param_3;\n    enter = param_4;\n    vec3 param_6 = _5562;\n    vec3 param_7 = _5588;\n    vec3 param_8 = param_2;\n    vec3 param_9 = param_3;\n    vec3 param_10 = param_4;\n    vec2 param_11 = param_5;\n    fa_ltc_clip_edge(param_6, param_7, param_8, param_9, param_10, param_11);\n    sum = param_8;\n    leave = param_9;\n    enter = param_10;\n    vec3 param_12 = _5588;\n    vec3 param_13 = _5614;\n    vec3 param_14 = param_8;\n    vec3 param_15 = param_9;\n    vec3 param_16 = param_10;\n    vec2 param_17 = param_11;\n    fa_ltc_clip_edge(param_12, param_13, param_14, param_15, param_16, param_17);\n    sum = param_14;\n    leave = param_15;\n    enter = param_16;\n    vec3 param_18 = _5614;\n    vec3 param_19 = _5536;\n    vec3 param_20 = param_14;\n    vec3 param_21 = param_15;\n    vec3 param_22 = param_16;\n    vec2 param_23 = param_17;\n    fa_ltc_clip_edge(param_18, param_19, param_20, param_21, param_22, param_23);\n    sum = param_20;\n    leave = param_21;\n    enter = param_22;\n    if ((param_23.x * param_23.y) > 0.5)\n    {\n        vec3 param_24 = leave;\n        vec3 param_25 = enter;\n        sum += fa_ltc_edge_vector(param_24, param_25);\n    }\n    return sum.z * 0.15915493667125701904296875;\n}\n\nfloat fa_ltc_rect(vec4 abcd, vec3 center, vec3 ex, vec3 ey)\n{\n    vec4 param = abcd;\n    vec3 param_1 = (center - ex) - ey;\n    vec3 param_2 = (center + ex) - ey;\n    vec3 param_3 = (center + ex) + ey;\n    vec3 param_4 = (center - ex) + ey;\n    return abs(fa_ltc_quad(param, param_1, param_2, param_3, param_4));\n}\n\nfloat fa_area_form(vec4 m, float shape, vec3 pc, vec3 ex, vec3 ey)\n{\n    if ((shape < 0.5) || (shape > 1.5))\n    {\n        vec4 param = m;\n        vec3 param_1 = pc;\n        vec3 param_2 = ex;\n        vec3 param_3 = ey;\n        return fa_ltc_rect(param, param_1, param_2, param_3);\n    }\n    vec3 _5763 = (pc + (ex * 0.92387950420379638671875)) + (ey * 0.3826834261417388916015625);\n    vec3 _5787 = (pc - (ex * 0.92387950420379638671875)) + (ey * 0.3826834261417388916015625);\n    vec3 _5803 = (pc - (ex * 0.3826834261417388916015625)) - (ey * 0.92387950420379638671875);\n    vec4 param_4 = m;\n    vec3 param_5 = _5763;\n    vec3 param_6 = (pc + (ex * 0.3826834261417388916015625)) + (ey * 0.92387950420379638671875);\n    vec3 param_7 = (pc - (ex * 0.3826834261417388916015625)) + (ey * 0.92387950420379638671875);\n    vec3 param_8 = _5787;\n    vec4 param_9 = m;\n    vec3 param_10 = _5763;\n    vec3 param_11 = _5787;\n    vec3 param_12 = (pc - (ex * 0.92387950420379638671875)) - (ey * 0.3826834261417388916015625);\n    vec3 param_13 = _5803;\n    vec4 param_14 = m;\n    vec3 param_15 = _5763;\n    vec3 param_16 = _5803;\n    vec3 param_17 = (pc + (ex * 0.3826834261417388916015625)) - (ey * 0.92387950420379638671875);\n    vec3 param_18 = (pc + (ex * 0.92387950420379638671875)) - (ey * 0.3826834261417388916015625);\n    return abs((fa_ltc_quad(param_4, param_5, param_6, param_7, param_8) + fa_ltc_quad(param_9, param_10, param_11, param_12, param_13)) + fa_ltc_quad(param_14, param_15, param_16, param_17, param_18));\n}\n\nvec2 fa_ltc_uv(float roughness, float ndv)\n{\n    return ((vec2(clamp((roughness - 0.0500000007450580596923828125) * 1.0526316165924072265625, 0.0, 1.0), sqrt(clamp(1.0 - ndv, 0.0, 1.0))) * 63.0) + vec2(0.5)) * vec2(0.015625);\n}\n\nvec3 fa_area_shade(int li, vec3 world_pos, vec3 n, vec3 v, vec3 diffuse_color, vec3 f0, float f90, float roughness, float ndv, float window)\n{\n    int param = li;\n    int _5861 = fa_light_base(param);\n    int param_1 = _5861;\n    int param_2 = _5861 + 1;\n    int param_3 = _5861 + 2;\n    int param_4 = _5861 + 4;\n    vec4 _5883 = fa_light_texel(param_4);\n    int param_5 = _5861 + 5;\n    vec4 _5888 = fa_light_texel(param_5);\n    int param_6 = _5861 + 6;\n    vec4 _5893 = fa_light_texel(param_6);\n    float _5894 = _5893.w;\n    vec3 _5899 = fa_light_texel(param_1).xyz - world_pos;\n    bool _5901 = _5894 < 1.5;\n    bool _5908;\n    if (_5901)\n    {\n        _5908 = dot(normalize(fa_light_texel(param_3).xyz), _5899) >= 0.0;\n    }\n    else\n    {\n        _5908 = _5901;\n    }\n    if (_5908)\n    {\n        return vec3(0.0);\n    }\n    bool _5917 = (_5894 > 0.5) && _5901;\n    float _5921 = _5917 ? 1.0539000034332275390625 : 1.0;\n    vec3 _5924 = _5883.xyz;\n    float _5926 = _5883.w;\n    vec3 _5932 = _5888.xyz;\n    float _5934 = _5888.w;\n    vec3 up = _5932 * (_5934 * _5921);\n    float _5940;\n    if (_5917)\n    {\n        _5940 = (3.1415927410125732421875 * _5926) * _5926;\n    }\n    else\n    {\n        _5940 = (4.0 * _5926) * _5934;\n    }\n    if (_5894 > 1.5)\n    {\n        vec3 _5966 = cross(_5924, -_5899);\n        vec3 perp = _5966;\n        float _5970 = dot(_5966, _5966);\n        vec3 _5973;\n        if (_5970 > 1.0000000133514319600180897396058e-10)\n        {\n            _5973 = perp * inversesqrt(_5970);\n        }\n        else\n        {\n            _5973 = _5932;\n        }\n        perp = _5973;\n        up = _5973 * _5934;\n    }\n    float _5994 = max(_5940, 9.9999999747524270787835121154785e-07);\n    vec3 param_7 = n;\n    vec3 param_8 = v;\n    vec3 _6004 = fa_ltc_tangent(param_7, param_8);\n    vec3 param_9 = _6004;\n    vec3 param_10 = n;\n    vec3 param_11 = _5899;\n    vec3 _6012 = fa_ltc_local(param_9, param_10, param_11);\n    vec3 param_12 = _6004;\n    vec3 param_13 = n;\n    vec3 param_14 = _5924 * (_5926 * _5921);\n    vec3 _6020 = fa_ltc_local(param_12, param_13, param_14);\n    vec3 param_15 = _6004;\n    vec3 param_16 = n;\n    vec3 param_17 = up;\n    vec3 _6028 = fa_ltc_local(param_15, param_16, param_17);\n    vec4 param_18 = vec4(1.0, 0.0, 0.0, 1.0);\n    float param_19 = _5894;\n    vec3 param_20 = _6012;\n    vec3 param_21 = _6020;\n    vec3 param_22 = _6028;\n    float param_23 = roughness;\n    float param_24 = ndv;\n    vec2 _6047 = fa_ltc_uv(param_23, param_24) * 64.0;\n    vec2 param_25 = _6047;\n    vec2 param_26 = _6047 + vec2(64.0, 0.0);\n    vec4 _6057 = fa_atlas_fetch(param_26);\n    vec4 param_27 = fa_atlas_fetch(param_25);\n    float param_28 = _5894;\n    vec3 param_29 = _6012;\n    vec3 param_30 = _6020;\n    vec3 param_31 = _6028;\n    return (((diffuse_color * fa_area_form(param_18, param_19, param_20, param_21, param_22)) + (((f0 * _6057.x) + ((vec3(f90) - f0) * _6057.y)) * fa_area_form(param_27, param_28, param_29, param_30, param_31))) * fa_light_texel(param_2).xyz) * ((((3.1415927410125732421875 * dot(_5899, _5899)) + _5994) / _5994) * window);\n}\n\nvec3 fa_light_rgb(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 1;\n    return fa_light_texel(param_1).xyz;\n}\n\nfloat fa_d_charlie(float alpha, float ndh)\n{\n    float _4237 = 1.0 / alpha;\n    return ((2.0 + _4237) * pow(sqrt(max(1.0 - (ndh * ndh), 9.9999997473787516355514526367188e-05)), _4237)) * 0.15915493667125701904296875;\n}\n\nfloat fa_v_ashikhmin(float ndl, float ndv)\n{\n    return clamp(0.25 / max((ndl + ndv) - (ndl * ndv), 9.9999997473787516355514526367188e-05), 0.0, 1.0);\n}\n\nfloat fa_layers_coat(FaLayers L, vec3 l, vec3 h, float vdh)\n{\n    float _4272 = max(dot(L.nc, l), 0.0);\n    float _4278 = max(dot(L.nc, h), 0.0);\n    float _4287 = ((_4278 * _4278) * (L.coat_a2 - 1.0)) + 1.0;\n    return (((L.coat * (0.039999999105930328369140625 + (0.959999978542327880859375 * pow(clamp(1.0 - vdh, 0.0, 1.0), 5.0)))) * (((L.coat_a2 / ((3.1415927410125732421875 * _4287) * _4287)) * (0.5 / max(mix((2.0 * _4272) * L.coat_ndv, _4272 + L.coat_ndv, L.coat_alpha), 9.9999997473787516355514526367188e-05))) * 3.1415927410125732421875)) * step(9.9999997473787516355514526367188e-05, _4272)) * _4272;\n}\n\nvec3 fa_area_layers(FaLayers L, int li, vec3 world_pos, vec3 n, vec3 v, vec3 l, vec3 diffuse_color, vec3 f0, float roughness, float ndv, float window)\n{\n    int param = li;\n    vec3 param_1 = world_pos;\n    vec3 param_2 = n;\n    vec3 param_3 = v;\n    vec3 param_4 = diffuse_color;\n    vec3 param_5 = f0;\n    float param_6 = L.f90;\n    float param_7 = roughness;\n    float param_8 = ndv;\n    float param_9 = window;\n    float _6125;\n    if (L.sheen_on)\n    {\n        _6125 = L.sheen_scale;\n    }\n    else\n    {\n        _6125 = 1.0;\n    }\n    vec3 result = fa_area_shade(param, param_1, param_2, param_3, param_4, param_5, param_6, param_7, param_8, param_9) * (L.keep * _6125);\n    vec3 _6138 = normalize(l + v);\n    int param_10 = li;\n    vec3 _6149 = fa_light_rgb(param_10) * window;\n    if (L.sheen_on)\n    {\n        float _6158 = max(dot(n, l), 0.0);\n        float param_11 = L.sheen_alpha;\n        float param_12 = max(dot(n, _6138), 0.0);\n        float param_13 = _6158;\n        float param_14 = ndv;\n        result += ((L.sheen * _6149) * (((((fa_d_charlie(param_11, param_12) * fa_v_ashikhmin(param_13, param_14)) * 3.1415927410125732421875) * step(9.9999997473787516355514526367188e-05, _6158)) * _6158) * L.keep));\n    }\n    if (L.coat > 0.0)\n    {\n        FaLayers param_15 = L;\n        vec3 param_16 = l;\n        vec3 param_17 = _6138;\n        float param_18 = max(dot(v, _6138), 0.0);\n        result += (_6149 * fa_layers_coat(param_15, param_16, param_17, param_18));\n    }\n    return result;\n}\n\nfloat fa_d_ggx_aniso(float ndh, float tdh, float bdh, float at, float ab)\n{\n    float _4140 = tdh / at;\n    float _4144 = bdh / ab;\n    float _4156 = ((_4140 * _4140) + (_4144 * _4144)) + (ndh * ndh);\n    return 1.0 / ((((3.1415927410125732421875 * at) * ab) * _4156) * _4156);\n}\n\nfloat fa_lambda_ggx_aniso(float n, float t, float b, float at, float ab)\n{\n    return 0.5 * (sqrt(1.0 + (((((at * at) * t) * t) + (((ab * ab) * b) * b)) / max(n * n, 9.9999999392252902907785028219223e-09))) - 1.0);\n}\n\nfloat fa_v_ggx_aniso(float ndl, float ndv, float tdv, float bdv, float tdl, float bdl, float at, float ab)\n{\n    float param = ndv;\n    float param_1 = tdv;\n    float param_2 = bdv;\n    float param_3 = at;\n    float param_4 = ab;\n    float param_5 = ndl;\n    float param_6 = tdl;\n    float param_7 = bdl;\n    float param_8 = at;\n    float param_9 = ab;\n    return clamp(1.0 / ((4.0 * max(ndl * ndv, 9.9999997473787516355514526367188e-05)) * ((1.0 + fa_lambda_ggx_aniso(param, param_1, param_2, param_3, param_4)) + fa_lambda_ggx_aniso(param_5, param_6, param_7, param_8, param_9))), 0.0, 1.0);\n}\n\nvec3 fa_layers_light(FaLayers L, vec3 diffuse_color, vec3 f0, vec3 n, vec3 v, vec3 l, vec3 h, float ndl, float ndv, float ndh, float vdh, float alpha, float a2)\n{\n    float _4336 = step(9.9999997473787516355514526367188e-05, ndl);\n    float d_ggx;\n    float vis;\n    if (L.aniso != 0.0)\n    {\n        float param = ndh;\n        float param_1 = dot(L.t, h);\n        float param_2 = dot(L.b, h);\n        float param_3 = L.at;\n        float param_4 = L.ab;\n        d_ggx = fa_d_ggx_aniso(param, param_1, param_2, param_3, param_4);\n        float param_5 = ndl;\n        float param_6 = ndv;\n        float param_7 = dot(L.t, v);\n        float param_8 = dot(L.b, v);\n        float param_9 = dot(L.t, l);\n        float param_10 = dot(L.b, l);\n        float param_11 = L.at;\n        float param_12 = L.ab;\n        vis = fa_v_ggx_aniso(param_5, param_6, param_7, param_8, param_9, param_10, param_11, param_12);\n    }\n    else\n    {\n        float _4415 = ((ndh * ndh) * (a2 - 1.0)) + 1.0;\n        d_ggx = a2 / ((3.1415927410125732421875 * _4415) * _4415);\n        vis = 0.5 / max(mix((2.0 * ndl) * ndv, ndl + ndv, alpha), 9.9999997473787516355514526367188e-05);\n    }\n    vec3 base = diffuse_color + (((f0 + ((vec3(L.f90) - f0) * pow(clamp(1.0 - vdh, 0.0, 1.0), 5.0))) * ((d_ggx * vis) * 3.1415927410125732421875)) * _4336);\n    if (L.sheen_on)\n    {\n        float param_13 = L.sheen_alpha;\n        float param_14 = ndh;\n        float param_15 = ndl;\n        float param_16 = ndv;\n        base = (base * L.sheen_scale) + (L.sheen * (((fa_d_charlie(param_13, param_14) * fa_v_ashikhmin(param_15, param_16)) * 3.1415927410125732421875) * _4336));\n    }\n    vec3 result = base * (L.keep * ndl);\n    if (L.coat > 0.0)\n    {\n        FaLayers param_17 = L;\n        vec3 param_18 = l;\n        vec3 param_19 = h;\n        float param_20 = vdh;\n        result += vec3(fa_layers_coat(param_17, param_18, param_19, param_20));\n    }\n    return result;\n}\n\nvec2 fa_env_brdf(float rough, float ndv)\n{\n    vec4 _3546 = (vec4(-1.0, -0.0274999998509883880615234375, -0.572000026702880859375, 0.02199999988079071044921875) * rough) + vec4(1.0, 0.0425000004470348358154296875, 1.03999996185302734375, -0.039999999105930328369140625);\n    float _3549 = _3546.x;\n    return (vec2(-1.03999996185302734375, 1.03999996185302734375) * ((min(_3549 * _3549, exp2((-9.27999973297119140625) * ndv)) * _3549) + _3546.y)) + _3546.zw;\n}\n\nvec3 fa_environment(vec3 d, float rough)\n{\n    if (fa_mesh_fs_params[11].w > 0.5)\n    {\n        return textureLod(fa_env_tex_fa_env_smp, d, clamp(rough, 0.0, 1.0) * fa_mesh_fs_params[12].w).xyz;\n    }\n    float _3400 = rough * rough;\n    float _3430 = 0.60000002384185791015625 * _3400;\n    return mix(mix(fa_mesh_fs_params[12].xyz * 0.550000011920928955078125, mix(fa_mesh_fs_params[12].xyz, fa_mesh_fs_params[11].xyz, vec3(pow(clamp(d.y * (1.0 - (0.699999988079071044921875 * _3400)), 0.0, 1.0), 0.550000011920928955078125))), vec3(smoothstep((-0.0500000007450580596923828125) - _3430, 0.0500000007450580596923828125 + _3430, d.y))), ((fa_mesh_fs_params[11].xyz + fa_mesh_fs_params[12].xyz) * 0.5) * 0.800000011920928955078125, vec3(_3400 * 0.60000002384185791015625));\n}\n\nvec3 fa_layers_ibl(FaLayers L, vec3 n, vec3 v, vec3 f0, float roughness)\n{\n    vec3 rn = n;\n    if (L.aniso != 0.0)\n    {\n        vec3 _4023;\n        if (L.aniso >= 0.0)\n        {\n            _4023 = L.b;\n        }\n        else\n        {\n            _4023 = L.t;\n        }\n        rn = normalize(mix(n, cross(cross(_4023, v), _4023), vec3(abs(L.aniso))));\n    }\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05);\n    vec2 _4056 = fa_env_brdf(param, param_1);\n    vec3 param_2 = reflect(-v, rn);\n    float param_3 = roughness;\n    vec3 result = (fa_environment(param_2, param_3) * ((f0 * _4056.x) + (vec3(L.f90) * _4056.y))) * L.base_scale;\n    if (L.sheen_on)\n    {\n        vec3 param_4 = n;\n        float param_5 = L.sheen_rough;\n        result += ((L.sheen * (L.sheen_e * L.keep)) * fa_environment(param_4, param_5));\n    }\n    if (L.coat > 0.0)\n    {\n        float param_6 = L.coat_rough;\n        float param_7 = L.coat_ndv;\n        vec2 _4111 = fa_env_brdf(param_6, param_7);\n        vec3 param_8 = reflect(-v, L.nc);\n        float param_9 = L.coat_rough;\n        result += (fa_environment(param_8, param_9) * (L.coat * ((0.039999999105930328369140625 * _4111.x) + _4111.y)));\n    }\n    return result;\n}\n\nvec3 fa_sky_reflection(vec3 n, vec3 v, vec3 f0, float roughness)\n{\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05);\n    vec2 _3588 = fa_env_brdf(param, param_1);\n    vec3 param_2 = reflect(-v, n);\n    float param_3 = roughness;\n    return fa_environment(param_2, param_3) * ((f0 * _3588.x) + vec3(_3588.y));\n}\n\nvec2 fa_xm_size(int k)\n{\n    return max(floor(fa_mesh_fs_params[24].zw / vec2(exp2(float(k)))), vec2(1.0));\n}\n\nvec2 fa_xm_origin(int k)\n{\n    if (k == 0)\n    {\n        return vec2(0.0);\n    }\n    float y = 0.0;\n    for (int j = 1; j < k; j++)\n    {\n        int param = j;\n        y += fa_xm_size(param).y;\n    }\n    return vec2(fa_mesh_fs_params[24].z, y);\n}\n\nvec3 fa_xm_texel(vec2 size, vec2 origin, vec2 p)\n{\n    return texelFetch(fa_screen_tex_fa_shadow_smp, ivec2(origin + clamp(p, vec2(0.0), size - vec2(1.0))), 0).xyz;\n}\n\nvec3 fa_xm_level(int k, vec2 uv)\n{\n    int param = k;\n    vec2 _4813 = fa_xm_size(param);\n    int param_1 = k;\n    vec2 _4817 = fa_xm_origin(param_1);\n    vec2 _4823 = (uv * _4813) - vec2(0.5);\n    vec2 _4826 = fract(_4823);\n    vec2 _4829 = floor(_4823);\n    vec2 param_2 = _4813;\n    vec2 param_3 = _4817;\n    vec2 param_4 = _4829;\n    vec2 param_5 = _4813;\n    vec2 param_6 = _4817;\n    vec2 param_7 = _4829 + vec2(1.0, 0.0);\n    vec2 param_8 = _4813;\n    vec2 param_9 = _4817;\n    vec2 param_10 = _4829 + vec2(0.0, 1.0);\n    vec2 param_11 = _4813;\n    vec2 param_12 = _4817;\n    vec2 param_13 = _4829 + vec2(1.0);\n    vec3 _4871 = vec3(_4826.x);\n    return mix(mix(fa_xm_texel(param_2, param_3, param_4), fa_xm_texel(param_5, param_6, param_7), _4871), mix(fa_xm_texel(param_8, param_9, param_10), fa_xm_texel(param_11, param_12, param_13), _4871), vec3(_4826.y));\n}\n\nvec3 fa_xm_sample(vec2 uv, float lod)\n{\n    float _4890 = max(fa_mesh_fs_params[31].w - 1.0, 0.0);\n    float _4894 = clamp(lod, 0.0, _4890);\n    int _4898 = int(floor(_4894));\n    int param = _4898;\n    vec2 param_1 = uv;\n    vec3 c = fa_xm_level(param, param_1);\n    float _4908 = float(_4898);\n    float _4909 = _4894 - _4908;\n    bool _4911 = _4909 > 0.001000000047497451305389404296875;\n    bool _4918;\n    if (_4911)\n    {\n        _4918 = _4908 < _4890;\n    }\n    else\n    {\n        _4918 = _4911;\n    }\n    if (_4918)\n    {\n        int param_2 = _4898 + 1;\n        vec2 param_3 = uv;\n        c = mix(c, fa_xm_level(param_2, param_3), vec3(_4909));\n    }\n    return c;\n}\n\nvec3 fa_transmitted(Surface s, vec3 n, vec3 v, float roughness, vec3 f0, float f90, float keep, float tr, inout float blend)\n{\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05);\n    vec2 _4944 = fa_env_brdf(param, param_1);\n    vec3 through = ((vec3(1.0) - clamp((f0 * _4944.x) + (vec3(f90) * _4944.y), vec3(0.0), vec3(1.0))) * s.albedo) * (tr * keep);\n    float _4972 = max(s.thickness, 0.0);\n    bool _4977 = _4972 > 0.0;\n    if ((s.attenuation_distance > 0.0) && _4977)\n    {\n        through *= exp((-((-log(clamp(s.attenuation_color, vec3(9.9999997473787516355514526367188e-05), vec3(1.0)))) / vec3(s.attenuation_distance))) * _4972);\n    }\n    bool _5002 = fa_mesh_fs_params[30].w > 1.5;\n    bool _5009;\n    if (!_5002)\n    {\n        _5009 = fa_mesh_fs_params[30].w < 0.5;\n    }\n    else\n    {\n        _5009 = _5002;\n    }\n    if (_5009)\n    {\n        blend = clamp(dot(through, vec3(0.3333333432674407958984375)), 0.0, 0.980000019073486328125);\n        return vec3(0.0);\n    }\n    vec3 world = fa_world_pos;\n    if (_4977)\n    {\n        world += (refract(-v, n, 1.0 / max(s.ior, 1.0)) * _4972);\n    }\n    vec4 _5044 = vec4(world, 1.0);\n    float _5049 = dot(fa_mesh_fs_params[28], _5044);\n    vec2 uv = vec2(0.5);\n    if (_5049 > 9.9999997473787516355514526367188e-05)\n    {\n        vec2 _5067 = vec2(dot(fa_mesh_fs_params[26], _5044), dot(fa_mesh_fs_params[27], _5044)) / vec2(_5049);\n        float _5075;\n        if (fa_mesh_fs_params[24].y > 0.5)\n        {\n            _5075 = (_5067.y * 0.5) + 0.5;\n        }\n        else\n        {\n            _5075 = 0.5 - (_5067.y * 0.5);\n        }\n        uv = vec2((_5067.x * 0.5) + 0.5, _5075);\n    }\n    vec2 param_2 = clamp(uv, vec2(0.0), vec2(1.0));\n    float param_3 = (clamp(roughness, 0.0, 1.0) * clamp((2.0 * s.ior) - 2.0, 0.0, 1.0)) * max(fa_mesh_fs_params[31].w - 1.0, 0.0);\n    return through * fa_xm_sample(param_2, param_3);\n}\n\nvec3 fa_shadow_debug(vec3 color, vec3 world)\n{\n    if (fa_shadows[27].w < 0.5)\n    {\n        return color;\n    }\n    int _3194 = int(fa_shadows[25].x + 0.5);\n    float _3204 = dot(world - fa_shadows[27].xyz, fa_shadows[28].xyz);\n    vec3 tint = vec3(0.3499999940395355224609375);\n    bool _3209 = _3194 > 0;\n    bool _3218;\n    if (_3209)\n    {\n        int param = _3194 - 1;\n        _3218 = _3204 <= fa_shadow_split_at(param);\n    }\n    else\n    {\n        _3218 = _3209;\n    }\n    if (_3218)\n    {\n        tint = vec3(1.0, 0.1500000059604644775390625, 0.100000001490116119384765625);\n        bool _3224 = _3194 > 1;\n        bool _3231;\n        if (_3224)\n        {\n            _3231 = _3204 > fa_shadows[24].x;\n        }\n        else\n        {\n            _3231 = _3224;\n        }\n        if (_3231)\n        {\n            tint = vec3(0.100000001490116119384765625, 0.89999997615814208984375, 0.20000000298023223876953125);\n        }\n        bool _3237 = _3194 > 2;\n        bool _3244;\n        if (_3237)\n        {\n            _3244 = _3204 > fa_shadows[24].y;\n        }\n        else\n        {\n            _3244 = _3237;\n        }\n        if (_3244)\n        {\n            tint = vec3(0.1500000059604644775390625, 0.300000011920928955078125, 1.0);\n        }\n        bool _3250 = _3194 > 3;\n        bool _3257;\n        if (_3250)\n        {\n            _3257 = _3204 > fa_shadows[24].z;\n        }\n        else\n        {\n            _3257 = _3250;\n        }\n        if (_3257)\n        {\n            tint = vec3(1.0, 0.89999997615814208984375, 0.100000001490116119384765625);\n        }\n    }\n    return mix(color, tint, vec3(0.550000011920928955078125));\n}\n\nvoid main()\n{\n    fa_inst_load();\n    vec3 _7317 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _7317 = -_7317;\n    }\n    vec3 _6607 = normalize(fa_mesh_fs_params[0].xyz - fa_world_pos);\n    vec3 param = fa_world_pos;\n    fa_cluster_begin(param);\n    SurfaceInput param_1 = SurfaceInput(fa_world_pos, _7317, fa_world_tangent, fa_uv, fa_vertex_color, _6607, gl_FrontFacing);\n    Surface _6615 = fa_standard_surface(param_1);\n    vec3 _7348 = _6615.albedo;\n    float _7349 = _6615.alpha;\n    vec3 _7350 = _6615.normal;\n    float _7351 = _6615.metallic;\n    float _7352 = _6615.roughness;\n    float _7353 = _6615.occlusion;\n    vec3 _7354 = _6615.emission;\n    float _7355 = _6615.clearcoat;\n    float _7356 = _6615.clearcoat_roughness;\n    vec3 _7357 = _6615.sheen_color;\n    float _7358 = _6615.sheen_roughness;\n    float _7359 = _6615.anisotropy;\n    float _7360 = _6615.anisotropy_rotation;\n    float _7361 = _6615.specular;\n    float _7362 = _6615.ior;\n    vec3 _7363 = _6615.specular_color;\n    float _7364 = _6615.transmission;\n    float _7365 = _6615.thickness;\n    vec3 _7366 = _6615.attenuation_color;\n    float _7367 = _6615.attenuation_distance;\n    SurfaceInput param_2 = SurfaceInput(fa_world_pos, _7317, fa_world_tangent, fa_uv, fa_vertex_color, _6607, gl_FrontFacing);\n    Surface param_3 = _6615;\n    surface(param_2, param_3);\n    _7348 = param_3.albedo;\n    _7349 = param_3.alpha;\n    _7350 = param_3.normal;\n    _7351 = param_3.metallic;\n    _7352 = param_3.roughness;\n    _7353 = param_3.occlusion;\n    _7354 = param_3.emission;\n    _7355 = param_3.clearcoat;\n    _7356 = param_3.clearcoat_roughness;\n    _7357 = param_3.sheen_color;\n    _7358 = param_3.sheen_roughness;\n    _7359 = param_3.anisotropy;\n    _7360 = param_3.anisotropy_rotation;\n    _7361 = param_3.specular;\n    _7362 = param_3.ior;\n    _7363 = param_3.specular_color;\n    _7364 = param_3.transmission;\n    _7365 = param_3.thickness;\n    _7366 = param_3.attenuation_color;\n    _7367 = param_3.attenuation_distance;\n    vec3 param_4 = fa_world_pos;\n    vec3 param_5 = _7317;\n    vec3 param_6 = param_3.albedo;\n    vec3 param_7 = param_3.normal;\n    fa_apply_decals(param_4, param_5, param_6, param_7);\n    _7348 = param_6;\n    _7350 = param_7;\n    float fa_tr_blend = 0.0;\n    vec3 result;\n    if (fa_mesh_fs_params[3].w > 0.5)\n    {\n        result = _7348;\n    }\n    else\n    {\n        vec3 _6655 = normalize(_7350);\n        float _6662 = clamp(_7351, 0.0, 1.0);\n        float _6666 = clamp(_7352, 0.0500000007450580596923828125, 1.0);\n        float _6670 = _6666 * _6666;\n        float _6674 = _6670 * _6670;\n        float _6679 = max(dot(_6655, _6607), 9.9999997473787516355514526367188e-05);\n        float _6685 = 1.0 - _6662;\n        float _6686 = clamp(_7364, 0.0, 1.0) * _6685;\n        vec3 _6695 = (_7348 * _6685) * (1.0 - _6686);\n        vec3 _6702 = mix(vec3(0.039999999105930328369140625), _7348, vec3(_6662));\n        vec3 f0 = _6702;\n        SurfaceInput param_8 = SurfaceInput(fa_world_pos, _7317, fa_world_tangent, fa_uv, fa_vertex_color, _6607, gl_FrontFacing);\n        Surface param_9 = Surface(_7348, _7349, _7350, _7351, _7352, _7353, _7354, _7355, _7356, _7357, _7358, _7359, _7360, _7361, _7362, _7363, _7364, _7365, _7366, _7367);\n        vec3 param_10 = _6655;\n        vec3 param_11 = _6607;\n        float param_12 = _6662;\n        float param_13 = _6666;\n        vec3 param_14 = _6702;\n        FaLayers _6718 = fa_layers_setup(param_8, param_9, param_10, param_11, param_12, param_13, param_14);\n        f0 = param_14;\n        vec3 param_15 = _6655;\n        vec3 lit = (fa_indirect_diffuse(param_15) * _6695) * _7353;\n        if (_6718.on)\n        {\n            lit *= _6718.base_scale;\n        }\n        int _6740 = fa_cl_ndir + fa_cl_local;\n        for (int ln = 0; ln < _6740; ln++)\n        {\n            int param_16 = ln;\n            int _6753 = fa_cl_light(param_16);\n            bool _6756 = fa_lm.z > 0.5;\n            bool _6762;\n            if (_6756)\n            {\n                int param_17 = _6753;\n                _6762 = fa_light_baked(param_17);\n            }\n            else\n            {\n                _6762 = _6756;\n            }\n            if (_6762)\n            {\n                continue;\n            }\n            int param_18 = _6753;\n            vec3 param_19 = fa_world_pos;\n            vec3 param_20 = _7317;\n            LightSample _6774 = fa_light_shadowed(param_18, param_19, param_20);\n            float _6782 = max(dot(_6655, _6774.direction), 0.0);\n            float _6788 = _6774.attenuation * _6774.shadow;\n            vec3 _6793 = normalize(_6774.direction + _6607);\n            float _6798 = max(dot(_6655, _6793), 0.0);\n            float _6803 = max(dot(_6607, _6793), 0.0);\n            bool _6810;\n            if (fa_light_is_area)\n            {\n                _6810 = !_6718.on;\n            }\n            else\n            {\n                _6810 = fa_light_is_area;\n            }\n            if (_6810)\n            {\n                int param_21 = _6753;\n                vec3 param_22 = fa_world_pos;\n                vec3 param_23 = _6655;\n                vec3 param_24 = _6607;\n                vec3 param_25 = _6695;\n                vec3 param_26 = f0;\n                float param_27 = 1.0;\n                float param_28 = _6666;\n                float param_29 = _6679;\n                float param_30 = _6788;\n                lit += fa_area_shade(param_21, param_22, param_23, param_24, param_25, param_26, param_27, param_28, param_29, param_30);\n            }\n            else\n            {\n                if (fa_light_is_area)\n                {\n                    FaLayers param_31 = _6718;\n                    int param_32 = _6753;\n                    vec3 param_33 = fa_world_pos;\n                    vec3 param_34 = _6655;\n                    vec3 param_35 = _6607;\n                    vec3 param_36 = _6774.direction;\n                    vec3 param_37 = _6695;\n                    vec3 param_38 = f0;\n                    float param_39 = _6666;\n                    float param_40 = _6679;\n                    float param_41 = _6788;\n                    lit += fa_area_layers(param_31, param_32, param_33, param_34, param_35, param_36, param_37, param_38, param_39, param_40, param_41);\n                }\n                else\n                {\n                    if (_6718.on)\n                    {\n                        FaLayers param_42 = _6718;\n                        vec3 param_43 = _6695;\n                        vec3 param_44 = f0;\n                        vec3 param_45 = _6655;\n                        vec3 param_46 = _6607;\n                        vec3 param_47 = _6774.direction;\n                        vec3 param_48 = _6793;\n                        float param_49 = _6782;\n                        float param_50 = _6679;\n                        float param_51 = _6798;\n                        float param_52 = _6803;\n                        float param_53 = _6670;\n                        float param_54 = _6674;\n                        int param_55 = _6753;\n                        lit += (fa_layers_light(param_42, param_43, param_44, param_45, param_46, param_47, param_48, param_49, param_50, param_51, param_52, param_53, param_54) * ((fa_light_rgb(param_55) * fa_light_tint) * _6788));\n                    }\n                    else\n                    {\n                        float _6916 = ((_6798 * _6798) * (_6674 - 1.0)) + 1.0;\n                        int param_56 = _6753;\n                        lit += (((_6695 + (((f0 + ((vec3(1.0) - f0) * pow(1.0 - _6803, 5.0))) * (((_6674 / ((3.1415927410125732421875 * _6916) * _6916)) * (0.5 / max(mix((2.0 * _6782) * _6679, _6782 + _6679, _6670), 9.9999997473787516355514526367188e-05))) * 3.1415927410125732421875)) * step(9.9999997473787516355514526367188e-05, _6782))) * (fa_light_rgb(param_56) * fa_light_tint)) * (_6782 * _6788));\n                    }\n                }\n            }\n        }\n        if (_6718.on)\n        {\n            FaLayers param_57 = _6718;\n            vec3 param_58 = _6655;\n            vec3 param_59 = _6607;\n            vec3 param_60 = f0;\n            float param_61 = _6666;\n            lit += (fa_layers_ibl(param_57, param_58, param_59, param_60, param_61) * _7353);\n        }\n        else\n        {\n            vec3 param_62 = _6655;\n            vec3 param_63 = _6607;\n            vec3 param_64 = f0;\n            float param_65 = _6666;\n            lit += (fa_sky_reflection(param_62, param_63, param_64, param_65) * _7353);\n        }\n        if (_6686 > 0.0)\n        {\n            float _7014;\n            if (_6718.on)\n            {\n                _7014 = _6718.f90;\n            }\n            else\n            {\n                _7014 = 1.0;\n            }\n            float _7022;\n            if (_6718.on)\n            {\n                _7022 = _6718.base_scale;\n            }\n            else\n            {\n                _7022 = 1.0;\n            }\n            Surface param_66 = Surface(_7348, _7349, _7350, _7351, _7352, _7353, _7354, _7355, _7356, _7357, _7358, _7359, _7360, _7361, _7362, _7363, _7364, _7365, _7366, _7367);\n            vec3 param_67 = _6655;\n            vec3 param_68 = _6607;\n            float param_69 = _6666;\n            vec3 param_70 = f0;\n            float param_71 = _7014;\n            float param_72 = _7022;\n            float param_73 = _6686;\n            float param_74 = fa_tr_blend;\n            vec3 _7046 = fa_transmitted(param_66, param_67, param_68, param_69, param_70, param_71, param_72, param_73, param_74);\n            fa_tr_blend = param_74;\n            lit += _7046;\n        }\n        result = lit;\n    }\n    vec3 _7053 = result;\n    vec3 _7054 = _7053 + _7354;\n    result = _7054;\n    vec3 param_75 = _7054;\n    vec3 param_76 = fa_world_pos;\n    result = fa_shadow_debug(param_75, param_76);\n    bool _7063 = fa_mesh_fs_params[7].w > 0.0;\n    bool _7070;\n    if (!_7063)\n    {\n        _7070 = fa_mesh_fs_params[8].y > 0.0;\n    }\n    else\n    {\n        _7070 = _7063;\n    }\n    if (_7070)\n    {\n        vec3 _7079 = fa_world_pos - fa_mesh_fs_params[0].xyz;\n        float _7085 = dot(_7079, fa_mesh_fs_params[9].xyz);\n        bool _7089 = fa_mesh_fs_params[9].w > 0.5;\n        float _7090;\n        if (_7089)\n        {\n            _7090 = _7085;\n        }\n        else\n        {\n            _7090 = length(_7079);\n        }\n        float _7102 = _7090 - fa_mesh_fs_params[8].x;\n        if (_7102 > 0.0)\n        {\n            float _7111 = fa_mesh_fs_params[7].w * _7102;\n            float tau = _7111 * _7111;\n            if (fa_mesh_fs_params[8].y > 0.0)\n            {\n                float _7127;\n                if (_7089)\n                {\n                    _7127 = fa_world_pos.y - (fa_mesh_fs_params[9].y * _7085);\n                }\n                else\n                {\n                    _7127 = fa_mesh_fs_params[0].y;\n                }\n                float _7148 = mix(_7127, fa_world_pos.y, clamp(fa_mesh_fs_params[8].x / _7090, 0.0, 1.0));\n                float _7152 = fa_world_pos.y - _7148;\n                float _7157 = _7148 - fa_mesh_fs_params[8].z;\n                float _7162 = fa_world_pos.y - fa_mesh_fs_params[8].z;\n                bool _7165 = _7157 <= 0.0;\n                bool _7166 = !_7165;\n                bool _7172;\n                if (_7166)\n                {\n                    _7172 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _7172 = _7165;\n                }\n                float _7173;\n                if (_7172)\n                {\n                    _7173 = fa_mesh_fs_params[8].y;\n                }\n                else\n                {\n                    _7173 = fa_mesh_fs_params[8].y * exp(-min(fa_mesh_fs_params[8].w * _7157, 80.0));\n                }\n                bool _7200;\n                if (_7166)\n                {\n                    _7200 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _7200 = _7165;\n                }\n                float _7201;\n                if (_7200)\n                {\n                    _7201 = fa_mesh_fs_params[8].y * _7157;\n                }\n                else\n                {\n                    _7201 = (fa_mesh_fs_params[8].y * (1.0 - exp(-min(fa_mesh_fs_params[8].w * _7157, 80.0)))) / fa_mesh_fs_params[8].w;\n                }\n                bool _7226 = _7162 <= 0.0;\n                bool _7233;\n                if (!_7226)\n                {\n                    _7233 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _7233 = _7226;\n                }\n                float _7234;\n                if (_7233)\n                {\n                    _7234 = fa_mesh_fs_params[8].y * _7162;\n                }\n                else\n                {\n                    _7234 = (fa_mesh_fs_params[8].y * (1.0 - exp(-min(fa_mesh_fs_params[8].w * _7162, 80.0)))) / fa_mesh_fs_params[8].w;\n                }\n                float _7261;\n                if (abs(_7152) < 0.001000000047497451305389404296875)\n                {\n                    _7261 = _7173;\n                }\n                else\n                {\n                    _7261 = (_7234 - _7201) / _7152;\n                }\n                tau += (_7102 * max(_7261, 0.0));\n            }\n            result = mix(result, fa_mesh_fs_params[7].xyz, vec3(clamp(1.0 - exp(-clamp(tau, 0.0, 80.0)), 0.0, 1.0)));\n        }\n    }\n    if (fa_tr_blend > 0.0)\n    {\n        float _7297 = 1.0 - fa_tr_blend;\n        result /= vec3(_7297);\n        _7349 *= _7297;\n    }\n    fa_frag_color = vec4(result, _7349);\n}\n\n",
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
            "size": 512,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_591",
            "glsl_uniforms": [
              {
                "type": "vec4",
                "array_count": 32,
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
            "inst_name": "_2258",
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
      "vs": "#version 430\n\nstruct VertexData\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 color;\n    vec3 object_pos;\n};\n\nstruct points_item\n{\n    vec4 pos;\n    vec4 tint;\n};\n\nlayout(binding = 0, std430) readonly buffer fa_vs_points_buf\n{\n    points_item data[];\n} fa_vs_points;\n\nuniform vec4 fa_mesh_vs_params[11];\nuniform vec4 fa_inst_base[4];\nlayout(location = 0) out vec3 fa_world_pos;\nlayout(location = 1) out vec3 fa_world_normal;\nlayout(location = 2) out vec4 fa_world_tangent;\nlayout(location = 3) out vec2 fa_uv;\nlayout(location = 4) out vec4 fa_vertex_color;\nlayout(location = 5) out float fa_pre_depth;\nlayout(location = 6) out vec3 fa_pre_r0;\nlayout(location = 7) out vec3 fa_pre_r1;\nlayout(location = 8) out vec3 fa_pre_r2;\nlayout(location = 0) in vec3 fa_position;\nlayout(location = 1) in vec3 fa_normal;\nlayout(location = 3) in vec4 fa_tangent;\nlayout(location = 2) in vec2 fa_texcoord0;\nlayout(location = 4) in vec4 fa_color;\nlayout(location = 5) in vec4 fa_inst_m0;\nlayout(location = 6) in vec4 fa_inst_m1;\nlayout(location = 7) in vec4 fa_inst_m2;\nlayout(location = 8) in vec4 fa_inst_m3;\n\nvoid fa_inst_begin()\n{\n}\n\nVertexData fa_vertex_data(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    vec3 _109 = cross(model[1].xyz, model[2].xyz);\n    float _114 = (dot(model[0].xyz, _109) < 0.0) ? (-1.0) : 1.0;\n    return VertexData((model * vec4(position, 1.0)).xyz, (((_109 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _114, vec4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _114), texcoord0 * fa_mesh_vs_params[8].xy, color, position);\n}\n\nvoid vertex(inout VertexData v)\n{\n    if (fa_vs_points.data[gl_InstanceID].pos.w < 0.5)\n    {\n        v.world_pos = vec3(1000000000.0);\n        return;\n    }\n    v.world_pos += fa_vs_points.data[gl_InstanceID].pos.xyz;\n    v.color = fa_vs_points.data[gl_InstanceID].tint;\n}\n\nvoid fa_prepass_vertex(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    mat4 param = model;\n    vec3 param_1 = position;\n    vec3 param_2 = normal;\n    vec4 param_3 = tangent;\n    vec2 param_4 = texcoord0;\n    vec4 param_5 = color;\n    VertexData param_6 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    vertex(param_6);\n    mat4 _203 = mat4(fa_mesh_vs_params[4], fa_mesh_vs_params[5], fa_mesh_vs_params[6], fa_mesh_vs_params[7]);\n    vec4 _210 = vec4(param_6.world_pos, 1.0);\n    fa_world_pos = param_6.world_pos;\n    fa_world_normal = param_6.world_normal;\n    fa_world_tangent = param_6.world_tangent;\n    fa_uv = param_6.uv;\n    fa_vertex_color = param_6.color;\n    fa_pre_depth = -(_203 * _210).z;\n    fa_pre_r0 = vec3(_203[0].x, _203[1].x, _203[2].x);\n    fa_pre_r1 = vec3(_203[0].y, _203[1].y, _203[2].y);\n    fa_pre_r2 = vec3(_203[0].z, _203[1].z, _203[2].z);\n    gl_Position = mat4(fa_mesh_vs_params[0], fa_mesh_vs_params[1], fa_mesh_vs_params[2], fa_mesh_vs_params[3]) * _210;\n}\n\nvoid main()\n{\n    fa_inst_begin();\n    mat4 param = mat4(fa_inst_base[0], fa_inst_base[1], fa_inst_base[2], fa_inst_base[3]);\n    vec3 param_1 = fa_position;\n    vec3 param_2 = fa_normal;\n    vec4 param_3 = fa_tangent;\n    vec2 param_4 = fa_texcoord0;\n    vec4 param_5 = fa_color;\n    fa_prepass_vertex(param, param_1, param_2, param_3, param_4, param_5);\n}\n\n",
      "fs": "#version 430\n\nstruct SurfaceInput\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 vertex_color;\n    vec3 view_dir;\n    bool front_facing;\n};\n\nstruct Surface\n{\n    vec3 albedo;\n    float alpha;\n    vec3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    vec3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    vec3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    vec3 specular_color;\n    float transmission;\n    float thickness;\n    vec3 attenuation_color;\n    float attenuation_distance;\n};\n\nstruct points_item\n{\n    vec4 pos;\n    vec4 tint;\n};\n\nlayout(binding = 1, std430) readonly buffer fa_points_buf\n{\n    points_item data[];\n} points;\n\nuniform vec4 fa_mesh_fs_params[32];\nlayout(binding = 0) uniform sampler2D fa_tex_fa_smp;\nlayout(binding = 1) uniform sampler2D fa_normal_tex_fa_smp;\nlayout(binding = 2) uniform sampler2D fa_mr_tex_fa_smp;\nlayout(binding = 3) uniform sampler2D fa_occlusion_tex_fa_smp;\nlayout(binding = 4) uniform sampler2D fa_emissive_tex_fa_smp;\n\nlayout(location = 0) in vec3 fa_world_pos;\nlayout(location = 1) in vec3 fa_world_normal;\nlayout(location = 2) in vec4 fa_world_tangent;\nlayout(location = 3) in vec2 fa_uv;\nlayout(location = 4) in vec4 fa_vertex_color;\nlayout(location = 6) in vec3 fa_pre_r0;\nlayout(location = 7) in vec3 fa_pre_r1;\nlayout(location = 8) in vec3 fa_pre_r2;\nlayout(location = 0) out vec4 fa_frag_color;\nlayout(location = 5) in float fa_pre_depth;\n\nvoid fa_inst_load()\n{\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nvec3 fa_linear_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_tex_fix(inout vec3 c, float mode)\n{\n    if (mode > 1.5)\n    {\n        vec3 param = c;\n        vec3 _190 = fa_linear_to_srgb(param);\n        c = _190;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            vec3 param_1 = c;\n            vec3 _199 = fa_srgb_to_linear(param_1);\n            c = _199;\n        }\n    }\n    return c;\n}\n\nvec3 fa_tangent_normal(SurfaceInput i, vec3 m)\n{\n    vec3 _56;\n    if (i.front_facing)\n    {\n        _56 = i.world_normal;\n    }\n    else\n    {\n        _56 = -i.world_normal;\n    }\n    vec3 _81 = normalize(i.world_tangent.xyz - (_56 * dot(_56, i.world_tangent.xyz)));\n    vec3 _109 = normalize(((_81 * m.x) + ((cross(_56, _81) * i.world_tangent.w) * m.y)) + (_56 * m.z));\n    vec3 _112;\n    if (i.front_facing)\n    {\n        _112 = _109;\n    }\n    else\n    {\n        _112 = -_109;\n    }\n    return _112;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    vec4 base_t = texture(fa_tex_fa_smp, i.uv);\n    float param = fa_mesh_fs_params[6].w;\n    float param_1 = 1.0;\n    vec3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    vec3 _242 = fa_tex_fix(param_2, param_3);\n    vec4 _793 = base_t;\n    _793.x = _242.x;\n    _793.y = _242.y;\n    _793.z = _242.z;\n    base_t = _793;\n    vec4 _257 = (_793 * fa_mesh_fs_params[2]) * i.vertex_color;\n    vec3 _748 = i.world_normal;\n    if (fa_mesh_fs_params[6].z > 0.5)\n    {\n        float param_4 = fa_mesh_fs_params[6].w;\n        float param_5 = 16.0;\n        vec3 param_6 = texture(fa_normal_tex_fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        vec3 _290 = fa_tex_fix(param_6, param_7);\n        vec3 _294 = (_290 * 2.0) - vec3(1.0);\n        vec2 _299 = _294.xy * fa_mesh_fs_params[6].x;\n        vec3 _801 = _294;\n        _801.x = _299.x;\n        _801.y = _299.y;\n        SurfaceInput param_8 = i;\n        vec3 param_9 = _801;\n        _748 = fa_tangent_normal(param_8, param_9);\n    }\n    vec4 mrt = texture(fa_mr_tex_fa_smp, i.uv);\n    float param_10 = fa_mesh_fs_params[6].w;\n    float param_11 = 64.0;\n    vec3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    vec3 _328 = fa_tex_fix(param_12, param_13);\n    vec4 _804 = mrt;\n    _804.x = _328.x;\n    _804.y = _328.y;\n    _804.z = _328.z;\n    mrt = _804;\n    vec4 _358 = texture(fa_occlusion_tex_fa_smp, i.uv);\n    float param_14 = fa_mesh_fs_params[6].w;\n    float param_15 = 256.0;\n    vec3 param_16 = _358.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    vec3 _370 = fa_tex_fix(param_16, param_17);\n    float param_18 = fa_mesh_fs_params[6].w;\n    float param_19 = 4.0;\n    vec3 param_20 = texture(fa_emissive_tex_fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    vec3 _400 = fa_tex_fix(param_20, param_21);\n    float _753 = fa_mesh_fs_params[20].x;\n    float _754 = fa_mesh_fs_params[20].y;\n    float _757 = fa_mesh_fs_params[20].z;\n    float _756 = fa_mesh_fs_params[21].w;\n    float _759 = fa_mesh_fs_params[22].x;\n    if (fa_mesh_fs_params[22].z > 0.5)\n    {\n        if (mod(fa_mesh_fs_params[22].z, 2.0) > 0.5)\n        {\n            _753 *= _370.y;\n            _754 *= _370.z;\n            _756 *= _358.w;\n        }\n        if (fa_mesh_fs_params[22].z > 1.5)\n        {\n            _757 *= mrt.x;\n            _759 *= mrt.w;\n        }\n    }\n    return Surface(_257.xyz, _257.w, _748, clamp(fa_mesh_fs_params[5].x * _328.z, 0.0, 1.0), clamp(fa_mesh_fs_params[5].y * _328.y, 0.0500000007450580596923828125, 1.0), 1.0 + (fa_mesh_fs_params[6].y * (_370.x - 1.0)), fa_mesh_fs_params[3].xyz + (fa_mesh_fs_params[4].xyz * _400), _753, _754, fa_mesh_fs_params[21].xyz, _756, _757, fa_mesh_fs_params[20].w, _759, fa_mesh_fs_params[22].y, fa_mesh_fs_params[23].xyz, fa_mesh_fs_params[30].x, fa_mesh_fs_params[30].y, fa_mesh_fs_params[31].xyz, fa_mesh_fs_params[30].z);\n}\n\nvoid surface(SurfaceInput i, inout Surface s)\n{\n    s.emission += (i.vertex_color.xyz * points.data[0].tint.w);\n}\n\nvoid main()\n{\n    fa_inst_load();\n    vec3 _643 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _643 = -_643;\n    }\n    vec3 _553 = normalize(fa_mesh_fs_params[0].xyz - fa_world_pos);\n    SurfaceInput param = SurfaceInput(fa_world_pos, _643, fa_world_tangent, fa_uv, fa_vertex_color, _553, gl_FrontFacing);\n    SurfaceInput param_1 = SurfaceInput(fa_world_pos, _643, fa_world_tangent, fa_uv, fa_vertex_color, _553, gl_FrontFacing);\n    Surface param_2 = fa_standard_surface(param);\n    surface(param_1, param_2);\n    vec3 _568 = normalize(param_2.normal);\n    vec3 _583 = normalize(vec3(dot(fa_pre_r0, _568), dot(fa_pre_r1, _568), dot(fa_pre_r2, _568)));\n    float _595 = _583.z;\n    vec2 e = _583.xy / vec2((abs(_583.x) + abs(_583.y)) + abs(_595));\n    if (_595 < 0.0)\n    {\n        e = (vec2(1.0) - abs(e.yx)) * vec2((e.x >= 0.0) ? 1.0 : (-1.0), (e.y >= 0.0) ? 1.0 : (-1.0));\n    }\n    fa_frag_color = vec4(min(fa_pre_depth, 60000.0), e, 1.0);\n}\n\n",
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
            "size": 512,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_231",
            "glsl_uniforms": [
              {
                "type": "vec4",
                "array_count": 32,
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
      "fs": "#version 430\n\nstruct SurfaceInput\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 vertex_color;\n    vec3 view_dir;\n    bool front_facing;\n};\n\nstruct Surface\n{\n    vec3 albedo;\n    float alpha;\n    vec3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    vec3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    vec3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    vec3 specular_color;\n    float transmission;\n    float thickness;\n    vec3 attenuation_color;\n    float attenuation_distance;\n};\n\nstruct points_item\n{\n    vec4 pos;\n    vec4 tint;\n};\n\nlayout(binding = 1, std430) readonly buffer fa_points_buf\n{\n    points_item data[];\n} points;\n\nuniform vec4 fa_mesh_fs_params[32];\nlayout(binding = 0) uniform sampler2D fa_tex_fa_smp;\nlayout(binding = 1) uniform sampler2D fa_normal_tex_fa_smp;\nlayout(binding = 2) uniform sampler2D fa_mr_tex_fa_smp;\nlayout(binding = 3) uniform sampler2D fa_occlusion_tex_fa_smp;\nlayout(binding = 4) uniform sampler2D fa_emissive_tex_fa_smp;\n\nlayout(location = 0) in vec3 fa_world_pos;\nlayout(location = 1) in vec3 fa_world_normal;\nlayout(location = 2) in vec4 fa_world_tangent;\nlayout(location = 3) in vec2 fa_uv;\nlayout(location = 4) in vec4 fa_vertex_color;\nlayout(location = 6) in vec3 fa_pre_r0;\nlayout(location = 7) in vec3 fa_pre_r1;\nlayout(location = 8) in vec3 fa_pre_r2;\nlayout(location = 0) out vec4 fa_frag_color;\nlayout(location = 5) in float fa_pre_depth;\n\nvoid fa_inst_load()\n{\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nvec3 fa_linear_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_tex_fix(inout vec3 c, float mode)\n{\n    if (mode > 1.5)\n    {\n        vec3 param = c;\n        vec3 _190 = fa_linear_to_srgb(param);\n        c = _190;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            vec3 param_1 = c;\n            vec3 _199 = fa_srgb_to_linear(param_1);\n            c = _199;\n        }\n    }\n    return c;\n}\n\nvec3 fa_tangent_normal(SurfaceInput i, vec3 m)\n{\n    vec3 _56;\n    if (i.front_facing)\n    {\n        _56 = i.world_normal;\n    }\n    else\n    {\n        _56 = -i.world_normal;\n    }\n    vec3 _81 = normalize(i.world_tangent.xyz - (_56 * dot(_56, i.world_tangent.xyz)));\n    vec3 _109 = normalize(((_81 * m.x) + ((cross(_56, _81) * i.world_tangent.w) * m.y)) + (_56 * m.z));\n    vec3 _112;\n    if (i.front_facing)\n    {\n        _112 = _109;\n    }\n    else\n    {\n        _112 = -_109;\n    }\n    return _112;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    vec4 base_t = texture(fa_tex_fa_smp, i.uv);\n    float param = fa_mesh_fs_params[6].w;\n    float param_1 = 1.0;\n    vec3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    vec3 _242 = fa_tex_fix(param_2, param_3);\n    vec4 _793 = base_t;\n    _793.x = _242.x;\n    _793.y = _242.y;\n    _793.z = _242.z;\n    base_t = _793;\n    vec4 _257 = (_793 * fa_mesh_fs_params[2]) * i.vertex_color;\n    vec3 _748 = i.world_normal;\n    if (fa_mesh_fs_params[6].z > 0.5)\n    {\n        float param_4 = fa_mesh_fs_params[6].w;\n        float param_5 = 16.0;\n        vec3 param_6 = texture(fa_normal_tex_fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        vec3 _290 = fa_tex_fix(param_6, param_7);\n        vec3 _294 = (_290 * 2.0) - vec3(1.0);\n        vec2 _299 = _294.xy * fa_mesh_fs_params[6].x;\n        vec3 _801 = _294;\n        _801.x = _299.x;\n        _801.y = _299.y;\n        SurfaceInput param_8 = i;\n        vec3 param_9 = _801;\n        _748 = fa_tangent_normal(param_8, param_9);\n    }\n    vec4 mrt = texture(fa_mr_tex_fa_smp, i.uv);\n    float param_10 = fa_mesh_fs_params[6].w;\n    float param_11 = 64.0;\n    vec3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    vec3 _328 = fa_tex_fix(param_12, param_13);\n    vec4 _804 = mrt;\n    _804.x = _328.x;\n    _804.y = _328.y;\n    _804.z = _328.z;\n    mrt = _804;\n    vec4 _358 = texture(fa_occlusion_tex_fa_smp, i.uv);\n    float param_14 = fa_mesh_fs_params[6].w;\n    float param_15 = 256.0;\n    vec3 param_16 = _358.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    vec3 _370 = fa_tex_fix(param_16, param_17);\n    float param_18 = fa_mesh_fs_params[6].w;\n    float param_19 = 4.0;\n    vec3 param_20 = texture(fa_emissive_tex_fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    vec3 _400 = fa_tex_fix(param_20, param_21);\n    float _753 = fa_mesh_fs_params[20].x;\n    float _754 = fa_mesh_fs_params[20].y;\n    float _757 = fa_mesh_fs_params[20].z;\n    float _756 = fa_mesh_fs_params[21].w;\n    float _759 = fa_mesh_fs_params[22].x;\n    if (fa_mesh_fs_params[22].z > 0.5)\n    {\n        if (mod(fa_mesh_fs_params[22].z, 2.0) > 0.5)\n        {\n            _753 *= _370.y;\n            _754 *= _370.z;\n            _756 *= _358.w;\n        }\n        if (fa_mesh_fs_params[22].z > 1.5)\n        {\n            _757 *= mrt.x;\n            _759 *= mrt.w;\n        }\n    }\n    return Surface(_257.xyz, _257.w, _748, clamp(fa_mesh_fs_params[5].x * _328.z, 0.0, 1.0), clamp(fa_mesh_fs_params[5].y * _328.y, 0.0500000007450580596923828125, 1.0), 1.0 + (fa_mesh_fs_params[6].y * (_370.x - 1.0)), fa_mesh_fs_params[3].xyz + (fa_mesh_fs_params[4].xyz * _400), _753, _754, fa_mesh_fs_params[21].xyz, _756, _757, fa_mesh_fs_params[20].w, _759, fa_mesh_fs_params[22].y, fa_mesh_fs_params[23].xyz, fa_mesh_fs_params[30].x, fa_mesh_fs_params[30].y, fa_mesh_fs_params[31].xyz, fa_mesh_fs_params[30].z);\n}\n\nvoid surface(SurfaceInput i, inout Surface s)\n{\n    s.emission += (i.vertex_color.xyz * points.data[0].tint.w);\n}\n\nvoid main()\n{\n    fa_inst_load();\n    vec3 _643 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _643 = -_643;\n    }\n    vec3 _553 = normalize(fa_mesh_fs_params[0].xyz - fa_world_pos);\n    SurfaceInput param = SurfaceInput(fa_world_pos, _643, fa_world_tangent, fa_uv, fa_vertex_color, _553, gl_FrontFacing);\n    SurfaceInput param_1 = SurfaceInput(fa_world_pos, _643, fa_world_tangent, fa_uv, fa_vertex_color, _553, gl_FrontFacing);\n    Surface param_2 = fa_standard_surface(param);\n    surface(param_1, param_2);\n    vec3 _568 = normalize(param_2.normal);\n    vec3 _583 = normalize(vec3(dot(fa_pre_r0, _568), dot(fa_pre_r1, _568), dot(fa_pre_r2, _568)));\n    float _595 = _583.z;\n    vec2 e = _583.xy / vec2((abs(_583.x) + abs(_583.y)) + abs(_595));\n    if (_595 < 0.0)\n    {\n        e = (vec2(1.0) - abs(e.yx)) * vec2((e.x >= 0.0) ? 1.0 : (-1.0), (e.y >= 0.0) ? 1.0 : (-1.0));\n    }\n    fa_frag_color = vec4(min(fa_pre_depth, 60000.0), e, 1.0);\n}\n\n",
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
            "size": 512,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_231",
            "glsl_uniforms": [
              {
                "type": "vec4",
                "array_count": 32,
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
