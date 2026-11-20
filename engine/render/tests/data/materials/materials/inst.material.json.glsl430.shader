{
  "format": "factoria.shader/1",
  "engine": "0.32.0",
  "template": "c074417cc32d65946d9fd800b8e1855ea5fc09e97e16038fe5558a6cb62d2704",
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
      "fs": "#version 430\n\nstruct SurfaceInput\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 vertex_color;\n    vec3 view_dir;\n    bool front_facing;\n};\n\nstruct LightSample\n{\n    vec3 direction;\n    vec3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct Surface\n{\n    vec3 albedo;\n    float alpha;\n    vec3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    vec3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    vec3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    vec3 specular_color;\n    float transmission;\n    float thickness;\n    vec3 attenuation_color;\n    float attenuation_distance;\n};\n\nstruct FaLayers\n{\n    bool on;\n    float f90;\n    float keep;\n    float base_scale;\n    float coat;\n    float coat_rough;\n    float coat_alpha;\n    float coat_a2;\n    vec3 nc;\n    float coat_ndv;\n    bool sheen_on;\n    vec3 sheen;\n    float sheen_rough;\n    float sheen_alpha;\n    float sheen_scale;\n    float sheen_e;\n    float aniso;\n    vec3 t;\n    vec3 b;\n    float at;\n    float ab;\n};\n\nconst float _4326[63] = float[](1.0, 1.0, 1.0, 0.4790000021457672119140625, 0.11699999868869781494140625, 0.01200000010430812835693359375, 0.0, 0.0, 0.0, 1.0, 1.0, 1.0, 0.578000009059906005859375, 0.19300000369548797607421875, 0.0350000001490116119384765625, 0.0030000000260770320892333984375, 0.0, 0.0, 1.0, 1.0, 1.0, 0.6740000247955322265625, 0.3459999859333038330078125, 0.1319999992847442626953125, 0.032999999821186065673828125, 0.0040000001899898052215576171875, 0.0, 0.971000015735626220703125, 0.954999983310699462890625, 0.828999996185302734375, 0.63999998569488525390625, 0.42599999904632568359375, 0.24500000476837158203125, 0.115000002086162567138671875, 0.037000000476837158203125, 0.0030000000260770320892333984375, 0.7469999790191650390625, 0.737999975681304931640625, 0.670000016689300537109375, 0.563000023365020751953125, 0.4309999942779541015625, 0.3039999902248382568359375, 0.1940000057220458984375, 0.1019999980926513671875, 0.0309999994933605194091796875, 0.614000022411346435546875, 0.609000027179718017578125, 0.566999971866607666015625, 0.499000012874603271484375, 0.412000000476837158203125, 0.32400000095367431640625, 0.240999996662139892578125, 0.162000000476837158203125, 0.087999999523162841796875, 0.538999974727630615234375, 0.535000026226043701171875, 0.505999982357025146484375, 0.4569999873638153076171875, 0.393999993801116943359375, 0.328999996185302734375, 0.2660000026226043701171875, 0.203999996185302734375, 0.14200000464916229248046875);\n\nuniform vec4 fa_mesh_fs_params[52];\nuniform vec4 fa_shadows[30];\nuniform vec4 fa_material[1];\nlayout(binding = 0) uniform sampler2D fa_light_tex_fa_shadow_smp;\nlayout(binding = 1) uniform sampler2D fa_tex_fa_smp;\nlayout(binding = 2) uniform sampler2D fa_normal_tex_fa_smp;\nlayout(binding = 3) uniform sampler2D fa_mr_tex_fa_smp;\nlayout(binding = 4) uniform sampler2D fa_occlusion_tex_fa_smp;\nlayout(binding = 5) uniform sampler2D fa_emissive_tex_fa_smp;\nlayout(binding = 6) uniform sampler2D fa_decal_tex_fa_env_smp;\nlayout(binding = 7) uniform sampler2D fa_lightmap_fa_env_smp;\nlayout(binding = 8) uniform sampler2D fa_probe_atlas_fa_env_smp;\nlayout(binding = 9) uniform sampler2D fa_light_atlas_fa_env_smp;\nlayout(binding = 10) uniform sampler2D fa_shadow_tex_fa_shadow_smp;\nlayout(binding = 11) uniform sampler2D fa_screen_tex_fa_shadow_smp;\n\nlayout(location = 2) in vec3 fa_world_pos;\nlayout(location = 7) in vec3 fa_lm;\nlayout(location = 0) flat in vec4 fa_inst_v0;\nlayout(location = 1) flat in vec4 fa_inst_v1;\nlayout(location = 3) in vec3 fa_world_normal;\nlayout(location = 4) in vec4 fa_world_tangent;\nlayout(location = 5) in vec2 fa_uv;\nlayout(location = 6) in vec4 fa_vertex_color;\nlayout(location = 0) out vec4 fa_frag_color;\nvec3 fa_light_tint;\nbool fa_light_is_area;\nint fa_cl_ndir;\nint fa_cl_slot;\nint fa_cl_local;\nfloat raise;\nvec4 tint;\n\nvoid fa_instance_unpack(vec4 fa_d0, vec4 fa_d1, vec4 fa_d2)\n{\n    raise = fa_d0.x;\n    tint = fa_d1;\n}\n\nvoid fa_inst_load()\n{\n    vec4 param = fa_inst_v0;\n    vec4 param_1 = fa_inst_v1;\n    vec4 param_2 = vec4(0.0);\n    fa_instance_unpack(param, param_1, param_2);\n}\n\nvec4 fa_light_texel(int t)\n{\n    return texelFetch(fa_light_tex_fa_shadow_smp, ivec2(t & 1023, t >> 10), 0);\n}\n\nvec4 fa_cluster_texel(vec3 world_pos)\n{\n    bool _1581 = fa_mesh_fs_params[19].x < 0.0;\n    bool _1588;\n    if (!_1581)\n    {\n        _1588 = fa_mesh_fs_params[19].w < 1.0;\n    }\n    else\n    {\n        _1588 = _1581;\n    }\n    bool _1596;\n    if (!_1588)\n    {\n        _1596 = fa_mesh_fs_params[18].x < 1.0;\n    }\n    else\n    {\n        _1596 = _1588;\n    }\n    bool _1603;\n    if (!_1596)\n    {\n        _1603 = fa_mesh_fs_params[18].y < 1.0;\n    }\n    else\n    {\n        _1603 = _1596;\n    }\n    bool _1610;\n    if (!_1603)\n    {\n        _1610 = fa_mesh_fs_params[19].y < 1.0;\n    }\n    else\n    {\n        _1610 = _1603;\n    }\n    if (_1610)\n    {\n        return vec4(0.0);\n    }\n    vec4 _1620 = vec4(world_pos, 1.0);\n    float _1626 = dot(fa_mesh_fs_params[16], _1620);\n    if (!(_1626 > 9.9999999747524270787835121154785e-07))\n    {\n        return vec4(0.0);\n    }\n    vec2 _1648 = vec2(dot(fa_mesh_fs_params[14], _1620), dot(fa_mesh_fs_params[15], _1620)) / vec2(_1626);\n    int _1652 = int(fa_mesh_fs_params[18].x);\n    int _1656 = int(fa_mesh_fs_params[18].y);\n    int param = (int(fa_mesh_fs_params[19].x) + (((clamp(int(floor(log2(max(dot(fa_mesh_fs_params[17].xyz, world_pos) + fa_mesh_fs_params[17].w, fa_mesh_fs_params[18].w) / fa_mesh_fs_params[18].w) * fa_mesh_fs_params[18].z)), 0, int(fa_mesh_fs_params[19].y) - 1) * _1656) + clamp(int(floor(((_1648.y * 0.5) + 0.5) * fa_mesh_fs_params[18].y)), 0, _1656 - 1)) * _1652)) + clamp(int(floor(((_1648.x * 0.5) + 0.5) * fa_mesh_fs_params[18].x)), 0, _1652 - 1);\n    return fa_light_texel(param);\n}\n\nivec2 fa_cluster_lookup(vec3 world_pos)\n{\n    vec3 param = world_pos;\n    vec4 _1732 = fa_cluster_texel(param);\n    return ivec2(int(_1732.x), int(_1732.y));\n}\n\nvoid fa_cluster_begin(vec3 world_pos)\n{\n    fa_cl_ndir = int(fa_mesh_fs_params[19].z);\n    vec3 param = world_pos;\n    ivec2 _5787 = fa_cluster_lookup(param);\n    fa_cl_slot = _5787.x;\n    fa_cl_local = _5787.y;\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nvec3 fa_linear_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_tex_fix(inout vec3 c, float mode)\n{\n    if (mode > 1.5)\n    {\n        vec3 param = c;\n        vec3 _6950 = fa_linear_to_srgb(param);\n        c = _6950;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            vec3 param_1 = c;\n            vec3 _6958 = fa_srgb_to_linear(param_1);\n            c = _6958;\n        }\n    }\n    return c;\n}\n\nvec3 fa_tangent_normal(SurfaceInput i, vec3 m)\n{\n    vec3 _525;\n    if (i.front_facing)\n    {\n        _525 = i.world_normal;\n    }\n    else\n    {\n        _525 = -i.world_normal;\n    }\n    vec3 _549 = normalize(i.world_tangent.xyz - (_525 * dot(_525, i.world_tangent.xyz)));\n    vec3 _576 = normalize(((_549 * m.x) + ((cross(_525, _549) * i.world_tangent.w) * m.y)) + (_525 * m.z));\n    vec3 _579;\n    if (i.front_facing)\n    {\n        _579 = _576;\n    }\n    else\n    {\n        _579 = -_576;\n    }\n    return _579;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    vec4 base_t = texture(fa_tex_fa_smp, i.uv);\n    float param = fa_mesh_fs_params[6].w;\n    float param_1 = 1.0;\n    vec3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    vec3 _6989 = fa_tex_fix(param_2, param_3);\n    vec4 _8612 = base_t;\n    _8612.x = _6989.x;\n    _8612.y = _6989.y;\n    _8612.z = _6989.z;\n    base_t = _8612;\n    vec4 _7003 = (_8612 * fa_mesh_fs_params[2]) * i.vertex_color;\n    vec3 _8396 = i.world_normal;\n    if (fa_mesh_fs_params[6].z > 0.5)\n    {\n        float param_4 = fa_mesh_fs_params[6].w;\n        float param_5 = 16.0;\n        vec3 param_6 = texture(fa_normal_tex_fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        vec3 _7035 = fa_tex_fix(param_6, param_7);\n        vec3 _7038 = (_7035 * 2.0) - vec3(1.0);\n        vec2 _7043 = _7038.xy * fa_mesh_fs_params[6].x;\n        vec3 _8620 = _7038;\n        _8620.x = _7043.x;\n        _8620.y = _7043.y;\n        SurfaceInput param_8 = i;\n        vec3 param_9 = _8620;\n        _8396 = fa_tangent_normal(param_8, param_9);\n    }\n    vec4 mrt = texture(fa_mr_tex_fa_smp, i.uv);\n    float param_10 = fa_mesh_fs_params[6].w;\n    float param_11 = 64.0;\n    vec3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    vec3 _7071 = fa_tex_fix(param_12, param_13);\n    vec4 _8623 = mrt;\n    _8623.x = _7071.x;\n    _8623.y = _7071.y;\n    _8623.z = _7071.z;\n    mrt = _8623;\n    vec4 _7099 = texture(fa_occlusion_tex_fa_smp, i.uv);\n    float param_14 = fa_mesh_fs_params[6].w;\n    float param_15 = 256.0;\n    vec3 param_16 = _7099.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    vec3 _7110 = fa_tex_fix(param_16, param_17);\n    float param_18 = fa_mesh_fs_params[6].w;\n    float param_19 = 4.0;\n    vec3 param_20 = texture(fa_emissive_tex_fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    vec3 _7140 = fa_tex_fix(param_20, param_21);\n    float _8401 = fa_mesh_fs_params[20].x;\n    float _8402 = fa_mesh_fs_params[20].y;\n    float _8405 = fa_mesh_fs_params[20].z;\n    float _8404 = fa_mesh_fs_params[21].w;\n    float _8407 = fa_mesh_fs_params[22].x;\n    if (fa_mesh_fs_params[22].z > 0.5)\n    {\n        if (mod(fa_mesh_fs_params[22].z, 2.0) > 0.5)\n        {\n            _8401 *= _7110.y;\n            _8402 *= _7110.z;\n            _8404 *= _7099.w;\n        }\n        if (fa_mesh_fs_params[22].z > 1.5)\n        {\n            _8405 *= mrt.x;\n            _8407 *= mrt.w;\n        }\n    }\n    return Surface(_7003.xyz, _7003.w, _8396, clamp(fa_mesh_fs_params[5].x * _7071.z, 0.0, 1.0), clamp(fa_mesh_fs_params[5].y * _7071.y, 0.0500000007450580596923828125, 1.0), 1.0 + (fa_mesh_fs_params[6].y * (_7110.x - 1.0)), fa_mesh_fs_params[3].xyz + (fa_mesh_fs_params[4].xyz * _7140), _8401, _8402, fa_mesh_fs_params[21].xyz, _8404, _8405, fa_mesh_fs_params[20].w, _8407, fa_mesh_fs_params[22].y, fa_mesh_fs_params[23].xyz, fa_mesh_fs_params[30].x, fa_mesh_fs_params[30].y, fa_mesh_fs_params[31].xyz, fa_mesh_fs_params[30].z);\n}\n\nvoid surface(SurfaceInput i, inout Surface s)\n{\n    s.emission += ((tint.xyz * tint.w) * fa_material[0].x);\n}\n\nvec4 fa_decal_tile(vec4 rect, vec2 uv, vec2 atlas, vec2 ddx, vec2 ddy)\n{\n    vec2 _1812 = rect.zw - rect.xy;\n    vec2 _1816 = _1812 * atlas;\n    vec2 _1820 = ddx * _1816;\n    vec2 _1824 = ddy * _1816;\n    return textureLod(fa_decal_tex_fa_env_smp, rect.xy + (clamp(uv, vec2(0.0), vec2(1.0)) * _1812), clamp(0.5 * log2(max(max(dot(_1820, _1820), dot(_1824, _1824)), 9.9999999392252902907785028219223e-09)), 0.0, 4.0));\n}\n\nvec3 fa_dc_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_dc_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvoid fa_apply_decals(vec3 world_pos, vec3 geo_normal, inout vec3 albedo, inout vec3 normal)\n{\n    bool _1857 = fa_mesh_fs_params[10].y < 0.5;\n    bool _1864;\n    if (!_1857)\n    {\n        _1864 = fa_mesh_fs_params[10].w < 0.5;\n    }\n    else\n    {\n        _1864 = _1857;\n    }\n    if (_1864)\n    {\n        return;\n    }\n    vec3 _1870 = dFdx(world_pos);\n    vec3 _1873 = dFdy(world_pos);\n    vec3 param = world_pos;\n    vec4 _1877 = fa_cluster_texel(param);\n    int _1881 = int(_1877.w);\n    if (_1881 < 1)\n    {\n        return;\n    }\n    int _1891 = int(fa_mesh_fs_params[10].y + 0.5);\n    int param_1 = _1891;\n    vec4 _1895 = fa_light_texel(param_1);\n    vec2 _1898 = _1895.yz;\n    int _1902 = int(_1895.w);\n    int param_2 = _1891 + 1;\n    vec4 _1907 = fa_light_texel(param_2);\n    float _1908 = _1907.x;\n    int _1914 = int(fa_mesh_fs_params[10].w + 0.5) - 1;\n    int _1918 = int(_1877.z);\n    vec3 _2183;\n    for (int k = 0; k < _1881; k++)\n    {\n        int _1931 = _1918 + k;\n        int param_3 = _1902 + (_1931 >> 2);\n        int _1948 = (_1891 + 2) + (int(fa_light_texel(param_3)[_1931 & 3]) * 7);\n        int param_4 = _1948 + 6;\n        vec4 _1953 = fa_light_texel(param_4);\n        if (((int(_1953.w + 0.5) >> _1914) & 1) == 0)\n        {\n            continue;\n        }\n        int param_5 = _1948;\n        vec4 _1968 = fa_light_texel(param_5);\n        int param_6 = _1948 + 1;\n        vec4 _1973 = fa_light_texel(param_6);\n        int param_7 = _1948 + 2;\n        vec4 _1978 = fa_light_texel(param_7);\n        vec3 _1981 = _1968.xyz;\n        float _1986 = dot(_1981, world_pos) + _1968.w;\n        vec3 _1988 = _1973.xyz;\n        float _1993 = dot(_1988, world_pos) + _1973.w;\n        vec3 _1995 = _1978.xyz;\n        float _2000 = dot(_1995, world_pos) + _1978.w;\n        bool _2005 = abs(_1986) > 0.5;\n        bool _2013;\n        if (!_2005)\n        {\n            _2013 = abs(_1993) > 0.5;\n        }\n        else\n        {\n            _2013 = _2005;\n        }\n        bool _2021;\n        if (!_2013)\n        {\n            _2021 = abs(_2000) > 0.5;\n        }\n        else\n        {\n            _2021 = _2013;\n        }\n        if (_2021)\n        {\n            continue;\n        }\n        float _2036 = clamp(dot(geo_normal, normalize(_1995)) * _1953.z, 0.0, 1.0);\n        if (_2036 <= 0.0)\n        {\n            continue;\n        }\n        float _2056 = (clamp((0.5 - abs(_2000)) * 10.0, 0.0, 1.0) * _2036) * _1953.x;\n        vec2 _2064 = vec2(_1986 + 0.5, 0.5 - _1993);\n        vec2 _2074 = vec2(dot(_1981, _1870), dot(_1988, _1870));\n        vec2 _2084 = vec2(dot(_1981, _1873), dot(_1988, _1873));\n        int param_8 = _1948 + 5;\n        vec4 _2089 = fa_light_texel(param_8);\n        int param_9 = _1948 + 3;\n        vec4 _2094 = fa_light_texel(param_9);\n        int param_10 = _1948 + 4;\n        vec4 _2099 = fa_light_texel(param_10);\n        float tex_a = 1.0;\n        vec3 col = _2089.xyz;\n        bool _2109 = _2094.z > _2094.x;\n        if (_2109)\n        {\n            vec4 param_11 = _2094;\n            vec2 param_12 = _2064;\n            vec2 param_13 = _1898;\n            vec2 param_14 = _2074;\n            vec2 param_15 = _2084;\n            vec4 tx = fa_decal_tile(param_11, param_12, param_13, param_14, param_15);\n            if ((_1908 > 0.5) && (_1908 < 1.5))\n            {\n                vec3 param_16 = tx.xyz;\n                vec3 _2135 = fa_dc_to_linear(param_16);\n                vec4 _8484 = tx;\n                _8484.x = _2135.x;\n                _8484.y = _2135.y;\n                _8484.z = _2135.z;\n                tx = _8484;\n            }\n            col *= tx.xyz;\n            tex_a = tx.w;\n        }\n        albedo = mix(albedo, col, vec3(clamp((_2056 * tex_a) * _2089.w, 0.0, 1.0)));\n        if (_2099.z > _2099.x)\n        {\n            vec4 param_17 = _2099;\n            vec2 param_18 = _2064;\n            vec2 param_19 = _1898;\n            vec2 param_20 = _2074;\n            vec2 param_21 = _2084;\n            vec4 _2179 = fa_decal_tile(param_17, param_18, param_19, param_20, param_21);\n            if (_1908 > 1.5)\n            {\n                vec3 param_22 = _2179.xyz;\n                vec3 _2189 = fa_dc_to_srgb(param_22);\n                _2183 = _2189;\n            }\n            else\n            {\n                _2183 = _2179.xyz;\n            }\n            vec3 _2198 = (_2183 * 2.0) - vec3(1.0);\n            vec2 _2203 = _2198.xy * _1953.y;\n            vec3 _2225 = (normalize(_1981) * _2203.x) + (normalize(_1988) * _2203.y);\n            vec3 _2228 = normalize(normal);\n            normal = normalize(mix(_2228, normalize((_2228 * max(_2198.z, 0.0500000007450580596923828125)) + (_2225 - (_2228 * dot(_2228, _2225)))), vec3(clamp(_2056 * (_2109 ? tex_a : 1.0), 0.0, 1.0))));\n        }\n    }\n}\n\nfloat fa_sheen_albedo(float ndv, float rough)\n{\n    float _4252 = min(sqrt(max(rough - 0.100000001490116119384765625, 0.0) * 1.111111164093017578125) * 6.0, 5.999000072479248046875);\n    float _4259 = min(sqrt(clamp(ndv, 0.0, 1.0)) * 8.0, 7.999000072479248046875);\n    int _4262 = int(_4252);\n    int _4265 = int(_4259);\n    float _4275 = _4259 - float(_4265);\n    int _4330 = (_4262 * 9) + _4265;\n    int _4350 = ((_4262 + 1) * 9) + _4265;\n    return mix(mix(_4326[_4330], _4326[_4330 + 1], _4275), mix(_4326[_4350], _4326[_4350 + 1], _4275), _4252 - float(_4262));\n}\n\nFaLayers fa_layers_setup(SurfaceInput i, Surface s, vec3 n, vec3 v, float metallic, float roughness, inout vec3 f0)\n{\n    bool _8319 = false;\n    float _8320 = 1.0;\n    float _8321 = 1.0;\n    float _8322 = 1.0;\n    float _8323 = 0.0;\n    float _8324 = 0.0;\n    float _8325 = 0.0;\n    float _8326 = 0.0;\n    float _8328 = 1.0;\n    bool _8329 = false;\n    vec3 _8330 = vec3(0.0);\n    float _8331 = 1.0;\n    float _8332 = 1.0;\n    float _8333 = 1.0;\n    float _8334 = 0.0;\n    float _8335 = 0.0;\n    vec3 _8336 = vec3(1.0, 0.0, 0.0);\n    vec3 _8337 = vec3(0.0, 0.0, 1.0);\n    float _8338 = 1.0;\n    float _8339 = 1.0;\n    float _4401 = clamp(s.specular, 0.0, 1.0);\n    float _4405 = clamp(s.ior, 1.0, 3.0);\n    bool _4410 = (_4401 != 1.0) || (_4405 != 1.5);\n    bool _4419;\n    if (!_4410)\n    {\n        _4419 = any(notEqual(s.specular_color, vec3(1.0)));\n    }\n    else\n    {\n        _4419 = _4410;\n    }\n    if (_4419)\n    {\n        float _4427 = (_4405 - 1.0) / (_4405 + 1.0);\n        f0 = mix(min(vec3(_4427 * _4427) * max(s.specular_color, vec3(0.0)), vec3(1.0)) * _4401, s.albedo, vec3(metallic));\n        _8320 = mix(_4401, 1.0, metallic);\n        _8319 = true;\n    }\n    float _4454 = clamp(s.clearcoat, 0.0, 1.0);\n    if (_4454 > 0.0)\n    {\n        float _4462 = clamp(s.clearcoat_roughness, 0.0500000007450580596923828125, 1.0);\n        _8323 = _4454;\n        _8324 = _4462;\n        float _4469 = _4462 * _4462;\n        _8325 = _4469;\n        _8326 = _4469 * _4469;\n        float _4481 = max(dot(i.world_normal, v), 9.9999997473787516355514526367188e-05);\n        _8328 = _4481;\n        _8321 = 1.0 - (_4454 * (0.039999999105930328369140625 + (0.959999978542327880859375 * pow(clamp(1.0 - _4481, 0.0, 1.0), 5.0))));\n        _8319 = true;\n    }\n    vec3 _4500 = max(s.sheen_color, vec3(0.0));\n    float _4509 = max(_4500.x, max(_4500.y, _4500.z));\n    if (_4509 > 0.0)\n    {\n        float _4517 = clamp(s.sheen_roughness, 0.100000001490116119384765625, 1.0);\n        _8329 = true;\n        _8330 = _4500;\n        _8331 = _4517;\n        _8332 = _4517 * _4517;\n        float param = max(dot(n, v), 9.9999997473787516355514526367188e-05);\n        float param_1 = _4517;\n        float _4534 = fa_sheen_albedo(param, param_1);\n        _8334 = _4534;\n        _8333 = 1.0 - min(_4509 * _4534, 1.0);\n        _8319 = true;\n    }\n    _8322 = _8321 * _8333;\n    float _4553 = clamp(s.anisotropy, -1.0, 1.0);\n    if (_4553 != 0.0)\n    {\n        vec3 _4568 = i.world_tangent.xyz - (n * dot(n, i.world_tangent.xyz));\n        vec3 t = _4568;\n        if (dot(_4568, _4568) < 9.9999999392252902907785028219223e-09)\n        {\n            bvec3 _4580 = bvec3(abs(n.y) < 0.9900000095367431640625);\n            t = cross(vec3(_4580.x ? vec3(0.0, 1.0, 0.0).x : vec3(1.0, 0.0, 0.0).x, _4580.y ? vec3(0.0, 1.0, 0.0).y : vec3(1.0, 0.0, 0.0).y, _4580.z ? vec3(0.0, 1.0, 0.0).z : vec3(1.0, 0.0, 0.0).z), n);\n        }\n        vec3 _4584 = t;\n        vec3 _4585 = normalize(_4584);\n        t = _4585;\n        vec3 _4610 = normalize((_4585 * cos(s.anisotropy_rotation)) + ((cross(n, _4585) * ((i.world_tangent.w < 0.0) ? (-1.0) : 1.0)) * sin(s.anisotropy_rotation)));\n        _8336 = _4610;\n        _8337 = cross(n, _4610);\n        float _4620 = roughness * roughness;\n        float _4626 = mix(_4620, 1.0, _4553 * _4553);\n        bool _4628 = _4553 > 0.0;\n        _8338 = _4628 ? _4626 : _4620;\n        _8339 = _4628 ? _4620 : _4626;\n        _8335 = _4553;\n        _8319 = true;\n    }\n    return FaLayers(_8319, _8320, _8321, _8322, _8323, _8324, _8325, _8326, i.world_normal, _8328, _8329, _8330, _8331, _8332, _8333, _8334, _8335, _8336, _8337, _8338, _8339);\n}\n\nvec2 fa_atlas_size()\n{\n    return vec2(textureSize(fa_probe_atlas_fa_env_smp, 0));\n}\n\nvec3 fa_probe_sh_coef(vec2 origin, float res, int k)\n{\n    vec3 v = textureLod(fa_probe_atlas_fa_env_smp, (origin + vec2(float(k) + 0.5, res + 2.5)) / fa_atlas_size(), 0.0).xyz;\n    if (fa_mesh_fs_params[41].y > 0.5)\n    {\n        v = (v - vec3(0.5)) * 8.0;\n    }\n    return v;\n}\n\nvec3 fa_sh_eval(vec3 c[9], vec3 n)\n{\n    vec3 _3423 = max((((c[0] * 0.2820948064327239990234375) + (((c[1] * (0.3257350027561187744140625 * n.y)) + (c[2] * (0.3257350027561187744140625 * n.z))) + (c[3] * (0.3257350027561187744140625 * n.x)))) + (((c[4] * ((0.2731371223926544189453125 * n.x) * n.y)) + (c[5] * ((0.2731371223926544189453125 * n.y) * n.z))) + (c[6] * (0.078847892582416534423828125 * (((3.0 * n.z) * n.z) - 1.0))))) + ((c[7] * ((0.2731371223926544189453125 * n.x) * n.z)) + (c[8] * (0.13656856119632720947265625 * ((n.x * n.x) - (n.y * n.y))))), vec3(0.0));\n    return _3423;\n}\n\nvec3 fa_ambient_light(vec3 n)\n{\n    float _4033 = (1.0 - fa_mesh_fs_params[42].w) - fa_mesh_fs_params[47].w;\n    vec3 amb = vec3(0.0);\n    bool _4038 = fa_mesh_fs_params[11].w > 0.5;\n    vec3 c[9];\n    for (int k = 0; k < 9; k++)\n    {\n        c[k] = vec3(0.0);\n    }\n    if (_4033 > 0.0005000000237487256526947021484375)\n    {\n        if (_4038)\n        {\n            for (int k_1 = 0; k_1 < 9; k_1++)\n            {\n                vec2 param = fa_mesh_fs_params[41].zw;\n                float param_1 = 128.0;\n                int param_2 = k_1;\n                c[k_1] = fa_probe_sh_coef(param, param_1, param_2) * _4033;\n            }\n        }\n        else\n        {\n            amb = fa_mesh_fs_params[1].xyz * _4033;\n        }\n    }\n    bool _4089 = fa_mesh_fs_params[42].w > 0.0;\n    if (_4089)\n    {\n        for (int k_2 = 0; k_2 < 9; k_2++)\n        {\n            vec2 param_3 = fa_mesh_fs_params[42].xy;\n            float param_4 = fa_mesh_fs_params[42].z;\n            int param_5 = k_2;\n            c[k_2] += (fa_probe_sh_coef(param_3, param_4, param_5) * fa_mesh_fs_params[42].w);\n        }\n    }\n    bool _4120 = fa_mesh_fs_params[47].w > 0.0;\n    if (_4120)\n    {\n        for (int k_3 = 0; k_3 < 9; k_3++)\n        {\n            vec2 param_6 = fa_mesh_fs_params[47].xy;\n            float param_7 = fa_mesh_fs_params[47].z;\n            int param_8 = k_3;\n            c[k_3] += (fa_probe_sh_coef(param_6, param_7, param_8) * fa_mesh_fs_params[47].w);\n        }\n    }\n    if ((_4038 || _4089) || _4120)\n    {\n        vec3 param_9[9] = c;\n        vec3 param_10 = n;\n        amb += fa_sh_eval(param_9, param_10);\n    }\n    return amb;\n}\n\nvec3 fa_indirect_diffuse(vec3 n)\n{\n    if (fa_lm.z > 0.5)\n    {\n        return textureLod(fa_lightmap_fa_env_smp, fa_lm.xy, 0.0).xyz;\n    }\n    if (fa_mesh_fs_params[32].w > 0.0)\n    {\n        vec3 c[9];\n        for (int k = 0; k < 9; k++)\n        {\n            c[k] = fa_mesh_fs_params[k * 1 + 32].xyz;\n        }\n        vec3 param = n;\n        vec3 param_1[9] = c;\n        vec3 param_2 = n;\n        return mix(fa_ambient_light(param), fa_sh_eval(param_1, param_2), vec3(clamp(fa_mesh_fs_params[32].w, 0.0, 1.0)));\n    }\n    vec3 param_3 = n;\n    return fa_ambient_light(param_3);\n}\n\nint fa_cluster_index(int slot, int n)\n{\n    int param = (int(fa_mesh_fs_params[19].x) + int(fa_mesh_fs_params[19].w)) + ((slot + n) >> 2);\n    vec4 t = fa_light_texel(param);\n    return int(t[(slot + n) & 3]);\n}\n\nint fa_cl_light(int n)\n{\n    if (n < fa_cl_ndir)\n    {\n        return n;\n    }\n    int param = fa_cl_slot;\n    int param_1 = n - fa_cl_ndir;\n    return fa_cluster_index(param, param_1);\n}\n\nint fa_light_base(int li)\n{\n    return li * ((fa_mesh_fs_params[1].w > 4.5) ? 8 : 4);\n}\n\nbool fa_light_baked(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 3;\n    return fa_light_texel(param_1).w > 0.5;\n}\n\nfloat fa_baked_keep(int li)\n{\n    float _5757;\n    if (fa_lm.z > 0.5)\n    {\n        _5757 = 0.0;\n    }\n    else\n    {\n        _5757 = 1.0 - clamp(fa_mesh_fs_params[32].w, 0.0, 1.0);\n    }\n    bool _5768 = _5757 < 1.0;\n    bool _5774;\n    if (_5768)\n    {\n        int param = li;\n        _5774 = fa_light_baked(param);\n    }\n    else\n    {\n        _5774 = _5768;\n    }\n    return _5774 ? _5757 : 1.0;\n}\n\nfloat fa_light_type(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 1;\n    return fa_light_texel(param_1).w;\n}\n\nvec4 fa_atlas_fetch(vec2 texel)\n{\n    return textureLod(fa_light_atlas_fa_env_smp, texel / vec2(textureSize(fa_light_atlas_fa_env_smp, 0)), 0.0);\n}\n\nvec3 fa_cookie_sample(vec2 tile_origin, vec2 uv)\n{\n    vec2 param = (tile_origin + vec2(1.0)) + (clamp(uv, vec2(0.0), vec2(1.0)) * 254.0);\n    return fa_atlas_fetch(param).xyz;\n}\n\nvec3 fa_area_point(vec3 c, vec3 axis, vec3 ru, vec3 uu, float hx, float hy, float shape, vec3 p, vec3 r)\n{\n    bool _830 = dot(r, r) > 0.5;\n    if (shape > 1.5)\n    {\n        vec3 _843 = (c - (ru * hx)) - p;\n        vec3 _849 = ru * (2.0 * hx);\n        float _855 = max(dot(_849, _849), 9.9999999392252902907785028219223e-09);\n        float _859 = dot(_843, _849);\n        float t = clamp((-_859) / _855, 0.0, 1.0);\n        if (_830)\n        {\n            float _874 = dot(r, _849);\n            float _880 = _855 - (_874 * _874);\n            if (abs(_880) > (9.9999997473787516355514526367188e-06 * _855))\n            {\n                t = clamp(((dot(r, _843) * _874) - _859) / _880, 0.0, 1.0);\n            }\n        }\n        return (p + _843) + (_849 * t);\n    }\n    vec3 q = p;\n    float _912 = dot(r, axis);\n    bool _920;\n    if (_830)\n    {\n        _920 = abs(_912) > 9.9999997473787516355514526367188e-05;\n    }\n    else\n    {\n        _920 = _830;\n    }\n    if (_920)\n    {\n        float _930 = dot(c - p, axis) / _912;\n        if (_930 > 0.0)\n        {\n            q = p + (r * _930);\n        }\n    }\n    vec3 _943 = q - c;\n    vec2 xy = vec2(dot(_943, ru), dot(_943, uu));\n    if (shape > 0.5)\n    {\n        float _958 = length(xy);\n        if (_958 > hx)\n        {\n            xy *= (hx / _958);\n        }\n    }\n    else\n    {\n        xy = clamp(xy, vec2(-hx, -hy), vec2(hx, hy));\n    }\n    return (c + (ru * xy.x)) + (uu * xy.y);\n}\n\nint fa_cube_face(vec3 d)\n{\n    vec3 _591 = abs(d);\n    float _593 = _591.x;\n    float _595 = _591.y;\n    bool _596 = _593 >= _595;\n    bool _604;\n    if (_596)\n    {\n        _604 = _593 >= _591.z;\n    }\n    else\n    {\n        _604 = _596;\n    }\n    int _605;\n    if (_604)\n    {\n        _605 = (d.x > 0.0) ? 0 : 1;\n    }\n    else\n    {\n        int _620;\n        if (_595 >= _591.z)\n        {\n            _620 = (d.y > 0.0) ? 2 : 3;\n        }\n        else\n        {\n            _620 = (d.z > 0.0) ? 4 : 5;\n        }\n        _605 = _620;\n    }\n    return _605;\n}\n\nvoid fa_cube_face_basis(int f, out vec3 fwd, out vec3 up)\n{\n    if (f == 0)\n    {\n        fwd = vec3(1.0, 0.0, 0.0);\n        up = vec3(0.0, 1.0, 0.0);\n    }\n    else\n    {\n        if (f == 1)\n        {\n            fwd = vec3(-1.0, 0.0, 0.0);\n            up = vec3(0.0, 1.0, 0.0);\n        }\n        else\n        {\n            if (f == 2)\n            {\n                fwd = vec3(0.0, 1.0, 0.0);\n                up = vec3(0.0, 0.0, 1.0);\n            }\n            else\n            {\n                if (f == 3)\n                {\n                    fwd = vec3(0.0, -1.0, 0.0);\n                    up = vec3(0.0, 0.0, -1.0);\n                }\n                else\n                {\n                    if (f == 4)\n                    {\n                        fwd = vec3(0.0, 0.0, 1.0);\n                        up = vec3(0.0, 1.0, 0.0);\n                    }\n                    else\n                    {\n                        fwd = vec3(0.0, 0.0, -1.0);\n                        up = vec3(0.0, 1.0, 0.0);\n                    }\n                }\n            }\n        }\n    }\n}\n\nfloat fa_ies_sample(vec2 tile_origin, vec3 d, vec3 axis, vec3 right, vec3 up)\n{\n    float _750 = dot(d, right);\n    float _754 = dot(d, up);\n    float _765;\n    if (((_750 * _750) + (_754 * _754)) > 1.0000000133514319600180897396058e-10)\n    {\n        _765 = atan(_754, _750) * 0.15915493667125701904296875;\n    }\n    else\n    {\n        _765 = 0.0;\n    }\n    vec2 param = tile_origin + vec2(1.0 + ((_765 - floor(_765)) * 64.0), 1.0 + (acos(clamp(dot(d, axis), -1.0, 1.0)) * 10.18591594696044921875));\n    return fa_atlas_fetch(param).x;\n}\n\nLightSample fa_light_sample_n(int li, vec3 world_pos, vec3 n)\n{\n    int param = li;\n    int _996 = fa_light_base(param);\n    bool _1000 = fa_mesh_fs_params[1].w > 4.5;\n    int param_1 = _996;\n    vec4 _1004 = fa_light_texel(param_1);\n    int param_2 = _996 + 1;\n    vec4 _1009 = fa_light_texel(param_2);\n    float _1012 = _1009.w;\n    float atten = 1.0;\n    float dist = 0.0;\n    fa_light_tint = vec3(1.0);\n    bool _1024 = _1000 && (_1012 > 2.5);\n    fa_light_is_area = _1024;\n    bool _1026 = _1012 < 0.5;\n    vec3 l;\n    if (_1026)\n    {\n        l = normalize(_1004.xyz);\n        if (_1000)\n        {\n            int param_3 = _996 + 6;\n            vec4 _1040 = fa_light_texel(param_3);\n            if (_1040.z > 0.5)\n            {\n                int param_4 = _996 + 4;\n                vec4 _1050 = fa_light_texel(param_4);\n                int param_5 = _996 + 5;\n                vec4 _1055 = fa_light_texel(param_5);\n                vec2 param_6 = _1040.xy;\n                vec2 param_7 = fract(vec2(dot(world_pos, _1050.xyz) * _1050.w, (-dot(world_pos, _1055.xyz)) * _1055.w) + vec2(0.5));\n                fa_light_tint = fa_cookie_sample(param_6, param_7);\n            }\n        }\n    }\n    else\n    {\n        vec3 _1085 = _1004.xyz;\n        vec3 _1087 = _1085 - world_pos;\n        vec3 to_light = _1087;\n        float _1090 = length(_1087);\n        float reach = _1090;\n        bool front = true;\n        if (_1024)\n        {\n            int param_8 = _996 + 7;\n            reach = max(_1090 - fa_light_texel(param_8).w, 0.0);\n            int param_9 = _996 + 4;\n            vec4 _1114 = fa_light_texel(param_9);\n            int param_10 = _996 + 5;\n            vec4 _1119 = fa_light_texel(param_10);\n            int param_11 = _996 + 6;\n            vec4 _1124 = fa_light_texel(param_11);\n            float _1125 = _1124.w;\n            int param_12 = _996 + 2;\n            vec3 _1132 = normalize(fa_light_texel(param_12).xyz);\n            bool _1134 = _1125 > 1.5;\n            bool _1142;\n            if (!_1134)\n            {\n                _1142 = dot(_1132, to_light) < 0.0;\n            }\n            else\n            {\n                _1142 = _1134;\n            }\n            front = _1142;\n            vec3 r = vec3(0.0);\n            vec3 _1151 = fa_mesh_fs_params[0].xyz - world_pos;\n            bool _1155 = dot(n, n) > 0.5;\n            bool _1163;\n            if (_1155)\n            {\n                _1163 = dot(_1151, _1151) > 9.9999999600419720025001879548654e-13;\n            }\n            else\n            {\n                _1163 = _1155;\n            }\n            if (_1163)\n            {\n                r = reflect(-normalize(_1151), normalize(n));\n            }\n            vec3 param_13 = _1085;\n            vec3 param_14 = _1132;\n            vec3 param_15 = _1114.xyz;\n            vec3 param_16 = _1119.xyz;\n            float param_17 = _1114.w;\n            float param_18 = _1119.w;\n            float param_19 = _1125;\n            vec3 param_20 = world_pos;\n            vec3 param_21 = r;\n            to_light = fa_area_point(param_13, param_14, param_15, param_16, param_17, param_18, param_19, param_20, param_21) - world_pos;\n        }\n        float _1199 = length(to_light);\n        dist = _1199;\n        l = to_light / vec3(max(_1199, 9.9999997473787516355514526367188e-05));\n        float _1213 = reach / max(_1004.w, 0.001000000047497451305389404296875);\n        float _1219 = clamp(1.0 - (_1213 * _1213), 0.0, 1.0);\n        float _1221;\n        if (front)\n        {\n            _1221 = _1219 * _1219;\n        }\n        else\n        {\n            _1221 = 0.0;\n        }\n        atten = _1221;\n        bool _1232 = _1012 < 2.5;\n        if ((_1012 > 1.5) && _1232)\n        {\n            int param_22 = _996 + 2;\n            vec4 _1240 = fa_light_texel(param_22);\n            float _1250 = _1240.w;\n            int param_23 = _996 + 3;\n            vec4 _1255 = fa_light_texel(param_23);\n            float _1256 = _1255.x;\n            float cos_inner = _1256;\n            if (_1256 > 1.5)\n            {\n                cos_inner = mix(_1250, 1.0, 0.25);\n            }\n            atten *= smoothstep(_1250, cos_inner, dot(-l, normalize(_1240.xyz)));\n        }\n        if (_1000 && (_1012 < 1.5))\n        {\n            int param_24 = _996 + 6;\n            vec4 _1280 = fa_light_texel(param_24);\n            if (_1280.z > 0.5)\n            {\n                vec3 _1288 = -to_light;\n                int param_25 = _996 + 4;\n                int param_26 = _996 + 5;\n                vec3 _1302 = fa_light_texel(param_25).xyz;\n                vec3 _1306 = fa_light_texel(param_26).xyz;\n                vec3 _1315 = vec3(dot(_1288, _1302), dot(_1288, _1306), dot(_1288, cross(_1302, _1306)));\n                vec3 param_27 = _1315;\n                int _1319 = fa_cube_face(param_27);\n                int param_28 = _1319;\n                vec3 param_29;\n                vec3 param_30;\n                fa_cube_face_basis(param_28, param_29, param_30);\n                vec2 _1346 = vec2(dot(_1315, cross(param_29, param_30)), dot(_1315, param_30)) / vec2(max(dot(_1315, param_29), 9.9999997473787516355514526367188e-05));\n                int _1350 = _1319 / 3;\n                vec2 param_31 = _1280.xy + (vec2(float(_1319 - (_1350 * 3)), float(_1350)) * 256.0);\n                vec2 param_32 = vec2(0.5 + (0.5 * _1346.x), 0.5 - (0.5 * _1346.y));\n                fa_light_tint = fa_cookie_sample(param_31, param_32);\n            }\n            int param_33 = _996 + 7;\n            vec4 _1380 = fa_light_texel(param_33);\n            if (_1380.z > 0.5)\n            {\n                int param_34 = _996 + 2;\n                int param_35 = _996 + 4;\n                int param_36 = _996 + 5;\n                vec2 param_37 = _1380.xy;\n                vec3 param_38 = -l;\n                vec3 param_39 = normalize(fa_light_texel(param_34).xyz);\n                vec3 param_40 = fa_light_texel(param_35).xyz;\n                vec3 param_41 = fa_light_texel(param_36).xyz;\n                atten *= fa_ies_sample(param_37, param_38, param_39, param_40, param_41);\n            }\n        }\n        else\n        {\n            if (_1000 && _1232)\n            {\n                int param_42 = _996 + 6;\n                vec4 _1427 = fa_light_texel(param_42);\n                int param_43 = _996 + 7;\n                vec4 _1432 = fa_light_texel(param_43);\n                bool _1435 = _1427.z > 0.5;\n                bool _1442;\n                if (!_1435)\n                {\n                    _1442 = _1432.z > 0.5;\n                }\n                else\n                {\n                    _1442 = _1435;\n                }\n                if (_1442)\n                {\n                    int param_44 = _996 + 2;\n                    vec4 _1449 = fa_light_texel(param_44);\n                    vec3 _1453 = normalize(_1449.xyz);\n                    int param_45 = _996 + 4;\n                    vec4 _1458 = fa_light_texel(param_45);\n                    int param_46 = _996 + 5;\n                    vec4 _1463 = fa_light_texel(param_46);\n                    if (_1435)\n                    {\n                        vec3 _1471 = -to_light;\n                        float _1478 = _1449.w;\n                        float _1494 = 0.5 / max(dot(_1471, _1453) * (sqrt(max(1.0 - (_1478 * _1478), 0.0)) / max(_1478, 0.001000000047497451305389404296875)), 9.9999997473787516355514526367188e-05);\n                        vec2 param_47 = _1427.xy;\n                        vec2 param_48 = vec2(0.5 + (dot(_1471, _1458.xyz) * _1494), 0.5 - (dot(_1471, _1463.xyz) * _1494));\n                        fa_light_tint = fa_cookie_sample(param_47, param_48);\n                    }\n                    if (_1432.z > 0.5)\n                    {\n                        vec2 param_49 = _1432.xy;\n                        vec3 param_50 = -l;\n                        vec3 param_51 = _1453;\n                        vec3 param_52 = _1458.xyz;\n                        vec3 param_53 = _1463.xyz;\n                        atten *= fa_ies_sample(param_49, param_50, param_51, param_52, param_53);\n                    }\n                }\n            }\n        }\n    }\n    vec3 _8307 = _1009.xyz * atten;\n    if (_1000)\n    {\n        _8307 *= fa_light_tint;\n    }\n    int _1563;\n    if (_1026)\n    {\n        _1563 = 0;\n    }\n    else\n    {\n        _1563 = ((_1012 > 1.5) && (_1012 < 2.5)) ? 2 : 1;\n    }\n    return LightSample(l, _8307, atten, 1.0, dist, _1563);\n}\n\nfloat fa_shadow_split_at(int i)\n{\n    float _2300;\n    if (i == 0)\n    {\n        _2300 = fa_shadows[24].x;\n    }\n    else\n    {\n        float _2316;\n        if (i == 1)\n        {\n            _2316 = fa_shadows[24].y;\n        }\n        else\n        {\n            float _2324;\n            if (i == 2)\n            {\n                _2324 = fa_shadows[24].z;\n            }\n            else\n            {\n                _2324 = fa_shadows[24].w;\n            }\n            _2316 = _2324;\n        }\n        _2300 = _2316;\n    }\n    return _2300;\n}\n\nfloat fa_shadow_depth(inout vec2 uv, vec4 rect)\n{\n    uv = clamp(uv, rect.xy, rect.zw);\n    return textureLod(fa_shadow_tex_fa_shadow_smp, uv, 0.0).x;\n}\n\nfloat fa_shadow_fetch(vec2 uv, vec4 rect, vec3 conv)\n{\n    vec2 param = uv;\n    vec4 param_1 = rect;\n    float _2357 = fa_shadow_depth(param, param_1);\n    float _2361;\n    if (conv.x < 0.5)\n    {\n        _2361 = _2357;\n    }\n    else\n    {\n        _2361 = (conv.y * conv.z) / (conv.z - (_2357 * (conv.z - conv.y)));\n    }\n    return _2361;\n}\n\nfloat fa_shadow_noise()\n{\n    return fract(52.98291778564453125 * fract(dot(gl_FragCoord.xy, vec2(0.067110560834407806396484375, 0.005837149918079376220703125))));\n}\n\nvec2 fa_shadow_vogel(int k, int n, float phi)\n{\n    float _2288 = (float(k) * 2.3999631404876708984375) + phi;\n    return vec2(cos(_2288), sin(_2288)) * sqrt((float(k) + 0.5) / float(n));\n}\n\nfloat fa_shadow_filter(vec2 uv, vec4 rect, float zr, float texel_m, float unit, float reach, float plane, vec3 conv, int mode, float k)\n{\n    if (mode == 1)\n    {\n        vec2 param = uv;\n        vec4 param_1 = rect;\n        vec3 param_2 = conv;\n        return float(zr <= fa_shadow_fetch(param, param_1, param_2));\n    }\n    float _2407 = fa_shadow_noise() * 6.283185482025146484375;\n    float radius = 1.5;\n    if (mode == 2)\n    {\n        float _2416;\n        if (k < 0.0)\n        {\n            _2416 = (-k) / max(zr, 0.100000001490116119384765625);\n        }\n        else\n        {\n            _2416 = k;\n        }\n        float _2436 = clamp((_2416 * reach) / texel_m, 3.0, 12.0);\n        float sum = 0.0;\n        float cnt = 0.0;\n        for (int i = 0; i < 16; i++)\n        {\n            int param_3 = i;\n            int param_4 = 16;\n            float param_5 = _2407;\n            vec2 _2455 = fa_shadow_vogel(param_3, param_4, param_5) * _2436;\n            vec2 param_6 = uv + (_2455 * fa_shadows[26].zw);\n            vec4 param_7 = rect;\n            vec3 param_8 = conv;\n            float _2467 = fa_shadow_fetch(param_6, param_7, param_8);\n            if (_2467 < (zr - (length(_2455) * plane)))\n            {\n                sum += _2467;\n                cnt += 1.0;\n            }\n        }\n        if (cnt < 0.5)\n        {\n            return 1.0;\n        }\n        float _2493 = sum / cnt;\n        float _2503;\n        if (k < 0.0)\n        {\n            _2503 = (-k) / max(_2493, 0.0500000007450580596923828125);\n        }\n        else\n        {\n            _2503 = k;\n        }\n        radius = clamp(((max(zr - _2493, 0.0) * unit) * _2503) / texel_m, 1.5, 16.0);\n    }\n    float lit = 0.0;\n    int _2525 = (mode == 2) ? 24 : 16;\n    for (int i_1 = 0; i_1 < _2525; i_1++)\n    {\n        int param_9 = i_1;\n        int param_10 = _2525;\n        float param_11 = _2407;\n        vec2 _2544 = fa_shadow_vogel(param_9, param_10, param_11) * radius;\n        vec2 param_12 = uv + (_2544 * fa_shadows[26].zw);\n        vec4 param_13 = rect;\n        vec3 param_14 = conv;\n        lit += float((zr - (length(_2544) * plane)) <= fa_shadow_fetch(param_12, param_13, param_14));\n    }\n    return lit / float(_2525);\n}\n\nfloat fa_shadow_cascade(int ci, vec3 world, vec3 n, vec3 l)\n{\n    float _2586 = max(fa_shadows[ci * 1 + 20].y, 0.001000000047497451305389404296875);\n    float _2591 = clamp(dot(n, l), 0.0, 1.0);\n    float _2597 = sqrt(1.0 - (_2591 * _2591));\n    float _2604 = min(_2597 / max(_2591, 0.20000000298023223876953125), 4.0);\n    float _2609;\n    if (fa_shadows[26].y > 0.0)\n    {\n        _2609 = fa_shadows[26].y;\n    }\n    else\n    {\n        _2609 = 1.5 * fa_shadows[ci * 1 + 20].x;\n    }\n    vec4 _2634 = mat4(fa_shadows[ci * 4 + 0], fa_shadows[ci * 4 + 1], fa_shadows[ci * 4 + 2], fa_shadows[ci * 4 + 3]) * vec4(world + (n * (_2609 * _2597)), 1.0);\n    float _2641 = _2634.x;\n    bool _2644 = _2641 < fa_shadows[ci * 1 + 16].x;\n    bool _2653;\n    if (!_2644)\n    {\n        _2653 = _2641 > fa_shadows[ci * 1 + 16].z;\n    }\n    else\n    {\n        _2653 = _2644;\n    }\n    bool _2662;\n    if (!_2653)\n    {\n        _2662 = _2634.y < fa_shadows[ci * 1 + 16].y;\n    }\n    else\n    {\n        _2662 = _2653;\n    }\n    bool _2671;\n    if (!_2662)\n    {\n        _2671 = _2634.y > fa_shadows[ci * 1 + 16].w;\n    }\n    else\n    {\n        _2671 = _2662;\n    }\n    bool _2678;\n    if (!_2671)\n    {\n        _2678 = _2634.z > 1.0;\n    }\n    else\n    {\n        _2678 = _2671;\n    }\n    if (_2678)\n    {\n        return -1.0;\n    }\n    float _2686;\n    if (fa_shadows[26].x > 0.0)\n    {\n        _2686 = fa_shadows[26].x;\n    }\n    else\n    {\n        _2686 = 1.5 * fa_shadows[ci * 1 + 20].x;\n    }\n    vec2 param = _2634.xy;\n    vec4 param_1 = fa_shadows[ci * 1 + 16];\n    float param_2 = _2634.z - ((_2686 * (1.0 + (0.5 * _2604))) / _2586);\n    float param_3 = fa_shadows[ci * 1 + 20].x;\n    float param_4 = _2586;\n    float param_5 = _2586 * 0.25;\n    float param_6 = ((fa_shadows[ci * 1 + 20].x * min(_2604, 3.0)) * 0.5) / _2586;\n    vec3 param_7 = vec3(0.0);\n    int param_8 = int(fa_shadows[25].z + 0.5);\n    float param_9 = fa_shadows[25].w;\n    return fa_shadow_filter(param, param_1, param_2, param_3, param_4, param_5, param_6, param_7, param_8, param_9);\n}\n\nfloat fa_shadow_sun(vec3 world, vec3 n, vec3 l)\n{\n    if (fa_mesh_fs_params[5].z < 0.5)\n    {\n        return 1.0;\n    }\n    int _3064 = int(fa_shadows[25].x + 0.5);\n    if (_3064 < 1)\n    {\n        return 1.0;\n    }\n    float _3079 = dot(world - fa_shadows[27].xyz, fa_shadows[28].xyz);\n    int param = _3064 - 1;\n    if (_3079 > fa_shadow_split_at(param))\n    {\n        return 1.0;\n    }\n    int ci = 0;\n    bool _3091 = _3064 > 1;\n    bool _3098;\n    if (_3091)\n    {\n        _3098 = _3079 > fa_shadows[24].x;\n    }\n    else\n    {\n        _3098 = _3091;\n    }\n    if (_3098)\n    {\n        ci = 1;\n    }\n    bool _3102 = _3064 > 2;\n    bool _3109;\n    if (_3102)\n    {\n        _3109 = _3079 > fa_shadows[24].y;\n    }\n    else\n    {\n        _3109 = _3102;\n    }\n    if (_3109)\n    {\n        ci = 2;\n    }\n    bool _3113 = _3064 > 3;\n    bool _3120;\n    if (_3113)\n    {\n        _3120 = _3079 > fa_shadows[24].z;\n    }\n    else\n    {\n        _3120 = _3113;\n    }\n    if (_3120)\n    {\n        ci = 3;\n    }\n    float s = -1.0;\n    for (int k = 0; k < 4; k++)\n    {\n        if (ci >= _3064)\n        {\n            break;\n        }\n        int param_1 = ci;\n        vec3 param_2 = world;\n        vec3 param_3 = n;\n        vec3 param_4 = l;\n        float _3146 = fa_shadow_cascade(param_1, param_2, param_3, param_4);\n        s = _3146;\n        if (_3146 >= 0.0)\n        {\n            break;\n        }\n        ci++;\n    }\n    if (s < 0.0)\n    {\n        return 1.0;\n    }\n    if (fa_shadows[25].y > 0.0)\n    {\n        float _3171;\n        if (ci > 0)\n        {\n            int param_5 = ci - 1;\n            _3171 = fa_shadow_split_at(param_5);\n        }\n        else\n        {\n            _3171 = fa_shadows[28].w;\n        }\n        int param_6 = ci;\n        float _3190 = fa_shadows[25].y * max(fa_shadow_split_at(param_6) - _3171, 9.9999997473787516355514526367188e-05);\n        int param_7 = ci;\n        float _3201 = clamp((_3079 - (fa_shadow_split_at(param_7) - _3190)) / _3190, 0.0, 1.0);\n        if (_3201 > 0.0)\n        {\n            float s2 = 1.0;\n            if ((ci + 1) < _3064)\n            {\n                int param_8 = ci + 1;\n                vec3 param_9 = world;\n                vec3 param_10 = n;\n                vec3 param_11 = l;\n                float _3222 = fa_shadow_cascade(param_8, param_9, param_10, param_11);\n                s2 = _3222;\n                if (_3222 < 0.0)\n                {\n                    s2 = s;\n                }\n            }\n            s = mix(s, s2, _3201);\n        }\n    }\n    return s;\n}\n\nfloat fa_shadow_factor(vec3 n, vec3 l)\n{\n    vec3 param = fa_world_pos;\n    vec3 param_1 = n;\n    vec3 param_2 = l;\n    return fa_shadow_sun(param, param_1, param_2);\n}\n\nfloat fa_shadow_local(int li, vec3 lpos, vec3 world, vec3 n, vec3 l)\n{\n    bool _2744 = fa_mesh_fs_params[5].z < 0.5;\n    bool _2751;\n    if (!_2744)\n    {\n        _2751 = fa_shadows[29].x < 0.5;\n    }\n    else\n    {\n        _2751 = _2744;\n    }\n    if (_2751)\n    {\n        return 1.0;\n    }\n    int param = (int(fa_shadows[29].x + 0.5) - 1) + li;\n    vec4 _2764 = fa_light_texel(param);\n    float _2765 = _2764.x;\n    if (_2765 < 0.0)\n    {\n        return 1.0;\n    }\n    int _2774 = int(_2765 + 0.5);\n    int param_1 = _2774;\n    vec4 _2778 = fa_light_texel(param_1);\n    int param_2 = _2774 + 1;\n    vec4 _2783 = fa_light_texel(param_2);\n    float fade = 1.0;\n    float _2786 = _2778.y;\n    if (_2786 > 0.0)\n    {\n        float _2803 = 1.0 - smoothstep(0.75 * _2786, _2786, length(world - fa_shadows[27].xyz));\n        fade = _2803;\n        if (_2803 <= 0.0)\n        {\n            return 1.0;\n        }\n    }\n    int face = 0;\n    if (_2778.x > 1.5)\n    {\n        vec3 param_3 = world - lpos;\n        face = fa_cube_face(param_3);\n    }\n    int _2827 = (_2774 + 2) + (face * 6);\n    int param_4 = _2827;\n    int param_5 = _2827 + 1;\n    int param_6 = _2827 + 3;\n    vec4 _2841 = fa_light_texel(param_6);\n    int param_7 = _2827 + 4;\n    vec4 _2846 = fa_light_texel(param_7);\n    int param_8 = _2827 + 5;\n    vec4 _2851 = fa_light_texel(param_8);\n    float _2863 = _2851.x * max(dot(_2841, vec4(world, 1.0)), 0.001000000047497451305389404296875);\n    float _2868 = clamp(dot(n, l), 0.0, 1.0);\n    float _2891 = clamp(dot(n, _2841.xyz), -1.0, 1.0);\n    float _2910 = min(sqrt(1.0 - (_2891 * _2891)) / max(abs(dot(n, world - lpos)) / max(dot(_2841, vec4(world, 1.0)), 0.001000000047497451305389404296875), 0.20000000298023223876953125), 4.0);\n    float _2913 = _2783.y;\n    float _2915;\n    if (_2913 > 0.0)\n    {\n        _2915 = _2913;\n    }\n    else\n    {\n        _2915 = 1.5 * _2863;\n    }\n    vec4 _2935 = vec4(world + (n * (_2915 * sqrt(1.0 - (_2868 * _2868)))), 1.0);\n    float _2939 = dot(_2841, _2935);\n    float _2942 = _2851.y;\n    if (_2939 < _2942)\n    {\n        return 1.0;\n    }\n    vec2 _2957 = vec2(dot(fa_light_texel(param_4), _2935), dot(fa_light_texel(param_5), _2935)) / vec2(_2939);\n    float _2959 = _2957.x;\n    bool _2962 = _2959 < _2846.x;\n    bool _2971;\n    if (!_2962)\n    {\n        _2971 = _2959 > _2846.z;\n    }\n    else\n    {\n        _2971 = _2962;\n    }\n    bool _2980;\n    if (!_2971)\n    {\n        _2980 = _2957.y < _2846.y;\n    }\n    else\n    {\n        _2980 = _2971;\n    }\n    bool _2989;\n    if (!_2980)\n    {\n        _2989 = _2957.y > _2846.w;\n    }\n    else\n    {\n        _2989 = _2980;\n    }\n    if (_2989)\n    {\n        return 1.0;\n    }\n    float _2995 = _2783.x;\n    float _2997;\n    if (_2995 > 0.0)\n    {\n        _2997 = _2995;\n    }\n    else\n    {\n        _2997 = 1.5 * _2863;\n    }\n    vec2 param_9 = _2957;\n    vec4 param_10 = _2846;\n    float param_11 = _2939 - (_2997 * (1.0 + (0.5 * _2910)));\n    float param_12 = _2863;\n    float param_13 = 1.0;\n    float param_14 = _2851.z * 0.25;\n    float param_15 = (_2863 * min(_2910, 3.0)) * 0.5;\n    vec3 param_16 = vec3(1.0, _2942, _2851.z);\n    int param_17 = int(_2778.z + 0.5);\n    float param_18 = _2778.w;\n    return mix(1.0, fa_shadow_filter(param_9, param_10, param_11, param_12, param_13, param_14, param_15, param_16, param_17, param_18), fade);\n}\n\nfloat fa_contact_shadow(int li, vec3 world, vec3 gn, vec3 l, float dist)\n{\n    bool _5138 = fa_mesh_fs_params[24].x < 0.5;\n    bool _5145;\n    if (!_5138)\n    {\n        _5145 = fa_shadows[29].x < 0.5;\n    }\n    else\n    {\n        _5145 = _5138;\n    }\n    if (_5145)\n    {\n        return 1.0;\n    }\n    int param = (int(fa_shadows[29].x + 0.5) - 1) + li;\n    vec4 _5158 = fa_light_texel(param);\n    float _5159 = _5158.y;\n    float len = _5159;\n    if (_5159 <= 0.0)\n    {\n        return 1.0;\n    }\n    float _5171 = length(world - fa_mesh_fs_params[0].xyz);\n    float _5181 = 1.0 - smoothstep(0.5 * fa_mesh_fs_params[25].x, fa_mesh_fs_params[25].x, _5171);\n    if (_5181 <= 0.0)\n    {\n        return 1.0;\n    }\n    float _5187 = len;\n    float _5190 = min(_5187, 0.89999997615814208984375 * dist);\n    len = _5190;\n    float _5195 = 0.004999999888241291046142578125 + (0.0030000000260770320892333984375 * _5171);\n    float _5200 = _5195 + (0.5 * _5190);\n    vec3 _5206 = world + (gn * _5195);\n    float _5208 = fa_shadow_noise();\n    float occ = 0.0;\n    float _5272;\n    for (int k = 0; k < 12; k++)\n    {\n        float _5223 = (float(k) + _5208) * 0.083333335816860198974609375;\n        vec3 _5231 = _5206 + (l * (_5223 * len));\n        vec4 _5237 = vec4(_5231, 1.0);\n        float _5243 = dot(fa_mesh_fs_params[28], _5237);\n        if (_5243 < 9.9999997473787516355514526367188e-05)\n        {\n            break;\n        }\n        vec2 _5263 = vec2(dot(fa_mesh_fs_params[26], _5237), dot(fa_mesh_fs_params[27], _5237)) / vec2(_5243);\n        float _5267 = _5263.x * 0.5;\n        float _5268 = _5267 + 0.5;\n        if (fa_mesh_fs_params[24].y > 0.5)\n        {\n            _5272 = (_5263.y * 0.5) + 0.5;\n        }\n        else\n        {\n            _5272 = 0.5 - (_5263.y * 0.5);\n        }\n        bool _5288 = _5268 < 0.0;\n        bool _5295;\n        if (!_5288)\n        {\n            _5295 = _5268 >= 1.0;\n        }\n        else\n        {\n            _5295 = _5288;\n        }\n        bool _5302;\n        if (!_5295)\n        {\n            _5302 = _5272 < 0.0;\n        }\n        else\n        {\n            _5302 = _5295;\n        }\n        bool _5309;\n        if (!_5302)\n        {\n            _5309 = _5272 >= 1.0;\n        }\n        else\n        {\n            _5309 = _5302;\n        }\n        if (_5309)\n        {\n            break;\n        }\n        vec4 _5328 = texelFetch(fa_screen_tex_fa_shadow_smp, ivec2(vec2(_5268, _5272) * fa_mesh_fs_params[24].zw), 0);\n        if (_5328.w < 0.5)\n        {\n            continue;\n        }\n        float _5347 = (dot(fa_mesh_fs_params[29].xyz, _5231) + fa_mesh_fs_params[29].w) - _5328.x;\n        if ((_5347 > _5195) && (_5347 < _5200))\n        {\n            occ = max(occ, (1.0 - (_5223 * _5223)) * smoothstep(0.0, 0.0500000007450580596923828125, min(min(_5268, 0.5 - _5267), min(_5272, 1.0 - _5272))));\n        }\n    }\n    return 1.0 - (occ * _5181);\n}\n\nLightSample fa_light_shadowed(int li, vec3 world_pos, vec3 gn)\n{\n    int param = li;\n    float _5813 = fa_baked_keep(param);\n    if (_5813 <= 0.0)\n    {\n        int param_1 = li;\n        return LightSample(vec3(0.0, 1.0, 0.0), vec3(0.0), 0.0, 1.0, 0.0, int(fa_light_type(param_1) + 0.5));\n    }\n    int param_2 = li;\n    vec3 param_3 = world_pos;\n    vec3 param_4 = gn;\n    LightSample _5839 = fa_light_sample_n(param_2, param_3, param_4);\n    vec3 _8376 = _5839.color;\n    float _8377 = _5839.attenuation;\n    float _8378 = _5839.shadow;\n    bool _5842 = _5839.type == 0;\n    if (_5842 && (li == 0))\n    {\n        vec3 param_5 = gn;\n        vec3 param_6 = _5839.direction;\n        float _5853 = fa_shadow_factor(param_5, param_6);\n        _8378 = _5853;\n        _8376 *= _5853;\n    }\n    else\n    {\n        bool _5864 = _5839.type != 0;\n        bool _5870;\n        if (_5864)\n        {\n            _5870 = _8377 > 0.0;\n        }\n        else\n        {\n            _5870 = _5864;\n        }\n        if (_5870)\n        {\n            int param_7 = li;\n            int param_8 = fa_light_base(param_7);\n            int param_9 = li;\n            vec3 param_10 = fa_light_texel(param_8).xyz;\n            vec3 param_11 = world_pos;\n            vec3 param_12 = gn;\n            vec3 param_13 = _5839.direction;\n            float _5889 = fa_shadow_local(param_9, param_10, param_11, param_12, param_13);\n            _8378 = _5889;\n            _8376 *= _5889;\n        }\n    }\n    bool _5899 = fa_mesh_fs_params[24].x > 0.5;\n    bool _5905;\n    if (_5899)\n    {\n        _5905 = _8377 > 0.0;\n    }\n    else\n    {\n        _5905 = _5899;\n    }\n    if (_5905)\n    {\n        float _5912;\n        if (_5842)\n        {\n            _5912 = 1000000000.0;\n        }\n        else\n        {\n            _5912 = _5839._distance;\n        }\n        int param_14 = li;\n        vec3 param_15 = world_pos;\n        vec3 param_16 = gn;\n        vec3 param_17 = _5839.direction;\n        float param_18 = _5912;\n        float _5930 = fa_contact_shadow(param_14, param_15, param_16, param_17, param_18);\n        _8378 *= _5930;\n        _8376 *= _5930;\n    }\n    float _5943 = _8377;\n    float _5944 = _5943 * _5813;\n    _8377 = _5944;\n    vec3 _5948 = _8376;\n    vec3 _5949 = _5948 * _5813;\n    _8376 = _5949;\n    return LightSample(_5839.direction, _5949, _5944, _8378, _5839._distance, _5839.type);\n}\n\nvec3 fa_ltc_tangent(vec3 n, vec3 v)\n{\n    vec3 _5983 = v - (n * dot(v, n));\n    vec3 t = _5983;\n    float _5987 = dot(_5983, _5983);\n    float l2 = _5987;\n    if (_5987 < 1.0000000133514319600180897396058e-10)\n    {\n        vec3 _5997;\n        if (abs(n.z) < 0.999000012874603271484375)\n        {\n            _5997 = cross(n, vec3(0.0, 0.0, 1.0));\n        }\n        else\n        {\n            _5997 = cross(n, vec3(1.0, 0.0, 0.0));\n        }\n        t = _5997;\n        l2 = dot(_5997, _5997);\n    }\n    return t * inversesqrt(l2);\n}\n\nvec3 fa_ltc_local(vec3 t1, vec3 n, vec3 p)\n{\n    return vec3(dot(t1, p), dot(cross(n, t1), p), dot(n, p));\n}\n\nvec3 fa_ltc_edge_vector(vec3 a, vec3 b)\n{\n    float _6032 = dot(a, a);\n    float _6036 = dot(b, b);\n    if ((_6032 < 1.0000000195414813782625560981111e-24) || (_6036 < 1.0000000195414813782625560981111e-24))\n    {\n        return vec3(0.0);\n    }\n    vec3 _6050 = a * inversesqrt(_6032);\n    vec3 _6055 = b * inversesqrt(_6036);\n    float _6059 = dot(_6050, _6055);\n    float _6062 = abs(_6059);\n    float g = (((((((((((0.0416471660137176513671875 * _6062) - 0.1924748718738555908203125) * _6062) + 0.4179156124591827392578125) * _6062) - 0.616057217121124267578125) * _6062) + 0.777722418308258056640625) * _6062) - 0.999542415142059326171875) * _6062) + 1.570791721343994140625;\n    if (_6059 < 0.0)\n    {\n        g = (3.1415927410125732421875 * inversesqrt(max(1.0 - (_6059 * _6059), 1.0000000116860974230803549289703e-07))) - g;\n    }\n    return cross(_6050, _6055) * g;\n}\n\nvoid fa_ltc_clip_edge(vec3 a, vec3 b, inout vec3 sum, inout vec3 leave, inout vec3 enter, inout vec2 seen)\n{\n    bool _6119 = a.z > 0.0;\n    bool _6123 = b.z > 0.0;\n    if (_6119 && _6123)\n    {\n        vec3 param = a;\n        vec3 param_1 = b;\n        sum += fa_ltc_edge_vector(param, param_1);\n    }\n    else\n    {\n        if (_6119 != _6123)\n        {\n            vec3 _6158 = a + ((b - a) * (a.z / (a.z - b.z)));\n            _6158.z = 0.0;\n            if (_6119)\n            {\n                vec3 param_2 = a;\n                vec3 param_3 = _6158;\n                sum += fa_ltc_edge_vector(param_2, param_3);\n                leave = _6158;\n                seen.x = 1.0;\n            }\n            else\n            {\n                vec3 param_4 = _6158;\n                vec3 param_5 = b;\n                sum += fa_ltc_edge_vector(param_4, param_5);\n                enter = _6158;\n                seen.y = 1.0;\n            }\n        }\n    }\n}\n\nfloat fa_ltc_quad(vec4 abcd, vec3 p0, vec3 p1, vec3 p2, vec3 p3)\n{\n    vec3 _6207 = vec3((abcd.x * p0.x) + (abcd.y * p0.z), p0.y, (abcd.z * p0.x) + (abcd.w * p0.z));\n    vec3 _6233 = vec3((abcd.x * p1.x) + (abcd.y * p1.z), p1.y, (abcd.z * p1.x) + (abcd.w * p1.z));\n    vec3 _6259 = vec3((abcd.x * p2.x) + (abcd.y * p2.z), p2.y, (abcd.z * p2.x) + (abcd.w * p2.z));\n    vec3 _6285 = vec3((abcd.x * p3.x) + (abcd.y * p3.z), p3.y, (abcd.z * p3.x) + (abcd.w * p3.z));\n    vec3 sum = vec3(0.0);\n    vec3 leave = vec3(0.0);\n    vec3 enter = vec3(0.0);\n    vec3 param = _6207;\n    vec3 param_1 = _6233;\n    vec3 param_2 = vec3(0.0);\n    vec3 param_3 = vec3(0.0);\n    vec3 param_4 = vec3(0.0);\n    vec2 param_5 = vec2(0.0);\n    fa_ltc_clip_edge(param, param_1, param_2, param_3, param_4, param_5);\n    sum = param_2;\n    leave = param_3;\n    enter = param_4;\n    vec3 param_6 = _6233;\n    vec3 param_7 = _6259;\n    vec3 param_8 = param_2;\n    vec3 param_9 = param_3;\n    vec3 param_10 = param_4;\n    vec2 param_11 = param_5;\n    fa_ltc_clip_edge(param_6, param_7, param_8, param_9, param_10, param_11);\n    sum = param_8;\n    leave = param_9;\n    enter = param_10;\n    vec3 param_12 = _6259;\n    vec3 param_13 = _6285;\n    vec3 param_14 = param_8;\n    vec3 param_15 = param_9;\n    vec3 param_16 = param_10;\n    vec2 param_17 = param_11;\n    fa_ltc_clip_edge(param_12, param_13, param_14, param_15, param_16, param_17);\n    sum = param_14;\n    leave = param_15;\n    enter = param_16;\n    vec3 param_18 = _6285;\n    vec3 param_19 = _6207;\n    vec3 param_20 = param_14;\n    vec3 param_21 = param_15;\n    vec3 param_22 = param_16;\n    vec2 param_23 = param_17;\n    fa_ltc_clip_edge(param_18, param_19, param_20, param_21, param_22, param_23);\n    sum = param_20;\n    leave = param_21;\n    enter = param_22;\n    if ((param_23.x * param_23.y) > 0.5)\n    {\n        vec3 param_24 = leave;\n        vec3 param_25 = enter;\n        sum += fa_ltc_edge_vector(param_24, param_25);\n    }\n    return sum.z * 0.15915493667125701904296875;\n}\n\nfloat fa_ltc_rect(vec4 abcd, vec3 center, vec3 ex, vec3 ey)\n{\n    vec4 param = abcd;\n    vec3 param_1 = (center - ex) - ey;\n    vec3 param_2 = (center + ex) - ey;\n    vec3 param_3 = (center + ex) + ey;\n    vec3 param_4 = (center - ex) + ey;\n    return abs(fa_ltc_quad(param, param_1, param_2, param_3, param_4));\n}\n\nfloat fa_area_form(vec4 m, float shape, vec3 pc, vec3 ex, vec3 ey)\n{\n    if ((shape < 0.5) || (shape > 1.5))\n    {\n        vec4 param = m;\n        vec3 param_1 = pc;\n        vec3 param_2 = ex;\n        vec3 param_3 = ey;\n        return fa_ltc_rect(param, param_1, param_2, param_3);\n    }\n    vec3 _6434 = (pc + (ex * 0.92387950420379638671875)) + (ey * 0.3826834261417388916015625);\n    vec3 _6458 = (pc - (ex * 0.92387950420379638671875)) + (ey * 0.3826834261417388916015625);\n    vec3 _6474 = (pc - (ex * 0.3826834261417388916015625)) - (ey * 0.92387950420379638671875);\n    vec4 param_4 = m;\n    vec3 param_5 = _6434;\n    vec3 param_6 = (pc + (ex * 0.3826834261417388916015625)) + (ey * 0.92387950420379638671875);\n    vec3 param_7 = (pc - (ex * 0.3826834261417388916015625)) + (ey * 0.92387950420379638671875);\n    vec3 param_8 = _6458;\n    vec4 param_9 = m;\n    vec3 param_10 = _6434;\n    vec3 param_11 = _6458;\n    vec3 param_12 = (pc - (ex * 0.92387950420379638671875)) - (ey * 0.3826834261417388916015625);\n    vec3 param_13 = _6474;\n    vec4 param_14 = m;\n    vec3 param_15 = _6434;\n    vec3 param_16 = _6474;\n    vec3 param_17 = (pc + (ex * 0.3826834261417388916015625)) - (ey * 0.92387950420379638671875);\n    vec3 param_18 = (pc + (ex * 0.92387950420379638671875)) - (ey * 0.3826834261417388916015625);\n    return abs((fa_ltc_quad(param_4, param_5, param_6, param_7, param_8) + fa_ltc_quad(param_9, param_10, param_11, param_12, param_13)) + fa_ltc_quad(param_14, param_15, param_16, param_17, param_18));\n}\n\nvec2 fa_ltc_uv(float roughness, float ndv)\n{\n    return ((vec2(clamp((roughness - 0.0500000007450580596923828125) * 1.0526316165924072265625, 0.0, 1.0), sqrt(clamp(1.0 - ndv, 0.0, 1.0))) * 63.0) + vec2(0.5)) * vec2(0.015625);\n}\n\nvec3 fa_area_shade(int li, vec3 world_pos, vec3 n, vec3 v, vec3 diffuse_color, vec3 f0, float f90, float roughness, float ndv, float window)\n{\n    int param = li;\n    int _6532 = fa_light_base(param);\n    int param_1 = _6532;\n    int param_2 = _6532 + 1;\n    int param_3 = _6532 + 2;\n    int param_4 = _6532 + 4;\n    vec4 _6554 = fa_light_texel(param_4);\n    int param_5 = _6532 + 5;\n    vec4 _6559 = fa_light_texel(param_5);\n    int param_6 = _6532 + 6;\n    vec4 _6564 = fa_light_texel(param_6);\n    float _6565 = _6564.w;\n    vec3 _6570 = fa_light_texel(param_1).xyz - world_pos;\n    bool _6572 = _6565 < 1.5;\n    bool _6579;\n    if (_6572)\n    {\n        _6579 = dot(normalize(fa_light_texel(param_3).xyz), _6570) >= 0.0;\n    }\n    else\n    {\n        _6579 = _6572;\n    }\n    if (_6579)\n    {\n        return vec3(0.0);\n    }\n    bool _6588 = (_6565 > 0.5) && _6572;\n    float _6592 = _6588 ? 1.0539000034332275390625 : 1.0;\n    vec3 _6595 = _6554.xyz;\n    float _6597 = _6554.w;\n    vec3 _6603 = _6559.xyz;\n    float _6605 = _6559.w;\n    vec3 up = _6603 * (_6605 * _6592);\n    float _6611;\n    if (_6588)\n    {\n        _6611 = (3.1415927410125732421875 * _6597) * _6597;\n    }\n    else\n    {\n        _6611 = (4.0 * _6597) * _6605;\n    }\n    if (_6565 > 1.5)\n    {\n        vec3 _6637 = cross(_6595, -_6570);\n        vec3 perp = _6637;\n        float _6641 = dot(_6637, _6637);\n        vec3 _6644;\n        if (_6641 > 1.0000000133514319600180897396058e-10)\n        {\n            _6644 = perp * inversesqrt(_6641);\n        }\n        else\n        {\n            _6644 = _6603;\n        }\n        perp = _6644;\n        up = _6644 * _6605;\n    }\n    float _6665 = max(_6611, 9.9999999747524270787835121154785e-07);\n    vec3 param_7 = n;\n    vec3 param_8 = v;\n    vec3 _6675 = fa_ltc_tangent(param_7, param_8);\n    vec3 param_9 = _6675;\n    vec3 param_10 = n;\n    vec3 param_11 = _6570;\n    vec3 _6683 = fa_ltc_local(param_9, param_10, param_11);\n    vec3 param_12 = _6675;\n    vec3 param_13 = n;\n    vec3 param_14 = _6595 * (_6597 * _6592);\n    vec3 _6691 = fa_ltc_local(param_12, param_13, param_14);\n    vec3 param_15 = _6675;\n    vec3 param_16 = n;\n    vec3 param_17 = up;\n    vec3 _6699 = fa_ltc_local(param_15, param_16, param_17);\n    vec4 param_18 = vec4(1.0, 0.0, 0.0, 1.0);\n    float param_19 = _6565;\n    vec3 param_20 = _6683;\n    vec3 param_21 = _6691;\n    vec3 param_22 = _6699;\n    float param_23 = roughness;\n    float param_24 = ndv;\n    vec2 _6718 = fa_ltc_uv(param_23, param_24) * 64.0;\n    vec2 param_25 = _6718;\n    vec2 param_26 = _6718 + vec2(64.0, 0.0);\n    vec4 _6728 = fa_atlas_fetch(param_26);\n    vec4 param_27 = fa_atlas_fetch(param_25);\n    float param_28 = _6565;\n    vec3 param_29 = _6683;\n    vec3 param_30 = _6691;\n    vec3 param_31 = _6699;\n    return (((diffuse_color * fa_area_form(param_18, param_19, param_20, param_21, param_22)) + (((f0 * _6728.x) + ((vec3(f90) - f0) * _6728.y)) * fa_area_form(param_27, param_28, param_29, param_30, param_31))) * fa_light_texel(param_2).xyz) * ((((3.1415927410125732421875 * dot(_6570, _6570)) + _6665) / _6665) * window);\n}\n\nvec3 fa_light_rgb(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 1;\n    return fa_light_texel(param_1).xyz;\n}\n\nfloat fa_d_charlie(float alpha, float ndh)\n{\n    float _4875 = 1.0 / alpha;\n    return ((2.0 + _4875) * pow(sqrt(max(1.0 - (ndh * ndh), 9.9999997473787516355514526367188e-05)), _4875)) * 0.15915493667125701904296875;\n}\n\nfloat fa_v_ashikhmin(float ndl, float ndv)\n{\n    return clamp(0.25 / max((ndl + ndv) - (ndl * ndv), 9.9999997473787516355514526367188e-05), 0.0, 1.0);\n}\n\nfloat fa_layers_coat(FaLayers L, vec3 l, vec3 h, float vdh)\n{\n    float _4910 = max(dot(L.nc, l), 0.0);\n    float _4916 = max(dot(L.nc, h), 0.0);\n    float _4925 = ((_4916 * _4916) * (L.coat_a2 - 1.0)) + 1.0;\n    return (((L.coat * (0.039999999105930328369140625 + (0.959999978542327880859375 * pow(clamp(1.0 - vdh, 0.0, 1.0), 5.0)))) * (((L.coat_a2 / ((3.1415927410125732421875 * _4925) * _4925)) * (0.5 / max(mix((2.0 * _4910) * L.coat_ndv, _4910 + L.coat_ndv, L.coat_alpha), 9.9999997473787516355514526367188e-05))) * 3.1415927410125732421875)) * step(9.9999997473787516355514526367188e-05, _4910)) * _4910;\n}\n\nvec3 fa_area_layers(FaLayers L, int li, vec3 world_pos, vec3 n, vec3 v, vec3 l, vec3 diffuse_color, vec3 f0, float roughness, float ndv, float window)\n{\n    int param = li;\n    vec3 param_1 = world_pos;\n    vec3 param_2 = n;\n    vec3 param_3 = v;\n    vec3 param_4 = diffuse_color;\n    vec3 param_5 = f0;\n    float param_6 = L.f90;\n    float param_7 = roughness;\n    float param_8 = ndv;\n    float param_9 = window;\n    float _6796;\n    if (L.sheen_on)\n    {\n        _6796 = L.sheen_scale;\n    }\n    else\n    {\n        _6796 = 1.0;\n    }\n    vec3 result = fa_area_shade(param, param_1, param_2, param_3, param_4, param_5, param_6, param_7, param_8, param_9) * (L.keep * _6796);\n    vec3 _6809 = normalize(l + v);\n    int param_10 = li;\n    vec3 _6820 = fa_light_rgb(param_10) * window;\n    if (L.sheen_on)\n    {\n        float _6829 = max(dot(n, l), 0.0);\n        float param_11 = L.sheen_alpha;\n        float param_12 = max(dot(n, _6809), 0.0);\n        float param_13 = _6829;\n        float param_14 = ndv;\n        result += ((L.sheen * _6820) * (((((fa_d_charlie(param_11, param_12) * fa_v_ashikhmin(param_13, param_14)) * 3.1415927410125732421875) * step(9.9999997473787516355514526367188e-05, _6829)) * _6829) * L.keep));\n    }\n    if (L.coat > 0.0)\n    {\n        FaLayers param_15 = L;\n        vec3 param_16 = l;\n        vec3 param_17 = _6809;\n        float param_18 = max(dot(v, _6809), 0.0);\n        result += (_6820 * fa_layers_coat(param_15, param_16, param_17, param_18));\n    }\n    return result;\n}\n\nfloat fa_d_ggx_aniso(float ndh, float tdh, float bdh, float at, float ab)\n{\n    float _4778 = tdh / at;\n    float _4782 = bdh / ab;\n    float _4794 = ((_4778 * _4778) + (_4782 * _4782)) + (ndh * ndh);\n    return 1.0 / ((((3.1415927410125732421875 * at) * ab) * _4794) * _4794);\n}\n\nfloat fa_lambda_ggx_aniso(float n, float t, float b, float at, float ab)\n{\n    return 0.5 * (sqrt(1.0 + (((((at * at) * t) * t) + (((ab * ab) * b) * b)) / max(n * n, 9.9999999392252902907785028219223e-09))) - 1.0);\n}\n\nfloat fa_v_ggx_aniso(float ndl, float ndv, float tdv, float bdv, float tdl, float bdl, float at, float ab)\n{\n    float param = ndv;\n    float param_1 = tdv;\n    float param_2 = bdv;\n    float param_3 = at;\n    float param_4 = ab;\n    float param_5 = ndl;\n    float param_6 = tdl;\n    float param_7 = bdl;\n    float param_8 = at;\n    float param_9 = ab;\n    return clamp(1.0 / ((4.0 * max(ndl * ndv, 9.9999997473787516355514526367188e-05)) * ((1.0 + fa_lambda_ggx_aniso(param, param_1, param_2, param_3, param_4)) + fa_lambda_ggx_aniso(param_5, param_6, param_7, param_8, param_9))), 0.0, 1.0);\n}\n\nvec3 fa_layers_light(FaLayers L, vec3 diffuse_color, vec3 f0, vec3 n, vec3 v, vec3 l, vec3 h, float ndl, float ndv, float ndh, float vdh, float alpha, float a2)\n{\n    float _4974 = step(9.9999997473787516355514526367188e-05, ndl);\n    float d_ggx;\n    float vis;\n    if (L.aniso != 0.0)\n    {\n        float param = ndh;\n        float param_1 = dot(L.t, h);\n        float param_2 = dot(L.b, h);\n        float param_3 = L.at;\n        float param_4 = L.ab;\n        d_ggx = fa_d_ggx_aniso(param, param_1, param_2, param_3, param_4);\n        float param_5 = ndl;\n        float param_6 = ndv;\n        float param_7 = dot(L.t, v);\n        float param_8 = dot(L.b, v);\n        float param_9 = dot(L.t, l);\n        float param_10 = dot(L.b, l);\n        float param_11 = L.at;\n        float param_12 = L.ab;\n        vis = fa_v_ggx_aniso(param_5, param_6, param_7, param_8, param_9, param_10, param_11, param_12);\n    }\n    else\n    {\n        float _5053 = ((ndh * ndh) * (a2 - 1.0)) + 1.0;\n        d_ggx = a2 / ((3.1415927410125732421875 * _5053) * _5053);\n        vis = 0.5 / max(mix((2.0 * ndl) * ndv, ndl + ndv, alpha), 9.9999997473787516355514526367188e-05);\n    }\n    vec3 base = diffuse_color + (((f0 + ((vec3(L.f90) - f0) * pow(clamp(1.0 - vdh, 0.0, 1.0), 5.0))) * ((d_ggx * vis) * 3.1415927410125732421875)) * _4974);\n    if (L.sheen_on)\n    {\n        float param_13 = L.sheen_alpha;\n        float param_14 = ndh;\n        float param_15 = ndl;\n        float param_16 = ndv;\n        base = (base * L.sheen_scale) + (L.sheen * (((fa_d_charlie(param_13, param_14) * fa_v_ashikhmin(param_15, param_16)) * 3.1415927410125732421875) * _4974));\n    }\n    vec3 result = base * (L.keep * ndl);\n    if (L.coat > 0.0)\n    {\n        FaLayers param_17 = L;\n        vec3 param_18 = l;\n        vec3 param_19 = h;\n        float param_20 = vdh;\n        result += vec3(fa_layers_coat(param_17, param_18, param_19, param_20));\n    }\n    return result;\n}\n\nvec2 fa_env_brdf(float rough, float ndv)\n{\n    vec4 _4184 = (vec4(-1.0, -0.0274999998509883880615234375, -0.572000026702880859375, 0.02199999988079071044921875) * rough) + vec4(1.0, 0.0425000004470348358154296875, 1.03999996185302734375, -0.039999999105930328369140625);\n    float _4187 = _4184.x;\n    return (vec2(-1.03999996185302734375, 1.03999996185302734375) * ((min(_4187 * _4187, exp2((-9.27999973297119140625) * ndv)) * _4187) + _4184.y)) + _4184.zw;\n}\n\nvec2 fa_oct_encode(vec3 d)\n{\n    vec3 _3443 = d / vec3(max((abs(d.x) + abs(d.y)) + abs(d.z), 9.9999999600419720025001879548654e-13));\n    float _3446 = _3443.x;\n    float _3448 = _3443.z;\n    vec2 e = vec2(_3446, _3448);\n    if (_3443.y < 0.0)\n    {\n        e = vec2((1.0 - abs(_3448)) * ((_3446 < 0.0) ? (-1.0) : 1.0), (1.0 - abs(_3446)) * ((_3448 < 0.0) ? (-1.0) : 1.0));\n    }\n    return e;\n}\n\nvec3 fa_probe_level(vec2 origin, float res, int lv, vec2 e)\n{\n    float _3495;\n    if (lv == 0)\n    {\n        _3495 = 0.0;\n    }\n    else\n    {\n        _3495 = res + 2.0;\n    }\n    float _3505;\n    if (lv == 0)\n    {\n        _3505 = 0.0;\n    }\n    else\n    {\n        _3505 = (res - (res / float(1 << (lv - 1)))) + (2.0 * float(lv - 1));\n    }\n    return textureLod(fa_probe_atlas_fa_env_smp, (((origin + vec2(_3495, _3505)) + vec2(1.0)) + (((e * 0.5) + vec2(0.5)) * (res / float(1 << lv)))) / fa_atlas_size(), 0.0).xyz;\n}\n\nvec3 fa_probe_radiance(vec2 origin, float res, vec3 d, float rough)\n{\n    float _3550;\n    if (res > 64.5)\n    {\n        _3550 = 5.0;\n    }\n    else\n    {\n        _3550 = (res > 32.5) ? 4.0 : 3.0;\n    }\n    float _3565 = clamp(rough, 0.0, 1.0) * (_3550 - 1.0);\n    int _3572 = int(min(floor(_3565), _3550 - 2.0));\n    float _3577 = _3565 - float(_3572);\n    vec3 param = d;\n    vec2 _3581 = fa_oct_encode(param);\n    vec2 param_1 = origin;\n    float param_2 = res;\n    int param_3 = _3572;\n    vec2 param_4 = _3581;\n    vec3 _3591 = fa_probe_level(param_1, param_2, param_3, param_4);\n    if (_3577 < 0.00200000009499490261077880859375)\n    {\n        return _3591;\n    }\n    vec2 param_5 = origin;\n    float param_6 = res;\n    int param_7 = _3572 + 1;\n    vec2 param_8 = _3581;\n    return mix(_3591, fa_probe_level(param_5, param_6, param_7, param_8), vec3(_3577));\n}\n\nvec3 fa_probe_box_dir(vec3 d, vec4 posw, vec4 bx, vec4 by, vec4 bz)\n{\n    if (posw.w < 0.5)\n    {\n        return d;\n    }\n    float _3661 = dot(bx.xyz, fa_world_pos) + bx.w;\n    float _3668 = dot(by.xyz, fa_world_pos) + by.w;\n    float _3675 = dot(bz.xyz, fa_world_pos) + bz.w;\n    float _3681 = dot(bx.xyz, d);\n    float _3685 = dot(by.xyz, d);\n    float _3689 = dot(bz.xyz, d);\n    float _3695;\n    if (_3681 > 9.9999999747524270787835121154785e-07)\n    {\n        _3695 = (1.0 - _3661) / _3681;\n    }\n    else\n    {\n        float _3709;\n        if (_3681 < (-9.9999999747524270787835121154785e-07))\n        {\n            _3709 = ((-1.0) - _3661) / _3681;\n        }\n        else\n        {\n            _3709 = 1000000015047466219876688855040.0;\n        }\n        _3695 = _3709;\n    }\n    float tx = _3695;\n    float _3726;\n    if (_3685 > 9.9999999747524270787835121154785e-07)\n    {\n        _3726 = (1.0 - _3668) / _3685;\n    }\n    else\n    {\n        float _3739;\n        if (_3685 < (-9.9999999747524270787835121154785e-07))\n        {\n            _3739 = ((-1.0) - _3668) / _3685;\n        }\n        else\n        {\n            _3739 = 1000000015047466219876688855040.0;\n        }\n        _3726 = _3739;\n    }\n    float ty = _3726;\n    float _3755;\n    if (_3689 > 9.9999999747524270787835121154785e-07)\n    {\n        _3755 = (1.0 - _3675) / _3689;\n    }\n    else\n    {\n        float _3768;\n        if (_3689 < (-9.9999999747524270787835121154785e-07))\n        {\n            _3768 = ((-1.0) - _3675) / _3689;\n        }\n        else\n        {\n            _3768 = 1000000015047466219876688855040.0;\n        }\n        _3755 = _3768;\n    }\n    float _3780 = tx;\n    float _3783 = (_3780 > 0.0) ? _3780 : 1000000015047466219876688855040.0;\n    tx = _3783;\n    float _3784 = ty;\n    float _3787 = (_3784 > 0.0) ? _3784 : 1000000015047466219876688855040.0;\n    ty = _3787;\n    float _3797 = min(_3783, min(_3787, (_3755 > 0.0) ? _3755 : 1000000015047466219876688855040.0));\n    if (_3797 > 100000001504746621987668885504.0)\n    {\n        return d;\n    }\n    vec3 _3813 = (fa_world_pos + (d * _3797)) - posw.xyz;\n    vec3 _3818;\n    if (dot(_3813, _3813) > 1.0000000133514319600180897396058e-10)\n    {\n        _3818 = normalize(_3813);\n    }\n    else\n    {\n        _3818 = d;\n    }\n    return _3818;\n}\n\nvec3 fa_probe_environment(vec4 tile, vec4 posw, vec4 bx, vec4 by, vec4 bz, inout vec3 d, float rough)\n{\n    vec3 param = d;\n    vec4 param_1 = posw;\n    vec4 param_2 = bx;\n    vec4 param_3 = by;\n    vec4 param_4 = bz;\n    d = fa_probe_box_dir(param, param_1, param_2, param_3, param_4);\n    vec2 param_5 = tile.xy;\n    float param_6 = tile.z;\n    vec3 param_7 = d;\n    float param_8 = rough;\n    return fa_probe_radiance(param_5, param_6, param_7, param_8);\n}\n\nvec3 fa_environment(vec3 d, float rough)\n{\n    float _3864 = (1.0 - fa_mesh_fs_params[42].w) - fa_mesh_fs_params[47].w;\n    vec3 outc = vec3(0.0);\n    if (_3864 > 0.0005000000237487256526947021484375)\n    {\n        vec3 base;\n        if (fa_mesh_fs_params[11].w > 0.5)\n        {\n            vec2 param = fa_mesh_fs_params[41].zw;\n            float param_1 = 128.0;\n            vec3 param_2 = d;\n            float param_3 = rough;\n            base = fa_probe_radiance(param, param_1, param_2, param_3);\n        }\n        else\n        {\n            float _3893 = rough * rough;\n            float _3924 = 0.60000002384185791015625 * _3893;\n            base = mix(mix(fa_mesh_fs_params[12].xyz * 0.550000011920928955078125, mix(fa_mesh_fs_params[12].xyz, fa_mesh_fs_params[11].xyz, vec3(pow(clamp(d.y * (1.0 - (0.699999988079071044921875 * _3893)), 0.0, 1.0), 0.550000011920928955078125))), vec3(smoothstep((-0.0500000007450580596923828125) - _3924, 0.0500000007450580596923828125 + _3924, d.y))), ((fa_mesh_fs_params[11].xyz + fa_mesh_fs_params[12].xyz) * 0.5) * 0.800000011920928955078125, vec3(_3893 * 0.60000002384185791015625));\n        }\n        outc = base * _3864;\n    }\n    if (fa_mesh_fs_params[42].w > 0.0)\n    {\n        vec4 param_4 = fa_mesh_fs_params[42];\n        vec4 param_5 = fa_mesh_fs_params[43];\n        vec4 param_6 = fa_mesh_fs_params[44];\n        vec4 param_7 = fa_mesh_fs_params[45];\n        vec4 param_8 = fa_mesh_fs_params[46];\n        vec3 param_9 = d;\n        float param_10 = rough;\n        vec3 _3983 = fa_probe_environment(param_4, param_5, param_6, param_7, param_8, param_9, param_10);\n        outc += (_3983 * fa_mesh_fs_params[42].w);\n    }\n    if (fa_mesh_fs_params[47].w > 0.0)\n    {\n        vec4 param_11 = fa_mesh_fs_params[47];\n        vec4 param_12 = fa_mesh_fs_params[48];\n        vec4 param_13 = fa_mesh_fs_params[49];\n        vec4 param_14 = fa_mesh_fs_params[50];\n        vec4 param_15 = fa_mesh_fs_params[51];\n        vec3 param_16 = d;\n        float param_17 = rough;\n        vec3 _4015 = fa_probe_environment(param_11, param_12, param_13, param_14, param_15, param_16, param_17);\n        outc += (_4015 * fa_mesh_fs_params[47].w);\n    }\n    return outc;\n}\n\nvec3 fa_layers_ibl(FaLayers L, vec3 n, vec3 v, vec3 f0, float roughness)\n{\n    vec3 rn = n;\n    if (L.aniso != 0.0)\n    {\n        vec3 _4661;\n        if (L.aniso >= 0.0)\n        {\n            _4661 = L.b;\n        }\n        else\n        {\n            _4661 = L.t;\n        }\n        rn = normalize(mix(n, cross(cross(_4661, v), _4661), vec3(abs(L.aniso))));\n    }\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05);\n    vec2 _4694 = fa_env_brdf(param, param_1);\n    vec3 param_2 = reflect(-v, rn);\n    float param_3 = roughness;\n    vec3 result = (fa_environment(param_2, param_3) * ((f0 * _4694.x) + (vec3(L.f90) * _4694.y))) * L.base_scale;\n    if (L.sheen_on)\n    {\n        vec3 param_4 = n;\n        float param_5 = L.sheen_rough;\n        result += ((L.sheen * (L.sheen_e * L.keep)) * fa_environment(param_4, param_5));\n    }\n    if (L.coat > 0.0)\n    {\n        float param_6 = L.coat_rough;\n        float param_7 = L.coat_ndv;\n        vec2 _4749 = fa_env_brdf(param_6, param_7);\n        vec3 param_8 = reflect(-v, L.nc);\n        float param_9 = L.coat_rough;\n        result += (fa_environment(param_8, param_9) * (L.coat * ((0.039999999105930328369140625 * _4749.x) + _4749.y)));\n    }\n    return result;\n}\n\nvec3 fa_sky_reflection(vec3 n, vec3 v, vec3 f0, float roughness)\n{\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05);\n    vec2 _4226 = fa_env_brdf(param, param_1);\n    vec3 param_2 = reflect(-v, n);\n    float param_3 = roughness;\n    return fa_environment(param_2, param_3) * ((f0 * _4226.x) + vec3(_4226.y));\n}\n\nvec2 fa_xm_size(int k)\n{\n    return max(floor(fa_mesh_fs_params[24].zw / vec2(exp2(float(k)))), vec2(1.0));\n}\n\nvec2 fa_xm_origin(int k)\n{\n    if (k == 0)\n    {\n        return vec2(0.0);\n    }\n    float y = 0.0;\n    for (int j = 1; j < k; j++)\n    {\n        int param = j;\n        y += fa_xm_size(param).y;\n    }\n    return vec2(fa_mesh_fs_params[24].z, y);\n}\n\nvec3 fa_xm_texel(vec2 size, vec2 origin, vec2 p)\n{\n    return texelFetch(fa_screen_tex_fa_shadow_smp, ivec2(origin + clamp(p, vec2(0.0), size - vec2(1.0))), 0).xyz;\n}\n\nvec3 fa_xm_level(int k, vec2 uv)\n{\n    int param = k;\n    vec2 _5451 = fa_xm_size(param);\n    int param_1 = k;\n    vec2 _5455 = fa_xm_origin(param_1);\n    vec2 _5461 = (uv * _5451) - vec2(0.5);\n    vec2 _5464 = fract(_5461);\n    vec2 _5467 = floor(_5461);\n    vec2 param_2 = _5451;\n    vec2 param_3 = _5455;\n    vec2 param_4 = _5467;\n    vec2 param_5 = _5451;\n    vec2 param_6 = _5455;\n    vec2 param_7 = _5467 + vec2(1.0, 0.0);\n    vec2 param_8 = _5451;\n    vec2 param_9 = _5455;\n    vec2 param_10 = _5467 + vec2(0.0, 1.0);\n    vec2 param_11 = _5451;\n    vec2 param_12 = _5455;\n    vec2 param_13 = _5467 + vec2(1.0);\n    vec3 _5509 = vec3(_5464.x);\n    return mix(mix(fa_xm_texel(param_2, param_3, param_4), fa_xm_texel(param_5, param_6, param_7), _5509), mix(fa_xm_texel(param_8, param_9, param_10), fa_xm_texel(param_11, param_12, param_13), _5509), vec3(_5464.y));\n}\n\nvec3 fa_xm_sample(vec2 uv, float lod)\n{\n    float _5528 = max(fa_mesh_fs_params[31].w - 1.0, 0.0);\n    float _5532 = clamp(lod, 0.0, _5528);\n    int _5536 = int(floor(_5532));\n    int param = _5536;\n    vec2 param_1 = uv;\n    vec3 c = fa_xm_level(param, param_1);\n    float _5546 = float(_5536);\n    float _5547 = _5532 - _5546;\n    bool _5549 = _5547 > 0.001000000047497451305389404296875;\n    bool _5556;\n    if (_5549)\n    {\n        _5556 = _5546 < _5528;\n    }\n    else\n    {\n        _5556 = _5549;\n    }\n    if (_5556)\n    {\n        int param_2 = _5536 + 1;\n        vec2 param_3 = uv;\n        c = mix(c, fa_xm_level(param_2, param_3), vec3(_5547));\n    }\n    return c;\n}\n\nvec3 fa_transmitted(Surface s, vec3 n, vec3 v, float roughness, vec3 f0, float f90, float keep, float tr, inout float blend)\n{\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05);\n    vec2 _5582 = fa_env_brdf(param, param_1);\n    vec3 through = ((vec3(1.0) - clamp((f0 * _5582.x) + (vec3(f90) * _5582.y), vec3(0.0), vec3(1.0))) * s.albedo) * (tr * keep);\n    float _5610 = max(s.thickness, 0.0);\n    bool _5615 = _5610 > 0.0;\n    if ((s.attenuation_distance > 0.0) && _5615)\n    {\n        through *= exp((-((-log(clamp(s.attenuation_color, vec3(9.9999997473787516355514526367188e-05), vec3(1.0)))) / vec3(s.attenuation_distance))) * _5610);\n    }\n    bool _5640 = fa_mesh_fs_params[30].w > 1.5;\n    bool _5647;\n    if (!_5640)\n    {\n        _5647 = fa_mesh_fs_params[30].w < 0.5;\n    }\n    else\n    {\n        _5647 = _5640;\n    }\n    if (_5647)\n    {\n        blend = clamp(dot(through, vec3(0.3333333432674407958984375)), 0.0, 0.980000019073486328125);\n        return vec3(0.0);\n    }\n    vec3 world = fa_world_pos;\n    if (_5615)\n    {\n        world += (refract(-v, n, 1.0 / max(s.ior, 1.0)) * _5610);\n    }\n    vec4 _5682 = vec4(world, 1.0);\n    float _5687 = dot(fa_mesh_fs_params[28], _5682);\n    vec2 uv = vec2(0.5);\n    if (_5687 > 9.9999997473787516355514526367188e-05)\n    {\n        vec2 _5705 = vec2(dot(fa_mesh_fs_params[26], _5682), dot(fa_mesh_fs_params[27], _5682)) / vec2(_5687);\n        float _5713;\n        if (fa_mesh_fs_params[24].y > 0.5)\n        {\n            _5713 = (_5705.y * 0.5) + 0.5;\n        }\n        else\n        {\n            _5713 = 0.5 - (_5705.y * 0.5);\n        }\n        uv = vec2((_5705.x * 0.5) + 0.5, _5713);\n    }\n    vec2 param_2 = clamp(uv, vec2(0.0), vec2(1.0));\n    float param_3 = (clamp(roughness, 0.0, 1.0) * clamp((2.0 * s.ior) - 2.0, 0.0, 1.0)) * max(fa_mesh_fs_params[31].w - 1.0, 0.0);\n    return through * fa_xm_sample(param_2, param_3);\n}\n\nvec3 fa_shadow_debug(vec3 color, vec3 world)\n{\n    if (fa_shadows[27].w < 0.5)\n    {\n        return color;\n    }\n    int _3246 = int(fa_shadows[25].x + 0.5);\n    float _3256 = dot(world - fa_shadows[27].xyz, fa_shadows[28].xyz);\n    vec3 tint_1 = vec3(0.3499999940395355224609375);\n    bool _3261 = _3246 > 0;\n    bool _3270;\n    if (_3261)\n    {\n        int param = _3246 - 1;\n        _3270 = _3256 <= fa_shadow_split_at(param);\n    }\n    else\n    {\n        _3270 = _3261;\n    }\n    if (_3270)\n    {\n        tint_1 = vec3(1.0, 0.1500000059604644775390625, 0.100000001490116119384765625);\n        bool _3276 = _3246 > 1;\n        bool _3283;\n        if (_3276)\n        {\n            _3283 = _3256 > fa_shadows[24].x;\n        }\n        else\n        {\n            _3283 = _3276;\n        }\n        if (_3283)\n        {\n            tint_1 = vec3(0.100000001490116119384765625, 0.89999997615814208984375, 0.20000000298023223876953125);\n        }\n        bool _3289 = _3246 > 2;\n        bool _3296;\n        if (_3289)\n        {\n            _3296 = _3256 > fa_shadows[24].y;\n        }\n        else\n        {\n            _3296 = _3289;\n        }\n        if (_3296)\n        {\n            tint_1 = vec3(0.1500000059604644775390625, 0.300000011920928955078125, 1.0);\n        }\n        bool _3302 = _3246 > 3;\n        bool _3309;\n        if (_3302)\n        {\n            _3309 = _3256 > fa_shadows[24].z;\n        }\n        else\n        {\n            _3309 = _3302;\n        }\n        if (_3309)\n        {\n            tint_1 = vec3(1.0, 0.89999997615814208984375, 0.100000001490116119384765625);\n        }\n    }\n    return mix(color, tint_1, vec3(0.550000011920928955078125));\n}\n\nvoid main()\n{\n    fa_inst_load();\n    vec3 _8035 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _8035 = -_8035;\n    }\n    vec3 _7330 = normalize(fa_mesh_fs_params[0].xyz - fa_world_pos);\n    vec3 param = fa_world_pos;\n    fa_cluster_begin(param);\n    SurfaceInput param_1 = SurfaceInput(fa_world_pos, _8035, fa_world_tangent, fa_uv, fa_vertex_color, _7330, gl_FrontFacing);\n    Surface _7338 = fa_standard_surface(param_1);\n    vec3 _8066 = _7338.albedo;\n    float _8067 = _7338.alpha;\n    vec3 _8068 = _7338.normal;\n    float _8069 = _7338.metallic;\n    float _8070 = _7338.roughness;\n    float _8071 = _7338.occlusion;\n    vec3 _8072 = _7338.emission;\n    float _8073 = _7338.clearcoat;\n    float _8074 = _7338.clearcoat_roughness;\n    vec3 _8075 = _7338.sheen_color;\n    float _8076 = _7338.sheen_roughness;\n    float _8077 = _7338.anisotropy;\n    float _8078 = _7338.anisotropy_rotation;\n    float _8079 = _7338.specular;\n    float _8080 = _7338.ior;\n    vec3 _8081 = _7338.specular_color;\n    float _8082 = _7338.transmission;\n    float _8083 = _7338.thickness;\n    vec3 _8084 = _7338.attenuation_color;\n    float _8085 = _7338.attenuation_distance;\n    SurfaceInput param_2 = SurfaceInput(fa_world_pos, _8035, fa_world_tangent, fa_uv, fa_vertex_color, _7330, gl_FrontFacing);\n    Surface param_3 = _7338;\n    surface(param_2, param_3);\n    _8066 = param_3.albedo;\n    _8067 = param_3.alpha;\n    _8068 = param_3.normal;\n    _8069 = param_3.metallic;\n    _8070 = param_3.roughness;\n    _8071 = param_3.occlusion;\n    _8072 = param_3.emission;\n    _8073 = param_3.clearcoat;\n    _8074 = param_3.clearcoat_roughness;\n    _8075 = param_3.sheen_color;\n    _8076 = param_3.sheen_roughness;\n    _8077 = param_3.anisotropy;\n    _8078 = param_3.anisotropy_rotation;\n    _8079 = param_3.specular;\n    _8080 = param_3.ior;\n    _8081 = param_3.specular_color;\n    _8082 = param_3.transmission;\n    _8083 = param_3.thickness;\n    _8084 = param_3.attenuation_color;\n    _8085 = param_3.attenuation_distance;\n    vec3 param_4 = fa_world_pos;\n    vec3 param_5 = _8035;\n    vec3 param_6 = param_3.albedo;\n    vec3 param_7 = param_3.normal;\n    fa_apply_decals(param_4, param_5, param_6, param_7);\n    _8066 = param_6;\n    _8068 = param_7;\n    float fa_tr_blend = 0.0;\n    vec3 result;\n    if (fa_mesh_fs_params[3].w > 0.5)\n    {\n        result = _8066;\n    }\n    else\n    {\n        vec3 _7378 = normalize(_8068);\n        float _7385 = clamp(_8069, 0.0, 1.0);\n        float _7389 = clamp(_8070, 0.0500000007450580596923828125, 1.0);\n        float _7393 = _7389 * _7389;\n        float _7397 = _7393 * _7393;\n        float _7402 = max(dot(_7378, _7330), 9.9999997473787516355514526367188e-05);\n        float _7408 = 1.0 - _7385;\n        float _7409 = clamp(_8082, 0.0, 1.0) * _7408;\n        vec3 _7418 = (_8066 * _7408) * (1.0 - _7409);\n        vec3 _7425 = mix(vec3(0.039999999105930328369140625), _8066, vec3(_7385));\n        vec3 f0 = _7425;\n        SurfaceInput param_8 = SurfaceInput(fa_world_pos, _8035, fa_world_tangent, fa_uv, fa_vertex_color, _7330, gl_FrontFacing);\n        Surface param_9 = Surface(_8066, _8067, _8068, _8069, _8070, _8071, _8072, _8073, _8074, _8075, _8076, _8077, _8078, _8079, _8080, _8081, _8082, _8083, _8084, _8085);\n        vec3 param_10 = _7378;\n        vec3 param_11 = _7330;\n        float param_12 = _7385;\n        float param_13 = _7389;\n        vec3 param_14 = _7425;\n        FaLayers _7441 = fa_layers_setup(param_8, param_9, param_10, param_11, param_12, param_13, param_14);\n        f0 = param_14;\n        vec3 param_15 = _7378;\n        vec3 lit = (fa_indirect_diffuse(param_15) * _7418) * _8071;\n        if (_7441.on)\n        {\n            lit *= _7441.base_scale;\n        }\n        int _7463 = fa_cl_ndir + fa_cl_local;\n        for (int ln = 0; ln < _7463; ln++)\n        {\n            int param_16 = ln;\n            int _7476 = fa_cl_light(param_16);\n            int param_17 = _7476;\n            if (fa_baked_keep(param_17) <= 0.0)\n            {\n                continue;\n            }\n            int param_18 = _7476;\n            vec3 param_19 = fa_world_pos;\n            vec3 param_20 = _8035;\n            LightSample _7492 = fa_light_shadowed(param_18, param_19, param_20);\n            float _7500 = max(dot(_7378, _7492.direction), 0.0);\n            float _7506 = _7492.attenuation * _7492.shadow;\n            vec3 _7511 = normalize(_7492.direction + _7330);\n            float _7516 = max(dot(_7378, _7511), 0.0);\n            float _7521 = max(dot(_7330, _7511), 0.0);\n            bool _7528;\n            if (fa_light_is_area)\n            {\n                _7528 = !_7441.on;\n            }\n            else\n            {\n                _7528 = fa_light_is_area;\n            }\n            if (_7528)\n            {\n                int param_21 = _7476;\n                vec3 param_22 = fa_world_pos;\n                vec3 param_23 = _7378;\n                vec3 param_24 = _7330;\n                vec3 param_25 = _7418;\n                vec3 param_26 = f0;\n                float param_27 = 1.0;\n                float param_28 = _7389;\n                float param_29 = _7402;\n                float param_30 = _7506;\n                lit += fa_area_shade(param_21, param_22, param_23, param_24, param_25, param_26, param_27, param_28, param_29, param_30);\n            }\n            else\n            {\n                if (fa_light_is_area)\n                {\n                    FaLayers param_31 = _7441;\n                    int param_32 = _7476;\n                    vec3 param_33 = fa_world_pos;\n                    vec3 param_34 = _7378;\n                    vec3 param_35 = _7330;\n                    vec3 param_36 = _7492.direction;\n                    vec3 param_37 = _7418;\n                    vec3 param_38 = f0;\n                    float param_39 = _7389;\n                    float param_40 = _7402;\n                    float param_41 = _7506;\n                    lit += fa_area_layers(param_31, param_32, param_33, param_34, param_35, param_36, param_37, param_38, param_39, param_40, param_41);\n                }\n                else\n                {\n                    if (_7441.on)\n                    {\n                        FaLayers param_42 = _7441;\n                        vec3 param_43 = _7418;\n                        vec3 param_44 = f0;\n                        vec3 param_45 = _7378;\n                        vec3 param_46 = _7330;\n                        vec3 param_47 = _7492.direction;\n                        vec3 param_48 = _7511;\n                        float param_49 = _7500;\n                        float param_50 = _7402;\n                        float param_51 = _7516;\n                        float param_52 = _7521;\n                        float param_53 = _7393;\n                        float param_54 = _7397;\n                        int param_55 = _7476;\n                        lit += (fa_layers_light(param_42, param_43, param_44, param_45, param_46, param_47, param_48, param_49, param_50, param_51, param_52, param_53, param_54) * ((fa_light_rgb(param_55) * fa_light_tint) * _7506));\n                    }\n                    else\n                    {\n                        float _7634 = ((_7516 * _7516) * (_7397 - 1.0)) + 1.0;\n                        int param_56 = _7476;\n                        lit += (((_7418 + (((f0 + ((vec3(1.0) - f0) * pow(1.0 - _7521, 5.0))) * (((_7397 / ((3.1415927410125732421875 * _7634) * _7634)) * (0.5 / max(mix((2.0 * _7500) * _7402, _7500 + _7402, _7393), 9.9999997473787516355514526367188e-05))) * 3.1415927410125732421875)) * step(9.9999997473787516355514526367188e-05, _7500))) * (fa_light_rgb(param_56) * fa_light_tint)) * (_7500 * _7506));\n                    }\n                }\n            }\n        }\n        if (_7441.on)\n        {\n            FaLayers param_57 = _7441;\n            vec3 param_58 = _7378;\n            vec3 param_59 = _7330;\n            vec3 param_60 = f0;\n            float param_61 = _7389;\n            lit += (fa_layers_ibl(param_57, param_58, param_59, param_60, param_61) * _8071);\n        }\n        else\n        {\n            vec3 param_62 = _7378;\n            vec3 param_63 = _7330;\n            vec3 param_64 = f0;\n            float param_65 = _7389;\n            lit += (fa_sky_reflection(param_62, param_63, param_64, param_65) * _8071);\n        }\n        if (_7409 > 0.0)\n        {\n            float _7732;\n            if (_7441.on)\n            {\n                _7732 = _7441.f90;\n            }\n            else\n            {\n                _7732 = 1.0;\n            }\n            float _7740;\n            if (_7441.on)\n            {\n                _7740 = _7441.base_scale;\n            }\n            else\n            {\n                _7740 = 1.0;\n            }\n            Surface param_66 = Surface(_8066, _8067, _8068, _8069, _8070, _8071, _8072, _8073, _8074, _8075, _8076, _8077, _8078, _8079, _8080, _8081, _8082, _8083, _8084, _8085);\n            vec3 param_67 = _7378;\n            vec3 param_68 = _7330;\n            float param_69 = _7389;\n            vec3 param_70 = f0;\n            float param_71 = _7732;\n            float param_72 = _7740;\n            float param_73 = _7409;\n            float param_74 = fa_tr_blend;\n            vec3 _7764 = fa_transmitted(param_66, param_67, param_68, param_69, param_70, param_71, param_72, param_73, param_74);\n            fa_tr_blend = param_74;\n            lit += _7764;\n        }\n        result = lit;\n    }\n    vec3 _7771 = result;\n    vec3 _7772 = _7771 + _8072;\n    result = _7772;\n    vec3 param_75 = _7772;\n    vec3 param_76 = fa_world_pos;\n    result = fa_shadow_debug(param_75, param_76);\n    bool _7781 = fa_mesh_fs_params[7].w > 0.0;\n    bool _7788;\n    if (!_7781)\n    {\n        _7788 = fa_mesh_fs_params[8].y > 0.0;\n    }\n    else\n    {\n        _7788 = _7781;\n    }\n    if (_7788)\n    {\n        vec3 _7797 = fa_world_pos - fa_mesh_fs_params[0].xyz;\n        float _7803 = dot(_7797, fa_mesh_fs_params[9].xyz);\n        bool _7807 = fa_mesh_fs_params[9].w > 0.5;\n        float _7808;\n        if (_7807)\n        {\n            _7808 = _7803;\n        }\n        else\n        {\n            _7808 = length(_7797);\n        }\n        float _7820 = _7808 - fa_mesh_fs_params[8].x;\n        if (_7820 > 0.0)\n        {\n            float _7829 = fa_mesh_fs_params[7].w * _7820;\n            float tau = _7829 * _7829;\n            if (fa_mesh_fs_params[8].y > 0.0)\n            {\n                float _7845;\n                if (_7807)\n                {\n                    _7845 = fa_world_pos.y - (fa_mesh_fs_params[9].y * _7803);\n                }\n                else\n                {\n                    _7845 = fa_mesh_fs_params[0].y;\n                }\n                float _7866 = mix(_7845, fa_world_pos.y, clamp(fa_mesh_fs_params[8].x / _7808, 0.0, 1.0));\n                float _7870 = fa_world_pos.y - _7866;\n                float _7875 = _7866 - fa_mesh_fs_params[8].z;\n                float _7880 = fa_world_pos.y - fa_mesh_fs_params[8].z;\n                bool _7883 = _7875 <= 0.0;\n                bool _7884 = !_7883;\n                bool _7890;\n                if (_7884)\n                {\n                    _7890 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _7890 = _7883;\n                }\n                float _7891;\n                if (_7890)\n                {\n                    _7891 = fa_mesh_fs_params[8].y;\n                }\n                else\n                {\n                    _7891 = fa_mesh_fs_params[8].y * exp(-min(fa_mesh_fs_params[8].w * _7875, 80.0));\n                }\n                bool _7918;\n                if (_7884)\n                {\n                    _7918 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _7918 = _7883;\n                }\n                float _7919;\n                if (_7918)\n                {\n                    _7919 = fa_mesh_fs_params[8].y * _7875;\n                }\n                else\n                {\n                    _7919 = (fa_mesh_fs_params[8].y * (1.0 - exp(-min(fa_mesh_fs_params[8].w * _7875, 80.0)))) / fa_mesh_fs_params[8].w;\n                }\n                bool _7944 = _7880 <= 0.0;\n                bool _7951;\n                if (!_7944)\n                {\n                    _7951 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _7951 = _7944;\n                }\n                float _7952;\n                if (_7951)\n                {\n                    _7952 = fa_mesh_fs_params[8].y * _7880;\n                }\n                else\n                {\n                    _7952 = (fa_mesh_fs_params[8].y * (1.0 - exp(-min(fa_mesh_fs_params[8].w * _7880, 80.0)))) / fa_mesh_fs_params[8].w;\n                }\n                float _7979;\n                if (abs(_7870) < 0.001000000047497451305389404296875)\n                {\n                    _7979 = _7891;\n                }\n                else\n                {\n                    _7979 = (_7952 - _7919) / _7870;\n                }\n                tau += (_7820 * max(_7979, 0.0));\n            }\n            result = mix(result, fa_mesh_fs_params[7].xyz, vec3(clamp(1.0 - exp(-clamp(tau, 0.0, 80.0)), 0.0, 1.0)));\n        }\n    }\n    if (fa_tr_blend > 0.0)\n    {\n        float _8015 = 1.0 - fa_tr_blend;\n        result /= vec3(_8015);\n        _8067 *= _8015;\n    }\n    fa_frag_color = vec4(result, _8067);\n}\n\n",
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
            "size": 832,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_643",
            "glsl_uniforms": [
              {
                "type": "vec4",
                "array_count": 52,
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
            "inst_name": "_2310",
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
            "inst_name": "_6898",
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
      "fs": "#version 430\n\nstruct SurfaceInput\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 vertex_color;\n    vec3 view_dir;\n    bool front_facing;\n};\n\nstruct LightSample\n{\n    vec3 direction;\n    vec3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct Surface\n{\n    vec3 albedo;\n    float alpha;\n    vec3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    vec3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    vec3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    vec3 specular_color;\n    float transmission;\n    float thickness;\n    vec3 attenuation_color;\n    float attenuation_distance;\n};\n\nstruct FaLayers\n{\n    bool on;\n    float f90;\n    float keep;\n    float base_scale;\n    float coat;\n    float coat_rough;\n    float coat_alpha;\n    float coat_a2;\n    vec3 nc;\n    float coat_ndv;\n    bool sheen_on;\n    vec3 sheen;\n    float sheen_rough;\n    float sheen_alpha;\n    float sheen_scale;\n    float sheen_e;\n    float aniso;\n    vec3 t;\n    vec3 b;\n    float at;\n    float ab;\n};\n\nconst float _4326[63] = float[](1.0, 1.0, 1.0, 0.4790000021457672119140625, 0.11699999868869781494140625, 0.01200000010430812835693359375, 0.0, 0.0, 0.0, 1.0, 1.0, 1.0, 0.578000009059906005859375, 0.19300000369548797607421875, 0.0350000001490116119384765625, 0.0030000000260770320892333984375, 0.0, 0.0, 1.0, 1.0, 1.0, 0.6740000247955322265625, 0.3459999859333038330078125, 0.1319999992847442626953125, 0.032999999821186065673828125, 0.0040000001899898052215576171875, 0.0, 0.971000015735626220703125, 0.954999983310699462890625, 0.828999996185302734375, 0.63999998569488525390625, 0.42599999904632568359375, 0.24500000476837158203125, 0.115000002086162567138671875, 0.037000000476837158203125, 0.0030000000260770320892333984375, 0.7469999790191650390625, 0.737999975681304931640625, 0.670000016689300537109375, 0.563000023365020751953125, 0.4309999942779541015625, 0.3039999902248382568359375, 0.1940000057220458984375, 0.1019999980926513671875, 0.0309999994933605194091796875, 0.614000022411346435546875, 0.609000027179718017578125, 0.566999971866607666015625, 0.499000012874603271484375, 0.412000000476837158203125, 0.32400000095367431640625, 0.240999996662139892578125, 0.162000000476837158203125, 0.087999999523162841796875, 0.538999974727630615234375, 0.535000026226043701171875, 0.505999982357025146484375, 0.4569999873638153076171875, 0.393999993801116943359375, 0.328999996185302734375, 0.2660000026226043701171875, 0.203999996185302734375, 0.14200000464916229248046875);\n\nuniform vec4 fa_mesh_fs_params[52];\nuniform vec4 fa_shadows[30];\nuniform vec4 fa_material[1];\nlayout(binding = 0) uniform sampler2D fa_light_tex_fa_shadow_smp;\nlayout(binding = 1) uniform sampler2D fa_tex_fa_smp;\nlayout(binding = 2) uniform sampler2D fa_normal_tex_fa_smp;\nlayout(binding = 3) uniform sampler2D fa_mr_tex_fa_smp;\nlayout(binding = 4) uniform sampler2D fa_occlusion_tex_fa_smp;\nlayout(binding = 5) uniform sampler2D fa_emissive_tex_fa_smp;\nlayout(binding = 6) uniform sampler2D fa_decal_tex_fa_env_smp;\nlayout(binding = 7) uniform sampler2D fa_lightmap_fa_env_smp;\nlayout(binding = 8) uniform sampler2D fa_probe_atlas_fa_env_smp;\nlayout(binding = 9) uniform sampler2D fa_light_atlas_fa_env_smp;\nlayout(binding = 10) uniform sampler2D fa_shadow_tex_fa_shadow_smp;\nlayout(binding = 11) uniform sampler2D fa_screen_tex_fa_shadow_smp;\n\nlayout(location = 2) in vec3 fa_world_pos;\nlayout(location = 7) in vec3 fa_lm;\nlayout(location = 0) flat in vec4 fa_inst_v0;\nlayout(location = 1) flat in vec4 fa_inst_v1;\nlayout(location = 3) in vec3 fa_world_normal;\nlayout(location = 4) in vec4 fa_world_tangent;\nlayout(location = 5) in vec2 fa_uv;\nlayout(location = 6) in vec4 fa_vertex_color;\nlayout(location = 0) out vec4 fa_frag_color;\nvec3 fa_light_tint;\nbool fa_light_is_area;\nint fa_cl_ndir;\nint fa_cl_slot;\nint fa_cl_local;\nfloat raise;\nvec4 tint;\n\nvoid fa_instance_unpack(vec4 fa_d0, vec4 fa_d1, vec4 fa_d2)\n{\n    raise = fa_d0.x;\n    tint = fa_d1;\n}\n\nvoid fa_inst_load()\n{\n    vec4 param = fa_inst_v0;\n    vec4 param_1 = fa_inst_v1;\n    vec4 param_2 = vec4(0.0);\n    fa_instance_unpack(param, param_1, param_2);\n}\n\nvec4 fa_light_texel(int t)\n{\n    return texelFetch(fa_light_tex_fa_shadow_smp, ivec2(t & 1023, t >> 10), 0);\n}\n\nvec4 fa_cluster_texel(vec3 world_pos)\n{\n    bool _1581 = fa_mesh_fs_params[19].x < 0.0;\n    bool _1588;\n    if (!_1581)\n    {\n        _1588 = fa_mesh_fs_params[19].w < 1.0;\n    }\n    else\n    {\n        _1588 = _1581;\n    }\n    bool _1596;\n    if (!_1588)\n    {\n        _1596 = fa_mesh_fs_params[18].x < 1.0;\n    }\n    else\n    {\n        _1596 = _1588;\n    }\n    bool _1603;\n    if (!_1596)\n    {\n        _1603 = fa_mesh_fs_params[18].y < 1.0;\n    }\n    else\n    {\n        _1603 = _1596;\n    }\n    bool _1610;\n    if (!_1603)\n    {\n        _1610 = fa_mesh_fs_params[19].y < 1.0;\n    }\n    else\n    {\n        _1610 = _1603;\n    }\n    if (_1610)\n    {\n        return vec4(0.0);\n    }\n    vec4 _1620 = vec4(world_pos, 1.0);\n    float _1626 = dot(fa_mesh_fs_params[16], _1620);\n    if (!(_1626 > 9.9999999747524270787835121154785e-07))\n    {\n        return vec4(0.0);\n    }\n    vec2 _1648 = vec2(dot(fa_mesh_fs_params[14], _1620), dot(fa_mesh_fs_params[15], _1620)) / vec2(_1626);\n    int _1652 = int(fa_mesh_fs_params[18].x);\n    int _1656 = int(fa_mesh_fs_params[18].y);\n    int param = (int(fa_mesh_fs_params[19].x) + (((clamp(int(floor(log2(max(dot(fa_mesh_fs_params[17].xyz, world_pos) + fa_mesh_fs_params[17].w, fa_mesh_fs_params[18].w) / fa_mesh_fs_params[18].w) * fa_mesh_fs_params[18].z)), 0, int(fa_mesh_fs_params[19].y) - 1) * _1656) + clamp(int(floor(((_1648.y * 0.5) + 0.5) * fa_mesh_fs_params[18].y)), 0, _1656 - 1)) * _1652)) + clamp(int(floor(((_1648.x * 0.5) + 0.5) * fa_mesh_fs_params[18].x)), 0, _1652 - 1);\n    return fa_light_texel(param);\n}\n\nivec2 fa_cluster_lookup(vec3 world_pos)\n{\n    vec3 param = world_pos;\n    vec4 _1732 = fa_cluster_texel(param);\n    return ivec2(int(_1732.x), int(_1732.y));\n}\n\nvoid fa_cluster_begin(vec3 world_pos)\n{\n    fa_cl_ndir = int(fa_mesh_fs_params[19].z);\n    vec3 param = world_pos;\n    ivec2 _5787 = fa_cluster_lookup(param);\n    fa_cl_slot = _5787.x;\n    fa_cl_local = _5787.y;\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nvec3 fa_linear_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_tex_fix(inout vec3 c, float mode)\n{\n    if (mode > 1.5)\n    {\n        vec3 param = c;\n        vec3 _6950 = fa_linear_to_srgb(param);\n        c = _6950;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            vec3 param_1 = c;\n            vec3 _6958 = fa_srgb_to_linear(param_1);\n            c = _6958;\n        }\n    }\n    return c;\n}\n\nvec3 fa_tangent_normal(SurfaceInput i, vec3 m)\n{\n    vec3 _525;\n    if (i.front_facing)\n    {\n        _525 = i.world_normal;\n    }\n    else\n    {\n        _525 = -i.world_normal;\n    }\n    vec3 _549 = normalize(i.world_tangent.xyz - (_525 * dot(_525, i.world_tangent.xyz)));\n    vec3 _576 = normalize(((_549 * m.x) + ((cross(_525, _549) * i.world_tangent.w) * m.y)) + (_525 * m.z));\n    vec3 _579;\n    if (i.front_facing)\n    {\n        _579 = _576;\n    }\n    else\n    {\n        _579 = -_576;\n    }\n    return _579;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    vec4 base_t = texture(fa_tex_fa_smp, i.uv);\n    float param = fa_mesh_fs_params[6].w;\n    float param_1 = 1.0;\n    vec3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    vec3 _6989 = fa_tex_fix(param_2, param_3);\n    vec4 _8612 = base_t;\n    _8612.x = _6989.x;\n    _8612.y = _6989.y;\n    _8612.z = _6989.z;\n    base_t = _8612;\n    vec4 _7003 = (_8612 * fa_mesh_fs_params[2]) * i.vertex_color;\n    vec3 _8396 = i.world_normal;\n    if (fa_mesh_fs_params[6].z > 0.5)\n    {\n        float param_4 = fa_mesh_fs_params[6].w;\n        float param_5 = 16.0;\n        vec3 param_6 = texture(fa_normal_tex_fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        vec3 _7035 = fa_tex_fix(param_6, param_7);\n        vec3 _7038 = (_7035 * 2.0) - vec3(1.0);\n        vec2 _7043 = _7038.xy * fa_mesh_fs_params[6].x;\n        vec3 _8620 = _7038;\n        _8620.x = _7043.x;\n        _8620.y = _7043.y;\n        SurfaceInput param_8 = i;\n        vec3 param_9 = _8620;\n        _8396 = fa_tangent_normal(param_8, param_9);\n    }\n    vec4 mrt = texture(fa_mr_tex_fa_smp, i.uv);\n    float param_10 = fa_mesh_fs_params[6].w;\n    float param_11 = 64.0;\n    vec3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    vec3 _7071 = fa_tex_fix(param_12, param_13);\n    vec4 _8623 = mrt;\n    _8623.x = _7071.x;\n    _8623.y = _7071.y;\n    _8623.z = _7071.z;\n    mrt = _8623;\n    vec4 _7099 = texture(fa_occlusion_tex_fa_smp, i.uv);\n    float param_14 = fa_mesh_fs_params[6].w;\n    float param_15 = 256.0;\n    vec3 param_16 = _7099.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    vec3 _7110 = fa_tex_fix(param_16, param_17);\n    float param_18 = fa_mesh_fs_params[6].w;\n    float param_19 = 4.0;\n    vec3 param_20 = texture(fa_emissive_tex_fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    vec3 _7140 = fa_tex_fix(param_20, param_21);\n    float _8401 = fa_mesh_fs_params[20].x;\n    float _8402 = fa_mesh_fs_params[20].y;\n    float _8405 = fa_mesh_fs_params[20].z;\n    float _8404 = fa_mesh_fs_params[21].w;\n    float _8407 = fa_mesh_fs_params[22].x;\n    if (fa_mesh_fs_params[22].z > 0.5)\n    {\n        if (mod(fa_mesh_fs_params[22].z, 2.0) > 0.5)\n        {\n            _8401 *= _7110.y;\n            _8402 *= _7110.z;\n            _8404 *= _7099.w;\n        }\n        if (fa_mesh_fs_params[22].z > 1.5)\n        {\n            _8405 *= mrt.x;\n            _8407 *= mrt.w;\n        }\n    }\n    return Surface(_7003.xyz, _7003.w, _8396, clamp(fa_mesh_fs_params[5].x * _7071.z, 0.0, 1.0), clamp(fa_mesh_fs_params[5].y * _7071.y, 0.0500000007450580596923828125, 1.0), 1.0 + (fa_mesh_fs_params[6].y * (_7110.x - 1.0)), fa_mesh_fs_params[3].xyz + (fa_mesh_fs_params[4].xyz * _7140), _8401, _8402, fa_mesh_fs_params[21].xyz, _8404, _8405, fa_mesh_fs_params[20].w, _8407, fa_mesh_fs_params[22].y, fa_mesh_fs_params[23].xyz, fa_mesh_fs_params[30].x, fa_mesh_fs_params[30].y, fa_mesh_fs_params[31].xyz, fa_mesh_fs_params[30].z);\n}\n\nvoid surface(SurfaceInput i, inout Surface s)\n{\n    s.emission += ((tint.xyz * tint.w) * fa_material[0].x);\n}\n\nvec4 fa_decal_tile(vec4 rect, vec2 uv, vec2 atlas, vec2 ddx, vec2 ddy)\n{\n    vec2 _1812 = rect.zw - rect.xy;\n    vec2 _1816 = _1812 * atlas;\n    vec2 _1820 = ddx * _1816;\n    vec2 _1824 = ddy * _1816;\n    return textureLod(fa_decal_tex_fa_env_smp, rect.xy + (clamp(uv, vec2(0.0), vec2(1.0)) * _1812), clamp(0.5 * log2(max(max(dot(_1820, _1820), dot(_1824, _1824)), 9.9999999392252902907785028219223e-09)), 0.0, 4.0));\n}\n\nvec3 fa_dc_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_dc_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvoid fa_apply_decals(vec3 world_pos, vec3 geo_normal, inout vec3 albedo, inout vec3 normal)\n{\n    bool _1857 = fa_mesh_fs_params[10].y < 0.5;\n    bool _1864;\n    if (!_1857)\n    {\n        _1864 = fa_mesh_fs_params[10].w < 0.5;\n    }\n    else\n    {\n        _1864 = _1857;\n    }\n    if (_1864)\n    {\n        return;\n    }\n    vec3 _1870 = dFdx(world_pos);\n    vec3 _1873 = dFdy(world_pos);\n    vec3 param = world_pos;\n    vec4 _1877 = fa_cluster_texel(param);\n    int _1881 = int(_1877.w);\n    if (_1881 < 1)\n    {\n        return;\n    }\n    int _1891 = int(fa_mesh_fs_params[10].y + 0.5);\n    int param_1 = _1891;\n    vec4 _1895 = fa_light_texel(param_1);\n    vec2 _1898 = _1895.yz;\n    int _1902 = int(_1895.w);\n    int param_2 = _1891 + 1;\n    vec4 _1907 = fa_light_texel(param_2);\n    float _1908 = _1907.x;\n    int _1914 = int(fa_mesh_fs_params[10].w + 0.5) - 1;\n    int _1918 = int(_1877.z);\n    vec3 _2183;\n    for (int k = 0; k < _1881; k++)\n    {\n        int _1931 = _1918 + k;\n        int param_3 = _1902 + (_1931 >> 2);\n        int _1948 = (_1891 + 2) + (int(fa_light_texel(param_3)[_1931 & 3]) * 7);\n        int param_4 = _1948 + 6;\n        vec4 _1953 = fa_light_texel(param_4);\n        if (((int(_1953.w + 0.5) >> _1914) & 1) == 0)\n        {\n            continue;\n        }\n        int param_5 = _1948;\n        vec4 _1968 = fa_light_texel(param_5);\n        int param_6 = _1948 + 1;\n        vec4 _1973 = fa_light_texel(param_6);\n        int param_7 = _1948 + 2;\n        vec4 _1978 = fa_light_texel(param_7);\n        vec3 _1981 = _1968.xyz;\n        float _1986 = dot(_1981, world_pos) + _1968.w;\n        vec3 _1988 = _1973.xyz;\n        float _1993 = dot(_1988, world_pos) + _1973.w;\n        vec3 _1995 = _1978.xyz;\n        float _2000 = dot(_1995, world_pos) + _1978.w;\n        bool _2005 = abs(_1986) > 0.5;\n        bool _2013;\n        if (!_2005)\n        {\n            _2013 = abs(_1993) > 0.5;\n        }\n        else\n        {\n            _2013 = _2005;\n        }\n        bool _2021;\n        if (!_2013)\n        {\n            _2021 = abs(_2000) > 0.5;\n        }\n        else\n        {\n            _2021 = _2013;\n        }\n        if (_2021)\n        {\n            continue;\n        }\n        float _2036 = clamp(dot(geo_normal, normalize(_1995)) * _1953.z, 0.0, 1.0);\n        if (_2036 <= 0.0)\n        {\n            continue;\n        }\n        float _2056 = (clamp((0.5 - abs(_2000)) * 10.0, 0.0, 1.0) * _2036) * _1953.x;\n        vec2 _2064 = vec2(_1986 + 0.5, 0.5 - _1993);\n        vec2 _2074 = vec2(dot(_1981, _1870), dot(_1988, _1870));\n        vec2 _2084 = vec2(dot(_1981, _1873), dot(_1988, _1873));\n        int param_8 = _1948 + 5;\n        vec4 _2089 = fa_light_texel(param_8);\n        int param_9 = _1948 + 3;\n        vec4 _2094 = fa_light_texel(param_9);\n        int param_10 = _1948 + 4;\n        vec4 _2099 = fa_light_texel(param_10);\n        float tex_a = 1.0;\n        vec3 col = _2089.xyz;\n        bool _2109 = _2094.z > _2094.x;\n        if (_2109)\n        {\n            vec4 param_11 = _2094;\n            vec2 param_12 = _2064;\n            vec2 param_13 = _1898;\n            vec2 param_14 = _2074;\n            vec2 param_15 = _2084;\n            vec4 tx = fa_decal_tile(param_11, param_12, param_13, param_14, param_15);\n            if ((_1908 > 0.5) && (_1908 < 1.5))\n            {\n                vec3 param_16 = tx.xyz;\n                vec3 _2135 = fa_dc_to_linear(param_16);\n                vec4 _8484 = tx;\n                _8484.x = _2135.x;\n                _8484.y = _2135.y;\n                _8484.z = _2135.z;\n                tx = _8484;\n            }\n            col *= tx.xyz;\n            tex_a = tx.w;\n        }\n        albedo = mix(albedo, col, vec3(clamp((_2056 * tex_a) * _2089.w, 0.0, 1.0)));\n        if (_2099.z > _2099.x)\n        {\n            vec4 param_17 = _2099;\n            vec2 param_18 = _2064;\n            vec2 param_19 = _1898;\n            vec2 param_20 = _2074;\n            vec2 param_21 = _2084;\n            vec4 _2179 = fa_decal_tile(param_17, param_18, param_19, param_20, param_21);\n            if (_1908 > 1.5)\n            {\n                vec3 param_22 = _2179.xyz;\n                vec3 _2189 = fa_dc_to_srgb(param_22);\n                _2183 = _2189;\n            }\n            else\n            {\n                _2183 = _2179.xyz;\n            }\n            vec3 _2198 = (_2183 * 2.0) - vec3(1.0);\n            vec2 _2203 = _2198.xy * _1953.y;\n            vec3 _2225 = (normalize(_1981) * _2203.x) + (normalize(_1988) * _2203.y);\n            vec3 _2228 = normalize(normal);\n            normal = normalize(mix(_2228, normalize((_2228 * max(_2198.z, 0.0500000007450580596923828125)) + (_2225 - (_2228 * dot(_2228, _2225)))), vec3(clamp(_2056 * (_2109 ? tex_a : 1.0), 0.0, 1.0))));\n        }\n    }\n}\n\nfloat fa_sheen_albedo(float ndv, float rough)\n{\n    float _4252 = min(sqrt(max(rough - 0.100000001490116119384765625, 0.0) * 1.111111164093017578125) * 6.0, 5.999000072479248046875);\n    float _4259 = min(sqrt(clamp(ndv, 0.0, 1.0)) * 8.0, 7.999000072479248046875);\n    int _4262 = int(_4252);\n    int _4265 = int(_4259);\n    float _4275 = _4259 - float(_4265);\n    int _4330 = (_4262 * 9) + _4265;\n    int _4350 = ((_4262 + 1) * 9) + _4265;\n    return mix(mix(_4326[_4330], _4326[_4330 + 1], _4275), mix(_4326[_4350], _4326[_4350 + 1], _4275), _4252 - float(_4262));\n}\n\nFaLayers fa_layers_setup(SurfaceInput i, Surface s, vec3 n, vec3 v, float metallic, float roughness, inout vec3 f0)\n{\n    bool _8319 = false;\n    float _8320 = 1.0;\n    float _8321 = 1.0;\n    float _8322 = 1.0;\n    float _8323 = 0.0;\n    float _8324 = 0.0;\n    float _8325 = 0.0;\n    float _8326 = 0.0;\n    float _8328 = 1.0;\n    bool _8329 = false;\n    vec3 _8330 = vec3(0.0);\n    float _8331 = 1.0;\n    float _8332 = 1.0;\n    float _8333 = 1.0;\n    float _8334 = 0.0;\n    float _8335 = 0.0;\n    vec3 _8336 = vec3(1.0, 0.0, 0.0);\n    vec3 _8337 = vec3(0.0, 0.0, 1.0);\n    float _8338 = 1.0;\n    float _8339 = 1.0;\n    float _4401 = clamp(s.specular, 0.0, 1.0);\n    float _4405 = clamp(s.ior, 1.0, 3.0);\n    bool _4410 = (_4401 != 1.0) || (_4405 != 1.5);\n    bool _4419;\n    if (!_4410)\n    {\n        _4419 = any(notEqual(s.specular_color, vec3(1.0)));\n    }\n    else\n    {\n        _4419 = _4410;\n    }\n    if (_4419)\n    {\n        float _4427 = (_4405 - 1.0) / (_4405 + 1.0);\n        f0 = mix(min(vec3(_4427 * _4427) * max(s.specular_color, vec3(0.0)), vec3(1.0)) * _4401, s.albedo, vec3(metallic));\n        _8320 = mix(_4401, 1.0, metallic);\n        _8319 = true;\n    }\n    float _4454 = clamp(s.clearcoat, 0.0, 1.0);\n    if (_4454 > 0.0)\n    {\n        float _4462 = clamp(s.clearcoat_roughness, 0.0500000007450580596923828125, 1.0);\n        _8323 = _4454;\n        _8324 = _4462;\n        float _4469 = _4462 * _4462;\n        _8325 = _4469;\n        _8326 = _4469 * _4469;\n        float _4481 = max(dot(i.world_normal, v), 9.9999997473787516355514526367188e-05);\n        _8328 = _4481;\n        _8321 = 1.0 - (_4454 * (0.039999999105930328369140625 + (0.959999978542327880859375 * pow(clamp(1.0 - _4481, 0.0, 1.0), 5.0))));\n        _8319 = true;\n    }\n    vec3 _4500 = max(s.sheen_color, vec3(0.0));\n    float _4509 = max(_4500.x, max(_4500.y, _4500.z));\n    if (_4509 > 0.0)\n    {\n        float _4517 = clamp(s.sheen_roughness, 0.100000001490116119384765625, 1.0);\n        _8329 = true;\n        _8330 = _4500;\n        _8331 = _4517;\n        _8332 = _4517 * _4517;\n        float param = max(dot(n, v), 9.9999997473787516355514526367188e-05);\n        float param_1 = _4517;\n        float _4534 = fa_sheen_albedo(param, param_1);\n        _8334 = _4534;\n        _8333 = 1.0 - min(_4509 * _4534, 1.0);\n        _8319 = true;\n    }\n    _8322 = _8321 * _8333;\n    float _4553 = clamp(s.anisotropy, -1.0, 1.0);\n    if (_4553 != 0.0)\n    {\n        vec3 _4568 = i.world_tangent.xyz - (n * dot(n, i.world_tangent.xyz));\n        vec3 t = _4568;\n        if (dot(_4568, _4568) < 9.9999999392252902907785028219223e-09)\n        {\n            bvec3 _4580 = bvec3(abs(n.y) < 0.9900000095367431640625);\n            t = cross(vec3(_4580.x ? vec3(0.0, 1.0, 0.0).x : vec3(1.0, 0.0, 0.0).x, _4580.y ? vec3(0.0, 1.0, 0.0).y : vec3(1.0, 0.0, 0.0).y, _4580.z ? vec3(0.0, 1.0, 0.0).z : vec3(1.0, 0.0, 0.0).z), n);\n        }\n        vec3 _4584 = t;\n        vec3 _4585 = normalize(_4584);\n        t = _4585;\n        vec3 _4610 = normalize((_4585 * cos(s.anisotropy_rotation)) + ((cross(n, _4585) * ((i.world_tangent.w < 0.0) ? (-1.0) : 1.0)) * sin(s.anisotropy_rotation)));\n        _8336 = _4610;\n        _8337 = cross(n, _4610);\n        float _4620 = roughness * roughness;\n        float _4626 = mix(_4620, 1.0, _4553 * _4553);\n        bool _4628 = _4553 > 0.0;\n        _8338 = _4628 ? _4626 : _4620;\n        _8339 = _4628 ? _4620 : _4626;\n        _8335 = _4553;\n        _8319 = true;\n    }\n    return FaLayers(_8319, _8320, _8321, _8322, _8323, _8324, _8325, _8326, i.world_normal, _8328, _8329, _8330, _8331, _8332, _8333, _8334, _8335, _8336, _8337, _8338, _8339);\n}\n\nvec2 fa_atlas_size()\n{\n    return vec2(textureSize(fa_probe_atlas_fa_env_smp, 0));\n}\n\nvec3 fa_probe_sh_coef(vec2 origin, float res, int k)\n{\n    vec3 v = textureLod(fa_probe_atlas_fa_env_smp, (origin + vec2(float(k) + 0.5, res + 2.5)) / fa_atlas_size(), 0.0).xyz;\n    if (fa_mesh_fs_params[41].y > 0.5)\n    {\n        v = (v - vec3(0.5)) * 8.0;\n    }\n    return v;\n}\n\nvec3 fa_sh_eval(vec3 c[9], vec3 n)\n{\n    vec3 _3423 = max((((c[0] * 0.2820948064327239990234375) + (((c[1] * (0.3257350027561187744140625 * n.y)) + (c[2] * (0.3257350027561187744140625 * n.z))) + (c[3] * (0.3257350027561187744140625 * n.x)))) + (((c[4] * ((0.2731371223926544189453125 * n.x) * n.y)) + (c[5] * ((0.2731371223926544189453125 * n.y) * n.z))) + (c[6] * (0.078847892582416534423828125 * (((3.0 * n.z) * n.z) - 1.0))))) + ((c[7] * ((0.2731371223926544189453125 * n.x) * n.z)) + (c[8] * (0.13656856119632720947265625 * ((n.x * n.x) - (n.y * n.y))))), vec3(0.0));\n    return _3423;\n}\n\nvec3 fa_ambient_light(vec3 n)\n{\n    float _4033 = (1.0 - fa_mesh_fs_params[42].w) - fa_mesh_fs_params[47].w;\n    vec3 amb = vec3(0.0);\n    bool _4038 = fa_mesh_fs_params[11].w > 0.5;\n    vec3 c[9];\n    for (int k = 0; k < 9; k++)\n    {\n        c[k] = vec3(0.0);\n    }\n    if (_4033 > 0.0005000000237487256526947021484375)\n    {\n        if (_4038)\n        {\n            for (int k_1 = 0; k_1 < 9; k_1++)\n            {\n                vec2 param = fa_mesh_fs_params[41].zw;\n                float param_1 = 128.0;\n                int param_2 = k_1;\n                c[k_1] = fa_probe_sh_coef(param, param_1, param_2) * _4033;\n            }\n        }\n        else\n        {\n            amb = fa_mesh_fs_params[1].xyz * _4033;\n        }\n    }\n    bool _4089 = fa_mesh_fs_params[42].w > 0.0;\n    if (_4089)\n    {\n        for (int k_2 = 0; k_2 < 9; k_2++)\n        {\n            vec2 param_3 = fa_mesh_fs_params[42].xy;\n            float param_4 = fa_mesh_fs_params[42].z;\n            int param_5 = k_2;\n            c[k_2] += (fa_probe_sh_coef(param_3, param_4, param_5) * fa_mesh_fs_params[42].w);\n        }\n    }\n    bool _4120 = fa_mesh_fs_params[47].w > 0.0;\n    if (_4120)\n    {\n        for (int k_3 = 0; k_3 < 9; k_3++)\n        {\n            vec2 param_6 = fa_mesh_fs_params[47].xy;\n            float param_7 = fa_mesh_fs_params[47].z;\n            int param_8 = k_3;\n            c[k_3] += (fa_probe_sh_coef(param_6, param_7, param_8) * fa_mesh_fs_params[47].w);\n        }\n    }\n    if ((_4038 || _4089) || _4120)\n    {\n        vec3 param_9[9] = c;\n        vec3 param_10 = n;\n        amb += fa_sh_eval(param_9, param_10);\n    }\n    return amb;\n}\n\nvec3 fa_indirect_diffuse(vec3 n)\n{\n    if (fa_lm.z > 0.5)\n    {\n        return textureLod(fa_lightmap_fa_env_smp, fa_lm.xy, 0.0).xyz;\n    }\n    if (fa_mesh_fs_params[32].w > 0.0)\n    {\n        vec3 c[9];\n        for (int k = 0; k < 9; k++)\n        {\n            c[k] = fa_mesh_fs_params[k * 1 + 32].xyz;\n        }\n        vec3 param = n;\n        vec3 param_1[9] = c;\n        vec3 param_2 = n;\n        return mix(fa_ambient_light(param), fa_sh_eval(param_1, param_2), vec3(clamp(fa_mesh_fs_params[32].w, 0.0, 1.0)));\n    }\n    vec3 param_3 = n;\n    return fa_ambient_light(param_3);\n}\n\nint fa_cluster_index(int slot, int n)\n{\n    int param = (int(fa_mesh_fs_params[19].x) + int(fa_mesh_fs_params[19].w)) + ((slot + n) >> 2);\n    vec4 t = fa_light_texel(param);\n    return int(t[(slot + n) & 3]);\n}\n\nint fa_cl_light(int n)\n{\n    if (n < fa_cl_ndir)\n    {\n        return n;\n    }\n    int param = fa_cl_slot;\n    int param_1 = n - fa_cl_ndir;\n    return fa_cluster_index(param, param_1);\n}\n\nint fa_light_base(int li)\n{\n    return li * ((fa_mesh_fs_params[1].w > 4.5) ? 8 : 4);\n}\n\nbool fa_light_baked(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 3;\n    return fa_light_texel(param_1).w > 0.5;\n}\n\nfloat fa_baked_keep(int li)\n{\n    float _5757;\n    if (fa_lm.z > 0.5)\n    {\n        _5757 = 0.0;\n    }\n    else\n    {\n        _5757 = 1.0 - clamp(fa_mesh_fs_params[32].w, 0.0, 1.0);\n    }\n    bool _5768 = _5757 < 1.0;\n    bool _5774;\n    if (_5768)\n    {\n        int param = li;\n        _5774 = fa_light_baked(param);\n    }\n    else\n    {\n        _5774 = _5768;\n    }\n    return _5774 ? _5757 : 1.0;\n}\n\nfloat fa_light_type(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 1;\n    return fa_light_texel(param_1).w;\n}\n\nvec4 fa_atlas_fetch(vec2 texel)\n{\n    return textureLod(fa_light_atlas_fa_env_smp, texel / vec2(textureSize(fa_light_atlas_fa_env_smp, 0)), 0.0);\n}\n\nvec3 fa_cookie_sample(vec2 tile_origin, vec2 uv)\n{\n    vec2 param = (tile_origin + vec2(1.0)) + (clamp(uv, vec2(0.0), vec2(1.0)) * 254.0);\n    return fa_atlas_fetch(param).xyz;\n}\n\nvec3 fa_area_point(vec3 c, vec3 axis, vec3 ru, vec3 uu, float hx, float hy, float shape, vec3 p, vec3 r)\n{\n    bool _830 = dot(r, r) > 0.5;\n    if (shape > 1.5)\n    {\n        vec3 _843 = (c - (ru * hx)) - p;\n        vec3 _849 = ru * (2.0 * hx);\n        float _855 = max(dot(_849, _849), 9.9999999392252902907785028219223e-09);\n        float _859 = dot(_843, _849);\n        float t = clamp((-_859) / _855, 0.0, 1.0);\n        if (_830)\n        {\n            float _874 = dot(r, _849);\n            float _880 = _855 - (_874 * _874);\n            if (abs(_880) > (9.9999997473787516355514526367188e-06 * _855))\n            {\n                t = clamp(((dot(r, _843) * _874) - _859) / _880, 0.0, 1.0);\n            }\n        }\n        return (p + _843) + (_849 * t);\n    }\n    vec3 q = p;\n    float _912 = dot(r, axis);\n    bool _920;\n    if (_830)\n    {\n        _920 = abs(_912) > 9.9999997473787516355514526367188e-05;\n    }\n    else\n    {\n        _920 = _830;\n    }\n    if (_920)\n    {\n        float _930 = dot(c - p, axis) / _912;\n        if (_930 > 0.0)\n        {\n            q = p + (r * _930);\n        }\n    }\n    vec3 _943 = q - c;\n    vec2 xy = vec2(dot(_943, ru), dot(_943, uu));\n    if (shape > 0.5)\n    {\n        float _958 = length(xy);\n        if (_958 > hx)\n        {\n            xy *= (hx / _958);\n        }\n    }\n    else\n    {\n        xy = clamp(xy, vec2(-hx, -hy), vec2(hx, hy));\n    }\n    return (c + (ru * xy.x)) + (uu * xy.y);\n}\n\nint fa_cube_face(vec3 d)\n{\n    vec3 _591 = abs(d);\n    float _593 = _591.x;\n    float _595 = _591.y;\n    bool _596 = _593 >= _595;\n    bool _604;\n    if (_596)\n    {\n        _604 = _593 >= _591.z;\n    }\n    else\n    {\n        _604 = _596;\n    }\n    int _605;\n    if (_604)\n    {\n        _605 = (d.x > 0.0) ? 0 : 1;\n    }\n    else\n    {\n        int _620;\n        if (_595 >= _591.z)\n        {\n            _620 = (d.y > 0.0) ? 2 : 3;\n        }\n        else\n        {\n            _620 = (d.z > 0.0) ? 4 : 5;\n        }\n        _605 = _620;\n    }\n    return _605;\n}\n\nvoid fa_cube_face_basis(int f, out vec3 fwd, out vec3 up)\n{\n    if (f == 0)\n    {\n        fwd = vec3(1.0, 0.0, 0.0);\n        up = vec3(0.0, 1.0, 0.0);\n    }\n    else\n    {\n        if (f == 1)\n        {\n            fwd = vec3(-1.0, 0.0, 0.0);\n            up = vec3(0.0, 1.0, 0.0);\n        }\n        else\n        {\n            if (f == 2)\n            {\n                fwd = vec3(0.0, 1.0, 0.0);\n                up = vec3(0.0, 0.0, 1.0);\n            }\n            else\n            {\n                if (f == 3)\n                {\n                    fwd = vec3(0.0, -1.0, 0.0);\n                    up = vec3(0.0, 0.0, -1.0);\n                }\n                else\n                {\n                    if (f == 4)\n                    {\n                        fwd = vec3(0.0, 0.0, 1.0);\n                        up = vec3(0.0, 1.0, 0.0);\n                    }\n                    else\n                    {\n                        fwd = vec3(0.0, 0.0, -1.0);\n                        up = vec3(0.0, 1.0, 0.0);\n                    }\n                }\n            }\n        }\n    }\n}\n\nfloat fa_ies_sample(vec2 tile_origin, vec3 d, vec3 axis, vec3 right, vec3 up)\n{\n    float _750 = dot(d, right);\n    float _754 = dot(d, up);\n    float _765;\n    if (((_750 * _750) + (_754 * _754)) > 1.0000000133514319600180897396058e-10)\n    {\n        _765 = atan(_754, _750) * 0.15915493667125701904296875;\n    }\n    else\n    {\n        _765 = 0.0;\n    }\n    vec2 param = tile_origin + vec2(1.0 + ((_765 - floor(_765)) * 64.0), 1.0 + (acos(clamp(dot(d, axis), -1.0, 1.0)) * 10.18591594696044921875));\n    return fa_atlas_fetch(param).x;\n}\n\nLightSample fa_light_sample_n(int li, vec3 world_pos, vec3 n)\n{\n    int param = li;\n    int _996 = fa_light_base(param);\n    bool _1000 = fa_mesh_fs_params[1].w > 4.5;\n    int param_1 = _996;\n    vec4 _1004 = fa_light_texel(param_1);\n    int param_2 = _996 + 1;\n    vec4 _1009 = fa_light_texel(param_2);\n    float _1012 = _1009.w;\n    float atten = 1.0;\n    float dist = 0.0;\n    fa_light_tint = vec3(1.0);\n    bool _1024 = _1000 && (_1012 > 2.5);\n    fa_light_is_area = _1024;\n    bool _1026 = _1012 < 0.5;\n    vec3 l;\n    if (_1026)\n    {\n        l = normalize(_1004.xyz);\n        if (_1000)\n        {\n            int param_3 = _996 + 6;\n            vec4 _1040 = fa_light_texel(param_3);\n            if (_1040.z > 0.5)\n            {\n                int param_4 = _996 + 4;\n                vec4 _1050 = fa_light_texel(param_4);\n                int param_5 = _996 + 5;\n                vec4 _1055 = fa_light_texel(param_5);\n                vec2 param_6 = _1040.xy;\n                vec2 param_7 = fract(vec2(dot(world_pos, _1050.xyz) * _1050.w, (-dot(world_pos, _1055.xyz)) * _1055.w) + vec2(0.5));\n                fa_light_tint = fa_cookie_sample(param_6, param_7);\n            }\n        }\n    }\n    else\n    {\n        vec3 _1085 = _1004.xyz;\n        vec3 _1087 = _1085 - world_pos;\n        vec3 to_light = _1087;\n        float _1090 = length(_1087);\n        float reach = _1090;\n        bool front = true;\n        if (_1024)\n        {\n            int param_8 = _996 + 7;\n            reach = max(_1090 - fa_light_texel(param_8).w, 0.0);\n            int param_9 = _996 + 4;\n            vec4 _1114 = fa_light_texel(param_9);\n            int param_10 = _996 + 5;\n            vec4 _1119 = fa_light_texel(param_10);\n            int param_11 = _996 + 6;\n            vec4 _1124 = fa_light_texel(param_11);\n            float _1125 = _1124.w;\n            int param_12 = _996 + 2;\n            vec3 _1132 = normalize(fa_light_texel(param_12).xyz);\n            bool _1134 = _1125 > 1.5;\n            bool _1142;\n            if (!_1134)\n            {\n                _1142 = dot(_1132, to_light) < 0.0;\n            }\n            else\n            {\n                _1142 = _1134;\n            }\n            front = _1142;\n            vec3 r = vec3(0.0);\n            vec3 _1151 = fa_mesh_fs_params[0].xyz - world_pos;\n            bool _1155 = dot(n, n) > 0.5;\n            bool _1163;\n            if (_1155)\n            {\n                _1163 = dot(_1151, _1151) > 9.9999999600419720025001879548654e-13;\n            }\n            else\n            {\n                _1163 = _1155;\n            }\n            if (_1163)\n            {\n                r = reflect(-normalize(_1151), normalize(n));\n            }\n            vec3 param_13 = _1085;\n            vec3 param_14 = _1132;\n            vec3 param_15 = _1114.xyz;\n            vec3 param_16 = _1119.xyz;\n            float param_17 = _1114.w;\n            float param_18 = _1119.w;\n            float param_19 = _1125;\n            vec3 param_20 = world_pos;\n            vec3 param_21 = r;\n            to_light = fa_area_point(param_13, param_14, param_15, param_16, param_17, param_18, param_19, param_20, param_21) - world_pos;\n        }\n        float _1199 = length(to_light);\n        dist = _1199;\n        l = to_light / vec3(max(_1199, 9.9999997473787516355514526367188e-05));\n        float _1213 = reach / max(_1004.w, 0.001000000047497451305389404296875);\n        float _1219 = clamp(1.0 - (_1213 * _1213), 0.0, 1.0);\n        float _1221;\n        if (front)\n        {\n            _1221 = _1219 * _1219;\n        }\n        else\n        {\n            _1221 = 0.0;\n        }\n        atten = _1221;\n        bool _1232 = _1012 < 2.5;\n        if ((_1012 > 1.5) && _1232)\n        {\n            int param_22 = _996 + 2;\n            vec4 _1240 = fa_light_texel(param_22);\n            float _1250 = _1240.w;\n            int param_23 = _996 + 3;\n            vec4 _1255 = fa_light_texel(param_23);\n            float _1256 = _1255.x;\n            float cos_inner = _1256;\n            if (_1256 > 1.5)\n            {\n                cos_inner = mix(_1250, 1.0, 0.25);\n            }\n            atten *= smoothstep(_1250, cos_inner, dot(-l, normalize(_1240.xyz)));\n        }\n        if (_1000 && (_1012 < 1.5))\n        {\n            int param_24 = _996 + 6;\n            vec4 _1280 = fa_light_texel(param_24);\n            if (_1280.z > 0.5)\n            {\n                vec3 _1288 = -to_light;\n                int param_25 = _996 + 4;\n                int param_26 = _996 + 5;\n                vec3 _1302 = fa_light_texel(param_25).xyz;\n                vec3 _1306 = fa_light_texel(param_26).xyz;\n                vec3 _1315 = vec3(dot(_1288, _1302), dot(_1288, _1306), dot(_1288, cross(_1302, _1306)));\n                vec3 param_27 = _1315;\n                int _1319 = fa_cube_face(param_27);\n                int param_28 = _1319;\n                vec3 param_29;\n                vec3 param_30;\n                fa_cube_face_basis(param_28, param_29, param_30);\n                vec2 _1346 = vec2(dot(_1315, cross(param_29, param_30)), dot(_1315, param_30)) / vec2(max(dot(_1315, param_29), 9.9999997473787516355514526367188e-05));\n                int _1350 = _1319 / 3;\n                vec2 param_31 = _1280.xy + (vec2(float(_1319 - (_1350 * 3)), float(_1350)) * 256.0);\n                vec2 param_32 = vec2(0.5 + (0.5 * _1346.x), 0.5 - (0.5 * _1346.y));\n                fa_light_tint = fa_cookie_sample(param_31, param_32);\n            }\n            int param_33 = _996 + 7;\n            vec4 _1380 = fa_light_texel(param_33);\n            if (_1380.z > 0.5)\n            {\n                int param_34 = _996 + 2;\n                int param_35 = _996 + 4;\n                int param_36 = _996 + 5;\n                vec2 param_37 = _1380.xy;\n                vec3 param_38 = -l;\n                vec3 param_39 = normalize(fa_light_texel(param_34).xyz);\n                vec3 param_40 = fa_light_texel(param_35).xyz;\n                vec3 param_41 = fa_light_texel(param_36).xyz;\n                atten *= fa_ies_sample(param_37, param_38, param_39, param_40, param_41);\n            }\n        }\n        else\n        {\n            if (_1000 && _1232)\n            {\n                int param_42 = _996 + 6;\n                vec4 _1427 = fa_light_texel(param_42);\n                int param_43 = _996 + 7;\n                vec4 _1432 = fa_light_texel(param_43);\n                bool _1435 = _1427.z > 0.5;\n                bool _1442;\n                if (!_1435)\n                {\n                    _1442 = _1432.z > 0.5;\n                }\n                else\n                {\n                    _1442 = _1435;\n                }\n                if (_1442)\n                {\n                    int param_44 = _996 + 2;\n                    vec4 _1449 = fa_light_texel(param_44);\n                    vec3 _1453 = normalize(_1449.xyz);\n                    int param_45 = _996 + 4;\n                    vec4 _1458 = fa_light_texel(param_45);\n                    int param_46 = _996 + 5;\n                    vec4 _1463 = fa_light_texel(param_46);\n                    if (_1435)\n                    {\n                        vec3 _1471 = -to_light;\n                        float _1478 = _1449.w;\n                        float _1494 = 0.5 / max(dot(_1471, _1453) * (sqrt(max(1.0 - (_1478 * _1478), 0.0)) / max(_1478, 0.001000000047497451305389404296875)), 9.9999997473787516355514526367188e-05);\n                        vec2 param_47 = _1427.xy;\n                        vec2 param_48 = vec2(0.5 + (dot(_1471, _1458.xyz) * _1494), 0.5 - (dot(_1471, _1463.xyz) * _1494));\n                        fa_light_tint = fa_cookie_sample(param_47, param_48);\n                    }\n                    if (_1432.z > 0.5)\n                    {\n                        vec2 param_49 = _1432.xy;\n                        vec3 param_50 = -l;\n                        vec3 param_51 = _1453;\n                        vec3 param_52 = _1458.xyz;\n                        vec3 param_53 = _1463.xyz;\n                        atten *= fa_ies_sample(param_49, param_50, param_51, param_52, param_53);\n                    }\n                }\n            }\n        }\n    }\n    vec3 _8307 = _1009.xyz * atten;\n    if (_1000)\n    {\n        _8307 *= fa_light_tint;\n    }\n    int _1563;\n    if (_1026)\n    {\n        _1563 = 0;\n    }\n    else\n    {\n        _1563 = ((_1012 > 1.5) && (_1012 < 2.5)) ? 2 : 1;\n    }\n    return LightSample(l, _8307, atten, 1.0, dist, _1563);\n}\n\nfloat fa_shadow_split_at(int i)\n{\n    float _2300;\n    if (i == 0)\n    {\n        _2300 = fa_shadows[24].x;\n    }\n    else\n    {\n        float _2316;\n        if (i == 1)\n        {\n            _2316 = fa_shadows[24].y;\n        }\n        else\n        {\n            float _2324;\n            if (i == 2)\n            {\n                _2324 = fa_shadows[24].z;\n            }\n            else\n            {\n                _2324 = fa_shadows[24].w;\n            }\n            _2316 = _2324;\n        }\n        _2300 = _2316;\n    }\n    return _2300;\n}\n\nfloat fa_shadow_depth(inout vec2 uv, vec4 rect)\n{\n    uv = clamp(uv, rect.xy, rect.zw);\n    return textureLod(fa_shadow_tex_fa_shadow_smp, uv, 0.0).x;\n}\n\nfloat fa_shadow_fetch(vec2 uv, vec4 rect, vec3 conv)\n{\n    vec2 param = uv;\n    vec4 param_1 = rect;\n    float _2357 = fa_shadow_depth(param, param_1);\n    float _2361;\n    if (conv.x < 0.5)\n    {\n        _2361 = _2357;\n    }\n    else\n    {\n        _2361 = (conv.y * conv.z) / (conv.z - (_2357 * (conv.z - conv.y)));\n    }\n    return _2361;\n}\n\nfloat fa_shadow_noise()\n{\n    return fract(52.98291778564453125 * fract(dot(gl_FragCoord.xy, vec2(0.067110560834407806396484375, 0.005837149918079376220703125))));\n}\n\nvec2 fa_shadow_vogel(int k, int n, float phi)\n{\n    float _2288 = (float(k) * 2.3999631404876708984375) + phi;\n    return vec2(cos(_2288), sin(_2288)) * sqrt((float(k) + 0.5) / float(n));\n}\n\nfloat fa_shadow_filter(vec2 uv, vec4 rect, float zr, float texel_m, float unit, float reach, float plane, vec3 conv, int mode, float k)\n{\n    if (mode == 1)\n    {\n        vec2 param = uv;\n        vec4 param_1 = rect;\n        vec3 param_2 = conv;\n        return float(zr <= fa_shadow_fetch(param, param_1, param_2));\n    }\n    float _2407 = fa_shadow_noise() * 6.283185482025146484375;\n    float radius = 1.5;\n    if (mode == 2)\n    {\n        float _2416;\n        if (k < 0.0)\n        {\n            _2416 = (-k) / max(zr, 0.100000001490116119384765625);\n        }\n        else\n        {\n            _2416 = k;\n        }\n        float _2436 = clamp((_2416 * reach) / texel_m, 3.0, 12.0);\n        float sum = 0.0;\n        float cnt = 0.0;\n        for (int i = 0; i < 16; i++)\n        {\n            int param_3 = i;\n            int param_4 = 16;\n            float param_5 = _2407;\n            vec2 _2455 = fa_shadow_vogel(param_3, param_4, param_5) * _2436;\n            vec2 param_6 = uv + (_2455 * fa_shadows[26].zw);\n            vec4 param_7 = rect;\n            vec3 param_8 = conv;\n            float _2467 = fa_shadow_fetch(param_6, param_7, param_8);\n            if (_2467 < (zr - (length(_2455) * plane)))\n            {\n                sum += _2467;\n                cnt += 1.0;\n            }\n        }\n        if (cnt < 0.5)\n        {\n            return 1.0;\n        }\n        float _2493 = sum / cnt;\n        float _2503;\n        if (k < 0.0)\n        {\n            _2503 = (-k) / max(_2493, 0.0500000007450580596923828125);\n        }\n        else\n        {\n            _2503 = k;\n        }\n        radius = clamp(((max(zr - _2493, 0.0) * unit) * _2503) / texel_m, 1.5, 16.0);\n    }\n    float lit = 0.0;\n    int _2525 = (mode == 2) ? 24 : 16;\n    for (int i_1 = 0; i_1 < _2525; i_1++)\n    {\n        int param_9 = i_1;\n        int param_10 = _2525;\n        float param_11 = _2407;\n        vec2 _2544 = fa_shadow_vogel(param_9, param_10, param_11) * radius;\n        vec2 param_12 = uv + (_2544 * fa_shadows[26].zw);\n        vec4 param_13 = rect;\n        vec3 param_14 = conv;\n        lit += float((zr - (length(_2544) * plane)) <= fa_shadow_fetch(param_12, param_13, param_14));\n    }\n    return lit / float(_2525);\n}\n\nfloat fa_shadow_cascade(int ci, vec3 world, vec3 n, vec3 l)\n{\n    float _2586 = max(fa_shadows[ci * 1 + 20].y, 0.001000000047497451305389404296875);\n    float _2591 = clamp(dot(n, l), 0.0, 1.0);\n    float _2597 = sqrt(1.0 - (_2591 * _2591));\n    float _2604 = min(_2597 / max(_2591, 0.20000000298023223876953125), 4.0);\n    float _2609;\n    if (fa_shadows[26].y > 0.0)\n    {\n        _2609 = fa_shadows[26].y;\n    }\n    else\n    {\n        _2609 = 1.5 * fa_shadows[ci * 1 + 20].x;\n    }\n    vec4 _2634 = mat4(fa_shadows[ci * 4 + 0], fa_shadows[ci * 4 + 1], fa_shadows[ci * 4 + 2], fa_shadows[ci * 4 + 3]) * vec4(world + (n * (_2609 * _2597)), 1.0);\n    float _2641 = _2634.x;\n    bool _2644 = _2641 < fa_shadows[ci * 1 + 16].x;\n    bool _2653;\n    if (!_2644)\n    {\n        _2653 = _2641 > fa_shadows[ci * 1 + 16].z;\n    }\n    else\n    {\n        _2653 = _2644;\n    }\n    bool _2662;\n    if (!_2653)\n    {\n        _2662 = _2634.y < fa_shadows[ci * 1 + 16].y;\n    }\n    else\n    {\n        _2662 = _2653;\n    }\n    bool _2671;\n    if (!_2662)\n    {\n        _2671 = _2634.y > fa_shadows[ci * 1 + 16].w;\n    }\n    else\n    {\n        _2671 = _2662;\n    }\n    bool _2678;\n    if (!_2671)\n    {\n        _2678 = _2634.z > 1.0;\n    }\n    else\n    {\n        _2678 = _2671;\n    }\n    if (_2678)\n    {\n        return -1.0;\n    }\n    float _2686;\n    if (fa_shadows[26].x > 0.0)\n    {\n        _2686 = fa_shadows[26].x;\n    }\n    else\n    {\n        _2686 = 1.5 * fa_shadows[ci * 1 + 20].x;\n    }\n    vec2 param = _2634.xy;\n    vec4 param_1 = fa_shadows[ci * 1 + 16];\n    float param_2 = _2634.z - ((_2686 * (1.0 + (0.5 * _2604))) / _2586);\n    float param_3 = fa_shadows[ci * 1 + 20].x;\n    float param_4 = _2586;\n    float param_5 = _2586 * 0.25;\n    float param_6 = ((fa_shadows[ci * 1 + 20].x * min(_2604, 3.0)) * 0.5) / _2586;\n    vec3 param_7 = vec3(0.0);\n    int param_8 = int(fa_shadows[25].z + 0.5);\n    float param_9 = fa_shadows[25].w;\n    return fa_shadow_filter(param, param_1, param_2, param_3, param_4, param_5, param_6, param_7, param_8, param_9);\n}\n\nfloat fa_shadow_sun(vec3 world, vec3 n, vec3 l)\n{\n    if (fa_mesh_fs_params[5].z < 0.5)\n    {\n        return 1.0;\n    }\n    int _3064 = int(fa_shadows[25].x + 0.5);\n    if (_3064 < 1)\n    {\n        return 1.0;\n    }\n    float _3079 = dot(world - fa_shadows[27].xyz, fa_shadows[28].xyz);\n    int param = _3064 - 1;\n    if (_3079 > fa_shadow_split_at(param))\n    {\n        return 1.0;\n    }\n    int ci = 0;\n    bool _3091 = _3064 > 1;\n    bool _3098;\n    if (_3091)\n    {\n        _3098 = _3079 > fa_shadows[24].x;\n    }\n    else\n    {\n        _3098 = _3091;\n    }\n    if (_3098)\n    {\n        ci = 1;\n    }\n    bool _3102 = _3064 > 2;\n    bool _3109;\n    if (_3102)\n    {\n        _3109 = _3079 > fa_shadows[24].y;\n    }\n    else\n    {\n        _3109 = _3102;\n    }\n    if (_3109)\n    {\n        ci = 2;\n    }\n    bool _3113 = _3064 > 3;\n    bool _3120;\n    if (_3113)\n    {\n        _3120 = _3079 > fa_shadows[24].z;\n    }\n    else\n    {\n        _3120 = _3113;\n    }\n    if (_3120)\n    {\n        ci = 3;\n    }\n    float s = -1.0;\n    for (int k = 0; k < 4; k++)\n    {\n        if (ci >= _3064)\n        {\n            break;\n        }\n        int param_1 = ci;\n        vec3 param_2 = world;\n        vec3 param_3 = n;\n        vec3 param_4 = l;\n        float _3146 = fa_shadow_cascade(param_1, param_2, param_3, param_4);\n        s = _3146;\n        if (_3146 >= 0.0)\n        {\n            break;\n        }\n        ci++;\n    }\n    if (s < 0.0)\n    {\n        return 1.0;\n    }\n    if (fa_shadows[25].y > 0.0)\n    {\n        float _3171;\n        if (ci > 0)\n        {\n            int param_5 = ci - 1;\n            _3171 = fa_shadow_split_at(param_5);\n        }\n        else\n        {\n            _3171 = fa_shadows[28].w;\n        }\n        int param_6 = ci;\n        float _3190 = fa_shadows[25].y * max(fa_shadow_split_at(param_6) - _3171, 9.9999997473787516355514526367188e-05);\n        int param_7 = ci;\n        float _3201 = clamp((_3079 - (fa_shadow_split_at(param_7) - _3190)) / _3190, 0.0, 1.0);\n        if (_3201 > 0.0)\n        {\n            float s2 = 1.0;\n            if ((ci + 1) < _3064)\n            {\n                int param_8 = ci + 1;\n                vec3 param_9 = world;\n                vec3 param_10 = n;\n                vec3 param_11 = l;\n                float _3222 = fa_shadow_cascade(param_8, param_9, param_10, param_11);\n                s2 = _3222;\n                if (_3222 < 0.0)\n                {\n                    s2 = s;\n                }\n            }\n            s = mix(s, s2, _3201);\n        }\n    }\n    return s;\n}\n\nfloat fa_shadow_factor(vec3 n, vec3 l)\n{\n    vec3 param = fa_world_pos;\n    vec3 param_1 = n;\n    vec3 param_2 = l;\n    return fa_shadow_sun(param, param_1, param_2);\n}\n\nfloat fa_shadow_local(int li, vec3 lpos, vec3 world, vec3 n, vec3 l)\n{\n    bool _2744 = fa_mesh_fs_params[5].z < 0.5;\n    bool _2751;\n    if (!_2744)\n    {\n        _2751 = fa_shadows[29].x < 0.5;\n    }\n    else\n    {\n        _2751 = _2744;\n    }\n    if (_2751)\n    {\n        return 1.0;\n    }\n    int param = (int(fa_shadows[29].x + 0.5) - 1) + li;\n    vec4 _2764 = fa_light_texel(param);\n    float _2765 = _2764.x;\n    if (_2765 < 0.0)\n    {\n        return 1.0;\n    }\n    int _2774 = int(_2765 + 0.5);\n    int param_1 = _2774;\n    vec4 _2778 = fa_light_texel(param_1);\n    int param_2 = _2774 + 1;\n    vec4 _2783 = fa_light_texel(param_2);\n    float fade = 1.0;\n    float _2786 = _2778.y;\n    if (_2786 > 0.0)\n    {\n        float _2803 = 1.0 - smoothstep(0.75 * _2786, _2786, length(world - fa_shadows[27].xyz));\n        fade = _2803;\n        if (_2803 <= 0.0)\n        {\n            return 1.0;\n        }\n    }\n    int face = 0;\n    if (_2778.x > 1.5)\n    {\n        vec3 param_3 = world - lpos;\n        face = fa_cube_face(param_3);\n    }\n    int _2827 = (_2774 + 2) + (face * 6);\n    int param_4 = _2827;\n    int param_5 = _2827 + 1;\n    int param_6 = _2827 + 3;\n    vec4 _2841 = fa_light_texel(param_6);\n    int param_7 = _2827 + 4;\n    vec4 _2846 = fa_light_texel(param_7);\n    int param_8 = _2827 + 5;\n    vec4 _2851 = fa_light_texel(param_8);\n    float _2863 = _2851.x * max(dot(_2841, vec4(world, 1.0)), 0.001000000047497451305389404296875);\n    float _2868 = clamp(dot(n, l), 0.0, 1.0);\n    float _2891 = clamp(dot(n, _2841.xyz), -1.0, 1.0);\n    float _2910 = min(sqrt(1.0 - (_2891 * _2891)) / max(abs(dot(n, world - lpos)) / max(dot(_2841, vec4(world, 1.0)), 0.001000000047497451305389404296875), 0.20000000298023223876953125), 4.0);\n    float _2913 = _2783.y;\n    float _2915;\n    if (_2913 > 0.0)\n    {\n        _2915 = _2913;\n    }\n    else\n    {\n        _2915 = 1.5 * _2863;\n    }\n    vec4 _2935 = vec4(world + (n * (_2915 * sqrt(1.0 - (_2868 * _2868)))), 1.0);\n    float _2939 = dot(_2841, _2935);\n    float _2942 = _2851.y;\n    if (_2939 < _2942)\n    {\n        return 1.0;\n    }\n    vec2 _2957 = vec2(dot(fa_light_texel(param_4), _2935), dot(fa_light_texel(param_5), _2935)) / vec2(_2939);\n    float _2959 = _2957.x;\n    bool _2962 = _2959 < _2846.x;\n    bool _2971;\n    if (!_2962)\n    {\n        _2971 = _2959 > _2846.z;\n    }\n    else\n    {\n        _2971 = _2962;\n    }\n    bool _2980;\n    if (!_2971)\n    {\n        _2980 = _2957.y < _2846.y;\n    }\n    else\n    {\n        _2980 = _2971;\n    }\n    bool _2989;\n    if (!_2980)\n    {\n        _2989 = _2957.y > _2846.w;\n    }\n    else\n    {\n        _2989 = _2980;\n    }\n    if (_2989)\n    {\n        return 1.0;\n    }\n    float _2995 = _2783.x;\n    float _2997;\n    if (_2995 > 0.0)\n    {\n        _2997 = _2995;\n    }\n    else\n    {\n        _2997 = 1.5 * _2863;\n    }\n    vec2 param_9 = _2957;\n    vec4 param_10 = _2846;\n    float param_11 = _2939 - (_2997 * (1.0 + (0.5 * _2910)));\n    float param_12 = _2863;\n    float param_13 = 1.0;\n    float param_14 = _2851.z * 0.25;\n    float param_15 = (_2863 * min(_2910, 3.0)) * 0.5;\n    vec3 param_16 = vec3(1.0, _2942, _2851.z);\n    int param_17 = int(_2778.z + 0.5);\n    float param_18 = _2778.w;\n    return mix(1.0, fa_shadow_filter(param_9, param_10, param_11, param_12, param_13, param_14, param_15, param_16, param_17, param_18), fade);\n}\n\nfloat fa_contact_shadow(int li, vec3 world, vec3 gn, vec3 l, float dist)\n{\n    bool _5138 = fa_mesh_fs_params[24].x < 0.5;\n    bool _5145;\n    if (!_5138)\n    {\n        _5145 = fa_shadows[29].x < 0.5;\n    }\n    else\n    {\n        _5145 = _5138;\n    }\n    if (_5145)\n    {\n        return 1.0;\n    }\n    int param = (int(fa_shadows[29].x + 0.5) - 1) + li;\n    vec4 _5158 = fa_light_texel(param);\n    float _5159 = _5158.y;\n    float len = _5159;\n    if (_5159 <= 0.0)\n    {\n        return 1.0;\n    }\n    float _5171 = length(world - fa_mesh_fs_params[0].xyz);\n    float _5181 = 1.0 - smoothstep(0.5 * fa_mesh_fs_params[25].x, fa_mesh_fs_params[25].x, _5171);\n    if (_5181 <= 0.0)\n    {\n        return 1.0;\n    }\n    float _5187 = len;\n    float _5190 = min(_5187, 0.89999997615814208984375 * dist);\n    len = _5190;\n    float _5195 = 0.004999999888241291046142578125 + (0.0030000000260770320892333984375 * _5171);\n    float _5200 = _5195 + (0.5 * _5190);\n    vec3 _5206 = world + (gn * _5195);\n    float _5208 = fa_shadow_noise();\n    float occ = 0.0;\n    float _5272;\n    for (int k = 0; k < 12; k++)\n    {\n        float _5223 = (float(k) + _5208) * 0.083333335816860198974609375;\n        vec3 _5231 = _5206 + (l * (_5223 * len));\n        vec4 _5237 = vec4(_5231, 1.0);\n        float _5243 = dot(fa_mesh_fs_params[28], _5237);\n        if (_5243 < 9.9999997473787516355514526367188e-05)\n        {\n            break;\n        }\n        vec2 _5263 = vec2(dot(fa_mesh_fs_params[26], _5237), dot(fa_mesh_fs_params[27], _5237)) / vec2(_5243);\n        float _5267 = _5263.x * 0.5;\n        float _5268 = _5267 + 0.5;\n        if (fa_mesh_fs_params[24].y > 0.5)\n        {\n            _5272 = (_5263.y * 0.5) + 0.5;\n        }\n        else\n        {\n            _5272 = 0.5 - (_5263.y * 0.5);\n        }\n        bool _5288 = _5268 < 0.0;\n        bool _5295;\n        if (!_5288)\n        {\n            _5295 = _5268 >= 1.0;\n        }\n        else\n        {\n            _5295 = _5288;\n        }\n        bool _5302;\n        if (!_5295)\n        {\n            _5302 = _5272 < 0.0;\n        }\n        else\n        {\n            _5302 = _5295;\n        }\n        bool _5309;\n        if (!_5302)\n        {\n            _5309 = _5272 >= 1.0;\n        }\n        else\n        {\n            _5309 = _5302;\n        }\n        if (_5309)\n        {\n            break;\n        }\n        vec4 _5328 = texelFetch(fa_screen_tex_fa_shadow_smp, ivec2(vec2(_5268, _5272) * fa_mesh_fs_params[24].zw), 0);\n        if (_5328.w < 0.5)\n        {\n            continue;\n        }\n        float _5347 = (dot(fa_mesh_fs_params[29].xyz, _5231) + fa_mesh_fs_params[29].w) - _5328.x;\n        if ((_5347 > _5195) && (_5347 < _5200))\n        {\n            occ = max(occ, (1.0 - (_5223 * _5223)) * smoothstep(0.0, 0.0500000007450580596923828125, min(min(_5268, 0.5 - _5267), min(_5272, 1.0 - _5272))));\n        }\n    }\n    return 1.0 - (occ * _5181);\n}\n\nLightSample fa_light_shadowed(int li, vec3 world_pos, vec3 gn)\n{\n    int param = li;\n    float _5813 = fa_baked_keep(param);\n    if (_5813 <= 0.0)\n    {\n        int param_1 = li;\n        return LightSample(vec3(0.0, 1.0, 0.0), vec3(0.0), 0.0, 1.0, 0.0, int(fa_light_type(param_1) + 0.5));\n    }\n    int param_2 = li;\n    vec3 param_3 = world_pos;\n    vec3 param_4 = gn;\n    LightSample _5839 = fa_light_sample_n(param_2, param_3, param_4);\n    vec3 _8376 = _5839.color;\n    float _8377 = _5839.attenuation;\n    float _8378 = _5839.shadow;\n    bool _5842 = _5839.type == 0;\n    if (_5842 && (li == 0))\n    {\n        vec3 param_5 = gn;\n        vec3 param_6 = _5839.direction;\n        float _5853 = fa_shadow_factor(param_5, param_6);\n        _8378 = _5853;\n        _8376 *= _5853;\n    }\n    else\n    {\n        bool _5864 = _5839.type != 0;\n        bool _5870;\n        if (_5864)\n        {\n            _5870 = _8377 > 0.0;\n        }\n        else\n        {\n            _5870 = _5864;\n        }\n        if (_5870)\n        {\n            int param_7 = li;\n            int param_8 = fa_light_base(param_7);\n            int param_9 = li;\n            vec3 param_10 = fa_light_texel(param_8).xyz;\n            vec3 param_11 = world_pos;\n            vec3 param_12 = gn;\n            vec3 param_13 = _5839.direction;\n            float _5889 = fa_shadow_local(param_9, param_10, param_11, param_12, param_13);\n            _8378 = _5889;\n            _8376 *= _5889;\n        }\n    }\n    bool _5899 = fa_mesh_fs_params[24].x > 0.5;\n    bool _5905;\n    if (_5899)\n    {\n        _5905 = _8377 > 0.0;\n    }\n    else\n    {\n        _5905 = _5899;\n    }\n    if (_5905)\n    {\n        float _5912;\n        if (_5842)\n        {\n            _5912 = 1000000000.0;\n        }\n        else\n        {\n            _5912 = _5839._distance;\n        }\n        int param_14 = li;\n        vec3 param_15 = world_pos;\n        vec3 param_16 = gn;\n        vec3 param_17 = _5839.direction;\n        float param_18 = _5912;\n        float _5930 = fa_contact_shadow(param_14, param_15, param_16, param_17, param_18);\n        _8378 *= _5930;\n        _8376 *= _5930;\n    }\n    float _5943 = _8377;\n    float _5944 = _5943 * _5813;\n    _8377 = _5944;\n    vec3 _5948 = _8376;\n    vec3 _5949 = _5948 * _5813;\n    _8376 = _5949;\n    return LightSample(_5839.direction, _5949, _5944, _8378, _5839._distance, _5839.type);\n}\n\nvec3 fa_ltc_tangent(vec3 n, vec3 v)\n{\n    vec3 _5983 = v - (n * dot(v, n));\n    vec3 t = _5983;\n    float _5987 = dot(_5983, _5983);\n    float l2 = _5987;\n    if (_5987 < 1.0000000133514319600180897396058e-10)\n    {\n        vec3 _5997;\n        if (abs(n.z) < 0.999000012874603271484375)\n        {\n            _5997 = cross(n, vec3(0.0, 0.0, 1.0));\n        }\n        else\n        {\n            _5997 = cross(n, vec3(1.0, 0.0, 0.0));\n        }\n        t = _5997;\n        l2 = dot(_5997, _5997);\n    }\n    return t * inversesqrt(l2);\n}\n\nvec3 fa_ltc_local(vec3 t1, vec3 n, vec3 p)\n{\n    return vec3(dot(t1, p), dot(cross(n, t1), p), dot(n, p));\n}\n\nvec3 fa_ltc_edge_vector(vec3 a, vec3 b)\n{\n    float _6032 = dot(a, a);\n    float _6036 = dot(b, b);\n    if ((_6032 < 1.0000000195414813782625560981111e-24) || (_6036 < 1.0000000195414813782625560981111e-24))\n    {\n        return vec3(0.0);\n    }\n    vec3 _6050 = a * inversesqrt(_6032);\n    vec3 _6055 = b * inversesqrt(_6036);\n    float _6059 = dot(_6050, _6055);\n    float _6062 = abs(_6059);\n    float g = (((((((((((0.0416471660137176513671875 * _6062) - 0.1924748718738555908203125) * _6062) + 0.4179156124591827392578125) * _6062) - 0.616057217121124267578125) * _6062) + 0.777722418308258056640625) * _6062) - 0.999542415142059326171875) * _6062) + 1.570791721343994140625;\n    if (_6059 < 0.0)\n    {\n        g = (3.1415927410125732421875 * inversesqrt(max(1.0 - (_6059 * _6059), 1.0000000116860974230803549289703e-07))) - g;\n    }\n    return cross(_6050, _6055) * g;\n}\n\nvoid fa_ltc_clip_edge(vec3 a, vec3 b, inout vec3 sum, inout vec3 leave, inout vec3 enter, inout vec2 seen)\n{\n    bool _6119 = a.z > 0.0;\n    bool _6123 = b.z > 0.0;\n    if (_6119 && _6123)\n    {\n        vec3 param = a;\n        vec3 param_1 = b;\n        sum += fa_ltc_edge_vector(param, param_1);\n    }\n    else\n    {\n        if (_6119 != _6123)\n        {\n            vec3 _6158 = a + ((b - a) * (a.z / (a.z - b.z)));\n            _6158.z = 0.0;\n            if (_6119)\n            {\n                vec3 param_2 = a;\n                vec3 param_3 = _6158;\n                sum += fa_ltc_edge_vector(param_2, param_3);\n                leave = _6158;\n                seen.x = 1.0;\n            }\n            else\n            {\n                vec3 param_4 = _6158;\n                vec3 param_5 = b;\n                sum += fa_ltc_edge_vector(param_4, param_5);\n                enter = _6158;\n                seen.y = 1.0;\n            }\n        }\n    }\n}\n\nfloat fa_ltc_quad(vec4 abcd, vec3 p0, vec3 p1, vec3 p2, vec3 p3)\n{\n    vec3 _6207 = vec3((abcd.x * p0.x) + (abcd.y * p0.z), p0.y, (abcd.z * p0.x) + (abcd.w * p0.z));\n    vec3 _6233 = vec3((abcd.x * p1.x) + (abcd.y * p1.z), p1.y, (abcd.z * p1.x) + (abcd.w * p1.z));\n    vec3 _6259 = vec3((abcd.x * p2.x) + (abcd.y * p2.z), p2.y, (abcd.z * p2.x) + (abcd.w * p2.z));\n    vec3 _6285 = vec3((abcd.x * p3.x) + (abcd.y * p3.z), p3.y, (abcd.z * p3.x) + (abcd.w * p3.z));\n    vec3 sum = vec3(0.0);\n    vec3 leave = vec3(0.0);\n    vec3 enter = vec3(0.0);\n    vec3 param = _6207;\n    vec3 param_1 = _6233;\n    vec3 param_2 = vec3(0.0);\n    vec3 param_3 = vec3(0.0);\n    vec3 param_4 = vec3(0.0);\n    vec2 param_5 = vec2(0.0);\n    fa_ltc_clip_edge(param, param_1, param_2, param_3, param_4, param_5);\n    sum = param_2;\n    leave = param_3;\n    enter = param_4;\n    vec3 param_6 = _6233;\n    vec3 param_7 = _6259;\n    vec3 param_8 = param_2;\n    vec3 param_9 = param_3;\n    vec3 param_10 = param_4;\n    vec2 param_11 = param_5;\n    fa_ltc_clip_edge(param_6, param_7, param_8, param_9, param_10, param_11);\n    sum = param_8;\n    leave = param_9;\n    enter = param_10;\n    vec3 param_12 = _6259;\n    vec3 param_13 = _6285;\n    vec3 param_14 = param_8;\n    vec3 param_15 = param_9;\n    vec3 param_16 = param_10;\n    vec2 param_17 = param_11;\n    fa_ltc_clip_edge(param_12, param_13, param_14, param_15, param_16, param_17);\n    sum = param_14;\n    leave = param_15;\n    enter = param_16;\n    vec3 param_18 = _6285;\n    vec3 param_19 = _6207;\n    vec3 param_20 = param_14;\n    vec3 param_21 = param_15;\n    vec3 param_22 = param_16;\n    vec2 param_23 = param_17;\n    fa_ltc_clip_edge(param_18, param_19, param_20, param_21, param_22, param_23);\n    sum = param_20;\n    leave = param_21;\n    enter = param_22;\n    if ((param_23.x * param_23.y) > 0.5)\n    {\n        vec3 param_24 = leave;\n        vec3 param_25 = enter;\n        sum += fa_ltc_edge_vector(param_24, param_25);\n    }\n    return sum.z * 0.15915493667125701904296875;\n}\n\nfloat fa_ltc_rect(vec4 abcd, vec3 center, vec3 ex, vec3 ey)\n{\n    vec4 param = abcd;\n    vec3 param_1 = (center - ex) - ey;\n    vec3 param_2 = (center + ex) - ey;\n    vec3 param_3 = (center + ex) + ey;\n    vec3 param_4 = (center - ex) + ey;\n    return abs(fa_ltc_quad(param, param_1, param_2, param_3, param_4));\n}\n\nfloat fa_area_form(vec4 m, float shape, vec3 pc, vec3 ex, vec3 ey)\n{\n    if ((shape < 0.5) || (shape > 1.5))\n    {\n        vec4 param = m;\n        vec3 param_1 = pc;\n        vec3 param_2 = ex;\n        vec3 param_3 = ey;\n        return fa_ltc_rect(param, param_1, param_2, param_3);\n    }\n    vec3 _6434 = (pc + (ex * 0.92387950420379638671875)) + (ey * 0.3826834261417388916015625);\n    vec3 _6458 = (pc - (ex * 0.92387950420379638671875)) + (ey * 0.3826834261417388916015625);\n    vec3 _6474 = (pc - (ex * 0.3826834261417388916015625)) - (ey * 0.92387950420379638671875);\n    vec4 param_4 = m;\n    vec3 param_5 = _6434;\n    vec3 param_6 = (pc + (ex * 0.3826834261417388916015625)) + (ey * 0.92387950420379638671875);\n    vec3 param_7 = (pc - (ex * 0.3826834261417388916015625)) + (ey * 0.92387950420379638671875);\n    vec3 param_8 = _6458;\n    vec4 param_9 = m;\n    vec3 param_10 = _6434;\n    vec3 param_11 = _6458;\n    vec3 param_12 = (pc - (ex * 0.92387950420379638671875)) - (ey * 0.3826834261417388916015625);\n    vec3 param_13 = _6474;\n    vec4 param_14 = m;\n    vec3 param_15 = _6434;\n    vec3 param_16 = _6474;\n    vec3 param_17 = (pc + (ex * 0.3826834261417388916015625)) - (ey * 0.92387950420379638671875);\n    vec3 param_18 = (pc + (ex * 0.92387950420379638671875)) - (ey * 0.3826834261417388916015625);\n    return abs((fa_ltc_quad(param_4, param_5, param_6, param_7, param_8) + fa_ltc_quad(param_9, param_10, param_11, param_12, param_13)) + fa_ltc_quad(param_14, param_15, param_16, param_17, param_18));\n}\n\nvec2 fa_ltc_uv(float roughness, float ndv)\n{\n    return ((vec2(clamp((roughness - 0.0500000007450580596923828125) * 1.0526316165924072265625, 0.0, 1.0), sqrt(clamp(1.0 - ndv, 0.0, 1.0))) * 63.0) + vec2(0.5)) * vec2(0.015625);\n}\n\nvec3 fa_area_shade(int li, vec3 world_pos, vec3 n, vec3 v, vec3 diffuse_color, vec3 f0, float f90, float roughness, float ndv, float window)\n{\n    int param = li;\n    int _6532 = fa_light_base(param);\n    int param_1 = _6532;\n    int param_2 = _6532 + 1;\n    int param_3 = _6532 + 2;\n    int param_4 = _6532 + 4;\n    vec4 _6554 = fa_light_texel(param_4);\n    int param_5 = _6532 + 5;\n    vec4 _6559 = fa_light_texel(param_5);\n    int param_6 = _6532 + 6;\n    vec4 _6564 = fa_light_texel(param_6);\n    float _6565 = _6564.w;\n    vec3 _6570 = fa_light_texel(param_1).xyz - world_pos;\n    bool _6572 = _6565 < 1.5;\n    bool _6579;\n    if (_6572)\n    {\n        _6579 = dot(normalize(fa_light_texel(param_3).xyz), _6570) >= 0.0;\n    }\n    else\n    {\n        _6579 = _6572;\n    }\n    if (_6579)\n    {\n        return vec3(0.0);\n    }\n    bool _6588 = (_6565 > 0.5) && _6572;\n    float _6592 = _6588 ? 1.0539000034332275390625 : 1.0;\n    vec3 _6595 = _6554.xyz;\n    float _6597 = _6554.w;\n    vec3 _6603 = _6559.xyz;\n    float _6605 = _6559.w;\n    vec3 up = _6603 * (_6605 * _6592);\n    float _6611;\n    if (_6588)\n    {\n        _6611 = (3.1415927410125732421875 * _6597) * _6597;\n    }\n    else\n    {\n        _6611 = (4.0 * _6597) * _6605;\n    }\n    if (_6565 > 1.5)\n    {\n        vec3 _6637 = cross(_6595, -_6570);\n        vec3 perp = _6637;\n        float _6641 = dot(_6637, _6637);\n        vec3 _6644;\n        if (_6641 > 1.0000000133514319600180897396058e-10)\n        {\n            _6644 = perp * inversesqrt(_6641);\n        }\n        else\n        {\n            _6644 = _6603;\n        }\n        perp = _6644;\n        up = _6644 * _6605;\n    }\n    float _6665 = max(_6611, 9.9999999747524270787835121154785e-07);\n    vec3 param_7 = n;\n    vec3 param_8 = v;\n    vec3 _6675 = fa_ltc_tangent(param_7, param_8);\n    vec3 param_9 = _6675;\n    vec3 param_10 = n;\n    vec3 param_11 = _6570;\n    vec3 _6683 = fa_ltc_local(param_9, param_10, param_11);\n    vec3 param_12 = _6675;\n    vec3 param_13 = n;\n    vec3 param_14 = _6595 * (_6597 * _6592);\n    vec3 _6691 = fa_ltc_local(param_12, param_13, param_14);\n    vec3 param_15 = _6675;\n    vec3 param_16 = n;\n    vec3 param_17 = up;\n    vec3 _6699 = fa_ltc_local(param_15, param_16, param_17);\n    vec4 param_18 = vec4(1.0, 0.0, 0.0, 1.0);\n    float param_19 = _6565;\n    vec3 param_20 = _6683;\n    vec3 param_21 = _6691;\n    vec3 param_22 = _6699;\n    float param_23 = roughness;\n    float param_24 = ndv;\n    vec2 _6718 = fa_ltc_uv(param_23, param_24) * 64.0;\n    vec2 param_25 = _6718;\n    vec2 param_26 = _6718 + vec2(64.0, 0.0);\n    vec4 _6728 = fa_atlas_fetch(param_26);\n    vec4 param_27 = fa_atlas_fetch(param_25);\n    float param_28 = _6565;\n    vec3 param_29 = _6683;\n    vec3 param_30 = _6691;\n    vec3 param_31 = _6699;\n    return (((diffuse_color * fa_area_form(param_18, param_19, param_20, param_21, param_22)) + (((f0 * _6728.x) + ((vec3(f90) - f0) * _6728.y)) * fa_area_form(param_27, param_28, param_29, param_30, param_31))) * fa_light_texel(param_2).xyz) * ((((3.1415927410125732421875 * dot(_6570, _6570)) + _6665) / _6665) * window);\n}\n\nvec3 fa_light_rgb(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 1;\n    return fa_light_texel(param_1).xyz;\n}\n\nfloat fa_d_charlie(float alpha, float ndh)\n{\n    float _4875 = 1.0 / alpha;\n    return ((2.0 + _4875) * pow(sqrt(max(1.0 - (ndh * ndh), 9.9999997473787516355514526367188e-05)), _4875)) * 0.15915493667125701904296875;\n}\n\nfloat fa_v_ashikhmin(float ndl, float ndv)\n{\n    return clamp(0.25 / max((ndl + ndv) - (ndl * ndv), 9.9999997473787516355514526367188e-05), 0.0, 1.0);\n}\n\nfloat fa_layers_coat(FaLayers L, vec3 l, vec3 h, float vdh)\n{\n    float _4910 = max(dot(L.nc, l), 0.0);\n    float _4916 = max(dot(L.nc, h), 0.0);\n    float _4925 = ((_4916 * _4916) * (L.coat_a2 - 1.0)) + 1.0;\n    return (((L.coat * (0.039999999105930328369140625 + (0.959999978542327880859375 * pow(clamp(1.0 - vdh, 0.0, 1.0), 5.0)))) * (((L.coat_a2 / ((3.1415927410125732421875 * _4925) * _4925)) * (0.5 / max(mix((2.0 * _4910) * L.coat_ndv, _4910 + L.coat_ndv, L.coat_alpha), 9.9999997473787516355514526367188e-05))) * 3.1415927410125732421875)) * step(9.9999997473787516355514526367188e-05, _4910)) * _4910;\n}\n\nvec3 fa_area_layers(FaLayers L, int li, vec3 world_pos, vec3 n, vec3 v, vec3 l, vec3 diffuse_color, vec3 f0, float roughness, float ndv, float window)\n{\n    int param = li;\n    vec3 param_1 = world_pos;\n    vec3 param_2 = n;\n    vec3 param_3 = v;\n    vec3 param_4 = diffuse_color;\n    vec3 param_5 = f0;\n    float param_6 = L.f90;\n    float param_7 = roughness;\n    float param_8 = ndv;\n    float param_9 = window;\n    float _6796;\n    if (L.sheen_on)\n    {\n        _6796 = L.sheen_scale;\n    }\n    else\n    {\n        _6796 = 1.0;\n    }\n    vec3 result = fa_area_shade(param, param_1, param_2, param_3, param_4, param_5, param_6, param_7, param_8, param_9) * (L.keep * _6796);\n    vec3 _6809 = normalize(l + v);\n    int param_10 = li;\n    vec3 _6820 = fa_light_rgb(param_10) * window;\n    if (L.sheen_on)\n    {\n        float _6829 = max(dot(n, l), 0.0);\n        float param_11 = L.sheen_alpha;\n        float param_12 = max(dot(n, _6809), 0.0);\n        float param_13 = _6829;\n        float param_14 = ndv;\n        result += ((L.sheen * _6820) * (((((fa_d_charlie(param_11, param_12) * fa_v_ashikhmin(param_13, param_14)) * 3.1415927410125732421875) * step(9.9999997473787516355514526367188e-05, _6829)) * _6829) * L.keep));\n    }\n    if (L.coat > 0.0)\n    {\n        FaLayers param_15 = L;\n        vec3 param_16 = l;\n        vec3 param_17 = _6809;\n        float param_18 = max(dot(v, _6809), 0.0);\n        result += (_6820 * fa_layers_coat(param_15, param_16, param_17, param_18));\n    }\n    return result;\n}\n\nfloat fa_d_ggx_aniso(float ndh, float tdh, float bdh, float at, float ab)\n{\n    float _4778 = tdh / at;\n    float _4782 = bdh / ab;\n    float _4794 = ((_4778 * _4778) + (_4782 * _4782)) + (ndh * ndh);\n    return 1.0 / ((((3.1415927410125732421875 * at) * ab) * _4794) * _4794);\n}\n\nfloat fa_lambda_ggx_aniso(float n, float t, float b, float at, float ab)\n{\n    return 0.5 * (sqrt(1.0 + (((((at * at) * t) * t) + (((ab * ab) * b) * b)) / max(n * n, 9.9999999392252902907785028219223e-09))) - 1.0);\n}\n\nfloat fa_v_ggx_aniso(float ndl, float ndv, float tdv, float bdv, float tdl, float bdl, float at, float ab)\n{\n    float param = ndv;\n    float param_1 = tdv;\n    float param_2 = bdv;\n    float param_3 = at;\n    float param_4 = ab;\n    float param_5 = ndl;\n    float param_6 = tdl;\n    float param_7 = bdl;\n    float param_8 = at;\n    float param_9 = ab;\n    return clamp(1.0 / ((4.0 * max(ndl * ndv, 9.9999997473787516355514526367188e-05)) * ((1.0 + fa_lambda_ggx_aniso(param, param_1, param_2, param_3, param_4)) + fa_lambda_ggx_aniso(param_5, param_6, param_7, param_8, param_9))), 0.0, 1.0);\n}\n\nvec3 fa_layers_light(FaLayers L, vec3 diffuse_color, vec3 f0, vec3 n, vec3 v, vec3 l, vec3 h, float ndl, float ndv, float ndh, float vdh, float alpha, float a2)\n{\n    float _4974 = step(9.9999997473787516355514526367188e-05, ndl);\n    float d_ggx;\n    float vis;\n    if (L.aniso != 0.0)\n    {\n        float param = ndh;\n        float param_1 = dot(L.t, h);\n        float param_2 = dot(L.b, h);\n        float param_3 = L.at;\n        float param_4 = L.ab;\n        d_ggx = fa_d_ggx_aniso(param, param_1, param_2, param_3, param_4);\n        float param_5 = ndl;\n        float param_6 = ndv;\n        float param_7 = dot(L.t, v);\n        float param_8 = dot(L.b, v);\n        float param_9 = dot(L.t, l);\n        float param_10 = dot(L.b, l);\n        float param_11 = L.at;\n        float param_12 = L.ab;\n        vis = fa_v_ggx_aniso(param_5, param_6, param_7, param_8, param_9, param_10, param_11, param_12);\n    }\n    else\n    {\n        float _5053 = ((ndh * ndh) * (a2 - 1.0)) + 1.0;\n        d_ggx = a2 / ((3.1415927410125732421875 * _5053) * _5053);\n        vis = 0.5 / max(mix((2.0 * ndl) * ndv, ndl + ndv, alpha), 9.9999997473787516355514526367188e-05);\n    }\n    vec3 base = diffuse_color + (((f0 + ((vec3(L.f90) - f0) * pow(clamp(1.0 - vdh, 0.0, 1.0), 5.0))) * ((d_ggx * vis) * 3.1415927410125732421875)) * _4974);\n    if (L.sheen_on)\n    {\n        float param_13 = L.sheen_alpha;\n        float param_14 = ndh;\n        float param_15 = ndl;\n        float param_16 = ndv;\n        base = (base * L.sheen_scale) + (L.sheen * (((fa_d_charlie(param_13, param_14) * fa_v_ashikhmin(param_15, param_16)) * 3.1415927410125732421875) * _4974));\n    }\n    vec3 result = base * (L.keep * ndl);\n    if (L.coat > 0.0)\n    {\n        FaLayers param_17 = L;\n        vec3 param_18 = l;\n        vec3 param_19 = h;\n        float param_20 = vdh;\n        result += vec3(fa_layers_coat(param_17, param_18, param_19, param_20));\n    }\n    return result;\n}\n\nvec2 fa_env_brdf(float rough, float ndv)\n{\n    vec4 _4184 = (vec4(-1.0, -0.0274999998509883880615234375, -0.572000026702880859375, 0.02199999988079071044921875) * rough) + vec4(1.0, 0.0425000004470348358154296875, 1.03999996185302734375, -0.039999999105930328369140625);\n    float _4187 = _4184.x;\n    return (vec2(-1.03999996185302734375, 1.03999996185302734375) * ((min(_4187 * _4187, exp2((-9.27999973297119140625) * ndv)) * _4187) + _4184.y)) + _4184.zw;\n}\n\nvec2 fa_oct_encode(vec3 d)\n{\n    vec3 _3443 = d / vec3(max((abs(d.x) + abs(d.y)) + abs(d.z), 9.9999999600419720025001879548654e-13));\n    float _3446 = _3443.x;\n    float _3448 = _3443.z;\n    vec2 e = vec2(_3446, _3448);\n    if (_3443.y < 0.0)\n    {\n        e = vec2((1.0 - abs(_3448)) * ((_3446 < 0.0) ? (-1.0) : 1.0), (1.0 - abs(_3446)) * ((_3448 < 0.0) ? (-1.0) : 1.0));\n    }\n    return e;\n}\n\nvec3 fa_probe_level(vec2 origin, float res, int lv, vec2 e)\n{\n    float _3495;\n    if (lv == 0)\n    {\n        _3495 = 0.0;\n    }\n    else\n    {\n        _3495 = res + 2.0;\n    }\n    float _3505;\n    if (lv == 0)\n    {\n        _3505 = 0.0;\n    }\n    else\n    {\n        _3505 = (res - (res / float(1 << (lv - 1)))) + (2.0 * float(lv - 1));\n    }\n    return textureLod(fa_probe_atlas_fa_env_smp, (((origin + vec2(_3495, _3505)) + vec2(1.0)) + (((e * 0.5) + vec2(0.5)) * (res / float(1 << lv)))) / fa_atlas_size(), 0.0).xyz;\n}\n\nvec3 fa_probe_radiance(vec2 origin, float res, vec3 d, float rough)\n{\n    float _3550;\n    if (res > 64.5)\n    {\n        _3550 = 5.0;\n    }\n    else\n    {\n        _3550 = (res > 32.5) ? 4.0 : 3.0;\n    }\n    float _3565 = clamp(rough, 0.0, 1.0) * (_3550 - 1.0);\n    int _3572 = int(min(floor(_3565), _3550 - 2.0));\n    float _3577 = _3565 - float(_3572);\n    vec3 param = d;\n    vec2 _3581 = fa_oct_encode(param);\n    vec2 param_1 = origin;\n    float param_2 = res;\n    int param_3 = _3572;\n    vec2 param_4 = _3581;\n    vec3 _3591 = fa_probe_level(param_1, param_2, param_3, param_4);\n    if (_3577 < 0.00200000009499490261077880859375)\n    {\n        return _3591;\n    }\n    vec2 param_5 = origin;\n    float param_6 = res;\n    int param_7 = _3572 + 1;\n    vec2 param_8 = _3581;\n    return mix(_3591, fa_probe_level(param_5, param_6, param_7, param_8), vec3(_3577));\n}\n\nvec3 fa_probe_box_dir(vec3 d, vec4 posw, vec4 bx, vec4 by, vec4 bz)\n{\n    if (posw.w < 0.5)\n    {\n        return d;\n    }\n    float _3661 = dot(bx.xyz, fa_world_pos) + bx.w;\n    float _3668 = dot(by.xyz, fa_world_pos) + by.w;\n    float _3675 = dot(bz.xyz, fa_world_pos) + bz.w;\n    float _3681 = dot(bx.xyz, d);\n    float _3685 = dot(by.xyz, d);\n    float _3689 = dot(bz.xyz, d);\n    float _3695;\n    if (_3681 > 9.9999999747524270787835121154785e-07)\n    {\n        _3695 = (1.0 - _3661) / _3681;\n    }\n    else\n    {\n        float _3709;\n        if (_3681 < (-9.9999999747524270787835121154785e-07))\n        {\n            _3709 = ((-1.0) - _3661) / _3681;\n        }\n        else\n        {\n            _3709 = 1000000015047466219876688855040.0;\n        }\n        _3695 = _3709;\n    }\n    float tx = _3695;\n    float _3726;\n    if (_3685 > 9.9999999747524270787835121154785e-07)\n    {\n        _3726 = (1.0 - _3668) / _3685;\n    }\n    else\n    {\n        float _3739;\n        if (_3685 < (-9.9999999747524270787835121154785e-07))\n        {\n            _3739 = ((-1.0) - _3668) / _3685;\n        }\n        else\n        {\n            _3739 = 1000000015047466219876688855040.0;\n        }\n        _3726 = _3739;\n    }\n    float ty = _3726;\n    float _3755;\n    if (_3689 > 9.9999999747524270787835121154785e-07)\n    {\n        _3755 = (1.0 - _3675) / _3689;\n    }\n    else\n    {\n        float _3768;\n        if (_3689 < (-9.9999999747524270787835121154785e-07))\n        {\n            _3768 = ((-1.0) - _3675) / _3689;\n        }\n        else\n        {\n            _3768 = 1000000015047466219876688855040.0;\n        }\n        _3755 = _3768;\n    }\n    float _3780 = tx;\n    float _3783 = (_3780 > 0.0) ? _3780 : 1000000015047466219876688855040.0;\n    tx = _3783;\n    float _3784 = ty;\n    float _3787 = (_3784 > 0.0) ? _3784 : 1000000015047466219876688855040.0;\n    ty = _3787;\n    float _3797 = min(_3783, min(_3787, (_3755 > 0.0) ? _3755 : 1000000015047466219876688855040.0));\n    if (_3797 > 100000001504746621987668885504.0)\n    {\n        return d;\n    }\n    vec3 _3813 = (fa_world_pos + (d * _3797)) - posw.xyz;\n    vec3 _3818;\n    if (dot(_3813, _3813) > 1.0000000133514319600180897396058e-10)\n    {\n        _3818 = normalize(_3813);\n    }\n    else\n    {\n        _3818 = d;\n    }\n    return _3818;\n}\n\nvec3 fa_probe_environment(vec4 tile, vec4 posw, vec4 bx, vec4 by, vec4 bz, inout vec3 d, float rough)\n{\n    vec3 param = d;\n    vec4 param_1 = posw;\n    vec4 param_2 = bx;\n    vec4 param_3 = by;\n    vec4 param_4 = bz;\n    d = fa_probe_box_dir(param, param_1, param_2, param_3, param_4);\n    vec2 param_5 = tile.xy;\n    float param_6 = tile.z;\n    vec3 param_7 = d;\n    float param_8 = rough;\n    return fa_probe_radiance(param_5, param_6, param_7, param_8);\n}\n\nvec3 fa_environment(vec3 d, float rough)\n{\n    float _3864 = (1.0 - fa_mesh_fs_params[42].w) - fa_mesh_fs_params[47].w;\n    vec3 outc = vec3(0.0);\n    if (_3864 > 0.0005000000237487256526947021484375)\n    {\n        vec3 base;\n        if (fa_mesh_fs_params[11].w > 0.5)\n        {\n            vec2 param = fa_mesh_fs_params[41].zw;\n            float param_1 = 128.0;\n            vec3 param_2 = d;\n            float param_3 = rough;\n            base = fa_probe_radiance(param, param_1, param_2, param_3);\n        }\n        else\n        {\n            float _3893 = rough * rough;\n            float _3924 = 0.60000002384185791015625 * _3893;\n            base = mix(mix(fa_mesh_fs_params[12].xyz * 0.550000011920928955078125, mix(fa_mesh_fs_params[12].xyz, fa_mesh_fs_params[11].xyz, vec3(pow(clamp(d.y * (1.0 - (0.699999988079071044921875 * _3893)), 0.0, 1.0), 0.550000011920928955078125))), vec3(smoothstep((-0.0500000007450580596923828125) - _3924, 0.0500000007450580596923828125 + _3924, d.y))), ((fa_mesh_fs_params[11].xyz + fa_mesh_fs_params[12].xyz) * 0.5) * 0.800000011920928955078125, vec3(_3893 * 0.60000002384185791015625));\n        }\n        outc = base * _3864;\n    }\n    if (fa_mesh_fs_params[42].w > 0.0)\n    {\n        vec4 param_4 = fa_mesh_fs_params[42];\n        vec4 param_5 = fa_mesh_fs_params[43];\n        vec4 param_6 = fa_mesh_fs_params[44];\n        vec4 param_7 = fa_mesh_fs_params[45];\n        vec4 param_8 = fa_mesh_fs_params[46];\n        vec3 param_9 = d;\n        float param_10 = rough;\n        vec3 _3983 = fa_probe_environment(param_4, param_5, param_6, param_7, param_8, param_9, param_10);\n        outc += (_3983 * fa_mesh_fs_params[42].w);\n    }\n    if (fa_mesh_fs_params[47].w > 0.0)\n    {\n        vec4 param_11 = fa_mesh_fs_params[47];\n        vec4 param_12 = fa_mesh_fs_params[48];\n        vec4 param_13 = fa_mesh_fs_params[49];\n        vec4 param_14 = fa_mesh_fs_params[50];\n        vec4 param_15 = fa_mesh_fs_params[51];\n        vec3 param_16 = d;\n        float param_17 = rough;\n        vec3 _4015 = fa_probe_environment(param_11, param_12, param_13, param_14, param_15, param_16, param_17);\n        outc += (_4015 * fa_mesh_fs_params[47].w);\n    }\n    return outc;\n}\n\nvec3 fa_layers_ibl(FaLayers L, vec3 n, vec3 v, vec3 f0, float roughness)\n{\n    vec3 rn = n;\n    if (L.aniso != 0.0)\n    {\n        vec3 _4661;\n        if (L.aniso >= 0.0)\n        {\n            _4661 = L.b;\n        }\n        else\n        {\n            _4661 = L.t;\n        }\n        rn = normalize(mix(n, cross(cross(_4661, v), _4661), vec3(abs(L.aniso))));\n    }\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05);\n    vec2 _4694 = fa_env_brdf(param, param_1);\n    vec3 param_2 = reflect(-v, rn);\n    float param_3 = roughness;\n    vec3 result = (fa_environment(param_2, param_3) * ((f0 * _4694.x) + (vec3(L.f90) * _4694.y))) * L.base_scale;\n    if (L.sheen_on)\n    {\n        vec3 param_4 = n;\n        float param_5 = L.sheen_rough;\n        result += ((L.sheen * (L.sheen_e * L.keep)) * fa_environment(param_4, param_5));\n    }\n    if (L.coat > 0.0)\n    {\n        float param_6 = L.coat_rough;\n        float param_7 = L.coat_ndv;\n        vec2 _4749 = fa_env_brdf(param_6, param_7);\n        vec3 param_8 = reflect(-v, L.nc);\n        float param_9 = L.coat_rough;\n        result += (fa_environment(param_8, param_9) * (L.coat * ((0.039999999105930328369140625 * _4749.x) + _4749.y)));\n    }\n    return result;\n}\n\nvec3 fa_sky_reflection(vec3 n, vec3 v, vec3 f0, float roughness)\n{\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05);\n    vec2 _4226 = fa_env_brdf(param, param_1);\n    vec3 param_2 = reflect(-v, n);\n    float param_3 = roughness;\n    return fa_environment(param_2, param_3) * ((f0 * _4226.x) + vec3(_4226.y));\n}\n\nvec2 fa_xm_size(int k)\n{\n    return max(floor(fa_mesh_fs_params[24].zw / vec2(exp2(float(k)))), vec2(1.0));\n}\n\nvec2 fa_xm_origin(int k)\n{\n    if (k == 0)\n    {\n        return vec2(0.0);\n    }\n    float y = 0.0;\n    for (int j = 1; j < k; j++)\n    {\n        int param = j;\n        y += fa_xm_size(param).y;\n    }\n    return vec2(fa_mesh_fs_params[24].z, y);\n}\n\nvec3 fa_xm_texel(vec2 size, vec2 origin, vec2 p)\n{\n    return texelFetch(fa_screen_tex_fa_shadow_smp, ivec2(origin + clamp(p, vec2(0.0), size - vec2(1.0))), 0).xyz;\n}\n\nvec3 fa_xm_level(int k, vec2 uv)\n{\n    int param = k;\n    vec2 _5451 = fa_xm_size(param);\n    int param_1 = k;\n    vec2 _5455 = fa_xm_origin(param_1);\n    vec2 _5461 = (uv * _5451) - vec2(0.5);\n    vec2 _5464 = fract(_5461);\n    vec2 _5467 = floor(_5461);\n    vec2 param_2 = _5451;\n    vec2 param_3 = _5455;\n    vec2 param_4 = _5467;\n    vec2 param_5 = _5451;\n    vec2 param_6 = _5455;\n    vec2 param_7 = _5467 + vec2(1.0, 0.0);\n    vec2 param_8 = _5451;\n    vec2 param_9 = _5455;\n    vec2 param_10 = _5467 + vec2(0.0, 1.0);\n    vec2 param_11 = _5451;\n    vec2 param_12 = _5455;\n    vec2 param_13 = _5467 + vec2(1.0);\n    vec3 _5509 = vec3(_5464.x);\n    return mix(mix(fa_xm_texel(param_2, param_3, param_4), fa_xm_texel(param_5, param_6, param_7), _5509), mix(fa_xm_texel(param_8, param_9, param_10), fa_xm_texel(param_11, param_12, param_13), _5509), vec3(_5464.y));\n}\n\nvec3 fa_xm_sample(vec2 uv, float lod)\n{\n    float _5528 = max(fa_mesh_fs_params[31].w - 1.0, 0.0);\n    float _5532 = clamp(lod, 0.0, _5528);\n    int _5536 = int(floor(_5532));\n    int param = _5536;\n    vec2 param_1 = uv;\n    vec3 c = fa_xm_level(param, param_1);\n    float _5546 = float(_5536);\n    float _5547 = _5532 - _5546;\n    bool _5549 = _5547 > 0.001000000047497451305389404296875;\n    bool _5556;\n    if (_5549)\n    {\n        _5556 = _5546 < _5528;\n    }\n    else\n    {\n        _5556 = _5549;\n    }\n    if (_5556)\n    {\n        int param_2 = _5536 + 1;\n        vec2 param_3 = uv;\n        c = mix(c, fa_xm_level(param_2, param_3), vec3(_5547));\n    }\n    return c;\n}\n\nvec3 fa_transmitted(Surface s, vec3 n, vec3 v, float roughness, vec3 f0, float f90, float keep, float tr, inout float blend)\n{\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05);\n    vec2 _5582 = fa_env_brdf(param, param_1);\n    vec3 through = ((vec3(1.0) - clamp((f0 * _5582.x) + (vec3(f90) * _5582.y), vec3(0.0), vec3(1.0))) * s.albedo) * (tr * keep);\n    float _5610 = max(s.thickness, 0.0);\n    bool _5615 = _5610 > 0.0;\n    if ((s.attenuation_distance > 0.0) && _5615)\n    {\n        through *= exp((-((-log(clamp(s.attenuation_color, vec3(9.9999997473787516355514526367188e-05), vec3(1.0)))) / vec3(s.attenuation_distance))) * _5610);\n    }\n    bool _5640 = fa_mesh_fs_params[30].w > 1.5;\n    bool _5647;\n    if (!_5640)\n    {\n        _5647 = fa_mesh_fs_params[30].w < 0.5;\n    }\n    else\n    {\n        _5647 = _5640;\n    }\n    if (_5647)\n    {\n        blend = clamp(dot(through, vec3(0.3333333432674407958984375)), 0.0, 0.980000019073486328125);\n        return vec3(0.0);\n    }\n    vec3 world = fa_world_pos;\n    if (_5615)\n    {\n        world += (refract(-v, n, 1.0 / max(s.ior, 1.0)) * _5610);\n    }\n    vec4 _5682 = vec4(world, 1.0);\n    float _5687 = dot(fa_mesh_fs_params[28], _5682);\n    vec2 uv = vec2(0.5);\n    if (_5687 > 9.9999997473787516355514526367188e-05)\n    {\n        vec2 _5705 = vec2(dot(fa_mesh_fs_params[26], _5682), dot(fa_mesh_fs_params[27], _5682)) / vec2(_5687);\n        float _5713;\n        if (fa_mesh_fs_params[24].y > 0.5)\n        {\n            _5713 = (_5705.y * 0.5) + 0.5;\n        }\n        else\n        {\n            _5713 = 0.5 - (_5705.y * 0.5);\n        }\n        uv = vec2((_5705.x * 0.5) + 0.5, _5713);\n    }\n    vec2 param_2 = clamp(uv, vec2(0.0), vec2(1.0));\n    float param_3 = (clamp(roughness, 0.0, 1.0) * clamp((2.0 * s.ior) - 2.0, 0.0, 1.0)) * max(fa_mesh_fs_params[31].w - 1.0, 0.0);\n    return through * fa_xm_sample(param_2, param_3);\n}\n\nvec3 fa_shadow_debug(vec3 color, vec3 world)\n{\n    if (fa_shadows[27].w < 0.5)\n    {\n        return color;\n    }\n    int _3246 = int(fa_shadows[25].x + 0.5);\n    float _3256 = dot(world - fa_shadows[27].xyz, fa_shadows[28].xyz);\n    vec3 tint_1 = vec3(0.3499999940395355224609375);\n    bool _3261 = _3246 > 0;\n    bool _3270;\n    if (_3261)\n    {\n        int param = _3246 - 1;\n        _3270 = _3256 <= fa_shadow_split_at(param);\n    }\n    else\n    {\n        _3270 = _3261;\n    }\n    if (_3270)\n    {\n        tint_1 = vec3(1.0, 0.1500000059604644775390625, 0.100000001490116119384765625);\n        bool _3276 = _3246 > 1;\n        bool _3283;\n        if (_3276)\n        {\n            _3283 = _3256 > fa_shadows[24].x;\n        }\n        else\n        {\n            _3283 = _3276;\n        }\n        if (_3283)\n        {\n            tint_1 = vec3(0.100000001490116119384765625, 0.89999997615814208984375, 0.20000000298023223876953125);\n        }\n        bool _3289 = _3246 > 2;\n        bool _3296;\n        if (_3289)\n        {\n            _3296 = _3256 > fa_shadows[24].y;\n        }\n        else\n        {\n            _3296 = _3289;\n        }\n        if (_3296)\n        {\n            tint_1 = vec3(0.1500000059604644775390625, 0.300000011920928955078125, 1.0);\n        }\n        bool _3302 = _3246 > 3;\n        bool _3309;\n        if (_3302)\n        {\n            _3309 = _3256 > fa_shadows[24].z;\n        }\n        else\n        {\n            _3309 = _3302;\n        }\n        if (_3309)\n        {\n            tint_1 = vec3(1.0, 0.89999997615814208984375, 0.100000001490116119384765625);\n        }\n    }\n    return mix(color, tint_1, vec3(0.550000011920928955078125));\n}\n\nvoid main()\n{\n    fa_inst_load();\n    vec3 _8035 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _8035 = -_8035;\n    }\n    vec3 _7330 = normalize(fa_mesh_fs_params[0].xyz - fa_world_pos);\n    vec3 param = fa_world_pos;\n    fa_cluster_begin(param);\n    SurfaceInput param_1 = SurfaceInput(fa_world_pos, _8035, fa_world_tangent, fa_uv, fa_vertex_color, _7330, gl_FrontFacing);\n    Surface _7338 = fa_standard_surface(param_1);\n    vec3 _8066 = _7338.albedo;\n    float _8067 = _7338.alpha;\n    vec3 _8068 = _7338.normal;\n    float _8069 = _7338.metallic;\n    float _8070 = _7338.roughness;\n    float _8071 = _7338.occlusion;\n    vec3 _8072 = _7338.emission;\n    float _8073 = _7338.clearcoat;\n    float _8074 = _7338.clearcoat_roughness;\n    vec3 _8075 = _7338.sheen_color;\n    float _8076 = _7338.sheen_roughness;\n    float _8077 = _7338.anisotropy;\n    float _8078 = _7338.anisotropy_rotation;\n    float _8079 = _7338.specular;\n    float _8080 = _7338.ior;\n    vec3 _8081 = _7338.specular_color;\n    float _8082 = _7338.transmission;\n    float _8083 = _7338.thickness;\n    vec3 _8084 = _7338.attenuation_color;\n    float _8085 = _7338.attenuation_distance;\n    SurfaceInput param_2 = SurfaceInput(fa_world_pos, _8035, fa_world_tangent, fa_uv, fa_vertex_color, _7330, gl_FrontFacing);\n    Surface param_3 = _7338;\n    surface(param_2, param_3);\n    _8066 = param_3.albedo;\n    _8067 = param_3.alpha;\n    _8068 = param_3.normal;\n    _8069 = param_3.metallic;\n    _8070 = param_3.roughness;\n    _8071 = param_3.occlusion;\n    _8072 = param_3.emission;\n    _8073 = param_3.clearcoat;\n    _8074 = param_3.clearcoat_roughness;\n    _8075 = param_3.sheen_color;\n    _8076 = param_3.sheen_roughness;\n    _8077 = param_3.anisotropy;\n    _8078 = param_3.anisotropy_rotation;\n    _8079 = param_3.specular;\n    _8080 = param_3.ior;\n    _8081 = param_3.specular_color;\n    _8082 = param_3.transmission;\n    _8083 = param_3.thickness;\n    _8084 = param_3.attenuation_color;\n    _8085 = param_3.attenuation_distance;\n    vec3 param_4 = fa_world_pos;\n    vec3 param_5 = _8035;\n    vec3 param_6 = param_3.albedo;\n    vec3 param_7 = param_3.normal;\n    fa_apply_decals(param_4, param_5, param_6, param_7);\n    _8066 = param_6;\n    _8068 = param_7;\n    float fa_tr_blend = 0.0;\n    vec3 result;\n    if (fa_mesh_fs_params[3].w > 0.5)\n    {\n        result = _8066;\n    }\n    else\n    {\n        vec3 _7378 = normalize(_8068);\n        float _7385 = clamp(_8069, 0.0, 1.0);\n        float _7389 = clamp(_8070, 0.0500000007450580596923828125, 1.0);\n        float _7393 = _7389 * _7389;\n        float _7397 = _7393 * _7393;\n        float _7402 = max(dot(_7378, _7330), 9.9999997473787516355514526367188e-05);\n        float _7408 = 1.0 - _7385;\n        float _7409 = clamp(_8082, 0.0, 1.0) * _7408;\n        vec3 _7418 = (_8066 * _7408) * (1.0 - _7409);\n        vec3 _7425 = mix(vec3(0.039999999105930328369140625), _8066, vec3(_7385));\n        vec3 f0 = _7425;\n        SurfaceInput param_8 = SurfaceInput(fa_world_pos, _8035, fa_world_tangent, fa_uv, fa_vertex_color, _7330, gl_FrontFacing);\n        Surface param_9 = Surface(_8066, _8067, _8068, _8069, _8070, _8071, _8072, _8073, _8074, _8075, _8076, _8077, _8078, _8079, _8080, _8081, _8082, _8083, _8084, _8085);\n        vec3 param_10 = _7378;\n        vec3 param_11 = _7330;\n        float param_12 = _7385;\n        float param_13 = _7389;\n        vec3 param_14 = _7425;\n        FaLayers _7441 = fa_layers_setup(param_8, param_9, param_10, param_11, param_12, param_13, param_14);\n        f0 = param_14;\n        vec3 param_15 = _7378;\n        vec3 lit = (fa_indirect_diffuse(param_15) * _7418) * _8071;\n        if (_7441.on)\n        {\n            lit *= _7441.base_scale;\n        }\n        int _7463 = fa_cl_ndir + fa_cl_local;\n        for (int ln = 0; ln < _7463; ln++)\n        {\n            int param_16 = ln;\n            int _7476 = fa_cl_light(param_16);\n            int param_17 = _7476;\n            if (fa_baked_keep(param_17) <= 0.0)\n            {\n                continue;\n            }\n            int param_18 = _7476;\n            vec3 param_19 = fa_world_pos;\n            vec3 param_20 = _8035;\n            LightSample _7492 = fa_light_shadowed(param_18, param_19, param_20);\n            float _7500 = max(dot(_7378, _7492.direction), 0.0);\n            float _7506 = _7492.attenuation * _7492.shadow;\n            vec3 _7511 = normalize(_7492.direction + _7330);\n            float _7516 = max(dot(_7378, _7511), 0.0);\n            float _7521 = max(dot(_7330, _7511), 0.0);\n            bool _7528;\n            if (fa_light_is_area)\n            {\n                _7528 = !_7441.on;\n            }\n            else\n            {\n                _7528 = fa_light_is_area;\n            }\n            if (_7528)\n            {\n                int param_21 = _7476;\n                vec3 param_22 = fa_world_pos;\n                vec3 param_23 = _7378;\n                vec3 param_24 = _7330;\n                vec3 param_25 = _7418;\n                vec3 param_26 = f0;\n                float param_27 = 1.0;\n                float param_28 = _7389;\n                float param_29 = _7402;\n                float param_30 = _7506;\n                lit += fa_area_shade(param_21, param_22, param_23, param_24, param_25, param_26, param_27, param_28, param_29, param_30);\n            }\n            else\n            {\n                if (fa_light_is_area)\n                {\n                    FaLayers param_31 = _7441;\n                    int param_32 = _7476;\n                    vec3 param_33 = fa_world_pos;\n                    vec3 param_34 = _7378;\n                    vec3 param_35 = _7330;\n                    vec3 param_36 = _7492.direction;\n                    vec3 param_37 = _7418;\n                    vec3 param_38 = f0;\n                    float param_39 = _7389;\n                    float param_40 = _7402;\n                    float param_41 = _7506;\n                    lit += fa_area_layers(param_31, param_32, param_33, param_34, param_35, param_36, param_37, param_38, param_39, param_40, param_41);\n                }\n                else\n                {\n                    if (_7441.on)\n                    {\n                        FaLayers param_42 = _7441;\n                        vec3 param_43 = _7418;\n                        vec3 param_44 = f0;\n                        vec3 param_45 = _7378;\n                        vec3 param_46 = _7330;\n                        vec3 param_47 = _7492.direction;\n                        vec3 param_48 = _7511;\n                        float param_49 = _7500;\n                        float param_50 = _7402;\n                        float param_51 = _7516;\n                        float param_52 = _7521;\n                        float param_53 = _7393;\n                        float param_54 = _7397;\n                        int param_55 = _7476;\n                        lit += (fa_layers_light(param_42, param_43, param_44, param_45, param_46, param_47, param_48, param_49, param_50, param_51, param_52, param_53, param_54) * ((fa_light_rgb(param_55) * fa_light_tint) * _7506));\n                    }\n                    else\n                    {\n                        float _7634 = ((_7516 * _7516) * (_7397 - 1.0)) + 1.0;\n                        int param_56 = _7476;\n                        lit += (((_7418 + (((f0 + ((vec3(1.0) - f0) * pow(1.0 - _7521, 5.0))) * (((_7397 / ((3.1415927410125732421875 * _7634) * _7634)) * (0.5 / max(mix((2.0 * _7500) * _7402, _7500 + _7402, _7393), 9.9999997473787516355514526367188e-05))) * 3.1415927410125732421875)) * step(9.9999997473787516355514526367188e-05, _7500))) * (fa_light_rgb(param_56) * fa_light_tint)) * (_7500 * _7506));\n                    }\n                }\n            }\n        }\n        if (_7441.on)\n        {\n            FaLayers param_57 = _7441;\n            vec3 param_58 = _7378;\n            vec3 param_59 = _7330;\n            vec3 param_60 = f0;\n            float param_61 = _7389;\n            lit += (fa_layers_ibl(param_57, param_58, param_59, param_60, param_61) * _8071);\n        }\n        else\n        {\n            vec3 param_62 = _7378;\n            vec3 param_63 = _7330;\n            vec3 param_64 = f0;\n            float param_65 = _7389;\n            lit += (fa_sky_reflection(param_62, param_63, param_64, param_65) * _8071);\n        }\n        if (_7409 > 0.0)\n        {\n            float _7732;\n            if (_7441.on)\n            {\n                _7732 = _7441.f90;\n            }\n            else\n            {\n                _7732 = 1.0;\n            }\n            float _7740;\n            if (_7441.on)\n            {\n                _7740 = _7441.base_scale;\n            }\n            else\n            {\n                _7740 = 1.0;\n            }\n            Surface param_66 = Surface(_8066, _8067, _8068, _8069, _8070, _8071, _8072, _8073, _8074, _8075, _8076, _8077, _8078, _8079, _8080, _8081, _8082, _8083, _8084, _8085);\n            vec3 param_67 = _7378;\n            vec3 param_68 = _7330;\n            float param_69 = _7389;\n            vec3 param_70 = f0;\n            float param_71 = _7732;\n            float param_72 = _7740;\n            float param_73 = _7409;\n            float param_74 = fa_tr_blend;\n            vec3 _7764 = fa_transmitted(param_66, param_67, param_68, param_69, param_70, param_71, param_72, param_73, param_74);\n            fa_tr_blend = param_74;\n            lit += _7764;\n        }\n        result = lit;\n    }\n    vec3 _7771 = result;\n    vec3 _7772 = _7771 + _8072;\n    result = _7772;\n    vec3 param_75 = _7772;\n    vec3 param_76 = fa_world_pos;\n    result = fa_shadow_debug(param_75, param_76);\n    bool _7781 = fa_mesh_fs_params[7].w > 0.0;\n    bool _7788;\n    if (!_7781)\n    {\n        _7788 = fa_mesh_fs_params[8].y > 0.0;\n    }\n    else\n    {\n        _7788 = _7781;\n    }\n    if (_7788)\n    {\n        vec3 _7797 = fa_world_pos - fa_mesh_fs_params[0].xyz;\n        float _7803 = dot(_7797, fa_mesh_fs_params[9].xyz);\n        bool _7807 = fa_mesh_fs_params[9].w > 0.5;\n        float _7808;\n        if (_7807)\n        {\n            _7808 = _7803;\n        }\n        else\n        {\n            _7808 = length(_7797);\n        }\n        float _7820 = _7808 - fa_mesh_fs_params[8].x;\n        if (_7820 > 0.0)\n        {\n            float _7829 = fa_mesh_fs_params[7].w * _7820;\n            float tau = _7829 * _7829;\n            if (fa_mesh_fs_params[8].y > 0.0)\n            {\n                float _7845;\n                if (_7807)\n                {\n                    _7845 = fa_world_pos.y - (fa_mesh_fs_params[9].y * _7803);\n                }\n                else\n                {\n                    _7845 = fa_mesh_fs_params[0].y;\n                }\n                float _7866 = mix(_7845, fa_world_pos.y, clamp(fa_mesh_fs_params[8].x / _7808, 0.0, 1.0));\n                float _7870 = fa_world_pos.y - _7866;\n                float _7875 = _7866 - fa_mesh_fs_params[8].z;\n                float _7880 = fa_world_pos.y - fa_mesh_fs_params[8].z;\n                bool _7883 = _7875 <= 0.0;\n                bool _7884 = !_7883;\n                bool _7890;\n                if (_7884)\n                {\n                    _7890 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _7890 = _7883;\n                }\n                float _7891;\n                if (_7890)\n                {\n                    _7891 = fa_mesh_fs_params[8].y;\n                }\n                else\n                {\n                    _7891 = fa_mesh_fs_params[8].y * exp(-min(fa_mesh_fs_params[8].w * _7875, 80.0));\n                }\n                bool _7918;\n                if (_7884)\n                {\n                    _7918 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _7918 = _7883;\n                }\n                float _7919;\n                if (_7918)\n                {\n                    _7919 = fa_mesh_fs_params[8].y * _7875;\n                }\n                else\n                {\n                    _7919 = (fa_mesh_fs_params[8].y * (1.0 - exp(-min(fa_mesh_fs_params[8].w * _7875, 80.0)))) / fa_mesh_fs_params[8].w;\n                }\n                bool _7944 = _7880 <= 0.0;\n                bool _7951;\n                if (!_7944)\n                {\n                    _7951 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _7951 = _7944;\n                }\n                float _7952;\n                if (_7951)\n                {\n                    _7952 = fa_mesh_fs_params[8].y * _7880;\n                }\n                else\n                {\n                    _7952 = (fa_mesh_fs_params[8].y * (1.0 - exp(-min(fa_mesh_fs_params[8].w * _7880, 80.0)))) / fa_mesh_fs_params[8].w;\n                }\n                float _7979;\n                if (abs(_7870) < 0.001000000047497451305389404296875)\n                {\n                    _7979 = _7891;\n                }\n                else\n                {\n                    _7979 = (_7952 - _7919) / _7870;\n                }\n                tau += (_7820 * max(_7979, 0.0));\n            }\n            result = mix(result, fa_mesh_fs_params[7].xyz, vec3(clamp(1.0 - exp(-clamp(tau, 0.0, 80.0)), 0.0, 1.0)));\n        }\n    }\n    if (fa_tr_blend > 0.0)\n    {\n        float _8015 = 1.0 - fa_tr_blend;\n        result /= vec3(_8015);\n        _8067 *= _8015;\n    }\n    fa_frag_color = vec4(result, _8067);\n}\n\n",
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
            "size": 832,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_643",
            "glsl_uniforms": [
              {
                "type": "vec4",
                "array_count": 52,
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
            "inst_name": "_2310",
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
            "inst_name": "_6898",
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
      "fs": "#version 430\n\nstruct SurfaceInput\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 vertex_color;\n    vec3 view_dir;\n    bool front_facing;\n};\n\nstruct Surface\n{\n    vec3 albedo;\n    float alpha;\n    vec3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    vec3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    vec3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    vec3 specular_color;\n    float transmission;\n    float thickness;\n    vec3 attenuation_color;\n    float attenuation_distance;\n};\n\nuniform vec4 fa_material[1];\nuniform vec4 fa_mesh_fs_params[52];\nlayout(binding = 0) uniform sampler2D fa_tex_fa_smp;\nlayout(binding = 1) uniform sampler2D fa_normal_tex_fa_smp;\nlayout(binding = 2) uniform sampler2D fa_mr_tex_fa_smp;\nlayout(binding = 3) uniform sampler2D fa_occlusion_tex_fa_smp;\nlayout(binding = 4) uniform sampler2D fa_emissive_tex_fa_smp;\n\nlayout(location = 0) flat in vec4 fa_inst_v0;\nlayout(location = 1) flat in vec4 fa_inst_v1;\nlayout(location = 2) in vec3 fa_world_pos;\nlayout(location = 3) in vec3 fa_world_normal;\nlayout(location = 4) in vec4 fa_world_tangent;\nlayout(location = 5) in vec2 fa_uv;\nlayout(location = 6) in vec4 fa_vertex_color;\nlayout(location = 8) in vec3 fa_pre_r0;\nlayout(location = 9) in vec3 fa_pre_r1;\nlayout(location = 10) in vec3 fa_pre_r2;\nlayout(location = 0) out vec4 fa_frag_color;\nlayout(location = 7) in float fa_pre_depth;\nfloat raise;\nvec4 tint;\n\nvoid fa_instance_unpack(vec4 fa_d0, vec4 fa_d1, vec4 fa_d2)\n{\n    raise = fa_d0.x;\n    tint = fa_d1;\n}\n\nvoid fa_inst_load()\n{\n    vec4 param = fa_inst_v0;\n    vec4 param_1 = fa_inst_v1;\n    vec4 param_2 = vec4(0.0);\n    fa_instance_unpack(param, param_1, param_2);\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nvec3 fa_linear_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_tex_fix(inout vec3 c, float mode)\n{\n    if (mode > 1.5)\n    {\n        vec3 param = c;\n        vec3 _212 = fa_linear_to_srgb(param);\n        c = _212;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            vec3 param_1 = c;\n            vec3 _221 = fa_srgb_to_linear(param_1);\n            c = _221;\n        }\n    }\n    return c;\n}\n\nvec3 fa_tangent_normal(SurfaceInput i, vec3 m)\n{\n    vec3 _63;\n    if (i.front_facing)\n    {\n        _63 = i.world_normal;\n    }\n    else\n    {\n        _63 = -i.world_normal;\n    }\n    vec3 _87 = normalize(i.world_tangent.xyz - (_63 * dot(_63, i.world_tangent.xyz)));\n    vec3 _115 = normalize(((_87 * m.x) + ((cross(_63, _87) * i.world_tangent.w) * m.y)) + (_63 * m.z));\n    vec3 _118;\n    if (i.front_facing)\n    {\n        _118 = _115;\n    }\n    else\n    {\n        _118 = -_115;\n    }\n    return _118;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    vec4 base_t = texture(fa_tex_fa_smp, i.uv);\n    float param = fa_mesh_fs_params[6].w;\n    float param_1 = 1.0;\n    vec3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    vec3 _266 = fa_tex_fix(param_2, param_3);\n    vec4 _815 = base_t;\n    _815.x = _266.x;\n    _815.y = _266.y;\n    _815.z = _266.z;\n    base_t = _815;\n    vec4 _282 = (_815 * fa_mesh_fs_params[2]) * i.vertex_color;\n    vec3 _770 = i.world_normal;\n    if (fa_mesh_fs_params[6].z > 0.5)\n    {\n        float param_4 = fa_mesh_fs_params[6].w;\n        float param_5 = 16.0;\n        vec3 param_6 = texture(fa_normal_tex_fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        vec3 _315 = fa_tex_fix(param_6, param_7);\n        vec3 _319 = (_315 * 2.0) - vec3(1.0);\n        vec2 _324 = _319.xy * fa_mesh_fs_params[6].x;\n        vec3 _823 = _319;\n        _823.x = _324.x;\n        _823.y = _324.y;\n        SurfaceInput param_8 = i;\n        vec3 param_9 = _823;\n        _770 = fa_tangent_normal(param_8, param_9);\n    }\n    vec4 mrt = texture(fa_mr_tex_fa_smp, i.uv);\n    float param_10 = fa_mesh_fs_params[6].w;\n    float param_11 = 64.0;\n    vec3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    vec3 _353 = fa_tex_fix(param_12, param_13);\n    vec4 _826 = mrt;\n    _826.x = _353.x;\n    _826.y = _353.y;\n    _826.z = _353.z;\n    mrt = _826;\n    vec4 _383 = texture(fa_occlusion_tex_fa_smp, i.uv);\n    float param_14 = fa_mesh_fs_params[6].w;\n    float param_15 = 256.0;\n    vec3 param_16 = _383.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    vec3 _395 = fa_tex_fix(param_16, param_17);\n    float param_18 = fa_mesh_fs_params[6].w;\n    float param_19 = 4.0;\n    vec3 param_20 = texture(fa_emissive_tex_fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    vec3 _425 = fa_tex_fix(param_20, param_21);\n    float _775 = fa_mesh_fs_params[20].x;\n    float _776 = fa_mesh_fs_params[20].y;\n    float _779 = fa_mesh_fs_params[20].z;\n    float _778 = fa_mesh_fs_params[21].w;\n    float _781 = fa_mesh_fs_params[22].x;\n    if (fa_mesh_fs_params[22].z > 0.5)\n    {\n        if (mod(fa_mesh_fs_params[22].z, 2.0) > 0.5)\n        {\n            _775 *= _395.y;\n            _776 *= _395.z;\n            _778 *= _383.w;\n        }\n        if (fa_mesh_fs_params[22].z > 1.5)\n        {\n            _779 *= mrt.x;\n            _781 *= mrt.w;\n        }\n    }\n    return Surface(_282.xyz, _282.w, _770, clamp(fa_mesh_fs_params[5].x * _353.z, 0.0, 1.0), clamp(fa_mesh_fs_params[5].y * _353.y, 0.0500000007450580596923828125, 1.0), 1.0 + (fa_mesh_fs_params[6].y * (_395.x - 1.0)), fa_mesh_fs_params[3].xyz + (fa_mesh_fs_params[4].xyz * _425), _775, _776, fa_mesh_fs_params[21].xyz, _778, _779, fa_mesh_fs_params[20].w, _781, fa_mesh_fs_params[22].y, fa_mesh_fs_params[23].xyz, fa_mesh_fs_params[30].x, fa_mesh_fs_params[30].y, fa_mesh_fs_params[31].xyz, fa_mesh_fs_params[30].z);\n}\n\nvoid surface(SurfaceInput i, inout Surface s)\n{\n    s.emission += ((tint.xyz * tint.w) * fa_material[0].x);\n}\n\nvoid main()\n{\n    fa_inst_load();\n    vec3 _665 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _665 = -_665;\n    }\n    vec3 _577 = normalize(fa_mesh_fs_params[0].xyz - fa_world_pos);\n    SurfaceInput param = SurfaceInput(fa_world_pos, _665, fa_world_tangent, fa_uv, fa_vertex_color, _577, gl_FrontFacing);\n    SurfaceInput param_1 = SurfaceInput(fa_world_pos, _665, fa_world_tangent, fa_uv, fa_vertex_color, _577, gl_FrontFacing);\n    Surface param_2 = fa_standard_surface(param);\n    surface(param_1, param_2);\n    vec3 _592 = normalize(param_2.normal);\n    vec3 _607 = normalize(vec3(dot(fa_pre_r0, _592), dot(fa_pre_r1, _592), dot(fa_pre_r2, _592)));\n    float _619 = _607.z;\n    vec2 e = _607.xy / vec2((abs(_607.x) + abs(_607.y)) + abs(_619));\n    if (_619 < 0.0)\n    {\n        e = (vec2(1.0) - abs(e.yx)) * vec2((e.x >= 0.0) ? 1.0 : (-1.0), (e.y >= 0.0) ? 1.0 : (-1.0));\n    }\n    fa_frag_color = vec4(min(fa_pre_depth, 60000.0), e, 1.0);\n}\n\n",
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
            "size": 832,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_255",
            "glsl_uniforms": [
              {
                "type": "vec4",
                "array_count": 52,
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
      "fs": "#version 430\n\nstruct SurfaceInput\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 vertex_color;\n    vec3 view_dir;\n    bool front_facing;\n};\n\nstruct Surface\n{\n    vec3 albedo;\n    float alpha;\n    vec3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    vec3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    vec3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    vec3 specular_color;\n    float transmission;\n    float thickness;\n    vec3 attenuation_color;\n    float attenuation_distance;\n};\n\nuniform vec4 fa_material[1];\nuniform vec4 fa_mesh_fs_params[52];\nlayout(binding = 0) uniform sampler2D fa_tex_fa_smp;\nlayout(binding = 1) uniform sampler2D fa_normal_tex_fa_smp;\nlayout(binding = 2) uniform sampler2D fa_mr_tex_fa_smp;\nlayout(binding = 3) uniform sampler2D fa_occlusion_tex_fa_smp;\nlayout(binding = 4) uniform sampler2D fa_emissive_tex_fa_smp;\n\nlayout(location = 0) flat in vec4 fa_inst_v0;\nlayout(location = 1) flat in vec4 fa_inst_v1;\nlayout(location = 2) in vec3 fa_world_pos;\nlayout(location = 3) in vec3 fa_world_normal;\nlayout(location = 4) in vec4 fa_world_tangent;\nlayout(location = 5) in vec2 fa_uv;\nlayout(location = 6) in vec4 fa_vertex_color;\nlayout(location = 8) in vec3 fa_pre_r0;\nlayout(location = 9) in vec3 fa_pre_r1;\nlayout(location = 10) in vec3 fa_pre_r2;\nlayout(location = 0) out vec4 fa_frag_color;\nlayout(location = 7) in float fa_pre_depth;\nfloat raise;\nvec4 tint;\n\nvoid fa_instance_unpack(vec4 fa_d0, vec4 fa_d1, vec4 fa_d2)\n{\n    raise = fa_d0.x;\n    tint = fa_d1;\n}\n\nvoid fa_inst_load()\n{\n    vec4 param = fa_inst_v0;\n    vec4 param_1 = fa_inst_v1;\n    vec4 param_2 = vec4(0.0);\n    fa_instance_unpack(param, param_1, param_2);\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nvec3 fa_linear_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_tex_fix(inout vec3 c, float mode)\n{\n    if (mode > 1.5)\n    {\n        vec3 param = c;\n        vec3 _212 = fa_linear_to_srgb(param);\n        c = _212;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            vec3 param_1 = c;\n            vec3 _221 = fa_srgb_to_linear(param_1);\n            c = _221;\n        }\n    }\n    return c;\n}\n\nvec3 fa_tangent_normal(SurfaceInput i, vec3 m)\n{\n    vec3 _63;\n    if (i.front_facing)\n    {\n        _63 = i.world_normal;\n    }\n    else\n    {\n        _63 = -i.world_normal;\n    }\n    vec3 _87 = normalize(i.world_tangent.xyz - (_63 * dot(_63, i.world_tangent.xyz)));\n    vec3 _115 = normalize(((_87 * m.x) + ((cross(_63, _87) * i.world_tangent.w) * m.y)) + (_63 * m.z));\n    vec3 _118;\n    if (i.front_facing)\n    {\n        _118 = _115;\n    }\n    else\n    {\n        _118 = -_115;\n    }\n    return _118;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    vec4 base_t = texture(fa_tex_fa_smp, i.uv);\n    float param = fa_mesh_fs_params[6].w;\n    float param_1 = 1.0;\n    vec3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    vec3 _266 = fa_tex_fix(param_2, param_3);\n    vec4 _815 = base_t;\n    _815.x = _266.x;\n    _815.y = _266.y;\n    _815.z = _266.z;\n    base_t = _815;\n    vec4 _282 = (_815 * fa_mesh_fs_params[2]) * i.vertex_color;\n    vec3 _770 = i.world_normal;\n    if (fa_mesh_fs_params[6].z > 0.5)\n    {\n        float param_4 = fa_mesh_fs_params[6].w;\n        float param_5 = 16.0;\n        vec3 param_6 = texture(fa_normal_tex_fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        vec3 _315 = fa_tex_fix(param_6, param_7);\n        vec3 _319 = (_315 * 2.0) - vec3(1.0);\n        vec2 _324 = _319.xy * fa_mesh_fs_params[6].x;\n        vec3 _823 = _319;\n        _823.x = _324.x;\n        _823.y = _324.y;\n        SurfaceInput param_8 = i;\n        vec3 param_9 = _823;\n        _770 = fa_tangent_normal(param_8, param_9);\n    }\n    vec4 mrt = texture(fa_mr_tex_fa_smp, i.uv);\n    float param_10 = fa_mesh_fs_params[6].w;\n    float param_11 = 64.0;\n    vec3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    vec3 _353 = fa_tex_fix(param_12, param_13);\n    vec4 _826 = mrt;\n    _826.x = _353.x;\n    _826.y = _353.y;\n    _826.z = _353.z;\n    mrt = _826;\n    vec4 _383 = texture(fa_occlusion_tex_fa_smp, i.uv);\n    float param_14 = fa_mesh_fs_params[6].w;\n    float param_15 = 256.0;\n    vec3 param_16 = _383.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    vec3 _395 = fa_tex_fix(param_16, param_17);\n    float param_18 = fa_mesh_fs_params[6].w;\n    float param_19 = 4.0;\n    vec3 param_20 = texture(fa_emissive_tex_fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    vec3 _425 = fa_tex_fix(param_20, param_21);\n    float _775 = fa_mesh_fs_params[20].x;\n    float _776 = fa_mesh_fs_params[20].y;\n    float _779 = fa_mesh_fs_params[20].z;\n    float _778 = fa_mesh_fs_params[21].w;\n    float _781 = fa_mesh_fs_params[22].x;\n    if (fa_mesh_fs_params[22].z > 0.5)\n    {\n        if (mod(fa_mesh_fs_params[22].z, 2.0) > 0.5)\n        {\n            _775 *= _395.y;\n            _776 *= _395.z;\n            _778 *= _383.w;\n        }\n        if (fa_mesh_fs_params[22].z > 1.5)\n        {\n            _779 *= mrt.x;\n            _781 *= mrt.w;\n        }\n    }\n    return Surface(_282.xyz, _282.w, _770, clamp(fa_mesh_fs_params[5].x * _353.z, 0.0, 1.0), clamp(fa_mesh_fs_params[5].y * _353.y, 0.0500000007450580596923828125, 1.0), 1.0 + (fa_mesh_fs_params[6].y * (_395.x - 1.0)), fa_mesh_fs_params[3].xyz + (fa_mesh_fs_params[4].xyz * _425), _775, _776, fa_mesh_fs_params[21].xyz, _778, _779, fa_mesh_fs_params[20].w, _781, fa_mesh_fs_params[22].y, fa_mesh_fs_params[23].xyz, fa_mesh_fs_params[30].x, fa_mesh_fs_params[30].y, fa_mesh_fs_params[31].xyz, fa_mesh_fs_params[30].z);\n}\n\nvoid surface(SurfaceInput i, inout Surface s)\n{\n    s.emission += ((tint.xyz * tint.w) * fa_material[0].x);\n}\n\nvoid main()\n{\n    fa_inst_load();\n    vec3 _665 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _665 = -_665;\n    }\n    vec3 _577 = normalize(fa_mesh_fs_params[0].xyz - fa_world_pos);\n    SurfaceInput param = SurfaceInput(fa_world_pos, _665, fa_world_tangent, fa_uv, fa_vertex_color, _577, gl_FrontFacing);\n    SurfaceInput param_1 = SurfaceInput(fa_world_pos, _665, fa_world_tangent, fa_uv, fa_vertex_color, _577, gl_FrontFacing);\n    Surface param_2 = fa_standard_surface(param);\n    surface(param_1, param_2);\n    vec3 _592 = normalize(param_2.normal);\n    vec3 _607 = normalize(vec3(dot(fa_pre_r0, _592), dot(fa_pre_r1, _592), dot(fa_pre_r2, _592)));\n    float _619 = _607.z;\n    vec2 e = _607.xy / vec2((abs(_607.x) + abs(_607.y)) + abs(_619));\n    if (_619 < 0.0)\n    {\n        e = (vec2(1.0) - abs(e.yx)) * vec2((e.x >= 0.0) ? 1.0 : (-1.0), (e.y >= 0.0) ? 1.0 : (-1.0));\n    }\n    fa_frag_color = vec4(min(fa_pre_depth, 60000.0), e, 1.0);\n}\n\n",
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
            "size": 832,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_255",
            "glsl_uniforms": [
              {
                "type": "vec4",
                "array_count": 52,
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
