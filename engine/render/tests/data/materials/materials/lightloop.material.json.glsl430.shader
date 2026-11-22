{
  "format": "factoria.shader/1",
  "engine": "0.34.0",
  "template": "d5ad4ba00a2086cd5c3d6440d2be629e3ce9b0f8ede644c9a19112677c2fea28",
  "slang": "glsl430",
  "params": [
    "dark",
    "skyAmount"
  ],
  "textures": [],
  "programs": {
    "mesh": {
      "vs": "#version 430\n\nstruct VertexData\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 color;\n    vec3 object_pos;\n};\n\nuniform vec4 fa_mesh_vs_params[11];\nlayout(location = 0) out vec3 fa_world_pos;\nlayout(location = 1) out vec3 fa_world_normal;\nlayout(location = 2) out vec4 fa_world_tangent;\nlayout(location = 3) out vec2 fa_uv;\nlayout(location = 4) out vec4 fa_vertex_color;\nlayout(location = 5) in vec4 fa_inst_m0;\nlayout(location = 6) in vec4 fa_inst_m1;\nlayout(location = 7) in vec4 fa_inst_m2;\nlayout(location = 8) in vec4 fa_inst_m3;\nlayout(location = 0) in vec3 fa_position;\nlayout(location = 1) in vec3 fa_normal;\nlayout(location = 3) in vec4 fa_tangent;\nlayout(location = 2) in vec2 fa_texcoord0;\nlayout(location = 4) in vec4 fa_color;\nlayout(location = 5) out vec3 fa_lm;\n\nvoid fa_inst_begin()\n{\n}\n\nVertexData fa_vertex_data(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    vec3 _69 = cross(model[1].xyz, model[2].xyz);\n    float _75 = (dot(model[0].xyz, _69) < 0.0) ? (-1.0) : 1.0;\n    return VertexData((model * vec4(position, 1.0)).xyz, (((_69 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _75, vec4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _75), texcoord0 * fa_mesh_vs_params[8].xy, color, position);\n}\n\nvoid fa_shade_vertex(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    mat4 param = model;\n    vec3 param_1 = position;\n    vec3 param_2 = normal;\n    vec4 param_3 = tangent;\n    vec2 param_4 = texcoord0;\n    vec4 param_5 = color;\n    VertexData _160 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    vec3 _270 = _160.world_pos;\n    fa_world_pos = _270;\n    fa_world_normal = _160.world_normal;\n    fa_world_tangent = _160.world_tangent;\n    fa_uv = _160.uv;\n    fa_vertex_color = _160.color;\n    gl_Position = mat4(fa_mesh_vs_params[0], fa_mesh_vs_params[1], fa_mesh_vs_params[2], fa_mesh_vs_params[3]) * vec4(_270, 1.0);\n}\n\nvoid main()\n{\n    fa_inst_begin();\n    mat4 param = mat4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3);\n    vec3 param_1 = fa_position;\n    vec3 param_2 = fa_normal;\n    vec4 param_3 = fa_tangent;\n    vec2 param_4 = fa_texcoord0;\n    vec4 param_5 = fa_color;\n    fa_shade_vertex(param, param_1, param_2, param_3, param_4, param_5);\n    fa_lm = vec3(0.0);\n}\n\n",
      "fs": "#version 430\n\nstruct SurfaceInput\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 vertex_color;\n    vec3 view_dir;\n    bool front_facing;\n};\n\nstruct LightSample\n{\n    vec3 direction;\n    vec3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct Surface\n{\n    vec3 albedo;\n    float alpha;\n    vec3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    vec3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    vec3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    vec3 specular_color;\n    float transmission;\n    float thickness;\n    vec3 attenuation_color;\n    float attenuation_distance;\n};\n\nstruct FaLayers\n{\n    bool on;\n    float f90;\n    float keep;\n    float base_scale;\n    float coat;\n    float coat_rough;\n    float coat_alpha;\n    float coat_a2;\n    vec3 nc;\n    float coat_ndv;\n    bool sheen_on;\n    vec3 sheen;\n    float sheen_rough;\n    float sheen_alpha;\n    float sheen_scale;\n    float sheen_e;\n    float aniso;\n    vec3 t;\n    vec3 b;\n    float at;\n    float ab;\n};\n\nconst float _3924[63] = float[](1.0, 1.0, 1.0, 0.4790000021457672119140625, 0.11699999868869781494140625, 0.01200000010430812835693359375, 0.0, 0.0, 0.0, 1.0, 1.0, 1.0, 0.578000009059906005859375, 0.19300000369548797607421875, 0.0350000001490116119384765625, 0.0030000000260770320892333984375, 0.0, 0.0, 1.0, 1.0, 1.0, 0.6740000247955322265625, 0.3459999859333038330078125, 0.1319999992847442626953125, 0.032999999821186065673828125, 0.0040000001899898052215576171875, 0.0, 0.971000015735626220703125, 0.954999983310699462890625, 0.828999996185302734375, 0.63999998569488525390625, 0.42599999904632568359375, 0.24500000476837158203125, 0.115000002086162567138671875, 0.037000000476837158203125, 0.0030000000260770320892333984375, 0.7469999790191650390625, 0.737999975681304931640625, 0.670000016689300537109375, 0.563000023365020751953125, 0.4309999942779541015625, 0.3039999902248382568359375, 0.1940000057220458984375, 0.1019999980926513671875, 0.0309999994933605194091796875, 0.614000022411346435546875, 0.609000027179718017578125, 0.566999971866607666015625, 0.499000012874603271484375, 0.412000000476837158203125, 0.32400000095367431640625, 0.240999996662139892578125, 0.162000000476837158203125, 0.087999999523162841796875, 0.538999974727630615234375, 0.535000026226043701171875, 0.505999982357025146484375, 0.4569999873638153076171875, 0.393999993801116943359375, 0.328999996185302734375, 0.2660000026226043701171875, 0.203999996185302734375, 0.14200000464916229248046875);\n\nuniform vec4 fa_mesh_fs_params[53];\nuniform vec4 fa_shadows[30];\nuniform vec4 fa_material[2];\nlayout(binding = 0) uniform sampler2D fa_light_tex_fa_shadow_smp;\nlayout(binding = 1) uniform sampler2D fa_tex_fa_smp;\nlayout(binding = 2) uniform sampler2D fa_normal_tex_fa_smp;\nlayout(binding = 3) uniform sampler2D fa_mr_tex_fa_smp;\nlayout(binding = 4) uniform sampler2D fa_occlusion_tex_fa_smp;\nlayout(binding = 5) uniform sampler2D fa_emissive_tex_fa_smp;\nlayout(binding = 6) uniform sampler2D fa_decal_tex_fa_env_smp;\nlayout(binding = 7) uniform sampler2D fa_light_atlas_fa_env_smp;\nlayout(binding = 8) uniform sampler2D fa_shadow_tex_fa_shadow_smp;\nlayout(binding = 9) uniform sampler2D fa_screen_tex_fa_shadow_smp;\nlayout(binding = 10) uniform sampler2D fa_probe_atlas_fa_env_smp;\n\nlayout(location = 0) in vec3 fa_world_pos;\nlayout(location = 5) in vec3 fa_lm;\nlayout(location = 1) in vec3 fa_world_normal;\nlayout(location = 2) in vec4 fa_world_tangent;\nlayout(location = 3) in vec2 fa_uv;\nlayout(location = 4) in vec4 fa_vertex_color;\nlayout(location = 0) out vec4 fa_frag_color;\nvec3 fa_light_tint;\nbool fa_light_is_area;\nint fa_cl_ndir;\nint fa_cl_slot;\nint fa_cl_local;\n\nvoid fa_inst_load()\n{\n}\n\nvec4 fa_light_texel(int t)\n{\n    return texelFetch(fa_light_tex_fa_shadow_smp, ivec2(t & 1023, t >> 10), 0);\n}\n\nvec4 fa_cluster_texel(vec3 world_pos)\n{\n    bool _1437 = fa_mesh_fs_params[19].x < 0.0;\n    bool _1444;\n    if (!_1437)\n    {\n        _1444 = fa_mesh_fs_params[19].w < 1.0;\n    }\n    else\n    {\n        _1444 = _1437;\n    }\n    bool _1452;\n    if (!_1444)\n    {\n        _1452 = fa_mesh_fs_params[18].x < 1.0;\n    }\n    else\n    {\n        _1452 = _1444;\n    }\n    bool _1459;\n    if (!_1452)\n    {\n        _1459 = fa_mesh_fs_params[18].y < 1.0;\n    }\n    else\n    {\n        _1459 = _1452;\n    }\n    bool _1466;\n    if (!_1459)\n    {\n        _1466 = fa_mesh_fs_params[19].y < 1.0;\n    }\n    else\n    {\n        _1466 = _1459;\n    }\n    if (_1466)\n    {\n        return vec4(0.0);\n    }\n    vec4 _1476 = vec4(world_pos, 1.0);\n    float _1482 = dot(fa_mesh_fs_params[16], _1476);\n    if (!(_1482 > 9.9999999747524270787835121154785e-07))\n    {\n        return vec4(0.0);\n    }\n    vec2 _1504 = vec2(dot(fa_mesh_fs_params[14], _1476), dot(fa_mesh_fs_params[15], _1476)) / vec2(_1482);\n    int _1508 = int(fa_mesh_fs_params[18].x);\n    int _1512 = int(fa_mesh_fs_params[18].y);\n    int param = (int(fa_mesh_fs_params[19].x) + (((clamp(int(floor(log2(max(dot(fa_mesh_fs_params[17].xyz, world_pos) + fa_mesh_fs_params[17].w, fa_mesh_fs_params[18].w) / fa_mesh_fs_params[18].w) * fa_mesh_fs_params[18].z)), 0, int(fa_mesh_fs_params[19].y) - 1) * _1512) + clamp(int(floor(((_1504.y * 0.5) + 0.5) * fa_mesh_fs_params[18].y)), 0, _1512 - 1)) * _1508)) + clamp(int(floor(((_1504.x * 0.5) + 0.5) * fa_mesh_fs_params[18].x)), 0, _1508 - 1);\n    return fa_light_texel(param);\n}\n\nivec2 fa_cluster_lookup(vec3 world_pos)\n{\n    vec3 param = world_pos;\n    vec4 _1588 = fa_cluster_texel(param);\n    return ivec2(int(_1588.x), int(_1588.y));\n}\n\nvoid fa_cluster_begin(vec3 world_pos)\n{\n    fa_cl_ndir = int(fa_mesh_fs_params[19].z);\n    vec3 param = world_pos;\n    ivec2 _4758 = fa_cluster_lookup(param);\n    fa_cl_slot = _4758.x;\n    fa_cl_local = _4758.y;\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_linear_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvec3 fa_tex_fix(inout vec3 c, float mode)\n{\n    if (mode > 1.5)\n    {\n        vec3 param = c;\n        vec3 _5135 = fa_linear_to_srgb(param);\n        c = _5135;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            vec3 param_1 = c;\n            vec3 _5143 = fa_srgb_to_linear(param_1);\n            c = _5143;\n        }\n    }\n    return c;\n}\n\nvec3 fa_tangent_normal(SurfaceInput i, vec3 m)\n{\n    vec3 _350;\n    if (i.front_facing)\n    {\n        _350 = i.world_normal;\n    }\n    else\n    {\n        _350 = -i.world_normal;\n    }\n    vec3 _374 = normalize(i.world_tangent.xyz - (_350 * dot(_350, i.world_tangent.xyz)));\n    vec3 _402 = normalize(((_374 * m.x) + ((cross(_350, _374) * i.world_tangent.w) * m.y)) + (_350 * m.z));\n    vec3 _405;\n    if (i.front_facing)\n    {\n        _405 = _402;\n    }\n    else\n    {\n        _405 = -_402;\n    }\n    return _405;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    vec4 base_t = texture(fa_tex_fa_smp, i.uv);\n    float param = fa_mesh_fs_params[6].w;\n    float param_1 = 1.0;\n    vec3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    vec3 _5174 = fa_tex_fix(param_2, param_3);\n    vec4 _6314 = base_t;\n    _6314.x = _5174.x;\n    _6314.y = _5174.y;\n    _6314.z = _5174.z;\n    base_t = _6314;\n    vec4 _5188 = (_6314 * fa_mesh_fs_params[2]) * i.vertex_color;\n    vec3 _6120 = i.world_normal;\n    if (fa_mesh_fs_params[6].z > 0.5)\n    {\n        float param_4 = fa_mesh_fs_params[6].w;\n        float param_5 = 16.0;\n        vec3 param_6 = texture(fa_normal_tex_fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        vec3 _5220 = fa_tex_fix(param_6, param_7);\n        vec3 _5223 = (_5220 * 2.0) - vec3(1.0);\n        vec2 _5228 = _5223.xy * fa_mesh_fs_params[6].x;\n        vec3 _6322 = _5223;\n        _6322.x = _5228.x;\n        _6322.y = _5228.y;\n        SurfaceInput param_8 = i;\n        vec3 param_9 = _6322;\n        _6120 = fa_tangent_normal(param_8, param_9);\n    }\n    vec4 mrt = texture(fa_mr_tex_fa_smp, i.uv);\n    float param_10 = fa_mesh_fs_params[6].w;\n    float param_11 = 64.0;\n    vec3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    vec3 _5256 = fa_tex_fix(param_12, param_13);\n    vec4 _6325 = mrt;\n    _6325.x = _5256.x;\n    _6325.y = _5256.y;\n    _6325.z = _5256.z;\n    mrt = _6325;\n    vec4 _5284 = texture(fa_occlusion_tex_fa_smp, i.uv);\n    float param_14 = fa_mesh_fs_params[6].w;\n    float param_15 = 256.0;\n    vec3 param_16 = _5284.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    vec3 _5295 = fa_tex_fix(param_16, param_17);\n    float param_18 = fa_mesh_fs_params[6].w;\n    float param_19 = 4.0;\n    vec3 param_20 = texture(fa_emissive_tex_fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    vec3 _5325 = fa_tex_fix(param_20, param_21);\n    float _6125 = fa_mesh_fs_params[20].x;\n    float _6126 = fa_mesh_fs_params[20].y;\n    float _6129 = fa_mesh_fs_params[20].z;\n    float _6128 = fa_mesh_fs_params[21].w;\n    float _6131 = fa_mesh_fs_params[22].x;\n    if (fa_mesh_fs_params[22].z > 0.5)\n    {\n        if (mod(fa_mesh_fs_params[22].z, 2.0) > 0.5)\n        {\n            _6125 *= _5295.y;\n            _6126 *= _5295.z;\n            _6128 *= _5284.w;\n        }\n        if (fa_mesh_fs_params[22].z > 1.5)\n        {\n            _6129 *= mrt.x;\n            _6131 *= mrt.w;\n        }\n    }\n    return Surface(_5188.xyz, _5188.w, _6120, clamp(fa_mesh_fs_params[5].x * _5256.z, 0.0, 1.0), clamp(fa_mesh_fs_params[5].y * _5256.y, 0.0500000007450580596923828125, 1.0), 1.0 + (fa_mesh_fs_params[6].y * (_5295.x - 1.0)), fa_mesh_fs_params[3].xyz + (fa_mesh_fs_params[4].xyz * _5325), _6125, _6126, fa_mesh_fs_params[21].xyz, _6128, _6129, fa_mesh_fs_params[20].w, _6131, fa_mesh_fs_params[22].y, fa_mesh_fs_params[23].xyz, fa_mesh_fs_params[30].x, fa_mesh_fs_params[30].y, fa_mesh_fs_params[31].xyz, fa_mesh_fs_params[30].z);\n}\n\nvoid surface(SurfaceInput i, Surface s)\n{\n}\n\nvec4 fa_decal_tile(vec4 rect, vec2 uv, vec2 atlas, vec2 ddx, vec2 ddy)\n{\n    vec2 _1668 = rect.zw - rect.xy;\n    vec2 _1672 = _1668 * atlas;\n    vec2 _1676 = ddx * _1672;\n    vec2 _1680 = ddy * _1672;\n    return textureLod(fa_decal_tex_fa_env_smp, rect.xy + (clamp(uv, vec2(0.0), vec2(1.0)) * _1668), clamp(0.5 * log2(max(max(dot(_1676, _1676), dot(_1680, _1680)), 9.9999999392252902907785028219223e-09)), 0.0, 3.0));\n}\n\nvec3 fa_dc_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_dc_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvoid fa_apply_decals(vec3 world_pos, vec3 geo_normal, inout vec3 albedo, inout vec3 normal)\n{\n    bool _1713 = fa_mesh_fs_params[10].y < 0.5;\n    bool _1720;\n    if (!_1713)\n    {\n        _1720 = fa_mesh_fs_params[10].w < 0.5;\n    }\n    else\n    {\n        _1720 = _1713;\n    }\n    if (_1720)\n    {\n        return;\n    }\n    vec3 _1726 = dFdx(world_pos);\n    vec3 _1729 = dFdy(world_pos);\n    vec3 param = world_pos;\n    vec4 _1733 = fa_cluster_texel(param);\n    int _1737 = int(_1733.w);\n    if (_1737 < 1)\n    {\n        return;\n    }\n    int _1747 = int(fa_mesh_fs_params[10].y + 0.5);\n    int param_1 = _1747;\n    vec4 _1751 = fa_light_texel(param_1);\n    vec2 _1754 = _1751.yz;\n    int _1758 = int(_1751.w);\n    int param_2 = _1747 + 1;\n    vec4 _1763 = fa_light_texel(param_2);\n    float _1764 = _1763.x;\n    int _1770 = int(fa_mesh_fs_params[10].w + 0.5) - 1;\n    int _1774 = int(_1733.z);\n    vec3 _2039;\n    for (int k = 0; k < _1737; k++)\n    {\n        int _1787 = _1774 + k;\n        int param_3 = _1758 + (_1787 >> 2);\n        int _1804 = (_1747 + 2) + (int(fa_light_texel(param_3)[_1787 & 3]) * 7);\n        int param_4 = _1804 + 6;\n        vec4 _1809 = fa_light_texel(param_4);\n        if (((int(_1809.w + 0.5) >> _1770) & 1) == 0)\n        {\n            continue;\n        }\n        int param_5 = _1804;\n        vec4 _1824 = fa_light_texel(param_5);\n        int param_6 = _1804 + 1;\n        vec4 _1829 = fa_light_texel(param_6);\n        int param_7 = _1804 + 2;\n        vec4 _1834 = fa_light_texel(param_7);\n        vec3 _1837 = _1824.xyz;\n        float _1842 = dot(_1837, world_pos) + _1824.w;\n        vec3 _1844 = _1829.xyz;\n        float _1849 = dot(_1844, world_pos) + _1829.w;\n        vec3 _1851 = _1834.xyz;\n        float _1856 = dot(_1851, world_pos) + _1834.w;\n        bool _1861 = abs(_1842) > 0.5;\n        bool _1869;\n        if (!_1861)\n        {\n            _1869 = abs(_1849) > 0.5;\n        }\n        else\n        {\n            _1869 = _1861;\n        }\n        bool _1877;\n        if (!_1869)\n        {\n            _1877 = abs(_1856) > 0.5;\n        }\n        else\n        {\n            _1877 = _1869;\n        }\n        if (_1877)\n        {\n            continue;\n        }\n        float _1892 = clamp(dot(geo_normal, normalize(_1851)) * _1809.z, 0.0, 1.0);\n        if (_1892 <= 0.0)\n        {\n            continue;\n        }\n        float _1912 = (clamp((0.5 - abs(_1856)) * 10.0, 0.0, 1.0) * _1892) * _1809.x;\n        vec2 _1920 = vec2(_1842 + 0.5, 0.5 - _1849);\n        vec2 _1930 = vec2(dot(_1837, _1726), dot(_1844, _1726));\n        vec2 _1940 = vec2(dot(_1837, _1729), dot(_1844, _1729));\n        int param_8 = _1804 + 5;\n        vec4 _1945 = fa_light_texel(param_8);\n        int param_9 = _1804 + 3;\n        vec4 _1950 = fa_light_texel(param_9);\n        int param_10 = _1804 + 4;\n        vec4 _1955 = fa_light_texel(param_10);\n        float tex_a = 1.0;\n        vec3 col = _1945.xyz;\n        bool _1965 = _1950.z > _1950.x;\n        if (_1965)\n        {\n            vec4 param_11 = _1950;\n            vec2 param_12 = _1920;\n            vec2 param_13 = _1754;\n            vec2 param_14 = _1930;\n            vec2 param_15 = _1940;\n            vec4 tx = fa_decal_tile(param_11, param_12, param_13, param_14, param_15);\n            if ((_1764 > 0.5) && (_1764 < 1.5))\n            {\n                vec3 param_16 = tx.xyz;\n                vec3 _1991 = fa_dc_to_linear(param_16);\n                vec4 _6208 = tx;\n                _6208.x = _1991.x;\n                _6208.y = _1991.y;\n                _6208.z = _1991.z;\n                tx = _6208;\n            }\n            col *= tx.xyz;\n            tex_a = tx.w;\n        }\n        albedo = mix(albedo, col, vec3(clamp((_1912 * tex_a) * _1945.w, 0.0, 1.0)));\n        if (_1955.z > _1955.x)\n        {\n            vec4 param_17 = _1955;\n            vec2 param_18 = _1920;\n            vec2 param_19 = _1754;\n            vec2 param_20 = _1930;\n            vec2 param_21 = _1940;\n            vec4 _2035 = fa_decal_tile(param_17, param_18, param_19, param_20, param_21);\n            if (_1764 > 1.5)\n            {\n                vec3 param_22 = _2035.xyz;\n                vec3 _2045 = fa_dc_to_srgb(param_22);\n                _2039 = _2045;\n            }\n            else\n            {\n                _2039 = _2035.xyz;\n            }\n            vec3 _2054 = (_2039 * 2.0) - vec3(1.0);\n            vec2 _2059 = _2054.xy * _1809.y;\n            vec3 _2081 = (normalize(_1837) * _2059.x) + (normalize(_1844) * _2059.y);\n            vec3 _2084 = normalize(normal);\n            normal = normalize(mix(_2084, normalize((_2084 * max(_2054.z, 0.0500000007450580596923828125)) + (_2081 - (_2084 * dot(_2084, _2081)))), vec3(clamp(_1912 * (_1965 ? tex_a : 1.0), 0.0, 1.0))));\n        }\n    }\n}\n\nvoid fa_lod_dither()\n{\n    if (fa_mesh_fs_params[52].w != 0.0)\n    {\n        float _442 = fract(52.98291778564453125 * fract(dot(gl_FragCoord.xy, vec2(0.067110560834407806396484375, 0.005837149918079376220703125))));\n        bool _445;\n        if (fa_mesh_fs_params[52].w > 0.0)\n        {\n            _445 = _442 >= fa_mesh_fs_params[52].w;\n        }\n        else\n        {\n            _445 = _442 < (-fa_mesh_fs_params[52].w);\n        }\n        if (_445)\n        {\n            discard;\n        }\n    }\n}\n\nint fa_light_count()\n{\n    return fa_cl_ndir + fa_cl_local;\n}\n\nLightSample fa_no_light()\n{\n    return LightSample(vec3(0.0, 1.0, 0.0), vec3(0.0), 0.0, 1.0, 0.0, 0);\n}\n\nint fa_cluster_index(int slot, int n)\n{\n    int param = (int(fa_mesh_fs_params[19].x) + int(fa_mesh_fs_params[19].w)) + ((slot + n) >> 2);\n    vec4 t = fa_light_texel(param);\n    return int(t[(slot + n) & 3]);\n}\n\nint fa_cl_light(int n)\n{\n    if (n < fa_cl_ndir)\n    {\n        return n;\n    }\n    int param = fa_cl_slot;\n    int param_1 = n - fa_cl_ndir;\n    return fa_cluster_index(param, param_1);\n}\n\nint fa_light_base(int li)\n{\n    return li * ((fa_mesh_fs_params[1].w > 4.5) ? 8 : 4);\n}\n\nbool fa_light_baked(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 3;\n    return fa_light_texel(param_1).w > 0.5;\n}\n\nfloat fa_baked_keep(int li)\n{\n    float _4728;\n    if (fa_lm.z > 0.5)\n    {\n        _4728 = 0.0;\n    }\n    else\n    {\n        _4728 = 1.0 - clamp(fa_mesh_fs_params[32].w, 0.0, 1.0);\n    }\n    bool _4739 = _4728 < 1.0;\n    bool _4745;\n    if (_4739)\n    {\n        int param = li;\n        _4745 = fa_light_baked(param);\n    }\n    else\n    {\n        _4745 = _4739;\n    }\n    return _4745 ? _4728 : 1.0;\n}\n\nvec3 fa_area_point(vec3 c, vec3 axis, vec3 ru, vec3 uu, float hx, float hy, float shape, vec3 p, vec3 r)\n{\n    bool _686 = dot(r, r) > 0.5;\n    if (shape > 1.5)\n    {\n        vec3 _699 = (c - (ru * hx)) - p;\n        vec3 _705 = ru * (2.0 * hx);\n        float _711 = max(dot(_705, _705), 9.9999999392252902907785028219223e-09);\n        float _715 = dot(_699, _705);\n        float t = clamp((-_715) / _711, 0.0, 1.0);\n        if (_686)\n        {\n            float _730 = dot(r, _705);\n            float _736 = _711 - (_730 * _730);\n            if (abs(_736) > (9.9999997473787516355514526367188e-06 * _711))\n            {\n                t = clamp(((dot(r, _699) * _730) - _715) / _736, 0.0, 1.0);\n            }\n        }\n        return (p + _699) + (_705 * t);\n    }\n    vec3 q = p;\n    float _768 = dot(r, axis);\n    bool _776;\n    if (_686)\n    {\n        _776 = abs(_768) > 9.9999997473787516355514526367188e-05;\n    }\n    else\n    {\n        _776 = _686;\n    }\n    if (_776)\n    {\n        float _786 = dot(c - p, axis) / _768;\n        if (_786 > 0.0)\n        {\n            q = p + (r * _786);\n        }\n    }\n    vec3 _799 = q - c;\n    vec2 xy = vec2(dot(_799, ru), dot(_799, uu));\n    if (shape > 0.5)\n    {\n        float _814 = length(xy);\n        if (_814 > hx)\n        {\n            xy *= (hx / _814);\n        }\n    }\n    else\n    {\n        xy = clamp(xy, vec2(-hx, -hy), vec2(hx, hy));\n    }\n    return (c + (ru * xy.x)) + (uu * xy.y);\n}\n\nvec4 fa_atlas_fetch(vec2 texel)\n{\n    return textureLod(fa_light_atlas_fa_env_smp, texel / vec2(textureSize(fa_light_atlas_fa_env_smp, 0)), 0.0);\n}\n\nvec3 fa_cookie_sample(vec2 tile_origin, vec2 uv)\n{\n    vec2 param = (tile_origin + vec2(1.0)) + (clamp(uv, vec2(0.0), vec2(1.0)) * 254.0);\n    return fa_atlas_fetch(param).xyz;\n}\n\nfloat fa_ies_sample(vec2 tile_origin, vec3 d, vec3 axis, vec3 right, vec3 up)\n{\n    float _606 = dot(d, right);\n    float _610 = dot(d, up);\n    float _621;\n    if (((_606 * _606) + (_610 * _610)) > 1.0000000133514319600180897396058e-10)\n    {\n        _621 = atan(_610, _606) * 0.15915493667125701904296875;\n    }\n    else\n    {\n        _621 = 0.0;\n    }\n    vec2 param = tile_origin + vec2(1.0 + ((_621 - floor(_621)) * 64.0), 1.0 + (acos(clamp(dot(d, axis), -1.0, 1.0)) * 10.18591594696044921875));\n    return fa_atlas_fetch(param).x;\n}\n\nint fa_cube_face(vec3 d)\n{\n    vec3 _462 = abs(d);\n    float _464 = _462.x;\n    float _466 = _462.y;\n    bool _467 = _464 >= _466;\n    bool _475;\n    if (_467)\n    {\n        _475 = _464 >= _462.z;\n    }\n    else\n    {\n        _475 = _467;\n    }\n    int _476;\n    if (_475)\n    {\n        _476 = (d.x > 0.0) ? 0 : 1;\n    }\n    else\n    {\n        int _490;\n        if (_466 >= _462.z)\n        {\n            _490 = (d.y > 0.0) ? 2 : 3;\n        }\n        else\n        {\n            _490 = (d.z > 0.0) ? 4 : 5;\n        }\n        _476 = _490;\n    }\n    return _476;\n}\n\nvoid fa_cube_face_basis(int f, out vec3 fwd, out vec3 up)\n{\n    if (f == 0)\n    {\n        fwd = vec3(1.0, 0.0, 0.0);\n        up = vec3(0.0, 1.0, 0.0);\n    }\n    else\n    {\n        if (f == 1)\n        {\n            fwd = vec3(-1.0, 0.0, 0.0);\n            up = vec3(0.0, 1.0, 0.0);\n        }\n        else\n        {\n            if (f == 2)\n            {\n                fwd = vec3(0.0, 1.0, 0.0);\n                up = vec3(0.0, 0.0, 1.0);\n            }\n            else\n            {\n                if (f == 3)\n                {\n                    fwd = vec3(0.0, -1.0, 0.0);\n                    up = vec3(0.0, 0.0, -1.0);\n                }\n                else\n                {\n                    if (f == 4)\n                    {\n                        fwd = vec3(0.0, 0.0, 1.0);\n                        up = vec3(0.0, 1.0, 0.0);\n                    }\n                    else\n                    {\n                        fwd = vec3(0.0, 0.0, -1.0);\n                        up = vec3(0.0, 1.0, 0.0);\n                    }\n                }\n            }\n        }\n    }\n}\n\nLightSample fa_light_sample_n(int li, vec3 world_pos, vec3 n)\n{\n    int param = li;\n    int _852 = fa_light_base(param);\n    bool _856 = fa_mesh_fs_params[1].w > 4.5;\n    int param_1 = _852;\n    vec4 _860 = fa_light_texel(param_1);\n    int param_2 = _852 + 1;\n    vec4 _865 = fa_light_texel(param_2);\n    float _868 = _865.w;\n    float atten = 1.0;\n    float dist = 0.0;\n    fa_light_tint = vec3(1.0);\n    bool _880 = _856 && (_868 > 2.5);\n    fa_light_is_area = _880;\n    bool _882 = _868 < 0.5;\n    vec3 l;\n    if (_882)\n    {\n        l = normalize(_860.xyz);\n        if (_856)\n        {\n            int param_3 = _852 + 6;\n            vec4 _896 = fa_light_texel(param_3);\n            if (_896.z > 0.5)\n            {\n                int param_4 = _852 + 4;\n                vec4 _906 = fa_light_texel(param_4);\n                int param_5 = _852 + 5;\n                vec4 _911 = fa_light_texel(param_5);\n                vec2 param_6 = _896.xy;\n                vec2 param_7 = fract(vec2(dot(world_pos, _906.xyz) * _906.w, (-dot(world_pos, _911.xyz)) * _911.w) + vec2(0.5));\n                fa_light_tint = fa_cookie_sample(param_6, param_7);\n            }\n        }\n    }\n    else\n    {\n        vec3 _941 = _860.xyz;\n        vec3 _943 = _941 - world_pos;\n        vec3 to_light = _943;\n        float _946 = length(_943);\n        float reach = _946;\n        bool front = true;\n        if (_880)\n        {\n            int param_8 = _852 + 7;\n            reach = max(_946 - fa_light_texel(param_8).w, 0.0);\n            int param_9 = _852 + 4;\n            vec4 _970 = fa_light_texel(param_9);\n            int param_10 = _852 + 5;\n            vec4 _975 = fa_light_texel(param_10);\n            int param_11 = _852 + 6;\n            vec4 _980 = fa_light_texel(param_11);\n            float _981 = _980.w;\n            int param_12 = _852 + 2;\n            vec3 _988 = normalize(fa_light_texel(param_12).xyz);\n            bool _990 = _981 > 1.5;\n            bool _998;\n            if (!_990)\n            {\n                _998 = dot(_988, to_light) < 0.0;\n            }\n            else\n            {\n                _998 = _990;\n            }\n            front = _998;\n            vec3 r = vec3(0.0);\n            vec3 _1007 = fa_mesh_fs_params[0].xyz - world_pos;\n            bool _1011 = dot(n, n) > 0.5;\n            bool _1019;\n            if (_1011)\n            {\n                _1019 = dot(_1007, _1007) > 9.9999999600419720025001879548654e-13;\n            }\n            else\n            {\n                _1019 = _1011;\n            }\n            if (_1019)\n            {\n                r = reflect(-normalize(_1007), normalize(n));\n            }\n            vec3 param_13 = _941;\n            vec3 param_14 = _988;\n            vec3 param_15 = _970.xyz;\n            vec3 param_16 = _975.xyz;\n            float param_17 = _970.w;\n            float param_18 = _975.w;\n            float param_19 = _981;\n            vec3 param_20 = world_pos;\n            vec3 param_21 = r;\n            to_light = fa_area_point(param_13, param_14, param_15, param_16, param_17, param_18, param_19, param_20, param_21) - world_pos;\n        }\n        float _1055 = length(to_light);\n        dist = _1055;\n        l = to_light / vec3(max(_1055, 9.9999997473787516355514526367188e-05));\n        float _1069 = reach / max(_860.w, 0.001000000047497451305389404296875);\n        float _1075 = clamp(1.0 - (_1069 * _1069), 0.0, 1.0);\n        float _1077;\n        if (front)\n        {\n            _1077 = _1075 * _1075;\n        }\n        else\n        {\n            _1077 = 0.0;\n        }\n        atten = _1077;\n        bool _1088 = _868 < 2.5;\n        if ((_868 > 1.5) && _1088)\n        {\n            int param_22 = _852 + 2;\n            vec4 _1096 = fa_light_texel(param_22);\n            float _1106 = _1096.w;\n            int param_23 = _852 + 3;\n            vec4 _1111 = fa_light_texel(param_23);\n            float _1112 = _1111.x;\n            float cos_inner = _1112;\n            if (_1112 > 1.5)\n            {\n                cos_inner = mix(_1106, 1.0, 0.25);\n            }\n            atten *= smoothstep(_1106, cos_inner, dot(-l, normalize(_1096.xyz)));\n        }\n        if (_856 && (_868 < 1.5))\n        {\n            int param_24 = _852 + 6;\n            vec4 _1136 = fa_light_texel(param_24);\n            if (_1136.z > 0.5)\n            {\n                vec3 _1144 = -to_light;\n                int param_25 = _852 + 4;\n                int param_26 = _852 + 5;\n                vec3 _1158 = fa_light_texel(param_25).xyz;\n                vec3 _1162 = fa_light_texel(param_26).xyz;\n                vec3 _1171 = vec3(dot(_1144, _1158), dot(_1144, _1162), dot(_1144, cross(_1158, _1162)));\n                vec3 param_27 = _1171;\n                int _1175 = fa_cube_face(param_27);\n                int param_28 = _1175;\n                vec3 param_29;\n                vec3 param_30;\n                fa_cube_face_basis(param_28, param_29, param_30);\n                vec2 _1202 = vec2(dot(_1171, cross(param_29, param_30)), dot(_1171, param_30)) / vec2(max(dot(_1171, param_29), 9.9999997473787516355514526367188e-05));\n                int _1206 = _1175 / 3;\n                vec2 param_31 = _1136.xy + (vec2(float(_1175 - (_1206 * 3)), float(_1206)) * 256.0);\n                vec2 param_32 = vec2(0.5 + (0.5 * _1202.x), 0.5 - (0.5 * _1202.y));\n                fa_light_tint = fa_cookie_sample(param_31, param_32);\n            }\n            int param_33 = _852 + 7;\n            vec4 _1236 = fa_light_texel(param_33);\n            if (_1236.z > 0.5)\n            {\n                int param_34 = _852 + 2;\n                int param_35 = _852 + 4;\n                int param_36 = _852 + 5;\n                vec2 param_37 = _1236.xy;\n                vec3 param_38 = -l;\n                vec3 param_39 = normalize(fa_light_texel(param_34).xyz);\n                vec3 param_40 = fa_light_texel(param_35).xyz;\n                vec3 param_41 = fa_light_texel(param_36).xyz;\n                atten *= fa_ies_sample(param_37, param_38, param_39, param_40, param_41);\n            }\n        }\n        else\n        {\n            if (_856 && _1088)\n            {\n                int param_42 = _852 + 6;\n                vec4 _1283 = fa_light_texel(param_42);\n                int param_43 = _852 + 7;\n                vec4 _1288 = fa_light_texel(param_43);\n                bool _1291 = _1283.z > 0.5;\n                bool _1298;\n                if (!_1291)\n                {\n                    _1298 = _1288.z > 0.5;\n                }\n                else\n                {\n                    _1298 = _1291;\n                }\n                if (_1298)\n                {\n                    int param_44 = _852 + 2;\n                    vec4 _1305 = fa_light_texel(param_44);\n                    vec3 _1309 = normalize(_1305.xyz);\n                    int param_45 = _852 + 4;\n                    vec4 _1314 = fa_light_texel(param_45);\n                    int param_46 = _852 + 5;\n                    vec4 _1319 = fa_light_texel(param_46);\n                    if (_1291)\n                    {\n                        vec3 _1327 = -to_light;\n                        float _1334 = _1305.w;\n                        float _1350 = 0.5 / max(dot(_1327, _1309) * (sqrt(max(1.0 - (_1334 * _1334), 0.0)) / max(_1334, 0.001000000047497451305389404296875)), 9.9999997473787516355514526367188e-05);\n                        vec2 param_47 = _1283.xy;\n                        vec2 param_48 = vec2(0.5 + (dot(_1327, _1314.xyz) * _1350), 0.5 - (dot(_1327, _1319.xyz) * _1350));\n                        fa_light_tint = fa_cookie_sample(param_47, param_48);\n                    }\n                    if (_1288.z > 0.5)\n                    {\n                        vec2 param_49 = _1288.xy;\n                        vec3 param_50 = -l;\n                        vec3 param_51 = _1309;\n                        vec3 param_52 = _1314.xyz;\n                        vec3 param_53 = _1319.xyz;\n                        atten *= fa_ies_sample(param_49, param_50, param_51, param_52, param_53);\n                    }\n                }\n            }\n        }\n    }\n    vec3 _5926 = _865.xyz * atten;\n    if (_856)\n    {\n        _5926 *= fa_light_tint;\n    }\n    int _1419;\n    if (_882)\n    {\n        _1419 = 0;\n    }\n    else\n    {\n        _1419 = ((_868 > 1.5) && (_868 < 2.5)) ? 2 : 1;\n    }\n    return LightSample(l, _5926, atten, 1.0, dist, _1419);\n}\n\nLightSample fa_light_unshadowed(int n, SurfaceInput i)\n{\n    bool _4957 = n < 0;\n    bool _4964;\n    if (!_4957)\n    {\n        _4964 = n >= fa_light_count();\n    }\n    else\n    {\n        _4964 = _4957;\n    }\n    if (_4964)\n    {\n        return fa_no_light();\n    }\n    int param = n;\n    int _4972 = fa_cl_light(param);\n    int param_1 = _4972;\n    float _4976 = fa_baked_keep(param_1);\n    if (_4976 <= 0.0)\n    {\n        return fa_no_light();\n    }\n    int param_2 = _4972;\n    vec3 param_3 = i.world_pos;\n    vec3 param_4 = i.world_normal;\n    LightSample _4992 = fa_light_sample_n(param_2, param_3, param_4);\n    return LightSample(_4992.direction, _4992.color * _4976, _4992.attenuation * _4976, _4992.shadow, _4992._distance, _4992.type);\n}\n\nfloat fa_light_type(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 1;\n    return fa_light_texel(param_1).w;\n}\n\nfloat fa_shadow_depth(inout vec2 uv, vec4 rect)\n{\n    uv = clamp(uv, rect.xy, rect.zw);\n    return textureLod(fa_shadow_tex_fa_shadow_smp, uv, 0.0).x;\n}\n\nfloat fa_shadow_fetch(vec2 uv, vec4 rect, vec3 conv)\n{\n    vec2 param = uv;\n    vec4 param_1 = rect;\n    float _2202 = fa_shadow_depth(param, param_1);\n    float _2206;\n    if (conv.x < 0.5)\n    {\n        _2206 = _2202;\n    }\n    else\n    {\n        _2206 = (conv.y * conv.z) / (conv.z - (_2202 * (conv.z - conv.y)));\n    }\n    return _2206;\n}\n\nfloat fa_shadow_noise()\n{\n    return fract(52.98291778564453125 * fract(dot(gl_FragCoord.xy, vec2(0.067110560834407806396484375, 0.005837149918079376220703125))));\n}\n\nvec2 fa_shadow_vogel_turn(vec2 d)\n{\n    return vec2((d.x * (-0.737368881702423095703125)) - (d.y * 0.675490319728851318359375), (d.y * (-0.737368881702423095703125)) + (d.x * 0.675490319728851318359375));\n}\n\nfloat fa_shadow_filter(vec2 uv, vec4 rect, float zr, float texel_m, float unit, float reach, float plane, vec3 conv, int mode, float k)\n{\n    if (mode == 1)\n    {\n        vec2 param = uv;\n        vec4 param_1 = rect;\n        vec3 param_2 = conv;\n        return float(zr <= fa_shadow_fetch(param, param_1, param_2));\n    }\n    float _2252 = fa_shadow_noise() * 6.283185482025146484375;\n    vec2 _2258 = vec2(cos(_2252), sin(_2252));\n    vec2 dir = _2258;\n    float radius = 1.5;\n    if (mode == 2)\n    {\n        float _2267;\n        if (k < 0.0)\n        {\n            _2267 = (-k) / max(zr, 0.100000001490116119384765625);\n        }\n        else\n        {\n            _2267 = k;\n        }\n        float _2286 = clamp((_2267 * reach) / texel_m, 3.0, 12.0);\n        float sum = 0.0;\n        float cnt = 0.0;\n        for (int i = 0; i < 16; i++)\n        {\n            float _2305 = sqrt((float(i) + 0.5) * 0.0625) * _2286;\n            vec2 param_3 = uv + (dir * (fa_shadows[26].zw * _2305));\n            vec4 param_4 = rect;\n            vec3 param_5 = conv;\n            float _2319 = fa_shadow_fetch(param_3, param_4, param_5);\n            if (_2319 < (zr - (_2305 * plane)))\n            {\n                sum += _2319;\n                cnt += 1.0;\n            }\n            vec2 param_6 = dir;\n            dir = fa_shadow_vogel_turn(param_6);\n        }\n        if (cnt < 0.5)\n        {\n            return 1.0;\n        }\n        float _2347 = sum / cnt;\n        float _2357;\n        if (k < 0.0)\n        {\n            _2357 = (-k) / max(_2347, 0.0500000007450580596923828125);\n        }\n        else\n        {\n            _2357 = k;\n        }\n        radius = clamp(((max(zr - _2347, 0.0) * unit) * _2357) / texel_m, 1.5, 16.0);\n        dir = _2258;\n    }\n    float lit = 0.0;\n    int _2383 = (mode == 2) ? 24 : 16;\n    for (int i_1 = 0; i_1 < _2383; i_1++)\n    {\n        float _2402 = sqrt((float(i_1) + 0.5) / float(_2383)) * radius;\n        vec2 param_7 = uv + (dir * (fa_shadows[26].zw * _2402));\n        vec4 param_8 = rect;\n        vec3 param_9 = conv;\n        lit += float((zr - (_2402 * plane)) <= fa_shadow_fetch(param_7, param_8, param_9));\n        vec2 param_10 = dir;\n        dir = fa_shadow_vogel_turn(param_10);\n    }\n    return lit / float(_2383);\n}\n\nfloat fa_shadow_local(int li, vec3 lpos, vec3 world, vec3 n, vec3 l)\n{\n    bool _2607 = fa_mesh_fs_params[5].z < 0.5;\n    bool _2614;\n    if (!_2607)\n    {\n        _2614 = fa_shadows[29].x < 0.5;\n    }\n    else\n    {\n        _2614 = _2607;\n    }\n    if (_2614)\n    {\n        return 1.0;\n    }\n    int param = (int(fa_shadows[29].x + 0.5) - 1) + li;\n    vec4 _2627 = fa_light_texel(param);\n    float _2628 = _2627.x;\n    if (_2628 < 0.0)\n    {\n        return 1.0;\n    }\n    int _2637 = int(_2628 + 0.5);\n    int param_1 = _2637;\n    vec4 _2641 = fa_light_texel(param_1);\n    int param_2 = _2637 + 1;\n    vec4 _2646 = fa_light_texel(param_2);\n    float fade = 1.0;\n    float _2649 = _2641.y;\n    if (_2649 > 0.0)\n    {\n        float _2666 = 1.0 - smoothstep(0.75 * _2649, _2649, length(world - fa_shadows[27].xyz));\n        fade = _2666;\n        if (_2666 <= 0.0)\n        {\n            return 1.0;\n        }\n    }\n    int face = 0;\n    if (_2641.x > 1.5)\n    {\n        vec3 param_3 = world - lpos;\n        face = fa_cube_face(param_3);\n    }\n    int _2690 = (_2637 + 2) + (face * 6);\n    int param_4 = _2690;\n    int param_5 = _2690 + 1;\n    int param_6 = _2690 + 3;\n    vec4 _2704 = fa_light_texel(param_6);\n    int param_7 = _2690 + 4;\n    vec4 _2709 = fa_light_texel(param_7);\n    int param_8 = _2690 + 5;\n    vec4 _2714 = fa_light_texel(param_8);\n    float _2726 = _2714.x * max(dot(_2704, vec4(world, 1.0)), 0.001000000047497451305389404296875);\n    float _2731 = clamp(dot(n, l), 0.0, 1.0);\n    float _2754 = clamp(dot(n, _2704.xyz), -1.0, 1.0);\n    float _2773 = min(sqrt(1.0 - (_2754 * _2754)) / max(abs(dot(n, world - lpos)) / max(dot(_2704, vec4(world, 1.0)), 0.001000000047497451305389404296875), 0.20000000298023223876953125), 4.0);\n    float _2776 = _2646.y;\n    float _2778;\n    if (_2776 > 0.0)\n    {\n        _2778 = _2776;\n    }\n    else\n    {\n        _2778 = 1.5 * _2726;\n    }\n    vec4 _2798 = vec4(world + (n * (_2778 * sqrt(1.0 - (_2731 * _2731)))), 1.0);\n    float _2802 = dot(_2704, _2798);\n    float _2805 = _2714.y;\n    if (_2802 < _2805)\n    {\n        return 1.0;\n    }\n    vec2 _2820 = vec2(dot(fa_light_texel(param_4), _2798), dot(fa_light_texel(param_5), _2798)) / vec2(_2802);\n    float _2822 = _2820.x;\n    bool _2825 = _2822 < _2709.x;\n    bool _2834;\n    if (!_2825)\n    {\n        _2834 = _2822 > _2709.z;\n    }\n    else\n    {\n        _2834 = _2825;\n    }\n    bool _2843;\n    if (!_2834)\n    {\n        _2843 = _2820.y < _2709.y;\n    }\n    else\n    {\n        _2843 = _2834;\n    }\n    bool _2852;\n    if (!_2843)\n    {\n        _2852 = _2820.y > _2709.w;\n    }\n    else\n    {\n        _2852 = _2843;\n    }\n    if (_2852)\n    {\n        return 1.0;\n    }\n    float _2858 = _2646.x;\n    float _2860;\n    if (_2858 > 0.0)\n    {\n        _2860 = _2858;\n    }\n    else\n    {\n        _2860 = 1.5 * _2726;\n    }\n    vec2 param_9 = _2820;\n    vec4 param_10 = _2709;\n    float param_11 = _2802 - (_2860 * (1.0 + (0.5 * _2773)));\n    float param_12 = _2726;\n    float param_13 = 1.0;\n    float param_14 = _2714.z * 0.25;\n    float param_15 = (_2726 * min(_2773, 3.0)) * 0.5;\n    vec3 param_16 = vec3(1.0, _2805, _2714.z);\n    int param_17 = int(_2641.z + 0.5);\n    float param_18 = _2641.w;\n    return mix(1.0, fa_shadow_filter(param_9, param_10, param_11, param_12, param_13, param_14, param_15, param_16, param_17, param_18), fade);\n}\n\nfloat fa_shadow_split_at(int i)\n{\n    float _2145;\n    if (i == 0)\n    {\n        _2145 = fa_shadows[24].x;\n    }\n    else\n    {\n        float _2161;\n        if (i == 1)\n        {\n            _2161 = fa_shadows[24].y;\n        }\n        else\n        {\n            float _2169;\n            if (i == 2)\n            {\n                _2169 = fa_shadows[24].z;\n            }\n            else\n            {\n                _2169 = fa_shadows[24].w;\n            }\n            _2161 = _2169;\n        }\n        _2145 = _2161;\n    }\n    return _2145;\n}\n\nfloat fa_shadow_cascade(int ci, vec3 world, vec3 n, vec3 l)\n{\n    float _2448 = max(fa_shadows[ci * 1 + 20].y, 0.001000000047497451305389404296875);\n    float _2453 = clamp(dot(n, l), 0.0, 1.0);\n    float _2459 = sqrt(1.0 - (_2453 * _2453));\n    float _2467 = min(_2459 / max(_2453, 0.20000000298023223876953125), 4.0);\n    float _2472;\n    if (fa_shadows[26].y > 0.0)\n    {\n        _2472 = fa_shadows[26].y;\n    }\n    else\n    {\n        _2472 = 1.5 * fa_shadows[ci * 1 + 20].x;\n    }\n    vec4 _2497 = mat4(fa_shadows[ci * 4 + 0], fa_shadows[ci * 4 + 1], fa_shadows[ci * 4 + 2], fa_shadows[ci * 4 + 3]) * vec4(world + (n * (_2472 * _2459)), 1.0);\n    float _2504 = _2497.x;\n    bool _2507 = _2504 < fa_shadows[ci * 1 + 16].x;\n    bool _2516;\n    if (!_2507)\n    {\n        _2516 = _2504 > fa_shadows[ci * 1 + 16].z;\n    }\n    else\n    {\n        _2516 = _2507;\n    }\n    bool _2525;\n    if (!_2516)\n    {\n        _2525 = _2497.y < fa_shadows[ci * 1 + 16].y;\n    }\n    else\n    {\n        _2525 = _2516;\n    }\n    bool _2534;\n    if (!_2525)\n    {\n        _2534 = _2497.y > fa_shadows[ci * 1 + 16].w;\n    }\n    else\n    {\n        _2534 = _2525;\n    }\n    bool _2541;\n    if (!_2534)\n    {\n        _2541 = _2497.z > 1.0;\n    }\n    else\n    {\n        _2541 = _2534;\n    }\n    if (_2541)\n    {\n        return -1.0;\n    }\n    float _2549;\n    if (fa_shadows[26].x > 0.0)\n    {\n        _2549 = fa_shadows[26].x;\n    }\n    else\n    {\n        _2549 = 1.5 * fa_shadows[ci * 1 + 20].x;\n    }\n    vec2 param = _2497.xy;\n    vec4 param_1 = fa_shadows[ci * 1 + 16];\n    float param_2 = _2497.z - ((_2549 * (1.0 + (0.5 * _2467))) / _2448);\n    float param_3 = fa_shadows[ci * 1 + 20].x;\n    float param_4 = _2448;\n    float param_5 = _2448 * 0.25;\n    float param_6 = ((fa_shadows[ci * 1 + 20].x * min(_2467, 3.0)) * 0.5) / _2448;\n    vec3 param_7 = vec3(0.0);\n    int param_8 = int(fa_shadows[25].z + 0.5);\n    float param_9 = fa_shadows[25].w;\n    return fa_shadow_filter(param, param_1, param_2, param_3, param_4, param_5, param_6, param_7, param_8, param_9);\n}\n\nfloat fa_shadow_sun(vec3 world, vec3 n, vec3 l)\n{\n    if (fa_mesh_fs_params[5].z < 0.5)\n    {\n        return 1.0;\n    }\n    int _2927 = int(fa_shadows[25].x + 0.5);\n    if (_2927 < 1)\n    {\n        return 1.0;\n    }\n    float _2942 = dot(world - fa_shadows[27].xyz, fa_shadows[28].xyz);\n    int param = _2927 - 1;\n    if (_2942 > fa_shadow_split_at(param))\n    {\n        return 1.0;\n    }\n    int ci = 0;\n    bool _2954 = _2927 > 1;\n    bool _2961;\n    if (_2954)\n    {\n        _2961 = _2942 > fa_shadows[24].x;\n    }\n    else\n    {\n        _2961 = _2954;\n    }\n    if (_2961)\n    {\n        ci = 1;\n    }\n    bool _2965 = _2927 > 2;\n    bool _2972;\n    if (_2965)\n    {\n        _2972 = _2942 > fa_shadows[24].y;\n    }\n    else\n    {\n        _2972 = _2965;\n    }\n    if (_2972)\n    {\n        ci = 2;\n    }\n    bool _2976 = _2927 > 3;\n    bool _2983;\n    if (_2976)\n    {\n        _2983 = _2942 > fa_shadows[24].z;\n    }\n    else\n    {\n        _2983 = _2976;\n    }\n    if (_2983)\n    {\n        ci = 3;\n    }\n    float s = -1.0;\n    float s2 = -1.0;\n    float t = 0.0;\n    int _2994 = min(_2927, 4);\n    float _3035;\n    for (int c = ci; c < _2994; c++)\n    {\n        int param_1 = c;\n        vec3 param_2 = world;\n        vec3 param_3 = n;\n        vec3 param_4 = l;\n        float _3014 = fa_shadow_cascade(param_1, param_2, param_3, param_4);\n        if (s >= 0.0)\n        {\n            s2 = _3014;\n            break;\n        }\n        if (_3014 < 0.0)\n        {\n            continue;\n        }\n        s = _3014;\n        ci = c;\n        if (fa_shadows[25].y > 0.0)\n        {\n            if (ci > 0)\n            {\n                int param_5 = ci - 1;\n                _3035 = fa_shadow_split_at(param_5);\n            }\n            else\n            {\n                _3035 = fa_shadows[28].w;\n            }\n            int param_6 = ci;\n            float _3054 = fa_shadows[25].y * max(fa_shadow_split_at(param_6) - _3035, 9.9999997473787516355514526367188e-05);\n            int param_7 = ci;\n            t = clamp((_2942 - (fa_shadow_split_at(param_7) - _3054)) / _3054, 0.0, 1.0);\n        }\n        if (t <= 0.0)\n        {\n            break;\n        }\n    }\n    if (s < 0.0)\n    {\n        return 1.0;\n    }\n    if (t > 0.0)\n    {\n        float _3086;\n        if ((ci + 1) < _2927)\n        {\n            _3086 = (s2 < 0.0) ? s : s2;\n        }\n        else\n        {\n            _3086 = 1.0;\n        }\n        s = mix(s, _3086, t);\n    }\n    return s;\n}\n\nfloat fa_shadow_factor(vec3 n, vec3 l)\n{\n    vec3 param = fa_world_pos;\n    vec3 param_1 = n;\n    vec3 param_2 = l;\n    return fa_shadow_sun(param, param_1, param_2);\n}\n\nfloat fa_contact_shadow(int li, vec3 world, vec3 gn, vec3 l, float dist)\n{\n    bool _4464 = fa_mesh_fs_params[24].x < 0.5;\n    bool _4471;\n    if (!_4464)\n    {\n        _4471 = fa_shadows[29].x < 0.5;\n    }\n    else\n    {\n        _4471 = _4464;\n    }\n    if (_4471)\n    {\n        return 1.0;\n    }\n    int param = (int(fa_shadows[29].x + 0.5) - 1) + li;\n    vec4 _4484 = fa_light_texel(param);\n    float _4485 = _4484.y;\n    float len = _4485;\n    if (_4485 <= 0.0)\n    {\n        return 1.0;\n    }\n    float _4497 = length(world - fa_mesh_fs_params[0].xyz);\n    float _4507 = 1.0 - smoothstep(0.5 * fa_mesh_fs_params[25].x, fa_mesh_fs_params[25].x, _4497);\n    if (_4507 <= 0.0)\n    {\n        return 1.0;\n    }\n    float _4513 = len;\n    float _4516 = min(_4513, 0.89999997615814208984375 * dist);\n    len = _4516;\n    float _4521 = 0.004999999888241291046142578125 + (0.0030000000260770320892333984375 * _4497);\n    float _4526 = _4521 + (0.5 * _4516);\n    vec3 _4532 = world + (gn * _4521);\n    float _4534 = fa_shadow_noise();\n    float occ = 0.0;\n    float _4598;\n    for (int k = 0; k < 12; k++)\n    {\n        float _4549 = (float(k) + _4534) * 0.083333335816860198974609375;\n        vec3 _4557 = _4532 + (l * (_4549 * len));\n        vec4 _4563 = vec4(_4557, 1.0);\n        float _4569 = dot(fa_mesh_fs_params[28], _4563);\n        if (_4569 < 9.9999997473787516355514526367188e-05)\n        {\n            break;\n        }\n        vec2 _4589 = vec2(dot(fa_mesh_fs_params[26], _4563), dot(fa_mesh_fs_params[27], _4563)) / vec2(_4569);\n        float _4593 = _4589.x * 0.5;\n        float _4594 = _4593 + 0.5;\n        if (fa_mesh_fs_params[24].y > 0.5)\n        {\n            _4598 = (_4589.y * 0.5) + 0.5;\n        }\n        else\n        {\n            _4598 = 0.5 - (_4589.y * 0.5);\n        }\n        bool _4614 = _4594 < 0.0;\n        bool _4621;\n        if (!_4614)\n        {\n            _4621 = _4594 >= 1.0;\n        }\n        else\n        {\n            _4621 = _4614;\n        }\n        bool _4628;\n        if (!_4621)\n        {\n            _4628 = _4598 < 0.0;\n        }\n        else\n        {\n            _4628 = _4621;\n        }\n        bool _4635;\n        if (!_4628)\n        {\n            _4635 = _4598 >= 1.0;\n        }\n        else\n        {\n            _4635 = _4628;\n        }\n        if (_4635)\n        {\n            break;\n        }\n        vec4 _4662 = texelFetch(fa_screen_tex_fa_shadow_smp, clamp(ivec2(vec2(_4594, _4598) * fa_mesh_fs_params[24].zw), ivec2(0), ivec2(fa_mesh_fs_params[24].zw) - ivec2(1)), 0);\n        if (_4662.w < 0.5)\n        {\n            continue;\n        }\n        float _4681 = (dot(fa_mesh_fs_params[29].xyz, _4557) + fa_mesh_fs_params[29].w) - _4662.x;\n        if ((_4681 > _4521) && (_4681 < _4526))\n        {\n            occ = max(occ, (1.0 - (_4549 * _4549)) * smoothstep(0.0, 0.0500000007450580596923828125, min(min(_4594, 0.5 - _4593), min(_4598, 1.0 - _4598))));\n        }\n    }\n    return 1.0 - (occ * _4507);\n}\n\nLightSample fa_light_shadowed(int li, vec3 world_pos, vec3 gn)\n{\n    int param = li;\n    float _4784 = fa_baked_keep(param);\n    if (_4784 <= 0.0)\n    {\n        int param_1 = li;\n        return LightSample(vec3(0.0, 1.0, 0.0), vec3(0.0), 0.0, 1.0, 0.0, int(fa_light_type(param_1) + 0.5));\n    }\n    int param_2 = li;\n    vec3 param_3 = world_pos;\n    vec3 param_4 = gn;\n    LightSample _4810 = fa_light_sample_n(param_2, param_3, param_4);\n    vec3 _6072 = _4810.color;\n    float _6073 = _4810.attenuation;\n    float _6074 = _4810.shadow;\n    bool _4813 = _4810.type == 0;\n    if (_4813 && (li == 0))\n    {\n        vec3 param_5 = gn;\n        vec3 param_6 = _4810.direction;\n        float _4824 = fa_shadow_factor(param_5, param_6);\n        _6074 = _4824;\n        _6072 *= _4824;\n    }\n    else\n    {\n        bool _4835 = _4810.type != 0;\n        bool _4841;\n        if (_4835)\n        {\n            _4841 = _6073 > 0.0;\n        }\n        else\n        {\n            _4841 = _4835;\n        }\n        if (_4841)\n        {\n            int param_7 = li;\n            int param_8 = fa_light_base(param_7);\n            int param_9 = li;\n            vec3 param_10 = fa_light_texel(param_8).xyz;\n            vec3 param_11 = world_pos;\n            vec3 param_12 = gn;\n            vec3 param_13 = _4810.direction;\n            float _4860 = fa_shadow_local(param_9, param_10, param_11, param_12, param_13);\n            _6074 = _4860;\n            _6072 *= _4860;\n        }\n    }\n    bool _4870 = fa_mesh_fs_params[24].x > 0.5;\n    bool _4876;\n    if (_4870)\n    {\n        _4876 = _6073 > 0.0;\n    }\n    else\n    {\n        _4876 = _4870;\n    }\n    if (_4876)\n    {\n        float _4883;\n        if (_4813)\n        {\n            _4883 = 1000000000.0;\n        }\n        else\n        {\n            _4883 = _4810._distance;\n        }\n        int param_14 = li;\n        vec3 param_15 = world_pos;\n        vec3 param_16 = gn;\n        vec3 param_17 = _4810.direction;\n        float param_18 = _4883;\n        float _4901 = fa_contact_shadow(param_14, param_15, param_16, param_17, param_18);\n        _6074 *= _4901;\n        _6072 *= _4901;\n    }\n    float _4914 = _6073;\n    float _4915 = _4914 * _4784;\n    _6073 = _4915;\n    vec3 _4919 = _6072;\n    vec3 _4920 = _4919 * _4784;\n    _6072 = _4920;\n    return LightSample(_4810.direction, _4920, _4915, _6074, _4810._distance, _4810.type);\n}\n\nLightSample fa_light(int n, SurfaceInput i)\n{\n    bool _4931 = n < 0;\n    bool _4938;\n    if (!_4931)\n    {\n        _4938 = n >= fa_light_count();\n    }\n    else\n    {\n        _4938 = _4931;\n    }\n    if (_4938)\n    {\n        return fa_no_light();\n    }\n    int param = n;\n    int param_1 = fa_cl_light(param);\n    vec3 param_2 = i.world_pos;\n    vec3 param_3 = i.world_normal;\n    LightSample _4953 = fa_light_shadowed(param_1, param_2, param_3);\n    return _4953;\n}\n\nfloat fa_sheen_albedo(float ndv, float rough)\n{\n    float _3849 = min(sqrt(max(rough - 0.100000001490116119384765625, 0.0) * 1.111111164093017578125) * 6.0, 5.999000072479248046875);\n    float _3857 = min(sqrt(clamp(ndv, 0.0, 1.0)) * 8.0, 7.999000072479248046875);\n    int _3860 = int(_3849);\n    int _3863 = int(_3857);\n    float _3873 = _3857 - float(_3863);\n    int _3929 = (_3860 * 9) + _3863;\n    int _3949 = ((_3860 + 1) * 9) + _3863;\n    return mix(mix(_3924[_3929], _3924[_3929 + 1], _3873), mix(_3924[_3949], _3924[_3949 + 1], _3873), _3849 - float(_3860));\n}\n\nFaLayers fa_layers_setup(SurfaceInput i, Surface s, vec3 n, vec3 v, float metallic, float roughness, inout vec3 f0)\n{\n    bool _5938 = false;\n    float _5939 = 1.0;\n    float _5940 = 1.0;\n    float _5941 = 1.0;\n    float _5942 = 0.0;\n    float _5943 = 0.0;\n    float _5944 = 0.0;\n    float _5945 = 0.0;\n    float _5947 = 1.0;\n    bool _5948 = false;\n    vec3 _5949 = vec3(0.0);\n    float _5950 = 1.0;\n    float _5951 = 1.0;\n    float _5952 = 1.0;\n    float _5953 = 0.0;\n    float _5954 = 0.0;\n    vec3 _5955 = vec3(1.0, 0.0, 0.0);\n    vec3 _5956 = vec3(0.0, 0.0, 1.0);\n    float _5957 = 1.0;\n    float _5958 = 1.0;\n    float _4000 = clamp(s.specular, 0.0, 1.0);\n    float _4004 = clamp(s.ior, 1.0, 3.0);\n    bool _4009 = (_4000 != 1.0) || (_4004 != 1.5);\n    bool _4018;\n    if (!_4009)\n    {\n        _4018 = any(notEqual(s.specular_color, vec3(1.0)));\n    }\n    else\n    {\n        _4018 = _4009;\n    }\n    if (_4018)\n    {\n        float _4026 = (_4004 - 1.0) / (_4004 + 1.0);\n        f0 = mix(min(vec3(_4026 * _4026) * max(s.specular_color, vec3(0.0)), vec3(1.0)) * _4000, s.albedo, vec3(metallic));\n        _5939 = mix(_4000, 1.0, metallic);\n        _5938 = true;\n    }\n    float _4053 = clamp(s.clearcoat, 0.0, 1.0);\n    if (_4053 > 0.0)\n    {\n        float _4061 = clamp(s.clearcoat_roughness, 0.0500000007450580596923828125, 1.0);\n        _5942 = _4053;\n        _5943 = _4061;\n        float _4068 = _4061 * _4061;\n        _5944 = _4068;\n        _5945 = _4068 * _4068;\n        float _4080 = max(dot(i.world_normal, v), 9.9999997473787516355514526367188e-05);\n        _5947 = _4080;\n        _5940 = 1.0 - (_4053 * (0.039999999105930328369140625 + (0.959999978542327880859375 * pow(clamp(1.0 - _4080, 0.0, 1.0), 5.0))));\n        _5938 = true;\n    }\n    vec3 _4099 = max(s.sheen_color, vec3(0.0));\n    float _4108 = max(_4099.x, max(_4099.y, _4099.z));\n    if (_4108 > 0.0)\n    {\n        float _4116 = clamp(s.sheen_roughness, 0.100000001490116119384765625, 1.0);\n        _5948 = true;\n        _5949 = _4099;\n        _5950 = _4116;\n        _5951 = _4116 * _4116;\n        float param = max(dot(n, v), 9.9999997473787516355514526367188e-05);\n        float param_1 = _4116;\n        float _4133 = fa_sheen_albedo(param, param_1);\n        _5953 = _4133;\n        _5952 = 1.0 - min(_4108 * _4133, 1.0);\n        _5938 = true;\n    }\n    _5941 = _5940 * _5952;\n    float _4152 = clamp(s.anisotropy, -1.0, 1.0);\n    if (_4152 != 0.0)\n    {\n        vec3 _4167 = i.world_tangent.xyz - (n * dot(n, i.world_tangent.xyz));\n        vec3 t = _4167;\n        if (dot(_4167, _4167) < 9.9999999392252902907785028219223e-09)\n        {\n            bvec3 _4179 = bvec3(abs(n.y) < 0.9900000095367431640625);\n            t = cross(vec3(_4179.x ? vec3(0.0, 1.0, 0.0).x : vec3(1.0, 0.0, 0.0).x, _4179.y ? vec3(0.0, 1.0, 0.0).y : vec3(1.0, 0.0, 0.0).y, _4179.z ? vec3(0.0, 1.0, 0.0).z : vec3(1.0, 0.0, 0.0).z), n);\n        }\n        vec3 _4183 = t;\n        vec3 _4184 = normalize(_4183);\n        t = _4184;\n        vec3 _4209 = normalize((_4184 * cos(s.anisotropy_rotation)) + ((cross(n, _4184) * ((i.world_tangent.w < 0.0) ? (-1.0) : 1.0)) * sin(s.anisotropy_rotation)));\n        _5955 = _4209;\n        _5956 = cross(n, _4209);\n        float _4219 = roughness * roughness;\n        float _4225 = mix(_4219, 1.0, _4152 * _4152);\n        bool _4227 = _4152 > 0.0;\n        _5957 = _4227 ? _4225 : _4219;\n        _5958 = _4227 ? _4219 : _4225;\n        _5954 = _4152;\n        _5938 = true;\n    }\n    return FaLayers(_5938, _5939, _5940, _5941, _5942, _5943, _5944, _5945, i.world_normal, _5947, _5948, _5949, _5950, _5951, _5952, _5953, _5954, _5955, _5956, _5957, _5958);\n}\n\nvec2 fa_env_brdf(float rough, float ndv)\n{\n    vec4 _3781 = (vec4(-1.0, -0.0274999998509883880615234375, -0.572000026702880859375, 0.02199999988079071044921875) * rough) + vec4(1.0, 0.0425000004470348358154296875, 1.03999996185302734375, -0.039999999105930328369140625);\n    float _3784 = _3781.x;\n    return (vec2(-1.03999996185302734375, 1.03999996185302734375) * ((min(_3784 * _3784, exp2((-9.27999973297119140625) * ndv)) * _3784) + _3781.y)) + _3781.zw;\n}\n\nvec2 fa_oct_encode(vec3 d)\n{\n    vec3 _3216 = d / vec3(max((abs(d.x) + abs(d.y)) + abs(d.z), 9.9999999600419720025001879548654e-13));\n    float _3219 = _3216.x;\n    float _3221 = _3216.z;\n    vec2 e = vec2(_3219, _3221);\n    if (_3216.y < 0.0)\n    {\n        e = vec2((1.0 - abs(_3221)) * ((_3219 < 0.0) ? (-1.0) : 1.0), (1.0 - abs(_3219)) * ((_3221 < 0.0) ? (-1.0) : 1.0));\n    }\n    return e;\n}\n\nvec2 fa_atlas_size()\n{\n    return vec2(textureSize(fa_probe_atlas_fa_env_smp, 0));\n}\n\nvec3 fa_probe_level(vec2 origin, float res, int lv, vec2 e)\n{\n    float _3268;\n    if (lv == 0)\n    {\n        _3268 = 0.0;\n    }\n    else\n    {\n        _3268 = res + 2.0;\n    }\n    float _3278;\n    if (lv == 0)\n    {\n        _3278 = 0.0;\n    }\n    else\n    {\n        _3278 = (res - (res / float(1 << max((lv - 1), 0)))) + (2.0 * float(lv - 1));\n    }\n    return textureLod(fa_probe_atlas_fa_env_smp, (((origin + vec2(_3268, _3278)) + vec2(1.0)) + (((e * 0.5) + vec2(0.5)) * (res / float(1 << lv)))) / fa_atlas_size(), 0.0).xyz;\n}\n\nvec3 fa_probe_radiance(vec2 origin, float res, vec3 d, float rough)\n{\n    float _3324;\n    if (res > 64.5)\n    {\n        _3324 = 5.0;\n    }\n    else\n    {\n        _3324 = (res > 32.5) ? 4.0 : 3.0;\n    }\n    float _3339 = clamp(rough, 0.0, 1.0) * (_3324 - 1.0);\n    int _3346 = int(min(floor(_3339), _3324 - 2.0));\n    float _3351 = _3339 - float(_3346);\n    vec3 param = d;\n    vec2 _3355 = fa_oct_encode(param);\n    vec2 param_1 = origin;\n    float param_2 = res;\n    int param_3 = _3346;\n    vec2 param_4 = _3355;\n    vec3 _3365 = fa_probe_level(param_1, param_2, param_3, param_4);\n    if (_3351 < 0.00200000009499490261077880859375)\n    {\n        return _3365;\n    }\n    vec2 param_5 = origin;\n    float param_6 = res;\n    int param_7 = _3346 + 1;\n    vec2 param_8 = _3355;\n    return mix(_3365, fa_probe_level(param_5, param_6, param_7, param_8), vec3(_3351));\n}\n\nvec3 fa_probe_box_dir(vec3 d, vec4 posw, vec4 bx, vec4 by, vec4 bz)\n{\n    if (posw.w < 0.5)\n    {\n        return d;\n    }\n    float _3403 = dot(bx.xyz, fa_world_pos) + bx.w;\n    float _3410 = dot(by.xyz, fa_world_pos) + by.w;\n    float _3417 = dot(bz.xyz, fa_world_pos) + bz.w;\n    float _3423 = dot(bx.xyz, d);\n    float _3427 = dot(by.xyz, d);\n    float _3431 = dot(bz.xyz, d);\n    float _3437;\n    if (_3423 > 9.9999999747524270787835121154785e-07)\n    {\n        _3437 = (1.0 - _3403) / _3423;\n    }\n    else\n    {\n        float _3451;\n        if (_3423 < (-9.9999999747524270787835121154785e-07))\n        {\n            _3451 = ((-1.0) - _3403) / _3423;\n        }\n        else\n        {\n            _3451 = 1000000015047466219876688855040.0;\n        }\n        _3437 = _3451;\n    }\n    float tx = _3437;\n    float _3468;\n    if (_3427 > 9.9999999747524270787835121154785e-07)\n    {\n        _3468 = (1.0 - _3410) / _3427;\n    }\n    else\n    {\n        float _3481;\n        if (_3427 < (-9.9999999747524270787835121154785e-07))\n        {\n            _3481 = ((-1.0) - _3410) / _3427;\n        }\n        else\n        {\n            _3481 = 1000000015047466219876688855040.0;\n        }\n        _3468 = _3481;\n    }\n    float ty = _3468;\n    float _3497;\n    if (_3431 > 9.9999999747524270787835121154785e-07)\n    {\n        _3497 = (1.0 - _3417) / _3431;\n    }\n    else\n    {\n        float _3510;\n        if (_3431 < (-9.9999999747524270787835121154785e-07))\n        {\n            _3510 = ((-1.0) - _3417) / _3431;\n        }\n        else\n        {\n            _3510 = 1000000015047466219876688855040.0;\n        }\n        _3497 = _3510;\n    }\n    float _3522 = tx;\n    float _3525 = (_3522 > 0.0) ? _3522 : 1000000015047466219876688855040.0;\n    tx = _3525;\n    float _3526 = ty;\n    float _3529 = (_3526 > 0.0) ? _3526 : 1000000015047466219876688855040.0;\n    ty = _3529;\n    float _3539 = min(_3525, min(_3529, (_3497 > 0.0) ? _3497 : 1000000015047466219876688855040.0));\n    if (_3539 > 100000001504746621987668885504.0)\n    {\n        return d;\n    }\n    vec3 _3555 = (fa_world_pos + (d * _3539)) - posw.xyz;\n    vec3 _3560;\n    if (dot(_3555, _3555) > 1.0000000133514319600180897396058e-10)\n    {\n        _3560 = normalize(_3555);\n    }\n    else\n    {\n        _3560 = d;\n    }\n    return _3560;\n}\n\nvec3 fa_probe_environment(vec4 tile, vec4 posw, vec4 bx, vec4 by, vec4 bz, inout vec3 d, float rough)\n{\n    vec3 param = d;\n    vec4 param_1 = posw;\n    vec4 param_2 = bx;\n    vec4 param_3 = by;\n    vec4 param_4 = bz;\n    d = fa_probe_box_dir(param, param_1, param_2, param_3, param_4);\n    vec2 param_5 = tile.xy;\n    float param_6 = tile.z;\n    vec3 param_7 = d;\n    float param_8 = rough;\n    return fa_probe_radiance(param_5, param_6, param_7, param_8);\n}\n\nvec3 fa_environment(vec3 d, float rough)\n{\n    float _3606 = (1.0 - fa_mesh_fs_params[42].w) - fa_mesh_fs_params[47].w;\n    vec3 outc = vec3(0.0);\n    if (_3606 > 0.0005000000237487256526947021484375)\n    {\n        vec3 base;\n        if (fa_mesh_fs_params[11].w > 0.5)\n        {\n            vec2 param = fa_mesh_fs_params[41].zw;\n            float param_1 = 128.0;\n            vec3 param_2 = d;\n            float param_3 = rough;\n            base = fa_probe_radiance(param, param_1, param_2, param_3);\n        }\n        else\n        {\n            float _3636 = rough * rough;\n            float _3667 = 0.60000002384185791015625 * _3636;\n            base = mix(mix(fa_mesh_fs_params[12].xyz * 0.550000011920928955078125, mix(fa_mesh_fs_params[12].xyz, fa_mesh_fs_params[11].xyz, vec3(pow(clamp(d.y * (1.0 - (0.699999988079071044921875 * _3636)), 0.0, 1.0), 0.550000011920928955078125))), vec3(smoothstep((-0.0500000007450580596923828125) - _3667, 0.0500000007450580596923828125 + _3667, d.y))), ((fa_mesh_fs_params[11].xyz + fa_mesh_fs_params[12].xyz) * 0.5) * 0.800000011920928955078125, vec3(_3636 * 0.60000002384185791015625));\n        }\n        outc = base * _3606;\n    }\n    if (fa_mesh_fs_params[42].w > 0.0)\n    {\n        vec4 param_4 = fa_mesh_fs_params[42];\n        vec4 param_5 = fa_mesh_fs_params[43];\n        vec4 param_6 = fa_mesh_fs_params[44];\n        vec4 param_7 = fa_mesh_fs_params[45];\n        vec4 param_8 = fa_mesh_fs_params[46];\n        vec3 param_9 = d;\n        float param_10 = rough;\n        vec3 _3726 = fa_probe_environment(param_4, param_5, param_6, param_7, param_8, param_9, param_10);\n        outc += (_3726 * fa_mesh_fs_params[42].w);\n    }\n    if (fa_mesh_fs_params[47].w > 0.0)\n    {\n        vec4 param_11 = fa_mesh_fs_params[47];\n        vec4 param_12 = fa_mesh_fs_params[48];\n        vec4 param_13 = fa_mesh_fs_params[49];\n        vec4 param_14 = fa_mesh_fs_params[50];\n        vec4 param_15 = fa_mesh_fs_params[51];\n        vec3 param_16 = d;\n        float param_17 = rough;\n        vec3 _3758 = fa_probe_environment(param_11, param_12, param_13, param_14, param_15, param_16, param_17);\n        outc += (_3758 * fa_mesh_fs_params[47].w);\n    }\n    return outc;\n}\n\nvec3 fa_layers_ibl(FaLayers L, vec3 n, vec3 v, vec3 f0, float roughness, float occlusion)\n{\n    vec3 rn = n;\n    if (L.aniso != 0.0)\n    {\n        vec3 _4260;\n        if (L.aniso >= 0.0)\n        {\n            _4260 = L.b;\n        }\n        else\n        {\n            _4260 = L.t;\n        }\n        rn = normalize(mix(n, cross(cross(_4260, v), _4260), vec3(abs(L.aniso) * smoothstep(0.0, 0.25, roughness))));\n    }\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05);\n    vec2 _4296 = fa_env_brdf(param, param_1);\n    vec3 param_2 = reflect(-v, rn);\n    float param_3 = roughness;\n    vec3 result = (fa_environment(param_2, param_3) * ((f0 * _4296.x) + (vec3(L.f90) * _4296.y))) * L.base_scale;\n    if (L.sheen_on)\n    {\n        vec3 param_4 = n;\n        float param_5 = L.sheen_rough;\n        result += ((L.sheen * (L.sheen_e * L.keep)) * fa_environment(param_4, param_5));\n    }\n    result *= occlusion;\n    if (L.coat > 0.0)\n    {\n        float param_6 = L.coat_rough;\n        float param_7 = L.coat_ndv;\n        vec2 _4354 = fa_env_brdf(param_6, param_7);\n        vec3 param_8 = reflect(-v, L.nc);\n        float param_9 = L.coat_rough;\n        result += (fa_environment(param_8, param_9) * (L.coat * ((0.039999999105930328369140625 * _4354.x) + _4354.y)));\n    }\n    return result;\n}\n\nvec3 fa_sky_reflection(vec3 n, vec3 v, vec3 f0, float roughness)\n{\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05);\n    vec2 _3823 = fa_env_brdf(param, param_1);\n    vec3 param_2 = reflect(-v, n);\n    float param_3 = roughness;\n    return fa_environment(param_2, param_3) * ((f0 * _3823.x) + vec3(_3823.y));\n}\n\nvec3 fa_sky_light(SurfaceInput i, Surface s)\n{\n    float _4393 = clamp(s.metallic, 0.0, 1.0);\n    float _4397 = clamp(s.roughness, 0.0500000007450580596923828125, 1.0);\n    vec3 _4404 = mix(vec3(0.039999999105930328369140625), s.albedo, vec3(_4393));\n    vec3 f0 = _4404;\n    vec3 _4408 = normalize(s.normal);\n    SurfaceInput param = i;\n    Surface param_1 = s;\n    vec3 param_2 = _4408;\n    vec3 param_3 = i.view_dir;\n    float param_4 = _4393;\n    float param_5 = _4397;\n    vec3 param_6 = _4404;\n    FaLayers _4425 = fa_layers_setup(param, param_1, param_2, param_3, param_4, param_5, param_6);\n    f0 = param_6;\n    if (_4425.on)\n    {\n        FaLayers param_7 = _4425;\n        vec3 param_8 = _4408;\n        vec3 param_9 = i.view_dir;\n        vec3 param_10 = f0;\n        float param_11 = _4397;\n        float param_12 = s.occlusion;\n        return fa_layers_ibl(param_7, param_8, param_9, param_10, param_11, param_12);\n    }\n    vec3 param_13 = _4408;\n    vec3 param_14 = i.view_dir;\n    vec3 param_15 = f0;\n    float param_16 = _4397;\n    return fa_sky_reflection(param_13, param_14, param_15, param_16) * s.occlusion;\n}\n\nvec3 lighting(SurfaceInput i, Surface s)\n{\n    int best = -1;\n    float bestPower = 0.0;\n    for (int n = 0; n < fa_light_count(); n++)\n    {\n        int param = n;\n        SurfaceInput param_1 = i;\n        LightSample _5023 = fa_light_unshadowed(param, param_1);\n        float _5031 = dot(_5023.color, vec3(0.2989999949932098388671875, 0.58700001239776611328125, 0.114000000059604644775390625));\n        if (_5031 > bestPower)\n        {\n            bestPower = _5031;\n            best = n;\n        }\n    }\n    vec3 lit = (fa_mesh_fs_params[1].xyz * s.albedo) * s.occlusion;\n    if (best >= 0)\n    {\n        int param_2 = best;\n        SurfaceInput param_3 = i;\n        LightSample _5060 = fa_light(param_2, param_3);\n        float _5068;\n        if (dot(s.normal, _5060.direction) > 0.5)\n        {\n            _5068 = 1.0;\n        }\n        else\n        {\n            _5068 = fa_material[0].x;\n        }\n        lit += ((s.albedo * _5060.color) * _5068);\n    }\n    SurfaceInput param_4 = i;\n    Surface param_5 = s;\n    return lit + (fa_sky_light(param_4, param_5) * fa_material[1].x);\n}\n\nvec3 fa_shadow_debug(vec3 color, vec3 world)\n{\n    if (fa_shadows[27].w < 0.5)\n    {\n        return color;\n    }\n    int _3114 = int(fa_shadows[25].x + 0.5);\n    float _3124 = dot(world - fa_shadows[27].xyz, fa_shadows[28].xyz);\n    vec3 tint = vec3(0.3499999940395355224609375);\n    bool _3129 = _3114 > 0;\n    bool _3138;\n    if (_3129)\n    {\n        int param = _3114 - 1;\n        _3138 = _3124 <= fa_shadow_split_at(param);\n    }\n    else\n    {\n        _3138 = _3129;\n    }\n    if (_3138)\n    {\n        tint = vec3(1.0, 0.1500000059604644775390625, 0.100000001490116119384765625);\n        bool _3144 = _3114 > 1;\n        bool _3151;\n        if (_3144)\n        {\n            _3151 = _3124 > fa_shadows[24].x;\n        }\n        else\n        {\n            _3151 = _3144;\n        }\n        if (_3151)\n        {\n            tint = vec3(0.100000001490116119384765625, 0.89999997615814208984375, 0.20000000298023223876953125);\n        }\n        bool _3157 = _3114 > 2;\n        bool _3164;\n        if (_3157)\n        {\n            _3164 = _3124 > fa_shadows[24].y;\n        }\n        else\n        {\n            _3164 = _3157;\n        }\n        if (_3164)\n        {\n            tint = vec3(0.1500000059604644775390625, 0.300000011920928955078125, 1.0);\n        }\n        bool _3170 = _3114 > 3;\n        bool _3177;\n        if (_3170)\n        {\n            _3177 = _3124 > fa_shadows[24].z;\n        }\n        else\n        {\n            _3177 = _3170;\n        }\n        if (_3177)\n        {\n            tint = vec3(1.0, 0.89999997615814208984375, 0.100000001490116119384765625);\n        }\n    }\n    return mix(color, tint, vec3(0.550000011920928955078125));\n}\n\nvoid main()\n{\n    fa_inst_load();\n    vec3 _5792 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _5792 = -_5792;\n    }\n    vec3 _5461 = normalize(fa_mesh_fs_params[0].xyz - fa_world_pos);\n    vec3 param = fa_world_pos;\n    fa_cluster_begin(param);\n    SurfaceInput param_1 = SurfaceInput(fa_world_pos, _5792, fa_world_tangent, fa_uv, fa_vertex_color, _5461, gl_FrontFacing);\n    Surface _5469 = fa_standard_surface(param_1);\n    vec3 _5823 = _5469.albedo;\n    float _5824 = _5469.alpha;\n    vec3 _5825 = _5469.normal;\n    float _5826 = _5469.metallic;\n    float _5827 = _5469.roughness;\n    float _5828 = _5469.occlusion;\n    vec3 _5829 = _5469.emission;\n    float _5830 = _5469.clearcoat;\n    float _5831 = _5469.clearcoat_roughness;\n    vec3 _5832 = _5469.sheen_color;\n    float _5833 = _5469.sheen_roughness;\n    float _5834 = _5469.anisotropy;\n    float _5835 = _5469.anisotropy_rotation;\n    float _5836 = _5469.specular;\n    float _5837 = _5469.ior;\n    vec3 _5838 = _5469.specular_color;\n    float _5839 = _5469.transmission;\n    float _5840 = _5469.thickness;\n    vec3 _5841 = _5469.attenuation_color;\n    float _5842 = _5469.attenuation_distance;\n    SurfaceInput param_2 = SurfaceInput(fa_world_pos, _5792, fa_world_tangent, fa_uv, fa_vertex_color, _5461, gl_FrontFacing);\n    Surface param_3 = _5469;\n    surface(param_2, param_3);\n    _5823 = param_3.albedo;\n    _5824 = param_3.alpha;\n    _5825 = param_3.normal;\n    _5826 = param_3.metallic;\n    _5827 = param_3.roughness;\n    _5828 = param_3.occlusion;\n    _5829 = param_3.emission;\n    _5830 = param_3.clearcoat;\n    _5831 = param_3.clearcoat_roughness;\n    _5832 = param_3.sheen_color;\n    _5833 = param_3.sheen_roughness;\n    _5834 = param_3.anisotropy;\n    _5835 = param_3.anisotropy_rotation;\n    _5836 = param_3.specular;\n    _5837 = param_3.ior;\n    _5838 = param_3.specular_color;\n    _5839 = param_3.transmission;\n    _5840 = param_3.thickness;\n    _5841 = param_3.attenuation_color;\n    _5842 = param_3.attenuation_distance;\n    vec3 param_4 = fa_world_pos;\n    vec3 param_5 = _5792;\n    vec3 param_6 = param_3.albedo;\n    vec3 param_7 = param_3.normal;\n    fa_apply_decals(param_4, param_5, param_6, param_7);\n    _5823 = param_6;\n    _5825 = param_7;\n    fa_lod_dither();\n    vec3 result;\n    if (fa_mesh_fs_params[3].w > 0.5)\n    {\n        result = _5823;\n    }\n    else\n    {\n        vec3 _5509 = _5825;\n        vec3 _5510 = normalize(_5509);\n        _5825 = _5510;\n        SurfaceInput param_8 = SurfaceInput(fa_world_pos, _5792, fa_world_tangent, fa_uv, fa_vertex_color, _5461, gl_FrontFacing);\n        Surface param_9 = Surface(_5823, _5824, _5510, _5826, _5827, _5828, _5829, _5830, _5831, _5832, _5833, _5834, _5835, _5836, _5837, _5838, _5839, _5840, _5841, _5842);\n        vec3 _5521 = lighting(param_8, param_9);\n        result = _5521;\n    }\n    vec3 _5525 = result;\n    vec3 _5526 = _5525 + _5829;\n    result = _5526;\n    vec3 param_10 = _5526;\n    vec3 param_11 = fa_world_pos;\n    result = fa_shadow_debug(param_10, param_11);\n    bool _5535 = fa_mesh_fs_params[7].w > 0.0;\n    bool _5542;\n    if (!_5535)\n    {\n        _5542 = fa_mesh_fs_params[8].y > 0.0;\n    }\n    else\n    {\n        _5542 = _5535;\n    }\n    if (_5542)\n    {\n        vec3 _5551 = fa_world_pos - fa_mesh_fs_params[0].xyz;\n        float _5557 = dot(_5551, fa_mesh_fs_params[9].xyz);\n        bool _5561 = fa_mesh_fs_params[9].w > 0.5;\n        float _5562;\n        if (_5561)\n        {\n            _5562 = _5557;\n        }\n        else\n        {\n            _5562 = length(_5551);\n        }\n        float _5574 = _5562 - fa_mesh_fs_params[8].x;\n        if (_5574 > 0.0)\n        {\n            float _5583 = fa_mesh_fs_params[7].w * _5574;\n            float tau = _5583 * _5583;\n            if (fa_mesh_fs_params[8].y > 0.0)\n            {\n                float _5599;\n                if (_5561)\n                {\n                    _5599 = fa_world_pos.y - (fa_mesh_fs_params[9].y * _5557);\n                }\n                else\n                {\n                    _5599 = fa_mesh_fs_params[0].y;\n                }\n                float _5620 = mix(_5599, fa_world_pos.y, clamp(fa_mesh_fs_params[8].x / _5562, 0.0, 1.0));\n                float _5624 = fa_world_pos.y - _5620;\n                float _5629 = _5620 - fa_mesh_fs_params[8].z;\n                float _5634 = fa_world_pos.y - fa_mesh_fs_params[8].z;\n                bool _5637 = _5629 <= 0.0;\n                bool _5638 = !_5637;\n                bool _5644;\n                if (_5638)\n                {\n                    _5644 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _5644 = _5637;\n                }\n                float _5645;\n                if (_5644)\n                {\n                    _5645 = fa_mesh_fs_params[8].y;\n                }\n                else\n                {\n                    _5645 = fa_mesh_fs_params[8].y * exp(-min(fa_mesh_fs_params[8].w * _5629, 80.0));\n                }\n                bool _5672;\n                if (_5638)\n                {\n                    _5672 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _5672 = _5637;\n                }\n                float _5673;\n                if (_5672)\n                {\n                    _5673 = fa_mesh_fs_params[8].y * _5629;\n                }\n                else\n                {\n                    _5673 = (fa_mesh_fs_params[8].y * (1.0 - exp(-min(fa_mesh_fs_params[8].w * _5629, 80.0)))) / fa_mesh_fs_params[8].w;\n                }\n                bool _5698 = _5634 <= 0.0;\n                bool _5705;\n                if (!_5698)\n                {\n                    _5705 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _5705 = _5698;\n                }\n                float _5706;\n                if (_5705)\n                {\n                    _5706 = fa_mesh_fs_params[8].y * _5634;\n                }\n                else\n                {\n                    _5706 = (fa_mesh_fs_params[8].y * (1.0 - exp(-min(fa_mesh_fs_params[8].w * _5634, 80.0)))) / fa_mesh_fs_params[8].w;\n                }\n                float _5733;\n                if (abs(_5624) < 0.001000000047497451305389404296875)\n                {\n                    _5733 = _5645;\n                }\n                else\n                {\n                    _5733 = (_5706 - _5673) / _5624;\n                }\n                tau += (_5574 * max(_5733, 0.0));\n            }\n            result = mix(result, fa_mesh_fs_params[7].xyz, vec3(clamp(1.0 - exp(-clamp(tau, 0.0, 80.0)), 0.0, 1.0)));\n        }\n    }\n    fa_frag_color = vec4(result, _5824);\n}\n\n",
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
            "inst_name": "_420",
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
            "inst_name": "_2155",
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
            "inst_name": "_5074",
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
      "fs": "#version 430\n\nstruct SurfaceInput\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 vertex_color;\n    vec3 view_dir;\n    bool front_facing;\n};\n\nstruct LightSample\n{\n    vec3 direction;\n    vec3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct Surface\n{\n    vec3 albedo;\n    float alpha;\n    vec3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    vec3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    vec3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    vec3 specular_color;\n    float transmission;\n    float thickness;\n    vec3 attenuation_color;\n    float attenuation_distance;\n};\n\nstruct FaLayers\n{\n    bool on;\n    float f90;\n    float keep;\n    float base_scale;\n    float coat;\n    float coat_rough;\n    float coat_alpha;\n    float coat_a2;\n    vec3 nc;\n    float coat_ndv;\n    bool sheen_on;\n    vec3 sheen;\n    float sheen_rough;\n    float sheen_alpha;\n    float sheen_scale;\n    float sheen_e;\n    float aniso;\n    vec3 t;\n    vec3 b;\n    float at;\n    float ab;\n};\n\nconst float _3924[63] = float[](1.0, 1.0, 1.0, 0.4790000021457672119140625, 0.11699999868869781494140625, 0.01200000010430812835693359375, 0.0, 0.0, 0.0, 1.0, 1.0, 1.0, 0.578000009059906005859375, 0.19300000369548797607421875, 0.0350000001490116119384765625, 0.0030000000260770320892333984375, 0.0, 0.0, 1.0, 1.0, 1.0, 0.6740000247955322265625, 0.3459999859333038330078125, 0.1319999992847442626953125, 0.032999999821186065673828125, 0.0040000001899898052215576171875, 0.0, 0.971000015735626220703125, 0.954999983310699462890625, 0.828999996185302734375, 0.63999998569488525390625, 0.42599999904632568359375, 0.24500000476837158203125, 0.115000002086162567138671875, 0.037000000476837158203125, 0.0030000000260770320892333984375, 0.7469999790191650390625, 0.737999975681304931640625, 0.670000016689300537109375, 0.563000023365020751953125, 0.4309999942779541015625, 0.3039999902248382568359375, 0.1940000057220458984375, 0.1019999980926513671875, 0.0309999994933605194091796875, 0.614000022411346435546875, 0.609000027179718017578125, 0.566999971866607666015625, 0.499000012874603271484375, 0.412000000476837158203125, 0.32400000095367431640625, 0.240999996662139892578125, 0.162000000476837158203125, 0.087999999523162841796875, 0.538999974727630615234375, 0.535000026226043701171875, 0.505999982357025146484375, 0.4569999873638153076171875, 0.393999993801116943359375, 0.328999996185302734375, 0.2660000026226043701171875, 0.203999996185302734375, 0.14200000464916229248046875);\n\nuniform vec4 fa_mesh_fs_params[53];\nuniform vec4 fa_shadows[30];\nuniform vec4 fa_material[2];\nlayout(binding = 0) uniform sampler2D fa_light_tex_fa_shadow_smp;\nlayout(binding = 1) uniform sampler2D fa_tex_fa_smp;\nlayout(binding = 2) uniform sampler2D fa_normal_tex_fa_smp;\nlayout(binding = 3) uniform sampler2D fa_mr_tex_fa_smp;\nlayout(binding = 4) uniform sampler2D fa_occlusion_tex_fa_smp;\nlayout(binding = 5) uniform sampler2D fa_emissive_tex_fa_smp;\nlayout(binding = 6) uniform sampler2D fa_decal_tex_fa_env_smp;\nlayout(binding = 7) uniform sampler2D fa_light_atlas_fa_env_smp;\nlayout(binding = 8) uniform sampler2D fa_shadow_tex_fa_shadow_smp;\nlayout(binding = 9) uniform sampler2D fa_screen_tex_fa_shadow_smp;\nlayout(binding = 10) uniform sampler2D fa_probe_atlas_fa_env_smp;\n\nlayout(location = 0) in vec3 fa_world_pos;\nlayout(location = 5) in vec3 fa_lm;\nlayout(location = 1) in vec3 fa_world_normal;\nlayout(location = 2) in vec4 fa_world_tangent;\nlayout(location = 3) in vec2 fa_uv;\nlayout(location = 4) in vec4 fa_vertex_color;\nlayout(location = 0) out vec4 fa_frag_color;\nvec3 fa_light_tint;\nbool fa_light_is_area;\nint fa_cl_ndir;\nint fa_cl_slot;\nint fa_cl_local;\n\nvoid fa_inst_load()\n{\n}\n\nvec4 fa_light_texel(int t)\n{\n    return texelFetch(fa_light_tex_fa_shadow_smp, ivec2(t & 1023, t >> 10), 0);\n}\n\nvec4 fa_cluster_texel(vec3 world_pos)\n{\n    bool _1437 = fa_mesh_fs_params[19].x < 0.0;\n    bool _1444;\n    if (!_1437)\n    {\n        _1444 = fa_mesh_fs_params[19].w < 1.0;\n    }\n    else\n    {\n        _1444 = _1437;\n    }\n    bool _1452;\n    if (!_1444)\n    {\n        _1452 = fa_mesh_fs_params[18].x < 1.0;\n    }\n    else\n    {\n        _1452 = _1444;\n    }\n    bool _1459;\n    if (!_1452)\n    {\n        _1459 = fa_mesh_fs_params[18].y < 1.0;\n    }\n    else\n    {\n        _1459 = _1452;\n    }\n    bool _1466;\n    if (!_1459)\n    {\n        _1466 = fa_mesh_fs_params[19].y < 1.0;\n    }\n    else\n    {\n        _1466 = _1459;\n    }\n    if (_1466)\n    {\n        return vec4(0.0);\n    }\n    vec4 _1476 = vec4(world_pos, 1.0);\n    float _1482 = dot(fa_mesh_fs_params[16], _1476);\n    if (!(_1482 > 9.9999999747524270787835121154785e-07))\n    {\n        return vec4(0.0);\n    }\n    vec2 _1504 = vec2(dot(fa_mesh_fs_params[14], _1476), dot(fa_mesh_fs_params[15], _1476)) / vec2(_1482);\n    int _1508 = int(fa_mesh_fs_params[18].x);\n    int _1512 = int(fa_mesh_fs_params[18].y);\n    int param = (int(fa_mesh_fs_params[19].x) + (((clamp(int(floor(log2(max(dot(fa_mesh_fs_params[17].xyz, world_pos) + fa_mesh_fs_params[17].w, fa_mesh_fs_params[18].w) / fa_mesh_fs_params[18].w) * fa_mesh_fs_params[18].z)), 0, int(fa_mesh_fs_params[19].y) - 1) * _1512) + clamp(int(floor(((_1504.y * 0.5) + 0.5) * fa_mesh_fs_params[18].y)), 0, _1512 - 1)) * _1508)) + clamp(int(floor(((_1504.x * 0.5) + 0.5) * fa_mesh_fs_params[18].x)), 0, _1508 - 1);\n    return fa_light_texel(param);\n}\n\nivec2 fa_cluster_lookup(vec3 world_pos)\n{\n    vec3 param = world_pos;\n    vec4 _1588 = fa_cluster_texel(param);\n    return ivec2(int(_1588.x), int(_1588.y));\n}\n\nvoid fa_cluster_begin(vec3 world_pos)\n{\n    fa_cl_ndir = int(fa_mesh_fs_params[19].z);\n    vec3 param = world_pos;\n    ivec2 _4758 = fa_cluster_lookup(param);\n    fa_cl_slot = _4758.x;\n    fa_cl_local = _4758.y;\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_linear_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvec3 fa_tex_fix(inout vec3 c, float mode)\n{\n    if (mode > 1.5)\n    {\n        vec3 param = c;\n        vec3 _5135 = fa_linear_to_srgb(param);\n        c = _5135;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            vec3 param_1 = c;\n            vec3 _5143 = fa_srgb_to_linear(param_1);\n            c = _5143;\n        }\n    }\n    return c;\n}\n\nvec3 fa_tangent_normal(SurfaceInput i, vec3 m)\n{\n    vec3 _350;\n    if (i.front_facing)\n    {\n        _350 = i.world_normal;\n    }\n    else\n    {\n        _350 = -i.world_normal;\n    }\n    vec3 _374 = normalize(i.world_tangent.xyz - (_350 * dot(_350, i.world_tangent.xyz)));\n    vec3 _402 = normalize(((_374 * m.x) + ((cross(_350, _374) * i.world_tangent.w) * m.y)) + (_350 * m.z));\n    vec3 _405;\n    if (i.front_facing)\n    {\n        _405 = _402;\n    }\n    else\n    {\n        _405 = -_402;\n    }\n    return _405;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    vec4 base_t = texture(fa_tex_fa_smp, i.uv);\n    float param = fa_mesh_fs_params[6].w;\n    float param_1 = 1.0;\n    vec3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    vec3 _5174 = fa_tex_fix(param_2, param_3);\n    vec4 _6314 = base_t;\n    _6314.x = _5174.x;\n    _6314.y = _5174.y;\n    _6314.z = _5174.z;\n    base_t = _6314;\n    vec4 _5188 = (_6314 * fa_mesh_fs_params[2]) * i.vertex_color;\n    vec3 _6120 = i.world_normal;\n    if (fa_mesh_fs_params[6].z > 0.5)\n    {\n        float param_4 = fa_mesh_fs_params[6].w;\n        float param_5 = 16.0;\n        vec3 param_6 = texture(fa_normal_tex_fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        vec3 _5220 = fa_tex_fix(param_6, param_7);\n        vec3 _5223 = (_5220 * 2.0) - vec3(1.0);\n        vec2 _5228 = _5223.xy * fa_mesh_fs_params[6].x;\n        vec3 _6322 = _5223;\n        _6322.x = _5228.x;\n        _6322.y = _5228.y;\n        SurfaceInput param_8 = i;\n        vec3 param_9 = _6322;\n        _6120 = fa_tangent_normal(param_8, param_9);\n    }\n    vec4 mrt = texture(fa_mr_tex_fa_smp, i.uv);\n    float param_10 = fa_mesh_fs_params[6].w;\n    float param_11 = 64.0;\n    vec3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    vec3 _5256 = fa_tex_fix(param_12, param_13);\n    vec4 _6325 = mrt;\n    _6325.x = _5256.x;\n    _6325.y = _5256.y;\n    _6325.z = _5256.z;\n    mrt = _6325;\n    vec4 _5284 = texture(fa_occlusion_tex_fa_smp, i.uv);\n    float param_14 = fa_mesh_fs_params[6].w;\n    float param_15 = 256.0;\n    vec3 param_16 = _5284.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    vec3 _5295 = fa_tex_fix(param_16, param_17);\n    float param_18 = fa_mesh_fs_params[6].w;\n    float param_19 = 4.0;\n    vec3 param_20 = texture(fa_emissive_tex_fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    vec3 _5325 = fa_tex_fix(param_20, param_21);\n    float _6125 = fa_mesh_fs_params[20].x;\n    float _6126 = fa_mesh_fs_params[20].y;\n    float _6129 = fa_mesh_fs_params[20].z;\n    float _6128 = fa_mesh_fs_params[21].w;\n    float _6131 = fa_mesh_fs_params[22].x;\n    if (fa_mesh_fs_params[22].z > 0.5)\n    {\n        if (mod(fa_mesh_fs_params[22].z, 2.0) > 0.5)\n        {\n            _6125 *= _5295.y;\n            _6126 *= _5295.z;\n            _6128 *= _5284.w;\n        }\n        if (fa_mesh_fs_params[22].z > 1.5)\n        {\n            _6129 *= mrt.x;\n            _6131 *= mrt.w;\n        }\n    }\n    return Surface(_5188.xyz, _5188.w, _6120, clamp(fa_mesh_fs_params[5].x * _5256.z, 0.0, 1.0), clamp(fa_mesh_fs_params[5].y * _5256.y, 0.0500000007450580596923828125, 1.0), 1.0 + (fa_mesh_fs_params[6].y * (_5295.x - 1.0)), fa_mesh_fs_params[3].xyz + (fa_mesh_fs_params[4].xyz * _5325), _6125, _6126, fa_mesh_fs_params[21].xyz, _6128, _6129, fa_mesh_fs_params[20].w, _6131, fa_mesh_fs_params[22].y, fa_mesh_fs_params[23].xyz, fa_mesh_fs_params[30].x, fa_mesh_fs_params[30].y, fa_mesh_fs_params[31].xyz, fa_mesh_fs_params[30].z);\n}\n\nvoid surface(SurfaceInput i, Surface s)\n{\n}\n\nvec4 fa_decal_tile(vec4 rect, vec2 uv, vec2 atlas, vec2 ddx, vec2 ddy)\n{\n    vec2 _1668 = rect.zw - rect.xy;\n    vec2 _1672 = _1668 * atlas;\n    vec2 _1676 = ddx * _1672;\n    vec2 _1680 = ddy * _1672;\n    return textureLod(fa_decal_tex_fa_env_smp, rect.xy + (clamp(uv, vec2(0.0), vec2(1.0)) * _1668), clamp(0.5 * log2(max(max(dot(_1676, _1676), dot(_1680, _1680)), 9.9999999392252902907785028219223e-09)), 0.0, 3.0));\n}\n\nvec3 fa_dc_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_dc_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvoid fa_apply_decals(vec3 world_pos, vec3 geo_normal, inout vec3 albedo, inout vec3 normal)\n{\n    bool _1713 = fa_mesh_fs_params[10].y < 0.5;\n    bool _1720;\n    if (!_1713)\n    {\n        _1720 = fa_mesh_fs_params[10].w < 0.5;\n    }\n    else\n    {\n        _1720 = _1713;\n    }\n    if (_1720)\n    {\n        return;\n    }\n    vec3 _1726 = dFdx(world_pos);\n    vec3 _1729 = dFdy(world_pos);\n    vec3 param = world_pos;\n    vec4 _1733 = fa_cluster_texel(param);\n    int _1737 = int(_1733.w);\n    if (_1737 < 1)\n    {\n        return;\n    }\n    int _1747 = int(fa_mesh_fs_params[10].y + 0.5);\n    int param_1 = _1747;\n    vec4 _1751 = fa_light_texel(param_1);\n    vec2 _1754 = _1751.yz;\n    int _1758 = int(_1751.w);\n    int param_2 = _1747 + 1;\n    vec4 _1763 = fa_light_texel(param_2);\n    float _1764 = _1763.x;\n    int _1770 = int(fa_mesh_fs_params[10].w + 0.5) - 1;\n    int _1774 = int(_1733.z);\n    vec3 _2039;\n    for (int k = 0; k < _1737; k++)\n    {\n        int _1787 = _1774 + k;\n        int param_3 = _1758 + (_1787 >> 2);\n        int _1804 = (_1747 + 2) + (int(fa_light_texel(param_3)[_1787 & 3]) * 7);\n        int param_4 = _1804 + 6;\n        vec4 _1809 = fa_light_texel(param_4);\n        if (((int(_1809.w + 0.5) >> _1770) & 1) == 0)\n        {\n            continue;\n        }\n        int param_5 = _1804;\n        vec4 _1824 = fa_light_texel(param_5);\n        int param_6 = _1804 + 1;\n        vec4 _1829 = fa_light_texel(param_6);\n        int param_7 = _1804 + 2;\n        vec4 _1834 = fa_light_texel(param_7);\n        vec3 _1837 = _1824.xyz;\n        float _1842 = dot(_1837, world_pos) + _1824.w;\n        vec3 _1844 = _1829.xyz;\n        float _1849 = dot(_1844, world_pos) + _1829.w;\n        vec3 _1851 = _1834.xyz;\n        float _1856 = dot(_1851, world_pos) + _1834.w;\n        bool _1861 = abs(_1842) > 0.5;\n        bool _1869;\n        if (!_1861)\n        {\n            _1869 = abs(_1849) > 0.5;\n        }\n        else\n        {\n            _1869 = _1861;\n        }\n        bool _1877;\n        if (!_1869)\n        {\n            _1877 = abs(_1856) > 0.5;\n        }\n        else\n        {\n            _1877 = _1869;\n        }\n        if (_1877)\n        {\n            continue;\n        }\n        float _1892 = clamp(dot(geo_normal, normalize(_1851)) * _1809.z, 0.0, 1.0);\n        if (_1892 <= 0.0)\n        {\n            continue;\n        }\n        float _1912 = (clamp((0.5 - abs(_1856)) * 10.0, 0.0, 1.0) * _1892) * _1809.x;\n        vec2 _1920 = vec2(_1842 + 0.5, 0.5 - _1849);\n        vec2 _1930 = vec2(dot(_1837, _1726), dot(_1844, _1726));\n        vec2 _1940 = vec2(dot(_1837, _1729), dot(_1844, _1729));\n        int param_8 = _1804 + 5;\n        vec4 _1945 = fa_light_texel(param_8);\n        int param_9 = _1804 + 3;\n        vec4 _1950 = fa_light_texel(param_9);\n        int param_10 = _1804 + 4;\n        vec4 _1955 = fa_light_texel(param_10);\n        float tex_a = 1.0;\n        vec3 col = _1945.xyz;\n        bool _1965 = _1950.z > _1950.x;\n        if (_1965)\n        {\n            vec4 param_11 = _1950;\n            vec2 param_12 = _1920;\n            vec2 param_13 = _1754;\n            vec2 param_14 = _1930;\n            vec2 param_15 = _1940;\n            vec4 tx = fa_decal_tile(param_11, param_12, param_13, param_14, param_15);\n            if ((_1764 > 0.5) && (_1764 < 1.5))\n            {\n                vec3 param_16 = tx.xyz;\n                vec3 _1991 = fa_dc_to_linear(param_16);\n                vec4 _6208 = tx;\n                _6208.x = _1991.x;\n                _6208.y = _1991.y;\n                _6208.z = _1991.z;\n                tx = _6208;\n            }\n            col *= tx.xyz;\n            tex_a = tx.w;\n        }\n        albedo = mix(albedo, col, vec3(clamp((_1912 * tex_a) * _1945.w, 0.0, 1.0)));\n        if (_1955.z > _1955.x)\n        {\n            vec4 param_17 = _1955;\n            vec2 param_18 = _1920;\n            vec2 param_19 = _1754;\n            vec2 param_20 = _1930;\n            vec2 param_21 = _1940;\n            vec4 _2035 = fa_decal_tile(param_17, param_18, param_19, param_20, param_21);\n            if (_1764 > 1.5)\n            {\n                vec3 param_22 = _2035.xyz;\n                vec3 _2045 = fa_dc_to_srgb(param_22);\n                _2039 = _2045;\n            }\n            else\n            {\n                _2039 = _2035.xyz;\n            }\n            vec3 _2054 = (_2039 * 2.0) - vec3(1.0);\n            vec2 _2059 = _2054.xy * _1809.y;\n            vec3 _2081 = (normalize(_1837) * _2059.x) + (normalize(_1844) * _2059.y);\n            vec3 _2084 = normalize(normal);\n            normal = normalize(mix(_2084, normalize((_2084 * max(_2054.z, 0.0500000007450580596923828125)) + (_2081 - (_2084 * dot(_2084, _2081)))), vec3(clamp(_1912 * (_1965 ? tex_a : 1.0), 0.0, 1.0))));\n        }\n    }\n}\n\nvoid fa_lod_dither()\n{\n    if (fa_mesh_fs_params[52].w != 0.0)\n    {\n        float _442 = fract(52.98291778564453125 * fract(dot(gl_FragCoord.xy, vec2(0.067110560834407806396484375, 0.005837149918079376220703125))));\n        bool _445;\n        if (fa_mesh_fs_params[52].w > 0.0)\n        {\n            _445 = _442 >= fa_mesh_fs_params[52].w;\n        }\n        else\n        {\n            _445 = _442 < (-fa_mesh_fs_params[52].w);\n        }\n        if (_445)\n        {\n            discard;\n        }\n    }\n}\n\nint fa_light_count()\n{\n    return fa_cl_ndir + fa_cl_local;\n}\n\nLightSample fa_no_light()\n{\n    return LightSample(vec3(0.0, 1.0, 0.0), vec3(0.0), 0.0, 1.0, 0.0, 0);\n}\n\nint fa_cluster_index(int slot, int n)\n{\n    int param = (int(fa_mesh_fs_params[19].x) + int(fa_mesh_fs_params[19].w)) + ((slot + n) >> 2);\n    vec4 t = fa_light_texel(param);\n    return int(t[(slot + n) & 3]);\n}\n\nint fa_cl_light(int n)\n{\n    if (n < fa_cl_ndir)\n    {\n        return n;\n    }\n    int param = fa_cl_slot;\n    int param_1 = n - fa_cl_ndir;\n    return fa_cluster_index(param, param_1);\n}\n\nint fa_light_base(int li)\n{\n    return li * ((fa_mesh_fs_params[1].w > 4.5) ? 8 : 4);\n}\n\nbool fa_light_baked(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 3;\n    return fa_light_texel(param_1).w > 0.5;\n}\n\nfloat fa_baked_keep(int li)\n{\n    float _4728;\n    if (fa_lm.z > 0.5)\n    {\n        _4728 = 0.0;\n    }\n    else\n    {\n        _4728 = 1.0 - clamp(fa_mesh_fs_params[32].w, 0.0, 1.0);\n    }\n    bool _4739 = _4728 < 1.0;\n    bool _4745;\n    if (_4739)\n    {\n        int param = li;\n        _4745 = fa_light_baked(param);\n    }\n    else\n    {\n        _4745 = _4739;\n    }\n    return _4745 ? _4728 : 1.0;\n}\n\nvec3 fa_area_point(vec3 c, vec3 axis, vec3 ru, vec3 uu, float hx, float hy, float shape, vec3 p, vec3 r)\n{\n    bool _686 = dot(r, r) > 0.5;\n    if (shape > 1.5)\n    {\n        vec3 _699 = (c - (ru * hx)) - p;\n        vec3 _705 = ru * (2.0 * hx);\n        float _711 = max(dot(_705, _705), 9.9999999392252902907785028219223e-09);\n        float _715 = dot(_699, _705);\n        float t = clamp((-_715) / _711, 0.0, 1.0);\n        if (_686)\n        {\n            float _730 = dot(r, _705);\n            float _736 = _711 - (_730 * _730);\n            if (abs(_736) > (9.9999997473787516355514526367188e-06 * _711))\n            {\n                t = clamp(((dot(r, _699) * _730) - _715) / _736, 0.0, 1.0);\n            }\n        }\n        return (p + _699) + (_705 * t);\n    }\n    vec3 q = p;\n    float _768 = dot(r, axis);\n    bool _776;\n    if (_686)\n    {\n        _776 = abs(_768) > 9.9999997473787516355514526367188e-05;\n    }\n    else\n    {\n        _776 = _686;\n    }\n    if (_776)\n    {\n        float _786 = dot(c - p, axis) / _768;\n        if (_786 > 0.0)\n        {\n            q = p + (r * _786);\n        }\n    }\n    vec3 _799 = q - c;\n    vec2 xy = vec2(dot(_799, ru), dot(_799, uu));\n    if (shape > 0.5)\n    {\n        float _814 = length(xy);\n        if (_814 > hx)\n        {\n            xy *= (hx / _814);\n        }\n    }\n    else\n    {\n        xy = clamp(xy, vec2(-hx, -hy), vec2(hx, hy));\n    }\n    return (c + (ru * xy.x)) + (uu * xy.y);\n}\n\nvec4 fa_atlas_fetch(vec2 texel)\n{\n    return textureLod(fa_light_atlas_fa_env_smp, texel / vec2(textureSize(fa_light_atlas_fa_env_smp, 0)), 0.0);\n}\n\nvec3 fa_cookie_sample(vec2 tile_origin, vec2 uv)\n{\n    vec2 param = (tile_origin + vec2(1.0)) + (clamp(uv, vec2(0.0), vec2(1.0)) * 254.0);\n    return fa_atlas_fetch(param).xyz;\n}\n\nfloat fa_ies_sample(vec2 tile_origin, vec3 d, vec3 axis, vec3 right, vec3 up)\n{\n    float _606 = dot(d, right);\n    float _610 = dot(d, up);\n    float _621;\n    if (((_606 * _606) + (_610 * _610)) > 1.0000000133514319600180897396058e-10)\n    {\n        _621 = atan(_610, _606) * 0.15915493667125701904296875;\n    }\n    else\n    {\n        _621 = 0.0;\n    }\n    vec2 param = tile_origin + vec2(1.0 + ((_621 - floor(_621)) * 64.0), 1.0 + (acos(clamp(dot(d, axis), -1.0, 1.0)) * 10.18591594696044921875));\n    return fa_atlas_fetch(param).x;\n}\n\nint fa_cube_face(vec3 d)\n{\n    vec3 _462 = abs(d);\n    float _464 = _462.x;\n    float _466 = _462.y;\n    bool _467 = _464 >= _466;\n    bool _475;\n    if (_467)\n    {\n        _475 = _464 >= _462.z;\n    }\n    else\n    {\n        _475 = _467;\n    }\n    int _476;\n    if (_475)\n    {\n        _476 = (d.x > 0.0) ? 0 : 1;\n    }\n    else\n    {\n        int _490;\n        if (_466 >= _462.z)\n        {\n            _490 = (d.y > 0.0) ? 2 : 3;\n        }\n        else\n        {\n            _490 = (d.z > 0.0) ? 4 : 5;\n        }\n        _476 = _490;\n    }\n    return _476;\n}\n\nvoid fa_cube_face_basis(int f, out vec3 fwd, out vec3 up)\n{\n    if (f == 0)\n    {\n        fwd = vec3(1.0, 0.0, 0.0);\n        up = vec3(0.0, 1.0, 0.0);\n    }\n    else\n    {\n        if (f == 1)\n        {\n            fwd = vec3(-1.0, 0.0, 0.0);\n            up = vec3(0.0, 1.0, 0.0);\n        }\n        else\n        {\n            if (f == 2)\n            {\n                fwd = vec3(0.0, 1.0, 0.0);\n                up = vec3(0.0, 0.0, 1.0);\n            }\n            else\n            {\n                if (f == 3)\n                {\n                    fwd = vec3(0.0, -1.0, 0.0);\n                    up = vec3(0.0, 0.0, -1.0);\n                }\n                else\n                {\n                    if (f == 4)\n                    {\n                        fwd = vec3(0.0, 0.0, 1.0);\n                        up = vec3(0.0, 1.0, 0.0);\n                    }\n                    else\n                    {\n                        fwd = vec3(0.0, 0.0, -1.0);\n                        up = vec3(0.0, 1.0, 0.0);\n                    }\n                }\n            }\n        }\n    }\n}\n\nLightSample fa_light_sample_n(int li, vec3 world_pos, vec3 n)\n{\n    int param = li;\n    int _852 = fa_light_base(param);\n    bool _856 = fa_mesh_fs_params[1].w > 4.5;\n    int param_1 = _852;\n    vec4 _860 = fa_light_texel(param_1);\n    int param_2 = _852 + 1;\n    vec4 _865 = fa_light_texel(param_2);\n    float _868 = _865.w;\n    float atten = 1.0;\n    float dist = 0.0;\n    fa_light_tint = vec3(1.0);\n    bool _880 = _856 && (_868 > 2.5);\n    fa_light_is_area = _880;\n    bool _882 = _868 < 0.5;\n    vec3 l;\n    if (_882)\n    {\n        l = normalize(_860.xyz);\n        if (_856)\n        {\n            int param_3 = _852 + 6;\n            vec4 _896 = fa_light_texel(param_3);\n            if (_896.z > 0.5)\n            {\n                int param_4 = _852 + 4;\n                vec4 _906 = fa_light_texel(param_4);\n                int param_5 = _852 + 5;\n                vec4 _911 = fa_light_texel(param_5);\n                vec2 param_6 = _896.xy;\n                vec2 param_7 = fract(vec2(dot(world_pos, _906.xyz) * _906.w, (-dot(world_pos, _911.xyz)) * _911.w) + vec2(0.5));\n                fa_light_tint = fa_cookie_sample(param_6, param_7);\n            }\n        }\n    }\n    else\n    {\n        vec3 _941 = _860.xyz;\n        vec3 _943 = _941 - world_pos;\n        vec3 to_light = _943;\n        float _946 = length(_943);\n        float reach = _946;\n        bool front = true;\n        if (_880)\n        {\n            int param_8 = _852 + 7;\n            reach = max(_946 - fa_light_texel(param_8).w, 0.0);\n            int param_9 = _852 + 4;\n            vec4 _970 = fa_light_texel(param_9);\n            int param_10 = _852 + 5;\n            vec4 _975 = fa_light_texel(param_10);\n            int param_11 = _852 + 6;\n            vec4 _980 = fa_light_texel(param_11);\n            float _981 = _980.w;\n            int param_12 = _852 + 2;\n            vec3 _988 = normalize(fa_light_texel(param_12).xyz);\n            bool _990 = _981 > 1.5;\n            bool _998;\n            if (!_990)\n            {\n                _998 = dot(_988, to_light) < 0.0;\n            }\n            else\n            {\n                _998 = _990;\n            }\n            front = _998;\n            vec3 r = vec3(0.0);\n            vec3 _1007 = fa_mesh_fs_params[0].xyz - world_pos;\n            bool _1011 = dot(n, n) > 0.5;\n            bool _1019;\n            if (_1011)\n            {\n                _1019 = dot(_1007, _1007) > 9.9999999600419720025001879548654e-13;\n            }\n            else\n            {\n                _1019 = _1011;\n            }\n            if (_1019)\n            {\n                r = reflect(-normalize(_1007), normalize(n));\n            }\n            vec3 param_13 = _941;\n            vec3 param_14 = _988;\n            vec3 param_15 = _970.xyz;\n            vec3 param_16 = _975.xyz;\n            float param_17 = _970.w;\n            float param_18 = _975.w;\n            float param_19 = _981;\n            vec3 param_20 = world_pos;\n            vec3 param_21 = r;\n            to_light = fa_area_point(param_13, param_14, param_15, param_16, param_17, param_18, param_19, param_20, param_21) - world_pos;\n        }\n        float _1055 = length(to_light);\n        dist = _1055;\n        l = to_light / vec3(max(_1055, 9.9999997473787516355514526367188e-05));\n        float _1069 = reach / max(_860.w, 0.001000000047497451305389404296875);\n        float _1075 = clamp(1.0 - (_1069 * _1069), 0.0, 1.0);\n        float _1077;\n        if (front)\n        {\n            _1077 = _1075 * _1075;\n        }\n        else\n        {\n            _1077 = 0.0;\n        }\n        atten = _1077;\n        bool _1088 = _868 < 2.5;\n        if ((_868 > 1.5) && _1088)\n        {\n            int param_22 = _852 + 2;\n            vec4 _1096 = fa_light_texel(param_22);\n            float _1106 = _1096.w;\n            int param_23 = _852 + 3;\n            vec4 _1111 = fa_light_texel(param_23);\n            float _1112 = _1111.x;\n            float cos_inner = _1112;\n            if (_1112 > 1.5)\n            {\n                cos_inner = mix(_1106, 1.0, 0.25);\n            }\n            atten *= smoothstep(_1106, cos_inner, dot(-l, normalize(_1096.xyz)));\n        }\n        if (_856 && (_868 < 1.5))\n        {\n            int param_24 = _852 + 6;\n            vec4 _1136 = fa_light_texel(param_24);\n            if (_1136.z > 0.5)\n            {\n                vec3 _1144 = -to_light;\n                int param_25 = _852 + 4;\n                int param_26 = _852 + 5;\n                vec3 _1158 = fa_light_texel(param_25).xyz;\n                vec3 _1162 = fa_light_texel(param_26).xyz;\n                vec3 _1171 = vec3(dot(_1144, _1158), dot(_1144, _1162), dot(_1144, cross(_1158, _1162)));\n                vec3 param_27 = _1171;\n                int _1175 = fa_cube_face(param_27);\n                int param_28 = _1175;\n                vec3 param_29;\n                vec3 param_30;\n                fa_cube_face_basis(param_28, param_29, param_30);\n                vec2 _1202 = vec2(dot(_1171, cross(param_29, param_30)), dot(_1171, param_30)) / vec2(max(dot(_1171, param_29), 9.9999997473787516355514526367188e-05));\n                int _1206 = _1175 / 3;\n                vec2 param_31 = _1136.xy + (vec2(float(_1175 - (_1206 * 3)), float(_1206)) * 256.0);\n                vec2 param_32 = vec2(0.5 + (0.5 * _1202.x), 0.5 - (0.5 * _1202.y));\n                fa_light_tint = fa_cookie_sample(param_31, param_32);\n            }\n            int param_33 = _852 + 7;\n            vec4 _1236 = fa_light_texel(param_33);\n            if (_1236.z > 0.5)\n            {\n                int param_34 = _852 + 2;\n                int param_35 = _852 + 4;\n                int param_36 = _852 + 5;\n                vec2 param_37 = _1236.xy;\n                vec3 param_38 = -l;\n                vec3 param_39 = normalize(fa_light_texel(param_34).xyz);\n                vec3 param_40 = fa_light_texel(param_35).xyz;\n                vec3 param_41 = fa_light_texel(param_36).xyz;\n                atten *= fa_ies_sample(param_37, param_38, param_39, param_40, param_41);\n            }\n        }\n        else\n        {\n            if (_856 && _1088)\n            {\n                int param_42 = _852 + 6;\n                vec4 _1283 = fa_light_texel(param_42);\n                int param_43 = _852 + 7;\n                vec4 _1288 = fa_light_texel(param_43);\n                bool _1291 = _1283.z > 0.5;\n                bool _1298;\n                if (!_1291)\n                {\n                    _1298 = _1288.z > 0.5;\n                }\n                else\n                {\n                    _1298 = _1291;\n                }\n                if (_1298)\n                {\n                    int param_44 = _852 + 2;\n                    vec4 _1305 = fa_light_texel(param_44);\n                    vec3 _1309 = normalize(_1305.xyz);\n                    int param_45 = _852 + 4;\n                    vec4 _1314 = fa_light_texel(param_45);\n                    int param_46 = _852 + 5;\n                    vec4 _1319 = fa_light_texel(param_46);\n                    if (_1291)\n                    {\n                        vec3 _1327 = -to_light;\n                        float _1334 = _1305.w;\n                        float _1350 = 0.5 / max(dot(_1327, _1309) * (sqrt(max(1.0 - (_1334 * _1334), 0.0)) / max(_1334, 0.001000000047497451305389404296875)), 9.9999997473787516355514526367188e-05);\n                        vec2 param_47 = _1283.xy;\n                        vec2 param_48 = vec2(0.5 + (dot(_1327, _1314.xyz) * _1350), 0.5 - (dot(_1327, _1319.xyz) * _1350));\n                        fa_light_tint = fa_cookie_sample(param_47, param_48);\n                    }\n                    if (_1288.z > 0.5)\n                    {\n                        vec2 param_49 = _1288.xy;\n                        vec3 param_50 = -l;\n                        vec3 param_51 = _1309;\n                        vec3 param_52 = _1314.xyz;\n                        vec3 param_53 = _1319.xyz;\n                        atten *= fa_ies_sample(param_49, param_50, param_51, param_52, param_53);\n                    }\n                }\n            }\n        }\n    }\n    vec3 _5926 = _865.xyz * atten;\n    if (_856)\n    {\n        _5926 *= fa_light_tint;\n    }\n    int _1419;\n    if (_882)\n    {\n        _1419 = 0;\n    }\n    else\n    {\n        _1419 = ((_868 > 1.5) && (_868 < 2.5)) ? 2 : 1;\n    }\n    return LightSample(l, _5926, atten, 1.0, dist, _1419);\n}\n\nLightSample fa_light_unshadowed(int n, SurfaceInput i)\n{\n    bool _4957 = n < 0;\n    bool _4964;\n    if (!_4957)\n    {\n        _4964 = n >= fa_light_count();\n    }\n    else\n    {\n        _4964 = _4957;\n    }\n    if (_4964)\n    {\n        return fa_no_light();\n    }\n    int param = n;\n    int _4972 = fa_cl_light(param);\n    int param_1 = _4972;\n    float _4976 = fa_baked_keep(param_1);\n    if (_4976 <= 0.0)\n    {\n        return fa_no_light();\n    }\n    int param_2 = _4972;\n    vec3 param_3 = i.world_pos;\n    vec3 param_4 = i.world_normal;\n    LightSample _4992 = fa_light_sample_n(param_2, param_3, param_4);\n    return LightSample(_4992.direction, _4992.color * _4976, _4992.attenuation * _4976, _4992.shadow, _4992._distance, _4992.type);\n}\n\nfloat fa_light_type(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 1;\n    return fa_light_texel(param_1).w;\n}\n\nfloat fa_shadow_depth(inout vec2 uv, vec4 rect)\n{\n    uv = clamp(uv, rect.xy, rect.zw);\n    return textureLod(fa_shadow_tex_fa_shadow_smp, uv, 0.0).x;\n}\n\nfloat fa_shadow_fetch(vec2 uv, vec4 rect, vec3 conv)\n{\n    vec2 param = uv;\n    vec4 param_1 = rect;\n    float _2202 = fa_shadow_depth(param, param_1);\n    float _2206;\n    if (conv.x < 0.5)\n    {\n        _2206 = _2202;\n    }\n    else\n    {\n        _2206 = (conv.y * conv.z) / (conv.z - (_2202 * (conv.z - conv.y)));\n    }\n    return _2206;\n}\n\nfloat fa_shadow_noise()\n{\n    return fract(52.98291778564453125 * fract(dot(gl_FragCoord.xy, vec2(0.067110560834407806396484375, 0.005837149918079376220703125))));\n}\n\nvec2 fa_shadow_vogel_turn(vec2 d)\n{\n    return vec2((d.x * (-0.737368881702423095703125)) - (d.y * 0.675490319728851318359375), (d.y * (-0.737368881702423095703125)) + (d.x * 0.675490319728851318359375));\n}\n\nfloat fa_shadow_filter(vec2 uv, vec4 rect, float zr, float texel_m, float unit, float reach, float plane, vec3 conv, int mode, float k)\n{\n    if (mode == 1)\n    {\n        vec2 param = uv;\n        vec4 param_1 = rect;\n        vec3 param_2 = conv;\n        return float(zr <= fa_shadow_fetch(param, param_1, param_2));\n    }\n    float _2252 = fa_shadow_noise() * 6.283185482025146484375;\n    vec2 _2258 = vec2(cos(_2252), sin(_2252));\n    vec2 dir = _2258;\n    float radius = 1.5;\n    if (mode == 2)\n    {\n        float _2267;\n        if (k < 0.0)\n        {\n            _2267 = (-k) / max(zr, 0.100000001490116119384765625);\n        }\n        else\n        {\n            _2267 = k;\n        }\n        float _2286 = clamp((_2267 * reach) / texel_m, 3.0, 12.0);\n        float sum = 0.0;\n        float cnt = 0.0;\n        for (int i = 0; i < 16; i++)\n        {\n            float _2305 = sqrt((float(i) + 0.5) * 0.0625) * _2286;\n            vec2 param_3 = uv + (dir * (fa_shadows[26].zw * _2305));\n            vec4 param_4 = rect;\n            vec3 param_5 = conv;\n            float _2319 = fa_shadow_fetch(param_3, param_4, param_5);\n            if (_2319 < (zr - (_2305 * plane)))\n            {\n                sum += _2319;\n                cnt += 1.0;\n            }\n            vec2 param_6 = dir;\n            dir = fa_shadow_vogel_turn(param_6);\n        }\n        if (cnt < 0.5)\n        {\n            return 1.0;\n        }\n        float _2347 = sum / cnt;\n        float _2357;\n        if (k < 0.0)\n        {\n            _2357 = (-k) / max(_2347, 0.0500000007450580596923828125);\n        }\n        else\n        {\n            _2357 = k;\n        }\n        radius = clamp(((max(zr - _2347, 0.0) * unit) * _2357) / texel_m, 1.5, 16.0);\n        dir = _2258;\n    }\n    float lit = 0.0;\n    int _2383 = (mode == 2) ? 24 : 16;\n    for (int i_1 = 0; i_1 < _2383; i_1++)\n    {\n        float _2402 = sqrt((float(i_1) + 0.5) / float(_2383)) * radius;\n        vec2 param_7 = uv + (dir * (fa_shadows[26].zw * _2402));\n        vec4 param_8 = rect;\n        vec3 param_9 = conv;\n        lit += float((zr - (_2402 * plane)) <= fa_shadow_fetch(param_7, param_8, param_9));\n        vec2 param_10 = dir;\n        dir = fa_shadow_vogel_turn(param_10);\n    }\n    return lit / float(_2383);\n}\n\nfloat fa_shadow_local(int li, vec3 lpos, vec3 world, vec3 n, vec3 l)\n{\n    bool _2607 = fa_mesh_fs_params[5].z < 0.5;\n    bool _2614;\n    if (!_2607)\n    {\n        _2614 = fa_shadows[29].x < 0.5;\n    }\n    else\n    {\n        _2614 = _2607;\n    }\n    if (_2614)\n    {\n        return 1.0;\n    }\n    int param = (int(fa_shadows[29].x + 0.5) - 1) + li;\n    vec4 _2627 = fa_light_texel(param);\n    float _2628 = _2627.x;\n    if (_2628 < 0.0)\n    {\n        return 1.0;\n    }\n    int _2637 = int(_2628 + 0.5);\n    int param_1 = _2637;\n    vec4 _2641 = fa_light_texel(param_1);\n    int param_2 = _2637 + 1;\n    vec4 _2646 = fa_light_texel(param_2);\n    float fade = 1.0;\n    float _2649 = _2641.y;\n    if (_2649 > 0.0)\n    {\n        float _2666 = 1.0 - smoothstep(0.75 * _2649, _2649, length(world - fa_shadows[27].xyz));\n        fade = _2666;\n        if (_2666 <= 0.0)\n        {\n            return 1.0;\n        }\n    }\n    int face = 0;\n    if (_2641.x > 1.5)\n    {\n        vec3 param_3 = world - lpos;\n        face = fa_cube_face(param_3);\n    }\n    int _2690 = (_2637 + 2) + (face * 6);\n    int param_4 = _2690;\n    int param_5 = _2690 + 1;\n    int param_6 = _2690 + 3;\n    vec4 _2704 = fa_light_texel(param_6);\n    int param_7 = _2690 + 4;\n    vec4 _2709 = fa_light_texel(param_7);\n    int param_8 = _2690 + 5;\n    vec4 _2714 = fa_light_texel(param_8);\n    float _2726 = _2714.x * max(dot(_2704, vec4(world, 1.0)), 0.001000000047497451305389404296875);\n    float _2731 = clamp(dot(n, l), 0.0, 1.0);\n    float _2754 = clamp(dot(n, _2704.xyz), -1.0, 1.0);\n    float _2773 = min(sqrt(1.0 - (_2754 * _2754)) / max(abs(dot(n, world - lpos)) / max(dot(_2704, vec4(world, 1.0)), 0.001000000047497451305389404296875), 0.20000000298023223876953125), 4.0);\n    float _2776 = _2646.y;\n    float _2778;\n    if (_2776 > 0.0)\n    {\n        _2778 = _2776;\n    }\n    else\n    {\n        _2778 = 1.5 * _2726;\n    }\n    vec4 _2798 = vec4(world + (n * (_2778 * sqrt(1.0 - (_2731 * _2731)))), 1.0);\n    float _2802 = dot(_2704, _2798);\n    float _2805 = _2714.y;\n    if (_2802 < _2805)\n    {\n        return 1.0;\n    }\n    vec2 _2820 = vec2(dot(fa_light_texel(param_4), _2798), dot(fa_light_texel(param_5), _2798)) / vec2(_2802);\n    float _2822 = _2820.x;\n    bool _2825 = _2822 < _2709.x;\n    bool _2834;\n    if (!_2825)\n    {\n        _2834 = _2822 > _2709.z;\n    }\n    else\n    {\n        _2834 = _2825;\n    }\n    bool _2843;\n    if (!_2834)\n    {\n        _2843 = _2820.y < _2709.y;\n    }\n    else\n    {\n        _2843 = _2834;\n    }\n    bool _2852;\n    if (!_2843)\n    {\n        _2852 = _2820.y > _2709.w;\n    }\n    else\n    {\n        _2852 = _2843;\n    }\n    if (_2852)\n    {\n        return 1.0;\n    }\n    float _2858 = _2646.x;\n    float _2860;\n    if (_2858 > 0.0)\n    {\n        _2860 = _2858;\n    }\n    else\n    {\n        _2860 = 1.5 * _2726;\n    }\n    vec2 param_9 = _2820;\n    vec4 param_10 = _2709;\n    float param_11 = _2802 - (_2860 * (1.0 + (0.5 * _2773)));\n    float param_12 = _2726;\n    float param_13 = 1.0;\n    float param_14 = _2714.z * 0.25;\n    float param_15 = (_2726 * min(_2773, 3.0)) * 0.5;\n    vec3 param_16 = vec3(1.0, _2805, _2714.z);\n    int param_17 = int(_2641.z + 0.5);\n    float param_18 = _2641.w;\n    return mix(1.0, fa_shadow_filter(param_9, param_10, param_11, param_12, param_13, param_14, param_15, param_16, param_17, param_18), fade);\n}\n\nfloat fa_shadow_split_at(int i)\n{\n    float _2145;\n    if (i == 0)\n    {\n        _2145 = fa_shadows[24].x;\n    }\n    else\n    {\n        float _2161;\n        if (i == 1)\n        {\n            _2161 = fa_shadows[24].y;\n        }\n        else\n        {\n            float _2169;\n            if (i == 2)\n            {\n                _2169 = fa_shadows[24].z;\n            }\n            else\n            {\n                _2169 = fa_shadows[24].w;\n            }\n            _2161 = _2169;\n        }\n        _2145 = _2161;\n    }\n    return _2145;\n}\n\nfloat fa_shadow_cascade(int ci, vec3 world, vec3 n, vec3 l)\n{\n    float _2448 = max(fa_shadows[ci * 1 + 20].y, 0.001000000047497451305389404296875);\n    float _2453 = clamp(dot(n, l), 0.0, 1.0);\n    float _2459 = sqrt(1.0 - (_2453 * _2453));\n    float _2467 = min(_2459 / max(_2453, 0.20000000298023223876953125), 4.0);\n    float _2472;\n    if (fa_shadows[26].y > 0.0)\n    {\n        _2472 = fa_shadows[26].y;\n    }\n    else\n    {\n        _2472 = 1.5 * fa_shadows[ci * 1 + 20].x;\n    }\n    vec4 _2497 = mat4(fa_shadows[ci * 4 + 0], fa_shadows[ci * 4 + 1], fa_shadows[ci * 4 + 2], fa_shadows[ci * 4 + 3]) * vec4(world + (n * (_2472 * _2459)), 1.0);\n    float _2504 = _2497.x;\n    bool _2507 = _2504 < fa_shadows[ci * 1 + 16].x;\n    bool _2516;\n    if (!_2507)\n    {\n        _2516 = _2504 > fa_shadows[ci * 1 + 16].z;\n    }\n    else\n    {\n        _2516 = _2507;\n    }\n    bool _2525;\n    if (!_2516)\n    {\n        _2525 = _2497.y < fa_shadows[ci * 1 + 16].y;\n    }\n    else\n    {\n        _2525 = _2516;\n    }\n    bool _2534;\n    if (!_2525)\n    {\n        _2534 = _2497.y > fa_shadows[ci * 1 + 16].w;\n    }\n    else\n    {\n        _2534 = _2525;\n    }\n    bool _2541;\n    if (!_2534)\n    {\n        _2541 = _2497.z > 1.0;\n    }\n    else\n    {\n        _2541 = _2534;\n    }\n    if (_2541)\n    {\n        return -1.0;\n    }\n    float _2549;\n    if (fa_shadows[26].x > 0.0)\n    {\n        _2549 = fa_shadows[26].x;\n    }\n    else\n    {\n        _2549 = 1.5 * fa_shadows[ci * 1 + 20].x;\n    }\n    vec2 param = _2497.xy;\n    vec4 param_1 = fa_shadows[ci * 1 + 16];\n    float param_2 = _2497.z - ((_2549 * (1.0 + (0.5 * _2467))) / _2448);\n    float param_3 = fa_shadows[ci * 1 + 20].x;\n    float param_4 = _2448;\n    float param_5 = _2448 * 0.25;\n    float param_6 = ((fa_shadows[ci * 1 + 20].x * min(_2467, 3.0)) * 0.5) / _2448;\n    vec3 param_7 = vec3(0.0);\n    int param_8 = int(fa_shadows[25].z + 0.5);\n    float param_9 = fa_shadows[25].w;\n    return fa_shadow_filter(param, param_1, param_2, param_3, param_4, param_5, param_6, param_7, param_8, param_9);\n}\n\nfloat fa_shadow_sun(vec3 world, vec3 n, vec3 l)\n{\n    if (fa_mesh_fs_params[5].z < 0.5)\n    {\n        return 1.0;\n    }\n    int _2927 = int(fa_shadows[25].x + 0.5);\n    if (_2927 < 1)\n    {\n        return 1.0;\n    }\n    float _2942 = dot(world - fa_shadows[27].xyz, fa_shadows[28].xyz);\n    int param = _2927 - 1;\n    if (_2942 > fa_shadow_split_at(param))\n    {\n        return 1.0;\n    }\n    int ci = 0;\n    bool _2954 = _2927 > 1;\n    bool _2961;\n    if (_2954)\n    {\n        _2961 = _2942 > fa_shadows[24].x;\n    }\n    else\n    {\n        _2961 = _2954;\n    }\n    if (_2961)\n    {\n        ci = 1;\n    }\n    bool _2965 = _2927 > 2;\n    bool _2972;\n    if (_2965)\n    {\n        _2972 = _2942 > fa_shadows[24].y;\n    }\n    else\n    {\n        _2972 = _2965;\n    }\n    if (_2972)\n    {\n        ci = 2;\n    }\n    bool _2976 = _2927 > 3;\n    bool _2983;\n    if (_2976)\n    {\n        _2983 = _2942 > fa_shadows[24].z;\n    }\n    else\n    {\n        _2983 = _2976;\n    }\n    if (_2983)\n    {\n        ci = 3;\n    }\n    float s = -1.0;\n    float s2 = -1.0;\n    float t = 0.0;\n    int _2994 = min(_2927, 4);\n    float _3035;\n    for (int c = ci; c < _2994; c++)\n    {\n        int param_1 = c;\n        vec3 param_2 = world;\n        vec3 param_3 = n;\n        vec3 param_4 = l;\n        float _3014 = fa_shadow_cascade(param_1, param_2, param_3, param_4);\n        if (s >= 0.0)\n        {\n            s2 = _3014;\n            break;\n        }\n        if (_3014 < 0.0)\n        {\n            continue;\n        }\n        s = _3014;\n        ci = c;\n        if (fa_shadows[25].y > 0.0)\n        {\n            if (ci > 0)\n            {\n                int param_5 = ci - 1;\n                _3035 = fa_shadow_split_at(param_5);\n            }\n            else\n            {\n                _3035 = fa_shadows[28].w;\n            }\n            int param_6 = ci;\n            float _3054 = fa_shadows[25].y * max(fa_shadow_split_at(param_6) - _3035, 9.9999997473787516355514526367188e-05);\n            int param_7 = ci;\n            t = clamp((_2942 - (fa_shadow_split_at(param_7) - _3054)) / _3054, 0.0, 1.0);\n        }\n        if (t <= 0.0)\n        {\n            break;\n        }\n    }\n    if (s < 0.0)\n    {\n        return 1.0;\n    }\n    if (t > 0.0)\n    {\n        float _3086;\n        if ((ci + 1) < _2927)\n        {\n            _3086 = (s2 < 0.0) ? s : s2;\n        }\n        else\n        {\n            _3086 = 1.0;\n        }\n        s = mix(s, _3086, t);\n    }\n    return s;\n}\n\nfloat fa_shadow_factor(vec3 n, vec3 l)\n{\n    vec3 param = fa_world_pos;\n    vec3 param_1 = n;\n    vec3 param_2 = l;\n    return fa_shadow_sun(param, param_1, param_2);\n}\n\nfloat fa_contact_shadow(int li, vec3 world, vec3 gn, vec3 l, float dist)\n{\n    bool _4464 = fa_mesh_fs_params[24].x < 0.5;\n    bool _4471;\n    if (!_4464)\n    {\n        _4471 = fa_shadows[29].x < 0.5;\n    }\n    else\n    {\n        _4471 = _4464;\n    }\n    if (_4471)\n    {\n        return 1.0;\n    }\n    int param = (int(fa_shadows[29].x + 0.5) - 1) + li;\n    vec4 _4484 = fa_light_texel(param);\n    float _4485 = _4484.y;\n    float len = _4485;\n    if (_4485 <= 0.0)\n    {\n        return 1.0;\n    }\n    float _4497 = length(world - fa_mesh_fs_params[0].xyz);\n    float _4507 = 1.0 - smoothstep(0.5 * fa_mesh_fs_params[25].x, fa_mesh_fs_params[25].x, _4497);\n    if (_4507 <= 0.0)\n    {\n        return 1.0;\n    }\n    float _4513 = len;\n    float _4516 = min(_4513, 0.89999997615814208984375 * dist);\n    len = _4516;\n    float _4521 = 0.004999999888241291046142578125 + (0.0030000000260770320892333984375 * _4497);\n    float _4526 = _4521 + (0.5 * _4516);\n    vec3 _4532 = world + (gn * _4521);\n    float _4534 = fa_shadow_noise();\n    float occ = 0.0;\n    float _4598;\n    for (int k = 0; k < 12; k++)\n    {\n        float _4549 = (float(k) + _4534) * 0.083333335816860198974609375;\n        vec3 _4557 = _4532 + (l * (_4549 * len));\n        vec4 _4563 = vec4(_4557, 1.0);\n        float _4569 = dot(fa_mesh_fs_params[28], _4563);\n        if (_4569 < 9.9999997473787516355514526367188e-05)\n        {\n            break;\n        }\n        vec2 _4589 = vec2(dot(fa_mesh_fs_params[26], _4563), dot(fa_mesh_fs_params[27], _4563)) / vec2(_4569);\n        float _4593 = _4589.x * 0.5;\n        float _4594 = _4593 + 0.5;\n        if (fa_mesh_fs_params[24].y > 0.5)\n        {\n            _4598 = (_4589.y * 0.5) + 0.5;\n        }\n        else\n        {\n            _4598 = 0.5 - (_4589.y * 0.5);\n        }\n        bool _4614 = _4594 < 0.0;\n        bool _4621;\n        if (!_4614)\n        {\n            _4621 = _4594 >= 1.0;\n        }\n        else\n        {\n            _4621 = _4614;\n        }\n        bool _4628;\n        if (!_4621)\n        {\n            _4628 = _4598 < 0.0;\n        }\n        else\n        {\n            _4628 = _4621;\n        }\n        bool _4635;\n        if (!_4628)\n        {\n            _4635 = _4598 >= 1.0;\n        }\n        else\n        {\n            _4635 = _4628;\n        }\n        if (_4635)\n        {\n            break;\n        }\n        vec4 _4662 = texelFetch(fa_screen_tex_fa_shadow_smp, clamp(ivec2(vec2(_4594, _4598) * fa_mesh_fs_params[24].zw), ivec2(0), ivec2(fa_mesh_fs_params[24].zw) - ivec2(1)), 0);\n        if (_4662.w < 0.5)\n        {\n            continue;\n        }\n        float _4681 = (dot(fa_mesh_fs_params[29].xyz, _4557) + fa_mesh_fs_params[29].w) - _4662.x;\n        if ((_4681 > _4521) && (_4681 < _4526))\n        {\n            occ = max(occ, (1.0 - (_4549 * _4549)) * smoothstep(0.0, 0.0500000007450580596923828125, min(min(_4594, 0.5 - _4593), min(_4598, 1.0 - _4598))));\n        }\n    }\n    return 1.0 - (occ * _4507);\n}\n\nLightSample fa_light_shadowed(int li, vec3 world_pos, vec3 gn)\n{\n    int param = li;\n    float _4784 = fa_baked_keep(param);\n    if (_4784 <= 0.0)\n    {\n        int param_1 = li;\n        return LightSample(vec3(0.0, 1.0, 0.0), vec3(0.0), 0.0, 1.0, 0.0, int(fa_light_type(param_1) + 0.5));\n    }\n    int param_2 = li;\n    vec3 param_3 = world_pos;\n    vec3 param_4 = gn;\n    LightSample _4810 = fa_light_sample_n(param_2, param_3, param_4);\n    vec3 _6072 = _4810.color;\n    float _6073 = _4810.attenuation;\n    float _6074 = _4810.shadow;\n    bool _4813 = _4810.type == 0;\n    if (_4813 && (li == 0))\n    {\n        vec3 param_5 = gn;\n        vec3 param_6 = _4810.direction;\n        float _4824 = fa_shadow_factor(param_5, param_6);\n        _6074 = _4824;\n        _6072 *= _4824;\n    }\n    else\n    {\n        bool _4835 = _4810.type != 0;\n        bool _4841;\n        if (_4835)\n        {\n            _4841 = _6073 > 0.0;\n        }\n        else\n        {\n            _4841 = _4835;\n        }\n        if (_4841)\n        {\n            int param_7 = li;\n            int param_8 = fa_light_base(param_7);\n            int param_9 = li;\n            vec3 param_10 = fa_light_texel(param_8).xyz;\n            vec3 param_11 = world_pos;\n            vec3 param_12 = gn;\n            vec3 param_13 = _4810.direction;\n            float _4860 = fa_shadow_local(param_9, param_10, param_11, param_12, param_13);\n            _6074 = _4860;\n            _6072 *= _4860;\n        }\n    }\n    bool _4870 = fa_mesh_fs_params[24].x > 0.5;\n    bool _4876;\n    if (_4870)\n    {\n        _4876 = _6073 > 0.0;\n    }\n    else\n    {\n        _4876 = _4870;\n    }\n    if (_4876)\n    {\n        float _4883;\n        if (_4813)\n        {\n            _4883 = 1000000000.0;\n        }\n        else\n        {\n            _4883 = _4810._distance;\n        }\n        int param_14 = li;\n        vec3 param_15 = world_pos;\n        vec3 param_16 = gn;\n        vec3 param_17 = _4810.direction;\n        float param_18 = _4883;\n        float _4901 = fa_contact_shadow(param_14, param_15, param_16, param_17, param_18);\n        _6074 *= _4901;\n        _6072 *= _4901;\n    }\n    float _4914 = _6073;\n    float _4915 = _4914 * _4784;\n    _6073 = _4915;\n    vec3 _4919 = _6072;\n    vec3 _4920 = _4919 * _4784;\n    _6072 = _4920;\n    return LightSample(_4810.direction, _4920, _4915, _6074, _4810._distance, _4810.type);\n}\n\nLightSample fa_light(int n, SurfaceInput i)\n{\n    bool _4931 = n < 0;\n    bool _4938;\n    if (!_4931)\n    {\n        _4938 = n >= fa_light_count();\n    }\n    else\n    {\n        _4938 = _4931;\n    }\n    if (_4938)\n    {\n        return fa_no_light();\n    }\n    int param = n;\n    int param_1 = fa_cl_light(param);\n    vec3 param_2 = i.world_pos;\n    vec3 param_3 = i.world_normal;\n    LightSample _4953 = fa_light_shadowed(param_1, param_2, param_3);\n    return _4953;\n}\n\nfloat fa_sheen_albedo(float ndv, float rough)\n{\n    float _3849 = min(sqrt(max(rough - 0.100000001490116119384765625, 0.0) * 1.111111164093017578125) * 6.0, 5.999000072479248046875);\n    float _3857 = min(sqrt(clamp(ndv, 0.0, 1.0)) * 8.0, 7.999000072479248046875);\n    int _3860 = int(_3849);\n    int _3863 = int(_3857);\n    float _3873 = _3857 - float(_3863);\n    int _3929 = (_3860 * 9) + _3863;\n    int _3949 = ((_3860 + 1) * 9) + _3863;\n    return mix(mix(_3924[_3929], _3924[_3929 + 1], _3873), mix(_3924[_3949], _3924[_3949 + 1], _3873), _3849 - float(_3860));\n}\n\nFaLayers fa_layers_setup(SurfaceInput i, Surface s, vec3 n, vec3 v, float metallic, float roughness, inout vec3 f0)\n{\n    bool _5938 = false;\n    float _5939 = 1.0;\n    float _5940 = 1.0;\n    float _5941 = 1.0;\n    float _5942 = 0.0;\n    float _5943 = 0.0;\n    float _5944 = 0.0;\n    float _5945 = 0.0;\n    float _5947 = 1.0;\n    bool _5948 = false;\n    vec3 _5949 = vec3(0.0);\n    float _5950 = 1.0;\n    float _5951 = 1.0;\n    float _5952 = 1.0;\n    float _5953 = 0.0;\n    float _5954 = 0.0;\n    vec3 _5955 = vec3(1.0, 0.0, 0.0);\n    vec3 _5956 = vec3(0.0, 0.0, 1.0);\n    float _5957 = 1.0;\n    float _5958 = 1.0;\n    float _4000 = clamp(s.specular, 0.0, 1.0);\n    float _4004 = clamp(s.ior, 1.0, 3.0);\n    bool _4009 = (_4000 != 1.0) || (_4004 != 1.5);\n    bool _4018;\n    if (!_4009)\n    {\n        _4018 = any(notEqual(s.specular_color, vec3(1.0)));\n    }\n    else\n    {\n        _4018 = _4009;\n    }\n    if (_4018)\n    {\n        float _4026 = (_4004 - 1.0) / (_4004 + 1.0);\n        f0 = mix(min(vec3(_4026 * _4026) * max(s.specular_color, vec3(0.0)), vec3(1.0)) * _4000, s.albedo, vec3(metallic));\n        _5939 = mix(_4000, 1.0, metallic);\n        _5938 = true;\n    }\n    float _4053 = clamp(s.clearcoat, 0.0, 1.0);\n    if (_4053 > 0.0)\n    {\n        float _4061 = clamp(s.clearcoat_roughness, 0.0500000007450580596923828125, 1.0);\n        _5942 = _4053;\n        _5943 = _4061;\n        float _4068 = _4061 * _4061;\n        _5944 = _4068;\n        _5945 = _4068 * _4068;\n        float _4080 = max(dot(i.world_normal, v), 9.9999997473787516355514526367188e-05);\n        _5947 = _4080;\n        _5940 = 1.0 - (_4053 * (0.039999999105930328369140625 + (0.959999978542327880859375 * pow(clamp(1.0 - _4080, 0.0, 1.0), 5.0))));\n        _5938 = true;\n    }\n    vec3 _4099 = max(s.sheen_color, vec3(0.0));\n    float _4108 = max(_4099.x, max(_4099.y, _4099.z));\n    if (_4108 > 0.0)\n    {\n        float _4116 = clamp(s.sheen_roughness, 0.100000001490116119384765625, 1.0);\n        _5948 = true;\n        _5949 = _4099;\n        _5950 = _4116;\n        _5951 = _4116 * _4116;\n        float param = max(dot(n, v), 9.9999997473787516355514526367188e-05);\n        float param_1 = _4116;\n        float _4133 = fa_sheen_albedo(param, param_1);\n        _5953 = _4133;\n        _5952 = 1.0 - min(_4108 * _4133, 1.0);\n        _5938 = true;\n    }\n    _5941 = _5940 * _5952;\n    float _4152 = clamp(s.anisotropy, -1.0, 1.0);\n    if (_4152 != 0.0)\n    {\n        vec3 _4167 = i.world_tangent.xyz - (n * dot(n, i.world_tangent.xyz));\n        vec3 t = _4167;\n        if (dot(_4167, _4167) < 9.9999999392252902907785028219223e-09)\n        {\n            bvec3 _4179 = bvec3(abs(n.y) < 0.9900000095367431640625);\n            t = cross(vec3(_4179.x ? vec3(0.0, 1.0, 0.0).x : vec3(1.0, 0.0, 0.0).x, _4179.y ? vec3(0.0, 1.0, 0.0).y : vec3(1.0, 0.0, 0.0).y, _4179.z ? vec3(0.0, 1.0, 0.0).z : vec3(1.0, 0.0, 0.0).z), n);\n        }\n        vec3 _4183 = t;\n        vec3 _4184 = normalize(_4183);\n        t = _4184;\n        vec3 _4209 = normalize((_4184 * cos(s.anisotropy_rotation)) + ((cross(n, _4184) * ((i.world_tangent.w < 0.0) ? (-1.0) : 1.0)) * sin(s.anisotropy_rotation)));\n        _5955 = _4209;\n        _5956 = cross(n, _4209);\n        float _4219 = roughness * roughness;\n        float _4225 = mix(_4219, 1.0, _4152 * _4152);\n        bool _4227 = _4152 > 0.0;\n        _5957 = _4227 ? _4225 : _4219;\n        _5958 = _4227 ? _4219 : _4225;\n        _5954 = _4152;\n        _5938 = true;\n    }\n    return FaLayers(_5938, _5939, _5940, _5941, _5942, _5943, _5944, _5945, i.world_normal, _5947, _5948, _5949, _5950, _5951, _5952, _5953, _5954, _5955, _5956, _5957, _5958);\n}\n\nvec2 fa_env_brdf(float rough, float ndv)\n{\n    vec4 _3781 = (vec4(-1.0, -0.0274999998509883880615234375, -0.572000026702880859375, 0.02199999988079071044921875) * rough) + vec4(1.0, 0.0425000004470348358154296875, 1.03999996185302734375, -0.039999999105930328369140625);\n    float _3784 = _3781.x;\n    return (vec2(-1.03999996185302734375, 1.03999996185302734375) * ((min(_3784 * _3784, exp2((-9.27999973297119140625) * ndv)) * _3784) + _3781.y)) + _3781.zw;\n}\n\nvec2 fa_oct_encode(vec3 d)\n{\n    vec3 _3216 = d / vec3(max((abs(d.x) + abs(d.y)) + abs(d.z), 9.9999999600419720025001879548654e-13));\n    float _3219 = _3216.x;\n    float _3221 = _3216.z;\n    vec2 e = vec2(_3219, _3221);\n    if (_3216.y < 0.0)\n    {\n        e = vec2((1.0 - abs(_3221)) * ((_3219 < 0.0) ? (-1.0) : 1.0), (1.0 - abs(_3219)) * ((_3221 < 0.0) ? (-1.0) : 1.0));\n    }\n    return e;\n}\n\nvec2 fa_atlas_size()\n{\n    return vec2(textureSize(fa_probe_atlas_fa_env_smp, 0));\n}\n\nvec3 fa_probe_level(vec2 origin, float res, int lv, vec2 e)\n{\n    float _3268;\n    if (lv == 0)\n    {\n        _3268 = 0.0;\n    }\n    else\n    {\n        _3268 = res + 2.0;\n    }\n    float _3278;\n    if (lv == 0)\n    {\n        _3278 = 0.0;\n    }\n    else\n    {\n        _3278 = (res - (res / float(1 << max((lv - 1), 0)))) + (2.0 * float(lv - 1));\n    }\n    return textureLod(fa_probe_atlas_fa_env_smp, (((origin + vec2(_3268, _3278)) + vec2(1.0)) + (((e * 0.5) + vec2(0.5)) * (res / float(1 << lv)))) / fa_atlas_size(), 0.0).xyz;\n}\n\nvec3 fa_probe_radiance(vec2 origin, float res, vec3 d, float rough)\n{\n    float _3324;\n    if (res > 64.5)\n    {\n        _3324 = 5.0;\n    }\n    else\n    {\n        _3324 = (res > 32.5) ? 4.0 : 3.0;\n    }\n    float _3339 = clamp(rough, 0.0, 1.0) * (_3324 - 1.0);\n    int _3346 = int(min(floor(_3339), _3324 - 2.0));\n    float _3351 = _3339 - float(_3346);\n    vec3 param = d;\n    vec2 _3355 = fa_oct_encode(param);\n    vec2 param_1 = origin;\n    float param_2 = res;\n    int param_3 = _3346;\n    vec2 param_4 = _3355;\n    vec3 _3365 = fa_probe_level(param_1, param_2, param_3, param_4);\n    if (_3351 < 0.00200000009499490261077880859375)\n    {\n        return _3365;\n    }\n    vec2 param_5 = origin;\n    float param_6 = res;\n    int param_7 = _3346 + 1;\n    vec2 param_8 = _3355;\n    return mix(_3365, fa_probe_level(param_5, param_6, param_7, param_8), vec3(_3351));\n}\n\nvec3 fa_probe_box_dir(vec3 d, vec4 posw, vec4 bx, vec4 by, vec4 bz)\n{\n    if (posw.w < 0.5)\n    {\n        return d;\n    }\n    float _3403 = dot(bx.xyz, fa_world_pos) + bx.w;\n    float _3410 = dot(by.xyz, fa_world_pos) + by.w;\n    float _3417 = dot(bz.xyz, fa_world_pos) + bz.w;\n    float _3423 = dot(bx.xyz, d);\n    float _3427 = dot(by.xyz, d);\n    float _3431 = dot(bz.xyz, d);\n    float _3437;\n    if (_3423 > 9.9999999747524270787835121154785e-07)\n    {\n        _3437 = (1.0 - _3403) / _3423;\n    }\n    else\n    {\n        float _3451;\n        if (_3423 < (-9.9999999747524270787835121154785e-07))\n        {\n            _3451 = ((-1.0) - _3403) / _3423;\n        }\n        else\n        {\n            _3451 = 1000000015047466219876688855040.0;\n        }\n        _3437 = _3451;\n    }\n    float tx = _3437;\n    float _3468;\n    if (_3427 > 9.9999999747524270787835121154785e-07)\n    {\n        _3468 = (1.0 - _3410) / _3427;\n    }\n    else\n    {\n        float _3481;\n        if (_3427 < (-9.9999999747524270787835121154785e-07))\n        {\n            _3481 = ((-1.0) - _3410) / _3427;\n        }\n        else\n        {\n            _3481 = 1000000015047466219876688855040.0;\n        }\n        _3468 = _3481;\n    }\n    float ty = _3468;\n    float _3497;\n    if (_3431 > 9.9999999747524270787835121154785e-07)\n    {\n        _3497 = (1.0 - _3417) / _3431;\n    }\n    else\n    {\n        float _3510;\n        if (_3431 < (-9.9999999747524270787835121154785e-07))\n        {\n            _3510 = ((-1.0) - _3417) / _3431;\n        }\n        else\n        {\n            _3510 = 1000000015047466219876688855040.0;\n        }\n        _3497 = _3510;\n    }\n    float _3522 = tx;\n    float _3525 = (_3522 > 0.0) ? _3522 : 1000000015047466219876688855040.0;\n    tx = _3525;\n    float _3526 = ty;\n    float _3529 = (_3526 > 0.0) ? _3526 : 1000000015047466219876688855040.0;\n    ty = _3529;\n    float _3539 = min(_3525, min(_3529, (_3497 > 0.0) ? _3497 : 1000000015047466219876688855040.0));\n    if (_3539 > 100000001504746621987668885504.0)\n    {\n        return d;\n    }\n    vec3 _3555 = (fa_world_pos + (d * _3539)) - posw.xyz;\n    vec3 _3560;\n    if (dot(_3555, _3555) > 1.0000000133514319600180897396058e-10)\n    {\n        _3560 = normalize(_3555);\n    }\n    else\n    {\n        _3560 = d;\n    }\n    return _3560;\n}\n\nvec3 fa_probe_environment(vec4 tile, vec4 posw, vec4 bx, vec4 by, vec4 bz, inout vec3 d, float rough)\n{\n    vec3 param = d;\n    vec4 param_1 = posw;\n    vec4 param_2 = bx;\n    vec4 param_3 = by;\n    vec4 param_4 = bz;\n    d = fa_probe_box_dir(param, param_1, param_2, param_3, param_4);\n    vec2 param_5 = tile.xy;\n    float param_6 = tile.z;\n    vec3 param_7 = d;\n    float param_8 = rough;\n    return fa_probe_radiance(param_5, param_6, param_7, param_8);\n}\n\nvec3 fa_environment(vec3 d, float rough)\n{\n    float _3606 = (1.0 - fa_mesh_fs_params[42].w) - fa_mesh_fs_params[47].w;\n    vec3 outc = vec3(0.0);\n    if (_3606 > 0.0005000000237487256526947021484375)\n    {\n        vec3 base;\n        if (fa_mesh_fs_params[11].w > 0.5)\n        {\n            vec2 param = fa_mesh_fs_params[41].zw;\n            float param_1 = 128.0;\n            vec3 param_2 = d;\n            float param_3 = rough;\n            base = fa_probe_radiance(param, param_1, param_2, param_3);\n        }\n        else\n        {\n            float _3636 = rough * rough;\n            float _3667 = 0.60000002384185791015625 * _3636;\n            base = mix(mix(fa_mesh_fs_params[12].xyz * 0.550000011920928955078125, mix(fa_mesh_fs_params[12].xyz, fa_mesh_fs_params[11].xyz, vec3(pow(clamp(d.y * (1.0 - (0.699999988079071044921875 * _3636)), 0.0, 1.0), 0.550000011920928955078125))), vec3(smoothstep((-0.0500000007450580596923828125) - _3667, 0.0500000007450580596923828125 + _3667, d.y))), ((fa_mesh_fs_params[11].xyz + fa_mesh_fs_params[12].xyz) * 0.5) * 0.800000011920928955078125, vec3(_3636 * 0.60000002384185791015625));\n        }\n        outc = base * _3606;\n    }\n    if (fa_mesh_fs_params[42].w > 0.0)\n    {\n        vec4 param_4 = fa_mesh_fs_params[42];\n        vec4 param_5 = fa_mesh_fs_params[43];\n        vec4 param_6 = fa_mesh_fs_params[44];\n        vec4 param_7 = fa_mesh_fs_params[45];\n        vec4 param_8 = fa_mesh_fs_params[46];\n        vec3 param_9 = d;\n        float param_10 = rough;\n        vec3 _3726 = fa_probe_environment(param_4, param_5, param_6, param_7, param_8, param_9, param_10);\n        outc += (_3726 * fa_mesh_fs_params[42].w);\n    }\n    if (fa_mesh_fs_params[47].w > 0.0)\n    {\n        vec4 param_11 = fa_mesh_fs_params[47];\n        vec4 param_12 = fa_mesh_fs_params[48];\n        vec4 param_13 = fa_mesh_fs_params[49];\n        vec4 param_14 = fa_mesh_fs_params[50];\n        vec4 param_15 = fa_mesh_fs_params[51];\n        vec3 param_16 = d;\n        float param_17 = rough;\n        vec3 _3758 = fa_probe_environment(param_11, param_12, param_13, param_14, param_15, param_16, param_17);\n        outc += (_3758 * fa_mesh_fs_params[47].w);\n    }\n    return outc;\n}\n\nvec3 fa_layers_ibl(FaLayers L, vec3 n, vec3 v, vec3 f0, float roughness, float occlusion)\n{\n    vec3 rn = n;\n    if (L.aniso != 0.0)\n    {\n        vec3 _4260;\n        if (L.aniso >= 0.0)\n        {\n            _4260 = L.b;\n        }\n        else\n        {\n            _4260 = L.t;\n        }\n        rn = normalize(mix(n, cross(cross(_4260, v), _4260), vec3(abs(L.aniso) * smoothstep(0.0, 0.25, roughness))));\n    }\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05);\n    vec2 _4296 = fa_env_brdf(param, param_1);\n    vec3 param_2 = reflect(-v, rn);\n    float param_3 = roughness;\n    vec3 result = (fa_environment(param_2, param_3) * ((f0 * _4296.x) + (vec3(L.f90) * _4296.y))) * L.base_scale;\n    if (L.sheen_on)\n    {\n        vec3 param_4 = n;\n        float param_5 = L.sheen_rough;\n        result += ((L.sheen * (L.sheen_e * L.keep)) * fa_environment(param_4, param_5));\n    }\n    result *= occlusion;\n    if (L.coat > 0.0)\n    {\n        float param_6 = L.coat_rough;\n        float param_7 = L.coat_ndv;\n        vec2 _4354 = fa_env_brdf(param_6, param_7);\n        vec3 param_8 = reflect(-v, L.nc);\n        float param_9 = L.coat_rough;\n        result += (fa_environment(param_8, param_9) * (L.coat * ((0.039999999105930328369140625 * _4354.x) + _4354.y)));\n    }\n    return result;\n}\n\nvec3 fa_sky_reflection(vec3 n, vec3 v, vec3 f0, float roughness)\n{\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05);\n    vec2 _3823 = fa_env_brdf(param, param_1);\n    vec3 param_2 = reflect(-v, n);\n    float param_3 = roughness;\n    return fa_environment(param_2, param_3) * ((f0 * _3823.x) + vec3(_3823.y));\n}\n\nvec3 fa_sky_light(SurfaceInput i, Surface s)\n{\n    float _4393 = clamp(s.metallic, 0.0, 1.0);\n    float _4397 = clamp(s.roughness, 0.0500000007450580596923828125, 1.0);\n    vec3 _4404 = mix(vec3(0.039999999105930328369140625), s.albedo, vec3(_4393));\n    vec3 f0 = _4404;\n    vec3 _4408 = normalize(s.normal);\n    SurfaceInput param = i;\n    Surface param_1 = s;\n    vec3 param_2 = _4408;\n    vec3 param_3 = i.view_dir;\n    float param_4 = _4393;\n    float param_5 = _4397;\n    vec3 param_6 = _4404;\n    FaLayers _4425 = fa_layers_setup(param, param_1, param_2, param_3, param_4, param_5, param_6);\n    f0 = param_6;\n    if (_4425.on)\n    {\n        FaLayers param_7 = _4425;\n        vec3 param_8 = _4408;\n        vec3 param_9 = i.view_dir;\n        vec3 param_10 = f0;\n        float param_11 = _4397;\n        float param_12 = s.occlusion;\n        return fa_layers_ibl(param_7, param_8, param_9, param_10, param_11, param_12);\n    }\n    vec3 param_13 = _4408;\n    vec3 param_14 = i.view_dir;\n    vec3 param_15 = f0;\n    float param_16 = _4397;\n    return fa_sky_reflection(param_13, param_14, param_15, param_16) * s.occlusion;\n}\n\nvec3 lighting(SurfaceInput i, Surface s)\n{\n    int best = -1;\n    float bestPower = 0.0;\n    for (int n = 0; n < fa_light_count(); n++)\n    {\n        int param = n;\n        SurfaceInput param_1 = i;\n        LightSample _5023 = fa_light_unshadowed(param, param_1);\n        float _5031 = dot(_5023.color, vec3(0.2989999949932098388671875, 0.58700001239776611328125, 0.114000000059604644775390625));\n        if (_5031 > bestPower)\n        {\n            bestPower = _5031;\n            best = n;\n        }\n    }\n    vec3 lit = (fa_mesh_fs_params[1].xyz * s.albedo) * s.occlusion;\n    if (best >= 0)\n    {\n        int param_2 = best;\n        SurfaceInput param_3 = i;\n        LightSample _5060 = fa_light(param_2, param_3);\n        float _5068;\n        if (dot(s.normal, _5060.direction) > 0.5)\n        {\n            _5068 = 1.0;\n        }\n        else\n        {\n            _5068 = fa_material[0].x;\n        }\n        lit += ((s.albedo * _5060.color) * _5068);\n    }\n    SurfaceInput param_4 = i;\n    Surface param_5 = s;\n    return lit + (fa_sky_light(param_4, param_5) * fa_material[1].x);\n}\n\nvec3 fa_shadow_debug(vec3 color, vec3 world)\n{\n    if (fa_shadows[27].w < 0.5)\n    {\n        return color;\n    }\n    int _3114 = int(fa_shadows[25].x + 0.5);\n    float _3124 = dot(world - fa_shadows[27].xyz, fa_shadows[28].xyz);\n    vec3 tint = vec3(0.3499999940395355224609375);\n    bool _3129 = _3114 > 0;\n    bool _3138;\n    if (_3129)\n    {\n        int param = _3114 - 1;\n        _3138 = _3124 <= fa_shadow_split_at(param);\n    }\n    else\n    {\n        _3138 = _3129;\n    }\n    if (_3138)\n    {\n        tint = vec3(1.0, 0.1500000059604644775390625, 0.100000001490116119384765625);\n        bool _3144 = _3114 > 1;\n        bool _3151;\n        if (_3144)\n        {\n            _3151 = _3124 > fa_shadows[24].x;\n        }\n        else\n        {\n            _3151 = _3144;\n        }\n        if (_3151)\n        {\n            tint = vec3(0.100000001490116119384765625, 0.89999997615814208984375, 0.20000000298023223876953125);\n        }\n        bool _3157 = _3114 > 2;\n        bool _3164;\n        if (_3157)\n        {\n            _3164 = _3124 > fa_shadows[24].y;\n        }\n        else\n        {\n            _3164 = _3157;\n        }\n        if (_3164)\n        {\n            tint = vec3(0.1500000059604644775390625, 0.300000011920928955078125, 1.0);\n        }\n        bool _3170 = _3114 > 3;\n        bool _3177;\n        if (_3170)\n        {\n            _3177 = _3124 > fa_shadows[24].z;\n        }\n        else\n        {\n            _3177 = _3170;\n        }\n        if (_3177)\n        {\n            tint = vec3(1.0, 0.89999997615814208984375, 0.100000001490116119384765625);\n        }\n    }\n    return mix(color, tint, vec3(0.550000011920928955078125));\n}\n\nvoid main()\n{\n    fa_inst_load();\n    vec3 _5792 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _5792 = -_5792;\n    }\n    vec3 _5461 = normalize(fa_mesh_fs_params[0].xyz - fa_world_pos);\n    vec3 param = fa_world_pos;\n    fa_cluster_begin(param);\n    SurfaceInput param_1 = SurfaceInput(fa_world_pos, _5792, fa_world_tangent, fa_uv, fa_vertex_color, _5461, gl_FrontFacing);\n    Surface _5469 = fa_standard_surface(param_1);\n    vec3 _5823 = _5469.albedo;\n    float _5824 = _5469.alpha;\n    vec3 _5825 = _5469.normal;\n    float _5826 = _5469.metallic;\n    float _5827 = _5469.roughness;\n    float _5828 = _5469.occlusion;\n    vec3 _5829 = _5469.emission;\n    float _5830 = _5469.clearcoat;\n    float _5831 = _5469.clearcoat_roughness;\n    vec3 _5832 = _5469.sheen_color;\n    float _5833 = _5469.sheen_roughness;\n    float _5834 = _5469.anisotropy;\n    float _5835 = _5469.anisotropy_rotation;\n    float _5836 = _5469.specular;\n    float _5837 = _5469.ior;\n    vec3 _5838 = _5469.specular_color;\n    float _5839 = _5469.transmission;\n    float _5840 = _5469.thickness;\n    vec3 _5841 = _5469.attenuation_color;\n    float _5842 = _5469.attenuation_distance;\n    SurfaceInput param_2 = SurfaceInput(fa_world_pos, _5792, fa_world_tangent, fa_uv, fa_vertex_color, _5461, gl_FrontFacing);\n    Surface param_3 = _5469;\n    surface(param_2, param_3);\n    _5823 = param_3.albedo;\n    _5824 = param_3.alpha;\n    _5825 = param_3.normal;\n    _5826 = param_3.metallic;\n    _5827 = param_3.roughness;\n    _5828 = param_3.occlusion;\n    _5829 = param_3.emission;\n    _5830 = param_3.clearcoat;\n    _5831 = param_3.clearcoat_roughness;\n    _5832 = param_3.sheen_color;\n    _5833 = param_3.sheen_roughness;\n    _5834 = param_3.anisotropy;\n    _5835 = param_3.anisotropy_rotation;\n    _5836 = param_3.specular;\n    _5837 = param_3.ior;\n    _5838 = param_3.specular_color;\n    _5839 = param_3.transmission;\n    _5840 = param_3.thickness;\n    _5841 = param_3.attenuation_color;\n    _5842 = param_3.attenuation_distance;\n    vec3 param_4 = fa_world_pos;\n    vec3 param_5 = _5792;\n    vec3 param_6 = param_3.albedo;\n    vec3 param_7 = param_3.normal;\n    fa_apply_decals(param_4, param_5, param_6, param_7);\n    _5823 = param_6;\n    _5825 = param_7;\n    fa_lod_dither();\n    vec3 result;\n    if (fa_mesh_fs_params[3].w > 0.5)\n    {\n        result = _5823;\n    }\n    else\n    {\n        vec3 _5509 = _5825;\n        vec3 _5510 = normalize(_5509);\n        _5825 = _5510;\n        SurfaceInput param_8 = SurfaceInput(fa_world_pos, _5792, fa_world_tangent, fa_uv, fa_vertex_color, _5461, gl_FrontFacing);\n        Surface param_9 = Surface(_5823, _5824, _5510, _5826, _5827, _5828, _5829, _5830, _5831, _5832, _5833, _5834, _5835, _5836, _5837, _5838, _5839, _5840, _5841, _5842);\n        vec3 _5521 = lighting(param_8, param_9);\n        result = _5521;\n    }\n    vec3 _5525 = result;\n    vec3 _5526 = _5525 + _5829;\n    result = _5526;\n    vec3 param_10 = _5526;\n    vec3 param_11 = fa_world_pos;\n    result = fa_shadow_debug(param_10, param_11);\n    bool _5535 = fa_mesh_fs_params[7].w > 0.0;\n    bool _5542;\n    if (!_5535)\n    {\n        _5542 = fa_mesh_fs_params[8].y > 0.0;\n    }\n    else\n    {\n        _5542 = _5535;\n    }\n    if (_5542)\n    {\n        vec3 _5551 = fa_world_pos - fa_mesh_fs_params[0].xyz;\n        float _5557 = dot(_5551, fa_mesh_fs_params[9].xyz);\n        bool _5561 = fa_mesh_fs_params[9].w > 0.5;\n        float _5562;\n        if (_5561)\n        {\n            _5562 = _5557;\n        }\n        else\n        {\n            _5562 = length(_5551);\n        }\n        float _5574 = _5562 - fa_mesh_fs_params[8].x;\n        if (_5574 > 0.0)\n        {\n            float _5583 = fa_mesh_fs_params[7].w * _5574;\n            float tau = _5583 * _5583;\n            if (fa_mesh_fs_params[8].y > 0.0)\n            {\n                float _5599;\n                if (_5561)\n                {\n                    _5599 = fa_world_pos.y - (fa_mesh_fs_params[9].y * _5557);\n                }\n                else\n                {\n                    _5599 = fa_mesh_fs_params[0].y;\n                }\n                float _5620 = mix(_5599, fa_world_pos.y, clamp(fa_mesh_fs_params[8].x / _5562, 0.0, 1.0));\n                float _5624 = fa_world_pos.y - _5620;\n                float _5629 = _5620 - fa_mesh_fs_params[8].z;\n                float _5634 = fa_world_pos.y - fa_mesh_fs_params[8].z;\n                bool _5637 = _5629 <= 0.0;\n                bool _5638 = !_5637;\n                bool _5644;\n                if (_5638)\n                {\n                    _5644 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _5644 = _5637;\n                }\n                float _5645;\n                if (_5644)\n                {\n                    _5645 = fa_mesh_fs_params[8].y;\n                }\n                else\n                {\n                    _5645 = fa_mesh_fs_params[8].y * exp(-min(fa_mesh_fs_params[8].w * _5629, 80.0));\n                }\n                bool _5672;\n                if (_5638)\n                {\n                    _5672 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _5672 = _5637;\n                }\n                float _5673;\n                if (_5672)\n                {\n                    _5673 = fa_mesh_fs_params[8].y * _5629;\n                }\n                else\n                {\n                    _5673 = (fa_mesh_fs_params[8].y * (1.0 - exp(-min(fa_mesh_fs_params[8].w * _5629, 80.0)))) / fa_mesh_fs_params[8].w;\n                }\n                bool _5698 = _5634 <= 0.0;\n                bool _5705;\n                if (!_5698)\n                {\n                    _5705 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _5705 = _5698;\n                }\n                float _5706;\n                if (_5705)\n                {\n                    _5706 = fa_mesh_fs_params[8].y * _5634;\n                }\n                else\n                {\n                    _5706 = (fa_mesh_fs_params[8].y * (1.0 - exp(-min(fa_mesh_fs_params[8].w * _5634, 80.0)))) / fa_mesh_fs_params[8].w;\n                }\n                float _5733;\n                if (abs(_5624) < 0.001000000047497451305389404296875)\n                {\n                    _5733 = _5645;\n                }\n                else\n                {\n                    _5733 = (_5706 - _5673) / _5624;\n                }\n                tau += (_5574 * max(_5733, 0.0));\n            }\n            result = mix(result, fa_mesh_fs_params[7].xyz, vec3(clamp(1.0 - exp(-clamp(tau, 0.0, 80.0)), 0.0, 1.0)));\n        }\n    }\n    fa_frag_color = vec4(result, _5824);\n}\n\n",
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
            "inst_name": "_420",
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
            "inst_name": "_2155",
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
            "inst_name": "_5074",
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
      "vs": "#version 430\n\nstruct VertexData\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 color;\n    vec3 object_pos;\n};\n\nuniform vec4 fa_mesh_vs_params[11];\nlayout(location = 0) out vec3 fa_world_pos;\nlayout(location = 1) out vec3 fa_world_normal;\nlayout(location = 2) out vec4 fa_world_tangent;\nlayout(location = 3) out vec2 fa_uv;\nlayout(location = 4) out vec4 fa_vertex_color;\nlayout(location = 5) out float fa_pre_depth;\nlayout(location = 6) out vec3 fa_pre_r0;\nlayout(location = 7) out vec3 fa_pre_r1;\nlayout(location = 8) out vec3 fa_pre_r2;\nlayout(location = 5) in vec4 fa_inst_m0;\nlayout(location = 6) in vec4 fa_inst_m1;\nlayout(location = 7) in vec4 fa_inst_m2;\nlayout(location = 8) in vec4 fa_inst_m3;\nlayout(location = 0) in vec3 fa_position;\nlayout(location = 1) in vec3 fa_normal;\nlayout(location = 3) in vec4 fa_tangent;\nlayout(location = 2) in vec2 fa_texcoord0;\nlayout(location = 4) in vec4 fa_color;\n\nvoid fa_inst_begin()\n{\n}\n\nVertexData fa_vertex_data(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    vec3 _69 = cross(model[1].xyz, model[2].xyz);\n    float _75 = (dot(model[0].xyz, _69) < 0.0) ? (-1.0) : 1.0;\n    return VertexData((model * vec4(position, 1.0)).xyz, (((_69 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _75, vec4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _75), texcoord0 * fa_mesh_vs_params[8].xy, color, position);\n}\n\nvoid fa_prepass_vertex(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    mat4 param = model;\n    vec3 param_1 = position;\n    vec3 param_2 = normal;\n    vec4 param_3 = tangent;\n    vec2 param_4 = texcoord0;\n    vec4 param_5 = color;\n    VertexData _160 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    vec3 _302 = _160.world_pos;\n    mat4 _164 = mat4(fa_mesh_vs_params[4], fa_mesh_vs_params[5], fa_mesh_vs_params[6], fa_mesh_vs_params[7]);\n    vec4 _171 = vec4(_302, 1.0);\n    fa_world_pos = _302;\n    fa_world_normal = _160.world_normal;\n    fa_world_tangent = _160.world_tangent;\n    fa_uv = _160.uv;\n    fa_vertex_color = _160.color;\n    fa_pre_depth = -(_164 * _171).z;\n    fa_pre_r0 = vec3(_164[0].x, _164[1].x, _164[2].x);\n    fa_pre_r1 = vec3(_164[0].y, _164[1].y, _164[2].y);\n    fa_pre_r2 = vec3(_164[0].z, _164[1].z, _164[2].z);\n    gl_Position = mat4(fa_mesh_vs_params[0], fa_mesh_vs_params[1], fa_mesh_vs_params[2], fa_mesh_vs_params[3]) * _171;\n}\n\nvoid main()\n{\n    fa_inst_begin();\n    mat4 param = mat4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3);\n    vec3 param_1 = fa_position;\n    vec3 param_2 = fa_normal;\n    vec4 param_3 = fa_tangent;\n    vec2 param_4 = fa_texcoord0;\n    vec4 param_5 = fa_color;\n    fa_prepass_vertex(param, param_1, param_2, param_3, param_4, param_5);\n}\n\n",
      "fs": "#version 430\n\nstruct SurfaceInput\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 vertex_color;\n    vec3 view_dir;\n    bool front_facing;\n};\n\nstruct Surface\n{\n    vec3 albedo;\n    float alpha;\n    vec3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    vec3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    vec3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    vec3 specular_color;\n    float transmission;\n    float thickness;\n    vec3 attenuation_color;\n    float attenuation_distance;\n};\n\nuniform vec4 fa_mesh_fs_params[53];\nlayout(binding = 0) uniform sampler2D fa_tex_fa_smp;\nlayout(binding = 1) uniform sampler2D fa_normal_tex_fa_smp;\nlayout(binding = 2) uniform sampler2D fa_mr_tex_fa_smp;\nlayout(binding = 3) uniform sampler2D fa_occlusion_tex_fa_smp;\nlayout(binding = 4) uniform sampler2D fa_emissive_tex_fa_smp;\n\nlayout(location = 0) in vec3 fa_world_pos;\nlayout(location = 1) in vec3 fa_world_normal;\nlayout(location = 2) in vec4 fa_world_tangent;\nlayout(location = 3) in vec2 fa_uv;\nlayout(location = 4) in vec4 fa_vertex_color;\nlayout(location = 6) in vec3 fa_pre_r0;\nlayout(location = 7) in vec3 fa_pre_r1;\nlayout(location = 8) in vec3 fa_pre_r2;\nlayout(location = 0) out vec4 fa_frag_color;\nlayout(location = 5) in float fa_pre_depth;\n\nvoid fa_inst_load()\n{\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nvec3 fa_linear_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_tex_fix(inout vec3 c, float mode)\n{\n    if (mode > 1.5)\n    {\n        vec3 param = c;\n        vec3 _218 = fa_linear_to_srgb(param);\n        c = _218;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            vec3 param_1 = c;\n            vec3 _227 = fa_srgb_to_linear(param_1);\n            c = _227;\n        }\n    }\n    return c;\n}\n\nvec3 fa_tangent_normal(SurfaceInput i, vec3 m)\n{\n    vec3 _58;\n    if (i.front_facing)\n    {\n        _58 = i.world_normal;\n    }\n    else\n    {\n        _58 = -i.world_normal;\n    }\n    vec3 _83 = normalize(i.world_tangent.xyz - (_58 * dot(_58, i.world_tangent.xyz)));\n    vec3 _111 = normalize(((_83 * m.x) + ((cross(_58, _83) * i.world_tangent.w) * m.y)) + (_58 * m.z));\n    vec3 _114;\n    if (i.front_facing)\n    {\n        _114 = _111;\n    }\n    else\n    {\n        _114 = -_111;\n    }\n    return _114;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    vec4 base_t = texture(fa_tex_fa_smp, i.uv);\n    float param = fa_mesh_fs_params[6].w;\n    float param_1 = 1.0;\n    vec3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    vec3 _267 = fa_tex_fix(param_2, param_3);\n    vec4 _871 = base_t;\n    _871.x = _267.x;\n    _871.y = _267.y;\n    _871.z = _267.z;\n    base_t = _871;\n    vec4 _283 = (_871 * fa_mesh_fs_params[2]) * i.vertex_color;\n    vec3 _826 = i.world_normal;\n    if (fa_mesh_fs_params[6].z > 0.5)\n    {\n        float param_4 = fa_mesh_fs_params[6].w;\n        float param_5 = 16.0;\n        vec3 param_6 = texture(fa_normal_tex_fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        vec3 _317 = fa_tex_fix(param_6, param_7);\n        vec3 _321 = (_317 * 2.0) - vec3(1.0);\n        vec2 _326 = _321.xy * fa_mesh_fs_params[6].x;\n        vec3 _879 = _321;\n        _879.x = _326.x;\n        _879.y = _326.y;\n        SurfaceInput param_8 = i;\n        vec3 param_9 = _879;\n        _826 = fa_tangent_normal(param_8, param_9);\n    }\n    vec4 mrt = texture(fa_mr_tex_fa_smp, i.uv);\n    float param_10 = fa_mesh_fs_params[6].w;\n    float param_11 = 64.0;\n    vec3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    vec3 _355 = fa_tex_fix(param_12, param_13);\n    vec4 _882 = mrt;\n    _882.x = _355.x;\n    _882.y = _355.y;\n    _882.z = _355.z;\n    mrt = _882;\n    vec4 _385 = texture(fa_occlusion_tex_fa_smp, i.uv);\n    float param_14 = fa_mesh_fs_params[6].w;\n    float param_15 = 256.0;\n    vec3 param_16 = _385.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    vec3 _397 = fa_tex_fix(param_16, param_17);\n    float param_18 = fa_mesh_fs_params[6].w;\n    float param_19 = 4.0;\n    vec3 param_20 = texture(fa_emissive_tex_fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    vec3 _427 = fa_tex_fix(param_20, param_21);\n    float _831 = fa_mesh_fs_params[20].x;\n    float _832 = fa_mesh_fs_params[20].y;\n    float _835 = fa_mesh_fs_params[20].z;\n    float _834 = fa_mesh_fs_params[21].w;\n    float _837 = fa_mesh_fs_params[22].x;\n    if (fa_mesh_fs_params[22].z > 0.5)\n    {\n        if (mod(fa_mesh_fs_params[22].z, 2.0) > 0.5)\n        {\n            _831 *= _397.y;\n            _832 *= _397.z;\n            _834 *= _385.w;\n        }\n        if (fa_mesh_fs_params[22].z > 1.5)\n        {\n            _835 *= mrt.x;\n            _837 *= mrt.w;\n        }\n    }\n    return Surface(_283.xyz, _283.w, _826, clamp(fa_mesh_fs_params[5].x * _355.z, 0.0, 1.0), clamp(fa_mesh_fs_params[5].y * _355.y, 0.0500000007450580596923828125, 1.0), 1.0 + (fa_mesh_fs_params[6].y * (_397.x - 1.0)), fa_mesh_fs_params[3].xyz + (fa_mesh_fs_params[4].xyz * _427), _831, _832, fa_mesh_fs_params[21].xyz, _834, _835, fa_mesh_fs_params[20].w, _837, fa_mesh_fs_params[22].y, fa_mesh_fs_params[23].xyz, fa_mesh_fs_params[30].x, fa_mesh_fs_params[30].y, fa_mesh_fs_params[31].xyz, fa_mesh_fs_params[30].z);\n}\n\nvoid surface(SurfaceInput i, Surface s)\n{\n}\n\nvoid fa_lod_dither()\n{\n    if (fa_mesh_fs_params[52].w != 0.0)\n    {\n        float _151 = fract(52.98291778564453125 * fract(dot(gl_FragCoord.xy, vec2(0.067110560834407806396484375, 0.005837149918079376220703125))));\n        bool _154;\n        if (fa_mesh_fs_params[52].w > 0.0)\n        {\n            _154 = _151 >= fa_mesh_fs_params[52].w;\n        }\n        else\n        {\n            _154 = _151 < (-fa_mesh_fs_params[52].w);\n        }\n        if (_154)\n        {\n            discard;\n        }\n    }\n}\n\nvoid main()\n{\n    fa_inst_load();\n    vec3 _721 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _721 = -_721;\n    }\n    vec3 _579 = normalize(fa_mesh_fs_params[0].xyz - fa_world_pos);\n    SurfaceInput param = SurfaceInput(fa_world_pos, _721, fa_world_tangent, fa_uv, fa_vertex_color, _579, gl_FrontFacing);\n    Surface _584 = fa_standard_surface(param);\n    vec3 _745 = _584.normal;\n    SurfaceInput param_1 = SurfaceInput(fa_world_pos, _721, fa_world_tangent, fa_uv, fa_vertex_color, _579, gl_FrontFacing);\n    Surface param_2 = _584;\n    surface(param_1, param_2);\n    _745 = param_2.normal;\n    fa_lod_dither();\n    vec3 _595 = normalize(_745);\n    vec3 _610 = normalize(vec3(dot(fa_pre_r0, _595), dot(fa_pre_r1, _595), dot(fa_pre_r2, _595)));\n    float _622 = _610.z;\n    vec2 e = _610.xy / vec2((abs(_610.x) + abs(_610.y)) + abs(_622));\n    if (_622 < 0.0)\n    {\n        e = (vec2(1.0) - abs(e.yx)) * vec2((e.x >= 0.0) ? 1.0 : (-1.0), (e.y >= 0.0) ? 1.0 : (-1.0));\n    }\n    fa_frag_color = vec4(min(fa_pre_depth, 60000.0), e, 1.0);\n}\n\n",
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
            "inst_name": "_129",
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
      "vs": "#version 430\n\nstruct VertexData\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 color;\n    vec3 object_pos;\n};\n\nuniform vec4 fa_mesh_vs_params[11];\nuniform vec4 fa_skin[192];\nlayout(location = 0) out vec3 fa_world_pos;\nlayout(location = 1) out vec3 fa_world_normal;\nlayout(location = 2) out vec4 fa_world_tangent;\nlayout(location = 3) out vec2 fa_uv;\nlayout(location = 4) out vec4 fa_vertex_color;\nlayout(location = 5) out float fa_pre_depth;\nlayout(location = 6) out vec3 fa_pre_r0;\nlayout(location = 7) out vec3 fa_pre_r1;\nlayout(location = 8) out vec3 fa_pre_r2;\nlayout(location = 5) in vec4 fa_inst_m0;\nlayout(location = 6) in vec4 fa_inst_m1;\nlayout(location = 7) in vec4 fa_inst_m2;\nlayout(location = 8) in vec4 fa_inst_m3;\nlayout(location = 9) in vec4 fa_joints;\nlayout(location = 10) in vec4 fa_weights;\nlayout(location = 0) in vec3 fa_position;\nlayout(location = 1) in vec3 fa_normal;\nlayout(location = 3) in vec4 fa_tangent;\nlayout(location = 2) in vec2 fa_texcoord0;\nlayout(location = 4) in vec4 fa_color;\n\nvoid fa_inst_begin()\n{\n}\n\nmat4 fa_skin_matrix(vec4 joints, vec4 weights)\n{\n    vec4 r0 = vec4(0.0);\n    vec4 r1 = vec4(0.0);\n    vec4 r2 = vec4(0.0);\n    for (int i = 0; i < 4; i++)\n    {\n        int _174 = int((joints[i] * 255.0) + 0.5) * 3;\n        r0 += (fa_skin[_174 * 1 + 0] * weights[i]);\n        r1 += (fa_skin[(_174 + 1) * 1 + 0] * weights[i]);\n        r2 += (fa_skin[(_174 + 2) * 1 + 0] * weights[i]);\n    }\n    return mat4(vec4(r0.x, r1.x, r2.x, 0.0), vec4(r0.y, r1.y, r2.y, 0.0), vec4(r0.z, r1.z, r2.z, 0.0), vec4(r0.w, r1.w, r2.w, 1.0));\n}\n\nVertexData fa_vertex_data(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    vec3 _74 = cross(model[1].xyz, model[2].xyz);\n    float _80 = (dot(model[0].xyz, _74) < 0.0) ? (-1.0) : 1.0;\n    return VertexData((model * vec4(position, 1.0)).xyz, (((_74 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _80, vec4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _80), texcoord0 * fa_mesh_vs_params[8].xy, color, position);\n}\n\nvoid fa_prepass_vertex(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    mat4 param = model;\n    vec3 param_1 = position;\n    vec3 param_2 = normal;\n    vec4 param_3 = tangent;\n    vec2 param_4 = texcoord0;\n    vec4 param_5 = color;\n    VertexData _273 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    vec3 _423 = _273.world_pos;\n    mat4 _277 = mat4(fa_mesh_vs_params[4], fa_mesh_vs_params[5], fa_mesh_vs_params[6], fa_mesh_vs_params[7]);\n    vec4 _284 = vec4(_423, 1.0);\n    fa_world_pos = _423;\n    fa_world_normal = _273.world_normal;\n    fa_world_tangent = _273.world_tangent;\n    fa_uv = _273.uv;\n    fa_vertex_color = _273.color;\n    fa_pre_depth = -(_277 * _284).z;\n    fa_pre_r0 = vec3(_277[0].x, _277[1].x, _277[2].x);\n    fa_pre_r1 = vec3(_277[0].y, _277[1].y, _277[2].y);\n    fa_pre_r2 = vec3(_277[0].z, _277[1].z, _277[2].z);\n    gl_Position = mat4(fa_mesh_vs_params[0], fa_mesh_vs_params[1], fa_mesh_vs_params[2], fa_mesh_vs_params[3]) * _284;\n}\n\nvoid main()\n{\n    fa_inst_begin();\n    vec4 param = fa_joints;\n    vec4 param_1 = fa_weights;\n    mat4 param_2 = mat4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3) * fa_skin_matrix(param, param_1);\n    vec3 param_3 = fa_position;\n    vec3 param_4 = fa_normal;\n    vec4 param_5 = fa_tangent;\n    vec2 param_6 = fa_texcoord0;\n    vec4 param_7 = fa_color;\n    fa_prepass_vertex(param_2, param_3, param_4, param_5, param_6, param_7);\n}\n\n",
      "fs": "#version 430\n\nstruct SurfaceInput\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 vertex_color;\n    vec3 view_dir;\n    bool front_facing;\n};\n\nstruct Surface\n{\n    vec3 albedo;\n    float alpha;\n    vec3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    vec3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    vec3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    vec3 specular_color;\n    float transmission;\n    float thickness;\n    vec3 attenuation_color;\n    float attenuation_distance;\n};\n\nuniform vec4 fa_mesh_fs_params[53];\nlayout(binding = 0) uniform sampler2D fa_tex_fa_smp;\nlayout(binding = 1) uniform sampler2D fa_normal_tex_fa_smp;\nlayout(binding = 2) uniform sampler2D fa_mr_tex_fa_smp;\nlayout(binding = 3) uniform sampler2D fa_occlusion_tex_fa_smp;\nlayout(binding = 4) uniform sampler2D fa_emissive_tex_fa_smp;\n\nlayout(location = 0) in vec3 fa_world_pos;\nlayout(location = 1) in vec3 fa_world_normal;\nlayout(location = 2) in vec4 fa_world_tangent;\nlayout(location = 3) in vec2 fa_uv;\nlayout(location = 4) in vec4 fa_vertex_color;\nlayout(location = 6) in vec3 fa_pre_r0;\nlayout(location = 7) in vec3 fa_pre_r1;\nlayout(location = 8) in vec3 fa_pre_r2;\nlayout(location = 0) out vec4 fa_frag_color;\nlayout(location = 5) in float fa_pre_depth;\n\nvoid fa_inst_load()\n{\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nvec3 fa_linear_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_tex_fix(inout vec3 c, float mode)\n{\n    if (mode > 1.5)\n    {\n        vec3 param = c;\n        vec3 _218 = fa_linear_to_srgb(param);\n        c = _218;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            vec3 param_1 = c;\n            vec3 _227 = fa_srgb_to_linear(param_1);\n            c = _227;\n        }\n    }\n    return c;\n}\n\nvec3 fa_tangent_normal(SurfaceInput i, vec3 m)\n{\n    vec3 _58;\n    if (i.front_facing)\n    {\n        _58 = i.world_normal;\n    }\n    else\n    {\n        _58 = -i.world_normal;\n    }\n    vec3 _83 = normalize(i.world_tangent.xyz - (_58 * dot(_58, i.world_tangent.xyz)));\n    vec3 _111 = normalize(((_83 * m.x) + ((cross(_58, _83) * i.world_tangent.w) * m.y)) + (_58 * m.z));\n    vec3 _114;\n    if (i.front_facing)\n    {\n        _114 = _111;\n    }\n    else\n    {\n        _114 = -_111;\n    }\n    return _114;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    vec4 base_t = texture(fa_tex_fa_smp, i.uv);\n    float param = fa_mesh_fs_params[6].w;\n    float param_1 = 1.0;\n    vec3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    vec3 _267 = fa_tex_fix(param_2, param_3);\n    vec4 _871 = base_t;\n    _871.x = _267.x;\n    _871.y = _267.y;\n    _871.z = _267.z;\n    base_t = _871;\n    vec4 _283 = (_871 * fa_mesh_fs_params[2]) * i.vertex_color;\n    vec3 _826 = i.world_normal;\n    if (fa_mesh_fs_params[6].z > 0.5)\n    {\n        float param_4 = fa_mesh_fs_params[6].w;\n        float param_5 = 16.0;\n        vec3 param_6 = texture(fa_normal_tex_fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        vec3 _317 = fa_tex_fix(param_6, param_7);\n        vec3 _321 = (_317 * 2.0) - vec3(1.0);\n        vec2 _326 = _321.xy * fa_mesh_fs_params[6].x;\n        vec3 _879 = _321;\n        _879.x = _326.x;\n        _879.y = _326.y;\n        SurfaceInput param_8 = i;\n        vec3 param_9 = _879;\n        _826 = fa_tangent_normal(param_8, param_9);\n    }\n    vec4 mrt = texture(fa_mr_tex_fa_smp, i.uv);\n    float param_10 = fa_mesh_fs_params[6].w;\n    float param_11 = 64.0;\n    vec3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    vec3 _355 = fa_tex_fix(param_12, param_13);\n    vec4 _882 = mrt;\n    _882.x = _355.x;\n    _882.y = _355.y;\n    _882.z = _355.z;\n    mrt = _882;\n    vec4 _385 = texture(fa_occlusion_tex_fa_smp, i.uv);\n    float param_14 = fa_mesh_fs_params[6].w;\n    float param_15 = 256.0;\n    vec3 param_16 = _385.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    vec3 _397 = fa_tex_fix(param_16, param_17);\n    float param_18 = fa_mesh_fs_params[6].w;\n    float param_19 = 4.0;\n    vec3 param_20 = texture(fa_emissive_tex_fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    vec3 _427 = fa_tex_fix(param_20, param_21);\n    float _831 = fa_mesh_fs_params[20].x;\n    float _832 = fa_mesh_fs_params[20].y;\n    float _835 = fa_mesh_fs_params[20].z;\n    float _834 = fa_mesh_fs_params[21].w;\n    float _837 = fa_mesh_fs_params[22].x;\n    if (fa_mesh_fs_params[22].z > 0.5)\n    {\n        if (mod(fa_mesh_fs_params[22].z, 2.0) > 0.5)\n        {\n            _831 *= _397.y;\n            _832 *= _397.z;\n            _834 *= _385.w;\n        }\n        if (fa_mesh_fs_params[22].z > 1.5)\n        {\n            _835 *= mrt.x;\n            _837 *= mrt.w;\n        }\n    }\n    return Surface(_283.xyz, _283.w, _826, clamp(fa_mesh_fs_params[5].x * _355.z, 0.0, 1.0), clamp(fa_mesh_fs_params[5].y * _355.y, 0.0500000007450580596923828125, 1.0), 1.0 + (fa_mesh_fs_params[6].y * (_397.x - 1.0)), fa_mesh_fs_params[3].xyz + (fa_mesh_fs_params[4].xyz * _427), _831, _832, fa_mesh_fs_params[21].xyz, _834, _835, fa_mesh_fs_params[20].w, _837, fa_mesh_fs_params[22].y, fa_mesh_fs_params[23].xyz, fa_mesh_fs_params[30].x, fa_mesh_fs_params[30].y, fa_mesh_fs_params[31].xyz, fa_mesh_fs_params[30].z);\n}\n\nvoid surface(SurfaceInput i, Surface s)\n{\n}\n\nvoid fa_lod_dither()\n{\n    if (fa_mesh_fs_params[52].w != 0.0)\n    {\n        float _151 = fract(52.98291778564453125 * fract(dot(gl_FragCoord.xy, vec2(0.067110560834407806396484375, 0.005837149918079376220703125))));\n        bool _154;\n        if (fa_mesh_fs_params[52].w > 0.0)\n        {\n            _154 = _151 >= fa_mesh_fs_params[52].w;\n        }\n        else\n        {\n            _154 = _151 < (-fa_mesh_fs_params[52].w);\n        }\n        if (_154)\n        {\n            discard;\n        }\n    }\n}\n\nvoid main()\n{\n    fa_inst_load();\n    vec3 _721 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _721 = -_721;\n    }\n    vec3 _579 = normalize(fa_mesh_fs_params[0].xyz - fa_world_pos);\n    SurfaceInput param = SurfaceInput(fa_world_pos, _721, fa_world_tangent, fa_uv, fa_vertex_color, _579, gl_FrontFacing);\n    Surface _584 = fa_standard_surface(param);\n    vec3 _745 = _584.normal;\n    SurfaceInput param_1 = SurfaceInput(fa_world_pos, _721, fa_world_tangent, fa_uv, fa_vertex_color, _579, gl_FrontFacing);\n    Surface param_2 = _584;\n    surface(param_1, param_2);\n    _745 = param_2.normal;\n    fa_lod_dither();\n    vec3 _595 = normalize(_745);\n    vec3 _610 = normalize(vec3(dot(fa_pre_r0, _595), dot(fa_pre_r1, _595), dot(fa_pre_r2, _595)));\n    float _622 = _610.z;\n    vec2 e = _610.xy / vec2((abs(_610.x) + abs(_610.y)) + abs(_622));\n    if (_622 < 0.0)\n    {\n        e = (vec2(1.0) - abs(e.yx)) * vec2((e.x >= 0.0) ? 1.0 : (-1.0), (e.y >= 0.0) ? 1.0 : (-1.0));\n    }\n    fa_frag_color = vec4(min(fa_pre_depth, 60000.0), e, 1.0);\n}\n\n",
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
            "inst_name": "_129",
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
    }
  }
}
