{
  "format": "factoria.shader/1",
  "engine": "0.32.0",
  "template": "5f457c7d0bc8edbcdea422ba00c093c613745eefd8db6d8c8f93fc5e235db1e8",
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
      "fs": "#version 430\n\nstruct SurfaceInput\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 vertex_color;\n    vec3 view_dir;\n    bool front_facing;\n};\n\nstruct LightSample\n{\n    vec3 direction;\n    vec3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct Surface\n{\n    vec3 albedo;\n    float alpha;\n    vec3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    vec3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    vec3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    vec3 specular_color;\n};\n\nstruct FaLayers\n{\n    bool on;\n    float f90;\n    float keep;\n    float base_scale;\n    float coat;\n    float coat_rough;\n    float coat_alpha;\n    float coat_a2;\n    vec3 nc;\n    float coat_ndv;\n    bool sheen_on;\n    vec3 sheen;\n    float sheen_rough;\n    float sheen_alpha;\n    float sheen_scale;\n    float sheen_e;\n    float aniso;\n    vec3 t;\n    vec3 b;\n    float at;\n    float ab;\n};\n\nconst float _3651[63] = float[](1.0, 1.0, 1.0, 0.4790000021457672119140625, 0.11699999868869781494140625, 0.01200000010430812835693359375, 0.0, 0.0, 0.0, 1.0, 1.0, 1.0, 0.578000009059906005859375, 0.19300000369548797607421875, 0.0350000001490116119384765625, 0.0030000000260770320892333984375, 0.0, 0.0, 1.0, 1.0, 1.0, 0.6740000247955322265625, 0.3459999859333038330078125, 0.1319999992847442626953125, 0.032999999821186065673828125, 0.0040000001899898052215576171875, 0.0, 0.971000015735626220703125, 0.954999983310699462890625, 0.828999996185302734375, 0.63999998569488525390625, 0.42599999904632568359375, 0.24500000476837158203125, 0.115000002086162567138671875, 0.037000000476837158203125, 0.0030000000260770320892333984375, 0.7469999790191650390625, 0.737999975681304931640625, 0.670000016689300537109375, 0.563000023365020751953125, 0.4309999942779541015625, 0.3039999902248382568359375, 0.1940000057220458984375, 0.1019999980926513671875, 0.0309999994933605194091796875, 0.614000022411346435546875, 0.609000027179718017578125, 0.566999971866607666015625, 0.499000012874603271484375, 0.412000000476837158203125, 0.32400000095367431640625, 0.240999996662139892578125, 0.162000000476837158203125, 0.087999999523162841796875, 0.538999974727630615234375, 0.535000026226043701171875, 0.505999982357025146484375, 0.4569999873638153076171875, 0.393999993801116943359375, 0.328999996185302734375, 0.2660000026226043701171875, 0.203999996185302734375, 0.14200000464916229248046875);\n\nuniform vec4 fa_mesh_fs_params[24];\nuniform vec4 fa_shadows[30];\nuniform vec4 fa_material[1];\nlayout(binding = 0) uniform sampler2D fa_light_tex_fa_shadow_smp;\nlayout(binding = 1) uniform sampler2D fa_tex_fa_smp;\nlayout(binding = 2) uniform sampler2D fa_normal_tex_fa_smp;\nlayout(binding = 3) uniform sampler2D fa_mr_tex_fa_smp;\nlayout(binding = 4) uniform sampler2D fa_occlusion_tex_fa_smp;\nlayout(binding = 5) uniform sampler2D fa_emissive_tex_fa_smp;\nlayout(binding = 6) uniform sampler2D fa_decal_tex_fa_env_smp;\nlayout(binding = 7) uniform sampler2D fa_lightmap_fa_env_smp;\nlayout(binding = 8) uniform samplerCube fa_env_tex_fa_env_smp;\nlayout(binding = 9) uniform sampler2D fa_light_atlas_fa_env_smp;\nlayout(binding = 10) uniform sampler2D fa_shadow_tex_fa_shadow_smp;\n\nlayout(location = 2) in vec3 fa_world_pos;\nlayout(location = 7) in vec3 fa_lm;\nlayout(location = 0) flat in vec4 fa_inst_v0;\nlayout(location = 1) flat in vec4 fa_inst_v1;\nlayout(location = 3) in vec3 fa_world_normal;\nlayout(location = 4) in vec4 fa_world_tangent;\nlayout(location = 5) in vec2 fa_uv;\nlayout(location = 6) in vec4 fa_vertex_color;\nlayout(location = 0) out vec4 fa_frag_color;\nvec3 fa_light_tint;\nbool fa_light_is_area;\nint fa_cl_ndir;\nint fa_cl_slot;\nint fa_cl_local;\nfloat raise;\nvec4 tint;\n\nvoid fa_instance_unpack(vec4 fa_d0, vec4 fa_d1, vec4 fa_d2)\n{\n    raise = fa_d0.x;\n    tint = fa_d1;\n}\n\nvoid fa_inst_load()\n{\n    vec4 param = fa_inst_v0;\n    vec4 param_1 = fa_inst_v1;\n    vec4 param_2 = vec4(0.0);\n    fa_instance_unpack(param, param_1, param_2);\n}\n\nvec4 fa_light_texel(int t)\n{\n    return texelFetch(fa_light_tex_fa_shadow_smp, ivec2(t & 1023, t >> 10), 0);\n}\n\nvec4 fa_cluster_texel(vec3 world_pos)\n{\n    bool _1492 = fa_mesh_fs_params[19].x < 0.0;\n    bool _1499;\n    if (!_1492)\n    {\n        _1499 = fa_mesh_fs_params[19].w < 1.0;\n    }\n    else\n    {\n        _1499 = _1492;\n    }\n    bool _1507;\n    if (!_1499)\n    {\n        _1507 = fa_mesh_fs_params[18].x < 1.0;\n    }\n    else\n    {\n        _1507 = _1499;\n    }\n    bool _1514;\n    if (!_1507)\n    {\n        _1514 = fa_mesh_fs_params[18].y < 1.0;\n    }\n    else\n    {\n        _1514 = _1507;\n    }\n    bool _1521;\n    if (!_1514)\n    {\n        _1521 = fa_mesh_fs_params[19].y < 1.0;\n    }\n    else\n    {\n        _1521 = _1514;\n    }\n    if (_1521)\n    {\n        return vec4(0.0);\n    }\n    vec4 _1531 = vec4(world_pos, 1.0);\n    float _1537 = dot(fa_mesh_fs_params[16], _1531);\n    if (!(_1537 > 9.9999999747524270787835121154785e-07))\n    {\n        return vec4(0.0);\n    }\n    vec2 _1559 = vec2(dot(fa_mesh_fs_params[14], _1531), dot(fa_mesh_fs_params[15], _1531)) / vec2(_1537);\n    int _1563 = int(fa_mesh_fs_params[18].x);\n    int _1567 = int(fa_mesh_fs_params[18].y);\n    int param = (int(fa_mesh_fs_params[19].x) + (((clamp(int(floor(log2(max(dot(fa_mesh_fs_params[17].xyz, world_pos) + fa_mesh_fs_params[17].w, fa_mesh_fs_params[18].w) / fa_mesh_fs_params[18].w) * fa_mesh_fs_params[18].z)), 0, int(fa_mesh_fs_params[19].y) - 1) * _1567) + clamp(int(floor(((_1559.y * 0.5) + 0.5) * fa_mesh_fs_params[18].y)), 0, _1567 - 1)) * _1563)) + clamp(int(floor(((_1559.x * 0.5) + 0.5) * fa_mesh_fs_params[18].x)), 0, _1563 - 1);\n    return fa_light_texel(param);\n}\n\nivec2 fa_cluster_lookup(vec3 world_pos)\n{\n    vec3 param = world_pos;\n    vec4 _1643 = fa_cluster_texel(param);\n    return ivec2(int(_1643.x), int(_1643.y));\n}\n\nvoid fa_cluster_begin(vec3 world_pos)\n{\n    fa_cl_ndir = int(fa_mesh_fs_params[19].z);\n    vec3 param = world_pos;\n    ivec2 _4470 = fa_cluster_lookup(param);\n    fa_cl_slot = _4470.x;\n    fa_cl_local = _4470.y;\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nvec3 fa_linear_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_tex_fix(inout vec3 c, float mode)\n{\n    if (mode > 1.5)\n    {\n        vec3 param = c;\n        vec3 _5585 = fa_linear_to_srgb(param);\n        c = _5585;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            vec3 param_1 = c;\n            vec3 _5593 = fa_srgb_to_linear(param_1);\n            c = _5593;\n        }\n    }\n    return c;\n}\n\nvec3 fa_tangent_normal(SurfaceInput i, vec3 m)\n{\n    vec3 _437;\n    if (i.front_facing)\n    {\n        _437 = i.world_normal;\n    }\n    else\n    {\n        _437 = -i.world_normal;\n    }\n    vec3 _461 = normalize(i.world_tangent.xyz - (_437 * dot(_437, i.world_tangent.xyz)));\n    vec3 _488 = normalize(((_461 * m.x) + ((cross(_437, _461) * i.world_tangent.w) * m.y)) + (_437 * m.z));\n    vec3 _491;\n    if (i.front_facing)\n    {\n        _491 = _488;\n    }\n    else\n    {\n        _491 = -_488;\n    }\n    return _491;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    vec4 base_t = texture(fa_tex_fa_smp, i.uv);\n    float param = fa_mesh_fs_params[6].w;\n    float param_1 = 1.0;\n    vec3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    vec3 _5624 = fa_tex_fix(param_2, param_3);\n    vec4 _7039 = base_t;\n    _7039.x = _5624.x;\n    _7039.y = _5624.y;\n    _7039.z = _5624.z;\n    base_t = _7039;\n    vec4 _5638 = (_7039 * fa_mesh_fs_params[2]) * i.vertex_color;\n    vec3 _6877 = i.world_normal;\n    if (fa_mesh_fs_params[6].z > 0.5)\n    {\n        float param_4 = fa_mesh_fs_params[6].w;\n        float param_5 = 16.0;\n        vec3 param_6 = texture(fa_normal_tex_fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        vec3 _5670 = fa_tex_fix(param_6, param_7);\n        vec3 _5673 = (_5670 * 2.0) - vec3(1.0);\n        vec2 _5678 = _5673.xy * fa_mesh_fs_params[6].x;\n        vec3 _7047 = _5673;\n        _7047.x = _5678.x;\n        _7047.y = _5678.y;\n        SurfaceInput param_8 = i;\n        vec3 param_9 = _7047;\n        _6877 = fa_tangent_normal(param_8, param_9);\n    }\n    vec4 mrt = texture(fa_mr_tex_fa_smp, i.uv);\n    float param_10 = fa_mesh_fs_params[6].w;\n    float param_11 = 64.0;\n    vec3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    vec3 _5706 = fa_tex_fix(param_12, param_13);\n    vec4 _7050 = mrt;\n    _7050.x = _5706.x;\n    _7050.y = _5706.y;\n    _7050.z = _5706.z;\n    mrt = _7050;\n    vec4 _5734 = texture(fa_occlusion_tex_fa_smp, i.uv);\n    float param_14 = fa_mesh_fs_params[6].w;\n    float param_15 = 256.0;\n    vec3 param_16 = _5734.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    vec3 _5745 = fa_tex_fix(param_16, param_17);\n    float param_18 = fa_mesh_fs_params[6].w;\n    float param_19 = 4.0;\n    vec3 param_20 = texture(fa_emissive_tex_fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    vec3 _5775 = fa_tex_fix(param_20, param_21);\n    float _6882 = fa_mesh_fs_params[20].x;\n    float _6883 = fa_mesh_fs_params[20].y;\n    float _6886 = fa_mesh_fs_params[20].z;\n    float _6885 = fa_mesh_fs_params[21].w;\n    float _6888 = fa_mesh_fs_params[22].x;\n    if (fa_mesh_fs_params[22].z > 0.5)\n    {\n        if (mod(fa_mesh_fs_params[22].z, 2.0) > 0.5)\n        {\n            _6882 *= _5745.y;\n            _6883 *= _5745.z;\n            _6885 *= _5734.w;\n        }\n        if (fa_mesh_fs_params[22].z > 1.5)\n        {\n            _6886 *= mrt.x;\n            _6888 *= mrt.w;\n        }\n    }\n    return Surface(_5638.xyz, _5638.w, _6877, clamp(fa_mesh_fs_params[5].x * _5706.z, 0.0, 1.0), clamp(fa_mesh_fs_params[5].y * _5706.y, 0.0500000007450580596923828125, 1.0), 1.0 + (fa_mesh_fs_params[6].y * (_5745.x - 1.0)), fa_mesh_fs_params[3].xyz + (fa_mesh_fs_params[4].xyz * _5775), _6882, _6883, fa_mesh_fs_params[21].xyz, _6885, _6886, fa_mesh_fs_params[20].w, _6888, fa_mesh_fs_params[22].y, fa_mesh_fs_params[23].xyz);\n}\n\nvoid surface(SurfaceInput i, inout Surface s)\n{\n    s.emission += ((tint.xyz * tint.w) * fa_material[0].x);\n}\n\nvec4 fa_decal_tile(vec4 rect, vec2 uv, vec2 atlas, vec2 ddx, vec2 ddy)\n{\n    vec2 _1723 = rect.zw - rect.xy;\n    vec2 _1727 = _1723 * atlas;\n    vec2 _1731 = ddx * _1727;\n    vec2 _1735 = ddy * _1727;\n    return textureLod(fa_decal_tex_fa_env_smp, rect.xy + (clamp(uv, vec2(0.0), vec2(1.0)) * _1723), clamp(0.5 * log2(max(max(dot(_1731, _1731), dot(_1735, _1735)), 9.9999999392252902907785028219223e-09)), 0.0, 4.0));\n}\n\nvec3 fa_dc_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_dc_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvoid fa_apply_decals(vec3 world_pos, vec3 geo_normal, inout vec3 albedo, inout vec3 normal)\n{\n    bool _1768 = fa_mesh_fs_params[10].y < 0.5;\n    bool _1775;\n    if (!_1768)\n    {\n        _1775 = fa_mesh_fs_params[10].w < 0.5;\n    }\n    else\n    {\n        _1775 = _1768;\n    }\n    if (_1775)\n    {\n        return;\n    }\n    vec3 _1781 = dFdx(world_pos);\n    vec3 _1784 = dFdy(world_pos);\n    vec3 param = world_pos;\n    vec4 _1788 = fa_cluster_texel(param);\n    int _1792 = int(_1788.w);\n    if (_1792 < 1)\n    {\n        return;\n    }\n    int _1802 = int(fa_mesh_fs_params[10].y + 0.5);\n    int param_1 = _1802;\n    vec4 _1806 = fa_light_texel(param_1);\n    vec2 _1809 = _1806.yz;\n    int _1813 = int(_1806.w);\n    int param_2 = _1802 + 1;\n    vec4 _1818 = fa_light_texel(param_2);\n    float _1819 = _1818.x;\n    int _1825 = int(fa_mesh_fs_params[10].w + 0.5) - 1;\n    int _1829 = int(_1788.z);\n    vec3 _2094;\n    for (int k = 0; k < _1792; k++)\n    {\n        int _1842 = _1829 + k;\n        int param_3 = _1813 + (_1842 >> 2);\n        int _1859 = (_1802 + 2) + (int(fa_light_texel(param_3)[_1842 & 3]) * 7);\n        int param_4 = _1859 + 6;\n        vec4 _1864 = fa_light_texel(param_4);\n        if (((int(_1864.w + 0.5) >> _1825) & 1) == 0)\n        {\n            continue;\n        }\n        int param_5 = _1859;\n        vec4 _1879 = fa_light_texel(param_5);\n        int param_6 = _1859 + 1;\n        vec4 _1884 = fa_light_texel(param_6);\n        int param_7 = _1859 + 2;\n        vec4 _1889 = fa_light_texel(param_7);\n        vec3 _1892 = _1879.xyz;\n        float _1897 = dot(_1892, world_pos) + _1879.w;\n        vec3 _1899 = _1884.xyz;\n        float _1904 = dot(_1899, world_pos) + _1884.w;\n        vec3 _1906 = _1889.xyz;\n        float _1911 = dot(_1906, world_pos) + _1889.w;\n        bool _1916 = abs(_1897) > 0.5;\n        bool _1924;\n        if (!_1916)\n        {\n            _1924 = abs(_1904) > 0.5;\n        }\n        else\n        {\n            _1924 = _1916;\n        }\n        bool _1932;\n        if (!_1924)\n        {\n            _1932 = abs(_1911) > 0.5;\n        }\n        else\n        {\n            _1932 = _1924;\n        }\n        if (_1932)\n        {\n            continue;\n        }\n        float _1947 = clamp(dot(geo_normal, normalize(_1906)) * _1864.z, 0.0, 1.0);\n        if (_1947 <= 0.0)\n        {\n            continue;\n        }\n        float _1967 = (clamp((0.5 - abs(_1911)) * 10.0, 0.0, 1.0) * _1947) * _1864.x;\n        vec2 _1975 = vec2(_1897 + 0.5, 0.5 - _1904);\n        vec2 _1985 = vec2(dot(_1892, _1781), dot(_1899, _1781));\n        vec2 _1995 = vec2(dot(_1892, _1784), dot(_1899, _1784));\n        int param_8 = _1859 + 5;\n        vec4 _2000 = fa_light_texel(param_8);\n        int param_9 = _1859 + 3;\n        vec4 _2005 = fa_light_texel(param_9);\n        int param_10 = _1859 + 4;\n        vec4 _2010 = fa_light_texel(param_10);\n        float tex_a = 1.0;\n        vec3 col = _2000.xyz;\n        bool _2020 = _2005.z > _2005.x;\n        if (_2020)\n        {\n            vec4 param_11 = _2005;\n            vec2 param_12 = _1975;\n            vec2 param_13 = _1809;\n            vec2 param_14 = _1985;\n            vec2 param_15 = _1995;\n            vec4 tx = fa_decal_tile(param_11, param_12, param_13, param_14, param_15);\n            if ((_1819 > 0.5) && (_1819 < 1.5))\n            {\n                vec3 param_16 = tx.xyz;\n                vec3 _2046 = fa_dc_to_linear(param_16);\n                vec4 _6957 = tx;\n                _6957.x = _2046.x;\n                _6957.y = _2046.y;\n                _6957.z = _2046.z;\n                tx = _6957;\n            }\n            col *= tx.xyz;\n            tex_a = tx.w;\n        }\n        albedo = mix(albedo, col, vec3(clamp((_1967 * tex_a) * _2000.w, 0.0, 1.0)));\n        if (_2010.z > _2010.x)\n        {\n            vec4 param_17 = _2010;\n            vec2 param_18 = _1975;\n            vec2 param_19 = _1809;\n            vec2 param_20 = _1985;\n            vec2 param_21 = _1995;\n            vec4 _2090 = fa_decal_tile(param_17, param_18, param_19, param_20, param_21);\n            if (_1819 > 1.5)\n            {\n                vec3 param_22 = _2090.xyz;\n                vec3 _2100 = fa_dc_to_srgb(param_22);\n                _2094 = _2100;\n            }\n            else\n            {\n                _2094 = _2090.xyz;\n            }\n            vec3 _2109 = (_2094 * 2.0) - vec3(1.0);\n            vec2 _2114 = _2109.xy * _1864.y;\n            vec3 _2136 = (normalize(_1892) * _2114.x) + (normalize(_1899) * _2114.y);\n            vec3 _2139 = normalize(normal);\n            normal = normalize(mix(_2139, normalize((_2139 * max(_2109.z, 0.0500000007450580596923828125)) + (_2136 - (_2139 * dot(_2139, _2136)))), vec3(clamp(_1967 * (_2020 ? tex_a : 1.0), 0.0, 1.0))));\n        }\n    }\n}\n\nfloat fa_sheen_albedo(float ndv, float rough)\n{\n    float _3577 = min(sqrt(max(rough - 0.100000001490116119384765625, 0.0) * 1.111111164093017578125) * 6.0, 5.999000072479248046875);\n    float _3584 = min(sqrt(clamp(ndv, 0.0, 1.0)) * 8.0, 7.999000072479248046875);\n    int _3587 = int(_3577);\n    int _3590 = int(_3584);\n    float _3600 = _3584 - float(_3590);\n    int _3655 = (_3587 * 9) + _3590;\n    int _3675 = ((_3587 + 1) * 9) + _3590;\n    return mix(mix(_3651[_3655], _3651[_3655 + 1], _3600), mix(_3651[_3675], _3651[_3675 + 1], _3600), _3577 - float(_3587));\n}\n\nFaLayers fa_layers_setup(SurfaceInput i, Surface s, vec3 n, vec3 v, float metallic, float roughness, inout vec3 f0)\n{\n    bool _6800 = false;\n    float _6801 = 1.0;\n    float _6802 = 1.0;\n    float _6803 = 1.0;\n    float _6804 = 0.0;\n    float _6805 = 0.0;\n    float _6806 = 0.0;\n    float _6807 = 0.0;\n    float _6809 = 1.0;\n    bool _6810 = false;\n    vec3 _6811 = vec3(0.0);\n    float _6812 = 1.0;\n    float _6813 = 1.0;\n    float _6814 = 1.0;\n    float _6815 = 0.0;\n    float _6816 = 0.0;\n    vec3 _6817 = vec3(1.0, 0.0, 0.0);\n    vec3 _6818 = vec3(0.0, 0.0, 1.0);\n    float _6819 = 1.0;\n    float _6820 = 1.0;\n    float _3726 = clamp(s.specular, 0.0, 1.0);\n    float _3730 = clamp(s.ior, 1.0, 3.0);\n    bool _3735 = (_3726 != 1.0) || (_3730 != 1.5);\n    bool _3744;\n    if (!_3735)\n    {\n        _3744 = any(notEqual(s.specular_color, vec3(1.0)));\n    }\n    else\n    {\n        _3744 = _3735;\n    }\n    if (_3744)\n    {\n        float _3752 = (_3730 - 1.0) / (_3730 + 1.0);\n        f0 = mix(min(vec3(_3752 * _3752) * max(s.specular_color, vec3(0.0)), vec3(1.0)) * _3726, s.albedo, vec3(metallic));\n        _6801 = mix(_3726, 1.0, metallic);\n        _6800 = true;\n    }\n    float _3779 = clamp(s.clearcoat, 0.0, 1.0);\n    if (_3779 > 0.0)\n    {\n        float _3787 = clamp(s.clearcoat_roughness, 0.0500000007450580596923828125, 1.0);\n        _6804 = _3779;\n        _6805 = _3787;\n        float _3794 = _3787 * _3787;\n        _6806 = _3794;\n        _6807 = _3794 * _3794;\n        float _3806 = max(dot(i.world_normal, v), 9.9999997473787516355514526367188e-05);\n        _6809 = _3806;\n        _6802 = 1.0 - (_3779 * (0.039999999105930328369140625 + (0.959999978542327880859375 * pow(clamp(1.0 - _3806, 0.0, 1.0), 5.0))));\n        _6800 = true;\n    }\n    vec3 _3825 = max(s.sheen_color, vec3(0.0));\n    float _3834 = max(_3825.x, max(_3825.y, _3825.z));\n    if (_3834 > 0.0)\n    {\n        float _3842 = clamp(s.sheen_roughness, 0.100000001490116119384765625, 1.0);\n        _6810 = true;\n        _6811 = _3825;\n        _6812 = _3842;\n        _6813 = _3842 * _3842;\n        float param = max(dot(n, v), 9.9999997473787516355514526367188e-05);\n        float param_1 = _3842;\n        float _3859 = fa_sheen_albedo(param, param_1);\n        _6815 = _3859;\n        _6814 = 1.0 - min(_3834 * _3859, 1.0);\n        _6800 = true;\n    }\n    _6803 = _6802 * _6814;\n    float _3878 = clamp(s.anisotropy, -1.0, 1.0);\n    if (_3878 != 0.0)\n    {\n        vec3 _3893 = i.world_tangent.xyz - (n * dot(n, i.world_tangent.xyz));\n        vec3 t = _3893;\n        if (dot(_3893, _3893) < 9.9999999392252902907785028219223e-09)\n        {\n            bvec3 _3905 = bvec3(abs(n.y) < 0.9900000095367431640625);\n            t = cross(vec3(_3905.x ? vec3(0.0, 1.0, 0.0).x : vec3(1.0, 0.0, 0.0).x, _3905.y ? vec3(0.0, 1.0, 0.0).y : vec3(1.0, 0.0, 0.0).y, _3905.z ? vec3(0.0, 1.0, 0.0).z : vec3(1.0, 0.0, 0.0).z), n);\n        }\n        vec3 _3909 = t;\n        vec3 _3910 = normalize(_3909);\n        t = _3910;\n        vec3 _3935 = normalize((_3910 * cos(s.anisotropy_rotation)) + ((cross(n, _3910) * ((i.world_tangent.w < 0.0) ? (-1.0) : 1.0)) * sin(s.anisotropy_rotation)));\n        _6817 = _3935;\n        _6818 = cross(n, _3935);\n        float _3945 = roughness * roughness;\n        float _3951 = mix(_3945, 1.0, _3878 * _3878);\n        bool _3953 = _3878 > 0.0;\n        _6819 = _3953 ? _3951 : _3945;\n        _6820 = _3953 ? _3945 : _3951;\n        _6816 = _3878;\n        _6800 = true;\n    }\n    return FaLayers(_6800, _6801, _6802, _6803, _6804, _6805, _6806, _6807, i.world_normal, _6809, _6810, _6811, _6812, _6813, _6814, _6815, _6816, _6817, _6818, _6819, _6820);\n}\n\nvec3 fa_sky_sh_coef(int k)\n{\n    vec3 v = textureLod(fa_env_tex_fa_env_smp, vec3(1.0, 1.0 - (float((2 * (k >> 2)) + 1) * 0.25), 1.0 - (float((2 * (k & 3)) + 1) * 0.25)), 5.0).xyz;\n    if (fa_mesh_fs_params[11].w > 1.5)\n    {\n        v = (v - vec3(0.5)) * 8.0;\n    }\n    return v;\n}\n\nvec3 fa_sh_eval(vec3 c[9], vec3 n)\n{\n    vec3 _3334 = max((((c[0] * 0.2820948064327239990234375) + (((c[1] * (0.3257350027561187744140625 * n.y)) + (c[2] * (0.3257350027561187744140625 * n.z))) + (c[3] * (0.3257350027561187744140625 * n.x)))) + (((c[4] * ((0.2731371223926544189453125 * n.x) * n.y)) + (c[5] * ((0.2731371223926544189453125 * n.y) * n.z))) + (c[6] * (0.078847892582416534423828125 * (((3.0 * n.z) * n.z) - 1.0))))) + ((c[7] * ((0.2731371223926544189453125 * n.x) * n.z)) + (c[8] * (0.13656856119632720947265625 * ((n.x * n.x) - (n.y * n.y))))), vec3(0.0));\n    return _3334;\n}\n\nvec3 fa_ambient_light(vec3 n)\n{\n    if (fa_mesh_fs_params[11].w > 0.5)\n    {\n        vec3 c[9];\n        for (int k = 0; k < 9; k++)\n        {\n            int param = k;\n            c[k] = fa_sky_sh_coef(param);\n        }\n        vec3 param_1[9] = c;\n        vec3 param_2 = n;\n        return fa_sh_eval(param_1, param_2);\n    }\n    return fa_mesh_fs_params[1].xyz;\n}\n\nvec3 fa_indirect_diffuse(vec3 n)\n{\n    if (fa_lm.z > 0.5)\n    {\n        return textureLod(fa_lightmap_fa_env_smp, fa_lm.xy, 0.0).xyz;\n    }\n    vec3 param = n;\n    return fa_ambient_light(param);\n}\n\nint fa_cluster_index(int slot, int n)\n{\n    int param = (int(fa_mesh_fs_params[19].x) + int(fa_mesh_fs_params[19].w)) + ((slot + n) >> 2);\n    vec4 t = fa_light_texel(param);\n    return int(t[(slot + n) & 3]);\n}\n\nint fa_cl_light(int n)\n{\n    if (n < fa_cl_ndir)\n    {\n        return n;\n    }\n    int param = fa_cl_slot;\n    int param_1 = n - fa_cl_ndir;\n    return fa_cluster_index(param, param_1);\n}\n\nint fa_light_base(int li)\n{\n    return li * ((fa_mesh_fs_params[1].w > 4.5) ? 8 : 4);\n}\n\nbool fa_light_baked(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 3;\n    return fa_light_texel(param_1).w > 0.5;\n}\n\nfloat fa_light_type(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 1;\n    return fa_light_texel(param_1).w;\n}\n\nvec4 fa_atlas_fetch(vec2 texel)\n{\n    return textureLod(fa_light_atlas_fa_env_smp, texel / vec2(textureSize(fa_light_atlas_fa_env_smp, 0)), 0.0);\n}\n\nvec3 fa_cookie_sample(vec2 tile_origin, vec2 uv)\n{\n    vec2 param = (tile_origin + vec2(1.0)) + (clamp(uv, vec2(0.0), vec2(1.0)) * 254.0);\n    return fa_atlas_fetch(param).xyz;\n}\n\nvec3 fa_area_point(vec3 c, vec3 axis, vec3 ru, vec3 uu, float hx, float hy, float shape, vec3 p, vec3 r)\n{\n    bool _741 = dot(r, r) > 0.5;\n    if (shape > 1.5)\n    {\n        vec3 _754 = (c - (ru * hx)) - p;\n        vec3 _760 = ru * (2.0 * hx);\n        float _766 = max(dot(_760, _760), 9.9999999392252902907785028219223e-09);\n        float _770 = dot(_754, _760);\n        float t = clamp((-_770) / _766, 0.0, 1.0);\n        if (_741)\n        {\n            float _785 = dot(r, _760);\n            float _791 = _766 - (_785 * _785);\n            if (abs(_791) > (9.9999997473787516355514526367188e-06 * _766))\n            {\n                t = clamp(((dot(r, _754) * _785) - _770) / _791, 0.0, 1.0);\n            }\n        }\n        return (p + _754) + (_760 * t);\n    }\n    vec3 q = p;\n    float _823 = dot(r, axis);\n    bool _831;\n    if (_741)\n    {\n        _831 = abs(_823) > 9.9999997473787516355514526367188e-05;\n    }\n    else\n    {\n        _831 = _741;\n    }\n    if (_831)\n    {\n        float _841 = dot(c - p, axis) / _823;\n        if (_841 > 0.0)\n        {\n            q = p + (r * _841);\n        }\n    }\n    vec3 _854 = q - c;\n    vec2 xy = vec2(dot(_854, ru), dot(_854, uu));\n    if (shape > 0.5)\n    {\n        float _869 = length(xy);\n        if (_869 > hx)\n        {\n            xy *= (hx / _869);\n        }\n    }\n    else\n    {\n        xy = clamp(xy, vec2(-hx, -hy), vec2(hx, hy));\n    }\n    return (c + (ru * xy.x)) + (uu * xy.y);\n}\n\nint fa_cube_face(vec3 d)\n{\n    vec3 _503 = abs(d);\n    float _505 = _503.x;\n    float _507 = _503.y;\n    bool _508 = _505 >= _507;\n    bool _516;\n    if (_508)\n    {\n        _516 = _505 >= _503.z;\n    }\n    else\n    {\n        _516 = _508;\n    }\n    int _517;\n    if (_516)\n    {\n        _517 = (d.x > 0.0) ? 0 : 1;\n    }\n    else\n    {\n        int _532;\n        if (_507 >= _503.z)\n        {\n            _532 = (d.y > 0.0) ? 2 : 3;\n        }\n        else\n        {\n            _532 = (d.z > 0.0) ? 4 : 5;\n        }\n        _517 = _532;\n    }\n    return _517;\n}\n\nvoid fa_cube_face_basis(int f, out vec3 fwd, out vec3 up)\n{\n    if (f == 0)\n    {\n        fwd = vec3(1.0, 0.0, 0.0);\n        up = vec3(0.0, 1.0, 0.0);\n    }\n    else\n    {\n        if (f == 1)\n        {\n            fwd = vec3(-1.0, 0.0, 0.0);\n            up = vec3(0.0, 1.0, 0.0);\n        }\n        else\n        {\n            if (f == 2)\n            {\n                fwd = vec3(0.0, 1.0, 0.0);\n                up = vec3(0.0, 0.0, 1.0);\n            }\n            else\n            {\n                if (f == 3)\n                {\n                    fwd = vec3(0.0, -1.0, 0.0);\n                    up = vec3(0.0, 0.0, -1.0);\n                }\n                else\n                {\n                    if (f == 4)\n                    {\n                        fwd = vec3(0.0, 0.0, 1.0);\n                        up = vec3(0.0, 1.0, 0.0);\n                    }\n                    else\n                    {\n                        fwd = vec3(0.0, 0.0, -1.0);\n                        up = vec3(0.0, 1.0, 0.0);\n                    }\n                }\n            }\n        }\n    }\n}\n\nfloat fa_ies_sample(vec2 tile_origin, vec3 d, vec3 axis, vec3 right, vec3 up)\n{\n    float _661 = dot(d, right);\n    float _665 = dot(d, up);\n    float _676;\n    if (((_661 * _661) + (_665 * _665)) > 1.0000000133514319600180897396058e-10)\n    {\n        _676 = atan(_665, _661) * 0.15915493667125701904296875;\n    }\n    else\n    {\n        _676 = 0.0;\n    }\n    vec2 param = tile_origin + vec2(1.0 + ((_676 - floor(_676)) * 64.0), 1.0 + (acos(clamp(dot(d, axis), -1.0, 1.0)) * 10.18591594696044921875));\n    return fa_atlas_fetch(param).x;\n}\n\nLightSample fa_light_sample_n(int li, vec3 world_pos, vec3 n)\n{\n    int param = li;\n    int _907 = fa_light_base(param);\n    bool _911 = fa_mesh_fs_params[1].w > 4.5;\n    int param_1 = _907;\n    vec4 _915 = fa_light_texel(param_1);\n    int param_2 = _907 + 1;\n    vec4 _920 = fa_light_texel(param_2);\n    float _923 = _920.w;\n    float atten = 1.0;\n    float dist = 0.0;\n    fa_light_tint = vec3(1.0);\n    bool _935 = _911 && (_923 > 2.5);\n    fa_light_is_area = _935;\n    bool _937 = _923 < 0.5;\n    vec3 l;\n    if (_937)\n    {\n        l = normalize(_915.xyz);\n        if (_911)\n        {\n            int param_3 = _907 + 6;\n            vec4 _951 = fa_light_texel(param_3);\n            if (_951.z > 0.5)\n            {\n                int param_4 = _907 + 4;\n                vec4 _961 = fa_light_texel(param_4);\n                int param_5 = _907 + 5;\n                vec4 _966 = fa_light_texel(param_5);\n                vec2 param_6 = _951.xy;\n                vec2 param_7 = fract(vec2(dot(world_pos, _961.xyz) * _961.w, (-dot(world_pos, _966.xyz)) * _966.w) + vec2(0.5));\n                fa_light_tint = fa_cookie_sample(param_6, param_7);\n            }\n        }\n    }\n    else\n    {\n        vec3 _996 = _915.xyz;\n        vec3 _998 = _996 - world_pos;\n        vec3 to_light = _998;\n        float _1001 = length(_998);\n        float reach = _1001;\n        bool front = true;\n        if (_935)\n        {\n            int param_8 = _907 + 7;\n            reach = max(_1001 - fa_light_texel(param_8).w, 0.0);\n            int param_9 = _907 + 4;\n            vec4 _1025 = fa_light_texel(param_9);\n            int param_10 = _907 + 5;\n            vec4 _1030 = fa_light_texel(param_10);\n            int param_11 = _907 + 6;\n            vec4 _1035 = fa_light_texel(param_11);\n            float _1036 = _1035.w;\n            int param_12 = _907 + 2;\n            vec3 _1043 = normalize(fa_light_texel(param_12).xyz);\n            bool _1045 = _1036 > 1.5;\n            bool _1053;\n            if (!_1045)\n            {\n                _1053 = dot(_1043, to_light) < 0.0;\n            }\n            else\n            {\n                _1053 = _1045;\n            }\n            front = _1053;\n            vec3 r = vec3(0.0);\n            vec3 _1062 = fa_mesh_fs_params[0].xyz - world_pos;\n            bool _1066 = dot(n, n) > 0.5;\n            bool _1074;\n            if (_1066)\n            {\n                _1074 = dot(_1062, _1062) > 9.9999999600419720025001879548654e-13;\n            }\n            else\n            {\n                _1074 = _1066;\n            }\n            if (_1074)\n            {\n                r = reflect(-normalize(_1062), normalize(n));\n            }\n            vec3 param_13 = _996;\n            vec3 param_14 = _1043;\n            vec3 param_15 = _1025.xyz;\n            vec3 param_16 = _1030.xyz;\n            float param_17 = _1025.w;\n            float param_18 = _1030.w;\n            float param_19 = _1036;\n            vec3 param_20 = world_pos;\n            vec3 param_21 = r;\n            to_light = fa_area_point(param_13, param_14, param_15, param_16, param_17, param_18, param_19, param_20, param_21) - world_pos;\n        }\n        float _1110 = length(to_light);\n        dist = _1110;\n        l = to_light / vec3(max(_1110, 9.9999997473787516355514526367188e-05));\n        float _1124 = reach / max(_915.w, 0.001000000047497451305389404296875);\n        float _1130 = clamp(1.0 - (_1124 * _1124), 0.0, 1.0);\n        float _1132;\n        if (front)\n        {\n            _1132 = _1130 * _1130;\n        }\n        else\n        {\n            _1132 = 0.0;\n        }\n        atten = _1132;\n        bool _1143 = _923 < 2.5;\n        if ((_923 > 1.5) && _1143)\n        {\n            int param_22 = _907 + 2;\n            vec4 _1151 = fa_light_texel(param_22);\n            float _1161 = _1151.w;\n            int param_23 = _907 + 3;\n            vec4 _1166 = fa_light_texel(param_23);\n            float _1167 = _1166.x;\n            float cos_inner = _1167;\n            if (_1167 > 1.5)\n            {\n                cos_inner = mix(_1161, 1.0, 0.25);\n            }\n            atten *= smoothstep(_1161, cos_inner, dot(-l, normalize(_1151.xyz)));\n        }\n        if (_911 && (_923 < 1.5))\n        {\n            int param_24 = _907 + 6;\n            vec4 _1191 = fa_light_texel(param_24);\n            if (_1191.z > 0.5)\n            {\n                vec3 _1199 = -to_light;\n                int param_25 = _907 + 4;\n                int param_26 = _907 + 5;\n                vec3 _1213 = fa_light_texel(param_25).xyz;\n                vec3 _1217 = fa_light_texel(param_26).xyz;\n                vec3 _1226 = vec3(dot(_1199, _1213), dot(_1199, _1217), dot(_1199, cross(_1213, _1217)));\n                vec3 param_27 = _1226;\n                int _1230 = fa_cube_face(param_27);\n                int param_28 = _1230;\n                vec3 param_29;\n                vec3 param_30;\n                fa_cube_face_basis(param_28, param_29, param_30);\n                vec2 _1257 = vec2(dot(_1226, cross(param_29, param_30)), dot(_1226, param_30)) / vec2(max(dot(_1226, param_29), 9.9999997473787516355514526367188e-05));\n                int _1261 = _1230 / 3;\n                vec2 param_31 = _1191.xy + (vec2(float(_1230 - (_1261 * 3)), float(_1261)) * 256.0);\n                vec2 param_32 = vec2(0.5 + (0.5 * _1257.x), 0.5 - (0.5 * _1257.y));\n                fa_light_tint = fa_cookie_sample(param_31, param_32);\n            }\n            int param_33 = _907 + 7;\n            vec4 _1291 = fa_light_texel(param_33);\n            if (_1291.z > 0.5)\n            {\n                int param_34 = _907 + 2;\n                int param_35 = _907 + 4;\n                int param_36 = _907 + 5;\n                vec2 param_37 = _1291.xy;\n                vec3 param_38 = -l;\n                vec3 param_39 = normalize(fa_light_texel(param_34).xyz);\n                vec3 param_40 = fa_light_texel(param_35).xyz;\n                vec3 param_41 = fa_light_texel(param_36).xyz;\n                atten *= fa_ies_sample(param_37, param_38, param_39, param_40, param_41);\n            }\n        }\n        else\n        {\n            if (_911 && _1143)\n            {\n                int param_42 = _907 + 6;\n                vec4 _1338 = fa_light_texel(param_42);\n                int param_43 = _907 + 7;\n                vec4 _1343 = fa_light_texel(param_43);\n                bool _1346 = _1338.z > 0.5;\n                bool _1353;\n                if (!_1346)\n                {\n                    _1353 = _1343.z > 0.5;\n                }\n                else\n                {\n                    _1353 = _1346;\n                }\n                if (_1353)\n                {\n                    int param_44 = _907 + 2;\n                    vec4 _1360 = fa_light_texel(param_44);\n                    vec3 _1364 = normalize(_1360.xyz);\n                    int param_45 = _907 + 4;\n                    vec4 _1369 = fa_light_texel(param_45);\n                    int param_46 = _907 + 5;\n                    vec4 _1374 = fa_light_texel(param_46);\n                    if (_1346)\n                    {\n                        vec3 _1382 = -to_light;\n                        float _1389 = _1360.w;\n                        float _1405 = 0.5 / max(dot(_1382, _1364) * (sqrt(max(1.0 - (_1389 * _1389), 0.0)) / max(_1389, 0.001000000047497451305389404296875)), 9.9999997473787516355514526367188e-05);\n                        vec2 param_47 = _1338.xy;\n                        vec2 param_48 = vec2(0.5 + (dot(_1382, _1369.xyz) * _1405), 0.5 - (dot(_1382, _1374.xyz) * _1405));\n                        fa_light_tint = fa_cookie_sample(param_47, param_48);\n                    }\n                    if (_1343.z > 0.5)\n                    {\n                        vec2 param_49 = _1343.xy;\n                        vec3 param_50 = -l;\n                        vec3 param_51 = _1364;\n                        vec3 param_52 = _1369.xyz;\n                        vec3 param_53 = _1374.xyz;\n                        atten *= fa_ies_sample(param_49, param_50, param_51, param_52, param_53);\n                    }\n                }\n            }\n        }\n    }\n    vec3 _6788 = _920.xyz * atten;\n    if (_911)\n    {\n        _6788 *= fa_light_tint;\n    }\n    int _1474;\n    if (_937)\n    {\n        _1474 = 0;\n    }\n    else\n    {\n        _1474 = ((_923 > 1.5) && (_923 < 2.5)) ? 2 : 1;\n    }\n    return LightSample(l, _6788, atten, 1.0, dist, _1474);\n}\n\nfloat fa_shadow_split_at(int i)\n{\n    float _2211;\n    if (i == 0)\n    {\n        _2211 = fa_shadows[24].x;\n    }\n    else\n    {\n        float _2227;\n        if (i == 1)\n        {\n            _2227 = fa_shadows[24].y;\n        }\n        else\n        {\n            float _2235;\n            if (i == 2)\n            {\n                _2235 = fa_shadows[24].z;\n            }\n            else\n            {\n                _2235 = fa_shadows[24].w;\n            }\n            _2227 = _2235;\n        }\n        _2211 = _2227;\n    }\n    return _2211;\n}\n\nfloat fa_shadow_depth(inout vec2 uv, vec4 rect)\n{\n    uv = clamp(uv, rect.xy, rect.zw);\n    return textureLod(fa_shadow_tex_fa_shadow_smp, uv, 0.0).x;\n}\n\nfloat fa_shadow_fetch(vec2 uv, vec4 rect, vec3 conv)\n{\n    vec2 param = uv;\n    vec4 param_1 = rect;\n    float _2268 = fa_shadow_depth(param, param_1);\n    float _2272;\n    if (conv.x < 0.5)\n    {\n        _2272 = _2268;\n    }\n    else\n    {\n        _2272 = (conv.y * conv.z) / (conv.z - (_2268 * (conv.z - conv.y)));\n    }\n    return _2272;\n}\n\nfloat fa_shadow_noise()\n{\n    return fract(52.98291778564453125 * fract(dot(gl_FragCoord.xy, vec2(0.067110560834407806396484375, 0.005837149918079376220703125))));\n}\n\nvec2 fa_shadow_vogel(int k, int n, float phi)\n{\n    float _2199 = (float(k) * 2.3999631404876708984375) + phi;\n    return vec2(cos(_2199), sin(_2199)) * sqrt((float(k) + 0.5) / float(n));\n}\n\nfloat fa_shadow_filter(vec2 uv, vec4 rect, float zr, float texel_m, float unit, float reach, float plane, vec3 conv, int mode, float k)\n{\n    if (mode == 1)\n    {\n        vec2 param = uv;\n        vec4 param_1 = rect;\n        vec3 param_2 = conv;\n        return float(zr <= fa_shadow_fetch(param, param_1, param_2));\n    }\n    float _2318 = fa_shadow_noise() * 6.283185482025146484375;\n    float radius = 1.5;\n    if (mode == 2)\n    {\n        float _2327;\n        if (k < 0.0)\n        {\n            _2327 = (-k) / max(zr, 0.100000001490116119384765625);\n        }\n        else\n        {\n            _2327 = k;\n        }\n        float _2347 = clamp((_2327 * reach) / texel_m, 3.0, 12.0);\n        float sum = 0.0;\n        float cnt = 0.0;\n        for (int i = 0; i < 16; i++)\n        {\n            int param_3 = i;\n            int param_4 = 16;\n            float param_5 = _2318;\n            vec2 _2366 = fa_shadow_vogel(param_3, param_4, param_5) * _2347;\n            vec2 param_6 = uv + (_2366 * fa_shadows[26].zw);\n            vec4 param_7 = rect;\n            vec3 param_8 = conv;\n            float _2378 = fa_shadow_fetch(param_6, param_7, param_8);\n            if (_2378 < (zr - (length(_2366) * plane)))\n            {\n                sum += _2378;\n                cnt += 1.0;\n            }\n        }\n        if (cnt < 0.5)\n        {\n            return 1.0;\n        }\n        float _2404 = sum / cnt;\n        float _2414;\n        if (k < 0.0)\n        {\n            _2414 = (-k) / max(_2404, 0.0500000007450580596923828125);\n        }\n        else\n        {\n            _2414 = k;\n        }\n        radius = clamp(((max(zr - _2404, 0.0) * unit) * _2414) / texel_m, 1.5, 16.0);\n    }\n    float lit = 0.0;\n    int _2436 = (mode == 2) ? 24 : 16;\n    for (int i_1 = 0; i_1 < _2436; i_1++)\n    {\n        int param_9 = i_1;\n        int param_10 = _2436;\n        float param_11 = _2318;\n        vec2 _2455 = fa_shadow_vogel(param_9, param_10, param_11) * radius;\n        vec2 param_12 = uv + (_2455 * fa_shadows[26].zw);\n        vec4 param_13 = rect;\n        vec3 param_14 = conv;\n        lit += float((zr - (length(_2455) * plane)) <= fa_shadow_fetch(param_12, param_13, param_14));\n    }\n    return lit / float(_2436);\n}\n\nfloat fa_shadow_cascade(int ci, vec3 world, vec3 n, vec3 l)\n{\n    float _2497 = max(fa_shadows[ci * 1 + 20].y, 0.001000000047497451305389404296875);\n    float _2502 = clamp(dot(n, l), 0.0, 1.0);\n    float _2508 = sqrt(1.0 - (_2502 * _2502));\n    float _2515 = min(_2508 / max(_2502, 0.20000000298023223876953125), 4.0);\n    float _2520;\n    if (fa_shadows[26].y > 0.0)\n    {\n        _2520 = fa_shadows[26].y;\n    }\n    else\n    {\n        _2520 = 1.5 * fa_shadows[ci * 1 + 20].x;\n    }\n    vec4 _2545 = mat4(fa_shadows[ci * 4 + 0], fa_shadows[ci * 4 + 1], fa_shadows[ci * 4 + 2], fa_shadows[ci * 4 + 3]) * vec4(world + (n * (_2520 * _2508)), 1.0);\n    float _2552 = _2545.x;\n    bool _2555 = _2552 < fa_shadows[ci * 1 + 16].x;\n    bool _2564;\n    if (!_2555)\n    {\n        _2564 = _2552 > fa_shadows[ci * 1 + 16].z;\n    }\n    else\n    {\n        _2564 = _2555;\n    }\n    bool _2573;\n    if (!_2564)\n    {\n        _2573 = _2545.y < fa_shadows[ci * 1 + 16].y;\n    }\n    else\n    {\n        _2573 = _2564;\n    }\n    bool _2582;\n    if (!_2573)\n    {\n        _2582 = _2545.y > fa_shadows[ci * 1 + 16].w;\n    }\n    else\n    {\n        _2582 = _2573;\n    }\n    bool _2589;\n    if (!_2582)\n    {\n        _2589 = _2545.z > 1.0;\n    }\n    else\n    {\n        _2589 = _2582;\n    }\n    if (_2589)\n    {\n        return -1.0;\n    }\n    float _2597;\n    if (fa_shadows[26].x > 0.0)\n    {\n        _2597 = fa_shadows[26].x;\n    }\n    else\n    {\n        _2597 = 1.5 * fa_shadows[ci * 1 + 20].x;\n    }\n    vec2 param = _2545.xy;\n    vec4 param_1 = fa_shadows[ci * 1 + 16];\n    float param_2 = _2545.z - ((_2597 * (1.0 + (0.5 * _2515))) / _2497);\n    float param_3 = fa_shadows[ci * 1 + 20].x;\n    float param_4 = _2497;\n    float param_5 = _2497 * 0.25;\n    float param_6 = ((fa_shadows[ci * 1 + 20].x * min(_2515, 3.0)) * 0.5) / _2497;\n    vec3 param_7 = vec3(0.0);\n    int param_8 = int(fa_shadows[25].z + 0.5);\n    float param_9 = fa_shadows[25].w;\n    return fa_shadow_filter(param, param_1, param_2, param_3, param_4, param_5, param_6, param_7, param_8, param_9);\n}\n\nfloat fa_shadow_sun(vec3 world, vec3 n, vec3 l)\n{\n    if (fa_mesh_fs_params[5].z < 0.5)\n    {\n        return 1.0;\n    }\n    int _2975 = int(fa_shadows[25].x + 0.5);\n    if (_2975 < 1)\n    {\n        return 1.0;\n    }\n    float _2990 = dot(world - fa_shadows[27].xyz, fa_shadows[28].xyz);\n    int param = _2975 - 1;\n    if (_2990 > fa_shadow_split_at(param))\n    {\n        return 1.0;\n    }\n    int ci = 0;\n    bool _3002 = _2975 > 1;\n    bool _3009;\n    if (_3002)\n    {\n        _3009 = _2990 > fa_shadows[24].x;\n    }\n    else\n    {\n        _3009 = _3002;\n    }\n    if (_3009)\n    {\n        ci = 1;\n    }\n    bool _3013 = _2975 > 2;\n    bool _3020;\n    if (_3013)\n    {\n        _3020 = _2990 > fa_shadows[24].y;\n    }\n    else\n    {\n        _3020 = _3013;\n    }\n    if (_3020)\n    {\n        ci = 2;\n    }\n    bool _3024 = _2975 > 3;\n    bool _3031;\n    if (_3024)\n    {\n        _3031 = _2990 > fa_shadows[24].z;\n    }\n    else\n    {\n        _3031 = _3024;\n    }\n    if (_3031)\n    {\n        ci = 3;\n    }\n    float s = -1.0;\n    for (int k = 0; k < 4; k++)\n    {\n        if (ci >= _2975)\n        {\n            break;\n        }\n        int param_1 = ci;\n        vec3 param_2 = world;\n        vec3 param_3 = n;\n        vec3 param_4 = l;\n        float _3057 = fa_shadow_cascade(param_1, param_2, param_3, param_4);\n        s = _3057;\n        if (_3057 >= 0.0)\n        {\n            break;\n        }\n        ci++;\n    }\n    if (s < 0.0)\n    {\n        return 1.0;\n    }\n    if (fa_shadows[25].y > 0.0)\n    {\n        float _3082;\n        if (ci > 0)\n        {\n            int param_5 = ci - 1;\n            _3082 = fa_shadow_split_at(param_5);\n        }\n        else\n        {\n            _3082 = fa_shadows[28].w;\n        }\n        int param_6 = ci;\n        float _3101 = fa_shadows[25].y * max(fa_shadow_split_at(param_6) - _3082, 9.9999997473787516355514526367188e-05);\n        int param_7 = ci;\n        float _3112 = clamp((_2990 - (fa_shadow_split_at(param_7) - _3101)) / _3101, 0.0, 1.0);\n        if (_3112 > 0.0)\n        {\n            float s2 = 1.0;\n            if ((ci + 1) < _2975)\n            {\n                int param_8 = ci + 1;\n                vec3 param_9 = world;\n                vec3 param_10 = n;\n                vec3 param_11 = l;\n                float _3133 = fa_shadow_cascade(param_8, param_9, param_10, param_11);\n                s2 = _3133;\n                if (_3133 < 0.0)\n                {\n                    s2 = s;\n                }\n            }\n            s = mix(s, s2, _3112);\n        }\n    }\n    return s;\n}\n\nfloat fa_shadow_factor(vec3 n, vec3 l)\n{\n    vec3 param = fa_world_pos;\n    vec3 param_1 = n;\n    vec3 param_2 = l;\n    return fa_shadow_sun(param, param_1, param_2);\n}\n\nfloat fa_shadow_local(int li, vec3 lpos, vec3 world, vec3 n, vec3 l)\n{\n    bool _2655 = fa_mesh_fs_params[5].z < 0.5;\n    bool _2662;\n    if (!_2655)\n    {\n        _2662 = fa_shadows[29].x < 0.5;\n    }\n    else\n    {\n        _2662 = _2655;\n    }\n    if (_2662)\n    {\n        return 1.0;\n    }\n    int param = (int(fa_shadows[29].x + 0.5) - 1) + li;\n    vec4 _2675 = fa_light_texel(param);\n    float _2676 = _2675.x;\n    if (_2676 < 0.0)\n    {\n        return 1.0;\n    }\n    int _2685 = int(_2676 + 0.5);\n    int param_1 = _2685;\n    vec4 _2689 = fa_light_texel(param_1);\n    int param_2 = _2685 + 1;\n    vec4 _2694 = fa_light_texel(param_2);\n    float fade = 1.0;\n    float _2697 = _2689.y;\n    if (_2697 > 0.0)\n    {\n        float _2714 = 1.0 - smoothstep(0.75 * _2697, _2697, length(world - fa_shadows[27].xyz));\n        fade = _2714;\n        if (_2714 <= 0.0)\n        {\n            return 1.0;\n        }\n    }\n    int face = 0;\n    if (_2689.x > 1.5)\n    {\n        vec3 param_3 = world - lpos;\n        face = fa_cube_face(param_3);\n    }\n    int _2738 = (_2685 + 2) + (face * 6);\n    int param_4 = _2738;\n    int param_5 = _2738 + 1;\n    int param_6 = _2738 + 3;\n    vec4 _2752 = fa_light_texel(param_6);\n    int param_7 = _2738 + 4;\n    vec4 _2757 = fa_light_texel(param_7);\n    int param_8 = _2738 + 5;\n    vec4 _2762 = fa_light_texel(param_8);\n    float _2774 = _2762.x * max(dot(_2752, vec4(world, 1.0)), 0.001000000047497451305389404296875);\n    float _2779 = clamp(dot(n, l), 0.0, 1.0);\n    float _2802 = clamp(dot(n, _2752.xyz), -1.0, 1.0);\n    float _2821 = min(sqrt(1.0 - (_2802 * _2802)) / max(abs(dot(n, world - lpos)) / max(dot(_2752, vec4(world, 1.0)), 0.001000000047497451305389404296875), 0.20000000298023223876953125), 4.0);\n    float _2824 = _2694.y;\n    float _2826;\n    if (_2824 > 0.0)\n    {\n        _2826 = _2824;\n    }\n    else\n    {\n        _2826 = 1.5 * _2774;\n    }\n    vec4 _2846 = vec4(world + (n * (_2826 * sqrt(1.0 - (_2779 * _2779)))), 1.0);\n    float _2850 = dot(_2752, _2846);\n    float _2853 = _2762.y;\n    if (_2850 < _2853)\n    {\n        return 1.0;\n    }\n    vec2 _2868 = vec2(dot(fa_light_texel(param_4), _2846), dot(fa_light_texel(param_5), _2846)) / vec2(_2850);\n    float _2870 = _2868.x;\n    bool _2873 = _2870 < _2757.x;\n    bool _2882;\n    if (!_2873)\n    {\n        _2882 = _2870 > _2757.z;\n    }\n    else\n    {\n        _2882 = _2873;\n    }\n    bool _2891;\n    if (!_2882)\n    {\n        _2891 = _2868.y < _2757.y;\n    }\n    else\n    {\n        _2891 = _2882;\n    }\n    bool _2900;\n    if (!_2891)\n    {\n        _2900 = _2868.y > _2757.w;\n    }\n    else\n    {\n        _2900 = _2891;\n    }\n    if (_2900)\n    {\n        return 1.0;\n    }\n    float _2906 = _2694.x;\n    float _2908;\n    if (_2906 > 0.0)\n    {\n        _2908 = _2906;\n    }\n    else\n    {\n        _2908 = 1.5 * _2774;\n    }\n    vec2 param_9 = _2868;\n    vec4 param_10 = _2757;\n    float param_11 = _2850 - (_2908 * (1.0 + (0.5 * _2821)));\n    float param_12 = _2774;\n    float param_13 = 1.0;\n    float param_14 = _2762.z * 0.25;\n    float param_15 = (_2774 * min(_2821, 3.0)) * 0.5;\n    vec3 param_16 = vec3(1.0, _2853, _2762.z);\n    int param_17 = int(_2689.z + 0.5);\n    float param_18 = _2689.w;\n    return mix(1.0, fa_shadow_filter(param_9, param_10, param_11, param_12, param_13, param_14, param_15, param_16, param_17, param_18), fade);\n}\n\nLightSample fa_light_shadowed(int li, vec3 world_pos, vec3 gn)\n{\n    bool _4497 = fa_lm.z > 0.5;\n    bool _4503;\n    if (_4497)\n    {\n        int param = li;\n        _4503 = fa_light_baked(param);\n    }\n    else\n    {\n        _4503 = _4497;\n    }\n    if (_4503)\n    {\n        int param_1 = li;\n        return LightSample(vec3(0.0, 1.0, 0.0), vec3(0.0), 0.0, 1.0, 0.0, int(fa_light_type(param_1) + 0.5));\n    }\n    int param_2 = li;\n    vec3 param_3 = world_pos;\n    vec3 param_4 = gn;\n    LightSample _4527 = fa_light_sample_n(param_2, param_3, param_4);\n    vec3 _6857 = _4527.color;\n    float _6859 = _4527.shadow;\n    if ((_4527.type == 0) && (li == 0))\n    {\n        vec3 param_5 = gn;\n        vec3 param_6 = _4527.direction;\n        float _4541 = fa_shadow_factor(param_5, param_6);\n        _6859 = _4541;\n        _6857 *= _4541;\n    }\n    else\n    {\n        bool _4552 = _4527.type != 0;\n        bool _4558;\n        if (_4552)\n        {\n            _4558 = _4527.attenuation > 0.0;\n        }\n        else\n        {\n            _4558 = _4552;\n        }\n        if (_4558)\n        {\n            int param_7 = li;\n            int param_8 = fa_light_base(param_7);\n            int param_9 = li;\n            vec3 param_10 = fa_light_texel(param_8).xyz;\n            vec3 param_11 = world_pos;\n            vec3 param_12 = gn;\n            vec3 param_13 = _4527.direction;\n            float _4577 = fa_shadow_local(param_9, param_10, param_11, param_12, param_13);\n            _6859 = _4577;\n            _6857 *= _4577;\n        }\n    }\n    return LightSample(_4527.direction, _6857, _4527.attenuation, _6859, _4527._distance, _4527.type);\n}\n\nvec3 fa_ltc_tangent(vec3 n, vec3 v)\n{\n    vec3 _4617 = v - (n * dot(v, n));\n    vec3 t = _4617;\n    float _4621 = dot(_4617, _4617);\n    float l2 = _4621;\n    if (_4621 < 1.0000000133514319600180897396058e-10)\n    {\n        vec3 _4631;\n        if (abs(n.z) < 0.999000012874603271484375)\n        {\n            _4631 = cross(n, vec3(0.0, 0.0, 1.0));\n        }\n        else\n        {\n            _4631 = cross(n, vec3(1.0, 0.0, 0.0));\n        }\n        t = _4631;\n        l2 = dot(_4631, _4631);\n    }\n    return t * inversesqrt(l2);\n}\n\nvec3 fa_ltc_local(vec3 t1, vec3 n, vec3 p)\n{\n    return vec3(dot(t1, p), dot(cross(n, t1), p), dot(n, p));\n}\n\nvec3 fa_ltc_edge_vector(vec3 a, vec3 b)\n{\n    float _4666 = dot(a, a);\n    float _4670 = dot(b, b);\n    if ((_4666 < 1.0000000195414813782625560981111e-24) || (_4670 < 1.0000000195414813782625560981111e-24))\n    {\n        return vec3(0.0);\n    }\n    vec3 _4684 = a * inversesqrt(_4666);\n    vec3 _4689 = b * inversesqrt(_4670);\n    float _4693 = dot(_4684, _4689);\n    float _4696 = abs(_4693);\n    float g = (((((((((((0.0416471660137176513671875 * _4696) - 0.1924748718738555908203125) * _4696) + 0.4179156124591827392578125) * _4696) - 0.616057217121124267578125) * _4696) + 0.777722418308258056640625) * _4696) - 0.999542415142059326171875) * _4696) + 1.570791721343994140625;\n    if (_4693 < 0.0)\n    {\n        g = (3.1415927410125732421875 * inversesqrt(max(1.0 - (_4693 * _4693), 1.0000000116860974230803549289703e-07))) - g;\n    }\n    return cross(_4684, _4689) * g;\n}\n\nvoid fa_ltc_clip_edge(vec3 a, vec3 b, inout vec3 sum, inout vec3 leave, inout vec3 enter, inout vec2 seen)\n{\n    bool _4753 = a.z > 0.0;\n    bool _4757 = b.z > 0.0;\n    if (_4753 && _4757)\n    {\n        vec3 param = a;\n        vec3 param_1 = b;\n        sum += fa_ltc_edge_vector(param, param_1);\n    }\n    else\n    {\n        if (_4753 != _4757)\n        {\n            vec3 _4792 = a + ((b - a) * (a.z / (a.z - b.z)));\n            _4792.z = 0.0;\n            if (_4753)\n            {\n                vec3 param_2 = a;\n                vec3 param_3 = _4792;\n                sum += fa_ltc_edge_vector(param_2, param_3);\n                leave = _4792;\n                seen.x = 1.0;\n            }\n            else\n            {\n                vec3 param_4 = _4792;\n                vec3 param_5 = b;\n                sum += fa_ltc_edge_vector(param_4, param_5);\n                enter = _4792;\n                seen.y = 1.0;\n            }\n        }\n    }\n}\n\nfloat fa_ltc_quad(vec4 abcd, vec3 p0, vec3 p1, vec3 p2, vec3 p3)\n{\n    vec3 _4841 = vec3((abcd.x * p0.x) + (abcd.y * p0.z), p0.y, (abcd.z * p0.x) + (abcd.w * p0.z));\n    vec3 _4867 = vec3((abcd.x * p1.x) + (abcd.y * p1.z), p1.y, (abcd.z * p1.x) + (abcd.w * p1.z));\n    vec3 _4893 = vec3((abcd.x * p2.x) + (abcd.y * p2.z), p2.y, (abcd.z * p2.x) + (abcd.w * p2.z));\n    vec3 _4919 = vec3((abcd.x * p3.x) + (abcd.y * p3.z), p3.y, (abcd.z * p3.x) + (abcd.w * p3.z));\n    vec3 sum = vec3(0.0);\n    vec3 leave = vec3(0.0);\n    vec3 enter = vec3(0.0);\n    vec3 param = _4841;\n    vec3 param_1 = _4867;\n    vec3 param_2 = vec3(0.0);\n    vec3 param_3 = vec3(0.0);\n    vec3 param_4 = vec3(0.0);\n    vec2 param_5 = vec2(0.0);\n    fa_ltc_clip_edge(param, param_1, param_2, param_3, param_4, param_5);\n    sum = param_2;\n    leave = param_3;\n    enter = param_4;\n    vec3 param_6 = _4867;\n    vec3 param_7 = _4893;\n    vec3 param_8 = param_2;\n    vec3 param_9 = param_3;\n    vec3 param_10 = param_4;\n    vec2 param_11 = param_5;\n    fa_ltc_clip_edge(param_6, param_7, param_8, param_9, param_10, param_11);\n    sum = param_8;\n    leave = param_9;\n    enter = param_10;\n    vec3 param_12 = _4893;\n    vec3 param_13 = _4919;\n    vec3 param_14 = param_8;\n    vec3 param_15 = param_9;\n    vec3 param_16 = param_10;\n    vec2 param_17 = param_11;\n    fa_ltc_clip_edge(param_12, param_13, param_14, param_15, param_16, param_17);\n    sum = param_14;\n    leave = param_15;\n    enter = param_16;\n    vec3 param_18 = _4919;\n    vec3 param_19 = _4841;\n    vec3 param_20 = param_14;\n    vec3 param_21 = param_15;\n    vec3 param_22 = param_16;\n    vec2 param_23 = param_17;\n    fa_ltc_clip_edge(param_18, param_19, param_20, param_21, param_22, param_23);\n    sum = param_20;\n    leave = param_21;\n    enter = param_22;\n    if ((param_23.x * param_23.y) > 0.5)\n    {\n        vec3 param_24 = leave;\n        vec3 param_25 = enter;\n        sum += fa_ltc_edge_vector(param_24, param_25);\n    }\n    return sum.z * 0.15915493667125701904296875;\n}\n\nfloat fa_ltc_rect(vec4 abcd, vec3 center, vec3 ex, vec3 ey)\n{\n    vec4 param = abcd;\n    vec3 param_1 = (center - ex) - ey;\n    vec3 param_2 = (center + ex) - ey;\n    vec3 param_3 = (center + ex) + ey;\n    vec3 param_4 = (center - ex) + ey;\n    return abs(fa_ltc_quad(param, param_1, param_2, param_3, param_4));\n}\n\nfloat fa_area_form(vec4 m, float shape, vec3 pc, vec3 ex, vec3 ey)\n{\n    if ((shape < 0.5) || (shape > 1.5))\n    {\n        vec4 param = m;\n        vec3 param_1 = pc;\n        vec3 param_2 = ex;\n        vec3 param_3 = ey;\n        return fa_ltc_rect(param, param_1, param_2, param_3);\n    }\n    vec3 _5069 = (pc + (ex * 0.92387950420379638671875)) + (ey * 0.3826834261417388916015625);\n    vec3 _5093 = (pc - (ex * 0.92387950420379638671875)) + (ey * 0.3826834261417388916015625);\n    vec3 _5109 = (pc - (ex * 0.3826834261417388916015625)) - (ey * 0.92387950420379638671875);\n    vec4 param_4 = m;\n    vec3 param_5 = _5069;\n    vec3 param_6 = (pc + (ex * 0.3826834261417388916015625)) + (ey * 0.92387950420379638671875);\n    vec3 param_7 = (pc - (ex * 0.3826834261417388916015625)) + (ey * 0.92387950420379638671875);\n    vec3 param_8 = _5093;\n    vec4 param_9 = m;\n    vec3 param_10 = _5069;\n    vec3 param_11 = _5093;\n    vec3 param_12 = (pc - (ex * 0.92387950420379638671875)) - (ey * 0.3826834261417388916015625);\n    vec3 param_13 = _5109;\n    vec4 param_14 = m;\n    vec3 param_15 = _5069;\n    vec3 param_16 = _5109;\n    vec3 param_17 = (pc + (ex * 0.3826834261417388916015625)) - (ey * 0.92387950420379638671875);\n    vec3 param_18 = (pc + (ex * 0.92387950420379638671875)) - (ey * 0.3826834261417388916015625);\n    return abs((fa_ltc_quad(param_4, param_5, param_6, param_7, param_8) + fa_ltc_quad(param_9, param_10, param_11, param_12, param_13)) + fa_ltc_quad(param_14, param_15, param_16, param_17, param_18));\n}\n\nvec2 fa_ltc_uv(float roughness, float ndv)\n{\n    return ((vec2(clamp((roughness - 0.0500000007450580596923828125) * 1.0526316165924072265625, 0.0, 1.0), sqrt(clamp(1.0 - ndv, 0.0, 1.0))) * 63.0) + vec2(0.5)) * vec2(0.015625);\n}\n\nvec3 fa_area_shade(int li, vec3 world_pos, vec3 n, vec3 v, vec3 diffuse_color, vec3 f0, float f90, float roughness, float ndv, float window)\n{\n    int param = li;\n    int _5167 = fa_light_base(param);\n    int param_1 = _5167;\n    int param_2 = _5167 + 1;\n    int param_3 = _5167 + 2;\n    int param_4 = _5167 + 4;\n    vec4 _5189 = fa_light_texel(param_4);\n    int param_5 = _5167 + 5;\n    vec4 _5194 = fa_light_texel(param_5);\n    int param_6 = _5167 + 6;\n    vec4 _5199 = fa_light_texel(param_6);\n    float _5200 = _5199.w;\n    vec3 _5205 = fa_light_texel(param_1).xyz - world_pos;\n    bool _5207 = _5200 < 1.5;\n    bool _5214;\n    if (_5207)\n    {\n        _5214 = dot(normalize(fa_light_texel(param_3).xyz), _5205) >= 0.0;\n    }\n    else\n    {\n        _5214 = _5207;\n    }\n    if (_5214)\n    {\n        return vec3(0.0);\n    }\n    bool _5223 = (_5200 > 0.5) && _5207;\n    float _5227 = _5223 ? 1.0539000034332275390625 : 1.0;\n    vec3 _5230 = _5189.xyz;\n    float _5232 = _5189.w;\n    vec3 _5238 = _5194.xyz;\n    float _5240 = _5194.w;\n    vec3 up = _5238 * (_5240 * _5227);\n    float _5246;\n    if (_5223)\n    {\n        _5246 = (3.1415927410125732421875 * _5232) * _5232;\n    }\n    else\n    {\n        _5246 = (4.0 * _5232) * _5240;\n    }\n    if (_5200 > 1.5)\n    {\n        vec3 _5272 = cross(_5230, -_5205);\n        vec3 perp = _5272;\n        float _5276 = dot(_5272, _5272);\n        vec3 _5279;\n        if (_5276 > 1.0000000133514319600180897396058e-10)\n        {\n            _5279 = perp * inversesqrt(_5276);\n        }\n        else\n        {\n            _5279 = _5238;\n        }\n        perp = _5279;\n        up = _5279 * _5240;\n    }\n    float _5300 = max(_5246, 9.9999999747524270787835121154785e-07);\n    vec3 param_7 = n;\n    vec3 param_8 = v;\n    vec3 _5310 = fa_ltc_tangent(param_7, param_8);\n    vec3 param_9 = _5310;\n    vec3 param_10 = n;\n    vec3 param_11 = _5205;\n    vec3 _5318 = fa_ltc_local(param_9, param_10, param_11);\n    vec3 param_12 = _5310;\n    vec3 param_13 = n;\n    vec3 param_14 = _5230 * (_5232 * _5227);\n    vec3 _5326 = fa_ltc_local(param_12, param_13, param_14);\n    vec3 param_15 = _5310;\n    vec3 param_16 = n;\n    vec3 param_17 = up;\n    vec3 _5334 = fa_ltc_local(param_15, param_16, param_17);\n    vec4 param_18 = vec4(1.0, 0.0, 0.0, 1.0);\n    float param_19 = _5200;\n    vec3 param_20 = _5318;\n    vec3 param_21 = _5326;\n    vec3 param_22 = _5334;\n    float param_23 = roughness;\n    float param_24 = ndv;\n    vec2 _5353 = fa_ltc_uv(param_23, param_24) * 64.0;\n    vec2 param_25 = _5353;\n    vec2 param_26 = _5353 + vec2(64.0, 0.0);\n    vec4 _5363 = fa_atlas_fetch(param_26);\n    vec4 param_27 = fa_atlas_fetch(param_25);\n    float param_28 = _5200;\n    vec3 param_29 = _5318;\n    vec3 param_30 = _5326;\n    vec3 param_31 = _5334;\n    return (((diffuse_color * fa_area_form(param_18, param_19, param_20, param_21, param_22)) + (((f0 * _5363.x) + ((vec3(f90) - f0) * _5363.y)) * fa_area_form(param_27, param_28, param_29, param_30, param_31))) * fa_light_texel(param_2).xyz) * ((((3.1415927410125732421875 * dot(_5205, _5205)) + _5300) / _5300) * window);\n}\n\nvec3 fa_light_rgb(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 1;\n    return fa_light_texel(param_1).xyz;\n}\n\nfloat fa_d_charlie(float alpha, float ndh)\n{\n    float _4200 = 1.0 / alpha;\n    return ((2.0 + _4200) * pow(sqrt(max(1.0 - (ndh * ndh), 9.9999997473787516355514526367188e-05)), _4200)) * 0.15915493667125701904296875;\n}\n\nfloat fa_v_ashikhmin(float ndl, float ndv)\n{\n    return clamp(0.25 / max((ndl + ndv) - (ndl * ndv), 9.9999997473787516355514526367188e-05), 0.0, 1.0);\n}\n\nfloat fa_layers_coat(FaLayers L, vec3 l, vec3 h, float vdh)\n{\n    float _4235 = max(dot(L.nc, l), 0.0);\n    float _4241 = max(dot(L.nc, h), 0.0);\n    float _4250 = ((_4241 * _4241) * (L.coat_a2 - 1.0)) + 1.0;\n    return (((L.coat * (0.039999999105930328369140625 + (0.959999978542327880859375 * pow(clamp(1.0 - vdh, 0.0, 1.0), 5.0)))) * (((L.coat_a2 / ((3.1415927410125732421875 * _4250) * _4250)) * (0.5 / max(mix((2.0 * _4235) * L.coat_ndv, _4235 + L.coat_ndv, L.coat_alpha), 9.9999997473787516355514526367188e-05))) * 3.1415927410125732421875)) * step(9.9999997473787516355514526367188e-05, _4235)) * _4235;\n}\n\nvec3 fa_area_layers(FaLayers L, int li, vec3 world_pos, vec3 n, vec3 v, vec3 l, vec3 diffuse_color, vec3 f0, float roughness, float ndv, float window)\n{\n    int param = li;\n    vec3 param_1 = world_pos;\n    vec3 param_2 = n;\n    vec3 param_3 = v;\n    vec3 param_4 = diffuse_color;\n    vec3 param_5 = f0;\n    float param_6 = L.f90;\n    float param_7 = roughness;\n    float param_8 = ndv;\n    float param_9 = window;\n    float _5431;\n    if (L.sheen_on)\n    {\n        _5431 = L.sheen_scale;\n    }\n    else\n    {\n        _5431 = 1.0;\n    }\n    vec3 result = fa_area_shade(param, param_1, param_2, param_3, param_4, param_5, param_6, param_7, param_8, param_9) * (L.keep * _5431);\n    vec3 _5444 = normalize(l + v);\n    int param_10 = li;\n    vec3 _5455 = fa_light_rgb(param_10) * window;\n    if (L.sheen_on)\n    {\n        float _5464 = max(dot(n, l), 0.0);\n        float param_11 = L.sheen_alpha;\n        float param_12 = max(dot(n, _5444), 0.0);\n        float param_13 = _5464;\n        float param_14 = ndv;\n        result += ((L.sheen * _5455) * (((((fa_d_charlie(param_11, param_12) * fa_v_ashikhmin(param_13, param_14)) * 3.1415927410125732421875) * step(9.9999997473787516355514526367188e-05, _5464)) * _5464) * L.keep));\n    }\n    if (L.coat > 0.0)\n    {\n        FaLayers param_15 = L;\n        vec3 param_16 = l;\n        vec3 param_17 = _5444;\n        float param_18 = max(dot(v, _5444), 0.0);\n        result += (_5455 * fa_layers_coat(param_15, param_16, param_17, param_18));\n    }\n    return result;\n}\n\nfloat fa_d_ggx_aniso(float ndh, float tdh, float bdh, float at, float ab)\n{\n    float _4103 = tdh / at;\n    float _4107 = bdh / ab;\n    float _4119 = ((_4103 * _4103) + (_4107 * _4107)) + (ndh * ndh);\n    return 1.0 / ((((3.1415927410125732421875 * at) * ab) * _4119) * _4119);\n}\n\nfloat fa_lambda_ggx_aniso(float n, float t, float b, float at, float ab)\n{\n    return 0.5 * (sqrt(1.0 + (((((at * at) * t) * t) + (((ab * ab) * b) * b)) / max(n * n, 9.9999999392252902907785028219223e-09))) - 1.0);\n}\n\nfloat fa_v_ggx_aniso(float ndl, float ndv, float tdv, float bdv, float tdl, float bdl, float at, float ab)\n{\n    float param = ndv;\n    float param_1 = tdv;\n    float param_2 = bdv;\n    float param_3 = at;\n    float param_4 = ab;\n    float param_5 = ndl;\n    float param_6 = tdl;\n    float param_7 = bdl;\n    float param_8 = at;\n    float param_9 = ab;\n    return clamp(1.0 / ((4.0 * max(ndl * ndv, 9.9999997473787516355514526367188e-05)) * ((1.0 + fa_lambda_ggx_aniso(param, param_1, param_2, param_3, param_4)) + fa_lambda_ggx_aniso(param_5, param_6, param_7, param_8, param_9))), 0.0, 1.0);\n}\n\nvec3 fa_layers_light(FaLayers L, vec3 diffuse_color, vec3 f0, vec3 n, vec3 v, vec3 l, vec3 h, float ndl, float ndv, float ndh, float vdh, float alpha, float a2)\n{\n    float _4299 = step(9.9999997473787516355514526367188e-05, ndl);\n    float d_ggx;\n    float vis;\n    if (L.aniso != 0.0)\n    {\n        float param = ndh;\n        float param_1 = dot(L.t, h);\n        float param_2 = dot(L.b, h);\n        float param_3 = L.at;\n        float param_4 = L.ab;\n        d_ggx = fa_d_ggx_aniso(param, param_1, param_2, param_3, param_4);\n        float param_5 = ndl;\n        float param_6 = ndv;\n        float param_7 = dot(L.t, v);\n        float param_8 = dot(L.b, v);\n        float param_9 = dot(L.t, l);\n        float param_10 = dot(L.b, l);\n        float param_11 = L.at;\n        float param_12 = L.ab;\n        vis = fa_v_ggx_aniso(param_5, param_6, param_7, param_8, param_9, param_10, param_11, param_12);\n    }\n    else\n    {\n        float _4378 = ((ndh * ndh) * (a2 - 1.0)) + 1.0;\n        d_ggx = a2 / ((3.1415927410125732421875 * _4378) * _4378);\n        vis = 0.5 / max(mix((2.0 * ndl) * ndv, ndl + ndv, alpha), 9.9999997473787516355514526367188e-05);\n    }\n    vec3 base = diffuse_color + (((f0 + ((vec3(L.f90) - f0) * pow(clamp(1.0 - vdh, 0.0, 1.0), 5.0))) * ((d_ggx * vis) * 3.1415927410125732421875)) * _4299);\n    if (L.sheen_on)\n    {\n        float param_13 = L.sheen_alpha;\n        float param_14 = ndh;\n        float param_15 = ndl;\n        float param_16 = ndv;\n        base = (base * L.sheen_scale) + (L.sheen * (((fa_d_charlie(param_13, param_14) * fa_v_ashikhmin(param_15, param_16)) * 3.1415927410125732421875) * _4299));\n    }\n    vec3 result = base * (L.keep * ndl);\n    if (L.coat > 0.0)\n    {\n        FaLayers param_17 = L;\n        vec3 param_18 = l;\n        vec3 param_19 = h;\n        float param_20 = vdh;\n        result += vec3(fa_layers_coat(param_17, param_18, param_19, param_20));\n    }\n    return result;\n}\n\nvec2 fa_env_brdf(float rough, float ndv)\n{\n    vec4 _3509 = (vec4(-1.0, -0.0274999998509883880615234375, -0.572000026702880859375, 0.02199999988079071044921875) * rough) + vec4(1.0, 0.0425000004470348358154296875, 1.03999996185302734375, -0.039999999105930328369140625);\n    float _3512 = _3509.x;\n    return (vec2(-1.03999996185302734375, 1.03999996185302734375) * ((min(_3512 * _3512, exp2((-9.27999973297119140625) * ndv)) * _3512) + _3509.y)) + _3509.zw;\n}\n\nvec3 fa_environment(vec3 d, float rough)\n{\n    if (fa_mesh_fs_params[11].w > 0.5)\n    {\n        return textureLod(fa_env_tex_fa_env_smp, d, clamp(rough, 0.0, 1.0) * fa_mesh_fs_params[12].w).xyz;\n    }\n    float _3363 = rough * rough;\n    float _3393 = 0.60000002384185791015625 * _3363;\n    return mix(mix(fa_mesh_fs_params[12].xyz * 0.550000011920928955078125, mix(fa_mesh_fs_params[12].xyz, fa_mesh_fs_params[11].xyz, vec3(pow(clamp(d.y * (1.0 - (0.699999988079071044921875 * _3363)), 0.0, 1.0), 0.550000011920928955078125))), vec3(smoothstep((-0.0500000007450580596923828125) - _3393, 0.0500000007450580596923828125 + _3393, d.y))), ((fa_mesh_fs_params[11].xyz + fa_mesh_fs_params[12].xyz) * 0.5) * 0.800000011920928955078125, vec3(_3363 * 0.60000002384185791015625));\n}\n\nvec3 fa_layers_ibl(FaLayers L, vec3 n, vec3 v, vec3 f0, float roughness)\n{\n    vec3 rn = n;\n    if (L.aniso != 0.0)\n    {\n        vec3 _3986;\n        if (L.aniso >= 0.0)\n        {\n            _3986 = L.b;\n        }\n        else\n        {\n            _3986 = L.t;\n        }\n        rn = normalize(mix(n, cross(cross(_3986, v), _3986), vec3(abs(L.aniso))));\n    }\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05);\n    vec2 _4019 = fa_env_brdf(param, param_1);\n    vec3 param_2 = reflect(-v, rn);\n    float param_3 = roughness;\n    vec3 result = (fa_environment(param_2, param_3) * ((f0 * _4019.x) + (vec3(L.f90) * _4019.y))) * L.base_scale;\n    if (L.sheen_on)\n    {\n        vec3 param_4 = n;\n        float param_5 = L.sheen_rough;\n        result += ((L.sheen * (L.sheen_e * L.keep)) * fa_environment(param_4, param_5));\n    }\n    if (L.coat > 0.0)\n    {\n        float param_6 = L.coat_rough;\n        float param_7 = L.coat_ndv;\n        vec2 _4074 = fa_env_brdf(param_6, param_7);\n        vec3 param_8 = reflect(-v, L.nc);\n        float param_9 = L.coat_rough;\n        result += (fa_environment(param_8, param_9) * (L.coat * ((0.039999999105930328369140625 * _4074.x) + _4074.y)));\n    }\n    return result;\n}\n\nvec3 fa_sky_reflection(vec3 n, vec3 v, vec3 f0, float roughness)\n{\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05);\n    vec2 _3551 = fa_env_brdf(param, param_1);\n    vec3 param_2 = reflect(-v, n);\n    float param_3 = roughness;\n    return fa_environment(param_2, param_3) * ((f0 * _3551.x) + vec3(_3551.y));\n}\n\nvec3 fa_shadow_debug(vec3 color, vec3 world)\n{\n    if (fa_shadows[27].w < 0.5)\n    {\n        return color;\n    }\n    int _3157 = int(fa_shadows[25].x + 0.5);\n    float _3167 = dot(world - fa_shadows[27].xyz, fa_shadows[28].xyz);\n    vec3 tint_1 = vec3(0.3499999940395355224609375);\n    bool _3172 = _3157 > 0;\n    bool _3181;\n    if (_3172)\n    {\n        int param = _3157 - 1;\n        _3181 = _3167 <= fa_shadow_split_at(param);\n    }\n    else\n    {\n        _3181 = _3172;\n    }\n    if (_3181)\n    {\n        tint_1 = vec3(1.0, 0.1500000059604644775390625, 0.100000001490116119384765625);\n        bool _3187 = _3157 > 1;\n        bool _3194;\n        if (_3187)\n        {\n            _3194 = _3167 > fa_shadows[24].x;\n        }\n        else\n        {\n            _3194 = _3187;\n        }\n        if (_3194)\n        {\n            tint_1 = vec3(0.100000001490116119384765625, 0.89999997615814208984375, 0.20000000298023223876953125);\n        }\n        bool _3200 = _3157 > 2;\n        bool _3207;\n        if (_3200)\n        {\n            _3207 = _3167 > fa_shadows[24].y;\n        }\n        else\n        {\n            _3207 = _3200;\n        }\n        if (_3207)\n        {\n            tint_1 = vec3(0.1500000059604644775390625, 0.300000011920928955078125, 1.0);\n        }\n        bool _3213 = _3157 > 3;\n        bool _3220;\n        if (_3213)\n        {\n            _3220 = _3167 > fa_shadows[24].z;\n        }\n        else\n        {\n            _3220 = _3213;\n        }\n        if (_3220)\n        {\n            tint_1 = vec3(1.0, 0.89999997615814208984375, 0.100000001490116119384765625);\n        }\n    }\n    return mix(color, tint_1, vec3(0.550000011920928955078125));\n}\n\nvoid main()\n{\n    fa_inst_load();\n    vec3 _6557 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _6557 = -_6557;\n    }\n    vec3 _5915 = normalize(fa_mesh_fs_params[0].xyz - fa_world_pos);\n    vec3 param = fa_world_pos;\n    fa_cluster_begin(param);\n    SurfaceInput param_1 = SurfaceInput(fa_world_pos, _6557, fa_world_tangent, fa_uv, fa_vertex_color, _5915, gl_FrontFacing);\n    Surface _5923 = fa_standard_surface(param_1);\n    vec3 _6588 = _5923.albedo;\n    float _6589 = _5923.alpha;\n    vec3 _6590 = _5923.normal;\n    float _6591 = _5923.metallic;\n    float _6592 = _5923.roughness;\n    float _6593 = _5923.occlusion;\n    vec3 _6594 = _5923.emission;\n    float _6595 = _5923.clearcoat;\n    float _6596 = _5923.clearcoat_roughness;\n    vec3 _6597 = _5923.sheen_color;\n    float _6598 = _5923.sheen_roughness;\n    float _6599 = _5923.anisotropy;\n    float _6600 = _5923.anisotropy_rotation;\n    float _6601 = _5923.specular;\n    float _6602 = _5923.ior;\n    vec3 _6603 = _5923.specular_color;\n    SurfaceInput param_2 = SurfaceInput(fa_world_pos, _6557, fa_world_tangent, fa_uv, fa_vertex_color, _5915, gl_FrontFacing);\n    Surface param_3 = _5923;\n    surface(param_2, param_3);\n    _6588 = param_3.albedo;\n    _6589 = param_3.alpha;\n    _6590 = param_3.normal;\n    _6591 = param_3.metallic;\n    _6592 = param_3.roughness;\n    _6593 = param_3.occlusion;\n    _6594 = param_3.emission;\n    _6595 = param_3.clearcoat;\n    _6596 = param_3.clearcoat_roughness;\n    _6597 = param_3.sheen_color;\n    _6598 = param_3.sheen_roughness;\n    _6599 = param_3.anisotropy;\n    _6600 = param_3.anisotropy_rotation;\n    _6601 = param_3.specular;\n    _6602 = param_3.ior;\n    _6603 = param_3.specular_color;\n    vec3 param_4 = fa_world_pos;\n    vec3 param_5 = _6557;\n    vec3 param_6 = param_3.albedo;\n    vec3 param_7 = param_3.normal;\n    fa_apply_decals(param_4, param_5, param_6, param_7);\n    _6588 = param_6;\n    _6590 = param_7;\n    vec3 result;\n    if (fa_mesh_fs_params[3].w > 0.5)\n    {\n        result = _6588;\n    }\n    else\n    {\n        vec3 _5962 = normalize(_6590);\n        float _5969 = clamp(_6591, 0.0, 1.0);\n        float _5973 = clamp(_6592, 0.0500000007450580596923828125, 1.0);\n        float _5977 = _5973 * _5973;\n        float _5981 = _5977 * _5977;\n        float _5986 = max(dot(_5962, _5915), 9.9999997473787516355514526367188e-05);\n        vec3 _5992 = _6588 * (1.0 - _5969);\n        vec3 _5999 = mix(vec3(0.039999999105930328369140625), _6588, vec3(_5969));\n        vec3 f0 = _5999;\n        SurfaceInput param_8 = SurfaceInput(fa_world_pos, _6557, fa_world_tangent, fa_uv, fa_vertex_color, _5915, gl_FrontFacing);\n        Surface param_9 = Surface(_6588, _6589, _6590, _6591, _6592, _6593, _6594, _6595, _6596, _6597, _6598, _6599, _6600, _6601, _6602, _6603);\n        vec3 param_10 = _5962;\n        vec3 param_11 = _5915;\n        float param_12 = _5969;\n        float param_13 = _5973;\n        vec3 param_14 = _5999;\n        FaLayers _6015 = fa_layers_setup(param_8, param_9, param_10, param_11, param_12, param_13, param_14);\n        f0 = param_14;\n        vec3 param_15 = _5962;\n        vec3 lit = (fa_indirect_diffuse(param_15) * _5992) * _6593;\n        if (_6015.on)\n        {\n            lit *= _6015.base_scale;\n        }\n        int _6037 = fa_cl_ndir + fa_cl_local;\n        for (int ln = 0; ln < _6037; ln++)\n        {\n            int param_16 = ln;\n            int _6050 = fa_cl_light(param_16);\n            bool _6053 = fa_lm.z > 0.5;\n            bool _6059;\n            if (_6053)\n            {\n                int param_17 = _6050;\n                _6059 = fa_light_baked(param_17);\n            }\n            else\n            {\n                _6059 = _6053;\n            }\n            if (_6059)\n            {\n                continue;\n            }\n            int param_18 = _6050;\n            vec3 param_19 = fa_world_pos;\n            vec3 param_20 = _6557;\n            LightSample _6071 = fa_light_shadowed(param_18, param_19, param_20);\n            float _6079 = max(dot(_5962, _6071.direction), 0.0);\n            float _6085 = _6071.attenuation * _6071.shadow;\n            vec3 _6090 = normalize(_6071.direction + _5915);\n            float _6095 = max(dot(_5962, _6090), 0.0);\n            float _6100 = max(dot(_5915, _6090), 0.0);\n            bool _6107;\n            if (fa_light_is_area)\n            {\n                _6107 = !_6015.on;\n            }\n            else\n            {\n                _6107 = fa_light_is_area;\n            }\n            if (_6107)\n            {\n                int param_21 = _6050;\n                vec3 param_22 = fa_world_pos;\n                vec3 param_23 = _5962;\n                vec3 param_24 = _5915;\n                vec3 param_25 = _5992;\n                vec3 param_26 = f0;\n                float param_27 = 1.0;\n                float param_28 = _5973;\n                float param_29 = _5986;\n                float param_30 = _6085;\n                lit += fa_area_shade(param_21, param_22, param_23, param_24, param_25, param_26, param_27, param_28, param_29, param_30);\n            }\n            else\n            {\n                if (fa_light_is_area)\n                {\n                    FaLayers param_31 = _6015;\n                    int param_32 = _6050;\n                    vec3 param_33 = fa_world_pos;\n                    vec3 param_34 = _5962;\n                    vec3 param_35 = _5915;\n                    vec3 param_36 = _6071.direction;\n                    vec3 param_37 = _5992;\n                    vec3 param_38 = f0;\n                    float param_39 = _5973;\n                    float param_40 = _5986;\n                    float param_41 = _6085;\n                    lit += fa_area_layers(param_31, param_32, param_33, param_34, param_35, param_36, param_37, param_38, param_39, param_40, param_41);\n                }\n                else\n                {\n                    if (_6015.on)\n                    {\n                        FaLayers param_42 = _6015;\n                        vec3 param_43 = _5992;\n                        vec3 param_44 = f0;\n                        vec3 param_45 = _5962;\n                        vec3 param_46 = _5915;\n                        vec3 param_47 = _6071.direction;\n                        vec3 param_48 = _6090;\n                        float param_49 = _6079;\n                        float param_50 = _5986;\n                        float param_51 = _6095;\n                        float param_52 = _6100;\n                        float param_53 = _5977;\n                        float param_54 = _5981;\n                        int param_55 = _6050;\n                        lit += (fa_layers_light(param_42, param_43, param_44, param_45, param_46, param_47, param_48, param_49, param_50, param_51, param_52, param_53, param_54) * ((fa_light_rgb(param_55) * fa_light_tint) * _6085));\n                    }\n                    else\n                    {\n                        float _6213 = ((_6095 * _6095) * (_5981 - 1.0)) + 1.0;\n                        int param_56 = _6050;\n                        lit += (((_5992 + (((f0 + ((vec3(1.0) - f0) * pow(1.0 - _6100, 5.0))) * (((_5981 / ((3.1415927410125732421875 * _6213) * _6213)) * (0.5 / max(mix((2.0 * _6079) * _5986, _6079 + _5986, _5977), 9.9999997473787516355514526367188e-05))) * 3.1415927410125732421875)) * step(9.9999997473787516355514526367188e-05, _6079))) * (fa_light_rgb(param_56) * fa_light_tint)) * (_6079 * _6085));\n                    }\n                }\n            }\n        }\n        if (_6015.on)\n        {\n            FaLayers param_57 = _6015;\n            vec3 param_58 = _5962;\n            vec3 param_59 = _5915;\n            vec3 param_60 = f0;\n            float param_61 = _5973;\n            lit += (fa_layers_ibl(param_57, param_58, param_59, param_60, param_61) * _6593);\n        }\n        else\n        {\n            vec3 param_62 = _5962;\n            vec3 param_63 = _5915;\n            vec3 param_64 = f0;\n            float param_65 = _5973;\n            lit += (fa_sky_reflection(param_62, param_63, param_64, param_65) * _6593);\n        }\n        result = lit;\n    }\n    vec3 _6308 = result;\n    vec3 _6309 = _6308 + _6594;\n    result = _6309;\n    vec3 param_66 = _6309;\n    vec3 param_67 = fa_world_pos;\n    result = fa_shadow_debug(param_66, param_67);\n    bool _6318 = fa_mesh_fs_params[7].w > 0.0;\n    bool _6325;\n    if (!_6318)\n    {\n        _6325 = fa_mesh_fs_params[8].y > 0.0;\n    }\n    else\n    {\n        _6325 = _6318;\n    }\n    if (_6325)\n    {\n        vec3 _6334 = fa_world_pos - fa_mesh_fs_params[0].xyz;\n        float _6340 = dot(_6334, fa_mesh_fs_params[9].xyz);\n        bool _6344 = fa_mesh_fs_params[9].w > 0.5;\n        float _6345;\n        if (_6344)\n        {\n            _6345 = _6340;\n        }\n        else\n        {\n            _6345 = length(_6334);\n        }\n        float _6357 = _6345 - fa_mesh_fs_params[8].x;\n        if (_6357 > 0.0)\n        {\n            float _6366 = fa_mesh_fs_params[7].w * _6357;\n            float tau = _6366 * _6366;\n            if (fa_mesh_fs_params[8].y > 0.0)\n            {\n                float _6382;\n                if (_6344)\n                {\n                    _6382 = fa_world_pos.y - (fa_mesh_fs_params[9].y * _6340);\n                }\n                else\n                {\n                    _6382 = fa_mesh_fs_params[0].y;\n                }\n                float _6403 = mix(_6382, fa_world_pos.y, clamp(fa_mesh_fs_params[8].x / _6345, 0.0, 1.0));\n                float _6407 = fa_world_pos.y - _6403;\n                float _6412 = _6403 - fa_mesh_fs_params[8].z;\n                float _6417 = fa_world_pos.y - fa_mesh_fs_params[8].z;\n                bool _6420 = _6412 <= 0.0;\n                bool _6421 = !_6420;\n                bool _6427;\n                if (_6421)\n                {\n                    _6427 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _6427 = _6420;\n                }\n                float _6428;\n                if (_6427)\n                {\n                    _6428 = fa_mesh_fs_params[8].y;\n                }\n                else\n                {\n                    _6428 = fa_mesh_fs_params[8].y * exp(-min(fa_mesh_fs_params[8].w * _6412, 80.0));\n                }\n                bool _6455;\n                if (_6421)\n                {\n                    _6455 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _6455 = _6420;\n                }\n                float _6456;\n                if (_6455)\n                {\n                    _6456 = fa_mesh_fs_params[8].y * _6412;\n                }\n                else\n                {\n                    _6456 = (fa_mesh_fs_params[8].y * (1.0 - exp(-min(fa_mesh_fs_params[8].w * _6412, 80.0)))) / fa_mesh_fs_params[8].w;\n                }\n                bool _6481 = _6417 <= 0.0;\n                bool _6488;\n                if (!_6481)\n                {\n                    _6488 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _6488 = _6481;\n                }\n                float _6489;\n                if (_6488)\n                {\n                    _6489 = fa_mesh_fs_params[8].y * _6417;\n                }\n                else\n                {\n                    _6489 = (fa_mesh_fs_params[8].y * (1.0 - exp(-min(fa_mesh_fs_params[8].w * _6417, 80.0)))) / fa_mesh_fs_params[8].w;\n                }\n                float _6516;\n                if (abs(_6407) < 0.001000000047497451305389404296875)\n                {\n                    _6516 = _6428;\n                }\n                else\n                {\n                    _6516 = (_6489 - _6456) / _6407;\n                }\n                tau += (_6357 * max(_6516, 0.0));\n            }\n            result = mix(result, fa_mesh_fs_params[7].xyz, vec3(clamp(1.0 - exp(-clamp(tau, 0.0, 80.0)), 0.0, 1.0)));\n        }\n    }\n    fa_frag_color = vec4(result, _6589);\n}\n\n",
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
            "inst_name": "_554",
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
            "inst_name": "_2221",
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
            "inst_name": "_5533",
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
      "vs": "#version 430\n\nstruct VertexData\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 color;\n    vec3 object_pos;\n};\n\nuniform vec4 fa_mesh_vs_params[11];\nuniform vec4 fa_skin[192];\nlayout(location = 2) out vec3 fa_world_pos;\nlayout(location = 3) out vec3 fa_world_normal;\nlayout(location = 4) out vec4 fa_world_tangent;\nlayout(location = 5) out vec2 fa_uv;\nlayout(location = 6) out vec4 fa_vertex_color;\nlayout(location = 11) in vec4 fa_inst_d0;\nlayout(location = 12) in vec4 fa_inst_d1;\nlayout(location = 0) flat out vec4 fa_inst_v0;\nlayout(location = 1) flat out vec4 fa_inst_v1;\nlayout(location = 5) in vec4 fa_inst_m0;\nlayout(location = 6) in vec4 fa_inst_m1;\nlayout(location = 7) in vec4 fa_inst_m2;\nlayout(location = 8) in vec4 fa_inst_m3;\nlayout(location = 9) in vec4 fa_joints;\nlayout(location = 10) in vec4 fa_weights;\nlayout(location = 0) in vec3 fa_position;\nlayout(location = 1) in vec3 fa_normal;\nlayout(location = 3) in vec4 fa_tangent;\nlayout(location = 2) in vec2 fa_texcoord0;\nlayout(location = 4) in vec4 fa_color;\nlayout(location = 7) out vec3 fa_lm;\nfloat raise;\nvec4 tint;\n\nvoid fa_instance_unpack(vec4 fa_d0, vec4 fa_d1, vec4 fa_d2)\n{\n    raise = fa_d0.x;\n    tint = fa_d1;\n}\n\nvoid fa_inst_begin()\n{\n    vec4 param = fa_inst_d0;\n    vec4 param_1 = fa_inst_d1;\n    vec4 param_2 = vec4(0.0);\n    fa_instance_unpack(param, param_1, param_2);\n    fa_inst_v0 = fa_inst_d0;\n    fa_inst_v1 = fa_inst_d1;\n}\n\nmat4 fa_skin_matrix(vec4 joints, vec4 weights)\n{\n    vec4 r0 = vec4(0.0);\n    vec4 r1 = vec4(0.0);\n    vec4 r2 = vec4(0.0);\n    for (int i = 0; i < 4; i++)\n    {\n        int _196 = int((joints[i] * 255.0) + 0.5) * 3;\n        r0 += (fa_skin[_196 * 1 + 0] * weights[i]);\n        r1 += (fa_skin[(_196 + 1) * 1 + 0] * weights[i]);\n        r2 += (fa_skin[(_196 + 2) * 1 + 0] * weights[i]);\n    }\n    return mat4(vec4(r0.x, r1.x, r2.x, 0.0), vec4(r0.y, r1.y, r2.y, 0.0), vec4(r0.z, r1.z, r2.z, 0.0), vec4(r0.w, r1.w, r2.w, 1.0));\n}\n\nVertexData fa_vertex_data(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    vec3 _99 = cross(model[1].xyz, model[2].xyz);\n    float _105 = (dot(model[0].xyz, _99) < 0.0) ? (-1.0) : 1.0;\n    return VertexData((model * vec4(position, 1.0)).xyz, (((_99 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _105, vec4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _105), texcoord0 * fa_mesh_vs_params[8].xy, color, position);\n}\n\nvoid vertex(inout VertexData v)\n{\n    v.world_pos.y += raise;\n}\n\nvoid fa_shade_vertex(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    mat4 param = model;\n    vec3 param_1 = position;\n    vec3 param_2 = normal;\n    vec4 param_3 = tangent;\n    vec2 param_4 = texcoord0;\n    vec4 param_5 = color;\n    VertexData param_6 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    vertex(param_6);\n    fa_world_pos = param_6.world_pos;\n    fa_world_normal = param_6.world_normal;\n    fa_world_tangent = param_6.world_tangent;\n    fa_uv = param_6.uv;\n    fa_vertex_color = param_6.color;\n    gl_Position = mat4(fa_mesh_vs_params[0], fa_mesh_vs_params[1], fa_mesh_vs_params[2], fa_mesh_vs_params[3]) * vec4(param_6.world_pos, 1.0);\n}\n\nvoid main()\n{\n    fa_inst_begin();\n    vec4 param = fa_joints;\n    vec4 param_1 = fa_weights;\n    mat4 param_2 = mat4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3) * fa_skin_matrix(param, param_1);\n    vec3 param_3 = fa_position;\n    vec3 param_4 = fa_normal;\n    vec4 param_5 = fa_tangent;\n    vec2 param_6 = fa_texcoord0;\n    vec4 param_7 = fa_color;\n    fa_shade_vertex(param_2, param_3, param_4, param_5, param_6, param_7);\n    fa_lm = vec3(0.0);\n}\n\n",
      "fs": "#version 430\n\nstruct SurfaceInput\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 vertex_color;\n    vec3 view_dir;\n    bool front_facing;\n};\n\nstruct LightSample\n{\n    vec3 direction;\n    vec3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct Surface\n{\n    vec3 albedo;\n    float alpha;\n    vec3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    vec3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    vec3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    vec3 specular_color;\n};\n\nstruct FaLayers\n{\n    bool on;\n    float f90;\n    float keep;\n    float base_scale;\n    float coat;\n    float coat_rough;\n    float coat_alpha;\n    float coat_a2;\n    vec3 nc;\n    float coat_ndv;\n    bool sheen_on;\n    vec3 sheen;\n    float sheen_rough;\n    float sheen_alpha;\n    float sheen_scale;\n    float sheen_e;\n    float aniso;\n    vec3 t;\n    vec3 b;\n    float at;\n    float ab;\n};\n\nconst float _3651[63] = float[](1.0, 1.0, 1.0, 0.4790000021457672119140625, 0.11699999868869781494140625, 0.01200000010430812835693359375, 0.0, 0.0, 0.0, 1.0, 1.0, 1.0, 0.578000009059906005859375, 0.19300000369548797607421875, 0.0350000001490116119384765625, 0.0030000000260770320892333984375, 0.0, 0.0, 1.0, 1.0, 1.0, 0.6740000247955322265625, 0.3459999859333038330078125, 0.1319999992847442626953125, 0.032999999821186065673828125, 0.0040000001899898052215576171875, 0.0, 0.971000015735626220703125, 0.954999983310699462890625, 0.828999996185302734375, 0.63999998569488525390625, 0.42599999904632568359375, 0.24500000476837158203125, 0.115000002086162567138671875, 0.037000000476837158203125, 0.0030000000260770320892333984375, 0.7469999790191650390625, 0.737999975681304931640625, 0.670000016689300537109375, 0.563000023365020751953125, 0.4309999942779541015625, 0.3039999902248382568359375, 0.1940000057220458984375, 0.1019999980926513671875, 0.0309999994933605194091796875, 0.614000022411346435546875, 0.609000027179718017578125, 0.566999971866607666015625, 0.499000012874603271484375, 0.412000000476837158203125, 0.32400000095367431640625, 0.240999996662139892578125, 0.162000000476837158203125, 0.087999999523162841796875, 0.538999974727630615234375, 0.535000026226043701171875, 0.505999982357025146484375, 0.4569999873638153076171875, 0.393999993801116943359375, 0.328999996185302734375, 0.2660000026226043701171875, 0.203999996185302734375, 0.14200000464916229248046875);\n\nuniform vec4 fa_mesh_fs_params[24];\nuniform vec4 fa_shadows[30];\nuniform vec4 fa_material[1];\nlayout(binding = 0) uniform sampler2D fa_light_tex_fa_shadow_smp;\nlayout(binding = 1) uniform sampler2D fa_tex_fa_smp;\nlayout(binding = 2) uniform sampler2D fa_normal_tex_fa_smp;\nlayout(binding = 3) uniform sampler2D fa_mr_tex_fa_smp;\nlayout(binding = 4) uniform sampler2D fa_occlusion_tex_fa_smp;\nlayout(binding = 5) uniform sampler2D fa_emissive_tex_fa_smp;\nlayout(binding = 6) uniform sampler2D fa_decal_tex_fa_env_smp;\nlayout(binding = 7) uniform sampler2D fa_lightmap_fa_env_smp;\nlayout(binding = 8) uniform samplerCube fa_env_tex_fa_env_smp;\nlayout(binding = 9) uniform sampler2D fa_light_atlas_fa_env_smp;\nlayout(binding = 10) uniform sampler2D fa_shadow_tex_fa_shadow_smp;\n\nlayout(location = 2) in vec3 fa_world_pos;\nlayout(location = 7) in vec3 fa_lm;\nlayout(location = 0) flat in vec4 fa_inst_v0;\nlayout(location = 1) flat in vec4 fa_inst_v1;\nlayout(location = 3) in vec3 fa_world_normal;\nlayout(location = 4) in vec4 fa_world_tangent;\nlayout(location = 5) in vec2 fa_uv;\nlayout(location = 6) in vec4 fa_vertex_color;\nlayout(location = 0) out vec4 fa_frag_color;\nvec3 fa_light_tint;\nbool fa_light_is_area;\nint fa_cl_ndir;\nint fa_cl_slot;\nint fa_cl_local;\nfloat raise;\nvec4 tint;\n\nvoid fa_instance_unpack(vec4 fa_d0, vec4 fa_d1, vec4 fa_d2)\n{\n    raise = fa_d0.x;\n    tint = fa_d1;\n}\n\nvoid fa_inst_load()\n{\n    vec4 param = fa_inst_v0;\n    vec4 param_1 = fa_inst_v1;\n    vec4 param_2 = vec4(0.0);\n    fa_instance_unpack(param, param_1, param_2);\n}\n\nvec4 fa_light_texel(int t)\n{\n    return texelFetch(fa_light_tex_fa_shadow_smp, ivec2(t & 1023, t >> 10), 0);\n}\n\nvec4 fa_cluster_texel(vec3 world_pos)\n{\n    bool _1492 = fa_mesh_fs_params[19].x < 0.0;\n    bool _1499;\n    if (!_1492)\n    {\n        _1499 = fa_mesh_fs_params[19].w < 1.0;\n    }\n    else\n    {\n        _1499 = _1492;\n    }\n    bool _1507;\n    if (!_1499)\n    {\n        _1507 = fa_mesh_fs_params[18].x < 1.0;\n    }\n    else\n    {\n        _1507 = _1499;\n    }\n    bool _1514;\n    if (!_1507)\n    {\n        _1514 = fa_mesh_fs_params[18].y < 1.0;\n    }\n    else\n    {\n        _1514 = _1507;\n    }\n    bool _1521;\n    if (!_1514)\n    {\n        _1521 = fa_mesh_fs_params[19].y < 1.0;\n    }\n    else\n    {\n        _1521 = _1514;\n    }\n    if (_1521)\n    {\n        return vec4(0.0);\n    }\n    vec4 _1531 = vec4(world_pos, 1.0);\n    float _1537 = dot(fa_mesh_fs_params[16], _1531);\n    if (!(_1537 > 9.9999999747524270787835121154785e-07))\n    {\n        return vec4(0.0);\n    }\n    vec2 _1559 = vec2(dot(fa_mesh_fs_params[14], _1531), dot(fa_mesh_fs_params[15], _1531)) / vec2(_1537);\n    int _1563 = int(fa_mesh_fs_params[18].x);\n    int _1567 = int(fa_mesh_fs_params[18].y);\n    int param = (int(fa_mesh_fs_params[19].x) + (((clamp(int(floor(log2(max(dot(fa_mesh_fs_params[17].xyz, world_pos) + fa_mesh_fs_params[17].w, fa_mesh_fs_params[18].w) / fa_mesh_fs_params[18].w) * fa_mesh_fs_params[18].z)), 0, int(fa_mesh_fs_params[19].y) - 1) * _1567) + clamp(int(floor(((_1559.y * 0.5) + 0.5) * fa_mesh_fs_params[18].y)), 0, _1567 - 1)) * _1563)) + clamp(int(floor(((_1559.x * 0.5) + 0.5) * fa_mesh_fs_params[18].x)), 0, _1563 - 1);\n    return fa_light_texel(param);\n}\n\nivec2 fa_cluster_lookup(vec3 world_pos)\n{\n    vec3 param = world_pos;\n    vec4 _1643 = fa_cluster_texel(param);\n    return ivec2(int(_1643.x), int(_1643.y));\n}\n\nvoid fa_cluster_begin(vec3 world_pos)\n{\n    fa_cl_ndir = int(fa_mesh_fs_params[19].z);\n    vec3 param = world_pos;\n    ivec2 _4470 = fa_cluster_lookup(param);\n    fa_cl_slot = _4470.x;\n    fa_cl_local = _4470.y;\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nvec3 fa_linear_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_tex_fix(inout vec3 c, float mode)\n{\n    if (mode > 1.5)\n    {\n        vec3 param = c;\n        vec3 _5585 = fa_linear_to_srgb(param);\n        c = _5585;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            vec3 param_1 = c;\n            vec3 _5593 = fa_srgb_to_linear(param_1);\n            c = _5593;\n        }\n    }\n    return c;\n}\n\nvec3 fa_tangent_normal(SurfaceInput i, vec3 m)\n{\n    vec3 _437;\n    if (i.front_facing)\n    {\n        _437 = i.world_normal;\n    }\n    else\n    {\n        _437 = -i.world_normal;\n    }\n    vec3 _461 = normalize(i.world_tangent.xyz - (_437 * dot(_437, i.world_tangent.xyz)));\n    vec3 _488 = normalize(((_461 * m.x) + ((cross(_437, _461) * i.world_tangent.w) * m.y)) + (_437 * m.z));\n    vec3 _491;\n    if (i.front_facing)\n    {\n        _491 = _488;\n    }\n    else\n    {\n        _491 = -_488;\n    }\n    return _491;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    vec4 base_t = texture(fa_tex_fa_smp, i.uv);\n    float param = fa_mesh_fs_params[6].w;\n    float param_1 = 1.0;\n    vec3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    vec3 _5624 = fa_tex_fix(param_2, param_3);\n    vec4 _7039 = base_t;\n    _7039.x = _5624.x;\n    _7039.y = _5624.y;\n    _7039.z = _5624.z;\n    base_t = _7039;\n    vec4 _5638 = (_7039 * fa_mesh_fs_params[2]) * i.vertex_color;\n    vec3 _6877 = i.world_normal;\n    if (fa_mesh_fs_params[6].z > 0.5)\n    {\n        float param_4 = fa_mesh_fs_params[6].w;\n        float param_5 = 16.0;\n        vec3 param_6 = texture(fa_normal_tex_fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        vec3 _5670 = fa_tex_fix(param_6, param_7);\n        vec3 _5673 = (_5670 * 2.0) - vec3(1.0);\n        vec2 _5678 = _5673.xy * fa_mesh_fs_params[6].x;\n        vec3 _7047 = _5673;\n        _7047.x = _5678.x;\n        _7047.y = _5678.y;\n        SurfaceInput param_8 = i;\n        vec3 param_9 = _7047;\n        _6877 = fa_tangent_normal(param_8, param_9);\n    }\n    vec4 mrt = texture(fa_mr_tex_fa_smp, i.uv);\n    float param_10 = fa_mesh_fs_params[6].w;\n    float param_11 = 64.0;\n    vec3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    vec3 _5706 = fa_tex_fix(param_12, param_13);\n    vec4 _7050 = mrt;\n    _7050.x = _5706.x;\n    _7050.y = _5706.y;\n    _7050.z = _5706.z;\n    mrt = _7050;\n    vec4 _5734 = texture(fa_occlusion_tex_fa_smp, i.uv);\n    float param_14 = fa_mesh_fs_params[6].w;\n    float param_15 = 256.0;\n    vec3 param_16 = _5734.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    vec3 _5745 = fa_tex_fix(param_16, param_17);\n    float param_18 = fa_mesh_fs_params[6].w;\n    float param_19 = 4.0;\n    vec3 param_20 = texture(fa_emissive_tex_fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    vec3 _5775 = fa_tex_fix(param_20, param_21);\n    float _6882 = fa_mesh_fs_params[20].x;\n    float _6883 = fa_mesh_fs_params[20].y;\n    float _6886 = fa_mesh_fs_params[20].z;\n    float _6885 = fa_mesh_fs_params[21].w;\n    float _6888 = fa_mesh_fs_params[22].x;\n    if (fa_mesh_fs_params[22].z > 0.5)\n    {\n        if (mod(fa_mesh_fs_params[22].z, 2.0) > 0.5)\n        {\n            _6882 *= _5745.y;\n            _6883 *= _5745.z;\n            _6885 *= _5734.w;\n        }\n        if (fa_mesh_fs_params[22].z > 1.5)\n        {\n            _6886 *= mrt.x;\n            _6888 *= mrt.w;\n        }\n    }\n    return Surface(_5638.xyz, _5638.w, _6877, clamp(fa_mesh_fs_params[5].x * _5706.z, 0.0, 1.0), clamp(fa_mesh_fs_params[5].y * _5706.y, 0.0500000007450580596923828125, 1.0), 1.0 + (fa_mesh_fs_params[6].y * (_5745.x - 1.0)), fa_mesh_fs_params[3].xyz + (fa_mesh_fs_params[4].xyz * _5775), _6882, _6883, fa_mesh_fs_params[21].xyz, _6885, _6886, fa_mesh_fs_params[20].w, _6888, fa_mesh_fs_params[22].y, fa_mesh_fs_params[23].xyz);\n}\n\nvoid surface(SurfaceInput i, inout Surface s)\n{\n    s.emission += ((tint.xyz * tint.w) * fa_material[0].x);\n}\n\nvec4 fa_decal_tile(vec4 rect, vec2 uv, vec2 atlas, vec2 ddx, vec2 ddy)\n{\n    vec2 _1723 = rect.zw - rect.xy;\n    vec2 _1727 = _1723 * atlas;\n    vec2 _1731 = ddx * _1727;\n    vec2 _1735 = ddy * _1727;\n    return textureLod(fa_decal_tex_fa_env_smp, rect.xy + (clamp(uv, vec2(0.0), vec2(1.0)) * _1723), clamp(0.5 * log2(max(max(dot(_1731, _1731), dot(_1735, _1735)), 9.9999999392252902907785028219223e-09)), 0.0, 4.0));\n}\n\nvec3 fa_dc_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_dc_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvoid fa_apply_decals(vec3 world_pos, vec3 geo_normal, inout vec3 albedo, inout vec3 normal)\n{\n    bool _1768 = fa_mesh_fs_params[10].y < 0.5;\n    bool _1775;\n    if (!_1768)\n    {\n        _1775 = fa_mesh_fs_params[10].w < 0.5;\n    }\n    else\n    {\n        _1775 = _1768;\n    }\n    if (_1775)\n    {\n        return;\n    }\n    vec3 _1781 = dFdx(world_pos);\n    vec3 _1784 = dFdy(world_pos);\n    vec3 param = world_pos;\n    vec4 _1788 = fa_cluster_texel(param);\n    int _1792 = int(_1788.w);\n    if (_1792 < 1)\n    {\n        return;\n    }\n    int _1802 = int(fa_mesh_fs_params[10].y + 0.5);\n    int param_1 = _1802;\n    vec4 _1806 = fa_light_texel(param_1);\n    vec2 _1809 = _1806.yz;\n    int _1813 = int(_1806.w);\n    int param_2 = _1802 + 1;\n    vec4 _1818 = fa_light_texel(param_2);\n    float _1819 = _1818.x;\n    int _1825 = int(fa_mesh_fs_params[10].w + 0.5) - 1;\n    int _1829 = int(_1788.z);\n    vec3 _2094;\n    for (int k = 0; k < _1792; k++)\n    {\n        int _1842 = _1829 + k;\n        int param_3 = _1813 + (_1842 >> 2);\n        int _1859 = (_1802 + 2) + (int(fa_light_texel(param_3)[_1842 & 3]) * 7);\n        int param_4 = _1859 + 6;\n        vec4 _1864 = fa_light_texel(param_4);\n        if (((int(_1864.w + 0.5) >> _1825) & 1) == 0)\n        {\n            continue;\n        }\n        int param_5 = _1859;\n        vec4 _1879 = fa_light_texel(param_5);\n        int param_6 = _1859 + 1;\n        vec4 _1884 = fa_light_texel(param_6);\n        int param_7 = _1859 + 2;\n        vec4 _1889 = fa_light_texel(param_7);\n        vec3 _1892 = _1879.xyz;\n        float _1897 = dot(_1892, world_pos) + _1879.w;\n        vec3 _1899 = _1884.xyz;\n        float _1904 = dot(_1899, world_pos) + _1884.w;\n        vec3 _1906 = _1889.xyz;\n        float _1911 = dot(_1906, world_pos) + _1889.w;\n        bool _1916 = abs(_1897) > 0.5;\n        bool _1924;\n        if (!_1916)\n        {\n            _1924 = abs(_1904) > 0.5;\n        }\n        else\n        {\n            _1924 = _1916;\n        }\n        bool _1932;\n        if (!_1924)\n        {\n            _1932 = abs(_1911) > 0.5;\n        }\n        else\n        {\n            _1932 = _1924;\n        }\n        if (_1932)\n        {\n            continue;\n        }\n        float _1947 = clamp(dot(geo_normal, normalize(_1906)) * _1864.z, 0.0, 1.0);\n        if (_1947 <= 0.0)\n        {\n            continue;\n        }\n        float _1967 = (clamp((0.5 - abs(_1911)) * 10.0, 0.0, 1.0) * _1947) * _1864.x;\n        vec2 _1975 = vec2(_1897 + 0.5, 0.5 - _1904);\n        vec2 _1985 = vec2(dot(_1892, _1781), dot(_1899, _1781));\n        vec2 _1995 = vec2(dot(_1892, _1784), dot(_1899, _1784));\n        int param_8 = _1859 + 5;\n        vec4 _2000 = fa_light_texel(param_8);\n        int param_9 = _1859 + 3;\n        vec4 _2005 = fa_light_texel(param_9);\n        int param_10 = _1859 + 4;\n        vec4 _2010 = fa_light_texel(param_10);\n        float tex_a = 1.0;\n        vec3 col = _2000.xyz;\n        bool _2020 = _2005.z > _2005.x;\n        if (_2020)\n        {\n            vec4 param_11 = _2005;\n            vec2 param_12 = _1975;\n            vec2 param_13 = _1809;\n            vec2 param_14 = _1985;\n            vec2 param_15 = _1995;\n            vec4 tx = fa_decal_tile(param_11, param_12, param_13, param_14, param_15);\n            if ((_1819 > 0.5) && (_1819 < 1.5))\n            {\n                vec3 param_16 = tx.xyz;\n                vec3 _2046 = fa_dc_to_linear(param_16);\n                vec4 _6957 = tx;\n                _6957.x = _2046.x;\n                _6957.y = _2046.y;\n                _6957.z = _2046.z;\n                tx = _6957;\n            }\n            col *= tx.xyz;\n            tex_a = tx.w;\n        }\n        albedo = mix(albedo, col, vec3(clamp((_1967 * tex_a) * _2000.w, 0.0, 1.0)));\n        if (_2010.z > _2010.x)\n        {\n            vec4 param_17 = _2010;\n            vec2 param_18 = _1975;\n            vec2 param_19 = _1809;\n            vec2 param_20 = _1985;\n            vec2 param_21 = _1995;\n            vec4 _2090 = fa_decal_tile(param_17, param_18, param_19, param_20, param_21);\n            if (_1819 > 1.5)\n            {\n                vec3 param_22 = _2090.xyz;\n                vec3 _2100 = fa_dc_to_srgb(param_22);\n                _2094 = _2100;\n            }\n            else\n            {\n                _2094 = _2090.xyz;\n            }\n            vec3 _2109 = (_2094 * 2.0) - vec3(1.0);\n            vec2 _2114 = _2109.xy * _1864.y;\n            vec3 _2136 = (normalize(_1892) * _2114.x) + (normalize(_1899) * _2114.y);\n            vec3 _2139 = normalize(normal);\n            normal = normalize(mix(_2139, normalize((_2139 * max(_2109.z, 0.0500000007450580596923828125)) + (_2136 - (_2139 * dot(_2139, _2136)))), vec3(clamp(_1967 * (_2020 ? tex_a : 1.0), 0.0, 1.0))));\n        }\n    }\n}\n\nfloat fa_sheen_albedo(float ndv, float rough)\n{\n    float _3577 = min(sqrt(max(rough - 0.100000001490116119384765625, 0.0) * 1.111111164093017578125) * 6.0, 5.999000072479248046875);\n    float _3584 = min(sqrt(clamp(ndv, 0.0, 1.0)) * 8.0, 7.999000072479248046875);\n    int _3587 = int(_3577);\n    int _3590 = int(_3584);\n    float _3600 = _3584 - float(_3590);\n    int _3655 = (_3587 * 9) + _3590;\n    int _3675 = ((_3587 + 1) * 9) + _3590;\n    return mix(mix(_3651[_3655], _3651[_3655 + 1], _3600), mix(_3651[_3675], _3651[_3675 + 1], _3600), _3577 - float(_3587));\n}\n\nFaLayers fa_layers_setup(SurfaceInput i, Surface s, vec3 n, vec3 v, float metallic, float roughness, inout vec3 f0)\n{\n    bool _6800 = false;\n    float _6801 = 1.0;\n    float _6802 = 1.0;\n    float _6803 = 1.0;\n    float _6804 = 0.0;\n    float _6805 = 0.0;\n    float _6806 = 0.0;\n    float _6807 = 0.0;\n    float _6809 = 1.0;\n    bool _6810 = false;\n    vec3 _6811 = vec3(0.0);\n    float _6812 = 1.0;\n    float _6813 = 1.0;\n    float _6814 = 1.0;\n    float _6815 = 0.0;\n    float _6816 = 0.0;\n    vec3 _6817 = vec3(1.0, 0.0, 0.0);\n    vec3 _6818 = vec3(0.0, 0.0, 1.0);\n    float _6819 = 1.0;\n    float _6820 = 1.0;\n    float _3726 = clamp(s.specular, 0.0, 1.0);\n    float _3730 = clamp(s.ior, 1.0, 3.0);\n    bool _3735 = (_3726 != 1.0) || (_3730 != 1.5);\n    bool _3744;\n    if (!_3735)\n    {\n        _3744 = any(notEqual(s.specular_color, vec3(1.0)));\n    }\n    else\n    {\n        _3744 = _3735;\n    }\n    if (_3744)\n    {\n        float _3752 = (_3730 - 1.0) / (_3730 + 1.0);\n        f0 = mix(min(vec3(_3752 * _3752) * max(s.specular_color, vec3(0.0)), vec3(1.0)) * _3726, s.albedo, vec3(metallic));\n        _6801 = mix(_3726, 1.0, metallic);\n        _6800 = true;\n    }\n    float _3779 = clamp(s.clearcoat, 0.0, 1.0);\n    if (_3779 > 0.0)\n    {\n        float _3787 = clamp(s.clearcoat_roughness, 0.0500000007450580596923828125, 1.0);\n        _6804 = _3779;\n        _6805 = _3787;\n        float _3794 = _3787 * _3787;\n        _6806 = _3794;\n        _6807 = _3794 * _3794;\n        float _3806 = max(dot(i.world_normal, v), 9.9999997473787516355514526367188e-05);\n        _6809 = _3806;\n        _6802 = 1.0 - (_3779 * (0.039999999105930328369140625 + (0.959999978542327880859375 * pow(clamp(1.0 - _3806, 0.0, 1.0), 5.0))));\n        _6800 = true;\n    }\n    vec3 _3825 = max(s.sheen_color, vec3(0.0));\n    float _3834 = max(_3825.x, max(_3825.y, _3825.z));\n    if (_3834 > 0.0)\n    {\n        float _3842 = clamp(s.sheen_roughness, 0.100000001490116119384765625, 1.0);\n        _6810 = true;\n        _6811 = _3825;\n        _6812 = _3842;\n        _6813 = _3842 * _3842;\n        float param = max(dot(n, v), 9.9999997473787516355514526367188e-05);\n        float param_1 = _3842;\n        float _3859 = fa_sheen_albedo(param, param_1);\n        _6815 = _3859;\n        _6814 = 1.0 - min(_3834 * _3859, 1.0);\n        _6800 = true;\n    }\n    _6803 = _6802 * _6814;\n    float _3878 = clamp(s.anisotropy, -1.0, 1.0);\n    if (_3878 != 0.0)\n    {\n        vec3 _3893 = i.world_tangent.xyz - (n * dot(n, i.world_tangent.xyz));\n        vec3 t = _3893;\n        if (dot(_3893, _3893) < 9.9999999392252902907785028219223e-09)\n        {\n            bvec3 _3905 = bvec3(abs(n.y) < 0.9900000095367431640625);\n            t = cross(vec3(_3905.x ? vec3(0.0, 1.0, 0.0).x : vec3(1.0, 0.0, 0.0).x, _3905.y ? vec3(0.0, 1.0, 0.0).y : vec3(1.0, 0.0, 0.0).y, _3905.z ? vec3(0.0, 1.0, 0.0).z : vec3(1.0, 0.0, 0.0).z), n);\n        }\n        vec3 _3909 = t;\n        vec3 _3910 = normalize(_3909);\n        t = _3910;\n        vec3 _3935 = normalize((_3910 * cos(s.anisotropy_rotation)) + ((cross(n, _3910) * ((i.world_tangent.w < 0.0) ? (-1.0) : 1.0)) * sin(s.anisotropy_rotation)));\n        _6817 = _3935;\n        _6818 = cross(n, _3935);\n        float _3945 = roughness * roughness;\n        float _3951 = mix(_3945, 1.0, _3878 * _3878);\n        bool _3953 = _3878 > 0.0;\n        _6819 = _3953 ? _3951 : _3945;\n        _6820 = _3953 ? _3945 : _3951;\n        _6816 = _3878;\n        _6800 = true;\n    }\n    return FaLayers(_6800, _6801, _6802, _6803, _6804, _6805, _6806, _6807, i.world_normal, _6809, _6810, _6811, _6812, _6813, _6814, _6815, _6816, _6817, _6818, _6819, _6820);\n}\n\nvec3 fa_sky_sh_coef(int k)\n{\n    vec3 v = textureLod(fa_env_tex_fa_env_smp, vec3(1.0, 1.0 - (float((2 * (k >> 2)) + 1) * 0.25), 1.0 - (float((2 * (k & 3)) + 1) * 0.25)), 5.0).xyz;\n    if (fa_mesh_fs_params[11].w > 1.5)\n    {\n        v = (v - vec3(0.5)) * 8.0;\n    }\n    return v;\n}\n\nvec3 fa_sh_eval(vec3 c[9], vec3 n)\n{\n    vec3 _3334 = max((((c[0] * 0.2820948064327239990234375) + (((c[1] * (0.3257350027561187744140625 * n.y)) + (c[2] * (0.3257350027561187744140625 * n.z))) + (c[3] * (0.3257350027561187744140625 * n.x)))) + (((c[4] * ((0.2731371223926544189453125 * n.x) * n.y)) + (c[5] * ((0.2731371223926544189453125 * n.y) * n.z))) + (c[6] * (0.078847892582416534423828125 * (((3.0 * n.z) * n.z) - 1.0))))) + ((c[7] * ((0.2731371223926544189453125 * n.x) * n.z)) + (c[8] * (0.13656856119632720947265625 * ((n.x * n.x) - (n.y * n.y))))), vec3(0.0));\n    return _3334;\n}\n\nvec3 fa_ambient_light(vec3 n)\n{\n    if (fa_mesh_fs_params[11].w > 0.5)\n    {\n        vec3 c[9];\n        for (int k = 0; k < 9; k++)\n        {\n            int param = k;\n            c[k] = fa_sky_sh_coef(param);\n        }\n        vec3 param_1[9] = c;\n        vec3 param_2 = n;\n        return fa_sh_eval(param_1, param_2);\n    }\n    return fa_mesh_fs_params[1].xyz;\n}\n\nvec3 fa_indirect_diffuse(vec3 n)\n{\n    if (fa_lm.z > 0.5)\n    {\n        return textureLod(fa_lightmap_fa_env_smp, fa_lm.xy, 0.0).xyz;\n    }\n    vec3 param = n;\n    return fa_ambient_light(param);\n}\n\nint fa_cluster_index(int slot, int n)\n{\n    int param = (int(fa_mesh_fs_params[19].x) + int(fa_mesh_fs_params[19].w)) + ((slot + n) >> 2);\n    vec4 t = fa_light_texel(param);\n    return int(t[(slot + n) & 3]);\n}\n\nint fa_cl_light(int n)\n{\n    if (n < fa_cl_ndir)\n    {\n        return n;\n    }\n    int param = fa_cl_slot;\n    int param_1 = n - fa_cl_ndir;\n    return fa_cluster_index(param, param_1);\n}\n\nint fa_light_base(int li)\n{\n    return li * ((fa_mesh_fs_params[1].w > 4.5) ? 8 : 4);\n}\n\nbool fa_light_baked(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 3;\n    return fa_light_texel(param_1).w > 0.5;\n}\n\nfloat fa_light_type(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 1;\n    return fa_light_texel(param_1).w;\n}\n\nvec4 fa_atlas_fetch(vec2 texel)\n{\n    return textureLod(fa_light_atlas_fa_env_smp, texel / vec2(textureSize(fa_light_atlas_fa_env_smp, 0)), 0.0);\n}\n\nvec3 fa_cookie_sample(vec2 tile_origin, vec2 uv)\n{\n    vec2 param = (tile_origin + vec2(1.0)) + (clamp(uv, vec2(0.0), vec2(1.0)) * 254.0);\n    return fa_atlas_fetch(param).xyz;\n}\n\nvec3 fa_area_point(vec3 c, vec3 axis, vec3 ru, vec3 uu, float hx, float hy, float shape, vec3 p, vec3 r)\n{\n    bool _741 = dot(r, r) > 0.5;\n    if (shape > 1.5)\n    {\n        vec3 _754 = (c - (ru * hx)) - p;\n        vec3 _760 = ru * (2.0 * hx);\n        float _766 = max(dot(_760, _760), 9.9999999392252902907785028219223e-09);\n        float _770 = dot(_754, _760);\n        float t = clamp((-_770) / _766, 0.0, 1.0);\n        if (_741)\n        {\n            float _785 = dot(r, _760);\n            float _791 = _766 - (_785 * _785);\n            if (abs(_791) > (9.9999997473787516355514526367188e-06 * _766))\n            {\n                t = clamp(((dot(r, _754) * _785) - _770) / _791, 0.0, 1.0);\n            }\n        }\n        return (p + _754) + (_760 * t);\n    }\n    vec3 q = p;\n    float _823 = dot(r, axis);\n    bool _831;\n    if (_741)\n    {\n        _831 = abs(_823) > 9.9999997473787516355514526367188e-05;\n    }\n    else\n    {\n        _831 = _741;\n    }\n    if (_831)\n    {\n        float _841 = dot(c - p, axis) / _823;\n        if (_841 > 0.0)\n        {\n            q = p + (r * _841);\n        }\n    }\n    vec3 _854 = q - c;\n    vec2 xy = vec2(dot(_854, ru), dot(_854, uu));\n    if (shape > 0.5)\n    {\n        float _869 = length(xy);\n        if (_869 > hx)\n        {\n            xy *= (hx / _869);\n        }\n    }\n    else\n    {\n        xy = clamp(xy, vec2(-hx, -hy), vec2(hx, hy));\n    }\n    return (c + (ru * xy.x)) + (uu * xy.y);\n}\n\nint fa_cube_face(vec3 d)\n{\n    vec3 _503 = abs(d);\n    float _505 = _503.x;\n    float _507 = _503.y;\n    bool _508 = _505 >= _507;\n    bool _516;\n    if (_508)\n    {\n        _516 = _505 >= _503.z;\n    }\n    else\n    {\n        _516 = _508;\n    }\n    int _517;\n    if (_516)\n    {\n        _517 = (d.x > 0.0) ? 0 : 1;\n    }\n    else\n    {\n        int _532;\n        if (_507 >= _503.z)\n        {\n            _532 = (d.y > 0.0) ? 2 : 3;\n        }\n        else\n        {\n            _532 = (d.z > 0.0) ? 4 : 5;\n        }\n        _517 = _532;\n    }\n    return _517;\n}\n\nvoid fa_cube_face_basis(int f, out vec3 fwd, out vec3 up)\n{\n    if (f == 0)\n    {\n        fwd = vec3(1.0, 0.0, 0.0);\n        up = vec3(0.0, 1.0, 0.0);\n    }\n    else\n    {\n        if (f == 1)\n        {\n            fwd = vec3(-1.0, 0.0, 0.0);\n            up = vec3(0.0, 1.0, 0.0);\n        }\n        else\n        {\n            if (f == 2)\n            {\n                fwd = vec3(0.0, 1.0, 0.0);\n                up = vec3(0.0, 0.0, 1.0);\n            }\n            else\n            {\n                if (f == 3)\n                {\n                    fwd = vec3(0.0, -1.0, 0.0);\n                    up = vec3(0.0, 0.0, -1.0);\n                }\n                else\n                {\n                    if (f == 4)\n                    {\n                        fwd = vec3(0.0, 0.0, 1.0);\n                        up = vec3(0.0, 1.0, 0.0);\n                    }\n                    else\n                    {\n                        fwd = vec3(0.0, 0.0, -1.0);\n                        up = vec3(0.0, 1.0, 0.0);\n                    }\n                }\n            }\n        }\n    }\n}\n\nfloat fa_ies_sample(vec2 tile_origin, vec3 d, vec3 axis, vec3 right, vec3 up)\n{\n    float _661 = dot(d, right);\n    float _665 = dot(d, up);\n    float _676;\n    if (((_661 * _661) + (_665 * _665)) > 1.0000000133514319600180897396058e-10)\n    {\n        _676 = atan(_665, _661) * 0.15915493667125701904296875;\n    }\n    else\n    {\n        _676 = 0.0;\n    }\n    vec2 param = tile_origin + vec2(1.0 + ((_676 - floor(_676)) * 64.0), 1.0 + (acos(clamp(dot(d, axis), -1.0, 1.0)) * 10.18591594696044921875));\n    return fa_atlas_fetch(param).x;\n}\n\nLightSample fa_light_sample_n(int li, vec3 world_pos, vec3 n)\n{\n    int param = li;\n    int _907 = fa_light_base(param);\n    bool _911 = fa_mesh_fs_params[1].w > 4.5;\n    int param_1 = _907;\n    vec4 _915 = fa_light_texel(param_1);\n    int param_2 = _907 + 1;\n    vec4 _920 = fa_light_texel(param_2);\n    float _923 = _920.w;\n    float atten = 1.0;\n    float dist = 0.0;\n    fa_light_tint = vec3(1.0);\n    bool _935 = _911 && (_923 > 2.5);\n    fa_light_is_area = _935;\n    bool _937 = _923 < 0.5;\n    vec3 l;\n    if (_937)\n    {\n        l = normalize(_915.xyz);\n        if (_911)\n        {\n            int param_3 = _907 + 6;\n            vec4 _951 = fa_light_texel(param_3);\n            if (_951.z > 0.5)\n            {\n                int param_4 = _907 + 4;\n                vec4 _961 = fa_light_texel(param_4);\n                int param_5 = _907 + 5;\n                vec4 _966 = fa_light_texel(param_5);\n                vec2 param_6 = _951.xy;\n                vec2 param_7 = fract(vec2(dot(world_pos, _961.xyz) * _961.w, (-dot(world_pos, _966.xyz)) * _966.w) + vec2(0.5));\n                fa_light_tint = fa_cookie_sample(param_6, param_7);\n            }\n        }\n    }\n    else\n    {\n        vec3 _996 = _915.xyz;\n        vec3 _998 = _996 - world_pos;\n        vec3 to_light = _998;\n        float _1001 = length(_998);\n        float reach = _1001;\n        bool front = true;\n        if (_935)\n        {\n            int param_8 = _907 + 7;\n            reach = max(_1001 - fa_light_texel(param_8).w, 0.0);\n            int param_9 = _907 + 4;\n            vec4 _1025 = fa_light_texel(param_9);\n            int param_10 = _907 + 5;\n            vec4 _1030 = fa_light_texel(param_10);\n            int param_11 = _907 + 6;\n            vec4 _1035 = fa_light_texel(param_11);\n            float _1036 = _1035.w;\n            int param_12 = _907 + 2;\n            vec3 _1043 = normalize(fa_light_texel(param_12).xyz);\n            bool _1045 = _1036 > 1.5;\n            bool _1053;\n            if (!_1045)\n            {\n                _1053 = dot(_1043, to_light) < 0.0;\n            }\n            else\n            {\n                _1053 = _1045;\n            }\n            front = _1053;\n            vec3 r = vec3(0.0);\n            vec3 _1062 = fa_mesh_fs_params[0].xyz - world_pos;\n            bool _1066 = dot(n, n) > 0.5;\n            bool _1074;\n            if (_1066)\n            {\n                _1074 = dot(_1062, _1062) > 9.9999999600419720025001879548654e-13;\n            }\n            else\n            {\n                _1074 = _1066;\n            }\n            if (_1074)\n            {\n                r = reflect(-normalize(_1062), normalize(n));\n            }\n            vec3 param_13 = _996;\n            vec3 param_14 = _1043;\n            vec3 param_15 = _1025.xyz;\n            vec3 param_16 = _1030.xyz;\n            float param_17 = _1025.w;\n            float param_18 = _1030.w;\n            float param_19 = _1036;\n            vec3 param_20 = world_pos;\n            vec3 param_21 = r;\n            to_light = fa_area_point(param_13, param_14, param_15, param_16, param_17, param_18, param_19, param_20, param_21) - world_pos;\n        }\n        float _1110 = length(to_light);\n        dist = _1110;\n        l = to_light / vec3(max(_1110, 9.9999997473787516355514526367188e-05));\n        float _1124 = reach / max(_915.w, 0.001000000047497451305389404296875);\n        float _1130 = clamp(1.0 - (_1124 * _1124), 0.0, 1.0);\n        float _1132;\n        if (front)\n        {\n            _1132 = _1130 * _1130;\n        }\n        else\n        {\n            _1132 = 0.0;\n        }\n        atten = _1132;\n        bool _1143 = _923 < 2.5;\n        if ((_923 > 1.5) && _1143)\n        {\n            int param_22 = _907 + 2;\n            vec4 _1151 = fa_light_texel(param_22);\n            float _1161 = _1151.w;\n            int param_23 = _907 + 3;\n            vec4 _1166 = fa_light_texel(param_23);\n            float _1167 = _1166.x;\n            float cos_inner = _1167;\n            if (_1167 > 1.5)\n            {\n                cos_inner = mix(_1161, 1.0, 0.25);\n            }\n            atten *= smoothstep(_1161, cos_inner, dot(-l, normalize(_1151.xyz)));\n        }\n        if (_911 && (_923 < 1.5))\n        {\n            int param_24 = _907 + 6;\n            vec4 _1191 = fa_light_texel(param_24);\n            if (_1191.z > 0.5)\n            {\n                vec3 _1199 = -to_light;\n                int param_25 = _907 + 4;\n                int param_26 = _907 + 5;\n                vec3 _1213 = fa_light_texel(param_25).xyz;\n                vec3 _1217 = fa_light_texel(param_26).xyz;\n                vec3 _1226 = vec3(dot(_1199, _1213), dot(_1199, _1217), dot(_1199, cross(_1213, _1217)));\n                vec3 param_27 = _1226;\n                int _1230 = fa_cube_face(param_27);\n                int param_28 = _1230;\n                vec3 param_29;\n                vec3 param_30;\n                fa_cube_face_basis(param_28, param_29, param_30);\n                vec2 _1257 = vec2(dot(_1226, cross(param_29, param_30)), dot(_1226, param_30)) / vec2(max(dot(_1226, param_29), 9.9999997473787516355514526367188e-05));\n                int _1261 = _1230 / 3;\n                vec2 param_31 = _1191.xy + (vec2(float(_1230 - (_1261 * 3)), float(_1261)) * 256.0);\n                vec2 param_32 = vec2(0.5 + (0.5 * _1257.x), 0.5 - (0.5 * _1257.y));\n                fa_light_tint = fa_cookie_sample(param_31, param_32);\n            }\n            int param_33 = _907 + 7;\n            vec4 _1291 = fa_light_texel(param_33);\n            if (_1291.z > 0.5)\n            {\n                int param_34 = _907 + 2;\n                int param_35 = _907 + 4;\n                int param_36 = _907 + 5;\n                vec2 param_37 = _1291.xy;\n                vec3 param_38 = -l;\n                vec3 param_39 = normalize(fa_light_texel(param_34).xyz);\n                vec3 param_40 = fa_light_texel(param_35).xyz;\n                vec3 param_41 = fa_light_texel(param_36).xyz;\n                atten *= fa_ies_sample(param_37, param_38, param_39, param_40, param_41);\n            }\n        }\n        else\n        {\n            if (_911 && _1143)\n            {\n                int param_42 = _907 + 6;\n                vec4 _1338 = fa_light_texel(param_42);\n                int param_43 = _907 + 7;\n                vec4 _1343 = fa_light_texel(param_43);\n                bool _1346 = _1338.z > 0.5;\n                bool _1353;\n                if (!_1346)\n                {\n                    _1353 = _1343.z > 0.5;\n                }\n                else\n                {\n                    _1353 = _1346;\n                }\n                if (_1353)\n                {\n                    int param_44 = _907 + 2;\n                    vec4 _1360 = fa_light_texel(param_44);\n                    vec3 _1364 = normalize(_1360.xyz);\n                    int param_45 = _907 + 4;\n                    vec4 _1369 = fa_light_texel(param_45);\n                    int param_46 = _907 + 5;\n                    vec4 _1374 = fa_light_texel(param_46);\n                    if (_1346)\n                    {\n                        vec3 _1382 = -to_light;\n                        float _1389 = _1360.w;\n                        float _1405 = 0.5 / max(dot(_1382, _1364) * (sqrt(max(1.0 - (_1389 * _1389), 0.0)) / max(_1389, 0.001000000047497451305389404296875)), 9.9999997473787516355514526367188e-05);\n                        vec2 param_47 = _1338.xy;\n                        vec2 param_48 = vec2(0.5 + (dot(_1382, _1369.xyz) * _1405), 0.5 - (dot(_1382, _1374.xyz) * _1405));\n                        fa_light_tint = fa_cookie_sample(param_47, param_48);\n                    }\n                    if (_1343.z > 0.5)\n                    {\n                        vec2 param_49 = _1343.xy;\n                        vec3 param_50 = -l;\n                        vec3 param_51 = _1364;\n                        vec3 param_52 = _1369.xyz;\n                        vec3 param_53 = _1374.xyz;\n                        atten *= fa_ies_sample(param_49, param_50, param_51, param_52, param_53);\n                    }\n                }\n            }\n        }\n    }\n    vec3 _6788 = _920.xyz * atten;\n    if (_911)\n    {\n        _6788 *= fa_light_tint;\n    }\n    int _1474;\n    if (_937)\n    {\n        _1474 = 0;\n    }\n    else\n    {\n        _1474 = ((_923 > 1.5) && (_923 < 2.5)) ? 2 : 1;\n    }\n    return LightSample(l, _6788, atten, 1.0, dist, _1474);\n}\n\nfloat fa_shadow_split_at(int i)\n{\n    float _2211;\n    if (i == 0)\n    {\n        _2211 = fa_shadows[24].x;\n    }\n    else\n    {\n        float _2227;\n        if (i == 1)\n        {\n            _2227 = fa_shadows[24].y;\n        }\n        else\n        {\n            float _2235;\n            if (i == 2)\n            {\n                _2235 = fa_shadows[24].z;\n            }\n            else\n            {\n                _2235 = fa_shadows[24].w;\n            }\n            _2227 = _2235;\n        }\n        _2211 = _2227;\n    }\n    return _2211;\n}\n\nfloat fa_shadow_depth(inout vec2 uv, vec4 rect)\n{\n    uv = clamp(uv, rect.xy, rect.zw);\n    return textureLod(fa_shadow_tex_fa_shadow_smp, uv, 0.0).x;\n}\n\nfloat fa_shadow_fetch(vec2 uv, vec4 rect, vec3 conv)\n{\n    vec2 param = uv;\n    vec4 param_1 = rect;\n    float _2268 = fa_shadow_depth(param, param_1);\n    float _2272;\n    if (conv.x < 0.5)\n    {\n        _2272 = _2268;\n    }\n    else\n    {\n        _2272 = (conv.y * conv.z) / (conv.z - (_2268 * (conv.z - conv.y)));\n    }\n    return _2272;\n}\n\nfloat fa_shadow_noise()\n{\n    return fract(52.98291778564453125 * fract(dot(gl_FragCoord.xy, vec2(0.067110560834407806396484375, 0.005837149918079376220703125))));\n}\n\nvec2 fa_shadow_vogel(int k, int n, float phi)\n{\n    float _2199 = (float(k) * 2.3999631404876708984375) + phi;\n    return vec2(cos(_2199), sin(_2199)) * sqrt((float(k) + 0.5) / float(n));\n}\n\nfloat fa_shadow_filter(vec2 uv, vec4 rect, float zr, float texel_m, float unit, float reach, float plane, vec3 conv, int mode, float k)\n{\n    if (mode == 1)\n    {\n        vec2 param = uv;\n        vec4 param_1 = rect;\n        vec3 param_2 = conv;\n        return float(zr <= fa_shadow_fetch(param, param_1, param_2));\n    }\n    float _2318 = fa_shadow_noise() * 6.283185482025146484375;\n    float radius = 1.5;\n    if (mode == 2)\n    {\n        float _2327;\n        if (k < 0.0)\n        {\n            _2327 = (-k) / max(zr, 0.100000001490116119384765625);\n        }\n        else\n        {\n            _2327 = k;\n        }\n        float _2347 = clamp((_2327 * reach) / texel_m, 3.0, 12.0);\n        float sum = 0.0;\n        float cnt = 0.0;\n        for (int i = 0; i < 16; i++)\n        {\n            int param_3 = i;\n            int param_4 = 16;\n            float param_5 = _2318;\n            vec2 _2366 = fa_shadow_vogel(param_3, param_4, param_5) * _2347;\n            vec2 param_6 = uv + (_2366 * fa_shadows[26].zw);\n            vec4 param_7 = rect;\n            vec3 param_8 = conv;\n            float _2378 = fa_shadow_fetch(param_6, param_7, param_8);\n            if (_2378 < (zr - (length(_2366) * plane)))\n            {\n                sum += _2378;\n                cnt += 1.0;\n            }\n        }\n        if (cnt < 0.5)\n        {\n            return 1.0;\n        }\n        float _2404 = sum / cnt;\n        float _2414;\n        if (k < 0.0)\n        {\n            _2414 = (-k) / max(_2404, 0.0500000007450580596923828125);\n        }\n        else\n        {\n            _2414 = k;\n        }\n        radius = clamp(((max(zr - _2404, 0.0) * unit) * _2414) / texel_m, 1.5, 16.0);\n    }\n    float lit = 0.0;\n    int _2436 = (mode == 2) ? 24 : 16;\n    for (int i_1 = 0; i_1 < _2436; i_1++)\n    {\n        int param_9 = i_1;\n        int param_10 = _2436;\n        float param_11 = _2318;\n        vec2 _2455 = fa_shadow_vogel(param_9, param_10, param_11) * radius;\n        vec2 param_12 = uv + (_2455 * fa_shadows[26].zw);\n        vec4 param_13 = rect;\n        vec3 param_14 = conv;\n        lit += float((zr - (length(_2455) * plane)) <= fa_shadow_fetch(param_12, param_13, param_14));\n    }\n    return lit / float(_2436);\n}\n\nfloat fa_shadow_cascade(int ci, vec3 world, vec3 n, vec3 l)\n{\n    float _2497 = max(fa_shadows[ci * 1 + 20].y, 0.001000000047497451305389404296875);\n    float _2502 = clamp(dot(n, l), 0.0, 1.0);\n    float _2508 = sqrt(1.0 - (_2502 * _2502));\n    float _2515 = min(_2508 / max(_2502, 0.20000000298023223876953125), 4.0);\n    float _2520;\n    if (fa_shadows[26].y > 0.0)\n    {\n        _2520 = fa_shadows[26].y;\n    }\n    else\n    {\n        _2520 = 1.5 * fa_shadows[ci * 1 + 20].x;\n    }\n    vec4 _2545 = mat4(fa_shadows[ci * 4 + 0], fa_shadows[ci * 4 + 1], fa_shadows[ci * 4 + 2], fa_shadows[ci * 4 + 3]) * vec4(world + (n * (_2520 * _2508)), 1.0);\n    float _2552 = _2545.x;\n    bool _2555 = _2552 < fa_shadows[ci * 1 + 16].x;\n    bool _2564;\n    if (!_2555)\n    {\n        _2564 = _2552 > fa_shadows[ci * 1 + 16].z;\n    }\n    else\n    {\n        _2564 = _2555;\n    }\n    bool _2573;\n    if (!_2564)\n    {\n        _2573 = _2545.y < fa_shadows[ci * 1 + 16].y;\n    }\n    else\n    {\n        _2573 = _2564;\n    }\n    bool _2582;\n    if (!_2573)\n    {\n        _2582 = _2545.y > fa_shadows[ci * 1 + 16].w;\n    }\n    else\n    {\n        _2582 = _2573;\n    }\n    bool _2589;\n    if (!_2582)\n    {\n        _2589 = _2545.z > 1.0;\n    }\n    else\n    {\n        _2589 = _2582;\n    }\n    if (_2589)\n    {\n        return -1.0;\n    }\n    float _2597;\n    if (fa_shadows[26].x > 0.0)\n    {\n        _2597 = fa_shadows[26].x;\n    }\n    else\n    {\n        _2597 = 1.5 * fa_shadows[ci * 1 + 20].x;\n    }\n    vec2 param = _2545.xy;\n    vec4 param_1 = fa_shadows[ci * 1 + 16];\n    float param_2 = _2545.z - ((_2597 * (1.0 + (0.5 * _2515))) / _2497);\n    float param_3 = fa_shadows[ci * 1 + 20].x;\n    float param_4 = _2497;\n    float param_5 = _2497 * 0.25;\n    float param_6 = ((fa_shadows[ci * 1 + 20].x * min(_2515, 3.0)) * 0.5) / _2497;\n    vec3 param_7 = vec3(0.0);\n    int param_8 = int(fa_shadows[25].z + 0.5);\n    float param_9 = fa_shadows[25].w;\n    return fa_shadow_filter(param, param_1, param_2, param_3, param_4, param_5, param_6, param_7, param_8, param_9);\n}\n\nfloat fa_shadow_sun(vec3 world, vec3 n, vec3 l)\n{\n    if (fa_mesh_fs_params[5].z < 0.5)\n    {\n        return 1.0;\n    }\n    int _2975 = int(fa_shadows[25].x + 0.5);\n    if (_2975 < 1)\n    {\n        return 1.0;\n    }\n    float _2990 = dot(world - fa_shadows[27].xyz, fa_shadows[28].xyz);\n    int param = _2975 - 1;\n    if (_2990 > fa_shadow_split_at(param))\n    {\n        return 1.0;\n    }\n    int ci = 0;\n    bool _3002 = _2975 > 1;\n    bool _3009;\n    if (_3002)\n    {\n        _3009 = _2990 > fa_shadows[24].x;\n    }\n    else\n    {\n        _3009 = _3002;\n    }\n    if (_3009)\n    {\n        ci = 1;\n    }\n    bool _3013 = _2975 > 2;\n    bool _3020;\n    if (_3013)\n    {\n        _3020 = _2990 > fa_shadows[24].y;\n    }\n    else\n    {\n        _3020 = _3013;\n    }\n    if (_3020)\n    {\n        ci = 2;\n    }\n    bool _3024 = _2975 > 3;\n    bool _3031;\n    if (_3024)\n    {\n        _3031 = _2990 > fa_shadows[24].z;\n    }\n    else\n    {\n        _3031 = _3024;\n    }\n    if (_3031)\n    {\n        ci = 3;\n    }\n    float s = -1.0;\n    for (int k = 0; k < 4; k++)\n    {\n        if (ci >= _2975)\n        {\n            break;\n        }\n        int param_1 = ci;\n        vec3 param_2 = world;\n        vec3 param_3 = n;\n        vec3 param_4 = l;\n        float _3057 = fa_shadow_cascade(param_1, param_2, param_3, param_4);\n        s = _3057;\n        if (_3057 >= 0.0)\n        {\n            break;\n        }\n        ci++;\n    }\n    if (s < 0.0)\n    {\n        return 1.0;\n    }\n    if (fa_shadows[25].y > 0.0)\n    {\n        float _3082;\n        if (ci > 0)\n        {\n            int param_5 = ci - 1;\n            _3082 = fa_shadow_split_at(param_5);\n        }\n        else\n        {\n            _3082 = fa_shadows[28].w;\n        }\n        int param_6 = ci;\n        float _3101 = fa_shadows[25].y * max(fa_shadow_split_at(param_6) - _3082, 9.9999997473787516355514526367188e-05);\n        int param_7 = ci;\n        float _3112 = clamp((_2990 - (fa_shadow_split_at(param_7) - _3101)) / _3101, 0.0, 1.0);\n        if (_3112 > 0.0)\n        {\n            float s2 = 1.0;\n            if ((ci + 1) < _2975)\n            {\n                int param_8 = ci + 1;\n                vec3 param_9 = world;\n                vec3 param_10 = n;\n                vec3 param_11 = l;\n                float _3133 = fa_shadow_cascade(param_8, param_9, param_10, param_11);\n                s2 = _3133;\n                if (_3133 < 0.0)\n                {\n                    s2 = s;\n                }\n            }\n            s = mix(s, s2, _3112);\n        }\n    }\n    return s;\n}\n\nfloat fa_shadow_factor(vec3 n, vec3 l)\n{\n    vec3 param = fa_world_pos;\n    vec3 param_1 = n;\n    vec3 param_2 = l;\n    return fa_shadow_sun(param, param_1, param_2);\n}\n\nfloat fa_shadow_local(int li, vec3 lpos, vec3 world, vec3 n, vec3 l)\n{\n    bool _2655 = fa_mesh_fs_params[5].z < 0.5;\n    bool _2662;\n    if (!_2655)\n    {\n        _2662 = fa_shadows[29].x < 0.5;\n    }\n    else\n    {\n        _2662 = _2655;\n    }\n    if (_2662)\n    {\n        return 1.0;\n    }\n    int param = (int(fa_shadows[29].x + 0.5) - 1) + li;\n    vec4 _2675 = fa_light_texel(param);\n    float _2676 = _2675.x;\n    if (_2676 < 0.0)\n    {\n        return 1.0;\n    }\n    int _2685 = int(_2676 + 0.5);\n    int param_1 = _2685;\n    vec4 _2689 = fa_light_texel(param_1);\n    int param_2 = _2685 + 1;\n    vec4 _2694 = fa_light_texel(param_2);\n    float fade = 1.0;\n    float _2697 = _2689.y;\n    if (_2697 > 0.0)\n    {\n        float _2714 = 1.0 - smoothstep(0.75 * _2697, _2697, length(world - fa_shadows[27].xyz));\n        fade = _2714;\n        if (_2714 <= 0.0)\n        {\n            return 1.0;\n        }\n    }\n    int face = 0;\n    if (_2689.x > 1.5)\n    {\n        vec3 param_3 = world - lpos;\n        face = fa_cube_face(param_3);\n    }\n    int _2738 = (_2685 + 2) + (face * 6);\n    int param_4 = _2738;\n    int param_5 = _2738 + 1;\n    int param_6 = _2738 + 3;\n    vec4 _2752 = fa_light_texel(param_6);\n    int param_7 = _2738 + 4;\n    vec4 _2757 = fa_light_texel(param_7);\n    int param_8 = _2738 + 5;\n    vec4 _2762 = fa_light_texel(param_8);\n    float _2774 = _2762.x * max(dot(_2752, vec4(world, 1.0)), 0.001000000047497451305389404296875);\n    float _2779 = clamp(dot(n, l), 0.0, 1.0);\n    float _2802 = clamp(dot(n, _2752.xyz), -1.0, 1.0);\n    float _2821 = min(sqrt(1.0 - (_2802 * _2802)) / max(abs(dot(n, world - lpos)) / max(dot(_2752, vec4(world, 1.0)), 0.001000000047497451305389404296875), 0.20000000298023223876953125), 4.0);\n    float _2824 = _2694.y;\n    float _2826;\n    if (_2824 > 0.0)\n    {\n        _2826 = _2824;\n    }\n    else\n    {\n        _2826 = 1.5 * _2774;\n    }\n    vec4 _2846 = vec4(world + (n * (_2826 * sqrt(1.0 - (_2779 * _2779)))), 1.0);\n    float _2850 = dot(_2752, _2846);\n    float _2853 = _2762.y;\n    if (_2850 < _2853)\n    {\n        return 1.0;\n    }\n    vec2 _2868 = vec2(dot(fa_light_texel(param_4), _2846), dot(fa_light_texel(param_5), _2846)) / vec2(_2850);\n    float _2870 = _2868.x;\n    bool _2873 = _2870 < _2757.x;\n    bool _2882;\n    if (!_2873)\n    {\n        _2882 = _2870 > _2757.z;\n    }\n    else\n    {\n        _2882 = _2873;\n    }\n    bool _2891;\n    if (!_2882)\n    {\n        _2891 = _2868.y < _2757.y;\n    }\n    else\n    {\n        _2891 = _2882;\n    }\n    bool _2900;\n    if (!_2891)\n    {\n        _2900 = _2868.y > _2757.w;\n    }\n    else\n    {\n        _2900 = _2891;\n    }\n    if (_2900)\n    {\n        return 1.0;\n    }\n    float _2906 = _2694.x;\n    float _2908;\n    if (_2906 > 0.0)\n    {\n        _2908 = _2906;\n    }\n    else\n    {\n        _2908 = 1.5 * _2774;\n    }\n    vec2 param_9 = _2868;\n    vec4 param_10 = _2757;\n    float param_11 = _2850 - (_2908 * (1.0 + (0.5 * _2821)));\n    float param_12 = _2774;\n    float param_13 = 1.0;\n    float param_14 = _2762.z * 0.25;\n    float param_15 = (_2774 * min(_2821, 3.0)) * 0.5;\n    vec3 param_16 = vec3(1.0, _2853, _2762.z);\n    int param_17 = int(_2689.z + 0.5);\n    float param_18 = _2689.w;\n    return mix(1.0, fa_shadow_filter(param_9, param_10, param_11, param_12, param_13, param_14, param_15, param_16, param_17, param_18), fade);\n}\n\nLightSample fa_light_shadowed(int li, vec3 world_pos, vec3 gn)\n{\n    bool _4497 = fa_lm.z > 0.5;\n    bool _4503;\n    if (_4497)\n    {\n        int param = li;\n        _4503 = fa_light_baked(param);\n    }\n    else\n    {\n        _4503 = _4497;\n    }\n    if (_4503)\n    {\n        int param_1 = li;\n        return LightSample(vec3(0.0, 1.0, 0.0), vec3(0.0), 0.0, 1.0, 0.0, int(fa_light_type(param_1) + 0.5));\n    }\n    int param_2 = li;\n    vec3 param_3 = world_pos;\n    vec3 param_4 = gn;\n    LightSample _4527 = fa_light_sample_n(param_2, param_3, param_4);\n    vec3 _6857 = _4527.color;\n    float _6859 = _4527.shadow;\n    if ((_4527.type == 0) && (li == 0))\n    {\n        vec3 param_5 = gn;\n        vec3 param_6 = _4527.direction;\n        float _4541 = fa_shadow_factor(param_5, param_6);\n        _6859 = _4541;\n        _6857 *= _4541;\n    }\n    else\n    {\n        bool _4552 = _4527.type != 0;\n        bool _4558;\n        if (_4552)\n        {\n            _4558 = _4527.attenuation > 0.0;\n        }\n        else\n        {\n            _4558 = _4552;\n        }\n        if (_4558)\n        {\n            int param_7 = li;\n            int param_8 = fa_light_base(param_7);\n            int param_9 = li;\n            vec3 param_10 = fa_light_texel(param_8).xyz;\n            vec3 param_11 = world_pos;\n            vec3 param_12 = gn;\n            vec3 param_13 = _4527.direction;\n            float _4577 = fa_shadow_local(param_9, param_10, param_11, param_12, param_13);\n            _6859 = _4577;\n            _6857 *= _4577;\n        }\n    }\n    return LightSample(_4527.direction, _6857, _4527.attenuation, _6859, _4527._distance, _4527.type);\n}\n\nvec3 fa_ltc_tangent(vec3 n, vec3 v)\n{\n    vec3 _4617 = v - (n * dot(v, n));\n    vec3 t = _4617;\n    float _4621 = dot(_4617, _4617);\n    float l2 = _4621;\n    if (_4621 < 1.0000000133514319600180897396058e-10)\n    {\n        vec3 _4631;\n        if (abs(n.z) < 0.999000012874603271484375)\n        {\n            _4631 = cross(n, vec3(0.0, 0.0, 1.0));\n        }\n        else\n        {\n            _4631 = cross(n, vec3(1.0, 0.0, 0.0));\n        }\n        t = _4631;\n        l2 = dot(_4631, _4631);\n    }\n    return t * inversesqrt(l2);\n}\n\nvec3 fa_ltc_local(vec3 t1, vec3 n, vec3 p)\n{\n    return vec3(dot(t1, p), dot(cross(n, t1), p), dot(n, p));\n}\n\nvec3 fa_ltc_edge_vector(vec3 a, vec3 b)\n{\n    float _4666 = dot(a, a);\n    float _4670 = dot(b, b);\n    if ((_4666 < 1.0000000195414813782625560981111e-24) || (_4670 < 1.0000000195414813782625560981111e-24))\n    {\n        return vec3(0.0);\n    }\n    vec3 _4684 = a * inversesqrt(_4666);\n    vec3 _4689 = b * inversesqrt(_4670);\n    float _4693 = dot(_4684, _4689);\n    float _4696 = abs(_4693);\n    float g = (((((((((((0.0416471660137176513671875 * _4696) - 0.1924748718738555908203125) * _4696) + 0.4179156124591827392578125) * _4696) - 0.616057217121124267578125) * _4696) + 0.777722418308258056640625) * _4696) - 0.999542415142059326171875) * _4696) + 1.570791721343994140625;\n    if (_4693 < 0.0)\n    {\n        g = (3.1415927410125732421875 * inversesqrt(max(1.0 - (_4693 * _4693), 1.0000000116860974230803549289703e-07))) - g;\n    }\n    return cross(_4684, _4689) * g;\n}\n\nvoid fa_ltc_clip_edge(vec3 a, vec3 b, inout vec3 sum, inout vec3 leave, inout vec3 enter, inout vec2 seen)\n{\n    bool _4753 = a.z > 0.0;\n    bool _4757 = b.z > 0.0;\n    if (_4753 && _4757)\n    {\n        vec3 param = a;\n        vec3 param_1 = b;\n        sum += fa_ltc_edge_vector(param, param_1);\n    }\n    else\n    {\n        if (_4753 != _4757)\n        {\n            vec3 _4792 = a + ((b - a) * (a.z / (a.z - b.z)));\n            _4792.z = 0.0;\n            if (_4753)\n            {\n                vec3 param_2 = a;\n                vec3 param_3 = _4792;\n                sum += fa_ltc_edge_vector(param_2, param_3);\n                leave = _4792;\n                seen.x = 1.0;\n            }\n            else\n            {\n                vec3 param_4 = _4792;\n                vec3 param_5 = b;\n                sum += fa_ltc_edge_vector(param_4, param_5);\n                enter = _4792;\n                seen.y = 1.0;\n            }\n        }\n    }\n}\n\nfloat fa_ltc_quad(vec4 abcd, vec3 p0, vec3 p1, vec3 p2, vec3 p3)\n{\n    vec3 _4841 = vec3((abcd.x * p0.x) + (abcd.y * p0.z), p0.y, (abcd.z * p0.x) + (abcd.w * p0.z));\n    vec3 _4867 = vec3((abcd.x * p1.x) + (abcd.y * p1.z), p1.y, (abcd.z * p1.x) + (abcd.w * p1.z));\n    vec3 _4893 = vec3((abcd.x * p2.x) + (abcd.y * p2.z), p2.y, (abcd.z * p2.x) + (abcd.w * p2.z));\n    vec3 _4919 = vec3((abcd.x * p3.x) + (abcd.y * p3.z), p3.y, (abcd.z * p3.x) + (abcd.w * p3.z));\n    vec3 sum = vec3(0.0);\n    vec3 leave = vec3(0.0);\n    vec3 enter = vec3(0.0);\n    vec3 param = _4841;\n    vec3 param_1 = _4867;\n    vec3 param_2 = vec3(0.0);\n    vec3 param_3 = vec3(0.0);\n    vec3 param_4 = vec3(0.0);\n    vec2 param_5 = vec2(0.0);\n    fa_ltc_clip_edge(param, param_1, param_2, param_3, param_4, param_5);\n    sum = param_2;\n    leave = param_3;\n    enter = param_4;\n    vec3 param_6 = _4867;\n    vec3 param_7 = _4893;\n    vec3 param_8 = param_2;\n    vec3 param_9 = param_3;\n    vec3 param_10 = param_4;\n    vec2 param_11 = param_5;\n    fa_ltc_clip_edge(param_6, param_7, param_8, param_9, param_10, param_11);\n    sum = param_8;\n    leave = param_9;\n    enter = param_10;\n    vec3 param_12 = _4893;\n    vec3 param_13 = _4919;\n    vec3 param_14 = param_8;\n    vec3 param_15 = param_9;\n    vec3 param_16 = param_10;\n    vec2 param_17 = param_11;\n    fa_ltc_clip_edge(param_12, param_13, param_14, param_15, param_16, param_17);\n    sum = param_14;\n    leave = param_15;\n    enter = param_16;\n    vec3 param_18 = _4919;\n    vec3 param_19 = _4841;\n    vec3 param_20 = param_14;\n    vec3 param_21 = param_15;\n    vec3 param_22 = param_16;\n    vec2 param_23 = param_17;\n    fa_ltc_clip_edge(param_18, param_19, param_20, param_21, param_22, param_23);\n    sum = param_20;\n    leave = param_21;\n    enter = param_22;\n    if ((param_23.x * param_23.y) > 0.5)\n    {\n        vec3 param_24 = leave;\n        vec3 param_25 = enter;\n        sum += fa_ltc_edge_vector(param_24, param_25);\n    }\n    return sum.z * 0.15915493667125701904296875;\n}\n\nfloat fa_ltc_rect(vec4 abcd, vec3 center, vec3 ex, vec3 ey)\n{\n    vec4 param = abcd;\n    vec3 param_1 = (center - ex) - ey;\n    vec3 param_2 = (center + ex) - ey;\n    vec3 param_3 = (center + ex) + ey;\n    vec3 param_4 = (center - ex) + ey;\n    return abs(fa_ltc_quad(param, param_1, param_2, param_3, param_4));\n}\n\nfloat fa_area_form(vec4 m, float shape, vec3 pc, vec3 ex, vec3 ey)\n{\n    if ((shape < 0.5) || (shape > 1.5))\n    {\n        vec4 param = m;\n        vec3 param_1 = pc;\n        vec3 param_2 = ex;\n        vec3 param_3 = ey;\n        return fa_ltc_rect(param, param_1, param_2, param_3);\n    }\n    vec3 _5069 = (pc + (ex * 0.92387950420379638671875)) + (ey * 0.3826834261417388916015625);\n    vec3 _5093 = (pc - (ex * 0.92387950420379638671875)) + (ey * 0.3826834261417388916015625);\n    vec3 _5109 = (pc - (ex * 0.3826834261417388916015625)) - (ey * 0.92387950420379638671875);\n    vec4 param_4 = m;\n    vec3 param_5 = _5069;\n    vec3 param_6 = (pc + (ex * 0.3826834261417388916015625)) + (ey * 0.92387950420379638671875);\n    vec3 param_7 = (pc - (ex * 0.3826834261417388916015625)) + (ey * 0.92387950420379638671875);\n    vec3 param_8 = _5093;\n    vec4 param_9 = m;\n    vec3 param_10 = _5069;\n    vec3 param_11 = _5093;\n    vec3 param_12 = (pc - (ex * 0.92387950420379638671875)) - (ey * 0.3826834261417388916015625);\n    vec3 param_13 = _5109;\n    vec4 param_14 = m;\n    vec3 param_15 = _5069;\n    vec3 param_16 = _5109;\n    vec3 param_17 = (pc + (ex * 0.3826834261417388916015625)) - (ey * 0.92387950420379638671875);\n    vec3 param_18 = (pc + (ex * 0.92387950420379638671875)) - (ey * 0.3826834261417388916015625);\n    return abs((fa_ltc_quad(param_4, param_5, param_6, param_7, param_8) + fa_ltc_quad(param_9, param_10, param_11, param_12, param_13)) + fa_ltc_quad(param_14, param_15, param_16, param_17, param_18));\n}\n\nvec2 fa_ltc_uv(float roughness, float ndv)\n{\n    return ((vec2(clamp((roughness - 0.0500000007450580596923828125) * 1.0526316165924072265625, 0.0, 1.0), sqrt(clamp(1.0 - ndv, 0.0, 1.0))) * 63.0) + vec2(0.5)) * vec2(0.015625);\n}\n\nvec3 fa_area_shade(int li, vec3 world_pos, vec3 n, vec3 v, vec3 diffuse_color, vec3 f0, float f90, float roughness, float ndv, float window)\n{\n    int param = li;\n    int _5167 = fa_light_base(param);\n    int param_1 = _5167;\n    int param_2 = _5167 + 1;\n    int param_3 = _5167 + 2;\n    int param_4 = _5167 + 4;\n    vec4 _5189 = fa_light_texel(param_4);\n    int param_5 = _5167 + 5;\n    vec4 _5194 = fa_light_texel(param_5);\n    int param_6 = _5167 + 6;\n    vec4 _5199 = fa_light_texel(param_6);\n    float _5200 = _5199.w;\n    vec3 _5205 = fa_light_texel(param_1).xyz - world_pos;\n    bool _5207 = _5200 < 1.5;\n    bool _5214;\n    if (_5207)\n    {\n        _5214 = dot(normalize(fa_light_texel(param_3).xyz), _5205) >= 0.0;\n    }\n    else\n    {\n        _5214 = _5207;\n    }\n    if (_5214)\n    {\n        return vec3(0.0);\n    }\n    bool _5223 = (_5200 > 0.5) && _5207;\n    float _5227 = _5223 ? 1.0539000034332275390625 : 1.0;\n    vec3 _5230 = _5189.xyz;\n    float _5232 = _5189.w;\n    vec3 _5238 = _5194.xyz;\n    float _5240 = _5194.w;\n    vec3 up = _5238 * (_5240 * _5227);\n    float _5246;\n    if (_5223)\n    {\n        _5246 = (3.1415927410125732421875 * _5232) * _5232;\n    }\n    else\n    {\n        _5246 = (4.0 * _5232) * _5240;\n    }\n    if (_5200 > 1.5)\n    {\n        vec3 _5272 = cross(_5230, -_5205);\n        vec3 perp = _5272;\n        float _5276 = dot(_5272, _5272);\n        vec3 _5279;\n        if (_5276 > 1.0000000133514319600180897396058e-10)\n        {\n            _5279 = perp * inversesqrt(_5276);\n        }\n        else\n        {\n            _5279 = _5238;\n        }\n        perp = _5279;\n        up = _5279 * _5240;\n    }\n    float _5300 = max(_5246, 9.9999999747524270787835121154785e-07);\n    vec3 param_7 = n;\n    vec3 param_8 = v;\n    vec3 _5310 = fa_ltc_tangent(param_7, param_8);\n    vec3 param_9 = _5310;\n    vec3 param_10 = n;\n    vec3 param_11 = _5205;\n    vec3 _5318 = fa_ltc_local(param_9, param_10, param_11);\n    vec3 param_12 = _5310;\n    vec3 param_13 = n;\n    vec3 param_14 = _5230 * (_5232 * _5227);\n    vec3 _5326 = fa_ltc_local(param_12, param_13, param_14);\n    vec3 param_15 = _5310;\n    vec3 param_16 = n;\n    vec3 param_17 = up;\n    vec3 _5334 = fa_ltc_local(param_15, param_16, param_17);\n    vec4 param_18 = vec4(1.0, 0.0, 0.0, 1.0);\n    float param_19 = _5200;\n    vec3 param_20 = _5318;\n    vec3 param_21 = _5326;\n    vec3 param_22 = _5334;\n    float param_23 = roughness;\n    float param_24 = ndv;\n    vec2 _5353 = fa_ltc_uv(param_23, param_24) * 64.0;\n    vec2 param_25 = _5353;\n    vec2 param_26 = _5353 + vec2(64.0, 0.0);\n    vec4 _5363 = fa_atlas_fetch(param_26);\n    vec4 param_27 = fa_atlas_fetch(param_25);\n    float param_28 = _5200;\n    vec3 param_29 = _5318;\n    vec3 param_30 = _5326;\n    vec3 param_31 = _5334;\n    return (((diffuse_color * fa_area_form(param_18, param_19, param_20, param_21, param_22)) + (((f0 * _5363.x) + ((vec3(f90) - f0) * _5363.y)) * fa_area_form(param_27, param_28, param_29, param_30, param_31))) * fa_light_texel(param_2).xyz) * ((((3.1415927410125732421875 * dot(_5205, _5205)) + _5300) / _5300) * window);\n}\n\nvec3 fa_light_rgb(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 1;\n    return fa_light_texel(param_1).xyz;\n}\n\nfloat fa_d_charlie(float alpha, float ndh)\n{\n    float _4200 = 1.0 / alpha;\n    return ((2.0 + _4200) * pow(sqrt(max(1.0 - (ndh * ndh), 9.9999997473787516355514526367188e-05)), _4200)) * 0.15915493667125701904296875;\n}\n\nfloat fa_v_ashikhmin(float ndl, float ndv)\n{\n    return clamp(0.25 / max((ndl + ndv) - (ndl * ndv), 9.9999997473787516355514526367188e-05), 0.0, 1.0);\n}\n\nfloat fa_layers_coat(FaLayers L, vec3 l, vec3 h, float vdh)\n{\n    float _4235 = max(dot(L.nc, l), 0.0);\n    float _4241 = max(dot(L.nc, h), 0.0);\n    float _4250 = ((_4241 * _4241) * (L.coat_a2 - 1.0)) + 1.0;\n    return (((L.coat * (0.039999999105930328369140625 + (0.959999978542327880859375 * pow(clamp(1.0 - vdh, 0.0, 1.0), 5.0)))) * (((L.coat_a2 / ((3.1415927410125732421875 * _4250) * _4250)) * (0.5 / max(mix((2.0 * _4235) * L.coat_ndv, _4235 + L.coat_ndv, L.coat_alpha), 9.9999997473787516355514526367188e-05))) * 3.1415927410125732421875)) * step(9.9999997473787516355514526367188e-05, _4235)) * _4235;\n}\n\nvec3 fa_area_layers(FaLayers L, int li, vec3 world_pos, vec3 n, vec3 v, vec3 l, vec3 diffuse_color, vec3 f0, float roughness, float ndv, float window)\n{\n    int param = li;\n    vec3 param_1 = world_pos;\n    vec3 param_2 = n;\n    vec3 param_3 = v;\n    vec3 param_4 = diffuse_color;\n    vec3 param_5 = f0;\n    float param_6 = L.f90;\n    float param_7 = roughness;\n    float param_8 = ndv;\n    float param_9 = window;\n    float _5431;\n    if (L.sheen_on)\n    {\n        _5431 = L.sheen_scale;\n    }\n    else\n    {\n        _5431 = 1.0;\n    }\n    vec3 result = fa_area_shade(param, param_1, param_2, param_3, param_4, param_5, param_6, param_7, param_8, param_9) * (L.keep * _5431);\n    vec3 _5444 = normalize(l + v);\n    int param_10 = li;\n    vec3 _5455 = fa_light_rgb(param_10) * window;\n    if (L.sheen_on)\n    {\n        float _5464 = max(dot(n, l), 0.0);\n        float param_11 = L.sheen_alpha;\n        float param_12 = max(dot(n, _5444), 0.0);\n        float param_13 = _5464;\n        float param_14 = ndv;\n        result += ((L.sheen * _5455) * (((((fa_d_charlie(param_11, param_12) * fa_v_ashikhmin(param_13, param_14)) * 3.1415927410125732421875) * step(9.9999997473787516355514526367188e-05, _5464)) * _5464) * L.keep));\n    }\n    if (L.coat > 0.0)\n    {\n        FaLayers param_15 = L;\n        vec3 param_16 = l;\n        vec3 param_17 = _5444;\n        float param_18 = max(dot(v, _5444), 0.0);\n        result += (_5455 * fa_layers_coat(param_15, param_16, param_17, param_18));\n    }\n    return result;\n}\n\nfloat fa_d_ggx_aniso(float ndh, float tdh, float bdh, float at, float ab)\n{\n    float _4103 = tdh / at;\n    float _4107 = bdh / ab;\n    float _4119 = ((_4103 * _4103) + (_4107 * _4107)) + (ndh * ndh);\n    return 1.0 / ((((3.1415927410125732421875 * at) * ab) * _4119) * _4119);\n}\n\nfloat fa_lambda_ggx_aniso(float n, float t, float b, float at, float ab)\n{\n    return 0.5 * (sqrt(1.0 + (((((at * at) * t) * t) + (((ab * ab) * b) * b)) / max(n * n, 9.9999999392252902907785028219223e-09))) - 1.0);\n}\n\nfloat fa_v_ggx_aniso(float ndl, float ndv, float tdv, float bdv, float tdl, float bdl, float at, float ab)\n{\n    float param = ndv;\n    float param_1 = tdv;\n    float param_2 = bdv;\n    float param_3 = at;\n    float param_4 = ab;\n    float param_5 = ndl;\n    float param_6 = tdl;\n    float param_7 = bdl;\n    float param_8 = at;\n    float param_9 = ab;\n    return clamp(1.0 / ((4.0 * max(ndl * ndv, 9.9999997473787516355514526367188e-05)) * ((1.0 + fa_lambda_ggx_aniso(param, param_1, param_2, param_3, param_4)) + fa_lambda_ggx_aniso(param_5, param_6, param_7, param_8, param_9))), 0.0, 1.0);\n}\n\nvec3 fa_layers_light(FaLayers L, vec3 diffuse_color, vec3 f0, vec3 n, vec3 v, vec3 l, vec3 h, float ndl, float ndv, float ndh, float vdh, float alpha, float a2)\n{\n    float _4299 = step(9.9999997473787516355514526367188e-05, ndl);\n    float d_ggx;\n    float vis;\n    if (L.aniso != 0.0)\n    {\n        float param = ndh;\n        float param_1 = dot(L.t, h);\n        float param_2 = dot(L.b, h);\n        float param_3 = L.at;\n        float param_4 = L.ab;\n        d_ggx = fa_d_ggx_aniso(param, param_1, param_2, param_3, param_4);\n        float param_5 = ndl;\n        float param_6 = ndv;\n        float param_7 = dot(L.t, v);\n        float param_8 = dot(L.b, v);\n        float param_9 = dot(L.t, l);\n        float param_10 = dot(L.b, l);\n        float param_11 = L.at;\n        float param_12 = L.ab;\n        vis = fa_v_ggx_aniso(param_5, param_6, param_7, param_8, param_9, param_10, param_11, param_12);\n    }\n    else\n    {\n        float _4378 = ((ndh * ndh) * (a2 - 1.0)) + 1.0;\n        d_ggx = a2 / ((3.1415927410125732421875 * _4378) * _4378);\n        vis = 0.5 / max(mix((2.0 * ndl) * ndv, ndl + ndv, alpha), 9.9999997473787516355514526367188e-05);\n    }\n    vec3 base = diffuse_color + (((f0 + ((vec3(L.f90) - f0) * pow(clamp(1.0 - vdh, 0.0, 1.0), 5.0))) * ((d_ggx * vis) * 3.1415927410125732421875)) * _4299);\n    if (L.sheen_on)\n    {\n        float param_13 = L.sheen_alpha;\n        float param_14 = ndh;\n        float param_15 = ndl;\n        float param_16 = ndv;\n        base = (base * L.sheen_scale) + (L.sheen * (((fa_d_charlie(param_13, param_14) * fa_v_ashikhmin(param_15, param_16)) * 3.1415927410125732421875) * _4299));\n    }\n    vec3 result = base * (L.keep * ndl);\n    if (L.coat > 0.0)\n    {\n        FaLayers param_17 = L;\n        vec3 param_18 = l;\n        vec3 param_19 = h;\n        float param_20 = vdh;\n        result += vec3(fa_layers_coat(param_17, param_18, param_19, param_20));\n    }\n    return result;\n}\n\nvec2 fa_env_brdf(float rough, float ndv)\n{\n    vec4 _3509 = (vec4(-1.0, -0.0274999998509883880615234375, -0.572000026702880859375, 0.02199999988079071044921875) * rough) + vec4(1.0, 0.0425000004470348358154296875, 1.03999996185302734375, -0.039999999105930328369140625);\n    float _3512 = _3509.x;\n    return (vec2(-1.03999996185302734375, 1.03999996185302734375) * ((min(_3512 * _3512, exp2((-9.27999973297119140625) * ndv)) * _3512) + _3509.y)) + _3509.zw;\n}\n\nvec3 fa_environment(vec3 d, float rough)\n{\n    if (fa_mesh_fs_params[11].w > 0.5)\n    {\n        return textureLod(fa_env_tex_fa_env_smp, d, clamp(rough, 0.0, 1.0) * fa_mesh_fs_params[12].w).xyz;\n    }\n    float _3363 = rough * rough;\n    float _3393 = 0.60000002384185791015625 * _3363;\n    return mix(mix(fa_mesh_fs_params[12].xyz * 0.550000011920928955078125, mix(fa_mesh_fs_params[12].xyz, fa_mesh_fs_params[11].xyz, vec3(pow(clamp(d.y * (1.0 - (0.699999988079071044921875 * _3363)), 0.0, 1.0), 0.550000011920928955078125))), vec3(smoothstep((-0.0500000007450580596923828125) - _3393, 0.0500000007450580596923828125 + _3393, d.y))), ((fa_mesh_fs_params[11].xyz + fa_mesh_fs_params[12].xyz) * 0.5) * 0.800000011920928955078125, vec3(_3363 * 0.60000002384185791015625));\n}\n\nvec3 fa_layers_ibl(FaLayers L, vec3 n, vec3 v, vec3 f0, float roughness)\n{\n    vec3 rn = n;\n    if (L.aniso != 0.0)\n    {\n        vec3 _3986;\n        if (L.aniso >= 0.0)\n        {\n            _3986 = L.b;\n        }\n        else\n        {\n            _3986 = L.t;\n        }\n        rn = normalize(mix(n, cross(cross(_3986, v), _3986), vec3(abs(L.aniso))));\n    }\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05);\n    vec2 _4019 = fa_env_brdf(param, param_1);\n    vec3 param_2 = reflect(-v, rn);\n    float param_3 = roughness;\n    vec3 result = (fa_environment(param_2, param_3) * ((f0 * _4019.x) + (vec3(L.f90) * _4019.y))) * L.base_scale;\n    if (L.sheen_on)\n    {\n        vec3 param_4 = n;\n        float param_5 = L.sheen_rough;\n        result += ((L.sheen * (L.sheen_e * L.keep)) * fa_environment(param_4, param_5));\n    }\n    if (L.coat > 0.0)\n    {\n        float param_6 = L.coat_rough;\n        float param_7 = L.coat_ndv;\n        vec2 _4074 = fa_env_brdf(param_6, param_7);\n        vec3 param_8 = reflect(-v, L.nc);\n        float param_9 = L.coat_rough;\n        result += (fa_environment(param_8, param_9) * (L.coat * ((0.039999999105930328369140625 * _4074.x) + _4074.y)));\n    }\n    return result;\n}\n\nvec3 fa_sky_reflection(vec3 n, vec3 v, vec3 f0, float roughness)\n{\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05);\n    vec2 _3551 = fa_env_brdf(param, param_1);\n    vec3 param_2 = reflect(-v, n);\n    float param_3 = roughness;\n    return fa_environment(param_2, param_3) * ((f0 * _3551.x) + vec3(_3551.y));\n}\n\nvec3 fa_shadow_debug(vec3 color, vec3 world)\n{\n    if (fa_shadows[27].w < 0.5)\n    {\n        return color;\n    }\n    int _3157 = int(fa_shadows[25].x + 0.5);\n    float _3167 = dot(world - fa_shadows[27].xyz, fa_shadows[28].xyz);\n    vec3 tint_1 = vec3(0.3499999940395355224609375);\n    bool _3172 = _3157 > 0;\n    bool _3181;\n    if (_3172)\n    {\n        int param = _3157 - 1;\n        _3181 = _3167 <= fa_shadow_split_at(param);\n    }\n    else\n    {\n        _3181 = _3172;\n    }\n    if (_3181)\n    {\n        tint_1 = vec3(1.0, 0.1500000059604644775390625, 0.100000001490116119384765625);\n        bool _3187 = _3157 > 1;\n        bool _3194;\n        if (_3187)\n        {\n            _3194 = _3167 > fa_shadows[24].x;\n        }\n        else\n        {\n            _3194 = _3187;\n        }\n        if (_3194)\n        {\n            tint_1 = vec3(0.100000001490116119384765625, 0.89999997615814208984375, 0.20000000298023223876953125);\n        }\n        bool _3200 = _3157 > 2;\n        bool _3207;\n        if (_3200)\n        {\n            _3207 = _3167 > fa_shadows[24].y;\n        }\n        else\n        {\n            _3207 = _3200;\n        }\n        if (_3207)\n        {\n            tint_1 = vec3(0.1500000059604644775390625, 0.300000011920928955078125, 1.0);\n        }\n        bool _3213 = _3157 > 3;\n        bool _3220;\n        if (_3213)\n        {\n            _3220 = _3167 > fa_shadows[24].z;\n        }\n        else\n        {\n            _3220 = _3213;\n        }\n        if (_3220)\n        {\n            tint_1 = vec3(1.0, 0.89999997615814208984375, 0.100000001490116119384765625);\n        }\n    }\n    return mix(color, tint_1, vec3(0.550000011920928955078125));\n}\n\nvoid main()\n{\n    fa_inst_load();\n    vec3 _6557 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _6557 = -_6557;\n    }\n    vec3 _5915 = normalize(fa_mesh_fs_params[0].xyz - fa_world_pos);\n    vec3 param = fa_world_pos;\n    fa_cluster_begin(param);\n    SurfaceInput param_1 = SurfaceInput(fa_world_pos, _6557, fa_world_tangent, fa_uv, fa_vertex_color, _5915, gl_FrontFacing);\n    Surface _5923 = fa_standard_surface(param_1);\n    vec3 _6588 = _5923.albedo;\n    float _6589 = _5923.alpha;\n    vec3 _6590 = _5923.normal;\n    float _6591 = _5923.metallic;\n    float _6592 = _5923.roughness;\n    float _6593 = _5923.occlusion;\n    vec3 _6594 = _5923.emission;\n    float _6595 = _5923.clearcoat;\n    float _6596 = _5923.clearcoat_roughness;\n    vec3 _6597 = _5923.sheen_color;\n    float _6598 = _5923.sheen_roughness;\n    float _6599 = _5923.anisotropy;\n    float _6600 = _5923.anisotropy_rotation;\n    float _6601 = _5923.specular;\n    float _6602 = _5923.ior;\n    vec3 _6603 = _5923.specular_color;\n    SurfaceInput param_2 = SurfaceInput(fa_world_pos, _6557, fa_world_tangent, fa_uv, fa_vertex_color, _5915, gl_FrontFacing);\n    Surface param_3 = _5923;\n    surface(param_2, param_3);\n    _6588 = param_3.albedo;\n    _6589 = param_3.alpha;\n    _6590 = param_3.normal;\n    _6591 = param_3.metallic;\n    _6592 = param_3.roughness;\n    _6593 = param_3.occlusion;\n    _6594 = param_3.emission;\n    _6595 = param_3.clearcoat;\n    _6596 = param_3.clearcoat_roughness;\n    _6597 = param_3.sheen_color;\n    _6598 = param_3.sheen_roughness;\n    _6599 = param_3.anisotropy;\n    _6600 = param_3.anisotropy_rotation;\n    _6601 = param_3.specular;\n    _6602 = param_3.ior;\n    _6603 = param_3.specular_color;\n    vec3 param_4 = fa_world_pos;\n    vec3 param_5 = _6557;\n    vec3 param_6 = param_3.albedo;\n    vec3 param_7 = param_3.normal;\n    fa_apply_decals(param_4, param_5, param_6, param_7);\n    _6588 = param_6;\n    _6590 = param_7;\n    vec3 result;\n    if (fa_mesh_fs_params[3].w > 0.5)\n    {\n        result = _6588;\n    }\n    else\n    {\n        vec3 _5962 = normalize(_6590);\n        float _5969 = clamp(_6591, 0.0, 1.0);\n        float _5973 = clamp(_6592, 0.0500000007450580596923828125, 1.0);\n        float _5977 = _5973 * _5973;\n        float _5981 = _5977 * _5977;\n        float _5986 = max(dot(_5962, _5915), 9.9999997473787516355514526367188e-05);\n        vec3 _5992 = _6588 * (1.0 - _5969);\n        vec3 _5999 = mix(vec3(0.039999999105930328369140625), _6588, vec3(_5969));\n        vec3 f0 = _5999;\n        SurfaceInput param_8 = SurfaceInput(fa_world_pos, _6557, fa_world_tangent, fa_uv, fa_vertex_color, _5915, gl_FrontFacing);\n        Surface param_9 = Surface(_6588, _6589, _6590, _6591, _6592, _6593, _6594, _6595, _6596, _6597, _6598, _6599, _6600, _6601, _6602, _6603);\n        vec3 param_10 = _5962;\n        vec3 param_11 = _5915;\n        float param_12 = _5969;\n        float param_13 = _5973;\n        vec3 param_14 = _5999;\n        FaLayers _6015 = fa_layers_setup(param_8, param_9, param_10, param_11, param_12, param_13, param_14);\n        f0 = param_14;\n        vec3 param_15 = _5962;\n        vec3 lit = (fa_indirect_diffuse(param_15) * _5992) * _6593;\n        if (_6015.on)\n        {\n            lit *= _6015.base_scale;\n        }\n        int _6037 = fa_cl_ndir + fa_cl_local;\n        for (int ln = 0; ln < _6037; ln++)\n        {\n            int param_16 = ln;\n            int _6050 = fa_cl_light(param_16);\n            bool _6053 = fa_lm.z > 0.5;\n            bool _6059;\n            if (_6053)\n            {\n                int param_17 = _6050;\n                _6059 = fa_light_baked(param_17);\n            }\n            else\n            {\n                _6059 = _6053;\n            }\n            if (_6059)\n            {\n                continue;\n            }\n            int param_18 = _6050;\n            vec3 param_19 = fa_world_pos;\n            vec3 param_20 = _6557;\n            LightSample _6071 = fa_light_shadowed(param_18, param_19, param_20);\n            float _6079 = max(dot(_5962, _6071.direction), 0.0);\n            float _6085 = _6071.attenuation * _6071.shadow;\n            vec3 _6090 = normalize(_6071.direction + _5915);\n            float _6095 = max(dot(_5962, _6090), 0.0);\n            float _6100 = max(dot(_5915, _6090), 0.0);\n            bool _6107;\n            if (fa_light_is_area)\n            {\n                _6107 = !_6015.on;\n            }\n            else\n            {\n                _6107 = fa_light_is_area;\n            }\n            if (_6107)\n            {\n                int param_21 = _6050;\n                vec3 param_22 = fa_world_pos;\n                vec3 param_23 = _5962;\n                vec3 param_24 = _5915;\n                vec3 param_25 = _5992;\n                vec3 param_26 = f0;\n                float param_27 = 1.0;\n                float param_28 = _5973;\n                float param_29 = _5986;\n                float param_30 = _6085;\n                lit += fa_area_shade(param_21, param_22, param_23, param_24, param_25, param_26, param_27, param_28, param_29, param_30);\n            }\n            else\n            {\n                if (fa_light_is_area)\n                {\n                    FaLayers param_31 = _6015;\n                    int param_32 = _6050;\n                    vec3 param_33 = fa_world_pos;\n                    vec3 param_34 = _5962;\n                    vec3 param_35 = _5915;\n                    vec3 param_36 = _6071.direction;\n                    vec3 param_37 = _5992;\n                    vec3 param_38 = f0;\n                    float param_39 = _5973;\n                    float param_40 = _5986;\n                    float param_41 = _6085;\n                    lit += fa_area_layers(param_31, param_32, param_33, param_34, param_35, param_36, param_37, param_38, param_39, param_40, param_41);\n                }\n                else\n                {\n                    if (_6015.on)\n                    {\n                        FaLayers param_42 = _6015;\n                        vec3 param_43 = _5992;\n                        vec3 param_44 = f0;\n                        vec3 param_45 = _5962;\n                        vec3 param_46 = _5915;\n                        vec3 param_47 = _6071.direction;\n                        vec3 param_48 = _6090;\n                        float param_49 = _6079;\n                        float param_50 = _5986;\n                        float param_51 = _6095;\n                        float param_52 = _6100;\n                        float param_53 = _5977;\n                        float param_54 = _5981;\n                        int param_55 = _6050;\n                        lit += (fa_layers_light(param_42, param_43, param_44, param_45, param_46, param_47, param_48, param_49, param_50, param_51, param_52, param_53, param_54) * ((fa_light_rgb(param_55) * fa_light_tint) * _6085));\n                    }\n                    else\n                    {\n                        float _6213 = ((_6095 * _6095) * (_5981 - 1.0)) + 1.0;\n                        int param_56 = _6050;\n                        lit += (((_5992 + (((f0 + ((vec3(1.0) - f0) * pow(1.0 - _6100, 5.0))) * (((_5981 / ((3.1415927410125732421875 * _6213) * _6213)) * (0.5 / max(mix((2.0 * _6079) * _5986, _6079 + _5986, _5977), 9.9999997473787516355514526367188e-05))) * 3.1415927410125732421875)) * step(9.9999997473787516355514526367188e-05, _6079))) * (fa_light_rgb(param_56) * fa_light_tint)) * (_6079 * _6085));\n                    }\n                }\n            }\n        }\n        if (_6015.on)\n        {\n            FaLayers param_57 = _6015;\n            vec3 param_58 = _5962;\n            vec3 param_59 = _5915;\n            vec3 param_60 = f0;\n            float param_61 = _5973;\n            lit += (fa_layers_ibl(param_57, param_58, param_59, param_60, param_61) * _6593);\n        }\n        else\n        {\n            vec3 param_62 = _5962;\n            vec3 param_63 = _5915;\n            vec3 param_64 = f0;\n            float param_65 = _5973;\n            lit += (fa_sky_reflection(param_62, param_63, param_64, param_65) * _6593);\n        }\n        result = lit;\n    }\n    vec3 _6308 = result;\n    vec3 _6309 = _6308 + _6594;\n    result = _6309;\n    vec3 param_66 = _6309;\n    vec3 param_67 = fa_world_pos;\n    result = fa_shadow_debug(param_66, param_67);\n    bool _6318 = fa_mesh_fs_params[7].w > 0.0;\n    bool _6325;\n    if (!_6318)\n    {\n        _6325 = fa_mesh_fs_params[8].y > 0.0;\n    }\n    else\n    {\n        _6325 = _6318;\n    }\n    if (_6325)\n    {\n        vec3 _6334 = fa_world_pos - fa_mesh_fs_params[0].xyz;\n        float _6340 = dot(_6334, fa_mesh_fs_params[9].xyz);\n        bool _6344 = fa_mesh_fs_params[9].w > 0.5;\n        float _6345;\n        if (_6344)\n        {\n            _6345 = _6340;\n        }\n        else\n        {\n            _6345 = length(_6334);\n        }\n        float _6357 = _6345 - fa_mesh_fs_params[8].x;\n        if (_6357 > 0.0)\n        {\n            float _6366 = fa_mesh_fs_params[7].w * _6357;\n            float tau = _6366 * _6366;\n            if (fa_mesh_fs_params[8].y > 0.0)\n            {\n                float _6382;\n                if (_6344)\n                {\n                    _6382 = fa_world_pos.y - (fa_mesh_fs_params[9].y * _6340);\n                }\n                else\n                {\n                    _6382 = fa_mesh_fs_params[0].y;\n                }\n                float _6403 = mix(_6382, fa_world_pos.y, clamp(fa_mesh_fs_params[8].x / _6345, 0.0, 1.0));\n                float _6407 = fa_world_pos.y - _6403;\n                float _6412 = _6403 - fa_mesh_fs_params[8].z;\n                float _6417 = fa_world_pos.y - fa_mesh_fs_params[8].z;\n                bool _6420 = _6412 <= 0.0;\n                bool _6421 = !_6420;\n                bool _6427;\n                if (_6421)\n                {\n                    _6427 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _6427 = _6420;\n                }\n                float _6428;\n                if (_6427)\n                {\n                    _6428 = fa_mesh_fs_params[8].y;\n                }\n                else\n                {\n                    _6428 = fa_mesh_fs_params[8].y * exp(-min(fa_mesh_fs_params[8].w * _6412, 80.0));\n                }\n                bool _6455;\n                if (_6421)\n                {\n                    _6455 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _6455 = _6420;\n                }\n                float _6456;\n                if (_6455)\n                {\n                    _6456 = fa_mesh_fs_params[8].y * _6412;\n                }\n                else\n                {\n                    _6456 = (fa_mesh_fs_params[8].y * (1.0 - exp(-min(fa_mesh_fs_params[8].w * _6412, 80.0)))) / fa_mesh_fs_params[8].w;\n                }\n                bool _6481 = _6417 <= 0.0;\n                bool _6488;\n                if (!_6481)\n                {\n                    _6488 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _6488 = _6481;\n                }\n                float _6489;\n                if (_6488)\n                {\n                    _6489 = fa_mesh_fs_params[8].y * _6417;\n                }\n                else\n                {\n                    _6489 = (fa_mesh_fs_params[8].y * (1.0 - exp(-min(fa_mesh_fs_params[8].w * _6417, 80.0)))) / fa_mesh_fs_params[8].w;\n                }\n                float _6516;\n                if (abs(_6407) < 0.001000000047497451305389404296875)\n                {\n                    _6516 = _6428;\n                }\n                else\n                {\n                    _6516 = (_6489 - _6456) / _6407;\n                }\n                tau += (_6357 * max(_6516, 0.0));\n            }\n            result = mix(result, fa_mesh_fs_params[7].xyz, vec3(clamp(1.0 - exp(-clamp(tau, 0.0, 80.0)), 0.0, 1.0)));\n        }\n    }\n    fa_frag_color = vec4(result, _6589);\n}\n\n",
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
            "inst_name": "_554",
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
            "inst_name": "_2221",
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
            "inst_name": "_5533",
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
      "vs": "#version 430\n\nstruct VertexData\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 color;\n    vec3 object_pos;\n};\n\nuniform vec4 fa_mesh_vs_params[11];\nlayout(location = 2) out vec3 fa_world_pos;\nlayout(location = 3) out vec3 fa_world_normal;\nlayout(location = 4) out vec4 fa_world_tangent;\nlayout(location = 5) out vec2 fa_uv;\nlayout(location = 6) out vec4 fa_vertex_color;\nlayout(location = 7) out float fa_pre_depth;\nlayout(location = 8) out vec3 fa_pre_r0;\nlayout(location = 9) out vec3 fa_pre_r1;\nlayout(location = 10) out vec3 fa_pre_r2;\nlayout(location = 9) in vec4 fa_inst_d0;\nlayout(location = 10) in vec4 fa_inst_d1;\nlayout(location = 0) flat out vec4 fa_inst_v0;\nlayout(location = 1) flat out vec4 fa_inst_v1;\nlayout(location = 5) in vec4 fa_inst_m0;\nlayout(location = 6) in vec4 fa_inst_m1;\nlayout(location = 7) in vec4 fa_inst_m2;\nlayout(location = 8) in vec4 fa_inst_m3;\nlayout(location = 0) in vec3 fa_position;\nlayout(location = 1) in vec3 fa_normal;\nlayout(location = 3) in vec4 fa_tangent;\nlayout(location = 2) in vec2 fa_texcoord0;\nlayout(location = 4) in vec4 fa_color;\nfloat raise;\nvec4 tint;\n\nvoid fa_instance_unpack(vec4 fa_d0, vec4 fa_d1, vec4 fa_d2)\n{\n    raise = fa_d0.x;\n    tint = fa_d1;\n}\n\nvoid fa_inst_begin()\n{\n    vec4 param = fa_inst_d0;\n    vec4 param_1 = fa_inst_d1;\n    vec4 param_2 = vec4(0.0);\n    fa_instance_unpack(param, param_1, param_2);\n    fa_inst_v0 = fa_inst_d0;\n    fa_inst_v1 = fa_inst_d1;\n}\n\nVertexData fa_vertex_data(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    vec3 _94 = cross(model[1].xyz, model[2].xyz);\n    float _100 = (dot(model[0].xyz, _94) < 0.0) ? (-1.0) : 1.0;\n    return VertexData((model * vec4(position, 1.0)).xyz, (((_94 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _100, vec4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _100), texcoord0 * fa_mesh_vs_params[8].xy, color, position);\n}\n\nvoid vertex(inout VertexData v)\n{\n    v.world_pos.y += raise;\n}\n\nvoid fa_prepass_vertex(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    mat4 param = model;\n    vec3 param_1 = position;\n    vec3 param_2 = normal;\n    vec4 param_3 = tangent;\n    vec2 param_4 = texcoord0;\n    vec4 param_5 = color;\n    VertexData param_6 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    vertex(param_6);\n    mat4 _190 = mat4(fa_mesh_vs_params[4], fa_mesh_vs_params[5], fa_mesh_vs_params[6], fa_mesh_vs_params[7]);\n    vec4 _197 = vec4(param_6.world_pos, 1.0);\n    fa_world_pos = param_6.world_pos;\n    fa_world_normal = param_6.world_normal;\n    fa_world_tangent = param_6.world_tangent;\n    fa_uv = param_6.uv;\n    fa_vertex_color = param_6.color;\n    fa_pre_depth = -(_190 * _197).z;\n    fa_pre_r0 = vec3(_190[0].x, _190[1].x, _190[2].x);\n    fa_pre_r1 = vec3(_190[0].y, _190[1].y, _190[2].y);\n    fa_pre_r2 = vec3(_190[0].z, _190[1].z, _190[2].z);\n    gl_Position = mat4(fa_mesh_vs_params[0], fa_mesh_vs_params[1], fa_mesh_vs_params[2], fa_mesh_vs_params[3]) * _197;\n}\n\nvoid main()\n{\n    fa_inst_begin();\n    mat4 param = mat4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3);\n    vec3 param_1 = fa_position;\n    vec3 param_2 = fa_normal;\n    vec4 param_3 = fa_tangent;\n    vec2 param_4 = fa_texcoord0;\n    vec4 param_5 = fa_color;\n    fa_prepass_vertex(param, param_1, param_2, param_3, param_4, param_5);\n}\n\n",
      "fs": "#version 430\n\nstruct SurfaceInput\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 vertex_color;\n    vec3 view_dir;\n    bool front_facing;\n};\n\nstruct Surface\n{\n    vec3 albedo;\n    float alpha;\n    vec3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    vec3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    vec3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    vec3 specular_color;\n};\n\nuniform vec4 fa_material[1];\nuniform vec4 fa_mesh_fs_params[24];\nlayout(binding = 0) uniform sampler2D fa_tex_fa_smp;\nlayout(binding = 1) uniform sampler2D fa_normal_tex_fa_smp;\nlayout(binding = 2) uniform sampler2D fa_mr_tex_fa_smp;\nlayout(binding = 3) uniform sampler2D fa_occlusion_tex_fa_smp;\nlayout(binding = 4) uniform sampler2D fa_emissive_tex_fa_smp;\n\nlayout(location = 0) flat in vec4 fa_inst_v0;\nlayout(location = 1) flat in vec4 fa_inst_v1;\nlayout(location = 2) in vec3 fa_world_pos;\nlayout(location = 3) in vec3 fa_world_normal;\nlayout(location = 4) in vec4 fa_world_tangent;\nlayout(location = 5) in vec2 fa_uv;\nlayout(location = 6) in vec4 fa_vertex_color;\nlayout(location = 8) in vec3 fa_pre_r0;\nlayout(location = 9) in vec3 fa_pre_r1;\nlayout(location = 10) in vec3 fa_pre_r2;\nlayout(location = 0) out vec4 fa_frag_color;\nlayout(location = 7) in float fa_pre_depth;\nfloat raise;\nvec4 tint;\n\nvoid fa_instance_unpack(vec4 fa_d0, vec4 fa_d1, vec4 fa_d2)\n{\n    raise = fa_d0.x;\n    tint = fa_d1;\n}\n\nvoid fa_inst_load()\n{\n    vec4 param = fa_inst_v0;\n    vec4 param_1 = fa_inst_v1;\n    vec4 param_2 = vec4(0.0);\n    fa_instance_unpack(param, param_1, param_2);\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nvec3 fa_linear_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_tex_fix(inout vec3 c, float mode)\n{\n    if (mode > 1.5)\n    {\n        vec3 param = c;\n        vec3 _212 = fa_linear_to_srgb(param);\n        c = _212;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            vec3 param_1 = c;\n            vec3 _221 = fa_srgb_to_linear(param_1);\n            c = _221;\n        }\n    }\n    return c;\n}\n\nvec3 fa_tangent_normal(SurfaceInput i, vec3 m)\n{\n    vec3 _63;\n    if (i.front_facing)\n    {\n        _63 = i.world_normal;\n    }\n    else\n    {\n        _63 = -i.world_normal;\n    }\n    vec3 _87 = normalize(i.world_tangent.xyz - (_63 * dot(_63, i.world_tangent.xyz)));\n    vec3 _115 = normalize(((_87 * m.x) + ((cross(_63, _87) * i.world_tangent.w) * m.y)) + (_63 * m.z));\n    vec3 _118;\n    if (i.front_facing)\n    {\n        _118 = _115;\n    }\n    else\n    {\n        _118 = -_115;\n    }\n    return _118;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    vec4 base_t = texture(fa_tex_fa_smp, i.uv);\n    float param = fa_mesh_fs_params[6].w;\n    float param_1 = 1.0;\n    vec3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    vec3 _264 = fa_tex_fix(param_2, param_3);\n    vec4 _771 = base_t;\n    _771.x = _264.x;\n    _771.y = _264.y;\n    _771.z = _264.z;\n    base_t = _771;\n    vec4 _280 = (_771 * fa_mesh_fs_params[2]) * i.vertex_color;\n    vec3 _734 = i.world_normal;\n    if (fa_mesh_fs_params[6].z > 0.5)\n    {\n        float param_4 = fa_mesh_fs_params[6].w;\n        float param_5 = 16.0;\n        vec3 param_6 = texture(fa_normal_tex_fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        vec3 _313 = fa_tex_fix(param_6, param_7);\n        vec3 _317 = (_313 * 2.0) - vec3(1.0);\n        vec2 _322 = _317.xy * fa_mesh_fs_params[6].x;\n        vec3 _779 = _317;\n        _779.x = _322.x;\n        _779.y = _322.y;\n        SurfaceInput param_8 = i;\n        vec3 param_9 = _779;\n        _734 = fa_tangent_normal(param_8, param_9);\n    }\n    vec4 mrt = texture(fa_mr_tex_fa_smp, i.uv);\n    float param_10 = fa_mesh_fs_params[6].w;\n    float param_11 = 64.0;\n    vec3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    vec3 _351 = fa_tex_fix(param_12, param_13);\n    vec4 _782 = mrt;\n    _782.x = _351.x;\n    _782.y = _351.y;\n    _782.z = _351.z;\n    mrt = _782;\n    vec4 _381 = texture(fa_occlusion_tex_fa_smp, i.uv);\n    float param_14 = fa_mesh_fs_params[6].w;\n    float param_15 = 256.0;\n    vec3 param_16 = _381.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    vec3 _393 = fa_tex_fix(param_16, param_17);\n    float param_18 = fa_mesh_fs_params[6].w;\n    float param_19 = 4.0;\n    vec3 param_20 = texture(fa_emissive_tex_fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    vec3 _423 = fa_tex_fix(param_20, param_21);\n    float _739 = fa_mesh_fs_params[20].x;\n    float _740 = fa_mesh_fs_params[20].y;\n    float _743 = fa_mesh_fs_params[20].z;\n    float _742 = fa_mesh_fs_params[21].w;\n    float _745 = fa_mesh_fs_params[22].x;\n    if (fa_mesh_fs_params[22].z > 0.5)\n    {\n        if (mod(fa_mesh_fs_params[22].z, 2.0) > 0.5)\n        {\n            _739 *= _393.y;\n            _740 *= _393.z;\n            _742 *= _381.w;\n        }\n        if (fa_mesh_fs_params[22].z > 1.5)\n        {\n            _743 *= mrt.x;\n            _745 *= mrt.w;\n        }\n    }\n    return Surface(_280.xyz, _280.w, _734, clamp(fa_mesh_fs_params[5].x * _351.z, 0.0, 1.0), clamp(fa_mesh_fs_params[5].y * _351.y, 0.0500000007450580596923828125, 1.0), 1.0 + (fa_mesh_fs_params[6].y * (_393.x - 1.0)), fa_mesh_fs_params[3].xyz + (fa_mesh_fs_params[4].xyz * _423), _739, _740, fa_mesh_fs_params[21].xyz, _742, _743, fa_mesh_fs_params[20].w, _745, fa_mesh_fs_params[22].y, fa_mesh_fs_params[23].xyz);\n}\n\nvoid surface(SurfaceInput i, inout Surface s)\n{\n    s.emission += ((tint.xyz * tint.w) * fa_material[0].x);\n}\n\nvoid main()\n{\n    fa_inst_load();\n    vec3 _645 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _645 = -_645;\n    }\n    vec3 _556 = normalize(fa_mesh_fs_params[0].xyz - fa_world_pos);\n    SurfaceInput param = SurfaceInput(fa_world_pos, _645, fa_world_tangent, fa_uv, fa_vertex_color, _556, gl_FrontFacing);\n    SurfaceInput param_1 = SurfaceInput(fa_world_pos, _645, fa_world_tangent, fa_uv, fa_vertex_color, _556, gl_FrontFacing);\n    Surface param_2 = fa_standard_surface(param);\n    surface(param_1, param_2);\n    vec3 _571 = normalize(param_2.normal);\n    vec3 _586 = normalize(vec3(dot(fa_pre_r0, _571), dot(fa_pre_r1, _571), dot(fa_pre_r2, _571)));\n    float _598 = _586.z;\n    vec2 e = _586.xy / vec2((abs(_586.x) + abs(_586.y)) + abs(_598));\n    if (_598 < 0.0)\n    {\n        e = (vec2(1.0) - abs(e.yx)) * vec2((e.x >= 0.0) ? 1.0 : (-1.0), (e.y >= 0.0) ? 1.0 : (-1.0));\n    }\n    fa_frag_color = vec4(min(fa_pre_depth, 60000.0), e, 1.0);\n}\n\n",
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
      "fs": "#version 430\n\nstruct SurfaceInput\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 vertex_color;\n    vec3 view_dir;\n    bool front_facing;\n};\n\nstruct Surface\n{\n    vec3 albedo;\n    float alpha;\n    vec3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    vec3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    vec3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    vec3 specular_color;\n};\n\nuniform vec4 fa_material[1];\nuniform vec4 fa_mesh_fs_params[24];\nlayout(binding = 0) uniform sampler2D fa_tex_fa_smp;\nlayout(binding = 1) uniform sampler2D fa_normal_tex_fa_smp;\nlayout(binding = 2) uniform sampler2D fa_mr_tex_fa_smp;\nlayout(binding = 3) uniform sampler2D fa_occlusion_tex_fa_smp;\nlayout(binding = 4) uniform sampler2D fa_emissive_tex_fa_smp;\n\nlayout(location = 0) flat in vec4 fa_inst_v0;\nlayout(location = 1) flat in vec4 fa_inst_v1;\nlayout(location = 2) in vec3 fa_world_pos;\nlayout(location = 3) in vec3 fa_world_normal;\nlayout(location = 4) in vec4 fa_world_tangent;\nlayout(location = 5) in vec2 fa_uv;\nlayout(location = 6) in vec4 fa_vertex_color;\nlayout(location = 8) in vec3 fa_pre_r0;\nlayout(location = 9) in vec3 fa_pre_r1;\nlayout(location = 10) in vec3 fa_pre_r2;\nlayout(location = 0) out vec4 fa_frag_color;\nlayout(location = 7) in float fa_pre_depth;\nfloat raise;\nvec4 tint;\n\nvoid fa_instance_unpack(vec4 fa_d0, vec4 fa_d1, vec4 fa_d2)\n{\n    raise = fa_d0.x;\n    tint = fa_d1;\n}\n\nvoid fa_inst_load()\n{\n    vec4 param = fa_inst_v0;\n    vec4 param_1 = fa_inst_v1;\n    vec4 param_2 = vec4(0.0);\n    fa_instance_unpack(param, param_1, param_2);\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nvec3 fa_linear_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_tex_fix(inout vec3 c, float mode)\n{\n    if (mode > 1.5)\n    {\n        vec3 param = c;\n        vec3 _212 = fa_linear_to_srgb(param);\n        c = _212;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            vec3 param_1 = c;\n            vec3 _221 = fa_srgb_to_linear(param_1);\n            c = _221;\n        }\n    }\n    return c;\n}\n\nvec3 fa_tangent_normal(SurfaceInput i, vec3 m)\n{\n    vec3 _63;\n    if (i.front_facing)\n    {\n        _63 = i.world_normal;\n    }\n    else\n    {\n        _63 = -i.world_normal;\n    }\n    vec3 _87 = normalize(i.world_tangent.xyz - (_63 * dot(_63, i.world_tangent.xyz)));\n    vec3 _115 = normalize(((_87 * m.x) + ((cross(_63, _87) * i.world_tangent.w) * m.y)) + (_63 * m.z));\n    vec3 _118;\n    if (i.front_facing)\n    {\n        _118 = _115;\n    }\n    else\n    {\n        _118 = -_115;\n    }\n    return _118;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    vec4 base_t = texture(fa_tex_fa_smp, i.uv);\n    float param = fa_mesh_fs_params[6].w;\n    float param_1 = 1.0;\n    vec3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    vec3 _264 = fa_tex_fix(param_2, param_3);\n    vec4 _771 = base_t;\n    _771.x = _264.x;\n    _771.y = _264.y;\n    _771.z = _264.z;\n    base_t = _771;\n    vec4 _280 = (_771 * fa_mesh_fs_params[2]) * i.vertex_color;\n    vec3 _734 = i.world_normal;\n    if (fa_mesh_fs_params[6].z > 0.5)\n    {\n        float param_4 = fa_mesh_fs_params[6].w;\n        float param_5 = 16.0;\n        vec3 param_6 = texture(fa_normal_tex_fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        vec3 _313 = fa_tex_fix(param_6, param_7);\n        vec3 _317 = (_313 * 2.0) - vec3(1.0);\n        vec2 _322 = _317.xy * fa_mesh_fs_params[6].x;\n        vec3 _779 = _317;\n        _779.x = _322.x;\n        _779.y = _322.y;\n        SurfaceInput param_8 = i;\n        vec3 param_9 = _779;\n        _734 = fa_tangent_normal(param_8, param_9);\n    }\n    vec4 mrt = texture(fa_mr_tex_fa_smp, i.uv);\n    float param_10 = fa_mesh_fs_params[6].w;\n    float param_11 = 64.0;\n    vec3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    vec3 _351 = fa_tex_fix(param_12, param_13);\n    vec4 _782 = mrt;\n    _782.x = _351.x;\n    _782.y = _351.y;\n    _782.z = _351.z;\n    mrt = _782;\n    vec4 _381 = texture(fa_occlusion_tex_fa_smp, i.uv);\n    float param_14 = fa_mesh_fs_params[6].w;\n    float param_15 = 256.0;\n    vec3 param_16 = _381.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    vec3 _393 = fa_tex_fix(param_16, param_17);\n    float param_18 = fa_mesh_fs_params[6].w;\n    float param_19 = 4.0;\n    vec3 param_20 = texture(fa_emissive_tex_fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    vec3 _423 = fa_tex_fix(param_20, param_21);\n    float _739 = fa_mesh_fs_params[20].x;\n    float _740 = fa_mesh_fs_params[20].y;\n    float _743 = fa_mesh_fs_params[20].z;\n    float _742 = fa_mesh_fs_params[21].w;\n    float _745 = fa_mesh_fs_params[22].x;\n    if (fa_mesh_fs_params[22].z > 0.5)\n    {\n        if (mod(fa_mesh_fs_params[22].z, 2.0) > 0.5)\n        {\n            _739 *= _393.y;\n            _740 *= _393.z;\n            _742 *= _381.w;\n        }\n        if (fa_mesh_fs_params[22].z > 1.5)\n        {\n            _743 *= mrt.x;\n            _745 *= mrt.w;\n        }\n    }\n    return Surface(_280.xyz, _280.w, _734, clamp(fa_mesh_fs_params[5].x * _351.z, 0.0, 1.0), clamp(fa_mesh_fs_params[5].y * _351.y, 0.0500000007450580596923828125, 1.0), 1.0 + (fa_mesh_fs_params[6].y * (_393.x - 1.0)), fa_mesh_fs_params[3].xyz + (fa_mesh_fs_params[4].xyz * _423), _739, _740, fa_mesh_fs_params[21].xyz, _742, _743, fa_mesh_fs_params[20].w, _745, fa_mesh_fs_params[22].y, fa_mesh_fs_params[23].xyz);\n}\n\nvoid surface(SurfaceInput i, inout Surface s)\n{\n    s.emission += ((tint.xyz * tint.w) * fa_material[0].x);\n}\n\nvoid main()\n{\n    fa_inst_load();\n    vec3 _645 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _645 = -_645;\n    }\n    vec3 _556 = normalize(fa_mesh_fs_params[0].xyz - fa_world_pos);\n    SurfaceInput param = SurfaceInput(fa_world_pos, _645, fa_world_tangent, fa_uv, fa_vertex_color, _556, gl_FrontFacing);\n    SurfaceInput param_1 = SurfaceInput(fa_world_pos, _645, fa_world_tangent, fa_uv, fa_vertex_color, _556, gl_FrontFacing);\n    Surface param_2 = fa_standard_surface(param);\n    surface(param_1, param_2);\n    vec3 _571 = normalize(param_2.normal);\n    vec3 _586 = normalize(vec3(dot(fa_pre_r0, _571), dot(fa_pre_r1, _571), dot(fa_pre_r2, _571)));\n    float _598 = _586.z;\n    vec2 e = _586.xy / vec2((abs(_586.x) + abs(_586.y)) + abs(_598));\n    if (_598 < 0.0)\n    {\n        e = (vec2(1.0) - abs(e.yx)) * vec2((e.x >= 0.0) ? 1.0 : (-1.0), (e.y >= 0.0) ? 1.0 : (-1.0));\n    }\n    fa_frag_color = vec4(min(fa_pre_depth, 60000.0), e, 1.0);\n}\n\n",
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
