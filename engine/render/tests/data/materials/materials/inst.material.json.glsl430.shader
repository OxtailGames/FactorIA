{
  "format": "factoria.shader/1",
  "engine": "0.32.0",
  "template": "4155841b00106f1351e36fe7e96d502ece90660dd797ea3c7df876d511a0f129",
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
      "fs": "#version 430\n\nstruct SurfaceInput\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 vertex_color;\n    vec3 view_dir;\n    bool front_facing;\n};\n\nstruct LightSample\n{\n    vec3 direction;\n    vec3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct Surface\n{\n    vec3 albedo;\n    float alpha;\n    vec3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    vec3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    vec3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    vec3 specular_color;\n    float transmission;\n    float thickness;\n    vec3 attenuation_color;\n    float attenuation_distance;\n};\n\nstruct FaLayers\n{\n    bool on;\n    float f90;\n    float keep;\n    float base_scale;\n    float coat;\n    float coat_rough;\n    float coat_alpha;\n    float coat_a2;\n    vec3 nc;\n    float coat_ndv;\n    bool sheen_on;\n    vec3 sheen;\n    float sheen_rough;\n    float sheen_alpha;\n    float sheen_scale;\n    float sheen_e;\n    float aniso;\n    vec3 t;\n    vec3 b;\n    float at;\n    float ab;\n};\n\nconst float _3698[63] = float[](1.0, 1.0, 1.0, 0.4790000021457672119140625, 0.11699999868869781494140625, 0.01200000010430812835693359375, 0.0, 0.0, 0.0, 1.0, 1.0, 1.0, 0.578000009059906005859375, 0.19300000369548797607421875, 0.0350000001490116119384765625, 0.0030000000260770320892333984375, 0.0, 0.0, 1.0, 1.0, 1.0, 0.6740000247955322265625, 0.3459999859333038330078125, 0.1319999992847442626953125, 0.032999999821186065673828125, 0.0040000001899898052215576171875, 0.0, 0.971000015735626220703125, 0.954999983310699462890625, 0.828999996185302734375, 0.63999998569488525390625, 0.42599999904632568359375, 0.24500000476837158203125, 0.115000002086162567138671875, 0.037000000476837158203125, 0.0030000000260770320892333984375, 0.7469999790191650390625, 0.737999975681304931640625, 0.670000016689300537109375, 0.563000023365020751953125, 0.4309999942779541015625, 0.3039999902248382568359375, 0.1940000057220458984375, 0.1019999980926513671875, 0.0309999994933605194091796875, 0.614000022411346435546875, 0.609000027179718017578125, 0.566999971866607666015625, 0.499000012874603271484375, 0.412000000476837158203125, 0.32400000095367431640625, 0.240999996662139892578125, 0.162000000476837158203125, 0.087999999523162841796875, 0.538999974727630615234375, 0.535000026226043701171875, 0.505999982357025146484375, 0.4569999873638153076171875, 0.393999993801116943359375, 0.328999996185302734375, 0.2660000026226043701171875, 0.203999996185302734375, 0.14200000464916229248046875);\n\nuniform vec4 fa_mesh_fs_params[41];\nuniform vec4 fa_shadows[30];\nuniform vec4 fa_material[1];\nlayout(binding = 0) uniform sampler2D fa_light_tex_fa_shadow_smp;\nlayout(binding = 1) uniform sampler2D fa_tex_fa_smp;\nlayout(binding = 2) uniform sampler2D fa_normal_tex_fa_smp;\nlayout(binding = 3) uniform sampler2D fa_mr_tex_fa_smp;\nlayout(binding = 4) uniform sampler2D fa_occlusion_tex_fa_smp;\nlayout(binding = 5) uniform sampler2D fa_emissive_tex_fa_smp;\nlayout(binding = 6) uniform sampler2D fa_decal_tex_fa_env_smp;\nlayout(binding = 7) uniform sampler2D fa_lightmap_fa_env_smp;\nlayout(binding = 8) uniform samplerCube fa_env_tex_fa_env_smp;\nlayout(binding = 9) uniform sampler2D fa_light_atlas_fa_env_smp;\nlayout(binding = 10) uniform sampler2D fa_shadow_tex_fa_shadow_smp;\nlayout(binding = 11) uniform sampler2D fa_screen_tex_fa_shadow_smp;\n\nlayout(location = 2) in vec3 fa_world_pos;\nlayout(location = 7) in vec3 fa_lm;\nlayout(location = 0) flat in vec4 fa_inst_v0;\nlayout(location = 1) flat in vec4 fa_inst_v1;\nlayout(location = 3) in vec3 fa_world_normal;\nlayout(location = 4) in vec4 fa_world_tangent;\nlayout(location = 5) in vec2 fa_uv;\nlayout(location = 6) in vec4 fa_vertex_color;\nlayout(location = 0) out vec4 fa_frag_color;\nvec3 fa_light_tint;\nbool fa_light_is_area;\nint fa_cl_ndir;\nint fa_cl_slot;\nint fa_cl_local;\nfloat raise;\nvec4 tint;\n\nvoid fa_instance_unpack(vec4 fa_d0, vec4 fa_d1, vec4 fa_d2)\n{\n    raise = fa_d0.x;\n    tint = fa_d1;\n}\n\nvoid fa_inst_load()\n{\n    vec4 param = fa_inst_v0;\n    vec4 param_1 = fa_inst_v1;\n    vec4 param_2 = vec4(0.0);\n    fa_instance_unpack(param, param_1, param_2);\n}\n\nvec4 fa_light_texel(int t)\n{\n    return texelFetch(fa_light_tex_fa_shadow_smp, ivec2(t & 1023, t >> 10), 0);\n}\n\nvec4 fa_cluster_texel(vec3 world_pos)\n{\n    bool _1539 = fa_mesh_fs_params[19].x < 0.0;\n    bool _1546;\n    if (!_1539)\n    {\n        _1546 = fa_mesh_fs_params[19].w < 1.0;\n    }\n    else\n    {\n        _1546 = _1539;\n    }\n    bool _1554;\n    if (!_1546)\n    {\n        _1554 = fa_mesh_fs_params[18].x < 1.0;\n    }\n    else\n    {\n        _1554 = _1546;\n    }\n    bool _1561;\n    if (!_1554)\n    {\n        _1561 = fa_mesh_fs_params[18].y < 1.0;\n    }\n    else\n    {\n        _1561 = _1554;\n    }\n    bool _1568;\n    if (!_1561)\n    {\n        _1568 = fa_mesh_fs_params[19].y < 1.0;\n    }\n    else\n    {\n        _1568 = _1561;\n    }\n    if (_1568)\n    {\n        return vec4(0.0);\n    }\n    vec4 _1578 = vec4(world_pos, 1.0);\n    float _1584 = dot(fa_mesh_fs_params[16], _1578);\n    if (!(_1584 > 9.9999999747524270787835121154785e-07))\n    {\n        return vec4(0.0);\n    }\n    vec2 _1606 = vec2(dot(fa_mesh_fs_params[14], _1578), dot(fa_mesh_fs_params[15], _1578)) / vec2(_1584);\n    int _1610 = int(fa_mesh_fs_params[18].x);\n    int _1614 = int(fa_mesh_fs_params[18].y);\n    int param = (int(fa_mesh_fs_params[19].x) + (((clamp(int(floor(log2(max(dot(fa_mesh_fs_params[17].xyz, world_pos) + fa_mesh_fs_params[17].w, fa_mesh_fs_params[18].w) / fa_mesh_fs_params[18].w) * fa_mesh_fs_params[18].z)), 0, int(fa_mesh_fs_params[19].y) - 1) * _1614) + clamp(int(floor(((_1606.y * 0.5) + 0.5) * fa_mesh_fs_params[18].y)), 0, _1614 - 1)) * _1610)) + clamp(int(floor(((_1606.x * 0.5) + 0.5) * fa_mesh_fs_params[18].x)), 0, _1610 - 1);\n    return fa_light_texel(param);\n}\n\nivec2 fa_cluster_lookup(vec3 world_pos)\n{\n    vec3 param = world_pos;\n    vec4 _1690 = fa_cluster_texel(param);\n    return ivec2(int(_1690.x), int(_1690.y));\n}\n\nvoid fa_cluster_begin(vec3 world_pos)\n{\n    fa_cl_ndir = int(fa_mesh_fs_params[19].z);\n    vec3 param = world_pos;\n    ivec2 _5159 = fa_cluster_lookup(param);\n    fa_cl_slot = _5159.x;\n    fa_cl_local = _5159.y;\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nvec3 fa_linear_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_tex_fix(inout vec3 c, float mode)\n{\n    if (mode > 1.5)\n    {\n        vec3 param = c;\n        vec3 _6322 = fa_linear_to_srgb(param);\n        c = _6322;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            vec3 param_1 = c;\n            vec3 _6330 = fa_srgb_to_linear(param_1);\n            c = _6330;\n        }\n    }\n    return c;\n}\n\nvec3 fa_tangent_normal(SurfaceInput i, vec3 m)\n{\n    vec3 _483;\n    if (i.front_facing)\n    {\n        _483 = i.world_normal;\n    }\n    else\n    {\n        _483 = -i.world_normal;\n    }\n    vec3 _507 = normalize(i.world_tangent.xyz - (_483 * dot(_483, i.world_tangent.xyz)));\n    vec3 _534 = normalize(((_507 * m.x) + ((cross(_483, _507) * i.world_tangent.w) * m.y)) + (_483 * m.z));\n    vec3 _537;\n    if (i.front_facing)\n    {\n        _537 = _534;\n    }\n    else\n    {\n        _537 = -_534;\n    }\n    return _537;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    vec4 base_t = texture(fa_tex_fa_smp, i.uv);\n    float param = fa_mesh_fs_params[6].w;\n    float param_1 = 1.0;\n    vec3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    vec3 _6361 = fa_tex_fix(param_2, param_3);\n    vec4 _7959 = base_t;\n    _7959.x = _6361.x;\n    _7959.y = _6361.y;\n    _7959.z = _6361.z;\n    base_t = _7959;\n    vec4 _6375 = (_7959 * fa_mesh_fs_params[2]) * i.vertex_color;\n    vec3 _7768 = i.world_normal;\n    if (fa_mesh_fs_params[6].z > 0.5)\n    {\n        float param_4 = fa_mesh_fs_params[6].w;\n        float param_5 = 16.0;\n        vec3 param_6 = texture(fa_normal_tex_fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        vec3 _6407 = fa_tex_fix(param_6, param_7);\n        vec3 _6410 = (_6407 * 2.0) - vec3(1.0);\n        vec2 _6415 = _6410.xy * fa_mesh_fs_params[6].x;\n        vec3 _7967 = _6410;\n        _7967.x = _6415.x;\n        _7967.y = _6415.y;\n        SurfaceInput param_8 = i;\n        vec3 param_9 = _7967;\n        _7768 = fa_tangent_normal(param_8, param_9);\n    }\n    vec4 mrt = texture(fa_mr_tex_fa_smp, i.uv);\n    float param_10 = fa_mesh_fs_params[6].w;\n    float param_11 = 64.0;\n    vec3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    vec3 _6443 = fa_tex_fix(param_12, param_13);\n    vec4 _7970 = mrt;\n    _7970.x = _6443.x;\n    _7970.y = _6443.y;\n    _7970.z = _6443.z;\n    mrt = _7970;\n    vec4 _6471 = texture(fa_occlusion_tex_fa_smp, i.uv);\n    float param_14 = fa_mesh_fs_params[6].w;\n    float param_15 = 256.0;\n    vec3 param_16 = _6471.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    vec3 _6482 = fa_tex_fix(param_16, param_17);\n    float param_18 = fa_mesh_fs_params[6].w;\n    float param_19 = 4.0;\n    vec3 param_20 = texture(fa_emissive_tex_fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    vec3 _6512 = fa_tex_fix(param_20, param_21);\n    float _7773 = fa_mesh_fs_params[20].x;\n    float _7774 = fa_mesh_fs_params[20].y;\n    float _7777 = fa_mesh_fs_params[20].z;\n    float _7776 = fa_mesh_fs_params[21].w;\n    float _7779 = fa_mesh_fs_params[22].x;\n    if (fa_mesh_fs_params[22].z > 0.5)\n    {\n        if (mod(fa_mesh_fs_params[22].z, 2.0) > 0.5)\n        {\n            _7773 *= _6482.y;\n            _7774 *= _6482.z;\n            _7776 *= _6471.w;\n        }\n        if (fa_mesh_fs_params[22].z > 1.5)\n        {\n            _7777 *= mrt.x;\n            _7779 *= mrt.w;\n        }\n    }\n    return Surface(_6375.xyz, _6375.w, _7768, clamp(fa_mesh_fs_params[5].x * _6443.z, 0.0, 1.0), clamp(fa_mesh_fs_params[5].y * _6443.y, 0.0500000007450580596923828125, 1.0), 1.0 + (fa_mesh_fs_params[6].y * (_6482.x - 1.0)), fa_mesh_fs_params[3].xyz + (fa_mesh_fs_params[4].xyz * _6512), _7773, _7774, fa_mesh_fs_params[21].xyz, _7776, _7777, fa_mesh_fs_params[20].w, _7779, fa_mesh_fs_params[22].y, fa_mesh_fs_params[23].xyz, fa_mesh_fs_params[30].x, fa_mesh_fs_params[30].y, fa_mesh_fs_params[31].xyz, fa_mesh_fs_params[30].z);\n}\n\nvoid surface(SurfaceInput i, inout Surface s)\n{\n    s.emission += ((tint.xyz * tint.w) * fa_material[0].x);\n}\n\nvec4 fa_decal_tile(vec4 rect, vec2 uv, vec2 atlas, vec2 ddx, vec2 ddy)\n{\n    vec2 _1770 = rect.zw - rect.xy;\n    vec2 _1774 = _1770 * atlas;\n    vec2 _1778 = ddx * _1774;\n    vec2 _1782 = ddy * _1774;\n    return textureLod(fa_decal_tex_fa_env_smp, rect.xy + (clamp(uv, vec2(0.0), vec2(1.0)) * _1770), clamp(0.5 * log2(max(max(dot(_1778, _1778), dot(_1782, _1782)), 9.9999999392252902907785028219223e-09)), 0.0, 4.0));\n}\n\nvec3 fa_dc_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_dc_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvoid fa_apply_decals(vec3 world_pos, vec3 geo_normal, inout vec3 albedo, inout vec3 normal)\n{\n    bool _1815 = fa_mesh_fs_params[10].y < 0.5;\n    bool _1822;\n    if (!_1815)\n    {\n        _1822 = fa_mesh_fs_params[10].w < 0.5;\n    }\n    else\n    {\n        _1822 = _1815;\n    }\n    if (_1822)\n    {\n        return;\n    }\n    vec3 _1828 = dFdx(world_pos);\n    vec3 _1831 = dFdy(world_pos);\n    vec3 param = world_pos;\n    vec4 _1835 = fa_cluster_texel(param);\n    int _1839 = int(_1835.w);\n    if (_1839 < 1)\n    {\n        return;\n    }\n    int _1849 = int(fa_mesh_fs_params[10].y + 0.5);\n    int param_1 = _1849;\n    vec4 _1853 = fa_light_texel(param_1);\n    vec2 _1856 = _1853.yz;\n    int _1860 = int(_1853.w);\n    int param_2 = _1849 + 1;\n    vec4 _1865 = fa_light_texel(param_2);\n    float _1866 = _1865.x;\n    int _1872 = int(fa_mesh_fs_params[10].w + 0.5) - 1;\n    int _1876 = int(_1835.z);\n    vec3 _2141;\n    for (int k = 0; k < _1839; k++)\n    {\n        int _1889 = _1876 + k;\n        int param_3 = _1860 + (_1889 >> 2);\n        int _1906 = (_1849 + 2) + (int(fa_light_texel(param_3)[_1889 & 3]) * 7);\n        int param_4 = _1906 + 6;\n        vec4 _1911 = fa_light_texel(param_4);\n        if (((int(_1911.w + 0.5) >> _1872) & 1) == 0)\n        {\n            continue;\n        }\n        int param_5 = _1906;\n        vec4 _1926 = fa_light_texel(param_5);\n        int param_6 = _1906 + 1;\n        vec4 _1931 = fa_light_texel(param_6);\n        int param_7 = _1906 + 2;\n        vec4 _1936 = fa_light_texel(param_7);\n        vec3 _1939 = _1926.xyz;\n        float _1944 = dot(_1939, world_pos) + _1926.w;\n        vec3 _1946 = _1931.xyz;\n        float _1951 = dot(_1946, world_pos) + _1931.w;\n        vec3 _1953 = _1936.xyz;\n        float _1958 = dot(_1953, world_pos) + _1936.w;\n        bool _1963 = abs(_1944) > 0.5;\n        bool _1971;\n        if (!_1963)\n        {\n            _1971 = abs(_1951) > 0.5;\n        }\n        else\n        {\n            _1971 = _1963;\n        }\n        bool _1979;\n        if (!_1971)\n        {\n            _1979 = abs(_1958) > 0.5;\n        }\n        else\n        {\n            _1979 = _1971;\n        }\n        if (_1979)\n        {\n            continue;\n        }\n        float _1994 = clamp(dot(geo_normal, normalize(_1953)) * _1911.z, 0.0, 1.0);\n        if (_1994 <= 0.0)\n        {\n            continue;\n        }\n        float _2014 = (clamp((0.5 - abs(_1958)) * 10.0, 0.0, 1.0) * _1994) * _1911.x;\n        vec2 _2022 = vec2(_1944 + 0.5, 0.5 - _1951);\n        vec2 _2032 = vec2(dot(_1939, _1828), dot(_1946, _1828));\n        vec2 _2042 = vec2(dot(_1939, _1831), dot(_1946, _1831));\n        int param_8 = _1906 + 5;\n        vec4 _2047 = fa_light_texel(param_8);\n        int param_9 = _1906 + 3;\n        vec4 _2052 = fa_light_texel(param_9);\n        int param_10 = _1906 + 4;\n        vec4 _2057 = fa_light_texel(param_10);\n        float tex_a = 1.0;\n        vec3 col = _2047.xyz;\n        bool _2067 = _2052.z > _2052.x;\n        if (_2067)\n        {\n            vec4 param_11 = _2052;\n            vec2 param_12 = _2022;\n            vec2 param_13 = _1856;\n            vec2 param_14 = _2032;\n            vec2 param_15 = _2042;\n            vec4 tx = fa_decal_tile(param_11, param_12, param_13, param_14, param_15);\n            if ((_1866 > 0.5) && (_1866 < 1.5))\n            {\n                vec3 param_16 = tx.xyz;\n                vec3 _2093 = fa_dc_to_linear(param_16);\n                vec4 _7856 = tx;\n                _7856.x = _2093.x;\n                _7856.y = _2093.y;\n                _7856.z = _2093.z;\n                tx = _7856;\n            }\n            col *= tx.xyz;\n            tex_a = tx.w;\n        }\n        albedo = mix(albedo, col, vec3(clamp((_2014 * tex_a) * _2047.w, 0.0, 1.0)));\n        if (_2057.z > _2057.x)\n        {\n            vec4 param_17 = _2057;\n            vec2 param_18 = _2022;\n            vec2 param_19 = _1856;\n            vec2 param_20 = _2032;\n            vec2 param_21 = _2042;\n            vec4 _2137 = fa_decal_tile(param_17, param_18, param_19, param_20, param_21);\n            if (_1866 > 1.5)\n            {\n                vec3 param_22 = _2137.xyz;\n                vec3 _2147 = fa_dc_to_srgb(param_22);\n                _2141 = _2147;\n            }\n            else\n            {\n                _2141 = _2137.xyz;\n            }\n            vec3 _2156 = (_2141 * 2.0) - vec3(1.0);\n            vec2 _2161 = _2156.xy * _1911.y;\n            vec3 _2183 = (normalize(_1939) * _2161.x) + (normalize(_1946) * _2161.y);\n            vec3 _2186 = normalize(normal);\n            normal = normalize(mix(_2186, normalize((_2186 * max(_2156.z, 0.0500000007450580596923828125)) + (_2183 - (_2186 * dot(_2186, _2183)))), vec3(clamp(_2014 * (_2067 ? tex_a : 1.0), 0.0, 1.0))));\n        }\n    }\n}\n\nfloat fa_sheen_albedo(float ndv, float rough)\n{\n    float _3624 = min(sqrt(max(rough - 0.100000001490116119384765625, 0.0) * 1.111111164093017578125) * 6.0, 5.999000072479248046875);\n    float _3631 = min(sqrt(clamp(ndv, 0.0, 1.0)) * 8.0, 7.999000072479248046875);\n    int _3634 = int(_3624);\n    int _3637 = int(_3631);\n    float _3647 = _3631 - float(_3637);\n    int _3702 = (_3634 * 9) + _3637;\n    int _3722 = ((_3634 + 1) * 9) + _3637;\n    return mix(mix(_3698[_3702], _3698[_3702 + 1], _3647), mix(_3698[_3722], _3698[_3722 + 1], _3647), _3624 - float(_3634));\n}\n\nFaLayers fa_layers_setup(SurfaceInput i, Surface s, vec3 n, vec3 v, float metallic, float roughness, inout vec3 f0)\n{\n    bool _7691 = false;\n    float _7692 = 1.0;\n    float _7693 = 1.0;\n    float _7694 = 1.0;\n    float _7695 = 0.0;\n    float _7696 = 0.0;\n    float _7697 = 0.0;\n    float _7698 = 0.0;\n    float _7700 = 1.0;\n    bool _7701 = false;\n    vec3 _7702 = vec3(0.0);\n    float _7703 = 1.0;\n    float _7704 = 1.0;\n    float _7705 = 1.0;\n    float _7706 = 0.0;\n    float _7707 = 0.0;\n    vec3 _7708 = vec3(1.0, 0.0, 0.0);\n    vec3 _7709 = vec3(0.0, 0.0, 1.0);\n    float _7710 = 1.0;\n    float _7711 = 1.0;\n    float _3773 = clamp(s.specular, 0.0, 1.0);\n    float _3777 = clamp(s.ior, 1.0, 3.0);\n    bool _3782 = (_3773 != 1.0) || (_3777 != 1.5);\n    bool _3791;\n    if (!_3782)\n    {\n        _3791 = any(notEqual(s.specular_color, vec3(1.0)));\n    }\n    else\n    {\n        _3791 = _3782;\n    }\n    if (_3791)\n    {\n        float _3799 = (_3777 - 1.0) / (_3777 + 1.0);\n        f0 = mix(min(vec3(_3799 * _3799) * max(s.specular_color, vec3(0.0)), vec3(1.0)) * _3773, s.albedo, vec3(metallic));\n        _7692 = mix(_3773, 1.0, metallic);\n        _7691 = true;\n    }\n    float _3826 = clamp(s.clearcoat, 0.0, 1.0);\n    if (_3826 > 0.0)\n    {\n        float _3834 = clamp(s.clearcoat_roughness, 0.0500000007450580596923828125, 1.0);\n        _7695 = _3826;\n        _7696 = _3834;\n        float _3841 = _3834 * _3834;\n        _7697 = _3841;\n        _7698 = _3841 * _3841;\n        float _3853 = max(dot(i.world_normal, v), 9.9999997473787516355514526367188e-05);\n        _7700 = _3853;\n        _7693 = 1.0 - (_3826 * (0.039999999105930328369140625 + (0.959999978542327880859375 * pow(clamp(1.0 - _3853, 0.0, 1.0), 5.0))));\n        _7691 = true;\n    }\n    vec3 _3872 = max(s.sheen_color, vec3(0.0));\n    float _3881 = max(_3872.x, max(_3872.y, _3872.z));\n    if (_3881 > 0.0)\n    {\n        float _3889 = clamp(s.sheen_roughness, 0.100000001490116119384765625, 1.0);\n        _7701 = true;\n        _7702 = _3872;\n        _7703 = _3889;\n        _7704 = _3889 * _3889;\n        float param = max(dot(n, v), 9.9999997473787516355514526367188e-05);\n        float param_1 = _3889;\n        float _3906 = fa_sheen_albedo(param, param_1);\n        _7706 = _3906;\n        _7705 = 1.0 - min(_3881 * _3906, 1.0);\n        _7691 = true;\n    }\n    _7694 = _7693 * _7705;\n    float _3925 = clamp(s.anisotropy, -1.0, 1.0);\n    if (_3925 != 0.0)\n    {\n        vec3 _3940 = i.world_tangent.xyz - (n * dot(n, i.world_tangent.xyz));\n        vec3 t = _3940;\n        if (dot(_3940, _3940) < 9.9999999392252902907785028219223e-09)\n        {\n            bvec3 _3952 = bvec3(abs(n.y) < 0.9900000095367431640625);\n            t = cross(vec3(_3952.x ? vec3(0.0, 1.0, 0.0).x : vec3(1.0, 0.0, 0.0).x, _3952.y ? vec3(0.0, 1.0, 0.0).y : vec3(1.0, 0.0, 0.0).y, _3952.z ? vec3(0.0, 1.0, 0.0).z : vec3(1.0, 0.0, 0.0).z), n);\n        }\n        vec3 _3956 = t;\n        vec3 _3957 = normalize(_3956);\n        t = _3957;\n        vec3 _3982 = normalize((_3957 * cos(s.anisotropy_rotation)) + ((cross(n, _3957) * ((i.world_tangent.w < 0.0) ? (-1.0) : 1.0)) * sin(s.anisotropy_rotation)));\n        _7708 = _3982;\n        _7709 = cross(n, _3982);\n        float _3992 = roughness * roughness;\n        float _3998 = mix(_3992, 1.0, _3925 * _3925);\n        bool _4000 = _3925 > 0.0;\n        _7710 = _4000 ? _3998 : _3992;\n        _7711 = _4000 ? _3992 : _3998;\n        _7707 = _3925;\n        _7691 = true;\n    }\n    return FaLayers(_7691, _7692, _7693, _7694, _7695, _7696, _7697, _7698, i.world_normal, _7700, _7701, _7702, _7703, _7704, _7705, _7706, _7707, _7708, _7709, _7710, _7711);\n}\n\nvec3 fa_sky_sh_coef(int k)\n{\n    vec3 v = textureLod(fa_env_tex_fa_env_smp, vec3(1.0, 1.0 - (float((2 * (k >> 2)) + 1) * 0.25), 1.0 - (float((2 * (k & 3)) + 1) * 0.25)), 5.0).xyz;\n    if (fa_mesh_fs_params[11].w > 1.5)\n    {\n        v = (v - vec3(0.5)) * 8.0;\n    }\n    return v;\n}\n\nvec3 fa_sh_eval(vec3 c[9], vec3 n)\n{\n    vec3 _3381 = max((((c[0] * 0.2820948064327239990234375) + (((c[1] * (0.3257350027561187744140625 * n.y)) + (c[2] * (0.3257350027561187744140625 * n.z))) + (c[3] * (0.3257350027561187744140625 * n.x)))) + (((c[4] * ((0.2731371223926544189453125 * n.x) * n.y)) + (c[5] * ((0.2731371223926544189453125 * n.y) * n.z))) + (c[6] * (0.078847892582416534423828125 * (((3.0 * n.z) * n.z) - 1.0))))) + ((c[7] * ((0.2731371223926544189453125 * n.x) * n.z)) + (c[8] * (0.13656856119632720947265625 * ((n.x * n.x) - (n.y * n.y))))), vec3(0.0));\n    return _3381;\n}\n\nvec3 fa_ambient_light(vec3 n)\n{\n    if (fa_mesh_fs_params[11].w > 0.5)\n    {\n        vec3 c[9];\n        for (int k = 0; k < 9; k++)\n        {\n            int param = k;\n            c[k] = fa_sky_sh_coef(param);\n        }\n        vec3 param_1[9] = c;\n        vec3 param_2 = n;\n        return fa_sh_eval(param_1, param_2);\n    }\n    return fa_mesh_fs_params[1].xyz;\n}\n\nvec3 fa_indirect_diffuse(vec3 n)\n{\n    if (fa_lm.z > 0.5)\n    {\n        return textureLod(fa_lightmap_fa_env_smp, fa_lm.xy, 0.0).xyz;\n    }\n    if (fa_mesh_fs_params[32].w > 0.0)\n    {\n        vec3 c[9];\n        for (int k = 0; k < 9; k++)\n        {\n            c[k] = fa_mesh_fs_params[k * 1 + 32].xyz;\n        }\n        vec3 param = n;\n        vec3 param_1[9] = c;\n        vec3 param_2 = n;\n        return mix(fa_ambient_light(param), fa_sh_eval(param_1, param_2), vec3(clamp(fa_mesh_fs_params[32].w, 0.0, 1.0)));\n    }\n    vec3 param_3 = n;\n    return fa_ambient_light(param_3);\n}\n\nint fa_cluster_index(int slot, int n)\n{\n    int param = (int(fa_mesh_fs_params[19].x) + int(fa_mesh_fs_params[19].w)) + ((slot + n) >> 2);\n    vec4 t = fa_light_texel(param);\n    return int(t[(slot + n) & 3]);\n}\n\nint fa_cl_light(int n)\n{\n    if (n < fa_cl_ndir)\n    {\n        return n;\n    }\n    int param = fa_cl_slot;\n    int param_1 = n - fa_cl_ndir;\n    return fa_cluster_index(param, param_1);\n}\n\nint fa_light_base(int li)\n{\n    return li * ((fa_mesh_fs_params[1].w > 4.5) ? 8 : 4);\n}\n\nbool fa_light_baked(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 3;\n    return fa_light_texel(param_1).w > 0.5;\n}\n\nfloat fa_baked_keep(int li)\n{\n    float _5129;\n    if (fa_lm.z > 0.5)\n    {\n        _5129 = 0.0;\n    }\n    else\n    {\n        _5129 = 1.0 - clamp(fa_mesh_fs_params[32].w, 0.0, 1.0);\n    }\n    bool _5140 = _5129 < 1.0;\n    bool _5146;\n    if (_5140)\n    {\n        int param = li;\n        _5146 = fa_light_baked(param);\n    }\n    else\n    {\n        _5146 = _5140;\n    }\n    return _5146 ? _5129 : 1.0;\n}\n\nfloat fa_light_type(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 1;\n    return fa_light_texel(param_1).w;\n}\n\nvec4 fa_atlas_fetch(vec2 texel)\n{\n    return textureLod(fa_light_atlas_fa_env_smp, texel / vec2(textureSize(fa_light_atlas_fa_env_smp, 0)), 0.0);\n}\n\nvec3 fa_cookie_sample(vec2 tile_origin, vec2 uv)\n{\n    vec2 param = (tile_origin + vec2(1.0)) + (clamp(uv, vec2(0.0), vec2(1.0)) * 254.0);\n    return fa_atlas_fetch(param).xyz;\n}\n\nvec3 fa_area_point(vec3 c, vec3 axis, vec3 ru, vec3 uu, float hx, float hy, float shape, vec3 p, vec3 r)\n{\n    bool _788 = dot(r, r) > 0.5;\n    if (shape > 1.5)\n    {\n        vec3 _801 = (c - (ru * hx)) - p;\n        vec3 _807 = ru * (2.0 * hx);\n        float _813 = max(dot(_807, _807), 9.9999999392252902907785028219223e-09);\n        float _817 = dot(_801, _807);\n        float t = clamp((-_817) / _813, 0.0, 1.0);\n        if (_788)\n        {\n            float _832 = dot(r, _807);\n            float _838 = _813 - (_832 * _832);\n            if (abs(_838) > (9.9999997473787516355514526367188e-06 * _813))\n            {\n                t = clamp(((dot(r, _801) * _832) - _817) / _838, 0.0, 1.0);\n            }\n        }\n        return (p + _801) + (_807 * t);\n    }\n    vec3 q = p;\n    float _870 = dot(r, axis);\n    bool _878;\n    if (_788)\n    {\n        _878 = abs(_870) > 9.9999997473787516355514526367188e-05;\n    }\n    else\n    {\n        _878 = _788;\n    }\n    if (_878)\n    {\n        float _888 = dot(c - p, axis) / _870;\n        if (_888 > 0.0)\n        {\n            q = p + (r * _888);\n        }\n    }\n    vec3 _901 = q - c;\n    vec2 xy = vec2(dot(_901, ru), dot(_901, uu));\n    if (shape > 0.5)\n    {\n        float _916 = length(xy);\n        if (_916 > hx)\n        {\n            xy *= (hx / _916);\n        }\n    }\n    else\n    {\n        xy = clamp(xy, vec2(-hx, -hy), vec2(hx, hy));\n    }\n    return (c + (ru * xy.x)) + (uu * xy.y);\n}\n\nint fa_cube_face(vec3 d)\n{\n    vec3 _549 = abs(d);\n    float _551 = _549.x;\n    float _553 = _549.y;\n    bool _554 = _551 >= _553;\n    bool _562;\n    if (_554)\n    {\n        _562 = _551 >= _549.z;\n    }\n    else\n    {\n        _562 = _554;\n    }\n    int _563;\n    if (_562)\n    {\n        _563 = (d.x > 0.0) ? 0 : 1;\n    }\n    else\n    {\n        int _578;\n        if (_553 >= _549.z)\n        {\n            _578 = (d.y > 0.0) ? 2 : 3;\n        }\n        else\n        {\n            _578 = (d.z > 0.0) ? 4 : 5;\n        }\n        _563 = _578;\n    }\n    return _563;\n}\n\nvoid fa_cube_face_basis(int f, out vec3 fwd, out vec3 up)\n{\n    if (f == 0)\n    {\n        fwd = vec3(1.0, 0.0, 0.0);\n        up = vec3(0.0, 1.0, 0.0);\n    }\n    else\n    {\n        if (f == 1)\n        {\n            fwd = vec3(-1.0, 0.0, 0.0);\n            up = vec3(0.0, 1.0, 0.0);\n        }\n        else\n        {\n            if (f == 2)\n            {\n                fwd = vec3(0.0, 1.0, 0.0);\n                up = vec3(0.0, 0.0, 1.0);\n            }\n            else\n            {\n                if (f == 3)\n                {\n                    fwd = vec3(0.0, -1.0, 0.0);\n                    up = vec3(0.0, 0.0, -1.0);\n                }\n                else\n                {\n                    if (f == 4)\n                    {\n                        fwd = vec3(0.0, 0.0, 1.0);\n                        up = vec3(0.0, 1.0, 0.0);\n                    }\n                    else\n                    {\n                        fwd = vec3(0.0, 0.0, -1.0);\n                        up = vec3(0.0, 1.0, 0.0);\n                    }\n                }\n            }\n        }\n    }\n}\n\nfloat fa_ies_sample(vec2 tile_origin, vec3 d, vec3 axis, vec3 right, vec3 up)\n{\n    float _708 = dot(d, right);\n    float _712 = dot(d, up);\n    float _723;\n    if (((_708 * _708) + (_712 * _712)) > 1.0000000133514319600180897396058e-10)\n    {\n        _723 = atan(_712, _708) * 0.15915493667125701904296875;\n    }\n    else\n    {\n        _723 = 0.0;\n    }\n    vec2 param = tile_origin + vec2(1.0 + ((_723 - floor(_723)) * 64.0), 1.0 + (acos(clamp(dot(d, axis), -1.0, 1.0)) * 10.18591594696044921875));\n    return fa_atlas_fetch(param).x;\n}\n\nLightSample fa_light_sample_n(int li, vec3 world_pos, vec3 n)\n{\n    int param = li;\n    int _954 = fa_light_base(param);\n    bool _958 = fa_mesh_fs_params[1].w > 4.5;\n    int param_1 = _954;\n    vec4 _962 = fa_light_texel(param_1);\n    int param_2 = _954 + 1;\n    vec4 _967 = fa_light_texel(param_2);\n    float _970 = _967.w;\n    float atten = 1.0;\n    float dist = 0.0;\n    fa_light_tint = vec3(1.0);\n    bool _982 = _958 && (_970 > 2.5);\n    fa_light_is_area = _982;\n    bool _984 = _970 < 0.5;\n    vec3 l;\n    if (_984)\n    {\n        l = normalize(_962.xyz);\n        if (_958)\n        {\n            int param_3 = _954 + 6;\n            vec4 _998 = fa_light_texel(param_3);\n            if (_998.z > 0.5)\n            {\n                int param_4 = _954 + 4;\n                vec4 _1008 = fa_light_texel(param_4);\n                int param_5 = _954 + 5;\n                vec4 _1013 = fa_light_texel(param_5);\n                vec2 param_6 = _998.xy;\n                vec2 param_7 = fract(vec2(dot(world_pos, _1008.xyz) * _1008.w, (-dot(world_pos, _1013.xyz)) * _1013.w) + vec2(0.5));\n                fa_light_tint = fa_cookie_sample(param_6, param_7);\n            }\n        }\n    }\n    else\n    {\n        vec3 _1043 = _962.xyz;\n        vec3 _1045 = _1043 - world_pos;\n        vec3 to_light = _1045;\n        float _1048 = length(_1045);\n        float reach = _1048;\n        bool front = true;\n        if (_982)\n        {\n            int param_8 = _954 + 7;\n            reach = max(_1048 - fa_light_texel(param_8).w, 0.0);\n            int param_9 = _954 + 4;\n            vec4 _1072 = fa_light_texel(param_9);\n            int param_10 = _954 + 5;\n            vec4 _1077 = fa_light_texel(param_10);\n            int param_11 = _954 + 6;\n            vec4 _1082 = fa_light_texel(param_11);\n            float _1083 = _1082.w;\n            int param_12 = _954 + 2;\n            vec3 _1090 = normalize(fa_light_texel(param_12).xyz);\n            bool _1092 = _1083 > 1.5;\n            bool _1100;\n            if (!_1092)\n            {\n                _1100 = dot(_1090, to_light) < 0.0;\n            }\n            else\n            {\n                _1100 = _1092;\n            }\n            front = _1100;\n            vec3 r = vec3(0.0);\n            vec3 _1109 = fa_mesh_fs_params[0].xyz - world_pos;\n            bool _1113 = dot(n, n) > 0.5;\n            bool _1121;\n            if (_1113)\n            {\n                _1121 = dot(_1109, _1109) > 9.9999999600419720025001879548654e-13;\n            }\n            else\n            {\n                _1121 = _1113;\n            }\n            if (_1121)\n            {\n                r = reflect(-normalize(_1109), normalize(n));\n            }\n            vec3 param_13 = _1043;\n            vec3 param_14 = _1090;\n            vec3 param_15 = _1072.xyz;\n            vec3 param_16 = _1077.xyz;\n            float param_17 = _1072.w;\n            float param_18 = _1077.w;\n            float param_19 = _1083;\n            vec3 param_20 = world_pos;\n            vec3 param_21 = r;\n            to_light = fa_area_point(param_13, param_14, param_15, param_16, param_17, param_18, param_19, param_20, param_21) - world_pos;\n        }\n        float _1157 = length(to_light);\n        dist = _1157;\n        l = to_light / vec3(max(_1157, 9.9999997473787516355514526367188e-05));\n        float _1171 = reach / max(_962.w, 0.001000000047497451305389404296875);\n        float _1177 = clamp(1.0 - (_1171 * _1171), 0.0, 1.0);\n        float _1179;\n        if (front)\n        {\n            _1179 = _1177 * _1177;\n        }\n        else\n        {\n            _1179 = 0.0;\n        }\n        atten = _1179;\n        bool _1190 = _970 < 2.5;\n        if ((_970 > 1.5) && _1190)\n        {\n            int param_22 = _954 + 2;\n            vec4 _1198 = fa_light_texel(param_22);\n            float _1208 = _1198.w;\n            int param_23 = _954 + 3;\n            vec4 _1213 = fa_light_texel(param_23);\n            float _1214 = _1213.x;\n            float cos_inner = _1214;\n            if (_1214 > 1.5)\n            {\n                cos_inner = mix(_1208, 1.0, 0.25);\n            }\n            atten *= smoothstep(_1208, cos_inner, dot(-l, normalize(_1198.xyz)));\n        }\n        if (_958 && (_970 < 1.5))\n        {\n            int param_24 = _954 + 6;\n            vec4 _1238 = fa_light_texel(param_24);\n            if (_1238.z > 0.5)\n            {\n                vec3 _1246 = -to_light;\n                int param_25 = _954 + 4;\n                int param_26 = _954 + 5;\n                vec3 _1260 = fa_light_texel(param_25).xyz;\n                vec3 _1264 = fa_light_texel(param_26).xyz;\n                vec3 _1273 = vec3(dot(_1246, _1260), dot(_1246, _1264), dot(_1246, cross(_1260, _1264)));\n                vec3 param_27 = _1273;\n                int _1277 = fa_cube_face(param_27);\n                int param_28 = _1277;\n                vec3 param_29;\n                vec3 param_30;\n                fa_cube_face_basis(param_28, param_29, param_30);\n                vec2 _1304 = vec2(dot(_1273, cross(param_29, param_30)), dot(_1273, param_30)) / vec2(max(dot(_1273, param_29), 9.9999997473787516355514526367188e-05));\n                int _1308 = _1277 / 3;\n                vec2 param_31 = _1238.xy + (vec2(float(_1277 - (_1308 * 3)), float(_1308)) * 256.0);\n                vec2 param_32 = vec2(0.5 + (0.5 * _1304.x), 0.5 - (0.5 * _1304.y));\n                fa_light_tint = fa_cookie_sample(param_31, param_32);\n            }\n            int param_33 = _954 + 7;\n            vec4 _1338 = fa_light_texel(param_33);\n            if (_1338.z > 0.5)\n            {\n                int param_34 = _954 + 2;\n                int param_35 = _954 + 4;\n                int param_36 = _954 + 5;\n                vec2 param_37 = _1338.xy;\n                vec3 param_38 = -l;\n                vec3 param_39 = normalize(fa_light_texel(param_34).xyz);\n                vec3 param_40 = fa_light_texel(param_35).xyz;\n                vec3 param_41 = fa_light_texel(param_36).xyz;\n                atten *= fa_ies_sample(param_37, param_38, param_39, param_40, param_41);\n            }\n        }\n        else\n        {\n            if (_958 && _1190)\n            {\n                int param_42 = _954 + 6;\n                vec4 _1385 = fa_light_texel(param_42);\n                int param_43 = _954 + 7;\n                vec4 _1390 = fa_light_texel(param_43);\n                bool _1393 = _1385.z > 0.5;\n                bool _1400;\n                if (!_1393)\n                {\n                    _1400 = _1390.z > 0.5;\n                }\n                else\n                {\n                    _1400 = _1393;\n                }\n                if (_1400)\n                {\n                    int param_44 = _954 + 2;\n                    vec4 _1407 = fa_light_texel(param_44);\n                    vec3 _1411 = normalize(_1407.xyz);\n                    int param_45 = _954 + 4;\n                    vec4 _1416 = fa_light_texel(param_45);\n                    int param_46 = _954 + 5;\n                    vec4 _1421 = fa_light_texel(param_46);\n                    if (_1393)\n                    {\n                        vec3 _1429 = -to_light;\n                        float _1436 = _1407.w;\n                        float _1452 = 0.5 / max(dot(_1429, _1411) * (sqrt(max(1.0 - (_1436 * _1436), 0.0)) / max(_1436, 0.001000000047497451305389404296875)), 9.9999997473787516355514526367188e-05);\n                        vec2 param_47 = _1385.xy;\n                        vec2 param_48 = vec2(0.5 + (dot(_1429, _1416.xyz) * _1452), 0.5 - (dot(_1429, _1421.xyz) * _1452));\n                        fa_light_tint = fa_cookie_sample(param_47, param_48);\n                    }\n                    if (_1390.z > 0.5)\n                    {\n                        vec2 param_49 = _1390.xy;\n                        vec3 param_50 = -l;\n                        vec3 param_51 = _1411;\n                        vec3 param_52 = _1416.xyz;\n                        vec3 param_53 = _1421.xyz;\n                        atten *= fa_ies_sample(param_49, param_50, param_51, param_52, param_53);\n                    }\n                }\n            }\n        }\n    }\n    vec3 _7679 = _967.xyz * atten;\n    if (_958)\n    {\n        _7679 *= fa_light_tint;\n    }\n    int _1521;\n    if (_984)\n    {\n        _1521 = 0;\n    }\n    else\n    {\n        _1521 = ((_970 > 1.5) && (_970 < 2.5)) ? 2 : 1;\n    }\n    return LightSample(l, _7679, atten, 1.0, dist, _1521);\n}\n\nfloat fa_shadow_split_at(int i)\n{\n    float _2258;\n    if (i == 0)\n    {\n        _2258 = fa_shadows[24].x;\n    }\n    else\n    {\n        float _2274;\n        if (i == 1)\n        {\n            _2274 = fa_shadows[24].y;\n        }\n        else\n        {\n            float _2282;\n            if (i == 2)\n            {\n                _2282 = fa_shadows[24].z;\n            }\n            else\n            {\n                _2282 = fa_shadows[24].w;\n            }\n            _2274 = _2282;\n        }\n        _2258 = _2274;\n    }\n    return _2258;\n}\n\nfloat fa_shadow_depth(inout vec2 uv, vec4 rect)\n{\n    uv = clamp(uv, rect.xy, rect.zw);\n    return textureLod(fa_shadow_tex_fa_shadow_smp, uv, 0.0).x;\n}\n\nfloat fa_shadow_fetch(vec2 uv, vec4 rect, vec3 conv)\n{\n    vec2 param = uv;\n    vec4 param_1 = rect;\n    float _2315 = fa_shadow_depth(param, param_1);\n    float _2319;\n    if (conv.x < 0.5)\n    {\n        _2319 = _2315;\n    }\n    else\n    {\n        _2319 = (conv.y * conv.z) / (conv.z - (_2315 * (conv.z - conv.y)));\n    }\n    return _2319;\n}\n\nfloat fa_shadow_noise()\n{\n    return fract(52.98291778564453125 * fract(dot(gl_FragCoord.xy, vec2(0.067110560834407806396484375, 0.005837149918079376220703125))));\n}\n\nvec2 fa_shadow_vogel(int k, int n, float phi)\n{\n    float _2246 = (float(k) * 2.3999631404876708984375) + phi;\n    return vec2(cos(_2246), sin(_2246)) * sqrt((float(k) + 0.5) / float(n));\n}\n\nfloat fa_shadow_filter(vec2 uv, vec4 rect, float zr, float texel_m, float unit, float reach, float plane, vec3 conv, int mode, float k)\n{\n    if (mode == 1)\n    {\n        vec2 param = uv;\n        vec4 param_1 = rect;\n        vec3 param_2 = conv;\n        return float(zr <= fa_shadow_fetch(param, param_1, param_2));\n    }\n    float _2365 = fa_shadow_noise() * 6.283185482025146484375;\n    float radius = 1.5;\n    if (mode == 2)\n    {\n        float _2374;\n        if (k < 0.0)\n        {\n            _2374 = (-k) / max(zr, 0.100000001490116119384765625);\n        }\n        else\n        {\n            _2374 = k;\n        }\n        float _2394 = clamp((_2374 * reach) / texel_m, 3.0, 12.0);\n        float sum = 0.0;\n        float cnt = 0.0;\n        for (int i = 0; i < 16; i++)\n        {\n            int param_3 = i;\n            int param_4 = 16;\n            float param_5 = _2365;\n            vec2 _2413 = fa_shadow_vogel(param_3, param_4, param_5) * _2394;\n            vec2 param_6 = uv + (_2413 * fa_shadows[26].zw);\n            vec4 param_7 = rect;\n            vec3 param_8 = conv;\n            float _2425 = fa_shadow_fetch(param_6, param_7, param_8);\n            if (_2425 < (zr - (length(_2413) * plane)))\n            {\n                sum += _2425;\n                cnt += 1.0;\n            }\n        }\n        if (cnt < 0.5)\n        {\n            return 1.0;\n        }\n        float _2451 = sum / cnt;\n        float _2461;\n        if (k < 0.0)\n        {\n            _2461 = (-k) / max(_2451, 0.0500000007450580596923828125);\n        }\n        else\n        {\n            _2461 = k;\n        }\n        radius = clamp(((max(zr - _2451, 0.0) * unit) * _2461) / texel_m, 1.5, 16.0);\n    }\n    float lit = 0.0;\n    int _2483 = (mode == 2) ? 24 : 16;\n    for (int i_1 = 0; i_1 < _2483; i_1++)\n    {\n        int param_9 = i_1;\n        int param_10 = _2483;\n        float param_11 = _2365;\n        vec2 _2502 = fa_shadow_vogel(param_9, param_10, param_11) * radius;\n        vec2 param_12 = uv + (_2502 * fa_shadows[26].zw);\n        vec4 param_13 = rect;\n        vec3 param_14 = conv;\n        lit += float((zr - (length(_2502) * plane)) <= fa_shadow_fetch(param_12, param_13, param_14));\n    }\n    return lit / float(_2483);\n}\n\nfloat fa_shadow_cascade(int ci, vec3 world, vec3 n, vec3 l)\n{\n    float _2544 = max(fa_shadows[ci * 1 + 20].y, 0.001000000047497451305389404296875);\n    float _2549 = clamp(dot(n, l), 0.0, 1.0);\n    float _2555 = sqrt(1.0 - (_2549 * _2549));\n    float _2562 = min(_2555 / max(_2549, 0.20000000298023223876953125), 4.0);\n    float _2567;\n    if (fa_shadows[26].y > 0.0)\n    {\n        _2567 = fa_shadows[26].y;\n    }\n    else\n    {\n        _2567 = 1.5 * fa_shadows[ci * 1 + 20].x;\n    }\n    vec4 _2592 = mat4(fa_shadows[ci * 4 + 0], fa_shadows[ci * 4 + 1], fa_shadows[ci * 4 + 2], fa_shadows[ci * 4 + 3]) * vec4(world + (n * (_2567 * _2555)), 1.0);\n    float _2599 = _2592.x;\n    bool _2602 = _2599 < fa_shadows[ci * 1 + 16].x;\n    bool _2611;\n    if (!_2602)\n    {\n        _2611 = _2599 > fa_shadows[ci * 1 + 16].z;\n    }\n    else\n    {\n        _2611 = _2602;\n    }\n    bool _2620;\n    if (!_2611)\n    {\n        _2620 = _2592.y < fa_shadows[ci * 1 + 16].y;\n    }\n    else\n    {\n        _2620 = _2611;\n    }\n    bool _2629;\n    if (!_2620)\n    {\n        _2629 = _2592.y > fa_shadows[ci * 1 + 16].w;\n    }\n    else\n    {\n        _2629 = _2620;\n    }\n    bool _2636;\n    if (!_2629)\n    {\n        _2636 = _2592.z > 1.0;\n    }\n    else\n    {\n        _2636 = _2629;\n    }\n    if (_2636)\n    {\n        return -1.0;\n    }\n    float _2644;\n    if (fa_shadows[26].x > 0.0)\n    {\n        _2644 = fa_shadows[26].x;\n    }\n    else\n    {\n        _2644 = 1.5 * fa_shadows[ci * 1 + 20].x;\n    }\n    vec2 param = _2592.xy;\n    vec4 param_1 = fa_shadows[ci * 1 + 16];\n    float param_2 = _2592.z - ((_2644 * (1.0 + (0.5 * _2562))) / _2544);\n    float param_3 = fa_shadows[ci * 1 + 20].x;\n    float param_4 = _2544;\n    float param_5 = _2544 * 0.25;\n    float param_6 = ((fa_shadows[ci * 1 + 20].x * min(_2562, 3.0)) * 0.5) / _2544;\n    vec3 param_7 = vec3(0.0);\n    int param_8 = int(fa_shadows[25].z + 0.5);\n    float param_9 = fa_shadows[25].w;\n    return fa_shadow_filter(param, param_1, param_2, param_3, param_4, param_5, param_6, param_7, param_8, param_9);\n}\n\nfloat fa_shadow_sun(vec3 world, vec3 n, vec3 l)\n{\n    if (fa_mesh_fs_params[5].z < 0.5)\n    {\n        return 1.0;\n    }\n    int _3022 = int(fa_shadows[25].x + 0.5);\n    if (_3022 < 1)\n    {\n        return 1.0;\n    }\n    float _3037 = dot(world - fa_shadows[27].xyz, fa_shadows[28].xyz);\n    int param = _3022 - 1;\n    if (_3037 > fa_shadow_split_at(param))\n    {\n        return 1.0;\n    }\n    int ci = 0;\n    bool _3049 = _3022 > 1;\n    bool _3056;\n    if (_3049)\n    {\n        _3056 = _3037 > fa_shadows[24].x;\n    }\n    else\n    {\n        _3056 = _3049;\n    }\n    if (_3056)\n    {\n        ci = 1;\n    }\n    bool _3060 = _3022 > 2;\n    bool _3067;\n    if (_3060)\n    {\n        _3067 = _3037 > fa_shadows[24].y;\n    }\n    else\n    {\n        _3067 = _3060;\n    }\n    if (_3067)\n    {\n        ci = 2;\n    }\n    bool _3071 = _3022 > 3;\n    bool _3078;\n    if (_3071)\n    {\n        _3078 = _3037 > fa_shadows[24].z;\n    }\n    else\n    {\n        _3078 = _3071;\n    }\n    if (_3078)\n    {\n        ci = 3;\n    }\n    float s = -1.0;\n    for (int k = 0; k < 4; k++)\n    {\n        if (ci >= _3022)\n        {\n            break;\n        }\n        int param_1 = ci;\n        vec3 param_2 = world;\n        vec3 param_3 = n;\n        vec3 param_4 = l;\n        float _3104 = fa_shadow_cascade(param_1, param_2, param_3, param_4);\n        s = _3104;\n        if (_3104 >= 0.0)\n        {\n            break;\n        }\n        ci++;\n    }\n    if (s < 0.0)\n    {\n        return 1.0;\n    }\n    if (fa_shadows[25].y > 0.0)\n    {\n        float _3129;\n        if (ci > 0)\n        {\n            int param_5 = ci - 1;\n            _3129 = fa_shadow_split_at(param_5);\n        }\n        else\n        {\n            _3129 = fa_shadows[28].w;\n        }\n        int param_6 = ci;\n        float _3148 = fa_shadows[25].y * max(fa_shadow_split_at(param_6) - _3129, 9.9999997473787516355514526367188e-05);\n        int param_7 = ci;\n        float _3159 = clamp((_3037 - (fa_shadow_split_at(param_7) - _3148)) / _3148, 0.0, 1.0);\n        if (_3159 > 0.0)\n        {\n            float s2 = 1.0;\n            if ((ci + 1) < _3022)\n            {\n                int param_8 = ci + 1;\n                vec3 param_9 = world;\n                vec3 param_10 = n;\n                vec3 param_11 = l;\n                float _3180 = fa_shadow_cascade(param_8, param_9, param_10, param_11);\n                s2 = _3180;\n                if (_3180 < 0.0)\n                {\n                    s2 = s;\n                }\n            }\n            s = mix(s, s2, _3159);\n        }\n    }\n    return s;\n}\n\nfloat fa_shadow_factor(vec3 n, vec3 l)\n{\n    vec3 param = fa_world_pos;\n    vec3 param_1 = n;\n    vec3 param_2 = l;\n    return fa_shadow_sun(param, param_1, param_2);\n}\n\nfloat fa_shadow_local(int li, vec3 lpos, vec3 world, vec3 n, vec3 l)\n{\n    bool _2702 = fa_mesh_fs_params[5].z < 0.5;\n    bool _2709;\n    if (!_2702)\n    {\n        _2709 = fa_shadows[29].x < 0.5;\n    }\n    else\n    {\n        _2709 = _2702;\n    }\n    if (_2709)\n    {\n        return 1.0;\n    }\n    int param = (int(fa_shadows[29].x + 0.5) - 1) + li;\n    vec4 _2722 = fa_light_texel(param);\n    float _2723 = _2722.x;\n    if (_2723 < 0.0)\n    {\n        return 1.0;\n    }\n    int _2732 = int(_2723 + 0.5);\n    int param_1 = _2732;\n    vec4 _2736 = fa_light_texel(param_1);\n    int param_2 = _2732 + 1;\n    vec4 _2741 = fa_light_texel(param_2);\n    float fade = 1.0;\n    float _2744 = _2736.y;\n    if (_2744 > 0.0)\n    {\n        float _2761 = 1.0 - smoothstep(0.75 * _2744, _2744, length(world - fa_shadows[27].xyz));\n        fade = _2761;\n        if (_2761 <= 0.0)\n        {\n            return 1.0;\n        }\n    }\n    int face = 0;\n    if (_2736.x > 1.5)\n    {\n        vec3 param_3 = world - lpos;\n        face = fa_cube_face(param_3);\n    }\n    int _2785 = (_2732 + 2) + (face * 6);\n    int param_4 = _2785;\n    int param_5 = _2785 + 1;\n    int param_6 = _2785 + 3;\n    vec4 _2799 = fa_light_texel(param_6);\n    int param_7 = _2785 + 4;\n    vec4 _2804 = fa_light_texel(param_7);\n    int param_8 = _2785 + 5;\n    vec4 _2809 = fa_light_texel(param_8);\n    float _2821 = _2809.x * max(dot(_2799, vec4(world, 1.0)), 0.001000000047497451305389404296875);\n    float _2826 = clamp(dot(n, l), 0.0, 1.0);\n    float _2849 = clamp(dot(n, _2799.xyz), -1.0, 1.0);\n    float _2868 = min(sqrt(1.0 - (_2849 * _2849)) / max(abs(dot(n, world - lpos)) / max(dot(_2799, vec4(world, 1.0)), 0.001000000047497451305389404296875), 0.20000000298023223876953125), 4.0);\n    float _2871 = _2741.y;\n    float _2873;\n    if (_2871 > 0.0)\n    {\n        _2873 = _2871;\n    }\n    else\n    {\n        _2873 = 1.5 * _2821;\n    }\n    vec4 _2893 = vec4(world + (n * (_2873 * sqrt(1.0 - (_2826 * _2826)))), 1.0);\n    float _2897 = dot(_2799, _2893);\n    float _2900 = _2809.y;\n    if (_2897 < _2900)\n    {\n        return 1.0;\n    }\n    vec2 _2915 = vec2(dot(fa_light_texel(param_4), _2893), dot(fa_light_texel(param_5), _2893)) / vec2(_2897);\n    float _2917 = _2915.x;\n    bool _2920 = _2917 < _2804.x;\n    bool _2929;\n    if (!_2920)\n    {\n        _2929 = _2917 > _2804.z;\n    }\n    else\n    {\n        _2929 = _2920;\n    }\n    bool _2938;\n    if (!_2929)\n    {\n        _2938 = _2915.y < _2804.y;\n    }\n    else\n    {\n        _2938 = _2929;\n    }\n    bool _2947;\n    if (!_2938)\n    {\n        _2947 = _2915.y > _2804.w;\n    }\n    else\n    {\n        _2947 = _2938;\n    }\n    if (_2947)\n    {\n        return 1.0;\n    }\n    float _2953 = _2741.x;\n    float _2955;\n    if (_2953 > 0.0)\n    {\n        _2955 = _2953;\n    }\n    else\n    {\n        _2955 = 1.5 * _2821;\n    }\n    vec2 param_9 = _2915;\n    vec4 param_10 = _2804;\n    float param_11 = _2897 - (_2955 * (1.0 + (0.5 * _2868)));\n    float param_12 = _2821;\n    float param_13 = 1.0;\n    float param_14 = _2809.z * 0.25;\n    float param_15 = (_2821 * min(_2868, 3.0)) * 0.5;\n    vec3 param_16 = vec3(1.0, _2900, _2809.z);\n    int param_17 = int(_2736.z + 0.5);\n    float param_18 = _2736.w;\n    return mix(1.0, fa_shadow_filter(param_9, param_10, param_11, param_12, param_13, param_14, param_15, param_16, param_17, param_18), fade);\n}\n\nfloat fa_contact_shadow(int li, vec3 world, vec3 gn, vec3 l, float dist)\n{\n    bool _4510 = fa_mesh_fs_params[24].x < 0.5;\n    bool _4517;\n    if (!_4510)\n    {\n        _4517 = fa_shadows[29].x < 0.5;\n    }\n    else\n    {\n        _4517 = _4510;\n    }\n    if (_4517)\n    {\n        return 1.0;\n    }\n    int param = (int(fa_shadows[29].x + 0.5) - 1) + li;\n    vec4 _4530 = fa_light_texel(param);\n    float _4531 = _4530.y;\n    float len = _4531;\n    if (_4531 <= 0.0)\n    {\n        return 1.0;\n    }\n    float _4543 = length(world - fa_mesh_fs_params[0].xyz);\n    float _4553 = 1.0 - smoothstep(0.5 * fa_mesh_fs_params[25].x, fa_mesh_fs_params[25].x, _4543);\n    if (_4553 <= 0.0)\n    {\n        return 1.0;\n    }\n    float _4559 = len;\n    float _4562 = min(_4559, 0.89999997615814208984375 * dist);\n    len = _4562;\n    float _4567 = 0.004999999888241291046142578125 + (0.0030000000260770320892333984375 * _4543);\n    float _4572 = _4567 + (0.5 * _4562);\n    vec3 _4578 = world + (gn * _4567);\n    float _4580 = fa_shadow_noise();\n    float occ = 0.0;\n    float _4644;\n    for (int k = 0; k < 12; k++)\n    {\n        float _4595 = (float(k) + _4580) * 0.083333335816860198974609375;\n        vec3 _4603 = _4578 + (l * (_4595 * len));\n        vec4 _4609 = vec4(_4603, 1.0);\n        float _4615 = dot(fa_mesh_fs_params[28], _4609);\n        if (_4615 < 9.9999997473787516355514526367188e-05)\n        {\n            break;\n        }\n        vec2 _4635 = vec2(dot(fa_mesh_fs_params[26], _4609), dot(fa_mesh_fs_params[27], _4609)) / vec2(_4615);\n        float _4639 = _4635.x * 0.5;\n        float _4640 = _4639 + 0.5;\n        if (fa_mesh_fs_params[24].y > 0.5)\n        {\n            _4644 = (_4635.y * 0.5) + 0.5;\n        }\n        else\n        {\n            _4644 = 0.5 - (_4635.y * 0.5);\n        }\n        bool _4660 = _4640 < 0.0;\n        bool _4667;\n        if (!_4660)\n        {\n            _4667 = _4640 >= 1.0;\n        }\n        else\n        {\n            _4667 = _4660;\n        }\n        bool _4674;\n        if (!_4667)\n        {\n            _4674 = _4644 < 0.0;\n        }\n        else\n        {\n            _4674 = _4667;\n        }\n        bool _4681;\n        if (!_4674)\n        {\n            _4681 = _4644 >= 1.0;\n        }\n        else\n        {\n            _4681 = _4674;\n        }\n        if (_4681)\n        {\n            break;\n        }\n        vec4 _4700 = texelFetch(fa_screen_tex_fa_shadow_smp, ivec2(vec2(_4640, _4644) * fa_mesh_fs_params[24].zw), 0);\n        if (_4700.w < 0.5)\n        {\n            continue;\n        }\n        float _4719 = (dot(fa_mesh_fs_params[29].xyz, _4603) + fa_mesh_fs_params[29].w) - _4700.x;\n        if ((_4719 > _4567) && (_4719 < _4572))\n        {\n            occ = max(occ, (1.0 - (_4595 * _4595)) * smoothstep(0.0, 0.0500000007450580596923828125, min(min(_4640, 0.5 - _4639), min(_4644, 1.0 - _4644))));\n        }\n    }\n    return 1.0 - (occ * _4553);\n}\n\nLightSample fa_light_shadowed(int li, vec3 world_pos, vec3 gn)\n{\n    int param = li;\n    float _5185 = fa_baked_keep(param);\n    if (_5185 <= 0.0)\n    {\n        int param_1 = li;\n        return LightSample(vec3(0.0, 1.0, 0.0), vec3(0.0), 0.0, 1.0, 0.0, int(fa_light_type(param_1) + 0.5));\n    }\n    int param_2 = li;\n    vec3 param_3 = world_pos;\n    vec3 param_4 = gn;\n    LightSample _5211 = fa_light_sample_n(param_2, param_3, param_4);\n    vec3 _7748 = _5211.color;\n    float _7749 = _5211.attenuation;\n    float _7750 = _5211.shadow;\n    bool _5214 = _5211.type == 0;\n    if (_5214 && (li == 0))\n    {\n        vec3 param_5 = gn;\n        vec3 param_6 = _5211.direction;\n        float _5225 = fa_shadow_factor(param_5, param_6);\n        _7750 = _5225;\n        _7748 *= _5225;\n    }\n    else\n    {\n        bool _5236 = _5211.type != 0;\n        bool _5242;\n        if (_5236)\n        {\n            _5242 = _7749 > 0.0;\n        }\n        else\n        {\n            _5242 = _5236;\n        }\n        if (_5242)\n        {\n            int param_7 = li;\n            int param_8 = fa_light_base(param_7);\n            int param_9 = li;\n            vec3 param_10 = fa_light_texel(param_8).xyz;\n            vec3 param_11 = world_pos;\n            vec3 param_12 = gn;\n            vec3 param_13 = _5211.direction;\n            float _5261 = fa_shadow_local(param_9, param_10, param_11, param_12, param_13);\n            _7750 = _5261;\n            _7748 *= _5261;\n        }\n    }\n    bool _5271 = fa_mesh_fs_params[24].x > 0.5;\n    bool _5277;\n    if (_5271)\n    {\n        _5277 = _7749 > 0.0;\n    }\n    else\n    {\n        _5277 = _5271;\n    }\n    if (_5277)\n    {\n        float _5284;\n        if (_5214)\n        {\n            _5284 = 1000000000.0;\n        }\n        else\n        {\n            _5284 = _5211._distance;\n        }\n        int param_14 = li;\n        vec3 param_15 = world_pos;\n        vec3 param_16 = gn;\n        vec3 param_17 = _5211.direction;\n        float param_18 = _5284;\n        float _5302 = fa_contact_shadow(param_14, param_15, param_16, param_17, param_18);\n        _7750 *= _5302;\n        _7748 *= _5302;\n    }\n    float _5315 = _7749;\n    float _5316 = _5315 * _5185;\n    _7749 = _5316;\n    vec3 _5320 = _7748;\n    vec3 _5321 = _5320 * _5185;\n    _7748 = _5321;\n    return LightSample(_5211.direction, _5321, _5316, _7750, _5211._distance, _5211.type);\n}\n\nvec3 fa_ltc_tangent(vec3 n, vec3 v)\n{\n    vec3 _5355 = v - (n * dot(v, n));\n    vec3 t = _5355;\n    float _5359 = dot(_5355, _5355);\n    float l2 = _5359;\n    if (_5359 < 1.0000000133514319600180897396058e-10)\n    {\n        vec3 _5369;\n        if (abs(n.z) < 0.999000012874603271484375)\n        {\n            _5369 = cross(n, vec3(0.0, 0.0, 1.0));\n        }\n        else\n        {\n            _5369 = cross(n, vec3(1.0, 0.0, 0.0));\n        }\n        t = _5369;\n        l2 = dot(_5369, _5369);\n    }\n    return t * inversesqrt(l2);\n}\n\nvec3 fa_ltc_local(vec3 t1, vec3 n, vec3 p)\n{\n    return vec3(dot(t1, p), dot(cross(n, t1), p), dot(n, p));\n}\n\nvec3 fa_ltc_edge_vector(vec3 a, vec3 b)\n{\n    float _5404 = dot(a, a);\n    float _5408 = dot(b, b);\n    if ((_5404 < 1.0000000195414813782625560981111e-24) || (_5408 < 1.0000000195414813782625560981111e-24))\n    {\n        return vec3(0.0);\n    }\n    vec3 _5422 = a * inversesqrt(_5404);\n    vec3 _5427 = b * inversesqrt(_5408);\n    float _5431 = dot(_5422, _5427);\n    float _5434 = abs(_5431);\n    float g = (((((((((((0.0416471660137176513671875 * _5434) - 0.1924748718738555908203125) * _5434) + 0.4179156124591827392578125) * _5434) - 0.616057217121124267578125) * _5434) + 0.777722418308258056640625) * _5434) - 0.999542415142059326171875) * _5434) + 1.570791721343994140625;\n    if (_5431 < 0.0)\n    {\n        g = (3.1415927410125732421875 * inversesqrt(max(1.0 - (_5431 * _5431), 1.0000000116860974230803549289703e-07))) - g;\n    }\n    return cross(_5422, _5427) * g;\n}\n\nvoid fa_ltc_clip_edge(vec3 a, vec3 b, inout vec3 sum, inout vec3 leave, inout vec3 enter, inout vec2 seen)\n{\n    bool _5491 = a.z > 0.0;\n    bool _5495 = b.z > 0.0;\n    if (_5491 && _5495)\n    {\n        vec3 param = a;\n        vec3 param_1 = b;\n        sum += fa_ltc_edge_vector(param, param_1);\n    }\n    else\n    {\n        if (_5491 != _5495)\n        {\n            vec3 _5530 = a + ((b - a) * (a.z / (a.z - b.z)));\n            _5530.z = 0.0;\n            if (_5491)\n            {\n                vec3 param_2 = a;\n                vec3 param_3 = _5530;\n                sum += fa_ltc_edge_vector(param_2, param_3);\n                leave = _5530;\n                seen.x = 1.0;\n            }\n            else\n            {\n                vec3 param_4 = _5530;\n                vec3 param_5 = b;\n                sum += fa_ltc_edge_vector(param_4, param_5);\n                enter = _5530;\n                seen.y = 1.0;\n            }\n        }\n    }\n}\n\nfloat fa_ltc_quad(vec4 abcd, vec3 p0, vec3 p1, vec3 p2, vec3 p3)\n{\n    vec3 _5579 = vec3((abcd.x * p0.x) + (abcd.y * p0.z), p0.y, (abcd.z * p0.x) + (abcd.w * p0.z));\n    vec3 _5605 = vec3((abcd.x * p1.x) + (abcd.y * p1.z), p1.y, (abcd.z * p1.x) + (abcd.w * p1.z));\n    vec3 _5631 = vec3((abcd.x * p2.x) + (abcd.y * p2.z), p2.y, (abcd.z * p2.x) + (abcd.w * p2.z));\n    vec3 _5657 = vec3((abcd.x * p3.x) + (abcd.y * p3.z), p3.y, (abcd.z * p3.x) + (abcd.w * p3.z));\n    vec3 sum = vec3(0.0);\n    vec3 leave = vec3(0.0);\n    vec3 enter = vec3(0.0);\n    vec3 param = _5579;\n    vec3 param_1 = _5605;\n    vec3 param_2 = vec3(0.0);\n    vec3 param_3 = vec3(0.0);\n    vec3 param_4 = vec3(0.0);\n    vec2 param_5 = vec2(0.0);\n    fa_ltc_clip_edge(param, param_1, param_2, param_3, param_4, param_5);\n    sum = param_2;\n    leave = param_3;\n    enter = param_4;\n    vec3 param_6 = _5605;\n    vec3 param_7 = _5631;\n    vec3 param_8 = param_2;\n    vec3 param_9 = param_3;\n    vec3 param_10 = param_4;\n    vec2 param_11 = param_5;\n    fa_ltc_clip_edge(param_6, param_7, param_8, param_9, param_10, param_11);\n    sum = param_8;\n    leave = param_9;\n    enter = param_10;\n    vec3 param_12 = _5631;\n    vec3 param_13 = _5657;\n    vec3 param_14 = param_8;\n    vec3 param_15 = param_9;\n    vec3 param_16 = param_10;\n    vec2 param_17 = param_11;\n    fa_ltc_clip_edge(param_12, param_13, param_14, param_15, param_16, param_17);\n    sum = param_14;\n    leave = param_15;\n    enter = param_16;\n    vec3 param_18 = _5657;\n    vec3 param_19 = _5579;\n    vec3 param_20 = param_14;\n    vec3 param_21 = param_15;\n    vec3 param_22 = param_16;\n    vec2 param_23 = param_17;\n    fa_ltc_clip_edge(param_18, param_19, param_20, param_21, param_22, param_23);\n    sum = param_20;\n    leave = param_21;\n    enter = param_22;\n    if ((param_23.x * param_23.y) > 0.5)\n    {\n        vec3 param_24 = leave;\n        vec3 param_25 = enter;\n        sum += fa_ltc_edge_vector(param_24, param_25);\n    }\n    return sum.z * 0.15915493667125701904296875;\n}\n\nfloat fa_ltc_rect(vec4 abcd, vec3 center, vec3 ex, vec3 ey)\n{\n    vec4 param = abcd;\n    vec3 param_1 = (center - ex) - ey;\n    vec3 param_2 = (center + ex) - ey;\n    vec3 param_3 = (center + ex) + ey;\n    vec3 param_4 = (center - ex) + ey;\n    return abs(fa_ltc_quad(param, param_1, param_2, param_3, param_4));\n}\n\nfloat fa_area_form(vec4 m, float shape, vec3 pc, vec3 ex, vec3 ey)\n{\n    if ((shape < 0.5) || (shape > 1.5))\n    {\n        vec4 param = m;\n        vec3 param_1 = pc;\n        vec3 param_2 = ex;\n        vec3 param_3 = ey;\n        return fa_ltc_rect(param, param_1, param_2, param_3);\n    }\n    vec3 _5806 = (pc + (ex * 0.92387950420379638671875)) + (ey * 0.3826834261417388916015625);\n    vec3 _5830 = (pc - (ex * 0.92387950420379638671875)) + (ey * 0.3826834261417388916015625);\n    vec3 _5846 = (pc - (ex * 0.3826834261417388916015625)) - (ey * 0.92387950420379638671875);\n    vec4 param_4 = m;\n    vec3 param_5 = _5806;\n    vec3 param_6 = (pc + (ex * 0.3826834261417388916015625)) + (ey * 0.92387950420379638671875);\n    vec3 param_7 = (pc - (ex * 0.3826834261417388916015625)) + (ey * 0.92387950420379638671875);\n    vec3 param_8 = _5830;\n    vec4 param_9 = m;\n    vec3 param_10 = _5806;\n    vec3 param_11 = _5830;\n    vec3 param_12 = (pc - (ex * 0.92387950420379638671875)) - (ey * 0.3826834261417388916015625);\n    vec3 param_13 = _5846;\n    vec4 param_14 = m;\n    vec3 param_15 = _5806;\n    vec3 param_16 = _5846;\n    vec3 param_17 = (pc + (ex * 0.3826834261417388916015625)) - (ey * 0.92387950420379638671875);\n    vec3 param_18 = (pc + (ex * 0.92387950420379638671875)) - (ey * 0.3826834261417388916015625);\n    return abs((fa_ltc_quad(param_4, param_5, param_6, param_7, param_8) + fa_ltc_quad(param_9, param_10, param_11, param_12, param_13)) + fa_ltc_quad(param_14, param_15, param_16, param_17, param_18));\n}\n\nvec2 fa_ltc_uv(float roughness, float ndv)\n{\n    return ((vec2(clamp((roughness - 0.0500000007450580596923828125) * 1.0526316165924072265625, 0.0, 1.0), sqrt(clamp(1.0 - ndv, 0.0, 1.0))) * 63.0) + vec2(0.5)) * vec2(0.015625);\n}\n\nvec3 fa_area_shade(int li, vec3 world_pos, vec3 n, vec3 v, vec3 diffuse_color, vec3 f0, float f90, float roughness, float ndv, float window)\n{\n    int param = li;\n    int _5904 = fa_light_base(param);\n    int param_1 = _5904;\n    int param_2 = _5904 + 1;\n    int param_3 = _5904 + 2;\n    int param_4 = _5904 + 4;\n    vec4 _5926 = fa_light_texel(param_4);\n    int param_5 = _5904 + 5;\n    vec4 _5931 = fa_light_texel(param_5);\n    int param_6 = _5904 + 6;\n    vec4 _5936 = fa_light_texel(param_6);\n    float _5937 = _5936.w;\n    vec3 _5942 = fa_light_texel(param_1).xyz - world_pos;\n    bool _5944 = _5937 < 1.5;\n    bool _5951;\n    if (_5944)\n    {\n        _5951 = dot(normalize(fa_light_texel(param_3).xyz), _5942) >= 0.0;\n    }\n    else\n    {\n        _5951 = _5944;\n    }\n    if (_5951)\n    {\n        return vec3(0.0);\n    }\n    bool _5960 = (_5937 > 0.5) && _5944;\n    float _5964 = _5960 ? 1.0539000034332275390625 : 1.0;\n    vec3 _5967 = _5926.xyz;\n    float _5969 = _5926.w;\n    vec3 _5975 = _5931.xyz;\n    float _5977 = _5931.w;\n    vec3 up = _5975 * (_5977 * _5964);\n    float _5983;\n    if (_5960)\n    {\n        _5983 = (3.1415927410125732421875 * _5969) * _5969;\n    }\n    else\n    {\n        _5983 = (4.0 * _5969) * _5977;\n    }\n    if (_5937 > 1.5)\n    {\n        vec3 _6009 = cross(_5967, -_5942);\n        vec3 perp = _6009;\n        float _6013 = dot(_6009, _6009);\n        vec3 _6016;\n        if (_6013 > 1.0000000133514319600180897396058e-10)\n        {\n            _6016 = perp * inversesqrt(_6013);\n        }\n        else\n        {\n            _6016 = _5975;\n        }\n        perp = _6016;\n        up = _6016 * _5977;\n    }\n    float _6037 = max(_5983, 9.9999999747524270787835121154785e-07);\n    vec3 param_7 = n;\n    vec3 param_8 = v;\n    vec3 _6047 = fa_ltc_tangent(param_7, param_8);\n    vec3 param_9 = _6047;\n    vec3 param_10 = n;\n    vec3 param_11 = _5942;\n    vec3 _6055 = fa_ltc_local(param_9, param_10, param_11);\n    vec3 param_12 = _6047;\n    vec3 param_13 = n;\n    vec3 param_14 = _5967 * (_5969 * _5964);\n    vec3 _6063 = fa_ltc_local(param_12, param_13, param_14);\n    vec3 param_15 = _6047;\n    vec3 param_16 = n;\n    vec3 param_17 = up;\n    vec3 _6071 = fa_ltc_local(param_15, param_16, param_17);\n    vec4 param_18 = vec4(1.0, 0.0, 0.0, 1.0);\n    float param_19 = _5937;\n    vec3 param_20 = _6055;\n    vec3 param_21 = _6063;\n    vec3 param_22 = _6071;\n    float param_23 = roughness;\n    float param_24 = ndv;\n    vec2 _6090 = fa_ltc_uv(param_23, param_24) * 64.0;\n    vec2 param_25 = _6090;\n    vec2 param_26 = _6090 + vec2(64.0, 0.0);\n    vec4 _6100 = fa_atlas_fetch(param_26);\n    vec4 param_27 = fa_atlas_fetch(param_25);\n    float param_28 = _5937;\n    vec3 param_29 = _6055;\n    vec3 param_30 = _6063;\n    vec3 param_31 = _6071;\n    return (((diffuse_color * fa_area_form(param_18, param_19, param_20, param_21, param_22)) + (((f0 * _6100.x) + ((vec3(f90) - f0) * _6100.y)) * fa_area_form(param_27, param_28, param_29, param_30, param_31))) * fa_light_texel(param_2).xyz) * ((((3.1415927410125732421875 * dot(_5942, _5942)) + _6037) / _6037) * window);\n}\n\nvec3 fa_light_rgb(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 1;\n    return fa_light_texel(param_1).xyz;\n}\n\nfloat fa_d_charlie(float alpha, float ndh)\n{\n    float _4247 = 1.0 / alpha;\n    return ((2.0 + _4247) * pow(sqrt(max(1.0 - (ndh * ndh), 9.9999997473787516355514526367188e-05)), _4247)) * 0.15915493667125701904296875;\n}\n\nfloat fa_v_ashikhmin(float ndl, float ndv)\n{\n    return clamp(0.25 / max((ndl + ndv) - (ndl * ndv), 9.9999997473787516355514526367188e-05), 0.0, 1.0);\n}\n\nfloat fa_layers_coat(FaLayers L, vec3 l, vec3 h, float vdh)\n{\n    float _4282 = max(dot(L.nc, l), 0.0);\n    float _4288 = max(dot(L.nc, h), 0.0);\n    float _4297 = ((_4288 * _4288) * (L.coat_a2 - 1.0)) + 1.0;\n    return (((L.coat * (0.039999999105930328369140625 + (0.959999978542327880859375 * pow(clamp(1.0 - vdh, 0.0, 1.0), 5.0)))) * (((L.coat_a2 / ((3.1415927410125732421875 * _4297) * _4297)) * (0.5 / max(mix((2.0 * _4282) * L.coat_ndv, _4282 + L.coat_ndv, L.coat_alpha), 9.9999997473787516355514526367188e-05))) * 3.1415927410125732421875)) * step(9.9999997473787516355514526367188e-05, _4282)) * _4282;\n}\n\nvec3 fa_area_layers(FaLayers L, int li, vec3 world_pos, vec3 n, vec3 v, vec3 l, vec3 diffuse_color, vec3 f0, float roughness, float ndv, float window)\n{\n    int param = li;\n    vec3 param_1 = world_pos;\n    vec3 param_2 = n;\n    vec3 param_3 = v;\n    vec3 param_4 = diffuse_color;\n    vec3 param_5 = f0;\n    float param_6 = L.f90;\n    float param_7 = roughness;\n    float param_8 = ndv;\n    float param_9 = window;\n    float _6168;\n    if (L.sheen_on)\n    {\n        _6168 = L.sheen_scale;\n    }\n    else\n    {\n        _6168 = 1.0;\n    }\n    vec3 result = fa_area_shade(param, param_1, param_2, param_3, param_4, param_5, param_6, param_7, param_8, param_9) * (L.keep * _6168);\n    vec3 _6181 = normalize(l + v);\n    int param_10 = li;\n    vec3 _6192 = fa_light_rgb(param_10) * window;\n    if (L.sheen_on)\n    {\n        float _6201 = max(dot(n, l), 0.0);\n        float param_11 = L.sheen_alpha;\n        float param_12 = max(dot(n, _6181), 0.0);\n        float param_13 = _6201;\n        float param_14 = ndv;\n        result += ((L.sheen * _6192) * (((((fa_d_charlie(param_11, param_12) * fa_v_ashikhmin(param_13, param_14)) * 3.1415927410125732421875) * step(9.9999997473787516355514526367188e-05, _6201)) * _6201) * L.keep));\n    }\n    if (L.coat > 0.0)\n    {\n        FaLayers param_15 = L;\n        vec3 param_16 = l;\n        vec3 param_17 = _6181;\n        float param_18 = max(dot(v, _6181), 0.0);\n        result += (_6192 * fa_layers_coat(param_15, param_16, param_17, param_18));\n    }\n    return result;\n}\n\nfloat fa_d_ggx_aniso(float ndh, float tdh, float bdh, float at, float ab)\n{\n    float _4150 = tdh / at;\n    float _4154 = bdh / ab;\n    float _4166 = ((_4150 * _4150) + (_4154 * _4154)) + (ndh * ndh);\n    return 1.0 / ((((3.1415927410125732421875 * at) * ab) * _4166) * _4166);\n}\n\nfloat fa_lambda_ggx_aniso(float n, float t, float b, float at, float ab)\n{\n    return 0.5 * (sqrt(1.0 + (((((at * at) * t) * t) + (((ab * ab) * b) * b)) / max(n * n, 9.9999999392252902907785028219223e-09))) - 1.0);\n}\n\nfloat fa_v_ggx_aniso(float ndl, float ndv, float tdv, float bdv, float tdl, float bdl, float at, float ab)\n{\n    float param = ndv;\n    float param_1 = tdv;\n    float param_2 = bdv;\n    float param_3 = at;\n    float param_4 = ab;\n    float param_5 = ndl;\n    float param_6 = tdl;\n    float param_7 = bdl;\n    float param_8 = at;\n    float param_9 = ab;\n    return clamp(1.0 / ((4.0 * max(ndl * ndv, 9.9999997473787516355514526367188e-05)) * ((1.0 + fa_lambda_ggx_aniso(param, param_1, param_2, param_3, param_4)) + fa_lambda_ggx_aniso(param_5, param_6, param_7, param_8, param_9))), 0.0, 1.0);\n}\n\nvec3 fa_layers_light(FaLayers L, vec3 diffuse_color, vec3 f0, vec3 n, vec3 v, vec3 l, vec3 h, float ndl, float ndv, float ndh, float vdh, float alpha, float a2)\n{\n    float _4346 = step(9.9999997473787516355514526367188e-05, ndl);\n    float d_ggx;\n    float vis;\n    if (L.aniso != 0.0)\n    {\n        float param = ndh;\n        float param_1 = dot(L.t, h);\n        float param_2 = dot(L.b, h);\n        float param_3 = L.at;\n        float param_4 = L.ab;\n        d_ggx = fa_d_ggx_aniso(param, param_1, param_2, param_3, param_4);\n        float param_5 = ndl;\n        float param_6 = ndv;\n        float param_7 = dot(L.t, v);\n        float param_8 = dot(L.b, v);\n        float param_9 = dot(L.t, l);\n        float param_10 = dot(L.b, l);\n        float param_11 = L.at;\n        float param_12 = L.ab;\n        vis = fa_v_ggx_aniso(param_5, param_6, param_7, param_8, param_9, param_10, param_11, param_12);\n    }\n    else\n    {\n        float _4425 = ((ndh * ndh) * (a2 - 1.0)) + 1.0;\n        d_ggx = a2 / ((3.1415927410125732421875 * _4425) * _4425);\n        vis = 0.5 / max(mix((2.0 * ndl) * ndv, ndl + ndv, alpha), 9.9999997473787516355514526367188e-05);\n    }\n    vec3 base = diffuse_color + (((f0 + ((vec3(L.f90) - f0) * pow(clamp(1.0 - vdh, 0.0, 1.0), 5.0))) * ((d_ggx * vis) * 3.1415927410125732421875)) * _4346);\n    if (L.sheen_on)\n    {\n        float param_13 = L.sheen_alpha;\n        float param_14 = ndh;\n        float param_15 = ndl;\n        float param_16 = ndv;\n        base = (base * L.sheen_scale) + (L.sheen * (((fa_d_charlie(param_13, param_14) * fa_v_ashikhmin(param_15, param_16)) * 3.1415927410125732421875) * _4346));\n    }\n    vec3 result = base * (L.keep * ndl);\n    if (L.coat > 0.0)\n    {\n        FaLayers param_17 = L;\n        vec3 param_18 = l;\n        vec3 param_19 = h;\n        float param_20 = vdh;\n        result += vec3(fa_layers_coat(param_17, param_18, param_19, param_20));\n    }\n    return result;\n}\n\nvec2 fa_env_brdf(float rough, float ndv)\n{\n    vec4 _3556 = (vec4(-1.0, -0.0274999998509883880615234375, -0.572000026702880859375, 0.02199999988079071044921875) * rough) + vec4(1.0, 0.0425000004470348358154296875, 1.03999996185302734375, -0.039999999105930328369140625);\n    float _3559 = _3556.x;\n    return (vec2(-1.03999996185302734375, 1.03999996185302734375) * ((min(_3559 * _3559, exp2((-9.27999973297119140625) * ndv)) * _3559) + _3556.y)) + _3556.zw;\n}\n\nvec3 fa_environment(vec3 d, float rough)\n{\n    if (fa_mesh_fs_params[11].w > 0.5)\n    {\n        return textureLod(fa_env_tex_fa_env_smp, d, clamp(rough, 0.0, 1.0) * fa_mesh_fs_params[12].w).xyz;\n    }\n    float _3410 = rough * rough;\n    float _3440 = 0.60000002384185791015625 * _3410;\n    return mix(mix(fa_mesh_fs_params[12].xyz * 0.550000011920928955078125, mix(fa_mesh_fs_params[12].xyz, fa_mesh_fs_params[11].xyz, vec3(pow(clamp(d.y * (1.0 - (0.699999988079071044921875 * _3410)), 0.0, 1.0), 0.550000011920928955078125))), vec3(smoothstep((-0.0500000007450580596923828125) - _3440, 0.0500000007450580596923828125 + _3440, d.y))), ((fa_mesh_fs_params[11].xyz + fa_mesh_fs_params[12].xyz) * 0.5) * 0.800000011920928955078125, vec3(_3410 * 0.60000002384185791015625));\n}\n\nvec3 fa_layers_ibl(FaLayers L, vec3 n, vec3 v, vec3 f0, float roughness)\n{\n    vec3 rn = n;\n    if (L.aniso != 0.0)\n    {\n        vec3 _4033;\n        if (L.aniso >= 0.0)\n        {\n            _4033 = L.b;\n        }\n        else\n        {\n            _4033 = L.t;\n        }\n        rn = normalize(mix(n, cross(cross(_4033, v), _4033), vec3(abs(L.aniso))));\n    }\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05);\n    vec2 _4066 = fa_env_brdf(param, param_1);\n    vec3 param_2 = reflect(-v, rn);\n    float param_3 = roughness;\n    vec3 result = (fa_environment(param_2, param_3) * ((f0 * _4066.x) + (vec3(L.f90) * _4066.y))) * L.base_scale;\n    if (L.sheen_on)\n    {\n        vec3 param_4 = n;\n        float param_5 = L.sheen_rough;\n        result += ((L.sheen * (L.sheen_e * L.keep)) * fa_environment(param_4, param_5));\n    }\n    if (L.coat > 0.0)\n    {\n        float param_6 = L.coat_rough;\n        float param_7 = L.coat_ndv;\n        vec2 _4121 = fa_env_brdf(param_6, param_7);\n        vec3 param_8 = reflect(-v, L.nc);\n        float param_9 = L.coat_rough;\n        result += (fa_environment(param_8, param_9) * (L.coat * ((0.039999999105930328369140625 * _4121.x) + _4121.y)));\n    }\n    return result;\n}\n\nvec3 fa_sky_reflection(vec3 n, vec3 v, vec3 f0, float roughness)\n{\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05);\n    vec2 _3598 = fa_env_brdf(param, param_1);\n    vec3 param_2 = reflect(-v, n);\n    float param_3 = roughness;\n    return fa_environment(param_2, param_3) * ((f0 * _3598.x) + vec3(_3598.y));\n}\n\nvec2 fa_xm_size(int k)\n{\n    return max(floor(fa_mesh_fs_params[24].zw / vec2(exp2(float(k)))), vec2(1.0));\n}\n\nvec2 fa_xm_origin(int k)\n{\n    if (k == 0)\n    {\n        return vec2(0.0);\n    }\n    float y = 0.0;\n    for (int j = 1; j < k; j++)\n    {\n        int param = j;\n        y += fa_xm_size(param).y;\n    }\n    return vec2(fa_mesh_fs_params[24].z, y);\n}\n\nvec3 fa_xm_texel(vec2 size, vec2 origin, vec2 p)\n{\n    return texelFetch(fa_screen_tex_fa_shadow_smp, ivec2(origin + clamp(p, vec2(0.0), size - vec2(1.0))), 0).xyz;\n}\n\nvec3 fa_xm_level(int k, vec2 uv)\n{\n    int param = k;\n    vec2 _4823 = fa_xm_size(param);\n    int param_1 = k;\n    vec2 _4827 = fa_xm_origin(param_1);\n    vec2 _4833 = (uv * _4823) - vec2(0.5);\n    vec2 _4836 = fract(_4833);\n    vec2 _4839 = floor(_4833);\n    vec2 param_2 = _4823;\n    vec2 param_3 = _4827;\n    vec2 param_4 = _4839;\n    vec2 param_5 = _4823;\n    vec2 param_6 = _4827;\n    vec2 param_7 = _4839 + vec2(1.0, 0.0);\n    vec2 param_8 = _4823;\n    vec2 param_9 = _4827;\n    vec2 param_10 = _4839 + vec2(0.0, 1.0);\n    vec2 param_11 = _4823;\n    vec2 param_12 = _4827;\n    vec2 param_13 = _4839 + vec2(1.0);\n    vec3 _4881 = vec3(_4836.x);\n    return mix(mix(fa_xm_texel(param_2, param_3, param_4), fa_xm_texel(param_5, param_6, param_7), _4881), mix(fa_xm_texel(param_8, param_9, param_10), fa_xm_texel(param_11, param_12, param_13), _4881), vec3(_4836.y));\n}\n\nvec3 fa_xm_sample(vec2 uv, float lod)\n{\n    float _4900 = max(fa_mesh_fs_params[31].w - 1.0, 0.0);\n    float _4904 = clamp(lod, 0.0, _4900);\n    int _4908 = int(floor(_4904));\n    int param = _4908;\n    vec2 param_1 = uv;\n    vec3 c = fa_xm_level(param, param_1);\n    float _4918 = float(_4908);\n    float _4919 = _4904 - _4918;\n    bool _4921 = _4919 > 0.001000000047497451305389404296875;\n    bool _4928;\n    if (_4921)\n    {\n        _4928 = _4918 < _4900;\n    }\n    else\n    {\n        _4928 = _4921;\n    }\n    if (_4928)\n    {\n        int param_2 = _4908 + 1;\n        vec2 param_3 = uv;\n        c = mix(c, fa_xm_level(param_2, param_3), vec3(_4919));\n    }\n    return c;\n}\n\nvec3 fa_transmitted(Surface s, vec3 n, vec3 v, float roughness, vec3 f0, float f90, float keep, float tr, inout float blend)\n{\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05);\n    vec2 _4954 = fa_env_brdf(param, param_1);\n    vec3 through = ((vec3(1.0) - clamp((f0 * _4954.x) + (vec3(f90) * _4954.y), vec3(0.0), vec3(1.0))) * s.albedo) * (tr * keep);\n    float _4982 = max(s.thickness, 0.0);\n    bool _4987 = _4982 > 0.0;\n    if ((s.attenuation_distance > 0.0) && _4987)\n    {\n        through *= exp((-((-log(clamp(s.attenuation_color, vec3(9.9999997473787516355514526367188e-05), vec3(1.0)))) / vec3(s.attenuation_distance))) * _4982);\n    }\n    bool _5012 = fa_mesh_fs_params[30].w > 1.5;\n    bool _5019;\n    if (!_5012)\n    {\n        _5019 = fa_mesh_fs_params[30].w < 0.5;\n    }\n    else\n    {\n        _5019 = _5012;\n    }\n    if (_5019)\n    {\n        blend = clamp(dot(through, vec3(0.3333333432674407958984375)), 0.0, 0.980000019073486328125);\n        return vec3(0.0);\n    }\n    vec3 world = fa_world_pos;\n    if (_4987)\n    {\n        world += (refract(-v, n, 1.0 / max(s.ior, 1.0)) * _4982);\n    }\n    vec4 _5054 = vec4(world, 1.0);\n    float _5059 = dot(fa_mesh_fs_params[28], _5054);\n    vec2 uv = vec2(0.5);\n    if (_5059 > 9.9999997473787516355514526367188e-05)\n    {\n        vec2 _5077 = vec2(dot(fa_mesh_fs_params[26], _5054), dot(fa_mesh_fs_params[27], _5054)) / vec2(_5059);\n        float _5085;\n        if (fa_mesh_fs_params[24].y > 0.5)\n        {\n            _5085 = (_5077.y * 0.5) + 0.5;\n        }\n        else\n        {\n            _5085 = 0.5 - (_5077.y * 0.5);\n        }\n        uv = vec2((_5077.x * 0.5) + 0.5, _5085);\n    }\n    vec2 param_2 = clamp(uv, vec2(0.0), vec2(1.0));\n    float param_3 = (clamp(roughness, 0.0, 1.0) * clamp((2.0 * s.ior) - 2.0, 0.0, 1.0)) * max(fa_mesh_fs_params[31].w - 1.0, 0.0);\n    return through * fa_xm_sample(param_2, param_3);\n}\n\nvec3 fa_shadow_debug(vec3 color, vec3 world)\n{\n    if (fa_shadows[27].w < 0.5)\n    {\n        return color;\n    }\n    int _3204 = int(fa_shadows[25].x + 0.5);\n    float _3214 = dot(world - fa_shadows[27].xyz, fa_shadows[28].xyz);\n    vec3 tint_1 = vec3(0.3499999940395355224609375);\n    bool _3219 = _3204 > 0;\n    bool _3228;\n    if (_3219)\n    {\n        int param = _3204 - 1;\n        _3228 = _3214 <= fa_shadow_split_at(param);\n    }\n    else\n    {\n        _3228 = _3219;\n    }\n    if (_3228)\n    {\n        tint_1 = vec3(1.0, 0.1500000059604644775390625, 0.100000001490116119384765625);\n        bool _3234 = _3204 > 1;\n        bool _3241;\n        if (_3234)\n        {\n            _3241 = _3214 > fa_shadows[24].x;\n        }\n        else\n        {\n            _3241 = _3234;\n        }\n        if (_3241)\n        {\n            tint_1 = vec3(0.100000001490116119384765625, 0.89999997615814208984375, 0.20000000298023223876953125);\n        }\n        bool _3247 = _3204 > 2;\n        bool _3254;\n        if (_3247)\n        {\n            _3254 = _3214 > fa_shadows[24].y;\n        }\n        else\n        {\n            _3254 = _3247;\n        }\n        if (_3254)\n        {\n            tint_1 = vec3(0.1500000059604644775390625, 0.300000011920928955078125, 1.0);\n        }\n        bool _3260 = _3204 > 3;\n        bool _3267;\n        if (_3260)\n        {\n            _3267 = _3214 > fa_shadows[24].z;\n        }\n        else\n        {\n            _3267 = _3260;\n        }\n        if (_3267)\n        {\n            tint_1 = vec3(1.0, 0.89999997615814208984375, 0.100000001490116119384765625);\n        }\n    }\n    return mix(color, tint_1, vec3(0.550000011920928955078125));\n}\n\nvoid main()\n{\n    fa_inst_load();\n    vec3 _7407 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _7407 = -_7407;\n    }\n    vec3 _6702 = normalize(fa_mesh_fs_params[0].xyz - fa_world_pos);\n    vec3 param = fa_world_pos;\n    fa_cluster_begin(param);\n    SurfaceInput param_1 = SurfaceInput(fa_world_pos, _7407, fa_world_tangent, fa_uv, fa_vertex_color, _6702, gl_FrontFacing);\n    Surface _6710 = fa_standard_surface(param_1);\n    vec3 _7438 = _6710.albedo;\n    float _7439 = _6710.alpha;\n    vec3 _7440 = _6710.normal;\n    float _7441 = _6710.metallic;\n    float _7442 = _6710.roughness;\n    float _7443 = _6710.occlusion;\n    vec3 _7444 = _6710.emission;\n    float _7445 = _6710.clearcoat;\n    float _7446 = _6710.clearcoat_roughness;\n    vec3 _7447 = _6710.sheen_color;\n    float _7448 = _6710.sheen_roughness;\n    float _7449 = _6710.anisotropy;\n    float _7450 = _6710.anisotropy_rotation;\n    float _7451 = _6710.specular;\n    float _7452 = _6710.ior;\n    vec3 _7453 = _6710.specular_color;\n    float _7454 = _6710.transmission;\n    float _7455 = _6710.thickness;\n    vec3 _7456 = _6710.attenuation_color;\n    float _7457 = _6710.attenuation_distance;\n    SurfaceInput param_2 = SurfaceInput(fa_world_pos, _7407, fa_world_tangent, fa_uv, fa_vertex_color, _6702, gl_FrontFacing);\n    Surface param_3 = _6710;\n    surface(param_2, param_3);\n    _7438 = param_3.albedo;\n    _7439 = param_3.alpha;\n    _7440 = param_3.normal;\n    _7441 = param_3.metallic;\n    _7442 = param_3.roughness;\n    _7443 = param_3.occlusion;\n    _7444 = param_3.emission;\n    _7445 = param_3.clearcoat;\n    _7446 = param_3.clearcoat_roughness;\n    _7447 = param_3.sheen_color;\n    _7448 = param_3.sheen_roughness;\n    _7449 = param_3.anisotropy;\n    _7450 = param_3.anisotropy_rotation;\n    _7451 = param_3.specular;\n    _7452 = param_3.ior;\n    _7453 = param_3.specular_color;\n    _7454 = param_3.transmission;\n    _7455 = param_3.thickness;\n    _7456 = param_3.attenuation_color;\n    _7457 = param_3.attenuation_distance;\n    vec3 param_4 = fa_world_pos;\n    vec3 param_5 = _7407;\n    vec3 param_6 = param_3.albedo;\n    vec3 param_7 = param_3.normal;\n    fa_apply_decals(param_4, param_5, param_6, param_7);\n    _7438 = param_6;\n    _7440 = param_7;\n    float fa_tr_blend = 0.0;\n    vec3 result;\n    if (fa_mesh_fs_params[3].w > 0.5)\n    {\n        result = _7438;\n    }\n    else\n    {\n        vec3 _6750 = normalize(_7440);\n        float _6757 = clamp(_7441, 0.0, 1.0);\n        float _6761 = clamp(_7442, 0.0500000007450580596923828125, 1.0);\n        float _6765 = _6761 * _6761;\n        float _6769 = _6765 * _6765;\n        float _6774 = max(dot(_6750, _6702), 9.9999997473787516355514526367188e-05);\n        float _6780 = 1.0 - _6757;\n        float _6781 = clamp(_7454, 0.0, 1.0) * _6780;\n        vec3 _6790 = (_7438 * _6780) * (1.0 - _6781);\n        vec3 _6797 = mix(vec3(0.039999999105930328369140625), _7438, vec3(_6757));\n        vec3 f0 = _6797;\n        SurfaceInput param_8 = SurfaceInput(fa_world_pos, _7407, fa_world_tangent, fa_uv, fa_vertex_color, _6702, gl_FrontFacing);\n        Surface param_9 = Surface(_7438, _7439, _7440, _7441, _7442, _7443, _7444, _7445, _7446, _7447, _7448, _7449, _7450, _7451, _7452, _7453, _7454, _7455, _7456, _7457);\n        vec3 param_10 = _6750;\n        vec3 param_11 = _6702;\n        float param_12 = _6757;\n        float param_13 = _6761;\n        vec3 param_14 = _6797;\n        FaLayers _6813 = fa_layers_setup(param_8, param_9, param_10, param_11, param_12, param_13, param_14);\n        f0 = param_14;\n        vec3 param_15 = _6750;\n        vec3 lit = (fa_indirect_diffuse(param_15) * _6790) * _7443;\n        if (_6813.on)\n        {\n            lit *= _6813.base_scale;\n        }\n        int _6835 = fa_cl_ndir + fa_cl_local;\n        for (int ln = 0; ln < _6835; ln++)\n        {\n            int param_16 = ln;\n            int _6848 = fa_cl_light(param_16);\n            int param_17 = _6848;\n            if (fa_baked_keep(param_17) <= 0.0)\n            {\n                continue;\n            }\n            int param_18 = _6848;\n            vec3 param_19 = fa_world_pos;\n            vec3 param_20 = _7407;\n            LightSample _6864 = fa_light_shadowed(param_18, param_19, param_20);\n            float _6872 = max(dot(_6750, _6864.direction), 0.0);\n            float _6878 = _6864.attenuation * _6864.shadow;\n            vec3 _6883 = normalize(_6864.direction + _6702);\n            float _6888 = max(dot(_6750, _6883), 0.0);\n            float _6893 = max(dot(_6702, _6883), 0.0);\n            bool _6900;\n            if (fa_light_is_area)\n            {\n                _6900 = !_6813.on;\n            }\n            else\n            {\n                _6900 = fa_light_is_area;\n            }\n            if (_6900)\n            {\n                int param_21 = _6848;\n                vec3 param_22 = fa_world_pos;\n                vec3 param_23 = _6750;\n                vec3 param_24 = _6702;\n                vec3 param_25 = _6790;\n                vec3 param_26 = f0;\n                float param_27 = 1.0;\n                float param_28 = _6761;\n                float param_29 = _6774;\n                float param_30 = _6878;\n                lit += fa_area_shade(param_21, param_22, param_23, param_24, param_25, param_26, param_27, param_28, param_29, param_30);\n            }\n            else\n            {\n                if (fa_light_is_area)\n                {\n                    FaLayers param_31 = _6813;\n                    int param_32 = _6848;\n                    vec3 param_33 = fa_world_pos;\n                    vec3 param_34 = _6750;\n                    vec3 param_35 = _6702;\n                    vec3 param_36 = _6864.direction;\n                    vec3 param_37 = _6790;\n                    vec3 param_38 = f0;\n                    float param_39 = _6761;\n                    float param_40 = _6774;\n                    float param_41 = _6878;\n                    lit += fa_area_layers(param_31, param_32, param_33, param_34, param_35, param_36, param_37, param_38, param_39, param_40, param_41);\n                }\n                else\n                {\n                    if (_6813.on)\n                    {\n                        FaLayers param_42 = _6813;\n                        vec3 param_43 = _6790;\n                        vec3 param_44 = f0;\n                        vec3 param_45 = _6750;\n                        vec3 param_46 = _6702;\n                        vec3 param_47 = _6864.direction;\n                        vec3 param_48 = _6883;\n                        float param_49 = _6872;\n                        float param_50 = _6774;\n                        float param_51 = _6888;\n                        float param_52 = _6893;\n                        float param_53 = _6765;\n                        float param_54 = _6769;\n                        int param_55 = _6848;\n                        lit += (fa_layers_light(param_42, param_43, param_44, param_45, param_46, param_47, param_48, param_49, param_50, param_51, param_52, param_53, param_54) * ((fa_light_rgb(param_55) * fa_light_tint) * _6878));\n                    }\n                    else\n                    {\n                        float _7006 = ((_6888 * _6888) * (_6769 - 1.0)) + 1.0;\n                        int param_56 = _6848;\n                        lit += (((_6790 + (((f0 + ((vec3(1.0) - f0) * pow(1.0 - _6893, 5.0))) * (((_6769 / ((3.1415927410125732421875 * _7006) * _7006)) * (0.5 / max(mix((2.0 * _6872) * _6774, _6872 + _6774, _6765), 9.9999997473787516355514526367188e-05))) * 3.1415927410125732421875)) * step(9.9999997473787516355514526367188e-05, _6872))) * (fa_light_rgb(param_56) * fa_light_tint)) * (_6872 * _6878));\n                    }\n                }\n            }\n        }\n        if (_6813.on)\n        {\n            FaLayers param_57 = _6813;\n            vec3 param_58 = _6750;\n            vec3 param_59 = _6702;\n            vec3 param_60 = f0;\n            float param_61 = _6761;\n            lit += (fa_layers_ibl(param_57, param_58, param_59, param_60, param_61) * _7443);\n        }\n        else\n        {\n            vec3 param_62 = _6750;\n            vec3 param_63 = _6702;\n            vec3 param_64 = f0;\n            float param_65 = _6761;\n            lit += (fa_sky_reflection(param_62, param_63, param_64, param_65) * _7443);\n        }\n        if (_6781 > 0.0)\n        {\n            float _7104;\n            if (_6813.on)\n            {\n                _7104 = _6813.f90;\n            }\n            else\n            {\n                _7104 = 1.0;\n            }\n            float _7112;\n            if (_6813.on)\n            {\n                _7112 = _6813.base_scale;\n            }\n            else\n            {\n                _7112 = 1.0;\n            }\n            Surface param_66 = Surface(_7438, _7439, _7440, _7441, _7442, _7443, _7444, _7445, _7446, _7447, _7448, _7449, _7450, _7451, _7452, _7453, _7454, _7455, _7456, _7457);\n            vec3 param_67 = _6750;\n            vec3 param_68 = _6702;\n            float param_69 = _6761;\n            vec3 param_70 = f0;\n            float param_71 = _7104;\n            float param_72 = _7112;\n            float param_73 = _6781;\n            float param_74 = fa_tr_blend;\n            vec3 _7136 = fa_transmitted(param_66, param_67, param_68, param_69, param_70, param_71, param_72, param_73, param_74);\n            fa_tr_blend = param_74;\n            lit += _7136;\n        }\n        result = lit;\n    }\n    vec3 _7143 = result;\n    vec3 _7144 = _7143 + _7444;\n    result = _7144;\n    vec3 param_75 = _7144;\n    vec3 param_76 = fa_world_pos;\n    result = fa_shadow_debug(param_75, param_76);\n    bool _7153 = fa_mesh_fs_params[7].w > 0.0;\n    bool _7160;\n    if (!_7153)\n    {\n        _7160 = fa_mesh_fs_params[8].y > 0.0;\n    }\n    else\n    {\n        _7160 = _7153;\n    }\n    if (_7160)\n    {\n        vec3 _7169 = fa_world_pos - fa_mesh_fs_params[0].xyz;\n        float _7175 = dot(_7169, fa_mesh_fs_params[9].xyz);\n        bool _7179 = fa_mesh_fs_params[9].w > 0.5;\n        float _7180;\n        if (_7179)\n        {\n            _7180 = _7175;\n        }\n        else\n        {\n            _7180 = length(_7169);\n        }\n        float _7192 = _7180 - fa_mesh_fs_params[8].x;\n        if (_7192 > 0.0)\n        {\n            float _7201 = fa_mesh_fs_params[7].w * _7192;\n            float tau = _7201 * _7201;\n            if (fa_mesh_fs_params[8].y > 0.0)\n            {\n                float _7217;\n                if (_7179)\n                {\n                    _7217 = fa_world_pos.y - (fa_mesh_fs_params[9].y * _7175);\n                }\n                else\n                {\n                    _7217 = fa_mesh_fs_params[0].y;\n                }\n                float _7238 = mix(_7217, fa_world_pos.y, clamp(fa_mesh_fs_params[8].x / _7180, 0.0, 1.0));\n                float _7242 = fa_world_pos.y - _7238;\n                float _7247 = _7238 - fa_mesh_fs_params[8].z;\n                float _7252 = fa_world_pos.y - fa_mesh_fs_params[8].z;\n                bool _7255 = _7247 <= 0.0;\n                bool _7256 = !_7255;\n                bool _7262;\n                if (_7256)\n                {\n                    _7262 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _7262 = _7255;\n                }\n                float _7263;\n                if (_7262)\n                {\n                    _7263 = fa_mesh_fs_params[8].y;\n                }\n                else\n                {\n                    _7263 = fa_mesh_fs_params[8].y * exp(-min(fa_mesh_fs_params[8].w * _7247, 80.0));\n                }\n                bool _7290;\n                if (_7256)\n                {\n                    _7290 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _7290 = _7255;\n                }\n                float _7291;\n                if (_7290)\n                {\n                    _7291 = fa_mesh_fs_params[8].y * _7247;\n                }\n                else\n                {\n                    _7291 = (fa_mesh_fs_params[8].y * (1.0 - exp(-min(fa_mesh_fs_params[8].w * _7247, 80.0)))) / fa_mesh_fs_params[8].w;\n                }\n                bool _7316 = _7252 <= 0.0;\n                bool _7323;\n                if (!_7316)\n                {\n                    _7323 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _7323 = _7316;\n                }\n                float _7324;\n                if (_7323)\n                {\n                    _7324 = fa_mesh_fs_params[8].y * _7252;\n                }\n                else\n                {\n                    _7324 = (fa_mesh_fs_params[8].y * (1.0 - exp(-min(fa_mesh_fs_params[8].w * _7252, 80.0)))) / fa_mesh_fs_params[8].w;\n                }\n                float _7351;\n                if (abs(_7242) < 0.001000000047497451305389404296875)\n                {\n                    _7351 = _7263;\n                }\n                else\n                {\n                    _7351 = (_7324 - _7291) / _7242;\n                }\n                tau += (_7192 * max(_7351, 0.0));\n            }\n            result = mix(result, fa_mesh_fs_params[7].xyz, vec3(clamp(1.0 - exp(-clamp(tau, 0.0, 80.0)), 0.0, 1.0)));\n        }\n    }\n    if (fa_tr_blend > 0.0)\n    {\n        float _7387 = 1.0 - fa_tr_blend;\n        result /= vec3(_7387);\n        _7439 *= _7387;\n    }\n    fa_frag_color = vec4(result, _7439);\n}\n\n",
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
            "size": 656,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_601",
            "glsl_uniforms": [
              {
                "type": "vec4",
                "array_count": 41,
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
            "inst_name": "_2268",
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
            "inst_name": "_6270",
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
      "vs": "#version 430\n\nstruct VertexData\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 color;\n    vec3 object_pos;\n};\n\nuniform vec4 fa_mesh_vs_params[11];\nuniform vec4 fa_skin[192];\nlayout(location = 2) out vec3 fa_world_pos;\nlayout(location = 3) out vec3 fa_world_normal;\nlayout(location = 4) out vec4 fa_world_tangent;\nlayout(location = 5) out vec2 fa_uv;\nlayout(location = 6) out vec4 fa_vertex_color;\nlayout(location = 11) in vec4 fa_inst_d0;\nlayout(location = 12) in vec4 fa_inst_d1;\nlayout(location = 0) flat out vec4 fa_inst_v0;\nlayout(location = 1) flat out vec4 fa_inst_v1;\nlayout(location = 5) in vec4 fa_inst_m0;\nlayout(location = 6) in vec4 fa_inst_m1;\nlayout(location = 7) in vec4 fa_inst_m2;\nlayout(location = 8) in vec4 fa_inst_m3;\nlayout(location = 9) in vec4 fa_joints;\nlayout(location = 10) in vec4 fa_weights;\nlayout(location = 0) in vec3 fa_position;\nlayout(location = 1) in vec3 fa_normal;\nlayout(location = 3) in vec4 fa_tangent;\nlayout(location = 2) in vec2 fa_texcoord0;\nlayout(location = 4) in vec4 fa_color;\nlayout(location = 7) out vec3 fa_lm;\nfloat raise;\nvec4 tint;\n\nvoid fa_instance_unpack(vec4 fa_d0, vec4 fa_d1, vec4 fa_d2)\n{\n    raise = fa_d0.x;\n    tint = fa_d1;\n}\n\nvoid fa_inst_begin()\n{\n    vec4 param = fa_inst_d0;\n    vec4 param_1 = fa_inst_d1;\n    vec4 param_2 = vec4(0.0);\n    fa_instance_unpack(param, param_1, param_2);\n    fa_inst_v0 = fa_inst_d0;\n    fa_inst_v1 = fa_inst_d1;\n}\n\nmat4 fa_skin_matrix(vec4 joints, vec4 weights)\n{\n    vec4 r0 = vec4(0.0);\n    vec4 r1 = vec4(0.0);\n    vec4 r2 = vec4(0.0);\n    for (int i = 0; i < 4; i++)\n    {\n        int _196 = int((joints[i] * 255.0) + 0.5) * 3;\n        r0 += (fa_skin[_196 * 1 + 0] * weights[i]);\n        r1 += (fa_skin[(_196 + 1) * 1 + 0] * weights[i]);\n        r2 += (fa_skin[(_196 + 2) * 1 + 0] * weights[i]);\n    }\n    return mat4(vec4(r0.x, r1.x, r2.x, 0.0), vec4(r0.y, r1.y, r2.y, 0.0), vec4(r0.z, r1.z, r2.z, 0.0), vec4(r0.w, r1.w, r2.w, 1.0));\n}\n\nVertexData fa_vertex_data(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    vec3 _99 = cross(model[1].xyz, model[2].xyz);\n    float _105 = (dot(model[0].xyz, _99) < 0.0) ? (-1.0) : 1.0;\n    return VertexData((model * vec4(position, 1.0)).xyz, (((_99 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _105, vec4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _105), texcoord0 * fa_mesh_vs_params[8].xy, color, position);\n}\n\nvoid vertex(inout VertexData v)\n{\n    v.world_pos.y += raise;\n}\n\nvoid fa_shade_vertex(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    mat4 param = model;\n    vec3 param_1 = position;\n    vec3 param_2 = normal;\n    vec4 param_3 = tangent;\n    vec2 param_4 = texcoord0;\n    vec4 param_5 = color;\n    VertexData param_6 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    vertex(param_6);\n    fa_world_pos = param_6.world_pos;\n    fa_world_normal = param_6.world_normal;\n    fa_world_tangent = param_6.world_tangent;\n    fa_uv = param_6.uv;\n    fa_vertex_color = param_6.color;\n    gl_Position = mat4(fa_mesh_vs_params[0], fa_mesh_vs_params[1], fa_mesh_vs_params[2], fa_mesh_vs_params[3]) * vec4(param_6.world_pos, 1.0);\n}\n\nvoid main()\n{\n    fa_inst_begin();\n    vec4 param = fa_joints;\n    vec4 param_1 = fa_weights;\n    mat4 param_2 = mat4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3) * fa_skin_matrix(param, param_1);\n    vec3 param_3 = fa_position;\n    vec3 param_4 = fa_normal;\n    vec4 param_5 = fa_tangent;\n    vec2 param_6 = fa_texcoord0;\n    vec4 param_7 = fa_color;\n    fa_shade_vertex(param_2, param_3, param_4, param_5, param_6, param_7);\n    fa_lm = vec3(0.0);\n}\n\n",
      "fs": "#version 430\n\nstruct SurfaceInput\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 vertex_color;\n    vec3 view_dir;\n    bool front_facing;\n};\n\nstruct LightSample\n{\n    vec3 direction;\n    vec3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct Surface\n{\n    vec3 albedo;\n    float alpha;\n    vec3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    vec3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    vec3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    vec3 specular_color;\n    float transmission;\n    float thickness;\n    vec3 attenuation_color;\n    float attenuation_distance;\n};\n\nstruct FaLayers\n{\n    bool on;\n    float f90;\n    float keep;\n    float base_scale;\n    float coat;\n    float coat_rough;\n    float coat_alpha;\n    float coat_a2;\n    vec3 nc;\n    float coat_ndv;\n    bool sheen_on;\n    vec3 sheen;\n    float sheen_rough;\n    float sheen_alpha;\n    float sheen_scale;\n    float sheen_e;\n    float aniso;\n    vec3 t;\n    vec3 b;\n    float at;\n    float ab;\n};\n\nconst float _3698[63] = float[](1.0, 1.0, 1.0, 0.4790000021457672119140625, 0.11699999868869781494140625, 0.01200000010430812835693359375, 0.0, 0.0, 0.0, 1.0, 1.0, 1.0, 0.578000009059906005859375, 0.19300000369548797607421875, 0.0350000001490116119384765625, 0.0030000000260770320892333984375, 0.0, 0.0, 1.0, 1.0, 1.0, 0.6740000247955322265625, 0.3459999859333038330078125, 0.1319999992847442626953125, 0.032999999821186065673828125, 0.0040000001899898052215576171875, 0.0, 0.971000015735626220703125, 0.954999983310699462890625, 0.828999996185302734375, 0.63999998569488525390625, 0.42599999904632568359375, 0.24500000476837158203125, 0.115000002086162567138671875, 0.037000000476837158203125, 0.0030000000260770320892333984375, 0.7469999790191650390625, 0.737999975681304931640625, 0.670000016689300537109375, 0.563000023365020751953125, 0.4309999942779541015625, 0.3039999902248382568359375, 0.1940000057220458984375, 0.1019999980926513671875, 0.0309999994933605194091796875, 0.614000022411346435546875, 0.609000027179718017578125, 0.566999971866607666015625, 0.499000012874603271484375, 0.412000000476837158203125, 0.32400000095367431640625, 0.240999996662139892578125, 0.162000000476837158203125, 0.087999999523162841796875, 0.538999974727630615234375, 0.535000026226043701171875, 0.505999982357025146484375, 0.4569999873638153076171875, 0.393999993801116943359375, 0.328999996185302734375, 0.2660000026226043701171875, 0.203999996185302734375, 0.14200000464916229248046875);\n\nuniform vec4 fa_mesh_fs_params[41];\nuniform vec4 fa_shadows[30];\nuniform vec4 fa_material[1];\nlayout(binding = 0) uniform sampler2D fa_light_tex_fa_shadow_smp;\nlayout(binding = 1) uniform sampler2D fa_tex_fa_smp;\nlayout(binding = 2) uniform sampler2D fa_normal_tex_fa_smp;\nlayout(binding = 3) uniform sampler2D fa_mr_tex_fa_smp;\nlayout(binding = 4) uniform sampler2D fa_occlusion_tex_fa_smp;\nlayout(binding = 5) uniform sampler2D fa_emissive_tex_fa_smp;\nlayout(binding = 6) uniform sampler2D fa_decal_tex_fa_env_smp;\nlayout(binding = 7) uniform sampler2D fa_lightmap_fa_env_smp;\nlayout(binding = 8) uniform samplerCube fa_env_tex_fa_env_smp;\nlayout(binding = 9) uniform sampler2D fa_light_atlas_fa_env_smp;\nlayout(binding = 10) uniform sampler2D fa_shadow_tex_fa_shadow_smp;\nlayout(binding = 11) uniform sampler2D fa_screen_tex_fa_shadow_smp;\n\nlayout(location = 2) in vec3 fa_world_pos;\nlayout(location = 7) in vec3 fa_lm;\nlayout(location = 0) flat in vec4 fa_inst_v0;\nlayout(location = 1) flat in vec4 fa_inst_v1;\nlayout(location = 3) in vec3 fa_world_normal;\nlayout(location = 4) in vec4 fa_world_tangent;\nlayout(location = 5) in vec2 fa_uv;\nlayout(location = 6) in vec4 fa_vertex_color;\nlayout(location = 0) out vec4 fa_frag_color;\nvec3 fa_light_tint;\nbool fa_light_is_area;\nint fa_cl_ndir;\nint fa_cl_slot;\nint fa_cl_local;\nfloat raise;\nvec4 tint;\n\nvoid fa_instance_unpack(vec4 fa_d0, vec4 fa_d1, vec4 fa_d2)\n{\n    raise = fa_d0.x;\n    tint = fa_d1;\n}\n\nvoid fa_inst_load()\n{\n    vec4 param = fa_inst_v0;\n    vec4 param_1 = fa_inst_v1;\n    vec4 param_2 = vec4(0.0);\n    fa_instance_unpack(param, param_1, param_2);\n}\n\nvec4 fa_light_texel(int t)\n{\n    return texelFetch(fa_light_tex_fa_shadow_smp, ivec2(t & 1023, t >> 10), 0);\n}\n\nvec4 fa_cluster_texel(vec3 world_pos)\n{\n    bool _1539 = fa_mesh_fs_params[19].x < 0.0;\n    bool _1546;\n    if (!_1539)\n    {\n        _1546 = fa_mesh_fs_params[19].w < 1.0;\n    }\n    else\n    {\n        _1546 = _1539;\n    }\n    bool _1554;\n    if (!_1546)\n    {\n        _1554 = fa_mesh_fs_params[18].x < 1.0;\n    }\n    else\n    {\n        _1554 = _1546;\n    }\n    bool _1561;\n    if (!_1554)\n    {\n        _1561 = fa_mesh_fs_params[18].y < 1.0;\n    }\n    else\n    {\n        _1561 = _1554;\n    }\n    bool _1568;\n    if (!_1561)\n    {\n        _1568 = fa_mesh_fs_params[19].y < 1.0;\n    }\n    else\n    {\n        _1568 = _1561;\n    }\n    if (_1568)\n    {\n        return vec4(0.0);\n    }\n    vec4 _1578 = vec4(world_pos, 1.0);\n    float _1584 = dot(fa_mesh_fs_params[16], _1578);\n    if (!(_1584 > 9.9999999747524270787835121154785e-07))\n    {\n        return vec4(0.0);\n    }\n    vec2 _1606 = vec2(dot(fa_mesh_fs_params[14], _1578), dot(fa_mesh_fs_params[15], _1578)) / vec2(_1584);\n    int _1610 = int(fa_mesh_fs_params[18].x);\n    int _1614 = int(fa_mesh_fs_params[18].y);\n    int param = (int(fa_mesh_fs_params[19].x) + (((clamp(int(floor(log2(max(dot(fa_mesh_fs_params[17].xyz, world_pos) + fa_mesh_fs_params[17].w, fa_mesh_fs_params[18].w) / fa_mesh_fs_params[18].w) * fa_mesh_fs_params[18].z)), 0, int(fa_mesh_fs_params[19].y) - 1) * _1614) + clamp(int(floor(((_1606.y * 0.5) + 0.5) * fa_mesh_fs_params[18].y)), 0, _1614 - 1)) * _1610)) + clamp(int(floor(((_1606.x * 0.5) + 0.5) * fa_mesh_fs_params[18].x)), 0, _1610 - 1);\n    return fa_light_texel(param);\n}\n\nivec2 fa_cluster_lookup(vec3 world_pos)\n{\n    vec3 param = world_pos;\n    vec4 _1690 = fa_cluster_texel(param);\n    return ivec2(int(_1690.x), int(_1690.y));\n}\n\nvoid fa_cluster_begin(vec3 world_pos)\n{\n    fa_cl_ndir = int(fa_mesh_fs_params[19].z);\n    vec3 param = world_pos;\n    ivec2 _5159 = fa_cluster_lookup(param);\n    fa_cl_slot = _5159.x;\n    fa_cl_local = _5159.y;\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nvec3 fa_linear_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_tex_fix(inout vec3 c, float mode)\n{\n    if (mode > 1.5)\n    {\n        vec3 param = c;\n        vec3 _6322 = fa_linear_to_srgb(param);\n        c = _6322;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            vec3 param_1 = c;\n            vec3 _6330 = fa_srgb_to_linear(param_1);\n            c = _6330;\n        }\n    }\n    return c;\n}\n\nvec3 fa_tangent_normal(SurfaceInput i, vec3 m)\n{\n    vec3 _483;\n    if (i.front_facing)\n    {\n        _483 = i.world_normal;\n    }\n    else\n    {\n        _483 = -i.world_normal;\n    }\n    vec3 _507 = normalize(i.world_tangent.xyz - (_483 * dot(_483, i.world_tangent.xyz)));\n    vec3 _534 = normalize(((_507 * m.x) + ((cross(_483, _507) * i.world_tangent.w) * m.y)) + (_483 * m.z));\n    vec3 _537;\n    if (i.front_facing)\n    {\n        _537 = _534;\n    }\n    else\n    {\n        _537 = -_534;\n    }\n    return _537;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    vec4 base_t = texture(fa_tex_fa_smp, i.uv);\n    float param = fa_mesh_fs_params[6].w;\n    float param_1 = 1.0;\n    vec3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    vec3 _6361 = fa_tex_fix(param_2, param_3);\n    vec4 _7959 = base_t;\n    _7959.x = _6361.x;\n    _7959.y = _6361.y;\n    _7959.z = _6361.z;\n    base_t = _7959;\n    vec4 _6375 = (_7959 * fa_mesh_fs_params[2]) * i.vertex_color;\n    vec3 _7768 = i.world_normal;\n    if (fa_mesh_fs_params[6].z > 0.5)\n    {\n        float param_4 = fa_mesh_fs_params[6].w;\n        float param_5 = 16.0;\n        vec3 param_6 = texture(fa_normal_tex_fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        vec3 _6407 = fa_tex_fix(param_6, param_7);\n        vec3 _6410 = (_6407 * 2.0) - vec3(1.0);\n        vec2 _6415 = _6410.xy * fa_mesh_fs_params[6].x;\n        vec3 _7967 = _6410;\n        _7967.x = _6415.x;\n        _7967.y = _6415.y;\n        SurfaceInput param_8 = i;\n        vec3 param_9 = _7967;\n        _7768 = fa_tangent_normal(param_8, param_9);\n    }\n    vec4 mrt = texture(fa_mr_tex_fa_smp, i.uv);\n    float param_10 = fa_mesh_fs_params[6].w;\n    float param_11 = 64.0;\n    vec3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    vec3 _6443 = fa_tex_fix(param_12, param_13);\n    vec4 _7970 = mrt;\n    _7970.x = _6443.x;\n    _7970.y = _6443.y;\n    _7970.z = _6443.z;\n    mrt = _7970;\n    vec4 _6471 = texture(fa_occlusion_tex_fa_smp, i.uv);\n    float param_14 = fa_mesh_fs_params[6].w;\n    float param_15 = 256.0;\n    vec3 param_16 = _6471.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    vec3 _6482 = fa_tex_fix(param_16, param_17);\n    float param_18 = fa_mesh_fs_params[6].w;\n    float param_19 = 4.0;\n    vec3 param_20 = texture(fa_emissive_tex_fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    vec3 _6512 = fa_tex_fix(param_20, param_21);\n    float _7773 = fa_mesh_fs_params[20].x;\n    float _7774 = fa_mesh_fs_params[20].y;\n    float _7777 = fa_mesh_fs_params[20].z;\n    float _7776 = fa_mesh_fs_params[21].w;\n    float _7779 = fa_mesh_fs_params[22].x;\n    if (fa_mesh_fs_params[22].z > 0.5)\n    {\n        if (mod(fa_mesh_fs_params[22].z, 2.0) > 0.5)\n        {\n            _7773 *= _6482.y;\n            _7774 *= _6482.z;\n            _7776 *= _6471.w;\n        }\n        if (fa_mesh_fs_params[22].z > 1.5)\n        {\n            _7777 *= mrt.x;\n            _7779 *= mrt.w;\n        }\n    }\n    return Surface(_6375.xyz, _6375.w, _7768, clamp(fa_mesh_fs_params[5].x * _6443.z, 0.0, 1.0), clamp(fa_mesh_fs_params[5].y * _6443.y, 0.0500000007450580596923828125, 1.0), 1.0 + (fa_mesh_fs_params[6].y * (_6482.x - 1.0)), fa_mesh_fs_params[3].xyz + (fa_mesh_fs_params[4].xyz * _6512), _7773, _7774, fa_mesh_fs_params[21].xyz, _7776, _7777, fa_mesh_fs_params[20].w, _7779, fa_mesh_fs_params[22].y, fa_mesh_fs_params[23].xyz, fa_mesh_fs_params[30].x, fa_mesh_fs_params[30].y, fa_mesh_fs_params[31].xyz, fa_mesh_fs_params[30].z);\n}\n\nvoid surface(SurfaceInput i, inout Surface s)\n{\n    s.emission += ((tint.xyz * tint.w) * fa_material[0].x);\n}\n\nvec4 fa_decal_tile(vec4 rect, vec2 uv, vec2 atlas, vec2 ddx, vec2 ddy)\n{\n    vec2 _1770 = rect.zw - rect.xy;\n    vec2 _1774 = _1770 * atlas;\n    vec2 _1778 = ddx * _1774;\n    vec2 _1782 = ddy * _1774;\n    return textureLod(fa_decal_tex_fa_env_smp, rect.xy + (clamp(uv, vec2(0.0), vec2(1.0)) * _1770), clamp(0.5 * log2(max(max(dot(_1778, _1778), dot(_1782, _1782)), 9.9999999392252902907785028219223e-09)), 0.0, 4.0));\n}\n\nvec3 fa_dc_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_dc_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvoid fa_apply_decals(vec3 world_pos, vec3 geo_normal, inout vec3 albedo, inout vec3 normal)\n{\n    bool _1815 = fa_mesh_fs_params[10].y < 0.5;\n    bool _1822;\n    if (!_1815)\n    {\n        _1822 = fa_mesh_fs_params[10].w < 0.5;\n    }\n    else\n    {\n        _1822 = _1815;\n    }\n    if (_1822)\n    {\n        return;\n    }\n    vec3 _1828 = dFdx(world_pos);\n    vec3 _1831 = dFdy(world_pos);\n    vec3 param = world_pos;\n    vec4 _1835 = fa_cluster_texel(param);\n    int _1839 = int(_1835.w);\n    if (_1839 < 1)\n    {\n        return;\n    }\n    int _1849 = int(fa_mesh_fs_params[10].y + 0.5);\n    int param_1 = _1849;\n    vec4 _1853 = fa_light_texel(param_1);\n    vec2 _1856 = _1853.yz;\n    int _1860 = int(_1853.w);\n    int param_2 = _1849 + 1;\n    vec4 _1865 = fa_light_texel(param_2);\n    float _1866 = _1865.x;\n    int _1872 = int(fa_mesh_fs_params[10].w + 0.5) - 1;\n    int _1876 = int(_1835.z);\n    vec3 _2141;\n    for (int k = 0; k < _1839; k++)\n    {\n        int _1889 = _1876 + k;\n        int param_3 = _1860 + (_1889 >> 2);\n        int _1906 = (_1849 + 2) + (int(fa_light_texel(param_3)[_1889 & 3]) * 7);\n        int param_4 = _1906 + 6;\n        vec4 _1911 = fa_light_texel(param_4);\n        if (((int(_1911.w + 0.5) >> _1872) & 1) == 0)\n        {\n            continue;\n        }\n        int param_5 = _1906;\n        vec4 _1926 = fa_light_texel(param_5);\n        int param_6 = _1906 + 1;\n        vec4 _1931 = fa_light_texel(param_6);\n        int param_7 = _1906 + 2;\n        vec4 _1936 = fa_light_texel(param_7);\n        vec3 _1939 = _1926.xyz;\n        float _1944 = dot(_1939, world_pos) + _1926.w;\n        vec3 _1946 = _1931.xyz;\n        float _1951 = dot(_1946, world_pos) + _1931.w;\n        vec3 _1953 = _1936.xyz;\n        float _1958 = dot(_1953, world_pos) + _1936.w;\n        bool _1963 = abs(_1944) > 0.5;\n        bool _1971;\n        if (!_1963)\n        {\n            _1971 = abs(_1951) > 0.5;\n        }\n        else\n        {\n            _1971 = _1963;\n        }\n        bool _1979;\n        if (!_1971)\n        {\n            _1979 = abs(_1958) > 0.5;\n        }\n        else\n        {\n            _1979 = _1971;\n        }\n        if (_1979)\n        {\n            continue;\n        }\n        float _1994 = clamp(dot(geo_normal, normalize(_1953)) * _1911.z, 0.0, 1.0);\n        if (_1994 <= 0.0)\n        {\n            continue;\n        }\n        float _2014 = (clamp((0.5 - abs(_1958)) * 10.0, 0.0, 1.0) * _1994) * _1911.x;\n        vec2 _2022 = vec2(_1944 + 0.5, 0.5 - _1951);\n        vec2 _2032 = vec2(dot(_1939, _1828), dot(_1946, _1828));\n        vec2 _2042 = vec2(dot(_1939, _1831), dot(_1946, _1831));\n        int param_8 = _1906 + 5;\n        vec4 _2047 = fa_light_texel(param_8);\n        int param_9 = _1906 + 3;\n        vec4 _2052 = fa_light_texel(param_9);\n        int param_10 = _1906 + 4;\n        vec4 _2057 = fa_light_texel(param_10);\n        float tex_a = 1.0;\n        vec3 col = _2047.xyz;\n        bool _2067 = _2052.z > _2052.x;\n        if (_2067)\n        {\n            vec4 param_11 = _2052;\n            vec2 param_12 = _2022;\n            vec2 param_13 = _1856;\n            vec2 param_14 = _2032;\n            vec2 param_15 = _2042;\n            vec4 tx = fa_decal_tile(param_11, param_12, param_13, param_14, param_15);\n            if ((_1866 > 0.5) && (_1866 < 1.5))\n            {\n                vec3 param_16 = tx.xyz;\n                vec3 _2093 = fa_dc_to_linear(param_16);\n                vec4 _7856 = tx;\n                _7856.x = _2093.x;\n                _7856.y = _2093.y;\n                _7856.z = _2093.z;\n                tx = _7856;\n            }\n            col *= tx.xyz;\n            tex_a = tx.w;\n        }\n        albedo = mix(albedo, col, vec3(clamp((_2014 * tex_a) * _2047.w, 0.0, 1.0)));\n        if (_2057.z > _2057.x)\n        {\n            vec4 param_17 = _2057;\n            vec2 param_18 = _2022;\n            vec2 param_19 = _1856;\n            vec2 param_20 = _2032;\n            vec2 param_21 = _2042;\n            vec4 _2137 = fa_decal_tile(param_17, param_18, param_19, param_20, param_21);\n            if (_1866 > 1.5)\n            {\n                vec3 param_22 = _2137.xyz;\n                vec3 _2147 = fa_dc_to_srgb(param_22);\n                _2141 = _2147;\n            }\n            else\n            {\n                _2141 = _2137.xyz;\n            }\n            vec3 _2156 = (_2141 * 2.0) - vec3(1.0);\n            vec2 _2161 = _2156.xy * _1911.y;\n            vec3 _2183 = (normalize(_1939) * _2161.x) + (normalize(_1946) * _2161.y);\n            vec3 _2186 = normalize(normal);\n            normal = normalize(mix(_2186, normalize((_2186 * max(_2156.z, 0.0500000007450580596923828125)) + (_2183 - (_2186 * dot(_2186, _2183)))), vec3(clamp(_2014 * (_2067 ? tex_a : 1.0), 0.0, 1.0))));\n        }\n    }\n}\n\nfloat fa_sheen_albedo(float ndv, float rough)\n{\n    float _3624 = min(sqrt(max(rough - 0.100000001490116119384765625, 0.0) * 1.111111164093017578125) * 6.0, 5.999000072479248046875);\n    float _3631 = min(sqrt(clamp(ndv, 0.0, 1.0)) * 8.0, 7.999000072479248046875);\n    int _3634 = int(_3624);\n    int _3637 = int(_3631);\n    float _3647 = _3631 - float(_3637);\n    int _3702 = (_3634 * 9) + _3637;\n    int _3722 = ((_3634 + 1) * 9) + _3637;\n    return mix(mix(_3698[_3702], _3698[_3702 + 1], _3647), mix(_3698[_3722], _3698[_3722 + 1], _3647), _3624 - float(_3634));\n}\n\nFaLayers fa_layers_setup(SurfaceInput i, Surface s, vec3 n, vec3 v, float metallic, float roughness, inout vec3 f0)\n{\n    bool _7691 = false;\n    float _7692 = 1.0;\n    float _7693 = 1.0;\n    float _7694 = 1.0;\n    float _7695 = 0.0;\n    float _7696 = 0.0;\n    float _7697 = 0.0;\n    float _7698 = 0.0;\n    float _7700 = 1.0;\n    bool _7701 = false;\n    vec3 _7702 = vec3(0.0);\n    float _7703 = 1.0;\n    float _7704 = 1.0;\n    float _7705 = 1.0;\n    float _7706 = 0.0;\n    float _7707 = 0.0;\n    vec3 _7708 = vec3(1.0, 0.0, 0.0);\n    vec3 _7709 = vec3(0.0, 0.0, 1.0);\n    float _7710 = 1.0;\n    float _7711 = 1.0;\n    float _3773 = clamp(s.specular, 0.0, 1.0);\n    float _3777 = clamp(s.ior, 1.0, 3.0);\n    bool _3782 = (_3773 != 1.0) || (_3777 != 1.5);\n    bool _3791;\n    if (!_3782)\n    {\n        _3791 = any(notEqual(s.specular_color, vec3(1.0)));\n    }\n    else\n    {\n        _3791 = _3782;\n    }\n    if (_3791)\n    {\n        float _3799 = (_3777 - 1.0) / (_3777 + 1.0);\n        f0 = mix(min(vec3(_3799 * _3799) * max(s.specular_color, vec3(0.0)), vec3(1.0)) * _3773, s.albedo, vec3(metallic));\n        _7692 = mix(_3773, 1.0, metallic);\n        _7691 = true;\n    }\n    float _3826 = clamp(s.clearcoat, 0.0, 1.0);\n    if (_3826 > 0.0)\n    {\n        float _3834 = clamp(s.clearcoat_roughness, 0.0500000007450580596923828125, 1.0);\n        _7695 = _3826;\n        _7696 = _3834;\n        float _3841 = _3834 * _3834;\n        _7697 = _3841;\n        _7698 = _3841 * _3841;\n        float _3853 = max(dot(i.world_normal, v), 9.9999997473787516355514526367188e-05);\n        _7700 = _3853;\n        _7693 = 1.0 - (_3826 * (0.039999999105930328369140625 + (0.959999978542327880859375 * pow(clamp(1.0 - _3853, 0.0, 1.0), 5.0))));\n        _7691 = true;\n    }\n    vec3 _3872 = max(s.sheen_color, vec3(0.0));\n    float _3881 = max(_3872.x, max(_3872.y, _3872.z));\n    if (_3881 > 0.0)\n    {\n        float _3889 = clamp(s.sheen_roughness, 0.100000001490116119384765625, 1.0);\n        _7701 = true;\n        _7702 = _3872;\n        _7703 = _3889;\n        _7704 = _3889 * _3889;\n        float param = max(dot(n, v), 9.9999997473787516355514526367188e-05);\n        float param_1 = _3889;\n        float _3906 = fa_sheen_albedo(param, param_1);\n        _7706 = _3906;\n        _7705 = 1.0 - min(_3881 * _3906, 1.0);\n        _7691 = true;\n    }\n    _7694 = _7693 * _7705;\n    float _3925 = clamp(s.anisotropy, -1.0, 1.0);\n    if (_3925 != 0.0)\n    {\n        vec3 _3940 = i.world_tangent.xyz - (n * dot(n, i.world_tangent.xyz));\n        vec3 t = _3940;\n        if (dot(_3940, _3940) < 9.9999999392252902907785028219223e-09)\n        {\n            bvec3 _3952 = bvec3(abs(n.y) < 0.9900000095367431640625);\n            t = cross(vec3(_3952.x ? vec3(0.0, 1.0, 0.0).x : vec3(1.0, 0.0, 0.0).x, _3952.y ? vec3(0.0, 1.0, 0.0).y : vec3(1.0, 0.0, 0.0).y, _3952.z ? vec3(0.0, 1.0, 0.0).z : vec3(1.0, 0.0, 0.0).z), n);\n        }\n        vec3 _3956 = t;\n        vec3 _3957 = normalize(_3956);\n        t = _3957;\n        vec3 _3982 = normalize((_3957 * cos(s.anisotropy_rotation)) + ((cross(n, _3957) * ((i.world_tangent.w < 0.0) ? (-1.0) : 1.0)) * sin(s.anisotropy_rotation)));\n        _7708 = _3982;\n        _7709 = cross(n, _3982);\n        float _3992 = roughness * roughness;\n        float _3998 = mix(_3992, 1.0, _3925 * _3925);\n        bool _4000 = _3925 > 0.0;\n        _7710 = _4000 ? _3998 : _3992;\n        _7711 = _4000 ? _3992 : _3998;\n        _7707 = _3925;\n        _7691 = true;\n    }\n    return FaLayers(_7691, _7692, _7693, _7694, _7695, _7696, _7697, _7698, i.world_normal, _7700, _7701, _7702, _7703, _7704, _7705, _7706, _7707, _7708, _7709, _7710, _7711);\n}\n\nvec3 fa_sky_sh_coef(int k)\n{\n    vec3 v = textureLod(fa_env_tex_fa_env_smp, vec3(1.0, 1.0 - (float((2 * (k >> 2)) + 1) * 0.25), 1.0 - (float((2 * (k & 3)) + 1) * 0.25)), 5.0).xyz;\n    if (fa_mesh_fs_params[11].w > 1.5)\n    {\n        v = (v - vec3(0.5)) * 8.0;\n    }\n    return v;\n}\n\nvec3 fa_sh_eval(vec3 c[9], vec3 n)\n{\n    vec3 _3381 = max((((c[0] * 0.2820948064327239990234375) + (((c[1] * (0.3257350027561187744140625 * n.y)) + (c[2] * (0.3257350027561187744140625 * n.z))) + (c[3] * (0.3257350027561187744140625 * n.x)))) + (((c[4] * ((0.2731371223926544189453125 * n.x) * n.y)) + (c[5] * ((0.2731371223926544189453125 * n.y) * n.z))) + (c[6] * (0.078847892582416534423828125 * (((3.0 * n.z) * n.z) - 1.0))))) + ((c[7] * ((0.2731371223926544189453125 * n.x) * n.z)) + (c[8] * (0.13656856119632720947265625 * ((n.x * n.x) - (n.y * n.y))))), vec3(0.0));\n    return _3381;\n}\n\nvec3 fa_ambient_light(vec3 n)\n{\n    if (fa_mesh_fs_params[11].w > 0.5)\n    {\n        vec3 c[9];\n        for (int k = 0; k < 9; k++)\n        {\n            int param = k;\n            c[k] = fa_sky_sh_coef(param);\n        }\n        vec3 param_1[9] = c;\n        vec3 param_2 = n;\n        return fa_sh_eval(param_1, param_2);\n    }\n    return fa_mesh_fs_params[1].xyz;\n}\n\nvec3 fa_indirect_diffuse(vec3 n)\n{\n    if (fa_lm.z > 0.5)\n    {\n        return textureLod(fa_lightmap_fa_env_smp, fa_lm.xy, 0.0).xyz;\n    }\n    if (fa_mesh_fs_params[32].w > 0.0)\n    {\n        vec3 c[9];\n        for (int k = 0; k < 9; k++)\n        {\n            c[k] = fa_mesh_fs_params[k * 1 + 32].xyz;\n        }\n        vec3 param = n;\n        vec3 param_1[9] = c;\n        vec3 param_2 = n;\n        return mix(fa_ambient_light(param), fa_sh_eval(param_1, param_2), vec3(clamp(fa_mesh_fs_params[32].w, 0.0, 1.0)));\n    }\n    vec3 param_3 = n;\n    return fa_ambient_light(param_3);\n}\n\nint fa_cluster_index(int slot, int n)\n{\n    int param = (int(fa_mesh_fs_params[19].x) + int(fa_mesh_fs_params[19].w)) + ((slot + n) >> 2);\n    vec4 t = fa_light_texel(param);\n    return int(t[(slot + n) & 3]);\n}\n\nint fa_cl_light(int n)\n{\n    if (n < fa_cl_ndir)\n    {\n        return n;\n    }\n    int param = fa_cl_slot;\n    int param_1 = n - fa_cl_ndir;\n    return fa_cluster_index(param, param_1);\n}\n\nint fa_light_base(int li)\n{\n    return li * ((fa_mesh_fs_params[1].w > 4.5) ? 8 : 4);\n}\n\nbool fa_light_baked(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 3;\n    return fa_light_texel(param_1).w > 0.5;\n}\n\nfloat fa_baked_keep(int li)\n{\n    float _5129;\n    if (fa_lm.z > 0.5)\n    {\n        _5129 = 0.0;\n    }\n    else\n    {\n        _5129 = 1.0 - clamp(fa_mesh_fs_params[32].w, 0.0, 1.0);\n    }\n    bool _5140 = _5129 < 1.0;\n    bool _5146;\n    if (_5140)\n    {\n        int param = li;\n        _5146 = fa_light_baked(param);\n    }\n    else\n    {\n        _5146 = _5140;\n    }\n    return _5146 ? _5129 : 1.0;\n}\n\nfloat fa_light_type(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 1;\n    return fa_light_texel(param_1).w;\n}\n\nvec4 fa_atlas_fetch(vec2 texel)\n{\n    return textureLod(fa_light_atlas_fa_env_smp, texel / vec2(textureSize(fa_light_atlas_fa_env_smp, 0)), 0.0);\n}\n\nvec3 fa_cookie_sample(vec2 tile_origin, vec2 uv)\n{\n    vec2 param = (tile_origin + vec2(1.0)) + (clamp(uv, vec2(0.0), vec2(1.0)) * 254.0);\n    return fa_atlas_fetch(param).xyz;\n}\n\nvec3 fa_area_point(vec3 c, vec3 axis, vec3 ru, vec3 uu, float hx, float hy, float shape, vec3 p, vec3 r)\n{\n    bool _788 = dot(r, r) > 0.5;\n    if (shape > 1.5)\n    {\n        vec3 _801 = (c - (ru * hx)) - p;\n        vec3 _807 = ru * (2.0 * hx);\n        float _813 = max(dot(_807, _807), 9.9999999392252902907785028219223e-09);\n        float _817 = dot(_801, _807);\n        float t = clamp((-_817) / _813, 0.0, 1.0);\n        if (_788)\n        {\n            float _832 = dot(r, _807);\n            float _838 = _813 - (_832 * _832);\n            if (abs(_838) > (9.9999997473787516355514526367188e-06 * _813))\n            {\n                t = clamp(((dot(r, _801) * _832) - _817) / _838, 0.0, 1.0);\n            }\n        }\n        return (p + _801) + (_807 * t);\n    }\n    vec3 q = p;\n    float _870 = dot(r, axis);\n    bool _878;\n    if (_788)\n    {\n        _878 = abs(_870) > 9.9999997473787516355514526367188e-05;\n    }\n    else\n    {\n        _878 = _788;\n    }\n    if (_878)\n    {\n        float _888 = dot(c - p, axis) / _870;\n        if (_888 > 0.0)\n        {\n            q = p + (r * _888);\n        }\n    }\n    vec3 _901 = q - c;\n    vec2 xy = vec2(dot(_901, ru), dot(_901, uu));\n    if (shape > 0.5)\n    {\n        float _916 = length(xy);\n        if (_916 > hx)\n        {\n            xy *= (hx / _916);\n        }\n    }\n    else\n    {\n        xy = clamp(xy, vec2(-hx, -hy), vec2(hx, hy));\n    }\n    return (c + (ru * xy.x)) + (uu * xy.y);\n}\n\nint fa_cube_face(vec3 d)\n{\n    vec3 _549 = abs(d);\n    float _551 = _549.x;\n    float _553 = _549.y;\n    bool _554 = _551 >= _553;\n    bool _562;\n    if (_554)\n    {\n        _562 = _551 >= _549.z;\n    }\n    else\n    {\n        _562 = _554;\n    }\n    int _563;\n    if (_562)\n    {\n        _563 = (d.x > 0.0) ? 0 : 1;\n    }\n    else\n    {\n        int _578;\n        if (_553 >= _549.z)\n        {\n            _578 = (d.y > 0.0) ? 2 : 3;\n        }\n        else\n        {\n            _578 = (d.z > 0.0) ? 4 : 5;\n        }\n        _563 = _578;\n    }\n    return _563;\n}\n\nvoid fa_cube_face_basis(int f, out vec3 fwd, out vec3 up)\n{\n    if (f == 0)\n    {\n        fwd = vec3(1.0, 0.0, 0.0);\n        up = vec3(0.0, 1.0, 0.0);\n    }\n    else\n    {\n        if (f == 1)\n        {\n            fwd = vec3(-1.0, 0.0, 0.0);\n            up = vec3(0.0, 1.0, 0.0);\n        }\n        else\n        {\n            if (f == 2)\n            {\n                fwd = vec3(0.0, 1.0, 0.0);\n                up = vec3(0.0, 0.0, 1.0);\n            }\n            else\n            {\n                if (f == 3)\n                {\n                    fwd = vec3(0.0, -1.0, 0.0);\n                    up = vec3(0.0, 0.0, -1.0);\n                }\n                else\n                {\n                    if (f == 4)\n                    {\n                        fwd = vec3(0.0, 0.0, 1.0);\n                        up = vec3(0.0, 1.0, 0.0);\n                    }\n                    else\n                    {\n                        fwd = vec3(0.0, 0.0, -1.0);\n                        up = vec3(0.0, 1.0, 0.0);\n                    }\n                }\n            }\n        }\n    }\n}\n\nfloat fa_ies_sample(vec2 tile_origin, vec3 d, vec3 axis, vec3 right, vec3 up)\n{\n    float _708 = dot(d, right);\n    float _712 = dot(d, up);\n    float _723;\n    if (((_708 * _708) + (_712 * _712)) > 1.0000000133514319600180897396058e-10)\n    {\n        _723 = atan(_712, _708) * 0.15915493667125701904296875;\n    }\n    else\n    {\n        _723 = 0.0;\n    }\n    vec2 param = tile_origin + vec2(1.0 + ((_723 - floor(_723)) * 64.0), 1.0 + (acos(clamp(dot(d, axis), -1.0, 1.0)) * 10.18591594696044921875));\n    return fa_atlas_fetch(param).x;\n}\n\nLightSample fa_light_sample_n(int li, vec3 world_pos, vec3 n)\n{\n    int param = li;\n    int _954 = fa_light_base(param);\n    bool _958 = fa_mesh_fs_params[1].w > 4.5;\n    int param_1 = _954;\n    vec4 _962 = fa_light_texel(param_1);\n    int param_2 = _954 + 1;\n    vec4 _967 = fa_light_texel(param_2);\n    float _970 = _967.w;\n    float atten = 1.0;\n    float dist = 0.0;\n    fa_light_tint = vec3(1.0);\n    bool _982 = _958 && (_970 > 2.5);\n    fa_light_is_area = _982;\n    bool _984 = _970 < 0.5;\n    vec3 l;\n    if (_984)\n    {\n        l = normalize(_962.xyz);\n        if (_958)\n        {\n            int param_3 = _954 + 6;\n            vec4 _998 = fa_light_texel(param_3);\n            if (_998.z > 0.5)\n            {\n                int param_4 = _954 + 4;\n                vec4 _1008 = fa_light_texel(param_4);\n                int param_5 = _954 + 5;\n                vec4 _1013 = fa_light_texel(param_5);\n                vec2 param_6 = _998.xy;\n                vec2 param_7 = fract(vec2(dot(world_pos, _1008.xyz) * _1008.w, (-dot(world_pos, _1013.xyz)) * _1013.w) + vec2(0.5));\n                fa_light_tint = fa_cookie_sample(param_6, param_7);\n            }\n        }\n    }\n    else\n    {\n        vec3 _1043 = _962.xyz;\n        vec3 _1045 = _1043 - world_pos;\n        vec3 to_light = _1045;\n        float _1048 = length(_1045);\n        float reach = _1048;\n        bool front = true;\n        if (_982)\n        {\n            int param_8 = _954 + 7;\n            reach = max(_1048 - fa_light_texel(param_8).w, 0.0);\n            int param_9 = _954 + 4;\n            vec4 _1072 = fa_light_texel(param_9);\n            int param_10 = _954 + 5;\n            vec4 _1077 = fa_light_texel(param_10);\n            int param_11 = _954 + 6;\n            vec4 _1082 = fa_light_texel(param_11);\n            float _1083 = _1082.w;\n            int param_12 = _954 + 2;\n            vec3 _1090 = normalize(fa_light_texel(param_12).xyz);\n            bool _1092 = _1083 > 1.5;\n            bool _1100;\n            if (!_1092)\n            {\n                _1100 = dot(_1090, to_light) < 0.0;\n            }\n            else\n            {\n                _1100 = _1092;\n            }\n            front = _1100;\n            vec3 r = vec3(0.0);\n            vec3 _1109 = fa_mesh_fs_params[0].xyz - world_pos;\n            bool _1113 = dot(n, n) > 0.5;\n            bool _1121;\n            if (_1113)\n            {\n                _1121 = dot(_1109, _1109) > 9.9999999600419720025001879548654e-13;\n            }\n            else\n            {\n                _1121 = _1113;\n            }\n            if (_1121)\n            {\n                r = reflect(-normalize(_1109), normalize(n));\n            }\n            vec3 param_13 = _1043;\n            vec3 param_14 = _1090;\n            vec3 param_15 = _1072.xyz;\n            vec3 param_16 = _1077.xyz;\n            float param_17 = _1072.w;\n            float param_18 = _1077.w;\n            float param_19 = _1083;\n            vec3 param_20 = world_pos;\n            vec3 param_21 = r;\n            to_light = fa_area_point(param_13, param_14, param_15, param_16, param_17, param_18, param_19, param_20, param_21) - world_pos;\n        }\n        float _1157 = length(to_light);\n        dist = _1157;\n        l = to_light / vec3(max(_1157, 9.9999997473787516355514526367188e-05));\n        float _1171 = reach / max(_962.w, 0.001000000047497451305389404296875);\n        float _1177 = clamp(1.0 - (_1171 * _1171), 0.0, 1.0);\n        float _1179;\n        if (front)\n        {\n            _1179 = _1177 * _1177;\n        }\n        else\n        {\n            _1179 = 0.0;\n        }\n        atten = _1179;\n        bool _1190 = _970 < 2.5;\n        if ((_970 > 1.5) && _1190)\n        {\n            int param_22 = _954 + 2;\n            vec4 _1198 = fa_light_texel(param_22);\n            float _1208 = _1198.w;\n            int param_23 = _954 + 3;\n            vec4 _1213 = fa_light_texel(param_23);\n            float _1214 = _1213.x;\n            float cos_inner = _1214;\n            if (_1214 > 1.5)\n            {\n                cos_inner = mix(_1208, 1.0, 0.25);\n            }\n            atten *= smoothstep(_1208, cos_inner, dot(-l, normalize(_1198.xyz)));\n        }\n        if (_958 && (_970 < 1.5))\n        {\n            int param_24 = _954 + 6;\n            vec4 _1238 = fa_light_texel(param_24);\n            if (_1238.z > 0.5)\n            {\n                vec3 _1246 = -to_light;\n                int param_25 = _954 + 4;\n                int param_26 = _954 + 5;\n                vec3 _1260 = fa_light_texel(param_25).xyz;\n                vec3 _1264 = fa_light_texel(param_26).xyz;\n                vec3 _1273 = vec3(dot(_1246, _1260), dot(_1246, _1264), dot(_1246, cross(_1260, _1264)));\n                vec3 param_27 = _1273;\n                int _1277 = fa_cube_face(param_27);\n                int param_28 = _1277;\n                vec3 param_29;\n                vec3 param_30;\n                fa_cube_face_basis(param_28, param_29, param_30);\n                vec2 _1304 = vec2(dot(_1273, cross(param_29, param_30)), dot(_1273, param_30)) / vec2(max(dot(_1273, param_29), 9.9999997473787516355514526367188e-05));\n                int _1308 = _1277 / 3;\n                vec2 param_31 = _1238.xy + (vec2(float(_1277 - (_1308 * 3)), float(_1308)) * 256.0);\n                vec2 param_32 = vec2(0.5 + (0.5 * _1304.x), 0.5 - (0.5 * _1304.y));\n                fa_light_tint = fa_cookie_sample(param_31, param_32);\n            }\n            int param_33 = _954 + 7;\n            vec4 _1338 = fa_light_texel(param_33);\n            if (_1338.z > 0.5)\n            {\n                int param_34 = _954 + 2;\n                int param_35 = _954 + 4;\n                int param_36 = _954 + 5;\n                vec2 param_37 = _1338.xy;\n                vec3 param_38 = -l;\n                vec3 param_39 = normalize(fa_light_texel(param_34).xyz);\n                vec3 param_40 = fa_light_texel(param_35).xyz;\n                vec3 param_41 = fa_light_texel(param_36).xyz;\n                atten *= fa_ies_sample(param_37, param_38, param_39, param_40, param_41);\n            }\n        }\n        else\n        {\n            if (_958 && _1190)\n            {\n                int param_42 = _954 + 6;\n                vec4 _1385 = fa_light_texel(param_42);\n                int param_43 = _954 + 7;\n                vec4 _1390 = fa_light_texel(param_43);\n                bool _1393 = _1385.z > 0.5;\n                bool _1400;\n                if (!_1393)\n                {\n                    _1400 = _1390.z > 0.5;\n                }\n                else\n                {\n                    _1400 = _1393;\n                }\n                if (_1400)\n                {\n                    int param_44 = _954 + 2;\n                    vec4 _1407 = fa_light_texel(param_44);\n                    vec3 _1411 = normalize(_1407.xyz);\n                    int param_45 = _954 + 4;\n                    vec4 _1416 = fa_light_texel(param_45);\n                    int param_46 = _954 + 5;\n                    vec4 _1421 = fa_light_texel(param_46);\n                    if (_1393)\n                    {\n                        vec3 _1429 = -to_light;\n                        float _1436 = _1407.w;\n                        float _1452 = 0.5 / max(dot(_1429, _1411) * (sqrt(max(1.0 - (_1436 * _1436), 0.0)) / max(_1436, 0.001000000047497451305389404296875)), 9.9999997473787516355514526367188e-05);\n                        vec2 param_47 = _1385.xy;\n                        vec2 param_48 = vec2(0.5 + (dot(_1429, _1416.xyz) * _1452), 0.5 - (dot(_1429, _1421.xyz) * _1452));\n                        fa_light_tint = fa_cookie_sample(param_47, param_48);\n                    }\n                    if (_1390.z > 0.5)\n                    {\n                        vec2 param_49 = _1390.xy;\n                        vec3 param_50 = -l;\n                        vec3 param_51 = _1411;\n                        vec3 param_52 = _1416.xyz;\n                        vec3 param_53 = _1421.xyz;\n                        atten *= fa_ies_sample(param_49, param_50, param_51, param_52, param_53);\n                    }\n                }\n            }\n        }\n    }\n    vec3 _7679 = _967.xyz * atten;\n    if (_958)\n    {\n        _7679 *= fa_light_tint;\n    }\n    int _1521;\n    if (_984)\n    {\n        _1521 = 0;\n    }\n    else\n    {\n        _1521 = ((_970 > 1.5) && (_970 < 2.5)) ? 2 : 1;\n    }\n    return LightSample(l, _7679, atten, 1.0, dist, _1521);\n}\n\nfloat fa_shadow_split_at(int i)\n{\n    float _2258;\n    if (i == 0)\n    {\n        _2258 = fa_shadows[24].x;\n    }\n    else\n    {\n        float _2274;\n        if (i == 1)\n        {\n            _2274 = fa_shadows[24].y;\n        }\n        else\n        {\n            float _2282;\n            if (i == 2)\n            {\n                _2282 = fa_shadows[24].z;\n            }\n            else\n            {\n                _2282 = fa_shadows[24].w;\n            }\n            _2274 = _2282;\n        }\n        _2258 = _2274;\n    }\n    return _2258;\n}\n\nfloat fa_shadow_depth(inout vec2 uv, vec4 rect)\n{\n    uv = clamp(uv, rect.xy, rect.zw);\n    return textureLod(fa_shadow_tex_fa_shadow_smp, uv, 0.0).x;\n}\n\nfloat fa_shadow_fetch(vec2 uv, vec4 rect, vec3 conv)\n{\n    vec2 param = uv;\n    vec4 param_1 = rect;\n    float _2315 = fa_shadow_depth(param, param_1);\n    float _2319;\n    if (conv.x < 0.5)\n    {\n        _2319 = _2315;\n    }\n    else\n    {\n        _2319 = (conv.y * conv.z) / (conv.z - (_2315 * (conv.z - conv.y)));\n    }\n    return _2319;\n}\n\nfloat fa_shadow_noise()\n{\n    return fract(52.98291778564453125 * fract(dot(gl_FragCoord.xy, vec2(0.067110560834407806396484375, 0.005837149918079376220703125))));\n}\n\nvec2 fa_shadow_vogel(int k, int n, float phi)\n{\n    float _2246 = (float(k) * 2.3999631404876708984375) + phi;\n    return vec2(cos(_2246), sin(_2246)) * sqrt((float(k) + 0.5) / float(n));\n}\n\nfloat fa_shadow_filter(vec2 uv, vec4 rect, float zr, float texel_m, float unit, float reach, float plane, vec3 conv, int mode, float k)\n{\n    if (mode == 1)\n    {\n        vec2 param = uv;\n        vec4 param_1 = rect;\n        vec3 param_2 = conv;\n        return float(zr <= fa_shadow_fetch(param, param_1, param_2));\n    }\n    float _2365 = fa_shadow_noise() * 6.283185482025146484375;\n    float radius = 1.5;\n    if (mode == 2)\n    {\n        float _2374;\n        if (k < 0.0)\n        {\n            _2374 = (-k) / max(zr, 0.100000001490116119384765625);\n        }\n        else\n        {\n            _2374 = k;\n        }\n        float _2394 = clamp((_2374 * reach) / texel_m, 3.0, 12.0);\n        float sum = 0.0;\n        float cnt = 0.0;\n        for (int i = 0; i < 16; i++)\n        {\n            int param_3 = i;\n            int param_4 = 16;\n            float param_5 = _2365;\n            vec2 _2413 = fa_shadow_vogel(param_3, param_4, param_5) * _2394;\n            vec2 param_6 = uv + (_2413 * fa_shadows[26].zw);\n            vec4 param_7 = rect;\n            vec3 param_8 = conv;\n            float _2425 = fa_shadow_fetch(param_6, param_7, param_8);\n            if (_2425 < (zr - (length(_2413) * plane)))\n            {\n                sum += _2425;\n                cnt += 1.0;\n            }\n        }\n        if (cnt < 0.5)\n        {\n            return 1.0;\n        }\n        float _2451 = sum / cnt;\n        float _2461;\n        if (k < 0.0)\n        {\n            _2461 = (-k) / max(_2451, 0.0500000007450580596923828125);\n        }\n        else\n        {\n            _2461 = k;\n        }\n        radius = clamp(((max(zr - _2451, 0.0) * unit) * _2461) / texel_m, 1.5, 16.0);\n    }\n    float lit = 0.0;\n    int _2483 = (mode == 2) ? 24 : 16;\n    for (int i_1 = 0; i_1 < _2483; i_1++)\n    {\n        int param_9 = i_1;\n        int param_10 = _2483;\n        float param_11 = _2365;\n        vec2 _2502 = fa_shadow_vogel(param_9, param_10, param_11) * radius;\n        vec2 param_12 = uv + (_2502 * fa_shadows[26].zw);\n        vec4 param_13 = rect;\n        vec3 param_14 = conv;\n        lit += float((zr - (length(_2502) * plane)) <= fa_shadow_fetch(param_12, param_13, param_14));\n    }\n    return lit / float(_2483);\n}\n\nfloat fa_shadow_cascade(int ci, vec3 world, vec3 n, vec3 l)\n{\n    float _2544 = max(fa_shadows[ci * 1 + 20].y, 0.001000000047497451305389404296875);\n    float _2549 = clamp(dot(n, l), 0.0, 1.0);\n    float _2555 = sqrt(1.0 - (_2549 * _2549));\n    float _2562 = min(_2555 / max(_2549, 0.20000000298023223876953125), 4.0);\n    float _2567;\n    if (fa_shadows[26].y > 0.0)\n    {\n        _2567 = fa_shadows[26].y;\n    }\n    else\n    {\n        _2567 = 1.5 * fa_shadows[ci * 1 + 20].x;\n    }\n    vec4 _2592 = mat4(fa_shadows[ci * 4 + 0], fa_shadows[ci * 4 + 1], fa_shadows[ci * 4 + 2], fa_shadows[ci * 4 + 3]) * vec4(world + (n * (_2567 * _2555)), 1.0);\n    float _2599 = _2592.x;\n    bool _2602 = _2599 < fa_shadows[ci * 1 + 16].x;\n    bool _2611;\n    if (!_2602)\n    {\n        _2611 = _2599 > fa_shadows[ci * 1 + 16].z;\n    }\n    else\n    {\n        _2611 = _2602;\n    }\n    bool _2620;\n    if (!_2611)\n    {\n        _2620 = _2592.y < fa_shadows[ci * 1 + 16].y;\n    }\n    else\n    {\n        _2620 = _2611;\n    }\n    bool _2629;\n    if (!_2620)\n    {\n        _2629 = _2592.y > fa_shadows[ci * 1 + 16].w;\n    }\n    else\n    {\n        _2629 = _2620;\n    }\n    bool _2636;\n    if (!_2629)\n    {\n        _2636 = _2592.z > 1.0;\n    }\n    else\n    {\n        _2636 = _2629;\n    }\n    if (_2636)\n    {\n        return -1.0;\n    }\n    float _2644;\n    if (fa_shadows[26].x > 0.0)\n    {\n        _2644 = fa_shadows[26].x;\n    }\n    else\n    {\n        _2644 = 1.5 * fa_shadows[ci * 1 + 20].x;\n    }\n    vec2 param = _2592.xy;\n    vec4 param_1 = fa_shadows[ci * 1 + 16];\n    float param_2 = _2592.z - ((_2644 * (1.0 + (0.5 * _2562))) / _2544);\n    float param_3 = fa_shadows[ci * 1 + 20].x;\n    float param_4 = _2544;\n    float param_5 = _2544 * 0.25;\n    float param_6 = ((fa_shadows[ci * 1 + 20].x * min(_2562, 3.0)) * 0.5) / _2544;\n    vec3 param_7 = vec3(0.0);\n    int param_8 = int(fa_shadows[25].z + 0.5);\n    float param_9 = fa_shadows[25].w;\n    return fa_shadow_filter(param, param_1, param_2, param_3, param_4, param_5, param_6, param_7, param_8, param_9);\n}\n\nfloat fa_shadow_sun(vec3 world, vec3 n, vec3 l)\n{\n    if (fa_mesh_fs_params[5].z < 0.5)\n    {\n        return 1.0;\n    }\n    int _3022 = int(fa_shadows[25].x + 0.5);\n    if (_3022 < 1)\n    {\n        return 1.0;\n    }\n    float _3037 = dot(world - fa_shadows[27].xyz, fa_shadows[28].xyz);\n    int param = _3022 - 1;\n    if (_3037 > fa_shadow_split_at(param))\n    {\n        return 1.0;\n    }\n    int ci = 0;\n    bool _3049 = _3022 > 1;\n    bool _3056;\n    if (_3049)\n    {\n        _3056 = _3037 > fa_shadows[24].x;\n    }\n    else\n    {\n        _3056 = _3049;\n    }\n    if (_3056)\n    {\n        ci = 1;\n    }\n    bool _3060 = _3022 > 2;\n    bool _3067;\n    if (_3060)\n    {\n        _3067 = _3037 > fa_shadows[24].y;\n    }\n    else\n    {\n        _3067 = _3060;\n    }\n    if (_3067)\n    {\n        ci = 2;\n    }\n    bool _3071 = _3022 > 3;\n    bool _3078;\n    if (_3071)\n    {\n        _3078 = _3037 > fa_shadows[24].z;\n    }\n    else\n    {\n        _3078 = _3071;\n    }\n    if (_3078)\n    {\n        ci = 3;\n    }\n    float s = -1.0;\n    for (int k = 0; k < 4; k++)\n    {\n        if (ci >= _3022)\n        {\n            break;\n        }\n        int param_1 = ci;\n        vec3 param_2 = world;\n        vec3 param_3 = n;\n        vec3 param_4 = l;\n        float _3104 = fa_shadow_cascade(param_1, param_2, param_3, param_4);\n        s = _3104;\n        if (_3104 >= 0.0)\n        {\n            break;\n        }\n        ci++;\n    }\n    if (s < 0.0)\n    {\n        return 1.0;\n    }\n    if (fa_shadows[25].y > 0.0)\n    {\n        float _3129;\n        if (ci > 0)\n        {\n            int param_5 = ci - 1;\n            _3129 = fa_shadow_split_at(param_5);\n        }\n        else\n        {\n            _3129 = fa_shadows[28].w;\n        }\n        int param_6 = ci;\n        float _3148 = fa_shadows[25].y * max(fa_shadow_split_at(param_6) - _3129, 9.9999997473787516355514526367188e-05);\n        int param_7 = ci;\n        float _3159 = clamp((_3037 - (fa_shadow_split_at(param_7) - _3148)) / _3148, 0.0, 1.0);\n        if (_3159 > 0.0)\n        {\n            float s2 = 1.0;\n            if ((ci + 1) < _3022)\n            {\n                int param_8 = ci + 1;\n                vec3 param_9 = world;\n                vec3 param_10 = n;\n                vec3 param_11 = l;\n                float _3180 = fa_shadow_cascade(param_8, param_9, param_10, param_11);\n                s2 = _3180;\n                if (_3180 < 0.0)\n                {\n                    s2 = s;\n                }\n            }\n            s = mix(s, s2, _3159);\n        }\n    }\n    return s;\n}\n\nfloat fa_shadow_factor(vec3 n, vec3 l)\n{\n    vec3 param = fa_world_pos;\n    vec3 param_1 = n;\n    vec3 param_2 = l;\n    return fa_shadow_sun(param, param_1, param_2);\n}\n\nfloat fa_shadow_local(int li, vec3 lpos, vec3 world, vec3 n, vec3 l)\n{\n    bool _2702 = fa_mesh_fs_params[5].z < 0.5;\n    bool _2709;\n    if (!_2702)\n    {\n        _2709 = fa_shadows[29].x < 0.5;\n    }\n    else\n    {\n        _2709 = _2702;\n    }\n    if (_2709)\n    {\n        return 1.0;\n    }\n    int param = (int(fa_shadows[29].x + 0.5) - 1) + li;\n    vec4 _2722 = fa_light_texel(param);\n    float _2723 = _2722.x;\n    if (_2723 < 0.0)\n    {\n        return 1.0;\n    }\n    int _2732 = int(_2723 + 0.5);\n    int param_1 = _2732;\n    vec4 _2736 = fa_light_texel(param_1);\n    int param_2 = _2732 + 1;\n    vec4 _2741 = fa_light_texel(param_2);\n    float fade = 1.0;\n    float _2744 = _2736.y;\n    if (_2744 > 0.0)\n    {\n        float _2761 = 1.0 - smoothstep(0.75 * _2744, _2744, length(world - fa_shadows[27].xyz));\n        fade = _2761;\n        if (_2761 <= 0.0)\n        {\n            return 1.0;\n        }\n    }\n    int face = 0;\n    if (_2736.x > 1.5)\n    {\n        vec3 param_3 = world - lpos;\n        face = fa_cube_face(param_3);\n    }\n    int _2785 = (_2732 + 2) + (face * 6);\n    int param_4 = _2785;\n    int param_5 = _2785 + 1;\n    int param_6 = _2785 + 3;\n    vec4 _2799 = fa_light_texel(param_6);\n    int param_7 = _2785 + 4;\n    vec4 _2804 = fa_light_texel(param_7);\n    int param_8 = _2785 + 5;\n    vec4 _2809 = fa_light_texel(param_8);\n    float _2821 = _2809.x * max(dot(_2799, vec4(world, 1.0)), 0.001000000047497451305389404296875);\n    float _2826 = clamp(dot(n, l), 0.0, 1.0);\n    float _2849 = clamp(dot(n, _2799.xyz), -1.0, 1.0);\n    float _2868 = min(sqrt(1.0 - (_2849 * _2849)) / max(abs(dot(n, world - lpos)) / max(dot(_2799, vec4(world, 1.0)), 0.001000000047497451305389404296875), 0.20000000298023223876953125), 4.0);\n    float _2871 = _2741.y;\n    float _2873;\n    if (_2871 > 0.0)\n    {\n        _2873 = _2871;\n    }\n    else\n    {\n        _2873 = 1.5 * _2821;\n    }\n    vec4 _2893 = vec4(world + (n * (_2873 * sqrt(1.0 - (_2826 * _2826)))), 1.0);\n    float _2897 = dot(_2799, _2893);\n    float _2900 = _2809.y;\n    if (_2897 < _2900)\n    {\n        return 1.0;\n    }\n    vec2 _2915 = vec2(dot(fa_light_texel(param_4), _2893), dot(fa_light_texel(param_5), _2893)) / vec2(_2897);\n    float _2917 = _2915.x;\n    bool _2920 = _2917 < _2804.x;\n    bool _2929;\n    if (!_2920)\n    {\n        _2929 = _2917 > _2804.z;\n    }\n    else\n    {\n        _2929 = _2920;\n    }\n    bool _2938;\n    if (!_2929)\n    {\n        _2938 = _2915.y < _2804.y;\n    }\n    else\n    {\n        _2938 = _2929;\n    }\n    bool _2947;\n    if (!_2938)\n    {\n        _2947 = _2915.y > _2804.w;\n    }\n    else\n    {\n        _2947 = _2938;\n    }\n    if (_2947)\n    {\n        return 1.0;\n    }\n    float _2953 = _2741.x;\n    float _2955;\n    if (_2953 > 0.0)\n    {\n        _2955 = _2953;\n    }\n    else\n    {\n        _2955 = 1.5 * _2821;\n    }\n    vec2 param_9 = _2915;\n    vec4 param_10 = _2804;\n    float param_11 = _2897 - (_2955 * (1.0 + (0.5 * _2868)));\n    float param_12 = _2821;\n    float param_13 = 1.0;\n    float param_14 = _2809.z * 0.25;\n    float param_15 = (_2821 * min(_2868, 3.0)) * 0.5;\n    vec3 param_16 = vec3(1.0, _2900, _2809.z);\n    int param_17 = int(_2736.z + 0.5);\n    float param_18 = _2736.w;\n    return mix(1.0, fa_shadow_filter(param_9, param_10, param_11, param_12, param_13, param_14, param_15, param_16, param_17, param_18), fade);\n}\n\nfloat fa_contact_shadow(int li, vec3 world, vec3 gn, vec3 l, float dist)\n{\n    bool _4510 = fa_mesh_fs_params[24].x < 0.5;\n    bool _4517;\n    if (!_4510)\n    {\n        _4517 = fa_shadows[29].x < 0.5;\n    }\n    else\n    {\n        _4517 = _4510;\n    }\n    if (_4517)\n    {\n        return 1.0;\n    }\n    int param = (int(fa_shadows[29].x + 0.5) - 1) + li;\n    vec4 _4530 = fa_light_texel(param);\n    float _4531 = _4530.y;\n    float len = _4531;\n    if (_4531 <= 0.0)\n    {\n        return 1.0;\n    }\n    float _4543 = length(world - fa_mesh_fs_params[0].xyz);\n    float _4553 = 1.0 - smoothstep(0.5 * fa_mesh_fs_params[25].x, fa_mesh_fs_params[25].x, _4543);\n    if (_4553 <= 0.0)\n    {\n        return 1.0;\n    }\n    float _4559 = len;\n    float _4562 = min(_4559, 0.89999997615814208984375 * dist);\n    len = _4562;\n    float _4567 = 0.004999999888241291046142578125 + (0.0030000000260770320892333984375 * _4543);\n    float _4572 = _4567 + (0.5 * _4562);\n    vec3 _4578 = world + (gn * _4567);\n    float _4580 = fa_shadow_noise();\n    float occ = 0.0;\n    float _4644;\n    for (int k = 0; k < 12; k++)\n    {\n        float _4595 = (float(k) + _4580) * 0.083333335816860198974609375;\n        vec3 _4603 = _4578 + (l * (_4595 * len));\n        vec4 _4609 = vec4(_4603, 1.0);\n        float _4615 = dot(fa_mesh_fs_params[28], _4609);\n        if (_4615 < 9.9999997473787516355514526367188e-05)\n        {\n            break;\n        }\n        vec2 _4635 = vec2(dot(fa_mesh_fs_params[26], _4609), dot(fa_mesh_fs_params[27], _4609)) / vec2(_4615);\n        float _4639 = _4635.x * 0.5;\n        float _4640 = _4639 + 0.5;\n        if (fa_mesh_fs_params[24].y > 0.5)\n        {\n            _4644 = (_4635.y * 0.5) + 0.5;\n        }\n        else\n        {\n            _4644 = 0.5 - (_4635.y * 0.5);\n        }\n        bool _4660 = _4640 < 0.0;\n        bool _4667;\n        if (!_4660)\n        {\n            _4667 = _4640 >= 1.0;\n        }\n        else\n        {\n            _4667 = _4660;\n        }\n        bool _4674;\n        if (!_4667)\n        {\n            _4674 = _4644 < 0.0;\n        }\n        else\n        {\n            _4674 = _4667;\n        }\n        bool _4681;\n        if (!_4674)\n        {\n            _4681 = _4644 >= 1.0;\n        }\n        else\n        {\n            _4681 = _4674;\n        }\n        if (_4681)\n        {\n            break;\n        }\n        vec4 _4700 = texelFetch(fa_screen_tex_fa_shadow_smp, ivec2(vec2(_4640, _4644) * fa_mesh_fs_params[24].zw), 0);\n        if (_4700.w < 0.5)\n        {\n            continue;\n        }\n        float _4719 = (dot(fa_mesh_fs_params[29].xyz, _4603) + fa_mesh_fs_params[29].w) - _4700.x;\n        if ((_4719 > _4567) && (_4719 < _4572))\n        {\n            occ = max(occ, (1.0 - (_4595 * _4595)) * smoothstep(0.0, 0.0500000007450580596923828125, min(min(_4640, 0.5 - _4639), min(_4644, 1.0 - _4644))));\n        }\n    }\n    return 1.0 - (occ * _4553);\n}\n\nLightSample fa_light_shadowed(int li, vec3 world_pos, vec3 gn)\n{\n    int param = li;\n    float _5185 = fa_baked_keep(param);\n    if (_5185 <= 0.0)\n    {\n        int param_1 = li;\n        return LightSample(vec3(0.0, 1.0, 0.0), vec3(0.0), 0.0, 1.0, 0.0, int(fa_light_type(param_1) + 0.5));\n    }\n    int param_2 = li;\n    vec3 param_3 = world_pos;\n    vec3 param_4 = gn;\n    LightSample _5211 = fa_light_sample_n(param_2, param_3, param_4);\n    vec3 _7748 = _5211.color;\n    float _7749 = _5211.attenuation;\n    float _7750 = _5211.shadow;\n    bool _5214 = _5211.type == 0;\n    if (_5214 && (li == 0))\n    {\n        vec3 param_5 = gn;\n        vec3 param_6 = _5211.direction;\n        float _5225 = fa_shadow_factor(param_5, param_6);\n        _7750 = _5225;\n        _7748 *= _5225;\n    }\n    else\n    {\n        bool _5236 = _5211.type != 0;\n        bool _5242;\n        if (_5236)\n        {\n            _5242 = _7749 > 0.0;\n        }\n        else\n        {\n            _5242 = _5236;\n        }\n        if (_5242)\n        {\n            int param_7 = li;\n            int param_8 = fa_light_base(param_7);\n            int param_9 = li;\n            vec3 param_10 = fa_light_texel(param_8).xyz;\n            vec3 param_11 = world_pos;\n            vec3 param_12 = gn;\n            vec3 param_13 = _5211.direction;\n            float _5261 = fa_shadow_local(param_9, param_10, param_11, param_12, param_13);\n            _7750 = _5261;\n            _7748 *= _5261;\n        }\n    }\n    bool _5271 = fa_mesh_fs_params[24].x > 0.5;\n    bool _5277;\n    if (_5271)\n    {\n        _5277 = _7749 > 0.0;\n    }\n    else\n    {\n        _5277 = _5271;\n    }\n    if (_5277)\n    {\n        float _5284;\n        if (_5214)\n        {\n            _5284 = 1000000000.0;\n        }\n        else\n        {\n            _5284 = _5211._distance;\n        }\n        int param_14 = li;\n        vec3 param_15 = world_pos;\n        vec3 param_16 = gn;\n        vec3 param_17 = _5211.direction;\n        float param_18 = _5284;\n        float _5302 = fa_contact_shadow(param_14, param_15, param_16, param_17, param_18);\n        _7750 *= _5302;\n        _7748 *= _5302;\n    }\n    float _5315 = _7749;\n    float _5316 = _5315 * _5185;\n    _7749 = _5316;\n    vec3 _5320 = _7748;\n    vec3 _5321 = _5320 * _5185;\n    _7748 = _5321;\n    return LightSample(_5211.direction, _5321, _5316, _7750, _5211._distance, _5211.type);\n}\n\nvec3 fa_ltc_tangent(vec3 n, vec3 v)\n{\n    vec3 _5355 = v - (n * dot(v, n));\n    vec3 t = _5355;\n    float _5359 = dot(_5355, _5355);\n    float l2 = _5359;\n    if (_5359 < 1.0000000133514319600180897396058e-10)\n    {\n        vec3 _5369;\n        if (abs(n.z) < 0.999000012874603271484375)\n        {\n            _5369 = cross(n, vec3(0.0, 0.0, 1.0));\n        }\n        else\n        {\n            _5369 = cross(n, vec3(1.0, 0.0, 0.0));\n        }\n        t = _5369;\n        l2 = dot(_5369, _5369);\n    }\n    return t * inversesqrt(l2);\n}\n\nvec3 fa_ltc_local(vec3 t1, vec3 n, vec3 p)\n{\n    return vec3(dot(t1, p), dot(cross(n, t1), p), dot(n, p));\n}\n\nvec3 fa_ltc_edge_vector(vec3 a, vec3 b)\n{\n    float _5404 = dot(a, a);\n    float _5408 = dot(b, b);\n    if ((_5404 < 1.0000000195414813782625560981111e-24) || (_5408 < 1.0000000195414813782625560981111e-24))\n    {\n        return vec3(0.0);\n    }\n    vec3 _5422 = a * inversesqrt(_5404);\n    vec3 _5427 = b * inversesqrt(_5408);\n    float _5431 = dot(_5422, _5427);\n    float _5434 = abs(_5431);\n    float g = (((((((((((0.0416471660137176513671875 * _5434) - 0.1924748718738555908203125) * _5434) + 0.4179156124591827392578125) * _5434) - 0.616057217121124267578125) * _5434) + 0.777722418308258056640625) * _5434) - 0.999542415142059326171875) * _5434) + 1.570791721343994140625;\n    if (_5431 < 0.0)\n    {\n        g = (3.1415927410125732421875 * inversesqrt(max(1.0 - (_5431 * _5431), 1.0000000116860974230803549289703e-07))) - g;\n    }\n    return cross(_5422, _5427) * g;\n}\n\nvoid fa_ltc_clip_edge(vec3 a, vec3 b, inout vec3 sum, inout vec3 leave, inout vec3 enter, inout vec2 seen)\n{\n    bool _5491 = a.z > 0.0;\n    bool _5495 = b.z > 0.0;\n    if (_5491 && _5495)\n    {\n        vec3 param = a;\n        vec3 param_1 = b;\n        sum += fa_ltc_edge_vector(param, param_1);\n    }\n    else\n    {\n        if (_5491 != _5495)\n        {\n            vec3 _5530 = a + ((b - a) * (a.z / (a.z - b.z)));\n            _5530.z = 0.0;\n            if (_5491)\n            {\n                vec3 param_2 = a;\n                vec3 param_3 = _5530;\n                sum += fa_ltc_edge_vector(param_2, param_3);\n                leave = _5530;\n                seen.x = 1.0;\n            }\n            else\n            {\n                vec3 param_4 = _5530;\n                vec3 param_5 = b;\n                sum += fa_ltc_edge_vector(param_4, param_5);\n                enter = _5530;\n                seen.y = 1.0;\n            }\n        }\n    }\n}\n\nfloat fa_ltc_quad(vec4 abcd, vec3 p0, vec3 p1, vec3 p2, vec3 p3)\n{\n    vec3 _5579 = vec3((abcd.x * p0.x) + (abcd.y * p0.z), p0.y, (abcd.z * p0.x) + (abcd.w * p0.z));\n    vec3 _5605 = vec3((abcd.x * p1.x) + (abcd.y * p1.z), p1.y, (abcd.z * p1.x) + (abcd.w * p1.z));\n    vec3 _5631 = vec3((abcd.x * p2.x) + (abcd.y * p2.z), p2.y, (abcd.z * p2.x) + (abcd.w * p2.z));\n    vec3 _5657 = vec3((abcd.x * p3.x) + (abcd.y * p3.z), p3.y, (abcd.z * p3.x) + (abcd.w * p3.z));\n    vec3 sum = vec3(0.0);\n    vec3 leave = vec3(0.0);\n    vec3 enter = vec3(0.0);\n    vec3 param = _5579;\n    vec3 param_1 = _5605;\n    vec3 param_2 = vec3(0.0);\n    vec3 param_3 = vec3(0.0);\n    vec3 param_4 = vec3(0.0);\n    vec2 param_5 = vec2(0.0);\n    fa_ltc_clip_edge(param, param_1, param_2, param_3, param_4, param_5);\n    sum = param_2;\n    leave = param_3;\n    enter = param_4;\n    vec3 param_6 = _5605;\n    vec3 param_7 = _5631;\n    vec3 param_8 = param_2;\n    vec3 param_9 = param_3;\n    vec3 param_10 = param_4;\n    vec2 param_11 = param_5;\n    fa_ltc_clip_edge(param_6, param_7, param_8, param_9, param_10, param_11);\n    sum = param_8;\n    leave = param_9;\n    enter = param_10;\n    vec3 param_12 = _5631;\n    vec3 param_13 = _5657;\n    vec3 param_14 = param_8;\n    vec3 param_15 = param_9;\n    vec3 param_16 = param_10;\n    vec2 param_17 = param_11;\n    fa_ltc_clip_edge(param_12, param_13, param_14, param_15, param_16, param_17);\n    sum = param_14;\n    leave = param_15;\n    enter = param_16;\n    vec3 param_18 = _5657;\n    vec3 param_19 = _5579;\n    vec3 param_20 = param_14;\n    vec3 param_21 = param_15;\n    vec3 param_22 = param_16;\n    vec2 param_23 = param_17;\n    fa_ltc_clip_edge(param_18, param_19, param_20, param_21, param_22, param_23);\n    sum = param_20;\n    leave = param_21;\n    enter = param_22;\n    if ((param_23.x * param_23.y) > 0.5)\n    {\n        vec3 param_24 = leave;\n        vec3 param_25 = enter;\n        sum += fa_ltc_edge_vector(param_24, param_25);\n    }\n    return sum.z * 0.15915493667125701904296875;\n}\n\nfloat fa_ltc_rect(vec4 abcd, vec3 center, vec3 ex, vec3 ey)\n{\n    vec4 param = abcd;\n    vec3 param_1 = (center - ex) - ey;\n    vec3 param_2 = (center + ex) - ey;\n    vec3 param_3 = (center + ex) + ey;\n    vec3 param_4 = (center - ex) + ey;\n    return abs(fa_ltc_quad(param, param_1, param_2, param_3, param_4));\n}\n\nfloat fa_area_form(vec4 m, float shape, vec3 pc, vec3 ex, vec3 ey)\n{\n    if ((shape < 0.5) || (shape > 1.5))\n    {\n        vec4 param = m;\n        vec3 param_1 = pc;\n        vec3 param_2 = ex;\n        vec3 param_3 = ey;\n        return fa_ltc_rect(param, param_1, param_2, param_3);\n    }\n    vec3 _5806 = (pc + (ex * 0.92387950420379638671875)) + (ey * 0.3826834261417388916015625);\n    vec3 _5830 = (pc - (ex * 0.92387950420379638671875)) + (ey * 0.3826834261417388916015625);\n    vec3 _5846 = (pc - (ex * 0.3826834261417388916015625)) - (ey * 0.92387950420379638671875);\n    vec4 param_4 = m;\n    vec3 param_5 = _5806;\n    vec3 param_6 = (pc + (ex * 0.3826834261417388916015625)) + (ey * 0.92387950420379638671875);\n    vec3 param_7 = (pc - (ex * 0.3826834261417388916015625)) + (ey * 0.92387950420379638671875);\n    vec3 param_8 = _5830;\n    vec4 param_9 = m;\n    vec3 param_10 = _5806;\n    vec3 param_11 = _5830;\n    vec3 param_12 = (pc - (ex * 0.92387950420379638671875)) - (ey * 0.3826834261417388916015625);\n    vec3 param_13 = _5846;\n    vec4 param_14 = m;\n    vec3 param_15 = _5806;\n    vec3 param_16 = _5846;\n    vec3 param_17 = (pc + (ex * 0.3826834261417388916015625)) - (ey * 0.92387950420379638671875);\n    vec3 param_18 = (pc + (ex * 0.92387950420379638671875)) - (ey * 0.3826834261417388916015625);\n    return abs((fa_ltc_quad(param_4, param_5, param_6, param_7, param_8) + fa_ltc_quad(param_9, param_10, param_11, param_12, param_13)) + fa_ltc_quad(param_14, param_15, param_16, param_17, param_18));\n}\n\nvec2 fa_ltc_uv(float roughness, float ndv)\n{\n    return ((vec2(clamp((roughness - 0.0500000007450580596923828125) * 1.0526316165924072265625, 0.0, 1.0), sqrt(clamp(1.0 - ndv, 0.0, 1.0))) * 63.0) + vec2(0.5)) * vec2(0.015625);\n}\n\nvec3 fa_area_shade(int li, vec3 world_pos, vec3 n, vec3 v, vec3 diffuse_color, vec3 f0, float f90, float roughness, float ndv, float window)\n{\n    int param = li;\n    int _5904 = fa_light_base(param);\n    int param_1 = _5904;\n    int param_2 = _5904 + 1;\n    int param_3 = _5904 + 2;\n    int param_4 = _5904 + 4;\n    vec4 _5926 = fa_light_texel(param_4);\n    int param_5 = _5904 + 5;\n    vec4 _5931 = fa_light_texel(param_5);\n    int param_6 = _5904 + 6;\n    vec4 _5936 = fa_light_texel(param_6);\n    float _5937 = _5936.w;\n    vec3 _5942 = fa_light_texel(param_1).xyz - world_pos;\n    bool _5944 = _5937 < 1.5;\n    bool _5951;\n    if (_5944)\n    {\n        _5951 = dot(normalize(fa_light_texel(param_3).xyz), _5942) >= 0.0;\n    }\n    else\n    {\n        _5951 = _5944;\n    }\n    if (_5951)\n    {\n        return vec3(0.0);\n    }\n    bool _5960 = (_5937 > 0.5) && _5944;\n    float _5964 = _5960 ? 1.0539000034332275390625 : 1.0;\n    vec3 _5967 = _5926.xyz;\n    float _5969 = _5926.w;\n    vec3 _5975 = _5931.xyz;\n    float _5977 = _5931.w;\n    vec3 up = _5975 * (_5977 * _5964);\n    float _5983;\n    if (_5960)\n    {\n        _5983 = (3.1415927410125732421875 * _5969) * _5969;\n    }\n    else\n    {\n        _5983 = (4.0 * _5969) * _5977;\n    }\n    if (_5937 > 1.5)\n    {\n        vec3 _6009 = cross(_5967, -_5942);\n        vec3 perp = _6009;\n        float _6013 = dot(_6009, _6009);\n        vec3 _6016;\n        if (_6013 > 1.0000000133514319600180897396058e-10)\n        {\n            _6016 = perp * inversesqrt(_6013);\n        }\n        else\n        {\n            _6016 = _5975;\n        }\n        perp = _6016;\n        up = _6016 * _5977;\n    }\n    float _6037 = max(_5983, 9.9999999747524270787835121154785e-07);\n    vec3 param_7 = n;\n    vec3 param_8 = v;\n    vec3 _6047 = fa_ltc_tangent(param_7, param_8);\n    vec3 param_9 = _6047;\n    vec3 param_10 = n;\n    vec3 param_11 = _5942;\n    vec3 _6055 = fa_ltc_local(param_9, param_10, param_11);\n    vec3 param_12 = _6047;\n    vec3 param_13 = n;\n    vec3 param_14 = _5967 * (_5969 * _5964);\n    vec3 _6063 = fa_ltc_local(param_12, param_13, param_14);\n    vec3 param_15 = _6047;\n    vec3 param_16 = n;\n    vec3 param_17 = up;\n    vec3 _6071 = fa_ltc_local(param_15, param_16, param_17);\n    vec4 param_18 = vec4(1.0, 0.0, 0.0, 1.0);\n    float param_19 = _5937;\n    vec3 param_20 = _6055;\n    vec3 param_21 = _6063;\n    vec3 param_22 = _6071;\n    float param_23 = roughness;\n    float param_24 = ndv;\n    vec2 _6090 = fa_ltc_uv(param_23, param_24) * 64.0;\n    vec2 param_25 = _6090;\n    vec2 param_26 = _6090 + vec2(64.0, 0.0);\n    vec4 _6100 = fa_atlas_fetch(param_26);\n    vec4 param_27 = fa_atlas_fetch(param_25);\n    float param_28 = _5937;\n    vec3 param_29 = _6055;\n    vec3 param_30 = _6063;\n    vec3 param_31 = _6071;\n    return (((diffuse_color * fa_area_form(param_18, param_19, param_20, param_21, param_22)) + (((f0 * _6100.x) + ((vec3(f90) - f0) * _6100.y)) * fa_area_form(param_27, param_28, param_29, param_30, param_31))) * fa_light_texel(param_2).xyz) * ((((3.1415927410125732421875 * dot(_5942, _5942)) + _6037) / _6037) * window);\n}\n\nvec3 fa_light_rgb(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 1;\n    return fa_light_texel(param_1).xyz;\n}\n\nfloat fa_d_charlie(float alpha, float ndh)\n{\n    float _4247 = 1.0 / alpha;\n    return ((2.0 + _4247) * pow(sqrt(max(1.0 - (ndh * ndh), 9.9999997473787516355514526367188e-05)), _4247)) * 0.15915493667125701904296875;\n}\n\nfloat fa_v_ashikhmin(float ndl, float ndv)\n{\n    return clamp(0.25 / max((ndl + ndv) - (ndl * ndv), 9.9999997473787516355514526367188e-05), 0.0, 1.0);\n}\n\nfloat fa_layers_coat(FaLayers L, vec3 l, vec3 h, float vdh)\n{\n    float _4282 = max(dot(L.nc, l), 0.0);\n    float _4288 = max(dot(L.nc, h), 0.0);\n    float _4297 = ((_4288 * _4288) * (L.coat_a2 - 1.0)) + 1.0;\n    return (((L.coat * (0.039999999105930328369140625 + (0.959999978542327880859375 * pow(clamp(1.0 - vdh, 0.0, 1.0), 5.0)))) * (((L.coat_a2 / ((3.1415927410125732421875 * _4297) * _4297)) * (0.5 / max(mix((2.0 * _4282) * L.coat_ndv, _4282 + L.coat_ndv, L.coat_alpha), 9.9999997473787516355514526367188e-05))) * 3.1415927410125732421875)) * step(9.9999997473787516355514526367188e-05, _4282)) * _4282;\n}\n\nvec3 fa_area_layers(FaLayers L, int li, vec3 world_pos, vec3 n, vec3 v, vec3 l, vec3 diffuse_color, vec3 f0, float roughness, float ndv, float window)\n{\n    int param = li;\n    vec3 param_1 = world_pos;\n    vec3 param_2 = n;\n    vec3 param_3 = v;\n    vec3 param_4 = diffuse_color;\n    vec3 param_5 = f0;\n    float param_6 = L.f90;\n    float param_7 = roughness;\n    float param_8 = ndv;\n    float param_9 = window;\n    float _6168;\n    if (L.sheen_on)\n    {\n        _6168 = L.sheen_scale;\n    }\n    else\n    {\n        _6168 = 1.0;\n    }\n    vec3 result = fa_area_shade(param, param_1, param_2, param_3, param_4, param_5, param_6, param_7, param_8, param_9) * (L.keep * _6168);\n    vec3 _6181 = normalize(l + v);\n    int param_10 = li;\n    vec3 _6192 = fa_light_rgb(param_10) * window;\n    if (L.sheen_on)\n    {\n        float _6201 = max(dot(n, l), 0.0);\n        float param_11 = L.sheen_alpha;\n        float param_12 = max(dot(n, _6181), 0.0);\n        float param_13 = _6201;\n        float param_14 = ndv;\n        result += ((L.sheen * _6192) * (((((fa_d_charlie(param_11, param_12) * fa_v_ashikhmin(param_13, param_14)) * 3.1415927410125732421875) * step(9.9999997473787516355514526367188e-05, _6201)) * _6201) * L.keep));\n    }\n    if (L.coat > 0.0)\n    {\n        FaLayers param_15 = L;\n        vec3 param_16 = l;\n        vec3 param_17 = _6181;\n        float param_18 = max(dot(v, _6181), 0.0);\n        result += (_6192 * fa_layers_coat(param_15, param_16, param_17, param_18));\n    }\n    return result;\n}\n\nfloat fa_d_ggx_aniso(float ndh, float tdh, float bdh, float at, float ab)\n{\n    float _4150 = tdh / at;\n    float _4154 = bdh / ab;\n    float _4166 = ((_4150 * _4150) + (_4154 * _4154)) + (ndh * ndh);\n    return 1.0 / ((((3.1415927410125732421875 * at) * ab) * _4166) * _4166);\n}\n\nfloat fa_lambda_ggx_aniso(float n, float t, float b, float at, float ab)\n{\n    return 0.5 * (sqrt(1.0 + (((((at * at) * t) * t) + (((ab * ab) * b) * b)) / max(n * n, 9.9999999392252902907785028219223e-09))) - 1.0);\n}\n\nfloat fa_v_ggx_aniso(float ndl, float ndv, float tdv, float bdv, float tdl, float bdl, float at, float ab)\n{\n    float param = ndv;\n    float param_1 = tdv;\n    float param_2 = bdv;\n    float param_3 = at;\n    float param_4 = ab;\n    float param_5 = ndl;\n    float param_6 = tdl;\n    float param_7 = bdl;\n    float param_8 = at;\n    float param_9 = ab;\n    return clamp(1.0 / ((4.0 * max(ndl * ndv, 9.9999997473787516355514526367188e-05)) * ((1.0 + fa_lambda_ggx_aniso(param, param_1, param_2, param_3, param_4)) + fa_lambda_ggx_aniso(param_5, param_6, param_7, param_8, param_9))), 0.0, 1.0);\n}\n\nvec3 fa_layers_light(FaLayers L, vec3 diffuse_color, vec3 f0, vec3 n, vec3 v, vec3 l, vec3 h, float ndl, float ndv, float ndh, float vdh, float alpha, float a2)\n{\n    float _4346 = step(9.9999997473787516355514526367188e-05, ndl);\n    float d_ggx;\n    float vis;\n    if (L.aniso != 0.0)\n    {\n        float param = ndh;\n        float param_1 = dot(L.t, h);\n        float param_2 = dot(L.b, h);\n        float param_3 = L.at;\n        float param_4 = L.ab;\n        d_ggx = fa_d_ggx_aniso(param, param_1, param_2, param_3, param_4);\n        float param_5 = ndl;\n        float param_6 = ndv;\n        float param_7 = dot(L.t, v);\n        float param_8 = dot(L.b, v);\n        float param_9 = dot(L.t, l);\n        float param_10 = dot(L.b, l);\n        float param_11 = L.at;\n        float param_12 = L.ab;\n        vis = fa_v_ggx_aniso(param_5, param_6, param_7, param_8, param_9, param_10, param_11, param_12);\n    }\n    else\n    {\n        float _4425 = ((ndh * ndh) * (a2 - 1.0)) + 1.0;\n        d_ggx = a2 / ((3.1415927410125732421875 * _4425) * _4425);\n        vis = 0.5 / max(mix((2.0 * ndl) * ndv, ndl + ndv, alpha), 9.9999997473787516355514526367188e-05);\n    }\n    vec3 base = diffuse_color + (((f0 + ((vec3(L.f90) - f0) * pow(clamp(1.0 - vdh, 0.0, 1.0), 5.0))) * ((d_ggx * vis) * 3.1415927410125732421875)) * _4346);\n    if (L.sheen_on)\n    {\n        float param_13 = L.sheen_alpha;\n        float param_14 = ndh;\n        float param_15 = ndl;\n        float param_16 = ndv;\n        base = (base * L.sheen_scale) + (L.sheen * (((fa_d_charlie(param_13, param_14) * fa_v_ashikhmin(param_15, param_16)) * 3.1415927410125732421875) * _4346));\n    }\n    vec3 result = base * (L.keep * ndl);\n    if (L.coat > 0.0)\n    {\n        FaLayers param_17 = L;\n        vec3 param_18 = l;\n        vec3 param_19 = h;\n        float param_20 = vdh;\n        result += vec3(fa_layers_coat(param_17, param_18, param_19, param_20));\n    }\n    return result;\n}\n\nvec2 fa_env_brdf(float rough, float ndv)\n{\n    vec4 _3556 = (vec4(-1.0, -0.0274999998509883880615234375, -0.572000026702880859375, 0.02199999988079071044921875) * rough) + vec4(1.0, 0.0425000004470348358154296875, 1.03999996185302734375, -0.039999999105930328369140625);\n    float _3559 = _3556.x;\n    return (vec2(-1.03999996185302734375, 1.03999996185302734375) * ((min(_3559 * _3559, exp2((-9.27999973297119140625) * ndv)) * _3559) + _3556.y)) + _3556.zw;\n}\n\nvec3 fa_environment(vec3 d, float rough)\n{\n    if (fa_mesh_fs_params[11].w > 0.5)\n    {\n        return textureLod(fa_env_tex_fa_env_smp, d, clamp(rough, 0.0, 1.0) * fa_mesh_fs_params[12].w).xyz;\n    }\n    float _3410 = rough * rough;\n    float _3440 = 0.60000002384185791015625 * _3410;\n    return mix(mix(fa_mesh_fs_params[12].xyz * 0.550000011920928955078125, mix(fa_mesh_fs_params[12].xyz, fa_mesh_fs_params[11].xyz, vec3(pow(clamp(d.y * (1.0 - (0.699999988079071044921875 * _3410)), 0.0, 1.0), 0.550000011920928955078125))), vec3(smoothstep((-0.0500000007450580596923828125) - _3440, 0.0500000007450580596923828125 + _3440, d.y))), ((fa_mesh_fs_params[11].xyz + fa_mesh_fs_params[12].xyz) * 0.5) * 0.800000011920928955078125, vec3(_3410 * 0.60000002384185791015625));\n}\n\nvec3 fa_layers_ibl(FaLayers L, vec3 n, vec3 v, vec3 f0, float roughness)\n{\n    vec3 rn = n;\n    if (L.aniso != 0.0)\n    {\n        vec3 _4033;\n        if (L.aniso >= 0.0)\n        {\n            _4033 = L.b;\n        }\n        else\n        {\n            _4033 = L.t;\n        }\n        rn = normalize(mix(n, cross(cross(_4033, v), _4033), vec3(abs(L.aniso))));\n    }\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05);\n    vec2 _4066 = fa_env_brdf(param, param_1);\n    vec3 param_2 = reflect(-v, rn);\n    float param_3 = roughness;\n    vec3 result = (fa_environment(param_2, param_3) * ((f0 * _4066.x) + (vec3(L.f90) * _4066.y))) * L.base_scale;\n    if (L.sheen_on)\n    {\n        vec3 param_4 = n;\n        float param_5 = L.sheen_rough;\n        result += ((L.sheen * (L.sheen_e * L.keep)) * fa_environment(param_4, param_5));\n    }\n    if (L.coat > 0.0)\n    {\n        float param_6 = L.coat_rough;\n        float param_7 = L.coat_ndv;\n        vec2 _4121 = fa_env_brdf(param_6, param_7);\n        vec3 param_8 = reflect(-v, L.nc);\n        float param_9 = L.coat_rough;\n        result += (fa_environment(param_8, param_9) * (L.coat * ((0.039999999105930328369140625 * _4121.x) + _4121.y)));\n    }\n    return result;\n}\n\nvec3 fa_sky_reflection(vec3 n, vec3 v, vec3 f0, float roughness)\n{\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05);\n    vec2 _3598 = fa_env_brdf(param, param_1);\n    vec3 param_2 = reflect(-v, n);\n    float param_3 = roughness;\n    return fa_environment(param_2, param_3) * ((f0 * _3598.x) + vec3(_3598.y));\n}\n\nvec2 fa_xm_size(int k)\n{\n    return max(floor(fa_mesh_fs_params[24].zw / vec2(exp2(float(k)))), vec2(1.0));\n}\n\nvec2 fa_xm_origin(int k)\n{\n    if (k == 0)\n    {\n        return vec2(0.0);\n    }\n    float y = 0.0;\n    for (int j = 1; j < k; j++)\n    {\n        int param = j;\n        y += fa_xm_size(param).y;\n    }\n    return vec2(fa_mesh_fs_params[24].z, y);\n}\n\nvec3 fa_xm_texel(vec2 size, vec2 origin, vec2 p)\n{\n    return texelFetch(fa_screen_tex_fa_shadow_smp, ivec2(origin + clamp(p, vec2(0.0), size - vec2(1.0))), 0).xyz;\n}\n\nvec3 fa_xm_level(int k, vec2 uv)\n{\n    int param = k;\n    vec2 _4823 = fa_xm_size(param);\n    int param_1 = k;\n    vec2 _4827 = fa_xm_origin(param_1);\n    vec2 _4833 = (uv * _4823) - vec2(0.5);\n    vec2 _4836 = fract(_4833);\n    vec2 _4839 = floor(_4833);\n    vec2 param_2 = _4823;\n    vec2 param_3 = _4827;\n    vec2 param_4 = _4839;\n    vec2 param_5 = _4823;\n    vec2 param_6 = _4827;\n    vec2 param_7 = _4839 + vec2(1.0, 0.0);\n    vec2 param_8 = _4823;\n    vec2 param_9 = _4827;\n    vec2 param_10 = _4839 + vec2(0.0, 1.0);\n    vec2 param_11 = _4823;\n    vec2 param_12 = _4827;\n    vec2 param_13 = _4839 + vec2(1.0);\n    vec3 _4881 = vec3(_4836.x);\n    return mix(mix(fa_xm_texel(param_2, param_3, param_4), fa_xm_texel(param_5, param_6, param_7), _4881), mix(fa_xm_texel(param_8, param_9, param_10), fa_xm_texel(param_11, param_12, param_13), _4881), vec3(_4836.y));\n}\n\nvec3 fa_xm_sample(vec2 uv, float lod)\n{\n    float _4900 = max(fa_mesh_fs_params[31].w - 1.0, 0.0);\n    float _4904 = clamp(lod, 0.0, _4900);\n    int _4908 = int(floor(_4904));\n    int param = _4908;\n    vec2 param_1 = uv;\n    vec3 c = fa_xm_level(param, param_1);\n    float _4918 = float(_4908);\n    float _4919 = _4904 - _4918;\n    bool _4921 = _4919 > 0.001000000047497451305389404296875;\n    bool _4928;\n    if (_4921)\n    {\n        _4928 = _4918 < _4900;\n    }\n    else\n    {\n        _4928 = _4921;\n    }\n    if (_4928)\n    {\n        int param_2 = _4908 + 1;\n        vec2 param_3 = uv;\n        c = mix(c, fa_xm_level(param_2, param_3), vec3(_4919));\n    }\n    return c;\n}\n\nvec3 fa_transmitted(Surface s, vec3 n, vec3 v, float roughness, vec3 f0, float f90, float keep, float tr, inout float blend)\n{\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05);\n    vec2 _4954 = fa_env_brdf(param, param_1);\n    vec3 through = ((vec3(1.0) - clamp((f0 * _4954.x) + (vec3(f90) * _4954.y), vec3(0.0), vec3(1.0))) * s.albedo) * (tr * keep);\n    float _4982 = max(s.thickness, 0.0);\n    bool _4987 = _4982 > 0.0;\n    if ((s.attenuation_distance > 0.0) && _4987)\n    {\n        through *= exp((-((-log(clamp(s.attenuation_color, vec3(9.9999997473787516355514526367188e-05), vec3(1.0)))) / vec3(s.attenuation_distance))) * _4982);\n    }\n    bool _5012 = fa_mesh_fs_params[30].w > 1.5;\n    bool _5019;\n    if (!_5012)\n    {\n        _5019 = fa_mesh_fs_params[30].w < 0.5;\n    }\n    else\n    {\n        _5019 = _5012;\n    }\n    if (_5019)\n    {\n        blend = clamp(dot(through, vec3(0.3333333432674407958984375)), 0.0, 0.980000019073486328125);\n        return vec3(0.0);\n    }\n    vec3 world = fa_world_pos;\n    if (_4987)\n    {\n        world += (refract(-v, n, 1.0 / max(s.ior, 1.0)) * _4982);\n    }\n    vec4 _5054 = vec4(world, 1.0);\n    float _5059 = dot(fa_mesh_fs_params[28], _5054);\n    vec2 uv = vec2(0.5);\n    if (_5059 > 9.9999997473787516355514526367188e-05)\n    {\n        vec2 _5077 = vec2(dot(fa_mesh_fs_params[26], _5054), dot(fa_mesh_fs_params[27], _5054)) / vec2(_5059);\n        float _5085;\n        if (fa_mesh_fs_params[24].y > 0.5)\n        {\n            _5085 = (_5077.y * 0.5) + 0.5;\n        }\n        else\n        {\n            _5085 = 0.5 - (_5077.y * 0.5);\n        }\n        uv = vec2((_5077.x * 0.5) + 0.5, _5085);\n    }\n    vec2 param_2 = clamp(uv, vec2(0.0), vec2(1.0));\n    float param_3 = (clamp(roughness, 0.0, 1.0) * clamp((2.0 * s.ior) - 2.0, 0.0, 1.0)) * max(fa_mesh_fs_params[31].w - 1.0, 0.0);\n    return through * fa_xm_sample(param_2, param_3);\n}\n\nvec3 fa_shadow_debug(vec3 color, vec3 world)\n{\n    if (fa_shadows[27].w < 0.5)\n    {\n        return color;\n    }\n    int _3204 = int(fa_shadows[25].x + 0.5);\n    float _3214 = dot(world - fa_shadows[27].xyz, fa_shadows[28].xyz);\n    vec3 tint_1 = vec3(0.3499999940395355224609375);\n    bool _3219 = _3204 > 0;\n    bool _3228;\n    if (_3219)\n    {\n        int param = _3204 - 1;\n        _3228 = _3214 <= fa_shadow_split_at(param);\n    }\n    else\n    {\n        _3228 = _3219;\n    }\n    if (_3228)\n    {\n        tint_1 = vec3(1.0, 0.1500000059604644775390625, 0.100000001490116119384765625);\n        bool _3234 = _3204 > 1;\n        bool _3241;\n        if (_3234)\n        {\n            _3241 = _3214 > fa_shadows[24].x;\n        }\n        else\n        {\n            _3241 = _3234;\n        }\n        if (_3241)\n        {\n            tint_1 = vec3(0.100000001490116119384765625, 0.89999997615814208984375, 0.20000000298023223876953125);\n        }\n        bool _3247 = _3204 > 2;\n        bool _3254;\n        if (_3247)\n        {\n            _3254 = _3214 > fa_shadows[24].y;\n        }\n        else\n        {\n            _3254 = _3247;\n        }\n        if (_3254)\n        {\n            tint_1 = vec3(0.1500000059604644775390625, 0.300000011920928955078125, 1.0);\n        }\n        bool _3260 = _3204 > 3;\n        bool _3267;\n        if (_3260)\n        {\n            _3267 = _3214 > fa_shadows[24].z;\n        }\n        else\n        {\n            _3267 = _3260;\n        }\n        if (_3267)\n        {\n            tint_1 = vec3(1.0, 0.89999997615814208984375, 0.100000001490116119384765625);\n        }\n    }\n    return mix(color, tint_1, vec3(0.550000011920928955078125));\n}\n\nvoid main()\n{\n    fa_inst_load();\n    vec3 _7407 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _7407 = -_7407;\n    }\n    vec3 _6702 = normalize(fa_mesh_fs_params[0].xyz - fa_world_pos);\n    vec3 param = fa_world_pos;\n    fa_cluster_begin(param);\n    SurfaceInput param_1 = SurfaceInput(fa_world_pos, _7407, fa_world_tangent, fa_uv, fa_vertex_color, _6702, gl_FrontFacing);\n    Surface _6710 = fa_standard_surface(param_1);\n    vec3 _7438 = _6710.albedo;\n    float _7439 = _6710.alpha;\n    vec3 _7440 = _6710.normal;\n    float _7441 = _6710.metallic;\n    float _7442 = _6710.roughness;\n    float _7443 = _6710.occlusion;\n    vec3 _7444 = _6710.emission;\n    float _7445 = _6710.clearcoat;\n    float _7446 = _6710.clearcoat_roughness;\n    vec3 _7447 = _6710.sheen_color;\n    float _7448 = _6710.sheen_roughness;\n    float _7449 = _6710.anisotropy;\n    float _7450 = _6710.anisotropy_rotation;\n    float _7451 = _6710.specular;\n    float _7452 = _6710.ior;\n    vec3 _7453 = _6710.specular_color;\n    float _7454 = _6710.transmission;\n    float _7455 = _6710.thickness;\n    vec3 _7456 = _6710.attenuation_color;\n    float _7457 = _6710.attenuation_distance;\n    SurfaceInput param_2 = SurfaceInput(fa_world_pos, _7407, fa_world_tangent, fa_uv, fa_vertex_color, _6702, gl_FrontFacing);\n    Surface param_3 = _6710;\n    surface(param_2, param_3);\n    _7438 = param_3.albedo;\n    _7439 = param_3.alpha;\n    _7440 = param_3.normal;\n    _7441 = param_3.metallic;\n    _7442 = param_3.roughness;\n    _7443 = param_3.occlusion;\n    _7444 = param_3.emission;\n    _7445 = param_3.clearcoat;\n    _7446 = param_3.clearcoat_roughness;\n    _7447 = param_3.sheen_color;\n    _7448 = param_3.sheen_roughness;\n    _7449 = param_3.anisotropy;\n    _7450 = param_3.anisotropy_rotation;\n    _7451 = param_3.specular;\n    _7452 = param_3.ior;\n    _7453 = param_3.specular_color;\n    _7454 = param_3.transmission;\n    _7455 = param_3.thickness;\n    _7456 = param_3.attenuation_color;\n    _7457 = param_3.attenuation_distance;\n    vec3 param_4 = fa_world_pos;\n    vec3 param_5 = _7407;\n    vec3 param_6 = param_3.albedo;\n    vec3 param_7 = param_3.normal;\n    fa_apply_decals(param_4, param_5, param_6, param_7);\n    _7438 = param_6;\n    _7440 = param_7;\n    float fa_tr_blend = 0.0;\n    vec3 result;\n    if (fa_mesh_fs_params[3].w > 0.5)\n    {\n        result = _7438;\n    }\n    else\n    {\n        vec3 _6750 = normalize(_7440);\n        float _6757 = clamp(_7441, 0.0, 1.0);\n        float _6761 = clamp(_7442, 0.0500000007450580596923828125, 1.0);\n        float _6765 = _6761 * _6761;\n        float _6769 = _6765 * _6765;\n        float _6774 = max(dot(_6750, _6702), 9.9999997473787516355514526367188e-05);\n        float _6780 = 1.0 - _6757;\n        float _6781 = clamp(_7454, 0.0, 1.0) * _6780;\n        vec3 _6790 = (_7438 * _6780) * (1.0 - _6781);\n        vec3 _6797 = mix(vec3(0.039999999105930328369140625), _7438, vec3(_6757));\n        vec3 f0 = _6797;\n        SurfaceInput param_8 = SurfaceInput(fa_world_pos, _7407, fa_world_tangent, fa_uv, fa_vertex_color, _6702, gl_FrontFacing);\n        Surface param_9 = Surface(_7438, _7439, _7440, _7441, _7442, _7443, _7444, _7445, _7446, _7447, _7448, _7449, _7450, _7451, _7452, _7453, _7454, _7455, _7456, _7457);\n        vec3 param_10 = _6750;\n        vec3 param_11 = _6702;\n        float param_12 = _6757;\n        float param_13 = _6761;\n        vec3 param_14 = _6797;\n        FaLayers _6813 = fa_layers_setup(param_8, param_9, param_10, param_11, param_12, param_13, param_14);\n        f0 = param_14;\n        vec3 param_15 = _6750;\n        vec3 lit = (fa_indirect_diffuse(param_15) * _6790) * _7443;\n        if (_6813.on)\n        {\n            lit *= _6813.base_scale;\n        }\n        int _6835 = fa_cl_ndir + fa_cl_local;\n        for (int ln = 0; ln < _6835; ln++)\n        {\n            int param_16 = ln;\n            int _6848 = fa_cl_light(param_16);\n            int param_17 = _6848;\n            if (fa_baked_keep(param_17) <= 0.0)\n            {\n                continue;\n            }\n            int param_18 = _6848;\n            vec3 param_19 = fa_world_pos;\n            vec3 param_20 = _7407;\n            LightSample _6864 = fa_light_shadowed(param_18, param_19, param_20);\n            float _6872 = max(dot(_6750, _6864.direction), 0.0);\n            float _6878 = _6864.attenuation * _6864.shadow;\n            vec3 _6883 = normalize(_6864.direction + _6702);\n            float _6888 = max(dot(_6750, _6883), 0.0);\n            float _6893 = max(dot(_6702, _6883), 0.0);\n            bool _6900;\n            if (fa_light_is_area)\n            {\n                _6900 = !_6813.on;\n            }\n            else\n            {\n                _6900 = fa_light_is_area;\n            }\n            if (_6900)\n            {\n                int param_21 = _6848;\n                vec3 param_22 = fa_world_pos;\n                vec3 param_23 = _6750;\n                vec3 param_24 = _6702;\n                vec3 param_25 = _6790;\n                vec3 param_26 = f0;\n                float param_27 = 1.0;\n                float param_28 = _6761;\n                float param_29 = _6774;\n                float param_30 = _6878;\n                lit += fa_area_shade(param_21, param_22, param_23, param_24, param_25, param_26, param_27, param_28, param_29, param_30);\n            }\n            else\n            {\n                if (fa_light_is_area)\n                {\n                    FaLayers param_31 = _6813;\n                    int param_32 = _6848;\n                    vec3 param_33 = fa_world_pos;\n                    vec3 param_34 = _6750;\n                    vec3 param_35 = _6702;\n                    vec3 param_36 = _6864.direction;\n                    vec3 param_37 = _6790;\n                    vec3 param_38 = f0;\n                    float param_39 = _6761;\n                    float param_40 = _6774;\n                    float param_41 = _6878;\n                    lit += fa_area_layers(param_31, param_32, param_33, param_34, param_35, param_36, param_37, param_38, param_39, param_40, param_41);\n                }\n                else\n                {\n                    if (_6813.on)\n                    {\n                        FaLayers param_42 = _6813;\n                        vec3 param_43 = _6790;\n                        vec3 param_44 = f0;\n                        vec3 param_45 = _6750;\n                        vec3 param_46 = _6702;\n                        vec3 param_47 = _6864.direction;\n                        vec3 param_48 = _6883;\n                        float param_49 = _6872;\n                        float param_50 = _6774;\n                        float param_51 = _6888;\n                        float param_52 = _6893;\n                        float param_53 = _6765;\n                        float param_54 = _6769;\n                        int param_55 = _6848;\n                        lit += (fa_layers_light(param_42, param_43, param_44, param_45, param_46, param_47, param_48, param_49, param_50, param_51, param_52, param_53, param_54) * ((fa_light_rgb(param_55) * fa_light_tint) * _6878));\n                    }\n                    else\n                    {\n                        float _7006 = ((_6888 * _6888) * (_6769 - 1.0)) + 1.0;\n                        int param_56 = _6848;\n                        lit += (((_6790 + (((f0 + ((vec3(1.0) - f0) * pow(1.0 - _6893, 5.0))) * (((_6769 / ((3.1415927410125732421875 * _7006) * _7006)) * (0.5 / max(mix((2.0 * _6872) * _6774, _6872 + _6774, _6765), 9.9999997473787516355514526367188e-05))) * 3.1415927410125732421875)) * step(9.9999997473787516355514526367188e-05, _6872))) * (fa_light_rgb(param_56) * fa_light_tint)) * (_6872 * _6878));\n                    }\n                }\n            }\n        }\n        if (_6813.on)\n        {\n            FaLayers param_57 = _6813;\n            vec3 param_58 = _6750;\n            vec3 param_59 = _6702;\n            vec3 param_60 = f0;\n            float param_61 = _6761;\n            lit += (fa_layers_ibl(param_57, param_58, param_59, param_60, param_61) * _7443);\n        }\n        else\n        {\n            vec3 param_62 = _6750;\n            vec3 param_63 = _6702;\n            vec3 param_64 = f0;\n            float param_65 = _6761;\n            lit += (fa_sky_reflection(param_62, param_63, param_64, param_65) * _7443);\n        }\n        if (_6781 > 0.0)\n        {\n            float _7104;\n            if (_6813.on)\n            {\n                _7104 = _6813.f90;\n            }\n            else\n            {\n                _7104 = 1.0;\n            }\n            float _7112;\n            if (_6813.on)\n            {\n                _7112 = _6813.base_scale;\n            }\n            else\n            {\n                _7112 = 1.0;\n            }\n            Surface param_66 = Surface(_7438, _7439, _7440, _7441, _7442, _7443, _7444, _7445, _7446, _7447, _7448, _7449, _7450, _7451, _7452, _7453, _7454, _7455, _7456, _7457);\n            vec3 param_67 = _6750;\n            vec3 param_68 = _6702;\n            float param_69 = _6761;\n            vec3 param_70 = f0;\n            float param_71 = _7104;\n            float param_72 = _7112;\n            float param_73 = _6781;\n            float param_74 = fa_tr_blend;\n            vec3 _7136 = fa_transmitted(param_66, param_67, param_68, param_69, param_70, param_71, param_72, param_73, param_74);\n            fa_tr_blend = param_74;\n            lit += _7136;\n        }\n        result = lit;\n    }\n    vec3 _7143 = result;\n    vec3 _7144 = _7143 + _7444;\n    result = _7144;\n    vec3 param_75 = _7144;\n    vec3 param_76 = fa_world_pos;\n    result = fa_shadow_debug(param_75, param_76);\n    bool _7153 = fa_mesh_fs_params[7].w > 0.0;\n    bool _7160;\n    if (!_7153)\n    {\n        _7160 = fa_mesh_fs_params[8].y > 0.0;\n    }\n    else\n    {\n        _7160 = _7153;\n    }\n    if (_7160)\n    {\n        vec3 _7169 = fa_world_pos - fa_mesh_fs_params[0].xyz;\n        float _7175 = dot(_7169, fa_mesh_fs_params[9].xyz);\n        bool _7179 = fa_mesh_fs_params[9].w > 0.5;\n        float _7180;\n        if (_7179)\n        {\n            _7180 = _7175;\n        }\n        else\n        {\n            _7180 = length(_7169);\n        }\n        float _7192 = _7180 - fa_mesh_fs_params[8].x;\n        if (_7192 > 0.0)\n        {\n            float _7201 = fa_mesh_fs_params[7].w * _7192;\n            float tau = _7201 * _7201;\n            if (fa_mesh_fs_params[8].y > 0.0)\n            {\n                float _7217;\n                if (_7179)\n                {\n                    _7217 = fa_world_pos.y - (fa_mesh_fs_params[9].y * _7175);\n                }\n                else\n                {\n                    _7217 = fa_mesh_fs_params[0].y;\n                }\n                float _7238 = mix(_7217, fa_world_pos.y, clamp(fa_mesh_fs_params[8].x / _7180, 0.0, 1.0));\n                float _7242 = fa_world_pos.y - _7238;\n                float _7247 = _7238 - fa_mesh_fs_params[8].z;\n                float _7252 = fa_world_pos.y - fa_mesh_fs_params[8].z;\n                bool _7255 = _7247 <= 0.0;\n                bool _7256 = !_7255;\n                bool _7262;\n                if (_7256)\n                {\n                    _7262 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _7262 = _7255;\n                }\n                float _7263;\n                if (_7262)\n                {\n                    _7263 = fa_mesh_fs_params[8].y;\n                }\n                else\n                {\n                    _7263 = fa_mesh_fs_params[8].y * exp(-min(fa_mesh_fs_params[8].w * _7247, 80.0));\n                }\n                bool _7290;\n                if (_7256)\n                {\n                    _7290 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _7290 = _7255;\n                }\n                float _7291;\n                if (_7290)\n                {\n                    _7291 = fa_mesh_fs_params[8].y * _7247;\n                }\n                else\n                {\n                    _7291 = (fa_mesh_fs_params[8].y * (1.0 - exp(-min(fa_mesh_fs_params[8].w * _7247, 80.0)))) / fa_mesh_fs_params[8].w;\n                }\n                bool _7316 = _7252 <= 0.0;\n                bool _7323;\n                if (!_7316)\n                {\n                    _7323 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _7323 = _7316;\n                }\n                float _7324;\n                if (_7323)\n                {\n                    _7324 = fa_mesh_fs_params[8].y * _7252;\n                }\n                else\n                {\n                    _7324 = (fa_mesh_fs_params[8].y * (1.0 - exp(-min(fa_mesh_fs_params[8].w * _7252, 80.0)))) / fa_mesh_fs_params[8].w;\n                }\n                float _7351;\n                if (abs(_7242) < 0.001000000047497451305389404296875)\n                {\n                    _7351 = _7263;\n                }\n                else\n                {\n                    _7351 = (_7324 - _7291) / _7242;\n                }\n                tau += (_7192 * max(_7351, 0.0));\n            }\n            result = mix(result, fa_mesh_fs_params[7].xyz, vec3(clamp(1.0 - exp(-clamp(tau, 0.0, 80.0)), 0.0, 1.0)));\n        }\n    }\n    if (fa_tr_blend > 0.0)\n    {\n        float _7387 = 1.0 - fa_tr_blend;\n        result /= vec3(_7387);\n        _7439 *= _7387;\n    }\n    fa_frag_color = vec4(result, _7439);\n}\n\n",
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
            "size": 656,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_601",
            "glsl_uniforms": [
              {
                "type": "vec4",
                "array_count": 41,
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
            "inst_name": "_2268",
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
            "inst_name": "_6270",
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
      "vs": "#version 430\n\nstruct VertexData\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 color;\n    vec3 object_pos;\n};\n\nuniform vec4 fa_mesh_vs_params[11];\nlayout(location = 2) out vec3 fa_world_pos;\nlayout(location = 3) out vec3 fa_world_normal;\nlayout(location = 4) out vec4 fa_world_tangent;\nlayout(location = 5) out vec2 fa_uv;\nlayout(location = 6) out vec4 fa_vertex_color;\nlayout(location = 7) out float fa_pre_depth;\nlayout(location = 8) out vec3 fa_pre_r0;\nlayout(location = 9) out vec3 fa_pre_r1;\nlayout(location = 10) out vec3 fa_pre_r2;\nlayout(location = 9) in vec4 fa_inst_d0;\nlayout(location = 10) in vec4 fa_inst_d1;\nlayout(location = 0) flat out vec4 fa_inst_v0;\nlayout(location = 1) flat out vec4 fa_inst_v1;\nlayout(location = 5) in vec4 fa_inst_m0;\nlayout(location = 6) in vec4 fa_inst_m1;\nlayout(location = 7) in vec4 fa_inst_m2;\nlayout(location = 8) in vec4 fa_inst_m3;\nlayout(location = 0) in vec3 fa_position;\nlayout(location = 1) in vec3 fa_normal;\nlayout(location = 3) in vec4 fa_tangent;\nlayout(location = 2) in vec2 fa_texcoord0;\nlayout(location = 4) in vec4 fa_color;\nfloat raise;\nvec4 tint;\n\nvoid fa_instance_unpack(vec4 fa_d0, vec4 fa_d1, vec4 fa_d2)\n{\n    raise = fa_d0.x;\n    tint = fa_d1;\n}\n\nvoid fa_inst_begin()\n{\n    vec4 param = fa_inst_d0;\n    vec4 param_1 = fa_inst_d1;\n    vec4 param_2 = vec4(0.0);\n    fa_instance_unpack(param, param_1, param_2);\n    fa_inst_v0 = fa_inst_d0;\n    fa_inst_v1 = fa_inst_d1;\n}\n\nVertexData fa_vertex_data(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    vec3 _94 = cross(model[1].xyz, model[2].xyz);\n    float _100 = (dot(model[0].xyz, _94) < 0.0) ? (-1.0) : 1.0;\n    return VertexData((model * vec4(position, 1.0)).xyz, (((_94 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _100, vec4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _100), texcoord0 * fa_mesh_vs_params[8].xy, color, position);\n}\n\nvoid vertex(inout VertexData v)\n{\n    v.world_pos.y += raise;\n}\n\nvoid fa_prepass_vertex(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    mat4 param = model;\n    vec3 param_1 = position;\n    vec3 param_2 = normal;\n    vec4 param_3 = tangent;\n    vec2 param_4 = texcoord0;\n    vec4 param_5 = color;\n    VertexData param_6 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    vertex(param_6);\n    mat4 _190 = mat4(fa_mesh_vs_params[4], fa_mesh_vs_params[5], fa_mesh_vs_params[6], fa_mesh_vs_params[7]);\n    vec4 _197 = vec4(param_6.world_pos, 1.0);\n    fa_world_pos = param_6.world_pos;\n    fa_world_normal = param_6.world_normal;\n    fa_world_tangent = param_6.world_tangent;\n    fa_uv = param_6.uv;\n    fa_vertex_color = param_6.color;\n    fa_pre_depth = -(_190 * _197).z;\n    fa_pre_r0 = vec3(_190[0].x, _190[1].x, _190[2].x);\n    fa_pre_r1 = vec3(_190[0].y, _190[1].y, _190[2].y);\n    fa_pre_r2 = vec3(_190[0].z, _190[1].z, _190[2].z);\n    gl_Position = mat4(fa_mesh_vs_params[0], fa_mesh_vs_params[1], fa_mesh_vs_params[2], fa_mesh_vs_params[3]) * _197;\n}\n\nvoid main()\n{\n    fa_inst_begin();\n    mat4 param = mat4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3);\n    vec3 param_1 = fa_position;\n    vec3 param_2 = fa_normal;\n    vec4 param_3 = fa_tangent;\n    vec2 param_4 = fa_texcoord0;\n    vec4 param_5 = fa_color;\n    fa_prepass_vertex(param, param_1, param_2, param_3, param_4, param_5);\n}\n\n",
      "fs": "#version 430\n\nstruct SurfaceInput\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 vertex_color;\n    vec3 view_dir;\n    bool front_facing;\n};\n\nstruct Surface\n{\n    vec3 albedo;\n    float alpha;\n    vec3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    vec3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    vec3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    vec3 specular_color;\n    float transmission;\n    float thickness;\n    vec3 attenuation_color;\n    float attenuation_distance;\n};\n\nuniform vec4 fa_material[1];\nuniform vec4 fa_mesh_fs_params[41];\nlayout(binding = 0) uniform sampler2D fa_tex_fa_smp;\nlayout(binding = 1) uniform sampler2D fa_normal_tex_fa_smp;\nlayout(binding = 2) uniform sampler2D fa_mr_tex_fa_smp;\nlayout(binding = 3) uniform sampler2D fa_occlusion_tex_fa_smp;\nlayout(binding = 4) uniform sampler2D fa_emissive_tex_fa_smp;\n\nlayout(location = 0) flat in vec4 fa_inst_v0;\nlayout(location = 1) flat in vec4 fa_inst_v1;\nlayout(location = 2) in vec3 fa_world_pos;\nlayout(location = 3) in vec3 fa_world_normal;\nlayout(location = 4) in vec4 fa_world_tangent;\nlayout(location = 5) in vec2 fa_uv;\nlayout(location = 6) in vec4 fa_vertex_color;\nlayout(location = 8) in vec3 fa_pre_r0;\nlayout(location = 9) in vec3 fa_pre_r1;\nlayout(location = 10) in vec3 fa_pre_r2;\nlayout(location = 0) out vec4 fa_frag_color;\nlayout(location = 7) in float fa_pre_depth;\nfloat raise;\nvec4 tint;\n\nvoid fa_instance_unpack(vec4 fa_d0, vec4 fa_d1, vec4 fa_d2)\n{\n    raise = fa_d0.x;\n    tint = fa_d1;\n}\n\nvoid fa_inst_load()\n{\n    vec4 param = fa_inst_v0;\n    vec4 param_1 = fa_inst_v1;\n    vec4 param_2 = vec4(0.0);\n    fa_instance_unpack(param, param_1, param_2);\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nvec3 fa_linear_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_tex_fix(inout vec3 c, float mode)\n{\n    if (mode > 1.5)\n    {\n        vec3 param = c;\n        vec3 _212 = fa_linear_to_srgb(param);\n        c = _212;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            vec3 param_1 = c;\n            vec3 _221 = fa_srgb_to_linear(param_1);\n            c = _221;\n        }\n    }\n    return c;\n}\n\nvec3 fa_tangent_normal(SurfaceInput i, vec3 m)\n{\n    vec3 _63;\n    if (i.front_facing)\n    {\n        _63 = i.world_normal;\n    }\n    else\n    {\n        _63 = -i.world_normal;\n    }\n    vec3 _87 = normalize(i.world_tangent.xyz - (_63 * dot(_63, i.world_tangent.xyz)));\n    vec3 _115 = normalize(((_87 * m.x) + ((cross(_63, _87) * i.world_tangent.w) * m.y)) + (_63 * m.z));\n    vec3 _118;\n    if (i.front_facing)\n    {\n        _118 = _115;\n    }\n    else\n    {\n        _118 = -_115;\n    }\n    return _118;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    vec4 base_t = texture(fa_tex_fa_smp, i.uv);\n    float param = fa_mesh_fs_params[6].w;\n    float param_1 = 1.0;\n    vec3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    vec3 _266 = fa_tex_fix(param_2, param_3);\n    vec4 _817 = base_t;\n    _817.x = _266.x;\n    _817.y = _266.y;\n    _817.z = _266.z;\n    base_t = _817;\n    vec4 _282 = (_817 * fa_mesh_fs_params[2]) * i.vertex_color;\n    vec3 _772 = i.world_normal;\n    if (fa_mesh_fs_params[6].z > 0.5)\n    {\n        float param_4 = fa_mesh_fs_params[6].w;\n        float param_5 = 16.0;\n        vec3 param_6 = texture(fa_normal_tex_fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        vec3 _315 = fa_tex_fix(param_6, param_7);\n        vec3 _319 = (_315 * 2.0) - vec3(1.0);\n        vec2 _324 = _319.xy * fa_mesh_fs_params[6].x;\n        vec3 _825 = _319;\n        _825.x = _324.x;\n        _825.y = _324.y;\n        SurfaceInput param_8 = i;\n        vec3 param_9 = _825;\n        _772 = fa_tangent_normal(param_8, param_9);\n    }\n    vec4 mrt = texture(fa_mr_tex_fa_smp, i.uv);\n    float param_10 = fa_mesh_fs_params[6].w;\n    float param_11 = 64.0;\n    vec3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    vec3 _353 = fa_tex_fix(param_12, param_13);\n    vec4 _828 = mrt;\n    _828.x = _353.x;\n    _828.y = _353.y;\n    _828.z = _353.z;\n    mrt = _828;\n    vec4 _383 = texture(fa_occlusion_tex_fa_smp, i.uv);\n    float param_14 = fa_mesh_fs_params[6].w;\n    float param_15 = 256.0;\n    vec3 param_16 = _383.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    vec3 _395 = fa_tex_fix(param_16, param_17);\n    float param_18 = fa_mesh_fs_params[6].w;\n    float param_19 = 4.0;\n    vec3 param_20 = texture(fa_emissive_tex_fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    vec3 _425 = fa_tex_fix(param_20, param_21);\n    float _777 = fa_mesh_fs_params[20].x;\n    float _778 = fa_mesh_fs_params[20].y;\n    float _781 = fa_mesh_fs_params[20].z;\n    float _780 = fa_mesh_fs_params[21].w;\n    float _783 = fa_mesh_fs_params[22].x;\n    if (fa_mesh_fs_params[22].z > 0.5)\n    {\n        if (mod(fa_mesh_fs_params[22].z, 2.0) > 0.5)\n        {\n            _777 *= _395.y;\n            _778 *= _395.z;\n            _780 *= _383.w;\n        }\n        if (fa_mesh_fs_params[22].z > 1.5)\n        {\n            _781 *= mrt.x;\n            _783 *= mrt.w;\n        }\n    }\n    return Surface(_282.xyz, _282.w, _772, clamp(fa_mesh_fs_params[5].x * _353.z, 0.0, 1.0), clamp(fa_mesh_fs_params[5].y * _353.y, 0.0500000007450580596923828125, 1.0), 1.0 + (fa_mesh_fs_params[6].y * (_395.x - 1.0)), fa_mesh_fs_params[3].xyz + (fa_mesh_fs_params[4].xyz * _425), _777, _778, fa_mesh_fs_params[21].xyz, _780, _781, fa_mesh_fs_params[20].w, _783, fa_mesh_fs_params[22].y, fa_mesh_fs_params[23].xyz, fa_mesh_fs_params[30].x, fa_mesh_fs_params[30].y, fa_mesh_fs_params[31].xyz, fa_mesh_fs_params[30].z);\n}\n\nvoid surface(SurfaceInput i, inout Surface s)\n{\n    s.emission += ((tint.xyz * tint.w) * fa_material[0].x);\n}\n\nvoid main()\n{\n    fa_inst_load();\n    vec3 _667 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _667 = -_667;\n    }\n    vec3 _577 = normalize(fa_mesh_fs_params[0].xyz - fa_world_pos);\n    SurfaceInput param = SurfaceInput(fa_world_pos, _667, fa_world_tangent, fa_uv, fa_vertex_color, _577, gl_FrontFacing);\n    SurfaceInput param_1 = SurfaceInput(fa_world_pos, _667, fa_world_tangent, fa_uv, fa_vertex_color, _577, gl_FrontFacing);\n    Surface param_2 = fa_standard_surface(param);\n    surface(param_1, param_2);\n    vec3 _592 = normalize(param_2.normal);\n    vec3 _607 = normalize(vec3(dot(fa_pre_r0, _592), dot(fa_pre_r1, _592), dot(fa_pre_r2, _592)));\n    float _619 = _607.z;\n    vec2 e = _607.xy / vec2((abs(_607.x) + abs(_607.y)) + abs(_619));\n    if (_619 < 0.0)\n    {\n        e = (vec2(1.0) - abs(e.yx)) * vec2((e.x >= 0.0) ? 1.0 : (-1.0), (e.y >= 0.0) ? 1.0 : (-1.0));\n    }\n    fa_frag_color = vec4(min(fa_pre_depth, 60000.0), e, 1.0);\n}\n\n",
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
            "size": 656,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_255",
            "glsl_uniforms": [
              {
                "type": "vec4",
                "array_count": 41,
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
      "fs": "#version 430\n\nstruct SurfaceInput\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 vertex_color;\n    vec3 view_dir;\n    bool front_facing;\n};\n\nstruct Surface\n{\n    vec3 albedo;\n    float alpha;\n    vec3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    vec3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    vec3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    vec3 specular_color;\n    float transmission;\n    float thickness;\n    vec3 attenuation_color;\n    float attenuation_distance;\n};\n\nuniform vec4 fa_material[1];\nuniform vec4 fa_mesh_fs_params[41];\nlayout(binding = 0) uniform sampler2D fa_tex_fa_smp;\nlayout(binding = 1) uniform sampler2D fa_normal_tex_fa_smp;\nlayout(binding = 2) uniform sampler2D fa_mr_tex_fa_smp;\nlayout(binding = 3) uniform sampler2D fa_occlusion_tex_fa_smp;\nlayout(binding = 4) uniform sampler2D fa_emissive_tex_fa_smp;\n\nlayout(location = 0) flat in vec4 fa_inst_v0;\nlayout(location = 1) flat in vec4 fa_inst_v1;\nlayout(location = 2) in vec3 fa_world_pos;\nlayout(location = 3) in vec3 fa_world_normal;\nlayout(location = 4) in vec4 fa_world_tangent;\nlayout(location = 5) in vec2 fa_uv;\nlayout(location = 6) in vec4 fa_vertex_color;\nlayout(location = 8) in vec3 fa_pre_r0;\nlayout(location = 9) in vec3 fa_pre_r1;\nlayout(location = 10) in vec3 fa_pre_r2;\nlayout(location = 0) out vec4 fa_frag_color;\nlayout(location = 7) in float fa_pre_depth;\nfloat raise;\nvec4 tint;\n\nvoid fa_instance_unpack(vec4 fa_d0, vec4 fa_d1, vec4 fa_d2)\n{\n    raise = fa_d0.x;\n    tint = fa_d1;\n}\n\nvoid fa_inst_load()\n{\n    vec4 param = fa_inst_v0;\n    vec4 param_1 = fa_inst_v1;\n    vec4 param_2 = vec4(0.0);\n    fa_instance_unpack(param, param_1, param_2);\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nvec3 fa_linear_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_tex_fix(inout vec3 c, float mode)\n{\n    if (mode > 1.5)\n    {\n        vec3 param = c;\n        vec3 _212 = fa_linear_to_srgb(param);\n        c = _212;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            vec3 param_1 = c;\n            vec3 _221 = fa_srgb_to_linear(param_1);\n            c = _221;\n        }\n    }\n    return c;\n}\n\nvec3 fa_tangent_normal(SurfaceInput i, vec3 m)\n{\n    vec3 _63;\n    if (i.front_facing)\n    {\n        _63 = i.world_normal;\n    }\n    else\n    {\n        _63 = -i.world_normal;\n    }\n    vec3 _87 = normalize(i.world_tangent.xyz - (_63 * dot(_63, i.world_tangent.xyz)));\n    vec3 _115 = normalize(((_87 * m.x) + ((cross(_63, _87) * i.world_tangent.w) * m.y)) + (_63 * m.z));\n    vec3 _118;\n    if (i.front_facing)\n    {\n        _118 = _115;\n    }\n    else\n    {\n        _118 = -_115;\n    }\n    return _118;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    vec4 base_t = texture(fa_tex_fa_smp, i.uv);\n    float param = fa_mesh_fs_params[6].w;\n    float param_1 = 1.0;\n    vec3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    vec3 _266 = fa_tex_fix(param_2, param_3);\n    vec4 _817 = base_t;\n    _817.x = _266.x;\n    _817.y = _266.y;\n    _817.z = _266.z;\n    base_t = _817;\n    vec4 _282 = (_817 * fa_mesh_fs_params[2]) * i.vertex_color;\n    vec3 _772 = i.world_normal;\n    if (fa_mesh_fs_params[6].z > 0.5)\n    {\n        float param_4 = fa_mesh_fs_params[6].w;\n        float param_5 = 16.0;\n        vec3 param_6 = texture(fa_normal_tex_fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        vec3 _315 = fa_tex_fix(param_6, param_7);\n        vec3 _319 = (_315 * 2.0) - vec3(1.0);\n        vec2 _324 = _319.xy * fa_mesh_fs_params[6].x;\n        vec3 _825 = _319;\n        _825.x = _324.x;\n        _825.y = _324.y;\n        SurfaceInput param_8 = i;\n        vec3 param_9 = _825;\n        _772 = fa_tangent_normal(param_8, param_9);\n    }\n    vec4 mrt = texture(fa_mr_tex_fa_smp, i.uv);\n    float param_10 = fa_mesh_fs_params[6].w;\n    float param_11 = 64.0;\n    vec3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    vec3 _353 = fa_tex_fix(param_12, param_13);\n    vec4 _828 = mrt;\n    _828.x = _353.x;\n    _828.y = _353.y;\n    _828.z = _353.z;\n    mrt = _828;\n    vec4 _383 = texture(fa_occlusion_tex_fa_smp, i.uv);\n    float param_14 = fa_mesh_fs_params[6].w;\n    float param_15 = 256.0;\n    vec3 param_16 = _383.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    vec3 _395 = fa_tex_fix(param_16, param_17);\n    float param_18 = fa_mesh_fs_params[6].w;\n    float param_19 = 4.0;\n    vec3 param_20 = texture(fa_emissive_tex_fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    vec3 _425 = fa_tex_fix(param_20, param_21);\n    float _777 = fa_mesh_fs_params[20].x;\n    float _778 = fa_mesh_fs_params[20].y;\n    float _781 = fa_mesh_fs_params[20].z;\n    float _780 = fa_mesh_fs_params[21].w;\n    float _783 = fa_mesh_fs_params[22].x;\n    if (fa_mesh_fs_params[22].z > 0.5)\n    {\n        if (mod(fa_mesh_fs_params[22].z, 2.0) > 0.5)\n        {\n            _777 *= _395.y;\n            _778 *= _395.z;\n            _780 *= _383.w;\n        }\n        if (fa_mesh_fs_params[22].z > 1.5)\n        {\n            _781 *= mrt.x;\n            _783 *= mrt.w;\n        }\n    }\n    return Surface(_282.xyz, _282.w, _772, clamp(fa_mesh_fs_params[5].x * _353.z, 0.0, 1.0), clamp(fa_mesh_fs_params[5].y * _353.y, 0.0500000007450580596923828125, 1.0), 1.0 + (fa_mesh_fs_params[6].y * (_395.x - 1.0)), fa_mesh_fs_params[3].xyz + (fa_mesh_fs_params[4].xyz * _425), _777, _778, fa_mesh_fs_params[21].xyz, _780, _781, fa_mesh_fs_params[20].w, _783, fa_mesh_fs_params[22].y, fa_mesh_fs_params[23].xyz, fa_mesh_fs_params[30].x, fa_mesh_fs_params[30].y, fa_mesh_fs_params[31].xyz, fa_mesh_fs_params[30].z);\n}\n\nvoid surface(SurfaceInput i, inout Surface s)\n{\n    s.emission += ((tint.xyz * tint.w) * fa_material[0].x);\n}\n\nvoid main()\n{\n    fa_inst_load();\n    vec3 _667 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _667 = -_667;\n    }\n    vec3 _577 = normalize(fa_mesh_fs_params[0].xyz - fa_world_pos);\n    SurfaceInput param = SurfaceInput(fa_world_pos, _667, fa_world_tangent, fa_uv, fa_vertex_color, _577, gl_FrontFacing);\n    SurfaceInput param_1 = SurfaceInput(fa_world_pos, _667, fa_world_tangent, fa_uv, fa_vertex_color, _577, gl_FrontFacing);\n    Surface param_2 = fa_standard_surface(param);\n    surface(param_1, param_2);\n    vec3 _592 = normalize(param_2.normal);\n    vec3 _607 = normalize(vec3(dot(fa_pre_r0, _592), dot(fa_pre_r1, _592), dot(fa_pre_r2, _592)));\n    float _619 = _607.z;\n    vec2 e = _607.xy / vec2((abs(_607.x) + abs(_607.y)) + abs(_619));\n    if (_619 < 0.0)\n    {\n        e = (vec2(1.0) - abs(e.yx)) * vec2((e.x >= 0.0) ? 1.0 : (-1.0), (e.y >= 0.0) ? 1.0 : (-1.0));\n    }\n    fa_frag_color = vec4(min(fa_pre_depth, 60000.0), e, 1.0);\n}\n\n",
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
            "size": 656,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_255",
            "glsl_uniforms": [
              {
                "type": "vec4",
                "array_count": 41,
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
