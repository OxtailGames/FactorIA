{
  "format": "factoria.shader/1",
  "engine": "0.32.0",
  "template": "63c8ed9ef72f0fba56beb38b3018a9ae9876604a67ae71ca005757f89f9b9e64",
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
      "fs": "#version 430\n\nstruct SurfaceInput\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 vertex_color;\n    vec3 view_dir;\n    bool front_facing;\n};\n\nstruct LightSample\n{\n    vec3 direction;\n    vec3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct Surface\n{\n    vec3 albedo;\n    float alpha;\n    vec3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    vec3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    vec3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    vec3 specular_color;\n};\n\nstruct FaLayers\n{\n    bool on;\n    float f90;\n    float keep;\n    float base_scale;\n    float coat;\n    float coat_rough;\n    float coat_alpha;\n    float coat_a2;\n    vec3 nc;\n    float coat_ndv;\n    bool sheen_on;\n    vec3 sheen;\n    float sheen_rough;\n    float sheen_alpha;\n    float sheen_scale;\n    float sheen_e;\n    float aniso;\n    vec3 t;\n    vec3 b;\n    float at;\n    float ab;\n};\n\nconst float _3492[63] = float[](1.0, 1.0, 1.0, 0.4790000021457672119140625, 0.11699999868869781494140625, 0.01200000010430812835693359375, 0.0, 0.0, 0.0, 1.0, 1.0, 1.0, 0.578000009059906005859375, 0.19300000369548797607421875, 0.0350000001490116119384765625, 0.0030000000260770320892333984375, 0.0, 0.0, 1.0, 1.0, 1.0, 0.6740000247955322265625, 0.3459999859333038330078125, 0.1319999992847442626953125, 0.032999999821186065673828125, 0.0040000001899898052215576171875, 0.0, 0.971000015735626220703125, 0.954999983310699462890625, 0.828999996185302734375, 0.63999998569488525390625, 0.42599999904632568359375, 0.24500000476837158203125, 0.115000002086162567138671875, 0.037000000476837158203125, 0.0030000000260770320892333984375, 0.7469999790191650390625, 0.737999975681304931640625, 0.670000016689300537109375, 0.563000023365020751953125, 0.4309999942779541015625, 0.3039999902248382568359375, 0.1940000057220458984375, 0.1019999980926513671875, 0.0309999994933605194091796875, 0.614000022411346435546875, 0.609000027179718017578125, 0.566999971866607666015625, 0.499000012874603271484375, 0.412000000476837158203125, 0.32400000095367431640625, 0.240999996662139892578125, 0.162000000476837158203125, 0.087999999523162841796875, 0.538999974727630615234375, 0.535000026226043701171875, 0.505999982357025146484375, 0.4569999873638153076171875, 0.393999993801116943359375, 0.328999996185302734375, 0.2660000026226043701171875, 0.203999996185302734375, 0.14200000464916229248046875);\n\nuniform vec4 fa_mesh_fs_params[24];\nuniform vec4 fa_shadows[30];\nuniform vec4 fa_material[1];\nlayout(binding = 0) uniform sampler2D fa_light_tex_fa_shadow_smp;\nlayout(binding = 1) uniform sampler2D fa_tex_fa_smp;\nlayout(binding = 2) uniform sampler2D fa_normal_tex_fa_smp;\nlayout(binding = 3) uniform sampler2D fa_mr_tex_fa_smp;\nlayout(binding = 4) uniform sampler2D fa_occlusion_tex_fa_smp;\nlayout(binding = 5) uniform sampler2D fa_emissive_tex_fa_smp;\nlayout(binding = 6) uniform sampler2D fa_decal_tex_fa_env_smp;\nlayout(binding = 7) uniform sampler2D fa_lightmap_fa_env_smp;\nlayout(binding = 8) uniform samplerCube fa_irr_tex_fa_env_smp;\nlayout(binding = 9) uniform sampler2D fa_light_atlas_fa_env_smp;\nlayout(binding = 10) uniform sampler2D fa_shadow_tex_fa_shadow_smp;\nlayout(binding = 11) uniform samplerCube fa_env_tex_fa_env_smp;\n\nlayout(location = 2) in vec3 fa_world_pos;\nlayout(location = 7) in vec3 fa_lm;\nlayout(location = 0) flat in vec4 fa_inst_v0;\nlayout(location = 1) flat in vec4 fa_inst_v1;\nlayout(location = 3) in vec3 fa_world_normal;\nlayout(location = 4) in vec4 fa_world_tangent;\nlayout(location = 5) in vec2 fa_uv;\nlayout(location = 6) in vec4 fa_vertex_color;\nlayout(location = 0) out vec4 fa_frag_color;\nvec3 fa_light_tint;\nbool fa_light_is_area;\nint fa_cl_ndir;\nint fa_cl_slot;\nint fa_cl_local;\nfloat raise;\nvec4 tint;\n\nvoid fa_instance_unpack(vec4 fa_d0, vec4 fa_d1, vec4 fa_d2)\n{\n    raise = fa_d0.x;\n    tint = fa_d1;\n}\n\nvoid fa_inst_load()\n{\n    vec4 param = fa_inst_v0;\n    vec4 param_1 = fa_inst_v1;\n    vec4 param_2 = vec4(0.0);\n    fa_instance_unpack(param, param_1, param_2);\n}\n\nvec4 fa_light_texel(int t)\n{\n    return texelFetch(fa_light_tex_fa_shadow_smp, ivec2(t & 1023, t >> 10), 0);\n}\n\nvec4 fa_cluster_texel(vec3 world_pos)\n{\n    bool _1469 = fa_mesh_fs_params[19].x < 0.0;\n    bool _1476;\n    if (!_1469)\n    {\n        _1476 = fa_mesh_fs_params[19].w < 1.0;\n    }\n    else\n    {\n        _1476 = _1469;\n    }\n    bool _1484;\n    if (!_1476)\n    {\n        _1484 = fa_mesh_fs_params[18].x < 1.0;\n    }\n    else\n    {\n        _1484 = _1476;\n    }\n    bool _1491;\n    if (!_1484)\n    {\n        _1491 = fa_mesh_fs_params[18].y < 1.0;\n    }\n    else\n    {\n        _1491 = _1484;\n    }\n    bool _1498;\n    if (!_1491)\n    {\n        _1498 = fa_mesh_fs_params[19].y < 1.0;\n    }\n    else\n    {\n        _1498 = _1491;\n    }\n    if (_1498)\n    {\n        return vec4(0.0);\n    }\n    vec4 _1508 = vec4(world_pos, 1.0);\n    float _1514 = dot(fa_mesh_fs_params[16], _1508);\n    if (!(_1514 > 9.9999999747524270787835121154785e-07))\n    {\n        return vec4(0.0);\n    }\n    vec2 _1536 = vec2(dot(fa_mesh_fs_params[14], _1508), dot(fa_mesh_fs_params[15], _1508)) / vec2(_1514);\n    int _1540 = int(fa_mesh_fs_params[18].x);\n    int _1544 = int(fa_mesh_fs_params[18].y);\n    int param = (int(fa_mesh_fs_params[19].x) + (((clamp(int(floor(log2(max(dot(fa_mesh_fs_params[17].xyz, world_pos) + fa_mesh_fs_params[17].w, fa_mesh_fs_params[18].w) / fa_mesh_fs_params[18].w) * fa_mesh_fs_params[18].z)), 0, int(fa_mesh_fs_params[19].y) - 1) * _1544) + clamp(int(floor(((_1536.y * 0.5) + 0.5) * fa_mesh_fs_params[18].y)), 0, _1544 - 1)) * _1540)) + clamp(int(floor(((_1536.x * 0.5) + 0.5) * fa_mesh_fs_params[18].x)), 0, _1540 - 1);\n    return fa_light_texel(param);\n}\n\nivec2 fa_cluster_lookup(vec3 world_pos)\n{\n    vec3 param = world_pos;\n    vec4 _1620 = fa_cluster_texel(param);\n    return ivec2(int(_1620.x), int(_1620.y));\n}\n\nvoid fa_cluster_begin(vec3 world_pos)\n{\n    fa_cl_ndir = int(fa_mesh_fs_params[19].z);\n    vec3 param = world_pos;\n    ivec2 _4313 = fa_cluster_lookup(param);\n    fa_cl_slot = _4313.x;\n    fa_cl_local = _4313.y;\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nvec3 fa_linear_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_tex_fix(inout vec3 c, float mode)\n{\n    if (mode > 1.5)\n    {\n        vec3 param = c;\n        vec3 _5421 = fa_linear_to_srgb(param);\n        c = _5421;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            vec3 param_1 = c;\n            vec3 _5429 = fa_srgb_to_linear(param_1);\n            c = _5429;\n        }\n    }\n    return c;\n}\n\nvec3 fa_tangent_normal(SurfaceInput i, vec3 m)\n{\n    vec3 _423;\n    if (i.front_facing)\n    {\n        _423 = i.world_normal;\n    }\n    else\n    {\n        _423 = -i.world_normal;\n    }\n    vec3 _447 = normalize(i.world_tangent.xyz - (_423 * dot(_423, i.world_tangent.xyz)));\n    vec3 _475 = normalize(((_447 * m.x) + ((cross(_423, _447) * i.world_tangent.w) * m.y)) + (_423 * m.z));\n    vec3 _478;\n    if (i.front_facing)\n    {\n        _478 = _475;\n    }\n    else\n    {\n        _478 = -_475;\n    }\n    return _478;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    vec4 base_t = texture(fa_tex_fa_smp, i.uv);\n    float param = fa_mesh_fs_params[6].w;\n    float param_1 = 1.0;\n    vec3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    vec3 _5460 = fa_tex_fix(param_2, param_3);\n    vec4 _6875 = base_t;\n    _6875.x = _5460.x;\n    _6875.y = _5460.y;\n    _6875.z = _5460.z;\n    base_t = _6875;\n    vec4 _5474 = (_6875 * fa_mesh_fs_params[2]) * i.vertex_color;\n    vec3 _6713 = i.world_normal;\n    if (fa_mesh_fs_params[6].z > 0.5)\n    {\n        float param_4 = fa_mesh_fs_params[6].w;\n        float param_5 = 16.0;\n        vec3 param_6 = texture(fa_normal_tex_fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        vec3 _5506 = fa_tex_fix(param_6, param_7);\n        vec3 _5509 = (_5506 * 2.0) - vec3(1.0);\n        vec2 _5514 = _5509.xy * fa_mesh_fs_params[6].x;\n        vec3 _6883 = _5509;\n        _6883.x = _5514.x;\n        _6883.y = _5514.y;\n        SurfaceInput param_8 = i;\n        vec3 param_9 = _6883;\n        _6713 = fa_tangent_normal(param_8, param_9);\n    }\n    vec4 mrt = texture(fa_mr_tex_fa_smp, i.uv);\n    float param_10 = fa_mesh_fs_params[6].w;\n    float param_11 = 64.0;\n    vec3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    vec3 _5542 = fa_tex_fix(param_12, param_13);\n    vec4 _6886 = mrt;\n    _6886.x = _5542.x;\n    _6886.y = _5542.y;\n    _6886.z = _5542.z;\n    mrt = _6886;\n    vec4 _5570 = texture(fa_occlusion_tex_fa_smp, i.uv);\n    float param_14 = fa_mesh_fs_params[6].w;\n    float param_15 = 256.0;\n    vec3 param_16 = _5570.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    vec3 _5581 = fa_tex_fix(param_16, param_17);\n    float param_18 = fa_mesh_fs_params[6].w;\n    float param_19 = 4.0;\n    vec3 param_20 = texture(fa_emissive_tex_fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    vec3 _5611 = fa_tex_fix(param_20, param_21);\n    float _6718 = fa_mesh_fs_params[20].x;\n    float _6719 = fa_mesh_fs_params[20].y;\n    float _6722 = fa_mesh_fs_params[20].z;\n    float _6721 = fa_mesh_fs_params[21].w;\n    float _6724 = fa_mesh_fs_params[22].x;\n    if (fa_mesh_fs_params[22].z > 0.5)\n    {\n        if (mod(fa_mesh_fs_params[22].z, 2.0) > 0.5)\n        {\n            _6718 *= _5581.y;\n            _6719 *= _5581.z;\n            _6721 *= _5570.w;\n        }\n        if (fa_mesh_fs_params[22].z > 1.5)\n        {\n            _6722 *= mrt.x;\n            _6724 *= mrt.w;\n        }\n    }\n    return Surface(_5474.xyz, _5474.w, _6713, clamp(fa_mesh_fs_params[5].x * _5542.z, 0.0, 1.0), clamp(fa_mesh_fs_params[5].y * _5542.y, 0.0500000007450580596923828125, 1.0), 1.0 + (fa_mesh_fs_params[6].y * (_5581.x - 1.0)), fa_mesh_fs_params[3].xyz + (fa_mesh_fs_params[4].xyz * _5611), _6718, _6719, fa_mesh_fs_params[21].xyz, _6721, _6722, fa_mesh_fs_params[20].w, _6724, fa_mesh_fs_params[22].y, fa_mesh_fs_params[23].xyz);\n}\n\nvoid surface(SurfaceInput i, inout Surface s)\n{\n    s.emission += ((tint.xyz * tint.w) * fa_material[0].x);\n}\n\nvec4 fa_decal_tile(vec4 rect, vec2 uv, vec2 atlas, vec2 ddx, vec2 ddy)\n{\n    vec2 _1700 = rect.zw - rect.xy;\n    vec2 _1704 = _1700 * atlas;\n    vec2 _1708 = ddx * _1704;\n    vec2 _1712 = ddy * _1704;\n    return textureLod(fa_decal_tex_fa_env_smp, rect.xy + (clamp(uv, vec2(0.0), vec2(1.0)) * _1700), clamp(0.5 * log2(max(max(dot(_1708, _1708), dot(_1712, _1712)), 9.9999999392252902907785028219223e-09)), 0.0, 4.0));\n}\n\nvec3 fa_dc_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_dc_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvoid fa_apply_decals(vec3 world_pos, vec3 geo_normal, inout vec3 albedo, inout vec3 normal)\n{\n    bool _1745 = fa_mesh_fs_params[10].y < 0.5;\n    bool _1752;\n    if (!_1745)\n    {\n        _1752 = fa_mesh_fs_params[10].w < 0.5;\n    }\n    else\n    {\n        _1752 = _1745;\n    }\n    if (_1752)\n    {\n        return;\n    }\n    vec3 _1758 = dFdx(world_pos);\n    vec3 _1761 = dFdy(world_pos);\n    vec3 param = world_pos;\n    vec4 _1765 = fa_cluster_texel(param);\n    int _1769 = int(_1765.w);\n    if (_1769 < 1)\n    {\n        return;\n    }\n    int _1779 = int(fa_mesh_fs_params[10].y + 0.5);\n    int param_1 = _1779;\n    vec4 _1783 = fa_light_texel(param_1);\n    vec2 _1786 = _1783.yz;\n    int _1790 = int(_1783.w);\n    int param_2 = _1779 + 1;\n    vec4 _1795 = fa_light_texel(param_2);\n    float _1796 = _1795.x;\n    int _1802 = int(fa_mesh_fs_params[10].w + 0.5) - 1;\n    int _1806 = int(_1765.z);\n    vec3 _2071;\n    for (int k = 0; k < _1769; k++)\n    {\n        int _1819 = _1806 + k;\n        int param_3 = _1790 + (_1819 >> 2);\n        int _1836 = (_1779 + 2) + (int(fa_light_texel(param_3)[_1819 & 3]) * 7);\n        int param_4 = _1836 + 6;\n        vec4 _1841 = fa_light_texel(param_4);\n        if (((int(_1841.w + 0.5) >> _1802) & 1) == 0)\n        {\n            continue;\n        }\n        int param_5 = _1836;\n        vec4 _1856 = fa_light_texel(param_5);\n        int param_6 = _1836 + 1;\n        vec4 _1861 = fa_light_texel(param_6);\n        int param_7 = _1836 + 2;\n        vec4 _1866 = fa_light_texel(param_7);\n        vec3 _1869 = _1856.xyz;\n        float _1874 = dot(_1869, world_pos) + _1856.w;\n        vec3 _1876 = _1861.xyz;\n        float _1881 = dot(_1876, world_pos) + _1861.w;\n        vec3 _1883 = _1866.xyz;\n        float _1888 = dot(_1883, world_pos) + _1866.w;\n        bool _1893 = abs(_1874) > 0.5;\n        bool _1901;\n        if (!_1893)\n        {\n            _1901 = abs(_1881) > 0.5;\n        }\n        else\n        {\n            _1901 = _1893;\n        }\n        bool _1909;\n        if (!_1901)\n        {\n            _1909 = abs(_1888) > 0.5;\n        }\n        else\n        {\n            _1909 = _1901;\n        }\n        if (_1909)\n        {\n            continue;\n        }\n        float _1924 = clamp(dot(geo_normal, normalize(_1883)) * _1841.z, 0.0, 1.0);\n        if (_1924 <= 0.0)\n        {\n            continue;\n        }\n        float _1944 = (clamp((0.5 - abs(_1888)) * 10.0, 0.0, 1.0) * _1924) * _1841.x;\n        vec2 _1952 = vec2(_1874 + 0.5, 0.5 - _1881);\n        vec2 _1962 = vec2(dot(_1869, _1758), dot(_1876, _1758));\n        vec2 _1972 = vec2(dot(_1869, _1761), dot(_1876, _1761));\n        int param_8 = _1836 + 5;\n        vec4 _1977 = fa_light_texel(param_8);\n        int param_9 = _1836 + 3;\n        vec4 _1982 = fa_light_texel(param_9);\n        int param_10 = _1836 + 4;\n        vec4 _1987 = fa_light_texel(param_10);\n        float tex_a = 1.0;\n        vec3 col = _1977.xyz;\n        bool _1997 = _1982.z > _1982.x;\n        if (_1997)\n        {\n            vec4 param_11 = _1982;\n            vec2 param_12 = _1952;\n            vec2 param_13 = _1786;\n            vec2 param_14 = _1962;\n            vec2 param_15 = _1972;\n            vec4 tx = fa_decal_tile(param_11, param_12, param_13, param_14, param_15);\n            if ((_1796 > 0.5) && (_1796 < 1.5))\n            {\n                vec3 param_16 = tx.xyz;\n                vec3 _2023 = fa_dc_to_linear(param_16);\n                vec4 _6793 = tx;\n                _6793.x = _2023.x;\n                _6793.y = _2023.y;\n                _6793.z = _2023.z;\n                tx = _6793;\n            }\n            col *= tx.xyz;\n            tex_a = tx.w;\n        }\n        albedo = mix(albedo, col, vec3(clamp((_1944 * tex_a) * _1977.w, 0.0, 1.0)));\n        if (_1987.z > _1987.x)\n        {\n            vec4 param_17 = _1987;\n            vec2 param_18 = _1952;\n            vec2 param_19 = _1786;\n            vec2 param_20 = _1962;\n            vec2 param_21 = _1972;\n            vec4 _2067 = fa_decal_tile(param_17, param_18, param_19, param_20, param_21);\n            if (_1796 > 1.5)\n            {\n                vec3 param_22 = _2067.xyz;\n                vec3 _2077 = fa_dc_to_srgb(param_22);\n                _2071 = _2077;\n            }\n            else\n            {\n                _2071 = _2067.xyz;\n            }\n            vec3 _2086 = (_2071 * 2.0) - vec3(1.0);\n            vec2 _2091 = _2086.xy * _1841.y;\n            vec3 _2113 = (normalize(_1869) * _2091.x) + (normalize(_1876) * _2091.y);\n            vec3 _2116 = normalize(normal);\n            normal = normalize(mix(_2116, normalize((_2116 * max(_2086.z, 0.0500000007450580596923828125)) + (_2113 - (_2116 * dot(_2116, _2113)))), vec3(clamp(_1944 * (_1997 ? tex_a : 1.0), 0.0, 1.0))));\n        }\n    }\n}\n\nfloat fa_sheen_albedo(float ndv, float rough)\n{\n    float _3417 = min(sqrt(max(rough - 0.100000001490116119384765625, 0.0) * 1.111111164093017578125) * 6.0, 5.999000072479248046875);\n    float _3425 = min(sqrt(clamp(ndv, 0.0, 1.0)) * 8.0, 7.999000072479248046875);\n    int _3428 = int(_3417);\n    int _3431 = int(_3425);\n    float _3441 = _3425 - float(_3431);\n    int _3497 = (_3428 * 9) + _3431;\n    int _3517 = ((_3428 + 1) * 9) + _3431;\n    return mix(mix(_3492[_3497], _3492[_3497 + 1], _3441), mix(_3492[_3517], _3492[_3517 + 1], _3441), _3417 - float(_3428));\n}\n\nFaLayers fa_layers_setup(SurfaceInput i, Surface s, vec3 n, vec3 v, float metallic, float roughness, inout vec3 f0)\n{\n    bool _6636 = false;\n    float _6637 = 1.0;\n    float _6638 = 1.0;\n    float _6639 = 1.0;\n    float _6640 = 0.0;\n    float _6641 = 0.0;\n    float _6642 = 0.0;\n    float _6643 = 0.0;\n    float _6645 = 1.0;\n    bool _6646 = false;\n    vec3 _6647 = vec3(0.0);\n    float _6648 = 1.0;\n    float _6649 = 1.0;\n    float _6650 = 1.0;\n    float _6651 = 0.0;\n    float _6652 = 0.0;\n    vec3 _6653 = vec3(1.0, 0.0, 0.0);\n    vec3 _6654 = vec3(0.0, 0.0, 1.0);\n    float _6655 = 1.0;\n    float _6656 = 1.0;\n    float _3568 = clamp(s.specular, 0.0, 1.0);\n    float _3572 = clamp(s.ior, 1.0, 3.0);\n    bool _3577 = (_3568 != 1.0) || (_3572 != 1.5);\n    bool _3586;\n    if (!_3577)\n    {\n        _3586 = any(notEqual(s.specular_color, vec3(1.0)));\n    }\n    else\n    {\n        _3586 = _3577;\n    }\n    if (_3586)\n    {\n        float _3594 = (_3572 - 1.0) / (_3572 + 1.0);\n        f0 = mix(min(vec3(_3594 * _3594) * max(s.specular_color, vec3(0.0)), vec3(1.0)) * _3568, s.albedo, vec3(metallic));\n        _6637 = mix(_3568, 1.0, metallic);\n        _6636 = true;\n    }\n    float _3621 = clamp(s.clearcoat, 0.0, 1.0);\n    if (_3621 > 0.0)\n    {\n        float _3629 = clamp(s.clearcoat_roughness, 0.0500000007450580596923828125, 1.0);\n        _6640 = _3621;\n        _6641 = _3629;\n        float _3636 = _3629 * _3629;\n        _6642 = _3636;\n        _6643 = _3636 * _3636;\n        float _3648 = max(dot(i.world_normal, v), 9.9999997473787516355514526367188e-05);\n        _6645 = _3648;\n        _6638 = 1.0 - (_3621 * (0.039999999105930328369140625 + (0.959999978542327880859375 * pow(clamp(1.0 - _3648, 0.0, 1.0), 5.0))));\n        _6636 = true;\n    }\n    vec3 _3668 = max(s.sheen_color, vec3(0.0));\n    float _3677 = max(_3668.x, max(_3668.y, _3668.z));\n    if (_3677 > 0.0)\n    {\n        float _3685 = clamp(s.sheen_roughness, 0.100000001490116119384765625, 1.0);\n        _6646 = true;\n        _6647 = _3668;\n        _6648 = _3685;\n        _6649 = _3685 * _3685;\n        float param = max(dot(n, v), 9.9999997473787516355514526367188e-05);\n        float param_1 = _3685;\n        float _3702 = fa_sheen_albedo(param, param_1);\n        _6651 = _3702;\n        _6650 = 1.0 - min(_3677 * _3702, 1.0);\n        _6636 = true;\n    }\n    _6639 = _6638 * _6650;\n    float _3721 = clamp(s.anisotropy, -1.0, 1.0);\n    if (_3721 != 0.0)\n    {\n        vec3 _3736 = i.world_tangent.xyz - (n * dot(n, i.world_tangent.xyz));\n        vec3 t = _3736;\n        if (dot(_3736, _3736) < 9.9999999392252902907785028219223e-09)\n        {\n            bvec3 _3748 = bvec3(abs(n.y) < 0.9900000095367431640625);\n            t = cross(vec3(_3748.x ? vec3(0.0, 1.0, 0.0).x : vec3(1.0, 0.0, 0.0).x, _3748.y ? vec3(0.0, 1.0, 0.0).y : vec3(1.0, 0.0, 0.0).y, _3748.z ? vec3(0.0, 1.0, 0.0).z : vec3(1.0, 0.0, 0.0).z), n);\n        }\n        vec3 _3752 = t;\n        vec3 _3753 = normalize(_3752);\n        t = _3753;\n        vec3 _3778 = normalize((_3753 * cos(s.anisotropy_rotation)) + ((cross(n, _3753) * ((i.world_tangent.w < 0.0) ? (-1.0) : 1.0)) * sin(s.anisotropy_rotation)));\n        _6653 = _3778;\n        _6654 = cross(n, _3778);\n        float _3788 = roughness * roughness;\n        float _3794 = mix(_3788, 1.0, _3721 * _3721);\n        bool _3796 = _3721 > 0.0;\n        _6655 = _3796 ? _3794 : _3788;\n        _6656 = _3796 ? _3788 : _3794;\n        _6652 = _3721;\n        _6636 = true;\n    }\n    return FaLayers(_6636, _6637, _6638, _6639, _6640, _6641, _6642, _6643, i.world_normal, _6645, _6646, _6647, _6648, _6649, _6650, _6651, _6652, _6653, _6654, _6655, _6656);\n}\n\nvec3 fa_ambient_light(vec3 n)\n{\n    if (fa_mesh_fs_params[11].w > 0.5)\n    {\n        return textureLod(fa_irr_tex_fa_env_smp, n, 0.0).xyz;\n    }\n    return fa_mesh_fs_params[1].xyz;\n}\n\nvec3 fa_indirect_diffuse(vec3 n)\n{\n    if (fa_lm.z > 0.5)\n    {\n        return textureLod(fa_lightmap_fa_env_smp, fa_lm.xy, 0.0).xyz;\n    }\n    vec3 param = n;\n    return fa_ambient_light(param);\n}\n\nint fa_cluster_index(int slot, int n)\n{\n    int param = (int(fa_mesh_fs_params[19].x) + int(fa_mesh_fs_params[19].w)) + ((slot + n) >> 2);\n    vec4 t = fa_light_texel(param);\n    return int(t[(slot + n) & 3]);\n}\n\nint fa_cl_light(int n)\n{\n    if (n < fa_cl_ndir)\n    {\n        return n;\n    }\n    int param = fa_cl_slot;\n    int param_1 = n - fa_cl_ndir;\n    return fa_cluster_index(param, param_1);\n}\n\nint fa_light_base(int li)\n{\n    return li * ((fa_mesh_fs_params[1].w > 4.5) ? 8 : 4);\n}\n\nbool fa_light_baked(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 3;\n    return fa_light_texel(param_1).w > 0.5;\n}\n\nfloat fa_light_type(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 1;\n    return fa_light_texel(param_1).w;\n}\n\nvec4 fa_atlas_fetch(vec2 texel)\n{\n    return textureLod(fa_light_atlas_fa_env_smp, texel / vec2(textureSize(fa_light_atlas_fa_env_smp, 0)), 0.0);\n}\n\nvec3 fa_cookie_sample(vec2 tile_origin, vec2 uv)\n{\n    vec2 param = (tile_origin + vec2(1.0)) + (clamp(uv, vec2(0.0), vec2(1.0)) * 254.0);\n    return fa_atlas_fetch(param).xyz;\n}\n\nvec3 fa_area_point(vec3 c, vec3 axis, vec3 ru, vec3 uu, float hx, float hy, float shape, vec3 p, vec3 r)\n{\n    bool _728 = dot(r, r) > 0.5;\n    if (shape > 1.5)\n    {\n        vec3 _741 = (c - (ru * hx)) - p;\n        vec3 _747 = ru * (2.0 * hx);\n        float _753 = max(dot(_747, _747), 9.9999999392252902907785028219223e-09);\n        float _757 = dot(_741, _747);\n        float t = clamp((-_757) / _753, 0.0, 1.0);\n        if (_728)\n        {\n            float _772 = dot(r, _747);\n            float _778 = _753 - (_772 * _772);\n            if (abs(_778) > (9.9999997473787516355514526367188e-06 * _753))\n            {\n                t = clamp(((dot(r, _741) * _772) - _757) / _778, 0.0, 1.0);\n            }\n        }\n        return (p + _741) + (_747 * t);\n    }\n    vec3 q = p;\n    float _810 = dot(r, axis);\n    bool _818;\n    if (_728)\n    {\n        _818 = abs(_810) > 9.9999997473787516355514526367188e-05;\n    }\n    else\n    {\n        _818 = _728;\n    }\n    if (_818)\n    {\n        float _828 = dot(c - p, axis) / _810;\n        if (_828 > 0.0)\n        {\n            q = p + (r * _828);\n        }\n    }\n    vec3 _841 = q - c;\n    vec2 xy = vec2(dot(_841, ru), dot(_841, uu));\n    if (shape > 0.5)\n    {\n        float _856 = length(xy);\n        if (_856 > hx)\n        {\n            xy *= (hx / _856);\n        }\n    }\n    else\n    {\n        xy = clamp(xy, vec2(-hx, -hy), vec2(hx, hy));\n    }\n    return (c + (ru * xy.x)) + (uu * xy.y);\n}\n\nint fa_cube_face(vec3 d)\n{\n    vec3 _649 = abs(d);\n    float _651 = _649.x;\n    float _653 = _649.y;\n    bool _654 = _651 >= _653;\n    bool _662;\n    if (_654)\n    {\n        _662 = _651 >= _649.z;\n    }\n    else\n    {\n        _662 = _654;\n    }\n    int _663;\n    if (_662)\n    {\n        _663 = (d.x > 0.0) ? 0 : 1;\n    }\n    else\n    {\n        int _676;\n        if (_653 >= _649.z)\n        {\n            _676 = (d.y > 0.0) ? 2 : 3;\n        }\n        else\n        {\n            _676 = (d.z > 0.0) ? 4 : 5;\n        }\n        _663 = _676;\n    }\n    return _663;\n}\n\nvoid fa_cube_face_basis(int f, out vec3 fwd, out vec3 up)\n{\n    if (f == 0)\n    {\n        fwd = vec3(1.0, 0.0, 0.0);\n        up = vec3(0.0, 1.0, 0.0);\n    }\n    else\n    {\n        if (f == 1)\n        {\n            fwd = vec3(-1.0, 0.0, 0.0);\n            up = vec3(0.0, 1.0, 0.0);\n        }\n        else\n        {\n            if (f == 2)\n            {\n                fwd = vec3(0.0, 1.0, 0.0);\n                up = vec3(0.0, 0.0, 1.0);\n            }\n            else\n            {\n                if (f == 3)\n                {\n                    fwd = vec3(0.0, -1.0, 0.0);\n                    up = vec3(0.0, 0.0, -1.0);\n                }\n                else\n                {\n                    if (f == 4)\n                    {\n                        fwd = vec3(0.0, 0.0, 1.0);\n                        up = vec3(0.0, 1.0, 0.0);\n                    }\n                    else\n                    {\n                        fwd = vec3(0.0, 0.0, -1.0);\n                        up = vec3(0.0, 1.0, 0.0);\n                    }\n                }\n            }\n        }\n    }\n}\n\nfloat fa_ies_sample(vec2 tile_origin, vec3 d, vec3 axis, vec3 right, vec3 up)\n{\n    float _602 = dot(d, right);\n    float _606 = dot(d, up);\n    float _617;\n    if (((_602 * _602) + (_606 * _606)) > 1.0000000133514319600180897396058e-10)\n    {\n        _617 = atan(_606, _602) * 0.15915493667125701904296875;\n    }\n    else\n    {\n        _617 = 0.0;\n    }\n    vec2 param = tile_origin + vec2(1.0 + ((_617 - floor(_617)) * 64.0), 1.0 + (acos(clamp(dot(d, axis), -1.0, 1.0)) * 10.18591594696044921875));\n    return fa_atlas_fetch(param).x;\n}\n\nLightSample fa_light_sample_n(int li, vec3 world_pos, vec3 n)\n{\n    int param = li;\n    int _894 = fa_light_base(param);\n    bool _898 = fa_mesh_fs_params[1].w > 4.5;\n    int param_1 = _894;\n    vec4 _902 = fa_light_texel(param_1);\n    int param_2 = _894 + 1;\n    vec4 _907 = fa_light_texel(param_2);\n    float _910 = _907.w;\n    float atten = 1.0;\n    float dist = 0.0;\n    fa_light_tint = vec3(1.0);\n    bool _922 = _898 && (_910 > 2.5);\n    fa_light_is_area = _922;\n    bool _924 = _910 < 0.5;\n    vec3 l;\n    if (_924)\n    {\n        l = normalize(_902.xyz);\n        if (_898)\n        {\n            int param_3 = _894 + 6;\n            vec4 _938 = fa_light_texel(param_3);\n            if (_938.z > 0.5)\n            {\n                int param_4 = _894 + 4;\n                vec4 _948 = fa_light_texel(param_4);\n                int param_5 = _894 + 5;\n                vec4 _953 = fa_light_texel(param_5);\n                vec2 param_6 = _938.xy;\n                vec2 param_7 = fract(vec2(dot(world_pos, _948.xyz) * _948.w, (-dot(world_pos, _953.xyz)) * _953.w) + vec2(0.5));\n                fa_light_tint = fa_cookie_sample(param_6, param_7);\n            }\n        }\n    }\n    else\n    {\n        vec3 _983 = _902.xyz;\n        vec3 _985 = _983 - world_pos;\n        vec3 to_light = _985;\n        float _988 = length(_985);\n        float reach = _988;\n        bool front = true;\n        if (_922)\n        {\n            int param_8 = _894 + 7;\n            reach = max(_988 - fa_light_texel(param_8).w, 0.0);\n            int param_9 = _894 + 4;\n            vec4 _1012 = fa_light_texel(param_9);\n            int param_10 = _894 + 5;\n            vec4 _1017 = fa_light_texel(param_10);\n            int param_11 = _894 + 6;\n            vec4 _1022 = fa_light_texel(param_11);\n            float _1023 = _1022.w;\n            int param_12 = _894 + 2;\n            vec3 _1030 = normalize(fa_light_texel(param_12).xyz);\n            bool _1032 = _1023 > 1.5;\n            bool _1040;\n            if (!_1032)\n            {\n                _1040 = dot(_1030, to_light) < 0.0;\n            }\n            else\n            {\n                _1040 = _1032;\n            }\n            front = _1040;\n            vec3 r = vec3(0.0);\n            if (dot(n, n) > 0.5)\n            {\n                r = reflect(-normalize(fa_mesh_fs_params[0].xyz - world_pos), normalize(n));\n            }\n            vec3 param_13 = _983;\n            vec3 param_14 = _1030;\n            vec3 param_15 = _1012.xyz;\n            vec3 param_16 = _1017.xyz;\n            float param_17 = _1012.w;\n            float param_18 = _1017.w;\n            float param_19 = _1023;\n            vec3 param_20 = world_pos;\n            vec3 param_21 = r;\n            to_light = fa_area_point(param_13, param_14, param_15, param_16, param_17, param_18, param_19, param_20, param_21) - world_pos;\n        }\n        float _1087 = length(to_light);\n        dist = _1087;\n        l = to_light / vec3(max(_1087, 9.9999997473787516355514526367188e-05));\n        float _1101 = reach / max(_902.w, 0.001000000047497451305389404296875);\n        float _1107 = clamp(1.0 - (_1101 * _1101), 0.0, 1.0);\n        float _1109;\n        if (front)\n        {\n            _1109 = _1107 * _1107;\n        }\n        else\n        {\n            _1109 = 0.0;\n        }\n        atten = _1109;\n        bool _1120 = _910 < 2.5;\n        if ((_910 > 1.5) && _1120)\n        {\n            int param_22 = _894 + 2;\n            vec4 _1128 = fa_light_texel(param_22);\n            float _1138 = _1128.w;\n            int param_23 = _894 + 3;\n            vec4 _1143 = fa_light_texel(param_23);\n            float _1144 = _1143.x;\n            float cos_inner = _1144;\n            if (_1144 > 1.5)\n            {\n                cos_inner = mix(_1138, 1.0, 0.25);\n            }\n            atten *= smoothstep(_1138, cos_inner, dot(-l, normalize(_1128.xyz)));\n        }\n        if (_898 && (_910 < 1.5))\n        {\n            int param_24 = _894 + 6;\n            vec4 _1168 = fa_light_texel(param_24);\n            if (_1168.z > 0.5)\n            {\n                vec3 _1176 = -to_light;\n                int param_25 = _894 + 4;\n                int param_26 = _894 + 5;\n                vec3 _1190 = fa_light_texel(param_25).xyz;\n                vec3 _1194 = fa_light_texel(param_26).xyz;\n                vec3 _1203 = vec3(dot(_1176, _1190), dot(_1176, _1194), dot(_1176, cross(_1190, _1194)));\n                vec3 param_27 = _1203;\n                int _1207 = fa_cube_face(param_27);\n                int param_28 = _1207;\n                vec3 param_29;\n                vec3 param_30;\n                fa_cube_face_basis(param_28, param_29, param_30);\n                vec2 _1234 = vec2(dot(_1203, cross(param_29, param_30)), dot(_1203, param_30)) / vec2(max(dot(_1203, param_29), 9.9999997473787516355514526367188e-05));\n                int _1238 = _1207 / 3;\n                vec2 param_31 = _1168.xy + (vec2(float(_1207 - (_1238 * 3)), float(_1238)) * 256.0);\n                vec2 param_32 = vec2(0.5 + (0.5 * _1234.x), 0.5 - (0.5 * _1234.y));\n                fa_light_tint = fa_cookie_sample(param_31, param_32);\n            }\n            int param_33 = _894 + 7;\n            vec4 _1268 = fa_light_texel(param_33);\n            if (_1268.z > 0.5)\n            {\n                int param_34 = _894 + 2;\n                int param_35 = _894 + 4;\n                int param_36 = _894 + 5;\n                vec2 param_37 = _1268.xy;\n                vec3 param_38 = -l;\n                vec3 param_39 = normalize(fa_light_texel(param_34).xyz);\n                vec3 param_40 = fa_light_texel(param_35).xyz;\n                vec3 param_41 = fa_light_texel(param_36).xyz;\n                atten *= fa_ies_sample(param_37, param_38, param_39, param_40, param_41);\n            }\n        }\n        else\n        {\n            if (_898 && _1120)\n            {\n                int param_42 = _894 + 6;\n                vec4 _1315 = fa_light_texel(param_42);\n                int param_43 = _894 + 7;\n                vec4 _1320 = fa_light_texel(param_43);\n                bool _1323 = _1315.z > 0.5;\n                bool _1330;\n                if (!_1323)\n                {\n                    _1330 = _1320.z > 0.5;\n                }\n                else\n                {\n                    _1330 = _1323;\n                }\n                if (_1330)\n                {\n                    int param_44 = _894 + 2;\n                    vec4 _1337 = fa_light_texel(param_44);\n                    vec3 _1341 = normalize(_1337.xyz);\n                    int param_45 = _894 + 4;\n                    vec4 _1346 = fa_light_texel(param_45);\n                    int param_46 = _894 + 5;\n                    vec4 _1351 = fa_light_texel(param_46);\n                    if (_1323)\n                    {\n                        vec3 _1359 = -to_light;\n                        float _1366 = _1337.w;\n                        float _1382 = 0.5 / max(dot(_1359, _1341) * (sqrt(max(1.0 - (_1366 * _1366), 0.0)) / max(_1366, 0.001000000047497451305389404296875)), 9.9999997473787516355514526367188e-05);\n                        vec2 param_47 = _1315.xy;\n                        vec2 param_48 = vec2(0.5 + (dot(_1359, _1346.xyz) * _1382), 0.5 - (dot(_1359, _1351.xyz) * _1382));\n                        fa_light_tint = fa_cookie_sample(param_47, param_48);\n                    }\n                    if (_1320.z > 0.5)\n                    {\n                        vec2 param_49 = _1320.xy;\n                        vec3 param_50 = -l;\n                        vec3 param_51 = _1341;\n                        vec3 param_52 = _1346.xyz;\n                        vec3 param_53 = _1351.xyz;\n                        atten *= fa_ies_sample(param_49, param_50, param_51, param_52, param_53);\n                    }\n                }\n            }\n        }\n    }\n    vec3 _6624 = _907.xyz * atten;\n    if (_898)\n    {\n        _6624 *= fa_light_tint;\n    }\n    int _1451;\n    if (_924)\n    {\n        _1451 = 0;\n    }\n    else\n    {\n        _1451 = ((_910 > 1.5) && (_910 < 2.5)) ? 2 : 1;\n    }\n    return LightSample(l, _6624, atten, 1.0, dist, _1451);\n}\n\nfloat fa_shadow_split_at(int i)\n{\n    float _2188;\n    if (i == 0)\n    {\n        _2188 = fa_shadows[24].x;\n    }\n    else\n    {\n        float _2204;\n        if (i == 1)\n        {\n            _2204 = fa_shadows[24].y;\n        }\n        else\n        {\n            float _2212;\n            if (i == 2)\n            {\n                _2212 = fa_shadows[24].z;\n            }\n            else\n            {\n                _2212 = fa_shadows[24].w;\n            }\n            _2204 = _2212;\n        }\n        _2188 = _2204;\n    }\n    return _2188;\n}\n\nfloat fa_shadow_depth(inout vec2 uv, vec4 rect)\n{\n    uv = clamp(uv, rect.xy, rect.zw);\n    return textureLod(fa_shadow_tex_fa_shadow_smp, uv, 0.0).x;\n}\n\nfloat fa_shadow_fetch(vec2 uv, vec4 rect, vec3 conv)\n{\n    vec2 param = uv;\n    vec4 param_1 = rect;\n    float _2245 = fa_shadow_depth(param, param_1);\n    float _2249;\n    if (conv.x < 0.5)\n    {\n        _2249 = _2245;\n    }\n    else\n    {\n        _2249 = (conv.y * conv.z) / (conv.z - (_2245 * (conv.z - conv.y)));\n    }\n    return _2249;\n}\n\nfloat fa_shadow_noise()\n{\n    return fract(52.98291778564453125 * fract(dot(gl_FragCoord.xy, vec2(0.067110560834407806396484375, 0.005837149918079376220703125))));\n}\n\nvec2 fa_shadow_vogel(int k, int n, float phi)\n{\n    float _2176 = (float(k) * 2.3999631404876708984375) + phi;\n    return vec2(cos(_2176), sin(_2176)) * sqrt((float(k) + 0.5) / float(n));\n}\n\nfloat fa_shadow_filter(vec2 uv, vec4 rect, float zr, float texel_m, float unit, float reach, float plane, vec3 conv, int mode, float k)\n{\n    if (mode == 1)\n    {\n        vec2 param = uv;\n        vec4 param_1 = rect;\n        vec3 param_2 = conv;\n        return float(zr <= fa_shadow_fetch(param, param_1, param_2));\n    }\n    float _2295 = fa_shadow_noise() * 6.283185482025146484375;\n    float radius = 1.5;\n    if (mode == 2)\n    {\n        float _2304;\n        if (k < 0.0)\n        {\n            _2304 = (-k) / max(zr, 0.100000001490116119384765625);\n        }\n        else\n        {\n            _2304 = k;\n        }\n        float _2324 = clamp((_2304 * reach) / texel_m, 3.0, 12.0);\n        float sum = 0.0;\n        float cnt = 0.0;\n        for (int i = 0; i < 16; i++)\n        {\n            int param_3 = i;\n            int param_4 = 16;\n            float param_5 = _2295;\n            vec2 _2343 = fa_shadow_vogel(param_3, param_4, param_5) * _2324;\n            vec2 param_6 = uv + (_2343 * fa_shadows[26].zw);\n            vec4 param_7 = rect;\n            vec3 param_8 = conv;\n            float _2355 = fa_shadow_fetch(param_6, param_7, param_8);\n            if (_2355 < (zr - (length(_2343) * plane)))\n            {\n                sum += _2355;\n                cnt += 1.0;\n            }\n        }\n        if (cnt < 0.5)\n        {\n            return 1.0;\n        }\n        float _2381 = sum / cnt;\n        float _2391;\n        if (k < 0.0)\n        {\n            _2391 = (-k) / max(_2381, 0.0500000007450580596923828125);\n        }\n        else\n        {\n            _2391 = k;\n        }\n        radius = clamp(((max(zr - _2381, 0.0) * unit) * _2391) / texel_m, 1.5, 16.0);\n    }\n    float lit = 0.0;\n    int _2413 = (mode == 2) ? 24 : 16;\n    for (int i_1 = 0; i_1 < _2413; i_1++)\n    {\n        int param_9 = i_1;\n        int param_10 = _2413;\n        float param_11 = _2295;\n        vec2 _2432 = fa_shadow_vogel(param_9, param_10, param_11) * radius;\n        vec2 param_12 = uv + (_2432 * fa_shadows[26].zw);\n        vec4 param_13 = rect;\n        vec3 param_14 = conv;\n        lit += float((zr - (length(_2432) * plane)) <= fa_shadow_fetch(param_12, param_13, param_14));\n    }\n    return lit / float(_2413);\n}\n\nfloat fa_shadow_cascade(int ci, vec3 world, vec3 n, vec3 l)\n{\n    float _2474 = max(fa_shadows[ci * 1 + 20].y, 0.001000000047497451305389404296875);\n    float _2479 = clamp(dot(n, l), 0.0, 1.0);\n    float _2485 = sqrt(1.0 - (_2479 * _2479));\n    float _2492 = min(_2485 / max(_2479, 0.20000000298023223876953125), 4.0);\n    float _2497;\n    if (fa_shadows[26].y > 0.0)\n    {\n        _2497 = fa_shadows[26].y;\n    }\n    else\n    {\n        _2497 = 1.5 * fa_shadows[ci * 1 + 20].x;\n    }\n    vec4 _2522 = mat4(fa_shadows[ci * 4 + 0], fa_shadows[ci * 4 + 1], fa_shadows[ci * 4 + 2], fa_shadows[ci * 4 + 3]) * vec4(world + (n * (_2497 * _2485)), 1.0);\n    float _2529 = _2522.x;\n    bool _2532 = _2529 < fa_shadows[ci * 1 + 16].x;\n    bool _2541;\n    if (!_2532)\n    {\n        _2541 = _2529 > fa_shadows[ci * 1 + 16].z;\n    }\n    else\n    {\n        _2541 = _2532;\n    }\n    bool _2550;\n    if (!_2541)\n    {\n        _2550 = _2522.y < fa_shadows[ci * 1 + 16].y;\n    }\n    else\n    {\n        _2550 = _2541;\n    }\n    bool _2559;\n    if (!_2550)\n    {\n        _2559 = _2522.y > fa_shadows[ci * 1 + 16].w;\n    }\n    else\n    {\n        _2559 = _2550;\n    }\n    bool _2566;\n    if (!_2559)\n    {\n        _2566 = _2522.z > 1.0;\n    }\n    else\n    {\n        _2566 = _2559;\n    }\n    if (_2566)\n    {\n        return -1.0;\n    }\n    float _2574;\n    if (fa_shadows[26].x > 0.0)\n    {\n        _2574 = fa_shadows[26].x;\n    }\n    else\n    {\n        _2574 = 1.5 * fa_shadows[ci * 1 + 20].x;\n    }\n    vec2 param = _2522.xy;\n    vec4 param_1 = fa_shadows[ci * 1 + 16];\n    float param_2 = _2522.z - ((_2574 * (1.0 + (0.5 * _2492))) / _2474);\n    float param_3 = fa_shadows[ci * 1 + 20].x;\n    float param_4 = _2474;\n    float param_5 = _2474 * 0.25;\n    float param_6 = ((fa_shadows[ci * 1 + 20].x * min(_2492, 3.0)) * 0.5) / _2474;\n    vec3 param_7 = vec3(0.0);\n    int param_8 = int(fa_shadows[25].z + 0.5);\n    float param_9 = fa_shadows[25].w;\n    return fa_shadow_filter(param, param_1, param_2, param_3, param_4, param_5, param_6, param_7, param_8, param_9);\n}\n\nfloat fa_shadow_sun(vec3 world, vec3 n, vec3 l)\n{\n    if (fa_mesh_fs_params[5].z < 0.5)\n    {\n        return 1.0;\n    }\n    int _2962 = int(fa_shadows[25].x + 0.5);\n    if (_2962 < 1)\n    {\n        return 1.0;\n    }\n    float _2977 = dot(world - fa_shadows[27].xyz, fa_shadows[28].xyz);\n    int param = _2962 - 1;\n    if (_2977 > fa_shadow_split_at(param))\n    {\n        return 1.0;\n    }\n    int ci = 0;\n    bool _2989 = _2962 > 1;\n    bool _2996;\n    if (_2989)\n    {\n        _2996 = _2977 > fa_shadows[24].x;\n    }\n    else\n    {\n        _2996 = _2989;\n    }\n    if (_2996)\n    {\n        ci = 1;\n    }\n    bool _3000 = _2962 > 2;\n    bool _3007;\n    if (_3000)\n    {\n        _3007 = _2977 > fa_shadows[24].y;\n    }\n    else\n    {\n        _3007 = _3000;\n    }\n    if (_3007)\n    {\n        ci = 2;\n    }\n    bool _3011 = _2962 > 3;\n    bool _3018;\n    if (_3011)\n    {\n        _3018 = _2977 > fa_shadows[24].z;\n    }\n    else\n    {\n        _3018 = _3011;\n    }\n    if (_3018)\n    {\n        ci = 3;\n    }\n    float s = -1.0;\n    for (int k = 0; k < 4; k++)\n    {\n        if (ci >= _2962)\n        {\n            break;\n        }\n        int param_1 = ci;\n        vec3 param_2 = world;\n        vec3 param_3 = n;\n        vec3 param_4 = l;\n        float _3044 = fa_shadow_cascade(param_1, param_2, param_3, param_4);\n        s = _3044;\n        if (_3044 >= 0.0)\n        {\n            break;\n        }\n        ci++;\n    }\n    if (s < 0.0)\n    {\n        return 1.0;\n    }\n    if (fa_shadows[25].y > 0.0)\n    {\n        float _3069;\n        if (ci > 0)\n        {\n            int param_5 = ci - 1;\n            _3069 = fa_shadow_split_at(param_5);\n        }\n        else\n        {\n            _3069 = fa_shadows[28].w;\n        }\n        int param_6 = ci;\n        float _3088 = fa_shadows[25].y * max(fa_shadow_split_at(param_6) - _3069, 9.9999997473787516355514526367188e-05);\n        int param_7 = ci;\n        float _3099 = clamp((_2977 - (fa_shadow_split_at(param_7) - _3088)) / _3088, 0.0, 1.0);\n        if (_3099 > 0.0)\n        {\n            float s2 = 1.0;\n            if ((ci + 1) < _2962)\n            {\n                int param_8 = ci + 1;\n                vec3 param_9 = world;\n                vec3 param_10 = n;\n                vec3 param_11 = l;\n                float _3120 = fa_shadow_cascade(param_8, param_9, param_10, param_11);\n                s2 = _3120;\n                if (_3120 < 0.0)\n                {\n                    s2 = s;\n                }\n            }\n            s = mix(s, s2, _3099);\n        }\n    }\n    return s;\n}\n\nfloat fa_shadow_factor(vec3 n, vec3 l)\n{\n    vec3 param = fa_world_pos;\n    vec3 param_1 = n;\n    vec3 param_2 = l;\n    return fa_shadow_sun(param, param_1, param_2);\n}\n\nfloat fa_shadow_local(int li, vec3 world, vec3 n, vec3 l)\n{\n    bool _2632 = fa_mesh_fs_params[5].z < 0.5;\n    bool _2639;\n    if (!_2632)\n    {\n        _2639 = fa_shadows[29].x < 0.5;\n    }\n    else\n    {\n        _2639 = _2632;\n    }\n    if (_2639)\n    {\n        return 1.0;\n    }\n    int param = (int(fa_shadows[29].x + 0.5) - 1) + li;\n    vec4 _2652 = fa_light_texel(param);\n    float _2653 = _2652.x;\n    if (_2653 < 0.0)\n    {\n        return 1.0;\n    }\n    int _2662 = int(_2653 + 0.5);\n    int param_1 = _2662;\n    vec4 _2666 = fa_light_texel(param_1);\n    int param_2 = _2662 + 1;\n    vec4 _2671 = fa_light_texel(param_2);\n    float fade = 1.0;\n    float _2674 = _2666.y;\n    if (_2674 > 0.0)\n    {\n        float _2691 = 1.0 - smoothstep(0.75 * _2674, _2674, length(world - fa_shadows[27].xyz));\n        fade = _2691;\n        if (_2691 <= 0.0)\n        {\n            return 1.0;\n        }\n    }\n    int face = 0;\n    if (_2666.x > 1.5)\n    {\n        int param_3 = li;\n        int param_4 = fa_light_base(param_3);\n        vec3 param_5 = world - fa_light_texel(param_4).xyz;\n        face = fa_cube_face(param_5);\n    }\n    int _2720 = (_2662 + 2) + (face * 6);\n    int param_6 = _2720;\n    int param_7 = _2720 + 1;\n    int param_8 = _2720 + 3;\n    vec4 _2734 = fa_light_texel(param_8);\n    int param_9 = _2720 + 4;\n    vec4 _2739 = fa_light_texel(param_9);\n    int param_10 = _2720 + 5;\n    vec4 _2744 = fa_light_texel(param_10);\n    float _2756 = _2744.x * max(dot(_2734, vec4(world, 1.0)), 0.001000000047497451305389404296875);\n    float _2761 = clamp(dot(n, l), 0.0, 1.0);\n    float _2784 = clamp(dot(n, _2734.xyz), -1.0, 1.0);\n    int param_11 = li;\n    int param_12 = fa_light_base(param_11);\n    float _2808 = min(sqrt(1.0 - (_2784 * _2784)) / max(abs(dot(n, world - fa_light_texel(param_12).xyz)) / max(dot(_2734, vec4(world, 1.0)), 0.001000000047497451305389404296875), 0.20000000298023223876953125), 4.0);\n    float _2811 = _2671.y;\n    float _2813;\n    if (_2811 > 0.0)\n    {\n        _2813 = _2811;\n    }\n    else\n    {\n        _2813 = 1.5 * _2756;\n    }\n    vec4 _2833 = vec4(world + (n * (_2813 * sqrt(1.0 - (_2761 * _2761)))), 1.0);\n    float _2837 = dot(_2734, _2833);\n    float _2840 = _2744.y;\n    if (_2837 < _2840)\n    {\n        return 1.0;\n    }\n    vec2 _2855 = vec2(dot(fa_light_texel(param_6), _2833), dot(fa_light_texel(param_7), _2833)) / vec2(_2837);\n    float _2857 = _2855.x;\n    bool _2860 = _2857 < _2739.x;\n    bool _2869;\n    if (!_2860)\n    {\n        _2869 = _2857 > _2739.z;\n    }\n    else\n    {\n        _2869 = _2860;\n    }\n    bool _2878;\n    if (!_2869)\n    {\n        _2878 = _2855.y < _2739.y;\n    }\n    else\n    {\n        _2878 = _2869;\n    }\n    bool _2887;\n    if (!_2878)\n    {\n        _2887 = _2855.y > _2739.w;\n    }\n    else\n    {\n        _2887 = _2878;\n    }\n    if (_2887)\n    {\n        return 1.0;\n    }\n    float _2893 = _2671.x;\n    float _2895;\n    if (_2893 > 0.0)\n    {\n        _2895 = _2893;\n    }\n    else\n    {\n        _2895 = 1.5 * _2756;\n    }\n    vec2 param_13 = _2855;\n    vec4 param_14 = _2739;\n    float param_15 = _2837 - (_2895 * (1.0 + (0.5 * _2808)));\n    float param_16 = _2756;\n    float param_17 = 1.0;\n    float param_18 = _2744.z * 0.25;\n    float param_19 = (_2756 * min(_2808, 3.0)) * 0.5;\n    vec3 param_20 = vec3(1.0, _2840, _2744.z);\n    int param_21 = int(_2666.z + 0.5);\n    float param_22 = _2666.w;\n    return mix(1.0, fa_shadow_filter(param_13, param_14, param_15, param_16, param_17, param_18, param_19, param_20, param_21, param_22), fade);\n}\n\nLightSample fa_light_shadowed(int li, vec3 world_pos, vec3 gn)\n{\n    bool _4340 = fa_lm.z > 0.5;\n    bool _4346;\n    if (_4340)\n    {\n        int param = li;\n        _4346 = fa_light_baked(param);\n    }\n    else\n    {\n        _4346 = _4340;\n    }\n    if (_4346)\n    {\n        int param_1 = li;\n        return LightSample(vec3(0.0, 1.0, 0.0), vec3(0.0), 0.0, 1.0, 0.0, int(fa_light_type(param_1) + 0.5));\n    }\n    int param_2 = li;\n    vec3 param_3 = world_pos;\n    vec3 param_4 = gn;\n    LightSample _4370 = fa_light_sample_n(param_2, param_3, param_4);\n    vec3 _6693 = _4370.color;\n    float _6695 = _4370.shadow;\n    if ((_4370.type == 0) && (li == 0))\n    {\n        vec3 param_5 = gn;\n        vec3 param_6 = _4370.direction;\n        float _4384 = fa_shadow_factor(param_5, param_6);\n        _6695 = _4384;\n        _6693 *= _4384;\n    }\n    else\n    {\n        bool _4395 = _4370.type != 0;\n        bool _4401;\n        if (_4395)\n        {\n            _4401 = _4370.attenuation > 0.0;\n        }\n        else\n        {\n            _4401 = _4395;\n        }\n        if (_4401)\n        {\n            int param_7 = li;\n            vec3 param_8 = world_pos;\n            vec3 param_9 = gn;\n            vec3 param_10 = _4370.direction;\n            float _4413 = fa_shadow_local(param_7, param_8, param_9, param_10);\n            _6695 = _4413;\n            _6693 *= _4413;\n        }\n    }\n    return LightSample(_4370.direction, _6693, _4370.attenuation, _6695, _4370._distance, _4370.type);\n}\n\nvec3 fa_ltc_tangent(vec3 n, vec3 v)\n{\n    vec3 _4453 = v - (n * dot(v, n));\n    vec3 t = _4453;\n    float _4457 = dot(_4453, _4453);\n    float l2 = _4457;\n    if (_4457 < 1.0000000133514319600180897396058e-10)\n    {\n        vec3 _4467;\n        if (abs(n.z) < 0.999000012874603271484375)\n        {\n            _4467 = cross(n, vec3(0.0, 0.0, 1.0));\n        }\n        else\n        {\n            _4467 = cross(n, vec3(1.0, 0.0, 0.0));\n        }\n        t = _4467;\n        l2 = dot(_4467, _4467);\n    }\n    return t * inversesqrt(l2);\n}\n\nvec3 fa_ltc_local(vec3 t1, vec3 n, vec3 p)\n{\n    return vec3(dot(t1, p), dot(cross(n, t1), p), dot(n, p));\n}\n\nvec3 fa_ltc_edge_vector(vec3 a, vec3 b)\n{\n    float _4502 = dot(a, a);\n    float _4506 = dot(b, b);\n    if ((_4502 < 1.0000000195414813782625560981111e-24) || (_4506 < 1.0000000195414813782625560981111e-24))\n    {\n        return vec3(0.0);\n    }\n    vec3 _4520 = a * inversesqrt(_4502);\n    vec3 _4525 = b * inversesqrt(_4506);\n    float _4529 = dot(_4520, _4525);\n    float _4532 = abs(_4529);\n    float g = (((((((((((0.0416471660137176513671875 * _4532) - 0.1924748718738555908203125) * _4532) + 0.4179156124591827392578125) * _4532) - 0.616057217121124267578125) * _4532) + 0.777722418308258056640625) * _4532) - 0.999542415142059326171875) * _4532) + 1.570791721343994140625;\n    if (_4529 < 0.0)\n    {\n        g = (3.1415927410125732421875 * inversesqrt(max(1.0 - (_4529 * _4529), 1.0000000116860974230803549289703e-07))) - g;\n    }\n    return cross(_4520, _4525) * g;\n}\n\nvoid fa_ltc_clip_edge(vec3 a, vec3 b, inout vec3 sum, inout vec3 leave, inout vec3 enter, inout vec2 seen)\n{\n    bool _4589 = a.z > 0.0;\n    bool _4593 = b.z > 0.0;\n    if (_4589 && _4593)\n    {\n        vec3 param = a;\n        vec3 param_1 = b;\n        sum += fa_ltc_edge_vector(param, param_1);\n    }\n    else\n    {\n        if (_4589 != _4593)\n        {\n            vec3 _4628 = a + ((b - a) * (a.z / (a.z - b.z)));\n            _4628.z = 0.0;\n            if (_4589)\n            {\n                vec3 param_2 = a;\n                vec3 param_3 = _4628;\n                sum += fa_ltc_edge_vector(param_2, param_3);\n                leave = _4628;\n                seen.x = 1.0;\n            }\n            else\n            {\n                vec3 param_4 = _4628;\n                vec3 param_5 = b;\n                sum += fa_ltc_edge_vector(param_4, param_5);\n                enter = _4628;\n                seen.y = 1.0;\n            }\n        }\n    }\n}\n\nfloat fa_ltc_quad(vec4 abcd, vec3 p0, vec3 p1, vec3 p2, vec3 p3)\n{\n    vec3 _4677 = vec3((abcd.x * p0.x) + (abcd.y * p0.z), p0.y, (abcd.z * p0.x) + (abcd.w * p0.z));\n    vec3 _4703 = vec3((abcd.x * p1.x) + (abcd.y * p1.z), p1.y, (abcd.z * p1.x) + (abcd.w * p1.z));\n    vec3 _4729 = vec3((abcd.x * p2.x) + (abcd.y * p2.z), p2.y, (abcd.z * p2.x) + (abcd.w * p2.z));\n    vec3 _4755 = vec3((abcd.x * p3.x) + (abcd.y * p3.z), p3.y, (abcd.z * p3.x) + (abcd.w * p3.z));\n    vec3 sum = vec3(0.0);\n    vec3 leave = vec3(0.0);\n    vec3 enter = vec3(0.0);\n    vec3 param = _4677;\n    vec3 param_1 = _4703;\n    vec3 param_2 = vec3(0.0);\n    vec3 param_3 = vec3(0.0);\n    vec3 param_4 = vec3(0.0);\n    vec2 param_5 = vec2(0.0);\n    fa_ltc_clip_edge(param, param_1, param_2, param_3, param_4, param_5);\n    sum = param_2;\n    leave = param_3;\n    enter = param_4;\n    vec3 param_6 = _4703;\n    vec3 param_7 = _4729;\n    vec3 param_8 = param_2;\n    vec3 param_9 = param_3;\n    vec3 param_10 = param_4;\n    vec2 param_11 = param_5;\n    fa_ltc_clip_edge(param_6, param_7, param_8, param_9, param_10, param_11);\n    sum = param_8;\n    leave = param_9;\n    enter = param_10;\n    vec3 param_12 = _4729;\n    vec3 param_13 = _4755;\n    vec3 param_14 = param_8;\n    vec3 param_15 = param_9;\n    vec3 param_16 = param_10;\n    vec2 param_17 = param_11;\n    fa_ltc_clip_edge(param_12, param_13, param_14, param_15, param_16, param_17);\n    sum = param_14;\n    leave = param_15;\n    enter = param_16;\n    vec3 param_18 = _4755;\n    vec3 param_19 = _4677;\n    vec3 param_20 = param_14;\n    vec3 param_21 = param_15;\n    vec3 param_22 = param_16;\n    vec2 param_23 = param_17;\n    fa_ltc_clip_edge(param_18, param_19, param_20, param_21, param_22, param_23);\n    sum = param_20;\n    leave = param_21;\n    enter = param_22;\n    if ((param_23.x * param_23.y) > 0.5)\n    {\n        vec3 param_24 = leave;\n        vec3 param_25 = enter;\n        sum += fa_ltc_edge_vector(param_24, param_25);\n    }\n    return sum.z * 0.15915493667125701904296875;\n}\n\nfloat fa_ltc_rect(vec4 abcd, vec3 center, vec3 ex, vec3 ey)\n{\n    vec4 param = abcd;\n    vec3 param_1 = (center - ex) - ey;\n    vec3 param_2 = (center + ex) - ey;\n    vec3 param_3 = (center + ex) + ey;\n    vec3 param_4 = (center - ex) + ey;\n    return abs(fa_ltc_quad(param, param_1, param_2, param_3, param_4));\n}\n\nfloat fa_area_form(vec4 m, float shape, vec3 pc, vec3 ex, vec3 ey)\n{\n    if ((shape < 0.5) || (shape > 1.5))\n    {\n        vec4 param = m;\n        vec3 param_1 = pc;\n        vec3 param_2 = ex;\n        vec3 param_3 = ey;\n        return fa_ltc_rect(param, param_1, param_2, param_3);\n    }\n    vec3 _4905 = (pc + (ex * 0.92387950420379638671875)) + (ey * 0.3826834261417388916015625);\n    vec3 _4929 = (pc - (ex * 0.92387950420379638671875)) + (ey * 0.3826834261417388916015625);\n    vec3 _4945 = (pc - (ex * 0.3826834261417388916015625)) - (ey * 0.92387950420379638671875);\n    vec4 param_4 = m;\n    vec3 param_5 = _4905;\n    vec3 param_6 = (pc + (ex * 0.3826834261417388916015625)) + (ey * 0.92387950420379638671875);\n    vec3 param_7 = (pc - (ex * 0.3826834261417388916015625)) + (ey * 0.92387950420379638671875);\n    vec3 param_8 = _4929;\n    vec4 param_9 = m;\n    vec3 param_10 = _4905;\n    vec3 param_11 = _4929;\n    vec3 param_12 = (pc - (ex * 0.92387950420379638671875)) - (ey * 0.3826834261417388916015625);\n    vec3 param_13 = _4945;\n    vec4 param_14 = m;\n    vec3 param_15 = _4905;\n    vec3 param_16 = _4945;\n    vec3 param_17 = (pc + (ex * 0.3826834261417388916015625)) - (ey * 0.92387950420379638671875);\n    vec3 param_18 = (pc + (ex * 0.92387950420379638671875)) - (ey * 0.3826834261417388916015625);\n    return abs((fa_ltc_quad(param_4, param_5, param_6, param_7, param_8) + fa_ltc_quad(param_9, param_10, param_11, param_12, param_13)) + fa_ltc_quad(param_14, param_15, param_16, param_17, param_18));\n}\n\nvec2 fa_ltc_uv(float roughness, float ndv)\n{\n    return ((vec2(clamp((roughness - 0.0500000007450580596923828125) * 1.0526316165924072265625, 0.0, 1.0), sqrt(clamp(1.0 - ndv, 0.0, 1.0))) * 63.0) + vec2(0.5)) * vec2(0.015625);\n}\n\nvec3 fa_area_shade(int li, vec3 world_pos, vec3 n, vec3 v, vec3 diffuse_color, vec3 f0, float f90, float roughness, float ndv, float window)\n{\n    int param = li;\n    int _5003 = fa_light_base(param);\n    int param_1 = _5003;\n    int param_2 = _5003 + 1;\n    int param_3 = _5003 + 2;\n    int param_4 = _5003 + 4;\n    vec4 _5025 = fa_light_texel(param_4);\n    int param_5 = _5003 + 5;\n    vec4 _5030 = fa_light_texel(param_5);\n    int param_6 = _5003 + 6;\n    vec4 _5035 = fa_light_texel(param_6);\n    float _5036 = _5035.w;\n    vec3 _5041 = fa_light_texel(param_1).xyz - world_pos;\n    bool _5043 = _5036 < 1.5;\n    bool _5050;\n    if (_5043)\n    {\n        _5050 = dot(normalize(fa_light_texel(param_3).xyz), _5041) >= 0.0;\n    }\n    else\n    {\n        _5050 = _5043;\n    }\n    if (_5050)\n    {\n        return vec3(0.0);\n    }\n    bool _5059 = (_5036 > 0.5) && _5043;\n    float _5063 = _5059 ? 1.0539000034332275390625 : 1.0;\n    vec3 _5066 = _5025.xyz;\n    float _5068 = _5025.w;\n    vec3 _5074 = _5030.xyz;\n    float _5076 = _5030.w;\n    vec3 up = _5074 * (_5076 * _5063);\n    float _5082;\n    if (_5059)\n    {\n        _5082 = (3.1415927410125732421875 * _5068) * _5068;\n    }\n    else\n    {\n        _5082 = (4.0 * _5068) * _5076;\n    }\n    if (_5036 > 1.5)\n    {\n        vec3 _5108 = cross(_5066, -_5041);\n        vec3 perp = _5108;\n        float _5112 = dot(_5108, _5108);\n        vec3 _5115;\n        if (_5112 > 1.0000000133514319600180897396058e-10)\n        {\n            _5115 = perp * inversesqrt(_5112);\n        }\n        else\n        {\n            _5115 = _5074;\n        }\n        perp = _5115;\n        up = _5115 * _5076;\n    }\n    float _5136 = max(_5082, 9.9999999747524270787835121154785e-07);\n    vec3 param_7 = n;\n    vec3 param_8 = v;\n    vec3 _5146 = fa_ltc_tangent(param_7, param_8);\n    vec3 param_9 = _5146;\n    vec3 param_10 = n;\n    vec3 param_11 = _5041;\n    vec3 _5154 = fa_ltc_local(param_9, param_10, param_11);\n    vec3 param_12 = _5146;\n    vec3 param_13 = n;\n    vec3 param_14 = _5066 * (_5068 * _5063);\n    vec3 _5162 = fa_ltc_local(param_12, param_13, param_14);\n    vec3 param_15 = _5146;\n    vec3 param_16 = n;\n    vec3 param_17 = up;\n    vec3 _5170 = fa_ltc_local(param_15, param_16, param_17);\n    vec4 param_18 = vec4(1.0, 0.0, 0.0, 1.0);\n    float param_19 = _5036;\n    vec3 param_20 = _5154;\n    vec3 param_21 = _5162;\n    vec3 param_22 = _5170;\n    float param_23 = roughness;\n    float param_24 = ndv;\n    vec2 _5189 = fa_ltc_uv(param_23, param_24) * 64.0;\n    vec2 param_25 = _5189;\n    vec2 param_26 = _5189 + vec2(64.0, 0.0);\n    vec4 _5199 = fa_atlas_fetch(param_26);\n    vec4 param_27 = fa_atlas_fetch(param_25);\n    float param_28 = _5036;\n    vec3 param_29 = _5154;\n    vec3 param_30 = _5162;\n    vec3 param_31 = _5170;\n    return (((diffuse_color * fa_area_form(param_18, param_19, param_20, param_21, param_22)) + (((f0 * _5199.x) + ((vec3(f90) - f0) * _5199.y)) * fa_area_form(param_27, param_28, param_29, param_30, param_31))) * fa_light_texel(param_2).xyz) * ((((3.1415927410125732421875 * dot(_5041, _5041)) + _5136) / _5136) * window);\n}\n\nvec3 fa_light_rgb(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 1;\n    return fa_light_texel(param_1).xyz;\n}\n\nfloat fa_d_charlie(float alpha, float ndh)\n{\n    float _4043 = 1.0 / alpha;\n    return ((2.0 + _4043) * pow(sqrt(max(1.0 - (ndh * ndh), 9.9999997473787516355514526367188e-05)), _4043)) * 0.15915493667125701904296875;\n}\n\nfloat fa_v_ashikhmin(float ndl, float ndv)\n{\n    return clamp(0.25 / max((ndl + ndv) - (ndl * ndv), 9.9999997473787516355514526367188e-05), 0.0, 1.0);\n}\n\nfloat fa_layers_coat(FaLayers L, vec3 l, vec3 h, float vdh)\n{\n    float _4078 = max(dot(L.nc, l), 0.0);\n    float _4084 = max(dot(L.nc, h), 0.0);\n    float _4093 = ((_4084 * _4084) * (L.coat_a2 - 1.0)) + 1.0;\n    return (((L.coat * (0.039999999105930328369140625 + (0.959999978542327880859375 * pow(clamp(1.0 - vdh, 0.0, 1.0), 5.0)))) * (((L.coat_a2 / ((3.1415927410125732421875 * _4093) * _4093)) * (0.5 / max(mix((2.0 * _4078) * L.coat_ndv, _4078 + L.coat_ndv, L.coat_alpha), 9.9999997473787516355514526367188e-05))) * 3.1415927410125732421875)) * step(9.9999997473787516355514526367188e-05, _4078)) * _4078;\n}\n\nvec3 fa_area_layers(FaLayers L, int li, vec3 world_pos, vec3 n, vec3 v, vec3 l, vec3 diffuse_color, vec3 f0, float roughness, float ndv, float window)\n{\n    int param = li;\n    vec3 param_1 = world_pos;\n    vec3 param_2 = n;\n    vec3 param_3 = v;\n    vec3 param_4 = diffuse_color;\n    vec3 param_5 = f0;\n    float param_6 = L.f90;\n    float param_7 = roughness;\n    float param_8 = ndv;\n    float param_9 = window;\n    float _5267;\n    if (L.sheen_on)\n    {\n        _5267 = L.sheen_scale;\n    }\n    else\n    {\n        _5267 = 1.0;\n    }\n    vec3 result = fa_area_shade(param, param_1, param_2, param_3, param_4, param_5, param_6, param_7, param_8, param_9) * (L.keep * _5267);\n    vec3 _5280 = normalize(l + v);\n    int param_10 = li;\n    vec3 _5291 = fa_light_rgb(param_10) * window;\n    if (L.sheen_on)\n    {\n        float _5300 = max(dot(n, l), 0.0);\n        float param_11 = L.sheen_alpha;\n        float param_12 = max(dot(n, _5280), 0.0);\n        float param_13 = _5300;\n        float param_14 = ndv;\n        result += ((L.sheen * _5291) * (((((fa_d_charlie(param_11, param_12) * fa_v_ashikhmin(param_13, param_14)) * 3.1415927410125732421875) * step(9.9999997473787516355514526367188e-05, _5300)) * _5300) * L.keep));\n    }\n    if (L.coat > 0.0)\n    {\n        FaLayers param_15 = L;\n        vec3 param_16 = l;\n        vec3 param_17 = _5280;\n        float param_18 = max(dot(v, _5280), 0.0);\n        result += (_5291 * fa_layers_coat(param_15, param_16, param_17, param_18));\n    }\n    return result;\n}\n\nfloat fa_d_ggx_aniso(float ndh, float tdh, float bdh, float at, float ab)\n{\n    float _3946 = tdh / at;\n    float _3950 = bdh / ab;\n    float _3962 = ((_3946 * _3946) + (_3950 * _3950)) + (ndh * ndh);\n    return 1.0 / ((((3.1415927410125732421875 * at) * ab) * _3962) * _3962);\n}\n\nfloat fa_lambda_ggx_aniso(float n, float t, float b, float at, float ab)\n{\n    return 0.5 * (sqrt(1.0 + (((((at * at) * t) * t) + (((ab * ab) * b) * b)) / max(n * n, 9.9999999392252902907785028219223e-09))) - 1.0);\n}\n\nfloat fa_v_ggx_aniso(float ndl, float ndv, float tdv, float bdv, float tdl, float bdl, float at, float ab)\n{\n    float param = ndv;\n    float param_1 = tdv;\n    float param_2 = bdv;\n    float param_3 = at;\n    float param_4 = ab;\n    float param_5 = ndl;\n    float param_6 = tdl;\n    float param_7 = bdl;\n    float param_8 = at;\n    float param_9 = ab;\n    return clamp(1.0 / ((4.0 * max(ndl * ndv, 9.9999997473787516355514526367188e-05)) * ((1.0 + fa_lambda_ggx_aniso(param, param_1, param_2, param_3, param_4)) + fa_lambda_ggx_aniso(param_5, param_6, param_7, param_8, param_9))), 0.0, 1.0);\n}\n\nvec3 fa_layers_light(FaLayers L, vec3 diffuse_color, vec3 f0, vec3 n, vec3 v, vec3 l, vec3 h, float ndl, float ndv, float ndh, float vdh, float alpha, float a2)\n{\n    float _4142 = step(9.9999997473787516355514526367188e-05, ndl);\n    float d_ggx;\n    float vis;\n    if (L.aniso != 0.0)\n    {\n        float param = ndh;\n        float param_1 = dot(L.t, h);\n        float param_2 = dot(L.b, h);\n        float param_3 = L.at;\n        float param_4 = L.ab;\n        d_ggx = fa_d_ggx_aniso(param, param_1, param_2, param_3, param_4);\n        float param_5 = ndl;\n        float param_6 = ndv;\n        float param_7 = dot(L.t, v);\n        float param_8 = dot(L.b, v);\n        float param_9 = dot(L.t, l);\n        float param_10 = dot(L.b, l);\n        float param_11 = L.at;\n        float param_12 = L.ab;\n        vis = fa_v_ggx_aniso(param_5, param_6, param_7, param_8, param_9, param_10, param_11, param_12);\n    }\n    else\n    {\n        float _4221 = ((ndh * ndh) * (a2 - 1.0)) + 1.0;\n        d_ggx = a2 / ((3.1415927410125732421875 * _4221) * _4221);\n        vis = 0.5 / max(mix((2.0 * ndl) * ndv, ndl + ndv, alpha), 9.9999997473787516355514526367188e-05);\n    }\n    vec3 base = diffuse_color + (((f0 + ((vec3(L.f90) - f0) * pow(clamp(1.0 - vdh, 0.0, 1.0), 5.0))) * ((d_ggx * vis) * 3.1415927410125732421875)) * _4142);\n    if (L.sheen_on)\n    {\n        float param_13 = L.sheen_alpha;\n        float param_14 = ndh;\n        float param_15 = ndl;\n        float param_16 = ndv;\n        base = (base * L.sheen_scale) + (L.sheen * (((fa_d_charlie(param_13, param_14) * fa_v_ashikhmin(param_15, param_16)) * 3.1415927410125732421875) * _4142));\n    }\n    vec3 result = base * (L.keep * ndl);\n    if (L.coat > 0.0)\n    {\n        FaLayers param_17 = L;\n        vec3 param_18 = l;\n        vec3 param_19 = h;\n        float param_20 = vdh;\n        result += vec3(fa_layers_coat(param_17, param_18, param_19, param_20));\n    }\n    return result;\n}\n\nvec2 fa_env_brdf(float rough, float ndv)\n{\n    vec4 _3349 = (vec4(-1.0, -0.0274999998509883880615234375, -0.572000026702880859375, 0.02199999988079071044921875) * rough) + vec4(1.0, 0.0425000004470348358154296875, 1.03999996185302734375, -0.039999999105930328369140625);\n    float _3352 = _3349.x;\n    return (vec2(-1.03999996185302734375, 1.03999996185302734375) * ((min(_3352 * _3352, exp2((-9.27999973297119140625) * ndv)) * _3352) + _3349.y)) + _3349.zw;\n}\n\nvec3 fa_environment(vec3 d, float rough)\n{\n    if (fa_mesh_fs_params[11].w > 0.5)\n    {\n        return textureLod(fa_env_tex_fa_env_smp, d, clamp(rough, 0.0, 1.0) * fa_mesh_fs_params[12].w).xyz;\n    }\n    float _3255 = rough * rough;\n    float _3285 = 0.60000002384185791015625 * _3255;\n    return mix(mix(fa_mesh_fs_params[12].xyz * 0.550000011920928955078125, mix(fa_mesh_fs_params[12].xyz, fa_mesh_fs_params[11].xyz, vec3(pow(clamp(d.y * (1.0 - (0.699999988079071044921875 * _3255)), 0.0, 1.0), 0.550000011920928955078125))), vec3(smoothstep((-0.0500000007450580596923828125) - _3285, 0.0500000007450580596923828125 + _3285, d.y))), ((fa_mesh_fs_params[11].xyz + fa_mesh_fs_params[12].xyz) * 0.5) * 0.800000011920928955078125, vec3(_3255 * 0.60000002384185791015625));\n}\n\nvec3 fa_layers_ibl(FaLayers L, vec3 n, vec3 v, vec3 f0, float roughness)\n{\n    vec3 rn = n;\n    if (L.aniso != 0.0)\n    {\n        vec3 _3829;\n        if (L.aniso >= 0.0)\n        {\n            _3829 = L.b;\n        }\n        else\n        {\n            _3829 = L.t;\n        }\n        rn = normalize(mix(n, cross(cross(_3829, v), _3829), vec3(abs(L.aniso))));\n    }\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05);\n    vec2 _3862 = fa_env_brdf(param, param_1);\n    vec3 param_2 = reflect(-v, rn);\n    float param_3 = roughness;\n    vec3 result = (fa_environment(param_2, param_3) * ((f0 * _3862.x) + (vec3(L.f90) * _3862.y))) * L.base_scale;\n    if (L.sheen_on)\n    {\n        vec3 param_4 = n;\n        float param_5 = L.sheen_rough;\n        result += ((L.sheen * (L.sheen_e * L.keep)) * fa_environment(param_4, param_5));\n    }\n    if (L.coat > 0.0)\n    {\n        float param_6 = L.coat_rough;\n        float param_7 = L.coat_ndv;\n        vec2 _3917 = fa_env_brdf(param_6, param_7);\n        vec3 param_8 = reflect(-v, L.nc);\n        float param_9 = L.coat_rough;\n        result += (fa_environment(param_8, param_9) * (L.coat * ((0.039999999105930328369140625 * _3917.x) + _3917.y)));\n    }\n    return result;\n}\n\nvec3 fa_sky_reflection(vec3 n, vec3 v, vec3 f0, float roughness)\n{\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05);\n    vec2 _3391 = fa_env_brdf(param, param_1);\n    vec3 param_2 = reflect(-v, n);\n    float param_3 = roughness;\n    return fa_environment(param_2, param_3) * ((f0 * _3391.x) + vec3(_3391.y));\n}\n\nvec3 fa_shadow_debug(vec3 color, vec3 world)\n{\n    if (fa_shadows[27].w < 0.5)\n    {\n        return color;\n    }\n    int _3144 = int(fa_shadows[25].x + 0.5);\n    float _3154 = dot(world - fa_shadows[27].xyz, fa_shadows[28].xyz);\n    vec3 tint_1 = vec3(0.3499999940395355224609375);\n    bool _3159 = _3144 > 0;\n    bool _3168;\n    if (_3159)\n    {\n        int param = _3144 - 1;\n        _3168 = _3154 <= fa_shadow_split_at(param);\n    }\n    else\n    {\n        _3168 = _3159;\n    }\n    if (_3168)\n    {\n        tint_1 = vec3(1.0, 0.1500000059604644775390625, 0.100000001490116119384765625);\n        bool _3174 = _3144 > 1;\n        bool _3181;\n        if (_3174)\n        {\n            _3181 = _3154 > fa_shadows[24].x;\n        }\n        else\n        {\n            _3181 = _3174;\n        }\n        if (_3181)\n        {\n            tint_1 = vec3(0.100000001490116119384765625, 0.89999997615814208984375, 0.20000000298023223876953125);\n        }\n        bool _3187 = _3144 > 2;\n        bool _3194;\n        if (_3187)\n        {\n            _3194 = _3154 > fa_shadows[24].y;\n        }\n        else\n        {\n            _3194 = _3187;\n        }\n        if (_3194)\n        {\n            tint_1 = vec3(0.1500000059604644775390625, 0.300000011920928955078125, 1.0);\n        }\n        bool _3200 = _3144 > 3;\n        bool _3207;\n        if (_3200)\n        {\n            _3207 = _3154 > fa_shadows[24].z;\n        }\n        else\n        {\n            _3207 = _3200;\n        }\n        if (_3207)\n        {\n            tint_1 = vec3(1.0, 0.89999997615814208984375, 0.100000001490116119384765625);\n        }\n    }\n    return mix(color, tint_1, vec3(0.550000011920928955078125));\n}\n\nvoid main()\n{\n    fa_inst_load();\n    vec3 _6393 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _6393 = -_6393;\n    }\n    vec3 _5751 = normalize(fa_mesh_fs_params[0].xyz - fa_world_pos);\n    vec3 param = fa_world_pos;\n    fa_cluster_begin(param);\n    SurfaceInput param_1 = SurfaceInput(fa_world_pos, _6393, fa_world_tangent, fa_uv, fa_vertex_color, _5751, gl_FrontFacing);\n    Surface _5759 = fa_standard_surface(param_1);\n    vec3 _6424 = _5759.albedo;\n    float _6425 = _5759.alpha;\n    vec3 _6426 = _5759.normal;\n    float _6427 = _5759.metallic;\n    float _6428 = _5759.roughness;\n    float _6429 = _5759.occlusion;\n    vec3 _6430 = _5759.emission;\n    float _6431 = _5759.clearcoat;\n    float _6432 = _5759.clearcoat_roughness;\n    vec3 _6433 = _5759.sheen_color;\n    float _6434 = _5759.sheen_roughness;\n    float _6435 = _5759.anisotropy;\n    float _6436 = _5759.anisotropy_rotation;\n    float _6437 = _5759.specular;\n    float _6438 = _5759.ior;\n    vec3 _6439 = _5759.specular_color;\n    SurfaceInput param_2 = SurfaceInput(fa_world_pos, _6393, fa_world_tangent, fa_uv, fa_vertex_color, _5751, gl_FrontFacing);\n    Surface param_3 = _5759;\n    surface(param_2, param_3);\n    _6424 = param_3.albedo;\n    _6425 = param_3.alpha;\n    _6426 = param_3.normal;\n    _6427 = param_3.metallic;\n    _6428 = param_3.roughness;\n    _6429 = param_3.occlusion;\n    _6430 = param_3.emission;\n    _6431 = param_3.clearcoat;\n    _6432 = param_3.clearcoat_roughness;\n    _6433 = param_3.sheen_color;\n    _6434 = param_3.sheen_roughness;\n    _6435 = param_3.anisotropy;\n    _6436 = param_3.anisotropy_rotation;\n    _6437 = param_3.specular;\n    _6438 = param_3.ior;\n    _6439 = param_3.specular_color;\n    vec3 param_4 = fa_world_pos;\n    vec3 param_5 = _6393;\n    vec3 param_6 = param_3.albedo;\n    vec3 param_7 = param_3.normal;\n    fa_apply_decals(param_4, param_5, param_6, param_7);\n    _6424 = param_6;\n    _6426 = param_7;\n    vec3 result;\n    if (fa_mesh_fs_params[3].w > 0.5)\n    {\n        result = _6424;\n    }\n    else\n    {\n        vec3 _5798 = normalize(_6426);\n        float _5805 = clamp(_6427, 0.0, 1.0);\n        float _5809 = clamp(_6428, 0.0500000007450580596923828125, 1.0);\n        float _5813 = _5809 * _5809;\n        float _5817 = _5813 * _5813;\n        float _5822 = max(dot(_5798, _5751), 9.9999997473787516355514526367188e-05);\n        vec3 _5828 = _6424 * (1.0 - _5805);\n        vec3 _5835 = mix(vec3(0.039999999105930328369140625), _6424, vec3(_5805));\n        vec3 f0 = _5835;\n        SurfaceInput param_8 = SurfaceInput(fa_world_pos, _6393, fa_world_tangent, fa_uv, fa_vertex_color, _5751, gl_FrontFacing);\n        Surface param_9 = Surface(_6424, _6425, _6426, _6427, _6428, _6429, _6430, _6431, _6432, _6433, _6434, _6435, _6436, _6437, _6438, _6439);\n        vec3 param_10 = _5798;\n        vec3 param_11 = _5751;\n        float param_12 = _5805;\n        float param_13 = _5809;\n        vec3 param_14 = _5835;\n        FaLayers _5851 = fa_layers_setup(param_8, param_9, param_10, param_11, param_12, param_13, param_14);\n        f0 = param_14;\n        vec3 param_15 = _5798;\n        vec3 lit = (fa_indirect_diffuse(param_15) * _5828) * _6429;\n        if (_5851.on)\n        {\n            lit *= _5851.base_scale;\n        }\n        int _5873 = fa_cl_ndir + fa_cl_local;\n        for (int ln = 0; ln < _5873; ln++)\n        {\n            int param_16 = ln;\n            int _5886 = fa_cl_light(param_16);\n            bool _5889 = fa_lm.z > 0.5;\n            bool _5895;\n            if (_5889)\n            {\n                int param_17 = _5886;\n                _5895 = fa_light_baked(param_17);\n            }\n            else\n            {\n                _5895 = _5889;\n            }\n            if (_5895)\n            {\n                continue;\n            }\n            int param_18 = _5886;\n            vec3 param_19 = fa_world_pos;\n            vec3 param_20 = _6393;\n            LightSample _5907 = fa_light_shadowed(param_18, param_19, param_20);\n            float _5915 = max(dot(_5798, _5907.direction), 0.0);\n            float _5921 = _5907.attenuation * _5907.shadow;\n            vec3 _5926 = normalize(_5907.direction + _5751);\n            float _5931 = max(dot(_5798, _5926), 0.0);\n            float _5936 = max(dot(_5751, _5926), 0.0);\n            bool _5943;\n            if (fa_light_is_area)\n            {\n                _5943 = !_5851.on;\n            }\n            else\n            {\n                _5943 = fa_light_is_area;\n            }\n            if (_5943)\n            {\n                int param_21 = _5886;\n                vec3 param_22 = fa_world_pos;\n                vec3 param_23 = _5798;\n                vec3 param_24 = _5751;\n                vec3 param_25 = _5828;\n                vec3 param_26 = f0;\n                float param_27 = 1.0;\n                float param_28 = _5809;\n                float param_29 = _5822;\n                float param_30 = _5921;\n                lit += fa_area_shade(param_21, param_22, param_23, param_24, param_25, param_26, param_27, param_28, param_29, param_30);\n            }\n            else\n            {\n                if (fa_light_is_area)\n                {\n                    FaLayers param_31 = _5851;\n                    int param_32 = _5886;\n                    vec3 param_33 = fa_world_pos;\n                    vec3 param_34 = _5798;\n                    vec3 param_35 = _5751;\n                    vec3 param_36 = _5907.direction;\n                    vec3 param_37 = _5828;\n                    vec3 param_38 = f0;\n                    float param_39 = _5809;\n                    float param_40 = _5822;\n                    float param_41 = _5921;\n                    lit += fa_area_layers(param_31, param_32, param_33, param_34, param_35, param_36, param_37, param_38, param_39, param_40, param_41);\n                }\n                else\n                {\n                    if (_5851.on)\n                    {\n                        FaLayers param_42 = _5851;\n                        vec3 param_43 = _5828;\n                        vec3 param_44 = f0;\n                        vec3 param_45 = _5798;\n                        vec3 param_46 = _5751;\n                        vec3 param_47 = _5907.direction;\n                        vec3 param_48 = _5926;\n                        float param_49 = _5915;\n                        float param_50 = _5822;\n                        float param_51 = _5931;\n                        float param_52 = _5936;\n                        float param_53 = _5813;\n                        float param_54 = _5817;\n                        int param_55 = _5886;\n                        lit += (fa_layers_light(param_42, param_43, param_44, param_45, param_46, param_47, param_48, param_49, param_50, param_51, param_52, param_53, param_54) * ((fa_light_rgb(param_55) * fa_light_tint) * _5921));\n                    }\n                    else\n                    {\n                        float _6049 = ((_5931 * _5931) * (_5817 - 1.0)) + 1.0;\n                        int param_56 = _5886;\n                        lit += (((_5828 + (((f0 + ((vec3(1.0) - f0) * pow(1.0 - _5936, 5.0))) * (((_5817 / ((3.1415927410125732421875 * _6049) * _6049)) * (0.5 / max(mix((2.0 * _5915) * _5822, _5915 + _5822, _5813), 9.9999997473787516355514526367188e-05))) * 3.1415927410125732421875)) * step(9.9999997473787516355514526367188e-05, _5915))) * (fa_light_rgb(param_56) * fa_light_tint)) * (_5915 * _5921));\n                    }\n                }\n            }\n        }\n        if (_5851.on)\n        {\n            FaLayers param_57 = _5851;\n            vec3 param_58 = _5798;\n            vec3 param_59 = _5751;\n            vec3 param_60 = f0;\n            float param_61 = _5809;\n            lit += (fa_layers_ibl(param_57, param_58, param_59, param_60, param_61) * _6429);\n        }\n        else\n        {\n            vec3 param_62 = _5798;\n            vec3 param_63 = _5751;\n            vec3 param_64 = f0;\n            float param_65 = _5809;\n            lit += (fa_sky_reflection(param_62, param_63, param_64, param_65) * _6429);\n        }\n        result = lit;\n    }\n    vec3 _6144 = result;\n    vec3 _6145 = _6144 + _6430;\n    result = _6145;\n    vec3 param_66 = _6145;\n    vec3 param_67 = fa_world_pos;\n    result = fa_shadow_debug(param_66, param_67);\n    bool _6154 = fa_mesh_fs_params[7].w > 0.0;\n    bool _6161;\n    if (!_6154)\n    {\n        _6161 = fa_mesh_fs_params[8].y > 0.0;\n    }\n    else\n    {\n        _6161 = _6154;\n    }\n    if (_6161)\n    {\n        vec3 _6170 = fa_world_pos - fa_mesh_fs_params[0].xyz;\n        float _6176 = dot(_6170, fa_mesh_fs_params[9].xyz);\n        bool _6180 = fa_mesh_fs_params[9].w > 0.5;\n        float _6181;\n        if (_6180)\n        {\n            _6181 = _6176;\n        }\n        else\n        {\n            _6181 = length(_6170);\n        }\n        float _6193 = _6181 - fa_mesh_fs_params[8].x;\n        if (_6193 > 0.0)\n        {\n            float _6202 = fa_mesh_fs_params[7].w * _6193;\n            float tau = _6202 * _6202;\n            if (fa_mesh_fs_params[8].y > 0.0)\n            {\n                float _6218;\n                if (_6180)\n                {\n                    _6218 = fa_world_pos.y - (fa_mesh_fs_params[9].y * _6176);\n                }\n                else\n                {\n                    _6218 = fa_mesh_fs_params[0].y;\n                }\n                float _6239 = mix(_6218, fa_world_pos.y, clamp(fa_mesh_fs_params[8].x / _6181, 0.0, 1.0));\n                float _6243 = fa_world_pos.y - _6239;\n                float _6248 = _6239 - fa_mesh_fs_params[8].z;\n                float _6253 = fa_world_pos.y - fa_mesh_fs_params[8].z;\n                bool _6256 = _6248 <= 0.0;\n                bool _6257 = !_6256;\n                bool _6263;\n                if (_6257)\n                {\n                    _6263 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _6263 = _6256;\n                }\n                float _6264;\n                if (_6263)\n                {\n                    _6264 = fa_mesh_fs_params[8].y;\n                }\n                else\n                {\n                    _6264 = fa_mesh_fs_params[8].y * exp(-min(fa_mesh_fs_params[8].w * _6248, 80.0));\n                }\n                bool _6291;\n                if (_6257)\n                {\n                    _6291 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _6291 = _6256;\n                }\n                float _6292;\n                if (_6291)\n                {\n                    _6292 = fa_mesh_fs_params[8].y * _6248;\n                }\n                else\n                {\n                    _6292 = (fa_mesh_fs_params[8].y * (1.0 - exp(-min(fa_mesh_fs_params[8].w * _6248, 80.0)))) / fa_mesh_fs_params[8].w;\n                }\n                bool _6317 = _6253 <= 0.0;\n                bool _6324;\n                if (!_6317)\n                {\n                    _6324 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _6324 = _6317;\n                }\n                float _6325;\n                if (_6324)\n                {\n                    _6325 = fa_mesh_fs_params[8].y * _6253;\n                }\n                else\n                {\n                    _6325 = (fa_mesh_fs_params[8].y * (1.0 - exp(-min(fa_mesh_fs_params[8].w * _6253, 80.0)))) / fa_mesh_fs_params[8].w;\n                }\n                float _6352;\n                if (abs(_6243) < 0.001000000047497451305389404296875)\n                {\n                    _6352 = _6264;\n                }\n                else\n                {\n                    _6352 = (_6325 - _6292) / _6243;\n                }\n                tau += (_6193 * max(_6352, 0.0));\n            }\n            result = mix(result, fa_mesh_fs_params[7].xyz, vec3(clamp(1.0 - exp(-clamp(tau, 0.0, 80.0)), 0.0, 1.0)));\n        }\n    }\n    fa_frag_color = vec4(result, _6425);\n}\n\n",
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
            "size": 384,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_491",
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
            "inst_name": "_2198",
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
            "inst_name": "_5369",
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
              "name": "fa_env_tex",
              "multisampled": false,
              "type": "cube",
              "sample_type": "float"
            }
          },
          {
            "texture": {
              "slot": 15,
              "stage": "fragment",
              "name": "fa_irr_tex",
              "multisampled": false,
              "type": "cube",
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
            "name": "fa_irr_tex_fa_env_smp",
            "view_name": "fa_irr_tex",
            "sampler_name": "fa_env_smp",
            "view_slot": 15,
            "sampler_slot": 10,
            "glsl_name": "fa_irr_tex_fa_env_smp"
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
            "name": "fa_env_tex_fa_env_smp",
            "view_name": "fa_env_tex",
            "sampler_name": "fa_env_smp",
            "view_slot": 14,
            "sampler_slot": 10,
            "glsl_name": "fa_env_tex_fa_env_smp"
          }
        ]
      }
    },
    "mesh_skin": {
      "vs": "#version 430\n\nstruct VertexData\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 color;\n    vec3 object_pos;\n};\n\nuniform vec4 fa_mesh_vs_params[11];\nuniform vec4 fa_skin[192];\nlayout(location = 2) out vec3 fa_world_pos;\nlayout(location = 3) out vec3 fa_world_normal;\nlayout(location = 4) out vec4 fa_world_tangent;\nlayout(location = 5) out vec2 fa_uv;\nlayout(location = 6) out vec4 fa_vertex_color;\nlayout(location = 11) in vec4 fa_inst_d0;\nlayout(location = 12) in vec4 fa_inst_d1;\nlayout(location = 0) flat out vec4 fa_inst_v0;\nlayout(location = 1) flat out vec4 fa_inst_v1;\nlayout(location = 5) in vec4 fa_inst_m0;\nlayout(location = 6) in vec4 fa_inst_m1;\nlayout(location = 7) in vec4 fa_inst_m2;\nlayout(location = 8) in vec4 fa_inst_m3;\nlayout(location = 9) in vec4 fa_joints;\nlayout(location = 10) in vec4 fa_weights;\nlayout(location = 0) in vec3 fa_position;\nlayout(location = 1) in vec3 fa_normal;\nlayout(location = 3) in vec4 fa_tangent;\nlayout(location = 2) in vec2 fa_texcoord0;\nlayout(location = 4) in vec4 fa_color;\nlayout(location = 7) out vec3 fa_lm;\nfloat raise;\nvec4 tint;\n\nvoid fa_instance_unpack(vec4 fa_d0, vec4 fa_d1, vec4 fa_d2)\n{\n    raise = fa_d0.x;\n    tint = fa_d1;\n}\n\nvoid fa_inst_begin()\n{\n    vec4 param = fa_inst_d0;\n    vec4 param_1 = fa_inst_d1;\n    vec4 param_2 = vec4(0.0);\n    fa_instance_unpack(param, param_1, param_2);\n    fa_inst_v0 = fa_inst_d0;\n    fa_inst_v1 = fa_inst_d1;\n}\n\nmat4 fa_skin_matrix(vec4 joints, vec4 weights)\n{\n    vec4 r0 = vec4(0.0);\n    vec4 r1 = vec4(0.0);\n    vec4 r2 = vec4(0.0);\n    for (int i = 0; i < 4; i++)\n    {\n        int _196 = int((joints[i] * 255.0) + 0.5) * 3;\n        r0 += (fa_skin[_196 * 1 + 0] * weights[i]);\n        r1 += (fa_skin[(_196 + 1) * 1 + 0] * weights[i]);\n        r2 += (fa_skin[(_196 + 2) * 1 + 0] * weights[i]);\n    }\n    return mat4(vec4(r0.x, r1.x, r2.x, 0.0), vec4(r0.y, r1.y, r2.y, 0.0), vec4(r0.z, r1.z, r2.z, 0.0), vec4(r0.w, r1.w, r2.w, 1.0));\n}\n\nVertexData fa_vertex_data(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    vec3 _99 = cross(model[1].xyz, model[2].xyz);\n    float _105 = (dot(model[0].xyz, _99) < 0.0) ? (-1.0) : 1.0;\n    return VertexData((model * vec4(position, 1.0)).xyz, (((_99 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _105, vec4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _105), texcoord0 * fa_mesh_vs_params[8].xy, color, position);\n}\n\nvoid vertex(inout VertexData v)\n{\n    v.world_pos.y += raise;\n}\n\nvoid fa_shade_vertex(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    mat4 param = model;\n    vec3 param_1 = position;\n    vec3 param_2 = normal;\n    vec4 param_3 = tangent;\n    vec2 param_4 = texcoord0;\n    vec4 param_5 = color;\n    VertexData param_6 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    vertex(param_6);\n    fa_world_pos = param_6.world_pos;\n    fa_world_normal = param_6.world_normal;\n    fa_world_tangent = param_6.world_tangent;\n    fa_uv = param_6.uv;\n    fa_vertex_color = param_6.color;\n    gl_Position = mat4(fa_mesh_vs_params[0], fa_mesh_vs_params[1], fa_mesh_vs_params[2], fa_mesh_vs_params[3]) * vec4(param_6.world_pos, 1.0);\n}\n\nvoid main()\n{\n    fa_inst_begin();\n    vec4 param = fa_joints;\n    vec4 param_1 = fa_weights;\n    mat4 param_2 = mat4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3) * fa_skin_matrix(param, param_1);\n    vec3 param_3 = fa_position;\n    vec3 param_4 = fa_normal;\n    vec4 param_5 = fa_tangent;\n    vec2 param_6 = fa_texcoord0;\n    vec4 param_7 = fa_color;\n    fa_shade_vertex(param_2, param_3, param_4, param_5, param_6, param_7);\n    fa_lm = vec3(0.0);\n}\n\n",
      "fs": "#version 430\n\nstruct SurfaceInput\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 vertex_color;\n    vec3 view_dir;\n    bool front_facing;\n};\n\nstruct LightSample\n{\n    vec3 direction;\n    vec3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct Surface\n{\n    vec3 albedo;\n    float alpha;\n    vec3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    vec3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    vec3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    vec3 specular_color;\n};\n\nstruct FaLayers\n{\n    bool on;\n    float f90;\n    float keep;\n    float base_scale;\n    float coat;\n    float coat_rough;\n    float coat_alpha;\n    float coat_a2;\n    vec3 nc;\n    float coat_ndv;\n    bool sheen_on;\n    vec3 sheen;\n    float sheen_rough;\n    float sheen_alpha;\n    float sheen_scale;\n    float sheen_e;\n    float aniso;\n    vec3 t;\n    vec3 b;\n    float at;\n    float ab;\n};\n\nconst float _3492[63] = float[](1.0, 1.0, 1.0, 0.4790000021457672119140625, 0.11699999868869781494140625, 0.01200000010430812835693359375, 0.0, 0.0, 0.0, 1.0, 1.0, 1.0, 0.578000009059906005859375, 0.19300000369548797607421875, 0.0350000001490116119384765625, 0.0030000000260770320892333984375, 0.0, 0.0, 1.0, 1.0, 1.0, 0.6740000247955322265625, 0.3459999859333038330078125, 0.1319999992847442626953125, 0.032999999821186065673828125, 0.0040000001899898052215576171875, 0.0, 0.971000015735626220703125, 0.954999983310699462890625, 0.828999996185302734375, 0.63999998569488525390625, 0.42599999904632568359375, 0.24500000476837158203125, 0.115000002086162567138671875, 0.037000000476837158203125, 0.0030000000260770320892333984375, 0.7469999790191650390625, 0.737999975681304931640625, 0.670000016689300537109375, 0.563000023365020751953125, 0.4309999942779541015625, 0.3039999902248382568359375, 0.1940000057220458984375, 0.1019999980926513671875, 0.0309999994933605194091796875, 0.614000022411346435546875, 0.609000027179718017578125, 0.566999971866607666015625, 0.499000012874603271484375, 0.412000000476837158203125, 0.32400000095367431640625, 0.240999996662139892578125, 0.162000000476837158203125, 0.087999999523162841796875, 0.538999974727630615234375, 0.535000026226043701171875, 0.505999982357025146484375, 0.4569999873638153076171875, 0.393999993801116943359375, 0.328999996185302734375, 0.2660000026226043701171875, 0.203999996185302734375, 0.14200000464916229248046875);\n\nuniform vec4 fa_mesh_fs_params[24];\nuniform vec4 fa_shadows[30];\nuniform vec4 fa_material[1];\nlayout(binding = 0) uniform sampler2D fa_light_tex_fa_shadow_smp;\nlayout(binding = 1) uniform sampler2D fa_tex_fa_smp;\nlayout(binding = 2) uniform sampler2D fa_normal_tex_fa_smp;\nlayout(binding = 3) uniform sampler2D fa_mr_tex_fa_smp;\nlayout(binding = 4) uniform sampler2D fa_occlusion_tex_fa_smp;\nlayout(binding = 5) uniform sampler2D fa_emissive_tex_fa_smp;\nlayout(binding = 6) uniform sampler2D fa_decal_tex_fa_env_smp;\nlayout(binding = 7) uniform sampler2D fa_lightmap_fa_env_smp;\nlayout(binding = 8) uniform samplerCube fa_irr_tex_fa_env_smp;\nlayout(binding = 9) uniform sampler2D fa_light_atlas_fa_env_smp;\nlayout(binding = 10) uniform sampler2D fa_shadow_tex_fa_shadow_smp;\nlayout(binding = 11) uniform samplerCube fa_env_tex_fa_env_smp;\n\nlayout(location = 2) in vec3 fa_world_pos;\nlayout(location = 7) in vec3 fa_lm;\nlayout(location = 0) flat in vec4 fa_inst_v0;\nlayout(location = 1) flat in vec4 fa_inst_v1;\nlayout(location = 3) in vec3 fa_world_normal;\nlayout(location = 4) in vec4 fa_world_tangent;\nlayout(location = 5) in vec2 fa_uv;\nlayout(location = 6) in vec4 fa_vertex_color;\nlayout(location = 0) out vec4 fa_frag_color;\nvec3 fa_light_tint;\nbool fa_light_is_area;\nint fa_cl_ndir;\nint fa_cl_slot;\nint fa_cl_local;\nfloat raise;\nvec4 tint;\n\nvoid fa_instance_unpack(vec4 fa_d0, vec4 fa_d1, vec4 fa_d2)\n{\n    raise = fa_d0.x;\n    tint = fa_d1;\n}\n\nvoid fa_inst_load()\n{\n    vec4 param = fa_inst_v0;\n    vec4 param_1 = fa_inst_v1;\n    vec4 param_2 = vec4(0.0);\n    fa_instance_unpack(param, param_1, param_2);\n}\n\nvec4 fa_light_texel(int t)\n{\n    return texelFetch(fa_light_tex_fa_shadow_smp, ivec2(t & 1023, t >> 10), 0);\n}\n\nvec4 fa_cluster_texel(vec3 world_pos)\n{\n    bool _1469 = fa_mesh_fs_params[19].x < 0.0;\n    bool _1476;\n    if (!_1469)\n    {\n        _1476 = fa_mesh_fs_params[19].w < 1.0;\n    }\n    else\n    {\n        _1476 = _1469;\n    }\n    bool _1484;\n    if (!_1476)\n    {\n        _1484 = fa_mesh_fs_params[18].x < 1.0;\n    }\n    else\n    {\n        _1484 = _1476;\n    }\n    bool _1491;\n    if (!_1484)\n    {\n        _1491 = fa_mesh_fs_params[18].y < 1.0;\n    }\n    else\n    {\n        _1491 = _1484;\n    }\n    bool _1498;\n    if (!_1491)\n    {\n        _1498 = fa_mesh_fs_params[19].y < 1.0;\n    }\n    else\n    {\n        _1498 = _1491;\n    }\n    if (_1498)\n    {\n        return vec4(0.0);\n    }\n    vec4 _1508 = vec4(world_pos, 1.0);\n    float _1514 = dot(fa_mesh_fs_params[16], _1508);\n    if (!(_1514 > 9.9999999747524270787835121154785e-07))\n    {\n        return vec4(0.0);\n    }\n    vec2 _1536 = vec2(dot(fa_mesh_fs_params[14], _1508), dot(fa_mesh_fs_params[15], _1508)) / vec2(_1514);\n    int _1540 = int(fa_mesh_fs_params[18].x);\n    int _1544 = int(fa_mesh_fs_params[18].y);\n    int param = (int(fa_mesh_fs_params[19].x) + (((clamp(int(floor(log2(max(dot(fa_mesh_fs_params[17].xyz, world_pos) + fa_mesh_fs_params[17].w, fa_mesh_fs_params[18].w) / fa_mesh_fs_params[18].w) * fa_mesh_fs_params[18].z)), 0, int(fa_mesh_fs_params[19].y) - 1) * _1544) + clamp(int(floor(((_1536.y * 0.5) + 0.5) * fa_mesh_fs_params[18].y)), 0, _1544 - 1)) * _1540)) + clamp(int(floor(((_1536.x * 0.5) + 0.5) * fa_mesh_fs_params[18].x)), 0, _1540 - 1);\n    return fa_light_texel(param);\n}\n\nivec2 fa_cluster_lookup(vec3 world_pos)\n{\n    vec3 param = world_pos;\n    vec4 _1620 = fa_cluster_texel(param);\n    return ivec2(int(_1620.x), int(_1620.y));\n}\n\nvoid fa_cluster_begin(vec3 world_pos)\n{\n    fa_cl_ndir = int(fa_mesh_fs_params[19].z);\n    vec3 param = world_pos;\n    ivec2 _4313 = fa_cluster_lookup(param);\n    fa_cl_slot = _4313.x;\n    fa_cl_local = _4313.y;\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nvec3 fa_linear_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_tex_fix(inout vec3 c, float mode)\n{\n    if (mode > 1.5)\n    {\n        vec3 param = c;\n        vec3 _5421 = fa_linear_to_srgb(param);\n        c = _5421;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            vec3 param_1 = c;\n            vec3 _5429 = fa_srgb_to_linear(param_1);\n            c = _5429;\n        }\n    }\n    return c;\n}\n\nvec3 fa_tangent_normal(SurfaceInput i, vec3 m)\n{\n    vec3 _423;\n    if (i.front_facing)\n    {\n        _423 = i.world_normal;\n    }\n    else\n    {\n        _423 = -i.world_normal;\n    }\n    vec3 _447 = normalize(i.world_tangent.xyz - (_423 * dot(_423, i.world_tangent.xyz)));\n    vec3 _475 = normalize(((_447 * m.x) + ((cross(_423, _447) * i.world_tangent.w) * m.y)) + (_423 * m.z));\n    vec3 _478;\n    if (i.front_facing)\n    {\n        _478 = _475;\n    }\n    else\n    {\n        _478 = -_475;\n    }\n    return _478;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    vec4 base_t = texture(fa_tex_fa_smp, i.uv);\n    float param = fa_mesh_fs_params[6].w;\n    float param_1 = 1.0;\n    vec3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    vec3 _5460 = fa_tex_fix(param_2, param_3);\n    vec4 _6875 = base_t;\n    _6875.x = _5460.x;\n    _6875.y = _5460.y;\n    _6875.z = _5460.z;\n    base_t = _6875;\n    vec4 _5474 = (_6875 * fa_mesh_fs_params[2]) * i.vertex_color;\n    vec3 _6713 = i.world_normal;\n    if (fa_mesh_fs_params[6].z > 0.5)\n    {\n        float param_4 = fa_mesh_fs_params[6].w;\n        float param_5 = 16.0;\n        vec3 param_6 = texture(fa_normal_tex_fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        vec3 _5506 = fa_tex_fix(param_6, param_7);\n        vec3 _5509 = (_5506 * 2.0) - vec3(1.0);\n        vec2 _5514 = _5509.xy * fa_mesh_fs_params[6].x;\n        vec3 _6883 = _5509;\n        _6883.x = _5514.x;\n        _6883.y = _5514.y;\n        SurfaceInput param_8 = i;\n        vec3 param_9 = _6883;\n        _6713 = fa_tangent_normal(param_8, param_9);\n    }\n    vec4 mrt = texture(fa_mr_tex_fa_smp, i.uv);\n    float param_10 = fa_mesh_fs_params[6].w;\n    float param_11 = 64.0;\n    vec3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    vec3 _5542 = fa_tex_fix(param_12, param_13);\n    vec4 _6886 = mrt;\n    _6886.x = _5542.x;\n    _6886.y = _5542.y;\n    _6886.z = _5542.z;\n    mrt = _6886;\n    vec4 _5570 = texture(fa_occlusion_tex_fa_smp, i.uv);\n    float param_14 = fa_mesh_fs_params[6].w;\n    float param_15 = 256.0;\n    vec3 param_16 = _5570.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    vec3 _5581 = fa_tex_fix(param_16, param_17);\n    float param_18 = fa_mesh_fs_params[6].w;\n    float param_19 = 4.0;\n    vec3 param_20 = texture(fa_emissive_tex_fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    vec3 _5611 = fa_tex_fix(param_20, param_21);\n    float _6718 = fa_mesh_fs_params[20].x;\n    float _6719 = fa_mesh_fs_params[20].y;\n    float _6722 = fa_mesh_fs_params[20].z;\n    float _6721 = fa_mesh_fs_params[21].w;\n    float _6724 = fa_mesh_fs_params[22].x;\n    if (fa_mesh_fs_params[22].z > 0.5)\n    {\n        if (mod(fa_mesh_fs_params[22].z, 2.0) > 0.5)\n        {\n            _6718 *= _5581.y;\n            _6719 *= _5581.z;\n            _6721 *= _5570.w;\n        }\n        if (fa_mesh_fs_params[22].z > 1.5)\n        {\n            _6722 *= mrt.x;\n            _6724 *= mrt.w;\n        }\n    }\n    return Surface(_5474.xyz, _5474.w, _6713, clamp(fa_mesh_fs_params[5].x * _5542.z, 0.0, 1.0), clamp(fa_mesh_fs_params[5].y * _5542.y, 0.0500000007450580596923828125, 1.0), 1.0 + (fa_mesh_fs_params[6].y * (_5581.x - 1.0)), fa_mesh_fs_params[3].xyz + (fa_mesh_fs_params[4].xyz * _5611), _6718, _6719, fa_mesh_fs_params[21].xyz, _6721, _6722, fa_mesh_fs_params[20].w, _6724, fa_mesh_fs_params[22].y, fa_mesh_fs_params[23].xyz);\n}\n\nvoid surface(SurfaceInput i, inout Surface s)\n{\n    s.emission += ((tint.xyz * tint.w) * fa_material[0].x);\n}\n\nvec4 fa_decal_tile(vec4 rect, vec2 uv, vec2 atlas, vec2 ddx, vec2 ddy)\n{\n    vec2 _1700 = rect.zw - rect.xy;\n    vec2 _1704 = _1700 * atlas;\n    vec2 _1708 = ddx * _1704;\n    vec2 _1712 = ddy * _1704;\n    return textureLod(fa_decal_tex_fa_env_smp, rect.xy + (clamp(uv, vec2(0.0), vec2(1.0)) * _1700), clamp(0.5 * log2(max(max(dot(_1708, _1708), dot(_1712, _1712)), 9.9999999392252902907785028219223e-09)), 0.0, 4.0));\n}\n\nvec3 fa_dc_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_dc_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvoid fa_apply_decals(vec3 world_pos, vec3 geo_normal, inout vec3 albedo, inout vec3 normal)\n{\n    bool _1745 = fa_mesh_fs_params[10].y < 0.5;\n    bool _1752;\n    if (!_1745)\n    {\n        _1752 = fa_mesh_fs_params[10].w < 0.5;\n    }\n    else\n    {\n        _1752 = _1745;\n    }\n    if (_1752)\n    {\n        return;\n    }\n    vec3 _1758 = dFdx(world_pos);\n    vec3 _1761 = dFdy(world_pos);\n    vec3 param = world_pos;\n    vec4 _1765 = fa_cluster_texel(param);\n    int _1769 = int(_1765.w);\n    if (_1769 < 1)\n    {\n        return;\n    }\n    int _1779 = int(fa_mesh_fs_params[10].y + 0.5);\n    int param_1 = _1779;\n    vec4 _1783 = fa_light_texel(param_1);\n    vec2 _1786 = _1783.yz;\n    int _1790 = int(_1783.w);\n    int param_2 = _1779 + 1;\n    vec4 _1795 = fa_light_texel(param_2);\n    float _1796 = _1795.x;\n    int _1802 = int(fa_mesh_fs_params[10].w + 0.5) - 1;\n    int _1806 = int(_1765.z);\n    vec3 _2071;\n    for (int k = 0; k < _1769; k++)\n    {\n        int _1819 = _1806 + k;\n        int param_3 = _1790 + (_1819 >> 2);\n        int _1836 = (_1779 + 2) + (int(fa_light_texel(param_3)[_1819 & 3]) * 7);\n        int param_4 = _1836 + 6;\n        vec4 _1841 = fa_light_texel(param_4);\n        if (((int(_1841.w + 0.5) >> _1802) & 1) == 0)\n        {\n            continue;\n        }\n        int param_5 = _1836;\n        vec4 _1856 = fa_light_texel(param_5);\n        int param_6 = _1836 + 1;\n        vec4 _1861 = fa_light_texel(param_6);\n        int param_7 = _1836 + 2;\n        vec4 _1866 = fa_light_texel(param_7);\n        vec3 _1869 = _1856.xyz;\n        float _1874 = dot(_1869, world_pos) + _1856.w;\n        vec3 _1876 = _1861.xyz;\n        float _1881 = dot(_1876, world_pos) + _1861.w;\n        vec3 _1883 = _1866.xyz;\n        float _1888 = dot(_1883, world_pos) + _1866.w;\n        bool _1893 = abs(_1874) > 0.5;\n        bool _1901;\n        if (!_1893)\n        {\n            _1901 = abs(_1881) > 0.5;\n        }\n        else\n        {\n            _1901 = _1893;\n        }\n        bool _1909;\n        if (!_1901)\n        {\n            _1909 = abs(_1888) > 0.5;\n        }\n        else\n        {\n            _1909 = _1901;\n        }\n        if (_1909)\n        {\n            continue;\n        }\n        float _1924 = clamp(dot(geo_normal, normalize(_1883)) * _1841.z, 0.0, 1.0);\n        if (_1924 <= 0.0)\n        {\n            continue;\n        }\n        float _1944 = (clamp((0.5 - abs(_1888)) * 10.0, 0.0, 1.0) * _1924) * _1841.x;\n        vec2 _1952 = vec2(_1874 + 0.5, 0.5 - _1881);\n        vec2 _1962 = vec2(dot(_1869, _1758), dot(_1876, _1758));\n        vec2 _1972 = vec2(dot(_1869, _1761), dot(_1876, _1761));\n        int param_8 = _1836 + 5;\n        vec4 _1977 = fa_light_texel(param_8);\n        int param_9 = _1836 + 3;\n        vec4 _1982 = fa_light_texel(param_9);\n        int param_10 = _1836 + 4;\n        vec4 _1987 = fa_light_texel(param_10);\n        float tex_a = 1.0;\n        vec3 col = _1977.xyz;\n        bool _1997 = _1982.z > _1982.x;\n        if (_1997)\n        {\n            vec4 param_11 = _1982;\n            vec2 param_12 = _1952;\n            vec2 param_13 = _1786;\n            vec2 param_14 = _1962;\n            vec2 param_15 = _1972;\n            vec4 tx = fa_decal_tile(param_11, param_12, param_13, param_14, param_15);\n            if ((_1796 > 0.5) && (_1796 < 1.5))\n            {\n                vec3 param_16 = tx.xyz;\n                vec3 _2023 = fa_dc_to_linear(param_16);\n                vec4 _6793 = tx;\n                _6793.x = _2023.x;\n                _6793.y = _2023.y;\n                _6793.z = _2023.z;\n                tx = _6793;\n            }\n            col *= tx.xyz;\n            tex_a = tx.w;\n        }\n        albedo = mix(albedo, col, vec3(clamp((_1944 * tex_a) * _1977.w, 0.0, 1.0)));\n        if (_1987.z > _1987.x)\n        {\n            vec4 param_17 = _1987;\n            vec2 param_18 = _1952;\n            vec2 param_19 = _1786;\n            vec2 param_20 = _1962;\n            vec2 param_21 = _1972;\n            vec4 _2067 = fa_decal_tile(param_17, param_18, param_19, param_20, param_21);\n            if (_1796 > 1.5)\n            {\n                vec3 param_22 = _2067.xyz;\n                vec3 _2077 = fa_dc_to_srgb(param_22);\n                _2071 = _2077;\n            }\n            else\n            {\n                _2071 = _2067.xyz;\n            }\n            vec3 _2086 = (_2071 * 2.0) - vec3(1.0);\n            vec2 _2091 = _2086.xy * _1841.y;\n            vec3 _2113 = (normalize(_1869) * _2091.x) + (normalize(_1876) * _2091.y);\n            vec3 _2116 = normalize(normal);\n            normal = normalize(mix(_2116, normalize((_2116 * max(_2086.z, 0.0500000007450580596923828125)) + (_2113 - (_2116 * dot(_2116, _2113)))), vec3(clamp(_1944 * (_1997 ? tex_a : 1.0), 0.0, 1.0))));\n        }\n    }\n}\n\nfloat fa_sheen_albedo(float ndv, float rough)\n{\n    float _3417 = min(sqrt(max(rough - 0.100000001490116119384765625, 0.0) * 1.111111164093017578125) * 6.0, 5.999000072479248046875);\n    float _3425 = min(sqrt(clamp(ndv, 0.0, 1.0)) * 8.0, 7.999000072479248046875);\n    int _3428 = int(_3417);\n    int _3431 = int(_3425);\n    float _3441 = _3425 - float(_3431);\n    int _3497 = (_3428 * 9) + _3431;\n    int _3517 = ((_3428 + 1) * 9) + _3431;\n    return mix(mix(_3492[_3497], _3492[_3497 + 1], _3441), mix(_3492[_3517], _3492[_3517 + 1], _3441), _3417 - float(_3428));\n}\n\nFaLayers fa_layers_setup(SurfaceInput i, Surface s, vec3 n, vec3 v, float metallic, float roughness, inout vec3 f0)\n{\n    bool _6636 = false;\n    float _6637 = 1.0;\n    float _6638 = 1.0;\n    float _6639 = 1.0;\n    float _6640 = 0.0;\n    float _6641 = 0.0;\n    float _6642 = 0.0;\n    float _6643 = 0.0;\n    float _6645 = 1.0;\n    bool _6646 = false;\n    vec3 _6647 = vec3(0.0);\n    float _6648 = 1.0;\n    float _6649 = 1.0;\n    float _6650 = 1.0;\n    float _6651 = 0.0;\n    float _6652 = 0.0;\n    vec3 _6653 = vec3(1.0, 0.0, 0.0);\n    vec3 _6654 = vec3(0.0, 0.0, 1.0);\n    float _6655 = 1.0;\n    float _6656 = 1.0;\n    float _3568 = clamp(s.specular, 0.0, 1.0);\n    float _3572 = clamp(s.ior, 1.0, 3.0);\n    bool _3577 = (_3568 != 1.0) || (_3572 != 1.5);\n    bool _3586;\n    if (!_3577)\n    {\n        _3586 = any(notEqual(s.specular_color, vec3(1.0)));\n    }\n    else\n    {\n        _3586 = _3577;\n    }\n    if (_3586)\n    {\n        float _3594 = (_3572 - 1.0) / (_3572 + 1.0);\n        f0 = mix(min(vec3(_3594 * _3594) * max(s.specular_color, vec3(0.0)), vec3(1.0)) * _3568, s.albedo, vec3(metallic));\n        _6637 = mix(_3568, 1.0, metallic);\n        _6636 = true;\n    }\n    float _3621 = clamp(s.clearcoat, 0.0, 1.0);\n    if (_3621 > 0.0)\n    {\n        float _3629 = clamp(s.clearcoat_roughness, 0.0500000007450580596923828125, 1.0);\n        _6640 = _3621;\n        _6641 = _3629;\n        float _3636 = _3629 * _3629;\n        _6642 = _3636;\n        _6643 = _3636 * _3636;\n        float _3648 = max(dot(i.world_normal, v), 9.9999997473787516355514526367188e-05);\n        _6645 = _3648;\n        _6638 = 1.0 - (_3621 * (0.039999999105930328369140625 + (0.959999978542327880859375 * pow(clamp(1.0 - _3648, 0.0, 1.0), 5.0))));\n        _6636 = true;\n    }\n    vec3 _3668 = max(s.sheen_color, vec3(0.0));\n    float _3677 = max(_3668.x, max(_3668.y, _3668.z));\n    if (_3677 > 0.0)\n    {\n        float _3685 = clamp(s.sheen_roughness, 0.100000001490116119384765625, 1.0);\n        _6646 = true;\n        _6647 = _3668;\n        _6648 = _3685;\n        _6649 = _3685 * _3685;\n        float param = max(dot(n, v), 9.9999997473787516355514526367188e-05);\n        float param_1 = _3685;\n        float _3702 = fa_sheen_albedo(param, param_1);\n        _6651 = _3702;\n        _6650 = 1.0 - min(_3677 * _3702, 1.0);\n        _6636 = true;\n    }\n    _6639 = _6638 * _6650;\n    float _3721 = clamp(s.anisotropy, -1.0, 1.0);\n    if (_3721 != 0.0)\n    {\n        vec3 _3736 = i.world_tangent.xyz - (n * dot(n, i.world_tangent.xyz));\n        vec3 t = _3736;\n        if (dot(_3736, _3736) < 9.9999999392252902907785028219223e-09)\n        {\n            bvec3 _3748 = bvec3(abs(n.y) < 0.9900000095367431640625);\n            t = cross(vec3(_3748.x ? vec3(0.0, 1.0, 0.0).x : vec3(1.0, 0.0, 0.0).x, _3748.y ? vec3(0.0, 1.0, 0.0).y : vec3(1.0, 0.0, 0.0).y, _3748.z ? vec3(0.0, 1.0, 0.0).z : vec3(1.0, 0.0, 0.0).z), n);\n        }\n        vec3 _3752 = t;\n        vec3 _3753 = normalize(_3752);\n        t = _3753;\n        vec3 _3778 = normalize((_3753 * cos(s.anisotropy_rotation)) + ((cross(n, _3753) * ((i.world_tangent.w < 0.0) ? (-1.0) : 1.0)) * sin(s.anisotropy_rotation)));\n        _6653 = _3778;\n        _6654 = cross(n, _3778);\n        float _3788 = roughness * roughness;\n        float _3794 = mix(_3788, 1.0, _3721 * _3721);\n        bool _3796 = _3721 > 0.0;\n        _6655 = _3796 ? _3794 : _3788;\n        _6656 = _3796 ? _3788 : _3794;\n        _6652 = _3721;\n        _6636 = true;\n    }\n    return FaLayers(_6636, _6637, _6638, _6639, _6640, _6641, _6642, _6643, i.world_normal, _6645, _6646, _6647, _6648, _6649, _6650, _6651, _6652, _6653, _6654, _6655, _6656);\n}\n\nvec3 fa_ambient_light(vec3 n)\n{\n    if (fa_mesh_fs_params[11].w > 0.5)\n    {\n        return textureLod(fa_irr_tex_fa_env_smp, n, 0.0).xyz;\n    }\n    return fa_mesh_fs_params[1].xyz;\n}\n\nvec3 fa_indirect_diffuse(vec3 n)\n{\n    if (fa_lm.z > 0.5)\n    {\n        return textureLod(fa_lightmap_fa_env_smp, fa_lm.xy, 0.0).xyz;\n    }\n    vec3 param = n;\n    return fa_ambient_light(param);\n}\n\nint fa_cluster_index(int slot, int n)\n{\n    int param = (int(fa_mesh_fs_params[19].x) + int(fa_mesh_fs_params[19].w)) + ((slot + n) >> 2);\n    vec4 t = fa_light_texel(param);\n    return int(t[(slot + n) & 3]);\n}\n\nint fa_cl_light(int n)\n{\n    if (n < fa_cl_ndir)\n    {\n        return n;\n    }\n    int param = fa_cl_slot;\n    int param_1 = n - fa_cl_ndir;\n    return fa_cluster_index(param, param_1);\n}\n\nint fa_light_base(int li)\n{\n    return li * ((fa_mesh_fs_params[1].w > 4.5) ? 8 : 4);\n}\n\nbool fa_light_baked(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 3;\n    return fa_light_texel(param_1).w > 0.5;\n}\n\nfloat fa_light_type(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 1;\n    return fa_light_texel(param_1).w;\n}\n\nvec4 fa_atlas_fetch(vec2 texel)\n{\n    return textureLod(fa_light_atlas_fa_env_smp, texel / vec2(textureSize(fa_light_atlas_fa_env_smp, 0)), 0.0);\n}\n\nvec3 fa_cookie_sample(vec2 tile_origin, vec2 uv)\n{\n    vec2 param = (tile_origin + vec2(1.0)) + (clamp(uv, vec2(0.0), vec2(1.0)) * 254.0);\n    return fa_atlas_fetch(param).xyz;\n}\n\nvec3 fa_area_point(vec3 c, vec3 axis, vec3 ru, vec3 uu, float hx, float hy, float shape, vec3 p, vec3 r)\n{\n    bool _728 = dot(r, r) > 0.5;\n    if (shape > 1.5)\n    {\n        vec3 _741 = (c - (ru * hx)) - p;\n        vec3 _747 = ru * (2.0 * hx);\n        float _753 = max(dot(_747, _747), 9.9999999392252902907785028219223e-09);\n        float _757 = dot(_741, _747);\n        float t = clamp((-_757) / _753, 0.0, 1.0);\n        if (_728)\n        {\n            float _772 = dot(r, _747);\n            float _778 = _753 - (_772 * _772);\n            if (abs(_778) > (9.9999997473787516355514526367188e-06 * _753))\n            {\n                t = clamp(((dot(r, _741) * _772) - _757) / _778, 0.0, 1.0);\n            }\n        }\n        return (p + _741) + (_747 * t);\n    }\n    vec3 q = p;\n    float _810 = dot(r, axis);\n    bool _818;\n    if (_728)\n    {\n        _818 = abs(_810) > 9.9999997473787516355514526367188e-05;\n    }\n    else\n    {\n        _818 = _728;\n    }\n    if (_818)\n    {\n        float _828 = dot(c - p, axis) / _810;\n        if (_828 > 0.0)\n        {\n            q = p + (r * _828);\n        }\n    }\n    vec3 _841 = q - c;\n    vec2 xy = vec2(dot(_841, ru), dot(_841, uu));\n    if (shape > 0.5)\n    {\n        float _856 = length(xy);\n        if (_856 > hx)\n        {\n            xy *= (hx / _856);\n        }\n    }\n    else\n    {\n        xy = clamp(xy, vec2(-hx, -hy), vec2(hx, hy));\n    }\n    return (c + (ru * xy.x)) + (uu * xy.y);\n}\n\nint fa_cube_face(vec3 d)\n{\n    vec3 _649 = abs(d);\n    float _651 = _649.x;\n    float _653 = _649.y;\n    bool _654 = _651 >= _653;\n    bool _662;\n    if (_654)\n    {\n        _662 = _651 >= _649.z;\n    }\n    else\n    {\n        _662 = _654;\n    }\n    int _663;\n    if (_662)\n    {\n        _663 = (d.x > 0.0) ? 0 : 1;\n    }\n    else\n    {\n        int _676;\n        if (_653 >= _649.z)\n        {\n            _676 = (d.y > 0.0) ? 2 : 3;\n        }\n        else\n        {\n            _676 = (d.z > 0.0) ? 4 : 5;\n        }\n        _663 = _676;\n    }\n    return _663;\n}\n\nvoid fa_cube_face_basis(int f, out vec3 fwd, out vec3 up)\n{\n    if (f == 0)\n    {\n        fwd = vec3(1.0, 0.0, 0.0);\n        up = vec3(0.0, 1.0, 0.0);\n    }\n    else\n    {\n        if (f == 1)\n        {\n            fwd = vec3(-1.0, 0.0, 0.0);\n            up = vec3(0.0, 1.0, 0.0);\n        }\n        else\n        {\n            if (f == 2)\n            {\n                fwd = vec3(0.0, 1.0, 0.0);\n                up = vec3(0.0, 0.0, 1.0);\n            }\n            else\n            {\n                if (f == 3)\n                {\n                    fwd = vec3(0.0, -1.0, 0.0);\n                    up = vec3(0.0, 0.0, -1.0);\n                }\n                else\n                {\n                    if (f == 4)\n                    {\n                        fwd = vec3(0.0, 0.0, 1.0);\n                        up = vec3(0.0, 1.0, 0.0);\n                    }\n                    else\n                    {\n                        fwd = vec3(0.0, 0.0, -1.0);\n                        up = vec3(0.0, 1.0, 0.0);\n                    }\n                }\n            }\n        }\n    }\n}\n\nfloat fa_ies_sample(vec2 tile_origin, vec3 d, vec3 axis, vec3 right, vec3 up)\n{\n    float _602 = dot(d, right);\n    float _606 = dot(d, up);\n    float _617;\n    if (((_602 * _602) + (_606 * _606)) > 1.0000000133514319600180897396058e-10)\n    {\n        _617 = atan(_606, _602) * 0.15915493667125701904296875;\n    }\n    else\n    {\n        _617 = 0.0;\n    }\n    vec2 param = tile_origin + vec2(1.0 + ((_617 - floor(_617)) * 64.0), 1.0 + (acos(clamp(dot(d, axis), -1.0, 1.0)) * 10.18591594696044921875));\n    return fa_atlas_fetch(param).x;\n}\n\nLightSample fa_light_sample_n(int li, vec3 world_pos, vec3 n)\n{\n    int param = li;\n    int _894 = fa_light_base(param);\n    bool _898 = fa_mesh_fs_params[1].w > 4.5;\n    int param_1 = _894;\n    vec4 _902 = fa_light_texel(param_1);\n    int param_2 = _894 + 1;\n    vec4 _907 = fa_light_texel(param_2);\n    float _910 = _907.w;\n    float atten = 1.0;\n    float dist = 0.0;\n    fa_light_tint = vec3(1.0);\n    bool _922 = _898 && (_910 > 2.5);\n    fa_light_is_area = _922;\n    bool _924 = _910 < 0.5;\n    vec3 l;\n    if (_924)\n    {\n        l = normalize(_902.xyz);\n        if (_898)\n        {\n            int param_3 = _894 + 6;\n            vec4 _938 = fa_light_texel(param_3);\n            if (_938.z > 0.5)\n            {\n                int param_4 = _894 + 4;\n                vec4 _948 = fa_light_texel(param_4);\n                int param_5 = _894 + 5;\n                vec4 _953 = fa_light_texel(param_5);\n                vec2 param_6 = _938.xy;\n                vec2 param_7 = fract(vec2(dot(world_pos, _948.xyz) * _948.w, (-dot(world_pos, _953.xyz)) * _953.w) + vec2(0.5));\n                fa_light_tint = fa_cookie_sample(param_6, param_7);\n            }\n        }\n    }\n    else\n    {\n        vec3 _983 = _902.xyz;\n        vec3 _985 = _983 - world_pos;\n        vec3 to_light = _985;\n        float _988 = length(_985);\n        float reach = _988;\n        bool front = true;\n        if (_922)\n        {\n            int param_8 = _894 + 7;\n            reach = max(_988 - fa_light_texel(param_8).w, 0.0);\n            int param_9 = _894 + 4;\n            vec4 _1012 = fa_light_texel(param_9);\n            int param_10 = _894 + 5;\n            vec4 _1017 = fa_light_texel(param_10);\n            int param_11 = _894 + 6;\n            vec4 _1022 = fa_light_texel(param_11);\n            float _1023 = _1022.w;\n            int param_12 = _894 + 2;\n            vec3 _1030 = normalize(fa_light_texel(param_12).xyz);\n            bool _1032 = _1023 > 1.5;\n            bool _1040;\n            if (!_1032)\n            {\n                _1040 = dot(_1030, to_light) < 0.0;\n            }\n            else\n            {\n                _1040 = _1032;\n            }\n            front = _1040;\n            vec3 r = vec3(0.0);\n            if (dot(n, n) > 0.5)\n            {\n                r = reflect(-normalize(fa_mesh_fs_params[0].xyz - world_pos), normalize(n));\n            }\n            vec3 param_13 = _983;\n            vec3 param_14 = _1030;\n            vec3 param_15 = _1012.xyz;\n            vec3 param_16 = _1017.xyz;\n            float param_17 = _1012.w;\n            float param_18 = _1017.w;\n            float param_19 = _1023;\n            vec3 param_20 = world_pos;\n            vec3 param_21 = r;\n            to_light = fa_area_point(param_13, param_14, param_15, param_16, param_17, param_18, param_19, param_20, param_21) - world_pos;\n        }\n        float _1087 = length(to_light);\n        dist = _1087;\n        l = to_light / vec3(max(_1087, 9.9999997473787516355514526367188e-05));\n        float _1101 = reach / max(_902.w, 0.001000000047497451305389404296875);\n        float _1107 = clamp(1.0 - (_1101 * _1101), 0.0, 1.0);\n        float _1109;\n        if (front)\n        {\n            _1109 = _1107 * _1107;\n        }\n        else\n        {\n            _1109 = 0.0;\n        }\n        atten = _1109;\n        bool _1120 = _910 < 2.5;\n        if ((_910 > 1.5) && _1120)\n        {\n            int param_22 = _894 + 2;\n            vec4 _1128 = fa_light_texel(param_22);\n            float _1138 = _1128.w;\n            int param_23 = _894 + 3;\n            vec4 _1143 = fa_light_texel(param_23);\n            float _1144 = _1143.x;\n            float cos_inner = _1144;\n            if (_1144 > 1.5)\n            {\n                cos_inner = mix(_1138, 1.0, 0.25);\n            }\n            atten *= smoothstep(_1138, cos_inner, dot(-l, normalize(_1128.xyz)));\n        }\n        if (_898 && (_910 < 1.5))\n        {\n            int param_24 = _894 + 6;\n            vec4 _1168 = fa_light_texel(param_24);\n            if (_1168.z > 0.5)\n            {\n                vec3 _1176 = -to_light;\n                int param_25 = _894 + 4;\n                int param_26 = _894 + 5;\n                vec3 _1190 = fa_light_texel(param_25).xyz;\n                vec3 _1194 = fa_light_texel(param_26).xyz;\n                vec3 _1203 = vec3(dot(_1176, _1190), dot(_1176, _1194), dot(_1176, cross(_1190, _1194)));\n                vec3 param_27 = _1203;\n                int _1207 = fa_cube_face(param_27);\n                int param_28 = _1207;\n                vec3 param_29;\n                vec3 param_30;\n                fa_cube_face_basis(param_28, param_29, param_30);\n                vec2 _1234 = vec2(dot(_1203, cross(param_29, param_30)), dot(_1203, param_30)) / vec2(max(dot(_1203, param_29), 9.9999997473787516355514526367188e-05));\n                int _1238 = _1207 / 3;\n                vec2 param_31 = _1168.xy + (vec2(float(_1207 - (_1238 * 3)), float(_1238)) * 256.0);\n                vec2 param_32 = vec2(0.5 + (0.5 * _1234.x), 0.5 - (0.5 * _1234.y));\n                fa_light_tint = fa_cookie_sample(param_31, param_32);\n            }\n            int param_33 = _894 + 7;\n            vec4 _1268 = fa_light_texel(param_33);\n            if (_1268.z > 0.5)\n            {\n                int param_34 = _894 + 2;\n                int param_35 = _894 + 4;\n                int param_36 = _894 + 5;\n                vec2 param_37 = _1268.xy;\n                vec3 param_38 = -l;\n                vec3 param_39 = normalize(fa_light_texel(param_34).xyz);\n                vec3 param_40 = fa_light_texel(param_35).xyz;\n                vec3 param_41 = fa_light_texel(param_36).xyz;\n                atten *= fa_ies_sample(param_37, param_38, param_39, param_40, param_41);\n            }\n        }\n        else\n        {\n            if (_898 && _1120)\n            {\n                int param_42 = _894 + 6;\n                vec4 _1315 = fa_light_texel(param_42);\n                int param_43 = _894 + 7;\n                vec4 _1320 = fa_light_texel(param_43);\n                bool _1323 = _1315.z > 0.5;\n                bool _1330;\n                if (!_1323)\n                {\n                    _1330 = _1320.z > 0.5;\n                }\n                else\n                {\n                    _1330 = _1323;\n                }\n                if (_1330)\n                {\n                    int param_44 = _894 + 2;\n                    vec4 _1337 = fa_light_texel(param_44);\n                    vec3 _1341 = normalize(_1337.xyz);\n                    int param_45 = _894 + 4;\n                    vec4 _1346 = fa_light_texel(param_45);\n                    int param_46 = _894 + 5;\n                    vec4 _1351 = fa_light_texel(param_46);\n                    if (_1323)\n                    {\n                        vec3 _1359 = -to_light;\n                        float _1366 = _1337.w;\n                        float _1382 = 0.5 / max(dot(_1359, _1341) * (sqrt(max(1.0 - (_1366 * _1366), 0.0)) / max(_1366, 0.001000000047497451305389404296875)), 9.9999997473787516355514526367188e-05);\n                        vec2 param_47 = _1315.xy;\n                        vec2 param_48 = vec2(0.5 + (dot(_1359, _1346.xyz) * _1382), 0.5 - (dot(_1359, _1351.xyz) * _1382));\n                        fa_light_tint = fa_cookie_sample(param_47, param_48);\n                    }\n                    if (_1320.z > 0.5)\n                    {\n                        vec2 param_49 = _1320.xy;\n                        vec3 param_50 = -l;\n                        vec3 param_51 = _1341;\n                        vec3 param_52 = _1346.xyz;\n                        vec3 param_53 = _1351.xyz;\n                        atten *= fa_ies_sample(param_49, param_50, param_51, param_52, param_53);\n                    }\n                }\n            }\n        }\n    }\n    vec3 _6624 = _907.xyz * atten;\n    if (_898)\n    {\n        _6624 *= fa_light_tint;\n    }\n    int _1451;\n    if (_924)\n    {\n        _1451 = 0;\n    }\n    else\n    {\n        _1451 = ((_910 > 1.5) && (_910 < 2.5)) ? 2 : 1;\n    }\n    return LightSample(l, _6624, atten, 1.0, dist, _1451);\n}\n\nfloat fa_shadow_split_at(int i)\n{\n    float _2188;\n    if (i == 0)\n    {\n        _2188 = fa_shadows[24].x;\n    }\n    else\n    {\n        float _2204;\n        if (i == 1)\n        {\n            _2204 = fa_shadows[24].y;\n        }\n        else\n        {\n            float _2212;\n            if (i == 2)\n            {\n                _2212 = fa_shadows[24].z;\n            }\n            else\n            {\n                _2212 = fa_shadows[24].w;\n            }\n            _2204 = _2212;\n        }\n        _2188 = _2204;\n    }\n    return _2188;\n}\n\nfloat fa_shadow_depth(inout vec2 uv, vec4 rect)\n{\n    uv = clamp(uv, rect.xy, rect.zw);\n    return textureLod(fa_shadow_tex_fa_shadow_smp, uv, 0.0).x;\n}\n\nfloat fa_shadow_fetch(vec2 uv, vec4 rect, vec3 conv)\n{\n    vec2 param = uv;\n    vec4 param_1 = rect;\n    float _2245 = fa_shadow_depth(param, param_1);\n    float _2249;\n    if (conv.x < 0.5)\n    {\n        _2249 = _2245;\n    }\n    else\n    {\n        _2249 = (conv.y * conv.z) / (conv.z - (_2245 * (conv.z - conv.y)));\n    }\n    return _2249;\n}\n\nfloat fa_shadow_noise()\n{\n    return fract(52.98291778564453125 * fract(dot(gl_FragCoord.xy, vec2(0.067110560834407806396484375, 0.005837149918079376220703125))));\n}\n\nvec2 fa_shadow_vogel(int k, int n, float phi)\n{\n    float _2176 = (float(k) * 2.3999631404876708984375) + phi;\n    return vec2(cos(_2176), sin(_2176)) * sqrt((float(k) + 0.5) / float(n));\n}\n\nfloat fa_shadow_filter(vec2 uv, vec4 rect, float zr, float texel_m, float unit, float reach, float plane, vec3 conv, int mode, float k)\n{\n    if (mode == 1)\n    {\n        vec2 param = uv;\n        vec4 param_1 = rect;\n        vec3 param_2 = conv;\n        return float(zr <= fa_shadow_fetch(param, param_1, param_2));\n    }\n    float _2295 = fa_shadow_noise() * 6.283185482025146484375;\n    float radius = 1.5;\n    if (mode == 2)\n    {\n        float _2304;\n        if (k < 0.0)\n        {\n            _2304 = (-k) / max(zr, 0.100000001490116119384765625);\n        }\n        else\n        {\n            _2304 = k;\n        }\n        float _2324 = clamp((_2304 * reach) / texel_m, 3.0, 12.0);\n        float sum = 0.0;\n        float cnt = 0.0;\n        for (int i = 0; i < 16; i++)\n        {\n            int param_3 = i;\n            int param_4 = 16;\n            float param_5 = _2295;\n            vec2 _2343 = fa_shadow_vogel(param_3, param_4, param_5) * _2324;\n            vec2 param_6 = uv + (_2343 * fa_shadows[26].zw);\n            vec4 param_7 = rect;\n            vec3 param_8 = conv;\n            float _2355 = fa_shadow_fetch(param_6, param_7, param_8);\n            if (_2355 < (zr - (length(_2343) * plane)))\n            {\n                sum += _2355;\n                cnt += 1.0;\n            }\n        }\n        if (cnt < 0.5)\n        {\n            return 1.0;\n        }\n        float _2381 = sum / cnt;\n        float _2391;\n        if (k < 0.0)\n        {\n            _2391 = (-k) / max(_2381, 0.0500000007450580596923828125);\n        }\n        else\n        {\n            _2391 = k;\n        }\n        radius = clamp(((max(zr - _2381, 0.0) * unit) * _2391) / texel_m, 1.5, 16.0);\n    }\n    float lit = 0.0;\n    int _2413 = (mode == 2) ? 24 : 16;\n    for (int i_1 = 0; i_1 < _2413; i_1++)\n    {\n        int param_9 = i_1;\n        int param_10 = _2413;\n        float param_11 = _2295;\n        vec2 _2432 = fa_shadow_vogel(param_9, param_10, param_11) * radius;\n        vec2 param_12 = uv + (_2432 * fa_shadows[26].zw);\n        vec4 param_13 = rect;\n        vec3 param_14 = conv;\n        lit += float((zr - (length(_2432) * plane)) <= fa_shadow_fetch(param_12, param_13, param_14));\n    }\n    return lit / float(_2413);\n}\n\nfloat fa_shadow_cascade(int ci, vec3 world, vec3 n, vec3 l)\n{\n    float _2474 = max(fa_shadows[ci * 1 + 20].y, 0.001000000047497451305389404296875);\n    float _2479 = clamp(dot(n, l), 0.0, 1.0);\n    float _2485 = sqrt(1.0 - (_2479 * _2479));\n    float _2492 = min(_2485 / max(_2479, 0.20000000298023223876953125), 4.0);\n    float _2497;\n    if (fa_shadows[26].y > 0.0)\n    {\n        _2497 = fa_shadows[26].y;\n    }\n    else\n    {\n        _2497 = 1.5 * fa_shadows[ci * 1 + 20].x;\n    }\n    vec4 _2522 = mat4(fa_shadows[ci * 4 + 0], fa_shadows[ci * 4 + 1], fa_shadows[ci * 4 + 2], fa_shadows[ci * 4 + 3]) * vec4(world + (n * (_2497 * _2485)), 1.0);\n    float _2529 = _2522.x;\n    bool _2532 = _2529 < fa_shadows[ci * 1 + 16].x;\n    bool _2541;\n    if (!_2532)\n    {\n        _2541 = _2529 > fa_shadows[ci * 1 + 16].z;\n    }\n    else\n    {\n        _2541 = _2532;\n    }\n    bool _2550;\n    if (!_2541)\n    {\n        _2550 = _2522.y < fa_shadows[ci * 1 + 16].y;\n    }\n    else\n    {\n        _2550 = _2541;\n    }\n    bool _2559;\n    if (!_2550)\n    {\n        _2559 = _2522.y > fa_shadows[ci * 1 + 16].w;\n    }\n    else\n    {\n        _2559 = _2550;\n    }\n    bool _2566;\n    if (!_2559)\n    {\n        _2566 = _2522.z > 1.0;\n    }\n    else\n    {\n        _2566 = _2559;\n    }\n    if (_2566)\n    {\n        return -1.0;\n    }\n    float _2574;\n    if (fa_shadows[26].x > 0.0)\n    {\n        _2574 = fa_shadows[26].x;\n    }\n    else\n    {\n        _2574 = 1.5 * fa_shadows[ci * 1 + 20].x;\n    }\n    vec2 param = _2522.xy;\n    vec4 param_1 = fa_shadows[ci * 1 + 16];\n    float param_2 = _2522.z - ((_2574 * (1.0 + (0.5 * _2492))) / _2474);\n    float param_3 = fa_shadows[ci * 1 + 20].x;\n    float param_4 = _2474;\n    float param_5 = _2474 * 0.25;\n    float param_6 = ((fa_shadows[ci * 1 + 20].x * min(_2492, 3.0)) * 0.5) / _2474;\n    vec3 param_7 = vec3(0.0);\n    int param_8 = int(fa_shadows[25].z + 0.5);\n    float param_9 = fa_shadows[25].w;\n    return fa_shadow_filter(param, param_1, param_2, param_3, param_4, param_5, param_6, param_7, param_8, param_9);\n}\n\nfloat fa_shadow_sun(vec3 world, vec3 n, vec3 l)\n{\n    if (fa_mesh_fs_params[5].z < 0.5)\n    {\n        return 1.0;\n    }\n    int _2962 = int(fa_shadows[25].x + 0.5);\n    if (_2962 < 1)\n    {\n        return 1.0;\n    }\n    float _2977 = dot(world - fa_shadows[27].xyz, fa_shadows[28].xyz);\n    int param = _2962 - 1;\n    if (_2977 > fa_shadow_split_at(param))\n    {\n        return 1.0;\n    }\n    int ci = 0;\n    bool _2989 = _2962 > 1;\n    bool _2996;\n    if (_2989)\n    {\n        _2996 = _2977 > fa_shadows[24].x;\n    }\n    else\n    {\n        _2996 = _2989;\n    }\n    if (_2996)\n    {\n        ci = 1;\n    }\n    bool _3000 = _2962 > 2;\n    bool _3007;\n    if (_3000)\n    {\n        _3007 = _2977 > fa_shadows[24].y;\n    }\n    else\n    {\n        _3007 = _3000;\n    }\n    if (_3007)\n    {\n        ci = 2;\n    }\n    bool _3011 = _2962 > 3;\n    bool _3018;\n    if (_3011)\n    {\n        _3018 = _2977 > fa_shadows[24].z;\n    }\n    else\n    {\n        _3018 = _3011;\n    }\n    if (_3018)\n    {\n        ci = 3;\n    }\n    float s = -1.0;\n    for (int k = 0; k < 4; k++)\n    {\n        if (ci >= _2962)\n        {\n            break;\n        }\n        int param_1 = ci;\n        vec3 param_2 = world;\n        vec3 param_3 = n;\n        vec3 param_4 = l;\n        float _3044 = fa_shadow_cascade(param_1, param_2, param_3, param_4);\n        s = _3044;\n        if (_3044 >= 0.0)\n        {\n            break;\n        }\n        ci++;\n    }\n    if (s < 0.0)\n    {\n        return 1.0;\n    }\n    if (fa_shadows[25].y > 0.0)\n    {\n        float _3069;\n        if (ci > 0)\n        {\n            int param_5 = ci - 1;\n            _3069 = fa_shadow_split_at(param_5);\n        }\n        else\n        {\n            _3069 = fa_shadows[28].w;\n        }\n        int param_6 = ci;\n        float _3088 = fa_shadows[25].y * max(fa_shadow_split_at(param_6) - _3069, 9.9999997473787516355514526367188e-05);\n        int param_7 = ci;\n        float _3099 = clamp((_2977 - (fa_shadow_split_at(param_7) - _3088)) / _3088, 0.0, 1.0);\n        if (_3099 > 0.0)\n        {\n            float s2 = 1.0;\n            if ((ci + 1) < _2962)\n            {\n                int param_8 = ci + 1;\n                vec3 param_9 = world;\n                vec3 param_10 = n;\n                vec3 param_11 = l;\n                float _3120 = fa_shadow_cascade(param_8, param_9, param_10, param_11);\n                s2 = _3120;\n                if (_3120 < 0.0)\n                {\n                    s2 = s;\n                }\n            }\n            s = mix(s, s2, _3099);\n        }\n    }\n    return s;\n}\n\nfloat fa_shadow_factor(vec3 n, vec3 l)\n{\n    vec3 param = fa_world_pos;\n    vec3 param_1 = n;\n    vec3 param_2 = l;\n    return fa_shadow_sun(param, param_1, param_2);\n}\n\nfloat fa_shadow_local(int li, vec3 world, vec3 n, vec3 l)\n{\n    bool _2632 = fa_mesh_fs_params[5].z < 0.5;\n    bool _2639;\n    if (!_2632)\n    {\n        _2639 = fa_shadows[29].x < 0.5;\n    }\n    else\n    {\n        _2639 = _2632;\n    }\n    if (_2639)\n    {\n        return 1.0;\n    }\n    int param = (int(fa_shadows[29].x + 0.5) - 1) + li;\n    vec4 _2652 = fa_light_texel(param);\n    float _2653 = _2652.x;\n    if (_2653 < 0.0)\n    {\n        return 1.0;\n    }\n    int _2662 = int(_2653 + 0.5);\n    int param_1 = _2662;\n    vec4 _2666 = fa_light_texel(param_1);\n    int param_2 = _2662 + 1;\n    vec4 _2671 = fa_light_texel(param_2);\n    float fade = 1.0;\n    float _2674 = _2666.y;\n    if (_2674 > 0.0)\n    {\n        float _2691 = 1.0 - smoothstep(0.75 * _2674, _2674, length(world - fa_shadows[27].xyz));\n        fade = _2691;\n        if (_2691 <= 0.0)\n        {\n            return 1.0;\n        }\n    }\n    int face = 0;\n    if (_2666.x > 1.5)\n    {\n        int param_3 = li;\n        int param_4 = fa_light_base(param_3);\n        vec3 param_5 = world - fa_light_texel(param_4).xyz;\n        face = fa_cube_face(param_5);\n    }\n    int _2720 = (_2662 + 2) + (face * 6);\n    int param_6 = _2720;\n    int param_7 = _2720 + 1;\n    int param_8 = _2720 + 3;\n    vec4 _2734 = fa_light_texel(param_8);\n    int param_9 = _2720 + 4;\n    vec4 _2739 = fa_light_texel(param_9);\n    int param_10 = _2720 + 5;\n    vec4 _2744 = fa_light_texel(param_10);\n    float _2756 = _2744.x * max(dot(_2734, vec4(world, 1.0)), 0.001000000047497451305389404296875);\n    float _2761 = clamp(dot(n, l), 0.0, 1.0);\n    float _2784 = clamp(dot(n, _2734.xyz), -1.0, 1.0);\n    int param_11 = li;\n    int param_12 = fa_light_base(param_11);\n    float _2808 = min(sqrt(1.0 - (_2784 * _2784)) / max(abs(dot(n, world - fa_light_texel(param_12).xyz)) / max(dot(_2734, vec4(world, 1.0)), 0.001000000047497451305389404296875), 0.20000000298023223876953125), 4.0);\n    float _2811 = _2671.y;\n    float _2813;\n    if (_2811 > 0.0)\n    {\n        _2813 = _2811;\n    }\n    else\n    {\n        _2813 = 1.5 * _2756;\n    }\n    vec4 _2833 = vec4(world + (n * (_2813 * sqrt(1.0 - (_2761 * _2761)))), 1.0);\n    float _2837 = dot(_2734, _2833);\n    float _2840 = _2744.y;\n    if (_2837 < _2840)\n    {\n        return 1.0;\n    }\n    vec2 _2855 = vec2(dot(fa_light_texel(param_6), _2833), dot(fa_light_texel(param_7), _2833)) / vec2(_2837);\n    float _2857 = _2855.x;\n    bool _2860 = _2857 < _2739.x;\n    bool _2869;\n    if (!_2860)\n    {\n        _2869 = _2857 > _2739.z;\n    }\n    else\n    {\n        _2869 = _2860;\n    }\n    bool _2878;\n    if (!_2869)\n    {\n        _2878 = _2855.y < _2739.y;\n    }\n    else\n    {\n        _2878 = _2869;\n    }\n    bool _2887;\n    if (!_2878)\n    {\n        _2887 = _2855.y > _2739.w;\n    }\n    else\n    {\n        _2887 = _2878;\n    }\n    if (_2887)\n    {\n        return 1.0;\n    }\n    float _2893 = _2671.x;\n    float _2895;\n    if (_2893 > 0.0)\n    {\n        _2895 = _2893;\n    }\n    else\n    {\n        _2895 = 1.5 * _2756;\n    }\n    vec2 param_13 = _2855;\n    vec4 param_14 = _2739;\n    float param_15 = _2837 - (_2895 * (1.0 + (0.5 * _2808)));\n    float param_16 = _2756;\n    float param_17 = 1.0;\n    float param_18 = _2744.z * 0.25;\n    float param_19 = (_2756 * min(_2808, 3.0)) * 0.5;\n    vec3 param_20 = vec3(1.0, _2840, _2744.z);\n    int param_21 = int(_2666.z + 0.5);\n    float param_22 = _2666.w;\n    return mix(1.0, fa_shadow_filter(param_13, param_14, param_15, param_16, param_17, param_18, param_19, param_20, param_21, param_22), fade);\n}\n\nLightSample fa_light_shadowed(int li, vec3 world_pos, vec3 gn)\n{\n    bool _4340 = fa_lm.z > 0.5;\n    bool _4346;\n    if (_4340)\n    {\n        int param = li;\n        _4346 = fa_light_baked(param);\n    }\n    else\n    {\n        _4346 = _4340;\n    }\n    if (_4346)\n    {\n        int param_1 = li;\n        return LightSample(vec3(0.0, 1.0, 0.0), vec3(0.0), 0.0, 1.0, 0.0, int(fa_light_type(param_1) + 0.5));\n    }\n    int param_2 = li;\n    vec3 param_3 = world_pos;\n    vec3 param_4 = gn;\n    LightSample _4370 = fa_light_sample_n(param_2, param_3, param_4);\n    vec3 _6693 = _4370.color;\n    float _6695 = _4370.shadow;\n    if ((_4370.type == 0) && (li == 0))\n    {\n        vec3 param_5 = gn;\n        vec3 param_6 = _4370.direction;\n        float _4384 = fa_shadow_factor(param_5, param_6);\n        _6695 = _4384;\n        _6693 *= _4384;\n    }\n    else\n    {\n        bool _4395 = _4370.type != 0;\n        bool _4401;\n        if (_4395)\n        {\n            _4401 = _4370.attenuation > 0.0;\n        }\n        else\n        {\n            _4401 = _4395;\n        }\n        if (_4401)\n        {\n            int param_7 = li;\n            vec3 param_8 = world_pos;\n            vec3 param_9 = gn;\n            vec3 param_10 = _4370.direction;\n            float _4413 = fa_shadow_local(param_7, param_8, param_9, param_10);\n            _6695 = _4413;\n            _6693 *= _4413;\n        }\n    }\n    return LightSample(_4370.direction, _6693, _4370.attenuation, _6695, _4370._distance, _4370.type);\n}\n\nvec3 fa_ltc_tangent(vec3 n, vec3 v)\n{\n    vec3 _4453 = v - (n * dot(v, n));\n    vec3 t = _4453;\n    float _4457 = dot(_4453, _4453);\n    float l2 = _4457;\n    if (_4457 < 1.0000000133514319600180897396058e-10)\n    {\n        vec3 _4467;\n        if (abs(n.z) < 0.999000012874603271484375)\n        {\n            _4467 = cross(n, vec3(0.0, 0.0, 1.0));\n        }\n        else\n        {\n            _4467 = cross(n, vec3(1.0, 0.0, 0.0));\n        }\n        t = _4467;\n        l2 = dot(_4467, _4467);\n    }\n    return t * inversesqrt(l2);\n}\n\nvec3 fa_ltc_local(vec3 t1, vec3 n, vec3 p)\n{\n    return vec3(dot(t1, p), dot(cross(n, t1), p), dot(n, p));\n}\n\nvec3 fa_ltc_edge_vector(vec3 a, vec3 b)\n{\n    float _4502 = dot(a, a);\n    float _4506 = dot(b, b);\n    if ((_4502 < 1.0000000195414813782625560981111e-24) || (_4506 < 1.0000000195414813782625560981111e-24))\n    {\n        return vec3(0.0);\n    }\n    vec3 _4520 = a * inversesqrt(_4502);\n    vec3 _4525 = b * inversesqrt(_4506);\n    float _4529 = dot(_4520, _4525);\n    float _4532 = abs(_4529);\n    float g = (((((((((((0.0416471660137176513671875 * _4532) - 0.1924748718738555908203125) * _4532) + 0.4179156124591827392578125) * _4532) - 0.616057217121124267578125) * _4532) + 0.777722418308258056640625) * _4532) - 0.999542415142059326171875) * _4532) + 1.570791721343994140625;\n    if (_4529 < 0.0)\n    {\n        g = (3.1415927410125732421875 * inversesqrt(max(1.0 - (_4529 * _4529), 1.0000000116860974230803549289703e-07))) - g;\n    }\n    return cross(_4520, _4525) * g;\n}\n\nvoid fa_ltc_clip_edge(vec3 a, vec3 b, inout vec3 sum, inout vec3 leave, inout vec3 enter, inout vec2 seen)\n{\n    bool _4589 = a.z > 0.0;\n    bool _4593 = b.z > 0.0;\n    if (_4589 && _4593)\n    {\n        vec3 param = a;\n        vec3 param_1 = b;\n        sum += fa_ltc_edge_vector(param, param_1);\n    }\n    else\n    {\n        if (_4589 != _4593)\n        {\n            vec3 _4628 = a + ((b - a) * (a.z / (a.z - b.z)));\n            _4628.z = 0.0;\n            if (_4589)\n            {\n                vec3 param_2 = a;\n                vec3 param_3 = _4628;\n                sum += fa_ltc_edge_vector(param_2, param_3);\n                leave = _4628;\n                seen.x = 1.0;\n            }\n            else\n            {\n                vec3 param_4 = _4628;\n                vec3 param_5 = b;\n                sum += fa_ltc_edge_vector(param_4, param_5);\n                enter = _4628;\n                seen.y = 1.0;\n            }\n        }\n    }\n}\n\nfloat fa_ltc_quad(vec4 abcd, vec3 p0, vec3 p1, vec3 p2, vec3 p3)\n{\n    vec3 _4677 = vec3((abcd.x * p0.x) + (abcd.y * p0.z), p0.y, (abcd.z * p0.x) + (abcd.w * p0.z));\n    vec3 _4703 = vec3((abcd.x * p1.x) + (abcd.y * p1.z), p1.y, (abcd.z * p1.x) + (abcd.w * p1.z));\n    vec3 _4729 = vec3((abcd.x * p2.x) + (abcd.y * p2.z), p2.y, (abcd.z * p2.x) + (abcd.w * p2.z));\n    vec3 _4755 = vec3((abcd.x * p3.x) + (abcd.y * p3.z), p3.y, (abcd.z * p3.x) + (abcd.w * p3.z));\n    vec3 sum = vec3(0.0);\n    vec3 leave = vec3(0.0);\n    vec3 enter = vec3(0.0);\n    vec3 param = _4677;\n    vec3 param_1 = _4703;\n    vec3 param_2 = vec3(0.0);\n    vec3 param_3 = vec3(0.0);\n    vec3 param_4 = vec3(0.0);\n    vec2 param_5 = vec2(0.0);\n    fa_ltc_clip_edge(param, param_1, param_2, param_3, param_4, param_5);\n    sum = param_2;\n    leave = param_3;\n    enter = param_4;\n    vec3 param_6 = _4703;\n    vec3 param_7 = _4729;\n    vec3 param_8 = param_2;\n    vec3 param_9 = param_3;\n    vec3 param_10 = param_4;\n    vec2 param_11 = param_5;\n    fa_ltc_clip_edge(param_6, param_7, param_8, param_9, param_10, param_11);\n    sum = param_8;\n    leave = param_9;\n    enter = param_10;\n    vec3 param_12 = _4729;\n    vec3 param_13 = _4755;\n    vec3 param_14 = param_8;\n    vec3 param_15 = param_9;\n    vec3 param_16 = param_10;\n    vec2 param_17 = param_11;\n    fa_ltc_clip_edge(param_12, param_13, param_14, param_15, param_16, param_17);\n    sum = param_14;\n    leave = param_15;\n    enter = param_16;\n    vec3 param_18 = _4755;\n    vec3 param_19 = _4677;\n    vec3 param_20 = param_14;\n    vec3 param_21 = param_15;\n    vec3 param_22 = param_16;\n    vec2 param_23 = param_17;\n    fa_ltc_clip_edge(param_18, param_19, param_20, param_21, param_22, param_23);\n    sum = param_20;\n    leave = param_21;\n    enter = param_22;\n    if ((param_23.x * param_23.y) > 0.5)\n    {\n        vec3 param_24 = leave;\n        vec3 param_25 = enter;\n        sum += fa_ltc_edge_vector(param_24, param_25);\n    }\n    return sum.z * 0.15915493667125701904296875;\n}\n\nfloat fa_ltc_rect(vec4 abcd, vec3 center, vec3 ex, vec3 ey)\n{\n    vec4 param = abcd;\n    vec3 param_1 = (center - ex) - ey;\n    vec3 param_2 = (center + ex) - ey;\n    vec3 param_3 = (center + ex) + ey;\n    vec3 param_4 = (center - ex) + ey;\n    return abs(fa_ltc_quad(param, param_1, param_2, param_3, param_4));\n}\n\nfloat fa_area_form(vec4 m, float shape, vec3 pc, vec3 ex, vec3 ey)\n{\n    if ((shape < 0.5) || (shape > 1.5))\n    {\n        vec4 param = m;\n        vec3 param_1 = pc;\n        vec3 param_2 = ex;\n        vec3 param_3 = ey;\n        return fa_ltc_rect(param, param_1, param_2, param_3);\n    }\n    vec3 _4905 = (pc + (ex * 0.92387950420379638671875)) + (ey * 0.3826834261417388916015625);\n    vec3 _4929 = (pc - (ex * 0.92387950420379638671875)) + (ey * 0.3826834261417388916015625);\n    vec3 _4945 = (pc - (ex * 0.3826834261417388916015625)) - (ey * 0.92387950420379638671875);\n    vec4 param_4 = m;\n    vec3 param_5 = _4905;\n    vec3 param_6 = (pc + (ex * 0.3826834261417388916015625)) + (ey * 0.92387950420379638671875);\n    vec3 param_7 = (pc - (ex * 0.3826834261417388916015625)) + (ey * 0.92387950420379638671875);\n    vec3 param_8 = _4929;\n    vec4 param_9 = m;\n    vec3 param_10 = _4905;\n    vec3 param_11 = _4929;\n    vec3 param_12 = (pc - (ex * 0.92387950420379638671875)) - (ey * 0.3826834261417388916015625);\n    vec3 param_13 = _4945;\n    vec4 param_14 = m;\n    vec3 param_15 = _4905;\n    vec3 param_16 = _4945;\n    vec3 param_17 = (pc + (ex * 0.3826834261417388916015625)) - (ey * 0.92387950420379638671875);\n    vec3 param_18 = (pc + (ex * 0.92387950420379638671875)) - (ey * 0.3826834261417388916015625);\n    return abs((fa_ltc_quad(param_4, param_5, param_6, param_7, param_8) + fa_ltc_quad(param_9, param_10, param_11, param_12, param_13)) + fa_ltc_quad(param_14, param_15, param_16, param_17, param_18));\n}\n\nvec2 fa_ltc_uv(float roughness, float ndv)\n{\n    return ((vec2(clamp((roughness - 0.0500000007450580596923828125) * 1.0526316165924072265625, 0.0, 1.0), sqrt(clamp(1.0 - ndv, 0.0, 1.0))) * 63.0) + vec2(0.5)) * vec2(0.015625);\n}\n\nvec3 fa_area_shade(int li, vec3 world_pos, vec3 n, vec3 v, vec3 diffuse_color, vec3 f0, float f90, float roughness, float ndv, float window)\n{\n    int param = li;\n    int _5003 = fa_light_base(param);\n    int param_1 = _5003;\n    int param_2 = _5003 + 1;\n    int param_3 = _5003 + 2;\n    int param_4 = _5003 + 4;\n    vec4 _5025 = fa_light_texel(param_4);\n    int param_5 = _5003 + 5;\n    vec4 _5030 = fa_light_texel(param_5);\n    int param_6 = _5003 + 6;\n    vec4 _5035 = fa_light_texel(param_6);\n    float _5036 = _5035.w;\n    vec3 _5041 = fa_light_texel(param_1).xyz - world_pos;\n    bool _5043 = _5036 < 1.5;\n    bool _5050;\n    if (_5043)\n    {\n        _5050 = dot(normalize(fa_light_texel(param_3).xyz), _5041) >= 0.0;\n    }\n    else\n    {\n        _5050 = _5043;\n    }\n    if (_5050)\n    {\n        return vec3(0.0);\n    }\n    bool _5059 = (_5036 > 0.5) && _5043;\n    float _5063 = _5059 ? 1.0539000034332275390625 : 1.0;\n    vec3 _5066 = _5025.xyz;\n    float _5068 = _5025.w;\n    vec3 _5074 = _5030.xyz;\n    float _5076 = _5030.w;\n    vec3 up = _5074 * (_5076 * _5063);\n    float _5082;\n    if (_5059)\n    {\n        _5082 = (3.1415927410125732421875 * _5068) * _5068;\n    }\n    else\n    {\n        _5082 = (4.0 * _5068) * _5076;\n    }\n    if (_5036 > 1.5)\n    {\n        vec3 _5108 = cross(_5066, -_5041);\n        vec3 perp = _5108;\n        float _5112 = dot(_5108, _5108);\n        vec3 _5115;\n        if (_5112 > 1.0000000133514319600180897396058e-10)\n        {\n            _5115 = perp * inversesqrt(_5112);\n        }\n        else\n        {\n            _5115 = _5074;\n        }\n        perp = _5115;\n        up = _5115 * _5076;\n    }\n    float _5136 = max(_5082, 9.9999999747524270787835121154785e-07);\n    vec3 param_7 = n;\n    vec3 param_8 = v;\n    vec3 _5146 = fa_ltc_tangent(param_7, param_8);\n    vec3 param_9 = _5146;\n    vec3 param_10 = n;\n    vec3 param_11 = _5041;\n    vec3 _5154 = fa_ltc_local(param_9, param_10, param_11);\n    vec3 param_12 = _5146;\n    vec3 param_13 = n;\n    vec3 param_14 = _5066 * (_5068 * _5063);\n    vec3 _5162 = fa_ltc_local(param_12, param_13, param_14);\n    vec3 param_15 = _5146;\n    vec3 param_16 = n;\n    vec3 param_17 = up;\n    vec3 _5170 = fa_ltc_local(param_15, param_16, param_17);\n    vec4 param_18 = vec4(1.0, 0.0, 0.0, 1.0);\n    float param_19 = _5036;\n    vec3 param_20 = _5154;\n    vec3 param_21 = _5162;\n    vec3 param_22 = _5170;\n    float param_23 = roughness;\n    float param_24 = ndv;\n    vec2 _5189 = fa_ltc_uv(param_23, param_24) * 64.0;\n    vec2 param_25 = _5189;\n    vec2 param_26 = _5189 + vec2(64.0, 0.0);\n    vec4 _5199 = fa_atlas_fetch(param_26);\n    vec4 param_27 = fa_atlas_fetch(param_25);\n    float param_28 = _5036;\n    vec3 param_29 = _5154;\n    vec3 param_30 = _5162;\n    vec3 param_31 = _5170;\n    return (((diffuse_color * fa_area_form(param_18, param_19, param_20, param_21, param_22)) + (((f0 * _5199.x) + ((vec3(f90) - f0) * _5199.y)) * fa_area_form(param_27, param_28, param_29, param_30, param_31))) * fa_light_texel(param_2).xyz) * ((((3.1415927410125732421875 * dot(_5041, _5041)) + _5136) / _5136) * window);\n}\n\nvec3 fa_light_rgb(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 1;\n    return fa_light_texel(param_1).xyz;\n}\n\nfloat fa_d_charlie(float alpha, float ndh)\n{\n    float _4043 = 1.0 / alpha;\n    return ((2.0 + _4043) * pow(sqrt(max(1.0 - (ndh * ndh), 9.9999997473787516355514526367188e-05)), _4043)) * 0.15915493667125701904296875;\n}\n\nfloat fa_v_ashikhmin(float ndl, float ndv)\n{\n    return clamp(0.25 / max((ndl + ndv) - (ndl * ndv), 9.9999997473787516355514526367188e-05), 0.0, 1.0);\n}\n\nfloat fa_layers_coat(FaLayers L, vec3 l, vec3 h, float vdh)\n{\n    float _4078 = max(dot(L.nc, l), 0.0);\n    float _4084 = max(dot(L.nc, h), 0.0);\n    float _4093 = ((_4084 * _4084) * (L.coat_a2 - 1.0)) + 1.0;\n    return (((L.coat * (0.039999999105930328369140625 + (0.959999978542327880859375 * pow(clamp(1.0 - vdh, 0.0, 1.0), 5.0)))) * (((L.coat_a2 / ((3.1415927410125732421875 * _4093) * _4093)) * (0.5 / max(mix((2.0 * _4078) * L.coat_ndv, _4078 + L.coat_ndv, L.coat_alpha), 9.9999997473787516355514526367188e-05))) * 3.1415927410125732421875)) * step(9.9999997473787516355514526367188e-05, _4078)) * _4078;\n}\n\nvec3 fa_area_layers(FaLayers L, int li, vec3 world_pos, vec3 n, vec3 v, vec3 l, vec3 diffuse_color, vec3 f0, float roughness, float ndv, float window)\n{\n    int param = li;\n    vec3 param_1 = world_pos;\n    vec3 param_2 = n;\n    vec3 param_3 = v;\n    vec3 param_4 = diffuse_color;\n    vec3 param_5 = f0;\n    float param_6 = L.f90;\n    float param_7 = roughness;\n    float param_8 = ndv;\n    float param_9 = window;\n    float _5267;\n    if (L.sheen_on)\n    {\n        _5267 = L.sheen_scale;\n    }\n    else\n    {\n        _5267 = 1.0;\n    }\n    vec3 result = fa_area_shade(param, param_1, param_2, param_3, param_4, param_5, param_6, param_7, param_8, param_9) * (L.keep * _5267);\n    vec3 _5280 = normalize(l + v);\n    int param_10 = li;\n    vec3 _5291 = fa_light_rgb(param_10) * window;\n    if (L.sheen_on)\n    {\n        float _5300 = max(dot(n, l), 0.0);\n        float param_11 = L.sheen_alpha;\n        float param_12 = max(dot(n, _5280), 0.0);\n        float param_13 = _5300;\n        float param_14 = ndv;\n        result += ((L.sheen * _5291) * (((((fa_d_charlie(param_11, param_12) * fa_v_ashikhmin(param_13, param_14)) * 3.1415927410125732421875) * step(9.9999997473787516355514526367188e-05, _5300)) * _5300) * L.keep));\n    }\n    if (L.coat > 0.0)\n    {\n        FaLayers param_15 = L;\n        vec3 param_16 = l;\n        vec3 param_17 = _5280;\n        float param_18 = max(dot(v, _5280), 0.0);\n        result += (_5291 * fa_layers_coat(param_15, param_16, param_17, param_18));\n    }\n    return result;\n}\n\nfloat fa_d_ggx_aniso(float ndh, float tdh, float bdh, float at, float ab)\n{\n    float _3946 = tdh / at;\n    float _3950 = bdh / ab;\n    float _3962 = ((_3946 * _3946) + (_3950 * _3950)) + (ndh * ndh);\n    return 1.0 / ((((3.1415927410125732421875 * at) * ab) * _3962) * _3962);\n}\n\nfloat fa_lambda_ggx_aniso(float n, float t, float b, float at, float ab)\n{\n    return 0.5 * (sqrt(1.0 + (((((at * at) * t) * t) + (((ab * ab) * b) * b)) / max(n * n, 9.9999999392252902907785028219223e-09))) - 1.0);\n}\n\nfloat fa_v_ggx_aniso(float ndl, float ndv, float tdv, float bdv, float tdl, float bdl, float at, float ab)\n{\n    float param = ndv;\n    float param_1 = tdv;\n    float param_2 = bdv;\n    float param_3 = at;\n    float param_4 = ab;\n    float param_5 = ndl;\n    float param_6 = tdl;\n    float param_7 = bdl;\n    float param_8 = at;\n    float param_9 = ab;\n    return clamp(1.0 / ((4.0 * max(ndl * ndv, 9.9999997473787516355514526367188e-05)) * ((1.0 + fa_lambda_ggx_aniso(param, param_1, param_2, param_3, param_4)) + fa_lambda_ggx_aniso(param_5, param_6, param_7, param_8, param_9))), 0.0, 1.0);\n}\n\nvec3 fa_layers_light(FaLayers L, vec3 diffuse_color, vec3 f0, vec3 n, vec3 v, vec3 l, vec3 h, float ndl, float ndv, float ndh, float vdh, float alpha, float a2)\n{\n    float _4142 = step(9.9999997473787516355514526367188e-05, ndl);\n    float d_ggx;\n    float vis;\n    if (L.aniso != 0.0)\n    {\n        float param = ndh;\n        float param_1 = dot(L.t, h);\n        float param_2 = dot(L.b, h);\n        float param_3 = L.at;\n        float param_4 = L.ab;\n        d_ggx = fa_d_ggx_aniso(param, param_1, param_2, param_3, param_4);\n        float param_5 = ndl;\n        float param_6 = ndv;\n        float param_7 = dot(L.t, v);\n        float param_8 = dot(L.b, v);\n        float param_9 = dot(L.t, l);\n        float param_10 = dot(L.b, l);\n        float param_11 = L.at;\n        float param_12 = L.ab;\n        vis = fa_v_ggx_aniso(param_5, param_6, param_7, param_8, param_9, param_10, param_11, param_12);\n    }\n    else\n    {\n        float _4221 = ((ndh * ndh) * (a2 - 1.0)) + 1.0;\n        d_ggx = a2 / ((3.1415927410125732421875 * _4221) * _4221);\n        vis = 0.5 / max(mix((2.0 * ndl) * ndv, ndl + ndv, alpha), 9.9999997473787516355514526367188e-05);\n    }\n    vec3 base = diffuse_color + (((f0 + ((vec3(L.f90) - f0) * pow(clamp(1.0 - vdh, 0.0, 1.0), 5.0))) * ((d_ggx * vis) * 3.1415927410125732421875)) * _4142);\n    if (L.sheen_on)\n    {\n        float param_13 = L.sheen_alpha;\n        float param_14 = ndh;\n        float param_15 = ndl;\n        float param_16 = ndv;\n        base = (base * L.sheen_scale) + (L.sheen * (((fa_d_charlie(param_13, param_14) * fa_v_ashikhmin(param_15, param_16)) * 3.1415927410125732421875) * _4142));\n    }\n    vec3 result = base * (L.keep * ndl);\n    if (L.coat > 0.0)\n    {\n        FaLayers param_17 = L;\n        vec3 param_18 = l;\n        vec3 param_19 = h;\n        float param_20 = vdh;\n        result += vec3(fa_layers_coat(param_17, param_18, param_19, param_20));\n    }\n    return result;\n}\n\nvec2 fa_env_brdf(float rough, float ndv)\n{\n    vec4 _3349 = (vec4(-1.0, -0.0274999998509883880615234375, -0.572000026702880859375, 0.02199999988079071044921875) * rough) + vec4(1.0, 0.0425000004470348358154296875, 1.03999996185302734375, -0.039999999105930328369140625);\n    float _3352 = _3349.x;\n    return (vec2(-1.03999996185302734375, 1.03999996185302734375) * ((min(_3352 * _3352, exp2((-9.27999973297119140625) * ndv)) * _3352) + _3349.y)) + _3349.zw;\n}\n\nvec3 fa_environment(vec3 d, float rough)\n{\n    if (fa_mesh_fs_params[11].w > 0.5)\n    {\n        return textureLod(fa_env_tex_fa_env_smp, d, clamp(rough, 0.0, 1.0) * fa_mesh_fs_params[12].w).xyz;\n    }\n    float _3255 = rough * rough;\n    float _3285 = 0.60000002384185791015625 * _3255;\n    return mix(mix(fa_mesh_fs_params[12].xyz * 0.550000011920928955078125, mix(fa_mesh_fs_params[12].xyz, fa_mesh_fs_params[11].xyz, vec3(pow(clamp(d.y * (1.0 - (0.699999988079071044921875 * _3255)), 0.0, 1.0), 0.550000011920928955078125))), vec3(smoothstep((-0.0500000007450580596923828125) - _3285, 0.0500000007450580596923828125 + _3285, d.y))), ((fa_mesh_fs_params[11].xyz + fa_mesh_fs_params[12].xyz) * 0.5) * 0.800000011920928955078125, vec3(_3255 * 0.60000002384185791015625));\n}\n\nvec3 fa_layers_ibl(FaLayers L, vec3 n, vec3 v, vec3 f0, float roughness)\n{\n    vec3 rn = n;\n    if (L.aniso != 0.0)\n    {\n        vec3 _3829;\n        if (L.aniso >= 0.0)\n        {\n            _3829 = L.b;\n        }\n        else\n        {\n            _3829 = L.t;\n        }\n        rn = normalize(mix(n, cross(cross(_3829, v), _3829), vec3(abs(L.aniso))));\n    }\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05);\n    vec2 _3862 = fa_env_brdf(param, param_1);\n    vec3 param_2 = reflect(-v, rn);\n    float param_3 = roughness;\n    vec3 result = (fa_environment(param_2, param_3) * ((f0 * _3862.x) + (vec3(L.f90) * _3862.y))) * L.base_scale;\n    if (L.sheen_on)\n    {\n        vec3 param_4 = n;\n        float param_5 = L.sheen_rough;\n        result += ((L.sheen * (L.sheen_e * L.keep)) * fa_environment(param_4, param_5));\n    }\n    if (L.coat > 0.0)\n    {\n        float param_6 = L.coat_rough;\n        float param_7 = L.coat_ndv;\n        vec2 _3917 = fa_env_brdf(param_6, param_7);\n        vec3 param_8 = reflect(-v, L.nc);\n        float param_9 = L.coat_rough;\n        result += (fa_environment(param_8, param_9) * (L.coat * ((0.039999999105930328369140625 * _3917.x) + _3917.y)));\n    }\n    return result;\n}\n\nvec3 fa_sky_reflection(vec3 n, vec3 v, vec3 f0, float roughness)\n{\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05);\n    vec2 _3391 = fa_env_brdf(param, param_1);\n    vec3 param_2 = reflect(-v, n);\n    float param_3 = roughness;\n    return fa_environment(param_2, param_3) * ((f0 * _3391.x) + vec3(_3391.y));\n}\n\nvec3 fa_shadow_debug(vec3 color, vec3 world)\n{\n    if (fa_shadows[27].w < 0.5)\n    {\n        return color;\n    }\n    int _3144 = int(fa_shadows[25].x + 0.5);\n    float _3154 = dot(world - fa_shadows[27].xyz, fa_shadows[28].xyz);\n    vec3 tint_1 = vec3(0.3499999940395355224609375);\n    bool _3159 = _3144 > 0;\n    bool _3168;\n    if (_3159)\n    {\n        int param = _3144 - 1;\n        _3168 = _3154 <= fa_shadow_split_at(param);\n    }\n    else\n    {\n        _3168 = _3159;\n    }\n    if (_3168)\n    {\n        tint_1 = vec3(1.0, 0.1500000059604644775390625, 0.100000001490116119384765625);\n        bool _3174 = _3144 > 1;\n        bool _3181;\n        if (_3174)\n        {\n            _3181 = _3154 > fa_shadows[24].x;\n        }\n        else\n        {\n            _3181 = _3174;\n        }\n        if (_3181)\n        {\n            tint_1 = vec3(0.100000001490116119384765625, 0.89999997615814208984375, 0.20000000298023223876953125);\n        }\n        bool _3187 = _3144 > 2;\n        bool _3194;\n        if (_3187)\n        {\n            _3194 = _3154 > fa_shadows[24].y;\n        }\n        else\n        {\n            _3194 = _3187;\n        }\n        if (_3194)\n        {\n            tint_1 = vec3(0.1500000059604644775390625, 0.300000011920928955078125, 1.0);\n        }\n        bool _3200 = _3144 > 3;\n        bool _3207;\n        if (_3200)\n        {\n            _3207 = _3154 > fa_shadows[24].z;\n        }\n        else\n        {\n            _3207 = _3200;\n        }\n        if (_3207)\n        {\n            tint_1 = vec3(1.0, 0.89999997615814208984375, 0.100000001490116119384765625);\n        }\n    }\n    return mix(color, tint_1, vec3(0.550000011920928955078125));\n}\n\nvoid main()\n{\n    fa_inst_load();\n    vec3 _6393 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _6393 = -_6393;\n    }\n    vec3 _5751 = normalize(fa_mesh_fs_params[0].xyz - fa_world_pos);\n    vec3 param = fa_world_pos;\n    fa_cluster_begin(param);\n    SurfaceInput param_1 = SurfaceInput(fa_world_pos, _6393, fa_world_tangent, fa_uv, fa_vertex_color, _5751, gl_FrontFacing);\n    Surface _5759 = fa_standard_surface(param_1);\n    vec3 _6424 = _5759.albedo;\n    float _6425 = _5759.alpha;\n    vec3 _6426 = _5759.normal;\n    float _6427 = _5759.metallic;\n    float _6428 = _5759.roughness;\n    float _6429 = _5759.occlusion;\n    vec3 _6430 = _5759.emission;\n    float _6431 = _5759.clearcoat;\n    float _6432 = _5759.clearcoat_roughness;\n    vec3 _6433 = _5759.sheen_color;\n    float _6434 = _5759.sheen_roughness;\n    float _6435 = _5759.anisotropy;\n    float _6436 = _5759.anisotropy_rotation;\n    float _6437 = _5759.specular;\n    float _6438 = _5759.ior;\n    vec3 _6439 = _5759.specular_color;\n    SurfaceInput param_2 = SurfaceInput(fa_world_pos, _6393, fa_world_tangent, fa_uv, fa_vertex_color, _5751, gl_FrontFacing);\n    Surface param_3 = _5759;\n    surface(param_2, param_3);\n    _6424 = param_3.albedo;\n    _6425 = param_3.alpha;\n    _6426 = param_3.normal;\n    _6427 = param_3.metallic;\n    _6428 = param_3.roughness;\n    _6429 = param_3.occlusion;\n    _6430 = param_3.emission;\n    _6431 = param_3.clearcoat;\n    _6432 = param_3.clearcoat_roughness;\n    _6433 = param_3.sheen_color;\n    _6434 = param_3.sheen_roughness;\n    _6435 = param_3.anisotropy;\n    _6436 = param_3.anisotropy_rotation;\n    _6437 = param_3.specular;\n    _6438 = param_3.ior;\n    _6439 = param_3.specular_color;\n    vec3 param_4 = fa_world_pos;\n    vec3 param_5 = _6393;\n    vec3 param_6 = param_3.albedo;\n    vec3 param_7 = param_3.normal;\n    fa_apply_decals(param_4, param_5, param_6, param_7);\n    _6424 = param_6;\n    _6426 = param_7;\n    vec3 result;\n    if (fa_mesh_fs_params[3].w > 0.5)\n    {\n        result = _6424;\n    }\n    else\n    {\n        vec3 _5798 = normalize(_6426);\n        float _5805 = clamp(_6427, 0.0, 1.0);\n        float _5809 = clamp(_6428, 0.0500000007450580596923828125, 1.0);\n        float _5813 = _5809 * _5809;\n        float _5817 = _5813 * _5813;\n        float _5822 = max(dot(_5798, _5751), 9.9999997473787516355514526367188e-05);\n        vec3 _5828 = _6424 * (1.0 - _5805);\n        vec3 _5835 = mix(vec3(0.039999999105930328369140625), _6424, vec3(_5805));\n        vec3 f0 = _5835;\n        SurfaceInput param_8 = SurfaceInput(fa_world_pos, _6393, fa_world_tangent, fa_uv, fa_vertex_color, _5751, gl_FrontFacing);\n        Surface param_9 = Surface(_6424, _6425, _6426, _6427, _6428, _6429, _6430, _6431, _6432, _6433, _6434, _6435, _6436, _6437, _6438, _6439);\n        vec3 param_10 = _5798;\n        vec3 param_11 = _5751;\n        float param_12 = _5805;\n        float param_13 = _5809;\n        vec3 param_14 = _5835;\n        FaLayers _5851 = fa_layers_setup(param_8, param_9, param_10, param_11, param_12, param_13, param_14);\n        f0 = param_14;\n        vec3 param_15 = _5798;\n        vec3 lit = (fa_indirect_diffuse(param_15) * _5828) * _6429;\n        if (_5851.on)\n        {\n            lit *= _5851.base_scale;\n        }\n        int _5873 = fa_cl_ndir + fa_cl_local;\n        for (int ln = 0; ln < _5873; ln++)\n        {\n            int param_16 = ln;\n            int _5886 = fa_cl_light(param_16);\n            bool _5889 = fa_lm.z > 0.5;\n            bool _5895;\n            if (_5889)\n            {\n                int param_17 = _5886;\n                _5895 = fa_light_baked(param_17);\n            }\n            else\n            {\n                _5895 = _5889;\n            }\n            if (_5895)\n            {\n                continue;\n            }\n            int param_18 = _5886;\n            vec3 param_19 = fa_world_pos;\n            vec3 param_20 = _6393;\n            LightSample _5907 = fa_light_shadowed(param_18, param_19, param_20);\n            float _5915 = max(dot(_5798, _5907.direction), 0.0);\n            float _5921 = _5907.attenuation * _5907.shadow;\n            vec3 _5926 = normalize(_5907.direction + _5751);\n            float _5931 = max(dot(_5798, _5926), 0.0);\n            float _5936 = max(dot(_5751, _5926), 0.0);\n            bool _5943;\n            if (fa_light_is_area)\n            {\n                _5943 = !_5851.on;\n            }\n            else\n            {\n                _5943 = fa_light_is_area;\n            }\n            if (_5943)\n            {\n                int param_21 = _5886;\n                vec3 param_22 = fa_world_pos;\n                vec3 param_23 = _5798;\n                vec3 param_24 = _5751;\n                vec3 param_25 = _5828;\n                vec3 param_26 = f0;\n                float param_27 = 1.0;\n                float param_28 = _5809;\n                float param_29 = _5822;\n                float param_30 = _5921;\n                lit += fa_area_shade(param_21, param_22, param_23, param_24, param_25, param_26, param_27, param_28, param_29, param_30);\n            }\n            else\n            {\n                if (fa_light_is_area)\n                {\n                    FaLayers param_31 = _5851;\n                    int param_32 = _5886;\n                    vec3 param_33 = fa_world_pos;\n                    vec3 param_34 = _5798;\n                    vec3 param_35 = _5751;\n                    vec3 param_36 = _5907.direction;\n                    vec3 param_37 = _5828;\n                    vec3 param_38 = f0;\n                    float param_39 = _5809;\n                    float param_40 = _5822;\n                    float param_41 = _5921;\n                    lit += fa_area_layers(param_31, param_32, param_33, param_34, param_35, param_36, param_37, param_38, param_39, param_40, param_41);\n                }\n                else\n                {\n                    if (_5851.on)\n                    {\n                        FaLayers param_42 = _5851;\n                        vec3 param_43 = _5828;\n                        vec3 param_44 = f0;\n                        vec3 param_45 = _5798;\n                        vec3 param_46 = _5751;\n                        vec3 param_47 = _5907.direction;\n                        vec3 param_48 = _5926;\n                        float param_49 = _5915;\n                        float param_50 = _5822;\n                        float param_51 = _5931;\n                        float param_52 = _5936;\n                        float param_53 = _5813;\n                        float param_54 = _5817;\n                        int param_55 = _5886;\n                        lit += (fa_layers_light(param_42, param_43, param_44, param_45, param_46, param_47, param_48, param_49, param_50, param_51, param_52, param_53, param_54) * ((fa_light_rgb(param_55) * fa_light_tint) * _5921));\n                    }\n                    else\n                    {\n                        float _6049 = ((_5931 * _5931) * (_5817 - 1.0)) + 1.0;\n                        int param_56 = _5886;\n                        lit += (((_5828 + (((f0 + ((vec3(1.0) - f0) * pow(1.0 - _5936, 5.0))) * (((_5817 / ((3.1415927410125732421875 * _6049) * _6049)) * (0.5 / max(mix((2.0 * _5915) * _5822, _5915 + _5822, _5813), 9.9999997473787516355514526367188e-05))) * 3.1415927410125732421875)) * step(9.9999997473787516355514526367188e-05, _5915))) * (fa_light_rgb(param_56) * fa_light_tint)) * (_5915 * _5921));\n                    }\n                }\n            }\n        }\n        if (_5851.on)\n        {\n            FaLayers param_57 = _5851;\n            vec3 param_58 = _5798;\n            vec3 param_59 = _5751;\n            vec3 param_60 = f0;\n            float param_61 = _5809;\n            lit += (fa_layers_ibl(param_57, param_58, param_59, param_60, param_61) * _6429);\n        }\n        else\n        {\n            vec3 param_62 = _5798;\n            vec3 param_63 = _5751;\n            vec3 param_64 = f0;\n            float param_65 = _5809;\n            lit += (fa_sky_reflection(param_62, param_63, param_64, param_65) * _6429);\n        }\n        result = lit;\n    }\n    vec3 _6144 = result;\n    vec3 _6145 = _6144 + _6430;\n    result = _6145;\n    vec3 param_66 = _6145;\n    vec3 param_67 = fa_world_pos;\n    result = fa_shadow_debug(param_66, param_67);\n    bool _6154 = fa_mesh_fs_params[7].w > 0.0;\n    bool _6161;\n    if (!_6154)\n    {\n        _6161 = fa_mesh_fs_params[8].y > 0.0;\n    }\n    else\n    {\n        _6161 = _6154;\n    }\n    if (_6161)\n    {\n        vec3 _6170 = fa_world_pos - fa_mesh_fs_params[0].xyz;\n        float _6176 = dot(_6170, fa_mesh_fs_params[9].xyz);\n        bool _6180 = fa_mesh_fs_params[9].w > 0.5;\n        float _6181;\n        if (_6180)\n        {\n            _6181 = _6176;\n        }\n        else\n        {\n            _6181 = length(_6170);\n        }\n        float _6193 = _6181 - fa_mesh_fs_params[8].x;\n        if (_6193 > 0.0)\n        {\n            float _6202 = fa_mesh_fs_params[7].w * _6193;\n            float tau = _6202 * _6202;\n            if (fa_mesh_fs_params[8].y > 0.0)\n            {\n                float _6218;\n                if (_6180)\n                {\n                    _6218 = fa_world_pos.y - (fa_mesh_fs_params[9].y * _6176);\n                }\n                else\n                {\n                    _6218 = fa_mesh_fs_params[0].y;\n                }\n                float _6239 = mix(_6218, fa_world_pos.y, clamp(fa_mesh_fs_params[8].x / _6181, 0.0, 1.0));\n                float _6243 = fa_world_pos.y - _6239;\n                float _6248 = _6239 - fa_mesh_fs_params[8].z;\n                float _6253 = fa_world_pos.y - fa_mesh_fs_params[8].z;\n                bool _6256 = _6248 <= 0.0;\n                bool _6257 = !_6256;\n                bool _6263;\n                if (_6257)\n                {\n                    _6263 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _6263 = _6256;\n                }\n                float _6264;\n                if (_6263)\n                {\n                    _6264 = fa_mesh_fs_params[8].y;\n                }\n                else\n                {\n                    _6264 = fa_mesh_fs_params[8].y * exp(-min(fa_mesh_fs_params[8].w * _6248, 80.0));\n                }\n                bool _6291;\n                if (_6257)\n                {\n                    _6291 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _6291 = _6256;\n                }\n                float _6292;\n                if (_6291)\n                {\n                    _6292 = fa_mesh_fs_params[8].y * _6248;\n                }\n                else\n                {\n                    _6292 = (fa_mesh_fs_params[8].y * (1.0 - exp(-min(fa_mesh_fs_params[8].w * _6248, 80.0)))) / fa_mesh_fs_params[8].w;\n                }\n                bool _6317 = _6253 <= 0.0;\n                bool _6324;\n                if (!_6317)\n                {\n                    _6324 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _6324 = _6317;\n                }\n                float _6325;\n                if (_6324)\n                {\n                    _6325 = fa_mesh_fs_params[8].y * _6253;\n                }\n                else\n                {\n                    _6325 = (fa_mesh_fs_params[8].y * (1.0 - exp(-min(fa_mesh_fs_params[8].w * _6253, 80.0)))) / fa_mesh_fs_params[8].w;\n                }\n                float _6352;\n                if (abs(_6243) < 0.001000000047497451305389404296875)\n                {\n                    _6352 = _6264;\n                }\n                else\n                {\n                    _6352 = (_6325 - _6292) / _6243;\n                }\n                tau += (_6193 * max(_6352, 0.0));\n            }\n            result = mix(result, fa_mesh_fs_params[7].xyz, vec3(clamp(1.0 - exp(-clamp(tau, 0.0, 80.0)), 0.0, 1.0)));\n        }\n    }\n    fa_frag_color = vec4(result, _6425);\n}\n\n",
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
            "size": 384,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_491",
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
            "inst_name": "_2198",
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
            "inst_name": "_5369",
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
              "name": "fa_env_tex",
              "multisampled": false,
              "type": "cube",
              "sample_type": "float"
            }
          },
          {
            "texture": {
              "slot": 15,
              "stage": "fragment",
              "name": "fa_irr_tex",
              "multisampled": false,
              "type": "cube",
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
            "name": "fa_irr_tex_fa_env_smp",
            "view_name": "fa_irr_tex",
            "sampler_name": "fa_env_smp",
            "view_slot": 15,
            "sampler_slot": 10,
            "glsl_name": "fa_irr_tex_fa_env_smp"
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
            "name": "fa_env_tex_fa_env_smp",
            "view_name": "fa_env_tex",
            "sampler_name": "fa_env_smp",
            "view_slot": 14,
            "sampler_slot": 10,
            "glsl_name": "fa_env_tex_fa_env_smp"
          }
        ]
      }
    },
    "prepass": {
      "vs": "#version 430\n\nstruct VertexData\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 color;\n    vec3 object_pos;\n};\n\nuniform vec4 fa_mesh_vs_params[11];\nlayout(location = 2) out vec3 fa_world_pos;\nlayout(location = 3) out vec3 fa_world_normal;\nlayout(location = 4) out vec4 fa_world_tangent;\nlayout(location = 5) out vec2 fa_uv;\nlayout(location = 6) out vec4 fa_vertex_color;\nlayout(location = 7) out float fa_pre_depth;\nlayout(location = 8) out vec3 fa_pre_r0;\nlayout(location = 9) out vec3 fa_pre_r1;\nlayout(location = 10) out vec3 fa_pre_r2;\nlayout(location = 9) in vec4 fa_inst_d0;\nlayout(location = 10) in vec4 fa_inst_d1;\nlayout(location = 0) flat out vec4 fa_inst_v0;\nlayout(location = 1) flat out vec4 fa_inst_v1;\nlayout(location = 5) in vec4 fa_inst_m0;\nlayout(location = 6) in vec4 fa_inst_m1;\nlayout(location = 7) in vec4 fa_inst_m2;\nlayout(location = 8) in vec4 fa_inst_m3;\nlayout(location = 0) in vec3 fa_position;\nlayout(location = 1) in vec3 fa_normal;\nlayout(location = 3) in vec4 fa_tangent;\nlayout(location = 2) in vec2 fa_texcoord0;\nlayout(location = 4) in vec4 fa_color;\nfloat raise;\nvec4 tint;\n\nvoid fa_instance_unpack(vec4 fa_d0, vec4 fa_d1, vec4 fa_d2)\n{\n    raise = fa_d0.x;\n    tint = fa_d1;\n}\n\nvoid fa_inst_begin()\n{\n    vec4 param = fa_inst_d0;\n    vec4 param_1 = fa_inst_d1;\n    vec4 param_2 = vec4(0.0);\n    fa_instance_unpack(param, param_1, param_2);\n    fa_inst_v0 = fa_inst_d0;\n    fa_inst_v1 = fa_inst_d1;\n}\n\nVertexData fa_vertex_data(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    vec3 _94 = cross(model[1].xyz, model[2].xyz);\n    float _100 = (dot(model[0].xyz, _94) < 0.0) ? (-1.0) : 1.0;\n    return VertexData((model * vec4(position, 1.0)).xyz, (((_94 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _100, vec4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _100), texcoord0 * fa_mesh_vs_params[8].xy, color, position);\n}\n\nvoid vertex(inout VertexData v)\n{\n    v.world_pos.y += raise;\n}\n\nvoid fa_prepass_vertex(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    mat4 param = model;\n    vec3 param_1 = position;\n    vec3 param_2 = normal;\n    vec4 param_3 = tangent;\n    vec2 param_4 = texcoord0;\n    vec4 param_5 = color;\n    VertexData param_6 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    vertex(param_6);\n    mat4 _190 = mat4(fa_mesh_vs_params[4], fa_mesh_vs_params[5], fa_mesh_vs_params[6], fa_mesh_vs_params[7]);\n    vec4 _197 = vec4(param_6.world_pos, 1.0);\n    fa_world_pos = param_6.world_pos;\n    fa_world_normal = param_6.world_normal;\n    fa_world_tangent = param_6.world_tangent;\n    fa_uv = param_6.uv;\n    fa_vertex_color = param_6.color;\n    fa_pre_depth = -(_190 * _197).z;\n    fa_pre_r0 = vec3(_190[0].x, _190[1].x, _190[2].x);\n    fa_pre_r1 = vec3(_190[0].y, _190[1].y, _190[2].y);\n    fa_pre_r2 = vec3(_190[0].z, _190[1].z, _190[2].z);\n    gl_Position = mat4(fa_mesh_vs_params[0], fa_mesh_vs_params[1], fa_mesh_vs_params[2], fa_mesh_vs_params[3]) * _197;\n}\n\nvoid main()\n{\n    fa_inst_begin();\n    mat4 param = mat4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3);\n    vec3 param_1 = fa_position;\n    vec3 param_2 = fa_normal;\n    vec4 param_3 = fa_tangent;\n    vec2 param_4 = fa_texcoord0;\n    vec4 param_5 = fa_color;\n    fa_prepass_vertex(param, param_1, param_2, param_3, param_4, param_5);\n}\n\n",
      "fs": "#version 430\n\nstruct SurfaceInput\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 vertex_color;\n    vec3 view_dir;\n    bool front_facing;\n};\n\nstruct Surface\n{\n    vec3 albedo;\n    float alpha;\n    vec3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    vec3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    vec3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    vec3 specular_color;\n};\n\nuniform vec4 fa_material[1];\nuniform vec4 fa_mesh_fs_params[24];\nlayout(binding = 0) uniform sampler2D fa_tex_fa_smp;\nlayout(binding = 1) uniform sampler2D fa_normal_tex_fa_smp;\nlayout(binding = 2) uniform sampler2D fa_mr_tex_fa_smp;\nlayout(binding = 3) uniform sampler2D fa_occlusion_tex_fa_smp;\nlayout(binding = 4) uniform sampler2D fa_emissive_tex_fa_smp;\n\nlayout(location = 0) flat in vec4 fa_inst_v0;\nlayout(location = 1) flat in vec4 fa_inst_v1;\nlayout(location = 2) in vec3 fa_world_pos;\nlayout(location = 3) in vec3 fa_world_normal;\nlayout(location = 4) in vec4 fa_world_tangent;\nlayout(location = 5) in vec2 fa_uv;\nlayout(location = 6) in vec4 fa_vertex_color;\nlayout(location = 8) in vec3 fa_pre_r0;\nlayout(location = 9) in vec3 fa_pre_r1;\nlayout(location = 10) in vec3 fa_pre_r2;\nlayout(location = 0) out vec4 fa_frag_color;\nlayout(location = 7) in float fa_pre_depth;\nfloat raise;\nvec4 tint;\n\nvoid fa_instance_unpack(vec4 fa_d0, vec4 fa_d1, vec4 fa_d2)\n{\n    raise = fa_d0.x;\n    tint = fa_d1;\n}\n\nvoid fa_inst_load()\n{\n    vec4 param = fa_inst_v0;\n    vec4 param_1 = fa_inst_v1;\n    vec4 param_2 = vec4(0.0);\n    fa_instance_unpack(param, param_1, param_2);\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nvec3 fa_linear_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_tex_fix(inout vec3 c, float mode)\n{\n    if (mode > 1.5)\n    {\n        vec3 param = c;\n        vec3 _212 = fa_linear_to_srgb(param);\n        c = _212;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            vec3 param_1 = c;\n            vec3 _221 = fa_srgb_to_linear(param_1);\n            c = _221;\n        }\n    }\n    return c;\n}\n\nvec3 fa_tangent_normal(SurfaceInput i, vec3 m)\n{\n    vec3 _63;\n    if (i.front_facing)\n    {\n        _63 = i.world_normal;\n    }\n    else\n    {\n        _63 = -i.world_normal;\n    }\n    vec3 _87 = normalize(i.world_tangent.xyz - (_63 * dot(_63, i.world_tangent.xyz)));\n    vec3 _115 = normalize(((_87 * m.x) + ((cross(_63, _87) * i.world_tangent.w) * m.y)) + (_63 * m.z));\n    vec3 _118;\n    if (i.front_facing)\n    {\n        _118 = _115;\n    }\n    else\n    {\n        _118 = -_115;\n    }\n    return _118;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    vec4 base_t = texture(fa_tex_fa_smp, i.uv);\n    float param = fa_mesh_fs_params[6].w;\n    float param_1 = 1.0;\n    vec3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    vec3 _264 = fa_tex_fix(param_2, param_3);\n    vec4 _772 = base_t;\n    _772.x = _264.x;\n    _772.y = _264.y;\n    _772.z = _264.z;\n    base_t = _772;\n    vec4 _280 = (_772 * fa_mesh_fs_params[2]) * i.vertex_color;\n    vec3 _735 = i.world_normal;\n    if (fa_mesh_fs_params[6].z > 0.5)\n    {\n        float param_4 = fa_mesh_fs_params[6].w;\n        float param_5 = 16.0;\n        vec3 param_6 = texture(fa_normal_tex_fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        vec3 _313 = fa_tex_fix(param_6, param_7);\n        vec3 _317 = (_313 * 2.0) - vec3(1.0);\n        vec2 _322 = _317.xy * fa_mesh_fs_params[6].x;\n        vec3 _780 = _317;\n        _780.x = _322.x;\n        _780.y = _322.y;\n        SurfaceInput param_8 = i;\n        vec3 param_9 = _780;\n        _735 = fa_tangent_normal(param_8, param_9);\n    }\n    vec4 mrt = texture(fa_mr_tex_fa_smp, i.uv);\n    float param_10 = fa_mesh_fs_params[6].w;\n    float param_11 = 64.0;\n    vec3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    vec3 _351 = fa_tex_fix(param_12, param_13);\n    vec4 _783 = mrt;\n    _783.x = _351.x;\n    _783.y = _351.y;\n    _783.z = _351.z;\n    mrt = _783;\n    vec4 _381 = texture(fa_occlusion_tex_fa_smp, i.uv);\n    float param_14 = fa_mesh_fs_params[6].w;\n    float param_15 = 256.0;\n    vec3 param_16 = _381.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    vec3 _393 = fa_tex_fix(param_16, param_17);\n    float param_18 = fa_mesh_fs_params[6].w;\n    float param_19 = 4.0;\n    vec3 param_20 = texture(fa_emissive_tex_fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    vec3 _423 = fa_tex_fix(param_20, param_21);\n    float _740 = fa_mesh_fs_params[20].x;\n    float _741 = fa_mesh_fs_params[20].y;\n    float _744 = fa_mesh_fs_params[20].z;\n    float _743 = fa_mesh_fs_params[21].w;\n    float _746 = fa_mesh_fs_params[22].x;\n    if (fa_mesh_fs_params[22].z > 0.5)\n    {\n        if (mod(fa_mesh_fs_params[22].z, 2.0) > 0.5)\n        {\n            _740 *= _393.y;\n            _741 *= _393.z;\n            _743 *= _381.w;\n        }\n        if (fa_mesh_fs_params[22].z > 1.5)\n        {\n            _744 *= mrt.x;\n            _746 *= mrt.w;\n        }\n    }\n    return Surface(_280.xyz, _280.w, _735, clamp(fa_mesh_fs_params[5].x * _351.z, 0.0, 1.0), clamp(fa_mesh_fs_params[5].y * _351.y, 0.0500000007450580596923828125, 1.0), 1.0 + (fa_mesh_fs_params[6].y * (_393.x - 1.0)), fa_mesh_fs_params[3].xyz + (fa_mesh_fs_params[4].xyz * _423), _740, _741, fa_mesh_fs_params[21].xyz, _743, _744, fa_mesh_fs_params[20].w, _746, fa_mesh_fs_params[22].y, fa_mesh_fs_params[23].xyz);\n}\n\nvoid surface(SurfaceInput i, inout Surface s)\n{\n    s.emission += ((tint.xyz * tint.w) * fa_material[0].x);\n}\n\nvoid main()\n{\n    fa_inst_load();\n    vec3 _646 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _646 = -_646;\n    }\n    vec3 _556 = normalize(fa_mesh_fs_params[0].xyz - fa_world_pos);\n    SurfaceInput param = SurfaceInput(fa_world_pos, _646, fa_world_tangent, fa_uv, fa_vertex_color, _556, gl_FrontFacing);\n    SurfaceInput param_1 = SurfaceInput(fa_world_pos, _646, fa_world_tangent, fa_uv, fa_vertex_color, _556, gl_FrontFacing);\n    Surface param_2 = fa_standard_surface(param);\n    surface(param_1, param_2);\n    vec3 _571 = normalize(param_2.normal);\n    vec3 _586 = normalize(vec3(dot(fa_pre_r0, _571), dot(fa_pre_r1, _571), dot(fa_pre_r2, _571)));\n    float _598 = _586.z;\n    vec2 e = _586.xy / vec2((abs(_586.x) + abs(_586.y)) + abs(_598));\n    if (_598 < 0.0)\n    {\n        e = (vec2(1.0) - abs(e.yx)) * vec2((e.x >= 0.0) ? 1.0 : (-1.0), (e.y >= 0.0) ? 1.0 : (-1.0));\n    }\n    fa_frag_color = vec4(min(fa_pre_depth, 60000.0), e, 1.0);\n}\n\n",
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
            "size": 384,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_253",
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
      "fs": "#version 430\n\nstruct SurfaceInput\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 vertex_color;\n    vec3 view_dir;\n    bool front_facing;\n};\n\nstruct Surface\n{\n    vec3 albedo;\n    float alpha;\n    vec3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    vec3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    vec3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    vec3 specular_color;\n};\n\nuniform vec4 fa_material[1];\nuniform vec4 fa_mesh_fs_params[24];\nlayout(binding = 0) uniform sampler2D fa_tex_fa_smp;\nlayout(binding = 1) uniform sampler2D fa_normal_tex_fa_smp;\nlayout(binding = 2) uniform sampler2D fa_mr_tex_fa_smp;\nlayout(binding = 3) uniform sampler2D fa_occlusion_tex_fa_smp;\nlayout(binding = 4) uniform sampler2D fa_emissive_tex_fa_smp;\n\nlayout(location = 0) flat in vec4 fa_inst_v0;\nlayout(location = 1) flat in vec4 fa_inst_v1;\nlayout(location = 2) in vec3 fa_world_pos;\nlayout(location = 3) in vec3 fa_world_normal;\nlayout(location = 4) in vec4 fa_world_tangent;\nlayout(location = 5) in vec2 fa_uv;\nlayout(location = 6) in vec4 fa_vertex_color;\nlayout(location = 8) in vec3 fa_pre_r0;\nlayout(location = 9) in vec3 fa_pre_r1;\nlayout(location = 10) in vec3 fa_pre_r2;\nlayout(location = 0) out vec4 fa_frag_color;\nlayout(location = 7) in float fa_pre_depth;\nfloat raise;\nvec4 tint;\n\nvoid fa_instance_unpack(vec4 fa_d0, vec4 fa_d1, vec4 fa_d2)\n{\n    raise = fa_d0.x;\n    tint = fa_d1;\n}\n\nvoid fa_inst_load()\n{\n    vec4 param = fa_inst_v0;\n    vec4 param_1 = fa_inst_v1;\n    vec4 param_2 = vec4(0.0);\n    fa_instance_unpack(param, param_1, param_2);\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nvec3 fa_linear_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_tex_fix(inout vec3 c, float mode)\n{\n    if (mode > 1.5)\n    {\n        vec3 param = c;\n        vec3 _212 = fa_linear_to_srgb(param);\n        c = _212;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            vec3 param_1 = c;\n            vec3 _221 = fa_srgb_to_linear(param_1);\n            c = _221;\n        }\n    }\n    return c;\n}\n\nvec3 fa_tangent_normal(SurfaceInput i, vec3 m)\n{\n    vec3 _63;\n    if (i.front_facing)\n    {\n        _63 = i.world_normal;\n    }\n    else\n    {\n        _63 = -i.world_normal;\n    }\n    vec3 _87 = normalize(i.world_tangent.xyz - (_63 * dot(_63, i.world_tangent.xyz)));\n    vec3 _115 = normalize(((_87 * m.x) + ((cross(_63, _87) * i.world_tangent.w) * m.y)) + (_63 * m.z));\n    vec3 _118;\n    if (i.front_facing)\n    {\n        _118 = _115;\n    }\n    else\n    {\n        _118 = -_115;\n    }\n    return _118;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    vec4 base_t = texture(fa_tex_fa_smp, i.uv);\n    float param = fa_mesh_fs_params[6].w;\n    float param_1 = 1.0;\n    vec3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    vec3 _264 = fa_tex_fix(param_2, param_3);\n    vec4 _772 = base_t;\n    _772.x = _264.x;\n    _772.y = _264.y;\n    _772.z = _264.z;\n    base_t = _772;\n    vec4 _280 = (_772 * fa_mesh_fs_params[2]) * i.vertex_color;\n    vec3 _735 = i.world_normal;\n    if (fa_mesh_fs_params[6].z > 0.5)\n    {\n        float param_4 = fa_mesh_fs_params[6].w;\n        float param_5 = 16.0;\n        vec3 param_6 = texture(fa_normal_tex_fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        vec3 _313 = fa_tex_fix(param_6, param_7);\n        vec3 _317 = (_313 * 2.0) - vec3(1.0);\n        vec2 _322 = _317.xy * fa_mesh_fs_params[6].x;\n        vec3 _780 = _317;\n        _780.x = _322.x;\n        _780.y = _322.y;\n        SurfaceInput param_8 = i;\n        vec3 param_9 = _780;\n        _735 = fa_tangent_normal(param_8, param_9);\n    }\n    vec4 mrt = texture(fa_mr_tex_fa_smp, i.uv);\n    float param_10 = fa_mesh_fs_params[6].w;\n    float param_11 = 64.0;\n    vec3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    vec3 _351 = fa_tex_fix(param_12, param_13);\n    vec4 _783 = mrt;\n    _783.x = _351.x;\n    _783.y = _351.y;\n    _783.z = _351.z;\n    mrt = _783;\n    vec4 _381 = texture(fa_occlusion_tex_fa_smp, i.uv);\n    float param_14 = fa_mesh_fs_params[6].w;\n    float param_15 = 256.0;\n    vec3 param_16 = _381.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    vec3 _393 = fa_tex_fix(param_16, param_17);\n    float param_18 = fa_mesh_fs_params[6].w;\n    float param_19 = 4.0;\n    vec3 param_20 = texture(fa_emissive_tex_fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    vec3 _423 = fa_tex_fix(param_20, param_21);\n    float _740 = fa_mesh_fs_params[20].x;\n    float _741 = fa_mesh_fs_params[20].y;\n    float _744 = fa_mesh_fs_params[20].z;\n    float _743 = fa_mesh_fs_params[21].w;\n    float _746 = fa_mesh_fs_params[22].x;\n    if (fa_mesh_fs_params[22].z > 0.5)\n    {\n        if (mod(fa_mesh_fs_params[22].z, 2.0) > 0.5)\n        {\n            _740 *= _393.y;\n            _741 *= _393.z;\n            _743 *= _381.w;\n        }\n        if (fa_mesh_fs_params[22].z > 1.5)\n        {\n            _744 *= mrt.x;\n            _746 *= mrt.w;\n        }\n    }\n    return Surface(_280.xyz, _280.w, _735, clamp(fa_mesh_fs_params[5].x * _351.z, 0.0, 1.0), clamp(fa_mesh_fs_params[5].y * _351.y, 0.0500000007450580596923828125, 1.0), 1.0 + (fa_mesh_fs_params[6].y * (_393.x - 1.0)), fa_mesh_fs_params[3].xyz + (fa_mesh_fs_params[4].xyz * _423), _740, _741, fa_mesh_fs_params[21].xyz, _743, _744, fa_mesh_fs_params[20].w, _746, fa_mesh_fs_params[22].y, fa_mesh_fs_params[23].xyz);\n}\n\nvoid surface(SurfaceInput i, inout Surface s)\n{\n    s.emission += ((tint.xyz * tint.w) * fa_material[0].x);\n}\n\nvoid main()\n{\n    fa_inst_load();\n    vec3 _646 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _646 = -_646;\n    }\n    vec3 _556 = normalize(fa_mesh_fs_params[0].xyz - fa_world_pos);\n    SurfaceInput param = SurfaceInput(fa_world_pos, _646, fa_world_tangent, fa_uv, fa_vertex_color, _556, gl_FrontFacing);\n    SurfaceInput param_1 = SurfaceInput(fa_world_pos, _646, fa_world_tangent, fa_uv, fa_vertex_color, _556, gl_FrontFacing);\n    Surface param_2 = fa_standard_surface(param);\n    surface(param_1, param_2);\n    vec3 _571 = normalize(param_2.normal);\n    vec3 _586 = normalize(vec3(dot(fa_pre_r0, _571), dot(fa_pre_r1, _571), dot(fa_pre_r2, _571)));\n    float _598 = _586.z;\n    vec2 e = _586.xy / vec2((abs(_586.x) + abs(_586.y)) + abs(_598));\n    if (_598 < 0.0)\n    {\n        e = (vec2(1.0) - abs(e.yx)) * vec2((e.x >= 0.0) ? 1.0 : (-1.0), (e.y >= 0.0) ? 1.0 : (-1.0));\n    }\n    fa_frag_color = vec4(min(fa_pre_depth, 60000.0), e, 1.0);\n}\n\n",
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
            "size": 384,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_253",
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
