{
  "format": "factoria.shader/1",
  "engine": "0.38.0",
  "template": "3fa6c13f5571f2fc0eb287205caf584b06954bd67d1e4a78d6bcea1f31efa8d6",
  "slang": "glsl430",
  "params": [
    "dark",
    "skyAmount"
  ],
  "textures": [],
  "programs": {
    "mesh": {
      "vs": "#version 430\n\nstruct VertexData\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 color;\n    vec3 object_pos;\n};\n\nuniform vec4 fa_mesh_vs_params[11];\nlayout(location = 0) out vec3 fa_world_pos;\nlayout(location = 1) out vec3 fa_world_normal;\nlayout(location = 2) out vec4 fa_world_tangent;\nlayout(location = 3) out vec2 fa_uv;\nlayout(location = 4) out vec4 fa_vertex_color;\nlayout(location = 5) in vec4 fa_inst_m0;\nlayout(location = 6) in vec4 fa_inst_m1;\nlayout(location = 7) in vec4 fa_inst_m2;\nlayout(location = 8) in vec4 fa_inst_m3;\nlayout(location = 0) in vec3 fa_position;\nlayout(location = 1) in vec3 fa_normal;\nlayout(location = 3) in vec4 fa_tangent;\nlayout(location = 2) in vec2 fa_texcoord0;\nlayout(location = 4) in vec4 fa_color;\nlayout(location = 5) out vec3 fa_lm;\n\nvoid fa_inst_begin()\n{\n}\n\nVertexData fa_vertex_data(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    vec3 _69 = cross(model[1].xyz, model[2].xyz);\n    float _75 = (dot(model[0].xyz, _69) < 0.0) ? (-1.0) : 1.0;\n    return VertexData((model * vec4(position, 1.0)).xyz, (((_69 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _75, vec4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _75), texcoord0 * fa_mesh_vs_params[8].xy, color, position);\n}\n\nvoid fa_shade_vertex(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    mat4 param = model;\n    vec3 param_1 = position;\n    vec3 param_2 = normal;\n    vec4 param_3 = tangent;\n    vec2 param_4 = texcoord0;\n    vec4 param_5 = color;\n    VertexData _160 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    vec3 _270 = _160.world_pos;\n    fa_world_pos = _270;\n    fa_world_normal = _160.world_normal;\n    fa_world_tangent = _160.world_tangent;\n    fa_uv = _160.uv;\n    fa_vertex_color = _160.color;\n    gl_Position = mat4(fa_mesh_vs_params[0], fa_mesh_vs_params[1], fa_mesh_vs_params[2], fa_mesh_vs_params[3]) * vec4(_270, 1.0);\n}\n\nvoid main()\n{\n    fa_inst_begin();\n    mat4 param = mat4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3);\n    vec3 param_1 = fa_position;\n    vec3 param_2 = fa_normal;\n    vec4 param_3 = fa_tangent;\n    vec2 param_4 = fa_texcoord0;\n    vec4 param_5 = fa_color;\n    fa_shade_vertex(param, param_1, param_2, param_3, param_4, param_5);\n    fa_lm = vec3(0.0);\n}\n\n",
      "fs": "#version 430\n\nstruct SurfaceInput\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 vertex_color;\n    vec3 view_dir;\n    bool front_facing;\n};\n\nstruct LightSample\n{\n    vec3 direction;\n    vec3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct Surface\n{\n    vec3 albedo;\n    float alpha;\n    vec3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    vec3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    vec3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    vec3 specular_color;\n    float transmission;\n    float thickness;\n    vec3 attenuation_color;\n    float attenuation_distance;\n};\n\nstruct FaLayers\n{\n    bool on;\n    float f90;\n    float keep;\n    float base_scale;\n    float coat;\n    float coat_rough;\n    float coat_alpha;\n    float coat_a2;\n    vec3 nc;\n    float coat_ndv;\n    bool sheen_on;\n    vec3 sheen;\n    float sheen_rough;\n    float sheen_alpha;\n    float sheen_scale;\n    float sheen_e;\n    float aniso;\n    vec3 t;\n    vec3 b;\n    float at;\n    float ab;\n};\n\nconst float _4060[63] = float[](1.0, 1.0, 1.0, 0.4790000021457672119140625, 0.11699999868869781494140625, 0.01200000010430812835693359375, 0.0, 0.0, 0.0, 1.0, 1.0, 1.0, 0.578000009059906005859375, 0.19300000369548797607421875, 0.0350000001490116119384765625, 0.0030000000260770320892333984375, 0.0, 0.0, 1.0, 1.0, 1.0, 0.6740000247955322265625, 0.3459999859333038330078125, 0.1319999992847442626953125, 0.032999999821186065673828125, 0.0040000001899898052215576171875, 0.0, 0.971000015735626220703125, 0.954999983310699462890625, 0.828999996185302734375, 0.63999998569488525390625, 0.42599999904632568359375, 0.24500000476837158203125, 0.115000002086162567138671875, 0.037000000476837158203125, 0.0030000000260770320892333984375, 0.7469999790191650390625, 0.737999975681304931640625, 0.670000016689300537109375, 0.563000023365020751953125, 0.4309999942779541015625, 0.3039999902248382568359375, 0.1940000057220458984375, 0.1019999980926513671875, 0.0309999994933605194091796875, 0.614000022411346435546875, 0.609000027179718017578125, 0.566999971866607666015625, 0.499000012874603271484375, 0.412000000476837158203125, 0.32400000095367431640625, 0.240999996662139892578125, 0.162000000476837158203125, 0.087999999523162841796875, 0.538999974727630615234375, 0.535000026226043701171875, 0.505999982357025146484375, 0.4569999873638153076171875, 0.393999993801116943359375, 0.328999996185302734375, 0.2660000026226043701171875, 0.203999996185302734375, 0.14200000464916229248046875);\n\nuniform vec4 fa_mesh_fs_params[53];\nuniform vec4 fa_shadows[30];\nuniform vec4 fa_material[2];\nlayout(binding = 0) uniform sampler2D fa_light_tex_fa_shadow_smp;\nlayout(binding = 1) uniform sampler2D fa_tex_fa_smp;\nlayout(binding = 2) uniform sampler2D fa_normal_tex_fa_smp;\nlayout(binding = 3) uniform sampler2D fa_mr_tex_fa_smp;\nlayout(binding = 4) uniform sampler2D fa_occlusion_tex_fa_smp;\nlayout(binding = 5) uniform sampler2D fa_emissive_tex_fa_smp;\nlayout(binding = 6) uniform sampler2D fa_decal_tex_fa_env_smp;\nlayout(binding = 7) uniform sampler2D fa_light_atlas_fa_env_smp;\nlayout(binding = 8) uniform sampler2D fa_shadow_tex_fa_shadow_smp;\nlayout(binding = 9) uniform sampler2D fa_screen_tex_fa_shadow_smp;\nlayout(binding = 10) uniform sampler2D fa_probe_atlas_fa_env_smp;\n\nlayout(location = 0) in vec3 fa_world_pos;\nlayout(location = 5) in vec3 fa_lm;\nlayout(location = 1) in vec3 fa_world_normal;\nlayout(location = 2) in vec4 fa_world_tangent;\nlayout(location = 3) in vec2 fa_uv;\nlayout(location = 4) in vec4 fa_vertex_color;\nlayout(location = 0) out vec4 fa_frag_color;\nvec3 fa_light_tint;\nbool fa_light_is_area;\nint fa_cl_ndir;\nint fa_cl_slot;\nint fa_cl_local;\n\nvoid fa_inst_load()\n{\n}\n\nvec4 fa_light_texel(int t)\n{\n    return texelFetch(fa_light_tex_fa_shadow_smp, ivec2(t & 1023, t >> 10), 0);\n}\n\nvec4 fa_cluster_texel(vec3 world_pos)\n{\n    bool _1397 = fa_mesh_fs_params[19].x < 0.0;\n    bool _1404;\n    if (!_1397)\n    {\n        _1404 = fa_mesh_fs_params[19].w < 1.0;\n    }\n    else\n    {\n        _1404 = _1397;\n    }\n    bool _1412;\n    if (!_1404)\n    {\n        _1412 = fa_mesh_fs_params[18].x < 1.0;\n    }\n    else\n    {\n        _1412 = _1404;\n    }\n    bool _1419;\n    if (!_1412)\n    {\n        _1419 = fa_mesh_fs_params[18].y < 1.0;\n    }\n    else\n    {\n        _1419 = _1412;\n    }\n    bool _1426;\n    if (!_1419)\n    {\n        _1426 = fa_mesh_fs_params[19].y < 1.0;\n    }\n    else\n    {\n        _1426 = _1419;\n    }\n    if (_1426)\n    {\n        return vec4(0.0);\n    }\n    vec4 _1436 = vec4(world_pos, 1.0);\n    float _1442 = dot(fa_mesh_fs_params[16], _1436);\n    if (!(_1442 > 9.9999999747524270787835121154785e-07))\n    {\n        return vec4(0.0);\n    }\n    vec2 _1464 = vec2(dot(fa_mesh_fs_params[14], _1436), dot(fa_mesh_fs_params[15], _1436)) / vec2(_1442);\n    int _1468 = int(fa_mesh_fs_params[18].x);\n    int _1472 = int(fa_mesh_fs_params[18].y);\n    int param = (int(fa_mesh_fs_params[19].x) + (((clamp(int(floor(log2(max(dot(fa_mesh_fs_params[17].xyz, world_pos) + fa_mesh_fs_params[17].w, fa_mesh_fs_params[18].w) / fa_mesh_fs_params[18].w) * fa_mesh_fs_params[18].z)), 0, int(fa_mesh_fs_params[19].y) - 1) * _1472) + clamp(int(floor(((_1464.y * 0.5) + 0.5) * fa_mesh_fs_params[18].y)), 0, _1472 - 1)) * _1468)) + clamp(int(floor(((_1464.x * 0.5) + 0.5) * fa_mesh_fs_params[18].x)), 0, _1468 - 1);\n    return fa_light_texel(param);\n}\n\nivec2 fa_cluster_lookup(vec3 world_pos)\n{\n    vec3 param = world_pos;\n    vec4 _1548 = fa_cluster_texel(param);\n    return ivec2(int(_1548.x), int(_1548.y));\n}\n\nvoid fa_cluster_begin(vec3 world_pos)\n{\n    fa_cl_ndir = int(fa_mesh_fs_params[19].z);\n    vec3 param = world_pos;\n    ivec2 _4886 = fa_cluster_lookup(param);\n    fa_cl_slot = _4886.x;\n    fa_cl_local = _4886.y;\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_linear_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvec3 fa_tex_fix(inout vec3 c, float mode)\n{\n    if (mode > 1.5)\n    {\n        vec3 param = c;\n        vec3 _5263 = fa_linear_to_srgb(param);\n        c = _5263;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            vec3 param_1 = c;\n            vec3 _5271 = fa_srgb_to_linear(param_1);\n            c = _5271;\n        }\n    }\n    return c;\n}\n\nvec3 fa_tangent_normal(SurfaceInput i, vec3 m)\n{\n    vec3 _348;\n    if (i.front_facing)\n    {\n        _348 = i.world_normal;\n    }\n    else\n    {\n        _348 = -i.world_normal;\n    }\n    vec3 _372 = normalize(i.world_tangent.xyz - (_348 * dot(_348, i.world_tangent.xyz)));\n    vec3 _400 = normalize(((_372 * m.x) + ((cross(_348, _372) * i.world_tangent.w) * m.y)) + (_348 * m.z));\n    vec3 _403;\n    if (i.front_facing)\n    {\n        _403 = _400;\n    }\n    else\n    {\n        _403 = -_400;\n    }\n    return _403;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    vec4 base_t = texture(fa_tex_fa_smp, i.uv, fa_mesh_fs_params[12].w);\n    float param = fa_mesh_fs_params[6].w;\n    float param_1 = 1.0;\n    vec3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    vec3 _5303 = fa_tex_fix(param_2, param_3);\n    vec4 _6461 = base_t;\n    _6461.x = _5303.x;\n    _6461.y = _5303.y;\n    _6461.z = _5303.z;\n    base_t = _6461;\n    vec4 _5317 = (_6461 * fa_mesh_fs_params[2]) * i.vertex_color;\n    vec3 _6256 = i.world_normal;\n    if (fa_mesh_fs_params[6].z > 0.5)\n    {\n        float param_4 = fa_mesh_fs_params[6].w;\n        float param_5 = 16.0;\n        vec3 param_6 = texture(fa_normal_tex_fa_smp, i.uv, fa_mesh_fs_params[12].w).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        vec3 _5351 = fa_tex_fix(param_6, param_7);\n        vec3 _5354 = (_5351 * 2.0) - vec3(1.0);\n        vec2 _5359 = _5354.xy * fa_mesh_fs_params[6].x;\n        vec3 _6469 = _5354;\n        _6469.x = _5359.x;\n        _6469.y = _5359.y;\n        SurfaceInput param_8 = i;\n        vec3 param_9 = _6469;\n        _6256 = fa_tangent_normal(param_8, param_9);\n    }\n    vec4 mrt = texture(fa_mr_tex_fa_smp, i.uv, fa_mesh_fs_params[12].w);\n    float param_10 = fa_mesh_fs_params[6].w;\n    float param_11 = 64.0;\n    vec3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    vec3 _5389 = fa_tex_fix(param_12, param_13);\n    vec4 _6472 = mrt;\n    _6472.x = _5389.x;\n    _6472.y = _5389.y;\n    _6472.z = _5389.z;\n    mrt = _6472;\n    vec4 _5419 = texture(fa_occlusion_tex_fa_smp, i.uv, fa_mesh_fs_params[12].w);\n    float param_14 = fa_mesh_fs_params[6].w;\n    float param_15 = 256.0;\n    vec3 param_16 = _5419.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    vec3 _5430 = fa_tex_fix(param_16, param_17);\n    float param_18 = fa_mesh_fs_params[6].w;\n    float param_19 = 4.0;\n    vec3 param_20 = texture(fa_emissive_tex_fa_smp, i.uv, fa_mesh_fs_params[12].w).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    vec3 _5462 = fa_tex_fix(param_20, param_21);\n    float _6261 = fa_mesh_fs_params[20].x;\n    float _6262 = fa_mesh_fs_params[20].y;\n    float _6265 = fa_mesh_fs_params[20].z;\n    float _6264 = fa_mesh_fs_params[21].w;\n    float _6267 = fa_mesh_fs_params[22].x;\n    if (fa_mesh_fs_params[22].z > 0.5)\n    {\n        if (mod(fa_mesh_fs_params[22].z, 2.0) > 0.5)\n        {\n            _6261 *= _5430.y;\n            _6262 *= _5430.z;\n            _6264 *= _5419.w;\n        }\n        if (fa_mesh_fs_params[22].z > 1.5)\n        {\n            _6265 *= mrt.x;\n            _6267 *= mrt.w;\n        }\n    }\n    return Surface(_5317.xyz, _5317.w, _6256, clamp(fa_mesh_fs_params[5].x * _5389.z, 0.0, 1.0), clamp(fa_mesh_fs_params[5].y * _5389.y, 0.0500000007450580596923828125, 1.0), 1.0 + (fa_mesh_fs_params[6].y * (_5430.x - 1.0)), fa_mesh_fs_params[3].xyz + (fa_mesh_fs_params[4].xyz * _5462), _6261, _6262, fa_mesh_fs_params[21].xyz, _6264, _6265, fa_mesh_fs_params[20].w, _6267, fa_mesh_fs_params[22].y, fa_mesh_fs_params[23].xyz, fa_mesh_fs_params[30].x, fa_mesh_fs_params[30].y, fa_mesh_fs_params[31].xyz, fa_mesh_fs_params[30].z);\n}\n\nvoid surface(SurfaceInput i, Surface s)\n{\n}\n\nvec4 fa_decal_tile(vec4 rect, vec2 uv, vec2 atlas, vec2 ddx, vec2 ddy)\n{\n    vec2 _1628 = rect.zw - rect.xy;\n    vec2 _1632 = _1628 * atlas;\n    vec2 _1636 = ddx * _1632;\n    vec2 _1640 = ddy * _1632;\n    return textureLod(fa_decal_tex_fa_env_smp, rect.xy + (clamp(uv, vec2(0.0), vec2(1.0)) * _1628), clamp(0.5 * log2(max(max(dot(_1636, _1636), dot(_1640, _1640)), 9.9999999392252902907785028219223e-09)), 0.0, 3.0));\n}\n\nvec3 fa_dc_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_dc_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvoid fa_apply_decals(vec3 world_pos, vec3 geo_normal, inout vec3 albedo, inout vec3 normal)\n{\n    bool _1673 = fa_mesh_fs_params[10].y < 0.5;\n    bool _1680;\n    if (!_1673)\n    {\n        _1680 = fa_mesh_fs_params[10].w < 0.5;\n    }\n    else\n    {\n        _1680 = _1673;\n    }\n    if (_1680)\n    {\n        return;\n    }\n    vec3 _1686 = dFdx(world_pos);\n    vec3 _1689 = dFdy(world_pos);\n    vec3 param = world_pos;\n    vec4 _1693 = fa_cluster_texel(param);\n    int _1697 = int(_1693.w);\n    if (_1697 < 1)\n    {\n        return;\n    }\n    int _1707 = int(fa_mesh_fs_params[10].y + 0.5);\n    int param_1 = _1707;\n    vec4 _1711 = fa_light_texel(param_1);\n    vec2 _1714 = _1711.yz;\n    int _1718 = int(_1711.w);\n    int param_2 = _1707 + 1;\n    vec4 _1723 = fa_light_texel(param_2);\n    float _1724 = _1723.x;\n    int _1730 = int(fa_mesh_fs_params[10].w + 0.5) - 1;\n    int _1734 = int(_1693.z);\n    vec3 _1999;\n    for (int k = 0; k < _1697; k++)\n    {\n        int _1747 = _1734 + k;\n        int param_3 = _1718 + (_1747 >> 2);\n        int _1764 = (_1707 + 2) + (int(fa_light_texel(param_3)[_1747 & 3]) * 7);\n        int param_4 = _1764 + 6;\n        vec4 _1769 = fa_light_texel(param_4);\n        if (((int(_1769.w + 0.5) >> _1730) & 1) == 0)\n        {\n            continue;\n        }\n        int param_5 = _1764;\n        vec4 _1784 = fa_light_texel(param_5);\n        int param_6 = _1764 + 1;\n        vec4 _1789 = fa_light_texel(param_6);\n        int param_7 = _1764 + 2;\n        vec4 _1794 = fa_light_texel(param_7);\n        vec3 _1797 = _1784.xyz;\n        float _1802 = dot(_1797, world_pos) + _1784.w;\n        vec3 _1804 = _1789.xyz;\n        float _1809 = dot(_1804, world_pos) + _1789.w;\n        vec3 _1811 = _1794.xyz;\n        float _1816 = dot(_1811, world_pos) + _1794.w;\n        bool _1821 = abs(_1802) > 0.5;\n        bool _1829;\n        if (!_1821)\n        {\n            _1829 = abs(_1809) > 0.5;\n        }\n        else\n        {\n            _1829 = _1821;\n        }\n        bool _1837;\n        if (!_1829)\n        {\n            _1837 = abs(_1816) > 0.5;\n        }\n        else\n        {\n            _1837 = _1829;\n        }\n        if (_1837)\n        {\n            continue;\n        }\n        float _1852 = clamp(dot(geo_normal, normalize(_1811)) * _1769.z, 0.0, 1.0);\n        if (_1852 <= 0.0)\n        {\n            continue;\n        }\n        float _1872 = (clamp((0.5 - abs(_1816)) * 10.0, 0.0, 1.0) * _1852) * _1769.x;\n        vec2 _1880 = vec2(_1802 + 0.5, 0.5 - _1809);\n        vec2 _1890 = vec2(dot(_1797, _1686), dot(_1804, _1686));\n        vec2 _1900 = vec2(dot(_1797, _1689), dot(_1804, _1689));\n        int param_8 = _1764 + 5;\n        vec4 _1905 = fa_light_texel(param_8);\n        int param_9 = _1764 + 3;\n        vec4 _1910 = fa_light_texel(param_9);\n        int param_10 = _1764 + 4;\n        vec4 _1915 = fa_light_texel(param_10);\n        float tex_a = 1.0;\n        vec3 col = _1905.xyz;\n        bool _1925 = _1910.z > _1910.x;\n        if (_1925)\n        {\n            vec4 param_11 = _1910;\n            vec2 param_12 = _1880;\n            vec2 param_13 = _1714;\n            vec2 param_14 = _1890;\n            vec2 param_15 = _1900;\n            vec4 tx = fa_decal_tile(param_11, param_12, param_13, param_14, param_15);\n            if ((_1724 > 0.5) && (_1724 < 1.5))\n            {\n                vec3 param_16 = tx.xyz;\n                vec3 _1951 = fa_dc_to_linear(param_16);\n                vec4 _6344 = tx;\n                _6344.x = _1951.x;\n                _6344.y = _1951.y;\n                _6344.z = _1951.z;\n                tx = _6344;\n            }\n            col *= tx.xyz;\n            tex_a = tx.w;\n        }\n        albedo = mix(albedo, col, vec3(clamp((_1872 * tex_a) * _1905.w, 0.0, 1.0)));\n        if (_1915.z > _1915.x)\n        {\n            vec4 param_17 = _1915;\n            vec2 param_18 = _1880;\n            vec2 param_19 = _1714;\n            vec2 param_20 = _1890;\n            vec2 param_21 = _1900;\n            vec4 _1995 = fa_decal_tile(param_17, param_18, param_19, param_20, param_21);\n            if (_1724 > 1.5)\n            {\n                vec3 param_22 = _1995.xyz;\n                vec3 _2005 = fa_dc_to_srgb(param_22);\n                _1999 = _2005;\n            }\n            else\n            {\n                _1999 = _1995.xyz;\n            }\n            vec3 _2014 = (_1999 * 2.0) - vec3(1.0);\n            vec2 _2019 = _2014.xy * _1769.y;\n            vec3 _2041 = (normalize(_1797) * _2019.x) + (normalize(_1804) * _2019.y);\n            vec3 _2044 = normalize(normal);\n            normal = normalize(mix(_2044, normalize((_2044 * max(_2014.z, 0.0500000007450580596923828125)) + (_2041 - (_2044 * dot(_2044, _2041)))), vec3(clamp(_1872 * (_1925 ? tex_a : 1.0), 0.0, 1.0))));\n        }\n    }\n}\n\nint fa_light_count()\n{\n    return fa_cl_ndir + fa_cl_local;\n}\n\nLightSample fa_no_light()\n{\n    return LightSample(vec3(0.0, 1.0, 0.0), vec3(0.0), 0.0, 1.0, 0.0, 0);\n}\n\nint fa_cluster_index(int slot, int n)\n{\n    int param = (int(fa_mesh_fs_params[19].x) + int(fa_mesh_fs_params[19].w)) + ((slot + n) >> 2);\n    vec4 t = fa_light_texel(param);\n    return int(t[(slot + n) & 3]);\n}\n\nint fa_cl_light(int n)\n{\n    if (n < fa_cl_ndir)\n    {\n        return n;\n    }\n    int param = fa_cl_slot;\n    int param_1 = n - fa_cl_ndir;\n    return fa_cluster_index(param, param_1);\n}\n\nint fa_light_base(int li)\n{\n    return li * ((fa_mesh_fs_params[1].w > 4.5) ? 8 : 4);\n}\n\nbool fa_light_baked(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 3;\n    return fa_light_texel(param_1).w > 0.5;\n}\n\nfloat fa_baked_keep(int li)\n{\n    float _4856;\n    if (fa_lm.z > 0.5)\n    {\n        _4856 = 0.0;\n    }\n    else\n    {\n        _4856 = 1.0 - clamp(fa_mesh_fs_params[32].w, 0.0, 1.0);\n    }\n    bool _4867 = _4856 < 1.0;\n    bool _4873;\n    if (_4867)\n    {\n        int param = li;\n        _4873 = fa_light_baked(param);\n    }\n    else\n    {\n        _4873 = _4867;\n    }\n    return _4873 ? _4856 : 1.0;\n}\n\nvec3 fa_area_point(vec3 c, vec3 axis, vec3 ru, vec3 uu, float hx, float hy, float shape, vec3 p, vec3 r)\n{\n    bool _646 = dot(r, r) > 0.5;\n    if (shape > 1.5)\n    {\n        vec3 _659 = (c - (ru * hx)) - p;\n        vec3 _665 = ru * (2.0 * hx);\n        float _671 = max(dot(_665, _665), 9.9999999392252902907785028219223e-09);\n        float _675 = dot(_659, _665);\n        float t = clamp((-_675) / _671, 0.0, 1.0);\n        if (_646)\n        {\n            float _690 = dot(r, _665);\n            float _696 = _671 - (_690 * _690);\n            if (abs(_696) > (9.9999997473787516355514526367188e-06 * _671))\n            {\n                t = clamp(((dot(r, _659) * _690) - _675) / _696, 0.0, 1.0);\n            }\n        }\n        return (p + _659) + (_665 * t);\n    }\n    vec3 q = p;\n    float _728 = dot(r, axis);\n    bool _736;\n    if (_646)\n    {\n        _736 = abs(_728) > 9.9999997473787516355514526367188e-05;\n    }\n    else\n    {\n        _736 = _646;\n    }\n    if (_736)\n    {\n        float _746 = dot(c - p, axis) / _728;\n        if (_746 > 0.0)\n        {\n            q = p + (r * _746);\n        }\n    }\n    vec3 _759 = q - c;\n    vec2 xy = vec2(dot(_759, ru), dot(_759, uu));\n    if (shape > 0.5)\n    {\n        float _774 = length(xy);\n        if (_774 > hx)\n        {\n            xy *= (hx / _774);\n        }\n    }\n    else\n    {\n        xy = clamp(xy, vec2(-hx, -hy), vec2(hx, hy));\n    }\n    return (c + (ru * xy.x)) + (uu * xy.y);\n}\n\nvec4 fa_atlas_fetch(vec2 texel)\n{\n    return textureLod(fa_light_atlas_fa_env_smp, texel / vec2(textureSize(fa_light_atlas_fa_env_smp, 0)), 0.0);\n}\n\nvec3 fa_cookie_sample(vec2 tile_origin, vec2 uv)\n{\n    vec2 param = (tile_origin + vec2(1.0)) + (clamp(uv, vec2(0.0), vec2(1.0)) * 254.0);\n    return fa_atlas_fetch(param).xyz;\n}\n\nfloat fa_ies_sample(vec2 tile_origin, vec3 d, vec3 axis, vec3 right, vec3 up)\n{\n    float _566 = dot(d, right);\n    float _570 = dot(d, up);\n    float _581;\n    if (((_566 * _566) + (_570 * _570)) > 1.0000000133514319600180897396058e-10)\n    {\n        _581 = atan(_570, _566) * 0.15915493667125701904296875;\n    }\n    else\n    {\n        _581 = 0.0;\n    }\n    vec2 param = tile_origin + vec2(1.0 + ((_581 - floor(_581)) * 64.0), 1.0 + (acos(clamp(dot(d, axis), -1.0, 1.0)) * 10.18591594696044921875));\n    return fa_atlas_fetch(param).x;\n}\n\nint fa_cube_face(vec3 d)\n{\n    vec3 _415 = abs(d);\n    float _417 = _415.x;\n    float _419 = _415.y;\n    bool _420 = _417 >= _419;\n    bool _428;\n    if (_420)\n    {\n        _428 = _417 >= _415.z;\n    }\n    else\n    {\n        _428 = _420;\n    }\n    int _429;\n    if (_428)\n    {\n        _429 = (d.x > 0.0) ? 0 : 1;\n    }\n    else\n    {\n        int _444;\n        if (_419 >= _415.z)\n        {\n            _444 = (d.y > 0.0) ? 2 : 3;\n        }\n        else\n        {\n            _444 = (d.z > 0.0) ? 4 : 5;\n        }\n        _429 = _444;\n    }\n    return _429;\n}\n\nvoid fa_cube_face_basis(int f, out vec3 fwd, out vec3 up)\n{\n    if (f == 0)\n    {\n        fwd = vec3(1.0, 0.0, 0.0);\n        up = vec3(0.0, 1.0, 0.0);\n    }\n    else\n    {\n        if (f == 1)\n        {\n            fwd = vec3(-1.0, 0.0, 0.0);\n            up = vec3(0.0, 1.0, 0.0);\n        }\n        else\n        {\n            if (f == 2)\n            {\n                fwd = vec3(0.0, 1.0, 0.0);\n                up = vec3(0.0, 0.0, 1.0);\n            }\n            else\n            {\n                if (f == 3)\n                {\n                    fwd = vec3(0.0, -1.0, 0.0);\n                    up = vec3(0.0, 0.0, -1.0);\n                }\n                else\n                {\n                    if (f == 4)\n                    {\n                        fwd = vec3(0.0, 0.0, 1.0);\n                        up = vec3(0.0, 1.0, 0.0);\n                    }\n                    else\n                    {\n                        fwd = vec3(0.0, 0.0, -1.0);\n                        up = vec3(0.0, 1.0, 0.0);\n                    }\n                }\n            }\n        }\n    }\n}\n\nLightSample fa_light_sample_n(int li, vec3 world_pos, vec3 n)\n{\n    int param = li;\n    int _812 = fa_light_base(param);\n    bool _816 = fa_mesh_fs_params[1].w > 4.5;\n    int param_1 = _812;\n    vec4 _820 = fa_light_texel(param_1);\n    int param_2 = _812 + 1;\n    vec4 _825 = fa_light_texel(param_2);\n    float _828 = _825.w;\n    float atten = 1.0;\n    float dist = 0.0;\n    fa_light_tint = vec3(1.0);\n    bool _840 = _816 && (_828 > 2.5);\n    fa_light_is_area = _840;\n    bool _842 = _828 < 0.5;\n    vec3 l;\n    if (_842)\n    {\n        l = normalize(_820.xyz);\n        if (_816)\n        {\n            int param_3 = _812 + 6;\n            vec4 _856 = fa_light_texel(param_3);\n            if (_856.z > 0.5)\n            {\n                int param_4 = _812 + 4;\n                vec4 _866 = fa_light_texel(param_4);\n                int param_5 = _812 + 5;\n                vec4 _871 = fa_light_texel(param_5);\n                vec2 param_6 = _856.xy;\n                vec2 param_7 = fract(vec2(dot(world_pos, _866.xyz) * _866.w, (-dot(world_pos, _871.xyz)) * _871.w) + vec2(0.5));\n                fa_light_tint = fa_cookie_sample(param_6, param_7);\n            }\n        }\n    }\n    else\n    {\n        vec3 _901 = _820.xyz;\n        vec3 _903 = _901 - world_pos;\n        vec3 to_light = _903;\n        float _906 = length(_903);\n        float reach = _906;\n        bool front = true;\n        if (_840)\n        {\n            int param_8 = _812 + 7;\n            reach = max(_906 - fa_light_texel(param_8).w, 0.0);\n            int param_9 = _812 + 4;\n            vec4 _930 = fa_light_texel(param_9);\n            int param_10 = _812 + 5;\n            vec4 _935 = fa_light_texel(param_10);\n            int param_11 = _812 + 6;\n            vec4 _940 = fa_light_texel(param_11);\n            float _941 = _940.w;\n            int param_12 = _812 + 2;\n            vec3 _948 = normalize(fa_light_texel(param_12).xyz);\n            bool _950 = _941 > 1.5;\n            bool _958;\n            if (!_950)\n            {\n                _958 = dot(_948, to_light) < 0.0;\n            }\n            else\n            {\n                _958 = _950;\n            }\n            front = _958;\n            vec3 r = vec3(0.0);\n            vec3 _967 = fa_mesh_fs_params[0].xyz - world_pos;\n            bool _971 = dot(n, n) > 0.5;\n            bool _979;\n            if (_971)\n            {\n                _979 = dot(_967, _967) > 9.9999999600419720025001879548654e-13;\n            }\n            else\n            {\n                _979 = _971;\n            }\n            if (_979)\n            {\n                r = reflect(-normalize(_967), normalize(n));\n            }\n            vec3 param_13 = _901;\n            vec3 param_14 = _948;\n            vec3 param_15 = _930.xyz;\n            vec3 param_16 = _935.xyz;\n            float param_17 = _930.w;\n            float param_18 = _935.w;\n            float param_19 = _941;\n            vec3 param_20 = world_pos;\n            vec3 param_21 = r;\n            to_light = fa_area_point(param_13, param_14, param_15, param_16, param_17, param_18, param_19, param_20, param_21) - world_pos;\n        }\n        float _1015 = length(to_light);\n        dist = _1015;\n        l = to_light / vec3(max(_1015, 9.9999997473787516355514526367188e-05));\n        float _1029 = reach / max(_820.w, 0.001000000047497451305389404296875);\n        float _1035 = clamp(1.0 - (_1029 * _1029), 0.0, 1.0);\n        float _1037;\n        if (front)\n        {\n            _1037 = _1035 * _1035;\n        }\n        else\n        {\n            _1037 = 0.0;\n        }\n        atten = _1037;\n        bool _1048 = _828 < 2.5;\n        if ((_828 > 1.5) && _1048)\n        {\n            int param_22 = _812 + 2;\n            vec4 _1056 = fa_light_texel(param_22);\n            float _1066 = _1056.w;\n            int param_23 = _812 + 3;\n            vec4 _1071 = fa_light_texel(param_23);\n            float _1072 = _1071.x;\n            float cos_inner = _1072;\n            if (_1072 > 1.5)\n            {\n                cos_inner = mix(_1066, 1.0, 0.25);\n            }\n            atten *= smoothstep(_1066, cos_inner, dot(-l, normalize(_1056.xyz)));\n        }\n        if (_816 && (_828 < 1.5))\n        {\n            int param_24 = _812 + 6;\n            vec4 _1096 = fa_light_texel(param_24);\n            if (_1096.z > 0.5)\n            {\n                vec3 _1104 = -to_light;\n                int param_25 = _812 + 4;\n                int param_26 = _812 + 5;\n                vec3 _1118 = fa_light_texel(param_25).xyz;\n                vec3 _1122 = fa_light_texel(param_26).xyz;\n                vec3 _1131 = vec3(dot(_1104, _1118), dot(_1104, _1122), dot(_1104, cross(_1118, _1122)));\n                vec3 param_27 = _1131;\n                int _1135 = fa_cube_face(param_27);\n                int param_28 = _1135;\n                vec3 param_29;\n                vec3 param_30;\n                fa_cube_face_basis(param_28, param_29, param_30);\n                vec2 _1162 = vec2(dot(_1131, cross(param_29, param_30)), dot(_1131, param_30)) / vec2(max(dot(_1131, param_29), 9.9999997473787516355514526367188e-05));\n                int _1166 = _1135 / 3;\n                vec2 param_31 = _1096.xy + (vec2(float(_1135 - (_1166 * 3)), float(_1166)) * 256.0);\n                vec2 param_32 = vec2(0.5 + (0.5 * _1162.x), 0.5 - (0.5 * _1162.y));\n                fa_light_tint = fa_cookie_sample(param_31, param_32);\n            }\n            int param_33 = _812 + 7;\n            vec4 _1196 = fa_light_texel(param_33);\n            if (_1196.z > 0.5)\n            {\n                int param_34 = _812 + 2;\n                int param_35 = _812 + 4;\n                int param_36 = _812 + 5;\n                vec2 param_37 = _1196.xy;\n                vec3 param_38 = -l;\n                vec3 param_39 = normalize(fa_light_texel(param_34).xyz);\n                vec3 param_40 = fa_light_texel(param_35).xyz;\n                vec3 param_41 = fa_light_texel(param_36).xyz;\n                atten *= fa_ies_sample(param_37, param_38, param_39, param_40, param_41);\n            }\n        }\n        else\n        {\n            if (_816 && _1048)\n            {\n                int param_42 = _812 + 6;\n                vec4 _1243 = fa_light_texel(param_42);\n                int param_43 = _812 + 7;\n                vec4 _1248 = fa_light_texel(param_43);\n                bool _1251 = _1243.z > 0.5;\n                bool _1258;\n                if (!_1251)\n                {\n                    _1258 = _1248.z > 0.5;\n                }\n                else\n                {\n                    _1258 = _1251;\n                }\n                if (_1258)\n                {\n                    int param_44 = _812 + 2;\n                    vec4 _1265 = fa_light_texel(param_44);\n                    vec3 _1269 = normalize(_1265.xyz);\n                    int param_45 = _812 + 4;\n                    vec4 _1274 = fa_light_texel(param_45);\n                    int param_46 = _812 + 5;\n                    vec4 _1279 = fa_light_texel(param_46);\n                    if (_1251)\n                    {\n                        vec3 _1287 = -to_light;\n                        float _1294 = _1265.w;\n                        float _1310 = 0.5 / max(dot(_1287, _1269) * (sqrt(max(1.0 - (_1294 * _1294), 0.0)) / max(_1294, 0.001000000047497451305389404296875)), 9.9999997473787516355514526367188e-05);\n                        vec2 param_47 = _1243.xy;\n                        vec2 param_48 = vec2(0.5 + (dot(_1287, _1274.xyz) * _1310), 0.5 - (dot(_1287, _1279.xyz) * _1310));\n                        fa_light_tint = fa_cookie_sample(param_47, param_48);\n                    }\n                    if (_1248.z > 0.5)\n                    {\n                        vec2 param_49 = _1248.xy;\n                        vec3 param_50 = -l;\n                        vec3 param_51 = _1269;\n                        vec3 param_52 = _1274.xyz;\n                        vec3 param_53 = _1279.xyz;\n                        atten *= fa_ies_sample(param_49, param_50, param_51, param_52, param_53);\n                    }\n                }\n            }\n        }\n    }\n    vec3 _6062 = _825.xyz * atten;\n    if (_816)\n    {\n        _6062 *= fa_light_tint;\n    }\n    int _1379;\n    if (_842)\n    {\n        _1379 = 0;\n    }\n    else\n    {\n        _1379 = ((_828 > 1.5) && (_828 < 2.5)) ? 2 : 1;\n    }\n    return LightSample(l, _6062, atten, 1.0, dist, _1379);\n}\n\nLightSample fa_light_unshadowed(int n, SurfaceInput i)\n{\n    bool _5085 = n < 0;\n    bool _5092;\n    if (!_5085)\n    {\n        _5092 = n >= fa_light_count();\n    }\n    else\n    {\n        _5092 = _5085;\n    }\n    if (_5092)\n    {\n        return fa_no_light();\n    }\n    int param = n;\n    int _5100 = fa_cl_light(param);\n    int param_1 = _5100;\n    float _5104 = fa_baked_keep(param_1);\n    if (_5104 <= 0.0)\n    {\n        return fa_no_light();\n    }\n    int param_2 = _5100;\n    vec3 param_3 = i.world_pos;\n    vec3 param_4 = i.world_normal;\n    LightSample _5120 = fa_light_sample_n(param_2, param_3, param_4);\n    return LightSample(_5120.direction, _5120.color * _5104, _5120.attenuation * _5104, _5120.shadow, _5120._distance, _5120.type);\n}\n\nfloat fa_light_type(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 1;\n    return fa_light_texel(param_1).w;\n}\n\nfloat fa_shadow_depth(inout vec2 uv, vec4 rect)\n{\n    uv = clamp(uv, rect.xy, rect.zw);\n    return textureLod(fa_shadow_tex_fa_shadow_smp, uv, 0.0).x;\n}\n\nfloat fa_shadow_fetch(vec2 uv, vec4 rect, vec3 conv)\n{\n    vec2 param = uv;\n    vec4 param_1 = rect;\n    float _2168 = fa_shadow_depth(param, param_1);\n    float _2172;\n    if (conv.x < 0.5)\n    {\n        _2172 = _2168;\n    }\n    else\n    {\n        _2172 = (conv.y * conv.z) / (conv.z - (_2168 * (conv.z - conv.y)));\n    }\n    return _2172;\n}\n\nfloat fa_shadow_noise()\n{\n    return fract(52.98291778564453125 * fract(dot(gl_FragCoord.xy, vec2(0.067110560834407806396484375, 0.005837149918079376220703125))));\n}\n\nvec2 fa_shadow_vogel_turn(vec2 d)\n{\n    return vec2((d.x * (-0.737368881702423095703125)) - (d.y * 0.675490319728851318359375), (d.y * (-0.737368881702423095703125)) + (d.x * 0.675490319728851318359375));\n}\n\nfloat fa_shadow_filter(vec2 uv, vec4 rect, float zr, float texel_m, float unit, float reach, float plane, vec3 conv, int mode, float k)\n{\n    if (mode == 1)\n    {\n        vec2 param = uv;\n        vec4 param_1 = rect;\n        vec3 param_2 = conv;\n        return float(zr <= fa_shadow_fetch(param, param_1, param_2));\n    }\n    float _2218 = fa_shadow_noise() * 6.283185482025146484375;\n    vec2 _2224 = vec2(cos(_2218), sin(_2218));\n    vec2 dir = _2224;\n    float radius = 1.5;\n    if (mode == 2)\n    {\n        float _2233;\n        if (k < 0.0)\n        {\n            _2233 = (-k) / max(zr, 0.100000001490116119384765625);\n        }\n        else\n        {\n            _2233 = k;\n        }\n        float _2252 = clamp((_2233 * reach) / texel_m, 3.0, 12.0);\n        float sum = 0.0;\n        float cnt = 0.0;\n        for (int i = 0; i < 16; i++)\n        {\n            float _2271 = sqrt((float(i) + 0.5) * 0.0625) * _2252;\n            vec2 param_3 = uv + (dir * (fa_shadows[26].zw * _2271));\n            vec4 param_4 = rect;\n            vec3 param_5 = conv;\n            float _2285 = fa_shadow_fetch(param_3, param_4, param_5);\n            if (_2285 < (zr - (_2271 * plane)))\n            {\n                sum += _2285;\n                cnt += 1.0;\n            }\n            vec2 param_6 = dir;\n            dir = fa_shadow_vogel_turn(param_6);\n        }\n        if (cnt < 0.5)\n        {\n            return 1.0;\n        }\n        float _2313 = sum / cnt;\n        float _2323;\n        if (k < 0.0)\n        {\n            _2323 = (-k) / max(_2313, 0.0500000007450580596923828125);\n        }\n        else\n        {\n            _2323 = k;\n        }\n        radius = clamp(((max(zr - _2313, 0.0) * unit) * _2323) / texel_m, 1.5, 16.0);\n        dir = _2224;\n    }\n    float lit = 0.0;\n    int _2349 = (mode == 2) ? 24 : 16;\n    for (int i_1 = 0; i_1 < _2349; i_1++)\n    {\n        float _2368 = sqrt((float(i_1) + 0.5) / float(_2349)) * radius;\n        vec2 param_7 = uv + (dir * (fa_shadows[26].zw * _2368));\n        vec4 param_8 = rect;\n        vec3 param_9 = conv;\n        lit += float((zr - (_2368 * plane)) <= fa_shadow_fetch(param_7, param_8, param_9));\n        vec2 param_10 = dir;\n        dir = fa_shadow_vogel_turn(param_10);\n    }\n    return lit / float(_2349);\n}\n\nfloat fa_shadow_local(int li, vec3 lpos, vec3 world, vec3 n, vec3 l)\n{\n    bool _2573 = fa_mesh_fs_params[5].z < 0.5;\n    bool _2580;\n    if (!_2573)\n    {\n        _2580 = fa_shadows[29].x < 0.5;\n    }\n    else\n    {\n        _2580 = _2573;\n    }\n    if (_2580)\n    {\n        return 1.0;\n    }\n    int param = (int(fa_shadows[29].x + 0.5) - 1) + li;\n    vec4 _2593 = fa_light_texel(param);\n    float _2594 = _2593.x;\n    if (_2594 < 0.0)\n    {\n        return 1.0;\n    }\n    int _2603 = int(_2594 + 0.5);\n    int param_1 = _2603;\n    vec4 _2607 = fa_light_texel(param_1);\n    int param_2 = _2603 + 1;\n    vec4 _2612 = fa_light_texel(param_2);\n    float fade = 1.0;\n    float _2615 = _2607.y;\n    if (_2615 > 0.0)\n    {\n        float _2632 = 1.0 - smoothstep(0.75 * _2615, _2615, length(world - fa_shadows[27].xyz));\n        fade = _2632;\n        if (_2632 <= 0.0)\n        {\n            return 1.0;\n        }\n    }\n    int face = 0;\n    if (_2607.x > 1.5)\n    {\n        vec3 param_3 = world - lpos;\n        face = fa_cube_face(param_3);\n    }\n    int _2656 = (_2603 + 2) + (face * 6);\n    int param_4 = _2656;\n    int param_5 = _2656 + 1;\n    int param_6 = _2656 + 3;\n    vec4 _2670 = fa_light_texel(param_6);\n    int param_7 = _2656 + 4;\n    vec4 _2675 = fa_light_texel(param_7);\n    int param_8 = _2656 + 5;\n    vec4 _2680 = fa_light_texel(param_8);\n    float _2692 = _2680.x * max(dot(_2670, vec4(world, 1.0)), 0.001000000047497451305389404296875);\n    float _2697 = clamp(dot(n, l), 0.0, 1.0);\n    float _2720 = clamp(dot(n, _2670.xyz), -1.0, 1.0);\n    float _2739 = min(sqrt(1.0 - (_2720 * _2720)) / max(abs(dot(n, world - lpos)) / max(dot(_2670, vec4(world, 1.0)), 0.001000000047497451305389404296875), 0.20000000298023223876953125), 4.0);\n    float _2742 = _2612.y;\n    float _2744;\n    if (_2742 > 0.0)\n    {\n        _2744 = _2742;\n    }\n    else\n    {\n        _2744 = 1.5 * _2692;\n    }\n    vec4 _2764 = vec4(world + (n * (_2744 * sqrt(1.0 - (_2697 * _2697)))), 1.0);\n    float _2768 = dot(_2670, _2764);\n    float _2771 = _2680.y;\n    if (_2768 < _2771)\n    {\n        return 1.0;\n    }\n    vec2 _2786 = vec2(dot(fa_light_texel(param_4), _2764), dot(fa_light_texel(param_5), _2764)) / vec2(_2768);\n    float _2788 = _2786.x;\n    bool _2791 = _2788 < _2675.x;\n    bool _2800;\n    if (!_2791)\n    {\n        _2800 = _2788 > _2675.z;\n    }\n    else\n    {\n        _2800 = _2791;\n    }\n    bool _2809;\n    if (!_2800)\n    {\n        _2809 = _2786.y < _2675.y;\n    }\n    else\n    {\n        _2809 = _2800;\n    }\n    bool _2818;\n    if (!_2809)\n    {\n        _2818 = _2786.y > _2675.w;\n    }\n    else\n    {\n        _2818 = _2809;\n    }\n    if (_2818)\n    {\n        return 1.0;\n    }\n    float _2824 = _2612.x;\n    float _2826;\n    if (_2824 > 0.0)\n    {\n        _2826 = _2824;\n    }\n    else\n    {\n        _2826 = 1.5 * _2692;\n    }\n    vec2 param_9 = _2786;\n    vec4 param_10 = _2675;\n    float param_11 = _2768 - (_2826 * (1.0 + (0.5 * _2739)));\n    float param_12 = _2692;\n    float param_13 = 1.0;\n    float param_14 = _2680.z * 0.25;\n    float param_15 = (_2692 * min(_2739, 3.0)) * 0.5;\n    vec3 param_16 = vec3(1.0, _2771, _2680.z);\n    int param_17 = int(_2607.z + 0.5);\n    float param_18 = _2607.w;\n    return mix(1.0, fa_shadow_filter(param_9, param_10, param_11, param_12, param_13, param_14, param_15, param_16, param_17, param_18), fade);\n}\n\nfloat fa_shadow_split_at(int i)\n{\n    float _2111;\n    if (i == 0)\n    {\n        _2111 = fa_shadows[24].x;\n    }\n    else\n    {\n        float _2127;\n        if (i == 1)\n        {\n            _2127 = fa_shadows[24].y;\n        }\n        else\n        {\n            float _2135;\n            if (i == 2)\n            {\n                _2135 = fa_shadows[24].z;\n            }\n            else\n            {\n                _2135 = fa_shadows[24].w;\n            }\n            _2127 = _2135;\n        }\n        _2111 = _2127;\n    }\n    return _2111;\n}\n\nfloat fa_shadow_cascade(int ci, vec3 world, vec3 n, vec3 l)\n{\n    float _2414 = max(fa_shadows[ci * 1 + 20].y, 0.001000000047497451305389404296875);\n    float _2419 = clamp(dot(n, l), 0.0, 1.0);\n    float _2425 = sqrt(1.0 - (_2419 * _2419));\n    float _2433 = min(_2425 / max(_2419, 0.20000000298023223876953125), 4.0);\n    float _2438;\n    if (fa_shadows[26].y > 0.0)\n    {\n        _2438 = fa_shadows[26].y;\n    }\n    else\n    {\n        _2438 = 1.5 * fa_shadows[ci * 1 + 20].x;\n    }\n    vec4 _2463 = mat4(fa_shadows[ci * 4 + 0], fa_shadows[ci * 4 + 1], fa_shadows[ci * 4 + 2], fa_shadows[ci * 4 + 3]) * vec4(world + (n * (_2438 * _2425)), 1.0);\n    float _2470 = _2463.x;\n    bool _2473 = _2470 < fa_shadows[ci * 1 + 16].x;\n    bool _2482;\n    if (!_2473)\n    {\n        _2482 = _2470 > fa_shadows[ci * 1 + 16].z;\n    }\n    else\n    {\n        _2482 = _2473;\n    }\n    bool _2491;\n    if (!_2482)\n    {\n        _2491 = _2463.y < fa_shadows[ci * 1 + 16].y;\n    }\n    else\n    {\n        _2491 = _2482;\n    }\n    bool _2500;\n    if (!_2491)\n    {\n        _2500 = _2463.y > fa_shadows[ci * 1 + 16].w;\n    }\n    else\n    {\n        _2500 = _2491;\n    }\n    bool _2507;\n    if (!_2500)\n    {\n        _2507 = _2463.z > 1.0;\n    }\n    else\n    {\n        _2507 = _2500;\n    }\n    if (_2507)\n    {\n        return -1.0;\n    }\n    float _2515;\n    if (fa_shadows[26].x > 0.0)\n    {\n        _2515 = fa_shadows[26].x;\n    }\n    else\n    {\n        _2515 = 1.5 * fa_shadows[ci * 1 + 20].x;\n    }\n    vec2 param = _2463.xy;\n    vec4 param_1 = fa_shadows[ci * 1 + 16];\n    float param_2 = _2463.z - ((_2515 * (1.0 + (0.5 * _2433))) / _2414);\n    float param_3 = fa_shadows[ci * 1 + 20].x;\n    float param_4 = _2414;\n    float param_5 = _2414 * 0.25;\n    float param_6 = ((fa_shadows[ci * 1 + 20].x * min(_2433, 3.0)) * 0.5) / _2414;\n    vec3 param_7 = vec3(0.0);\n    int param_8 = int(fa_shadows[25].z + 0.5);\n    float param_9 = fa_shadows[25].w;\n    return fa_shadow_filter(param, param_1, param_2, param_3, param_4, param_5, param_6, param_7, param_8, param_9);\n}\n\nfloat fa_shadow_sun(vec3 world, vec3 n, vec3 l)\n{\n    if (fa_mesh_fs_params[5].z < 0.5)\n    {\n        return 1.0;\n    }\n    int _2893 = int(fa_shadows[25].x + 0.5);\n    if (_2893 < 1)\n    {\n        return 1.0;\n    }\n    float _2908 = dot(world - fa_shadows[27].xyz, fa_shadows[28].xyz);\n    int param = _2893 - 1;\n    if (_2908 > fa_shadow_split_at(param))\n    {\n        return 1.0;\n    }\n    int ci = 0;\n    bool _2920 = _2893 > 1;\n    bool _2927;\n    if (_2920)\n    {\n        _2927 = _2908 > fa_shadows[24].x;\n    }\n    else\n    {\n        _2927 = _2920;\n    }\n    if (_2927)\n    {\n        ci = 1;\n    }\n    bool _2931 = _2893 > 2;\n    bool _2938;\n    if (_2931)\n    {\n        _2938 = _2908 > fa_shadows[24].y;\n    }\n    else\n    {\n        _2938 = _2931;\n    }\n    if (_2938)\n    {\n        ci = 2;\n    }\n    bool _2942 = _2893 > 3;\n    bool _2949;\n    if (_2942)\n    {\n        _2949 = _2908 > fa_shadows[24].z;\n    }\n    else\n    {\n        _2949 = _2942;\n    }\n    if (_2949)\n    {\n        ci = 3;\n    }\n    float s = -1.0;\n    float s2 = -1.0;\n    float t = 0.0;\n    int _2960 = min(_2893, 4);\n    float _3001;\n    for (int c = ci; c < _2960; c++)\n    {\n        int param_1 = c;\n        vec3 param_2 = world;\n        vec3 param_3 = n;\n        vec3 param_4 = l;\n        float _2980 = fa_shadow_cascade(param_1, param_2, param_3, param_4);\n        if (s >= 0.0)\n        {\n            s2 = _2980;\n            break;\n        }\n        if (_2980 < 0.0)\n        {\n            continue;\n        }\n        s = _2980;\n        ci = c;\n        if (fa_shadows[25].y > 0.0)\n        {\n            if (ci > 0)\n            {\n                int param_5 = ci - 1;\n                _3001 = fa_shadow_split_at(param_5);\n            }\n            else\n            {\n                _3001 = fa_shadows[28].w;\n            }\n            int param_6 = ci;\n            float _3020 = fa_shadows[25].y * max(fa_shadow_split_at(param_6) - _3001, 9.9999997473787516355514526367188e-05);\n            int param_7 = ci;\n            t = clamp((_2908 - (fa_shadow_split_at(param_7) - _3020)) / _3020, 0.0, 1.0);\n        }\n        if (t <= 0.0)\n        {\n            break;\n        }\n    }\n    if (s < 0.0)\n    {\n        return 1.0;\n    }\n    if (t > 0.0)\n    {\n        float _3052;\n        if ((ci + 1) < _2893)\n        {\n            _3052 = (s2 < 0.0) ? s : s2;\n        }\n        else\n        {\n            _3052 = 1.0;\n        }\n        s = mix(s, _3052, t);\n    }\n    return s;\n}\n\nfloat fa_shadow_factor(vec3 n, vec3 l)\n{\n    bool _3157 = fa_mesh_fs_params[25].y > 0.5;\n    bool _3163;\n    if (_3157)\n    {\n        _3163 = fa_mesh_fs_params[5].z > 0.5;\n    }\n    else\n    {\n        _3163 = _3157;\n    }\n    if (_3163)\n    {\n        float _3177 = dot(fa_mesh_fs_params[29].xyz, fa_world_pos) + fa_mesh_fs_params[29].w;\n        float _3180 = fwidth(_3177);\n        vec4 _3190 = vec4(fa_world_pos, 1.0);\n        float _3196 = dot(fa_mesh_fs_params[28], _3190);\n        if (_3196 > 9.9999997473787516355514526367188e-05)\n        {\n            vec2 _3215 = vec2(dot(fa_mesh_fs_params[26], _3190), dot(fa_mesh_fs_params[27], _3190)) / vec2(_3196);\n            float _3220 = (_3215.x * 0.5) + 0.5;\n            float _3224;\n            if (fa_mesh_fs_params[24].y > 0.5)\n            {\n                _3224 = (_3215.y * 0.5) + 0.5;\n            }\n            else\n            {\n                _3224 = 0.5 - (_3215.y * 0.5);\n            }\n            bool _3240 = _3220 >= 0.0;\n            bool _3246;\n            if (_3240)\n            {\n                _3246 = _3220 < 1.0;\n            }\n            else\n            {\n                _3246 = _3240;\n            }\n            bool _3252;\n            if (_3246)\n            {\n                _3252 = _3224 >= 0.0;\n            }\n            else\n            {\n                _3252 = _3246;\n            }\n            bool _3258;\n            if (_3252)\n            {\n                _3258 = _3224 < 1.0;\n            }\n            else\n            {\n                _3258 = _3252;\n            }\n            if (_3258)\n            {\n                vec4 _3284 = texelFetch(fa_screen_tex_fa_shadow_smp, clamp(ivec2(vec2(_3220, _3224) * fa_mesh_fs_params[24].zw), ivec2(0), ivec2(fa_mesh_fs_params[24].zw) - ivec2(1)), 0);\n                bool _3287 = _3284.w > 0.5;\n                bool _3303;\n                if (_3287)\n                {\n                    _3303 = abs(_3177 - _3284.x) <= (((0.00200000009499490261077880859375 * _3177) + 0.00999999977648258209228515625) + min(1.5 * _3180, 0.100000001490116119384765625 * _3177));\n                }\n                else\n                {\n                    _3303 = _3287;\n                }\n                if (_3303)\n                {\n                    float _3309;\n                    if (fa_mesh_fs_params[25].z > 0.5)\n                    {\n                        vec3 param = fa_world_pos;\n                        vec3 param_1 = n;\n                        vec3 param_2 = l;\n                        _3309 = min(_3284.y, fa_shadow_sun(param, param_1, param_2));\n                    }\n                    else\n                    {\n                        _3309 = _3284.y;\n                    }\n                    return _3309;\n                }\n            }\n        }\n    }\n    vec3 param_3 = fa_world_pos;\n    vec3 param_4 = n;\n    vec3 param_5 = l;\n    return fa_shadow_sun(param_3, param_4, param_5);\n}\n\nfloat fa_contact_shadow(int li, vec3 world, vec3 gn, vec3 l, float dist)\n{\n    bool _4600 = fa_mesh_fs_params[24].x < 0.5;\n    bool _4607;\n    if (!_4600)\n    {\n        _4607 = fa_shadows[29].x < 0.5;\n    }\n    else\n    {\n        _4607 = _4600;\n    }\n    if (_4607)\n    {\n        return 1.0;\n    }\n    int param = (int(fa_shadows[29].x + 0.5) - 1) + li;\n    vec4 _4620 = fa_light_texel(param);\n    float _4621 = _4620.y;\n    float len = _4621;\n    if (_4621 <= 0.0)\n    {\n        return 1.0;\n    }\n    float _4633 = length(world - fa_mesh_fs_params[0].xyz);\n    float _4642 = 1.0 - smoothstep(0.5 * fa_mesh_fs_params[25].x, fa_mesh_fs_params[25].x, _4633);\n    if (_4642 <= 0.0)\n    {\n        return 1.0;\n    }\n    float _4648 = len;\n    float _4651 = min(_4648, 0.89999997615814208984375 * dist);\n    len = _4651;\n    float _4656 = 0.004999999888241291046142578125 + (0.0030000000260770320892333984375 * _4633);\n    float _4661 = _4656 + (0.5 * _4651);\n    vec3 _4667 = world + (gn * _4656);\n    float _4669 = fa_shadow_noise();\n    float occ = 0.0;\n    float _4730;\n    for (int k = 0; k < 12; k++)\n    {\n        float _4684 = (float(k) + _4669) * 0.083333335816860198974609375;\n        vec3 _4692 = _4667 + (l * (_4684 * len));\n        vec4 _4698 = vec4(_4692, 1.0);\n        float _4703 = dot(fa_mesh_fs_params[28], _4698);\n        if (_4703 < 9.9999997473787516355514526367188e-05)\n        {\n            break;\n        }\n        vec2 _4721 = vec2(dot(fa_mesh_fs_params[26], _4698), dot(fa_mesh_fs_params[27], _4698)) / vec2(_4703);\n        float _4725 = _4721.x * 0.5;\n        float _4726 = _4725 + 0.5;\n        if (fa_mesh_fs_params[24].y > 0.5)\n        {\n            _4730 = (_4721.y * 0.5) + 0.5;\n        }\n        else\n        {\n            _4730 = 0.5 - (_4721.y * 0.5);\n        }\n        bool _4746 = _4726 < 0.0;\n        bool _4753;\n        if (!_4746)\n        {\n            _4753 = _4726 >= 1.0;\n        }\n        else\n        {\n            _4753 = _4746;\n        }\n        bool _4760;\n        if (!_4753)\n        {\n            _4760 = _4730 < 0.0;\n        }\n        else\n        {\n            _4760 = _4753;\n        }\n        bool _4767;\n        if (!_4760)\n        {\n            _4767 = _4730 >= 1.0;\n        }\n        else\n        {\n            _4767 = _4760;\n        }\n        if (_4767)\n        {\n            break;\n        }\n        vec4 _4791 = texelFetch(fa_screen_tex_fa_shadow_smp, clamp(ivec2(vec2(_4726, _4730) * fa_mesh_fs_params[24].zw), ivec2(0), ivec2(fa_mesh_fs_params[24].zw) - ivec2(1)), 0);\n        if (_4791.w < 0.5)\n        {\n            continue;\n        }\n        float _4809 = (dot(fa_mesh_fs_params[29].xyz, _4692) + fa_mesh_fs_params[29].w) - _4791.x;\n        if ((_4809 > _4656) && (_4809 < _4661))\n        {\n            occ = max(occ, (1.0 - (_4684 * _4684)) * smoothstep(0.0, 0.0500000007450580596923828125, min(min(_4726, 0.5 - _4725), min(_4730, 1.0 - _4730))));\n        }\n    }\n    return 1.0 - (occ * _4642);\n}\n\nLightSample fa_light_shadowed(int li, vec3 world_pos, vec3 gn)\n{\n    int param = li;\n    float _4912 = fa_baked_keep(param);\n    if (_4912 <= 0.0)\n    {\n        int param_1 = li;\n        return LightSample(vec3(0.0, 1.0, 0.0), vec3(0.0), 0.0, 1.0, 0.0, int(fa_light_type(param_1) + 0.5));\n    }\n    int param_2 = li;\n    vec3 param_3 = world_pos;\n    vec3 param_4 = gn;\n    LightSample _4938 = fa_light_sample_n(param_2, param_3, param_4);\n    vec3 _6208 = _4938.color;\n    float _6209 = _4938.attenuation;\n    float _6210 = _4938.shadow;\n    bool _4941 = _4938.type == 0;\n    if (_4941 && (li == 0))\n    {\n        vec3 param_5 = gn;\n        vec3 param_6 = _4938.direction;\n        float _4952 = fa_shadow_factor(param_5, param_6);\n        _6210 = _4952;\n        _6208 *= _4952;\n    }\n    else\n    {\n        bool _4963 = _4938.type != 0;\n        bool _4969;\n        if (_4963)\n        {\n            _4969 = _6209 > 0.0;\n        }\n        else\n        {\n            _4969 = _4963;\n        }\n        if (_4969)\n        {\n            int param_7 = li;\n            int param_8 = fa_light_base(param_7);\n            int param_9 = li;\n            vec3 param_10 = fa_light_texel(param_8).xyz;\n            vec3 param_11 = world_pos;\n            vec3 param_12 = gn;\n            vec3 param_13 = _4938.direction;\n            float _4988 = fa_shadow_local(param_9, param_10, param_11, param_12, param_13);\n            _6210 = _4988;\n            _6208 *= _4988;\n        }\n    }\n    bool _4998 = fa_mesh_fs_params[24].x > 0.5;\n    bool _5004;\n    if (_4998)\n    {\n        _5004 = _6209 > 0.0;\n    }\n    else\n    {\n        _5004 = _4998;\n    }\n    if (_5004)\n    {\n        float _5011;\n        if (_4941)\n        {\n            _5011 = 1000000000.0;\n        }\n        else\n        {\n            _5011 = _4938._distance;\n        }\n        int param_14 = li;\n        vec3 param_15 = world_pos;\n        vec3 param_16 = gn;\n        vec3 param_17 = _4938.direction;\n        float param_18 = _5011;\n        float _5029 = fa_contact_shadow(param_14, param_15, param_16, param_17, param_18);\n        _6210 *= _5029;\n        _6208 *= _5029;\n    }\n    float _5042 = _6209;\n    float _5043 = _5042 * _4912;\n    _6209 = _5043;\n    vec3 _5047 = _6208;\n    vec3 _5048 = _5047 * _4912;\n    _6208 = _5048;\n    return LightSample(_4938.direction, _5048, _5043, _6210, _4938._distance, _4938.type);\n}\n\nLightSample fa_light(int n, SurfaceInput i)\n{\n    bool _5059 = n < 0;\n    bool _5066;\n    if (!_5059)\n    {\n        _5066 = n >= fa_light_count();\n    }\n    else\n    {\n        _5066 = _5059;\n    }\n    if (_5066)\n    {\n        return fa_no_light();\n    }\n    int param = n;\n    int param_1 = fa_cl_light(param);\n    vec3 param_2 = i.world_pos;\n    vec3 param_3 = i.world_normal;\n    LightSample _5081 = fa_light_shadowed(param_1, param_2, param_3);\n    return _5081;\n}\n\nfloat fa_sheen_albedo(float ndv, float rough)\n{\n    float _3985 = min(sqrt(max(rough - 0.100000001490116119384765625, 0.0) * 1.111111164093017578125) * 6.0, 5.999000072479248046875);\n    float _3993 = min(sqrt(clamp(ndv, 0.0, 1.0)) * 8.0, 7.999000072479248046875);\n    int _3996 = int(_3985);\n    int _3999 = int(_3993);\n    float _4009 = _3993 - float(_3999);\n    int _4065 = (_3996 * 9) + _3999;\n    int _4085 = ((_3996 + 1) * 9) + _3999;\n    return mix(mix(_4060[_4065], _4060[_4065 + 1], _4009), mix(_4060[_4085], _4060[_4085 + 1], _4009), _3985 - float(_3996));\n}\n\nFaLayers fa_layers_setup(SurfaceInput i, Surface s, vec3 n, vec3 v, float metallic, float roughness, inout vec3 f0)\n{\n    bool _6074 = false;\n    float _6075 = 1.0;\n    float _6076 = 1.0;\n    float _6077 = 1.0;\n    float _6078 = 0.0;\n    float _6079 = 0.0;\n    float _6080 = 0.0;\n    float _6081 = 0.0;\n    float _6083 = 1.0;\n    bool _6084 = false;\n    vec3 _6085 = vec3(0.0);\n    float _6086 = 1.0;\n    float _6087 = 1.0;\n    float _6088 = 1.0;\n    float _6089 = 0.0;\n    float _6090 = 0.0;\n    vec3 _6091 = vec3(1.0, 0.0, 0.0);\n    vec3 _6092 = vec3(0.0, 0.0, 1.0);\n    float _6093 = 1.0;\n    float _6094 = 1.0;\n    float _4136 = clamp(s.specular, 0.0, 1.0);\n    float _4140 = clamp(s.ior, 1.0, 3.0);\n    bool _4145 = (_4136 != 1.0) || (_4140 != 1.5);\n    bool _4154;\n    if (!_4145)\n    {\n        _4154 = any(notEqual(s.specular_color, vec3(1.0)));\n    }\n    else\n    {\n        _4154 = _4145;\n    }\n    if (_4154)\n    {\n        float _4162 = (_4140 - 1.0) / (_4140 + 1.0);\n        f0 = mix(min(vec3(_4162 * _4162) * max(s.specular_color, vec3(0.0)), vec3(1.0)) * _4136, s.albedo, vec3(metallic));\n        _6075 = mix(_4136, 1.0, metallic);\n        _6074 = true;\n    }\n    float _4189 = clamp(s.clearcoat, 0.0, 1.0);\n    if (_4189 > 0.0)\n    {\n        float _4197 = clamp(s.clearcoat_roughness, 0.0500000007450580596923828125, 1.0);\n        _6078 = _4189;\n        _6079 = _4197;\n        float _4204 = _4197 * _4197;\n        _6080 = _4204;\n        _6081 = _4204 * _4204;\n        float _4216 = max(dot(i.world_normal, v), 9.9999997473787516355514526367188e-05);\n        _6083 = _4216;\n        _6076 = 1.0 - (_4189 * (0.039999999105930328369140625 + (0.959999978542327880859375 * pow(clamp(1.0 - _4216, 0.0, 1.0), 5.0))));\n        _6074 = true;\n    }\n    vec3 _4235 = max(s.sheen_color, vec3(0.0));\n    float _4244 = max(_4235.x, max(_4235.y, _4235.z));\n    if (_4244 > 0.0)\n    {\n        float _4252 = clamp(s.sheen_roughness, 0.100000001490116119384765625, 1.0);\n        _6084 = true;\n        _6085 = _4235;\n        _6086 = _4252;\n        _6087 = _4252 * _4252;\n        float param = max(dot(n, v), 9.9999997473787516355514526367188e-05);\n        float param_1 = _4252;\n        float _4269 = fa_sheen_albedo(param, param_1);\n        _6089 = _4269;\n        _6088 = 1.0 - min(_4244 * _4269, 1.0);\n        _6074 = true;\n    }\n    _6077 = _6076 * _6088;\n    float _4288 = clamp(s.anisotropy, -1.0, 1.0);\n    if (_4288 != 0.0)\n    {\n        vec3 _4303 = i.world_tangent.xyz - (n * dot(n, i.world_tangent.xyz));\n        vec3 t = _4303;\n        if (dot(_4303, _4303) < 9.9999999392252902907785028219223e-09)\n        {\n            bvec3 _4315 = bvec3(abs(n.y) < 0.9900000095367431640625);\n            t = cross(vec3(_4315.x ? vec3(0.0, 1.0, 0.0).x : vec3(1.0, 0.0, 0.0).x, _4315.y ? vec3(0.0, 1.0, 0.0).y : vec3(1.0, 0.0, 0.0).y, _4315.z ? vec3(0.0, 1.0, 0.0).z : vec3(1.0, 0.0, 0.0).z), n);\n        }\n        vec3 _4319 = t;\n        vec3 _4320 = normalize(_4319);\n        t = _4320;\n        vec3 _4345 = normalize((_4320 * cos(s.anisotropy_rotation)) + ((cross(n, _4320) * ((i.world_tangent.w < 0.0) ? (-1.0) : 1.0)) * sin(s.anisotropy_rotation)));\n        _6091 = _4345;\n        _6092 = cross(n, _4345);\n        float _4355 = roughness * roughness;\n        float _4361 = mix(_4355, 1.0, _4288 * _4288);\n        bool _4363 = _4288 > 0.0;\n        _6093 = _4363 ? _4361 : _4355;\n        _6094 = _4363 ? _4355 : _4361;\n        _6090 = _4288;\n        _6074 = true;\n    }\n    return FaLayers(_6074, _6075, _6076, _6077, _6078, _6079, _6080, _6081, i.world_normal, _6083, _6084, _6085, _6086, _6087, _6088, _6089, _6090, _6091, _6092, _6093, _6094);\n}\n\nvec2 fa_env_brdf(float rough, float ndv)\n{\n    vec4 _3917 = (vec4(-1.0, -0.0274999998509883880615234375, -0.572000026702880859375, 0.02199999988079071044921875) * rough) + vec4(1.0, 0.0425000004470348358154296875, 1.03999996185302734375, -0.039999999105930328369140625);\n    float _3920 = _3917.x;\n    return (vec2(-1.03999996185302734375, 1.03999996185302734375) * ((min(_3920 * _3920, exp2((-9.27999973297119140625) * ndv)) * _3920) + _3917.y)) + _3917.zw;\n}\n\nvec2 fa_oct_encode(vec3 d)\n{\n    vec3 _3353 = d / vec3(max((abs(d.x) + abs(d.y)) + abs(d.z), 9.9999999600419720025001879548654e-13));\n    float _3356 = _3353.x;\n    float _3358 = _3353.z;\n    vec2 e = vec2(_3356, _3358);\n    if (_3353.y < 0.0)\n    {\n        e = vec2((1.0 - abs(_3358)) * ((_3356 < 0.0) ? (-1.0) : 1.0), (1.0 - abs(_3356)) * ((_3358 < 0.0) ? (-1.0) : 1.0));\n    }\n    return e;\n}\n\nvec2 fa_atlas_size()\n{\n    return vec2(textureSize(fa_probe_atlas_fa_env_smp, 0));\n}\n\nvec3 fa_probe_level(vec2 origin, float res, int lv, vec2 e)\n{\n    float _3405;\n    if (lv == 0)\n    {\n        _3405 = 0.0;\n    }\n    else\n    {\n        _3405 = res + 2.0;\n    }\n    float _3415;\n    if (lv == 0)\n    {\n        _3415 = 0.0;\n    }\n    else\n    {\n        _3415 = (res - (res / float(1 << max((lv - 1), 0)))) + (2.0 * float(lv - 1));\n    }\n    return textureLod(fa_probe_atlas_fa_env_smp, (((origin + vec2(_3405, _3415)) + vec2(1.0)) + (((e * 0.5) + vec2(0.5)) * (res / float(1 << lv)))) / fa_atlas_size(), 0.0).xyz;\n}\n\nvec3 fa_probe_radiance(vec2 origin, float res, vec3 d, float rough)\n{\n    float _3461;\n    if (res > 64.5)\n    {\n        _3461 = 5.0;\n    }\n    else\n    {\n        _3461 = (res > 32.5) ? 4.0 : 3.0;\n    }\n    float _3476 = clamp(rough, 0.0, 1.0) * (_3461 - 1.0);\n    int _3483 = int(min(floor(_3476), _3461 - 2.0));\n    float _3488 = _3476 - float(_3483);\n    vec3 param = d;\n    vec2 _3492 = fa_oct_encode(param);\n    vec2 param_1 = origin;\n    float param_2 = res;\n    int param_3 = _3483;\n    vec2 param_4 = _3492;\n    vec3 _3502 = fa_probe_level(param_1, param_2, param_3, param_4);\n    if (_3488 < 0.00200000009499490261077880859375)\n    {\n        return _3502;\n    }\n    vec2 param_5 = origin;\n    float param_6 = res;\n    int param_7 = _3483 + 1;\n    vec2 param_8 = _3492;\n    return mix(_3502, fa_probe_level(param_5, param_6, param_7, param_8), vec3(_3488));\n}\n\nvec3 fa_probe_box_dir(vec3 d, vec4 posw, vec4 bx, vec4 by, vec4 bz)\n{\n    if (posw.w < 0.5)\n    {\n        return d;\n    }\n    float _3539 = dot(bx.xyz, fa_world_pos) + bx.w;\n    float _3546 = dot(by.xyz, fa_world_pos) + by.w;\n    float _3553 = dot(bz.xyz, fa_world_pos) + bz.w;\n    float _3559 = dot(bx.xyz, d);\n    float _3563 = dot(by.xyz, d);\n    float _3567 = dot(bz.xyz, d);\n    float _3573;\n    if (_3559 > 9.9999999747524270787835121154785e-07)\n    {\n        _3573 = (1.0 - _3539) / _3559;\n    }\n    else\n    {\n        float _3587;\n        if (_3559 < (-9.9999999747524270787835121154785e-07))\n        {\n            _3587 = ((-1.0) - _3539) / _3559;\n        }\n        else\n        {\n            _3587 = 1000000015047466219876688855040.0;\n        }\n        _3573 = _3587;\n    }\n    float tx = _3573;\n    float _3604;\n    if (_3563 > 9.9999999747524270787835121154785e-07)\n    {\n        _3604 = (1.0 - _3546) / _3563;\n    }\n    else\n    {\n        float _3617;\n        if (_3563 < (-9.9999999747524270787835121154785e-07))\n        {\n            _3617 = ((-1.0) - _3546) / _3563;\n        }\n        else\n        {\n            _3617 = 1000000015047466219876688855040.0;\n        }\n        _3604 = _3617;\n    }\n    float ty = _3604;\n    float _3633;\n    if (_3567 > 9.9999999747524270787835121154785e-07)\n    {\n        _3633 = (1.0 - _3553) / _3567;\n    }\n    else\n    {\n        float _3646;\n        if (_3567 < (-9.9999999747524270787835121154785e-07))\n        {\n            _3646 = ((-1.0) - _3553) / _3567;\n        }\n        else\n        {\n            _3646 = 1000000015047466219876688855040.0;\n        }\n        _3633 = _3646;\n    }\n    float _3658 = tx;\n    float _3661 = (_3658 > 0.0) ? _3658 : 1000000015047466219876688855040.0;\n    tx = _3661;\n    float _3662 = ty;\n    float _3665 = (_3662 > 0.0) ? _3662 : 1000000015047466219876688855040.0;\n    ty = _3665;\n    float _3675 = min(_3661, min(_3665, (_3633 > 0.0) ? _3633 : 1000000015047466219876688855040.0));\n    if (_3675 > 100000001504746621987668885504.0)\n    {\n        return d;\n    }\n    vec3 _3691 = (fa_world_pos + (d * _3675)) - posw.xyz;\n    vec3 _3696;\n    if (dot(_3691, _3691) > 1.0000000133514319600180897396058e-10)\n    {\n        _3696 = normalize(_3691);\n    }\n    else\n    {\n        _3696 = d;\n    }\n    return _3696;\n}\n\nvec3 fa_probe_environment(vec4 tile, vec4 posw, vec4 bx, vec4 by, vec4 bz, inout vec3 d, float rough)\n{\n    vec3 param = d;\n    vec4 param_1 = posw;\n    vec4 param_2 = bx;\n    vec4 param_3 = by;\n    vec4 param_4 = bz;\n    d = fa_probe_box_dir(param, param_1, param_2, param_3, param_4);\n    vec2 param_5 = tile.xy;\n    float param_6 = tile.z;\n    vec3 param_7 = d;\n    float param_8 = rough;\n    return fa_probe_radiance(param_5, param_6, param_7, param_8);\n}\n\nvec3 fa_environment(vec3 d, float rough)\n{\n    float _3742 = (1.0 - fa_mesh_fs_params[42].w) - fa_mesh_fs_params[47].w;\n    vec3 outc = vec3(0.0);\n    if (_3742 > 0.0005000000237487256526947021484375)\n    {\n        vec3 base;\n        if (fa_mesh_fs_params[11].w > 0.5)\n        {\n            vec2 param = fa_mesh_fs_params[41].zw;\n            float param_1 = 128.0;\n            vec3 param_2 = d;\n            float param_3 = rough;\n            base = fa_probe_radiance(param, param_1, param_2, param_3);\n        }\n        else\n        {\n            float _3772 = rough * rough;\n            float _3803 = 0.60000002384185791015625 * _3772;\n            base = mix(mix(fa_mesh_fs_params[12].xyz * 0.550000011920928955078125, mix(fa_mesh_fs_params[12].xyz, fa_mesh_fs_params[11].xyz, vec3(pow(clamp(d.y * (1.0 - (0.699999988079071044921875 * _3772)), 0.0, 1.0), 0.550000011920928955078125))), vec3(smoothstep((-0.0500000007450580596923828125) - _3803, 0.0500000007450580596923828125 + _3803, d.y))), ((fa_mesh_fs_params[11].xyz + fa_mesh_fs_params[12].xyz) * 0.5) * 0.800000011920928955078125, vec3(_3772 * 0.60000002384185791015625));\n        }\n        outc = base * _3742;\n    }\n    if (fa_mesh_fs_params[42].w > 0.0)\n    {\n        vec4 param_4 = fa_mesh_fs_params[42];\n        vec4 param_5 = fa_mesh_fs_params[43];\n        vec4 param_6 = fa_mesh_fs_params[44];\n        vec4 param_7 = fa_mesh_fs_params[45];\n        vec4 param_8 = fa_mesh_fs_params[46];\n        vec3 param_9 = d;\n        float param_10 = rough;\n        vec3 _3862 = fa_probe_environment(param_4, param_5, param_6, param_7, param_8, param_9, param_10);\n        outc += (_3862 * fa_mesh_fs_params[42].w);\n    }\n    if (fa_mesh_fs_params[47].w > 0.0)\n    {\n        vec4 param_11 = fa_mesh_fs_params[47];\n        vec4 param_12 = fa_mesh_fs_params[48];\n        vec4 param_13 = fa_mesh_fs_params[49];\n        vec4 param_14 = fa_mesh_fs_params[50];\n        vec4 param_15 = fa_mesh_fs_params[51];\n        vec3 param_16 = d;\n        float param_17 = rough;\n        vec3 _3894 = fa_probe_environment(param_11, param_12, param_13, param_14, param_15, param_16, param_17);\n        outc += (_3894 * fa_mesh_fs_params[47].w);\n    }\n    return outc;\n}\n\nvec3 fa_layers_ibl(FaLayers L, vec3 n, vec3 v, vec3 f0, float roughness, float occlusion)\n{\n    vec3 rn = n;\n    if (L.aniso != 0.0)\n    {\n        vec3 _4396;\n        if (L.aniso >= 0.0)\n        {\n            _4396 = L.b;\n        }\n        else\n        {\n            _4396 = L.t;\n        }\n        rn = normalize(mix(n, cross(cross(_4396, v), _4396), vec3(abs(L.aniso) * smoothstep(0.0, 0.25, roughness))));\n    }\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05);\n    vec2 _4432 = fa_env_brdf(param, param_1);\n    vec3 param_2 = reflect(-v, rn);\n    float param_3 = roughness;\n    vec3 result = (fa_environment(param_2, param_3) * ((f0 * _4432.x) + (vec3(L.f90) * _4432.y))) * L.base_scale;\n    if (L.sheen_on)\n    {\n        vec3 param_4 = n;\n        float param_5 = L.sheen_rough;\n        result += ((L.sheen * (L.sheen_e * L.keep)) * fa_environment(param_4, param_5));\n    }\n    result *= occlusion;\n    if (L.coat > 0.0)\n    {\n        float param_6 = L.coat_rough;\n        float param_7 = L.coat_ndv;\n        vec2 _4490 = fa_env_brdf(param_6, param_7);\n        vec3 param_8 = reflect(-v, L.nc);\n        float param_9 = L.coat_rough;\n        result += (fa_environment(param_8, param_9) * (L.coat * ((0.039999999105930328369140625 * _4490.x) + _4490.y)));\n    }\n    return result;\n}\n\nvec3 fa_sky_reflection(vec3 n, vec3 v, vec3 f0, float roughness)\n{\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05);\n    vec2 _3959 = fa_env_brdf(param, param_1);\n    vec3 param_2 = reflect(-v, n);\n    float param_3 = roughness;\n    return fa_environment(param_2, param_3) * ((f0 * _3959.x) + vec3(_3959.y));\n}\n\nvec3 fa_sky_light(SurfaceInput i, Surface s)\n{\n    float _4529 = clamp(s.metallic, 0.0, 1.0);\n    float _4533 = clamp(s.roughness, 0.0500000007450580596923828125, 1.0);\n    vec3 _4540 = mix(vec3(0.039999999105930328369140625), s.albedo, vec3(_4529));\n    vec3 f0 = _4540;\n    vec3 _4544 = normalize(s.normal);\n    SurfaceInput param = i;\n    Surface param_1 = s;\n    vec3 param_2 = _4544;\n    vec3 param_3 = i.view_dir;\n    float param_4 = _4529;\n    float param_5 = _4533;\n    vec3 param_6 = _4540;\n    FaLayers _4561 = fa_layers_setup(param, param_1, param_2, param_3, param_4, param_5, param_6);\n    f0 = param_6;\n    if (_4561.on)\n    {\n        FaLayers param_7 = _4561;\n        vec3 param_8 = _4544;\n        vec3 param_9 = i.view_dir;\n        vec3 param_10 = f0;\n        float param_11 = _4533;\n        float param_12 = s.occlusion;\n        return fa_layers_ibl(param_7, param_8, param_9, param_10, param_11, param_12);\n    }\n    vec3 param_13 = _4544;\n    vec3 param_14 = i.view_dir;\n    vec3 param_15 = f0;\n    float param_16 = _4533;\n    return fa_sky_reflection(param_13, param_14, param_15, param_16) * s.occlusion;\n}\n\nvec3 lighting(SurfaceInput i, Surface s)\n{\n    int best = -1;\n    float bestPower = 0.0;\n    for (int n = 0; n < fa_light_count(); n++)\n    {\n        int param = n;\n        SurfaceInput param_1 = i;\n        LightSample _5151 = fa_light_unshadowed(param, param_1);\n        float _5159 = dot(_5151.color, vec3(0.2989999949932098388671875, 0.58700001239776611328125, 0.114000000059604644775390625));\n        if (_5159 > bestPower)\n        {\n            bestPower = _5159;\n            best = n;\n        }\n    }\n    vec3 lit = (fa_mesh_fs_params[1].xyz * s.albedo) * s.occlusion;\n    if (best >= 0)\n    {\n        int param_2 = best;\n        SurfaceInput param_3 = i;\n        LightSample _5188 = fa_light(param_2, param_3);\n        float _5196;\n        if (dot(s.normal, _5188.direction) > 0.5)\n        {\n            _5196 = 1.0;\n        }\n        else\n        {\n            _5196 = fa_material[0].x;\n        }\n        lit += ((s.albedo * _5188.color) * _5196);\n    }\n    SurfaceInput param_4 = i;\n    Surface param_5 = s;\n    return lit + (fa_sky_light(param_4, param_5) * fa_material[1].x);\n}\n\nvec3 fa_shadow_debug(vec3 color, vec3 world)\n{\n    if (fa_shadows[27].w < 0.5)\n    {\n        return color;\n    }\n    int _3080 = int(fa_shadows[25].x + 0.5);\n    float _3090 = dot(world - fa_shadows[27].xyz, fa_shadows[28].xyz);\n    vec3 tint = vec3(0.3499999940395355224609375);\n    bool _3095 = _3080 > 0;\n    bool _3104;\n    if (_3095)\n    {\n        int param = _3080 - 1;\n        _3104 = _3090 <= fa_shadow_split_at(param);\n    }\n    else\n    {\n        _3104 = _3095;\n    }\n    if (_3104)\n    {\n        tint = vec3(1.0, 0.1500000059604644775390625, 0.100000001490116119384765625);\n        bool _3110 = _3080 > 1;\n        bool _3117;\n        if (_3110)\n        {\n            _3117 = _3090 > fa_shadows[24].x;\n        }\n        else\n        {\n            _3117 = _3110;\n        }\n        if (_3117)\n        {\n            tint = vec3(0.100000001490116119384765625, 0.89999997615814208984375, 0.20000000298023223876953125);\n        }\n        bool _3123 = _3080 > 2;\n        bool _3130;\n        if (_3123)\n        {\n            _3130 = _3090 > fa_shadows[24].y;\n        }\n        else\n        {\n            _3130 = _3123;\n        }\n        if (_3130)\n        {\n            tint = vec3(0.1500000059604644775390625, 0.300000011920928955078125, 1.0);\n        }\n        bool _3136 = _3080 > 3;\n        bool _3143;\n        if (_3136)\n        {\n            _3143 = _3090 > fa_shadows[24].z;\n        }\n        else\n        {\n            _3143 = _3136;\n        }\n        if (_3143)\n        {\n            tint = vec3(1.0, 0.89999997615814208984375, 0.100000001490116119384765625);\n        }\n    }\n    return mix(color, tint, vec3(0.550000011920928955078125));\n}\n\nvoid main()\n{\n    fa_inst_load();\n    vec3 _5928 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _5928 = -_5928;\n    }\n    vec3 _5598 = normalize(fa_mesh_fs_params[0].xyz - fa_world_pos);\n    vec3 param = fa_world_pos;\n    fa_cluster_begin(param);\n    SurfaceInput param_1 = SurfaceInput(fa_world_pos, _5928, fa_world_tangent, fa_uv, fa_vertex_color, _5598, gl_FrontFacing);\n    Surface _5606 = fa_standard_surface(param_1);\n    vec3 _5959 = _5606.albedo;\n    float _5960 = _5606.alpha;\n    vec3 _5961 = _5606.normal;\n    float _5962 = _5606.metallic;\n    float _5963 = _5606.roughness;\n    float _5964 = _5606.occlusion;\n    vec3 _5965 = _5606.emission;\n    float _5966 = _5606.clearcoat;\n    float _5967 = _5606.clearcoat_roughness;\n    vec3 _5968 = _5606.sheen_color;\n    float _5969 = _5606.sheen_roughness;\n    float _5970 = _5606.anisotropy;\n    float _5971 = _5606.anisotropy_rotation;\n    float _5972 = _5606.specular;\n    float _5973 = _5606.ior;\n    vec3 _5974 = _5606.specular_color;\n    float _5975 = _5606.transmission;\n    float _5976 = _5606.thickness;\n    vec3 _5977 = _5606.attenuation_color;\n    float _5978 = _5606.attenuation_distance;\n    SurfaceInput param_2 = SurfaceInput(fa_world_pos, _5928, fa_world_tangent, fa_uv, fa_vertex_color, _5598, gl_FrontFacing);\n    Surface param_3 = _5606;\n    surface(param_2, param_3);\n    _5959 = param_3.albedo;\n    _5960 = param_3.alpha;\n    _5961 = param_3.normal;\n    _5962 = param_3.metallic;\n    _5963 = param_3.roughness;\n    _5964 = param_3.occlusion;\n    _5965 = param_3.emission;\n    _5966 = param_3.clearcoat;\n    _5967 = param_3.clearcoat_roughness;\n    _5968 = param_3.sheen_color;\n    _5969 = param_3.sheen_roughness;\n    _5970 = param_3.anisotropy;\n    _5971 = param_3.anisotropy_rotation;\n    _5972 = param_3.specular;\n    _5973 = param_3.ior;\n    _5974 = param_3.specular_color;\n    _5975 = param_3.transmission;\n    _5976 = param_3.thickness;\n    _5977 = param_3.attenuation_color;\n    _5978 = param_3.attenuation_distance;\n    vec3 param_4 = fa_world_pos;\n    vec3 param_5 = _5928;\n    vec3 param_6 = param_3.albedo;\n    vec3 param_7 = param_3.normal;\n    fa_apply_decals(param_4, param_5, param_6, param_7);\n    _5959 = param_6;\n    _5961 = param_7;\n    vec3 result;\n    if (fa_mesh_fs_params[3].w > 0.5)\n    {\n        result = _5959;\n    }\n    else\n    {\n        vec3 _5645 = _5961;\n        vec3 _5646 = normalize(_5645);\n        _5961 = _5646;\n        SurfaceInput param_8 = SurfaceInput(fa_world_pos, _5928, fa_world_tangent, fa_uv, fa_vertex_color, _5598, gl_FrontFacing);\n        Surface param_9 = Surface(_5959, _5960, _5646, _5962, _5963, _5964, _5965, _5966, _5967, _5968, _5969, _5970, _5971, _5972, _5973, _5974, _5975, _5976, _5977, _5978);\n        vec3 _5657 = lighting(param_8, param_9);\n        result = _5657;\n    }\n    vec3 _5661 = result;\n    vec3 _5662 = _5661 + _5965;\n    result = _5662;\n    vec3 param_10 = _5662;\n    vec3 param_11 = fa_world_pos;\n    result = fa_shadow_debug(param_10, param_11);\n    bool _5671 = fa_mesh_fs_params[7].w > 0.0;\n    bool _5678;\n    if (!_5671)\n    {\n        _5678 = fa_mesh_fs_params[8].y > 0.0;\n    }\n    else\n    {\n        _5678 = _5671;\n    }\n    if (_5678)\n    {\n        vec3 _5687 = fa_world_pos - fa_mesh_fs_params[0].xyz;\n        float _5693 = dot(_5687, fa_mesh_fs_params[9].xyz);\n        bool _5697 = fa_mesh_fs_params[9].w > 0.5;\n        float _5698;\n        if (_5697)\n        {\n            _5698 = _5693;\n        }\n        else\n        {\n            _5698 = length(_5687);\n        }\n        float _5710 = _5698 - fa_mesh_fs_params[8].x;\n        if (_5710 > 0.0)\n        {\n            float _5719 = fa_mesh_fs_params[7].w * _5710;\n            float tau = _5719 * _5719;\n            if (fa_mesh_fs_params[8].y > 0.0)\n            {\n                float _5735;\n                if (_5697)\n                {\n                    _5735 = fa_world_pos.y - (fa_mesh_fs_params[9].y * _5693);\n                }\n                else\n                {\n                    _5735 = fa_mesh_fs_params[0].y;\n                }\n                float _5756 = mix(_5735, fa_world_pos.y, clamp(fa_mesh_fs_params[8].x / _5698, 0.0, 1.0));\n                float _5760 = fa_world_pos.y - _5756;\n                float _5765 = _5756 - fa_mesh_fs_params[8].z;\n                float _5770 = fa_world_pos.y - fa_mesh_fs_params[8].z;\n                bool _5773 = _5765 <= 0.0;\n                bool _5774 = !_5773;\n                bool _5780;\n                if (_5774)\n                {\n                    _5780 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _5780 = _5773;\n                }\n                float _5781;\n                if (_5780)\n                {\n                    _5781 = fa_mesh_fs_params[8].y;\n                }\n                else\n                {\n                    _5781 = fa_mesh_fs_params[8].y * exp(-min(fa_mesh_fs_params[8].w * _5765, 80.0));\n                }\n                bool _5808;\n                if (_5774)\n                {\n                    _5808 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _5808 = _5773;\n                }\n                float _5809;\n                if (_5808)\n                {\n                    _5809 = fa_mesh_fs_params[8].y * _5765;\n                }\n                else\n                {\n                    _5809 = (fa_mesh_fs_params[8].y * (1.0 - exp(-min(fa_mesh_fs_params[8].w * _5765, 80.0)))) / fa_mesh_fs_params[8].w;\n                }\n                bool _5834 = _5770 <= 0.0;\n                bool _5841;\n                if (!_5834)\n                {\n                    _5841 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _5841 = _5834;\n                }\n                float _5842;\n                if (_5841)\n                {\n                    _5842 = fa_mesh_fs_params[8].y * _5770;\n                }\n                else\n                {\n                    _5842 = (fa_mesh_fs_params[8].y * (1.0 - exp(-min(fa_mesh_fs_params[8].w * _5770, 80.0)))) / fa_mesh_fs_params[8].w;\n                }\n                float _5869;\n                if (abs(_5760) < 0.001000000047497451305389404296875)\n                {\n                    _5869 = _5781;\n                }\n                else\n                {\n                    _5869 = (_5842 - _5809) / _5760;\n                }\n                tau += (_5710 * max(_5869, 0.0));\n            }\n            result = mix(result, fa_mesh_fs_params[7].xyz, vec3(clamp(1.0 - exp(-clamp(tau, 0.0, 80.0)), 0.0, 1.0)));\n        }\n    }\n    fa_frag_color = vec4(result, _5960);\n}\n\n",
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
            "inst_name": "_131",
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
            "inst_name": "_468",
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
            "inst_name": "_2121",
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
            "size": 32,
            "struct_name": "fa_material",
            "inst_name": "_5202",
            "glsl_uniforms": [
              {
                "type": "vec4",
                "array_count": 2,
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
            "name": "fa_light_atlas_fa_env_smp",
            "view_name": "fa_light_atlas",
            "sampler_name": "fa_env_smp",
            "view_slot": 25,
            "sampler_slot": 10,
            "glsl_name": "fa_light_atlas_fa_env_smp"
          },
          {
            "slot": 8,
            "stage": "fragment",
            "name": "fa_shadow_tex_fa_shadow_smp",
            "view_name": "fa_shadow_tex",
            "sampler_name": "fa_shadow_smp",
            "view_slot": 1,
            "sampler_slot": 1,
            "glsl_name": "fa_shadow_tex_fa_shadow_smp"
          },
          {
            "slot": 9,
            "stage": "fragment",
            "name": "fa_screen_tex_fa_shadow_smp",
            "view_name": "fa_screen_tex",
            "sampler_name": "fa_shadow_smp",
            "view_slot": 28,
            "sampler_slot": 1,
            "glsl_name": "fa_screen_tex_fa_shadow_smp"
          },
          {
            "slot": 10,
            "stage": "fragment",
            "name": "fa_probe_atlas_fa_env_smp",
            "view_name": "fa_probe_atlas",
            "sampler_name": "fa_env_smp",
            "view_slot": 14,
            "sampler_slot": 10,
            "glsl_name": "fa_probe_atlas_fa_env_smp"
          }
        ]
      }
    },
    "mesh_skin": {
      "vs": "#version 430\n\nstruct VertexData\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 color;\n    vec3 object_pos;\n};\n\nuniform vec4 fa_mesh_vs_params[11];\nuniform vec4 fa_skin[192];\nlayout(location = 0) out vec3 fa_world_pos;\nlayout(location = 1) out vec3 fa_world_normal;\nlayout(location = 2) out vec4 fa_world_tangent;\nlayout(location = 3) out vec2 fa_uv;\nlayout(location = 4) out vec4 fa_vertex_color;\nlayout(location = 5) in vec4 fa_inst_m0;\nlayout(location = 6) in vec4 fa_inst_m1;\nlayout(location = 7) in vec4 fa_inst_m2;\nlayout(location = 8) in vec4 fa_inst_m3;\nlayout(location = 9) in vec4 fa_joints;\nlayout(location = 10) in vec4 fa_weights;\nlayout(location = 0) in vec3 fa_position;\nlayout(location = 1) in vec3 fa_normal;\nlayout(location = 3) in vec4 fa_tangent;\nlayout(location = 2) in vec2 fa_texcoord0;\nlayout(location = 4) in vec4 fa_color;\nlayout(location = 5) out vec3 fa_lm;\n\nvoid fa_inst_begin()\n{\n}\n\nmat4 fa_skin_matrix(vec4 joints, vec4 weights)\n{\n    vec4 r0 = vec4(0.0);\n    vec4 r1 = vec4(0.0);\n    vec4 r2 = vec4(0.0);\n    for (int i = 0; i < 4; i++)\n    {\n        int _174 = int((joints[i] * 255.0) + 0.5) * 3;\n        r0 += (fa_skin[_174 * 1 + 0] * weights[i]);\n        r1 += (fa_skin[(_174 + 1) * 1 + 0] * weights[i]);\n        r2 += (fa_skin[(_174 + 2) * 1 + 0] * weights[i]);\n    }\n    return mat4(vec4(r0.x, r1.x, r2.x, 0.0), vec4(r0.y, r1.y, r2.y, 0.0), vec4(r0.z, r1.z, r2.z, 0.0), vec4(r0.w, r1.w, r2.w, 1.0));\n}\n\nVertexData fa_vertex_data(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    vec3 _74 = cross(model[1].xyz, model[2].xyz);\n    float _80 = (dot(model[0].xyz, _74) < 0.0) ? (-1.0) : 1.0;\n    return VertexData((model * vec4(position, 1.0)).xyz, (((_74 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _80, vec4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _80), texcoord0 * fa_mesh_vs_params[8].xy, color, position);\n}\n\nvoid fa_shade_vertex(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    mat4 param = model;\n    vec3 param_1 = position;\n    vec3 param_2 = normal;\n    vec4 param_3 = tangent;\n    vec2 param_4 = texcoord0;\n    vec4 param_5 = color;\n    VertexData _273 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    vec3 _391 = _273.world_pos;\n    fa_world_pos = _391;\n    fa_world_normal = _273.world_normal;\n    fa_world_tangent = _273.world_tangent;\n    fa_uv = _273.uv;\n    fa_vertex_color = _273.color;\n    gl_Position = mat4(fa_mesh_vs_params[0], fa_mesh_vs_params[1], fa_mesh_vs_params[2], fa_mesh_vs_params[3]) * vec4(_391, 1.0);\n}\n\nvoid main()\n{\n    fa_inst_begin();\n    vec4 param = fa_joints;\n    vec4 param_1 = fa_weights;\n    mat4 param_2 = mat4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3) * fa_skin_matrix(param, param_1);\n    vec3 param_3 = fa_position;\n    vec3 param_4 = fa_normal;\n    vec4 param_5 = fa_tangent;\n    vec2 param_6 = fa_texcoord0;\n    vec4 param_7 = fa_color;\n    fa_shade_vertex(param_2, param_3, param_4, param_5, param_6, param_7);\n    fa_lm = vec3(0.0);\n}\n\n",
      "fs": "#version 430\n\nstruct SurfaceInput\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 vertex_color;\n    vec3 view_dir;\n    bool front_facing;\n};\n\nstruct LightSample\n{\n    vec3 direction;\n    vec3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct Surface\n{\n    vec3 albedo;\n    float alpha;\n    vec3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    vec3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    vec3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    vec3 specular_color;\n    float transmission;\n    float thickness;\n    vec3 attenuation_color;\n    float attenuation_distance;\n};\n\nstruct FaLayers\n{\n    bool on;\n    float f90;\n    float keep;\n    float base_scale;\n    float coat;\n    float coat_rough;\n    float coat_alpha;\n    float coat_a2;\n    vec3 nc;\n    float coat_ndv;\n    bool sheen_on;\n    vec3 sheen;\n    float sheen_rough;\n    float sheen_alpha;\n    float sheen_scale;\n    float sheen_e;\n    float aniso;\n    vec3 t;\n    vec3 b;\n    float at;\n    float ab;\n};\n\nconst float _4060[63] = float[](1.0, 1.0, 1.0, 0.4790000021457672119140625, 0.11699999868869781494140625, 0.01200000010430812835693359375, 0.0, 0.0, 0.0, 1.0, 1.0, 1.0, 0.578000009059906005859375, 0.19300000369548797607421875, 0.0350000001490116119384765625, 0.0030000000260770320892333984375, 0.0, 0.0, 1.0, 1.0, 1.0, 0.6740000247955322265625, 0.3459999859333038330078125, 0.1319999992847442626953125, 0.032999999821186065673828125, 0.0040000001899898052215576171875, 0.0, 0.971000015735626220703125, 0.954999983310699462890625, 0.828999996185302734375, 0.63999998569488525390625, 0.42599999904632568359375, 0.24500000476837158203125, 0.115000002086162567138671875, 0.037000000476837158203125, 0.0030000000260770320892333984375, 0.7469999790191650390625, 0.737999975681304931640625, 0.670000016689300537109375, 0.563000023365020751953125, 0.4309999942779541015625, 0.3039999902248382568359375, 0.1940000057220458984375, 0.1019999980926513671875, 0.0309999994933605194091796875, 0.614000022411346435546875, 0.609000027179718017578125, 0.566999971866607666015625, 0.499000012874603271484375, 0.412000000476837158203125, 0.32400000095367431640625, 0.240999996662139892578125, 0.162000000476837158203125, 0.087999999523162841796875, 0.538999974727630615234375, 0.535000026226043701171875, 0.505999982357025146484375, 0.4569999873638153076171875, 0.393999993801116943359375, 0.328999996185302734375, 0.2660000026226043701171875, 0.203999996185302734375, 0.14200000464916229248046875);\n\nuniform vec4 fa_mesh_fs_params[53];\nuniform vec4 fa_shadows[30];\nuniform vec4 fa_material[2];\nlayout(binding = 0) uniform sampler2D fa_light_tex_fa_shadow_smp;\nlayout(binding = 1) uniform sampler2D fa_tex_fa_smp;\nlayout(binding = 2) uniform sampler2D fa_normal_tex_fa_smp;\nlayout(binding = 3) uniform sampler2D fa_mr_tex_fa_smp;\nlayout(binding = 4) uniform sampler2D fa_occlusion_tex_fa_smp;\nlayout(binding = 5) uniform sampler2D fa_emissive_tex_fa_smp;\nlayout(binding = 6) uniform sampler2D fa_decal_tex_fa_env_smp;\nlayout(binding = 7) uniform sampler2D fa_light_atlas_fa_env_smp;\nlayout(binding = 8) uniform sampler2D fa_shadow_tex_fa_shadow_smp;\nlayout(binding = 9) uniform sampler2D fa_screen_tex_fa_shadow_smp;\nlayout(binding = 10) uniform sampler2D fa_probe_atlas_fa_env_smp;\n\nlayout(location = 0) in vec3 fa_world_pos;\nlayout(location = 5) in vec3 fa_lm;\nlayout(location = 1) in vec3 fa_world_normal;\nlayout(location = 2) in vec4 fa_world_tangent;\nlayout(location = 3) in vec2 fa_uv;\nlayout(location = 4) in vec4 fa_vertex_color;\nlayout(location = 0) out vec4 fa_frag_color;\nvec3 fa_light_tint;\nbool fa_light_is_area;\nint fa_cl_ndir;\nint fa_cl_slot;\nint fa_cl_local;\n\nvoid fa_inst_load()\n{\n}\n\nvec4 fa_light_texel(int t)\n{\n    return texelFetch(fa_light_tex_fa_shadow_smp, ivec2(t & 1023, t >> 10), 0);\n}\n\nvec4 fa_cluster_texel(vec3 world_pos)\n{\n    bool _1397 = fa_mesh_fs_params[19].x < 0.0;\n    bool _1404;\n    if (!_1397)\n    {\n        _1404 = fa_mesh_fs_params[19].w < 1.0;\n    }\n    else\n    {\n        _1404 = _1397;\n    }\n    bool _1412;\n    if (!_1404)\n    {\n        _1412 = fa_mesh_fs_params[18].x < 1.0;\n    }\n    else\n    {\n        _1412 = _1404;\n    }\n    bool _1419;\n    if (!_1412)\n    {\n        _1419 = fa_mesh_fs_params[18].y < 1.0;\n    }\n    else\n    {\n        _1419 = _1412;\n    }\n    bool _1426;\n    if (!_1419)\n    {\n        _1426 = fa_mesh_fs_params[19].y < 1.0;\n    }\n    else\n    {\n        _1426 = _1419;\n    }\n    if (_1426)\n    {\n        return vec4(0.0);\n    }\n    vec4 _1436 = vec4(world_pos, 1.0);\n    float _1442 = dot(fa_mesh_fs_params[16], _1436);\n    if (!(_1442 > 9.9999999747524270787835121154785e-07))\n    {\n        return vec4(0.0);\n    }\n    vec2 _1464 = vec2(dot(fa_mesh_fs_params[14], _1436), dot(fa_mesh_fs_params[15], _1436)) / vec2(_1442);\n    int _1468 = int(fa_mesh_fs_params[18].x);\n    int _1472 = int(fa_mesh_fs_params[18].y);\n    int param = (int(fa_mesh_fs_params[19].x) + (((clamp(int(floor(log2(max(dot(fa_mesh_fs_params[17].xyz, world_pos) + fa_mesh_fs_params[17].w, fa_mesh_fs_params[18].w) / fa_mesh_fs_params[18].w) * fa_mesh_fs_params[18].z)), 0, int(fa_mesh_fs_params[19].y) - 1) * _1472) + clamp(int(floor(((_1464.y * 0.5) + 0.5) * fa_mesh_fs_params[18].y)), 0, _1472 - 1)) * _1468)) + clamp(int(floor(((_1464.x * 0.5) + 0.5) * fa_mesh_fs_params[18].x)), 0, _1468 - 1);\n    return fa_light_texel(param);\n}\n\nivec2 fa_cluster_lookup(vec3 world_pos)\n{\n    vec3 param = world_pos;\n    vec4 _1548 = fa_cluster_texel(param);\n    return ivec2(int(_1548.x), int(_1548.y));\n}\n\nvoid fa_cluster_begin(vec3 world_pos)\n{\n    fa_cl_ndir = int(fa_mesh_fs_params[19].z);\n    vec3 param = world_pos;\n    ivec2 _4886 = fa_cluster_lookup(param);\n    fa_cl_slot = _4886.x;\n    fa_cl_local = _4886.y;\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_linear_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvec3 fa_tex_fix(inout vec3 c, float mode)\n{\n    if (mode > 1.5)\n    {\n        vec3 param = c;\n        vec3 _5263 = fa_linear_to_srgb(param);\n        c = _5263;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            vec3 param_1 = c;\n            vec3 _5271 = fa_srgb_to_linear(param_1);\n            c = _5271;\n        }\n    }\n    return c;\n}\n\nvec3 fa_tangent_normal(SurfaceInput i, vec3 m)\n{\n    vec3 _348;\n    if (i.front_facing)\n    {\n        _348 = i.world_normal;\n    }\n    else\n    {\n        _348 = -i.world_normal;\n    }\n    vec3 _372 = normalize(i.world_tangent.xyz - (_348 * dot(_348, i.world_tangent.xyz)));\n    vec3 _400 = normalize(((_372 * m.x) + ((cross(_348, _372) * i.world_tangent.w) * m.y)) + (_348 * m.z));\n    vec3 _403;\n    if (i.front_facing)\n    {\n        _403 = _400;\n    }\n    else\n    {\n        _403 = -_400;\n    }\n    return _403;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    vec4 base_t = texture(fa_tex_fa_smp, i.uv, fa_mesh_fs_params[12].w);\n    float param = fa_mesh_fs_params[6].w;\n    float param_1 = 1.0;\n    vec3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    vec3 _5303 = fa_tex_fix(param_2, param_3);\n    vec4 _6461 = base_t;\n    _6461.x = _5303.x;\n    _6461.y = _5303.y;\n    _6461.z = _5303.z;\n    base_t = _6461;\n    vec4 _5317 = (_6461 * fa_mesh_fs_params[2]) * i.vertex_color;\n    vec3 _6256 = i.world_normal;\n    if (fa_mesh_fs_params[6].z > 0.5)\n    {\n        float param_4 = fa_mesh_fs_params[6].w;\n        float param_5 = 16.0;\n        vec3 param_6 = texture(fa_normal_tex_fa_smp, i.uv, fa_mesh_fs_params[12].w).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        vec3 _5351 = fa_tex_fix(param_6, param_7);\n        vec3 _5354 = (_5351 * 2.0) - vec3(1.0);\n        vec2 _5359 = _5354.xy * fa_mesh_fs_params[6].x;\n        vec3 _6469 = _5354;\n        _6469.x = _5359.x;\n        _6469.y = _5359.y;\n        SurfaceInput param_8 = i;\n        vec3 param_9 = _6469;\n        _6256 = fa_tangent_normal(param_8, param_9);\n    }\n    vec4 mrt = texture(fa_mr_tex_fa_smp, i.uv, fa_mesh_fs_params[12].w);\n    float param_10 = fa_mesh_fs_params[6].w;\n    float param_11 = 64.0;\n    vec3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    vec3 _5389 = fa_tex_fix(param_12, param_13);\n    vec4 _6472 = mrt;\n    _6472.x = _5389.x;\n    _6472.y = _5389.y;\n    _6472.z = _5389.z;\n    mrt = _6472;\n    vec4 _5419 = texture(fa_occlusion_tex_fa_smp, i.uv, fa_mesh_fs_params[12].w);\n    float param_14 = fa_mesh_fs_params[6].w;\n    float param_15 = 256.0;\n    vec3 param_16 = _5419.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    vec3 _5430 = fa_tex_fix(param_16, param_17);\n    float param_18 = fa_mesh_fs_params[6].w;\n    float param_19 = 4.0;\n    vec3 param_20 = texture(fa_emissive_tex_fa_smp, i.uv, fa_mesh_fs_params[12].w).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    vec3 _5462 = fa_tex_fix(param_20, param_21);\n    float _6261 = fa_mesh_fs_params[20].x;\n    float _6262 = fa_mesh_fs_params[20].y;\n    float _6265 = fa_mesh_fs_params[20].z;\n    float _6264 = fa_mesh_fs_params[21].w;\n    float _6267 = fa_mesh_fs_params[22].x;\n    if (fa_mesh_fs_params[22].z > 0.5)\n    {\n        if (mod(fa_mesh_fs_params[22].z, 2.0) > 0.5)\n        {\n            _6261 *= _5430.y;\n            _6262 *= _5430.z;\n            _6264 *= _5419.w;\n        }\n        if (fa_mesh_fs_params[22].z > 1.5)\n        {\n            _6265 *= mrt.x;\n            _6267 *= mrt.w;\n        }\n    }\n    return Surface(_5317.xyz, _5317.w, _6256, clamp(fa_mesh_fs_params[5].x * _5389.z, 0.0, 1.0), clamp(fa_mesh_fs_params[5].y * _5389.y, 0.0500000007450580596923828125, 1.0), 1.0 + (fa_mesh_fs_params[6].y * (_5430.x - 1.0)), fa_mesh_fs_params[3].xyz + (fa_mesh_fs_params[4].xyz * _5462), _6261, _6262, fa_mesh_fs_params[21].xyz, _6264, _6265, fa_mesh_fs_params[20].w, _6267, fa_mesh_fs_params[22].y, fa_mesh_fs_params[23].xyz, fa_mesh_fs_params[30].x, fa_mesh_fs_params[30].y, fa_mesh_fs_params[31].xyz, fa_mesh_fs_params[30].z);\n}\n\nvoid surface(SurfaceInput i, Surface s)\n{\n}\n\nvec4 fa_decal_tile(vec4 rect, vec2 uv, vec2 atlas, vec2 ddx, vec2 ddy)\n{\n    vec2 _1628 = rect.zw - rect.xy;\n    vec2 _1632 = _1628 * atlas;\n    vec2 _1636 = ddx * _1632;\n    vec2 _1640 = ddy * _1632;\n    return textureLod(fa_decal_tex_fa_env_smp, rect.xy + (clamp(uv, vec2(0.0), vec2(1.0)) * _1628), clamp(0.5 * log2(max(max(dot(_1636, _1636), dot(_1640, _1640)), 9.9999999392252902907785028219223e-09)), 0.0, 3.0));\n}\n\nvec3 fa_dc_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_dc_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvoid fa_apply_decals(vec3 world_pos, vec3 geo_normal, inout vec3 albedo, inout vec3 normal)\n{\n    bool _1673 = fa_mesh_fs_params[10].y < 0.5;\n    bool _1680;\n    if (!_1673)\n    {\n        _1680 = fa_mesh_fs_params[10].w < 0.5;\n    }\n    else\n    {\n        _1680 = _1673;\n    }\n    if (_1680)\n    {\n        return;\n    }\n    vec3 _1686 = dFdx(world_pos);\n    vec3 _1689 = dFdy(world_pos);\n    vec3 param = world_pos;\n    vec4 _1693 = fa_cluster_texel(param);\n    int _1697 = int(_1693.w);\n    if (_1697 < 1)\n    {\n        return;\n    }\n    int _1707 = int(fa_mesh_fs_params[10].y + 0.5);\n    int param_1 = _1707;\n    vec4 _1711 = fa_light_texel(param_1);\n    vec2 _1714 = _1711.yz;\n    int _1718 = int(_1711.w);\n    int param_2 = _1707 + 1;\n    vec4 _1723 = fa_light_texel(param_2);\n    float _1724 = _1723.x;\n    int _1730 = int(fa_mesh_fs_params[10].w + 0.5) - 1;\n    int _1734 = int(_1693.z);\n    vec3 _1999;\n    for (int k = 0; k < _1697; k++)\n    {\n        int _1747 = _1734 + k;\n        int param_3 = _1718 + (_1747 >> 2);\n        int _1764 = (_1707 + 2) + (int(fa_light_texel(param_3)[_1747 & 3]) * 7);\n        int param_4 = _1764 + 6;\n        vec4 _1769 = fa_light_texel(param_4);\n        if (((int(_1769.w + 0.5) >> _1730) & 1) == 0)\n        {\n            continue;\n        }\n        int param_5 = _1764;\n        vec4 _1784 = fa_light_texel(param_5);\n        int param_6 = _1764 + 1;\n        vec4 _1789 = fa_light_texel(param_6);\n        int param_7 = _1764 + 2;\n        vec4 _1794 = fa_light_texel(param_7);\n        vec3 _1797 = _1784.xyz;\n        float _1802 = dot(_1797, world_pos) + _1784.w;\n        vec3 _1804 = _1789.xyz;\n        float _1809 = dot(_1804, world_pos) + _1789.w;\n        vec3 _1811 = _1794.xyz;\n        float _1816 = dot(_1811, world_pos) + _1794.w;\n        bool _1821 = abs(_1802) > 0.5;\n        bool _1829;\n        if (!_1821)\n        {\n            _1829 = abs(_1809) > 0.5;\n        }\n        else\n        {\n            _1829 = _1821;\n        }\n        bool _1837;\n        if (!_1829)\n        {\n            _1837 = abs(_1816) > 0.5;\n        }\n        else\n        {\n            _1837 = _1829;\n        }\n        if (_1837)\n        {\n            continue;\n        }\n        float _1852 = clamp(dot(geo_normal, normalize(_1811)) * _1769.z, 0.0, 1.0);\n        if (_1852 <= 0.0)\n        {\n            continue;\n        }\n        float _1872 = (clamp((0.5 - abs(_1816)) * 10.0, 0.0, 1.0) * _1852) * _1769.x;\n        vec2 _1880 = vec2(_1802 + 0.5, 0.5 - _1809);\n        vec2 _1890 = vec2(dot(_1797, _1686), dot(_1804, _1686));\n        vec2 _1900 = vec2(dot(_1797, _1689), dot(_1804, _1689));\n        int param_8 = _1764 + 5;\n        vec4 _1905 = fa_light_texel(param_8);\n        int param_9 = _1764 + 3;\n        vec4 _1910 = fa_light_texel(param_9);\n        int param_10 = _1764 + 4;\n        vec4 _1915 = fa_light_texel(param_10);\n        float tex_a = 1.0;\n        vec3 col = _1905.xyz;\n        bool _1925 = _1910.z > _1910.x;\n        if (_1925)\n        {\n            vec4 param_11 = _1910;\n            vec2 param_12 = _1880;\n            vec2 param_13 = _1714;\n            vec2 param_14 = _1890;\n            vec2 param_15 = _1900;\n            vec4 tx = fa_decal_tile(param_11, param_12, param_13, param_14, param_15);\n            if ((_1724 > 0.5) && (_1724 < 1.5))\n            {\n                vec3 param_16 = tx.xyz;\n                vec3 _1951 = fa_dc_to_linear(param_16);\n                vec4 _6344 = tx;\n                _6344.x = _1951.x;\n                _6344.y = _1951.y;\n                _6344.z = _1951.z;\n                tx = _6344;\n            }\n            col *= tx.xyz;\n            tex_a = tx.w;\n        }\n        albedo = mix(albedo, col, vec3(clamp((_1872 * tex_a) * _1905.w, 0.0, 1.0)));\n        if (_1915.z > _1915.x)\n        {\n            vec4 param_17 = _1915;\n            vec2 param_18 = _1880;\n            vec2 param_19 = _1714;\n            vec2 param_20 = _1890;\n            vec2 param_21 = _1900;\n            vec4 _1995 = fa_decal_tile(param_17, param_18, param_19, param_20, param_21);\n            if (_1724 > 1.5)\n            {\n                vec3 param_22 = _1995.xyz;\n                vec3 _2005 = fa_dc_to_srgb(param_22);\n                _1999 = _2005;\n            }\n            else\n            {\n                _1999 = _1995.xyz;\n            }\n            vec3 _2014 = (_1999 * 2.0) - vec3(1.0);\n            vec2 _2019 = _2014.xy * _1769.y;\n            vec3 _2041 = (normalize(_1797) * _2019.x) + (normalize(_1804) * _2019.y);\n            vec3 _2044 = normalize(normal);\n            normal = normalize(mix(_2044, normalize((_2044 * max(_2014.z, 0.0500000007450580596923828125)) + (_2041 - (_2044 * dot(_2044, _2041)))), vec3(clamp(_1872 * (_1925 ? tex_a : 1.0), 0.0, 1.0))));\n        }\n    }\n}\n\nint fa_light_count()\n{\n    return fa_cl_ndir + fa_cl_local;\n}\n\nLightSample fa_no_light()\n{\n    return LightSample(vec3(0.0, 1.0, 0.0), vec3(0.0), 0.0, 1.0, 0.0, 0);\n}\n\nint fa_cluster_index(int slot, int n)\n{\n    int param = (int(fa_mesh_fs_params[19].x) + int(fa_mesh_fs_params[19].w)) + ((slot + n) >> 2);\n    vec4 t = fa_light_texel(param);\n    return int(t[(slot + n) & 3]);\n}\n\nint fa_cl_light(int n)\n{\n    if (n < fa_cl_ndir)\n    {\n        return n;\n    }\n    int param = fa_cl_slot;\n    int param_1 = n - fa_cl_ndir;\n    return fa_cluster_index(param, param_1);\n}\n\nint fa_light_base(int li)\n{\n    return li * ((fa_mesh_fs_params[1].w > 4.5) ? 8 : 4);\n}\n\nbool fa_light_baked(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 3;\n    return fa_light_texel(param_1).w > 0.5;\n}\n\nfloat fa_baked_keep(int li)\n{\n    float _4856;\n    if (fa_lm.z > 0.5)\n    {\n        _4856 = 0.0;\n    }\n    else\n    {\n        _4856 = 1.0 - clamp(fa_mesh_fs_params[32].w, 0.0, 1.0);\n    }\n    bool _4867 = _4856 < 1.0;\n    bool _4873;\n    if (_4867)\n    {\n        int param = li;\n        _4873 = fa_light_baked(param);\n    }\n    else\n    {\n        _4873 = _4867;\n    }\n    return _4873 ? _4856 : 1.0;\n}\n\nvec3 fa_area_point(vec3 c, vec3 axis, vec3 ru, vec3 uu, float hx, float hy, float shape, vec3 p, vec3 r)\n{\n    bool _646 = dot(r, r) > 0.5;\n    if (shape > 1.5)\n    {\n        vec3 _659 = (c - (ru * hx)) - p;\n        vec3 _665 = ru * (2.0 * hx);\n        float _671 = max(dot(_665, _665), 9.9999999392252902907785028219223e-09);\n        float _675 = dot(_659, _665);\n        float t = clamp((-_675) / _671, 0.0, 1.0);\n        if (_646)\n        {\n            float _690 = dot(r, _665);\n            float _696 = _671 - (_690 * _690);\n            if (abs(_696) > (9.9999997473787516355514526367188e-06 * _671))\n            {\n                t = clamp(((dot(r, _659) * _690) - _675) / _696, 0.0, 1.0);\n            }\n        }\n        return (p + _659) + (_665 * t);\n    }\n    vec3 q = p;\n    float _728 = dot(r, axis);\n    bool _736;\n    if (_646)\n    {\n        _736 = abs(_728) > 9.9999997473787516355514526367188e-05;\n    }\n    else\n    {\n        _736 = _646;\n    }\n    if (_736)\n    {\n        float _746 = dot(c - p, axis) / _728;\n        if (_746 > 0.0)\n        {\n            q = p + (r * _746);\n        }\n    }\n    vec3 _759 = q - c;\n    vec2 xy = vec2(dot(_759, ru), dot(_759, uu));\n    if (shape > 0.5)\n    {\n        float _774 = length(xy);\n        if (_774 > hx)\n        {\n            xy *= (hx / _774);\n        }\n    }\n    else\n    {\n        xy = clamp(xy, vec2(-hx, -hy), vec2(hx, hy));\n    }\n    return (c + (ru * xy.x)) + (uu * xy.y);\n}\n\nvec4 fa_atlas_fetch(vec2 texel)\n{\n    return textureLod(fa_light_atlas_fa_env_smp, texel / vec2(textureSize(fa_light_atlas_fa_env_smp, 0)), 0.0);\n}\n\nvec3 fa_cookie_sample(vec2 tile_origin, vec2 uv)\n{\n    vec2 param = (tile_origin + vec2(1.0)) + (clamp(uv, vec2(0.0), vec2(1.0)) * 254.0);\n    return fa_atlas_fetch(param).xyz;\n}\n\nfloat fa_ies_sample(vec2 tile_origin, vec3 d, vec3 axis, vec3 right, vec3 up)\n{\n    float _566 = dot(d, right);\n    float _570 = dot(d, up);\n    float _581;\n    if (((_566 * _566) + (_570 * _570)) > 1.0000000133514319600180897396058e-10)\n    {\n        _581 = atan(_570, _566) * 0.15915493667125701904296875;\n    }\n    else\n    {\n        _581 = 0.0;\n    }\n    vec2 param = tile_origin + vec2(1.0 + ((_581 - floor(_581)) * 64.0), 1.0 + (acos(clamp(dot(d, axis), -1.0, 1.0)) * 10.18591594696044921875));\n    return fa_atlas_fetch(param).x;\n}\n\nint fa_cube_face(vec3 d)\n{\n    vec3 _415 = abs(d);\n    float _417 = _415.x;\n    float _419 = _415.y;\n    bool _420 = _417 >= _419;\n    bool _428;\n    if (_420)\n    {\n        _428 = _417 >= _415.z;\n    }\n    else\n    {\n        _428 = _420;\n    }\n    int _429;\n    if (_428)\n    {\n        _429 = (d.x > 0.0) ? 0 : 1;\n    }\n    else\n    {\n        int _444;\n        if (_419 >= _415.z)\n        {\n            _444 = (d.y > 0.0) ? 2 : 3;\n        }\n        else\n        {\n            _444 = (d.z > 0.0) ? 4 : 5;\n        }\n        _429 = _444;\n    }\n    return _429;\n}\n\nvoid fa_cube_face_basis(int f, out vec3 fwd, out vec3 up)\n{\n    if (f == 0)\n    {\n        fwd = vec3(1.0, 0.0, 0.0);\n        up = vec3(0.0, 1.0, 0.0);\n    }\n    else\n    {\n        if (f == 1)\n        {\n            fwd = vec3(-1.0, 0.0, 0.0);\n            up = vec3(0.0, 1.0, 0.0);\n        }\n        else\n        {\n            if (f == 2)\n            {\n                fwd = vec3(0.0, 1.0, 0.0);\n                up = vec3(0.0, 0.0, 1.0);\n            }\n            else\n            {\n                if (f == 3)\n                {\n                    fwd = vec3(0.0, -1.0, 0.0);\n                    up = vec3(0.0, 0.0, -1.0);\n                }\n                else\n                {\n                    if (f == 4)\n                    {\n                        fwd = vec3(0.0, 0.0, 1.0);\n                        up = vec3(0.0, 1.0, 0.0);\n                    }\n                    else\n                    {\n                        fwd = vec3(0.0, 0.0, -1.0);\n                        up = vec3(0.0, 1.0, 0.0);\n                    }\n                }\n            }\n        }\n    }\n}\n\nLightSample fa_light_sample_n(int li, vec3 world_pos, vec3 n)\n{\n    int param = li;\n    int _812 = fa_light_base(param);\n    bool _816 = fa_mesh_fs_params[1].w > 4.5;\n    int param_1 = _812;\n    vec4 _820 = fa_light_texel(param_1);\n    int param_2 = _812 + 1;\n    vec4 _825 = fa_light_texel(param_2);\n    float _828 = _825.w;\n    float atten = 1.0;\n    float dist = 0.0;\n    fa_light_tint = vec3(1.0);\n    bool _840 = _816 && (_828 > 2.5);\n    fa_light_is_area = _840;\n    bool _842 = _828 < 0.5;\n    vec3 l;\n    if (_842)\n    {\n        l = normalize(_820.xyz);\n        if (_816)\n        {\n            int param_3 = _812 + 6;\n            vec4 _856 = fa_light_texel(param_3);\n            if (_856.z > 0.5)\n            {\n                int param_4 = _812 + 4;\n                vec4 _866 = fa_light_texel(param_4);\n                int param_5 = _812 + 5;\n                vec4 _871 = fa_light_texel(param_5);\n                vec2 param_6 = _856.xy;\n                vec2 param_7 = fract(vec2(dot(world_pos, _866.xyz) * _866.w, (-dot(world_pos, _871.xyz)) * _871.w) + vec2(0.5));\n                fa_light_tint = fa_cookie_sample(param_6, param_7);\n            }\n        }\n    }\n    else\n    {\n        vec3 _901 = _820.xyz;\n        vec3 _903 = _901 - world_pos;\n        vec3 to_light = _903;\n        float _906 = length(_903);\n        float reach = _906;\n        bool front = true;\n        if (_840)\n        {\n            int param_8 = _812 + 7;\n            reach = max(_906 - fa_light_texel(param_8).w, 0.0);\n            int param_9 = _812 + 4;\n            vec4 _930 = fa_light_texel(param_9);\n            int param_10 = _812 + 5;\n            vec4 _935 = fa_light_texel(param_10);\n            int param_11 = _812 + 6;\n            vec4 _940 = fa_light_texel(param_11);\n            float _941 = _940.w;\n            int param_12 = _812 + 2;\n            vec3 _948 = normalize(fa_light_texel(param_12).xyz);\n            bool _950 = _941 > 1.5;\n            bool _958;\n            if (!_950)\n            {\n                _958 = dot(_948, to_light) < 0.0;\n            }\n            else\n            {\n                _958 = _950;\n            }\n            front = _958;\n            vec3 r = vec3(0.0);\n            vec3 _967 = fa_mesh_fs_params[0].xyz - world_pos;\n            bool _971 = dot(n, n) > 0.5;\n            bool _979;\n            if (_971)\n            {\n                _979 = dot(_967, _967) > 9.9999999600419720025001879548654e-13;\n            }\n            else\n            {\n                _979 = _971;\n            }\n            if (_979)\n            {\n                r = reflect(-normalize(_967), normalize(n));\n            }\n            vec3 param_13 = _901;\n            vec3 param_14 = _948;\n            vec3 param_15 = _930.xyz;\n            vec3 param_16 = _935.xyz;\n            float param_17 = _930.w;\n            float param_18 = _935.w;\n            float param_19 = _941;\n            vec3 param_20 = world_pos;\n            vec3 param_21 = r;\n            to_light = fa_area_point(param_13, param_14, param_15, param_16, param_17, param_18, param_19, param_20, param_21) - world_pos;\n        }\n        float _1015 = length(to_light);\n        dist = _1015;\n        l = to_light / vec3(max(_1015, 9.9999997473787516355514526367188e-05));\n        float _1029 = reach / max(_820.w, 0.001000000047497451305389404296875);\n        float _1035 = clamp(1.0 - (_1029 * _1029), 0.0, 1.0);\n        float _1037;\n        if (front)\n        {\n            _1037 = _1035 * _1035;\n        }\n        else\n        {\n            _1037 = 0.0;\n        }\n        atten = _1037;\n        bool _1048 = _828 < 2.5;\n        if ((_828 > 1.5) && _1048)\n        {\n            int param_22 = _812 + 2;\n            vec4 _1056 = fa_light_texel(param_22);\n            float _1066 = _1056.w;\n            int param_23 = _812 + 3;\n            vec4 _1071 = fa_light_texel(param_23);\n            float _1072 = _1071.x;\n            float cos_inner = _1072;\n            if (_1072 > 1.5)\n            {\n                cos_inner = mix(_1066, 1.0, 0.25);\n            }\n            atten *= smoothstep(_1066, cos_inner, dot(-l, normalize(_1056.xyz)));\n        }\n        if (_816 && (_828 < 1.5))\n        {\n            int param_24 = _812 + 6;\n            vec4 _1096 = fa_light_texel(param_24);\n            if (_1096.z > 0.5)\n            {\n                vec3 _1104 = -to_light;\n                int param_25 = _812 + 4;\n                int param_26 = _812 + 5;\n                vec3 _1118 = fa_light_texel(param_25).xyz;\n                vec3 _1122 = fa_light_texel(param_26).xyz;\n                vec3 _1131 = vec3(dot(_1104, _1118), dot(_1104, _1122), dot(_1104, cross(_1118, _1122)));\n                vec3 param_27 = _1131;\n                int _1135 = fa_cube_face(param_27);\n                int param_28 = _1135;\n                vec3 param_29;\n                vec3 param_30;\n                fa_cube_face_basis(param_28, param_29, param_30);\n                vec2 _1162 = vec2(dot(_1131, cross(param_29, param_30)), dot(_1131, param_30)) / vec2(max(dot(_1131, param_29), 9.9999997473787516355514526367188e-05));\n                int _1166 = _1135 / 3;\n                vec2 param_31 = _1096.xy + (vec2(float(_1135 - (_1166 * 3)), float(_1166)) * 256.0);\n                vec2 param_32 = vec2(0.5 + (0.5 * _1162.x), 0.5 - (0.5 * _1162.y));\n                fa_light_tint = fa_cookie_sample(param_31, param_32);\n            }\n            int param_33 = _812 + 7;\n            vec4 _1196 = fa_light_texel(param_33);\n            if (_1196.z > 0.5)\n            {\n                int param_34 = _812 + 2;\n                int param_35 = _812 + 4;\n                int param_36 = _812 + 5;\n                vec2 param_37 = _1196.xy;\n                vec3 param_38 = -l;\n                vec3 param_39 = normalize(fa_light_texel(param_34).xyz);\n                vec3 param_40 = fa_light_texel(param_35).xyz;\n                vec3 param_41 = fa_light_texel(param_36).xyz;\n                atten *= fa_ies_sample(param_37, param_38, param_39, param_40, param_41);\n            }\n        }\n        else\n        {\n            if (_816 && _1048)\n            {\n                int param_42 = _812 + 6;\n                vec4 _1243 = fa_light_texel(param_42);\n                int param_43 = _812 + 7;\n                vec4 _1248 = fa_light_texel(param_43);\n                bool _1251 = _1243.z > 0.5;\n                bool _1258;\n                if (!_1251)\n                {\n                    _1258 = _1248.z > 0.5;\n                }\n                else\n                {\n                    _1258 = _1251;\n                }\n                if (_1258)\n                {\n                    int param_44 = _812 + 2;\n                    vec4 _1265 = fa_light_texel(param_44);\n                    vec3 _1269 = normalize(_1265.xyz);\n                    int param_45 = _812 + 4;\n                    vec4 _1274 = fa_light_texel(param_45);\n                    int param_46 = _812 + 5;\n                    vec4 _1279 = fa_light_texel(param_46);\n                    if (_1251)\n                    {\n                        vec3 _1287 = -to_light;\n                        float _1294 = _1265.w;\n                        float _1310 = 0.5 / max(dot(_1287, _1269) * (sqrt(max(1.0 - (_1294 * _1294), 0.0)) / max(_1294, 0.001000000047497451305389404296875)), 9.9999997473787516355514526367188e-05);\n                        vec2 param_47 = _1243.xy;\n                        vec2 param_48 = vec2(0.5 + (dot(_1287, _1274.xyz) * _1310), 0.5 - (dot(_1287, _1279.xyz) * _1310));\n                        fa_light_tint = fa_cookie_sample(param_47, param_48);\n                    }\n                    if (_1248.z > 0.5)\n                    {\n                        vec2 param_49 = _1248.xy;\n                        vec3 param_50 = -l;\n                        vec3 param_51 = _1269;\n                        vec3 param_52 = _1274.xyz;\n                        vec3 param_53 = _1279.xyz;\n                        atten *= fa_ies_sample(param_49, param_50, param_51, param_52, param_53);\n                    }\n                }\n            }\n        }\n    }\n    vec3 _6062 = _825.xyz * atten;\n    if (_816)\n    {\n        _6062 *= fa_light_tint;\n    }\n    int _1379;\n    if (_842)\n    {\n        _1379 = 0;\n    }\n    else\n    {\n        _1379 = ((_828 > 1.5) && (_828 < 2.5)) ? 2 : 1;\n    }\n    return LightSample(l, _6062, atten, 1.0, dist, _1379);\n}\n\nLightSample fa_light_unshadowed(int n, SurfaceInput i)\n{\n    bool _5085 = n < 0;\n    bool _5092;\n    if (!_5085)\n    {\n        _5092 = n >= fa_light_count();\n    }\n    else\n    {\n        _5092 = _5085;\n    }\n    if (_5092)\n    {\n        return fa_no_light();\n    }\n    int param = n;\n    int _5100 = fa_cl_light(param);\n    int param_1 = _5100;\n    float _5104 = fa_baked_keep(param_1);\n    if (_5104 <= 0.0)\n    {\n        return fa_no_light();\n    }\n    int param_2 = _5100;\n    vec3 param_3 = i.world_pos;\n    vec3 param_4 = i.world_normal;\n    LightSample _5120 = fa_light_sample_n(param_2, param_3, param_4);\n    return LightSample(_5120.direction, _5120.color * _5104, _5120.attenuation * _5104, _5120.shadow, _5120._distance, _5120.type);\n}\n\nfloat fa_light_type(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 1;\n    return fa_light_texel(param_1).w;\n}\n\nfloat fa_shadow_depth(inout vec2 uv, vec4 rect)\n{\n    uv = clamp(uv, rect.xy, rect.zw);\n    return textureLod(fa_shadow_tex_fa_shadow_smp, uv, 0.0).x;\n}\n\nfloat fa_shadow_fetch(vec2 uv, vec4 rect, vec3 conv)\n{\n    vec2 param = uv;\n    vec4 param_1 = rect;\n    float _2168 = fa_shadow_depth(param, param_1);\n    float _2172;\n    if (conv.x < 0.5)\n    {\n        _2172 = _2168;\n    }\n    else\n    {\n        _2172 = (conv.y * conv.z) / (conv.z - (_2168 * (conv.z - conv.y)));\n    }\n    return _2172;\n}\n\nfloat fa_shadow_noise()\n{\n    return fract(52.98291778564453125 * fract(dot(gl_FragCoord.xy, vec2(0.067110560834407806396484375, 0.005837149918079376220703125))));\n}\n\nvec2 fa_shadow_vogel_turn(vec2 d)\n{\n    return vec2((d.x * (-0.737368881702423095703125)) - (d.y * 0.675490319728851318359375), (d.y * (-0.737368881702423095703125)) + (d.x * 0.675490319728851318359375));\n}\n\nfloat fa_shadow_filter(vec2 uv, vec4 rect, float zr, float texel_m, float unit, float reach, float plane, vec3 conv, int mode, float k)\n{\n    if (mode == 1)\n    {\n        vec2 param = uv;\n        vec4 param_1 = rect;\n        vec3 param_2 = conv;\n        return float(zr <= fa_shadow_fetch(param, param_1, param_2));\n    }\n    float _2218 = fa_shadow_noise() * 6.283185482025146484375;\n    vec2 _2224 = vec2(cos(_2218), sin(_2218));\n    vec2 dir = _2224;\n    float radius = 1.5;\n    if (mode == 2)\n    {\n        float _2233;\n        if (k < 0.0)\n        {\n            _2233 = (-k) / max(zr, 0.100000001490116119384765625);\n        }\n        else\n        {\n            _2233 = k;\n        }\n        float _2252 = clamp((_2233 * reach) / texel_m, 3.0, 12.0);\n        float sum = 0.0;\n        float cnt = 0.0;\n        for (int i = 0; i < 16; i++)\n        {\n            float _2271 = sqrt((float(i) + 0.5) * 0.0625) * _2252;\n            vec2 param_3 = uv + (dir * (fa_shadows[26].zw * _2271));\n            vec4 param_4 = rect;\n            vec3 param_5 = conv;\n            float _2285 = fa_shadow_fetch(param_3, param_4, param_5);\n            if (_2285 < (zr - (_2271 * plane)))\n            {\n                sum += _2285;\n                cnt += 1.0;\n            }\n            vec2 param_6 = dir;\n            dir = fa_shadow_vogel_turn(param_6);\n        }\n        if (cnt < 0.5)\n        {\n            return 1.0;\n        }\n        float _2313 = sum / cnt;\n        float _2323;\n        if (k < 0.0)\n        {\n            _2323 = (-k) / max(_2313, 0.0500000007450580596923828125);\n        }\n        else\n        {\n            _2323 = k;\n        }\n        radius = clamp(((max(zr - _2313, 0.0) * unit) * _2323) / texel_m, 1.5, 16.0);\n        dir = _2224;\n    }\n    float lit = 0.0;\n    int _2349 = (mode == 2) ? 24 : 16;\n    for (int i_1 = 0; i_1 < _2349; i_1++)\n    {\n        float _2368 = sqrt((float(i_1) + 0.5) / float(_2349)) * radius;\n        vec2 param_7 = uv + (dir * (fa_shadows[26].zw * _2368));\n        vec4 param_8 = rect;\n        vec3 param_9 = conv;\n        lit += float((zr - (_2368 * plane)) <= fa_shadow_fetch(param_7, param_8, param_9));\n        vec2 param_10 = dir;\n        dir = fa_shadow_vogel_turn(param_10);\n    }\n    return lit / float(_2349);\n}\n\nfloat fa_shadow_local(int li, vec3 lpos, vec3 world, vec3 n, vec3 l)\n{\n    bool _2573 = fa_mesh_fs_params[5].z < 0.5;\n    bool _2580;\n    if (!_2573)\n    {\n        _2580 = fa_shadows[29].x < 0.5;\n    }\n    else\n    {\n        _2580 = _2573;\n    }\n    if (_2580)\n    {\n        return 1.0;\n    }\n    int param = (int(fa_shadows[29].x + 0.5) - 1) + li;\n    vec4 _2593 = fa_light_texel(param);\n    float _2594 = _2593.x;\n    if (_2594 < 0.0)\n    {\n        return 1.0;\n    }\n    int _2603 = int(_2594 + 0.5);\n    int param_1 = _2603;\n    vec4 _2607 = fa_light_texel(param_1);\n    int param_2 = _2603 + 1;\n    vec4 _2612 = fa_light_texel(param_2);\n    float fade = 1.0;\n    float _2615 = _2607.y;\n    if (_2615 > 0.0)\n    {\n        float _2632 = 1.0 - smoothstep(0.75 * _2615, _2615, length(world - fa_shadows[27].xyz));\n        fade = _2632;\n        if (_2632 <= 0.0)\n        {\n            return 1.0;\n        }\n    }\n    int face = 0;\n    if (_2607.x > 1.5)\n    {\n        vec3 param_3 = world - lpos;\n        face = fa_cube_face(param_3);\n    }\n    int _2656 = (_2603 + 2) + (face * 6);\n    int param_4 = _2656;\n    int param_5 = _2656 + 1;\n    int param_6 = _2656 + 3;\n    vec4 _2670 = fa_light_texel(param_6);\n    int param_7 = _2656 + 4;\n    vec4 _2675 = fa_light_texel(param_7);\n    int param_8 = _2656 + 5;\n    vec4 _2680 = fa_light_texel(param_8);\n    float _2692 = _2680.x * max(dot(_2670, vec4(world, 1.0)), 0.001000000047497451305389404296875);\n    float _2697 = clamp(dot(n, l), 0.0, 1.0);\n    float _2720 = clamp(dot(n, _2670.xyz), -1.0, 1.0);\n    float _2739 = min(sqrt(1.0 - (_2720 * _2720)) / max(abs(dot(n, world - lpos)) / max(dot(_2670, vec4(world, 1.0)), 0.001000000047497451305389404296875), 0.20000000298023223876953125), 4.0);\n    float _2742 = _2612.y;\n    float _2744;\n    if (_2742 > 0.0)\n    {\n        _2744 = _2742;\n    }\n    else\n    {\n        _2744 = 1.5 * _2692;\n    }\n    vec4 _2764 = vec4(world + (n * (_2744 * sqrt(1.0 - (_2697 * _2697)))), 1.0);\n    float _2768 = dot(_2670, _2764);\n    float _2771 = _2680.y;\n    if (_2768 < _2771)\n    {\n        return 1.0;\n    }\n    vec2 _2786 = vec2(dot(fa_light_texel(param_4), _2764), dot(fa_light_texel(param_5), _2764)) / vec2(_2768);\n    float _2788 = _2786.x;\n    bool _2791 = _2788 < _2675.x;\n    bool _2800;\n    if (!_2791)\n    {\n        _2800 = _2788 > _2675.z;\n    }\n    else\n    {\n        _2800 = _2791;\n    }\n    bool _2809;\n    if (!_2800)\n    {\n        _2809 = _2786.y < _2675.y;\n    }\n    else\n    {\n        _2809 = _2800;\n    }\n    bool _2818;\n    if (!_2809)\n    {\n        _2818 = _2786.y > _2675.w;\n    }\n    else\n    {\n        _2818 = _2809;\n    }\n    if (_2818)\n    {\n        return 1.0;\n    }\n    float _2824 = _2612.x;\n    float _2826;\n    if (_2824 > 0.0)\n    {\n        _2826 = _2824;\n    }\n    else\n    {\n        _2826 = 1.5 * _2692;\n    }\n    vec2 param_9 = _2786;\n    vec4 param_10 = _2675;\n    float param_11 = _2768 - (_2826 * (1.0 + (0.5 * _2739)));\n    float param_12 = _2692;\n    float param_13 = 1.0;\n    float param_14 = _2680.z * 0.25;\n    float param_15 = (_2692 * min(_2739, 3.0)) * 0.5;\n    vec3 param_16 = vec3(1.0, _2771, _2680.z);\n    int param_17 = int(_2607.z + 0.5);\n    float param_18 = _2607.w;\n    return mix(1.0, fa_shadow_filter(param_9, param_10, param_11, param_12, param_13, param_14, param_15, param_16, param_17, param_18), fade);\n}\n\nfloat fa_shadow_split_at(int i)\n{\n    float _2111;\n    if (i == 0)\n    {\n        _2111 = fa_shadows[24].x;\n    }\n    else\n    {\n        float _2127;\n        if (i == 1)\n        {\n            _2127 = fa_shadows[24].y;\n        }\n        else\n        {\n            float _2135;\n            if (i == 2)\n            {\n                _2135 = fa_shadows[24].z;\n            }\n            else\n            {\n                _2135 = fa_shadows[24].w;\n            }\n            _2127 = _2135;\n        }\n        _2111 = _2127;\n    }\n    return _2111;\n}\n\nfloat fa_shadow_cascade(int ci, vec3 world, vec3 n, vec3 l)\n{\n    float _2414 = max(fa_shadows[ci * 1 + 20].y, 0.001000000047497451305389404296875);\n    float _2419 = clamp(dot(n, l), 0.0, 1.0);\n    float _2425 = sqrt(1.0 - (_2419 * _2419));\n    float _2433 = min(_2425 / max(_2419, 0.20000000298023223876953125), 4.0);\n    float _2438;\n    if (fa_shadows[26].y > 0.0)\n    {\n        _2438 = fa_shadows[26].y;\n    }\n    else\n    {\n        _2438 = 1.5 * fa_shadows[ci * 1 + 20].x;\n    }\n    vec4 _2463 = mat4(fa_shadows[ci * 4 + 0], fa_shadows[ci * 4 + 1], fa_shadows[ci * 4 + 2], fa_shadows[ci * 4 + 3]) * vec4(world + (n * (_2438 * _2425)), 1.0);\n    float _2470 = _2463.x;\n    bool _2473 = _2470 < fa_shadows[ci * 1 + 16].x;\n    bool _2482;\n    if (!_2473)\n    {\n        _2482 = _2470 > fa_shadows[ci * 1 + 16].z;\n    }\n    else\n    {\n        _2482 = _2473;\n    }\n    bool _2491;\n    if (!_2482)\n    {\n        _2491 = _2463.y < fa_shadows[ci * 1 + 16].y;\n    }\n    else\n    {\n        _2491 = _2482;\n    }\n    bool _2500;\n    if (!_2491)\n    {\n        _2500 = _2463.y > fa_shadows[ci * 1 + 16].w;\n    }\n    else\n    {\n        _2500 = _2491;\n    }\n    bool _2507;\n    if (!_2500)\n    {\n        _2507 = _2463.z > 1.0;\n    }\n    else\n    {\n        _2507 = _2500;\n    }\n    if (_2507)\n    {\n        return -1.0;\n    }\n    float _2515;\n    if (fa_shadows[26].x > 0.0)\n    {\n        _2515 = fa_shadows[26].x;\n    }\n    else\n    {\n        _2515 = 1.5 * fa_shadows[ci * 1 + 20].x;\n    }\n    vec2 param = _2463.xy;\n    vec4 param_1 = fa_shadows[ci * 1 + 16];\n    float param_2 = _2463.z - ((_2515 * (1.0 + (0.5 * _2433))) / _2414);\n    float param_3 = fa_shadows[ci * 1 + 20].x;\n    float param_4 = _2414;\n    float param_5 = _2414 * 0.25;\n    float param_6 = ((fa_shadows[ci * 1 + 20].x * min(_2433, 3.0)) * 0.5) / _2414;\n    vec3 param_7 = vec3(0.0);\n    int param_8 = int(fa_shadows[25].z + 0.5);\n    float param_9 = fa_shadows[25].w;\n    return fa_shadow_filter(param, param_1, param_2, param_3, param_4, param_5, param_6, param_7, param_8, param_9);\n}\n\nfloat fa_shadow_sun(vec3 world, vec3 n, vec3 l)\n{\n    if (fa_mesh_fs_params[5].z < 0.5)\n    {\n        return 1.0;\n    }\n    int _2893 = int(fa_shadows[25].x + 0.5);\n    if (_2893 < 1)\n    {\n        return 1.0;\n    }\n    float _2908 = dot(world - fa_shadows[27].xyz, fa_shadows[28].xyz);\n    int param = _2893 - 1;\n    if (_2908 > fa_shadow_split_at(param))\n    {\n        return 1.0;\n    }\n    int ci = 0;\n    bool _2920 = _2893 > 1;\n    bool _2927;\n    if (_2920)\n    {\n        _2927 = _2908 > fa_shadows[24].x;\n    }\n    else\n    {\n        _2927 = _2920;\n    }\n    if (_2927)\n    {\n        ci = 1;\n    }\n    bool _2931 = _2893 > 2;\n    bool _2938;\n    if (_2931)\n    {\n        _2938 = _2908 > fa_shadows[24].y;\n    }\n    else\n    {\n        _2938 = _2931;\n    }\n    if (_2938)\n    {\n        ci = 2;\n    }\n    bool _2942 = _2893 > 3;\n    bool _2949;\n    if (_2942)\n    {\n        _2949 = _2908 > fa_shadows[24].z;\n    }\n    else\n    {\n        _2949 = _2942;\n    }\n    if (_2949)\n    {\n        ci = 3;\n    }\n    float s = -1.0;\n    float s2 = -1.0;\n    float t = 0.0;\n    int _2960 = min(_2893, 4);\n    float _3001;\n    for (int c = ci; c < _2960; c++)\n    {\n        int param_1 = c;\n        vec3 param_2 = world;\n        vec3 param_3 = n;\n        vec3 param_4 = l;\n        float _2980 = fa_shadow_cascade(param_1, param_2, param_3, param_4);\n        if (s >= 0.0)\n        {\n            s2 = _2980;\n            break;\n        }\n        if (_2980 < 0.0)\n        {\n            continue;\n        }\n        s = _2980;\n        ci = c;\n        if (fa_shadows[25].y > 0.0)\n        {\n            if (ci > 0)\n            {\n                int param_5 = ci - 1;\n                _3001 = fa_shadow_split_at(param_5);\n            }\n            else\n            {\n                _3001 = fa_shadows[28].w;\n            }\n            int param_6 = ci;\n            float _3020 = fa_shadows[25].y * max(fa_shadow_split_at(param_6) - _3001, 9.9999997473787516355514526367188e-05);\n            int param_7 = ci;\n            t = clamp((_2908 - (fa_shadow_split_at(param_7) - _3020)) / _3020, 0.0, 1.0);\n        }\n        if (t <= 0.0)\n        {\n            break;\n        }\n    }\n    if (s < 0.0)\n    {\n        return 1.0;\n    }\n    if (t > 0.0)\n    {\n        float _3052;\n        if ((ci + 1) < _2893)\n        {\n            _3052 = (s2 < 0.0) ? s : s2;\n        }\n        else\n        {\n            _3052 = 1.0;\n        }\n        s = mix(s, _3052, t);\n    }\n    return s;\n}\n\nfloat fa_shadow_factor(vec3 n, vec3 l)\n{\n    bool _3157 = fa_mesh_fs_params[25].y > 0.5;\n    bool _3163;\n    if (_3157)\n    {\n        _3163 = fa_mesh_fs_params[5].z > 0.5;\n    }\n    else\n    {\n        _3163 = _3157;\n    }\n    if (_3163)\n    {\n        float _3177 = dot(fa_mesh_fs_params[29].xyz, fa_world_pos) + fa_mesh_fs_params[29].w;\n        float _3180 = fwidth(_3177);\n        vec4 _3190 = vec4(fa_world_pos, 1.0);\n        float _3196 = dot(fa_mesh_fs_params[28], _3190);\n        if (_3196 > 9.9999997473787516355514526367188e-05)\n        {\n            vec2 _3215 = vec2(dot(fa_mesh_fs_params[26], _3190), dot(fa_mesh_fs_params[27], _3190)) / vec2(_3196);\n            float _3220 = (_3215.x * 0.5) + 0.5;\n            float _3224;\n            if (fa_mesh_fs_params[24].y > 0.5)\n            {\n                _3224 = (_3215.y * 0.5) + 0.5;\n            }\n            else\n            {\n                _3224 = 0.5 - (_3215.y * 0.5);\n            }\n            bool _3240 = _3220 >= 0.0;\n            bool _3246;\n            if (_3240)\n            {\n                _3246 = _3220 < 1.0;\n            }\n            else\n            {\n                _3246 = _3240;\n            }\n            bool _3252;\n            if (_3246)\n            {\n                _3252 = _3224 >= 0.0;\n            }\n            else\n            {\n                _3252 = _3246;\n            }\n            bool _3258;\n            if (_3252)\n            {\n                _3258 = _3224 < 1.0;\n            }\n            else\n            {\n                _3258 = _3252;\n            }\n            if (_3258)\n            {\n                vec4 _3284 = texelFetch(fa_screen_tex_fa_shadow_smp, clamp(ivec2(vec2(_3220, _3224) * fa_mesh_fs_params[24].zw), ivec2(0), ivec2(fa_mesh_fs_params[24].zw) - ivec2(1)), 0);\n                bool _3287 = _3284.w > 0.5;\n                bool _3303;\n                if (_3287)\n                {\n                    _3303 = abs(_3177 - _3284.x) <= (((0.00200000009499490261077880859375 * _3177) + 0.00999999977648258209228515625) + min(1.5 * _3180, 0.100000001490116119384765625 * _3177));\n                }\n                else\n                {\n                    _3303 = _3287;\n                }\n                if (_3303)\n                {\n                    float _3309;\n                    if (fa_mesh_fs_params[25].z > 0.5)\n                    {\n                        vec3 param = fa_world_pos;\n                        vec3 param_1 = n;\n                        vec3 param_2 = l;\n                        _3309 = min(_3284.y, fa_shadow_sun(param, param_1, param_2));\n                    }\n                    else\n                    {\n                        _3309 = _3284.y;\n                    }\n                    return _3309;\n                }\n            }\n        }\n    }\n    vec3 param_3 = fa_world_pos;\n    vec3 param_4 = n;\n    vec3 param_5 = l;\n    return fa_shadow_sun(param_3, param_4, param_5);\n}\n\nfloat fa_contact_shadow(int li, vec3 world, vec3 gn, vec3 l, float dist)\n{\n    bool _4600 = fa_mesh_fs_params[24].x < 0.5;\n    bool _4607;\n    if (!_4600)\n    {\n        _4607 = fa_shadows[29].x < 0.5;\n    }\n    else\n    {\n        _4607 = _4600;\n    }\n    if (_4607)\n    {\n        return 1.0;\n    }\n    int param = (int(fa_shadows[29].x + 0.5) - 1) + li;\n    vec4 _4620 = fa_light_texel(param);\n    float _4621 = _4620.y;\n    float len = _4621;\n    if (_4621 <= 0.0)\n    {\n        return 1.0;\n    }\n    float _4633 = length(world - fa_mesh_fs_params[0].xyz);\n    float _4642 = 1.0 - smoothstep(0.5 * fa_mesh_fs_params[25].x, fa_mesh_fs_params[25].x, _4633);\n    if (_4642 <= 0.0)\n    {\n        return 1.0;\n    }\n    float _4648 = len;\n    float _4651 = min(_4648, 0.89999997615814208984375 * dist);\n    len = _4651;\n    float _4656 = 0.004999999888241291046142578125 + (0.0030000000260770320892333984375 * _4633);\n    float _4661 = _4656 + (0.5 * _4651);\n    vec3 _4667 = world + (gn * _4656);\n    float _4669 = fa_shadow_noise();\n    float occ = 0.0;\n    float _4730;\n    for (int k = 0; k < 12; k++)\n    {\n        float _4684 = (float(k) + _4669) * 0.083333335816860198974609375;\n        vec3 _4692 = _4667 + (l * (_4684 * len));\n        vec4 _4698 = vec4(_4692, 1.0);\n        float _4703 = dot(fa_mesh_fs_params[28], _4698);\n        if (_4703 < 9.9999997473787516355514526367188e-05)\n        {\n            break;\n        }\n        vec2 _4721 = vec2(dot(fa_mesh_fs_params[26], _4698), dot(fa_mesh_fs_params[27], _4698)) / vec2(_4703);\n        float _4725 = _4721.x * 0.5;\n        float _4726 = _4725 + 0.5;\n        if (fa_mesh_fs_params[24].y > 0.5)\n        {\n            _4730 = (_4721.y * 0.5) + 0.5;\n        }\n        else\n        {\n            _4730 = 0.5 - (_4721.y * 0.5);\n        }\n        bool _4746 = _4726 < 0.0;\n        bool _4753;\n        if (!_4746)\n        {\n            _4753 = _4726 >= 1.0;\n        }\n        else\n        {\n            _4753 = _4746;\n        }\n        bool _4760;\n        if (!_4753)\n        {\n            _4760 = _4730 < 0.0;\n        }\n        else\n        {\n            _4760 = _4753;\n        }\n        bool _4767;\n        if (!_4760)\n        {\n            _4767 = _4730 >= 1.0;\n        }\n        else\n        {\n            _4767 = _4760;\n        }\n        if (_4767)\n        {\n            break;\n        }\n        vec4 _4791 = texelFetch(fa_screen_tex_fa_shadow_smp, clamp(ivec2(vec2(_4726, _4730) * fa_mesh_fs_params[24].zw), ivec2(0), ivec2(fa_mesh_fs_params[24].zw) - ivec2(1)), 0);\n        if (_4791.w < 0.5)\n        {\n            continue;\n        }\n        float _4809 = (dot(fa_mesh_fs_params[29].xyz, _4692) + fa_mesh_fs_params[29].w) - _4791.x;\n        if ((_4809 > _4656) && (_4809 < _4661))\n        {\n            occ = max(occ, (1.0 - (_4684 * _4684)) * smoothstep(0.0, 0.0500000007450580596923828125, min(min(_4726, 0.5 - _4725), min(_4730, 1.0 - _4730))));\n        }\n    }\n    return 1.0 - (occ * _4642);\n}\n\nLightSample fa_light_shadowed(int li, vec3 world_pos, vec3 gn)\n{\n    int param = li;\n    float _4912 = fa_baked_keep(param);\n    if (_4912 <= 0.0)\n    {\n        int param_1 = li;\n        return LightSample(vec3(0.0, 1.0, 0.0), vec3(0.0), 0.0, 1.0, 0.0, int(fa_light_type(param_1) + 0.5));\n    }\n    int param_2 = li;\n    vec3 param_3 = world_pos;\n    vec3 param_4 = gn;\n    LightSample _4938 = fa_light_sample_n(param_2, param_3, param_4);\n    vec3 _6208 = _4938.color;\n    float _6209 = _4938.attenuation;\n    float _6210 = _4938.shadow;\n    bool _4941 = _4938.type == 0;\n    if (_4941 && (li == 0))\n    {\n        vec3 param_5 = gn;\n        vec3 param_6 = _4938.direction;\n        float _4952 = fa_shadow_factor(param_5, param_6);\n        _6210 = _4952;\n        _6208 *= _4952;\n    }\n    else\n    {\n        bool _4963 = _4938.type != 0;\n        bool _4969;\n        if (_4963)\n        {\n            _4969 = _6209 > 0.0;\n        }\n        else\n        {\n            _4969 = _4963;\n        }\n        if (_4969)\n        {\n            int param_7 = li;\n            int param_8 = fa_light_base(param_7);\n            int param_9 = li;\n            vec3 param_10 = fa_light_texel(param_8).xyz;\n            vec3 param_11 = world_pos;\n            vec3 param_12 = gn;\n            vec3 param_13 = _4938.direction;\n            float _4988 = fa_shadow_local(param_9, param_10, param_11, param_12, param_13);\n            _6210 = _4988;\n            _6208 *= _4988;\n        }\n    }\n    bool _4998 = fa_mesh_fs_params[24].x > 0.5;\n    bool _5004;\n    if (_4998)\n    {\n        _5004 = _6209 > 0.0;\n    }\n    else\n    {\n        _5004 = _4998;\n    }\n    if (_5004)\n    {\n        float _5011;\n        if (_4941)\n        {\n            _5011 = 1000000000.0;\n        }\n        else\n        {\n            _5011 = _4938._distance;\n        }\n        int param_14 = li;\n        vec3 param_15 = world_pos;\n        vec3 param_16 = gn;\n        vec3 param_17 = _4938.direction;\n        float param_18 = _5011;\n        float _5029 = fa_contact_shadow(param_14, param_15, param_16, param_17, param_18);\n        _6210 *= _5029;\n        _6208 *= _5029;\n    }\n    float _5042 = _6209;\n    float _5043 = _5042 * _4912;\n    _6209 = _5043;\n    vec3 _5047 = _6208;\n    vec3 _5048 = _5047 * _4912;\n    _6208 = _5048;\n    return LightSample(_4938.direction, _5048, _5043, _6210, _4938._distance, _4938.type);\n}\n\nLightSample fa_light(int n, SurfaceInput i)\n{\n    bool _5059 = n < 0;\n    bool _5066;\n    if (!_5059)\n    {\n        _5066 = n >= fa_light_count();\n    }\n    else\n    {\n        _5066 = _5059;\n    }\n    if (_5066)\n    {\n        return fa_no_light();\n    }\n    int param = n;\n    int param_1 = fa_cl_light(param);\n    vec3 param_2 = i.world_pos;\n    vec3 param_3 = i.world_normal;\n    LightSample _5081 = fa_light_shadowed(param_1, param_2, param_3);\n    return _5081;\n}\n\nfloat fa_sheen_albedo(float ndv, float rough)\n{\n    float _3985 = min(sqrt(max(rough - 0.100000001490116119384765625, 0.0) * 1.111111164093017578125) * 6.0, 5.999000072479248046875);\n    float _3993 = min(sqrt(clamp(ndv, 0.0, 1.0)) * 8.0, 7.999000072479248046875);\n    int _3996 = int(_3985);\n    int _3999 = int(_3993);\n    float _4009 = _3993 - float(_3999);\n    int _4065 = (_3996 * 9) + _3999;\n    int _4085 = ((_3996 + 1) * 9) + _3999;\n    return mix(mix(_4060[_4065], _4060[_4065 + 1], _4009), mix(_4060[_4085], _4060[_4085 + 1], _4009), _3985 - float(_3996));\n}\n\nFaLayers fa_layers_setup(SurfaceInput i, Surface s, vec3 n, vec3 v, float metallic, float roughness, inout vec3 f0)\n{\n    bool _6074 = false;\n    float _6075 = 1.0;\n    float _6076 = 1.0;\n    float _6077 = 1.0;\n    float _6078 = 0.0;\n    float _6079 = 0.0;\n    float _6080 = 0.0;\n    float _6081 = 0.0;\n    float _6083 = 1.0;\n    bool _6084 = false;\n    vec3 _6085 = vec3(0.0);\n    float _6086 = 1.0;\n    float _6087 = 1.0;\n    float _6088 = 1.0;\n    float _6089 = 0.0;\n    float _6090 = 0.0;\n    vec3 _6091 = vec3(1.0, 0.0, 0.0);\n    vec3 _6092 = vec3(0.0, 0.0, 1.0);\n    float _6093 = 1.0;\n    float _6094 = 1.0;\n    float _4136 = clamp(s.specular, 0.0, 1.0);\n    float _4140 = clamp(s.ior, 1.0, 3.0);\n    bool _4145 = (_4136 != 1.0) || (_4140 != 1.5);\n    bool _4154;\n    if (!_4145)\n    {\n        _4154 = any(notEqual(s.specular_color, vec3(1.0)));\n    }\n    else\n    {\n        _4154 = _4145;\n    }\n    if (_4154)\n    {\n        float _4162 = (_4140 - 1.0) / (_4140 + 1.0);\n        f0 = mix(min(vec3(_4162 * _4162) * max(s.specular_color, vec3(0.0)), vec3(1.0)) * _4136, s.albedo, vec3(metallic));\n        _6075 = mix(_4136, 1.0, metallic);\n        _6074 = true;\n    }\n    float _4189 = clamp(s.clearcoat, 0.0, 1.0);\n    if (_4189 > 0.0)\n    {\n        float _4197 = clamp(s.clearcoat_roughness, 0.0500000007450580596923828125, 1.0);\n        _6078 = _4189;\n        _6079 = _4197;\n        float _4204 = _4197 * _4197;\n        _6080 = _4204;\n        _6081 = _4204 * _4204;\n        float _4216 = max(dot(i.world_normal, v), 9.9999997473787516355514526367188e-05);\n        _6083 = _4216;\n        _6076 = 1.0 - (_4189 * (0.039999999105930328369140625 + (0.959999978542327880859375 * pow(clamp(1.0 - _4216, 0.0, 1.0), 5.0))));\n        _6074 = true;\n    }\n    vec3 _4235 = max(s.sheen_color, vec3(0.0));\n    float _4244 = max(_4235.x, max(_4235.y, _4235.z));\n    if (_4244 > 0.0)\n    {\n        float _4252 = clamp(s.sheen_roughness, 0.100000001490116119384765625, 1.0);\n        _6084 = true;\n        _6085 = _4235;\n        _6086 = _4252;\n        _6087 = _4252 * _4252;\n        float param = max(dot(n, v), 9.9999997473787516355514526367188e-05);\n        float param_1 = _4252;\n        float _4269 = fa_sheen_albedo(param, param_1);\n        _6089 = _4269;\n        _6088 = 1.0 - min(_4244 * _4269, 1.0);\n        _6074 = true;\n    }\n    _6077 = _6076 * _6088;\n    float _4288 = clamp(s.anisotropy, -1.0, 1.0);\n    if (_4288 != 0.0)\n    {\n        vec3 _4303 = i.world_tangent.xyz - (n * dot(n, i.world_tangent.xyz));\n        vec3 t = _4303;\n        if (dot(_4303, _4303) < 9.9999999392252902907785028219223e-09)\n        {\n            bvec3 _4315 = bvec3(abs(n.y) < 0.9900000095367431640625);\n            t = cross(vec3(_4315.x ? vec3(0.0, 1.0, 0.0).x : vec3(1.0, 0.0, 0.0).x, _4315.y ? vec3(0.0, 1.0, 0.0).y : vec3(1.0, 0.0, 0.0).y, _4315.z ? vec3(0.0, 1.0, 0.0).z : vec3(1.0, 0.0, 0.0).z), n);\n        }\n        vec3 _4319 = t;\n        vec3 _4320 = normalize(_4319);\n        t = _4320;\n        vec3 _4345 = normalize((_4320 * cos(s.anisotropy_rotation)) + ((cross(n, _4320) * ((i.world_tangent.w < 0.0) ? (-1.0) : 1.0)) * sin(s.anisotropy_rotation)));\n        _6091 = _4345;\n        _6092 = cross(n, _4345);\n        float _4355 = roughness * roughness;\n        float _4361 = mix(_4355, 1.0, _4288 * _4288);\n        bool _4363 = _4288 > 0.0;\n        _6093 = _4363 ? _4361 : _4355;\n        _6094 = _4363 ? _4355 : _4361;\n        _6090 = _4288;\n        _6074 = true;\n    }\n    return FaLayers(_6074, _6075, _6076, _6077, _6078, _6079, _6080, _6081, i.world_normal, _6083, _6084, _6085, _6086, _6087, _6088, _6089, _6090, _6091, _6092, _6093, _6094);\n}\n\nvec2 fa_env_brdf(float rough, float ndv)\n{\n    vec4 _3917 = (vec4(-1.0, -0.0274999998509883880615234375, -0.572000026702880859375, 0.02199999988079071044921875) * rough) + vec4(1.0, 0.0425000004470348358154296875, 1.03999996185302734375, -0.039999999105930328369140625);\n    float _3920 = _3917.x;\n    return (vec2(-1.03999996185302734375, 1.03999996185302734375) * ((min(_3920 * _3920, exp2((-9.27999973297119140625) * ndv)) * _3920) + _3917.y)) + _3917.zw;\n}\n\nvec2 fa_oct_encode(vec3 d)\n{\n    vec3 _3353 = d / vec3(max((abs(d.x) + abs(d.y)) + abs(d.z), 9.9999999600419720025001879548654e-13));\n    float _3356 = _3353.x;\n    float _3358 = _3353.z;\n    vec2 e = vec2(_3356, _3358);\n    if (_3353.y < 0.0)\n    {\n        e = vec2((1.0 - abs(_3358)) * ((_3356 < 0.0) ? (-1.0) : 1.0), (1.0 - abs(_3356)) * ((_3358 < 0.0) ? (-1.0) : 1.0));\n    }\n    return e;\n}\n\nvec2 fa_atlas_size()\n{\n    return vec2(textureSize(fa_probe_atlas_fa_env_smp, 0));\n}\n\nvec3 fa_probe_level(vec2 origin, float res, int lv, vec2 e)\n{\n    float _3405;\n    if (lv == 0)\n    {\n        _3405 = 0.0;\n    }\n    else\n    {\n        _3405 = res + 2.0;\n    }\n    float _3415;\n    if (lv == 0)\n    {\n        _3415 = 0.0;\n    }\n    else\n    {\n        _3415 = (res - (res / float(1 << max((lv - 1), 0)))) + (2.0 * float(lv - 1));\n    }\n    return textureLod(fa_probe_atlas_fa_env_smp, (((origin + vec2(_3405, _3415)) + vec2(1.0)) + (((e * 0.5) + vec2(0.5)) * (res / float(1 << lv)))) / fa_atlas_size(), 0.0).xyz;\n}\n\nvec3 fa_probe_radiance(vec2 origin, float res, vec3 d, float rough)\n{\n    float _3461;\n    if (res > 64.5)\n    {\n        _3461 = 5.0;\n    }\n    else\n    {\n        _3461 = (res > 32.5) ? 4.0 : 3.0;\n    }\n    float _3476 = clamp(rough, 0.0, 1.0) * (_3461 - 1.0);\n    int _3483 = int(min(floor(_3476), _3461 - 2.0));\n    float _3488 = _3476 - float(_3483);\n    vec3 param = d;\n    vec2 _3492 = fa_oct_encode(param);\n    vec2 param_1 = origin;\n    float param_2 = res;\n    int param_3 = _3483;\n    vec2 param_4 = _3492;\n    vec3 _3502 = fa_probe_level(param_1, param_2, param_3, param_4);\n    if (_3488 < 0.00200000009499490261077880859375)\n    {\n        return _3502;\n    }\n    vec2 param_5 = origin;\n    float param_6 = res;\n    int param_7 = _3483 + 1;\n    vec2 param_8 = _3492;\n    return mix(_3502, fa_probe_level(param_5, param_6, param_7, param_8), vec3(_3488));\n}\n\nvec3 fa_probe_box_dir(vec3 d, vec4 posw, vec4 bx, vec4 by, vec4 bz)\n{\n    if (posw.w < 0.5)\n    {\n        return d;\n    }\n    float _3539 = dot(bx.xyz, fa_world_pos) + bx.w;\n    float _3546 = dot(by.xyz, fa_world_pos) + by.w;\n    float _3553 = dot(bz.xyz, fa_world_pos) + bz.w;\n    float _3559 = dot(bx.xyz, d);\n    float _3563 = dot(by.xyz, d);\n    float _3567 = dot(bz.xyz, d);\n    float _3573;\n    if (_3559 > 9.9999999747524270787835121154785e-07)\n    {\n        _3573 = (1.0 - _3539) / _3559;\n    }\n    else\n    {\n        float _3587;\n        if (_3559 < (-9.9999999747524270787835121154785e-07))\n        {\n            _3587 = ((-1.0) - _3539) / _3559;\n        }\n        else\n        {\n            _3587 = 1000000015047466219876688855040.0;\n        }\n        _3573 = _3587;\n    }\n    float tx = _3573;\n    float _3604;\n    if (_3563 > 9.9999999747524270787835121154785e-07)\n    {\n        _3604 = (1.0 - _3546) / _3563;\n    }\n    else\n    {\n        float _3617;\n        if (_3563 < (-9.9999999747524270787835121154785e-07))\n        {\n            _3617 = ((-1.0) - _3546) / _3563;\n        }\n        else\n        {\n            _3617 = 1000000015047466219876688855040.0;\n        }\n        _3604 = _3617;\n    }\n    float ty = _3604;\n    float _3633;\n    if (_3567 > 9.9999999747524270787835121154785e-07)\n    {\n        _3633 = (1.0 - _3553) / _3567;\n    }\n    else\n    {\n        float _3646;\n        if (_3567 < (-9.9999999747524270787835121154785e-07))\n        {\n            _3646 = ((-1.0) - _3553) / _3567;\n        }\n        else\n        {\n            _3646 = 1000000015047466219876688855040.0;\n        }\n        _3633 = _3646;\n    }\n    float _3658 = tx;\n    float _3661 = (_3658 > 0.0) ? _3658 : 1000000015047466219876688855040.0;\n    tx = _3661;\n    float _3662 = ty;\n    float _3665 = (_3662 > 0.0) ? _3662 : 1000000015047466219876688855040.0;\n    ty = _3665;\n    float _3675 = min(_3661, min(_3665, (_3633 > 0.0) ? _3633 : 1000000015047466219876688855040.0));\n    if (_3675 > 100000001504746621987668885504.0)\n    {\n        return d;\n    }\n    vec3 _3691 = (fa_world_pos + (d * _3675)) - posw.xyz;\n    vec3 _3696;\n    if (dot(_3691, _3691) > 1.0000000133514319600180897396058e-10)\n    {\n        _3696 = normalize(_3691);\n    }\n    else\n    {\n        _3696 = d;\n    }\n    return _3696;\n}\n\nvec3 fa_probe_environment(vec4 tile, vec4 posw, vec4 bx, vec4 by, vec4 bz, inout vec3 d, float rough)\n{\n    vec3 param = d;\n    vec4 param_1 = posw;\n    vec4 param_2 = bx;\n    vec4 param_3 = by;\n    vec4 param_4 = bz;\n    d = fa_probe_box_dir(param, param_1, param_2, param_3, param_4);\n    vec2 param_5 = tile.xy;\n    float param_6 = tile.z;\n    vec3 param_7 = d;\n    float param_8 = rough;\n    return fa_probe_radiance(param_5, param_6, param_7, param_8);\n}\n\nvec3 fa_environment(vec3 d, float rough)\n{\n    float _3742 = (1.0 - fa_mesh_fs_params[42].w) - fa_mesh_fs_params[47].w;\n    vec3 outc = vec3(0.0);\n    if (_3742 > 0.0005000000237487256526947021484375)\n    {\n        vec3 base;\n        if (fa_mesh_fs_params[11].w > 0.5)\n        {\n            vec2 param = fa_mesh_fs_params[41].zw;\n            float param_1 = 128.0;\n            vec3 param_2 = d;\n            float param_3 = rough;\n            base = fa_probe_radiance(param, param_1, param_2, param_3);\n        }\n        else\n        {\n            float _3772 = rough * rough;\n            float _3803 = 0.60000002384185791015625 * _3772;\n            base = mix(mix(fa_mesh_fs_params[12].xyz * 0.550000011920928955078125, mix(fa_mesh_fs_params[12].xyz, fa_mesh_fs_params[11].xyz, vec3(pow(clamp(d.y * (1.0 - (0.699999988079071044921875 * _3772)), 0.0, 1.0), 0.550000011920928955078125))), vec3(smoothstep((-0.0500000007450580596923828125) - _3803, 0.0500000007450580596923828125 + _3803, d.y))), ((fa_mesh_fs_params[11].xyz + fa_mesh_fs_params[12].xyz) * 0.5) * 0.800000011920928955078125, vec3(_3772 * 0.60000002384185791015625));\n        }\n        outc = base * _3742;\n    }\n    if (fa_mesh_fs_params[42].w > 0.0)\n    {\n        vec4 param_4 = fa_mesh_fs_params[42];\n        vec4 param_5 = fa_mesh_fs_params[43];\n        vec4 param_6 = fa_mesh_fs_params[44];\n        vec4 param_7 = fa_mesh_fs_params[45];\n        vec4 param_8 = fa_mesh_fs_params[46];\n        vec3 param_9 = d;\n        float param_10 = rough;\n        vec3 _3862 = fa_probe_environment(param_4, param_5, param_6, param_7, param_8, param_9, param_10);\n        outc += (_3862 * fa_mesh_fs_params[42].w);\n    }\n    if (fa_mesh_fs_params[47].w > 0.0)\n    {\n        vec4 param_11 = fa_mesh_fs_params[47];\n        vec4 param_12 = fa_mesh_fs_params[48];\n        vec4 param_13 = fa_mesh_fs_params[49];\n        vec4 param_14 = fa_mesh_fs_params[50];\n        vec4 param_15 = fa_mesh_fs_params[51];\n        vec3 param_16 = d;\n        float param_17 = rough;\n        vec3 _3894 = fa_probe_environment(param_11, param_12, param_13, param_14, param_15, param_16, param_17);\n        outc += (_3894 * fa_mesh_fs_params[47].w);\n    }\n    return outc;\n}\n\nvec3 fa_layers_ibl(FaLayers L, vec3 n, vec3 v, vec3 f0, float roughness, float occlusion)\n{\n    vec3 rn = n;\n    if (L.aniso != 0.0)\n    {\n        vec3 _4396;\n        if (L.aniso >= 0.0)\n        {\n            _4396 = L.b;\n        }\n        else\n        {\n            _4396 = L.t;\n        }\n        rn = normalize(mix(n, cross(cross(_4396, v), _4396), vec3(abs(L.aniso) * smoothstep(0.0, 0.25, roughness))));\n    }\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05);\n    vec2 _4432 = fa_env_brdf(param, param_1);\n    vec3 param_2 = reflect(-v, rn);\n    float param_3 = roughness;\n    vec3 result = (fa_environment(param_2, param_3) * ((f0 * _4432.x) + (vec3(L.f90) * _4432.y))) * L.base_scale;\n    if (L.sheen_on)\n    {\n        vec3 param_4 = n;\n        float param_5 = L.sheen_rough;\n        result += ((L.sheen * (L.sheen_e * L.keep)) * fa_environment(param_4, param_5));\n    }\n    result *= occlusion;\n    if (L.coat > 0.0)\n    {\n        float param_6 = L.coat_rough;\n        float param_7 = L.coat_ndv;\n        vec2 _4490 = fa_env_brdf(param_6, param_7);\n        vec3 param_8 = reflect(-v, L.nc);\n        float param_9 = L.coat_rough;\n        result += (fa_environment(param_8, param_9) * (L.coat * ((0.039999999105930328369140625 * _4490.x) + _4490.y)));\n    }\n    return result;\n}\n\nvec3 fa_sky_reflection(vec3 n, vec3 v, vec3 f0, float roughness)\n{\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05);\n    vec2 _3959 = fa_env_brdf(param, param_1);\n    vec3 param_2 = reflect(-v, n);\n    float param_3 = roughness;\n    return fa_environment(param_2, param_3) * ((f0 * _3959.x) + vec3(_3959.y));\n}\n\nvec3 fa_sky_light(SurfaceInput i, Surface s)\n{\n    float _4529 = clamp(s.metallic, 0.0, 1.0);\n    float _4533 = clamp(s.roughness, 0.0500000007450580596923828125, 1.0);\n    vec3 _4540 = mix(vec3(0.039999999105930328369140625), s.albedo, vec3(_4529));\n    vec3 f0 = _4540;\n    vec3 _4544 = normalize(s.normal);\n    SurfaceInput param = i;\n    Surface param_1 = s;\n    vec3 param_2 = _4544;\n    vec3 param_3 = i.view_dir;\n    float param_4 = _4529;\n    float param_5 = _4533;\n    vec3 param_6 = _4540;\n    FaLayers _4561 = fa_layers_setup(param, param_1, param_2, param_3, param_4, param_5, param_6);\n    f0 = param_6;\n    if (_4561.on)\n    {\n        FaLayers param_7 = _4561;\n        vec3 param_8 = _4544;\n        vec3 param_9 = i.view_dir;\n        vec3 param_10 = f0;\n        float param_11 = _4533;\n        float param_12 = s.occlusion;\n        return fa_layers_ibl(param_7, param_8, param_9, param_10, param_11, param_12);\n    }\n    vec3 param_13 = _4544;\n    vec3 param_14 = i.view_dir;\n    vec3 param_15 = f0;\n    float param_16 = _4533;\n    return fa_sky_reflection(param_13, param_14, param_15, param_16) * s.occlusion;\n}\n\nvec3 lighting(SurfaceInput i, Surface s)\n{\n    int best = -1;\n    float bestPower = 0.0;\n    for (int n = 0; n < fa_light_count(); n++)\n    {\n        int param = n;\n        SurfaceInput param_1 = i;\n        LightSample _5151 = fa_light_unshadowed(param, param_1);\n        float _5159 = dot(_5151.color, vec3(0.2989999949932098388671875, 0.58700001239776611328125, 0.114000000059604644775390625));\n        if (_5159 > bestPower)\n        {\n            bestPower = _5159;\n            best = n;\n        }\n    }\n    vec3 lit = (fa_mesh_fs_params[1].xyz * s.albedo) * s.occlusion;\n    if (best >= 0)\n    {\n        int param_2 = best;\n        SurfaceInput param_3 = i;\n        LightSample _5188 = fa_light(param_2, param_3);\n        float _5196;\n        if (dot(s.normal, _5188.direction) > 0.5)\n        {\n            _5196 = 1.0;\n        }\n        else\n        {\n            _5196 = fa_material[0].x;\n        }\n        lit += ((s.albedo * _5188.color) * _5196);\n    }\n    SurfaceInput param_4 = i;\n    Surface param_5 = s;\n    return lit + (fa_sky_light(param_4, param_5) * fa_material[1].x);\n}\n\nvec3 fa_shadow_debug(vec3 color, vec3 world)\n{\n    if (fa_shadows[27].w < 0.5)\n    {\n        return color;\n    }\n    int _3080 = int(fa_shadows[25].x + 0.5);\n    float _3090 = dot(world - fa_shadows[27].xyz, fa_shadows[28].xyz);\n    vec3 tint = vec3(0.3499999940395355224609375);\n    bool _3095 = _3080 > 0;\n    bool _3104;\n    if (_3095)\n    {\n        int param = _3080 - 1;\n        _3104 = _3090 <= fa_shadow_split_at(param);\n    }\n    else\n    {\n        _3104 = _3095;\n    }\n    if (_3104)\n    {\n        tint = vec3(1.0, 0.1500000059604644775390625, 0.100000001490116119384765625);\n        bool _3110 = _3080 > 1;\n        bool _3117;\n        if (_3110)\n        {\n            _3117 = _3090 > fa_shadows[24].x;\n        }\n        else\n        {\n            _3117 = _3110;\n        }\n        if (_3117)\n        {\n            tint = vec3(0.100000001490116119384765625, 0.89999997615814208984375, 0.20000000298023223876953125);\n        }\n        bool _3123 = _3080 > 2;\n        bool _3130;\n        if (_3123)\n        {\n            _3130 = _3090 > fa_shadows[24].y;\n        }\n        else\n        {\n            _3130 = _3123;\n        }\n        if (_3130)\n        {\n            tint = vec3(0.1500000059604644775390625, 0.300000011920928955078125, 1.0);\n        }\n        bool _3136 = _3080 > 3;\n        bool _3143;\n        if (_3136)\n        {\n            _3143 = _3090 > fa_shadows[24].z;\n        }\n        else\n        {\n            _3143 = _3136;\n        }\n        if (_3143)\n        {\n            tint = vec3(1.0, 0.89999997615814208984375, 0.100000001490116119384765625);\n        }\n    }\n    return mix(color, tint, vec3(0.550000011920928955078125));\n}\n\nvoid main()\n{\n    fa_inst_load();\n    vec3 _5928 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _5928 = -_5928;\n    }\n    vec3 _5598 = normalize(fa_mesh_fs_params[0].xyz - fa_world_pos);\n    vec3 param = fa_world_pos;\n    fa_cluster_begin(param);\n    SurfaceInput param_1 = SurfaceInput(fa_world_pos, _5928, fa_world_tangent, fa_uv, fa_vertex_color, _5598, gl_FrontFacing);\n    Surface _5606 = fa_standard_surface(param_1);\n    vec3 _5959 = _5606.albedo;\n    float _5960 = _5606.alpha;\n    vec3 _5961 = _5606.normal;\n    float _5962 = _5606.metallic;\n    float _5963 = _5606.roughness;\n    float _5964 = _5606.occlusion;\n    vec3 _5965 = _5606.emission;\n    float _5966 = _5606.clearcoat;\n    float _5967 = _5606.clearcoat_roughness;\n    vec3 _5968 = _5606.sheen_color;\n    float _5969 = _5606.sheen_roughness;\n    float _5970 = _5606.anisotropy;\n    float _5971 = _5606.anisotropy_rotation;\n    float _5972 = _5606.specular;\n    float _5973 = _5606.ior;\n    vec3 _5974 = _5606.specular_color;\n    float _5975 = _5606.transmission;\n    float _5976 = _5606.thickness;\n    vec3 _5977 = _5606.attenuation_color;\n    float _5978 = _5606.attenuation_distance;\n    SurfaceInput param_2 = SurfaceInput(fa_world_pos, _5928, fa_world_tangent, fa_uv, fa_vertex_color, _5598, gl_FrontFacing);\n    Surface param_3 = _5606;\n    surface(param_2, param_3);\n    _5959 = param_3.albedo;\n    _5960 = param_3.alpha;\n    _5961 = param_3.normal;\n    _5962 = param_3.metallic;\n    _5963 = param_3.roughness;\n    _5964 = param_3.occlusion;\n    _5965 = param_3.emission;\n    _5966 = param_3.clearcoat;\n    _5967 = param_3.clearcoat_roughness;\n    _5968 = param_3.sheen_color;\n    _5969 = param_3.sheen_roughness;\n    _5970 = param_3.anisotropy;\n    _5971 = param_3.anisotropy_rotation;\n    _5972 = param_3.specular;\n    _5973 = param_3.ior;\n    _5974 = param_3.specular_color;\n    _5975 = param_3.transmission;\n    _5976 = param_3.thickness;\n    _5977 = param_3.attenuation_color;\n    _5978 = param_3.attenuation_distance;\n    vec3 param_4 = fa_world_pos;\n    vec3 param_5 = _5928;\n    vec3 param_6 = param_3.albedo;\n    vec3 param_7 = param_3.normal;\n    fa_apply_decals(param_4, param_5, param_6, param_7);\n    _5959 = param_6;\n    _5961 = param_7;\n    vec3 result;\n    if (fa_mesh_fs_params[3].w > 0.5)\n    {\n        result = _5959;\n    }\n    else\n    {\n        vec3 _5645 = _5961;\n        vec3 _5646 = normalize(_5645);\n        _5961 = _5646;\n        SurfaceInput param_8 = SurfaceInput(fa_world_pos, _5928, fa_world_tangent, fa_uv, fa_vertex_color, _5598, gl_FrontFacing);\n        Surface param_9 = Surface(_5959, _5960, _5646, _5962, _5963, _5964, _5965, _5966, _5967, _5968, _5969, _5970, _5971, _5972, _5973, _5974, _5975, _5976, _5977, _5978);\n        vec3 _5657 = lighting(param_8, param_9);\n        result = _5657;\n    }\n    vec3 _5661 = result;\n    vec3 _5662 = _5661 + _5965;\n    result = _5662;\n    vec3 param_10 = _5662;\n    vec3 param_11 = fa_world_pos;\n    result = fa_shadow_debug(param_10, param_11);\n    bool _5671 = fa_mesh_fs_params[7].w > 0.0;\n    bool _5678;\n    if (!_5671)\n    {\n        _5678 = fa_mesh_fs_params[8].y > 0.0;\n    }\n    else\n    {\n        _5678 = _5671;\n    }\n    if (_5678)\n    {\n        vec3 _5687 = fa_world_pos - fa_mesh_fs_params[0].xyz;\n        float _5693 = dot(_5687, fa_mesh_fs_params[9].xyz);\n        bool _5697 = fa_mesh_fs_params[9].w > 0.5;\n        float _5698;\n        if (_5697)\n        {\n            _5698 = _5693;\n        }\n        else\n        {\n            _5698 = length(_5687);\n        }\n        float _5710 = _5698 - fa_mesh_fs_params[8].x;\n        if (_5710 > 0.0)\n        {\n            float _5719 = fa_mesh_fs_params[7].w * _5710;\n            float tau = _5719 * _5719;\n            if (fa_mesh_fs_params[8].y > 0.0)\n            {\n                float _5735;\n                if (_5697)\n                {\n                    _5735 = fa_world_pos.y - (fa_mesh_fs_params[9].y * _5693);\n                }\n                else\n                {\n                    _5735 = fa_mesh_fs_params[0].y;\n                }\n                float _5756 = mix(_5735, fa_world_pos.y, clamp(fa_mesh_fs_params[8].x / _5698, 0.0, 1.0));\n                float _5760 = fa_world_pos.y - _5756;\n                float _5765 = _5756 - fa_mesh_fs_params[8].z;\n                float _5770 = fa_world_pos.y - fa_mesh_fs_params[8].z;\n                bool _5773 = _5765 <= 0.0;\n                bool _5774 = !_5773;\n                bool _5780;\n                if (_5774)\n                {\n                    _5780 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _5780 = _5773;\n                }\n                float _5781;\n                if (_5780)\n                {\n                    _5781 = fa_mesh_fs_params[8].y;\n                }\n                else\n                {\n                    _5781 = fa_mesh_fs_params[8].y * exp(-min(fa_mesh_fs_params[8].w * _5765, 80.0));\n                }\n                bool _5808;\n                if (_5774)\n                {\n                    _5808 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _5808 = _5773;\n                }\n                float _5809;\n                if (_5808)\n                {\n                    _5809 = fa_mesh_fs_params[8].y * _5765;\n                }\n                else\n                {\n                    _5809 = (fa_mesh_fs_params[8].y * (1.0 - exp(-min(fa_mesh_fs_params[8].w * _5765, 80.0)))) / fa_mesh_fs_params[8].w;\n                }\n                bool _5834 = _5770 <= 0.0;\n                bool _5841;\n                if (!_5834)\n                {\n                    _5841 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _5841 = _5834;\n                }\n                float _5842;\n                if (_5841)\n                {\n                    _5842 = fa_mesh_fs_params[8].y * _5770;\n                }\n                else\n                {\n                    _5842 = (fa_mesh_fs_params[8].y * (1.0 - exp(-min(fa_mesh_fs_params[8].w * _5770, 80.0)))) / fa_mesh_fs_params[8].w;\n                }\n                float _5869;\n                if (abs(_5760) < 0.001000000047497451305389404296875)\n                {\n                    _5869 = _5781;\n                }\n                else\n                {\n                    _5869 = (_5842 - _5809) / _5760;\n                }\n                tau += (_5710 * max(_5869, 0.0));\n            }\n            result = mix(result, fa_mesh_fs_params[7].xyz, vec3(clamp(1.0 - exp(-clamp(tau, 0.0, 80.0)), 0.0, 1.0)));\n        }\n    }\n    fa_frag_color = vec4(result, _5960);\n}\n\n",
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
            "inst_name": "_136",
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
            "inst_name": "_183",
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
            "inst_name": "_468",
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
            "inst_name": "_2121",
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
            "size": 32,
            "struct_name": "fa_material",
            "inst_name": "_5202",
            "glsl_uniforms": [
              {
                "type": "vec4",
                "array_count": 2,
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
            "name": "fa_light_atlas_fa_env_smp",
            "view_name": "fa_light_atlas",
            "sampler_name": "fa_env_smp",
            "view_slot": 25,
            "sampler_slot": 10,
            "glsl_name": "fa_light_atlas_fa_env_smp"
          },
          {
            "slot": 8,
            "stage": "fragment",
            "name": "fa_shadow_tex_fa_shadow_smp",
            "view_name": "fa_shadow_tex",
            "sampler_name": "fa_shadow_smp",
            "view_slot": 1,
            "sampler_slot": 1,
            "glsl_name": "fa_shadow_tex_fa_shadow_smp"
          },
          {
            "slot": 9,
            "stage": "fragment",
            "name": "fa_screen_tex_fa_shadow_smp",
            "view_name": "fa_screen_tex",
            "sampler_name": "fa_shadow_smp",
            "view_slot": 28,
            "sampler_slot": 1,
            "glsl_name": "fa_screen_tex_fa_shadow_smp"
          },
          {
            "slot": 10,
            "stage": "fragment",
            "name": "fa_probe_atlas_fa_env_smp",
            "view_name": "fa_probe_atlas",
            "sampler_name": "fa_env_smp",
            "view_slot": 14,
            "sampler_slot": 10,
            "glsl_name": "fa_probe_atlas_fa_env_smp"
          }
        ]
      }
    },
    "prepass": {
      "vs": "#version 430\n\nstruct VertexData\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 color;\n    vec3 object_pos;\n};\n\nuniform vec4 fa_mesh_vs_params[11];\nuniform vec4 fa_vel_params[9];\nlayout(location = 0) out vec3 fa_world_pos;\nlayout(location = 1) out vec3 fa_world_normal;\nlayout(location = 2) out vec4 fa_world_tangent;\nlayout(location = 3) out vec2 fa_uv;\nlayout(location = 4) out vec4 fa_vertex_color;\nlayout(location = 5) out float fa_pre_depth;\nlayout(location = 6) out vec3 fa_pre_r0;\nlayout(location = 7) out vec3 fa_pre_r1;\nlayout(location = 8) out vec3 fa_pre_r2;\nlayout(location = 9) out vec3 fa_vel_cur;\nlayout(location = 10) out vec3 fa_vel_prev;\nlayout(location = 9) in vec4 fa_prev_r0;\nlayout(location = 10) in vec4 fa_prev_r1;\nlayout(location = 11) in vec4 fa_prev_r2;\nlayout(location = 5) in vec4 fa_inst_m0;\nlayout(location = 6) in vec4 fa_inst_m1;\nlayout(location = 7) in vec4 fa_inst_m2;\nlayout(location = 8) in vec4 fa_inst_m3;\nlayout(location = 0) in vec3 fa_position;\nlayout(location = 1) in vec3 fa_normal;\nlayout(location = 3) in vec4 fa_tangent;\nlayout(location = 2) in vec2 fa_texcoord0;\nlayout(location = 4) in vec4 fa_color;\nvec4 fa_vtime;\n\nvoid fa_inst_begin()\n{\n}\n\nvec4 fa_time_now()\n{\n    return fa_mesh_vs_params[9];\n}\n\nVertexData fa_vertex_data(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    vec3 _97 = cross(model[1].xyz, model[2].xyz);\n    float _101 = (dot(model[0].xyz, _97) < 0.0) ? (-1.0) : 1.0;\n    return VertexData((model * vec4(position, 1.0)).xyz, (((_97 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _101, vec4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _101), texcoord0 * fa_mesh_vs_params[8].xy, color, position);\n}\n\nmat4 fa_rows_to_mat4(vec4 r0, vec4 r1, vec4 r2)\n{\n    return mat4(vec4(r0.x, r1.x, r2.x, 0.0), vec4(r0.y, r1.y, r2.y, 0.0), vec4(r0.z, r1.z, r2.z, 0.0), vec4(r0.w, r1.w, r2.w, 1.0));\n}\n\nmat4 fa_prev_model()\n{\n    vec4 param = fa_prev_r0;\n    vec4 param_1 = fa_prev_r1;\n    vec4 param_2 = fa_prev_r2;\n    return fa_rows_to_mat4(param, param_1, param_2);\n}\n\nvoid fa_prepass_vertex(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color, bool has_prev)\n{\n    bool _231;\n    if (has_prev)\n    {\n        _231 = fa_vel_params[8].x > 0.5;\n    }\n    else\n    {\n        _231 = has_prev;\n    }\n    fa_vtime = fa_time_now();\n    mat4 param = model;\n    vec3 param_1 = position;\n    vec3 param_2 = normal;\n    vec4 param_3 = tangent;\n    vec2 param_4 = texcoord0;\n    vec4 param_5 = color;\n    VertexData _246 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    vec3 _458 = _246.world_pos;\n    mat4 _250 = mat4(fa_mesh_vs_params[4], fa_mesh_vs_params[5], fa_mesh_vs_params[6], fa_mesh_vs_params[7]);\n    vec4 _257 = vec4(_458, 1.0);\n    fa_world_pos = _458;\n    fa_world_normal = _246.world_normal;\n    fa_world_tangent = _246.world_tangent;\n    fa_uv = _246.uv;\n    fa_vertex_color = _246.color;\n    fa_pre_depth = -(_250 * _257).z;\n    fa_pre_r0 = vec3(_250[0].x, _250[1].x, _250[2].x);\n    fa_pre_r1 = vec3(_250[0].y, _250[1].y, _250[2].y);\n    fa_pre_r2 = vec3(_250[0].z, _250[1].z, _250[2].z);\n    gl_Position = mat4(fa_mesh_vs_params[0], fa_mesh_vs_params[1], fa_mesh_vs_params[2], fa_mesh_vs_params[3]) * _257;\n    fa_vel_cur = vec3(0.0, 0.0, 1.0);\n    fa_vel_prev = vec3(0.0);\n    if (_231)\n    {\n        vec4 _330 = vec4(position, 1.0);\n        fa_vel_cur = vec3((mat4(fa_vel_params[0], fa_vel_params[1], fa_vel_params[2], fa_vel_params[3]) * _257).xyw);\n        fa_vel_prev = vec3((mat4(fa_vel_params[4], fa_vel_params[5], fa_vel_params[6], fa_vel_params[7]) * vec4((_458 + (fa_prev_model() * _330).xyz) - (model * _330).xyz, 1.0)).xyw);\n    }\n}\n\nvoid main()\n{\n    fa_vtime = vec4(0.0);\n    fa_inst_begin();\n    mat4 param = mat4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3);\n    vec3 param_1 = fa_position;\n    vec3 param_2 = fa_normal;\n    vec4 param_3 = fa_tangent;\n    vec2 param_4 = fa_texcoord0;\n    vec4 param_5 = fa_color;\n    bool param_6 = true;\n    fa_prepass_vertex(param, param_1, param_2, param_3, param_4, param_5, param_6);\n}\n\n",
      "fs": "#version 430\n\nstruct SurfaceInput\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 vertex_color;\n    vec3 view_dir;\n    bool front_facing;\n};\n\nstruct Surface\n{\n    vec3 albedo;\n    float alpha;\n    vec3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    vec3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    vec3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    vec3 specular_color;\n    float transmission;\n    float thickness;\n    vec3 attenuation_color;\n    float attenuation_distance;\n};\n\nuniform vec4 fa_mesh_fs_params[53];\nlayout(binding = 0) uniform sampler2D fa_tex_fa_smp;\nlayout(binding = 1) uniform sampler2D fa_normal_tex_fa_smp;\nlayout(binding = 2) uniform sampler2D fa_mr_tex_fa_smp;\nlayout(binding = 3) uniform sampler2D fa_occlusion_tex_fa_smp;\nlayout(binding = 4) uniform sampler2D fa_emissive_tex_fa_smp;\n\nlayout(location = 0) in vec3 fa_world_pos;\nlayout(location = 1) in vec3 fa_world_normal;\nlayout(location = 2) in vec4 fa_world_tangent;\nlayout(location = 3) in vec2 fa_uv;\nlayout(location = 4) in vec4 fa_vertex_color;\nlayout(location = 6) in vec3 fa_pre_r0;\nlayout(location = 7) in vec3 fa_pre_r1;\nlayout(location = 8) in vec3 fa_pre_r2;\nlayout(location = 0) out vec4 fa_frag_color;\nlayout(location = 5) in float fa_pre_depth;\nlayout(location = 9) in vec3 fa_vel_cur;\nlayout(location = 10) in vec3 fa_vel_prev;\nlayout(location = 1) out vec2 fa_frag_velocity;\n\nvoid fa_inst_load()\n{\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nvec3 fa_linear_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_tex_fix(inout vec3 c, float mode)\n{\n    if (mode > 1.5)\n    {\n        vec3 param = c;\n        vec3 _172 = fa_linear_to_srgb(param);\n        c = _172;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            vec3 param_1 = c;\n            vec3 _181 = fa_srgb_to_linear(param_1);\n            c = _181;\n        }\n    }\n    return c;\n}\n\nvec3 fa_tangent_normal(SurfaceInput i, vec3 m)\n{\n    vec3 _56;\n    if (i.front_facing)\n    {\n        _56 = i.world_normal;\n    }\n    else\n    {\n        _56 = -i.world_normal;\n    }\n    vec3 _81 = normalize(i.world_tangent.xyz - (_56 * dot(_56, i.world_tangent.xyz)));\n    vec3 _109 = normalize(((_81 * m.x) + ((cross(_56, _81) * i.world_tangent.w) * m.y)) + (_56 * m.z));\n    vec3 _112;\n    if (i.front_facing)\n    {\n        _112 = _109;\n    }\n    else\n    {\n        _112 = -_109;\n    }\n    return _112;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    vec4 base_t = texture(fa_tex_fa_smp, i.uv, fa_mesh_fs_params[12].w);\n    float param = fa_mesh_fs_params[6].w;\n    float param_1 = 1.0;\n    vec3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    vec3 _230 = fa_tex_fix(param_2, param_3);\n    vec4 _892 = base_t;\n    _892.x = _230.x;\n    _892.y = _230.y;\n    _892.z = _230.z;\n    base_t = _892;\n    vec4 _246 = (_892 * fa_mesh_fs_params[2]) * i.vertex_color;\n    vec3 _847 = i.world_normal;\n    if (fa_mesh_fs_params[6].z > 0.5)\n    {\n        float param_4 = fa_mesh_fs_params[6].w;\n        float param_5 = 16.0;\n        vec3 param_6 = texture(fa_normal_tex_fa_smp, i.uv, fa_mesh_fs_params[12].w).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        vec3 _282 = fa_tex_fix(param_6, param_7);\n        vec3 _286 = (_282 * 2.0) - vec3(1.0);\n        vec2 _291 = _286.xy * fa_mesh_fs_params[6].x;\n        vec3 _900 = _286;\n        _900.x = _291.x;\n        _900.y = _291.y;\n        SurfaceInput param_8 = i;\n        vec3 param_9 = _900;\n        _847 = fa_tangent_normal(param_8, param_9);\n    }\n    vec4 mrt = texture(fa_mr_tex_fa_smp, i.uv, fa_mesh_fs_params[12].w);\n    float param_10 = fa_mesh_fs_params[6].w;\n    float param_11 = 64.0;\n    vec3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    vec3 _322 = fa_tex_fix(param_12, param_13);\n    vec4 _903 = mrt;\n    _903.x = _322.x;\n    _903.y = _322.y;\n    _903.z = _322.z;\n    mrt = _903;\n    vec4 _354 = texture(fa_occlusion_tex_fa_smp, i.uv, fa_mesh_fs_params[12].w);\n    float param_14 = fa_mesh_fs_params[6].w;\n    float param_15 = 256.0;\n    vec3 param_16 = _354.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    vec3 _366 = fa_tex_fix(param_16, param_17);\n    float param_18 = fa_mesh_fs_params[6].w;\n    float param_19 = 4.0;\n    vec3 param_20 = texture(fa_emissive_tex_fa_smp, i.uv, fa_mesh_fs_params[12].w).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    vec3 _398 = fa_tex_fix(param_20, param_21);\n    float _852 = fa_mesh_fs_params[20].x;\n    float _853 = fa_mesh_fs_params[20].y;\n    float _856 = fa_mesh_fs_params[20].z;\n    float _855 = fa_mesh_fs_params[21].w;\n    float _858 = fa_mesh_fs_params[22].x;\n    if (fa_mesh_fs_params[22].z > 0.5)\n    {\n        if (mod(fa_mesh_fs_params[22].z, 2.0) > 0.5)\n        {\n            _852 *= _366.y;\n            _853 *= _366.z;\n            _855 *= _354.w;\n        }\n        if (fa_mesh_fs_params[22].z > 1.5)\n        {\n            _856 *= mrt.x;\n            _858 *= mrt.w;\n        }\n    }\n    return Surface(_246.xyz, _246.w, _847, clamp(fa_mesh_fs_params[5].x * _322.z, 0.0, 1.0), clamp(fa_mesh_fs_params[5].y * _322.y, 0.0500000007450580596923828125, 1.0), 1.0 + (fa_mesh_fs_params[6].y * (_366.x - 1.0)), fa_mesh_fs_params[3].xyz + (fa_mesh_fs_params[4].xyz * _398), _852, _853, fa_mesh_fs_params[21].xyz, _855, _856, fa_mesh_fs_params[20].w, _858, fa_mesh_fs_params[22].y, fa_mesh_fs_params[23].xyz, fa_mesh_fs_params[30].x, fa_mesh_fs_params[30].y, fa_mesh_fs_params[31].xyz, fa_mesh_fs_params[30].z);\n}\n\nvoid surface(SurfaceInput i, Surface s)\n{\n}\n\nvoid main()\n{\n    fa_inst_load();\n    vec3 _742 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _742 = -_742;\n    }\n    vec3 _550 = normalize(fa_mesh_fs_params[0].xyz - fa_world_pos);\n    SurfaceInput param = SurfaceInput(fa_world_pos, _742, fa_world_tangent, fa_uv, fa_vertex_color, _550, gl_FrontFacing);\n    SurfaceInput param_1 = SurfaceInput(fa_world_pos, _742, fa_world_tangent, fa_uv, fa_vertex_color, _550, gl_FrontFacing);\n    Surface param_2 = fa_standard_surface(param);\n    surface(param_1, param_2);\n    vec3 _565 = normalize(param_2.normal);\n    vec3 _580 = normalize(vec3(dot(fa_pre_r0, _565), dot(fa_pre_r1, _565), dot(fa_pre_r2, _565)));\n    float _592 = _580.z;\n    vec2 e = _580.xy / vec2((abs(_580.x) + abs(_580.y)) + abs(_592));\n    if (_592 < 0.0)\n    {\n        e = (vec2(1.0) - abs(e.yx)) * vec2((e.x >= 0.0) ? 1.0 : (-1.0), (e.y >= 0.0) ? 1.0 : (-1.0));\n    }\n    fa_frag_color = vec4(min(fa_pre_depth, 60000.0), e, 1.0);\n    vec2 motion = vec2(1024.0);\n    bool _636 = fa_vel_cur.z > 9.9999997473787516355514526367188e-06;\n    bool _643;\n    if (_636)\n    {\n        _643 = fa_vel_prev.z > 9.9999997473787516355514526367188e-06;\n    }\n    else\n    {\n        _643 = _636;\n    }\n    if (_643)\n    {\n        motion = clamp(((vec2(fa_vel_prev.x, -fa_vel_prev.y) / vec2(fa_vel_prev.z)) * 0.5) - ((vec2(fa_vel_cur.x, -fa_vel_cur.y) / vec2(fa_vel_cur.z)) * 0.5), vec2(-4.0), vec2(4.0));\n    }\n    fa_frag_velocity = motion;\n}\n\n",
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
            "glsl_name": "fa_prev_r0"
          },
          {
            "slot": 10,
            "type": "vec4",
            "base_type": "Float",
            "glsl_name": "fa_prev_r1"
          },
          {
            "slot": 11,
            "type": "vec4",
            "base_type": "Float",
            "glsl_name": "fa_prev_r2"
          }
        ],
        "uniform_blocks": [
          {
            "slot": 0,
            "stage": "vertex",
            "size": 176,
            "struct_name": "fa_mesh_vs_params",
            "inst_name": "_57",
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
            "inst_name": "_225",
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
            "slot": 1,
            "stage": "fragment",
            "size": 848,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_214",
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
      "vs": "#version 430\n\nstruct VertexData\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 color;\n    vec3 object_pos;\n};\n\nuniform vec4 fa_mesh_vs_params[11];\nuniform vec4 fa_skin[192];\nuniform vec4 fa_vel_params[9];\nlayout(binding = 0) uniform sampler2D fa_prev_pal_tex_fa_prev_pal_smp;\n\nlayout(location = 0) out vec3 fa_world_pos;\nlayout(location = 1) out vec3 fa_world_normal;\nlayout(location = 2) out vec4 fa_world_tangent;\nlayout(location = 3) out vec2 fa_uv;\nlayout(location = 4) out vec4 fa_vertex_color;\nlayout(location = 5) out float fa_pre_depth;\nlayout(location = 6) out vec3 fa_pre_r0;\nlayout(location = 7) out vec3 fa_pre_r1;\nlayout(location = 8) out vec3 fa_pre_r2;\nlayout(location = 9) out vec3 fa_vel_cur;\nlayout(location = 10) out vec3 fa_vel_prev;\nlayout(location = 11) in vec4 fa_prev_r0;\nlayout(location = 12) in vec4 fa_prev_r1;\nlayout(location = 13) in vec4 fa_prev_r2;\nlayout(location = 9) in vec4 fa_joints;\nlayout(location = 10) in vec4 fa_weights;\nlayout(location = 5) in vec4 fa_inst_m0;\nlayout(location = 6) in vec4 fa_inst_m1;\nlayout(location = 7) in vec4 fa_inst_m2;\nlayout(location = 8) in vec4 fa_inst_m3;\nlayout(location = 0) in vec3 fa_position;\nlayout(location = 1) in vec3 fa_normal;\nlayout(location = 3) in vec4 fa_tangent;\nlayout(location = 2) in vec2 fa_texcoord0;\nlayout(location = 4) in vec4 fa_color;\nvec4 fa_vtime;\n\nvoid fa_inst_begin()\n{\n}\n\nmat4 fa_skin_matrix(vec4 joints, vec4 weights)\n{\n    vec4 r0 = vec4(0.0);\n    vec4 r1 = vec4(0.0);\n    vec4 r2 = vec4(0.0);\n    for (int i = 0; i < 4; i++)\n    {\n        int _204 = int((joints[i] * 255.0) + 0.5) * 3;\n        r0 += (fa_skin[_204 * 1 + 0] * weights[i]);\n        r1 += (fa_skin[(_204 + 1) * 1 + 0] * weights[i]);\n        r2 += (fa_skin[(_204 + 2) * 1 + 0] * weights[i]);\n    }\n    return mat4(vec4(r0.x, r1.x, r2.x, 0.0), vec4(r0.y, r1.y, r2.y, 0.0), vec4(r0.z, r1.z, r2.z, 0.0), vec4(r0.w, r1.w, r2.w, 1.0));\n}\n\nvec4 fa_time_now()\n{\n    return fa_mesh_vs_params[9];\n}\n\nVertexData fa_vertex_data(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    vec3 _113 = cross(model[1].xyz, model[2].xyz);\n    float _117 = (dot(model[0].xyz, _113) < 0.0) ? (-1.0) : 1.0;\n    return VertexData((model * vec4(position, 1.0)).xyz, (((_113 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _117, vec4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _117), texcoord0 * fa_mesh_vs_params[8].xy, color, position);\n}\n\nmat4 fa_rows_to_mat4(vec4 r0, vec4 r1, vec4 r2)\n{\n    return mat4(vec4(r0.x, r1.x, r2.x, 0.0), vec4(r0.y, r1.y, r2.y, 0.0), vec4(r0.z, r1.z, r2.z, 0.0), vec4(r0.w, r1.w, r2.w, 1.0));\n}\n\nvec4 fa_prev_pal_texel(int t)\n{\n    return texelFetch(fa_prev_pal_tex_fa_prev_pal_smp, ivec2(t & 1023, t >> 10), 0);\n}\n\nmat4 fa_prev_skin_matrix(vec4 joints, vec4 weights, int base)\n{\n    vec4 r0 = vec4(0.0);\n    vec4 r1 = vec4(0.0);\n    vec4 r2 = vec4(0.0);\n    for (int i = 0; i < 4; i++)\n    {\n        int _332 = base + (int((joints[i] * 255.0) + 0.5) * 3);\n        int param = _332;\n        r0 += (fa_prev_pal_texel(param) * weights[i]);\n        int param_1 = _332 + 1;\n        r1 += (fa_prev_pal_texel(param_1) * weights[i]);\n        int param_2 = _332 + 2;\n        r2 += (fa_prev_pal_texel(param_2) * weights[i]);\n    }\n    return mat4(vec4(r0.x, r1.x, r2.x, 0.0), vec4(r0.y, r1.y, r2.y, 0.0), vec4(r0.z, r1.z, r2.z, 0.0), vec4(r0.w, r1.w, r2.w, 1.0));\n}\n\nmat4 fa_prev_model()\n{\n    vec4 param = fa_prev_r0;\n    vec4 param_1 = fa_prev_r1;\n    vec4 param_2 = fa_prev_r2;\n    vec4 param_3 = fa_joints;\n    vec4 param_4 = fa_weights;\n    int param_5 = int(fa_vel_params[8].w + 0.5);\n    return fa_rows_to_mat4(param, param_1, param_2) * fa_prev_skin_matrix(param_3, param_4, param_5);\n}\n\nvoid fa_prepass_vertex(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color, bool has_prev)\n{\n    bool _475;\n    if (has_prev)\n    {\n        _475 = fa_vel_params[8].x > 0.5;\n    }\n    else\n    {\n        _475 = has_prev;\n    }\n    fa_vtime = fa_time_now();\n    mat4 param = model;\n    vec3 param_1 = position;\n    vec3 param_2 = normal;\n    vec4 param_3 = tangent;\n    vec2 param_4 = texcoord0;\n    vec4 param_5 = color;\n    VertexData _490 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    vec3 _723 = _490.world_pos;\n    mat4 _494 = mat4(fa_mesh_vs_params[4], fa_mesh_vs_params[5], fa_mesh_vs_params[6], fa_mesh_vs_params[7]);\n    vec4 _501 = vec4(_723, 1.0);\n    fa_world_pos = _723;\n    fa_world_normal = _490.world_normal;\n    fa_world_tangent = _490.world_tangent;\n    fa_uv = _490.uv;\n    fa_vertex_color = _490.color;\n    fa_pre_depth = -(_494 * _501).z;\n    fa_pre_r0 = vec3(_494[0].x, _494[1].x, _494[2].x);\n    fa_pre_r1 = vec3(_494[0].y, _494[1].y, _494[2].y);\n    fa_pre_r2 = vec3(_494[0].z, _494[1].z, _494[2].z);\n    gl_Position = mat4(fa_mesh_vs_params[0], fa_mesh_vs_params[1], fa_mesh_vs_params[2], fa_mesh_vs_params[3]) * _501;\n    fa_vel_cur = vec3(0.0, 0.0, 1.0);\n    fa_vel_prev = vec3(0.0);\n    if (_475)\n    {\n        vec4 _574 = vec4(position, 1.0);\n        fa_vel_cur = vec3((mat4(fa_vel_params[0], fa_vel_params[1], fa_vel_params[2], fa_vel_params[3]) * _501).xyw);\n        fa_vel_prev = vec3((mat4(fa_vel_params[4], fa_vel_params[5], fa_vel_params[6], fa_vel_params[7]) * vec4((_723 + (fa_prev_model() * _574).xyz) - (model * _574).xyz, 1.0)).xyw);\n    }\n}\n\nvoid main()\n{\n    fa_vtime = vec4(0.0);\n    fa_inst_begin();\n    vec4 param = fa_joints;\n    vec4 param_1 = fa_weights;\n    mat4 param_2 = mat4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3) * fa_skin_matrix(param, param_1);\n    vec3 param_3 = fa_position;\n    vec3 param_4 = fa_normal;\n    vec4 param_5 = fa_tangent;\n    vec2 param_6 = fa_texcoord0;\n    vec4 param_7 = fa_color;\n    bool param_8 = fa_vel_params[8].z > 0.5;\n    fa_prepass_vertex(param_2, param_3, param_4, param_5, param_6, param_7, param_8);\n}\n\n",
      "fs": "#version 430\n\nstruct SurfaceInput\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 vertex_color;\n    vec3 view_dir;\n    bool front_facing;\n};\n\nstruct Surface\n{\n    vec3 albedo;\n    float alpha;\n    vec3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    vec3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    vec3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    vec3 specular_color;\n    float transmission;\n    float thickness;\n    vec3 attenuation_color;\n    float attenuation_distance;\n};\n\nuniform vec4 fa_mesh_fs_params[53];\nlayout(binding = 0) uniform sampler2D fa_tex_fa_smp;\nlayout(binding = 1) uniform sampler2D fa_normal_tex_fa_smp;\nlayout(binding = 2) uniform sampler2D fa_mr_tex_fa_smp;\nlayout(binding = 3) uniform sampler2D fa_occlusion_tex_fa_smp;\nlayout(binding = 4) uniform sampler2D fa_emissive_tex_fa_smp;\n\nlayout(location = 0) in vec3 fa_world_pos;\nlayout(location = 1) in vec3 fa_world_normal;\nlayout(location = 2) in vec4 fa_world_tangent;\nlayout(location = 3) in vec2 fa_uv;\nlayout(location = 4) in vec4 fa_vertex_color;\nlayout(location = 6) in vec3 fa_pre_r0;\nlayout(location = 7) in vec3 fa_pre_r1;\nlayout(location = 8) in vec3 fa_pre_r2;\nlayout(location = 0) out vec4 fa_frag_color;\nlayout(location = 5) in float fa_pre_depth;\nlayout(location = 9) in vec3 fa_vel_cur;\nlayout(location = 10) in vec3 fa_vel_prev;\nlayout(location = 1) out vec2 fa_frag_velocity;\n\nvoid fa_inst_load()\n{\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nvec3 fa_linear_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_tex_fix(inout vec3 c, float mode)\n{\n    if (mode > 1.5)\n    {\n        vec3 param = c;\n        vec3 _172 = fa_linear_to_srgb(param);\n        c = _172;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            vec3 param_1 = c;\n            vec3 _181 = fa_srgb_to_linear(param_1);\n            c = _181;\n        }\n    }\n    return c;\n}\n\nvec3 fa_tangent_normal(SurfaceInput i, vec3 m)\n{\n    vec3 _56;\n    if (i.front_facing)\n    {\n        _56 = i.world_normal;\n    }\n    else\n    {\n        _56 = -i.world_normal;\n    }\n    vec3 _81 = normalize(i.world_tangent.xyz - (_56 * dot(_56, i.world_tangent.xyz)));\n    vec3 _109 = normalize(((_81 * m.x) + ((cross(_56, _81) * i.world_tangent.w) * m.y)) + (_56 * m.z));\n    vec3 _112;\n    if (i.front_facing)\n    {\n        _112 = _109;\n    }\n    else\n    {\n        _112 = -_109;\n    }\n    return _112;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    vec4 base_t = texture(fa_tex_fa_smp, i.uv, fa_mesh_fs_params[12].w);\n    float param = fa_mesh_fs_params[6].w;\n    float param_1 = 1.0;\n    vec3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    vec3 _230 = fa_tex_fix(param_2, param_3);\n    vec4 _892 = base_t;\n    _892.x = _230.x;\n    _892.y = _230.y;\n    _892.z = _230.z;\n    base_t = _892;\n    vec4 _246 = (_892 * fa_mesh_fs_params[2]) * i.vertex_color;\n    vec3 _847 = i.world_normal;\n    if (fa_mesh_fs_params[6].z > 0.5)\n    {\n        float param_4 = fa_mesh_fs_params[6].w;\n        float param_5 = 16.0;\n        vec3 param_6 = texture(fa_normal_tex_fa_smp, i.uv, fa_mesh_fs_params[12].w).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        vec3 _282 = fa_tex_fix(param_6, param_7);\n        vec3 _286 = (_282 * 2.0) - vec3(1.0);\n        vec2 _291 = _286.xy * fa_mesh_fs_params[6].x;\n        vec3 _900 = _286;\n        _900.x = _291.x;\n        _900.y = _291.y;\n        SurfaceInput param_8 = i;\n        vec3 param_9 = _900;\n        _847 = fa_tangent_normal(param_8, param_9);\n    }\n    vec4 mrt = texture(fa_mr_tex_fa_smp, i.uv, fa_mesh_fs_params[12].w);\n    float param_10 = fa_mesh_fs_params[6].w;\n    float param_11 = 64.0;\n    vec3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    vec3 _322 = fa_tex_fix(param_12, param_13);\n    vec4 _903 = mrt;\n    _903.x = _322.x;\n    _903.y = _322.y;\n    _903.z = _322.z;\n    mrt = _903;\n    vec4 _354 = texture(fa_occlusion_tex_fa_smp, i.uv, fa_mesh_fs_params[12].w);\n    float param_14 = fa_mesh_fs_params[6].w;\n    float param_15 = 256.0;\n    vec3 param_16 = _354.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    vec3 _366 = fa_tex_fix(param_16, param_17);\n    float param_18 = fa_mesh_fs_params[6].w;\n    float param_19 = 4.0;\n    vec3 param_20 = texture(fa_emissive_tex_fa_smp, i.uv, fa_mesh_fs_params[12].w).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    vec3 _398 = fa_tex_fix(param_20, param_21);\n    float _852 = fa_mesh_fs_params[20].x;\n    float _853 = fa_mesh_fs_params[20].y;\n    float _856 = fa_mesh_fs_params[20].z;\n    float _855 = fa_mesh_fs_params[21].w;\n    float _858 = fa_mesh_fs_params[22].x;\n    if (fa_mesh_fs_params[22].z > 0.5)\n    {\n        if (mod(fa_mesh_fs_params[22].z, 2.0) > 0.5)\n        {\n            _852 *= _366.y;\n            _853 *= _366.z;\n            _855 *= _354.w;\n        }\n        if (fa_mesh_fs_params[22].z > 1.5)\n        {\n            _856 *= mrt.x;\n            _858 *= mrt.w;\n        }\n    }\n    return Surface(_246.xyz, _246.w, _847, clamp(fa_mesh_fs_params[5].x * _322.z, 0.0, 1.0), clamp(fa_mesh_fs_params[5].y * _322.y, 0.0500000007450580596923828125, 1.0), 1.0 + (fa_mesh_fs_params[6].y * (_366.x - 1.0)), fa_mesh_fs_params[3].xyz + (fa_mesh_fs_params[4].xyz * _398), _852, _853, fa_mesh_fs_params[21].xyz, _855, _856, fa_mesh_fs_params[20].w, _858, fa_mesh_fs_params[22].y, fa_mesh_fs_params[23].xyz, fa_mesh_fs_params[30].x, fa_mesh_fs_params[30].y, fa_mesh_fs_params[31].xyz, fa_mesh_fs_params[30].z);\n}\n\nvoid surface(SurfaceInput i, Surface s)\n{\n}\n\nvoid main()\n{\n    fa_inst_load();\n    vec3 _742 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _742 = -_742;\n    }\n    vec3 _550 = normalize(fa_mesh_fs_params[0].xyz - fa_world_pos);\n    SurfaceInput param = SurfaceInput(fa_world_pos, _742, fa_world_tangent, fa_uv, fa_vertex_color, _550, gl_FrontFacing);\n    SurfaceInput param_1 = SurfaceInput(fa_world_pos, _742, fa_world_tangent, fa_uv, fa_vertex_color, _550, gl_FrontFacing);\n    Surface param_2 = fa_standard_surface(param);\n    surface(param_1, param_2);\n    vec3 _565 = normalize(param_2.normal);\n    vec3 _580 = normalize(vec3(dot(fa_pre_r0, _565), dot(fa_pre_r1, _565), dot(fa_pre_r2, _565)));\n    float _592 = _580.z;\n    vec2 e = _580.xy / vec2((abs(_580.x) + abs(_580.y)) + abs(_592));\n    if (_592 < 0.0)\n    {\n        e = (vec2(1.0) - abs(e.yx)) * vec2((e.x >= 0.0) ? 1.0 : (-1.0), (e.y >= 0.0) ? 1.0 : (-1.0));\n    }\n    fa_frag_color = vec4(min(fa_pre_depth, 60000.0), e, 1.0);\n    vec2 motion = vec2(1024.0);\n    bool _636 = fa_vel_cur.z > 9.9999997473787516355514526367188e-06;\n    bool _643;\n    if (_636)\n    {\n        _643 = fa_vel_prev.z > 9.9999997473787516355514526367188e-06;\n    }\n    else\n    {\n        _643 = _636;\n    }\n    if (_643)\n    {\n        motion = clamp(((vec2(fa_vel_prev.x, -fa_vel_prev.y) / vec2(fa_vel_prev.z)) * 0.5) - ((vec2(fa_vel_cur.x, -fa_vel_cur.y) / vec2(fa_vel_cur.z)) * 0.5), vec2(-4.0), vec2(4.0));\n    }\n    fa_frag_velocity = motion;\n}\n\n",
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
            "glsl_name": "fa_prev_r0"
          },
          {
            "slot": 12,
            "type": "vec4",
            "base_type": "Float",
            "glsl_name": "fa_prev_r1"
          },
          {
            "slot": 13,
            "type": "vec4",
            "base_type": "Float",
            "glsl_name": "fa_prev_r2"
          }
        ],
        "uniform_blocks": [
          {
            "slot": 0,
            "stage": "vertex",
            "size": 176,
            "struct_name": "fa_mesh_vs_params",
            "inst_name": "_74",
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
            "inst_name": "_213",
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
            "inst_name": "_470",
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
            "slot": 1,
            "stage": "fragment",
            "size": 848,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_214",
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
            "texture": {
              "slot": 29,
              "stage": "vertex",
              "name": "fa_prev_pal_tex",
              "multisampled": false,
              "type": "2d",
              "sample_type": "unfilterable_float"
            }
          }
        ],
        "samplers": [
          {
            "slot": 11,
            "stage": "vertex",
            "name": "fa_prev_pal_smp",
            "sampler_type": "nonfiltering"
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
            "stage": "vertex",
            "name": "fa_prev_pal_tex_fa_prev_pal_smp",
            "view_name": "fa_prev_pal_tex",
            "sampler_name": "fa_prev_pal_smp",
            "view_slot": 29,
            "sampler_slot": 11,
            "glsl_name": "fa_prev_pal_tex_fa_prev_pal_smp"
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
          }
        ]
      }
    }
  }
}
