{
  "format": "factoria.shader/1",
  "engine": "0.32.0",
  "template": "4a8331d4c52f4add9385ad09f3cee754aeec6a52a5c8c810972e182590f5426b",
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
      "fs": "#version 430\n\nstruct SurfaceInput\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 vertex_color;\n    vec3 view_dir;\n    bool front_facing;\n};\n\nstruct LightSample\n{\n    vec3 direction;\n    vec3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct Surface\n{\n    vec3 albedo;\n    float alpha;\n    vec3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    vec3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    vec3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    vec3 specular_color;\n    float transmission;\n    float thickness;\n    vec3 attenuation_color;\n    float attenuation_distance;\n};\n\nstruct FaLayers\n{\n    bool on;\n    float f90;\n    float keep;\n    float base_scale;\n    float coat;\n    float coat_rough;\n    float coat_alpha;\n    float coat_a2;\n    vec3 nc;\n    float coat_ndv;\n    bool sheen_on;\n    vec3 sheen;\n    float sheen_rough;\n    float sheen_alpha;\n    float sheen_scale;\n    float sheen_e;\n    float aniso;\n    vec3 t;\n    vec3 b;\n    float at;\n    float ab;\n};\n\nconst float _4343[63] = float[](1.0, 1.0, 1.0, 0.4790000021457672119140625, 0.11699999868869781494140625, 0.01200000010430812835693359375, 0.0, 0.0, 0.0, 1.0, 1.0, 1.0, 0.578000009059906005859375, 0.19300000369548797607421875, 0.0350000001490116119384765625, 0.0030000000260770320892333984375, 0.0, 0.0, 1.0, 1.0, 1.0, 0.6740000247955322265625, 0.3459999859333038330078125, 0.1319999992847442626953125, 0.032999999821186065673828125, 0.0040000001899898052215576171875, 0.0, 0.971000015735626220703125, 0.954999983310699462890625, 0.828999996185302734375, 0.63999998569488525390625, 0.42599999904632568359375, 0.24500000476837158203125, 0.115000002086162567138671875, 0.037000000476837158203125, 0.0030000000260770320892333984375, 0.7469999790191650390625, 0.737999975681304931640625, 0.670000016689300537109375, 0.563000023365020751953125, 0.4309999942779541015625, 0.3039999902248382568359375, 0.1940000057220458984375, 0.1019999980926513671875, 0.0309999994933605194091796875, 0.614000022411346435546875, 0.609000027179718017578125, 0.566999971866607666015625, 0.499000012874603271484375, 0.412000000476837158203125, 0.32400000095367431640625, 0.240999996662139892578125, 0.162000000476837158203125, 0.087999999523162841796875, 0.538999974727630615234375, 0.535000026226043701171875, 0.505999982357025146484375, 0.4569999873638153076171875, 0.393999993801116943359375, 0.328999996185302734375, 0.2660000026226043701171875, 0.203999996185302734375, 0.14200000464916229248046875);\n\nuniform vec4 fa_mesh_fs_params[53];\nuniform vec4 fa_shadows[30];\nuniform vec4 fa_material[1];\nlayout(binding = 0) uniform sampler2D fa_light_tex_fa_shadow_smp;\nlayout(binding = 1) uniform sampler2D fa_tex_fa_smp;\nlayout(binding = 2) uniform sampler2D fa_normal_tex_fa_smp;\nlayout(binding = 3) uniform sampler2D fa_mr_tex_fa_smp;\nlayout(binding = 4) uniform sampler2D fa_occlusion_tex_fa_smp;\nlayout(binding = 5) uniform sampler2D fa_emissive_tex_fa_smp;\nlayout(binding = 6) uniform sampler2D fa_decal_tex_fa_env_smp;\nlayout(binding = 7) uniform sampler2D fa_lightmap_fa_env_smp;\nlayout(binding = 8) uniform sampler2D fa_probe_atlas_fa_env_smp;\nlayout(binding = 9) uniform sampler2D fa_light_atlas_fa_env_smp;\nlayout(binding = 10) uniform sampler2D fa_shadow_tex_fa_shadow_smp;\nlayout(binding = 11) uniform sampler2D fa_screen_tex_fa_shadow_smp;\n\nlayout(location = 2) in vec3 fa_world_pos;\nlayout(location = 7) in vec3 fa_lm;\nlayout(location = 0) flat in vec4 fa_inst_v0;\nlayout(location = 1) flat in vec4 fa_inst_v1;\nlayout(location = 3) in vec3 fa_world_normal;\nlayout(location = 4) in vec4 fa_world_tangent;\nlayout(location = 5) in vec2 fa_uv;\nlayout(location = 6) in vec4 fa_vertex_color;\nlayout(location = 0) out vec4 fa_frag_color;\nvec3 fa_light_tint;\nbool fa_light_is_area;\nint fa_cl_ndir;\nint fa_cl_slot;\nint fa_cl_local;\nfloat raise;\nvec4 tint;\n\nvoid fa_instance_unpack(vec4 fa_d0, vec4 fa_d1, vec4 fa_d2)\n{\n    raise = fa_d0.x;\n    tint = fa_d1;\n}\n\nvoid fa_inst_load()\n{\n    vec4 param = fa_inst_v0;\n    vec4 param_1 = fa_inst_v1;\n    vec4 param_2 = vec4(0.0);\n    fa_instance_unpack(param, param_1, param_2);\n}\n\nvec4 fa_light_texel(int t)\n{\n    return texelFetch(fa_light_tex_fa_shadow_smp, ivec2(t & 1023, t >> 10), 0);\n}\n\nvec4 fa_cluster_texel(vec3 world_pos)\n{\n    bool _1598 = fa_mesh_fs_params[19].x < 0.0;\n    bool _1605;\n    if (!_1598)\n    {\n        _1605 = fa_mesh_fs_params[19].w < 1.0;\n    }\n    else\n    {\n        _1605 = _1598;\n    }\n    bool _1613;\n    if (!_1605)\n    {\n        _1613 = fa_mesh_fs_params[18].x < 1.0;\n    }\n    else\n    {\n        _1613 = _1605;\n    }\n    bool _1620;\n    if (!_1613)\n    {\n        _1620 = fa_mesh_fs_params[18].y < 1.0;\n    }\n    else\n    {\n        _1620 = _1613;\n    }\n    bool _1627;\n    if (!_1620)\n    {\n        _1627 = fa_mesh_fs_params[19].y < 1.0;\n    }\n    else\n    {\n        _1627 = _1620;\n    }\n    if (_1627)\n    {\n        return vec4(0.0);\n    }\n    vec4 _1637 = vec4(world_pos, 1.0);\n    float _1643 = dot(fa_mesh_fs_params[16], _1637);\n    if (!(_1643 > 9.9999999747524270787835121154785e-07))\n    {\n        return vec4(0.0);\n    }\n    vec2 _1665 = vec2(dot(fa_mesh_fs_params[14], _1637), dot(fa_mesh_fs_params[15], _1637)) / vec2(_1643);\n    int _1669 = int(fa_mesh_fs_params[18].x);\n    int _1673 = int(fa_mesh_fs_params[18].y);\n    int param = (int(fa_mesh_fs_params[19].x) + (((clamp(int(floor(log2(max(dot(fa_mesh_fs_params[17].xyz, world_pos) + fa_mesh_fs_params[17].w, fa_mesh_fs_params[18].w) / fa_mesh_fs_params[18].w) * fa_mesh_fs_params[18].z)), 0, int(fa_mesh_fs_params[19].y) - 1) * _1673) + clamp(int(floor(((_1665.y * 0.5) + 0.5) * fa_mesh_fs_params[18].y)), 0, _1673 - 1)) * _1669)) + clamp(int(floor(((_1665.x * 0.5) + 0.5) * fa_mesh_fs_params[18].x)), 0, _1669 - 1);\n    return fa_light_texel(param);\n}\n\nivec2 fa_cluster_lookup(vec3 world_pos)\n{\n    vec3 param = world_pos;\n    vec4 _1749 = fa_cluster_texel(param);\n    return ivec2(int(_1749.x), int(_1749.y));\n}\n\nvoid fa_cluster_begin(vec3 world_pos)\n{\n    fa_cl_ndir = int(fa_mesh_fs_params[19].z);\n    vec3 param = world_pos;\n    ivec2 _5804 = fa_cluster_lookup(param);\n    fa_cl_slot = _5804.x;\n    fa_cl_local = _5804.y;\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nvec3 fa_linear_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_tex_fix(inout vec3 c, float mode)\n{\n    if (mode > 1.5)\n    {\n        vec3 param = c;\n        vec3 _6967 = fa_linear_to_srgb(param);\n        c = _6967;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            vec3 param_1 = c;\n            vec3 _6975 = fa_srgb_to_linear(param_1);\n            c = _6975;\n        }\n    }\n    return c;\n}\n\nvec3 fa_tangent_normal(SurfaceInput i, vec3 m)\n{\n    vec3 _542;\n    if (i.front_facing)\n    {\n        _542 = i.world_normal;\n    }\n    else\n    {\n        _542 = -i.world_normal;\n    }\n    vec3 _566 = normalize(i.world_tangent.xyz - (_542 * dot(_542, i.world_tangent.xyz)));\n    vec3 _593 = normalize(((_566 * m.x) + ((cross(_542, _566) * i.world_tangent.w) * m.y)) + (_542 * m.z));\n    vec3 _596;\n    if (i.front_facing)\n    {\n        _596 = _593;\n    }\n    else\n    {\n        _596 = -_593;\n    }\n    return _596;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    vec4 base_t = texture(fa_tex_fa_smp, i.uv);\n    float param = fa_mesh_fs_params[6].w;\n    float param_1 = 1.0;\n    vec3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    vec3 _7006 = fa_tex_fix(param_2, param_3);\n    vec4 _9199 = base_t;\n    _9199.x = _7006.x;\n    _9199.y = _7006.y;\n    _9199.z = _7006.z;\n    base_t = _9199;\n    vec4 _7020 = (_9199 * fa_mesh_fs_params[2]) * i.vertex_color;\n    vec3 _8983 = i.world_normal;\n    if (fa_mesh_fs_params[6].z > 0.5)\n    {\n        float param_4 = fa_mesh_fs_params[6].w;\n        float param_5 = 16.0;\n        vec3 param_6 = texture(fa_normal_tex_fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        vec3 _7052 = fa_tex_fix(param_6, param_7);\n        vec3 _7055 = (_7052 * 2.0) - vec3(1.0);\n        vec2 _7060 = _7055.xy * fa_mesh_fs_params[6].x;\n        vec3 _9207 = _7055;\n        _9207.x = _7060.x;\n        _9207.y = _7060.y;\n        SurfaceInput param_8 = i;\n        vec3 param_9 = _9207;\n        _8983 = fa_tangent_normal(param_8, param_9);\n    }\n    vec4 mrt = texture(fa_mr_tex_fa_smp, i.uv);\n    float param_10 = fa_mesh_fs_params[6].w;\n    float param_11 = 64.0;\n    vec3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    vec3 _7088 = fa_tex_fix(param_12, param_13);\n    vec4 _9210 = mrt;\n    _9210.x = _7088.x;\n    _9210.y = _7088.y;\n    _9210.z = _7088.z;\n    mrt = _9210;\n    vec4 _7116 = texture(fa_occlusion_tex_fa_smp, i.uv);\n    float param_14 = fa_mesh_fs_params[6].w;\n    float param_15 = 256.0;\n    vec3 param_16 = _7116.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    vec3 _7127 = fa_tex_fix(param_16, param_17);\n    float param_18 = fa_mesh_fs_params[6].w;\n    float param_19 = 4.0;\n    vec3 param_20 = texture(fa_emissive_tex_fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    vec3 _7157 = fa_tex_fix(param_20, param_21);\n    float _8988 = fa_mesh_fs_params[20].x;\n    float _8989 = fa_mesh_fs_params[20].y;\n    float _8992 = fa_mesh_fs_params[20].z;\n    float _8991 = fa_mesh_fs_params[21].w;\n    float _8994 = fa_mesh_fs_params[22].x;\n    if (fa_mesh_fs_params[22].z > 0.5)\n    {\n        if (mod(fa_mesh_fs_params[22].z, 2.0) > 0.5)\n        {\n            _8988 *= _7127.y;\n            _8989 *= _7127.z;\n            _8991 *= _7116.w;\n        }\n        if (fa_mesh_fs_params[22].z > 1.5)\n        {\n            _8992 *= mrt.x;\n            _8994 *= mrt.w;\n        }\n    }\n    return Surface(_7020.xyz, _7020.w, _8983, clamp(fa_mesh_fs_params[5].x * _7088.z, 0.0, 1.0), clamp(fa_mesh_fs_params[5].y * _7088.y, 0.0500000007450580596923828125, 1.0), 1.0 + (fa_mesh_fs_params[6].y * (_7127.x - 1.0)), fa_mesh_fs_params[3].xyz + (fa_mesh_fs_params[4].xyz * _7157), _8988, _8989, fa_mesh_fs_params[21].xyz, _8991, _8992, fa_mesh_fs_params[20].w, _8994, fa_mesh_fs_params[22].y, fa_mesh_fs_params[23].xyz, fa_mesh_fs_params[30].x, fa_mesh_fs_params[30].y, fa_mesh_fs_params[31].xyz, fa_mesh_fs_params[30].z);\n}\n\nvoid surface(SurfaceInput i, inout Surface s)\n{\n    s.emission += ((tint.xyz * tint.w) * fa_material[0].x);\n}\n\nvec4 fa_decal_tile(vec4 rect, vec2 uv, vec2 atlas, vec2 ddx, vec2 ddy)\n{\n    vec2 _1829 = rect.zw - rect.xy;\n    vec2 _1833 = _1829 * atlas;\n    vec2 _1837 = ddx * _1833;\n    vec2 _1841 = ddy * _1833;\n    return textureLod(fa_decal_tex_fa_env_smp, rect.xy + (clamp(uv, vec2(0.0), vec2(1.0)) * _1829), clamp(0.5 * log2(max(max(dot(_1837, _1837), dot(_1841, _1841)), 9.9999999392252902907785028219223e-09)), 0.0, 4.0));\n}\n\nvec3 fa_dc_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_dc_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvoid fa_apply_decals(vec3 world_pos, vec3 geo_normal, inout vec3 albedo, inout vec3 normal)\n{\n    bool _1874 = fa_mesh_fs_params[10].y < 0.5;\n    bool _1881;\n    if (!_1874)\n    {\n        _1881 = fa_mesh_fs_params[10].w < 0.5;\n    }\n    else\n    {\n        _1881 = _1874;\n    }\n    if (_1881)\n    {\n        return;\n    }\n    vec3 _1887 = dFdx(world_pos);\n    vec3 _1890 = dFdy(world_pos);\n    vec3 param = world_pos;\n    vec4 _1894 = fa_cluster_texel(param);\n    int _1898 = int(_1894.w);\n    if (_1898 < 1)\n    {\n        return;\n    }\n    int _1908 = int(fa_mesh_fs_params[10].y + 0.5);\n    int param_1 = _1908;\n    vec4 _1912 = fa_light_texel(param_1);\n    vec2 _1915 = _1912.yz;\n    int _1919 = int(_1912.w);\n    int param_2 = _1908 + 1;\n    vec4 _1924 = fa_light_texel(param_2);\n    float _1925 = _1924.x;\n    int _1931 = int(fa_mesh_fs_params[10].w + 0.5) - 1;\n    int _1935 = int(_1894.z);\n    vec3 _2200;\n    for (int k = 0; k < _1898; k++)\n    {\n        int _1948 = _1935 + k;\n        int param_3 = _1919 + (_1948 >> 2);\n        int _1965 = (_1908 + 2) + (int(fa_light_texel(param_3)[_1948 & 3]) * 7);\n        int param_4 = _1965 + 6;\n        vec4 _1970 = fa_light_texel(param_4);\n        if (((int(_1970.w + 0.5) >> _1931) & 1) == 0)\n        {\n            continue;\n        }\n        int param_5 = _1965;\n        vec4 _1985 = fa_light_texel(param_5);\n        int param_6 = _1965 + 1;\n        vec4 _1990 = fa_light_texel(param_6);\n        int param_7 = _1965 + 2;\n        vec4 _1995 = fa_light_texel(param_7);\n        vec3 _1998 = _1985.xyz;\n        float _2003 = dot(_1998, world_pos) + _1985.w;\n        vec3 _2005 = _1990.xyz;\n        float _2010 = dot(_2005, world_pos) + _1990.w;\n        vec3 _2012 = _1995.xyz;\n        float _2017 = dot(_2012, world_pos) + _1995.w;\n        bool _2022 = abs(_2003) > 0.5;\n        bool _2030;\n        if (!_2022)\n        {\n            _2030 = abs(_2010) > 0.5;\n        }\n        else\n        {\n            _2030 = _2022;\n        }\n        bool _2038;\n        if (!_2030)\n        {\n            _2038 = abs(_2017) > 0.5;\n        }\n        else\n        {\n            _2038 = _2030;\n        }\n        if (_2038)\n        {\n            continue;\n        }\n        float _2053 = clamp(dot(geo_normal, normalize(_2012)) * _1970.z, 0.0, 1.0);\n        if (_2053 <= 0.0)\n        {\n            continue;\n        }\n        float _2073 = (clamp((0.5 - abs(_2017)) * 10.0, 0.0, 1.0) * _2053) * _1970.x;\n        vec2 _2081 = vec2(_2003 + 0.5, 0.5 - _2010);\n        vec2 _2091 = vec2(dot(_1998, _1887), dot(_2005, _1887));\n        vec2 _2101 = vec2(dot(_1998, _1890), dot(_2005, _1890));\n        int param_8 = _1965 + 5;\n        vec4 _2106 = fa_light_texel(param_8);\n        int param_9 = _1965 + 3;\n        vec4 _2111 = fa_light_texel(param_9);\n        int param_10 = _1965 + 4;\n        vec4 _2116 = fa_light_texel(param_10);\n        float tex_a = 1.0;\n        vec3 col = _2106.xyz;\n        bool _2126 = _2111.z > _2111.x;\n        if (_2126)\n        {\n            vec4 param_11 = _2111;\n            vec2 param_12 = _2081;\n            vec2 param_13 = _1915;\n            vec2 param_14 = _2091;\n            vec2 param_15 = _2101;\n            vec4 tx = fa_decal_tile(param_11, param_12, param_13, param_14, param_15);\n            if ((_1925 > 0.5) && (_1925 < 1.5))\n            {\n                vec3 param_16 = tx.xyz;\n                vec3 _2152 = fa_dc_to_linear(param_16);\n                vec4 _9071 = tx;\n                _9071.x = _2152.x;\n                _9071.y = _2152.y;\n                _9071.z = _2152.z;\n                tx = _9071;\n            }\n            col *= tx.xyz;\n            tex_a = tx.w;\n        }\n        albedo = mix(albedo, col, vec3(clamp((_2073 * tex_a) * _2106.w, 0.0, 1.0)));\n        if (_2116.z > _2116.x)\n        {\n            vec4 param_17 = _2116;\n            vec2 param_18 = _2081;\n            vec2 param_19 = _1915;\n            vec2 param_20 = _2091;\n            vec2 param_21 = _2101;\n            vec4 _2196 = fa_decal_tile(param_17, param_18, param_19, param_20, param_21);\n            if (_1925 > 1.5)\n            {\n                vec3 param_22 = _2196.xyz;\n                vec3 _2206 = fa_dc_to_srgb(param_22);\n                _2200 = _2206;\n            }\n            else\n            {\n                _2200 = _2196.xyz;\n            }\n            vec3 _2215 = (_2200 * 2.0) - vec3(1.0);\n            vec2 _2220 = _2215.xy * _1970.y;\n            vec3 _2242 = (normalize(_1998) * _2220.x) + (normalize(_2005) * _2220.y);\n            vec3 _2245 = normalize(normal);\n            normal = normalize(mix(_2245, normalize((_2245 * max(_2215.z, 0.0500000007450580596923828125)) + (_2242 - (_2245 * dot(_2245, _2242)))), vec3(clamp(_2073 * (_2126 ? tex_a : 1.0), 0.0, 1.0))));\n        }\n    }\n}\n\nfloat fa_sheen_albedo(float ndv, float rough)\n{\n    float _4269 = min(sqrt(max(rough - 0.100000001490116119384765625, 0.0) * 1.111111164093017578125) * 6.0, 5.999000072479248046875);\n    float _4276 = min(sqrt(clamp(ndv, 0.0, 1.0)) * 8.0, 7.999000072479248046875);\n    int _4279 = int(_4269);\n    int _4282 = int(_4276);\n    float _4292 = _4276 - float(_4282);\n    int _4347 = (_4279 * 9) + _4282;\n    int _4367 = ((_4279 + 1) * 9) + _4282;\n    return mix(mix(_4343[_4347], _4343[_4347 + 1], _4292), mix(_4343[_4367], _4343[_4367 + 1], _4292), _4269 - float(_4279));\n}\n\nFaLayers fa_layers_setup(SurfaceInput i, Surface s, vec3 n, vec3 v, float metallic, float roughness, inout vec3 f0)\n{\n    bool _8906 = false;\n    float _8907 = 1.0;\n    float _8908 = 1.0;\n    float _8909 = 1.0;\n    float _8910 = 0.0;\n    float _8911 = 0.0;\n    float _8912 = 0.0;\n    float _8913 = 0.0;\n    float _8915 = 1.0;\n    bool _8916 = false;\n    vec3 _8917 = vec3(0.0);\n    float _8918 = 1.0;\n    float _8919 = 1.0;\n    float _8920 = 1.0;\n    float _8921 = 0.0;\n    float _8922 = 0.0;\n    vec3 _8923 = vec3(1.0, 0.0, 0.0);\n    vec3 _8924 = vec3(0.0, 0.0, 1.0);\n    float _8925 = 1.0;\n    float _8926 = 1.0;\n    float _4418 = clamp(s.specular, 0.0, 1.0);\n    float _4422 = clamp(s.ior, 1.0, 3.0);\n    bool _4427 = (_4418 != 1.0) || (_4422 != 1.5);\n    bool _4436;\n    if (!_4427)\n    {\n        _4436 = any(notEqual(s.specular_color, vec3(1.0)));\n    }\n    else\n    {\n        _4436 = _4427;\n    }\n    if (_4436)\n    {\n        float _4444 = (_4422 - 1.0) / (_4422 + 1.0);\n        f0 = mix(min(vec3(_4444 * _4444) * max(s.specular_color, vec3(0.0)), vec3(1.0)) * _4418, s.albedo, vec3(metallic));\n        _8907 = mix(_4418, 1.0, metallic);\n        _8906 = true;\n    }\n    float _4471 = clamp(s.clearcoat, 0.0, 1.0);\n    if (_4471 > 0.0)\n    {\n        float _4479 = clamp(s.clearcoat_roughness, 0.0500000007450580596923828125, 1.0);\n        _8910 = _4471;\n        _8911 = _4479;\n        float _4486 = _4479 * _4479;\n        _8912 = _4486;\n        _8913 = _4486 * _4486;\n        float _4498 = max(dot(i.world_normal, v), 9.9999997473787516355514526367188e-05);\n        _8915 = _4498;\n        _8908 = 1.0 - (_4471 * (0.039999999105930328369140625 + (0.959999978542327880859375 * pow(clamp(1.0 - _4498, 0.0, 1.0), 5.0))));\n        _8906 = true;\n    }\n    vec3 _4517 = max(s.sheen_color, vec3(0.0));\n    float _4526 = max(_4517.x, max(_4517.y, _4517.z));\n    if (_4526 > 0.0)\n    {\n        float _4534 = clamp(s.sheen_roughness, 0.100000001490116119384765625, 1.0);\n        _8916 = true;\n        _8917 = _4517;\n        _8918 = _4534;\n        _8919 = _4534 * _4534;\n        float param = max(dot(n, v), 9.9999997473787516355514526367188e-05);\n        float param_1 = _4534;\n        float _4551 = fa_sheen_albedo(param, param_1);\n        _8921 = _4551;\n        _8920 = 1.0 - min(_4526 * _4551, 1.0);\n        _8906 = true;\n    }\n    _8909 = _8908 * _8920;\n    float _4570 = clamp(s.anisotropy, -1.0, 1.0);\n    if (_4570 != 0.0)\n    {\n        vec3 _4585 = i.world_tangent.xyz - (n * dot(n, i.world_tangent.xyz));\n        vec3 t = _4585;\n        if (dot(_4585, _4585) < 9.9999999392252902907785028219223e-09)\n        {\n            bvec3 _4597 = bvec3(abs(n.y) < 0.9900000095367431640625);\n            t = cross(vec3(_4597.x ? vec3(0.0, 1.0, 0.0).x : vec3(1.0, 0.0, 0.0).x, _4597.y ? vec3(0.0, 1.0, 0.0).y : vec3(1.0, 0.0, 0.0).y, _4597.z ? vec3(0.0, 1.0, 0.0).z : vec3(1.0, 0.0, 0.0).z), n);\n        }\n        vec3 _4601 = t;\n        vec3 _4602 = normalize(_4601);\n        t = _4602;\n        vec3 _4627 = normalize((_4602 * cos(s.anisotropy_rotation)) + ((cross(n, _4602) * ((i.world_tangent.w < 0.0) ? (-1.0) : 1.0)) * sin(s.anisotropy_rotation)));\n        _8923 = _4627;\n        _8924 = cross(n, _4627);\n        float _4637 = roughness * roughness;\n        float _4643 = mix(_4637, 1.0, _4570 * _4570);\n        bool _4645 = _4570 > 0.0;\n        _8925 = _4645 ? _4643 : _4637;\n        _8926 = _4645 ? _4637 : _4643;\n        _8922 = _4570;\n        _8906 = true;\n    }\n    return FaLayers(_8906, _8907, _8908, _8909, _8910, _8911, _8912, _8913, i.world_normal, _8915, _8916, _8917, _8918, _8919, _8920, _8921, _8922, _8923, _8924, _8925, _8926);\n}\n\nvec3 fa_sh_eval(vec3 c[9], vec3 n)\n{\n    vec3 _3440 = max((((c[0] * 0.2820948064327239990234375) + (((c[1] * (0.3257350027561187744140625 * n.y)) + (c[2] * (0.3257350027561187744140625 * n.z))) + (c[3] * (0.3257350027561187744140625 * n.x)))) + (((c[4] * ((0.2731371223926544189453125 * n.x) * n.y)) + (c[5] * ((0.2731371223926544189453125 * n.y) * n.z))) + (c[6] * (0.078847892582416534423828125 * (((3.0 * n.z) * n.z) - 1.0))))) + ((c[7] * ((0.2731371223926544189453125 * n.x) * n.z)) + (c[8] * (0.13656856119632720947265625 * ((n.x * n.x) - (n.y * n.y))))), vec3(0.0));\n    return _3440;\n}\n\nvec2 fa_atlas_size()\n{\n    return vec2(textureSize(fa_probe_atlas_fa_env_smp, 0));\n}\n\nvec4 fa_gi_fetch(vec2 texel)\n{\n    return textureLod(fa_probe_atlas_fa_env_smp, texel / fa_atlas_size(), 0.0);\n}\n\nvec2 fa_oct_encode(vec3 d)\n{\n    vec3 _3460 = d / vec3(max((abs(d.x) + abs(d.y)) + abs(d.z), 9.9999999600419720025001879548654e-13));\n    float _3463 = _3460.x;\n    float _3465 = _3460.z;\n    vec2 e = vec2(_3463, _3465);\n    if (_3460.y < 0.0)\n    {\n        e = vec2((1.0 - abs(_3465)) * ((_3463 < 0.0) ? (-1.0) : 1.0), (1.0 - abs(_3463)) * ((_3465 < 0.0) ? (-1.0) : 1.0));\n    }\n    return e;\n}\n\nvec3 fa_gi_grid(int rec, vec3 n, vec3 v, out float cover)\n{\n    cover = 0.0;\n    int param = rec;\n    vec4 _7267 = fa_light_texel(param);\n    int param_1 = rec + 1;\n    vec4 _7272 = fa_light_texel(param_1);\n    int param_2 = rec + 2;\n    vec4 _7277 = fa_light_texel(param_2);\n    int param_3 = rec + 3;\n    vec4 _7282 = fa_light_texel(param_3);\n    bool _7285 = _7282.z < 0.5;\n    bool _7293;\n    if (!_7285)\n    {\n        _7293 = fa_atlas_size().y < 1155.0;\n    }\n    else\n    {\n        _7293 = _7285;\n    }\n    if (_7293)\n    {\n        return vec3(0.0);\n    }\n    float _7300 = max(_7267.w, 9.9999997473787516355514526367188e-05);\n    vec3 _7303 = _7272.xyz;\n    vec3 _7307 = _7267.xyz;\n    vec3 _7311 = (fa_world_pos - _7307) / vec3(_7300);\n    vec3 _7320 = min(_7311 + vec3(0.5), (_7303 - vec3(0.5)) - _7311);\n    float _7329 = min(_7320.x, min(_7320.y, _7320.z));\n    if (!(_7329 > 0.0))\n    {\n        return vec3(0.0);\n    }\n    vec3 _7344 = _7303 - vec3(1.0);\n    vec3 _7345 = clamp(_7311, vec3(0.0), _7344);\n    vec3 _7353 = min(floor(_7345), max(_7303 - vec3(2.0), vec3(0.0)));\n    vec3 _7357 = _7345 - _7353;\n    vec3 _7368 = fa_world_pos + (((n * 0.800000011920928955078125) + (v * 0.20000000298023223876953125)) * (0.20000000298023223876953125 * _7300));\n    int _7373 = int(_7277.y + 0.5);\n    vec3 sh[9];\n    for (int k = 0; k < 9; k++)\n    {\n        sh[k] = vec3(0.0);\n    }\n    float wsum = 0.0;\n    int _7391 = int(_7282.w);\n    int _7392 = 8 + _7391;\n    int _7397 = 9 + _7391;\n    float _7424;\n    float _7437;\n    float _7451;\n    for (int k_1 = 0; k_1 < _7392; k_1++)\n    {\n        float _7410 = float(k_1 & 1);\n        float _7414 = float((k_1 >> 1) & 1);\n        float _7418 = float((k_1 >> 2) & 1);\n        if (_7410 > 0.5)\n        {\n            _7424 = _7357.x;\n        }\n        else\n        {\n            _7424 = 1.0 - _7357.x;\n        }\n        if (_7414 > 0.5)\n        {\n            _7437 = _7357.y;\n        }\n        else\n        {\n            _7437 = 1.0 - _7357.y;\n        }\n        if (_7418 > 0.5)\n        {\n            _7451 = _7357.z;\n        }\n        else\n        {\n            _7451 = 1.0 - _7357.z;\n        }\n        float _7461 = (_7424 * _7437) * _7451;\n        if (!(_7461 > 0.0))\n        {\n            continue;\n        }\n        vec3 _7474 = min(_7353 + vec3(_7410, _7414, _7418), _7344);\n        int _7494 = int(((_7277.x + _7474.x) + (_7272.x * (_7474.y + (_7272.y * _7474.z)))) + 0.5);\n        vec2 _7509 = vec2(float(_7494 % _7373) * 10.0, 1024.0 + (float(_7494 / _7373) * 11.0));\n        vec2 param_4 = _7509 + vec2(9.5, 10.5);\n        vec4 _7517 = fa_gi_fetch(param_4);\n        bool _7520 = _7517.y < 0.5;\n        bool _7529;\n        if (!_7520)\n        {\n            _7529 = _7517.x > _7282.y;\n        }\n        else\n        {\n            _7529 = _7520;\n        }\n        if (_7529)\n        {\n            continue;\n        }\n        vec3 _7541 = _7368 - (_7307 + (_7474 * _7300));\n        float _7544 = length(_7541);\n        vec3 _7550 = _7541 / vec3(max(_7544, 9.9999997473787516355514526367188e-05));\n        float _7560 = max(9.9999997473787516355514526367188e-05, (dot(-_7550, n) + 1.0) * 0.5);\n        float w = _7461 * (_7560 * _7560);\n        vec3 param_5 = _7550;\n        vec2 param_6 = (_7509 + vec2(1.0)) + (((fa_oct_encode(param_5) * 0.5) + vec2(0.5)) * 8.0);\n        vec4 _7579 = fa_gi_fetch(param_6);\n        float _7586 = _7544 / max(_7277.z, 9.9999997473787516355514526367188e-05);\n        float _7589 = _7579.x;\n        if (_7586 > _7589)\n        {\n            float _7602 = max(_7579.y - (_7589 * _7589), 0.0);\n            float _7607 = _7586 - _7589;\n            float _7616 = _7602 / max(_7602 + (_7607 * _7607), 9.9999999600419720025001879548654e-13);\n            w *= ((_7616 * _7616) * _7616);\n        }\n        if (!(w > 0.0))\n        {\n            continue;\n        }\n        for (int c = 0; c < _7397; c++)\n        {\n            vec2 param_7 = _7509 + vec2(float(c) + 0.5, 10.5);\n            sh[c] += (fa_gi_fetch(param_7).xyz * w);\n        }\n        wsum += w;\n    }\n    if (!(wsum > 9.9999997473787516355514526367188e-06))\n    {\n        return vec3(0.0);\n    }\n    for (int c_1 = 0; c_1 < 9; c_1++)\n    {\n        sh[c_1] /= vec3(wsum);\n    }\n    cover = smoothstep(0.0, 1.0, clamp(_7329 * 2.0, 0.0, 1.0)) * smoothstep(0.0, 0.0199999995529651641845703125, wsum);\n    float _7697;\n    if (fa_mesh_fs_params[52].z > 0.5)\n    {\n        _7697 = _7282.x;\n    }\n    else\n    {\n        _7697 = 1.0;\n    }\n    vec3 param_8[9] = sh;\n    vec3 param_9 = n;\n    return fa_sh_eval(param_8, param_9) * (_7277.w * _7697);\n}\n\nvec3 fa_gi_light(vec3 n, inout float left)\n{\n    left = 1.0;\n    vec3 acc = vec3(0.0);\n    vec3 _7721 = normalize(fa_mesh_fs_params[0].xyz - fa_world_pos);\n    int _7726 = int(fa_mesh_fs_params[52].x + 0.5);\n    int _7731 = int(fa_mesh_fs_params[52].y + 0.5);\n    float param_3;\n    for (int k = 0; (k < _7731) && (k < 8); k++)\n    {\n        int param = _7726 + (4 * k);\n        vec3 param_1 = n;\n        vec3 param_2 = _7721;\n        vec3 _7756 = fa_gi_grid(param, param_1, param_2, param_3);\n        float _7761 = param_3 * left;\n        acc += (_7756 * _7761);\n        left -= _7761;\n        if (left < 0.001000000047497451305389404296875)\n        {\n            left = 0.0;\n            break;\n        }\n    }\n    return acc;\n}\n\nvec3 fa_probe_sh_coef(vec2 origin, float res, int k)\n{\n    vec3 v = textureLod(fa_probe_atlas_fa_env_smp, (origin + vec2(float(k) + 0.5, res + 2.5)) / fa_atlas_size(), 0.0).xyz;\n    if (fa_mesh_fs_params[41].y > 0.5)\n    {\n        v = (v - vec3(0.5)) * 8.0;\n    }\n    return v;\n}\n\nvec3 fa_ambient_light(vec3 n)\n{\n    float _4050 = (1.0 - fa_mesh_fs_params[42].w) - fa_mesh_fs_params[47].w;\n    vec3 amb = vec3(0.0);\n    bool _4055 = fa_mesh_fs_params[11].w > 0.5;\n    vec3 c[9];\n    for (int k = 0; k < 9; k++)\n    {\n        c[k] = vec3(0.0);\n    }\n    if (_4050 > 0.0005000000237487256526947021484375)\n    {\n        if (_4055)\n        {\n            for (int k_1 = 0; k_1 < 9; k_1++)\n            {\n                vec2 param = fa_mesh_fs_params[41].zw;\n                float param_1 = 128.0;\n                int param_2 = k_1;\n                c[k_1] = fa_probe_sh_coef(param, param_1, param_2) * _4050;\n            }\n        }\n        else\n        {\n            amb = fa_mesh_fs_params[1].xyz * _4050;\n        }\n    }\n    bool _4106 = fa_mesh_fs_params[42].w > 0.0;\n    if (_4106)\n    {\n        for (int k_2 = 0; k_2 < 9; k_2++)\n        {\n            vec2 param_3 = fa_mesh_fs_params[42].xy;\n            float param_4 = fa_mesh_fs_params[42].z;\n            int param_5 = k_2;\n            c[k_2] += (fa_probe_sh_coef(param_3, param_4, param_5) * fa_mesh_fs_params[42].w);\n        }\n    }\n    bool _4137 = fa_mesh_fs_params[47].w > 0.0;\n    if (_4137)\n    {\n        for (int k_3 = 0; k_3 < 9; k_3++)\n        {\n            vec2 param_6 = fa_mesh_fs_params[47].xy;\n            float param_7 = fa_mesh_fs_params[47].z;\n            int param_8 = k_3;\n            c[k_3] += (fa_probe_sh_coef(param_6, param_7, param_8) * fa_mesh_fs_params[47].w);\n        }\n    }\n    if ((_4055 || _4106) || _4137)\n    {\n        vec3 param_9[9] = c;\n        vec3 param_10 = n;\n        amb += fa_sh_eval(param_9, param_10);\n    }\n    return amb;\n}\n\nvec3 fa_realtime_or_ambient(vec3 n)\n{\n    if (fa_mesh_fs_params[52].y > 0.5)\n    {\n        vec3 param = n;\n        float param_1;\n        vec3 _7790 = fa_gi_light(param, param_1);\n        if (param_1 < 0.999000012874603271484375)\n        {\n            vec3 _7798;\n            if (param_1 > 0.0)\n            {\n                vec3 param_2 = n;\n                _7798 = _7790 + (fa_ambient_light(param_2) * param_1);\n            }\n            else\n            {\n                _7798 = _7790;\n            }\n            return _7798;\n        }\n    }\n    vec3 param_3 = n;\n    return fa_ambient_light(param_3);\n}\n\nvec3 fa_indirect_diffuse(vec3 n)\n{\n    if (fa_lm.z > 0.5)\n    {\n        return textureLod(fa_lightmap_fa_env_smp, fa_lm.xy, 0.0).xyz;\n    }\n    if (fa_mesh_fs_params[32].w > 0.0)\n    {\n        vec3 c[9];\n        for (int k = 0; k < 9; k++)\n        {\n            c[k] = fa_mesh_fs_params[k * 1 + 32].xyz;\n        }\n        vec3 param[9] = c;\n        vec3 param_1 = n;\n        vec3 _7860 = fa_sh_eval(param, param_1);\n        if (fa_mesh_fs_params[32].w >= 1.0)\n        {\n            return _7860;\n        }\n        vec3 param_2 = n;\n        return mix(fa_realtime_or_ambient(param_2), _7860, vec3(clamp(fa_mesh_fs_params[32].w, 0.0, 1.0)));\n    }\n    vec3 param_3 = n;\n    return fa_realtime_or_ambient(param_3);\n}\n\nint fa_cluster_index(int slot, int n)\n{\n    int param = (int(fa_mesh_fs_params[19].x) + int(fa_mesh_fs_params[19].w)) + ((slot + n) >> 2);\n    vec4 t = fa_light_texel(param);\n    return int(t[(slot + n) & 3]);\n}\n\nint fa_cl_light(int n)\n{\n    if (n < fa_cl_ndir)\n    {\n        return n;\n    }\n    int param = fa_cl_slot;\n    int param_1 = n - fa_cl_ndir;\n    return fa_cluster_index(param, param_1);\n}\n\nint fa_light_base(int li)\n{\n    return li * ((fa_mesh_fs_params[1].w > 4.5) ? 8 : 4);\n}\n\nbool fa_light_baked(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 3;\n    return fa_light_texel(param_1).w > 0.5;\n}\n\nfloat fa_baked_keep(int li)\n{\n    float _5774;\n    if (fa_lm.z > 0.5)\n    {\n        _5774 = 0.0;\n    }\n    else\n    {\n        _5774 = 1.0 - clamp(fa_mesh_fs_params[32].w, 0.0, 1.0);\n    }\n    bool _5785 = _5774 < 1.0;\n    bool _5791;\n    if (_5785)\n    {\n        int param = li;\n        _5791 = fa_light_baked(param);\n    }\n    else\n    {\n        _5791 = _5785;\n    }\n    return _5791 ? _5774 : 1.0;\n}\n\nfloat fa_light_type(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 1;\n    return fa_light_texel(param_1).w;\n}\n\nvec4 fa_atlas_fetch(vec2 texel)\n{\n    return textureLod(fa_light_atlas_fa_env_smp, texel / vec2(textureSize(fa_light_atlas_fa_env_smp, 0)), 0.0);\n}\n\nvec3 fa_cookie_sample(vec2 tile_origin, vec2 uv)\n{\n    vec2 param = (tile_origin + vec2(1.0)) + (clamp(uv, vec2(0.0), vec2(1.0)) * 254.0);\n    return fa_atlas_fetch(param).xyz;\n}\n\nvec3 fa_area_point(vec3 c, vec3 axis, vec3 ru, vec3 uu, float hx, float hy, float shape, vec3 p, vec3 r)\n{\n    bool _847 = dot(r, r) > 0.5;\n    if (shape > 1.5)\n    {\n        vec3 _860 = (c - (ru * hx)) - p;\n        vec3 _866 = ru * (2.0 * hx);\n        float _872 = max(dot(_866, _866), 9.9999999392252902907785028219223e-09);\n        float _876 = dot(_860, _866);\n        float t = clamp((-_876) / _872, 0.0, 1.0);\n        if (_847)\n        {\n            float _891 = dot(r, _866);\n            float _897 = _872 - (_891 * _891);\n            if (abs(_897) > (9.9999997473787516355514526367188e-06 * _872))\n            {\n                t = clamp(((dot(r, _860) * _891) - _876) / _897, 0.0, 1.0);\n            }\n        }\n        return (p + _860) + (_866 * t);\n    }\n    vec3 q = p;\n    float _929 = dot(r, axis);\n    bool _937;\n    if (_847)\n    {\n        _937 = abs(_929) > 9.9999997473787516355514526367188e-05;\n    }\n    else\n    {\n        _937 = _847;\n    }\n    if (_937)\n    {\n        float _947 = dot(c - p, axis) / _929;\n        if (_947 > 0.0)\n        {\n            q = p + (r * _947);\n        }\n    }\n    vec3 _960 = q - c;\n    vec2 xy = vec2(dot(_960, ru), dot(_960, uu));\n    if (shape > 0.5)\n    {\n        float _975 = length(xy);\n        if (_975 > hx)\n        {\n            xy *= (hx / _975);\n        }\n    }\n    else\n    {\n        xy = clamp(xy, vec2(-hx, -hy), vec2(hx, hy));\n    }\n    return (c + (ru * xy.x)) + (uu * xy.y);\n}\n\nint fa_cube_face(vec3 d)\n{\n    vec3 _608 = abs(d);\n    float _610 = _608.x;\n    float _612 = _608.y;\n    bool _613 = _610 >= _612;\n    bool _621;\n    if (_613)\n    {\n        _621 = _610 >= _608.z;\n    }\n    else\n    {\n        _621 = _613;\n    }\n    int _622;\n    if (_621)\n    {\n        _622 = (d.x > 0.0) ? 0 : 1;\n    }\n    else\n    {\n        int _637;\n        if (_612 >= _608.z)\n        {\n            _637 = (d.y > 0.0) ? 2 : 3;\n        }\n        else\n        {\n            _637 = (d.z > 0.0) ? 4 : 5;\n        }\n        _622 = _637;\n    }\n    return _622;\n}\n\nvoid fa_cube_face_basis(int f, out vec3 fwd, out vec3 up)\n{\n    if (f == 0)\n    {\n        fwd = vec3(1.0, 0.0, 0.0);\n        up = vec3(0.0, 1.0, 0.0);\n    }\n    else\n    {\n        if (f == 1)\n        {\n            fwd = vec3(-1.0, 0.0, 0.0);\n            up = vec3(0.0, 1.0, 0.0);\n        }\n        else\n        {\n            if (f == 2)\n            {\n                fwd = vec3(0.0, 1.0, 0.0);\n                up = vec3(0.0, 0.0, 1.0);\n            }\n            else\n            {\n                if (f == 3)\n                {\n                    fwd = vec3(0.0, -1.0, 0.0);\n                    up = vec3(0.0, 0.0, -1.0);\n                }\n                else\n                {\n                    if (f == 4)\n                    {\n                        fwd = vec3(0.0, 0.0, 1.0);\n                        up = vec3(0.0, 1.0, 0.0);\n                    }\n                    else\n                    {\n                        fwd = vec3(0.0, 0.0, -1.0);\n                        up = vec3(0.0, 1.0, 0.0);\n                    }\n                }\n            }\n        }\n    }\n}\n\nfloat fa_ies_sample(vec2 tile_origin, vec3 d, vec3 axis, vec3 right, vec3 up)\n{\n    float _767 = dot(d, right);\n    float _771 = dot(d, up);\n    float _782;\n    if (((_767 * _767) + (_771 * _771)) > 1.0000000133514319600180897396058e-10)\n    {\n        _782 = atan(_771, _767) * 0.15915493667125701904296875;\n    }\n    else\n    {\n        _782 = 0.0;\n    }\n    vec2 param = tile_origin + vec2(1.0 + ((_782 - floor(_782)) * 64.0), 1.0 + (acos(clamp(dot(d, axis), -1.0, 1.0)) * 10.18591594696044921875));\n    return fa_atlas_fetch(param).x;\n}\n\nLightSample fa_light_sample_n(int li, vec3 world_pos, vec3 n)\n{\n    int param = li;\n    int _1013 = fa_light_base(param);\n    bool _1017 = fa_mesh_fs_params[1].w > 4.5;\n    int param_1 = _1013;\n    vec4 _1021 = fa_light_texel(param_1);\n    int param_2 = _1013 + 1;\n    vec4 _1026 = fa_light_texel(param_2);\n    float _1029 = _1026.w;\n    float atten = 1.0;\n    float dist = 0.0;\n    fa_light_tint = vec3(1.0);\n    bool _1041 = _1017 && (_1029 > 2.5);\n    fa_light_is_area = _1041;\n    bool _1043 = _1029 < 0.5;\n    vec3 l;\n    if (_1043)\n    {\n        l = normalize(_1021.xyz);\n        if (_1017)\n        {\n            int param_3 = _1013 + 6;\n            vec4 _1057 = fa_light_texel(param_3);\n            if (_1057.z > 0.5)\n            {\n                int param_4 = _1013 + 4;\n                vec4 _1067 = fa_light_texel(param_4);\n                int param_5 = _1013 + 5;\n                vec4 _1072 = fa_light_texel(param_5);\n                vec2 param_6 = _1057.xy;\n                vec2 param_7 = fract(vec2(dot(world_pos, _1067.xyz) * _1067.w, (-dot(world_pos, _1072.xyz)) * _1072.w) + vec2(0.5));\n                fa_light_tint = fa_cookie_sample(param_6, param_7);\n            }\n        }\n    }\n    else\n    {\n        vec3 _1102 = _1021.xyz;\n        vec3 _1104 = _1102 - world_pos;\n        vec3 to_light = _1104;\n        float _1107 = length(_1104);\n        float reach = _1107;\n        bool front = true;\n        if (_1041)\n        {\n            int param_8 = _1013 + 7;\n            reach = max(_1107 - fa_light_texel(param_8).w, 0.0);\n            int param_9 = _1013 + 4;\n            vec4 _1131 = fa_light_texel(param_9);\n            int param_10 = _1013 + 5;\n            vec4 _1136 = fa_light_texel(param_10);\n            int param_11 = _1013 + 6;\n            vec4 _1141 = fa_light_texel(param_11);\n            float _1142 = _1141.w;\n            int param_12 = _1013 + 2;\n            vec3 _1149 = normalize(fa_light_texel(param_12).xyz);\n            bool _1151 = _1142 > 1.5;\n            bool _1159;\n            if (!_1151)\n            {\n                _1159 = dot(_1149, to_light) < 0.0;\n            }\n            else\n            {\n                _1159 = _1151;\n            }\n            front = _1159;\n            vec3 r = vec3(0.0);\n            vec3 _1168 = fa_mesh_fs_params[0].xyz - world_pos;\n            bool _1172 = dot(n, n) > 0.5;\n            bool _1180;\n            if (_1172)\n            {\n                _1180 = dot(_1168, _1168) > 9.9999999600419720025001879548654e-13;\n            }\n            else\n            {\n                _1180 = _1172;\n            }\n            if (_1180)\n            {\n                r = reflect(-normalize(_1168), normalize(n));\n            }\n            vec3 param_13 = _1102;\n            vec3 param_14 = _1149;\n            vec3 param_15 = _1131.xyz;\n            vec3 param_16 = _1136.xyz;\n            float param_17 = _1131.w;\n            float param_18 = _1136.w;\n            float param_19 = _1142;\n            vec3 param_20 = world_pos;\n            vec3 param_21 = r;\n            to_light = fa_area_point(param_13, param_14, param_15, param_16, param_17, param_18, param_19, param_20, param_21) - world_pos;\n        }\n        float _1216 = length(to_light);\n        dist = _1216;\n        l = to_light / vec3(max(_1216, 9.9999997473787516355514526367188e-05));\n        float _1230 = reach / max(_1021.w, 0.001000000047497451305389404296875);\n        float _1236 = clamp(1.0 - (_1230 * _1230), 0.0, 1.0);\n        float _1238;\n        if (front)\n        {\n            _1238 = _1236 * _1236;\n        }\n        else\n        {\n            _1238 = 0.0;\n        }\n        atten = _1238;\n        bool _1249 = _1029 < 2.5;\n        if ((_1029 > 1.5) && _1249)\n        {\n            int param_22 = _1013 + 2;\n            vec4 _1257 = fa_light_texel(param_22);\n            float _1267 = _1257.w;\n            int param_23 = _1013 + 3;\n            vec4 _1272 = fa_light_texel(param_23);\n            float _1273 = _1272.x;\n            float cos_inner = _1273;\n            if (_1273 > 1.5)\n            {\n                cos_inner = mix(_1267, 1.0, 0.25);\n            }\n            atten *= smoothstep(_1267, cos_inner, dot(-l, normalize(_1257.xyz)));\n        }\n        if (_1017 && (_1029 < 1.5))\n        {\n            int param_24 = _1013 + 6;\n            vec4 _1297 = fa_light_texel(param_24);\n            if (_1297.z > 0.5)\n            {\n                vec3 _1305 = -to_light;\n                int param_25 = _1013 + 4;\n                int param_26 = _1013 + 5;\n                vec3 _1319 = fa_light_texel(param_25).xyz;\n                vec3 _1323 = fa_light_texel(param_26).xyz;\n                vec3 _1332 = vec3(dot(_1305, _1319), dot(_1305, _1323), dot(_1305, cross(_1319, _1323)));\n                vec3 param_27 = _1332;\n                int _1336 = fa_cube_face(param_27);\n                int param_28 = _1336;\n                vec3 param_29;\n                vec3 param_30;\n                fa_cube_face_basis(param_28, param_29, param_30);\n                vec2 _1363 = vec2(dot(_1332, cross(param_29, param_30)), dot(_1332, param_30)) / vec2(max(dot(_1332, param_29), 9.9999997473787516355514526367188e-05));\n                int _1367 = _1336 / 3;\n                vec2 param_31 = _1297.xy + (vec2(float(_1336 - (_1367 * 3)), float(_1367)) * 256.0);\n                vec2 param_32 = vec2(0.5 + (0.5 * _1363.x), 0.5 - (0.5 * _1363.y));\n                fa_light_tint = fa_cookie_sample(param_31, param_32);\n            }\n            int param_33 = _1013 + 7;\n            vec4 _1397 = fa_light_texel(param_33);\n            if (_1397.z > 0.5)\n            {\n                int param_34 = _1013 + 2;\n                int param_35 = _1013 + 4;\n                int param_36 = _1013 + 5;\n                vec2 param_37 = _1397.xy;\n                vec3 param_38 = -l;\n                vec3 param_39 = normalize(fa_light_texel(param_34).xyz);\n                vec3 param_40 = fa_light_texel(param_35).xyz;\n                vec3 param_41 = fa_light_texel(param_36).xyz;\n                atten *= fa_ies_sample(param_37, param_38, param_39, param_40, param_41);\n            }\n        }\n        else\n        {\n            if (_1017 && _1249)\n            {\n                int param_42 = _1013 + 6;\n                vec4 _1444 = fa_light_texel(param_42);\n                int param_43 = _1013 + 7;\n                vec4 _1449 = fa_light_texel(param_43);\n                bool _1452 = _1444.z > 0.5;\n                bool _1459;\n                if (!_1452)\n                {\n                    _1459 = _1449.z > 0.5;\n                }\n                else\n                {\n                    _1459 = _1452;\n                }\n                if (_1459)\n                {\n                    int param_44 = _1013 + 2;\n                    vec4 _1466 = fa_light_texel(param_44);\n                    vec3 _1470 = normalize(_1466.xyz);\n                    int param_45 = _1013 + 4;\n                    vec4 _1475 = fa_light_texel(param_45);\n                    int param_46 = _1013 + 5;\n                    vec4 _1480 = fa_light_texel(param_46);\n                    if (_1452)\n                    {\n                        vec3 _1488 = -to_light;\n                        float _1495 = _1466.w;\n                        float _1511 = 0.5 / max(dot(_1488, _1470) * (sqrt(max(1.0 - (_1495 * _1495), 0.0)) / max(_1495, 0.001000000047497451305389404296875)), 9.9999997473787516355514526367188e-05);\n                        vec2 param_47 = _1444.xy;\n                        vec2 param_48 = vec2(0.5 + (dot(_1488, _1475.xyz) * _1511), 0.5 - (dot(_1488, _1480.xyz) * _1511));\n                        fa_light_tint = fa_cookie_sample(param_47, param_48);\n                    }\n                    if (_1449.z > 0.5)\n                    {\n                        vec2 param_49 = _1449.xy;\n                        vec3 param_50 = -l;\n                        vec3 param_51 = _1470;\n                        vec3 param_52 = _1475.xyz;\n                        vec3 param_53 = _1480.xyz;\n                        atten *= fa_ies_sample(param_49, param_50, param_51, param_52, param_53);\n                    }\n                }\n            }\n        }\n    }\n    vec3 _8894 = _1026.xyz * atten;\n    if (_1017)\n    {\n        _8894 *= fa_light_tint;\n    }\n    int _1580;\n    if (_1043)\n    {\n        _1580 = 0;\n    }\n    else\n    {\n        _1580 = ((_1029 > 1.5) && (_1029 < 2.5)) ? 2 : 1;\n    }\n    return LightSample(l, _8894, atten, 1.0, dist, _1580);\n}\n\nfloat fa_shadow_split_at(int i)\n{\n    float _2317;\n    if (i == 0)\n    {\n        _2317 = fa_shadows[24].x;\n    }\n    else\n    {\n        float _2333;\n        if (i == 1)\n        {\n            _2333 = fa_shadows[24].y;\n        }\n        else\n        {\n            float _2341;\n            if (i == 2)\n            {\n                _2341 = fa_shadows[24].z;\n            }\n            else\n            {\n                _2341 = fa_shadows[24].w;\n            }\n            _2333 = _2341;\n        }\n        _2317 = _2333;\n    }\n    return _2317;\n}\n\nfloat fa_shadow_depth(inout vec2 uv, vec4 rect)\n{\n    uv = clamp(uv, rect.xy, rect.zw);\n    return textureLod(fa_shadow_tex_fa_shadow_smp, uv, 0.0).x;\n}\n\nfloat fa_shadow_fetch(vec2 uv, vec4 rect, vec3 conv)\n{\n    vec2 param = uv;\n    vec4 param_1 = rect;\n    float _2374 = fa_shadow_depth(param, param_1);\n    float _2378;\n    if (conv.x < 0.5)\n    {\n        _2378 = _2374;\n    }\n    else\n    {\n        _2378 = (conv.y * conv.z) / (conv.z - (_2374 * (conv.z - conv.y)));\n    }\n    return _2378;\n}\n\nfloat fa_shadow_noise()\n{\n    return fract(52.98291778564453125 * fract(dot(gl_FragCoord.xy, vec2(0.067110560834407806396484375, 0.005837149918079376220703125))));\n}\n\nvec2 fa_shadow_vogel(int k, int n, float phi)\n{\n    float _2305 = (float(k) * 2.3999631404876708984375) + phi;\n    return vec2(cos(_2305), sin(_2305)) * sqrt((float(k) + 0.5) / float(n));\n}\n\nfloat fa_shadow_filter(vec2 uv, vec4 rect, float zr, float texel_m, float unit, float reach, float plane, vec3 conv, int mode, float k)\n{\n    if (mode == 1)\n    {\n        vec2 param = uv;\n        vec4 param_1 = rect;\n        vec3 param_2 = conv;\n        return float(zr <= fa_shadow_fetch(param, param_1, param_2));\n    }\n    float _2424 = fa_shadow_noise() * 6.283185482025146484375;\n    float radius = 1.5;\n    if (mode == 2)\n    {\n        float _2433;\n        if (k < 0.0)\n        {\n            _2433 = (-k) / max(zr, 0.100000001490116119384765625);\n        }\n        else\n        {\n            _2433 = k;\n        }\n        float _2453 = clamp((_2433 * reach) / texel_m, 3.0, 12.0);\n        float sum = 0.0;\n        float cnt = 0.0;\n        for (int i = 0; i < 16; i++)\n        {\n            int param_3 = i;\n            int param_4 = 16;\n            float param_5 = _2424;\n            vec2 _2472 = fa_shadow_vogel(param_3, param_4, param_5) * _2453;\n            vec2 param_6 = uv + (_2472 * fa_shadows[26].zw);\n            vec4 param_7 = rect;\n            vec3 param_8 = conv;\n            float _2484 = fa_shadow_fetch(param_6, param_7, param_8);\n            if (_2484 < (zr - (length(_2472) * plane)))\n            {\n                sum += _2484;\n                cnt += 1.0;\n            }\n        }\n        if (cnt < 0.5)\n        {\n            return 1.0;\n        }\n        float _2510 = sum / cnt;\n        float _2520;\n        if (k < 0.0)\n        {\n            _2520 = (-k) / max(_2510, 0.0500000007450580596923828125);\n        }\n        else\n        {\n            _2520 = k;\n        }\n        radius = clamp(((max(zr - _2510, 0.0) * unit) * _2520) / texel_m, 1.5, 16.0);\n    }\n    float lit = 0.0;\n    int _2542 = (mode == 2) ? 24 : 16;\n    for (int i_1 = 0; i_1 < _2542; i_1++)\n    {\n        int param_9 = i_1;\n        int param_10 = _2542;\n        float param_11 = _2424;\n        vec2 _2561 = fa_shadow_vogel(param_9, param_10, param_11) * radius;\n        vec2 param_12 = uv + (_2561 * fa_shadows[26].zw);\n        vec4 param_13 = rect;\n        vec3 param_14 = conv;\n        lit += float((zr - (length(_2561) * plane)) <= fa_shadow_fetch(param_12, param_13, param_14));\n    }\n    return lit / float(_2542);\n}\n\nfloat fa_shadow_cascade(int ci, vec3 world, vec3 n, vec3 l)\n{\n    float _2603 = max(fa_shadows[ci * 1 + 20].y, 0.001000000047497451305389404296875);\n    float _2608 = clamp(dot(n, l), 0.0, 1.0);\n    float _2614 = sqrt(1.0 - (_2608 * _2608));\n    float _2621 = min(_2614 / max(_2608, 0.20000000298023223876953125), 4.0);\n    float _2626;\n    if (fa_shadows[26].y > 0.0)\n    {\n        _2626 = fa_shadows[26].y;\n    }\n    else\n    {\n        _2626 = 1.5 * fa_shadows[ci * 1 + 20].x;\n    }\n    vec4 _2651 = mat4(fa_shadows[ci * 4 + 0], fa_shadows[ci * 4 + 1], fa_shadows[ci * 4 + 2], fa_shadows[ci * 4 + 3]) * vec4(world + (n * (_2626 * _2614)), 1.0);\n    float _2658 = _2651.x;\n    bool _2661 = _2658 < fa_shadows[ci * 1 + 16].x;\n    bool _2670;\n    if (!_2661)\n    {\n        _2670 = _2658 > fa_shadows[ci * 1 + 16].z;\n    }\n    else\n    {\n        _2670 = _2661;\n    }\n    bool _2679;\n    if (!_2670)\n    {\n        _2679 = _2651.y < fa_shadows[ci * 1 + 16].y;\n    }\n    else\n    {\n        _2679 = _2670;\n    }\n    bool _2688;\n    if (!_2679)\n    {\n        _2688 = _2651.y > fa_shadows[ci * 1 + 16].w;\n    }\n    else\n    {\n        _2688 = _2679;\n    }\n    bool _2695;\n    if (!_2688)\n    {\n        _2695 = _2651.z > 1.0;\n    }\n    else\n    {\n        _2695 = _2688;\n    }\n    if (_2695)\n    {\n        return -1.0;\n    }\n    float _2703;\n    if (fa_shadows[26].x > 0.0)\n    {\n        _2703 = fa_shadows[26].x;\n    }\n    else\n    {\n        _2703 = 1.5 * fa_shadows[ci * 1 + 20].x;\n    }\n    vec2 param = _2651.xy;\n    vec4 param_1 = fa_shadows[ci * 1 + 16];\n    float param_2 = _2651.z - ((_2703 * (1.0 + (0.5 * _2621))) / _2603);\n    float param_3 = fa_shadows[ci * 1 + 20].x;\n    float param_4 = _2603;\n    float param_5 = _2603 * 0.25;\n    float param_6 = ((fa_shadows[ci * 1 + 20].x * min(_2621, 3.0)) * 0.5) / _2603;\n    vec3 param_7 = vec3(0.0);\n    int param_8 = int(fa_shadows[25].z + 0.5);\n    float param_9 = fa_shadows[25].w;\n    return fa_shadow_filter(param, param_1, param_2, param_3, param_4, param_5, param_6, param_7, param_8, param_9);\n}\n\nfloat fa_shadow_sun(vec3 world, vec3 n, vec3 l)\n{\n    if (fa_mesh_fs_params[5].z < 0.5)\n    {\n        return 1.0;\n    }\n    int _3081 = int(fa_shadows[25].x + 0.5);\n    if (_3081 < 1)\n    {\n        return 1.0;\n    }\n    float _3096 = dot(world - fa_shadows[27].xyz, fa_shadows[28].xyz);\n    int param = _3081 - 1;\n    if (_3096 > fa_shadow_split_at(param))\n    {\n        return 1.0;\n    }\n    int ci = 0;\n    bool _3108 = _3081 > 1;\n    bool _3115;\n    if (_3108)\n    {\n        _3115 = _3096 > fa_shadows[24].x;\n    }\n    else\n    {\n        _3115 = _3108;\n    }\n    if (_3115)\n    {\n        ci = 1;\n    }\n    bool _3119 = _3081 > 2;\n    bool _3126;\n    if (_3119)\n    {\n        _3126 = _3096 > fa_shadows[24].y;\n    }\n    else\n    {\n        _3126 = _3119;\n    }\n    if (_3126)\n    {\n        ci = 2;\n    }\n    bool _3130 = _3081 > 3;\n    bool _3137;\n    if (_3130)\n    {\n        _3137 = _3096 > fa_shadows[24].z;\n    }\n    else\n    {\n        _3137 = _3130;\n    }\n    if (_3137)\n    {\n        ci = 3;\n    }\n    float s = -1.0;\n    for (int k = 0; k < 4; k++)\n    {\n        if (ci >= _3081)\n        {\n            break;\n        }\n        int param_1 = ci;\n        vec3 param_2 = world;\n        vec3 param_3 = n;\n        vec3 param_4 = l;\n        float _3163 = fa_shadow_cascade(param_1, param_2, param_3, param_4);\n        s = _3163;\n        if (_3163 >= 0.0)\n        {\n            break;\n        }\n        ci++;\n    }\n    if (s < 0.0)\n    {\n        return 1.0;\n    }\n    if (fa_shadows[25].y > 0.0)\n    {\n        float _3188;\n        if (ci > 0)\n        {\n            int param_5 = ci - 1;\n            _3188 = fa_shadow_split_at(param_5);\n        }\n        else\n        {\n            _3188 = fa_shadows[28].w;\n        }\n        int param_6 = ci;\n        float _3207 = fa_shadows[25].y * max(fa_shadow_split_at(param_6) - _3188, 9.9999997473787516355514526367188e-05);\n        int param_7 = ci;\n        float _3218 = clamp((_3096 - (fa_shadow_split_at(param_7) - _3207)) / _3207, 0.0, 1.0);\n        if (_3218 > 0.0)\n        {\n            float s2 = 1.0;\n            if ((ci + 1) < _3081)\n            {\n                int param_8 = ci + 1;\n                vec3 param_9 = world;\n                vec3 param_10 = n;\n                vec3 param_11 = l;\n                float _3239 = fa_shadow_cascade(param_8, param_9, param_10, param_11);\n                s2 = _3239;\n                if (_3239 < 0.0)\n                {\n                    s2 = s;\n                }\n            }\n            s = mix(s, s2, _3218);\n        }\n    }\n    return s;\n}\n\nfloat fa_shadow_factor(vec3 n, vec3 l)\n{\n    vec3 param = fa_world_pos;\n    vec3 param_1 = n;\n    vec3 param_2 = l;\n    return fa_shadow_sun(param, param_1, param_2);\n}\n\nfloat fa_shadow_local(int li, vec3 lpos, vec3 world, vec3 n, vec3 l)\n{\n    bool _2761 = fa_mesh_fs_params[5].z < 0.5;\n    bool _2768;\n    if (!_2761)\n    {\n        _2768 = fa_shadows[29].x < 0.5;\n    }\n    else\n    {\n        _2768 = _2761;\n    }\n    if (_2768)\n    {\n        return 1.0;\n    }\n    int param = (int(fa_shadows[29].x + 0.5) - 1) + li;\n    vec4 _2781 = fa_light_texel(param);\n    float _2782 = _2781.x;\n    if (_2782 < 0.0)\n    {\n        return 1.0;\n    }\n    int _2791 = int(_2782 + 0.5);\n    int param_1 = _2791;\n    vec4 _2795 = fa_light_texel(param_1);\n    int param_2 = _2791 + 1;\n    vec4 _2800 = fa_light_texel(param_2);\n    float fade = 1.0;\n    float _2803 = _2795.y;\n    if (_2803 > 0.0)\n    {\n        float _2820 = 1.0 - smoothstep(0.75 * _2803, _2803, length(world - fa_shadows[27].xyz));\n        fade = _2820;\n        if (_2820 <= 0.0)\n        {\n            return 1.0;\n        }\n    }\n    int face = 0;\n    if (_2795.x > 1.5)\n    {\n        vec3 param_3 = world - lpos;\n        face = fa_cube_face(param_3);\n    }\n    int _2844 = (_2791 + 2) + (face * 6);\n    int param_4 = _2844;\n    int param_5 = _2844 + 1;\n    int param_6 = _2844 + 3;\n    vec4 _2858 = fa_light_texel(param_6);\n    int param_7 = _2844 + 4;\n    vec4 _2863 = fa_light_texel(param_7);\n    int param_8 = _2844 + 5;\n    vec4 _2868 = fa_light_texel(param_8);\n    float _2880 = _2868.x * max(dot(_2858, vec4(world, 1.0)), 0.001000000047497451305389404296875);\n    float _2885 = clamp(dot(n, l), 0.0, 1.0);\n    float _2908 = clamp(dot(n, _2858.xyz), -1.0, 1.0);\n    float _2927 = min(sqrt(1.0 - (_2908 * _2908)) / max(abs(dot(n, world - lpos)) / max(dot(_2858, vec4(world, 1.0)), 0.001000000047497451305389404296875), 0.20000000298023223876953125), 4.0);\n    float _2930 = _2800.y;\n    float _2932;\n    if (_2930 > 0.0)\n    {\n        _2932 = _2930;\n    }\n    else\n    {\n        _2932 = 1.5 * _2880;\n    }\n    vec4 _2952 = vec4(world + (n * (_2932 * sqrt(1.0 - (_2885 * _2885)))), 1.0);\n    float _2956 = dot(_2858, _2952);\n    float _2959 = _2868.y;\n    if (_2956 < _2959)\n    {\n        return 1.0;\n    }\n    vec2 _2974 = vec2(dot(fa_light_texel(param_4), _2952), dot(fa_light_texel(param_5), _2952)) / vec2(_2956);\n    float _2976 = _2974.x;\n    bool _2979 = _2976 < _2863.x;\n    bool _2988;\n    if (!_2979)\n    {\n        _2988 = _2976 > _2863.z;\n    }\n    else\n    {\n        _2988 = _2979;\n    }\n    bool _2997;\n    if (!_2988)\n    {\n        _2997 = _2974.y < _2863.y;\n    }\n    else\n    {\n        _2997 = _2988;\n    }\n    bool _3006;\n    if (!_2997)\n    {\n        _3006 = _2974.y > _2863.w;\n    }\n    else\n    {\n        _3006 = _2997;\n    }\n    if (_3006)\n    {\n        return 1.0;\n    }\n    float _3012 = _2800.x;\n    float _3014;\n    if (_3012 > 0.0)\n    {\n        _3014 = _3012;\n    }\n    else\n    {\n        _3014 = 1.5 * _2880;\n    }\n    vec2 param_9 = _2974;\n    vec4 param_10 = _2863;\n    float param_11 = _2956 - (_3014 * (1.0 + (0.5 * _2927)));\n    float param_12 = _2880;\n    float param_13 = 1.0;\n    float param_14 = _2868.z * 0.25;\n    float param_15 = (_2880 * min(_2927, 3.0)) * 0.5;\n    vec3 param_16 = vec3(1.0, _2959, _2868.z);\n    int param_17 = int(_2795.z + 0.5);\n    float param_18 = _2795.w;\n    return mix(1.0, fa_shadow_filter(param_9, param_10, param_11, param_12, param_13, param_14, param_15, param_16, param_17, param_18), fade);\n}\n\nfloat fa_contact_shadow(int li, vec3 world, vec3 gn, vec3 l, float dist)\n{\n    bool _5155 = fa_mesh_fs_params[24].x < 0.5;\n    bool _5162;\n    if (!_5155)\n    {\n        _5162 = fa_shadows[29].x < 0.5;\n    }\n    else\n    {\n        _5162 = _5155;\n    }\n    if (_5162)\n    {\n        return 1.0;\n    }\n    int param = (int(fa_shadows[29].x + 0.5) - 1) + li;\n    vec4 _5175 = fa_light_texel(param);\n    float _5176 = _5175.y;\n    float len = _5176;\n    if (_5176 <= 0.0)\n    {\n        return 1.0;\n    }\n    float _5188 = length(world - fa_mesh_fs_params[0].xyz);\n    float _5198 = 1.0 - smoothstep(0.5 * fa_mesh_fs_params[25].x, fa_mesh_fs_params[25].x, _5188);\n    if (_5198 <= 0.0)\n    {\n        return 1.0;\n    }\n    float _5204 = len;\n    float _5207 = min(_5204, 0.89999997615814208984375 * dist);\n    len = _5207;\n    float _5212 = 0.004999999888241291046142578125 + (0.0030000000260770320892333984375 * _5188);\n    float _5217 = _5212 + (0.5 * _5207);\n    vec3 _5223 = world + (gn * _5212);\n    float _5225 = fa_shadow_noise();\n    float occ = 0.0;\n    float _5289;\n    for (int k = 0; k < 12; k++)\n    {\n        float _5240 = (float(k) + _5225) * 0.083333335816860198974609375;\n        vec3 _5248 = _5223 + (l * (_5240 * len));\n        vec4 _5254 = vec4(_5248, 1.0);\n        float _5260 = dot(fa_mesh_fs_params[28], _5254);\n        if (_5260 < 9.9999997473787516355514526367188e-05)\n        {\n            break;\n        }\n        vec2 _5280 = vec2(dot(fa_mesh_fs_params[26], _5254), dot(fa_mesh_fs_params[27], _5254)) / vec2(_5260);\n        float _5284 = _5280.x * 0.5;\n        float _5285 = _5284 + 0.5;\n        if (fa_mesh_fs_params[24].y > 0.5)\n        {\n            _5289 = (_5280.y * 0.5) + 0.5;\n        }\n        else\n        {\n            _5289 = 0.5 - (_5280.y * 0.5);\n        }\n        bool _5305 = _5285 < 0.0;\n        bool _5312;\n        if (!_5305)\n        {\n            _5312 = _5285 >= 1.0;\n        }\n        else\n        {\n            _5312 = _5305;\n        }\n        bool _5319;\n        if (!_5312)\n        {\n            _5319 = _5289 < 0.0;\n        }\n        else\n        {\n            _5319 = _5312;\n        }\n        bool _5326;\n        if (!_5319)\n        {\n            _5326 = _5289 >= 1.0;\n        }\n        else\n        {\n            _5326 = _5319;\n        }\n        if (_5326)\n        {\n            break;\n        }\n        vec4 _5345 = texelFetch(fa_screen_tex_fa_shadow_smp, ivec2(vec2(_5285, _5289) * fa_mesh_fs_params[24].zw), 0);\n        if (_5345.w < 0.5)\n        {\n            continue;\n        }\n        float _5364 = (dot(fa_mesh_fs_params[29].xyz, _5248) + fa_mesh_fs_params[29].w) - _5345.x;\n        if ((_5364 > _5212) && (_5364 < _5217))\n        {\n            occ = max(occ, (1.0 - (_5240 * _5240)) * smoothstep(0.0, 0.0500000007450580596923828125, min(min(_5285, 0.5 - _5284), min(_5289, 1.0 - _5289))));\n        }\n    }\n    return 1.0 - (occ * _5198);\n}\n\nLightSample fa_light_shadowed(int li, vec3 world_pos, vec3 gn)\n{\n    int param = li;\n    float _5830 = fa_baked_keep(param);\n    if (_5830 <= 0.0)\n    {\n        int param_1 = li;\n        return LightSample(vec3(0.0, 1.0, 0.0), vec3(0.0), 0.0, 1.0, 0.0, int(fa_light_type(param_1) + 0.5));\n    }\n    int param_2 = li;\n    vec3 param_3 = world_pos;\n    vec3 param_4 = gn;\n    LightSample _5856 = fa_light_sample_n(param_2, param_3, param_4);\n    vec3 _8963 = _5856.color;\n    float _8964 = _5856.attenuation;\n    float _8965 = _5856.shadow;\n    bool _5859 = _5856.type == 0;\n    if (_5859 && (li == 0))\n    {\n        vec3 param_5 = gn;\n        vec3 param_6 = _5856.direction;\n        float _5870 = fa_shadow_factor(param_5, param_6);\n        _8965 = _5870;\n        _8963 *= _5870;\n    }\n    else\n    {\n        bool _5881 = _5856.type != 0;\n        bool _5887;\n        if (_5881)\n        {\n            _5887 = _8964 > 0.0;\n        }\n        else\n        {\n            _5887 = _5881;\n        }\n        if (_5887)\n        {\n            int param_7 = li;\n            int param_8 = fa_light_base(param_7);\n            int param_9 = li;\n            vec3 param_10 = fa_light_texel(param_8).xyz;\n            vec3 param_11 = world_pos;\n            vec3 param_12 = gn;\n            vec3 param_13 = _5856.direction;\n            float _5906 = fa_shadow_local(param_9, param_10, param_11, param_12, param_13);\n            _8965 = _5906;\n            _8963 *= _5906;\n        }\n    }\n    bool _5916 = fa_mesh_fs_params[24].x > 0.5;\n    bool _5922;\n    if (_5916)\n    {\n        _5922 = _8964 > 0.0;\n    }\n    else\n    {\n        _5922 = _5916;\n    }\n    if (_5922)\n    {\n        float _5929;\n        if (_5859)\n        {\n            _5929 = 1000000000.0;\n        }\n        else\n        {\n            _5929 = _5856._distance;\n        }\n        int param_14 = li;\n        vec3 param_15 = world_pos;\n        vec3 param_16 = gn;\n        vec3 param_17 = _5856.direction;\n        float param_18 = _5929;\n        float _5947 = fa_contact_shadow(param_14, param_15, param_16, param_17, param_18);\n        _8965 *= _5947;\n        _8963 *= _5947;\n    }\n    float _5960 = _8964;\n    float _5961 = _5960 * _5830;\n    _8964 = _5961;\n    vec3 _5965 = _8963;\n    vec3 _5966 = _5965 * _5830;\n    _8963 = _5966;\n    return LightSample(_5856.direction, _5966, _5961, _8965, _5856._distance, _5856.type);\n}\n\nvec3 fa_ltc_tangent(vec3 n, vec3 v)\n{\n    vec3 _6000 = v - (n * dot(v, n));\n    vec3 t = _6000;\n    float _6004 = dot(_6000, _6000);\n    float l2 = _6004;\n    if (_6004 < 1.0000000133514319600180897396058e-10)\n    {\n        vec3 _6014;\n        if (abs(n.z) < 0.999000012874603271484375)\n        {\n            _6014 = cross(n, vec3(0.0, 0.0, 1.0));\n        }\n        else\n        {\n            _6014 = cross(n, vec3(1.0, 0.0, 0.0));\n        }\n        t = _6014;\n        l2 = dot(_6014, _6014);\n    }\n    return t * inversesqrt(l2);\n}\n\nvec3 fa_ltc_local(vec3 t1, vec3 n, vec3 p)\n{\n    return vec3(dot(t1, p), dot(cross(n, t1), p), dot(n, p));\n}\n\nvec3 fa_ltc_edge_vector(vec3 a, vec3 b)\n{\n    float _6049 = dot(a, a);\n    float _6053 = dot(b, b);\n    if ((_6049 < 1.0000000195414813782625560981111e-24) || (_6053 < 1.0000000195414813782625560981111e-24))\n    {\n        return vec3(0.0);\n    }\n    vec3 _6067 = a * inversesqrt(_6049);\n    vec3 _6072 = b * inversesqrt(_6053);\n    float _6076 = dot(_6067, _6072);\n    float _6079 = abs(_6076);\n    float g = (((((((((((0.0416471660137176513671875 * _6079) - 0.1924748718738555908203125) * _6079) + 0.4179156124591827392578125) * _6079) - 0.616057217121124267578125) * _6079) + 0.777722418308258056640625) * _6079) - 0.999542415142059326171875) * _6079) + 1.570791721343994140625;\n    if (_6076 < 0.0)\n    {\n        g = (3.1415927410125732421875 * inversesqrt(max(1.0 - (_6076 * _6076), 1.0000000116860974230803549289703e-07))) - g;\n    }\n    return cross(_6067, _6072) * g;\n}\n\nvoid fa_ltc_clip_edge(vec3 a, vec3 b, inout vec3 sum, inout vec3 leave, inout vec3 enter, inout vec2 seen)\n{\n    bool _6136 = a.z > 0.0;\n    bool _6140 = b.z > 0.0;\n    if (_6136 && _6140)\n    {\n        vec3 param = a;\n        vec3 param_1 = b;\n        sum += fa_ltc_edge_vector(param, param_1);\n    }\n    else\n    {\n        if (_6136 != _6140)\n        {\n            vec3 _6175 = a + ((b - a) * (a.z / (a.z - b.z)));\n            _6175.z = 0.0;\n            if (_6136)\n            {\n                vec3 param_2 = a;\n                vec3 param_3 = _6175;\n                sum += fa_ltc_edge_vector(param_2, param_3);\n                leave = _6175;\n                seen.x = 1.0;\n            }\n            else\n            {\n                vec3 param_4 = _6175;\n                vec3 param_5 = b;\n                sum += fa_ltc_edge_vector(param_4, param_5);\n                enter = _6175;\n                seen.y = 1.0;\n            }\n        }\n    }\n}\n\nfloat fa_ltc_quad(vec4 abcd, vec3 p0, vec3 p1, vec3 p2, vec3 p3)\n{\n    vec3 _6224 = vec3((abcd.x * p0.x) + (abcd.y * p0.z), p0.y, (abcd.z * p0.x) + (abcd.w * p0.z));\n    vec3 _6250 = vec3((abcd.x * p1.x) + (abcd.y * p1.z), p1.y, (abcd.z * p1.x) + (abcd.w * p1.z));\n    vec3 _6276 = vec3((abcd.x * p2.x) + (abcd.y * p2.z), p2.y, (abcd.z * p2.x) + (abcd.w * p2.z));\n    vec3 _6302 = vec3((abcd.x * p3.x) + (abcd.y * p3.z), p3.y, (abcd.z * p3.x) + (abcd.w * p3.z));\n    vec3 sum = vec3(0.0);\n    vec3 leave = vec3(0.0);\n    vec3 enter = vec3(0.0);\n    vec3 param = _6224;\n    vec3 param_1 = _6250;\n    vec3 param_2 = vec3(0.0);\n    vec3 param_3 = vec3(0.0);\n    vec3 param_4 = vec3(0.0);\n    vec2 param_5 = vec2(0.0);\n    fa_ltc_clip_edge(param, param_1, param_2, param_3, param_4, param_5);\n    sum = param_2;\n    leave = param_3;\n    enter = param_4;\n    vec3 param_6 = _6250;\n    vec3 param_7 = _6276;\n    vec3 param_8 = param_2;\n    vec3 param_9 = param_3;\n    vec3 param_10 = param_4;\n    vec2 param_11 = param_5;\n    fa_ltc_clip_edge(param_6, param_7, param_8, param_9, param_10, param_11);\n    sum = param_8;\n    leave = param_9;\n    enter = param_10;\n    vec3 param_12 = _6276;\n    vec3 param_13 = _6302;\n    vec3 param_14 = param_8;\n    vec3 param_15 = param_9;\n    vec3 param_16 = param_10;\n    vec2 param_17 = param_11;\n    fa_ltc_clip_edge(param_12, param_13, param_14, param_15, param_16, param_17);\n    sum = param_14;\n    leave = param_15;\n    enter = param_16;\n    vec3 param_18 = _6302;\n    vec3 param_19 = _6224;\n    vec3 param_20 = param_14;\n    vec3 param_21 = param_15;\n    vec3 param_22 = param_16;\n    vec2 param_23 = param_17;\n    fa_ltc_clip_edge(param_18, param_19, param_20, param_21, param_22, param_23);\n    sum = param_20;\n    leave = param_21;\n    enter = param_22;\n    if ((param_23.x * param_23.y) > 0.5)\n    {\n        vec3 param_24 = leave;\n        vec3 param_25 = enter;\n        sum += fa_ltc_edge_vector(param_24, param_25);\n    }\n    return sum.z * 0.15915493667125701904296875;\n}\n\nfloat fa_ltc_rect(vec4 abcd, vec3 center, vec3 ex, vec3 ey)\n{\n    vec4 param = abcd;\n    vec3 param_1 = (center - ex) - ey;\n    vec3 param_2 = (center + ex) - ey;\n    vec3 param_3 = (center + ex) + ey;\n    vec3 param_4 = (center - ex) + ey;\n    return abs(fa_ltc_quad(param, param_1, param_2, param_3, param_4));\n}\n\nfloat fa_area_form(vec4 m, float shape, vec3 pc, vec3 ex, vec3 ey)\n{\n    if ((shape < 0.5) || (shape > 1.5))\n    {\n        vec4 param = m;\n        vec3 param_1 = pc;\n        vec3 param_2 = ex;\n        vec3 param_3 = ey;\n        return fa_ltc_rect(param, param_1, param_2, param_3);\n    }\n    vec3 _6451 = (pc + (ex * 0.92387950420379638671875)) + (ey * 0.3826834261417388916015625);\n    vec3 _6475 = (pc - (ex * 0.92387950420379638671875)) + (ey * 0.3826834261417388916015625);\n    vec3 _6491 = (pc - (ex * 0.3826834261417388916015625)) - (ey * 0.92387950420379638671875);\n    vec4 param_4 = m;\n    vec3 param_5 = _6451;\n    vec3 param_6 = (pc + (ex * 0.3826834261417388916015625)) + (ey * 0.92387950420379638671875);\n    vec3 param_7 = (pc - (ex * 0.3826834261417388916015625)) + (ey * 0.92387950420379638671875);\n    vec3 param_8 = _6475;\n    vec4 param_9 = m;\n    vec3 param_10 = _6451;\n    vec3 param_11 = _6475;\n    vec3 param_12 = (pc - (ex * 0.92387950420379638671875)) - (ey * 0.3826834261417388916015625);\n    vec3 param_13 = _6491;\n    vec4 param_14 = m;\n    vec3 param_15 = _6451;\n    vec3 param_16 = _6491;\n    vec3 param_17 = (pc + (ex * 0.3826834261417388916015625)) - (ey * 0.92387950420379638671875);\n    vec3 param_18 = (pc + (ex * 0.92387950420379638671875)) - (ey * 0.3826834261417388916015625);\n    return abs((fa_ltc_quad(param_4, param_5, param_6, param_7, param_8) + fa_ltc_quad(param_9, param_10, param_11, param_12, param_13)) + fa_ltc_quad(param_14, param_15, param_16, param_17, param_18));\n}\n\nvec2 fa_ltc_uv(float roughness, float ndv)\n{\n    return ((vec2(clamp((roughness - 0.0500000007450580596923828125) * 1.0526316165924072265625, 0.0, 1.0), sqrt(clamp(1.0 - ndv, 0.0, 1.0))) * 63.0) + vec2(0.5)) * vec2(0.015625);\n}\n\nvec3 fa_area_shade(int li, vec3 world_pos, vec3 n, vec3 v, vec3 diffuse_color, vec3 f0, float f90, float roughness, float ndv, float window)\n{\n    int param = li;\n    int _6549 = fa_light_base(param);\n    int param_1 = _6549;\n    int param_2 = _6549 + 1;\n    int param_3 = _6549 + 2;\n    int param_4 = _6549 + 4;\n    vec4 _6571 = fa_light_texel(param_4);\n    int param_5 = _6549 + 5;\n    vec4 _6576 = fa_light_texel(param_5);\n    int param_6 = _6549 + 6;\n    vec4 _6581 = fa_light_texel(param_6);\n    float _6582 = _6581.w;\n    vec3 _6587 = fa_light_texel(param_1).xyz - world_pos;\n    bool _6589 = _6582 < 1.5;\n    bool _6596;\n    if (_6589)\n    {\n        _6596 = dot(normalize(fa_light_texel(param_3).xyz), _6587) >= 0.0;\n    }\n    else\n    {\n        _6596 = _6589;\n    }\n    if (_6596)\n    {\n        return vec3(0.0);\n    }\n    bool _6605 = (_6582 > 0.5) && _6589;\n    float _6609 = _6605 ? 1.0539000034332275390625 : 1.0;\n    vec3 _6612 = _6571.xyz;\n    float _6614 = _6571.w;\n    vec3 _6620 = _6576.xyz;\n    float _6622 = _6576.w;\n    vec3 up = _6620 * (_6622 * _6609);\n    float _6628;\n    if (_6605)\n    {\n        _6628 = (3.1415927410125732421875 * _6614) * _6614;\n    }\n    else\n    {\n        _6628 = (4.0 * _6614) * _6622;\n    }\n    if (_6582 > 1.5)\n    {\n        vec3 _6654 = cross(_6612, -_6587);\n        vec3 perp = _6654;\n        float _6658 = dot(_6654, _6654);\n        vec3 _6661;\n        if (_6658 > 1.0000000133514319600180897396058e-10)\n        {\n            _6661 = perp * inversesqrt(_6658);\n        }\n        else\n        {\n            _6661 = _6620;\n        }\n        perp = _6661;\n        up = _6661 * _6622;\n    }\n    float _6682 = max(_6628, 9.9999999747524270787835121154785e-07);\n    vec3 param_7 = n;\n    vec3 param_8 = v;\n    vec3 _6692 = fa_ltc_tangent(param_7, param_8);\n    vec3 param_9 = _6692;\n    vec3 param_10 = n;\n    vec3 param_11 = _6587;\n    vec3 _6700 = fa_ltc_local(param_9, param_10, param_11);\n    vec3 param_12 = _6692;\n    vec3 param_13 = n;\n    vec3 param_14 = _6612 * (_6614 * _6609);\n    vec3 _6708 = fa_ltc_local(param_12, param_13, param_14);\n    vec3 param_15 = _6692;\n    vec3 param_16 = n;\n    vec3 param_17 = up;\n    vec3 _6716 = fa_ltc_local(param_15, param_16, param_17);\n    vec4 param_18 = vec4(1.0, 0.0, 0.0, 1.0);\n    float param_19 = _6582;\n    vec3 param_20 = _6700;\n    vec3 param_21 = _6708;\n    vec3 param_22 = _6716;\n    float param_23 = roughness;\n    float param_24 = ndv;\n    vec2 _6735 = fa_ltc_uv(param_23, param_24) * 64.0;\n    vec2 param_25 = _6735;\n    vec2 param_26 = _6735 + vec2(64.0, 0.0);\n    vec4 _6745 = fa_atlas_fetch(param_26);\n    vec4 param_27 = fa_atlas_fetch(param_25);\n    float param_28 = _6582;\n    vec3 param_29 = _6700;\n    vec3 param_30 = _6708;\n    vec3 param_31 = _6716;\n    return (((diffuse_color * fa_area_form(param_18, param_19, param_20, param_21, param_22)) + (((f0 * _6745.x) + ((vec3(f90) - f0) * _6745.y)) * fa_area_form(param_27, param_28, param_29, param_30, param_31))) * fa_light_texel(param_2).xyz) * ((((3.1415927410125732421875 * dot(_6587, _6587)) + _6682) / _6682) * window);\n}\n\nvec3 fa_light_rgb(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 1;\n    return fa_light_texel(param_1).xyz;\n}\n\nfloat fa_d_charlie(float alpha, float ndh)\n{\n    float _4892 = 1.0 / alpha;\n    return ((2.0 + _4892) * pow(sqrt(max(1.0 - (ndh * ndh), 9.9999997473787516355514526367188e-05)), _4892)) * 0.15915493667125701904296875;\n}\n\nfloat fa_v_ashikhmin(float ndl, float ndv)\n{\n    return clamp(0.25 / max((ndl + ndv) - (ndl * ndv), 9.9999997473787516355514526367188e-05), 0.0, 1.0);\n}\n\nfloat fa_layers_coat(FaLayers L, vec3 l, vec3 h, float vdh)\n{\n    float _4927 = max(dot(L.nc, l), 0.0);\n    float _4933 = max(dot(L.nc, h), 0.0);\n    float _4942 = ((_4933 * _4933) * (L.coat_a2 - 1.0)) + 1.0;\n    return (((L.coat * (0.039999999105930328369140625 + (0.959999978542327880859375 * pow(clamp(1.0 - vdh, 0.0, 1.0), 5.0)))) * (((L.coat_a2 / ((3.1415927410125732421875 * _4942) * _4942)) * (0.5 / max(mix((2.0 * _4927) * L.coat_ndv, _4927 + L.coat_ndv, L.coat_alpha), 9.9999997473787516355514526367188e-05))) * 3.1415927410125732421875)) * step(9.9999997473787516355514526367188e-05, _4927)) * _4927;\n}\n\nvec3 fa_area_layers(FaLayers L, int li, vec3 world_pos, vec3 n, vec3 v, vec3 l, vec3 diffuse_color, vec3 f0, float roughness, float ndv, float window)\n{\n    int param = li;\n    vec3 param_1 = world_pos;\n    vec3 param_2 = n;\n    vec3 param_3 = v;\n    vec3 param_4 = diffuse_color;\n    vec3 param_5 = f0;\n    float param_6 = L.f90;\n    float param_7 = roughness;\n    float param_8 = ndv;\n    float param_9 = window;\n    float _6813;\n    if (L.sheen_on)\n    {\n        _6813 = L.sheen_scale;\n    }\n    else\n    {\n        _6813 = 1.0;\n    }\n    vec3 result = fa_area_shade(param, param_1, param_2, param_3, param_4, param_5, param_6, param_7, param_8, param_9) * (L.keep * _6813);\n    vec3 _6826 = normalize(l + v);\n    int param_10 = li;\n    vec3 _6837 = fa_light_rgb(param_10) * window;\n    if (L.sheen_on)\n    {\n        float _6846 = max(dot(n, l), 0.0);\n        float param_11 = L.sheen_alpha;\n        float param_12 = max(dot(n, _6826), 0.0);\n        float param_13 = _6846;\n        float param_14 = ndv;\n        result += ((L.sheen * _6837) * (((((fa_d_charlie(param_11, param_12) * fa_v_ashikhmin(param_13, param_14)) * 3.1415927410125732421875) * step(9.9999997473787516355514526367188e-05, _6846)) * _6846) * L.keep));\n    }\n    if (L.coat > 0.0)\n    {\n        FaLayers param_15 = L;\n        vec3 param_16 = l;\n        vec3 param_17 = _6826;\n        float param_18 = max(dot(v, _6826), 0.0);\n        result += (_6837 * fa_layers_coat(param_15, param_16, param_17, param_18));\n    }\n    return result;\n}\n\nfloat fa_d_ggx_aniso(float ndh, float tdh, float bdh, float at, float ab)\n{\n    float _4795 = tdh / at;\n    float _4799 = bdh / ab;\n    float _4811 = ((_4795 * _4795) + (_4799 * _4799)) + (ndh * ndh);\n    return 1.0 / ((((3.1415927410125732421875 * at) * ab) * _4811) * _4811);\n}\n\nfloat fa_lambda_ggx_aniso(float n, float t, float b, float at, float ab)\n{\n    return 0.5 * (sqrt(1.0 + (((((at * at) * t) * t) + (((ab * ab) * b) * b)) / max(n * n, 9.9999999392252902907785028219223e-09))) - 1.0);\n}\n\nfloat fa_v_ggx_aniso(float ndl, float ndv, float tdv, float bdv, float tdl, float bdl, float at, float ab)\n{\n    float param = ndv;\n    float param_1 = tdv;\n    float param_2 = bdv;\n    float param_3 = at;\n    float param_4 = ab;\n    float param_5 = ndl;\n    float param_6 = tdl;\n    float param_7 = bdl;\n    float param_8 = at;\n    float param_9 = ab;\n    return clamp(1.0 / ((4.0 * max(ndl * ndv, 9.9999997473787516355514526367188e-05)) * ((1.0 + fa_lambda_ggx_aniso(param, param_1, param_2, param_3, param_4)) + fa_lambda_ggx_aniso(param_5, param_6, param_7, param_8, param_9))), 0.0, 1.0);\n}\n\nvec3 fa_layers_light(FaLayers L, vec3 diffuse_color, vec3 f0, vec3 n, vec3 v, vec3 l, vec3 h, float ndl, float ndv, float ndh, float vdh, float alpha, float a2)\n{\n    float _4991 = step(9.9999997473787516355514526367188e-05, ndl);\n    float d_ggx;\n    float vis;\n    if (L.aniso != 0.0)\n    {\n        float param = ndh;\n        float param_1 = dot(L.t, h);\n        float param_2 = dot(L.b, h);\n        float param_3 = L.at;\n        float param_4 = L.ab;\n        d_ggx = fa_d_ggx_aniso(param, param_1, param_2, param_3, param_4);\n        float param_5 = ndl;\n        float param_6 = ndv;\n        float param_7 = dot(L.t, v);\n        float param_8 = dot(L.b, v);\n        float param_9 = dot(L.t, l);\n        float param_10 = dot(L.b, l);\n        float param_11 = L.at;\n        float param_12 = L.ab;\n        vis = fa_v_ggx_aniso(param_5, param_6, param_7, param_8, param_9, param_10, param_11, param_12);\n    }\n    else\n    {\n        float _5070 = ((ndh * ndh) * (a2 - 1.0)) + 1.0;\n        d_ggx = a2 / ((3.1415927410125732421875 * _5070) * _5070);\n        vis = 0.5 / max(mix((2.0 * ndl) * ndv, ndl + ndv, alpha), 9.9999997473787516355514526367188e-05);\n    }\n    vec3 base = diffuse_color + (((f0 + ((vec3(L.f90) - f0) * pow(clamp(1.0 - vdh, 0.0, 1.0), 5.0))) * ((d_ggx * vis) * 3.1415927410125732421875)) * _4991);\n    if (L.sheen_on)\n    {\n        float param_13 = L.sheen_alpha;\n        float param_14 = ndh;\n        float param_15 = ndl;\n        float param_16 = ndv;\n        base = (base * L.sheen_scale) + (L.sheen * (((fa_d_charlie(param_13, param_14) * fa_v_ashikhmin(param_15, param_16)) * 3.1415927410125732421875) * _4991));\n    }\n    vec3 result = base * (L.keep * ndl);\n    if (L.coat > 0.0)\n    {\n        FaLayers param_17 = L;\n        vec3 param_18 = l;\n        vec3 param_19 = h;\n        float param_20 = vdh;\n        result += vec3(fa_layers_coat(param_17, param_18, param_19, param_20));\n    }\n    return result;\n}\n\nvec2 fa_env_brdf(float rough, float ndv)\n{\n    vec4 _4201 = (vec4(-1.0, -0.0274999998509883880615234375, -0.572000026702880859375, 0.02199999988079071044921875) * rough) + vec4(1.0, 0.0425000004470348358154296875, 1.03999996185302734375, -0.039999999105930328369140625);\n    float _4204 = _4201.x;\n    return (vec2(-1.03999996185302734375, 1.03999996185302734375) * ((min(_4204 * _4204, exp2((-9.27999973297119140625) * ndv)) * _4204) + _4201.y)) + _4201.zw;\n}\n\nvec3 fa_probe_level(vec2 origin, float res, int lv, vec2 e)\n{\n    float _3512;\n    if (lv == 0)\n    {\n        _3512 = 0.0;\n    }\n    else\n    {\n        _3512 = res + 2.0;\n    }\n    float _3522;\n    if (lv == 0)\n    {\n        _3522 = 0.0;\n    }\n    else\n    {\n        _3522 = (res - (res / float(1 << (lv - 1)))) + (2.0 * float(lv - 1));\n    }\n    return textureLod(fa_probe_atlas_fa_env_smp, (((origin + vec2(_3512, _3522)) + vec2(1.0)) + (((e * 0.5) + vec2(0.5)) * (res / float(1 << lv)))) / fa_atlas_size(), 0.0).xyz;\n}\n\nvec3 fa_probe_radiance(vec2 origin, float res, vec3 d, float rough)\n{\n    float _3567;\n    if (res > 64.5)\n    {\n        _3567 = 5.0;\n    }\n    else\n    {\n        _3567 = (res > 32.5) ? 4.0 : 3.0;\n    }\n    float _3582 = clamp(rough, 0.0, 1.0) * (_3567 - 1.0);\n    int _3589 = int(min(floor(_3582), _3567 - 2.0));\n    float _3594 = _3582 - float(_3589);\n    vec3 param = d;\n    vec2 _3598 = fa_oct_encode(param);\n    vec2 param_1 = origin;\n    float param_2 = res;\n    int param_3 = _3589;\n    vec2 param_4 = _3598;\n    vec3 _3608 = fa_probe_level(param_1, param_2, param_3, param_4);\n    if (_3594 < 0.00200000009499490261077880859375)\n    {\n        return _3608;\n    }\n    vec2 param_5 = origin;\n    float param_6 = res;\n    int param_7 = _3589 + 1;\n    vec2 param_8 = _3598;\n    return mix(_3608, fa_probe_level(param_5, param_6, param_7, param_8), vec3(_3594));\n}\n\nvec3 fa_probe_box_dir(vec3 d, vec4 posw, vec4 bx, vec4 by, vec4 bz)\n{\n    if (posw.w < 0.5)\n    {\n        return d;\n    }\n    float _3678 = dot(bx.xyz, fa_world_pos) + bx.w;\n    float _3685 = dot(by.xyz, fa_world_pos) + by.w;\n    float _3692 = dot(bz.xyz, fa_world_pos) + bz.w;\n    float _3698 = dot(bx.xyz, d);\n    float _3702 = dot(by.xyz, d);\n    float _3706 = dot(bz.xyz, d);\n    float _3712;\n    if (_3698 > 9.9999999747524270787835121154785e-07)\n    {\n        _3712 = (1.0 - _3678) / _3698;\n    }\n    else\n    {\n        float _3726;\n        if (_3698 < (-9.9999999747524270787835121154785e-07))\n        {\n            _3726 = ((-1.0) - _3678) / _3698;\n        }\n        else\n        {\n            _3726 = 1000000015047466219876688855040.0;\n        }\n        _3712 = _3726;\n    }\n    float tx = _3712;\n    float _3743;\n    if (_3702 > 9.9999999747524270787835121154785e-07)\n    {\n        _3743 = (1.0 - _3685) / _3702;\n    }\n    else\n    {\n        float _3756;\n        if (_3702 < (-9.9999999747524270787835121154785e-07))\n        {\n            _3756 = ((-1.0) - _3685) / _3702;\n        }\n        else\n        {\n            _3756 = 1000000015047466219876688855040.0;\n        }\n        _3743 = _3756;\n    }\n    float ty = _3743;\n    float _3772;\n    if (_3706 > 9.9999999747524270787835121154785e-07)\n    {\n        _3772 = (1.0 - _3692) / _3706;\n    }\n    else\n    {\n        float _3785;\n        if (_3706 < (-9.9999999747524270787835121154785e-07))\n        {\n            _3785 = ((-1.0) - _3692) / _3706;\n        }\n        else\n        {\n            _3785 = 1000000015047466219876688855040.0;\n        }\n        _3772 = _3785;\n    }\n    float _3797 = tx;\n    float _3800 = (_3797 > 0.0) ? _3797 : 1000000015047466219876688855040.0;\n    tx = _3800;\n    float _3801 = ty;\n    float _3804 = (_3801 > 0.0) ? _3801 : 1000000015047466219876688855040.0;\n    ty = _3804;\n    float _3814 = min(_3800, min(_3804, (_3772 > 0.0) ? _3772 : 1000000015047466219876688855040.0));\n    if (_3814 > 100000001504746621987668885504.0)\n    {\n        return d;\n    }\n    vec3 _3830 = (fa_world_pos + (d * _3814)) - posw.xyz;\n    vec3 _3835;\n    if (dot(_3830, _3830) > 1.0000000133514319600180897396058e-10)\n    {\n        _3835 = normalize(_3830);\n    }\n    else\n    {\n        _3835 = d;\n    }\n    return _3835;\n}\n\nvec3 fa_probe_environment(vec4 tile, vec4 posw, vec4 bx, vec4 by, vec4 bz, inout vec3 d, float rough)\n{\n    vec3 param = d;\n    vec4 param_1 = posw;\n    vec4 param_2 = bx;\n    vec4 param_3 = by;\n    vec4 param_4 = bz;\n    d = fa_probe_box_dir(param, param_1, param_2, param_3, param_4);\n    vec2 param_5 = tile.xy;\n    float param_6 = tile.z;\n    vec3 param_7 = d;\n    float param_8 = rough;\n    return fa_probe_radiance(param_5, param_6, param_7, param_8);\n}\n\nvec3 fa_environment(vec3 d, float rough)\n{\n    float _3881 = (1.0 - fa_mesh_fs_params[42].w) - fa_mesh_fs_params[47].w;\n    vec3 outc = vec3(0.0);\n    if (_3881 > 0.0005000000237487256526947021484375)\n    {\n        vec3 base;\n        if (fa_mesh_fs_params[11].w > 0.5)\n        {\n            vec2 param = fa_mesh_fs_params[41].zw;\n            float param_1 = 128.0;\n            vec3 param_2 = d;\n            float param_3 = rough;\n            base = fa_probe_radiance(param, param_1, param_2, param_3);\n        }\n        else\n        {\n            float _3910 = rough * rough;\n            float _3941 = 0.60000002384185791015625 * _3910;\n            base = mix(mix(fa_mesh_fs_params[12].xyz * 0.550000011920928955078125, mix(fa_mesh_fs_params[12].xyz, fa_mesh_fs_params[11].xyz, vec3(pow(clamp(d.y * (1.0 - (0.699999988079071044921875 * _3910)), 0.0, 1.0), 0.550000011920928955078125))), vec3(smoothstep((-0.0500000007450580596923828125) - _3941, 0.0500000007450580596923828125 + _3941, d.y))), ((fa_mesh_fs_params[11].xyz + fa_mesh_fs_params[12].xyz) * 0.5) * 0.800000011920928955078125, vec3(_3910 * 0.60000002384185791015625));\n        }\n        outc = base * _3881;\n    }\n    if (fa_mesh_fs_params[42].w > 0.0)\n    {\n        vec4 param_4 = fa_mesh_fs_params[42];\n        vec4 param_5 = fa_mesh_fs_params[43];\n        vec4 param_6 = fa_mesh_fs_params[44];\n        vec4 param_7 = fa_mesh_fs_params[45];\n        vec4 param_8 = fa_mesh_fs_params[46];\n        vec3 param_9 = d;\n        float param_10 = rough;\n        vec3 _4000 = fa_probe_environment(param_4, param_5, param_6, param_7, param_8, param_9, param_10);\n        outc += (_4000 * fa_mesh_fs_params[42].w);\n    }\n    if (fa_mesh_fs_params[47].w > 0.0)\n    {\n        vec4 param_11 = fa_mesh_fs_params[47];\n        vec4 param_12 = fa_mesh_fs_params[48];\n        vec4 param_13 = fa_mesh_fs_params[49];\n        vec4 param_14 = fa_mesh_fs_params[50];\n        vec4 param_15 = fa_mesh_fs_params[51];\n        vec3 param_16 = d;\n        float param_17 = rough;\n        vec3 _4032 = fa_probe_environment(param_11, param_12, param_13, param_14, param_15, param_16, param_17);\n        outc += (_4032 * fa_mesh_fs_params[47].w);\n    }\n    return outc;\n}\n\nvec3 fa_layers_ibl(FaLayers L, vec3 n, vec3 v, vec3 f0, float roughness)\n{\n    vec3 rn = n;\n    if (L.aniso != 0.0)\n    {\n        vec3 _4678;\n        if (L.aniso >= 0.0)\n        {\n            _4678 = L.b;\n        }\n        else\n        {\n            _4678 = L.t;\n        }\n        rn = normalize(mix(n, cross(cross(_4678, v), _4678), vec3(abs(L.aniso))));\n    }\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05);\n    vec2 _4711 = fa_env_brdf(param, param_1);\n    vec3 param_2 = reflect(-v, rn);\n    float param_3 = roughness;\n    vec3 result = (fa_environment(param_2, param_3) * ((f0 * _4711.x) + (vec3(L.f90) * _4711.y))) * L.base_scale;\n    if (L.sheen_on)\n    {\n        vec3 param_4 = n;\n        float param_5 = L.sheen_rough;\n        result += ((L.sheen * (L.sheen_e * L.keep)) * fa_environment(param_4, param_5));\n    }\n    if (L.coat > 0.0)\n    {\n        float param_6 = L.coat_rough;\n        float param_7 = L.coat_ndv;\n        vec2 _4766 = fa_env_brdf(param_6, param_7);\n        vec3 param_8 = reflect(-v, L.nc);\n        float param_9 = L.coat_rough;\n        result += (fa_environment(param_8, param_9) * (L.coat * ((0.039999999105930328369140625 * _4766.x) + _4766.y)));\n    }\n    return result;\n}\n\nvec3 fa_sky_reflection(vec3 n, vec3 v, vec3 f0, float roughness)\n{\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05);\n    vec2 _4243 = fa_env_brdf(param, param_1);\n    vec3 param_2 = reflect(-v, n);\n    float param_3 = roughness;\n    return fa_environment(param_2, param_3) * ((f0 * _4243.x) + vec3(_4243.y));\n}\n\nvec2 fa_xm_size(int k)\n{\n    return max(floor(fa_mesh_fs_params[24].zw / vec2(exp2(float(k)))), vec2(1.0));\n}\n\nvec2 fa_xm_origin(int k)\n{\n    if (k == 0)\n    {\n        return vec2(0.0);\n    }\n    float y = 0.0;\n    for (int j = 1; j < k; j++)\n    {\n        int param = j;\n        y += fa_xm_size(param).y;\n    }\n    return vec2(fa_mesh_fs_params[24].z, y);\n}\n\nvec3 fa_xm_texel(vec2 size, vec2 origin, vec2 p)\n{\n    return texelFetch(fa_screen_tex_fa_shadow_smp, ivec2(origin + clamp(p, vec2(0.0), size - vec2(1.0))), 0).xyz;\n}\n\nvec3 fa_xm_level(int k, vec2 uv)\n{\n    int param = k;\n    vec2 _5468 = fa_xm_size(param);\n    int param_1 = k;\n    vec2 _5472 = fa_xm_origin(param_1);\n    vec2 _5478 = (uv * _5468) - vec2(0.5);\n    vec2 _5481 = fract(_5478);\n    vec2 _5484 = floor(_5478);\n    vec2 param_2 = _5468;\n    vec2 param_3 = _5472;\n    vec2 param_4 = _5484;\n    vec2 param_5 = _5468;\n    vec2 param_6 = _5472;\n    vec2 param_7 = _5484 + vec2(1.0, 0.0);\n    vec2 param_8 = _5468;\n    vec2 param_9 = _5472;\n    vec2 param_10 = _5484 + vec2(0.0, 1.0);\n    vec2 param_11 = _5468;\n    vec2 param_12 = _5472;\n    vec2 param_13 = _5484 + vec2(1.0);\n    vec3 _5526 = vec3(_5481.x);\n    return mix(mix(fa_xm_texel(param_2, param_3, param_4), fa_xm_texel(param_5, param_6, param_7), _5526), mix(fa_xm_texel(param_8, param_9, param_10), fa_xm_texel(param_11, param_12, param_13), _5526), vec3(_5481.y));\n}\n\nvec3 fa_xm_sample(vec2 uv, float lod)\n{\n    float _5545 = max(fa_mesh_fs_params[31].w - 1.0, 0.0);\n    float _5549 = clamp(lod, 0.0, _5545);\n    int _5553 = int(floor(_5549));\n    int param = _5553;\n    vec2 param_1 = uv;\n    vec3 c = fa_xm_level(param, param_1);\n    float _5563 = float(_5553);\n    float _5564 = _5549 - _5563;\n    bool _5566 = _5564 > 0.001000000047497451305389404296875;\n    bool _5573;\n    if (_5566)\n    {\n        _5573 = _5563 < _5545;\n    }\n    else\n    {\n        _5573 = _5566;\n    }\n    if (_5573)\n    {\n        int param_2 = _5553 + 1;\n        vec2 param_3 = uv;\n        c = mix(c, fa_xm_level(param_2, param_3), vec3(_5564));\n    }\n    return c;\n}\n\nvec3 fa_transmitted(Surface s, vec3 n, vec3 v, float roughness, vec3 f0, float f90, float keep, float tr, inout float blend)\n{\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05);\n    vec2 _5599 = fa_env_brdf(param, param_1);\n    vec3 through = ((vec3(1.0) - clamp((f0 * _5599.x) + (vec3(f90) * _5599.y), vec3(0.0), vec3(1.0))) * s.albedo) * (tr * keep);\n    float _5627 = max(s.thickness, 0.0);\n    bool _5632 = _5627 > 0.0;\n    if ((s.attenuation_distance > 0.0) && _5632)\n    {\n        through *= exp((-((-log(clamp(s.attenuation_color, vec3(9.9999997473787516355514526367188e-05), vec3(1.0)))) / vec3(s.attenuation_distance))) * _5627);\n    }\n    bool _5657 = fa_mesh_fs_params[30].w > 1.5;\n    bool _5664;\n    if (!_5657)\n    {\n        _5664 = fa_mesh_fs_params[30].w < 0.5;\n    }\n    else\n    {\n        _5664 = _5657;\n    }\n    if (_5664)\n    {\n        blend = clamp(dot(through, vec3(0.3333333432674407958984375)), 0.0, 0.980000019073486328125);\n        return vec3(0.0);\n    }\n    vec3 world = fa_world_pos;\n    if (_5632)\n    {\n        world += (refract(-v, n, 1.0 / max(s.ior, 1.0)) * _5627);\n    }\n    vec4 _5699 = vec4(world, 1.0);\n    float _5704 = dot(fa_mesh_fs_params[28], _5699);\n    vec2 uv = vec2(0.5);\n    if (_5704 > 9.9999997473787516355514526367188e-05)\n    {\n        vec2 _5722 = vec2(dot(fa_mesh_fs_params[26], _5699), dot(fa_mesh_fs_params[27], _5699)) / vec2(_5704);\n        float _5730;\n        if (fa_mesh_fs_params[24].y > 0.5)\n        {\n            _5730 = (_5722.y * 0.5) + 0.5;\n        }\n        else\n        {\n            _5730 = 0.5 - (_5722.y * 0.5);\n        }\n        uv = vec2((_5722.x * 0.5) + 0.5, _5730);\n    }\n    vec2 param_2 = clamp(uv, vec2(0.0), vec2(1.0));\n    float param_3 = (clamp(roughness, 0.0, 1.0) * clamp((2.0 * s.ior) - 2.0, 0.0, 1.0)) * max(fa_mesh_fs_params[31].w - 1.0, 0.0);\n    return through * fa_xm_sample(param_2, param_3);\n}\n\nvec3 fa_shadow_debug(vec3 color, vec3 world)\n{\n    if (fa_shadows[27].w < 0.5)\n    {\n        return color;\n    }\n    int _3263 = int(fa_shadows[25].x + 0.5);\n    float _3273 = dot(world - fa_shadows[27].xyz, fa_shadows[28].xyz);\n    vec3 tint_1 = vec3(0.3499999940395355224609375);\n    bool _3278 = _3263 > 0;\n    bool _3287;\n    if (_3278)\n    {\n        int param = _3263 - 1;\n        _3287 = _3273 <= fa_shadow_split_at(param);\n    }\n    else\n    {\n        _3287 = _3278;\n    }\n    if (_3287)\n    {\n        tint_1 = vec3(1.0, 0.1500000059604644775390625, 0.100000001490116119384765625);\n        bool _3293 = _3263 > 1;\n        bool _3300;\n        if (_3293)\n        {\n            _3300 = _3273 > fa_shadows[24].x;\n        }\n        else\n        {\n            _3300 = _3293;\n        }\n        if (_3300)\n        {\n            tint_1 = vec3(0.100000001490116119384765625, 0.89999997615814208984375, 0.20000000298023223876953125);\n        }\n        bool _3306 = _3263 > 2;\n        bool _3313;\n        if (_3306)\n        {\n            _3313 = _3273 > fa_shadows[24].y;\n        }\n        else\n        {\n            _3313 = _3306;\n        }\n        if (_3313)\n        {\n            tint_1 = vec3(0.1500000059604644775390625, 0.300000011920928955078125, 1.0);\n        }\n        bool _3319 = _3263 > 3;\n        bool _3326;\n        if (_3319)\n        {\n            _3326 = _3273 > fa_shadows[24].z;\n        }\n        else\n        {\n            _3326 = _3319;\n        }\n        if (_3326)\n        {\n            tint_1 = vec3(1.0, 0.89999997615814208984375, 0.100000001490116119384765625);\n        }\n    }\n    return mix(color, tint_1, vec3(0.550000011920928955078125));\n}\n\nvoid main()\n{\n    fa_inst_load();\n    vec3 _8622 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _8622 = -_8622;\n    }\n    vec3 _7917 = normalize(fa_mesh_fs_params[0].xyz - fa_world_pos);\n    vec3 param = fa_world_pos;\n    fa_cluster_begin(param);\n    SurfaceInput param_1 = SurfaceInput(fa_world_pos, _8622, fa_world_tangent, fa_uv, fa_vertex_color, _7917, gl_FrontFacing);\n    Surface _7925 = fa_standard_surface(param_1);\n    vec3 _8653 = _7925.albedo;\n    float _8654 = _7925.alpha;\n    vec3 _8655 = _7925.normal;\n    float _8656 = _7925.metallic;\n    float _8657 = _7925.roughness;\n    float _8658 = _7925.occlusion;\n    vec3 _8659 = _7925.emission;\n    float _8660 = _7925.clearcoat;\n    float _8661 = _7925.clearcoat_roughness;\n    vec3 _8662 = _7925.sheen_color;\n    float _8663 = _7925.sheen_roughness;\n    float _8664 = _7925.anisotropy;\n    float _8665 = _7925.anisotropy_rotation;\n    float _8666 = _7925.specular;\n    float _8667 = _7925.ior;\n    vec3 _8668 = _7925.specular_color;\n    float _8669 = _7925.transmission;\n    float _8670 = _7925.thickness;\n    vec3 _8671 = _7925.attenuation_color;\n    float _8672 = _7925.attenuation_distance;\n    SurfaceInput param_2 = SurfaceInput(fa_world_pos, _8622, fa_world_tangent, fa_uv, fa_vertex_color, _7917, gl_FrontFacing);\n    Surface param_3 = _7925;\n    surface(param_2, param_3);\n    _8653 = param_3.albedo;\n    _8654 = param_3.alpha;\n    _8655 = param_3.normal;\n    _8656 = param_3.metallic;\n    _8657 = param_3.roughness;\n    _8658 = param_3.occlusion;\n    _8659 = param_3.emission;\n    _8660 = param_3.clearcoat;\n    _8661 = param_3.clearcoat_roughness;\n    _8662 = param_3.sheen_color;\n    _8663 = param_3.sheen_roughness;\n    _8664 = param_3.anisotropy;\n    _8665 = param_3.anisotropy_rotation;\n    _8666 = param_3.specular;\n    _8667 = param_3.ior;\n    _8668 = param_3.specular_color;\n    _8669 = param_3.transmission;\n    _8670 = param_3.thickness;\n    _8671 = param_3.attenuation_color;\n    _8672 = param_3.attenuation_distance;\n    vec3 param_4 = fa_world_pos;\n    vec3 param_5 = _8622;\n    vec3 param_6 = param_3.albedo;\n    vec3 param_7 = param_3.normal;\n    fa_apply_decals(param_4, param_5, param_6, param_7);\n    _8653 = param_6;\n    _8655 = param_7;\n    float fa_tr_blend = 0.0;\n    vec3 result;\n    if (fa_mesh_fs_params[3].w > 0.5)\n    {\n        result = _8653;\n    }\n    else\n    {\n        vec3 _7965 = normalize(_8655);\n        float _7972 = clamp(_8656, 0.0, 1.0);\n        float _7976 = clamp(_8657, 0.0500000007450580596923828125, 1.0);\n        float _7980 = _7976 * _7976;\n        float _7984 = _7980 * _7980;\n        float _7989 = max(dot(_7965, _7917), 9.9999997473787516355514526367188e-05);\n        float _7995 = 1.0 - _7972;\n        float _7996 = clamp(_8669, 0.0, 1.0) * _7995;\n        vec3 _8005 = (_8653 * _7995) * (1.0 - _7996);\n        vec3 _8012 = mix(vec3(0.039999999105930328369140625), _8653, vec3(_7972));\n        vec3 f0 = _8012;\n        SurfaceInput param_8 = SurfaceInput(fa_world_pos, _8622, fa_world_tangent, fa_uv, fa_vertex_color, _7917, gl_FrontFacing);\n        Surface param_9 = Surface(_8653, _8654, _8655, _8656, _8657, _8658, _8659, _8660, _8661, _8662, _8663, _8664, _8665, _8666, _8667, _8668, _8669, _8670, _8671, _8672);\n        vec3 param_10 = _7965;\n        vec3 param_11 = _7917;\n        float param_12 = _7972;\n        float param_13 = _7976;\n        vec3 param_14 = _8012;\n        FaLayers _8028 = fa_layers_setup(param_8, param_9, param_10, param_11, param_12, param_13, param_14);\n        f0 = param_14;\n        vec3 param_15 = _7965;\n        vec3 lit = (fa_indirect_diffuse(param_15) * _8005) * _8658;\n        if (_8028.on)\n        {\n            lit *= _8028.base_scale;\n        }\n        int _8050 = fa_cl_ndir + fa_cl_local;\n        for (int ln = 0; ln < _8050; ln++)\n        {\n            int param_16 = ln;\n            int _8063 = fa_cl_light(param_16);\n            int param_17 = _8063;\n            if (fa_baked_keep(param_17) <= 0.0)\n            {\n                continue;\n            }\n            int param_18 = _8063;\n            vec3 param_19 = fa_world_pos;\n            vec3 param_20 = _8622;\n            LightSample _8079 = fa_light_shadowed(param_18, param_19, param_20);\n            float _8087 = max(dot(_7965, _8079.direction), 0.0);\n            float _8093 = _8079.attenuation * _8079.shadow;\n            vec3 _8098 = normalize(_8079.direction + _7917);\n            float _8103 = max(dot(_7965, _8098), 0.0);\n            float _8108 = max(dot(_7917, _8098), 0.0);\n            bool _8115;\n            if (fa_light_is_area)\n            {\n                _8115 = !_8028.on;\n            }\n            else\n            {\n                _8115 = fa_light_is_area;\n            }\n            if (_8115)\n            {\n                int param_21 = _8063;\n                vec3 param_22 = fa_world_pos;\n                vec3 param_23 = _7965;\n                vec3 param_24 = _7917;\n                vec3 param_25 = _8005;\n                vec3 param_26 = f0;\n                float param_27 = 1.0;\n                float param_28 = _7976;\n                float param_29 = _7989;\n                float param_30 = _8093;\n                lit += fa_area_shade(param_21, param_22, param_23, param_24, param_25, param_26, param_27, param_28, param_29, param_30);\n            }\n            else\n            {\n                if (fa_light_is_area)\n                {\n                    FaLayers param_31 = _8028;\n                    int param_32 = _8063;\n                    vec3 param_33 = fa_world_pos;\n                    vec3 param_34 = _7965;\n                    vec3 param_35 = _7917;\n                    vec3 param_36 = _8079.direction;\n                    vec3 param_37 = _8005;\n                    vec3 param_38 = f0;\n                    float param_39 = _7976;\n                    float param_40 = _7989;\n                    float param_41 = _8093;\n                    lit += fa_area_layers(param_31, param_32, param_33, param_34, param_35, param_36, param_37, param_38, param_39, param_40, param_41);\n                }\n                else\n                {\n                    if (_8028.on)\n                    {\n                        FaLayers param_42 = _8028;\n                        vec3 param_43 = _8005;\n                        vec3 param_44 = f0;\n                        vec3 param_45 = _7965;\n                        vec3 param_46 = _7917;\n                        vec3 param_47 = _8079.direction;\n                        vec3 param_48 = _8098;\n                        float param_49 = _8087;\n                        float param_50 = _7989;\n                        float param_51 = _8103;\n                        float param_52 = _8108;\n                        float param_53 = _7980;\n                        float param_54 = _7984;\n                        int param_55 = _8063;\n                        lit += (fa_layers_light(param_42, param_43, param_44, param_45, param_46, param_47, param_48, param_49, param_50, param_51, param_52, param_53, param_54) * ((fa_light_rgb(param_55) * fa_light_tint) * _8093));\n                    }\n                    else\n                    {\n                        float _8221 = ((_8103 * _8103) * (_7984 - 1.0)) + 1.0;\n                        int param_56 = _8063;\n                        lit += (((_8005 + (((f0 + ((vec3(1.0) - f0) * pow(1.0 - _8108, 5.0))) * (((_7984 / ((3.1415927410125732421875 * _8221) * _8221)) * (0.5 / max(mix((2.0 * _8087) * _7989, _8087 + _7989, _7980), 9.9999997473787516355514526367188e-05))) * 3.1415927410125732421875)) * step(9.9999997473787516355514526367188e-05, _8087))) * (fa_light_rgb(param_56) * fa_light_tint)) * (_8087 * _8093));\n                    }\n                }\n            }\n        }\n        if (_8028.on)\n        {\n            FaLayers param_57 = _8028;\n            vec3 param_58 = _7965;\n            vec3 param_59 = _7917;\n            vec3 param_60 = f0;\n            float param_61 = _7976;\n            lit += (fa_layers_ibl(param_57, param_58, param_59, param_60, param_61) * _8658);\n        }\n        else\n        {\n            vec3 param_62 = _7965;\n            vec3 param_63 = _7917;\n            vec3 param_64 = f0;\n            float param_65 = _7976;\n            lit += (fa_sky_reflection(param_62, param_63, param_64, param_65) * _8658);\n        }\n        if (_7996 > 0.0)\n        {\n            float _8319;\n            if (_8028.on)\n            {\n                _8319 = _8028.f90;\n            }\n            else\n            {\n                _8319 = 1.0;\n            }\n            float _8327;\n            if (_8028.on)\n            {\n                _8327 = _8028.base_scale;\n            }\n            else\n            {\n                _8327 = 1.0;\n            }\n            Surface param_66 = Surface(_8653, _8654, _8655, _8656, _8657, _8658, _8659, _8660, _8661, _8662, _8663, _8664, _8665, _8666, _8667, _8668, _8669, _8670, _8671, _8672);\n            vec3 param_67 = _7965;\n            vec3 param_68 = _7917;\n            float param_69 = _7976;\n            vec3 param_70 = f0;\n            float param_71 = _8319;\n            float param_72 = _8327;\n            float param_73 = _7996;\n            float param_74 = fa_tr_blend;\n            vec3 _8351 = fa_transmitted(param_66, param_67, param_68, param_69, param_70, param_71, param_72, param_73, param_74);\n            fa_tr_blend = param_74;\n            lit += _8351;\n        }\n        result = lit;\n    }\n    vec3 _8358 = result;\n    vec3 _8359 = _8358 + _8659;\n    result = _8359;\n    vec3 param_75 = _8359;\n    vec3 param_76 = fa_world_pos;\n    result = fa_shadow_debug(param_75, param_76);\n    bool _8368 = fa_mesh_fs_params[7].w > 0.0;\n    bool _8375;\n    if (!_8368)\n    {\n        _8375 = fa_mesh_fs_params[8].y > 0.0;\n    }\n    else\n    {\n        _8375 = _8368;\n    }\n    if (_8375)\n    {\n        vec3 _8384 = fa_world_pos - fa_mesh_fs_params[0].xyz;\n        float _8390 = dot(_8384, fa_mesh_fs_params[9].xyz);\n        bool _8394 = fa_mesh_fs_params[9].w > 0.5;\n        float _8395;\n        if (_8394)\n        {\n            _8395 = _8390;\n        }\n        else\n        {\n            _8395 = length(_8384);\n        }\n        float _8407 = _8395 - fa_mesh_fs_params[8].x;\n        if (_8407 > 0.0)\n        {\n            float _8416 = fa_mesh_fs_params[7].w * _8407;\n            float tau = _8416 * _8416;\n            if (fa_mesh_fs_params[8].y > 0.0)\n            {\n                float _8432;\n                if (_8394)\n                {\n                    _8432 = fa_world_pos.y - (fa_mesh_fs_params[9].y * _8390);\n                }\n                else\n                {\n                    _8432 = fa_mesh_fs_params[0].y;\n                }\n                float _8453 = mix(_8432, fa_world_pos.y, clamp(fa_mesh_fs_params[8].x / _8395, 0.0, 1.0));\n                float _8457 = fa_world_pos.y - _8453;\n                float _8462 = _8453 - fa_mesh_fs_params[8].z;\n                float _8467 = fa_world_pos.y - fa_mesh_fs_params[8].z;\n                bool _8470 = _8462 <= 0.0;\n                bool _8471 = !_8470;\n                bool _8477;\n                if (_8471)\n                {\n                    _8477 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _8477 = _8470;\n                }\n                float _8478;\n                if (_8477)\n                {\n                    _8478 = fa_mesh_fs_params[8].y;\n                }\n                else\n                {\n                    _8478 = fa_mesh_fs_params[8].y * exp(-min(fa_mesh_fs_params[8].w * _8462, 80.0));\n                }\n                bool _8505;\n                if (_8471)\n                {\n                    _8505 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _8505 = _8470;\n                }\n                float _8506;\n                if (_8505)\n                {\n                    _8506 = fa_mesh_fs_params[8].y * _8462;\n                }\n                else\n                {\n                    _8506 = (fa_mesh_fs_params[8].y * (1.0 - exp(-min(fa_mesh_fs_params[8].w * _8462, 80.0)))) / fa_mesh_fs_params[8].w;\n                }\n                bool _8531 = _8467 <= 0.0;\n                bool _8538;\n                if (!_8531)\n                {\n                    _8538 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _8538 = _8531;\n                }\n                float _8539;\n                if (_8538)\n                {\n                    _8539 = fa_mesh_fs_params[8].y * _8467;\n                }\n                else\n                {\n                    _8539 = (fa_mesh_fs_params[8].y * (1.0 - exp(-min(fa_mesh_fs_params[8].w * _8467, 80.0)))) / fa_mesh_fs_params[8].w;\n                }\n                float _8566;\n                if (abs(_8457) < 0.001000000047497451305389404296875)\n                {\n                    _8566 = _8478;\n                }\n                else\n                {\n                    _8566 = (_8539 - _8506) / _8457;\n                }\n                tau += (_8407 * max(_8566, 0.0));\n            }\n            result = mix(result, fa_mesh_fs_params[7].xyz, vec3(clamp(1.0 - exp(-clamp(tau, 0.0, 80.0)), 0.0, 1.0)));\n        }\n    }\n    if (fa_tr_blend > 0.0)\n    {\n        float _8602 = 1.0 - fa_tr_blend;\n        result /= vec3(_8602);\n        _8654 *= _8602;\n    }\n    fa_frag_color = vec4(result, _8654);\n}\n\n",
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
            "inst_name": "_660",
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
            "inst_name": "_2327",
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
            "inst_name": "_6915",
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
      "fs": "#version 430\n\nstruct SurfaceInput\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 vertex_color;\n    vec3 view_dir;\n    bool front_facing;\n};\n\nstruct LightSample\n{\n    vec3 direction;\n    vec3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct Surface\n{\n    vec3 albedo;\n    float alpha;\n    vec3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    vec3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    vec3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    vec3 specular_color;\n    float transmission;\n    float thickness;\n    vec3 attenuation_color;\n    float attenuation_distance;\n};\n\nstruct FaLayers\n{\n    bool on;\n    float f90;\n    float keep;\n    float base_scale;\n    float coat;\n    float coat_rough;\n    float coat_alpha;\n    float coat_a2;\n    vec3 nc;\n    float coat_ndv;\n    bool sheen_on;\n    vec3 sheen;\n    float sheen_rough;\n    float sheen_alpha;\n    float sheen_scale;\n    float sheen_e;\n    float aniso;\n    vec3 t;\n    vec3 b;\n    float at;\n    float ab;\n};\n\nconst float _4343[63] = float[](1.0, 1.0, 1.0, 0.4790000021457672119140625, 0.11699999868869781494140625, 0.01200000010430812835693359375, 0.0, 0.0, 0.0, 1.0, 1.0, 1.0, 0.578000009059906005859375, 0.19300000369548797607421875, 0.0350000001490116119384765625, 0.0030000000260770320892333984375, 0.0, 0.0, 1.0, 1.0, 1.0, 0.6740000247955322265625, 0.3459999859333038330078125, 0.1319999992847442626953125, 0.032999999821186065673828125, 0.0040000001899898052215576171875, 0.0, 0.971000015735626220703125, 0.954999983310699462890625, 0.828999996185302734375, 0.63999998569488525390625, 0.42599999904632568359375, 0.24500000476837158203125, 0.115000002086162567138671875, 0.037000000476837158203125, 0.0030000000260770320892333984375, 0.7469999790191650390625, 0.737999975681304931640625, 0.670000016689300537109375, 0.563000023365020751953125, 0.4309999942779541015625, 0.3039999902248382568359375, 0.1940000057220458984375, 0.1019999980926513671875, 0.0309999994933605194091796875, 0.614000022411346435546875, 0.609000027179718017578125, 0.566999971866607666015625, 0.499000012874603271484375, 0.412000000476837158203125, 0.32400000095367431640625, 0.240999996662139892578125, 0.162000000476837158203125, 0.087999999523162841796875, 0.538999974727630615234375, 0.535000026226043701171875, 0.505999982357025146484375, 0.4569999873638153076171875, 0.393999993801116943359375, 0.328999996185302734375, 0.2660000026226043701171875, 0.203999996185302734375, 0.14200000464916229248046875);\n\nuniform vec4 fa_mesh_fs_params[53];\nuniform vec4 fa_shadows[30];\nuniform vec4 fa_material[1];\nlayout(binding = 0) uniform sampler2D fa_light_tex_fa_shadow_smp;\nlayout(binding = 1) uniform sampler2D fa_tex_fa_smp;\nlayout(binding = 2) uniform sampler2D fa_normal_tex_fa_smp;\nlayout(binding = 3) uniform sampler2D fa_mr_tex_fa_smp;\nlayout(binding = 4) uniform sampler2D fa_occlusion_tex_fa_smp;\nlayout(binding = 5) uniform sampler2D fa_emissive_tex_fa_smp;\nlayout(binding = 6) uniform sampler2D fa_decal_tex_fa_env_smp;\nlayout(binding = 7) uniform sampler2D fa_lightmap_fa_env_smp;\nlayout(binding = 8) uniform sampler2D fa_probe_atlas_fa_env_smp;\nlayout(binding = 9) uniform sampler2D fa_light_atlas_fa_env_smp;\nlayout(binding = 10) uniform sampler2D fa_shadow_tex_fa_shadow_smp;\nlayout(binding = 11) uniform sampler2D fa_screen_tex_fa_shadow_smp;\n\nlayout(location = 2) in vec3 fa_world_pos;\nlayout(location = 7) in vec3 fa_lm;\nlayout(location = 0) flat in vec4 fa_inst_v0;\nlayout(location = 1) flat in vec4 fa_inst_v1;\nlayout(location = 3) in vec3 fa_world_normal;\nlayout(location = 4) in vec4 fa_world_tangent;\nlayout(location = 5) in vec2 fa_uv;\nlayout(location = 6) in vec4 fa_vertex_color;\nlayout(location = 0) out vec4 fa_frag_color;\nvec3 fa_light_tint;\nbool fa_light_is_area;\nint fa_cl_ndir;\nint fa_cl_slot;\nint fa_cl_local;\nfloat raise;\nvec4 tint;\n\nvoid fa_instance_unpack(vec4 fa_d0, vec4 fa_d1, vec4 fa_d2)\n{\n    raise = fa_d0.x;\n    tint = fa_d1;\n}\n\nvoid fa_inst_load()\n{\n    vec4 param = fa_inst_v0;\n    vec4 param_1 = fa_inst_v1;\n    vec4 param_2 = vec4(0.0);\n    fa_instance_unpack(param, param_1, param_2);\n}\n\nvec4 fa_light_texel(int t)\n{\n    return texelFetch(fa_light_tex_fa_shadow_smp, ivec2(t & 1023, t >> 10), 0);\n}\n\nvec4 fa_cluster_texel(vec3 world_pos)\n{\n    bool _1598 = fa_mesh_fs_params[19].x < 0.0;\n    bool _1605;\n    if (!_1598)\n    {\n        _1605 = fa_mesh_fs_params[19].w < 1.0;\n    }\n    else\n    {\n        _1605 = _1598;\n    }\n    bool _1613;\n    if (!_1605)\n    {\n        _1613 = fa_mesh_fs_params[18].x < 1.0;\n    }\n    else\n    {\n        _1613 = _1605;\n    }\n    bool _1620;\n    if (!_1613)\n    {\n        _1620 = fa_mesh_fs_params[18].y < 1.0;\n    }\n    else\n    {\n        _1620 = _1613;\n    }\n    bool _1627;\n    if (!_1620)\n    {\n        _1627 = fa_mesh_fs_params[19].y < 1.0;\n    }\n    else\n    {\n        _1627 = _1620;\n    }\n    if (_1627)\n    {\n        return vec4(0.0);\n    }\n    vec4 _1637 = vec4(world_pos, 1.0);\n    float _1643 = dot(fa_mesh_fs_params[16], _1637);\n    if (!(_1643 > 9.9999999747524270787835121154785e-07))\n    {\n        return vec4(0.0);\n    }\n    vec2 _1665 = vec2(dot(fa_mesh_fs_params[14], _1637), dot(fa_mesh_fs_params[15], _1637)) / vec2(_1643);\n    int _1669 = int(fa_mesh_fs_params[18].x);\n    int _1673 = int(fa_mesh_fs_params[18].y);\n    int param = (int(fa_mesh_fs_params[19].x) + (((clamp(int(floor(log2(max(dot(fa_mesh_fs_params[17].xyz, world_pos) + fa_mesh_fs_params[17].w, fa_mesh_fs_params[18].w) / fa_mesh_fs_params[18].w) * fa_mesh_fs_params[18].z)), 0, int(fa_mesh_fs_params[19].y) - 1) * _1673) + clamp(int(floor(((_1665.y * 0.5) + 0.5) * fa_mesh_fs_params[18].y)), 0, _1673 - 1)) * _1669)) + clamp(int(floor(((_1665.x * 0.5) + 0.5) * fa_mesh_fs_params[18].x)), 0, _1669 - 1);\n    return fa_light_texel(param);\n}\n\nivec2 fa_cluster_lookup(vec3 world_pos)\n{\n    vec3 param = world_pos;\n    vec4 _1749 = fa_cluster_texel(param);\n    return ivec2(int(_1749.x), int(_1749.y));\n}\n\nvoid fa_cluster_begin(vec3 world_pos)\n{\n    fa_cl_ndir = int(fa_mesh_fs_params[19].z);\n    vec3 param = world_pos;\n    ivec2 _5804 = fa_cluster_lookup(param);\n    fa_cl_slot = _5804.x;\n    fa_cl_local = _5804.y;\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nvec3 fa_linear_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_tex_fix(inout vec3 c, float mode)\n{\n    if (mode > 1.5)\n    {\n        vec3 param = c;\n        vec3 _6967 = fa_linear_to_srgb(param);\n        c = _6967;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            vec3 param_1 = c;\n            vec3 _6975 = fa_srgb_to_linear(param_1);\n            c = _6975;\n        }\n    }\n    return c;\n}\n\nvec3 fa_tangent_normal(SurfaceInput i, vec3 m)\n{\n    vec3 _542;\n    if (i.front_facing)\n    {\n        _542 = i.world_normal;\n    }\n    else\n    {\n        _542 = -i.world_normal;\n    }\n    vec3 _566 = normalize(i.world_tangent.xyz - (_542 * dot(_542, i.world_tangent.xyz)));\n    vec3 _593 = normalize(((_566 * m.x) + ((cross(_542, _566) * i.world_tangent.w) * m.y)) + (_542 * m.z));\n    vec3 _596;\n    if (i.front_facing)\n    {\n        _596 = _593;\n    }\n    else\n    {\n        _596 = -_593;\n    }\n    return _596;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    vec4 base_t = texture(fa_tex_fa_smp, i.uv);\n    float param = fa_mesh_fs_params[6].w;\n    float param_1 = 1.0;\n    vec3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    vec3 _7006 = fa_tex_fix(param_2, param_3);\n    vec4 _9199 = base_t;\n    _9199.x = _7006.x;\n    _9199.y = _7006.y;\n    _9199.z = _7006.z;\n    base_t = _9199;\n    vec4 _7020 = (_9199 * fa_mesh_fs_params[2]) * i.vertex_color;\n    vec3 _8983 = i.world_normal;\n    if (fa_mesh_fs_params[6].z > 0.5)\n    {\n        float param_4 = fa_mesh_fs_params[6].w;\n        float param_5 = 16.0;\n        vec3 param_6 = texture(fa_normal_tex_fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        vec3 _7052 = fa_tex_fix(param_6, param_7);\n        vec3 _7055 = (_7052 * 2.0) - vec3(1.0);\n        vec2 _7060 = _7055.xy * fa_mesh_fs_params[6].x;\n        vec3 _9207 = _7055;\n        _9207.x = _7060.x;\n        _9207.y = _7060.y;\n        SurfaceInput param_8 = i;\n        vec3 param_9 = _9207;\n        _8983 = fa_tangent_normal(param_8, param_9);\n    }\n    vec4 mrt = texture(fa_mr_tex_fa_smp, i.uv);\n    float param_10 = fa_mesh_fs_params[6].w;\n    float param_11 = 64.0;\n    vec3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    vec3 _7088 = fa_tex_fix(param_12, param_13);\n    vec4 _9210 = mrt;\n    _9210.x = _7088.x;\n    _9210.y = _7088.y;\n    _9210.z = _7088.z;\n    mrt = _9210;\n    vec4 _7116 = texture(fa_occlusion_tex_fa_smp, i.uv);\n    float param_14 = fa_mesh_fs_params[6].w;\n    float param_15 = 256.0;\n    vec3 param_16 = _7116.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    vec3 _7127 = fa_tex_fix(param_16, param_17);\n    float param_18 = fa_mesh_fs_params[6].w;\n    float param_19 = 4.0;\n    vec3 param_20 = texture(fa_emissive_tex_fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    vec3 _7157 = fa_tex_fix(param_20, param_21);\n    float _8988 = fa_mesh_fs_params[20].x;\n    float _8989 = fa_mesh_fs_params[20].y;\n    float _8992 = fa_mesh_fs_params[20].z;\n    float _8991 = fa_mesh_fs_params[21].w;\n    float _8994 = fa_mesh_fs_params[22].x;\n    if (fa_mesh_fs_params[22].z > 0.5)\n    {\n        if (mod(fa_mesh_fs_params[22].z, 2.0) > 0.5)\n        {\n            _8988 *= _7127.y;\n            _8989 *= _7127.z;\n            _8991 *= _7116.w;\n        }\n        if (fa_mesh_fs_params[22].z > 1.5)\n        {\n            _8992 *= mrt.x;\n            _8994 *= mrt.w;\n        }\n    }\n    return Surface(_7020.xyz, _7020.w, _8983, clamp(fa_mesh_fs_params[5].x * _7088.z, 0.0, 1.0), clamp(fa_mesh_fs_params[5].y * _7088.y, 0.0500000007450580596923828125, 1.0), 1.0 + (fa_mesh_fs_params[6].y * (_7127.x - 1.0)), fa_mesh_fs_params[3].xyz + (fa_mesh_fs_params[4].xyz * _7157), _8988, _8989, fa_mesh_fs_params[21].xyz, _8991, _8992, fa_mesh_fs_params[20].w, _8994, fa_mesh_fs_params[22].y, fa_mesh_fs_params[23].xyz, fa_mesh_fs_params[30].x, fa_mesh_fs_params[30].y, fa_mesh_fs_params[31].xyz, fa_mesh_fs_params[30].z);\n}\n\nvoid surface(SurfaceInput i, inout Surface s)\n{\n    s.emission += ((tint.xyz * tint.w) * fa_material[0].x);\n}\n\nvec4 fa_decal_tile(vec4 rect, vec2 uv, vec2 atlas, vec2 ddx, vec2 ddy)\n{\n    vec2 _1829 = rect.zw - rect.xy;\n    vec2 _1833 = _1829 * atlas;\n    vec2 _1837 = ddx * _1833;\n    vec2 _1841 = ddy * _1833;\n    return textureLod(fa_decal_tex_fa_env_smp, rect.xy + (clamp(uv, vec2(0.0), vec2(1.0)) * _1829), clamp(0.5 * log2(max(max(dot(_1837, _1837), dot(_1841, _1841)), 9.9999999392252902907785028219223e-09)), 0.0, 4.0));\n}\n\nvec3 fa_dc_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_dc_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvoid fa_apply_decals(vec3 world_pos, vec3 geo_normal, inout vec3 albedo, inout vec3 normal)\n{\n    bool _1874 = fa_mesh_fs_params[10].y < 0.5;\n    bool _1881;\n    if (!_1874)\n    {\n        _1881 = fa_mesh_fs_params[10].w < 0.5;\n    }\n    else\n    {\n        _1881 = _1874;\n    }\n    if (_1881)\n    {\n        return;\n    }\n    vec3 _1887 = dFdx(world_pos);\n    vec3 _1890 = dFdy(world_pos);\n    vec3 param = world_pos;\n    vec4 _1894 = fa_cluster_texel(param);\n    int _1898 = int(_1894.w);\n    if (_1898 < 1)\n    {\n        return;\n    }\n    int _1908 = int(fa_mesh_fs_params[10].y + 0.5);\n    int param_1 = _1908;\n    vec4 _1912 = fa_light_texel(param_1);\n    vec2 _1915 = _1912.yz;\n    int _1919 = int(_1912.w);\n    int param_2 = _1908 + 1;\n    vec4 _1924 = fa_light_texel(param_2);\n    float _1925 = _1924.x;\n    int _1931 = int(fa_mesh_fs_params[10].w + 0.5) - 1;\n    int _1935 = int(_1894.z);\n    vec3 _2200;\n    for (int k = 0; k < _1898; k++)\n    {\n        int _1948 = _1935 + k;\n        int param_3 = _1919 + (_1948 >> 2);\n        int _1965 = (_1908 + 2) + (int(fa_light_texel(param_3)[_1948 & 3]) * 7);\n        int param_4 = _1965 + 6;\n        vec4 _1970 = fa_light_texel(param_4);\n        if (((int(_1970.w + 0.5) >> _1931) & 1) == 0)\n        {\n            continue;\n        }\n        int param_5 = _1965;\n        vec4 _1985 = fa_light_texel(param_5);\n        int param_6 = _1965 + 1;\n        vec4 _1990 = fa_light_texel(param_6);\n        int param_7 = _1965 + 2;\n        vec4 _1995 = fa_light_texel(param_7);\n        vec3 _1998 = _1985.xyz;\n        float _2003 = dot(_1998, world_pos) + _1985.w;\n        vec3 _2005 = _1990.xyz;\n        float _2010 = dot(_2005, world_pos) + _1990.w;\n        vec3 _2012 = _1995.xyz;\n        float _2017 = dot(_2012, world_pos) + _1995.w;\n        bool _2022 = abs(_2003) > 0.5;\n        bool _2030;\n        if (!_2022)\n        {\n            _2030 = abs(_2010) > 0.5;\n        }\n        else\n        {\n            _2030 = _2022;\n        }\n        bool _2038;\n        if (!_2030)\n        {\n            _2038 = abs(_2017) > 0.5;\n        }\n        else\n        {\n            _2038 = _2030;\n        }\n        if (_2038)\n        {\n            continue;\n        }\n        float _2053 = clamp(dot(geo_normal, normalize(_2012)) * _1970.z, 0.0, 1.0);\n        if (_2053 <= 0.0)\n        {\n            continue;\n        }\n        float _2073 = (clamp((0.5 - abs(_2017)) * 10.0, 0.0, 1.0) * _2053) * _1970.x;\n        vec2 _2081 = vec2(_2003 + 0.5, 0.5 - _2010);\n        vec2 _2091 = vec2(dot(_1998, _1887), dot(_2005, _1887));\n        vec2 _2101 = vec2(dot(_1998, _1890), dot(_2005, _1890));\n        int param_8 = _1965 + 5;\n        vec4 _2106 = fa_light_texel(param_8);\n        int param_9 = _1965 + 3;\n        vec4 _2111 = fa_light_texel(param_9);\n        int param_10 = _1965 + 4;\n        vec4 _2116 = fa_light_texel(param_10);\n        float tex_a = 1.0;\n        vec3 col = _2106.xyz;\n        bool _2126 = _2111.z > _2111.x;\n        if (_2126)\n        {\n            vec4 param_11 = _2111;\n            vec2 param_12 = _2081;\n            vec2 param_13 = _1915;\n            vec2 param_14 = _2091;\n            vec2 param_15 = _2101;\n            vec4 tx = fa_decal_tile(param_11, param_12, param_13, param_14, param_15);\n            if ((_1925 > 0.5) && (_1925 < 1.5))\n            {\n                vec3 param_16 = tx.xyz;\n                vec3 _2152 = fa_dc_to_linear(param_16);\n                vec4 _9071 = tx;\n                _9071.x = _2152.x;\n                _9071.y = _2152.y;\n                _9071.z = _2152.z;\n                tx = _9071;\n            }\n            col *= tx.xyz;\n            tex_a = tx.w;\n        }\n        albedo = mix(albedo, col, vec3(clamp((_2073 * tex_a) * _2106.w, 0.0, 1.0)));\n        if (_2116.z > _2116.x)\n        {\n            vec4 param_17 = _2116;\n            vec2 param_18 = _2081;\n            vec2 param_19 = _1915;\n            vec2 param_20 = _2091;\n            vec2 param_21 = _2101;\n            vec4 _2196 = fa_decal_tile(param_17, param_18, param_19, param_20, param_21);\n            if (_1925 > 1.5)\n            {\n                vec3 param_22 = _2196.xyz;\n                vec3 _2206 = fa_dc_to_srgb(param_22);\n                _2200 = _2206;\n            }\n            else\n            {\n                _2200 = _2196.xyz;\n            }\n            vec3 _2215 = (_2200 * 2.0) - vec3(1.0);\n            vec2 _2220 = _2215.xy * _1970.y;\n            vec3 _2242 = (normalize(_1998) * _2220.x) + (normalize(_2005) * _2220.y);\n            vec3 _2245 = normalize(normal);\n            normal = normalize(mix(_2245, normalize((_2245 * max(_2215.z, 0.0500000007450580596923828125)) + (_2242 - (_2245 * dot(_2245, _2242)))), vec3(clamp(_2073 * (_2126 ? tex_a : 1.0), 0.0, 1.0))));\n        }\n    }\n}\n\nfloat fa_sheen_albedo(float ndv, float rough)\n{\n    float _4269 = min(sqrt(max(rough - 0.100000001490116119384765625, 0.0) * 1.111111164093017578125) * 6.0, 5.999000072479248046875);\n    float _4276 = min(sqrt(clamp(ndv, 0.0, 1.0)) * 8.0, 7.999000072479248046875);\n    int _4279 = int(_4269);\n    int _4282 = int(_4276);\n    float _4292 = _4276 - float(_4282);\n    int _4347 = (_4279 * 9) + _4282;\n    int _4367 = ((_4279 + 1) * 9) + _4282;\n    return mix(mix(_4343[_4347], _4343[_4347 + 1], _4292), mix(_4343[_4367], _4343[_4367 + 1], _4292), _4269 - float(_4279));\n}\n\nFaLayers fa_layers_setup(SurfaceInput i, Surface s, vec3 n, vec3 v, float metallic, float roughness, inout vec3 f0)\n{\n    bool _8906 = false;\n    float _8907 = 1.0;\n    float _8908 = 1.0;\n    float _8909 = 1.0;\n    float _8910 = 0.0;\n    float _8911 = 0.0;\n    float _8912 = 0.0;\n    float _8913 = 0.0;\n    float _8915 = 1.0;\n    bool _8916 = false;\n    vec3 _8917 = vec3(0.0);\n    float _8918 = 1.0;\n    float _8919 = 1.0;\n    float _8920 = 1.0;\n    float _8921 = 0.0;\n    float _8922 = 0.0;\n    vec3 _8923 = vec3(1.0, 0.0, 0.0);\n    vec3 _8924 = vec3(0.0, 0.0, 1.0);\n    float _8925 = 1.0;\n    float _8926 = 1.0;\n    float _4418 = clamp(s.specular, 0.0, 1.0);\n    float _4422 = clamp(s.ior, 1.0, 3.0);\n    bool _4427 = (_4418 != 1.0) || (_4422 != 1.5);\n    bool _4436;\n    if (!_4427)\n    {\n        _4436 = any(notEqual(s.specular_color, vec3(1.0)));\n    }\n    else\n    {\n        _4436 = _4427;\n    }\n    if (_4436)\n    {\n        float _4444 = (_4422 - 1.0) / (_4422 + 1.0);\n        f0 = mix(min(vec3(_4444 * _4444) * max(s.specular_color, vec3(0.0)), vec3(1.0)) * _4418, s.albedo, vec3(metallic));\n        _8907 = mix(_4418, 1.0, metallic);\n        _8906 = true;\n    }\n    float _4471 = clamp(s.clearcoat, 0.0, 1.0);\n    if (_4471 > 0.0)\n    {\n        float _4479 = clamp(s.clearcoat_roughness, 0.0500000007450580596923828125, 1.0);\n        _8910 = _4471;\n        _8911 = _4479;\n        float _4486 = _4479 * _4479;\n        _8912 = _4486;\n        _8913 = _4486 * _4486;\n        float _4498 = max(dot(i.world_normal, v), 9.9999997473787516355514526367188e-05);\n        _8915 = _4498;\n        _8908 = 1.0 - (_4471 * (0.039999999105930328369140625 + (0.959999978542327880859375 * pow(clamp(1.0 - _4498, 0.0, 1.0), 5.0))));\n        _8906 = true;\n    }\n    vec3 _4517 = max(s.sheen_color, vec3(0.0));\n    float _4526 = max(_4517.x, max(_4517.y, _4517.z));\n    if (_4526 > 0.0)\n    {\n        float _4534 = clamp(s.sheen_roughness, 0.100000001490116119384765625, 1.0);\n        _8916 = true;\n        _8917 = _4517;\n        _8918 = _4534;\n        _8919 = _4534 * _4534;\n        float param = max(dot(n, v), 9.9999997473787516355514526367188e-05);\n        float param_1 = _4534;\n        float _4551 = fa_sheen_albedo(param, param_1);\n        _8921 = _4551;\n        _8920 = 1.0 - min(_4526 * _4551, 1.0);\n        _8906 = true;\n    }\n    _8909 = _8908 * _8920;\n    float _4570 = clamp(s.anisotropy, -1.0, 1.0);\n    if (_4570 != 0.0)\n    {\n        vec3 _4585 = i.world_tangent.xyz - (n * dot(n, i.world_tangent.xyz));\n        vec3 t = _4585;\n        if (dot(_4585, _4585) < 9.9999999392252902907785028219223e-09)\n        {\n            bvec3 _4597 = bvec3(abs(n.y) < 0.9900000095367431640625);\n            t = cross(vec3(_4597.x ? vec3(0.0, 1.0, 0.0).x : vec3(1.0, 0.0, 0.0).x, _4597.y ? vec3(0.0, 1.0, 0.0).y : vec3(1.0, 0.0, 0.0).y, _4597.z ? vec3(0.0, 1.0, 0.0).z : vec3(1.0, 0.0, 0.0).z), n);\n        }\n        vec3 _4601 = t;\n        vec3 _4602 = normalize(_4601);\n        t = _4602;\n        vec3 _4627 = normalize((_4602 * cos(s.anisotropy_rotation)) + ((cross(n, _4602) * ((i.world_tangent.w < 0.0) ? (-1.0) : 1.0)) * sin(s.anisotropy_rotation)));\n        _8923 = _4627;\n        _8924 = cross(n, _4627);\n        float _4637 = roughness * roughness;\n        float _4643 = mix(_4637, 1.0, _4570 * _4570);\n        bool _4645 = _4570 > 0.0;\n        _8925 = _4645 ? _4643 : _4637;\n        _8926 = _4645 ? _4637 : _4643;\n        _8922 = _4570;\n        _8906 = true;\n    }\n    return FaLayers(_8906, _8907, _8908, _8909, _8910, _8911, _8912, _8913, i.world_normal, _8915, _8916, _8917, _8918, _8919, _8920, _8921, _8922, _8923, _8924, _8925, _8926);\n}\n\nvec3 fa_sh_eval(vec3 c[9], vec3 n)\n{\n    vec3 _3440 = max((((c[0] * 0.2820948064327239990234375) + (((c[1] * (0.3257350027561187744140625 * n.y)) + (c[2] * (0.3257350027561187744140625 * n.z))) + (c[3] * (0.3257350027561187744140625 * n.x)))) + (((c[4] * ((0.2731371223926544189453125 * n.x) * n.y)) + (c[5] * ((0.2731371223926544189453125 * n.y) * n.z))) + (c[6] * (0.078847892582416534423828125 * (((3.0 * n.z) * n.z) - 1.0))))) + ((c[7] * ((0.2731371223926544189453125 * n.x) * n.z)) + (c[8] * (0.13656856119632720947265625 * ((n.x * n.x) - (n.y * n.y))))), vec3(0.0));\n    return _3440;\n}\n\nvec2 fa_atlas_size()\n{\n    return vec2(textureSize(fa_probe_atlas_fa_env_smp, 0));\n}\n\nvec4 fa_gi_fetch(vec2 texel)\n{\n    return textureLod(fa_probe_atlas_fa_env_smp, texel / fa_atlas_size(), 0.0);\n}\n\nvec2 fa_oct_encode(vec3 d)\n{\n    vec3 _3460 = d / vec3(max((abs(d.x) + abs(d.y)) + abs(d.z), 9.9999999600419720025001879548654e-13));\n    float _3463 = _3460.x;\n    float _3465 = _3460.z;\n    vec2 e = vec2(_3463, _3465);\n    if (_3460.y < 0.0)\n    {\n        e = vec2((1.0 - abs(_3465)) * ((_3463 < 0.0) ? (-1.0) : 1.0), (1.0 - abs(_3463)) * ((_3465 < 0.0) ? (-1.0) : 1.0));\n    }\n    return e;\n}\n\nvec3 fa_gi_grid(int rec, vec3 n, vec3 v, out float cover)\n{\n    cover = 0.0;\n    int param = rec;\n    vec4 _7267 = fa_light_texel(param);\n    int param_1 = rec + 1;\n    vec4 _7272 = fa_light_texel(param_1);\n    int param_2 = rec + 2;\n    vec4 _7277 = fa_light_texel(param_2);\n    int param_3 = rec + 3;\n    vec4 _7282 = fa_light_texel(param_3);\n    bool _7285 = _7282.z < 0.5;\n    bool _7293;\n    if (!_7285)\n    {\n        _7293 = fa_atlas_size().y < 1155.0;\n    }\n    else\n    {\n        _7293 = _7285;\n    }\n    if (_7293)\n    {\n        return vec3(0.0);\n    }\n    float _7300 = max(_7267.w, 9.9999997473787516355514526367188e-05);\n    vec3 _7303 = _7272.xyz;\n    vec3 _7307 = _7267.xyz;\n    vec3 _7311 = (fa_world_pos - _7307) / vec3(_7300);\n    vec3 _7320 = min(_7311 + vec3(0.5), (_7303 - vec3(0.5)) - _7311);\n    float _7329 = min(_7320.x, min(_7320.y, _7320.z));\n    if (!(_7329 > 0.0))\n    {\n        return vec3(0.0);\n    }\n    vec3 _7344 = _7303 - vec3(1.0);\n    vec3 _7345 = clamp(_7311, vec3(0.0), _7344);\n    vec3 _7353 = min(floor(_7345), max(_7303 - vec3(2.0), vec3(0.0)));\n    vec3 _7357 = _7345 - _7353;\n    vec3 _7368 = fa_world_pos + (((n * 0.800000011920928955078125) + (v * 0.20000000298023223876953125)) * (0.20000000298023223876953125 * _7300));\n    int _7373 = int(_7277.y + 0.5);\n    vec3 sh[9];\n    for (int k = 0; k < 9; k++)\n    {\n        sh[k] = vec3(0.0);\n    }\n    float wsum = 0.0;\n    int _7391 = int(_7282.w);\n    int _7392 = 8 + _7391;\n    int _7397 = 9 + _7391;\n    float _7424;\n    float _7437;\n    float _7451;\n    for (int k_1 = 0; k_1 < _7392; k_1++)\n    {\n        float _7410 = float(k_1 & 1);\n        float _7414 = float((k_1 >> 1) & 1);\n        float _7418 = float((k_1 >> 2) & 1);\n        if (_7410 > 0.5)\n        {\n            _7424 = _7357.x;\n        }\n        else\n        {\n            _7424 = 1.0 - _7357.x;\n        }\n        if (_7414 > 0.5)\n        {\n            _7437 = _7357.y;\n        }\n        else\n        {\n            _7437 = 1.0 - _7357.y;\n        }\n        if (_7418 > 0.5)\n        {\n            _7451 = _7357.z;\n        }\n        else\n        {\n            _7451 = 1.0 - _7357.z;\n        }\n        float _7461 = (_7424 * _7437) * _7451;\n        if (!(_7461 > 0.0))\n        {\n            continue;\n        }\n        vec3 _7474 = min(_7353 + vec3(_7410, _7414, _7418), _7344);\n        int _7494 = int(((_7277.x + _7474.x) + (_7272.x * (_7474.y + (_7272.y * _7474.z)))) + 0.5);\n        vec2 _7509 = vec2(float(_7494 % _7373) * 10.0, 1024.0 + (float(_7494 / _7373) * 11.0));\n        vec2 param_4 = _7509 + vec2(9.5, 10.5);\n        vec4 _7517 = fa_gi_fetch(param_4);\n        bool _7520 = _7517.y < 0.5;\n        bool _7529;\n        if (!_7520)\n        {\n            _7529 = _7517.x > _7282.y;\n        }\n        else\n        {\n            _7529 = _7520;\n        }\n        if (_7529)\n        {\n            continue;\n        }\n        vec3 _7541 = _7368 - (_7307 + (_7474 * _7300));\n        float _7544 = length(_7541);\n        vec3 _7550 = _7541 / vec3(max(_7544, 9.9999997473787516355514526367188e-05));\n        float _7560 = max(9.9999997473787516355514526367188e-05, (dot(-_7550, n) + 1.0) * 0.5);\n        float w = _7461 * (_7560 * _7560);\n        vec3 param_5 = _7550;\n        vec2 param_6 = (_7509 + vec2(1.0)) + (((fa_oct_encode(param_5) * 0.5) + vec2(0.5)) * 8.0);\n        vec4 _7579 = fa_gi_fetch(param_6);\n        float _7586 = _7544 / max(_7277.z, 9.9999997473787516355514526367188e-05);\n        float _7589 = _7579.x;\n        if (_7586 > _7589)\n        {\n            float _7602 = max(_7579.y - (_7589 * _7589), 0.0);\n            float _7607 = _7586 - _7589;\n            float _7616 = _7602 / max(_7602 + (_7607 * _7607), 9.9999999600419720025001879548654e-13);\n            w *= ((_7616 * _7616) * _7616);\n        }\n        if (!(w > 0.0))\n        {\n            continue;\n        }\n        for (int c = 0; c < _7397; c++)\n        {\n            vec2 param_7 = _7509 + vec2(float(c) + 0.5, 10.5);\n            sh[c] += (fa_gi_fetch(param_7).xyz * w);\n        }\n        wsum += w;\n    }\n    if (!(wsum > 9.9999997473787516355514526367188e-06))\n    {\n        return vec3(0.0);\n    }\n    for (int c_1 = 0; c_1 < 9; c_1++)\n    {\n        sh[c_1] /= vec3(wsum);\n    }\n    cover = smoothstep(0.0, 1.0, clamp(_7329 * 2.0, 0.0, 1.0)) * smoothstep(0.0, 0.0199999995529651641845703125, wsum);\n    float _7697;\n    if (fa_mesh_fs_params[52].z > 0.5)\n    {\n        _7697 = _7282.x;\n    }\n    else\n    {\n        _7697 = 1.0;\n    }\n    vec3 param_8[9] = sh;\n    vec3 param_9 = n;\n    return fa_sh_eval(param_8, param_9) * (_7277.w * _7697);\n}\n\nvec3 fa_gi_light(vec3 n, inout float left)\n{\n    left = 1.0;\n    vec3 acc = vec3(0.0);\n    vec3 _7721 = normalize(fa_mesh_fs_params[0].xyz - fa_world_pos);\n    int _7726 = int(fa_mesh_fs_params[52].x + 0.5);\n    int _7731 = int(fa_mesh_fs_params[52].y + 0.5);\n    float param_3;\n    for (int k = 0; (k < _7731) && (k < 8); k++)\n    {\n        int param = _7726 + (4 * k);\n        vec3 param_1 = n;\n        vec3 param_2 = _7721;\n        vec3 _7756 = fa_gi_grid(param, param_1, param_2, param_3);\n        float _7761 = param_3 * left;\n        acc += (_7756 * _7761);\n        left -= _7761;\n        if (left < 0.001000000047497451305389404296875)\n        {\n            left = 0.0;\n            break;\n        }\n    }\n    return acc;\n}\n\nvec3 fa_probe_sh_coef(vec2 origin, float res, int k)\n{\n    vec3 v = textureLod(fa_probe_atlas_fa_env_smp, (origin + vec2(float(k) + 0.5, res + 2.5)) / fa_atlas_size(), 0.0).xyz;\n    if (fa_mesh_fs_params[41].y > 0.5)\n    {\n        v = (v - vec3(0.5)) * 8.0;\n    }\n    return v;\n}\n\nvec3 fa_ambient_light(vec3 n)\n{\n    float _4050 = (1.0 - fa_mesh_fs_params[42].w) - fa_mesh_fs_params[47].w;\n    vec3 amb = vec3(0.0);\n    bool _4055 = fa_mesh_fs_params[11].w > 0.5;\n    vec3 c[9];\n    for (int k = 0; k < 9; k++)\n    {\n        c[k] = vec3(0.0);\n    }\n    if (_4050 > 0.0005000000237487256526947021484375)\n    {\n        if (_4055)\n        {\n            for (int k_1 = 0; k_1 < 9; k_1++)\n            {\n                vec2 param = fa_mesh_fs_params[41].zw;\n                float param_1 = 128.0;\n                int param_2 = k_1;\n                c[k_1] = fa_probe_sh_coef(param, param_1, param_2) * _4050;\n            }\n        }\n        else\n        {\n            amb = fa_mesh_fs_params[1].xyz * _4050;\n        }\n    }\n    bool _4106 = fa_mesh_fs_params[42].w > 0.0;\n    if (_4106)\n    {\n        for (int k_2 = 0; k_2 < 9; k_2++)\n        {\n            vec2 param_3 = fa_mesh_fs_params[42].xy;\n            float param_4 = fa_mesh_fs_params[42].z;\n            int param_5 = k_2;\n            c[k_2] += (fa_probe_sh_coef(param_3, param_4, param_5) * fa_mesh_fs_params[42].w);\n        }\n    }\n    bool _4137 = fa_mesh_fs_params[47].w > 0.0;\n    if (_4137)\n    {\n        for (int k_3 = 0; k_3 < 9; k_3++)\n        {\n            vec2 param_6 = fa_mesh_fs_params[47].xy;\n            float param_7 = fa_mesh_fs_params[47].z;\n            int param_8 = k_3;\n            c[k_3] += (fa_probe_sh_coef(param_6, param_7, param_8) * fa_mesh_fs_params[47].w);\n        }\n    }\n    if ((_4055 || _4106) || _4137)\n    {\n        vec3 param_9[9] = c;\n        vec3 param_10 = n;\n        amb += fa_sh_eval(param_9, param_10);\n    }\n    return amb;\n}\n\nvec3 fa_realtime_or_ambient(vec3 n)\n{\n    if (fa_mesh_fs_params[52].y > 0.5)\n    {\n        vec3 param = n;\n        float param_1;\n        vec3 _7790 = fa_gi_light(param, param_1);\n        if (param_1 < 0.999000012874603271484375)\n        {\n            vec3 _7798;\n            if (param_1 > 0.0)\n            {\n                vec3 param_2 = n;\n                _7798 = _7790 + (fa_ambient_light(param_2) * param_1);\n            }\n            else\n            {\n                _7798 = _7790;\n            }\n            return _7798;\n        }\n    }\n    vec3 param_3 = n;\n    return fa_ambient_light(param_3);\n}\n\nvec3 fa_indirect_diffuse(vec3 n)\n{\n    if (fa_lm.z > 0.5)\n    {\n        return textureLod(fa_lightmap_fa_env_smp, fa_lm.xy, 0.0).xyz;\n    }\n    if (fa_mesh_fs_params[32].w > 0.0)\n    {\n        vec3 c[9];\n        for (int k = 0; k < 9; k++)\n        {\n            c[k] = fa_mesh_fs_params[k * 1 + 32].xyz;\n        }\n        vec3 param[9] = c;\n        vec3 param_1 = n;\n        vec3 _7860 = fa_sh_eval(param, param_1);\n        if (fa_mesh_fs_params[32].w >= 1.0)\n        {\n            return _7860;\n        }\n        vec3 param_2 = n;\n        return mix(fa_realtime_or_ambient(param_2), _7860, vec3(clamp(fa_mesh_fs_params[32].w, 0.0, 1.0)));\n    }\n    vec3 param_3 = n;\n    return fa_realtime_or_ambient(param_3);\n}\n\nint fa_cluster_index(int slot, int n)\n{\n    int param = (int(fa_mesh_fs_params[19].x) + int(fa_mesh_fs_params[19].w)) + ((slot + n) >> 2);\n    vec4 t = fa_light_texel(param);\n    return int(t[(slot + n) & 3]);\n}\n\nint fa_cl_light(int n)\n{\n    if (n < fa_cl_ndir)\n    {\n        return n;\n    }\n    int param = fa_cl_slot;\n    int param_1 = n - fa_cl_ndir;\n    return fa_cluster_index(param, param_1);\n}\n\nint fa_light_base(int li)\n{\n    return li * ((fa_mesh_fs_params[1].w > 4.5) ? 8 : 4);\n}\n\nbool fa_light_baked(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 3;\n    return fa_light_texel(param_1).w > 0.5;\n}\n\nfloat fa_baked_keep(int li)\n{\n    float _5774;\n    if (fa_lm.z > 0.5)\n    {\n        _5774 = 0.0;\n    }\n    else\n    {\n        _5774 = 1.0 - clamp(fa_mesh_fs_params[32].w, 0.0, 1.0);\n    }\n    bool _5785 = _5774 < 1.0;\n    bool _5791;\n    if (_5785)\n    {\n        int param = li;\n        _5791 = fa_light_baked(param);\n    }\n    else\n    {\n        _5791 = _5785;\n    }\n    return _5791 ? _5774 : 1.0;\n}\n\nfloat fa_light_type(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 1;\n    return fa_light_texel(param_1).w;\n}\n\nvec4 fa_atlas_fetch(vec2 texel)\n{\n    return textureLod(fa_light_atlas_fa_env_smp, texel / vec2(textureSize(fa_light_atlas_fa_env_smp, 0)), 0.0);\n}\n\nvec3 fa_cookie_sample(vec2 tile_origin, vec2 uv)\n{\n    vec2 param = (tile_origin + vec2(1.0)) + (clamp(uv, vec2(0.0), vec2(1.0)) * 254.0);\n    return fa_atlas_fetch(param).xyz;\n}\n\nvec3 fa_area_point(vec3 c, vec3 axis, vec3 ru, vec3 uu, float hx, float hy, float shape, vec3 p, vec3 r)\n{\n    bool _847 = dot(r, r) > 0.5;\n    if (shape > 1.5)\n    {\n        vec3 _860 = (c - (ru * hx)) - p;\n        vec3 _866 = ru * (2.0 * hx);\n        float _872 = max(dot(_866, _866), 9.9999999392252902907785028219223e-09);\n        float _876 = dot(_860, _866);\n        float t = clamp((-_876) / _872, 0.0, 1.0);\n        if (_847)\n        {\n            float _891 = dot(r, _866);\n            float _897 = _872 - (_891 * _891);\n            if (abs(_897) > (9.9999997473787516355514526367188e-06 * _872))\n            {\n                t = clamp(((dot(r, _860) * _891) - _876) / _897, 0.0, 1.0);\n            }\n        }\n        return (p + _860) + (_866 * t);\n    }\n    vec3 q = p;\n    float _929 = dot(r, axis);\n    bool _937;\n    if (_847)\n    {\n        _937 = abs(_929) > 9.9999997473787516355514526367188e-05;\n    }\n    else\n    {\n        _937 = _847;\n    }\n    if (_937)\n    {\n        float _947 = dot(c - p, axis) / _929;\n        if (_947 > 0.0)\n        {\n            q = p + (r * _947);\n        }\n    }\n    vec3 _960 = q - c;\n    vec2 xy = vec2(dot(_960, ru), dot(_960, uu));\n    if (shape > 0.5)\n    {\n        float _975 = length(xy);\n        if (_975 > hx)\n        {\n            xy *= (hx / _975);\n        }\n    }\n    else\n    {\n        xy = clamp(xy, vec2(-hx, -hy), vec2(hx, hy));\n    }\n    return (c + (ru * xy.x)) + (uu * xy.y);\n}\n\nint fa_cube_face(vec3 d)\n{\n    vec3 _608 = abs(d);\n    float _610 = _608.x;\n    float _612 = _608.y;\n    bool _613 = _610 >= _612;\n    bool _621;\n    if (_613)\n    {\n        _621 = _610 >= _608.z;\n    }\n    else\n    {\n        _621 = _613;\n    }\n    int _622;\n    if (_621)\n    {\n        _622 = (d.x > 0.0) ? 0 : 1;\n    }\n    else\n    {\n        int _637;\n        if (_612 >= _608.z)\n        {\n            _637 = (d.y > 0.0) ? 2 : 3;\n        }\n        else\n        {\n            _637 = (d.z > 0.0) ? 4 : 5;\n        }\n        _622 = _637;\n    }\n    return _622;\n}\n\nvoid fa_cube_face_basis(int f, out vec3 fwd, out vec3 up)\n{\n    if (f == 0)\n    {\n        fwd = vec3(1.0, 0.0, 0.0);\n        up = vec3(0.0, 1.0, 0.0);\n    }\n    else\n    {\n        if (f == 1)\n        {\n            fwd = vec3(-1.0, 0.0, 0.0);\n            up = vec3(0.0, 1.0, 0.0);\n        }\n        else\n        {\n            if (f == 2)\n            {\n                fwd = vec3(0.0, 1.0, 0.0);\n                up = vec3(0.0, 0.0, 1.0);\n            }\n            else\n            {\n                if (f == 3)\n                {\n                    fwd = vec3(0.0, -1.0, 0.0);\n                    up = vec3(0.0, 0.0, -1.0);\n                }\n                else\n                {\n                    if (f == 4)\n                    {\n                        fwd = vec3(0.0, 0.0, 1.0);\n                        up = vec3(0.0, 1.0, 0.0);\n                    }\n                    else\n                    {\n                        fwd = vec3(0.0, 0.0, -1.0);\n                        up = vec3(0.0, 1.0, 0.0);\n                    }\n                }\n            }\n        }\n    }\n}\n\nfloat fa_ies_sample(vec2 tile_origin, vec3 d, vec3 axis, vec3 right, vec3 up)\n{\n    float _767 = dot(d, right);\n    float _771 = dot(d, up);\n    float _782;\n    if (((_767 * _767) + (_771 * _771)) > 1.0000000133514319600180897396058e-10)\n    {\n        _782 = atan(_771, _767) * 0.15915493667125701904296875;\n    }\n    else\n    {\n        _782 = 0.0;\n    }\n    vec2 param = tile_origin + vec2(1.0 + ((_782 - floor(_782)) * 64.0), 1.0 + (acos(clamp(dot(d, axis), -1.0, 1.0)) * 10.18591594696044921875));\n    return fa_atlas_fetch(param).x;\n}\n\nLightSample fa_light_sample_n(int li, vec3 world_pos, vec3 n)\n{\n    int param = li;\n    int _1013 = fa_light_base(param);\n    bool _1017 = fa_mesh_fs_params[1].w > 4.5;\n    int param_1 = _1013;\n    vec4 _1021 = fa_light_texel(param_1);\n    int param_2 = _1013 + 1;\n    vec4 _1026 = fa_light_texel(param_2);\n    float _1029 = _1026.w;\n    float atten = 1.0;\n    float dist = 0.0;\n    fa_light_tint = vec3(1.0);\n    bool _1041 = _1017 && (_1029 > 2.5);\n    fa_light_is_area = _1041;\n    bool _1043 = _1029 < 0.5;\n    vec3 l;\n    if (_1043)\n    {\n        l = normalize(_1021.xyz);\n        if (_1017)\n        {\n            int param_3 = _1013 + 6;\n            vec4 _1057 = fa_light_texel(param_3);\n            if (_1057.z > 0.5)\n            {\n                int param_4 = _1013 + 4;\n                vec4 _1067 = fa_light_texel(param_4);\n                int param_5 = _1013 + 5;\n                vec4 _1072 = fa_light_texel(param_5);\n                vec2 param_6 = _1057.xy;\n                vec2 param_7 = fract(vec2(dot(world_pos, _1067.xyz) * _1067.w, (-dot(world_pos, _1072.xyz)) * _1072.w) + vec2(0.5));\n                fa_light_tint = fa_cookie_sample(param_6, param_7);\n            }\n        }\n    }\n    else\n    {\n        vec3 _1102 = _1021.xyz;\n        vec3 _1104 = _1102 - world_pos;\n        vec3 to_light = _1104;\n        float _1107 = length(_1104);\n        float reach = _1107;\n        bool front = true;\n        if (_1041)\n        {\n            int param_8 = _1013 + 7;\n            reach = max(_1107 - fa_light_texel(param_8).w, 0.0);\n            int param_9 = _1013 + 4;\n            vec4 _1131 = fa_light_texel(param_9);\n            int param_10 = _1013 + 5;\n            vec4 _1136 = fa_light_texel(param_10);\n            int param_11 = _1013 + 6;\n            vec4 _1141 = fa_light_texel(param_11);\n            float _1142 = _1141.w;\n            int param_12 = _1013 + 2;\n            vec3 _1149 = normalize(fa_light_texel(param_12).xyz);\n            bool _1151 = _1142 > 1.5;\n            bool _1159;\n            if (!_1151)\n            {\n                _1159 = dot(_1149, to_light) < 0.0;\n            }\n            else\n            {\n                _1159 = _1151;\n            }\n            front = _1159;\n            vec3 r = vec3(0.0);\n            vec3 _1168 = fa_mesh_fs_params[0].xyz - world_pos;\n            bool _1172 = dot(n, n) > 0.5;\n            bool _1180;\n            if (_1172)\n            {\n                _1180 = dot(_1168, _1168) > 9.9999999600419720025001879548654e-13;\n            }\n            else\n            {\n                _1180 = _1172;\n            }\n            if (_1180)\n            {\n                r = reflect(-normalize(_1168), normalize(n));\n            }\n            vec3 param_13 = _1102;\n            vec3 param_14 = _1149;\n            vec3 param_15 = _1131.xyz;\n            vec3 param_16 = _1136.xyz;\n            float param_17 = _1131.w;\n            float param_18 = _1136.w;\n            float param_19 = _1142;\n            vec3 param_20 = world_pos;\n            vec3 param_21 = r;\n            to_light = fa_area_point(param_13, param_14, param_15, param_16, param_17, param_18, param_19, param_20, param_21) - world_pos;\n        }\n        float _1216 = length(to_light);\n        dist = _1216;\n        l = to_light / vec3(max(_1216, 9.9999997473787516355514526367188e-05));\n        float _1230 = reach / max(_1021.w, 0.001000000047497451305389404296875);\n        float _1236 = clamp(1.0 - (_1230 * _1230), 0.0, 1.0);\n        float _1238;\n        if (front)\n        {\n            _1238 = _1236 * _1236;\n        }\n        else\n        {\n            _1238 = 0.0;\n        }\n        atten = _1238;\n        bool _1249 = _1029 < 2.5;\n        if ((_1029 > 1.5) && _1249)\n        {\n            int param_22 = _1013 + 2;\n            vec4 _1257 = fa_light_texel(param_22);\n            float _1267 = _1257.w;\n            int param_23 = _1013 + 3;\n            vec4 _1272 = fa_light_texel(param_23);\n            float _1273 = _1272.x;\n            float cos_inner = _1273;\n            if (_1273 > 1.5)\n            {\n                cos_inner = mix(_1267, 1.0, 0.25);\n            }\n            atten *= smoothstep(_1267, cos_inner, dot(-l, normalize(_1257.xyz)));\n        }\n        if (_1017 && (_1029 < 1.5))\n        {\n            int param_24 = _1013 + 6;\n            vec4 _1297 = fa_light_texel(param_24);\n            if (_1297.z > 0.5)\n            {\n                vec3 _1305 = -to_light;\n                int param_25 = _1013 + 4;\n                int param_26 = _1013 + 5;\n                vec3 _1319 = fa_light_texel(param_25).xyz;\n                vec3 _1323 = fa_light_texel(param_26).xyz;\n                vec3 _1332 = vec3(dot(_1305, _1319), dot(_1305, _1323), dot(_1305, cross(_1319, _1323)));\n                vec3 param_27 = _1332;\n                int _1336 = fa_cube_face(param_27);\n                int param_28 = _1336;\n                vec3 param_29;\n                vec3 param_30;\n                fa_cube_face_basis(param_28, param_29, param_30);\n                vec2 _1363 = vec2(dot(_1332, cross(param_29, param_30)), dot(_1332, param_30)) / vec2(max(dot(_1332, param_29), 9.9999997473787516355514526367188e-05));\n                int _1367 = _1336 / 3;\n                vec2 param_31 = _1297.xy + (vec2(float(_1336 - (_1367 * 3)), float(_1367)) * 256.0);\n                vec2 param_32 = vec2(0.5 + (0.5 * _1363.x), 0.5 - (0.5 * _1363.y));\n                fa_light_tint = fa_cookie_sample(param_31, param_32);\n            }\n            int param_33 = _1013 + 7;\n            vec4 _1397 = fa_light_texel(param_33);\n            if (_1397.z > 0.5)\n            {\n                int param_34 = _1013 + 2;\n                int param_35 = _1013 + 4;\n                int param_36 = _1013 + 5;\n                vec2 param_37 = _1397.xy;\n                vec3 param_38 = -l;\n                vec3 param_39 = normalize(fa_light_texel(param_34).xyz);\n                vec3 param_40 = fa_light_texel(param_35).xyz;\n                vec3 param_41 = fa_light_texel(param_36).xyz;\n                atten *= fa_ies_sample(param_37, param_38, param_39, param_40, param_41);\n            }\n        }\n        else\n        {\n            if (_1017 && _1249)\n            {\n                int param_42 = _1013 + 6;\n                vec4 _1444 = fa_light_texel(param_42);\n                int param_43 = _1013 + 7;\n                vec4 _1449 = fa_light_texel(param_43);\n                bool _1452 = _1444.z > 0.5;\n                bool _1459;\n                if (!_1452)\n                {\n                    _1459 = _1449.z > 0.5;\n                }\n                else\n                {\n                    _1459 = _1452;\n                }\n                if (_1459)\n                {\n                    int param_44 = _1013 + 2;\n                    vec4 _1466 = fa_light_texel(param_44);\n                    vec3 _1470 = normalize(_1466.xyz);\n                    int param_45 = _1013 + 4;\n                    vec4 _1475 = fa_light_texel(param_45);\n                    int param_46 = _1013 + 5;\n                    vec4 _1480 = fa_light_texel(param_46);\n                    if (_1452)\n                    {\n                        vec3 _1488 = -to_light;\n                        float _1495 = _1466.w;\n                        float _1511 = 0.5 / max(dot(_1488, _1470) * (sqrt(max(1.0 - (_1495 * _1495), 0.0)) / max(_1495, 0.001000000047497451305389404296875)), 9.9999997473787516355514526367188e-05);\n                        vec2 param_47 = _1444.xy;\n                        vec2 param_48 = vec2(0.5 + (dot(_1488, _1475.xyz) * _1511), 0.5 - (dot(_1488, _1480.xyz) * _1511));\n                        fa_light_tint = fa_cookie_sample(param_47, param_48);\n                    }\n                    if (_1449.z > 0.5)\n                    {\n                        vec2 param_49 = _1449.xy;\n                        vec3 param_50 = -l;\n                        vec3 param_51 = _1470;\n                        vec3 param_52 = _1475.xyz;\n                        vec3 param_53 = _1480.xyz;\n                        atten *= fa_ies_sample(param_49, param_50, param_51, param_52, param_53);\n                    }\n                }\n            }\n        }\n    }\n    vec3 _8894 = _1026.xyz * atten;\n    if (_1017)\n    {\n        _8894 *= fa_light_tint;\n    }\n    int _1580;\n    if (_1043)\n    {\n        _1580 = 0;\n    }\n    else\n    {\n        _1580 = ((_1029 > 1.5) && (_1029 < 2.5)) ? 2 : 1;\n    }\n    return LightSample(l, _8894, atten, 1.0, dist, _1580);\n}\n\nfloat fa_shadow_split_at(int i)\n{\n    float _2317;\n    if (i == 0)\n    {\n        _2317 = fa_shadows[24].x;\n    }\n    else\n    {\n        float _2333;\n        if (i == 1)\n        {\n            _2333 = fa_shadows[24].y;\n        }\n        else\n        {\n            float _2341;\n            if (i == 2)\n            {\n                _2341 = fa_shadows[24].z;\n            }\n            else\n            {\n                _2341 = fa_shadows[24].w;\n            }\n            _2333 = _2341;\n        }\n        _2317 = _2333;\n    }\n    return _2317;\n}\n\nfloat fa_shadow_depth(inout vec2 uv, vec4 rect)\n{\n    uv = clamp(uv, rect.xy, rect.zw);\n    return textureLod(fa_shadow_tex_fa_shadow_smp, uv, 0.0).x;\n}\n\nfloat fa_shadow_fetch(vec2 uv, vec4 rect, vec3 conv)\n{\n    vec2 param = uv;\n    vec4 param_1 = rect;\n    float _2374 = fa_shadow_depth(param, param_1);\n    float _2378;\n    if (conv.x < 0.5)\n    {\n        _2378 = _2374;\n    }\n    else\n    {\n        _2378 = (conv.y * conv.z) / (conv.z - (_2374 * (conv.z - conv.y)));\n    }\n    return _2378;\n}\n\nfloat fa_shadow_noise()\n{\n    return fract(52.98291778564453125 * fract(dot(gl_FragCoord.xy, vec2(0.067110560834407806396484375, 0.005837149918079376220703125))));\n}\n\nvec2 fa_shadow_vogel(int k, int n, float phi)\n{\n    float _2305 = (float(k) * 2.3999631404876708984375) + phi;\n    return vec2(cos(_2305), sin(_2305)) * sqrt((float(k) + 0.5) / float(n));\n}\n\nfloat fa_shadow_filter(vec2 uv, vec4 rect, float zr, float texel_m, float unit, float reach, float plane, vec3 conv, int mode, float k)\n{\n    if (mode == 1)\n    {\n        vec2 param = uv;\n        vec4 param_1 = rect;\n        vec3 param_2 = conv;\n        return float(zr <= fa_shadow_fetch(param, param_1, param_2));\n    }\n    float _2424 = fa_shadow_noise() * 6.283185482025146484375;\n    float radius = 1.5;\n    if (mode == 2)\n    {\n        float _2433;\n        if (k < 0.0)\n        {\n            _2433 = (-k) / max(zr, 0.100000001490116119384765625);\n        }\n        else\n        {\n            _2433 = k;\n        }\n        float _2453 = clamp((_2433 * reach) / texel_m, 3.0, 12.0);\n        float sum = 0.0;\n        float cnt = 0.0;\n        for (int i = 0; i < 16; i++)\n        {\n            int param_3 = i;\n            int param_4 = 16;\n            float param_5 = _2424;\n            vec2 _2472 = fa_shadow_vogel(param_3, param_4, param_5) * _2453;\n            vec2 param_6 = uv + (_2472 * fa_shadows[26].zw);\n            vec4 param_7 = rect;\n            vec3 param_8 = conv;\n            float _2484 = fa_shadow_fetch(param_6, param_7, param_8);\n            if (_2484 < (zr - (length(_2472) * plane)))\n            {\n                sum += _2484;\n                cnt += 1.0;\n            }\n        }\n        if (cnt < 0.5)\n        {\n            return 1.0;\n        }\n        float _2510 = sum / cnt;\n        float _2520;\n        if (k < 0.0)\n        {\n            _2520 = (-k) / max(_2510, 0.0500000007450580596923828125);\n        }\n        else\n        {\n            _2520 = k;\n        }\n        radius = clamp(((max(zr - _2510, 0.0) * unit) * _2520) / texel_m, 1.5, 16.0);\n    }\n    float lit = 0.0;\n    int _2542 = (mode == 2) ? 24 : 16;\n    for (int i_1 = 0; i_1 < _2542; i_1++)\n    {\n        int param_9 = i_1;\n        int param_10 = _2542;\n        float param_11 = _2424;\n        vec2 _2561 = fa_shadow_vogel(param_9, param_10, param_11) * radius;\n        vec2 param_12 = uv + (_2561 * fa_shadows[26].zw);\n        vec4 param_13 = rect;\n        vec3 param_14 = conv;\n        lit += float((zr - (length(_2561) * plane)) <= fa_shadow_fetch(param_12, param_13, param_14));\n    }\n    return lit / float(_2542);\n}\n\nfloat fa_shadow_cascade(int ci, vec3 world, vec3 n, vec3 l)\n{\n    float _2603 = max(fa_shadows[ci * 1 + 20].y, 0.001000000047497451305389404296875);\n    float _2608 = clamp(dot(n, l), 0.0, 1.0);\n    float _2614 = sqrt(1.0 - (_2608 * _2608));\n    float _2621 = min(_2614 / max(_2608, 0.20000000298023223876953125), 4.0);\n    float _2626;\n    if (fa_shadows[26].y > 0.0)\n    {\n        _2626 = fa_shadows[26].y;\n    }\n    else\n    {\n        _2626 = 1.5 * fa_shadows[ci * 1 + 20].x;\n    }\n    vec4 _2651 = mat4(fa_shadows[ci * 4 + 0], fa_shadows[ci * 4 + 1], fa_shadows[ci * 4 + 2], fa_shadows[ci * 4 + 3]) * vec4(world + (n * (_2626 * _2614)), 1.0);\n    float _2658 = _2651.x;\n    bool _2661 = _2658 < fa_shadows[ci * 1 + 16].x;\n    bool _2670;\n    if (!_2661)\n    {\n        _2670 = _2658 > fa_shadows[ci * 1 + 16].z;\n    }\n    else\n    {\n        _2670 = _2661;\n    }\n    bool _2679;\n    if (!_2670)\n    {\n        _2679 = _2651.y < fa_shadows[ci * 1 + 16].y;\n    }\n    else\n    {\n        _2679 = _2670;\n    }\n    bool _2688;\n    if (!_2679)\n    {\n        _2688 = _2651.y > fa_shadows[ci * 1 + 16].w;\n    }\n    else\n    {\n        _2688 = _2679;\n    }\n    bool _2695;\n    if (!_2688)\n    {\n        _2695 = _2651.z > 1.0;\n    }\n    else\n    {\n        _2695 = _2688;\n    }\n    if (_2695)\n    {\n        return -1.0;\n    }\n    float _2703;\n    if (fa_shadows[26].x > 0.0)\n    {\n        _2703 = fa_shadows[26].x;\n    }\n    else\n    {\n        _2703 = 1.5 * fa_shadows[ci * 1 + 20].x;\n    }\n    vec2 param = _2651.xy;\n    vec4 param_1 = fa_shadows[ci * 1 + 16];\n    float param_2 = _2651.z - ((_2703 * (1.0 + (0.5 * _2621))) / _2603);\n    float param_3 = fa_shadows[ci * 1 + 20].x;\n    float param_4 = _2603;\n    float param_5 = _2603 * 0.25;\n    float param_6 = ((fa_shadows[ci * 1 + 20].x * min(_2621, 3.0)) * 0.5) / _2603;\n    vec3 param_7 = vec3(0.0);\n    int param_8 = int(fa_shadows[25].z + 0.5);\n    float param_9 = fa_shadows[25].w;\n    return fa_shadow_filter(param, param_1, param_2, param_3, param_4, param_5, param_6, param_7, param_8, param_9);\n}\n\nfloat fa_shadow_sun(vec3 world, vec3 n, vec3 l)\n{\n    if (fa_mesh_fs_params[5].z < 0.5)\n    {\n        return 1.0;\n    }\n    int _3081 = int(fa_shadows[25].x + 0.5);\n    if (_3081 < 1)\n    {\n        return 1.0;\n    }\n    float _3096 = dot(world - fa_shadows[27].xyz, fa_shadows[28].xyz);\n    int param = _3081 - 1;\n    if (_3096 > fa_shadow_split_at(param))\n    {\n        return 1.0;\n    }\n    int ci = 0;\n    bool _3108 = _3081 > 1;\n    bool _3115;\n    if (_3108)\n    {\n        _3115 = _3096 > fa_shadows[24].x;\n    }\n    else\n    {\n        _3115 = _3108;\n    }\n    if (_3115)\n    {\n        ci = 1;\n    }\n    bool _3119 = _3081 > 2;\n    bool _3126;\n    if (_3119)\n    {\n        _3126 = _3096 > fa_shadows[24].y;\n    }\n    else\n    {\n        _3126 = _3119;\n    }\n    if (_3126)\n    {\n        ci = 2;\n    }\n    bool _3130 = _3081 > 3;\n    bool _3137;\n    if (_3130)\n    {\n        _3137 = _3096 > fa_shadows[24].z;\n    }\n    else\n    {\n        _3137 = _3130;\n    }\n    if (_3137)\n    {\n        ci = 3;\n    }\n    float s = -1.0;\n    for (int k = 0; k < 4; k++)\n    {\n        if (ci >= _3081)\n        {\n            break;\n        }\n        int param_1 = ci;\n        vec3 param_2 = world;\n        vec3 param_3 = n;\n        vec3 param_4 = l;\n        float _3163 = fa_shadow_cascade(param_1, param_2, param_3, param_4);\n        s = _3163;\n        if (_3163 >= 0.0)\n        {\n            break;\n        }\n        ci++;\n    }\n    if (s < 0.0)\n    {\n        return 1.0;\n    }\n    if (fa_shadows[25].y > 0.0)\n    {\n        float _3188;\n        if (ci > 0)\n        {\n            int param_5 = ci - 1;\n            _3188 = fa_shadow_split_at(param_5);\n        }\n        else\n        {\n            _3188 = fa_shadows[28].w;\n        }\n        int param_6 = ci;\n        float _3207 = fa_shadows[25].y * max(fa_shadow_split_at(param_6) - _3188, 9.9999997473787516355514526367188e-05);\n        int param_7 = ci;\n        float _3218 = clamp((_3096 - (fa_shadow_split_at(param_7) - _3207)) / _3207, 0.0, 1.0);\n        if (_3218 > 0.0)\n        {\n            float s2 = 1.0;\n            if ((ci + 1) < _3081)\n            {\n                int param_8 = ci + 1;\n                vec3 param_9 = world;\n                vec3 param_10 = n;\n                vec3 param_11 = l;\n                float _3239 = fa_shadow_cascade(param_8, param_9, param_10, param_11);\n                s2 = _3239;\n                if (_3239 < 0.0)\n                {\n                    s2 = s;\n                }\n            }\n            s = mix(s, s2, _3218);\n        }\n    }\n    return s;\n}\n\nfloat fa_shadow_factor(vec3 n, vec3 l)\n{\n    vec3 param = fa_world_pos;\n    vec3 param_1 = n;\n    vec3 param_2 = l;\n    return fa_shadow_sun(param, param_1, param_2);\n}\n\nfloat fa_shadow_local(int li, vec3 lpos, vec3 world, vec3 n, vec3 l)\n{\n    bool _2761 = fa_mesh_fs_params[5].z < 0.5;\n    bool _2768;\n    if (!_2761)\n    {\n        _2768 = fa_shadows[29].x < 0.5;\n    }\n    else\n    {\n        _2768 = _2761;\n    }\n    if (_2768)\n    {\n        return 1.0;\n    }\n    int param = (int(fa_shadows[29].x + 0.5) - 1) + li;\n    vec4 _2781 = fa_light_texel(param);\n    float _2782 = _2781.x;\n    if (_2782 < 0.0)\n    {\n        return 1.0;\n    }\n    int _2791 = int(_2782 + 0.5);\n    int param_1 = _2791;\n    vec4 _2795 = fa_light_texel(param_1);\n    int param_2 = _2791 + 1;\n    vec4 _2800 = fa_light_texel(param_2);\n    float fade = 1.0;\n    float _2803 = _2795.y;\n    if (_2803 > 0.0)\n    {\n        float _2820 = 1.0 - smoothstep(0.75 * _2803, _2803, length(world - fa_shadows[27].xyz));\n        fade = _2820;\n        if (_2820 <= 0.0)\n        {\n            return 1.0;\n        }\n    }\n    int face = 0;\n    if (_2795.x > 1.5)\n    {\n        vec3 param_3 = world - lpos;\n        face = fa_cube_face(param_3);\n    }\n    int _2844 = (_2791 + 2) + (face * 6);\n    int param_4 = _2844;\n    int param_5 = _2844 + 1;\n    int param_6 = _2844 + 3;\n    vec4 _2858 = fa_light_texel(param_6);\n    int param_7 = _2844 + 4;\n    vec4 _2863 = fa_light_texel(param_7);\n    int param_8 = _2844 + 5;\n    vec4 _2868 = fa_light_texel(param_8);\n    float _2880 = _2868.x * max(dot(_2858, vec4(world, 1.0)), 0.001000000047497451305389404296875);\n    float _2885 = clamp(dot(n, l), 0.0, 1.0);\n    float _2908 = clamp(dot(n, _2858.xyz), -1.0, 1.0);\n    float _2927 = min(sqrt(1.0 - (_2908 * _2908)) / max(abs(dot(n, world - lpos)) / max(dot(_2858, vec4(world, 1.0)), 0.001000000047497451305389404296875), 0.20000000298023223876953125), 4.0);\n    float _2930 = _2800.y;\n    float _2932;\n    if (_2930 > 0.0)\n    {\n        _2932 = _2930;\n    }\n    else\n    {\n        _2932 = 1.5 * _2880;\n    }\n    vec4 _2952 = vec4(world + (n * (_2932 * sqrt(1.0 - (_2885 * _2885)))), 1.0);\n    float _2956 = dot(_2858, _2952);\n    float _2959 = _2868.y;\n    if (_2956 < _2959)\n    {\n        return 1.0;\n    }\n    vec2 _2974 = vec2(dot(fa_light_texel(param_4), _2952), dot(fa_light_texel(param_5), _2952)) / vec2(_2956);\n    float _2976 = _2974.x;\n    bool _2979 = _2976 < _2863.x;\n    bool _2988;\n    if (!_2979)\n    {\n        _2988 = _2976 > _2863.z;\n    }\n    else\n    {\n        _2988 = _2979;\n    }\n    bool _2997;\n    if (!_2988)\n    {\n        _2997 = _2974.y < _2863.y;\n    }\n    else\n    {\n        _2997 = _2988;\n    }\n    bool _3006;\n    if (!_2997)\n    {\n        _3006 = _2974.y > _2863.w;\n    }\n    else\n    {\n        _3006 = _2997;\n    }\n    if (_3006)\n    {\n        return 1.0;\n    }\n    float _3012 = _2800.x;\n    float _3014;\n    if (_3012 > 0.0)\n    {\n        _3014 = _3012;\n    }\n    else\n    {\n        _3014 = 1.5 * _2880;\n    }\n    vec2 param_9 = _2974;\n    vec4 param_10 = _2863;\n    float param_11 = _2956 - (_3014 * (1.0 + (0.5 * _2927)));\n    float param_12 = _2880;\n    float param_13 = 1.0;\n    float param_14 = _2868.z * 0.25;\n    float param_15 = (_2880 * min(_2927, 3.0)) * 0.5;\n    vec3 param_16 = vec3(1.0, _2959, _2868.z);\n    int param_17 = int(_2795.z + 0.5);\n    float param_18 = _2795.w;\n    return mix(1.0, fa_shadow_filter(param_9, param_10, param_11, param_12, param_13, param_14, param_15, param_16, param_17, param_18), fade);\n}\n\nfloat fa_contact_shadow(int li, vec3 world, vec3 gn, vec3 l, float dist)\n{\n    bool _5155 = fa_mesh_fs_params[24].x < 0.5;\n    bool _5162;\n    if (!_5155)\n    {\n        _5162 = fa_shadows[29].x < 0.5;\n    }\n    else\n    {\n        _5162 = _5155;\n    }\n    if (_5162)\n    {\n        return 1.0;\n    }\n    int param = (int(fa_shadows[29].x + 0.5) - 1) + li;\n    vec4 _5175 = fa_light_texel(param);\n    float _5176 = _5175.y;\n    float len = _5176;\n    if (_5176 <= 0.0)\n    {\n        return 1.0;\n    }\n    float _5188 = length(world - fa_mesh_fs_params[0].xyz);\n    float _5198 = 1.0 - smoothstep(0.5 * fa_mesh_fs_params[25].x, fa_mesh_fs_params[25].x, _5188);\n    if (_5198 <= 0.0)\n    {\n        return 1.0;\n    }\n    float _5204 = len;\n    float _5207 = min(_5204, 0.89999997615814208984375 * dist);\n    len = _5207;\n    float _5212 = 0.004999999888241291046142578125 + (0.0030000000260770320892333984375 * _5188);\n    float _5217 = _5212 + (0.5 * _5207);\n    vec3 _5223 = world + (gn * _5212);\n    float _5225 = fa_shadow_noise();\n    float occ = 0.0;\n    float _5289;\n    for (int k = 0; k < 12; k++)\n    {\n        float _5240 = (float(k) + _5225) * 0.083333335816860198974609375;\n        vec3 _5248 = _5223 + (l * (_5240 * len));\n        vec4 _5254 = vec4(_5248, 1.0);\n        float _5260 = dot(fa_mesh_fs_params[28], _5254);\n        if (_5260 < 9.9999997473787516355514526367188e-05)\n        {\n            break;\n        }\n        vec2 _5280 = vec2(dot(fa_mesh_fs_params[26], _5254), dot(fa_mesh_fs_params[27], _5254)) / vec2(_5260);\n        float _5284 = _5280.x * 0.5;\n        float _5285 = _5284 + 0.5;\n        if (fa_mesh_fs_params[24].y > 0.5)\n        {\n            _5289 = (_5280.y * 0.5) + 0.5;\n        }\n        else\n        {\n            _5289 = 0.5 - (_5280.y * 0.5);\n        }\n        bool _5305 = _5285 < 0.0;\n        bool _5312;\n        if (!_5305)\n        {\n            _5312 = _5285 >= 1.0;\n        }\n        else\n        {\n            _5312 = _5305;\n        }\n        bool _5319;\n        if (!_5312)\n        {\n            _5319 = _5289 < 0.0;\n        }\n        else\n        {\n            _5319 = _5312;\n        }\n        bool _5326;\n        if (!_5319)\n        {\n            _5326 = _5289 >= 1.0;\n        }\n        else\n        {\n            _5326 = _5319;\n        }\n        if (_5326)\n        {\n            break;\n        }\n        vec4 _5345 = texelFetch(fa_screen_tex_fa_shadow_smp, ivec2(vec2(_5285, _5289) * fa_mesh_fs_params[24].zw), 0);\n        if (_5345.w < 0.5)\n        {\n            continue;\n        }\n        float _5364 = (dot(fa_mesh_fs_params[29].xyz, _5248) + fa_mesh_fs_params[29].w) - _5345.x;\n        if ((_5364 > _5212) && (_5364 < _5217))\n        {\n            occ = max(occ, (1.0 - (_5240 * _5240)) * smoothstep(0.0, 0.0500000007450580596923828125, min(min(_5285, 0.5 - _5284), min(_5289, 1.0 - _5289))));\n        }\n    }\n    return 1.0 - (occ * _5198);\n}\n\nLightSample fa_light_shadowed(int li, vec3 world_pos, vec3 gn)\n{\n    int param = li;\n    float _5830 = fa_baked_keep(param);\n    if (_5830 <= 0.0)\n    {\n        int param_1 = li;\n        return LightSample(vec3(0.0, 1.0, 0.0), vec3(0.0), 0.0, 1.0, 0.0, int(fa_light_type(param_1) + 0.5));\n    }\n    int param_2 = li;\n    vec3 param_3 = world_pos;\n    vec3 param_4 = gn;\n    LightSample _5856 = fa_light_sample_n(param_2, param_3, param_4);\n    vec3 _8963 = _5856.color;\n    float _8964 = _5856.attenuation;\n    float _8965 = _5856.shadow;\n    bool _5859 = _5856.type == 0;\n    if (_5859 && (li == 0))\n    {\n        vec3 param_5 = gn;\n        vec3 param_6 = _5856.direction;\n        float _5870 = fa_shadow_factor(param_5, param_6);\n        _8965 = _5870;\n        _8963 *= _5870;\n    }\n    else\n    {\n        bool _5881 = _5856.type != 0;\n        bool _5887;\n        if (_5881)\n        {\n            _5887 = _8964 > 0.0;\n        }\n        else\n        {\n            _5887 = _5881;\n        }\n        if (_5887)\n        {\n            int param_7 = li;\n            int param_8 = fa_light_base(param_7);\n            int param_9 = li;\n            vec3 param_10 = fa_light_texel(param_8).xyz;\n            vec3 param_11 = world_pos;\n            vec3 param_12 = gn;\n            vec3 param_13 = _5856.direction;\n            float _5906 = fa_shadow_local(param_9, param_10, param_11, param_12, param_13);\n            _8965 = _5906;\n            _8963 *= _5906;\n        }\n    }\n    bool _5916 = fa_mesh_fs_params[24].x > 0.5;\n    bool _5922;\n    if (_5916)\n    {\n        _5922 = _8964 > 0.0;\n    }\n    else\n    {\n        _5922 = _5916;\n    }\n    if (_5922)\n    {\n        float _5929;\n        if (_5859)\n        {\n            _5929 = 1000000000.0;\n        }\n        else\n        {\n            _5929 = _5856._distance;\n        }\n        int param_14 = li;\n        vec3 param_15 = world_pos;\n        vec3 param_16 = gn;\n        vec3 param_17 = _5856.direction;\n        float param_18 = _5929;\n        float _5947 = fa_contact_shadow(param_14, param_15, param_16, param_17, param_18);\n        _8965 *= _5947;\n        _8963 *= _5947;\n    }\n    float _5960 = _8964;\n    float _5961 = _5960 * _5830;\n    _8964 = _5961;\n    vec3 _5965 = _8963;\n    vec3 _5966 = _5965 * _5830;\n    _8963 = _5966;\n    return LightSample(_5856.direction, _5966, _5961, _8965, _5856._distance, _5856.type);\n}\n\nvec3 fa_ltc_tangent(vec3 n, vec3 v)\n{\n    vec3 _6000 = v - (n * dot(v, n));\n    vec3 t = _6000;\n    float _6004 = dot(_6000, _6000);\n    float l2 = _6004;\n    if (_6004 < 1.0000000133514319600180897396058e-10)\n    {\n        vec3 _6014;\n        if (abs(n.z) < 0.999000012874603271484375)\n        {\n            _6014 = cross(n, vec3(0.0, 0.0, 1.0));\n        }\n        else\n        {\n            _6014 = cross(n, vec3(1.0, 0.0, 0.0));\n        }\n        t = _6014;\n        l2 = dot(_6014, _6014);\n    }\n    return t * inversesqrt(l2);\n}\n\nvec3 fa_ltc_local(vec3 t1, vec3 n, vec3 p)\n{\n    return vec3(dot(t1, p), dot(cross(n, t1), p), dot(n, p));\n}\n\nvec3 fa_ltc_edge_vector(vec3 a, vec3 b)\n{\n    float _6049 = dot(a, a);\n    float _6053 = dot(b, b);\n    if ((_6049 < 1.0000000195414813782625560981111e-24) || (_6053 < 1.0000000195414813782625560981111e-24))\n    {\n        return vec3(0.0);\n    }\n    vec3 _6067 = a * inversesqrt(_6049);\n    vec3 _6072 = b * inversesqrt(_6053);\n    float _6076 = dot(_6067, _6072);\n    float _6079 = abs(_6076);\n    float g = (((((((((((0.0416471660137176513671875 * _6079) - 0.1924748718738555908203125) * _6079) + 0.4179156124591827392578125) * _6079) - 0.616057217121124267578125) * _6079) + 0.777722418308258056640625) * _6079) - 0.999542415142059326171875) * _6079) + 1.570791721343994140625;\n    if (_6076 < 0.0)\n    {\n        g = (3.1415927410125732421875 * inversesqrt(max(1.0 - (_6076 * _6076), 1.0000000116860974230803549289703e-07))) - g;\n    }\n    return cross(_6067, _6072) * g;\n}\n\nvoid fa_ltc_clip_edge(vec3 a, vec3 b, inout vec3 sum, inout vec3 leave, inout vec3 enter, inout vec2 seen)\n{\n    bool _6136 = a.z > 0.0;\n    bool _6140 = b.z > 0.0;\n    if (_6136 && _6140)\n    {\n        vec3 param = a;\n        vec3 param_1 = b;\n        sum += fa_ltc_edge_vector(param, param_1);\n    }\n    else\n    {\n        if (_6136 != _6140)\n        {\n            vec3 _6175 = a + ((b - a) * (a.z / (a.z - b.z)));\n            _6175.z = 0.0;\n            if (_6136)\n            {\n                vec3 param_2 = a;\n                vec3 param_3 = _6175;\n                sum += fa_ltc_edge_vector(param_2, param_3);\n                leave = _6175;\n                seen.x = 1.0;\n            }\n            else\n            {\n                vec3 param_4 = _6175;\n                vec3 param_5 = b;\n                sum += fa_ltc_edge_vector(param_4, param_5);\n                enter = _6175;\n                seen.y = 1.0;\n            }\n        }\n    }\n}\n\nfloat fa_ltc_quad(vec4 abcd, vec3 p0, vec3 p1, vec3 p2, vec3 p3)\n{\n    vec3 _6224 = vec3((abcd.x * p0.x) + (abcd.y * p0.z), p0.y, (abcd.z * p0.x) + (abcd.w * p0.z));\n    vec3 _6250 = vec3((abcd.x * p1.x) + (abcd.y * p1.z), p1.y, (abcd.z * p1.x) + (abcd.w * p1.z));\n    vec3 _6276 = vec3((abcd.x * p2.x) + (abcd.y * p2.z), p2.y, (abcd.z * p2.x) + (abcd.w * p2.z));\n    vec3 _6302 = vec3((abcd.x * p3.x) + (abcd.y * p3.z), p3.y, (abcd.z * p3.x) + (abcd.w * p3.z));\n    vec3 sum = vec3(0.0);\n    vec3 leave = vec3(0.0);\n    vec3 enter = vec3(0.0);\n    vec3 param = _6224;\n    vec3 param_1 = _6250;\n    vec3 param_2 = vec3(0.0);\n    vec3 param_3 = vec3(0.0);\n    vec3 param_4 = vec3(0.0);\n    vec2 param_5 = vec2(0.0);\n    fa_ltc_clip_edge(param, param_1, param_2, param_3, param_4, param_5);\n    sum = param_2;\n    leave = param_3;\n    enter = param_4;\n    vec3 param_6 = _6250;\n    vec3 param_7 = _6276;\n    vec3 param_8 = param_2;\n    vec3 param_9 = param_3;\n    vec3 param_10 = param_4;\n    vec2 param_11 = param_5;\n    fa_ltc_clip_edge(param_6, param_7, param_8, param_9, param_10, param_11);\n    sum = param_8;\n    leave = param_9;\n    enter = param_10;\n    vec3 param_12 = _6276;\n    vec3 param_13 = _6302;\n    vec3 param_14 = param_8;\n    vec3 param_15 = param_9;\n    vec3 param_16 = param_10;\n    vec2 param_17 = param_11;\n    fa_ltc_clip_edge(param_12, param_13, param_14, param_15, param_16, param_17);\n    sum = param_14;\n    leave = param_15;\n    enter = param_16;\n    vec3 param_18 = _6302;\n    vec3 param_19 = _6224;\n    vec3 param_20 = param_14;\n    vec3 param_21 = param_15;\n    vec3 param_22 = param_16;\n    vec2 param_23 = param_17;\n    fa_ltc_clip_edge(param_18, param_19, param_20, param_21, param_22, param_23);\n    sum = param_20;\n    leave = param_21;\n    enter = param_22;\n    if ((param_23.x * param_23.y) > 0.5)\n    {\n        vec3 param_24 = leave;\n        vec3 param_25 = enter;\n        sum += fa_ltc_edge_vector(param_24, param_25);\n    }\n    return sum.z * 0.15915493667125701904296875;\n}\n\nfloat fa_ltc_rect(vec4 abcd, vec3 center, vec3 ex, vec3 ey)\n{\n    vec4 param = abcd;\n    vec3 param_1 = (center - ex) - ey;\n    vec3 param_2 = (center + ex) - ey;\n    vec3 param_3 = (center + ex) + ey;\n    vec3 param_4 = (center - ex) + ey;\n    return abs(fa_ltc_quad(param, param_1, param_2, param_3, param_4));\n}\n\nfloat fa_area_form(vec4 m, float shape, vec3 pc, vec3 ex, vec3 ey)\n{\n    if ((shape < 0.5) || (shape > 1.5))\n    {\n        vec4 param = m;\n        vec3 param_1 = pc;\n        vec3 param_2 = ex;\n        vec3 param_3 = ey;\n        return fa_ltc_rect(param, param_1, param_2, param_3);\n    }\n    vec3 _6451 = (pc + (ex * 0.92387950420379638671875)) + (ey * 0.3826834261417388916015625);\n    vec3 _6475 = (pc - (ex * 0.92387950420379638671875)) + (ey * 0.3826834261417388916015625);\n    vec3 _6491 = (pc - (ex * 0.3826834261417388916015625)) - (ey * 0.92387950420379638671875);\n    vec4 param_4 = m;\n    vec3 param_5 = _6451;\n    vec3 param_6 = (pc + (ex * 0.3826834261417388916015625)) + (ey * 0.92387950420379638671875);\n    vec3 param_7 = (pc - (ex * 0.3826834261417388916015625)) + (ey * 0.92387950420379638671875);\n    vec3 param_8 = _6475;\n    vec4 param_9 = m;\n    vec3 param_10 = _6451;\n    vec3 param_11 = _6475;\n    vec3 param_12 = (pc - (ex * 0.92387950420379638671875)) - (ey * 0.3826834261417388916015625);\n    vec3 param_13 = _6491;\n    vec4 param_14 = m;\n    vec3 param_15 = _6451;\n    vec3 param_16 = _6491;\n    vec3 param_17 = (pc + (ex * 0.3826834261417388916015625)) - (ey * 0.92387950420379638671875);\n    vec3 param_18 = (pc + (ex * 0.92387950420379638671875)) - (ey * 0.3826834261417388916015625);\n    return abs((fa_ltc_quad(param_4, param_5, param_6, param_7, param_8) + fa_ltc_quad(param_9, param_10, param_11, param_12, param_13)) + fa_ltc_quad(param_14, param_15, param_16, param_17, param_18));\n}\n\nvec2 fa_ltc_uv(float roughness, float ndv)\n{\n    return ((vec2(clamp((roughness - 0.0500000007450580596923828125) * 1.0526316165924072265625, 0.0, 1.0), sqrt(clamp(1.0 - ndv, 0.0, 1.0))) * 63.0) + vec2(0.5)) * vec2(0.015625);\n}\n\nvec3 fa_area_shade(int li, vec3 world_pos, vec3 n, vec3 v, vec3 diffuse_color, vec3 f0, float f90, float roughness, float ndv, float window)\n{\n    int param = li;\n    int _6549 = fa_light_base(param);\n    int param_1 = _6549;\n    int param_2 = _6549 + 1;\n    int param_3 = _6549 + 2;\n    int param_4 = _6549 + 4;\n    vec4 _6571 = fa_light_texel(param_4);\n    int param_5 = _6549 + 5;\n    vec4 _6576 = fa_light_texel(param_5);\n    int param_6 = _6549 + 6;\n    vec4 _6581 = fa_light_texel(param_6);\n    float _6582 = _6581.w;\n    vec3 _6587 = fa_light_texel(param_1).xyz - world_pos;\n    bool _6589 = _6582 < 1.5;\n    bool _6596;\n    if (_6589)\n    {\n        _6596 = dot(normalize(fa_light_texel(param_3).xyz), _6587) >= 0.0;\n    }\n    else\n    {\n        _6596 = _6589;\n    }\n    if (_6596)\n    {\n        return vec3(0.0);\n    }\n    bool _6605 = (_6582 > 0.5) && _6589;\n    float _6609 = _6605 ? 1.0539000034332275390625 : 1.0;\n    vec3 _6612 = _6571.xyz;\n    float _6614 = _6571.w;\n    vec3 _6620 = _6576.xyz;\n    float _6622 = _6576.w;\n    vec3 up = _6620 * (_6622 * _6609);\n    float _6628;\n    if (_6605)\n    {\n        _6628 = (3.1415927410125732421875 * _6614) * _6614;\n    }\n    else\n    {\n        _6628 = (4.0 * _6614) * _6622;\n    }\n    if (_6582 > 1.5)\n    {\n        vec3 _6654 = cross(_6612, -_6587);\n        vec3 perp = _6654;\n        float _6658 = dot(_6654, _6654);\n        vec3 _6661;\n        if (_6658 > 1.0000000133514319600180897396058e-10)\n        {\n            _6661 = perp * inversesqrt(_6658);\n        }\n        else\n        {\n            _6661 = _6620;\n        }\n        perp = _6661;\n        up = _6661 * _6622;\n    }\n    float _6682 = max(_6628, 9.9999999747524270787835121154785e-07);\n    vec3 param_7 = n;\n    vec3 param_8 = v;\n    vec3 _6692 = fa_ltc_tangent(param_7, param_8);\n    vec3 param_9 = _6692;\n    vec3 param_10 = n;\n    vec3 param_11 = _6587;\n    vec3 _6700 = fa_ltc_local(param_9, param_10, param_11);\n    vec3 param_12 = _6692;\n    vec3 param_13 = n;\n    vec3 param_14 = _6612 * (_6614 * _6609);\n    vec3 _6708 = fa_ltc_local(param_12, param_13, param_14);\n    vec3 param_15 = _6692;\n    vec3 param_16 = n;\n    vec3 param_17 = up;\n    vec3 _6716 = fa_ltc_local(param_15, param_16, param_17);\n    vec4 param_18 = vec4(1.0, 0.0, 0.0, 1.0);\n    float param_19 = _6582;\n    vec3 param_20 = _6700;\n    vec3 param_21 = _6708;\n    vec3 param_22 = _6716;\n    float param_23 = roughness;\n    float param_24 = ndv;\n    vec2 _6735 = fa_ltc_uv(param_23, param_24) * 64.0;\n    vec2 param_25 = _6735;\n    vec2 param_26 = _6735 + vec2(64.0, 0.0);\n    vec4 _6745 = fa_atlas_fetch(param_26);\n    vec4 param_27 = fa_atlas_fetch(param_25);\n    float param_28 = _6582;\n    vec3 param_29 = _6700;\n    vec3 param_30 = _6708;\n    vec3 param_31 = _6716;\n    return (((diffuse_color * fa_area_form(param_18, param_19, param_20, param_21, param_22)) + (((f0 * _6745.x) + ((vec3(f90) - f0) * _6745.y)) * fa_area_form(param_27, param_28, param_29, param_30, param_31))) * fa_light_texel(param_2).xyz) * ((((3.1415927410125732421875 * dot(_6587, _6587)) + _6682) / _6682) * window);\n}\n\nvec3 fa_light_rgb(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 1;\n    return fa_light_texel(param_1).xyz;\n}\n\nfloat fa_d_charlie(float alpha, float ndh)\n{\n    float _4892 = 1.0 / alpha;\n    return ((2.0 + _4892) * pow(sqrt(max(1.0 - (ndh * ndh), 9.9999997473787516355514526367188e-05)), _4892)) * 0.15915493667125701904296875;\n}\n\nfloat fa_v_ashikhmin(float ndl, float ndv)\n{\n    return clamp(0.25 / max((ndl + ndv) - (ndl * ndv), 9.9999997473787516355514526367188e-05), 0.0, 1.0);\n}\n\nfloat fa_layers_coat(FaLayers L, vec3 l, vec3 h, float vdh)\n{\n    float _4927 = max(dot(L.nc, l), 0.0);\n    float _4933 = max(dot(L.nc, h), 0.0);\n    float _4942 = ((_4933 * _4933) * (L.coat_a2 - 1.0)) + 1.0;\n    return (((L.coat * (0.039999999105930328369140625 + (0.959999978542327880859375 * pow(clamp(1.0 - vdh, 0.0, 1.0), 5.0)))) * (((L.coat_a2 / ((3.1415927410125732421875 * _4942) * _4942)) * (0.5 / max(mix((2.0 * _4927) * L.coat_ndv, _4927 + L.coat_ndv, L.coat_alpha), 9.9999997473787516355514526367188e-05))) * 3.1415927410125732421875)) * step(9.9999997473787516355514526367188e-05, _4927)) * _4927;\n}\n\nvec3 fa_area_layers(FaLayers L, int li, vec3 world_pos, vec3 n, vec3 v, vec3 l, vec3 diffuse_color, vec3 f0, float roughness, float ndv, float window)\n{\n    int param = li;\n    vec3 param_1 = world_pos;\n    vec3 param_2 = n;\n    vec3 param_3 = v;\n    vec3 param_4 = diffuse_color;\n    vec3 param_5 = f0;\n    float param_6 = L.f90;\n    float param_7 = roughness;\n    float param_8 = ndv;\n    float param_9 = window;\n    float _6813;\n    if (L.sheen_on)\n    {\n        _6813 = L.sheen_scale;\n    }\n    else\n    {\n        _6813 = 1.0;\n    }\n    vec3 result = fa_area_shade(param, param_1, param_2, param_3, param_4, param_5, param_6, param_7, param_8, param_9) * (L.keep * _6813);\n    vec3 _6826 = normalize(l + v);\n    int param_10 = li;\n    vec3 _6837 = fa_light_rgb(param_10) * window;\n    if (L.sheen_on)\n    {\n        float _6846 = max(dot(n, l), 0.0);\n        float param_11 = L.sheen_alpha;\n        float param_12 = max(dot(n, _6826), 0.0);\n        float param_13 = _6846;\n        float param_14 = ndv;\n        result += ((L.sheen * _6837) * (((((fa_d_charlie(param_11, param_12) * fa_v_ashikhmin(param_13, param_14)) * 3.1415927410125732421875) * step(9.9999997473787516355514526367188e-05, _6846)) * _6846) * L.keep));\n    }\n    if (L.coat > 0.0)\n    {\n        FaLayers param_15 = L;\n        vec3 param_16 = l;\n        vec3 param_17 = _6826;\n        float param_18 = max(dot(v, _6826), 0.0);\n        result += (_6837 * fa_layers_coat(param_15, param_16, param_17, param_18));\n    }\n    return result;\n}\n\nfloat fa_d_ggx_aniso(float ndh, float tdh, float bdh, float at, float ab)\n{\n    float _4795 = tdh / at;\n    float _4799 = bdh / ab;\n    float _4811 = ((_4795 * _4795) + (_4799 * _4799)) + (ndh * ndh);\n    return 1.0 / ((((3.1415927410125732421875 * at) * ab) * _4811) * _4811);\n}\n\nfloat fa_lambda_ggx_aniso(float n, float t, float b, float at, float ab)\n{\n    return 0.5 * (sqrt(1.0 + (((((at * at) * t) * t) + (((ab * ab) * b) * b)) / max(n * n, 9.9999999392252902907785028219223e-09))) - 1.0);\n}\n\nfloat fa_v_ggx_aniso(float ndl, float ndv, float tdv, float bdv, float tdl, float bdl, float at, float ab)\n{\n    float param = ndv;\n    float param_1 = tdv;\n    float param_2 = bdv;\n    float param_3 = at;\n    float param_4 = ab;\n    float param_5 = ndl;\n    float param_6 = tdl;\n    float param_7 = bdl;\n    float param_8 = at;\n    float param_9 = ab;\n    return clamp(1.0 / ((4.0 * max(ndl * ndv, 9.9999997473787516355514526367188e-05)) * ((1.0 + fa_lambda_ggx_aniso(param, param_1, param_2, param_3, param_4)) + fa_lambda_ggx_aniso(param_5, param_6, param_7, param_8, param_9))), 0.0, 1.0);\n}\n\nvec3 fa_layers_light(FaLayers L, vec3 diffuse_color, vec3 f0, vec3 n, vec3 v, vec3 l, vec3 h, float ndl, float ndv, float ndh, float vdh, float alpha, float a2)\n{\n    float _4991 = step(9.9999997473787516355514526367188e-05, ndl);\n    float d_ggx;\n    float vis;\n    if (L.aniso != 0.0)\n    {\n        float param = ndh;\n        float param_1 = dot(L.t, h);\n        float param_2 = dot(L.b, h);\n        float param_3 = L.at;\n        float param_4 = L.ab;\n        d_ggx = fa_d_ggx_aniso(param, param_1, param_2, param_3, param_4);\n        float param_5 = ndl;\n        float param_6 = ndv;\n        float param_7 = dot(L.t, v);\n        float param_8 = dot(L.b, v);\n        float param_9 = dot(L.t, l);\n        float param_10 = dot(L.b, l);\n        float param_11 = L.at;\n        float param_12 = L.ab;\n        vis = fa_v_ggx_aniso(param_5, param_6, param_7, param_8, param_9, param_10, param_11, param_12);\n    }\n    else\n    {\n        float _5070 = ((ndh * ndh) * (a2 - 1.0)) + 1.0;\n        d_ggx = a2 / ((3.1415927410125732421875 * _5070) * _5070);\n        vis = 0.5 / max(mix((2.0 * ndl) * ndv, ndl + ndv, alpha), 9.9999997473787516355514526367188e-05);\n    }\n    vec3 base = diffuse_color + (((f0 + ((vec3(L.f90) - f0) * pow(clamp(1.0 - vdh, 0.0, 1.0), 5.0))) * ((d_ggx * vis) * 3.1415927410125732421875)) * _4991);\n    if (L.sheen_on)\n    {\n        float param_13 = L.sheen_alpha;\n        float param_14 = ndh;\n        float param_15 = ndl;\n        float param_16 = ndv;\n        base = (base * L.sheen_scale) + (L.sheen * (((fa_d_charlie(param_13, param_14) * fa_v_ashikhmin(param_15, param_16)) * 3.1415927410125732421875) * _4991));\n    }\n    vec3 result = base * (L.keep * ndl);\n    if (L.coat > 0.0)\n    {\n        FaLayers param_17 = L;\n        vec3 param_18 = l;\n        vec3 param_19 = h;\n        float param_20 = vdh;\n        result += vec3(fa_layers_coat(param_17, param_18, param_19, param_20));\n    }\n    return result;\n}\n\nvec2 fa_env_brdf(float rough, float ndv)\n{\n    vec4 _4201 = (vec4(-1.0, -0.0274999998509883880615234375, -0.572000026702880859375, 0.02199999988079071044921875) * rough) + vec4(1.0, 0.0425000004470348358154296875, 1.03999996185302734375, -0.039999999105930328369140625);\n    float _4204 = _4201.x;\n    return (vec2(-1.03999996185302734375, 1.03999996185302734375) * ((min(_4204 * _4204, exp2((-9.27999973297119140625) * ndv)) * _4204) + _4201.y)) + _4201.zw;\n}\n\nvec3 fa_probe_level(vec2 origin, float res, int lv, vec2 e)\n{\n    float _3512;\n    if (lv == 0)\n    {\n        _3512 = 0.0;\n    }\n    else\n    {\n        _3512 = res + 2.0;\n    }\n    float _3522;\n    if (lv == 0)\n    {\n        _3522 = 0.0;\n    }\n    else\n    {\n        _3522 = (res - (res / float(1 << (lv - 1)))) + (2.0 * float(lv - 1));\n    }\n    return textureLod(fa_probe_atlas_fa_env_smp, (((origin + vec2(_3512, _3522)) + vec2(1.0)) + (((e * 0.5) + vec2(0.5)) * (res / float(1 << lv)))) / fa_atlas_size(), 0.0).xyz;\n}\n\nvec3 fa_probe_radiance(vec2 origin, float res, vec3 d, float rough)\n{\n    float _3567;\n    if (res > 64.5)\n    {\n        _3567 = 5.0;\n    }\n    else\n    {\n        _3567 = (res > 32.5) ? 4.0 : 3.0;\n    }\n    float _3582 = clamp(rough, 0.0, 1.0) * (_3567 - 1.0);\n    int _3589 = int(min(floor(_3582), _3567 - 2.0));\n    float _3594 = _3582 - float(_3589);\n    vec3 param = d;\n    vec2 _3598 = fa_oct_encode(param);\n    vec2 param_1 = origin;\n    float param_2 = res;\n    int param_3 = _3589;\n    vec2 param_4 = _3598;\n    vec3 _3608 = fa_probe_level(param_1, param_2, param_3, param_4);\n    if (_3594 < 0.00200000009499490261077880859375)\n    {\n        return _3608;\n    }\n    vec2 param_5 = origin;\n    float param_6 = res;\n    int param_7 = _3589 + 1;\n    vec2 param_8 = _3598;\n    return mix(_3608, fa_probe_level(param_5, param_6, param_7, param_8), vec3(_3594));\n}\n\nvec3 fa_probe_box_dir(vec3 d, vec4 posw, vec4 bx, vec4 by, vec4 bz)\n{\n    if (posw.w < 0.5)\n    {\n        return d;\n    }\n    float _3678 = dot(bx.xyz, fa_world_pos) + bx.w;\n    float _3685 = dot(by.xyz, fa_world_pos) + by.w;\n    float _3692 = dot(bz.xyz, fa_world_pos) + bz.w;\n    float _3698 = dot(bx.xyz, d);\n    float _3702 = dot(by.xyz, d);\n    float _3706 = dot(bz.xyz, d);\n    float _3712;\n    if (_3698 > 9.9999999747524270787835121154785e-07)\n    {\n        _3712 = (1.0 - _3678) / _3698;\n    }\n    else\n    {\n        float _3726;\n        if (_3698 < (-9.9999999747524270787835121154785e-07))\n        {\n            _3726 = ((-1.0) - _3678) / _3698;\n        }\n        else\n        {\n            _3726 = 1000000015047466219876688855040.0;\n        }\n        _3712 = _3726;\n    }\n    float tx = _3712;\n    float _3743;\n    if (_3702 > 9.9999999747524270787835121154785e-07)\n    {\n        _3743 = (1.0 - _3685) / _3702;\n    }\n    else\n    {\n        float _3756;\n        if (_3702 < (-9.9999999747524270787835121154785e-07))\n        {\n            _3756 = ((-1.0) - _3685) / _3702;\n        }\n        else\n        {\n            _3756 = 1000000015047466219876688855040.0;\n        }\n        _3743 = _3756;\n    }\n    float ty = _3743;\n    float _3772;\n    if (_3706 > 9.9999999747524270787835121154785e-07)\n    {\n        _3772 = (1.0 - _3692) / _3706;\n    }\n    else\n    {\n        float _3785;\n        if (_3706 < (-9.9999999747524270787835121154785e-07))\n        {\n            _3785 = ((-1.0) - _3692) / _3706;\n        }\n        else\n        {\n            _3785 = 1000000015047466219876688855040.0;\n        }\n        _3772 = _3785;\n    }\n    float _3797 = tx;\n    float _3800 = (_3797 > 0.0) ? _3797 : 1000000015047466219876688855040.0;\n    tx = _3800;\n    float _3801 = ty;\n    float _3804 = (_3801 > 0.0) ? _3801 : 1000000015047466219876688855040.0;\n    ty = _3804;\n    float _3814 = min(_3800, min(_3804, (_3772 > 0.0) ? _3772 : 1000000015047466219876688855040.0));\n    if (_3814 > 100000001504746621987668885504.0)\n    {\n        return d;\n    }\n    vec3 _3830 = (fa_world_pos + (d * _3814)) - posw.xyz;\n    vec3 _3835;\n    if (dot(_3830, _3830) > 1.0000000133514319600180897396058e-10)\n    {\n        _3835 = normalize(_3830);\n    }\n    else\n    {\n        _3835 = d;\n    }\n    return _3835;\n}\n\nvec3 fa_probe_environment(vec4 tile, vec4 posw, vec4 bx, vec4 by, vec4 bz, inout vec3 d, float rough)\n{\n    vec3 param = d;\n    vec4 param_1 = posw;\n    vec4 param_2 = bx;\n    vec4 param_3 = by;\n    vec4 param_4 = bz;\n    d = fa_probe_box_dir(param, param_1, param_2, param_3, param_4);\n    vec2 param_5 = tile.xy;\n    float param_6 = tile.z;\n    vec3 param_7 = d;\n    float param_8 = rough;\n    return fa_probe_radiance(param_5, param_6, param_7, param_8);\n}\n\nvec3 fa_environment(vec3 d, float rough)\n{\n    float _3881 = (1.0 - fa_mesh_fs_params[42].w) - fa_mesh_fs_params[47].w;\n    vec3 outc = vec3(0.0);\n    if (_3881 > 0.0005000000237487256526947021484375)\n    {\n        vec3 base;\n        if (fa_mesh_fs_params[11].w > 0.5)\n        {\n            vec2 param = fa_mesh_fs_params[41].zw;\n            float param_1 = 128.0;\n            vec3 param_2 = d;\n            float param_3 = rough;\n            base = fa_probe_radiance(param, param_1, param_2, param_3);\n        }\n        else\n        {\n            float _3910 = rough * rough;\n            float _3941 = 0.60000002384185791015625 * _3910;\n            base = mix(mix(fa_mesh_fs_params[12].xyz * 0.550000011920928955078125, mix(fa_mesh_fs_params[12].xyz, fa_mesh_fs_params[11].xyz, vec3(pow(clamp(d.y * (1.0 - (0.699999988079071044921875 * _3910)), 0.0, 1.0), 0.550000011920928955078125))), vec3(smoothstep((-0.0500000007450580596923828125) - _3941, 0.0500000007450580596923828125 + _3941, d.y))), ((fa_mesh_fs_params[11].xyz + fa_mesh_fs_params[12].xyz) * 0.5) * 0.800000011920928955078125, vec3(_3910 * 0.60000002384185791015625));\n        }\n        outc = base * _3881;\n    }\n    if (fa_mesh_fs_params[42].w > 0.0)\n    {\n        vec4 param_4 = fa_mesh_fs_params[42];\n        vec4 param_5 = fa_mesh_fs_params[43];\n        vec4 param_6 = fa_mesh_fs_params[44];\n        vec4 param_7 = fa_mesh_fs_params[45];\n        vec4 param_8 = fa_mesh_fs_params[46];\n        vec3 param_9 = d;\n        float param_10 = rough;\n        vec3 _4000 = fa_probe_environment(param_4, param_5, param_6, param_7, param_8, param_9, param_10);\n        outc += (_4000 * fa_mesh_fs_params[42].w);\n    }\n    if (fa_mesh_fs_params[47].w > 0.0)\n    {\n        vec4 param_11 = fa_mesh_fs_params[47];\n        vec4 param_12 = fa_mesh_fs_params[48];\n        vec4 param_13 = fa_mesh_fs_params[49];\n        vec4 param_14 = fa_mesh_fs_params[50];\n        vec4 param_15 = fa_mesh_fs_params[51];\n        vec3 param_16 = d;\n        float param_17 = rough;\n        vec3 _4032 = fa_probe_environment(param_11, param_12, param_13, param_14, param_15, param_16, param_17);\n        outc += (_4032 * fa_mesh_fs_params[47].w);\n    }\n    return outc;\n}\n\nvec3 fa_layers_ibl(FaLayers L, vec3 n, vec3 v, vec3 f0, float roughness)\n{\n    vec3 rn = n;\n    if (L.aniso != 0.0)\n    {\n        vec3 _4678;\n        if (L.aniso >= 0.0)\n        {\n            _4678 = L.b;\n        }\n        else\n        {\n            _4678 = L.t;\n        }\n        rn = normalize(mix(n, cross(cross(_4678, v), _4678), vec3(abs(L.aniso))));\n    }\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05);\n    vec2 _4711 = fa_env_brdf(param, param_1);\n    vec3 param_2 = reflect(-v, rn);\n    float param_3 = roughness;\n    vec3 result = (fa_environment(param_2, param_3) * ((f0 * _4711.x) + (vec3(L.f90) * _4711.y))) * L.base_scale;\n    if (L.sheen_on)\n    {\n        vec3 param_4 = n;\n        float param_5 = L.sheen_rough;\n        result += ((L.sheen * (L.sheen_e * L.keep)) * fa_environment(param_4, param_5));\n    }\n    if (L.coat > 0.0)\n    {\n        float param_6 = L.coat_rough;\n        float param_7 = L.coat_ndv;\n        vec2 _4766 = fa_env_brdf(param_6, param_7);\n        vec3 param_8 = reflect(-v, L.nc);\n        float param_9 = L.coat_rough;\n        result += (fa_environment(param_8, param_9) * (L.coat * ((0.039999999105930328369140625 * _4766.x) + _4766.y)));\n    }\n    return result;\n}\n\nvec3 fa_sky_reflection(vec3 n, vec3 v, vec3 f0, float roughness)\n{\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05);\n    vec2 _4243 = fa_env_brdf(param, param_1);\n    vec3 param_2 = reflect(-v, n);\n    float param_3 = roughness;\n    return fa_environment(param_2, param_3) * ((f0 * _4243.x) + vec3(_4243.y));\n}\n\nvec2 fa_xm_size(int k)\n{\n    return max(floor(fa_mesh_fs_params[24].zw / vec2(exp2(float(k)))), vec2(1.0));\n}\n\nvec2 fa_xm_origin(int k)\n{\n    if (k == 0)\n    {\n        return vec2(0.0);\n    }\n    float y = 0.0;\n    for (int j = 1; j < k; j++)\n    {\n        int param = j;\n        y += fa_xm_size(param).y;\n    }\n    return vec2(fa_mesh_fs_params[24].z, y);\n}\n\nvec3 fa_xm_texel(vec2 size, vec2 origin, vec2 p)\n{\n    return texelFetch(fa_screen_tex_fa_shadow_smp, ivec2(origin + clamp(p, vec2(0.0), size - vec2(1.0))), 0).xyz;\n}\n\nvec3 fa_xm_level(int k, vec2 uv)\n{\n    int param = k;\n    vec2 _5468 = fa_xm_size(param);\n    int param_1 = k;\n    vec2 _5472 = fa_xm_origin(param_1);\n    vec2 _5478 = (uv * _5468) - vec2(0.5);\n    vec2 _5481 = fract(_5478);\n    vec2 _5484 = floor(_5478);\n    vec2 param_2 = _5468;\n    vec2 param_3 = _5472;\n    vec2 param_4 = _5484;\n    vec2 param_5 = _5468;\n    vec2 param_6 = _5472;\n    vec2 param_7 = _5484 + vec2(1.0, 0.0);\n    vec2 param_8 = _5468;\n    vec2 param_9 = _5472;\n    vec2 param_10 = _5484 + vec2(0.0, 1.0);\n    vec2 param_11 = _5468;\n    vec2 param_12 = _5472;\n    vec2 param_13 = _5484 + vec2(1.0);\n    vec3 _5526 = vec3(_5481.x);\n    return mix(mix(fa_xm_texel(param_2, param_3, param_4), fa_xm_texel(param_5, param_6, param_7), _5526), mix(fa_xm_texel(param_8, param_9, param_10), fa_xm_texel(param_11, param_12, param_13), _5526), vec3(_5481.y));\n}\n\nvec3 fa_xm_sample(vec2 uv, float lod)\n{\n    float _5545 = max(fa_mesh_fs_params[31].w - 1.0, 0.0);\n    float _5549 = clamp(lod, 0.0, _5545);\n    int _5553 = int(floor(_5549));\n    int param = _5553;\n    vec2 param_1 = uv;\n    vec3 c = fa_xm_level(param, param_1);\n    float _5563 = float(_5553);\n    float _5564 = _5549 - _5563;\n    bool _5566 = _5564 > 0.001000000047497451305389404296875;\n    bool _5573;\n    if (_5566)\n    {\n        _5573 = _5563 < _5545;\n    }\n    else\n    {\n        _5573 = _5566;\n    }\n    if (_5573)\n    {\n        int param_2 = _5553 + 1;\n        vec2 param_3 = uv;\n        c = mix(c, fa_xm_level(param_2, param_3), vec3(_5564));\n    }\n    return c;\n}\n\nvec3 fa_transmitted(Surface s, vec3 n, vec3 v, float roughness, vec3 f0, float f90, float keep, float tr, inout float blend)\n{\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05);\n    vec2 _5599 = fa_env_brdf(param, param_1);\n    vec3 through = ((vec3(1.0) - clamp((f0 * _5599.x) + (vec3(f90) * _5599.y), vec3(0.0), vec3(1.0))) * s.albedo) * (tr * keep);\n    float _5627 = max(s.thickness, 0.0);\n    bool _5632 = _5627 > 0.0;\n    if ((s.attenuation_distance > 0.0) && _5632)\n    {\n        through *= exp((-((-log(clamp(s.attenuation_color, vec3(9.9999997473787516355514526367188e-05), vec3(1.0)))) / vec3(s.attenuation_distance))) * _5627);\n    }\n    bool _5657 = fa_mesh_fs_params[30].w > 1.5;\n    bool _5664;\n    if (!_5657)\n    {\n        _5664 = fa_mesh_fs_params[30].w < 0.5;\n    }\n    else\n    {\n        _5664 = _5657;\n    }\n    if (_5664)\n    {\n        blend = clamp(dot(through, vec3(0.3333333432674407958984375)), 0.0, 0.980000019073486328125);\n        return vec3(0.0);\n    }\n    vec3 world = fa_world_pos;\n    if (_5632)\n    {\n        world += (refract(-v, n, 1.0 / max(s.ior, 1.0)) * _5627);\n    }\n    vec4 _5699 = vec4(world, 1.0);\n    float _5704 = dot(fa_mesh_fs_params[28], _5699);\n    vec2 uv = vec2(0.5);\n    if (_5704 > 9.9999997473787516355514526367188e-05)\n    {\n        vec2 _5722 = vec2(dot(fa_mesh_fs_params[26], _5699), dot(fa_mesh_fs_params[27], _5699)) / vec2(_5704);\n        float _5730;\n        if (fa_mesh_fs_params[24].y > 0.5)\n        {\n            _5730 = (_5722.y * 0.5) + 0.5;\n        }\n        else\n        {\n            _5730 = 0.5 - (_5722.y * 0.5);\n        }\n        uv = vec2((_5722.x * 0.5) + 0.5, _5730);\n    }\n    vec2 param_2 = clamp(uv, vec2(0.0), vec2(1.0));\n    float param_3 = (clamp(roughness, 0.0, 1.0) * clamp((2.0 * s.ior) - 2.0, 0.0, 1.0)) * max(fa_mesh_fs_params[31].w - 1.0, 0.0);\n    return through * fa_xm_sample(param_2, param_3);\n}\n\nvec3 fa_shadow_debug(vec3 color, vec3 world)\n{\n    if (fa_shadows[27].w < 0.5)\n    {\n        return color;\n    }\n    int _3263 = int(fa_shadows[25].x + 0.5);\n    float _3273 = dot(world - fa_shadows[27].xyz, fa_shadows[28].xyz);\n    vec3 tint_1 = vec3(0.3499999940395355224609375);\n    bool _3278 = _3263 > 0;\n    bool _3287;\n    if (_3278)\n    {\n        int param = _3263 - 1;\n        _3287 = _3273 <= fa_shadow_split_at(param);\n    }\n    else\n    {\n        _3287 = _3278;\n    }\n    if (_3287)\n    {\n        tint_1 = vec3(1.0, 0.1500000059604644775390625, 0.100000001490116119384765625);\n        bool _3293 = _3263 > 1;\n        bool _3300;\n        if (_3293)\n        {\n            _3300 = _3273 > fa_shadows[24].x;\n        }\n        else\n        {\n            _3300 = _3293;\n        }\n        if (_3300)\n        {\n            tint_1 = vec3(0.100000001490116119384765625, 0.89999997615814208984375, 0.20000000298023223876953125);\n        }\n        bool _3306 = _3263 > 2;\n        bool _3313;\n        if (_3306)\n        {\n            _3313 = _3273 > fa_shadows[24].y;\n        }\n        else\n        {\n            _3313 = _3306;\n        }\n        if (_3313)\n        {\n            tint_1 = vec3(0.1500000059604644775390625, 0.300000011920928955078125, 1.0);\n        }\n        bool _3319 = _3263 > 3;\n        bool _3326;\n        if (_3319)\n        {\n            _3326 = _3273 > fa_shadows[24].z;\n        }\n        else\n        {\n            _3326 = _3319;\n        }\n        if (_3326)\n        {\n            tint_1 = vec3(1.0, 0.89999997615814208984375, 0.100000001490116119384765625);\n        }\n    }\n    return mix(color, tint_1, vec3(0.550000011920928955078125));\n}\n\nvoid main()\n{\n    fa_inst_load();\n    vec3 _8622 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _8622 = -_8622;\n    }\n    vec3 _7917 = normalize(fa_mesh_fs_params[0].xyz - fa_world_pos);\n    vec3 param = fa_world_pos;\n    fa_cluster_begin(param);\n    SurfaceInput param_1 = SurfaceInput(fa_world_pos, _8622, fa_world_tangent, fa_uv, fa_vertex_color, _7917, gl_FrontFacing);\n    Surface _7925 = fa_standard_surface(param_1);\n    vec3 _8653 = _7925.albedo;\n    float _8654 = _7925.alpha;\n    vec3 _8655 = _7925.normal;\n    float _8656 = _7925.metallic;\n    float _8657 = _7925.roughness;\n    float _8658 = _7925.occlusion;\n    vec3 _8659 = _7925.emission;\n    float _8660 = _7925.clearcoat;\n    float _8661 = _7925.clearcoat_roughness;\n    vec3 _8662 = _7925.sheen_color;\n    float _8663 = _7925.sheen_roughness;\n    float _8664 = _7925.anisotropy;\n    float _8665 = _7925.anisotropy_rotation;\n    float _8666 = _7925.specular;\n    float _8667 = _7925.ior;\n    vec3 _8668 = _7925.specular_color;\n    float _8669 = _7925.transmission;\n    float _8670 = _7925.thickness;\n    vec3 _8671 = _7925.attenuation_color;\n    float _8672 = _7925.attenuation_distance;\n    SurfaceInput param_2 = SurfaceInput(fa_world_pos, _8622, fa_world_tangent, fa_uv, fa_vertex_color, _7917, gl_FrontFacing);\n    Surface param_3 = _7925;\n    surface(param_2, param_3);\n    _8653 = param_3.albedo;\n    _8654 = param_3.alpha;\n    _8655 = param_3.normal;\n    _8656 = param_3.metallic;\n    _8657 = param_3.roughness;\n    _8658 = param_3.occlusion;\n    _8659 = param_3.emission;\n    _8660 = param_3.clearcoat;\n    _8661 = param_3.clearcoat_roughness;\n    _8662 = param_3.sheen_color;\n    _8663 = param_3.sheen_roughness;\n    _8664 = param_3.anisotropy;\n    _8665 = param_3.anisotropy_rotation;\n    _8666 = param_3.specular;\n    _8667 = param_3.ior;\n    _8668 = param_3.specular_color;\n    _8669 = param_3.transmission;\n    _8670 = param_3.thickness;\n    _8671 = param_3.attenuation_color;\n    _8672 = param_3.attenuation_distance;\n    vec3 param_4 = fa_world_pos;\n    vec3 param_5 = _8622;\n    vec3 param_6 = param_3.albedo;\n    vec3 param_7 = param_3.normal;\n    fa_apply_decals(param_4, param_5, param_6, param_7);\n    _8653 = param_6;\n    _8655 = param_7;\n    float fa_tr_blend = 0.0;\n    vec3 result;\n    if (fa_mesh_fs_params[3].w > 0.5)\n    {\n        result = _8653;\n    }\n    else\n    {\n        vec3 _7965 = normalize(_8655);\n        float _7972 = clamp(_8656, 0.0, 1.0);\n        float _7976 = clamp(_8657, 0.0500000007450580596923828125, 1.0);\n        float _7980 = _7976 * _7976;\n        float _7984 = _7980 * _7980;\n        float _7989 = max(dot(_7965, _7917), 9.9999997473787516355514526367188e-05);\n        float _7995 = 1.0 - _7972;\n        float _7996 = clamp(_8669, 0.0, 1.0) * _7995;\n        vec3 _8005 = (_8653 * _7995) * (1.0 - _7996);\n        vec3 _8012 = mix(vec3(0.039999999105930328369140625), _8653, vec3(_7972));\n        vec3 f0 = _8012;\n        SurfaceInput param_8 = SurfaceInput(fa_world_pos, _8622, fa_world_tangent, fa_uv, fa_vertex_color, _7917, gl_FrontFacing);\n        Surface param_9 = Surface(_8653, _8654, _8655, _8656, _8657, _8658, _8659, _8660, _8661, _8662, _8663, _8664, _8665, _8666, _8667, _8668, _8669, _8670, _8671, _8672);\n        vec3 param_10 = _7965;\n        vec3 param_11 = _7917;\n        float param_12 = _7972;\n        float param_13 = _7976;\n        vec3 param_14 = _8012;\n        FaLayers _8028 = fa_layers_setup(param_8, param_9, param_10, param_11, param_12, param_13, param_14);\n        f0 = param_14;\n        vec3 param_15 = _7965;\n        vec3 lit = (fa_indirect_diffuse(param_15) * _8005) * _8658;\n        if (_8028.on)\n        {\n            lit *= _8028.base_scale;\n        }\n        int _8050 = fa_cl_ndir + fa_cl_local;\n        for (int ln = 0; ln < _8050; ln++)\n        {\n            int param_16 = ln;\n            int _8063 = fa_cl_light(param_16);\n            int param_17 = _8063;\n            if (fa_baked_keep(param_17) <= 0.0)\n            {\n                continue;\n            }\n            int param_18 = _8063;\n            vec3 param_19 = fa_world_pos;\n            vec3 param_20 = _8622;\n            LightSample _8079 = fa_light_shadowed(param_18, param_19, param_20);\n            float _8087 = max(dot(_7965, _8079.direction), 0.0);\n            float _8093 = _8079.attenuation * _8079.shadow;\n            vec3 _8098 = normalize(_8079.direction + _7917);\n            float _8103 = max(dot(_7965, _8098), 0.0);\n            float _8108 = max(dot(_7917, _8098), 0.0);\n            bool _8115;\n            if (fa_light_is_area)\n            {\n                _8115 = !_8028.on;\n            }\n            else\n            {\n                _8115 = fa_light_is_area;\n            }\n            if (_8115)\n            {\n                int param_21 = _8063;\n                vec3 param_22 = fa_world_pos;\n                vec3 param_23 = _7965;\n                vec3 param_24 = _7917;\n                vec3 param_25 = _8005;\n                vec3 param_26 = f0;\n                float param_27 = 1.0;\n                float param_28 = _7976;\n                float param_29 = _7989;\n                float param_30 = _8093;\n                lit += fa_area_shade(param_21, param_22, param_23, param_24, param_25, param_26, param_27, param_28, param_29, param_30);\n            }\n            else\n            {\n                if (fa_light_is_area)\n                {\n                    FaLayers param_31 = _8028;\n                    int param_32 = _8063;\n                    vec3 param_33 = fa_world_pos;\n                    vec3 param_34 = _7965;\n                    vec3 param_35 = _7917;\n                    vec3 param_36 = _8079.direction;\n                    vec3 param_37 = _8005;\n                    vec3 param_38 = f0;\n                    float param_39 = _7976;\n                    float param_40 = _7989;\n                    float param_41 = _8093;\n                    lit += fa_area_layers(param_31, param_32, param_33, param_34, param_35, param_36, param_37, param_38, param_39, param_40, param_41);\n                }\n                else\n                {\n                    if (_8028.on)\n                    {\n                        FaLayers param_42 = _8028;\n                        vec3 param_43 = _8005;\n                        vec3 param_44 = f0;\n                        vec3 param_45 = _7965;\n                        vec3 param_46 = _7917;\n                        vec3 param_47 = _8079.direction;\n                        vec3 param_48 = _8098;\n                        float param_49 = _8087;\n                        float param_50 = _7989;\n                        float param_51 = _8103;\n                        float param_52 = _8108;\n                        float param_53 = _7980;\n                        float param_54 = _7984;\n                        int param_55 = _8063;\n                        lit += (fa_layers_light(param_42, param_43, param_44, param_45, param_46, param_47, param_48, param_49, param_50, param_51, param_52, param_53, param_54) * ((fa_light_rgb(param_55) * fa_light_tint) * _8093));\n                    }\n                    else\n                    {\n                        float _8221 = ((_8103 * _8103) * (_7984 - 1.0)) + 1.0;\n                        int param_56 = _8063;\n                        lit += (((_8005 + (((f0 + ((vec3(1.0) - f0) * pow(1.0 - _8108, 5.0))) * (((_7984 / ((3.1415927410125732421875 * _8221) * _8221)) * (0.5 / max(mix((2.0 * _8087) * _7989, _8087 + _7989, _7980), 9.9999997473787516355514526367188e-05))) * 3.1415927410125732421875)) * step(9.9999997473787516355514526367188e-05, _8087))) * (fa_light_rgb(param_56) * fa_light_tint)) * (_8087 * _8093));\n                    }\n                }\n            }\n        }\n        if (_8028.on)\n        {\n            FaLayers param_57 = _8028;\n            vec3 param_58 = _7965;\n            vec3 param_59 = _7917;\n            vec3 param_60 = f0;\n            float param_61 = _7976;\n            lit += (fa_layers_ibl(param_57, param_58, param_59, param_60, param_61) * _8658);\n        }\n        else\n        {\n            vec3 param_62 = _7965;\n            vec3 param_63 = _7917;\n            vec3 param_64 = f0;\n            float param_65 = _7976;\n            lit += (fa_sky_reflection(param_62, param_63, param_64, param_65) * _8658);\n        }\n        if (_7996 > 0.0)\n        {\n            float _8319;\n            if (_8028.on)\n            {\n                _8319 = _8028.f90;\n            }\n            else\n            {\n                _8319 = 1.0;\n            }\n            float _8327;\n            if (_8028.on)\n            {\n                _8327 = _8028.base_scale;\n            }\n            else\n            {\n                _8327 = 1.0;\n            }\n            Surface param_66 = Surface(_8653, _8654, _8655, _8656, _8657, _8658, _8659, _8660, _8661, _8662, _8663, _8664, _8665, _8666, _8667, _8668, _8669, _8670, _8671, _8672);\n            vec3 param_67 = _7965;\n            vec3 param_68 = _7917;\n            float param_69 = _7976;\n            vec3 param_70 = f0;\n            float param_71 = _8319;\n            float param_72 = _8327;\n            float param_73 = _7996;\n            float param_74 = fa_tr_blend;\n            vec3 _8351 = fa_transmitted(param_66, param_67, param_68, param_69, param_70, param_71, param_72, param_73, param_74);\n            fa_tr_blend = param_74;\n            lit += _8351;\n        }\n        result = lit;\n    }\n    vec3 _8358 = result;\n    vec3 _8359 = _8358 + _8659;\n    result = _8359;\n    vec3 param_75 = _8359;\n    vec3 param_76 = fa_world_pos;\n    result = fa_shadow_debug(param_75, param_76);\n    bool _8368 = fa_mesh_fs_params[7].w > 0.0;\n    bool _8375;\n    if (!_8368)\n    {\n        _8375 = fa_mesh_fs_params[8].y > 0.0;\n    }\n    else\n    {\n        _8375 = _8368;\n    }\n    if (_8375)\n    {\n        vec3 _8384 = fa_world_pos - fa_mesh_fs_params[0].xyz;\n        float _8390 = dot(_8384, fa_mesh_fs_params[9].xyz);\n        bool _8394 = fa_mesh_fs_params[9].w > 0.5;\n        float _8395;\n        if (_8394)\n        {\n            _8395 = _8390;\n        }\n        else\n        {\n            _8395 = length(_8384);\n        }\n        float _8407 = _8395 - fa_mesh_fs_params[8].x;\n        if (_8407 > 0.0)\n        {\n            float _8416 = fa_mesh_fs_params[7].w * _8407;\n            float tau = _8416 * _8416;\n            if (fa_mesh_fs_params[8].y > 0.0)\n            {\n                float _8432;\n                if (_8394)\n                {\n                    _8432 = fa_world_pos.y - (fa_mesh_fs_params[9].y * _8390);\n                }\n                else\n                {\n                    _8432 = fa_mesh_fs_params[0].y;\n                }\n                float _8453 = mix(_8432, fa_world_pos.y, clamp(fa_mesh_fs_params[8].x / _8395, 0.0, 1.0));\n                float _8457 = fa_world_pos.y - _8453;\n                float _8462 = _8453 - fa_mesh_fs_params[8].z;\n                float _8467 = fa_world_pos.y - fa_mesh_fs_params[8].z;\n                bool _8470 = _8462 <= 0.0;\n                bool _8471 = !_8470;\n                bool _8477;\n                if (_8471)\n                {\n                    _8477 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _8477 = _8470;\n                }\n                float _8478;\n                if (_8477)\n                {\n                    _8478 = fa_mesh_fs_params[8].y;\n                }\n                else\n                {\n                    _8478 = fa_mesh_fs_params[8].y * exp(-min(fa_mesh_fs_params[8].w * _8462, 80.0));\n                }\n                bool _8505;\n                if (_8471)\n                {\n                    _8505 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _8505 = _8470;\n                }\n                float _8506;\n                if (_8505)\n                {\n                    _8506 = fa_mesh_fs_params[8].y * _8462;\n                }\n                else\n                {\n                    _8506 = (fa_mesh_fs_params[8].y * (1.0 - exp(-min(fa_mesh_fs_params[8].w * _8462, 80.0)))) / fa_mesh_fs_params[8].w;\n                }\n                bool _8531 = _8467 <= 0.0;\n                bool _8538;\n                if (!_8531)\n                {\n                    _8538 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _8538 = _8531;\n                }\n                float _8539;\n                if (_8538)\n                {\n                    _8539 = fa_mesh_fs_params[8].y * _8467;\n                }\n                else\n                {\n                    _8539 = (fa_mesh_fs_params[8].y * (1.0 - exp(-min(fa_mesh_fs_params[8].w * _8467, 80.0)))) / fa_mesh_fs_params[8].w;\n                }\n                float _8566;\n                if (abs(_8457) < 0.001000000047497451305389404296875)\n                {\n                    _8566 = _8478;\n                }\n                else\n                {\n                    _8566 = (_8539 - _8506) / _8457;\n                }\n                tau += (_8407 * max(_8566, 0.0));\n            }\n            result = mix(result, fa_mesh_fs_params[7].xyz, vec3(clamp(1.0 - exp(-clamp(tau, 0.0, 80.0)), 0.0, 1.0)));\n        }\n    }\n    if (fa_tr_blend > 0.0)\n    {\n        float _8602 = 1.0 - fa_tr_blend;\n        result /= vec3(_8602);\n        _8654 *= _8602;\n    }\n    fa_frag_color = vec4(result, _8654);\n}\n\n",
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
            "inst_name": "_660",
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
            "inst_name": "_2327",
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
            "inst_name": "_6915",
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
