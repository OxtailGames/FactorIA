{
  "format": "factoria.shader/1",
  "engine": "0.32.0",
  "template": "fc5698cd941e0af057040ef4c307a7106b1e2971cc74f7501935817daedb7ce8",
  "slang": "glsl430",
  "params": [],
  "textures": [],
  "programs": {
    "mesh": {
      "vs": "#version 430\n\nstruct VertexData\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 color;\n    vec3 object_pos;\n};\n\nuniform vec4 fa_mesh_vs_params[11];\nlayout(location = 0) out vec3 fa_world_pos;\nlayout(location = 1) out vec3 fa_world_normal;\nlayout(location = 2) out vec4 fa_world_tangent;\nlayout(location = 3) out vec2 fa_uv;\nlayout(location = 4) out vec4 fa_vertex_color;\nlayout(location = 5) in vec4 fa_inst_m0;\nlayout(location = 6) in vec4 fa_inst_m1;\nlayout(location = 7) in vec4 fa_inst_m2;\nlayout(location = 8) in vec4 fa_inst_m3;\nlayout(location = 0) in vec3 fa_position;\nlayout(location = 1) in vec3 fa_normal;\nlayout(location = 3) in vec4 fa_tangent;\nlayout(location = 2) in vec2 fa_texcoord0;\nlayout(location = 4) in vec4 fa_color;\nlayout(location = 5) out vec3 fa_lm;\n\nvoid fa_inst_begin()\n{\n}\n\nVertexData fa_vertex_data(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    vec3 _69 = cross(model[1].xyz, model[2].xyz);\n    float _75 = (dot(model[0].xyz, _69) < 0.0) ? (-1.0) : 1.0;\n    return VertexData((model * vec4(position, 1.0)).xyz, (((_69 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _75, vec4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _75), texcoord0 * fa_mesh_vs_params[8].xy, color, position);\n}\n\nvoid fa_shade_vertex(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    mat4 param = model;\n    vec3 param_1 = position;\n    vec3 param_2 = normal;\n    vec4 param_3 = tangent;\n    vec2 param_4 = texcoord0;\n    vec4 param_5 = color;\n    VertexData _160 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    vec3 _267 = _160.world_pos;\n    fa_world_pos = _267;\n    fa_world_normal = _160.world_normal;\n    fa_world_tangent = _160.world_tangent;\n    fa_uv = _160.uv;\n    fa_vertex_color = _160.color;\n    gl_Position = mat4(fa_mesh_vs_params[0], fa_mesh_vs_params[1], fa_mesh_vs_params[2], fa_mesh_vs_params[3]) * vec4(_267, 1.0);\n}\n\nvoid main()\n{\n    fa_inst_begin();\n    mat4 param = mat4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3);\n    vec3 param_1 = fa_position;\n    vec3 param_2 = fa_normal;\n    vec4 param_3 = fa_tangent;\n    vec2 param_4 = fa_texcoord0;\n    vec4 param_5 = fa_color;\n    fa_shade_vertex(param, param_1, param_2, param_3, param_4, param_5);\n    fa_lm = vec3(0.0);\n}\n\n",
      "fs": "#version 430\n\nstruct SurfaceInput\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 vertex_color;\n    vec3 view_dir;\n    bool front_facing;\n};\n\nstruct LightSample\n{\n    vec3 direction;\n    vec3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct Surface\n{\n    vec3 albedo;\n    float alpha;\n    vec3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    vec3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    vec3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    vec3 specular_color;\n};\n\nstruct FaLayers\n{\n    bool on;\n    float f90;\n    float keep;\n    float base_scale;\n    float coat;\n    float coat_rough;\n    float coat_alpha;\n    float coat_a2;\n    vec3 nc;\n    float coat_ndv;\n    bool sheen_on;\n    vec3 sheen;\n    float sheen_rough;\n    float sheen_alpha;\n    float sheen_scale;\n    float sheen_e;\n    float aniso;\n    vec3 t;\n    vec3 b;\n    float at;\n    float ab;\n};\n\nconst float _3496[63] = float[](1.0, 1.0, 1.0, 0.4790000021457672119140625, 0.11699999868869781494140625, 0.01200000010430812835693359375, 0.0, 0.0, 0.0, 1.0, 1.0, 1.0, 0.578000009059906005859375, 0.19300000369548797607421875, 0.0350000001490116119384765625, 0.0030000000260770320892333984375, 0.0, 0.0, 1.0, 1.0, 1.0, 0.6740000247955322265625, 0.3459999859333038330078125, 0.1319999992847442626953125, 0.032999999821186065673828125, 0.0040000001899898052215576171875, 0.0, 0.971000015735626220703125, 0.954999983310699462890625, 0.828999996185302734375, 0.63999998569488525390625, 0.42599999904632568359375, 0.24500000476837158203125, 0.115000002086162567138671875, 0.037000000476837158203125, 0.0030000000260770320892333984375, 0.7469999790191650390625, 0.737999975681304931640625, 0.670000016689300537109375, 0.563000023365020751953125, 0.4309999942779541015625, 0.3039999902248382568359375, 0.1940000057220458984375, 0.1019999980926513671875, 0.0309999994933605194091796875, 0.614000022411346435546875, 0.609000027179718017578125, 0.566999971866607666015625, 0.499000012874603271484375, 0.412000000476837158203125, 0.32400000095367431640625, 0.240999996662139892578125, 0.162000000476837158203125, 0.087999999523162841796875, 0.538999974727630615234375, 0.535000026226043701171875, 0.505999982357025146484375, 0.4569999873638153076171875, 0.393999993801116943359375, 0.328999996185302734375, 0.2660000026226043701171875, 0.203999996185302734375, 0.14200000464916229248046875);\n\nuniform vec4 fa_mesh_fs_params[24];\nuniform vec4 fa_shadows[30];\nlayout(binding = 0) uniform sampler2D fa_light_tex_fa_shadow_smp;\nlayout(binding = 1) uniform sampler2D fa_tex_fa_smp;\nlayout(binding = 2) uniform sampler2D fa_normal_tex_fa_smp;\nlayout(binding = 3) uniform sampler2D fa_mr_tex_fa_smp;\nlayout(binding = 4) uniform sampler2D fa_occlusion_tex_fa_smp;\nlayout(binding = 5) uniform sampler2D fa_emissive_tex_fa_smp;\nlayout(binding = 6) uniform sampler2D fa_decal_tex_fa_env_smp;\nlayout(binding = 7) uniform sampler2D fa_lightmap_fa_env_smp;\nlayout(binding = 8) uniform samplerCube fa_irr_tex_fa_env_smp;\nlayout(binding = 9) uniform sampler2D fa_light_atlas_fa_env_smp;\nlayout(binding = 10) uniform sampler2D fa_shadow_tex_fa_shadow_smp;\nlayout(binding = 11) uniform samplerCube fa_env_tex_fa_env_smp;\n\nlayout(location = 0) in vec3 fa_world_pos;\nlayout(location = 5) in vec3 fa_lm;\nlayout(location = 1) in vec3 fa_world_normal;\nlayout(location = 2) in vec4 fa_world_tangent;\nlayout(location = 3) in vec2 fa_uv;\nlayout(location = 4) in vec4 fa_vertex_color;\nlayout(location = 0) out vec4 fa_frag_color;\nvec3 fa_light_tint;\nbool fa_light_is_area;\nint fa_cl_ndir;\nint fa_cl_slot;\nint fa_cl_local;\n\nvoid fa_inst_load()\n{\n}\n\nvec4 fa_light_texel(int t)\n{\n    return texelFetch(fa_light_tex_fa_shadow_smp, ivec2(t & 1023, t >> 10), 0);\n}\n\nvec4 fa_cluster_texel(vec3 world_pos)\n{\n    bool _1473 = fa_mesh_fs_params[19].x < 0.0;\n    bool _1480;\n    if (!_1473)\n    {\n        _1480 = fa_mesh_fs_params[19].w < 1.0;\n    }\n    else\n    {\n        _1480 = _1473;\n    }\n    bool _1488;\n    if (!_1480)\n    {\n        _1488 = fa_mesh_fs_params[18].x < 1.0;\n    }\n    else\n    {\n        _1488 = _1480;\n    }\n    bool _1495;\n    if (!_1488)\n    {\n        _1495 = fa_mesh_fs_params[18].y < 1.0;\n    }\n    else\n    {\n        _1495 = _1488;\n    }\n    bool _1502;\n    if (!_1495)\n    {\n        _1502 = fa_mesh_fs_params[19].y < 1.0;\n    }\n    else\n    {\n        _1502 = _1495;\n    }\n    if (_1502)\n    {\n        return vec4(0.0);\n    }\n    vec4 _1512 = vec4(world_pos, 1.0);\n    float _1518 = dot(fa_mesh_fs_params[16], _1512);\n    if (!(_1518 > 9.9999999747524270787835121154785e-07))\n    {\n        return vec4(0.0);\n    }\n    vec2 _1540 = vec2(dot(fa_mesh_fs_params[14], _1512), dot(fa_mesh_fs_params[15], _1512)) / vec2(_1518);\n    int _1544 = int(fa_mesh_fs_params[18].x);\n    int _1548 = int(fa_mesh_fs_params[18].y);\n    int param = (int(fa_mesh_fs_params[19].x) + (((clamp(int(floor(log2(max(dot(fa_mesh_fs_params[17].xyz, world_pos) + fa_mesh_fs_params[17].w, fa_mesh_fs_params[18].w) / fa_mesh_fs_params[18].w) * fa_mesh_fs_params[18].z)), 0, int(fa_mesh_fs_params[19].y) - 1) * _1548) + clamp(int(floor(((_1540.y * 0.5) + 0.5) * fa_mesh_fs_params[18].y)), 0, _1548 - 1)) * _1544)) + clamp(int(floor(((_1540.x * 0.5) + 0.5) * fa_mesh_fs_params[18].x)), 0, _1544 - 1);\n    return fa_light_texel(param);\n}\n\nivec2 fa_cluster_lookup(vec3 world_pos)\n{\n    vec3 param = world_pos;\n    vec4 _1624 = fa_cluster_texel(param);\n    return ivec2(int(_1624.x), int(_1624.y));\n}\n\nvoid fa_cluster_begin(vec3 world_pos)\n{\n    fa_cl_ndir = int(fa_mesh_fs_params[19].z);\n    vec3 param = world_pos;\n    ivec2 _4317 = fa_cluster_lookup(param);\n    fa_cl_slot = _4317.x;\n    fa_cl_local = _4317.y;\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nvec3 fa_linear_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_tex_fix(inout vec3 c, float mode)\n{\n    if (mode > 1.5)\n    {\n        vec3 param = c;\n        vec3 _5410 = fa_linear_to_srgb(param);\n        c = _5410;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            vec3 param_1 = c;\n            vec3 _5418 = fa_srgb_to_linear(param_1);\n            c = _5418;\n        }\n    }\n    return c;\n}\n\nvec3 fa_tangent_normal(SurfaceInput i, vec3 m)\n{\n    vec3 _417;\n    if (i.front_facing)\n    {\n        _417 = i.world_normal;\n    }\n    else\n    {\n        _417 = -i.world_normal;\n    }\n    vec3 _441 = normalize(i.world_tangent.xyz - (_417 * dot(_417, i.world_tangent.xyz)));\n    vec3 _469 = normalize(((_441 * m.x) + ((cross(_417, _441) * i.world_tangent.w) * m.y)) + (_417 * m.z));\n    vec3 _472;\n    if (i.front_facing)\n    {\n        _472 = _469;\n    }\n    else\n    {\n        _472 = -_469;\n    }\n    return _472;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    vec4 base_t = texture(fa_tex_fa_smp, i.uv);\n    float param = fa_mesh_fs_params[6].w;\n    float param_1 = 1.0;\n    vec3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    vec3 _5449 = fa_tex_fix(param_2, param_3);\n    vec4 _6864 = base_t;\n    _6864.x = _5449.x;\n    _6864.y = _5449.y;\n    _6864.z = _5449.z;\n    base_t = _6864;\n    vec4 _5463 = (_6864 * fa_mesh_fs_params[2]) * i.vertex_color;\n    vec3 _6702 = i.world_normal;\n    if (fa_mesh_fs_params[6].z > 0.5)\n    {\n        float param_4 = fa_mesh_fs_params[6].w;\n        float param_5 = 16.0;\n        vec3 param_6 = texture(fa_normal_tex_fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        vec3 _5495 = fa_tex_fix(param_6, param_7);\n        vec3 _5498 = (_5495 * 2.0) - vec3(1.0);\n        vec2 _5503 = _5498.xy * fa_mesh_fs_params[6].x;\n        vec3 _6872 = _5498;\n        _6872.x = _5503.x;\n        _6872.y = _5503.y;\n        SurfaceInput param_8 = i;\n        vec3 param_9 = _6872;\n        _6702 = fa_tangent_normal(param_8, param_9);\n    }\n    vec4 mrt = texture(fa_mr_tex_fa_smp, i.uv);\n    float param_10 = fa_mesh_fs_params[6].w;\n    float param_11 = 64.0;\n    vec3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    vec3 _5531 = fa_tex_fix(param_12, param_13);\n    vec4 _6875 = mrt;\n    _6875.x = _5531.x;\n    _6875.y = _5531.y;\n    _6875.z = _5531.z;\n    mrt = _6875;\n    vec4 _5559 = texture(fa_occlusion_tex_fa_smp, i.uv);\n    float param_14 = fa_mesh_fs_params[6].w;\n    float param_15 = 256.0;\n    vec3 param_16 = _5559.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    vec3 _5570 = fa_tex_fix(param_16, param_17);\n    float param_18 = fa_mesh_fs_params[6].w;\n    float param_19 = 4.0;\n    vec3 param_20 = texture(fa_emissive_tex_fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    vec3 _5600 = fa_tex_fix(param_20, param_21);\n    float _6707 = fa_mesh_fs_params[20].x;\n    float _6708 = fa_mesh_fs_params[20].y;\n    float _6711 = fa_mesh_fs_params[20].z;\n    float _6710 = fa_mesh_fs_params[21].w;\n    float _6713 = fa_mesh_fs_params[22].x;\n    if (fa_mesh_fs_params[22].z > 0.5)\n    {\n        if (mod(fa_mesh_fs_params[22].z, 2.0) > 0.5)\n        {\n            _6707 *= _5570.y;\n            _6708 *= _5570.z;\n            _6710 *= _5559.w;\n        }\n        if (fa_mesh_fs_params[22].z > 1.5)\n        {\n            _6711 *= mrt.x;\n            _6713 *= mrt.w;\n        }\n    }\n    return Surface(_5463.xyz, _5463.w, _6702, clamp(fa_mesh_fs_params[5].x * _5531.z, 0.0, 1.0), clamp(fa_mesh_fs_params[5].y * _5531.y, 0.0500000007450580596923828125, 1.0), 1.0 + (fa_mesh_fs_params[6].y * (_5570.x - 1.0)), fa_mesh_fs_params[3].xyz + (fa_mesh_fs_params[4].xyz * _5600), _6707, _6708, fa_mesh_fs_params[21].xyz, _6710, _6711, fa_mesh_fs_params[20].w, _6713, fa_mesh_fs_params[22].y, fa_mesh_fs_params[23].xyz);\n}\n\nvoid surface(SurfaceInput i, inout Surface s)\n{\n    s.emission += vec3(0.5 + (0.5 * sin(fa_mesh_fs_params[13].x * 3.0)), 0.25 * fract(fa_mesh_fs_params[13].x), 0.0);\n}\n\nvec4 fa_decal_tile(vec4 rect, vec2 uv, vec2 atlas, vec2 ddx, vec2 ddy)\n{\n    vec2 _1704 = rect.zw - rect.xy;\n    vec2 _1708 = _1704 * atlas;\n    vec2 _1712 = ddx * _1708;\n    vec2 _1716 = ddy * _1708;\n    return textureLod(fa_decal_tex_fa_env_smp, rect.xy + (clamp(uv, vec2(0.0), vec2(1.0)) * _1704), clamp(0.5 * log2(max(max(dot(_1712, _1712), dot(_1716, _1716)), 9.9999999392252902907785028219223e-09)), 0.0, 4.0));\n}\n\nvec3 fa_dc_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_dc_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvoid fa_apply_decals(vec3 world_pos, vec3 geo_normal, inout vec3 albedo, inout vec3 normal)\n{\n    bool _1749 = fa_mesh_fs_params[10].y < 0.5;\n    bool _1756;\n    if (!_1749)\n    {\n        _1756 = fa_mesh_fs_params[10].w < 0.5;\n    }\n    else\n    {\n        _1756 = _1749;\n    }\n    if (_1756)\n    {\n        return;\n    }\n    vec3 _1762 = dFdx(world_pos);\n    vec3 _1765 = dFdy(world_pos);\n    vec3 param = world_pos;\n    vec4 _1769 = fa_cluster_texel(param);\n    int _1773 = int(_1769.w);\n    if (_1773 < 1)\n    {\n        return;\n    }\n    int _1783 = int(fa_mesh_fs_params[10].y + 0.5);\n    int param_1 = _1783;\n    vec4 _1787 = fa_light_texel(param_1);\n    vec2 _1790 = _1787.yz;\n    int _1794 = int(_1787.w);\n    int param_2 = _1783 + 1;\n    vec4 _1799 = fa_light_texel(param_2);\n    float _1800 = _1799.x;\n    int _1806 = int(fa_mesh_fs_params[10].w + 0.5) - 1;\n    int _1810 = int(_1769.z);\n    vec3 _2075;\n    for (int k = 0; k < _1773; k++)\n    {\n        int _1823 = _1810 + k;\n        int param_3 = _1794 + (_1823 >> 2);\n        int _1840 = (_1783 + 2) + (int(fa_light_texel(param_3)[_1823 & 3]) * 7);\n        int param_4 = _1840 + 6;\n        vec4 _1845 = fa_light_texel(param_4);\n        if (((int(_1845.w + 0.5) >> _1806) & 1) == 0)\n        {\n            continue;\n        }\n        int param_5 = _1840;\n        vec4 _1860 = fa_light_texel(param_5);\n        int param_6 = _1840 + 1;\n        vec4 _1865 = fa_light_texel(param_6);\n        int param_7 = _1840 + 2;\n        vec4 _1870 = fa_light_texel(param_7);\n        vec3 _1873 = _1860.xyz;\n        float _1878 = dot(_1873, world_pos) + _1860.w;\n        vec3 _1880 = _1865.xyz;\n        float _1885 = dot(_1880, world_pos) + _1865.w;\n        vec3 _1887 = _1870.xyz;\n        float _1892 = dot(_1887, world_pos) + _1870.w;\n        bool _1897 = abs(_1878) > 0.5;\n        bool _1905;\n        if (!_1897)\n        {\n            _1905 = abs(_1885) > 0.5;\n        }\n        else\n        {\n            _1905 = _1897;\n        }\n        bool _1913;\n        if (!_1905)\n        {\n            _1913 = abs(_1892) > 0.5;\n        }\n        else\n        {\n            _1913 = _1905;\n        }\n        if (_1913)\n        {\n            continue;\n        }\n        float _1928 = clamp(dot(geo_normal, normalize(_1887)) * _1845.z, 0.0, 1.0);\n        if (_1928 <= 0.0)\n        {\n            continue;\n        }\n        float _1948 = (clamp((0.5 - abs(_1892)) * 10.0, 0.0, 1.0) * _1928) * _1845.x;\n        vec2 _1956 = vec2(_1878 + 0.5, 0.5 - _1885);\n        vec2 _1966 = vec2(dot(_1873, _1762), dot(_1880, _1762));\n        vec2 _1976 = vec2(dot(_1873, _1765), dot(_1880, _1765));\n        int param_8 = _1840 + 5;\n        vec4 _1981 = fa_light_texel(param_8);\n        int param_9 = _1840 + 3;\n        vec4 _1986 = fa_light_texel(param_9);\n        int param_10 = _1840 + 4;\n        vec4 _1991 = fa_light_texel(param_10);\n        float tex_a = 1.0;\n        vec3 col = _1981.xyz;\n        bool _2001 = _1986.z > _1986.x;\n        if (_2001)\n        {\n            vec4 param_11 = _1986;\n            vec2 param_12 = _1956;\n            vec2 param_13 = _1790;\n            vec2 param_14 = _1966;\n            vec2 param_15 = _1976;\n            vec4 tx = fa_decal_tile(param_11, param_12, param_13, param_14, param_15);\n            if ((_1800 > 0.5) && (_1800 < 1.5))\n            {\n                vec3 param_16 = tx.xyz;\n                vec3 _2027 = fa_dc_to_linear(param_16);\n                vec4 _6782 = tx;\n                _6782.x = _2027.x;\n                _6782.y = _2027.y;\n                _6782.z = _2027.z;\n                tx = _6782;\n            }\n            col *= tx.xyz;\n            tex_a = tx.w;\n        }\n        albedo = mix(albedo, col, vec3(clamp((_1948 * tex_a) * _1981.w, 0.0, 1.0)));\n        if (_1991.z > _1991.x)\n        {\n            vec4 param_17 = _1991;\n            vec2 param_18 = _1956;\n            vec2 param_19 = _1790;\n            vec2 param_20 = _1966;\n            vec2 param_21 = _1976;\n            vec4 _2071 = fa_decal_tile(param_17, param_18, param_19, param_20, param_21);\n            if (_1800 > 1.5)\n            {\n                vec3 param_22 = _2071.xyz;\n                vec3 _2081 = fa_dc_to_srgb(param_22);\n                _2075 = _2081;\n            }\n            else\n            {\n                _2075 = _2071.xyz;\n            }\n            vec3 _2090 = (_2075 * 2.0) - vec3(1.0);\n            vec2 _2095 = _2090.xy * _1845.y;\n            vec3 _2117 = (normalize(_1873) * _2095.x) + (normalize(_1880) * _2095.y);\n            vec3 _2120 = normalize(normal);\n            normal = normalize(mix(_2120, normalize((_2120 * max(_2090.z, 0.0500000007450580596923828125)) + (_2117 - (_2120 * dot(_2120, _2117)))), vec3(clamp(_1948 * (_2001 ? tex_a : 1.0), 0.0, 1.0))));\n        }\n    }\n}\n\nfloat fa_sheen_albedo(float ndv, float rough)\n{\n    float _3421 = min(sqrt(max(rough - 0.100000001490116119384765625, 0.0) * 1.111111164093017578125) * 6.0, 5.999000072479248046875);\n    float _3429 = min(sqrt(clamp(ndv, 0.0, 1.0)) * 8.0, 7.999000072479248046875);\n    int _3432 = int(_3421);\n    int _3435 = int(_3429);\n    float _3445 = _3429 - float(_3435);\n    int _3501 = (_3432 * 9) + _3435;\n    int _3521 = ((_3432 + 1) * 9) + _3435;\n    return mix(mix(_3496[_3501], _3496[_3501 + 1], _3445), mix(_3496[_3521], _3496[_3521 + 1], _3445), _3421 - float(_3432));\n}\n\nFaLayers fa_layers_setup(SurfaceInput i, Surface s, vec3 n, vec3 v, float metallic, float roughness, inout vec3 f0)\n{\n    bool _6625 = false;\n    float _6626 = 1.0;\n    float _6627 = 1.0;\n    float _6628 = 1.0;\n    float _6629 = 0.0;\n    float _6630 = 0.0;\n    float _6631 = 0.0;\n    float _6632 = 0.0;\n    float _6634 = 1.0;\n    bool _6635 = false;\n    vec3 _6636 = vec3(0.0);\n    float _6637 = 1.0;\n    float _6638 = 1.0;\n    float _6639 = 1.0;\n    float _6640 = 0.0;\n    float _6641 = 0.0;\n    vec3 _6642 = vec3(1.0, 0.0, 0.0);\n    vec3 _6643 = vec3(0.0, 0.0, 1.0);\n    float _6644 = 1.0;\n    float _6645 = 1.0;\n    float _3572 = clamp(s.specular, 0.0, 1.0);\n    float _3576 = clamp(s.ior, 1.0, 3.0);\n    bool _3581 = (_3572 != 1.0) || (_3576 != 1.5);\n    bool _3590;\n    if (!_3581)\n    {\n        _3590 = any(notEqual(s.specular_color, vec3(1.0)));\n    }\n    else\n    {\n        _3590 = _3581;\n    }\n    if (_3590)\n    {\n        float _3598 = (_3576 - 1.0) / (_3576 + 1.0);\n        f0 = mix(min(vec3(_3598 * _3598) * max(s.specular_color, vec3(0.0)), vec3(1.0)) * _3572, s.albedo, vec3(metallic));\n        _6626 = mix(_3572, 1.0, metallic);\n        _6625 = true;\n    }\n    float _3625 = clamp(s.clearcoat, 0.0, 1.0);\n    if (_3625 > 0.0)\n    {\n        float _3633 = clamp(s.clearcoat_roughness, 0.0500000007450580596923828125, 1.0);\n        _6629 = _3625;\n        _6630 = _3633;\n        float _3640 = _3633 * _3633;\n        _6631 = _3640;\n        _6632 = _3640 * _3640;\n        float _3652 = max(dot(i.world_normal, v), 9.9999997473787516355514526367188e-05);\n        _6634 = _3652;\n        _6627 = 1.0 - (_3625 * (0.039999999105930328369140625 + (0.959999978542327880859375 * pow(clamp(1.0 - _3652, 0.0, 1.0), 5.0))));\n        _6625 = true;\n    }\n    vec3 _3672 = max(s.sheen_color, vec3(0.0));\n    float _3681 = max(_3672.x, max(_3672.y, _3672.z));\n    if (_3681 > 0.0)\n    {\n        float _3689 = clamp(s.sheen_roughness, 0.100000001490116119384765625, 1.0);\n        _6635 = true;\n        _6636 = _3672;\n        _6637 = _3689;\n        _6638 = _3689 * _3689;\n        float param = max(dot(n, v), 9.9999997473787516355514526367188e-05);\n        float param_1 = _3689;\n        float _3706 = fa_sheen_albedo(param, param_1);\n        _6640 = _3706;\n        _6639 = 1.0 - min(_3681 * _3706, 1.0);\n        _6625 = true;\n    }\n    _6628 = _6627 * _6639;\n    float _3725 = clamp(s.anisotropy, -1.0, 1.0);\n    if (_3725 != 0.0)\n    {\n        vec3 _3740 = i.world_tangent.xyz - (n * dot(n, i.world_tangent.xyz));\n        vec3 t = _3740;\n        if (dot(_3740, _3740) < 9.9999999392252902907785028219223e-09)\n        {\n            bvec3 _3752 = bvec3(abs(n.y) < 0.9900000095367431640625);\n            t = cross(vec3(_3752.x ? vec3(0.0, 1.0, 0.0).x : vec3(1.0, 0.0, 0.0).x, _3752.y ? vec3(0.0, 1.0, 0.0).y : vec3(1.0, 0.0, 0.0).y, _3752.z ? vec3(0.0, 1.0, 0.0).z : vec3(1.0, 0.0, 0.0).z), n);\n        }\n        vec3 _3756 = t;\n        vec3 _3757 = normalize(_3756);\n        t = _3757;\n        vec3 _3782 = normalize((_3757 * cos(s.anisotropy_rotation)) + ((cross(n, _3757) * ((i.world_tangent.w < 0.0) ? (-1.0) : 1.0)) * sin(s.anisotropy_rotation)));\n        _6642 = _3782;\n        _6643 = cross(n, _3782);\n        float _3792 = roughness * roughness;\n        float _3798 = mix(_3792, 1.0, _3725 * _3725);\n        bool _3800 = _3725 > 0.0;\n        _6644 = _3800 ? _3798 : _3792;\n        _6645 = _3800 ? _3792 : _3798;\n        _6641 = _3725;\n        _6625 = true;\n    }\n    return FaLayers(_6625, _6626, _6627, _6628, _6629, _6630, _6631, _6632, i.world_normal, _6634, _6635, _6636, _6637, _6638, _6639, _6640, _6641, _6642, _6643, _6644, _6645);\n}\n\nvec3 fa_ambient_light(vec3 n)\n{\n    if (fa_mesh_fs_params[11].w > 0.5)\n    {\n        return textureLod(fa_irr_tex_fa_env_smp, n, 0.0).xyz;\n    }\n    return fa_mesh_fs_params[1].xyz;\n}\n\nvec3 fa_indirect_diffuse(vec3 n)\n{\n    if (fa_lm.z > 0.5)\n    {\n        return textureLod(fa_lightmap_fa_env_smp, fa_lm.xy, 0.0).xyz;\n    }\n    vec3 param = n;\n    return fa_ambient_light(param);\n}\n\nint fa_cluster_index(int slot, int n)\n{\n    int param = (int(fa_mesh_fs_params[19].x) + int(fa_mesh_fs_params[19].w)) + ((slot + n) >> 2);\n    vec4 t = fa_light_texel(param);\n    return int(t[(slot + n) & 3]);\n}\n\nint fa_cl_light(int n)\n{\n    if (n < fa_cl_ndir)\n    {\n        return n;\n    }\n    int param = fa_cl_slot;\n    int param_1 = n - fa_cl_ndir;\n    return fa_cluster_index(param, param_1);\n}\n\nint fa_light_base(int li)\n{\n    return li * ((fa_mesh_fs_params[1].w > 4.5) ? 8 : 4);\n}\n\nbool fa_light_baked(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 3;\n    return fa_light_texel(param_1).w > 0.5;\n}\n\nfloat fa_light_type(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 1;\n    return fa_light_texel(param_1).w;\n}\n\nvec4 fa_atlas_fetch(vec2 texel)\n{\n    return textureLod(fa_light_atlas_fa_env_smp, texel / vec2(textureSize(fa_light_atlas_fa_env_smp, 0)), 0.0);\n}\n\nvec3 fa_cookie_sample(vec2 tile_origin, vec2 uv)\n{\n    vec2 param = (tile_origin + vec2(1.0)) + (clamp(uv, vec2(0.0), vec2(1.0)) * 254.0);\n    return fa_atlas_fetch(param).xyz;\n}\n\nvec3 fa_area_point(vec3 c, vec3 axis, vec3 ru, vec3 uu, float hx, float hy, float shape, vec3 p, vec3 r)\n{\n    bool _722 = dot(r, r) > 0.5;\n    if (shape > 1.5)\n    {\n        vec3 _735 = (c - (ru * hx)) - p;\n        vec3 _741 = ru * (2.0 * hx);\n        float _747 = max(dot(_741, _741), 9.9999999392252902907785028219223e-09);\n        float _751 = dot(_735, _741);\n        float t = clamp((-_751) / _747, 0.0, 1.0);\n        if (_722)\n        {\n            float _766 = dot(r, _741);\n            float _772 = _747 - (_766 * _766);\n            if (abs(_772) > (9.9999997473787516355514526367188e-06 * _747))\n            {\n                t = clamp(((dot(r, _735) * _766) - _751) / _772, 0.0, 1.0);\n            }\n        }\n        return (p + _735) + (_741 * t);\n    }\n    vec3 q = p;\n    float _804 = dot(r, axis);\n    bool _812;\n    if (_722)\n    {\n        _812 = abs(_804) > 9.9999997473787516355514526367188e-05;\n    }\n    else\n    {\n        _812 = _722;\n    }\n    if (_812)\n    {\n        float _822 = dot(c - p, axis) / _804;\n        if (_822 > 0.0)\n        {\n            q = p + (r * _822);\n        }\n    }\n    vec3 _835 = q - c;\n    vec2 xy = vec2(dot(_835, ru), dot(_835, uu));\n    if (shape > 0.5)\n    {\n        float _850 = length(xy);\n        if (_850 > hx)\n        {\n            xy *= (hx / _850);\n        }\n    }\n    else\n    {\n        xy = clamp(xy, vec2(-hx, -hy), vec2(hx, hy));\n    }\n    return (c + (ru * xy.x)) + (uu * xy.y);\n}\n\nint fa_cube_face(vec3 d)\n{\n    vec3 _643 = abs(d);\n    float _645 = _643.x;\n    float _647 = _643.y;\n    bool _648 = _645 >= _647;\n    bool _656;\n    if (_648)\n    {\n        _656 = _645 >= _643.z;\n    }\n    else\n    {\n        _656 = _648;\n    }\n    int _657;\n    if (_656)\n    {\n        _657 = (d.x > 0.0) ? 0 : 1;\n    }\n    else\n    {\n        int _670;\n        if (_647 >= _643.z)\n        {\n            _670 = (d.y > 0.0) ? 2 : 3;\n        }\n        else\n        {\n            _670 = (d.z > 0.0) ? 4 : 5;\n        }\n        _657 = _670;\n    }\n    return _657;\n}\n\nvoid fa_cube_face_basis(int f, out vec3 fwd, out vec3 up)\n{\n    if (f == 0)\n    {\n        fwd = vec3(1.0, 0.0, 0.0);\n        up = vec3(0.0, 1.0, 0.0);\n    }\n    else\n    {\n        if (f == 1)\n        {\n            fwd = vec3(-1.0, 0.0, 0.0);\n            up = vec3(0.0, 1.0, 0.0);\n        }\n        else\n        {\n            if (f == 2)\n            {\n                fwd = vec3(0.0, 1.0, 0.0);\n                up = vec3(0.0, 0.0, 1.0);\n            }\n            else\n            {\n                if (f == 3)\n                {\n                    fwd = vec3(0.0, -1.0, 0.0);\n                    up = vec3(0.0, 0.0, -1.0);\n                }\n                else\n                {\n                    if (f == 4)\n                    {\n                        fwd = vec3(0.0, 0.0, 1.0);\n                        up = vec3(0.0, 1.0, 0.0);\n                    }\n                    else\n                    {\n                        fwd = vec3(0.0, 0.0, -1.0);\n                        up = vec3(0.0, 1.0, 0.0);\n                    }\n                }\n            }\n        }\n    }\n}\n\nfloat fa_ies_sample(vec2 tile_origin, vec3 d, vec3 axis, vec3 right, vec3 up)\n{\n    float _596 = dot(d, right);\n    float _600 = dot(d, up);\n    float _611;\n    if (((_596 * _596) + (_600 * _600)) > 1.0000000133514319600180897396058e-10)\n    {\n        _611 = atan(_600, _596) * 0.15915493667125701904296875;\n    }\n    else\n    {\n        _611 = 0.0;\n    }\n    vec2 param = tile_origin + vec2(1.0 + ((_611 - floor(_611)) * 64.0), 1.0 + (acos(clamp(dot(d, axis), -1.0, 1.0)) * 10.18591594696044921875));\n    return fa_atlas_fetch(param).x;\n}\n\nLightSample fa_light_sample_n(int li, vec3 world_pos, vec3 n)\n{\n    int param = li;\n    int _888 = fa_light_base(param);\n    bool _892 = fa_mesh_fs_params[1].w > 4.5;\n    int param_1 = _888;\n    vec4 _896 = fa_light_texel(param_1);\n    int param_2 = _888 + 1;\n    vec4 _901 = fa_light_texel(param_2);\n    float _904 = _901.w;\n    float atten = 1.0;\n    float dist = 0.0;\n    fa_light_tint = vec3(1.0);\n    bool _916 = _892 && (_904 > 2.5);\n    fa_light_is_area = _916;\n    bool _918 = _904 < 0.5;\n    vec3 l;\n    if (_918)\n    {\n        l = normalize(_896.xyz);\n        if (_892)\n        {\n            int param_3 = _888 + 6;\n            vec4 _932 = fa_light_texel(param_3);\n            if (_932.z > 0.5)\n            {\n                int param_4 = _888 + 4;\n                vec4 _942 = fa_light_texel(param_4);\n                int param_5 = _888 + 5;\n                vec4 _947 = fa_light_texel(param_5);\n                vec2 param_6 = _932.xy;\n                vec2 param_7 = fract(vec2(dot(world_pos, _942.xyz) * _942.w, (-dot(world_pos, _947.xyz)) * _947.w) + vec2(0.5));\n                fa_light_tint = fa_cookie_sample(param_6, param_7);\n            }\n        }\n    }\n    else\n    {\n        vec3 _977 = _896.xyz;\n        vec3 _979 = _977 - world_pos;\n        vec3 to_light = _979;\n        float _982 = length(_979);\n        float reach = _982;\n        bool front = true;\n        if (_916)\n        {\n            int param_8 = _888 + 7;\n            reach = max(_982 - fa_light_texel(param_8).w, 0.0);\n            int param_9 = _888 + 4;\n            vec4 _1006 = fa_light_texel(param_9);\n            int param_10 = _888 + 5;\n            vec4 _1011 = fa_light_texel(param_10);\n            int param_11 = _888 + 6;\n            vec4 _1016 = fa_light_texel(param_11);\n            float _1017 = _1016.w;\n            int param_12 = _888 + 2;\n            vec3 _1024 = normalize(fa_light_texel(param_12).xyz);\n            bool _1026 = _1017 > 1.5;\n            bool _1034;\n            if (!_1026)\n            {\n                _1034 = dot(_1024, to_light) < 0.0;\n            }\n            else\n            {\n                _1034 = _1026;\n            }\n            front = _1034;\n            vec3 r = vec3(0.0);\n            vec3 _1043 = fa_mesh_fs_params[0].xyz - world_pos;\n            bool _1047 = dot(n, n) > 0.5;\n            bool _1055;\n            if (_1047)\n            {\n                _1055 = dot(_1043, _1043) > 9.9999999600419720025001879548654e-13;\n            }\n            else\n            {\n                _1055 = _1047;\n            }\n            if (_1055)\n            {\n                r = reflect(-normalize(_1043), normalize(n));\n            }\n            vec3 param_13 = _977;\n            vec3 param_14 = _1024;\n            vec3 param_15 = _1006.xyz;\n            vec3 param_16 = _1011.xyz;\n            float param_17 = _1006.w;\n            float param_18 = _1011.w;\n            float param_19 = _1017;\n            vec3 param_20 = world_pos;\n            vec3 param_21 = r;\n            to_light = fa_area_point(param_13, param_14, param_15, param_16, param_17, param_18, param_19, param_20, param_21) - world_pos;\n        }\n        float _1091 = length(to_light);\n        dist = _1091;\n        l = to_light / vec3(max(_1091, 9.9999997473787516355514526367188e-05));\n        float _1105 = reach / max(_896.w, 0.001000000047497451305389404296875);\n        float _1111 = clamp(1.0 - (_1105 * _1105), 0.0, 1.0);\n        float _1113;\n        if (front)\n        {\n            _1113 = _1111 * _1111;\n        }\n        else\n        {\n            _1113 = 0.0;\n        }\n        atten = _1113;\n        bool _1124 = _904 < 2.5;\n        if ((_904 > 1.5) && _1124)\n        {\n            int param_22 = _888 + 2;\n            vec4 _1132 = fa_light_texel(param_22);\n            float _1142 = _1132.w;\n            int param_23 = _888 + 3;\n            vec4 _1147 = fa_light_texel(param_23);\n            float _1148 = _1147.x;\n            float cos_inner = _1148;\n            if (_1148 > 1.5)\n            {\n                cos_inner = mix(_1142, 1.0, 0.25);\n            }\n            atten *= smoothstep(_1142, cos_inner, dot(-l, normalize(_1132.xyz)));\n        }\n        if (_892 && (_904 < 1.5))\n        {\n            int param_24 = _888 + 6;\n            vec4 _1172 = fa_light_texel(param_24);\n            if (_1172.z > 0.5)\n            {\n                vec3 _1180 = -to_light;\n                int param_25 = _888 + 4;\n                int param_26 = _888 + 5;\n                vec3 _1194 = fa_light_texel(param_25).xyz;\n                vec3 _1198 = fa_light_texel(param_26).xyz;\n                vec3 _1207 = vec3(dot(_1180, _1194), dot(_1180, _1198), dot(_1180, cross(_1194, _1198)));\n                vec3 param_27 = _1207;\n                int _1211 = fa_cube_face(param_27);\n                int param_28 = _1211;\n                vec3 param_29;\n                vec3 param_30;\n                fa_cube_face_basis(param_28, param_29, param_30);\n                vec2 _1238 = vec2(dot(_1207, cross(param_29, param_30)), dot(_1207, param_30)) / vec2(max(dot(_1207, param_29), 9.9999997473787516355514526367188e-05));\n                int _1242 = _1211 / 3;\n                vec2 param_31 = _1172.xy + (vec2(float(_1211 - (_1242 * 3)), float(_1242)) * 256.0);\n                vec2 param_32 = vec2(0.5 + (0.5 * _1238.x), 0.5 - (0.5 * _1238.y));\n                fa_light_tint = fa_cookie_sample(param_31, param_32);\n            }\n            int param_33 = _888 + 7;\n            vec4 _1272 = fa_light_texel(param_33);\n            if (_1272.z > 0.5)\n            {\n                int param_34 = _888 + 2;\n                int param_35 = _888 + 4;\n                int param_36 = _888 + 5;\n                vec2 param_37 = _1272.xy;\n                vec3 param_38 = -l;\n                vec3 param_39 = normalize(fa_light_texel(param_34).xyz);\n                vec3 param_40 = fa_light_texel(param_35).xyz;\n                vec3 param_41 = fa_light_texel(param_36).xyz;\n                atten *= fa_ies_sample(param_37, param_38, param_39, param_40, param_41);\n            }\n        }\n        else\n        {\n            if (_892 && _1124)\n            {\n                int param_42 = _888 + 6;\n                vec4 _1319 = fa_light_texel(param_42);\n                int param_43 = _888 + 7;\n                vec4 _1324 = fa_light_texel(param_43);\n                bool _1327 = _1319.z > 0.5;\n                bool _1334;\n                if (!_1327)\n                {\n                    _1334 = _1324.z > 0.5;\n                }\n                else\n                {\n                    _1334 = _1327;\n                }\n                if (_1334)\n                {\n                    int param_44 = _888 + 2;\n                    vec4 _1341 = fa_light_texel(param_44);\n                    vec3 _1345 = normalize(_1341.xyz);\n                    int param_45 = _888 + 4;\n                    vec4 _1350 = fa_light_texel(param_45);\n                    int param_46 = _888 + 5;\n                    vec4 _1355 = fa_light_texel(param_46);\n                    if (_1327)\n                    {\n                        vec3 _1363 = -to_light;\n                        float _1370 = _1341.w;\n                        float _1386 = 0.5 / max(dot(_1363, _1345) * (sqrt(max(1.0 - (_1370 * _1370), 0.0)) / max(_1370, 0.001000000047497451305389404296875)), 9.9999997473787516355514526367188e-05);\n                        vec2 param_47 = _1319.xy;\n                        vec2 param_48 = vec2(0.5 + (dot(_1363, _1350.xyz) * _1386), 0.5 - (dot(_1363, _1355.xyz) * _1386));\n                        fa_light_tint = fa_cookie_sample(param_47, param_48);\n                    }\n                    if (_1324.z > 0.5)\n                    {\n                        vec2 param_49 = _1324.xy;\n                        vec3 param_50 = -l;\n                        vec3 param_51 = _1345;\n                        vec3 param_52 = _1350.xyz;\n                        vec3 param_53 = _1355.xyz;\n                        atten *= fa_ies_sample(param_49, param_50, param_51, param_52, param_53);\n                    }\n                }\n            }\n        }\n    }\n    vec3 _6613 = _901.xyz * atten;\n    if (_892)\n    {\n        _6613 *= fa_light_tint;\n    }\n    int _1455;\n    if (_918)\n    {\n        _1455 = 0;\n    }\n    else\n    {\n        _1455 = ((_904 > 1.5) && (_904 < 2.5)) ? 2 : 1;\n    }\n    return LightSample(l, _6613, atten, 1.0, dist, _1455);\n}\n\nfloat fa_shadow_split_at(int i)\n{\n    float _2192;\n    if (i == 0)\n    {\n        _2192 = fa_shadows[24].x;\n    }\n    else\n    {\n        float _2208;\n        if (i == 1)\n        {\n            _2208 = fa_shadows[24].y;\n        }\n        else\n        {\n            float _2216;\n            if (i == 2)\n            {\n                _2216 = fa_shadows[24].z;\n            }\n            else\n            {\n                _2216 = fa_shadows[24].w;\n            }\n            _2208 = _2216;\n        }\n        _2192 = _2208;\n    }\n    return _2192;\n}\n\nfloat fa_shadow_depth(inout vec2 uv, vec4 rect)\n{\n    uv = clamp(uv, rect.xy, rect.zw);\n    return textureLod(fa_shadow_tex_fa_shadow_smp, uv, 0.0).x;\n}\n\nfloat fa_shadow_fetch(vec2 uv, vec4 rect, vec3 conv)\n{\n    vec2 param = uv;\n    vec4 param_1 = rect;\n    float _2249 = fa_shadow_depth(param, param_1);\n    float _2253;\n    if (conv.x < 0.5)\n    {\n        _2253 = _2249;\n    }\n    else\n    {\n        _2253 = (conv.y * conv.z) / (conv.z - (_2249 * (conv.z - conv.y)));\n    }\n    return _2253;\n}\n\nfloat fa_shadow_noise()\n{\n    return fract(52.98291778564453125 * fract(dot(gl_FragCoord.xy, vec2(0.067110560834407806396484375, 0.005837149918079376220703125))));\n}\n\nvec2 fa_shadow_vogel(int k, int n, float phi)\n{\n    float _2180 = (float(k) * 2.3999631404876708984375) + phi;\n    return vec2(cos(_2180), sin(_2180)) * sqrt((float(k) + 0.5) / float(n));\n}\n\nfloat fa_shadow_filter(vec2 uv, vec4 rect, float zr, float texel_m, float unit, float reach, float plane, vec3 conv, int mode, float k)\n{\n    if (mode == 1)\n    {\n        vec2 param = uv;\n        vec4 param_1 = rect;\n        vec3 param_2 = conv;\n        return float(zr <= fa_shadow_fetch(param, param_1, param_2));\n    }\n    float _2299 = fa_shadow_noise() * 6.283185482025146484375;\n    float radius = 1.5;\n    if (mode == 2)\n    {\n        float _2308;\n        if (k < 0.0)\n        {\n            _2308 = (-k) / max(zr, 0.100000001490116119384765625);\n        }\n        else\n        {\n            _2308 = k;\n        }\n        float _2328 = clamp((_2308 * reach) / texel_m, 3.0, 12.0);\n        float sum = 0.0;\n        float cnt = 0.0;\n        for (int i = 0; i < 16; i++)\n        {\n            int param_3 = i;\n            int param_4 = 16;\n            float param_5 = _2299;\n            vec2 _2347 = fa_shadow_vogel(param_3, param_4, param_5) * _2328;\n            vec2 param_6 = uv + (_2347 * fa_shadows[26].zw);\n            vec4 param_7 = rect;\n            vec3 param_8 = conv;\n            float _2359 = fa_shadow_fetch(param_6, param_7, param_8);\n            if (_2359 < (zr - (length(_2347) * plane)))\n            {\n                sum += _2359;\n                cnt += 1.0;\n            }\n        }\n        if (cnt < 0.5)\n        {\n            return 1.0;\n        }\n        float _2385 = sum / cnt;\n        float _2395;\n        if (k < 0.0)\n        {\n            _2395 = (-k) / max(_2385, 0.0500000007450580596923828125);\n        }\n        else\n        {\n            _2395 = k;\n        }\n        radius = clamp(((max(zr - _2385, 0.0) * unit) * _2395) / texel_m, 1.5, 16.0);\n    }\n    float lit = 0.0;\n    int _2417 = (mode == 2) ? 24 : 16;\n    for (int i_1 = 0; i_1 < _2417; i_1++)\n    {\n        int param_9 = i_1;\n        int param_10 = _2417;\n        float param_11 = _2299;\n        vec2 _2436 = fa_shadow_vogel(param_9, param_10, param_11) * radius;\n        vec2 param_12 = uv + (_2436 * fa_shadows[26].zw);\n        vec4 param_13 = rect;\n        vec3 param_14 = conv;\n        lit += float((zr - (length(_2436) * plane)) <= fa_shadow_fetch(param_12, param_13, param_14));\n    }\n    return lit / float(_2417);\n}\n\nfloat fa_shadow_cascade(int ci, vec3 world, vec3 n, vec3 l)\n{\n    float _2478 = max(fa_shadows[ci * 1 + 20].y, 0.001000000047497451305389404296875);\n    float _2483 = clamp(dot(n, l), 0.0, 1.0);\n    float _2489 = sqrt(1.0 - (_2483 * _2483));\n    float _2496 = min(_2489 / max(_2483, 0.20000000298023223876953125), 4.0);\n    float _2501;\n    if (fa_shadows[26].y > 0.0)\n    {\n        _2501 = fa_shadows[26].y;\n    }\n    else\n    {\n        _2501 = 1.5 * fa_shadows[ci * 1 + 20].x;\n    }\n    vec4 _2526 = mat4(fa_shadows[ci * 4 + 0], fa_shadows[ci * 4 + 1], fa_shadows[ci * 4 + 2], fa_shadows[ci * 4 + 3]) * vec4(world + (n * (_2501 * _2489)), 1.0);\n    float _2533 = _2526.x;\n    bool _2536 = _2533 < fa_shadows[ci * 1 + 16].x;\n    bool _2545;\n    if (!_2536)\n    {\n        _2545 = _2533 > fa_shadows[ci * 1 + 16].z;\n    }\n    else\n    {\n        _2545 = _2536;\n    }\n    bool _2554;\n    if (!_2545)\n    {\n        _2554 = _2526.y < fa_shadows[ci * 1 + 16].y;\n    }\n    else\n    {\n        _2554 = _2545;\n    }\n    bool _2563;\n    if (!_2554)\n    {\n        _2563 = _2526.y > fa_shadows[ci * 1 + 16].w;\n    }\n    else\n    {\n        _2563 = _2554;\n    }\n    bool _2570;\n    if (!_2563)\n    {\n        _2570 = _2526.z > 1.0;\n    }\n    else\n    {\n        _2570 = _2563;\n    }\n    if (_2570)\n    {\n        return -1.0;\n    }\n    float _2578;\n    if (fa_shadows[26].x > 0.0)\n    {\n        _2578 = fa_shadows[26].x;\n    }\n    else\n    {\n        _2578 = 1.5 * fa_shadows[ci * 1 + 20].x;\n    }\n    vec2 param = _2526.xy;\n    vec4 param_1 = fa_shadows[ci * 1 + 16];\n    float param_2 = _2526.z - ((_2578 * (1.0 + (0.5 * _2496))) / _2478);\n    float param_3 = fa_shadows[ci * 1 + 20].x;\n    float param_4 = _2478;\n    float param_5 = _2478 * 0.25;\n    float param_6 = ((fa_shadows[ci * 1 + 20].x * min(_2496, 3.0)) * 0.5) / _2478;\n    vec3 param_7 = vec3(0.0);\n    int param_8 = int(fa_shadows[25].z + 0.5);\n    float param_9 = fa_shadows[25].w;\n    return fa_shadow_filter(param, param_1, param_2, param_3, param_4, param_5, param_6, param_7, param_8, param_9);\n}\n\nfloat fa_shadow_sun(vec3 world, vec3 n, vec3 l)\n{\n    if (fa_mesh_fs_params[5].z < 0.5)\n    {\n        return 1.0;\n    }\n    int _2966 = int(fa_shadows[25].x + 0.5);\n    if (_2966 < 1)\n    {\n        return 1.0;\n    }\n    float _2981 = dot(world - fa_shadows[27].xyz, fa_shadows[28].xyz);\n    int param = _2966 - 1;\n    if (_2981 > fa_shadow_split_at(param))\n    {\n        return 1.0;\n    }\n    int ci = 0;\n    bool _2993 = _2966 > 1;\n    bool _3000;\n    if (_2993)\n    {\n        _3000 = _2981 > fa_shadows[24].x;\n    }\n    else\n    {\n        _3000 = _2993;\n    }\n    if (_3000)\n    {\n        ci = 1;\n    }\n    bool _3004 = _2966 > 2;\n    bool _3011;\n    if (_3004)\n    {\n        _3011 = _2981 > fa_shadows[24].y;\n    }\n    else\n    {\n        _3011 = _3004;\n    }\n    if (_3011)\n    {\n        ci = 2;\n    }\n    bool _3015 = _2966 > 3;\n    bool _3022;\n    if (_3015)\n    {\n        _3022 = _2981 > fa_shadows[24].z;\n    }\n    else\n    {\n        _3022 = _3015;\n    }\n    if (_3022)\n    {\n        ci = 3;\n    }\n    float s = -1.0;\n    for (int k = 0; k < 4; k++)\n    {\n        if (ci >= _2966)\n        {\n            break;\n        }\n        int param_1 = ci;\n        vec3 param_2 = world;\n        vec3 param_3 = n;\n        vec3 param_4 = l;\n        float _3048 = fa_shadow_cascade(param_1, param_2, param_3, param_4);\n        s = _3048;\n        if (_3048 >= 0.0)\n        {\n            break;\n        }\n        ci++;\n    }\n    if (s < 0.0)\n    {\n        return 1.0;\n    }\n    if (fa_shadows[25].y > 0.0)\n    {\n        float _3073;\n        if (ci > 0)\n        {\n            int param_5 = ci - 1;\n            _3073 = fa_shadow_split_at(param_5);\n        }\n        else\n        {\n            _3073 = fa_shadows[28].w;\n        }\n        int param_6 = ci;\n        float _3092 = fa_shadows[25].y * max(fa_shadow_split_at(param_6) - _3073, 9.9999997473787516355514526367188e-05);\n        int param_7 = ci;\n        float _3103 = clamp((_2981 - (fa_shadow_split_at(param_7) - _3092)) / _3092, 0.0, 1.0);\n        if (_3103 > 0.0)\n        {\n            float s2 = 1.0;\n            if ((ci + 1) < _2966)\n            {\n                int param_8 = ci + 1;\n                vec3 param_9 = world;\n                vec3 param_10 = n;\n                vec3 param_11 = l;\n                float _3124 = fa_shadow_cascade(param_8, param_9, param_10, param_11);\n                s2 = _3124;\n                if (_3124 < 0.0)\n                {\n                    s2 = s;\n                }\n            }\n            s = mix(s, s2, _3103);\n        }\n    }\n    return s;\n}\n\nfloat fa_shadow_factor(vec3 n, vec3 l)\n{\n    vec3 param = fa_world_pos;\n    vec3 param_1 = n;\n    vec3 param_2 = l;\n    return fa_shadow_sun(param, param_1, param_2);\n}\n\nfloat fa_shadow_local(int li, vec3 world, vec3 n, vec3 l)\n{\n    bool _2636 = fa_mesh_fs_params[5].z < 0.5;\n    bool _2643;\n    if (!_2636)\n    {\n        _2643 = fa_shadows[29].x < 0.5;\n    }\n    else\n    {\n        _2643 = _2636;\n    }\n    if (_2643)\n    {\n        return 1.0;\n    }\n    int param = (int(fa_shadows[29].x + 0.5) - 1) + li;\n    vec4 _2656 = fa_light_texel(param);\n    float _2657 = _2656.x;\n    if (_2657 < 0.0)\n    {\n        return 1.0;\n    }\n    int _2666 = int(_2657 + 0.5);\n    int param_1 = _2666;\n    vec4 _2670 = fa_light_texel(param_1);\n    int param_2 = _2666 + 1;\n    vec4 _2675 = fa_light_texel(param_2);\n    float fade = 1.0;\n    float _2678 = _2670.y;\n    if (_2678 > 0.0)\n    {\n        float _2695 = 1.0 - smoothstep(0.75 * _2678, _2678, length(world - fa_shadows[27].xyz));\n        fade = _2695;\n        if (_2695 <= 0.0)\n        {\n            return 1.0;\n        }\n    }\n    int face = 0;\n    if (_2670.x > 1.5)\n    {\n        int param_3 = li;\n        int param_4 = fa_light_base(param_3);\n        vec3 param_5 = world - fa_light_texel(param_4).xyz;\n        face = fa_cube_face(param_5);\n    }\n    int _2724 = (_2666 + 2) + (face * 6);\n    int param_6 = _2724;\n    int param_7 = _2724 + 1;\n    int param_8 = _2724 + 3;\n    vec4 _2738 = fa_light_texel(param_8);\n    int param_9 = _2724 + 4;\n    vec4 _2743 = fa_light_texel(param_9);\n    int param_10 = _2724 + 5;\n    vec4 _2748 = fa_light_texel(param_10);\n    float _2760 = _2748.x * max(dot(_2738, vec4(world, 1.0)), 0.001000000047497451305389404296875);\n    float _2765 = clamp(dot(n, l), 0.0, 1.0);\n    float _2788 = clamp(dot(n, _2738.xyz), -1.0, 1.0);\n    int param_11 = li;\n    int param_12 = fa_light_base(param_11);\n    float _2812 = min(sqrt(1.0 - (_2788 * _2788)) / max(abs(dot(n, world - fa_light_texel(param_12).xyz)) / max(dot(_2738, vec4(world, 1.0)), 0.001000000047497451305389404296875), 0.20000000298023223876953125), 4.0);\n    float _2815 = _2675.y;\n    float _2817;\n    if (_2815 > 0.0)\n    {\n        _2817 = _2815;\n    }\n    else\n    {\n        _2817 = 1.5 * _2760;\n    }\n    vec4 _2837 = vec4(world + (n * (_2817 * sqrt(1.0 - (_2765 * _2765)))), 1.0);\n    float _2841 = dot(_2738, _2837);\n    float _2844 = _2748.y;\n    if (_2841 < _2844)\n    {\n        return 1.0;\n    }\n    vec2 _2859 = vec2(dot(fa_light_texel(param_6), _2837), dot(fa_light_texel(param_7), _2837)) / vec2(_2841);\n    float _2861 = _2859.x;\n    bool _2864 = _2861 < _2743.x;\n    bool _2873;\n    if (!_2864)\n    {\n        _2873 = _2861 > _2743.z;\n    }\n    else\n    {\n        _2873 = _2864;\n    }\n    bool _2882;\n    if (!_2873)\n    {\n        _2882 = _2859.y < _2743.y;\n    }\n    else\n    {\n        _2882 = _2873;\n    }\n    bool _2891;\n    if (!_2882)\n    {\n        _2891 = _2859.y > _2743.w;\n    }\n    else\n    {\n        _2891 = _2882;\n    }\n    if (_2891)\n    {\n        return 1.0;\n    }\n    float _2897 = _2675.x;\n    float _2899;\n    if (_2897 > 0.0)\n    {\n        _2899 = _2897;\n    }\n    else\n    {\n        _2899 = 1.5 * _2760;\n    }\n    vec2 param_13 = _2859;\n    vec4 param_14 = _2743;\n    float param_15 = _2841 - (_2899 * (1.0 + (0.5 * _2812)));\n    float param_16 = _2760;\n    float param_17 = 1.0;\n    float param_18 = _2748.z * 0.25;\n    float param_19 = (_2760 * min(_2812, 3.0)) * 0.5;\n    vec3 param_20 = vec3(1.0, _2844, _2748.z);\n    int param_21 = int(_2670.z + 0.5);\n    float param_22 = _2670.w;\n    return mix(1.0, fa_shadow_filter(param_13, param_14, param_15, param_16, param_17, param_18, param_19, param_20, param_21, param_22), fade);\n}\n\nLightSample fa_light_shadowed(int li, vec3 world_pos, vec3 gn)\n{\n    bool _4344 = fa_lm.z > 0.5;\n    bool _4350;\n    if (_4344)\n    {\n        int param = li;\n        _4350 = fa_light_baked(param);\n    }\n    else\n    {\n        _4350 = _4344;\n    }\n    if (_4350)\n    {\n        int param_1 = li;\n        return LightSample(vec3(0.0, 1.0, 0.0), vec3(0.0), 0.0, 1.0, 0.0, int(fa_light_type(param_1) + 0.5));\n    }\n    int param_2 = li;\n    vec3 param_3 = world_pos;\n    vec3 param_4 = gn;\n    LightSample _4374 = fa_light_sample_n(param_2, param_3, param_4);\n    vec3 _6682 = _4374.color;\n    float _6684 = _4374.shadow;\n    if ((_4374.type == 0) && (li == 0))\n    {\n        vec3 param_5 = gn;\n        vec3 param_6 = _4374.direction;\n        float _4388 = fa_shadow_factor(param_5, param_6);\n        _6684 = _4388;\n        _6682 *= _4388;\n    }\n    else\n    {\n        bool _4399 = _4374.type != 0;\n        bool _4405;\n        if (_4399)\n        {\n            _4405 = _4374.attenuation > 0.0;\n        }\n        else\n        {\n            _4405 = _4399;\n        }\n        if (_4405)\n        {\n            int param_7 = li;\n            vec3 param_8 = world_pos;\n            vec3 param_9 = gn;\n            vec3 param_10 = _4374.direction;\n            float _4417 = fa_shadow_local(param_7, param_8, param_9, param_10);\n            _6684 = _4417;\n            _6682 *= _4417;\n        }\n    }\n    return LightSample(_4374.direction, _6682, _4374.attenuation, _6684, _4374._distance, _4374.type);\n}\n\nvec3 fa_ltc_tangent(vec3 n, vec3 v)\n{\n    vec3 _4457 = v - (n * dot(v, n));\n    vec3 t = _4457;\n    float _4461 = dot(_4457, _4457);\n    float l2 = _4461;\n    if (_4461 < 1.0000000133514319600180897396058e-10)\n    {\n        vec3 _4471;\n        if (abs(n.z) < 0.999000012874603271484375)\n        {\n            _4471 = cross(n, vec3(0.0, 0.0, 1.0));\n        }\n        else\n        {\n            _4471 = cross(n, vec3(1.0, 0.0, 0.0));\n        }\n        t = _4471;\n        l2 = dot(_4471, _4471);\n    }\n    return t * inversesqrt(l2);\n}\n\nvec3 fa_ltc_local(vec3 t1, vec3 n, vec3 p)\n{\n    return vec3(dot(t1, p), dot(cross(n, t1), p), dot(n, p));\n}\n\nvec3 fa_ltc_edge_vector(vec3 a, vec3 b)\n{\n    float _4506 = dot(a, a);\n    float _4510 = dot(b, b);\n    if ((_4506 < 1.0000000195414813782625560981111e-24) || (_4510 < 1.0000000195414813782625560981111e-24))\n    {\n        return vec3(0.0);\n    }\n    vec3 _4524 = a * inversesqrt(_4506);\n    vec3 _4529 = b * inversesqrt(_4510);\n    float _4533 = dot(_4524, _4529);\n    float _4536 = abs(_4533);\n    float g = (((((((((((0.0416471660137176513671875 * _4536) - 0.1924748718738555908203125) * _4536) + 0.4179156124591827392578125) * _4536) - 0.616057217121124267578125) * _4536) + 0.777722418308258056640625) * _4536) - 0.999542415142059326171875) * _4536) + 1.570791721343994140625;\n    if (_4533 < 0.0)\n    {\n        g = (3.1415927410125732421875 * inversesqrt(max(1.0 - (_4533 * _4533), 1.0000000116860974230803549289703e-07))) - g;\n    }\n    return cross(_4524, _4529) * g;\n}\n\nvoid fa_ltc_clip_edge(vec3 a, vec3 b, inout vec3 sum, inout vec3 leave, inout vec3 enter, inout vec2 seen)\n{\n    bool _4593 = a.z > 0.0;\n    bool _4597 = b.z > 0.0;\n    if (_4593 && _4597)\n    {\n        vec3 param = a;\n        vec3 param_1 = b;\n        sum += fa_ltc_edge_vector(param, param_1);\n    }\n    else\n    {\n        if (_4593 != _4597)\n        {\n            vec3 _4632 = a + ((b - a) * (a.z / (a.z - b.z)));\n            _4632.z = 0.0;\n            if (_4593)\n            {\n                vec3 param_2 = a;\n                vec3 param_3 = _4632;\n                sum += fa_ltc_edge_vector(param_2, param_3);\n                leave = _4632;\n                seen.x = 1.0;\n            }\n            else\n            {\n                vec3 param_4 = _4632;\n                vec3 param_5 = b;\n                sum += fa_ltc_edge_vector(param_4, param_5);\n                enter = _4632;\n                seen.y = 1.0;\n            }\n        }\n    }\n}\n\nfloat fa_ltc_quad(vec4 abcd, vec3 p0, vec3 p1, vec3 p2, vec3 p3)\n{\n    vec3 _4681 = vec3((abcd.x * p0.x) + (abcd.y * p0.z), p0.y, (abcd.z * p0.x) + (abcd.w * p0.z));\n    vec3 _4707 = vec3((abcd.x * p1.x) + (abcd.y * p1.z), p1.y, (abcd.z * p1.x) + (abcd.w * p1.z));\n    vec3 _4733 = vec3((abcd.x * p2.x) + (abcd.y * p2.z), p2.y, (abcd.z * p2.x) + (abcd.w * p2.z));\n    vec3 _4759 = vec3((abcd.x * p3.x) + (abcd.y * p3.z), p3.y, (abcd.z * p3.x) + (abcd.w * p3.z));\n    vec3 sum = vec3(0.0);\n    vec3 leave = vec3(0.0);\n    vec3 enter = vec3(0.0);\n    vec3 param = _4681;\n    vec3 param_1 = _4707;\n    vec3 param_2 = vec3(0.0);\n    vec3 param_3 = vec3(0.0);\n    vec3 param_4 = vec3(0.0);\n    vec2 param_5 = vec2(0.0);\n    fa_ltc_clip_edge(param, param_1, param_2, param_3, param_4, param_5);\n    sum = param_2;\n    leave = param_3;\n    enter = param_4;\n    vec3 param_6 = _4707;\n    vec3 param_7 = _4733;\n    vec3 param_8 = param_2;\n    vec3 param_9 = param_3;\n    vec3 param_10 = param_4;\n    vec2 param_11 = param_5;\n    fa_ltc_clip_edge(param_6, param_7, param_8, param_9, param_10, param_11);\n    sum = param_8;\n    leave = param_9;\n    enter = param_10;\n    vec3 param_12 = _4733;\n    vec3 param_13 = _4759;\n    vec3 param_14 = param_8;\n    vec3 param_15 = param_9;\n    vec3 param_16 = param_10;\n    vec2 param_17 = param_11;\n    fa_ltc_clip_edge(param_12, param_13, param_14, param_15, param_16, param_17);\n    sum = param_14;\n    leave = param_15;\n    enter = param_16;\n    vec3 param_18 = _4759;\n    vec3 param_19 = _4681;\n    vec3 param_20 = param_14;\n    vec3 param_21 = param_15;\n    vec3 param_22 = param_16;\n    vec2 param_23 = param_17;\n    fa_ltc_clip_edge(param_18, param_19, param_20, param_21, param_22, param_23);\n    sum = param_20;\n    leave = param_21;\n    enter = param_22;\n    if ((param_23.x * param_23.y) > 0.5)\n    {\n        vec3 param_24 = leave;\n        vec3 param_25 = enter;\n        sum += fa_ltc_edge_vector(param_24, param_25);\n    }\n    return sum.z * 0.15915493667125701904296875;\n}\n\nfloat fa_ltc_rect(vec4 abcd, vec3 center, vec3 ex, vec3 ey)\n{\n    vec4 param = abcd;\n    vec3 param_1 = (center - ex) - ey;\n    vec3 param_2 = (center + ex) - ey;\n    vec3 param_3 = (center + ex) + ey;\n    vec3 param_4 = (center - ex) + ey;\n    return abs(fa_ltc_quad(param, param_1, param_2, param_3, param_4));\n}\n\nfloat fa_area_form(vec4 m, float shape, vec3 pc, vec3 ex, vec3 ey)\n{\n    if ((shape < 0.5) || (shape > 1.5))\n    {\n        vec4 param = m;\n        vec3 param_1 = pc;\n        vec3 param_2 = ex;\n        vec3 param_3 = ey;\n        return fa_ltc_rect(param, param_1, param_2, param_3);\n    }\n    vec3 _4909 = (pc + (ex * 0.92387950420379638671875)) + (ey * 0.3826834261417388916015625);\n    vec3 _4933 = (pc - (ex * 0.92387950420379638671875)) + (ey * 0.3826834261417388916015625);\n    vec3 _4949 = (pc - (ex * 0.3826834261417388916015625)) - (ey * 0.92387950420379638671875);\n    vec4 param_4 = m;\n    vec3 param_5 = _4909;\n    vec3 param_6 = (pc + (ex * 0.3826834261417388916015625)) + (ey * 0.92387950420379638671875);\n    vec3 param_7 = (pc - (ex * 0.3826834261417388916015625)) + (ey * 0.92387950420379638671875);\n    vec3 param_8 = _4933;\n    vec4 param_9 = m;\n    vec3 param_10 = _4909;\n    vec3 param_11 = _4933;\n    vec3 param_12 = (pc - (ex * 0.92387950420379638671875)) - (ey * 0.3826834261417388916015625);\n    vec3 param_13 = _4949;\n    vec4 param_14 = m;\n    vec3 param_15 = _4909;\n    vec3 param_16 = _4949;\n    vec3 param_17 = (pc + (ex * 0.3826834261417388916015625)) - (ey * 0.92387950420379638671875);\n    vec3 param_18 = (pc + (ex * 0.92387950420379638671875)) - (ey * 0.3826834261417388916015625);\n    return abs((fa_ltc_quad(param_4, param_5, param_6, param_7, param_8) + fa_ltc_quad(param_9, param_10, param_11, param_12, param_13)) + fa_ltc_quad(param_14, param_15, param_16, param_17, param_18));\n}\n\nvec2 fa_ltc_uv(float roughness, float ndv)\n{\n    return ((vec2(clamp((roughness - 0.0500000007450580596923828125) * 1.0526316165924072265625, 0.0, 1.0), sqrt(clamp(1.0 - ndv, 0.0, 1.0))) * 63.0) + vec2(0.5)) * vec2(0.015625);\n}\n\nvec3 fa_area_shade(int li, vec3 world_pos, vec3 n, vec3 v, vec3 diffuse_color, vec3 f0, float f90, float roughness, float ndv, float window)\n{\n    int param = li;\n    int _5007 = fa_light_base(param);\n    int param_1 = _5007;\n    int param_2 = _5007 + 1;\n    int param_3 = _5007 + 2;\n    int param_4 = _5007 + 4;\n    vec4 _5029 = fa_light_texel(param_4);\n    int param_5 = _5007 + 5;\n    vec4 _5034 = fa_light_texel(param_5);\n    int param_6 = _5007 + 6;\n    vec4 _5039 = fa_light_texel(param_6);\n    float _5040 = _5039.w;\n    vec3 _5045 = fa_light_texel(param_1).xyz - world_pos;\n    bool _5047 = _5040 < 1.5;\n    bool _5054;\n    if (_5047)\n    {\n        _5054 = dot(normalize(fa_light_texel(param_3).xyz), _5045) >= 0.0;\n    }\n    else\n    {\n        _5054 = _5047;\n    }\n    if (_5054)\n    {\n        return vec3(0.0);\n    }\n    bool _5063 = (_5040 > 0.5) && _5047;\n    float _5067 = _5063 ? 1.0539000034332275390625 : 1.0;\n    vec3 _5070 = _5029.xyz;\n    float _5072 = _5029.w;\n    vec3 _5078 = _5034.xyz;\n    float _5080 = _5034.w;\n    vec3 up = _5078 * (_5080 * _5067);\n    float _5086;\n    if (_5063)\n    {\n        _5086 = (3.1415927410125732421875 * _5072) * _5072;\n    }\n    else\n    {\n        _5086 = (4.0 * _5072) * _5080;\n    }\n    if (_5040 > 1.5)\n    {\n        vec3 _5112 = cross(_5070, -_5045);\n        vec3 perp = _5112;\n        float _5116 = dot(_5112, _5112);\n        vec3 _5119;\n        if (_5116 > 1.0000000133514319600180897396058e-10)\n        {\n            _5119 = perp * inversesqrt(_5116);\n        }\n        else\n        {\n            _5119 = _5078;\n        }\n        perp = _5119;\n        up = _5119 * _5080;\n    }\n    float _5140 = max(_5086, 9.9999999747524270787835121154785e-07);\n    vec3 param_7 = n;\n    vec3 param_8 = v;\n    vec3 _5150 = fa_ltc_tangent(param_7, param_8);\n    vec3 param_9 = _5150;\n    vec3 param_10 = n;\n    vec3 param_11 = _5045;\n    vec3 _5158 = fa_ltc_local(param_9, param_10, param_11);\n    vec3 param_12 = _5150;\n    vec3 param_13 = n;\n    vec3 param_14 = _5070 * (_5072 * _5067);\n    vec3 _5166 = fa_ltc_local(param_12, param_13, param_14);\n    vec3 param_15 = _5150;\n    vec3 param_16 = n;\n    vec3 param_17 = up;\n    vec3 _5174 = fa_ltc_local(param_15, param_16, param_17);\n    vec4 param_18 = vec4(1.0, 0.0, 0.0, 1.0);\n    float param_19 = _5040;\n    vec3 param_20 = _5158;\n    vec3 param_21 = _5166;\n    vec3 param_22 = _5174;\n    float param_23 = roughness;\n    float param_24 = ndv;\n    vec2 _5193 = fa_ltc_uv(param_23, param_24) * 64.0;\n    vec2 param_25 = _5193;\n    vec2 param_26 = _5193 + vec2(64.0, 0.0);\n    vec4 _5203 = fa_atlas_fetch(param_26);\n    vec4 param_27 = fa_atlas_fetch(param_25);\n    float param_28 = _5040;\n    vec3 param_29 = _5158;\n    vec3 param_30 = _5166;\n    vec3 param_31 = _5174;\n    return (((diffuse_color * fa_area_form(param_18, param_19, param_20, param_21, param_22)) + (((f0 * _5203.x) + ((vec3(f90) - f0) * _5203.y)) * fa_area_form(param_27, param_28, param_29, param_30, param_31))) * fa_light_texel(param_2).xyz) * ((((3.1415927410125732421875 * dot(_5045, _5045)) + _5140) / _5140) * window);\n}\n\nvec3 fa_light_rgb(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 1;\n    return fa_light_texel(param_1).xyz;\n}\n\nfloat fa_d_charlie(float alpha, float ndh)\n{\n    float _4047 = 1.0 / alpha;\n    return ((2.0 + _4047) * pow(sqrt(max(1.0 - (ndh * ndh), 9.9999997473787516355514526367188e-05)), _4047)) * 0.15915493667125701904296875;\n}\n\nfloat fa_v_ashikhmin(float ndl, float ndv)\n{\n    return clamp(0.25 / max((ndl + ndv) - (ndl * ndv), 9.9999997473787516355514526367188e-05), 0.0, 1.0);\n}\n\nfloat fa_layers_coat(FaLayers L, vec3 l, vec3 h, float vdh)\n{\n    float _4082 = max(dot(L.nc, l), 0.0);\n    float _4088 = max(dot(L.nc, h), 0.0);\n    float _4097 = ((_4088 * _4088) * (L.coat_a2 - 1.0)) + 1.0;\n    return (((L.coat * (0.039999999105930328369140625 + (0.959999978542327880859375 * pow(clamp(1.0 - vdh, 0.0, 1.0), 5.0)))) * (((L.coat_a2 / ((3.1415927410125732421875 * _4097) * _4097)) * (0.5 / max(mix((2.0 * _4082) * L.coat_ndv, _4082 + L.coat_ndv, L.coat_alpha), 9.9999997473787516355514526367188e-05))) * 3.1415927410125732421875)) * step(9.9999997473787516355514526367188e-05, _4082)) * _4082;\n}\n\nvec3 fa_area_layers(FaLayers L, int li, vec3 world_pos, vec3 n, vec3 v, vec3 l, vec3 diffuse_color, vec3 f0, float roughness, float ndv, float window)\n{\n    int param = li;\n    vec3 param_1 = world_pos;\n    vec3 param_2 = n;\n    vec3 param_3 = v;\n    vec3 param_4 = diffuse_color;\n    vec3 param_5 = f0;\n    float param_6 = L.f90;\n    float param_7 = roughness;\n    float param_8 = ndv;\n    float param_9 = window;\n    float _5271;\n    if (L.sheen_on)\n    {\n        _5271 = L.sheen_scale;\n    }\n    else\n    {\n        _5271 = 1.0;\n    }\n    vec3 result = fa_area_shade(param, param_1, param_2, param_3, param_4, param_5, param_6, param_7, param_8, param_9) * (L.keep * _5271);\n    vec3 _5284 = normalize(l + v);\n    int param_10 = li;\n    vec3 _5295 = fa_light_rgb(param_10) * window;\n    if (L.sheen_on)\n    {\n        float _5304 = max(dot(n, l), 0.0);\n        float param_11 = L.sheen_alpha;\n        float param_12 = max(dot(n, _5284), 0.0);\n        float param_13 = _5304;\n        float param_14 = ndv;\n        result += ((L.sheen * _5295) * (((((fa_d_charlie(param_11, param_12) * fa_v_ashikhmin(param_13, param_14)) * 3.1415927410125732421875) * step(9.9999997473787516355514526367188e-05, _5304)) * _5304) * L.keep));\n    }\n    if (L.coat > 0.0)\n    {\n        FaLayers param_15 = L;\n        vec3 param_16 = l;\n        vec3 param_17 = _5284;\n        float param_18 = max(dot(v, _5284), 0.0);\n        result += (_5295 * fa_layers_coat(param_15, param_16, param_17, param_18));\n    }\n    return result;\n}\n\nfloat fa_d_ggx_aniso(float ndh, float tdh, float bdh, float at, float ab)\n{\n    float _3950 = tdh / at;\n    float _3954 = bdh / ab;\n    float _3966 = ((_3950 * _3950) + (_3954 * _3954)) + (ndh * ndh);\n    return 1.0 / ((((3.1415927410125732421875 * at) * ab) * _3966) * _3966);\n}\n\nfloat fa_lambda_ggx_aniso(float n, float t, float b, float at, float ab)\n{\n    return 0.5 * (sqrt(1.0 + (((((at * at) * t) * t) + (((ab * ab) * b) * b)) / max(n * n, 9.9999999392252902907785028219223e-09))) - 1.0);\n}\n\nfloat fa_v_ggx_aniso(float ndl, float ndv, float tdv, float bdv, float tdl, float bdl, float at, float ab)\n{\n    float param = ndv;\n    float param_1 = tdv;\n    float param_2 = bdv;\n    float param_3 = at;\n    float param_4 = ab;\n    float param_5 = ndl;\n    float param_6 = tdl;\n    float param_7 = bdl;\n    float param_8 = at;\n    float param_9 = ab;\n    return clamp(1.0 / ((4.0 * max(ndl * ndv, 9.9999997473787516355514526367188e-05)) * ((1.0 + fa_lambda_ggx_aniso(param, param_1, param_2, param_3, param_4)) + fa_lambda_ggx_aniso(param_5, param_6, param_7, param_8, param_9))), 0.0, 1.0);\n}\n\nvec3 fa_layers_light(FaLayers L, vec3 diffuse_color, vec3 f0, vec3 n, vec3 v, vec3 l, vec3 h, float ndl, float ndv, float ndh, float vdh, float alpha, float a2)\n{\n    float _4146 = step(9.9999997473787516355514526367188e-05, ndl);\n    float d_ggx;\n    float vis;\n    if (L.aniso != 0.0)\n    {\n        float param = ndh;\n        float param_1 = dot(L.t, h);\n        float param_2 = dot(L.b, h);\n        float param_3 = L.at;\n        float param_4 = L.ab;\n        d_ggx = fa_d_ggx_aniso(param, param_1, param_2, param_3, param_4);\n        float param_5 = ndl;\n        float param_6 = ndv;\n        float param_7 = dot(L.t, v);\n        float param_8 = dot(L.b, v);\n        float param_9 = dot(L.t, l);\n        float param_10 = dot(L.b, l);\n        float param_11 = L.at;\n        float param_12 = L.ab;\n        vis = fa_v_ggx_aniso(param_5, param_6, param_7, param_8, param_9, param_10, param_11, param_12);\n    }\n    else\n    {\n        float _4225 = ((ndh * ndh) * (a2 - 1.0)) + 1.0;\n        d_ggx = a2 / ((3.1415927410125732421875 * _4225) * _4225);\n        vis = 0.5 / max(mix((2.0 * ndl) * ndv, ndl + ndv, alpha), 9.9999997473787516355514526367188e-05);\n    }\n    vec3 base = diffuse_color + (((f0 + ((vec3(L.f90) - f0) * pow(clamp(1.0 - vdh, 0.0, 1.0), 5.0))) * ((d_ggx * vis) * 3.1415927410125732421875)) * _4146);\n    if (L.sheen_on)\n    {\n        float param_13 = L.sheen_alpha;\n        float param_14 = ndh;\n        float param_15 = ndl;\n        float param_16 = ndv;\n        base = (base * L.sheen_scale) + (L.sheen * (((fa_d_charlie(param_13, param_14) * fa_v_ashikhmin(param_15, param_16)) * 3.1415927410125732421875) * _4146));\n    }\n    vec3 result = base * (L.keep * ndl);\n    if (L.coat > 0.0)\n    {\n        FaLayers param_17 = L;\n        vec3 param_18 = l;\n        vec3 param_19 = h;\n        float param_20 = vdh;\n        result += vec3(fa_layers_coat(param_17, param_18, param_19, param_20));\n    }\n    return result;\n}\n\nvec2 fa_env_brdf(float rough, float ndv)\n{\n    vec4 _3353 = (vec4(-1.0, -0.0274999998509883880615234375, -0.572000026702880859375, 0.02199999988079071044921875) * rough) + vec4(1.0, 0.0425000004470348358154296875, 1.03999996185302734375, -0.039999999105930328369140625);\n    float _3356 = _3353.x;\n    return (vec2(-1.03999996185302734375, 1.03999996185302734375) * ((min(_3356 * _3356, exp2((-9.27999973297119140625) * ndv)) * _3356) + _3353.y)) + _3353.zw;\n}\n\nvec3 fa_environment(vec3 d, float rough)\n{\n    if (fa_mesh_fs_params[11].w > 0.5)\n    {\n        return textureLod(fa_env_tex_fa_env_smp, d, clamp(rough, 0.0, 1.0) * fa_mesh_fs_params[12].w).xyz;\n    }\n    float _3259 = rough * rough;\n    float _3289 = 0.60000002384185791015625 * _3259;\n    return mix(mix(fa_mesh_fs_params[12].xyz * 0.550000011920928955078125, mix(fa_mesh_fs_params[12].xyz, fa_mesh_fs_params[11].xyz, vec3(pow(clamp(d.y * (1.0 - (0.699999988079071044921875 * _3259)), 0.0, 1.0), 0.550000011920928955078125))), vec3(smoothstep((-0.0500000007450580596923828125) - _3289, 0.0500000007450580596923828125 + _3289, d.y))), ((fa_mesh_fs_params[11].xyz + fa_mesh_fs_params[12].xyz) * 0.5) * 0.800000011920928955078125, vec3(_3259 * 0.60000002384185791015625));\n}\n\nvec3 fa_layers_ibl(FaLayers L, vec3 n, vec3 v, vec3 f0, float roughness)\n{\n    vec3 rn = n;\n    if (L.aniso != 0.0)\n    {\n        vec3 _3833;\n        if (L.aniso >= 0.0)\n        {\n            _3833 = L.b;\n        }\n        else\n        {\n            _3833 = L.t;\n        }\n        rn = normalize(mix(n, cross(cross(_3833, v), _3833), vec3(abs(L.aniso))));\n    }\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05);\n    vec2 _3866 = fa_env_brdf(param, param_1);\n    vec3 param_2 = reflect(-v, rn);\n    float param_3 = roughness;\n    vec3 result = (fa_environment(param_2, param_3) * ((f0 * _3866.x) + (vec3(L.f90) * _3866.y))) * L.base_scale;\n    if (L.sheen_on)\n    {\n        vec3 param_4 = n;\n        float param_5 = L.sheen_rough;\n        result += ((L.sheen * (L.sheen_e * L.keep)) * fa_environment(param_4, param_5));\n    }\n    if (L.coat > 0.0)\n    {\n        float param_6 = L.coat_rough;\n        float param_7 = L.coat_ndv;\n        vec2 _3921 = fa_env_brdf(param_6, param_7);\n        vec3 param_8 = reflect(-v, L.nc);\n        float param_9 = L.coat_rough;\n        result += (fa_environment(param_8, param_9) * (L.coat * ((0.039999999105930328369140625 * _3921.x) + _3921.y)));\n    }\n    return result;\n}\n\nvec3 fa_sky_reflection(vec3 n, vec3 v, vec3 f0, float roughness)\n{\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05);\n    vec2 _3395 = fa_env_brdf(param, param_1);\n    vec3 param_2 = reflect(-v, n);\n    float param_3 = roughness;\n    return fa_environment(param_2, param_3) * ((f0 * _3395.x) + vec3(_3395.y));\n}\n\nvec3 fa_shadow_debug(vec3 color, vec3 world)\n{\n    if (fa_shadows[27].w < 0.5)\n    {\n        return color;\n    }\n    int _3148 = int(fa_shadows[25].x + 0.5);\n    float _3158 = dot(world - fa_shadows[27].xyz, fa_shadows[28].xyz);\n    vec3 tint = vec3(0.3499999940395355224609375);\n    bool _3163 = _3148 > 0;\n    bool _3172;\n    if (_3163)\n    {\n        int param = _3148 - 1;\n        _3172 = _3158 <= fa_shadow_split_at(param);\n    }\n    else\n    {\n        _3172 = _3163;\n    }\n    if (_3172)\n    {\n        tint = vec3(1.0, 0.1500000059604644775390625, 0.100000001490116119384765625);\n        bool _3178 = _3148 > 1;\n        bool _3185;\n        if (_3178)\n        {\n            _3185 = _3158 > fa_shadows[24].x;\n        }\n        else\n        {\n            _3185 = _3178;\n        }\n        if (_3185)\n        {\n            tint = vec3(0.100000001490116119384765625, 0.89999997615814208984375, 0.20000000298023223876953125);\n        }\n        bool _3191 = _3148 > 2;\n        bool _3198;\n        if (_3191)\n        {\n            _3198 = _3158 > fa_shadows[24].y;\n        }\n        else\n        {\n            _3198 = _3191;\n        }\n        if (_3198)\n        {\n            tint = vec3(0.1500000059604644775390625, 0.300000011920928955078125, 1.0);\n        }\n        bool _3204 = _3148 > 3;\n        bool _3211;\n        if (_3204)\n        {\n            _3211 = _3158 > fa_shadows[24].z;\n        }\n        else\n        {\n            _3211 = _3204;\n        }\n        if (_3211)\n        {\n            tint = vec3(1.0, 0.89999997615814208984375, 0.100000001490116119384765625);\n        }\n    }\n    return mix(color, tint, vec3(0.550000011920928955078125));\n}\n\nvoid main()\n{\n    fa_inst_load();\n    vec3 _6382 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _6382 = -_6382;\n    }\n    vec3 _5740 = normalize(fa_mesh_fs_params[0].xyz - fa_world_pos);\n    vec3 param = fa_world_pos;\n    fa_cluster_begin(param);\n    SurfaceInput param_1 = SurfaceInput(fa_world_pos, _6382, fa_world_tangent, fa_uv, fa_vertex_color, _5740, gl_FrontFacing);\n    Surface _5748 = fa_standard_surface(param_1);\n    vec3 _6413 = _5748.albedo;\n    float _6414 = _5748.alpha;\n    vec3 _6415 = _5748.normal;\n    float _6416 = _5748.metallic;\n    float _6417 = _5748.roughness;\n    float _6418 = _5748.occlusion;\n    vec3 _6419 = _5748.emission;\n    float _6420 = _5748.clearcoat;\n    float _6421 = _5748.clearcoat_roughness;\n    vec3 _6422 = _5748.sheen_color;\n    float _6423 = _5748.sheen_roughness;\n    float _6424 = _5748.anisotropy;\n    float _6425 = _5748.anisotropy_rotation;\n    float _6426 = _5748.specular;\n    float _6427 = _5748.ior;\n    vec3 _6428 = _5748.specular_color;\n    SurfaceInput param_2 = SurfaceInput(fa_world_pos, _6382, fa_world_tangent, fa_uv, fa_vertex_color, _5740, gl_FrontFacing);\n    Surface param_3 = _5748;\n    surface(param_2, param_3);\n    _6413 = param_3.albedo;\n    _6414 = param_3.alpha;\n    _6415 = param_3.normal;\n    _6416 = param_3.metallic;\n    _6417 = param_3.roughness;\n    _6418 = param_3.occlusion;\n    _6419 = param_3.emission;\n    _6420 = param_3.clearcoat;\n    _6421 = param_3.clearcoat_roughness;\n    _6422 = param_3.sheen_color;\n    _6423 = param_3.sheen_roughness;\n    _6424 = param_3.anisotropy;\n    _6425 = param_3.anisotropy_rotation;\n    _6426 = param_3.specular;\n    _6427 = param_3.ior;\n    _6428 = param_3.specular_color;\n    vec3 param_4 = fa_world_pos;\n    vec3 param_5 = _6382;\n    vec3 param_6 = param_3.albedo;\n    vec3 param_7 = param_3.normal;\n    fa_apply_decals(param_4, param_5, param_6, param_7);\n    _6413 = param_6;\n    _6415 = param_7;\n    vec3 result;\n    if (fa_mesh_fs_params[3].w > 0.5)\n    {\n        result = _6413;\n    }\n    else\n    {\n        vec3 _5787 = normalize(_6415);\n        float _5794 = clamp(_6416, 0.0, 1.0);\n        float _5798 = clamp(_6417, 0.0500000007450580596923828125, 1.0);\n        float _5802 = _5798 * _5798;\n        float _5806 = _5802 * _5802;\n        float _5811 = max(dot(_5787, _5740), 9.9999997473787516355514526367188e-05);\n        vec3 _5817 = _6413 * (1.0 - _5794);\n        vec3 _5824 = mix(vec3(0.039999999105930328369140625), _6413, vec3(_5794));\n        vec3 f0 = _5824;\n        SurfaceInput param_8 = SurfaceInput(fa_world_pos, _6382, fa_world_tangent, fa_uv, fa_vertex_color, _5740, gl_FrontFacing);\n        Surface param_9 = Surface(_6413, _6414, _6415, _6416, _6417, _6418, _6419, _6420, _6421, _6422, _6423, _6424, _6425, _6426, _6427, _6428);\n        vec3 param_10 = _5787;\n        vec3 param_11 = _5740;\n        float param_12 = _5794;\n        float param_13 = _5798;\n        vec3 param_14 = _5824;\n        FaLayers _5840 = fa_layers_setup(param_8, param_9, param_10, param_11, param_12, param_13, param_14);\n        f0 = param_14;\n        vec3 param_15 = _5787;\n        vec3 lit = (fa_indirect_diffuse(param_15) * _5817) * _6418;\n        if (_5840.on)\n        {\n            lit *= _5840.base_scale;\n        }\n        int _5862 = fa_cl_ndir + fa_cl_local;\n        for (int ln = 0; ln < _5862; ln++)\n        {\n            int param_16 = ln;\n            int _5875 = fa_cl_light(param_16);\n            bool _5878 = fa_lm.z > 0.5;\n            bool _5884;\n            if (_5878)\n            {\n                int param_17 = _5875;\n                _5884 = fa_light_baked(param_17);\n            }\n            else\n            {\n                _5884 = _5878;\n            }\n            if (_5884)\n            {\n                continue;\n            }\n            int param_18 = _5875;\n            vec3 param_19 = fa_world_pos;\n            vec3 param_20 = _6382;\n            LightSample _5896 = fa_light_shadowed(param_18, param_19, param_20);\n            float _5904 = max(dot(_5787, _5896.direction), 0.0);\n            float _5910 = _5896.attenuation * _5896.shadow;\n            vec3 _5915 = normalize(_5896.direction + _5740);\n            float _5920 = max(dot(_5787, _5915), 0.0);\n            float _5925 = max(dot(_5740, _5915), 0.0);\n            bool _5932;\n            if (fa_light_is_area)\n            {\n                _5932 = !_5840.on;\n            }\n            else\n            {\n                _5932 = fa_light_is_area;\n            }\n            if (_5932)\n            {\n                int param_21 = _5875;\n                vec3 param_22 = fa_world_pos;\n                vec3 param_23 = _5787;\n                vec3 param_24 = _5740;\n                vec3 param_25 = _5817;\n                vec3 param_26 = f0;\n                float param_27 = 1.0;\n                float param_28 = _5798;\n                float param_29 = _5811;\n                float param_30 = _5910;\n                lit += fa_area_shade(param_21, param_22, param_23, param_24, param_25, param_26, param_27, param_28, param_29, param_30);\n            }\n            else\n            {\n                if (fa_light_is_area)\n                {\n                    FaLayers param_31 = _5840;\n                    int param_32 = _5875;\n                    vec3 param_33 = fa_world_pos;\n                    vec3 param_34 = _5787;\n                    vec3 param_35 = _5740;\n                    vec3 param_36 = _5896.direction;\n                    vec3 param_37 = _5817;\n                    vec3 param_38 = f0;\n                    float param_39 = _5798;\n                    float param_40 = _5811;\n                    float param_41 = _5910;\n                    lit += fa_area_layers(param_31, param_32, param_33, param_34, param_35, param_36, param_37, param_38, param_39, param_40, param_41);\n                }\n                else\n                {\n                    if (_5840.on)\n                    {\n                        FaLayers param_42 = _5840;\n                        vec3 param_43 = _5817;\n                        vec3 param_44 = f0;\n                        vec3 param_45 = _5787;\n                        vec3 param_46 = _5740;\n                        vec3 param_47 = _5896.direction;\n                        vec3 param_48 = _5915;\n                        float param_49 = _5904;\n                        float param_50 = _5811;\n                        float param_51 = _5920;\n                        float param_52 = _5925;\n                        float param_53 = _5802;\n                        float param_54 = _5806;\n                        int param_55 = _5875;\n                        lit += (fa_layers_light(param_42, param_43, param_44, param_45, param_46, param_47, param_48, param_49, param_50, param_51, param_52, param_53, param_54) * ((fa_light_rgb(param_55) * fa_light_tint) * _5910));\n                    }\n                    else\n                    {\n                        float _6038 = ((_5920 * _5920) * (_5806 - 1.0)) + 1.0;\n                        int param_56 = _5875;\n                        lit += (((_5817 + (((f0 + ((vec3(1.0) - f0) * pow(1.0 - _5925, 5.0))) * (((_5806 / ((3.1415927410125732421875 * _6038) * _6038)) * (0.5 / max(mix((2.0 * _5904) * _5811, _5904 + _5811, _5802), 9.9999997473787516355514526367188e-05))) * 3.1415927410125732421875)) * step(9.9999997473787516355514526367188e-05, _5904))) * (fa_light_rgb(param_56) * fa_light_tint)) * (_5904 * _5910));\n                    }\n                }\n            }\n        }\n        if (_5840.on)\n        {\n            FaLayers param_57 = _5840;\n            vec3 param_58 = _5787;\n            vec3 param_59 = _5740;\n            vec3 param_60 = f0;\n            float param_61 = _5798;\n            lit += (fa_layers_ibl(param_57, param_58, param_59, param_60, param_61) * _6418);\n        }\n        else\n        {\n            vec3 param_62 = _5787;\n            vec3 param_63 = _5740;\n            vec3 param_64 = f0;\n            float param_65 = _5798;\n            lit += (fa_sky_reflection(param_62, param_63, param_64, param_65) * _6418);\n        }\n        result = lit;\n    }\n    vec3 _6133 = result;\n    vec3 _6134 = _6133 + _6419;\n    result = _6134;\n    vec3 param_66 = _6134;\n    vec3 param_67 = fa_world_pos;\n    result = fa_shadow_debug(param_66, param_67);\n    bool _6143 = fa_mesh_fs_params[7].w > 0.0;\n    bool _6150;\n    if (!_6143)\n    {\n        _6150 = fa_mesh_fs_params[8].y > 0.0;\n    }\n    else\n    {\n        _6150 = _6143;\n    }\n    if (_6150)\n    {\n        vec3 _6159 = fa_world_pos - fa_mesh_fs_params[0].xyz;\n        float _6165 = dot(_6159, fa_mesh_fs_params[9].xyz);\n        bool _6169 = fa_mesh_fs_params[9].w > 0.5;\n        float _6170;\n        if (_6169)\n        {\n            _6170 = _6165;\n        }\n        else\n        {\n            _6170 = length(_6159);\n        }\n        float _6182 = _6170 - fa_mesh_fs_params[8].x;\n        if (_6182 > 0.0)\n        {\n            float _6191 = fa_mesh_fs_params[7].w * _6182;\n            float tau = _6191 * _6191;\n            if (fa_mesh_fs_params[8].y > 0.0)\n            {\n                float _6207;\n                if (_6169)\n                {\n                    _6207 = fa_world_pos.y - (fa_mesh_fs_params[9].y * _6165);\n                }\n                else\n                {\n                    _6207 = fa_mesh_fs_params[0].y;\n                }\n                float _6228 = mix(_6207, fa_world_pos.y, clamp(fa_mesh_fs_params[8].x / _6170, 0.0, 1.0));\n                float _6232 = fa_world_pos.y - _6228;\n                float _6237 = _6228 - fa_mesh_fs_params[8].z;\n                float _6242 = fa_world_pos.y - fa_mesh_fs_params[8].z;\n                bool _6245 = _6237 <= 0.0;\n                bool _6246 = !_6245;\n                bool _6252;\n                if (_6246)\n                {\n                    _6252 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _6252 = _6245;\n                }\n                float _6253;\n                if (_6252)\n                {\n                    _6253 = fa_mesh_fs_params[8].y;\n                }\n                else\n                {\n                    _6253 = fa_mesh_fs_params[8].y * exp(-min(fa_mesh_fs_params[8].w * _6237, 80.0));\n                }\n                bool _6280;\n                if (_6246)\n                {\n                    _6280 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _6280 = _6245;\n                }\n                float _6281;\n                if (_6280)\n                {\n                    _6281 = fa_mesh_fs_params[8].y * _6237;\n                }\n                else\n                {\n                    _6281 = (fa_mesh_fs_params[8].y * (1.0 - exp(-min(fa_mesh_fs_params[8].w * _6237, 80.0)))) / fa_mesh_fs_params[8].w;\n                }\n                bool _6306 = _6242 <= 0.0;\n                bool _6313;\n                if (!_6306)\n                {\n                    _6313 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _6313 = _6306;\n                }\n                float _6314;\n                if (_6313)\n                {\n                    _6314 = fa_mesh_fs_params[8].y * _6242;\n                }\n                else\n                {\n                    _6314 = (fa_mesh_fs_params[8].y * (1.0 - exp(-min(fa_mesh_fs_params[8].w * _6242, 80.0)))) / fa_mesh_fs_params[8].w;\n                }\n                float _6341;\n                if (abs(_6232) < 0.001000000047497451305389404296875)\n                {\n                    _6341 = _6253;\n                }\n                else\n                {\n                    _6341 = (_6314 - _6281) / _6232;\n                }\n                tau += (_6182 * max(_6341, 0.0));\n            }\n            result = mix(result, fa_mesh_fs_params[7].xyz, vec3(clamp(1.0 - exp(-clamp(tau, 0.0, 80.0)), 0.0, 1.0)));\n        }\n    }\n    fa_frag_color = vec4(result, _6414);\n}\n\n",
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
            "size": 384,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_485",
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
            "inst_name": "_2202",
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
      "vs": "#version 430\n\nstruct VertexData\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 color;\n    vec3 object_pos;\n};\n\nuniform vec4 fa_mesh_vs_params[11];\nuniform vec4 fa_skin[192];\nlayout(location = 0) out vec3 fa_world_pos;\nlayout(location = 1) out vec3 fa_world_normal;\nlayout(location = 2) out vec4 fa_world_tangent;\nlayout(location = 3) out vec2 fa_uv;\nlayout(location = 4) out vec4 fa_vertex_color;\nlayout(location = 5) in vec4 fa_inst_m0;\nlayout(location = 6) in vec4 fa_inst_m1;\nlayout(location = 7) in vec4 fa_inst_m2;\nlayout(location = 8) in vec4 fa_inst_m3;\nlayout(location = 9) in vec4 fa_joints;\nlayout(location = 10) in vec4 fa_weights;\nlayout(location = 0) in vec3 fa_position;\nlayout(location = 1) in vec3 fa_normal;\nlayout(location = 3) in vec4 fa_tangent;\nlayout(location = 2) in vec2 fa_texcoord0;\nlayout(location = 4) in vec4 fa_color;\nlayout(location = 5) out vec3 fa_lm;\n\nvoid fa_inst_begin()\n{\n}\n\nmat4 fa_skin_matrix(vec4 joints, vec4 weights)\n{\n    vec4 r0 = vec4(0.0);\n    vec4 r1 = vec4(0.0);\n    vec4 r2 = vec4(0.0);\n    for (int i = 0; i < 4; i++)\n    {\n        int _174 = int((joints[i] * 255.0) + 0.5) * 3;\n        r0 += (fa_skin[_174 * 1 + 0] * weights[i]);\n        r1 += (fa_skin[(_174 + 1) * 1 + 0] * weights[i]);\n        r2 += (fa_skin[(_174 + 2) * 1 + 0] * weights[i]);\n    }\n    return mat4(vec4(r0.x, r1.x, r2.x, 0.0), vec4(r0.y, r1.y, r2.y, 0.0), vec4(r0.z, r1.z, r2.z, 0.0), vec4(r0.w, r1.w, r2.w, 1.0));\n}\n\nVertexData fa_vertex_data(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    vec3 _74 = cross(model[1].xyz, model[2].xyz);\n    float _80 = (dot(model[0].xyz, _74) < 0.0) ? (-1.0) : 1.0;\n    return VertexData((model * vec4(position, 1.0)).xyz, (((_74 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _80, vec4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _80), texcoord0 * fa_mesh_vs_params[8].xy, color, position);\n}\n\nvoid fa_shade_vertex(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    mat4 param = model;\n    vec3 param_1 = position;\n    vec3 param_2 = normal;\n    vec4 param_3 = tangent;\n    vec2 param_4 = texcoord0;\n    vec4 param_5 = color;\n    VertexData _273 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    vec3 _388 = _273.world_pos;\n    fa_world_pos = _388;\n    fa_world_normal = _273.world_normal;\n    fa_world_tangent = _273.world_tangent;\n    fa_uv = _273.uv;\n    fa_vertex_color = _273.color;\n    gl_Position = mat4(fa_mesh_vs_params[0], fa_mesh_vs_params[1], fa_mesh_vs_params[2], fa_mesh_vs_params[3]) * vec4(_388, 1.0);\n}\n\nvoid main()\n{\n    fa_inst_begin();\n    vec4 param = fa_joints;\n    vec4 param_1 = fa_weights;\n    mat4 param_2 = mat4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3) * fa_skin_matrix(param, param_1);\n    vec3 param_3 = fa_position;\n    vec3 param_4 = fa_normal;\n    vec4 param_5 = fa_tangent;\n    vec2 param_6 = fa_texcoord0;\n    vec4 param_7 = fa_color;\n    fa_shade_vertex(param_2, param_3, param_4, param_5, param_6, param_7);\n    fa_lm = vec3(0.0);\n}\n\n",
      "fs": "#version 430\n\nstruct SurfaceInput\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 vertex_color;\n    vec3 view_dir;\n    bool front_facing;\n};\n\nstruct LightSample\n{\n    vec3 direction;\n    vec3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct Surface\n{\n    vec3 albedo;\n    float alpha;\n    vec3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    vec3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    vec3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    vec3 specular_color;\n};\n\nstruct FaLayers\n{\n    bool on;\n    float f90;\n    float keep;\n    float base_scale;\n    float coat;\n    float coat_rough;\n    float coat_alpha;\n    float coat_a2;\n    vec3 nc;\n    float coat_ndv;\n    bool sheen_on;\n    vec3 sheen;\n    float sheen_rough;\n    float sheen_alpha;\n    float sheen_scale;\n    float sheen_e;\n    float aniso;\n    vec3 t;\n    vec3 b;\n    float at;\n    float ab;\n};\n\nconst float _3496[63] = float[](1.0, 1.0, 1.0, 0.4790000021457672119140625, 0.11699999868869781494140625, 0.01200000010430812835693359375, 0.0, 0.0, 0.0, 1.0, 1.0, 1.0, 0.578000009059906005859375, 0.19300000369548797607421875, 0.0350000001490116119384765625, 0.0030000000260770320892333984375, 0.0, 0.0, 1.0, 1.0, 1.0, 0.6740000247955322265625, 0.3459999859333038330078125, 0.1319999992847442626953125, 0.032999999821186065673828125, 0.0040000001899898052215576171875, 0.0, 0.971000015735626220703125, 0.954999983310699462890625, 0.828999996185302734375, 0.63999998569488525390625, 0.42599999904632568359375, 0.24500000476837158203125, 0.115000002086162567138671875, 0.037000000476837158203125, 0.0030000000260770320892333984375, 0.7469999790191650390625, 0.737999975681304931640625, 0.670000016689300537109375, 0.563000023365020751953125, 0.4309999942779541015625, 0.3039999902248382568359375, 0.1940000057220458984375, 0.1019999980926513671875, 0.0309999994933605194091796875, 0.614000022411346435546875, 0.609000027179718017578125, 0.566999971866607666015625, 0.499000012874603271484375, 0.412000000476837158203125, 0.32400000095367431640625, 0.240999996662139892578125, 0.162000000476837158203125, 0.087999999523162841796875, 0.538999974727630615234375, 0.535000026226043701171875, 0.505999982357025146484375, 0.4569999873638153076171875, 0.393999993801116943359375, 0.328999996185302734375, 0.2660000026226043701171875, 0.203999996185302734375, 0.14200000464916229248046875);\n\nuniform vec4 fa_mesh_fs_params[24];\nuniform vec4 fa_shadows[30];\nlayout(binding = 0) uniform sampler2D fa_light_tex_fa_shadow_smp;\nlayout(binding = 1) uniform sampler2D fa_tex_fa_smp;\nlayout(binding = 2) uniform sampler2D fa_normal_tex_fa_smp;\nlayout(binding = 3) uniform sampler2D fa_mr_tex_fa_smp;\nlayout(binding = 4) uniform sampler2D fa_occlusion_tex_fa_smp;\nlayout(binding = 5) uniform sampler2D fa_emissive_tex_fa_smp;\nlayout(binding = 6) uniform sampler2D fa_decal_tex_fa_env_smp;\nlayout(binding = 7) uniform sampler2D fa_lightmap_fa_env_smp;\nlayout(binding = 8) uniform samplerCube fa_irr_tex_fa_env_smp;\nlayout(binding = 9) uniform sampler2D fa_light_atlas_fa_env_smp;\nlayout(binding = 10) uniform sampler2D fa_shadow_tex_fa_shadow_smp;\nlayout(binding = 11) uniform samplerCube fa_env_tex_fa_env_smp;\n\nlayout(location = 0) in vec3 fa_world_pos;\nlayout(location = 5) in vec3 fa_lm;\nlayout(location = 1) in vec3 fa_world_normal;\nlayout(location = 2) in vec4 fa_world_tangent;\nlayout(location = 3) in vec2 fa_uv;\nlayout(location = 4) in vec4 fa_vertex_color;\nlayout(location = 0) out vec4 fa_frag_color;\nvec3 fa_light_tint;\nbool fa_light_is_area;\nint fa_cl_ndir;\nint fa_cl_slot;\nint fa_cl_local;\n\nvoid fa_inst_load()\n{\n}\n\nvec4 fa_light_texel(int t)\n{\n    return texelFetch(fa_light_tex_fa_shadow_smp, ivec2(t & 1023, t >> 10), 0);\n}\n\nvec4 fa_cluster_texel(vec3 world_pos)\n{\n    bool _1473 = fa_mesh_fs_params[19].x < 0.0;\n    bool _1480;\n    if (!_1473)\n    {\n        _1480 = fa_mesh_fs_params[19].w < 1.0;\n    }\n    else\n    {\n        _1480 = _1473;\n    }\n    bool _1488;\n    if (!_1480)\n    {\n        _1488 = fa_mesh_fs_params[18].x < 1.0;\n    }\n    else\n    {\n        _1488 = _1480;\n    }\n    bool _1495;\n    if (!_1488)\n    {\n        _1495 = fa_mesh_fs_params[18].y < 1.0;\n    }\n    else\n    {\n        _1495 = _1488;\n    }\n    bool _1502;\n    if (!_1495)\n    {\n        _1502 = fa_mesh_fs_params[19].y < 1.0;\n    }\n    else\n    {\n        _1502 = _1495;\n    }\n    if (_1502)\n    {\n        return vec4(0.0);\n    }\n    vec4 _1512 = vec4(world_pos, 1.0);\n    float _1518 = dot(fa_mesh_fs_params[16], _1512);\n    if (!(_1518 > 9.9999999747524270787835121154785e-07))\n    {\n        return vec4(0.0);\n    }\n    vec2 _1540 = vec2(dot(fa_mesh_fs_params[14], _1512), dot(fa_mesh_fs_params[15], _1512)) / vec2(_1518);\n    int _1544 = int(fa_mesh_fs_params[18].x);\n    int _1548 = int(fa_mesh_fs_params[18].y);\n    int param = (int(fa_mesh_fs_params[19].x) + (((clamp(int(floor(log2(max(dot(fa_mesh_fs_params[17].xyz, world_pos) + fa_mesh_fs_params[17].w, fa_mesh_fs_params[18].w) / fa_mesh_fs_params[18].w) * fa_mesh_fs_params[18].z)), 0, int(fa_mesh_fs_params[19].y) - 1) * _1548) + clamp(int(floor(((_1540.y * 0.5) + 0.5) * fa_mesh_fs_params[18].y)), 0, _1548 - 1)) * _1544)) + clamp(int(floor(((_1540.x * 0.5) + 0.5) * fa_mesh_fs_params[18].x)), 0, _1544 - 1);\n    return fa_light_texel(param);\n}\n\nivec2 fa_cluster_lookup(vec3 world_pos)\n{\n    vec3 param = world_pos;\n    vec4 _1624 = fa_cluster_texel(param);\n    return ivec2(int(_1624.x), int(_1624.y));\n}\n\nvoid fa_cluster_begin(vec3 world_pos)\n{\n    fa_cl_ndir = int(fa_mesh_fs_params[19].z);\n    vec3 param = world_pos;\n    ivec2 _4317 = fa_cluster_lookup(param);\n    fa_cl_slot = _4317.x;\n    fa_cl_local = _4317.y;\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nvec3 fa_linear_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_tex_fix(inout vec3 c, float mode)\n{\n    if (mode > 1.5)\n    {\n        vec3 param = c;\n        vec3 _5410 = fa_linear_to_srgb(param);\n        c = _5410;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            vec3 param_1 = c;\n            vec3 _5418 = fa_srgb_to_linear(param_1);\n            c = _5418;\n        }\n    }\n    return c;\n}\n\nvec3 fa_tangent_normal(SurfaceInput i, vec3 m)\n{\n    vec3 _417;\n    if (i.front_facing)\n    {\n        _417 = i.world_normal;\n    }\n    else\n    {\n        _417 = -i.world_normal;\n    }\n    vec3 _441 = normalize(i.world_tangent.xyz - (_417 * dot(_417, i.world_tangent.xyz)));\n    vec3 _469 = normalize(((_441 * m.x) + ((cross(_417, _441) * i.world_tangent.w) * m.y)) + (_417 * m.z));\n    vec3 _472;\n    if (i.front_facing)\n    {\n        _472 = _469;\n    }\n    else\n    {\n        _472 = -_469;\n    }\n    return _472;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    vec4 base_t = texture(fa_tex_fa_smp, i.uv);\n    float param = fa_mesh_fs_params[6].w;\n    float param_1 = 1.0;\n    vec3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    vec3 _5449 = fa_tex_fix(param_2, param_3);\n    vec4 _6864 = base_t;\n    _6864.x = _5449.x;\n    _6864.y = _5449.y;\n    _6864.z = _5449.z;\n    base_t = _6864;\n    vec4 _5463 = (_6864 * fa_mesh_fs_params[2]) * i.vertex_color;\n    vec3 _6702 = i.world_normal;\n    if (fa_mesh_fs_params[6].z > 0.5)\n    {\n        float param_4 = fa_mesh_fs_params[6].w;\n        float param_5 = 16.0;\n        vec3 param_6 = texture(fa_normal_tex_fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        vec3 _5495 = fa_tex_fix(param_6, param_7);\n        vec3 _5498 = (_5495 * 2.0) - vec3(1.0);\n        vec2 _5503 = _5498.xy * fa_mesh_fs_params[6].x;\n        vec3 _6872 = _5498;\n        _6872.x = _5503.x;\n        _6872.y = _5503.y;\n        SurfaceInput param_8 = i;\n        vec3 param_9 = _6872;\n        _6702 = fa_tangent_normal(param_8, param_9);\n    }\n    vec4 mrt = texture(fa_mr_tex_fa_smp, i.uv);\n    float param_10 = fa_mesh_fs_params[6].w;\n    float param_11 = 64.0;\n    vec3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    vec3 _5531 = fa_tex_fix(param_12, param_13);\n    vec4 _6875 = mrt;\n    _6875.x = _5531.x;\n    _6875.y = _5531.y;\n    _6875.z = _5531.z;\n    mrt = _6875;\n    vec4 _5559 = texture(fa_occlusion_tex_fa_smp, i.uv);\n    float param_14 = fa_mesh_fs_params[6].w;\n    float param_15 = 256.0;\n    vec3 param_16 = _5559.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    vec3 _5570 = fa_tex_fix(param_16, param_17);\n    float param_18 = fa_mesh_fs_params[6].w;\n    float param_19 = 4.0;\n    vec3 param_20 = texture(fa_emissive_tex_fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    vec3 _5600 = fa_tex_fix(param_20, param_21);\n    float _6707 = fa_mesh_fs_params[20].x;\n    float _6708 = fa_mesh_fs_params[20].y;\n    float _6711 = fa_mesh_fs_params[20].z;\n    float _6710 = fa_mesh_fs_params[21].w;\n    float _6713 = fa_mesh_fs_params[22].x;\n    if (fa_mesh_fs_params[22].z > 0.5)\n    {\n        if (mod(fa_mesh_fs_params[22].z, 2.0) > 0.5)\n        {\n            _6707 *= _5570.y;\n            _6708 *= _5570.z;\n            _6710 *= _5559.w;\n        }\n        if (fa_mesh_fs_params[22].z > 1.5)\n        {\n            _6711 *= mrt.x;\n            _6713 *= mrt.w;\n        }\n    }\n    return Surface(_5463.xyz, _5463.w, _6702, clamp(fa_mesh_fs_params[5].x * _5531.z, 0.0, 1.0), clamp(fa_mesh_fs_params[5].y * _5531.y, 0.0500000007450580596923828125, 1.0), 1.0 + (fa_mesh_fs_params[6].y * (_5570.x - 1.0)), fa_mesh_fs_params[3].xyz + (fa_mesh_fs_params[4].xyz * _5600), _6707, _6708, fa_mesh_fs_params[21].xyz, _6710, _6711, fa_mesh_fs_params[20].w, _6713, fa_mesh_fs_params[22].y, fa_mesh_fs_params[23].xyz);\n}\n\nvoid surface(SurfaceInput i, inout Surface s)\n{\n    s.emission += vec3(0.5 + (0.5 * sin(fa_mesh_fs_params[13].x * 3.0)), 0.25 * fract(fa_mesh_fs_params[13].x), 0.0);\n}\n\nvec4 fa_decal_tile(vec4 rect, vec2 uv, vec2 atlas, vec2 ddx, vec2 ddy)\n{\n    vec2 _1704 = rect.zw - rect.xy;\n    vec2 _1708 = _1704 * atlas;\n    vec2 _1712 = ddx * _1708;\n    vec2 _1716 = ddy * _1708;\n    return textureLod(fa_decal_tex_fa_env_smp, rect.xy + (clamp(uv, vec2(0.0), vec2(1.0)) * _1704), clamp(0.5 * log2(max(max(dot(_1712, _1712), dot(_1716, _1716)), 9.9999999392252902907785028219223e-09)), 0.0, 4.0));\n}\n\nvec3 fa_dc_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_dc_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvoid fa_apply_decals(vec3 world_pos, vec3 geo_normal, inout vec3 albedo, inout vec3 normal)\n{\n    bool _1749 = fa_mesh_fs_params[10].y < 0.5;\n    bool _1756;\n    if (!_1749)\n    {\n        _1756 = fa_mesh_fs_params[10].w < 0.5;\n    }\n    else\n    {\n        _1756 = _1749;\n    }\n    if (_1756)\n    {\n        return;\n    }\n    vec3 _1762 = dFdx(world_pos);\n    vec3 _1765 = dFdy(world_pos);\n    vec3 param = world_pos;\n    vec4 _1769 = fa_cluster_texel(param);\n    int _1773 = int(_1769.w);\n    if (_1773 < 1)\n    {\n        return;\n    }\n    int _1783 = int(fa_mesh_fs_params[10].y + 0.5);\n    int param_1 = _1783;\n    vec4 _1787 = fa_light_texel(param_1);\n    vec2 _1790 = _1787.yz;\n    int _1794 = int(_1787.w);\n    int param_2 = _1783 + 1;\n    vec4 _1799 = fa_light_texel(param_2);\n    float _1800 = _1799.x;\n    int _1806 = int(fa_mesh_fs_params[10].w + 0.5) - 1;\n    int _1810 = int(_1769.z);\n    vec3 _2075;\n    for (int k = 0; k < _1773; k++)\n    {\n        int _1823 = _1810 + k;\n        int param_3 = _1794 + (_1823 >> 2);\n        int _1840 = (_1783 + 2) + (int(fa_light_texel(param_3)[_1823 & 3]) * 7);\n        int param_4 = _1840 + 6;\n        vec4 _1845 = fa_light_texel(param_4);\n        if (((int(_1845.w + 0.5) >> _1806) & 1) == 0)\n        {\n            continue;\n        }\n        int param_5 = _1840;\n        vec4 _1860 = fa_light_texel(param_5);\n        int param_6 = _1840 + 1;\n        vec4 _1865 = fa_light_texel(param_6);\n        int param_7 = _1840 + 2;\n        vec4 _1870 = fa_light_texel(param_7);\n        vec3 _1873 = _1860.xyz;\n        float _1878 = dot(_1873, world_pos) + _1860.w;\n        vec3 _1880 = _1865.xyz;\n        float _1885 = dot(_1880, world_pos) + _1865.w;\n        vec3 _1887 = _1870.xyz;\n        float _1892 = dot(_1887, world_pos) + _1870.w;\n        bool _1897 = abs(_1878) > 0.5;\n        bool _1905;\n        if (!_1897)\n        {\n            _1905 = abs(_1885) > 0.5;\n        }\n        else\n        {\n            _1905 = _1897;\n        }\n        bool _1913;\n        if (!_1905)\n        {\n            _1913 = abs(_1892) > 0.5;\n        }\n        else\n        {\n            _1913 = _1905;\n        }\n        if (_1913)\n        {\n            continue;\n        }\n        float _1928 = clamp(dot(geo_normal, normalize(_1887)) * _1845.z, 0.0, 1.0);\n        if (_1928 <= 0.0)\n        {\n            continue;\n        }\n        float _1948 = (clamp((0.5 - abs(_1892)) * 10.0, 0.0, 1.0) * _1928) * _1845.x;\n        vec2 _1956 = vec2(_1878 + 0.5, 0.5 - _1885);\n        vec2 _1966 = vec2(dot(_1873, _1762), dot(_1880, _1762));\n        vec2 _1976 = vec2(dot(_1873, _1765), dot(_1880, _1765));\n        int param_8 = _1840 + 5;\n        vec4 _1981 = fa_light_texel(param_8);\n        int param_9 = _1840 + 3;\n        vec4 _1986 = fa_light_texel(param_9);\n        int param_10 = _1840 + 4;\n        vec4 _1991 = fa_light_texel(param_10);\n        float tex_a = 1.0;\n        vec3 col = _1981.xyz;\n        bool _2001 = _1986.z > _1986.x;\n        if (_2001)\n        {\n            vec4 param_11 = _1986;\n            vec2 param_12 = _1956;\n            vec2 param_13 = _1790;\n            vec2 param_14 = _1966;\n            vec2 param_15 = _1976;\n            vec4 tx = fa_decal_tile(param_11, param_12, param_13, param_14, param_15);\n            if ((_1800 > 0.5) && (_1800 < 1.5))\n            {\n                vec3 param_16 = tx.xyz;\n                vec3 _2027 = fa_dc_to_linear(param_16);\n                vec4 _6782 = tx;\n                _6782.x = _2027.x;\n                _6782.y = _2027.y;\n                _6782.z = _2027.z;\n                tx = _6782;\n            }\n            col *= tx.xyz;\n            tex_a = tx.w;\n        }\n        albedo = mix(albedo, col, vec3(clamp((_1948 * tex_a) * _1981.w, 0.0, 1.0)));\n        if (_1991.z > _1991.x)\n        {\n            vec4 param_17 = _1991;\n            vec2 param_18 = _1956;\n            vec2 param_19 = _1790;\n            vec2 param_20 = _1966;\n            vec2 param_21 = _1976;\n            vec4 _2071 = fa_decal_tile(param_17, param_18, param_19, param_20, param_21);\n            if (_1800 > 1.5)\n            {\n                vec3 param_22 = _2071.xyz;\n                vec3 _2081 = fa_dc_to_srgb(param_22);\n                _2075 = _2081;\n            }\n            else\n            {\n                _2075 = _2071.xyz;\n            }\n            vec3 _2090 = (_2075 * 2.0) - vec3(1.0);\n            vec2 _2095 = _2090.xy * _1845.y;\n            vec3 _2117 = (normalize(_1873) * _2095.x) + (normalize(_1880) * _2095.y);\n            vec3 _2120 = normalize(normal);\n            normal = normalize(mix(_2120, normalize((_2120 * max(_2090.z, 0.0500000007450580596923828125)) + (_2117 - (_2120 * dot(_2120, _2117)))), vec3(clamp(_1948 * (_2001 ? tex_a : 1.0), 0.0, 1.0))));\n        }\n    }\n}\n\nfloat fa_sheen_albedo(float ndv, float rough)\n{\n    float _3421 = min(sqrt(max(rough - 0.100000001490116119384765625, 0.0) * 1.111111164093017578125) * 6.0, 5.999000072479248046875);\n    float _3429 = min(sqrt(clamp(ndv, 0.0, 1.0)) * 8.0, 7.999000072479248046875);\n    int _3432 = int(_3421);\n    int _3435 = int(_3429);\n    float _3445 = _3429 - float(_3435);\n    int _3501 = (_3432 * 9) + _3435;\n    int _3521 = ((_3432 + 1) * 9) + _3435;\n    return mix(mix(_3496[_3501], _3496[_3501 + 1], _3445), mix(_3496[_3521], _3496[_3521 + 1], _3445), _3421 - float(_3432));\n}\n\nFaLayers fa_layers_setup(SurfaceInput i, Surface s, vec3 n, vec3 v, float metallic, float roughness, inout vec3 f0)\n{\n    bool _6625 = false;\n    float _6626 = 1.0;\n    float _6627 = 1.0;\n    float _6628 = 1.0;\n    float _6629 = 0.0;\n    float _6630 = 0.0;\n    float _6631 = 0.0;\n    float _6632 = 0.0;\n    float _6634 = 1.0;\n    bool _6635 = false;\n    vec3 _6636 = vec3(0.0);\n    float _6637 = 1.0;\n    float _6638 = 1.0;\n    float _6639 = 1.0;\n    float _6640 = 0.0;\n    float _6641 = 0.0;\n    vec3 _6642 = vec3(1.0, 0.0, 0.0);\n    vec3 _6643 = vec3(0.0, 0.0, 1.0);\n    float _6644 = 1.0;\n    float _6645 = 1.0;\n    float _3572 = clamp(s.specular, 0.0, 1.0);\n    float _3576 = clamp(s.ior, 1.0, 3.0);\n    bool _3581 = (_3572 != 1.0) || (_3576 != 1.5);\n    bool _3590;\n    if (!_3581)\n    {\n        _3590 = any(notEqual(s.specular_color, vec3(1.0)));\n    }\n    else\n    {\n        _3590 = _3581;\n    }\n    if (_3590)\n    {\n        float _3598 = (_3576 - 1.0) / (_3576 + 1.0);\n        f0 = mix(min(vec3(_3598 * _3598) * max(s.specular_color, vec3(0.0)), vec3(1.0)) * _3572, s.albedo, vec3(metallic));\n        _6626 = mix(_3572, 1.0, metallic);\n        _6625 = true;\n    }\n    float _3625 = clamp(s.clearcoat, 0.0, 1.0);\n    if (_3625 > 0.0)\n    {\n        float _3633 = clamp(s.clearcoat_roughness, 0.0500000007450580596923828125, 1.0);\n        _6629 = _3625;\n        _6630 = _3633;\n        float _3640 = _3633 * _3633;\n        _6631 = _3640;\n        _6632 = _3640 * _3640;\n        float _3652 = max(dot(i.world_normal, v), 9.9999997473787516355514526367188e-05);\n        _6634 = _3652;\n        _6627 = 1.0 - (_3625 * (0.039999999105930328369140625 + (0.959999978542327880859375 * pow(clamp(1.0 - _3652, 0.0, 1.0), 5.0))));\n        _6625 = true;\n    }\n    vec3 _3672 = max(s.sheen_color, vec3(0.0));\n    float _3681 = max(_3672.x, max(_3672.y, _3672.z));\n    if (_3681 > 0.0)\n    {\n        float _3689 = clamp(s.sheen_roughness, 0.100000001490116119384765625, 1.0);\n        _6635 = true;\n        _6636 = _3672;\n        _6637 = _3689;\n        _6638 = _3689 * _3689;\n        float param = max(dot(n, v), 9.9999997473787516355514526367188e-05);\n        float param_1 = _3689;\n        float _3706 = fa_sheen_albedo(param, param_1);\n        _6640 = _3706;\n        _6639 = 1.0 - min(_3681 * _3706, 1.0);\n        _6625 = true;\n    }\n    _6628 = _6627 * _6639;\n    float _3725 = clamp(s.anisotropy, -1.0, 1.0);\n    if (_3725 != 0.0)\n    {\n        vec3 _3740 = i.world_tangent.xyz - (n * dot(n, i.world_tangent.xyz));\n        vec3 t = _3740;\n        if (dot(_3740, _3740) < 9.9999999392252902907785028219223e-09)\n        {\n            bvec3 _3752 = bvec3(abs(n.y) < 0.9900000095367431640625);\n            t = cross(vec3(_3752.x ? vec3(0.0, 1.0, 0.0).x : vec3(1.0, 0.0, 0.0).x, _3752.y ? vec3(0.0, 1.0, 0.0).y : vec3(1.0, 0.0, 0.0).y, _3752.z ? vec3(0.0, 1.0, 0.0).z : vec3(1.0, 0.0, 0.0).z), n);\n        }\n        vec3 _3756 = t;\n        vec3 _3757 = normalize(_3756);\n        t = _3757;\n        vec3 _3782 = normalize((_3757 * cos(s.anisotropy_rotation)) + ((cross(n, _3757) * ((i.world_tangent.w < 0.0) ? (-1.0) : 1.0)) * sin(s.anisotropy_rotation)));\n        _6642 = _3782;\n        _6643 = cross(n, _3782);\n        float _3792 = roughness * roughness;\n        float _3798 = mix(_3792, 1.0, _3725 * _3725);\n        bool _3800 = _3725 > 0.0;\n        _6644 = _3800 ? _3798 : _3792;\n        _6645 = _3800 ? _3792 : _3798;\n        _6641 = _3725;\n        _6625 = true;\n    }\n    return FaLayers(_6625, _6626, _6627, _6628, _6629, _6630, _6631, _6632, i.world_normal, _6634, _6635, _6636, _6637, _6638, _6639, _6640, _6641, _6642, _6643, _6644, _6645);\n}\n\nvec3 fa_ambient_light(vec3 n)\n{\n    if (fa_mesh_fs_params[11].w > 0.5)\n    {\n        return textureLod(fa_irr_tex_fa_env_smp, n, 0.0).xyz;\n    }\n    return fa_mesh_fs_params[1].xyz;\n}\n\nvec3 fa_indirect_diffuse(vec3 n)\n{\n    if (fa_lm.z > 0.5)\n    {\n        return textureLod(fa_lightmap_fa_env_smp, fa_lm.xy, 0.0).xyz;\n    }\n    vec3 param = n;\n    return fa_ambient_light(param);\n}\n\nint fa_cluster_index(int slot, int n)\n{\n    int param = (int(fa_mesh_fs_params[19].x) + int(fa_mesh_fs_params[19].w)) + ((slot + n) >> 2);\n    vec4 t = fa_light_texel(param);\n    return int(t[(slot + n) & 3]);\n}\n\nint fa_cl_light(int n)\n{\n    if (n < fa_cl_ndir)\n    {\n        return n;\n    }\n    int param = fa_cl_slot;\n    int param_1 = n - fa_cl_ndir;\n    return fa_cluster_index(param, param_1);\n}\n\nint fa_light_base(int li)\n{\n    return li * ((fa_mesh_fs_params[1].w > 4.5) ? 8 : 4);\n}\n\nbool fa_light_baked(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 3;\n    return fa_light_texel(param_1).w > 0.5;\n}\n\nfloat fa_light_type(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 1;\n    return fa_light_texel(param_1).w;\n}\n\nvec4 fa_atlas_fetch(vec2 texel)\n{\n    return textureLod(fa_light_atlas_fa_env_smp, texel / vec2(textureSize(fa_light_atlas_fa_env_smp, 0)), 0.0);\n}\n\nvec3 fa_cookie_sample(vec2 tile_origin, vec2 uv)\n{\n    vec2 param = (tile_origin + vec2(1.0)) + (clamp(uv, vec2(0.0), vec2(1.0)) * 254.0);\n    return fa_atlas_fetch(param).xyz;\n}\n\nvec3 fa_area_point(vec3 c, vec3 axis, vec3 ru, vec3 uu, float hx, float hy, float shape, vec3 p, vec3 r)\n{\n    bool _722 = dot(r, r) > 0.5;\n    if (shape > 1.5)\n    {\n        vec3 _735 = (c - (ru * hx)) - p;\n        vec3 _741 = ru * (2.0 * hx);\n        float _747 = max(dot(_741, _741), 9.9999999392252902907785028219223e-09);\n        float _751 = dot(_735, _741);\n        float t = clamp((-_751) / _747, 0.0, 1.0);\n        if (_722)\n        {\n            float _766 = dot(r, _741);\n            float _772 = _747 - (_766 * _766);\n            if (abs(_772) > (9.9999997473787516355514526367188e-06 * _747))\n            {\n                t = clamp(((dot(r, _735) * _766) - _751) / _772, 0.0, 1.0);\n            }\n        }\n        return (p + _735) + (_741 * t);\n    }\n    vec3 q = p;\n    float _804 = dot(r, axis);\n    bool _812;\n    if (_722)\n    {\n        _812 = abs(_804) > 9.9999997473787516355514526367188e-05;\n    }\n    else\n    {\n        _812 = _722;\n    }\n    if (_812)\n    {\n        float _822 = dot(c - p, axis) / _804;\n        if (_822 > 0.0)\n        {\n            q = p + (r * _822);\n        }\n    }\n    vec3 _835 = q - c;\n    vec2 xy = vec2(dot(_835, ru), dot(_835, uu));\n    if (shape > 0.5)\n    {\n        float _850 = length(xy);\n        if (_850 > hx)\n        {\n            xy *= (hx / _850);\n        }\n    }\n    else\n    {\n        xy = clamp(xy, vec2(-hx, -hy), vec2(hx, hy));\n    }\n    return (c + (ru * xy.x)) + (uu * xy.y);\n}\n\nint fa_cube_face(vec3 d)\n{\n    vec3 _643 = abs(d);\n    float _645 = _643.x;\n    float _647 = _643.y;\n    bool _648 = _645 >= _647;\n    bool _656;\n    if (_648)\n    {\n        _656 = _645 >= _643.z;\n    }\n    else\n    {\n        _656 = _648;\n    }\n    int _657;\n    if (_656)\n    {\n        _657 = (d.x > 0.0) ? 0 : 1;\n    }\n    else\n    {\n        int _670;\n        if (_647 >= _643.z)\n        {\n            _670 = (d.y > 0.0) ? 2 : 3;\n        }\n        else\n        {\n            _670 = (d.z > 0.0) ? 4 : 5;\n        }\n        _657 = _670;\n    }\n    return _657;\n}\n\nvoid fa_cube_face_basis(int f, out vec3 fwd, out vec3 up)\n{\n    if (f == 0)\n    {\n        fwd = vec3(1.0, 0.0, 0.0);\n        up = vec3(0.0, 1.0, 0.0);\n    }\n    else\n    {\n        if (f == 1)\n        {\n            fwd = vec3(-1.0, 0.0, 0.0);\n            up = vec3(0.0, 1.0, 0.0);\n        }\n        else\n        {\n            if (f == 2)\n            {\n                fwd = vec3(0.0, 1.0, 0.0);\n                up = vec3(0.0, 0.0, 1.0);\n            }\n            else\n            {\n                if (f == 3)\n                {\n                    fwd = vec3(0.0, -1.0, 0.0);\n                    up = vec3(0.0, 0.0, -1.0);\n                }\n                else\n                {\n                    if (f == 4)\n                    {\n                        fwd = vec3(0.0, 0.0, 1.0);\n                        up = vec3(0.0, 1.0, 0.0);\n                    }\n                    else\n                    {\n                        fwd = vec3(0.0, 0.0, -1.0);\n                        up = vec3(0.0, 1.0, 0.0);\n                    }\n                }\n            }\n        }\n    }\n}\n\nfloat fa_ies_sample(vec2 tile_origin, vec3 d, vec3 axis, vec3 right, vec3 up)\n{\n    float _596 = dot(d, right);\n    float _600 = dot(d, up);\n    float _611;\n    if (((_596 * _596) + (_600 * _600)) > 1.0000000133514319600180897396058e-10)\n    {\n        _611 = atan(_600, _596) * 0.15915493667125701904296875;\n    }\n    else\n    {\n        _611 = 0.0;\n    }\n    vec2 param = tile_origin + vec2(1.0 + ((_611 - floor(_611)) * 64.0), 1.0 + (acos(clamp(dot(d, axis), -1.0, 1.0)) * 10.18591594696044921875));\n    return fa_atlas_fetch(param).x;\n}\n\nLightSample fa_light_sample_n(int li, vec3 world_pos, vec3 n)\n{\n    int param = li;\n    int _888 = fa_light_base(param);\n    bool _892 = fa_mesh_fs_params[1].w > 4.5;\n    int param_1 = _888;\n    vec4 _896 = fa_light_texel(param_1);\n    int param_2 = _888 + 1;\n    vec4 _901 = fa_light_texel(param_2);\n    float _904 = _901.w;\n    float atten = 1.0;\n    float dist = 0.0;\n    fa_light_tint = vec3(1.0);\n    bool _916 = _892 && (_904 > 2.5);\n    fa_light_is_area = _916;\n    bool _918 = _904 < 0.5;\n    vec3 l;\n    if (_918)\n    {\n        l = normalize(_896.xyz);\n        if (_892)\n        {\n            int param_3 = _888 + 6;\n            vec4 _932 = fa_light_texel(param_3);\n            if (_932.z > 0.5)\n            {\n                int param_4 = _888 + 4;\n                vec4 _942 = fa_light_texel(param_4);\n                int param_5 = _888 + 5;\n                vec4 _947 = fa_light_texel(param_5);\n                vec2 param_6 = _932.xy;\n                vec2 param_7 = fract(vec2(dot(world_pos, _942.xyz) * _942.w, (-dot(world_pos, _947.xyz)) * _947.w) + vec2(0.5));\n                fa_light_tint = fa_cookie_sample(param_6, param_7);\n            }\n        }\n    }\n    else\n    {\n        vec3 _977 = _896.xyz;\n        vec3 _979 = _977 - world_pos;\n        vec3 to_light = _979;\n        float _982 = length(_979);\n        float reach = _982;\n        bool front = true;\n        if (_916)\n        {\n            int param_8 = _888 + 7;\n            reach = max(_982 - fa_light_texel(param_8).w, 0.0);\n            int param_9 = _888 + 4;\n            vec4 _1006 = fa_light_texel(param_9);\n            int param_10 = _888 + 5;\n            vec4 _1011 = fa_light_texel(param_10);\n            int param_11 = _888 + 6;\n            vec4 _1016 = fa_light_texel(param_11);\n            float _1017 = _1016.w;\n            int param_12 = _888 + 2;\n            vec3 _1024 = normalize(fa_light_texel(param_12).xyz);\n            bool _1026 = _1017 > 1.5;\n            bool _1034;\n            if (!_1026)\n            {\n                _1034 = dot(_1024, to_light) < 0.0;\n            }\n            else\n            {\n                _1034 = _1026;\n            }\n            front = _1034;\n            vec3 r = vec3(0.0);\n            vec3 _1043 = fa_mesh_fs_params[0].xyz - world_pos;\n            bool _1047 = dot(n, n) > 0.5;\n            bool _1055;\n            if (_1047)\n            {\n                _1055 = dot(_1043, _1043) > 9.9999999600419720025001879548654e-13;\n            }\n            else\n            {\n                _1055 = _1047;\n            }\n            if (_1055)\n            {\n                r = reflect(-normalize(_1043), normalize(n));\n            }\n            vec3 param_13 = _977;\n            vec3 param_14 = _1024;\n            vec3 param_15 = _1006.xyz;\n            vec3 param_16 = _1011.xyz;\n            float param_17 = _1006.w;\n            float param_18 = _1011.w;\n            float param_19 = _1017;\n            vec3 param_20 = world_pos;\n            vec3 param_21 = r;\n            to_light = fa_area_point(param_13, param_14, param_15, param_16, param_17, param_18, param_19, param_20, param_21) - world_pos;\n        }\n        float _1091 = length(to_light);\n        dist = _1091;\n        l = to_light / vec3(max(_1091, 9.9999997473787516355514526367188e-05));\n        float _1105 = reach / max(_896.w, 0.001000000047497451305389404296875);\n        float _1111 = clamp(1.0 - (_1105 * _1105), 0.0, 1.0);\n        float _1113;\n        if (front)\n        {\n            _1113 = _1111 * _1111;\n        }\n        else\n        {\n            _1113 = 0.0;\n        }\n        atten = _1113;\n        bool _1124 = _904 < 2.5;\n        if ((_904 > 1.5) && _1124)\n        {\n            int param_22 = _888 + 2;\n            vec4 _1132 = fa_light_texel(param_22);\n            float _1142 = _1132.w;\n            int param_23 = _888 + 3;\n            vec4 _1147 = fa_light_texel(param_23);\n            float _1148 = _1147.x;\n            float cos_inner = _1148;\n            if (_1148 > 1.5)\n            {\n                cos_inner = mix(_1142, 1.0, 0.25);\n            }\n            atten *= smoothstep(_1142, cos_inner, dot(-l, normalize(_1132.xyz)));\n        }\n        if (_892 && (_904 < 1.5))\n        {\n            int param_24 = _888 + 6;\n            vec4 _1172 = fa_light_texel(param_24);\n            if (_1172.z > 0.5)\n            {\n                vec3 _1180 = -to_light;\n                int param_25 = _888 + 4;\n                int param_26 = _888 + 5;\n                vec3 _1194 = fa_light_texel(param_25).xyz;\n                vec3 _1198 = fa_light_texel(param_26).xyz;\n                vec3 _1207 = vec3(dot(_1180, _1194), dot(_1180, _1198), dot(_1180, cross(_1194, _1198)));\n                vec3 param_27 = _1207;\n                int _1211 = fa_cube_face(param_27);\n                int param_28 = _1211;\n                vec3 param_29;\n                vec3 param_30;\n                fa_cube_face_basis(param_28, param_29, param_30);\n                vec2 _1238 = vec2(dot(_1207, cross(param_29, param_30)), dot(_1207, param_30)) / vec2(max(dot(_1207, param_29), 9.9999997473787516355514526367188e-05));\n                int _1242 = _1211 / 3;\n                vec2 param_31 = _1172.xy + (vec2(float(_1211 - (_1242 * 3)), float(_1242)) * 256.0);\n                vec2 param_32 = vec2(0.5 + (0.5 * _1238.x), 0.5 - (0.5 * _1238.y));\n                fa_light_tint = fa_cookie_sample(param_31, param_32);\n            }\n            int param_33 = _888 + 7;\n            vec4 _1272 = fa_light_texel(param_33);\n            if (_1272.z > 0.5)\n            {\n                int param_34 = _888 + 2;\n                int param_35 = _888 + 4;\n                int param_36 = _888 + 5;\n                vec2 param_37 = _1272.xy;\n                vec3 param_38 = -l;\n                vec3 param_39 = normalize(fa_light_texel(param_34).xyz);\n                vec3 param_40 = fa_light_texel(param_35).xyz;\n                vec3 param_41 = fa_light_texel(param_36).xyz;\n                atten *= fa_ies_sample(param_37, param_38, param_39, param_40, param_41);\n            }\n        }\n        else\n        {\n            if (_892 && _1124)\n            {\n                int param_42 = _888 + 6;\n                vec4 _1319 = fa_light_texel(param_42);\n                int param_43 = _888 + 7;\n                vec4 _1324 = fa_light_texel(param_43);\n                bool _1327 = _1319.z > 0.5;\n                bool _1334;\n                if (!_1327)\n                {\n                    _1334 = _1324.z > 0.5;\n                }\n                else\n                {\n                    _1334 = _1327;\n                }\n                if (_1334)\n                {\n                    int param_44 = _888 + 2;\n                    vec4 _1341 = fa_light_texel(param_44);\n                    vec3 _1345 = normalize(_1341.xyz);\n                    int param_45 = _888 + 4;\n                    vec4 _1350 = fa_light_texel(param_45);\n                    int param_46 = _888 + 5;\n                    vec4 _1355 = fa_light_texel(param_46);\n                    if (_1327)\n                    {\n                        vec3 _1363 = -to_light;\n                        float _1370 = _1341.w;\n                        float _1386 = 0.5 / max(dot(_1363, _1345) * (sqrt(max(1.0 - (_1370 * _1370), 0.0)) / max(_1370, 0.001000000047497451305389404296875)), 9.9999997473787516355514526367188e-05);\n                        vec2 param_47 = _1319.xy;\n                        vec2 param_48 = vec2(0.5 + (dot(_1363, _1350.xyz) * _1386), 0.5 - (dot(_1363, _1355.xyz) * _1386));\n                        fa_light_tint = fa_cookie_sample(param_47, param_48);\n                    }\n                    if (_1324.z > 0.5)\n                    {\n                        vec2 param_49 = _1324.xy;\n                        vec3 param_50 = -l;\n                        vec3 param_51 = _1345;\n                        vec3 param_52 = _1350.xyz;\n                        vec3 param_53 = _1355.xyz;\n                        atten *= fa_ies_sample(param_49, param_50, param_51, param_52, param_53);\n                    }\n                }\n            }\n        }\n    }\n    vec3 _6613 = _901.xyz * atten;\n    if (_892)\n    {\n        _6613 *= fa_light_tint;\n    }\n    int _1455;\n    if (_918)\n    {\n        _1455 = 0;\n    }\n    else\n    {\n        _1455 = ((_904 > 1.5) && (_904 < 2.5)) ? 2 : 1;\n    }\n    return LightSample(l, _6613, atten, 1.0, dist, _1455);\n}\n\nfloat fa_shadow_split_at(int i)\n{\n    float _2192;\n    if (i == 0)\n    {\n        _2192 = fa_shadows[24].x;\n    }\n    else\n    {\n        float _2208;\n        if (i == 1)\n        {\n            _2208 = fa_shadows[24].y;\n        }\n        else\n        {\n            float _2216;\n            if (i == 2)\n            {\n                _2216 = fa_shadows[24].z;\n            }\n            else\n            {\n                _2216 = fa_shadows[24].w;\n            }\n            _2208 = _2216;\n        }\n        _2192 = _2208;\n    }\n    return _2192;\n}\n\nfloat fa_shadow_depth(inout vec2 uv, vec4 rect)\n{\n    uv = clamp(uv, rect.xy, rect.zw);\n    return textureLod(fa_shadow_tex_fa_shadow_smp, uv, 0.0).x;\n}\n\nfloat fa_shadow_fetch(vec2 uv, vec4 rect, vec3 conv)\n{\n    vec2 param = uv;\n    vec4 param_1 = rect;\n    float _2249 = fa_shadow_depth(param, param_1);\n    float _2253;\n    if (conv.x < 0.5)\n    {\n        _2253 = _2249;\n    }\n    else\n    {\n        _2253 = (conv.y * conv.z) / (conv.z - (_2249 * (conv.z - conv.y)));\n    }\n    return _2253;\n}\n\nfloat fa_shadow_noise()\n{\n    return fract(52.98291778564453125 * fract(dot(gl_FragCoord.xy, vec2(0.067110560834407806396484375, 0.005837149918079376220703125))));\n}\n\nvec2 fa_shadow_vogel(int k, int n, float phi)\n{\n    float _2180 = (float(k) * 2.3999631404876708984375) + phi;\n    return vec2(cos(_2180), sin(_2180)) * sqrt((float(k) + 0.5) / float(n));\n}\n\nfloat fa_shadow_filter(vec2 uv, vec4 rect, float zr, float texel_m, float unit, float reach, float plane, vec3 conv, int mode, float k)\n{\n    if (mode == 1)\n    {\n        vec2 param = uv;\n        vec4 param_1 = rect;\n        vec3 param_2 = conv;\n        return float(zr <= fa_shadow_fetch(param, param_1, param_2));\n    }\n    float _2299 = fa_shadow_noise() * 6.283185482025146484375;\n    float radius = 1.5;\n    if (mode == 2)\n    {\n        float _2308;\n        if (k < 0.0)\n        {\n            _2308 = (-k) / max(zr, 0.100000001490116119384765625);\n        }\n        else\n        {\n            _2308 = k;\n        }\n        float _2328 = clamp((_2308 * reach) / texel_m, 3.0, 12.0);\n        float sum = 0.0;\n        float cnt = 0.0;\n        for (int i = 0; i < 16; i++)\n        {\n            int param_3 = i;\n            int param_4 = 16;\n            float param_5 = _2299;\n            vec2 _2347 = fa_shadow_vogel(param_3, param_4, param_5) * _2328;\n            vec2 param_6 = uv + (_2347 * fa_shadows[26].zw);\n            vec4 param_7 = rect;\n            vec3 param_8 = conv;\n            float _2359 = fa_shadow_fetch(param_6, param_7, param_8);\n            if (_2359 < (zr - (length(_2347) * plane)))\n            {\n                sum += _2359;\n                cnt += 1.0;\n            }\n        }\n        if (cnt < 0.5)\n        {\n            return 1.0;\n        }\n        float _2385 = sum / cnt;\n        float _2395;\n        if (k < 0.0)\n        {\n            _2395 = (-k) / max(_2385, 0.0500000007450580596923828125);\n        }\n        else\n        {\n            _2395 = k;\n        }\n        radius = clamp(((max(zr - _2385, 0.0) * unit) * _2395) / texel_m, 1.5, 16.0);\n    }\n    float lit = 0.0;\n    int _2417 = (mode == 2) ? 24 : 16;\n    for (int i_1 = 0; i_1 < _2417; i_1++)\n    {\n        int param_9 = i_1;\n        int param_10 = _2417;\n        float param_11 = _2299;\n        vec2 _2436 = fa_shadow_vogel(param_9, param_10, param_11) * radius;\n        vec2 param_12 = uv + (_2436 * fa_shadows[26].zw);\n        vec4 param_13 = rect;\n        vec3 param_14 = conv;\n        lit += float((zr - (length(_2436) * plane)) <= fa_shadow_fetch(param_12, param_13, param_14));\n    }\n    return lit / float(_2417);\n}\n\nfloat fa_shadow_cascade(int ci, vec3 world, vec3 n, vec3 l)\n{\n    float _2478 = max(fa_shadows[ci * 1 + 20].y, 0.001000000047497451305389404296875);\n    float _2483 = clamp(dot(n, l), 0.0, 1.0);\n    float _2489 = sqrt(1.0 - (_2483 * _2483));\n    float _2496 = min(_2489 / max(_2483, 0.20000000298023223876953125), 4.0);\n    float _2501;\n    if (fa_shadows[26].y > 0.0)\n    {\n        _2501 = fa_shadows[26].y;\n    }\n    else\n    {\n        _2501 = 1.5 * fa_shadows[ci * 1 + 20].x;\n    }\n    vec4 _2526 = mat4(fa_shadows[ci * 4 + 0], fa_shadows[ci * 4 + 1], fa_shadows[ci * 4 + 2], fa_shadows[ci * 4 + 3]) * vec4(world + (n * (_2501 * _2489)), 1.0);\n    float _2533 = _2526.x;\n    bool _2536 = _2533 < fa_shadows[ci * 1 + 16].x;\n    bool _2545;\n    if (!_2536)\n    {\n        _2545 = _2533 > fa_shadows[ci * 1 + 16].z;\n    }\n    else\n    {\n        _2545 = _2536;\n    }\n    bool _2554;\n    if (!_2545)\n    {\n        _2554 = _2526.y < fa_shadows[ci * 1 + 16].y;\n    }\n    else\n    {\n        _2554 = _2545;\n    }\n    bool _2563;\n    if (!_2554)\n    {\n        _2563 = _2526.y > fa_shadows[ci * 1 + 16].w;\n    }\n    else\n    {\n        _2563 = _2554;\n    }\n    bool _2570;\n    if (!_2563)\n    {\n        _2570 = _2526.z > 1.0;\n    }\n    else\n    {\n        _2570 = _2563;\n    }\n    if (_2570)\n    {\n        return -1.0;\n    }\n    float _2578;\n    if (fa_shadows[26].x > 0.0)\n    {\n        _2578 = fa_shadows[26].x;\n    }\n    else\n    {\n        _2578 = 1.5 * fa_shadows[ci * 1 + 20].x;\n    }\n    vec2 param = _2526.xy;\n    vec4 param_1 = fa_shadows[ci * 1 + 16];\n    float param_2 = _2526.z - ((_2578 * (1.0 + (0.5 * _2496))) / _2478);\n    float param_3 = fa_shadows[ci * 1 + 20].x;\n    float param_4 = _2478;\n    float param_5 = _2478 * 0.25;\n    float param_6 = ((fa_shadows[ci * 1 + 20].x * min(_2496, 3.0)) * 0.5) / _2478;\n    vec3 param_7 = vec3(0.0);\n    int param_8 = int(fa_shadows[25].z + 0.5);\n    float param_9 = fa_shadows[25].w;\n    return fa_shadow_filter(param, param_1, param_2, param_3, param_4, param_5, param_6, param_7, param_8, param_9);\n}\n\nfloat fa_shadow_sun(vec3 world, vec3 n, vec3 l)\n{\n    if (fa_mesh_fs_params[5].z < 0.5)\n    {\n        return 1.0;\n    }\n    int _2966 = int(fa_shadows[25].x + 0.5);\n    if (_2966 < 1)\n    {\n        return 1.0;\n    }\n    float _2981 = dot(world - fa_shadows[27].xyz, fa_shadows[28].xyz);\n    int param = _2966 - 1;\n    if (_2981 > fa_shadow_split_at(param))\n    {\n        return 1.0;\n    }\n    int ci = 0;\n    bool _2993 = _2966 > 1;\n    bool _3000;\n    if (_2993)\n    {\n        _3000 = _2981 > fa_shadows[24].x;\n    }\n    else\n    {\n        _3000 = _2993;\n    }\n    if (_3000)\n    {\n        ci = 1;\n    }\n    bool _3004 = _2966 > 2;\n    bool _3011;\n    if (_3004)\n    {\n        _3011 = _2981 > fa_shadows[24].y;\n    }\n    else\n    {\n        _3011 = _3004;\n    }\n    if (_3011)\n    {\n        ci = 2;\n    }\n    bool _3015 = _2966 > 3;\n    bool _3022;\n    if (_3015)\n    {\n        _3022 = _2981 > fa_shadows[24].z;\n    }\n    else\n    {\n        _3022 = _3015;\n    }\n    if (_3022)\n    {\n        ci = 3;\n    }\n    float s = -1.0;\n    for (int k = 0; k < 4; k++)\n    {\n        if (ci >= _2966)\n        {\n            break;\n        }\n        int param_1 = ci;\n        vec3 param_2 = world;\n        vec3 param_3 = n;\n        vec3 param_4 = l;\n        float _3048 = fa_shadow_cascade(param_1, param_2, param_3, param_4);\n        s = _3048;\n        if (_3048 >= 0.0)\n        {\n            break;\n        }\n        ci++;\n    }\n    if (s < 0.0)\n    {\n        return 1.0;\n    }\n    if (fa_shadows[25].y > 0.0)\n    {\n        float _3073;\n        if (ci > 0)\n        {\n            int param_5 = ci - 1;\n            _3073 = fa_shadow_split_at(param_5);\n        }\n        else\n        {\n            _3073 = fa_shadows[28].w;\n        }\n        int param_6 = ci;\n        float _3092 = fa_shadows[25].y * max(fa_shadow_split_at(param_6) - _3073, 9.9999997473787516355514526367188e-05);\n        int param_7 = ci;\n        float _3103 = clamp((_2981 - (fa_shadow_split_at(param_7) - _3092)) / _3092, 0.0, 1.0);\n        if (_3103 > 0.0)\n        {\n            float s2 = 1.0;\n            if ((ci + 1) < _2966)\n            {\n                int param_8 = ci + 1;\n                vec3 param_9 = world;\n                vec3 param_10 = n;\n                vec3 param_11 = l;\n                float _3124 = fa_shadow_cascade(param_8, param_9, param_10, param_11);\n                s2 = _3124;\n                if (_3124 < 0.0)\n                {\n                    s2 = s;\n                }\n            }\n            s = mix(s, s2, _3103);\n        }\n    }\n    return s;\n}\n\nfloat fa_shadow_factor(vec3 n, vec3 l)\n{\n    vec3 param = fa_world_pos;\n    vec3 param_1 = n;\n    vec3 param_2 = l;\n    return fa_shadow_sun(param, param_1, param_2);\n}\n\nfloat fa_shadow_local(int li, vec3 world, vec3 n, vec3 l)\n{\n    bool _2636 = fa_mesh_fs_params[5].z < 0.5;\n    bool _2643;\n    if (!_2636)\n    {\n        _2643 = fa_shadows[29].x < 0.5;\n    }\n    else\n    {\n        _2643 = _2636;\n    }\n    if (_2643)\n    {\n        return 1.0;\n    }\n    int param = (int(fa_shadows[29].x + 0.5) - 1) + li;\n    vec4 _2656 = fa_light_texel(param);\n    float _2657 = _2656.x;\n    if (_2657 < 0.0)\n    {\n        return 1.0;\n    }\n    int _2666 = int(_2657 + 0.5);\n    int param_1 = _2666;\n    vec4 _2670 = fa_light_texel(param_1);\n    int param_2 = _2666 + 1;\n    vec4 _2675 = fa_light_texel(param_2);\n    float fade = 1.0;\n    float _2678 = _2670.y;\n    if (_2678 > 0.0)\n    {\n        float _2695 = 1.0 - smoothstep(0.75 * _2678, _2678, length(world - fa_shadows[27].xyz));\n        fade = _2695;\n        if (_2695 <= 0.0)\n        {\n            return 1.0;\n        }\n    }\n    int face = 0;\n    if (_2670.x > 1.5)\n    {\n        int param_3 = li;\n        int param_4 = fa_light_base(param_3);\n        vec3 param_5 = world - fa_light_texel(param_4).xyz;\n        face = fa_cube_face(param_5);\n    }\n    int _2724 = (_2666 + 2) + (face * 6);\n    int param_6 = _2724;\n    int param_7 = _2724 + 1;\n    int param_8 = _2724 + 3;\n    vec4 _2738 = fa_light_texel(param_8);\n    int param_9 = _2724 + 4;\n    vec4 _2743 = fa_light_texel(param_9);\n    int param_10 = _2724 + 5;\n    vec4 _2748 = fa_light_texel(param_10);\n    float _2760 = _2748.x * max(dot(_2738, vec4(world, 1.0)), 0.001000000047497451305389404296875);\n    float _2765 = clamp(dot(n, l), 0.0, 1.0);\n    float _2788 = clamp(dot(n, _2738.xyz), -1.0, 1.0);\n    int param_11 = li;\n    int param_12 = fa_light_base(param_11);\n    float _2812 = min(sqrt(1.0 - (_2788 * _2788)) / max(abs(dot(n, world - fa_light_texel(param_12).xyz)) / max(dot(_2738, vec4(world, 1.0)), 0.001000000047497451305389404296875), 0.20000000298023223876953125), 4.0);\n    float _2815 = _2675.y;\n    float _2817;\n    if (_2815 > 0.0)\n    {\n        _2817 = _2815;\n    }\n    else\n    {\n        _2817 = 1.5 * _2760;\n    }\n    vec4 _2837 = vec4(world + (n * (_2817 * sqrt(1.0 - (_2765 * _2765)))), 1.0);\n    float _2841 = dot(_2738, _2837);\n    float _2844 = _2748.y;\n    if (_2841 < _2844)\n    {\n        return 1.0;\n    }\n    vec2 _2859 = vec2(dot(fa_light_texel(param_6), _2837), dot(fa_light_texel(param_7), _2837)) / vec2(_2841);\n    float _2861 = _2859.x;\n    bool _2864 = _2861 < _2743.x;\n    bool _2873;\n    if (!_2864)\n    {\n        _2873 = _2861 > _2743.z;\n    }\n    else\n    {\n        _2873 = _2864;\n    }\n    bool _2882;\n    if (!_2873)\n    {\n        _2882 = _2859.y < _2743.y;\n    }\n    else\n    {\n        _2882 = _2873;\n    }\n    bool _2891;\n    if (!_2882)\n    {\n        _2891 = _2859.y > _2743.w;\n    }\n    else\n    {\n        _2891 = _2882;\n    }\n    if (_2891)\n    {\n        return 1.0;\n    }\n    float _2897 = _2675.x;\n    float _2899;\n    if (_2897 > 0.0)\n    {\n        _2899 = _2897;\n    }\n    else\n    {\n        _2899 = 1.5 * _2760;\n    }\n    vec2 param_13 = _2859;\n    vec4 param_14 = _2743;\n    float param_15 = _2841 - (_2899 * (1.0 + (0.5 * _2812)));\n    float param_16 = _2760;\n    float param_17 = 1.0;\n    float param_18 = _2748.z * 0.25;\n    float param_19 = (_2760 * min(_2812, 3.0)) * 0.5;\n    vec3 param_20 = vec3(1.0, _2844, _2748.z);\n    int param_21 = int(_2670.z + 0.5);\n    float param_22 = _2670.w;\n    return mix(1.0, fa_shadow_filter(param_13, param_14, param_15, param_16, param_17, param_18, param_19, param_20, param_21, param_22), fade);\n}\n\nLightSample fa_light_shadowed(int li, vec3 world_pos, vec3 gn)\n{\n    bool _4344 = fa_lm.z > 0.5;\n    bool _4350;\n    if (_4344)\n    {\n        int param = li;\n        _4350 = fa_light_baked(param);\n    }\n    else\n    {\n        _4350 = _4344;\n    }\n    if (_4350)\n    {\n        int param_1 = li;\n        return LightSample(vec3(0.0, 1.0, 0.0), vec3(0.0), 0.0, 1.0, 0.0, int(fa_light_type(param_1) + 0.5));\n    }\n    int param_2 = li;\n    vec3 param_3 = world_pos;\n    vec3 param_4 = gn;\n    LightSample _4374 = fa_light_sample_n(param_2, param_3, param_4);\n    vec3 _6682 = _4374.color;\n    float _6684 = _4374.shadow;\n    if ((_4374.type == 0) && (li == 0))\n    {\n        vec3 param_5 = gn;\n        vec3 param_6 = _4374.direction;\n        float _4388 = fa_shadow_factor(param_5, param_6);\n        _6684 = _4388;\n        _6682 *= _4388;\n    }\n    else\n    {\n        bool _4399 = _4374.type != 0;\n        bool _4405;\n        if (_4399)\n        {\n            _4405 = _4374.attenuation > 0.0;\n        }\n        else\n        {\n            _4405 = _4399;\n        }\n        if (_4405)\n        {\n            int param_7 = li;\n            vec3 param_8 = world_pos;\n            vec3 param_9 = gn;\n            vec3 param_10 = _4374.direction;\n            float _4417 = fa_shadow_local(param_7, param_8, param_9, param_10);\n            _6684 = _4417;\n            _6682 *= _4417;\n        }\n    }\n    return LightSample(_4374.direction, _6682, _4374.attenuation, _6684, _4374._distance, _4374.type);\n}\n\nvec3 fa_ltc_tangent(vec3 n, vec3 v)\n{\n    vec3 _4457 = v - (n * dot(v, n));\n    vec3 t = _4457;\n    float _4461 = dot(_4457, _4457);\n    float l2 = _4461;\n    if (_4461 < 1.0000000133514319600180897396058e-10)\n    {\n        vec3 _4471;\n        if (abs(n.z) < 0.999000012874603271484375)\n        {\n            _4471 = cross(n, vec3(0.0, 0.0, 1.0));\n        }\n        else\n        {\n            _4471 = cross(n, vec3(1.0, 0.0, 0.0));\n        }\n        t = _4471;\n        l2 = dot(_4471, _4471);\n    }\n    return t * inversesqrt(l2);\n}\n\nvec3 fa_ltc_local(vec3 t1, vec3 n, vec3 p)\n{\n    return vec3(dot(t1, p), dot(cross(n, t1), p), dot(n, p));\n}\n\nvec3 fa_ltc_edge_vector(vec3 a, vec3 b)\n{\n    float _4506 = dot(a, a);\n    float _4510 = dot(b, b);\n    if ((_4506 < 1.0000000195414813782625560981111e-24) || (_4510 < 1.0000000195414813782625560981111e-24))\n    {\n        return vec3(0.0);\n    }\n    vec3 _4524 = a * inversesqrt(_4506);\n    vec3 _4529 = b * inversesqrt(_4510);\n    float _4533 = dot(_4524, _4529);\n    float _4536 = abs(_4533);\n    float g = (((((((((((0.0416471660137176513671875 * _4536) - 0.1924748718738555908203125) * _4536) + 0.4179156124591827392578125) * _4536) - 0.616057217121124267578125) * _4536) + 0.777722418308258056640625) * _4536) - 0.999542415142059326171875) * _4536) + 1.570791721343994140625;\n    if (_4533 < 0.0)\n    {\n        g = (3.1415927410125732421875 * inversesqrt(max(1.0 - (_4533 * _4533), 1.0000000116860974230803549289703e-07))) - g;\n    }\n    return cross(_4524, _4529) * g;\n}\n\nvoid fa_ltc_clip_edge(vec3 a, vec3 b, inout vec3 sum, inout vec3 leave, inout vec3 enter, inout vec2 seen)\n{\n    bool _4593 = a.z > 0.0;\n    bool _4597 = b.z > 0.0;\n    if (_4593 && _4597)\n    {\n        vec3 param = a;\n        vec3 param_1 = b;\n        sum += fa_ltc_edge_vector(param, param_1);\n    }\n    else\n    {\n        if (_4593 != _4597)\n        {\n            vec3 _4632 = a + ((b - a) * (a.z / (a.z - b.z)));\n            _4632.z = 0.0;\n            if (_4593)\n            {\n                vec3 param_2 = a;\n                vec3 param_3 = _4632;\n                sum += fa_ltc_edge_vector(param_2, param_3);\n                leave = _4632;\n                seen.x = 1.0;\n            }\n            else\n            {\n                vec3 param_4 = _4632;\n                vec3 param_5 = b;\n                sum += fa_ltc_edge_vector(param_4, param_5);\n                enter = _4632;\n                seen.y = 1.0;\n            }\n        }\n    }\n}\n\nfloat fa_ltc_quad(vec4 abcd, vec3 p0, vec3 p1, vec3 p2, vec3 p3)\n{\n    vec3 _4681 = vec3((abcd.x * p0.x) + (abcd.y * p0.z), p0.y, (abcd.z * p0.x) + (abcd.w * p0.z));\n    vec3 _4707 = vec3((abcd.x * p1.x) + (abcd.y * p1.z), p1.y, (abcd.z * p1.x) + (abcd.w * p1.z));\n    vec3 _4733 = vec3((abcd.x * p2.x) + (abcd.y * p2.z), p2.y, (abcd.z * p2.x) + (abcd.w * p2.z));\n    vec3 _4759 = vec3((abcd.x * p3.x) + (abcd.y * p3.z), p3.y, (abcd.z * p3.x) + (abcd.w * p3.z));\n    vec3 sum = vec3(0.0);\n    vec3 leave = vec3(0.0);\n    vec3 enter = vec3(0.0);\n    vec3 param = _4681;\n    vec3 param_1 = _4707;\n    vec3 param_2 = vec3(0.0);\n    vec3 param_3 = vec3(0.0);\n    vec3 param_4 = vec3(0.0);\n    vec2 param_5 = vec2(0.0);\n    fa_ltc_clip_edge(param, param_1, param_2, param_3, param_4, param_5);\n    sum = param_2;\n    leave = param_3;\n    enter = param_4;\n    vec3 param_6 = _4707;\n    vec3 param_7 = _4733;\n    vec3 param_8 = param_2;\n    vec3 param_9 = param_3;\n    vec3 param_10 = param_4;\n    vec2 param_11 = param_5;\n    fa_ltc_clip_edge(param_6, param_7, param_8, param_9, param_10, param_11);\n    sum = param_8;\n    leave = param_9;\n    enter = param_10;\n    vec3 param_12 = _4733;\n    vec3 param_13 = _4759;\n    vec3 param_14 = param_8;\n    vec3 param_15 = param_9;\n    vec3 param_16 = param_10;\n    vec2 param_17 = param_11;\n    fa_ltc_clip_edge(param_12, param_13, param_14, param_15, param_16, param_17);\n    sum = param_14;\n    leave = param_15;\n    enter = param_16;\n    vec3 param_18 = _4759;\n    vec3 param_19 = _4681;\n    vec3 param_20 = param_14;\n    vec3 param_21 = param_15;\n    vec3 param_22 = param_16;\n    vec2 param_23 = param_17;\n    fa_ltc_clip_edge(param_18, param_19, param_20, param_21, param_22, param_23);\n    sum = param_20;\n    leave = param_21;\n    enter = param_22;\n    if ((param_23.x * param_23.y) > 0.5)\n    {\n        vec3 param_24 = leave;\n        vec3 param_25 = enter;\n        sum += fa_ltc_edge_vector(param_24, param_25);\n    }\n    return sum.z * 0.15915493667125701904296875;\n}\n\nfloat fa_ltc_rect(vec4 abcd, vec3 center, vec3 ex, vec3 ey)\n{\n    vec4 param = abcd;\n    vec3 param_1 = (center - ex) - ey;\n    vec3 param_2 = (center + ex) - ey;\n    vec3 param_3 = (center + ex) + ey;\n    vec3 param_4 = (center - ex) + ey;\n    return abs(fa_ltc_quad(param, param_1, param_2, param_3, param_4));\n}\n\nfloat fa_area_form(vec4 m, float shape, vec3 pc, vec3 ex, vec3 ey)\n{\n    if ((shape < 0.5) || (shape > 1.5))\n    {\n        vec4 param = m;\n        vec3 param_1 = pc;\n        vec3 param_2 = ex;\n        vec3 param_3 = ey;\n        return fa_ltc_rect(param, param_1, param_2, param_3);\n    }\n    vec3 _4909 = (pc + (ex * 0.92387950420379638671875)) + (ey * 0.3826834261417388916015625);\n    vec3 _4933 = (pc - (ex * 0.92387950420379638671875)) + (ey * 0.3826834261417388916015625);\n    vec3 _4949 = (pc - (ex * 0.3826834261417388916015625)) - (ey * 0.92387950420379638671875);\n    vec4 param_4 = m;\n    vec3 param_5 = _4909;\n    vec3 param_6 = (pc + (ex * 0.3826834261417388916015625)) + (ey * 0.92387950420379638671875);\n    vec3 param_7 = (pc - (ex * 0.3826834261417388916015625)) + (ey * 0.92387950420379638671875);\n    vec3 param_8 = _4933;\n    vec4 param_9 = m;\n    vec3 param_10 = _4909;\n    vec3 param_11 = _4933;\n    vec3 param_12 = (pc - (ex * 0.92387950420379638671875)) - (ey * 0.3826834261417388916015625);\n    vec3 param_13 = _4949;\n    vec4 param_14 = m;\n    vec3 param_15 = _4909;\n    vec3 param_16 = _4949;\n    vec3 param_17 = (pc + (ex * 0.3826834261417388916015625)) - (ey * 0.92387950420379638671875);\n    vec3 param_18 = (pc + (ex * 0.92387950420379638671875)) - (ey * 0.3826834261417388916015625);\n    return abs((fa_ltc_quad(param_4, param_5, param_6, param_7, param_8) + fa_ltc_quad(param_9, param_10, param_11, param_12, param_13)) + fa_ltc_quad(param_14, param_15, param_16, param_17, param_18));\n}\n\nvec2 fa_ltc_uv(float roughness, float ndv)\n{\n    return ((vec2(clamp((roughness - 0.0500000007450580596923828125) * 1.0526316165924072265625, 0.0, 1.0), sqrt(clamp(1.0 - ndv, 0.0, 1.0))) * 63.0) + vec2(0.5)) * vec2(0.015625);\n}\n\nvec3 fa_area_shade(int li, vec3 world_pos, vec3 n, vec3 v, vec3 diffuse_color, vec3 f0, float f90, float roughness, float ndv, float window)\n{\n    int param = li;\n    int _5007 = fa_light_base(param);\n    int param_1 = _5007;\n    int param_2 = _5007 + 1;\n    int param_3 = _5007 + 2;\n    int param_4 = _5007 + 4;\n    vec4 _5029 = fa_light_texel(param_4);\n    int param_5 = _5007 + 5;\n    vec4 _5034 = fa_light_texel(param_5);\n    int param_6 = _5007 + 6;\n    vec4 _5039 = fa_light_texel(param_6);\n    float _5040 = _5039.w;\n    vec3 _5045 = fa_light_texel(param_1).xyz - world_pos;\n    bool _5047 = _5040 < 1.5;\n    bool _5054;\n    if (_5047)\n    {\n        _5054 = dot(normalize(fa_light_texel(param_3).xyz), _5045) >= 0.0;\n    }\n    else\n    {\n        _5054 = _5047;\n    }\n    if (_5054)\n    {\n        return vec3(0.0);\n    }\n    bool _5063 = (_5040 > 0.5) && _5047;\n    float _5067 = _5063 ? 1.0539000034332275390625 : 1.0;\n    vec3 _5070 = _5029.xyz;\n    float _5072 = _5029.w;\n    vec3 _5078 = _5034.xyz;\n    float _5080 = _5034.w;\n    vec3 up = _5078 * (_5080 * _5067);\n    float _5086;\n    if (_5063)\n    {\n        _5086 = (3.1415927410125732421875 * _5072) * _5072;\n    }\n    else\n    {\n        _5086 = (4.0 * _5072) * _5080;\n    }\n    if (_5040 > 1.5)\n    {\n        vec3 _5112 = cross(_5070, -_5045);\n        vec3 perp = _5112;\n        float _5116 = dot(_5112, _5112);\n        vec3 _5119;\n        if (_5116 > 1.0000000133514319600180897396058e-10)\n        {\n            _5119 = perp * inversesqrt(_5116);\n        }\n        else\n        {\n            _5119 = _5078;\n        }\n        perp = _5119;\n        up = _5119 * _5080;\n    }\n    float _5140 = max(_5086, 9.9999999747524270787835121154785e-07);\n    vec3 param_7 = n;\n    vec3 param_8 = v;\n    vec3 _5150 = fa_ltc_tangent(param_7, param_8);\n    vec3 param_9 = _5150;\n    vec3 param_10 = n;\n    vec3 param_11 = _5045;\n    vec3 _5158 = fa_ltc_local(param_9, param_10, param_11);\n    vec3 param_12 = _5150;\n    vec3 param_13 = n;\n    vec3 param_14 = _5070 * (_5072 * _5067);\n    vec3 _5166 = fa_ltc_local(param_12, param_13, param_14);\n    vec3 param_15 = _5150;\n    vec3 param_16 = n;\n    vec3 param_17 = up;\n    vec3 _5174 = fa_ltc_local(param_15, param_16, param_17);\n    vec4 param_18 = vec4(1.0, 0.0, 0.0, 1.0);\n    float param_19 = _5040;\n    vec3 param_20 = _5158;\n    vec3 param_21 = _5166;\n    vec3 param_22 = _5174;\n    float param_23 = roughness;\n    float param_24 = ndv;\n    vec2 _5193 = fa_ltc_uv(param_23, param_24) * 64.0;\n    vec2 param_25 = _5193;\n    vec2 param_26 = _5193 + vec2(64.0, 0.0);\n    vec4 _5203 = fa_atlas_fetch(param_26);\n    vec4 param_27 = fa_atlas_fetch(param_25);\n    float param_28 = _5040;\n    vec3 param_29 = _5158;\n    vec3 param_30 = _5166;\n    vec3 param_31 = _5174;\n    return (((diffuse_color * fa_area_form(param_18, param_19, param_20, param_21, param_22)) + (((f0 * _5203.x) + ((vec3(f90) - f0) * _5203.y)) * fa_area_form(param_27, param_28, param_29, param_30, param_31))) * fa_light_texel(param_2).xyz) * ((((3.1415927410125732421875 * dot(_5045, _5045)) + _5140) / _5140) * window);\n}\n\nvec3 fa_light_rgb(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 1;\n    return fa_light_texel(param_1).xyz;\n}\n\nfloat fa_d_charlie(float alpha, float ndh)\n{\n    float _4047 = 1.0 / alpha;\n    return ((2.0 + _4047) * pow(sqrt(max(1.0 - (ndh * ndh), 9.9999997473787516355514526367188e-05)), _4047)) * 0.15915493667125701904296875;\n}\n\nfloat fa_v_ashikhmin(float ndl, float ndv)\n{\n    return clamp(0.25 / max((ndl + ndv) - (ndl * ndv), 9.9999997473787516355514526367188e-05), 0.0, 1.0);\n}\n\nfloat fa_layers_coat(FaLayers L, vec3 l, vec3 h, float vdh)\n{\n    float _4082 = max(dot(L.nc, l), 0.0);\n    float _4088 = max(dot(L.nc, h), 0.0);\n    float _4097 = ((_4088 * _4088) * (L.coat_a2 - 1.0)) + 1.0;\n    return (((L.coat * (0.039999999105930328369140625 + (0.959999978542327880859375 * pow(clamp(1.0 - vdh, 0.0, 1.0), 5.0)))) * (((L.coat_a2 / ((3.1415927410125732421875 * _4097) * _4097)) * (0.5 / max(mix((2.0 * _4082) * L.coat_ndv, _4082 + L.coat_ndv, L.coat_alpha), 9.9999997473787516355514526367188e-05))) * 3.1415927410125732421875)) * step(9.9999997473787516355514526367188e-05, _4082)) * _4082;\n}\n\nvec3 fa_area_layers(FaLayers L, int li, vec3 world_pos, vec3 n, vec3 v, vec3 l, vec3 diffuse_color, vec3 f0, float roughness, float ndv, float window)\n{\n    int param = li;\n    vec3 param_1 = world_pos;\n    vec3 param_2 = n;\n    vec3 param_3 = v;\n    vec3 param_4 = diffuse_color;\n    vec3 param_5 = f0;\n    float param_6 = L.f90;\n    float param_7 = roughness;\n    float param_8 = ndv;\n    float param_9 = window;\n    float _5271;\n    if (L.sheen_on)\n    {\n        _5271 = L.sheen_scale;\n    }\n    else\n    {\n        _5271 = 1.0;\n    }\n    vec3 result = fa_area_shade(param, param_1, param_2, param_3, param_4, param_5, param_6, param_7, param_8, param_9) * (L.keep * _5271);\n    vec3 _5284 = normalize(l + v);\n    int param_10 = li;\n    vec3 _5295 = fa_light_rgb(param_10) * window;\n    if (L.sheen_on)\n    {\n        float _5304 = max(dot(n, l), 0.0);\n        float param_11 = L.sheen_alpha;\n        float param_12 = max(dot(n, _5284), 0.0);\n        float param_13 = _5304;\n        float param_14 = ndv;\n        result += ((L.sheen * _5295) * (((((fa_d_charlie(param_11, param_12) * fa_v_ashikhmin(param_13, param_14)) * 3.1415927410125732421875) * step(9.9999997473787516355514526367188e-05, _5304)) * _5304) * L.keep));\n    }\n    if (L.coat > 0.0)\n    {\n        FaLayers param_15 = L;\n        vec3 param_16 = l;\n        vec3 param_17 = _5284;\n        float param_18 = max(dot(v, _5284), 0.0);\n        result += (_5295 * fa_layers_coat(param_15, param_16, param_17, param_18));\n    }\n    return result;\n}\n\nfloat fa_d_ggx_aniso(float ndh, float tdh, float bdh, float at, float ab)\n{\n    float _3950 = tdh / at;\n    float _3954 = bdh / ab;\n    float _3966 = ((_3950 * _3950) + (_3954 * _3954)) + (ndh * ndh);\n    return 1.0 / ((((3.1415927410125732421875 * at) * ab) * _3966) * _3966);\n}\n\nfloat fa_lambda_ggx_aniso(float n, float t, float b, float at, float ab)\n{\n    return 0.5 * (sqrt(1.0 + (((((at * at) * t) * t) + (((ab * ab) * b) * b)) / max(n * n, 9.9999999392252902907785028219223e-09))) - 1.0);\n}\n\nfloat fa_v_ggx_aniso(float ndl, float ndv, float tdv, float bdv, float tdl, float bdl, float at, float ab)\n{\n    float param = ndv;\n    float param_1 = tdv;\n    float param_2 = bdv;\n    float param_3 = at;\n    float param_4 = ab;\n    float param_5 = ndl;\n    float param_6 = tdl;\n    float param_7 = bdl;\n    float param_8 = at;\n    float param_9 = ab;\n    return clamp(1.0 / ((4.0 * max(ndl * ndv, 9.9999997473787516355514526367188e-05)) * ((1.0 + fa_lambda_ggx_aniso(param, param_1, param_2, param_3, param_4)) + fa_lambda_ggx_aniso(param_5, param_6, param_7, param_8, param_9))), 0.0, 1.0);\n}\n\nvec3 fa_layers_light(FaLayers L, vec3 diffuse_color, vec3 f0, vec3 n, vec3 v, vec3 l, vec3 h, float ndl, float ndv, float ndh, float vdh, float alpha, float a2)\n{\n    float _4146 = step(9.9999997473787516355514526367188e-05, ndl);\n    float d_ggx;\n    float vis;\n    if (L.aniso != 0.0)\n    {\n        float param = ndh;\n        float param_1 = dot(L.t, h);\n        float param_2 = dot(L.b, h);\n        float param_3 = L.at;\n        float param_4 = L.ab;\n        d_ggx = fa_d_ggx_aniso(param, param_1, param_2, param_3, param_4);\n        float param_5 = ndl;\n        float param_6 = ndv;\n        float param_7 = dot(L.t, v);\n        float param_8 = dot(L.b, v);\n        float param_9 = dot(L.t, l);\n        float param_10 = dot(L.b, l);\n        float param_11 = L.at;\n        float param_12 = L.ab;\n        vis = fa_v_ggx_aniso(param_5, param_6, param_7, param_8, param_9, param_10, param_11, param_12);\n    }\n    else\n    {\n        float _4225 = ((ndh * ndh) * (a2 - 1.0)) + 1.0;\n        d_ggx = a2 / ((3.1415927410125732421875 * _4225) * _4225);\n        vis = 0.5 / max(mix((2.0 * ndl) * ndv, ndl + ndv, alpha), 9.9999997473787516355514526367188e-05);\n    }\n    vec3 base = diffuse_color + (((f0 + ((vec3(L.f90) - f0) * pow(clamp(1.0 - vdh, 0.0, 1.0), 5.0))) * ((d_ggx * vis) * 3.1415927410125732421875)) * _4146);\n    if (L.sheen_on)\n    {\n        float param_13 = L.sheen_alpha;\n        float param_14 = ndh;\n        float param_15 = ndl;\n        float param_16 = ndv;\n        base = (base * L.sheen_scale) + (L.sheen * (((fa_d_charlie(param_13, param_14) * fa_v_ashikhmin(param_15, param_16)) * 3.1415927410125732421875) * _4146));\n    }\n    vec3 result = base * (L.keep * ndl);\n    if (L.coat > 0.0)\n    {\n        FaLayers param_17 = L;\n        vec3 param_18 = l;\n        vec3 param_19 = h;\n        float param_20 = vdh;\n        result += vec3(fa_layers_coat(param_17, param_18, param_19, param_20));\n    }\n    return result;\n}\n\nvec2 fa_env_brdf(float rough, float ndv)\n{\n    vec4 _3353 = (vec4(-1.0, -0.0274999998509883880615234375, -0.572000026702880859375, 0.02199999988079071044921875) * rough) + vec4(1.0, 0.0425000004470348358154296875, 1.03999996185302734375, -0.039999999105930328369140625);\n    float _3356 = _3353.x;\n    return (vec2(-1.03999996185302734375, 1.03999996185302734375) * ((min(_3356 * _3356, exp2((-9.27999973297119140625) * ndv)) * _3356) + _3353.y)) + _3353.zw;\n}\n\nvec3 fa_environment(vec3 d, float rough)\n{\n    if (fa_mesh_fs_params[11].w > 0.5)\n    {\n        return textureLod(fa_env_tex_fa_env_smp, d, clamp(rough, 0.0, 1.0) * fa_mesh_fs_params[12].w).xyz;\n    }\n    float _3259 = rough * rough;\n    float _3289 = 0.60000002384185791015625 * _3259;\n    return mix(mix(fa_mesh_fs_params[12].xyz * 0.550000011920928955078125, mix(fa_mesh_fs_params[12].xyz, fa_mesh_fs_params[11].xyz, vec3(pow(clamp(d.y * (1.0 - (0.699999988079071044921875 * _3259)), 0.0, 1.0), 0.550000011920928955078125))), vec3(smoothstep((-0.0500000007450580596923828125) - _3289, 0.0500000007450580596923828125 + _3289, d.y))), ((fa_mesh_fs_params[11].xyz + fa_mesh_fs_params[12].xyz) * 0.5) * 0.800000011920928955078125, vec3(_3259 * 0.60000002384185791015625));\n}\n\nvec3 fa_layers_ibl(FaLayers L, vec3 n, vec3 v, vec3 f0, float roughness)\n{\n    vec3 rn = n;\n    if (L.aniso != 0.0)\n    {\n        vec3 _3833;\n        if (L.aniso >= 0.0)\n        {\n            _3833 = L.b;\n        }\n        else\n        {\n            _3833 = L.t;\n        }\n        rn = normalize(mix(n, cross(cross(_3833, v), _3833), vec3(abs(L.aniso))));\n    }\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05);\n    vec2 _3866 = fa_env_brdf(param, param_1);\n    vec3 param_2 = reflect(-v, rn);\n    float param_3 = roughness;\n    vec3 result = (fa_environment(param_2, param_3) * ((f0 * _3866.x) + (vec3(L.f90) * _3866.y))) * L.base_scale;\n    if (L.sheen_on)\n    {\n        vec3 param_4 = n;\n        float param_5 = L.sheen_rough;\n        result += ((L.sheen * (L.sheen_e * L.keep)) * fa_environment(param_4, param_5));\n    }\n    if (L.coat > 0.0)\n    {\n        float param_6 = L.coat_rough;\n        float param_7 = L.coat_ndv;\n        vec2 _3921 = fa_env_brdf(param_6, param_7);\n        vec3 param_8 = reflect(-v, L.nc);\n        float param_9 = L.coat_rough;\n        result += (fa_environment(param_8, param_9) * (L.coat * ((0.039999999105930328369140625 * _3921.x) + _3921.y)));\n    }\n    return result;\n}\n\nvec3 fa_sky_reflection(vec3 n, vec3 v, vec3 f0, float roughness)\n{\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05);\n    vec2 _3395 = fa_env_brdf(param, param_1);\n    vec3 param_2 = reflect(-v, n);\n    float param_3 = roughness;\n    return fa_environment(param_2, param_3) * ((f0 * _3395.x) + vec3(_3395.y));\n}\n\nvec3 fa_shadow_debug(vec3 color, vec3 world)\n{\n    if (fa_shadows[27].w < 0.5)\n    {\n        return color;\n    }\n    int _3148 = int(fa_shadows[25].x + 0.5);\n    float _3158 = dot(world - fa_shadows[27].xyz, fa_shadows[28].xyz);\n    vec3 tint = vec3(0.3499999940395355224609375);\n    bool _3163 = _3148 > 0;\n    bool _3172;\n    if (_3163)\n    {\n        int param = _3148 - 1;\n        _3172 = _3158 <= fa_shadow_split_at(param);\n    }\n    else\n    {\n        _3172 = _3163;\n    }\n    if (_3172)\n    {\n        tint = vec3(1.0, 0.1500000059604644775390625, 0.100000001490116119384765625);\n        bool _3178 = _3148 > 1;\n        bool _3185;\n        if (_3178)\n        {\n            _3185 = _3158 > fa_shadows[24].x;\n        }\n        else\n        {\n            _3185 = _3178;\n        }\n        if (_3185)\n        {\n            tint = vec3(0.100000001490116119384765625, 0.89999997615814208984375, 0.20000000298023223876953125);\n        }\n        bool _3191 = _3148 > 2;\n        bool _3198;\n        if (_3191)\n        {\n            _3198 = _3158 > fa_shadows[24].y;\n        }\n        else\n        {\n            _3198 = _3191;\n        }\n        if (_3198)\n        {\n            tint = vec3(0.1500000059604644775390625, 0.300000011920928955078125, 1.0);\n        }\n        bool _3204 = _3148 > 3;\n        bool _3211;\n        if (_3204)\n        {\n            _3211 = _3158 > fa_shadows[24].z;\n        }\n        else\n        {\n            _3211 = _3204;\n        }\n        if (_3211)\n        {\n            tint = vec3(1.0, 0.89999997615814208984375, 0.100000001490116119384765625);\n        }\n    }\n    return mix(color, tint, vec3(0.550000011920928955078125));\n}\n\nvoid main()\n{\n    fa_inst_load();\n    vec3 _6382 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _6382 = -_6382;\n    }\n    vec3 _5740 = normalize(fa_mesh_fs_params[0].xyz - fa_world_pos);\n    vec3 param = fa_world_pos;\n    fa_cluster_begin(param);\n    SurfaceInput param_1 = SurfaceInput(fa_world_pos, _6382, fa_world_tangent, fa_uv, fa_vertex_color, _5740, gl_FrontFacing);\n    Surface _5748 = fa_standard_surface(param_1);\n    vec3 _6413 = _5748.albedo;\n    float _6414 = _5748.alpha;\n    vec3 _6415 = _5748.normal;\n    float _6416 = _5748.metallic;\n    float _6417 = _5748.roughness;\n    float _6418 = _5748.occlusion;\n    vec3 _6419 = _5748.emission;\n    float _6420 = _5748.clearcoat;\n    float _6421 = _5748.clearcoat_roughness;\n    vec3 _6422 = _5748.sheen_color;\n    float _6423 = _5748.sheen_roughness;\n    float _6424 = _5748.anisotropy;\n    float _6425 = _5748.anisotropy_rotation;\n    float _6426 = _5748.specular;\n    float _6427 = _5748.ior;\n    vec3 _6428 = _5748.specular_color;\n    SurfaceInput param_2 = SurfaceInput(fa_world_pos, _6382, fa_world_tangent, fa_uv, fa_vertex_color, _5740, gl_FrontFacing);\n    Surface param_3 = _5748;\n    surface(param_2, param_3);\n    _6413 = param_3.albedo;\n    _6414 = param_3.alpha;\n    _6415 = param_3.normal;\n    _6416 = param_3.metallic;\n    _6417 = param_3.roughness;\n    _6418 = param_3.occlusion;\n    _6419 = param_3.emission;\n    _6420 = param_3.clearcoat;\n    _6421 = param_3.clearcoat_roughness;\n    _6422 = param_3.sheen_color;\n    _6423 = param_3.sheen_roughness;\n    _6424 = param_3.anisotropy;\n    _6425 = param_3.anisotropy_rotation;\n    _6426 = param_3.specular;\n    _6427 = param_3.ior;\n    _6428 = param_3.specular_color;\n    vec3 param_4 = fa_world_pos;\n    vec3 param_5 = _6382;\n    vec3 param_6 = param_3.albedo;\n    vec3 param_7 = param_3.normal;\n    fa_apply_decals(param_4, param_5, param_6, param_7);\n    _6413 = param_6;\n    _6415 = param_7;\n    vec3 result;\n    if (fa_mesh_fs_params[3].w > 0.5)\n    {\n        result = _6413;\n    }\n    else\n    {\n        vec3 _5787 = normalize(_6415);\n        float _5794 = clamp(_6416, 0.0, 1.0);\n        float _5798 = clamp(_6417, 0.0500000007450580596923828125, 1.0);\n        float _5802 = _5798 * _5798;\n        float _5806 = _5802 * _5802;\n        float _5811 = max(dot(_5787, _5740), 9.9999997473787516355514526367188e-05);\n        vec3 _5817 = _6413 * (1.0 - _5794);\n        vec3 _5824 = mix(vec3(0.039999999105930328369140625), _6413, vec3(_5794));\n        vec3 f0 = _5824;\n        SurfaceInput param_8 = SurfaceInput(fa_world_pos, _6382, fa_world_tangent, fa_uv, fa_vertex_color, _5740, gl_FrontFacing);\n        Surface param_9 = Surface(_6413, _6414, _6415, _6416, _6417, _6418, _6419, _6420, _6421, _6422, _6423, _6424, _6425, _6426, _6427, _6428);\n        vec3 param_10 = _5787;\n        vec3 param_11 = _5740;\n        float param_12 = _5794;\n        float param_13 = _5798;\n        vec3 param_14 = _5824;\n        FaLayers _5840 = fa_layers_setup(param_8, param_9, param_10, param_11, param_12, param_13, param_14);\n        f0 = param_14;\n        vec3 param_15 = _5787;\n        vec3 lit = (fa_indirect_diffuse(param_15) * _5817) * _6418;\n        if (_5840.on)\n        {\n            lit *= _5840.base_scale;\n        }\n        int _5862 = fa_cl_ndir + fa_cl_local;\n        for (int ln = 0; ln < _5862; ln++)\n        {\n            int param_16 = ln;\n            int _5875 = fa_cl_light(param_16);\n            bool _5878 = fa_lm.z > 0.5;\n            bool _5884;\n            if (_5878)\n            {\n                int param_17 = _5875;\n                _5884 = fa_light_baked(param_17);\n            }\n            else\n            {\n                _5884 = _5878;\n            }\n            if (_5884)\n            {\n                continue;\n            }\n            int param_18 = _5875;\n            vec3 param_19 = fa_world_pos;\n            vec3 param_20 = _6382;\n            LightSample _5896 = fa_light_shadowed(param_18, param_19, param_20);\n            float _5904 = max(dot(_5787, _5896.direction), 0.0);\n            float _5910 = _5896.attenuation * _5896.shadow;\n            vec3 _5915 = normalize(_5896.direction + _5740);\n            float _5920 = max(dot(_5787, _5915), 0.0);\n            float _5925 = max(dot(_5740, _5915), 0.0);\n            bool _5932;\n            if (fa_light_is_area)\n            {\n                _5932 = !_5840.on;\n            }\n            else\n            {\n                _5932 = fa_light_is_area;\n            }\n            if (_5932)\n            {\n                int param_21 = _5875;\n                vec3 param_22 = fa_world_pos;\n                vec3 param_23 = _5787;\n                vec3 param_24 = _5740;\n                vec3 param_25 = _5817;\n                vec3 param_26 = f0;\n                float param_27 = 1.0;\n                float param_28 = _5798;\n                float param_29 = _5811;\n                float param_30 = _5910;\n                lit += fa_area_shade(param_21, param_22, param_23, param_24, param_25, param_26, param_27, param_28, param_29, param_30);\n            }\n            else\n            {\n                if (fa_light_is_area)\n                {\n                    FaLayers param_31 = _5840;\n                    int param_32 = _5875;\n                    vec3 param_33 = fa_world_pos;\n                    vec3 param_34 = _5787;\n                    vec3 param_35 = _5740;\n                    vec3 param_36 = _5896.direction;\n                    vec3 param_37 = _5817;\n                    vec3 param_38 = f0;\n                    float param_39 = _5798;\n                    float param_40 = _5811;\n                    float param_41 = _5910;\n                    lit += fa_area_layers(param_31, param_32, param_33, param_34, param_35, param_36, param_37, param_38, param_39, param_40, param_41);\n                }\n                else\n                {\n                    if (_5840.on)\n                    {\n                        FaLayers param_42 = _5840;\n                        vec3 param_43 = _5817;\n                        vec3 param_44 = f0;\n                        vec3 param_45 = _5787;\n                        vec3 param_46 = _5740;\n                        vec3 param_47 = _5896.direction;\n                        vec3 param_48 = _5915;\n                        float param_49 = _5904;\n                        float param_50 = _5811;\n                        float param_51 = _5920;\n                        float param_52 = _5925;\n                        float param_53 = _5802;\n                        float param_54 = _5806;\n                        int param_55 = _5875;\n                        lit += (fa_layers_light(param_42, param_43, param_44, param_45, param_46, param_47, param_48, param_49, param_50, param_51, param_52, param_53, param_54) * ((fa_light_rgb(param_55) * fa_light_tint) * _5910));\n                    }\n                    else\n                    {\n                        float _6038 = ((_5920 * _5920) * (_5806 - 1.0)) + 1.0;\n                        int param_56 = _5875;\n                        lit += (((_5817 + (((f0 + ((vec3(1.0) - f0) * pow(1.0 - _5925, 5.0))) * (((_5806 / ((3.1415927410125732421875 * _6038) * _6038)) * (0.5 / max(mix((2.0 * _5904) * _5811, _5904 + _5811, _5802), 9.9999997473787516355514526367188e-05))) * 3.1415927410125732421875)) * step(9.9999997473787516355514526367188e-05, _5904))) * (fa_light_rgb(param_56) * fa_light_tint)) * (_5904 * _5910));\n                    }\n                }\n            }\n        }\n        if (_5840.on)\n        {\n            FaLayers param_57 = _5840;\n            vec3 param_58 = _5787;\n            vec3 param_59 = _5740;\n            vec3 param_60 = f0;\n            float param_61 = _5798;\n            lit += (fa_layers_ibl(param_57, param_58, param_59, param_60, param_61) * _6418);\n        }\n        else\n        {\n            vec3 param_62 = _5787;\n            vec3 param_63 = _5740;\n            vec3 param_64 = f0;\n            float param_65 = _5798;\n            lit += (fa_sky_reflection(param_62, param_63, param_64, param_65) * _6418);\n        }\n        result = lit;\n    }\n    vec3 _6133 = result;\n    vec3 _6134 = _6133 + _6419;\n    result = _6134;\n    vec3 param_66 = _6134;\n    vec3 param_67 = fa_world_pos;\n    result = fa_shadow_debug(param_66, param_67);\n    bool _6143 = fa_mesh_fs_params[7].w > 0.0;\n    bool _6150;\n    if (!_6143)\n    {\n        _6150 = fa_mesh_fs_params[8].y > 0.0;\n    }\n    else\n    {\n        _6150 = _6143;\n    }\n    if (_6150)\n    {\n        vec3 _6159 = fa_world_pos - fa_mesh_fs_params[0].xyz;\n        float _6165 = dot(_6159, fa_mesh_fs_params[9].xyz);\n        bool _6169 = fa_mesh_fs_params[9].w > 0.5;\n        float _6170;\n        if (_6169)\n        {\n            _6170 = _6165;\n        }\n        else\n        {\n            _6170 = length(_6159);\n        }\n        float _6182 = _6170 - fa_mesh_fs_params[8].x;\n        if (_6182 > 0.0)\n        {\n            float _6191 = fa_mesh_fs_params[7].w * _6182;\n            float tau = _6191 * _6191;\n            if (fa_mesh_fs_params[8].y > 0.0)\n            {\n                float _6207;\n                if (_6169)\n                {\n                    _6207 = fa_world_pos.y - (fa_mesh_fs_params[9].y * _6165);\n                }\n                else\n                {\n                    _6207 = fa_mesh_fs_params[0].y;\n                }\n                float _6228 = mix(_6207, fa_world_pos.y, clamp(fa_mesh_fs_params[8].x / _6170, 0.0, 1.0));\n                float _6232 = fa_world_pos.y - _6228;\n                float _6237 = _6228 - fa_mesh_fs_params[8].z;\n                float _6242 = fa_world_pos.y - fa_mesh_fs_params[8].z;\n                bool _6245 = _6237 <= 0.0;\n                bool _6246 = !_6245;\n                bool _6252;\n                if (_6246)\n                {\n                    _6252 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _6252 = _6245;\n                }\n                float _6253;\n                if (_6252)\n                {\n                    _6253 = fa_mesh_fs_params[8].y;\n                }\n                else\n                {\n                    _6253 = fa_mesh_fs_params[8].y * exp(-min(fa_mesh_fs_params[8].w * _6237, 80.0));\n                }\n                bool _6280;\n                if (_6246)\n                {\n                    _6280 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _6280 = _6245;\n                }\n                float _6281;\n                if (_6280)\n                {\n                    _6281 = fa_mesh_fs_params[8].y * _6237;\n                }\n                else\n                {\n                    _6281 = (fa_mesh_fs_params[8].y * (1.0 - exp(-min(fa_mesh_fs_params[8].w * _6237, 80.0)))) / fa_mesh_fs_params[8].w;\n                }\n                bool _6306 = _6242 <= 0.0;\n                bool _6313;\n                if (!_6306)\n                {\n                    _6313 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _6313 = _6306;\n                }\n                float _6314;\n                if (_6313)\n                {\n                    _6314 = fa_mesh_fs_params[8].y * _6242;\n                }\n                else\n                {\n                    _6314 = (fa_mesh_fs_params[8].y * (1.0 - exp(-min(fa_mesh_fs_params[8].w * _6242, 80.0)))) / fa_mesh_fs_params[8].w;\n                }\n                float _6341;\n                if (abs(_6232) < 0.001000000047497451305389404296875)\n                {\n                    _6341 = _6253;\n                }\n                else\n                {\n                    _6341 = (_6314 - _6281) / _6232;\n                }\n                tau += (_6182 * max(_6341, 0.0));\n            }\n            result = mix(result, fa_mesh_fs_params[7].xyz, vec3(clamp(1.0 - exp(-clamp(tau, 0.0, 80.0)), 0.0, 1.0)));\n        }\n    }\n    fa_frag_color = vec4(result, _6414);\n}\n\n",
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
            "size": 384,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_485",
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
            "inst_name": "_2202",
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
      "vs": "#version 430\n\nstruct VertexData\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 color;\n    vec3 object_pos;\n};\n\nuniform vec4 fa_mesh_vs_params[11];\nlayout(location = 0) out vec3 fa_world_pos;\nlayout(location = 1) out vec3 fa_world_normal;\nlayout(location = 2) out vec4 fa_world_tangent;\nlayout(location = 3) out vec2 fa_uv;\nlayout(location = 4) out vec4 fa_vertex_color;\nlayout(location = 5) out float fa_pre_depth;\nlayout(location = 6) out vec3 fa_pre_r0;\nlayout(location = 7) out vec3 fa_pre_r1;\nlayout(location = 8) out vec3 fa_pre_r2;\nlayout(location = 5) in vec4 fa_inst_m0;\nlayout(location = 6) in vec4 fa_inst_m1;\nlayout(location = 7) in vec4 fa_inst_m2;\nlayout(location = 8) in vec4 fa_inst_m3;\nlayout(location = 0) in vec3 fa_position;\nlayout(location = 1) in vec3 fa_normal;\nlayout(location = 3) in vec4 fa_tangent;\nlayout(location = 2) in vec2 fa_texcoord0;\nlayout(location = 4) in vec4 fa_color;\n\nvoid fa_inst_begin()\n{\n}\n\nVertexData fa_vertex_data(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    vec3 _69 = cross(model[1].xyz, model[2].xyz);\n    float _75 = (dot(model[0].xyz, _69) < 0.0) ? (-1.0) : 1.0;\n    return VertexData((model * vec4(position, 1.0)).xyz, (((_69 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _75, vec4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _75), texcoord0 * fa_mesh_vs_params[8].xy, color, position);\n}\n\nvoid fa_prepass_vertex(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    mat4 param = model;\n    vec3 param_1 = position;\n    vec3 param_2 = normal;\n    vec4 param_3 = tangent;\n    vec2 param_4 = texcoord0;\n    vec4 param_5 = color;\n    VertexData _160 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    vec3 _299 = _160.world_pos;\n    mat4 _164 = mat4(fa_mesh_vs_params[4], fa_mesh_vs_params[5], fa_mesh_vs_params[6], fa_mesh_vs_params[7]);\n    vec4 _171 = vec4(_299, 1.0);\n    fa_world_pos = _299;\n    fa_world_normal = _160.world_normal;\n    fa_world_tangent = _160.world_tangent;\n    fa_uv = _160.uv;\n    fa_vertex_color = _160.color;\n    fa_pre_depth = -(_164 * _171).z;\n    fa_pre_r0 = vec3(_164[0].x, _164[1].x, _164[2].x);\n    fa_pre_r1 = vec3(_164[0].y, _164[1].y, _164[2].y);\n    fa_pre_r2 = vec3(_164[0].z, _164[1].z, _164[2].z);\n    gl_Position = mat4(fa_mesh_vs_params[0], fa_mesh_vs_params[1], fa_mesh_vs_params[2], fa_mesh_vs_params[3]) * _171;\n}\n\nvoid main()\n{\n    fa_inst_begin();\n    mat4 param = mat4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3);\n    vec3 param_1 = fa_position;\n    vec3 param_2 = fa_normal;\n    vec4 param_3 = fa_tangent;\n    vec2 param_4 = fa_texcoord0;\n    vec4 param_5 = fa_color;\n    fa_prepass_vertex(param, param_1, param_2, param_3, param_4, param_5);\n}\n\n",
      "fs": "#version 430\n\nstruct SurfaceInput\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 vertex_color;\n    vec3 view_dir;\n    bool front_facing;\n};\n\nstruct Surface\n{\n    vec3 albedo;\n    float alpha;\n    vec3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    vec3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    vec3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    vec3 specular_color;\n};\n\nuniform vec4 fa_mesh_fs_params[24];\nlayout(binding = 0) uniform sampler2D fa_tex_fa_smp;\nlayout(binding = 1) uniform sampler2D fa_normal_tex_fa_smp;\nlayout(binding = 2) uniform sampler2D fa_mr_tex_fa_smp;\nlayout(binding = 3) uniform sampler2D fa_occlusion_tex_fa_smp;\nlayout(binding = 4) uniform sampler2D fa_emissive_tex_fa_smp;\n\nlayout(location = 0) in vec3 fa_world_pos;\nlayout(location = 1) in vec3 fa_world_normal;\nlayout(location = 2) in vec4 fa_world_tangent;\nlayout(location = 3) in vec2 fa_uv;\nlayout(location = 4) in vec4 fa_vertex_color;\nlayout(location = 6) in vec3 fa_pre_r0;\nlayout(location = 7) in vec3 fa_pre_r1;\nlayout(location = 8) in vec3 fa_pre_r2;\nlayout(location = 0) out vec4 fa_frag_color;\nlayout(location = 5) in float fa_pre_depth;\n\nvoid fa_inst_load()\n{\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nvec3 fa_linear_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_tex_fix(inout vec3 c, float mode)\n{\n    if (mode > 1.5)\n    {\n        vec3 param = c;\n        vec3 _195 = fa_linear_to_srgb(param);\n        c = _195;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            vec3 param_1 = c;\n            vec3 _203 = fa_srgb_to_linear(param_1);\n            c = _203;\n        }\n    }\n    return c;\n}\n\nvec3 fa_tangent_normal(SurfaceInput i, vec3 m)\n{\n    vec3 _56;\n    if (i.front_facing)\n    {\n        _56 = i.world_normal;\n    }\n    else\n    {\n        _56 = -i.world_normal;\n    }\n    vec3 _81 = normalize(i.world_tangent.xyz - (_56 * dot(_56, i.world_tangent.xyz)));\n    vec3 _109 = normalize(((_81 * m.x) + ((cross(_56, _81) * i.world_tangent.w) * m.y)) + (_56 * m.z));\n    vec3 _112;\n    if (i.front_facing)\n    {\n        _112 = _109;\n    }\n    else\n    {\n        _112 = -_109;\n    }\n    return _112;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    vec4 base_t = texture(fa_tex_fa_smp, i.uv);\n    float param = fa_mesh_fs_params[6].w;\n    float param_1 = 1.0;\n    vec3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    vec3 _243 = fa_tex_fix(param_2, param_3);\n    vec4 _752 = base_t;\n    _752.x = _243.x;\n    _752.y = _243.y;\n    _752.z = _243.z;\n    base_t = _752;\n    vec4 _259 = (_752 * fa_mesh_fs_params[2]) * i.vertex_color;\n    vec3 _715 = i.world_normal;\n    if (fa_mesh_fs_params[6].z > 0.5)\n    {\n        float param_4 = fa_mesh_fs_params[6].w;\n        float param_5 = 16.0;\n        vec3 param_6 = texture(fa_normal_tex_fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        vec3 _293 = fa_tex_fix(param_6, param_7);\n        vec3 _297 = (_293 * 2.0) - vec3(1.0);\n        vec2 _302 = _297.xy * fa_mesh_fs_params[6].x;\n        vec3 _760 = _297;\n        _760.x = _302.x;\n        _760.y = _302.y;\n        SurfaceInput param_8 = i;\n        vec3 param_9 = _760;\n        _715 = fa_tangent_normal(param_8, param_9);\n    }\n    vec4 mrt = texture(fa_mr_tex_fa_smp, i.uv);\n    float param_10 = fa_mesh_fs_params[6].w;\n    float param_11 = 64.0;\n    vec3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    vec3 _331 = fa_tex_fix(param_12, param_13);\n    vec4 _763 = mrt;\n    _763.x = _331.x;\n    _763.y = _331.y;\n    _763.z = _331.z;\n    mrt = _763;\n    vec4 _361 = texture(fa_occlusion_tex_fa_smp, i.uv);\n    float param_14 = fa_mesh_fs_params[6].w;\n    float param_15 = 256.0;\n    vec3 param_16 = _361.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    vec3 _373 = fa_tex_fix(param_16, param_17);\n    float param_18 = fa_mesh_fs_params[6].w;\n    float param_19 = 4.0;\n    vec3 param_20 = texture(fa_emissive_tex_fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    vec3 _403 = fa_tex_fix(param_20, param_21);\n    float _720 = fa_mesh_fs_params[20].x;\n    float _721 = fa_mesh_fs_params[20].y;\n    float _724 = fa_mesh_fs_params[20].z;\n    float _723 = fa_mesh_fs_params[21].w;\n    float _726 = fa_mesh_fs_params[22].x;\n    if (fa_mesh_fs_params[22].z > 0.5)\n    {\n        if (mod(fa_mesh_fs_params[22].z, 2.0) > 0.5)\n        {\n            _720 *= _373.y;\n            _721 *= _373.z;\n            _723 *= _361.w;\n        }\n        if (fa_mesh_fs_params[22].z > 1.5)\n        {\n            _724 *= mrt.x;\n            _726 *= mrt.w;\n        }\n    }\n    return Surface(_259.xyz, _259.w, _715, clamp(fa_mesh_fs_params[5].x * _331.z, 0.0, 1.0), clamp(fa_mesh_fs_params[5].y * _331.y, 0.0500000007450580596923828125, 1.0), 1.0 + (fa_mesh_fs_params[6].y * (_373.x - 1.0)), fa_mesh_fs_params[3].xyz + (fa_mesh_fs_params[4].xyz * _403), _720, _721, fa_mesh_fs_params[21].xyz, _723, _724, fa_mesh_fs_params[20].w, _726, fa_mesh_fs_params[22].y, fa_mesh_fs_params[23].xyz);\n}\n\nvoid surface(SurfaceInput i, inout Surface s)\n{\n    s.emission += vec3(0.5 + (0.5 * sin(fa_mesh_fs_params[13].x * 3.0)), 0.25 * fract(fa_mesh_fs_params[13].x), 0.0);\n}\n\nvoid main()\n{\n    fa_inst_load();\n    vec3 _626 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _626 = -_626;\n    }\n    vec3 _536 = normalize(fa_mesh_fs_params[0].xyz - fa_world_pos);\n    SurfaceInput param = SurfaceInput(fa_world_pos, _626, fa_world_tangent, fa_uv, fa_vertex_color, _536, gl_FrontFacing);\n    SurfaceInput param_1 = SurfaceInput(fa_world_pos, _626, fa_world_tangent, fa_uv, fa_vertex_color, _536, gl_FrontFacing);\n    Surface param_2 = fa_standard_surface(param);\n    surface(param_1, param_2);\n    vec3 _551 = normalize(param_2.normal);\n    vec3 _566 = normalize(vec3(dot(fa_pre_r0, _551), dot(fa_pre_r1, _551), dot(fa_pre_r2, _551)));\n    float _578 = _566.z;\n    vec2 e = _566.xy / vec2((abs(_566.x) + abs(_566.y)) + abs(_578));\n    if (_578 < 0.0)\n    {\n        e = (vec2(1.0) - abs(e.yx)) * vec2((e.x >= 0.0) ? 1.0 : (-1.0), (e.y >= 0.0) ? 1.0 : (-1.0));\n    }\n    fa_frag_color = vec4(min(fa_pre_depth, 60000.0), e, 1.0);\n}\n\n",
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
            "size": 384,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_125",
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
      "vs": "#version 430\n\nstruct VertexData\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 color;\n    vec3 object_pos;\n};\n\nuniform vec4 fa_mesh_vs_params[11];\nuniform vec4 fa_skin[192];\nlayout(location = 0) out vec3 fa_world_pos;\nlayout(location = 1) out vec3 fa_world_normal;\nlayout(location = 2) out vec4 fa_world_tangent;\nlayout(location = 3) out vec2 fa_uv;\nlayout(location = 4) out vec4 fa_vertex_color;\nlayout(location = 5) out float fa_pre_depth;\nlayout(location = 6) out vec3 fa_pre_r0;\nlayout(location = 7) out vec3 fa_pre_r1;\nlayout(location = 8) out vec3 fa_pre_r2;\nlayout(location = 5) in vec4 fa_inst_m0;\nlayout(location = 6) in vec4 fa_inst_m1;\nlayout(location = 7) in vec4 fa_inst_m2;\nlayout(location = 8) in vec4 fa_inst_m3;\nlayout(location = 9) in vec4 fa_joints;\nlayout(location = 10) in vec4 fa_weights;\nlayout(location = 0) in vec3 fa_position;\nlayout(location = 1) in vec3 fa_normal;\nlayout(location = 3) in vec4 fa_tangent;\nlayout(location = 2) in vec2 fa_texcoord0;\nlayout(location = 4) in vec4 fa_color;\n\nvoid fa_inst_begin()\n{\n}\n\nmat4 fa_skin_matrix(vec4 joints, vec4 weights)\n{\n    vec4 r0 = vec4(0.0);\n    vec4 r1 = vec4(0.0);\n    vec4 r2 = vec4(0.0);\n    for (int i = 0; i < 4; i++)\n    {\n        int _174 = int((joints[i] * 255.0) + 0.5) * 3;\n        r0 += (fa_skin[_174 * 1 + 0] * weights[i]);\n        r1 += (fa_skin[(_174 + 1) * 1 + 0] * weights[i]);\n        r2 += (fa_skin[(_174 + 2) * 1 + 0] * weights[i]);\n    }\n    return mat4(vec4(r0.x, r1.x, r2.x, 0.0), vec4(r0.y, r1.y, r2.y, 0.0), vec4(r0.z, r1.z, r2.z, 0.0), vec4(r0.w, r1.w, r2.w, 1.0));\n}\n\nVertexData fa_vertex_data(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    vec3 _74 = cross(model[1].xyz, model[2].xyz);\n    float _80 = (dot(model[0].xyz, _74) < 0.0) ? (-1.0) : 1.0;\n    return VertexData((model * vec4(position, 1.0)).xyz, (((_74 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _80, vec4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _80), texcoord0 * fa_mesh_vs_params[8].xy, color, position);\n}\n\nvoid fa_prepass_vertex(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    mat4 param = model;\n    vec3 param_1 = position;\n    vec3 param_2 = normal;\n    vec4 param_3 = tangent;\n    vec2 param_4 = texcoord0;\n    vec4 param_5 = color;\n    VertexData _273 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    vec3 _420 = _273.world_pos;\n    mat4 _277 = mat4(fa_mesh_vs_params[4], fa_mesh_vs_params[5], fa_mesh_vs_params[6], fa_mesh_vs_params[7]);\n    vec4 _284 = vec4(_420, 1.0);\n    fa_world_pos = _420;\n    fa_world_normal = _273.world_normal;\n    fa_world_tangent = _273.world_tangent;\n    fa_uv = _273.uv;\n    fa_vertex_color = _273.color;\n    fa_pre_depth = -(_277 * _284).z;\n    fa_pre_r0 = vec3(_277[0].x, _277[1].x, _277[2].x);\n    fa_pre_r1 = vec3(_277[0].y, _277[1].y, _277[2].y);\n    fa_pre_r2 = vec3(_277[0].z, _277[1].z, _277[2].z);\n    gl_Position = mat4(fa_mesh_vs_params[0], fa_mesh_vs_params[1], fa_mesh_vs_params[2], fa_mesh_vs_params[3]) * _284;\n}\n\nvoid main()\n{\n    fa_inst_begin();\n    vec4 param = fa_joints;\n    vec4 param_1 = fa_weights;\n    mat4 param_2 = mat4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3) * fa_skin_matrix(param, param_1);\n    vec3 param_3 = fa_position;\n    vec3 param_4 = fa_normal;\n    vec4 param_5 = fa_tangent;\n    vec2 param_6 = fa_texcoord0;\n    vec4 param_7 = fa_color;\n    fa_prepass_vertex(param_2, param_3, param_4, param_5, param_6, param_7);\n}\n\n",
      "fs": "#version 430\n\nstruct SurfaceInput\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 vertex_color;\n    vec3 view_dir;\n    bool front_facing;\n};\n\nstruct Surface\n{\n    vec3 albedo;\n    float alpha;\n    vec3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    vec3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    vec3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    vec3 specular_color;\n};\n\nuniform vec4 fa_mesh_fs_params[24];\nlayout(binding = 0) uniform sampler2D fa_tex_fa_smp;\nlayout(binding = 1) uniform sampler2D fa_normal_tex_fa_smp;\nlayout(binding = 2) uniform sampler2D fa_mr_tex_fa_smp;\nlayout(binding = 3) uniform sampler2D fa_occlusion_tex_fa_smp;\nlayout(binding = 4) uniform sampler2D fa_emissive_tex_fa_smp;\n\nlayout(location = 0) in vec3 fa_world_pos;\nlayout(location = 1) in vec3 fa_world_normal;\nlayout(location = 2) in vec4 fa_world_tangent;\nlayout(location = 3) in vec2 fa_uv;\nlayout(location = 4) in vec4 fa_vertex_color;\nlayout(location = 6) in vec3 fa_pre_r0;\nlayout(location = 7) in vec3 fa_pre_r1;\nlayout(location = 8) in vec3 fa_pre_r2;\nlayout(location = 0) out vec4 fa_frag_color;\nlayout(location = 5) in float fa_pre_depth;\n\nvoid fa_inst_load()\n{\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nvec3 fa_linear_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_tex_fix(inout vec3 c, float mode)\n{\n    if (mode > 1.5)\n    {\n        vec3 param = c;\n        vec3 _195 = fa_linear_to_srgb(param);\n        c = _195;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            vec3 param_1 = c;\n            vec3 _203 = fa_srgb_to_linear(param_1);\n            c = _203;\n        }\n    }\n    return c;\n}\n\nvec3 fa_tangent_normal(SurfaceInput i, vec3 m)\n{\n    vec3 _56;\n    if (i.front_facing)\n    {\n        _56 = i.world_normal;\n    }\n    else\n    {\n        _56 = -i.world_normal;\n    }\n    vec3 _81 = normalize(i.world_tangent.xyz - (_56 * dot(_56, i.world_tangent.xyz)));\n    vec3 _109 = normalize(((_81 * m.x) + ((cross(_56, _81) * i.world_tangent.w) * m.y)) + (_56 * m.z));\n    vec3 _112;\n    if (i.front_facing)\n    {\n        _112 = _109;\n    }\n    else\n    {\n        _112 = -_109;\n    }\n    return _112;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    vec4 base_t = texture(fa_tex_fa_smp, i.uv);\n    float param = fa_mesh_fs_params[6].w;\n    float param_1 = 1.0;\n    vec3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    vec3 _243 = fa_tex_fix(param_2, param_3);\n    vec4 _752 = base_t;\n    _752.x = _243.x;\n    _752.y = _243.y;\n    _752.z = _243.z;\n    base_t = _752;\n    vec4 _259 = (_752 * fa_mesh_fs_params[2]) * i.vertex_color;\n    vec3 _715 = i.world_normal;\n    if (fa_mesh_fs_params[6].z > 0.5)\n    {\n        float param_4 = fa_mesh_fs_params[6].w;\n        float param_5 = 16.0;\n        vec3 param_6 = texture(fa_normal_tex_fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        vec3 _293 = fa_tex_fix(param_6, param_7);\n        vec3 _297 = (_293 * 2.0) - vec3(1.0);\n        vec2 _302 = _297.xy * fa_mesh_fs_params[6].x;\n        vec3 _760 = _297;\n        _760.x = _302.x;\n        _760.y = _302.y;\n        SurfaceInput param_8 = i;\n        vec3 param_9 = _760;\n        _715 = fa_tangent_normal(param_8, param_9);\n    }\n    vec4 mrt = texture(fa_mr_tex_fa_smp, i.uv);\n    float param_10 = fa_mesh_fs_params[6].w;\n    float param_11 = 64.0;\n    vec3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    vec3 _331 = fa_tex_fix(param_12, param_13);\n    vec4 _763 = mrt;\n    _763.x = _331.x;\n    _763.y = _331.y;\n    _763.z = _331.z;\n    mrt = _763;\n    vec4 _361 = texture(fa_occlusion_tex_fa_smp, i.uv);\n    float param_14 = fa_mesh_fs_params[6].w;\n    float param_15 = 256.0;\n    vec3 param_16 = _361.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    vec3 _373 = fa_tex_fix(param_16, param_17);\n    float param_18 = fa_mesh_fs_params[6].w;\n    float param_19 = 4.0;\n    vec3 param_20 = texture(fa_emissive_tex_fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    vec3 _403 = fa_tex_fix(param_20, param_21);\n    float _720 = fa_mesh_fs_params[20].x;\n    float _721 = fa_mesh_fs_params[20].y;\n    float _724 = fa_mesh_fs_params[20].z;\n    float _723 = fa_mesh_fs_params[21].w;\n    float _726 = fa_mesh_fs_params[22].x;\n    if (fa_mesh_fs_params[22].z > 0.5)\n    {\n        if (mod(fa_mesh_fs_params[22].z, 2.0) > 0.5)\n        {\n            _720 *= _373.y;\n            _721 *= _373.z;\n            _723 *= _361.w;\n        }\n        if (fa_mesh_fs_params[22].z > 1.5)\n        {\n            _724 *= mrt.x;\n            _726 *= mrt.w;\n        }\n    }\n    return Surface(_259.xyz, _259.w, _715, clamp(fa_mesh_fs_params[5].x * _331.z, 0.0, 1.0), clamp(fa_mesh_fs_params[5].y * _331.y, 0.0500000007450580596923828125, 1.0), 1.0 + (fa_mesh_fs_params[6].y * (_373.x - 1.0)), fa_mesh_fs_params[3].xyz + (fa_mesh_fs_params[4].xyz * _403), _720, _721, fa_mesh_fs_params[21].xyz, _723, _724, fa_mesh_fs_params[20].w, _726, fa_mesh_fs_params[22].y, fa_mesh_fs_params[23].xyz);\n}\n\nvoid surface(SurfaceInput i, inout Surface s)\n{\n    s.emission += vec3(0.5 + (0.5 * sin(fa_mesh_fs_params[13].x * 3.0)), 0.25 * fract(fa_mesh_fs_params[13].x), 0.0);\n}\n\nvoid main()\n{\n    fa_inst_load();\n    vec3 _626 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _626 = -_626;\n    }\n    vec3 _536 = normalize(fa_mesh_fs_params[0].xyz - fa_world_pos);\n    SurfaceInput param = SurfaceInput(fa_world_pos, _626, fa_world_tangent, fa_uv, fa_vertex_color, _536, gl_FrontFacing);\n    SurfaceInput param_1 = SurfaceInput(fa_world_pos, _626, fa_world_tangent, fa_uv, fa_vertex_color, _536, gl_FrontFacing);\n    Surface param_2 = fa_standard_surface(param);\n    surface(param_1, param_2);\n    vec3 _551 = normalize(param_2.normal);\n    vec3 _566 = normalize(vec3(dot(fa_pre_r0, _551), dot(fa_pre_r1, _551), dot(fa_pre_r2, _551)));\n    float _578 = _566.z;\n    vec2 e = _566.xy / vec2((abs(_566.x) + abs(_566.y)) + abs(_578));\n    if (_578 < 0.0)\n    {\n        e = (vec2(1.0) - abs(e.yx)) * vec2((e.x >= 0.0) ? 1.0 : (-1.0), (e.y >= 0.0) ? 1.0 : (-1.0));\n    }\n    fa_frag_color = vec4(min(fa_pre_depth, 60000.0), e, 1.0);\n}\n\n",
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
            "size": 384,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_125",
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
    }
  }
}
