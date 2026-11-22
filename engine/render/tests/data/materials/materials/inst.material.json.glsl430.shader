{
  "format": "factoria.shader/1",
  "engine": "0.34.0",
  "template": "d5ad4ba00a2086cd5c3d6440d2be629e3ce9b0f8ede644c9a19112677c2fea28",
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
      "fs": "#version 430\n\nstruct SurfaceInput\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 vertex_color;\n    vec3 view_dir;\n    bool front_facing;\n};\n\nstruct LightSample\n{\n    vec3 direction;\n    vec3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct Surface\n{\n    vec3 albedo;\n    float alpha;\n    vec3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    vec3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    vec3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    vec3 specular_color;\n    float transmission;\n    float thickness;\n    vec3 attenuation_color;\n    float attenuation_distance;\n};\n\nstruct FaLayers\n{\n    bool on;\n    float f90;\n    float keep;\n    float base_scale;\n    float coat;\n    float coat_rough;\n    float coat_alpha;\n    float coat_a2;\n    vec3 nc;\n    float coat_ndv;\n    bool sheen_on;\n    vec3 sheen;\n    float sheen_rough;\n    float sheen_alpha;\n    float sheen_scale;\n    float sheen_e;\n    float aniso;\n    vec3 t;\n    vec3 b;\n    float at;\n    float ab;\n};\n\nconst float _4395[63] = float[](1.0, 1.0, 1.0, 0.4790000021457672119140625, 0.11699999868869781494140625, 0.01200000010430812835693359375, 0.0, 0.0, 0.0, 1.0, 1.0, 1.0, 0.578000009059906005859375, 0.19300000369548797607421875, 0.0350000001490116119384765625, 0.0030000000260770320892333984375, 0.0, 0.0, 1.0, 1.0, 1.0, 0.6740000247955322265625, 0.3459999859333038330078125, 0.1319999992847442626953125, 0.032999999821186065673828125, 0.0040000001899898052215576171875, 0.0, 0.971000015735626220703125, 0.954999983310699462890625, 0.828999996185302734375, 0.63999998569488525390625, 0.42599999904632568359375, 0.24500000476837158203125, 0.115000002086162567138671875, 0.037000000476837158203125, 0.0030000000260770320892333984375, 0.7469999790191650390625, 0.737999975681304931640625, 0.670000016689300537109375, 0.563000023365020751953125, 0.4309999942779541015625, 0.3039999902248382568359375, 0.1940000057220458984375, 0.1019999980926513671875, 0.0309999994933605194091796875, 0.614000022411346435546875, 0.609000027179718017578125, 0.566999971866607666015625, 0.499000012874603271484375, 0.412000000476837158203125, 0.32400000095367431640625, 0.240999996662139892578125, 0.162000000476837158203125, 0.087999999523162841796875, 0.538999974727630615234375, 0.535000026226043701171875, 0.505999982357025146484375, 0.4569999873638153076171875, 0.393999993801116943359375, 0.328999996185302734375, 0.2660000026226043701171875, 0.203999996185302734375, 0.14200000464916229248046875);\n\nuniform vec4 fa_mesh_fs_params[53];\nuniform vec4 fa_shadows[30];\nuniform vec4 fa_material[1];\nlayout(binding = 0) uniform sampler2D fa_light_tex_fa_shadow_smp;\nlayout(binding = 1) uniform sampler2D fa_tex_fa_smp;\nlayout(binding = 2) uniform sampler2D fa_normal_tex_fa_smp;\nlayout(binding = 3) uniform sampler2D fa_mr_tex_fa_smp;\nlayout(binding = 4) uniform sampler2D fa_occlusion_tex_fa_smp;\nlayout(binding = 5) uniform sampler2D fa_emissive_tex_fa_smp;\nlayout(binding = 6) uniform sampler2D fa_decal_tex_fa_env_smp;\nlayout(binding = 7) uniform sampler2D fa_lightmap_fa_env_smp;\nlayout(binding = 8) uniform sampler2D fa_probe_atlas_fa_env_smp;\nlayout(binding = 9) uniform sampler2D fa_light_atlas_fa_env_smp;\nlayout(binding = 10) uniform sampler2D fa_shadow_tex_fa_shadow_smp;\nlayout(binding = 11) uniform sampler2D fa_screen_tex_fa_shadow_smp;\n\nlayout(location = 2) in vec3 fa_world_pos;\nlayout(location = 7) in vec3 fa_lm;\nlayout(location = 0) flat in vec4 fa_inst_v0;\nlayout(location = 1) flat in vec4 fa_inst_v1;\nlayout(location = 3) in vec3 fa_world_normal;\nlayout(location = 4) in vec4 fa_world_tangent;\nlayout(location = 5) in vec2 fa_uv;\nlayout(location = 6) in vec4 fa_vertex_color;\nlayout(location = 0) out vec4 fa_frag_color;\nvec3 fa_light_tint;\nbool fa_light_is_area;\nint fa_cl_ndir;\nint fa_cl_slot;\nint fa_cl_local;\nfloat raise;\nvec4 tint;\n\nvoid fa_instance_unpack(vec4 fa_d0, vec4 fa_d1, vec4 fa_d2)\n{\n    raise = fa_d0.x;\n    tint = fa_d1;\n}\n\nvoid fa_inst_load()\n{\n    vec4 param = fa_inst_v0;\n    vec4 param_1 = fa_inst_v1;\n    vec4 param_2 = vec4(0.0);\n    fa_instance_unpack(param, param_1, param_2);\n}\n\nvec4 fa_light_texel(int t)\n{\n    return texelFetch(fa_light_tex_fa_shadow_smp, ivec2(t & 1023, t >> 10), 0);\n}\n\nvec4 fa_cluster_texel(vec3 world_pos)\n{\n    bool _1634 = fa_mesh_fs_params[19].x < 0.0;\n    bool _1641;\n    if (!_1634)\n    {\n        _1641 = fa_mesh_fs_params[19].w < 1.0;\n    }\n    else\n    {\n        _1641 = _1634;\n    }\n    bool _1649;\n    if (!_1641)\n    {\n        _1649 = fa_mesh_fs_params[18].x < 1.0;\n    }\n    else\n    {\n        _1649 = _1641;\n    }\n    bool _1656;\n    if (!_1649)\n    {\n        _1656 = fa_mesh_fs_params[18].y < 1.0;\n    }\n    else\n    {\n        _1656 = _1649;\n    }\n    bool _1663;\n    if (!_1656)\n    {\n        _1663 = fa_mesh_fs_params[19].y < 1.0;\n    }\n    else\n    {\n        _1663 = _1656;\n    }\n    if (_1663)\n    {\n        return vec4(0.0);\n    }\n    vec4 _1673 = vec4(world_pos, 1.0);\n    float _1679 = dot(fa_mesh_fs_params[16], _1673);\n    if (!(_1679 > 9.9999999747524270787835121154785e-07))\n    {\n        return vec4(0.0);\n    }\n    vec2 _1701 = vec2(dot(fa_mesh_fs_params[14], _1673), dot(fa_mesh_fs_params[15], _1673)) / vec2(_1679);\n    int _1705 = int(fa_mesh_fs_params[18].x);\n    int _1709 = int(fa_mesh_fs_params[18].y);\n    int param = (int(fa_mesh_fs_params[19].x) + (((clamp(int(floor(log2(max(dot(fa_mesh_fs_params[17].xyz, world_pos) + fa_mesh_fs_params[17].w, fa_mesh_fs_params[18].w) / fa_mesh_fs_params[18].w) * fa_mesh_fs_params[18].z)), 0, int(fa_mesh_fs_params[19].y) - 1) * _1709) + clamp(int(floor(((_1701.y * 0.5) + 0.5) * fa_mesh_fs_params[18].y)), 0, _1709 - 1)) * _1705)) + clamp(int(floor(((_1701.x * 0.5) + 0.5) * fa_mesh_fs_params[18].x)), 0, _1705 - 1);\n    return fa_light_texel(param);\n}\n\nivec2 fa_cluster_lookup(vec3 world_pos)\n{\n    vec3 param = world_pos;\n    vec4 _1785 = fa_cluster_texel(param);\n    return ivec2(int(_1785.x), int(_1785.y));\n}\n\nvoid fa_cluster_begin(vec3 world_pos)\n{\n    fa_cl_ndir = int(fa_mesh_fs_params[19].z);\n    vec3 param = world_pos;\n    ivec2 _5870 = fa_cluster_lookup(param);\n    fa_cl_slot = _5870.x;\n    fa_cl_local = _5870.y;\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nvec3 fa_linear_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_tex_fix(inout vec3 c, float mode)\n{\n    if (mode > 1.5)\n    {\n        vec3 param = c;\n        vec3 _7059 = fa_linear_to_srgb(param);\n        c = _7059;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            vec3 param_1 = c;\n            vec3 _7067 = fa_srgb_to_linear(param_1);\n            c = _7067;\n        }\n    }\n    return c;\n}\n\nvec3 fa_tangent_normal(SurfaceInput i, vec3 m)\n{\n    vec3 _540;\n    if (i.front_facing)\n    {\n        _540 = i.world_normal;\n    }\n    else\n    {\n        _540 = -i.world_normal;\n    }\n    vec3 _564 = normalize(i.world_tangent.xyz - (_540 * dot(_540, i.world_tangent.xyz)));\n    vec3 _591 = normalize(((_564 * m.x) + ((cross(_540, _564) * i.world_tangent.w) * m.y)) + (_540 * m.z));\n    vec3 _594;\n    if (i.front_facing)\n    {\n        _594 = _591;\n    }\n    else\n    {\n        _594 = -_591;\n    }\n    return _594;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    vec4 base_t = texture(fa_tex_fa_smp, i.uv);\n    float param = fa_mesh_fs_params[6].w;\n    float param_1 = 1.0;\n    vec3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    vec3 _7098 = fa_tex_fix(param_2, param_3);\n    vec4 _9360 = base_t;\n    _9360.x = _7098.x;\n    _9360.y = _7098.y;\n    _9360.z = _7098.z;\n    base_t = _9360;\n    vec4 _7112 = (_9360 * fa_mesh_fs_params[2]) * i.vertex_color;\n    vec3 _9136 = i.world_normal;\n    if (fa_mesh_fs_params[6].z > 0.5)\n    {\n        float param_4 = fa_mesh_fs_params[6].w;\n        float param_5 = 16.0;\n        vec3 param_6 = texture(fa_normal_tex_fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        vec3 _7144 = fa_tex_fix(param_6, param_7);\n        vec3 _7147 = (_7144 * 2.0) - vec3(1.0);\n        vec2 _7152 = _7147.xy * fa_mesh_fs_params[6].x;\n        vec3 _9368 = _7147;\n        _9368.x = _7152.x;\n        _9368.y = _7152.y;\n        SurfaceInput param_8 = i;\n        vec3 param_9 = _9368;\n        _9136 = fa_tangent_normal(param_8, param_9);\n    }\n    vec4 mrt = texture(fa_mr_tex_fa_smp, i.uv);\n    float param_10 = fa_mesh_fs_params[6].w;\n    float param_11 = 64.0;\n    vec3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    vec3 _7180 = fa_tex_fix(param_12, param_13);\n    vec4 _9371 = mrt;\n    _9371.x = _7180.x;\n    _9371.y = _7180.y;\n    _9371.z = _7180.z;\n    mrt = _9371;\n    vec4 _7208 = texture(fa_occlusion_tex_fa_smp, i.uv);\n    float param_14 = fa_mesh_fs_params[6].w;\n    float param_15 = 256.0;\n    vec3 param_16 = _7208.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    vec3 _7219 = fa_tex_fix(param_16, param_17);\n    float param_18 = fa_mesh_fs_params[6].w;\n    float param_19 = 4.0;\n    vec3 param_20 = texture(fa_emissive_tex_fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    vec3 _7249 = fa_tex_fix(param_20, param_21);\n    float _9141 = fa_mesh_fs_params[20].x;\n    float _9142 = fa_mesh_fs_params[20].y;\n    float _9145 = fa_mesh_fs_params[20].z;\n    float _9144 = fa_mesh_fs_params[21].w;\n    float _9147 = fa_mesh_fs_params[22].x;\n    if (fa_mesh_fs_params[22].z > 0.5)\n    {\n        if (mod(fa_mesh_fs_params[22].z, 2.0) > 0.5)\n        {\n            _9141 *= _7219.y;\n            _9142 *= _7219.z;\n            _9144 *= _7208.w;\n        }\n        if (fa_mesh_fs_params[22].z > 1.5)\n        {\n            _9145 *= mrt.x;\n            _9147 *= mrt.w;\n        }\n    }\n    return Surface(_7112.xyz, _7112.w, _9136, clamp(fa_mesh_fs_params[5].x * _7180.z, 0.0, 1.0), clamp(fa_mesh_fs_params[5].y * _7180.y, 0.0500000007450580596923828125, 1.0), 1.0 + (fa_mesh_fs_params[6].y * (_7219.x - 1.0)), fa_mesh_fs_params[3].xyz + (fa_mesh_fs_params[4].xyz * _7249), _9141, _9142, fa_mesh_fs_params[21].xyz, _9144, _9145, fa_mesh_fs_params[20].w, _9147, fa_mesh_fs_params[22].y, fa_mesh_fs_params[23].xyz, fa_mesh_fs_params[30].x, fa_mesh_fs_params[30].y, fa_mesh_fs_params[31].xyz, fa_mesh_fs_params[30].z);\n}\n\nvoid surface(SurfaceInput i, inout Surface s)\n{\n    s.emission += ((tint.xyz * tint.w) * fa_material[0].x);\n}\n\nvec4 fa_decal_tile(vec4 rect, vec2 uv, vec2 atlas, vec2 ddx, vec2 ddy)\n{\n    vec2 _1865 = rect.zw - rect.xy;\n    vec2 _1869 = _1865 * atlas;\n    vec2 _1873 = ddx * _1869;\n    vec2 _1877 = ddy * _1869;\n    return textureLod(fa_decal_tex_fa_env_smp, rect.xy + (clamp(uv, vec2(0.0), vec2(1.0)) * _1865), clamp(0.5 * log2(max(max(dot(_1873, _1873), dot(_1877, _1877)), 9.9999999392252902907785028219223e-09)), 0.0, 3.0));\n}\n\nvec3 fa_dc_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_dc_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvoid fa_apply_decals(vec3 world_pos, vec3 geo_normal, inout vec3 albedo, inout vec3 normal)\n{\n    bool _1910 = fa_mesh_fs_params[10].y < 0.5;\n    bool _1917;\n    if (!_1910)\n    {\n        _1917 = fa_mesh_fs_params[10].w < 0.5;\n    }\n    else\n    {\n        _1917 = _1910;\n    }\n    if (_1917)\n    {\n        return;\n    }\n    vec3 _1923 = dFdx(world_pos);\n    vec3 _1926 = dFdy(world_pos);\n    vec3 param = world_pos;\n    vec4 _1930 = fa_cluster_texel(param);\n    int _1934 = int(_1930.w);\n    if (_1934 < 1)\n    {\n        return;\n    }\n    int _1944 = int(fa_mesh_fs_params[10].y + 0.5);\n    int param_1 = _1944;\n    vec4 _1948 = fa_light_texel(param_1);\n    vec2 _1951 = _1948.yz;\n    int _1955 = int(_1948.w);\n    int param_2 = _1944 + 1;\n    vec4 _1960 = fa_light_texel(param_2);\n    float _1961 = _1960.x;\n    int _1967 = int(fa_mesh_fs_params[10].w + 0.5) - 1;\n    int _1971 = int(_1930.z);\n    vec3 _2236;\n    for (int k = 0; k < _1934; k++)\n    {\n        int _1984 = _1971 + k;\n        int param_3 = _1955 + (_1984 >> 2);\n        int _2001 = (_1944 + 2) + (int(fa_light_texel(param_3)[_1984 & 3]) * 7);\n        int param_4 = _2001 + 6;\n        vec4 _2006 = fa_light_texel(param_4);\n        if (((int(_2006.w + 0.5) >> _1967) & 1) == 0)\n        {\n            continue;\n        }\n        int param_5 = _2001;\n        vec4 _2021 = fa_light_texel(param_5);\n        int param_6 = _2001 + 1;\n        vec4 _2026 = fa_light_texel(param_6);\n        int param_7 = _2001 + 2;\n        vec4 _2031 = fa_light_texel(param_7);\n        vec3 _2034 = _2021.xyz;\n        float _2039 = dot(_2034, world_pos) + _2021.w;\n        vec3 _2041 = _2026.xyz;\n        float _2046 = dot(_2041, world_pos) + _2026.w;\n        vec3 _2048 = _2031.xyz;\n        float _2053 = dot(_2048, world_pos) + _2031.w;\n        bool _2058 = abs(_2039) > 0.5;\n        bool _2066;\n        if (!_2058)\n        {\n            _2066 = abs(_2046) > 0.5;\n        }\n        else\n        {\n            _2066 = _2058;\n        }\n        bool _2074;\n        if (!_2066)\n        {\n            _2074 = abs(_2053) > 0.5;\n        }\n        else\n        {\n            _2074 = _2066;\n        }\n        if (_2074)\n        {\n            continue;\n        }\n        float _2089 = clamp(dot(geo_normal, normalize(_2048)) * _2006.z, 0.0, 1.0);\n        if (_2089 <= 0.0)\n        {\n            continue;\n        }\n        float _2109 = (clamp((0.5 - abs(_2053)) * 10.0, 0.0, 1.0) * _2089) * _2006.x;\n        vec2 _2117 = vec2(_2039 + 0.5, 0.5 - _2046);\n        vec2 _2127 = vec2(dot(_2034, _1923), dot(_2041, _1923));\n        vec2 _2137 = vec2(dot(_2034, _1926), dot(_2041, _1926));\n        int param_8 = _2001 + 5;\n        vec4 _2142 = fa_light_texel(param_8);\n        int param_9 = _2001 + 3;\n        vec4 _2147 = fa_light_texel(param_9);\n        int param_10 = _2001 + 4;\n        vec4 _2152 = fa_light_texel(param_10);\n        float tex_a = 1.0;\n        vec3 col = _2142.xyz;\n        bool _2162 = _2147.z > _2147.x;\n        if (_2162)\n        {\n            vec4 param_11 = _2147;\n            vec2 param_12 = _2117;\n            vec2 param_13 = _1951;\n            vec2 param_14 = _2127;\n            vec2 param_15 = _2137;\n            vec4 tx = fa_decal_tile(param_11, param_12, param_13, param_14, param_15);\n            if ((_1961 > 0.5) && (_1961 < 1.5))\n            {\n                vec3 param_16 = tx.xyz;\n                vec3 _2188 = fa_dc_to_linear(param_16);\n                vec4 _9224 = tx;\n                _9224.x = _2188.x;\n                _9224.y = _2188.y;\n                _9224.z = _2188.z;\n                tx = _9224;\n            }\n            col *= tx.xyz;\n            tex_a = tx.w;\n        }\n        albedo = mix(albedo, col, vec3(clamp((_2109 * tex_a) * _2142.w, 0.0, 1.0)));\n        if (_2152.z > _2152.x)\n        {\n            vec4 param_17 = _2152;\n            vec2 param_18 = _2117;\n            vec2 param_19 = _1951;\n            vec2 param_20 = _2127;\n            vec2 param_21 = _2137;\n            vec4 _2232 = fa_decal_tile(param_17, param_18, param_19, param_20, param_21);\n            if (_1961 > 1.5)\n            {\n                vec3 param_22 = _2232.xyz;\n                vec3 _2242 = fa_dc_to_srgb(param_22);\n                _2236 = _2242;\n            }\n            else\n            {\n                _2236 = _2232.xyz;\n            }\n            vec3 _2251 = (_2236 * 2.0) - vec3(1.0);\n            vec2 _2256 = _2251.xy * _2006.y;\n            vec3 _2278 = (normalize(_2034) * _2256.x) + (normalize(_2041) * _2256.y);\n            vec3 _2281 = normalize(normal);\n            normal = normalize(mix(_2281, normalize((_2281 * max(_2251.z, 0.0500000007450580596923828125)) + (_2278 - (_2281 * dot(_2281, _2278)))), vec3(clamp(_2109 * (_2162 ? tex_a : 1.0), 0.0, 1.0))));\n        }\n    }\n}\n\nvoid fa_lod_dither()\n{\n    if (fa_mesh_fs_params[52].w != 0.0)\n    {\n        float _630 = fract(52.98291778564453125 * fract(dot(gl_FragCoord.xy, vec2(0.067110560834407806396484375, 0.005837149918079376220703125))));\n        bool _633;\n        if (fa_mesh_fs_params[52].w > 0.0)\n        {\n            _633 = _630 >= fa_mesh_fs_params[52].w;\n        }\n        else\n        {\n            _633 = _630 < (-fa_mesh_fs_params[52].w);\n        }\n        if (_633)\n        {\n            discard;\n        }\n    }\n}\n\nfloat fa_sheen_albedo(float ndv, float rough)\n{\n    float _4320 = min(sqrt(max(rough - 0.100000001490116119384765625, 0.0) * 1.111111164093017578125) * 6.0, 5.999000072479248046875);\n    float _4328 = min(sqrt(clamp(ndv, 0.0, 1.0)) * 8.0, 7.999000072479248046875);\n    int _4331 = int(_4320);\n    int _4334 = int(_4328);\n    float _4344 = _4328 - float(_4334);\n    int _4399 = (_4331 * 9) + _4334;\n    int _4419 = ((_4331 + 1) * 9) + _4334;\n    return mix(mix(_4395[_4399], _4395[_4399 + 1], _4344), mix(_4395[_4419], _4395[_4419 + 1], _4344), _4320 - float(_4331));\n}\n\nFaLayers fa_layers_setup(SurfaceInput i, Surface s, vec3 n, vec3 v, float metallic, float roughness, inout vec3 f0)\n{\n    bool _9059 = false;\n    float _9060 = 1.0;\n    float _9061 = 1.0;\n    float _9062 = 1.0;\n    float _9063 = 0.0;\n    float _9064 = 0.0;\n    float _9065 = 0.0;\n    float _9066 = 0.0;\n    float _9068 = 1.0;\n    bool _9069 = false;\n    vec3 _9070 = vec3(0.0);\n    float _9071 = 1.0;\n    float _9072 = 1.0;\n    float _9073 = 1.0;\n    float _9074 = 0.0;\n    float _9075 = 0.0;\n    vec3 _9076 = vec3(1.0, 0.0, 0.0);\n    vec3 _9077 = vec3(0.0, 0.0, 1.0);\n    float _9078 = 1.0;\n    float _9079 = 1.0;\n    float _4470 = clamp(s.specular, 0.0, 1.0);\n    float _4474 = clamp(s.ior, 1.0, 3.0);\n    bool _4479 = (_4470 != 1.0) || (_4474 != 1.5);\n    bool _4488;\n    if (!_4479)\n    {\n        _4488 = any(notEqual(s.specular_color, vec3(1.0)));\n    }\n    else\n    {\n        _4488 = _4479;\n    }\n    if (_4488)\n    {\n        float _4496 = (_4474 - 1.0) / (_4474 + 1.0);\n        f0 = mix(min(vec3(_4496 * _4496) * max(s.specular_color, vec3(0.0)), vec3(1.0)) * _4470, s.albedo, vec3(metallic));\n        _9060 = mix(_4470, 1.0, metallic);\n        _9059 = true;\n    }\n    float _4523 = clamp(s.clearcoat, 0.0, 1.0);\n    if (_4523 > 0.0)\n    {\n        float _4531 = clamp(s.clearcoat_roughness, 0.0500000007450580596923828125, 1.0);\n        _9063 = _4523;\n        _9064 = _4531;\n        float _4538 = _4531 * _4531;\n        _9065 = _4538;\n        _9066 = _4538 * _4538;\n        float _4550 = max(dot(i.world_normal, v), 9.9999997473787516355514526367188e-05);\n        _9068 = _4550;\n        _9061 = 1.0 - (_4523 * (0.039999999105930328369140625 + (0.959999978542327880859375 * pow(clamp(1.0 - _4550, 0.0, 1.0), 5.0))));\n        _9059 = true;\n    }\n    vec3 _4569 = max(s.sheen_color, vec3(0.0));\n    float _4578 = max(_4569.x, max(_4569.y, _4569.z));\n    if (_4578 > 0.0)\n    {\n        float _4586 = clamp(s.sheen_roughness, 0.100000001490116119384765625, 1.0);\n        _9069 = true;\n        _9070 = _4569;\n        _9071 = _4586;\n        _9072 = _4586 * _4586;\n        float param = max(dot(n, v), 9.9999997473787516355514526367188e-05);\n        float param_1 = _4586;\n        float _4603 = fa_sheen_albedo(param, param_1);\n        _9074 = _4603;\n        _9073 = 1.0 - min(_4578 * _4603, 1.0);\n        _9059 = true;\n    }\n    _9062 = _9061 * _9073;\n    float _4622 = clamp(s.anisotropy, -1.0, 1.0);\n    if (_4622 != 0.0)\n    {\n        vec3 _4637 = i.world_tangent.xyz - (n * dot(n, i.world_tangent.xyz));\n        vec3 t = _4637;\n        if (dot(_4637, _4637) < 9.9999999392252902907785028219223e-09)\n        {\n            bvec3 _4649 = bvec3(abs(n.y) < 0.9900000095367431640625);\n            t = cross(vec3(_4649.x ? vec3(0.0, 1.0, 0.0).x : vec3(1.0, 0.0, 0.0).x, _4649.y ? vec3(0.0, 1.0, 0.0).y : vec3(1.0, 0.0, 0.0).y, _4649.z ? vec3(0.0, 1.0, 0.0).z : vec3(1.0, 0.0, 0.0).z), n);\n        }\n        vec3 _4653 = t;\n        vec3 _4654 = normalize(_4653);\n        t = _4654;\n        vec3 _4679 = normalize((_4654 * cos(s.anisotropy_rotation)) + ((cross(n, _4654) * ((i.world_tangent.w < 0.0) ? (-1.0) : 1.0)) * sin(s.anisotropy_rotation)));\n        _9076 = _4679;\n        _9077 = cross(n, _4679);\n        float _4689 = roughness * roughness;\n        float _4695 = mix(_4689, 1.0, _4622 * _4622);\n        bool _4697 = _4622 > 0.0;\n        _9078 = _4697 ? _4695 : _4689;\n        _9079 = _4697 ? _4689 : _4695;\n        _9075 = _4622;\n        _9059 = true;\n    }\n    return FaLayers(_9059, _9060, _9061, _9062, _9063, _9064, _9065, _9066, i.world_normal, _9068, _9069, _9070, _9071, _9072, _9073, _9074, _9075, _9076, _9077, _9078, _9079);\n}\n\nvec2 fa_atlas_size()\n{\n    return vec2(textureSize(fa_probe_atlas_fa_env_smp, 0));\n}\n\nvec3 fa_probe_sh_coef(vec2 origin, float res, int k)\n{\n    vec3 v = textureLod(fa_probe_atlas_fa_env_smp, (origin + vec2(float(k) + 0.5, res + 2.5)) / fa_atlas_size(), 0.0).xyz;\n    if (fa_mesh_fs_params[41].y > 0.5)\n    {\n        v = ((v * 255.0) - vec3(128.0)) * 0.03149606287479400634765625;\n    }\n    return v;\n}\n\nvec3 fa_sh_eval(vec3 c[9], vec3 n)\n{\n    vec3 _3488 = max((((c[0] * 0.2820948064327239990234375) + (((c[1] * (0.3257350027561187744140625 * n.y)) + (c[2] * (0.3257350027561187744140625 * n.z))) + (c[3] * (0.3257350027561187744140625 * n.x)))) + (((c[4] * ((0.2731371223926544189453125 * n.x) * n.y)) + (c[5] * ((0.2731371223926544189453125 * n.y) * n.z))) + (c[6] * (0.078847892582416534423828125 * (((3.0 * n.z) * n.z) - 1.0))))) + ((c[7] * ((0.2731371223926544189453125 * n.x) * n.z)) + (c[8] * (0.13656856119632720947265625 * ((n.x * n.x) - (n.y * n.y))))), vec3(0.0));\n    return _3488;\n}\n\nvec3 fa_ambient_light(vec3 n)\n{\n    float _4101 = (1.0 - fa_mesh_fs_params[42].w) - fa_mesh_fs_params[47].w;\n    vec3 amb = vec3(0.0);\n    bool _4106 = fa_mesh_fs_params[11].w > 0.5;\n    vec3 c[9];\n    for (int k = 0; k < 9; k++)\n    {\n        c[k] = vec3(0.0);\n    }\n    if (_4101 > 0.0005000000237487256526947021484375)\n    {\n        if (_4106)\n        {\n            for (int k_1 = 0; k_1 < 9; k_1++)\n            {\n                vec2 param = fa_mesh_fs_params[41].zw;\n                float param_1 = 128.0;\n                int param_2 = k_1;\n                c[k_1] = fa_probe_sh_coef(param, param_1, param_2) * _4101;\n            }\n        }\n        else\n        {\n            amb = fa_mesh_fs_params[1].xyz * _4101;\n        }\n    }\n    bool _4157 = fa_mesh_fs_params[42].w > 0.0;\n    if (_4157)\n    {\n        for (int k_2 = 0; k_2 < 9; k_2++)\n        {\n            vec2 param_3 = fa_mesh_fs_params[42].xy;\n            float param_4 = fa_mesh_fs_params[42].z;\n            int param_5 = k_2;\n            c[k_2] += (fa_probe_sh_coef(param_3, param_4, param_5) * fa_mesh_fs_params[42].w);\n        }\n    }\n    bool _4188 = fa_mesh_fs_params[47].w > 0.0;\n    if (_4188)\n    {\n        for (int k_3 = 0; k_3 < 9; k_3++)\n        {\n            vec2 param_6 = fa_mesh_fs_params[47].xy;\n            float param_7 = fa_mesh_fs_params[47].z;\n            int param_8 = k_3;\n            c[k_3] += (fa_probe_sh_coef(param_6, param_7, param_8) * fa_mesh_fs_params[47].w);\n        }\n    }\n    if ((_4106 || _4157) || _4188)\n    {\n        vec3 param_9[9] = c;\n        vec3 param_10 = n;\n        amb += fa_sh_eval(param_9, param_10);\n    }\n    return amb;\n}\n\nvec4 fa_gi_fetch(vec2 texel)\n{\n    return textureLod(fa_probe_atlas_fa_env_smp, texel / fa_atlas_size(), 0.0);\n}\n\nvec2 fa_oct_encode(vec3 d)\n{\n    vec3 _3508 = d / vec3(max((abs(d.x) + abs(d.y)) + abs(d.z), 9.9999999600419720025001879548654e-13));\n    float _3511 = _3508.x;\n    float _3513 = _3508.z;\n    vec2 e = vec2(_3511, _3513);\n    if (_3508.y < 0.0)\n    {\n        e = vec2((1.0 - abs(_3513)) * ((_3511 < 0.0) ? (-1.0) : 1.0), (1.0 - abs(_3511)) * ((_3513 < 0.0) ? (-1.0) : 1.0));\n    }\n    return e;\n}\n\nvec3 fa_gi_grid(int rec, vec3 n, vec3 v, out float cover)\n{\n    cover = 0.0;\n    int param = rec;\n    vec4 _7359 = fa_light_texel(param);\n    int param_1 = rec + 1;\n    vec4 _7364 = fa_light_texel(param_1);\n    int param_2 = rec + 2;\n    vec4 _7369 = fa_light_texel(param_2);\n    int param_3 = rec + 3;\n    vec4 _7374 = fa_light_texel(param_3);\n    bool _7377 = _7374.z < 0.5;\n    bool _7385;\n    if (!_7377)\n    {\n        _7385 = fa_atlas_size().y < 1155.0;\n    }\n    else\n    {\n        _7385 = _7377;\n    }\n    if (_7385)\n    {\n        return vec3(0.0);\n    }\n    float _7392 = max(_7359.w, 9.9999997473787516355514526367188e-05);\n    vec3 _7395 = _7364.xyz;\n    vec3 _7399 = _7359.xyz;\n    vec3 _7403 = (fa_world_pos - _7399) / vec3(_7392);\n    vec3 _7412 = min(_7403 + vec3(0.5), (_7395 - vec3(0.5)) - _7403);\n    float _7421 = min(_7412.x, min(_7412.y, _7412.z));\n    if (!(_7421 > 0.0))\n    {\n        return vec3(0.0);\n    }\n    vec3 _7436 = _7395 - vec3(1.0);\n    vec3 _7437 = clamp(_7403, vec3(0.0), _7436);\n    vec3 _7445 = min(floor(_7437), max(_7395 - vec3(2.0), vec3(0.0)));\n    vec3 _7449 = _7437 - _7445;\n    vec3 _7460 = fa_world_pos + (((n * 0.800000011920928955078125) + (v * 0.20000000298023223876953125)) * (0.20000000298023223876953125 * _7392));\n    int _7465 = int(_7369.y + 0.5);\n    float _7470 = 0.3257350027561187744140625 * n.y;\n    float _7474 = 0.3257350027561187744140625 * n.z;\n    float _7478 = 0.3257350027561187744140625 * n.x;\n    float _7485 = (0.2731371223926544189453125 * n.x) * n.y;\n    float _7492 = (0.2731371223926544189453125 * n.y) * n.z;\n    float _7501 = 0.078847892582416534423828125 * (((3.0 * n.z) * n.z) - 1.0);\n    float _7508 = (0.2731371223926544189453125 * n.x) * n.z;\n    float _7521 = 0.13656856119632720947265625 * ((n.x * n.x) - (n.y * n.y));\n    vec3 acc = vec3(0.0);\n    float wsum = 0.0;\n    int _7528 = 8 + int(_7374.w);\n    float _7555;\n    float _7568;\n    float _7582;\n    for (int k = 0; k < _7528; k++)\n    {\n        float _7541 = float(k & 1);\n        float _7545 = float((k >> 1) & 1);\n        float _7549 = float((k >> 2) & 1);\n        if (_7541 > 0.5)\n        {\n            _7555 = _7449.x;\n        }\n        else\n        {\n            _7555 = 1.0 - _7449.x;\n        }\n        if (_7545 > 0.5)\n        {\n            _7568 = _7449.y;\n        }\n        else\n        {\n            _7568 = 1.0 - _7449.y;\n        }\n        if (_7549 > 0.5)\n        {\n            _7582 = _7449.z;\n        }\n        else\n        {\n            _7582 = 1.0 - _7449.z;\n        }\n        float _7592 = (_7555 * _7568) * _7582;\n        if (!(_7592 > 0.0))\n        {\n            continue;\n        }\n        vec3 _7605 = min(_7445 + vec3(_7541, _7545, _7549), _7436);\n        int _7625 = int(((_7369.x + _7605.x) + (_7364.x * (_7605.y + (_7364.y * _7605.z)))) + 0.5);\n        vec2 _7640 = vec2(float(_7625 % _7465) * 10.0, 1024.0 + (float(_7625 / _7465) * 11.0));\n        vec2 param_4 = _7640 + vec2(9.5, 10.5);\n        vec4 _7648 = fa_gi_fetch(param_4);\n        bool _7651 = _7648.y < 0.5;\n        bool _7660;\n        if (!_7651)\n        {\n            _7660 = _7648.x > _7374.y;\n        }\n        else\n        {\n            _7660 = _7651;\n        }\n        if (_7660)\n        {\n            continue;\n        }\n        vec3 _7672 = _7460 - (_7399 + (_7605 * _7392));\n        float _7675 = length(_7672);\n        vec3 _7681 = _7672 / vec3(max(_7675, 9.9999997473787516355514526367188e-05));\n        float _7691 = max(9.9999997473787516355514526367188e-05, (dot(-_7681, n) + 1.0) * 0.5);\n        float w = _7592 * (_7691 * _7691);\n        vec3 param_5 = _7681;\n        vec2 param_6 = (_7640 + vec2(1.0)) + (((fa_oct_encode(param_5) * 0.5) + vec2(0.5)) * 8.0);\n        vec4 _7710 = fa_gi_fetch(param_6);\n        float _7717 = _7675 / max(_7369.z, 9.9999997473787516355514526367188e-05);\n        float _7720 = _7710.x;\n        if (_7717 > _7720)\n        {\n            float _7733 = max(_7710.y - (_7720 * _7720), 0.0);\n            float _7738 = _7717 - _7720;\n            float _7747 = _7733 / max(_7733 + (_7738 * _7738), 9.9999999600419720025001879548654e-13);\n            w *= ((_7747 * _7747) * _7747);\n        }\n        if (!(w > 0.0))\n        {\n            continue;\n        }\n        vec2 param_7 = _7640 + vec2(0.5, 10.5);\n        vec2 param_8 = _7640 + vec2(1.5, 10.5);\n        vec2 param_9 = _7640 + vec2(2.5, 10.5);\n        vec2 param_10 = _7640 + vec2(3.5, 10.5);\n        vec2 param_11 = _7640 + vec2(4.5, 10.5);\n        vec2 param_12 = _7640 + vec2(5.5, 10.5);\n        vec2 param_13 = _7640 + vec2(6.5, 10.5);\n        vec2 param_14 = _7640 + vec2(7.5, 10.5);\n        vec2 param_15 = _7640 + vec2(8.5, 10.5);\n        acc += ((((((((((fa_gi_fetch(param_7).xyz * 0.2820948064327239990234375) + (fa_gi_fetch(param_8).xyz * _7470)) + (fa_gi_fetch(param_9).xyz * _7474)) + (fa_gi_fetch(param_10).xyz * _7478)) + (fa_gi_fetch(param_11).xyz * _7485)) + (fa_gi_fetch(param_12).xyz * _7492)) + (fa_gi_fetch(param_13).xyz * _7501)) + (fa_gi_fetch(param_14).xyz * _7508)) + (fa_gi_fetch(param_15).xyz * _7521)) * w);\n        wsum += w;\n    }\n    if (!(wsum > 9.9999997473787516355514526367188e-06))\n    {\n        return vec3(0.0);\n    }\n    cover = smoothstep(0.0, 1.0, clamp(_7421 * 2.0, 0.0, 1.0)) * smoothstep(0.0, 0.0199999995529651641845703125, wsum);\n    float _7871;\n    if (fa_mesh_fs_params[52].z > 0.5)\n    {\n        _7871 = _7374.x;\n    }\n    else\n    {\n        _7871 = 1.0;\n    }\n    return max(acc / vec3(wsum), vec3(0.0)) * (_7369.w * _7871);\n}\n\nvec3 fa_gi_light(vec3 n, inout float left)\n{\n    left = 1.0;\n    vec3 acc = vec3(0.0);\n    vec3 _7895 = normalize(fa_mesh_fs_params[0].xyz - fa_world_pos);\n    int _7900 = int(fa_mesh_fs_params[52].x + 0.5);\n    int _7905 = int(fa_mesh_fs_params[52].y + 0.5);\n    float param_3;\n    for (int k = 0; (k < _7905) && (k < 8); k++)\n    {\n        int param = _7900 + (4 * k);\n        vec3 param_1 = n;\n        vec3 param_2 = _7895;\n        vec3 _7930 = fa_gi_grid(param, param_1, param_2, param_3);\n        float _7935 = param_3 * left;\n        acc += (_7930 * _7935);\n        left -= _7935;\n        if (left < 0.001000000047497451305389404296875)\n        {\n            left = 0.0;\n            break;\n        }\n    }\n    return acc;\n}\n\nvec3 fa_realtime_or_ambient(vec3 n)\n{\n    vec3 gi = vec3(0.0);\n    float left = 1.0;\n    if (fa_mesh_fs_params[52].y > 0.5)\n    {\n        vec3 param = n;\n        float param_1;\n        vec3 _7964 = fa_gi_light(param, param_1);\n        left = param_1;\n        gi = _7964;\n    }\n    if (left <= 0.0)\n    {\n        return gi;\n    }\n    vec3 param_2 = n;\n    return gi + (fa_ambient_light(param_2) * left);\n}\n\nvec3 fa_indirect_diffuse(vec3 n)\n{\n    if (fa_lm.z > 0.5)\n    {\n        return textureLod(fa_lightmap_fa_env_smp, fa_lm.xy, 0.0).xyz;\n    }\n    if (fa_mesh_fs_params[32].w > 0.0)\n    {\n        vec3 c[9];\n        for (int k = 0; k < 9; k++)\n        {\n            c[k] = fa_mesh_fs_params[k * 1 + 32].xyz;\n        }\n        vec3 param = n;\n        vec3 param_1[9] = c;\n        vec3 param_2 = n;\n        return mix(fa_ambient_light(param), fa_sh_eval(param_1, param_2), vec3(clamp(fa_mesh_fs_params[32].w, 0.0, 1.0)));\n    }\n    vec3 param_3 = n;\n    return fa_realtime_or_ambient(param_3);\n}\n\nint fa_cluster_index(int slot, int n)\n{\n    int param = (int(fa_mesh_fs_params[19].x) + int(fa_mesh_fs_params[19].w)) + ((slot + n) >> 2);\n    vec4 t = fa_light_texel(param);\n    return int(t[(slot + n) & 3]);\n}\n\nint fa_cl_light(int n)\n{\n    if (n < fa_cl_ndir)\n    {\n        return n;\n    }\n    int param = fa_cl_slot;\n    int param_1 = n - fa_cl_ndir;\n    return fa_cluster_index(param, param_1);\n}\n\nint fa_light_base(int li)\n{\n    return li * ((fa_mesh_fs_params[1].w > 4.5) ? 8 : 4);\n}\n\nbool fa_light_baked(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 3;\n    return fa_light_texel(param_1).w > 0.5;\n}\n\nfloat fa_baked_keep(int li)\n{\n    float _5840;\n    if (fa_lm.z > 0.5)\n    {\n        _5840 = 0.0;\n    }\n    else\n    {\n        _5840 = 1.0 - clamp(fa_mesh_fs_params[32].w, 0.0, 1.0);\n    }\n    bool _5851 = _5840 < 1.0;\n    bool _5857;\n    if (_5851)\n    {\n        int param = li;\n        _5857 = fa_light_baked(param);\n    }\n    else\n    {\n        _5857 = _5851;\n    }\n    return _5857 ? _5840 : 1.0;\n}\n\nfloat fa_light_type(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 1;\n    return fa_light_texel(param_1).w;\n}\n\nvec4 fa_atlas_fetch(vec2 texel)\n{\n    return textureLod(fa_light_atlas_fa_env_smp, texel / vec2(textureSize(fa_light_atlas_fa_env_smp, 0)), 0.0);\n}\n\nvec3 fa_cookie_sample(vec2 tile_origin, vec2 uv)\n{\n    vec2 param = (tile_origin + vec2(1.0)) + (clamp(uv, vec2(0.0), vec2(1.0)) * 254.0);\n    return fa_atlas_fetch(param).xyz;\n}\n\nvec3 fa_area_point(vec3 c, vec3 axis, vec3 ru, vec3 uu, float hx, float hy, float shape, vec3 p, vec3 r)\n{\n    bool _883 = dot(r, r) > 0.5;\n    if (shape > 1.5)\n    {\n        vec3 _896 = (c - (ru * hx)) - p;\n        vec3 _902 = ru * (2.0 * hx);\n        float _908 = max(dot(_902, _902), 9.9999999392252902907785028219223e-09);\n        float _912 = dot(_896, _902);\n        float t = clamp((-_912) / _908, 0.0, 1.0);\n        if (_883)\n        {\n            float _927 = dot(r, _902);\n            float _933 = _908 - (_927 * _927);\n            if (abs(_933) > (9.9999997473787516355514526367188e-06 * _908))\n            {\n                t = clamp(((dot(r, _896) * _927) - _912) / _933, 0.0, 1.0);\n            }\n        }\n        return (p + _896) + (_902 * t);\n    }\n    vec3 q = p;\n    float _965 = dot(r, axis);\n    bool _973;\n    if (_883)\n    {\n        _973 = abs(_965) > 9.9999997473787516355514526367188e-05;\n    }\n    else\n    {\n        _973 = _883;\n    }\n    if (_973)\n    {\n        float _983 = dot(c - p, axis) / _965;\n        if (_983 > 0.0)\n        {\n            q = p + (r * _983);\n        }\n    }\n    vec3 _996 = q - c;\n    vec2 xy = vec2(dot(_996, ru), dot(_996, uu));\n    if (shape > 0.5)\n    {\n        float _1011 = length(xy);\n        if (_1011 > hx)\n        {\n            xy *= (hx / _1011);\n        }\n    }\n    else\n    {\n        xy = clamp(xy, vec2(-hx, -hy), vec2(hx, hy));\n    }\n    return (c + (ru * xy.x)) + (uu * xy.y);\n}\n\nint fa_cube_face(vec3 d)\n{\n    vec3 _650 = abs(d);\n    float _652 = _650.x;\n    float _654 = _650.y;\n    bool _655 = _652 >= _654;\n    bool _663;\n    if (_655)\n    {\n        _663 = _652 >= _650.z;\n    }\n    else\n    {\n        _663 = _655;\n    }\n    int _664;\n    if (_663)\n    {\n        _664 = (d.x > 0.0) ? 0 : 1;\n    }\n    else\n    {\n        int _678;\n        if (_654 >= _650.z)\n        {\n            _678 = (d.y > 0.0) ? 2 : 3;\n        }\n        else\n        {\n            _678 = (d.z > 0.0) ? 4 : 5;\n        }\n        _664 = _678;\n    }\n    return _664;\n}\n\nvoid fa_cube_face_basis(int f, out vec3 fwd, out vec3 up)\n{\n    if (f == 0)\n    {\n        fwd = vec3(1.0, 0.0, 0.0);\n        up = vec3(0.0, 1.0, 0.0);\n    }\n    else\n    {\n        if (f == 1)\n        {\n            fwd = vec3(-1.0, 0.0, 0.0);\n            up = vec3(0.0, 1.0, 0.0);\n        }\n        else\n        {\n            if (f == 2)\n            {\n                fwd = vec3(0.0, 1.0, 0.0);\n                up = vec3(0.0, 0.0, 1.0);\n            }\n            else\n            {\n                if (f == 3)\n                {\n                    fwd = vec3(0.0, -1.0, 0.0);\n                    up = vec3(0.0, 0.0, -1.0);\n                }\n                else\n                {\n                    if (f == 4)\n                    {\n                        fwd = vec3(0.0, 0.0, 1.0);\n                        up = vec3(0.0, 1.0, 0.0);\n                    }\n                    else\n                    {\n                        fwd = vec3(0.0, 0.0, -1.0);\n                        up = vec3(0.0, 1.0, 0.0);\n                    }\n                }\n            }\n        }\n    }\n}\n\nfloat fa_ies_sample(vec2 tile_origin, vec3 d, vec3 axis, vec3 right, vec3 up)\n{\n    float _803 = dot(d, right);\n    float _807 = dot(d, up);\n    float _818;\n    if (((_803 * _803) + (_807 * _807)) > 1.0000000133514319600180897396058e-10)\n    {\n        _818 = atan(_807, _803) * 0.15915493667125701904296875;\n    }\n    else\n    {\n        _818 = 0.0;\n    }\n    vec2 param = tile_origin + vec2(1.0 + ((_818 - floor(_818)) * 64.0), 1.0 + (acos(clamp(dot(d, axis), -1.0, 1.0)) * 10.18591594696044921875));\n    return fa_atlas_fetch(param).x;\n}\n\nLightSample fa_light_sample_n(int li, vec3 world_pos, vec3 n)\n{\n    int param = li;\n    int _1049 = fa_light_base(param);\n    bool _1053 = fa_mesh_fs_params[1].w > 4.5;\n    int param_1 = _1049;\n    vec4 _1057 = fa_light_texel(param_1);\n    int param_2 = _1049 + 1;\n    vec4 _1062 = fa_light_texel(param_2);\n    float _1065 = _1062.w;\n    float atten = 1.0;\n    float dist = 0.0;\n    fa_light_tint = vec3(1.0);\n    bool _1077 = _1053 && (_1065 > 2.5);\n    fa_light_is_area = _1077;\n    bool _1079 = _1065 < 0.5;\n    vec3 l;\n    if (_1079)\n    {\n        l = normalize(_1057.xyz);\n        if (_1053)\n        {\n            int param_3 = _1049 + 6;\n            vec4 _1093 = fa_light_texel(param_3);\n            if (_1093.z > 0.5)\n            {\n                int param_4 = _1049 + 4;\n                vec4 _1103 = fa_light_texel(param_4);\n                int param_5 = _1049 + 5;\n                vec4 _1108 = fa_light_texel(param_5);\n                vec2 param_6 = _1093.xy;\n                vec2 param_7 = fract(vec2(dot(world_pos, _1103.xyz) * _1103.w, (-dot(world_pos, _1108.xyz)) * _1108.w) + vec2(0.5));\n                fa_light_tint = fa_cookie_sample(param_6, param_7);\n            }\n        }\n    }\n    else\n    {\n        vec3 _1138 = _1057.xyz;\n        vec3 _1140 = _1138 - world_pos;\n        vec3 to_light = _1140;\n        float _1143 = length(_1140);\n        float reach = _1143;\n        bool front = true;\n        if (_1077)\n        {\n            int param_8 = _1049 + 7;\n            reach = max(_1143 - fa_light_texel(param_8).w, 0.0);\n            int param_9 = _1049 + 4;\n            vec4 _1167 = fa_light_texel(param_9);\n            int param_10 = _1049 + 5;\n            vec4 _1172 = fa_light_texel(param_10);\n            int param_11 = _1049 + 6;\n            vec4 _1177 = fa_light_texel(param_11);\n            float _1178 = _1177.w;\n            int param_12 = _1049 + 2;\n            vec3 _1185 = normalize(fa_light_texel(param_12).xyz);\n            bool _1187 = _1178 > 1.5;\n            bool _1195;\n            if (!_1187)\n            {\n                _1195 = dot(_1185, to_light) < 0.0;\n            }\n            else\n            {\n                _1195 = _1187;\n            }\n            front = _1195;\n            vec3 r = vec3(0.0);\n            vec3 _1204 = fa_mesh_fs_params[0].xyz - world_pos;\n            bool _1208 = dot(n, n) > 0.5;\n            bool _1216;\n            if (_1208)\n            {\n                _1216 = dot(_1204, _1204) > 9.9999999600419720025001879548654e-13;\n            }\n            else\n            {\n                _1216 = _1208;\n            }\n            if (_1216)\n            {\n                r = reflect(-normalize(_1204), normalize(n));\n            }\n            vec3 param_13 = _1138;\n            vec3 param_14 = _1185;\n            vec3 param_15 = _1167.xyz;\n            vec3 param_16 = _1172.xyz;\n            float param_17 = _1167.w;\n            float param_18 = _1172.w;\n            float param_19 = _1178;\n            vec3 param_20 = world_pos;\n            vec3 param_21 = r;\n            to_light = fa_area_point(param_13, param_14, param_15, param_16, param_17, param_18, param_19, param_20, param_21) - world_pos;\n        }\n        float _1252 = length(to_light);\n        dist = _1252;\n        l = to_light / vec3(max(_1252, 9.9999997473787516355514526367188e-05));\n        float _1266 = reach / max(_1057.w, 0.001000000047497451305389404296875);\n        float _1272 = clamp(1.0 - (_1266 * _1266), 0.0, 1.0);\n        float _1274;\n        if (front)\n        {\n            _1274 = _1272 * _1272;\n        }\n        else\n        {\n            _1274 = 0.0;\n        }\n        atten = _1274;\n        bool _1285 = _1065 < 2.5;\n        if ((_1065 > 1.5) && _1285)\n        {\n            int param_22 = _1049 + 2;\n            vec4 _1293 = fa_light_texel(param_22);\n            float _1303 = _1293.w;\n            int param_23 = _1049 + 3;\n            vec4 _1308 = fa_light_texel(param_23);\n            float _1309 = _1308.x;\n            float cos_inner = _1309;\n            if (_1309 > 1.5)\n            {\n                cos_inner = mix(_1303, 1.0, 0.25);\n            }\n            atten *= smoothstep(_1303, cos_inner, dot(-l, normalize(_1293.xyz)));\n        }\n        if (_1053 && (_1065 < 1.5))\n        {\n            int param_24 = _1049 + 6;\n            vec4 _1333 = fa_light_texel(param_24);\n            if (_1333.z > 0.5)\n            {\n                vec3 _1341 = -to_light;\n                int param_25 = _1049 + 4;\n                int param_26 = _1049 + 5;\n                vec3 _1355 = fa_light_texel(param_25).xyz;\n                vec3 _1359 = fa_light_texel(param_26).xyz;\n                vec3 _1368 = vec3(dot(_1341, _1355), dot(_1341, _1359), dot(_1341, cross(_1355, _1359)));\n                vec3 param_27 = _1368;\n                int _1372 = fa_cube_face(param_27);\n                int param_28 = _1372;\n                vec3 param_29;\n                vec3 param_30;\n                fa_cube_face_basis(param_28, param_29, param_30);\n                vec2 _1399 = vec2(dot(_1368, cross(param_29, param_30)), dot(_1368, param_30)) / vec2(max(dot(_1368, param_29), 9.9999997473787516355514526367188e-05));\n                int _1403 = _1372 / 3;\n                vec2 param_31 = _1333.xy + (vec2(float(_1372 - (_1403 * 3)), float(_1403)) * 256.0);\n                vec2 param_32 = vec2(0.5 + (0.5 * _1399.x), 0.5 - (0.5 * _1399.y));\n                fa_light_tint = fa_cookie_sample(param_31, param_32);\n            }\n            int param_33 = _1049 + 7;\n            vec4 _1433 = fa_light_texel(param_33);\n            if (_1433.z > 0.5)\n            {\n                int param_34 = _1049 + 2;\n                int param_35 = _1049 + 4;\n                int param_36 = _1049 + 5;\n                vec2 param_37 = _1433.xy;\n                vec3 param_38 = -l;\n                vec3 param_39 = normalize(fa_light_texel(param_34).xyz);\n                vec3 param_40 = fa_light_texel(param_35).xyz;\n                vec3 param_41 = fa_light_texel(param_36).xyz;\n                atten *= fa_ies_sample(param_37, param_38, param_39, param_40, param_41);\n            }\n        }\n        else\n        {\n            if (_1053 && _1285)\n            {\n                int param_42 = _1049 + 6;\n                vec4 _1480 = fa_light_texel(param_42);\n                int param_43 = _1049 + 7;\n                vec4 _1485 = fa_light_texel(param_43);\n                bool _1488 = _1480.z > 0.5;\n                bool _1495;\n                if (!_1488)\n                {\n                    _1495 = _1485.z > 0.5;\n                }\n                else\n                {\n                    _1495 = _1488;\n                }\n                if (_1495)\n                {\n                    int param_44 = _1049 + 2;\n                    vec4 _1502 = fa_light_texel(param_44);\n                    vec3 _1506 = normalize(_1502.xyz);\n                    int param_45 = _1049 + 4;\n                    vec4 _1511 = fa_light_texel(param_45);\n                    int param_46 = _1049 + 5;\n                    vec4 _1516 = fa_light_texel(param_46);\n                    if (_1488)\n                    {\n                        vec3 _1524 = -to_light;\n                        float _1531 = _1502.w;\n                        float _1547 = 0.5 / max(dot(_1524, _1506) * (sqrt(max(1.0 - (_1531 * _1531), 0.0)) / max(_1531, 0.001000000047497451305389404296875)), 9.9999997473787516355514526367188e-05);\n                        vec2 param_47 = _1480.xy;\n                        vec2 param_48 = vec2(0.5 + (dot(_1524, _1511.xyz) * _1547), 0.5 - (dot(_1524, _1516.xyz) * _1547));\n                        fa_light_tint = fa_cookie_sample(param_47, param_48);\n                    }\n                    if (_1485.z > 0.5)\n                    {\n                        vec2 param_49 = _1485.xy;\n                        vec3 param_50 = -l;\n                        vec3 param_51 = _1506;\n                        vec3 param_52 = _1511.xyz;\n                        vec3 param_53 = _1516.xyz;\n                        atten *= fa_ies_sample(param_49, param_50, param_51, param_52, param_53);\n                    }\n                }\n            }\n        }\n    }\n    vec3 _9047 = _1062.xyz * atten;\n    if (_1053)\n    {\n        _9047 *= fa_light_tint;\n    }\n    int _1616;\n    if (_1079)\n    {\n        _1616 = 0;\n    }\n    else\n    {\n        _1616 = ((_1065 > 1.5) && (_1065 < 2.5)) ? 2 : 1;\n    }\n    return LightSample(l, _9047, atten, 1.0, dist, _1616);\n}\n\nfloat fa_shadow_split_at(int i)\n{\n    float _2342;\n    if (i == 0)\n    {\n        _2342 = fa_shadows[24].x;\n    }\n    else\n    {\n        float _2358;\n        if (i == 1)\n        {\n            _2358 = fa_shadows[24].y;\n        }\n        else\n        {\n            float _2366;\n            if (i == 2)\n            {\n                _2366 = fa_shadows[24].z;\n            }\n            else\n            {\n                _2366 = fa_shadows[24].w;\n            }\n            _2358 = _2366;\n        }\n        _2342 = _2358;\n    }\n    return _2342;\n}\n\nfloat fa_shadow_depth(inout vec2 uv, vec4 rect)\n{\n    uv = clamp(uv, rect.xy, rect.zw);\n    return textureLod(fa_shadow_tex_fa_shadow_smp, uv, 0.0).x;\n}\n\nfloat fa_shadow_fetch(vec2 uv, vec4 rect, vec3 conv)\n{\n    vec2 param = uv;\n    vec4 param_1 = rect;\n    float _2399 = fa_shadow_depth(param, param_1);\n    float _2403;\n    if (conv.x < 0.5)\n    {\n        _2403 = _2399;\n    }\n    else\n    {\n        _2403 = (conv.y * conv.z) / (conv.z - (_2399 * (conv.z - conv.y)));\n    }\n    return _2403;\n}\n\nfloat fa_shadow_noise()\n{\n    return fract(52.98291778564453125 * fract(dot(gl_FragCoord.xy, vec2(0.067110560834407806396484375, 0.005837149918079376220703125))));\n}\n\nvec2 fa_shadow_vogel_turn(vec2 d)\n{\n    return vec2((d.x * (-0.737368881702423095703125)) - (d.y * 0.675490319728851318359375), (d.y * (-0.737368881702423095703125)) + (d.x * 0.675490319728851318359375));\n}\n\nfloat fa_shadow_filter(vec2 uv, vec4 rect, float zr, float texel_m, float unit, float reach, float plane, vec3 conv, int mode, float k)\n{\n    if (mode == 1)\n    {\n        vec2 param = uv;\n        vec4 param_1 = rect;\n        vec3 param_2 = conv;\n        return float(zr <= fa_shadow_fetch(param, param_1, param_2));\n    }\n    float _2449 = fa_shadow_noise() * 6.283185482025146484375;\n    vec2 _2455 = vec2(cos(_2449), sin(_2449));\n    vec2 dir = _2455;\n    float radius = 1.5;\n    if (mode == 2)\n    {\n        float _2464;\n        if (k < 0.0)\n        {\n            _2464 = (-k) / max(zr, 0.100000001490116119384765625);\n        }\n        else\n        {\n            _2464 = k;\n        }\n        float _2483 = clamp((_2464 * reach) / texel_m, 3.0, 12.0);\n        float sum = 0.0;\n        float cnt = 0.0;\n        for (int i = 0; i < 16; i++)\n        {\n            float _2502 = sqrt((float(i) + 0.5) * 0.0625) * _2483;\n            vec2 param_3 = uv + (dir * (fa_shadows[26].zw * _2502));\n            vec4 param_4 = rect;\n            vec3 param_5 = conv;\n            float _2516 = fa_shadow_fetch(param_3, param_4, param_5);\n            if (_2516 < (zr - (_2502 * plane)))\n            {\n                sum += _2516;\n                cnt += 1.0;\n            }\n            vec2 param_6 = dir;\n            dir = fa_shadow_vogel_turn(param_6);\n        }\n        if (cnt < 0.5)\n        {\n            return 1.0;\n        }\n        float _2544 = sum / cnt;\n        float _2554;\n        if (k < 0.0)\n        {\n            _2554 = (-k) / max(_2544, 0.0500000007450580596923828125);\n        }\n        else\n        {\n            _2554 = k;\n        }\n        radius = clamp(((max(zr - _2544, 0.0) * unit) * _2554) / texel_m, 1.5, 16.0);\n        dir = _2455;\n    }\n    float lit = 0.0;\n    int _2580 = (mode == 2) ? 24 : 16;\n    for (int i_1 = 0; i_1 < _2580; i_1++)\n    {\n        float _2599 = sqrt((float(i_1) + 0.5) / float(_2580)) * radius;\n        vec2 param_7 = uv + (dir * (fa_shadows[26].zw * _2599));\n        vec4 param_8 = rect;\n        vec3 param_9 = conv;\n        lit += float((zr - (_2599 * plane)) <= fa_shadow_fetch(param_7, param_8, param_9));\n        vec2 param_10 = dir;\n        dir = fa_shadow_vogel_turn(param_10);\n    }\n    return lit / float(_2580);\n}\n\nfloat fa_shadow_cascade(int ci, vec3 world, vec3 n, vec3 l)\n{\n    float _2645 = max(fa_shadows[ci * 1 + 20].y, 0.001000000047497451305389404296875);\n    float _2650 = clamp(dot(n, l), 0.0, 1.0);\n    float _2656 = sqrt(1.0 - (_2650 * _2650));\n    float _2664 = min(_2656 / max(_2650, 0.20000000298023223876953125), 4.0);\n    float _2669;\n    if (fa_shadows[26].y > 0.0)\n    {\n        _2669 = fa_shadows[26].y;\n    }\n    else\n    {\n        _2669 = 1.5 * fa_shadows[ci * 1 + 20].x;\n    }\n    vec4 _2694 = mat4(fa_shadows[ci * 4 + 0], fa_shadows[ci * 4 + 1], fa_shadows[ci * 4 + 2], fa_shadows[ci * 4 + 3]) * vec4(world + (n * (_2669 * _2656)), 1.0);\n    float _2701 = _2694.x;\n    bool _2704 = _2701 < fa_shadows[ci * 1 + 16].x;\n    bool _2713;\n    if (!_2704)\n    {\n        _2713 = _2701 > fa_shadows[ci * 1 + 16].z;\n    }\n    else\n    {\n        _2713 = _2704;\n    }\n    bool _2722;\n    if (!_2713)\n    {\n        _2722 = _2694.y < fa_shadows[ci * 1 + 16].y;\n    }\n    else\n    {\n        _2722 = _2713;\n    }\n    bool _2731;\n    if (!_2722)\n    {\n        _2731 = _2694.y > fa_shadows[ci * 1 + 16].w;\n    }\n    else\n    {\n        _2731 = _2722;\n    }\n    bool _2738;\n    if (!_2731)\n    {\n        _2738 = _2694.z > 1.0;\n    }\n    else\n    {\n        _2738 = _2731;\n    }\n    if (_2738)\n    {\n        return -1.0;\n    }\n    float _2746;\n    if (fa_shadows[26].x > 0.0)\n    {\n        _2746 = fa_shadows[26].x;\n    }\n    else\n    {\n        _2746 = 1.5 * fa_shadows[ci * 1 + 20].x;\n    }\n    vec2 param = _2694.xy;\n    vec4 param_1 = fa_shadows[ci * 1 + 16];\n    float param_2 = _2694.z - ((_2746 * (1.0 + (0.5 * _2664))) / _2645);\n    float param_3 = fa_shadows[ci * 1 + 20].x;\n    float param_4 = _2645;\n    float param_5 = _2645 * 0.25;\n    float param_6 = ((fa_shadows[ci * 1 + 20].x * min(_2664, 3.0)) * 0.5) / _2645;\n    vec3 param_7 = vec3(0.0);\n    int param_8 = int(fa_shadows[25].z + 0.5);\n    float param_9 = fa_shadows[25].w;\n    return fa_shadow_filter(param, param_1, param_2, param_3, param_4, param_5, param_6, param_7, param_8, param_9);\n}\n\nfloat fa_shadow_sun(vec3 world, vec3 n, vec3 l)\n{\n    if (fa_mesh_fs_params[5].z < 0.5)\n    {\n        return 1.0;\n    }\n    int _3124 = int(fa_shadows[25].x + 0.5);\n    if (_3124 < 1)\n    {\n        return 1.0;\n    }\n    float _3139 = dot(world - fa_shadows[27].xyz, fa_shadows[28].xyz);\n    int param = _3124 - 1;\n    if (_3139 > fa_shadow_split_at(param))\n    {\n        return 1.0;\n    }\n    int ci = 0;\n    bool _3151 = _3124 > 1;\n    bool _3158;\n    if (_3151)\n    {\n        _3158 = _3139 > fa_shadows[24].x;\n    }\n    else\n    {\n        _3158 = _3151;\n    }\n    if (_3158)\n    {\n        ci = 1;\n    }\n    bool _3162 = _3124 > 2;\n    bool _3169;\n    if (_3162)\n    {\n        _3169 = _3139 > fa_shadows[24].y;\n    }\n    else\n    {\n        _3169 = _3162;\n    }\n    if (_3169)\n    {\n        ci = 2;\n    }\n    bool _3173 = _3124 > 3;\n    bool _3180;\n    if (_3173)\n    {\n        _3180 = _3139 > fa_shadows[24].z;\n    }\n    else\n    {\n        _3180 = _3173;\n    }\n    if (_3180)\n    {\n        ci = 3;\n    }\n    float s = -1.0;\n    float s2 = -1.0;\n    float t = 0.0;\n    int _3191 = min(_3124, 4);\n    float _3232;\n    for (int c = ci; c < _3191; c++)\n    {\n        int param_1 = c;\n        vec3 param_2 = world;\n        vec3 param_3 = n;\n        vec3 param_4 = l;\n        float _3211 = fa_shadow_cascade(param_1, param_2, param_3, param_4);\n        if (s >= 0.0)\n        {\n            s2 = _3211;\n            break;\n        }\n        if (_3211 < 0.0)\n        {\n            continue;\n        }\n        s = _3211;\n        ci = c;\n        if (fa_shadows[25].y > 0.0)\n        {\n            if (ci > 0)\n            {\n                int param_5 = ci - 1;\n                _3232 = fa_shadow_split_at(param_5);\n            }\n            else\n            {\n                _3232 = fa_shadows[28].w;\n            }\n            int param_6 = ci;\n            float _3251 = fa_shadows[25].y * max(fa_shadow_split_at(param_6) - _3232, 9.9999997473787516355514526367188e-05);\n            int param_7 = ci;\n            t = clamp((_3139 - (fa_shadow_split_at(param_7) - _3251)) / _3251, 0.0, 1.0);\n        }\n        if (t <= 0.0)\n        {\n            break;\n        }\n    }\n    if (s < 0.0)\n    {\n        return 1.0;\n    }\n    if (t > 0.0)\n    {\n        float _3283;\n        if ((ci + 1) < _3124)\n        {\n            _3283 = (s2 < 0.0) ? s : s2;\n        }\n        else\n        {\n            _3283 = 1.0;\n        }\n        s = mix(s, _3283, t);\n    }\n    return s;\n}\n\nfloat fa_shadow_factor(vec3 n, vec3 l)\n{\n    vec3 param = fa_world_pos;\n    vec3 param_1 = n;\n    vec3 param_2 = l;\n    return fa_shadow_sun(param, param_1, param_2);\n}\n\nfloat fa_shadow_local(int li, vec3 lpos, vec3 world, vec3 n, vec3 l)\n{\n    bool _2804 = fa_mesh_fs_params[5].z < 0.5;\n    bool _2811;\n    if (!_2804)\n    {\n        _2811 = fa_shadows[29].x < 0.5;\n    }\n    else\n    {\n        _2811 = _2804;\n    }\n    if (_2811)\n    {\n        return 1.0;\n    }\n    int param = (int(fa_shadows[29].x + 0.5) - 1) + li;\n    vec4 _2824 = fa_light_texel(param);\n    float _2825 = _2824.x;\n    if (_2825 < 0.0)\n    {\n        return 1.0;\n    }\n    int _2834 = int(_2825 + 0.5);\n    int param_1 = _2834;\n    vec4 _2838 = fa_light_texel(param_1);\n    int param_2 = _2834 + 1;\n    vec4 _2843 = fa_light_texel(param_2);\n    float fade = 1.0;\n    float _2846 = _2838.y;\n    if (_2846 > 0.0)\n    {\n        float _2863 = 1.0 - smoothstep(0.75 * _2846, _2846, length(world - fa_shadows[27].xyz));\n        fade = _2863;\n        if (_2863 <= 0.0)\n        {\n            return 1.0;\n        }\n    }\n    int face = 0;\n    if (_2838.x > 1.5)\n    {\n        vec3 param_3 = world - lpos;\n        face = fa_cube_face(param_3);\n    }\n    int _2887 = (_2834 + 2) + (face * 6);\n    int param_4 = _2887;\n    int param_5 = _2887 + 1;\n    int param_6 = _2887 + 3;\n    vec4 _2901 = fa_light_texel(param_6);\n    int param_7 = _2887 + 4;\n    vec4 _2906 = fa_light_texel(param_7);\n    int param_8 = _2887 + 5;\n    vec4 _2911 = fa_light_texel(param_8);\n    float _2923 = _2911.x * max(dot(_2901, vec4(world, 1.0)), 0.001000000047497451305389404296875);\n    float _2928 = clamp(dot(n, l), 0.0, 1.0);\n    float _2951 = clamp(dot(n, _2901.xyz), -1.0, 1.0);\n    float _2970 = min(sqrt(1.0 - (_2951 * _2951)) / max(abs(dot(n, world - lpos)) / max(dot(_2901, vec4(world, 1.0)), 0.001000000047497451305389404296875), 0.20000000298023223876953125), 4.0);\n    float _2973 = _2843.y;\n    float _2975;\n    if (_2973 > 0.0)\n    {\n        _2975 = _2973;\n    }\n    else\n    {\n        _2975 = 1.5 * _2923;\n    }\n    vec4 _2995 = vec4(world + (n * (_2975 * sqrt(1.0 - (_2928 * _2928)))), 1.0);\n    float _2999 = dot(_2901, _2995);\n    float _3002 = _2911.y;\n    if (_2999 < _3002)\n    {\n        return 1.0;\n    }\n    vec2 _3017 = vec2(dot(fa_light_texel(param_4), _2995), dot(fa_light_texel(param_5), _2995)) / vec2(_2999);\n    float _3019 = _3017.x;\n    bool _3022 = _3019 < _2906.x;\n    bool _3031;\n    if (!_3022)\n    {\n        _3031 = _3019 > _2906.z;\n    }\n    else\n    {\n        _3031 = _3022;\n    }\n    bool _3040;\n    if (!_3031)\n    {\n        _3040 = _3017.y < _2906.y;\n    }\n    else\n    {\n        _3040 = _3031;\n    }\n    bool _3049;\n    if (!_3040)\n    {\n        _3049 = _3017.y > _2906.w;\n    }\n    else\n    {\n        _3049 = _3040;\n    }\n    if (_3049)\n    {\n        return 1.0;\n    }\n    float _3055 = _2843.x;\n    float _3057;\n    if (_3055 > 0.0)\n    {\n        _3057 = _3055;\n    }\n    else\n    {\n        _3057 = 1.5 * _2923;\n    }\n    vec2 param_9 = _3017;\n    vec4 param_10 = _2906;\n    float param_11 = _2999 - (_3057 * (1.0 + (0.5 * _2970)));\n    float param_12 = _2923;\n    float param_13 = 1.0;\n    float param_14 = _2911.z * 0.25;\n    float param_15 = (_2923 * min(_2970, 3.0)) * 0.5;\n    vec3 param_16 = vec3(1.0, _3002, _2911.z);\n    int param_17 = int(_2838.z + 0.5);\n    float param_18 = _2838.w;\n    return mix(1.0, fa_shadow_filter(param_9, param_10, param_11, param_12, param_13, param_14, param_15, param_16, param_17, param_18), fade);\n}\n\nfloat fa_contact_shadow(int li, vec3 world, vec3 gn, vec3 l, float dist)\n{\n    bool _5213 = fa_mesh_fs_params[24].x < 0.5;\n    bool _5220;\n    if (!_5213)\n    {\n        _5220 = fa_shadows[29].x < 0.5;\n    }\n    else\n    {\n        _5220 = _5213;\n    }\n    if (_5220)\n    {\n        return 1.0;\n    }\n    int param = (int(fa_shadows[29].x + 0.5) - 1) + li;\n    vec4 _5233 = fa_light_texel(param);\n    float _5234 = _5233.y;\n    float len = _5234;\n    if (_5234 <= 0.0)\n    {\n        return 1.0;\n    }\n    float _5246 = length(world - fa_mesh_fs_params[0].xyz);\n    float _5256 = 1.0 - smoothstep(0.5 * fa_mesh_fs_params[25].x, fa_mesh_fs_params[25].x, _5246);\n    if (_5256 <= 0.0)\n    {\n        return 1.0;\n    }\n    float _5262 = len;\n    float _5265 = min(_5262, 0.89999997615814208984375 * dist);\n    len = _5265;\n    float _5270 = 0.004999999888241291046142578125 + (0.0030000000260770320892333984375 * _5246);\n    float _5275 = _5270 + (0.5 * _5265);\n    vec3 _5281 = world + (gn * _5270);\n    float _5283 = fa_shadow_noise();\n    float occ = 0.0;\n    float _5347;\n    for (int k = 0; k < 12; k++)\n    {\n        float _5298 = (float(k) + _5283) * 0.083333335816860198974609375;\n        vec3 _5306 = _5281 + (l * (_5298 * len));\n        vec4 _5312 = vec4(_5306, 1.0);\n        float _5318 = dot(fa_mesh_fs_params[28], _5312);\n        if (_5318 < 9.9999997473787516355514526367188e-05)\n        {\n            break;\n        }\n        vec2 _5338 = vec2(dot(fa_mesh_fs_params[26], _5312), dot(fa_mesh_fs_params[27], _5312)) / vec2(_5318);\n        float _5342 = _5338.x * 0.5;\n        float _5343 = _5342 + 0.5;\n        if (fa_mesh_fs_params[24].y > 0.5)\n        {\n            _5347 = (_5338.y * 0.5) + 0.5;\n        }\n        else\n        {\n            _5347 = 0.5 - (_5338.y * 0.5);\n        }\n        bool _5363 = _5343 < 0.0;\n        bool _5370;\n        if (!_5363)\n        {\n            _5370 = _5343 >= 1.0;\n        }\n        else\n        {\n            _5370 = _5363;\n        }\n        bool _5377;\n        if (!_5370)\n        {\n            _5377 = _5347 < 0.0;\n        }\n        else\n        {\n            _5377 = _5370;\n        }\n        bool _5384;\n        if (!_5377)\n        {\n            _5384 = _5347 >= 1.0;\n        }\n        else\n        {\n            _5384 = _5377;\n        }\n        if (_5384)\n        {\n            break;\n        }\n        vec4 _5411 = texelFetch(fa_screen_tex_fa_shadow_smp, clamp(ivec2(vec2(_5343, _5347) * fa_mesh_fs_params[24].zw), ivec2(0), ivec2(fa_mesh_fs_params[24].zw) - ivec2(1)), 0);\n        if (_5411.w < 0.5)\n        {\n            continue;\n        }\n        float _5430 = (dot(fa_mesh_fs_params[29].xyz, _5306) + fa_mesh_fs_params[29].w) - _5411.x;\n        if ((_5430 > _5270) && (_5430 < _5275))\n        {\n            occ = max(occ, (1.0 - (_5298 * _5298)) * smoothstep(0.0, 0.0500000007450580596923828125, min(min(_5343, 0.5 - _5342), min(_5347, 1.0 - _5347))));\n        }\n    }\n    return 1.0 - (occ * _5256);\n}\n\nLightSample fa_light_shadowed(int li, vec3 world_pos, vec3 gn)\n{\n    int param = li;\n    float _5896 = fa_baked_keep(param);\n    if (_5896 <= 0.0)\n    {\n        int param_1 = li;\n        return LightSample(vec3(0.0, 1.0, 0.0), vec3(0.0), 0.0, 1.0, 0.0, int(fa_light_type(param_1) + 0.5));\n    }\n    int param_2 = li;\n    vec3 param_3 = world_pos;\n    vec3 param_4 = gn;\n    LightSample _5922 = fa_light_sample_n(param_2, param_3, param_4);\n    vec3 _9116 = _5922.color;\n    float _9117 = _5922.attenuation;\n    float _9118 = _5922.shadow;\n    bool _5925 = _5922.type == 0;\n    if (_5925 && (li == 0))\n    {\n        vec3 param_5 = gn;\n        vec3 param_6 = _5922.direction;\n        float _5936 = fa_shadow_factor(param_5, param_6);\n        _9118 = _5936;\n        _9116 *= _5936;\n    }\n    else\n    {\n        bool _5947 = _5922.type != 0;\n        bool _5953;\n        if (_5947)\n        {\n            _5953 = _9117 > 0.0;\n        }\n        else\n        {\n            _5953 = _5947;\n        }\n        if (_5953)\n        {\n            int param_7 = li;\n            int param_8 = fa_light_base(param_7);\n            int param_9 = li;\n            vec3 param_10 = fa_light_texel(param_8).xyz;\n            vec3 param_11 = world_pos;\n            vec3 param_12 = gn;\n            vec3 param_13 = _5922.direction;\n            float _5972 = fa_shadow_local(param_9, param_10, param_11, param_12, param_13);\n            _9118 = _5972;\n            _9116 *= _5972;\n        }\n    }\n    bool _5982 = fa_mesh_fs_params[24].x > 0.5;\n    bool _5988;\n    if (_5982)\n    {\n        _5988 = _9117 > 0.0;\n    }\n    else\n    {\n        _5988 = _5982;\n    }\n    if (_5988)\n    {\n        float _5995;\n        if (_5925)\n        {\n            _5995 = 1000000000.0;\n        }\n        else\n        {\n            _5995 = _5922._distance;\n        }\n        int param_14 = li;\n        vec3 param_15 = world_pos;\n        vec3 param_16 = gn;\n        vec3 param_17 = _5922.direction;\n        float param_18 = _5995;\n        float _6013 = fa_contact_shadow(param_14, param_15, param_16, param_17, param_18);\n        _9118 *= _6013;\n        _9116 *= _6013;\n    }\n    float _6026 = _9117;\n    float _6027 = _6026 * _5896;\n    _9117 = _6027;\n    vec3 _6031 = _9116;\n    vec3 _6032 = _6031 * _5896;\n    _9116 = _6032;\n    return LightSample(_5922.direction, _6032, _6027, _9118, _5922._distance, _5922.type);\n}\n\nvec3 fa_ltc_tangent(vec3 n, vec3 v)\n{\n    vec3 _6066 = v - (n * dot(v, n));\n    vec3 t = _6066;\n    float _6070 = dot(_6066, _6066);\n    float l2 = _6070;\n    if (_6070 < 1.0000000133514319600180897396058e-10)\n    {\n        vec3 _6080;\n        if (abs(n.z) < 0.999000012874603271484375)\n        {\n            _6080 = cross(n, vec3(0.0, 0.0, 1.0));\n        }\n        else\n        {\n            _6080 = cross(n, vec3(1.0, 0.0, 0.0));\n        }\n        t = _6080;\n        l2 = dot(_6080, _6080);\n    }\n    return t * inversesqrt(l2);\n}\n\nvec3 fa_ltc_local(vec3 t1, vec3 n, vec3 p)\n{\n    return vec3(dot(t1, p), dot(cross(n, t1), p), dot(n, p));\n}\n\nvec2 fa_ltc_uv(float roughness, float ndv)\n{\n    return ((vec2(clamp((roughness - 0.0500000007450580596923828125) * 1.0526316165924072265625, 0.0, 1.0), sqrt(clamp(1.0 - ndv, 0.0, 1.0))) * 63.0) + vec2(0.5)) * vec2(0.015625);\n}\n\nvec3 fa_oct_vertex(int j, vec3 pc, vec3 ex, vec3 ey)\n{\n    float _6467;\n    if ((j == 0) || (j == 7))\n    {\n        _6467 = 0.92387950420379638671875;\n    }\n    else\n    {\n        float _6477;\n        if ((j == 3) || (j == 4))\n        {\n            _6477 = -0.92387950420379638671875;\n        }\n        else\n        {\n            _6477 = ((j == 1) || (j == 6)) ? 0.3826834261417388916015625 : (-0.3826834261417388916015625);\n        }\n        _6467 = _6477;\n    }\n    float _6498;\n    if ((j == 1) || (j == 2))\n    {\n        _6498 = 0.92387950420379638671875;\n    }\n    else\n    {\n        float _6507;\n        if ((j == 5) || (j == 6))\n        {\n            _6507 = -0.92387950420379638671875;\n        }\n        else\n        {\n            _6507 = ((j == 0) || (j == 3)) ? 0.3826834261417388916015625 : (-0.3826834261417388916015625);\n        }\n        _6498 = _6507;\n    }\n    return (pc + (ex * _6467)) + (ey * _6498);\n}\n\nvec3 fa_ltc_edge_vector(vec3 a, vec3 b)\n{\n    float _6115 = dot(a, a);\n    float _6119 = dot(b, b);\n    if ((_6115 < 1.0000000195414813782625560981111e-24) || (_6119 < 1.0000000195414813782625560981111e-24))\n    {\n        return vec3(0.0);\n    }\n    vec3 _6133 = a * inversesqrt(_6115);\n    vec3 _6138 = b * inversesqrt(_6119);\n    float _6142 = dot(_6133, _6138);\n    float _6145 = abs(_6142);\n    float g = (((((((((((0.0416471660137176513671875 * _6145) - 0.1924748718738555908203125) * _6145) + 0.4179156124591827392578125) * _6145) - 0.616057217121124267578125) * _6145) + 0.777722418308258056640625) * _6145) - 0.999542415142059326171875) * _6145) + 1.570791721343994140625;\n    if (_6142 < 0.0)\n    {\n        g = (3.1415927410125732421875 * inversesqrt(max(1.0 - (_6142 * _6142), 1.0000000116860974230803549289703e-07))) - g;\n    }\n    return cross(_6133, _6138) * g;\n}\n\nvoid fa_ltc_clip_edge(vec3 a, vec3 b, inout vec3 sum, inout vec3 leave, inout vec3 enter, inout vec2 seen)\n{\n    bool _6202 = a.z > 0.0;\n    bool _6206 = b.z > 0.0;\n    if (_6202 && _6206)\n    {\n        vec3 param = a;\n        vec3 param_1 = b;\n        sum += fa_ltc_edge_vector(param, param_1);\n    }\n    else\n    {\n        if (_6202 != _6206)\n        {\n            vec3 _6241 = a + ((b - a) * (a.z / (a.z - b.z)));\n            _6241.z = 0.0;\n            if (_6202)\n            {\n                vec3 param_2 = a;\n                vec3 param_3 = _6241;\n                sum += fa_ltc_edge_vector(param_2, param_3);\n                leave = _6241;\n                seen.x = 1.0;\n            }\n            else\n            {\n                vec3 param_4 = _6241;\n                vec3 param_5 = b;\n                sum += fa_ltc_edge_vector(param_4, param_5);\n                enter = _6241;\n                seen.y = 1.0;\n            }\n        }\n    }\n}\n\nfloat fa_ltc_quad(vec4 abcd, vec3 p0, vec3 p1, vec3 p2, vec3 p3)\n{\n    vec3 _6290 = vec3((abcd.x * p0.x) + (abcd.y * p0.z), p0.y, (abcd.z * p0.x) + (abcd.w * p0.z));\n    vec3 _6316 = vec3((abcd.x * p1.x) + (abcd.y * p1.z), p1.y, (abcd.z * p1.x) + (abcd.w * p1.z));\n    vec3 _6342 = vec3((abcd.x * p2.x) + (abcd.y * p2.z), p2.y, (abcd.z * p2.x) + (abcd.w * p2.z));\n    vec3 _6368 = vec3((abcd.x * p3.x) + (abcd.y * p3.z), p3.y, (abcd.z * p3.x) + (abcd.w * p3.z));\n    vec3 sum = vec3(0.0);\n    vec3 leave = vec3(0.0);\n    vec3 enter = vec3(0.0);\n    vec3 param = _6290;\n    vec3 param_1 = _6316;\n    vec3 param_2 = vec3(0.0);\n    vec3 param_3 = vec3(0.0);\n    vec3 param_4 = vec3(0.0);\n    vec2 param_5 = vec2(0.0);\n    fa_ltc_clip_edge(param, param_1, param_2, param_3, param_4, param_5);\n    sum = param_2;\n    leave = param_3;\n    enter = param_4;\n    vec3 param_6 = _6316;\n    vec3 param_7 = _6342;\n    vec3 param_8 = param_2;\n    vec3 param_9 = param_3;\n    vec3 param_10 = param_4;\n    vec2 param_11 = param_5;\n    fa_ltc_clip_edge(param_6, param_7, param_8, param_9, param_10, param_11);\n    sum = param_8;\n    leave = param_9;\n    enter = param_10;\n    vec3 param_12 = _6342;\n    vec3 param_13 = _6368;\n    vec3 param_14 = param_8;\n    vec3 param_15 = param_9;\n    vec3 param_16 = param_10;\n    vec2 param_17 = param_11;\n    fa_ltc_clip_edge(param_12, param_13, param_14, param_15, param_16, param_17);\n    sum = param_14;\n    leave = param_15;\n    enter = param_16;\n    vec3 param_18 = _6368;\n    vec3 param_19 = _6290;\n    vec3 param_20 = param_14;\n    vec3 param_21 = param_15;\n    vec3 param_22 = param_16;\n    vec2 param_23 = param_17;\n    fa_ltc_clip_edge(param_18, param_19, param_20, param_21, param_22, param_23);\n    sum = param_20;\n    leave = param_21;\n    enter = param_22;\n    if ((param_23.x * param_23.y) > 0.5)\n    {\n        vec3 param_24 = leave;\n        vec3 param_25 = enter;\n        sum += fa_ltc_edge_vector(param_24, param_25);\n    }\n    return sum.z * 0.15915493667125701904296875;\n}\n\nvec2 fa_area_forms(vec4 m, float shape, vec3 pc, vec3 ex, vec3 ey)\n{\n    int _6536 = ((shape < 0.5) || (shape > 1.5)) ? 1 : 3;\n    vec2 sum = vec2(0.0);\n    int _6554;\n    for (int k = 0; k < (2 * _6536); k++)\n    {\n        bool _6551 = k >= _6536;\n        if (_6551)\n        {\n            _6554 = k - _6536;\n        }\n        else\n        {\n            _6554 = k;\n        }\n        vec3 p0 = (pc - ex) - ey;\n        vec3 p1 = (pc + ex) - ey;\n        vec3 p2 = (pc + ex) + ey;\n        vec3 p3 = (pc - ex) + ey;\n        if (_6536 == 3)\n        {\n            int param = 0;\n            vec3 param_1 = pc;\n            vec3 param_2 = ex;\n            vec3 param_3 = ey;\n            p0 = fa_oct_vertex(param, param_1, param_2, param_3);\n            int _6600 = 2 * _6554;\n            int param_4 = _6600 + 1;\n            vec3 param_5 = pc;\n            vec3 param_6 = ex;\n            vec3 param_7 = ey;\n            p1 = fa_oct_vertex(param_4, param_5, param_6, param_7);\n            int param_8 = _6600 + 2;\n            vec3 param_9 = pc;\n            vec3 param_10 = ex;\n            vec3 param_11 = ey;\n            p2 = fa_oct_vertex(param_8, param_9, param_10, param_11);\n            int param_12 = _6600 + 3;\n            vec3 param_13 = pc;\n            vec3 param_14 = ex;\n            vec3 param_15 = ey;\n            p3 = fa_oct_vertex(param_12, param_13, param_14, param_15);\n        }\n        bvec4 _6637 = bvec4(_6551);\n        vec4 param_16 = vec4(_6637.x ? m.x : vec4(1.0, 0.0, 0.0, 1.0).x, _6637.y ? m.y : vec4(1.0, 0.0, 0.0, 1.0).y, _6637.z ? m.z : vec4(1.0, 0.0, 0.0, 1.0).z, _6637.w ? m.w : vec4(1.0, 0.0, 0.0, 1.0).w);\n        vec3 param_17 = p0;\n        vec3 param_18 = p1;\n        vec3 param_19 = p2;\n        vec3 param_20 = p3;\n        float _6648 = fa_ltc_quad(param_16, param_17, param_18, param_19, param_20);\n        if (_6551)\n        {\n            vec2 _9343 = sum;\n            _9343.y = _9343.y + _6648;\n            sum = _9343;\n        }\n        else\n        {\n            vec2 _9346 = sum;\n            _9346.x = _9346.x + _6648;\n            sum = _9346;\n        }\n    }\n    return abs(sum);\n}\n\nvec3 fa_area_shade(int li, vec3 world_pos, vec3 n, vec3 v, vec3 diffuse_color, vec3 f0, float f90, float roughness, float ndv, float window)\n{\n    int param = li;\n    int _6672 = fa_light_base(param);\n    int param_1 = _6672;\n    int param_2 = _6672 + 1;\n    int param_3 = _6672 + 2;\n    int param_4 = _6672 + 4;\n    vec4 _6694 = fa_light_texel(param_4);\n    int param_5 = _6672 + 5;\n    vec4 _6699 = fa_light_texel(param_5);\n    int param_6 = _6672 + 6;\n    vec4 _6704 = fa_light_texel(param_6);\n    float _6705 = _6704.w;\n    vec3 _6710 = fa_light_texel(param_1).xyz - world_pos;\n    bool _6712 = _6705 < 1.5;\n    bool _6719;\n    if (_6712)\n    {\n        _6719 = dot(normalize(fa_light_texel(param_3).xyz), _6710) >= 0.0;\n    }\n    else\n    {\n        _6719 = _6712;\n    }\n    if (_6719)\n    {\n        return vec3(0.0);\n    }\n    bool _6728 = (_6705 > 0.5) && _6712;\n    float _6732 = _6728 ? 1.0539000034332275390625 : 1.0;\n    vec3 _6735 = _6694.xyz;\n    float _6737 = _6694.w;\n    vec3 _6743 = _6699.xyz;\n    float _6745 = _6699.w;\n    vec3 up = _6743 * (_6745 * _6732);\n    float _6751;\n    if (_6728)\n    {\n        _6751 = (3.1415927410125732421875 * _6737) * _6737;\n    }\n    else\n    {\n        _6751 = (4.0 * _6737) * _6745;\n    }\n    if (_6705 > 1.5)\n    {\n        vec3 _6777 = cross(_6735, -_6710);\n        vec3 perp = _6777;\n        float _6781 = dot(_6777, _6777);\n        vec3 _6784;\n        if (_6781 > 1.0000000133514319600180897396058e-10)\n        {\n            _6784 = perp * inversesqrt(_6781);\n        }\n        else\n        {\n            _6784 = _6743;\n        }\n        perp = _6784;\n        up = _6784 * _6745;\n    }\n    float _6805 = max(_6751, 9.9999999747524270787835121154785e-07);\n    vec3 param_7 = n;\n    vec3 param_8 = v;\n    vec3 _6815 = fa_ltc_tangent(param_7, param_8);\n    vec3 param_9 = _6815;\n    vec3 param_10 = n;\n    vec3 param_11 = _6710;\n    vec3 param_12 = _6815;\n    vec3 param_13 = n;\n    vec3 param_14 = _6735 * (_6737 * _6732);\n    vec3 param_15 = _6815;\n    vec3 param_16 = n;\n    vec3 param_17 = up;\n    float param_18 = roughness;\n    float param_19 = ndv;\n    vec2 _6846 = fa_ltc_uv(param_18, param_19) * 64.0;\n    vec2 param_20 = _6846;\n    vec2 param_21 = _6846 + vec2(64.0, 0.0);\n    vec4 _6856 = fa_atlas_fetch(param_21);\n    vec4 param_22 = fa_atlas_fetch(param_20);\n    float param_23 = _6705;\n    vec3 param_24 = fa_ltc_local(param_9, param_10, param_11);\n    vec3 param_25 = fa_ltc_local(param_12, param_13, param_14);\n    vec3 param_26 = fa_ltc_local(param_15, param_16, param_17);\n    vec2 _6868 = fa_area_forms(param_22, param_23, param_24, param_25, param_26);\n    return (((diffuse_color * _6868.x) + (((f0 * _6856.x) + ((vec3(f90) - f0) * _6856.y)) * _6868.y)) * fa_light_texel(param_2).xyz) * ((((3.1415927410125732421875 * dot(_6710, _6710)) + _6805) / _6805) * window);\n}\n\nvec3 fa_light_rgb(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 1;\n    return fa_light_texel(param_1).xyz;\n}\n\nfloat fa_d_charlie(float alpha, float ndh)\n{\n    float _4950 = 1.0 / alpha;\n    return ((2.0 + _4950) * pow(sqrt(max(1.0 - (ndh * ndh), 9.9999997473787516355514526367188e-05)), _4950)) * 0.15915493667125701904296875;\n}\n\nfloat fa_v_ashikhmin(float ndl, float ndv)\n{\n    return clamp(0.25 / max((ndl + ndv) - (ndl * ndv), 9.9999997473787516355514526367188e-05), 0.0, 1.0);\n}\n\nfloat fa_layers_coat(FaLayers L, vec3 l, vec3 h, float vdh)\n{\n    float _4985 = max(dot(L.nc, l), 0.0);\n    float _4991 = max(dot(L.nc, h), 0.0);\n    float _5000 = ((_4991 * _4991) * (L.coat_a2 - 1.0)) + 1.0;\n    return (((L.coat * (0.039999999105930328369140625 + (0.959999978542327880859375 * pow(clamp(1.0 - vdh, 0.0, 1.0), 5.0)))) * (((L.coat_a2 / ((3.1415927410125732421875 * _5000) * _5000)) * (0.5 / max(mix((2.0 * _4985) * L.coat_ndv, _4985 + L.coat_ndv, L.coat_alpha), 9.9999997473787516355514526367188e-05))) * 3.1415927410125732421875)) * step(9.9999997473787516355514526367188e-05, _4985)) * _4985;\n}\n\nvec3 fa_area_layers(FaLayers L, vec3 base, int li, vec3 n, vec3 v, vec3 l, float ndv, float window)\n{\n    float _6905;\n    if (L.sheen_on)\n    {\n        _6905 = L.sheen_scale;\n    }\n    else\n    {\n        _6905 = 1.0;\n    }\n    vec3 result = base * (L.keep * _6905);\n    vec3 _6918 = normalize(l + v);\n    int param = li;\n    vec3 _6929 = fa_light_rgb(param) * window;\n    if (L.sheen_on)\n    {\n        float _6938 = max(dot(n, l), 0.0);\n        float param_1 = L.sheen_alpha;\n        float param_2 = max(dot(n, _6918), 0.0);\n        float param_3 = _6938;\n        float param_4 = ndv;\n        result += ((L.sheen * _6929) * (((((fa_d_charlie(param_1, param_2) * fa_v_ashikhmin(param_3, param_4)) * 3.1415927410125732421875) * step(9.9999997473787516355514526367188e-05, _6938)) * _6938) * L.keep));\n    }\n    if (L.coat > 0.0)\n    {\n        FaLayers param_5 = L;\n        vec3 param_6 = l;\n        vec3 param_7 = _6918;\n        float param_8 = max(dot(v, _6918), 0.0);\n        result += (_6929 * fa_layers_coat(param_5, param_6, param_7, param_8));\n    }\n    return result;\n}\n\nfloat fa_d_ggx_aniso(float ndh, float tdh, float bdh, float at, float ab)\n{\n    float _4853 = tdh / at;\n    float _4857 = bdh / ab;\n    float _4869 = ((_4853 * _4853) + (_4857 * _4857)) + (ndh * ndh);\n    return 1.0 / ((((3.1415927410125732421875 * at) * ab) * _4869) * _4869);\n}\n\nfloat fa_lambda_ggx_aniso(float n, float t, float b, float at, float ab)\n{\n    return 0.5 * (sqrt(1.0 + (((((at * at) * t) * t) + (((ab * ab) * b) * b)) / max(n * n, 9.9999999392252902907785028219223e-09))) - 1.0);\n}\n\nfloat fa_v_ggx_aniso(float ndl, float ndv, float tdv, float bdv, float tdl, float bdl, float at, float ab)\n{\n    float param = ndv;\n    float param_1 = tdv;\n    float param_2 = bdv;\n    float param_3 = at;\n    float param_4 = ab;\n    float param_5 = ndl;\n    float param_6 = tdl;\n    float param_7 = bdl;\n    float param_8 = at;\n    float param_9 = ab;\n    return clamp(1.0 / ((4.0 * max(ndl * ndv, 9.9999997473787516355514526367188e-05)) * ((1.0 + fa_lambda_ggx_aniso(param, param_1, param_2, param_3, param_4)) + fa_lambda_ggx_aniso(param_5, param_6, param_7, param_8, param_9))), 0.0, 1.0);\n}\n\nvec3 fa_layers_light(FaLayers L, vec3 diffuse_color, vec3 f0, vec3 n, vec3 v, vec3 l, vec3 h, float ndl, float ndv, float ndh, float vdh, float alpha, float a2)\n{\n    float _5049 = step(9.9999997473787516355514526367188e-05, ndl);\n    float d_ggx;\n    float vis;\n    if (L.aniso != 0.0)\n    {\n        float param = ndh;\n        float param_1 = dot(L.t, h);\n        float param_2 = dot(L.b, h);\n        float param_3 = L.at;\n        float param_4 = L.ab;\n        d_ggx = fa_d_ggx_aniso(param, param_1, param_2, param_3, param_4);\n        float param_5 = ndl;\n        float param_6 = ndv;\n        float param_7 = dot(L.t, v);\n        float param_8 = dot(L.b, v);\n        float param_9 = dot(L.t, l);\n        float param_10 = dot(L.b, l);\n        float param_11 = L.at;\n        float param_12 = L.ab;\n        vis = fa_v_ggx_aniso(param_5, param_6, param_7, param_8, param_9, param_10, param_11, param_12);\n    }\n    else\n    {\n        float _5128 = ((ndh * ndh) * (a2 - 1.0)) + 1.0;\n        d_ggx = a2 / ((3.1415927410125732421875 * _5128) * _5128);\n        vis = 0.5 / max(mix((2.0 * ndl) * ndv, ndl + ndv, alpha), 9.9999997473787516355514526367188e-05);\n    }\n    vec3 base = diffuse_color + (((f0 + ((vec3(L.f90) - f0) * pow(clamp(1.0 - vdh, 0.0, 1.0), 5.0))) * ((d_ggx * vis) * 3.1415927410125732421875)) * _5049);\n    if (L.sheen_on)\n    {\n        float param_13 = L.sheen_alpha;\n        float param_14 = ndh;\n        float param_15 = ndl;\n        float param_16 = ndv;\n        base = (base * L.sheen_scale) + (L.sheen * (((fa_d_charlie(param_13, param_14) * fa_v_ashikhmin(param_15, param_16)) * 3.1415927410125732421875) * _5049));\n    }\n    vec3 result = base * (L.keep * ndl);\n    if (L.coat > 0.0)\n    {\n        FaLayers param_17 = L;\n        vec3 param_18 = l;\n        vec3 param_19 = h;\n        float param_20 = vdh;\n        result += vec3(fa_layers_coat(param_17, param_18, param_19, param_20));\n    }\n    return result;\n}\n\nvec2 fa_env_brdf(float rough, float ndv)\n{\n    vec4 _4252 = (vec4(-1.0, -0.0274999998509883880615234375, -0.572000026702880859375, 0.02199999988079071044921875) * rough) + vec4(1.0, 0.0425000004470348358154296875, 1.03999996185302734375, -0.039999999105930328369140625);\n    float _4255 = _4252.x;\n    return (vec2(-1.03999996185302734375, 1.03999996185302734375) * ((min(_4255 * _4255, exp2((-9.27999973297119140625) * ndv)) * _4255) + _4252.y)) + _4252.zw;\n}\n\nvec3 fa_probe_level(vec2 origin, float res, int lv, vec2 e)\n{\n    float _3560;\n    if (lv == 0)\n    {\n        _3560 = 0.0;\n    }\n    else\n    {\n        _3560 = res + 2.0;\n    }\n    float _3570;\n    if (lv == 0)\n    {\n        _3570 = 0.0;\n    }\n    else\n    {\n        _3570 = (res - (res / float(1 << max((lv - 1), 0)))) + (2.0 * float(lv - 1));\n    }\n    return textureLod(fa_probe_atlas_fa_env_smp, (((origin + vec2(_3560, _3570)) + vec2(1.0)) + (((e * 0.5) + vec2(0.5)) * (res / float(1 << lv)))) / fa_atlas_size(), 0.0).xyz;\n}\n\nvec3 fa_probe_radiance(vec2 origin, float res, vec3 d, float rough)\n{\n    float _3616;\n    if (res > 64.5)\n    {\n        _3616 = 5.0;\n    }\n    else\n    {\n        _3616 = (res > 32.5) ? 4.0 : 3.0;\n    }\n    float _3631 = clamp(rough, 0.0, 1.0) * (_3616 - 1.0);\n    int _3638 = int(min(floor(_3631), _3616 - 2.0));\n    float _3643 = _3631 - float(_3638);\n    vec3 param = d;\n    vec2 _3647 = fa_oct_encode(param);\n    vec2 param_1 = origin;\n    float param_2 = res;\n    int param_3 = _3638;\n    vec2 param_4 = _3647;\n    vec3 _3657 = fa_probe_level(param_1, param_2, param_3, param_4);\n    if (_3643 < 0.00200000009499490261077880859375)\n    {\n        return _3657;\n    }\n    vec2 param_5 = origin;\n    float param_6 = res;\n    int param_7 = _3638 + 1;\n    vec2 param_8 = _3647;\n    return mix(_3657, fa_probe_level(param_5, param_6, param_7, param_8), vec3(_3643));\n}\n\nvec3 fa_probe_box_dir(vec3 d, vec4 posw, vec4 bx, vec4 by, vec4 bz)\n{\n    if (posw.w < 0.5)\n    {\n        return d;\n    }\n    float _3730 = dot(bx.xyz, fa_world_pos) + bx.w;\n    float _3737 = dot(by.xyz, fa_world_pos) + by.w;\n    float _3744 = dot(bz.xyz, fa_world_pos) + bz.w;\n    float _3750 = dot(bx.xyz, d);\n    float _3754 = dot(by.xyz, d);\n    float _3758 = dot(bz.xyz, d);\n    float _3764;\n    if (_3750 > 9.9999999747524270787835121154785e-07)\n    {\n        _3764 = (1.0 - _3730) / _3750;\n    }\n    else\n    {\n        float _3778;\n        if (_3750 < (-9.9999999747524270787835121154785e-07))\n        {\n            _3778 = ((-1.0) - _3730) / _3750;\n        }\n        else\n        {\n            _3778 = 1000000015047466219876688855040.0;\n        }\n        _3764 = _3778;\n    }\n    float tx = _3764;\n    float _3795;\n    if (_3754 > 9.9999999747524270787835121154785e-07)\n    {\n        _3795 = (1.0 - _3737) / _3754;\n    }\n    else\n    {\n        float _3808;\n        if (_3754 < (-9.9999999747524270787835121154785e-07))\n        {\n            _3808 = ((-1.0) - _3737) / _3754;\n        }\n        else\n        {\n            _3808 = 1000000015047466219876688855040.0;\n        }\n        _3795 = _3808;\n    }\n    float ty = _3795;\n    float _3824;\n    if (_3758 > 9.9999999747524270787835121154785e-07)\n    {\n        _3824 = (1.0 - _3744) / _3758;\n    }\n    else\n    {\n        float _3837;\n        if (_3758 < (-9.9999999747524270787835121154785e-07))\n        {\n            _3837 = ((-1.0) - _3744) / _3758;\n        }\n        else\n        {\n            _3837 = 1000000015047466219876688855040.0;\n        }\n        _3824 = _3837;\n    }\n    float _3849 = tx;\n    float _3852 = (_3849 > 0.0) ? _3849 : 1000000015047466219876688855040.0;\n    tx = _3852;\n    float _3853 = ty;\n    float _3856 = (_3853 > 0.0) ? _3853 : 1000000015047466219876688855040.0;\n    ty = _3856;\n    float _3866 = min(_3852, min(_3856, (_3824 > 0.0) ? _3824 : 1000000015047466219876688855040.0));\n    if (_3866 > 100000001504746621987668885504.0)\n    {\n        return d;\n    }\n    vec3 _3882 = (fa_world_pos + (d * _3866)) - posw.xyz;\n    vec3 _3887;\n    if (dot(_3882, _3882) > 1.0000000133514319600180897396058e-10)\n    {\n        _3887 = normalize(_3882);\n    }\n    else\n    {\n        _3887 = d;\n    }\n    return _3887;\n}\n\nvec3 fa_probe_environment(vec4 tile, vec4 posw, vec4 bx, vec4 by, vec4 bz, inout vec3 d, float rough)\n{\n    vec3 param = d;\n    vec4 param_1 = posw;\n    vec4 param_2 = bx;\n    vec4 param_3 = by;\n    vec4 param_4 = bz;\n    d = fa_probe_box_dir(param, param_1, param_2, param_3, param_4);\n    vec2 param_5 = tile.xy;\n    float param_6 = tile.z;\n    vec3 param_7 = d;\n    float param_8 = rough;\n    return fa_probe_radiance(param_5, param_6, param_7, param_8);\n}\n\nvec3 fa_environment(vec3 d, float rough)\n{\n    float _3933 = (1.0 - fa_mesh_fs_params[42].w) - fa_mesh_fs_params[47].w;\n    vec3 outc = vec3(0.0);\n    if (_3933 > 0.0005000000237487256526947021484375)\n    {\n        vec3 base;\n        if (fa_mesh_fs_params[11].w > 0.5)\n        {\n            vec2 param = fa_mesh_fs_params[41].zw;\n            float param_1 = 128.0;\n            vec3 param_2 = d;\n            float param_3 = rough;\n            base = fa_probe_radiance(param, param_1, param_2, param_3);\n        }\n        else\n        {\n            float _3961 = rough * rough;\n            float _3992 = 0.60000002384185791015625 * _3961;\n            base = mix(mix(fa_mesh_fs_params[12].xyz * 0.550000011920928955078125, mix(fa_mesh_fs_params[12].xyz, fa_mesh_fs_params[11].xyz, vec3(pow(clamp(d.y * (1.0 - (0.699999988079071044921875 * _3961)), 0.0, 1.0), 0.550000011920928955078125))), vec3(smoothstep((-0.0500000007450580596923828125) - _3992, 0.0500000007450580596923828125 + _3992, d.y))), ((fa_mesh_fs_params[11].xyz + fa_mesh_fs_params[12].xyz) * 0.5) * 0.800000011920928955078125, vec3(_3961 * 0.60000002384185791015625));\n        }\n        outc = base * _3933;\n    }\n    if (fa_mesh_fs_params[42].w > 0.0)\n    {\n        vec4 param_4 = fa_mesh_fs_params[42];\n        vec4 param_5 = fa_mesh_fs_params[43];\n        vec4 param_6 = fa_mesh_fs_params[44];\n        vec4 param_7 = fa_mesh_fs_params[45];\n        vec4 param_8 = fa_mesh_fs_params[46];\n        vec3 param_9 = d;\n        float param_10 = rough;\n        vec3 _4051 = fa_probe_environment(param_4, param_5, param_6, param_7, param_8, param_9, param_10);\n        outc += (_4051 * fa_mesh_fs_params[42].w);\n    }\n    if (fa_mesh_fs_params[47].w > 0.0)\n    {\n        vec4 param_11 = fa_mesh_fs_params[47];\n        vec4 param_12 = fa_mesh_fs_params[48];\n        vec4 param_13 = fa_mesh_fs_params[49];\n        vec4 param_14 = fa_mesh_fs_params[50];\n        vec4 param_15 = fa_mesh_fs_params[51];\n        vec3 param_16 = d;\n        float param_17 = rough;\n        vec3 _4083 = fa_probe_environment(param_11, param_12, param_13, param_14, param_15, param_16, param_17);\n        outc += (_4083 * fa_mesh_fs_params[47].w);\n    }\n    return outc;\n}\n\nvec3 fa_layers_ibl(FaLayers L, vec3 n, vec3 v, vec3 f0, float roughness, float occlusion)\n{\n    vec3 rn = n;\n    if (L.aniso != 0.0)\n    {\n        vec3 _4730;\n        if (L.aniso >= 0.0)\n        {\n            _4730 = L.b;\n        }\n        else\n        {\n            _4730 = L.t;\n        }\n        rn = normalize(mix(n, cross(cross(_4730, v), _4730), vec3(abs(L.aniso) * smoothstep(0.0, 0.25, roughness))));\n    }\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05);\n    vec2 _4766 = fa_env_brdf(param, param_1);\n    vec3 param_2 = reflect(-v, rn);\n    float param_3 = roughness;\n    vec3 result = (fa_environment(param_2, param_3) * ((f0 * _4766.x) + (vec3(L.f90) * _4766.y))) * L.base_scale;\n    if (L.sheen_on)\n    {\n        vec3 param_4 = n;\n        float param_5 = L.sheen_rough;\n        result += ((L.sheen * (L.sheen_e * L.keep)) * fa_environment(param_4, param_5));\n    }\n    result *= occlusion;\n    if (L.coat > 0.0)\n    {\n        float param_6 = L.coat_rough;\n        float param_7 = L.coat_ndv;\n        vec2 _4824 = fa_env_brdf(param_6, param_7);\n        vec3 param_8 = reflect(-v, L.nc);\n        float param_9 = L.coat_rough;\n        result += (fa_environment(param_8, param_9) * (L.coat * ((0.039999999105930328369140625 * _4824.x) + _4824.y)));\n    }\n    return result;\n}\n\nvec3 fa_sky_reflection(vec3 n, vec3 v, vec3 f0, float roughness)\n{\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05);\n    vec2 _4294 = fa_env_brdf(param, param_1);\n    vec3 param_2 = reflect(-v, n);\n    float param_3 = roughness;\n    return fa_environment(param_2, param_3) * ((f0 * _4294.x) + vec3(_4294.y));\n}\n\nvec2 fa_xm_size(int k)\n{\n    return max(floor(fa_mesh_fs_params[24].zw / vec2(float(1 << k))), vec2(1.0));\n}\n\nvec2 fa_xm_origin(int k)\n{\n    if (k == 0)\n    {\n        return vec2(0.0);\n    }\n    float y = 0.0;\n    for (int j = 1; j < k; j++)\n    {\n        int param = j;\n        y += fa_xm_size(param).y;\n    }\n    return vec2(fa_mesh_fs_params[24].z, y);\n}\n\nvec3 fa_xm_texel(vec2 size, vec2 origin, vec2 p)\n{\n    return texelFetch(fa_screen_tex_fa_shadow_smp, ivec2(origin + clamp(p, vec2(0.0), size - vec2(1.0))), 0).xyz;\n}\n\nvec3 fa_xm_level(int k, vec2 uv)\n{\n    int param = k;\n    vec2 _5534 = fa_xm_size(param);\n    int param_1 = k;\n    vec2 _5538 = fa_xm_origin(param_1);\n    vec2 _5544 = (uv * _5534) - vec2(0.5);\n    vec2 _5547 = fract(_5544);\n    vec2 _5550 = floor(_5544);\n    vec2 param_2 = _5534;\n    vec2 param_3 = _5538;\n    vec2 param_4 = _5550;\n    vec2 param_5 = _5534;\n    vec2 param_6 = _5538;\n    vec2 param_7 = _5550 + vec2(1.0, 0.0);\n    vec2 param_8 = _5534;\n    vec2 param_9 = _5538;\n    vec2 param_10 = _5550 + vec2(0.0, 1.0);\n    vec2 param_11 = _5534;\n    vec2 param_12 = _5538;\n    vec2 param_13 = _5550 + vec2(1.0);\n    vec3 _5592 = vec3(_5547.x);\n    return mix(mix(fa_xm_texel(param_2, param_3, param_4), fa_xm_texel(param_5, param_6, param_7), _5592), mix(fa_xm_texel(param_8, param_9, param_10), fa_xm_texel(param_11, param_12, param_13), _5592), vec3(_5547.y));\n}\n\nvec3 fa_xm_sample(vec2 uv, float lod)\n{\n    float _5611 = max(fa_mesh_fs_params[31].w - 1.0, 0.0);\n    float _5615 = clamp(lod, 0.0, _5611);\n    int _5619 = int(floor(_5615));\n    int param = _5619;\n    vec2 param_1 = uv;\n    vec3 c = fa_xm_level(param, param_1);\n    float _5629 = float(_5619);\n    float _5630 = _5615 - _5629;\n    bool _5632 = _5630 > 0.001000000047497451305389404296875;\n    bool _5639;\n    if (_5632)\n    {\n        _5639 = _5629 < _5611;\n    }\n    else\n    {\n        _5639 = _5632;\n    }\n    if (_5639)\n    {\n        int param_2 = _5619 + 1;\n        vec2 param_3 = uv;\n        c = mix(c, fa_xm_level(param_2, param_3), vec3(_5630));\n    }\n    return c;\n}\n\nvec3 fa_transmitted(Surface s, vec3 n, vec3 v, float roughness, vec3 f0, float f90, float keep, float tr, inout float blend)\n{\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05);\n    vec2 _5665 = fa_env_brdf(param, param_1);\n    vec3 through = ((vec3(1.0) - clamp((f0 * _5665.x) + (vec3(f90) * _5665.y), vec3(0.0), vec3(1.0))) * s.albedo) * (tr * keep);\n    float _5693 = max(s.thickness, 0.0);\n    bool _5698 = _5693 > 0.0;\n    if ((s.attenuation_distance > 0.0) && _5698)\n    {\n        through *= exp((-((-log(clamp(s.attenuation_color, vec3(9.9999997473787516355514526367188e-05), vec3(1.0)))) / vec3(s.attenuation_distance))) * _5693);\n    }\n    bool _5723 = fa_mesh_fs_params[30].w > 1.5;\n    bool _5730;\n    if (!_5723)\n    {\n        _5730 = fa_mesh_fs_params[30].w < 0.5;\n    }\n    else\n    {\n        _5730 = _5723;\n    }\n    if (_5730)\n    {\n        blend = clamp(dot(through, vec3(0.3333333432674407958984375)), 0.0, 0.980000019073486328125);\n        return vec3(0.0);\n    }\n    vec3 world = fa_world_pos;\n    if (_5698)\n    {\n        world += (refract(-v, n, 1.0 / max(s.ior, 1.0)) * _5693);\n    }\n    vec4 _5765 = vec4(world, 1.0);\n    float _5770 = dot(fa_mesh_fs_params[28], _5765);\n    vec2 uv = vec2(0.5);\n    if (_5770 > 9.9999997473787516355514526367188e-05)\n    {\n        vec2 _5788 = vec2(dot(fa_mesh_fs_params[26], _5765), dot(fa_mesh_fs_params[27], _5765)) / vec2(_5770);\n        float _5796;\n        if (fa_mesh_fs_params[24].y > 0.5)\n        {\n            _5796 = (_5788.y * 0.5) + 0.5;\n        }\n        else\n        {\n            _5796 = 0.5 - (_5788.y * 0.5);\n        }\n        uv = vec2((_5788.x * 0.5) + 0.5, _5796);\n    }\n    vec2 param_2 = clamp(uv, vec2(0.0), vec2(1.0));\n    float param_3 = (clamp(roughness, 0.0, 1.0) * clamp((2.0 * s.ior) - 2.0, 0.0, 1.0)) * max(fa_mesh_fs_params[31].w - 1.0, 0.0);\n    return through * fa_xm_sample(param_2, param_3);\n}\n\nvec3 fa_shadow_debug(vec3 color, vec3 world)\n{\n    if (fa_shadows[27].w < 0.5)\n    {\n        return color;\n    }\n    int _3311 = int(fa_shadows[25].x + 0.5);\n    float _3321 = dot(world - fa_shadows[27].xyz, fa_shadows[28].xyz);\n    vec3 tint_1 = vec3(0.3499999940395355224609375);\n    bool _3326 = _3311 > 0;\n    bool _3335;\n    if (_3326)\n    {\n        int param = _3311 - 1;\n        _3335 = _3321 <= fa_shadow_split_at(param);\n    }\n    else\n    {\n        _3335 = _3326;\n    }\n    if (_3335)\n    {\n        tint_1 = vec3(1.0, 0.1500000059604644775390625, 0.100000001490116119384765625);\n        bool _3341 = _3311 > 1;\n        bool _3348;\n        if (_3341)\n        {\n            _3348 = _3321 > fa_shadows[24].x;\n        }\n        else\n        {\n            _3348 = _3341;\n        }\n        if (_3348)\n        {\n            tint_1 = vec3(0.100000001490116119384765625, 0.89999997615814208984375, 0.20000000298023223876953125);\n        }\n        bool _3354 = _3311 > 2;\n        bool _3361;\n        if (_3354)\n        {\n            _3361 = _3321 > fa_shadows[24].y;\n        }\n        else\n        {\n            _3361 = _3354;\n        }\n        if (_3361)\n        {\n            tint_1 = vec3(0.1500000059604644775390625, 0.300000011920928955078125, 1.0);\n        }\n        bool _3367 = _3311 > 3;\n        bool _3374;\n        if (_3367)\n        {\n            _3374 = _3321 > fa_shadows[24].z;\n        }\n        else\n        {\n            _3374 = _3367;\n        }\n        if (_3374)\n        {\n            tint_1 = vec3(1.0, 0.89999997615814208984375, 0.100000001490116119384765625);\n        }\n    }\n    return mix(color, tint_1, vec3(0.550000011920928955078125));\n}\n\nvoid main()\n{\n    fa_inst_load();\n    vec3 _8775 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _8775 = -_8775;\n    }\n    vec3 _8072 = normalize(fa_mesh_fs_params[0].xyz - fa_world_pos);\n    vec3 param = fa_world_pos;\n    fa_cluster_begin(param);\n    SurfaceInput param_1 = SurfaceInput(fa_world_pos, _8775, fa_world_tangent, fa_uv, fa_vertex_color, _8072, gl_FrontFacing);\n    Surface _8080 = fa_standard_surface(param_1);\n    vec3 _8806 = _8080.albedo;\n    float _8807 = _8080.alpha;\n    vec3 _8808 = _8080.normal;\n    float _8809 = _8080.metallic;\n    float _8810 = _8080.roughness;\n    float _8811 = _8080.occlusion;\n    vec3 _8812 = _8080.emission;\n    float _8813 = _8080.clearcoat;\n    float _8814 = _8080.clearcoat_roughness;\n    vec3 _8815 = _8080.sheen_color;\n    float _8816 = _8080.sheen_roughness;\n    float _8817 = _8080.anisotropy;\n    float _8818 = _8080.anisotropy_rotation;\n    float _8819 = _8080.specular;\n    float _8820 = _8080.ior;\n    vec3 _8821 = _8080.specular_color;\n    float _8822 = _8080.transmission;\n    float _8823 = _8080.thickness;\n    vec3 _8824 = _8080.attenuation_color;\n    float _8825 = _8080.attenuation_distance;\n    SurfaceInput param_2 = SurfaceInput(fa_world_pos, _8775, fa_world_tangent, fa_uv, fa_vertex_color, _8072, gl_FrontFacing);\n    Surface param_3 = _8080;\n    surface(param_2, param_3);\n    _8806 = param_3.albedo;\n    _8807 = param_3.alpha;\n    _8808 = param_3.normal;\n    _8809 = param_3.metallic;\n    _8810 = param_3.roughness;\n    _8811 = param_3.occlusion;\n    _8812 = param_3.emission;\n    _8813 = param_3.clearcoat;\n    _8814 = param_3.clearcoat_roughness;\n    _8815 = param_3.sheen_color;\n    _8816 = param_3.sheen_roughness;\n    _8817 = param_3.anisotropy;\n    _8818 = param_3.anisotropy_rotation;\n    _8819 = param_3.specular;\n    _8820 = param_3.ior;\n    _8821 = param_3.specular_color;\n    _8822 = param_3.transmission;\n    _8823 = param_3.thickness;\n    _8824 = param_3.attenuation_color;\n    _8825 = param_3.attenuation_distance;\n    vec3 param_4 = fa_world_pos;\n    vec3 param_5 = _8775;\n    vec3 param_6 = param_3.albedo;\n    vec3 param_7 = param_3.normal;\n    fa_apply_decals(param_4, param_5, param_6, param_7);\n    _8806 = param_6;\n    _8808 = param_7;\n    fa_lod_dither();\n    float fa_tr_blend = 0.0;\n    vec3 result;\n    if (fa_mesh_fs_params[3].w > 0.5)\n    {\n        result = _8806;\n    }\n    else\n    {\n        vec3 _8121 = normalize(_8808);\n        float _8128 = clamp(_8809, 0.0, 1.0);\n        float _8132 = clamp(_8810, 0.0500000007450580596923828125, 1.0);\n        float _8136 = _8132 * _8132;\n        float _8140 = _8136 * _8136;\n        float _8145 = max(dot(_8121, _8072), 9.9999997473787516355514526367188e-05);\n        float _8151 = 1.0 - _8128;\n        float _8152 = clamp(_8822, 0.0, 1.0) * _8151;\n        vec3 _8161 = (_8806 * _8151) * (1.0 - _8152);\n        vec3 _8168 = mix(vec3(0.039999999105930328369140625), _8806, vec3(_8128));\n        vec3 f0 = _8168;\n        SurfaceInput param_8 = SurfaceInput(fa_world_pos, _8775, fa_world_tangent, fa_uv, fa_vertex_color, _8072, gl_FrontFacing);\n        Surface param_9 = Surface(_8806, _8807, _8808, _8809, _8810, _8811, _8812, _8813, _8814, _8815, _8816, _8817, _8818, _8819, _8820, _8821, _8822, _8823, _8824, _8825);\n        vec3 param_10 = _8121;\n        vec3 param_11 = _8072;\n        float param_12 = _8128;\n        float param_13 = _8132;\n        vec3 param_14 = _8168;\n        FaLayers _8184 = fa_layers_setup(param_8, param_9, param_10, param_11, param_12, param_13, param_14);\n        f0 = param_14;\n        vec3 param_15 = _8121;\n        vec3 lit = (fa_indirect_diffuse(param_15) * _8161) * _8811;\n        if (_8184.on)\n        {\n            lit *= _8184.base_scale;\n        }\n        int _8206 = fa_cl_ndir + fa_cl_local;\n        float _8271;\n        for (int ln = 0; ln < _8206; ln++)\n        {\n            int param_16 = ln;\n            int _8219 = fa_cl_light(param_16);\n            int param_17 = _8219;\n            if (fa_baked_keep(param_17) <= 0.0)\n            {\n                continue;\n            }\n            int param_18 = _8219;\n            vec3 param_19 = fa_world_pos;\n            vec3 param_20 = _8775;\n            LightSample _8235 = fa_light_shadowed(param_18, param_19, param_20);\n            float _8243 = max(dot(_8121, _8235.direction), 0.0);\n            float _8249 = _8235.attenuation * _8235.shadow;\n            vec3 _8254 = normalize(_8235.direction + _8072);\n            float _8259 = max(dot(_8121, _8254), 0.0);\n            float _8264 = max(dot(_8072, _8254), 0.0);\n            if (fa_light_is_area)\n            {\n                if (_8184.on)\n                {\n                    _8271 = _8184.f90;\n                }\n                else\n                {\n                    _8271 = 1.0;\n                }\n                int param_21 = _8219;\n                vec3 param_22 = fa_world_pos;\n                vec3 param_23 = _8121;\n                vec3 param_24 = _8072;\n                vec3 param_25 = _8161;\n                vec3 param_26 = f0;\n                float param_27 = _8271;\n                float param_28 = _8132;\n                float param_29 = _8145;\n                float param_30 = _8249;\n                vec3 area = fa_area_shade(param_21, param_22, param_23, param_24, param_25, param_26, param_27, param_28, param_29, param_30);\n                if (_8184.on)\n                {\n                    FaLayers param_31 = _8184;\n                    vec3 param_32 = area;\n                    int param_33 = _8219;\n                    vec3 param_34 = _8121;\n                    vec3 param_35 = _8072;\n                    vec3 param_36 = _8235.direction;\n                    float param_37 = _8145;\n                    float param_38 = _8249;\n                    area = fa_area_layers(param_31, param_32, param_33, param_34, param_35, param_36, param_37, param_38);\n                }\n                lit += area;\n            }\n            else\n            {\n                if (_8184.on)\n                {\n                    FaLayers param_39 = _8184;\n                    vec3 param_40 = _8161;\n                    vec3 param_41 = f0;\n                    vec3 param_42 = _8121;\n                    vec3 param_43 = _8072;\n                    vec3 param_44 = _8235.direction;\n                    vec3 param_45 = _8254;\n                    float param_46 = _8243;\n                    float param_47 = _8145;\n                    float param_48 = _8259;\n                    float param_49 = _8264;\n                    float param_50 = _8136;\n                    float param_51 = _8140;\n                    int param_52 = _8219;\n                    lit += (fa_layers_light(param_39, param_40, param_41, param_42, param_43, param_44, param_45, param_46, param_47, param_48, param_49, param_50, param_51) * ((fa_light_rgb(param_52) * fa_light_tint) * _8249));\n                }\n                else\n                {\n                    float _8373 = ((_8259 * _8259) * (_8140 - 1.0)) + 1.0;\n                    int param_53 = _8219;\n                    lit += (((_8161 + (((f0 + ((vec3(1.0) - f0) * pow(1.0 - _8264, 5.0))) * (((_8140 / ((3.1415927410125732421875 * _8373) * _8373)) * (0.5 / max(mix((2.0 * _8243) * _8145, _8243 + _8145, _8136), 9.9999997473787516355514526367188e-05))) * 3.1415927410125732421875)) * step(9.9999997473787516355514526367188e-05, _8243))) * (fa_light_rgb(param_53) * fa_light_tint)) * (_8243 * _8249));\n                }\n            }\n        }\n        if (_8184.on)\n        {\n            FaLayers param_54 = _8184;\n            vec3 param_55 = _8121;\n            vec3 param_56 = _8072;\n            vec3 param_57 = f0;\n            float param_58 = _8132;\n            float param_59 = _8811;\n            lit += fa_layers_ibl(param_54, param_55, param_56, param_57, param_58, param_59);\n        }\n        else\n        {\n            vec3 param_60 = _8121;\n            vec3 param_61 = _8072;\n            vec3 param_62 = f0;\n            float param_63 = _8132;\n            lit += (fa_sky_reflection(param_60, param_61, param_62, param_63) * _8811);\n        }\n        if (_8152 > 0.0)\n        {\n            float _8471;\n            if (_8184.on)\n            {\n                _8471 = _8184.f90;\n            }\n            else\n            {\n                _8471 = 1.0;\n            }\n            float _8479;\n            if (_8184.on)\n            {\n                _8479 = _8184.base_scale;\n            }\n            else\n            {\n                _8479 = 1.0;\n            }\n            Surface param_64 = Surface(_8806, _8807, _8808, _8809, _8810, _8811, _8812, _8813, _8814, _8815, _8816, _8817, _8818, _8819, _8820, _8821, _8822, _8823, _8824, _8825);\n            vec3 param_65 = _8121;\n            vec3 param_66 = _8072;\n            float param_67 = _8132;\n            vec3 param_68 = f0;\n            float param_69 = _8471;\n            float param_70 = _8479;\n            float param_71 = _8152;\n            float param_72 = fa_tr_blend;\n            vec3 _8503 = fa_transmitted(param_64, param_65, param_66, param_67, param_68, param_69, param_70, param_71, param_72);\n            fa_tr_blend = param_72;\n            lit += _8503;\n        }\n        result = lit;\n    }\n    vec3 _8510 = result;\n    vec3 _8511 = _8510 + _8812;\n    result = _8511;\n    vec3 param_73 = _8511;\n    vec3 param_74 = fa_world_pos;\n    result = fa_shadow_debug(param_73, param_74);\n    bool _8520 = fa_mesh_fs_params[7].w > 0.0;\n    bool _8527;\n    if (!_8520)\n    {\n        _8527 = fa_mesh_fs_params[8].y > 0.0;\n    }\n    else\n    {\n        _8527 = _8520;\n    }\n    if (_8527)\n    {\n        vec3 _8536 = fa_world_pos - fa_mesh_fs_params[0].xyz;\n        float _8542 = dot(_8536, fa_mesh_fs_params[9].xyz);\n        bool _8546 = fa_mesh_fs_params[9].w > 0.5;\n        float _8547;\n        if (_8546)\n        {\n            _8547 = _8542;\n        }\n        else\n        {\n            _8547 = length(_8536);\n        }\n        float _8559 = _8547 - fa_mesh_fs_params[8].x;\n        if (_8559 > 0.0)\n        {\n            float _8568 = fa_mesh_fs_params[7].w * _8559;\n            float tau = _8568 * _8568;\n            if (fa_mesh_fs_params[8].y > 0.0)\n            {\n                float _8584;\n                if (_8546)\n                {\n                    _8584 = fa_world_pos.y - (fa_mesh_fs_params[9].y * _8542);\n                }\n                else\n                {\n                    _8584 = fa_mesh_fs_params[0].y;\n                }\n                float _8605 = mix(_8584, fa_world_pos.y, clamp(fa_mesh_fs_params[8].x / _8547, 0.0, 1.0));\n                float _8609 = fa_world_pos.y - _8605;\n                float _8614 = _8605 - fa_mesh_fs_params[8].z;\n                float _8619 = fa_world_pos.y - fa_mesh_fs_params[8].z;\n                bool _8622 = _8614 <= 0.0;\n                bool _8623 = !_8622;\n                bool _8629;\n                if (_8623)\n                {\n                    _8629 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _8629 = _8622;\n                }\n                float _8630;\n                if (_8629)\n                {\n                    _8630 = fa_mesh_fs_params[8].y;\n                }\n                else\n                {\n                    _8630 = fa_mesh_fs_params[8].y * exp(-min(fa_mesh_fs_params[8].w * _8614, 80.0));\n                }\n                bool _8657;\n                if (_8623)\n                {\n                    _8657 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _8657 = _8622;\n                }\n                float _8658;\n                if (_8657)\n                {\n                    _8658 = fa_mesh_fs_params[8].y * _8614;\n                }\n                else\n                {\n                    _8658 = (fa_mesh_fs_params[8].y * (1.0 - exp(-min(fa_mesh_fs_params[8].w * _8614, 80.0)))) / fa_mesh_fs_params[8].w;\n                }\n                bool _8683 = _8619 <= 0.0;\n                bool _8690;\n                if (!_8683)\n                {\n                    _8690 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _8690 = _8683;\n                }\n                float _8691;\n                if (_8690)\n                {\n                    _8691 = fa_mesh_fs_params[8].y * _8619;\n                }\n                else\n                {\n                    _8691 = (fa_mesh_fs_params[8].y * (1.0 - exp(-min(fa_mesh_fs_params[8].w * _8619, 80.0)))) / fa_mesh_fs_params[8].w;\n                }\n                float _8718;\n                if (abs(_8609) < 0.001000000047497451305389404296875)\n                {\n                    _8718 = _8630;\n                }\n                else\n                {\n                    _8718 = (_8691 - _8658) / _8609;\n                }\n                tau += (_8559 * max(_8718, 0.0));\n            }\n            result = mix(result, fa_mesh_fs_params[7].xyz, vec3(clamp(1.0 - exp(-clamp(tau, 0.0, 80.0)), 0.0, 1.0)));\n        }\n    }\n    if (fa_tr_blend > 0.0)\n    {\n        float _8754 = 1.0 - fa_tr_blend;\n        result /= vec3(_8754);\n        _8807 *= _8754;\n    }\n    fa_frag_color = vec4(result, _8807);\n}\n\n",
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
            "inst_name": "_608",
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
            "inst_name": "_2352",
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
            "inst_name": "_7007",
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
      "fs": "#version 430\n\nstruct SurfaceInput\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 vertex_color;\n    vec3 view_dir;\n    bool front_facing;\n};\n\nstruct LightSample\n{\n    vec3 direction;\n    vec3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct Surface\n{\n    vec3 albedo;\n    float alpha;\n    vec3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    vec3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    vec3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    vec3 specular_color;\n    float transmission;\n    float thickness;\n    vec3 attenuation_color;\n    float attenuation_distance;\n};\n\nstruct FaLayers\n{\n    bool on;\n    float f90;\n    float keep;\n    float base_scale;\n    float coat;\n    float coat_rough;\n    float coat_alpha;\n    float coat_a2;\n    vec3 nc;\n    float coat_ndv;\n    bool sheen_on;\n    vec3 sheen;\n    float sheen_rough;\n    float sheen_alpha;\n    float sheen_scale;\n    float sheen_e;\n    float aniso;\n    vec3 t;\n    vec3 b;\n    float at;\n    float ab;\n};\n\nconst float _4395[63] = float[](1.0, 1.0, 1.0, 0.4790000021457672119140625, 0.11699999868869781494140625, 0.01200000010430812835693359375, 0.0, 0.0, 0.0, 1.0, 1.0, 1.0, 0.578000009059906005859375, 0.19300000369548797607421875, 0.0350000001490116119384765625, 0.0030000000260770320892333984375, 0.0, 0.0, 1.0, 1.0, 1.0, 0.6740000247955322265625, 0.3459999859333038330078125, 0.1319999992847442626953125, 0.032999999821186065673828125, 0.0040000001899898052215576171875, 0.0, 0.971000015735626220703125, 0.954999983310699462890625, 0.828999996185302734375, 0.63999998569488525390625, 0.42599999904632568359375, 0.24500000476837158203125, 0.115000002086162567138671875, 0.037000000476837158203125, 0.0030000000260770320892333984375, 0.7469999790191650390625, 0.737999975681304931640625, 0.670000016689300537109375, 0.563000023365020751953125, 0.4309999942779541015625, 0.3039999902248382568359375, 0.1940000057220458984375, 0.1019999980926513671875, 0.0309999994933605194091796875, 0.614000022411346435546875, 0.609000027179718017578125, 0.566999971866607666015625, 0.499000012874603271484375, 0.412000000476837158203125, 0.32400000095367431640625, 0.240999996662139892578125, 0.162000000476837158203125, 0.087999999523162841796875, 0.538999974727630615234375, 0.535000026226043701171875, 0.505999982357025146484375, 0.4569999873638153076171875, 0.393999993801116943359375, 0.328999996185302734375, 0.2660000026226043701171875, 0.203999996185302734375, 0.14200000464916229248046875);\n\nuniform vec4 fa_mesh_fs_params[53];\nuniform vec4 fa_shadows[30];\nuniform vec4 fa_material[1];\nlayout(binding = 0) uniform sampler2D fa_light_tex_fa_shadow_smp;\nlayout(binding = 1) uniform sampler2D fa_tex_fa_smp;\nlayout(binding = 2) uniform sampler2D fa_normal_tex_fa_smp;\nlayout(binding = 3) uniform sampler2D fa_mr_tex_fa_smp;\nlayout(binding = 4) uniform sampler2D fa_occlusion_tex_fa_smp;\nlayout(binding = 5) uniform sampler2D fa_emissive_tex_fa_smp;\nlayout(binding = 6) uniform sampler2D fa_decal_tex_fa_env_smp;\nlayout(binding = 7) uniform sampler2D fa_lightmap_fa_env_smp;\nlayout(binding = 8) uniform sampler2D fa_probe_atlas_fa_env_smp;\nlayout(binding = 9) uniform sampler2D fa_light_atlas_fa_env_smp;\nlayout(binding = 10) uniform sampler2D fa_shadow_tex_fa_shadow_smp;\nlayout(binding = 11) uniform sampler2D fa_screen_tex_fa_shadow_smp;\n\nlayout(location = 2) in vec3 fa_world_pos;\nlayout(location = 7) in vec3 fa_lm;\nlayout(location = 0) flat in vec4 fa_inst_v0;\nlayout(location = 1) flat in vec4 fa_inst_v1;\nlayout(location = 3) in vec3 fa_world_normal;\nlayout(location = 4) in vec4 fa_world_tangent;\nlayout(location = 5) in vec2 fa_uv;\nlayout(location = 6) in vec4 fa_vertex_color;\nlayout(location = 0) out vec4 fa_frag_color;\nvec3 fa_light_tint;\nbool fa_light_is_area;\nint fa_cl_ndir;\nint fa_cl_slot;\nint fa_cl_local;\nfloat raise;\nvec4 tint;\n\nvoid fa_instance_unpack(vec4 fa_d0, vec4 fa_d1, vec4 fa_d2)\n{\n    raise = fa_d0.x;\n    tint = fa_d1;\n}\n\nvoid fa_inst_load()\n{\n    vec4 param = fa_inst_v0;\n    vec4 param_1 = fa_inst_v1;\n    vec4 param_2 = vec4(0.0);\n    fa_instance_unpack(param, param_1, param_2);\n}\n\nvec4 fa_light_texel(int t)\n{\n    return texelFetch(fa_light_tex_fa_shadow_smp, ivec2(t & 1023, t >> 10), 0);\n}\n\nvec4 fa_cluster_texel(vec3 world_pos)\n{\n    bool _1634 = fa_mesh_fs_params[19].x < 0.0;\n    bool _1641;\n    if (!_1634)\n    {\n        _1641 = fa_mesh_fs_params[19].w < 1.0;\n    }\n    else\n    {\n        _1641 = _1634;\n    }\n    bool _1649;\n    if (!_1641)\n    {\n        _1649 = fa_mesh_fs_params[18].x < 1.0;\n    }\n    else\n    {\n        _1649 = _1641;\n    }\n    bool _1656;\n    if (!_1649)\n    {\n        _1656 = fa_mesh_fs_params[18].y < 1.0;\n    }\n    else\n    {\n        _1656 = _1649;\n    }\n    bool _1663;\n    if (!_1656)\n    {\n        _1663 = fa_mesh_fs_params[19].y < 1.0;\n    }\n    else\n    {\n        _1663 = _1656;\n    }\n    if (_1663)\n    {\n        return vec4(0.0);\n    }\n    vec4 _1673 = vec4(world_pos, 1.0);\n    float _1679 = dot(fa_mesh_fs_params[16], _1673);\n    if (!(_1679 > 9.9999999747524270787835121154785e-07))\n    {\n        return vec4(0.0);\n    }\n    vec2 _1701 = vec2(dot(fa_mesh_fs_params[14], _1673), dot(fa_mesh_fs_params[15], _1673)) / vec2(_1679);\n    int _1705 = int(fa_mesh_fs_params[18].x);\n    int _1709 = int(fa_mesh_fs_params[18].y);\n    int param = (int(fa_mesh_fs_params[19].x) + (((clamp(int(floor(log2(max(dot(fa_mesh_fs_params[17].xyz, world_pos) + fa_mesh_fs_params[17].w, fa_mesh_fs_params[18].w) / fa_mesh_fs_params[18].w) * fa_mesh_fs_params[18].z)), 0, int(fa_mesh_fs_params[19].y) - 1) * _1709) + clamp(int(floor(((_1701.y * 0.5) + 0.5) * fa_mesh_fs_params[18].y)), 0, _1709 - 1)) * _1705)) + clamp(int(floor(((_1701.x * 0.5) + 0.5) * fa_mesh_fs_params[18].x)), 0, _1705 - 1);\n    return fa_light_texel(param);\n}\n\nivec2 fa_cluster_lookup(vec3 world_pos)\n{\n    vec3 param = world_pos;\n    vec4 _1785 = fa_cluster_texel(param);\n    return ivec2(int(_1785.x), int(_1785.y));\n}\n\nvoid fa_cluster_begin(vec3 world_pos)\n{\n    fa_cl_ndir = int(fa_mesh_fs_params[19].z);\n    vec3 param = world_pos;\n    ivec2 _5870 = fa_cluster_lookup(param);\n    fa_cl_slot = _5870.x;\n    fa_cl_local = _5870.y;\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nvec3 fa_linear_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_tex_fix(inout vec3 c, float mode)\n{\n    if (mode > 1.5)\n    {\n        vec3 param = c;\n        vec3 _7059 = fa_linear_to_srgb(param);\n        c = _7059;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            vec3 param_1 = c;\n            vec3 _7067 = fa_srgb_to_linear(param_1);\n            c = _7067;\n        }\n    }\n    return c;\n}\n\nvec3 fa_tangent_normal(SurfaceInput i, vec3 m)\n{\n    vec3 _540;\n    if (i.front_facing)\n    {\n        _540 = i.world_normal;\n    }\n    else\n    {\n        _540 = -i.world_normal;\n    }\n    vec3 _564 = normalize(i.world_tangent.xyz - (_540 * dot(_540, i.world_tangent.xyz)));\n    vec3 _591 = normalize(((_564 * m.x) + ((cross(_540, _564) * i.world_tangent.w) * m.y)) + (_540 * m.z));\n    vec3 _594;\n    if (i.front_facing)\n    {\n        _594 = _591;\n    }\n    else\n    {\n        _594 = -_591;\n    }\n    return _594;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    vec4 base_t = texture(fa_tex_fa_smp, i.uv);\n    float param = fa_mesh_fs_params[6].w;\n    float param_1 = 1.0;\n    vec3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    vec3 _7098 = fa_tex_fix(param_2, param_3);\n    vec4 _9360 = base_t;\n    _9360.x = _7098.x;\n    _9360.y = _7098.y;\n    _9360.z = _7098.z;\n    base_t = _9360;\n    vec4 _7112 = (_9360 * fa_mesh_fs_params[2]) * i.vertex_color;\n    vec3 _9136 = i.world_normal;\n    if (fa_mesh_fs_params[6].z > 0.5)\n    {\n        float param_4 = fa_mesh_fs_params[6].w;\n        float param_5 = 16.0;\n        vec3 param_6 = texture(fa_normal_tex_fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        vec3 _7144 = fa_tex_fix(param_6, param_7);\n        vec3 _7147 = (_7144 * 2.0) - vec3(1.0);\n        vec2 _7152 = _7147.xy * fa_mesh_fs_params[6].x;\n        vec3 _9368 = _7147;\n        _9368.x = _7152.x;\n        _9368.y = _7152.y;\n        SurfaceInput param_8 = i;\n        vec3 param_9 = _9368;\n        _9136 = fa_tangent_normal(param_8, param_9);\n    }\n    vec4 mrt = texture(fa_mr_tex_fa_smp, i.uv);\n    float param_10 = fa_mesh_fs_params[6].w;\n    float param_11 = 64.0;\n    vec3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    vec3 _7180 = fa_tex_fix(param_12, param_13);\n    vec4 _9371 = mrt;\n    _9371.x = _7180.x;\n    _9371.y = _7180.y;\n    _9371.z = _7180.z;\n    mrt = _9371;\n    vec4 _7208 = texture(fa_occlusion_tex_fa_smp, i.uv);\n    float param_14 = fa_mesh_fs_params[6].w;\n    float param_15 = 256.0;\n    vec3 param_16 = _7208.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    vec3 _7219 = fa_tex_fix(param_16, param_17);\n    float param_18 = fa_mesh_fs_params[6].w;\n    float param_19 = 4.0;\n    vec3 param_20 = texture(fa_emissive_tex_fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    vec3 _7249 = fa_tex_fix(param_20, param_21);\n    float _9141 = fa_mesh_fs_params[20].x;\n    float _9142 = fa_mesh_fs_params[20].y;\n    float _9145 = fa_mesh_fs_params[20].z;\n    float _9144 = fa_mesh_fs_params[21].w;\n    float _9147 = fa_mesh_fs_params[22].x;\n    if (fa_mesh_fs_params[22].z > 0.5)\n    {\n        if (mod(fa_mesh_fs_params[22].z, 2.0) > 0.5)\n        {\n            _9141 *= _7219.y;\n            _9142 *= _7219.z;\n            _9144 *= _7208.w;\n        }\n        if (fa_mesh_fs_params[22].z > 1.5)\n        {\n            _9145 *= mrt.x;\n            _9147 *= mrt.w;\n        }\n    }\n    return Surface(_7112.xyz, _7112.w, _9136, clamp(fa_mesh_fs_params[5].x * _7180.z, 0.0, 1.0), clamp(fa_mesh_fs_params[5].y * _7180.y, 0.0500000007450580596923828125, 1.0), 1.0 + (fa_mesh_fs_params[6].y * (_7219.x - 1.0)), fa_mesh_fs_params[3].xyz + (fa_mesh_fs_params[4].xyz * _7249), _9141, _9142, fa_mesh_fs_params[21].xyz, _9144, _9145, fa_mesh_fs_params[20].w, _9147, fa_mesh_fs_params[22].y, fa_mesh_fs_params[23].xyz, fa_mesh_fs_params[30].x, fa_mesh_fs_params[30].y, fa_mesh_fs_params[31].xyz, fa_mesh_fs_params[30].z);\n}\n\nvoid surface(SurfaceInput i, inout Surface s)\n{\n    s.emission += ((tint.xyz * tint.w) * fa_material[0].x);\n}\n\nvec4 fa_decal_tile(vec4 rect, vec2 uv, vec2 atlas, vec2 ddx, vec2 ddy)\n{\n    vec2 _1865 = rect.zw - rect.xy;\n    vec2 _1869 = _1865 * atlas;\n    vec2 _1873 = ddx * _1869;\n    vec2 _1877 = ddy * _1869;\n    return textureLod(fa_decal_tex_fa_env_smp, rect.xy + (clamp(uv, vec2(0.0), vec2(1.0)) * _1865), clamp(0.5 * log2(max(max(dot(_1873, _1873), dot(_1877, _1877)), 9.9999999392252902907785028219223e-09)), 0.0, 3.0));\n}\n\nvec3 fa_dc_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_dc_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvoid fa_apply_decals(vec3 world_pos, vec3 geo_normal, inout vec3 albedo, inout vec3 normal)\n{\n    bool _1910 = fa_mesh_fs_params[10].y < 0.5;\n    bool _1917;\n    if (!_1910)\n    {\n        _1917 = fa_mesh_fs_params[10].w < 0.5;\n    }\n    else\n    {\n        _1917 = _1910;\n    }\n    if (_1917)\n    {\n        return;\n    }\n    vec3 _1923 = dFdx(world_pos);\n    vec3 _1926 = dFdy(world_pos);\n    vec3 param = world_pos;\n    vec4 _1930 = fa_cluster_texel(param);\n    int _1934 = int(_1930.w);\n    if (_1934 < 1)\n    {\n        return;\n    }\n    int _1944 = int(fa_mesh_fs_params[10].y + 0.5);\n    int param_1 = _1944;\n    vec4 _1948 = fa_light_texel(param_1);\n    vec2 _1951 = _1948.yz;\n    int _1955 = int(_1948.w);\n    int param_2 = _1944 + 1;\n    vec4 _1960 = fa_light_texel(param_2);\n    float _1961 = _1960.x;\n    int _1967 = int(fa_mesh_fs_params[10].w + 0.5) - 1;\n    int _1971 = int(_1930.z);\n    vec3 _2236;\n    for (int k = 0; k < _1934; k++)\n    {\n        int _1984 = _1971 + k;\n        int param_3 = _1955 + (_1984 >> 2);\n        int _2001 = (_1944 + 2) + (int(fa_light_texel(param_3)[_1984 & 3]) * 7);\n        int param_4 = _2001 + 6;\n        vec4 _2006 = fa_light_texel(param_4);\n        if (((int(_2006.w + 0.5) >> _1967) & 1) == 0)\n        {\n            continue;\n        }\n        int param_5 = _2001;\n        vec4 _2021 = fa_light_texel(param_5);\n        int param_6 = _2001 + 1;\n        vec4 _2026 = fa_light_texel(param_6);\n        int param_7 = _2001 + 2;\n        vec4 _2031 = fa_light_texel(param_7);\n        vec3 _2034 = _2021.xyz;\n        float _2039 = dot(_2034, world_pos) + _2021.w;\n        vec3 _2041 = _2026.xyz;\n        float _2046 = dot(_2041, world_pos) + _2026.w;\n        vec3 _2048 = _2031.xyz;\n        float _2053 = dot(_2048, world_pos) + _2031.w;\n        bool _2058 = abs(_2039) > 0.5;\n        bool _2066;\n        if (!_2058)\n        {\n            _2066 = abs(_2046) > 0.5;\n        }\n        else\n        {\n            _2066 = _2058;\n        }\n        bool _2074;\n        if (!_2066)\n        {\n            _2074 = abs(_2053) > 0.5;\n        }\n        else\n        {\n            _2074 = _2066;\n        }\n        if (_2074)\n        {\n            continue;\n        }\n        float _2089 = clamp(dot(geo_normal, normalize(_2048)) * _2006.z, 0.0, 1.0);\n        if (_2089 <= 0.0)\n        {\n            continue;\n        }\n        float _2109 = (clamp((0.5 - abs(_2053)) * 10.0, 0.0, 1.0) * _2089) * _2006.x;\n        vec2 _2117 = vec2(_2039 + 0.5, 0.5 - _2046);\n        vec2 _2127 = vec2(dot(_2034, _1923), dot(_2041, _1923));\n        vec2 _2137 = vec2(dot(_2034, _1926), dot(_2041, _1926));\n        int param_8 = _2001 + 5;\n        vec4 _2142 = fa_light_texel(param_8);\n        int param_9 = _2001 + 3;\n        vec4 _2147 = fa_light_texel(param_9);\n        int param_10 = _2001 + 4;\n        vec4 _2152 = fa_light_texel(param_10);\n        float tex_a = 1.0;\n        vec3 col = _2142.xyz;\n        bool _2162 = _2147.z > _2147.x;\n        if (_2162)\n        {\n            vec4 param_11 = _2147;\n            vec2 param_12 = _2117;\n            vec2 param_13 = _1951;\n            vec2 param_14 = _2127;\n            vec2 param_15 = _2137;\n            vec4 tx = fa_decal_tile(param_11, param_12, param_13, param_14, param_15);\n            if ((_1961 > 0.5) && (_1961 < 1.5))\n            {\n                vec3 param_16 = tx.xyz;\n                vec3 _2188 = fa_dc_to_linear(param_16);\n                vec4 _9224 = tx;\n                _9224.x = _2188.x;\n                _9224.y = _2188.y;\n                _9224.z = _2188.z;\n                tx = _9224;\n            }\n            col *= tx.xyz;\n            tex_a = tx.w;\n        }\n        albedo = mix(albedo, col, vec3(clamp((_2109 * tex_a) * _2142.w, 0.0, 1.0)));\n        if (_2152.z > _2152.x)\n        {\n            vec4 param_17 = _2152;\n            vec2 param_18 = _2117;\n            vec2 param_19 = _1951;\n            vec2 param_20 = _2127;\n            vec2 param_21 = _2137;\n            vec4 _2232 = fa_decal_tile(param_17, param_18, param_19, param_20, param_21);\n            if (_1961 > 1.5)\n            {\n                vec3 param_22 = _2232.xyz;\n                vec3 _2242 = fa_dc_to_srgb(param_22);\n                _2236 = _2242;\n            }\n            else\n            {\n                _2236 = _2232.xyz;\n            }\n            vec3 _2251 = (_2236 * 2.0) - vec3(1.0);\n            vec2 _2256 = _2251.xy * _2006.y;\n            vec3 _2278 = (normalize(_2034) * _2256.x) + (normalize(_2041) * _2256.y);\n            vec3 _2281 = normalize(normal);\n            normal = normalize(mix(_2281, normalize((_2281 * max(_2251.z, 0.0500000007450580596923828125)) + (_2278 - (_2281 * dot(_2281, _2278)))), vec3(clamp(_2109 * (_2162 ? tex_a : 1.0), 0.0, 1.0))));\n        }\n    }\n}\n\nvoid fa_lod_dither()\n{\n    if (fa_mesh_fs_params[52].w != 0.0)\n    {\n        float _630 = fract(52.98291778564453125 * fract(dot(gl_FragCoord.xy, vec2(0.067110560834407806396484375, 0.005837149918079376220703125))));\n        bool _633;\n        if (fa_mesh_fs_params[52].w > 0.0)\n        {\n            _633 = _630 >= fa_mesh_fs_params[52].w;\n        }\n        else\n        {\n            _633 = _630 < (-fa_mesh_fs_params[52].w);\n        }\n        if (_633)\n        {\n            discard;\n        }\n    }\n}\n\nfloat fa_sheen_albedo(float ndv, float rough)\n{\n    float _4320 = min(sqrt(max(rough - 0.100000001490116119384765625, 0.0) * 1.111111164093017578125) * 6.0, 5.999000072479248046875);\n    float _4328 = min(sqrt(clamp(ndv, 0.0, 1.0)) * 8.0, 7.999000072479248046875);\n    int _4331 = int(_4320);\n    int _4334 = int(_4328);\n    float _4344 = _4328 - float(_4334);\n    int _4399 = (_4331 * 9) + _4334;\n    int _4419 = ((_4331 + 1) * 9) + _4334;\n    return mix(mix(_4395[_4399], _4395[_4399 + 1], _4344), mix(_4395[_4419], _4395[_4419 + 1], _4344), _4320 - float(_4331));\n}\n\nFaLayers fa_layers_setup(SurfaceInput i, Surface s, vec3 n, vec3 v, float metallic, float roughness, inout vec3 f0)\n{\n    bool _9059 = false;\n    float _9060 = 1.0;\n    float _9061 = 1.0;\n    float _9062 = 1.0;\n    float _9063 = 0.0;\n    float _9064 = 0.0;\n    float _9065 = 0.0;\n    float _9066 = 0.0;\n    float _9068 = 1.0;\n    bool _9069 = false;\n    vec3 _9070 = vec3(0.0);\n    float _9071 = 1.0;\n    float _9072 = 1.0;\n    float _9073 = 1.0;\n    float _9074 = 0.0;\n    float _9075 = 0.0;\n    vec3 _9076 = vec3(1.0, 0.0, 0.0);\n    vec3 _9077 = vec3(0.0, 0.0, 1.0);\n    float _9078 = 1.0;\n    float _9079 = 1.0;\n    float _4470 = clamp(s.specular, 0.0, 1.0);\n    float _4474 = clamp(s.ior, 1.0, 3.0);\n    bool _4479 = (_4470 != 1.0) || (_4474 != 1.5);\n    bool _4488;\n    if (!_4479)\n    {\n        _4488 = any(notEqual(s.specular_color, vec3(1.0)));\n    }\n    else\n    {\n        _4488 = _4479;\n    }\n    if (_4488)\n    {\n        float _4496 = (_4474 - 1.0) / (_4474 + 1.0);\n        f0 = mix(min(vec3(_4496 * _4496) * max(s.specular_color, vec3(0.0)), vec3(1.0)) * _4470, s.albedo, vec3(metallic));\n        _9060 = mix(_4470, 1.0, metallic);\n        _9059 = true;\n    }\n    float _4523 = clamp(s.clearcoat, 0.0, 1.0);\n    if (_4523 > 0.0)\n    {\n        float _4531 = clamp(s.clearcoat_roughness, 0.0500000007450580596923828125, 1.0);\n        _9063 = _4523;\n        _9064 = _4531;\n        float _4538 = _4531 * _4531;\n        _9065 = _4538;\n        _9066 = _4538 * _4538;\n        float _4550 = max(dot(i.world_normal, v), 9.9999997473787516355514526367188e-05);\n        _9068 = _4550;\n        _9061 = 1.0 - (_4523 * (0.039999999105930328369140625 + (0.959999978542327880859375 * pow(clamp(1.0 - _4550, 0.0, 1.0), 5.0))));\n        _9059 = true;\n    }\n    vec3 _4569 = max(s.sheen_color, vec3(0.0));\n    float _4578 = max(_4569.x, max(_4569.y, _4569.z));\n    if (_4578 > 0.0)\n    {\n        float _4586 = clamp(s.sheen_roughness, 0.100000001490116119384765625, 1.0);\n        _9069 = true;\n        _9070 = _4569;\n        _9071 = _4586;\n        _9072 = _4586 * _4586;\n        float param = max(dot(n, v), 9.9999997473787516355514526367188e-05);\n        float param_1 = _4586;\n        float _4603 = fa_sheen_albedo(param, param_1);\n        _9074 = _4603;\n        _9073 = 1.0 - min(_4578 * _4603, 1.0);\n        _9059 = true;\n    }\n    _9062 = _9061 * _9073;\n    float _4622 = clamp(s.anisotropy, -1.0, 1.0);\n    if (_4622 != 0.0)\n    {\n        vec3 _4637 = i.world_tangent.xyz - (n * dot(n, i.world_tangent.xyz));\n        vec3 t = _4637;\n        if (dot(_4637, _4637) < 9.9999999392252902907785028219223e-09)\n        {\n            bvec3 _4649 = bvec3(abs(n.y) < 0.9900000095367431640625);\n            t = cross(vec3(_4649.x ? vec3(0.0, 1.0, 0.0).x : vec3(1.0, 0.0, 0.0).x, _4649.y ? vec3(0.0, 1.0, 0.0).y : vec3(1.0, 0.0, 0.0).y, _4649.z ? vec3(0.0, 1.0, 0.0).z : vec3(1.0, 0.0, 0.0).z), n);\n        }\n        vec3 _4653 = t;\n        vec3 _4654 = normalize(_4653);\n        t = _4654;\n        vec3 _4679 = normalize((_4654 * cos(s.anisotropy_rotation)) + ((cross(n, _4654) * ((i.world_tangent.w < 0.0) ? (-1.0) : 1.0)) * sin(s.anisotropy_rotation)));\n        _9076 = _4679;\n        _9077 = cross(n, _4679);\n        float _4689 = roughness * roughness;\n        float _4695 = mix(_4689, 1.0, _4622 * _4622);\n        bool _4697 = _4622 > 0.0;\n        _9078 = _4697 ? _4695 : _4689;\n        _9079 = _4697 ? _4689 : _4695;\n        _9075 = _4622;\n        _9059 = true;\n    }\n    return FaLayers(_9059, _9060, _9061, _9062, _9063, _9064, _9065, _9066, i.world_normal, _9068, _9069, _9070, _9071, _9072, _9073, _9074, _9075, _9076, _9077, _9078, _9079);\n}\n\nvec2 fa_atlas_size()\n{\n    return vec2(textureSize(fa_probe_atlas_fa_env_smp, 0));\n}\n\nvec3 fa_probe_sh_coef(vec2 origin, float res, int k)\n{\n    vec3 v = textureLod(fa_probe_atlas_fa_env_smp, (origin + vec2(float(k) + 0.5, res + 2.5)) / fa_atlas_size(), 0.0).xyz;\n    if (fa_mesh_fs_params[41].y > 0.5)\n    {\n        v = ((v * 255.0) - vec3(128.0)) * 0.03149606287479400634765625;\n    }\n    return v;\n}\n\nvec3 fa_sh_eval(vec3 c[9], vec3 n)\n{\n    vec3 _3488 = max((((c[0] * 0.2820948064327239990234375) + (((c[1] * (0.3257350027561187744140625 * n.y)) + (c[2] * (0.3257350027561187744140625 * n.z))) + (c[3] * (0.3257350027561187744140625 * n.x)))) + (((c[4] * ((0.2731371223926544189453125 * n.x) * n.y)) + (c[5] * ((0.2731371223926544189453125 * n.y) * n.z))) + (c[6] * (0.078847892582416534423828125 * (((3.0 * n.z) * n.z) - 1.0))))) + ((c[7] * ((0.2731371223926544189453125 * n.x) * n.z)) + (c[8] * (0.13656856119632720947265625 * ((n.x * n.x) - (n.y * n.y))))), vec3(0.0));\n    return _3488;\n}\n\nvec3 fa_ambient_light(vec3 n)\n{\n    float _4101 = (1.0 - fa_mesh_fs_params[42].w) - fa_mesh_fs_params[47].w;\n    vec3 amb = vec3(0.0);\n    bool _4106 = fa_mesh_fs_params[11].w > 0.5;\n    vec3 c[9];\n    for (int k = 0; k < 9; k++)\n    {\n        c[k] = vec3(0.0);\n    }\n    if (_4101 > 0.0005000000237487256526947021484375)\n    {\n        if (_4106)\n        {\n            for (int k_1 = 0; k_1 < 9; k_1++)\n            {\n                vec2 param = fa_mesh_fs_params[41].zw;\n                float param_1 = 128.0;\n                int param_2 = k_1;\n                c[k_1] = fa_probe_sh_coef(param, param_1, param_2) * _4101;\n            }\n        }\n        else\n        {\n            amb = fa_mesh_fs_params[1].xyz * _4101;\n        }\n    }\n    bool _4157 = fa_mesh_fs_params[42].w > 0.0;\n    if (_4157)\n    {\n        for (int k_2 = 0; k_2 < 9; k_2++)\n        {\n            vec2 param_3 = fa_mesh_fs_params[42].xy;\n            float param_4 = fa_mesh_fs_params[42].z;\n            int param_5 = k_2;\n            c[k_2] += (fa_probe_sh_coef(param_3, param_4, param_5) * fa_mesh_fs_params[42].w);\n        }\n    }\n    bool _4188 = fa_mesh_fs_params[47].w > 0.0;\n    if (_4188)\n    {\n        for (int k_3 = 0; k_3 < 9; k_3++)\n        {\n            vec2 param_6 = fa_mesh_fs_params[47].xy;\n            float param_7 = fa_mesh_fs_params[47].z;\n            int param_8 = k_3;\n            c[k_3] += (fa_probe_sh_coef(param_6, param_7, param_8) * fa_mesh_fs_params[47].w);\n        }\n    }\n    if ((_4106 || _4157) || _4188)\n    {\n        vec3 param_9[9] = c;\n        vec3 param_10 = n;\n        amb += fa_sh_eval(param_9, param_10);\n    }\n    return amb;\n}\n\nvec4 fa_gi_fetch(vec2 texel)\n{\n    return textureLod(fa_probe_atlas_fa_env_smp, texel / fa_atlas_size(), 0.0);\n}\n\nvec2 fa_oct_encode(vec3 d)\n{\n    vec3 _3508 = d / vec3(max((abs(d.x) + abs(d.y)) + abs(d.z), 9.9999999600419720025001879548654e-13));\n    float _3511 = _3508.x;\n    float _3513 = _3508.z;\n    vec2 e = vec2(_3511, _3513);\n    if (_3508.y < 0.0)\n    {\n        e = vec2((1.0 - abs(_3513)) * ((_3511 < 0.0) ? (-1.0) : 1.0), (1.0 - abs(_3511)) * ((_3513 < 0.0) ? (-1.0) : 1.0));\n    }\n    return e;\n}\n\nvec3 fa_gi_grid(int rec, vec3 n, vec3 v, out float cover)\n{\n    cover = 0.0;\n    int param = rec;\n    vec4 _7359 = fa_light_texel(param);\n    int param_1 = rec + 1;\n    vec4 _7364 = fa_light_texel(param_1);\n    int param_2 = rec + 2;\n    vec4 _7369 = fa_light_texel(param_2);\n    int param_3 = rec + 3;\n    vec4 _7374 = fa_light_texel(param_3);\n    bool _7377 = _7374.z < 0.5;\n    bool _7385;\n    if (!_7377)\n    {\n        _7385 = fa_atlas_size().y < 1155.0;\n    }\n    else\n    {\n        _7385 = _7377;\n    }\n    if (_7385)\n    {\n        return vec3(0.0);\n    }\n    float _7392 = max(_7359.w, 9.9999997473787516355514526367188e-05);\n    vec3 _7395 = _7364.xyz;\n    vec3 _7399 = _7359.xyz;\n    vec3 _7403 = (fa_world_pos - _7399) / vec3(_7392);\n    vec3 _7412 = min(_7403 + vec3(0.5), (_7395 - vec3(0.5)) - _7403);\n    float _7421 = min(_7412.x, min(_7412.y, _7412.z));\n    if (!(_7421 > 0.0))\n    {\n        return vec3(0.0);\n    }\n    vec3 _7436 = _7395 - vec3(1.0);\n    vec3 _7437 = clamp(_7403, vec3(0.0), _7436);\n    vec3 _7445 = min(floor(_7437), max(_7395 - vec3(2.0), vec3(0.0)));\n    vec3 _7449 = _7437 - _7445;\n    vec3 _7460 = fa_world_pos + (((n * 0.800000011920928955078125) + (v * 0.20000000298023223876953125)) * (0.20000000298023223876953125 * _7392));\n    int _7465 = int(_7369.y + 0.5);\n    float _7470 = 0.3257350027561187744140625 * n.y;\n    float _7474 = 0.3257350027561187744140625 * n.z;\n    float _7478 = 0.3257350027561187744140625 * n.x;\n    float _7485 = (0.2731371223926544189453125 * n.x) * n.y;\n    float _7492 = (0.2731371223926544189453125 * n.y) * n.z;\n    float _7501 = 0.078847892582416534423828125 * (((3.0 * n.z) * n.z) - 1.0);\n    float _7508 = (0.2731371223926544189453125 * n.x) * n.z;\n    float _7521 = 0.13656856119632720947265625 * ((n.x * n.x) - (n.y * n.y));\n    vec3 acc = vec3(0.0);\n    float wsum = 0.0;\n    int _7528 = 8 + int(_7374.w);\n    float _7555;\n    float _7568;\n    float _7582;\n    for (int k = 0; k < _7528; k++)\n    {\n        float _7541 = float(k & 1);\n        float _7545 = float((k >> 1) & 1);\n        float _7549 = float((k >> 2) & 1);\n        if (_7541 > 0.5)\n        {\n            _7555 = _7449.x;\n        }\n        else\n        {\n            _7555 = 1.0 - _7449.x;\n        }\n        if (_7545 > 0.5)\n        {\n            _7568 = _7449.y;\n        }\n        else\n        {\n            _7568 = 1.0 - _7449.y;\n        }\n        if (_7549 > 0.5)\n        {\n            _7582 = _7449.z;\n        }\n        else\n        {\n            _7582 = 1.0 - _7449.z;\n        }\n        float _7592 = (_7555 * _7568) * _7582;\n        if (!(_7592 > 0.0))\n        {\n            continue;\n        }\n        vec3 _7605 = min(_7445 + vec3(_7541, _7545, _7549), _7436);\n        int _7625 = int(((_7369.x + _7605.x) + (_7364.x * (_7605.y + (_7364.y * _7605.z)))) + 0.5);\n        vec2 _7640 = vec2(float(_7625 % _7465) * 10.0, 1024.0 + (float(_7625 / _7465) * 11.0));\n        vec2 param_4 = _7640 + vec2(9.5, 10.5);\n        vec4 _7648 = fa_gi_fetch(param_4);\n        bool _7651 = _7648.y < 0.5;\n        bool _7660;\n        if (!_7651)\n        {\n            _7660 = _7648.x > _7374.y;\n        }\n        else\n        {\n            _7660 = _7651;\n        }\n        if (_7660)\n        {\n            continue;\n        }\n        vec3 _7672 = _7460 - (_7399 + (_7605 * _7392));\n        float _7675 = length(_7672);\n        vec3 _7681 = _7672 / vec3(max(_7675, 9.9999997473787516355514526367188e-05));\n        float _7691 = max(9.9999997473787516355514526367188e-05, (dot(-_7681, n) + 1.0) * 0.5);\n        float w = _7592 * (_7691 * _7691);\n        vec3 param_5 = _7681;\n        vec2 param_6 = (_7640 + vec2(1.0)) + (((fa_oct_encode(param_5) * 0.5) + vec2(0.5)) * 8.0);\n        vec4 _7710 = fa_gi_fetch(param_6);\n        float _7717 = _7675 / max(_7369.z, 9.9999997473787516355514526367188e-05);\n        float _7720 = _7710.x;\n        if (_7717 > _7720)\n        {\n            float _7733 = max(_7710.y - (_7720 * _7720), 0.0);\n            float _7738 = _7717 - _7720;\n            float _7747 = _7733 / max(_7733 + (_7738 * _7738), 9.9999999600419720025001879548654e-13);\n            w *= ((_7747 * _7747) * _7747);\n        }\n        if (!(w > 0.0))\n        {\n            continue;\n        }\n        vec2 param_7 = _7640 + vec2(0.5, 10.5);\n        vec2 param_8 = _7640 + vec2(1.5, 10.5);\n        vec2 param_9 = _7640 + vec2(2.5, 10.5);\n        vec2 param_10 = _7640 + vec2(3.5, 10.5);\n        vec2 param_11 = _7640 + vec2(4.5, 10.5);\n        vec2 param_12 = _7640 + vec2(5.5, 10.5);\n        vec2 param_13 = _7640 + vec2(6.5, 10.5);\n        vec2 param_14 = _7640 + vec2(7.5, 10.5);\n        vec2 param_15 = _7640 + vec2(8.5, 10.5);\n        acc += ((((((((((fa_gi_fetch(param_7).xyz * 0.2820948064327239990234375) + (fa_gi_fetch(param_8).xyz * _7470)) + (fa_gi_fetch(param_9).xyz * _7474)) + (fa_gi_fetch(param_10).xyz * _7478)) + (fa_gi_fetch(param_11).xyz * _7485)) + (fa_gi_fetch(param_12).xyz * _7492)) + (fa_gi_fetch(param_13).xyz * _7501)) + (fa_gi_fetch(param_14).xyz * _7508)) + (fa_gi_fetch(param_15).xyz * _7521)) * w);\n        wsum += w;\n    }\n    if (!(wsum > 9.9999997473787516355514526367188e-06))\n    {\n        return vec3(0.0);\n    }\n    cover = smoothstep(0.0, 1.0, clamp(_7421 * 2.0, 0.0, 1.0)) * smoothstep(0.0, 0.0199999995529651641845703125, wsum);\n    float _7871;\n    if (fa_mesh_fs_params[52].z > 0.5)\n    {\n        _7871 = _7374.x;\n    }\n    else\n    {\n        _7871 = 1.0;\n    }\n    return max(acc / vec3(wsum), vec3(0.0)) * (_7369.w * _7871);\n}\n\nvec3 fa_gi_light(vec3 n, inout float left)\n{\n    left = 1.0;\n    vec3 acc = vec3(0.0);\n    vec3 _7895 = normalize(fa_mesh_fs_params[0].xyz - fa_world_pos);\n    int _7900 = int(fa_mesh_fs_params[52].x + 0.5);\n    int _7905 = int(fa_mesh_fs_params[52].y + 0.5);\n    float param_3;\n    for (int k = 0; (k < _7905) && (k < 8); k++)\n    {\n        int param = _7900 + (4 * k);\n        vec3 param_1 = n;\n        vec3 param_2 = _7895;\n        vec3 _7930 = fa_gi_grid(param, param_1, param_2, param_3);\n        float _7935 = param_3 * left;\n        acc += (_7930 * _7935);\n        left -= _7935;\n        if (left < 0.001000000047497451305389404296875)\n        {\n            left = 0.0;\n            break;\n        }\n    }\n    return acc;\n}\n\nvec3 fa_realtime_or_ambient(vec3 n)\n{\n    vec3 gi = vec3(0.0);\n    float left = 1.0;\n    if (fa_mesh_fs_params[52].y > 0.5)\n    {\n        vec3 param = n;\n        float param_1;\n        vec3 _7964 = fa_gi_light(param, param_1);\n        left = param_1;\n        gi = _7964;\n    }\n    if (left <= 0.0)\n    {\n        return gi;\n    }\n    vec3 param_2 = n;\n    return gi + (fa_ambient_light(param_2) * left);\n}\n\nvec3 fa_indirect_diffuse(vec3 n)\n{\n    if (fa_lm.z > 0.5)\n    {\n        return textureLod(fa_lightmap_fa_env_smp, fa_lm.xy, 0.0).xyz;\n    }\n    if (fa_mesh_fs_params[32].w > 0.0)\n    {\n        vec3 c[9];\n        for (int k = 0; k < 9; k++)\n        {\n            c[k] = fa_mesh_fs_params[k * 1 + 32].xyz;\n        }\n        vec3 param = n;\n        vec3 param_1[9] = c;\n        vec3 param_2 = n;\n        return mix(fa_ambient_light(param), fa_sh_eval(param_1, param_2), vec3(clamp(fa_mesh_fs_params[32].w, 0.0, 1.0)));\n    }\n    vec3 param_3 = n;\n    return fa_realtime_or_ambient(param_3);\n}\n\nint fa_cluster_index(int slot, int n)\n{\n    int param = (int(fa_mesh_fs_params[19].x) + int(fa_mesh_fs_params[19].w)) + ((slot + n) >> 2);\n    vec4 t = fa_light_texel(param);\n    return int(t[(slot + n) & 3]);\n}\n\nint fa_cl_light(int n)\n{\n    if (n < fa_cl_ndir)\n    {\n        return n;\n    }\n    int param = fa_cl_slot;\n    int param_1 = n - fa_cl_ndir;\n    return fa_cluster_index(param, param_1);\n}\n\nint fa_light_base(int li)\n{\n    return li * ((fa_mesh_fs_params[1].w > 4.5) ? 8 : 4);\n}\n\nbool fa_light_baked(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 3;\n    return fa_light_texel(param_1).w > 0.5;\n}\n\nfloat fa_baked_keep(int li)\n{\n    float _5840;\n    if (fa_lm.z > 0.5)\n    {\n        _5840 = 0.0;\n    }\n    else\n    {\n        _5840 = 1.0 - clamp(fa_mesh_fs_params[32].w, 0.0, 1.0);\n    }\n    bool _5851 = _5840 < 1.0;\n    bool _5857;\n    if (_5851)\n    {\n        int param = li;\n        _5857 = fa_light_baked(param);\n    }\n    else\n    {\n        _5857 = _5851;\n    }\n    return _5857 ? _5840 : 1.0;\n}\n\nfloat fa_light_type(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 1;\n    return fa_light_texel(param_1).w;\n}\n\nvec4 fa_atlas_fetch(vec2 texel)\n{\n    return textureLod(fa_light_atlas_fa_env_smp, texel / vec2(textureSize(fa_light_atlas_fa_env_smp, 0)), 0.0);\n}\n\nvec3 fa_cookie_sample(vec2 tile_origin, vec2 uv)\n{\n    vec2 param = (tile_origin + vec2(1.0)) + (clamp(uv, vec2(0.0), vec2(1.0)) * 254.0);\n    return fa_atlas_fetch(param).xyz;\n}\n\nvec3 fa_area_point(vec3 c, vec3 axis, vec3 ru, vec3 uu, float hx, float hy, float shape, vec3 p, vec3 r)\n{\n    bool _883 = dot(r, r) > 0.5;\n    if (shape > 1.5)\n    {\n        vec3 _896 = (c - (ru * hx)) - p;\n        vec3 _902 = ru * (2.0 * hx);\n        float _908 = max(dot(_902, _902), 9.9999999392252902907785028219223e-09);\n        float _912 = dot(_896, _902);\n        float t = clamp((-_912) / _908, 0.0, 1.0);\n        if (_883)\n        {\n            float _927 = dot(r, _902);\n            float _933 = _908 - (_927 * _927);\n            if (abs(_933) > (9.9999997473787516355514526367188e-06 * _908))\n            {\n                t = clamp(((dot(r, _896) * _927) - _912) / _933, 0.0, 1.0);\n            }\n        }\n        return (p + _896) + (_902 * t);\n    }\n    vec3 q = p;\n    float _965 = dot(r, axis);\n    bool _973;\n    if (_883)\n    {\n        _973 = abs(_965) > 9.9999997473787516355514526367188e-05;\n    }\n    else\n    {\n        _973 = _883;\n    }\n    if (_973)\n    {\n        float _983 = dot(c - p, axis) / _965;\n        if (_983 > 0.0)\n        {\n            q = p + (r * _983);\n        }\n    }\n    vec3 _996 = q - c;\n    vec2 xy = vec2(dot(_996, ru), dot(_996, uu));\n    if (shape > 0.5)\n    {\n        float _1011 = length(xy);\n        if (_1011 > hx)\n        {\n            xy *= (hx / _1011);\n        }\n    }\n    else\n    {\n        xy = clamp(xy, vec2(-hx, -hy), vec2(hx, hy));\n    }\n    return (c + (ru * xy.x)) + (uu * xy.y);\n}\n\nint fa_cube_face(vec3 d)\n{\n    vec3 _650 = abs(d);\n    float _652 = _650.x;\n    float _654 = _650.y;\n    bool _655 = _652 >= _654;\n    bool _663;\n    if (_655)\n    {\n        _663 = _652 >= _650.z;\n    }\n    else\n    {\n        _663 = _655;\n    }\n    int _664;\n    if (_663)\n    {\n        _664 = (d.x > 0.0) ? 0 : 1;\n    }\n    else\n    {\n        int _678;\n        if (_654 >= _650.z)\n        {\n            _678 = (d.y > 0.0) ? 2 : 3;\n        }\n        else\n        {\n            _678 = (d.z > 0.0) ? 4 : 5;\n        }\n        _664 = _678;\n    }\n    return _664;\n}\n\nvoid fa_cube_face_basis(int f, out vec3 fwd, out vec3 up)\n{\n    if (f == 0)\n    {\n        fwd = vec3(1.0, 0.0, 0.0);\n        up = vec3(0.0, 1.0, 0.0);\n    }\n    else\n    {\n        if (f == 1)\n        {\n            fwd = vec3(-1.0, 0.0, 0.0);\n            up = vec3(0.0, 1.0, 0.0);\n        }\n        else\n        {\n            if (f == 2)\n            {\n                fwd = vec3(0.0, 1.0, 0.0);\n                up = vec3(0.0, 0.0, 1.0);\n            }\n            else\n            {\n                if (f == 3)\n                {\n                    fwd = vec3(0.0, -1.0, 0.0);\n                    up = vec3(0.0, 0.0, -1.0);\n                }\n                else\n                {\n                    if (f == 4)\n                    {\n                        fwd = vec3(0.0, 0.0, 1.0);\n                        up = vec3(0.0, 1.0, 0.0);\n                    }\n                    else\n                    {\n                        fwd = vec3(0.0, 0.0, -1.0);\n                        up = vec3(0.0, 1.0, 0.0);\n                    }\n                }\n            }\n        }\n    }\n}\n\nfloat fa_ies_sample(vec2 tile_origin, vec3 d, vec3 axis, vec3 right, vec3 up)\n{\n    float _803 = dot(d, right);\n    float _807 = dot(d, up);\n    float _818;\n    if (((_803 * _803) + (_807 * _807)) > 1.0000000133514319600180897396058e-10)\n    {\n        _818 = atan(_807, _803) * 0.15915493667125701904296875;\n    }\n    else\n    {\n        _818 = 0.0;\n    }\n    vec2 param = tile_origin + vec2(1.0 + ((_818 - floor(_818)) * 64.0), 1.0 + (acos(clamp(dot(d, axis), -1.0, 1.0)) * 10.18591594696044921875));\n    return fa_atlas_fetch(param).x;\n}\n\nLightSample fa_light_sample_n(int li, vec3 world_pos, vec3 n)\n{\n    int param = li;\n    int _1049 = fa_light_base(param);\n    bool _1053 = fa_mesh_fs_params[1].w > 4.5;\n    int param_1 = _1049;\n    vec4 _1057 = fa_light_texel(param_1);\n    int param_2 = _1049 + 1;\n    vec4 _1062 = fa_light_texel(param_2);\n    float _1065 = _1062.w;\n    float atten = 1.0;\n    float dist = 0.0;\n    fa_light_tint = vec3(1.0);\n    bool _1077 = _1053 && (_1065 > 2.5);\n    fa_light_is_area = _1077;\n    bool _1079 = _1065 < 0.5;\n    vec3 l;\n    if (_1079)\n    {\n        l = normalize(_1057.xyz);\n        if (_1053)\n        {\n            int param_3 = _1049 + 6;\n            vec4 _1093 = fa_light_texel(param_3);\n            if (_1093.z > 0.5)\n            {\n                int param_4 = _1049 + 4;\n                vec4 _1103 = fa_light_texel(param_4);\n                int param_5 = _1049 + 5;\n                vec4 _1108 = fa_light_texel(param_5);\n                vec2 param_6 = _1093.xy;\n                vec2 param_7 = fract(vec2(dot(world_pos, _1103.xyz) * _1103.w, (-dot(world_pos, _1108.xyz)) * _1108.w) + vec2(0.5));\n                fa_light_tint = fa_cookie_sample(param_6, param_7);\n            }\n        }\n    }\n    else\n    {\n        vec3 _1138 = _1057.xyz;\n        vec3 _1140 = _1138 - world_pos;\n        vec3 to_light = _1140;\n        float _1143 = length(_1140);\n        float reach = _1143;\n        bool front = true;\n        if (_1077)\n        {\n            int param_8 = _1049 + 7;\n            reach = max(_1143 - fa_light_texel(param_8).w, 0.0);\n            int param_9 = _1049 + 4;\n            vec4 _1167 = fa_light_texel(param_9);\n            int param_10 = _1049 + 5;\n            vec4 _1172 = fa_light_texel(param_10);\n            int param_11 = _1049 + 6;\n            vec4 _1177 = fa_light_texel(param_11);\n            float _1178 = _1177.w;\n            int param_12 = _1049 + 2;\n            vec3 _1185 = normalize(fa_light_texel(param_12).xyz);\n            bool _1187 = _1178 > 1.5;\n            bool _1195;\n            if (!_1187)\n            {\n                _1195 = dot(_1185, to_light) < 0.0;\n            }\n            else\n            {\n                _1195 = _1187;\n            }\n            front = _1195;\n            vec3 r = vec3(0.0);\n            vec3 _1204 = fa_mesh_fs_params[0].xyz - world_pos;\n            bool _1208 = dot(n, n) > 0.5;\n            bool _1216;\n            if (_1208)\n            {\n                _1216 = dot(_1204, _1204) > 9.9999999600419720025001879548654e-13;\n            }\n            else\n            {\n                _1216 = _1208;\n            }\n            if (_1216)\n            {\n                r = reflect(-normalize(_1204), normalize(n));\n            }\n            vec3 param_13 = _1138;\n            vec3 param_14 = _1185;\n            vec3 param_15 = _1167.xyz;\n            vec3 param_16 = _1172.xyz;\n            float param_17 = _1167.w;\n            float param_18 = _1172.w;\n            float param_19 = _1178;\n            vec3 param_20 = world_pos;\n            vec3 param_21 = r;\n            to_light = fa_area_point(param_13, param_14, param_15, param_16, param_17, param_18, param_19, param_20, param_21) - world_pos;\n        }\n        float _1252 = length(to_light);\n        dist = _1252;\n        l = to_light / vec3(max(_1252, 9.9999997473787516355514526367188e-05));\n        float _1266 = reach / max(_1057.w, 0.001000000047497451305389404296875);\n        float _1272 = clamp(1.0 - (_1266 * _1266), 0.0, 1.0);\n        float _1274;\n        if (front)\n        {\n            _1274 = _1272 * _1272;\n        }\n        else\n        {\n            _1274 = 0.0;\n        }\n        atten = _1274;\n        bool _1285 = _1065 < 2.5;\n        if ((_1065 > 1.5) && _1285)\n        {\n            int param_22 = _1049 + 2;\n            vec4 _1293 = fa_light_texel(param_22);\n            float _1303 = _1293.w;\n            int param_23 = _1049 + 3;\n            vec4 _1308 = fa_light_texel(param_23);\n            float _1309 = _1308.x;\n            float cos_inner = _1309;\n            if (_1309 > 1.5)\n            {\n                cos_inner = mix(_1303, 1.0, 0.25);\n            }\n            atten *= smoothstep(_1303, cos_inner, dot(-l, normalize(_1293.xyz)));\n        }\n        if (_1053 && (_1065 < 1.5))\n        {\n            int param_24 = _1049 + 6;\n            vec4 _1333 = fa_light_texel(param_24);\n            if (_1333.z > 0.5)\n            {\n                vec3 _1341 = -to_light;\n                int param_25 = _1049 + 4;\n                int param_26 = _1049 + 5;\n                vec3 _1355 = fa_light_texel(param_25).xyz;\n                vec3 _1359 = fa_light_texel(param_26).xyz;\n                vec3 _1368 = vec3(dot(_1341, _1355), dot(_1341, _1359), dot(_1341, cross(_1355, _1359)));\n                vec3 param_27 = _1368;\n                int _1372 = fa_cube_face(param_27);\n                int param_28 = _1372;\n                vec3 param_29;\n                vec3 param_30;\n                fa_cube_face_basis(param_28, param_29, param_30);\n                vec2 _1399 = vec2(dot(_1368, cross(param_29, param_30)), dot(_1368, param_30)) / vec2(max(dot(_1368, param_29), 9.9999997473787516355514526367188e-05));\n                int _1403 = _1372 / 3;\n                vec2 param_31 = _1333.xy + (vec2(float(_1372 - (_1403 * 3)), float(_1403)) * 256.0);\n                vec2 param_32 = vec2(0.5 + (0.5 * _1399.x), 0.5 - (0.5 * _1399.y));\n                fa_light_tint = fa_cookie_sample(param_31, param_32);\n            }\n            int param_33 = _1049 + 7;\n            vec4 _1433 = fa_light_texel(param_33);\n            if (_1433.z > 0.5)\n            {\n                int param_34 = _1049 + 2;\n                int param_35 = _1049 + 4;\n                int param_36 = _1049 + 5;\n                vec2 param_37 = _1433.xy;\n                vec3 param_38 = -l;\n                vec3 param_39 = normalize(fa_light_texel(param_34).xyz);\n                vec3 param_40 = fa_light_texel(param_35).xyz;\n                vec3 param_41 = fa_light_texel(param_36).xyz;\n                atten *= fa_ies_sample(param_37, param_38, param_39, param_40, param_41);\n            }\n        }\n        else\n        {\n            if (_1053 && _1285)\n            {\n                int param_42 = _1049 + 6;\n                vec4 _1480 = fa_light_texel(param_42);\n                int param_43 = _1049 + 7;\n                vec4 _1485 = fa_light_texel(param_43);\n                bool _1488 = _1480.z > 0.5;\n                bool _1495;\n                if (!_1488)\n                {\n                    _1495 = _1485.z > 0.5;\n                }\n                else\n                {\n                    _1495 = _1488;\n                }\n                if (_1495)\n                {\n                    int param_44 = _1049 + 2;\n                    vec4 _1502 = fa_light_texel(param_44);\n                    vec3 _1506 = normalize(_1502.xyz);\n                    int param_45 = _1049 + 4;\n                    vec4 _1511 = fa_light_texel(param_45);\n                    int param_46 = _1049 + 5;\n                    vec4 _1516 = fa_light_texel(param_46);\n                    if (_1488)\n                    {\n                        vec3 _1524 = -to_light;\n                        float _1531 = _1502.w;\n                        float _1547 = 0.5 / max(dot(_1524, _1506) * (sqrt(max(1.0 - (_1531 * _1531), 0.0)) / max(_1531, 0.001000000047497451305389404296875)), 9.9999997473787516355514526367188e-05);\n                        vec2 param_47 = _1480.xy;\n                        vec2 param_48 = vec2(0.5 + (dot(_1524, _1511.xyz) * _1547), 0.5 - (dot(_1524, _1516.xyz) * _1547));\n                        fa_light_tint = fa_cookie_sample(param_47, param_48);\n                    }\n                    if (_1485.z > 0.5)\n                    {\n                        vec2 param_49 = _1485.xy;\n                        vec3 param_50 = -l;\n                        vec3 param_51 = _1506;\n                        vec3 param_52 = _1511.xyz;\n                        vec3 param_53 = _1516.xyz;\n                        atten *= fa_ies_sample(param_49, param_50, param_51, param_52, param_53);\n                    }\n                }\n            }\n        }\n    }\n    vec3 _9047 = _1062.xyz * atten;\n    if (_1053)\n    {\n        _9047 *= fa_light_tint;\n    }\n    int _1616;\n    if (_1079)\n    {\n        _1616 = 0;\n    }\n    else\n    {\n        _1616 = ((_1065 > 1.5) && (_1065 < 2.5)) ? 2 : 1;\n    }\n    return LightSample(l, _9047, atten, 1.0, dist, _1616);\n}\n\nfloat fa_shadow_split_at(int i)\n{\n    float _2342;\n    if (i == 0)\n    {\n        _2342 = fa_shadows[24].x;\n    }\n    else\n    {\n        float _2358;\n        if (i == 1)\n        {\n            _2358 = fa_shadows[24].y;\n        }\n        else\n        {\n            float _2366;\n            if (i == 2)\n            {\n                _2366 = fa_shadows[24].z;\n            }\n            else\n            {\n                _2366 = fa_shadows[24].w;\n            }\n            _2358 = _2366;\n        }\n        _2342 = _2358;\n    }\n    return _2342;\n}\n\nfloat fa_shadow_depth(inout vec2 uv, vec4 rect)\n{\n    uv = clamp(uv, rect.xy, rect.zw);\n    return textureLod(fa_shadow_tex_fa_shadow_smp, uv, 0.0).x;\n}\n\nfloat fa_shadow_fetch(vec2 uv, vec4 rect, vec3 conv)\n{\n    vec2 param = uv;\n    vec4 param_1 = rect;\n    float _2399 = fa_shadow_depth(param, param_1);\n    float _2403;\n    if (conv.x < 0.5)\n    {\n        _2403 = _2399;\n    }\n    else\n    {\n        _2403 = (conv.y * conv.z) / (conv.z - (_2399 * (conv.z - conv.y)));\n    }\n    return _2403;\n}\n\nfloat fa_shadow_noise()\n{\n    return fract(52.98291778564453125 * fract(dot(gl_FragCoord.xy, vec2(0.067110560834407806396484375, 0.005837149918079376220703125))));\n}\n\nvec2 fa_shadow_vogel_turn(vec2 d)\n{\n    return vec2((d.x * (-0.737368881702423095703125)) - (d.y * 0.675490319728851318359375), (d.y * (-0.737368881702423095703125)) + (d.x * 0.675490319728851318359375));\n}\n\nfloat fa_shadow_filter(vec2 uv, vec4 rect, float zr, float texel_m, float unit, float reach, float plane, vec3 conv, int mode, float k)\n{\n    if (mode == 1)\n    {\n        vec2 param = uv;\n        vec4 param_1 = rect;\n        vec3 param_2 = conv;\n        return float(zr <= fa_shadow_fetch(param, param_1, param_2));\n    }\n    float _2449 = fa_shadow_noise() * 6.283185482025146484375;\n    vec2 _2455 = vec2(cos(_2449), sin(_2449));\n    vec2 dir = _2455;\n    float radius = 1.5;\n    if (mode == 2)\n    {\n        float _2464;\n        if (k < 0.0)\n        {\n            _2464 = (-k) / max(zr, 0.100000001490116119384765625);\n        }\n        else\n        {\n            _2464 = k;\n        }\n        float _2483 = clamp((_2464 * reach) / texel_m, 3.0, 12.0);\n        float sum = 0.0;\n        float cnt = 0.0;\n        for (int i = 0; i < 16; i++)\n        {\n            float _2502 = sqrt((float(i) + 0.5) * 0.0625) * _2483;\n            vec2 param_3 = uv + (dir * (fa_shadows[26].zw * _2502));\n            vec4 param_4 = rect;\n            vec3 param_5 = conv;\n            float _2516 = fa_shadow_fetch(param_3, param_4, param_5);\n            if (_2516 < (zr - (_2502 * plane)))\n            {\n                sum += _2516;\n                cnt += 1.0;\n            }\n            vec2 param_6 = dir;\n            dir = fa_shadow_vogel_turn(param_6);\n        }\n        if (cnt < 0.5)\n        {\n            return 1.0;\n        }\n        float _2544 = sum / cnt;\n        float _2554;\n        if (k < 0.0)\n        {\n            _2554 = (-k) / max(_2544, 0.0500000007450580596923828125);\n        }\n        else\n        {\n            _2554 = k;\n        }\n        radius = clamp(((max(zr - _2544, 0.0) * unit) * _2554) / texel_m, 1.5, 16.0);\n        dir = _2455;\n    }\n    float lit = 0.0;\n    int _2580 = (mode == 2) ? 24 : 16;\n    for (int i_1 = 0; i_1 < _2580; i_1++)\n    {\n        float _2599 = sqrt((float(i_1) + 0.5) / float(_2580)) * radius;\n        vec2 param_7 = uv + (dir * (fa_shadows[26].zw * _2599));\n        vec4 param_8 = rect;\n        vec3 param_9 = conv;\n        lit += float((zr - (_2599 * plane)) <= fa_shadow_fetch(param_7, param_8, param_9));\n        vec2 param_10 = dir;\n        dir = fa_shadow_vogel_turn(param_10);\n    }\n    return lit / float(_2580);\n}\n\nfloat fa_shadow_cascade(int ci, vec3 world, vec3 n, vec3 l)\n{\n    float _2645 = max(fa_shadows[ci * 1 + 20].y, 0.001000000047497451305389404296875);\n    float _2650 = clamp(dot(n, l), 0.0, 1.0);\n    float _2656 = sqrt(1.0 - (_2650 * _2650));\n    float _2664 = min(_2656 / max(_2650, 0.20000000298023223876953125), 4.0);\n    float _2669;\n    if (fa_shadows[26].y > 0.0)\n    {\n        _2669 = fa_shadows[26].y;\n    }\n    else\n    {\n        _2669 = 1.5 * fa_shadows[ci * 1 + 20].x;\n    }\n    vec4 _2694 = mat4(fa_shadows[ci * 4 + 0], fa_shadows[ci * 4 + 1], fa_shadows[ci * 4 + 2], fa_shadows[ci * 4 + 3]) * vec4(world + (n * (_2669 * _2656)), 1.0);\n    float _2701 = _2694.x;\n    bool _2704 = _2701 < fa_shadows[ci * 1 + 16].x;\n    bool _2713;\n    if (!_2704)\n    {\n        _2713 = _2701 > fa_shadows[ci * 1 + 16].z;\n    }\n    else\n    {\n        _2713 = _2704;\n    }\n    bool _2722;\n    if (!_2713)\n    {\n        _2722 = _2694.y < fa_shadows[ci * 1 + 16].y;\n    }\n    else\n    {\n        _2722 = _2713;\n    }\n    bool _2731;\n    if (!_2722)\n    {\n        _2731 = _2694.y > fa_shadows[ci * 1 + 16].w;\n    }\n    else\n    {\n        _2731 = _2722;\n    }\n    bool _2738;\n    if (!_2731)\n    {\n        _2738 = _2694.z > 1.0;\n    }\n    else\n    {\n        _2738 = _2731;\n    }\n    if (_2738)\n    {\n        return -1.0;\n    }\n    float _2746;\n    if (fa_shadows[26].x > 0.0)\n    {\n        _2746 = fa_shadows[26].x;\n    }\n    else\n    {\n        _2746 = 1.5 * fa_shadows[ci * 1 + 20].x;\n    }\n    vec2 param = _2694.xy;\n    vec4 param_1 = fa_shadows[ci * 1 + 16];\n    float param_2 = _2694.z - ((_2746 * (1.0 + (0.5 * _2664))) / _2645);\n    float param_3 = fa_shadows[ci * 1 + 20].x;\n    float param_4 = _2645;\n    float param_5 = _2645 * 0.25;\n    float param_6 = ((fa_shadows[ci * 1 + 20].x * min(_2664, 3.0)) * 0.5) / _2645;\n    vec3 param_7 = vec3(0.0);\n    int param_8 = int(fa_shadows[25].z + 0.5);\n    float param_9 = fa_shadows[25].w;\n    return fa_shadow_filter(param, param_1, param_2, param_3, param_4, param_5, param_6, param_7, param_8, param_9);\n}\n\nfloat fa_shadow_sun(vec3 world, vec3 n, vec3 l)\n{\n    if (fa_mesh_fs_params[5].z < 0.5)\n    {\n        return 1.0;\n    }\n    int _3124 = int(fa_shadows[25].x + 0.5);\n    if (_3124 < 1)\n    {\n        return 1.0;\n    }\n    float _3139 = dot(world - fa_shadows[27].xyz, fa_shadows[28].xyz);\n    int param = _3124 - 1;\n    if (_3139 > fa_shadow_split_at(param))\n    {\n        return 1.0;\n    }\n    int ci = 0;\n    bool _3151 = _3124 > 1;\n    bool _3158;\n    if (_3151)\n    {\n        _3158 = _3139 > fa_shadows[24].x;\n    }\n    else\n    {\n        _3158 = _3151;\n    }\n    if (_3158)\n    {\n        ci = 1;\n    }\n    bool _3162 = _3124 > 2;\n    bool _3169;\n    if (_3162)\n    {\n        _3169 = _3139 > fa_shadows[24].y;\n    }\n    else\n    {\n        _3169 = _3162;\n    }\n    if (_3169)\n    {\n        ci = 2;\n    }\n    bool _3173 = _3124 > 3;\n    bool _3180;\n    if (_3173)\n    {\n        _3180 = _3139 > fa_shadows[24].z;\n    }\n    else\n    {\n        _3180 = _3173;\n    }\n    if (_3180)\n    {\n        ci = 3;\n    }\n    float s = -1.0;\n    float s2 = -1.0;\n    float t = 0.0;\n    int _3191 = min(_3124, 4);\n    float _3232;\n    for (int c = ci; c < _3191; c++)\n    {\n        int param_1 = c;\n        vec3 param_2 = world;\n        vec3 param_3 = n;\n        vec3 param_4 = l;\n        float _3211 = fa_shadow_cascade(param_1, param_2, param_3, param_4);\n        if (s >= 0.0)\n        {\n            s2 = _3211;\n            break;\n        }\n        if (_3211 < 0.0)\n        {\n            continue;\n        }\n        s = _3211;\n        ci = c;\n        if (fa_shadows[25].y > 0.0)\n        {\n            if (ci > 0)\n            {\n                int param_5 = ci - 1;\n                _3232 = fa_shadow_split_at(param_5);\n            }\n            else\n            {\n                _3232 = fa_shadows[28].w;\n            }\n            int param_6 = ci;\n            float _3251 = fa_shadows[25].y * max(fa_shadow_split_at(param_6) - _3232, 9.9999997473787516355514526367188e-05);\n            int param_7 = ci;\n            t = clamp((_3139 - (fa_shadow_split_at(param_7) - _3251)) / _3251, 0.0, 1.0);\n        }\n        if (t <= 0.0)\n        {\n            break;\n        }\n    }\n    if (s < 0.0)\n    {\n        return 1.0;\n    }\n    if (t > 0.0)\n    {\n        float _3283;\n        if ((ci + 1) < _3124)\n        {\n            _3283 = (s2 < 0.0) ? s : s2;\n        }\n        else\n        {\n            _3283 = 1.0;\n        }\n        s = mix(s, _3283, t);\n    }\n    return s;\n}\n\nfloat fa_shadow_factor(vec3 n, vec3 l)\n{\n    vec3 param = fa_world_pos;\n    vec3 param_1 = n;\n    vec3 param_2 = l;\n    return fa_shadow_sun(param, param_1, param_2);\n}\n\nfloat fa_shadow_local(int li, vec3 lpos, vec3 world, vec3 n, vec3 l)\n{\n    bool _2804 = fa_mesh_fs_params[5].z < 0.5;\n    bool _2811;\n    if (!_2804)\n    {\n        _2811 = fa_shadows[29].x < 0.5;\n    }\n    else\n    {\n        _2811 = _2804;\n    }\n    if (_2811)\n    {\n        return 1.0;\n    }\n    int param = (int(fa_shadows[29].x + 0.5) - 1) + li;\n    vec4 _2824 = fa_light_texel(param);\n    float _2825 = _2824.x;\n    if (_2825 < 0.0)\n    {\n        return 1.0;\n    }\n    int _2834 = int(_2825 + 0.5);\n    int param_1 = _2834;\n    vec4 _2838 = fa_light_texel(param_1);\n    int param_2 = _2834 + 1;\n    vec4 _2843 = fa_light_texel(param_2);\n    float fade = 1.0;\n    float _2846 = _2838.y;\n    if (_2846 > 0.0)\n    {\n        float _2863 = 1.0 - smoothstep(0.75 * _2846, _2846, length(world - fa_shadows[27].xyz));\n        fade = _2863;\n        if (_2863 <= 0.0)\n        {\n            return 1.0;\n        }\n    }\n    int face = 0;\n    if (_2838.x > 1.5)\n    {\n        vec3 param_3 = world - lpos;\n        face = fa_cube_face(param_3);\n    }\n    int _2887 = (_2834 + 2) + (face * 6);\n    int param_4 = _2887;\n    int param_5 = _2887 + 1;\n    int param_6 = _2887 + 3;\n    vec4 _2901 = fa_light_texel(param_6);\n    int param_7 = _2887 + 4;\n    vec4 _2906 = fa_light_texel(param_7);\n    int param_8 = _2887 + 5;\n    vec4 _2911 = fa_light_texel(param_8);\n    float _2923 = _2911.x * max(dot(_2901, vec4(world, 1.0)), 0.001000000047497451305389404296875);\n    float _2928 = clamp(dot(n, l), 0.0, 1.0);\n    float _2951 = clamp(dot(n, _2901.xyz), -1.0, 1.0);\n    float _2970 = min(sqrt(1.0 - (_2951 * _2951)) / max(abs(dot(n, world - lpos)) / max(dot(_2901, vec4(world, 1.0)), 0.001000000047497451305389404296875), 0.20000000298023223876953125), 4.0);\n    float _2973 = _2843.y;\n    float _2975;\n    if (_2973 > 0.0)\n    {\n        _2975 = _2973;\n    }\n    else\n    {\n        _2975 = 1.5 * _2923;\n    }\n    vec4 _2995 = vec4(world + (n * (_2975 * sqrt(1.0 - (_2928 * _2928)))), 1.0);\n    float _2999 = dot(_2901, _2995);\n    float _3002 = _2911.y;\n    if (_2999 < _3002)\n    {\n        return 1.0;\n    }\n    vec2 _3017 = vec2(dot(fa_light_texel(param_4), _2995), dot(fa_light_texel(param_5), _2995)) / vec2(_2999);\n    float _3019 = _3017.x;\n    bool _3022 = _3019 < _2906.x;\n    bool _3031;\n    if (!_3022)\n    {\n        _3031 = _3019 > _2906.z;\n    }\n    else\n    {\n        _3031 = _3022;\n    }\n    bool _3040;\n    if (!_3031)\n    {\n        _3040 = _3017.y < _2906.y;\n    }\n    else\n    {\n        _3040 = _3031;\n    }\n    bool _3049;\n    if (!_3040)\n    {\n        _3049 = _3017.y > _2906.w;\n    }\n    else\n    {\n        _3049 = _3040;\n    }\n    if (_3049)\n    {\n        return 1.0;\n    }\n    float _3055 = _2843.x;\n    float _3057;\n    if (_3055 > 0.0)\n    {\n        _3057 = _3055;\n    }\n    else\n    {\n        _3057 = 1.5 * _2923;\n    }\n    vec2 param_9 = _3017;\n    vec4 param_10 = _2906;\n    float param_11 = _2999 - (_3057 * (1.0 + (0.5 * _2970)));\n    float param_12 = _2923;\n    float param_13 = 1.0;\n    float param_14 = _2911.z * 0.25;\n    float param_15 = (_2923 * min(_2970, 3.0)) * 0.5;\n    vec3 param_16 = vec3(1.0, _3002, _2911.z);\n    int param_17 = int(_2838.z + 0.5);\n    float param_18 = _2838.w;\n    return mix(1.0, fa_shadow_filter(param_9, param_10, param_11, param_12, param_13, param_14, param_15, param_16, param_17, param_18), fade);\n}\n\nfloat fa_contact_shadow(int li, vec3 world, vec3 gn, vec3 l, float dist)\n{\n    bool _5213 = fa_mesh_fs_params[24].x < 0.5;\n    bool _5220;\n    if (!_5213)\n    {\n        _5220 = fa_shadows[29].x < 0.5;\n    }\n    else\n    {\n        _5220 = _5213;\n    }\n    if (_5220)\n    {\n        return 1.0;\n    }\n    int param = (int(fa_shadows[29].x + 0.5) - 1) + li;\n    vec4 _5233 = fa_light_texel(param);\n    float _5234 = _5233.y;\n    float len = _5234;\n    if (_5234 <= 0.0)\n    {\n        return 1.0;\n    }\n    float _5246 = length(world - fa_mesh_fs_params[0].xyz);\n    float _5256 = 1.0 - smoothstep(0.5 * fa_mesh_fs_params[25].x, fa_mesh_fs_params[25].x, _5246);\n    if (_5256 <= 0.0)\n    {\n        return 1.0;\n    }\n    float _5262 = len;\n    float _5265 = min(_5262, 0.89999997615814208984375 * dist);\n    len = _5265;\n    float _5270 = 0.004999999888241291046142578125 + (0.0030000000260770320892333984375 * _5246);\n    float _5275 = _5270 + (0.5 * _5265);\n    vec3 _5281 = world + (gn * _5270);\n    float _5283 = fa_shadow_noise();\n    float occ = 0.0;\n    float _5347;\n    for (int k = 0; k < 12; k++)\n    {\n        float _5298 = (float(k) + _5283) * 0.083333335816860198974609375;\n        vec3 _5306 = _5281 + (l * (_5298 * len));\n        vec4 _5312 = vec4(_5306, 1.0);\n        float _5318 = dot(fa_mesh_fs_params[28], _5312);\n        if (_5318 < 9.9999997473787516355514526367188e-05)\n        {\n            break;\n        }\n        vec2 _5338 = vec2(dot(fa_mesh_fs_params[26], _5312), dot(fa_mesh_fs_params[27], _5312)) / vec2(_5318);\n        float _5342 = _5338.x * 0.5;\n        float _5343 = _5342 + 0.5;\n        if (fa_mesh_fs_params[24].y > 0.5)\n        {\n            _5347 = (_5338.y * 0.5) + 0.5;\n        }\n        else\n        {\n            _5347 = 0.5 - (_5338.y * 0.5);\n        }\n        bool _5363 = _5343 < 0.0;\n        bool _5370;\n        if (!_5363)\n        {\n            _5370 = _5343 >= 1.0;\n        }\n        else\n        {\n            _5370 = _5363;\n        }\n        bool _5377;\n        if (!_5370)\n        {\n            _5377 = _5347 < 0.0;\n        }\n        else\n        {\n            _5377 = _5370;\n        }\n        bool _5384;\n        if (!_5377)\n        {\n            _5384 = _5347 >= 1.0;\n        }\n        else\n        {\n            _5384 = _5377;\n        }\n        if (_5384)\n        {\n            break;\n        }\n        vec4 _5411 = texelFetch(fa_screen_tex_fa_shadow_smp, clamp(ivec2(vec2(_5343, _5347) * fa_mesh_fs_params[24].zw), ivec2(0), ivec2(fa_mesh_fs_params[24].zw) - ivec2(1)), 0);\n        if (_5411.w < 0.5)\n        {\n            continue;\n        }\n        float _5430 = (dot(fa_mesh_fs_params[29].xyz, _5306) + fa_mesh_fs_params[29].w) - _5411.x;\n        if ((_5430 > _5270) && (_5430 < _5275))\n        {\n            occ = max(occ, (1.0 - (_5298 * _5298)) * smoothstep(0.0, 0.0500000007450580596923828125, min(min(_5343, 0.5 - _5342), min(_5347, 1.0 - _5347))));\n        }\n    }\n    return 1.0 - (occ * _5256);\n}\n\nLightSample fa_light_shadowed(int li, vec3 world_pos, vec3 gn)\n{\n    int param = li;\n    float _5896 = fa_baked_keep(param);\n    if (_5896 <= 0.0)\n    {\n        int param_1 = li;\n        return LightSample(vec3(0.0, 1.0, 0.0), vec3(0.0), 0.0, 1.0, 0.0, int(fa_light_type(param_1) + 0.5));\n    }\n    int param_2 = li;\n    vec3 param_3 = world_pos;\n    vec3 param_4 = gn;\n    LightSample _5922 = fa_light_sample_n(param_2, param_3, param_4);\n    vec3 _9116 = _5922.color;\n    float _9117 = _5922.attenuation;\n    float _9118 = _5922.shadow;\n    bool _5925 = _5922.type == 0;\n    if (_5925 && (li == 0))\n    {\n        vec3 param_5 = gn;\n        vec3 param_6 = _5922.direction;\n        float _5936 = fa_shadow_factor(param_5, param_6);\n        _9118 = _5936;\n        _9116 *= _5936;\n    }\n    else\n    {\n        bool _5947 = _5922.type != 0;\n        bool _5953;\n        if (_5947)\n        {\n            _5953 = _9117 > 0.0;\n        }\n        else\n        {\n            _5953 = _5947;\n        }\n        if (_5953)\n        {\n            int param_7 = li;\n            int param_8 = fa_light_base(param_7);\n            int param_9 = li;\n            vec3 param_10 = fa_light_texel(param_8).xyz;\n            vec3 param_11 = world_pos;\n            vec3 param_12 = gn;\n            vec3 param_13 = _5922.direction;\n            float _5972 = fa_shadow_local(param_9, param_10, param_11, param_12, param_13);\n            _9118 = _5972;\n            _9116 *= _5972;\n        }\n    }\n    bool _5982 = fa_mesh_fs_params[24].x > 0.5;\n    bool _5988;\n    if (_5982)\n    {\n        _5988 = _9117 > 0.0;\n    }\n    else\n    {\n        _5988 = _5982;\n    }\n    if (_5988)\n    {\n        float _5995;\n        if (_5925)\n        {\n            _5995 = 1000000000.0;\n        }\n        else\n        {\n            _5995 = _5922._distance;\n        }\n        int param_14 = li;\n        vec3 param_15 = world_pos;\n        vec3 param_16 = gn;\n        vec3 param_17 = _5922.direction;\n        float param_18 = _5995;\n        float _6013 = fa_contact_shadow(param_14, param_15, param_16, param_17, param_18);\n        _9118 *= _6013;\n        _9116 *= _6013;\n    }\n    float _6026 = _9117;\n    float _6027 = _6026 * _5896;\n    _9117 = _6027;\n    vec3 _6031 = _9116;\n    vec3 _6032 = _6031 * _5896;\n    _9116 = _6032;\n    return LightSample(_5922.direction, _6032, _6027, _9118, _5922._distance, _5922.type);\n}\n\nvec3 fa_ltc_tangent(vec3 n, vec3 v)\n{\n    vec3 _6066 = v - (n * dot(v, n));\n    vec3 t = _6066;\n    float _6070 = dot(_6066, _6066);\n    float l2 = _6070;\n    if (_6070 < 1.0000000133514319600180897396058e-10)\n    {\n        vec3 _6080;\n        if (abs(n.z) < 0.999000012874603271484375)\n        {\n            _6080 = cross(n, vec3(0.0, 0.0, 1.0));\n        }\n        else\n        {\n            _6080 = cross(n, vec3(1.0, 0.0, 0.0));\n        }\n        t = _6080;\n        l2 = dot(_6080, _6080);\n    }\n    return t * inversesqrt(l2);\n}\n\nvec3 fa_ltc_local(vec3 t1, vec3 n, vec3 p)\n{\n    return vec3(dot(t1, p), dot(cross(n, t1), p), dot(n, p));\n}\n\nvec2 fa_ltc_uv(float roughness, float ndv)\n{\n    return ((vec2(clamp((roughness - 0.0500000007450580596923828125) * 1.0526316165924072265625, 0.0, 1.0), sqrt(clamp(1.0 - ndv, 0.0, 1.0))) * 63.0) + vec2(0.5)) * vec2(0.015625);\n}\n\nvec3 fa_oct_vertex(int j, vec3 pc, vec3 ex, vec3 ey)\n{\n    float _6467;\n    if ((j == 0) || (j == 7))\n    {\n        _6467 = 0.92387950420379638671875;\n    }\n    else\n    {\n        float _6477;\n        if ((j == 3) || (j == 4))\n        {\n            _6477 = -0.92387950420379638671875;\n        }\n        else\n        {\n            _6477 = ((j == 1) || (j == 6)) ? 0.3826834261417388916015625 : (-0.3826834261417388916015625);\n        }\n        _6467 = _6477;\n    }\n    float _6498;\n    if ((j == 1) || (j == 2))\n    {\n        _6498 = 0.92387950420379638671875;\n    }\n    else\n    {\n        float _6507;\n        if ((j == 5) || (j == 6))\n        {\n            _6507 = -0.92387950420379638671875;\n        }\n        else\n        {\n            _6507 = ((j == 0) || (j == 3)) ? 0.3826834261417388916015625 : (-0.3826834261417388916015625);\n        }\n        _6498 = _6507;\n    }\n    return (pc + (ex * _6467)) + (ey * _6498);\n}\n\nvec3 fa_ltc_edge_vector(vec3 a, vec3 b)\n{\n    float _6115 = dot(a, a);\n    float _6119 = dot(b, b);\n    if ((_6115 < 1.0000000195414813782625560981111e-24) || (_6119 < 1.0000000195414813782625560981111e-24))\n    {\n        return vec3(0.0);\n    }\n    vec3 _6133 = a * inversesqrt(_6115);\n    vec3 _6138 = b * inversesqrt(_6119);\n    float _6142 = dot(_6133, _6138);\n    float _6145 = abs(_6142);\n    float g = (((((((((((0.0416471660137176513671875 * _6145) - 0.1924748718738555908203125) * _6145) + 0.4179156124591827392578125) * _6145) - 0.616057217121124267578125) * _6145) + 0.777722418308258056640625) * _6145) - 0.999542415142059326171875) * _6145) + 1.570791721343994140625;\n    if (_6142 < 0.0)\n    {\n        g = (3.1415927410125732421875 * inversesqrt(max(1.0 - (_6142 * _6142), 1.0000000116860974230803549289703e-07))) - g;\n    }\n    return cross(_6133, _6138) * g;\n}\n\nvoid fa_ltc_clip_edge(vec3 a, vec3 b, inout vec3 sum, inout vec3 leave, inout vec3 enter, inout vec2 seen)\n{\n    bool _6202 = a.z > 0.0;\n    bool _6206 = b.z > 0.0;\n    if (_6202 && _6206)\n    {\n        vec3 param = a;\n        vec3 param_1 = b;\n        sum += fa_ltc_edge_vector(param, param_1);\n    }\n    else\n    {\n        if (_6202 != _6206)\n        {\n            vec3 _6241 = a + ((b - a) * (a.z / (a.z - b.z)));\n            _6241.z = 0.0;\n            if (_6202)\n            {\n                vec3 param_2 = a;\n                vec3 param_3 = _6241;\n                sum += fa_ltc_edge_vector(param_2, param_3);\n                leave = _6241;\n                seen.x = 1.0;\n            }\n            else\n            {\n                vec3 param_4 = _6241;\n                vec3 param_5 = b;\n                sum += fa_ltc_edge_vector(param_4, param_5);\n                enter = _6241;\n                seen.y = 1.0;\n            }\n        }\n    }\n}\n\nfloat fa_ltc_quad(vec4 abcd, vec3 p0, vec3 p1, vec3 p2, vec3 p3)\n{\n    vec3 _6290 = vec3((abcd.x * p0.x) + (abcd.y * p0.z), p0.y, (abcd.z * p0.x) + (abcd.w * p0.z));\n    vec3 _6316 = vec3((abcd.x * p1.x) + (abcd.y * p1.z), p1.y, (abcd.z * p1.x) + (abcd.w * p1.z));\n    vec3 _6342 = vec3((abcd.x * p2.x) + (abcd.y * p2.z), p2.y, (abcd.z * p2.x) + (abcd.w * p2.z));\n    vec3 _6368 = vec3((abcd.x * p3.x) + (abcd.y * p3.z), p3.y, (abcd.z * p3.x) + (abcd.w * p3.z));\n    vec3 sum = vec3(0.0);\n    vec3 leave = vec3(0.0);\n    vec3 enter = vec3(0.0);\n    vec3 param = _6290;\n    vec3 param_1 = _6316;\n    vec3 param_2 = vec3(0.0);\n    vec3 param_3 = vec3(0.0);\n    vec3 param_4 = vec3(0.0);\n    vec2 param_5 = vec2(0.0);\n    fa_ltc_clip_edge(param, param_1, param_2, param_3, param_4, param_5);\n    sum = param_2;\n    leave = param_3;\n    enter = param_4;\n    vec3 param_6 = _6316;\n    vec3 param_7 = _6342;\n    vec3 param_8 = param_2;\n    vec3 param_9 = param_3;\n    vec3 param_10 = param_4;\n    vec2 param_11 = param_5;\n    fa_ltc_clip_edge(param_6, param_7, param_8, param_9, param_10, param_11);\n    sum = param_8;\n    leave = param_9;\n    enter = param_10;\n    vec3 param_12 = _6342;\n    vec3 param_13 = _6368;\n    vec3 param_14 = param_8;\n    vec3 param_15 = param_9;\n    vec3 param_16 = param_10;\n    vec2 param_17 = param_11;\n    fa_ltc_clip_edge(param_12, param_13, param_14, param_15, param_16, param_17);\n    sum = param_14;\n    leave = param_15;\n    enter = param_16;\n    vec3 param_18 = _6368;\n    vec3 param_19 = _6290;\n    vec3 param_20 = param_14;\n    vec3 param_21 = param_15;\n    vec3 param_22 = param_16;\n    vec2 param_23 = param_17;\n    fa_ltc_clip_edge(param_18, param_19, param_20, param_21, param_22, param_23);\n    sum = param_20;\n    leave = param_21;\n    enter = param_22;\n    if ((param_23.x * param_23.y) > 0.5)\n    {\n        vec3 param_24 = leave;\n        vec3 param_25 = enter;\n        sum += fa_ltc_edge_vector(param_24, param_25);\n    }\n    return sum.z * 0.15915493667125701904296875;\n}\n\nvec2 fa_area_forms(vec4 m, float shape, vec3 pc, vec3 ex, vec3 ey)\n{\n    int _6536 = ((shape < 0.5) || (shape > 1.5)) ? 1 : 3;\n    vec2 sum = vec2(0.0);\n    int _6554;\n    for (int k = 0; k < (2 * _6536); k++)\n    {\n        bool _6551 = k >= _6536;\n        if (_6551)\n        {\n            _6554 = k - _6536;\n        }\n        else\n        {\n            _6554 = k;\n        }\n        vec3 p0 = (pc - ex) - ey;\n        vec3 p1 = (pc + ex) - ey;\n        vec3 p2 = (pc + ex) + ey;\n        vec3 p3 = (pc - ex) + ey;\n        if (_6536 == 3)\n        {\n            int param = 0;\n            vec3 param_1 = pc;\n            vec3 param_2 = ex;\n            vec3 param_3 = ey;\n            p0 = fa_oct_vertex(param, param_1, param_2, param_3);\n            int _6600 = 2 * _6554;\n            int param_4 = _6600 + 1;\n            vec3 param_5 = pc;\n            vec3 param_6 = ex;\n            vec3 param_7 = ey;\n            p1 = fa_oct_vertex(param_4, param_5, param_6, param_7);\n            int param_8 = _6600 + 2;\n            vec3 param_9 = pc;\n            vec3 param_10 = ex;\n            vec3 param_11 = ey;\n            p2 = fa_oct_vertex(param_8, param_9, param_10, param_11);\n            int param_12 = _6600 + 3;\n            vec3 param_13 = pc;\n            vec3 param_14 = ex;\n            vec3 param_15 = ey;\n            p3 = fa_oct_vertex(param_12, param_13, param_14, param_15);\n        }\n        bvec4 _6637 = bvec4(_6551);\n        vec4 param_16 = vec4(_6637.x ? m.x : vec4(1.0, 0.0, 0.0, 1.0).x, _6637.y ? m.y : vec4(1.0, 0.0, 0.0, 1.0).y, _6637.z ? m.z : vec4(1.0, 0.0, 0.0, 1.0).z, _6637.w ? m.w : vec4(1.0, 0.0, 0.0, 1.0).w);\n        vec3 param_17 = p0;\n        vec3 param_18 = p1;\n        vec3 param_19 = p2;\n        vec3 param_20 = p3;\n        float _6648 = fa_ltc_quad(param_16, param_17, param_18, param_19, param_20);\n        if (_6551)\n        {\n            vec2 _9343 = sum;\n            _9343.y = _9343.y + _6648;\n            sum = _9343;\n        }\n        else\n        {\n            vec2 _9346 = sum;\n            _9346.x = _9346.x + _6648;\n            sum = _9346;\n        }\n    }\n    return abs(sum);\n}\n\nvec3 fa_area_shade(int li, vec3 world_pos, vec3 n, vec3 v, vec3 diffuse_color, vec3 f0, float f90, float roughness, float ndv, float window)\n{\n    int param = li;\n    int _6672 = fa_light_base(param);\n    int param_1 = _6672;\n    int param_2 = _6672 + 1;\n    int param_3 = _6672 + 2;\n    int param_4 = _6672 + 4;\n    vec4 _6694 = fa_light_texel(param_4);\n    int param_5 = _6672 + 5;\n    vec4 _6699 = fa_light_texel(param_5);\n    int param_6 = _6672 + 6;\n    vec4 _6704 = fa_light_texel(param_6);\n    float _6705 = _6704.w;\n    vec3 _6710 = fa_light_texel(param_1).xyz - world_pos;\n    bool _6712 = _6705 < 1.5;\n    bool _6719;\n    if (_6712)\n    {\n        _6719 = dot(normalize(fa_light_texel(param_3).xyz), _6710) >= 0.0;\n    }\n    else\n    {\n        _6719 = _6712;\n    }\n    if (_6719)\n    {\n        return vec3(0.0);\n    }\n    bool _6728 = (_6705 > 0.5) && _6712;\n    float _6732 = _6728 ? 1.0539000034332275390625 : 1.0;\n    vec3 _6735 = _6694.xyz;\n    float _6737 = _6694.w;\n    vec3 _6743 = _6699.xyz;\n    float _6745 = _6699.w;\n    vec3 up = _6743 * (_6745 * _6732);\n    float _6751;\n    if (_6728)\n    {\n        _6751 = (3.1415927410125732421875 * _6737) * _6737;\n    }\n    else\n    {\n        _6751 = (4.0 * _6737) * _6745;\n    }\n    if (_6705 > 1.5)\n    {\n        vec3 _6777 = cross(_6735, -_6710);\n        vec3 perp = _6777;\n        float _6781 = dot(_6777, _6777);\n        vec3 _6784;\n        if (_6781 > 1.0000000133514319600180897396058e-10)\n        {\n            _6784 = perp * inversesqrt(_6781);\n        }\n        else\n        {\n            _6784 = _6743;\n        }\n        perp = _6784;\n        up = _6784 * _6745;\n    }\n    float _6805 = max(_6751, 9.9999999747524270787835121154785e-07);\n    vec3 param_7 = n;\n    vec3 param_8 = v;\n    vec3 _6815 = fa_ltc_tangent(param_7, param_8);\n    vec3 param_9 = _6815;\n    vec3 param_10 = n;\n    vec3 param_11 = _6710;\n    vec3 param_12 = _6815;\n    vec3 param_13 = n;\n    vec3 param_14 = _6735 * (_6737 * _6732);\n    vec3 param_15 = _6815;\n    vec3 param_16 = n;\n    vec3 param_17 = up;\n    float param_18 = roughness;\n    float param_19 = ndv;\n    vec2 _6846 = fa_ltc_uv(param_18, param_19) * 64.0;\n    vec2 param_20 = _6846;\n    vec2 param_21 = _6846 + vec2(64.0, 0.0);\n    vec4 _6856 = fa_atlas_fetch(param_21);\n    vec4 param_22 = fa_atlas_fetch(param_20);\n    float param_23 = _6705;\n    vec3 param_24 = fa_ltc_local(param_9, param_10, param_11);\n    vec3 param_25 = fa_ltc_local(param_12, param_13, param_14);\n    vec3 param_26 = fa_ltc_local(param_15, param_16, param_17);\n    vec2 _6868 = fa_area_forms(param_22, param_23, param_24, param_25, param_26);\n    return (((diffuse_color * _6868.x) + (((f0 * _6856.x) + ((vec3(f90) - f0) * _6856.y)) * _6868.y)) * fa_light_texel(param_2).xyz) * ((((3.1415927410125732421875 * dot(_6710, _6710)) + _6805) / _6805) * window);\n}\n\nvec3 fa_light_rgb(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 1;\n    return fa_light_texel(param_1).xyz;\n}\n\nfloat fa_d_charlie(float alpha, float ndh)\n{\n    float _4950 = 1.0 / alpha;\n    return ((2.0 + _4950) * pow(sqrt(max(1.0 - (ndh * ndh), 9.9999997473787516355514526367188e-05)), _4950)) * 0.15915493667125701904296875;\n}\n\nfloat fa_v_ashikhmin(float ndl, float ndv)\n{\n    return clamp(0.25 / max((ndl + ndv) - (ndl * ndv), 9.9999997473787516355514526367188e-05), 0.0, 1.0);\n}\n\nfloat fa_layers_coat(FaLayers L, vec3 l, vec3 h, float vdh)\n{\n    float _4985 = max(dot(L.nc, l), 0.0);\n    float _4991 = max(dot(L.nc, h), 0.0);\n    float _5000 = ((_4991 * _4991) * (L.coat_a2 - 1.0)) + 1.0;\n    return (((L.coat * (0.039999999105930328369140625 + (0.959999978542327880859375 * pow(clamp(1.0 - vdh, 0.0, 1.0), 5.0)))) * (((L.coat_a2 / ((3.1415927410125732421875 * _5000) * _5000)) * (0.5 / max(mix((2.0 * _4985) * L.coat_ndv, _4985 + L.coat_ndv, L.coat_alpha), 9.9999997473787516355514526367188e-05))) * 3.1415927410125732421875)) * step(9.9999997473787516355514526367188e-05, _4985)) * _4985;\n}\n\nvec3 fa_area_layers(FaLayers L, vec3 base, int li, vec3 n, vec3 v, vec3 l, float ndv, float window)\n{\n    float _6905;\n    if (L.sheen_on)\n    {\n        _6905 = L.sheen_scale;\n    }\n    else\n    {\n        _6905 = 1.0;\n    }\n    vec3 result = base * (L.keep * _6905);\n    vec3 _6918 = normalize(l + v);\n    int param = li;\n    vec3 _6929 = fa_light_rgb(param) * window;\n    if (L.sheen_on)\n    {\n        float _6938 = max(dot(n, l), 0.0);\n        float param_1 = L.sheen_alpha;\n        float param_2 = max(dot(n, _6918), 0.0);\n        float param_3 = _6938;\n        float param_4 = ndv;\n        result += ((L.sheen * _6929) * (((((fa_d_charlie(param_1, param_2) * fa_v_ashikhmin(param_3, param_4)) * 3.1415927410125732421875) * step(9.9999997473787516355514526367188e-05, _6938)) * _6938) * L.keep));\n    }\n    if (L.coat > 0.0)\n    {\n        FaLayers param_5 = L;\n        vec3 param_6 = l;\n        vec3 param_7 = _6918;\n        float param_8 = max(dot(v, _6918), 0.0);\n        result += (_6929 * fa_layers_coat(param_5, param_6, param_7, param_8));\n    }\n    return result;\n}\n\nfloat fa_d_ggx_aniso(float ndh, float tdh, float bdh, float at, float ab)\n{\n    float _4853 = tdh / at;\n    float _4857 = bdh / ab;\n    float _4869 = ((_4853 * _4853) + (_4857 * _4857)) + (ndh * ndh);\n    return 1.0 / ((((3.1415927410125732421875 * at) * ab) * _4869) * _4869);\n}\n\nfloat fa_lambda_ggx_aniso(float n, float t, float b, float at, float ab)\n{\n    return 0.5 * (sqrt(1.0 + (((((at * at) * t) * t) + (((ab * ab) * b) * b)) / max(n * n, 9.9999999392252902907785028219223e-09))) - 1.0);\n}\n\nfloat fa_v_ggx_aniso(float ndl, float ndv, float tdv, float bdv, float tdl, float bdl, float at, float ab)\n{\n    float param = ndv;\n    float param_1 = tdv;\n    float param_2 = bdv;\n    float param_3 = at;\n    float param_4 = ab;\n    float param_5 = ndl;\n    float param_6 = tdl;\n    float param_7 = bdl;\n    float param_8 = at;\n    float param_9 = ab;\n    return clamp(1.0 / ((4.0 * max(ndl * ndv, 9.9999997473787516355514526367188e-05)) * ((1.0 + fa_lambda_ggx_aniso(param, param_1, param_2, param_3, param_4)) + fa_lambda_ggx_aniso(param_5, param_6, param_7, param_8, param_9))), 0.0, 1.0);\n}\n\nvec3 fa_layers_light(FaLayers L, vec3 diffuse_color, vec3 f0, vec3 n, vec3 v, vec3 l, vec3 h, float ndl, float ndv, float ndh, float vdh, float alpha, float a2)\n{\n    float _5049 = step(9.9999997473787516355514526367188e-05, ndl);\n    float d_ggx;\n    float vis;\n    if (L.aniso != 0.0)\n    {\n        float param = ndh;\n        float param_1 = dot(L.t, h);\n        float param_2 = dot(L.b, h);\n        float param_3 = L.at;\n        float param_4 = L.ab;\n        d_ggx = fa_d_ggx_aniso(param, param_1, param_2, param_3, param_4);\n        float param_5 = ndl;\n        float param_6 = ndv;\n        float param_7 = dot(L.t, v);\n        float param_8 = dot(L.b, v);\n        float param_9 = dot(L.t, l);\n        float param_10 = dot(L.b, l);\n        float param_11 = L.at;\n        float param_12 = L.ab;\n        vis = fa_v_ggx_aniso(param_5, param_6, param_7, param_8, param_9, param_10, param_11, param_12);\n    }\n    else\n    {\n        float _5128 = ((ndh * ndh) * (a2 - 1.0)) + 1.0;\n        d_ggx = a2 / ((3.1415927410125732421875 * _5128) * _5128);\n        vis = 0.5 / max(mix((2.0 * ndl) * ndv, ndl + ndv, alpha), 9.9999997473787516355514526367188e-05);\n    }\n    vec3 base = diffuse_color + (((f0 + ((vec3(L.f90) - f0) * pow(clamp(1.0 - vdh, 0.0, 1.0), 5.0))) * ((d_ggx * vis) * 3.1415927410125732421875)) * _5049);\n    if (L.sheen_on)\n    {\n        float param_13 = L.sheen_alpha;\n        float param_14 = ndh;\n        float param_15 = ndl;\n        float param_16 = ndv;\n        base = (base * L.sheen_scale) + (L.sheen * (((fa_d_charlie(param_13, param_14) * fa_v_ashikhmin(param_15, param_16)) * 3.1415927410125732421875) * _5049));\n    }\n    vec3 result = base * (L.keep * ndl);\n    if (L.coat > 0.0)\n    {\n        FaLayers param_17 = L;\n        vec3 param_18 = l;\n        vec3 param_19 = h;\n        float param_20 = vdh;\n        result += vec3(fa_layers_coat(param_17, param_18, param_19, param_20));\n    }\n    return result;\n}\n\nvec2 fa_env_brdf(float rough, float ndv)\n{\n    vec4 _4252 = (vec4(-1.0, -0.0274999998509883880615234375, -0.572000026702880859375, 0.02199999988079071044921875) * rough) + vec4(1.0, 0.0425000004470348358154296875, 1.03999996185302734375, -0.039999999105930328369140625);\n    float _4255 = _4252.x;\n    return (vec2(-1.03999996185302734375, 1.03999996185302734375) * ((min(_4255 * _4255, exp2((-9.27999973297119140625) * ndv)) * _4255) + _4252.y)) + _4252.zw;\n}\n\nvec3 fa_probe_level(vec2 origin, float res, int lv, vec2 e)\n{\n    float _3560;\n    if (lv == 0)\n    {\n        _3560 = 0.0;\n    }\n    else\n    {\n        _3560 = res + 2.0;\n    }\n    float _3570;\n    if (lv == 0)\n    {\n        _3570 = 0.0;\n    }\n    else\n    {\n        _3570 = (res - (res / float(1 << max((lv - 1), 0)))) + (2.0 * float(lv - 1));\n    }\n    return textureLod(fa_probe_atlas_fa_env_smp, (((origin + vec2(_3560, _3570)) + vec2(1.0)) + (((e * 0.5) + vec2(0.5)) * (res / float(1 << lv)))) / fa_atlas_size(), 0.0).xyz;\n}\n\nvec3 fa_probe_radiance(vec2 origin, float res, vec3 d, float rough)\n{\n    float _3616;\n    if (res > 64.5)\n    {\n        _3616 = 5.0;\n    }\n    else\n    {\n        _3616 = (res > 32.5) ? 4.0 : 3.0;\n    }\n    float _3631 = clamp(rough, 0.0, 1.0) * (_3616 - 1.0);\n    int _3638 = int(min(floor(_3631), _3616 - 2.0));\n    float _3643 = _3631 - float(_3638);\n    vec3 param = d;\n    vec2 _3647 = fa_oct_encode(param);\n    vec2 param_1 = origin;\n    float param_2 = res;\n    int param_3 = _3638;\n    vec2 param_4 = _3647;\n    vec3 _3657 = fa_probe_level(param_1, param_2, param_3, param_4);\n    if (_3643 < 0.00200000009499490261077880859375)\n    {\n        return _3657;\n    }\n    vec2 param_5 = origin;\n    float param_6 = res;\n    int param_7 = _3638 + 1;\n    vec2 param_8 = _3647;\n    return mix(_3657, fa_probe_level(param_5, param_6, param_7, param_8), vec3(_3643));\n}\n\nvec3 fa_probe_box_dir(vec3 d, vec4 posw, vec4 bx, vec4 by, vec4 bz)\n{\n    if (posw.w < 0.5)\n    {\n        return d;\n    }\n    float _3730 = dot(bx.xyz, fa_world_pos) + bx.w;\n    float _3737 = dot(by.xyz, fa_world_pos) + by.w;\n    float _3744 = dot(bz.xyz, fa_world_pos) + bz.w;\n    float _3750 = dot(bx.xyz, d);\n    float _3754 = dot(by.xyz, d);\n    float _3758 = dot(bz.xyz, d);\n    float _3764;\n    if (_3750 > 9.9999999747524270787835121154785e-07)\n    {\n        _3764 = (1.0 - _3730) / _3750;\n    }\n    else\n    {\n        float _3778;\n        if (_3750 < (-9.9999999747524270787835121154785e-07))\n        {\n            _3778 = ((-1.0) - _3730) / _3750;\n        }\n        else\n        {\n            _3778 = 1000000015047466219876688855040.0;\n        }\n        _3764 = _3778;\n    }\n    float tx = _3764;\n    float _3795;\n    if (_3754 > 9.9999999747524270787835121154785e-07)\n    {\n        _3795 = (1.0 - _3737) / _3754;\n    }\n    else\n    {\n        float _3808;\n        if (_3754 < (-9.9999999747524270787835121154785e-07))\n        {\n            _3808 = ((-1.0) - _3737) / _3754;\n        }\n        else\n        {\n            _3808 = 1000000015047466219876688855040.0;\n        }\n        _3795 = _3808;\n    }\n    float ty = _3795;\n    float _3824;\n    if (_3758 > 9.9999999747524270787835121154785e-07)\n    {\n        _3824 = (1.0 - _3744) / _3758;\n    }\n    else\n    {\n        float _3837;\n        if (_3758 < (-9.9999999747524270787835121154785e-07))\n        {\n            _3837 = ((-1.0) - _3744) / _3758;\n        }\n        else\n        {\n            _3837 = 1000000015047466219876688855040.0;\n        }\n        _3824 = _3837;\n    }\n    float _3849 = tx;\n    float _3852 = (_3849 > 0.0) ? _3849 : 1000000015047466219876688855040.0;\n    tx = _3852;\n    float _3853 = ty;\n    float _3856 = (_3853 > 0.0) ? _3853 : 1000000015047466219876688855040.0;\n    ty = _3856;\n    float _3866 = min(_3852, min(_3856, (_3824 > 0.0) ? _3824 : 1000000015047466219876688855040.0));\n    if (_3866 > 100000001504746621987668885504.0)\n    {\n        return d;\n    }\n    vec3 _3882 = (fa_world_pos + (d * _3866)) - posw.xyz;\n    vec3 _3887;\n    if (dot(_3882, _3882) > 1.0000000133514319600180897396058e-10)\n    {\n        _3887 = normalize(_3882);\n    }\n    else\n    {\n        _3887 = d;\n    }\n    return _3887;\n}\n\nvec3 fa_probe_environment(vec4 tile, vec4 posw, vec4 bx, vec4 by, vec4 bz, inout vec3 d, float rough)\n{\n    vec3 param = d;\n    vec4 param_1 = posw;\n    vec4 param_2 = bx;\n    vec4 param_3 = by;\n    vec4 param_4 = bz;\n    d = fa_probe_box_dir(param, param_1, param_2, param_3, param_4);\n    vec2 param_5 = tile.xy;\n    float param_6 = tile.z;\n    vec3 param_7 = d;\n    float param_8 = rough;\n    return fa_probe_radiance(param_5, param_6, param_7, param_8);\n}\n\nvec3 fa_environment(vec3 d, float rough)\n{\n    float _3933 = (1.0 - fa_mesh_fs_params[42].w) - fa_mesh_fs_params[47].w;\n    vec3 outc = vec3(0.0);\n    if (_3933 > 0.0005000000237487256526947021484375)\n    {\n        vec3 base;\n        if (fa_mesh_fs_params[11].w > 0.5)\n        {\n            vec2 param = fa_mesh_fs_params[41].zw;\n            float param_1 = 128.0;\n            vec3 param_2 = d;\n            float param_3 = rough;\n            base = fa_probe_radiance(param, param_1, param_2, param_3);\n        }\n        else\n        {\n            float _3961 = rough * rough;\n            float _3992 = 0.60000002384185791015625 * _3961;\n            base = mix(mix(fa_mesh_fs_params[12].xyz * 0.550000011920928955078125, mix(fa_mesh_fs_params[12].xyz, fa_mesh_fs_params[11].xyz, vec3(pow(clamp(d.y * (1.0 - (0.699999988079071044921875 * _3961)), 0.0, 1.0), 0.550000011920928955078125))), vec3(smoothstep((-0.0500000007450580596923828125) - _3992, 0.0500000007450580596923828125 + _3992, d.y))), ((fa_mesh_fs_params[11].xyz + fa_mesh_fs_params[12].xyz) * 0.5) * 0.800000011920928955078125, vec3(_3961 * 0.60000002384185791015625));\n        }\n        outc = base * _3933;\n    }\n    if (fa_mesh_fs_params[42].w > 0.0)\n    {\n        vec4 param_4 = fa_mesh_fs_params[42];\n        vec4 param_5 = fa_mesh_fs_params[43];\n        vec4 param_6 = fa_mesh_fs_params[44];\n        vec4 param_7 = fa_mesh_fs_params[45];\n        vec4 param_8 = fa_mesh_fs_params[46];\n        vec3 param_9 = d;\n        float param_10 = rough;\n        vec3 _4051 = fa_probe_environment(param_4, param_5, param_6, param_7, param_8, param_9, param_10);\n        outc += (_4051 * fa_mesh_fs_params[42].w);\n    }\n    if (fa_mesh_fs_params[47].w > 0.0)\n    {\n        vec4 param_11 = fa_mesh_fs_params[47];\n        vec4 param_12 = fa_mesh_fs_params[48];\n        vec4 param_13 = fa_mesh_fs_params[49];\n        vec4 param_14 = fa_mesh_fs_params[50];\n        vec4 param_15 = fa_mesh_fs_params[51];\n        vec3 param_16 = d;\n        float param_17 = rough;\n        vec3 _4083 = fa_probe_environment(param_11, param_12, param_13, param_14, param_15, param_16, param_17);\n        outc += (_4083 * fa_mesh_fs_params[47].w);\n    }\n    return outc;\n}\n\nvec3 fa_layers_ibl(FaLayers L, vec3 n, vec3 v, vec3 f0, float roughness, float occlusion)\n{\n    vec3 rn = n;\n    if (L.aniso != 0.0)\n    {\n        vec3 _4730;\n        if (L.aniso >= 0.0)\n        {\n            _4730 = L.b;\n        }\n        else\n        {\n            _4730 = L.t;\n        }\n        rn = normalize(mix(n, cross(cross(_4730, v), _4730), vec3(abs(L.aniso) * smoothstep(0.0, 0.25, roughness))));\n    }\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05);\n    vec2 _4766 = fa_env_brdf(param, param_1);\n    vec3 param_2 = reflect(-v, rn);\n    float param_3 = roughness;\n    vec3 result = (fa_environment(param_2, param_3) * ((f0 * _4766.x) + (vec3(L.f90) * _4766.y))) * L.base_scale;\n    if (L.sheen_on)\n    {\n        vec3 param_4 = n;\n        float param_5 = L.sheen_rough;\n        result += ((L.sheen * (L.sheen_e * L.keep)) * fa_environment(param_4, param_5));\n    }\n    result *= occlusion;\n    if (L.coat > 0.0)\n    {\n        float param_6 = L.coat_rough;\n        float param_7 = L.coat_ndv;\n        vec2 _4824 = fa_env_brdf(param_6, param_7);\n        vec3 param_8 = reflect(-v, L.nc);\n        float param_9 = L.coat_rough;\n        result += (fa_environment(param_8, param_9) * (L.coat * ((0.039999999105930328369140625 * _4824.x) + _4824.y)));\n    }\n    return result;\n}\n\nvec3 fa_sky_reflection(vec3 n, vec3 v, vec3 f0, float roughness)\n{\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05);\n    vec2 _4294 = fa_env_brdf(param, param_1);\n    vec3 param_2 = reflect(-v, n);\n    float param_3 = roughness;\n    return fa_environment(param_2, param_3) * ((f0 * _4294.x) + vec3(_4294.y));\n}\n\nvec2 fa_xm_size(int k)\n{\n    return max(floor(fa_mesh_fs_params[24].zw / vec2(float(1 << k))), vec2(1.0));\n}\n\nvec2 fa_xm_origin(int k)\n{\n    if (k == 0)\n    {\n        return vec2(0.0);\n    }\n    float y = 0.0;\n    for (int j = 1; j < k; j++)\n    {\n        int param = j;\n        y += fa_xm_size(param).y;\n    }\n    return vec2(fa_mesh_fs_params[24].z, y);\n}\n\nvec3 fa_xm_texel(vec2 size, vec2 origin, vec2 p)\n{\n    return texelFetch(fa_screen_tex_fa_shadow_smp, ivec2(origin + clamp(p, vec2(0.0), size - vec2(1.0))), 0).xyz;\n}\n\nvec3 fa_xm_level(int k, vec2 uv)\n{\n    int param = k;\n    vec2 _5534 = fa_xm_size(param);\n    int param_1 = k;\n    vec2 _5538 = fa_xm_origin(param_1);\n    vec2 _5544 = (uv * _5534) - vec2(0.5);\n    vec2 _5547 = fract(_5544);\n    vec2 _5550 = floor(_5544);\n    vec2 param_2 = _5534;\n    vec2 param_3 = _5538;\n    vec2 param_4 = _5550;\n    vec2 param_5 = _5534;\n    vec2 param_6 = _5538;\n    vec2 param_7 = _5550 + vec2(1.0, 0.0);\n    vec2 param_8 = _5534;\n    vec2 param_9 = _5538;\n    vec2 param_10 = _5550 + vec2(0.0, 1.0);\n    vec2 param_11 = _5534;\n    vec2 param_12 = _5538;\n    vec2 param_13 = _5550 + vec2(1.0);\n    vec3 _5592 = vec3(_5547.x);\n    return mix(mix(fa_xm_texel(param_2, param_3, param_4), fa_xm_texel(param_5, param_6, param_7), _5592), mix(fa_xm_texel(param_8, param_9, param_10), fa_xm_texel(param_11, param_12, param_13), _5592), vec3(_5547.y));\n}\n\nvec3 fa_xm_sample(vec2 uv, float lod)\n{\n    float _5611 = max(fa_mesh_fs_params[31].w - 1.0, 0.0);\n    float _5615 = clamp(lod, 0.0, _5611);\n    int _5619 = int(floor(_5615));\n    int param = _5619;\n    vec2 param_1 = uv;\n    vec3 c = fa_xm_level(param, param_1);\n    float _5629 = float(_5619);\n    float _5630 = _5615 - _5629;\n    bool _5632 = _5630 > 0.001000000047497451305389404296875;\n    bool _5639;\n    if (_5632)\n    {\n        _5639 = _5629 < _5611;\n    }\n    else\n    {\n        _5639 = _5632;\n    }\n    if (_5639)\n    {\n        int param_2 = _5619 + 1;\n        vec2 param_3 = uv;\n        c = mix(c, fa_xm_level(param_2, param_3), vec3(_5630));\n    }\n    return c;\n}\n\nvec3 fa_transmitted(Surface s, vec3 n, vec3 v, float roughness, vec3 f0, float f90, float keep, float tr, inout float blend)\n{\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05);\n    vec2 _5665 = fa_env_brdf(param, param_1);\n    vec3 through = ((vec3(1.0) - clamp((f0 * _5665.x) + (vec3(f90) * _5665.y), vec3(0.0), vec3(1.0))) * s.albedo) * (tr * keep);\n    float _5693 = max(s.thickness, 0.0);\n    bool _5698 = _5693 > 0.0;\n    if ((s.attenuation_distance > 0.0) && _5698)\n    {\n        through *= exp((-((-log(clamp(s.attenuation_color, vec3(9.9999997473787516355514526367188e-05), vec3(1.0)))) / vec3(s.attenuation_distance))) * _5693);\n    }\n    bool _5723 = fa_mesh_fs_params[30].w > 1.5;\n    bool _5730;\n    if (!_5723)\n    {\n        _5730 = fa_mesh_fs_params[30].w < 0.5;\n    }\n    else\n    {\n        _5730 = _5723;\n    }\n    if (_5730)\n    {\n        blend = clamp(dot(through, vec3(0.3333333432674407958984375)), 0.0, 0.980000019073486328125);\n        return vec3(0.0);\n    }\n    vec3 world = fa_world_pos;\n    if (_5698)\n    {\n        world += (refract(-v, n, 1.0 / max(s.ior, 1.0)) * _5693);\n    }\n    vec4 _5765 = vec4(world, 1.0);\n    float _5770 = dot(fa_mesh_fs_params[28], _5765);\n    vec2 uv = vec2(0.5);\n    if (_5770 > 9.9999997473787516355514526367188e-05)\n    {\n        vec2 _5788 = vec2(dot(fa_mesh_fs_params[26], _5765), dot(fa_mesh_fs_params[27], _5765)) / vec2(_5770);\n        float _5796;\n        if (fa_mesh_fs_params[24].y > 0.5)\n        {\n            _5796 = (_5788.y * 0.5) + 0.5;\n        }\n        else\n        {\n            _5796 = 0.5 - (_5788.y * 0.5);\n        }\n        uv = vec2((_5788.x * 0.5) + 0.5, _5796);\n    }\n    vec2 param_2 = clamp(uv, vec2(0.0), vec2(1.0));\n    float param_3 = (clamp(roughness, 0.0, 1.0) * clamp((2.0 * s.ior) - 2.0, 0.0, 1.0)) * max(fa_mesh_fs_params[31].w - 1.0, 0.0);\n    return through * fa_xm_sample(param_2, param_3);\n}\n\nvec3 fa_shadow_debug(vec3 color, vec3 world)\n{\n    if (fa_shadows[27].w < 0.5)\n    {\n        return color;\n    }\n    int _3311 = int(fa_shadows[25].x + 0.5);\n    float _3321 = dot(world - fa_shadows[27].xyz, fa_shadows[28].xyz);\n    vec3 tint_1 = vec3(0.3499999940395355224609375);\n    bool _3326 = _3311 > 0;\n    bool _3335;\n    if (_3326)\n    {\n        int param = _3311 - 1;\n        _3335 = _3321 <= fa_shadow_split_at(param);\n    }\n    else\n    {\n        _3335 = _3326;\n    }\n    if (_3335)\n    {\n        tint_1 = vec3(1.0, 0.1500000059604644775390625, 0.100000001490116119384765625);\n        bool _3341 = _3311 > 1;\n        bool _3348;\n        if (_3341)\n        {\n            _3348 = _3321 > fa_shadows[24].x;\n        }\n        else\n        {\n            _3348 = _3341;\n        }\n        if (_3348)\n        {\n            tint_1 = vec3(0.100000001490116119384765625, 0.89999997615814208984375, 0.20000000298023223876953125);\n        }\n        bool _3354 = _3311 > 2;\n        bool _3361;\n        if (_3354)\n        {\n            _3361 = _3321 > fa_shadows[24].y;\n        }\n        else\n        {\n            _3361 = _3354;\n        }\n        if (_3361)\n        {\n            tint_1 = vec3(0.1500000059604644775390625, 0.300000011920928955078125, 1.0);\n        }\n        bool _3367 = _3311 > 3;\n        bool _3374;\n        if (_3367)\n        {\n            _3374 = _3321 > fa_shadows[24].z;\n        }\n        else\n        {\n            _3374 = _3367;\n        }\n        if (_3374)\n        {\n            tint_1 = vec3(1.0, 0.89999997615814208984375, 0.100000001490116119384765625);\n        }\n    }\n    return mix(color, tint_1, vec3(0.550000011920928955078125));\n}\n\nvoid main()\n{\n    fa_inst_load();\n    vec3 _8775 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _8775 = -_8775;\n    }\n    vec3 _8072 = normalize(fa_mesh_fs_params[0].xyz - fa_world_pos);\n    vec3 param = fa_world_pos;\n    fa_cluster_begin(param);\n    SurfaceInput param_1 = SurfaceInput(fa_world_pos, _8775, fa_world_tangent, fa_uv, fa_vertex_color, _8072, gl_FrontFacing);\n    Surface _8080 = fa_standard_surface(param_1);\n    vec3 _8806 = _8080.albedo;\n    float _8807 = _8080.alpha;\n    vec3 _8808 = _8080.normal;\n    float _8809 = _8080.metallic;\n    float _8810 = _8080.roughness;\n    float _8811 = _8080.occlusion;\n    vec3 _8812 = _8080.emission;\n    float _8813 = _8080.clearcoat;\n    float _8814 = _8080.clearcoat_roughness;\n    vec3 _8815 = _8080.sheen_color;\n    float _8816 = _8080.sheen_roughness;\n    float _8817 = _8080.anisotropy;\n    float _8818 = _8080.anisotropy_rotation;\n    float _8819 = _8080.specular;\n    float _8820 = _8080.ior;\n    vec3 _8821 = _8080.specular_color;\n    float _8822 = _8080.transmission;\n    float _8823 = _8080.thickness;\n    vec3 _8824 = _8080.attenuation_color;\n    float _8825 = _8080.attenuation_distance;\n    SurfaceInput param_2 = SurfaceInput(fa_world_pos, _8775, fa_world_tangent, fa_uv, fa_vertex_color, _8072, gl_FrontFacing);\n    Surface param_3 = _8080;\n    surface(param_2, param_3);\n    _8806 = param_3.albedo;\n    _8807 = param_3.alpha;\n    _8808 = param_3.normal;\n    _8809 = param_3.metallic;\n    _8810 = param_3.roughness;\n    _8811 = param_3.occlusion;\n    _8812 = param_3.emission;\n    _8813 = param_3.clearcoat;\n    _8814 = param_3.clearcoat_roughness;\n    _8815 = param_3.sheen_color;\n    _8816 = param_3.sheen_roughness;\n    _8817 = param_3.anisotropy;\n    _8818 = param_3.anisotropy_rotation;\n    _8819 = param_3.specular;\n    _8820 = param_3.ior;\n    _8821 = param_3.specular_color;\n    _8822 = param_3.transmission;\n    _8823 = param_3.thickness;\n    _8824 = param_3.attenuation_color;\n    _8825 = param_3.attenuation_distance;\n    vec3 param_4 = fa_world_pos;\n    vec3 param_5 = _8775;\n    vec3 param_6 = param_3.albedo;\n    vec3 param_7 = param_3.normal;\n    fa_apply_decals(param_4, param_5, param_6, param_7);\n    _8806 = param_6;\n    _8808 = param_7;\n    fa_lod_dither();\n    float fa_tr_blend = 0.0;\n    vec3 result;\n    if (fa_mesh_fs_params[3].w > 0.5)\n    {\n        result = _8806;\n    }\n    else\n    {\n        vec3 _8121 = normalize(_8808);\n        float _8128 = clamp(_8809, 0.0, 1.0);\n        float _8132 = clamp(_8810, 0.0500000007450580596923828125, 1.0);\n        float _8136 = _8132 * _8132;\n        float _8140 = _8136 * _8136;\n        float _8145 = max(dot(_8121, _8072), 9.9999997473787516355514526367188e-05);\n        float _8151 = 1.0 - _8128;\n        float _8152 = clamp(_8822, 0.0, 1.0) * _8151;\n        vec3 _8161 = (_8806 * _8151) * (1.0 - _8152);\n        vec3 _8168 = mix(vec3(0.039999999105930328369140625), _8806, vec3(_8128));\n        vec3 f0 = _8168;\n        SurfaceInput param_8 = SurfaceInput(fa_world_pos, _8775, fa_world_tangent, fa_uv, fa_vertex_color, _8072, gl_FrontFacing);\n        Surface param_9 = Surface(_8806, _8807, _8808, _8809, _8810, _8811, _8812, _8813, _8814, _8815, _8816, _8817, _8818, _8819, _8820, _8821, _8822, _8823, _8824, _8825);\n        vec3 param_10 = _8121;\n        vec3 param_11 = _8072;\n        float param_12 = _8128;\n        float param_13 = _8132;\n        vec3 param_14 = _8168;\n        FaLayers _8184 = fa_layers_setup(param_8, param_9, param_10, param_11, param_12, param_13, param_14);\n        f0 = param_14;\n        vec3 param_15 = _8121;\n        vec3 lit = (fa_indirect_diffuse(param_15) * _8161) * _8811;\n        if (_8184.on)\n        {\n            lit *= _8184.base_scale;\n        }\n        int _8206 = fa_cl_ndir + fa_cl_local;\n        float _8271;\n        for (int ln = 0; ln < _8206; ln++)\n        {\n            int param_16 = ln;\n            int _8219 = fa_cl_light(param_16);\n            int param_17 = _8219;\n            if (fa_baked_keep(param_17) <= 0.0)\n            {\n                continue;\n            }\n            int param_18 = _8219;\n            vec3 param_19 = fa_world_pos;\n            vec3 param_20 = _8775;\n            LightSample _8235 = fa_light_shadowed(param_18, param_19, param_20);\n            float _8243 = max(dot(_8121, _8235.direction), 0.0);\n            float _8249 = _8235.attenuation * _8235.shadow;\n            vec3 _8254 = normalize(_8235.direction + _8072);\n            float _8259 = max(dot(_8121, _8254), 0.0);\n            float _8264 = max(dot(_8072, _8254), 0.0);\n            if (fa_light_is_area)\n            {\n                if (_8184.on)\n                {\n                    _8271 = _8184.f90;\n                }\n                else\n                {\n                    _8271 = 1.0;\n                }\n                int param_21 = _8219;\n                vec3 param_22 = fa_world_pos;\n                vec3 param_23 = _8121;\n                vec3 param_24 = _8072;\n                vec3 param_25 = _8161;\n                vec3 param_26 = f0;\n                float param_27 = _8271;\n                float param_28 = _8132;\n                float param_29 = _8145;\n                float param_30 = _8249;\n                vec3 area = fa_area_shade(param_21, param_22, param_23, param_24, param_25, param_26, param_27, param_28, param_29, param_30);\n                if (_8184.on)\n                {\n                    FaLayers param_31 = _8184;\n                    vec3 param_32 = area;\n                    int param_33 = _8219;\n                    vec3 param_34 = _8121;\n                    vec3 param_35 = _8072;\n                    vec3 param_36 = _8235.direction;\n                    float param_37 = _8145;\n                    float param_38 = _8249;\n                    area = fa_area_layers(param_31, param_32, param_33, param_34, param_35, param_36, param_37, param_38);\n                }\n                lit += area;\n            }\n            else\n            {\n                if (_8184.on)\n                {\n                    FaLayers param_39 = _8184;\n                    vec3 param_40 = _8161;\n                    vec3 param_41 = f0;\n                    vec3 param_42 = _8121;\n                    vec3 param_43 = _8072;\n                    vec3 param_44 = _8235.direction;\n                    vec3 param_45 = _8254;\n                    float param_46 = _8243;\n                    float param_47 = _8145;\n                    float param_48 = _8259;\n                    float param_49 = _8264;\n                    float param_50 = _8136;\n                    float param_51 = _8140;\n                    int param_52 = _8219;\n                    lit += (fa_layers_light(param_39, param_40, param_41, param_42, param_43, param_44, param_45, param_46, param_47, param_48, param_49, param_50, param_51) * ((fa_light_rgb(param_52) * fa_light_tint) * _8249));\n                }\n                else\n                {\n                    float _8373 = ((_8259 * _8259) * (_8140 - 1.0)) + 1.0;\n                    int param_53 = _8219;\n                    lit += (((_8161 + (((f0 + ((vec3(1.0) - f0) * pow(1.0 - _8264, 5.0))) * (((_8140 / ((3.1415927410125732421875 * _8373) * _8373)) * (0.5 / max(mix((2.0 * _8243) * _8145, _8243 + _8145, _8136), 9.9999997473787516355514526367188e-05))) * 3.1415927410125732421875)) * step(9.9999997473787516355514526367188e-05, _8243))) * (fa_light_rgb(param_53) * fa_light_tint)) * (_8243 * _8249));\n                }\n            }\n        }\n        if (_8184.on)\n        {\n            FaLayers param_54 = _8184;\n            vec3 param_55 = _8121;\n            vec3 param_56 = _8072;\n            vec3 param_57 = f0;\n            float param_58 = _8132;\n            float param_59 = _8811;\n            lit += fa_layers_ibl(param_54, param_55, param_56, param_57, param_58, param_59);\n        }\n        else\n        {\n            vec3 param_60 = _8121;\n            vec3 param_61 = _8072;\n            vec3 param_62 = f0;\n            float param_63 = _8132;\n            lit += (fa_sky_reflection(param_60, param_61, param_62, param_63) * _8811);\n        }\n        if (_8152 > 0.0)\n        {\n            float _8471;\n            if (_8184.on)\n            {\n                _8471 = _8184.f90;\n            }\n            else\n            {\n                _8471 = 1.0;\n            }\n            float _8479;\n            if (_8184.on)\n            {\n                _8479 = _8184.base_scale;\n            }\n            else\n            {\n                _8479 = 1.0;\n            }\n            Surface param_64 = Surface(_8806, _8807, _8808, _8809, _8810, _8811, _8812, _8813, _8814, _8815, _8816, _8817, _8818, _8819, _8820, _8821, _8822, _8823, _8824, _8825);\n            vec3 param_65 = _8121;\n            vec3 param_66 = _8072;\n            float param_67 = _8132;\n            vec3 param_68 = f0;\n            float param_69 = _8471;\n            float param_70 = _8479;\n            float param_71 = _8152;\n            float param_72 = fa_tr_blend;\n            vec3 _8503 = fa_transmitted(param_64, param_65, param_66, param_67, param_68, param_69, param_70, param_71, param_72);\n            fa_tr_blend = param_72;\n            lit += _8503;\n        }\n        result = lit;\n    }\n    vec3 _8510 = result;\n    vec3 _8511 = _8510 + _8812;\n    result = _8511;\n    vec3 param_73 = _8511;\n    vec3 param_74 = fa_world_pos;\n    result = fa_shadow_debug(param_73, param_74);\n    bool _8520 = fa_mesh_fs_params[7].w > 0.0;\n    bool _8527;\n    if (!_8520)\n    {\n        _8527 = fa_mesh_fs_params[8].y > 0.0;\n    }\n    else\n    {\n        _8527 = _8520;\n    }\n    if (_8527)\n    {\n        vec3 _8536 = fa_world_pos - fa_mesh_fs_params[0].xyz;\n        float _8542 = dot(_8536, fa_mesh_fs_params[9].xyz);\n        bool _8546 = fa_mesh_fs_params[9].w > 0.5;\n        float _8547;\n        if (_8546)\n        {\n            _8547 = _8542;\n        }\n        else\n        {\n            _8547 = length(_8536);\n        }\n        float _8559 = _8547 - fa_mesh_fs_params[8].x;\n        if (_8559 > 0.0)\n        {\n            float _8568 = fa_mesh_fs_params[7].w * _8559;\n            float tau = _8568 * _8568;\n            if (fa_mesh_fs_params[8].y > 0.0)\n            {\n                float _8584;\n                if (_8546)\n                {\n                    _8584 = fa_world_pos.y - (fa_mesh_fs_params[9].y * _8542);\n                }\n                else\n                {\n                    _8584 = fa_mesh_fs_params[0].y;\n                }\n                float _8605 = mix(_8584, fa_world_pos.y, clamp(fa_mesh_fs_params[8].x / _8547, 0.0, 1.0));\n                float _8609 = fa_world_pos.y - _8605;\n                float _8614 = _8605 - fa_mesh_fs_params[8].z;\n                float _8619 = fa_world_pos.y - fa_mesh_fs_params[8].z;\n                bool _8622 = _8614 <= 0.0;\n                bool _8623 = !_8622;\n                bool _8629;\n                if (_8623)\n                {\n                    _8629 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _8629 = _8622;\n                }\n                float _8630;\n                if (_8629)\n                {\n                    _8630 = fa_mesh_fs_params[8].y;\n                }\n                else\n                {\n                    _8630 = fa_mesh_fs_params[8].y * exp(-min(fa_mesh_fs_params[8].w * _8614, 80.0));\n                }\n                bool _8657;\n                if (_8623)\n                {\n                    _8657 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _8657 = _8622;\n                }\n                float _8658;\n                if (_8657)\n                {\n                    _8658 = fa_mesh_fs_params[8].y * _8614;\n                }\n                else\n                {\n                    _8658 = (fa_mesh_fs_params[8].y * (1.0 - exp(-min(fa_mesh_fs_params[8].w * _8614, 80.0)))) / fa_mesh_fs_params[8].w;\n                }\n                bool _8683 = _8619 <= 0.0;\n                bool _8690;\n                if (!_8683)\n                {\n                    _8690 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _8690 = _8683;\n                }\n                float _8691;\n                if (_8690)\n                {\n                    _8691 = fa_mesh_fs_params[8].y * _8619;\n                }\n                else\n                {\n                    _8691 = (fa_mesh_fs_params[8].y * (1.0 - exp(-min(fa_mesh_fs_params[8].w * _8619, 80.0)))) / fa_mesh_fs_params[8].w;\n                }\n                float _8718;\n                if (abs(_8609) < 0.001000000047497451305389404296875)\n                {\n                    _8718 = _8630;\n                }\n                else\n                {\n                    _8718 = (_8691 - _8658) / _8609;\n                }\n                tau += (_8559 * max(_8718, 0.0));\n            }\n            result = mix(result, fa_mesh_fs_params[7].xyz, vec3(clamp(1.0 - exp(-clamp(tau, 0.0, 80.0)), 0.0, 1.0)));\n        }\n    }\n    if (fa_tr_blend > 0.0)\n    {\n        float _8754 = 1.0 - fa_tr_blend;\n        result /= vec3(_8754);\n        _8807 *= _8754;\n    }\n    fa_frag_color = vec4(result, _8807);\n}\n\n",
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
            "inst_name": "_608",
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
            "inst_name": "_2352",
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
            "inst_name": "_7007",
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
      "fs": "#version 430\n\nstruct SurfaceInput\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 vertex_color;\n    vec3 view_dir;\n    bool front_facing;\n};\n\nstruct Surface\n{\n    vec3 albedo;\n    float alpha;\n    vec3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    vec3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    vec3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    vec3 specular_color;\n    float transmission;\n    float thickness;\n    vec3 attenuation_color;\n    float attenuation_distance;\n};\n\nuniform vec4 fa_mesh_fs_params[53];\nuniform vec4 fa_material[1];\nlayout(binding = 0) uniform sampler2D fa_tex_fa_smp;\nlayout(binding = 1) uniform sampler2D fa_normal_tex_fa_smp;\nlayout(binding = 2) uniform sampler2D fa_mr_tex_fa_smp;\nlayout(binding = 3) uniform sampler2D fa_occlusion_tex_fa_smp;\nlayout(binding = 4) uniform sampler2D fa_emissive_tex_fa_smp;\n\nlayout(location = 0) flat in vec4 fa_inst_v0;\nlayout(location = 1) flat in vec4 fa_inst_v1;\nlayout(location = 2) in vec3 fa_world_pos;\nlayout(location = 3) in vec3 fa_world_normal;\nlayout(location = 4) in vec4 fa_world_tangent;\nlayout(location = 5) in vec2 fa_uv;\nlayout(location = 6) in vec4 fa_vertex_color;\nlayout(location = 8) in vec3 fa_pre_r0;\nlayout(location = 9) in vec3 fa_pre_r1;\nlayout(location = 10) in vec3 fa_pre_r2;\nlayout(location = 0) out vec4 fa_frag_color;\nlayout(location = 7) in float fa_pre_depth;\nfloat raise;\nvec4 tint;\n\nvoid fa_instance_unpack(vec4 fa_d0, vec4 fa_d1, vec4 fa_d2)\n{\n    raise = fa_d0.x;\n    tint = fa_d1;\n}\n\nvoid fa_inst_load()\n{\n    vec4 param = fa_inst_v0;\n    vec4 param_1 = fa_inst_v1;\n    vec4 param_2 = vec4(0.0);\n    fa_instance_unpack(param, param_1, param_2);\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nvec3 fa_linear_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_tex_fix(inout vec3 c, float mode)\n{\n    if (mode > 1.5)\n    {\n        vec3 param = c;\n        vec3 _256 = fa_linear_to_srgb(param);\n        c = _256;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            vec3 param_1 = c;\n            vec3 _265 = fa_srgb_to_linear(param_1);\n            c = _265;\n        }\n    }\n    return c;\n}\n\nvec3 fa_tangent_normal(SurfaceInput i, vec3 m)\n{\n    vec3 _65;\n    if (i.front_facing)\n    {\n        _65 = i.world_normal;\n    }\n    else\n    {\n        _65 = -i.world_normal;\n    }\n    vec3 _89 = normalize(i.world_tangent.xyz - (_65 * dot(_65, i.world_tangent.xyz)));\n    vec3 _117 = normalize(((_89 * m.x) + ((cross(_65, _89) * i.world_tangent.w) * m.y)) + (_65 * m.z));\n    vec3 _120;\n    if (i.front_facing)\n    {\n        _120 = _117;\n    }\n    else\n    {\n        _120 = -_117;\n    }\n    return _120;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    vec4 base_t = texture(fa_tex_fa_smp, i.uv);\n    float param = fa_mesh_fs_params[6].w;\n    float param_1 = 1.0;\n    vec3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    vec3 _305 = fa_tex_fix(param_2, param_3);\n    vec4 _855 = base_t;\n    _855.x = _305.x;\n    _855.y = _305.y;\n    _855.z = _305.z;\n    base_t = _855;\n    vec4 _321 = (_855 * fa_mesh_fs_params[2]) * i.vertex_color;\n    vec3 _810 = i.world_normal;\n    if (fa_mesh_fs_params[6].z > 0.5)\n    {\n        float param_4 = fa_mesh_fs_params[6].w;\n        float param_5 = 16.0;\n        vec3 param_6 = texture(fa_normal_tex_fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        vec3 _354 = fa_tex_fix(param_6, param_7);\n        vec3 _358 = (_354 * 2.0) - vec3(1.0);\n        vec2 _363 = _358.xy * fa_mesh_fs_params[6].x;\n        vec3 _863 = _358;\n        _863.x = _363.x;\n        _863.y = _363.y;\n        SurfaceInput param_8 = i;\n        vec3 param_9 = _863;\n        _810 = fa_tangent_normal(param_8, param_9);\n    }\n    vec4 mrt = texture(fa_mr_tex_fa_smp, i.uv);\n    float param_10 = fa_mesh_fs_params[6].w;\n    float param_11 = 64.0;\n    vec3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    vec3 _392 = fa_tex_fix(param_12, param_13);\n    vec4 _866 = mrt;\n    _866.x = _392.x;\n    _866.y = _392.y;\n    _866.z = _392.z;\n    mrt = _866;\n    vec4 _422 = texture(fa_occlusion_tex_fa_smp, i.uv);\n    float param_14 = fa_mesh_fs_params[6].w;\n    float param_15 = 256.0;\n    vec3 param_16 = _422.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    vec3 _434 = fa_tex_fix(param_16, param_17);\n    float param_18 = fa_mesh_fs_params[6].w;\n    float param_19 = 4.0;\n    vec3 param_20 = texture(fa_emissive_tex_fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    vec3 _464 = fa_tex_fix(param_20, param_21);\n    float _815 = fa_mesh_fs_params[20].x;\n    float _816 = fa_mesh_fs_params[20].y;\n    float _819 = fa_mesh_fs_params[20].z;\n    float _818 = fa_mesh_fs_params[21].w;\n    float _821 = fa_mesh_fs_params[22].x;\n    if (fa_mesh_fs_params[22].z > 0.5)\n    {\n        if (mod(fa_mesh_fs_params[22].z, 2.0) > 0.5)\n        {\n            _815 *= _434.y;\n            _816 *= _434.z;\n            _818 *= _422.w;\n        }\n        if (fa_mesh_fs_params[22].z > 1.5)\n        {\n            _819 *= mrt.x;\n            _821 *= mrt.w;\n        }\n    }\n    return Surface(_321.xyz, _321.w, _810, clamp(fa_mesh_fs_params[5].x * _392.z, 0.0, 1.0), clamp(fa_mesh_fs_params[5].y * _392.y, 0.0500000007450580596923828125, 1.0), 1.0 + (fa_mesh_fs_params[6].y * (_434.x - 1.0)), fa_mesh_fs_params[3].xyz + (fa_mesh_fs_params[4].xyz * _464), _815, _816, fa_mesh_fs_params[21].xyz, _818, _819, fa_mesh_fs_params[20].w, _821, fa_mesh_fs_params[22].y, fa_mesh_fs_params[23].xyz, fa_mesh_fs_params[30].x, fa_mesh_fs_params[30].y, fa_mesh_fs_params[31].xyz, fa_mesh_fs_params[30].z);\n}\n\nvoid surface(SurfaceInput i, inout Surface s)\n{\n    s.emission += ((tint.xyz * tint.w) * fa_material[0].x);\n}\n\nvoid fa_lod_dither()\n{\n    if (fa_mesh_fs_params[52].w != 0.0)\n    {\n        float _157 = fract(52.98291778564453125 * fract(dot(gl_FragCoord.xy, vec2(0.067110560834407806396484375, 0.005837149918079376220703125))));\n        bool _160;\n        if (fa_mesh_fs_params[52].w > 0.0)\n        {\n            _160 = _157 >= fa_mesh_fs_params[52].w;\n        }\n        else\n        {\n            _160 = _157 < (-fa_mesh_fs_params[52].w);\n        }\n        if (_160)\n        {\n            discard;\n        }\n    }\n}\n\nvoid main()\n{\n    fa_inst_load();\n    vec3 _705 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _705 = -_705;\n    }\n    vec3 _616 = normalize(fa_mesh_fs_params[0].xyz - fa_world_pos);\n    SurfaceInput param = SurfaceInput(fa_world_pos, _705, fa_world_tangent, fa_uv, fa_vertex_color, _616, gl_FrontFacing);\n    Surface _621 = fa_standard_surface(param);\n    vec3 _729 = _621.normal;\n    SurfaceInput param_1 = SurfaceInput(fa_world_pos, _705, fa_world_tangent, fa_uv, fa_vertex_color, _616, gl_FrontFacing);\n    Surface param_2 = _621;\n    surface(param_1, param_2);\n    _729 = param_2.normal;\n    fa_lod_dither();\n    vec3 _632 = normalize(_729);\n    vec3 _647 = normalize(vec3(dot(fa_pre_r0, _632), dot(fa_pre_r1, _632), dot(fa_pre_r2, _632)));\n    float _659 = _647.z;\n    vec2 e = _647.xy / vec2((abs(_647.x) + abs(_647.y)) + abs(_659));\n    if (_659 < 0.0)\n    {\n        e = (vec2(1.0) - abs(e.yx)) * vec2((e.x >= 0.0) ? 1.0 : (-1.0), (e.y >= 0.0) ? 1.0 : (-1.0));\n    }\n    fa_frag_color = vec4(min(fa_pre_depth, 60000.0), e, 1.0);\n}\n\n",
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
            "inst_name": "_135",
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
            "slot": 5,
            "stage": "fragment",
            "size": 16,
            "struct_name": "fa_material",
            "inst_name": "_189",
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
      "fs": "#version 430\n\nstruct SurfaceInput\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 vertex_color;\n    vec3 view_dir;\n    bool front_facing;\n};\n\nstruct Surface\n{\n    vec3 albedo;\n    float alpha;\n    vec3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    vec3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    vec3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    vec3 specular_color;\n    float transmission;\n    float thickness;\n    vec3 attenuation_color;\n    float attenuation_distance;\n};\n\nuniform vec4 fa_mesh_fs_params[53];\nuniform vec4 fa_material[1];\nlayout(binding = 0) uniform sampler2D fa_tex_fa_smp;\nlayout(binding = 1) uniform sampler2D fa_normal_tex_fa_smp;\nlayout(binding = 2) uniform sampler2D fa_mr_tex_fa_smp;\nlayout(binding = 3) uniform sampler2D fa_occlusion_tex_fa_smp;\nlayout(binding = 4) uniform sampler2D fa_emissive_tex_fa_smp;\n\nlayout(location = 0) flat in vec4 fa_inst_v0;\nlayout(location = 1) flat in vec4 fa_inst_v1;\nlayout(location = 2) in vec3 fa_world_pos;\nlayout(location = 3) in vec3 fa_world_normal;\nlayout(location = 4) in vec4 fa_world_tangent;\nlayout(location = 5) in vec2 fa_uv;\nlayout(location = 6) in vec4 fa_vertex_color;\nlayout(location = 8) in vec3 fa_pre_r0;\nlayout(location = 9) in vec3 fa_pre_r1;\nlayout(location = 10) in vec3 fa_pre_r2;\nlayout(location = 0) out vec4 fa_frag_color;\nlayout(location = 7) in float fa_pre_depth;\nfloat raise;\nvec4 tint;\n\nvoid fa_instance_unpack(vec4 fa_d0, vec4 fa_d1, vec4 fa_d2)\n{\n    raise = fa_d0.x;\n    tint = fa_d1;\n}\n\nvoid fa_inst_load()\n{\n    vec4 param = fa_inst_v0;\n    vec4 param_1 = fa_inst_v1;\n    vec4 param_2 = vec4(0.0);\n    fa_instance_unpack(param, param_1, param_2);\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nvec3 fa_linear_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_tex_fix(inout vec3 c, float mode)\n{\n    if (mode > 1.5)\n    {\n        vec3 param = c;\n        vec3 _256 = fa_linear_to_srgb(param);\n        c = _256;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            vec3 param_1 = c;\n            vec3 _265 = fa_srgb_to_linear(param_1);\n            c = _265;\n        }\n    }\n    return c;\n}\n\nvec3 fa_tangent_normal(SurfaceInput i, vec3 m)\n{\n    vec3 _65;\n    if (i.front_facing)\n    {\n        _65 = i.world_normal;\n    }\n    else\n    {\n        _65 = -i.world_normal;\n    }\n    vec3 _89 = normalize(i.world_tangent.xyz - (_65 * dot(_65, i.world_tangent.xyz)));\n    vec3 _117 = normalize(((_89 * m.x) + ((cross(_65, _89) * i.world_tangent.w) * m.y)) + (_65 * m.z));\n    vec3 _120;\n    if (i.front_facing)\n    {\n        _120 = _117;\n    }\n    else\n    {\n        _120 = -_117;\n    }\n    return _120;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    vec4 base_t = texture(fa_tex_fa_smp, i.uv);\n    float param = fa_mesh_fs_params[6].w;\n    float param_1 = 1.0;\n    vec3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    vec3 _305 = fa_tex_fix(param_2, param_3);\n    vec4 _855 = base_t;\n    _855.x = _305.x;\n    _855.y = _305.y;\n    _855.z = _305.z;\n    base_t = _855;\n    vec4 _321 = (_855 * fa_mesh_fs_params[2]) * i.vertex_color;\n    vec3 _810 = i.world_normal;\n    if (fa_mesh_fs_params[6].z > 0.5)\n    {\n        float param_4 = fa_mesh_fs_params[6].w;\n        float param_5 = 16.0;\n        vec3 param_6 = texture(fa_normal_tex_fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        vec3 _354 = fa_tex_fix(param_6, param_7);\n        vec3 _358 = (_354 * 2.0) - vec3(1.0);\n        vec2 _363 = _358.xy * fa_mesh_fs_params[6].x;\n        vec3 _863 = _358;\n        _863.x = _363.x;\n        _863.y = _363.y;\n        SurfaceInput param_8 = i;\n        vec3 param_9 = _863;\n        _810 = fa_tangent_normal(param_8, param_9);\n    }\n    vec4 mrt = texture(fa_mr_tex_fa_smp, i.uv);\n    float param_10 = fa_mesh_fs_params[6].w;\n    float param_11 = 64.0;\n    vec3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    vec3 _392 = fa_tex_fix(param_12, param_13);\n    vec4 _866 = mrt;\n    _866.x = _392.x;\n    _866.y = _392.y;\n    _866.z = _392.z;\n    mrt = _866;\n    vec4 _422 = texture(fa_occlusion_tex_fa_smp, i.uv);\n    float param_14 = fa_mesh_fs_params[6].w;\n    float param_15 = 256.0;\n    vec3 param_16 = _422.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    vec3 _434 = fa_tex_fix(param_16, param_17);\n    float param_18 = fa_mesh_fs_params[6].w;\n    float param_19 = 4.0;\n    vec3 param_20 = texture(fa_emissive_tex_fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    vec3 _464 = fa_tex_fix(param_20, param_21);\n    float _815 = fa_mesh_fs_params[20].x;\n    float _816 = fa_mesh_fs_params[20].y;\n    float _819 = fa_mesh_fs_params[20].z;\n    float _818 = fa_mesh_fs_params[21].w;\n    float _821 = fa_mesh_fs_params[22].x;\n    if (fa_mesh_fs_params[22].z > 0.5)\n    {\n        if (mod(fa_mesh_fs_params[22].z, 2.0) > 0.5)\n        {\n            _815 *= _434.y;\n            _816 *= _434.z;\n            _818 *= _422.w;\n        }\n        if (fa_mesh_fs_params[22].z > 1.5)\n        {\n            _819 *= mrt.x;\n            _821 *= mrt.w;\n        }\n    }\n    return Surface(_321.xyz, _321.w, _810, clamp(fa_mesh_fs_params[5].x * _392.z, 0.0, 1.0), clamp(fa_mesh_fs_params[5].y * _392.y, 0.0500000007450580596923828125, 1.0), 1.0 + (fa_mesh_fs_params[6].y * (_434.x - 1.0)), fa_mesh_fs_params[3].xyz + (fa_mesh_fs_params[4].xyz * _464), _815, _816, fa_mesh_fs_params[21].xyz, _818, _819, fa_mesh_fs_params[20].w, _821, fa_mesh_fs_params[22].y, fa_mesh_fs_params[23].xyz, fa_mesh_fs_params[30].x, fa_mesh_fs_params[30].y, fa_mesh_fs_params[31].xyz, fa_mesh_fs_params[30].z);\n}\n\nvoid surface(SurfaceInput i, inout Surface s)\n{\n    s.emission += ((tint.xyz * tint.w) * fa_material[0].x);\n}\n\nvoid fa_lod_dither()\n{\n    if (fa_mesh_fs_params[52].w != 0.0)\n    {\n        float _157 = fract(52.98291778564453125 * fract(dot(gl_FragCoord.xy, vec2(0.067110560834407806396484375, 0.005837149918079376220703125))));\n        bool _160;\n        if (fa_mesh_fs_params[52].w > 0.0)\n        {\n            _160 = _157 >= fa_mesh_fs_params[52].w;\n        }\n        else\n        {\n            _160 = _157 < (-fa_mesh_fs_params[52].w);\n        }\n        if (_160)\n        {\n            discard;\n        }\n    }\n}\n\nvoid main()\n{\n    fa_inst_load();\n    vec3 _705 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _705 = -_705;\n    }\n    vec3 _616 = normalize(fa_mesh_fs_params[0].xyz - fa_world_pos);\n    SurfaceInput param = SurfaceInput(fa_world_pos, _705, fa_world_tangent, fa_uv, fa_vertex_color, _616, gl_FrontFacing);\n    Surface _621 = fa_standard_surface(param);\n    vec3 _729 = _621.normal;\n    SurfaceInput param_1 = SurfaceInput(fa_world_pos, _705, fa_world_tangent, fa_uv, fa_vertex_color, _616, gl_FrontFacing);\n    Surface param_2 = _621;\n    surface(param_1, param_2);\n    _729 = param_2.normal;\n    fa_lod_dither();\n    vec3 _632 = normalize(_729);\n    vec3 _647 = normalize(vec3(dot(fa_pre_r0, _632), dot(fa_pre_r1, _632), dot(fa_pre_r2, _632)));\n    float _659 = _647.z;\n    vec2 e = _647.xy / vec2((abs(_647.x) + abs(_647.y)) + abs(_659));\n    if (_659 < 0.0)\n    {\n        e = (vec2(1.0) - abs(e.yx)) * vec2((e.x >= 0.0) ? 1.0 : (-1.0), (e.y >= 0.0) ? 1.0 : (-1.0));\n    }\n    fa_frag_color = vec4(min(fa_pre_depth, 60000.0), e, 1.0);\n}\n\n",
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
            "inst_name": "_135",
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
            "slot": 5,
            "stage": "fragment",
            "size": 16,
            "struct_name": "fa_material",
            "inst_name": "_189",
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
