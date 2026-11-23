{
  "format": "factoria.shader/1",
  "engine": "0.35.2",
  "template": "fa8167552b2b36a7f7f7aabbbfd121188850db007da21e603f0701c03f2dab1c",
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
      "fs": "#version 430\n\nstruct SurfaceInput\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 vertex_color;\n    vec3 view_dir;\n    bool front_facing;\n};\n\nstruct LightSample\n{\n    vec3 direction;\n    vec3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct Surface\n{\n    vec3 albedo;\n    float alpha;\n    vec3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    vec3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    vec3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    vec3 specular_color;\n    float transmission;\n    float thickness;\n    vec3 attenuation_color;\n    float attenuation_distance;\n};\n\nstruct FaLayers\n{\n    bool on;\n    float f90;\n    float keep;\n    float base_scale;\n    float coat;\n    float coat_rough;\n    float coat_alpha;\n    float coat_a2;\n    vec3 nc;\n    float coat_ndv;\n    bool sheen_on;\n    vec3 sheen;\n    float sheen_rough;\n    float sheen_alpha;\n    float sheen_scale;\n    float sheen_e;\n    float aniso;\n    vec3 t;\n    vec3 b;\n    float at;\n    float ab;\n};\n\nconst float _4355[63] = float[](1.0, 1.0, 1.0, 0.4790000021457672119140625, 0.11699999868869781494140625, 0.01200000010430812835693359375, 0.0, 0.0, 0.0, 1.0, 1.0, 1.0, 0.578000009059906005859375, 0.19300000369548797607421875, 0.0350000001490116119384765625, 0.0030000000260770320892333984375, 0.0, 0.0, 1.0, 1.0, 1.0, 0.6740000247955322265625, 0.3459999859333038330078125, 0.1319999992847442626953125, 0.032999999821186065673828125, 0.0040000001899898052215576171875, 0.0, 0.971000015735626220703125, 0.954999983310699462890625, 0.828999996185302734375, 0.63999998569488525390625, 0.42599999904632568359375, 0.24500000476837158203125, 0.115000002086162567138671875, 0.037000000476837158203125, 0.0030000000260770320892333984375, 0.7469999790191650390625, 0.737999975681304931640625, 0.670000016689300537109375, 0.563000023365020751953125, 0.4309999942779541015625, 0.3039999902248382568359375, 0.1940000057220458984375, 0.1019999980926513671875, 0.0309999994933605194091796875, 0.614000022411346435546875, 0.609000027179718017578125, 0.566999971866607666015625, 0.499000012874603271484375, 0.412000000476837158203125, 0.32400000095367431640625, 0.240999996662139892578125, 0.162000000476837158203125, 0.087999999523162841796875, 0.538999974727630615234375, 0.535000026226043701171875, 0.505999982357025146484375, 0.4569999873638153076171875, 0.393999993801116943359375, 0.328999996185302734375, 0.2660000026226043701171875, 0.203999996185302734375, 0.14200000464916229248046875);\n\nstruct points_item\n{\n    vec4 pos;\n    vec4 tint;\n};\n\nuniform vec4 fa_mesh_fs_params[53];\nuniform vec4 fa_shadows[30];\nlayout(binding = 1, std430) readonly buffer fa_points_buf\n{\n    points_item data[];\n} points;\n\nlayout(binding = 0) uniform sampler2D fa_light_tex_fa_shadow_smp;\nlayout(binding = 1) uniform sampler2D fa_tex_fa_smp;\nlayout(binding = 2) uniform sampler2D fa_normal_tex_fa_smp;\nlayout(binding = 3) uniform sampler2D fa_mr_tex_fa_smp;\nlayout(binding = 4) uniform sampler2D fa_occlusion_tex_fa_smp;\nlayout(binding = 5) uniform sampler2D fa_emissive_tex_fa_smp;\nlayout(binding = 6) uniform sampler2D fa_decal_tex_fa_env_smp;\nlayout(binding = 7) uniform sampler2D fa_lightmap_fa_env_smp;\nlayout(binding = 8) uniform sampler2D fa_probe_atlas_fa_env_smp;\nlayout(binding = 9) uniform sampler2D fa_light_atlas_fa_env_smp;\nlayout(binding = 10) uniform sampler2D fa_shadow_tex_fa_shadow_smp;\nlayout(binding = 11) uniform sampler2D fa_screen_tex_fa_shadow_smp;\n\nlayout(location = 0) in vec3 fa_world_pos;\nlayout(location = 5) in vec3 fa_lm;\nlayout(location = 1) in vec3 fa_world_normal;\nlayout(location = 2) in vec4 fa_world_tangent;\nlayout(location = 3) in vec2 fa_uv;\nlayout(location = 4) in vec4 fa_vertex_color;\nlayout(location = 0) out vec4 fa_frag_color;\nvec3 fa_light_tint;\nbool fa_light_is_area;\nint fa_cl_ndir;\nint fa_cl_slot;\nint fa_cl_local;\n\nvoid fa_inst_load()\n{\n}\n\nvec4 fa_light_texel(int t)\n{\n    return texelFetch(fa_light_tex_fa_shadow_smp, ivec2(t & 1023, t >> 10), 0);\n}\n\nvec4 fa_cluster_texel(vec3 world_pos)\n{\n    bool _1588 = fa_mesh_fs_params[19].x < 0.0;\n    bool _1595;\n    if (!_1588)\n    {\n        _1595 = fa_mesh_fs_params[19].w < 1.0;\n    }\n    else\n    {\n        _1595 = _1588;\n    }\n    bool _1603;\n    if (!_1595)\n    {\n        _1603 = fa_mesh_fs_params[18].x < 1.0;\n    }\n    else\n    {\n        _1603 = _1595;\n    }\n    bool _1610;\n    if (!_1603)\n    {\n        _1610 = fa_mesh_fs_params[18].y < 1.0;\n    }\n    else\n    {\n        _1610 = _1603;\n    }\n    bool _1617;\n    if (!_1610)\n    {\n        _1617 = fa_mesh_fs_params[19].y < 1.0;\n    }\n    else\n    {\n        _1617 = _1610;\n    }\n    if (_1617)\n    {\n        return vec4(0.0);\n    }\n    vec4 _1627 = vec4(world_pos, 1.0);\n    float _1633 = dot(fa_mesh_fs_params[16], _1627);\n    if (!(_1633 > 9.9999999747524270787835121154785e-07))\n    {\n        return vec4(0.0);\n    }\n    vec2 _1655 = vec2(dot(fa_mesh_fs_params[14], _1627), dot(fa_mesh_fs_params[15], _1627)) / vec2(_1633);\n    int _1659 = int(fa_mesh_fs_params[18].x);\n    int _1663 = int(fa_mesh_fs_params[18].y);\n    int param = (int(fa_mesh_fs_params[19].x) + (((clamp(int(floor(log2(max(dot(fa_mesh_fs_params[17].xyz, world_pos) + fa_mesh_fs_params[17].w, fa_mesh_fs_params[18].w) / fa_mesh_fs_params[18].w) * fa_mesh_fs_params[18].z)), 0, int(fa_mesh_fs_params[19].y) - 1) * _1663) + clamp(int(floor(((_1655.y * 0.5) + 0.5) * fa_mesh_fs_params[18].y)), 0, _1663 - 1)) * _1659)) + clamp(int(floor(((_1655.x * 0.5) + 0.5) * fa_mesh_fs_params[18].x)), 0, _1659 - 1);\n    return fa_light_texel(param);\n}\n\nivec2 fa_cluster_lookup(vec3 world_pos)\n{\n    vec3 param = world_pos;\n    vec4 _1739 = fa_cluster_texel(param);\n    return ivec2(int(_1739.x), int(_1739.y));\n}\n\nvoid fa_cluster_begin(vec3 world_pos)\n{\n    fa_cl_ndir = int(fa_mesh_fs_params[19].z);\n    vec3 param = world_pos;\n    ivec2 _5830 = fa_cluster_lookup(param);\n    fa_cl_slot = _5830.x;\n    fa_cl_local = _5830.y;\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nvec3 fa_linear_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_tex_fix(inout vec3 c, float mode)\n{\n    if (mode > 1.5)\n    {\n        vec3 param = c;\n        vec3 _7004 = fa_linear_to_srgb(param);\n        c = _7004;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            vec3 param_1 = c;\n            vec3 _7012 = fa_srgb_to_linear(param_1);\n            c = _7012;\n        }\n    }\n    return c;\n}\n\nvec3 fa_tangent_normal(SurfaceInput i, vec3 m)\n{\n    vec3 _532;\n    if (i.front_facing)\n    {\n        _532 = i.world_normal;\n    }\n    else\n    {\n        _532 = -i.world_normal;\n    }\n    vec3 _556 = normalize(i.world_tangent.xyz - (_532 * dot(_532, i.world_tangent.xyz)));\n    vec3 _583 = normalize(((_556 * m.x) + ((cross(_532, _556) * i.world_tangent.w) * m.y)) + (_532 * m.z));\n    vec3 _586;\n    if (i.front_facing)\n    {\n        _586 = _583;\n    }\n    else\n    {\n        _586 = -_583;\n    }\n    return _586;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    vec4 base_t = texture(fa_tex_fa_smp, i.uv);\n    float param = fa_mesh_fs_params[6].w;\n    float param_1 = 1.0;\n    vec3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    vec3 _7043 = fa_tex_fix(param_2, param_3);\n    vec4 _9305 = base_t;\n    _9305.x = _7043.x;\n    _9305.y = _7043.y;\n    _9305.z = _7043.z;\n    base_t = _9305;\n    vec4 _7057 = (_9305 * fa_mesh_fs_params[2]) * i.vertex_color;\n    vec3 _9081 = i.world_normal;\n    if (fa_mesh_fs_params[6].z > 0.5)\n    {\n        float param_4 = fa_mesh_fs_params[6].w;\n        float param_5 = 16.0;\n        vec3 param_6 = texture(fa_normal_tex_fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        vec3 _7089 = fa_tex_fix(param_6, param_7);\n        vec3 _7092 = (_7089 * 2.0) - vec3(1.0);\n        vec2 _7097 = _7092.xy * fa_mesh_fs_params[6].x;\n        vec3 _9313 = _7092;\n        _9313.x = _7097.x;\n        _9313.y = _7097.y;\n        SurfaceInput param_8 = i;\n        vec3 param_9 = _9313;\n        _9081 = fa_tangent_normal(param_8, param_9);\n    }\n    vec4 mrt = texture(fa_mr_tex_fa_smp, i.uv);\n    float param_10 = fa_mesh_fs_params[6].w;\n    float param_11 = 64.0;\n    vec3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    vec3 _7125 = fa_tex_fix(param_12, param_13);\n    vec4 _9316 = mrt;\n    _9316.x = _7125.x;\n    _9316.y = _7125.y;\n    _9316.z = _7125.z;\n    mrt = _9316;\n    vec4 _7153 = texture(fa_occlusion_tex_fa_smp, i.uv);\n    float param_14 = fa_mesh_fs_params[6].w;\n    float param_15 = 256.0;\n    vec3 param_16 = _7153.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    vec3 _7164 = fa_tex_fix(param_16, param_17);\n    float param_18 = fa_mesh_fs_params[6].w;\n    float param_19 = 4.0;\n    vec3 param_20 = texture(fa_emissive_tex_fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    vec3 _7194 = fa_tex_fix(param_20, param_21);\n    float _9086 = fa_mesh_fs_params[20].x;\n    float _9087 = fa_mesh_fs_params[20].y;\n    float _9090 = fa_mesh_fs_params[20].z;\n    float _9089 = fa_mesh_fs_params[21].w;\n    float _9092 = fa_mesh_fs_params[22].x;\n    if (fa_mesh_fs_params[22].z > 0.5)\n    {\n        if (mod(fa_mesh_fs_params[22].z, 2.0) > 0.5)\n        {\n            _9086 *= _7164.y;\n            _9087 *= _7164.z;\n            _9089 *= _7153.w;\n        }\n        if (fa_mesh_fs_params[22].z > 1.5)\n        {\n            _9090 *= mrt.x;\n            _9092 *= mrt.w;\n        }\n    }\n    return Surface(_7057.xyz, _7057.w, _9081, clamp(fa_mesh_fs_params[5].x * _7125.z, 0.0, 1.0), clamp(fa_mesh_fs_params[5].y * _7125.y, 0.0500000007450580596923828125, 1.0), 1.0 + (fa_mesh_fs_params[6].y * (_7164.x - 1.0)), fa_mesh_fs_params[3].xyz + (fa_mesh_fs_params[4].xyz * _7194), _9086, _9087, fa_mesh_fs_params[21].xyz, _9089, _9090, fa_mesh_fs_params[20].w, _9092, fa_mesh_fs_params[22].y, fa_mesh_fs_params[23].xyz, fa_mesh_fs_params[30].x, fa_mesh_fs_params[30].y, fa_mesh_fs_params[31].xyz, fa_mesh_fs_params[30].z);\n}\n\nvoid surface(SurfaceInput i, inout Surface s)\n{\n    s.emission += (i.vertex_color.xyz * points.data[0].tint.w);\n}\n\nvec4 fa_decal_tile(vec4 rect, vec2 uv, vec2 atlas, vec2 ddx, vec2 ddy)\n{\n    vec2 _1819 = rect.zw - rect.xy;\n    vec2 _1823 = _1819 * atlas;\n    vec2 _1827 = ddx * _1823;\n    vec2 _1831 = ddy * _1823;\n    return textureLod(fa_decal_tex_fa_env_smp, rect.xy + (clamp(uv, vec2(0.0), vec2(1.0)) * _1819), clamp(0.5 * log2(max(max(dot(_1827, _1827), dot(_1831, _1831)), 9.9999999392252902907785028219223e-09)), 0.0, 3.0));\n}\n\nvec3 fa_dc_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_dc_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvoid fa_apply_decals(vec3 world_pos, vec3 geo_normal, inout vec3 albedo, inout vec3 normal)\n{\n    bool _1864 = fa_mesh_fs_params[10].y < 0.5;\n    bool _1871;\n    if (!_1864)\n    {\n        _1871 = fa_mesh_fs_params[10].w < 0.5;\n    }\n    else\n    {\n        _1871 = _1864;\n    }\n    if (_1871)\n    {\n        return;\n    }\n    vec3 _1877 = dFdx(world_pos);\n    vec3 _1880 = dFdy(world_pos);\n    vec3 param = world_pos;\n    vec4 _1884 = fa_cluster_texel(param);\n    int _1888 = int(_1884.w);\n    if (_1888 < 1)\n    {\n        return;\n    }\n    int _1898 = int(fa_mesh_fs_params[10].y + 0.5);\n    int param_1 = _1898;\n    vec4 _1902 = fa_light_texel(param_1);\n    vec2 _1905 = _1902.yz;\n    int _1909 = int(_1902.w);\n    int param_2 = _1898 + 1;\n    vec4 _1914 = fa_light_texel(param_2);\n    float _1915 = _1914.x;\n    int _1921 = int(fa_mesh_fs_params[10].w + 0.5) - 1;\n    int _1925 = int(_1884.z);\n    vec3 _2190;\n    for (int k = 0; k < _1888; k++)\n    {\n        int _1938 = _1925 + k;\n        int param_3 = _1909 + (_1938 >> 2);\n        int _1955 = (_1898 + 2) + (int(fa_light_texel(param_3)[_1938 & 3]) * 7);\n        int param_4 = _1955 + 6;\n        vec4 _1960 = fa_light_texel(param_4);\n        if (((int(_1960.w + 0.5) >> _1921) & 1) == 0)\n        {\n            continue;\n        }\n        int param_5 = _1955;\n        vec4 _1975 = fa_light_texel(param_5);\n        int param_6 = _1955 + 1;\n        vec4 _1980 = fa_light_texel(param_6);\n        int param_7 = _1955 + 2;\n        vec4 _1985 = fa_light_texel(param_7);\n        vec3 _1988 = _1975.xyz;\n        float _1993 = dot(_1988, world_pos) + _1975.w;\n        vec3 _1995 = _1980.xyz;\n        float _2000 = dot(_1995, world_pos) + _1980.w;\n        vec3 _2002 = _1985.xyz;\n        float _2007 = dot(_2002, world_pos) + _1985.w;\n        bool _2012 = abs(_1993) > 0.5;\n        bool _2020;\n        if (!_2012)\n        {\n            _2020 = abs(_2000) > 0.5;\n        }\n        else\n        {\n            _2020 = _2012;\n        }\n        bool _2028;\n        if (!_2020)\n        {\n            _2028 = abs(_2007) > 0.5;\n        }\n        else\n        {\n            _2028 = _2020;\n        }\n        if (_2028)\n        {\n            continue;\n        }\n        float _2043 = clamp(dot(geo_normal, normalize(_2002)) * _1960.z, 0.0, 1.0);\n        if (_2043 <= 0.0)\n        {\n            continue;\n        }\n        float _2063 = (clamp((0.5 - abs(_2007)) * 10.0, 0.0, 1.0) * _2043) * _1960.x;\n        vec2 _2071 = vec2(_1993 + 0.5, 0.5 - _2000);\n        vec2 _2081 = vec2(dot(_1988, _1877), dot(_1995, _1877));\n        vec2 _2091 = vec2(dot(_1988, _1880), dot(_1995, _1880));\n        int param_8 = _1955 + 5;\n        vec4 _2096 = fa_light_texel(param_8);\n        int param_9 = _1955 + 3;\n        vec4 _2101 = fa_light_texel(param_9);\n        int param_10 = _1955 + 4;\n        vec4 _2106 = fa_light_texel(param_10);\n        float tex_a = 1.0;\n        vec3 col = _2096.xyz;\n        bool _2116 = _2101.z > _2101.x;\n        if (_2116)\n        {\n            vec4 param_11 = _2101;\n            vec2 param_12 = _2071;\n            vec2 param_13 = _1905;\n            vec2 param_14 = _2081;\n            vec2 param_15 = _2091;\n            vec4 tx = fa_decal_tile(param_11, param_12, param_13, param_14, param_15);\n            if ((_1915 > 0.5) && (_1915 < 1.5))\n            {\n                vec3 param_16 = tx.xyz;\n                vec3 _2142 = fa_dc_to_linear(param_16);\n                vec4 _9169 = tx;\n                _9169.x = _2142.x;\n                _9169.y = _2142.y;\n                _9169.z = _2142.z;\n                tx = _9169;\n            }\n            col *= tx.xyz;\n            tex_a = tx.w;\n        }\n        albedo = mix(albedo, col, vec3(clamp((_2063 * tex_a) * _2096.w, 0.0, 1.0)));\n        if (_2106.z > _2106.x)\n        {\n            vec4 param_17 = _2106;\n            vec2 param_18 = _2071;\n            vec2 param_19 = _1905;\n            vec2 param_20 = _2081;\n            vec2 param_21 = _2091;\n            vec4 _2186 = fa_decal_tile(param_17, param_18, param_19, param_20, param_21);\n            if (_1915 > 1.5)\n            {\n                vec3 param_22 = _2186.xyz;\n                vec3 _2196 = fa_dc_to_srgb(param_22);\n                _2190 = _2196;\n            }\n            else\n            {\n                _2190 = _2186.xyz;\n            }\n            vec3 _2205 = (_2190 * 2.0) - vec3(1.0);\n            vec2 _2210 = _2205.xy * _1960.y;\n            vec3 _2232 = (normalize(_1988) * _2210.x) + (normalize(_1995) * _2210.y);\n            vec3 _2235 = normalize(normal);\n            normal = normalize(mix(_2235, normalize((_2235 * max(_2205.z, 0.0500000007450580596923828125)) + (_2232 - (_2235 * dot(_2235, _2232)))), vec3(clamp(_2063 * (_2116 ? tex_a : 1.0), 0.0, 1.0))));\n        }\n    }\n}\n\nfloat fa_sheen_albedo(float ndv, float rough)\n{\n    float _4280 = min(sqrt(max(rough - 0.100000001490116119384765625, 0.0) * 1.111111164093017578125) * 6.0, 5.999000072479248046875);\n    float _4288 = min(sqrt(clamp(ndv, 0.0, 1.0)) * 8.0, 7.999000072479248046875);\n    int _4291 = int(_4280);\n    int _4294 = int(_4288);\n    float _4304 = _4288 - float(_4294);\n    int _4359 = (_4291 * 9) + _4294;\n    int _4379 = ((_4291 + 1) * 9) + _4294;\n    return mix(mix(_4355[_4359], _4355[_4359 + 1], _4304), mix(_4355[_4379], _4355[_4379 + 1], _4304), _4280 - float(_4291));\n}\n\nFaLayers fa_layers_setup(SurfaceInput i, Surface s, vec3 n, vec3 v, float metallic, float roughness, inout vec3 f0)\n{\n    bool _9004 = false;\n    float _9005 = 1.0;\n    float _9006 = 1.0;\n    float _9007 = 1.0;\n    float _9008 = 0.0;\n    float _9009 = 0.0;\n    float _9010 = 0.0;\n    float _9011 = 0.0;\n    float _9013 = 1.0;\n    bool _9014 = false;\n    vec3 _9015 = vec3(0.0);\n    float _9016 = 1.0;\n    float _9017 = 1.0;\n    float _9018 = 1.0;\n    float _9019 = 0.0;\n    float _9020 = 0.0;\n    vec3 _9021 = vec3(1.0, 0.0, 0.0);\n    vec3 _9022 = vec3(0.0, 0.0, 1.0);\n    float _9023 = 1.0;\n    float _9024 = 1.0;\n    float _4430 = clamp(s.specular, 0.0, 1.0);\n    float _4434 = clamp(s.ior, 1.0, 3.0);\n    bool _4439 = (_4430 != 1.0) || (_4434 != 1.5);\n    bool _4448;\n    if (!_4439)\n    {\n        _4448 = any(notEqual(s.specular_color, vec3(1.0)));\n    }\n    else\n    {\n        _4448 = _4439;\n    }\n    if (_4448)\n    {\n        float _4456 = (_4434 - 1.0) / (_4434 + 1.0);\n        f0 = mix(min(vec3(_4456 * _4456) * max(s.specular_color, vec3(0.0)), vec3(1.0)) * _4430, s.albedo, vec3(metallic));\n        _9005 = mix(_4430, 1.0, metallic);\n        _9004 = true;\n    }\n    float _4483 = clamp(s.clearcoat, 0.0, 1.0);\n    if (_4483 > 0.0)\n    {\n        float _4491 = clamp(s.clearcoat_roughness, 0.0500000007450580596923828125, 1.0);\n        _9008 = _4483;\n        _9009 = _4491;\n        float _4498 = _4491 * _4491;\n        _9010 = _4498;\n        _9011 = _4498 * _4498;\n        float _4510 = max(dot(i.world_normal, v), 9.9999997473787516355514526367188e-05);\n        _9013 = _4510;\n        _9006 = 1.0 - (_4483 * (0.039999999105930328369140625 + (0.959999978542327880859375 * pow(clamp(1.0 - _4510, 0.0, 1.0), 5.0))));\n        _9004 = true;\n    }\n    vec3 _4529 = max(s.sheen_color, vec3(0.0));\n    float _4538 = max(_4529.x, max(_4529.y, _4529.z));\n    if (_4538 > 0.0)\n    {\n        float _4546 = clamp(s.sheen_roughness, 0.100000001490116119384765625, 1.0);\n        _9014 = true;\n        _9015 = _4529;\n        _9016 = _4546;\n        _9017 = _4546 * _4546;\n        float param = max(dot(n, v), 9.9999997473787516355514526367188e-05);\n        float param_1 = _4546;\n        float _4563 = fa_sheen_albedo(param, param_1);\n        _9019 = _4563;\n        _9018 = 1.0 - min(_4538 * _4563, 1.0);\n        _9004 = true;\n    }\n    _9007 = _9006 * _9018;\n    float _4582 = clamp(s.anisotropy, -1.0, 1.0);\n    if (_4582 != 0.0)\n    {\n        vec3 _4597 = i.world_tangent.xyz - (n * dot(n, i.world_tangent.xyz));\n        vec3 t = _4597;\n        if (dot(_4597, _4597) < 9.9999999392252902907785028219223e-09)\n        {\n            bvec3 _4609 = bvec3(abs(n.y) < 0.9900000095367431640625);\n            t = cross(vec3(_4609.x ? vec3(0.0, 1.0, 0.0).x : vec3(1.0, 0.0, 0.0).x, _4609.y ? vec3(0.0, 1.0, 0.0).y : vec3(1.0, 0.0, 0.0).y, _4609.z ? vec3(0.0, 1.0, 0.0).z : vec3(1.0, 0.0, 0.0).z), n);\n        }\n        vec3 _4613 = t;\n        vec3 _4614 = normalize(_4613);\n        t = _4614;\n        vec3 _4639 = normalize((_4614 * cos(s.anisotropy_rotation)) + ((cross(n, _4614) * ((i.world_tangent.w < 0.0) ? (-1.0) : 1.0)) * sin(s.anisotropy_rotation)));\n        _9021 = _4639;\n        _9022 = cross(n, _4639);\n        float _4649 = roughness * roughness;\n        float _4655 = mix(_4649, 1.0, _4582 * _4582);\n        bool _4657 = _4582 > 0.0;\n        _9023 = _4657 ? _4655 : _4649;\n        _9024 = _4657 ? _4649 : _4655;\n        _9020 = _4582;\n        _9004 = true;\n    }\n    return FaLayers(_9004, _9005, _9006, _9007, _9008, _9009, _9010, _9011, i.world_normal, _9013, _9014, _9015, _9016, _9017, _9018, _9019, _9020, _9021, _9022, _9023, _9024);\n}\n\nvec2 fa_atlas_size()\n{\n    return vec2(textureSize(fa_probe_atlas_fa_env_smp, 0));\n}\n\nvec3 fa_probe_sh_coef(vec2 origin, float res, int k)\n{\n    vec3 v = textureLod(fa_probe_atlas_fa_env_smp, (origin + vec2(float(k) + 0.5, res + 2.5)) / fa_atlas_size(), 0.0).xyz;\n    if (fa_mesh_fs_params[41].y > 0.5)\n    {\n        v = ((v * 255.0) - vec3(128.0)) * 0.03149606287479400634765625;\n    }\n    return v;\n}\n\nvec3 fa_sh_eval(vec3 c[9], vec3 n)\n{\n    vec3 _3448 = max((((c[0] * 0.2820948064327239990234375) + (((c[1] * (0.3257350027561187744140625 * n.y)) + (c[2] * (0.3257350027561187744140625 * n.z))) + (c[3] * (0.3257350027561187744140625 * n.x)))) + (((c[4] * ((0.2731371223926544189453125 * n.x) * n.y)) + (c[5] * ((0.2731371223926544189453125 * n.y) * n.z))) + (c[6] * (0.078847892582416534423828125 * (((3.0 * n.z) * n.z) - 1.0))))) + ((c[7] * ((0.2731371223926544189453125 * n.x) * n.z)) + (c[8] * (0.13656856119632720947265625 * ((n.x * n.x) - (n.y * n.y))))), vec3(0.0));\n    return _3448;\n}\n\nvec3 fa_ambient_light(vec3 n)\n{\n    float _4061 = (1.0 - fa_mesh_fs_params[42].w) - fa_mesh_fs_params[47].w;\n    vec3 amb = vec3(0.0);\n    bool _4066 = fa_mesh_fs_params[11].w > 0.5;\n    vec3 c[9];\n    for (int k = 0; k < 9; k++)\n    {\n        c[k] = vec3(0.0);\n    }\n    if (_4061 > 0.0005000000237487256526947021484375)\n    {\n        if (_4066)\n        {\n            for (int k_1 = 0; k_1 < 9; k_1++)\n            {\n                vec2 param = fa_mesh_fs_params[41].zw;\n                float param_1 = 128.0;\n                int param_2 = k_1;\n                c[k_1] = fa_probe_sh_coef(param, param_1, param_2) * _4061;\n            }\n        }\n        else\n        {\n            amb = fa_mesh_fs_params[1].xyz * _4061;\n        }\n    }\n    bool _4117 = fa_mesh_fs_params[42].w > 0.0;\n    if (_4117)\n    {\n        for (int k_2 = 0; k_2 < 9; k_2++)\n        {\n            vec2 param_3 = fa_mesh_fs_params[42].xy;\n            float param_4 = fa_mesh_fs_params[42].z;\n            int param_5 = k_2;\n            c[k_2] += (fa_probe_sh_coef(param_3, param_4, param_5) * fa_mesh_fs_params[42].w);\n        }\n    }\n    bool _4148 = fa_mesh_fs_params[47].w > 0.0;\n    if (_4148)\n    {\n        for (int k_3 = 0; k_3 < 9; k_3++)\n        {\n            vec2 param_6 = fa_mesh_fs_params[47].xy;\n            float param_7 = fa_mesh_fs_params[47].z;\n            int param_8 = k_3;\n            c[k_3] += (fa_probe_sh_coef(param_6, param_7, param_8) * fa_mesh_fs_params[47].w);\n        }\n    }\n    if ((_4066 || _4117) || _4148)\n    {\n        vec3 param_9[9] = c;\n        vec3 param_10 = n;\n        amb += fa_sh_eval(param_9, param_10);\n    }\n    return amb;\n}\n\nvec4 fa_gi_fetch(vec2 texel)\n{\n    return textureLod(fa_probe_atlas_fa_env_smp, texel / fa_atlas_size(), 0.0);\n}\n\nvec2 fa_oct_encode(vec3 d)\n{\n    vec3 _3468 = d / vec3(max((abs(d.x) + abs(d.y)) + abs(d.z), 9.9999999600419720025001879548654e-13));\n    float _3471 = _3468.x;\n    float _3473 = _3468.z;\n    vec2 e = vec2(_3471, _3473);\n    if (_3468.y < 0.0)\n    {\n        e = vec2((1.0 - abs(_3473)) * ((_3471 < 0.0) ? (-1.0) : 1.0), (1.0 - abs(_3471)) * ((_3473 < 0.0) ? (-1.0) : 1.0));\n    }\n    return e;\n}\n\nvec3 fa_gi_grid(int rec, vec3 n, vec3 v, out float cover)\n{\n    cover = 0.0;\n    int param = rec;\n    vec4 _7304 = fa_light_texel(param);\n    int param_1 = rec + 1;\n    vec4 _7309 = fa_light_texel(param_1);\n    int param_2 = rec + 2;\n    vec4 _7314 = fa_light_texel(param_2);\n    int param_3 = rec + 3;\n    vec4 _7319 = fa_light_texel(param_3);\n    bool _7322 = _7319.z < 0.5;\n    bool _7330;\n    if (!_7322)\n    {\n        _7330 = fa_atlas_size().y < 1155.0;\n    }\n    else\n    {\n        _7330 = _7322;\n    }\n    if (_7330)\n    {\n        return vec3(0.0);\n    }\n    float _7337 = max(_7304.w, 9.9999997473787516355514526367188e-05);\n    vec3 _7340 = _7309.xyz;\n    vec3 _7344 = _7304.xyz;\n    vec3 _7348 = (fa_world_pos - _7344) / vec3(_7337);\n    vec3 _7357 = min(_7348 + vec3(0.5), (_7340 - vec3(0.5)) - _7348);\n    float _7366 = min(_7357.x, min(_7357.y, _7357.z));\n    if (!(_7366 > 0.0))\n    {\n        return vec3(0.0);\n    }\n    vec3 _7381 = _7340 - vec3(1.0);\n    vec3 _7382 = clamp(_7348, vec3(0.0), _7381);\n    vec3 _7390 = min(floor(_7382), max(_7340 - vec3(2.0), vec3(0.0)));\n    vec3 _7394 = _7382 - _7390;\n    vec3 _7405 = fa_world_pos + (((n * 0.800000011920928955078125) + (v * 0.20000000298023223876953125)) * (0.20000000298023223876953125 * _7337));\n    int _7410 = int(_7314.y + 0.5);\n    float _7415 = 0.3257350027561187744140625 * n.y;\n    float _7419 = 0.3257350027561187744140625 * n.z;\n    float _7423 = 0.3257350027561187744140625 * n.x;\n    float _7430 = (0.2731371223926544189453125 * n.x) * n.y;\n    float _7437 = (0.2731371223926544189453125 * n.y) * n.z;\n    float _7446 = 0.078847892582416534423828125 * (((3.0 * n.z) * n.z) - 1.0);\n    float _7453 = (0.2731371223926544189453125 * n.x) * n.z;\n    float _7466 = 0.13656856119632720947265625 * ((n.x * n.x) - (n.y * n.y));\n    vec3 acc = vec3(0.0);\n    float wsum = 0.0;\n    int _7473 = 8 + int(_7319.w);\n    float _7500;\n    float _7513;\n    float _7527;\n    for (int k = 0; k < _7473; k++)\n    {\n        float _7486 = float(k & 1);\n        float _7490 = float((k >> 1) & 1);\n        float _7494 = float((k >> 2) & 1);\n        if (_7486 > 0.5)\n        {\n            _7500 = _7394.x;\n        }\n        else\n        {\n            _7500 = 1.0 - _7394.x;\n        }\n        if (_7490 > 0.5)\n        {\n            _7513 = _7394.y;\n        }\n        else\n        {\n            _7513 = 1.0 - _7394.y;\n        }\n        if (_7494 > 0.5)\n        {\n            _7527 = _7394.z;\n        }\n        else\n        {\n            _7527 = 1.0 - _7394.z;\n        }\n        float _7537 = (_7500 * _7513) * _7527;\n        if (!(_7537 > 0.0))\n        {\n            continue;\n        }\n        vec3 _7550 = min(_7390 + vec3(_7486, _7490, _7494), _7381);\n        int _7570 = int(((_7314.x + _7550.x) + (_7309.x * (_7550.y + (_7309.y * _7550.z)))) + 0.5);\n        vec2 _7585 = vec2(float(_7570 % _7410) * 10.0, 1024.0 + (float(_7570 / _7410) * 11.0));\n        vec2 param_4 = _7585 + vec2(9.5, 10.5);\n        vec4 _7593 = fa_gi_fetch(param_4);\n        bool _7596 = _7593.y < 0.5;\n        bool _7605;\n        if (!_7596)\n        {\n            _7605 = _7593.x > _7319.y;\n        }\n        else\n        {\n            _7605 = _7596;\n        }\n        if (_7605)\n        {\n            continue;\n        }\n        vec3 _7617 = _7405 - (_7344 + (_7550 * _7337));\n        float _7620 = length(_7617);\n        vec3 _7626 = _7617 / vec3(max(_7620, 9.9999997473787516355514526367188e-05));\n        float _7636 = max(9.9999997473787516355514526367188e-05, (dot(-_7626, n) + 1.0) * 0.5);\n        float w = _7537 * (_7636 * _7636);\n        vec3 param_5 = _7626;\n        vec2 param_6 = (_7585 + vec2(1.0)) + (((fa_oct_encode(param_5) * 0.5) + vec2(0.5)) * 8.0);\n        vec4 _7655 = fa_gi_fetch(param_6);\n        float _7662 = _7620 / max(_7314.z, 9.9999997473787516355514526367188e-05);\n        float _7665 = _7655.x;\n        if (_7662 > _7665)\n        {\n            float _7678 = max(_7655.y - (_7665 * _7665), 0.0);\n            float _7683 = _7662 - _7665;\n            float _7692 = _7678 / max(_7678 + (_7683 * _7683), 9.9999999600419720025001879548654e-13);\n            w *= ((_7692 * _7692) * _7692);\n        }\n        if (!(w > 0.0))\n        {\n            continue;\n        }\n        vec2 param_7 = _7585 + vec2(0.5, 10.5);\n        vec2 param_8 = _7585 + vec2(1.5, 10.5);\n        vec2 param_9 = _7585 + vec2(2.5, 10.5);\n        vec2 param_10 = _7585 + vec2(3.5, 10.5);\n        vec2 param_11 = _7585 + vec2(4.5, 10.5);\n        vec2 param_12 = _7585 + vec2(5.5, 10.5);\n        vec2 param_13 = _7585 + vec2(6.5, 10.5);\n        vec2 param_14 = _7585 + vec2(7.5, 10.5);\n        vec2 param_15 = _7585 + vec2(8.5, 10.5);\n        acc += ((((((((((fa_gi_fetch(param_7).xyz * 0.2820948064327239990234375) + (fa_gi_fetch(param_8).xyz * _7415)) + (fa_gi_fetch(param_9).xyz * _7419)) + (fa_gi_fetch(param_10).xyz * _7423)) + (fa_gi_fetch(param_11).xyz * _7430)) + (fa_gi_fetch(param_12).xyz * _7437)) + (fa_gi_fetch(param_13).xyz * _7446)) + (fa_gi_fetch(param_14).xyz * _7453)) + (fa_gi_fetch(param_15).xyz * _7466)) * w);\n        wsum += w;\n    }\n    if (!(wsum > 9.9999997473787516355514526367188e-06))\n    {\n        return vec3(0.0);\n    }\n    cover = smoothstep(0.0, 1.0, clamp(_7366 * 2.0, 0.0, 1.0)) * smoothstep(0.0, 0.0199999995529651641845703125, wsum);\n    float _7817;\n    if (fa_mesh_fs_params[52].z > 0.5)\n    {\n        _7817 = _7319.x;\n    }\n    else\n    {\n        _7817 = 1.0;\n    }\n    return max(acc / vec3(wsum), vec3(0.0)) * (_7314.w * _7817);\n}\n\nvec3 fa_gi_light(vec3 n, inout float left)\n{\n    left = 1.0;\n    vec3 acc = vec3(0.0);\n    vec3 _7841 = normalize(fa_mesh_fs_params[0].xyz - fa_world_pos);\n    int _7846 = int(fa_mesh_fs_params[52].x + 0.5);\n    int _7851 = int(fa_mesh_fs_params[52].y + 0.5);\n    float param_3;\n    for (int k = 0; (k < _7851) && (k < 8); k++)\n    {\n        int param = _7846 + (4 * k);\n        vec3 param_1 = n;\n        vec3 param_2 = _7841;\n        vec3 _7876 = fa_gi_grid(param, param_1, param_2, param_3);\n        float _7881 = param_3 * left;\n        acc += (_7876 * _7881);\n        left -= _7881;\n        if (left < 0.001000000047497451305389404296875)\n        {\n            left = 0.0;\n            break;\n        }\n    }\n    return acc;\n}\n\nvec3 fa_realtime_or_ambient(vec3 n)\n{\n    vec3 gi = vec3(0.0);\n    float left = 1.0;\n    if (fa_mesh_fs_params[52].y > 0.5)\n    {\n        vec3 param = n;\n        float param_1;\n        vec3 _7910 = fa_gi_light(param, param_1);\n        left = param_1;\n        gi = _7910;\n    }\n    if (left <= 0.0)\n    {\n        return gi;\n    }\n    vec3 param_2 = n;\n    return gi + (fa_ambient_light(param_2) * left);\n}\n\nvec3 fa_indirect_diffuse(vec3 n)\n{\n    if (fa_lm.z > 0.5)\n    {\n        return textureLod(fa_lightmap_fa_env_smp, fa_lm.xy, 0.0).xyz;\n    }\n    if (fa_mesh_fs_params[32].w > 0.0)\n    {\n        vec3 c[9];\n        for (int k = 0; k < 9; k++)\n        {\n            c[k] = fa_mesh_fs_params[k * 1 + 32].xyz;\n        }\n        vec3 param = n;\n        vec3 param_1[9] = c;\n        vec3 param_2 = n;\n        return mix(fa_ambient_light(param), fa_sh_eval(param_1, param_2), vec3(clamp(fa_mesh_fs_params[32].w, 0.0, 1.0)));\n    }\n    vec3 param_3 = n;\n    return fa_realtime_or_ambient(param_3);\n}\n\nint fa_cluster_index(int slot, int n)\n{\n    int param = (int(fa_mesh_fs_params[19].x) + int(fa_mesh_fs_params[19].w)) + ((slot + n) >> 2);\n    vec4 t = fa_light_texel(param);\n    return int(t[(slot + n) & 3]);\n}\n\nint fa_cl_light(int n)\n{\n    if (n < fa_cl_ndir)\n    {\n        return n;\n    }\n    int param = fa_cl_slot;\n    int param_1 = n - fa_cl_ndir;\n    return fa_cluster_index(param, param_1);\n}\n\nint fa_light_base(int li)\n{\n    return li * ((fa_mesh_fs_params[1].w > 4.5) ? 8 : 4);\n}\n\nbool fa_light_baked(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 3;\n    return fa_light_texel(param_1).w > 0.5;\n}\n\nfloat fa_baked_keep(int li)\n{\n    float _5800;\n    if (fa_lm.z > 0.5)\n    {\n        _5800 = 0.0;\n    }\n    else\n    {\n        _5800 = 1.0 - clamp(fa_mesh_fs_params[32].w, 0.0, 1.0);\n    }\n    bool _5811 = _5800 < 1.0;\n    bool _5817;\n    if (_5811)\n    {\n        int param = li;\n        _5817 = fa_light_baked(param);\n    }\n    else\n    {\n        _5817 = _5811;\n    }\n    return _5817 ? _5800 : 1.0;\n}\n\nfloat fa_light_type(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 1;\n    return fa_light_texel(param_1).w;\n}\n\nvec4 fa_atlas_fetch(vec2 texel)\n{\n    return textureLod(fa_light_atlas_fa_env_smp, texel / vec2(textureSize(fa_light_atlas_fa_env_smp, 0)), 0.0);\n}\n\nvec3 fa_cookie_sample(vec2 tile_origin, vec2 uv)\n{\n    vec2 param = (tile_origin + vec2(1.0)) + (clamp(uv, vec2(0.0), vec2(1.0)) * 254.0);\n    return fa_atlas_fetch(param).xyz;\n}\n\nvec3 fa_area_point(vec3 c, vec3 axis, vec3 ru, vec3 uu, float hx, float hy, float shape, vec3 p, vec3 r)\n{\n    bool _837 = dot(r, r) > 0.5;\n    if (shape > 1.5)\n    {\n        vec3 _850 = (c - (ru * hx)) - p;\n        vec3 _856 = ru * (2.0 * hx);\n        float _862 = max(dot(_856, _856), 9.9999999392252902907785028219223e-09);\n        float _866 = dot(_850, _856);\n        float t = clamp((-_866) / _862, 0.0, 1.0);\n        if (_837)\n        {\n            float _881 = dot(r, _856);\n            float _887 = _862 - (_881 * _881);\n            if (abs(_887) > (9.9999997473787516355514526367188e-06 * _862))\n            {\n                t = clamp(((dot(r, _850) * _881) - _866) / _887, 0.0, 1.0);\n            }\n        }\n        return (p + _850) + (_856 * t);\n    }\n    vec3 q = p;\n    float _919 = dot(r, axis);\n    bool _927;\n    if (_837)\n    {\n        _927 = abs(_919) > 9.9999997473787516355514526367188e-05;\n    }\n    else\n    {\n        _927 = _837;\n    }\n    if (_927)\n    {\n        float _937 = dot(c - p, axis) / _919;\n        if (_937 > 0.0)\n        {\n            q = p + (r * _937);\n        }\n    }\n    vec3 _950 = q - c;\n    vec2 xy = vec2(dot(_950, ru), dot(_950, uu));\n    if (shape > 0.5)\n    {\n        float _965 = length(xy);\n        if (_965 > hx)\n        {\n            xy *= (hx / _965);\n        }\n    }\n    else\n    {\n        xy = clamp(xy, vec2(-hx, -hy), vec2(hx, hy));\n    }\n    return (c + (ru * xy.x)) + (uu * xy.y);\n}\n\nint fa_cube_face(vec3 d)\n{\n    vec3 _598 = abs(d);\n    float _600 = _598.x;\n    float _602 = _598.y;\n    bool _603 = _600 >= _602;\n    bool _611;\n    if (_603)\n    {\n        _611 = _600 >= _598.z;\n    }\n    else\n    {\n        _611 = _603;\n    }\n    int _612;\n    if (_611)\n    {\n        _612 = (d.x > 0.0) ? 0 : 1;\n    }\n    else\n    {\n        int _627;\n        if (_602 >= _598.z)\n        {\n            _627 = (d.y > 0.0) ? 2 : 3;\n        }\n        else\n        {\n            _627 = (d.z > 0.0) ? 4 : 5;\n        }\n        _612 = _627;\n    }\n    return _612;\n}\n\nvoid fa_cube_face_basis(int f, out vec3 fwd, out vec3 up)\n{\n    if (f == 0)\n    {\n        fwd = vec3(1.0, 0.0, 0.0);\n        up = vec3(0.0, 1.0, 0.0);\n    }\n    else\n    {\n        if (f == 1)\n        {\n            fwd = vec3(-1.0, 0.0, 0.0);\n            up = vec3(0.0, 1.0, 0.0);\n        }\n        else\n        {\n            if (f == 2)\n            {\n                fwd = vec3(0.0, 1.0, 0.0);\n                up = vec3(0.0, 0.0, 1.0);\n            }\n            else\n            {\n                if (f == 3)\n                {\n                    fwd = vec3(0.0, -1.0, 0.0);\n                    up = vec3(0.0, 0.0, -1.0);\n                }\n                else\n                {\n                    if (f == 4)\n                    {\n                        fwd = vec3(0.0, 0.0, 1.0);\n                        up = vec3(0.0, 1.0, 0.0);\n                    }\n                    else\n                    {\n                        fwd = vec3(0.0, 0.0, -1.0);\n                        up = vec3(0.0, 1.0, 0.0);\n                    }\n                }\n            }\n        }\n    }\n}\n\nfloat fa_ies_sample(vec2 tile_origin, vec3 d, vec3 axis, vec3 right, vec3 up)\n{\n    float _757 = dot(d, right);\n    float _761 = dot(d, up);\n    float _772;\n    if (((_757 * _757) + (_761 * _761)) > 1.0000000133514319600180897396058e-10)\n    {\n        _772 = atan(_761, _757) * 0.15915493667125701904296875;\n    }\n    else\n    {\n        _772 = 0.0;\n    }\n    vec2 param = tile_origin + vec2(1.0 + ((_772 - floor(_772)) * 64.0), 1.0 + (acos(clamp(dot(d, axis), -1.0, 1.0)) * 10.18591594696044921875));\n    return fa_atlas_fetch(param).x;\n}\n\nLightSample fa_light_sample_n(int li, vec3 world_pos, vec3 n)\n{\n    int param = li;\n    int _1003 = fa_light_base(param);\n    bool _1007 = fa_mesh_fs_params[1].w > 4.5;\n    int param_1 = _1003;\n    vec4 _1011 = fa_light_texel(param_1);\n    int param_2 = _1003 + 1;\n    vec4 _1016 = fa_light_texel(param_2);\n    float _1019 = _1016.w;\n    float atten = 1.0;\n    float dist = 0.0;\n    fa_light_tint = vec3(1.0);\n    bool _1031 = _1007 && (_1019 > 2.5);\n    fa_light_is_area = _1031;\n    bool _1033 = _1019 < 0.5;\n    vec3 l;\n    if (_1033)\n    {\n        l = normalize(_1011.xyz);\n        if (_1007)\n        {\n            int param_3 = _1003 + 6;\n            vec4 _1047 = fa_light_texel(param_3);\n            if (_1047.z > 0.5)\n            {\n                int param_4 = _1003 + 4;\n                vec4 _1057 = fa_light_texel(param_4);\n                int param_5 = _1003 + 5;\n                vec4 _1062 = fa_light_texel(param_5);\n                vec2 param_6 = _1047.xy;\n                vec2 param_7 = fract(vec2(dot(world_pos, _1057.xyz) * _1057.w, (-dot(world_pos, _1062.xyz)) * _1062.w) + vec2(0.5));\n                fa_light_tint = fa_cookie_sample(param_6, param_7);\n            }\n        }\n    }\n    else\n    {\n        vec3 _1092 = _1011.xyz;\n        vec3 _1094 = _1092 - world_pos;\n        vec3 to_light = _1094;\n        float _1097 = length(_1094);\n        float reach = _1097;\n        bool front = true;\n        if (_1031)\n        {\n            int param_8 = _1003 + 7;\n            reach = max(_1097 - fa_light_texel(param_8).w, 0.0);\n            int param_9 = _1003 + 4;\n            vec4 _1121 = fa_light_texel(param_9);\n            int param_10 = _1003 + 5;\n            vec4 _1126 = fa_light_texel(param_10);\n            int param_11 = _1003 + 6;\n            vec4 _1131 = fa_light_texel(param_11);\n            float _1132 = _1131.w;\n            int param_12 = _1003 + 2;\n            vec3 _1139 = normalize(fa_light_texel(param_12).xyz);\n            bool _1141 = _1132 > 1.5;\n            bool _1149;\n            if (!_1141)\n            {\n                _1149 = dot(_1139, to_light) < 0.0;\n            }\n            else\n            {\n                _1149 = _1141;\n            }\n            front = _1149;\n            vec3 r = vec3(0.0);\n            vec3 _1158 = fa_mesh_fs_params[0].xyz - world_pos;\n            bool _1162 = dot(n, n) > 0.5;\n            bool _1170;\n            if (_1162)\n            {\n                _1170 = dot(_1158, _1158) > 9.9999999600419720025001879548654e-13;\n            }\n            else\n            {\n                _1170 = _1162;\n            }\n            if (_1170)\n            {\n                r = reflect(-normalize(_1158), normalize(n));\n            }\n            vec3 param_13 = _1092;\n            vec3 param_14 = _1139;\n            vec3 param_15 = _1121.xyz;\n            vec3 param_16 = _1126.xyz;\n            float param_17 = _1121.w;\n            float param_18 = _1126.w;\n            float param_19 = _1132;\n            vec3 param_20 = world_pos;\n            vec3 param_21 = r;\n            to_light = fa_area_point(param_13, param_14, param_15, param_16, param_17, param_18, param_19, param_20, param_21) - world_pos;\n        }\n        float _1206 = length(to_light);\n        dist = _1206;\n        l = to_light / vec3(max(_1206, 9.9999997473787516355514526367188e-05));\n        float _1220 = reach / max(_1011.w, 0.001000000047497451305389404296875);\n        float _1226 = clamp(1.0 - (_1220 * _1220), 0.0, 1.0);\n        float _1228;\n        if (front)\n        {\n            _1228 = _1226 * _1226;\n        }\n        else\n        {\n            _1228 = 0.0;\n        }\n        atten = _1228;\n        bool _1239 = _1019 < 2.5;\n        if ((_1019 > 1.5) && _1239)\n        {\n            int param_22 = _1003 + 2;\n            vec4 _1247 = fa_light_texel(param_22);\n            float _1257 = _1247.w;\n            int param_23 = _1003 + 3;\n            vec4 _1262 = fa_light_texel(param_23);\n            float _1263 = _1262.x;\n            float cos_inner = _1263;\n            if (_1263 > 1.5)\n            {\n                cos_inner = mix(_1257, 1.0, 0.25);\n            }\n            atten *= smoothstep(_1257, cos_inner, dot(-l, normalize(_1247.xyz)));\n        }\n        if (_1007 && (_1019 < 1.5))\n        {\n            int param_24 = _1003 + 6;\n            vec4 _1287 = fa_light_texel(param_24);\n            if (_1287.z > 0.5)\n            {\n                vec3 _1295 = -to_light;\n                int param_25 = _1003 + 4;\n                int param_26 = _1003 + 5;\n                vec3 _1309 = fa_light_texel(param_25).xyz;\n                vec3 _1313 = fa_light_texel(param_26).xyz;\n                vec3 _1322 = vec3(dot(_1295, _1309), dot(_1295, _1313), dot(_1295, cross(_1309, _1313)));\n                vec3 param_27 = _1322;\n                int _1326 = fa_cube_face(param_27);\n                int param_28 = _1326;\n                vec3 param_29;\n                vec3 param_30;\n                fa_cube_face_basis(param_28, param_29, param_30);\n                vec2 _1353 = vec2(dot(_1322, cross(param_29, param_30)), dot(_1322, param_30)) / vec2(max(dot(_1322, param_29), 9.9999997473787516355514526367188e-05));\n                int _1357 = _1326 / 3;\n                vec2 param_31 = _1287.xy + (vec2(float(_1326 - (_1357 * 3)), float(_1357)) * 256.0);\n                vec2 param_32 = vec2(0.5 + (0.5 * _1353.x), 0.5 - (0.5 * _1353.y));\n                fa_light_tint = fa_cookie_sample(param_31, param_32);\n            }\n            int param_33 = _1003 + 7;\n            vec4 _1387 = fa_light_texel(param_33);\n            if (_1387.z > 0.5)\n            {\n                int param_34 = _1003 + 2;\n                int param_35 = _1003 + 4;\n                int param_36 = _1003 + 5;\n                vec2 param_37 = _1387.xy;\n                vec3 param_38 = -l;\n                vec3 param_39 = normalize(fa_light_texel(param_34).xyz);\n                vec3 param_40 = fa_light_texel(param_35).xyz;\n                vec3 param_41 = fa_light_texel(param_36).xyz;\n                atten *= fa_ies_sample(param_37, param_38, param_39, param_40, param_41);\n            }\n        }\n        else\n        {\n            if (_1007 && _1239)\n            {\n                int param_42 = _1003 + 6;\n                vec4 _1434 = fa_light_texel(param_42);\n                int param_43 = _1003 + 7;\n                vec4 _1439 = fa_light_texel(param_43);\n                bool _1442 = _1434.z > 0.5;\n                bool _1449;\n                if (!_1442)\n                {\n                    _1449 = _1439.z > 0.5;\n                }\n                else\n                {\n                    _1449 = _1442;\n                }\n                if (_1449)\n                {\n                    int param_44 = _1003 + 2;\n                    vec4 _1456 = fa_light_texel(param_44);\n                    vec3 _1460 = normalize(_1456.xyz);\n                    int param_45 = _1003 + 4;\n                    vec4 _1465 = fa_light_texel(param_45);\n                    int param_46 = _1003 + 5;\n                    vec4 _1470 = fa_light_texel(param_46);\n                    if (_1442)\n                    {\n                        vec3 _1478 = -to_light;\n                        float _1485 = _1456.w;\n                        float _1501 = 0.5 / max(dot(_1478, _1460) * (sqrt(max(1.0 - (_1485 * _1485), 0.0)) / max(_1485, 0.001000000047497451305389404296875)), 9.9999997473787516355514526367188e-05);\n                        vec2 param_47 = _1434.xy;\n                        vec2 param_48 = vec2(0.5 + (dot(_1478, _1465.xyz) * _1501), 0.5 - (dot(_1478, _1470.xyz) * _1501));\n                        fa_light_tint = fa_cookie_sample(param_47, param_48);\n                    }\n                    if (_1439.z > 0.5)\n                    {\n                        vec2 param_49 = _1439.xy;\n                        vec3 param_50 = -l;\n                        vec3 param_51 = _1460;\n                        vec3 param_52 = _1465.xyz;\n                        vec3 param_53 = _1470.xyz;\n                        atten *= fa_ies_sample(param_49, param_50, param_51, param_52, param_53);\n                    }\n                }\n            }\n        }\n    }\n    vec3 _8992 = _1016.xyz * atten;\n    if (_1007)\n    {\n        _8992 *= fa_light_tint;\n    }\n    int _1570;\n    if (_1033)\n    {\n        _1570 = 0;\n    }\n    else\n    {\n        _1570 = ((_1019 > 1.5) && (_1019 < 2.5)) ? 2 : 1;\n    }\n    return LightSample(l, _8992, atten, 1.0, dist, _1570);\n}\n\nfloat fa_shadow_split_at(int i)\n{\n    float _2302;\n    if (i == 0)\n    {\n        _2302 = fa_shadows[24].x;\n    }\n    else\n    {\n        float _2318;\n        if (i == 1)\n        {\n            _2318 = fa_shadows[24].y;\n        }\n        else\n        {\n            float _2326;\n            if (i == 2)\n            {\n                _2326 = fa_shadows[24].z;\n            }\n            else\n            {\n                _2326 = fa_shadows[24].w;\n            }\n            _2318 = _2326;\n        }\n        _2302 = _2318;\n    }\n    return _2302;\n}\n\nfloat fa_shadow_depth(inout vec2 uv, vec4 rect)\n{\n    uv = clamp(uv, rect.xy, rect.zw);\n    return textureLod(fa_shadow_tex_fa_shadow_smp, uv, 0.0).x;\n}\n\nfloat fa_shadow_fetch(vec2 uv, vec4 rect, vec3 conv)\n{\n    vec2 param = uv;\n    vec4 param_1 = rect;\n    float _2359 = fa_shadow_depth(param, param_1);\n    float _2363;\n    if (conv.x < 0.5)\n    {\n        _2363 = _2359;\n    }\n    else\n    {\n        _2363 = (conv.y * conv.z) / (conv.z - (_2359 * (conv.z - conv.y)));\n    }\n    return _2363;\n}\n\nfloat fa_shadow_noise()\n{\n    return fract(52.98291778564453125 * fract(dot(gl_FragCoord.xy, vec2(0.067110560834407806396484375, 0.005837149918079376220703125))));\n}\n\nvec2 fa_shadow_vogel_turn(vec2 d)\n{\n    return vec2((d.x * (-0.737368881702423095703125)) - (d.y * 0.675490319728851318359375), (d.y * (-0.737368881702423095703125)) + (d.x * 0.675490319728851318359375));\n}\n\nfloat fa_shadow_filter(vec2 uv, vec4 rect, float zr, float texel_m, float unit, float reach, float plane, vec3 conv, int mode, float k)\n{\n    if (mode == 1)\n    {\n        vec2 param = uv;\n        vec4 param_1 = rect;\n        vec3 param_2 = conv;\n        return float(zr <= fa_shadow_fetch(param, param_1, param_2));\n    }\n    float _2409 = fa_shadow_noise() * 6.283185482025146484375;\n    vec2 _2415 = vec2(cos(_2409), sin(_2409));\n    vec2 dir = _2415;\n    float radius = 1.5;\n    if (mode == 2)\n    {\n        float _2424;\n        if (k < 0.0)\n        {\n            _2424 = (-k) / max(zr, 0.100000001490116119384765625);\n        }\n        else\n        {\n            _2424 = k;\n        }\n        float _2443 = clamp((_2424 * reach) / texel_m, 3.0, 12.0);\n        float sum = 0.0;\n        float cnt = 0.0;\n        for (int i = 0; i < 16; i++)\n        {\n            float _2462 = sqrt((float(i) + 0.5) * 0.0625) * _2443;\n            vec2 param_3 = uv + (dir * (fa_shadows[26].zw * _2462));\n            vec4 param_4 = rect;\n            vec3 param_5 = conv;\n            float _2476 = fa_shadow_fetch(param_3, param_4, param_5);\n            if (_2476 < (zr - (_2462 * plane)))\n            {\n                sum += _2476;\n                cnt += 1.0;\n            }\n            vec2 param_6 = dir;\n            dir = fa_shadow_vogel_turn(param_6);\n        }\n        if (cnt < 0.5)\n        {\n            return 1.0;\n        }\n        float _2504 = sum / cnt;\n        float _2514;\n        if (k < 0.0)\n        {\n            _2514 = (-k) / max(_2504, 0.0500000007450580596923828125);\n        }\n        else\n        {\n            _2514 = k;\n        }\n        radius = clamp(((max(zr - _2504, 0.0) * unit) * _2514) / texel_m, 1.5, 16.0);\n        dir = _2415;\n    }\n    float lit = 0.0;\n    int _2540 = (mode == 2) ? 24 : 16;\n    for (int i_1 = 0; i_1 < _2540; i_1++)\n    {\n        float _2559 = sqrt((float(i_1) + 0.5) / float(_2540)) * radius;\n        vec2 param_7 = uv + (dir * (fa_shadows[26].zw * _2559));\n        vec4 param_8 = rect;\n        vec3 param_9 = conv;\n        lit += float((zr - (_2559 * plane)) <= fa_shadow_fetch(param_7, param_8, param_9));\n        vec2 param_10 = dir;\n        dir = fa_shadow_vogel_turn(param_10);\n    }\n    return lit / float(_2540);\n}\n\nfloat fa_shadow_cascade(int ci, vec3 world, vec3 n, vec3 l)\n{\n    float _2605 = max(fa_shadows[ci * 1 + 20].y, 0.001000000047497451305389404296875);\n    float _2610 = clamp(dot(n, l), 0.0, 1.0);\n    float _2616 = sqrt(1.0 - (_2610 * _2610));\n    float _2624 = min(_2616 / max(_2610, 0.20000000298023223876953125), 4.0);\n    float _2629;\n    if (fa_shadows[26].y > 0.0)\n    {\n        _2629 = fa_shadows[26].y;\n    }\n    else\n    {\n        _2629 = 1.5 * fa_shadows[ci * 1 + 20].x;\n    }\n    vec4 _2654 = mat4(fa_shadows[ci * 4 + 0], fa_shadows[ci * 4 + 1], fa_shadows[ci * 4 + 2], fa_shadows[ci * 4 + 3]) * vec4(world + (n * (_2629 * _2616)), 1.0);\n    float _2661 = _2654.x;\n    bool _2664 = _2661 < fa_shadows[ci * 1 + 16].x;\n    bool _2673;\n    if (!_2664)\n    {\n        _2673 = _2661 > fa_shadows[ci * 1 + 16].z;\n    }\n    else\n    {\n        _2673 = _2664;\n    }\n    bool _2682;\n    if (!_2673)\n    {\n        _2682 = _2654.y < fa_shadows[ci * 1 + 16].y;\n    }\n    else\n    {\n        _2682 = _2673;\n    }\n    bool _2691;\n    if (!_2682)\n    {\n        _2691 = _2654.y > fa_shadows[ci * 1 + 16].w;\n    }\n    else\n    {\n        _2691 = _2682;\n    }\n    bool _2698;\n    if (!_2691)\n    {\n        _2698 = _2654.z > 1.0;\n    }\n    else\n    {\n        _2698 = _2691;\n    }\n    if (_2698)\n    {\n        return -1.0;\n    }\n    float _2706;\n    if (fa_shadows[26].x > 0.0)\n    {\n        _2706 = fa_shadows[26].x;\n    }\n    else\n    {\n        _2706 = 1.5 * fa_shadows[ci * 1 + 20].x;\n    }\n    vec2 param = _2654.xy;\n    vec4 param_1 = fa_shadows[ci * 1 + 16];\n    float param_2 = _2654.z - ((_2706 * (1.0 + (0.5 * _2624))) / _2605);\n    float param_3 = fa_shadows[ci * 1 + 20].x;\n    float param_4 = _2605;\n    float param_5 = _2605 * 0.25;\n    float param_6 = ((fa_shadows[ci * 1 + 20].x * min(_2624, 3.0)) * 0.5) / _2605;\n    vec3 param_7 = vec3(0.0);\n    int param_8 = int(fa_shadows[25].z + 0.5);\n    float param_9 = fa_shadows[25].w;\n    return fa_shadow_filter(param, param_1, param_2, param_3, param_4, param_5, param_6, param_7, param_8, param_9);\n}\n\nfloat fa_shadow_sun(vec3 world, vec3 n, vec3 l)\n{\n    if (fa_mesh_fs_params[5].z < 0.5)\n    {\n        return 1.0;\n    }\n    int _3084 = int(fa_shadows[25].x + 0.5);\n    if (_3084 < 1)\n    {\n        return 1.0;\n    }\n    float _3099 = dot(world - fa_shadows[27].xyz, fa_shadows[28].xyz);\n    int param = _3084 - 1;\n    if (_3099 > fa_shadow_split_at(param))\n    {\n        return 1.0;\n    }\n    int ci = 0;\n    bool _3111 = _3084 > 1;\n    bool _3118;\n    if (_3111)\n    {\n        _3118 = _3099 > fa_shadows[24].x;\n    }\n    else\n    {\n        _3118 = _3111;\n    }\n    if (_3118)\n    {\n        ci = 1;\n    }\n    bool _3122 = _3084 > 2;\n    bool _3129;\n    if (_3122)\n    {\n        _3129 = _3099 > fa_shadows[24].y;\n    }\n    else\n    {\n        _3129 = _3122;\n    }\n    if (_3129)\n    {\n        ci = 2;\n    }\n    bool _3133 = _3084 > 3;\n    bool _3140;\n    if (_3133)\n    {\n        _3140 = _3099 > fa_shadows[24].z;\n    }\n    else\n    {\n        _3140 = _3133;\n    }\n    if (_3140)\n    {\n        ci = 3;\n    }\n    float s = -1.0;\n    float s2 = -1.0;\n    float t = 0.0;\n    int _3151 = min(_3084, 4);\n    float _3192;\n    for (int c = ci; c < _3151; c++)\n    {\n        int param_1 = c;\n        vec3 param_2 = world;\n        vec3 param_3 = n;\n        vec3 param_4 = l;\n        float _3171 = fa_shadow_cascade(param_1, param_2, param_3, param_4);\n        if (s >= 0.0)\n        {\n            s2 = _3171;\n            break;\n        }\n        if (_3171 < 0.0)\n        {\n            continue;\n        }\n        s = _3171;\n        ci = c;\n        if (fa_shadows[25].y > 0.0)\n        {\n            if (ci > 0)\n            {\n                int param_5 = ci - 1;\n                _3192 = fa_shadow_split_at(param_5);\n            }\n            else\n            {\n                _3192 = fa_shadows[28].w;\n            }\n            int param_6 = ci;\n            float _3211 = fa_shadows[25].y * max(fa_shadow_split_at(param_6) - _3192, 9.9999997473787516355514526367188e-05);\n            int param_7 = ci;\n            t = clamp((_3099 - (fa_shadow_split_at(param_7) - _3211)) / _3211, 0.0, 1.0);\n        }\n        if (t <= 0.0)\n        {\n            break;\n        }\n    }\n    if (s < 0.0)\n    {\n        return 1.0;\n    }\n    if (t > 0.0)\n    {\n        float _3243;\n        if ((ci + 1) < _3084)\n        {\n            _3243 = (s2 < 0.0) ? s : s2;\n        }\n        else\n        {\n            _3243 = 1.0;\n        }\n        s = mix(s, _3243, t);\n    }\n    return s;\n}\n\nfloat fa_shadow_factor(vec3 n, vec3 l)\n{\n    vec3 param = fa_world_pos;\n    vec3 param_1 = n;\n    vec3 param_2 = l;\n    return fa_shadow_sun(param, param_1, param_2);\n}\n\nfloat fa_shadow_local(int li, vec3 lpos, vec3 world, vec3 n, vec3 l)\n{\n    bool _2764 = fa_mesh_fs_params[5].z < 0.5;\n    bool _2771;\n    if (!_2764)\n    {\n        _2771 = fa_shadows[29].x < 0.5;\n    }\n    else\n    {\n        _2771 = _2764;\n    }\n    if (_2771)\n    {\n        return 1.0;\n    }\n    int param = (int(fa_shadows[29].x + 0.5) - 1) + li;\n    vec4 _2784 = fa_light_texel(param);\n    float _2785 = _2784.x;\n    if (_2785 < 0.0)\n    {\n        return 1.0;\n    }\n    int _2794 = int(_2785 + 0.5);\n    int param_1 = _2794;\n    vec4 _2798 = fa_light_texel(param_1);\n    int param_2 = _2794 + 1;\n    vec4 _2803 = fa_light_texel(param_2);\n    float fade = 1.0;\n    float _2806 = _2798.y;\n    if (_2806 > 0.0)\n    {\n        float _2823 = 1.0 - smoothstep(0.75 * _2806, _2806, length(world - fa_shadows[27].xyz));\n        fade = _2823;\n        if (_2823 <= 0.0)\n        {\n            return 1.0;\n        }\n    }\n    int face = 0;\n    if (_2798.x > 1.5)\n    {\n        vec3 param_3 = world - lpos;\n        face = fa_cube_face(param_3);\n    }\n    int _2847 = (_2794 + 2) + (face * 6);\n    int param_4 = _2847;\n    int param_5 = _2847 + 1;\n    int param_6 = _2847 + 3;\n    vec4 _2861 = fa_light_texel(param_6);\n    int param_7 = _2847 + 4;\n    vec4 _2866 = fa_light_texel(param_7);\n    int param_8 = _2847 + 5;\n    vec4 _2871 = fa_light_texel(param_8);\n    float _2883 = _2871.x * max(dot(_2861, vec4(world, 1.0)), 0.001000000047497451305389404296875);\n    float _2888 = clamp(dot(n, l), 0.0, 1.0);\n    float _2911 = clamp(dot(n, _2861.xyz), -1.0, 1.0);\n    float _2930 = min(sqrt(1.0 - (_2911 * _2911)) / max(abs(dot(n, world - lpos)) / max(dot(_2861, vec4(world, 1.0)), 0.001000000047497451305389404296875), 0.20000000298023223876953125), 4.0);\n    float _2933 = _2803.y;\n    float _2935;\n    if (_2933 > 0.0)\n    {\n        _2935 = _2933;\n    }\n    else\n    {\n        _2935 = 1.5 * _2883;\n    }\n    vec4 _2955 = vec4(world + (n * (_2935 * sqrt(1.0 - (_2888 * _2888)))), 1.0);\n    float _2959 = dot(_2861, _2955);\n    float _2962 = _2871.y;\n    if (_2959 < _2962)\n    {\n        return 1.0;\n    }\n    vec2 _2977 = vec2(dot(fa_light_texel(param_4), _2955), dot(fa_light_texel(param_5), _2955)) / vec2(_2959);\n    float _2979 = _2977.x;\n    bool _2982 = _2979 < _2866.x;\n    bool _2991;\n    if (!_2982)\n    {\n        _2991 = _2979 > _2866.z;\n    }\n    else\n    {\n        _2991 = _2982;\n    }\n    bool _3000;\n    if (!_2991)\n    {\n        _3000 = _2977.y < _2866.y;\n    }\n    else\n    {\n        _3000 = _2991;\n    }\n    bool _3009;\n    if (!_3000)\n    {\n        _3009 = _2977.y > _2866.w;\n    }\n    else\n    {\n        _3009 = _3000;\n    }\n    if (_3009)\n    {\n        return 1.0;\n    }\n    float _3015 = _2803.x;\n    float _3017;\n    if (_3015 > 0.0)\n    {\n        _3017 = _3015;\n    }\n    else\n    {\n        _3017 = 1.5 * _2883;\n    }\n    vec2 param_9 = _2977;\n    vec4 param_10 = _2866;\n    float param_11 = _2959 - (_3017 * (1.0 + (0.5 * _2930)));\n    float param_12 = _2883;\n    float param_13 = 1.0;\n    float param_14 = _2871.z * 0.25;\n    float param_15 = (_2883 * min(_2930, 3.0)) * 0.5;\n    vec3 param_16 = vec3(1.0, _2962, _2871.z);\n    int param_17 = int(_2798.z + 0.5);\n    float param_18 = _2798.w;\n    return mix(1.0, fa_shadow_filter(param_9, param_10, param_11, param_12, param_13, param_14, param_15, param_16, param_17, param_18), fade);\n}\n\nfloat fa_contact_shadow(int li, vec3 world, vec3 gn, vec3 l, float dist)\n{\n    bool _5173 = fa_mesh_fs_params[24].x < 0.5;\n    bool _5180;\n    if (!_5173)\n    {\n        _5180 = fa_shadows[29].x < 0.5;\n    }\n    else\n    {\n        _5180 = _5173;\n    }\n    if (_5180)\n    {\n        return 1.0;\n    }\n    int param = (int(fa_shadows[29].x + 0.5) - 1) + li;\n    vec4 _5193 = fa_light_texel(param);\n    float _5194 = _5193.y;\n    float len = _5194;\n    if (_5194 <= 0.0)\n    {\n        return 1.0;\n    }\n    float _5206 = length(world - fa_mesh_fs_params[0].xyz);\n    float _5216 = 1.0 - smoothstep(0.5 * fa_mesh_fs_params[25].x, fa_mesh_fs_params[25].x, _5206);\n    if (_5216 <= 0.0)\n    {\n        return 1.0;\n    }\n    float _5222 = len;\n    float _5225 = min(_5222, 0.89999997615814208984375 * dist);\n    len = _5225;\n    float _5230 = 0.004999999888241291046142578125 + (0.0030000000260770320892333984375 * _5206);\n    float _5235 = _5230 + (0.5 * _5225);\n    vec3 _5241 = world + (gn * _5230);\n    float _5243 = fa_shadow_noise();\n    float occ = 0.0;\n    float _5307;\n    for (int k = 0; k < 12; k++)\n    {\n        float _5258 = (float(k) + _5243) * 0.083333335816860198974609375;\n        vec3 _5266 = _5241 + (l * (_5258 * len));\n        vec4 _5272 = vec4(_5266, 1.0);\n        float _5278 = dot(fa_mesh_fs_params[28], _5272);\n        if (_5278 < 9.9999997473787516355514526367188e-05)\n        {\n            break;\n        }\n        vec2 _5298 = vec2(dot(fa_mesh_fs_params[26], _5272), dot(fa_mesh_fs_params[27], _5272)) / vec2(_5278);\n        float _5302 = _5298.x * 0.5;\n        float _5303 = _5302 + 0.5;\n        if (fa_mesh_fs_params[24].y > 0.5)\n        {\n            _5307 = (_5298.y * 0.5) + 0.5;\n        }\n        else\n        {\n            _5307 = 0.5 - (_5298.y * 0.5);\n        }\n        bool _5323 = _5303 < 0.0;\n        bool _5330;\n        if (!_5323)\n        {\n            _5330 = _5303 >= 1.0;\n        }\n        else\n        {\n            _5330 = _5323;\n        }\n        bool _5337;\n        if (!_5330)\n        {\n            _5337 = _5307 < 0.0;\n        }\n        else\n        {\n            _5337 = _5330;\n        }\n        bool _5344;\n        if (!_5337)\n        {\n            _5344 = _5307 >= 1.0;\n        }\n        else\n        {\n            _5344 = _5337;\n        }\n        if (_5344)\n        {\n            break;\n        }\n        vec4 _5371 = texelFetch(fa_screen_tex_fa_shadow_smp, clamp(ivec2(vec2(_5303, _5307) * fa_mesh_fs_params[24].zw), ivec2(0), ivec2(fa_mesh_fs_params[24].zw) - ivec2(1)), 0);\n        if (_5371.w < 0.5)\n        {\n            continue;\n        }\n        float _5390 = (dot(fa_mesh_fs_params[29].xyz, _5266) + fa_mesh_fs_params[29].w) - _5371.x;\n        if ((_5390 > _5230) && (_5390 < _5235))\n        {\n            occ = max(occ, (1.0 - (_5258 * _5258)) * smoothstep(0.0, 0.0500000007450580596923828125, min(min(_5303, 0.5 - _5302), min(_5307, 1.0 - _5307))));\n        }\n    }\n    return 1.0 - (occ * _5216);\n}\n\nLightSample fa_light_shadowed(int li, vec3 world_pos, vec3 gn)\n{\n    int param = li;\n    float _5856 = fa_baked_keep(param);\n    if (_5856 <= 0.0)\n    {\n        int param_1 = li;\n        return LightSample(vec3(0.0, 1.0, 0.0), vec3(0.0), 0.0, 1.0, 0.0, int(fa_light_type(param_1) + 0.5));\n    }\n    int param_2 = li;\n    vec3 param_3 = world_pos;\n    vec3 param_4 = gn;\n    LightSample _5882 = fa_light_sample_n(param_2, param_3, param_4);\n    vec3 _9061 = _5882.color;\n    float _9062 = _5882.attenuation;\n    float _9063 = _5882.shadow;\n    bool _5885 = _5882.type == 0;\n    if (_5885 && (li == 0))\n    {\n        vec3 param_5 = gn;\n        vec3 param_6 = _5882.direction;\n        float _5896 = fa_shadow_factor(param_5, param_6);\n        _9063 = _5896;\n        _9061 *= _5896;\n    }\n    else\n    {\n        bool _5907 = _5882.type != 0;\n        bool _5913;\n        if (_5907)\n        {\n            _5913 = _9062 > 0.0;\n        }\n        else\n        {\n            _5913 = _5907;\n        }\n        if (_5913)\n        {\n            int param_7 = li;\n            int param_8 = fa_light_base(param_7);\n            int param_9 = li;\n            vec3 param_10 = fa_light_texel(param_8).xyz;\n            vec3 param_11 = world_pos;\n            vec3 param_12 = gn;\n            vec3 param_13 = _5882.direction;\n            float _5932 = fa_shadow_local(param_9, param_10, param_11, param_12, param_13);\n            _9063 = _5932;\n            _9061 *= _5932;\n        }\n    }\n    bool _5942 = fa_mesh_fs_params[24].x > 0.5;\n    bool _5948;\n    if (_5942)\n    {\n        _5948 = _9062 > 0.0;\n    }\n    else\n    {\n        _5948 = _5942;\n    }\n    if (_5948)\n    {\n        float _5955;\n        if (_5885)\n        {\n            _5955 = 1000000000.0;\n        }\n        else\n        {\n            _5955 = _5882._distance;\n        }\n        int param_14 = li;\n        vec3 param_15 = world_pos;\n        vec3 param_16 = gn;\n        vec3 param_17 = _5882.direction;\n        float param_18 = _5955;\n        float _5973 = fa_contact_shadow(param_14, param_15, param_16, param_17, param_18);\n        _9063 *= _5973;\n        _9061 *= _5973;\n    }\n    float _5986 = _9062;\n    float _5987 = _5986 * _5856;\n    _9062 = _5987;\n    vec3 _5991 = _9061;\n    vec3 _5992 = _5991 * _5856;\n    _9061 = _5992;\n    return LightSample(_5882.direction, _5992, _5987, _9063, _5882._distance, _5882.type);\n}\n\nvec3 fa_ltc_tangent(vec3 n, vec3 v)\n{\n    vec3 _6026 = v - (n * dot(v, n));\n    vec3 t = _6026;\n    float _6030 = dot(_6026, _6026);\n    float l2 = _6030;\n    if (_6030 < 1.0000000133514319600180897396058e-10)\n    {\n        vec3 _6040;\n        if (abs(n.z) < 0.999000012874603271484375)\n        {\n            _6040 = cross(n, vec3(0.0, 0.0, 1.0));\n        }\n        else\n        {\n            _6040 = cross(n, vec3(1.0, 0.0, 0.0));\n        }\n        t = _6040;\n        l2 = dot(_6040, _6040);\n    }\n    return t * inversesqrt(l2);\n}\n\nvec3 fa_ltc_local(vec3 t1, vec3 n, vec3 p)\n{\n    return vec3(dot(t1, p), dot(cross(n, t1), p), dot(n, p));\n}\n\nvec2 fa_ltc_uv(float roughness, float ndv)\n{\n    return ((vec2(clamp((roughness - 0.0500000007450580596923828125) * 1.0526316165924072265625, 0.0, 1.0), sqrt(clamp(1.0 - ndv, 0.0, 1.0))) * 63.0) + vec2(0.5)) * vec2(0.015625);\n}\n\nvec3 fa_oct_vertex(int j, vec3 pc, vec3 ex, vec3 ey)\n{\n    float _6427;\n    if ((j == 0) || (j == 7))\n    {\n        _6427 = 0.92387950420379638671875;\n    }\n    else\n    {\n        float _6437;\n        if ((j == 3) || (j == 4))\n        {\n            _6437 = -0.92387950420379638671875;\n        }\n        else\n        {\n            _6437 = ((j == 1) || (j == 6)) ? 0.3826834261417388916015625 : (-0.3826834261417388916015625);\n        }\n        _6427 = _6437;\n    }\n    float _6458;\n    if ((j == 1) || (j == 2))\n    {\n        _6458 = 0.92387950420379638671875;\n    }\n    else\n    {\n        float _6467;\n        if ((j == 5) || (j == 6))\n        {\n            _6467 = -0.92387950420379638671875;\n        }\n        else\n        {\n            _6467 = ((j == 0) || (j == 3)) ? 0.3826834261417388916015625 : (-0.3826834261417388916015625);\n        }\n        _6458 = _6467;\n    }\n    return (pc + (ex * _6427)) + (ey * _6458);\n}\n\nvec3 fa_ltc_edge_vector(vec3 a, vec3 b)\n{\n    float _6075 = dot(a, a);\n    float _6079 = dot(b, b);\n    if ((_6075 < 1.0000000195414813782625560981111e-24) || (_6079 < 1.0000000195414813782625560981111e-24))\n    {\n        return vec3(0.0);\n    }\n    vec3 _6093 = a * inversesqrt(_6075);\n    vec3 _6098 = b * inversesqrt(_6079);\n    float _6102 = dot(_6093, _6098);\n    float _6105 = abs(_6102);\n    float g = (((((((((((0.0416471660137176513671875 * _6105) - 0.1924748718738555908203125) * _6105) + 0.4179156124591827392578125) * _6105) - 0.616057217121124267578125) * _6105) + 0.777722418308258056640625) * _6105) - 0.999542415142059326171875) * _6105) + 1.570791721343994140625;\n    if (_6102 < 0.0)\n    {\n        g = (3.1415927410125732421875 * inversesqrt(max(1.0 - (_6102 * _6102), 1.0000000116860974230803549289703e-07))) - g;\n    }\n    return cross(_6093, _6098) * g;\n}\n\nvoid fa_ltc_clip_edge(vec3 a, vec3 b, inout vec3 sum, inout vec3 leave, inout vec3 enter, inout vec2 seen)\n{\n    bool _6162 = a.z > 0.0;\n    bool _6166 = b.z > 0.0;\n    if (_6162 && _6166)\n    {\n        vec3 param = a;\n        vec3 param_1 = b;\n        sum += fa_ltc_edge_vector(param, param_1);\n    }\n    else\n    {\n        if (_6162 != _6166)\n        {\n            vec3 _6201 = a + ((b - a) * (a.z / (a.z - b.z)));\n            _6201.z = 0.0;\n            if (_6162)\n            {\n                vec3 param_2 = a;\n                vec3 param_3 = _6201;\n                sum += fa_ltc_edge_vector(param_2, param_3);\n                leave = _6201;\n                seen.x = 1.0;\n            }\n            else\n            {\n                vec3 param_4 = _6201;\n                vec3 param_5 = b;\n                sum += fa_ltc_edge_vector(param_4, param_5);\n                enter = _6201;\n                seen.y = 1.0;\n            }\n        }\n    }\n}\n\nfloat fa_ltc_quad(vec4 abcd, vec3 p0, vec3 p1, vec3 p2, vec3 p3)\n{\n    vec3 _6250 = vec3((abcd.x * p0.x) + (abcd.y * p0.z), p0.y, (abcd.z * p0.x) + (abcd.w * p0.z));\n    vec3 _6276 = vec3((abcd.x * p1.x) + (abcd.y * p1.z), p1.y, (abcd.z * p1.x) + (abcd.w * p1.z));\n    vec3 _6302 = vec3((abcd.x * p2.x) + (abcd.y * p2.z), p2.y, (abcd.z * p2.x) + (abcd.w * p2.z));\n    vec3 _6328 = vec3((abcd.x * p3.x) + (abcd.y * p3.z), p3.y, (abcd.z * p3.x) + (abcd.w * p3.z));\n    vec3 sum = vec3(0.0);\n    vec3 leave = vec3(0.0);\n    vec3 enter = vec3(0.0);\n    vec3 param = _6250;\n    vec3 param_1 = _6276;\n    vec3 param_2 = vec3(0.0);\n    vec3 param_3 = vec3(0.0);\n    vec3 param_4 = vec3(0.0);\n    vec2 param_5 = vec2(0.0);\n    fa_ltc_clip_edge(param, param_1, param_2, param_3, param_4, param_5);\n    sum = param_2;\n    leave = param_3;\n    enter = param_4;\n    vec3 param_6 = _6276;\n    vec3 param_7 = _6302;\n    vec3 param_8 = param_2;\n    vec3 param_9 = param_3;\n    vec3 param_10 = param_4;\n    vec2 param_11 = param_5;\n    fa_ltc_clip_edge(param_6, param_7, param_8, param_9, param_10, param_11);\n    sum = param_8;\n    leave = param_9;\n    enter = param_10;\n    vec3 param_12 = _6302;\n    vec3 param_13 = _6328;\n    vec3 param_14 = param_8;\n    vec3 param_15 = param_9;\n    vec3 param_16 = param_10;\n    vec2 param_17 = param_11;\n    fa_ltc_clip_edge(param_12, param_13, param_14, param_15, param_16, param_17);\n    sum = param_14;\n    leave = param_15;\n    enter = param_16;\n    vec3 param_18 = _6328;\n    vec3 param_19 = _6250;\n    vec3 param_20 = param_14;\n    vec3 param_21 = param_15;\n    vec3 param_22 = param_16;\n    vec2 param_23 = param_17;\n    fa_ltc_clip_edge(param_18, param_19, param_20, param_21, param_22, param_23);\n    sum = param_20;\n    leave = param_21;\n    enter = param_22;\n    if ((param_23.x * param_23.y) > 0.5)\n    {\n        vec3 param_24 = leave;\n        vec3 param_25 = enter;\n        sum += fa_ltc_edge_vector(param_24, param_25);\n    }\n    return sum.z * 0.15915493667125701904296875;\n}\n\nvec2 fa_area_forms(vec4 m, float shape, vec3 pc, vec3 ex, vec3 ey)\n{\n    int _6496 = ((shape < 0.5) || (shape > 1.5)) ? 1 : 3;\n    vec2 sum = vec2(0.0);\n    int _6514;\n    for (int k = 0; k < (2 * _6496); k++)\n    {\n        bool _6511 = k >= _6496;\n        if (_6511)\n        {\n            _6514 = k - _6496;\n        }\n        else\n        {\n            _6514 = k;\n        }\n        vec3 p0 = (pc - ex) - ey;\n        vec3 p1 = (pc + ex) - ey;\n        vec3 p2 = (pc + ex) + ey;\n        vec3 p3 = (pc - ex) + ey;\n        if (_6496 == 3)\n        {\n            int param = 0;\n            vec3 param_1 = pc;\n            vec3 param_2 = ex;\n            vec3 param_3 = ey;\n            p0 = fa_oct_vertex(param, param_1, param_2, param_3);\n            int _6560 = 2 * _6514;\n            int param_4 = _6560 + 1;\n            vec3 param_5 = pc;\n            vec3 param_6 = ex;\n            vec3 param_7 = ey;\n            p1 = fa_oct_vertex(param_4, param_5, param_6, param_7);\n            int param_8 = _6560 + 2;\n            vec3 param_9 = pc;\n            vec3 param_10 = ex;\n            vec3 param_11 = ey;\n            p2 = fa_oct_vertex(param_8, param_9, param_10, param_11);\n            int param_12 = _6560 + 3;\n            vec3 param_13 = pc;\n            vec3 param_14 = ex;\n            vec3 param_15 = ey;\n            p3 = fa_oct_vertex(param_12, param_13, param_14, param_15);\n        }\n        bvec4 _6597 = bvec4(_6511);\n        vec4 param_16 = vec4(_6597.x ? m.x : vec4(1.0, 0.0, 0.0, 1.0).x, _6597.y ? m.y : vec4(1.0, 0.0, 0.0, 1.0).y, _6597.z ? m.z : vec4(1.0, 0.0, 0.0, 1.0).z, _6597.w ? m.w : vec4(1.0, 0.0, 0.0, 1.0).w);\n        vec3 param_17 = p0;\n        vec3 param_18 = p1;\n        vec3 param_19 = p2;\n        vec3 param_20 = p3;\n        float _6608 = fa_ltc_quad(param_16, param_17, param_18, param_19, param_20);\n        if (_6511)\n        {\n            vec2 _9288 = sum;\n            _9288.y = _9288.y + _6608;\n            sum = _9288;\n        }\n        else\n        {\n            vec2 _9291 = sum;\n            _9291.x = _9291.x + _6608;\n            sum = _9291;\n        }\n    }\n    return abs(sum);\n}\n\nvec3 fa_area_shade(int li, vec3 world_pos, vec3 n, vec3 v, vec3 diffuse_color, vec3 f0, float f90, float roughness, float ndv, float window)\n{\n    int param = li;\n    int _6632 = fa_light_base(param);\n    int param_1 = _6632;\n    int param_2 = _6632 + 1;\n    int param_3 = _6632 + 2;\n    int param_4 = _6632 + 4;\n    vec4 _6654 = fa_light_texel(param_4);\n    int param_5 = _6632 + 5;\n    vec4 _6659 = fa_light_texel(param_5);\n    int param_6 = _6632 + 6;\n    vec4 _6664 = fa_light_texel(param_6);\n    float _6665 = _6664.w;\n    vec3 _6670 = fa_light_texel(param_1).xyz - world_pos;\n    bool _6672 = _6665 < 1.5;\n    bool _6679;\n    if (_6672)\n    {\n        _6679 = dot(normalize(fa_light_texel(param_3).xyz), _6670) >= 0.0;\n    }\n    else\n    {\n        _6679 = _6672;\n    }\n    if (_6679)\n    {\n        return vec3(0.0);\n    }\n    bool _6688 = (_6665 > 0.5) && _6672;\n    float _6692 = _6688 ? 1.0539000034332275390625 : 1.0;\n    vec3 _6695 = _6654.xyz;\n    float _6697 = _6654.w;\n    vec3 _6703 = _6659.xyz;\n    float _6705 = _6659.w;\n    vec3 up = _6703 * (_6705 * _6692);\n    float _6711;\n    if (_6688)\n    {\n        _6711 = (3.1415927410125732421875 * _6697) * _6697;\n    }\n    else\n    {\n        _6711 = (4.0 * _6697) * _6705;\n    }\n    if (_6665 > 1.5)\n    {\n        vec3 _6737 = cross(_6695, -_6670);\n        vec3 perp = _6737;\n        float _6741 = dot(_6737, _6737);\n        vec3 _6744;\n        if (_6741 > 1.0000000133514319600180897396058e-10)\n        {\n            _6744 = perp * inversesqrt(_6741);\n        }\n        else\n        {\n            _6744 = _6703;\n        }\n        perp = _6744;\n        up = _6744 * _6705;\n    }\n    float _6765 = max(_6711, 9.9999999747524270787835121154785e-07);\n    vec3 param_7 = n;\n    vec3 param_8 = v;\n    vec3 _6775 = fa_ltc_tangent(param_7, param_8);\n    vec3 param_9 = _6775;\n    vec3 param_10 = n;\n    vec3 param_11 = _6670;\n    vec3 param_12 = _6775;\n    vec3 param_13 = n;\n    vec3 param_14 = _6695 * (_6697 * _6692);\n    vec3 param_15 = _6775;\n    vec3 param_16 = n;\n    vec3 param_17 = up;\n    float param_18 = roughness;\n    float param_19 = ndv;\n    vec2 _6806 = fa_ltc_uv(param_18, param_19) * 64.0;\n    vec2 param_20 = _6806;\n    vec2 param_21 = _6806 + vec2(64.0, 0.0);\n    vec4 _6816 = fa_atlas_fetch(param_21);\n    vec4 param_22 = fa_atlas_fetch(param_20);\n    float param_23 = _6665;\n    vec3 param_24 = fa_ltc_local(param_9, param_10, param_11);\n    vec3 param_25 = fa_ltc_local(param_12, param_13, param_14);\n    vec3 param_26 = fa_ltc_local(param_15, param_16, param_17);\n    vec2 _6828 = fa_area_forms(param_22, param_23, param_24, param_25, param_26);\n    return (((diffuse_color * _6828.x) + (((f0 * _6816.x) + ((vec3(f90) - f0) * _6816.y)) * _6828.y)) * fa_light_texel(param_2).xyz) * ((((3.1415927410125732421875 * dot(_6670, _6670)) + _6765) / _6765) * window);\n}\n\nvec3 fa_light_rgb(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 1;\n    return fa_light_texel(param_1).xyz;\n}\n\nfloat fa_d_charlie(float alpha, float ndh)\n{\n    float _4910 = 1.0 / alpha;\n    return ((2.0 + _4910) * pow(sqrt(max(1.0 - (ndh * ndh), 9.9999997473787516355514526367188e-05)), _4910)) * 0.15915493667125701904296875;\n}\n\nfloat fa_v_ashikhmin(float ndl, float ndv)\n{\n    return clamp(0.25 / max((ndl + ndv) - (ndl * ndv), 9.9999997473787516355514526367188e-05), 0.0, 1.0);\n}\n\nfloat fa_layers_coat(FaLayers L, vec3 l, vec3 h, float vdh)\n{\n    float _4945 = max(dot(L.nc, l), 0.0);\n    float _4951 = max(dot(L.nc, h), 0.0);\n    float _4960 = ((_4951 * _4951) * (L.coat_a2 - 1.0)) + 1.0;\n    return (((L.coat * (0.039999999105930328369140625 + (0.959999978542327880859375 * pow(clamp(1.0 - vdh, 0.0, 1.0), 5.0)))) * (((L.coat_a2 / ((3.1415927410125732421875 * _4960) * _4960)) * (0.5 / max(mix((2.0 * _4945) * L.coat_ndv, _4945 + L.coat_ndv, L.coat_alpha), 9.9999997473787516355514526367188e-05))) * 3.1415927410125732421875)) * step(9.9999997473787516355514526367188e-05, _4945)) * _4945;\n}\n\nvec3 fa_area_layers(FaLayers L, vec3 base, int li, vec3 n, vec3 v, vec3 l, float ndv, float window)\n{\n    float _6865;\n    if (L.sheen_on)\n    {\n        _6865 = L.sheen_scale;\n    }\n    else\n    {\n        _6865 = 1.0;\n    }\n    vec3 result = base * (L.keep * _6865);\n    vec3 _6878 = normalize(l + v);\n    int param = li;\n    vec3 _6889 = fa_light_rgb(param) * window;\n    if (L.sheen_on)\n    {\n        float _6898 = max(dot(n, l), 0.0);\n        float param_1 = L.sheen_alpha;\n        float param_2 = max(dot(n, _6878), 0.0);\n        float param_3 = _6898;\n        float param_4 = ndv;\n        result += ((L.sheen * _6889) * (((((fa_d_charlie(param_1, param_2) * fa_v_ashikhmin(param_3, param_4)) * 3.1415927410125732421875) * step(9.9999997473787516355514526367188e-05, _6898)) * _6898) * L.keep));\n    }\n    if (L.coat > 0.0)\n    {\n        FaLayers param_5 = L;\n        vec3 param_6 = l;\n        vec3 param_7 = _6878;\n        float param_8 = max(dot(v, _6878), 0.0);\n        result += (_6889 * fa_layers_coat(param_5, param_6, param_7, param_8));\n    }\n    return result;\n}\n\nfloat fa_d_ggx_aniso(float ndh, float tdh, float bdh, float at, float ab)\n{\n    float _4813 = tdh / at;\n    float _4817 = bdh / ab;\n    float _4829 = ((_4813 * _4813) + (_4817 * _4817)) + (ndh * ndh);\n    return 1.0 / ((((3.1415927410125732421875 * at) * ab) * _4829) * _4829);\n}\n\nfloat fa_lambda_ggx_aniso(float n, float t, float b, float at, float ab)\n{\n    return 0.5 * (sqrt(1.0 + (((((at * at) * t) * t) + (((ab * ab) * b) * b)) / max(n * n, 9.9999999392252902907785028219223e-09))) - 1.0);\n}\n\nfloat fa_v_ggx_aniso(float ndl, float ndv, float tdv, float bdv, float tdl, float bdl, float at, float ab)\n{\n    float param = ndv;\n    float param_1 = tdv;\n    float param_2 = bdv;\n    float param_3 = at;\n    float param_4 = ab;\n    float param_5 = ndl;\n    float param_6 = tdl;\n    float param_7 = bdl;\n    float param_8 = at;\n    float param_9 = ab;\n    return clamp(1.0 / ((4.0 * max(ndl * ndv, 9.9999997473787516355514526367188e-05)) * ((1.0 + fa_lambda_ggx_aniso(param, param_1, param_2, param_3, param_4)) + fa_lambda_ggx_aniso(param_5, param_6, param_7, param_8, param_9))), 0.0, 1.0);\n}\n\nvec3 fa_layers_light(FaLayers L, vec3 diffuse_color, vec3 f0, vec3 n, vec3 v, vec3 l, vec3 h, float ndl, float ndv, float ndh, float vdh, float alpha, float a2)\n{\n    float _5009 = step(9.9999997473787516355514526367188e-05, ndl);\n    float d_ggx;\n    float vis;\n    if (L.aniso != 0.0)\n    {\n        float param = ndh;\n        float param_1 = dot(L.t, h);\n        float param_2 = dot(L.b, h);\n        float param_3 = L.at;\n        float param_4 = L.ab;\n        d_ggx = fa_d_ggx_aniso(param, param_1, param_2, param_3, param_4);\n        float param_5 = ndl;\n        float param_6 = ndv;\n        float param_7 = dot(L.t, v);\n        float param_8 = dot(L.b, v);\n        float param_9 = dot(L.t, l);\n        float param_10 = dot(L.b, l);\n        float param_11 = L.at;\n        float param_12 = L.ab;\n        vis = fa_v_ggx_aniso(param_5, param_6, param_7, param_8, param_9, param_10, param_11, param_12);\n    }\n    else\n    {\n        float _5088 = ((ndh * ndh) * (a2 - 1.0)) + 1.0;\n        d_ggx = a2 / ((3.1415927410125732421875 * _5088) * _5088);\n        vis = 0.5 / max(mix((2.0 * ndl) * ndv, ndl + ndv, alpha), 9.9999997473787516355514526367188e-05);\n    }\n    vec3 base = diffuse_color + (((f0 + ((vec3(L.f90) - f0) * pow(clamp(1.0 - vdh, 0.0, 1.0), 5.0))) * ((d_ggx * vis) * 3.1415927410125732421875)) * _5009);\n    if (L.sheen_on)\n    {\n        float param_13 = L.sheen_alpha;\n        float param_14 = ndh;\n        float param_15 = ndl;\n        float param_16 = ndv;\n        base = (base * L.sheen_scale) + (L.sheen * (((fa_d_charlie(param_13, param_14) * fa_v_ashikhmin(param_15, param_16)) * 3.1415927410125732421875) * _5009));\n    }\n    vec3 result = base * (L.keep * ndl);\n    if (L.coat > 0.0)\n    {\n        FaLayers param_17 = L;\n        vec3 param_18 = l;\n        vec3 param_19 = h;\n        float param_20 = vdh;\n        result += vec3(fa_layers_coat(param_17, param_18, param_19, param_20));\n    }\n    return result;\n}\n\nvec2 fa_env_brdf(float rough, float ndv)\n{\n    vec4 _4212 = (vec4(-1.0, -0.0274999998509883880615234375, -0.572000026702880859375, 0.02199999988079071044921875) * rough) + vec4(1.0, 0.0425000004470348358154296875, 1.03999996185302734375, -0.039999999105930328369140625);\n    float _4215 = _4212.x;\n    return (vec2(-1.03999996185302734375, 1.03999996185302734375) * ((min(_4215 * _4215, exp2((-9.27999973297119140625) * ndv)) * _4215) + _4212.y)) + _4212.zw;\n}\n\nvec3 fa_probe_level(vec2 origin, float res, int lv, vec2 e)\n{\n    float _3520;\n    if (lv == 0)\n    {\n        _3520 = 0.0;\n    }\n    else\n    {\n        _3520 = res + 2.0;\n    }\n    float _3530;\n    if (lv == 0)\n    {\n        _3530 = 0.0;\n    }\n    else\n    {\n        _3530 = (res - (res / float(1 << max((lv - 1), 0)))) + (2.0 * float(lv - 1));\n    }\n    return textureLod(fa_probe_atlas_fa_env_smp, (((origin + vec2(_3520, _3530)) + vec2(1.0)) + (((e * 0.5) + vec2(0.5)) * (res / float(1 << lv)))) / fa_atlas_size(), 0.0).xyz;\n}\n\nvec3 fa_probe_radiance(vec2 origin, float res, vec3 d, float rough)\n{\n    float _3576;\n    if (res > 64.5)\n    {\n        _3576 = 5.0;\n    }\n    else\n    {\n        _3576 = (res > 32.5) ? 4.0 : 3.0;\n    }\n    float _3591 = clamp(rough, 0.0, 1.0) * (_3576 - 1.0);\n    int _3598 = int(min(floor(_3591), _3576 - 2.0));\n    float _3603 = _3591 - float(_3598);\n    vec3 param = d;\n    vec2 _3607 = fa_oct_encode(param);\n    vec2 param_1 = origin;\n    float param_2 = res;\n    int param_3 = _3598;\n    vec2 param_4 = _3607;\n    vec3 _3617 = fa_probe_level(param_1, param_2, param_3, param_4);\n    if (_3603 < 0.00200000009499490261077880859375)\n    {\n        return _3617;\n    }\n    vec2 param_5 = origin;\n    float param_6 = res;\n    int param_7 = _3598 + 1;\n    vec2 param_8 = _3607;\n    return mix(_3617, fa_probe_level(param_5, param_6, param_7, param_8), vec3(_3603));\n}\n\nvec3 fa_probe_box_dir(vec3 d, vec4 posw, vec4 bx, vec4 by, vec4 bz)\n{\n    if (posw.w < 0.5)\n    {\n        return d;\n    }\n    float _3690 = dot(bx.xyz, fa_world_pos) + bx.w;\n    float _3697 = dot(by.xyz, fa_world_pos) + by.w;\n    float _3704 = dot(bz.xyz, fa_world_pos) + bz.w;\n    float _3710 = dot(bx.xyz, d);\n    float _3714 = dot(by.xyz, d);\n    float _3718 = dot(bz.xyz, d);\n    float _3724;\n    if (_3710 > 9.9999999747524270787835121154785e-07)\n    {\n        _3724 = (1.0 - _3690) / _3710;\n    }\n    else\n    {\n        float _3738;\n        if (_3710 < (-9.9999999747524270787835121154785e-07))\n        {\n            _3738 = ((-1.0) - _3690) / _3710;\n        }\n        else\n        {\n            _3738 = 1000000015047466219876688855040.0;\n        }\n        _3724 = _3738;\n    }\n    float tx = _3724;\n    float _3755;\n    if (_3714 > 9.9999999747524270787835121154785e-07)\n    {\n        _3755 = (1.0 - _3697) / _3714;\n    }\n    else\n    {\n        float _3768;\n        if (_3714 < (-9.9999999747524270787835121154785e-07))\n        {\n            _3768 = ((-1.0) - _3697) / _3714;\n        }\n        else\n        {\n            _3768 = 1000000015047466219876688855040.0;\n        }\n        _3755 = _3768;\n    }\n    float ty = _3755;\n    float _3784;\n    if (_3718 > 9.9999999747524270787835121154785e-07)\n    {\n        _3784 = (1.0 - _3704) / _3718;\n    }\n    else\n    {\n        float _3797;\n        if (_3718 < (-9.9999999747524270787835121154785e-07))\n        {\n            _3797 = ((-1.0) - _3704) / _3718;\n        }\n        else\n        {\n            _3797 = 1000000015047466219876688855040.0;\n        }\n        _3784 = _3797;\n    }\n    float _3809 = tx;\n    float _3812 = (_3809 > 0.0) ? _3809 : 1000000015047466219876688855040.0;\n    tx = _3812;\n    float _3813 = ty;\n    float _3816 = (_3813 > 0.0) ? _3813 : 1000000015047466219876688855040.0;\n    ty = _3816;\n    float _3826 = min(_3812, min(_3816, (_3784 > 0.0) ? _3784 : 1000000015047466219876688855040.0));\n    if (_3826 > 100000001504746621987668885504.0)\n    {\n        return d;\n    }\n    vec3 _3842 = (fa_world_pos + (d * _3826)) - posw.xyz;\n    vec3 _3847;\n    if (dot(_3842, _3842) > 1.0000000133514319600180897396058e-10)\n    {\n        _3847 = normalize(_3842);\n    }\n    else\n    {\n        _3847 = d;\n    }\n    return _3847;\n}\n\nvec3 fa_probe_environment(vec4 tile, vec4 posw, vec4 bx, vec4 by, vec4 bz, inout vec3 d, float rough)\n{\n    vec3 param = d;\n    vec4 param_1 = posw;\n    vec4 param_2 = bx;\n    vec4 param_3 = by;\n    vec4 param_4 = bz;\n    d = fa_probe_box_dir(param, param_1, param_2, param_3, param_4);\n    vec2 param_5 = tile.xy;\n    float param_6 = tile.z;\n    vec3 param_7 = d;\n    float param_8 = rough;\n    return fa_probe_radiance(param_5, param_6, param_7, param_8);\n}\n\nvec3 fa_environment(vec3 d, float rough)\n{\n    float _3893 = (1.0 - fa_mesh_fs_params[42].w) - fa_mesh_fs_params[47].w;\n    vec3 outc = vec3(0.0);\n    if (_3893 > 0.0005000000237487256526947021484375)\n    {\n        vec3 base;\n        if (fa_mesh_fs_params[11].w > 0.5)\n        {\n            vec2 param = fa_mesh_fs_params[41].zw;\n            float param_1 = 128.0;\n            vec3 param_2 = d;\n            float param_3 = rough;\n            base = fa_probe_radiance(param, param_1, param_2, param_3);\n        }\n        else\n        {\n            float _3921 = rough * rough;\n            float _3952 = 0.60000002384185791015625 * _3921;\n            base = mix(mix(fa_mesh_fs_params[12].xyz * 0.550000011920928955078125, mix(fa_mesh_fs_params[12].xyz, fa_mesh_fs_params[11].xyz, vec3(pow(clamp(d.y * (1.0 - (0.699999988079071044921875 * _3921)), 0.0, 1.0), 0.550000011920928955078125))), vec3(smoothstep((-0.0500000007450580596923828125) - _3952, 0.0500000007450580596923828125 + _3952, d.y))), ((fa_mesh_fs_params[11].xyz + fa_mesh_fs_params[12].xyz) * 0.5) * 0.800000011920928955078125, vec3(_3921 * 0.60000002384185791015625));\n        }\n        outc = base * _3893;\n    }\n    if (fa_mesh_fs_params[42].w > 0.0)\n    {\n        vec4 param_4 = fa_mesh_fs_params[42];\n        vec4 param_5 = fa_mesh_fs_params[43];\n        vec4 param_6 = fa_mesh_fs_params[44];\n        vec4 param_7 = fa_mesh_fs_params[45];\n        vec4 param_8 = fa_mesh_fs_params[46];\n        vec3 param_9 = d;\n        float param_10 = rough;\n        vec3 _4011 = fa_probe_environment(param_4, param_5, param_6, param_7, param_8, param_9, param_10);\n        outc += (_4011 * fa_mesh_fs_params[42].w);\n    }\n    if (fa_mesh_fs_params[47].w > 0.0)\n    {\n        vec4 param_11 = fa_mesh_fs_params[47];\n        vec4 param_12 = fa_mesh_fs_params[48];\n        vec4 param_13 = fa_mesh_fs_params[49];\n        vec4 param_14 = fa_mesh_fs_params[50];\n        vec4 param_15 = fa_mesh_fs_params[51];\n        vec3 param_16 = d;\n        float param_17 = rough;\n        vec3 _4043 = fa_probe_environment(param_11, param_12, param_13, param_14, param_15, param_16, param_17);\n        outc += (_4043 * fa_mesh_fs_params[47].w);\n    }\n    return outc;\n}\n\nvec3 fa_layers_ibl(FaLayers L, vec3 n, vec3 v, vec3 f0, float roughness, float occlusion)\n{\n    vec3 rn = n;\n    if (L.aniso != 0.0)\n    {\n        vec3 _4690;\n        if (L.aniso >= 0.0)\n        {\n            _4690 = L.b;\n        }\n        else\n        {\n            _4690 = L.t;\n        }\n        rn = normalize(mix(n, cross(cross(_4690, v), _4690), vec3(abs(L.aniso) * smoothstep(0.0, 0.25, roughness))));\n    }\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05);\n    vec2 _4726 = fa_env_brdf(param, param_1);\n    vec3 param_2 = reflect(-v, rn);\n    float param_3 = roughness;\n    vec3 result = (fa_environment(param_2, param_3) * ((f0 * _4726.x) + (vec3(L.f90) * _4726.y))) * L.base_scale;\n    if (L.sheen_on)\n    {\n        vec3 param_4 = n;\n        float param_5 = L.sheen_rough;\n        result += ((L.sheen * (L.sheen_e * L.keep)) * fa_environment(param_4, param_5));\n    }\n    result *= occlusion;\n    if (L.coat > 0.0)\n    {\n        float param_6 = L.coat_rough;\n        float param_7 = L.coat_ndv;\n        vec2 _4784 = fa_env_brdf(param_6, param_7);\n        vec3 param_8 = reflect(-v, L.nc);\n        float param_9 = L.coat_rough;\n        result += (fa_environment(param_8, param_9) * (L.coat * ((0.039999999105930328369140625 * _4784.x) + _4784.y)));\n    }\n    return result;\n}\n\nvec3 fa_sky_reflection(vec3 n, vec3 v, vec3 f0, float roughness)\n{\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05);\n    vec2 _4254 = fa_env_brdf(param, param_1);\n    vec3 param_2 = reflect(-v, n);\n    float param_3 = roughness;\n    return fa_environment(param_2, param_3) * ((f0 * _4254.x) + vec3(_4254.y));\n}\n\nvec2 fa_xm_size(int k)\n{\n    return max(floor(fa_mesh_fs_params[24].zw / vec2(float(1 << k))), vec2(1.0));\n}\n\nvec2 fa_xm_origin(int k)\n{\n    if (k == 0)\n    {\n        return vec2(0.0);\n    }\n    float y = 0.0;\n    for (int j = 1; j < k; j++)\n    {\n        int param = j;\n        y += fa_xm_size(param).y;\n    }\n    return vec2(fa_mesh_fs_params[24].z, y);\n}\n\nvec3 fa_xm_texel(vec2 size, vec2 origin, vec2 p)\n{\n    return texelFetch(fa_screen_tex_fa_shadow_smp, ivec2(origin + clamp(p, vec2(0.0), size - vec2(1.0))), 0).xyz;\n}\n\nvec3 fa_xm_level(int k, vec2 uv)\n{\n    int param = k;\n    vec2 _5494 = fa_xm_size(param);\n    int param_1 = k;\n    vec2 _5498 = fa_xm_origin(param_1);\n    vec2 _5504 = (uv * _5494) - vec2(0.5);\n    vec2 _5507 = fract(_5504);\n    vec2 _5510 = floor(_5504);\n    vec2 param_2 = _5494;\n    vec2 param_3 = _5498;\n    vec2 param_4 = _5510;\n    vec2 param_5 = _5494;\n    vec2 param_6 = _5498;\n    vec2 param_7 = _5510 + vec2(1.0, 0.0);\n    vec2 param_8 = _5494;\n    vec2 param_9 = _5498;\n    vec2 param_10 = _5510 + vec2(0.0, 1.0);\n    vec2 param_11 = _5494;\n    vec2 param_12 = _5498;\n    vec2 param_13 = _5510 + vec2(1.0);\n    vec3 _5552 = vec3(_5507.x);\n    return mix(mix(fa_xm_texel(param_2, param_3, param_4), fa_xm_texel(param_5, param_6, param_7), _5552), mix(fa_xm_texel(param_8, param_9, param_10), fa_xm_texel(param_11, param_12, param_13), _5552), vec3(_5507.y));\n}\n\nvec3 fa_xm_sample(vec2 uv, float lod)\n{\n    float _5571 = max(fa_mesh_fs_params[31].w - 1.0, 0.0);\n    float _5575 = clamp(lod, 0.0, _5571);\n    int _5579 = int(floor(_5575));\n    int param = _5579;\n    vec2 param_1 = uv;\n    vec3 c = fa_xm_level(param, param_1);\n    float _5589 = float(_5579);\n    float _5590 = _5575 - _5589;\n    bool _5592 = _5590 > 0.001000000047497451305389404296875;\n    bool _5599;\n    if (_5592)\n    {\n        _5599 = _5589 < _5571;\n    }\n    else\n    {\n        _5599 = _5592;\n    }\n    if (_5599)\n    {\n        int param_2 = _5579 + 1;\n        vec2 param_3 = uv;\n        c = mix(c, fa_xm_level(param_2, param_3), vec3(_5590));\n    }\n    return c;\n}\n\nvec3 fa_transmitted(Surface s, vec3 n, vec3 v, float roughness, vec3 f0, float f90, float keep, float tr, inout float blend)\n{\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05);\n    vec2 _5625 = fa_env_brdf(param, param_1);\n    vec3 through = ((vec3(1.0) - clamp((f0 * _5625.x) + (vec3(f90) * _5625.y), vec3(0.0), vec3(1.0))) * s.albedo) * (tr * keep);\n    float _5653 = max(s.thickness, 0.0);\n    bool _5658 = _5653 > 0.0;\n    if ((s.attenuation_distance > 0.0) && _5658)\n    {\n        through *= exp((-((-log(clamp(s.attenuation_color, vec3(9.9999997473787516355514526367188e-05), vec3(1.0)))) / vec3(s.attenuation_distance))) * _5653);\n    }\n    bool _5683 = fa_mesh_fs_params[30].w > 1.5;\n    bool _5690;\n    if (!_5683)\n    {\n        _5690 = fa_mesh_fs_params[30].w < 0.5;\n    }\n    else\n    {\n        _5690 = _5683;\n    }\n    if (_5690)\n    {\n        blend = clamp(dot(through, vec3(0.3333333432674407958984375)), 0.0, 0.980000019073486328125);\n        return vec3(0.0);\n    }\n    vec3 world = fa_world_pos;\n    if (_5658)\n    {\n        world += (refract(-v, n, 1.0 / max(s.ior, 1.0)) * _5653);\n    }\n    vec4 _5725 = vec4(world, 1.0);\n    float _5730 = dot(fa_mesh_fs_params[28], _5725);\n    vec2 uv = vec2(0.5);\n    if (_5730 > 9.9999997473787516355514526367188e-05)\n    {\n        vec2 _5748 = vec2(dot(fa_mesh_fs_params[26], _5725), dot(fa_mesh_fs_params[27], _5725)) / vec2(_5730);\n        float _5756;\n        if (fa_mesh_fs_params[24].y > 0.5)\n        {\n            _5756 = (_5748.y * 0.5) + 0.5;\n        }\n        else\n        {\n            _5756 = 0.5 - (_5748.y * 0.5);\n        }\n        uv = vec2((_5748.x * 0.5) + 0.5, _5756);\n    }\n    vec2 param_2 = clamp(uv, vec2(0.0), vec2(1.0));\n    float param_3 = (clamp(roughness, 0.0, 1.0) * clamp((2.0 * s.ior) - 2.0, 0.0, 1.0)) * max(fa_mesh_fs_params[31].w - 1.0, 0.0);\n    return through * fa_xm_sample(param_2, param_3);\n}\n\nvec3 fa_shadow_debug(vec3 color, vec3 world)\n{\n    if (fa_shadows[27].w < 0.5)\n    {\n        return color;\n    }\n    int _3271 = int(fa_shadows[25].x + 0.5);\n    float _3281 = dot(world - fa_shadows[27].xyz, fa_shadows[28].xyz);\n    vec3 tint = vec3(0.3499999940395355224609375);\n    bool _3286 = _3271 > 0;\n    bool _3295;\n    if (_3286)\n    {\n        int param = _3271 - 1;\n        _3295 = _3281 <= fa_shadow_split_at(param);\n    }\n    else\n    {\n        _3295 = _3286;\n    }\n    if (_3295)\n    {\n        tint = vec3(1.0, 0.1500000059604644775390625, 0.100000001490116119384765625);\n        bool _3301 = _3271 > 1;\n        bool _3308;\n        if (_3301)\n        {\n            _3308 = _3281 > fa_shadows[24].x;\n        }\n        else\n        {\n            _3308 = _3301;\n        }\n        if (_3308)\n        {\n            tint = vec3(0.100000001490116119384765625, 0.89999997615814208984375, 0.20000000298023223876953125);\n        }\n        bool _3314 = _3271 > 2;\n        bool _3321;\n        if (_3314)\n        {\n            _3321 = _3281 > fa_shadows[24].y;\n        }\n        else\n        {\n            _3321 = _3314;\n        }\n        if (_3321)\n        {\n            tint = vec3(0.1500000059604644775390625, 0.300000011920928955078125, 1.0);\n        }\n        bool _3327 = _3271 > 3;\n        bool _3334;\n        if (_3327)\n        {\n            _3334 = _3281 > fa_shadows[24].z;\n        }\n        else\n        {\n            _3334 = _3327;\n        }\n        if (_3334)\n        {\n            tint = vec3(1.0, 0.89999997615814208984375, 0.100000001490116119384765625);\n        }\n    }\n    return mix(color, tint, vec3(0.550000011920928955078125));\n}\n\nvoid main()\n{\n    fa_inst_load();\n    vec3 _8720 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _8720 = -_8720;\n    }\n    vec3 _8018 = normalize(fa_mesh_fs_params[0].xyz - fa_world_pos);\n    vec3 param = fa_world_pos;\n    fa_cluster_begin(param);\n    SurfaceInput param_1 = SurfaceInput(fa_world_pos, _8720, fa_world_tangent, fa_uv, fa_vertex_color, _8018, gl_FrontFacing);\n    Surface _8026 = fa_standard_surface(param_1);\n    vec3 _8751 = _8026.albedo;\n    float _8752 = _8026.alpha;\n    vec3 _8753 = _8026.normal;\n    float _8754 = _8026.metallic;\n    float _8755 = _8026.roughness;\n    float _8756 = _8026.occlusion;\n    vec3 _8757 = _8026.emission;\n    float _8758 = _8026.clearcoat;\n    float _8759 = _8026.clearcoat_roughness;\n    vec3 _8760 = _8026.sheen_color;\n    float _8761 = _8026.sheen_roughness;\n    float _8762 = _8026.anisotropy;\n    float _8763 = _8026.anisotropy_rotation;\n    float _8764 = _8026.specular;\n    float _8765 = _8026.ior;\n    vec3 _8766 = _8026.specular_color;\n    float _8767 = _8026.transmission;\n    float _8768 = _8026.thickness;\n    vec3 _8769 = _8026.attenuation_color;\n    float _8770 = _8026.attenuation_distance;\n    SurfaceInput param_2 = SurfaceInput(fa_world_pos, _8720, fa_world_tangent, fa_uv, fa_vertex_color, _8018, gl_FrontFacing);\n    Surface param_3 = _8026;\n    surface(param_2, param_3);\n    _8751 = param_3.albedo;\n    _8752 = param_3.alpha;\n    _8753 = param_3.normal;\n    _8754 = param_3.metallic;\n    _8755 = param_3.roughness;\n    _8756 = param_3.occlusion;\n    _8757 = param_3.emission;\n    _8758 = param_3.clearcoat;\n    _8759 = param_3.clearcoat_roughness;\n    _8760 = param_3.sheen_color;\n    _8761 = param_3.sheen_roughness;\n    _8762 = param_3.anisotropy;\n    _8763 = param_3.anisotropy_rotation;\n    _8764 = param_3.specular;\n    _8765 = param_3.ior;\n    _8766 = param_3.specular_color;\n    _8767 = param_3.transmission;\n    _8768 = param_3.thickness;\n    _8769 = param_3.attenuation_color;\n    _8770 = param_3.attenuation_distance;\n    vec3 param_4 = fa_world_pos;\n    vec3 param_5 = _8720;\n    vec3 param_6 = param_3.albedo;\n    vec3 param_7 = param_3.normal;\n    fa_apply_decals(param_4, param_5, param_6, param_7);\n    _8751 = param_6;\n    _8753 = param_7;\n    float fa_tr_blend = 0.0;\n    vec3 result;\n    if (fa_mesh_fs_params[3].w > 0.5)\n    {\n        result = _8751;\n    }\n    else\n    {\n        vec3 _8066 = normalize(_8753);\n        float _8073 = clamp(_8754, 0.0, 1.0);\n        float _8077 = clamp(_8755, 0.0500000007450580596923828125, 1.0);\n        float _8081 = _8077 * _8077;\n        float _8085 = _8081 * _8081;\n        float _8090 = max(dot(_8066, _8018), 9.9999997473787516355514526367188e-05);\n        float _8096 = 1.0 - _8073;\n        float _8097 = clamp(_8767, 0.0, 1.0) * _8096;\n        vec3 _8106 = (_8751 * _8096) * (1.0 - _8097);\n        vec3 _8113 = mix(vec3(0.039999999105930328369140625), _8751, vec3(_8073));\n        vec3 f0 = _8113;\n        SurfaceInput param_8 = SurfaceInput(fa_world_pos, _8720, fa_world_tangent, fa_uv, fa_vertex_color, _8018, gl_FrontFacing);\n        Surface param_9 = Surface(_8751, _8752, _8753, _8754, _8755, _8756, _8757, _8758, _8759, _8760, _8761, _8762, _8763, _8764, _8765, _8766, _8767, _8768, _8769, _8770);\n        vec3 param_10 = _8066;\n        vec3 param_11 = _8018;\n        float param_12 = _8073;\n        float param_13 = _8077;\n        vec3 param_14 = _8113;\n        FaLayers _8129 = fa_layers_setup(param_8, param_9, param_10, param_11, param_12, param_13, param_14);\n        f0 = param_14;\n        vec3 param_15 = _8066;\n        vec3 lit = (fa_indirect_diffuse(param_15) * _8106) * _8756;\n        if (_8129.on)\n        {\n            lit *= _8129.base_scale;\n        }\n        int _8151 = fa_cl_ndir + fa_cl_local;\n        float _8216;\n        for (int ln = 0; ln < _8151; ln++)\n        {\n            int param_16 = ln;\n            int _8164 = fa_cl_light(param_16);\n            int param_17 = _8164;\n            if (fa_baked_keep(param_17) <= 0.0)\n            {\n                continue;\n            }\n            int param_18 = _8164;\n            vec3 param_19 = fa_world_pos;\n            vec3 param_20 = _8720;\n            LightSample _8180 = fa_light_shadowed(param_18, param_19, param_20);\n            float _8188 = max(dot(_8066, _8180.direction), 0.0);\n            float _8194 = _8180.attenuation * _8180.shadow;\n            vec3 _8199 = normalize(_8180.direction + _8018);\n            float _8204 = max(dot(_8066, _8199), 0.0);\n            float _8209 = max(dot(_8018, _8199), 0.0);\n            if (fa_light_is_area)\n            {\n                if (_8129.on)\n                {\n                    _8216 = _8129.f90;\n                }\n                else\n                {\n                    _8216 = 1.0;\n                }\n                int param_21 = _8164;\n                vec3 param_22 = fa_world_pos;\n                vec3 param_23 = _8066;\n                vec3 param_24 = _8018;\n                vec3 param_25 = _8106;\n                vec3 param_26 = f0;\n                float param_27 = _8216;\n                float param_28 = _8077;\n                float param_29 = _8090;\n                float param_30 = _8194;\n                vec3 area = fa_area_shade(param_21, param_22, param_23, param_24, param_25, param_26, param_27, param_28, param_29, param_30);\n                if (_8129.on)\n                {\n                    FaLayers param_31 = _8129;\n                    vec3 param_32 = area;\n                    int param_33 = _8164;\n                    vec3 param_34 = _8066;\n                    vec3 param_35 = _8018;\n                    vec3 param_36 = _8180.direction;\n                    float param_37 = _8090;\n                    float param_38 = _8194;\n                    area = fa_area_layers(param_31, param_32, param_33, param_34, param_35, param_36, param_37, param_38);\n                }\n                lit += area;\n            }\n            else\n            {\n                if (_8129.on)\n                {\n                    FaLayers param_39 = _8129;\n                    vec3 param_40 = _8106;\n                    vec3 param_41 = f0;\n                    vec3 param_42 = _8066;\n                    vec3 param_43 = _8018;\n                    vec3 param_44 = _8180.direction;\n                    vec3 param_45 = _8199;\n                    float param_46 = _8188;\n                    float param_47 = _8090;\n                    float param_48 = _8204;\n                    float param_49 = _8209;\n                    float param_50 = _8081;\n                    float param_51 = _8085;\n                    int param_52 = _8164;\n                    lit += (fa_layers_light(param_39, param_40, param_41, param_42, param_43, param_44, param_45, param_46, param_47, param_48, param_49, param_50, param_51) * ((fa_light_rgb(param_52) * fa_light_tint) * _8194));\n                }\n                else\n                {\n                    float _8318 = ((_8204 * _8204) * (_8085 - 1.0)) + 1.0;\n                    int param_53 = _8164;\n                    lit += (((_8106 + (((f0 + ((vec3(1.0) - f0) * pow(1.0 - _8209, 5.0))) * (((_8085 / ((3.1415927410125732421875 * _8318) * _8318)) * (0.5 / max(mix((2.0 * _8188) * _8090, _8188 + _8090, _8081), 9.9999997473787516355514526367188e-05))) * 3.1415927410125732421875)) * step(9.9999997473787516355514526367188e-05, _8188))) * (fa_light_rgb(param_53) * fa_light_tint)) * (_8188 * _8194));\n                }\n            }\n        }\n        if (_8129.on)\n        {\n            FaLayers param_54 = _8129;\n            vec3 param_55 = _8066;\n            vec3 param_56 = _8018;\n            vec3 param_57 = f0;\n            float param_58 = _8077;\n            float param_59 = _8756;\n            lit += fa_layers_ibl(param_54, param_55, param_56, param_57, param_58, param_59);\n        }\n        else\n        {\n            vec3 param_60 = _8066;\n            vec3 param_61 = _8018;\n            vec3 param_62 = f0;\n            float param_63 = _8077;\n            lit += (fa_sky_reflection(param_60, param_61, param_62, param_63) * _8756);\n        }\n        if (_8097 > 0.0)\n        {\n            float _8416;\n            if (_8129.on)\n            {\n                _8416 = _8129.f90;\n            }\n            else\n            {\n                _8416 = 1.0;\n            }\n            float _8424;\n            if (_8129.on)\n            {\n                _8424 = _8129.base_scale;\n            }\n            else\n            {\n                _8424 = 1.0;\n            }\n            Surface param_64 = Surface(_8751, _8752, _8753, _8754, _8755, _8756, _8757, _8758, _8759, _8760, _8761, _8762, _8763, _8764, _8765, _8766, _8767, _8768, _8769, _8770);\n            vec3 param_65 = _8066;\n            vec3 param_66 = _8018;\n            float param_67 = _8077;\n            vec3 param_68 = f0;\n            float param_69 = _8416;\n            float param_70 = _8424;\n            float param_71 = _8097;\n            float param_72 = fa_tr_blend;\n            vec3 _8448 = fa_transmitted(param_64, param_65, param_66, param_67, param_68, param_69, param_70, param_71, param_72);\n            fa_tr_blend = param_72;\n            lit += _8448;\n        }\n        result = lit;\n    }\n    vec3 _8455 = result;\n    vec3 _8456 = _8455 + _8757;\n    result = _8456;\n    vec3 param_73 = _8456;\n    vec3 param_74 = fa_world_pos;\n    result = fa_shadow_debug(param_73, param_74);\n    bool _8465 = fa_mesh_fs_params[7].w > 0.0;\n    bool _8472;\n    if (!_8465)\n    {\n        _8472 = fa_mesh_fs_params[8].y > 0.0;\n    }\n    else\n    {\n        _8472 = _8465;\n    }\n    if (_8472)\n    {\n        vec3 _8481 = fa_world_pos - fa_mesh_fs_params[0].xyz;\n        float _8487 = dot(_8481, fa_mesh_fs_params[9].xyz);\n        bool _8491 = fa_mesh_fs_params[9].w > 0.5;\n        float _8492;\n        if (_8491)\n        {\n            _8492 = _8487;\n        }\n        else\n        {\n            _8492 = length(_8481);\n        }\n        float _8504 = _8492 - fa_mesh_fs_params[8].x;\n        if (_8504 > 0.0)\n        {\n            float _8513 = fa_mesh_fs_params[7].w * _8504;\n            float tau = _8513 * _8513;\n            if (fa_mesh_fs_params[8].y > 0.0)\n            {\n                float _8529;\n                if (_8491)\n                {\n                    _8529 = fa_world_pos.y - (fa_mesh_fs_params[9].y * _8487);\n                }\n                else\n                {\n                    _8529 = fa_mesh_fs_params[0].y;\n                }\n                float _8550 = mix(_8529, fa_world_pos.y, clamp(fa_mesh_fs_params[8].x / _8492, 0.0, 1.0));\n                float _8554 = fa_world_pos.y - _8550;\n                float _8559 = _8550 - fa_mesh_fs_params[8].z;\n                float _8564 = fa_world_pos.y - fa_mesh_fs_params[8].z;\n                bool _8567 = _8559 <= 0.0;\n                bool _8568 = !_8567;\n                bool _8574;\n                if (_8568)\n                {\n                    _8574 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _8574 = _8567;\n                }\n                float _8575;\n                if (_8574)\n                {\n                    _8575 = fa_mesh_fs_params[8].y;\n                }\n                else\n                {\n                    _8575 = fa_mesh_fs_params[8].y * exp(-min(fa_mesh_fs_params[8].w * _8559, 80.0));\n                }\n                bool _8602;\n                if (_8568)\n                {\n                    _8602 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _8602 = _8567;\n                }\n                float _8603;\n                if (_8602)\n                {\n                    _8603 = fa_mesh_fs_params[8].y * _8559;\n                }\n                else\n                {\n                    _8603 = (fa_mesh_fs_params[8].y * (1.0 - exp(-min(fa_mesh_fs_params[8].w * _8559, 80.0)))) / fa_mesh_fs_params[8].w;\n                }\n                bool _8628 = _8564 <= 0.0;\n                bool _8635;\n                if (!_8628)\n                {\n                    _8635 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _8635 = _8628;\n                }\n                float _8636;\n                if (_8635)\n                {\n                    _8636 = fa_mesh_fs_params[8].y * _8564;\n                }\n                else\n                {\n                    _8636 = (fa_mesh_fs_params[8].y * (1.0 - exp(-min(fa_mesh_fs_params[8].w * _8564, 80.0)))) / fa_mesh_fs_params[8].w;\n                }\n                float _8663;\n                if (abs(_8554) < 0.001000000047497451305389404296875)\n                {\n                    _8663 = _8575;\n                }\n                else\n                {\n                    _8663 = (_8636 - _8603) / _8554;\n                }\n                tau += (_8504 * max(_8663, 0.0));\n            }\n            result = mix(result, fa_mesh_fs_params[7].xyz, vec3(clamp(1.0 - exp(-clamp(tau, 0.0, 80.0)), 0.0, 1.0)));\n        }\n    }\n    if (fa_tr_blend > 0.0)\n    {\n        float _8699 = 1.0 - fa_tr_blend;\n        result /= vec3(_8699);\n        _8752 *= _8699;\n    }\n    fa_frag_color = vec4(result, _8752);\n}\n\n",
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
            "size": 848,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_650",
            "glsl_uniforms": [
              {
                "type": "vec4",
                "array_count": 53,
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
            "inst_name": "_2312",
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
      "vs": "#version 430\n\nstruct VertexData\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 color;\n    vec3 object_pos;\n};\n\nstruct points_item\n{\n    vec4 pos;\n    vec4 tint;\n};\n\nlayout(binding = 0, std430) readonly buffer fa_vs_points_buf\n{\n    points_item data[];\n} fa_vs_points;\n\nuniform vec4 fa_mesh_vs_params[11];\nuniform vec4 fa_skin[192];\nuniform vec4 fa_inst_base[4];\nlayout(location = 0) out vec3 fa_world_pos;\nlayout(location = 1) out vec3 fa_world_normal;\nlayout(location = 2) out vec4 fa_world_tangent;\nlayout(location = 3) out vec2 fa_uv;\nlayout(location = 4) out vec4 fa_vertex_color;\nlayout(location = 9) in vec4 fa_joints;\nlayout(location = 10) in vec4 fa_weights;\nlayout(location = 0) in vec3 fa_position;\nlayout(location = 1) in vec3 fa_normal;\nlayout(location = 3) in vec4 fa_tangent;\nlayout(location = 2) in vec2 fa_texcoord0;\nlayout(location = 4) in vec4 fa_color;\nlayout(location = 5) out vec3 fa_lm;\nlayout(location = 5) in vec4 fa_inst_m0;\nlayout(location = 6) in vec4 fa_inst_m1;\nlayout(location = 7) in vec4 fa_inst_m2;\nlayout(location = 8) in vec4 fa_inst_m3;\n\nvoid fa_inst_begin()\n{\n}\n\nmat4 fa_skin_matrix_at(vec4 joints, vec4 weights, int base)\n{\n    vec4 r0 = vec4(0.0);\n    vec4 r1 = vec4(0.0);\n    vec4 r2 = vec4(0.0);\n    for (int i = 0; i < 4; i++)\n    {\n        int _216 = base + (int((joints[i] * 255.0) + 0.5) * 3);\n        r0 += (fa_skin[_216 * 1 + 0] * weights[i]);\n        r1 += (fa_skin[(_216 + 1) * 1 + 0] * weights[i]);\n        r2 += (fa_skin[(_216 + 2) * 1 + 0] * weights[i]);\n    }\n    return mat4(vec4(r0.x, r1.x, r2.x, 0.0), vec4(r0.y, r1.y, r2.y, 0.0), vec4(r0.z, r1.z, r2.z, 0.0), vec4(r0.w, r1.w, r2.w, 1.0));\n}\n\nmat4 fa_skin_matrix(vec4 joints, vec4 weights)\n{\n    vec4 param = joints;\n    vec4 param_1 = weights;\n    int param_2 = 0;\n    return fa_skin_matrix_at(param, param_1, param_2);\n}\n\nVertexData fa_vertex_data(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    vec3 _121 = cross(model[1].xyz, model[2].xyz);\n    float _126 = (dot(model[0].xyz, _121) < 0.0) ? (-1.0) : 1.0;\n    return VertexData((model * vec4(position, 1.0)).xyz, (((_121 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _126, vec4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _126), texcoord0 * fa_mesh_vs_params[8].xy, color, position);\n}\n\nvoid vertex(inout VertexData v)\n{\n    if (fa_vs_points.data[gl_InstanceID].pos.w < 0.5)\n    {\n        v.world_pos = vec3(1000000000.0);\n        return;\n    }\n    v.world_pos += fa_vs_points.data[gl_InstanceID].pos.xyz;\n    v.color = fa_vs_points.data[gl_InstanceID].tint;\n}\n\nvoid fa_shade_vertex(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    mat4 param = model;\n    vec3 param_1 = position;\n    vec3 param_2 = normal;\n    vec4 param_3 = tangent;\n    vec2 param_4 = texcoord0;\n    vec4 param_5 = color;\n    VertexData param_6 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    vertex(param_6);\n    fa_world_pos = param_6.world_pos;\n    fa_world_normal = param_6.world_normal;\n    fa_world_tangent = param_6.world_tangent;\n    fa_uv = param_6.uv;\n    fa_vertex_color = param_6.color;\n    gl_Position = mat4(fa_mesh_vs_params[0], fa_mesh_vs_params[1], fa_mesh_vs_params[2], fa_mesh_vs_params[3]) * vec4(param_6.world_pos, 1.0);\n}\n\nvoid main()\n{\n    fa_inst_begin();\n    vec4 param = fa_joints;\n    vec4 param_1 = fa_weights;\n    mat4 param_2 = mat4(fa_inst_base[0], fa_inst_base[1], fa_inst_base[2], fa_inst_base[3]) * fa_skin_matrix(param, param_1);\n    vec3 param_3 = fa_position;\n    vec3 param_4 = fa_normal;\n    vec4 param_5 = fa_tangent;\n    vec2 param_6 = fa_texcoord0;\n    vec4 param_7 = fa_color;\n    fa_shade_vertex(param_2, param_3, param_4, param_5, param_6, param_7);\n    fa_lm = vec3(0.0);\n}\n\n",
      "fs": "#version 430\n\nstruct SurfaceInput\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 vertex_color;\n    vec3 view_dir;\n    bool front_facing;\n};\n\nstruct LightSample\n{\n    vec3 direction;\n    vec3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct Surface\n{\n    vec3 albedo;\n    float alpha;\n    vec3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    vec3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    vec3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    vec3 specular_color;\n    float transmission;\n    float thickness;\n    vec3 attenuation_color;\n    float attenuation_distance;\n};\n\nstruct FaLayers\n{\n    bool on;\n    float f90;\n    float keep;\n    float base_scale;\n    float coat;\n    float coat_rough;\n    float coat_alpha;\n    float coat_a2;\n    vec3 nc;\n    float coat_ndv;\n    bool sheen_on;\n    vec3 sheen;\n    float sheen_rough;\n    float sheen_alpha;\n    float sheen_scale;\n    float sheen_e;\n    float aniso;\n    vec3 t;\n    vec3 b;\n    float at;\n    float ab;\n};\n\nconst float _4355[63] = float[](1.0, 1.0, 1.0, 0.4790000021457672119140625, 0.11699999868869781494140625, 0.01200000010430812835693359375, 0.0, 0.0, 0.0, 1.0, 1.0, 1.0, 0.578000009059906005859375, 0.19300000369548797607421875, 0.0350000001490116119384765625, 0.0030000000260770320892333984375, 0.0, 0.0, 1.0, 1.0, 1.0, 0.6740000247955322265625, 0.3459999859333038330078125, 0.1319999992847442626953125, 0.032999999821186065673828125, 0.0040000001899898052215576171875, 0.0, 0.971000015735626220703125, 0.954999983310699462890625, 0.828999996185302734375, 0.63999998569488525390625, 0.42599999904632568359375, 0.24500000476837158203125, 0.115000002086162567138671875, 0.037000000476837158203125, 0.0030000000260770320892333984375, 0.7469999790191650390625, 0.737999975681304931640625, 0.670000016689300537109375, 0.563000023365020751953125, 0.4309999942779541015625, 0.3039999902248382568359375, 0.1940000057220458984375, 0.1019999980926513671875, 0.0309999994933605194091796875, 0.614000022411346435546875, 0.609000027179718017578125, 0.566999971866607666015625, 0.499000012874603271484375, 0.412000000476837158203125, 0.32400000095367431640625, 0.240999996662139892578125, 0.162000000476837158203125, 0.087999999523162841796875, 0.538999974727630615234375, 0.535000026226043701171875, 0.505999982357025146484375, 0.4569999873638153076171875, 0.393999993801116943359375, 0.328999996185302734375, 0.2660000026226043701171875, 0.203999996185302734375, 0.14200000464916229248046875);\n\nstruct points_item\n{\n    vec4 pos;\n    vec4 tint;\n};\n\nuniform vec4 fa_mesh_fs_params[53];\nuniform vec4 fa_shadows[30];\nlayout(binding = 1, std430) readonly buffer fa_points_buf\n{\n    points_item data[];\n} points;\n\nlayout(binding = 0) uniform sampler2D fa_light_tex_fa_shadow_smp;\nlayout(binding = 1) uniform sampler2D fa_tex_fa_smp;\nlayout(binding = 2) uniform sampler2D fa_normal_tex_fa_smp;\nlayout(binding = 3) uniform sampler2D fa_mr_tex_fa_smp;\nlayout(binding = 4) uniform sampler2D fa_occlusion_tex_fa_smp;\nlayout(binding = 5) uniform sampler2D fa_emissive_tex_fa_smp;\nlayout(binding = 6) uniform sampler2D fa_decal_tex_fa_env_smp;\nlayout(binding = 7) uniform sampler2D fa_lightmap_fa_env_smp;\nlayout(binding = 8) uniform sampler2D fa_probe_atlas_fa_env_smp;\nlayout(binding = 9) uniform sampler2D fa_light_atlas_fa_env_smp;\nlayout(binding = 10) uniform sampler2D fa_shadow_tex_fa_shadow_smp;\nlayout(binding = 11) uniform sampler2D fa_screen_tex_fa_shadow_smp;\n\nlayout(location = 0) in vec3 fa_world_pos;\nlayout(location = 5) in vec3 fa_lm;\nlayout(location = 1) in vec3 fa_world_normal;\nlayout(location = 2) in vec4 fa_world_tangent;\nlayout(location = 3) in vec2 fa_uv;\nlayout(location = 4) in vec4 fa_vertex_color;\nlayout(location = 0) out vec4 fa_frag_color;\nvec3 fa_light_tint;\nbool fa_light_is_area;\nint fa_cl_ndir;\nint fa_cl_slot;\nint fa_cl_local;\n\nvoid fa_inst_load()\n{\n}\n\nvec4 fa_light_texel(int t)\n{\n    return texelFetch(fa_light_tex_fa_shadow_smp, ivec2(t & 1023, t >> 10), 0);\n}\n\nvec4 fa_cluster_texel(vec3 world_pos)\n{\n    bool _1588 = fa_mesh_fs_params[19].x < 0.0;\n    bool _1595;\n    if (!_1588)\n    {\n        _1595 = fa_mesh_fs_params[19].w < 1.0;\n    }\n    else\n    {\n        _1595 = _1588;\n    }\n    bool _1603;\n    if (!_1595)\n    {\n        _1603 = fa_mesh_fs_params[18].x < 1.0;\n    }\n    else\n    {\n        _1603 = _1595;\n    }\n    bool _1610;\n    if (!_1603)\n    {\n        _1610 = fa_mesh_fs_params[18].y < 1.0;\n    }\n    else\n    {\n        _1610 = _1603;\n    }\n    bool _1617;\n    if (!_1610)\n    {\n        _1617 = fa_mesh_fs_params[19].y < 1.0;\n    }\n    else\n    {\n        _1617 = _1610;\n    }\n    if (_1617)\n    {\n        return vec4(0.0);\n    }\n    vec4 _1627 = vec4(world_pos, 1.0);\n    float _1633 = dot(fa_mesh_fs_params[16], _1627);\n    if (!(_1633 > 9.9999999747524270787835121154785e-07))\n    {\n        return vec4(0.0);\n    }\n    vec2 _1655 = vec2(dot(fa_mesh_fs_params[14], _1627), dot(fa_mesh_fs_params[15], _1627)) / vec2(_1633);\n    int _1659 = int(fa_mesh_fs_params[18].x);\n    int _1663 = int(fa_mesh_fs_params[18].y);\n    int param = (int(fa_mesh_fs_params[19].x) + (((clamp(int(floor(log2(max(dot(fa_mesh_fs_params[17].xyz, world_pos) + fa_mesh_fs_params[17].w, fa_mesh_fs_params[18].w) / fa_mesh_fs_params[18].w) * fa_mesh_fs_params[18].z)), 0, int(fa_mesh_fs_params[19].y) - 1) * _1663) + clamp(int(floor(((_1655.y * 0.5) + 0.5) * fa_mesh_fs_params[18].y)), 0, _1663 - 1)) * _1659)) + clamp(int(floor(((_1655.x * 0.5) + 0.5) * fa_mesh_fs_params[18].x)), 0, _1659 - 1);\n    return fa_light_texel(param);\n}\n\nivec2 fa_cluster_lookup(vec3 world_pos)\n{\n    vec3 param = world_pos;\n    vec4 _1739 = fa_cluster_texel(param);\n    return ivec2(int(_1739.x), int(_1739.y));\n}\n\nvoid fa_cluster_begin(vec3 world_pos)\n{\n    fa_cl_ndir = int(fa_mesh_fs_params[19].z);\n    vec3 param = world_pos;\n    ivec2 _5830 = fa_cluster_lookup(param);\n    fa_cl_slot = _5830.x;\n    fa_cl_local = _5830.y;\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nvec3 fa_linear_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_tex_fix(inout vec3 c, float mode)\n{\n    if (mode > 1.5)\n    {\n        vec3 param = c;\n        vec3 _7004 = fa_linear_to_srgb(param);\n        c = _7004;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            vec3 param_1 = c;\n            vec3 _7012 = fa_srgb_to_linear(param_1);\n            c = _7012;\n        }\n    }\n    return c;\n}\n\nvec3 fa_tangent_normal(SurfaceInput i, vec3 m)\n{\n    vec3 _532;\n    if (i.front_facing)\n    {\n        _532 = i.world_normal;\n    }\n    else\n    {\n        _532 = -i.world_normal;\n    }\n    vec3 _556 = normalize(i.world_tangent.xyz - (_532 * dot(_532, i.world_tangent.xyz)));\n    vec3 _583 = normalize(((_556 * m.x) + ((cross(_532, _556) * i.world_tangent.w) * m.y)) + (_532 * m.z));\n    vec3 _586;\n    if (i.front_facing)\n    {\n        _586 = _583;\n    }\n    else\n    {\n        _586 = -_583;\n    }\n    return _586;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    vec4 base_t = texture(fa_tex_fa_smp, i.uv);\n    float param = fa_mesh_fs_params[6].w;\n    float param_1 = 1.0;\n    vec3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    vec3 _7043 = fa_tex_fix(param_2, param_3);\n    vec4 _9305 = base_t;\n    _9305.x = _7043.x;\n    _9305.y = _7043.y;\n    _9305.z = _7043.z;\n    base_t = _9305;\n    vec4 _7057 = (_9305 * fa_mesh_fs_params[2]) * i.vertex_color;\n    vec3 _9081 = i.world_normal;\n    if (fa_mesh_fs_params[6].z > 0.5)\n    {\n        float param_4 = fa_mesh_fs_params[6].w;\n        float param_5 = 16.0;\n        vec3 param_6 = texture(fa_normal_tex_fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        vec3 _7089 = fa_tex_fix(param_6, param_7);\n        vec3 _7092 = (_7089 * 2.0) - vec3(1.0);\n        vec2 _7097 = _7092.xy * fa_mesh_fs_params[6].x;\n        vec3 _9313 = _7092;\n        _9313.x = _7097.x;\n        _9313.y = _7097.y;\n        SurfaceInput param_8 = i;\n        vec3 param_9 = _9313;\n        _9081 = fa_tangent_normal(param_8, param_9);\n    }\n    vec4 mrt = texture(fa_mr_tex_fa_smp, i.uv);\n    float param_10 = fa_mesh_fs_params[6].w;\n    float param_11 = 64.0;\n    vec3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    vec3 _7125 = fa_tex_fix(param_12, param_13);\n    vec4 _9316 = mrt;\n    _9316.x = _7125.x;\n    _9316.y = _7125.y;\n    _9316.z = _7125.z;\n    mrt = _9316;\n    vec4 _7153 = texture(fa_occlusion_tex_fa_smp, i.uv);\n    float param_14 = fa_mesh_fs_params[6].w;\n    float param_15 = 256.0;\n    vec3 param_16 = _7153.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    vec3 _7164 = fa_tex_fix(param_16, param_17);\n    float param_18 = fa_mesh_fs_params[6].w;\n    float param_19 = 4.0;\n    vec3 param_20 = texture(fa_emissive_tex_fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    vec3 _7194 = fa_tex_fix(param_20, param_21);\n    float _9086 = fa_mesh_fs_params[20].x;\n    float _9087 = fa_mesh_fs_params[20].y;\n    float _9090 = fa_mesh_fs_params[20].z;\n    float _9089 = fa_mesh_fs_params[21].w;\n    float _9092 = fa_mesh_fs_params[22].x;\n    if (fa_mesh_fs_params[22].z > 0.5)\n    {\n        if (mod(fa_mesh_fs_params[22].z, 2.0) > 0.5)\n        {\n            _9086 *= _7164.y;\n            _9087 *= _7164.z;\n            _9089 *= _7153.w;\n        }\n        if (fa_mesh_fs_params[22].z > 1.5)\n        {\n            _9090 *= mrt.x;\n            _9092 *= mrt.w;\n        }\n    }\n    return Surface(_7057.xyz, _7057.w, _9081, clamp(fa_mesh_fs_params[5].x * _7125.z, 0.0, 1.0), clamp(fa_mesh_fs_params[5].y * _7125.y, 0.0500000007450580596923828125, 1.0), 1.0 + (fa_mesh_fs_params[6].y * (_7164.x - 1.0)), fa_mesh_fs_params[3].xyz + (fa_mesh_fs_params[4].xyz * _7194), _9086, _9087, fa_mesh_fs_params[21].xyz, _9089, _9090, fa_mesh_fs_params[20].w, _9092, fa_mesh_fs_params[22].y, fa_mesh_fs_params[23].xyz, fa_mesh_fs_params[30].x, fa_mesh_fs_params[30].y, fa_mesh_fs_params[31].xyz, fa_mesh_fs_params[30].z);\n}\n\nvoid surface(SurfaceInput i, inout Surface s)\n{\n    s.emission += (i.vertex_color.xyz * points.data[0].tint.w);\n}\n\nvec4 fa_decal_tile(vec4 rect, vec2 uv, vec2 atlas, vec2 ddx, vec2 ddy)\n{\n    vec2 _1819 = rect.zw - rect.xy;\n    vec2 _1823 = _1819 * atlas;\n    vec2 _1827 = ddx * _1823;\n    vec2 _1831 = ddy * _1823;\n    return textureLod(fa_decal_tex_fa_env_smp, rect.xy + (clamp(uv, vec2(0.0), vec2(1.0)) * _1819), clamp(0.5 * log2(max(max(dot(_1827, _1827), dot(_1831, _1831)), 9.9999999392252902907785028219223e-09)), 0.0, 3.0));\n}\n\nvec3 fa_dc_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_dc_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvoid fa_apply_decals(vec3 world_pos, vec3 geo_normal, inout vec3 albedo, inout vec3 normal)\n{\n    bool _1864 = fa_mesh_fs_params[10].y < 0.5;\n    bool _1871;\n    if (!_1864)\n    {\n        _1871 = fa_mesh_fs_params[10].w < 0.5;\n    }\n    else\n    {\n        _1871 = _1864;\n    }\n    if (_1871)\n    {\n        return;\n    }\n    vec3 _1877 = dFdx(world_pos);\n    vec3 _1880 = dFdy(world_pos);\n    vec3 param = world_pos;\n    vec4 _1884 = fa_cluster_texel(param);\n    int _1888 = int(_1884.w);\n    if (_1888 < 1)\n    {\n        return;\n    }\n    int _1898 = int(fa_mesh_fs_params[10].y + 0.5);\n    int param_1 = _1898;\n    vec4 _1902 = fa_light_texel(param_1);\n    vec2 _1905 = _1902.yz;\n    int _1909 = int(_1902.w);\n    int param_2 = _1898 + 1;\n    vec4 _1914 = fa_light_texel(param_2);\n    float _1915 = _1914.x;\n    int _1921 = int(fa_mesh_fs_params[10].w + 0.5) - 1;\n    int _1925 = int(_1884.z);\n    vec3 _2190;\n    for (int k = 0; k < _1888; k++)\n    {\n        int _1938 = _1925 + k;\n        int param_3 = _1909 + (_1938 >> 2);\n        int _1955 = (_1898 + 2) + (int(fa_light_texel(param_3)[_1938 & 3]) * 7);\n        int param_4 = _1955 + 6;\n        vec4 _1960 = fa_light_texel(param_4);\n        if (((int(_1960.w + 0.5) >> _1921) & 1) == 0)\n        {\n            continue;\n        }\n        int param_5 = _1955;\n        vec4 _1975 = fa_light_texel(param_5);\n        int param_6 = _1955 + 1;\n        vec4 _1980 = fa_light_texel(param_6);\n        int param_7 = _1955 + 2;\n        vec4 _1985 = fa_light_texel(param_7);\n        vec3 _1988 = _1975.xyz;\n        float _1993 = dot(_1988, world_pos) + _1975.w;\n        vec3 _1995 = _1980.xyz;\n        float _2000 = dot(_1995, world_pos) + _1980.w;\n        vec3 _2002 = _1985.xyz;\n        float _2007 = dot(_2002, world_pos) + _1985.w;\n        bool _2012 = abs(_1993) > 0.5;\n        bool _2020;\n        if (!_2012)\n        {\n            _2020 = abs(_2000) > 0.5;\n        }\n        else\n        {\n            _2020 = _2012;\n        }\n        bool _2028;\n        if (!_2020)\n        {\n            _2028 = abs(_2007) > 0.5;\n        }\n        else\n        {\n            _2028 = _2020;\n        }\n        if (_2028)\n        {\n            continue;\n        }\n        float _2043 = clamp(dot(geo_normal, normalize(_2002)) * _1960.z, 0.0, 1.0);\n        if (_2043 <= 0.0)\n        {\n            continue;\n        }\n        float _2063 = (clamp((0.5 - abs(_2007)) * 10.0, 0.0, 1.0) * _2043) * _1960.x;\n        vec2 _2071 = vec2(_1993 + 0.5, 0.5 - _2000);\n        vec2 _2081 = vec2(dot(_1988, _1877), dot(_1995, _1877));\n        vec2 _2091 = vec2(dot(_1988, _1880), dot(_1995, _1880));\n        int param_8 = _1955 + 5;\n        vec4 _2096 = fa_light_texel(param_8);\n        int param_9 = _1955 + 3;\n        vec4 _2101 = fa_light_texel(param_9);\n        int param_10 = _1955 + 4;\n        vec4 _2106 = fa_light_texel(param_10);\n        float tex_a = 1.0;\n        vec3 col = _2096.xyz;\n        bool _2116 = _2101.z > _2101.x;\n        if (_2116)\n        {\n            vec4 param_11 = _2101;\n            vec2 param_12 = _2071;\n            vec2 param_13 = _1905;\n            vec2 param_14 = _2081;\n            vec2 param_15 = _2091;\n            vec4 tx = fa_decal_tile(param_11, param_12, param_13, param_14, param_15);\n            if ((_1915 > 0.5) && (_1915 < 1.5))\n            {\n                vec3 param_16 = tx.xyz;\n                vec3 _2142 = fa_dc_to_linear(param_16);\n                vec4 _9169 = tx;\n                _9169.x = _2142.x;\n                _9169.y = _2142.y;\n                _9169.z = _2142.z;\n                tx = _9169;\n            }\n            col *= tx.xyz;\n            tex_a = tx.w;\n        }\n        albedo = mix(albedo, col, vec3(clamp((_2063 * tex_a) * _2096.w, 0.0, 1.0)));\n        if (_2106.z > _2106.x)\n        {\n            vec4 param_17 = _2106;\n            vec2 param_18 = _2071;\n            vec2 param_19 = _1905;\n            vec2 param_20 = _2081;\n            vec2 param_21 = _2091;\n            vec4 _2186 = fa_decal_tile(param_17, param_18, param_19, param_20, param_21);\n            if (_1915 > 1.5)\n            {\n                vec3 param_22 = _2186.xyz;\n                vec3 _2196 = fa_dc_to_srgb(param_22);\n                _2190 = _2196;\n            }\n            else\n            {\n                _2190 = _2186.xyz;\n            }\n            vec3 _2205 = (_2190 * 2.0) - vec3(1.0);\n            vec2 _2210 = _2205.xy * _1960.y;\n            vec3 _2232 = (normalize(_1988) * _2210.x) + (normalize(_1995) * _2210.y);\n            vec3 _2235 = normalize(normal);\n            normal = normalize(mix(_2235, normalize((_2235 * max(_2205.z, 0.0500000007450580596923828125)) + (_2232 - (_2235 * dot(_2235, _2232)))), vec3(clamp(_2063 * (_2116 ? tex_a : 1.0), 0.0, 1.0))));\n        }\n    }\n}\n\nfloat fa_sheen_albedo(float ndv, float rough)\n{\n    float _4280 = min(sqrt(max(rough - 0.100000001490116119384765625, 0.0) * 1.111111164093017578125) * 6.0, 5.999000072479248046875);\n    float _4288 = min(sqrt(clamp(ndv, 0.0, 1.0)) * 8.0, 7.999000072479248046875);\n    int _4291 = int(_4280);\n    int _4294 = int(_4288);\n    float _4304 = _4288 - float(_4294);\n    int _4359 = (_4291 * 9) + _4294;\n    int _4379 = ((_4291 + 1) * 9) + _4294;\n    return mix(mix(_4355[_4359], _4355[_4359 + 1], _4304), mix(_4355[_4379], _4355[_4379 + 1], _4304), _4280 - float(_4291));\n}\n\nFaLayers fa_layers_setup(SurfaceInput i, Surface s, vec3 n, vec3 v, float metallic, float roughness, inout vec3 f0)\n{\n    bool _9004 = false;\n    float _9005 = 1.0;\n    float _9006 = 1.0;\n    float _9007 = 1.0;\n    float _9008 = 0.0;\n    float _9009 = 0.0;\n    float _9010 = 0.0;\n    float _9011 = 0.0;\n    float _9013 = 1.0;\n    bool _9014 = false;\n    vec3 _9015 = vec3(0.0);\n    float _9016 = 1.0;\n    float _9017 = 1.0;\n    float _9018 = 1.0;\n    float _9019 = 0.0;\n    float _9020 = 0.0;\n    vec3 _9021 = vec3(1.0, 0.0, 0.0);\n    vec3 _9022 = vec3(0.0, 0.0, 1.0);\n    float _9023 = 1.0;\n    float _9024 = 1.0;\n    float _4430 = clamp(s.specular, 0.0, 1.0);\n    float _4434 = clamp(s.ior, 1.0, 3.0);\n    bool _4439 = (_4430 != 1.0) || (_4434 != 1.5);\n    bool _4448;\n    if (!_4439)\n    {\n        _4448 = any(notEqual(s.specular_color, vec3(1.0)));\n    }\n    else\n    {\n        _4448 = _4439;\n    }\n    if (_4448)\n    {\n        float _4456 = (_4434 - 1.0) / (_4434 + 1.0);\n        f0 = mix(min(vec3(_4456 * _4456) * max(s.specular_color, vec3(0.0)), vec3(1.0)) * _4430, s.albedo, vec3(metallic));\n        _9005 = mix(_4430, 1.0, metallic);\n        _9004 = true;\n    }\n    float _4483 = clamp(s.clearcoat, 0.0, 1.0);\n    if (_4483 > 0.0)\n    {\n        float _4491 = clamp(s.clearcoat_roughness, 0.0500000007450580596923828125, 1.0);\n        _9008 = _4483;\n        _9009 = _4491;\n        float _4498 = _4491 * _4491;\n        _9010 = _4498;\n        _9011 = _4498 * _4498;\n        float _4510 = max(dot(i.world_normal, v), 9.9999997473787516355514526367188e-05);\n        _9013 = _4510;\n        _9006 = 1.0 - (_4483 * (0.039999999105930328369140625 + (0.959999978542327880859375 * pow(clamp(1.0 - _4510, 0.0, 1.0), 5.0))));\n        _9004 = true;\n    }\n    vec3 _4529 = max(s.sheen_color, vec3(0.0));\n    float _4538 = max(_4529.x, max(_4529.y, _4529.z));\n    if (_4538 > 0.0)\n    {\n        float _4546 = clamp(s.sheen_roughness, 0.100000001490116119384765625, 1.0);\n        _9014 = true;\n        _9015 = _4529;\n        _9016 = _4546;\n        _9017 = _4546 * _4546;\n        float param = max(dot(n, v), 9.9999997473787516355514526367188e-05);\n        float param_1 = _4546;\n        float _4563 = fa_sheen_albedo(param, param_1);\n        _9019 = _4563;\n        _9018 = 1.0 - min(_4538 * _4563, 1.0);\n        _9004 = true;\n    }\n    _9007 = _9006 * _9018;\n    float _4582 = clamp(s.anisotropy, -1.0, 1.0);\n    if (_4582 != 0.0)\n    {\n        vec3 _4597 = i.world_tangent.xyz - (n * dot(n, i.world_tangent.xyz));\n        vec3 t = _4597;\n        if (dot(_4597, _4597) < 9.9999999392252902907785028219223e-09)\n        {\n            bvec3 _4609 = bvec3(abs(n.y) < 0.9900000095367431640625);\n            t = cross(vec3(_4609.x ? vec3(0.0, 1.0, 0.0).x : vec3(1.0, 0.0, 0.0).x, _4609.y ? vec3(0.0, 1.0, 0.0).y : vec3(1.0, 0.0, 0.0).y, _4609.z ? vec3(0.0, 1.0, 0.0).z : vec3(1.0, 0.0, 0.0).z), n);\n        }\n        vec3 _4613 = t;\n        vec3 _4614 = normalize(_4613);\n        t = _4614;\n        vec3 _4639 = normalize((_4614 * cos(s.anisotropy_rotation)) + ((cross(n, _4614) * ((i.world_tangent.w < 0.0) ? (-1.0) : 1.0)) * sin(s.anisotropy_rotation)));\n        _9021 = _4639;\n        _9022 = cross(n, _4639);\n        float _4649 = roughness * roughness;\n        float _4655 = mix(_4649, 1.0, _4582 * _4582);\n        bool _4657 = _4582 > 0.0;\n        _9023 = _4657 ? _4655 : _4649;\n        _9024 = _4657 ? _4649 : _4655;\n        _9020 = _4582;\n        _9004 = true;\n    }\n    return FaLayers(_9004, _9005, _9006, _9007, _9008, _9009, _9010, _9011, i.world_normal, _9013, _9014, _9015, _9016, _9017, _9018, _9019, _9020, _9021, _9022, _9023, _9024);\n}\n\nvec2 fa_atlas_size()\n{\n    return vec2(textureSize(fa_probe_atlas_fa_env_smp, 0));\n}\n\nvec3 fa_probe_sh_coef(vec2 origin, float res, int k)\n{\n    vec3 v = textureLod(fa_probe_atlas_fa_env_smp, (origin + vec2(float(k) + 0.5, res + 2.5)) / fa_atlas_size(), 0.0).xyz;\n    if (fa_mesh_fs_params[41].y > 0.5)\n    {\n        v = ((v * 255.0) - vec3(128.0)) * 0.03149606287479400634765625;\n    }\n    return v;\n}\n\nvec3 fa_sh_eval(vec3 c[9], vec3 n)\n{\n    vec3 _3448 = max((((c[0] * 0.2820948064327239990234375) + (((c[1] * (0.3257350027561187744140625 * n.y)) + (c[2] * (0.3257350027561187744140625 * n.z))) + (c[3] * (0.3257350027561187744140625 * n.x)))) + (((c[4] * ((0.2731371223926544189453125 * n.x) * n.y)) + (c[5] * ((0.2731371223926544189453125 * n.y) * n.z))) + (c[6] * (0.078847892582416534423828125 * (((3.0 * n.z) * n.z) - 1.0))))) + ((c[7] * ((0.2731371223926544189453125 * n.x) * n.z)) + (c[8] * (0.13656856119632720947265625 * ((n.x * n.x) - (n.y * n.y))))), vec3(0.0));\n    return _3448;\n}\n\nvec3 fa_ambient_light(vec3 n)\n{\n    float _4061 = (1.0 - fa_mesh_fs_params[42].w) - fa_mesh_fs_params[47].w;\n    vec3 amb = vec3(0.0);\n    bool _4066 = fa_mesh_fs_params[11].w > 0.5;\n    vec3 c[9];\n    for (int k = 0; k < 9; k++)\n    {\n        c[k] = vec3(0.0);\n    }\n    if (_4061 > 0.0005000000237487256526947021484375)\n    {\n        if (_4066)\n        {\n            for (int k_1 = 0; k_1 < 9; k_1++)\n            {\n                vec2 param = fa_mesh_fs_params[41].zw;\n                float param_1 = 128.0;\n                int param_2 = k_1;\n                c[k_1] = fa_probe_sh_coef(param, param_1, param_2) * _4061;\n            }\n        }\n        else\n        {\n            amb = fa_mesh_fs_params[1].xyz * _4061;\n        }\n    }\n    bool _4117 = fa_mesh_fs_params[42].w > 0.0;\n    if (_4117)\n    {\n        for (int k_2 = 0; k_2 < 9; k_2++)\n        {\n            vec2 param_3 = fa_mesh_fs_params[42].xy;\n            float param_4 = fa_mesh_fs_params[42].z;\n            int param_5 = k_2;\n            c[k_2] += (fa_probe_sh_coef(param_3, param_4, param_5) * fa_mesh_fs_params[42].w);\n        }\n    }\n    bool _4148 = fa_mesh_fs_params[47].w > 0.0;\n    if (_4148)\n    {\n        for (int k_3 = 0; k_3 < 9; k_3++)\n        {\n            vec2 param_6 = fa_mesh_fs_params[47].xy;\n            float param_7 = fa_mesh_fs_params[47].z;\n            int param_8 = k_3;\n            c[k_3] += (fa_probe_sh_coef(param_6, param_7, param_8) * fa_mesh_fs_params[47].w);\n        }\n    }\n    if ((_4066 || _4117) || _4148)\n    {\n        vec3 param_9[9] = c;\n        vec3 param_10 = n;\n        amb += fa_sh_eval(param_9, param_10);\n    }\n    return amb;\n}\n\nvec4 fa_gi_fetch(vec2 texel)\n{\n    return textureLod(fa_probe_atlas_fa_env_smp, texel / fa_atlas_size(), 0.0);\n}\n\nvec2 fa_oct_encode(vec3 d)\n{\n    vec3 _3468 = d / vec3(max((abs(d.x) + abs(d.y)) + abs(d.z), 9.9999999600419720025001879548654e-13));\n    float _3471 = _3468.x;\n    float _3473 = _3468.z;\n    vec2 e = vec2(_3471, _3473);\n    if (_3468.y < 0.0)\n    {\n        e = vec2((1.0 - abs(_3473)) * ((_3471 < 0.0) ? (-1.0) : 1.0), (1.0 - abs(_3471)) * ((_3473 < 0.0) ? (-1.0) : 1.0));\n    }\n    return e;\n}\n\nvec3 fa_gi_grid(int rec, vec3 n, vec3 v, out float cover)\n{\n    cover = 0.0;\n    int param = rec;\n    vec4 _7304 = fa_light_texel(param);\n    int param_1 = rec + 1;\n    vec4 _7309 = fa_light_texel(param_1);\n    int param_2 = rec + 2;\n    vec4 _7314 = fa_light_texel(param_2);\n    int param_3 = rec + 3;\n    vec4 _7319 = fa_light_texel(param_3);\n    bool _7322 = _7319.z < 0.5;\n    bool _7330;\n    if (!_7322)\n    {\n        _7330 = fa_atlas_size().y < 1155.0;\n    }\n    else\n    {\n        _7330 = _7322;\n    }\n    if (_7330)\n    {\n        return vec3(0.0);\n    }\n    float _7337 = max(_7304.w, 9.9999997473787516355514526367188e-05);\n    vec3 _7340 = _7309.xyz;\n    vec3 _7344 = _7304.xyz;\n    vec3 _7348 = (fa_world_pos - _7344) / vec3(_7337);\n    vec3 _7357 = min(_7348 + vec3(0.5), (_7340 - vec3(0.5)) - _7348);\n    float _7366 = min(_7357.x, min(_7357.y, _7357.z));\n    if (!(_7366 > 0.0))\n    {\n        return vec3(0.0);\n    }\n    vec3 _7381 = _7340 - vec3(1.0);\n    vec3 _7382 = clamp(_7348, vec3(0.0), _7381);\n    vec3 _7390 = min(floor(_7382), max(_7340 - vec3(2.0), vec3(0.0)));\n    vec3 _7394 = _7382 - _7390;\n    vec3 _7405 = fa_world_pos + (((n * 0.800000011920928955078125) + (v * 0.20000000298023223876953125)) * (0.20000000298023223876953125 * _7337));\n    int _7410 = int(_7314.y + 0.5);\n    float _7415 = 0.3257350027561187744140625 * n.y;\n    float _7419 = 0.3257350027561187744140625 * n.z;\n    float _7423 = 0.3257350027561187744140625 * n.x;\n    float _7430 = (0.2731371223926544189453125 * n.x) * n.y;\n    float _7437 = (0.2731371223926544189453125 * n.y) * n.z;\n    float _7446 = 0.078847892582416534423828125 * (((3.0 * n.z) * n.z) - 1.0);\n    float _7453 = (0.2731371223926544189453125 * n.x) * n.z;\n    float _7466 = 0.13656856119632720947265625 * ((n.x * n.x) - (n.y * n.y));\n    vec3 acc = vec3(0.0);\n    float wsum = 0.0;\n    int _7473 = 8 + int(_7319.w);\n    float _7500;\n    float _7513;\n    float _7527;\n    for (int k = 0; k < _7473; k++)\n    {\n        float _7486 = float(k & 1);\n        float _7490 = float((k >> 1) & 1);\n        float _7494 = float((k >> 2) & 1);\n        if (_7486 > 0.5)\n        {\n            _7500 = _7394.x;\n        }\n        else\n        {\n            _7500 = 1.0 - _7394.x;\n        }\n        if (_7490 > 0.5)\n        {\n            _7513 = _7394.y;\n        }\n        else\n        {\n            _7513 = 1.0 - _7394.y;\n        }\n        if (_7494 > 0.5)\n        {\n            _7527 = _7394.z;\n        }\n        else\n        {\n            _7527 = 1.0 - _7394.z;\n        }\n        float _7537 = (_7500 * _7513) * _7527;\n        if (!(_7537 > 0.0))\n        {\n            continue;\n        }\n        vec3 _7550 = min(_7390 + vec3(_7486, _7490, _7494), _7381);\n        int _7570 = int(((_7314.x + _7550.x) + (_7309.x * (_7550.y + (_7309.y * _7550.z)))) + 0.5);\n        vec2 _7585 = vec2(float(_7570 % _7410) * 10.0, 1024.0 + (float(_7570 / _7410) * 11.0));\n        vec2 param_4 = _7585 + vec2(9.5, 10.5);\n        vec4 _7593 = fa_gi_fetch(param_4);\n        bool _7596 = _7593.y < 0.5;\n        bool _7605;\n        if (!_7596)\n        {\n            _7605 = _7593.x > _7319.y;\n        }\n        else\n        {\n            _7605 = _7596;\n        }\n        if (_7605)\n        {\n            continue;\n        }\n        vec3 _7617 = _7405 - (_7344 + (_7550 * _7337));\n        float _7620 = length(_7617);\n        vec3 _7626 = _7617 / vec3(max(_7620, 9.9999997473787516355514526367188e-05));\n        float _7636 = max(9.9999997473787516355514526367188e-05, (dot(-_7626, n) + 1.0) * 0.5);\n        float w = _7537 * (_7636 * _7636);\n        vec3 param_5 = _7626;\n        vec2 param_6 = (_7585 + vec2(1.0)) + (((fa_oct_encode(param_5) * 0.5) + vec2(0.5)) * 8.0);\n        vec4 _7655 = fa_gi_fetch(param_6);\n        float _7662 = _7620 / max(_7314.z, 9.9999997473787516355514526367188e-05);\n        float _7665 = _7655.x;\n        if (_7662 > _7665)\n        {\n            float _7678 = max(_7655.y - (_7665 * _7665), 0.0);\n            float _7683 = _7662 - _7665;\n            float _7692 = _7678 / max(_7678 + (_7683 * _7683), 9.9999999600419720025001879548654e-13);\n            w *= ((_7692 * _7692) * _7692);\n        }\n        if (!(w > 0.0))\n        {\n            continue;\n        }\n        vec2 param_7 = _7585 + vec2(0.5, 10.5);\n        vec2 param_8 = _7585 + vec2(1.5, 10.5);\n        vec2 param_9 = _7585 + vec2(2.5, 10.5);\n        vec2 param_10 = _7585 + vec2(3.5, 10.5);\n        vec2 param_11 = _7585 + vec2(4.5, 10.5);\n        vec2 param_12 = _7585 + vec2(5.5, 10.5);\n        vec2 param_13 = _7585 + vec2(6.5, 10.5);\n        vec2 param_14 = _7585 + vec2(7.5, 10.5);\n        vec2 param_15 = _7585 + vec2(8.5, 10.5);\n        acc += ((((((((((fa_gi_fetch(param_7).xyz * 0.2820948064327239990234375) + (fa_gi_fetch(param_8).xyz * _7415)) + (fa_gi_fetch(param_9).xyz * _7419)) + (fa_gi_fetch(param_10).xyz * _7423)) + (fa_gi_fetch(param_11).xyz * _7430)) + (fa_gi_fetch(param_12).xyz * _7437)) + (fa_gi_fetch(param_13).xyz * _7446)) + (fa_gi_fetch(param_14).xyz * _7453)) + (fa_gi_fetch(param_15).xyz * _7466)) * w);\n        wsum += w;\n    }\n    if (!(wsum > 9.9999997473787516355514526367188e-06))\n    {\n        return vec3(0.0);\n    }\n    cover = smoothstep(0.0, 1.0, clamp(_7366 * 2.0, 0.0, 1.0)) * smoothstep(0.0, 0.0199999995529651641845703125, wsum);\n    float _7817;\n    if (fa_mesh_fs_params[52].z > 0.5)\n    {\n        _7817 = _7319.x;\n    }\n    else\n    {\n        _7817 = 1.0;\n    }\n    return max(acc / vec3(wsum), vec3(0.0)) * (_7314.w * _7817);\n}\n\nvec3 fa_gi_light(vec3 n, inout float left)\n{\n    left = 1.0;\n    vec3 acc = vec3(0.0);\n    vec3 _7841 = normalize(fa_mesh_fs_params[0].xyz - fa_world_pos);\n    int _7846 = int(fa_mesh_fs_params[52].x + 0.5);\n    int _7851 = int(fa_mesh_fs_params[52].y + 0.5);\n    float param_3;\n    for (int k = 0; (k < _7851) && (k < 8); k++)\n    {\n        int param = _7846 + (4 * k);\n        vec3 param_1 = n;\n        vec3 param_2 = _7841;\n        vec3 _7876 = fa_gi_grid(param, param_1, param_2, param_3);\n        float _7881 = param_3 * left;\n        acc += (_7876 * _7881);\n        left -= _7881;\n        if (left < 0.001000000047497451305389404296875)\n        {\n            left = 0.0;\n            break;\n        }\n    }\n    return acc;\n}\n\nvec3 fa_realtime_or_ambient(vec3 n)\n{\n    vec3 gi = vec3(0.0);\n    float left = 1.0;\n    if (fa_mesh_fs_params[52].y > 0.5)\n    {\n        vec3 param = n;\n        float param_1;\n        vec3 _7910 = fa_gi_light(param, param_1);\n        left = param_1;\n        gi = _7910;\n    }\n    if (left <= 0.0)\n    {\n        return gi;\n    }\n    vec3 param_2 = n;\n    return gi + (fa_ambient_light(param_2) * left);\n}\n\nvec3 fa_indirect_diffuse(vec3 n)\n{\n    if (fa_lm.z > 0.5)\n    {\n        return textureLod(fa_lightmap_fa_env_smp, fa_lm.xy, 0.0).xyz;\n    }\n    if (fa_mesh_fs_params[32].w > 0.0)\n    {\n        vec3 c[9];\n        for (int k = 0; k < 9; k++)\n        {\n            c[k] = fa_mesh_fs_params[k * 1 + 32].xyz;\n        }\n        vec3 param = n;\n        vec3 param_1[9] = c;\n        vec3 param_2 = n;\n        return mix(fa_ambient_light(param), fa_sh_eval(param_1, param_2), vec3(clamp(fa_mesh_fs_params[32].w, 0.0, 1.0)));\n    }\n    vec3 param_3 = n;\n    return fa_realtime_or_ambient(param_3);\n}\n\nint fa_cluster_index(int slot, int n)\n{\n    int param = (int(fa_mesh_fs_params[19].x) + int(fa_mesh_fs_params[19].w)) + ((slot + n) >> 2);\n    vec4 t = fa_light_texel(param);\n    return int(t[(slot + n) & 3]);\n}\n\nint fa_cl_light(int n)\n{\n    if (n < fa_cl_ndir)\n    {\n        return n;\n    }\n    int param = fa_cl_slot;\n    int param_1 = n - fa_cl_ndir;\n    return fa_cluster_index(param, param_1);\n}\n\nint fa_light_base(int li)\n{\n    return li * ((fa_mesh_fs_params[1].w > 4.5) ? 8 : 4);\n}\n\nbool fa_light_baked(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 3;\n    return fa_light_texel(param_1).w > 0.5;\n}\n\nfloat fa_baked_keep(int li)\n{\n    float _5800;\n    if (fa_lm.z > 0.5)\n    {\n        _5800 = 0.0;\n    }\n    else\n    {\n        _5800 = 1.0 - clamp(fa_mesh_fs_params[32].w, 0.0, 1.0);\n    }\n    bool _5811 = _5800 < 1.0;\n    bool _5817;\n    if (_5811)\n    {\n        int param = li;\n        _5817 = fa_light_baked(param);\n    }\n    else\n    {\n        _5817 = _5811;\n    }\n    return _5817 ? _5800 : 1.0;\n}\n\nfloat fa_light_type(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 1;\n    return fa_light_texel(param_1).w;\n}\n\nvec4 fa_atlas_fetch(vec2 texel)\n{\n    return textureLod(fa_light_atlas_fa_env_smp, texel / vec2(textureSize(fa_light_atlas_fa_env_smp, 0)), 0.0);\n}\n\nvec3 fa_cookie_sample(vec2 tile_origin, vec2 uv)\n{\n    vec2 param = (tile_origin + vec2(1.0)) + (clamp(uv, vec2(0.0), vec2(1.0)) * 254.0);\n    return fa_atlas_fetch(param).xyz;\n}\n\nvec3 fa_area_point(vec3 c, vec3 axis, vec3 ru, vec3 uu, float hx, float hy, float shape, vec3 p, vec3 r)\n{\n    bool _837 = dot(r, r) > 0.5;\n    if (shape > 1.5)\n    {\n        vec3 _850 = (c - (ru * hx)) - p;\n        vec3 _856 = ru * (2.0 * hx);\n        float _862 = max(dot(_856, _856), 9.9999999392252902907785028219223e-09);\n        float _866 = dot(_850, _856);\n        float t = clamp((-_866) / _862, 0.0, 1.0);\n        if (_837)\n        {\n            float _881 = dot(r, _856);\n            float _887 = _862 - (_881 * _881);\n            if (abs(_887) > (9.9999997473787516355514526367188e-06 * _862))\n            {\n                t = clamp(((dot(r, _850) * _881) - _866) / _887, 0.0, 1.0);\n            }\n        }\n        return (p + _850) + (_856 * t);\n    }\n    vec3 q = p;\n    float _919 = dot(r, axis);\n    bool _927;\n    if (_837)\n    {\n        _927 = abs(_919) > 9.9999997473787516355514526367188e-05;\n    }\n    else\n    {\n        _927 = _837;\n    }\n    if (_927)\n    {\n        float _937 = dot(c - p, axis) / _919;\n        if (_937 > 0.0)\n        {\n            q = p + (r * _937);\n        }\n    }\n    vec3 _950 = q - c;\n    vec2 xy = vec2(dot(_950, ru), dot(_950, uu));\n    if (shape > 0.5)\n    {\n        float _965 = length(xy);\n        if (_965 > hx)\n        {\n            xy *= (hx / _965);\n        }\n    }\n    else\n    {\n        xy = clamp(xy, vec2(-hx, -hy), vec2(hx, hy));\n    }\n    return (c + (ru * xy.x)) + (uu * xy.y);\n}\n\nint fa_cube_face(vec3 d)\n{\n    vec3 _598 = abs(d);\n    float _600 = _598.x;\n    float _602 = _598.y;\n    bool _603 = _600 >= _602;\n    bool _611;\n    if (_603)\n    {\n        _611 = _600 >= _598.z;\n    }\n    else\n    {\n        _611 = _603;\n    }\n    int _612;\n    if (_611)\n    {\n        _612 = (d.x > 0.0) ? 0 : 1;\n    }\n    else\n    {\n        int _627;\n        if (_602 >= _598.z)\n        {\n            _627 = (d.y > 0.0) ? 2 : 3;\n        }\n        else\n        {\n            _627 = (d.z > 0.0) ? 4 : 5;\n        }\n        _612 = _627;\n    }\n    return _612;\n}\n\nvoid fa_cube_face_basis(int f, out vec3 fwd, out vec3 up)\n{\n    if (f == 0)\n    {\n        fwd = vec3(1.0, 0.0, 0.0);\n        up = vec3(0.0, 1.0, 0.0);\n    }\n    else\n    {\n        if (f == 1)\n        {\n            fwd = vec3(-1.0, 0.0, 0.0);\n            up = vec3(0.0, 1.0, 0.0);\n        }\n        else\n        {\n            if (f == 2)\n            {\n                fwd = vec3(0.0, 1.0, 0.0);\n                up = vec3(0.0, 0.0, 1.0);\n            }\n            else\n            {\n                if (f == 3)\n                {\n                    fwd = vec3(0.0, -1.0, 0.0);\n                    up = vec3(0.0, 0.0, -1.0);\n                }\n                else\n                {\n                    if (f == 4)\n                    {\n                        fwd = vec3(0.0, 0.0, 1.0);\n                        up = vec3(0.0, 1.0, 0.0);\n                    }\n                    else\n                    {\n                        fwd = vec3(0.0, 0.0, -1.0);\n                        up = vec3(0.0, 1.0, 0.0);\n                    }\n                }\n            }\n        }\n    }\n}\n\nfloat fa_ies_sample(vec2 tile_origin, vec3 d, vec3 axis, vec3 right, vec3 up)\n{\n    float _757 = dot(d, right);\n    float _761 = dot(d, up);\n    float _772;\n    if (((_757 * _757) + (_761 * _761)) > 1.0000000133514319600180897396058e-10)\n    {\n        _772 = atan(_761, _757) * 0.15915493667125701904296875;\n    }\n    else\n    {\n        _772 = 0.0;\n    }\n    vec2 param = tile_origin + vec2(1.0 + ((_772 - floor(_772)) * 64.0), 1.0 + (acos(clamp(dot(d, axis), -1.0, 1.0)) * 10.18591594696044921875));\n    return fa_atlas_fetch(param).x;\n}\n\nLightSample fa_light_sample_n(int li, vec3 world_pos, vec3 n)\n{\n    int param = li;\n    int _1003 = fa_light_base(param);\n    bool _1007 = fa_mesh_fs_params[1].w > 4.5;\n    int param_1 = _1003;\n    vec4 _1011 = fa_light_texel(param_1);\n    int param_2 = _1003 + 1;\n    vec4 _1016 = fa_light_texel(param_2);\n    float _1019 = _1016.w;\n    float atten = 1.0;\n    float dist = 0.0;\n    fa_light_tint = vec3(1.0);\n    bool _1031 = _1007 && (_1019 > 2.5);\n    fa_light_is_area = _1031;\n    bool _1033 = _1019 < 0.5;\n    vec3 l;\n    if (_1033)\n    {\n        l = normalize(_1011.xyz);\n        if (_1007)\n        {\n            int param_3 = _1003 + 6;\n            vec4 _1047 = fa_light_texel(param_3);\n            if (_1047.z > 0.5)\n            {\n                int param_4 = _1003 + 4;\n                vec4 _1057 = fa_light_texel(param_4);\n                int param_5 = _1003 + 5;\n                vec4 _1062 = fa_light_texel(param_5);\n                vec2 param_6 = _1047.xy;\n                vec2 param_7 = fract(vec2(dot(world_pos, _1057.xyz) * _1057.w, (-dot(world_pos, _1062.xyz)) * _1062.w) + vec2(0.5));\n                fa_light_tint = fa_cookie_sample(param_6, param_7);\n            }\n        }\n    }\n    else\n    {\n        vec3 _1092 = _1011.xyz;\n        vec3 _1094 = _1092 - world_pos;\n        vec3 to_light = _1094;\n        float _1097 = length(_1094);\n        float reach = _1097;\n        bool front = true;\n        if (_1031)\n        {\n            int param_8 = _1003 + 7;\n            reach = max(_1097 - fa_light_texel(param_8).w, 0.0);\n            int param_9 = _1003 + 4;\n            vec4 _1121 = fa_light_texel(param_9);\n            int param_10 = _1003 + 5;\n            vec4 _1126 = fa_light_texel(param_10);\n            int param_11 = _1003 + 6;\n            vec4 _1131 = fa_light_texel(param_11);\n            float _1132 = _1131.w;\n            int param_12 = _1003 + 2;\n            vec3 _1139 = normalize(fa_light_texel(param_12).xyz);\n            bool _1141 = _1132 > 1.5;\n            bool _1149;\n            if (!_1141)\n            {\n                _1149 = dot(_1139, to_light) < 0.0;\n            }\n            else\n            {\n                _1149 = _1141;\n            }\n            front = _1149;\n            vec3 r = vec3(0.0);\n            vec3 _1158 = fa_mesh_fs_params[0].xyz - world_pos;\n            bool _1162 = dot(n, n) > 0.5;\n            bool _1170;\n            if (_1162)\n            {\n                _1170 = dot(_1158, _1158) > 9.9999999600419720025001879548654e-13;\n            }\n            else\n            {\n                _1170 = _1162;\n            }\n            if (_1170)\n            {\n                r = reflect(-normalize(_1158), normalize(n));\n            }\n            vec3 param_13 = _1092;\n            vec3 param_14 = _1139;\n            vec3 param_15 = _1121.xyz;\n            vec3 param_16 = _1126.xyz;\n            float param_17 = _1121.w;\n            float param_18 = _1126.w;\n            float param_19 = _1132;\n            vec3 param_20 = world_pos;\n            vec3 param_21 = r;\n            to_light = fa_area_point(param_13, param_14, param_15, param_16, param_17, param_18, param_19, param_20, param_21) - world_pos;\n        }\n        float _1206 = length(to_light);\n        dist = _1206;\n        l = to_light / vec3(max(_1206, 9.9999997473787516355514526367188e-05));\n        float _1220 = reach / max(_1011.w, 0.001000000047497451305389404296875);\n        float _1226 = clamp(1.0 - (_1220 * _1220), 0.0, 1.0);\n        float _1228;\n        if (front)\n        {\n            _1228 = _1226 * _1226;\n        }\n        else\n        {\n            _1228 = 0.0;\n        }\n        atten = _1228;\n        bool _1239 = _1019 < 2.5;\n        if ((_1019 > 1.5) && _1239)\n        {\n            int param_22 = _1003 + 2;\n            vec4 _1247 = fa_light_texel(param_22);\n            float _1257 = _1247.w;\n            int param_23 = _1003 + 3;\n            vec4 _1262 = fa_light_texel(param_23);\n            float _1263 = _1262.x;\n            float cos_inner = _1263;\n            if (_1263 > 1.5)\n            {\n                cos_inner = mix(_1257, 1.0, 0.25);\n            }\n            atten *= smoothstep(_1257, cos_inner, dot(-l, normalize(_1247.xyz)));\n        }\n        if (_1007 && (_1019 < 1.5))\n        {\n            int param_24 = _1003 + 6;\n            vec4 _1287 = fa_light_texel(param_24);\n            if (_1287.z > 0.5)\n            {\n                vec3 _1295 = -to_light;\n                int param_25 = _1003 + 4;\n                int param_26 = _1003 + 5;\n                vec3 _1309 = fa_light_texel(param_25).xyz;\n                vec3 _1313 = fa_light_texel(param_26).xyz;\n                vec3 _1322 = vec3(dot(_1295, _1309), dot(_1295, _1313), dot(_1295, cross(_1309, _1313)));\n                vec3 param_27 = _1322;\n                int _1326 = fa_cube_face(param_27);\n                int param_28 = _1326;\n                vec3 param_29;\n                vec3 param_30;\n                fa_cube_face_basis(param_28, param_29, param_30);\n                vec2 _1353 = vec2(dot(_1322, cross(param_29, param_30)), dot(_1322, param_30)) / vec2(max(dot(_1322, param_29), 9.9999997473787516355514526367188e-05));\n                int _1357 = _1326 / 3;\n                vec2 param_31 = _1287.xy + (vec2(float(_1326 - (_1357 * 3)), float(_1357)) * 256.0);\n                vec2 param_32 = vec2(0.5 + (0.5 * _1353.x), 0.5 - (0.5 * _1353.y));\n                fa_light_tint = fa_cookie_sample(param_31, param_32);\n            }\n            int param_33 = _1003 + 7;\n            vec4 _1387 = fa_light_texel(param_33);\n            if (_1387.z > 0.5)\n            {\n                int param_34 = _1003 + 2;\n                int param_35 = _1003 + 4;\n                int param_36 = _1003 + 5;\n                vec2 param_37 = _1387.xy;\n                vec3 param_38 = -l;\n                vec3 param_39 = normalize(fa_light_texel(param_34).xyz);\n                vec3 param_40 = fa_light_texel(param_35).xyz;\n                vec3 param_41 = fa_light_texel(param_36).xyz;\n                atten *= fa_ies_sample(param_37, param_38, param_39, param_40, param_41);\n            }\n        }\n        else\n        {\n            if (_1007 && _1239)\n            {\n                int param_42 = _1003 + 6;\n                vec4 _1434 = fa_light_texel(param_42);\n                int param_43 = _1003 + 7;\n                vec4 _1439 = fa_light_texel(param_43);\n                bool _1442 = _1434.z > 0.5;\n                bool _1449;\n                if (!_1442)\n                {\n                    _1449 = _1439.z > 0.5;\n                }\n                else\n                {\n                    _1449 = _1442;\n                }\n                if (_1449)\n                {\n                    int param_44 = _1003 + 2;\n                    vec4 _1456 = fa_light_texel(param_44);\n                    vec3 _1460 = normalize(_1456.xyz);\n                    int param_45 = _1003 + 4;\n                    vec4 _1465 = fa_light_texel(param_45);\n                    int param_46 = _1003 + 5;\n                    vec4 _1470 = fa_light_texel(param_46);\n                    if (_1442)\n                    {\n                        vec3 _1478 = -to_light;\n                        float _1485 = _1456.w;\n                        float _1501 = 0.5 / max(dot(_1478, _1460) * (sqrt(max(1.0 - (_1485 * _1485), 0.0)) / max(_1485, 0.001000000047497451305389404296875)), 9.9999997473787516355514526367188e-05);\n                        vec2 param_47 = _1434.xy;\n                        vec2 param_48 = vec2(0.5 + (dot(_1478, _1465.xyz) * _1501), 0.5 - (dot(_1478, _1470.xyz) * _1501));\n                        fa_light_tint = fa_cookie_sample(param_47, param_48);\n                    }\n                    if (_1439.z > 0.5)\n                    {\n                        vec2 param_49 = _1439.xy;\n                        vec3 param_50 = -l;\n                        vec3 param_51 = _1460;\n                        vec3 param_52 = _1465.xyz;\n                        vec3 param_53 = _1470.xyz;\n                        atten *= fa_ies_sample(param_49, param_50, param_51, param_52, param_53);\n                    }\n                }\n            }\n        }\n    }\n    vec3 _8992 = _1016.xyz * atten;\n    if (_1007)\n    {\n        _8992 *= fa_light_tint;\n    }\n    int _1570;\n    if (_1033)\n    {\n        _1570 = 0;\n    }\n    else\n    {\n        _1570 = ((_1019 > 1.5) && (_1019 < 2.5)) ? 2 : 1;\n    }\n    return LightSample(l, _8992, atten, 1.0, dist, _1570);\n}\n\nfloat fa_shadow_split_at(int i)\n{\n    float _2302;\n    if (i == 0)\n    {\n        _2302 = fa_shadows[24].x;\n    }\n    else\n    {\n        float _2318;\n        if (i == 1)\n        {\n            _2318 = fa_shadows[24].y;\n        }\n        else\n        {\n            float _2326;\n            if (i == 2)\n            {\n                _2326 = fa_shadows[24].z;\n            }\n            else\n            {\n                _2326 = fa_shadows[24].w;\n            }\n            _2318 = _2326;\n        }\n        _2302 = _2318;\n    }\n    return _2302;\n}\n\nfloat fa_shadow_depth(inout vec2 uv, vec4 rect)\n{\n    uv = clamp(uv, rect.xy, rect.zw);\n    return textureLod(fa_shadow_tex_fa_shadow_smp, uv, 0.0).x;\n}\n\nfloat fa_shadow_fetch(vec2 uv, vec4 rect, vec3 conv)\n{\n    vec2 param = uv;\n    vec4 param_1 = rect;\n    float _2359 = fa_shadow_depth(param, param_1);\n    float _2363;\n    if (conv.x < 0.5)\n    {\n        _2363 = _2359;\n    }\n    else\n    {\n        _2363 = (conv.y * conv.z) / (conv.z - (_2359 * (conv.z - conv.y)));\n    }\n    return _2363;\n}\n\nfloat fa_shadow_noise()\n{\n    return fract(52.98291778564453125 * fract(dot(gl_FragCoord.xy, vec2(0.067110560834407806396484375, 0.005837149918079376220703125))));\n}\n\nvec2 fa_shadow_vogel_turn(vec2 d)\n{\n    return vec2((d.x * (-0.737368881702423095703125)) - (d.y * 0.675490319728851318359375), (d.y * (-0.737368881702423095703125)) + (d.x * 0.675490319728851318359375));\n}\n\nfloat fa_shadow_filter(vec2 uv, vec4 rect, float zr, float texel_m, float unit, float reach, float plane, vec3 conv, int mode, float k)\n{\n    if (mode == 1)\n    {\n        vec2 param = uv;\n        vec4 param_1 = rect;\n        vec3 param_2 = conv;\n        return float(zr <= fa_shadow_fetch(param, param_1, param_2));\n    }\n    float _2409 = fa_shadow_noise() * 6.283185482025146484375;\n    vec2 _2415 = vec2(cos(_2409), sin(_2409));\n    vec2 dir = _2415;\n    float radius = 1.5;\n    if (mode == 2)\n    {\n        float _2424;\n        if (k < 0.0)\n        {\n            _2424 = (-k) / max(zr, 0.100000001490116119384765625);\n        }\n        else\n        {\n            _2424 = k;\n        }\n        float _2443 = clamp((_2424 * reach) / texel_m, 3.0, 12.0);\n        float sum = 0.0;\n        float cnt = 0.0;\n        for (int i = 0; i < 16; i++)\n        {\n            float _2462 = sqrt((float(i) + 0.5) * 0.0625) * _2443;\n            vec2 param_3 = uv + (dir * (fa_shadows[26].zw * _2462));\n            vec4 param_4 = rect;\n            vec3 param_5 = conv;\n            float _2476 = fa_shadow_fetch(param_3, param_4, param_5);\n            if (_2476 < (zr - (_2462 * plane)))\n            {\n                sum += _2476;\n                cnt += 1.0;\n            }\n            vec2 param_6 = dir;\n            dir = fa_shadow_vogel_turn(param_6);\n        }\n        if (cnt < 0.5)\n        {\n            return 1.0;\n        }\n        float _2504 = sum / cnt;\n        float _2514;\n        if (k < 0.0)\n        {\n            _2514 = (-k) / max(_2504, 0.0500000007450580596923828125);\n        }\n        else\n        {\n            _2514 = k;\n        }\n        radius = clamp(((max(zr - _2504, 0.0) * unit) * _2514) / texel_m, 1.5, 16.0);\n        dir = _2415;\n    }\n    float lit = 0.0;\n    int _2540 = (mode == 2) ? 24 : 16;\n    for (int i_1 = 0; i_1 < _2540; i_1++)\n    {\n        float _2559 = sqrt((float(i_1) + 0.5) / float(_2540)) * radius;\n        vec2 param_7 = uv + (dir * (fa_shadows[26].zw * _2559));\n        vec4 param_8 = rect;\n        vec3 param_9 = conv;\n        lit += float((zr - (_2559 * plane)) <= fa_shadow_fetch(param_7, param_8, param_9));\n        vec2 param_10 = dir;\n        dir = fa_shadow_vogel_turn(param_10);\n    }\n    return lit / float(_2540);\n}\n\nfloat fa_shadow_cascade(int ci, vec3 world, vec3 n, vec3 l)\n{\n    float _2605 = max(fa_shadows[ci * 1 + 20].y, 0.001000000047497451305389404296875);\n    float _2610 = clamp(dot(n, l), 0.0, 1.0);\n    float _2616 = sqrt(1.0 - (_2610 * _2610));\n    float _2624 = min(_2616 / max(_2610, 0.20000000298023223876953125), 4.0);\n    float _2629;\n    if (fa_shadows[26].y > 0.0)\n    {\n        _2629 = fa_shadows[26].y;\n    }\n    else\n    {\n        _2629 = 1.5 * fa_shadows[ci * 1 + 20].x;\n    }\n    vec4 _2654 = mat4(fa_shadows[ci * 4 + 0], fa_shadows[ci * 4 + 1], fa_shadows[ci * 4 + 2], fa_shadows[ci * 4 + 3]) * vec4(world + (n * (_2629 * _2616)), 1.0);\n    float _2661 = _2654.x;\n    bool _2664 = _2661 < fa_shadows[ci * 1 + 16].x;\n    bool _2673;\n    if (!_2664)\n    {\n        _2673 = _2661 > fa_shadows[ci * 1 + 16].z;\n    }\n    else\n    {\n        _2673 = _2664;\n    }\n    bool _2682;\n    if (!_2673)\n    {\n        _2682 = _2654.y < fa_shadows[ci * 1 + 16].y;\n    }\n    else\n    {\n        _2682 = _2673;\n    }\n    bool _2691;\n    if (!_2682)\n    {\n        _2691 = _2654.y > fa_shadows[ci * 1 + 16].w;\n    }\n    else\n    {\n        _2691 = _2682;\n    }\n    bool _2698;\n    if (!_2691)\n    {\n        _2698 = _2654.z > 1.0;\n    }\n    else\n    {\n        _2698 = _2691;\n    }\n    if (_2698)\n    {\n        return -1.0;\n    }\n    float _2706;\n    if (fa_shadows[26].x > 0.0)\n    {\n        _2706 = fa_shadows[26].x;\n    }\n    else\n    {\n        _2706 = 1.5 * fa_shadows[ci * 1 + 20].x;\n    }\n    vec2 param = _2654.xy;\n    vec4 param_1 = fa_shadows[ci * 1 + 16];\n    float param_2 = _2654.z - ((_2706 * (1.0 + (0.5 * _2624))) / _2605);\n    float param_3 = fa_shadows[ci * 1 + 20].x;\n    float param_4 = _2605;\n    float param_5 = _2605 * 0.25;\n    float param_6 = ((fa_shadows[ci * 1 + 20].x * min(_2624, 3.0)) * 0.5) / _2605;\n    vec3 param_7 = vec3(0.0);\n    int param_8 = int(fa_shadows[25].z + 0.5);\n    float param_9 = fa_shadows[25].w;\n    return fa_shadow_filter(param, param_1, param_2, param_3, param_4, param_5, param_6, param_7, param_8, param_9);\n}\n\nfloat fa_shadow_sun(vec3 world, vec3 n, vec3 l)\n{\n    if (fa_mesh_fs_params[5].z < 0.5)\n    {\n        return 1.0;\n    }\n    int _3084 = int(fa_shadows[25].x + 0.5);\n    if (_3084 < 1)\n    {\n        return 1.0;\n    }\n    float _3099 = dot(world - fa_shadows[27].xyz, fa_shadows[28].xyz);\n    int param = _3084 - 1;\n    if (_3099 > fa_shadow_split_at(param))\n    {\n        return 1.0;\n    }\n    int ci = 0;\n    bool _3111 = _3084 > 1;\n    bool _3118;\n    if (_3111)\n    {\n        _3118 = _3099 > fa_shadows[24].x;\n    }\n    else\n    {\n        _3118 = _3111;\n    }\n    if (_3118)\n    {\n        ci = 1;\n    }\n    bool _3122 = _3084 > 2;\n    bool _3129;\n    if (_3122)\n    {\n        _3129 = _3099 > fa_shadows[24].y;\n    }\n    else\n    {\n        _3129 = _3122;\n    }\n    if (_3129)\n    {\n        ci = 2;\n    }\n    bool _3133 = _3084 > 3;\n    bool _3140;\n    if (_3133)\n    {\n        _3140 = _3099 > fa_shadows[24].z;\n    }\n    else\n    {\n        _3140 = _3133;\n    }\n    if (_3140)\n    {\n        ci = 3;\n    }\n    float s = -1.0;\n    float s2 = -1.0;\n    float t = 0.0;\n    int _3151 = min(_3084, 4);\n    float _3192;\n    for (int c = ci; c < _3151; c++)\n    {\n        int param_1 = c;\n        vec3 param_2 = world;\n        vec3 param_3 = n;\n        vec3 param_4 = l;\n        float _3171 = fa_shadow_cascade(param_1, param_2, param_3, param_4);\n        if (s >= 0.0)\n        {\n            s2 = _3171;\n            break;\n        }\n        if (_3171 < 0.0)\n        {\n            continue;\n        }\n        s = _3171;\n        ci = c;\n        if (fa_shadows[25].y > 0.0)\n        {\n            if (ci > 0)\n            {\n                int param_5 = ci - 1;\n                _3192 = fa_shadow_split_at(param_5);\n            }\n            else\n            {\n                _3192 = fa_shadows[28].w;\n            }\n            int param_6 = ci;\n            float _3211 = fa_shadows[25].y * max(fa_shadow_split_at(param_6) - _3192, 9.9999997473787516355514526367188e-05);\n            int param_7 = ci;\n            t = clamp((_3099 - (fa_shadow_split_at(param_7) - _3211)) / _3211, 0.0, 1.0);\n        }\n        if (t <= 0.0)\n        {\n            break;\n        }\n    }\n    if (s < 0.0)\n    {\n        return 1.0;\n    }\n    if (t > 0.0)\n    {\n        float _3243;\n        if ((ci + 1) < _3084)\n        {\n            _3243 = (s2 < 0.0) ? s : s2;\n        }\n        else\n        {\n            _3243 = 1.0;\n        }\n        s = mix(s, _3243, t);\n    }\n    return s;\n}\n\nfloat fa_shadow_factor(vec3 n, vec3 l)\n{\n    vec3 param = fa_world_pos;\n    vec3 param_1 = n;\n    vec3 param_2 = l;\n    return fa_shadow_sun(param, param_1, param_2);\n}\n\nfloat fa_shadow_local(int li, vec3 lpos, vec3 world, vec3 n, vec3 l)\n{\n    bool _2764 = fa_mesh_fs_params[5].z < 0.5;\n    bool _2771;\n    if (!_2764)\n    {\n        _2771 = fa_shadows[29].x < 0.5;\n    }\n    else\n    {\n        _2771 = _2764;\n    }\n    if (_2771)\n    {\n        return 1.0;\n    }\n    int param = (int(fa_shadows[29].x + 0.5) - 1) + li;\n    vec4 _2784 = fa_light_texel(param);\n    float _2785 = _2784.x;\n    if (_2785 < 0.0)\n    {\n        return 1.0;\n    }\n    int _2794 = int(_2785 + 0.5);\n    int param_1 = _2794;\n    vec4 _2798 = fa_light_texel(param_1);\n    int param_2 = _2794 + 1;\n    vec4 _2803 = fa_light_texel(param_2);\n    float fade = 1.0;\n    float _2806 = _2798.y;\n    if (_2806 > 0.0)\n    {\n        float _2823 = 1.0 - smoothstep(0.75 * _2806, _2806, length(world - fa_shadows[27].xyz));\n        fade = _2823;\n        if (_2823 <= 0.0)\n        {\n            return 1.0;\n        }\n    }\n    int face = 0;\n    if (_2798.x > 1.5)\n    {\n        vec3 param_3 = world - lpos;\n        face = fa_cube_face(param_3);\n    }\n    int _2847 = (_2794 + 2) + (face * 6);\n    int param_4 = _2847;\n    int param_5 = _2847 + 1;\n    int param_6 = _2847 + 3;\n    vec4 _2861 = fa_light_texel(param_6);\n    int param_7 = _2847 + 4;\n    vec4 _2866 = fa_light_texel(param_7);\n    int param_8 = _2847 + 5;\n    vec4 _2871 = fa_light_texel(param_8);\n    float _2883 = _2871.x * max(dot(_2861, vec4(world, 1.0)), 0.001000000047497451305389404296875);\n    float _2888 = clamp(dot(n, l), 0.0, 1.0);\n    float _2911 = clamp(dot(n, _2861.xyz), -1.0, 1.0);\n    float _2930 = min(sqrt(1.0 - (_2911 * _2911)) / max(abs(dot(n, world - lpos)) / max(dot(_2861, vec4(world, 1.0)), 0.001000000047497451305389404296875), 0.20000000298023223876953125), 4.0);\n    float _2933 = _2803.y;\n    float _2935;\n    if (_2933 > 0.0)\n    {\n        _2935 = _2933;\n    }\n    else\n    {\n        _2935 = 1.5 * _2883;\n    }\n    vec4 _2955 = vec4(world + (n * (_2935 * sqrt(1.0 - (_2888 * _2888)))), 1.0);\n    float _2959 = dot(_2861, _2955);\n    float _2962 = _2871.y;\n    if (_2959 < _2962)\n    {\n        return 1.0;\n    }\n    vec2 _2977 = vec2(dot(fa_light_texel(param_4), _2955), dot(fa_light_texel(param_5), _2955)) / vec2(_2959);\n    float _2979 = _2977.x;\n    bool _2982 = _2979 < _2866.x;\n    bool _2991;\n    if (!_2982)\n    {\n        _2991 = _2979 > _2866.z;\n    }\n    else\n    {\n        _2991 = _2982;\n    }\n    bool _3000;\n    if (!_2991)\n    {\n        _3000 = _2977.y < _2866.y;\n    }\n    else\n    {\n        _3000 = _2991;\n    }\n    bool _3009;\n    if (!_3000)\n    {\n        _3009 = _2977.y > _2866.w;\n    }\n    else\n    {\n        _3009 = _3000;\n    }\n    if (_3009)\n    {\n        return 1.0;\n    }\n    float _3015 = _2803.x;\n    float _3017;\n    if (_3015 > 0.0)\n    {\n        _3017 = _3015;\n    }\n    else\n    {\n        _3017 = 1.5 * _2883;\n    }\n    vec2 param_9 = _2977;\n    vec4 param_10 = _2866;\n    float param_11 = _2959 - (_3017 * (1.0 + (0.5 * _2930)));\n    float param_12 = _2883;\n    float param_13 = 1.0;\n    float param_14 = _2871.z * 0.25;\n    float param_15 = (_2883 * min(_2930, 3.0)) * 0.5;\n    vec3 param_16 = vec3(1.0, _2962, _2871.z);\n    int param_17 = int(_2798.z + 0.5);\n    float param_18 = _2798.w;\n    return mix(1.0, fa_shadow_filter(param_9, param_10, param_11, param_12, param_13, param_14, param_15, param_16, param_17, param_18), fade);\n}\n\nfloat fa_contact_shadow(int li, vec3 world, vec3 gn, vec3 l, float dist)\n{\n    bool _5173 = fa_mesh_fs_params[24].x < 0.5;\n    bool _5180;\n    if (!_5173)\n    {\n        _5180 = fa_shadows[29].x < 0.5;\n    }\n    else\n    {\n        _5180 = _5173;\n    }\n    if (_5180)\n    {\n        return 1.0;\n    }\n    int param = (int(fa_shadows[29].x + 0.5) - 1) + li;\n    vec4 _5193 = fa_light_texel(param);\n    float _5194 = _5193.y;\n    float len = _5194;\n    if (_5194 <= 0.0)\n    {\n        return 1.0;\n    }\n    float _5206 = length(world - fa_mesh_fs_params[0].xyz);\n    float _5216 = 1.0 - smoothstep(0.5 * fa_mesh_fs_params[25].x, fa_mesh_fs_params[25].x, _5206);\n    if (_5216 <= 0.0)\n    {\n        return 1.0;\n    }\n    float _5222 = len;\n    float _5225 = min(_5222, 0.89999997615814208984375 * dist);\n    len = _5225;\n    float _5230 = 0.004999999888241291046142578125 + (0.0030000000260770320892333984375 * _5206);\n    float _5235 = _5230 + (0.5 * _5225);\n    vec3 _5241 = world + (gn * _5230);\n    float _5243 = fa_shadow_noise();\n    float occ = 0.0;\n    float _5307;\n    for (int k = 0; k < 12; k++)\n    {\n        float _5258 = (float(k) + _5243) * 0.083333335816860198974609375;\n        vec3 _5266 = _5241 + (l * (_5258 * len));\n        vec4 _5272 = vec4(_5266, 1.0);\n        float _5278 = dot(fa_mesh_fs_params[28], _5272);\n        if (_5278 < 9.9999997473787516355514526367188e-05)\n        {\n            break;\n        }\n        vec2 _5298 = vec2(dot(fa_mesh_fs_params[26], _5272), dot(fa_mesh_fs_params[27], _5272)) / vec2(_5278);\n        float _5302 = _5298.x * 0.5;\n        float _5303 = _5302 + 0.5;\n        if (fa_mesh_fs_params[24].y > 0.5)\n        {\n            _5307 = (_5298.y * 0.5) + 0.5;\n        }\n        else\n        {\n            _5307 = 0.5 - (_5298.y * 0.5);\n        }\n        bool _5323 = _5303 < 0.0;\n        bool _5330;\n        if (!_5323)\n        {\n            _5330 = _5303 >= 1.0;\n        }\n        else\n        {\n            _5330 = _5323;\n        }\n        bool _5337;\n        if (!_5330)\n        {\n            _5337 = _5307 < 0.0;\n        }\n        else\n        {\n            _5337 = _5330;\n        }\n        bool _5344;\n        if (!_5337)\n        {\n            _5344 = _5307 >= 1.0;\n        }\n        else\n        {\n            _5344 = _5337;\n        }\n        if (_5344)\n        {\n            break;\n        }\n        vec4 _5371 = texelFetch(fa_screen_tex_fa_shadow_smp, clamp(ivec2(vec2(_5303, _5307) * fa_mesh_fs_params[24].zw), ivec2(0), ivec2(fa_mesh_fs_params[24].zw) - ivec2(1)), 0);\n        if (_5371.w < 0.5)\n        {\n            continue;\n        }\n        float _5390 = (dot(fa_mesh_fs_params[29].xyz, _5266) + fa_mesh_fs_params[29].w) - _5371.x;\n        if ((_5390 > _5230) && (_5390 < _5235))\n        {\n            occ = max(occ, (1.0 - (_5258 * _5258)) * smoothstep(0.0, 0.0500000007450580596923828125, min(min(_5303, 0.5 - _5302), min(_5307, 1.0 - _5307))));\n        }\n    }\n    return 1.0 - (occ * _5216);\n}\n\nLightSample fa_light_shadowed(int li, vec3 world_pos, vec3 gn)\n{\n    int param = li;\n    float _5856 = fa_baked_keep(param);\n    if (_5856 <= 0.0)\n    {\n        int param_1 = li;\n        return LightSample(vec3(0.0, 1.0, 0.0), vec3(0.0), 0.0, 1.0, 0.0, int(fa_light_type(param_1) + 0.5));\n    }\n    int param_2 = li;\n    vec3 param_3 = world_pos;\n    vec3 param_4 = gn;\n    LightSample _5882 = fa_light_sample_n(param_2, param_3, param_4);\n    vec3 _9061 = _5882.color;\n    float _9062 = _5882.attenuation;\n    float _9063 = _5882.shadow;\n    bool _5885 = _5882.type == 0;\n    if (_5885 && (li == 0))\n    {\n        vec3 param_5 = gn;\n        vec3 param_6 = _5882.direction;\n        float _5896 = fa_shadow_factor(param_5, param_6);\n        _9063 = _5896;\n        _9061 *= _5896;\n    }\n    else\n    {\n        bool _5907 = _5882.type != 0;\n        bool _5913;\n        if (_5907)\n        {\n            _5913 = _9062 > 0.0;\n        }\n        else\n        {\n            _5913 = _5907;\n        }\n        if (_5913)\n        {\n            int param_7 = li;\n            int param_8 = fa_light_base(param_7);\n            int param_9 = li;\n            vec3 param_10 = fa_light_texel(param_8).xyz;\n            vec3 param_11 = world_pos;\n            vec3 param_12 = gn;\n            vec3 param_13 = _5882.direction;\n            float _5932 = fa_shadow_local(param_9, param_10, param_11, param_12, param_13);\n            _9063 = _5932;\n            _9061 *= _5932;\n        }\n    }\n    bool _5942 = fa_mesh_fs_params[24].x > 0.5;\n    bool _5948;\n    if (_5942)\n    {\n        _5948 = _9062 > 0.0;\n    }\n    else\n    {\n        _5948 = _5942;\n    }\n    if (_5948)\n    {\n        float _5955;\n        if (_5885)\n        {\n            _5955 = 1000000000.0;\n        }\n        else\n        {\n            _5955 = _5882._distance;\n        }\n        int param_14 = li;\n        vec3 param_15 = world_pos;\n        vec3 param_16 = gn;\n        vec3 param_17 = _5882.direction;\n        float param_18 = _5955;\n        float _5973 = fa_contact_shadow(param_14, param_15, param_16, param_17, param_18);\n        _9063 *= _5973;\n        _9061 *= _5973;\n    }\n    float _5986 = _9062;\n    float _5987 = _5986 * _5856;\n    _9062 = _5987;\n    vec3 _5991 = _9061;\n    vec3 _5992 = _5991 * _5856;\n    _9061 = _5992;\n    return LightSample(_5882.direction, _5992, _5987, _9063, _5882._distance, _5882.type);\n}\n\nvec3 fa_ltc_tangent(vec3 n, vec3 v)\n{\n    vec3 _6026 = v - (n * dot(v, n));\n    vec3 t = _6026;\n    float _6030 = dot(_6026, _6026);\n    float l2 = _6030;\n    if (_6030 < 1.0000000133514319600180897396058e-10)\n    {\n        vec3 _6040;\n        if (abs(n.z) < 0.999000012874603271484375)\n        {\n            _6040 = cross(n, vec3(0.0, 0.0, 1.0));\n        }\n        else\n        {\n            _6040 = cross(n, vec3(1.0, 0.0, 0.0));\n        }\n        t = _6040;\n        l2 = dot(_6040, _6040);\n    }\n    return t * inversesqrt(l2);\n}\n\nvec3 fa_ltc_local(vec3 t1, vec3 n, vec3 p)\n{\n    return vec3(dot(t1, p), dot(cross(n, t1), p), dot(n, p));\n}\n\nvec2 fa_ltc_uv(float roughness, float ndv)\n{\n    return ((vec2(clamp((roughness - 0.0500000007450580596923828125) * 1.0526316165924072265625, 0.0, 1.0), sqrt(clamp(1.0 - ndv, 0.0, 1.0))) * 63.0) + vec2(0.5)) * vec2(0.015625);\n}\n\nvec3 fa_oct_vertex(int j, vec3 pc, vec3 ex, vec3 ey)\n{\n    float _6427;\n    if ((j == 0) || (j == 7))\n    {\n        _6427 = 0.92387950420379638671875;\n    }\n    else\n    {\n        float _6437;\n        if ((j == 3) || (j == 4))\n        {\n            _6437 = -0.92387950420379638671875;\n        }\n        else\n        {\n            _6437 = ((j == 1) || (j == 6)) ? 0.3826834261417388916015625 : (-0.3826834261417388916015625);\n        }\n        _6427 = _6437;\n    }\n    float _6458;\n    if ((j == 1) || (j == 2))\n    {\n        _6458 = 0.92387950420379638671875;\n    }\n    else\n    {\n        float _6467;\n        if ((j == 5) || (j == 6))\n        {\n            _6467 = -0.92387950420379638671875;\n        }\n        else\n        {\n            _6467 = ((j == 0) || (j == 3)) ? 0.3826834261417388916015625 : (-0.3826834261417388916015625);\n        }\n        _6458 = _6467;\n    }\n    return (pc + (ex * _6427)) + (ey * _6458);\n}\n\nvec3 fa_ltc_edge_vector(vec3 a, vec3 b)\n{\n    float _6075 = dot(a, a);\n    float _6079 = dot(b, b);\n    if ((_6075 < 1.0000000195414813782625560981111e-24) || (_6079 < 1.0000000195414813782625560981111e-24))\n    {\n        return vec3(0.0);\n    }\n    vec3 _6093 = a * inversesqrt(_6075);\n    vec3 _6098 = b * inversesqrt(_6079);\n    float _6102 = dot(_6093, _6098);\n    float _6105 = abs(_6102);\n    float g = (((((((((((0.0416471660137176513671875 * _6105) - 0.1924748718738555908203125) * _6105) + 0.4179156124591827392578125) * _6105) - 0.616057217121124267578125) * _6105) + 0.777722418308258056640625) * _6105) - 0.999542415142059326171875) * _6105) + 1.570791721343994140625;\n    if (_6102 < 0.0)\n    {\n        g = (3.1415927410125732421875 * inversesqrt(max(1.0 - (_6102 * _6102), 1.0000000116860974230803549289703e-07))) - g;\n    }\n    return cross(_6093, _6098) * g;\n}\n\nvoid fa_ltc_clip_edge(vec3 a, vec3 b, inout vec3 sum, inout vec3 leave, inout vec3 enter, inout vec2 seen)\n{\n    bool _6162 = a.z > 0.0;\n    bool _6166 = b.z > 0.0;\n    if (_6162 && _6166)\n    {\n        vec3 param = a;\n        vec3 param_1 = b;\n        sum += fa_ltc_edge_vector(param, param_1);\n    }\n    else\n    {\n        if (_6162 != _6166)\n        {\n            vec3 _6201 = a + ((b - a) * (a.z / (a.z - b.z)));\n            _6201.z = 0.0;\n            if (_6162)\n            {\n                vec3 param_2 = a;\n                vec3 param_3 = _6201;\n                sum += fa_ltc_edge_vector(param_2, param_3);\n                leave = _6201;\n                seen.x = 1.0;\n            }\n            else\n            {\n                vec3 param_4 = _6201;\n                vec3 param_5 = b;\n                sum += fa_ltc_edge_vector(param_4, param_5);\n                enter = _6201;\n                seen.y = 1.0;\n            }\n        }\n    }\n}\n\nfloat fa_ltc_quad(vec4 abcd, vec3 p0, vec3 p1, vec3 p2, vec3 p3)\n{\n    vec3 _6250 = vec3((abcd.x * p0.x) + (abcd.y * p0.z), p0.y, (abcd.z * p0.x) + (abcd.w * p0.z));\n    vec3 _6276 = vec3((abcd.x * p1.x) + (abcd.y * p1.z), p1.y, (abcd.z * p1.x) + (abcd.w * p1.z));\n    vec3 _6302 = vec3((abcd.x * p2.x) + (abcd.y * p2.z), p2.y, (abcd.z * p2.x) + (abcd.w * p2.z));\n    vec3 _6328 = vec3((abcd.x * p3.x) + (abcd.y * p3.z), p3.y, (abcd.z * p3.x) + (abcd.w * p3.z));\n    vec3 sum = vec3(0.0);\n    vec3 leave = vec3(0.0);\n    vec3 enter = vec3(0.0);\n    vec3 param = _6250;\n    vec3 param_1 = _6276;\n    vec3 param_2 = vec3(0.0);\n    vec3 param_3 = vec3(0.0);\n    vec3 param_4 = vec3(0.0);\n    vec2 param_5 = vec2(0.0);\n    fa_ltc_clip_edge(param, param_1, param_2, param_3, param_4, param_5);\n    sum = param_2;\n    leave = param_3;\n    enter = param_4;\n    vec3 param_6 = _6276;\n    vec3 param_7 = _6302;\n    vec3 param_8 = param_2;\n    vec3 param_9 = param_3;\n    vec3 param_10 = param_4;\n    vec2 param_11 = param_5;\n    fa_ltc_clip_edge(param_6, param_7, param_8, param_9, param_10, param_11);\n    sum = param_8;\n    leave = param_9;\n    enter = param_10;\n    vec3 param_12 = _6302;\n    vec3 param_13 = _6328;\n    vec3 param_14 = param_8;\n    vec3 param_15 = param_9;\n    vec3 param_16 = param_10;\n    vec2 param_17 = param_11;\n    fa_ltc_clip_edge(param_12, param_13, param_14, param_15, param_16, param_17);\n    sum = param_14;\n    leave = param_15;\n    enter = param_16;\n    vec3 param_18 = _6328;\n    vec3 param_19 = _6250;\n    vec3 param_20 = param_14;\n    vec3 param_21 = param_15;\n    vec3 param_22 = param_16;\n    vec2 param_23 = param_17;\n    fa_ltc_clip_edge(param_18, param_19, param_20, param_21, param_22, param_23);\n    sum = param_20;\n    leave = param_21;\n    enter = param_22;\n    if ((param_23.x * param_23.y) > 0.5)\n    {\n        vec3 param_24 = leave;\n        vec3 param_25 = enter;\n        sum += fa_ltc_edge_vector(param_24, param_25);\n    }\n    return sum.z * 0.15915493667125701904296875;\n}\n\nvec2 fa_area_forms(vec4 m, float shape, vec3 pc, vec3 ex, vec3 ey)\n{\n    int _6496 = ((shape < 0.5) || (shape > 1.5)) ? 1 : 3;\n    vec2 sum = vec2(0.0);\n    int _6514;\n    for (int k = 0; k < (2 * _6496); k++)\n    {\n        bool _6511 = k >= _6496;\n        if (_6511)\n        {\n            _6514 = k - _6496;\n        }\n        else\n        {\n            _6514 = k;\n        }\n        vec3 p0 = (pc - ex) - ey;\n        vec3 p1 = (pc + ex) - ey;\n        vec3 p2 = (pc + ex) + ey;\n        vec3 p3 = (pc - ex) + ey;\n        if (_6496 == 3)\n        {\n            int param = 0;\n            vec3 param_1 = pc;\n            vec3 param_2 = ex;\n            vec3 param_3 = ey;\n            p0 = fa_oct_vertex(param, param_1, param_2, param_3);\n            int _6560 = 2 * _6514;\n            int param_4 = _6560 + 1;\n            vec3 param_5 = pc;\n            vec3 param_6 = ex;\n            vec3 param_7 = ey;\n            p1 = fa_oct_vertex(param_4, param_5, param_6, param_7);\n            int param_8 = _6560 + 2;\n            vec3 param_9 = pc;\n            vec3 param_10 = ex;\n            vec3 param_11 = ey;\n            p2 = fa_oct_vertex(param_8, param_9, param_10, param_11);\n            int param_12 = _6560 + 3;\n            vec3 param_13 = pc;\n            vec3 param_14 = ex;\n            vec3 param_15 = ey;\n            p3 = fa_oct_vertex(param_12, param_13, param_14, param_15);\n        }\n        bvec4 _6597 = bvec4(_6511);\n        vec4 param_16 = vec4(_6597.x ? m.x : vec4(1.0, 0.0, 0.0, 1.0).x, _6597.y ? m.y : vec4(1.0, 0.0, 0.0, 1.0).y, _6597.z ? m.z : vec4(1.0, 0.0, 0.0, 1.0).z, _6597.w ? m.w : vec4(1.0, 0.0, 0.0, 1.0).w);\n        vec3 param_17 = p0;\n        vec3 param_18 = p1;\n        vec3 param_19 = p2;\n        vec3 param_20 = p3;\n        float _6608 = fa_ltc_quad(param_16, param_17, param_18, param_19, param_20);\n        if (_6511)\n        {\n            vec2 _9288 = sum;\n            _9288.y = _9288.y + _6608;\n            sum = _9288;\n        }\n        else\n        {\n            vec2 _9291 = sum;\n            _9291.x = _9291.x + _6608;\n            sum = _9291;\n        }\n    }\n    return abs(sum);\n}\n\nvec3 fa_area_shade(int li, vec3 world_pos, vec3 n, vec3 v, vec3 diffuse_color, vec3 f0, float f90, float roughness, float ndv, float window)\n{\n    int param = li;\n    int _6632 = fa_light_base(param);\n    int param_1 = _6632;\n    int param_2 = _6632 + 1;\n    int param_3 = _6632 + 2;\n    int param_4 = _6632 + 4;\n    vec4 _6654 = fa_light_texel(param_4);\n    int param_5 = _6632 + 5;\n    vec4 _6659 = fa_light_texel(param_5);\n    int param_6 = _6632 + 6;\n    vec4 _6664 = fa_light_texel(param_6);\n    float _6665 = _6664.w;\n    vec3 _6670 = fa_light_texel(param_1).xyz - world_pos;\n    bool _6672 = _6665 < 1.5;\n    bool _6679;\n    if (_6672)\n    {\n        _6679 = dot(normalize(fa_light_texel(param_3).xyz), _6670) >= 0.0;\n    }\n    else\n    {\n        _6679 = _6672;\n    }\n    if (_6679)\n    {\n        return vec3(0.0);\n    }\n    bool _6688 = (_6665 > 0.5) && _6672;\n    float _6692 = _6688 ? 1.0539000034332275390625 : 1.0;\n    vec3 _6695 = _6654.xyz;\n    float _6697 = _6654.w;\n    vec3 _6703 = _6659.xyz;\n    float _6705 = _6659.w;\n    vec3 up = _6703 * (_6705 * _6692);\n    float _6711;\n    if (_6688)\n    {\n        _6711 = (3.1415927410125732421875 * _6697) * _6697;\n    }\n    else\n    {\n        _6711 = (4.0 * _6697) * _6705;\n    }\n    if (_6665 > 1.5)\n    {\n        vec3 _6737 = cross(_6695, -_6670);\n        vec3 perp = _6737;\n        float _6741 = dot(_6737, _6737);\n        vec3 _6744;\n        if (_6741 > 1.0000000133514319600180897396058e-10)\n        {\n            _6744 = perp * inversesqrt(_6741);\n        }\n        else\n        {\n            _6744 = _6703;\n        }\n        perp = _6744;\n        up = _6744 * _6705;\n    }\n    float _6765 = max(_6711, 9.9999999747524270787835121154785e-07);\n    vec3 param_7 = n;\n    vec3 param_8 = v;\n    vec3 _6775 = fa_ltc_tangent(param_7, param_8);\n    vec3 param_9 = _6775;\n    vec3 param_10 = n;\n    vec3 param_11 = _6670;\n    vec3 param_12 = _6775;\n    vec3 param_13 = n;\n    vec3 param_14 = _6695 * (_6697 * _6692);\n    vec3 param_15 = _6775;\n    vec3 param_16 = n;\n    vec3 param_17 = up;\n    float param_18 = roughness;\n    float param_19 = ndv;\n    vec2 _6806 = fa_ltc_uv(param_18, param_19) * 64.0;\n    vec2 param_20 = _6806;\n    vec2 param_21 = _6806 + vec2(64.0, 0.0);\n    vec4 _6816 = fa_atlas_fetch(param_21);\n    vec4 param_22 = fa_atlas_fetch(param_20);\n    float param_23 = _6665;\n    vec3 param_24 = fa_ltc_local(param_9, param_10, param_11);\n    vec3 param_25 = fa_ltc_local(param_12, param_13, param_14);\n    vec3 param_26 = fa_ltc_local(param_15, param_16, param_17);\n    vec2 _6828 = fa_area_forms(param_22, param_23, param_24, param_25, param_26);\n    return (((diffuse_color * _6828.x) + (((f0 * _6816.x) + ((vec3(f90) - f0) * _6816.y)) * _6828.y)) * fa_light_texel(param_2).xyz) * ((((3.1415927410125732421875 * dot(_6670, _6670)) + _6765) / _6765) * window);\n}\n\nvec3 fa_light_rgb(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 1;\n    return fa_light_texel(param_1).xyz;\n}\n\nfloat fa_d_charlie(float alpha, float ndh)\n{\n    float _4910 = 1.0 / alpha;\n    return ((2.0 + _4910) * pow(sqrt(max(1.0 - (ndh * ndh), 9.9999997473787516355514526367188e-05)), _4910)) * 0.15915493667125701904296875;\n}\n\nfloat fa_v_ashikhmin(float ndl, float ndv)\n{\n    return clamp(0.25 / max((ndl + ndv) - (ndl * ndv), 9.9999997473787516355514526367188e-05), 0.0, 1.0);\n}\n\nfloat fa_layers_coat(FaLayers L, vec3 l, vec3 h, float vdh)\n{\n    float _4945 = max(dot(L.nc, l), 0.0);\n    float _4951 = max(dot(L.nc, h), 0.0);\n    float _4960 = ((_4951 * _4951) * (L.coat_a2 - 1.0)) + 1.0;\n    return (((L.coat * (0.039999999105930328369140625 + (0.959999978542327880859375 * pow(clamp(1.0 - vdh, 0.0, 1.0), 5.0)))) * (((L.coat_a2 / ((3.1415927410125732421875 * _4960) * _4960)) * (0.5 / max(mix((2.0 * _4945) * L.coat_ndv, _4945 + L.coat_ndv, L.coat_alpha), 9.9999997473787516355514526367188e-05))) * 3.1415927410125732421875)) * step(9.9999997473787516355514526367188e-05, _4945)) * _4945;\n}\n\nvec3 fa_area_layers(FaLayers L, vec3 base, int li, vec3 n, vec3 v, vec3 l, float ndv, float window)\n{\n    float _6865;\n    if (L.sheen_on)\n    {\n        _6865 = L.sheen_scale;\n    }\n    else\n    {\n        _6865 = 1.0;\n    }\n    vec3 result = base * (L.keep * _6865);\n    vec3 _6878 = normalize(l + v);\n    int param = li;\n    vec3 _6889 = fa_light_rgb(param) * window;\n    if (L.sheen_on)\n    {\n        float _6898 = max(dot(n, l), 0.0);\n        float param_1 = L.sheen_alpha;\n        float param_2 = max(dot(n, _6878), 0.0);\n        float param_3 = _6898;\n        float param_4 = ndv;\n        result += ((L.sheen * _6889) * (((((fa_d_charlie(param_1, param_2) * fa_v_ashikhmin(param_3, param_4)) * 3.1415927410125732421875) * step(9.9999997473787516355514526367188e-05, _6898)) * _6898) * L.keep));\n    }\n    if (L.coat > 0.0)\n    {\n        FaLayers param_5 = L;\n        vec3 param_6 = l;\n        vec3 param_7 = _6878;\n        float param_8 = max(dot(v, _6878), 0.0);\n        result += (_6889 * fa_layers_coat(param_5, param_6, param_7, param_8));\n    }\n    return result;\n}\n\nfloat fa_d_ggx_aniso(float ndh, float tdh, float bdh, float at, float ab)\n{\n    float _4813 = tdh / at;\n    float _4817 = bdh / ab;\n    float _4829 = ((_4813 * _4813) + (_4817 * _4817)) + (ndh * ndh);\n    return 1.0 / ((((3.1415927410125732421875 * at) * ab) * _4829) * _4829);\n}\n\nfloat fa_lambda_ggx_aniso(float n, float t, float b, float at, float ab)\n{\n    return 0.5 * (sqrt(1.0 + (((((at * at) * t) * t) + (((ab * ab) * b) * b)) / max(n * n, 9.9999999392252902907785028219223e-09))) - 1.0);\n}\n\nfloat fa_v_ggx_aniso(float ndl, float ndv, float tdv, float bdv, float tdl, float bdl, float at, float ab)\n{\n    float param = ndv;\n    float param_1 = tdv;\n    float param_2 = bdv;\n    float param_3 = at;\n    float param_4 = ab;\n    float param_5 = ndl;\n    float param_6 = tdl;\n    float param_7 = bdl;\n    float param_8 = at;\n    float param_9 = ab;\n    return clamp(1.0 / ((4.0 * max(ndl * ndv, 9.9999997473787516355514526367188e-05)) * ((1.0 + fa_lambda_ggx_aniso(param, param_1, param_2, param_3, param_4)) + fa_lambda_ggx_aniso(param_5, param_6, param_7, param_8, param_9))), 0.0, 1.0);\n}\n\nvec3 fa_layers_light(FaLayers L, vec3 diffuse_color, vec3 f0, vec3 n, vec3 v, vec3 l, vec3 h, float ndl, float ndv, float ndh, float vdh, float alpha, float a2)\n{\n    float _5009 = step(9.9999997473787516355514526367188e-05, ndl);\n    float d_ggx;\n    float vis;\n    if (L.aniso != 0.0)\n    {\n        float param = ndh;\n        float param_1 = dot(L.t, h);\n        float param_2 = dot(L.b, h);\n        float param_3 = L.at;\n        float param_4 = L.ab;\n        d_ggx = fa_d_ggx_aniso(param, param_1, param_2, param_3, param_4);\n        float param_5 = ndl;\n        float param_6 = ndv;\n        float param_7 = dot(L.t, v);\n        float param_8 = dot(L.b, v);\n        float param_9 = dot(L.t, l);\n        float param_10 = dot(L.b, l);\n        float param_11 = L.at;\n        float param_12 = L.ab;\n        vis = fa_v_ggx_aniso(param_5, param_6, param_7, param_8, param_9, param_10, param_11, param_12);\n    }\n    else\n    {\n        float _5088 = ((ndh * ndh) * (a2 - 1.0)) + 1.0;\n        d_ggx = a2 / ((3.1415927410125732421875 * _5088) * _5088);\n        vis = 0.5 / max(mix((2.0 * ndl) * ndv, ndl + ndv, alpha), 9.9999997473787516355514526367188e-05);\n    }\n    vec3 base = diffuse_color + (((f0 + ((vec3(L.f90) - f0) * pow(clamp(1.0 - vdh, 0.0, 1.0), 5.0))) * ((d_ggx * vis) * 3.1415927410125732421875)) * _5009);\n    if (L.sheen_on)\n    {\n        float param_13 = L.sheen_alpha;\n        float param_14 = ndh;\n        float param_15 = ndl;\n        float param_16 = ndv;\n        base = (base * L.sheen_scale) + (L.sheen * (((fa_d_charlie(param_13, param_14) * fa_v_ashikhmin(param_15, param_16)) * 3.1415927410125732421875) * _5009));\n    }\n    vec3 result = base * (L.keep * ndl);\n    if (L.coat > 0.0)\n    {\n        FaLayers param_17 = L;\n        vec3 param_18 = l;\n        vec3 param_19 = h;\n        float param_20 = vdh;\n        result += vec3(fa_layers_coat(param_17, param_18, param_19, param_20));\n    }\n    return result;\n}\n\nvec2 fa_env_brdf(float rough, float ndv)\n{\n    vec4 _4212 = (vec4(-1.0, -0.0274999998509883880615234375, -0.572000026702880859375, 0.02199999988079071044921875) * rough) + vec4(1.0, 0.0425000004470348358154296875, 1.03999996185302734375, -0.039999999105930328369140625);\n    float _4215 = _4212.x;\n    return (vec2(-1.03999996185302734375, 1.03999996185302734375) * ((min(_4215 * _4215, exp2((-9.27999973297119140625) * ndv)) * _4215) + _4212.y)) + _4212.zw;\n}\n\nvec3 fa_probe_level(vec2 origin, float res, int lv, vec2 e)\n{\n    float _3520;\n    if (lv == 0)\n    {\n        _3520 = 0.0;\n    }\n    else\n    {\n        _3520 = res + 2.0;\n    }\n    float _3530;\n    if (lv == 0)\n    {\n        _3530 = 0.0;\n    }\n    else\n    {\n        _3530 = (res - (res / float(1 << max((lv - 1), 0)))) + (2.0 * float(lv - 1));\n    }\n    return textureLod(fa_probe_atlas_fa_env_smp, (((origin + vec2(_3520, _3530)) + vec2(1.0)) + (((e * 0.5) + vec2(0.5)) * (res / float(1 << lv)))) / fa_atlas_size(), 0.0).xyz;\n}\n\nvec3 fa_probe_radiance(vec2 origin, float res, vec3 d, float rough)\n{\n    float _3576;\n    if (res > 64.5)\n    {\n        _3576 = 5.0;\n    }\n    else\n    {\n        _3576 = (res > 32.5) ? 4.0 : 3.0;\n    }\n    float _3591 = clamp(rough, 0.0, 1.0) * (_3576 - 1.0);\n    int _3598 = int(min(floor(_3591), _3576 - 2.0));\n    float _3603 = _3591 - float(_3598);\n    vec3 param = d;\n    vec2 _3607 = fa_oct_encode(param);\n    vec2 param_1 = origin;\n    float param_2 = res;\n    int param_3 = _3598;\n    vec2 param_4 = _3607;\n    vec3 _3617 = fa_probe_level(param_1, param_2, param_3, param_4);\n    if (_3603 < 0.00200000009499490261077880859375)\n    {\n        return _3617;\n    }\n    vec2 param_5 = origin;\n    float param_6 = res;\n    int param_7 = _3598 + 1;\n    vec2 param_8 = _3607;\n    return mix(_3617, fa_probe_level(param_5, param_6, param_7, param_8), vec3(_3603));\n}\n\nvec3 fa_probe_box_dir(vec3 d, vec4 posw, vec4 bx, vec4 by, vec4 bz)\n{\n    if (posw.w < 0.5)\n    {\n        return d;\n    }\n    float _3690 = dot(bx.xyz, fa_world_pos) + bx.w;\n    float _3697 = dot(by.xyz, fa_world_pos) + by.w;\n    float _3704 = dot(bz.xyz, fa_world_pos) + bz.w;\n    float _3710 = dot(bx.xyz, d);\n    float _3714 = dot(by.xyz, d);\n    float _3718 = dot(bz.xyz, d);\n    float _3724;\n    if (_3710 > 9.9999999747524270787835121154785e-07)\n    {\n        _3724 = (1.0 - _3690) / _3710;\n    }\n    else\n    {\n        float _3738;\n        if (_3710 < (-9.9999999747524270787835121154785e-07))\n        {\n            _3738 = ((-1.0) - _3690) / _3710;\n        }\n        else\n        {\n            _3738 = 1000000015047466219876688855040.0;\n        }\n        _3724 = _3738;\n    }\n    float tx = _3724;\n    float _3755;\n    if (_3714 > 9.9999999747524270787835121154785e-07)\n    {\n        _3755 = (1.0 - _3697) / _3714;\n    }\n    else\n    {\n        float _3768;\n        if (_3714 < (-9.9999999747524270787835121154785e-07))\n        {\n            _3768 = ((-1.0) - _3697) / _3714;\n        }\n        else\n        {\n            _3768 = 1000000015047466219876688855040.0;\n        }\n        _3755 = _3768;\n    }\n    float ty = _3755;\n    float _3784;\n    if (_3718 > 9.9999999747524270787835121154785e-07)\n    {\n        _3784 = (1.0 - _3704) / _3718;\n    }\n    else\n    {\n        float _3797;\n        if (_3718 < (-9.9999999747524270787835121154785e-07))\n        {\n            _3797 = ((-1.0) - _3704) / _3718;\n        }\n        else\n        {\n            _3797 = 1000000015047466219876688855040.0;\n        }\n        _3784 = _3797;\n    }\n    float _3809 = tx;\n    float _3812 = (_3809 > 0.0) ? _3809 : 1000000015047466219876688855040.0;\n    tx = _3812;\n    float _3813 = ty;\n    float _3816 = (_3813 > 0.0) ? _3813 : 1000000015047466219876688855040.0;\n    ty = _3816;\n    float _3826 = min(_3812, min(_3816, (_3784 > 0.0) ? _3784 : 1000000015047466219876688855040.0));\n    if (_3826 > 100000001504746621987668885504.0)\n    {\n        return d;\n    }\n    vec3 _3842 = (fa_world_pos + (d * _3826)) - posw.xyz;\n    vec3 _3847;\n    if (dot(_3842, _3842) > 1.0000000133514319600180897396058e-10)\n    {\n        _3847 = normalize(_3842);\n    }\n    else\n    {\n        _3847 = d;\n    }\n    return _3847;\n}\n\nvec3 fa_probe_environment(vec4 tile, vec4 posw, vec4 bx, vec4 by, vec4 bz, inout vec3 d, float rough)\n{\n    vec3 param = d;\n    vec4 param_1 = posw;\n    vec4 param_2 = bx;\n    vec4 param_3 = by;\n    vec4 param_4 = bz;\n    d = fa_probe_box_dir(param, param_1, param_2, param_3, param_4);\n    vec2 param_5 = tile.xy;\n    float param_6 = tile.z;\n    vec3 param_7 = d;\n    float param_8 = rough;\n    return fa_probe_radiance(param_5, param_6, param_7, param_8);\n}\n\nvec3 fa_environment(vec3 d, float rough)\n{\n    float _3893 = (1.0 - fa_mesh_fs_params[42].w) - fa_mesh_fs_params[47].w;\n    vec3 outc = vec3(0.0);\n    if (_3893 > 0.0005000000237487256526947021484375)\n    {\n        vec3 base;\n        if (fa_mesh_fs_params[11].w > 0.5)\n        {\n            vec2 param = fa_mesh_fs_params[41].zw;\n            float param_1 = 128.0;\n            vec3 param_2 = d;\n            float param_3 = rough;\n            base = fa_probe_radiance(param, param_1, param_2, param_3);\n        }\n        else\n        {\n            float _3921 = rough * rough;\n            float _3952 = 0.60000002384185791015625 * _3921;\n            base = mix(mix(fa_mesh_fs_params[12].xyz * 0.550000011920928955078125, mix(fa_mesh_fs_params[12].xyz, fa_mesh_fs_params[11].xyz, vec3(pow(clamp(d.y * (1.0 - (0.699999988079071044921875 * _3921)), 0.0, 1.0), 0.550000011920928955078125))), vec3(smoothstep((-0.0500000007450580596923828125) - _3952, 0.0500000007450580596923828125 + _3952, d.y))), ((fa_mesh_fs_params[11].xyz + fa_mesh_fs_params[12].xyz) * 0.5) * 0.800000011920928955078125, vec3(_3921 * 0.60000002384185791015625));\n        }\n        outc = base * _3893;\n    }\n    if (fa_mesh_fs_params[42].w > 0.0)\n    {\n        vec4 param_4 = fa_mesh_fs_params[42];\n        vec4 param_5 = fa_mesh_fs_params[43];\n        vec4 param_6 = fa_mesh_fs_params[44];\n        vec4 param_7 = fa_mesh_fs_params[45];\n        vec4 param_8 = fa_mesh_fs_params[46];\n        vec3 param_9 = d;\n        float param_10 = rough;\n        vec3 _4011 = fa_probe_environment(param_4, param_5, param_6, param_7, param_8, param_9, param_10);\n        outc += (_4011 * fa_mesh_fs_params[42].w);\n    }\n    if (fa_mesh_fs_params[47].w > 0.0)\n    {\n        vec4 param_11 = fa_mesh_fs_params[47];\n        vec4 param_12 = fa_mesh_fs_params[48];\n        vec4 param_13 = fa_mesh_fs_params[49];\n        vec4 param_14 = fa_mesh_fs_params[50];\n        vec4 param_15 = fa_mesh_fs_params[51];\n        vec3 param_16 = d;\n        float param_17 = rough;\n        vec3 _4043 = fa_probe_environment(param_11, param_12, param_13, param_14, param_15, param_16, param_17);\n        outc += (_4043 * fa_mesh_fs_params[47].w);\n    }\n    return outc;\n}\n\nvec3 fa_layers_ibl(FaLayers L, vec3 n, vec3 v, vec3 f0, float roughness, float occlusion)\n{\n    vec3 rn = n;\n    if (L.aniso != 0.0)\n    {\n        vec3 _4690;\n        if (L.aniso >= 0.0)\n        {\n            _4690 = L.b;\n        }\n        else\n        {\n            _4690 = L.t;\n        }\n        rn = normalize(mix(n, cross(cross(_4690, v), _4690), vec3(abs(L.aniso) * smoothstep(0.0, 0.25, roughness))));\n    }\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05);\n    vec2 _4726 = fa_env_brdf(param, param_1);\n    vec3 param_2 = reflect(-v, rn);\n    float param_3 = roughness;\n    vec3 result = (fa_environment(param_2, param_3) * ((f0 * _4726.x) + (vec3(L.f90) * _4726.y))) * L.base_scale;\n    if (L.sheen_on)\n    {\n        vec3 param_4 = n;\n        float param_5 = L.sheen_rough;\n        result += ((L.sheen * (L.sheen_e * L.keep)) * fa_environment(param_4, param_5));\n    }\n    result *= occlusion;\n    if (L.coat > 0.0)\n    {\n        float param_6 = L.coat_rough;\n        float param_7 = L.coat_ndv;\n        vec2 _4784 = fa_env_brdf(param_6, param_7);\n        vec3 param_8 = reflect(-v, L.nc);\n        float param_9 = L.coat_rough;\n        result += (fa_environment(param_8, param_9) * (L.coat * ((0.039999999105930328369140625 * _4784.x) + _4784.y)));\n    }\n    return result;\n}\n\nvec3 fa_sky_reflection(vec3 n, vec3 v, vec3 f0, float roughness)\n{\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05);\n    vec2 _4254 = fa_env_brdf(param, param_1);\n    vec3 param_2 = reflect(-v, n);\n    float param_3 = roughness;\n    return fa_environment(param_2, param_3) * ((f0 * _4254.x) + vec3(_4254.y));\n}\n\nvec2 fa_xm_size(int k)\n{\n    return max(floor(fa_mesh_fs_params[24].zw / vec2(float(1 << k))), vec2(1.0));\n}\n\nvec2 fa_xm_origin(int k)\n{\n    if (k == 0)\n    {\n        return vec2(0.0);\n    }\n    float y = 0.0;\n    for (int j = 1; j < k; j++)\n    {\n        int param = j;\n        y += fa_xm_size(param).y;\n    }\n    return vec2(fa_mesh_fs_params[24].z, y);\n}\n\nvec3 fa_xm_texel(vec2 size, vec2 origin, vec2 p)\n{\n    return texelFetch(fa_screen_tex_fa_shadow_smp, ivec2(origin + clamp(p, vec2(0.0), size - vec2(1.0))), 0).xyz;\n}\n\nvec3 fa_xm_level(int k, vec2 uv)\n{\n    int param = k;\n    vec2 _5494 = fa_xm_size(param);\n    int param_1 = k;\n    vec2 _5498 = fa_xm_origin(param_1);\n    vec2 _5504 = (uv * _5494) - vec2(0.5);\n    vec2 _5507 = fract(_5504);\n    vec2 _5510 = floor(_5504);\n    vec2 param_2 = _5494;\n    vec2 param_3 = _5498;\n    vec2 param_4 = _5510;\n    vec2 param_5 = _5494;\n    vec2 param_6 = _5498;\n    vec2 param_7 = _5510 + vec2(1.0, 0.0);\n    vec2 param_8 = _5494;\n    vec2 param_9 = _5498;\n    vec2 param_10 = _5510 + vec2(0.0, 1.0);\n    vec2 param_11 = _5494;\n    vec2 param_12 = _5498;\n    vec2 param_13 = _5510 + vec2(1.0);\n    vec3 _5552 = vec3(_5507.x);\n    return mix(mix(fa_xm_texel(param_2, param_3, param_4), fa_xm_texel(param_5, param_6, param_7), _5552), mix(fa_xm_texel(param_8, param_9, param_10), fa_xm_texel(param_11, param_12, param_13), _5552), vec3(_5507.y));\n}\n\nvec3 fa_xm_sample(vec2 uv, float lod)\n{\n    float _5571 = max(fa_mesh_fs_params[31].w - 1.0, 0.0);\n    float _5575 = clamp(lod, 0.0, _5571);\n    int _5579 = int(floor(_5575));\n    int param = _5579;\n    vec2 param_1 = uv;\n    vec3 c = fa_xm_level(param, param_1);\n    float _5589 = float(_5579);\n    float _5590 = _5575 - _5589;\n    bool _5592 = _5590 > 0.001000000047497451305389404296875;\n    bool _5599;\n    if (_5592)\n    {\n        _5599 = _5589 < _5571;\n    }\n    else\n    {\n        _5599 = _5592;\n    }\n    if (_5599)\n    {\n        int param_2 = _5579 + 1;\n        vec2 param_3 = uv;\n        c = mix(c, fa_xm_level(param_2, param_3), vec3(_5590));\n    }\n    return c;\n}\n\nvec3 fa_transmitted(Surface s, vec3 n, vec3 v, float roughness, vec3 f0, float f90, float keep, float tr, inout float blend)\n{\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05);\n    vec2 _5625 = fa_env_brdf(param, param_1);\n    vec3 through = ((vec3(1.0) - clamp((f0 * _5625.x) + (vec3(f90) * _5625.y), vec3(0.0), vec3(1.0))) * s.albedo) * (tr * keep);\n    float _5653 = max(s.thickness, 0.0);\n    bool _5658 = _5653 > 0.0;\n    if ((s.attenuation_distance > 0.0) && _5658)\n    {\n        through *= exp((-((-log(clamp(s.attenuation_color, vec3(9.9999997473787516355514526367188e-05), vec3(1.0)))) / vec3(s.attenuation_distance))) * _5653);\n    }\n    bool _5683 = fa_mesh_fs_params[30].w > 1.5;\n    bool _5690;\n    if (!_5683)\n    {\n        _5690 = fa_mesh_fs_params[30].w < 0.5;\n    }\n    else\n    {\n        _5690 = _5683;\n    }\n    if (_5690)\n    {\n        blend = clamp(dot(through, vec3(0.3333333432674407958984375)), 0.0, 0.980000019073486328125);\n        return vec3(0.0);\n    }\n    vec3 world = fa_world_pos;\n    if (_5658)\n    {\n        world += (refract(-v, n, 1.0 / max(s.ior, 1.0)) * _5653);\n    }\n    vec4 _5725 = vec4(world, 1.0);\n    float _5730 = dot(fa_mesh_fs_params[28], _5725);\n    vec2 uv = vec2(0.5);\n    if (_5730 > 9.9999997473787516355514526367188e-05)\n    {\n        vec2 _5748 = vec2(dot(fa_mesh_fs_params[26], _5725), dot(fa_mesh_fs_params[27], _5725)) / vec2(_5730);\n        float _5756;\n        if (fa_mesh_fs_params[24].y > 0.5)\n        {\n            _5756 = (_5748.y * 0.5) + 0.5;\n        }\n        else\n        {\n            _5756 = 0.5 - (_5748.y * 0.5);\n        }\n        uv = vec2((_5748.x * 0.5) + 0.5, _5756);\n    }\n    vec2 param_2 = clamp(uv, vec2(0.0), vec2(1.0));\n    float param_3 = (clamp(roughness, 0.0, 1.0) * clamp((2.0 * s.ior) - 2.0, 0.0, 1.0)) * max(fa_mesh_fs_params[31].w - 1.0, 0.0);\n    return through * fa_xm_sample(param_2, param_3);\n}\n\nvec3 fa_shadow_debug(vec3 color, vec3 world)\n{\n    if (fa_shadows[27].w < 0.5)\n    {\n        return color;\n    }\n    int _3271 = int(fa_shadows[25].x + 0.5);\n    float _3281 = dot(world - fa_shadows[27].xyz, fa_shadows[28].xyz);\n    vec3 tint = vec3(0.3499999940395355224609375);\n    bool _3286 = _3271 > 0;\n    bool _3295;\n    if (_3286)\n    {\n        int param = _3271 - 1;\n        _3295 = _3281 <= fa_shadow_split_at(param);\n    }\n    else\n    {\n        _3295 = _3286;\n    }\n    if (_3295)\n    {\n        tint = vec3(1.0, 0.1500000059604644775390625, 0.100000001490116119384765625);\n        bool _3301 = _3271 > 1;\n        bool _3308;\n        if (_3301)\n        {\n            _3308 = _3281 > fa_shadows[24].x;\n        }\n        else\n        {\n            _3308 = _3301;\n        }\n        if (_3308)\n        {\n            tint = vec3(0.100000001490116119384765625, 0.89999997615814208984375, 0.20000000298023223876953125);\n        }\n        bool _3314 = _3271 > 2;\n        bool _3321;\n        if (_3314)\n        {\n            _3321 = _3281 > fa_shadows[24].y;\n        }\n        else\n        {\n            _3321 = _3314;\n        }\n        if (_3321)\n        {\n            tint = vec3(0.1500000059604644775390625, 0.300000011920928955078125, 1.0);\n        }\n        bool _3327 = _3271 > 3;\n        bool _3334;\n        if (_3327)\n        {\n            _3334 = _3281 > fa_shadows[24].z;\n        }\n        else\n        {\n            _3334 = _3327;\n        }\n        if (_3334)\n        {\n            tint = vec3(1.0, 0.89999997615814208984375, 0.100000001490116119384765625);\n        }\n    }\n    return mix(color, tint, vec3(0.550000011920928955078125));\n}\n\nvoid main()\n{\n    fa_inst_load();\n    vec3 _8720 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _8720 = -_8720;\n    }\n    vec3 _8018 = normalize(fa_mesh_fs_params[0].xyz - fa_world_pos);\n    vec3 param = fa_world_pos;\n    fa_cluster_begin(param);\n    SurfaceInput param_1 = SurfaceInput(fa_world_pos, _8720, fa_world_tangent, fa_uv, fa_vertex_color, _8018, gl_FrontFacing);\n    Surface _8026 = fa_standard_surface(param_1);\n    vec3 _8751 = _8026.albedo;\n    float _8752 = _8026.alpha;\n    vec3 _8753 = _8026.normal;\n    float _8754 = _8026.metallic;\n    float _8755 = _8026.roughness;\n    float _8756 = _8026.occlusion;\n    vec3 _8757 = _8026.emission;\n    float _8758 = _8026.clearcoat;\n    float _8759 = _8026.clearcoat_roughness;\n    vec3 _8760 = _8026.sheen_color;\n    float _8761 = _8026.sheen_roughness;\n    float _8762 = _8026.anisotropy;\n    float _8763 = _8026.anisotropy_rotation;\n    float _8764 = _8026.specular;\n    float _8765 = _8026.ior;\n    vec3 _8766 = _8026.specular_color;\n    float _8767 = _8026.transmission;\n    float _8768 = _8026.thickness;\n    vec3 _8769 = _8026.attenuation_color;\n    float _8770 = _8026.attenuation_distance;\n    SurfaceInput param_2 = SurfaceInput(fa_world_pos, _8720, fa_world_tangent, fa_uv, fa_vertex_color, _8018, gl_FrontFacing);\n    Surface param_3 = _8026;\n    surface(param_2, param_3);\n    _8751 = param_3.albedo;\n    _8752 = param_3.alpha;\n    _8753 = param_3.normal;\n    _8754 = param_3.metallic;\n    _8755 = param_3.roughness;\n    _8756 = param_3.occlusion;\n    _8757 = param_3.emission;\n    _8758 = param_3.clearcoat;\n    _8759 = param_3.clearcoat_roughness;\n    _8760 = param_3.sheen_color;\n    _8761 = param_3.sheen_roughness;\n    _8762 = param_3.anisotropy;\n    _8763 = param_3.anisotropy_rotation;\n    _8764 = param_3.specular;\n    _8765 = param_3.ior;\n    _8766 = param_3.specular_color;\n    _8767 = param_3.transmission;\n    _8768 = param_3.thickness;\n    _8769 = param_3.attenuation_color;\n    _8770 = param_3.attenuation_distance;\n    vec3 param_4 = fa_world_pos;\n    vec3 param_5 = _8720;\n    vec3 param_6 = param_3.albedo;\n    vec3 param_7 = param_3.normal;\n    fa_apply_decals(param_4, param_5, param_6, param_7);\n    _8751 = param_6;\n    _8753 = param_7;\n    float fa_tr_blend = 0.0;\n    vec3 result;\n    if (fa_mesh_fs_params[3].w > 0.5)\n    {\n        result = _8751;\n    }\n    else\n    {\n        vec3 _8066 = normalize(_8753);\n        float _8073 = clamp(_8754, 0.0, 1.0);\n        float _8077 = clamp(_8755, 0.0500000007450580596923828125, 1.0);\n        float _8081 = _8077 * _8077;\n        float _8085 = _8081 * _8081;\n        float _8090 = max(dot(_8066, _8018), 9.9999997473787516355514526367188e-05);\n        float _8096 = 1.0 - _8073;\n        float _8097 = clamp(_8767, 0.0, 1.0) * _8096;\n        vec3 _8106 = (_8751 * _8096) * (1.0 - _8097);\n        vec3 _8113 = mix(vec3(0.039999999105930328369140625), _8751, vec3(_8073));\n        vec3 f0 = _8113;\n        SurfaceInput param_8 = SurfaceInput(fa_world_pos, _8720, fa_world_tangent, fa_uv, fa_vertex_color, _8018, gl_FrontFacing);\n        Surface param_9 = Surface(_8751, _8752, _8753, _8754, _8755, _8756, _8757, _8758, _8759, _8760, _8761, _8762, _8763, _8764, _8765, _8766, _8767, _8768, _8769, _8770);\n        vec3 param_10 = _8066;\n        vec3 param_11 = _8018;\n        float param_12 = _8073;\n        float param_13 = _8077;\n        vec3 param_14 = _8113;\n        FaLayers _8129 = fa_layers_setup(param_8, param_9, param_10, param_11, param_12, param_13, param_14);\n        f0 = param_14;\n        vec3 param_15 = _8066;\n        vec3 lit = (fa_indirect_diffuse(param_15) * _8106) * _8756;\n        if (_8129.on)\n        {\n            lit *= _8129.base_scale;\n        }\n        int _8151 = fa_cl_ndir + fa_cl_local;\n        float _8216;\n        for (int ln = 0; ln < _8151; ln++)\n        {\n            int param_16 = ln;\n            int _8164 = fa_cl_light(param_16);\n            int param_17 = _8164;\n            if (fa_baked_keep(param_17) <= 0.0)\n            {\n                continue;\n            }\n            int param_18 = _8164;\n            vec3 param_19 = fa_world_pos;\n            vec3 param_20 = _8720;\n            LightSample _8180 = fa_light_shadowed(param_18, param_19, param_20);\n            float _8188 = max(dot(_8066, _8180.direction), 0.0);\n            float _8194 = _8180.attenuation * _8180.shadow;\n            vec3 _8199 = normalize(_8180.direction + _8018);\n            float _8204 = max(dot(_8066, _8199), 0.0);\n            float _8209 = max(dot(_8018, _8199), 0.0);\n            if (fa_light_is_area)\n            {\n                if (_8129.on)\n                {\n                    _8216 = _8129.f90;\n                }\n                else\n                {\n                    _8216 = 1.0;\n                }\n                int param_21 = _8164;\n                vec3 param_22 = fa_world_pos;\n                vec3 param_23 = _8066;\n                vec3 param_24 = _8018;\n                vec3 param_25 = _8106;\n                vec3 param_26 = f0;\n                float param_27 = _8216;\n                float param_28 = _8077;\n                float param_29 = _8090;\n                float param_30 = _8194;\n                vec3 area = fa_area_shade(param_21, param_22, param_23, param_24, param_25, param_26, param_27, param_28, param_29, param_30);\n                if (_8129.on)\n                {\n                    FaLayers param_31 = _8129;\n                    vec3 param_32 = area;\n                    int param_33 = _8164;\n                    vec3 param_34 = _8066;\n                    vec3 param_35 = _8018;\n                    vec3 param_36 = _8180.direction;\n                    float param_37 = _8090;\n                    float param_38 = _8194;\n                    area = fa_area_layers(param_31, param_32, param_33, param_34, param_35, param_36, param_37, param_38);\n                }\n                lit += area;\n            }\n            else\n            {\n                if (_8129.on)\n                {\n                    FaLayers param_39 = _8129;\n                    vec3 param_40 = _8106;\n                    vec3 param_41 = f0;\n                    vec3 param_42 = _8066;\n                    vec3 param_43 = _8018;\n                    vec3 param_44 = _8180.direction;\n                    vec3 param_45 = _8199;\n                    float param_46 = _8188;\n                    float param_47 = _8090;\n                    float param_48 = _8204;\n                    float param_49 = _8209;\n                    float param_50 = _8081;\n                    float param_51 = _8085;\n                    int param_52 = _8164;\n                    lit += (fa_layers_light(param_39, param_40, param_41, param_42, param_43, param_44, param_45, param_46, param_47, param_48, param_49, param_50, param_51) * ((fa_light_rgb(param_52) * fa_light_tint) * _8194));\n                }\n                else\n                {\n                    float _8318 = ((_8204 * _8204) * (_8085 - 1.0)) + 1.0;\n                    int param_53 = _8164;\n                    lit += (((_8106 + (((f0 + ((vec3(1.0) - f0) * pow(1.0 - _8209, 5.0))) * (((_8085 / ((3.1415927410125732421875 * _8318) * _8318)) * (0.5 / max(mix((2.0 * _8188) * _8090, _8188 + _8090, _8081), 9.9999997473787516355514526367188e-05))) * 3.1415927410125732421875)) * step(9.9999997473787516355514526367188e-05, _8188))) * (fa_light_rgb(param_53) * fa_light_tint)) * (_8188 * _8194));\n                }\n            }\n        }\n        if (_8129.on)\n        {\n            FaLayers param_54 = _8129;\n            vec3 param_55 = _8066;\n            vec3 param_56 = _8018;\n            vec3 param_57 = f0;\n            float param_58 = _8077;\n            float param_59 = _8756;\n            lit += fa_layers_ibl(param_54, param_55, param_56, param_57, param_58, param_59);\n        }\n        else\n        {\n            vec3 param_60 = _8066;\n            vec3 param_61 = _8018;\n            vec3 param_62 = f0;\n            float param_63 = _8077;\n            lit += (fa_sky_reflection(param_60, param_61, param_62, param_63) * _8756);\n        }\n        if (_8097 > 0.0)\n        {\n            float _8416;\n            if (_8129.on)\n            {\n                _8416 = _8129.f90;\n            }\n            else\n            {\n                _8416 = 1.0;\n            }\n            float _8424;\n            if (_8129.on)\n            {\n                _8424 = _8129.base_scale;\n            }\n            else\n            {\n                _8424 = 1.0;\n            }\n            Surface param_64 = Surface(_8751, _8752, _8753, _8754, _8755, _8756, _8757, _8758, _8759, _8760, _8761, _8762, _8763, _8764, _8765, _8766, _8767, _8768, _8769, _8770);\n            vec3 param_65 = _8066;\n            vec3 param_66 = _8018;\n            float param_67 = _8077;\n            vec3 param_68 = f0;\n            float param_69 = _8416;\n            float param_70 = _8424;\n            float param_71 = _8097;\n            float param_72 = fa_tr_blend;\n            vec3 _8448 = fa_transmitted(param_64, param_65, param_66, param_67, param_68, param_69, param_70, param_71, param_72);\n            fa_tr_blend = param_72;\n            lit += _8448;\n        }\n        result = lit;\n    }\n    vec3 _8455 = result;\n    vec3 _8456 = _8455 + _8757;\n    result = _8456;\n    vec3 param_73 = _8456;\n    vec3 param_74 = fa_world_pos;\n    result = fa_shadow_debug(param_73, param_74);\n    bool _8465 = fa_mesh_fs_params[7].w > 0.0;\n    bool _8472;\n    if (!_8465)\n    {\n        _8472 = fa_mesh_fs_params[8].y > 0.0;\n    }\n    else\n    {\n        _8472 = _8465;\n    }\n    if (_8472)\n    {\n        vec3 _8481 = fa_world_pos - fa_mesh_fs_params[0].xyz;\n        float _8487 = dot(_8481, fa_mesh_fs_params[9].xyz);\n        bool _8491 = fa_mesh_fs_params[9].w > 0.5;\n        float _8492;\n        if (_8491)\n        {\n            _8492 = _8487;\n        }\n        else\n        {\n            _8492 = length(_8481);\n        }\n        float _8504 = _8492 - fa_mesh_fs_params[8].x;\n        if (_8504 > 0.0)\n        {\n            float _8513 = fa_mesh_fs_params[7].w * _8504;\n            float tau = _8513 * _8513;\n            if (fa_mesh_fs_params[8].y > 0.0)\n            {\n                float _8529;\n                if (_8491)\n                {\n                    _8529 = fa_world_pos.y - (fa_mesh_fs_params[9].y * _8487);\n                }\n                else\n                {\n                    _8529 = fa_mesh_fs_params[0].y;\n                }\n                float _8550 = mix(_8529, fa_world_pos.y, clamp(fa_mesh_fs_params[8].x / _8492, 0.0, 1.0));\n                float _8554 = fa_world_pos.y - _8550;\n                float _8559 = _8550 - fa_mesh_fs_params[8].z;\n                float _8564 = fa_world_pos.y - fa_mesh_fs_params[8].z;\n                bool _8567 = _8559 <= 0.0;\n                bool _8568 = !_8567;\n                bool _8574;\n                if (_8568)\n                {\n                    _8574 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _8574 = _8567;\n                }\n                float _8575;\n                if (_8574)\n                {\n                    _8575 = fa_mesh_fs_params[8].y;\n                }\n                else\n                {\n                    _8575 = fa_mesh_fs_params[8].y * exp(-min(fa_mesh_fs_params[8].w * _8559, 80.0));\n                }\n                bool _8602;\n                if (_8568)\n                {\n                    _8602 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _8602 = _8567;\n                }\n                float _8603;\n                if (_8602)\n                {\n                    _8603 = fa_mesh_fs_params[8].y * _8559;\n                }\n                else\n                {\n                    _8603 = (fa_mesh_fs_params[8].y * (1.0 - exp(-min(fa_mesh_fs_params[8].w * _8559, 80.0)))) / fa_mesh_fs_params[8].w;\n                }\n                bool _8628 = _8564 <= 0.0;\n                bool _8635;\n                if (!_8628)\n                {\n                    _8635 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _8635 = _8628;\n                }\n                float _8636;\n                if (_8635)\n                {\n                    _8636 = fa_mesh_fs_params[8].y * _8564;\n                }\n                else\n                {\n                    _8636 = (fa_mesh_fs_params[8].y * (1.0 - exp(-min(fa_mesh_fs_params[8].w * _8564, 80.0)))) / fa_mesh_fs_params[8].w;\n                }\n                float _8663;\n                if (abs(_8554) < 0.001000000047497451305389404296875)\n                {\n                    _8663 = _8575;\n                }\n                else\n                {\n                    _8663 = (_8636 - _8603) / _8554;\n                }\n                tau += (_8504 * max(_8663, 0.0));\n            }\n            result = mix(result, fa_mesh_fs_params[7].xyz, vec3(clamp(1.0 - exp(-clamp(tau, 0.0, 80.0)), 0.0, 1.0)));\n        }\n    }\n    if (fa_tr_blend > 0.0)\n    {\n        float _8699 = 1.0 - fa_tr_blend;\n        result /= vec3(_8699);\n        _8752 *= _8699;\n    }\n    fa_frag_color = vec4(result, _8752);\n}\n\n",
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
            "inst_name": "_180",
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
            "inst_name": "_225",
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
            "inst_name": "_366",
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
            "size": 848,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_650",
            "glsl_uniforms": [
              {
                "type": "vec4",
                "array_count": 53,
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
            "inst_name": "_2312",
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
      "vs": "#version 430\n\nstruct VertexData\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 color;\n    vec3 object_pos;\n};\n\nstruct points_item\n{\n    vec4 pos;\n    vec4 tint;\n};\n\nuniform vec4 fa_mesh_vs_params[11];\nlayout(binding = 0, std430) readonly buffer fa_vs_points_buf\n{\n    points_item data[];\n} fa_vs_points;\n\nuniform vec4 fa_vel_params[9];\nuniform vec4 fa_inst_base[4];\nlayout(location = 0) out vec3 fa_world_pos;\nlayout(location = 1) out vec3 fa_world_normal;\nlayout(location = 2) out vec4 fa_world_tangent;\nlayout(location = 3) out vec2 fa_uv;\nlayout(location = 4) out vec4 fa_vertex_color;\nlayout(location = 5) out float fa_pre_depth;\nlayout(location = 6) out vec3 fa_pre_r0;\nlayout(location = 7) out vec3 fa_pre_r1;\nlayout(location = 8) out vec3 fa_pre_r2;\nlayout(location = 9) out vec3 fa_vel_cur;\nlayout(location = 10) out vec3 fa_vel_prev;\nlayout(location = 0) in vec3 fa_position;\nlayout(location = 1) in vec3 fa_normal;\nlayout(location = 3) in vec4 fa_tangent;\nlayout(location = 2) in vec2 fa_texcoord0;\nlayout(location = 4) in vec4 fa_color;\nlayout(location = 5) in vec4 fa_inst_m0;\nlayout(location = 6) in vec4 fa_inst_m1;\nlayout(location = 7) in vec4 fa_inst_m2;\nlayout(location = 8) in vec4 fa_inst_m3;\nvec4 fa_vtime;\n\nvoid fa_inst_begin()\n{\n}\n\nvec4 fa_time_now()\n{\n    return fa_mesh_vs_params[9];\n}\n\nVertexData fa_vertex_data(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    vec3 _127 = cross(model[1].xyz, model[2].xyz);\n    float _131 = (dot(model[0].xyz, _127) < 0.0) ? (-1.0) : 1.0;\n    return VertexData((model * vec4(position, 1.0)).xyz, (((_127 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _131, vec4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _131), texcoord0 * fa_mesh_vs_params[8].xy, color, position);\n}\n\nvoid vertex(inout VertexData v)\n{\n    if (fa_vs_points.data[gl_InstanceID].pos.w < 0.5)\n    {\n        v.world_pos = vec3(1000000000.0);\n        return;\n    }\n    v.world_pos += fa_vs_points.data[gl_InstanceID].pos.xyz;\n    v.color = fa_vs_points.data[gl_InstanceID].tint;\n}\n\nvoid fa_prepass_vertex(mat4 model, mat4 prev_model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color, bool has_prev)\n{\n    bool _206;\n    if (has_prev)\n    {\n        _206 = fa_vel_params[8].x > 0.5;\n    }\n    else\n    {\n        _206 = has_prev;\n    }\n    fa_vtime = fa_time_now();\n    mat4 param = model;\n    vec3 param_1 = position;\n    vec3 param_2 = normal;\n    vec4 param_3 = tangent;\n    vec2 param_4 = texcoord0;\n    vec4 param_5 = color;\n    VertexData param_6 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    vertex(param_6);\n    mat4 _229 = mat4(fa_mesh_vs_params[4], fa_mesh_vs_params[5], fa_mesh_vs_params[6], fa_mesh_vs_params[7]);\n    vec4 _236 = vec4(param_6.world_pos, 1.0);\n    fa_world_pos = param_6.world_pos;\n    fa_world_normal = param_6.world_normal;\n    fa_world_tangent = param_6.world_tangent;\n    fa_uv = param_6.uv;\n    fa_vertex_color = param_6.color;\n    fa_pre_depth = -(_229 * _236).z;\n    fa_pre_r0 = vec3(_229[0].x, _229[1].x, _229[2].x);\n    fa_pre_r1 = vec3(_229[0].y, _229[1].y, _229[2].y);\n    fa_pre_r2 = vec3(_229[0].z, _229[1].z, _229[2].z);\n    gl_Position = mat4(fa_mesh_vs_params[0], fa_mesh_vs_params[1], fa_mesh_vs_params[2], fa_mesh_vs_params[3]) * _236;\n    fa_vel_cur = vec3(0.0, 0.0, 1.0);\n    fa_vel_prev = vec3(0.0);\n    if (_206)\n    {\n        fa_vtime.x = fa_vel_params[8].y;\n        mat4 param_7 = prev_model;\n        vec3 param_8 = position;\n        vec3 param_9 = normal;\n        vec4 param_10 = tangent;\n        vec2 param_11 = texcoord0;\n        vec4 param_12 = color;\n        VertexData param_13 = fa_vertex_data(param_7, param_8, param_9, param_10, param_11, param_12);\n        vertex(param_13);\n        fa_vel_cur = vec3((mat4(fa_vel_params[0], fa_vel_params[1], fa_vel_params[2], fa_vel_params[3]) * _236).xyw);\n        fa_vel_prev = vec3((mat4(fa_vel_params[4], fa_vel_params[5], fa_vel_params[6], fa_vel_params[7]) * vec4(param_13.world_pos, 1.0)).xyw);\n    }\n}\n\nvoid main()\n{\n    fa_vtime = vec4(0.0);\n    fa_inst_begin();\n    mat4 param = mat4(fa_inst_base[0], fa_inst_base[1], fa_inst_base[2], fa_inst_base[3]);\n    mat4 param_1 = mat4(vec4(1.0, 0.0, 0.0, 0.0), vec4(0.0, 1.0, 0.0, 0.0), vec4(0.0, 0.0, 1.0, 0.0), vec4(0.0, 0.0, 0.0, 1.0));\n    vec3 param_2 = fa_position;\n    vec3 param_3 = fa_normal;\n    vec4 param_4 = fa_tangent;\n    vec2 param_5 = fa_texcoord0;\n    vec4 param_6 = fa_color;\n    bool param_7 = false;\n    fa_prepass_vertex(param, param_1, param_2, param_3, param_4, param_5, param_6, param_7);\n}\n\n",
      "fs": "#version 430\n\nstruct SurfaceInput\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 vertex_color;\n    vec3 view_dir;\n    bool front_facing;\n};\n\nstruct Surface\n{\n    vec3 albedo;\n    float alpha;\n    vec3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    vec3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    vec3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    vec3 specular_color;\n    float transmission;\n    float thickness;\n    vec3 attenuation_color;\n    float attenuation_distance;\n};\n\nstruct points_item\n{\n    vec4 pos;\n    vec4 tint;\n};\n\nlayout(binding = 1, std430) readonly buffer fa_points_buf\n{\n    points_item data[];\n} points;\n\nuniform vec4 fa_mesh_fs_params[53];\nlayout(binding = 0) uniform sampler2D fa_tex_fa_smp;\nlayout(binding = 1) uniform sampler2D fa_normal_tex_fa_smp;\nlayout(binding = 2) uniform sampler2D fa_mr_tex_fa_smp;\nlayout(binding = 3) uniform sampler2D fa_occlusion_tex_fa_smp;\nlayout(binding = 4) uniform sampler2D fa_emissive_tex_fa_smp;\n\nlayout(location = 0) in vec3 fa_world_pos;\nlayout(location = 1) in vec3 fa_world_normal;\nlayout(location = 2) in vec4 fa_world_tangent;\nlayout(location = 3) in vec2 fa_uv;\nlayout(location = 4) in vec4 fa_vertex_color;\nlayout(location = 6) in vec3 fa_pre_r0;\nlayout(location = 7) in vec3 fa_pre_r1;\nlayout(location = 8) in vec3 fa_pre_r2;\nlayout(location = 0) out vec4 fa_frag_color;\nlayout(location = 5) in float fa_pre_depth;\nlayout(location = 9) in vec3 fa_vel_cur;\nlayout(location = 10) in vec3 fa_vel_prev;\nlayout(location = 1) out vec2 fa_frag_velocity;\n\nvoid fa_inst_load()\n{\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nvec3 fa_linear_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_tex_fix(inout vec3 c, float mode)\n{\n    if (mode > 1.5)\n    {\n        vec3 param = c;\n        vec3 _190 = fa_linear_to_srgb(param);\n        c = _190;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            vec3 param_1 = c;\n            vec3 _199 = fa_srgb_to_linear(param_1);\n            c = _199;\n        }\n    }\n    return c;\n}\n\nvec3 fa_tangent_normal(SurfaceInput i, vec3 m)\n{\n    vec3 _56;\n    if (i.front_facing)\n    {\n        _56 = i.world_normal;\n    }\n    else\n    {\n        _56 = -i.world_normal;\n    }\n    vec3 _81 = normalize(i.world_tangent.xyz - (_56 * dot(_56, i.world_tangent.xyz)));\n    vec3 _109 = normalize(((_81 * m.x) + ((cross(_56, _81) * i.world_tangent.w) * m.y)) + (_56 * m.z));\n    vec3 _112;\n    if (i.front_facing)\n    {\n        _112 = _109;\n    }\n    else\n    {\n        _112 = -_109;\n    }\n    return _112;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    vec4 base_t = texture(fa_tex_fa_smp, i.uv);\n    float param = fa_mesh_fs_params[6].w;\n    float param_1 = 1.0;\n    vec3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    vec3 _244 = fa_tex_fix(param_2, param_3);\n    vec4 _844 = base_t;\n    _844.x = _244.x;\n    _844.y = _244.y;\n    _844.z = _244.z;\n    base_t = _844;\n    vec4 _259 = (_844 * fa_mesh_fs_params[2]) * i.vertex_color;\n    vec3 _799 = i.world_normal;\n    if (fa_mesh_fs_params[6].z > 0.5)\n    {\n        float param_4 = fa_mesh_fs_params[6].w;\n        float param_5 = 16.0;\n        vec3 param_6 = texture(fa_normal_tex_fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        vec3 _292 = fa_tex_fix(param_6, param_7);\n        vec3 _296 = (_292 * 2.0) - vec3(1.0);\n        vec2 _301 = _296.xy * fa_mesh_fs_params[6].x;\n        vec3 _852 = _296;\n        _852.x = _301.x;\n        _852.y = _301.y;\n        SurfaceInput param_8 = i;\n        vec3 param_9 = _852;\n        _799 = fa_tangent_normal(param_8, param_9);\n    }\n    vec4 mrt = texture(fa_mr_tex_fa_smp, i.uv);\n    float param_10 = fa_mesh_fs_params[6].w;\n    float param_11 = 64.0;\n    vec3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    vec3 _330 = fa_tex_fix(param_12, param_13);\n    vec4 _855 = mrt;\n    _855.x = _330.x;\n    _855.y = _330.y;\n    _855.z = _330.z;\n    mrt = _855;\n    vec4 _360 = texture(fa_occlusion_tex_fa_smp, i.uv);\n    float param_14 = fa_mesh_fs_params[6].w;\n    float param_15 = 256.0;\n    vec3 param_16 = _360.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    vec3 _372 = fa_tex_fix(param_16, param_17);\n    float param_18 = fa_mesh_fs_params[6].w;\n    float param_19 = 4.0;\n    vec3 param_20 = texture(fa_emissive_tex_fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    vec3 _402 = fa_tex_fix(param_20, param_21);\n    float _804 = fa_mesh_fs_params[20].x;\n    float _805 = fa_mesh_fs_params[20].y;\n    float _808 = fa_mesh_fs_params[20].z;\n    float _807 = fa_mesh_fs_params[21].w;\n    float _810 = fa_mesh_fs_params[22].x;\n    if (fa_mesh_fs_params[22].z > 0.5)\n    {\n        if (mod(fa_mesh_fs_params[22].z, 2.0) > 0.5)\n        {\n            _804 *= _372.y;\n            _805 *= _372.z;\n            _807 *= _360.w;\n        }\n        if (fa_mesh_fs_params[22].z > 1.5)\n        {\n            _808 *= mrt.x;\n            _810 *= mrt.w;\n        }\n    }\n    return Surface(_259.xyz, _259.w, _799, clamp(fa_mesh_fs_params[5].x * _330.z, 0.0, 1.0), clamp(fa_mesh_fs_params[5].y * _330.y, 0.0500000007450580596923828125, 1.0), 1.0 + (fa_mesh_fs_params[6].y * (_372.x - 1.0)), fa_mesh_fs_params[3].xyz + (fa_mesh_fs_params[4].xyz * _402), _804, _805, fa_mesh_fs_params[21].xyz, _807, _808, fa_mesh_fs_params[20].w, _810, fa_mesh_fs_params[22].y, fa_mesh_fs_params[23].xyz, fa_mesh_fs_params[30].x, fa_mesh_fs_params[30].y, fa_mesh_fs_params[31].xyz, fa_mesh_fs_params[30].z);\n}\n\nvoid surface(SurfaceInput i, inout Surface s)\n{\n    s.emission += (i.vertex_color.xyz * points.data[0].tint.w);\n}\n\nvoid main()\n{\n    fa_inst_load();\n    vec3 _694 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _694 = -_694;\n    }\n    vec3 _555 = normalize(fa_mesh_fs_params[0].xyz - fa_world_pos);\n    SurfaceInput param = SurfaceInput(fa_world_pos, _694, fa_world_tangent, fa_uv, fa_vertex_color, _555, gl_FrontFacing);\n    SurfaceInput param_1 = SurfaceInput(fa_world_pos, _694, fa_world_tangent, fa_uv, fa_vertex_color, _555, gl_FrontFacing);\n    Surface param_2 = fa_standard_surface(param);\n    surface(param_1, param_2);\n    vec3 _570 = normalize(param_2.normal);\n    vec3 _585 = normalize(vec3(dot(fa_pre_r0, _570), dot(fa_pre_r1, _570), dot(fa_pre_r2, _570)));\n    float _597 = _585.z;\n    vec2 e = _585.xy / vec2((abs(_585.x) + abs(_585.y)) + abs(_597));\n    if (_597 < 0.0)\n    {\n        e = (vec2(1.0) - abs(e.yx)) * vec2((e.x >= 0.0) ? 1.0 : (-1.0), (e.y >= 0.0) ? 1.0 : (-1.0));\n    }\n    fa_frag_color = vec4(min(fa_pre_depth, 60000.0), e, 1.0);\n    vec2 motion = vec2(1024.0);\n    bool _641 = fa_vel_cur.z > 9.9999997473787516355514526367188e-06;\n    bool _648;\n    if (_641)\n    {\n        _648 = fa_vel_prev.z > 9.9999997473787516355514526367188e-06;\n    }\n    else\n    {\n        _648 = _641;\n    }\n    if (_648)\n    {\n        motion = clamp(((vec2(fa_vel_prev.x, -fa_vel_prev.y) / vec2(fa_vel_prev.z)) * 0.5) - ((vec2(fa_vel_cur.x, -fa_vel_cur.y) / vec2(fa_vel_cur.z)) * 0.5), vec2(-4.0), vec2(4.0));\n    }\n    fa_frag_velocity = motion;\n}\n\n",
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
            "inst_name": "_54",
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
            "inst_name": "_201",
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
            "inst_name": "_358",
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
            "size": 848,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_233",
            "glsl_uniforms": [
              {
                "type": "vec4",
                "array_count": 53,
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
      "vs": "#version 430\n\nstruct VertexData\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 color;\n    vec3 object_pos;\n};\n\nstruct points_item\n{\n    vec4 pos;\n    vec4 tint;\n};\n\nuniform vec4 fa_mesh_vs_params[11];\nlayout(binding = 0, std430) readonly buffer fa_vs_points_buf\n{\n    points_item data[];\n} fa_vs_points;\n\nuniform vec4 fa_skin[192];\nuniform vec4 fa_vel_params[9];\nuniform vec4 fa_inst_base[4];\nlayout(location = 0) out vec3 fa_world_pos;\nlayout(location = 1) out vec3 fa_world_normal;\nlayout(location = 2) out vec4 fa_world_tangent;\nlayout(location = 3) out vec2 fa_uv;\nlayout(location = 4) out vec4 fa_vertex_color;\nlayout(location = 5) out float fa_pre_depth;\nlayout(location = 6) out vec3 fa_pre_r0;\nlayout(location = 7) out vec3 fa_pre_r1;\nlayout(location = 8) out vec3 fa_pre_r2;\nlayout(location = 9) out vec3 fa_vel_cur;\nlayout(location = 10) out vec3 fa_vel_prev;\nlayout(location = 9) in vec4 fa_joints;\nlayout(location = 10) in vec4 fa_weights;\nlayout(location = 0) in vec3 fa_position;\nlayout(location = 1) in vec3 fa_normal;\nlayout(location = 3) in vec4 fa_tangent;\nlayout(location = 2) in vec2 fa_texcoord0;\nlayout(location = 4) in vec4 fa_color;\nlayout(location = 5) in vec4 fa_inst_m0;\nlayout(location = 6) in vec4 fa_inst_m1;\nlayout(location = 7) in vec4 fa_inst_m2;\nlayout(location = 8) in vec4 fa_inst_m3;\nvec4 fa_vtime;\n\nvoid fa_inst_begin()\n{\n}\n\nmat4 fa_skin_matrix_at(vec4 joints, vec4 weights, int base)\n{\n    vec4 r0 = vec4(0.0);\n    vec4 r1 = vec4(0.0);\n    vec4 r2 = vec4(0.0);\n    for (int i = 0; i < 4; i++)\n    {\n        int _228 = base + (int((joints[i] * 255.0) + 0.5) * 3);\n        r0 += (fa_skin[_228 * 1 + 0] * weights[i]);\n        r1 += (fa_skin[(_228 + 1) * 1 + 0] * weights[i]);\n        r2 += (fa_skin[(_228 + 2) * 1 + 0] * weights[i]);\n    }\n    return mat4(vec4(r0.x, r1.x, r2.x, 0.0), vec4(r0.y, r1.y, r2.y, 0.0), vec4(r0.z, r1.z, r2.z, 0.0), vec4(r0.w, r1.w, r2.w, 1.0));\n}\n\nmat4 fa_skin_matrix(vec4 joints, vec4 weights)\n{\n    vec4 param = joints;\n    vec4 param_1 = weights;\n    int param_2 = 0;\n    return fa_skin_matrix_at(param, param_1, param_2);\n}\n\nvec4 fa_time_now()\n{\n    return fa_mesh_vs_params[9];\n}\n\nVertexData fa_vertex_data(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    vec3 _139 = cross(model[1].xyz, model[2].xyz);\n    float _143 = (dot(model[0].xyz, _139) < 0.0) ? (-1.0) : 1.0;\n    return VertexData((model * vec4(position, 1.0)).xyz, (((_139 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _143, vec4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _143), texcoord0 * fa_mesh_vs_params[8].xy, color, position);\n}\n\nvoid vertex(inout VertexData v)\n{\n    if (fa_vs_points.data[gl_InstanceID].pos.w < 0.5)\n    {\n        v.world_pos = vec3(1000000000.0);\n        return;\n    }\n    v.world_pos += fa_vs_points.data[gl_InstanceID].pos.xyz;\n    v.color = fa_vs_points.data[gl_InstanceID].tint;\n}\n\nvoid fa_prepass_vertex(mat4 model, mat4 prev_model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color, bool has_prev)\n{\n    bool _333;\n    if (has_prev)\n    {\n        _333 = fa_vel_params[8].x > 0.5;\n    }\n    else\n    {\n        _333 = has_prev;\n    }\n    fa_vtime = fa_time_now();\n    mat4 param = model;\n    vec3 param_1 = position;\n    vec3 param_2 = normal;\n    vec4 param_3 = tangent;\n    vec2 param_4 = texcoord0;\n    vec4 param_5 = color;\n    VertexData param_6 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    vertex(param_6);\n    mat4 _356 = mat4(fa_mesh_vs_params[4], fa_mesh_vs_params[5], fa_mesh_vs_params[6], fa_mesh_vs_params[7]);\n    vec4 _363 = vec4(param_6.world_pos, 1.0);\n    fa_world_pos = param_6.world_pos;\n    fa_world_normal = param_6.world_normal;\n    fa_world_tangent = param_6.world_tangent;\n    fa_uv = param_6.uv;\n    fa_vertex_color = param_6.color;\n    fa_pre_depth = -(_356 * _363).z;\n    fa_pre_r0 = vec3(_356[0].x, _356[1].x, _356[2].x);\n    fa_pre_r1 = vec3(_356[0].y, _356[1].y, _356[2].y);\n    fa_pre_r2 = vec3(_356[0].z, _356[1].z, _356[2].z);\n    gl_Position = mat4(fa_mesh_vs_params[0], fa_mesh_vs_params[1], fa_mesh_vs_params[2], fa_mesh_vs_params[3]) * _363;\n    fa_vel_cur = vec3(0.0, 0.0, 1.0);\n    fa_vel_prev = vec3(0.0);\n    if (_333)\n    {\n        fa_vtime.x = fa_vel_params[8].y;\n        mat4 param_7 = prev_model;\n        vec3 param_8 = position;\n        vec3 param_9 = normal;\n        vec4 param_10 = tangent;\n        vec2 param_11 = texcoord0;\n        vec4 param_12 = color;\n        VertexData param_13 = fa_vertex_data(param_7, param_8, param_9, param_10, param_11, param_12);\n        vertex(param_13);\n        fa_vel_cur = vec3((mat4(fa_vel_params[0], fa_vel_params[1], fa_vel_params[2], fa_vel_params[3]) * _363).xyw);\n        fa_vel_prev = vec3((mat4(fa_vel_params[4], fa_vel_params[5], fa_vel_params[6], fa_vel_params[7]) * vec4(param_13.world_pos, 1.0)).xyw);\n    }\n}\n\nvoid main()\n{\n    fa_vtime = vec4(0.0);\n    fa_inst_begin();\n    vec4 param = fa_joints;\n    vec4 param_1 = fa_weights;\n    mat4 param_2 = mat4(fa_inst_base[0], fa_inst_base[1], fa_inst_base[2], fa_inst_base[3]) * fa_skin_matrix(param, param_1);\n    mat4 param_3 = mat4(vec4(1.0, 0.0, 0.0, 0.0), vec4(0.0, 1.0, 0.0, 0.0), vec4(0.0, 0.0, 1.0, 0.0), vec4(0.0, 0.0, 0.0, 1.0));\n    vec3 param_4 = fa_position;\n    vec3 param_5 = fa_normal;\n    vec4 param_6 = fa_tangent;\n    vec2 param_7 = fa_texcoord0;\n    vec4 param_8 = fa_color;\n    bool param_9 = false;\n    fa_prepass_vertex(param_2, param_3, param_4, param_5, param_6, param_7, param_8, param_9);\n}\n\n",
      "fs": "#version 430\n\nstruct SurfaceInput\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 vertex_color;\n    vec3 view_dir;\n    bool front_facing;\n};\n\nstruct Surface\n{\n    vec3 albedo;\n    float alpha;\n    vec3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    vec3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    vec3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    vec3 specular_color;\n    float transmission;\n    float thickness;\n    vec3 attenuation_color;\n    float attenuation_distance;\n};\n\nstruct points_item\n{\n    vec4 pos;\n    vec4 tint;\n};\n\nlayout(binding = 1, std430) readonly buffer fa_points_buf\n{\n    points_item data[];\n} points;\n\nuniform vec4 fa_mesh_fs_params[53];\nlayout(binding = 0) uniform sampler2D fa_tex_fa_smp;\nlayout(binding = 1) uniform sampler2D fa_normal_tex_fa_smp;\nlayout(binding = 2) uniform sampler2D fa_mr_tex_fa_smp;\nlayout(binding = 3) uniform sampler2D fa_occlusion_tex_fa_smp;\nlayout(binding = 4) uniform sampler2D fa_emissive_tex_fa_smp;\n\nlayout(location = 0) in vec3 fa_world_pos;\nlayout(location = 1) in vec3 fa_world_normal;\nlayout(location = 2) in vec4 fa_world_tangent;\nlayout(location = 3) in vec2 fa_uv;\nlayout(location = 4) in vec4 fa_vertex_color;\nlayout(location = 6) in vec3 fa_pre_r0;\nlayout(location = 7) in vec3 fa_pre_r1;\nlayout(location = 8) in vec3 fa_pre_r2;\nlayout(location = 0) out vec4 fa_frag_color;\nlayout(location = 5) in float fa_pre_depth;\nlayout(location = 9) in vec3 fa_vel_cur;\nlayout(location = 10) in vec3 fa_vel_prev;\nlayout(location = 1) out vec2 fa_frag_velocity;\n\nvoid fa_inst_load()\n{\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nvec3 fa_linear_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_tex_fix(inout vec3 c, float mode)\n{\n    if (mode > 1.5)\n    {\n        vec3 param = c;\n        vec3 _190 = fa_linear_to_srgb(param);\n        c = _190;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            vec3 param_1 = c;\n            vec3 _199 = fa_srgb_to_linear(param_1);\n            c = _199;\n        }\n    }\n    return c;\n}\n\nvec3 fa_tangent_normal(SurfaceInput i, vec3 m)\n{\n    vec3 _56;\n    if (i.front_facing)\n    {\n        _56 = i.world_normal;\n    }\n    else\n    {\n        _56 = -i.world_normal;\n    }\n    vec3 _81 = normalize(i.world_tangent.xyz - (_56 * dot(_56, i.world_tangent.xyz)));\n    vec3 _109 = normalize(((_81 * m.x) + ((cross(_56, _81) * i.world_tangent.w) * m.y)) + (_56 * m.z));\n    vec3 _112;\n    if (i.front_facing)\n    {\n        _112 = _109;\n    }\n    else\n    {\n        _112 = -_109;\n    }\n    return _112;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    vec4 base_t = texture(fa_tex_fa_smp, i.uv);\n    float param = fa_mesh_fs_params[6].w;\n    float param_1 = 1.0;\n    vec3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    vec3 _244 = fa_tex_fix(param_2, param_3);\n    vec4 _844 = base_t;\n    _844.x = _244.x;\n    _844.y = _244.y;\n    _844.z = _244.z;\n    base_t = _844;\n    vec4 _259 = (_844 * fa_mesh_fs_params[2]) * i.vertex_color;\n    vec3 _799 = i.world_normal;\n    if (fa_mesh_fs_params[6].z > 0.5)\n    {\n        float param_4 = fa_mesh_fs_params[6].w;\n        float param_5 = 16.0;\n        vec3 param_6 = texture(fa_normal_tex_fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        vec3 _292 = fa_tex_fix(param_6, param_7);\n        vec3 _296 = (_292 * 2.0) - vec3(1.0);\n        vec2 _301 = _296.xy * fa_mesh_fs_params[6].x;\n        vec3 _852 = _296;\n        _852.x = _301.x;\n        _852.y = _301.y;\n        SurfaceInput param_8 = i;\n        vec3 param_9 = _852;\n        _799 = fa_tangent_normal(param_8, param_9);\n    }\n    vec4 mrt = texture(fa_mr_tex_fa_smp, i.uv);\n    float param_10 = fa_mesh_fs_params[6].w;\n    float param_11 = 64.0;\n    vec3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    vec3 _330 = fa_tex_fix(param_12, param_13);\n    vec4 _855 = mrt;\n    _855.x = _330.x;\n    _855.y = _330.y;\n    _855.z = _330.z;\n    mrt = _855;\n    vec4 _360 = texture(fa_occlusion_tex_fa_smp, i.uv);\n    float param_14 = fa_mesh_fs_params[6].w;\n    float param_15 = 256.0;\n    vec3 param_16 = _360.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    vec3 _372 = fa_tex_fix(param_16, param_17);\n    float param_18 = fa_mesh_fs_params[6].w;\n    float param_19 = 4.0;\n    vec3 param_20 = texture(fa_emissive_tex_fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    vec3 _402 = fa_tex_fix(param_20, param_21);\n    float _804 = fa_mesh_fs_params[20].x;\n    float _805 = fa_mesh_fs_params[20].y;\n    float _808 = fa_mesh_fs_params[20].z;\n    float _807 = fa_mesh_fs_params[21].w;\n    float _810 = fa_mesh_fs_params[22].x;\n    if (fa_mesh_fs_params[22].z > 0.5)\n    {\n        if (mod(fa_mesh_fs_params[22].z, 2.0) > 0.5)\n        {\n            _804 *= _372.y;\n            _805 *= _372.z;\n            _807 *= _360.w;\n        }\n        if (fa_mesh_fs_params[22].z > 1.5)\n        {\n            _808 *= mrt.x;\n            _810 *= mrt.w;\n        }\n    }\n    return Surface(_259.xyz, _259.w, _799, clamp(fa_mesh_fs_params[5].x * _330.z, 0.0, 1.0), clamp(fa_mesh_fs_params[5].y * _330.y, 0.0500000007450580596923828125, 1.0), 1.0 + (fa_mesh_fs_params[6].y * (_372.x - 1.0)), fa_mesh_fs_params[3].xyz + (fa_mesh_fs_params[4].xyz * _402), _804, _805, fa_mesh_fs_params[21].xyz, _807, _808, fa_mesh_fs_params[20].w, _810, fa_mesh_fs_params[22].y, fa_mesh_fs_params[23].xyz, fa_mesh_fs_params[30].x, fa_mesh_fs_params[30].y, fa_mesh_fs_params[31].xyz, fa_mesh_fs_params[30].z);\n}\n\nvoid surface(SurfaceInput i, inout Surface s)\n{\n    s.emission += (i.vertex_color.xyz * points.data[0].tint.w);\n}\n\nvoid main()\n{\n    fa_inst_load();\n    vec3 _694 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _694 = -_694;\n    }\n    vec3 _555 = normalize(fa_mesh_fs_params[0].xyz - fa_world_pos);\n    SurfaceInput param = SurfaceInput(fa_world_pos, _694, fa_world_tangent, fa_uv, fa_vertex_color, _555, gl_FrontFacing);\n    SurfaceInput param_1 = SurfaceInput(fa_world_pos, _694, fa_world_tangent, fa_uv, fa_vertex_color, _555, gl_FrontFacing);\n    Surface param_2 = fa_standard_surface(param);\n    surface(param_1, param_2);\n    vec3 _570 = normalize(param_2.normal);\n    vec3 _585 = normalize(vec3(dot(fa_pre_r0, _570), dot(fa_pre_r1, _570), dot(fa_pre_r2, _570)));\n    float _597 = _585.z;\n    vec2 e = _585.xy / vec2((abs(_585.x) + abs(_585.y)) + abs(_597));\n    if (_597 < 0.0)\n    {\n        e = (vec2(1.0) - abs(e.yx)) * vec2((e.x >= 0.0) ? 1.0 : (-1.0), (e.y >= 0.0) ? 1.0 : (-1.0));\n    }\n    fa_frag_color = vec4(min(fa_pre_depth, 60000.0), e, 1.0);\n    vec2 motion = vec2(1024.0);\n    bool _641 = fa_vel_cur.z > 9.9999997473787516355514526367188e-06;\n    bool _648;\n    if (_641)\n    {\n        _648 = fa_vel_prev.z > 9.9999997473787516355514526367188e-06;\n    }\n    else\n    {\n        _648 = _641;\n    }\n    if (_648)\n    {\n        motion = clamp(((vec2(fa_vel_prev.x, -fa_vel_prev.y) / vec2(fa_vel_prev.z)) * 0.5) - ((vec2(fa_vel_cur.x, -fa_vel_cur.y) / vec2(fa_vel_cur.z)) * 0.5), vec2(-4.0), vec2(4.0));\n    }\n    fa_frag_velocity = motion;\n}\n\n",
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
            "inst_name": "_67",
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
            "inst_name": "_237",
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
            "inst_name": "_328",
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
            "inst_name": "_485",
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
            "size": 848,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_233",
            "glsl_uniforms": [
              {
                "type": "vec4",
                "array_count": 53,
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
      "vs": "#version 430\n\nstruct VertexData\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 color;\n    vec3 object_pos;\n};\n\nstruct points_item\n{\n    vec4 pos;\n    vec4 tint;\n};\n\nlayout(binding = 0, std430) readonly buffer fa_vs_points_buf\n{\n    points_item data[];\n} fa_vs_points;\n\nuniform vec4 fa_mesh_vs_params[11];\nuniform vec4 fa_skin[192];\nuniform vec4 fa_inst_base[4];\nlayout(location = 5) in vec4 fa_joints;\nlayout(location = 6) in vec4 fa_weights;\nlayout(location = 0) in vec3 fa_position;\nlayout(location = 7) in vec3 fa_normal;\nlayout(location = 9) in vec4 fa_tangent;\nlayout(location = 8) in vec2 fa_texcoord0;\nlayout(location = 10) in vec4 fa_color;\nlayout(location = 1) in vec4 fa_inst_m0;\nlayout(location = 2) in vec4 fa_inst_m1;\nlayout(location = 3) in vec4 fa_inst_m2;\nlayout(location = 4) in vec4 fa_inst_m3;\n\nmat4 fa_skin_matrix_at(vec4 joints, vec4 weights, int base)\n{\n    vec4 r0 = vec4(0.0);\n    vec4 r1 = vec4(0.0);\n    vec4 r2 = vec4(0.0);\n    for (int i = 0; i < 4; i++)\n    {\n        int _207 = base + (int((joints[i] * 255.0) + 0.5) * 3);\n        r0 += (fa_skin[_207 * 1 + 0] * weights[i]);\n        r1 += (fa_skin[(_207 + 1) * 1 + 0] * weights[i]);\n        r2 += (fa_skin[(_207 + 2) * 1 + 0] * weights[i]);\n    }\n    return mat4(vec4(r0.x, r1.x, r2.x, 0.0), vec4(r0.y, r1.y, r2.y, 0.0), vec4(r0.z, r1.z, r2.z, 0.0), vec4(r0.w, r1.w, r2.w, 1.0));\n}\n\nmat4 fa_skin_matrix(vec4 joints, vec4 weights)\n{\n    vec4 param = joints;\n    vec4 param_1 = weights;\n    int param_2 = 0;\n    return fa_skin_matrix_at(param, param_1, param_2);\n}\n\nvoid fa_inst_begin()\n{\n}\n\nVertexData fa_vertex_data(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    vec3 _112 = cross(model[1].xyz, model[2].xyz);\n    float _117 = (dot(model[0].xyz, _112) < 0.0) ? (-1.0) : 1.0;\n    return VertexData((model * vec4(position, 1.0)).xyz, (((_112 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _117, vec4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _117), texcoord0 * fa_mesh_vs_params[8].xy, color, position);\n}\n\nvoid vertex(inout VertexData v)\n{\n    if (fa_vs_points.data[gl_InstanceID].pos.w < 0.5)\n    {\n        v.world_pos = vec3(1000000000.0);\n        return;\n    }\n    v.world_pos += fa_vs_points.data[gl_InstanceID].pos.xyz;\n    v.color = fa_vs_points.data[gl_InstanceID].tint;\n}\n\nvoid main()\n{\n    vec4 param = fa_joints;\n    vec4 param_1 = fa_weights;\n    fa_inst_begin();\n    mat4 param_2 = mat4(fa_inst_base[0], fa_inst_base[1], fa_inst_base[2], fa_inst_base[3]) * fa_skin_matrix(param, param_1);\n    vec3 param_3 = fa_position;\n    vec3 param_4 = fa_normal;\n    vec4 param_5 = fa_tangent;\n    vec2 param_6 = fa_texcoord0;\n    vec4 param_7 = fa_color;\n    VertexData param_8 = fa_vertex_data(param_2, param_3, param_4, param_5, param_6, param_7);\n    vertex(param_8);\n    gl_Position = mat4(fa_mesh_vs_params[4], fa_mesh_vs_params[5], fa_mesh_vs_params[6], fa_mesh_vs_params[7]) * vec4(param_8.world_pos, 1.0);\n}\n\n",
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
            "inst_name": "_171",
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
            "inst_name": "_216",
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
            "inst_name": "_304",
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
