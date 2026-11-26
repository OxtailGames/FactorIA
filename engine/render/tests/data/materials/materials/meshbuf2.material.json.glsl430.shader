{
  "format": "factoria.shader/1",
  "engine": "0.38.0",
  "template": "7dfc96845a84a2e1eeb941c4a325b3e44f1dd63d04807d1dd0da2d9b2c3c7186",
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
      "fs": "#version 430\n\nstruct SurfaceInput\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 vertex_color;\n    vec3 view_dir;\n    bool front_facing;\n};\n\nstruct LightSample\n{\n    vec3 direction;\n    vec3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct Surface\n{\n    vec3 albedo;\n    float alpha;\n    vec3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    vec3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    vec3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    vec3 specular_color;\n    float transmission;\n    float thickness;\n    vec3 attenuation_color;\n    float attenuation_distance;\n};\n\nstruct FaLayers\n{\n    bool on;\n    float f90;\n    float keep;\n    float base_scale;\n    float coat;\n    float coat_rough;\n    float coat_alpha;\n    float coat_a2;\n    vec3 nc;\n    float coat_ndv;\n    bool sheen_on;\n    vec3 sheen;\n    float sheen_rough;\n    float sheen_alpha;\n    float sheen_scale;\n    float sheen_e;\n    float aniso;\n    vec3 t;\n    vec3 b;\n    float at;\n    float ab;\n};\n\nconst float _4498[63] = float[](1.0, 1.0, 1.0, 0.4790000021457672119140625, 0.11699999868869781494140625, 0.01200000010430812835693359375, 0.0, 0.0, 0.0, 1.0, 1.0, 1.0, 0.578000009059906005859375, 0.19300000369548797607421875, 0.0350000001490116119384765625, 0.0030000000260770320892333984375, 0.0, 0.0, 1.0, 1.0, 1.0, 0.6740000247955322265625, 0.3459999859333038330078125, 0.1319999992847442626953125, 0.032999999821186065673828125, 0.0040000001899898052215576171875, 0.0, 0.971000015735626220703125, 0.954999983310699462890625, 0.828999996185302734375, 0.63999998569488525390625, 0.42599999904632568359375, 0.24500000476837158203125, 0.115000002086162567138671875, 0.037000000476837158203125, 0.0030000000260770320892333984375, 0.7469999790191650390625, 0.737999975681304931640625, 0.670000016689300537109375, 0.563000023365020751953125, 0.4309999942779541015625, 0.3039999902248382568359375, 0.1940000057220458984375, 0.1019999980926513671875, 0.0309999994933605194091796875, 0.614000022411346435546875, 0.609000027179718017578125, 0.566999971866607666015625, 0.499000012874603271484375, 0.412000000476837158203125, 0.32400000095367431640625, 0.240999996662139892578125, 0.162000000476837158203125, 0.087999999523162841796875, 0.538999974727630615234375, 0.535000026226043701171875, 0.505999982357025146484375, 0.4569999873638153076171875, 0.393999993801116943359375, 0.328999996185302734375, 0.2660000026226043701171875, 0.203999996185302734375, 0.14200000464916229248046875);\n\nstruct points_item\n{\n    vec4 pos;\n    vec4 tint;\n};\n\nuniform vec4 fa_mesh_fs_params[53];\nuniform vec4 fa_shadows[30];\nlayout(binding = 3, std430) readonly buffer fa_points_buf\n{\n    points_item data[];\n} points;\n\nlayout(binding = 0) uniform sampler2D fa_light_tex_fa_shadow_smp;\nlayout(binding = 1) uniform sampler2D fa_tex_fa_smp;\nlayout(binding = 2) uniform sampler2D fa_normal_tex_fa_smp;\nlayout(binding = 3) uniform sampler2D fa_mr_tex_fa_smp;\nlayout(binding = 4) uniform sampler2D fa_occlusion_tex_fa_smp;\nlayout(binding = 5) uniform sampler2D fa_emissive_tex_fa_smp;\nlayout(binding = 6) uniform sampler2D fa_decal_tex_fa_env_smp;\nlayout(binding = 7) uniform sampler2D fa_lightmap_fa_env_smp;\nlayout(binding = 8) uniform sampler2D fa_probe_atlas_fa_env_smp;\nlayout(binding = 9) uniform sampler2D fa_light_atlas_fa_env_smp;\nlayout(binding = 10) uniform sampler2D fa_screen_tex_fa_shadow_smp;\nlayout(binding = 11) uniform sampler2D fa_shadow_tex_fa_shadow_smp;\n\nlayout(location = 0) in vec3 fa_world_pos;\nlayout(location = 5) in vec3 fa_lm;\nlayout(location = 1) in vec3 fa_world_normal;\nlayout(location = 2) in vec4 fa_world_tangent;\nlayout(location = 3) in vec2 fa_uv;\nlayout(location = 4) in vec4 fa_vertex_color;\nlayout(location = 0) out vec4 fa_frag_color;\nvec3 fa_light_tint;\nbool fa_light_is_area;\nint fa_cl_ndir;\nint fa_cl_slot;\nint fa_cl_local;\n\nvoid fa_inst_load()\n{\n}\n\nvec4 fa_light_texel(int t)\n{\n    return texelFetch(fa_light_tex_fa_shadow_smp, ivec2(t & 1023, t >> 10), 0);\n}\n\nvec4 fa_cluster_texel(vec3 world_pos)\n{\n    bool _1588 = fa_mesh_fs_params[19].x < 0.0;\n    bool _1595;\n    if (!_1588)\n    {\n        _1595 = fa_mesh_fs_params[19].w < 1.0;\n    }\n    else\n    {\n        _1595 = _1588;\n    }\n    bool _1603;\n    if (!_1595)\n    {\n        _1603 = fa_mesh_fs_params[18].x < 1.0;\n    }\n    else\n    {\n        _1603 = _1595;\n    }\n    bool _1610;\n    if (!_1603)\n    {\n        _1610 = fa_mesh_fs_params[18].y < 1.0;\n    }\n    else\n    {\n        _1610 = _1603;\n    }\n    bool _1617;\n    if (!_1610)\n    {\n        _1617 = fa_mesh_fs_params[19].y < 1.0;\n    }\n    else\n    {\n        _1617 = _1610;\n    }\n    if (_1617)\n    {\n        return vec4(0.0);\n    }\n    vec4 _1627 = vec4(world_pos, 1.0);\n    float _1633 = dot(fa_mesh_fs_params[16], _1627);\n    if (!(_1633 > 9.9999999747524270787835121154785e-07))\n    {\n        return vec4(0.0);\n    }\n    vec2 _1655 = vec2(dot(fa_mesh_fs_params[14], _1627), dot(fa_mesh_fs_params[15], _1627)) / vec2(_1633);\n    int _1659 = int(fa_mesh_fs_params[18].x);\n    int _1663 = int(fa_mesh_fs_params[18].y);\n    int param = (int(fa_mesh_fs_params[19].x) + (((clamp(int(floor(log2(max(dot(fa_mesh_fs_params[17].xyz, world_pos) + fa_mesh_fs_params[17].w, fa_mesh_fs_params[18].w) / fa_mesh_fs_params[18].w) * fa_mesh_fs_params[18].z)), 0, int(fa_mesh_fs_params[19].y) - 1) * _1663) + clamp(int(floor(((_1655.y * 0.5) + 0.5) * fa_mesh_fs_params[18].y)), 0, _1663 - 1)) * _1659)) + clamp(int(floor(((_1655.x * 0.5) + 0.5) * fa_mesh_fs_params[18].x)), 0, _1659 - 1);\n    return fa_light_texel(param);\n}\n\nivec2 fa_cluster_lookup(vec3 world_pos)\n{\n    vec3 param = world_pos;\n    vec4 _1739 = fa_cluster_texel(param);\n    return ivec2(int(_1739.x), int(_1739.y));\n}\n\nvoid fa_cluster_begin(vec3 world_pos)\n{\n    fa_cl_ndir = int(fa_mesh_fs_params[19].z);\n    vec3 param = world_pos;\n    ivec2 _5965 = fa_cluster_lookup(param);\n    fa_cl_slot = _5965.x;\n    fa_cl_local = _5965.y;\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nvec3 fa_linear_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_tex_fix(inout vec3 c, float mode)\n{\n    if (mode > 1.5)\n    {\n        vec3 param = c;\n        vec3 _7139 = fa_linear_to_srgb(param);\n        c = _7139;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            vec3 param_1 = c;\n            vec3 _7147 = fa_srgb_to_linear(param_1);\n            c = _7147;\n        }\n    }\n    return c;\n}\n\nvec3 fa_tangent_normal(SurfaceInput i, vec3 m)\n{\n    vec3 _532;\n    if (i.front_facing)\n    {\n        _532 = i.world_normal;\n    }\n    else\n    {\n        _532 = -i.world_normal;\n    }\n    vec3 _556 = normalize(i.world_tangent.xyz - (_532 * dot(_532, i.world_tangent.xyz)));\n    vec3 _583 = normalize(((_556 * m.x) + ((cross(_532, _556) * i.world_tangent.w) * m.y)) + (_532 * m.z));\n    vec3 _586;\n    if (i.front_facing)\n    {\n        _586 = _583;\n    }\n    else\n    {\n        _586 = -_583;\n    }\n    return _586;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    vec4 base_t = texture(fa_tex_fa_smp, i.uv, fa_mesh_fs_params[12].w);\n    float param = fa_mesh_fs_params[6].w;\n    float param_1 = 1.0;\n    vec3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    vec3 _7179 = fa_tex_fix(param_2, param_3);\n    vec4 _9464 = base_t;\n    _9464.x = _7179.x;\n    _9464.y = _7179.y;\n    _9464.z = _7179.z;\n    base_t = _9464;\n    vec4 _7193 = (_9464 * fa_mesh_fs_params[2]) * i.vertex_color;\n    vec3 _9230 = i.world_normal;\n    if (fa_mesh_fs_params[6].z > 0.5)\n    {\n        float param_4 = fa_mesh_fs_params[6].w;\n        float param_5 = 16.0;\n        vec3 param_6 = texture(fa_normal_tex_fa_smp, i.uv, fa_mesh_fs_params[12].w).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        vec3 _7227 = fa_tex_fix(param_6, param_7);\n        vec3 _7230 = (_7227 * 2.0) - vec3(1.0);\n        vec2 _7235 = _7230.xy * fa_mesh_fs_params[6].x;\n        vec3 _9472 = _7230;\n        _9472.x = _7235.x;\n        _9472.y = _7235.y;\n        SurfaceInput param_8 = i;\n        vec3 param_9 = _9472;\n        _9230 = fa_tangent_normal(param_8, param_9);\n    }\n    vec4 mrt = texture(fa_mr_tex_fa_smp, i.uv, fa_mesh_fs_params[12].w);\n    float param_10 = fa_mesh_fs_params[6].w;\n    float param_11 = 64.0;\n    vec3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    vec3 _7265 = fa_tex_fix(param_12, param_13);\n    vec4 _9475 = mrt;\n    _9475.x = _7265.x;\n    _9475.y = _7265.y;\n    _9475.z = _7265.z;\n    mrt = _9475;\n    vec4 _7295 = texture(fa_occlusion_tex_fa_smp, i.uv, fa_mesh_fs_params[12].w);\n    float param_14 = fa_mesh_fs_params[6].w;\n    float param_15 = 256.0;\n    vec3 param_16 = _7295.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    vec3 _7306 = fa_tex_fix(param_16, param_17);\n    float param_18 = fa_mesh_fs_params[6].w;\n    float param_19 = 4.0;\n    vec3 param_20 = texture(fa_emissive_tex_fa_smp, i.uv, fa_mesh_fs_params[12].w).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    vec3 _7338 = fa_tex_fix(param_20, param_21);\n    float _9235 = fa_mesh_fs_params[20].x;\n    float _9236 = fa_mesh_fs_params[20].y;\n    float _9239 = fa_mesh_fs_params[20].z;\n    float _9238 = fa_mesh_fs_params[21].w;\n    float _9241 = fa_mesh_fs_params[22].x;\n    if (fa_mesh_fs_params[22].z > 0.5)\n    {\n        if (mod(fa_mesh_fs_params[22].z, 2.0) > 0.5)\n        {\n            _9235 *= _7306.y;\n            _9236 *= _7306.z;\n            _9238 *= _7295.w;\n        }\n        if (fa_mesh_fs_params[22].z > 1.5)\n        {\n            _9239 *= mrt.x;\n            _9241 *= mrt.w;\n        }\n    }\n    return Surface(_7193.xyz, _7193.w, _9230, clamp(fa_mesh_fs_params[5].x * _7265.z, 0.0, 1.0), clamp(fa_mesh_fs_params[5].y * _7265.y, 0.0500000007450580596923828125, 1.0), 1.0 + (fa_mesh_fs_params[6].y * (_7306.x - 1.0)), fa_mesh_fs_params[3].xyz + (fa_mesh_fs_params[4].xyz * _7338), _9235, _9236, fa_mesh_fs_params[21].xyz, _9238, _9239, fa_mesh_fs_params[20].w, _9241, fa_mesh_fs_params[22].y, fa_mesh_fs_params[23].xyz, fa_mesh_fs_params[30].x, fa_mesh_fs_params[30].y, fa_mesh_fs_params[31].xyz, fa_mesh_fs_params[30].z);\n}\n\nvoid surface(SurfaceInput i, inout Surface s)\n{\n    s.emission += (i.vertex_color.xyz * points.data[0].tint.w);\n}\n\nvec4 fa_decal_tile(vec4 rect, vec2 uv, vec2 atlas, vec2 ddx, vec2 ddy)\n{\n    vec2 _1819 = rect.zw - rect.xy;\n    vec2 _1823 = _1819 * atlas;\n    vec2 _1827 = ddx * _1823;\n    vec2 _1831 = ddy * _1823;\n    return textureLod(fa_decal_tex_fa_env_smp, rect.xy + (clamp(uv, vec2(0.0), vec2(1.0)) * _1819), clamp(0.5 * log2(max(max(dot(_1827, _1827), dot(_1831, _1831)), 9.9999999392252902907785028219223e-09)), 0.0, 3.0));\n}\n\nvec3 fa_dc_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_dc_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvoid fa_apply_decals(vec3 world_pos, vec3 geo_normal, inout vec3 albedo, inout vec3 normal)\n{\n    bool _1864 = fa_mesh_fs_params[10].y < 0.5;\n    bool _1871;\n    if (!_1864)\n    {\n        _1871 = fa_mesh_fs_params[10].w < 0.5;\n    }\n    else\n    {\n        _1871 = _1864;\n    }\n    if (_1871)\n    {\n        return;\n    }\n    vec3 _1877 = dFdx(world_pos);\n    vec3 _1880 = dFdy(world_pos);\n    vec3 param = world_pos;\n    vec4 _1884 = fa_cluster_texel(param);\n    int _1888 = int(_1884.w);\n    if (_1888 < 1)\n    {\n        return;\n    }\n    int _1898 = int(fa_mesh_fs_params[10].y + 0.5);\n    int param_1 = _1898;\n    vec4 _1902 = fa_light_texel(param_1);\n    vec2 _1905 = _1902.yz;\n    int _1909 = int(_1902.w);\n    int param_2 = _1898 + 1;\n    vec4 _1914 = fa_light_texel(param_2);\n    float _1915 = _1914.x;\n    int _1921 = int(fa_mesh_fs_params[10].w + 0.5) - 1;\n    int _1925 = int(_1884.z);\n    vec3 _2190;\n    for (int k = 0; k < _1888; k++)\n    {\n        int _1938 = _1925 + k;\n        int param_3 = _1909 + (_1938 >> 2);\n        int _1955 = (_1898 + 2) + (int(fa_light_texel(param_3)[_1938 & 3]) * 7);\n        int param_4 = _1955 + 6;\n        vec4 _1960 = fa_light_texel(param_4);\n        if (((int(_1960.w + 0.5) >> _1921) & 1) == 0)\n        {\n            continue;\n        }\n        int param_5 = _1955;\n        vec4 _1975 = fa_light_texel(param_5);\n        int param_6 = _1955 + 1;\n        vec4 _1980 = fa_light_texel(param_6);\n        int param_7 = _1955 + 2;\n        vec4 _1985 = fa_light_texel(param_7);\n        vec3 _1988 = _1975.xyz;\n        float _1993 = dot(_1988, world_pos) + _1975.w;\n        vec3 _1995 = _1980.xyz;\n        float _2000 = dot(_1995, world_pos) + _1980.w;\n        vec3 _2002 = _1985.xyz;\n        float _2007 = dot(_2002, world_pos) + _1985.w;\n        bool _2012 = abs(_1993) > 0.5;\n        bool _2020;\n        if (!_2012)\n        {\n            _2020 = abs(_2000) > 0.5;\n        }\n        else\n        {\n            _2020 = _2012;\n        }\n        bool _2028;\n        if (!_2020)\n        {\n            _2028 = abs(_2007) > 0.5;\n        }\n        else\n        {\n            _2028 = _2020;\n        }\n        if (_2028)\n        {\n            continue;\n        }\n        float _2043 = clamp(dot(geo_normal, normalize(_2002)) * _1960.z, 0.0, 1.0);\n        if (_2043 <= 0.0)\n        {\n            continue;\n        }\n        float _2063 = (clamp((0.5 - abs(_2007)) * 10.0, 0.0, 1.0) * _2043) * _1960.x;\n        vec2 _2071 = vec2(_1993 + 0.5, 0.5 - _2000);\n        vec2 _2081 = vec2(dot(_1988, _1877), dot(_1995, _1877));\n        vec2 _2091 = vec2(dot(_1988, _1880), dot(_1995, _1880));\n        int param_8 = _1955 + 5;\n        vec4 _2096 = fa_light_texel(param_8);\n        int param_9 = _1955 + 3;\n        vec4 _2101 = fa_light_texel(param_9);\n        int param_10 = _1955 + 4;\n        vec4 _2106 = fa_light_texel(param_10);\n        float tex_a = 1.0;\n        vec3 col = _2096.xyz;\n        bool _2116 = _2101.z > _2101.x;\n        if (_2116)\n        {\n            vec4 param_11 = _2101;\n            vec2 param_12 = _2071;\n            vec2 param_13 = _1905;\n            vec2 param_14 = _2081;\n            vec2 param_15 = _2091;\n            vec4 tx = fa_decal_tile(param_11, param_12, param_13, param_14, param_15);\n            if ((_1915 > 0.5) && (_1915 < 1.5))\n            {\n                vec3 param_16 = tx.xyz;\n                vec3 _2142 = fa_dc_to_linear(param_16);\n                vec4 _9318 = tx;\n                _9318.x = _2142.x;\n                _9318.y = _2142.y;\n                _9318.z = _2142.z;\n                tx = _9318;\n            }\n            col *= tx.xyz;\n            tex_a = tx.w;\n        }\n        albedo = mix(albedo, col, vec3(clamp((_2063 * tex_a) * _2096.w, 0.0, 1.0)));\n        if (_2106.z > _2106.x)\n        {\n            vec4 param_17 = _2106;\n            vec2 param_18 = _2071;\n            vec2 param_19 = _1905;\n            vec2 param_20 = _2081;\n            vec2 param_21 = _2091;\n            vec4 _2186 = fa_decal_tile(param_17, param_18, param_19, param_20, param_21);\n            if (_1915 > 1.5)\n            {\n                vec3 param_22 = _2186.xyz;\n                vec3 _2196 = fa_dc_to_srgb(param_22);\n                _2190 = _2196;\n            }\n            else\n            {\n                _2190 = _2186.xyz;\n            }\n            vec3 _2205 = (_2190 * 2.0) - vec3(1.0);\n            vec2 _2210 = _2205.xy * _1960.y;\n            vec3 _2232 = (normalize(_1988) * _2210.x) + (normalize(_1995) * _2210.y);\n            vec3 _2235 = normalize(normal);\n            normal = normalize(mix(_2235, normalize((_2235 * max(_2205.z, 0.0500000007450580596923828125)) + (_2232 - (_2235 * dot(_2235, _2232)))), vec3(clamp(_2063 * (_2116 ? tex_a : 1.0), 0.0, 1.0))));\n        }\n    }\n}\n\nfloat fa_sheen_albedo(float ndv, float rough)\n{\n    float _4423 = min(sqrt(max(rough - 0.100000001490116119384765625, 0.0) * 1.111111164093017578125) * 6.0, 5.999000072479248046875);\n    float _4431 = min(sqrt(clamp(ndv, 0.0, 1.0)) * 8.0, 7.999000072479248046875);\n    int _4434 = int(_4423);\n    int _4437 = int(_4431);\n    float _4447 = _4431 - float(_4437);\n    int _4502 = (_4434 * 9) + _4437;\n    int _4522 = ((_4434 + 1) * 9) + _4437;\n    return mix(mix(_4498[_4502], _4498[_4502 + 1], _4447), mix(_4498[_4522], _4498[_4522 + 1], _4447), _4423 - float(_4434));\n}\n\nFaLayers fa_layers_setup(SurfaceInput i, Surface s, vec3 n, vec3 v, float metallic, float roughness, inout vec3 f0)\n{\n    bool _9153 = false;\n    float _9154 = 1.0;\n    float _9155 = 1.0;\n    float _9156 = 1.0;\n    float _9157 = 0.0;\n    float _9158 = 0.0;\n    float _9159 = 0.0;\n    float _9160 = 0.0;\n    float _9162 = 1.0;\n    bool _9163 = false;\n    vec3 _9164 = vec3(0.0);\n    float _9165 = 1.0;\n    float _9166 = 1.0;\n    float _9167 = 1.0;\n    float _9168 = 0.0;\n    float _9169 = 0.0;\n    vec3 _9170 = vec3(1.0, 0.0, 0.0);\n    vec3 _9171 = vec3(0.0, 0.0, 1.0);\n    float _9172 = 1.0;\n    float _9173 = 1.0;\n    float _4573 = clamp(s.specular, 0.0, 1.0);\n    float _4577 = clamp(s.ior, 1.0, 3.0);\n    bool _4582 = (_4573 != 1.0) || (_4577 != 1.5);\n    bool _4591;\n    if (!_4582)\n    {\n        _4591 = any(notEqual(s.specular_color, vec3(1.0)));\n    }\n    else\n    {\n        _4591 = _4582;\n    }\n    if (_4591)\n    {\n        float _4599 = (_4577 - 1.0) / (_4577 + 1.0);\n        f0 = mix(min(vec3(_4599 * _4599) * max(s.specular_color, vec3(0.0)), vec3(1.0)) * _4573, s.albedo, vec3(metallic));\n        _9154 = mix(_4573, 1.0, metallic);\n        _9153 = true;\n    }\n    float _4626 = clamp(s.clearcoat, 0.0, 1.0);\n    if (_4626 > 0.0)\n    {\n        float _4634 = clamp(s.clearcoat_roughness, 0.0500000007450580596923828125, 1.0);\n        _9157 = _4626;\n        _9158 = _4634;\n        float _4641 = _4634 * _4634;\n        _9159 = _4641;\n        _9160 = _4641 * _4641;\n        float _4653 = max(dot(i.world_normal, v), 9.9999997473787516355514526367188e-05);\n        _9162 = _4653;\n        _9155 = 1.0 - (_4626 * (0.039999999105930328369140625 + (0.959999978542327880859375 * pow(clamp(1.0 - _4653, 0.0, 1.0), 5.0))));\n        _9153 = true;\n    }\n    vec3 _4672 = max(s.sheen_color, vec3(0.0));\n    float _4681 = max(_4672.x, max(_4672.y, _4672.z));\n    if (_4681 > 0.0)\n    {\n        float _4689 = clamp(s.sheen_roughness, 0.100000001490116119384765625, 1.0);\n        _9163 = true;\n        _9164 = _4672;\n        _9165 = _4689;\n        _9166 = _4689 * _4689;\n        float param = max(dot(n, v), 9.9999997473787516355514526367188e-05);\n        float param_1 = _4689;\n        float _4706 = fa_sheen_albedo(param, param_1);\n        _9168 = _4706;\n        _9167 = 1.0 - min(_4681 * _4706, 1.0);\n        _9153 = true;\n    }\n    _9156 = _9155 * _9167;\n    float _4725 = clamp(s.anisotropy, -1.0, 1.0);\n    if (_4725 != 0.0)\n    {\n        vec3 _4740 = i.world_tangent.xyz - (n * dot(n, i.world_tangent.xyz));\n        vec3 t = _4740;\n        if (dot(_4740, _4740) < 9.9999999392252902907785028219223e-09)\n        {\n            bvec3 _4752 = bvec3(abs(n.y) < 0.9900000095367431640625);\n            t = cross(vec3(_4752.x ? vec3(0.0, 1.0, 0.0).x : vec3(1.0, 0.0, 0.0).x, _4752.y ? vec3(0.0, 1.0, 0.0).y : vec3(1.0, 0.0, 0.0).y, _4752.z ? vec3(0.0, 1.0, 0.0).z : vec3(1.0, 0.0, 0.0).z), n);\n        }\n        vec3 _4756 = t;\n        vec3 _4757 = normalize(_4756);\n        t = _4757;\n        vec3 _4782 = normalize((_4757 * cos(s.anisotropy_rotation)) + ((cross(n, _4757) * ((i.world_tangent.w < 0.0) ? (-1.0) : 1.0)) * sin(s.anisotropy_rotation)));\n        _9170 = _4782;\n        _9171 = cross(n, _4782);\n        float _4792 = roughness * roughness;\n        float _4798 = mix(_4792, 1.0, _4725 * _4725);\n        bool _4800 = _4725 > 0.0;\n        _9172 = _4800 ? _4798 : _4792;\n        _9173 = _4800 ? _4792 : _4798;\n        _9169 = _4725;\n        _9153 = true;\n    }\n    return FaLayers(_9153, _9154, _9155, _9156, _9157, _9158, _9159, _9160, i.world_normal, _9162, _9163, _9164, _9165, _9166, _9167, _9168, _9169, _9170, _9171, _9172, _9173);\n}\n\nvec2 fa_atlas_size()\n{\n    return vec2(textureSize(fa_probe_atlas_fa_env_smp, 0));\n}\n\nvec3 fa_probe_sh_coef(vec2 origin, float res, int k)\n{\n    vec3 v = textureLod(fa_probe_atlas_fa_env_smp, (origin + vec2(float(k) + 0.5, res + 2.5)) / fa_atlas_size(), 0.0).xyz;\n    if (fa_mesh_fs_params[41].y > 0.5)\n    {\n        v = ((v * 255.0) - vec3(128.0)) * 0.03149606287479400634765625;\n    }\n    return v;\n}\n\nvec3 fa_sh_eval(vec3 c[9], vec3 n)\n{\n    vec3 _3592 = max((((c[0] * 0.2820948064327239990234375) + (((c[1] * (0.3257350027561187744140625 * n.y)) + (c[2] * (0.3257350027561187744140625 * n.z))) + (c[3] * (0.3257350027561187744140625 * n.x)))) + (((c[4] * ((0.2731371223926544189453125 * n.x) * n.y)) + (c[5] * ((0.2731371223926544189453125 * n.y) * n.z))) + (c[6] * (0.078847892582416534423828125 * (((3.0 * n.z) * n.z) - 1.0))))) + ((c[7] * ((0.2731371223926544189453125 * n.x) * n.z)) + (c[8] * (0.13656856119632720947265625 * ((n.x * n.x) - (n.y * n.y))))), vec3(0.0));\n    return _3592;\n}\n\nvec3 fa_ambient_light(vec3 n)\n{\n    float _4204 = (1.0 - fa_mesh_fs_params[42].w) - fa_mesh_fs_params[47].w;\n    vec3 amb = vec3(0.0);\n    bool _4209 = fa_mesh_fs_params[11].w > 0.5;\n    vec3 c[9];\n    for (int k = 0; k < 9; k++)\n    {\n        c[k] = vec3(0.0);\n    }\n    if (_4204 > 0.0005000000237487256526947021484375)\n    {\n        if (_4209)\n        {\n            for (int k_1 = 0; k_1 < 9; k_1++)\n            {\n                vec2 param = fa_mesh_fs_params[41].zw;\n                float param_1 = 128.0;\n                int param_2 = k_1;\n                c[k_1] = fa_probe_sh_coef(param, param_1, param_2) * _4204;\n            }\n        }\n        else\n        {\n            amb = fa_mesh_fs_params[1].xyz * _4204;\n        }\n    }\n    bool _4260 = fa_mesh_fs_params[42].w > 0.0;\n    if (_4260)\n    {\n        for (int k_2 = 0; k_2 < 9; k_2++)\n        {\n            vec2 param_3 = fa_mesh_fs_params[42].xy;\n            float param_4 = fa_mesh_fs_params[42].z;\n            int param_5 = k_2;\n            c[k_2] += (fa_probe_sh_coef(param_3, param_4, param_5) * fa_mesh_fs_params[42].w);\n        }\n    }\n    bool _4291 = fa_mesh_fs_params[47].w > 0.0;\n    if (_4291)\n    {\n        for (int k_3 = 0; k_3 < 9; k_3++)\n        {\n            vec2 param_6 = fa_mesh_fs_params[47].xy;\n            float param_7 = fa_mesh_fs_params[47].z;\n            int param_8 = k_3;\n            c[k_3] += (fa_probe_sh_coef(param_6, param_7, param_8) * fa_mesh_fs_params[47].w);\n        }\n    }\n    if ((_4209 || _4260) || _4291)\n    {\n        vec3 param_9[9] = c;\n        vec3 param_10 = n;\n        amb += fa_sh_eval(param_9, param_10);\n    }\n    return amb;\n}\n\nvec4 fa_gi_fetch(vec2 texel)\n{\n    return textureLod(fa_probe_atlas_fa_env_smp, texel / fa_atlas_size(), 0.0);\n}\n\nvec2 fa_oct_encode(vec3 d)\n{\n    vec3 _3612 = d / vec3(max((abs(d.x) + abs(d.y)) + abs(d.z), 9.9999999600419720025001879548654e-13));\n    float _3615 = _3612.x;\n    float _3617 = _3612.z;\n    vec2 e = vec2(_3615, _3617);\n    if (_3612.y < 0.0)\n    {\n        e = vec2((1.0 - abs(_3617)) * ((_3615 < 0.0) ? (-1.0) : 1.0), (1.0 - abs(_3615)) * ((_3617 < 0.0) ? (-1.0) : 1.0));\n    }\n    return e;\n}\n\nvec3 fa_gi_grid(int rec, vec3 n, vec3 v, out float cover)\n{\n    cover = 0.0;\n    int param = rec;\n    vec4 _7448 = fa_light_texel(param);\n    int param_1 = rec + 1;\n    vec4 _7453 = fa_light_texel(param_1);\n    int param_2 = rec + 2;\n    vec4 _7458 = fa_light_texel(param_2);\n    int param_3 = rec + 3;\n    vec4 _7463 = fa_light_texel(param_3);\n    bool _7466 = _7463.z < 0.5;\n    bool _7474;\n    if (!_7466)\n    {\n        _7474 = fa_atlas_size().y < 1155.0;\n    }\n    else\n    {\n        _7474 = _7466;\n    }\n    if (_7474)\n    {\n        return vec3(0.0);\n    }\n    float _7481 = max(_7448.w, 9.9999997473787516355514526367188e-05);\n    vec3 _7484 = _7453.xyz;\n    vec3 _7488 = _7448.xyz;\n    vec3 _7492 = (fa_world_pos - _7488) / vec3(_7481);\n    vec3 _7501 = min(_7492 + vec3(0.5), (_7484 - vec3(0.5)) - _7492);\n    float _7510 = min(_7501.x, min(_7501.y, _7501.z));\n    if (!(_7510 > 0.0))\n    {\n        return vec3(0.0);\n    }\n    vec3 _7525 = _7484 - vec3(1.0);\n    vec3 _7526 = clamp(_7492, vec3(0.0), _7525);\n    vec3 _7534 = min(floor(_7526), max(_7484 - vec3(2.0), vec3(0.0)));\n    vec3 _7538 = _7526 - _7534;\n    vec3 _7549 = fa_world_pos + (((n * 0.800000011920928955078125) + (v * 0.20000000298023223876953125)) * (0.20000000298023223876953125 * _7481));\n    int _7554 = int(_7458.y + 0.5);\n    float _7559 = 0.3257350027561187744140625 * n.y;\n    float _7563 = 0.3257350027561187744140625 * n.z;\n    float _7567 = 0.3257350027561187744140625 * n.x;\n    float _7574 = (0.2731371223926544189453125 * n.x) * n.y;\n    float _7581 = (0.2731371223926544189453125 * n.y) * n.z;\n    float _7590 = 0.078847892582416534423828125 * (((3.0 * n.z) * n.z) - 1.0);\n    float _7597 = (0.2731371223926544189453125 * n.x) * n.z;\n    float _7610 = 0.13656856119632720947265625 * ((n.x * n.x) - (n.y * n.y));\n    vec3 acc = vec3(0.0);\n    float wsum = 0.0;\n    int _7617 = 8 + int(_7463.w);\n    float _7644;\n    float _7657;\n    float _7671;\n    for (int k = 0; k < _7617; k++)\n    {\n        float _7630 = float(k & 1);\n        float _7634 = float((k >> 1) & 1);\n        float _7638 = float((k >> 2) & 1);\n        if (_7630 > 0.5)\n        {\n            _7644 = _7538.x;\n        }\n        else\n        {\n            _7644 = 1.0 - _7538.x;\n        }\n        if (_7634 > 0.5)\n        {\n            _7657 = _7538.y;\n        }\n        else\n        {\n            _7657 = 1.0 - _7538.y;\n        }\n        if (_7638 > 0.5)\n        {\n            _7671 = _7538.z;\n        }\n        else\n        {\n            _7671 = 1.0 - _7538.z;\n        }\n        float _7681 = (_7644 * _7657) * _7671;\n        if (!(_7681 > 0.0))\n        {\n            continue;\n        }\n        vec3 _7694 = min(_7534 + vec3(_7630, _7634, _7638), _7525);\n        int _7714 = int(((_7458.x + _7694.x) + (_7453.x * (_7694.y + (_7453.y * _7694.z)))) + 0.5);\n        vec2 _7729 = vec2(float(_7714 % _7554) * 10.0, 1024.0 + (float(_7714 / _7554) * 11.0));\n        vec2 param_4 = _7729 + vec2(9.5, 10.5);\n        vec4 _7737 = fa_gi_fetch(param_4);\n        bool _7740 = _7737.y < 0.5;\n        bool _7749;\n        if (!_7740)\n        {\n            _7749 = _7737.x > _7463.y;\n        }\n        else\n        {\n            _7749 = _7740;\n        }\n        if (_7749)\n        {\n            continue;\n        }\n        vec3 _7761 = _7549 - (_7488 + (_7694 * _7481));\n        float _7764 = length(_7761);\n        vec3 _7770 = _7761 / vec3(max(_7764, 9.9999997473787516355514526367188e-05));\n        float _7780 = max(9.9999997473787516355514526367188e-05, (dot(-_7770, n) + 1.0) * 0.5);\n        float w = _7681 * (_7780 * _7780);\n        vec3 param_5 = _7770;\n        vec2 param_6 = (_7729 + vec2(1.0)) + (((fa_oct_encode(param_5) * 0.5) + vec2(0.5)) * 8.0);\n        vec4 _7799 = fa_gi_fetch(param_6);\n        float _7806 = _7764 / max(_7458.z, 9.9999997473787516355514526367188e-05);\n        float _7809 = _7799.x;\n        if (_7806 > _7809)\n        {\n            float _7822 = max(_7799.y - (_7809 * _7809), 0.0);\n            float _7827 = _7806 - _7809;\n            float _7836 = _7822 / max(_7822 + (_7827 * _7827), 9.9999999600419720025001879548654e-13);\n            w *= ((_7836 * _7836) * _7836);\n        }\n        if (!(w > 0.0))\n        {\n            continue;\n        }\n        vec2 param_7 = _7729 + vec2(0.5, 10.5);\n        vec2 param_8 = _7729 + vec2(1.5, 10.5);\n        vec2 param_9 = _7729 + vec2(2.5, 10.5);\n        vec2 param_10 = _7729 + vec2(3.5, 10.5);\n        vec2 param_11 = _7729 + vec2(4.5, 10.5);\n        vec2 param_12 = _7729 + vec2(5.5, 10.5);\n        vec2 param_13 = _7729 + vec2(6.5, 10.5);\n        vec2 param_14 = _7729 + vec2(7.5, 10.5);\n        vec2 param_15 = _7729 + vec2(8.5, 10.5);\n        acc += ((((((((((fa_gi_fetch(param_7).xyz * 0.2820948064327239990234375) + (fa_gi_fetch(param_8).xyz * _7559)) + (fa_gi_fetch(param_9).xyz * _7563)) + (fa_gi_fetch(param_10).xyz * _7567)) + (fa_gi_fetch(param_11).xyz * _7574)) + (fa_gi_fetch(param_12).xyz * _7581)) + (fa_gi_fetch(param_13).xyz * _7590)) + (fa_gi_fetch(param_14).xyz * _7597)) + (fa_gi_fetch(param_15).xyz * _7610)) * w);\n        wsum += w;\n    }\n    if (!(wsum > 9.9999997473787516355514526367188e-06))\n    {\n        return vec3(0.0);\n    }\n    cover = smoothstep(0.0, 1.0, clamp(_7510 * 2.0, 0.0, 1.0)) * smoothstep(0.0, 0.0199999995529651641845703125, wsum);\n    float _7961;\n    if (fa_mesh_fs_params[52].z > 0.5)\n    {\n        _7961 = _7463.x;\n    }\n    else\n    {\n        _7961 = 1.0;\n    }\n    return max(acc / vec3(wsum), vec3(0.0)) * (_7458.w * _7961);\n}\n\nvec3 fa_gi_light(vec3 n, inout float left)\n{\n    left = 1.0;\n    vec3 acc = vec3(0.0);\n    vec3 _7985 = normalize(fa_mesh_fs_params[0].xyz - fa_world_pos);\n    int _7990 = int(fa_mesh_fs_params[52].x + 0.5);\n    int _7995 = int(fa_mesh_fs_params[52].y + 0.5);\n    float param_3;\n    for (int k = 0; (k < _7995) && (k < 8); k++)\n    {\n        int param = _7990 + (4 * k);\n        vec3 param_1 = n;\n        vec3 param_2 = _7985;\n        vec3 _8020 = fa_gi_grid(param, param_1, param_2, param_3);\n        float _8025 = param_3 * left;\n        acc += (_8020 * _8025);\n        left -= _8025;\n        if (left < 0.001000000047497451305389404296875)\n        {\n            left = 0.0;\n            break;\n        }\n    }\n    return acc;\n}\n\nvec3 fa_realtime_or_ambient(vec3 n)\n{\n    vec3 gi = vec3(0.0);\n    float left = 1.0;\n    if (fa_mesh_fs_params[52].y > 0.5)\n    {\n        vec3 param = n;\n        float param_1;\n        vec3 _8054 = fa_gi_light(param, param_1);\n        left = param_1;\n        gi = _8054;\n    }\n    if (left <= 0.0)\n    {\n        return gi;\n    }\n    vec3 param_2 = n;\n    return gi + (fa_ambient_light(param_2) * left);\n}\n\nvec3 fa_indirect_diffuse(vec3 n)\n{\n    if (fa_lm.z > 0.5)\n    {\n        return textureLod(fa_lightmap_fa_env_smp, fa_lm.xy, 0.0).xyz;\n    }\n    if (fa_mesh_fs_params[32].w > 0.0)\n    {\n        vec3 c[9];\n        for (int k = 0; k < 9; k++)\n        {\n            c[k] = fa_mesh_fs_params[k * 1 + 32].xyz;\n        }\n        vec3 param = n;\n        vec3 param_1[9] = c;\n        vec3 param_2 = n;\n        return mix(fa_ambient_light(param), fa_sh_eval(param_1, param_2), vec3(clamp(fa_mesh_fs_params[32].w, 0.0, 1.0)));\n    }\n    vec3 param_3 = n;\n    return fa_realtime_or_ambient(param_3);\n}\n\nint fa_cluster_index(int slot, int n)\n{\n    int param = (int(fa_mesh_fs_params[19].x) + int(fa_mesh_fs_params[19].w)) + ((slot + n) >> 2);\n    vec4 t = fa_light_texel(param);\n    return int(t[(slot + n) & 3]);\n}\n\nint fa_cl_light(int n)\n{\n    if (n < fa_cl_ndir)\n    {\n        return n;\n    }\n    int param = fa_cl_slot;\n    int param_1 = n - fa_cl_ndir;\n    return fa_cluster_index(param, param_1);\n}\n\nint fa_light_base(int li)\n{\n    return li * ((fa_mesh_fs_params[1].w > 4.5) ? 8 : 4);\n}\n\nbool fa_light_baked(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 3;\n    return fa_light_texel(param_1).w > 0.5;\n}\n\nfloat fa_baked_keep(int li)\n{\n    float _5935;\n    if (fa_lm.z > 0.5)\n    {\n        _5935 = 0.0;\n    }\n    else\n    {\n        _5935 = 1.0 - clamp(fa_mesh_fs_params[32].w, 0.0, 1.0);\n    }\n    bool _5946 = _5935 < 1.0;\n    bool _5952;\n    if (_5946)\n    {\n        int param = li;\n        _5952 = fa_light_baked(param);\n    }\n    else\n    {\n        _5952 = _5946;\n    }\n    return _5952 ? _5935 : 1.0;\n}\n\nfloat fa_light_type(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 1;\n    return fa_light_texel(param_1).w;\n}\n\nvec4 fa_atlas_fetch(vec2 texel)\n{\n    return textureLod(fa_light_atlas_fa_env_smp, texel / vec2(textureSize(fa_light_atlas_fa_env_smp, 0)), 0.0);\n}\n\nvec3 fa_cookie_sample(vec2 tile_origin, vec2 uv)\n{\n    vec2 param = (tile_origin + vec2(1.0)) + (clamp(uv, vec2(0.0), vec2(1.0)) * 254.0);\n    return fa_atlas_fetch(param).xyz;\n}\n\nvec3 fa_area_point(vec3 c, vec3 axis, vec3 ru, vec3 uu, float hx, float hy, float shape, vec3 p, vec3 r)\n{\n    bool _837 = dot(r, r) > 0.5;\n    if (shape > 1.5)\n    {\n        vec3 _850 = (c - (ru * hx)) - p;\n        vec3 _856 = ru * (2.0 * hx);\n        float _862 = max(dot(_856, _856), 9.9999999392252902907785028219223e-09);\n        float _866 = dot(_850, _856);\n        float t = clamp((-_866) / _862, 0.0, 1.0);\n        if (_837)\n        {\n            float _881 = dot(r, _856);\n            float _887 = _862 - (_881 * _881);\n            if (abs(_887) > (9.9999997473787516355514526367188e-06 * _862))\n            {\n                t = clamp(((dot(r, _850) * _881) - _866) / _887, 0.0, 1.0);\n            }\n        }\n        return (p + _850) + (_856 * t);\n    }\n    vec3 q = p;\n    float _919 = dot(r, axis);\n    bool _927;\n    if (_837)\n    {\n        _927 = abs(_919) > 9.9999997473787516355514526367188e-05;\n    }\n    else\n    {\n        _927 = _837;\n    }\n    if (_927)\n    {\n        float _937 = dot(c - p, axis) / _919;\n        if (_937 > 0.0)\n        {\n            q = p + (r * _937);\n        }\n    }\n    vec3 _950 = q - c;\n    vec2 xy = vec2(dot(_950, ru), dot(_950, uu));\n    if (shape > 0.5)\n    {\n        float _965 = length(xy);\n        if (_965 > hx)\n        {\n            xy *= (hx / _965);\n        }\n    }\n    else\n    {\n        xy = clamp(xy, vec2(-hx, -hy), vec2(hx, hy));\n    }\n    return (c + (ru * xy.x)) + (uu * xy.y);\n}\n\nint fa_cube_face(vec3 d)\n{\n    vec3 _598 = abs(d);\n    float _600 = _598.x;\n    float _602 = _598.y;\n    bool _603 = _600 >= _602;\n    bool _611;\n    if (_603)\n    {\n        _611 = _600 >= _598.z;\n    }\n    else\n    {\n        _611 = _603;\n    }\n    int _612;\n    if (_611)\n    {\n        _612 = (d.x > 0.0) ? 0 : 1;\n    }\n    else\n    {\n        int _627;\n        if (_602 >= _598.z)\n        {\n            _627 = (d.y > 0.0) ? 2 : 3;\n        }\n        else\n        {\n            _627 = (d.z > 0.0) ? 4 : 5;\n        }\n        _612 = _627;\n    }\n    return _612;\n}\n\nvoid fa_cube_face_basis(int f, out vec3 fwd, out vec3 up)\n{\n    if (f == 0)\n    {\n        fwd = vec3(1.0, 0.0, 0.0);\n        up = vec3(0.0, 1.0, 0.0);\n    }\n    else\n    {\n        if (f == 1)\n        {\n            fwd = vec3(-1.0, 0.0, 0.0);\n            up = vec3(0.0, 1.0, 0.0);\n        }\n        else\n        {\n            if (f == 2)\n            {\n                fwd = vec3(0.0, 1.0, 0.0);\n                up = vec3(0.0, 0.0, 1.0);\n            }\n            else\n            {\n                if (f == 3)\n                {\n                    fwd = vec3(0.0, -1.0, 0.0);\n                    up = vec3(0.0, 0.0, -1.0);\n                }\n                else\n                {\n                    if (f == 4)\n                    {\n                        fwd = vec3(0.0, 0.0, 1.0);\n                        up = vec3(0.0, 1.0, 0.0);\n                    }\n                    else\n                    {\n                        fwd = vec3(0.0, 0.0, -1.0);\n                        up = vec3(0.0, 1.0, 0.0);\n                    }\n                }\n            }\n        }\n    }\n}\n\nfloat fa_ies_sample(vec2 tile_origin, vec3 d, vec3 axis, vec3 right, vec3 up)\n{\n    float _757 = dot(d, right);\n    float _761 = dot(d, up);\n    float _772;\n    if (((_757 * _757) + (_761 * _761)) > 1.0000000133514319600180897396058e-10)\n    {\n        _772 = atan(_761, _757) * 0.15915493667125701904296875;\n    }\n    else\n    {\n        _772 = 0.0;\n    }\n    vec2 param = tile_origin + vec2(1.0 + ((_772 - floor(_772)) * 64.0), 1.0 + (acos(clamp(dot(d, axis), -1.0, 1.0)) * 10.18591594696044921875));\n    return fa_atlas_fetch(param).x;\n}\n\nLightSample fa_light_sample_n(int li, vec3 world_pos, vec3 n)\n{\n    int param = li;\n    int _1003 = fa_light_base(param);\n    bool _1007 = fa_mesh_fs_params[1].w > 4.5;\n    int param_1 = _1003;\n    vec4 _1011 = fa_light_texel(param_1);\n    int param_2 = _1003 + 1;\n    vec4 _1016 = fa_light_texel(param_2);\n    float _1019 = _1016.w;\n    float atten = 1.0;\n    float dist = 0.0;\n    fa_light_tint = vec3(1.0);\n    bool _1031 = _1007 && (_1019 > 2.5);\n    fa_light_is_area = _1031;\n    bool _1033 = _1019 < 0.5;\n    vec3 l;\n    if (_1033)\n    {\n        l = normalize(_1011.xyz);\n        if (_1007)\n        {\n            int param_3 = _1003 + 6;\n            vec4 _1047 = fa_light_texel(param_3);\n            if (_1047.z > 0.5)\n            {\n                int param_4 = _1003 + 4;\n                vec4 _1057 = fa_light_texel(param_4);\n                int param_5 = _1003 + 5;\n                vec4 _1062 = fa_light_texel(param_5);\n                vec2 param_6 = _1047.xy;\n                vec2 param_7 = fract(vec2(dot(world_pos, _1057.xyz) * _1057.w, (-dot(world_pos, _1062.xyz)) * _1062.w) + vec2(0.5));\n                fa_light_tint = fa_cookie_sample(param_6, param_7);\n            }\n        }\n    }\n    else\n    {\n        vec3 _1092 = _1011.xyz;\n        vec3 _1094 = _1092 - world_pos;\n        vec3 to_light = _1094;\n        float _1097 = length(_1094);\n        float reach = _1097;\n        bool front = true;\n        if (_1031)\n        {\n            int param_8 = _1003 + 7;\n            reach = max(_1097 - fa_light_texel(param_8).w, 0.0);\n            int param_9 = _1003 + 4;\n            vec4 _1121 = fa_light_texel(param_9);\n            int param_10 = _1003 + 5;\n            vec4 _1126 = fa_light_texel(param_10);\n            int param_11 = _1003 + 6;\n            vec4 _1131 = fa_light_texel(param_11);\n            float _1132 = _1131.w;\n            int param_12 = _1003 + 2;\n            vec3 _1139 = normalize(fa_light_texel(param_12).xyz);\n            bool _1141 = _1132 > 1.5;\n            bool _1149;\n            if (!_1141)\n            {\n                _1149 = dot(_1139, to_light) < 0.0;\n            }\n            else\n            {\n                _1149 = _1141;\n            }\n            front = _1149;\n            vec3 r = vec3(0.0);\n            vec3 _1158 = fa_mesh_fs_params[0].xyz - world_pos;\n            bool _1162 = dot(n, n) > 0.5;\n            bool _1170;\n            if (_1162)\n            {\n                _1170 = dot(_1158, _1158) > 9.9999999600419720025001879548654e-13;\n            }\n            else\n            {\n                _1170 = _1162;\n            }\n            if (_1170)\n            {\n                r = reflect(-normalize(_1158), normalize(n));\n            }\n            vec3 param_13 = _1092;\n            vec3 param_14 = _1139;\n            vec3 param_15 = _1121.xyz;\n            vec3 param_16 = _1126.xyz;\n            float param_17 = _1121.w;\n            float param_18 = _1126.w;\n            float param_19 = _1132;\n            vec3 param_20 = world_pos;\n            vec3 param_21 = r;\n            to_light = fa_area_point(param_13, param_14, param_15, param_16, param_17, param_18, param_19, param_20, param_21) - world_pos;\n        }\n        float _1206 = length(to_light);\n        dist = _1206;\n        l = to_light / vec3(max(_1206, 9.9999997473787516355514526367188e-05));\n        float _1220 = reach / max(_1011.w, 0.001000000047497451305389404296875);\n        float _1226 = clamp(1.0 - (_1220 * _1220), 0.0, 1.0);\n        float _1228;\n        if (front)\n        {\n            _1228 = _1226 * _1226;\n        }\n        else\n        {\n            _1228 = 0.0;\n        }\n        atten = _1228;\n        bool _1239 = _1019 < 2.5;\n        if ((_1019 > 1.5) && _1239)\n        {\n            int param_22 = _1003 + 2;\n            vec4 _1247 = fa_light_texel(param_22);\n            float _1257 = _1247.w;\n            int param_23 = _1003 + 3;\n            vec4 _1262 = fa_light_texel(param_23);\n            float _1263 = _1262.x;\n            float cos_inner = _1263;\n            if (_1263 > 1.5)\n            {\n                cos_inner = mix(_1257, 1.0, 0.25);\n            }\n            atten *= smoothstep(_1257, cos_inner, dot(-l, normalize(_1247.xyz)));\n        }\n        if (_1007 && (_1019 < 1.5))\n        {\n            int param_24 = _1003 + 6;\n            vec4 _1287 = fa_light_texel(param_24);\n            if (_1287.z > 0.5)\n            {\n                vec3 _1295 = -to_light;\n                int param_25 = _1003 + 4;\n                int param_26 = _1003 + 5;\n                vec3 _1309 = fa_light_texel(param_25).xyz;\n                vec3 _1313 = fa_light_texel(param_26).xyz;\n                vec3 _1322 = vec3(dot(_1295, _1309), dot(_1295, _1313), dot(_1295, cross(_1309, _1313)));\n                vec3 param_27 = _1322;\n                int _1326 = fa_cube_face(param_27);\n                int param_28 = _1326;\n                vec3 param_29;\n                vec3 param_30;\n                fa_cube_face_basis(param_28, param_29, param_30);\n                vec2 _1353 = vec2(dot(_1322, cross(param_29, param_30)), dot(_1322, param_30)) / vec2(max(dot(_1322, param_29), 9.9999997473787516355514526367188e-05));\n                int _1357 = _1326 / 3;\n                vec2 param_31 = _1287.xy + (vec2(float(_1326 - (_1357 * 3)), float(_1357)) * 256.0);\n                vec2 param_32 = vec2(0.5 + (0.5 * _1353.x), 0.5 - (0.5 * _1353.y));\n                fa_light_tint = fa_cookie_sample(param_31, param_32);\n            }\n            int param_33 = _1003 + 7;\n            vec4 _1387 = fa_light_texel(param_33);\n            if (_1387.z > 0.5)\n            {\n                int param_34 = _1003 + 2;\n                int param_35 = _1003 + 4;\n                int param_36 = _1003 + 5;\n                vec2 param_37 = _1387.xy;\n                vec3 param_38 = -l;\n                vec3 param_39 = normalize(fa_light_texel(param_34).xyz);\n                vec3 param_40 = fa_light_texel(param_35).xyz;\n                vec3 param_41 = fa_light_texel(param_36).xyz;\n                atten *= fa_ies_sample(param_37, param_38, param_39, param_40, param_41);\n            }\n        }\n        else\n        {\n            if (_1007 && _1239)\n            {\n                int param_42 = _1003 + 6;\n                vec4 _1434 = fa_light_texel(param_42);\n                int param_43 = _1003 + 7;\n                vec4 _1439 = fa_light_texel(param_43);\n                bool _1442 = _1434.z > 0.5;\n                bool _1449;\n                if (!_1442)\n                {\n                    _1449 = _1439.z > 0.5;\n                }\n                else\n                {\n                    _1449 = _1442;\n                }\n                if (_1449)\n                {\n                    int param_44 = _1003 + 2;\n                    vec4 _1456 = fa_light_texel(param_44);\n                    vec3 _1460 = normalize(_1456.xyz);\n                    int param_45 = _1003 + 4;\n                    vec4 _1465 = fa_light_texel(param_45);\n                    int param_46 = _1003 + 5;\n                    vec4 _1470 = fa_light_texel(param_46);\n                    if (_1442)\n                    {\n                        vec3 _1478 = -to_light;\n                        float _1485 = _1456.w;\n                        float _1501 = 0.5 / max(dot(_1478, _1460) * (sqrt(max(1.0 - (_1485 * _1485), 0.0)) / max(_1485, 0.001000000047497451305389404296875)), 9.9999997473787516355514526367188e-05);\n                        vec2 param_47 = _1434.xy;\n                        vec2 param_48 = vec2(0.5 + (dot(_1478, _1465.xyz) * _1501), 0.5 - (dot(_1478, _1470.xyz) * _1501));\n                        fa_light_tint = fa_cookie_sample(param_47, param_48);\n                    }\n                    if (_1439.z > 0.5)\n                    {\n                        vec2 param_49 = _1439.xy;\n                        vec3 param_50 = -l;\n                        vec3 param_51 = _1460;\n                        vec3 param_52 = _1465.xyz;\n                        vec3 param_53 = _1470.xyz;\n                        atten *= fa_ies_sample(param_49, param_50, param_51, param_52, param_53);\n                    }\n                }\n            }\n        }\n    }\n    vec3 _9141 = _1016.xyz * atten;\n    if (_1007)\n    {\n        _9141 *= fa_light_tint;\n    }\n    int _1570;\n    if (_1033)\n    {\n        _1570 = 0;\n    }\n    else\n    {\n        _1570 = ((_1019 > 1.5) && (_1019 < 2.5)) ? 2 : 1;\n    }\n    return LightSample(l, _9141, atten, 1.0, dist, _1570);\n}\n\nfloat fa_shadow_split_at(int i)\n{\n    float _2302;\n    if (i == 0)\n    {\n        _2302 = fa_shadows[24].x;\n    }\n    else\n    {\n        float _2318;\n        if (i == 1)\n        {\n            _2318 = fa_shadows[24].y;\n        }\n        else\n        {\n            float _2326;\n            if (i == 2)\n            {\n                _2326 = fa_shadows[24].z;\n            }\n            else\n            {\n                _2326 = fa_shadows[24].w;\n            }\n            _2318 = _2326;\n        }\n        _2302 = _2318;\n    }\n    return _2302;\n}\n\nfloat fa_shadow_depth(inout vec2 uv, vec4 rect)\n{\n    uv = clamp(uv, rect.xy, rect.zw);\n    return textureLod(fa_shadow_tex_fa_shadow_smp, uv, 0.0).x;\n}\n\nfloat fa_shadow_fetch(vec2 uv, vec4 rect, vec3 conv)\n{\n    vec2 param = uv;\n    vec4 param_1 = rect;\n    float _2359 = fa_shadow_depth(param, param_1);\n    float _2363;\n    if (conv.x < 0.5)\n    {\n        _2363 = _2359;\n    }\n    else\n    {\n        _2363 = (conv.y * conv.z) / (conv.z - (_2359 * (conv.z - conv.y)));\n    }\n    return _2363;\n}\n\nfloat fa_shadow_noise()\n{\n    return fract(52.98291778564453125 * fract(dot(gl_FragCoord.xy, vec2(0.067110560834407806396484375, 0.005837149918079376220703125))));\n}\n\nvec2 fa_shadow_vogel_turn(vec2 d)\n{\n    return vec2((d.x * (-0.737368881702423095703125)) - (d.y * 0.675490319728851318359375), (d.y * (-0.737368881702423095703125)) + (d.x * 0.675490319728851318359375));\n}\n\nfloat fa_shadow_filter(vec2 uv, vec4 rect, float zr, float texel_m, float unit, float reach, float plane, vec3 conv, int mode, float k)\n{\n    if (mode == 1)\n    {\n        vec2 param = uv;\n        vec4 param_1 = rect;\n        vec3 param_2 = conv;\n        return float(zr <= fa_shadow_fetch(param, param_1, param_2));\n    }\n    float _2409 = fa_shadow_noise() * 6.283185482025146484375;\n    vec2 _2415 = vec2(cos(_2409), sin(_2409));\n    vec2 dir = _2415;\n    float radius = 1.5;\n    if (mode == 2)\n    {\n        float _2424;\n        if (k < 0.0)\n        {\n            _2424 = (-k) / max(zr, 0.100000001490116119384765625);\n        }\n        else\n        {\n            _2424 = k;\n        }\n        float _2443 = clamp((_2424 * reach) / texel_m, 3.0, 12.0);\n        float sum = 0.0;\n        float cnt = 0.0;\n        for (int i = 0; i < 16; i++)\n        {\n            float _2462 = sqrt((float(i) + 0.5) * 0.0625) * _2443;\n            vec2 param_3 = uv + (dir * (fa_shadows[26].zw * _2462));\n            vec4 param_4 = rect;\n            vec3 param_5 = conv;\n            float _2476 = fa_shadow_fetch(param_3, param_4, param_5);\n            if (_2476 < (zr - (_2462 * plane)))\n            {\n                sum += _2476;\n                cnt += 1.0;\n            }\n            vec2 param_6 = dir;\n            dir = fa_shadow_vogel_turn(param_6);\n        }\n        if (cnt < 0.5)\n        {\n            return 1.0;\n        }\n        float _2504 = sum / cnt;\n        float _2514;\n        if (k < 0.0)\n        {\n            _2514 = (-k) / max(_2504, 0.0500000007450580596923828125);\n        }\n        else\n        {\n            _2514 = k;\n        }\n        radius = clamp(((max(zr - _2504, 0.0) * unit) * _2514) / texel_m, 1.5, 16.0);\n        dir = _2415;\n    }\n    float lit = 0.0;\n    int _2540 = (mode == 2) ? 24 : 16;\n    for (int i_1 = 0; i_1 < _2540; i_1++)\n    {\n        float _2559 = sqrt((float(i_1) + 0.5) / float(_2540)) * radius;\n        vec2 param_7 = uv + (dir * (fa_shadows[26].zw * _2559));\n        vec4 param_8 = rect;\n        vec3 param_9 = conv;\n        lit += float((zr - (_2559 * plane)) <= fa_shadow_fetch(param_7, param_8, param_9));\n        vec2 param_10 = dir;\n        dir = fa_shadow_vogel_turn(param_10);\n    }\n    return lit / float(_2540);\n}\n\nfloat fa_shadow_cascade(int ci, vec3 world, vec3 n, vec3 l)\n{\n    float _2605 = max(fa_shadows[ci * 1 + 20].y, 0.001000000047497451305389404296875);\n    float _2610 = clamp(dot(n, l), 0.0, 1.0);\n    float _2616 = sqrt(1.0 - (_2610 * _2610));\n    float _2624 = min(_2616 / max(_2610, 0.20000000298023223876953125), 4.0);\n    float _2629;\n    if (fa_shadows[26].y > 0.0)\n    {\n        _2629 = fa_shadows[26].y;\n    }\n    else\n    {\n        _2629 = 1.5 * fa_shadows[ci * 1 + 20].x;\n    }\n    vec4 _2654 = mat4(fa_shadows[ci * 4 + 0], fa_shadows[ci * 4 + 1], fa_shadows[ci * 4 + 2], fa_shadows[ci * 4 + 3]) * vec4(world + (n * (_2629 * _2616)), 1.0);\n    float _2661 = _2654.x;\n    bool _2664 = _2661 < fa_shadows[ci * 1 + 16].x;\n    bool _2673;\n    if (!_2664)\n    {\n        _2673 = _2661 > fa_shadows[ci * 1 + 16].z;\n    }\n    else\n    {\n        _2673 = _2664;\n    }\n    bool _2682;\n    if (!_2673)\n    {\n        _2682 = _2654.y < fa_shadows[ci * 1 + 16].y;\n    }\n    else\n    {\n        _2682 = _2673;\n    }\n    bool _2691;\n    if (!_2682)\n    {\n        _2691 = _2654.y > fa_shadows[ci * 1 + 16].w;\n    }\n    else\n    {\n        _2691 = _2682;\n    }\n    bool _2698;\n    if (!_2691)\n    {\n        _2698 = _2654.z > 1.0;\n    }\n    else\n    {\n        _2698 = _2691;\n    }\n    if (_2698)\n    {\n        return -1.0;\n    }\n    float _2706;\n    if (fa_shadows[26].x > 0.0)\n    {\n        _2706 = fa_shadows[26].x;\n    }\n    else\n    {\n        _2706 = 1.5 * fa_shadows[ci * 1 + 20].x;\n    }\n    vec2 param = _2654.xy;\n    vec4 param_1 = fa_shadows[ci * 1 + 16];\n    float param_2 = _2654.z - ((_2706 * (1.0 + (0.5 * _2624))) / _2605);\n    float param_3 = fa_shadows[ci * 1 + 20].x;\n    float param_4 = _2605;\n    float param_5 = _2605 * 0.25;\n    float param_6 = ((fa_shadows[ci * 1 + 20].x * min(_2624, 3.0)) * 0.5) / _2605;\n    vec3 param_7 = vec3(0.0);\n    int param_8 = int(fa_shadows[25].z + 0.5);\n    float param_9 = fa_shadows[25].w;\n    return fa_shadow_filter(param, param_1, param_2, param_3, param_4, param_5, param_6, param_7, param_8, param_9);\n}\n\nfloat fa_shadow_sun(vec3 world, vec3 n, vec3 l)\n{\n    if (fa_mesh_fs_params[5].z < 0.5)\n    {\n        return 1.0;\n    }\n    int _3084 = int(fa_shadows[25].x + 0.5);\n    if (_3084 < 1)\n    {\n        return 1.0;\n    }\n    float _3099 = dot(world - fa_shadows[27].xyz, fa_shadows[28].xyz);\n    int param = _3084 - 1;\n    if (_3099 > fa_shadow_split_at(param))\n    {\n        return 1.0;\n    }\n    int ci = 0;\n    bool _3111 = _3084 > 1;\n    bool _3118;\n    if (_3111)\n    {\n        _3118 = _3099 > fa_shadows[24].x;\n    }\n    else\n    {\n        _3118 = _3111;\n    }\n    if (_3118)\n    {\n        ci = 1;\n    }\n    bool _3122 = _3084 > 2;\n    bool _3129;\n    if (_3122)\n    {\n        _3129 = _3099 > fa_shadows[24].y;\n    }\n    else\n    {\n        _3129 = _3122;\n    }\n    if (_3129)\n    {\n        ci = 2;\n    }\n    bool _3133 = _3084 > 3;\n    bool _3140;\n    if (_3133)\n    {\n        _3140 = _3099 > fa_shadows[24].z;\n    }\n    else\n    {\n        _3140 = _3133;\n    }\n    if (_3140)\n    {\n        ci = 3;\n    }\n    float s = -1.0;\n    float s2 = -1.0;\n    float t = 0.0;\n    int _3151 = min(_3084, 4);\n    float _3192;\n    for (int c = ci; c < _3151; c++)\n    {\n        int param_1 = c;\n        vec3 param_2 = world;\n        vec3 param_3 = n;\n        vec3 param_4 = l;\n        float _3171 = fa_shadow_cascade(param_1, param_2, param_3, param_4);\n        if (s >= 0.0)\n        {\n            s2 = _3171;\n            break;\n        }\n        if (_3171 < 0.0)\n        {\n            continue;\n        }\n        s = _3171;\n        ci = c;\n        if (fa_shadows[25].y > 0.0)\n        {\n            if (ci > 0)\n            {\n                int param_5 = ci - 1;\n                _3192 = fa_shadow_split_at(param_5);\n            }\n            else\n            {\n                _3192 = fa_shadows[28].w;\n            }\n            int param_6 = ci;\n            float _3211 = fa_shadows[25].y * max(fa_shadow_split_at(param_6) - _3192, 9.9999997473787516355514526367188e-05);\n            int param_7 = ci;\n            t = clamp((_3099 - (fa_shadow_split_at(param_7) - _3211)) / _3211, 0.0, 1.0);\n        }\n        if (t <= 0.0)\n        {\n            break;\n        }\n    }\n    if (s < 0.0)\n    {\n        return 1.0;\n    }\n    if (t > 0.0)\n    {\n        float _3243;\n        if ((ci + 1) < _3084)\n        {\n            _3243 = (s2 < 0.0) ? s : s2;\n        }\n        else\n        {\n            _3243 = 1.0;\n        }\n        s = mix(s, _3243, t);\n    }\n    return s;\n}\n\nfloat fa_shadow_factor(vec3 n, vec3 l)\n{\n    bool _3348 = fa_mesh_fs_params[25].y > 0.5;\n    bool _3354;\n    if (_3348)\n    {\n        _3354 = fa_mesh_fs_params[5].z > 0.5;\n    }\n    else\n    {\n        _3354 = _3348;\n    }\n    if (_3354)\n    {\n        vec4 _3364 = vec4(fa_world_pos, 1.0);\n        float _3370 = dot(fa_mesh_fs_params[28], _3364);\n        if (_3370 > 9.9999997473787516355514526367188e-05)\n        {\n            vec2 _3389 = vec2(dot(fa_mesh_fs_params[26], _3364), dot(fa_mesh_fs_params[27], _3364)) / vec2(_3370);\n            float _3394 = (_3389.x * 0.5) + 0.5;\n            float _3398;\n            if (fa_mesh_fs_params[24].y > 0.5)\n            {\n                _3398 = (_3389.y * 0.5) + 0.5;\n            }\n            else\n            {\n                _3398 = 0.5 - (_3389.y * 0.5);\n            }\n            bool _3414 = _3394 >= 0.0;\n            bool _3420;\n            if (_3414)\n            {\n                _3420 = _3394 < 1.0;\n            }\n            else\n            {\n                _3420 = _3414;\n            }\n            bool _3426;\n            if (_3420)\n            {\n                _3426 = _3398 >= 0.0;\n            }\n            else\n            {\n                _3426 = _3420;\n            }\n            bool _3432;\n            if (_3426)\n            {\n                _3432 = _3398 < 1.0;\n            }\n            else\n            {\n                _3432 = _3426;\n            }\n            if (_3432)\n            {\n                vec4 _3458 = texelFetch(fa_screen_tex_fa_shadow_smp, clamp(ivec2(vec2(_3394, _3398) * fa_mesh_fs_params[24].zw), ivec2(0), ivec2(fa_mesh_fs_params[24].zw) - ivec2(1)), 0);\n                float _3468 = dot(fa_mesh_fs_params[29].xyz, fa_world_pos) + fa_mesh_fs_params[29].w;\n                bool _3471 = _3458.w > 0.5;\n                bool _3485;\n                if (_3471)\n                {\n                    _3485 = abs(_3468 - _3458.x) <= ((0.00200000009499490261077880859375 * _3468) + 0.00999999977648258209228515625);\n                }\n                else\n                {\n                    _3485 = _3471;\n                }\n                if (_3485)\n                {\n                    return _3458.y;\n                }\n            }\n        }\n    }\n    vec3 param = fa_world_pos;\n    vec3 param_1 = n;\n    vec3 param_2 = l;\n    return fa_shadow_sun(param, param_1, param_2);\n}\n\nfloat fa_shadow_local(int li, vec3 lpos, vec3 world, vec3 n, vec3 l)\n{\n    bool _2764 = fa_mesh_fs_params[5].z < 0.5;\n    bool _2771;\n    if (!_2764)\n    {\n        _2771 = fa_shadows[29].x < 0.5;\n    }\n    else\n    {\n        _2771 = _2764;\n    }\n    if (_2771)\n    {\n        return 1.0;\n    }\n    int param = (int(fa_shadows[29].x + 0.5) - 1) + li;\n    vec4 _2784 = fa_light_texel(param);\n    float _2785 = _2784.x;\n    if (_2785 < 0.0)\n    {\n        return 1.0;\n    }\n    int _2794 = int(_2785 + 0.5);\n    int param_1 = _2794;\n    vec4 _2798 = fa_light_texel(param_1);\n    int param_2 = _2794 + 1;\n    vec4 _2803 = fa_light_texel(param_2);\n    float fade = 1.0;\n    float _2806 = _2798.y;\n    if (_2806 > 0.0)\n    {\n        float _2823 = 1.0 - smoothstep(0.75 * _2806, _2806, length(world - fa_shadows[27].xyz));\n        fade = _2823;\n        if (_2823 <= 0.0)\n        {\n            return 1.0;\n        }\n    }\n    int face = 0;\n    if (_2798.x > 1.5)\n    {\n        vec3 param_3 = world - lpos;\n        face = fa_cube_face(param_3);\n    }\n    int _2847 = (_2794 + 2) + (face * 6);\n    int param_4 = _2847;\n    int param_5 = _2847 + 1;\n    int param_6 = _2847 + 3;\n    vec4 _2861 = fa_light_texel(param_6);\n    int param_7 = _2847 + 4;\n    vec4 _2866 = fa_light_texel(param_7);\n    int param_8 = _2847 + 5;\n    vec4 _2871 = fa_light_texel(param_8);\n    float _2883 = _2871.x * max(dot(_2861, vec4(world, 1.0)), 0.001000000047497451305389404296875);\n    float _2888 = clamp(dot(n, l), 0.0, 1.0);\n    float _2911 = clamp(dot(n, _2861.xyz), -1.0, 1.0);\n    float _2930 = min(sqrt(1.0 - (_2911 * _2911)) / max(abs(dot(n, world - lpos)) / max(dot(_2861, vec4(world, 1.0)), 0.001000000047497451305389404296875), 0.20000000298023223876953125), 4.0);\n    float _2933 = _2803.y;\n    float _2935;\n    if (_2933 > 0.0)\n    {\n        _2935 = _2933;\n    }\n    else\n    {\n        _2935 = 1.5 * _2883;\n    }\n    vec4 _2955 = vec4(world + (n * (_2935 * sqrt(1.0 - (_2888 * _2888)))), 1.0);\n    float _2959 = dot(_2861, _2955);\n    float _2962 = _2871.y;\n    if (_2959 < _2962)\n    {\n        return 1.0;\n    }\n    vec2 _2977 = vec2(dot(fa_light_texel(param_4), _2955), dot(fa_light_texel(param_5), _2955)) / vec2(_2959);\n    float _2979 = _2977.x;\n    bool _2982 = _2979 < _2866.x;\n    bool _2991;\n    if (!_2982)\n    {\n        _2991 = _2979 > _2866.z;\n    }\n    else\n    {\n        _2991 = _2982;\n    }\n    bool _3000;\n    if (!_2991)\n    {\n        _3000 = _2977.y < _2866.y;\n    }\n    else\n    {\n        _3000 = _2991;\n    }\n    bool _3009;\n    if (!_3000)\n    {\n        _3009 = _2977.y > _2866.w;\n    }\n    else\n    {\n        _3009 = _3000;\n    }\n    if (_3009)\n    {\n        return 1.0;\n    }\n    float _3015 = _2803.x;\n    float _3017;\n    if (_3015 > 0.0)\n    {\n        _3017 = _3015;\n    }\n    else\n    {\n        _3017 = 1.5 * _2883;\n    }\n    vec2 param_9 = _2977;\n    vec4 param_10 = _2866;\n    float param_11 = _2959 - (_3017 * (1.0 + (0.5 * _2930)));\n    float param_12 = _2883;\n    float param_13 = 1.0;\n    float param_14 = _2871.z * 0.25;\n    float param_15 = (_2883 * min(_2930, 3.0)) * 0.5;\n    vec3 param_16 = vec3(1.0, _2962, _2871.z);\n    int param_17 = int(_2798.z + 0.5);\n    float param_18 = _2798.w;\n    return mix(1.0, fa_shadow_filter(param_9, param_10, param_11, param_12, param_13, param_14, param_15, param_16, param_17, param_18), fade);\n}\n\nfloat fa_contact_shadow(int li, vec3 world, vec3 gn, vec3 l, float dist)\n{\n    bool _5316 = fa_mesh_fs_params[24].x < 0.5;\n    bool _5323;\n    if (!_5316)\n    {\n        _5323 = fa_shadows[29].x < 0.5;\n    }\n    else\n    {\n        _5323 = _5316;\n    }\n    if (_5323)\n    {\n        return 1.0;\n    }\n    int param = (int(fa_shadows[29].x + 0.5) - 1) + li;\n    vec4 _5336 = fa_light_texel(param);\n    float _5337 = _5336.y;\n    float len = _5337;\n    if (_5337 <= 0.0)\n    {\n        return 1.0;\n    }\n    float _5349 = length(world - fa_mesh_fs_params[0].xyz);\n    float _5358 = 1.0 - smoothstep(0.5 * fa_mesh_fs_params[25].x, fa_mesh_fs_params[25].x, _5349);\n    if (_5358 <= 0.0)\n    {\n        return 1.0;\n    }\n    float _5364 = len;\n    float _5367 = min(_5364, 0.89999997615814208984375 * dist);\n    len = _5367;\n    float _5372 = 0.004999999888241291046142578125 + (0.0030000000260770320892333984375 * _5349);\n    float _5377 = _5372 + (0.5 * _5367);\n    vec3 _5383 = world + (gn * _5372);\n    float _5385 = fa_shadow_noise();\n    float occ = 0.0;\n    float _5446;\n    for (int k = 0; k < 12; k++)\n    {\n        float _5400 = (float(k) + _5385) * 0.083333335816860198974609375;\n        vec3 _5408 = _5383 + (l * (_5400 * len));\n        vec4 _5414 = vec4(_5408, 1.0);\n        float _5419 = dot(fa_mesh_fs_params[28], _5414);\n        if (_5419 < 9.9999997473787516355514526367188e-05)\n        {\n            break;\n        }\n        vec2 _5437 = vec2(dot(fa_mesh_fs_params[26], _5414), dot(fa_mesh_fs_params[27], _5414)) / vec2(_5419);\n        float _5441 = _5437.x * 0.5;\n        float _5442 = _5441 + 0.5;\n        if (fa_mesh_fs_params[24].y > 0.5)\n        {\n            _5446 = (_5437.y * 0.5) + 0.5;\n        }\n        else\n        {\n            _5446 = 0.5 - (_5437.y * 0.5);\n        }\n        bool _5462 = _5442 < 0.0;\n        bool _5469;\n        if (!_5462)\n        {\n            _5469 = _5442 >= 1.0;\n        }\n        else\n        {\n            _5469 = _5462;\n        }\n        bool _5476;\n        if (!_5469)\n        {\n            _5476 = _5446 < 0.0;\n        }\n        else\n        {\n            _5476 = _5469;\n        }\n        bool _5483;\n        if (!_5476)\n        {\n            _5483 = _5446 >= 1.0;\n        }\n        else\n        {\n            _5483 = _5476;\n        }\n        if (_5483)\n        {\n            break;\n        }\n        vec4 _5507 = texelFetch(fa_screen_tex_fa_shadow_smp, clamp(ivec2(vec2(_5442, _5446) * fa_mesh_fs_params[24].zw), ivec2(0), ivec2(fa_mesh_fs_params[24].zw) - ivec2(1)), 0);\n        if (_5507.w < 0.5)\n        {\n            continue;\n        }\n        float _5525 = (dot(fa_mesh_fs_params[29].xyz, _5408) + fa_mesh_fs_params[29].w) - _5507.x;\n        if ((_5525 > _5372) && (_5525 < _5377))\n        {\n            occ = max(occ, (1.0 - (_5400 * _5400)) * smoothstep(0.0, 0.0500000007450580596923828125, min(min(_5442, 0.5 - _5441), min(_5446, 1.0 - _5446))));\n        }\n    }\n    return 1.0 - (occ * _5358);\n}\n\nLightSample fa_light_shadowed(int li, vec3 world_pos, vec3 gn)\n{\n    int param = li;\n    float _5991 = fa_baked_keep(param);\n    if (_5991 <= 0.0)\n    {\n        int param_1 = li;\n        return LightSample(vec3(0.0, 1.0, 0.0), vec3(0.0), 0.0, 1.0, 0.0, int(fa_light_type(param_1) + 0.5));\n    }\n    int param_2 = li;\n    vec3 param_3 = world_pos;\n    vec3 param_4 = gn;\n    LightSample _6017 = fa_light_sample_n(param_2, param_3, param_4);\n    vec3 _9210 = _6017.color;\n    float _9211 = _6017.attenuation;\n    float _9212 = _6017.shadow;\n    bool _6020 = _6017.type == 0;\n    if (_6020 && (li == 0))\n    {\n        vec3 param_5 = gn;\n        vec3 param_6 = _6017.direction;\n        float _6031 = fa_shadow_factor(param_5, param_6);\n        _9212 = _6031;\n        _9210 *= _6031;\n    }\n    else\n    {\n        bool _6042 = _6017.type != 0;\n        bool _6048;\n        if (_6042)\n        {\n            _6048 = _9211 > 0.0;\n        }\n        else\n        {\n            _6048 = _6042;\n        }\n        if (_6048)\n        {\n            int param_7 = li;\n            int param_8 = fa_light_base(param_7);\n            int param_9 = li;\n            vec3 param_10 = fa_light_texel(param_8).xyz;\n            vec3 param_11 = world_pos;\n            vec3 param_12 = gn;\n            vec3 param_13 = _6017.direction;\n            float _6067 = fa_shadow_local(param_9, param_10, param_11, param_12, param_13);\n            _9212 = _6067;\n            _9210 *= _6067;\n        }\n    }\n    bool _6077 = fa_mesh_fs_params[24].x > 0.5;\n    bool _6083;\n    if (_6077)\n    {\n        _6083 = _9211 > 0.0;\n    }\n    else\n    {\n        _6083 = _6077;\n    }\n    if (_6083)\n    {\n        float _6090;\n        if (_6020)\n        {\n            _6090 = 1000000000.0;\n        }\n        else\n        {\n            _6090 = _6017._distance;\n        }\n        int param_14 = li;\n        vec3 param_15 = world_pos;\n        vec3 param_16 = gn;\n        vec3 param_17 = _6017.direction;\n        float param_18 = _6090;\n        float _6108 = fa_contact_shadow(param_14, param_15, param_16, param_17, param_18);\n        _9212 *= _6108;\n        _9210 *= _6108;\n    }\n    float _6121 = _9211;\n    float _6122 = _6121 * _5991;\n    _9211 = _6122;\n    vec3 _6126 = _9210;\n    vec3 _6127 = _6126 * _5991;\n    _9210 = _6127;\n    return LightSample(_6017.direction, _6127, _6122, _9212, _6017._distance, _6017.type);\n}\n\nvec3 fa_ltc_tangent(vec3 n, vec3 v)\n{\n    vec3 _6161 = v - (n * dot(v, n));\n    vec3 t = _6161;\n    float _6165 = dot(_6161, _6161);\n    float l2 = _6165;\n    if (_6165 < 1.0000000133514319600180897396058e-10)\n    {\n        vec3 _6175;\n        if (abs(n.z) < 0.999000012874603271484375)\n        {\n            _6175 = cross(n, vec3(0.0, 0.0, 1.0));\n        }\n        else\n        {\n            _6175 = cross(n, vec3(1.0, 0.0, 0.0));\n        }\n        t = _6175;\n        l2 = dot(_6175, _6175);\n    }\n    return t * inversesqrt(l2);\n}\n\nvec3 fa_ltc_local(vec3 t1, vec3 n, vec3 p)\n{\n    return vec3(dot(t1, p), dot(cross(n, t1), p), dot(n, p));\n}\n\nvec2 fa_ltc_uv(float roughness, float ndv)\n{\n    return ((vec2(clamp((roughness - 0.0500000007450580596923828125) * 1.0526316165924072265625, 0.0, 1.0), sqrt(clamp(1.0 - ndv, 0.0, 1.0))) * 63.0) + vec2(0.5)) * vec2(0.015625);\n}\n\nvec3 fa_oct_vertex(int j, vec3 pc, vec3 ex, vec3 ey)\n{\n    float _6562;\n    if ((j == 0) || (j == 7))\n    {\n        _6562 = 0.92387950420379638671875;\n    }\n    else\n    {\n        float _6572;\n        if ((j == 3) || (j == 4))\n        {\n            _6572 = -0.92387950420379638671875;\n        }\n        else\n        {\n            _6572 = ((j == 1) || (j == 6)) ? 0.3826834261417388916015625 : (-0.3826834261417388916015625);\n        }\n        _6562 = _6572;\n    }\n    float _6593;\n    if ((j == 1) || (j == 2))\n    {\n        _6593 = 0.92387950420379638671875;\n    }\n    else\n    {\n        float _6602;\n        if ((j == 5) || (j == 6))\n        {\n            _6602 = -0.92387950420379638671875;\n        }\n        else\n        {\n            _6602 = ((j == 0) || (j == 3)) ? 0.3826834261417388916015625 : (-0.3826834261417388916015625);\n        }\n        _6593 = _6602;\n    }\n    return (pc + (ex * _6562)) + (ey * _6593);\n}\n\nvec3 fa_ltc_edge_vector(vec3 a, vec3 b)\n{\n    float _6210 = dot(a, a);\n    float _6214 = dot(b, b);\n    if ((_6210 < 1.0000000195414813782625560981111e-24) || (_6214 < 1.0000000195414813782625560981111e-24))\n    {\n        return vec3(0.0);\n    }\n    vec3 _6228 = a * inversesqrt(_6210);\n    vec3 _6233 = b * inversesqrt(_6214);\n    float _6237 = dot(_6228, _6233);\n    float _6240 = abs(_6237);\n    float g = (((((((((((0.0416471660137176513671875 * _6240) - 0.1924748718738555908203125) * _6240) + 0.4179156124591827392578125) * _6240) - 0.616057217121124267578125) * _6240) + 0.777722418308258056640625) * _6240) - 0.999542415142059326171875) * _6240) + 1.570791721343994140625;\n    if (_6237 < 0.0)\n    {\n        g = (3.1415927410125732421875 * inversesqrt(max(1.0 - (_6237 * _6237), 1.0000000116860974230803549289703e-07))) - g;\n    }\n    return cross(_6228, _6233) * g;\n}\n\nvoid fa_ltc_clip_edge(vec3 a, vec3 b, inout vec3 sum, inout vec3 leave, inout vec3 enter, inout vec2 seen)\n{\n    bool _6297 = a.z > 0.0;\n    bool _6301 = b.z > 0.0;\n    if (_6297 && _6301)\n    {\n        vec3 param = a;\n        vec3 param_1 = b;\n        sum += fa_ltc_edge_vector(param, param_1);\n    }\n    else\n    {\n        if (_6297 != _6301)\n        {\n            vec3 _6336 = a + ((b - a) * (a.z / (a.z - b.z)));\n            _6336.z = 0.0;\n            if (_6297)\n            {\n                vec3 param_2 = a;\n                vec3 param_3 = _6336;\n                sum += fa_ltc_edge_vector(param_2, param_3);\n                leave = _6336;\n                seen.x = 1.0;\n            }\n            else\n            {\n                vec3 param_4 = _6336;\n                vec3 param_5 = b;\n                sum += fa_ltc_edge_vector(param_4, param_5);\n                enter = _6336;\n                seen.y = 1.0;\n            }\n        }\n    }\n}\n\nfloat fa_ltc_quad(vec4 abcd, vec3 p0, vec3 p1, vec3 p2, vec3 p3)\n{\n    vec3 _6385 = vec3((abcd.x * p0.x) + (abcd.y * p0.z), p0.y, (abcd.z * p0.x) + (abcd.w * p0.z));\n    vec3 _6411 = vec3((abcd.x * p1.x) + (abcd.y * p1.z), p1.y, (abcd.z * p1.x) + (abcd.w * p1.z));\n    vec3 _6437 = vec3((abcd.x * p2.x) + (abcd.y * p2.z), p2.y, (abcd.z * p2.x) + (abcd.w * p2.z));\n    vec3 _6463 = vec3((abcd.x * p3.x) + (abcd.y * p3.z), p3.y, (abcd.z * p3.x) + (abcd.w * p3.z));\n    vec3 sum = vec3(0.0);\n    vec3 leave = vec3(0.0);\n    vec3 enter = vec3(0.0);\n    vec3 param = _6385;\n    vec3 param_1 = _6411;\n    vec3 param_2 = vec3(0.0);\n    vec3 param_3 = vec3(0.0);\n    vec3 param_4 = vec3(0.0);\n    vec2 param_5 = vec2(0.0);\n    fa_ltc_clip_edge(param, param_1, param_2, param_3, param_4, param_5);\n    sum = param_2;\n    leave = param_3;\n    enter = param_4;\n    vec3 param_6 = _6411;\n    vec3 param_7 = _6437;\n    vec3 param_8 = param_2;\n    vec3 param_9 = param_3;\n    vec3 param_10 = param_4;\n    vec2 param_11 = param_5;\n    fa_ltc_clip_edge(param_6, param_7, param_8, param_9, param_10, param_11);\n    sum = param_8;\n    leave = param_9;\n    enter = param_10;\n    vec3 param_12 = _6437;\n    vec3 param_13 = _6463;\n    vec3 param_14 = param_8;\n    vec3 param_15 = param_9;\n    vec3 param_16 = param_10;\n    vec2 param_17 = param_11;\n    fa_ltc_clip_edge(param_12, param_13, param_14, param_15, param_16, param_17);\n    sum = param_14;\n    leave = param_15;\n    enter = param_16;\n    vec3 param_18 = _6463;\n    vec3 param_19 = _6385;\n    vec3 param_20 = param_14;\n    vec3 param_21 = param_15;\n    vec3 param_22 = param_16;\n    vec2 param_23 = param_17;\n    fa_ltc_clip_edge(param_18, param_19, param_20, param_21, param_22, param_23);\n    sum = param_20;\n    leave = param_21;\n    enter = param_22;\n    if ((param_23.x * param_23.y) > 0.5)\n    {\n        vec3 param_24 = leave;\n        vec3 param_25 = enter;\n        sum += fa_ltc_edge_vector(param_24, param_25);\n    }\n    return sum.z * 0.15915493667125701904296875;\n}\n\nvec2 fa_area_forms(vec4 m, float shape, vec3 pc, vec3 ex, vec3 ey)\n{\n    int _6631 = ((shape < 0.5) || (shape > 1.5)) ? 1 : 3;\n    vec2 sum = vec2(0.0);\n    int _6649;\n    for (int k = 0; k < (2 * _6631); k++)\n    {\n        bool _6646 = k >= _6631;\n        if (_6646)\n        {\n            _6649 = k - _6631;\n        }\n        else\n        {\n            _6649 = k;\n        }\n        vec3 p0 = (pc - ex) - ey;\n        vec3 p1 = (pc + ex) - ey;\n        vec3 p2 = (pc + ex) + ey;\n        vec3 p3 = (pc - ex) + ey;\n        if (_6631 == 3)\n        {\n            int param = 0;\n            vec3 param_1 = pc;\n            vec3 param_2 = ex;\n            vec3 param_3 = ey;\n            p0 = fa_oct_vertex(param, param_1, param_2, param_3);\n            int _6695 = 2 * _6649;\n            int param_4 = _6695 + 1;\n            vec3 param_5 = pc;\n            vec3 param_6 = ex;\n            vec3 param_7 = ey;\n            p1 = fa_oct_vertex(param_4, param_5, param_6, param_7);\n            int param_8 = _6695 + 2;\n            vec3 param_9 = pc;\n            vec3 param_10 = ex;\n            vec3 param_11 = ey;\n            p2 = fa_oct_vertex(param_8, param_9, param_10, param_11);\n            int param_12 = _6695 + 3;\n            vec3 param_13 = pc;\n            vec3 param_14 = ex;\n            vec3 param_15 = ey;\n            p3 = fa_oct_vertex(param_12, param_13, param_14, param_15);\n        }\n        bvec4 _6732 = bvec4(_6646);\n        vec4 param_16 = vec4(_6732.x ? m.x : vec4(1.0, 0.0, 0.0, 1.0).x, _6732.y ? m.y : vec4(1.0, 0.0, 0.0, 1.0).y, _6732.z ? m.z : vec4(1.0, 0.0, 0.0, 1.0).z, _6732.w ? m.w : vec4(1.0, 0.0, 0.0, 1.0).w);\n        vec3 param_17 = p0;\n        vec3 param_18 = p1;\n        vec3 param_19 = p2;\n        vec3 param_20 = p3;\n        float _6743 = fa_ltc_quad(param_16, param_17, param_18, param_19, param_20);\n        if (_6646)\n        {\n            vec2 _9447 = sum;\n            _9447.y = _9447.y + _6743;\n            sum = _9447;\n        }\n        else\n        {\n            vec2 _9450 = sum;\n            _9450.x = _9450.x + _6743;\n            sum = _9450;\n        }\n    }\n    return abs(sum);\n}\n\nvec3 fa_area_shade(int li, vec3 world_pos, vec3 n, vec3 v, vec3 diffuse_color, vec3 f0, float f90, float roughness, float ndv, float window)\n{\n    int param = li;\n    int _6767 = fa_light_base(param);\n    int param_1 = _6767;\n    int param_2 = _6767 + 1;\n    int param_3 = _6767 + 2;\n    int param_4 = _6767 + 4;\n    vec4 _6789 = fa_light_texel(param_4);\n    int param_5 = _6767 + 5;\n    vec4 _6794 = fa_light_texel(param_5);\n    int param_6 = _6767 + 6;\n    vec4 _6799 = fa_light_texel(param_6);\n    float _6800 = _6799.w;\n    vec3 _6805 = fa_light_texel(param_1).xyz - world_pos;\n    bool _6807 = _6800 < 1.5;\n    bool _6814;\n    if (_6807)\n    {\n        _6814 = dot(normalize(fa_light_texel(param_3).xyz), _6805) >= 0.0;\n    }\n    else\n    {\n        _6814 = _6807;\n    }\n    if (_6814)\n    {\n        return vec3(0.0);\n    }\n    bool _6823 = (_6800 > 0.5) && _6807;\n    float _6827 = _6823 ? 1.0539000034332275390625 : 1.0;\n    vec3 _6830 = _6789.xyz;\n    float _6832 = _6789.w;\n    vec3 _6838 = _6794.xyz;\n    float _6840 = _6794.w;\n    vec3 up = _6838 * (_6840 * _6827);\n    float _6846;\n    if (_6823)\n    {\n        _6846 = (3.1415927410125732421875 * _6832) * _6832;\n    }\n    else\n    {\n        _6846 = (4.0 * _6832) * _6840;\n    }\n    if (_6800 > 1.5)\n    {\n        vec3 _6872 = cross(_6830, -_6805);\n        vec3 perp = _6872;\n        float _6876 = dot(_6872, _6872);\n        vec3 _6879;\n        if (_6876 > 1.0000000133514319600180897396058e-10)\n        {\n            _6879 = perp * inversesqrt(_6876);\n        }\n        else\n        {\n            _6879 = _6838;\n        }\n        perp = _6879;\n        up = _6879 * _6840;\n    }\n    float _6900 = max(_6846, 9.9999999747524270787835121154785e-07);\n    vec3 param_7 = n;\n    vec3 param_8 = v;\n    vec3 _6910 = fa_ltc_tangent(param_7, param_8);\n    vec3 param_9 = _6910;\n    vec3 param_10 = n;\n    vec3 param_11 = _6805;\n    vec3 param_12 = _6910;\n    vec3 param_13 = n;\n    vec3 param_14 = _6830 * (_6832 * _6827);\n    vec3 param_15 = _6910;\n    vec3 param_16 = n;\n    vec3 param_17 = up;\n    float param_18 = roughness;\n    float param_19 = ndv;\n    vec2 _6941 = fa_ltc_uv(param_18, param_19) * 64.0;\n    vec2 param_20 = _6941;\n    vec2 param_21 = _6941 + vec2(64.0, 0.0);\n    vec4 _6951 = fa_atlas_fetch(param_21);\n    vec4 param_22 = fa_atlas_fetch(param_20);\n    float param_23 = _6800;\n    vec3 param_24 = fa_ltc_local(param_9, param_10, param_11);\n    vec3 param_25 = fa_ltc_local(param_12, param_13, param_14);\n    vec3 param_26 = fa_ltc_local(param_15, param_16, param_17);\n    vec2 _6963 = fa_area_forms(param_22, param_23, param_24, param_25, param_26);\n    return (((diffuse_color * _6963.x) + (((f0 * _6951.x) + ((vec3(f90) - f0) * _6951.y)) * _6963.y)) * fa_light_texel(param_2).xyz) * ((((3.1415927410125732421875 * dot(_6805, _6805)) + _6900) / _6900) * window);\n}\n\nvec3 fa_light_rgb(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 1;\n    return fa_light_texel(param_1).xyz;\n}\n\nfloat fa_d_charlie(float alpha, float ndh)\n{\n    float _5053 = 1.0 / alpha;\n    return ((2.0 + _5053) * pow(sqrt(max(1.0 - (ndh * ndh), 9.9999997473787516355514526367188e-05)), _5053)) * 0.15915493667125701904296875;\n}\n\nfloat fa_v_ashikhmin(float ndl, float ndv)\n{\n    return clamp(0.25 / max((ndl + ndv) - (ndl * ndv), 9.9999997473787516355514526367188e-05), 0.0, 1.0);\n}\n\nfloat fa_layers_coat(FaLayers L, vec3 l, vec3 h, float vdh)\n{\n    float _5088 = max(dot(L.nc, l), 0.0);\n    float _5094 = max(dot(L.nc, h), 0.0);\n    float _5103 = ((_5094 * _5094) * (L.coat_a2 - 1.0)) + 1.0;\n    return (((L.coat * (0.039999999105930328369140625 + (0.959999978542327880859375 * pow(clamp(1.0 - vdh, 0.0, 1.0), 5.0)))) * (((L.coat_a2 / ((3.1415927410125732421875 * _5103) * _5103)) * (0.5 / max(mix((2.0 * _5088) * L.coat_ndv, _5088 + L.coat_ndv, L.coat_alpha), 9.9999997473787516355514526367188e-05))) * 3.1415927410125732421875)) * step(9.9999997473787516355514526367188e-05, _5088)) * _5088;\n}\n\nvec3 fa_area_layers(FaLayers L, vec3 base, int li, vec3 n, vec3 v, vec3 l, float ndv, float window)\n{\n    float _7000;\n    if (L.sheen_on)\n    {\n        _7000 = L.sheen_scale;\n    }\n    else\n    {\n        _7000 = 1.0;\n    }\n    vec3 result = base * (L.keep * _7000);\n    vec3 _7013 = normalize(l + v);\n    int param = li;\n    vec3 _7024 = fa_light_rgb(param) * window;\n    if (L.sheen_on)\n    {\n        float _7033 = max(dot(n, l), 0.0);\n        float param_1 = L.sheen_alpha;\n        float param_2 = max(dot(n, _7013), 0.0);\n        float param_3 = _7033;\n        float param_4 = ndv;\n        result += ((L.sheen * _7024) * (((((fa_d_charlie(param_1, param_2) * fa_v_ashikhmin(param_3, param_4)) * 3.1415927410125732421875) * step(9.9999997473787516355514526367188e-05, _7033)) * _7033) * L.keep));\n    }\n    if (L.coat > 0.0)\n    {\n        FaLayers param_5 = L;\n        vec3 param_6 = l;\n        vec3 param_7 = _7013;\n        float param_8 = max(dot(v, _7013), 0.0);\n        result += (_7024 * fa_layers_coat(param_5, param_6, param_7, param_8));\n    }\n    return result;\n}\n\nfloat fa_d_ggx_aniso(float ndh, float tdh, float bdh, float at, float ab)\n{\n    float _4956 = tdh / at;\n    float _4960 = bdh / ab;\n    float _4972 = ((_4956 * _4956) + (_4960 * _4960)) + (ndh * ndh);\n    return 1.0 / ((((3.1415927410125732421875 * at) * ab) * _4972) * _4972);\n}\n\nfloat fa_lambda_ggx_aniso(float n, float t, float b, float at, float ab)\n{\n    return 0.5 * (sqrt(1.0 + (((((at * at) * t) * t) + (((ab * ab) * b) * b)) / max(n * n, 9.9999999392252902907785028219223e-09))) - 1.0);\n}\n\nfloat fa_v_ggx_aniso(float ndl, float ndv, float tdv, float bdv, float tdl, float bdl, float at, float ab)\n{\n    float param = ndv;\n    float param_1 = tdv;\n    float param_2 = bdv;\n    float param_3 = at;\n    float param_4 = ab;\n    float param_5 = ndl;\n    float param_6 = tdl;\n    float param_7 = bdl;\n    float param_8 = at;\n    float param_9 = ab;\n    return clamp(1.0 / ((4.0 * max(ndl * ndv, 9.9999997473787516355514526367188e-05)) * ((1.0 + fa_lambda_ggx_aniso(param, param_1, param_2, param_3, param_4)) + fa_lambda_ggx_aniso(param_5, param_6, param_7, param_8, param_9))), 0.0, 1.0);\n}\n\nvec3 fa_layers_light(FaLayers L, vec3 diffuse_color, vec3 f0, vec3 n, vec3 v, vec3 l, vec3 h, float ndl, float ndv, float ndh, float vdh, float alpha, float a2)\n{\n    float _5152 = step(9.9999997473787516355514526367188e-05, ndl);\n    float d_ggx;\n    float vis;\n    if (L.aniso != 0.0)\n    {\n        float param = ndh;\n        float param_1 = dot(L.t, h);\n        float param_2 = dot(L.b, h);\n        float param_3 = L.at;\n        float param_4 = L.ab;\n        d_ggx = fa_d_ggx_aniso(param, param_1, param_2, param_3, param_4);\n        float param_5 = ndl;\n        float param_6 = ndv;\n        float param_7 = dot(L.t, v);\n        float param_8 = dot(L.b, v);\n        float param_9 = dot(L.t, l);\n        float param_10 = dot(L.b, l);\n        float param_11 = L.at;\n        float param_12 = L.ab;\n        vis = fa_v_ggx_aniso(param_5, param_6, param_7, param_8, param_9, param_10, param_11, param_12);\n    }\n    else\n    {\n        float _5231 = ((ndh * ndh) * (a2 - 1.0)) + 1.0;\n        d_ggx = a2 / ((3.1415927410125732421875 * _5231) * _5231);\n        vis = 0.5 / max(mix((2.0 * ndl) * ndv, ndl + ndv, alpha), 9.9999997473787516355514526367188e-05);\n    }\n    vec3 base = diffuse_color + (((f0 + ((vec3(L.f90) - f0) * pow(clamp(1.0 - vdh, 0.0, 1.0), 5.0))) * ((d_ggx * vis) * 3.1415927410125732421875)) * _5152);\n    if (L.sheen_on)\n    {\n        float param_13 = L.sheen_alpha;\n        float param_14 = ndh;\n        float param_15 = ndl;\n        float param_16 = ndv;\n        base = (base * L.sheen_scale) + (L.sheen * (((fa_d_charlie(param_13, param_14) * fa_v_ashikhmin(param_15, param_16)) * 3.1415927410125732421875) * _5152));\n    }\n    vec3 result = base * (L.keep * ndl);\n    if (L.coat > 0.0)\n    {\n        FaLayers param_17 = L;\n        vec3 param_18 = l;\n        vec3 param_19 = h;\n        float param_20 = vdh;\n        result += vec3(fa_layers_coat(param_17, param_18, param_19, param_20));\n    }\n    return result;\n}\n\nvec2 fa_env_brdf(float rough, float ndv)\n{\n    vec4 _4355 = (vec4(-1.0, -0.0274999998509883880615234375, -0.572000026702880859375, 0.02199999988079071044921875) * rough) + vec4(1.0, 0.0425000004470348358154296875, 1.03999996185302734375, -0.039999999105930328369140625);\n    float _4358 = _4355.x;\n    return (vec2(-1.03999996185302734375, 1.03999996185302734375) * ((min(_4358 * _4358, exp2((-9.27999973297119140625) * ndv)) * _4358) + _4355.y)) + _4355.zw;\n}\n\nvec3 fa_probe_level(vec2 origin, float res, int lv, vec2 e)\n{\n    float _3664;\n    if (lv == 0)\n    {\n        _3664 = 0.0;\n    }\n    else\n    {\n        _3664 = res + 2.0;\n    }\n    float _3674;\n    if (lv == 0)\n    {\n        _3674 = 0.0;\n    }\n    else\n    {\n        _3674 = (res - (res / float(1 << max((lv - 1), 0)))) + (2.0 * float(lv - 1));\n    }\n    return textureLod(fa_probe_atlas_fa_env_smp, (((origin + vec2(_3664, _3674)) + vec2(1.0)) + (((e * 0.5) + vec2(0.5)) * (res / float(1 << lv)))) / fa_atlas_size(), 0.0).xyz;\n}\n\nvec3 fa_probe_radiance(vec2 origin, float res, vec3 d, float rough)\n{\n    float _3720;\n    if (res > 64.5)\n    {\n        _3720 = 5.0;\n    }\n    else\n    {\n        _3720 = (res > 32.5) ? 4.0 : 3.0;\n    }\n    float _3735 = clamp(rough, 0.0, 1.0) * (_3720 - 1.0);\n    int _3742 = int(min(floor(_3735), _3720 - 2.0));\n    float _3747 = _3735 - float(_3742);\n    vec3 param = d;\n    vec2 _3751 = fa_oct_encode(param);\n    vec2 param_1 = origin;\n    float param_2 = res;\n    int param_3 = _3742;\n    vec2 param_4 = _3751;\n    vec3 _3761 = fa_probe_level(param_1, param_2, param_3, param_4);\n    if (_3747 < 0.00200000009499490261077880859375)\n    {\n        return _3761;\n    }\n    vec2 param_5 = origin;\n    float param_6 = res;\n    int param_7 = _3742 + 1;\n    vec2 param_8 = _3751;\n    return mix(_3761, fa_probe_level(param_5, param_6, param_7, param_8), vec3(_3747));\n}\n\nvec3 fa_probe_box_dir(vec3 d, vec4 posw, vec4 bx, vec4 by, vec4 bz)\n{\n    if (posw.w < 0.5)\n    {\n        return d;\n    }\n    float _3833 = dot(bx.xyz, fa_world_pos) + bx.w;\n    float _3840 = dot(by.xyz, fa_world_pos) + by.w;\n    float _3847 = dot(bz.xyz, fa_world_pos) + bz.w;\n    float _3853 = dot(bx.xyz, d);\n    float _3857 = dot(by.xyz, d);\n    float _3861 = dot(bz.xyz, d);\n    float _3867;\n    if (_3853 > 9.9999999747524270787835121154785e-07)\n    {\n        _3867 = (1.0 - _3833) / _3853;\n    }\n    else\n    {\n        float _3881;\n        if (_3853 < (-9.9999999747524270787835121154785e-07))\n        {\n            _3881 = ((-1.0) - _3833) / _3853;\n        }\n        else\n        {\n            _3881 = 1000000015047466219876688855040.0;\n        }\n        _3867 = _3881;\n    }\n    float tx = _3867;\n    float _3898;\n    if (_3857 > 9.9999999747524270787835121154785e-07)\n    {\n        _3898 = (1.0 - _3840) / _3857;\n    }\n    else\n    {\n        float _3911;\n        if (_3857 < (-9.9999999747524270787835121154785e-07))\n        {\n            _3911 = ((-1.0) - _3840) / _3857;\n        }\n        else\n        {\n            _3911 = 1000000015047466219876688855040.0;\n        }\n        _3898 = _3911;\n    }\n    float ty = _3898;\n    float _3927;\n    if (_3861 > 9.9999999747524270787835121154785e-07)\n    {\n        _3927 = (1.0 - _3847) / _3861;\n    }\n    else\n    {\n        float _3940;\n        if (_3861 < (-9.9999999747524270787835121154785e-07))\n        {\n            _3940 = ((-1.0) - _3847) / _3861;\n        }\n        else\n        {\n            _3940 = 1000000015047466219876688855040.0;\n        }\n        _3927 = _3940;\n    }\n    float _3952 = tx;\n    float _3955 = (_3952 > 0.0) ? _3952 : 1000000015047466219876688855040.0;\n    tx = _3955;\n    float _3956 = ty;\n    float _3959 = (_3956 > 0.0) ? _3956 : 1000000015047466219876688855040.0;\n    ty = _3959;\n    float _3969 = min(_3955, min(_3959, (_3927 > 0.0) ? _3927 : 1000000015047466219876688855040.0));\n    if (_3969 > 100000001504746621987668885504.0)\n    {\n        return d;\n    }\n    vec3 _3985 = (fa_world_pos + (d * _3969)) - posw.xyz;\n    vec3 _3990;\n    if (dot(_3985, _3985) > 1.0000000133514319600180897396058e-10)\n    {\n        _3990 = normalize(_3985);\n    }\n    else\n    {\n        _3990 = d;\n    }\n    return _3990;\n}\n\nvec3 fa_probe_environment(vec4 tile, vec4 posw, vec4 bx, vec4 by, vec4 bz, inout vec3 d, float rough)\n{\n    vec3 param = d;\n    vec4 param_1 = posw;\n    vec4 param_2 = bx;\n    vec4 param_3 = by;\n    vec4 param_4 = bz;\n    d = fa_probe_box_dir(param, param_1, param_2, param_3, param_4);\n    vec2 param_5 = tile.xy;\n    float param_6 = tile.z;\n    vec3 param_7 = d;\n    float param_8 = rough;\n    return fa_probe_radiance(param_5, param_6, param_7, param_8);\n}\n\nvec3 fa_environment(vec3 d, float rough)\n{\n    float _4036 = (1.0 - fa_mesh_fs_params[42].w) - fa_mesh_fs_params[47].w;\n    vec3 outc = vec3(0.0);\n    if (_4036 > 0.0005000000237487256526947021484375)\n    {\n        vec3 base;\n        if (fa_mesh_fs_params[11].w > 0.5)\n        {\n            vec2 param = fa_mesh_fs_params[41].zw;\n            float param_1 = 128.0;\n            vec3 param_2 = d;\n            float param_3 = rough;\n            base = fa_probe_radiance(param, param_1, param_2, param_3);\n        }\n        else\n        {\n            float _4064 = rough * rough;\n            float _4095 = 0.60000002384185791015625 * _4064;\n            base = mix(mix(fa_mesh_fs_params[12].xyz * 0.550000011920928955078125, mix(fa_mesh_fs_params[12].xyz, fa_mesh_fs_params[11].xyz, vec3(pow(clamp(d.y * (1.0 - (0.699999988079071044921875 * _4064)), 0.0, 1.0), 0.550000011920928955078125))), vec3(smoothstep((-0.0500000007450580596923828125) - _4095, 0.0500000007450580596923828125 + _4095, d.y))), ((fa_mesh_fs_params[11].xyz + fa_mesh_fs_params[12].xyz) * 0.5) * 0.800000011920928955078125, vec3(_4064 * 0.60000002384185791015625));\n        }\n        outc = base * _4036;\n    }\n    if (fa_mesh_fs_params[42].w > 0.0)\n    {\n        vec4 param_4 = fa_mesh_fs_params[42];\n        vec4 param_5 = fa_mesh_fs_params[43];\n        vec4 param_6 = fa_mesh_fs_params[44];\n        vec4 param_7 = fa_mesh_fs_params[45];\n        vec4 param_8 = fa_mesh_fs_params[46];\n        vec3 param_9 = d;\n        float param_10 = rough;\n        vec3 _4154 = fa_probe_environment(param_4, param_5, param_6, param_7, param_8, param_9, param_10);\n        outc += (_4154 * fa_mesh_fs_params[42].w);\n    }\n    if (fa_mesh_fs_params[47].w > 0.0)\n    {\n        vec4 param_11 = fa_mesh_fs_params[47];\n        vec4 param_12 = fa_mesh_fs_params[48];\n        vec4 param_13 = fa_mesh_fs_params[49];\n        vec4 param_14 = fa_mesh_fs_params[50];\n        vec4 param_15 = fa_mesh_fs_params[51];\n        vec3 param_16 = d;\n        float param_17 = rough;\n        vec3 _4186 = fa_probe_environment(param_11, param_12, param_13, param_14, param_15, param_16, param_17);\n        outc += (_4186 * fa_mesh_fs_params[47].w);\n    }\n    return outc;\n}\n\nvec3 fa_layers_ibl(FaLayers L, vec3 n, vec3 v, vec3 f0, float roughness, float occlusion)\n{\n    vec3 rn = n;\n    if (L.aniso != 0.0)\n    {\n        vec3 _4833;\n        if (L.aniso >= 0.0)\n        {\n            _4833 = L.b;\n        }\n        else\n        {\n            _4833 = L.t;\n        }\n        rn = normalize(mix(n, cross(cross(_4833, v), _4833), vec3(abs(L.aniso) * smoothstep(0.0, 0.25, roughness))));\n    }\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05);\n    vec2 _4869 = fa_env_brdf(param, param_1);\n    vec3 param_2 = reflect(-v, rn);\n    float param_3 = roughness;\n    vec3 result = (fa_environment(param_2, param_3) * ((f0 * _4869.x) + (vec3(L.f90) * _4869.y))) * L.base_scale;\n    if (L.sheen_on)\n    {\n        vec3 param_4 = n;\n        float param_5 = L.sheen_rough;\n        result += ((L.sheen * (L.sheen_e * L.keep)) * fa_environment(param_4, param_5));\n    }\n    result *= occlusion;\n    if (L.coat > 0.0)\n    {\n        float param_6 = L.coat_rough;\n        float param_7 = L.coat_ndv;\n        vec2 _4927 = fa_env_brdf(param_6, param_7);\n        vec3 param_8 = reflect(-v, L.nc);\n        float param_9 = L.coat_rough;\n        result += (fa_environment(param_8, param_9) * (L.coat * ((0.039999999105930328369140625 * _4927.x) + _4927.y)));\n    }\n    return result;\n}\n\nvec3 fa_sky_reflection(vec3 n, vec3 v, vec3 f0, float roughness)\n{\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05);\n    vec2 _4397 = fa_env_brdf(param, param_1);\n    vec3 param_2 = reflect(-v, n);\n    float param_3 = roughness;\n    return fa_environment(param_2, param_3) * ((f0 * _4397.x) + vec3(_4397.y));\n}\n\nvec2 fa_xm_size(int k)\n{\n    return max(floor(fa_mesh_fs_params[24].zw / vec2(float(1 << k))), vec2(1.0));\n}\n\nvec2 fa_xm_origin(int k)\n{\n    if (k == 0)\n    {\n        return vec2(0.0);\n    }\n    float y = 0.0;\n    for (int j = 1; j < k; j++)\n    {\n        int param = j;\n        y += fa_xm_size(param).y;\n    }\n    return vec2(fa_mesh_fs_params[24].z, y);\n}\n\nvec3 fa_xm_texel(vec2 size, vec2 origin, vec2 p)\n{\n    return texelFetch(fa_screen_tex_fa_shadow_smp, ivec2(origin + clamp(p, vec2(0.0), size - vec2(1.0))), 0).xyz;\n}\n\nvec3 fa_xm_level(int k, vec2 uv)\n{\n    int param = k;\n    vec2 _5629 = fa_xm_size(param);\n    int param_1 = k;\n    vec2 _5633 = fa_xm_origin(param_1);\n    vec2 _5639 = (uv * _5629) - vec2(0.5);\n    vec2 _5642 = fract(_5639);\n    vec2 _5645 = floor(_5639);\n    vec2 param_2 = _5629;\n    vec2 param_3 = _5633;\n    vec2 param_4 = _5645;\n    vec2 param_5 = _5629;\n    vec2 param_6 = _5633;\n    vec2 param_7 = _5645 + vec2(1.0, 0.0);\n    vec2 param_8 = _5629;\n    vec2 param_9 = _5633;\n    vec2 param_10 = _5645 + vec2(0.0, 1.0);\n    vec2 param_11 = _5629;\n    vec2 param_12 = _5633;\n    vec2 param_13 = _5645 + vec2(1.0);\n    vec3 _5687 = vec3(_5642.x);\n    return mix(mix(fa_xm_texel(param_2, param_3, param_4), fa_xm_texel(param_5, param_6, param_7), _5687), mix(fa_xm_texel(param_8, param_9, param_10), fa_xm_texel(param_11, param_12, param_13), _5687), vec3(_5642.y));\n}\n\nvec3 fa_xm_sample(vec2 uv, float lod)\n{\n    float _5706 = max(fa_mesh_fs_params[31].w - 1.0, 0.0);\n    float _5710 = clamp(lod, 0.0, _5706);\n    int _5714 = int(floor(_5710));\n    int param = _5714;\n    vec2 param_1 = uv;\n    vec3 c = fa_xm_level(param, param_1);\n    float _5724 = float(_5714);\n    float _5725 = _5710 - _5724;\n    bool _5727 = _5725 > 0.001000000047497451305389404296875;\n    bool _5734;\n    if (_5727)\n    {\n        _5734 = _5724 < _5706;\n    }\n    else\n    {\n        _5734 = _5727;\n    }\n    if (_5734)\n    {\n        int param_2 = _5714 + 1;\n        vec2 param_3 = uv;\n        c = mix(c, fa_xm_level(param_2, param_3), vec3(_5725));\n    }\n    return c;\n}\n\nvec3 fa_transmitted(Surface s, vec3 n, vec3 v, float roughness, vec3 f0, float f90, float keep, float tr, inout float blend)\n{\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05);\n    vec2 _5760 = fa_env_brdf(param, param_1);\n    vec3 through = ((vec3(1.0) - clamp((f0 * _5760.x) + (vec3(f90) * _5760.y), vec3(0.0), vec3(1.0))) * s.albedo) * (tr * keep);\n    float _5788 = max(s.thickness, 0.0);\n    bool _5793 = _5788 > 0.0;\n    if ((s.attenuation_distance > 0.0) && _5793)\n    {\n        through *= exp((-((-log(clamp(s.attenuation_color, vec3(9.9999997473787516355514526367188e-05), vec3(1.0)))) / vec3(s.attenuation_distance))) * _5788);\n    }\n    bool _5818 = fa_mesh_fs_params[30].w > 1.5;\n    bool _5825;\n    if (!_5818)\n    {\n        _5825 = fa_mesh_fs_params[30].w < 0.5;\n    }\n    else\n    {\n        _5825 = _5818;\n    }\n    if (_5825)\n    {\n        blend = clamp(dot(through, vec3(0.3333333432674407958984375)), 0.0, 0.980000019073486328125);\n        return vec3(0.0);\n    }\n    vec3 world = fa_world_pos;\n    if (_5793)\n    {\n        world += (refract(-v, n, 1.0 / max(s.ior, 1.0)) * _5788);\n    }\n    vec4 _5860 = vec4(world, 1.0);\n    float _5865 = dot(fa_mesh_fs_params[28], _5860);\n    vec2 uv = vec2(0.5);\n    if (_5865 > 9.9999997473787516355514526367188e-05)\n    {\n        vec2 _5883 = vec2(dot(fa_mesh_fs_params[26], _5860), dot(fa_mesh_fs_params[27], _5860)) / vec2(_5865);\n        float _5891;\n        if (fa_mesh_fs_params[24].y > 0.5)\n        {\n            _5891 = (_5883.y * 0.5) + 0.5;\n        }\n        else\n        {\n            _5891 = 0.5 - (_5883.y * 0.5);\n        }\n        uv = vec2((_5883.x * 0.5) + 0.5, _5891);\n    }\n    vec2 param_2 = clamp(uv, vec2(0.0), vec2(1.0));\n    float param_3 = (clamp(roughness, 0.0, 1.0) * clamp((2.0 * s.ior) - 2.0, 0.0, 1.0)) * max(fa_mesh_fs_params[31].w - 1.0, 0.0);\n    return through * fa_xm_sample(param_2, param_3);\n}\n\nvec3 fa_shadow_debug(vec3 color, vec3 world)\n{\n    if (fa_shadows[27].w < 0.5)\n    {\n        return color;\n    }\n    int _3271 = int(fa_shadows[25].x + 0.5);\n    float _3281 = dot(world - fa_shadows[27].xyz, fa_shadows[28].xyz);\n    vec3 tint = vec3(0.3499999940395355224609375);\n    bool _3286 = _3271 > 0;\n    bool _3295;\n    if (_3286)\n    {\n        int param = _3271 - 1;\n        _3295 = _3281 <= fa_shadow_split_at(param);\n    }\n    else\n    {\n        _3295 = _3286;\n    }\n    if (_3295)\n    {\n        tint = vec3(1.0, 0.1500000059604644775390625, 0.100000001490116119384765625);\n        bool _3301 = _3271 > 1;\n        bool _3308;\n        if (_3301)\n        {\n            _3308 = _3281 > fa_shadows[24].x;\n        }\n        else\n        {\n            _3308 = _3301;\n        }\n        if (_3308)\n        {\n            tint = vec3(0.100000001490116119384765625, 0.89999997615814208984375, 0.20000000298023223876953125);\n        }\n        bool _3314 = _3271 > 2;\n        bool _3321;\n        if (_3314)\n        {\n            _3321 = _3281 > fa_shadows[24].y;\n        }\n        else\n        {\n            _3321 = _3314;\n        }\n        if (_3321)\n        {\n            tint = vec3(0.1500000059604644775390625, 0.300000011920928955078125, 1.0);\n        }\n        bool _3327 = _3271 > 3;\n        bool _3334;\n        if (_3327)\n        {\n            _3334 = _3281 > fa_shadows[24].z;\n        }\n        else\n        {\n            _3334 = _3327;\n        }\n        if (_3334)\n        {\n            tint = vec3(1.0, 0.89999997615814208984375, 0.100000001490116119384765625);\n        }\n    }\n    return mix(color, tint, vec3(0.550000011920928955078125));\n}\n\nvoid main()\n{\n    fa_inst_load();\n    vec3 _8869 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _8869 = -_8869;\n    }\n    vec3 _8162 = normalize(fa_mesh_fs_params[0].xyz - fa_world_pos);\n    vec3 param = fa_world_pos;\n    fa_cluster_begin(param);\n    SurfaceInput param_1 = SurfaceInput(fa_world_pos, _8869, fa_world_tangent, fa_uv, fa_vertex_color, _8162, gl_FrontFacing);\n    Surface _8170 = fa_standard_surface(param_1);\n    vec3 _8900 = _8170.albedo;\n    float _8901 = _8170.alpha;\n    vec3 _8902 = _8170.normal;\n    float _8903 = _8170.metallic;\n    float _8904 = _8170.roughness;\n    float _8905 = _8170.occlusion;\n    vec3 _8906 = _8170.emission;\n    float _8907 = _8170.clearcoat;\n    float _8908 = _8170.clearcoat_roughness;\n    vec3 _8909 = _8170.sheen_color;\n    float _8910 = _8170.sheen_roughness;\n    float _8911 = _8170.anisotropy;\n    float _8912 = _8170.anisotropy_rotation;\n    float _8913 = _8170.specular;\n    float _8914 = _8170.ior;\n    vec3 _8915 = _8170.specular_color;\n    float _8916 = _8170.transmission;\n    float _8917 = _8170.thickness;\n    vec3 _8918 = _8170.attenuation_color;\n    float _8919 = _8170.attenuation_distance;\n    SurfaceInput param_2 = SurfaceInput(fa_world_pos, _8869, fa_world_tangent, fa_uv, fa_vertex_color, _8162, gl_FrontFacing);\n    Surface param_3 = _8170;\n    surface(param_2, param_3);\n    _8900 = param_3.albedo;\n    _8901 = param_3.alpha;\n    _8902 = param_3.normal;\n    _8903 = param_3.metallic;\n    _8904 = param_3.roughness;\n    _8905 = param_3.occlusion;\n    _8906 = param_3.emission;\n    _8907 = param_3.clearcoat;\n    _8908 = param_3.clearcoat_roughness;\n    _8909 = param_3.sheen_color;\n    _8910 = param_3.sheen_roughness;\n    _8911 = param_3.anisotropy;\n    _8912 = param_3.anisotropy_rotation;\n    _8913 = param_3.specular;\n    _8914 = param_3.ior;\n    _8915 = param_3.specular_color;\n    _8916 = param_3.transmission;\n    _8917 = param_3.thickness;\n    _8918 = param_3.attenuation_color;\n    _8919 = param_3.attenuation_distance;\n    vec3 param_4 = fa_world_pos;\n    vec3 param_5 = _8869;\n    vec3 param_6 = param_3.albedo;\n    vec3 param_7 = param_3.normal;\n    fa_apply_decals(param_4, param_5, param_6, param_7);\n    _8900 = param_6;\n    _8902 = param_7;\n    float fa_tr_blend = 0.0;\n    vec3 result;\n    if (fa_mesh_fs_params[3].w > 0.5)\n    {\n        result = _8900;\n    }\n    else\n    {\n        vec3 _8210 = normalize(_8902);\n        float _8217 = clamp(_8903, 0.0, 1.0);\n        float _8221 = clamp(_8904, 0.0500000007450580596923828125, 1.0);\n        float _8225 = _8221 * _8221;\n        float _8229 = _8225 * _8225;\n        float _8234 = max(dot(_8210, _8162), 9.9999997473787516355514526367188e-05);\n        float _8240 = 1.0 - _8217;\n        float _8241 = clamp(_8916, 0.0, 1.0) * _8240;\n        vec3 _8250 = (_8900 * _8240) * (1.0 - _8241);\n        vec3 _8257 = mix(vec3(0.039999999105930328369140625), _8900, vec3(_8217));\n        vec3 f0 = _8257;\n        SurfaceInput param_8 = SurfaceInput(fa_world_pos, _8869, fa_world_tangent, fa_uv, fa_vertex_color, _8162, gl_FrontFacing);\n        Surface param_9 = Surface(_8900, _8901, _8902, _8903, _8904, _8905, _8906, _8907, _8908, _8909, _8910, _8911, _8912, _8913, _8914, _8915, _8916, _8917, _8918, _8919);\n        vec3 param_10 = _8210;\n        vec3 param_11 = _8162;\n        float param_12 = _8217;\n        float param_13 = _8221;\n        vec3 param_14 = _8257;\n        FaLayers _8273 = fa_layers_setup(param_8, param_9, param_10, param_11, param_12, param_13, param_14);\n        f0 = param_14;\n        vec3 param_15 = _8210;\n        vec3 lit = (fa_indirect_diffuse(param_15) * _8250) * _8905;\n        if (_8273.on)\n        {\n            lit *= _8273.base_scale;\n        }\n        int _8295 = fa_cl_ndir + fa_cl_local;\n        float _8360;\n        for (int ln = 0; ln < _8295; ln++)\n        {\n            int param_16 = ln;\n            int _8308 = fa_cl_light(param_16);\n            int param_17 = _8308;\n            if (fa_baked_keep(param_17) <= 0.0)\n            {\n                continue;\n            }\n            int param_18 = _8308;\n            vec3 param_19 = fa_world_pos;\n            vec3 param_20 = _8869;\n            LightSample _8324 = fa_light_shadowed(param_18, param_19, param_20);\n            float _8332 = max(dot(_8210, _8324.direction), 0.0);\n            float _8338 = _8324.attenuation * _8324.shadow;\n            vec3 _8343 = normalize(_8324.direction + _8162);\n            float _8348 = max(dot(_8210, _8343), 0.0);\n            float _8353 = max(dot(_8162, _8343), 0.0);\n            if (fa_light_is_area)\n            {\n                if (_8273.on)\n                {\n                    _8360 = _8273.f90;\n                }\n                else\n                {\n                    _8360 = 1.0;\n                }\n                int param_21 = _8308;\n                vec3 param_22 = fa_world_pos;\n                vec3 param_23 = _8210;\n                vec3 param_24 = _8162;\n                vec3 param_25 = _8250;\n                vec3 param_26 = f0;\n                float param_27 = _8360;\n                float param_28 = _8221;\n                float param_29 = _8234;\n                float param_30 = _8338;\n                vec3 area = fa_area_shade(param_21, param_22, param_23, param_24, param_25, param_26, param_27, param_28, param_29, param_30);\n                if (_8273.on)\n                {\n                    FaLayers param_31 = _8273;\n                    vec3 param_32 = area;\n                    int param_33 = _8308;\n                    vec3 param_34 = _8210;\n                    vec3 param_35 = _8162;\n                    vec3 param_36 = _8324.direction;\n                    float param_37 = _8234;\n                    float param_38 = _8338;\n                    area = fa_area_layers(param_31, param_32, param_33, param_34, param_35, param_36, param_37, param_38);\n                }\n                lit += area;\n            }\n            else\n            {\n                if (_8273.on)\n                {\n                    FaLayers param_39 = _8273;\n                    vec3 param_40 = _8250;\n                    vec3 param_41 = f0;\n                    vec3 param_42 = _8210;\n                    vec3 param_43 = _8162;\n                    vec3 param_44 = _8324.direction;\n                    vec3 param_45 = _8343;\n                    float param_46 = _8332;\n                    float param_47 = _8234;\n                    float param_48 = _8348;\n                    float param_49 = _8353;\n                    float param_50 = _8225;\n                    float param_51 = _8229;\n                    int param_52 = _8308;\n                    lit += (fa_layers_light(param_39, param_40, param_41, param_42, param_43, param_44, param_45, param_46, param_47, param_48, param_49, param_50, param_51) * ((fa_light_rgb(param_52) * fa_light_tint) * _8338));\n                }\n                else\n                {\n                    float _8462 = ((_8348 * _8348) * (_8229 - 1.0)) + 1.0;\n                    int param_53 = _8308;\n                    lit += (((_8250 + (((f0 + ((vec3(1.0) - f0) * pow(1.0 - _8353, 5.0))) * (((_8229 / ((3.1415927410125732421875 * _8462) * _8462)) * (0.5 / max(mix((2.0 * _8332) * _8234, _8332 + _8234, _8225), 9.9999997473787516355514526367188e-05))) * 3.1415927410125732421875)) * step(9.9999997473787516355514526367188e-05, _8332))) * (fa_light_rgb(param_53) * fa_light_tint)) * (_8332 * _8338));\n                }\n            }\n        }\n        if (_8273.on)\n        {\n            FaLayers param_54 = _8273;\n            vec3 param_55 = _8210;\n            vec3 param_56 = _8162;\n            vec3 param_57 = f0;\n            float param_58 = _8221;\n            float param_59 = _8905;\n            lit += fa_layers_ibl(param_54, param_55, param_56, param_57, param_58, param_59);\n        }\n        else\n        {\n            vec3 param_60 = _8210;\n            vec3 param_61 = _8162;\n            vec3 param_62 = f0;\n            float param_63 = _8221;\n            lit += (fa_sky_reflection(param_60, param_61, param_62, param_63) * _8905);\n        }\n        if (_8241 > 0.0)\n        {\n            float _8560;\n            if (_8273.on)\n            {\n                _8560 = _8273.f90;\n            }\n            else\n            {\n                _8560 = 1.0;\n            }\n            float _8568;\n            if (_8273.on)\n            {\n                _8568 = _8273.base_scale;\n            }\n            else\n            {\n                _8568 = 1.0;\n            }\n            Surface param_64 = Surface(_8900, _8901, _8902, _8903, _8904, _8905, _8906, _8907, _8908, _8909, _8910, _8911, _8912, _8913, _8914, _8915, _8916, _8917, _8918, _8919);\n            vec3 param_65 = _8210;\n            vec3 param_66 = _8162;\n            float param_67 = _8221;\n            vec3 param_68 = f0;\n            float param_69 = _8560;\n            float param_70 = _8568;\n            float param_71 = _8241;\n            float param_72 = fa_tr_blend;\n            vec3 _8592 = fa_transmitted(param_64, param_65, param_66, param_67, param_68, param_69, param_70, param_71, param_72);\n            fa_tr_blend = param_72;\n            lit += _8592;\n        }\n        result = lit;\n    }\n    vec3 _8599 = result;\n    vec3 _8600 = _8599 + _8906;\n    result = _8600;\n    vec3 param_73 = _8600;\n    vec3 param_74 = fa_world_pos;\n    result = fa_shadow_debug(param_73, param_74);\n    bool _8609 = fa_mesh_fs_params[7].w > 0.0;\n    bool _8616;\n    if (!_8609)\n    {\n        _8616 = fa_mesh_fs_params[8].y > 0.0;\n    }\n    else\n    {\n        _8616 = _8609;\n    }\n    if (_8616)\n    {\n        vec3 _8625 = fa_world_pos - fa_mesh_fs_params[0].xyz;\n        float _8631 = dot(_8625, fa_mesh_fs_params[9].xyz);\n        bool _8635 = fa_mesh_fs_params[9].w > 0.5;\n        float _8636;\n        if (_8635)\n        {\n            _8636 = _8631;\n        }\n        else\n        {\n            _8636 = length(_8625);\n        }\n        float _8648 = _8636 - fa_mesh_fs_params[8].x;\n        if (_8648 > 0.0)\n        {\n            float _8657 = fa_mesh_fs_params[7].w * _8648;\n            float tau = _8657 * _8657;\n            if (fa_mesh_fs_params[8].y > 0.0)\n            {\n                float _8673;\n                if (_8635)\n                {\n                    _8673 = fa_world_pos.y - (fa_mesh_fs_params[9].y * _8631);\n                }\n                else\n                {\n                    _8673 = fa_mesh_fs_params[0].y;\n                }\n                float _8694 = mix(_8673, fa_world_pos.y, clamp(fa_mesh_fs_params[8].x / _8636, 0.0, 1.0));\n                float _8698 = fa_world_pos.y - _8694;\n                float _8703 = _8694 - fa_mesh_fs_params[8].z;\n                float _8708 = fa_world_pos.y - fa_mesh_fs_params[8].z;\n                bool _8711 = _8703 <= 0.0;\n                bool _8712 = !_8711;\n                bool _8718;\n                if (_8712)\n                {\n                    _8718 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _8718 = _8711;\n                }\n                float _8719;\n                if (_8718)\n                {\n                    _8719 = fa_mesh_fs_params[8].y;\n                }\n                else\n                {\n                    _8719 = fa_mesh_fs_params[8].y * exp(-min(fa_mesh_fs_params[8].w * _8703, 80.0));\n                }\n                bool _8746;\n                if (_8712)\n                {\n                    _8746 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _8746 = _8711;\n                }\n                float _8747;\n                if (_8746)\n                {\n                    _8747 = fa_mesh_fs_params[8].y * _8703;\n                }\n                else\n                {\n                    _8747 = (fa_mesh_fs_params[8].y * (1.0 - exp(-min(fa_mesh_fs_params[8].w * _8703, 80.0)))) / fa_mesh_fs_params[8].w;\n                }\n                bool _8772 = _8708 <= 0.0;\n                bool _8779;\n                if (!_8772)\n                {\n                    _8779 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _8779 = _8772;\n                }\n                float _8780;\n                if (_8779)\n                {\n                    _8780 = fa_mesh_fs_params[8].y * _8708;\n                }\n                else\n                {\n                    _8780 = (fa_mesh_fs_params[8].y * (1.0 - exp(-min(fa_mesh_fs_params[8].w * _8708, 80.0)))) / fa_mesh_fs_params[8].w;\n                }\n                float _8807;\n                if (abs(_8698) < 0.001000000047497451305389404296875)\n                {\n                    _8807 = _8719;\n                }\n                else\n                {\n                    _8807 = (_8780 - _8747) / _8698;\n                }\n                tau += (_8648 * max(_8807, 0.0));\n            }\n            result = mix(result, fa_mesh_fs_params[7].xyz, vec3(clamp(1.0 - exp(-clamp(tau, 0.0, 80.0)), 0.0, 1.0)));\n        }\n    }\n    if (fa_tr_blend > 0.0)\n    {\n        float _8843 = 1.0 - fa_tr_blend;\n        result /= vec3(_8843);\n        _8901 *= _8843;\n    }\n    fa_frag_color = vec4(result, _8901);\n}\n\n",
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
      "vs": "#version 430\n\nstruct VertexData\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 color;\n    vec3 object_pos;\n};\n\nstruct points_item\n{\n    vec4 pos;\n    vec4 tint;\n};\n\nstruct extra_item\n{\n    vec4 pos;\n    vec4 tint;\n};\n\nlayout(binding = 1, std430) readonly buffer fa_vs_points_buf\n{\n    points_item data[];\n} fa_vs_points;\n\nlayout(binding = 0, std430) readonly buffer fa_vs_extra_buf\n{\n    extra_item data[];\n} fa_vs_extra;\n\nuniform vec4 fa_mesh_vs_params[11];\nuniform vec4 fa_skin[192];\nuniform vec4 fa_inst_base[4];\nlayout(location = 0) out vec3 fa_world_pos;\nlayout(location = 1) out vec3 fa_world_normal;\nlayout(location = 2) out vec4 fa_world_tangent;\nlayout(location = 3) out vec2 fa_uv;\nlayout(location = 4) out vec4 fa_vertex_color;\nlayout(location = 9) in vec4 fa_joints;\nlayout(location = 10) in vec4 fa_weights;\nlayout(location = 0) in vec3 fa_position;\nlayout(location = 1) in vec3 fa_normal;\nlayout(location = 3) in vec4 fa_tangent;\nlayout(location = 2) in vec2 fa_texcoord0;\nlayout(location = 4) in vec4 fa_color;\nlayout(location = 5) out vec3 fa_lm;\nlayout(location = 5) in vec4 fa_inst_m0;\nlayout(location = 6) in vec4 fa_inst_m1;\nlayout(location = 7) in vec4 fa_inst_m2;\nlayout(location = 8) in vec4 fa_inst_m3;\n\nvoid fa_inst_begin()\n{\n}\n\nmat4 fa_skin_matrix(vec4 joints, vec4 weights)\n{\n    vec4 r0 = vec4(0.0);\n    vec4 r1 = vec4(0.0);\n    vec4 r2 = vec4(0.0);\n    for (int i = 0; i < 4; i++)\n    {\n        int _222 = int((joints[i] * 255.0) + 0.5) * 3;\n        r0 += (fa_skin[_222 * 1 + 0] * weights[i]);\n        r1 += (fa_skin[(_222 + 1) * 1 + 0] * weights[i]);\n        r2 += (fa_skin[(_222 + 2) * 1 + 0] * weights[i]);\n    }\n    return mat4(vec4(r0.x, r1.x, r2.x, 0.0), vec4(r0.y, r1.y, r2.y, 0.0), vec4(r0.z, r1.z, r2.z, 0.0), vec4(r0.w, r1.w, r2.w, 1.0));\n}\n\nVertexData fa_vertex_data(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    vec3 _129 = cross(model[1].xyz, model[2].xyz);\n    float _133 = (dot(model[0].xyz, _129) < 0.0) ? (-1.0) : 1.0;\n    return VertexData((model * vec4(position, 1.0)).xyz, (((_129 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _133, vec4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _133), texcoord0 * fa_mesh_vs_params[8].xy, color, position);\n}\n\nvoid vertex(inout VertexData v)\n{\n    bool _67 = fa_vs_points.data[gl_InstanceID].pos.w < 0.5;\n    bool _82;\n    if (!_67)\n    {\n        _82 = fa_vs_extra.data[gl_InstanceID].pos.w < (-1.0);\n    }\n    else\n    {\n        _82 = _67;\n    }\n    if (_82)\n    {\n        v.world_pos = vec3(1000000000.0);\n        return;\n    }\n    v.world_pos += fa_vs_points.data[gl_InstanceID].pos.xyz;\n    v.color = fa_vs_points.data[gl_InstanceID].tint;\n}\n\nvoid fa_shade_vertex(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    mat4 param = model;\n    vec3 param_1 = position;\n    vec3 param_2 = normal;\n    vec4 param_3 = tangent;\n    vec2 param_4 = texcoord0;\n    vec4 param_5 = color;\n    VertexData param_6 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    vertex(param_6);\n    fa_world_pos = param_6.world_pos;\n    fa_world_normal = param_6.world_normal;\n    fa_world_tangent = param_6.world_tangent;\n    fa_uv = param_6.uv;\n    fa_vertex_color = param_6.color;\n    gl_Position = mat4(fa_mesh_vs_params[0], fa_mesh_vs_params[1], fa_mesh_vs_params[2], fa_mesh_vs_params[3]) * vec4(param_6.world_pos, 1.0);\n}\n\nvoid main()\n{\n    fa_inst_begin();\n    vec4 param = fa_joints;\n    vec4 param_1 = fa_weights;\n    mat4 param_2 = mat4(fa_inst_base[0], fa_inst_base[1], fa_inst_base[2], fa_inst_base[3]) * fa_skin_matrix(param, param_1);\n    vec3 param_3 = fa_position;\n    vec3 param_4 = fa_normal;\n    vec4 param_5 = fa_tangent;\n    vec2 param_6 = fa_texcoord0;\n    vec4 param_7 = fa_color;\n    fa_shade_vertex(param_2, param_3, param_4, param_5, param_6, param_7);\n    fa_lm = vec3(0.0);\n}\n\n",
      "fs": "#version 430\n\nstruct SurfaceInput\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 vertex_color;\n    vec3 view_dir;\n    bool front_facing;\n};\n\nstruct LightSample\n{\n    vec3 direction;\n    vec3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct Surface\n{\n    vec3 albedo;\n    float alpha;\n    vec3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    vec3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    vec3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    vec3 specular_color;\n    float transmission;\n    float thickness;\n    vec3 attenuation_color;\n    float attenuation_distance;\n};\n\nstruct FaLayers\n{\n    bool on;\n    float f90;\n    float keep;\n    float base_scale;\n    float coat;\n    float coat_rough;\n    float coat_alpha;\n    float coat_a2;\n    vec3 nc;\n    float coat_ndv;\n    bool sheen_on;\n    vec3 sheen;\n    float sheen_rough;\n    float sheen_alpha;\n    float sheen_scale;\n    float sheen_e;\n    float aniso;\n    vec3 t;\n    vec3 b;\n    float at;\n    float ab;\n};\n\nconst float _4498[63] = float[](1.0, 1.0, 1.0, 0.4790000021457672119140625, 0.11699999868869781494140625, 0.01200000010430812835693359375, 0.0, 0.0, 0.0, 1.0, 1.0, 1.0, 0.578000009059906005859375, 0.19300000369548797607421875, 0.0350000001490116119384765625, 0.0030000000260770320892333984375, 0.0, 0.0, 1.0, 1.0, 1.0, 0.6740000247955322265625, 0.3459999859333038330078125, 0.1319999992847442626953125, 0.032999999821186065673828125, 0.0040000001899898052215576171875, 0.0, 0.971000015735626220703125, 0.954999983310699462890625, 0.828999996185302734375, 0.63999998569488525390625, 0.42599999904632568359375, 0.24500000476837158203125, 0.115000002086162567138671875, 0.037000000476837158203125, 0.0030000000260770320892333984375, 0.7469999790191650390625, 0.737999975681304931640625, 0.670000016689300537109375, 0.563000023365020751953125, 0.4309999942779541015625, 0.3039999902248382568359375, 0.1940000057220458984375, 0.1019999980926513671875, 0.0309999994933605194091796875, 0.614000022411346435546875, 0.609000027179718017578125, 0.566999971866607666015625, 0.499000012874603271484375, 0.412000000476837158203125, 0.32400000095367431640625, 0.240999996662139892578125, 0.162000000476837158203125, 0.087999999523162841796875, 0.538999974727630615234375, 0.535000026226043701171875, 0.505999982357025146484375, 0.4569999873638153076171875, 0.393999993801116943359375, 0.328999996185302734375, 0.2660000026226043701171875, 0.203999996185302734375, 0.14200000464916229248046875);\n\nstruct points_item\n{\n    vec4 pos;\n    vec4 tint;\n};\n\nuniform vec4 fa_mesh_fs_params[53];\nuniform vec4 fa_shadows[30];\nlayout(binding = 3, std430) readonly buffer fa_points_buf\n{\n    points_item data[];\n} points;\n\nlayout(binding = 0) uniform sampler2D fa_light_tex_fa_shadow_smp;\nlayout(binding = 1) uniform sampler2D fa_tex_fa_smp;\nlayout(binding = 2) uniform sampler2D fa_normal_tex_fa_smp;\nlayout(binding = 3) uniform sampler2D fa_mr_tex_fa_smp;\nlayout(binding = 4) uniform sampler2D fa_occlusion_tex_fa_smp;\nlayout(binding = 5) uniform sampler2D fa_emissive_tex_fa_smp;\nlayout(binding = 6) uniform sampler2D fa_decal_tex_fa_env_smp;\nlayout(binding = 7) uniform sampler2D fa_lightmap_fa_env_smp;\nlayout(binding = 8) uniform sampler2D fa_probe_atlas_fa_env_smp;\nlayout(binding = 9) uniform sampler2D fa_light_atlas_fa_env_smp;\nlayout(binding = 10) uniform sampler2D fa_screen_tex_fa_shadow_smp;\nlayout(binding = 11) uniform sampler2D fa_shadow_tex_fa_shadow_smp;\n\nlayout(location = 0) in vec3 fa_world_pos;\nlayout(location = 5) in vec3 fa_lm;\nlayout(location = 1) in vec3 fa_world_normal;\nlayout(location = 2) in vec4 fa_world_tangent;\nlayout(location = 3) in vec2 fa_uv;\nlayout(location = 4) in vec4 fa_vertex_color;\nlayout(location = 0) out vec4 fa_frag_color;\nvec3 fa_light_tint;\nbool fa_light_is_area;\nint fa_cl_ndir;\nint fa_cl_slot;\nint fa_cl_local;\n\nvoid fa_inst_load()\n{\n}\n\nvec4 fa_light_texel(int t)\n{\n    return texelFetch(fa_light_tex_fa_shadow_smp, ivec2(t & 1023, t >> 10), 0);\n}\n\nvec4 fa_cluster_texel(vec3 world_pos)\n{\n    bool _1588 = fa_mesh_fs_params[19].x < 0.0;\n    bool _1595;\n    if (!_1588)\n    {\n        _1595 = fa_mesh_fs_params[19].w < 1.0;\n    }\n    else\n    {\n        _1595 = _1588;\n    }\n    bool _1603;\n    if (!_1595)\n    {\n        _1603 = fa_mesh_fs_params[18].x < 1.0;\n    }\n    else\n    {\n        _1603 = _1595;\n    }\n    bool _1610;\n    if (!_1603)\n    {\n        _1610 = fa_mesh_fs_params[18].y < 1.0;\n    }\n    else\n    {\n        _1610 = _1603;\n    }\n    bool _1617;\n    if (!_1610)\n    {\n        _1617 = fa_mesh_fs_params[19].y < 1.0;\n    }\n    else\n    {\n        _1617 = _1610;\n    }\n    if (_1617)\n    {\n        return vec4(0.0);\n    }\n    vec4 _1627 = vec4(world_pos, 1.0);\n    float _1633 = dot(fa_mesh_fs_params[16], _1627);\n    if (!(_1633 > 9.9999999747524270787835121154785e-07))\n    {\n        return vec4(0.0);\n    }\n    vec2 _1655 = vec2(dot(fa_mesh_fs_params[14], _1627), dot(fa_mesh_fs_params[15], _1627)) / vec2(_1633);\n    int _1659 = int(fa_mesh_fs_params[18].x);\n    int _1663 = int(fa_mesh_fs_params[18].y);\n    int param = (int(fa_mesh_fs_params[19].x) + (((clamp(int(floor(log2(max(dot(fa_mesh_fs_params[17].xyz, world_pos) + fa_mesh_fs_params[17].w, fa_mesh_fs_params[18].w) / fa_mesh_fs_params[18].w) * fa_mesh_fs_params[18].z)), 0, int(fa_mesh_fs_params[19].y) - 1) * _1663) + clamp(int(floor(((_1655.y * 0.5) + 0.5) * fa_mesh_fs_params[18].y)), 0, _1663 - 1)) * _1659)) + clamp(int(floor(((_1655.x * 0.5) + 0.5) * fa_mesh_fs_params[18].x)), 0, _1659 - 1);\n    return fa_light_texel(param);\n}\n\nivec2 fa_cluster_lookup(vec3 world_pos)\n{\n    vec3 param = world_pos;\n    vec4 _1739 = fa_cluster_texel(param);\n    return ivec2(int(_1739.x), int(_1739.y));\n}\n\nvoid fa_cluster_begin(vec3 world_pos)\n{\n    fa_cl_ndir = int(fa_mesh_fs_params[19].z);\n    vec3 param = world_pos;\n    ivec2 _5965 = fa_cluster_lookup(param);\n    fa_cl_slot = _5965.x;\n    fa_cl_local = _5965.y;\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nvec3 fa_linear_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_tex_fix(inout vec3 c, float mode)\n{\n    if (mode > 1.5)\n    {\n        vec3 param = c;\n        vec3 _7139 = fa_linear_to_srgb(param);\n        c = _7139;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            vec3 param_1 = c;\n            vec3 _7147 = fa_srgb_to_linear(param_1);\n            c = _7147;\n        }\n    }\n    return c;\n}\n\nvec3 fa_tangent_normal(SurfaceInput i, vec3 m)\n{\n    vec3 _532;\n    if (i.front_facing)\n    {\n        _532 = i.world_normal;\n    }\n    else\n    {\n        _532 = -i.world_normal;\n    }\n    vec3 _556 = normalize(i.world_tangent.xyz - (_532 * dot(_532, i.world_tangent.xyz)));\n    vec3 _583 = normalize(((_556 * m.x) + ((cross(_532, _556) * i.world_tangent.w) * m.y)) + (_532 * m.z));\n    vec3 _586;\n    if (i.front_facing)\n    {\n        _586 = _583;\n    }\n    else\n    {\n        _586 = -_583;\n    }\n    return _586;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    vec4 base_t = texture(fa_tex_fa_smp, i.uv, fa_mesh_fs_params[12].w);\n    float param = fa_mesh_fs_params[6].w;\n    float param_1 = 1.0;\n    vec3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    vec3 _7179 = fa_tex_fix(param_2, param_3);\n    vec4 _9464 = base_t;\n    _9464.x = _7179.x;\n    _9464.y = _7179.y;\n    _9464.z = _7179.z;\n    base_t = _9464;\n    vec4 _7193 = (_9464 * fa_mesh_fs_params[2]) * i.vertex_color;\n    vec3 _9230 = i.world_normal;\n    if (fa_mesh_fs_params[6].z > 0.5)\n    {\n        float param_4 = fa_mesh_fs_params[6].w;\n        float param_5 = 16.0;\n        vec3 param_6 = texture(fa_normal_tex_fa_smp, i.uv, fa_mesh_fs_params[12].w).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        vec3 _7227 = fa_tex_fix(param_6, param_7);\n        vec3 _7230 = (_7227 * 2.0) - vec3(1.0);\n        vec2 _7235 = _7230.xy * fa_mesh_fs_params[6].x;\n        vec3 _9472 = _7230;\n        _9472.x = _7235.x;\n        _9472.y = _7235.y;\n        SurfaceInput param_8 = i;\n        vec3 param_9 = _9472;\n        _9230 = fa_tangent_normal(param_8, param_9);\n    }\n    vec4 mrt = texture(fa_mr_tex_fa_smp, i.uv, fa_mesh_fs_params[12].w);\n    float param_10 = fa_mesh_fs_params[6].w;\n    float param_11 = 64.0;\n    vec3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    vec3 _7265 = fa_tex_fix(param_12, param_13);\n    vec4 _9475 = mrt;\n    _9475.x = _7265.x;\n    _9475.y = _7265.y;\n    _9475.z = _7265.z;\n    mrt = _9475;\n    vec4 _7295 = texture(fa_occlusion_tex_fa_smp, i.uv, fa_mesh_fs_params[12].w);\n    float param_14 = fa_mesh_fs_params[6].w;\n    float param_15 = 256.0;\n    vec3 param_16 = _7295.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    vec3 _7306 = fa_tex_fix(param_16, param_17);\n    float param_18 = fa_mesh_fs_params[6].w;\n    float param_19 = 4.0;\n    vec3 param_20 = texture(fa_emissive_tex_fa_smp, i.uv, fa_mesh_fs_params[12].w).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    vec3 _7338 = fa_tex_fix(param_20, param_21);\n    float _9235 = fa_mesh_fs_params[20].x;\n    float _9236 = fa_mesh_fs_params[20].y;\n    float _9239 = fa_mesh_fs_params[20].z;\n    float _9238 = fa_mesh_fs_params[21].w;\n    float _9241 = fa_mesh_fs_params[22].x;\n    if (fa_mesh_fs_params[22].z > 0.5)\n    {\n        if (mod(fa_mesh_fs_params[22].z, 2.0) > 0.5)\n        {\n            _9235 *= _7306.y;\n            _9236 *= _7306.z;\n            _9238 *= _7295.w;\n        }\n        if (fa_mesh_fs_params[22].z > 1.5)\n        {\n            _9239 *= mrt.x;\n            _9241 *= mrt.w;\n        }\n    }\n    return Surface(_7193.xyz, _7193.w, _9230, clamp(fa_mesh_fs_params[5].x * _7265.z, 0.0, 1.0), clamp(fa_mesh_fs_params[5].y * _7265.y, 0.0500000007450580596923828125, 1.0), 1.0 + (fa_mesh_fs_params[6].y * (_7306.x - 1.0)), fa_mesh_fs_params[3].xyz + (fa_mesh_fs_params[4].xyz * _7338), _9235, _9236, fa_mesh_fs_params[21].xyz, _9238, _9239, fa_mesh_fs_params[20].w, _9241, fa_mesh_fs_params[22].y, fa_mesh_fs_params[23].xyz, fa_mesh_fs_params[30].x, fa_mesh_fs_params[30].y, fa_mesh_fs_params[31].xyz, fa_mesh_fs_params[30].z);\n}\n\nvoid surface(SurfaceInput i, inout Surface s)\n{\n    s.emission += (i.vertex_color.xyz * points.data[0].tint.w);\n}\n\nvec4 fa_decal_tile(vec4 rect, vec2 uv, vec2 atlas, vec2 ddx, vec2 ddy)\n{\n    vec2 _1819 = rect.zw - rect.xy;\n    vec2 _1823 = _1819 * atlas;\n    vec2 _1827 = ddx * _1823;\n    vec2 _1831 = ddy * _1823;\n    return textureLod(fa_decal_tex_fa_env_smp, rect.xy + (clamp(uv, vec2(0.0), vec2(1.0)) * _1819), clamp(0.5 * log2(max(max(dot(_1827, _1827), dot(_1831, _1831)), 9.9999999392252902907785028219223e-09)), 0.0, 3.0));\n}\n\nvec3 fa_dc_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_dc_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvoid fa_apply_decals(vec3 world_pos, vec3 geo_normal, inout vec3 albedo, inout vec3 normal)\n{\n    bool _1864 = fa_mesh_fs_params[10].y < 0.5;\n    bool _1871;\n    if (!_1864)\n    {\n        _1871 = fa_mesh_fs_params[10].w < 0.5;\n    }\n    else\n    {\n        _1871 = _1864;\n    }\n    if (_1871)\n    {\n        return;\n    }\n    vec3 _1877 = dFdx(world_pos);\n    vec3 _1880 = dFdy(world_pos);\n    vec3 param = world_pos;\n    vec4 _1884 = fa_cluster_texel(param);\n    int _1888 = int(_1884.w);\n    if (_1888 < 1)\n    {\n        return;\n    }\n    int _1898 = int(fa_mesh_fs_params[10].y + 0.5);\n    int param_1 = _1898;\n    vec4 _1902 = fa_light_texel(param_1);\n    vec2 _1905 = _1902.yz;\n    int _1909 = int(_1902.w);\n    int param_2 = _1898 + 1;\n    vec4 _1914 = fa_light_texel(param_2);\n    float _1915 = _1914.x;\n    int _1921 = int(fa_mesh_fs_params[10].w + 0.5) - 1;\n    int _1925 = int(_1884.z);\n    vec3 _2190;\n    for (int k = 0; k < _1888; k++)\n    {\n        int _1938 = _1925 + k;\n        int param_3 = _1909 + (_1938 >> 2);\n        int _1955 = (_1898 + 2) + (int(fa_light_texel(param_3)[_1938 & 3]) * 7);\n        int param_4 = _1955 + 6;\n        vec4 _1960 = fa_light_texel(param_4);\n        if (((int(_1960.w + 0.5) >> _1921) & 1) == 0)\n        {\n            continue;\n        }\n        int param_5 = _1955;\n        vec4 _1975 = fa_light_texel(param_5);\n        int param_6 = _1955 + 1;\n        vec4 _1980 = fa_light_texel(param_6);\n        int param_7 = _1955 + 2;\n        vec4 _1985 = fa_light_texel(param_7);\n        vec3 _1988 = _1975.xyz;\n        float _1993 = dot(_1988, world_pos) + _1975.w;\n        vec3 _1995 = _1980.xyz;\n        float _2000 = dot(_1995, world_pos) + _1980.w;\n        vec3 _2002 = _1985.xyz;\n        float _2007 = dot(_2002, world_pos) + _1985.w;\n        bool _2012 = abs(_1993) > 0.5;\n        bool _2020;\n        if (!_2012)\n        {\n            _2020 = abs(_2000) > 0.5;\n        }\n        else\n        {\n            _2020 = _2012;\n        }\n        bool _2028;\n        if (!_2020)\n        {\n            _2028 = abs(_2007) > 0.5;\n        }\n        else\n        {\n            _2028 = _2020;\n        }\n        if (_2028)\n        {\n            continue;\n        }\n        float _2043 = clamp(dot(geo_normal, normalize(_2002)) * _1960.z, 0.0, 1.0);\n        if (_2043 <= 0.0)\n        {\n            continue;\n        }\n        float _2063 = (clamp((0.5 - abs(_2007)) * 10.0, 0.0, 1.0) * _2043) * _1960.x;\n        vec2 _2071 = vec2(_1993 + 0.5, 0.5 - _2000);\n        vec2 _2081 = vec2(dot(_1988, _1877), dot(_1995, _1877));\n        vec2 _2091 = vec2(dot(_1988, _1880), dot(_1995, _1880));\n        int param_8 = _1955 + 5;\n        vec4 _2096 = fa_light_texel(param_8);\n        int param_9 = _1955 + 3;\n        vec4 _2101 = fa_light_texel(param_9);\n        int param_10 = _1955 + 4;\n        vec4 _2106 = fa_light_texel(param_10);\n        float tex_a = 1.0;\n        vec3 col = _2096.xyz;\n        bool _2116 = _2101.z > _2101.x;\n        if (_2116)\n        {\n            vec4 param_11 = _2101;\n            vec2 param_12 = _2071;\n            vec2 param_13 = _1905;\n            vec2 param_14 = _2081;\n            vec2 param_15 = _2091;\n            vec4 tx = fa_decal_tile(param_11, param_12, param_13, param_14, param_15);\n            if ((_1915 > 0.5) && (_1915 < 1.5))\n            {\n                vec3 param_16 = tx.xyz;\n                vec3 _2142 = fa_dc_to_linear(param_16);\n                vec4 _9318 = tx;\n                _9318.x = _2142.x;\n                _9318.y = _2142.y;\n                _9318.z = _2142.z;\n                tx = _9318;\n            }\n            col *= tx.xyz;\n            tex_a = tx.w;\n        }\n        albedo = mix(albedo, col, vec3(clamp((_2063 * tex_a) * _2096.w, 0.0, 1.0)));\n        if (_2106.z > _2106.x)\n        {\n            vec4 param_17 = _2106;\n            vec2 param_18 = _2071;\n            vec2 param_19 = _1905;\n            vec2 param_20 = _2081;\n            vec2 param_21 = _2091;\n            vec4 _2186 = fa_decal_tile(param_17, param_18, param_19, param_20, param_21);\n            if (_1915 > 1.5)\n            {\n                vec3 param_22 = _2186.xyz;\n                vec3 _2196 = fa_dc_to_srgb(param_22);\n                _2190 = _2196;\n            }\n            else\n            {\n                _2190 = _2186.xyz;\n            }\n            vec3 _2205 = (_2190 * 2.0) - vec3(1.0);\n            vec2 _2210 = _2205.xy * _1960.y;\n            vec3 _2232 = (normalize(_1988) * _2210.x) + (normalize(_1995) * _2210.y);\n            vec3 _2235 = normalize(normal);\n            normal = normalize(mix(_2235, normalize((_2235 * max(_2205.z, 0.0500000007450580596923828125)) + (_2232 - (_2235 * dot(_2235, _2232)))), vec3(clamp(_2063 * (_2116 ? tex_a : 1.0), 0.0, 1.0))));\n        }\n    }\n}\n\nfloat fa_sheen_albedo(float ndv, float rough)\n{\n    float _4423 = min(sqrt(max(rough - 0.100000001490116119384765625, 0.0) * 1.111111164093017578125) * 6.0, 5.999000072479248046875);\n    float _4431 = min(sqrt(clamp(ndv, 0.0, 1.0)) * 8.0, 7.999000072479248046875);\n    int _4434 = int(_4423);\n    int _4437 = int(_4431);\n    float _4447 = _4431 - float(_4437);\n    int _4502 = (_4434 * 9) + _4437;\n    int _4522 = ((_4434 + 1) * 9) + _4437;\n    return mix(mix(_4498[_4502], _4498[_4502 + 1], _4447), mix(_4498[_4522], _4498[_4522 + 1], _4447), _4423 - float(_4434));\n}\n\nFaLayers fa_layers_setup(SurfaceInput i, Surface s, vec3 n, vec3 v, float metallic, float roughness, inout vec3 f0)\n{\n    bool _9153 = false;\n    float _9154 = 1.0;\n    float _9155 = 1.0;\n    float _9156 = 1.0;\n    float _9157 = 0.0;\n    float _9158 = 0.0;\n    float _9159 = 0.0;\n    float _9160 = 0.0;\n    float _9162 = 1.0;\n    bool _9163 = false;\n    vec3 _9164 = vec3(0.0);\n    float _9165 = 1.0;\n    float _9166 = 1.0;\n    float _9167 = 1.0;\n    float _9168 = 0.0;\n    float _9169 = 0.0;\n    vec3 _9170 = vec3(1.0, 0.0, 0.0);\n    vec3 _9171 = vec3(0.0, 0.0, 1.0);\n    float _9172 = 1.0;\n    float _9173 = 1.0;\n    float _4573 = clamp(s.specular, 0.0, 1.0);\n    float _4577 = clamp(s.ior, 1.0, 3.0);\n    bool _4582 = (_4573 != 1.0) || (_4577 != 1.5);\n    bool _4591;\n    if (!_4582)\n    {\n        _4591 = any(notEqual(s.specular_color, vec3(1.0)));\n    }\n    else\n    {\n        _4591 = _4582;\n    }\n    if (_4591)\n    {\n        float _4599 = (_4577 - 1.0) / (_4577 + 1.0);\n        f0 = mix(min(vec3(_4599 * _4599) * max(s.specular_color, vec3(0.0)), vec3(1.0)) * _4573, s.albedo, vec3(metallic));\n        _9154 = mix(_4573, 1.0, metallic);\n        _9153 = true;\n    }\n    float _4626 = clamp(s.clearcoat, 0.0, 1.0);\n    if (_4626 > 0.0)\n    {\n        float _4634 = clamp(s.clearcoat_roughness, 0.0500000007450580596923828125, 1.0);\n        _9157 = _4626;\n        _9158 = _4634;\n        float _4641 = _4634 * _4634;\n        _9159 = _4641;\n        _9160 = _4641 * _4641;\n        float _4653 = max(dot(i.world_normal, v), 9.9999997473787516355514526367188e-05);\n        _9162 = _4653;\n        _9155 = 1.0 - (_4626 * (0.039999999105930328369140625 + (0.959999978542327880859375 * pow(clamp(1.0 - _4653, 0.0, 1.0), 5.0))));\n        _9153 = true;\n    }\n    vec3 _4672 = max(s.sheen_color, vec3(0.0));\n    float _4681 = max(_4672.x, max(_4672.y, _4672.z));\n    if (_4681 > 0.0)\n    {\n        float _4689 = clamp(s.sheen_roughness, 0.100000001490116119384765625, 1.0);\n        _9163 = true;\n        _9164 = _4672;\n        _9165 = _4689;\n        _9166 = _4689 * _4689;\n        float param = max(dot(n, v), 9.9999997473787516355514526367188e-05);\n        float param_1 = _4689;\n        float _4706 = fa_sheen_albedo(param, param_1);\n        _9168 = _4706;\n        _9167 = 1.0 - min(_4681 * _4706, 1.0);\n        _9153 = true;\n    }\n    _9156 = _9155 * _9167;\n    float _4725 = clamp(s.anisotropy, -1.0, 1.0);\n    if (_4725 != 0.0)\n    {\n        vec3 _4740 = i.world_tangent.xyz - (n * dot(n, i.world_tangent.xyz));\n        vec3 t = _4740;\n        if (dot(_4740, _4740) < 9.9999999392252902907785028219223e-09)\n        {\n            bvec3 _4752 = bvec3(abs(n.y) < 0.9900000095367431640625);\n            t = cross(vec3(_4752.x ? vec3(0.0, 1.0, 0.0).x : vec3(1.0, 0.0, 0.0).x, _4752.y ? vec3(0.0, 1.0, 0.0).y : vec3(1.0, 0.0, 0.0).y, _4752.z ? vec3(0.0, 1.0, 0.0).z : vec3(1.0, 0.0, 0.0).z), n);\n        }\n        vec3 _4756 = t;\n        vec3 _4757 = normalize(_4756);\n        t = _4757;\n        vec3 _4782 = normalize((_4757 * cos(s.anisotropy_rotation)) + ((cross(n, _4757) * ((i.world_tangent.w < 0.0) ? (-1.0) : 1.0)) * sin(s.anisotropy_rotation)));\n        _9170 = _4782;\n        _9171 = cross(n, _4782);\n        float _4792 = roughness * roughness;\n        float _4798 = mix(_4792, 1.0, _4725 * _4725);\n        bool _4800 = _4725 > 0.0;\n        _9172 = _4800 ? _4798 : _4792;\n        _9173 = _4800 ? _4792 : _4798;\n        _9169 = _4725;\n        _9153 = true;\n    }\n    return FaLayers(_9153, _9154, _9155, _9156, _9157, _9158, _9159, _9160, i.world_normal, _9162, _9163, _9164, _9165, _9166, _9167, _9168, _9169, _9170, _9171, _9172, _9173);\n}\n\nvec2 fa_atlas_size()\n{\n    return vec2(textureSize(fa_probe_atlas_fa_env_smp, 0));\n}\n\nvec3 fa_probe_sh_coef(vec2 origin, float res, int k)\n{\n    vec3 v = textureLod(fa_probe_atlas_fa_env_smp, (origin + vec2(float(k) + 0.5, res + 2.5)) / fa_atlas_size(), 0.0).xyz;\n    if (fa_mesh_fs_params[41].y > 0.5)\n    {\n        v = ((v * 255.0) - vec3(128.0)) * 0.03149606287479400634765625;\n    }\n    return v;\n}\n\nvec3 fa_sh_eval(vec3 c[9], vec3 n)\n{\n    vec3 _3592 = max((((c[0] * 0.2820948064327239990234375) + (((c[1] * (0.3257350027561187744140625 * n.y)) + (c[2] * (0.3257350027561187744140625 * n.z))) + (c[3] * (0.3257350027561187744140625 * n.x)))) + (((c[4] * ((0.2731371223926544189453125 * n.x) * n.y)) + (c[5] * ((0.2731371223926544189453125 * n.y) * n.z))) + (c[6] * (0.078847892582416534423828125 * (((3.0 * n.z) * n.z) - 1.0))))) + ((c[7] * ((0.2731371223926544189453125 * n.x) * n.z)) + (c[8] * (0.13656856119632720947265625 * ((n.x * n.x) - (n.y * n.y))))), vec3(0.0));\n    return _3592;\n}\n\nvec3 fa_ambient_light(vec3 n)\n{\n    float _4204 = (1.0 - fa_mesh_fs_params[42].w) - fa_mesh_fs_params[47].w;\n    vec3 amb = vec3(0.0);\n    bool _4209 = fa_mesh_fs_params[11].w > 0.5;\n    vec3 c[9];\n    for (int k = 0; k < 9; k++)\n    {\n        c[k] = vec3(0.0);\n    }\n    if (_4204 > 0.0005000000237487256526947021484375)\n    {\n        if (_4209)\n        {\n            for (int k_1 = 0; k_1 < 9; k_1++)\n            {\n                vec2 param = fa_mesh_fs_params[41].zw;\n                float param_1 = 128.0;\n                int param_2 = k_1;\n                c[k_1] = fa_probe_sh_coef(param, param_1, param_2) * _4204;\n            }\n        }\n        else\n        {\n            amb = fa_mesh_fs_params[1].xyz * _4204;\n        }\n    }\n    bool _4260 = fa_mesh_fs_params[42].w > 0.0;\n    if (_4260)\n    {\n        for (int k_2 = 0; k_2 < 9; k_2++)\n        {\n            vec2 param_3 = fa_mesh_fs_params[42].xy;\n            float param_4 = fa_mesh_fs_params[42].z;\n            int param_5 = k_2;\n            c[k_2] += (fa_probe_sh_coef(param_3, param_4, param_5) * fa_mesh_fs_params[42].w);\n        }\n    }\n    bool _4291 = fa_mesh_fs_params[47].w > 0.0;\n    if (_4291)\n    {\n        for (int k_3 = 0; k_3 < 9; k_3++)\n        {\n            vec2 param_6 = fa_mesh_fs_params[47].xy;\n            float param_7 = fa_mesh_fs_params[47].z;\n            int param_8 = k_3;\n            c[k_3] += (fa_probe_sh_coef(param_6, param_7, param_8) * fa_mesh_fs_params[47].w);\n        }\n    }\n    if ((_4209 || _4260) || _4291)\n    {\n        vec3 param_9[9] = c;\n        vec3 param_10 = n;\n        amb += fa_sh_eval(param_9, param_10);\n    }\n    return amb;\n}\n\nvec4 fa_gi_fetch(vec2 texel)\n{\n    return textureLod(fa_probe_atlas_fa_env_smp, texel / fa_atlas_size(), 0.0);\n}\n\nvec2 fa_oct_encode(vec3 d)\n{\n    vec3 _3612 = d / vec3(max((abs(d.x) + abs(d.y)) + abs(d.z), 9.9999999600419720025001879548654e-13));\n    float _3615 = _3612.x;\n    float _3617 = _3612.z;\n    vec2 e = vec2(_3615, _3617);\n    if (_3612.y < 0.0)\n    {\n        e = vec2((1.0 - abs(_3617)) * ((_3615 < 0.0) ? (-1.0) : 1.0), (1.0 - abs(_3615)) * ((_3617 < 0.0) ? (-1.0) : 1.0));\n    }\n    return e;\n}\n\nvec3 fa_gi_grid(int rec, vec3 n, vec3 v, out float cover)\n{\n    cover = 0.0;\n    int param = rec;\n    vec4 _7448 = fa_light_texel(param);\n    int param_1 = rec + 1;\n    vec4 _7453 = fa_light_texel(param_1);\n    int param_2 = rec + 2;\n    vec4 _7458 = fa_light_texel(param_2);\n    int param_3 = rec + 3;\n    vec4 _7463 = fa_light_texel(param_3);\n    bool _7466 = _7463.z < 0.5;\n    bool _7474;\n    if (!_7466)\n    {\n        _7474 = fa_atlas_size().y < 1155.0;\n    }\n    else\n    {\n        _7474 = _7466;\n    }\n    if (_7474)\n    {\n        return vec3(0.0);\n    }\n    float _7481 = max(_7448.w, 9.9999997473787516355514526367188e-05);\n    vec3 _7484 = _7453.xyz;\n    vec3 _7488 = _7448.xyz;\n    vec3 _7492 = (fa_world_pos - _7488) / vec3(_7481);\n    vec3 _7501 = min(_7492 + vec3(0.5), (_7484 - vec3(0.5)) - _7492);\n    float _7510 = min(_7501.x, min(_7501.y, _7501.z));\n    if (!(_7510 > 0.0))\n    {\n        return vec3(0.0);\n    }\n    vec3 _7525 = _7484 - vec3(1.0);\n    vec3 _7526 = clamp(_7492, vec3(0.0), _7525);\n    vec3 _7534 = min(floor(_7526), max(_7484 - vec3(2.0), vec3(0.0)));\n    vec3 _7538 = _7526 - _7534;\n    vec3 _7549 = fa_world_pos + (((n * 0.800000011920928955078125) + (v * 0.20000000298023223876953125)) * (0.20000000298023223876953125 * _7481));\n    int _7554 = int(_7458.y + 0.5);\n    float _7559 = 0.3257350027561187744140625 * n.y;\n    float _7563 = 0.3257350027561187744140625 * n.z;\n    float _7567 = 0.3257350027561187744140625 * n.x;\n    float _7574 = (0.2731371223926544189453125 * n.x) * n.y;\n    float _7581 = (0.2731371223926544189453125 * n.y) * n.z;\n    float _7590 = 0.078847892582416534423828125 * (((3.0 * n.z) * n.z) - 1.0);\n    float _7597 = (0.2731371223926544189453125 * n.x) * n.z;\n    float _7610 = 0.13656856119632720947265625 * ((n.x * n.x) - (n.y * n.y));\n    vec3 acc = vec3(0.0);\n    float wsum = 0.0;\n    int _7617 = 8 + int(_7463.w);\n    float _7644;\n    float _7657;\n    float _7671;\n    for (int k = 0; k < _7617; k++)\n    {\n        float _7630 = float(k & 1);\n        float _7634 = float((k >> 1) & 1);\n        float _7638 = float((k >> 2) & 1);\n        if (_7630 > 0.5)\n        {\n            _7644 = _7538.x;\n        }\n        else\n        {\n            _7644 = 1.0 - _7538.x;\n        }\n        if (_7634 > 0.5)\n        {\n            _7657 = _7538.y;\n        }\n        else\n        {\n            _7657 = 1.0 - _7538.y;\n        }\n        if (_7638 > 0.5)\n        {\n            _7671 = _7538.z;\n        }\n        else\n        {\n            _7671 = 1.0 - _7538.z;\n        }\n        float _7681 = (_7644 * _7657) * _7671;\n        if (!(_7681 > 0.0))\n        {\n            continue;\n        }\n        vec3 _7694 = min(_7534 + vec3(_7630, _7634, _7638), _7525);\n        int _7714 = int(((_7458.x + _7694.x) + (_7453.x * (_7694.y + (_7453.y * _7694.z)))) + 0.5);\n        vec2 _7729 = vec2(float(_7714 % _7554) * 10.0, 1024.0 + (float(_7714 / _7554) * 11.0));\n        vec2 param_4 = _7729 + vec2(9.5, 10.5);\n        vec4 _7737 = fa_gi_fetch(param_4);\n        bool _7740 = _7737.y < 0.5;\n        bool _7749;\n        if (!_7740)\n        {\n            _7749 = _7737.x > _7463.y;\n        }\n        else\n        {\n            _7749 = _7740;\n        }\n        if (_7749)\n        {\n            continue;\n        }\n        vec3 _7761 = _7549 - (_7488 + (_7694 * _7481));\n        float _7764 = length(_7761);\n        vec3 _7770 = _7761 / vec3(max(_7764, 9.9999997473787516355514526367188e-05));\n        float _7780 = max(9.9999997473787516355514526367188e-05, (dot(-_7770, n) + 1.0) * 0.5);\n        float w = _7681 * (_7780 * _7780);\n        vec3 param_5 = _7770;\n        vec2 param_6 = (_7729 + vec2(1.0)) + (((fa_oct_encode(param_5) * 0.5) + vec2(0.5)) * 8.0);\n        vec4 _7799 = fa_gi_fetch(param_6);\n        float _7806 = _7764 / max(_7458.z, 9.9999997473787516355514526367188e-05);\n        float _7809 = _7799.x;\n        if (_7806 > _7809)\n        {\n            float _7822 = max(_7799.y - (_7809 * _7809), 0.0);\n            float _7827 = _7806 - _7809;\n            float _7836 = _7822 / max(_7822 + (_7827 * _7827), 9.9999999600419720025001879548654e-13);\n            w *= ((_7836 * _7836) * _7836);\n        }\n        if (!(w > 0.0))\n        {\n            continue;\n        }\n        vec2 param_7 = _7729 + vec2(0.5, 10.5);\n        vec2 param_8 = _7729 + vec2(1.5, 10.5);\n        vec2 param_9 = _7729 + vec2(2.5, 10.5);\n        vec2 param_10 = _7729 + vec2(3.5, 10.5);\n        vec2 param_11 = _7729 + vec2(4.5, 10.5);\n        vec2 param_12 = _7729 + vec2(5.5, 10.5);\n        vec2 param_13 = _7729 + vec2(6.5, 10.5);\n        vec2 param_14 = _7729 + vec2(7.5, 10.5);\n        vec2 param_15 = _7729 + vec2(8.5, 10.5);\n        acc += ((((((((((fa_gi_fetch(param_7).xyz * 0.2820948064327239990234375) + (fa_gi_fetch(param_8).xyz * _7559)) + (fa_gi_fetch(param_9).xyz * _7563)) + (fa_gi_fetch(param_10).xyz * _7567)) + (fa_gi_fetch(param_11).xyz * _7574)) + (fa_gi_fetch(param_12).xyz * _7581)) + (fa_gi_fetch(param_13).xyz * _7590)) + (fa_gi_fetch(param_14).xyz * _7597)) + (fa_gi_fetch(param_15).xyz * _7610)) * w);\n        wsum += w;\n    }\n    if (!(wsum > 9.9999997473787516355514526367188e-06))\n    {\n        return vec3(0.0);\n    }\n    cover = smoothstep(0.0, 1.0, clamp(_7510 * 2.0, 0.0, 1.0)) * smoothstep(0.0, 0.0199999995529651641845703125, wsum);\n    float _7961;\n    if (fa_mesh_fs_params[52].z > 0.5)\n    {\n        _7961 = _7463.x;\n    }\n    else\n    {\n        _7961 = 1.0;\n    }\n    return max(acc / vec3(wsum), vec3(0.0)) * (_7458.w * _7961);\n}\n\nvec3 fa_gi_light(vec3 n, inout float left)\n{\n    left = 1.0;\n    vec3 acc = vec3(0.0);\n    vec3 _7985 = normalize(fa_mesh_fs_params[0].xyz - fa_world_pos);\n    int _7990 = int(fa_mesh_fs_params[52].x + 0.5);\n    int _7995 = int(fa_mesh_fs_params[52].y + 0.5);\n    float param_3;\n    for (int k = 0; (k < _7995) && (k < 8); k++)\n    {\n        int param = _7990 + (4 * k);\n        vec3 param_1 = n;\n        vec3 param_2 = _7985;\n        vec3 _8020 = fa_gi_grid(param, param_1, param_2, param_3);\n        float _8025 = param_3 * left;\n        acc += (_8020 * _8025);\n        left -= _8025;\n        if (left < 0.001000000047497451305389404296875)\n        {\n            left = 0.0;\n            break;\n        }\n    }\n    return acc;\n}\n\nvec3 fa_realtime_or_ambient(vec3 n)\n{\n    vec3 gi = vec3(0.0);\n    float left = 1.0;\n    if (fa_mesh_fs_params[52].y > 0.5)\n    {\n        vec3 param = n;\n        float param_1;\n        vec3 _8054 = fa_gi_light(param, param_1);\n        left = param_1;\n        gi = _8054;\n    }\n    if (left <= 0.0)\n    {\n        return gi;\n    }\n    vec3 param_2 = n;\n    return gi + (fa_ambient_light(param_2) * left);\n}\n\nvec3 fa_indirect_diffuse(vec3 n)\n{\n    if (fa_lm.z > 0.5)\n    {\n        return textureLod(fa_lightmap_fa_env_smp, fa_lm.xy, 0.0).xyz;\n    }\n    if (fa_mesh_fs_params[32].w > 0.0)\n    {\n        vec3 c[9];\n        for (int k = 0; k < 9; k++)\n        {\n            c[k] = fa_mesh_fs_params[k * 1 + 32].xyz;\n        }\n        vec3 param = n;\n        vec3 param_1[9] = c;\n        vec3 param_2 = n;\n        return mix(fa_ambient_light(param), fa_sh_eval(param_1, param_2), vec3(clamp(fa_mesh_fs_params[32].w, 0.0, 1.0)));\n    }\n    vec3 param_3 = n;\n    return fa_realtime_or_ambient(param_3);\n}\n\nint fa_cluster_index(int slot, int n)\n{\n    int param = (int(fa_mesh_fs_params[19].x) + int(fa_mesh_fs_params[19].w)) + ((slot + n) >> 2);\n    vec4 t = fa_light_texel(param);\n    return int(t[(slot + n) & 3]);\n}\n\nint fa_cl_light(int n)\n{\n    if (n < fa_cl_ndir)\n    {\n        return n;\n    }\n    int param = fa_cl_slot;\n    int param_1 = n - fa_cl_ndir;\n    return fa_cluster_index(param, param_1);\n}\n\nint fa_light_base(int li)\n{\n    return li * ((fa_mesh_fs_params[1].w > 4.5) ? 8 : 4);\n}\n\nbool fa_light_baked(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 3;\n    return fa_light_texel(param_1).w > 0.5;\n}\n\nfloat fa_baked_keep(int li)\n{\n    float _5935;\n    if (fa_lm.z > 0.5)\n    {\n        _5935 = 0.0;\n    }\n    else\n    {\n        _5935 = 1.0 - clamp(fa_mesh_fs_params[32].w, 0.0, 1.0);\n    }\n    bool _5946 = _5935 < 1.0;\n    bool _5952;\n    if (_5946)\n    {\n        int param = li;\n        _5952 = fa_light_baked(param);\n    }\n    else\n    {\n        _5952 = _5946;\n    }\n    return _5952 ? _5935 : 1.0;\n}\n\nfloat fa_light_type(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 1;\n    return fa_light_texel(param_1).w;\n}\n\nvec4 fa_atlas_fetch(vec2 texel)\n{\n    return textureLod(fa_light_atlas_fa_env_smp, texel / vec2(textureSize(fa_light_atlas_fa_env_smp, 0)), 0.0);\n}\n\nvec3 fa_cookie_sample(vec2 tile_origin, vec2 uv)\n{\n    vec2 param = (tile_origin + vec2(1.0)) + (clamp(uv, vec2(0.0), vec2(1.0)) * 254.0);\n    return fa_atlas_fetch(param).xyz;\n}\n\nvec3 fa_area_point(vec3 c, vec3 axis, vec3 ru, vec3 uu, float hx, float hy, float shape, vec3 p, vec3 r)\n{\n    bool _837 = dot(r, r) > 0.5;\n    if (shape > 1.5)\n    {\n        vec3 _850 = (c - (ru * hx)) - p;\n        vec3 _856 = ru * (2.0 * hx);\n        float _862 = max(dot(_856, _856), 9.9999999392252902907785028219223e-09);\n        float _866 = dot(_850, _856);\n        float t = clamp((-_866) / _862, 0.0, 1.0);\n        if (_837)\n        {\n            float _881 = dot(r, _856);\n            float _887 = _862 - (_881 * _881);\n            if (abs(_887) > (9.9999997473787516355514526367188e-06 * _862))\n            {\n                t = clamp(((dot(r, _850) * _881) - _866) / _887, 0.0, 1.0);\n            }\n        }\n        return (p + _850) + (_856 * t);\n    }\n    vec3 q = p;\n    float _919 = dot(r, axis);\n    bool _927;\n    if (_837)\n    {\n        _927 = abs(_919) > 9.9999997473787516355514526367188e-05;\n    }\n    else\n    {\n        _927 = _837;\n    }\n    if (_927)\n    {\n        float _937 = dot(c - p, axis) / _919;\n        if (_937 > 0.0)\n        {\n            q = p + (r * _937);\n        }\n    }\n    vec3 _950 = q - c;\n    vec2 xy = vec2(dot(_950, ru), dot(_950, uu));\n    if (shape > 0.5)\n    {\n        float _965 = length(xy);\n        if (_965 > hx)\n        {\n            xy *= (hx / _965);\n        }\n    }\n    else\n    {\n        xy = clamp(xy, vec2(-hx, -hy), vec2(hx, hy));\n    }\n    return (c + (ru * xy.x)) + (uu * xy.y);\n}\n\nint fa_cube_face(vec3 d)\n{\n    vec3 _598 = abs(d);\n    float _600 = _598.x;\n    float _602 = _598.y;\n    bool _603 = _600 >= _602;\n    bool _611;\n    if (_603)\n    {\n        _611 = _600 >= _598.z;\n    }\n    else\n    {\n        _611 = _603;\n    }\n    int _612;\n    if (_611)\n    {\n        _612 = (d.x > 0.0) ? 0 : 1;\n    }\n    else\n    {\n        int _627;\n        if (_602 >= _598.z)\n        {\n            _627 = (d.y > 0.0) ? 2 : 3;\n        }\n        else\n        {\n            _627 = (d.z > 0.0) ? 4 : 5;\n        }\n        _612 = _627;\n    }\n    return _612;\n}\n\nvoid fa_cube_face_basis(int f, out vec3 fwd, out vec3 up)\n{\n    if (f == 0)\n    {\n        fwd = vec3(1.0, 0.0, 0.0);\n        up = vec3(0.0, 1.0, 0.0);\n    }\n    else\n    {\n        if (f == 1)\n        {\n            fwd = vec3(-1.0, 0.0, 0.0);\n            up = vec3(0.0, 1.0, 0.0);\n        }\n        else\n        {\n            if (f == 2)\n            {\n                fwd = vec3(0.0, 1.0, 0.0);\n                up = vec3(0.0, 0.0, 1.0);\n            }\n            else\n            {\n                if (f == 3)\n                {\n                    fwd = vec3(0.0, -1.0, 0.0);\n                    up = vec3(0.0, 0.0, -1.0);\n                }\n                else\n                {\n                    if (f == 4)\n                    {\n                        fwd = vec3(0.0, 0.0, 1.0);\n                        up = vec3(0.0, 1.0, 0.0);\n                    }\n                    else\n                    {\n                        fwd = vec3(0.0, 0.0, -1.0);\n                        up = vec3(0.0, 1.0, 0.0);\n                    }\n                }\n            }\n        }\n    }\n}\n\nfloat fa_ies_sample(vec2 tile_origin, vec3 d, vec3 axis, vec3 right, vec3 up)\n{\n    float _757 = dot(d, right);\n    float _761 = dot(d, up);\n    float _772;\n    if (((_757 * _757) + (_761 * _761)) > 1.0000000133514319600180897396058e-10)\n    {\n        _772 = atan(_761, _757) * 0.15915493667125701904296875;\n    }\n    else\n    {\n        _772 = 0.0;\n    }\n    vec2 param = tile_origin + vec2(1.0 + ((_772 - floor(_772)) * 64.0), 1.0 + (acos(clamp(dot(d, axis), -1.0, 1.0)) * 10.18591594696044921875));\n    return fa_atlas_fetch(param).x;\n}\n\nLightSample fa_light_sample_n(int li, vec3 world_pos, vec3 n)\n{\n    int param = li;\n    int _1003 = fa_light_base(param);\n    bool _1007 = fa_mesh_fs_params[1].w > 4.5;\n    int param_1 = _1003;\n    vec4 _1011 = fa_light_texel(param_1);\n    int param_2 = _1003 + 1;\n    vec4 _1016 = fa_light_texel(param_2);\n    float _1019 = _1016.w;\n    float atten = 1.0;\n    float dist = 0.0;\n    fa_light_tint = vec3(1.0);\n    bool _1031 = _1007 && (_1019 > 2.5);\n    fa_light_is_area = _1031;\n    bool _1033 = _1019 < 0.5;\n    vec3 l;\n    if (_1033)\n    {\n        l = normalize(_1011.xyz);\n        if (_1007)\n        {\n            int param_3 = _1003 + 6;\n            vec4 _1047 = fa_light_texel(param_3);\n            if (_1047.z > 0.5)\n            {\n                int param_4 = _1003 + 4;\n                vec4 _1057 = fa_light_texel(param_4);\n                int param_5 = _1003 + 5;\n                vec4 _1062 = fa_light_texel(param_5);\n                vec2 param_6 = _1047.xy;\n                vec2 param_7 = fract(vec2(dot(world_pos, _1057.xyz) * _1057.w, (-dot(world_pos, _1062.xyz)) * _1062.w) + vec2(0.5));\n                fa_light_tint = fa_cookie_sample(param_6, param_7);\n            }\n        }\n    }\n    else\n    {\n        vec3 _1092 = _1011.xyz;\n        vec3 _1094 = _1092 - world_pos;\n        vec3 to_light = _1094;\n        float _1097 = length(_1094);\n        float reach = _1097;\n        bool front = true;\n        if (_1031)\n        {\n            int param_8 = _1003 + 7;\n            reach = max(_1097 - fa_light_texel(param_8).w, 0.0);\n            int param_9 = _1003 + 4;\n            vec4 _1121 = fa_light_texel(param_9);\n            int param_10 = _1003 + 5;\n            vec4 _1126 = fa_light_texel(param_10);\n            int param_11 = _1003 + 6;\n            vec4 _1131 = fa_light_texel(param_11);\n            float _1132 = _1131.w;\n            int param_12 = _1003 + 2;\n            vec3 _1139 = normalize(fa_light_texel(param_12).xyz);\n            bool _1141 = _1132 > 1.5;\n            bool _1149;\n            if (!_1141)\n            {\n                _1149 = dot(_1139, to_light) < 0.0;\n            }\n            else\n            {\n                _1149 = _1141;\n            }\n            front = _1149;\n            vec3 r = vec3(0.0);\n            vec3 _1158 = fa_mesh_fs_params[0].xyz - world_pos;\n            bool _1162 = dot(n, n) > 0.5;\n            bool _1170;\n            if (_1162)\n            {\n                _1170 = dot(_1158, _1158) > 9.9999999600419720025001879548654e-13;\n            }\n            else\n            {\n                _1170 = _1162;\n            }\n            if (_1170)\n            {\n                r = reflect(-normalize(_1158), normalize(n));\n            }\n            vec3 param_13 = _1092;\n            vec3 param_14 = _1139;\n            vec3 param_15 = _1121.xyz;\n            vec3 param_16 = _1126.xyz;\n            float param_17 = _1121.w;\n            float param_18 = _1126.w;\n            float param_19 = _1132;\n            vec3 param_20 = world_pos;\n            vec3 param_21 = r;\n            to_light = fa_area_point(param_13, param_14, param_15, param_16, param_17, param_18, param_19, param_20, param_21) - world_pos;\n        }\n        float _1206 = length(to_light);\n        dist = _1206;\n        l = to_light / vec3(max(_1206, 9.9999997473787516355514526367188e-05));\n        float _1220 = reach / max(_1011.w, 0.001000000047497451305389404296875);\n        float _1226 = clamp(1.0 - (_1220 * _1220), 0.0, 1.0);\n        float _1228;\n        if (front)\n        {\n            _1228 = _1226 * _1226;\n        }\n        else\n        {\n            _1228 = 0.0;\n        }\n        atten = _1228;\n        bool _1239 = _1019 < 2.5;\n        if ((_1019 > 1.5) && _1239)\n        {\n            int param_22 = _1003 + 2;\n            vec4 _1247 = fa_light_texel(param_22);\n            float _1257 = _1247.w;\n            int param_23 = _1003 + 3;\n            vec4 _1262 = fa_light_texel(param_23);\n            float _1263 = _1262.x;\n            float cos_inner = _1263;\n            if (_1263 > 1.5)\n            {\n                cos_inner = mix(_1257, 1.0, 0.25);\n            }\n            atten *= smoothstep(_1257, cos_inner, dot(-l, normalize(_1247.xyz)));\n        }\n        if (_1007 && (_1019 < 1.5))\n        {\n            int param_24 = _1003 + 6;\n            vec4 _1287 = fa_light_texel(param_24);\n            if (_1287.z > 0.5)\n            {\n                vec3 _1295 = -to_light;\n                int param_25 = _1003 + 4;\n                int param_26 = _1003 + 5;\n                vec3 _1309 = fa_light_texel(param_25).xyz;\n                vec3 _1313 = fa_light_texel(param_26).xyz;\n                vec3 _1322 = vec3(dot(_1295, _1309), dot(_1295, _1313), dot(_1295, cross(_1309, _1313)));\n                vec3 param_27 = _1322;\n                int _1326 = fa_cube_face(param_27);\n                int param_28 = _1326;\n                vec3 param_29;\n                vec3 param_30;\n                fa_cube_face_basis(param_28, param_29, param_30);\n                vec2 _1353 = vec2(dot(_1322, cross(param_29, param_30)), dot(_1322, param_30)) / vec2(max(dot(_1322, param_29), 9.9999997473787516355514526367188e-05));\n                int _1357 = _1326 / 3;\n                vec2 param_31 = _1287.xy + (vec2(float(_1326 - (_1357 * 3)), float(_1357)) * 256.0);\n                vec2 param_32 = vec2(0.5 + (0.5 * _1353.x), 0.5 - (0.5 * _1353.y));\n                fa_light_tint = fa_cookie_sample(param_31, param_32);\n            }\n            int param_33 = _1003 + 7;\n            vec4 _1387 = fa_light_texel(param_33);\n            if (_1387.z > 0.5)\n            {\n                int param_34 = _1003 + 2;\n                int param_35 = _1003 + 4;\n                int param_36 = _1003 + 5;\n                vec2 param_37 = _1387.xy;\n                vec3 param_38 = -l;\n                vec3 param_39 = normalize(fa_light_texel(param_34).xyz);\n                vec3 param_40 = fa_light_texel(param_35).xyz;\n                vec3 param_41 = fa_light_texel(param_36).xyz;\n                atten *= fa_ies_sample(param_37, param_38, param_39, param_40, param_41);\n            }\n        }\n        else\n        {\n            if (_1007 && _1239)\n            {\n                int param_42 = _1003 + 6;\n                vec4 _1434 = fa_light_texel(param_42);\n                int param_43 = _1003 + 7;\n                vec4 _1439 = fa_light_texel(param_43);\n                bool _1442 = _1434.z > 0.5;\n                bool _1449;\n                if (!_1442)\n                {\n                    _1449 = _1439.z > 0.5;\n                }\n                else\n                {\n                    _1449 = _1442;\n                }\n                if (_1449)\n                {\n                    int param_44 = _1003 + 2;\n                    vec4 _1456 = fa_light_texel(param_44);\n                    vec3 _1460 = normalize(_1456.xyz);\n                    int param_45 = _1003 + 4;\n                    vec4 _1465 = fa_light_texel(param_45);\n                    int param_46 = _1003 + 5;\n                    vec4 _1470 = fa_light_texel(param_46);\n                    if (_1442)\n                    {\n                        vec3 _1478 = -to_light;\n                        float _1485 = _1456.w;\n                        float _1501 = 0.5 / max(dot(_1478, _1460) * (sqrt(max(1.0 - (_1485 * _1485), 0.0)) / max(_1485, 0.001000000047497451305389404296875)), 9.9999997473787516355514526367188e-05);\n                        vec2 param_47 = _1434.xy;\n                        vec2 param_48 = vec2(0.5 + (dot(_1478, _1465.xyz) * _1501), 0.5 - (dot(_1478, _1470.xyz) * _1501));\n                        fa_light_tint = fa_cookie_sample(param_47, param_48);\n                    }\n                    if (_1439.z > 0.5)\n                    {\n                        vec2 param_49 = _1439.xy;\n                        vec3 param_50 = -l;\n                        vec3 param_51 = _1460;\n                        vec3 param_52 = _1465.xyz;\n                        vec3 param_53 = _1470.xyz;\n                        atten *= fa_ies_sample(param_49, param_50, param_51, param_52, param_53);\n                    }\n                }\n            }\n        }\n    }\n    vec3 _9141 = _1016.xyz * atten;\n    if (_1007)\n    {\n        _9141 *= fa_light_tint;\n    }\n    int _1570;\n    if (_1033)\n    {\n        _1570 = 0;\n    }\n    else\n    {\n        _1570 = ((_1019 > 1.5) && (_1019 < 2.5)) ? 2 : 1;\n    }\n    return LightSample(l, _9141, atten, 1.0, dist, _1570);\n}\n\nfloat fa_shadow_split_at(int i)\n{\n    float _2302;\n    if (i == 0)\n    {\n        _2302 = fa_shadows[24].x;\n    }\n    else\n    {\n        float _2318;\n        if (i == 1)\n        {\n            _2318 = fa_shadows[24].y;\n        }\n        else\n        {\n            float _2326;\n            if (i == 2)\n            {\n                _2326 = fa_shadows[24].z;\n            }\n            else\n            {\n                _2326 = fa_shadows[24].w;\n            }\n            _2318 = _2326;\n        }\n        _2302 = _2318;\n    }\n    return _2302;\n}\n\nfloat fa_shadow_depth(inout vec2 uv, vec4 rect)\n{\n    uv = clamp(uv, rect.xy, rect.zw);\n    return textureLod(fa_shadow_tex_fa_shadow_smp, uv, 0.0).x;\n}\n\nfloat fa_shadow_fetch(vec2 uv, vec4 rect, vec3 conv)\n{\n    vec2 param = uv;\n    vec4 param_1 = rect;\n    float _2359 = fa_shadow_depth(param, param_1);\n    float _2363;\n    if (conv.x < 0.5)\n    {\n        _2363 = _2359;\n    }\n    else\n    {\n        _2363 = (conv.y * conv.z) / (conv.z - (_2359 * (conv.z - conv.y)));\n    }\n    return _2363;\n}\n\nfloat fa_shadow_noise()\n{\n    return fract(52.98291778564453125 * fract(dot(gl_FragCoord.xy, vec2(0.067110560834407806396484375, 0.005837149918079376220703125))));\n}\n\nvec2 fa_shadow_vogel_turn(vec2 d)\n{\n    return vec2((d.x * (-0.737368881702423095703125)) - (d.y * 0.675490319728851318359375), (d.y * (-0.737368881702423095703125)) + (d.x * 0.675490319728851318359375));\n}\n\nfloat fa_shadow_filter(vec2 uv, vec4 rect, float zr, float texel_m, float unit, float reach, float plane, vec3 conv, int mode, float k)\n{\n    if (mode == 1)\n    {\n        vec2 param = uv;\n        vec4 param_1 = rect;\n        vec3 param_2 = conv;\n        return float(zr <= fa_shadow_fetch(param, param_1, param_2));\n    }\n    float _2409 = fa_shadow_noise() * 6.283185482025146484375;\n    vec2 _2415 = vec2(cos(_2409), sin(_2409));\n    vec2 dir = _2415;\n    float radius = 1.5;\n    if (mode == 2)\n    {\n        float _2424;\n        if (k < 0.0)\n        {\n            _2424 = (-k) / max(zr, 0.100000001490116119384765625);\n        }\n        else\n        {\n            _2424 = k;\n        }\n        float _2443 = clamp((_2424 * reach) / texel_m, 3.0, 12.0);\n        float sum = 0.0;\n        float cnt = 0.0;\n        for (int i = 0; i < 16; i++)\n        {\n            float _2462 = sqrt((float(i) + 0.5) * 0.0625) * _2443;\n            vec2 param_3 = uv + (dir * (fa_shadows[26].zw * _2462));\n            vec4 param_4 = rect;\n            vec3 param_5 = conv;\n            float _2476 = fa_shadow_fetch(param_3, param_4, param_5);\n            if (_2476 < (zr - (_2462 * plane)))\n            {\n                sum += _2476;\n                cnt += 1.0;\n            }\n            vec2 param_6 = dir;\n            dir = fa_shadow_vogel_turn(param_6);\n        }\n        if (cnt < 0.5)\n        {\n            return 1.0;\n        }\n        float _2504 = sum / cnt;\n        float _2514;\n        if (k < 0.0)\n        {\n            _2514 = (-k) / max(_2504, 0.0500000007450580596923828125);\n        }\n        else\n        {\n            _2514 = k;\n        }\n        radius = clamp(((max(zr - _2504, 0.0) * unit) * _2514) / texel_m, 1.5, 16.0);\n        dir = _2415;\n    }\n    float lit = 0.0;\n    int _2540 = (mode == 2) ? 24 : 16;\n    for (int i_1 = 0; i_1 < _2540; i_1++)\n    {\n        float _2559 = sqrt((float(i_1) + 0.5) / float(_2540)) * radius;\n        vec2 param_7 = uv + (dir * (fa_shadows[26].zw * _2559));\n        vec4 param_8 = rect;\n        vec3 param_9 = conv;\n        lit += float((zr - (_2559 * plane)) <= fa_shadow_fetch(param_7, param_8, param_9));\n        vec2 param_10 = dir;\n        dir = fa_shadow_vogel_turn(param_10);\n    }\n    return lit / float(_2540);\n}\n\nfloat fa_shadow_cascade(int ci, vec3 world, vec3 n, vec3 l)\n{\n    float _2605 = max(fa_shadows[ci * 1 + 20].y, 0.001000000047497451305389404296875);\n    float _2610 = clamp(dot(n, l), 0.0, 1.0);\n    float _2616 = sqrt(1.0 - (_2610 * _2610));\n    float _2624 = min(_2616 / max(_2610, 0.20000000298023223876953125), 4.0);\n    float _2629;\n    if (fa_shadows[26].y > 0.0)\n    {\n        _2629 = fa_shadows[26].y;\n    }\n    else\n    {\n        _2629 = 1.5 * fa_shadows[ci * 1 + 20].x;\n    }\n    vec4 _2654 = mat4(fa_shadows[ci * 4 + 0], fa_shadows[ci * 4 + 1], fa_shadows[ci * 4 + 2], fa_shadows[ci * 4 + 3]) * vec4(world + (n * (_2629 * _2616)), 1.0);\n    float _2661 = _2654.x;\n    bool _2664 = _2661 < fa_shadows[ci * 1 + 16].x;\n    bool _2673;\n    if (!_2664)\n    {\n        _2673 = _2661 > fa_shadows[ci * 1 + 16].z;\n    }\n    else\n    {\n        _2673 = _2664;\n    }\n    bool _2682;\n    if (!_2673)\n    {\n        _2682 = _2654.y < fa_shadows[ci * 1 + 16].y;\n    }\n    else\n    {\n        _2682 = _2673;\n    }\n    bool _2691;\n    if (!_2682)\n    {\n        _2691 = _2654.y > fa_shadows[ci * 1 + 16].w;\n    }\n    else\n    {\n        _2691 = _2682;\n    }\n    bool _2698;\n    if (!_2691)\n    {\n        _2698 = _2654.z > 1.0;\n    }\n    else\n    {\n        _2698 = _2691;\n    }\n    if (_2698)\n    {\n        return -1.0;\n    }\n    float _2706;\n    if (fa_shadows[26].x > 0.0)\n    {\n        _2706 = fa_shadows[26].x;\n    }\n    else\n    {\n        _2706 = 1.5 * fa_shadows[ci * 1 + 20].x;\n    }\n    vec2 param = _2654.xy;\n    vec4 param_1 = fa_shadows[ci * 1 + 16];\n    float param_2 = _2654.z - ((_2706 * (1.0 + (0.5 * _2624))) / _2605);\n    float param_3 = fa_shadows[ci * 1 + 20].x;\n    float param_4 = _2605;\n    float param_5 = _2605 * 0.25;\n    float param_6 = ((fa_shadows[ci * 1 + 20].x * min(_2624, 3.0)) * 0.5) / _2605;\n    vec3 param_7 = vec3(0.0);\n    int param_8 = int(fa_shadows[25].z + 0.5);\n    float param_9 = fa_shadows[25].w;\n    return fa_shadow_filter(param, param_1, param_2, param_3, param_4, param_5, param_6, param_7, param_8, param_9);\n}\n\nfloat fa_shadow_sun(vec3 world, vec3 n, vec3 l)\n{\n    if (fa_mesh_fs_params[5].z < 0.5)\n    {\n        return 1.0;\n    }\n    int _3084 = int(fa_shadows[25].x + 0.5);\n    if (_3084 < 1)\n    {\n        return 1.0;\n    }\n    float _3099 = dot(world - fa_shadows[27].xyz, fa_shadows[28].xyz);\n    int param = _3084 - 1;\n    if (_3099 > fa_shadow_split_at(param))\n    {\n        return 1.0;\n    }\n    int ci = 0;\n    bool _3111 = _3084 > 1;\n    bool _3118;\n    if (_3111)\n    {\n        _3118 = _3099 > fa_shadows[24].x;\n    }\n    else\n    {\n        _3118 = _3111;\n    }\n    if (_3118)\n    {\n        ci = 1;\n    }\n    bool _3122 = _3084 > 2;\n    bool _3129;\n    if (_3122)\n    {\n        _3129 = _3099 > fa_shadows[24].y;\n    }\n    else\n    {\n        _3129 = _3122;\n    }\n    if (_3129)\n    {\n        ci = 2;\n    }\n    bool _3133 = _3084 > 3;\n    bool _3140;\n    if (_3133)\n    {\n        _3140 = _3099 > fa_shadows[24].z;\n    }\n    else\n    {\n        _3140 = _3133;\n    }\n    if (_3140)\n    {\n        ci = 3;\n    }\n    float s = -1.0;\n    float s2 = -1.0;\n    float t = 0.0;\n    int _3151 = min(_3084, 4);\n    float _3192;\n    for (int c = ci; c < _3151; c++)\n    {\n        int param_1 = c;\n        vec3 param_2 = world;\n        vec3 param_3 = n;\n        vec3 param_4 = l;\n        float _3171 = fa_shadow_cascade(param_1, param_2, param_3, param_4);\n        if (s >= 0.0)\n        {\n            s2 = _3171;\n            break;\n        }\n        if (_3171 < 0.0)\n        {\n            continue;\n        }\n        s = _3171;\n        ci = c;\n        if (fa_shadows[25].y > 0.0)\n        {\n            if (ci > 0)\n            {\n                int param_5 = ci - 1;\n                _3192 = fa_shadow_split_at(param_5);\n            }\n            else\n            {\n                _3192 = fa_shadows[28].w;\n            }\n            int param_6 = ci;\n            float _3211 = fa_shadows[25].y * max(fa_shadow_split_at(param_6) - _3192, 9.9999997473787516355514526367188e-05);\n            int param_7 = ci;\n            t = clamp((_3099 - (fa_shadow_split_at(param_7) - _3211)) / _3211, 0.0, 1.0);\n        }\n        if (t <= 0.0)\n        {\n            break;\n        }\n    }\n    if (s < 0.0)\n    {\n        return 1.0;\n    }\n    if (t > 0.0)\n    {\n        float _3243;\n        if ((ci + 1) < _3084)\n        {\n            _3243 = (s2 < 0.0) ? s : s2;\n        }\n        else\n        {\n            _3243 = 1.0;\n        }\n        s = mix(s, _3243, t);\n    }\n    return s;\n}\n\nfloat fa_shadow_factor(vec3 n, vec3 l)\n{\n    bool _3348 = fa_mesh_fs_params[25].y > 0.5;\n    bool _3354;\n    if (_3348)\n    {\n        _3354 = fa_mesh_fs_params[5].z > 0.5;\n    }\n    else\n    {\n        _3354 = _3348;\n    }\n    if (_3354)\n    {\n        vec4 _3364 = vec4(fa_world_pos, 1.0);\n        float _3370 = dot(fa_mesh_fs_params[28], _3364);\n        if (_3370 > 9.9999997473787516355514526367188e-05)\n        {\n            vec2 _3389 = vec2(dot(fa_mesh_fs_params[26], _3364), dot(fa_mesh_fs_params[27], _3364)) / vec2(_3370);\n            float _3394 = (_3389.x * 0.5) + 0.5;\n            float _3398;\n            if (fa_mesh_fs_params[24].y > 0.5)\n            {\n                _3398 = (_3389.y * 0.5) + 0.5;\n            }\n            else\n            {\n                _3398 = 0.5 - (_3389.y * 0.5);\n            }\n            bool _3414 = _3394 >= 0.0;\n            bool _3420;\n            if (_3414)\n            {\n                _3420 = _3394 < 1.0;\n            }\n            else\n            {\n                _3420 = _3414;\n            }\n            bool _3426;\n            if (_3420)\n            {\n                _3426 = _3398 >= 0.0;\n            }\n            else\n            {\n                _3426 = _3420;\n            }\n            bool _3432;\n            if (_3426)\n            {\n                _3432 = _3398 < 1.0;\n            }\n            else\n            {\n                _3432 = _3426;\n            }\n            if (_3432)\n            {\n                vec4 _3458 = texelFetch(fa_screen_tex_fa_shadow_smp, clamp(ivec2(vec2(_3394, _3398) * fa_mesh_fs_params[24].zw), ivec2(0), ivec2(fa_mesh_fs_params[24].zw) - ivec2(1)), 0);\n                float _3468 = dot(fa_mesh_fs_params[29].xyz, fa_world_pos) + fa_mesh_fs_params[29].w;\n                bool _3471 = _3458.w > 0.5;\n                bool _3485;\n                if (_3471)\n                {\n                    _3485 = abs(_3468 - _3458.x) <= ((0.00200000009499490261077880859375 * _3468) + 0.00999999977648258209228515625);\n                }\n                else\n                {\n                    _3485 = _3471;\n                }\n                if (_3485)\n                {\n                    return _3458.y;\n                }\n            }\n        }\n    }\n    vec3 param = fa_world_pos;\n    vec3 param_1 = n;\n    vec3 param_2 = l;\n    return fa_shadow_sun(param, param_1, param_2);\n}\n\nfloat fa_shadow_local(int li, vec3 lpos, vec3 world, vec3 n, vec3 l)\n{\n    bool _2764 = fa_mesh_fs_params[5].z < 0.5;\n    bool _2771;\n    if (!_2764)\n    {\n        _2771 = fa_shadows[29].x < 0.5;\n    }\n    else\n    {\n        _2771 = _2764;\n    }\n    if (_2771)\n    {\n        return 1.0;\n    }\n    int param = (int(fa_shadows[29].x + 0.5) - 1) + li;\n    vec4 _2784 = fa_light_texel(param);\n    float _2785 = _2784.x;\n    if (_2785 < 0.0)\n    {\n        return 1.0;\n    }\n    int _2794 = int(_2785 + 0.5);\n    int param_1 = _2794;\n    vec4 _2798 = fa_light_texel(param_1);\n    int param_2 = _2794 + 1;\n    vec4 _2803 = fa_light_texel(param_2);\n    float fade = 1.0;\n    float _2806 = _2798.y;\n    if (_2806 > 0.0)\n    {\n        float _2823 = 1.0 - smoothstep(0.75 * _2806, _2806, length(world - fa_shadows[27].xyz));\n        fade = _2823;\n        if (_2823 <= 0.0)\n        {\n            return 1.0;\n        }\n    }\n    int face = 0;\n    if (_2798.x > 1.5)\n    {\n        vec3 param_3 = world - lpos;\n        face = fa_cube_face(param_3);\n    }\n    int _2847 = (_2794 + 2) + (face * 6);\n    int param_4 = _2847;\n    int param_5 = _2847 + 1;\n    int param_6 = _2847 + 3;\n    vec4 _2861 = fa_light_texel(param_6);\n    int param_7 = _2847 + 4;\n    vec4 _2866 = fa_light_texel(param_7);\n    int param_8 = _2847 + 5;\n    vec4 _2871 = fa_light_texel(param_8);\n    float _2883 = _2871.x * max(dot(_2861, vec4(world, 1.0)), 0.001000000047497451305389404296875);\n    float _2888 = clamp(dot(n, l), 0.0, 1.0);\n    float _2911 = clamp(dot(n, _2861.xyz), -1.0, 1.0);\n    float _2930 = min(sqrt(1.0 - (_2911 * _2911)) / max(abs(dot(n, world - lpos)) / max(dot(_2861, vec4(world, 1.0)), 0.001000000047497451305389404296875), 0.20000000298023223876953125), 4.0);\n    float _2933 = _2803.y;\n    float _2935;\n    if (_2933 > 0.0)\n    {\n        _2935 = _2933;\n    }\n    else\n    {\n        _2935 = 1.5 * _2883;\n    }\n    vec4 _2955 = vec4(world + (n * (_2935 * sqrt(1.0 - (_2888 * _2888)))), 1.0);\n    float _2959 = dot(_2861, _2955);\n    float _2962 = _2871.y;\n    if (_2959 < _2962)\n    {\n        return 1.0;\n    }\n    vec2 _2977 = vec2(dot(fa_light_texel(param_4), _2955), dot(fa_light_texel(param_5), _2955)) / vec2(_2959);\n    float _2979 = _2977.x;\n    bool _2982 = _2979 < _2866.x;\n    bool _2991;\n    if (!_2982)\n    {\n        _2991 = _2979 > _2866.z;\n    }\n    else\n    {\n        _2991 = _2982;\n    }\n    bool _3000;\n    if (!_2991)\n    {\n        _3000 = _2977.y < _2866.y;\n    }\n    else\n    {\n        _3000 = _2991;\n    }\n    bool _3009;\n    if (!_3000)\n    {\n        _3009 = _2977.y > _2866.w;\n    }\n    else\n    {\n        _3009 = _3000;\n    }\n    if (_3009)\n    {\n        return 1.0;\n    }\n    float _3015 = _2803.x;\n    float _3017;\n    if (_3015 > 0.0)\n    {\n        _3017 = _3015;\n    }\n    else\n    {\n        _3017 = 1.5 * _2883;\n    }\n    vec2 param_9 = _2977;\n    vec4 param_10 = _2866;\n    float param_11 = _2959 - (_3017 * (1.0 + (0.5 * _2930)));\n    float param_12 = _2883;\n    float param_13 = 1.0;\n    float param_14 = _2871.z * 0.25;\n    float param_15 = (_2883 * min(_2930, 3.0)) * 0.5;\n    vec3 param_16 = vec3(1.0, _2962, _2871.z);\n    int param_17 = int(_2798.z + 0.5);\n    float param_18 = _2798.w;\n    return mix(1.0, fa_shadow_filter(param_9, param_10, param_11, param_12, param_13, param_14, param_15, param_16, param_17, param_18), fade);\n}\n\nfloat fa_contact_shadow(int li, vec3 world, vec3 gn, vec3 l, float dist)\n{\n    bool _5316 = fa_mesh_fs_params[24].x < 0.5;\n    bool _5323;\n    if (!_5316)\n    {\n        _5323 = fa_shadows[29].x < 0.5;\n    }\n    else\n    {\n        _5323 = _5316;\n    }\n    if (_5323)\n    {\n        return 1.0;\n    }\n    int param = (int(fa_shadows[29].x + 0.5) - 1) + li;\n    vec4 _5336 = fa_light_texel(param);\n    float _5337 = _5336.y;\n    float len = _5337;\n    if (_5337 <= 0.0)\n    {\n        return 1.0;\n    }\n    float _5349 = length(world - fa_mesh_fs_params[0].xyz);\n    float _5358 = 1.0 - smoothstep(0.5 * fa_mesh_fs_params[25].x, fa_mesh_fs_params[25].x, _5349);\n    if (_5358 <= 0.0)\n    {\n        return 1.0;\n    }\n    float _5364 = len;\n    float _5367 = min(_5364, 0.89999997615814208984375 * dist);\n    len = _5367;\n    float _5372 = 0.004999999888241291046142578125 + (0.0030000000260770320892333984375 * _5349);\n    float _5377 = _5372 + (0.5 * _5367);\n    vec3 _5383 = world + (gn * _5372);\n    float _5385 = fa_shadow_noise();\n    float occ = 0.0;\n    float _5446;\n    for (int k = 0; k < 12; k++)\n    {\n        float _5400 = (float(k) + _5385) * 0.083333335816860198974609375;\n        vec3 _5408 = _5383 + (l * (_5400 * len));\n        vec4 _5414 = vec4(_5408, 1.0);\n        float _5419 = dot(fa_mesh_fs_params[28], _5414);\n        if (_5419 < 9.9999997473787516355514526367188e-05)\n        {\n            break;\n        }\n        vec2 _5437 = vec2(dot(fa_mesh_fs_params[26], _5414), dot(fa_mesh_fs_params[27], _5414)) / vec2(_5419);\n        float _5441 = _5437.x * 0.5;\n        float _5442 = _5441 + 0.5;\n        if (fa_mesh_fs_params[24].y > 0.5)\n        {\n            _5446 = (_5437.y * 0.5) + 0.5;\n        }\n        else\n        {\n            _5446 = 0.5 - (_5437.y * 0.5);\n        }\n        bool _5462 = _5442 < 0.0;\n        bool _5469;\n        if (!_5462)\n        {\n            _5469 = _5442 >= 1.0;\n        }\n        else\n        {\n            _5469 = _5462;\n        }\n        bool _5476;\n        if (!_5469)\n        {\n            _5476 = _5446 < 0.0;\n        }\n        else\n        {\n            _5476 = _5469;\n        }\n        bool _5483;\n        if (!_5476)\n        {\n            _5483 = _5446 >= 1.0;\n        }\n        else\n        {\n            _5483 = _5476;\n        }\n        if (_5483)\n        {\n            break;\n        }\n        vec4 _5507 = texelFetch(fa_screen_tex_fa_shadow_smp, clamp(ivec2(vec2(_5442, _5446) * fa_mesh_fs_params[24].zw), ivec2(0), ivec2(fa_mesh_fs_params[24].zw) - ivec2(1)), 0);\n        if (_5507.w < 0.5)\n        {\n            continue;\n        }\n        float _5525 = (dot(fa_mesh_fs_params[29].xyz, _5408) + fa_mesh_fs_params[29].w) - _5507.x;\n        if ((_5525 > _5372) && (_5525 < _5377))\n        {\n            occ = max(occ, (1.0 - (_5400 * _5400)) * smoothstep(0.0, 0.0500000007450580596923828125, min(min(_5442, 0.5 - _5441), min(_5446, 1.0 - _5446))));\n        }\n    }\n    return 1.0 - (occ * _5358);\n}\n\nLightSample fa_light_shadowed(int li, vec3 world_pos, vec3 gn)\n{\n    int param = li;\n    float _5991 = fa_baked_keep(param);\n    if (_5991 <= 0.0)\n    {\n        int param_1 = li;\n        return LightSample(vec3(0.0, 1.0, 0.0), vec3(0.0), 0.0, 1.0, 0.0, int(fa_light_type(param_1) + 0.5));\n    }\n    int param_2 = li;\n    vec3 param_3 = world_pos;\n    vec3 param_4 = gn;\n    LightSample _6017 = fa_light_sample_n(param_2, param_3, param_4);\n    vec3 _9210 = _6017.color;\n    float _9211 = _6017.attenuation;\n    float _9212 = _6017.shadow;\n    bool _6020 = _6017.type == 0;\n    if (_6020 && (li == 0))\n    {\n        vec3 param_5 = gn;\n        vec3 param_6 = _6017.direction;\n        float _6031 = fa_shadow_factor(param_5, param_6);\n        _9212 = _6031;\n        _9210 *= _6031;\n    }\n    else\n    {\n        bool _6042 = _6017.type != 0;\n        bool _6048;\n        if (_6042)\n        {\n            _6048 = _9211 > 0.0;\n        }\n        else\n        {\n            _6048 = _6042;\n        }\n        if (_6048)\n        {\n            int param_7 = li;\n            int param_8 = fa_light_base(param_7);\n            int param_9 = li;\n            vec3 param_10 = fa_light_texel(param_8).xyz;\n            vec3 param_11 = world_pos;\n            vec3 param_12 = gn;\n            vec3 param_13 = _6017.direction;\n            float _6067 = fa_shadow_local(param_9, param_10, param_11, param_12, param_13);\n            _9212 = _6067;\n            _9210 *= _6067;\n        }\n    }\n    bool _6077 = fa_mesh_fs_params[24].x > 0.5;\n    bool _6083;\n    if (_6077)\n    {\n        _6083 = _9211 > 0.0;\n    }\n    else\n    {\n        _6083 = _6077;\n    }\n    if (_6083)\n    {\n        float _6090;\n        if (_6020)\n        {\n            _6090 = 1000000000.0;\n        }\n        else\n        {\n            _6090 = _6017._distance;\n        }\n        int param_14 = li;\n        vec3 param_15 = world_pos;\n        vec3 param_16 = gn;\n        vec3 param_17 = _6017.direction;\n        float param_18 = _6090;\n        float _6108 = fa_contact_shadow(param_14, param_15, param_16, param_17, param_18);\n        _9212 *= _6108;\n        _9210 *= _6108;\n    }\n    float _6121 = _9211;\n    float _6122 = _6121 * _5991;\n    _9211 = _6122;\n    vec3 _6126 = _9210;\n    vec3 _6127 = _6126 * _5991;\n    _9210 = _6127;\n    return LightSample(_6017.direction, _6127, _6122, _9212, _6017._distance, _6017.type);\n}\n\nvec3 fa_ltc_tangent(vec3 n, vec3 v)\n{\n    vec3 _6161 = v - (n * dot(v, n));\n    vec3 t = _6161;\n    float _6165 = dot(_6161, _6161);\n    float l2 = _6165;\n    if (_6165 < 1.0000000133514319600180897396058e-10)\n    {\n        vec3 _6175;\n        if (abs(n.z) < 0.999000012874603271484375)\n        {\n            _6175 = cross(n, vec3(0.0, 0.0, 1.0));\n        }\n        else\n        {\n            _6175 = cross(n, vec3(1.0, 0.0, 0.0));\n        }\n        t = _6175;\n        l2 = dot(_6175, _6175);\n    }\n    return t * inversesqrt(l2);\n}\n\nvec3 fa_ltc_local(vec3 t1, vec3 n, vec3 p)\n{\n    return vec3(dot(t1, p), dot(cross(n, t1), p), dot(n, p));\n}\n\nvec2 fa_ltc_uv(float roughness, float ndv)\n{\n    return ((vec2(clamp((roughness - 0.0500000007450580596923828125) * 1.0526316165924072265625, 0.0, 1.0), sqrt(clamp(1.0 - ndv, 0.0, 1.0))) * 63.0) + vec2(0.5)) * vec2(0.015625);\n}\n\nvec3 fa_oct_vertex(int j, vec3 pc, vec3 ex, vec3 ey)\n{\n    float _6562;\n    if ((j == 0) || (j == 7))\n    {\n        _6562 = 0.92387950420379638671875;\n    }\n    else\n    {\n        float _6572;\n        if ((j == 3) || (j == 4))\n        {\n            _6572 = -0.92387950420379638671875;\n        }\n        else\n        {\n            _6572 = ((j == 1) || (j == 6)) ? 0.3826834261417388916015625 : (-0.3826834261417388916015625);\n        }\n        _6562 = _6572;\n    }\n    float _6593;\n    if ((j == 1) || (j == 2))\n    {\n        _6593 = 0.92387950420379638671875;\n    }\n    else\n    {\n        float _6602;\n        if ((j == 5) || (j == 6))\n        {\n            _6602 = -0.92387950420379638671875;\n        }\n        else\n        {\n            _6602 = ((j == 0) || (j == 3)) ? 0.3826834261417388916015625 : (-0.3826834261417388916015625);\n        }\n        _6593 = _6602;\n    }\n    return (pc + (ex * _6562)) + (ey * _6593);\n}\n\nvec3 fa_ltc_edge_vector(vec3 a, vec3 b)\n{\n    float _6210 = dot(a, a);\n    float _6214 = dot(b, b);\n    if ((_6210 < 1.0000000195414813782625560981111e-24) || (_6214 < 1.0000000195414813782625560981111e-24))\n    {\n        return vec3(0.0);\n    }\n    vec3 _6228 = a * inversesqrt(_6210);\n    vec3 _6233 = b * inversesqrt(_6214);\n    float _6237 = dot(_6228, _6233);\n    float _6240 = abs(_6237);\n    float g = (((((((((((0.0416471660137176513671875 * _6240) - 0.1924748718738555908203125) * _6240) + 0.4179156124591827392578125) * _6240) - 0.616057217121124267578125) * _6240) + 0.777722418308258056640625) * _6240) - 0.999542415142059326171875) * _6240) + 1.570791721343994140625;\n    if (_6237 < 0.0)\n    {\n        g = (3.1415927410125732421875 * inversesqrt(max(1.0 - (_6237 * _6237), 1.0000000116860974230803549289703e-07))) - g;\n    }\n    return cross(_6228, _6233) * g;\n}\n\nvoid fa_ltc_clip_edge(vec3 a, vec3 b, inout vec3 sum, inout vec3 leave, inout vec3 enter, inout vec2 seen)\n{\n    bool _6297 = a.z > 0.0;\n    bool _6301 = b.z > 0.0;\n    if (_6297 && _6301)\n    {\n        vec3 param = a;\n        vec3 param_1 = b;\n        sum += fa_ltc_edge_vector(param, param_1);\n    }\n    else\n    {\n        if (_6297 != _6301)\n        {\n            vec3 _6336 = a + ((b - a) * (a.z / (a.z - b.z)));\n            _6336.z = 0.0;\n            if (_6297)\n            {\n                vec3 param_2 = a;\n                vec3 param_3 = _6336;\n                sum += fa_ltc_edge_vector(param_2, param_3);\n                leave = _6336;\n                seen.x = 1.0;\n            }\n            else\n            {\n                vec3 param_4 = _6336;\n                vec3 param_5 = b;\n                sum += fa_ltc_edge_vector(param_4, param_5);\n                enter = _6336;\n                seen.y = 1.0;\n            }\n        }\n    }\n}\n\nfloat fa_ltc_quad(vec4 abcd, vec3 p0, vec3 p1, vec3 p2, vec3 p3)\n{\n    vec3 _6385 = vec3((abcd.x * p0.x) + (abcd.y * p0.z), p0.y, (abcd.z * p0.x) + (abcd.w * p0.z));\n    vec3 _6411 = vec3((abcd.x * p1.x) + (abcd.y * p1.z), p1.y, (abcd.z * p1.x) + (abcd.w * p1.z));\n    vec3 _6437 = vec3((abcd.x * p2.x) + (abcd.y * p2.z), p2.y, (abcd.z * p2.x) + (abcd.w * p2.z));\n    vec3 _6463 = vec3((abcd.x * p3.x) + (abcd.y * p3.z), p3.y, (abcd.z * p3.x) + (abcd.w * p3.z));\n    vec3 sum = vec3(0.0);\n    vec3 leave = vec3(0.0);\n    vec3 enter = vec3(0.0);\n    vec3 param = _6385;\n    vec3 param_1 = _6411;\n    vec3 param_2 = vec3(0.0);\n    vec3 param_3 = vec3(0.0);\n    vec3 param_4 = vec3(0.0);\n    vec2 param_5 = vec2(0.0);\n    fa_ltc_clip_edge(param, param_1, param_2, param_3, param_4, param_5);\n    sum = param_2;\n    leave = param_3;\n    enter = param_4;\n    vec3 param_6 = _6411;\n    vec3 param_7 = _6437;\n    vec3 param_8 = param_2;\n    vec3 param_9 = param_3;\n    vec3 param_10 = param_4;\n    vec2 param_11 = param_5;\n    fa_ltc_clip_edge(param_6, param_7, param_8, param_9, param_10, param_11);\n    sum = param_8;\n    leave = param_9;\n    enter = param_10;\n    vec3 param_12 = _6437;\n    vec3 param_13 = _6463;\n    vec3 param_14 = param_8;\n    vec3 param_15 = param_9;\n    vec3 param_16 = param_10;\n    vec2 param_17 = param_11;\n    fa_ltc_clip_edge(param_12, param_13, param_14, param_15, param_16, param_17);\n    sum = param_14;\n    leave = param_15;\n    enter = param_16;\n    vec3 param_18 = _6463;\n    vec3 param_19 = _6385;\n    vec3 param_20 = param_14;\n    vec3 param_21 = param_15;\n    vec3 param_22 = param_16;\n    vec2 param_23 = param_17;\n    fa_ltc_clip_edge(param_18, param_19, param_20, param_21, param_22, param_23);\n    sum = param_20;\n    leave = param_21;\n    enter = param_22;\n    if ((param_23.x * param_23.y) > 0.5)\n    {\n        vec3 param_24 = leave;\n        vec3 param_25 = enter;\n        sum += fa_ltc_edge_vector(param_24, param_25);\n    }\n    return sum.z * 0.15915493667125701904296875;\n}\n\nvec2 fa_area_forms(vec4 m, float shape, vec3 pc, vec3 ex, vec3 ey)\n{\n    int _6631 = ((shape < 0.5) || (shape > 1.5)) ? 1 : 3;\n    vec2 sum = vec2(0.0);\n    int _6649;\n    for (int k = 0; k < (2 * _6631); k++)\n    {\n        bool _6646 = k >= _6631;\n        if (_6646)\n        {\n            _6649 = k - _6631;\n        }\n        else\n        {\n            _6649 = k;\n        }\n        vec3 p0 = (pc - ex) - ey;\n        vec3 p1 = (pc + ex) - ey;\n        vec3 p2 = (pc + ex) + ey;\n        vec3 p3 = (pc - ex) + ey;\n        if (_6631 == 3)\n        {\n            int param = 0;\n            vec3 param_1 = pc;\n            vec3 param_2 = ex;\n            vec3 param_3 = ey;\n            p0 = fa_oct_vertex(param, param_1, param_2, param_3);\n            int _6695 = 2 * _6649;\n            int param_4 = _6695 + 1;\n            vec3 param_5 = pc;\n            vec3 param_6 = ex;\n            vec3 param_7 = ey;\n            p1 = fa_oct_vertex(param_4, param_5, param_6, param_7);\n            int param_8 = _6695 + 2;\n            vec3 param_9 = pc;\n            vec3 param_10 = ex;\n            vec3 param_11 = ey;\n            p2 = fa_oct_vertex(param_8, param_9, param_10, param_11);\n            int param_12 = _6695 + 3;\n            vec3 param_13 = pc;\n            vec3 param_14 = ex;\n            vec3 param_15 = ey;\n            p3 = fa_oct_vertex(param_12, param_13, param_14, param_15);\n        }\n        bvec4 _6732 = bvec4(_6646);\n        vec4 param_16 = vec4(_6732.x ? m.x : vec4(1.0, 0.0, 0.0, 1.0).x, _6732.y ? m.y : vec4(1.0, 0.0, 0.0, 1.0).y, _6732.z ? m.z : vec4(1.0, 0.0, 0.0, 1.0).z, _6732.w ? m.w : vec4(1.0, 0.0, 0.0, 1.0).w);\n        vec3 param_17 = p0;\n        vec3 param_18 = p1;\n        vec3 param_19 = p2;\n        vec3 param_20 = p3;\n        float _6743 = fa_ltc_quad(param_16, param_17, param_18, param_19, param_20);\n        if (_6646)\n        {\n            vec2 _9447 = sum;\n            _9447.y = _9447.y + _6743;\n            sum = _9447;\n        }\n        else\n        {\n            vec2 _9450 = sum;\n            _9450.x = _9450.x + _6743;\n            sum = _9450;\n        }\n    }\n    return abs(sum);\n}\n\nvec3 fa_area_shade(int li, vec3 world_pos, vec3 n, vec3 v, vec3 diffuse_color, vec3 f0, float f90, float roughness, float ndv, float window)\n{\n    int param = li;\n    int _6767 = fa_light_base(param);\n    int param_1 = _6767;\n    int param_2 = _6767 + 1;\n    int param_3 = _6767 + 2;\n    int param_4 = _6767 + 4;\n    vec4 _6789 = fa_light_texel(param_4);\n    int param_5 = _6767 + 5;\n    vec4 _6794 = fa_light_texel(param_5);\n    int param_6 = _6767 + 6;\n    vec4 _6799 = fa_light_texel(param_6);\n    float _6800 = _6799.w;\n    vec3 _6805 = fa_light_texel(param_1).xyz - world_pos;\n    bool _6807 = _6800 < 1.5;\n    bool _6814;\n    if (_6807)\n    {\n        _6814 = dot(normalize(fa_light_texel(param_3).xyz), _6805) >= 0.0;\n    }\n    else\n    {\n        _6814 = _6807;\n    }\n    if (_6814)\n    {\n        return vec3(0.0);\n    }\n    bool _6823 = (_6800 > 0.5) && _6807;\n    float _6827 = _6823 ? 1.0539000034332275390625 : 1.0;\n    vec3 _6830 = _6789.xyz;\n    float _6832 = _6789.w;\n    vec3 _6838 = _6794.xyz;\n    float _6840 = _6794.w;\n    vec3 up = _6838 * (_6840 * _6827);\n    float _6846;\n    if (_6823)\n    {\n        _6846 = (3.1415927410125732421875 * _6832) * _6832;\n    }\n    else\n    {\n        _6846 = (4.0 * _6832) * _6840;\n    }\n    if (_6800 > 1.5)\n    {\n        vec3 _6872 = cross(_6830, -_6805);\n        vec3 perp = _6872;\n        float _6876 = dot(_6872, _6872);\n        vec3 _6879;\n        if (_6876 > 1.0000000133514319600180897396058e-10)\n        {\n            _6879 = perp * inversesqrt(_6876);\n        }\n        else\n        {\n            _6879 = _6838;\n        }\n        perp = _6879;\n        up = _6879 * _6840;\n    }\n    float _6900 = max(_6846, 9.9999999747524270787835121154785e-07);\n    vec3 param_7 = n;\n    vec3 param_8 = v;\n    vec3 _6910 = fa_ltc_tangent(param_7, param_8);\n    vec3 param_9 = _6910;\n    vec3 param_10 = n;\n    vec3 param_11 = _6805;\n    vec3 param_12 = _6910;\n    vec3 param_13 = n;\n    vec3 param_14 = _6830 * (_6832 * _6827);\n    vec3 param_15 = _6910;\n    vec3 param_16 = n;\n    vec3 param_17 = up;\n    float param_18 = roughness;\n    float param_19 = ndv;\n    vec2 _6941 = fa_ltc_uv(param_18, param_19) * 64.0;\n    vec2 param_20 = _6941;\n    vec2 param_21 = _6941 + vec2(64.0, 0.0);\n    vec4 _6951 = fa_atlas_fetch(param_21);\n    vec4 param_22 = fa_atlas_fetch(param_20);\n    float param_23 = _6800;\n    vec3 param_24 = fa_ltc_local(param_9, param_10, param_11);\n    vec3 param_25 = fa_ltc_local(param_12, param_13, param_14);\n    vec3 param_26 = fa_ltc_local(param_15, param_16, param_17);\n    vec2 _6963 = fa_area_forms(param_22, param_23, param_24, param_25, param_26);\n    return (((diffuse_color * _6963.x) + (((f0 * _6951.x) + ((vec3(f90) - f0) * _6951.y)) * _6963.y)) * fa_light_texel(param_2).xyz) * ((((3.1415927410125732421875 * dot(_6805, _6805)) + _6900) / _6900) * window);\n}\n\nvec3 fa_light_rgb(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 1;\n    return fa_light_texel(param_1).xyz;\n}\n\nfloat fa_d_charlie(float alpha, float ndh)\n{\n    float _5053 = 1.0 / alpha;\n    return ((2.0 + _5053) * pow(sqrt(max(1.0 - (ndh * ndh), 9.9999997473787516355514526367188e-05)), _5053)) * 0.15915493667125701904296875;\n}\n\nfloat fa_v_ashikhmin(float ndl, float ndv)\n{\n    return clamp(0.25 / max((ndl + ndv) - (ndl * ndv), 9.9999997473787516355514526367188e-05), 0.0, 1.0);\n}\n\nfloat fa_layers_coat(FaLayers L, vec3 l, vec3 h, float vdh)\n{\n    float _5088 = max(dot(L.nc, l), 0.0);\n    float _5094 = max(dot(L.nc, h), 0.0);\n    float _5103 = ((_5094 * _5094) * (L.coat_a2 - 1.0)) + 1.0;\n    return (((L.coat * (0.039999999105930328369140625 + (0.959999978542327880859375 * pow(clamp(1.0 - vdh, 0.0, 1.0), 5.0)))) * (((L.coat_a2 / ((3.1415927410125732421875 * _5103) * _5103)) * (0.5 / max(mix((2.0 * _5088) * L.coat_ndv, _5088 + L.coat_ndv, L.coat_alpha), 9.9999997473787516355514526367188e-05))) * 3.1415927410125732421875)) * step(9.9999997473787516355514526367188e-05, _5088)) * _5088;\n}\n\nvec3 fa_area_layers(FaLayers L, vec3 base, int li, vec3 n, vec3 v, vec3 l, float ndv, float window)\n{\n    float _7000;\n    if (L.sheen_on)\n    {\n        _7000 = L.sheen_scale;\n    }\n    else\n    {\n        _7000 = 1.0;\n    }\n    vec3 result = base * (L.keep * _7000);\n    vec3 _7013 = normalize(l + v);\n    int param = li;\n    vec3 _7024 = fa_light_rgb(param) * window;\n    if (L.sheen_on)\n    {\n        float _7033 = max(dot(n, l), 0.0);\n        float param_1 = L.sheen_alpha;\n        float param_2 = max(dot(n, _7013), 0.0);\n        float param_3 = _7033;\n        float param_4 = ndv;\n        result += ((L.sheen * _7024) * (((((fa_d_charlie(param_1, param_2) * fa_v_ashikhmin(param_3, param_4)) * 3.1415927410125732421875) * step(9.9999997473787516355514526367188e-05, _7033)) * _7033) * L.keep));\n    }\n    if (L.coat > 0.0)\n    {\n        FaLayers param_5 = L;\n        vec3 param_6 = l;\n        vec3 param_7 = _7013;\n        float param_8 = max(dot(v, _7013), 0.0);\n        result += (_7024 * fa_layers_coat(param_5, param_6, param_7, param_8));\n    }\n    return result;\n}\n\nfloat fa_d_ggx_aniso(float ndh, float tdh, float bdh, float at, float ab)\n{\n    float _4956 = tdh / at;\n    float _4960 = bdh / ab;\n    float _4972 = ((_4956 * _4956) + (_4960 * _4960)) + (ndh * ndh);\n    return 1.0 / ((((3.1415927410125732421875 * at) * ab) * _4972) * _4972);\n}\n\nfloat fa_lambda_ggx_aniso(float n, float t, float b, float at, float ab)\n{\n    return 0.5 * (sqrt(1.0 + (((((at * at) * t) * t) + (((ab * ab) * b) * b)) / max(n * n, 9.9999999392252902907785028219223e-09))) - 1.0);\n}\n\nfloat fa_v_ggx_aniso(float ndl, float ndv, float tdv, float bdv, float tdl, float bdl, float at, float ab)\n{\n    float param = ndv;\n    float param_1 = tdv;\n    float param_2 = bdv;\n    float param_3 = at;\n    float param_4 = ab;\n    float param_5 = ndl;\n    float param_6 = tdl;\n    float param_7 = bdl;\n    float param_8 = at;\n    float param_9 = ab;\n    return clamp(1.0 / ((4.0 * max(ndl * ndv, 9.9999997473787516355514526367188e-05)) * ((1.0 + fa_lambda_ggx_aniso(param, param_1, param_2, param_3, param_4)) + fa_lambda_ggx_aniso(param_5, param_6, param_7, param_8, param_9))), 0.0, 1.0);\n}\n\nvec3 fa_layers_light(FaLayers L, vec3 diffuse_color, vec3 f0, vec3 n, vec3 v, vec3 l, vec3 h, float ndl, float ndv, float ndh, float vdh, float alpha, float a2)\n{\n    float _5152 = step(9.9999997473787516355514526367188e-05, ndl);\n    float d_ggx;\n    float vis;\n    if (L.aniso != 0.0)\n    {\n        float param = ndh;\n        float param_1 = dot(L.t, h);\n        float param_2 = dot(L.b, h);\n        float param_3 = L.at;\n        float param_4 = L.ab;\n        d_ggx = fa_d_ggx_aniso(param, param_1, param_2, param_3, param_4);\n        float param_5 = ndl;\n        float param_6 = ndv;\n        float param_7 = dot(L.t, v);\n        float param_8 = dot(L.b, v);\n        float param_9 = dot(L.t, l);\n        float param_10 = dot(L.b, l);\n        float param_11 = L.at;\n        float param_12 = L.ab;\n        vis = fa_v_ggx_aniso(param_5, param_6, param_7, param_8, param_9, param_10, param_11, param_12);\n    }\n    else\n    {\n        float _5231 = ((ndh * ndh) * (a2 - 1.0)) + 1.0;\n        d_ggx = a2 / ((3.1415927410125732421875 * _5231) * _5231);\n        vis = 0.5 / max(mix((2.0 * ndl) * ndv, ndl + ndv, alpha), 9.9999997473787516355514526367188e-05);\n    }\n    vec3 base = diffuse_color + (((f0 + ((vec3(L.f90) - f0) * pow(clamp(1.0 - vdh, 0.0, 1.0), 5.0))) * ((d_ggx * vis) * 3.1415927410125732421875)) * _5152);\n    if (L.sheen_on)\n    {\n        float param_13 = L.sheen_alpha;\n        float param_14 = ndh;\n        float param_15 = ndl;\n        float param_16 = ndv;\n        base = (base * L.sheen_scale) + (L.sheen * (((fa_d_charlie(param_13, param_14) * fa_v_ashikhmin(param_15, param_16)) * 3.1415927410125732421875) * _5152));\n    }\n    vec3 result = base * (L.keep * ndl);\n    if (L.coat > 0.0)\n    {\n        FaLayers param_17 = L;\n        vec3 param_18 = l;\n        vec3 param_19 = h;\n        float param_20 = vdh;\n        result += vec3(fa_layers_coat(param_17, param_18, param_19, param_20));\n    }\n    return result;\n}\n\nvec2 fa_env_brdf(float rough, float ndv)\n{\n    vec4 _4355 = (vec4(-1.0, -0.0274999998509883880615234375, -0.572000026702880859375, 0.02199999988079071044921875) * rough) + vec4(1.0, 0.0425000004470348358154296875, 1.03999996185302734375, -0.039999999105930328369140625);\n    float _4358 = _4355.x;\n    return (vec2(-1.03999996185302734375, 1.03999996185302734375) * ((min(_4358 * _4358, exp2((-9.27999973297119140625) * ndv)) * _4358) + _4355.y)) + _4355.zw;\n}\n\nvec3 fa_probe_level(vec2 origin, float res, int lv, vec2 e)\n{\n    float _3664;\n    if (lv == 0)\n    {\n        _3664 = 0.0;\n    }\n    else\n    {\n        _3664 = res + 2.0;\n    }\n    float _3674;\n    if (lv == 0)\n    {\n        _3674 = 0.0;\n    }\n    else\n    {\n        _3674 = (res - (res / float(1 << max((lv - 1), 0)))) + (2.0 * float(lv - 1));\n    }\n    return textureLod(fa_probe_atlas_fa_env_smp, (((origin + vec2(_3664, _3674)) + vec2(1.0)) + (((e * 0.5) + vec2(0.5)) * (res / float(1 << lv)))) / fa_atlas_size(), 0.0).xyz;\n}\n\nvec3 fa_probe_radiance(vec2 origin, float res, vec3 d, float rough)\n{\n    float _3720;\n    if (res > 64.5)\n    {\n        _3720 = 5.0;\n    }\n    else\n    {\n        _3720 = (res > 32.5) ? 4.0 : 3.0;\n    }\n    float _3735 = clamp(rough, 0.0, 1.0) * (_3720 - 1.0);\n    int _3742 = int(min(floor(_3735), _3720 - 2.0));\n    float _3747 = _3735 - float(_3742);\n    vec3 param = d;\n    vec2 _3751 = fa_oct_encode(param);\n    vec2 param_1 = origin;\n    float param_2 = res;\n    int param_3 = _3742;\n    vec2 param_4 = _3751;\n    vec3 _3761 = fa_probe_level(param_1, param_2, param_3, param_4);\n    if (_3747 < 0.00200000009499490261077880859375)\n    {\n        return _3761;\n    }\n    vec2 param_5 = origin;\n    float param_6 = res;\n    int param_7 = _3742 + 1;\n    vec2 param_8 = _3751;\n    return mix(_3761, fa_probe_level(param_5, param_6, param_7, param_8), vec3(_3747));\n}\n\nvec3 fa_probe_box_dir(vec3 d, vec4 posw, vec4 bx, vec4 by, vec4 bz)\n{\n    if (posw.w < 0.5)\n    {\n        return d;\n    }\n    float _3833 = dot(bx.xyz, fa_world_pos) + bx.w;\n    float _3840 = dot(by.xyz, fa_world_pos) + by.w;\n    float _3847 = dot(bz.xyz, fa_world_pos) + bz.w;\n    float _3853 = dot(bx.xyz, d);\n    float _3857 = dot(by.xyz, d);\n    float _3861 = dot(bz.xyz, d);\n    float _3867;\n    if (_3853 > 9.9999999747524270787835121154785e-07)\n    {\n        _3867 = (1.0 - _3833) / _3853;\n    }\n    else\n    {\n        float _3881;\n        if (_3853 < (-9.9999999747524270787835121154785e-07))\n        {\n            _3881 = ((-1.0) - _3833) / _3853;\n        }\n        else\n        {\n            _3881 = 1000000015047466219876688855040.0;\n        }\n        _3867 = _3881;\n    }\n    float tx = _3867;\n    float _3898;\n    if (_3857 > 9.9999999747524270787835121154785e-07)\n    {\n        _3898 = (1.0 - _3840) / _3857;\n    }\n    else\n    {\n        float _3911;\n        if (_3857 < (-9.9999999747524270787835121154785e-07))\n        {\n            _3911 = ((-1.0) - _3840) / _3857;\n        }\n        else\n        {\n            _3911 = 1000000015047466219876688855040.0;\n        }\n        _3898 = _3911;\n    }\n    float ty = _3898;\n    float _3927;\n    if (_3861 > 9.9999999747524270787835121154785e-07)\n    {\n        _3927 = (1.0 - _3847) / _3861;\n    }\n    else\n    {\n        float _3940;\n        if (_3861 < (-9.9999999747524270787835121154785e-07))\n        {\n            _3940 = ((-1.0) - _3847) / _3861;\n        }\n        else\n        {\n            _3940 = 1000000015047466219876688855040.0;\n        }\n        _3927 = _3940;\n    }\n    float _3952 = tx;\n    float _3955 = (_3952 > 0.0) ? _3952 : 1000000015047466219876688855040.0;\n    tx = _3955;\n    float _3956 = ty;\n    float _3959 = (_3956 > 0.0) ? _3956 : 1000000015047466219876688855040.0;\n    ty = _3959;\n    float _3969 = min(_3955, min(_3959, (_3927 > 0.0) ? _3927 : 1000000015047466219876688855040.0));\n    if (_3969 > 100000001504746621987668885504.0)\n    {\n        return d;\n    }\n    vec3 _3985 = (fa_world_pos + (d * _3969)) - posw.xyz;\n    vec3 _3990;\n    if (dot(_3985, _3985) > 1.0000000133514319600180897396058e-10)\n    {\n        _3990 = normalize(_3985);\n    }\n    else\n    {\n        _3990 = d;\n    }\n    return _3990;\n}\n\nvec3 fa_probe_environment(vec4 tile, vec4 posw, vec4 bx, vec4 by, vec4 bz, inout vec3 d, float rough)\n{\n    vec3 param = d;\n    vec4 param_1 = posw;\n    vec4 param_2 = bx;\n    vec4 param_3 = by;\n    vec4 param_4 = bz;\n    d = fa_probe_box_dir(param, param_1, param_2, param_3, param_4);\n    vec2 param_5 = tile.xy;\n    float param_6 = tile.z;\n    vec3 param_7 = d;\n    float param_8 = rough;\n    return fa_probe_radiance(param_5, param_6, param_7, param_8);\n}\n\nvec3 fa_environment(vec3 d, float rough)\n{\n    float _4036 = (1.0 - fa_mesh_fs_params[42].w) - fa_mesh_fs_params[47].w;\n    vec3 outc = vec3(0.0);\n    if (_4036 > 0.0005000000237487256526947021484375)\n    {\n        vec3 base;\n        if (fa_mesh_fs_params[11].w > 0.5)\n        {\n            vec2 param = fa_mesh_fs_params[41].zw;\n            float param_1 = 128.0;\n            vec3 param_2 = d;\n            float param_3 = rough;\n            base = fa_probe_radiance(param, param_1, param_2, param_3);\n        }\n        else\n        {\n            float _4064 = rough * rough;\n            float _4095 = 0.60000002384185791015625 * _4064;\n            base = mix(mix(fa_mesh_fs_params[12].xyz * 0.550000011920928955078125, mix(fa_mesh_fs_params[12].xyz, fa_mesh_fs_params[11].xyz, vec3(pow(clamp(d.y * (1.0 - (0.699999988079071044921875 * _4064)), 0.0, 1.0), 0.550000011920928955078125))), vec3(smoothstep((-0.0500000007450580596923828125) - _4095, 0.0500000007450580596923828125 + _4095, d.y))), ((fa_mesh_fs_params[11].xyz + fa_mesh_fs_params[12].xyz) * 0.5) * 0.800000011920928955078125, vec3(_4064 * 0.60000002384185791015625));\n        }\n        outc = base * _4036;\n    }\n    if (fa_mesh_fs_params[42].w > 0.0)\n    {\n        vec4 param_4 = fa_mesh_fs_params[42];\n        vec4 param_5 = fa_mesh_fs_params[43];\n        vec4 param_6 = fa_mesh_fs_params[44];\n        vec4 param_7 = fa_mesh_fs_params[45];\n        vec4 param_8 = fa_mesh_fs_params[46];\n        vec3 param_9 = d;\n        float param_10 = rough;\n        vec3 _4154 = fa_probe_environment(param_4, param_5, param_6, param_7, param_8, param_9, param_10);\n        outc += (_4154 * fa_mesh_fs_params[42].w);\n    }\n    if (fa_mesh_fs_params[47].w > 0.0)\n    {\n        vec4 param_11 = fa_mesh_fs_params[47];\n        vec4 param_12 = fa_mesh_fs_params[48];\n        vec4 param_13 = fa_mesh_fs_params[49];\n        vec4 param_14 = fa_mesh_fs_params[50];\n        vec4 param_15 = fa_mesh_fs_params[51];\n        vec3 param_16 = d;\n        float param_17 = rough;\n        vec3 _4186 = fa_probe_environment(param_11, param_12, param_13, param_14, param_15, param_16, param_17);\n        outc += (_4186 * fa_mesh_fs_params[47].w);\n    }\n    return outc;\n}\n\nvec3 fa_layers_ibl(FaLayers L, vec3 n, vec3 v, vec3 f0, float roughness, float occlusion)\n{\n    vec3 rn = n;\n    if (L.aniso != 0.0)\n    {\n        vec3 _4833;\n        if (L.aniso >= 0.0)\n        {\n            _4833 = L.b;\n        }\n        else\n        {\n            _4833 = L.t;\n        }\n        rn = normalize(mix(n, cross(cross(_4833, v), _4833), vec3(abs(L.aniso) * smoothstep(0.0, 0.25, roughness))));\n    }\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05);\n    vec2 _4869 = fa_env_brdf(param, param_1);\n    vec3 param_2 = reflect(-v, rn);\n    float param_3 = roughness;\n    vec3 result = (fa_environment(param_2, param_3) * ((f0 * _4869.x) + (vec3(L.f90) * _4869.y))) * L.base_scale;\n    if (L.sheen_on)\n    {\n        vec3 param_4 = n;\n        float param_5 = L.sheen_rough;\n        result += ((L.sheen * (L.sheen_e * L.keep)) * fa_environment(param_4, param_5));\n    }\n    result *= occlusion;\n    if (L.coat > 0.0)\n    {\n        float param_6 = L.coat_rough;\n        float param_7 = L.coat_ndv;\n        vec2 _4927 = fa_env_brdf(param_6, param_7);\n        vec3 param_8 = reflect(-v, L.nc);\n        float param_9 = L.coat_rough;\n        result += (fa_environment(param_8, param_9) * (L.coat * ((0.039999999105930328369140625 * _4927.x) + _4927.y)));\n    }\n    return result;\n}\n\nvec3 fa_sky_reflection(vec3 n, vec3 v, vec3 f0, float roughness)\n{\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05);\n    vec2 _4397 = fa_env_brdf(param, param_1);\n    vec3 param_2 = reflect(-v, n);\n    float param_3 = roughness;\n    return fa_environment(param_2, param_3) * ((f0 * _4397.x) + vec3(_4397.y));\n}\n\nvec2 fa_xm_size(int k)\n{\n    return max(floor(fa_mesh_fs_params[24].zw / vec2(float(1 << k))), vec2(1.0));\n}\n\nvec2 fa_xm_origin(int k)\n{\n    if (k == 0)\n    {\n        return vec2(0.0);\n    }\n    float y = 0.0;\n    for (int j = 1; j < k; j++)\n    {\n        int param = j;\n        y += fa_xm_size(param).y;\n    }\n    return vec2(fa_mesh_fs_params[24].z, y);\n}\n\nvec3 fa_xm_texel(vec2 size, vec2 origin, vec2 p)\n{\n    return texelFetch(fa_screen_tex_fa_shadow_smp, ivec2(origin + clamp(p, vec2(0.0), size - vec2(1.0))), 0).xyz;\n}\n\nvec3 fa_xm_level(int k, vec2 uv)\n{\n    int param = k;\n    vec2 _5629 = fa_xm_size(param);\n    int param_1 = k;\n    vec2 _5633 = fa_xm_origin(param_1);\n    vec2 _5639 = (uv * _5629) - vec2(0.5);\n    vec2 _5642 = fract(_5639);\n    vec2 _5645 = floor(_5639);\n    vec2 param_2 = _5629;\n    vec2 param_3 = _5633;\n    vec2 param_4 = _5645;\n    vec2 param_5 = _5629;\n    vec2 param_6 = _5633;\n    vec2 param_7 = _5645 + vec2(1.0, 0.0);\n    vec2 param_8 = _5629;\n    vec2 param_9 = _5633;\n    vec2 param_10 = _5645 + vec2(0.0, 1.0);\n    vec2 param_11 = _5629;\n    vec2 param_12 = _5633;\n    vec2 param_13 = _5645 + vec2(1.0);\n    vec3 _5687 = vec3(_5642.x);\n    return mix(mix(fa_xm_texel(param_2, param_3, param_4), fa_xm_texel(param_5, param_6, param_7), _5687), mix(fa_xm_texel(param_8, param_9, param_10), fa_xm_texel(param_11, param_12, param_13), _5687), vec3(_5642.y));\n}\n\nvec3 fa_xm_sample(vec2 uv, float lod)\n{\n    float _5706 = max(fa_mesh_fs_params[31].w - 1.0, 0.0);\n    float _5710 = clamp(lod, 0.0, _5706);\n    int _5714 = int(floor(_5710));\n    int param = _5714;\n    vec2 param_1 = uv;\n    vec3 c = fa_xm_level(param, param_1);\n    float _5724 = float(_5714);\n    float _5725 = _5710 - _5724;\n    bool _5727 = _5725 > 0.001000000047497451305389404296875;\n    bool _5734;\n    if (_5727)\n    {\n        _5734 = _5724 < _5706;\n    }\n    else\n    {\n        _5734 = _5727;\n    }\n    if (_5734)\n    {\n        int param_2 = _5714 + 1;\n        vec2 param_3 = uv;\n        c = mix(c, fa_xm_level(param_2, param_3), vec3(_5725));\n    }\n    return c;\n}\n\nvec3 fa_transmitted(Surface s, vec3 n, vec3 v, float roughness, vec3 f0, float f90, float keep, float tr, inout float blend)\n{\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05);\n    vec2 _5760 = fa_env_brdf(param, param_1);\n    vec3 through = ((vec3(1.0) - clamp((f0 * _5760.x) + (vec3(f90) * _5760.y), vec3(0.0), vec3(1.0))) * s.albedo) * (tr * keep);\n    float _5788 = max(s.thickness, 0.0);\n    bool _5793 = _5788 > 0.0;\n    if ((s.attenuation_distance > 0.0) && _5793)\n    {\n        through *= exp((-((-log(clamp(s.attenuation_color, vec3(9.9999997473787516355514526367188e-05), vec3(1.0)))) / vec3(s.attenuation_distance))) * _5788);\n    }\n    bool _5818 = fa_mesh_fs_params[30].w > 1.5;\n    bool _5825;\n    if (!_5818)\n    {\n        _5825 = fa_mesh_fs_params[30].w < 0.5;\n    }\n    else\n    {\n        _5825 = _5818;\n    }\n    if (_5825)\n    {\n        blend = clamp(dot(through, vec3(0.3333333432674407958984375)), 0.0, 0.980000019073486328125);\n        return vec3(0.0);\n    }\n    vec3 world = fa_world_pos;\n    if (_5793)\n    {\n        world += (refract(-v, n, 1.0 / max(s.ior, 1.0)) * _5788);\n    }\n    vec4 _5860 = vec4(world, 1.0);\n    float _5865 = dot(fa_mesh_fs_params[28], _5860);\n    vec2 uv = vec2(0.5);\n    if (_5865 > 9.9999997473787516355514526367188e-05)\n    {\n        vec2 _5883 = vec2(dot(fa_mesh_fs_params[26], _5860), dot(fa_mesh_fs_params[27], _5860)) / vec2(_5865);\n        float _5891;\n        if (fa_mesh_fs_params[24].y > 0.5)\n        {\n            _5891 = (_5883.y * 0.5) + 0.5;\n        }\n        else\n        {\n            _5891 = 0.5 - (_5883.y * 0.5);\n        }\n        uv = vec2((_5883.x * 0.5) + 0.5, _5891);\n    }\n    vec2 param_2 = clamp(uv, vec2(0.0), vec2(1.0));\n    float param_3 = (clamp(roughness, 0.0, 1.0) * clamp((2.0 * s.ior) - 2.0, 0.0, 1.0)) * max(fa_mesh_fs_params[31].w - 1.0, 0.0);\n    return through * fa_xm_sample(param_2, param_3);\n}\n\nvec3 fa_shadow_debug(vec3 color, vec3 world)\n{\n    if (fa_shadows[27].w < 0.5)\n    {\n        return color;\n    }\n    int _3271 = int(fa_shadows[25].x + 0.5);\n    float _3281 = dot(world - fa_shadows[27].xyz, fa_shadows[28].xyz);\n    vec3 tint = vec3(0.3499999940395355224609375);\n    bool _3286 = _3271 > 0;\n    bool _3295;\n    if (_3286)\n    {\n        int param = _3271 - 1;\n        _3295 = _3281 <= fa_shadow_split_at(param);\n    }\n    else\n    {\n        _3295 = _3286;\n    }\n    if (_3295)\n    {\n        tint = vec3(1.0, 0.1500000059604644775390625, 0.100000001490116119384765625);\n        bool _3301 = _3271 > 1;\n        bool _3308;\n        if (_3301)\n        {\n            _3308 = _3281 > fa_shadows[24].x;\n        }\n        else\n        {\n            _3308 = _3301;\n        }\n        if (_3308)\n        {\n            tint = vec3(0.100000001490116119384765625, 0.89999997615814208984375, 0.20000000298023223876953125);\n        }\n        bool _3314 = _3271 > 2;\n        bool _3321;\n        if (_3314)\n        {\n            _3321 = _3281 > fa_shadows[24].y;\n        }\n        else\n        {\n            _3321 = _3314;\n        }\n        if (_3321)\n        {\n            tint = vec3(0.1500000059604644775390625, 0.300000011920928955078125, 1.0);\n        }\n        bool _3327 = _3271 > 3;\n        bool _3334;\n        if (_3327)\n        {\n            _3334 = _3281 > fa_shadows[24].z;\n        }\n        else\n        {\n            _3334 = _3327;\n        }\n        if (_3334)\n        {\n            tint = vec3(1.0, 0.89999997615814208984375, 0.100000001490116119384765625);\n        }\n    }\n    return mix(color, tint, vec3(0.550000011920928955078125));\n}\n\nvoid main()\n{\n    fa_inst_load();\n    vec3 _8869 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _8869 = -_8869;\n    }\n    vec3 _8162 = normalize(fa_mesh_fs_params[0].xyz - fa_world_pos);\n    vec3 param = fa_world_pos;\n    fa_cluster_begin(param);\n    SurfaceInput param_1 = SurfaceInput(fa_world_pos, _8869, fa_world_tangent, fa_uv, fa_vertex_color, _8162, gl_FrontFacing);\n    Surface _8170 = fa_standard_surface(param_1);\n    vec3 _8900 = _8170.albedo;\n    float _8901 = _8170.alpha;\n    vec3 _8902 = _8170.normal;\n    float _8903 = _8170.metallic;\n    float _8904 = _8170.roughness;\n    float _8905 = _8170.occlusion;\n    vec3 _8906 = _8170.emission;\n    float _8907 = _8170.clearcoat;\n    float _8908 = _8170.clearcoat_roughness;\n    vec3 _8909 = _8170.sheen_color;\n    float _8910 = _8170.sheen_roughness;\n    float _8911 = _8170.anisotropy;\n    float _8912 = _8170.anisotropy_rotation;\n    float _8913 = _8170.specular;\n    float _8914 = _8170.ior;\n    vec3 _8915 = _8170.specular_color;\n    float _8916 = _8170.transmission;\n    float _8917 = _8170.thickness;\n    vec3 _8918 = _8170.attenuation_color;\n    float _8919 = _8170.attenuation_distance;\n    SurfaceInput param_2 = SurfaceInput(fa_world_pos, _8869, fa_world_tangent, fa_uv, fa_vertex_color, _8162, gl_FrontFacing);\n    Surface param_3 = _8170;\n    surface(param_2, param_3);\n    _8900 = param_3.albedo;\n    _8901 = param_3.alpha;\n    _8902 = param_3.normal;\n    _8903 = param_3.metallic;\n    _8904 = param_3.roughness;\n    _8905 = param_3.occlusion;\n    _8906 = param_3.emission;\n    _8907 = param_3.clearcoat;\n    _8908 = param_3.clearcoat_roughness;\n    _8909 = param_3.sheen_color;\n    _8910 = param_3.sheen_roughness;\n    _8911 = param_3.anisotropy;\n    _8912 = param_3.anisotropy_rotation;\n    _8913 = param_3.specular;\n    _8914 = param_3.ior;\n    _8915 = param_3.specular_color;\n    _8916 = param_3.transmission;\n    _8917 = param_3.thickness;\n    _8918 = param_3.attenuation_color;\n    _8919 = param_3.attenuation_distance;\n    vec3 param_4 = fa_world_pos;\n    vec3 param_5 = _8869;\n    vec3 param_6 = param_3.albedo;\n    vec3 param_7 = param_3.normal;\n    fa_apply_decals(param_4, param_5, param_6, param_7);\n    _8900 = param_6;\n    _8902 = param_7;\n    float fa_tr_blend = 0.0;\n    vec3 result;\n    if (fa_mesh_fs_params[3].w > 0.5)\n    {\n        result = _8900;\n    }\n    else\n    {\n        vec3 _8210 = normalize(_8902);\n        float _8217 = clamp(_8903, 0.0, 1.0);\n        float _8221 = clamp(_8904, 0.0500000007450580596923828125, 1.0);\n        float _8225 = _8221 * _8221;\n        float _8229 = _8225 * _8225;\n        float _8234 = max(dot(_8210, _8162), 9.9999997473787516355514526367188e-05);\n        float _8240 = 1.0 - _8217;\n        float _8241 = clamp(_8916, 0.0, 1.0) * _8240;\n        vec3 _8250 = (_8900 * _8240) * (1.0 - _8241);\n        vec3 _8257 = mix(vec3(0.039999999105930328369140625), _8900, vec3(_8217));\n        vec3 f0 = _8257;\n        SurfaceInput param_8 = SurfaceInput(fa_world_pos, _8869, fa_world_tangent, fa_uv, fa_vertex_color, _8162, gl_FrontFacing);\n        Surface param_9 = Surface(_8900, _8901, _8902, _8903, _8904, _8905, _8906, _8907, _8908, _8909, _8910, _8911, _8912, _8913, _8914, _8915, _8916, _8917, _8918, _8919);\n        vec3 param_10 = _8210;\n        vec3 param_11 = _8162;\n        float param_12 = _8217;\n        float param_13 = _8221;\n        vec3 param_14 = _8257;\n        FaLayers _8273 = fa_layers_setup(param_8, param_9, param_10, param_11, param_12, param_13, param_14);\n        f0 = param_14;\n        vec3 param_15 = _8210;\n        vec3 lit = (fa_indirect_diffuse(param_15) * _8250) * _8905;\n        if (_8273.on)\n        {\n            lit *= _8273.base_scale;\n        }\n        int _8295 = fa_cl_ndir + fa_cl_local;\n        float _8360;\n        for (int ln = 0; ln < _8295; ln++)\n        {\n            int param_16 = ln;\n            int _8308 = fa_cl_light(param_16);\n            int param_17 = _8308;\n            if (fa_baked_keep(param_17) <= 0.0)\n            {\n                continue;\n            }\n            int param_18 = _8308;\n            vec3 param_19 = fa_world_pos;\n            vec3 param_20 = _8869;\n            LightSample _8324 = fa_light_shadowed(param_18, param_19, param_20);\n            float _8332 = max(dot(_8210, _8324.direction), 0.0);\n            float _8338 = _8324.attenuation * _8324.shadow;\n            vec3 _8343 = normalize(_8324.direction + _8162);\n            float _8348 = max(dot(_8210, _8343), 0.0);\n            float _8353 = max(dot(_8162, _8343), 0.0);\n            if (fa_light_is_area)\n            {\n                if (_8273.on)\n                {\n                    _8360 = _8273.f90;\n                }\n                else\n                {\n                    _8360 = 1.0;\n                }\n                int param_21 = _8308;\n                vec3 param_22 = fa_world_pos;\n                vec3 param_23 = _8210;\n                vec3 param_24 = _8162;\n                vec3 param_25 = _8250;\n                vec3 param_26 = f0;\n                float param_27 = _8360;\n                float param_28 = _8221;\n                float param_29 = _8234;\n                float param_30 = _8338;\n                vec3 area = fa_area_shade(param_21, param_22, param_23, param_24, param_25, param_26, param_27, param_28, param_29, param_30);\n                if (_8273.on)\n                {\n                    FaLayers param_31 = _8273;\n                    vec3 param_32 = area;\n                    int param_33 = _8308;\n                    vec3 param_34 = _8210;\n                    vec3 param_35 = _8162;\n                    vec3 param_36 = _8324.direction;\n                    float param_37 = _8234;\n                    float param_38 = _8338;\n                    area = fa_area_layers(param_31, param_32, param_33, param_34, param_35, param_36, param_37, param_38);\n                }\n                lit += area;\n            }\n            else\n            {\n                if (_8273.on)\n                {\n                    FaLayers param_39 = _8273;\n                    vec3 param_40 = _8250;\n                    vec3 param_41 = f0;\n                    vec3 param_42 = _8210;\n                    vec3 param_43 = _8162;\n                    vec3 param_44 = _8324.direction;\n                    vec3 param_45 = _8343;\n                    float param_46 = _8332;\n                    float param_47 = _8234;\n                    float param_48 = _8348;\n                    float param_49 = _8353;\n                    float param_50 = _8225;\n                    float param_51 = _8229;\n                    int param_52 = _8308;\n                    lit += (fa_layers_light(param_39, param_40, param_41, param_42, param_43, param_44, param_45, param_46, param_47, param_48, param_49, param_50, param_51) * ((fa_light_rgb(param_52) * fa_light_tint) * _8338));\n                }\n                else\n                {\n                    float _8462 = ((_8348 * _8348) * (_8229 - 1.0)) + 1.0;\n                    int param_53 = _8308;\n                    lit += (((_8250 + (((f0 + ((vec3(1.0) - f0) * pow(1.0 - _8353, 5.0))) * (((_8229 / ((3.1415927410125732421875 * _8462) * _8462)) * (0.5 / max(mix((2.0 * _8332) * _8234, _8332 + _8234, _8225), 9.9999997473787516355514526367188e-05))) * 3.1415927410125732421875)) * step(9.9999997473787516355514526367188e-05, _8332))) * (fa_light_rgb(param_53) * fa_light_tint)) * (_8332 * _8338));\n                }\n            }\n        }\n        if (_8273.on)\n        {\n            FaLayers param_54 = _8273;\n            vec3 param_55 = _8210;\n            vec3 param_56 = _8162;\n            vec3 param_57 = f0;\n            float param_58 = _8221;\n            float param_59 = _8905;\n            lit += fa_layers_ibl(param_54, param_55, param_56, param_57, param_58, param_59);\n        }\n        else\n        {\n            vec3 param_60 = _8210;\n            vec3 param_61 = _8162;\n            vec3 param_62 = f0;\n            float param_63 = _8221;\n            lit += (fa_sky_reflection(param_60, param_61, param_62, param_63) * _8905);\n        }\n        if (_8241 > 0.0)\n        {\n            float _8560;\n            if (_8273.on)\n            {\n                _8560 = _8273.f90;\n            }\n            else\n            {\n                _8560 = 1.0;\n            }\n            float _8568;\n            if (_8273.on)\n            {\n                _8568 = _8273.base_scale;\n            }\n            else\n            {\n                _8568 = 1.0;\n            }\n            Surface param_64 = Surface(_8900, _8901, _8902, _8903, _8904, _8905, _8906, _8907, _8908, _8909, _8910, _8911, _8912, _8913, _8914, _8915, _8916, _8917, _8918, _8919);\n            vec3 param_65 = _8210;\n            vec3 param_66 = _8162;\n            float param_67 = _8221;\n            vec3 param_68 = f0;\n            float param_69 = _8560;\n            float param_70 = _8568;\n            float param_71 = _8241;\n            float param_72 = fa_tr_blend;\n            vec3 _8592 = fa_transmitted(param_64, param_65, param_66, param_67, param_68, param_69, param_70, param_71, param_72);\n            fa_tr_blend = param_72;\n            lit += _8592;\n        }\n        result = lit;\n    }\n    vec3 _8599 = result;\n    vec3 _8600 = _8599 + _8906;\n    result = _8600;\n    vec3 param_73 = _8600;\n    vec3 param_74 = fa_world_pos;\n    result = fa_shadow_debug(param_73, param_74);\n    bool _8609 = fa_mesh_fs_params[7].w > 0.0;\n    bool _8616;\n    if (!_8609)\n    {\n        _8616 = fa_mesh_fs_params[8].y > 0.0;\n    }\n    else\n    {\n        _8616 = _8609;\n    }\n    if (_8616)\n    {\n        vec3 _8625 = fa_world_pos - fa_mesh_fs_params[0].xyz;\n        float _8631 = dot(_8625, fa_mesh_fs_params[9].xyz);\n        bool _8635 = fa_mesh_fs_params[9].w > 0.5;\n        float _8636;\n        if (_8635)\n        {\n            _8636 = _8631;\n        }\n        else\n        {\n            _8636 = length(_8625);\n        }\n        float _8648 = _8636 - fa_mesh_fs_params[8].x;\n        if (_8648 > 0.0)\n        {\n            float _8657 = fa_mesh_fs_params[7].w * _8648;\n            float tau = _8657 * _8657;\n            if (fa_mesh_fs_params[8].y > 0.0)\n            {\n                float _8673;\n                if (_8635)\n                {\n                    _8673 = fa_world_pos.y - (fa_mesh_fs_params[9].y * _8631);\n                }\n                else\n                {\n                    _8673 = fa_mesh_fs_params[0].y;\n                }\n                float _8694 = mix(_8673, fa_world_pos.y, clamp(fa_mesh_fs_params[8].x / _8636, 0.0, 1.0));\n                float _8698 = fa_world_pos.y - _8694;\n                float _8703 = _8694 - fa_mesh_fs_params[8].z;\n                float _8708 = fa_world_pos.y - fa_mesh_fs_params[8].z;\n                bool _8711 = _8703 <= 0.0;\n                bool _8712 = !_8711;\n                bool _8718;\n                if (_8712)\n                {\n                    _8718 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _8718 = _8711;\n                }\n                float _8719;\n                if (_8718)\n                {\n                    _8719 = fa_mesh_fs_params[8].y;\n                }\n                else\n                {\n                    _8719 = fa_mesh_fs_params[8].y * exp(-min(fa_mesh_fs_params[8].w * _8703, 80.0));\n                }\n                bool _8746;\n                if (_8712)\n                {\n                    _8746 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _8746 = _8711;\n                }\n                float _8747;\n                if (_8746)\n                {\n                    _8747 = fa_mesh_fs_params[8].y * _8703;\n                }\n                else\n                {\n                    _8747 = (fa_mesh_fs_params[8].y * (1.0 - exp(-min(fa_mesh_fs_params[8].w * _8703, 80.0)))) / fa_mesh_fs_params[8].w;\n                }\n                bool _8772 = _8708 <= 0.0;\n                bool _8779;\n                if (!_8772)\n                {\n                    _8779 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _8779 = _8772;\n                }\n                float _8780;\n                if (_8779)\n                {\n                    _8780 = fa_mesh_fs_params[8].y * _8708;\n                }\n                else\n                {\n                    _8780 = (fa_mesh_fs_params[8].y * (1.0 - exp(-min(fa_mesh_fs_params[8].w * _8708, 80.0)))) / fa_mesh_fs_params[8].w;\n                }\n                float _8807;\n                if (abs(_8698) < 0.001000000047497451305389404296875)\n                {\n                    _8807 = _8719;\n                }\n                else\n                {\n                    _8807 = (_8780 - _8747) / _8698;\n                }\n                tau += (_8648 * max(_8807, 0.0));\n            }\n            result = mix(result, fa_mesh_fs_params[7].xyz, vec3(clamp(1.0 - exp(-clamp(tau, 0.0, 80.0)), 0.0, 1.0)));\n        }\n    }\n    if (fa_tr_blend > 0.0)\n    {\n        float _8843 = 1.0 - fa_tr_blend;\n        result /= vec3(_8843);\n        _8901 *= _8843;\n    }\n    fa_frag_color = vec4(result, _8901);\n}\n\n",
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
      "vs": "#version 430\n\nstruct VertexData\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 color;\n    vec3 object_pos;\n};\n\nstruct points_item\n{\n    vec4 pos;\n    vec4 tint;\n};\n\nstruct extra_item\n{\n    vec4 pos;\n    vec4 tint;\n};\n\nuniform vec4 fa_mesh_vs_params[11];\nlayout(binding = 1, std430) readonly buffer fa_vs_points_buf\n{\n    points_item data[];\n} fa_vs_points;\n\nlayout(binding = 0, std430) readonly buffer fa_vs_extra_buf\n{\n    extra_item data[];\n} fa_vs_extra;\n\nuniform vec4 fa_vel_params[9];\nuniform vec4 fa_inst_base[4];\nlayout(location = 0) out vec3 fa_world_pos;\nlayout(location = 1) out vec3 fa_world_normal;\nlayout(location = 2) out vec4 fa_world_tangent;\nlayout(location = 3) out vec2 fa_uv;\nlayout(location = 4) out vec4 fa_vertex_color;\nlayout(location = 5) out float fa_pre_depth;\nlayout(location = 6) out vec3 fa_pre_r0;\nlayout(location = 7) out vec3 fa_pre_r1;\nlayout(location = 8) out vec3 fa_pre_r2;\nlayout(location = 9) out vec3 fa_vel_cur;\nlayout(location = 10) out vec3 fa_vel_prev;\nlayout(location = 0) in vec3 fa_position;\nlayout(location = 1) in vec3 fa_normal;\nlayout(location = 3) in vec4 fa_tangent;\nlayout(location = 2) in vec2 fa_texcoord0;\nlayout(location = 4) in vec4 fa_color;\nlayout(location = 5) in vec4 fa_inst_m0;\nlayout(location = 6) in vec4 fa_inst_m1;\nlayout(location = 7) in vec4 fa_inst_m2;\nlayout(location = 8) in vec4 fa_inst_m3;\nvec4 fa_vtime;\n\nvoid fa_inst_begin()\n{\n}\n\nvec4 fa_time_now()\n{\n    return fa_mesh_vs_params[9];\n}\n\nVertexData fa_vertex_data(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    vec3 _144 = cross(model[1].xyz, model[2].xyz);\n    float _147 = (dot(model[0].xyz, _144) < 0.0) ? (-1.0) : 1.0;\n    return VertexData((model * vec4(position, 1.0)).xyz, (((_144 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _147, vec4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _147), texcoord0 * fa_mesh_vs_params[8].xy, color, position);\n}\n\nvoid vertex(inout VertexData v)\n{\n    bool _82 = fa_vs_points.data[gl_InstanceID].pos.w < 0.5;\n    bool _97;\n    if (!_82)\n    {\n        _97 = fa_vs_extra.data[gl_InstanceID].pos.w < (-1.0);\n    }\n    else\n    {\n        _97 = _82;\n    }\n    if (_97)\n    {\n        v.world_pos = vec3(1000000000.0);\n        return;\n    }\n    v.world_pos += fa_vs_points.data[gl_InstanceID].pos.xyz;\n    v.color = fa_vs_points.data[gl_InstanceID].tint;\n}\n\nmat4 fa_prev_model()\n{\n    return mat4(vec4(1.0, 0.0, 0.0, 0.0), vec4(0.0, 1.0, 0.0, 0.0), vec4(0.0, 0.0, 1.0, 0.0), vec4(0.0, 0.0, 0.0, 1.0));\n}\n\nvoid fa_prepass_vertex(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color, bool has_prev)\n{\n    bool _221;\n    if (has_prev)\n    {\n        _221 = fa_vel_params[8].x > 0.5;\n    }\n    else\n    {\n        _221 = has_prev;\n    }\n    fa_vtime = fa_time_now();\n    mat4 param = model;\n    vec3 param_1 = position;\n    vec3 param_2 = normal;\n    vec4 param_3 = tangent;\n    vec2 param_4 = texcoord0;\n    vec4 param_5 = color;\n    VertexData param_6 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    vertex(param_6);\n    mat4 _244 = mat4(fa_mesh_vs_params[4], fa_mesh_vs_params[5], fa_mesh_vs_params[6], fa_mesh_vs_params[7]);\n    vec4 _251 = vec4(param_6.world_pos, 1.0);\n    fa_world_pos = param_6.world_pos;\n    fa_world_normal = param_6.world_normal;\n    fa_world_tangent = param_6.world_tangent;\n    fa_uv = param_6.uv;\n    fa_vertex_color = param_6.color;\n    fa_pre_depth = -(_244 * _251).z;\n    fa_pre_r0 = vec3(_244[0].x, _244[1].x, _244[2].x);\n    fa_pre_r1 = vec3(_244[0].y, _244[1].y, _244[2].y);\n    fa_pre_r2 = vec3(_244[0].z, _244[1].z, _244[2].z);\n    gl_Position = mat4(fa_mesh_vs_params[0], fa_mesh_vs_params[1], fa_mesh_vs_params[2], fa_mesh_vs_params[3]) * _251;\n    fa_vel_cur = vec3(0.0, 0.0, 1.0);\n    fa_vel_prev = vec3(0.0);\n    if (_221)\n    {\n        fa_vtime.x = fa_vel_params[8].y;\n        mat4 param_7 = fa_prev_model();\n        vec3 param_8 = position;\n        vec3 param_9 = normal;\n        vec4 param_10 = tangent;\n        vec2 param_11 = texcoord0;\n        vec4 param_12 = color;\n        VertexData param_13 = fa_vertex_data(param_7, param_8, param_9, param_10, param_11, param_12);\n        vertex(param_13);\n        fa_vel_cur = vec3((mat4(fa_vel_params[0], fa_vel_params[1], fa_vel_params[2], fa_vel_params[3]) * _251).xyw);\n        fa_vel_prev = vec3((mat4(fa_vel_params[4], fa_vel_params[5], fa_vel_params[6], fa_vel_params[7]) * vec4(param_13.world_pos, 1.0)).xyw);\n    }\n}\n\nvoid main()\n{\n    fa_vtime = vec4(0.0);\n    fa_inst_begin();\n    mat4 param = mat4(fa_inst_base[0], fa_inst_base[1], fa_inst_base[2], fa_inst_base[3]);\n    vec3 param_1 = fa_position;\n    vec3 param_2 = fa_normal;\n    vec4 param_3 = fa_tangent;\n    vec2 param_4 = fa_texcoord0;\n    vec4 param_5 = fa_color;\n    bool param_6 = false;\n    fa_prepass_vertex(param, param_1, param_2, param_3, param_4, param_5, param_6);\n}\n\n",
      "fs": "#version 430\n\nstruct SurfaceInput\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 vertex_color;\n    vec3 view_dir;\n    bool front_facing;\n};\n\nstruct Surface\n{\n    vec3 albedo;\n    float alpha;\n    vec3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    vec3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    vec3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    vec3 specular_color;\n    float transmission;\n    float thickness;\n    vec3 attenuation_color;\n    float attenuation_distance;\n};\n\nstruct points_item\n{\n    vec4 pos;\n    vec4 tint;\n};\n\nlayout(binding = 3, std430) readonly buffer fa_points_buf\n{\n    points_item data[];\n} points;\n\nuniform vec4 fa_mesh_fs_params[53];\nlayout(binding = 0) uniform sampler2D fa_tex_fa_smp;\nlayout(binding = 1) uniform sampler2D fa_normal_tex_fa_smp;\nlayout(binding = 2) uniform sampler2D fa_mr_tex_fa_smp;\nlayout(binding = 3) uniform sampler2D fa_occlusion_tex_fa_smp;\nlayout(binding = 4) uniform sampler2D fa_emissive_tex_fa_smp;\n\nlayout(location = 0) in vec3 fa_world_pos;\nlayout(location = 1) in vec3 fa_world_normal;\nlayout(location = 2) in vec4 fa_world_tangent;\nlayout(location = 3) in vec2 fa_uv;\nlayout(location = 4) in vec4 fa_vertex_color;\nlayout(location = 6) in vec3 fa_pre_r0;\nlayout(location = 7) in vec3 fa_pre_r1;\nlayout(location = 8) in vec3 fa_pre_r2;\nlayout(location = 0) out vec4 fa_frag_color;\nlayout(location = 5) in float fa_pre_depth;\nlayout(location = 9) in vec3 fa_vel_cur;\nlayout(location = 10) in vec3 fa_vel_prev;\nlayout(location = 1) out vec2 fa_frag_velocity;\n\nvoid fa_inst_load()\n{\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nvec3 fa_linear_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_tex_fix(inout vec3 c, float mode)\n{\n    if (mode > 1.5)\n    {\n        vec3 param = c;\n        vec3 _190 = fa_linear_to_srgb(param);\n        c = _190;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            vec3 param_1 = c;\n            vec3 _199 = fa_srgb_to_linear(param_1);\n            c = _199;\n        }\n    }\n    return c;\n}\n\nvec3 fa_tangent_normal(SurfaceInput i, vec3 m)\n{\n    vec3 _56;\n    if (i.front_facing)\n    {\n        _56 = i.world_normal;\n    }\n    else\n    {\n        _56 = -i.world_normal;\n    }\n    vec3 _81 = normalize(i.world_tangent.xyz - (_56 * dot(_56, i.world_tangent.xyz)));\n    vec3 _109 = normalize(((_81 * m.x) + ((cross(_56, _81) * i.world_tangent.w) * m.y)) + (_56 * m.z));\n    vec3 _112;\n    if (i.front_facing)\n    {\n        _112 = _109;\n    }\n    else\n    {\n        _112 = -_109;\n    }\n    return _112;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    vec4 base_t = texture(fa_tex_fa_smp, i.uv, fa_mesh_fs_params[12].w);\n    float param = fa_mesh_fs_params[6].w;\n    float param_1 = 1.0;\n    vec3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    vec3 _247 = fa_tex_fix(param_2, param_3);\n    vec4 _859 = base_t;\n    _859.x = _247.x;\n    _859.y = _247.y;\n    _859.z = _247.z;\n    base_t = _859;\n    vec4 _262 = (_859 * fa_mesh_fs_params[2]) * i.vertex_color;\n    vec3 _814 = i.world_normal;\n    if (fa_mesh_fs_params[6].z > 0.5)\n    {\n        float param_4 = fa_mesh_fs_params[6].w;\n        float param_5 = 16.0;\n        vec3 param_6 = texture(fa_normal_tex_fa_smp, i.uv, fa_mesh_fs_params[12].w).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        vec3 _297 = fa_tex_fix(param_6, param_7);\n        vec3 _301 = (_297 * 2.0) - vec3(1.0);\n        vec2 _306 = _301.xy * fa_mesh_fs_params[6].x;\n        vec3 _867 = _301;\n        _867.x = _306.x;\n        _867.y = _306.y;\n        SurfaceInput param_8 = i;\n        vec3 param_9 = _867;\n        _814 = fa_tangent_normal(param_8, param_9);\n    }\n    vec4 mrt = texture(fa_mr_tex_fa_smp, i.uv, fa_mesh_fs_params[12].w);\n    float param_10 = fa_mesh_fs_params[6].w;\n    float param_11 = 64.0;\n    vec3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    vec3 _337 = fa_tex_fix(param_12, param_13);\n    vec4 _870 = mrt;\n    _870.x = _337.x;\n    _870.y = _337.y;\n    _870.z = _337.z;\n    mrt = _870;\n    vec4 _369 = texture(fa_occlusion_tex_fa_smp, i.uv, fa_mesh_fs_params[12].w);\n    float param_14 = fa_mesh_fs_params[6].w;\n    float param_15 = 256.0;\n    vec3 param_16 = _369.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    vec3 _381 = fa_tex_fix(param_16, param_17);\n    float param_18 = fa_mesh_fs_params[6].w;\n    float param_19 = 4.0;\n    vec3 param_20 = texture(fa_emissive_tex_fa_smp, i.uv, fa_mesh_fs_params[12].w).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    vec3 _413 = fa_tex_fix(param_20, param_21);\n    float _819 = fa_mesh_fs_params[20].x;\n    float _820 = fa_mesh_fs_params[20].y;\n    float _823 = fa_mesh_fs_params[20].z;\n    float _822 = fa_mesh_fs_params[21].w;\n    float _825 = fa_mesh_fs_params[22].x;\n    if (fa_mesh_fs_params[22].z > 0.5)\n    {\n        if (mod(fa_mesh_fs_params[22].z, 2.0) > 0.5)\n        {\n            _819 *= _381.y;\n            _820 *= _381.z;\n            _822 *= _369.w;\n        }\n        if (fa_mesh_fs_params[22].z > 1.5)\n        {\n            _823 *= mrt.x;\n            _825 *= mrt.w;\n        }\n    }\n    return Surface(_262.xyz, _262.w, _814, clamp(fa_mesh_fs_params[5].x * _337.z, 0.0, 1.0), clamp(fa_mesh_fs_params[5].y * _337.y, 0.0500000007450580596923828125, 1.0), 1.0 + (fa_mesh_fs_params[6].y * (_381.x - 1.0)), fa_mesh_fs_params[3].xyz + (fa_mesh_fs_params[4].xyz * _413), _819, _820, fa_mesh_fs_params[21].xyz, _822, _823, fa_mesh_fs_params[20].w, _825, fa_mesh_fs_params[22].y, fa_mesh_fs_params[23].xyz, fa_mesh_fs_params[30].x, fa_mesh_fs_params[30].y, fa_mesh_fs_params[31].xyz, fa_mesh_fs_params[30].z);\n}\n\nvoid surface(SurfaceInput i, inout Surface s)\n{\n    s.emission += (i.vertex_color.xyz * points.data[0].tint.w);\n}\n\nvoid main()\n{\n    fa_inst_load();\n    vec3 _709 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _709 = -_709;\n    }\n    vec3 _565 = normalize(fa_mesh_fs_params[0].xyz - fa_world_pos);\n    SurfaceInput param = SurfaceInput(fa_world_pos, _709, fa_world_tangent, fa_uv, fa_vertex_color, _565, gl_FrontFacing);\n    SurfaceInput param_1 = SurfaceInput(fa_world_pos, _709, fa_world_tangent, fa_uv, fa_vertex_color, _565, gl_FrontFacing);\n    Surface param_2 = fa_standard_surface(param);\n    surface(param_1, param_2);\n    vec3 _580 = normalize(param_2.normal);\n    vec3 _595 = normalize(vec3(dot(fa_pre_r0, _580), dot(fa_pre_r1, _580), dot(fa_pre_r2, _580)));\n    float _607 = _595.z;\n    vec2 e = _595.xy / vec2((abs(_595.x) + abs(_595.y)) + abs(_607));\n    if (_607 < 0.0)\n    {\n        e = (vec2(1.0) - abs(e.yx)) * vec2((e.x >= 0.0) ? 1.0 : (-1.0), (e.y >= 0.0) ? 1.0 : (-1.0));\n    }\n    fa_frag_color = vec4(min(fa_pre_depth, 60000.0), e, 1.0);\n    vec2 motion = vec2(1024.0);\n    bool _651 = fa_vel_cur.z > 9.9999997473787516355514526367188e-06;\n    bool _658;\n    if (_651)\n    {\n        _658 = fa_vel_prev.z > 9.9999997473787516355514526367188e-06;\n    }\n    else\n    {\n        _658 = _651;\n    }\n    if (_658)\n    {\n        motion = clamp(((vec2(fa_vel_prev.x, -fa_vel_prev.y) / vec2(fa_vel_prev.z)) * 0.5) - ((vec2(fa_vel_cur.x, -fa_vel_cur.y) / vec2(fa_vel_cur.z)) * 0.5), vec2(-4.0), vec2(4.0));\n    }\n    fa_frag_velocity = motion;\n}\n\n",
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
            "inst_name": "_217",
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
            "inst_name": "_382",
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
            "inst_name": "_232",
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
      "vs": "#version 430\n\nstruct VertexData\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 color;\n    vec3 object_pos;\n};\n\nstruct points_item\n{\n    vec4 pos;\n    vec4 tint;\n};\n\nstruct extra_item\n{\n    vec4 pos;\n    vec4 tint;\n};\n\nuniform vec4 fa_mesh_vs_params[11];\nlayout(binding = 1, std430) readonly buffer fa_vs_points_buf\n{\n    points_item data[];\n} fa_vs_points;\n\nlayout(binding = 0, std430) readonly buffer fa_vs_extra_buf\n{\n    extra_item data[];\n} fa_vs_extra;\n\nuniform vec4 fa_skin[192];\nuniform vec4 fa_vel_params[9];\nuniform vec4 fa_inst_base[4];\nlayout(location = 0) out vec3 fa_world_pos;\nlayout(location = 1) out vec3 fa_world_normal;\nlayout(location = 2) out vec4 fa_world_tangent;\nlayout(location = 3) out vec2 fa_uv;\nlayout(location = 4) out vec4 fa_vertex_color;\nlayout(location = 5) out float fa_pre_depth;\nlayout(location = 6) out vec3 fa_pre_r0;\nlayout(location = 7) out vec3 fa_pre_r1;\nlayout(location = 8) out vec3 fa_pre_r2;\nlayout(location = 9) out vec3 fa_vel_cur;\nlayout(location = 10) out vec3 fa_vel_prev;\nlayout(location = 9) in vec4 fa_joints;\nlayout(location = 10) in vec4 fa_weights;\nlayout(location = 0) in vec3 fa_position;\nlayout(location = 1) in vec3 fa_normal;\nlayout(location = 3) in vec4 fa_tangent;\nlayout(location = 2) in vec2 fa_texcoord0;\nlayout(location = 4) in vec4 fa_color;\nlayout(location = 5) in vec4 fa_inst_m0;\nlayout(location = 6) in vec4 fa_inst_m1;\nlayout(location = 7) in vec4 fa_inst_m2;\nlayout(location = 8) in vec4 fa_inst_m3;\nvec4 fa_vtime;\n\nvoid fa_inst_begin()\n{\n}\n\nmat4 fa_skin_matrix(vec4 joints, vec4 weights)\n{\n    vec4 r0 = vec4(0.0);\n    vec4 r1 = vec4(0.0);\n    vec4 r2 = vec4(0.0);\n    for (int i = 0; i < 4; i++)\n    {\n        int _236 = int((joints[i] * 255.0) + 0.5) * 3;\n        r0 += (fa_skin[_236 * 1 + 0] * weights[i]);\n        r1 += (fa_skin[(_236 + 1) * 1 + 0] * weights[i]);\n        r2 += (fa_skin[(_236 + 2) * 1 + 0] * weights[i]);\n    }\n    return mat4(vec4(r0.x, r1.x, r2.x, 0.0), vec4(r0.y, r1.y, r2.y, 0.0), vec4(r0.z, r1.z, r2.z, 0.0), vec4(r0.w, r1.w, r2.w, 1.0));\n}\n\nvec4 fa_time_now()\n{\n    return fa_mesh_vs_params[9];\n}\n\nVertexData fa_vertex_data(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    vec3 _149 = cross(model[1].xyz, model[2].xyz);\n    float _152 = (dot(model[0].xyz, _149) < 0.0) ? (-1.0) : 1.0;\n    return VertexData((model * vec4(position, 1.0)).xyz, (((_149 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _152, vec4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _152), texcoord0 * fa_mesh_vs_params[8].xy, color, position);\n}\n\nvoid vertex(inout VertexData v)\n{\n    bool _87 = fa_vs_points.data[gl_InstanceID].pos.w < 0.5;\n    bool _102;\n    if (!_87)\n    {\n        _102 = fa_vs_extra.data[gl_InstanceID].pos.w < (-1.0);\n    }\n    else\n    {\n        _102 = _87;\n    }\n    if (_102)\n    {\n        v.world_pos = vec3(1000000000.0);\n        return;\n    }\n    v.world_pos += fa_vs_points.data[gl_InstanceID].pos.xyz;\n    v.color = fa_vs_points.data[gl_InstanceID].tint;\n}\n\nmat4 fa_prev_model()\n{\n    return mat4(vec4(1.0, 0.0, 0.0, 0.0), vec4(0.0, 1.0, 0.0, 0.0), vec4(0.0, 0.0, 1.0, 0.0), vec4(0.0, 0.0, 0.0, 1.0));\n}\n\nvoid fa_prepass_vertex(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color, bool has_prev)\n{\n    bool _332;\n    if (has_prev)\n    {\n        _332 = fa_vel_params[8].x > 0.5;\n    }\n    else\n    {\n        _332 = has_prev;\n    }\n    fa_vtime = fa_time_now();\n    mat4 param = model;\n    vec3 param_1 = position;\n    vec3 param_2 = normal;\n    vec4 param_3 = tangent;\n    vec2 param_4 = texcoord0;\n    vec4 param_5 = color;\n    VertexData param_6 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    vertex(param_6);\n    mat4 _355 = mat4(fa_mesh_vs_params[4], fa_mesh_vs_params[5], fa_mesh_vs_params[6], fa_mesh_vs_params[7]);\n    vec4 _362 = vec4(param_6.world_pos, 1.0);\n    fa_world_pos = param_6.world_pos;\n    fa_world_normal = param_6.world_normal;\n    fa_world_tangent = param_6.world_tangent;\n    fa_uv = param_6.uv;\n    fa_vertex_color = param_6.color;\n    fa_pre_depth = -(_355 * _362).z;\n    fa_pre_r0 = vec3(_355[0].x, _355[1].x, _355[2].x);\n    fa_pre_r1 = vec3(_355[0].y, _355[1].y, _355[2].y);\n    fa_pre_r2 = vec3(_355[0].z, _355[1].z, _355[2].z);\n    gl_Position = mat4(fa_mesh_vs_params[0], fa_mesh_vs_params[1], fa_mesh_vs_params[2], fa_mesh_vs_params[3]) * _362;\n    fa_vel_cur = vec3(0.0, 0.0, 1.0);\n    fa_vel_prev = vec3(0.0);\n    if (_332)\n    {\n        fa_vtime.x = fa_vel_params[8].y;\n        mat4 param_7 = fa_prev_model();\n        vec3 param_8 = position;\n        vec3 param_9 = normal;\n        vec4 param_10 = tangent;\n        vec2 param_11 = texcoord0;\n        vec4 param_12 = color;\n        VertexData param_13 = fa_vertex_data(param_7, param_8, param_9, param_10, param_11, param_12);\n        vertex(param_13);\n        fa_vel_cur = vec3((mat4(fa_vel_params[0], fa_vel_params[1], fa_vel_params[2], fa_vel_params[3]) * _362).xyw);\n        fa_vel_prev = vec3((mat4(fa_vel_params[4], fa_vel_params[5], fa_vel_params[6], fa_vel_params[7]) * vec4(param_13.world_pos, 1.0)).xyw);\n    }\n}\n\nvoid main()\n{\n    fa_vtime = vec4(0.0);\n    fa_inst_begin();\n    vec4 param = fa_joints;\n    vec4 param_1 = fa_weights;\n    mat4 param_2 = mat4(fa_inst_base[0], fa_inst_base[1], fa_inst_base[2], fa_inst_base[3]) * fa_skin_matrix(param, param_1);\n    vec3 param_3 = fa_position;\n    vec3 param_4 = fa_normal;\n    vec4 param_5 = fa_tangent;\n    vec2 param_6 = fa_texcoord0;\n    vec4 param_7 = fa_color;\n    bool param_8 = false;\n    fa_prepass_vertex(param_2, param_3, param_4, param_5, param_6, param_7, param_8);\n}\n\n",
      "fs": "#version 430\n\nstruct SurfaceInput\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 vertex_color;\n    vec3 view_dir;\n    bool front_facing;\n};\n\nstruct Surface\n{\n    vec3 albedo;\n    float alpha;\n    vec3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    vec3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    vec3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    vec3 specular_color;\n    float transmission;\n    float thickness;\n    vec3 attenuation_color;\n    float attenuation_distance;\n};\n\nstruct points_item\n{\n    vec4 pos;\n    vec4 tint;\n};\n\nlayout(binding = 3, std430) readonly buffer fa_points_buf\n{\n    points_item data[];\n} points;\n\nuniform vec4 fa_mesh_fs_params[53];\nlayout(binding = 0) uniform sampler2D fa_tex_fa_smp;\nlayout(binding = 1) uniform sampler2D fa_normal_tex_fa_smp;\nlayout(binding = 2) uniform sampler2D fa_mr_tex_fa_smp;\nlayout(binding = 3) uniform sampler2D fa_occlusion_tex_fa_smp;\nlayout(binding = 4) uniform sampler2D fa_emissive_tex_fa_smp;\n\nlayout(location = 0) in vec3 fa_world_pos;\nlayout(location = 1) in vec3 fa_world_normal;\nlayout(location = 2) in vec4 fa_world_tangent;\nlayout(location = 3) in vec2 fa_uv;\nlayout(location = 4) in vec4 fa_vertex_color;\nlayout(location = 6) in vec3 fa_pre_r0;\nlayout(location = 7) in vec3 fa_pre_r1;\nlayout(location = 8) in vec3 fa_pre_r2;\nlayout(location = 0) out vec4 fa_frag_color;\nlayout(location = 5) in float fa_pre_depth;\nlayout(location = 9) in vec3 fa_vel_cur;\nlayout(location = 10) in vec3 fa_vel_prev;\nlayout(location = 1) out vec2 fa_frag_velocity;\n\nvoid fa_inst_load()\n{\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nvec3 fa_linear_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_tex_fix(inout vec3 c, float mode)\n{\n    if (mode > 1.5)\n    {\n        vec3 param = c;\n        vec3 _190 = fa_linear_to_srgb(param);\n        c = _190;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            vec3 param_1 = c;\n            vec3 _199 = fa_srgb_to_linear(param_1);\n            c = _199;\n        }\n    }\n    return c;\n}\n\nvec3 fa_tangent_normal(SurfaceInput i, vec3 m)\n{\n    vec3 _56;\n    if (i.front_facing)\n    {\n        _56 = i.world_normal;\n    }\n    else\n    {\n        _56 = -i.world_normal;\n    }\n    vec3 _81 = normalize(i.world_tangent.xyz - (_56 * dot(_56, i.world_tangent.xyz)));\n    vec3 _109 = normalize(((_81 * m.x) + ((cross(_56, _81) * i.world_tangent.w) * m.y)) + (_56 * m.z));\n    vec3 _112;\n    if (i.front_facing)\n    {\n        _112 = _109;\n    }\n    else\n    {\n        _112 = -_109;\n    }\n    return _112;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    vec4 base_t = texture(fa_tex_fa_smp, i.uv, fa_mesh_fs_params[12].w);\n    float param = fa_mesh_fs_params[6].w;\n    float param_1 = 1.0;\n    vec3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    vec3 _247 = fa_tex_fix(param_2, param_3);\n    vec4 _859 = base_t;\n    _859.x = _247.x;\n    _859.y = _247.y;\n    _859.z = _247.z;\n    base_t = _859;\n    vec4 _262 = (_859 * fa_mesh_fs_params[2]) * i.vertex_color;\n    vec3 _814 = i.world_normal;\n    if (fa_mesh_fs_params[6].z > 0.5)\n    {\n        float param_4 = fa_mesh_fs_params[6].w;\n        float param_5 = 16.0;\n        vec3 param_6 = texture(fa_normal_tex_fa_smp, i.uv, fa_mesh_fs_params[12].w).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        vec3 _297 = fa_tex_fix(param_6, param_7);\n        vec3 _301 = (_297 * 2.0) - vec3(1.0);\n        vec2 _306 = _301.xy * fa_mesh_fs_params[6].x;\n        vec3 _867 = _301;\n        _867.x = _306.x;\n        _867.y = _306.y;\n        SurfaceInput param_8 = i;\n        vec3 param_9 = _867;\n        _814 = fa_tangent_normal(param_8, param_9);\n    }\n    vec4 mrt = texture(fa_mr_tex_fa_smp, i.uv, fa_mesh_fs_params[12].w);\n    float param_10 = fa_mesh_fs_params[6].w;\n    float param_11 = 64.0;\n    vec3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    vec3 _337 = fa_tex_fix(param_12, param_13);\n    vec4 _870 = mrt;\n    _870.x = _337.x;\n    _870.y = _337.y;\n    _870.z = _337.z;\n    mrt = _870;\n    vec4 _369 = texture(fa_occlusion_tex_fa_smp, i.uv, fa_mesh_fs_params[12].w);\n    float param_14 = fa_mesh_fs_params[6].w;\n    float param_15 = 256.0;\n    vec3 param_16 = _369.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    vec3 _381 = fa_tex_fix(param_16, param_17);\n    float param_18 = fa_mesh_fs_params[6].w;\n    float param_19 = 4.0;\n    vec3 param_20 = texture(fa_emissive_tex_fa_smp, i.uv, fa_mesh_fs_params[12].w).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    vec3 _413 = fa_tex_fix(param_20, param_21);\n    float _819 = fa_mesh_fs_params[20].x;\n    float _820 = fa_mesh_fs_params[20].y;\n    float _823 = fa_mesh_fs_params[20].z;\n    float _822 = fa_mesh_fs_params[21].w;\n    float _825 = fa_mesh_fs_params[22].x;\n    if (fa_mesh_fs_params[22].z > 0.5)\n    {\n        if (mod(fa_mesh_fs_params[22].z, 2.0) > 0.5)\n        {\n            _819 *= _381.y;\n            _820 *= _381.z;\n            _822 *= _369.w;\n        }\n        if (fa_mesh_fs_params[22].z > 1.5)\n        {\n            _823 *= mrt.x;\n            _825 *= mrt.w;\n        }\n    }\n    return Surface(_262.xyz, _262.w, _814, clamp(fa_mesh_fs_params[5].x * _337.z, 0.0, 1.0), clamp(fa_mesh_fs_params[5].y * _337.y, 0.0500000007450580596923828125, 1.0), 1.0 + (fa_mesh_fs_params[6].y * (_381.x - 1.0)), fa_mesh_fs_params[3].xyz + (fa_mesh_fs_params[4].xyz * _413), _819, _820, fa_mesh_fs_params[21].xyz, _822, _823, fa_mesh_fs_params[20].w, _825, fa_mesh_fs_params[22].y, fa_mesh_fs_params[23].xyz, fa_mesh_fs_params[30].x, fa_mesh_fs_params[30].y, fa_mesh_fs_params[31].xyz, fa_mesh_fs_params[30].z);\n}\n\nvoid surface(SurfaceInput i, inout Surface s)\n{\n    s.emission += (i.vertex_color.xyz * points.data[0].tint.w);\n}\n\nvoid main()\n{\n    fa_inst_load();\n    vec3 _709 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _709 = -_709;\n    }\n    vec3 _565 = normalize(fa_mesh_fs_params[0].xyz - fa_world_pos);\n    SurfaceInput param = SurfaceInput(fa_world_pos, _709, fa_world_tangent, fa_uv, fa_vertex_color, _565, gl_FrontFacing);\n    SurfaceInput param_1 = SurfaceInput(fa_world_pos, _709, fa_world_tangent, fa_uv, fa_vertex_color, _565, gl_FrontFacing);\n    Surface param_2 = fa_standard_surface(param);\n    surface(param_1, param_2);\n    vec3 _580 = normalize(param_2.normal);\n    vec3 _595 = normalize(vec3(dot(fa_pre_r0, _580), dot(fa_pre_r1, _580), dot(fa_pre_r2, _580)));\n    float _607 = _595.z;\n    vec2 e = _595.xy / vec2((abs(_595.x) + abs(_595.y)) + abs(_607));\n    if (_607 < 0.0)\n    {\n        e = (vec2(1.0) - abs(e.yx)) * vec2((e.x >= 0.0) ? 1.0 : (-1.0), (e.y >= 0.0) ? 1.0 : (-1.0));\n    }\n    fa_frag_color = vec4(min(fa_pre_depth, 60000.0), e, 1.0);\n    vec2 motion = vec2(1024.0);\n    bool _651 = fa_vel_cur.z > 9.9999997473787516355514526367188e-06;\n    bool _658;\n    if (_651)\n    {\n        _658 = fa_vel_prev.z > 9.9999997473787516355514526367188e-06;\n    }\n    else\n    {\n        _658 = _651;\n    }\n    if (_658)\n    {\n        motion = clamp(((vec2(fa_vel_prev.x, -fa_vel_prev.y) / vec2(fa_vel_prev.z)) * 0.5) - ((vec2(fa_vel_cur.x, -fa_vel_cur.y) / vec2(fa_vel_cur.z)) * 0.5), vec2(-4.0), vec2(4.0));\n    }\n    fa_frag_velocity = motion;\n}\n\n",
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
            "inst_name": "_245",
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
            "inst_name": "_493",
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
            "inst_name": "_232",
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
