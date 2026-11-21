{
  "format": "factoria.shader/1",
  "engine": "0.32.0",
  "template": "ae26515a48b1a8d2e7a58b8583b7398bc5ad5b1e5314aaacf65f28e91c149fe7",
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
      "fs": "#version 430\n\nstruct SurfaceInput\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 vertex_color;\n    vec3 view_dir;\n    bool front_facing;\n};\n\nstruct LightSample\n{\n    vec3 direction;\n    vec3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct Surface\n{\n    vec3 albedo;\n    float alpha;\n    vec3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    vec3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    vec3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    vec3 specular_color;\n    float transmission;\n    float thickness;\n    vec3 attenuation_color;\n    float attenuation_distance;\n};\n\nstruct FaLayers\n{\n    bool on;\n    float f90;\n    float keep;\n    float base_scale;\n    float coat;\n    float coat_rough;\n    float coat_alpha;\n    float coat_a2;\n    vec3 nc;\n    float coat_ndv;\n    bool sheen_on;\n    vec3 sheen;\n    float sheen_rough;\n    float sheen_alpha;\n    float sheen_scale;\n    float sheen_e;\n    float aniso;\n    vec3 t;\n    vec3 b;\n    float at;\n    float ab;\n};\n\nconst float _4359[63] = float[](1.0, 1.0, 1.0, 0.4790000021457672119140625, 0.11699999868869781494140625, 0.01200000010430812835693359375, 0.0, 0.0, 0.0, 1.0, 1.0, 1.0, 0.578000009059906005859375, 0.19300000369548797607421875, 0.0350000001490116119384765625, 0.0030000000260770320892333984375, 0.0, 0.0, 1.0, 1.0, 1.0, 0.6740000247955322265625, 0.3459999859333038330078125, 0.1319999992847442626953125, 0.032999999821186065673828125, 0.0040000001899898052215576171875, 0.0, 0.971000015735626220703125, 0.954999983310699462890625, 0.828999996185302734375, 0.63999998569488525390625, 0.42599999904632568359375, 0.24500000476837158203125, 0.115000002086162567138671875, 0.037000000476837158203125, 0.0030000000260770320892333984375, 0.7469999790191650390625, 0.737999975681304931640625, 0.670000016689300537109375, 0.563000023365020751953125, 0.4309999942779541015625, 0.3039999902248382568359375, 0.1940000057220458984375, 0.1019999980926513671875, 0.0309999994933605194091796875, 0.614000022411346435546875, 0.609000027179718017578125, 0.566999971866607666015625, 0.499000012874603271484375, 0.412000000476837158203125, 0.32400000095367431640625, 0.240999996662139892578125, 0.162000000476837158203125, 0.087999999523162841796875, 0.538999974727630615234375, 0.535000026226043701171875, 0.505999982357025146484375, 0.4569999873638153076171875, 0.393999993801116943359375, 0.328999996185302734375, 0.2660000026226043701171875, 0.203999996185302734375, 0.14200000464916229248046875);\n\nuniform vec4 fa_mesh_fs_params[53];\nuniform vec4 fa_shadows[30];\nuniform vec4 fa_material[1];\nlayout(binding = 0) uniform sampler2D fa_light_tex_fa_shadow_smp;\nlayout(binding = 1) uniform sampler2D fa_tex_fa_smp;\nlayout(binding = 2) uniform sampler2D fa_normal_tex_fa_smp;\nlayout(binding = 3) uniform sampler2D fa_mr_tex_fa_smp;\nlayout(binding = 4) uniform sampler2D fa_occlusion_tex_fa_smp;\nlayout(binding = 5) uniform sampler2D fa_emissive_tex_fa_smp;\nlayout(binding = 6) uniform sampler2D fa_decal_tex_fa_env_smp;\nlayout(binding = 7) uniform sampler2D fa_lightmap_fa_env_smp;\nlayout(binding = 8) uniform sampler2D fa_probe_atlas_fa_env_smp;\nlayout(binding = 9) uniform sampler2D fa_light_atlas_fa_env_smp;\nlayout(binding = 10) uniform sampler2D fa_shadow_tex_fa_shadow_smp;\nlayout(binding = 11) uniform sampler2D fa_screen_tex_fa_shadow_smp;\n\nlayout(location = 2) in vec3 fa_world_pos;\nlayout(location = 7) in vec3 fa_lm;\nlayout(location = 0) flat in vec4 fa_inst_v0;\nlayout(location = 1) flat in vec4 fa_inst_v1;\nlayout(location = 3) in vec3 fa_world_normal;\nlayout(location = 4) in vec4 fa_world_tangent;\nlayout(location = 5) in vec2 fa_uv;\nlayout(location = 6) in vec4 fa_vertex_color;\nlayout(location = 0) out vec4 fa_frag_color;\nvec3 fa_light_tint;\nbool fa_light_is_area;\nint fa_cl_ndir;\nint fa_cl_slot;\nint fa_cl_local;\nfloat raise;\nvec4 tint;\n\nvoid fa_instance_unpack(vec4 fa_d0, vec4 fa_d1, vec4 fa_d2)\n{\n    raise = fa_d0.x;\n    tint = fa_d1;\n}\n\nvoid fa_inst_load()\n{\n    vec4 param = fa_inst_v0;\n    vec4 param_1 = fa_inst_v1;\n    vec4 param_2 = vec4(0.0);\n    fa_instance_unpack(param, param_1, param_2);\n}\n\nvec4 fa_light_texel(int t)\n{\n    return texelFetch(fa_light_tex_fa_shadow_smp, ivec2(t & 1023, t >> 10), 0);\n}\n\nvec4 fa_cluster_texel(vec3 world_pos)\n{\n    bool _1597 = fa_mesh_fs_params[19].x < 0.0;\n    bool _1604;\n    if (!_1597)\n    {\n        _1604 = fa_mesh_fs_params[19].w < 1.0;\n    }\n    else\n    {\n        _1604 = _1597;\n    }\n    bool _1612;\n    if (!_1604)\n    {\n        _1612 = fa_mesh_fs_params[18].x < 1.0;\n    }\n    else\n    {\n        _1612 = _1604;\n    }\n    bool _1619;\n    if (!_1612)\n    {\n        _1619 = fa_mesh_fs_params[18].y < 1.0;\n    }\n    else\n    {\n        _1619 = _1612;\n    }\n    bool _1626;\n    if (!_1619)\n    {\n        _1626 = fa_mesh_fs_params[19].y < 1.0;\n    }\n    else\n    {\n        _1626 = _1619;\n    }\n    if (_1626)\n    {\n        return vec4(0.0);\n    }\n    vec4 _1636 = vec4(world_pos, 1.0);\n    float _1642 = dot(fa_mesh_fs_params[16], _1636);\n    if (!(_1642 > 9.9999999747524270787835121154785e-07))\n    {\n        return vec4(0.0);\n    }\n    vec2 _1664 = vec2(dot(fa_mesh_fs_params[14], _1636), dot(fa_mesh_fs_params[15], _1636)) / vec2(_1642);\n    int _1668 = int(fa_mesh_fs_params[18].x);\n    int _1672 = int(fa_mesh_fs_params[18].y);\n    int param = (int(fa_mesh_fs_params[19].x) + (((clamp(int(floor(log2(max(dot(fa_mesh_fs_params[17].xyz, world_pos) + fa_mesh_fs_params[17].w, fa_mesh_fs_params[18].w) / fa_mesh_fs_params[18].w) * fa_mesh_fs_params[18].z)), 0, int(fa_mesh_fs_params[19].y) - 1) * _1672) + clamp(int(floor(((_1664.y * 0.5) + 0.5) * fa_mesh_fs_params[18].y)), 0, _1672 - 1)) * _1668)) + clamp(int(floor(((_1664.x * 0.5) + 0.5) * fa_mesh_fs_params[18].x)), 0, _1668 - 1);\n    return fa_light_texel(param);\n}\n\nivec2 fa_cluster_lookup(vec3 world_pos)\n{\n    vec3 param = world_pos;\n    vec4 _1748 = fa_cluster_texel(param);\n    return ivec2(int(_1748.x), int(_1748.y));\n}\n\nvoid fa_cluster_begin(vec3 world_pos)\n{\n    fa_cl_ndir = int(fa_mesh_fs_params[19].z);\n    vec3 param = world_pos;\n    ivec2 _5834 = fa_cluster_lookup(param);\n    fa_cl_slot = _5834.x;\n    fa_cl_local = _5834.y;\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nvec3 fa_linear_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_tex_fix(inout vec3 c, float mode)\n{\n    if (mode > 1.5)\n    {\n        vec3 param = c;\n        vec3 _6997 = fa_linear_to_srgb(param);\n        c = _6997;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            vec3 param_1 = c;\n            vec3 _7005 = fa_srgb_to_linear(param_1);\n            c = _7005;\n        }\n    }\n    return c;\n}\n\nvec3 fa_tangent_normal(SurfaceInput i, vec3 m)\n{\n    vec3 _541;\n    if (i.front_facing)\n    {\n        _541 = i.world_normal;\n    }\n    else\n    {\n        _541 = -i.world_normal;\n    }\n    vec3 _565 = normalize(i.world_tangent.xyz - (_541 * dot(_541, i.world_tangent.xyz)));\n    vec3 _592 = normalize(((_565 * m.x) + ((cross(_541, _565) * i.world_tangent.w) * m.y)) + (_541 * m.z));\n    vec3 _595;\n    if (i.front_facing)\n    {\n        _595 = _592;\n    }\n    else\n    {\n        _595 = -_592;\n    }\n    return _595;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    vec4 base_t = texture(fa_tex_fa_smp, i.uv);\n    float param = fa_mesh_fs_params[6].w;\n    float param_1 = 1.0;\n    vec3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    vec3 _7036 = fa_tex_fix(param_2, param_3);\n    vec4 _9294 = base_t;\n    _9294.x = _7036.x;\n    _9294.y = _7036.y;\n    _9294.z = _7036.z;\n    base_t = _9294;\n    vec4 _7050 = (_9294 * fa_mesh_fs_params[2]) * i.vertex_color;\n    vec3 _9078 = i.world_normal;\n    if (fa_mesh_fs_params[6].z > 0.5)\n    {\n        float param_4 = fa_mesh_fs_params[6].w;\n        float param_5 = 16.0;\n        vec3 param_6 = texture(fa_normal_tex_fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        vec3 _7082 = fa_tex_fix(param_6, param_7);\n        vec3 _7085 = (_7082 * 2.0) - vec3(1.0);\n        vec2 _7090 = _7085.xy * fa_mesh_fs_params[6].x;\n        vec3 _9302 = _7085;\n        _9302.x = _7090.x;\n        _9302.y = _7090.y;\n        SurfaceInput param_8 = i;\n        vec3 param_9 = _9302;\n        _9078 = fa_tangent_normal(param_8, param_9);\n    }\n    vec4 mrt = texture(fa_mr_tex_fa_smp, i.uv);\n    float param_10 = fa_mesh_fs_params[6].w;\n    float param_11 = 64.0;\n    vec3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    vec3 _7118 = fa_tex_fix(param_12, param_13);\n    vec4 _9305 = mrt;\n    _9305.x = _7118.x;\n    _9305.y = _7118.y;\n    _9305.z = _7118.z;\n    mrt = _9305;\n    vec4 _7146 = texture(fa_occlusion_tex_fa_smp, i.uv);\n    float param_14 = fa_mesh_fs_params[6].w;\n    float param_15 = 256.0;\n    vec3 param_16 = _7146.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    vec3 _7157 = fa_tex_fix(param_16, param_17);\n    float param_18 = fa_mesh_fs_params[6].w;\n    float param_19 = 4.0;\n    vec3 param_20 = texture(fa_emissive_tex_fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    vec3 _7187 = fa_tex_fix(param_20, param_21);\n    float _9083 = fa_mesh_fs_params[20].x;\n    float _9084 = fa_mesh_fs_params[20].y;\n    float _9087 = fa_mesh_fs_params[20].z;\n    float _9086 = fa_mesh_fs_params[21].w;\n    float _9089 = fa_mesh_fs_params[22].x;\n    if (fa_mesh_fs_params[22].z > 0.5)\n    {\n        if (mod(fa_mesh_fs_params[22].z, 2.0) > 0.5)\n        {\n            _9083 *= _7157.y;\n            _9084 *= _7157.z;\n            _9086 *= _7146.w;\n        }\n        if (fa_mesh_fs_params[22].z > 1.5)\n        {\n            _9087 *= mrt.x;\n            _9089 *= mrt.w;\n        }\n    }\n    return Surface(_7050.xyz, _7050.w, _9078, clamp(fa_mesh_fs_params[5].x * _7118.z, 0.0, 1.0), clamp(fa_mesh_fs_params[5].y * _7118.y, 0.0500000007450580596923828125, 1.0), 1.0 + (fa_mesh_fs_params[6].y * (_7157.x - 1.0)), fa_mesh_fs_params[3].xyz + (fa_mesh_fs_params[4].xyz * _7187), _9083, _9084, fa_mesh_fs_params[21].xyz, _9086, _9087, fa_mesh_fs_params[20].w, _9089, fa_mesh_fs_params[22].y, fa_mesh_fs_params[23].xyz, fa_mesh_fs_params[30].x, fa_mesh_fs_params[30].y, fa_mesh_fs_params[31].xyz, fa_mesh_fs_params[30].z);\n}\n\nvoid surface(SurfaceInput i, inout Surface s)\n{\n    s.emission += ((tint.xyz * tint.w) * fa_material[0].x);\n}\n\nvec4 fa_decal_tile(vec4 rect, vec2 uv, vec2 atlas, vec2 ddx, vec2 ddy)\n{\n    vec2 _1828 = rect.zw - rect.xy;\n    vec2 _1832 = _1828 * atlas;\n    vec2 _1836 = ddx * _1832;\n    vec2 _1840 = ddy * _1832;\n    return textureLod(fa_decal_tex_fa_env_smp, rect.xy + (clamp(uv, vec2(0.0), vec2(1.0)) * _1828), clamp(0.5 * log2(max(max(dot(_1836, _1836), dot(_1840, _1840)), 9.9999999392252902907785028219223e-09)), 0.0, 3.0));\n}\n\nvec3 fa_dc_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_dc_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvoid fa_apply_decals(vec3 world_pos, vec3 geo_normal, inout vec3 albedo, inout vec3 normal)\n{\n    bool _1873 = fa_mesh_fs_params[10].y < 0.5;\n    bool _1880;\n    if (!_1873)\n    {\n        _1880 = fa_mesh_fs_params[10].w < 0.5;\n    }\n    else\n    {\n        _1880 = _1873;\n    }\n    if (_1880)\n    {\n        return;\n    }\n    vec3 _1886 = dFdx(world_pos);\n    vec3 _1889 = dFdy(world_pos);\n    vec3 param = world_pos;\n    vec4 _1893 = fa_cluster_texel(param);\n    int _1897 = int(_1893.w);\n    if (_1897 < 1)\n    {\n        return;\n    }\n    int _1907 = int(fa_mesh_fs_params[10].y + 0.5);\n    int param_1 = _1907;\n    vec4 _1911 = fa_light_texel(param_1);\n    vec2 _1914 = _1911.yz;\n    int _1918 = int(_1911.w);\n    int param_2 = _1907 + 1;\n    vec4 _1923 = fa_light_texel(param_2);\n    float _1924 = _1923.x;\n    int _1930 = int(fa_mesh_fs_params[10].w + 0.5) - 1;\n    int _1934 = int(_1893.z);\n    vec3 _2199;\n    for (int k = 0; k < _1897; k++)\n    {\n        int _1947 = _1934 + k;\n        int param_3 = _1918 + (_1947 >> 2);\n        int _1964 = (_1907 + 2) + (int(fa_light_texel(param_3)[_1947 & 3]) * 7);\n        int param_4 = _1964 + 6;\n        vec4 _1969 = fa_light_texel(param_4);\n        if (((int(_1969.w + 0.5) >> _1930) & 1) == 0)\n        {\n            continue;\n        }\n        int param_5 = _1964;\n        vec4 _1984 = fa_light_texel(param_5);\n        int param_6 = _1964 + 1;\n        vec4 _1989 = fa_light_texel(param_6);\n        int param_7 = _1964 + 2;\n        vec4 _1994 = fa_light_texel(param_7);\n        vec3 _1997 = _1984.xyz;\n        float _2002 = dot(_1997, world_pos) + _1984.w;\n        vec3 _2004 = _1989.xyz;\n        float _2009 = dot(_2004, world_pos) + _1989.w;\n        vec3 _2011 = _1994.xyz;\n        float _2016 = dot(_2011, world_pos) + _1994.w;\n        bool _2021 = abs(_2002) > 0.5;\n        bool _2029;\n        if (!_2021)\n        {\n            _2029 = abs(_2009) > 0.5;\n        }\n        else\n        {\n            _2029 = _2021;\n        }\n        bool _2037;\n        if (!_2029)\n        {\n            _2037 = abs(_2016) > 0.5;\n        }\n        else\n        {\n            _2037 = _2029;\n        }\n        if (_2037)\n        {\n            continue;\n        }\n        float _2052 = clamp(dot(geo_normal, normalize(_2011)) * _1969.z, 0.0, 1.0);\n        if (_2052 <= 0.0)\n        {\n            continue;\n        }\n        float _2072 = (clamp((0.5 - abs(_2016)) * 10.0, 0.0, 1.0) * _2052) * _1969.x;\n        vec2 _2080 = vec2(_2002 + 0.5, 0.5 - _2009);\n        vec2 _2090 = vec2(dot(_1997, _1886), dot(_2004, _1886));\n        vec2 _2100 = vec2(dot(_1997, _1889), dot(_2004, _1889));\n        int param_8 = _1964 + 5;\n        vec4 _2105 = fa_light_texel(param_8);\n        int param_9 = _1964 + 3;\n        vec4 _2110 = fa_light_texel(param_9);\n        int param_10 = _1964 + 4;\n        vec4 _2115 = fa_light_texel(param_10);\n        float tex_a = 1.0;\n        vec3 col = _2105.xyz;\n        bool _2125 = _2110.z > _2110.x;\n        if (_2125)\n        {\n            vec4 param_11 = _2110;\n            vec2 param_12 = _2080;\n            vec2 param_13 = _1914;\n            vec2 param_14 = _2090;\n            vec2 param_15 = _2100;\n            vec4 tx = fa_decal_tile(param_11, param_12, param_13, param_14, param_15);\n            if ((_1924 > 0.5) && (_1924 < 1.5))\n            {\n                vec3 param_16 = tx.xyz;\n                vec3 _2151 = fa_dc_to_linear(param_16);\n                vec4 _9166 = tx;\n                _9166.x = _2151.x;\n                _9166.y = _2151.y;\n                _9166.z = _2151.z;\n                tx = _9166;\n            }\n            col *= tx.xyz;\n            tex_a = tx.w;\n        }\n        albedo = mix(albedo, col, vec3(clamp((_2072 * tex_a) * _2105.w, 0.0, 1.0)));\n        if (_2115.z > _2115.x)\n        {\n            vec4 param_17 = _2115;\n            vec2 param_18 = _2080;\n            vec2 param_19 = _1914;\n            vec2 param_20 = _2090;\n            vec2 param_21 = _2100;\n            vec4 _2195 = fa_decal_tile(param_17, param_18, param_19, param_20, param_21);\n            if (_1924 > 1.5)\n            {\n                vec3 param_22 = _2195.xyz;\n                vec3 _2205 = fa_dc_to_srgb(param_22);\n                _2199 = _2205;\n            }\n            else\n            {\n                _2199 = _2195.xyz;\n            }\n            vec3 _2214 = (_2199 * 2.0) - vec3(1.0);\n            vec2 _2219 = _2214.xy * _1969.y;\n            vec3 _2241 = (normalize(_1997) * _2219.x) + (normalize(_2004) * _2219.y);\n            vec3 _2244 = normalize(normal);\n            normal = normalize(mix(_2244, normalize((_2244 * max(_2214.z, 0.0500000007450580596923828125)) + (_2241 - (_2244 * dot(_2244, _2241)))), vec3(clamp(_2072 * (_2125 ? tex_a : 1.0), 0.0, 1.0))));\n        }\n    }\n}\n\nfloat fa_sheen_albedo(float ndv, float rough)\n{\n    float _4284 = min(sqrt(max(rough - 0.100000001490116119384765625, 0.0) * 1.111111164093017578125) * 6.0, 5.999000072479248046875);\n    float _4292 = min(sqrt(clamp(ndv, 0.0, 1.0)) * 8.0, 7.999000072479248046875);\n    int _4295 = int(_4284);\n    int _4298 = int(_4292);\n    float _4308 = _4292 - float(_4298);\n    int _4363 = (_4295 * 9) + _4298;\n    int _4383 = ((_4295 + 1) * 9) + _4298;\n    return mix(mix(_4359[_4363], _4359[_4363 + 1], _4308), mix(_4359[_4383], _4359[_4383 + 1], _4308), _4284 - float(_4295));\n}\n\nFaLayers fa_layers_setup(SurfaceInput i, Surface s, vec3 n, vec3 v, float metallic, float roughness, inout vec3 f0)\n{\n    bool _9001 = false;\n    float _9002 = 1.0;\n    float _9003 = 1.0;\n    float _9004 = 1.0;\n    float _9005 = 0.0;\n    float _9006 = 0.0;\n    float _9007 = 0.0;\n    float _9008 = 0.0;\n    float _9010 = 1.0;\n    bool _9011 = false;\n    vec3 _9012 = vec3(0.0);\n    float _9013 = 1.0;\n    float _9014 = 1.0;\n    float _9015 = 1.0;\n    float _9016 = 0.0;\n    float _9017 = 0.0;\n    vec3 _9018 = vec3(1.0, 0.0, 0.0);\n    vec3 _9019 = vec3(0.0, 0.0, 1.0);\n    float _9020 = 1.0;\n    float _9021 = 1.0;\n    float _4434 = clamp(s.specular, 0.0, 1.0);\n    float _4438 = clamp(s.ior, 1.0, 3.0);\n    bool _4443 = (_4434 != 1.0) || (_4438 != 1.5);\n    bool _4452;\n    if (!_4443)\n    {\n        _4452 = any(notEqual(s.specular_color, vec3(1.0)));\n    }\n    else\n    {\n        _4452 = _4443;\n    }\n    if (_4452)\n    {\n        float _4460 = (_4438 - 1.0) / (_4438 + 1.0);\n        f0 = mix(min(vec3(_4460 * _4460) * max(s.specular_color, vec3(0.0)), vec3(1.0)) * _4434, s.albedo, vec3(metallic));\n        _9002 = mix(_4434, 1.0, metallic);\n        _9001 = true;\n    }\n    float _4487 = clamp(s.clearcoat, 0.0, 1.0);\n    if (_4487 > 0.0)\n    {\n        float _4495 = clamp(s.clearcoat_roughness, 0.0500000007450580596923828125, 1.0);\n        _9005 = _4487;\n        _9006 = _4495;\n        float _4502 = _4495 * _4495;\n        _9007 = _4502;\n        _9008 = _4502 * _4502;\n        float _4514 = max(dot(i.world_normal, v), 9.9999997473787516355514526367188e-05);\n        _9010 = _4514;\n        _9003 = 1.0 - (_4487 * (0.039999999105930328369140625 + (0.959999978542327880859375 * pow(clamp(1.0 - _4514, 0.0, 1.0), 5.0))));\n        _9001 = true;\n    }\n    vec3 _4533 = max(s.sheen_color, vec3(0.0));\n    float _4542 = max(_4533.x, max(_4533.y, _4533.z));\n    if (_4542 > 0.0)\n    {\n        float _4550 = clamp(s.sheen_roughness, 0.100000001490116119384765625, 1.0);\n        _9011 = true;\n        _9012 = _4533;\n        _9013 = _4550;\n        _9014 = _4550 * _4550;\n        float param = max(dot(n, v), 9.9999997473787516355514526367188e-05);\n        float param_1 = _4550;\n        float _4567 = fa_sheen_albedo(param, param_1);\n        _9016 = _4567;\n        _9015 = 1.0 - min(_4542 * _4567, 1.0);\n        _9001 = true;\n    }\n    _9004 = _9003 * _9015;\n    float _4586 = clamp(s.anisotropy, -1.0, 1.0);\n    if (_4586 != 0.0)\n    {\n        vec3 _4601 = i.world_tangent.xyz - (n * dot(n, i.world_tangent.xyz));\n        vec3 t = _4601;\n        if (dot(_4601, _4601) < 9.9999999392252902907785028219223e-09)\n        {\n            bvec3 _4613 = bvec3(abs(n.y) < 0.9900000095367431640625);\n            t = cross(vec3(_4613.x ? vec3(0.0, 1.0, 0.0).x : vec3(1.0, 0.0, 0.0).x, _4613.y ? vec3(0.0, 1.0, 0.0).y : vec3(1.0, 0.0, 0.0).y, _4613.z ? vec3(0.0, 1.0, 0.0).z : vec3(1.0, 0.0, 0.0).z), n);\n        }\n        vec3 _4617 = t;\n        vec3 _4618 = normalize(_4617);\n        t = _4618;\n        vec3 _4643 = normalize((_4618 * cos(s.anisotropy_rotation)) + ((cross(n, _4618) * ((i.world_tangent.w < 0.0) ? (-1.0) : 1.0)) * sin(s.anisotropy_rotation)));\n        _9018 = _4643;\n        _9019 = cross(n, _4643);\n        float _4653 = roughness * roughness;\n        float _4659 = mix(_4653, 1.0, _4586 * _4586);\n        bool _4661 = _4586 > 0.0;\n        _9020 = _4661 ? _4659 : _4653;\n        _9021 = _4661 ? _4653 : _4659;\n        _9017 = _4586;\n        _9001 = true;\n    }\n    return FaLayers(_9001, _9002, _9003, _9004, _9005, _9006, _9007, _9008, i.world_normal, _9010, _9011, _9012, _9013, _9014, _9015, _9016, _9017, _9018, _9019, _9020, _9021);\n}\n\nvec2 fa_atlas_size()\n{\n    return vec2(textureSize(fa_probe_atlas_fa_env_smp, 0));\n}\n\nvec3 fa_probe_sh_coef(vec2 origin, float res, int k)\n{\n    vec3 v = textureLod(fa_probe_atlas_fa_env_smp, (origin + vec2(float(k) + 0.5, res + 2.5)) / fa_atlas_size(), 0.0).xyz;\n    if (fa_mesh_fs_params[41].y > 0.5)\n    {\n        v = ((v * 255.0) - vec3(128.0)) * 0.03149606287479400634765625;\n    }\n    return v;\n}\n\nvec3 fa_sh_eval(vec3 c[9], vec3 n)\n{\n    vec3 _3452 = max((((c[0] * 0.2820948064327239990234375) + (((c[1] * (0.3257350027561187744140625 * n.y)) + (c[2] * (0.3257350027561187744140625 * n.z))) + (c[3] * (0.3257350027561187744140625 * n.x)))) + (((c[4] * ((0.2731371223926544189453125 * n.x) * n.y)) + (c[5] * ((0.2731371223926544189453125 * n.y) * n.z))) + (c[6] * (0.078847892582416534423828125 * (((3.0 * n.z) * n.z) - 1.0))))) + ((c[7] * ((0.2731371223926544189453125 * n.x) * n.z)) + (c[8] * (0.13656856119632720947265625 * ((n.x * n.x) - (n.y * n.y))))), vec3(0.0));\n    return _3452;\n}\n\nvec3 fa_ambient_light(vec3 n)\n{\n    float _4065 = (1.0 - fa_mesh_fs_params[42].w) - fa_mesh_fs_params[47].w;\n    vec3 amb = vec3(0.0);\n    bool _4070 = fa_mesh_fs_params[11].w > 0.5;\n    vec3 c[9];\n    for (int k = 0; k < 9; k++)\n    {\n        c[k] = vec3(0.0);\n    }\n    if (_4065 > 0.0005000000237487256526947021484375)\n    {\n        if (_4070)\n        {\n            for (int k_1 = 0; k_1 < 9; k_1++)\n            {\n                vec2 param = fa_mesh_fs_params[41].zw;\n                float param_1 = 128.0;\n                int param_2 = k_1;\n                c[k_1] = fa_probe_sh_coef(param, param_1, param_2) * _4065;\n            }\n        }\n        else\n        {\n            amb = fa_mesh_fs_params[1].xyz * _4065;\n        }\n    }\n    bool _4121 = fa_mesh_fs_params[42].w > 0.0;\n    if (_4121)\n    {\n        for (int k_2 = 0; k_2 < 9; k_2++)\n        {\n            vec2 param_3 = fa_mesh_fs_params[42].xy;\n            float param_4 = fa_mesh_fs_params[42].z;\n            int param_5 = k_2;\n            c[k_2] += (fa_probe_sh_coef(param_3, param_4, param_5) * fa_mesh_fs_params[42].w);\n        }\n    }\n    bool _4152 = fa_mesh_fs_params[47].w > 0.0;\n    if (_4152)\n    {\n        for (int k_3 = 0; k_3 < 9; k_3++)\n        {\n            vec2 param_6 = fa_mesh_fs_params[47].xy;\n            float param_7 = fa_mesh_fs_params[47].z;\n            int param_8 = k_3;\n            c[k_3] += (fa_probe_sh_coef(param_6, param_7, param_8) * fa_mesh_fs_params[47].w);\n        }\n    }\n    if ((_4070 || _4121) || _4152)\n    {\n        vec3 param_9[9] = c;\n        vec3 param_10 = n;\n        amb += fa_sh_eval(param_9, param_10);\n    }\n    return amb;\n}\n\nvec4 fa_gi_fetch(vec2 texel)\n{\n    return textureLod(fa_probe_atlas_fa_env_smp, texel / fa_atlas_size(), 0.0);\n}\n\nvec2 fa_oct_encode(vec3 d)\n{\n    vec3 _3472 = d / vec3(max((abs(d.x) + abs(d.y)) + abs(d.z), 9.9999999600419720025001879548654e-13));\n    float _3475 = _3472.x;\n    float _3477 = _3472.z;\n    vec2 e = vec2(_3475, _3477);\n    if (_3472.y < 0.0)\n    {\n        e = vec2((1.0 - abs(_3477)) * ((_3475 < 0.0) ? (-1.0) : 1.0), (1.0 - abs(_3475)) * ((_3477 < 0.0) ? (-1.0) : 1.0));\n    }\n    return e;\n}\n\nvec3 fa_gi_grid(int rec, vec3 n, vec3 v, out float cover)\n{\n    cover = 0.0;\n    int param = rec;\n    vec4 _7297 = fa_light_texel(param);\n    int param_1 = rec + 1;\n    vec4 _7302 = fa_light_texel(param_1);\n    int param_2 = rec + 2;\n    vec4 _7307 = fa_light_texel(param_2);\n    int param_3 = rec + 3;\n    vec4 _7312 = fa_light_texel(param_3);\n    bool _7315 = _7312.z < 0.5;\n    bool _7323;\n    if (!_7315)\n    {\n        _7323 = fa_atlas_size().y < 1155.0;\n    }\n    else\n    {\n        _7323 = _7315;\n    }\n    if (_7323)\n    {\n        return vec3(0.0);\n    }\n    float _7330 = max(_7297.w, 9.9999997473787516355514526367188e-05);\n    vec3 _7333 = _7302.xyz;\n    vec3 _7337 = _7297.xyz;\n    vec3 _7341 = (fa_world_pos - _7337) / vec3(_7330);\n    vec3 _7350 = min(_7341 + vec3(0.5), (_7333 - vec3(0.5)) - _7341);\n    float _7359 = min(_7350.x, min(_7350.y, _7350.z));\n    if (!(_7359 > 0.0))\n    {\n        return vec3(0.0);\n    }\n    vec3 _7374 = _7333 - vec3(1.0);\n    vec3 _7375 = clamp(_7341, vec3(0.0), _7374);\n    vec3 _7383 = min(floor(_7375), max(_7333 - vec3(2.0), vec3(0.0)));\n    vec3 _7387 = _7375 - _7383;\n    vec3 _7398 = fa_world_pos + (((n * 0.800000011920928955078125) + (v * 0.20000000298023223876953125)) * (0.20000000298023223876953125 * _7330));\n    int _7403 = int(_7307.y + 0.5);\n    float _7408 = 0.3257350027561187744140625 * n.y;\n    float _7412 = 0.3257350027561187744140625 * n.z;\n    float _7416 = 0.3257350027561187744140625 * n.x;\n    float _7423 = (0.2731371223926544189453125 * n.x) * n.y;\n    float _7430 = (0.2731371223926544189453125 * n.y) * n.z;\n    float _7439 = 0.078847892582416534423828125 * (((3.0 * n.z) * n.z) - 1.0);\n    float _7446 = (0.2731371223926544189453125 * n.x) * n.z;\n    float _7459 = 0.13656856119632720947265625 * ((n.x * n.x) - (n.y * n.y));\n    vec3 acc = vec3(0.0);\n    float wsum = 0.0;\n    int _7466 = 8 + int(_7312.w);\n    float _7493;\n    float _7506;\n    float _7520;\n    for (int k = 0; k < _7466; k++)\n    {\n        float _7479 = float(k & 1);\n        float _7483 = float((k >> 1) & 1);\n        float _7487 = float((k >> 2) & 1);\n        if (_7479 > 0.5)\n        {\n            _7493 = _7387.x;\n        }\n        else\n        {\n            _7493 = 1.0 - _7387.x;\n        }\n        if (_7483 > 0.5)\n        {\n            _7506 = _7387.y;\n        }\n        else\n        {\n            _7506 = 1.0 - _7387.y;\n        }\n        if (_7487 > 0.5)\n        {\n            _7520 = _7387.z;\n        }\n        else\n        {\n            _7520 = 1.0 - _7387.z;\n        }\n        float _7530 = (_7493 * _7506) * _7520;\n        if (!(_7530 > 0.0))\n        {\n            continue;\n        }\n        vec3 _7543 = min(_7383 + vec3(_7479, _7483, _7487), _7374);\n        int _7563 = int(((_7307.x + _7543.x) + (_7302.x * (_7543.y + (_7302.y * _7543.z)))) + 0.5);\n        vec2 _7578 = vec2(float(_7563 % _7403) * 10.0, 1024.0 + (float(_7563 / _7403) * 11.0));\n        vec2 param_4 = _7578 + vec2(9.5, 10.5);\n        vec4 _7586 = fa_gi_fetch(param_4);\n        bool _7589 = _7586.y < 0.5;\n        bool _7598;\n        if (!_7589)\n        {\n            _7598 = _7586.x > _7312.y;\n        }\n        else\n        {\n            _7598 = _7589;\n        }\n        if (_7598)\n        {\n            continue;\n        }\n        vec3 _7610 = _7398 - (_7337 + (_7543 * _7330));\n        float _7613 = length(_7610);\n        vec3 _7619 = _7610 / vec3(max(_7613, 9.9999997473787516355514526367188e-05));\n        float _7629 = max(9.9999997473787516355514526367188e-05, (dot(-_7619, n) + 1.0) * 0.5);\n        float w = _7530 * (_7629 * _7629);\n        vec3 param_5 = _7619;\n        vec2 param_6 = (_7578 + vec2(1.0)) + (((fa_oct_encode(param_5) * 0.5) + vec2(0.5)) * 8.0);\n        vec4 _7648 = fa_gi_fetch(param_6);\n        float _7655 = _7613 / max(_7307.z, 9.9999997473787516355514526367188e-05);\n        float _7658 = _7648.x;\n        if (_7655 > _7658)\n        {\n            float _7671 = max(_7648.y - (_7658 * _7658), 0.0);\n            float _7676 = _7655 - _7658;\n            float _7685 = _7671 / max(_7671 + (_7676 * _7676), 9.9999999600419720025001879548654e-13);\n            w *= ((_7685 * _7685) * _7685);\n        }\n        if (!(w > 0.0))\n        {\n            continue;\n        }\n        vec2 param_7 = _7578 + vec2(0.5, 10.5);\n        vec2 param_8 = _7578 + vec2(1.5, 10.5);\n        vec2 param_9 = _7578 + vec2(2.5, 10.5);\n        vec2 param_10 = _7578 + vec2(3.5, 10.5);\n        vec2 param_11 = _7578 + vec2(4.5, 10.5);\n        vec2 param_12 = _7578 + vec2(5.5, 10.5);\n        vec2 param_13 = _7578 + vec2(6.5, 10.5);\n        vec2 param_14 = _7578 + vec2(7.5, 10.5);\n        vec2 param_15 = _7578 + vec2(8.5, 10.5);\n        acc += ((((((((((fa_gi_fetch(param_7).xyz * 0.2820948064327239990234375) + (fa_gi_fetch(param_8).xyz * _7408)) + (fa_gi_fetch(param_9).xyz * _7412)) + (fa_gi_fetch(param_10).xyz * _7416)) + (fa_gi_fetch(param_11).xyz * _7423)) + (fa_gi_fetch(param_12).xyz * _7430)) + (fa_gi_fetch(param_13).xyz * _7439)) + (fa_gi_fetch(param_14).xyz * _7446)) + (fa_gi_fetch(param_15).xyz * _7459)) * w);\n        wsum += w;\n    }\n    if (!(wsum > 9.9999997473787516355514526367188e-06))\n    {\n        return vec3(0.0);\n    }\n    cover = smoothstep(0.0, 1.0, clamp(_7359 * 2.0, 0.0, 1.0)) * smoothstep(0.0, 0.0199999995529651641845703125, wsum);\n    float _7810;\n    if (fa_mesh_fs_params[52].z > 0.5)\n    {\n        _7810 = _7312.x;\n    }\n    else\n    {\n        _7810 = 1.0;\n    }\n    return max(acc / vec3(wsum), vec3(0.0)) * (_7307.w * _7810);\n}\n\nvec3 fa_gi_light(vec3 n, inout float left)\n{\n    left = 1.0;\n    vec3 acc = vec3(0.0);\n    vec3 _7834 = normalize(fa_mesh_fs_params[0].xyz - fa_world_pos);\n    int _7839 = int(fa_mesh_fs_params[52].x + 0.5);\n    int _7844 = int(fa_mesh_fs_params[52].y + 0.5);\n    float param_3;\n    for (int k = 0; (k < _7844) && (k < 8); k++)\n    {\n        int param = _7839 + (4 * k);\n        vec3 param_1 = n;\n        vec3 param_2 = _7834;\n        vec3 _7869 = fa_gi_grid(param, param_1, param_2, param_3);\n        float _7874 = param_3 * left;\n        acc += (_7869 * _7874);\n        left -= _7874;\n        if (left < 0.001000000047497451305389404296875)\n        {\n            left = 0.0;\n            break;\n        }\n    }\n    return acc;\n}\n\nvec3 fa_realtime_or_ambient(vec3 n)\n{\n    vec3 gi = vec3(0.0);\n    float left = 1.0;\n    if (fa_mesh_fs_params[52].y > 0.5)\n    {\n        vec3 param = n;\n        float param_1;\n        vec3 _7903 = fa_gi_light(param, param_1);\n        left = param_1;\n        gi = _7903;\n    }\n    if (left <= 0.0)\n    {\n        return gi;\n    }\n    vec3 param_2 = n;\n    return gi + (fa_ambient_light(param_2) * left);\n}\n\nvec3 fa_indirect_diffuse(vec3 n)\n{\n    if (fa_lm.z > 0.5)\n    {\n        return textureLod(fa_lightmap_fa_env_smp, fa_lm.xy, 0.0).xyz;\n    }\n    if (fa_mesh_fs_params[32].w > 0.0)\n    {\n        vec3 c[9];\n        for (int k = 0; k < 9; k++)\n        {\n            c[k] = fa_mesh_fs_params[k * 1 + 32].xyz;\n        }\n        vec3 param = n;\n        vec3 param_1[9] = c;\n        vec3 param_2 = n;\n        return mix(fa_ambient_light(param), fa_sh_eval(param_1, param_2), vec3(clamp(fa_mesh_fs_params[32].w, 0.0, 1.0)));\n    }\n    vec3 param_3 = n;\n    return fa_realtime_or_ambient(param_3);\n}\n\nint fa_cluster_index(int slot, int n)\n{\n    int param = (int(fa_mesh_fs_params[19].x) + int(fa_mesh_fs_params[19].w)) + ((slot + n) >> 2);\n    vec4 t = fa_light_texel(param);\n    return int(t[(slot + n) & 3]);\n}\n\nint fa_cl_light(int n)\n{\n    if (n < fa_cl_ndir)\n    {\n        return n;\n    }\n    int param = fa_cl_slot;\n    int param_1 = n - fa_cl_ndir;\n    return fa_cluster_index(param, param_1);\n}\n\nint fa_light_base(int li)\n{\n    return li * ((fa_mesh_fs_params[1].w > 4.5) ? 8 : 4);\n}\n\nbool fa_light_baked(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 3;\n    return fa_light_texel(param_1).w > 0.5;\n}\n\nfloat fa_baked_keep(int li)\n{\n    float _5804;\n    if (fa_lm.z > 0.5)\n    {\n        _5804 = 0.0;\n    }\n    else\n    {\n        _5804 = 1.0 - clamp(fa_mesh_fs_params[32].w, 0.0, 1.0);\n    }\n    bool _5815 = _5804 < 1.0;\n    bool _5821;\n    if (_5815)\n    {\n        int param = li;\n        _5821 = fa_light_baked(param);\n    }\n    else\n    {\n        _5821 = _5815;\n    }\n    return _5821 ? _5804 : 1.0;\n}\n\nfloat fa_light_type(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 1;\n    return fa_light_texel(param_1).w;\n}\n\nvec4 fa_atlas_fetch(vec2 texel)\n{\n    return textureLod(fa_light_atlas_fa_env_smp, texel / vec2(textureSize(fa_light_atlas_fa_env_smp, 0)), 0.0);\n}\n\nvec3 fa_cookie_sample(vec2 tile_origin, vec2 uv)\n{\n    vec2 param = (tile_origin + vec2(1.0)) + (clamp(uv, vec2(0.0), vec2(1.0)) * 254.0);\n    return fa_atlas_fetch(param).xyz;\n}\n\nvec3 fa_area_point(vec3 c, vec3 axis, vec3 ru, vec3 uu, float hx, float hy, float shape, vec3 p, vec3 r)\n{\n    bool _846 = dot(r, r) > 0.5;\n    if (shape > 1.5)\n    {\n        vec3 _859 = (c - (ru * hx)) - p;\n        vec3 _865 = ru * (2.0 * hx);\n        float _871 = max(dot(_865, _865), 9.9999999392252902907785028219223e-09);\n        float _875 = dot(_859, _865);\n        float t = clamp((-_875) / _871, 0.0, 1.0);\n        if (_846)\n        {\n            float _890 = dot(r, _865);\n            float _896 = _871 - (_890 * _890);\n            if (abs(_896) > (9.9999997473787516355514526367188e-06 * _871))\n            {\n                t = clamp(((dot(r, _859) * _890) - _875) / _896, 0.0, 1.0);\n            }\n        }\n        return (p + _859) + (_865 * t);\n    }\n    vec3 q = p;\n    float _928 = dot(r, axis);\n    bool _936;\n    if (_846)\n    {\n        _936 = abs(_928) > 9.9999997473787516355514526367188e-05;\n    }\n    else\n    {\n        _936 = _846;\n    }\n    if (_936)\n    {\n        float _946 = dot(c - p, axis) / _928;\n        if (_946 > 0.0)\n        {\n            q = p + (r * _946);\n        }\n    }\n    vec3 _959 = q - c;\n    vec2 xy = vec2(dot(_959, ru), dot(_959, uu));\n    if (shape > 0.5)\n    {\n        float _974 = length(xy);\n        if (_974 > hx)\n        {\n            xy *= (hx / _974);\n        }\n    }\n    else\n    {\n        xy = clamp(xy, vec2(-hx, -hy), vec2(hx, hy));\n    }\n    return (c + (ru * xy.x)) + (uu * xy.y);\n}\n\nint fa_cube_face(vec3 d)\n{\n    vec3 _607 = abs(d);\n    float _609 = _607.x;\n    float _611 = _607.y;\n    bool _612 = _609 >= _611;\n    bool _620;\n    if (_612)\n    {\n        _620 = _609 >= _607.z;\n    }\n    else\n    {\n        _620 = _612;\n    }\n    int _621;\n    if (_620)\n    {\n        _621 = (d.x > 0.0) ? 0 : 1;\n    }\n    else\n    {\n        int _636;\n        if (_611 >= _607.z)\n        {\n            _636 = (d.y > 0.0) ? 2 : 3;\n        }\n        else\n        {\n            _636 = (d.z > 0.0) ? 4 : 5;\n        }\n        _621 = _636;\n    }\n    return _621;\n}\n\nvoid fa_cube_face_basis(int f, out vec3 fwd, out vec3 up)\n{\n    if (f == 0)\n    {\n        fwd = vec3(1.0, 0.0, 0.0);\n        up = vec3(0.0, 1.0, 0.0);\n    }\n    else\n    {\n        if (f == 1)\n        {\n            fwd = vec3(-1.0, 0.0, 0.0);\n            up = vec3(0.0, 1.0, 0.0);\n        }\n        else\n        {\n            if (f == 2)\n            {\n                fwd = vec3(0.0, 1.0, 0.0);\n                up = vec3(0.0, 0.0, 1.0);\n            }\n            else\n            {\n                if (f == 3)\n                {\n                    fwd = vec3(0.0, -1.0, 0.0);\n                    up = vec3(0.0, 0.0, -1.0);\n                }\n                else\n                {\n                    if (f == 4)\n                    {\n                        fwd = vec3(0.0, 0.0, 1.0);\n                        up = vec3(0.0, 1.0, 0.0);\n                    }\n                    else\n                    {\n                        fwd = vec3(0.0, 0.0, -1.0);\n                        up = vec3(0.0, 1.0, 0.0);\n                    }\n                }\n            }\n        }\n    }\n}\n\nfloat fa_ies_sample(vec2 tile_origin, vec3 d, vec3 axis, vec3 right, vec3 up)\n{\n    float _766 = dot(d, right);\n    float _770 = dot(d, up);\n    float _781;\n    if (((_766 * _766) + (_770 * _770)) > 1.0000000133514319600180897396058e-10)\n    {\n        _781 = atan(_770, _766) * 0.15915493667125701904296875;\n    }\n    else\n    {\n        _781 = 0.0;\n    }\n    vec2 param = tile_origin + vec2(1.0 + ((_781 - floor(_781)) * 64.0), 1.0 + (acos(clamp(dot(d, axis), -1.0, 1.0)) * 10.18591594696044921875));\n    return fa_atlas_fetch(param).x;\n}\n\nLightSample fa_light_sample_n(int li, vec3 world_pos, vec3 n)\n{\n    int param = li;\n    int _1012 = fa_light_base(param);\n    bool _1016 = fa_mesh_fs_params[1].w > 4.5;\n    int param_1 = _1012;\n    vec4 _1020 = fa_light_texel(param_1);\n    int param_2 = _1012 + 1;\n    vec4 _1025 = fa_light_texel(param_2);\n    float _1028 = _1025.w;\n    float atten = 1.0;\n    float dist = 0.0;\n    fa_light_tint = vec3(1.0);\n    bool _1040 = _1016 && (_1028 > 2.5);\n    fa_light_is_area = _1040;\n    bool _1042 = _1028 < 0.5;\n    vec3 l;\n    if (_1042)\n    {\n        l = normalize(_1020.xyz);\n        if (_1016)\n        {\n            int param_3 = _1012 + 6;\n            vec4 _1056 = fa_light_texel(param_3);\n            if (_1056.z > 0.5)\n            {\n                int param_4 = _1012 + 4;\n                vec4 _1066 = fa_light_texel(param_4);\n                int param_5 = _1012 + 5;\n                vec4 _1071 = fa_light_texel(param_5);\n                vec2 param_6 = _1056.xy;\n                vec2 param_7 = fract(vec2(dot(world_pos, _1066.xyz) * _1066.w, (-dot(world_pos, _1071.xyz)) * _1071.w) + vec2(0.5));\n                fa_light_tint = fa_cookie_sample(param_6, param_7);\n            }\n        }\n    }\n    else\n    {\n        vec3 _1101 = _1020.xyz;\n        vec3 _1103 = _1101 - world_pos;\n        vec3 to_light = _1103;\n        float _1106 = length(_1103);\n        float reach = _1106;\n        bool front = true;\n        if (_1040)\n        {\n            int param_8 = _1012 + 7;\n            reach = max(_1106 - fa_light_texel(param_8).w, 0.0);\n            int param_9 = _1012 + 4;\n            vec4 _1130 = fa_light_texel(param_9);\n            int param_10 = _1012 + 5;\n            vec4 _1135 = fa_light_texel(param_10);\n            int param_11 = _1012 + 6;\n            vec4 _1140 = fa_light_texel(param_11);\n            float _1141 = _1140.w;\n            int param_12 = _1012 + 2;\n            vec3 _1148 = normalize(fa_light_texel(param_12).xyz);\n            bool _1150 = _1141 > 1.5;\n            bool _1158;\n            if (!_1150)\n            {\n                _1158 = dot(_1148, to_light) < 0.0;\n            }\n            else\n            {\n                _1158 = _1150;\n            }\n            front = _1158;\n            vec3 r = vec3(0.0);\n            vec3 _1167 = fa_mesh_fs_params[0].xyz - world_pos;\n            bool _1171 = dot(n, n) > 0.5;\n            bool _1179;\n            if (_1171)\n            {\n                _1179 = dot(_1167, _1167) > 9.9999999600419720025001879548654e-13;\n            }\n            else\n            {\n                _1179 = _1171;\n            }\n            if (_1179)\n            {\n                r = reflect(-normalize(_1167), normalize(n));\n            }\n            vec3 param_13 = _1101;\n            vec3 param_14 = _1148;\n            vec3 param_15 = _1130.xyz;\n            vec3 param_16 = _1135.xyz;\n            float param_17 = _1130.w;\n            float param_18 = _1135.w;\n            float param_19 = _1141;\n            vec3 param_20 = world_pos;\n            vec3 param_21 = r;\n            to_light = fa_area_point(param_13, param_14, param_15, param_16, param_17, param_18, param_19, param_20, param_21) - world_pos;\n        }\n        float _1215 = length(to_light);\n        dist = _1215;\n        l = to_light / vec3(max(_1215, 9.9999997473787516355514526367188e-05));\n        float _1229 = reach / max(_1020.w, 0.001000000047497451305389404296875);\n        float _1235 = clamp(1.0 - (_1229 * _1229), 0.0, 1.0);\n        float _1237;\n        if (front)\n        {\n            _1237 = _1235 * _1235;\n        }\n        else\n        {\n            _1237 = 0.0;\n        }\n        atten = _1237;\n        bool _1248 = _1028 < 2.5;\n        if ((_1028 > 1.5) && _1248)\n        {\n            int param_22 = _1012 + 2;\n            vec4 _1256 = fa_light_texel(param_22);\n            float _1266 = _1256.w;\n            int param_23 = _1012 + 3;\n            vec4 _1271 = fa_light_texel(param_23);\n            float _1272 = _1271.x;\n            float cos_inner = _1272;\n            if (_1272 > 1.5)\n            {\n                cos_inner = mix(_1266, 1.0, 0.25);\n            }\n            atten *= smoothstep(_1266, cos_inner, dot(-l, normalize(_1256.xyz)));\n        }\n        if (_1016 && (_1028 < 1.5))\n        {\n            int param_24 = _1012 + 6;\n            vec4 _1296 = fa_light_texel(param_24);\n            if (_1296.z > 0.5)\n            {\n                vec3 _1304 = -to_light;\n                int param_25 = _1012 + 4;\n                int param_26 = _1012 + 5;\n                vec3 _1318 = fa_light_texel(param_25).xyz;\n                vec3 _1322 = fa_light_texel(param_26).xyz;\n                vec3 _1331 = vec3(dot(_1304, _1318), dot(_1304, _1322), dot(_1304, cross(_1318, _1322)));\n                vec3 param_27 = _1331;\n                int _1335 = fa_cube_face(param_27);\n                int param_28 = _1335;\n                vec3 param_29;\n                vec3 param_30;\n                fa_cube_face_basis(param_28, param_29, param_30);\n                vec2 _1362 = vec2(dot(_1331, cross(param_29, param_30)), dot(_1331, param_30)) / vec2(max(dot(_1331, param_29), 9.9999997473787516355514526367188e-05));\n                int _1366 = _1335 / 3;\n                vec2 param_31 = _1296.xy + (vec2(float(_1335 - (_1366 * 3)), float(_1366)) * 256.0);\n                vec2 param_32 = vec2(0.5 + (0.5 * _1362.x), 0.5 - (0.5 * _1362.y));\n                fa_light_tint = fa_cookie_sample(param_31, param_32);\n            }\n            int param_33 = _1012 + 7;\n            vec4 _1396 = fa_light_texel(param_33);\n            if (_1396.z > 0.5)\n            {\n                int param_34 = _1012 + 2;\n                int param_35 = _1012 + 4;\n                int param_36 = _1012 + 5;\n                vec2 param_37 = _1396.xy;\n                vec3 param_38 = -l;\n                vec3 param_39 = normalize(fa_light_texel(param_34).xyz);\n                vec3 param_40 = fa_light_texel(param_35).xyz;\n                vec3 param_41 = fa_light_texel(param_36).xyz;\n                atten *= fa_ies_sample(param_37, param_38, param_39, param_40, param_41);\n            }\n        }\n        else\n        {\n            if (_1016 && _1248)\n            {\n                int param_42 = _1012 + 6;\n                vec4 _1443 = fa_light_texel(param_42);\n                int param_43 = _1012 + 7;\n                vec4 _1448 = fa_light_texel(param_43);\n                bool _1451 = _1443.z > 0.5;\n                bool _1458;\n                if (!_1451)\n                {\n                    _1458 = _1448.z > 0.5;\n                }\n                else\n                {\n                    _1458 = _1451;\n                }\n                if (_1458)\n                {\n                    int param_44 = _1012 + 2;\n                    vec4 _1465 = fa_light_texel(param_44);\n                    vec3 _1469 = normalize(_1465.xyz);\n                    int param_45 = _1012 + 4;\n                    vec4 _1474 = fa_light_texel(param_45);\n                    int param_46 = _1012 + 5;\n                    vec4 _1479 = fa_light_texel(param_46);\n                    if (_1451)\n                    {\n                        vec3 _1487 = -to_light;\n                        float _1494 = _1465.w;\n                        float _1510 = 0.5 / max(dot(_1487, _1469) * (sqrt(max(1.0 - (_1494 * _1494), 0.0)) / max(_1494, 0.001000000047497451305389404296875)), 9.9999997473787516355514526367188e-05);\n                        vec2 param_47 = _1443.xy;\n                        vec2 param_48 = vec2(0.5 + (dot(_1487, _1474.xyz) * _1510), 0.5 - (dot(_1487, _1479.xyz) * _1510));\n                        fa_light_tint = fa_cookie_sample(param_47, param_48);\n                    }\n                    if (_1448.z > 0.5)\n                    {\n                        vec2 param_49 = _1448.xy;\n                        vec3 param_50 = -l;\n                        vec3 param_51 = _1469;\n                        vec3 param_52 = _1474.xyz;\n                        vec3 param_53 = _1479.xyz;\n                        atten *= fa_ies_sample(param_49, param_50, param_51, param_52, param_53);\n                    }\n                }\n            }\n        }\n    }\n    vec3 _8989 = _1025.xyz * atten;\n    if (_1016)\n    {\n        _8989 *= fa_light_tint;\n    }\n    int _1579;\n    if (_1042)\n    {\n        _1579 = 0;\n    }\n    else\n    {\n        _1579 = ((_1028 > 1.5) && (_1028 < 2.5)) ? 2 : 1;\n    }\n    return LightSample(l, _8989, atten, 1.0, dist, _1579);\n}\n\nfloat fa_shadow_split_at(int i)\n{\n    float _2311;\n    if (i == 0)\n    {\n        _2311 = fa_shadows[24].x;\n    }\n    else\n    {\n        float _2327;\n        if (i == 1)\n        {\n            _2327 = fa_shadows[24].y;\n        }\n        else\n        {\n            float _2335;\n            if (i == 2)\n            {\n                _2335 = fa_shadows[24].z;\n            }\n            else\n            {\n                _2335 = fa_shadows[24].w;\n            }\n            _2327 = _2335;\n        }\n        _2311 = _2327;\n    }\n    return _2311;\n}\n\nfloat fa_shadow_depth(inout vec2 uv, vec4 rect)\n{\n    uv = clamp(uv, rect.xy, rect.zw);\n    return textureLod(fa_shadow_tex_fa_shadow_smp, uv, 0.0).x;\n}\n\nfloat fa_shadow_fetch(vec2 uv, vec4 rect, vec3 conv)\n{\n    vec2 param = uv;\n    vec4 param_1 = rect;\n    float _2368 = fa_shadow_depth(param, param_1);\n    float _2372;\n    if (conv.x < 0.5)\n    {\n        _2372 = _2368;\n    }\n    else\n    {\n        _2372 = (conv.y * conv.z) / (conv.z - (_2368 * (conv.z - conv.y)));\n    }\n    return _2372;\n}\n\nfloat fa_shadow_noise()\n{\n    return fract(52.98291778564453125 * fract(dot(gl_FragCoord.xy, vec2(0.067110560834407806396484375, 0.005837149918079376220703125))));\n}\n\nvec2 fa_shadow_vogel_turn(vec2 d)\n{\n    return vec2((d.x * (-0.737368881702423095703125)) - (d.y * 0.675490319728851318359375), (d.y * (-0.737368881702423095703125)) + (d.x * 0.675490319728851318359375));\n}\n\nfloat fa_shadow_filter(vec2 uv, vec4 rect, float zr, float texel_m, float unit, float reach, float plane, vec3 conv, int mode, float k)\n{\n    if (mode == 1)\n    {\n        vec2 param = uv;\n        vec4 param_1 = rect;\n        vec3 param_2 = conv;\n        return float(zr <= fa_shadow_fetch(param, param_1, param_2));\n    }\n    float _2418 = fa_shadow_noise() * 6.283185482025146484375;\n    vec2 _2424 = vec2(cos(_2418), sin(_2418));\n    vec2 dir = _2424;\n    float radius = 1.5;\n    if (mode == 2)\n    {\n        float _2433;\n        if (k < 0.0)\n        {\n            _2433 = (-k) / max(zr, 0.100000001490116119384765625);\n        }\n        else\n        {\n            _2433 = k;\n        }\n        float _2452 = clamp((_2433 * reach) / texel_m, 3.0, 12.0);\n        float sum = 0.0;\n        float cnt = 0.0;\n        for (int i = 0; i < 16; i++)\n        {\n            float _2471 = sqrt((float(i) + 0.5) * 0.0625) * _2452;\n            vec2 param_3 = uv + (dir * (fa_shadows[26].zw * _2471));\n            vec4 param_4 = rect;\n            vec3 param_5 = conv;\n            float _2485 = fa_shadow_fetch(param_3, param_4, param_5);\n            if (_2485 < (zr - (_2471 * plane)))\n            {\n                sum += _2485;\n                cnt += 1.0;\n            }\n            vec2 param_6 = dir;\n            dir = fa_shadow_vogel_turn(param_6);\n        }\n        if (cnt < 0.5)\n        {\n            return 1.0;\n        }\n        float _2513 = sum / cnt;\n        float _2523;\n        if (k < 0.0)\n        {\n            _2523 = (-k) / max(_2513, 0.0500000007450580596923828125);\n        }\n        else\n        {\n            _2523 = k;\n        }\n        radius = clamp(((max(zr - _2513, 0.0) * unit) * _2523) / texel_m, 1.5, 16.0);\n        dir = _2424;\n    }\n    float lit = 0.0;\n    int _2549 = (mode == 2) ? 24 : 16;\n    for (int i_1 = 0; i_1 < _2549; i_1++)\n    {\n        float _2568 = sqrt((float(i_1) + 0.5) / float(_2549)) * radius;\n        vec2 param_7 = uv + (dir * (fa_shadows[26].zw * _2568));\n        vec4 param_8 = rect;\n        vec3 param_9 = conv;\n        lit += float((zr - (_2568 * plane)) <= fa_shadow_fetch(param_7, param_8, param_9));\n        vec2 param_10 = dir;\n        dir = fa_shadow_vogel_turn(param_10);\n    }\n    return lit / float(_2549);\n}\n\nfloat fa_shadow_cascade(int ci, vec3 world, vec3 n, vec3 l)\n{\n    float _2614 = max(fa_shadows[ci * 1 + 20].y, 0.001000000047497451305389404296875);\n    float _2619 = clamp(dot(n, l), 0.0, 1.0);\n    float _2625 = sqrt(1.0 - (_2619 * _2619));\n    float _2633 = min(_2625 / max(_2619, 0.20000000298023223876953125), 4.0);\n    float _2638;\n    if (fa_shadows[26].y > 0.0)\n    {\n        _2638 = fa_shadows[26].y;\n    }\n    else\n    {\n        _2638 = 1.5 * fa_shadows[ci * 1 + 20].x;\n    }\n    vec4 _2663 = mat4(fa_shadows[ci * 4 + 0], fa_shadows[ci * 4 + 1], fa_shadows[ci * 4 + 2], fa_shadows[ci * 4 + 3]) * vec4(world + (n * (_2638 * _2625)), 1.0);\n    float _2670 = _2663.x;\n    bool _2673 = _2670 < fa_shadows[ci * 1 + 16].x;\n    bool _2682;\n    if (!_2673)\n    {\n        _2682 = _2670 > fa_shadows[ci * 1 + 16].z;\n    }\n    else\n    {\n        _2682 = _2673;\n    }\n    bool _2691;\n    if (!_2682)\n    {\n        _2691 = _2663.y < fa_shadows[ci * 1 + 16].y;\n    }\n    else\n    {\n        _2691 = _2682;\n    }\n    bool _2700;\n    if (!_2691)\n    {\n        _2700 = _2663.y > fa_shadows[ci * 1 + 16].w;\n    }\n    else\n    {\n        _2700 = _2691;\n    }\n    bool _2707;\n    if (!_2700)\n    {\n        _2707 = _2663.z > 1.0;\n    }\n    else\n    {\n        _2707 = _2700;\n    }\n    if (_2707)\n    {\n        return -1.0;\n    }\n    float _2715;\n    if (fa_shadows[26].x > 0.0)\n    {\n        _2715 = fa_shadows[26].x;\n    }\n    else\n    {\n        _2715 = 1.5 * fa_shadows[ci * 1 + 20].x;\n    }\n    vec2 param = _2663.xy;\n    vec4 param_1 = fa_shadows[ci * 1 + 16];\n    float param_2 = _2663.z - ((_2715 * (1.0 + (0.5 * _2633))) / _2614);\n    float param_3 = fa_shadows[ci * 1 + 20].x;\n    float param_4 = _2614;\n    float param_5 = _2614 * 0.25;\n    float param_6 = ((fa_shadows[ci * 1 + 20].x * min(_2633, 3.0)) * 0.5) / _2614;\n    vec3 param_7 = vec3(0.0);\n    int param_8 = int(fa_shadows[25].z + 0.5);\n    float param_9 = fa_shadows[25].w;\n    return fa_shadow_filter(param, param_1, param_2, param_3, param_4, param_5, param_6, param_7, param_8, param_9);\n}\n\nfloat fa_shadow_sun(vec3 world, vec3 n, vec3 l)\n{\n    if (fa_mesh_fs_params[5].z < 0.5)\n    {\n        return 1.0;\n    }\n    int _3093 = int(fa_shadows[25].x + 0.5);\n    if (_3093 < 1)\n    {\n        return 1.0;\n    }\n    float _3108 = dot(world - fa_shadows[27].xyz, fa_shadows[28].xyz);\n    int param = _3093 - 1;\n    if (_3108 > fa_shadow_split_at(param))\n    {\n        return 1.0;\n    }\n    int ci = 0;\n    bool _3120 = _3093 > 1;\n    bool _3127;\n    if (_3120)\n    {\n        _3127 = _3108 > fa_shadows[24].x;\n    }\n    else\n    {\n        _3127 = _3120;\n    }\n    if (_3127)\n    {\n        ci = 1;\n    }\n    bool _3131 = _3093 > 2;\n    bool _3138;\n    if (_3131)\n    {\n        _3138 = _3108 > fa_shadows[24].y;\n    }\n    else\n    {\n        _3138 = _3131;\n    }\n    if (_3138)\n    {\n        ci = 2;\n    }\n    bool _3142 = _3093 > 3;\n    bool _3149;\n    if (_3142)\n    {\n        _3149 = _3108 > fa_shadows[24].z;\n    }\n    else\n    {\n        _3149 = _3142;\n    }\n    if (_3149)\n    {\n        ci = 3;\n    }\n    float s = -1.0;\n    for (int k = 0; k < 4; k++)\n    {\n        if (ci >= _3093)\n        {\n            break;\n        }\n        int param_1 = ci;\n        vec3 param_2 = world;\n        vec3 param_3 = n;\n        vec3 param_4 = l;\n        float _3175 = fa_shadow_cascade(param_1, param_2, param_3, param_4);\n        s = _3175;\n        if (_3175 >= 0.0)\n        {\n            break;\n        }\n        ci++;\n    }\n    if (s < 0.0)\n    {\n        return 1.0;\n    }\n    if (fa_shadows[25].y > 0.0)\n    {\n        float _3200;\n        if (ci > 0)\n        {\n            int param_5 = ci - 1;\n            _3200 = fa_shadow_split_at(param_5);\n        }\n        else\n        {\n            _3200 = fa_shadows[28].w;\n        }\n        int param_6 = ci;\n        float _3219 = fa_shadows[25].y * max(fa_shadow_split_at(param_6) - _3200, 9.9999997473787516355514526367188e-05);\n        int param_7 = ci;\n        float _3230 = clamp((_3108 - (fa_shadow_split_at(param_7) - _3219)) / _3219, 0.0, 1.0);\n        if (_3230 > 0.0)\n        {\n            float s2 = 1.0;\n            if ((ci + 1) < _3093)\n            {\n                int param_8 = ci + 1;\n                vec3 param_9 = world;\n                vec3 param_10 = n;\n                vec3 param_11 = l;\n                float _3251 = fa_shadow_cascade(param_8, param_9, param_10, param_11);\n                s2 = _3251;\n                if (_3251 < 0.0)\n                {\n                    s2 = s;\n                }\n            }\n            s = mix(s, s2, _3230);\n        }\n    }\n    return s;\n}\n\nfloat fa_shadow_factor(vec3 n, vec3 l)\n{\n    vec3 param = fa_world_pos;\n    vec3 param_1 = n;\n    vec3 param_2 = l;\n    return fa_shadow_sun(param, param_1, param_2);\n}\n\nfloat fa_shadow_local(int li, vec3 lpos, vec3 world, vec3 n, vec3 l)\n{\n    bool _2773 = fa_mesh_fs_params[5].z < 0.5;\n    bool _2780;\n    if (!_2773)\n    {\n        _2780 = fa_shadows[29].x < 0.5;\n    }\n    else\n    {\n        _2780 = _2773;\n    }\n    if (_2780)\n    {\n        return 1.0;\n    }\n    int param = (int(fa_shadows[29].x + 0.5) - 1) + li;\n    vec4 _2793 = fa_light_texel(param);\n    float _2794 = _2793.x;\n    if (_2794 < 0.0)\n    {\n        return 1.0;\n    }\n    int _2803 = int(_2794 + 0.5);\n    int param_1 = _2803;\n    vec4 _2807 = fa_light_texel(param_1);\n    int param_2 = _2803 + 1;\n    vec4 _2812 = fa_light_texel(param_2);\n    float fade = 1.0;\n    float _2815 = _2807.y;\n    if (_2815 > 0.0)\n    {\n        float _2832 = 1.0 - smoothstep(0.75 * _2815, _2815, length(world - fa_shadows[27].xyz));\n        fade = _2832;\n        if (_2832 <= 0.0)\n        {\n            return 1.0;\n        }\n    }\n    int face = 0;\n    if (_2807.x > 1.5)\n    {\n        vec3 param_3 = world - lpos;\n        face = fa_cube_face(param_3);\n    }\n    int _2856 = (_2803 + 2) + (face * 6);\n    int param_4 = _2856;\n    int param_5 = _2856 + 1;\n    int param_6 = _2856 + 3;\n    vec4 _2870 = fa_light_texel(param_6);\n    int param_7 = _2856 + 4;\n    vec4 _2875 = fa_light_texel(param_7);\n    int param_8 = _2856 + 5;\n    vec4 _2880 = fa_light_texel(param_8);\n    float _2892 = _2880.x * max(dot(_2870, vec4(world, 1.0)), 0.001000000047497451305389404296875);\n    float _2897 = clamp(dot(n, l), 0.0, 1.0);\n    float _2920 = clamp(dot(n, _2870.xyz), -1.0, 1.0);\n    float _2939 = min(sqrt(1.0 - (_2920 * _2920)) / max(abs(dot(n, world - lpos)) / max(dot(_2870, vec4(world, 1.0)), 0.001000000047497451305389404296875), 0.20000000298023223876953125), 4.0);\n    float _2942 = _2812.y;\n    float _2944;\n    if (_2942 > 0.0)\n    {\n        _2944 = _2942;\n    }\n    else\n    {\n        _2944 = 1.5 * _2892;\n    }\n    vec4 _2964 = vec4(world + (n * (_2944 * sqrt(1.0 - (_2897 * _2897)))), 1.0);\n    float _2968 = dot(_2870, _2964);\n    float _2971 = _2880.y;\n    if (_2968 < _2971)\n    {\n        return 1.0;\n    }\n    vec2 _2986 = vec2(dot(fa_light_texel(param_4), _2964), dot(fa_light_texel(param_5), _2964)) / vec2(_2968);\n    float _2988 = _2986.x;\n    bool _2991 = _2988 < _2875.x;\n    bool _3000;\n    if (!_2991)\n    {\n        _3000 = _2988 > _2875.z;\n    }\n    else\n    {\n        _3000 = _2991;\n    }\n    bool _3009;\n    if (!_3000)\n    {\n        _3009 = _2986.y < _2875.y;\n    }\n    else\n    {\n        _3009 = _3000;\n    }\n    bool _3018;\n    if (!_3009)\n    {\n        _3018 = _2986.y > _2875.w;\n    }\n    else\n    {\n        _3018 = _3009;\n    }\n    if (_3018)\n    {\n        return 1.0;\n    }\n    float _3024 = _2812.x;\n    float _3026;\n    if (_3024 > 0.0)\n    {\n        _3026 = _3024;\n    }\n    else\n    {\n        _3026 = 1.5 * _2892;\n    }\n    vec2 param_9 = _2986;\n    vec4 param_10 = _2875;\n    float param_11 = _2968 - (_3026 * (1.0 + (0.5 * _2939)));\n    float param_12 = _2892;\n    float param_13 = 1.0;\n    float param_14 = _2880.z * 0.25;\n    float param_15 = (_2892 * min(_2939, 3.0)) * 0.5;\n    vec3 param_16 = vec3(1.0, _2971, _2880.z);\n    int param_17 = int(_2807.z + 0.5);\n    float param_18 = _2807.w;\n    return mix(1.0, fa_shadow_filter(param_9, param_10, param_11, param_12, param_13, param_14, param_15, param_16, param_17, param_18), fade);\n}\n\nfloat fa_contact_shadow(int li, vec3 world, vec3 gn, vec3 l, float dist)\n{\n    bool _5177 = fa_mesh_fs_params[24].x < 0.5;\n    bool _5184;\n    if (!_5177)\n    {\n        _5184 = fa_shadows[29].x < 0.5;\n    }\n    else\n    {\n        _5184 = _5177;\n    }\n    if (_5184)\n    {\n        return 1.0;\n    }\n    int param = (int(fa_shadows[29].x + 0.5) - 1) + li;\n    vec4 _5197 = fa_light_texel(param);\n    float _5198 = _5197.y;\n    float len = _5198;\n    if (_5198 <= 0.0)\n    {\n        return 1.0;\n    }\n    float _5210 = length(world - fa_mesh_fs_params[0].xyz);\n    float _5220 = 1.0 - smoothstep(0.5 * fa_mesh_fs_params[25].x, fa_mesh_fs_params[25].x, _5210);\n    if (_5220 <= 0.0)\n    {\n        return 1.0;\n    }\n    float _5226 = len;\n    float _5229 = min(_5226, 0.89999997615814208984375 * dist);\n    len = _5229;\n    float _5234 = 0.004999999888241291046142578125 + (0.0030000000260770320892333984375 * _5210);\n    float _5239 = _5234 + (0.5 * _5229);\n    vec3 _5245 = world + (gn * _5234);\n    float _5247 = fa_shadow_noise();\n    float occ = 0.0;\n    float _5311;\n    for (int k = 0; k < 12; k++)\n    {\n        float _5262 = (float(k) + _5247) * 0.083333335816860198974609375;\n        vec3 _5270 = _5245 + (l * (_5262 * len));\n        vec4 _5276 = vec4(_5270, 1.0);\n        float _5282 = dot(fa_mesh_fs_params[28], _5276);\n        if (_5282 < 9.9999997473787516355514526367188e-05)\n        {\n            break;\n        }\n        vec2 _5302 = vec2(dot(fa_mesh_fs_params[26], _5276), dot(fa_mesh_fs_params[27], _5276)) / vec2(_5282);\n        float _5306 = _5302.x * 0.5;\n        float _5307 = _5306 + 0.5;\n        if (fa_mesh_fs_params[24].y > 0.5)\n        {\n            _5311 = (_5302.y * 0.5) + 0.5;\n        }\n        else\n        {\n            _5311 = 0.5 - (_5302.y * 0.5);\n        }\n        bool _5327 = _5307 < 0.0;\n        bool _5334;\n        if (!_5327)\n        {\n            _5334 = _5307 >= 1.0;\n        }\n        else\n        {\n            _5334 = _5327;\n        }\n        bool _5341;\n        if (!_5334)\n        {\n            _5341 = _5311 < 0.0;\n        }\n        else\n        {\n            _5341 = _5334;\n        }\n        bool _5348;\n        if (!_5341)\n        {\n            _5348 = _5311 >= 1.0;\n        }\n        else\n        {\n            _5348 = _5341;\n        }\n        if (_5348)\n        {\n            break;\n        }\n        vec4 _5375 = texelFetch(fa_screen_tex_fa_shadow_smp, clamp(ivec2(vec2(_5307, _5311) * fa_mesh_fs_params[24].zw), ivec2(0), ivec2(fa_mesh_fs_params[24].zw) - ivec2(1)), 0);\n        if (_5375.w < 0.5)\n        {\n            continue;\n        }\n        float _5394 = (dot(fa_mesh_fs_params[29].xyz, _5270) + fa_mesh_fs_params[29].w) - _5375.x;\n        if ((_5394 > _5234) && (_5394 < _5239))\n        {\n            occ = max(occ, (1.0 - (_5262 * _5262)) * smoothstep(0.0, 0.0500000007450580596923828125, min(min(_5307, 0.5 - _5306), min(_5311, 1.0 - _5311))));\n        }\n    }\n    return 1.0 - (occ * _5220);\n}\n\nLightSample fa_light_shadowed(int li, vec3 world_pos, vec3 gn)\n{\n    int param = li;\n    float _5860 = fa_baked_keep(param);\n    if (_5860 <= 0.0)\n    {\n        int param_1 = li;\n        return LightSample(vec3(0.0, 1.0, 0.0), vec3(0.0), 0.0, 1.0, 0.0, int(fa_light_type(param_1) + 0.5));\n    }\n    int param_2 = li;\n    vec3 param_3 = world_pos;\n    vec3 param_4 = gn;\n    LightSample _5886 = fa_light_sample_n(param_2, param_3, param_4);\n    vec3 _9058 = _5886.color;\n    float _9059 = _5886.attenuation;\n    float _9060 = _5886.shadow;\n    bool _5889 = _5886.type == 0;\n    if (_5889 && (li == 0))\n    {\n        vec3 param_5 = gn;\n        vec3 param_6 = _5886.direction;\n        float _5900 = fa_shadow_factor(param_5, param_6);\n        _9060 = _5900;\n        _9058 *= _5900;\n    }\n    else\n    {\n        bool _5911 = _5886.type != 0;\n        bool _5917;\n        if (_5911)\n        {\n            _5917 = _9059 > 0.0;\n        }\n        else\n        {\n            _5917 = _5911;\n        }\n        if (_5917)\n        {\n            int param_7 = li;\n            int param_8 = fa_light_base(param_7);\n            int param_9 = li;\n            vec3 param_10 = fa_light_texel(param_8).xyz;\n            vec3 param_11 = world_pos;\n            vec3 param_12 = gn;\n            vec3 param_13 = _5886.direction;\n            float _5936 = fa_shadow_local(param_9, param_10, param_11, param_12, param_13);\n            _9060 = _5936;\n            _9058 *= _5936;\n        }\n    }\n    bool _5946 = fa_mesh_fs_params[24].x > 0.5;\n    bool _5952;\n    if (_5946)\n    {\n        _5952 = _9059 > 0.0;\n    }\n    else\n    {\n        _5952 = _5946;\n    }\n    if (_5952)\n    {\n        float _5959;\n        if (_5889)\n        {\n            _5959 = 1000000000.0;\n        }\n        else\n        {\n            _5959 = _5886._distance;\n        }\n        int param_14 = li;\n        vec3 param_15 = world_pos;\n        vec3 param_16 = gn;\n        vec3 param_17 = _5886.direction;\n        float param_18 = _5959;\n        float _5977 = fa_contact_shadow(param_14, param_15, param_16, param_17, param_18);\n        _9060 *= _5977;\n        _9058 *= _5977;\n    }\n    float _5990 = _9059;\n    float _5991 = _5990 * _5860;\n    _9059 = _5991;\n    vec3 _5995 = _9058;\n    vec3 _5996 = _5995 * _5860;\n    _9058 = _5996;\n    return LightSample(_5886.direction, _5996, _5991, _9060, _5886._distance, _5886.type);\n}\n\nvec3 fa_ltc_tangent(vec3 n, vec3 v)\n{\n    vec3 _6030 = v - (n * dot(v, n));\n    vec3 t = _6030;\n    float _6034 = dot(_6030, _6030);\n    float l2 = _6034;\n    if (_6034 < 1.0000000133514319600180897396058e-10)\n    {\n        vec3 _6044;\n        if (abs(n.z) < 0.999000012874603271484375)\n        {\n            _6044 = cross(n, vec3(0.0, 0.0, 1.0));\n        }\n        else\n        {\n            _6044 = cross(n, vec3(1.0, 0.0, 0.0));\n        }\n        t = _6044;\n        l2 = dot(_6044, _6044);\n    }\n    return t * inversesqrt(l2);\n}\n\nvec3 fa_ltc_local(vec3 t1, vec3 n, vec3 p)\n{\n    return vec3(dot(t1, p), dot(cross(n, t1), p), dot(n, p));\n}\n\nvec3 fa_ltc_edge_vector(vec3 a, vec3 b)\n{\n    float _6079 = dot(a, a);\n    float _6083 = dot(b, b);\n    if ((_6079 < 1.0000000195414813782625560981111e-24) || (_6083 < 1.0000000195414813782625560981111e-24))\n    {\n        return vec3(0.0);\n    }\n    vec3 _6097 = a * inversesqrt(_6079);\n    vec3 _6102 = b * inversesqrt(_6083);\n    float _6106 = dot(_6097, _6102);\n    float _6109 = abs(_6106);\n    float g = (((((((((((0.0416471660137176513671875 * _6109) - 0.1924748718738555908203125) * _6109) + 0.4179156124591827392578125) * _6109) - 0.616057217121124267578125) * _6109) + 0.777722418308258056640625) * _6109) - 0.999542415142059326171875) * _6109) + 1.570791721343994140625;\n    if (_6106 < 0.0)\n    {\n        g = (3.1415927410125732421875 * inversesqrt(max(1.0 - (_6106 * _6106), 1.0000000116860974230803549289703e-07))) - g;\n    }\n    return cross(_6097, _6102) * g;\n}\n\nvoid fa_ltc_clip_edge(vec3 a, vec3 b, inout vec3 sum, inout vec3 leave, inout vec3 enter, inout vec2 seen)\n{\n    bool _6166 = a.z > 0.0;\n    bool _6170 = b.z > 0.0;\n    if (_6166 && _6170)\n    {\n        vec3 param = a;\n        vec3 param_1 = b;\n        sum += fa_ltc_edge_vector(param, param_1);\n    }\n    else\n    {\n        if (_6166 != _6170)\n        {\n            vec3 _6205 = a + ((b - a) * (a.z / (a.z - b.z)));\n            _6205.z = 0.0;\n            if (_6166)\n            {\n                vec3 param_2 = a;\n                vec3 param_3 = _6205;\n                sum += fa_ltc_edge_vector(param_2, param_3);\n                leave = _6205;\n                seen.x = 1.0;\n            }\n            else\n            {\n                vec3 param_4 = _6205;\n                vec3 param_5 = b;\n                sum += fa_ltc_edge_vector(param_4, param_5);\n                enter = _6205;\n                seen.y = 1.0;\n            }\n        }\n    }\n}\n\nfloat fa_ltc_quad(vec4 abcd, vec3 p0, vec3 p1, vec3 p2, vec3 p3)\n{\n    vec3 _6254 = vec3((abcd.x * p0.x) + (abcd.y * p0.z), p0.y, (abcd.z * p0.x) + (abcd.w * p0.z));\n    vec3 _6280 = vec3((abcd.x * p1.x) + (abcd.y * p1.z), p1.y, (abcd.z * p1.x) + (abcd.w * p1.z));\n    vec3 _6306 = vec3((abcd.x * p2.x) + (abcd.y * p2.z), p2.y, (abcd.z * p2.x) + (abcd.w * p2.z));\n    vec3 _6332 = vec3((abcd.x * p3.x) + (abcd.y * p3.z), p3.y, (abcd.z * p3.x) + (abcd.w * p3.z));\n    vec3 sum = vec3(0.0);\n    vec3 leave = vec3(0.0);\n    vec3 enter = vec3(0.0);\n    vec3 param = _6254;\n    vec3 param_1 = _6280;\n    vec3 param_2 = vec3(0.0);\n    vec3 param_3 = vec3(0.0);\n    vec3 param_4 = vec3(0.0);\n    vec2 param_5 = vec2(0.0);\n    fa_ltc_clip_edge(param, param_1, param_2, param_3, param_4, param_5);\n    sum = param_2;\n    leave = param_3;\n    enter = param_4;\n    vec3 param_6 = _6280;\n    vec3 param_7 = _6306;\n    vec3 param_8 = param_2;\n    vec3 param_9 = param_3;\n    vec3 param_10 = param_4;\n    vec2 param_11 = param_5;\n    fa_ltc_clip_edge(param_6, param_7, param_8, param_9, param_10, param_11);\n    sum = param_8;\n    leave = param_9;\n    enter = param_10;\n    vec3 param_12 = _6306;\n    vec3 param_13 = _6332;\n    vec3 param_14 = param_8;\n    vec3 param_15 = param_9;\n    vec3 param_16 = param_10;\n    vec2 param_17 = param_11;\n    fa_ltc_clip_edge(param_12, param_13, param_14, param_15, param_16, param_17);\n    sum = param_14;\n    leave = param_15;\n    enter = param_16;\n    vec3 param_18 = _6332;\n    vec3 param_19 = _6254;\n    vec3 param_20 = param_14;\n    vec3 param_21 = param_15;\n    vec3 param_22 = param_16;\n    vec2 param_23 = param_17;\n    fa_ltc_clip_edge(param_18, param_19, param_20, param_21, param_22, param_23);\n    sum = param_20;\n    leave = param_21;\n    enter = param_22;\n    if ((param_23.x * param_23.y) > 0.5)\n    {\n        vec3 param_24 = leave;\n        vec3 param_25 = enter;\n        sum += fa_ltc_edge_vector(param_24, param_25);\n    }\n    return sum.z * 0.15915493667125701904296875;\n}\n\nfloat fa_ltc_rect(vec4 abcd, vec3 center, vec3 ex, vec3 ey)\n{\n    vec4 param = abcd;\n    vec3 param_1 = (center - ex) - ey;\n    vec3 param_2 = (center + ex) - ey;\n    vec3 param_3 = (center + ex) + ey;\n    vec3 param_4 = (center - ex) + ey;\n    return abs(fa_ltc_quad(param, param_1, param_2, param_3, param_4));\n}\n\nfloat fa_area_form(vec4 m, float shape, vec3 pc, vec3 ex, vec3 ey)\n{\n    if ((shape < 0.5) || (shape > 1.5))\n    {\n        vec4 param = m;\n        vec3 param_1 = pc;\n        vec3 param_2 = ex;\n        vec3 param_3 = ey;\n        return fa_ltc_rect(param, param_1, param_2, param_3);\n    }\n    vec3 _6481 = (pc + (ex * 0.92387950420379638671875)) + (ey * 0.3826834261417388916015625);\n    vec3 _6505 = (pc - (ex * 0.92387950420379638671875)) + (ey * 0.3826834261417388916015625);\n    vec3 _6521 = (pc - (ex * 0.3826834261417388916015625)) - (ey * 0.92387950420379638671875);\n    vec4 param_4 = m;\n    vec3 param_5 = _6481;\n    vec3 param_6 = (pc + (ex * 0.3826834261417388916015625)) + (ey * 0.92387950420379638671875);\n    vec3 param_7 = (pc - (ex * 0.3826834261417388916015625)) + (ey * 0.92387950420379638671875);\n    vec3 param_8 = _6505;\n    vec4 param_9 = m;\n    vec3 param_10 = _6481;\n    vec3 param_11 = _6505;\n    vec3 param_12 = (pc - (ex * 0.92387950420379638671875)) - (ey * 0.3826834261417388916015625);\n    vec3 param_13 = _6521;\n    vec4 param_14 = m;\n    vec3 param_15 = _6481;\n    vec3 param_16 = _6521;\n    vec3 param_17 = (pc + (ex * 0.3826834261417388916015625)) - (ey * 0.92387950420379638671875);\n    vec3 param_18 = (pc + (ex * 0.92387950420379638671875)) - (ey * 0.3826834261417388916015625);\n    return abs((fa_ltc_quad(param_4, param_5, param_6, param_7, param_8) + fa_ltc_quad(param_9, param_10, param_11, param_12, param_13)) + fa_ltc_quad(param_14, param_15, param_16, param_17, param_18));\n}\n\nvec2 fa_ltc_uv(float roughness, float ndv)\n{\n    return ((vec2(clamp((roughness - 0.0500000007450580596923828125) * 1.0526316165924072265625, 0.0, 1.0), sqrt(clamp(1.0 - ndv, 0.0, 1.0))) * 63.0) + vec2(0.5)) * vec2(0.015625);\n}\n\nvec3 fa_area_shade(int li, vec3 world_pos, vec3 n, vec3 v, vec3 diffuse_color, vec3 f0, float f90, float roughness, float ndv, float window)\n{\n    int param = li;\n    int _6579 = fa_light_base(param);\n    int param_1 = _6579;\n    int param_2 = _6579 + 1;\n    int param_3 = _6579 + 2;\n    int param_4 = _6579 + 4;\n    vec4 _6601 = fa_light_texel(param_4);\n    int param_5 = _6579 + 5;\n    vec4 _6606 = fa_light_texel(param_5);\n    int param_6 = _6579 + 6;\n    vec4 _6611 = fa_light_texel(param_6);\n    float _6612 = _6611.w;\n    vec3 _6617 = fa_light_texel(param_1).xyz - world_pos;\n    bool _6619 = _6612 < 1.5;\n    bool _6626;\n    if (_6619)\n    {\n        _6626 = dot(normalize(fa_light_texel(param_3).xyz), _6617) >= 0.0;\n    }\n    else\n    {\n        _6626 = _6619;\n    }\n    if (_6626)\n    {\n        return vec3(0.0);\n    }\n    bool _6635 = (_6612 > 0.5) && _6619;\n    float _6639 = _6635 ? 1.0539000034332275390625 : 1.0;\n    vec3 _6642 = _6601.xyz;\n    float _6644 = _6601.w;\n    vec3 _6650 = _6606.xyz;\n    float _6652 = _6606.w;\n    vec3 up = _6650 * (_6652 * _6639);\n    float _6658;\n    if (_6635)\n    {\n        _6658 = (3.1415927410125732421875 * _6644) * _6644;\n    }\n    else\n    {\n        _6658 = (4.0 * _6644) * _6652;\n    }\n    if (_6612 > 1.5)\n    {\n        vec3 _6684 = cross(_6642, -_6617);\n        vec3 perp = _6684;\n        float _6688 = dot(_6684, _6684);\n        vec3 _6691;\n        if (_6688 > 1.0000000133514319600180897396058e-10)\n        {\n            _6691 = perp * inversesqrt(_6688);\n        }\n        else\n        {\n            _6691 = _6650;\n        }\n        perp = _6691;\n        up = _6691 * _6652;\n    }\n    float _6712 = max(_6658, 9.9999999747524270787835121154785e-07);\n    vec3 param_7 = n;\n    vec3 param_8 = v;\n    vec3 _6722 = fa_ltc_tangent(param_7, param_8);\n    vec3 param_9 = _6722;\n    vec3 param_10 = n;\n    vec3 param_11 = _6617;\n    vec3 _6730 = fa_ltc_local(param_9, param_10, param_11);\n    vec3 param_12 = _6722;\n    vec3 param_13 = n;\n    vec3 param_14 = _6642 * (_6644 * _6639);\n    vec3 _6738 = fa_ltc_local(param_12, param_13, param_14);\n    vec3 param_15 = _6722;\n    vec3 param_16 = n;\n    vec3 param_17 = up;\n    vec3 _6746 = fa_ltc_local(param_15, param_16, param_17);\n    vec4 param_18 = vec4(1.0, 0.0, 0.0, 1.0);\n    float param_19 = _6612;\n    vec3 param_20 = _6730;\n    vec3 param_21 = _6738;\n    vec3 param_22 = _6746;\n    float param_23 = roughness;\n    float param_24 = ndv;\n    vec2 _6765 = fa_ltc_uv(param_23, param_24) * 64.0;\n    vec2 param_25 = _6765;\n    vec2 param_26 = _6765 + vec2(64.0, 0.0);\n    vec4 _6775 = fa_atlas_fetch(param_26);\n    vec4 param_27 = fa_atlas_fetch(param_25);\n    float param_28 = _6612;\n    vec3 param_29 = _6730;\n    vec3 param_30 = _6738;\n    vec3 param_31 = _6746;\n    return (((diffuse_color * fa_area_form(param_18, param_19, param_20, param_21, param_22)) + (((f0 * _6775.x) + ((vec3(f90) - f0) * _6775.y)) * fa_area_form(param_27, param_28, param_29, param_30, param_31))) * fa_light_texel(param_2).xyz) * ((((3.1415927410125732421875 * dot(_6617, _6617)) + _6712) / _6712) * window);\n}\n\nvec3 fa_light_rgb(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 1;\n    return fa_light_texel(param_1).xyz;\n}\n\nfloat fa_d_charlie(float alpha, float ndh)\n{\n    float _4914 = 1.0 / alpha;\n    return ((2.0 + _4914) * pow(sqrt(max(1.0 - (ndh * ndh), 9.9999997473787516355514526367188e-05)), _4914)) * 0.15915493667125701904296875;\n}\n\nfloat fa_v_ashikhmin(float ndl, float ndv)\n{\n    return clamp(0.25 / max((ndl + ndv) - (ndl * ndv), 9.9999997473787516355514526367188e-05), 0.0, 1.0);\n}\n\nfloat fa_layers_coat(FaLayers L, vec3 l, vec3 h, float vdh)\n{\n    float _4949 = max(dot(L.nc, l), 0.0);\n    float _4955 = max(dot(L.nc, h), 0.0);\n    float _4964 = ((_4955 * _4955) * (L.coat_a2 - 1.0)) + 1.0;\n    return (((L.coat * (0.039999999105930328369140625 + (0.959999978542327880859375 * pow(clamp(1.0 - vdh, 0.0, 1.0), 5.0)))) * (((L.coat_a2 / ((3.1415927410125732421875 * _4964) * _4964)) * (0.5 / max(mix((2.0 * _4949) * L.coat_ndv, _4949 + L.coat_ndv, L.coat_alpha), 9.9999997473787516355514526367188e-05))) * 3.1415927410125732421875)) * step(9.9999997473787516355514526367188e-05, _4949)) * _4949;\n}\n\nvec3 fa_area_layers(FaLayers L, int li, vec3 world_pos, vec3 n, vec3 v, vec3 l, vec3 diffuse_color, vec3 f0, float roughness, float ndv, float window)\n{\n    int param = li;\n    vec3 param_1 = world_pos;\n    vec3 param_2 = n;\n    vec3 param_3 = v;\n    vec3 param_4 = diffuse_color;\n    vec3 param_5 = f0;\n    float param_6 = L.f90;\n    float param_7 = roughness;\n    float param_8 = ndv;\n    float param_9 = window;\n    float _6843;\n    if (L.sheen_on)\n    {\n        _6843 = L.sheen_scale;\n    }\n    else\n    {\n        _6843 = 1.0;\n    }\n    vec3 result = fa_area_shade(param, param_1, param_2, param_3, param_4, param_5, param_6, param_7, param_8, param_9) * (L.keep * _6843);\n    vec3 _6856 = normalize(l + v);\n    int param_10 = li;\n    vec3 _6867 = fa_light_rgb(param_10) * window;\n    if (L.sheen_on)\n    {\n        float _6876 = max(dot(n, l), 0.0);\n        float param_11 = L.sheen_alpha;\n        float param_12 = max(dot(n, _6856), 0.0);\n        float param_13 = _6876;\n        float param_14 = ndv;\n        result += ((L.sheen * _6867) * (((((fa_d_charlie(param_11, param_12) * fa_v_ashikhmin(param_13, param_14)) * 3.1415927410125732421875) * step(9.9999997473787516355514526367188e-05, _6876)) * _6876) * L.keep));\n    }\n    if (L.coat > 0.0)\n    {\n        FaLayers param_15 = L;\n        vec3 param_16 = l;\n        vec3 param_17 = _6856;\n        float param_18 = max(dot(v, _6856), 0.0);\n        result += (_6867 * fa_layers_coat(param_15, param_16, param_17, param_18));\n    }\n    return result;\n}\n\nfloat fa_d_ggx_aniso(float ndh, float tdh, float bdh, float at, float ab)\n{\n    float _4817 = tdh / at;\n    float _4821 = bdh / ab;\n    float _4833 = ((_4817 * _4817) + (_4821 * _4821)) + (ndh * ndh);\n    return 1.0 / ((((3.1415927410125732421875 * at) * ab) * _4833) * _4833);\n}\n\nfloat fa_lambda_ggx_aniso(float n, float t, float b, float at, float ab)\n{\n    return 0.5 * (sqrt(1.0 + (((((at * at) * t) * t) + (((ab * ab) * b) * b)) / max(n * n, 9.9999999392252902907785028219223e-09))) - 1.0);\n}\n\nfloat fa_v_ggx_aniso(float ndl, float ndv, float tdv, float bdv, float tdl, float bdl, float at, float ab)\n{\n    float param = ndv;\n    float param_1 = tdv;\n    float param_2 = bdv;\n    float param_3 = at;\n    float param_4 = ab;\n    float param_5 = ndl;\n    float param_6 = tdl;\n    float param_7 = bdl;\n    float param_8 = at;\n    float param_9 = ab;\n    return clamp(1.0 / ((4.0 * max(ndl * ndv, 9.9999997473787516355514526367188e-05)) * ((1.0 + fa_lambda_ggx_aniso(param, param_1, param_2, param_3, param_4)) + fa_lambda_ggx_aniso(param_5, param_6, param_7, param_8, param_9))), 0.0, 1.0);\n}\n\nvec3 fa_layers_light(FaLayers L, vec3 diffuse_color, vec3 f0, vec3 n, vec3 v, vec3 l, vec3 h, float ndl, float ndv, float ndh, float vdh, float alpha, float a2)\n{\n    float _5013 = step(9.9999997473787516355514526367188e-05, ndl);\n    float d_ggx;\n    float vis;\n    if (L.aniso != 0.0)\n    {\n        float param = ndh;\n        float param_1 = dot(L.t, h);\n        float param_2 = dot(L.b, h);\n        float param_3 = L.at;\n        float param_4 = L.ab;\n        d_ggx = fa_d_ggx_aniso(param, param_1, param_2, param_3, param_4);\n        float param_5 = ndl;\n        float param_6 = ndv;\n        float param_7 = dot(L.t, v);\n        float param_8 = dot(L.b, v);\n        float param_9 = dot(L.t, l);\n        float param_10 = dot(L.b, l);\n        float param_11 = L.at;\n        float param_12 = L.ab;\n        vis = fa_v_ggx_aniso(param_5, param_6, param_7, param_8, param_9, param_10, param_11, param_12);\n    }\n    else\n    {\n        float _5092 = ((ndh * ndh) * (a2 - 1.0)) + 1.0;\n        d_ggx = a2 / ((3.1415927410125732421875 * _5092) * _5092);\n        vis = 0.5 / max(mix((2.0 * ndl) * ndv, ndl + ndv, alpha), 9.9999997473787516355514526367188e-05);\n    }\n    vec3 base = diffuse_color + (((f0 + ((vec3(L.f90) - f0) * pow(clamp(1.0 - vdh, 0.0, 1.0), 5.0))) * ((d_ggx * vis) * 3.1415927410125732421875)) * _5013);\n    if (L.sheen_on)\n    {\n        float param_13 = L.sheen_alpha;\n        float param_14 = ndh;\n        float param_15 = ndl;\n        float param_16 = ndv;\n        base = (base * L.sheen_scale) + (L.sheen * (((fa_d_charlie(param_13, param_14) * fa_v_ashikhmin(param_15, param_16)) * 3.1415927410125732421875) * _5013));\n    }\n    vec3 result = base * (L.keep * ndl);\n    if (L.coat > 0.0)\n    {\n        FaLayers param_17 = L;\n        vec3 param_18 = l;\n        vec3 param_19 = h;\n        float param_20 = vdh;\n        result += vec3(fa_layers_coat(param_17, param_18, param_19, param_20));\n    }\n    return result;\n}\n\nvec2 fa_env_brdf(float rough, float ndv)\n{\n    vec4 _4216 = (vec4(-1.0, -0.0274999998509883880615234375, -0.572000026702880859375, 0.02199999988079071044921875) * rough) + vec4(1.0, 0.0425000004470348358154296875, 1.03999996185302734375, -0.039999999105930328369140625);\n    float _4219 = _4216.x;\n    return (vec2(-1.03999996185302734375, 1.03999996185302734375) * ((min(_4219 * _4219, exp2((-9.27999973297119140625) * ndv)) * _4219) + _4216.y)) + _4216.zw;\n}\n\nvec3 fa_probe_level(vec2 origin, float res, int lv, vec2 e)\n{\n    float _3524;\n    if (lv == 0)\n    {\n        _3524 = 0.0;\n    }\n    else\n    {\n        _3524 = res + 2.0;\n    }\n    float _3534;\n    if (lv == 0)\n    {\n        _3534 = 0.0;\n    }\n    else\n    {\n        _3534 = (res - (res / float(1 << max((lv - 1), 0)))) + (2.0 * float(lv - 1));\n    }\n    return textureLod(fa_probe_atlas_fa_env_smp, (((origin + vec2(_3524, _3534)) + vec2(1.0)) + (((e * 0.5) + vec2(0.5)) * (res / float(1 << lv)))) / fa_atlas_size(), 0.0).xyz;\n}\n\nvec3 fa_probe_radiance(vec2 origin, float res, vec3 d, float rough)\n{\n    float _3580;\n    if (res > 64.5)\n    {\n        _3580 = 5.0;\n    }\n    else\n    {\n        _3580 = (res > 32.5) ? 4.0 : 3.0;\n    }\n    float _3595 = clamp(rough, 0.0, 1.0) * (_3580 - 1.0);\n    int _3602 = int(min(floor(_3595), _3580 - 2.0));\n    float _3607 = _3595 - float(_3602);\n    vec3 param = d;\n    vec2 _3611 = fa_oct_encode(param);\n    vec2 param_1 = origin;\n    float param_2 = res;\n    int param_3 = _3602;\n    vec2 param_4 = _3611;\n    vec3 _3621 = fa_probe_level(param_1, param_2, param_3, param_4);\n    if (_3607 < 0.00200000009499490261077880859375)\n    {\n        return _3621;\n    }\n    vec2 param_5 = origin;\n    float param_6 = res;\n    int param_7 = _3602 + 1;\n    vec2 param_8 = _3611;\n    return mix(_3621, fa_probe_level(param_5, param_6, param_7, param_8), vec3(_3607));\n}\n\nvec3 fa_probe_box_dir(vec3 d, vec4 posw, vec4 bx, vec4 by, vec4 bz)\n{\n    if (posw.w < 0.5)\n    {\n        return d;\n    }\n    float _3694 = dot(bx.xyz, fa_world_pos) + bx.w;\n    float _3701 = dot(by.xyz, fa_world_pos) + by.w;\n    float _3708 = dot(bz.xyz, fa_world_pos) + bz.w;\n    float _3714 = dot(bx.xyz, d);\n    float _3718 = dot(by.xyz, d);\n    float _3722 = dot(bz.xyz, d);\n    float _3728;\n    if (_3714 > 9.9999999747524270787835121154785e-07)\n    {\n        _3728 = (1.0 - _3694) / _3714;\n    }\n    else\n    {\n        float _3742;\n        if (_3714 < (-9.9999999747524270787835121154785e-07))\n        {\n            _3742 = ((-1.0) - _3694) / _3714;\n        }\n        else\n        {\n            _3742 = 1000000015047466219876688855040.0;\n        }\n        _3728 = _3742;\n    }\n    float tx = _3728;\n    float _3759;\n    if (_3718 > 9.9999999747524270787835121154785e-07)\n    {\n        _3759 = (1.0 - _3701) / _3718;\n    }\n    else\n    {\n        float _3772;\n        if (_3718 < (-9.9999999747524270787835121154785e-07))\n        {\n            _3772 = ((-1.0) - _3701) / _3718;\n        }\n        else\n        {\n            _3772 = 1000000015047466219876688855040.0;\n        }\n        _3759 = _3772;\n    }\n    float ty = _3759;\n    float _3788;\n    if (_3722 > 9.9999999747524270787835121154785e-07)\n    {\n        _3788 = (1.0 - _3708) / _3722;\n    }\n    else\n    {\n        float _3801;\n        if (_3722 < (-9.9999999747524270787835121154785e-07))\n        {\n            _3801 = ((-1.0) - _3708) / _3722;\n        }\n        else\n        {\n            _3801 = 1000000015047466219876688855040.0;\n        }\n        _3788 = _3801;\n    }\n    float _3813 = tx;\n    float _3816 = (_3813 > 0.0) ? _3813 : 1000000015047466219876688855040.0;\n    tx = _3816;\n    float _3817 = ty;\n    float _3820 = (_3817 > 0.0) ? _3817 : 1000000015047466219876688855040.0;\n    ty = _3820;\n    float _3830 = min(_3816, min(_3820, (_3788 > 0.0) ? _3788 : 1000000015047466219876688855040.0));\n    if (_3830 > 100000001504746621987668885504.0)\n    {\n        return d;\n    }\n    vec3 _3846 = (fa_world_pos + (d * _3830)) - posw.xyz;\n    vec3 _3851;\n    if (dot(_3846, _3846) > 1.0000000133514319600180897396058e-10)\n    {\n        _3851 = normalize(_3846);\n    }\n    else\n    {\n        _3851 = d;\n    }\n    return _3851;\n}\n\nvec3 fa_probe_environment(vec4 tile, vec4 posw, vec4 bx, vec4 by, vec4 bz, inout vec3 d, float rough)\n{\n    vec3 param = d;\n    vec4 param_1 = posw;\n    vec4 param_2 = bx;\n    vec4 param_3 = by;\n    vec4 param_4 = bz;\n    d = fa_probe_box_dir(param, param_1, param_2, param_3, param_4);\n    vec2 param_5 = tile.xy;\n    float param_6 = tile.z;\n    vec3 param_7 = d;\n    float param_8 = rough;\n    return fa_probe_radiance(param_5, param_6, param_7, param_8);\n}\n\nvec3 fa_environment(vec3 d, float rough)\n{\n    float _3897 = (1.0 - fa_mesh_fs_params[42].w) - fa_mesh_fs_params[47].w;\n    vec3 outc = vec3(0.0);\n    if (_3897 > 0.0005000000237487256526947021484375)\n    {\n        vec3 base;\n        if (fa_mesh_fs_params[11].w > 0.5)\n        {\n            vec2 param = fa_mesh_fs_params[41].zw;\n            float param_1 = 128.0;\n            vec3 param_2 = d;\n            float param_3 = rough;\n            base = fa_probe_radiance(param, param_1, param_2, param_3);\n        }\n        else\n        {\n            float _3925 = rough * rough;\n            float _3956 = 0.60000002384185791015625 * _3925;\n            base = mix(mix(fa_mesh_fs_params[12].xyz * 0.550000011920928955078125, mix(fa_mesh_fs_params[12].xyz, fa_mesh_fs_params[11].xyz, vec3(pow(clamp(d.y * (1.0 - (0.699999988079071044921875 * _3925)), 0.0, 1.0), 0.550000011920928955078125))), vec3(smoothstep((-0.0500000007450580596923828125) - _3956, 0.0500000007450580596923828125 + _3956, d.y))), ((fa_mesh_fs_params[11].xyz + fa_mesh_fs_params[12].xyz) * 0.5) * 0.800000011920928955078125, vec3(_3925 * 0.60000002384185791015625));\n        }\n        outc = base * _3897;\n    }\n    if (fa_mesh_fs_params[42].w > 0.0)\n    {\n        vec4 param_4 = fa_mesh_fs_params[42];\n        vec4 param_5 = fa_mesh_fs_params[43];\n        vec4 param_6 = fa_mesh_fs_params[44];\n        vec4 param_7 = fa_mesh_fs_params[45];\n        vec4 param_8 = fa_mesh_fs_params[46];\n        vec3 param_9 = d;\n        float param_10 = rough;\n        vec3 _4015 = fa_probe_environment(param_4, param_5, param_6, param_7, param_8, param_9, param_10);\n        outc += (_4015 * fa_mesh_fs_params[42].w);\n    }\n    if (fa_mesh_fs_params[47].w > 0.0)\n    {\n        vec4 param_11 = fa_mesh_fs_params[47];\n        vec4 param_12 = fa_mesh_fs_params[48];\n        vec4 param_13 = fa_mesh_fs_params[49];\n        vec4 param_14 = fa_mesh_fs_params[50];\n        vec4 param_15 = fa_mesh_fs_params[51];\n        vec3 param_16 = d;\n        float param_17 = rough;\n        vec3 _4047 = fa_probe_environment(param_11, param_12, param_13, param_14, param_15, param_16, param_17);\n        outc += (_4047 * fa_mesh_fs_params[47].w);\n    }\n    return outc;\n}\n\nvec3 fa_layers_ibl(FaLayers L, vec3 n, vec3 v, vec3 f0, float roughness, float occlusion)\n{\n    vec3 rn = n;\n    if (L.aniso != 0.0)\n    {\n        vec3 _4694;\n        if (L.aniso >= 0.0)\n        {\n            _4694 = L.b;\n        }\n        else\n        {\n            _4694 = L.t;\n        }\n        rn = normalize(mix(n, cross(cross(_4694, v), _4694), vec3(abs(L.aniso) * smoothstep(0.0, 0.25, roughness))));\n    }\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05);\n    vec2 _4730 = fa_env_brdf(param, param_1);\n    vec3 param_2 = reflect(-v, rn);\n    float param_3 = roughness;\n    vec3 result = (fa_environment(param_2, param_3) * ((f0 * _4730.x) + (vec3(L.f90) * _4730.y))) * L.base_scale;\n    if (L.sheen_on)\n    {\n        vec3 param_4 = n;\n        float param_5 = L.sheen_rough;\n        result += ((L.sheen * (L.sheen_e * L.keep)) * fa_environment(param_4, param_5));\n    }\n    result *= occlusion;\n    if (L.coat > 0.0)\n    {\n        float param_6 = L.coat_rough;\n        float param_7 = L.coat_ndv;\n        vec2 _4788 = fa_env_brdf(param_6, param_7);\n        vec3 param_8 = reflect(-v, L.nc);\n        float param_9 = L.coat_rough;\n        result += (fa_environment(param_8, param_9) * (L.coat * ((0.039999999105930328369140625 * _4788.x) + _4788.y)));\n    }\n    return result;\n}\n\nvec3 fa_sky_reflection(vec3 n, vec3 v, vec3 f0, float roughness)\n{\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05);\n    vec2 _4258 = fa_env_brdf(param, param_1);\n    vec3 param_2 = reflect(-v, n);\n    float param_3 = roughness;\n    return fa_environment(param_2, param_3) * ((f0 * _4258.x) + vec3(_4258.y));\n}\n\nvec2 fa_xm_size(int k)\n{\n    return max(floor(fa_mesh_fs_params[24].zw / vec2(float(1 << k))), vec2(1.0));\n}\n\nvec2 fa_xm_origin(int k)\n{\n    if (k == 0)\n    {\n        return vec2(0.0);\n    }\n    float y = 0.0;\n    for (int j = 1; j < k; j++)\n    {\n        int param = j;\n        y += fa_xm_size(param).y;\n    }\n    return vec2(fa_mesh_fs_params[24].z, y);\n}\n\nvec3 fa_xm_texel(vec2 size, vec2 origin, vec2 p)\n{\n    return texelFetch(fa_screen_tex_fa_shadow_smp, ivec2(origin + clamp(p, vec2(0.0), size - vec2(1.0))), 0).xyz;\n}\n\nvec3 fa_xm_level(int k, vec2 uv)\n{\n    int param = k;\n    vec2 _5498 = fa_xm_size(param);\n    int param_1 = k;\n    vec2 _5502 = fa_xm_origin(param_1);\n    vec2 _5508 = (uv * _5498) - vec2(0.5);\n    vec2 _5511 = fract(_5508);\n    vec2 _5514 = floor(_5508);\n    vec2 param_2 = _5498;\n    vec2 param_3 = _5502;\n    vec2 param_4 = _5514;\n    vec2 param_5 = _5498;\n    vec2 param_6 = _5502;\n    vec2 param_7 = _5514 + vec2(1.0, 0.0);\n    vec2 param_8 = _5498;\n    vec2 param_9 = _5502;\n    vec2 param_10 = _5514 + vec2(0.0, 1.0);\n    vec2 param_11 = _5498;\n    vec2 param_12 = _5502;\n    vec2 param_13 = _5514 + vec2(1.0);\n    vec3 _5556 = vec3(_5511.x);\n    return mix(mix(fa_xm_texel(param_2, param_3, param_4), fa_xm_texel(param_5, param_6, param_7), _5556), mix(fa_xm_texel(param_8, param_9, param_10), fa_xm_texel(param_11, param_12, param_13), _5556), vec3(_5511.y));\n}\n\nvec3 fa_xm_sample(vec2 uv, float lod)\n{\n    float _5575 = max(fa_mesh_fs_params[31].w - 1.0, 0.0);\n    float _5579 = clamp(lod, 0.0, _5575);\n    int _5583 = int(floor(_5579));\n    int param = _5583;\n    vec2 param_1 = uv;\n    vec3 c = fa_xm_level(param, param_1);\n    float _5593 = float(_5583);\n    float _5594 = _5579 - _5593;\n    bool _5596 = _5594 > 0.001000000047497451305389404296875;\n    bool _5603;\n    if (_5596)\n    {\n        _5603 = _5593 < _5575;\n    }\n    else\n    {\n        _5603 = _5596;\n    }\n    if (_5603)\n    {\n        int param_2 = _5583 + 1;\n        vec2 param_3 = uv;\n        c = mix(c, fa_xm_level(param_2, param_3), vec3(_5594));\n    }\n    return c;\n}\n\nvec3 fa_transmitted(Surface s, vec3 n, vec3 v, float roughness, vec3 f0, float f90, float keep, float tr, inout float blend)\n{\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05);\n    vec2 _5629 = fa_env_brdf(param, param_1);\n    vec3 through = ((vec3(1.0) - clamp((f0 * _5629.x) + (vec3(f90) * _5629.y), vec3(0.0), vec3(1.0))) * s.albedo) * (tr * keep);\n    float _5657 = max(s.thickness, 0.0);\n    bool _5662 = _5657 > 0.0;\n    if ((s.attenuation_distance > 0.0) && _5662)\n    {\n        through *= exp((-((-log(clamp(s.attenuation_color, vec3(9.9999997473787516355514526367188e-05), vec3(1.0)))) / vec3(s.attenuation_distance))) * _5657);\n    }\n    bool _5687 = fa_mesh_fs_params[30].w > 1.5;\n    bool _5694;\n    if (!_5687)\n    {\n        _5694 = fa_mesh_fs_params[30].w < 0.5;\n    }\n    else\n    {\n        _5694 = _5687;\n    }\n    if (_5694)\n    {\n        blend = clamp(dot(through, vec3(0.3333333432674407958984375)), 0.0, 0.980000019073486328125);\n        return vec3(0.0);\n    }\n    vec3 world = fa_world_pos;\n    if (_5662)\n    {\n        world += (refract(-v, n, 1.0 / max(s.ior, 1.0)) * _5657);\n    }\n    vec4 _5729 = vec4(world, 1.0);\n    float _5734 = dot(fa_mesh_fs_params[28], _5729);\n    vec2 uv = vec2(0.5);\n    if (_5734 > 9.9999997473787516355514526367188e-05)\n    {\n        vec2 _5752 = vec2(dot(fa_mesh_fs_params[26], _5729), dot(fa_mesh_fs_params[27], _5729)) / vec2(_5734);\n        float _5760;\n        if (fa_mesh_fs_params[24].y > 0.5)\n        {\n            _5760 = (_5752.y * 0.5) + 0.5;\n        }\n        else\n        {\n            _5760 = 0.5 - (_5752.y * 0.5);\n        }\n        uv = vec2((_5752.x * 0.5) + 0.5, _5760);\n    }\n    vec2 param_2 = clamp(uv, vec2(0.0), vec2(1.0));\n    float param_3 = (clamp(roughness, 0.0, 1.0) * clamp((2.0 * s.ior) - 2.0, 0.0, 1.0)) * max(fa_mesh_fs_params[31].w - 1.0, 0.0);\n    return through * fa_xm_sample(param_2, param_3);\n}\n\nvec3 fa_shadow_debug(vec3 color, vec3 world)\n{\n    if (fa_shadows[27].w < 0.5)\n    {\n        return color;\n    }\n    int _3275 = int(fa_shadows[25].x + 0.5);\n    float _3285 = dot(world - fa_shadows[27].xyz, fa_shadows[28].xyz);\n    vec3 tint_1 = vec3(0.3499999940395355224609375);\n    bool _3290 = _3275 > 0;\n    bool _3299;\n    if (_3290)\n    {\n        int param = _3275 - 1;\n        _3299 = _3285 <= fa_shadow_split_at(param);\n    }\n    else\n    {\n        _3299 = _3290;\n    }\n    if (_3299)\n    {\n        tint_1 = vec3(1.0, 0.1500000059604644775390625, 0.100000001490116119384765625);\n        bool _3305 = _3275 > 1;\n        bool _3312;\n        if (_3305)\n        {\n            _3312 = _3285 > fa_shadows[24].x;\n        }\n        else\n        {\n            _3312 = _3305;\n        }\n        if (_3312)\n        {\n            tint_1 = vec3(0.100000001490116119384765625, 0.89999997615814208984375, 0.20000000298023223876953125);\n        }\n        bool _3318 = _3275 > 2;\n        bool _3325;\n        if (_3318)\n        {\n            _3325 = _3285 > fa_shadows[24].y;\n        }\n        else\n        {\n            _3325 = _3318;\n        }\n        if (_3325)\n        {\n            tint_1 = vec3(0.1500000059604644775390625, 0.300000011920928955078125, 1.0);\n        }\n        bool _3331 = _3275 > 3;\n        bool _3338;\n        if (_3331)\n        {\n            _3338 = _3285 > fa_shadows[24].z;\n        }\n        else\n        {\n            _3338 = _3331;\n        }\n        if (_3338)\n        {\n            tint_1 = vec3(1.0, 0.89999997615814208984375, 0.100000001490116119384765625);\n        }\n    }\n    return mix(color, tint_1, vec3(0.550000011920928955078125));\n}\n\nvoid main()\n{\n    fa_inst_load();\n    vec3 _8717 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _8717 = -_8717;\n    }\n    vec3 _8011 = normalize(fa_mesh_fs_params[0].xyz - fa_world_pos);\n    vec3 param = fa_world_pos;\n    fa_cluster_begin(param);\n    SurfaceInput param_1 = SurfaceInput(fa_world_pos, _8717, fa_world_tangent, fa_uv, fa_vertex_color, _8011, gl_FrontFacing);\n    Surface _8019 = fa_standard_surface(param_1);\n    vec3 _8748 = _8019.albedo;\n    float _8749 = _8019.alpha;\n    vec3 _8750 = _8019.normal;\n    float _8751 = _8019.metallic;\n    float _8752 = _8019.roughness;\n    float _8753 = _8019.occlusion;\n    vec3 _8754 = _8019.emission;\n    float _8755 = _8019.clearcoat;\n    float _8756 = _8019.clearcoat_roughness;\n    vec3 _8757 = _8019.sheen_color;\n    float _8758 = _8019.sheen_roughness;\n    float _8759 = _8019.anisotropy;\n    float _8760 = _8019.anisotropy_rotation;\n    float _8761 = _8019.specular;\n    float _8762 = _8019.ior;\n    vec3 _8763 = _8019.specular_color;\n    float _8764 = _8019.transmission;\n    float _8765 = _8019.thickness;\n    vec3 _8766 = _8019.attenuation_color;\n    float _8767 = _8019.attenuation_distance;\n    SurfaceInput param_2 = SurfaceInput(fa_world_pos, _8717, fa_world_tangent, fa_uv, fa_vertex_color, _8011, gl_FrontFacing);\n    Surface param_3 = _8019;\n    surface(param_2, param_3);\n    _8748 = param_3.albedo;\n    _8749 = param_3.alpha;\n    _8750 = param_3.normal;\n    _8751 = param_3.metallic;\n    _8752 = param_3.roughness;\n    _8753 = param_3.occlusion;\n    _8754 = param_3.emission;\n    _8755 = param_3.clearcoat;\n    _8756 = param_3.clearcoat_roughness;\n    _8757 = param_3.sheen_color;\n    _8758 = param_3.sheen_roughness;\n    _8759 = param_3.anisotropy;\n    _8760 = param_3.anisotropy_rotation;\n    _8761 = param_3.specular;\n    _8762 = param_3.ior;\n    _8763 = param_3.specular_color;\n    _8764 = param_3.transmission;\n    _8765 = param_3.thickness;\n    _8766 = param_3.attenuation_color;\n    _8767 = param_3.attenuation_distance;\n    vec3 param_4 = fa_world_pos;\n    vec3 param_5 = _8717;\n    vec3 param_6 = param_3.albedo;\n    vec3 param_7 = param_3.normal;\n    fa_apply_decals(param_4, param_5, param_6, param_7);\n    _8748 = param_6;\n    _8750 = param_7;\n    float fa_tr_blend = 0.0;\n    vec3 result;\n    if (fa_mesh_fs_params[3].w > 0.5)\n    {\n        result = _8748;\n    }\n    else\n    {\n        vec3 _8059 = normalize(_8750);\n        float _8066 = clamp(_8751, 0.0, 1.0);\n        float _8070 = clamp(_8752, 0.0500000007450580596923828125, 1.0);\n        float _8074 = _8070 * _8070;\n        float _8078 = _8074 * _8074;\n        float _8083 = max(dot(_8059, _8011), 9.9999997473787516355514526367188e-05);\n        float _8089 = 1.0 - _8066;\n        float _8090 = clamp(_8764, 0.0, 1.0) * _8089;\n        vec3 _8099 = (_8748 * _8089) * (1.0 - _8090);\n        vec3 _8106 = mix(vec3(0.039999999105930328369140625), _8748, vec3(_8066));\n        vec3 f0 = _8106;\n        SurfaceInput param_8 = SurfaceInput(fa_world_pos, _8717, fa_world_tangent, fa_uv, fa_vertex_color, _8011, gl_FrontFacing);\n        Surface param_9 = Surface(_8748, _8749, _8750, _8751, _8752, _8753, _8754, _8755, _8756, _8757, _8758, _8759, _8760, _8761, _8762, _8763, _8764, _8765, _8766, _8767);\n        vec3 param_10 = _8059;\n        vec3 param_11 = _8011;\n        float param_12 = _8066;\n        float param_13 = _8070;\n        vec3 param_14 = _8106;\n        FaLayers _8122 = fa_layers_setup(param_8, param_9, param_10, param_11, param_12, param_13, param_14);\n        f0 = param_14;\n        vec3 param_15 = _8059;\n        vec3 lit = (fa_indirect_diffuse(param_15) * _8099) * _8753;\n        if (_8122.on)\n        {\n            lit *= _8122.base_scale;\n        }\n        int _8144 = fa_cl_ndir + fa_cl_local;\n        for (int ln = 0; ln < _8144; ln++)\n        {\n            int param_16 = ln;\n            int _8157 = fa_cl_light(param_16);\n            int param_17 = _8157;\n            if (fa_baked_keep(param_17) <= 0.0)\n            {\n                continue;\n            }\n            int param_18 = _8157;\n            vec3 param_19 = fa_world_pos;\n            vec3 param_20 = _8717;\n            LightSample _8173 = fa_light_shadowed(param_18, param_19, param_20);\n            float _8181 = max(dot(_8059, _8173.direction), 0.0);\n            float _8187 = _8173.attenuation * _8173.shadow;\n            vec3 _8192 = normalize(_8173.direction + _8011);\n            float _8197 = max(dot(_8059, _8192), 0.0);\n            float _8202 = max(dot(_8011, _8192), 0.0);\n            bool _8209;\n            if (fa_light_is_area)\n            {\n                _8209 = !_8122.on;\n            }\n            else\n            {\n                _8209 = fa_light_is_area;\n            }\n            if (_8209)\n            {\n                int param_21 = _8157;\n                vec3 param_22 = fa_world_pos;\n                vec3 param_23 = _8059;\n                vec3 param_24 = _8011;\n                vec3 param_25 = _8099;\n                vec3 param_26 = f0;\n                float param_27 = 1.0;\n                float param_28 = _8070;\n                float param_29 = _8083;\n                float param_30 = _8187;\n                lit += fa_area_shade(param_21, param_22, param_23, param_24, param_25, param_26, param_27, param_28, param_29, param_30);\n            }\n            else\n            {\n                if (fa_light_is_area)\n                {\n                    FaLayers param_31 = _8122;\n                    int param_32 = _8157;\n                    vec3 param_33 = fa_world_pos;\n                    vec3 param_34 = _8059;\n                    vec3 param_35 = _8011;\n                    vec3 param_36 = _8173.direction;\n                    vec3 param_37 = _8099;\n                    vec3 param_38 = f0;\n                    float param_39 = _8070;\n                    float param_40 = _8083;\n                    float param_41 = _8187;\n                    lit += fa_area_layers(param_31, param_32, param_33, param_34, param_35, param_36, param_37, param_38, param_39, param_40, param_41);\n                }\n                else\n                {\n                    if (_8122.on)\n                    {\n                        FaLayers param_42 = _8122;\n                        vec3 param_43 = _8099;\n                        vec3 param_44 = f0;\n                        vec3 param_45 = _8059;\n                        vec3 param_46 = _8011;\n                        vec3 param_47 = _8173.direction;\n                        vec3 param_48 = _8192;\n                        float param_49 = _8181;\n                        float param_50 = _8083;\n                        float param_51 = _8197;\n                        float param_52 = _8202;\n                        float param_53 = _8074;\n                        float param_54 = _8078;\n                        int param_55 = _8157;\n                        lit += (fa_layers_light(param_42, param_43, param_44, param_45, param_46, param_47, param_48, param_49, param_50, param_51, param_52, param_53, param_54) * ((fa_light_rgb(param_55) * fa_light_tint) * _8187));\n                    }\n                    else\n                    {\n                        float _8315 = ((_8197 * _8197) * (_8078 - 1.0)) + 1.0;\n                        int param_56 = _8157;\n                        lit += (((_8099 + (((f0 + ((vec3(1.0) - f0) * pow(1.0 - _8202, 5.0))) * (((_8078 / ((3.1415927410125732421875 * _8315) * _8315)) * (0.5 / max(mix((2.0 * _8181) * _8083, _8181 + _8083, _8074), 9.9999997473787516355514526367188e-05))) * 3.1415927410125732421875)) * step(9.9999997473787516355514526367188e-05, _8181))) * (fa_light_rgb(param_56) * fa_light_tint)) * (_8181 * _8187));\n                    }\n                }\n            }\n        }\n        if (_8122.on)\n        {\n            FaLayers param_57 = _8122;\n            vec3 param_58 = _8059;\n            vec3 param_59 = _8011;\n            vec3 param_60 = f0;\n            float param_61 = _8070;\n            float param_62 = _8753;\n            lit += fa_layers_ibl(param_57, param_58, param_59, param_60, param_61, param_62);\n        }\n        else\n        {\n            vec3 param_63 = _8059;\n            vec3 param_64 = _8011;\n            vec3 param_65 = f0;\n            float param_66 = _8070;\n            lit += (fa_sky_reflection(param_63, param_64, param_65, param_66) * _8753);\n        }\n        if (_8090 > 0.0)\n        {\n            float _8413;\n            if (_8122.on)\n            {\n                _8413 = _8122.f90;\n            }\n            else\n            {\n                _8413 = 1.0;\n            }\n            float _8421;\n            if (_8122.on)\n            {\n                _8421 = _8122.base_scale;\n            }\n            else\n            {\n                _8421 = 1.0;\n            }\n            Surface param_67 = Surface(_8748, _8749, _8750, _8751, _8752, _8753, _8754, _8755, _8756, _8757, _8758, _8759, _8760, _8761, _8762, _8763, _8764, _8765, _8766, _8767);\n            vec3 param_68 = _8059;\n            vec3 param_69 = _8011;\n            float param_70 = _8070;\n            vec3 param_71 = f0;\n            float param_72 = _8413;\n            float param_73 = _8421;\n            float param_74 = _8090;\n            float param_75 = fa_tr_blend;\n            vec3 _8445 = fa_transmitted(param_67, param_68, param_69, param_70, param_71, param_72, param_73, param_74, param_75);\n            fa_tr_blend = param_75;\n            lit += _8445;\n        }\n        result = lit;\n    }\n    vec3 _8452 = result;\n    vec3 _8453 = _8452 + _8754;\n    result = _8453;\n    vec3 param_76 = _8453;\n    vec3 param_77 = fa_world_pos;\n    result = fa_shadow_debug(param_76, param_77);\n    bool _8462 = fa_mesh_fs_params[7].w > 0.0;\n    bool _8469;\n    if (!_8462)\n    {\n        _8469 = fa_mesh_fs_params[8].y > 0.0;\n    }\n    else\n    {\n        _8469 = _8462;\n    }\n    if (_8469)\n    {\n        vec3 _8478 = fa_world_pos - fa_mesh_fs_params[0].xyz;\n        float _8484 = dot(_8478, fa_mesh_fs_params[9].xyz);\n        bool _8488 = fa_mesh_fs_params[9].w > 0.5;\n        float _8489;\n        if (_8488)\n        {\n            _8489 = _8484;\n        }\n        else\n        {\n            _8489 = length(_8478);\n        }\n        float _8501 = _8489 - fa_mesh_fs_params[8].x;\n        if (_8501 > 0.0)\n        {\n            float _8510 = fa_mesh_fs_params[7].w * _8501;\n            float tau = _8510 * _8510;\n            if (fa_mesh_fs_params[8].y > 0.0)\n            {\n                float _8526;\n                if (_8488)\n                {\n                    _8526 = fa_world_pos.y - (fa_mesh_fs_params[9].y * _8484);\n                }\n                else\n                {\n                    _8526 = fa_mesh_fs_params[0].y;\n                }\n                float _8547 = mix(_8526, fa_world_pos.y, clamp(fa_mesh_fs_params[8].x / _8489, 0.0, 1.0));\n                float _8551 = fa_world_pos.y - _8547;\n                float _8556 = _8547 - fa_mesh_fs_params[8].z;\n                float _8561 = fa_world_pos.y - fa_mesh_fs_params[8].z;\n                bool _8564 = _8556 <= 0.0;\n                bool _8565 = !_8564;\n                bool _8571;\n                if (_8565)\n                {\n                    _8571 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _8571 = _8564;\n                }\n                float _8572;\n                if (_8571)\n                {\n                    _8572 = fa_mesh_fs_params[8].y;\n                }\n                else\n                {\n                    _8572 = fa_mesh_fs_params[8].y * exp(-min(fa_mesh_fs_params[8].w * _8556, 80.0));\n                }\n                bool _8599;\n                if (_8565)\n                {\n                    _8599 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _8599 = _8564;\n                }\n                float _8600;\n                if (_8599)\n                {\n                    _8600 = fa_mesh_fs_params[8].y * _8556;\n                }\n                else\n                {\n                    _8600 = (fa_mesh_fs_params[8].y * (1.0 - exp(-min(fa_mesh_fs_params[8].w * _8556, 80.0)))) / fa_mesh_fs_params[8].w;\n                }\n                bool _8625 = _8561 <= 0.0;\n                bool _8632;\n                if (!_8625)\n                {\n                    _8632 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _8632 = _8625;\n                }\n                float _8633;\n                if (_8632)\n                {\n                    _8633 = fa_mesh_fs_params[8].y * _8561;\n                }\n                else\n                {\n                    _8633 = (fa_mesh_fs_params[8].y * (1.0 - exp(-min(fa_mesh_fs_params[8].w * _8561, 80.0)))) / fa_mesh_fs_params[8].w;\n                }\n                float _8660;\n                if (abs(_8551) < 0.001000000047497451305389404296875)\n                {\n                    _8660 = _8572;\n                }\n                else\n                {\n                    _8660 = (_8633 - _8600) / _8551;\n                }\n                tau += (_8501 * max(_8660, 0.0));\n            }\n            result = mix(result, fa_mesh_fs_params[7].xyz, vec3(clamp(1.0 - exp(-clamp(tau, 0.0, 80.0)), 0.0, 1.0)));\n        }\n    }\n    if (fa_tr_blend > 0.0)\n    {\n        float _8696 = 1.0 - fa_tr_blend;\n        result /= vec3(_8696);\n        _8749 *= _8696;\n    }\n    fa_frag_color = vec4(result, _8749);\n}\n\n",
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
            "size": 848,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_659",
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
            "inst_name": "_2321",
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
            "inst_name": "_6945",
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
              "name": "fa_probe_atlas",
              "multisampled": false,
              "type": "2d",
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
      "vs": "#version 430\n\nstruct VertexData\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 color;\n    vec3 object_pos;\n};\n\nuniform vec4 fa_mesh_vs_params[11];\nuniform vec4 fa_skin[192];\nlayout(location = 2) out vec3 fa_world_pos;\nlayout(location = 3) out vec3 fa_world_normal;\nlayout(location = 4) out vec4 fa_world_tangent;\nlayout(location = 5) out vec2 fa_uv;\nlayout(location = 6) out vec4 fa_vertex_color;\nlayout(location = 11) in vec4 fa_inst_d0;\nlayout(location = 12) in vec4 fa_inst_d1;\nlayout(location = 0) flat out vec4 fa_inst_v0;\nlayout(location = 1) flat out vec4 fa_inst_v1;\nlayout(location = 5) in vec4 fa_inst_m0;\nlayout(location = 6) in vec4 fa_inst_m1;\nlayout(location = 7) in vec4 fa_inst_m2;\nlayout(location = 8) in vec4 fa_inst_m3;\nlayout(location = 9) in vec4 fa_joints;\nlayout(location = 10) in vec4 fa_weights;\nlayout(location = 0) in vec3 fa_position;\nlayout(location = 1) in vec3 fa_normal;\nlayout(location = 3) in vec4 fa_tangent;\nlayout(location = 2) in vec2 fa_texcoord0;\nlayout(location = 4) in vec4 fa_color;\nlayout(location = 7) out vec3 fa_lm;\nfloat raise;\nvec4 tint;\n\nvoid fa_instance_unpack(vec4 fa_d0, vec4 fa_d1, vec4 fa_d2)\n{\n    raise = fa_d0.x;\n    tint = fa_d1;\n}\n\nvoid fa_inst_begin()\n{\n    vec4 param = fa_inst_d0;\n    vec4 param_1 = fa_inst_d1;\n    vec4 param_2 = vec4(0.0);\n    fa_instance_unpack(param, param_1, param_2);\n    fa_inst_v0 = fa_inst_d0;\n    fa_inst_v1 = fa_inst_d1;\n}\n\nmat4 fa_skin_matrix(vec4 joints, vec4 weights)\n{\n    vec4 r0 = vec4(0.0);\n    vec4 r1 = vec4(0.0);\n    vec4 r2 = vec4(0.0);\n    for (int i = 0; i < 4; i++)\n    {\n        int _196 = int((joints[i] * 255.0) + 0.5) * 3;\n        r0 += (fa_skin[_196 * 1 + 0] * weights[i]);\n        r1 += (fa_skin[(_196 + 1) * 1 + 0] * weights[i]);\n        r2 += (fa_skin[(_196 + 2) * 1 + 0] * weights[i]);\n    }\n    return mat4(vec4(r0.x, r1.x, r2.x, 0.0), vec4(r0.y, r1.y, r2.y, 0.0), vec4(r0.z, r1.z, r2.z, 0.0), vec4(r0.w, r1.w, r2.w, 1.0));\n}\n\nVertexData fa_vertex_data(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    vec3 _99 = cross(model[1].xyz, model[2].xyz);\n    float _105 = (dot(model[0].xyz, _99) < 0.0) ? (-1.0) : 1.0;\n    return VertexData((model * vec4(position, 1.0)).xyz, (((_99 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _105, vec4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _105), texcoord0 * fa_mesh_vs_params[8].xy, color, position);\n}\n\nvoid vertex(inout VertexData v)\n{\n    v.world_pos.y += raise;\n}\n\nvoid fa_shade_vertex(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    mat4 param = model;\n    vec3 param_1 = position;\n    vec3 param_2 = normal;\n    vec4 param_3 = tangent;\n    vec2 param_4 = texcoord0;\n    vec4 param_5 = color;\n    VertexData param_6 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    vertex(param_6);\n    fa_world_pos = param_6.world_pos;\n    fa_world_normal = param_6.world_normal;\n    fa_world_tangent = param_6.world_tangent;\n    fa_uv = param_6.uv;\n    fa_vertex_color = param_6.color;\n    gl_Position = mat4(fa_mesh_vs_params[0], fa_mesh_vs_params[1], fa_mesh_vs_params[2], fa_mesh_vs_params[3]) * vec4(param_6.world_pos, 1.0);\n}\n\nvoid main()\n{\n    fa_inst_begin();\n    vec4 param = fa_joints;\n    vec4 param_1 = fa_weights;\n    mat4 param_2 = mat4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3) * fa_skin_matrix(param, param_1);\n    vec3 param_3 = fa_position;\n    vec3 param_4 = fa_normal;\n    vec4 param_5 = fa_tangent;\n    vec2 param_6 = fa_texcoord0;\n    vec4 param_7 = fa_color;\n    fa_shade_vertex(param_2, param_3, param_4, param_5, param_6, param_7);\n    fa_lm = vec3(0.0);\n}\n\n",
      "fs": "#version 430\n\nstruct SurfaceInput\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 vertex_color;\n    vec3 view_dir;\n    bool front_facing;\n};\n\nstruct LightSample\n{\n    vec3 direction;\n    vec3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct Surface\n{\n    vec3 albedo;\n    float alpha;\n    vec3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    vec3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    vec3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    vec3 specular_color;\n    float transmission;\n    float thickness;\n    vec3 attenuation_color;\n    float attenuation_distance;\n};\n\nstruct FaLayers\n{\n    bool on;\n    float f90;\n    float keep;\n    float base_scale;\n    float coat;\n    float coat_rough;\n    float coat_alpha;\n    float coat_a2;\n    vec3 nc;\n    float coat_ndv;\n    bool sheen_on;\n    vec3 sheen;\n    float sheen_rough;\n    float sheen_alpha;\n    float sheen_scale;\n    float sheen_e;\n    float aniso;\n    vec3 t;\n    vec3 b;\n    float at;\n    float ab;\n};\n\nconst float _4359[63] = float[](1.0, 1.0, 1.0, 0.4790000021457672119140625, 0.11699999868869781494140625, 0.01200000010430812835693359375, 0.0, 0.0, 0.0, 1.0, 1.0, 1.0, 0.578000009059906005859375, 0.19300000369548797607421875, 0.0350000001490116119384765625, 0.0030000000260770320892333984375, 0.0, 0.0, 1.0, 1.0, 1.0, 0.6740000247955322265625, 0.3459999859333038330078125, 0.1319999992847442626953125, 0.032999999821186065673828125, 0.0040000001899898052215576171875, 0.0, 0.971000015735626220703125, 0.954999983310699462890625, 0.828999996185302734375, 0.63999998569488525390625, 0.42599999904632568359375, 0.24500000476837158203125, 0.115000002086162567138671875, 0.037000000476837158203125, 0.0030000000260770320892333984375, 0.7469999790191650390625, 0.737999975681304931640625, 0.670000016689300537109375, 0.563000023365020751953125, 0.4309999942779541015625, 0.3039999902248382568359375, 0.1940000057220458984375, 0.1019999980926513671875, 0.0309999994933605194091796875, 0.614000022411346435546875, 0.609000027179718017578125, 0.566999971866607666015625, 0.499000012874603271484375, 0.412000000476837158203125, 0.32400000095367431640625, 0.240999996662139892578125, 0.162000000476837158203125, 0.087999999523162841796875, 0.538999974727630615234375, 0.535000026226043701171875, 0.505999982357025146484375, 0.4569999873638153076171875, 0.393999993801116943359375, 0.328999996185302734375, 0.2660000026226043701171875, 0.203999996185302734375, 0.14200000464916229248046875);\n\nuniform vec4 fa_mesh_fs_params[53];\nuniform vec4 fa_shadows[30];\nuniform vec4 fa_material[1];\nlayout(binding = 0) uniform sampler2D fa_light_tex_fa_shadow_smp;\nlayout(binding = 1) uniform sampler2D fa_tex_fa_smp;\nlayout(binding = 2) uniform sampler2D fa_normal_tex_fa_smp;\nlayout(binding = 3) uniform sampler2D fa_mr_tex_fa_smp;\nlayout(binding = 4) uniform sampler2D fa_occlusion_tex_fa_smp;\nlayout(binding = 5) uniform sampler2D fa_emissive_tex_fa_smp;\nlayout(binding = 6) uniform sampler2D fa_decal_tex_fa_env_smp;\nlayout(binding = 7) uniform sampler2D fa_lightmap_fa_env_smp;\nlayout(binding = 8) uniform sampler2D fa_probe_atlas_fa_env_smp;\nlayout(binding = 9) uniform sampler2D fa_light_atlas_fa_env_smp;\nlayout(binding = 10) uniform sampler2D fa_shadow_tex_fa_shadow_smp;\nlayout(binding = 11) uniform sampler2D fa_screen_tex_fa_shadow_smp;\n\nlayout(location = 2) in vec3 fa_world_pos;\nlayout(location = 7) in vec3 fa_lm;\nlayout(location = 0) flat in vec4 fa_inst_v0;\nlayout(location = 1) flat in vec4 fa_inst_v1;\nlayout(location = 3) in vec3 fa_world_normal;\nlayout(location = 4) in vec4 fa_world_tangent;\nlayout(location = 5) in vec2 fa_uv;\nlayout(location = 6) in vec4 fa_vertex_color;\nlayout(location = 0) out vec4 fa_frag_color;\nvec3 fa_light_tint;\nbool fa_light_is_area;\nint fa_cl_ndir;\nint fa_cl_slot;\nint fa_cl_local;\nfloat raise;\nvec4 tint;\n\nvoid fa_instance_unpack(vec4 fa_d0, vec4 fa_d1, vec4 fa_d2)\n{\n    raise = fa_d0.x;\n    tint = fa_d1;\n}\n\nvoid fa_inst_load()\n{\n    vec4 param = fa_inst_v0;\n    vec4 param_1 = fa_inst_v1;\n    vec4 param_2 = vec4(0.0);\n    fa_instance_unpack(param, param_1, param_2);\n}\n\nvec4 fa_light_texel(int t)\n{\n    return texelFetch(fa_light_tex_fa_shadow_smp, ivec2(t & 1023, t >> 10), 0);\n}\n\nvec4 fa_cluster_texel(vec3 world_pos)\n{\n    bool _1597 = fa_mesh_fs_params[19].x < 0.0;\n    bool _1604;\n    if (!_1597)\n    {\n        _1604 = fa_mesh_fs_params[19].w < 1.0;\n    }\n    else\n    {\n        _1604 = _1597;\n    }\n    bool _1612;\n    if (!_1604)\n    {\n        _1612 = fa_mesh_fs_params[18].x < 1.0;\n    }\n    else\n    {\n        _1612 = _1604;\n    }\n    bool _1619;\n    if (!_1612)\n    {\n        _1619 = fa_mesh_fs_params[18].y < 1.0;\n    }\n    else\n    {\n        _1619 = _1612;\n    }\n    bool _1626;\n    if (!_1619)\n    {\n        _1626 = fa_mesh_fs_params[19].y < 1.0;\n    }\n    else\n    {\n        _1626 = _1619;\n    }\n    if (_1626)\n    {\n        return vec4(0.0);\n    }\n    vec4 _1636 = vec4(world_pos, 1.0);\n    float _1642 = dot(fa_mesh_fs_params[16], _1636);\n    if (!(_1642 > 9.9999999747524270787835121154785e-07))\n    {\n        return vec4(0.0);\n    }\n    vec2 _1664 = vec2(dot(fa_mesh_fs_params[14], _1636), dot(fa_mesh_fs_params[15], _1636)) / vec2(_1642);\n    int _1668 = int(fa_mesh_fs_params[18].x);\n    int _1672 = int(fa_mesh_fs_params[18].y);\n    int param = (int(fa_mesh_fs_params[19].x) + (((clamp(int(floor(log2(max(dot(fa_mesh_fs_params[17].xyz, world_pos) + fa_mesh_fs_params[17].w, fa_mesh_fs_params[18].w) / fa_mesh_fs_params[18].w) * fa_mesh_fs_params[18].z)), 0, int(fa_mesh_fs_params[19].y) - 1) * _1672) + clamp(int(floor(((_1664.y * 0.5) + 0.5) * fa_mesh_fs_params[18].y)), 0, _1672 - 1)) * _1668)) + clamp(int(floor(((_1664.x * 0.5) + 0.5) * fa_mesh_fs_params[18].x)), 0, _1668 - 1);\n    return fa_light_texel(param);\n}\n\nivec2 fa_cluster_lookup(vec3 world_pos)\n{\n    vec3 param = world_pos;\n    vec4 _1748 = fa_cluster_texel(param);\n    return ivec2(int(_1748.x), int(_1748.y));\n}\n\nvoid fa_cluster_begin(vec3 world_pos)\n{\n    fa_cl_ndir = int(fa_mesh_fs_params[19].z);\n    vec3 param = world_pos;\n    ivec2 _5834 = fa_cluster_lookup(param);\n    fa_cl_slot = _5834.x;\n    fa_cl_local = _5834.y;\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nvec3 fa_linear_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_tex_fix(inout vec3 c, float mode)\n{\n    if (mode > 1.5)\n    {\n        vec3 param = c;\n        vec3 _6997 = fa_linear_to_srgb(param);\n        c = _6997;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            vec3 param_1 = c;\n            vec3 _7005 = fa_srgb_to_linear(param_1);\n            c = _7005;\n        }\n    }\n    return c;\n}\n\nvec3 fa_tangent_normal(SurfaceInput i, vec3 m)\n{\n    vec3 _541;\n    if (i.front_facing)\n    {\n        _541 = i.world_normal;\n    }\n    else\n    {\n        _541 = -i.world_normal;\n    }\n    vec3 _565 = normalize(i.world_tangent.xyz - (_541 * dot(_541, i.world_tangent.xyz)));\n    vec3 _592 = normalize(((_565 * m.x) + ((cross(_541, _565) * i.world_tangent.w) * m.y)) + (_541 * m.z));\n    vec3 _595;\n    if (i.front_facing)\n    {\n        _595 = _592;\n    }\n    else\n    {\n        _595 = -_592;\n    }\n    return _595;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    vec4 base_t = texture(fa_tex_fa_smp, i.uv);\n    float param = fa_mesh_fs_params[6].w;\n    float param_1 = 1.0;\n    vec3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    vec3 _7036 = fa_tex_fix(param_2, param_3);\n    vec4 _9294 = base_t;\n    _9294.x = _7036.x;\n    _9294.y = _7036.y;\n    _9294.z = _7036.z;\n    base_t = _9294;\n    vec4 _7050 = (_9294 * fa_mesh_fs_params[2]) * i.vertex_color;\n    vec3 _9078 = i.world_normal;\n    if (fa_mesh_fs_params[6].z > 0.5)\n    {\n        float param_4 = fa_mesh_fs_params[6].w;\n        float param_5 = 16.0;\n        vec3 param_6 = texture(fa_normal_tex_fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        vec3 _7082 = fa_tex_fix(param_6, param_7);\n        vec3 _7085 = (_7082 * 2.0) - vec3(1.0);\n        vec2 _7090 = _7085.xy * fa_mesh_fs_params[6].x;\n        vec3 _9302 = _7085;\n        _9302.x = _7090.x;\n        _9302.y = _7090.y;\n        SurfaceInput param_8 = i;\n        vec3 param_9 = _9302;\n        _9078 = fa_tangent_normal(param_8, param_9);\n    }\n    vec4 mrt = texture(fa_mr_tex_fa_smp, i.uv);\n    float param_10 = fa_mesh_fs_params[6].w;\n    float param_11 = 64.0;\n    vec3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    vec3 _7118 = fa_tex_fix(param_12, param_13);\n    vec4 _9305 = mrt;\n    _9305.x = _7118.x;\n    _9305.y = _7118.y;\n    _9305.z = _7118.z;\n    mrt = _9305;\n    vec4 _7146 = texture(fa_occlusion_tex_fa_smp, i.uv);\n    float param_14 = fa_mesh_fs_params[6].w;\n    float param_15 = 256.0;\n    vec3 param_16 = _7146.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    vec3 _7157 = fa_tex_fix(param_16, param_17);\n    float param_18 = fa_mesh_fs_params[6].w;\n    float param_19 = 4.0;\n    vec3 param_20 = texture(fa_emissive_tex_fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    vec3 _7187 = fa_tex_fix(param_20, param_21);\n    float _9083 = fa_mesh_fs_params[20].x;\n    float _9084 = fa_mesh_fs_params[20].y;\n    float _9087 = fa_mesh_fs_params[20].z;\n    float _9086 = fa_mesh_fs_params[21].w;\n    float _9089 = fa_mesh_fs_params[22].x;\n    if (fa_mesh_fs_params[22].z > 0.5)\n    {\n        if (mod(fa_mesh_fs_params[22].z, 2.0) > 0.5)\n        {\n            _9083 *= _7157.y;\n            _9084 *= _7157.z;\n            _9086 *= _7146.w;\n        }\n        if (fa_mesh_fs_params[22].z > 1.5)\n        {\n            _9087 *= mrt.x;\n            _9089 *= mrt.w;\n        }\n    }\n    return Surface(_7050.xyz, _7050.w, _9078, clamp(fa_mesh_fs_params[5].x * _7118.z, 0.0, 1.0), clamp(fa_mesh_fs_params[5].y * _7118.y, 0.0500000007450580596923828125, 1.0), 1.0 + (fa_mesh_fs_params[6].y * (_7157.x - 1.0)), fa_mesh_fs_params[3].xyz + (fa_mesh_fs_params[4].xyz * _7187), _9083, _9084, fa_mesh_fs_params[21].xyz, _9086, _9087, fa_mesh_fs_params[20].w, _9089, fa_mesh_fs_params[22].y, fa_mesh_fs_params[23].xyz, fa_mesh_fs_params[30].x, fa_mesh_fs_params[30].y, fa_mesh_fs_params[31].xyz, fa_mesh_fs_params[30].z);\n}\n\nvoid surface(SurfaceInput i, inout Surface s)\n{\n    s.emission += ((tint.xyz * tint.w) * fa_material[0].x);\n}\n\nvec4 fa_decal_tile(vec4 rect, vec2 uv, vec2 atlas, vec2 ddx, vec2 ddy)\n{\n    vec2 _1828 = rect.zw - rect.xy;\n    vec2 _1832 = _1828 * atlas;\n    vec2 _1836 = ddx * _1832;\n    vec2 _1840 = ddy * _1832;\n    return textureLod(fa_decal_tex_fa_env_smp, rect.xy + (clamp(uv, vec2(0.0), vec2(1.0)) * _1828), clamp(0.5 * log2(max(max(dot(_1836, _1836), dot(_1840, _1840)), 9.9999999392252902907785028219223e-09)), 0.0, 3.0));\n}\n\nvec3 fa_dc_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_dc_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvoid fa_apply_decals(vec3 world_pos, vec3 geo_normal, inout vec3 albedo, inout vec3 normal)\n{\n    bool _1873 = fa_mesh_fs_params[10].y < 0.5;\n    bool _1880;\n    if (!_1873)\n    {\n        _1880 = fa_mesh_fs_params[10].w < 0.5;\n    }\n    else\n    {\n        _1880 = _1873;\n    }\n    if (_1880)\n    {\n        return;\n    }\n    vec3 _1886 = dFdx(world_pos);\n    vec3 _1889 = dFdy(world_pos);\n    vec3 param = world_pos;\n    vec4 _1893 = fa_cluster_texel(param);\n    int _1897 = int(_1893.w);\n    if (_1897 < 1)\n    {\n        return;\n    }\n    int _1907 = int(fa_mesh_fs_params[10].y + 0.5);\n    int param_1 = _1907;\n    vec4 _1911 = fa_light_texel(param_1);\n    vec2 _1914 = _1911.yz;\n    int _1918 = int(_1911.w);\n    int param_2 = _1907 + 1;\n    vec4 _1923 = fa_light_texel(param_2);\n    float _1924 = _1923.x;\n    int _1930 = int(fa_mesh_fs_params[10].w + 0.5) - 1;\n    int _1934 = int(_1893.z);\n    vec3 _2199;\n    for (int k = 0; k < _1897; k++)\n    {\n        int _1947 = _1934 + k;\n        int param_3 = _1918 + (_1947 >> 2);\n        int _1964 = (_1907 + 2) + (int(fa_light_texel(param_3)[_1947 & 3]) * 7);\n        int param_4 = _1964 + 6;\n        vec4 _1969 = fa_light_texel(param_4);\n        if (((int(_1969.w + 0.5) >> _1930) & 1) == 0)\n        {\n            continue;\n        }\n        int param_5 = _1964;\n        vec4 _1984 = fa_light_texel(param_5);\n        int param_6 = _1964 + 1;\n        vec4 _1989 = fa_light_texel(param_6);\n        int param_7 = _1964 + 2;\n        vec4 _1994 = fa_light_texel(param_7);\n        vec3 _1997 = _1984.xyz;\n        float _2002 = dot(_1997, world_pos) + _1984.w;\n        vec3 _2004 = _1989.xyz;\n        float _2009 = dot(_2004, world_pos) + _1989.w;\n        vec3 _2011 = _1994.xyz;\n        float _2016 = dot(_2011, world_pos) + _1994.w;\n        bool _2021 = abs(_2002) > 0.5;\n        bool _2029;\n        if (!_2021)\n        {\n            _2029 = abs(_2009) > 0.5;\n        }\n        else\n        {\n            _2029 = _2021;\n        }\n        bool _2037;\n        if (!_2029)\n        {\n            _2037 = abs(_2016) > 0.5;\n        }\n        else\n        {\n            _2037 = _2029;\n        }\n        if (_2037)\n        {\n            continue;\n        }\n        float _2052 = clamp(dot(geo_normal, normalize(_2011)) * _1969.z, 0.0, 1.0);\n        if (_2052 <= 0.0)\n        {\n            continue;\n        }\n        float _2072 = (clamp((0.5 - abs(_2016)) * 10.0, 0.0, 1.0) * _2052) * _1969.x;\n        vec2 _2080 = vec2(_2002 + 0.5, 0.5 - _2009);\n        vec2 _2090 = vec2(dot(_1997, _1886), dot(_2004, _1886));\n        vec2 _2100 = vec2(dot(_1997, _1889), dot(_2004, _1889));\n        int param_8 = _1964 + 5;\n        vec4 _2105 = fa_light_texel(param_8);\n        int param_9 = _1964 + 3;\n        vec4 _2110 = fa_light_texel(param_9);\n        int param_10 = _1964 + 4;\n        vec4 _2115 = fa_light_texel(param_10);\n        float tex_a = 1.0;\n        vec3 col = _2105.xyz;\n        bool _2125 = _2110.z > _2110.x;\n        if (_2125)\n        {\n            vec4 param_11 = _2110;\n            vec2 param_12 = _2080;\n            vec2 param_13 = _1914;\n            vec2 param_14 = _2090;\n            vec2 param_15 = _2100;\n            vec4 tx = fa_decal_tile(param_11, param_12, param_13, param_14, param_15);\n            if ((_1924 > 0.5) && (_1924 < 1.5))\n            {\n                vec3 param_16 = tx.xyz;\n                vec3 _2151 = fa_dc_to_linear(param_16);\n                vec4 _9166 = tx;\n                _9166.x = _2151.x;\n                _9166.y = _2151.y;\n                _9166.z = _2151.z;\n                tx = _9166;\n            }\n            col *= tx.xyz;\n            tex_a = tx.w;\n        }\n        albedo = mix(albedo, col, vec3(clamp((_2072 * tex_a) * _2105.w, 0.0, 1.0)));\n        if (_2115.z > _2115.x)\n        {\n            vec4 param_17 = _2115;\n            vec2 param_18 = _2080;\n            vec2 param_19 = _1914;\n            vec2 param_20 = _2090;\n            vec2 param_21 = _2100;\n            vec4 _2195 = fa_decal_tile(param_17, param_18, param_19, param_20, param_21);\n            if (_1924 > 1.5)\n            {\n                vec3 param_22 = _2195.xyz;\n                vec3 _2205 = fa_dc_to_srgb(param_22);\n                _2199 = _2205;\n            }\n            else\n            {\n                _2199 = _2195.xyz;\n            }\n            vec3 _2214 = (_2199 * 2.0) - vec3(1.0);\n            vec2 _2219 = _2214.xy * _1969.y;\n            vec3 _2241 = (normalize(_1997) * _2219.x) + (normalize(_2004) * _2219.y);\n            vec3 _2244 = normalize(normal);\n            normal = normalize(mix(_2244, normalize((_2244 * max(_2214.z, 0.0500000007450580596923828125)) + (_2241 - (_2244 * dot(_2244, _2241)))), vec3(clamp(_2072 * (_2125 ? tex_a : 1.0), 0.0, 1.0))));\n        }\n    }\n}\n\nfloat fa_sheen_albedo(float ndv, float rough)\n{\n    float _4284 = min(sqrt(max(rough - 0.100000001490116119384765625, 0.0) * 1.111111164093017578125) * 6.0, 5.999000072479248046875);\n    float _4292 = min(sqrt(clamp(ndv, 0.0, 1.0)) * 8.0, 7.999000072479248046875);\n    int _4295 = int(_4284);\n    int _4298 = int(_4292);\n    float _4308 = _4292 - float(_4298);\n    int _4363 = (_4295 * 9) + _4298;\n    int _4383 = ((_4295 + 1) * 9) + _4298;\n    return mix(mix(_4359[_4363], _4359[_4363 + 1], _4308), mix(_4359[_4383], _4359[_4383 + 1], _4308), _4284 - float(_4295));\n}\n\nFaLayers fa_layers_setup(SurfaceInput i, Surface s, vec3 n, vec3 v, float metallic, float roughness, inout vec3 f0)\n{\n    bool _9001 = false;\n    float _9002 = 1.0;\n    float _9003 = 1.0;\n    float _9004 = 1.0;\n    float _9005 = 0.0;\n    float _9006 = 0.0;\n    float _9007 = 0.0;\n    float _9008 = 0.0;\n    float _9010 = 1.0;\n    bool _9011 = false;\n    vec3 _9012 = vec3(0.0);\n    float _9013 = 1.0;\n    float _9014 = 1.0;\n    float _9015 = 1.0;\n    float _9016 = 0.0;\n    float _9017 = 0.0;\n    vec3 _9018 = vec3(1.0, 0.0, 0.0);\n    vec3 _9019 = vec3(0.0, 0.0, 1.0);\n    float _9020 = 1.0;\n    float _9021 = 1.0;\n    float _4434 = clamp(s.specular, 0.0, 1.0);\n    float _4438 = clamp(s.ior, 1.0, 3.0);\n    bool _4443 = (_4434 != 1.0) || (_4438 != 1.5);\n    bool _4452;\n    if (!_4443)\n    {\n        _4452 = any(notEqual(s.specular_color, vec3(1.0)));\n    }\n    else\n    {\n        _4452 = _4443;\n    }\n    if (_4452)\n    {\n        float _4460 = (_4438 - 1.0) / (_4438 + 1.0);\n        f0 = mix(min(vec3(_4460 * _4460) * max(s.specular_color, vec3(0.0)), vec3(1.0)) * _4434, s.albedo, vec3(metallic));\n        _9002 = mix(_4434, 1.0, metallic);\n        _9001 = true;\n    }\n    float _4487 = clamp(s.clearcoat, 0.0, 1.0);\n    if (_4487 > 0.0)\n    {\n        float _4495 = clamp(s.clearcoat_roughness, 0.0500000007450580596923828125, 1.0);\n        _9005 = _4487;\n        _9006 = _4495;\n        float _4502 = _4495 * _4495;\n        _9007 = _4502;\n        _9008 = _4502 * _4502;\n        float _4514 = max(dot(i.world_normal, v), 9.9999997473787516355514526367188e-05);\n        _9010 = _4514;\n        _9003 = 1.0 - (_4487 * (0.039999999105930328369140625 + (0.959999978542327880859375 * pow(clamp(1.0 - _4514, 0.0, 1.0), 5.0))));\n        _9001 = true;\n    }\n    vec3 _4533 = max(s.sheen_color, vec3(0.0));\n    float _4542 = max(_4533.x, max(_4533.y, _4533.z));\n    if (_4542 > 0.0)\n    {\n        float _4550 = clamp(s.sheen_roughness, 0.100000001490116119384765625, 1.0);\n        _9011 = true;\n        _9012 = _4533;\n        _9013 = _4550;\n        _9014 = _4550 * _4550;\n        float param = max(dot(n, v), 9.9999997473787516355514526367188e-05);\n        float param_1 = _4550;\n        float _4567 = fa_sheen_albedo(param, param_1);\n        _9016 = _4567;\n        _9015 = 1.0 - min(_4542 * _4567, 1.0);\n        _9001 = true;\n    }\n    _9004 = _9003 * _9015;\n    float _4586 = clamp(s.anisotropy, -1.0, 1.0);\n    if (_4586 != 0.0)\n    {\n        vec3 _4601 = i.world_tangent.xyz - (n * dot(n, i.world_tangent.xyz));\n        vec3 t = _4601;\n        if (dot(_4601, _4601) < 9.9999999392252902907785028219223e-09)\n        {\n            bvec3 _4613 = bvec3(abs(n.y) < 0.9900000095367431640625);\n            t = cross(vec3(_4613.x ? vec3(0.0, 1.0, 0.0).x : vec3(1.0, 0.0, 0.0).x, _4613.y ? vec3(0.0, 1.0, 0.0).y : vec3(1.0, 0.0, 0.0).y, _4613.z ? vec3(0.0, 1.0, 0.0).z : vec3(1.0, 0.0, 0.0).z), n);\n        }\n        vec3 _4617 = t;\n        vec3 _4618 = normalize(_4617);\n        t = _4618;\n        vec3 _4643 = normalize((_4618 * cos(s.anisotropy_rotation)) + ((cross(n, _4618) * ((i.world_tangent.w < 0.0) ? (-1.0) : 1.0)) * sin(s.anisotropy_rotation)));\n        _9018 = _4643;\n        _9019 = cross(n, _4643);\n        float _4653 = roughness * roughness;\n        float _4659 = mix(_4653, 1.0, _4586 * _4586);\n        bool _4661 = _4586 > 0.0;\n        _9020 = _4661 ? _4659 : _4653;\n        _9021 = _4661 ? _4653 : _4659;\n        _9017 = _4586;\n        _9001 = true;\n    }\n    return FaLayers(_9001, _9002, _9003, _9004, _9005, _9006, _9007, _9008, i.world_normal, _9010, _9011, _9012, _9013, _9014, _9015, _9016, _9017, _9018, _9019, _9020, _9021);\n}\n\nvec2 fa_atlas_size()\n{\n    return vec2(textureSize(fa_probe_atlas_fa_env_smp, 0));\n}\n\nvec3 fa_probe_sh_coef(vec2 origin, float res, int k)\n{\n    vec3 v = textureLod(fa_probe_atlas_fa_env_smp, (origin + vec2(float(k) + 0.5, res + 2.5)) / fa_atlas_size(), 0.0).xyz;\n    if (fa_mesh_fs_params[41].y > 0.5)\n    {\n        v = ((v * 255.0) - vec3(128.0)) * 0.03149606287479400634765625;\n    }\n    return v;\n}\n\nvec3 fa_sh_eval(vec3 c[9], vec3 n)\n{\n    vec3 _3452 = max((((c[0] * 0.2820948064327239990234375) + (((c[1] * (0.3257350027561187744140625 * n.y)) + (c[2] * (0.3257350027561187744140625 * n.z))) + (c[3] * (0.3257350027561187744140625 * n.x)))) + (((c[4] * ((0.2731371223926544189453125 * n.x) * n.y)) + (c[5] * ((0.2731371223926544189453125 * n.y) * n.z))) + (c[6] * (0.078847892582416534423828125 * (((3.0 * n.z) * n.z) - 1.0))))) + ((c[7] * ((0.2731371223926544189453125 * n.x) * n.z)) + (c[8] * (0.13656856119632720947265625 * ((n.x * n.x) - (n.y * n.y))))), vec3(0.0));\n    return _3452;\n}\n\nvec3 fa_ambient_light(vec3 n)\n{\n    float _4065 = (1.0 - fa_mesh_fs_params[42].w) - fa_mesh_fs_params[47].w;\n    vec3 amb = vec3(0.0);\n    bool _4070 = fa_mesh_fs_params[11].w > 0.5;\n    vec3 c[9];\n    for (int k = 0; k < 9; k++)\n    {\n        c[k] = vec3(0.0);\n    }\n    if (_4065 > 0.0005000000237487256526947021484375)\n    {\n        if (_4070)\n        {\n            for (int k_1 = 0; k_1 < 9; k_1++)\n            {\n                vec2 param = fa_mesh_fs_params[41].zw;\n                float param_1 = 128.0;\n                int param_2 = k_1;\n                c[k_1] = fa_probe_sh_coef(param, param_1, param_2) * _4065;\n            }\n        }\n        else\n        {\n            amb = fa_mesh_fs_params[1].xyz * _4065;\n        }\n    }\n    bool _4121 = fa_mesh_fs_params[42].w > 0.0;\n    if (_4121)\n    {\n        for (int k_2 = 0; k_2 < 9; k_2++)\n        {\n            vec2 param_3 = fa_mesh_fs_params[42].xy;\n            float param_4 = fa_mesh_fs_params[42].z;\n            int param_5 = k_2;\n            c[k_2] += (fa_probe_sh_coef(param_3, param_4, param_5) * fa_mesh_fs_params[42].w);\n        }\n    }\n    bool _4152 = fa_mesh_fs_params[47].w > 0.0;\n    if (_4152)\n    {\n        for (int k_3 = 0; k_3 < 9; k_3++)\n        {\n            vec2 param_6 = fa_mesh_fs_params[47].xy;\n            float param_7 = fa_mesh_fs_params[47].z;\n            int param_8 = k_3;\n            c[k_3] += (fa_probe_sh_coef(param_6, param_7, param_8) * fa_mesh_fs_params[47].w);\n        }\n    }\n    if ((_4070 || _4121) || _4152)\n    {\n        vec3 param_9[9] = c;\n        vec3 param_10 = n;\n        amb += fa_sh_eval(param_9, param_10);\n    }\n    return amb;\n}\n\nvec4 fa_gi_fetch(vec2 texel)\n{\n    return textureLod(fa_probe_atlas_fa_env_smp, texel / fa_atlas_size(), 0.0);\n}\n\nvec2 fa_oct_encode(vec3 d)\n{\n    vec3 _3472 = d / vec3(max((abs(d.x) + abs(d.y)) + abs(d.z), 9.9999999600419720025001879548654e-13));\n    float _3475 = _3472.x;\n    float _3477 = _3472.z;\n    vec2 e = vec2(_3475, _3477);\n    if (_3472.y < 0.0)\n    {\n        e = vec2((1.0 - abs(_3477)) * ((_3475 < 0.0) ? (-1.0) : 1.0), (1.0 - abs(_3475)) * ((_3477 < 0.0) ? (-1.0) : 1.0));\n    }\n    return e;\n}\n\nvec3 fa_gi_grid(int rec, vec3 n, vec3 v, out float cover)\n{\n    cover = 0.0;\n    int param = rec;\n    vec4 _7297 = fa_light_texel(param);\n    int param_1 = rec + 1;\n    vec4 _7302 = fa_light_texel(param_1);\n    int param_2 = rec + 2;\n    vec4 _7307 = fa_light_texel(param_2);\n    int param_3 = rec + 3;\n    vec4 _7312 = fa_light_texel(param_3);\n    bool _7315 = _7312.z < 0.5;\n    bool _7323;\n    if (!_7315)\n    {\n        _7323 = fa_atlas_size().y < 1155.0;\n    }\n    else\n    {\n        _7323 = _7315;\n    }\n    if (_7323)\n    {\n        return vec3(0.0);\n    }\n    float _7330 = max(_7297.w, 9.9999997473787516355514526367188e-05);\n    vec3 _7333 = _7302.xyz;\n    vec3 _7337 = _7297.xyz;\n    vec3 _7341 = (fa_world_pos - _7337) / vec3(_7330);\n    vec3 _7350 = min(_7341 + vec3(0.5), (_7333 - vec3(0.5)) - _7341);\n    float _7359 = min(_7350.x, min(_7350.y, _7350.z));\n    if (!(_7359 > 0.0))\n    {\n        return vec3(0.0);\n    }\n    vec3 _7374 = _7333 - vec3(1.0);\n    vec3 _7375 = clamp(_7341, vec3(0.0), _7374);\n    vec3 _7383 = min(floor(_7375), max(_7333 - vec3(2.0), vec3(0.0)));\n    vec3 _7387 = _7375 - _7383;\n    vec3 _7398 = fa_world_pos + (((n * 0.800000011920928955078125) + (v * 0.20000000298023223876953125)) * (0.20000000298023223876953125 * _7330));\n    int _7403 = int(_7307.y + 0.5);\n    float _7408 = 0.3257350027561187744140625 * n.y;\n    float _7412 = 0.3257350027561187744140625 * n.z;\n    float _7416 = 0.3257350027561187744140625 * n.x;\n    float _7423 = (0.2731371223926544189453125 * n.x) * n.y;\n    float _7430 = (0.2731371223926544189453125 * n.y) * n.z;\n    float _7439 = 0.078847892582416534423828125 * (((3.0 * n.z) * n.z) - 1.0);\n    float _7446 = (0.2731371223926544189453125 * n.x) * n.z;\n    float _7459 = 0.13656856119632720947265625 * ((n.x * n.x) - (n.y * n.y));\n    vec3 acc = vec3(0.0);\n    float wsum = 0.0;\n    int _7466 = 8 + int(_7312.w);\n    float _7493;\n    float _7506;\n    float _7520;\n    for (int k = 0; k < _7466; k++)\n    {\n        float _7479 = float(k & 1);\n        float _7483 = float((k >> 1) & 1);\n        float _7487 = float((k >> 2) & 1);\n        if (_7479 > 0.5)\n        {\n            _7493 = _7387.x;\n        }\n        else\n        {\n            _7493 = 1.0 - _7387.x;\n        }\n        if (_7483 > 0.5)\n        {\n            _7506 = _7387.y;\n        }\n        else\n        {\n            _7506 = 1.0 - _7387.y;\n        }\n        if (_7487 > 0.5)\n        {\n            _7520 = _7387.z;\n        }\n        else\n        {\n            _7520 = 1.0 - _7387.z;\n        }\n        float _7530 = (_7493 * _7506) * _7520;\n        if (!(_7530 > 0.0))\n        {\n            continue;\n        }\n        vec3 _7543 = min(_7383 + vec3(_7479, _7483, _7487), _7374);\n        int _7563 = int(((_7307.x + _7543.x) + (_7302.x * (_7543.y + (_7302.y * _7543.z)))) + 0.5);\n        vec2 _7578 = vec2(float(_7563 % _7403) * 10.0, 1024.0 + (float(_7563 / _7403) * 11.0));\n        vec2 param_4 = _7578 + vec2(9.5, 10.5);\n        vec4 _7586 = fa_gi_fetch(param_4);\n        bool _7589 = _7586.y < 0.5;\n        bool _7598;\n        if (!_7589)\n        {\n            _7598 = _7586.x > _7312.y;\n        }\n        else\n        {\n            _7598 = _7589;\n        }\n        if (_7598)\n        {\n            continue;\n        }\n        vec3 _7610 = _7398 - (_7337 + (_7543 * _7330));\n        float _7613 = length(_7610);\n        vec3 _7619 = _7610 / vec3(max(_7613, 9.9999997473787516355514526367188e-05));\n        float _7629 = max(9.9999997473787516355514526367188e-05, (dot(-_7619, n) + 1.0) * 0.5);\n        float w = _7530 * (_7629 * _7629);\n        vec3 param_5 = _7619;\n        vec2 param_6 = (_7578 + vec2(1.0)) + (((fa_oct_encode(param_5) * 0.5) + vec2(0.5)) * 8.0);\n        vec4 _7648 = fa_gi_fetch(param_6);\n        float _7655 = _7613 / max(_7307.z, 9.9999997473787516355514526367188e-05);\n        float _7658 = _7648.x;\n        if (_7655 > _7658)\n        {\n            float _7671 = max(_7648.y - (_7658 * _7658), 0.0);\n            float _7676 = _7655 - _7658;\n            float _7685 = _7671 / max(_7671 + (_7676 * _7676), 9.9999999600419720025001879548654e-13);\n            w *= ((_7685 * _7685) * _7685);\n        }\n        if (!(w > 0.0))\n        {\n            continue;\n        }\n        vec2 param_7 = _7578 + vec2(0.5, 10.5);\n        vec2 param_8 = _7578 + vec2(1.5, 10.5);\n        vec2 param_9 = _7578 + vec2(2.5, 10.5);\n        vec2 param_10 = _7578 + vec2(3.5, 10.5);\n        vec2 param_11 = _7578 + vec2(4.5, 10.5);\n        vec2 param_12 = _7578 + vec2(5.5, 10.5);\n        vec2 param_13 = _7578 + vec2(6.5, 10.5);\n        vec2 param_14 = _7578 + vec2(7.5, 10.5);\n        vec2 param_15 = _7578 + vec2(8.5, 10.5);\n        acc += ((((((((((fa_gi_fetch(param_7).xyz * 0.2820948064327239990234375) + (fa_gi_fetch(param_8).xyz * _7408)) + (fa_gi_fetch(param_9).xyz * _7412)) + (fa_gi_fetch(param_10).xyz * _7416)) + (fa_gi_fetch(param_11).xyz * _7423)) + (fa_gi_fetch(param_12).xyz * _7430)) + (fa_gi_fetch(param_13).xyz * _7439)) + (fa_gi_fetch(param_14).xyz * _7446)) + (fa_gi_fetch(param_15).xyz * _7459)) * w);\n        wsum += w;\n    }\n    if (!(wsum > 9.9999997473787516355514526367188e-06))\n    {\n        return vec3(0.0);\n    }\n    cover = smoothstep(0.0, 1.0, clamp(_7359 * 2.0, 0.0, 1.0)) * smoothstep(0.0, 0.0199999995529651641845703125, wsum);\n    float _7810;\n    if (fa_mesh_fs_params[52].z > 0.5)\n    {\n        _7810 = _7312.x;\n    }\n    else\n    {\n        _7810 = 1.0;\n    }\n    return max(acc / vec3(wsum), vec3(0.0)) * (_7307.w * _7810);\n}\n\nvec3 fa_gi_light(vec3 n, inout float left)\n{\n    left = 1.0;\n    vec3 acc = vec3(0.0);\n    vec3 _7834 = normalize(fa_mesh_fs_params[0].xyz - fa_world_pos);\n    int _7839 = int(fa_mesh_fs_params[52].x + 0.5);\n    int _7844 = int(fa_mesh_fs_params[52].y + 0.5);\n    float param_3;\n    for (int k = 0; (k < _7844) && (k < 8); k++)\n    {\n        int param = _7839 + (4 * k);\n        vec3 param_1 = n;\n        vec3 param_2 = _7834;\n        vec3 _7869 = fa_gi_grid(param, param_1, param_2, param_3);\n        float _7874 = param_3 * left;\n        acc += (_7869 * _7874);\n        left -= _7874;\n        if (left < 0.001000000047497451305389404296875)\n        {\n            left = 0.0;\n            break;\n        }\n    }\n    return acc;\n}\n\nvec3 fa_realtime_or_ambient(vec3 n)\n{\n    vec3 gi = vec3(0.0);\n    float left = 1.0;\n    if (fa_mesh_fs_params[52].y > 0.5)\n    {\n        vec3 param = n;\n        float param_1;\n        vec3 _7903 = fa_gi_light(param, param_1);\n        left = param_1;\n        gi = _7903;\n    }\n    if (left <= 0.0)\n    {\n        return gi;\n    }\n    vec3 param_2 = n;\n    return gi + (fa_ambient_light(param_2) * left);\n}\n\nvec3 fa_indirect_diffuse(vec3 n)\n{\n    if (fa_lm.z > 0.5)\n    {\n        return textureLod(fa_lightmap_fa_env_smp, fa_lm.xy, 0.0).xyz;\n    }\n    if (fa_mesh_fs_params[32].w > 0.0)\n    {\n        vec3 c[9];\n        for (int k = 0; k < 9; k++)\n        {\n            c[k] = fa_mesh_fs_params[k * 1 + 32].xyz;\n        }\n        vec3 param = n;\n        vec3 param_1[9] = c;\n        vec3 param_2 = n;\n        return mix(fa_ambient_light(param), fa_sh_eval(param_1, param_2), vec3(clamp(fa_mesh_fs_params[32].w, 0.0, 1.0)));\n    }\n    vec3 param_3 = n;\n    return fa_realtime_or_ambient(param_3);\n}\n\nint fa_cluster_index(int slot, int n)\n{\n    int param = (int(fa_mesh_fs_params[19].x) + int(fa_mesh_fs_params[19].w)) + ((slot + n) >> 2);\n    vec4 t = fa_light_texel(param);\n    return int(t[(slot + n) & 3]);\n}\n\nint fa_cl_light(int n)\n{\n    if (n < fa_cl_ndir)\n    {\n        return n;\n    }\n    int param = fa_cl_slot;\n    int param_1 = n - fa_cl_ndir;\n    return fa_cluster_index(param, param_1);\n}\n\nint fa_light_base(int li)\n{\n    return li * ((fa_mesh_fs_params[1].w > 4.5) ? 8 : 4);\n}\n\nbool fa_light_baked(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 3;\n    return fa_light_texel(param_1).w > 0.5;\n}\n\nfloat fa_baked_keep(int li)\n{\n    float _5804;\n    if (fa_lm.z > 0.5)\n    {\n        _5804 = 0.0;\n    }\n    else\n    {\n        _5804 = 1.0 - clamp(fa_mesh_fs_params[32].w, 0.0, 1.0);\n    }\n    bool _5815 = _5804 < 1.0;\n    bool _5821;\n    if (_5815)\n    {\n        int param = li;\n        _5821 = fa_light_baked(param);\n    }\n    else\n    {\n        _5821 = _5815;\n    }\n    return _5821 ? _5804 : 1.0;\n}\n\nfloat fa_light_type(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 1;\n    return fa_light_texel(param_1).w;\n}\n\nvec4 fa_atlas_fetch(vec2 texel)\n{\n    return textureLod(fa_light_atlas_fa_env_smp, texel / vec2(textureSize(fa_light_atlas_fa_env_smp, 0)), 0.0);\n}\n\nvec3 fa_cookie_sample(vec2 tile_origin, vec2 uv)\n{\n    vec2 param = (tile_origin + vec2(1.0)) + (clamp(uv, vec2(0.0), vec2(1.0)) * 254.0);\n    return fa_atlas_fetch(param).xyz;\n}\n\nvec3 fa_area_point(vec3 c, vec3 axis, vec3 ru, vec3 uu, float hx, float hy, float shape, vec3 p, vec3 r)\n{\n    bool _846 = dot(r, r) > 0.5;\n    if (shape > 1.5)\n    {\n        vec3 _859 = (c - (ru * hx)) - p;\n        vec3 _865 = ru * (2.0 * hx);\n        float _871 = max(dot(_865, _865), 9.9999999392252902907785028219223e-09);\n        float _875 = dot(_859, _865);\n        float t = clamp((-_875) / _871, 0.0, 1.0);\n        if (_846)\n        {\n            float _890 = dot(r, _865);\n            float _896 = _871 - (_890 * _890);\n            if (abs(_896) > (9.9999997473787516355514526367188e-06 * _871))\n            {\n                t = clamp(((dot(r, _859) * _890) - _875) / _896, 0.0, 1.0);\n            }\n        }\n        return (p + _859) + (_865 * t);\n    }\n    vec3 q = p;\n    float _928 = dot(r, axis);\n    bool _936;\n    if (_846)\n    {\n        _936 = abs(_928) > 9.9999997473787516355514526367188e-05;\n    }\n    else\n    {\n        _936 = _846;\n    }\n    if (_936)\n    {\n        float _946 = dot(c - p, axis) / _928;\n        if (_946 > 0.0)\n        {\n            q = p + (r * _946);\n        }\n    }\n    vec3 _959 = q - c;\n    vec2 xy = vec2(dot(_959, ru), dot(_959, uu));\n    if (shape > 0.5)\n    {\n        float _974 = length(xy);\n        if (_974 > hx)\n        {\n            xy *= (hx / _974);\n        }\n    }\n    else\n    {\n        xy = clamp(xy, vec2(-hx, -hy), vec2(hx, hy));\n    }\n    return (c + (ru * xy.x)) + (uu * xy.y);\n}\n\nint fa_cube_face(vec3 d)\n{\n    vec3 _607 = abs(d);\n    float _609 = _607.x;\n    float _611 = _607.y;\n    bool _612 = _609 >= _611;\n    bool _620;\n    if (_612)\n    {\n        _620 = _609 >= _607.z;\n    }\n    else\n    {\n        _620 = _612;\n    }\n    int _621;\n    if (_620)\n    {\n        _621 = (d.x > 0.0) ? 0 : 1;\n    }\n    else\n    {\n        int _636;\n        if (_611 >= _607.z)\n        {\n            _636 = (d.y > 0.0) ? 2 : 3;\n        }\n        else\n        {\n            _636 = (d.z > 0.0) ? 4 : 5;\n        }\n        _621 = _636;\n    }\n    return _621;\n}\n\nvoid fa_cube_face_basis(int f, out vec3 fwd, out vec3 up)\n{\n    if (f == 0)\n    {\n        fwd = vec3(1.0, 0.0, 0.0);\n        up = vec3(0.0, 1.0, 0.0);\n    }\n    else\n    {\n        if (f == 1)\n        {\n            fwd = vec3(-1.0, 0.0, 0.0);\n            up = vec3(0.0, 1.0, 0.0);\n        }\n        else\n        {\n            if (f == 2)\n            {\n                fwd = vec3(0.0, 1.0, 0.0);\n                up = vec3(0.0, 0.0, 1.0);\n            }\n            else\n            {\n                if (f == 3)\n                {\n                    fwd = vec3(0.0, -1.0, 0.0);\n                    up = vec3(0.0, 0.0, -1.0);\n                }\n                else\n                {\n                    if (f == 4)\n                    {\n                        fwd = vec3(0.0, 0.0, 1.0);\n                        up = vec3(0.0, 1.0, 0.0);\n                    }\n                    else\n                    {\n                        fwd = vec3(0.0, 0.0, -1.0);\n                        up = vec3(0.0, 1.0, 0.0);\n                    }\n                }\n            }\n        }\n    }\n}\n\nfloat fa_ies_sample(vec2 tile_origin, vec3 d, vec3 axis, vec3 right, vec3 up)\n{\n    float _766 = dot(d, right);\n    float _770 = dot(d, up);\n    float _781;\n    if (((_766 * _766) + (_770 * _770)) > 1.0000000133514319600180897396058e-10)\n    {\n        _781 = atan(_770, _766) * 0.15915493667125701904296875;\n    }\n    else\n    {\n        _781 = 0.0;\n    }\n    vec2 param = tile_origin + vec2(1.0 + ((_781 - floor(_781)) * 64.0), 1.0 + (acos(clamp(dot(d, axis), -1.0, 1.0)) * 10.18591594696044921875));\n    return fa_atlas_fetch(param).x;\n}\n\nLightSample fa_light_sample_n(int li, vec3 world_pos, vec3 n)\n{\n    int param = li;\n    int _1012 = fa_light_base(param);\n    bool _1016 = fa_mesh_fs_params[1].w > 4.5;\n    int param_1 = _1012;\n    vec4 _1020 = fa_light_texel(param_1);\n    int param_2 = _1012 + 1;\n    vec4 _1025 = fa_light_texel(param_2);\n    float _1028 = _1025.w;\n    float atten = 1.0;\n    float dist = 0.0;\n    fa_light_tint = vec3(1.0);\n    bool _1040 = _1016 && (_1028 > 2.5);\n    fa_light_is_area = _1040;\n    bool _1042 = _1028 < 0.5;\n    vec3 l;\n    if (_1042)\n    {\n        l = normalize(_1020.xyz);\n        if (_1016)\n        {\n            int param_3 = _1012 + 6;\n            vec4 _1056 = fa_light_texel(param_3);\n            if (_1056.z > 0.5)\n            {\n                int param_4 = _1012 + 4;\n                vec4 _1066 = fa_light_texel(param_4);\n                int param_5 = _1012 + 5;\n                vec4 _1071 = fa_light_texel(param_5);\n                vec2 param_6 = _1056.xy;\n                vec2 param_7 = fract(vec2(dot(world_pos, _1066.xyz) * _1066.w, (-dot(world_pos, _1071.xyz)) * _1071.w) + vec2(0.5));\n                fa_light_tint = fa_cookie_sample(param_6, param_7);\n            }\n        }\n    }\n    else\n    {\n        vec3 _1101 = _1020.xyz;\n        vec3 _1103 = _1101 - world_pos;\n        vec3 to_light = _1103;\n        float _1106 = length(_1103);\n        float reach = _1106;\n        bool front = true;\n        if (_1040)\n        {\n            int param_8 = _1012 + 7;\n            reach = max(_1106 - fa_light_texel(param_8).w, 0.0);\n            int param_9 = _1012 + 4;\n            vec4 _1130 = fa_light_texel(param_9);\n            int param_10 = _1012 + 5;\n            vec4 _1135 = fa_light_texel(param_10);\n            int param_11 = _1012 + 6;\n            vec4 _1140 = fa_light_texel(param_11);\n            float _1141 = _1140.w;\n            int param_12 = _1012 + 2;\n            vec3 _1148 = normalize(fa_light_texel(param_12).xyz);\n            bool _1150 = _1141 > 1.5;\n            bool _1158;\n            if (!_1150)\n            {\n                _1158 = dot(_1148, to_light) < 0.0;\n            }\n            else\n            {\n                _1158 = _1150;\n            }\n            front = _1158;\n            vec3 r = vec3(0.0);\n            vec3 _1167 = fa_mesh_fs_params[0].xyz - world_pos;\n            bool _1171 = dot(n, n) > 0.5;\n            bool _1179;\n            if (_1171)\n            {\n                _1179 = dot(_1167, _1167) > 9.9999999600419720025001879548654e-13;\n            }\n            else\n            {\n                _1179 = _1171;\n            }\n            if (_1179)\n            {\n                r = reflect(-normalize(_1167), normalize(n));\n            }\n            vec3 param_13 = _1101;\n            vec3 param_14 = _1148;\n            vec3 param_15 = _1130.xyz;\n            vec3 param_16 = _1135.xyz;\n            float param_17 = _1130.w;\n            float param_18 = _1135.w;\n            float param_19 = _1141;\n            vec3 param_20 = world_pos;\n            vec3 param_21 = r;\n            to_light = fa_area_point(param_13, param_14, param_15, param_16, param_17, param_18, param_19, param_20, param_21) - world_pos;\n        }\n        float _1215 = length(to_light);\n        dist = _1215;\n        l = to_light / vec3(max(_1215, 9.9999997473787516355514526367188e-05));\n        float _1229 = reach / max(_1020.w, 0.001000000047497451305389404296875);\n        float _1235 = clamp(1.0 - (_1229 * _1229), 0.0, 1.0);\n        float _1237;\n        if (front)\n        {\n            _1237 = _1235 * _1235;\n        }\n        else\n        {\n            _1237 = 0.0;\n        }\n        atten = _1237;\n        bool _1248 = _1028 < 2.5;\n        if ((_1028 > 1.5) && _1248)\n        {\n            int param_22 = _1012 + 2;\n            vec4 _1256 = fa_light_texel(param_22);\n            float _1266 = _1256.w;\n            int param_23 = _1012 + 3;\n            vec4 _1271 = fa_light_texel(param_23);\n            float _1272 = _1271.x;\n            float cos_inner = _1272;\n            if (_1272 > 1.5)\n            {\n                cos_inner = mix(_1266, 1.0, 0.25);\n            }\n            atten *= smoothstep(_1266, cos_inner, dot(-l, normalize(_1256.xyz)));\n        }\n        if (_1016 && (_1028 < 1.5))\n        {\n            int param_24 = _1012 + 6;\n            vec4 _1296 = fa_light_texel(param_24);\n            if (_1296.z > 0.5)\n            {\n                vec3 _1304 = -to_light;\n                int param_25 = _1012 + 4;\n                int param_26 = _1012 + 5;\n                vec3 _1318 = fa_light_texel(param_25).xyz;\n                vec3 _1322 = fa_light_texel(param_26).xyz;\n                vec3 _1331 = vec3(dot(_1304, _1318), dot(_1304, _1322), dot(_1304, cross(_1318, _1322)));\n                vec3 param_27 = _1331;\n                int _1335 = fa_cube_face(param_27);\n                int param_28 = _1335;\n                vec3 param_29;\n                vec3 param_30;\n                fa_cube_face_basis(param_28, param_29, param_30);\n                vec2 _1362 = vec2(dot(_1331, cross(param_29, param_30)), dot(_1331, param_30)) / vec2(max(dot(_1331, param_29), 9.9999997473787516355514526367188e-05));\n                int _1366 = _1335 / 3;\n                vec2 param_31 = _1296.xy + (vec2(float(_1335 - (_1366 * 3)), float(_1366)) * 256.0);\n                vec2 param_32 = vec2(0.5 + (0.5 * _1362.x), 0.5 - (0.5 * _1362.y));\n                fa_light_tint = fa_cookie_sample(param_31, param_32);\n            }\n            int param_33 = _1012 + 7;\n            vec4 _1396 = fa_light_texel(param_33);\n            if (_1396.z > 0.5)\n            {\n                int param_34 = _1012 + 2;\n                int param_35 = _1012 + 4;\n                int param_36 = _1012 + 5;\n                vec2 param_37 = _1396.xy;\n                vec3 param_38 = -l;\n                vec3 param_39 = normalize(fa_light_texel(param_34).xyz);\n                vec3 param_40 = fa_light_texel(param_35).xyz;\n                vec3 param_41 = fa_light_texel(param_36).xyz;\n                atten *= fa_ies_sample(param_37, param_38, param_39, param_40, param_41);\n            }\n        }\n        else\n        {\n            if (_1016 && _1248)\n            {\n                int param_42 = _1012 + 6;\n                vec4 _1443 = fa_light_texel(param_42);\n                int param_43 = _1012 + 7;\n                vec4 _1448 = fa_light_texel(param_43);\n                bool _1451 = _1443.z > 0.5;\n                bool _1458;\n                if (!_1451)\n                {\n                    _1458 = _1448.z > 0.5;\n                }\n                else\n                {\n                    _1458 = _1451;\n                }\n                if (_1458)\n                {\n                    int param_44 = _1012 + 2;\n                    vec4 _1465 = fa_light_texel(param_44);\n                    vec3 _1469 = normalize(_1465.xyz);\n                    int param_45 = _1012 + 4;\n                    vec4 _1474 = fa_light_texel(param_45);\n                    int param_46 = _1012 + 5;\n                    vec4 _1479 = fa_light_texel(param_46);\n                    if (_1451)\n                    {\n                        vec3 _1487 = -to_light;\n                        float _1494 = _1465.w;\n                        float _1510 = 0.5 / max(dot(_1487, _1469) * (sqrt(max(1.0 - (_1494 * _1494), 0.0)) / max(_1494, 0.001000000047497451305389404296875)), 9.9999997473787516355514526367188e-05);\n                        vec2 param_47 = _1443.xy;\n                        vec2 param_48 = vec2(0.5 + (dot(_1487, _1474.xyz) * _1510), 0.5 - (dot(_1487, _1479.xyz) * _1510));\n                        fa_light_tint = fa_cookie_sample(param_47, param_48);\n                    }\n                    if (_1448.z > 0.5)\n                    {\n                        vec2 param_49 = _1448.xy;\n                        vec3 param_50 = -l;\n                        vec3 param_51 = _1469;\n                        vec3 param_52 = _1474.xyz;\n                        vec3 param_53 = _1479.xyz;\n                        atten *= fa_ies_sample(param_49, param_50, param_51, param_52, param_53);\n                    }\n                }\n            }\n        }\n    }\n    vec3 _8989 = _1025.xyz * atten;\n    if (_1016)\n    {\n        _8989 *= fa_light_tint;\n    }\n    int _1579;\n    if (_1042)\n    {\n        _1579 = 0;\n    }\n    else\n    {\n        _1579 = ((_1028 > 1.5) && (_1028 < 2.5)) ? 2 : 1;\n    }\n    return LightSample(l, _8989, atten, 1.0, dist, _1579);\n}\n\nfloat fa_shadow_split_at(int i)\n{\n    float _2311;\n    if (i == 0)\n    {\n        _2311 = fa_shadows[24].x;\n    }\n    else\n    {\n        float _2327;\n        if (i == 1)\n        {\n            _2327 = fa_shadows[24].y;\n        }\n        else\n        {\n            float _2335;\n            if (i == 2)\n            {\n                _2335 = fa_shadows[24].z;\n            }\n            else\n            {\n                _2335 = fa_shadows[24].w;\n            }\n            _2327 = _2335;\n        }\n        _2311 = _2327;\n    }\n    return _2311;\n}\n\nfloat fa_shadow_depth(inout vec2 uv, vec4 rect)\n{\n    uv = clamp(uv, rect.xy, rect.zw);\n    return textureLod(fa_shadow_tex_fa_shadow_smp, uv, 0.0).x;\n}\n\nfloat fa_shadow_fetch(vec2 uv, vec4 rect, vec3 conv)\n{\n    vec2 param = uv;\n    vec4 param_1 = rect;\n    float _2368 = fa_shadow_depth(param, param_1);\n    float _2372;\n    if (conv.x < 0.5)\n    {\n        _2372 = _2368;\n    }\n    else\n    {\n        _2372 = (conv.y * conv.z) / (conv.z - (_2368 * (conv.z - conv.y)));\n    }\n    return _2372;\n}\n\nfloat fa_shadow_noise()\n{\n    return fract(52.98291778564453125 * fract(dot(gl_FragCoord.xy, vec2(0.067110560834407806396484375, 0.005837149918079376220703125))));\n}\n\nvec2 fa_shadow_vogel_turn(vec2 d)\n{\n    return vec2((d.x * (-0.737368881702423095703125)) - (d.y * 0.675490319728851318359375), (d.y * (-0.737368881702423095703125)) + (d.x * 0.675490319728851318359375));\n}\n\nfloat fa_shadow_filter(vec2 uv, vec4 rect, float zr, float texel_m, float unit, float reach, float plane, vec3 conv, int mode, float k)\n{\n    if (mode == 1)\n    {\n        vec2 param = uv;\n        vec4 param_1 = rect;\n        vec3 param_2 = conv;\n        return float(zr <= fa_shadow_fetch(param, param_1, param_2));\n    }\n    float _2418 = fa_shadow_noise() * 6.283185482025146484375;\n    vec2 _2424 = vec2(cos(_2418), sin(_2418));\n    vec2 dir = _2424;\n    float radius = 1.5;\n    if (mode == 2)\n    {\n        float _2433;\n        if (k < 0.0)\n        {\n            _2433 = (-k) / max(zr, 0.100000001490116119384765625);\n        }\n        else\n        {\n            _2433 = k;\n        }\n        float _2452 = clamp((_2433 * reach) / texel_m, 3.0, 12.0);\n        float sum = 0.0;\n        float cnt = 0.0;\n        for (int i = 0; i < 16; i++)\n        {\n            float _2471 = sqrt((float(i) + 0.5) * 0.0625) * _2452;\n            vec2 param_3 = uv + (dir * (fa_shadows[26].zw * _2471));\n            vec4 param_4 = rect;\n            vec3 param_5 = conv;\n            float _2485 = fa_shadow_fetch(param_3, param_4, param_5);\n            if (_2485 < (zr - (_2471 * plane)))\n            {\n                sum += _2485;\n                cnt += 1.0;\n            }\n            vec2 param_6 = dir;\n            dir = fa_shadow_vogel_turn(param_6);\n        }\n        if (cnt < 0.5)\n        {\n            return 1.0;\n        }\n        float _2513 = sum / cnt;\n        float _2523;\n        if (k < 0.0)\n        {\n            _2523 = (-k) / max(_2513, 0.0500000007450580596923828125);\n        }\n        else\n        {\n            _2523 = k;\n        }\n        radius = clamp(((max(zr - _2513, 0.0) * unit) * _2523) / texel_m, 1.5, 16.0);\n        dir = _2424;\n    }\n    float lit = 0.0;\n    int _2549 = (mode == 2) ? 24 : 16;\n    for (int i_1 = 0; i_1 < _2549; i_1++)\n    {\n        float _2568 = sqrt((float(i_1) + 0.5) / float(_2549)) * radius;\n        vec2 param_7 = uv + (dir * (fa_shadows[26].zw * _2568));\n        vec4 param_8 = rect;\n        vec3 param_9 = conv;\n        lit += float((zr - (_2568 * plane)) <= fa_shadow_fetch(param_7, param_8, param_9));\n        vec2 param_10 = dir;\n        dir = fa_shadow_vogel_turn(param_10);\n    }\n    return lit / float(_2549);\n}\n\nfloat fa_shadow_cascade(int ci, vec3 world, vec3 n, vec3 l)\n{\n    float _2614 = max(fa_shadows[ci * 1 + 20].y, 0.001000000047497451305389404296875);\n    float _2619 = clamp(dot(n, l), 0.0, 1.0);\n    float _2625 = sqrt(1.0 - (_2619 * _2619));\n    float _2633 = min(_2625 / max(_2619, 0.20000000298023223876953125), 4.0);\n    float _2638;\n    if (fa_shadows[26].y > 0.0)\n    {\n        _2638 = fa_shadows[26].y;\n    }\n    else\n    {\n        _2638 = 1.5 * fa_shadows[ci * 1 + 20].x;\n    }\n    vec4 _2663 = mat4(fa_shadows[ci * 4 + 0], fa_shadows[ci * 4 + 1], fa_shadows[ci * 4 + 2], fa_shadows[ci * 4 + 3]) * vec4(world + (n * (_2638 * _2625)), 1.0);\n    float _2670 = _2663.x;\n    bool _2673 = _2670 < fa_shadows[ci * 1 + 16].x;\n    bool _2682;\n    if (!_2673)\n    {\n        _2682 = _2670 > fa_shadows[ci * 1 + 16].z;\n    }\n    else\n    {\n        _2682 = _2673;\n    }\n    bool _2691;\n    if (!_2682)\n    {\n        _2691 = _2663.y < fa_shadows[ci * 1 + 16].y;\n    }\n    else\n    {\n        _2691 = _2682;\n    }\n    bool _2700;\n    if (!_2691)\n    {\n        _2700 = _2663.y > fa_shadows[ci * 1 + 16].w;\n    }\n    else\n    {\n        _2700 = _2691;\n    }\n    bool _2707;\n    if (!_2700)\n    {\n        _2707 = _2663.z > 1.0;\n    }\n    else\n    {\n        _2707 = _2700;\n    }\n    if (_2707)\n    {\n        return -1.0;\n    }\n    float _2715;\n    if (fa_shadows[26].x > 0.0)\n    {\n        _2715 = fa_shadows[26].x;\n    }\n    else\n    {\n        _2715 = 1.5 * fa_shadows[ci * 1 + 20].x;\n    }\n    vec2 param = _2663.xy;\n    vec4 param_1 = fa_shadows[ci * 1 + 16];\n    float param_2 = _2663.z - ((_2715 * (1.0 + (0.5 * _2633))) / _2614);\n    float param_3 = fa_shadows[ci * 1 + 20].x;\n    float param_4 = _2614;\n    float param_5 = _2614 * 0.25;\n    float param_6 = ((fa_shadows[ci * 1 + 20].x * min(_2633, 3.0)) * 0.5) / _2614;\n    vec3 param_7 = vec3(0.0);\n    int param_8 = int(fa_shadows[25].z + 0.5);\n    float param_9 = fa_shadows[25].w;\n    return fa_shadow_filter(param, param_1, param_2, param_3, param_4, param_5, param_6, param_7, param_8, param_9);\n}\n\nfloat fa_shadow_sun(vec3 world, vec3 n, vec3 l)\n{\n    if (fa_mesh_fs_params[5].z < 0.5)\n    {\n        return 1.0;\n    }\n    int _3093 = int(fa_shadows[25].x + 0.5);\n    if (_3093 < 1)\n    {\n        return 1.0;\n    }\n    float _3108 = dot(world - fa_shadows[27].xyz, fa_shadows[28].xyz);\n    int param = _3093 - 1;\n    if (_3108 > fa_shadow_split_at(param))\n    {\n        return 1.0;\n    }\n    int ci = 0;\n    bool _3120 = _3093 > 1;\n    bool _3127;\n    if (_3120)\n    {\n        _3127 = _3108 > fa_shadows[24].x;\n    }\n    else\n    {\n        _3127 = _3120;\n    }\n    if (_3127)\n    {\n        ci = 1;\n    }\n    bool _3131 = _3093 > 2;\n    bool _3138;\n    if (_3131)\n    {\n        _3138 = _3108 > fa_shadows[24].y;\n    }\n    else\n    {\n        _3138 = _3131;\n    }\n    if (_3138)\n    {\n        ci = 2;\n    }\n    bool _3142 = _3093 > 3;\n    bool _3149;\n    if (_3142)\n    {\n        _3149 = _3108 > fa_shadows[24].z;\n    }\n    else\n    {\n        _3149 = _3142;\n    }\n    if (_3149)\n    {\n        ci = 3;\n    }\n    float s = -1.0;\n    for (int k = 0; k < 4; k++)\n    {\n        if (ci >= _3093)\n        {\n            break;\n        }\n        int param_1 = ci;\n        vec3 param_2 = world;\n        vec3 param_3 = n;\n        vec3 param_4 = l;\n        float _3175 = fa_shadow_cascade(param_1, param_2, param_3, param_4);\n        s = _3175;\n        if (_3175 >= 0.0)\n        {\n            break;\n        }\n        ci++;\n    }\n    if (s < 0.0)\n    {\n        return 1.0;\n    }\n    if (fa_shadows[25].y > 0.0)\n    {\n        float _3200;\n        if (ci > 0)\n        {\n            int param_5 = ci - 1;\n            _3200 = fa_shadow_split_at(param_5);\n        }\n        else\n        {\n            _3200 = fa_shadows[28].w;\n        }\n        int param_6 = ci;\n        float _3219 = fa_shadows[25].y * max(fa_shadow_split_at(param_6) - _3200, 9.9999997473787516355514526367188e-05);\n        int param_7 = ci;\n        float _3230 = clamp((_3108 - (fa_shadow_split_at(param_7) - _3219)) / _3219, 0.0, 1.0);\n        if (_3230 > 0.0)\n        {\n            float s2 = 1.0;\n            if ((ci + 1) < _3093)\n            {\n                int param_8 = ci + 1;\n                vec3 param_9 = world;\n                vec3 param_10 = n;\n                vec3 param_11 = l;\n                float _3251 = fa_shadow_cascade(param_8, param_9, param_10, param_11);\n                s2 = _3251;\n                if (_3251 < 0.0)\n                {\n                    s2 = s;\n                }\n            }\n            s = mix(s, s2, _3230);\n        }\n    }\n    return s;\n}\n\nfloat fa_shadow_factor(vec3 n, vec3 l)\n{\n    vec3 param = fa_world_pos;\n    vec3 param_1 = n;\n    vec3 param_2 = l;\n    return fa_shadow_sun(param, param_1, param_2);\n}\n\nfloat fa_shadow_local(int li, vec3 lpos, vec3 world, vec3 n, vec3 l)\n{\n    bool _2773 = fa_mesh_fs_params[5].z < 0.5;\n    bool _2780;\n    if (!_2773)\n    {\n        _2780 = fa_shadows[29].x < 0.5;\n    }\n    else\n    {\n        _2780 = _2773;\n    }\n    if (_2780)\n    {\n        return 1.0;\n    }\n    int param = (int(fa_shadows[29].x + 0.5) - 1) + li;\n    vec4 _2793 = fa_light_texel(param);\n    float _2794 = _2793.x;\n    if (_2794 < 0.0)\n    {\n        return 1.0;\n    }\n    int _2803 = int(_2794 + 0.5);\n    int param_1 = _2803;\n    vec4 _2807 = fa_light_texel(param_1);\n    int param_2 = _2803 + 1;\n    vec4 _2812 = fa_light_texel(param_2);\n    float fade = 1.0;\n    float _2815 = _2807.y;\n    if (_2815 > 0.0)\n    {\n        float _2832 = 1.0 - smoothstep(0.75 * _2815, _2815, length(world - fa_shadows[27].xyz));\n        fade = _2832;\n        if (_2832 <= 0.0)\n        {\n            return 1.0;\n        }\n    }\n    int face = 0;\n    if (_2807.x > 1.5)\n    {\n        vec3 param_3 = world - lpos;\n        face = fa_cube_face(param_3);\n    }\n    int _2856 = (_2803 + 2) + (face * 6);\n    int param_4 = _2856;\n    int param_5 = _2856 + 1;\n    int param_6 = _2856 + 3;\n    vec4 _2870 = fa_light_texel(param_6);\n    int param_7 = _2856 + 4;\n    vec4 _2875 = fa_light_texel(param_7);\n    int param_8 = _2856 + 5;\n    vec4 _2880 = fa_light_texel(param_8);\n    float _2892 = _2880.x * max(dot(_2870, vec4(world, 1.0)), 0.001000000047497451305389404296875);\n    float _2897 = clamp(dot(n, l), 0.0, 1.0);\n    float _2920 = clamp(dot(n, _2870.xyz), -1.0, 1.0);\n    float _2939 = min(sqrt(1.0 - (_2920 * _2920)) / max(abs(dot(n, world - lpos)) / max(dot(_2870, vec4(world, 1.0)), 0.001000000047497451305389404296875), 0.20000000298023223876953125), 4.0);\n    float _2942 = _2812.y;\n    float _2944;\n    if (_2942 > 0.0)\n    {\n        _2944 = _2942;\n    }\n    else\n    {\n        _2944 = 1.5 * _2892;\n    }\n    vec4 _2964 = vec4(world + (n * (_2944 * sqrt(1.0 - (_2897 * _2897)))), 1.0);\n    float _2968 = dot(_2870, _2964);\n    float _2971 = _2880.y;\n    if (_2968 < _2971)\n    {\n        return 1.0;\n    }\n    vec2 _2986 = vec2(dot(fa_light_texel(param_4), _2964), dot(fa_light_texel(param_5), _2964)) / vec2(_2968);\n    float _2988 = _2986.x;\n    bool _2991 = _2988 < _2875.x;\n    bool _3000;\n    if (!_2991)\n    {\n        _3000 = _2988 > _2875.z;\n    }\n    else\n    {\n        _3000 = _2991;\n    }\n    bool _3009;\n    if (!_3000)\n    {\n        _3009 = _2986.y < _2875.y;\n    }\n    else\n    {\n        _3009 = _3000;\n    }\n    bool _3018;\n    if (!_3009)\n    {\n        _3018 = _2986.y > _2875.w;\n    }\n    else\n    {\n        _3018 = _3009;\n    }\n    if (_3018)\n    {\n        return 1.0;\n    }\n    float _3024 = _2812.x;\n    float _3026;\n    if (_3024 > 0.0)\n    {\n        _3026 = _3024;\n    }\n    else\n    {\n        _3026 = 1.5 * _2892;\n    }\n    vec2 param_9 = _2986;\n    vec4 param_10 = _2875;\n    float param_11 = _2968 - (_3026 * (1.0 + (0.5 * _2939)));\n    float param_12 = _2892;\n    float param_13 = 1.0;\n    float param_14 = _2880.z * 0.25;\n    float param_15 = (_2892 * min(_2939, 3.0)) * 0.5;\n    vec3 param_16 = vec3(1.0, _2971, _2880.z);\n    int param_17 = int(_2807.z + 0.5);\n    float param_18 = _2807.w;\n    return mix(1.0, fa_shadow_filter(param_9, param_10, param_11, param_12, param_13, param_14, param_15, param_16, param_17, param_18), fade);\n}\n\nfloat fa_contact_shadow(int li, vec3 world, vec3 gn, vec3 l, float dist)\n{\n    bool _5177 = fa_mesh_fs_params[24].x < 0.5;\n    bool _5184;\n    if (!_5177)\n    {\n        _5184 = fa_shadows[29].x < 0.5;\n    }\n    else\n    {\n        _5184 = _5177;\n    }\n    if (_5184)\n    {\n        return 1.0;\n    }\n    int param = (int(fa_shadows[29].x + 0.5) - 1) + li;\n    vec4 _5197 = fa_light_texel(param);\n    float _5198 = _5197.y;\n    float len = _5198;\n    if (_5198 <= 0.0)\n    {\n        return 1.0;\n    }\n    float _5210 = length(world - fa_mesh_fs_params[0].xyz);\n    float _5220 = 1.0 - smoothstep(0.5 * fa_mesh_fs_params[25].x, fa_mesh_fs_params[25].x, _5210);\n    if (_5220 <= 0.0)\n    {\n        return 1.0;\n    }\n    float _5226 = len;\n    float _5229 = min(_5226, 0.89999997615814208984375 * dist);\n    len = _5229;\n    float _5234 = 0.004999999888241291046142578125 + (0.0030000000260770320892333984375 * _5210);\n    float _5239 = _5234 + (0.5 * _5229);\n    vec3 _5245 = world + (gn * _5234);\n    float _5247 = fa_shadow_noise();\n    float occ = 0.0;\n    float _5311;\n    for (int k = 0; k < 12; k++)\n    {\n        float _5262 = (float(k) + _5247) * 0.083333335816860198974609375;\n        vec3 _5270 = _5245 + (l * (_5262 * len));\n        vec4 _5276 = vec4(_5270, 1.0);\n        float _5282 = dot(fa_mesh_fs_params[28], _5276);\n        if (_5282 < 9.9999997473787516355514526367188e-05)\n        {\n            break;\n        }\n        vec2 _5302 = vec2(dot(fa_mesh_fs_params[26], _5276), dot(fa_mesh_fs_params[27], _5276)) / vec2(_5282);\n        float _5306 = _5302.x * 0.5;\n        float _5307 = _5306 + 0.5;\n        if (fa_mesh_fs_params[24].y > 0.5)\n        {\n            _5311 = (_5302.y * 0.5) + 0.5;\n        }\n        else\n        {\n            _5311 = 0.5 - (_5302.y * 0.5);\n        }\n        bool _5327 = _5307 < 0.0;\n        bool _5334;\n        if (!_5327)\n        {\n            _5334 = _5307 >= 1.0;\n        }\n        else\n        {\n            _5334 = _5327;\n        }\n        bool _5341;\n        if (!_5334)\n        {\n            _5341 = _5311 < 0.0;\n        }\n        else\n        {\n            _5341 = _5334;\n        }\n        bool _5348;\n        if (!_5341)\n        {\n            _5348 = _5311 >= 1.0;\n        }\n        else\n        {\n            _5348 = _5341;\n        }\n        if (_5348)\n        {\n            break;\n        }\n        vec4 _5375 = texelFetch(fa_screen_tex_fa_shadow_smp, clamp(ivec2(vec2(_5307, _5311) * fa_mesh_fs_params[24].zw), ivec2(0), ivec2(fa_mesh_fs_params[24].zw) - ivec2(1)), 0);\n        if (_5375.w < 0.5)\n        {\n            continue;\n        }\n        float _5394 = (dot(fa_mesh_fs_params[29].xyz, _5270) + fa_mesh_fs_params[29].w) - _5375.x;\n        if ((_5394 > _5234) && (_5394 < _5239))\n        {\n            occ = max(occ, (1.0 - (_5262 * _5262)) * smoothstep(0.0, 0.0500000007450580596923828125, min(min(_5307, 0.5 - _5306), min(_5311, 1.0 - _5311))));\n        }\n    }\n    return 1.0 - (occ * _5220);\n}\n\nLightSample fa_light_shadowed(int li, vec3 world_pos, vec3 gn)\n{\n    int param = li;\n    float _5860 = fa_baked_keep(param);\n    if (_5860 <= 0.0)\n    {\n        int param_1 = li;\n        return LightSample(vec3(0.0, 1.0, 0.0), vec3(0.0), 0.0, 1.0, 0.0, int(fa_light_type(param_1) + 0.5));\n    }\n    int param_2 = li;\n    vec3 param_3 = world_pos;\n    vec3 param_4 = gn;\n    LightSample _5886 = fa_light_sample_n(param_2, param_3, param_4);\n    vec3 _9058 = _5886.color;\n    float _9059 = _5886.attenuation;\n    float _9060 = _5886.shadow;\n    bool _5889 = _5886.type == 0;\n    if (_5889 && (li == 0))\n    {\n        vec3 param_5 = gn;\n        vec3 param_6 = _5886.direction;\n        float _5900 = fa_shadow_factor(param_5, param_6);\n        _9060 = _5900;\n        _9058 *= _5900;\n    }\n    else\n    {\n        bool _5911 = _5886.type != 0;\n        bool _5917;\n        if (_5911)\n        {\n            _5917 = _9059 > 0.0;\n        }\n        else\n        {\n            _5917 = _5911;\n        }\n        if (_5917)\n        {\n            int param_7 = li;\n            int param_8 = fa_light_base(param_7);\n            int param_9 = li;\n            vec3 param_10 = fa_light_texel(param_8).xyz;\n            vec3 param_11 = world_pos;\n            vec3 param_12 = gn;\n            vec3 param_13 = _5886.direction;\n            float _5936 = fa_shadow_local(param_9, param_10, param_11, param_12, param_13);\n            _9060 = _5936;\n            _9058 *= _5936;\n        }\n    }\n    bool _5946 = fa_mesh_fs_params[24].x > 0.5;\n    bool _5952;\n    if (_5946)\n    {\n        _5952 = _9059 > 0.0;\n    }\n    else\n    {\n        _5952 = _5946;\n    }\n    if (_5952)\n    {\n        float _5959;\n        if (_5889)\n        {\n            _5959 = 1000000000.0;\n        }\n        else\n        {\n            _5959 = _5886._distance;\n        }\n        int param_14 = li;\n        vec3 param_15 = world_pos;\n        vec3 param_16 = gn;\n        vec3 param_17 = _5886.direction;\n        float param_18 = _5959;\n        float _5977 = fa_contact_shadow(param_14, param_15, param_16, param_17, param_18);\n        _9060 *= _5977;\n        _9058 *= _5977;\n    }\n    float _5990 = _9059;\n    float _5991 = _5990 * _5860;\n    _9059 = _5991;\n    vec3 _5995 = _9058;\n    vec3 _5996 = _5995 * _5860;\n    _9058 = _5996;\n    return LightSample(_5886.direction, _5996, _5991, _9060, _5886._distance, _5886.type);\n}\n\nvec3 fa_ltc_tangent(vec3 n, vec3 v)\n{\n    vec3 _6030 = v - (n * dot(v, n));\n    vec3 t = _6030;\n    float _6034 = dot(_6030, _6030);\n    float l2 = _6034;\n    if (_6034 < 1.0000000133514319600180897396058e-10)\n    {\n        vec3 _6044;\n        if (abs(n.z) < 0.999000012874603271484375)\n        {\n            _6044 = cross(n, vec3(0.0, 0.0, 1.0));\n        }\n        else\n        {\n            _6044 = cross(n, vec3(1.0, 0.0, 0.0));\n        }\n        t = _6044;\n        l2 = dot(_6044, _6044);\n    }\n    return t * inversesqrt(l2);\n}\n\nvec3 fa_ltc_local(vec3 t1, vec3 n, vec3 p)\n{\n    return vec3(dot(t1, p), dot(cross(n, t1), p), dot(n, p));\n}\n\nvec3 fa_ltc_edge_vector(vec3 a, vec3 b)\n{\n    float _6079 = dot(a, a);\n    float _6083 = dot(b, b);\n    if ((_6079 < 1.0000000195414813782625560981111e-24) || (_6083 < 1.0000000195414813782625560981111e-24))\n    {\n        return vec3(0.0);\n    }\n    vec3 _6097 = a * inversesqrt(_6079);\n    vec3 _6102 = b * inversesqrt(_6083);\n    float _6106 = dot(_6097, _6102);\n    float _6109 = abs(_6106);\n    float g = (((((((((((0.0416471660137176513671875 * _6109) - 0.1924748718738555908203125) * _6109) + 0.4179156124591827392578125) * _6109) - 0.616057217121124267578125) * _6109) + 0.777722418308258056640625) * _6109) - 0.999542415142059326171875) * _6109) + 1.570791721343994140625;\n    if (_6106 < 0.0)\n    {\n        g = (3.1415927410125732421875 * inversesqrt(max(1.0 - (_6106 * _6106), 1.0000000116860974230803549289703e-07))) - g;\n    }\n    return cross(_6097, _6102) * g;\n}\n\nvoid fa_ltc_clip_edge(vec3 a, vec3 b, inout vec3 sum, inout vec3 leave, inout vec3 enter, inout vec2 seen)\n{\n    bool _6166 = a.z > 0.0;\n    bool _6170 = b.z > 0.0;\n    if (_6166 && _6170)\n    {\n        vec3 param = a;\n        vec3 param_1 = b;\n        sum += fa_ltc_edge_vector(param, param_1);\n    }\n    else\n    {\n        if (_6166 != _6170)\n        {\n            vec3 _6205 = a + ((b - a) * (a.z / (a.z - b.z)));\n            _6205.z = 0.0;\n            if (_6166)\n            {\n                vec3 param_2 = a;\n                vec3 param_3 = _6205;\n                sum += fa_ltc_edge_vector(param_2, param_3);\n                leave = _6205;\n                seen.x = 1.0;\n            }\n            else\n            {\n                vec3 param_4 = _6205;\n                vec3 param_5 = b;\n                sum += fa_ltc_edge_vector(param_4, param_5);\n                enter = _6205;\n                seen.y = 1.0;\n            }\n        }\n    }\n}\n\nfloat fa_ltc_quad(vec4 abcd, vec3 p0, vec3 p1, vec3 p2, vec3 p3)\n{\n    vec3 _6254 = vec3((abcd.x * p0.x) + (abcd.y * p0.z), p0.y, (abcd.z * p0.x) + (abcd.w * p0.z));\n    vec3 _6280 = vec3((abcd.x * p1.x) + (abcd.y * p1.z), p1.y, (abcd.z * p1.x) + (abcd.w * p1.z));\n    vec3 _6306 = vec3((abcd.x * p2.x) + (abcd.y * p2.z), p2.y, (abcd.z * p2.x) + (abcd.w * p2.z));\n    vec3 _6332 = vec3((abcd.x * p3.x) + (abcd.y * p3.z), p3.y, (abcd.z * p3.x) + (abcd.w * p3.z));\n    vec3 sum = vec3(0.0);\n    vec3 leave = vec3(0.0);\n    vec3 enter = vec3(0.0);\n    vec3 param = _6254;\n    vec3 param_1 = _6280;\n    vec3 param_2 = vec3(0.0);\n    vec3 param_3 = vec3(0.0);\n    vec3 param_4 = vec3(0.0);\n    vec2 param_5 = vec2(0.0);\n    fa_ltc_clip_edge(param, param_1, param_2, param_3, param_4, param_5);\n    sum = param_2;\n    leave = param_3;\n    enter = param_4;\n    vec3 param_6 = _6280;\n    vec3 param_7 = _6306;\n    vec3 param_8 = param_2;\n    vec3 param_9 = param_3;\n    vec3 param_10 = param_4;\n    vec2 param_11 = param_5;\n    fa_ltc_clip_edge(param_6, param_7, param_8, param_9, param_10, param_11);\n    sum = param_8;\n    leave = param_9;\n    enter = param_10;\n    vec3 param_12 = _6306;\n    vec3 param_13 = _6332;\n    vec3 param_14 = param_8;\n    vec3 param_15 = param_9;\n    vec3 param_16 = param_10;\n    vec2 param_17 = param_11;\n    fa_ltc_clip_edge(param_12, param_13, param_14, param_15, param_16, param_17);\n    sum = param_14;\n    leave = param_15;\n    enter = param_16;\n    vec3 param_18 = _6332;\n    vec3 param_19 = _6254;\n    vec3 param_20 = param_14;\n    vec3 param_21 = param_15;\n    vec3 param_22 = param_16;\n    vec2 param_23 = param_17;\n    fa_ltc_clip_edge(param_18, param_19, param_20, param_21, param_22, param_23);\n    sum = param_20;\n    leave = param_21;\n    enter = param_22;\n    if ((param_23.x * param_23.y) > 0.5)\n    {\n        vec3 param_24 = leave;\n        vec3 param_25 = enter;\n        sum += fa_ltc_edge_vector(param_24, param_25);\n    }\n    return sum.z * 0.15915493667125701904296875;\n}\n\nfloat fa_ltc_rect(vec4 abcd, vec3 center, vec3 ex, vec3 ey)\n{\n    vec4 param = abcd;\n    vec3 param_1 = (center - ex) - ey;\n    vec3 param_2 = (center + ex) - ey;\n    vec3 param_3 = (center + ex) + ey;\n    vec3 param_4 = (center - ex) + ey;\n    return abs(fa_ltc_quad(param, param_1, param_2, param_3, param_4));\n}\n\nfloat fa_area_form(vec4 m, float shape, vec3 pc, vec3 ex, vec3 ey)\n{\n    if ((shape < 0.5) || (shape > 1.5))\n    {\n        vec4 param = m;\n        vec3 param_1 = pc;\n        vec3 param_2 = ex;\n        vec3 param_3 = ey;\n        return fa_ltc_rect(param, param_1, param_2, param_3);\n    }\n    vec3 _6481 = (pc + (ex * 0.92387950420379638671875)) + (ey * 0.3826834261417388916015625);\n    vec3 _6505 = (pc - (ex * 0.92387950420379638671875)) + (ey * 0.3826834261417388916015625);\n    vec3 _6521 = (pc - (ex * 0.3826834261417388916015625)) - (ey * 0.92387950420379638671875);\n    vec4 param_4 = m;\n    vec3 param_5 = _6481;\n    vec3 param_6 = (pc + (ex * 0.3826834261417388916015625)) + (ey * 0.92387950420379638671875);\n    vec3 param_7 = (pc - (ex * 0.3826834261417388916015625)) + (ey * 0.92387950420379638671875);\n    vec3 param_8 = _6505;\n    vec4 param_9 = m;\n    vec3 param_10 = _6481;\n    vec3 param_11 = _6505;\n    vec3 param_12 = (pc - (ex * 0.92387950420379638671875)) - (ey * 0.3826834261417388916015625);\n    vec3 param_13 = _6521;\n    vec4 param_14 = m;\n    vec3 param_15 = _6481;\n    vec3 param_16 = _6521;\n    vec3 param_17 = (pc + (ex * 0.3826834261417388916015625)) - (ey * 0.92387950420379638671875);\n    vec3 param_18 = (pc + (ex * 0.92387950420379638671875)) - (ey * 0.3826834261417388916015625);\n    return abs((fa_ltc_quad(param_4, param_5, param_6, param_7, param_8) + fa_ltc_quad(param_9, param_10, param_11, param_12, param_13)) + fa_ltc_quad(param_14, param_15, param_16, param_17, param_18));\n}\n\nvec2 fa_ltc_uv(float roughness, float ndv)\n{\n    return ((vec2(clamp((roughness - 0.0500000007450580596923828125) * 1.0526316165924072265625, 0.0, 1.0), sqrt(clamp(1.0 - ndv, 0.0, 1.0))) * 63.0) + vec2(0.5)) * vec2(0.015625);\n}\n\nvec3 fa_area_shade(int li, vec3 world_pos, vec3 n, vec3 v, vec3 diffuse_color, vec3 f0, float f90, float roughness, float ndv, float window)\n{\n    int param = li;\n    int _6579 = fa_light_base(param);\n    int param_1 = _6579;\n    int param_2 = _6579 + 1;\n    int param_3 = _6579 + 2;\n    int param_4 = _6579 + 4;\n    vec4 _6601 = fa_light_texel(param_4);\n    int param_5 = _6579 + 5;\n    vec4 _6606 = fa_light_texel(param_5);\n    int param_6 = _6579 + 6;\n    vec4 _6611 = fa_light_texel(param_6);\n    float _6612 = _6611.w;\n    vec3 _6617 = fa_light_texel(param_1).xyz - world_pos;\n    bool _6619 = _6612 < 1.5;\n    bool _6626;\n    if (_6619)\n    {\n        _6626 = dot(normalize(fa_light_texel(param_3).xyz), _6617) >= 0.0;\n    }\n    else\n    {\n        _6626 = _6619;\n    }\n    if (_6626)\n    {\n        return vec3(0.0);\n    }\n    bool _6635 = (_6612 > 0.5) && _6619;\n    float _6639 = _6635 ? 1.0539000034332275390625 : 1.0;\n    vec3 _6642 = _6601.xyz;\n    float _6644 = _6601.w;\n    vec3 _6650 = _6606.xyz;\n    float _6652 = _6606.w;\n    vec3 up = _6650 * (_6652 * _6639);\n    float _6658;\n    if (_6635)\n    {\n        _6658 = (3.1415927410125732421875 * _6644) * _6644;\n    }\n    else\n    {\n        _6658 = (4.0 * _6644) * _6652;\n    }\n    if (_6612 > 1.5)\n    {\n        vec3 _6684 = cross(_6642, -_6617);\n        vec3 perp = _6684;\n        float _6688 = dot(_6684, _6684);\n        vec3 _6691;\n        if (_6688 > 1.0000000133514319600180897396058e-10)\n        {\n            _6691 = perp * inversesqrt(_6688);\n        }\n        else\n        {\n            _6691 = _6650;\n        }\n        perp = _6691;\n        up = _6691 * _6652;\n    }\n    float _6712 = max(_6658, 9.9999999747524270787835121154785e-07);\n    vec3 param_7 = n;\n    vec3 param_8 = v;\n    vec3 _6722 = fa_ltc_tangent(param_7, param_8);\n    vec3 param_9 = _6722;\n    vec3 param_10 = n;\n    vec3 param_11 = _6617;\n    vec3 _6730 = fa_ltc_local(param_9, param_10, param_11);\n    vec3 param_12 = _6722;\n    vec3 param_13 = n;\n    vec3 param_14 = _6642 * (_6644 * _6639);\n    vec3 _6738 = fa_ltc_local(param_12, param_13, param_14);\n    vec3 param_15 = _6722;\n    vec3 param_16 = n;\n    vec3 param_17 = up;\n    vec3 _6746 = fa_ltc_local(param_15, param_16, param_17);\n    vec4 param_18 = vec4(1.0, 0.0, 0.0, 1.0);\n    float param_19 = _6612;\n    vec3 param_20 = _6730;\n    vec3 param_21 = _6738;\n    vec3 param_22 = _6746;\n    float param_23 = roughness;\n    float param_24 = ndv;\n    vec2 _6765 = fa_ltc_uv(param_23, param_24) * 64.0;\n    vec2 param_25 = _6765;\n    vec2 param_26 = _6765 + vec2(64.0, 0.0);\n    vec4 _6775 = fa_atlas_fetch(param_26);\n    vec4 param_27 = fa_atlas_fetch(param_25);\n    float param_28 = _6612;\n    vec3 param_29 = _6730;\n    vec3 param_30 = _6738;\n    vec3 param_31 = _6746;\n    return (((diffuse_color * fa_area_form(param_18, param_19, param_20, param_21, param_22)) + (((f0 * _6775.x) + ((vec3(f90) - f0) * _6775.y)) * fa_area_form(param_27, param_28, param_29, param_30, param_31))) * fa_light_texel(param_2).xyz) * ((((3.1415927410125732421875 * dot(_6617, _6617)) + _6712) / _6712) * window);\n}\n\nvec3 fa_light_rgb(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 1;\n    return fa_light_texel(param_1).xyz;\n}\n\nfloat fa_d_charlie(float alpha, float ndh)\n{\n    float _4914 = 1.0 / alpha;\n    return ((2.0 + _4914) * pow(sqrt(max(1.0 - (ndh * ndh), 9.9999997473787516355514526367188e-05)), _4914)) * 0.15915493667125701904296875;\n}\n\nfloat fa_v_ashikhmin(float ndl, float ndv)\n{\n    return clamp(0.25 / max((ndl + ndv) - (ndl * ndv), 9.9999997473787516355514526367188e-05), 0.0, 1.0);\n}\n\nfloat fa_layers_coat(FaLayers L, vec3 l, vec3 h, float vdh)\n{\n    float _4949 = max(dot(L.nc, l), 0.0);\n    float _4955 = max(dot(L.nc, h), 0.0);\n    float _4964 = ((_4955 * _4955) * (L.coat_a2 - 1.0)) + 1.0;\n    return (((L.coat * (0.039999999105930328369140625 + (0.959999978542327880859375 * pow(clamp(1.0 - vdh, 0.0, 1.0), 5.0)))) * (((L.coat_a2 / ((3.1415927410125732421875 * _4964) * _4964)) * (0.5 / max(mix((2.0 * _4949) * L.coat_ndv, _4949 + L.coat_ndv, L.coat_alpha), 9.9999997473787516355514526367188e-05))) * 3.1415927410125732421875)) * step(9.9999997473787516355514526367188e-05, _4949)) * _4949;\n}\n\nvec3 fa_area_layers(FaLayers L, int li, vec3 world_pos, vec3 n, vec3 v, vec3 l, vec3 diffuse_color, vec3 f0, float roughness, float ndv, float window)\n{\n    int param = li;\n    vec3 param_1 = world_pos;\n    vec3 param_2 = n;\n    vec3 param_3 = v;\n    vec3 param_4 = diffuse_color;\n    vec3 param_5 = f0;\n    float param_6 = L.f90;\n    float param_7 = roughness;\n    float param_8 = ndv;\n    float param_9 = window;\n    float _6843;\n    if (L.sheen_on)\n    {\n        _6843 = L.sheen_scale;\n    }\n    else\n    {\n        _6843 = 1.0;\n    }\n    vec3 result = fa_area_shade(param, param_1, param_2, param_3, param_4, param_5, param_6, param_7, param_8, param_9) * (L.keep * _6843);\n    vec3 _6856 = normalize(l + v);\n    int param_10 = li;\n    vec3 _6867 = fa_light_rgb(param_10) * window;\n    if (L.sheen_on)\n    {\n        float _6876 = max(dot(n, l), 0.0);\n        float param_11 = L.sheen_alpha;\n        float param_12 = max(dot(n, _6856), 0.0);\n        float param_13 = _6876;\n        float param_14 = ndv;\n        result += ((L.sheen * _6867) * (((((fa_d_charlie(param_11, param_12) * fa_v_ashikhmin(param_13, param_14)) * 3.1415927410125732421875) * step(9.9999997473787516355514526367188e-05, _6876)) * _6876) * L.keep));\n    }\n    if (L.coat > 0.0)\n    {\n        FaLayers param_15 = L;\n        vec3 param_16 = l;\n        vec3 param_17 = _6856;\n        float param_18 = max(dot(v, _6856), 0.0);\n        result += (_6867 * fa_layers_coat(param_15, param_16, param_17, param_18));\n    }\n    return result;\n}\n\nfloat fa_d_ggx_aniso(float ndh, float tdh, float bdh, float at, float ab)\n{\n    float _4817 = tdh / at;\n    float _4821 = bdh / ab;\n    float _4833 = ((_4817 * _4817) + (_4821 * _4821)) + (ndh * ndh);\n    return 1.0 / ((((3.1415927410125732421875 * at) * ab) * _4833) * _4833);\n}\n\nfloat fa_lambda_ggx_aniso(float n, float t, float b, float at, float ab)\n{\n    return 0.5 * (sqrt(1.0 + (((((at * at) * t) * t) + (((ab * ab) * b) * b)) / max(n * n, 9.9999999392252902907785028219223e-09))) - 1.0);\n}\n\nfloat fa_v_ggx_aniso(float ndl, float ndv, float tdv, float bdv, float tdl, float bdl, float at, float ab)\n{\n    float param = ndv;\n    float param_1 = tdv;\n    float param_2 = bdv;\n    float param_3 = at;\n    float param_4 = ab;\n    float param_5 = ndl;\n    float param_6 = tdl;\n    float param_7 = bdl;\n    float param_8 = at;\n    float param_9 = ab;\n    return clamp(1.0 / ((4.0 * max(ndl * ndv, 9.9999997473787516355514526367188e-05)) * ((1.0 + fa_lambda_ggx_aniso(param, param_1, param_2, param_3, param_4)) + fa_lambda_ggx_aniso(param_5, param_6, param_7, param_8, param_9))), 0.0, 1.0);\n}\n\nvec3 fa_layers_light(FaLayers L, vec3 diffuse_color, vec3 f0, vec3 n, vec3 v, vec3 l, vec3 h, float ndl, float ndv, float ndh, float vdh, float alpha, float a2)\n{\n    float _5013 = step(9.9999997473787516355514526367188e-05, ndl);\n    float d_ggx;\n    float vis;\n    if (L.aniso != 0.0)\n    {\n        float param = ndh;\n        float param_1 = dot(L.t, h);\n        float param_2 = dot(L.b, h);\n        float param_3 = L.at;\n        float param_4 = L.ab;\n        d_ggx = fa_d_ggx_aniso(param, param_1, param_2, param_3, param_4);\n        float param_5 = ndl;\n        float param_6 = ndv;\n        float param_7 = dot(L.t, v);\n        float param_8 = dot(L.b, v);\n        float param_9 = dot(L.t, l);\n        float param_10 = dot(L.b, l);\n        float param_11 = L.at;\n        float param_12 = L.ab;\n        vis = fa_v_ggx_aniso(param_5, param_6, param_7, param_8, param_9, param_10, param_11, param_12);\n    }\n    else\n    {\n        float _5092 = ((ndh * ndh) * (a2 - 1.0)) + 1.0;\n        d_ggx = a2 / ((3.1415927410125732421875 * _5092) * _5092);\n        vis = 0.5 / max(mix((2.0 * ndl) * ndv, ndl + ndv, alpha), 9.9999997473787516355514526367188e-05);\n    }\n    vec3 base = diffuse_color + (((f0 + ((vec3(L.f90) - f0) * pow(clamp(1.0 - vdh, 0.0, 1.0), 5.0))) * ((d_ggx * vis) * 3.1415927410125732421875)) * _5013);\n    if (L.sheen_on)\n    {\n        float param_13 = L.sheen_alpha;\n        float param_14 = ndh;\n        float param_15 = ndl;\n        float param_16 = ndv;\n        base = (base * L.sheen_scale) + (L.sheen * (((fa_d_charlie(param_13, param_14) * fa_v_ashikhmin(param_15, param_16)) * 3.1415927410125732421875) * _5013));\n    }\n    vec3 result = base * (L.keep * ndl);\n    if (L.coat > 0.0)\n    {\n        FaLayers param_17 = L;\n        vec3 param_18 = l;\n        vec3 param_19 = h;\n        float param_20 = vdh;\n        result += vec3(fa_layers_coat(param_17, param_18, param_19, param_20));\n    }\n    return result;\n}\n\nvec2 fa_env_brdf(float rough, float ndv)\n{\n    vec4 _4216 = (vec4(-1.0, -0.0274999998509883880615234375, -0.572000026702880859375, 0.02199999988079071044921875) * rough) + vec4(1.0, 0.0425000004470348358154296875, 1.03999996185302734375, -0.039999999105930328369140625);\n    float _4219 = _4216.x;\n    return (vec2(-1.03999996185302734375, 1.03999996185302734375) * ((min(_4219 * _4219, exp2((-9.27999973297119140625) * ndv)) * _4219) + _4216.y)) + _4216.zw;\n}\n\nvec3 fa_probe_level(vec2 origin, float res, int lv, vec2 e)\n{\n    float _3524;\n    if (lv == 0)\n    {\n        _3524 = 0.0;\n    }\n    else\n    {\n        _3524 = res + 2.0;\n    }\n    float _3534;\n    if (lv == 0)\n    {\n        _3534 = 0.0;\n    }\n    else\n    {\n        _3534 = (res - (res / float(1 << max((lv - 1), 0)))) + (2.0 * float(lv - 1));\n    }\n    return textureLod(fa_probe_atlas_fa_env_smp, (((origin + vec2(_3524, _3534)) + vec2(1.0)) + (((e * 0.5) + vec2(0.5)) * (res / float(1 << lv)))) / fa_atlas_size(), 0.0).xyz;\n}\n\nvec3 fa_probe_radiance(vec2 origin, float res, vec3 d, float rough)\n{\n    float _3580;\n    if (res > 64.5)\n    {\n        _3580 = 5.0;\n    }\n    else\n    {\n        _3580 = (res > 32.5) ? 4.0 : 3.0;\n    }\n    float _3595 = clamp(rough, 0.0, 1.0) * (_3580 - 1.0);\n    int _3602 = int(min(floor(_3595), _3580 - 2.0));\n    float _3607 = _3595 - float(_3602);\n    vec3 param = d;\n    vec2 _3611 = fa_oct_encode(param);\n    vec2 param_1 = origin;\n    float param_2 = res;\n    int param_3 = _3602;\n    vec2 param_4 = _3611;\n    vec3 _3621 = fa_probe_level(param_1, param_2, param_3, param_4);\n    if (_3607 < 0.00200000009499490261077880859375)\n    {\n        return _3621;\n    }\n    vec2 param_5 = origin;\n    float param_6 = res;\n    int param_7 = _3602 + 1;\n    vec2 param_8 = _3611;\n    return mix(_3621, fa_probe_level(param_5, param_6, param_7, param_8), vec3(_3607));\n}\n\nvec3 fa_probe_box_dir(vec3 d, vec4 posw, vec4 bx, vec4 by, vec4 bz)\n{\n    if (posw.w < 0.5)\n    {\n        return d;\n    }\n    float _3694 = dot(bx.xyz, fa_world_pos) + bx.w;\n    float _3701 = dot(by.xyz, fa_world_pos) + by.w;\n    float _3708 = dot(bz.xyz, fa_world_pos) + bz.w;\n    float _3714 = dot(bx.xyz, d);\n    float _3718 = dot(by.xyz, d);\n    float _3722 = dot(bz.xyz, d);\n    float _3728;\n    if (_3714 > 9.9999999747524270787835121154785e-07)\n    {\n        _3728 = (1.0 - _3694) / _3714;\n    }\n    else\n    {\n        float _3742;\n        if (_3714 < (-9.9999999747524270787835121154785e-07))\n        {\n            _3742 = ((-1.0) - _3694) / _3714;\n        }\n        else\n        {\n            _3742 = 1000000015047466219876688855040.0;\n        }\n        _3728 = _3742;\n    }\n    float tx = _3728;\n    float _3759;\n    if (_3718 > 9.9999999747524270787835121154785e-07)\n    {\n        _3759 = (1.0 - _3701) / _3718;\n    }\n    else\n    {\n        float _3772;\n        if (_3718 < (-9.9999999747524270787835121154785e-07))\n        {\n            _3772 = ((-1.0) - _3701) / _3718;\n        }\n        else\n        {\n            _3772 = 1000000015047466219876688855040.0;\n        }\n        _3759 = _3772;\n    }\n    float ty = _3759;\n    float _3788;\n    if (_3722 > 9.9999999747524270787835121154785e-07)\n    {\n        _3788 = (1.0 - _3708) / _3722;\n    }\n    else\n    {\n        float _3801;\n        if (_3722 < (-9.9999999747524270787835121154785e-07))\n        {\n            _3801 = ((-1.0) - _3708) / _3722;\n        }\n        else\n        {\n            _3801 = 1000000015047466219876688855040.0;\n        }\n        _3788 = _3801;\n    }\n    float _3813 = tx;\n    float _3816 = (_3813 > 0.0) ? _3813 : 1000000015047466219876688855040.0;\n    tx = _3816;\n    float _3817 = ty;\n    float _3820 = (_3817 > 0.0) ? _3817 : 1000000015047466219876688855040.0;\n    ty = _3820;\n    float _3830 = min(_3816, min(_3820, (_3788 > 0.0) ? _3788 : 1000000015047466219876688855040.0));\n    if (_3830 > 100000001504746621987668885504.0)\n    {\n        return d;\n    }\n    vec3 _3846 = (fa_world_pos + (d * _3830)) - posw.xyz;\n    vec3 _3851;\n    if (dot(_3846, _3846) > 1.0000000133514319600180897396058e-10)\n    {\n        _3851 = normalize(_3846);\n    }\n    else\n    {\n        _3851 = d;\n    }\n    return _3851;\n}\n\nvec3 fa_probe_environment(vec4 tile, vec4 posw, vec4 bx, vec4 by, vec4 bz, inout vec3 d, float rough)\n{\n    vec3 param = d;\n    vec4 param_1 = posw;\n    vec4 param_2 = bx;\n    vec4 param_3 = by;\n    vec4 param_4 = bz;\n    d = fa_probe_box_dir(param, param_1, param_2, param_3, param_4);\n    vec2 param_5 = tile.xy;\n    float param_6 = tile.z;\n    vec3 param_7 = d;\n    float param_8 = rough;\n    return fa_probe_radiance(param_5, param_6, param_7, param_8);\n}\n\nvec3 fa_environment(vec3 d, float rough)\n{\n    float _3897 = (1.0 - fa_mesh_fs_params[42].w) - fa_mesh_fs_params[47].w;\n    vec3 outc = vec3(0.0);\n    if (_3897 > 0.0005000000237487256526947021484375)\n    {\n        vec3 base;\n        if (fa_mesh_fs_params[11].w > 0.5)\n        {\n            vec2 param = fa_mesh_fs_params[41].zw;\n            float param_1 = 128.0;\n            vec3 param_2 = d;\n            float param_3 = rough;\n            base = fa_probe_radiance(param, param_1, param_2, param_3);\n        }\n        else\n        {\n            float _3925 = rough * rough;\n            float _3956 = 0.60000002384185791015625 * _3925;\n            base = mix(mix(fa_mesh_fs_params[12].xyz * 0.550000011920928955078125, mix(fa_mesh_fs_params[12].xyz, fa_mesh_fs_params[11].xyz, vec3(pow(clamp(d.y * (1.0 - (0.699999988079071044921875 * _3925)), 0.0, 1.0), 0.550000011920928955078125))), vec3(smoothstep((-0.0500000007450580596923828125) - _3956, 0.0500000007450580596923828125 + _3956, d.y))), ((fa_mesh_fs_params[11].xyz + fa_mesh_fs_params[12].xyz) * 0.5) * 0.800000011920928955078125, vec3(_3925 * 0.60000002384185791015625));\n        }\n        outc = base * _3897;\n    }\n    if (fa_mesh_fs_params[42].w > 0.0)\n    {\n        vec4 param_4 = fa_mesh_fs_params[42];\n        vec4 param_5 = fa_mesh_fs_params[43];\n        vec4 param_6 = fa_mesh_fs_params[44];\n        vec4 param_7 = fa_mesh_fs_params[45];\n        vec4 param_8 = fa_mesh_fs_params[46];\n        vec3 param_9 = d;\n        float param_10 = rough;\n        vec3 _4015 = fa_probe_environment(param_4, param_5, param_6, param_7, param_8, param_9, param_10);\n        outc += (_4015 * fa_mesh_fs_params[42].w);\n    }\n    if (fa_mesh_fs_params[47].w > 0.0)\n    {\n        vec4 param_11 = fa_mesh_fs_params[47];\n        vec4 param_12 = fa_mesh_fs_params[48];\n        vec4 param_13 = fa_mesh_fs_params[49];\n        vec4 param_14 = fa_mesh_fs_params[50];\n        vec4 param_15 = fa_mesh_fs_params[51];\n        vec3 param_16 = d;\n        float param_17 = rough;\n        vec3 _4047 = fa_probe_environment(param_11, param_12, param_13, param_14, param_15, param_16, param_17);\n        outc += (_4047 * fa_mesh_fs_params[47].w);\n    }\n    return outc;\n}\n\nvec3 fa_layers_ibl(FaLayers L, vec3 n, vec3 v, vec3 f0, float roughness, float occlusion)\n{\n    vec3 rn = n;\n    if (L.aniso != 0.0)\n    {\n        vec3 _4694;\n        if (L.aniso >= 0.0)\n        {\n            _4694 = L.b;\n        }\n        else\n        {\n            _4694 = L.t;\n        }\n        rn = normalize(mix(n, cross(cross(_4694, v), _4694), vec3(abs(L.aniso) * smoothstep(0.0, 0.25, roughness))));\n    }\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05);\n    vec2 _4730 = fa_env_brdf(param, param_1);\n    vec3 param_2 = reflect(-v, rn);\n    float param_3 = roughness;\n    vec3 result = (fa_environment(param_2, param_3) * ((f0 * _4730.x) + (vec3(L.f90) * _4730.y))) * L.base_scale;\n    if (L.sheen_on)\n    {\n        vec3 param_4 = n;\n        float param_5 = L.sheen_rough;\n        result += ((L.sheen * (L.sheen_e * L.keep)) * fa_environment(param_4, param_5));\n    }\n    result *= occlusion;\n    if (L.coat > 0.0)\n    {\n        float param_6 = L.coat_rough;\n        float param_7 = L.coat_ndv;\n        vec2 _4788 = fa_env_brdf(param_6, param_7);\n        vec3 param_8 = reflect(-v, L.nc);\n        float param_9 = L.coat_rough;\n        result += (fa_environment(param_8, param_9) * (L.coat * ((0.039999999105930328369140625 * _4788.x) + _4788.y)));\n    }\n    return result;\n}\n\nvec3 fa_sky_reflection(vec3 n, vec3 v, vec3 f0, float roughness)\n{\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05);\n    vec2 _4258 = fa_env_brdf(param, param_1);\n    vec3 param_2 = reflect(-v, n);\n    float param_3 = roughness;\n    return fa_environment(param_2, param_3) * ((f0 * _4258.x) + vec3(_4258.y));\n}\n\nvec2 fa_xm_size(int k)\n{\n    return max(floor(fa_mesh_fs_params[24].zw / vec2(float(1 << k))), vec2(1.0));\n}\n\nvec2 fa_xm_origin(int k)\n{\n    if (k == 0)\n    {\n        return vec2(0.0);\n    }\n    float y = 0.0;\n    for (int j = 1; j < k; j++)\n    {\n        int param = j;\n        y += fa_xm_size(param).y;\n    }\n    return vec2(fa_mesh_fs_params[24].z, y);\n}\n\nvec3 fa_xm_texel(vec2 size, vec2 origin, vec2 p)\n{\n    return texelFetch(fa_screen_tex_fa_shadow_smp, ivec2(origin + clamp(p, vec2(0.0), size - vec2(1.0))), 0).xyz;\n}\n\nvec3 fa_xm_level(int k, vec2 uv)\n{\n    int param = k;\n    vec2 _5498 = fa_xm_size(param);\n    int param_1 = k;\n    vec2 _5502 = fa_xm_origin(param_1);\n    vec2 _5508 = (uv * _5498) - vec2(0.5);\n    vec2 _5511 = fract(_5508);\n    vec2 _5514 = floor(_5508);\n    vec2 param_2 = _5498;\n    vec2 param_3 = _5502;\n    vec2 param_4 = _5514;\n    vec2 param_5 = _5498;\n    vec2 param_6 = _5502;\n    vec2 param_7 = _5514 + vec2(1.0, 0.0);\n    vec2 param_8 = _5498;\n    vec2 param_9 = _5502;\n    vec2 param_10 = _5514 + vec2(0.0, 1.0);\n    vec2 param_11 = _5498;\n    vec2 param_12 = _5502;\n    vec2 param_13 = _5514 + vec2(1.0);\n    vec3 _5556 = vec3(_5511.x);\n    return mix(mix(fa_xm_texel(param_2, param_3, param_4), fa_xm_texel(param_5, param_6, param_7), _5556), mix(fa_xm_texel(param_8, param_9, param_10), fa_xm_texel(param_11, param_12, param_13), _5556), vec3(_5511.y));\n}\n\nvec3 fa_xm_sample(vec2 uv, float lod)\n{\n    float _5575 = max(fa_mesh_fs_params[31].w - 1.0, 0.0);\n    float _5579 = clamp(lod, 0.0, _5575);\n    int _5583 = int(floor(_5579));\n    int param = _5583;\n    vec2 param_1 = uv;\n    vec3 c = fa_xm_level(param, param_1);\n    float _5593 = float(_5583);\n    float _5594 = _5579 - _5593;\n    bool _5596 = _5594 > 0.001000000047497451305389404296875;\n    bool _5603;\n    if (_5596)\n    {\n        _5603 = _5593 < _5575;\n    }\n    else\n    {\n        _5603 = _5596;\n    }\n    if (_5603)\n    {\n        int param_2 = _5583 + 1;\n        vec2 param_3 = uv;\n        c = mix(c, fa_xm_level(param_2, param_3), vec3(_5594));\n    }\n    return c;\n}\n\nvec3 fa_transmitted(Surface s, vec3 n, vec3 v, float roughness, vec3 f0, float f90, float keep, float tr, inout float blend)\n{\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05);\n    vec2 _5629 = fa_env_brdf(param, param_1);\n    vec3 through = ((vec3(1.0) - clamp((f0 * _5629.x) + (vec3(f90) * _5629.y), vec3(0.0), vec3(1.0))) * s.albedo) * (tr * keep);\n    float _5657 = max(s.thickness, 0.0);\n    bool _5662 = _5657 > 0.0;\n    if ((s.attenuation_distance > 0.0) && _5662)\n    {\n        through *= exp((-((-log(clamp(s.attenuation_color, vec3(9.9999997473787516355514526367188e-05), vec3(1.0)))) / vec3(s.attenuation_distance))) * _5657);\n    }\n    bool _5687 = fa_mesh_fs_params[30].w > 1.5;\n    bool _5694;\n    if (!_5687)\n    {\n        _5694 = fa_mesh_fs_params[30].w < 0.5;\n    }\n    else\n    {\n        _5694 = _5687;\n    }\n    if (_5694)\n    {\n        blend = clamp(dot(through, vec3(0.3333333432674407958984375)), 0.0, 0.980000019073486328125);\n        return vec3(0.0);\n    }\n    vec3 world = fa_world_pos;\n    if (_5662)\n    {\n        world += (refract(-v, n, 1.0 / max(s.ior, 1.0)) * _5657);\n    }\n    vec4 _5729 = vec4(world, 1.0);\n    float _5734 = dot(fa_mesh_fs_params[28], _5729);\n    vec2 uv = vec2(0.5);\n    if (_5734 > 9.9999997473787516355514526367188e-05)\n    {\n        vec2 _5752 = vec2(dot(fa_mesh_fs_params[26], _5729), dot(fa_mesh_fs_params[27], _5729)) / vec2(_5734);\n        float _5760;\n        if (fa_mesh_fs_params[24].y > 0.5)\n        {\n            _5760 = (_5752.y * 0.5) + 0.5;\n        }\n        else\n        {\n            _5760 = 0.5 - (_5752.y * 0.5);\n        }\n        uv = vec2((_5752.x * 0.5) + 0.5, _5760);\n    }\n    vec2 param_2 = clamp(uv, vec2(0.0), vec2(1.0));\n    float param_3 = (clamp(roughness, 0.0, 1.0) * clamp((2.0 * s.ior) - 2.0, 0.0, 1.0)) * max(fa_mesh_fs_params[31].w - 1.0, 0.0);\n    return through * fa_xm_sample(param_2, param_3);\n}\n\nvec3 fa_shadow_debug(vec3 color, vec3 world)\n{\n    if (fa_shadows[27].w < 0.5)\n    {\n        return color;\n    }\n    int _3275 = int(fa_shadows[25].x + 0.5);\n    float _3285 = dot(world - fa_shadows[27].xyz, fa_shadows[28].xyz);\n    vec3 tint_1 = vec3(0.3499999940395355224609375);\n    bool _3290 = _3275 > 0;\n    bool _3299;\n    if (_3290)\n    {\n        int param = _3275 - 1;\n        _3299 = _3285 <= fa_shadow_split_at(param);\n    }\n    else\n    {\n        _3299 = _3290;\n    }\n    if (_3299)\n    {\n        tint_1 = vec3(1.0, 0.1500000059604644775390625, 0.100000001490116119384765625);\n        bool _3305 = _3275 > 1;\n        bool _3312;\n        if (_3305)\n        {\n            _3312 = _3285 > fa_shadows[24].x;\n        }\n        else\n        {\n            _3312 = _3305;\n        }\n        if (_3312)\n        {\n            tint_1 = vec3(0.100000001490116119384765625, 0.89999997615814208984375, 0.20000000298023223876953125);\n        }\n        bool _3318 = _3275 > 2;\n        bool _3325;\n        if (_3318)\n        {\n            _3325 = _3285 > fa_shadows[24].y;\n        }\n        else\n        {\n            _3325 = _3318;\n        }\n        if (_3325)\n        {\n            tint_1 = vec3(0.1500000059604644775390625, 0.300000011920928955078125, 1.0);\n        }\n        bool _3331 = _3275 > 3;\n        bool _3338;\n        if (_3331)\n        {\n            _3338 = _3285 > fa_shadows[24].z;\n        }\n        else\n        {\n            _3338 = _3331;\n        }\n        if (_3338)\n        {\n            tint_1 = vec3(1.0, 0.89999997615814208984375, 0.100000001490116119384765625);\n        }\n    }\n    return mix(color, tint_1, vec3(0.550000011920928955078125));\n}\n\nvoid main()\n{\n    fa_inst_load();\n    vec3 _8717 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _8717 = -_8717;\n    }\n    vec3 _8011 = normalize(fa_mesh_fs_params[0].xyz - fa_world_pos);\n    vec3 param = fa_world_pos;\n    fa_cluster_begin(param);\n    SurfaceInput param_1 = SurfaceInput(fa_world_pos, _8717, fa_world_tangent, fa_uv, fa_vertex_color, _8011, gl_FrontFacing);\n    Surface _8019 = fa_standard_surface(param_1);\n    vec3 _8748 = _8019.albedo;\n    float _8749 = _8019.alpha;\n    vec3 _8750 = _8019.normal;\n    float _8751 = _8019.metallic;\n    float _8752 = _8019.roughness;\n    float _8753 = _8019.occlusion;\n    vec3 _8754 = _8019.emission;\n    float _8755 = _8019.clearcoat;\n    float _8756 = _8019.clearcoat_roughness;\n    vec3 _8757 = _8019.sheen_color;\n    float _8758 = _8019.sheen_roughness;\n    float _8759 = _8019.anisotropy;\n    float _8760 = _8019.anisotropy_rotation;\n    float _8761 = _8019.specular;\n    float _8762 = _8019.ior;\n    vec3 _8763 = _8019.specular_color;\n    float _8764 = _8019.transmission;\n    float _8765 = _8019.thickness;\n    vec3 _8766 = _8019.attenuation_color;\n    float _8767 = _8019.attenuation_distance;\n    SurfaceInput param_2 = SurfaceInput(fa_world_pos, _8717, fa_world_tangent, fa_uv, fa_vertex_color, _8011, gl_FrontFacing);\n    Surface param_3 = _8019;\n    surface(param_2, param_3);\n    _8748 = param_3.albedo;\n    _8749 = param_3.alpha;\n    _8750 = param_3.normal;\n    _8751 = param_3.metallic;\n    _8752 = param_3.roughness;\n    _8753 = param_3.occlusion;\n    _8754 = param_3.emission;\n    _8755 = param_3.clearcoat;\n    _8756 = param_3.clearcoat_roughness;\n    _8757 = param_3.sheen_color;\n    _8758 = param_3.sheen_roughness;\n    _8759 = param_3.anisotropy;\n    _8760 = param_3.anisotropy_rotation;\n    _8761 = param_3.specular;\n    _8762 = param_3.ior;\n    _8763 = param_3.specular_color;\n    _8764 = param_3.transmission;\n    _8765 = param_3.thickness;\n    _8766 = param_3.attenuation_color;\n    _8767 = param_3.attenuation_distance;\n    vec3 param_4 = fa_world_pos;\n    vec3 param_5 = _8717;\n    vec3 param_6 = param_3.albedo;\n    vec3 param_7 = param_3.normal;\n    fa_apply_decals(param_4, param_5, param_6, param_7);\n    _8748 = param_6;\n    _8750 = param_7;\n    float fa_tr_blend = 0.0;\n    vec3 result;\n    if (fa_mesh_fs_params[3].w > 0.5)\n    {\n        result = _8748;\n    }\n    else\n    {\n        vec3 _8059 = normalize(_8750);\n        float _8066 = clamp(_8751, 0.0, 1.0);\n        float _8070 = clamp(_8752, 0.0500000007450580596923828125, 1.0);\n        float _8074 = _8070 * _8070;\n        float _8078 = _8074 * _8074;\n        float _8083 = max(dot(_8059, _8011), 9.9999997473787516355514526367188e-05);\n        float _8089 = 1.0 - _8066;\n        float _8090 = clamp(_8764, 0.0, 1.0) * _8089;\n        vec3 _8099 = (_8748 * _8089) * (1.0 - _8090);\n        vec3 _8106 = mix(vec3(0.039999999105930328369140625), _8748, vec3(_8066));\n        vec3 f0 = _8106;\n        SurfaceInput param_8 = SurfaceInput(fa_world_pos, _8717, fa_world_tangent, fa_uv, fa_vertex_color, _8011, gl_FrontFacing);\n        Surface param_9 = Surface(_8748, _8749, _8750, _8751, _8752, _8753, _8754, _8755, _8756, _8757, _8758, _8759, _8760, _8761, _8762, _8763, _8764, _8765, _8766, _8767);\n        vec3 param_10 = _8059;\n        vec3 param_11 = _8011;\n        float param_12 = _8066;\n        float param_13 = _8070;\n        vec3 param_14 = _8106;\n        FaLayers _8122 = fa_layers_setup(param_8, param_9, param_10, param_11, param_12, param_13, param_14);\n        f0 = param_14;\n        vec3 param_15 = _8059;\n        vec3 lit = (fa_indirect_diffuse(param_15) * _8099) * _8753;\n        if (_8122.on)\n        {\n            lit *= _8122.base_scale;\n        }\n        int _8144 = fa_cl_ndir + fa_cl_local;\n        for (int ln = 0; ln < _8144; ln++)\n        {\n            int param_16 = ln;\n            int _8157 = fa_cl_light(param_16);\n            int param_17 = _8157;\n            if (fa_baked_keep(param_17) <= 0.0)\n            {\n                continue;\n            }\n            int param_18 = _8157;\n            vec3 param_19 = fa_world_pos;\n            vec3 param_20 = _8717;\n            LightSample _8173 = fa_light_shadowed(param_18, param_19, param_20);\n            float _8181 = max(dot(_8059, _8173.direction), 0.0);\n            float _8187 = _8173.attenuation * _8173.shadow;\n            vec3 _8192 = normalize(_8173.direction + _8011);\n            float _8197 = max(dot(_8059, _8192), 0.0);\n            float _8202 = max(dot(_8011, _8192), 0.0);\n            bool _8209;\n            if (fa_light_is_area)\n            {\n                _8209 = !_8122.on;\n            }\n            else\n            {\n                _8209 = fa_light_is_area;\n            }\n            if (_8209)\n            {\n                int param_21 = _8157;\n                vec3 param_22 = fa_world_pos;\n                vec3 param_23 = _8059;\n                vec3 param_24 = _8011;\n                vec3 param_25 = _8099;\n                vec3 param_26 = f0;\n                float param_27 = 1.0;\n                float param_28 = _8070;\n                float param_29 = _8083;\n                float param_30 = _8187;\n                lit += fa_area_shade(param_21, param_22, param_23, param_24, param_25, param_26, param_27, param_28, param_29, param_30);\n            }\n            else\n            {\n                if (fa_light_is_area)\n                {\n                    FaLayers param_31 = _8122;\n                    int param_32 = _8157;\n                    vec3 param_33 = fa_world_pos;\n                    vec3 param_34 = _8059;\n                    vec3 param_35 = _8011;\n                    vec3 param_36 = _8173.direction;\n                    vec3 param_37 = _8099;\n                    vec3 param_38 = f0;\n                    float param_39 = _8070;\n                    float param_40 = _8083;\n                    float param_41 = _8187;\n                    lit += fa_area_layers(param_31, param_32, param_33, param_34, param_35, param_36, param_37, param_38, param_39, param_40, param_41);\n                }\n                else\n                {\n                    if (_8122.on)\n                    {\n                        FaLayers param_42 = _8122;\n                        vec3 param_43 = _8099;\n                        vec3 param_44 = f0;\n                        vec3 param_45 = _8059;\n                        vec3 param_46 = _8011;\n                        vec3 param_47 = _8173.direction;\n                        vec3 param_48 = _8192;\n                        float param_49 = _8181;\n                        float param_50 = _8083;\n                        float param_51 = _8197;\n                        float param_52 = _8202;\n                        float param_53 = _8074;\n                        float param_54 = _8078;\n                        int param_55 = _8157;\n                        lit += (fa_layers_light(param_42, param_43, param_44, param_45, param_46, param_47, param_48, param_49, param_50, param_51, param_52, param_53, param_54) * ((fa_light_rgb(param_55) * fa_light_tint) * _8187));\n                    }\n                    else\n                    {\n                        float _8315 = ((_8197 * _8197) * (_8078 - 1.0)) + 1.0;\n                        int param_56 = _8157;\n                        lit += (((_8099 + (((f0 + ((vec3(1.0) - f0) * pow(1.0 - _8202, 5.0))) * (((_8078 / ((3.1415927410125732421875 * _8315) * _8315)) * (0.5 / max(mix((2.0 * _8181) * _8083, _8181 + _8083, _8074), 9.9999997473787516355514526367188e-05))) * 3.1415927410125732421875)) * step(9.9999997473787516355514526367188e-05, _8181))) * (fa_light_rgb(param_56) * fa_light_tint)) * (_8181 * _8187));\n                    }\n                }\n            }\n        }\n        if (_8122.on)\n        {\n            FaLayers param_57 = _8122;\n            vec3 param_58 = _8059;\n            vec3 param_59 = _8011;\n            vec3 param_60 = f0;\n            float param_61 = _8070;\n            float param_62 = _8753;\n            lit += fa_layers_ibl(param_57, param_58, param_59, param_60, param_61, param_62);\n        }\n        else\n        {\n            vec3 param_63 = _8059;\n            vec3 param_64 = _8011;\n            vec3 param_65 = f0;\n            float param_66 = _8070;\n            lit += (fa_sky_reflection(param_63, param_64, param_65, param_66) * _8753);\n        }\n        if (_8090 > 0.0)\n        {\n            float _8413;\n            if (_8122.on)\n            {\n                _8413 = _8122.f90;\n            }\n            else\n            {\n                _8413 = 1.0;\n            }\n            float _8421;\n            if (_8122.on)\n            {\n                _8421 = _8122.base_scale;\n            }\n            else\n            {\n                _8421 = 1.0;\n            }\n            Surface param_67 = Surface(_8748, _8749, _8750, _8751, _8752, _8753, _8754, _8755, _8756, _8757, _8758, _8759, _8760, _8761, _8762, _8763, _8764, _8765, _8766, _8767);\n            vec3 param_68 = _8059;\n            vec3 param_69 = _8011;\n            float param_70 = _8070;\n            vec3 param_71 = f0;\n            float param_72 = _8413;\n            float param_73 = _8421;\n            float param_74 = _8090;\n            float param_75 = fa_tr_blend;\n            vec3 _8445 = fa_transmitted(param_67, param_68, param_69, param_70, param_71, param_72, param_73, param_74, param_75);\n            fa_tr_blend = param_75;\n            lit += _8445;\n        }\n        result = lit;\n    }\n    vec3 _8452 = result;\n    vec3 _8453 = _8452 + _8754;\n    result = _8453;\n    vec3 param_76 = _8453;\n    vec3 param_77 = fa_world_pos;\n    result = fa_shadow_debug(param_76, param_77);\n    bool _8462 = fa_mesh_fs_params[7].w > 0.0;\n    bool _8469;\n    if (!_8462)\n    {\n        _8469 = fa_mesh_fs_params[8].y > 0.0;\n    }\n    else\n    {\n        _8469 = _8462;\n    }\n    if (_8469)\n    {\n        vec3 _8478 = fa_world_pos - fa_mesh_fs_params[0].xyz;\n        float _8484 = dot(_8478, fa_mesh_fs_params[9].xyz);\n        bool _8488 = fa_mesh_fs_params[9].w > 0.5;\n        float _8489;\n        if (_8488)\n        {\n            _8489 = _8484;\n        }\n        else\n        {\n            _8489 = length(_8478);\n        }\n        float _8501 = _8489 - fa_mesh_fs_params[8].x;\n        if (_8501 > 0.0)\n        {\n            float _8510 = fa_mesh_fs_params[7].w * _8501;\n            float tau = _8510 * _8510;\n            if (fa_mesh_fs_params[8].y > 0.0)\n            {\n                float _8526;\n                if (_8488)\n                {\n                    _8526 = fa_world_pos.y - (fa_mesh_fs_params[9].y * _8484);\n                }\n                else\n                {\n                    _8526 = fa_mesh_fs_params[0].y;\n                }\n                float _8547 = mix(_8526, fa_world_pos.y, clamp(fa_mesh_fs_params[8].x / _8489, 0.0, 1.0));\n                float _8551 = fa_world_pos.y - _8547;\n                float _8556 = _8547 - fa_mesh_fs_params[8].z;\n                float _8561 = fa_world_pos.y - fa_mesh_fs_params[8].z;\n                bool _8564 = _8556 <= 0.0;\n                bool _8565 = !_8564;\n                bool _8571;\n                if (_8565)\n                {\n                    _8571 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _8571 = _8564;\n                }\n                float _8572;\n                if (_8571)\n                {\n                    _8572 = fa_mesh_fs_params[8].y;\n                }\n                else\n                {\n                    _8572 = fa_mesh_fs_params[8].y * exp(-min(fa_mesh_fs_params[8].w * _8556, 80.0));\n                }\n                bool _8599;\n                if (_8565)\n                {\n                    _8599 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _8599 = _8564;\n                }\n                float _8600;\n                if (_8599)\n                {\n                    _8600 = fa_mesh_fs_params[8].y * _8556;\n                }\n                else\n                {\n                    _8600 = (fa_mesh_fs_params[8].y * (1.0 - exp(-min(fa_mesh_fs_params[8].w * _8556, 80.0)))) / fa_mesh_fs_params[8].w;\n                }\n                bool _8625 = _8561 <= 0.0;\n                bool _8632;\n                if (!_8625)\n                {\n                    _8632 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _8632 = _8625;\n                }\n                float _8633;\n                if (_8632)\n                {\n                    _8633 = fa_mesh_fs_params[8].y * _8561;\n                }\n                else\n                {\n                    _8633 = (fa_mesh_fs_params[8].y * (1.0 - exp(-min(fa_mesh_fs_params[8].w * _8561, 80.0)))) / fa_mesh_fs_params[8].w;\n                }\n                float _8660;\n                if (abs(_8551) < 0.001000000047497451305389404296875)\n                {\n                    _8660 = _8572;\n                }\n                else\n                {\n                    _8660 = (_8633 - _8600) / _8551;\n                }\n                tau += (_8501 * max(_8660, 0.0));\n            }\n            result = mix(result, fa_mesh_fs_params[7].xyz, vec3(clamp(1.0 - exp(-clamp(tau, 0.0, 80.0)), 0.0, 1.0)));\n        }\n    }\n    if (fa_tr_blend > 0.0)\n    {\n        float _8696 = 1.0 - fa_tr_blend;\n        result /= vec3(_8696);\n        _8749 *= _8696;\n    }\n    fa_frag_color = vec4(result, _8749);\n}\n\n",
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
            "size": 848,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_659",
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
            "inst_name": "_2321",
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
            "inst_name": "_6945",
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
              "name": "fa_probe_atlas",
              "multisampled": false,
              "type": "2d",
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
      "vs": "#version 430\n\nstruct VertexData\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 color;\n    vec3 object_pos;\n};\n\nuniform vec4 fa_mesh_vs_params[11];\nlayout(location = 2) out vec3 fa_world_pos;\nlayout(location = 3) out vec3 fa_world_normal;\nlayout(location = 4) out vec4 fa_world_tangent;\nlayout(location = 5) out vec2 fa_uv;\nlayout(location = 6) out vec4 fa_vertex_color;\nlayout(location = 7) out float fa_pre_depth;\nlayout(location = 8) out vec3 fa_pre_r0;\nlayout(location = 9) out vec3 fa_pre_r1;\nlayout(location = 10) out vec3 fa_pre_r2;\nlayout(location = 9) in vec4 fa_inst_d0;\nlayout(location = 10) in vec4 fa_inst_d1;\nlayout(location = 0) flat out vec4 fa_inst_v0;\nlayout(location = 1) flat out vec4 fa_inst_v1;\nlayout(location = 5) in vec4 fa_inst_m0;\nlayout(location = 6) in vec4 fa_inst_m1;\nlayout(location = 7) in vec4 fa_inst_m2;\nlayout(location = 8) in vec4 fa_inst_m3;\nlayout(location = 0) in vec3 fa_position;\nlayout(location = 1) in vec3 fa_normal;\nlayout(location = 3) in vec4 fa_tangent;\nlayout(location = 2) in vec2 fa_texcoord0;\nlayout(location = 4) in vec4 fa_color;\nfloat raise;\nvec4 tint;\n\nvoid fa_instance_unpack(vec4 fa_d0, vec4 fa_d1, vec4 fa_d2)\n{\n    raise = fa_d0.x;\n    tint = fa_d1;\n}\n\nvoid fa_inst_begin()\n{\n    vec4 param = fa_inst_d0;\n    vec4 param_1 = fa_inst_d1;\n    vec4 param_2 = vec4(0.0);\n    fa_instance_unpack(param, param_1, param_2);\n    fa_inst_v0 = fa_inst_d0;\n    fa_inst_v1 = fa_inst_d1;\n}\n\nVertexData fa_vertex_data(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    vec3 _94 = cross(model[1].xyz, model[2].xyz);\n    float _100 = (dot(model[0].xyz, _94) < 0.0) ? (-1.0) : 1.0;\n    return VertexData((model * vec4(position, 1.0)).xyz, (((_94 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _100, vec4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _100), texcoord0 * fa_mesh_vs_params[8].xy, color, position);\n}\n\nvoid vertex(inout VertexData v)\n{\n    v.world_pos.y += raise;\n}\n\nvoid fa_prepass_vertex(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    mat4 param = model;\n    vec3 param_1 = position;\n    vec3 param_2 = normal;\n    vec4 param_3 = tangent;\n    vec2 param_4 = texcoord0;\n    vec4 param_5 = color;\n    VertexData param_6 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    vertex(param_6);\n    mat4 _190 = mat4(fa_mesh_vs_params[4], fa_mesh_vs_params[5], fa_mesh_vs_params[6], fa_mesh_vs_params[7]);\n    vec4 _197 = vec4(param_6.world_pos, 1.0);\n    fa_world_pos = param_6.world_pos;\n    fa_world_normal = param_6.world_normal;\n    fa_world_tangent = param_6.world_tangent;\n    fa_uv = param_6.uv;\n    fa_vertex_color = param_6.color;\n    fa_pre_depth = -(_190 * _197).z;\n    fa_pre_r0 = vec3(_190[0].x, _190[1].x, _190[2].x);\n    fa_pre_r1 = vec3(_190[0].y, _190[1].y, _190[2].y);\n    fa_pre_r2 = vec3(_190[0].z, _190[1].z, _190[2].z);\n    gl_Position = mat4(fa_mesh_vs_params[0], fa_mesh_vs_params[1], fa_mesh_vs_params[2], fa_mesh_vs_params[3]) * _197;\n}\n\nvoid main()\n{\n    fa_inst_begin();\n    mat4 param = mat4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3);\n    vec3 param_1 = fa_position;\n    vec3 param_2 = fa_normal;\n    vec4 param_3 = fa_tangent;\n    vec2 param_4 = fa_texcoord0;\n    vec4 param_5 = fa_color;\n    fa_prepass_vertex(param, param_1, param_2, param_3, param_4, param_5);\n}\n\n",
      "fs": "#version 430\n\nstruct SurfaceInput\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 vertex_color;\n    vec3 view_dir;\n    bool front_facing;\n};\n\nstruct Surface\n{\n    vec3 albedo;\n    float alpha;\n    vec3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    vec3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    vec3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    vec3 specular_color;\n    float transmission;\n    float thickness;\n    vec3 attenuation_color;\n    float attenuation_distance;\n};\n\nuniform vec4 fa_material[1];\nuniform vec4 fa_mesh_fs_params[53];\nlayout(binding = 0) uniform sampler2D fa_tex_fa_smp;\nlayout(binding = 1) uniform sampler2D fa_normal_tex_fa_smp;\nlayout(binding = 2) uniform sampler2D fa_mr_tex_fa_smp;\nlayout(binding = 3) uniform sampler2D fa_occlusion_tex_fa_smp;\nlayout(binding = 4) uniform sampler2D fa_emissive_tex_fa_smp;\n\nlayout(location = 0) flat in vec4 fa_inst_v0;\nlayout(location = 1) flat in vec4 fa_inst_v1;\nlayout(location = 2) in vec3 fa_world_pos;\nlayout(location = 3) in vec3 fa_world_normal;\nlayout(location = 4) in vec4 fa_world_tangent;\nlayout(location = 5) in vec2 fa_uv;\nlayout(location = 6) in vec4 fa_vertex_color;\nlayout(location = 8) in vec3 fa_pre_r0;\nlayout(location = 9) in vec3 fa_pre_r1;\nlayout(location = 10) in vec3 fa_pre_r2;\nlayout(location = 0) out vec4 fa_frag_color;\nlayout(location = 7) in float fa_pre_depth;\nfloat raise;\nvec4 tint;\n\nvoid fa_instance_unpack(vec4 fa_d0, vec4 fa_d1, vec4 fa_d2)\n{\n    raise = fa_d0.x;\n    tint = fa_d1;\n}\n\nvoid fa_inst_load()\n{\n    vec4 param = fa_inst_v0;\n    vec4 param_1 = fa_inst_v1;\n    vec4 param_2 = vec4(0.0);\n    fa_instance_unpack(param, param_1, param_2);\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nvec3 fa_linear_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_tex_fix(inout vec3 c, float mode)\n{\n    if (mode > 1.5)\n    {\n        vec3 param = c;\n        vec3 _212 = fa_linear_to_srgb(param);\n        c = _212;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            vec3 param_1 = c;\n            vec3 _221 = fa_srgb_to_linear(param_1);\n            c = _221;\n        }\n    }\n    return c;\n}\n\nvec3 fa_tangent_normal(SurfaceInput i, vec3 m)\n{\n    vec3 _63;\n    if (i.front_facing)\n    {\n        _63 = i.world_normal;\n    }\n    else\n    {\n        _63 = -i.world_normal;\n    }\n    vec3 _87 = normalize(i.world_tangent.xyz - (_63 * dot(_63, i.world_tangent.xyz)));\n    vec3 _115 = normalize(((_87 * m.x) + ((cross(_63, _87) * i.world_tangent.w) * m.y)) + (_63 * m.z));\n    vec3 _118;\n    if (i.front_facing)\n    {\n        _118 = _115;\n    }\n    else\n    {\n        _118 = -_115;\n    }\n    return _118;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    vec4 base_t = texture(fa_tex_fa_smp, i.uv);\n    float param = fa_mesh_fs_params[6].w;\n    float param_1 = 1.0;\n    vec3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    vec3 _266 = fa_tex_fix(param_2, param_3);\n    vec4 _815 = base_t;\n    _815.x = _266.x;\n    _815.y = _266.y;\n    _815.z = _266.z;\n    base_t = _815;\n    vec4 _282 = (_815 * fa_mesh_fs_params[2]) * i.vertex_color;\n    vec3 _770 = i.world_normal;\n    if (fa_mesh_fs_params[6].z > 0.5)\n    {\n        float param_4 = fa_mesh_fs_params[6].w;\n        float param_5 = 16.0;\n        vec3 param_6 = texture(fa_normal_tex_fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        vec3 _315 = fa_tex_fix(param_6, param_7);\n        vec3 _319 = (_315 * 2.0) - vec3(1.0);\n        vec2 _324 = _319.xy * fa_mesh_fs_params[6].x;\n        vec3 _823 = _319;\n        _823.x = _324.x;\n        _823.y = _324.y;\n        SurfaceInput param_8 = i;\n        vec3 param_9 = _823;\n        _770 = fa_tangent_normal(param_8, param_9);\n    }\n    vec4 mrt = texture(fa_mr_tex_fa_smp, i.uv);\n    float param_10 = fa_mesh_fs_params[6].w;\n    float param_11 = 64.0;\n    vec3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    vec3 _353 = fa_tex_fix(param_12, param_13);\n    vec4 _826 = mrt;\n    _826.x = _353.x;\n    _826.y = _353.y;\n    _826.z = _353.z;\n    mrt = _826;\n    vec4 _383 = texture(fa_occlusion_tex_fa_smp, i.uv);\n    float param_14 = fa_mesh_fs_params[6].w;\n    float param_15 = 256.0;\n    vec3 param_16 = _383.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    vec3 _395 = fa_tex_fix(param_16, param_17);\n    float param_18 = fa_mesh_fs_params[6].w;\n    float param_19 = 4.0;\n    vec3 param_20 = texture(fa_emissive_tex_fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    vec3 _425 = fa_tex_fix(param_20, param_21);\n    float _775 = fa_mesh_fs_params[20].x;\n    float _776 = fa_mesh_fs_params[20].y;\n    float _779 = fa_mesh_fs_params[20].z;\n    float _778 = fa_mesh_fs_params[21].w;\n    float _781 = fa_mesh_fs_params[22].x;\n    if (fa_mesh_fs_params[22].z > 0.5)\n    {\n        if (mod(fa_mesh_fs_params[22].z, 2.0) > 0.5)\n        {\n            _775 *= _395.y;\n            _776 *= _395.z;\n            _778 *= _383.w;\n        }\n        if (fa_mesh_fs_params[22].z > 1.5)\n        {\n            _779 *= mrt.x;\n            _781 *= mrt.w;\n        }\n    }\n    return Surface(_282.xyz, _282.w, _770, clamp(fa_mesh_fs_params[5].x * _353.z, 0.0, 1.0), clamp(fa_mesh_fs_params[5].y * _353.y, 0.0500000007450580596923828125, 1.0), 1.0 + (fa_mesh_fs_params[6].y * (_395.x - 1.0)), fa_mesh_fs_params[3].xyz + (fa_mesh_fs_params[4].xyz * _425), _775, _776, fa_mesh_fs_params[21].xyz, _778, _779, fa_mesh_fs_params[20].w, _781, fa_mesh_fs_params[22].y, fa_mesh_fs_params[23].xyz, fa_mesh_fs_params[30].x, fa_mesh_fs_params[30].y, fa_mesh_fs_params[31].xyz, fa_mesh_fs_params[30].z);\n}\n\nvoid surface(SurfaceInput i, inout Surface s)\n{\n    s.emission += ((tint.xyz * tint.w) * fa_material[0].x);\n}\n\nvoid main()\n{\n    fa_inst_load();\n    vec3 _665 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _665 = -_665;\n    }\n    vec3 _577 = normalize(fa_mesh_fs_params[0].xyz - fa_world_pos);\n    SurfaceInput param = SurfaceInput(fa_world_pos, _665, fa_world_tangent, fa_uv, fa_vertex_color, _577, gl_FrontFacing);\n    SurfaceInput param_1 = SurfaceInput(fa_world_pos, _665, fa_world_tangent, fa_uv, fa_vertex_color, _577, gl_FrontFacing);\n    Surface param_2 = fa_standard_surface(param);\n    surface(param_1, param_2);\n    vec3 _592 = normalize(param_2.normal);\n    vec3 _607 = normalize(vec3(dot(fa_pre_r0, _592), dot(fa_pre_r1, _592), dot(fa_pre_r2, _592)));\n    float _619 = _607.z;\n    vec2 e = _607.xy / vec2((abs(_607.x) + abs(_607.y)) + abs(_619));\n    if (_619 < 0.0)\n    {\n        e = (vec2(1.0) - abs(e.yx)) * vec2((e.x >= 0.0) ? 1.0 : (-1.0), (e.y >= 0.0) ? 1.0 : (-1.0));\n    }\n    fa_frag_color = vec4(min(fa_pre_depth, 60000.0), e, 1.0);\n}\n\n",
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
            "size": 848,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_255",
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
      "fs": "#version 430\n\nstruct SurfaceInput\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 vertex_color;\n    vec3 view_dir;\n    bool front_facing;\n};\n\nstruct Surface\n{\n    vec3 albedo;\n    float alpha;\n    vec3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    vec3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    vec3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    vec3 specular_color;\n    float transmission;\n    float thickness;\n    vec3 attenuation_color;\n    float attenuation_distance;\n};\n\nuniform vec4 fa_material[1];\nuniform vec4 fa_mesh_fs_params[53];\nlayout(binding = 0) uniform sampler2D fa_tex_fa_smp;\nlayout(binding = 1) uniform sampler2D fa_normal_tex_fa_smp;\nlayout(binding = 2) uniform sampler2D fa_mr_tex_fa_smp;\nlayout(binding = 3) uniform sampler2D fa_occlusion_tex_fa_smp;\nlayout(binding = 4) uniform sampler2D fa_emissive_tex_fa_smp;\n\nlayout(location = 0) flat in vec4 fa_inst_v0;\nlayout(location = 1) flat in vec4 fa_inst_v1;\nlayout(location = 2) in vec3 fa_world_pos;\nlayout(location = 3) in vec3 fa_world_normal;\nlayout(location = 4) in vec4 fa_world_tangent;\nlayout(location = 5) in vec2 fa_uv;\nlayout(location = 6) in vec4 fa_vertex_color;\nlayout(location = 8) in vec3 fa_pre_r0;\nlayout(location = 9) in vec3 fa_pre_r1;\nlayout(location = 10) in vec3 fa_pre_r2;\nlayout(location = 0) out vec4 fa_frag_color;\nlayout(location = 7) in float fa_pre_depth;\nfloat raise;\nvec4 tint;\n\nvoid fa_instance_unpack(vec4 fa_d0, vec4 fa_d1, vec4 fa_d2)\n{\n    raise = fa_d0.x;\n    tint = fa_d1;\n}\n\nvoid fa_inst_load()\n{\n    vec4 param = fa_inst_v0;\n    vec4 param_1 = fa_inst_v1;\n    vec4 param_2 = vec4(0.0);\n    fa_instance_unpack(param, param_1, param_2);\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nvec3 fa_linear_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_tex_fix(inout vec3 c, float mode)\n{\n    if (mode > 1.5)\n    {\n        vec3 param = c;\n        vec3 _212 = fa_linear_to_srgb(param);\n        c = _212;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            vec3 param_1 = c;\n            vec3 _221 = fa_srgb_to_linear(param_1);\n            c = _221;\n        }\n    }\n    return c;\n}\n\nvec3 fa_tangent_normal(SurfaceInput i, vec3 m)\n{\n    vec3 _63;\n    if (i.front_facing)\n    {\n        _63 = i.world_normal;\n    }\n    else\n    {\n        _63 = -i.world_normal;\n    }\n    vec3 _87 = normalize(i.world_tangent.xyz - (_63 * dot(_63, i.world_tangent.xyz)));\n    vec3 _115 = normalize(((_87 * m.x) + ((cross(_63, _87) * i.world_tangent.w) * m.y)) + (_63 * m.z));\n    vec3 _118;\n    if (i.front_facing)\n    {\n        _118 = _115;\n    }\n    else\n    {\n        _118 = -_115;\n    }\n    return _118;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    vec4 base_t = texture(fa_tex_fa_smp, i.uv);\n    float param = fa_mesh_fs_params[6].w;\n    float param_1 = 1.0;\n    vec3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    vec3 _266 = fa_tex_fix(param_2, param_3);\n    vec4 _815 = base_t;\n    _815.x = _266.x;\n    _815.y = _266.y;\n    _815.z = _266.z;\n    base_t = _815;\n    vec4 _282 = (_815 * fa_mesh_fs_params[2]) * i.vertex_color;\n    vec3 _770 = i.world_normal;\n    if (fa_mesh_fs_params[6].z > 0.5)\n    {\n        float param_4 = fa_mesh_fs_params[6].w;\n        float param_5 = 16.0;\n        vec3 param_6 = texture(fa_normal_tex_fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        vec3 _315 = fa_tex_fix(param_6, param_7);\n        vec3 _319 = (_315 * 2.0) - vec3(1.0);\n        vec2 _324 = _319.xy * fa_mesh_fs_params[6].x;\n        vec3 _823 = _319;\n        _823.x = _324.x;\n        _823.y = _324.y;\n        SurfaceInput param_8 = i;\n        vec3 param_9 = _823;\n        _770 = fa_tangent_normal(param_8, param_9);\n    }\n    vec4 mrt = texture(fa_mr_tex_fa_smp, i.uv);\n    float param_10 = fa_mesh_fs_params[6].w;\n    float param_11 = 64.0;\n    vec3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    vec3 _353 = fa_tex_fix(param_12, param_13);\n    vec4 _826 = mrt;\n    _826.x = _353.x;\n    _826.y = _353.y;\n    _826.z = _353.z;\n    mrt = _826;\n    vec4 _383 = texture(fa_occlusion_tex_fa_smp, i.uv);\n    float param_14 = fa_mesh_fs_params[6].w;\n    float param_15 = 256.0;\n    vec3 param_16 = _383.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    vec3 _395 = fa_tex_fix(param_16, param_17);\n    float param_18 = fa_mesh_fs_params[6].w;\n    float param_19 = 4.0;\n    vec3 param_20 = texture(fa_emissive_tex_fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    vec3 _425 = fa_tex_fix(param_20, param_21);\n    float _775 = fa_mesh_fs_params[20].x;\n    float _776 = fa_mesh_fs_params[20].y;\n    float _779 = fa_mesh_fs_params[20].z;\n    float _778 = fa_mesh_fs_params[21].w;\n    float _781 = fa_mesh_fs_params[22].x;\n    if (fa_mesh_fs_params[22].z > 0.5)\n    {\n        if (mod(fa_mesh_fs_params[22].z, 2.0) > 0.5)\n        {\n            _775 *= _395.y;\n            _776 *= _395.z;\n            _778 *= _383.w;\n        }\n        if (fa_mesh_fs_params[22].z > 1.5)\n        {\n            _779 *= mrt.x;\n            _781 *= mrt.w;\n        }\n    }\n    return Surface(_282.xyz, _282.w, _770, clamp(fa_mesh_fs_params[5].x * _353.z, 0.0, 1.0), clamp(fa_mesh_fs_params[5].y * _353.y, 0.0500000007450580596923828125, 1.0), 1.0 + (fa_mesh_fs_params[6].y * (_395.x - 1.0)), fa_mesh_fs_params[3].xyz + (fa_mesh_fs_params[4].xyz * _425), _775, _776, fa_mesh_fs_params[21].xyz, _778, _779, fa_mesh_fs_params[20].w, _781, fa_mesh_fs_params[22].y, fa_mesh_fs_params[23].xyz, fa_mesh_fs_params[30].x, fa_mesh_fs_params[30].y, fa_mesh_fs_params[31].xyz, fa_mesh_fs_params[30].z);\n}\n\nvoid surface(SurfaceInput i, inout Surface s)\n{\n    s.emission += ((tint.xyz * tint.w) * fa_material[0].x);\n}\n\nvoid main()\n{\n    fa_inst_load();\n    vec3 _665 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _665 = -_665;\n    }\n    vec3 _577 = normalize(fa_mesh_fs_params[0].xyz - fa_world_pos);\n    SurfaceInput param = SurfaceInput(fa_world_pos, _665, fa_world_tangent, fa_uv, fa_vertex_color, _577, gl_FrontFacing);\n    SurfaceInput param_1 = SurfaceInput(fa_world_pos, _665, fa_world_tangent, fa_uv, fa_vertex_color, _577, gl_FrontFacing);\n    Surface param_2 = fa_standard_surface(param);\n    surface(param_1, param_2);\n    vec3 _592 = normalize(param_2.normal);\n    vec3 _607 = normalize(vec3(dot(fa_pre_r0, _592), dot(fa_pre_r1, _592), dot(fa_pre_r2, _592)));\n    float _619 = _607.z;\n    vec2 e = _607.xy / vec2((abs(_607.x) + abs(_607.y)) + abs(_619));\n    if (_619 < 0.0)\n    {\n        e = (vec2(1.0) - abs(e.yx)) * vec2((e.x >= 0.0) ? 1.0 : (-1.0), (e.y >= 0.0) ? 1.0 : (-1.0));\n    }\n    fa_frag_color = vec4(min(fa_pre_depth, 60000.0), e, 1.0);\n}\n\n",
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
            "size": 848,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_255",
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
