{
  "format": "factoria.shader/1",
  "engine": "0.38.0",
  "template": "4f7d190a643df7eea422f9bce37d2bb8920145f92f7e586baf62c54f579868ea",
  "slang": "glsl430",
  "params": [],
  "textures": [],
  "programs": {
    "mesh": {
      "vs": "#version 430\n\nstruct VertexData\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 color;\n    vec3 object_pos;\n};\n\nuniform vec4 fa_mesh_vs_params[11];\nlayout(location = 0) out vec3 fa_world_pos;\nlayout(location = 1) out vec3 fa_world_normal;\nlayout(location = 2) out vec4 fa_world_tangent;\nlayout(location = 3) out vec2 fa_uv;\nlayout(location = 4) out vec4 fa_vertex_color;\nlayout(location = 5) in vec4 fa_inst_m0;\nlayout(location = 6) in vec4 fa_inst_m1;\nlayout(location = 7) in vec4 fa_inst_m2;\nlayout(location = 8) in vec4 fa_inst_m3;\nlayout(location = 0) in vec3 fa_position;\nlayout(location = 1) in vec3 fa_normal;\nlayout(location = 3) in vec4 fa_tangent;\nlayout(location = 2) in vec2 fa_texcoord0;\nlayout(location = 4) in vec4 fa_color;\nlayout(location = 5) out vec3 fa_lm;\n\nvoid fa_inst_begin()\n{\n}\n\nVertexData fa_vertex_data(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    vec3 _69 = cross(model[1].xyz, model[2].xyz);\n    float _75 = (dot(model[0].xyz, _69) < 0.0) ? (-1.0) : 1.0;\n    return VertexData((model * vec4(position, 1.0)).xyz, (((_69 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _75, vec4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _75), texcoord0 * fa_mesh_vs_params[8].xy, color, position);\n}\n\nvoid fa_shade_vertex(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    mat4 param = model;\n    vec3 param_1 = position;\n    vec3 param_2 = normal;\n    vec4 param_3 = tangent;\n    vec2 param_4 = texcoord0;\n    vec4 param_5 = color;\n    VertexData _160 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    vec3 _267 = _160.world_pos;\n    fa_world_pos = _267;\n    fa_world_normal = _160.world_normal;\n    fa_world_tangent = _160.world_tangent;\n    fa_uv = _160.uv;\n    fa_vertex_color = _160.color;\n    gl_Position = mat4(fa_mesh_vs_params[0], fa_mesh_vs_params[1], fa_mesh_vs_params[2], fa_mesh_vs_params[3]) * vec4(_267, 1.0);\n}\n\nvoid main()\n{\n    fa_inst_begin();\n    mat4 param = mat4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3);\n    vec3 param_1 = fa_position;\n    vec3 param_2 = fa_normal;\n    vec4 param_3 = fa_tangent;\n    vec2 param_4 = fa_texcoord0;\n    vec4 param_5 = fa_color;\n    fa_shade_vertex(param, param_1, param_2, param_3, param_4, param_5);\n    fa_lm = vec3(0.0);\n}\n\n",
      "fs": "#version 430\n\nstruct SurfaceInput\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 vertex_color;\n    vec3 view_dir;\n    bool front_facing;\n};\n\nstruct LightSample\n{\n    vec3 direction;\n    vec3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct Surface\n{\n    vec3 albedo;\n    float alpha;\n    vec3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    vec3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    vec3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    vec3 specular_color;\n    float transmission;\n    float thickness;\n    vec3 attenuation_color;\n    float attenuation_distance;\n};\n\nstruct FaLayers\n{\n    bool on;\n    float f90;\n    float keep;\n    float base_scale;\n    float coat;\n    float coat_rough;\n    float coat_alpha;\n    float coat_a2;\n    vec3 nc;\n    float coat_ndv;\n    bool sheen_on;\n    vec3 sheen;\n    float sheen_rough;\n    float sheen_alpha;\n    float sheen_scale;\n    float sheen_e;\n    float aniso;\n    vec3 t;\n    vec3 b;\n    float at;\n    float ab;\n};\n\nconst float _4654[63] = float[](1.0, 1.0, 1.0, 0.4790000021457672119140625, 0.11699999868869781494140625, 0.01200000010430812835693359375, 0.0, 0.0, 0.0, 1.0, 1.0, 1.0, 0.578000009059906005859375, 0.19300000369548797607421875, 0.0350000001490116119384765625, 0.0030000000260770320892333984375, 0.0, 0.0, 1.0, 1.0, 1.0, 0.6740000247955322265625, 0.3459999859333038330078125, 0.1319999992847442626953125, 0.032999999821186065673828125, 0.0040000001899898052215576171875, 0.0, 0.971000015735626220703125, 0.954999983310699462890625, 0.828999996185302734375, 0.63999998569488525390625, 0.42599999904632568359375, 0.24500000476837158203125, 0.115000002086162567138671875, 0.037000000476837158203125, 0.0030000000260770320892333984375, 0.7469999790191650390625, 0.737999975681304931640625, 0.670000016689300537109375, 0.563000023365020751953125, 0.4309999942779541015625, 0.3039999902248382568359375, 0.1940000057220458984375, 0.1019999980926513671875, 0.0309999994933605194091796875, 0.614000022411346435546875, 0.609000027179718017578125, 0.566999971866607666015625, 0.499000012874603271484375, 0.412000000476837158203125, 0.32400000095367431640625, 0.240999996662139892578125, 0.162000000476837158203125, 0.087999999523162841796875, 0.538999974727630615234375, 0.535000026226043701171875, 0.505999982357025146484375, 0.4569999873638153076171875, 0.393999993801116943359375, 0.328999996185302734375, 0.2660000026226043701171875, 0.203999996185302734375, 0.14200000464916229248046875);\n\nuniform vec4 fa_mesh_fs_params[54];\nuniform vec4 fa_shadows[30];\nlayout(binding = 0) uniform sampler2D fa_light_tex_fa_shadow_smp;\nlayout(binding = 1) uniform sampler2D fa_tex_fa_smp;\nlayout(binding = 2) uniform sampler2D fa_normal_tex_fa_smp;\nlayout(binding = 3) uniform sampler2D fa_mr_tex_fa_smp;\nlayout(binding = 4) uniform sampler2D fa_occlusion_tex_fa_smp;\nlayout(binding = 5) uniform sampler2D fa_emissive_tex_fa_smp;\nlayout(binding = 6) uniform sampler2D fa_decal_tex_fa_env_smp;\nlayout(binding = 7) uniform sampler2D fa_lightmap_fa_env_smp;\nlayout(binding = 8) uniform sampler2D fa_probe_atlas_fa_env_smp;\nlayout(binding = 9) uniform sampler2D fa_light_atlas_fa_env_smp;\nlayout(binding = 10) uniform sampler2D fa_screen_tex_fa_shadow_smp;\nlayout(binding = 11) uniform sampler2D fa_shadow_tex_fa_shadow_smp;\n\nlayout(location = 0) in vec3 fa_world_pos;\nlayout(location = 5) in vec3 fa_lm;\nlayout(location = 1) in vec3 fa_world_normal;\nlayout(location = 2) in vec4 fa_world_tangent;\nlayout(location = 3) in vec2 fa_uv;\nlayout(location = 4) in vec4 fa_vertex_color;\nlayout(location = 0) out vec4 fa_frag_color;\nfloat fa_rt_slope;\nvec3 fa_light_tint;\nbool fa_light_is_area;\nint fa_cl_ndir;\nint fa_cl_slot;\nint fa_cl_local;\n\nvoid fa_inst_load()\n{\n}\n\nvec4 fa_light_texel(int t)\n{\n    return texelFetch(fa_light_tex_fa_shadow_smp, ivec2(t & 1023, t >> 10), 0);\n}\n\nvec4 fa_cluster_texel(vec3 world_pos)\n{\n    bool _1435 = fa_mesh_fs_params[19].x < 0.0;\n    bool _1442;\n    if (!_1435)\n    {\n        _1442 = fa_mesh_fs_params[19].w < 1.0;\n    }\n    else\n    {\n        _1442 = _1435;\n    }\n    bool _1450;\n    if (!_1442)\n    {\n        _1450 = fa_mesh_fs_params[18].x < 1.0;\n    }\n    else\n    {\n        _1450 = _1442;\n    }\n    bool _1457;\n    if (!_1450)\n    {\n        _1457 = fa_mesh_fs_params[18].y < 1.0;\n    }\n    else\n    {\n        _1457 = _1450;\n    }\n    bool _1464;\n    if (!_1457)\n    {\n        _1464 = fa_mesh_fs_params[19].y < 1.0;\n    }\n    else\n    {\n        _1464 = _1457;\n    }\n    if (_1464)\n    {\n        return vec4(0.0);\n    }\n    vec4 _1474 = vec4(world_pos, 1.0);\n    float _1480 = dot(fa_mesh_fs_params[16], _1474);\n    if (!(_1480 > 9.9999999747524270787835121154785e-07))\n    {\n        return vec4(0.0);\n    }\n    vec2 _1502 = vec2(dot(fa_mesh_fs_params[14], _1474), dot(fa_mesh_fs_params[15], _1474)) / vec2(_1480);\n    int _1506 = int(fa_mesh_fs_params[18].x);\n    int _1510 = int(fa_mesh_fs_params[18].y);\n    int param = (int(fa_mesh_fs_params[19].x) + (((clamp(int(floor(log2(max(dot(fa_mesh_fs_params[17].xyz, world_pos) + fa_mesh_fs_params[17].w, fa_mesh_fs_params[18].w) / fa_mesh_fs_params[18].w) * fa_mesh_fs_params[18].z)), 0, int(fa_mesh_fs_params[19].y) - 1) * _1510) + clamp(int(floor(((_1502.y * 0.5) + 0.5) * fa_mesh_fs_params[18].y)), 0, _1510 - 1)) * _1506)) + clamp(int(floor(((_1502.x * 0.5) + 0.5) * fa_mesh_fs_params[18].x)), 0, _1506 - 1);\n    return fa_light_texel(param);\n}\n\nivec2 fa_cluster_lookup(vec3 world_pos)\n{\n    vec3 param = world_pos;\n    vec4 _1586 = fa_cluster_texel(param);\n    return ivec2(int(_1586.x), int(_1586.y));\n}\n\nvoid fa_cluster_begin(vec3 world_pos)\n{\n    float _5469 = dot(fa_mesh_fs_params[29].xyz, world_pos) + fa_mesh_fs_params[29].w;\n    float _5472 = fwidth(_5469);\n    bool _5475 = fa_mesh_fs_params[25].y > 0.5;\n    bool _5482;\n    if (!_5475)\n    {\n        _5482 = fa_mesh_fs_params[25].w > 0.5;\n    }\n    else\n    {\n        _5482 = _5475;\n    }\n    if (_5482)\n    {\n        fa_rt_slope = min(1.5 * _5472, 0.100000001490116119384765625 * _5469);\n    }\n    fa_cl_ndir = int(fa_mesh_fs_params[19].z);\n    vec3 param = world_pos;\n    ivec2 _5498 = fa_cluster_lookup(param);\n    fa_cl_slot = _5498.x;\n    fa_cl_local = _5498.y;\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_linear_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvec3 fa_tex_fix(inout vec3 c, float mode)\n{\n    if (mode > 1.5)\n    {\n        vec3 param = c;\n        vec3 _5710 = fa_linear_to_srgb(param);\n        c = _5710;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            vec3 param_1 = c;\n            vec3 _5718 = fa_srgb_to_linear(param_1);\n            c = _5718;\n        }\n    }\n    return c;\n}\n\nvec3 fa_tangent_normal(SurfaceInput i, vec3 m)\n{\n    vec3 _390;\n    if (i.front_facing)\n    {\n        _390 = i.world_normal;\n    }\n    else\n    {\n        _390 = -i.world_normal;\n    }\n    vec3 _414 = normalize(i.world_tangent.xyz - (_390 * dot(_390, i.world_tangent.xyz)));\n    vec3 _441 = normalize(((_414 * m.x) + ((cross(_390, _414) * i.world_tangent.w) * m.y)) + (_390 * m.z));\n    vec3 _444;\n    if (i.front_facing)\n    {\n        _444 = _441;\n    }\n    else\n    {\n        _444 = -_441;\n    }\n    return _444;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    vec4 base_t = texture(fa_tex_fa_smp, i.uv, fa_mesh_fs_params[12].w);\n    float param = fa_mesh_fs_params[6].w;\n    float param_1 = 1.0;\n    vec3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    vec3 _5750 = fa_tex_fix(param_2, param_3);\n    vec4 _7738 = base_t;\n    _7738.x = _5750.x;\n    _7738.y = _5750.y;\n    _7738.z = _5750.z;\n    base_t = _7738;\n    vec4 _5764 = (_7738 * fa_mesh_fs_params[2]) * i.vertex_color;\n    vec3 _7523 = i.world_normal;\n    if (fa_mesh_fs_params[6].z > 0.5)\n    {\n        float param_4 = fa_mesh_fs_params[6].w;\n        float param_5 = 16.0;\n        vec3 param_6 = texture(fa_normal_tex_fa_smp, i.uv, fa_mesh_fs_params[12].w).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        vec3 _5798 = fa_tex_fix(param_6, param_7);\n        vec3 _5801 = (_5798 * 2.0) - vec3(1.0);\n        vec2 _5806 = _5801.xy * fa_mesh_fs_params[6].x;\n        vec3 _7746 = _5801;\n        _7746.x = _5806.x;\n        _7746.y = _5806.y;\n        SurfaceInput param_8 = i;\n        vec3 param_9 = _7746;\n        _7523 = fa_tangent_normal(param_8, param_9);\n    }\n    vec4 mrt = texture(fa_mr_tex_fa_smp, i.uv, fa_mesh_fs_params[12].w);\n    float param_10 = fa_mesh_fs_params[6].w;\n    float param_11 = 64.0;\n    vec3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    vec3 _5836 = fa_tex_fix(param_12, param_13);\n    vec4 _7749 = mrt;\n    _7749.x = _5836.x;\n    _7749.y = _5836.y;\n    _7749.z = _5836.z;\n    mrt = _7749;\n    vec4 _5866 = texture(fa_occlusion_tex_fa_smp, i.uv, fa_mesh_fs_params[12].w);\n    float param_14 = fa_mesh_fs_params[6].w;\n    float param_15 = 256.0;\n    vec3 param_16 = _5866.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    vec3 _5877 = fa_tex_fix(param_16, param_17);\n    float param_18 = fa_mesh_fs_params[6].w;\n    float param_19 = 4.0;\n    vec3 param_20 = texture(fa_emissive_tex_fa_smp, i.uv, fa_mesh_fs_params[12].w).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    vec3 _5909 = fa_tex_fix(param_20, param_21);\n    float _7528 = fa_mesh_fs_params[20].x;\n    float _7529 = fa_mesh_fs_params[20].y;\n    float _7532 = fa_mesh_fs_params[20].z;\n    float _7531 = fa_mesh_fs_params[21].w;\n    float _7534 = fa_mesh_fs_params[22].x;\n    if (fa_mesh_fs_params[22].z > 0.5)\n    {\n        if (mod(fa_mesh_fs_params[22].z, 2.0) > 0.5)\n        {\n            _7528 *= _5877.y;\n            _7529 *= _5877.z;\n            _7531 *= _5866.w;\n        }\n        if (fa_mesh_fs_params[22].z > 1.5)\n        {\n            _7532 *= mrt.x;\n            _7534 *= mrt.w;\n        }\n    }\n    return Surface(_5764.xyz, _5764.w, _7523, clamp(fa_mesh_fs_params[5].x * _5836.z, 0.0, 1.0), clamp(fa_mesh_fs_params[5].y * _5836.y, 0.0500000007450580596923828125, 1.0), 1.0 + (fa_mesh_fs_params[6].y * (_5877.x - 1.0)), fa_mesh_fs_params[3].xyz + (fa_mesh_fs_params[4].xyz * _5909), _7528, _7529, fa_mesh_fs_params[21].xyz, _7531, _7532, fa_mesh_fs_params[20].w, _7534, fa_mesh_fs_params[22].y, fa_mesh_fs_params[23].xyz, fa_mesh_fs_params[30].x, fa_mesh_fs_params[30].y, fa_mesh_fs_params[31].xyz, fa_mesh_fs_params[30].z);\n}\n\nvoid surface(SurfaceInput i, Surface s)\n{\n}\n\nvec4 fa_decal_tile(vec4 rect, vec2 uv, vec2 atlas, vec2 ddx, vec2 ddy)\n{\n    vec2 _1666 = rect.zw - rect.xy;\n    vec2 _1670 = _1666 * atlas;\n    vec2 _1674 = ddx * _1670;\n    vec2 _1678 = ddy * _1670;\n    return textureLod(fa_decal_tex_fa_env_smp, rect.xy + (clamp(uv, vec2(0.0), vec2(1.0)) * _1666), clamp(0.5 * log2(max(max(dot(_1674, _1674), dot(_1678, _1678)), 9.9999999392252902907785028219223e-09)), 0.0, 3.0));\n}\n\nvec3 fa_dc_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_dc_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvoid fa_apply_decals(vec3 world_pos, vec3 geo_normal, inout vec3 albedo, inout vec3 normal)\n{\n    bool _1711 = fa_mesh_fs_params[10].y < 0.5;\n    bool _1718;\n    if (!_1711)\n    {\n        _1718 = fa_mesh_fs_params[10].w < 0.5;\n    }\n    else\n    {\n        _1718 = _1711;\n    }\n    if (_1718)\n    {\n        return;\n    }\n    vec3 _1724 = dFdx(world_pos);\n    vec3 _1727 = dFdy(world_pos);\n    vec3 param = world_pos;\n    vec4 _1731 = fa_cluster_texel(param);\n    int _1735 = int(_1731.w);\n    if (_1735 < 1)\n    {\n        return;\n    }\n    int _1745 = int(fa_mesh_fs_params[10].y + 0.5);\n    int param_1 = _1745;\n    vec4 _1749 = fa_light_texel(param_1);\n    vec2 _1752 = _1749.yz;\n    int _1756 = int(_1749.w);\n    int param_2 = _1745 + 1;\n    vec4 _1761 = fa_light_texel(param_2);\n    float _1762 = _1761.x;\n    int _1768 = int(fa_mesh_fs_params[10].w + 0.5) - 1;\n    int _1772 = int(_1731.z);\n    vec3 _2037;\n    for (int k = 0; k < _1735; k++)\n    {\n        int _1785 = _1772 + k;\n        int param_3 = _1756 + (_1785 >> 2);\n        int _1802 = (_1745 + 2) + (int(fa_light_texel(param_3)[_1785 & 3]) * 7);\n        int param_4 = _1802 + 6;\n        vec4 _1807 = fa_light_texel(param_4);\n        if (((int(_1807.w + 0.5) >> _1768) & 1) == 0)\n        {\n            continue;\n        }\n        int param_5 = _1802;\n        vec4 _1822 = fa_light_texel(param_5);\n        int param_6 = _1802 + 1;\n        vec4 _1827 = fa_light_texel(param_6);\n        int param_7 = _1802 + 2;\n        vec4 _1832 = fa_light_texel(param_7);\n        vec3 _1835 = _1822.xyz;\n        float _1840 = dot(_1835, world_pos) + _1822.w;\n        vec3 _1842 = _1827.xyz;\n        float _1847 = dot(_1842, world_pos) + _1827.w;\n        vec3 _1849 = _1832.xyz;\n        float _1854 = dot(_1849, world_pos) + _1832.w;\n        bool _1859 = abs(_1840) > 0.5;\n        bool _1867;\n        if (!_1859)\n        {\n            _1867 = abs(_1847) > 0.5;\n        }\n        else\n        {\n            _1867 = _1859;\n        }\n        bool _1875;\n        if (!_1867)\n        {\n            _1875 = abs(_1854) > 0.5;\n        }\n        else\n        {\n            _1875 = _1867;\n        }\n        if (_1875)\n        {\n            continue;\n        }\n        float _1890 = clamp(dot(geo_normal, normalize(_1849)) * _1807.z, 0.0, 1.0);\n        if (_1890 <= 0.0)\n        {\n            continue;\n        }\n        float _1910 = (clamp((0.5 - abs(_1854)) * 10.0, 0.0, 1.0) * _1890) * _1807.x;\n        vec2 _1918 = vec2(_1840 + 0.5, 0.5 - _1847);\n        vec2 _1928 = vec2(dot(_1835, _1724), dot(_1842, _1724));\n        vec2 _1938 = vec2(dot(_1835, _1727), dot(_1842, _1727));\n        int param_8 = _1802 + 5;\n        vec4 _1943 = fa_light_texel(param_8);\n        int param_9 = _1802 + 3;\n        vec4 _1948 = fa_light_texel(param_9);\n        int param_10 = _1802 + 4;\n        vec4 _1953 = fa_light_texel(param_10);\n        float tex_a = 1.0;\n        vec3 col = _1943.xyz;\n        bool _1963 = _1948.z > _1948.x;\n        if (_1963)\n        {\n            vec4 param_11 = _1948;\n            vec2 param_12 = _1918;\n            vec2 param_13 = _1752;\n            vec2 param_14 = _1928;\n            vec2 param_15 = _1938;\n            vec4 tx = fa_decal_tile(param_11, param_12, param_13, param_14, param_15);\n            if ((_1762 > 0.5) && (_1762 < 1.5))\n            {\n                vec3 param_16 = tx.xyz;\n                vec3 _1989 = fa_dc_to_linear(param_16);\n                vec4 _7611 = tx;\n                _7611.x = _1989.x;\n                _7611.y = _1989.y;\n                _7611.z = _1989.z;\n                tx = _7611;\n            }\n            col *= tx.xyz;\n            tex_a = tx.w;\n        }\n        albedo = mix(albedo, col, vec3(clamp((_1910 * tex_a) * _1943.w, 0.0, 1.0)));\n        if (_1953.z > _1953.x)\n        {\n            vec4 param_17 = _1953;\n            vec2 param_18 = _1918;\n            vec2 param_19 = _1752;\n            vec2 param_20 = _1928;\n            vec2 param_21 = _1938;\n            vec4 _2033 = fa_decal_tile(param_17, param_18, param_19, param_20, param_21);\n            if (_1762 > 1.5)\n            {\n                vec3 param_22 = _2033.xyz;\n                vec3 _2043 = fa_dc_to_srgb(param_22);\n                _2037 = _2043;\n            }\n            else\n            {\n                _2037 = _2033.xyz;\n            }\n            vec3 _2052 = (_2037 * 2.0) - vec3(1.0);\n            vec2 _2057 = _2052.xy * _1807.y;\n            vec3 _2079 = (normalize(_1835) * _2057.x) + (normalize(_1842) * _2057.y);\n            vec3 _2082 = normalize(normal);\n            normal = normalize(mix(_2082, normalize((_2082 * max(_2052.z, 0.0500000007450580596923828125)) + (_2079 - (_2082 * dot(_2082, _2079)))), vec3(clamp(_1910 * (_1963 ? tex_a : 1.0), 0.0, 1.0))));\n        }\n    }\n}\n\nvec2 fa_atlas_size()\n{\n    return vec2(textureSize(fa_probe_atlas_fa_env_smp, 0));\n}\n\nvec3 fa_probe_sh_coef(vec2 origin, float res, int k)\n{\n    vec3 v = textureLod(fa_probe_atlas_fa_env_smp, (origin + vec2(float(k) + 0.5, res + 2.5)) / fa_atlas_size(), 0.0).xyz;\n    if (fa_mesh_fs_params[41].y > 0.5)\n    {\n        v = ((v * 255.0) - vec3(128.0)) * 0.03149606287479400634765625;\n    }\n    return v;\n}\n\nvec3 fa_sh_eval(vec3 c[9], vec3 n)\n{\n    vec3 _3750 = max((((c[0] * 0.2820948064327239990234375) + (((c[1] * (0.3257350027561187744140625 * n.y)) + (c[2] * (0.3257350027561187744140625 * n.z))) + (c[3] * (0.3257350027561187744140625 * n.x)))) + (((c[4] * ((0.2731371223926544189453125 * n.x) * n.y)) + (c[5] * ((0.2731371223926544189453125 * n.y) * n.z))) + (c[6] * (0.078847892582416534423828125 * (((3.0 * n.z) * n.z) - 1.0))))) + ((c[7] * ((0.2731371223926544189453125 * n.x) * n.z)) + (c[8] * (0.13656856119632720947265625 * ((n.x * n.x) - (n.y * n.y))))), vec3(0.0));\n    return _3750;\n}\n\nvec3 fa_ambient_light(vec3 n)\n{\n    float _4361 = (1.0 - fa_mesh_fs_params[42].w) - fa_mesh_fs_params[47].w;\n    vec3 amb = vec3(0.0);\n    bool _4366 = fa_mesh_fs_params[11].w > 0.5;\n    vec3 c[9];\n    for (int k = 0; k < 9; k++)\n    {\n        c[k] = vec3(0.0);\n    }\n    if (_4361 > 0.0005000000237487256526947021484375)\n    {\n        if (_4366)\n        {\n            for (int k_1 = 0; k_1 < 9; k_1++)\n            {\n                vec2 param = fa_mesh_fs_params[41].zw;\n                float param_1 = 128.0;\n                int param_2 = k_1;\n                c[k_1] = fa_probe_sh_coef(param, param_1, param_2) * _4361;\n            }\n        }\n        else\n        {\n            amb = fa_mesh_fs_params[1].xyz * _4361;\n        }\n    }\n    bool _4416 = fa_mesh_fs_params[42].w > 0.0;\n    if (_4416)\n    {\n        for (int k_2 = 0; k_2 < 9; k_2++)\n        {\n            vec2 param_3 = fa_mesh_fs_params[42].xy;\n            float param_4 = fa_mesh_fs_params[42].z;\n            int param_5 = k_2;\n            c[k_2] += (fa_probe_sh_coef(param_3, param_4, param_5) * fa_mesh_fs_params[42].w);\n        }\n    }\n    bool _4447 = fa_mesh_fs_params[47].w > 0.0;\n    if (_4447)\n    {\n        for (int k_3 = 0; k_3 < 9; k_3++)\n        {\n            vec2 param_6 = fa_mesh_fs_params[47].xy;\n            float param_7 = fa_mesh_fs_params[47].z;\n            int param_8 = k_3;\n            c[k_3] += (fa_probe_sh_coef(param_6, param_7, param_8) * fa_mesh_fs_params[47].w);\n        }\n    }\n    if ((_4366 || _4416) || _4447)\n    {\n        vec3 param_9[9] = c;\n        vec3 param_10 = n;\n        amb += fa_sh_eval(param_9, param_10);\n    }\n    return amb;\n}\n\nvec4 fa_gi_fetch(vec2 texel)\n{\n    return textureLod(fa_probe_atlas_fa_env_smp, texel / fa_atlas_size(), 0.0);\n}\n\nvec2 fa_oct_encode(vec3 d)\n{\n    vec3 _3770 = d / vec3(max((abs(d.x) + abs(d.y)) + abs(d.z), 9.9999999600419720025001879548654e-13));\n    float _3773 = _3770.x;\n    float _3775 = _3770.z;\n    vec2 e = vec2(_3773, _3775);\n    if (_3770.y < 0.0)\n    {\n        e = vec2((1.0 - abs(_3775)) * ((_3773 < 0.0) ? (-1.0) : 1.0), (1.0 - abs(_3773)) * ((_3775 < 0.0) ? (-1.0) : 1.0));\n    }\n    return e;\n}\n\nvec3 fa_gi_grid(int rec, vec3 n, vec3 v, out float cover)\n{\n    cover = 0.0;\n    int param = rec;\n    vec4 _6021 = fa_light_texel(param);\n    int param_1 = rec + 1;\n    vec4 _6026 = fa_light_texel(param_1);\n    int param_2 = rec + 2;\n    vec4 _6031 = fa_light_texel(param_2);\n    int param_3 = rec + 3;\n    vec4 _6036 = fa_light_texel(param_3);\n    bool _6039 = _6036.z < 0.5;\n    bool _6047;\n    if (!_6039)\n    {\n        _6047 = fa_atlas_size().y < 1155.0;\n    }\n    else\n    {\n        _6047 = _6039;\n    }\n    if (_6047)\n    {\n        return vec3(0.0);\n    }\n    float _6054 = max(_6021.w, 9.9999997473787516355514526367188e-05);\n    vec3 _6057 = _6026.xyz;\n    vec3 _6061 = _6021.xyz;\n    vec3 _6065 = (fa_world_pos - _6061) / vec3(_6054);\n    vec3 _6074 = min(_6065 + vec3(0.5), (_6057 - vec3(0.5)) - _6065);\n    float _6083 = min(_6074.x, min(_6074.y, _6074.z));\n    if (!(_6083 > 0.0))\n    {\n        return vec3(0.0);\n    }\n    vec3 _6098 = _6057 - vec3(1.0);\n    vec3 _6099 = clamp(_6065, vec3(0.0), _6098);\n    vec3 _6107 = min(floor(_6099), max(_6057 - vec3(2.0), vec3(0.0)));\n    vec3 _6111 = _6099 - _6107;\n    vec3 _6122 = fa_world_pos + (((n * 0.800000011920928955078125) + (v * 0.20000000298023223876953125)) * (0.20000000298023223876953125 * _6054));\n    int _6127 = int(_6031.y + 0.5);\n    float _6132 = 0.3257350027561187744140625 * n.y;\n    float _6136 = 0.3257350027561187744140625 * n.z;\n    float _6140 = 0.3257350027561187744140625 * n.x;\n    float _6147 = (0.2731371223926544189453125 * n.x) * n.y;\n    float _6154 = (0.2731371223926544189453125 * n.y) * n.z;\n    float _6163 = 0.078847892582416534423828125 * (((3.0 * n.z) * n.z) - 1.0);\n    float _6170 = (0.2731371223926544189453125 * n.x) * n.z;\n    float _6183 = 0.13656856119632720947265625 * ((n.x * n.x) - (n.y * n.y));\n    vec3 acc = vec3(0.0);\n    float wsum = 0.0;\n    int _6190 = 8 + int(_6036.w);\n    float _6217;\n    float _6230;\n    float _6244;\n    for (int k = 0; k < _6190; k++)\n    {\n        float _6203 = float(k & 1);\n        float _6207 = float((k >> 1) & 1);\n        float _6211 = float((k >> 2) & 1);\n        if (_6203 > 0.5)\n        {\n            _6217 = _6111.x;\n        }\n        else\n        {\n            _6217 = 1.0 - _6111.x;\n        }\n        if (_6207 > 0.5)\n        {\n            _6230 = _6111.y;\n        }\n        else\n        {\n            _6230 = 1.0 - _6111.y;\n        }\n        if (_6211 > 0.5)\n        {\n            _6244 = _6111.z;\n        }\n        else\n        {\n            _6244 = 1.0 - _6111.z;\n        }\n        float _6254 = (_6217 * _6230) * _6244;\n        if (!(_6254 > 0.0))\n        {\n            continue;\n        }\n        vec3 _6267 = min(_6107 + vec3(_6203, _6207, _6211), _6098);\n        int _6287 = int(((_6031.x + _6267.x) + (_6026.x * (_6267.y + (_6026.y * _6267.z)))) + 0.5);\n        vec2 _6302 = vec2(float(_6287 % _6127) * 10.0, 1024.0 + (float(_6287 / _6127) * 11.0));\n        vec2 param_4 = _6302 + vec2(9.5, 10.5);\n        vec4 _6310 = fa_gi_fetch(param_4);\n        bool _6313 = _6310.y < 0.5;\n        bool _6322;\n        if (!_6313)\n        {\n            _6322 = _6310.x > _6036.y;\n        }\n        else\n        {\n            _6322 = _6313;\n        }\n        if (_6322)\n        {\n            continue;\n        }\n        vec3 _6334 = _6122 - (_6061 + (_6267 * _6054));\n        float _6337 = length(_6334);\n        vec3 _6343 = _6334 / vec3(max(_6337, 9.9999997473787516355514526367188e-05));\n        float _6353 = max(9.9999997473787516355514526367188e-05, (dot(-_6343, n) + 1.0) * 0.5);\n        float w = _6254 * (_6353 * _6353);\n        vec3 param_5 = _6343;\n        vec2 param_6 = (_6302 + vec2(1.0)) + (((fa_oct_encode(param_5) * 0.5) + vec2(0.5)) * 8.0);\n        vec4 _6372 = fa_gi_fetch(param_6);\n        float _6379 = _6337 / max(_6031.z, 9.9999997473787516355514526367188e-05);\n        float _6382 = _6372.x;\n        if (_6379 > _6382)\n        {\n            float _6395 = max(_6372.y - (_6382 * _6382), 0.0);\n            float _6400 = _6379 - _6382;\n            float _6409 = _6395 / max(_6395 + (_6400 * _6400), 9.9999999600419720025001879548654e-13);\n            w *= ((_6409 * _6409) * _6409);\n        }\n        if (!(w > 0.0))\n        {\n            continue;\n        }\n        vec2 param_7 = _6302 + vec2(0.5, 10.5);\n        vec2 param_8 = _6302 + vec2(1.5, 10.5);\n        vec2 param_9 = _6302 + vec2(2.5, 10.5);\n        vec2 param_10 = _6302 + vec2(3.5, 10.5);\n        vec2 param_11 = _6302 + vec2(4.5, 10.5);\n        vec2 param_12 = _6302 + vec2(5.5, 10.5);\n        vec2 param_13 = _6302 + vec2(6.5, 10.5);\n        vec2 param_14 = _6302 + vec2(7.5, 10.5);\n        vec2 param_15 = _6302 + vec2(8.5, 10.5);\n        acc += ((((((((((fa_gi_fetch(param_7).xyz * 0.2820948064327239990234375) + (fa_gi_fetch(param_8).xyz * _6132)) + (fa_gi_fetch(param_9).xyz * _6136)) + (fa_gi_fetch(param_10).xyz * _6140)) + (fa_gi_fetch(param_11).xyz * _6147)) + (fa_gi_fetch(param_12).xyz * _6154)) + (fa_gi_fetch(param_13).xyz * _6163)) + (fa_gi_fetch(param_14).xyz * _6170)) + (fa_gi_fetch(param_15).xyz * _6183)) * w);\n        wsum += w;\n    }\n    if (!(wsum > 9.9999997473787516355514526367188e-06))\n    {\n        return vec3(0.0);\n    }\n    cover = smoothstep(0.0, 1.0, clamp(_6083 * 2.0, 0.0, 1.0)) * smoothstep(0.0, 0.0199999995529651641845703125, wsum);\n    float _6535;\n    if (fa_mesh_fs_params[52].z > 0.5)\n    {\n        _6535 = _6036.x;\n    }\n    else\n    {\n        _6535 = 1.0;\n    }\n    return max(acc / vec3(wsum), vec3(0.0)) * (_6031.w * _6535);\n}\n\nvec3 fa_gi_light(vec3 n, inout float left)\n{\n    left = 1.0;\n    vec3 acc = vec3(0.0);\n    vec3 _6559 = normalize(fa_mesh_fs_params[0].xyz - fa_world_pos);\n    int _6564 = int(fa_mesh_fs_params[52].x + 0.5);\n    int _6569 = int(fa_mesh_fs_params[52].y + 0.5);\n    float param_3;\n    for (int k = 0; (k < _6569) && (k < 8); k++)\n    {\n        int param = _6564 + (4 * k);\n        vec3 param_1 = n;\n        vec3 param_2 = _6559;\n        vec3 _6594 = fa_gi_grid(param, param_1, param_2, param_3);\n        float _6599 = param_3 * left;\n        acc += (_6594 * _6599);\n        left -= _6599;\n        if (left < 0.001000000047497451305389404296875)\n        {\n            left = 0.0;\n            break;\n        }\n    }\n    return acc;\n}\n\nvec3 fa_realtime_or_ambient(vec3 n)\n{\n    vec3 gi = vec3(0.0);\n    float left = 1.0;\n    if (fa_mesh_fs_params[52].y > 0.5)\n    {\n        vec3 param = n;\n        float param_1;\n        vec3 _6628 = fa_gi_light(param, param_1);\n        left = param_1;\n        gi = _6628;\n    }\n    if (left <= 0.0)\n    {\n        return gi;\n    }\n    vec3 param_2 = n;\n    return gi + (fa_ambient_light(param_2) * left);\n}\n\nvec3 fa_indirect_diffuse(vec3 n)\n{\n    if (fa_lm.z > 0.5)\n    {\n        return textureLod(fa_lightmap_fa_env_smp, fa_lm.xy, 0.0).xyz;\n    }\n    if (fa_mesh_fs_params[53].x > 0.5)\n    {\n        vec4 _6670 = vec4(fa_world_pos, 1.0);\n        vec2 _6689 = vec2(dot(fa_mesh_fs_params[26], _6670), dot(fa_mesh_fs_params[27], _6670)) / vec2(max(dot(fa_mesh_fs_params[28], _6670), 9.9999997473787516355514526367188e-05));\n        float _6698;\n        if (fa_mesh_fs_params[24].y > 0.5)\n        {\n            _6698 = (_6689.y * 0.5) + 0.5;\n        }\n        else\n        {\n            _6698 = 0.5 - (_6689.y * 0.5);\n        }\n        return texelFetch(fa_lightmap_fa_env_smp, clamp(ivec2(vec2((_6689.x * 0.5) + 0.5, _6698) * fa_mesh_fs_params[24].zw), ivec2(0), ivec2(fa_mesh_fs_params[24].zw) - ivec2(1)), 0).xyz;\n    }\n    if (fa_mesh_fs_params[32].w > 0.0)\n    {\n        vec3 c[9];\n        for (int k = 0; k < 9; k++)\n        {\n            c[k] = fa_mesh_fs_params[k * 1 + 32].xyz;\n        }\n        vec3 param = n;\n        vec3 param_1[9] = c;\n        vec3 param_2 = n;\n        return mix(fa_ambient_light(param), fa_sh_eval(param_1, param_2), vec3(clamp(fa_mesh_fs_params[32].w, 0.0, 1.0)));\n    }\n    vec3 param_3 = n;\n    return fa_realtime_or_ambient(param_3);\n}\n\nfloat fa_sheen_albedo(float ndv, float rough)\n{\n    float _4579 = min(sqrt(max(rough - 0.100000001490116119384765625, 0.0) * 1.111111164093017578125) * 6.0, 5.999000072479248046875);\n    float _4587 = min(sqrt(clamp(ndv, 0.0, 1.0)) * 8.0, 7.999000072479248046875);\n    int _4590 = int(_4579);\n    int _4593 = int(_4587);\n    float _4603 = _4587 - float(_4593);\n    int _4658 = (_4590 * 9) + _4593;\n    int _4678 = ((_4590 + 1) * 9) + _4593;\n    return mix(mix(_4654[_4658], _4654[_4658 + 1], _4603), mix(_4654[_4678], _4654[_4678 + 1], _4603), _4579 - float(_4590));\n}\n\nFaLayers fa_layers_setup(SurfaceInput i, Surface s, vec3 n, vec3 v, float metallic, float roughness, inout vec3 f0)\n{\n    bool _7382 = false;\n    float _7383 = 1.0;\n    float _7384 = 1.0;\n    float _7385 = 1.0;\n    float _7386 = 0.0;\n    float _7387 = 0.0;\n    float _7388 = 0.0;\n    float _7389 = 0.0;\n    float _7391 = 1.0;\n    bool _7392 = false;\n    vec3 _7393 = vec3(0.0);\n    float _7394 = 1.0;\n    float _7395 = 1.0;\n    float _7396 = 1.0;\n    float _7397 = 0.0;\n    float _7398 = 0.0;\n    vec3 _7399 = vec3(1.0, 0.0, 0.0);\n    vec3 _7400 = vec3(0.0, 0.0, 1.0);\n    float _7401 = 1.0;\n    float _7402 = 1.0;\n    float _4729 = clamp(s.specular, 0.0, 1.0);\n    float _4733 = clamp(s.ior, 1.0, 3.0);\n    bool _4738 = (_4729 != 1.0) || (_4733 != 1.5);\n    bool _4747;\n    if (!_4738)\n    {\n        _4747 = any(notEqual(s.specular_color, vec3(1.0)));\n    }\n    else\n    {\n        _4747 = _4738;\n    }\n    if (_4747)\n    {\n        float _4755 = (_4733 - 1.0) / (_4733 + 1.0);\n        f0 = mix(min(vec3(_4755 * _4755) * max(s.specular_color, vec3(0.0)), vec3(1.0)) * _4729, s.albedo, vec3(metallic));\n        _7383 = mix(_4729, 1.0, metallic);\n        _7382 = true;\n    }\n    float _4782 = clamp(s.clearcoat, 0.0, 1.0);\n    if (_4782 > 0.0)\n    {\n        float _4790 = clamp(s.clearcoat_roughness, 0.0500000007450580596923828125, 1.0);\n        _7386 = _4782;\n        _7387 = _4790;\n        float _4797 = _4790 * _4790;\n        _7388 = _4797;\n        _7389 = _4797 * _4797;\n        float _4809 = max(dot(i.world_normal, v), 9.9999997473787516355514526367188e-05);\n        _7391 = _4809;\n        _7384 = 1.0 - (_4782 * (0.039999999105930328369140625 + (0.959999978542327880859375 * pow(clamp(1.0 - _4809, 0.0, 1.0), 5.0))));\n        _7382 = true;\n    }\n    vec3 _4828 = max(s.sheen_color, vec3(0.0));\n    float _4837 = max(_4828.x, max(_4828.y, _4828.z));\n    if (_4837 > 0.0)\n    {\n        float _4845 = clamp(s.sheen_roughness, 0.100000001490116119384765625, 1.0);\n        _7392 = true;\n        _7393 = _4828;\n        _7394 = _4845;\n        _7395 = _4845 * _4845;\n        float param = max(dot(n, v), 9.9999997473787516355514526367188e-05);\n        float param_1 = _4845;\n        float _4862 = fa_sheen_albedo(param, param_1);\n        _7397 = _4862;\n        _7396 = 1.0 - min(_4837 * _4862, 1.0);\n        _7382 = true;\n    }\n    _7385 = _7384 * _7396;\n    float _4881 = clamp(s.anisotropy, -1.0, 1.0);\n    if (_4881 != 0.0)\n    {\n        vec3 _4896 = i.world_tangent.xyz - (n * dot(n, i.world_tangent.xyz));\n        vec3 t = _4896;\n        if (dot(_4896, _4896) < 9.9999999392252902907785028219223e-09)\n        {\n            bvec3 _4908 = bvec3(abs(n.y) < 0.9900000095367431640625);\n            t = cross(vec3(_4908.x ? vec3(0.0, 1.0, 0.0).x : vec3(1.0, 0.0, 0.0).x, _4908.y ? vec3(0.0, 1.0, 0.0).y : vec3(1.0, 0.0, 0.0).y, _4908.z ? vec3(0.0, 1.0, 0.0).z : vec3(1.0, 0.0, 0.0).z), n);\n        }\n        vec3 _4912 = t;\n        vec3 _4913 = normalize(_4912);\n        t = _4913;\n        vec3 _4938 = normalize((_4913 * cos(s.anisotropy_rotation)) + ((cross(n, _4913) * ((i.world_tangent.w < 0.0) ? (-1.0) : 1.0)) * sin(s.anisotropy_rotation)));\n        _7399 = _4938;\n        _7400 = cross(n, _4938);\n        float _4948 = roughness * roughness;\n        float _4954 = mix(_4948, 1.0, _4881 * _4881);\n        bool _4956 = _4881 > 0.0;\n        _7401 = _4956 ? _4954 : _4948;\n        _7402 = _4956 ? _4948 : _4954;\n        _7398 = _4881;\n        _7382 = true;\n    }\n    return FaLayers(_7382, _7383, _7384, _7385, _7386, _7387, _7388, _7389, i.world_normal, _7391, _7392, _7393, _7394, _7395, _7396, _7397, _7398, _7399, _7400, _7401, _7402);\n}\n\nvec2 fa_env_brdf(float rough, float ndv)\n{\n    vec4 _4511 = (vec4(-1.0, -0.0274999998509883880615234375, -0.572000026702880859375, 0.02199999988079071044921875) * rough) + vec4(1.0, 0.0425000004470348358154296875, 1.03999996185302734375, -0.039999999105930328369140625);\n    float _4514 = _4511.x;\n    return (vec2(-1.03999996185302734375, 1.03999996185302734375) * ((min(_4514 * _4514, exp2((-9.27999973297119140625) * ndv)) * _4514) + _4511.y)) + _4511.zw;\n}\n\nvec3 fa_probe_level(vec2 origin, float res, int lv, vec2 e)\n{\n    float _3822;\n    if (lv == 0)\n    {\n        _3822 = 0.0;\n    }\n    else\n    {\n        _3822 = res + 2.0;\n    }\n    float _3832;\n    if (lv == 0)\n    {\n        _3832 = 0.0;\n    }\n    else\n    {\n        _3832 = (res - (res / float(1 << max((lv - 1), 0)))) + (2.0 * float(lv - 1));\n    }\n    return textureLod(fa_probe_atlas_fa_env_smp, (((origin + vec2(_3822, _3832)) + vec2(1.0)) + (((e * 0.5) + vec2(0.5)) * (res / float(1 << lv)))) / fa_atlas_size(), 0.0).xyz;\n}\n\nvec3 fa_probe_radiance(vec2 origin, float res, vec3 d, float rough)\n{\n    float _3878;\n    if (res > 64.5)\n    {\n        _3878 = 5.0;\n    }\n    else\n    {\n        _3878 = (res > 32.5) ? 4.0 : 3.0;\n    }\n    float _3893 = clamp(rough, 0.0, 1.0) * (_3878 - 1.0);\n    int _3900 = int(min(floor(_3893), _3878 - 2.0));\n    float _3905 = _3893 - float(_3900);\n    vec3 param = d;\n    vec2 _3909 = fa_oct_encode(param);\n    vec2 param_1 = origin;\n    float param_2 = res;\n    int param_3 = _3900;\n    vec2 param_4 = _3909;\n    vec3 _3919 = fa_probe_level(param_1, param_2, param_3, param_4);\n    if (_3905 < 0.00200000009499490261077880859375)\n    {\n        return _3919;\n    }\n    vec2 param_5 = origin;\n    float param_6 = res;\n    int param_7 = _3900 + 1;\n    vec2 param_8 = _3909;\n    return mix(_3919, fa_probe_level(param_5, param_6, param_7, param_8), vec3(_3905));\n}\n\nvec3 fa_probe_box_dir(vec3 d, vec4 posw, vec4 bx, vec4 by, vec4 bz)\n{\n    if (posw.w < 0.5)\n    {\n        return d;\n    }\n    float _3990 = dot(bx.xyz, fa_world_pos) + bx.w;\n    float _3997 = dot(by.xyz, fa_world_pos) + by.w;\n    float _4004 = dot(bz.xyz, fa_world_pos) + bz.w;\n    float _4010 = dot(bx.xyz, d);\n    float _4014 = dot(by.xyz, d);\n    float _4018 = dot(bz.xyz, d);\n    float _4024;\n    if (_4010 > 9.9999999747524270787835121154785e-07)\n    {\n        _4024 = (1.0 - _3990) / _4010;\n    }\n    else\n    {\n        float _4038;\n        if (_4010 < (-9.9999999747524270787835121154785e-07))\n        {\n            _4038 = ((-1.0) - _3990) / _4010;\n        }\n        else\n        {\n            _4038 = 1000000015047466219876688855040.0;\n        }\n        _4024 = _4038;\n    }\n    float tx = _4024;\n    float _4055;\n    if (_4014 > 9.9999999747524270787835121154785e-07)\n    {\n        _4055 = (1.0 - _3997) / _4014;\n    }\n    else\n    {\n        float _4068;\n        if (_4014 < (-9.9999999747524270787835121154785e-07))\n        {\n            _4068 = ((-1.0) - _3997) / _4014;\n        }\n        else\n        {\n            _4068 = 1000000015047466219876688855040.0;\n        }\n        _4055 = _4068;\n    }\n    float ty = _4055;\n    float _4084;\n    if (_4018 > 9.9999999747524270787835121154785e-07)\n    {\n        _4084 = (1.0 - _4004) / _4018;\n    }\n    else\n    {\n        float _4097;\n        if (_4018 < (-9.9999999747524270787835121154785e-07))\n        {\n            _4097 = ((-1.0) - _4004) / _4018;\n        }\n        else\n        {\n            _4097 = 1000000015047466219876688855040.0;\n        }\n        _4084 = _4097;\n    }\n    float _4109 = tx;\n    float _4112 = (_4109 > 0.0) ? _4109 : 1000000015047466219876688855040.0;\n    tx = _4112;\n    float _4113 = ty;\n    float _4116 = (_4113 > 0.0) ? _4113 : 1000000015047466219876688855040.0;\n    ty = _4116;\n    float _4126 = min(_4112, min(_4116, (_4084 > 0.0) ? _4084 : 1000000015047466219876688855040.0));\n    if (_4126 > 100000001504746621987668885504.0)\n    {\n        return d;\n    }\n    vec3 _4142 = (fa_world_pos + (d * _4126)) - posw.xyz;\n    vec3 _4147;\n    if (dot(_4142, _4142) > 1.0000000133514319600180897396058e-10)\n    {\n        _4147 = normalize(_4142);\n    }\n    else\n    {\n        _4147 = d;\n    }\n    return _4147;\n}\n\nvec3 fa_probe_environment(vec4 tile, vec4 posw, vec4 bx, vec4 by, vec4 bz, inout vec3 d, float rough)\n{\n    vec3 param = d;\n    vec4 param_1 = posw;\n    vec4 param_2 = bx;\n    vec4 param_3 = by;\n    vec4 param_4 = bz;\n    d = fa_probe_box_dir(param, param_1, param_2, param_3, param_4);\n    vec2 param_5 = tile.xy;\n    float param_6 = tile.z;\n    vec3 param_7 = d;\n    float param_8 = rough;\n    return fa_probe_radiance(param_5, param_6, param_7, param_8);\n}\n\nvec3 fa_environment(vec3 d, float rough)\n{\n    float _4193 = (1.0 - fa_mesh_fs_params[42].w) - fa_mesh_fs_params[47].w;\n    vec3 outc = vec3(0.0);\n    if (_4193 > 0.0005000000237487256526947021484375)\n    {\n        vec3 base;\n        if (fa_mesh_fs_params[11].w > 0.5)\n        {\n            vec2 param = fa_mesh_fs_params[41].zw;\n            float param_1 = 128.0;\n            vec3 param_2 = d;\n            float param_3 = rough;\n            base = fa_probe_radiance(param, param_1, param_2, param_3);\n        }\n        else\n        {\n            float _4221 = rough * rough;\n            float _4252 = 0.60000002384185791015625 * _4221;\n            base = mix(mix(fa_mesh_fs_params[12].xyz * 0.550000011920928955078125, mix(fa_mesh_fs_params[12].xyz, fa_mesh_fs_params[11].xyz, vec3(pow(clamp(d.y * (1.0 - (0.699999988079071044921875 * _4221)), 0.0, 1.0), 0.550000011920928955078125))), vec3(smoothstep((-0.0500000007450580596923828125) - _4252, 0.0500000007450580596923828125 + _4252, d.y))), ((fa_mesh_fs_params[11].xyz + fa_mesh_fs_params[12].xyz) * 0.5) * 0.800000011920928955078125, vec3(_4221 * 0.60000002384185791015625));\n        }\n        outc = base * _4193;\n    }\n    if (fa_mesh_fs_params[42].w > 0.0)\n    {\n        vec4 param_4 = fa_mesh_fs_params[42];\n        vec4 param_5 = fa_mesh_fs_params[43];\n        vec4 param_6 = fa_mesh_fs_params[44];\n        vec4 param_7 = fa_mesh_fs_params[45];\n        vec4 param_8 = fa_mesh_fs_params[46];\n        vec3 param_9 = d;\n        float param_10 = rough;\n        vec3 _4311 = fa_probe_environment(param_4, param_5, param_6, param_7, param_8, param_9, param_10);\n        outc += (_4311 * fa_mesh_fs_params[42].w);\n    }\n    if (fa_mesh_fs_params[47].w > 0.0)\n    {\n        vec4 param_11 = fa_mesh_fs_params[47];\n        vec4 param_12 = fa_mesh_fs_params[48];\n        vec4 param_13 = fa_mesh_fs_params[49];\n        vec4 param_14 = fa_mesh_fs_params[50];\n        vec4 param_15 = fa_mesh_fs_params[51];\n        vec3 param_16 = d;\n        float param_17 = rough;\n        vec3 _4343 = fa_probe_environment(param_11, param_12, param_13, param_14, param_15, param_16, param_17);\n        outc += (_4343 * fa_mesh_fs_params[47].w);\n    }\n    return outc;\n}\n\nvec3 fa_layers_ibl(FaLayers L, vec3 n, vec3 v, vec3 f0, float roughness, float occlusion)\n{\n    vec3 rn = n;\n    if (L.aniso != 0.0)\n    {\n        vec3 _4989;\n        if (L.aniso >= 0.0)\n        {\n            _4989 = L.b;\n        }\n        else\n        {\n            _4989 = L.t;\n        }\n        rn = normalize(mix(n, cross(cross(_4989, v), _4989), vec3(abs(L.aniso) * smoothstep(0.0, 0.25, roughness))));\n    }\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05);\n    vec2 _5025 = fa_env_brdf(param, param_1);\n    vec3 param_2 = reflect(-v, rn);\n    float param_3 = roughness;\n    vec3 result = (fa_environment(param_2, param_3) * ((f0 * _5025.x) + (vec3(L.f90) * _5025.y))) * L.base_scale;\n    if (L.sheen_on)\n    {\n        vec3 param_4 = n;\n        float param_5 = L.sheen_rough;\n        result += ((L.sheen * (L.sheen_e * L.keep)) * fa_environment(param_4, param_5));\n    }\n    result *= occlusion;\n    if (L.coat > 0.0)\n    {\n        float param_6 = L.coat_rough;\n        float param_7 = L.coat_ndv;\n        vec2 _5083 = fa_env_brdf(param_6, param_7);\n        vec3 param_8 = reflect(-v, L.nc);\n        float param_9 = L.coat_rough;\n        result += (fa_environment(param_8, param_9) * (L.coat * ((0.039999999105930328369140625 * _5083.x) + _5083.y)));\n    }\n    return result;\n}\n\nvec3 fa_sky_reflection(vec3 n, vec3 v, vec3 f0, float roughness)\n{\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05);\n    vec2 _4553 = fa_env_brdf(param, param_1);\n    vec3 param_2 = reflect(-v, n);\n    float param_3 = roughness;\n    return fa_environment(param_2, param_3) * ((f0 * _4553.x) + vec3(_4553.y));\n}\n\nvec3 fa_sky_light(SurfaceInput i, Surface s)\n{\n    float _5112 = clamp(s.metallic, 0.0, 1.0);\n    float _5116 = clamp(s.roughness, 0.0500000007450580596923828125, 1.0);\n    vec3 _5123 = mix(vec3(0.039999999105930328369140625), s.albedo, vec3(_5112));\n    vec3 f0 = _5123;\n    vec3 _5127 = normalize(s.normal);\n    SurfaceInput param = i;\n    Surface param_1 = s;\n    vec3 param_2 = _5127;\n    vec3 param_3 = i.view_dir;\n    float param_4 = _5112;\n    float param_5 = _5116;\n    vec3 param_6 = _5123;\n    FaLayers _5144 = fa_layers_setup(param, param_1, param_2, param_3, param_4, param_5, param_6);\n    f0 = param_6;\n    if (_5144.on)\n    {\n        FaLayers param_7 = _5144;\n        vec3 param_8 = _5127;\n        vec3 param_9 = i.view_dir;\n        vec3 param_10 = f0;\n        float param_11 = _5116;\n        float param_12 = s.occlusion;\n        return fa_layers_ibl(param_7, param_8, param_9, param_10, param_11, param_12);\n    }\n    vec3 param_13 = _5127;\n    vec3 param_14 = i.view_dir;\n    vec3 param_15 = f0;\n    float param_16 = _5116;\n    return fa_sky_reflection(param_13, param_14, param_15, param_16) * s.occlusion;\n}\n\nvec3 ambient(SurfaceInput i, Surface s, vec3 ambientColor)\n{\n    SurfaceInput param = i;\n    Surface param_1 = s;\n    return fa_sky_light(param, param_1);\n}\n\nint fa_cluster_index(int slot, int n)\n{\n    int param = (int(fa_mesh_fs_params[19].x) + int(fa_mesh_fs_params[19].w)) + ((slot + n) >> 2);\n    vec4 t = fa_light_texel(param);\n    return int(t[(slot + n) & 3]);\n}\n\nint fa_cl_light(int n)\n{\n    if (n < fa_cl_ndir)\n    {\n        return n;\n    }\n    int param = fa_cl_slot;\n    int param_1 = n - fa_cl_ndir;\n    return fa_cluster_index(param, param_1);\n}\n\nint fa_light_base(int li)\n{\n    return li * ((fa_mesh_fs_params[1].w > 4.5) ? 8 : 4);\n}\n\nbool fa_light_baked(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 3;\n    return fa_light_texel(param_1).w > 0.5;\n}\n\nfloat fa_baked_keep(int li)\n{\n    float _5439;\n    if (fa_lm.z > 0.5)\n    {\n        _5439 = 0.0;\n    }\n    else\n    {\n        _5439 = 1.0 - clamp(fa_mesh_fs_params[32].w, 0.0, 1.0);\n    }\n    bool _5450 = _5439 < 1.0;\n    bool _5456;\n    if (_5450)\n    {\n        int param = li;\n        _5456 = fa_light_baked(param);\n    }\n    else\n    {\n        _5456 = _5450;\n    }\n    return _5456 ? _5439 : 1.0;\n}\n\nfloat fa_light_type(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 1;\n    return fa_light_texel(param_1).w;\n}\n\nvec3 fa_area_point(vec3 c, vec3 axis, vec3 ru, vec3 uu, float hx, float hy, float shape, vec3 p, vec3 r)\n{\n    bool _685 = dot(r, r) > 0.5;\n    if (shape > 1.5)\n    {\n        vec3 _698 = (c - (ru * hx)) - p;\n        vec3 _704 = ru * (2.0 * hx);\n        float _710 = max(dot(_704, _704), 9.9999999392252902907785028219223e-09);\n        float _714 = dot(_698, _704);\n        float t = clamp((-_714) / _710, 0.0, 1.0);\n        if (_685)\n        {\n            float _729 = dot(r, _704);\n            float _735 = _710 - (_729 * _729);\n            if (abs(_735) > (9.9999997473787516355514526367188e-06 * _710))\n            {\n                t = clamp(((dot(r, _698) * _729) - _714) / _735, 0.0, 1.0);\n            }\n        }\n        return (p + _698) + (_704 * t);\n    }\n    vec3 q = p;\n    float _767 = dot(r, axis);\n    bool _775;\n    if (_685)\n    {\n        _775 = abs(_767) > 9.9999997473787516355514526367188e-05;\n    }\n    else\n    {\n        _775 = _685;\n    }\n    if (_775)\n    {\n        float _785 = dot(c - p, axis) / _767;\n        if (_785 > 0.0)\n        {\n            q = p + (r * _785);\n        }\n    }\n    vec3 _798 = q - c;\n    vec2 xy = vec2(dot(_798, ru), dot(_798, uu));\n    if (shape > 0.5)\n    {\n        float _813 = length(xy);\n        if (_813 > hx)\n        {\n            xy *= (hx / _813);\n        }\n    }\n    else\n    {\n        xy = clamp(xy, vec2(-hx, -hy), vec2(hx, hy));\n    }\n    return (c + (ru * xy.x)) + (uu * xy.y);\n}\n\nvec4 fa_atlas_fetch(vec2 texel)\n{\n    return textureLod(fa_light_atlas_fa_env_smp, texel / vec2(textureSize(fa_light_atlas_fa_env_smp, 0)), 0.0);\n}\n\nvec3 fa_cookie_sample(vec2 tile_origin, vec2 uv)\n{\n    vec2 param = (tile_origin + vec2(1.0)) + (clamp(uv, vec2(0.0), vec2(1.0)) * 254.0);\n    return fa_atlas_fetch(param).xyz;\n}\n\nfloat fa_ies_sample(vec2 tile_origin, vec3 d, vec3 axis, vec3 right, vec3 up)\n{\n    float _605 = dot(d, right);\n    float _609 = dot(d, up);\n    float _620;\n    if (((_605 * _605) + (_609 * _609)) > 1.0000000133514319600180897396058e-10)\n    {\n        _620 = atan(_609, _605) * 0.15915493667125701904296875;\n    }\n    else\n    {\n        _620 = 0.0;\n    }\n    vec2 param = tile_origin + vec2(1.0 + ((_620 - floor(_620)) * 64.0), 1.0 + (acos(clamp(dot(d, axis), -1.0, 1.0)) * 10.18591594696044921875));\n    return fa_atlas_fetch(param).x;\n}\n\nint fa_cube_face(vec3 d)\n{\n    vec3 _456 = abs(d);\n    float _458 = _456.x;\n    float _460 = _456.y;\n    bool _461 = _458 >= _460;\n    bool _469;\n    if (_461)\n    {\n        _469 = _458 >= _456.z;\n    }\n    else\n    {\n        _469 = _461;\n    }\n    int _470;\n    if (_469)\n    {\n        _470 = (d.x > 0.0) ? 0 : 1;\n    }\n    else\n    {\n        int _484;\n        if (_460 >= _456.z)\n        {\n            _484 = (d.y > 0.0) ? 2 : 3;\n        }\n        else\n        {\n            _484 = (d.z > 0.0) ? 4 : 5;\n        }\n        _470 = _484;\n    }\n    return _470;\n}\n\nvoid fa_cube_face_basis(int f, out vec3 fwd, out vec3 up)\n{\n    if (f == 0)\n    {\n        fwd = vec3(1.0, 0.0, 0.0);\n        up = vec3(0.0, 1.0, 0.0);\n    }\n    else\n    {\n        if (f == 1)\n        {\n            fwd = vec3(-1.0, 0.0, 0.0);\n            up = vec3(0.0, 1.0, 0.0);\n        }\n        else\n        {\n            if (f == 2)\n            {\n                fwd = vec3(0.0, 1.0, 0.0);\n                up = vec3(0.0, 0.0, 1.0);\n            }\n            else\n            {\n                if (f == 3)\n                {\n                    fwd = vec3(0.0, -1.0, 0.0);\n                    up = vec3(0.0, 0.0, -1.0);\n                }\n                else\n                {\n                    if (f == 4)\n                    {\n                        fwd = vec3(0.0, 0.0, 1.0);\n                        up = vec3(0.0, 1.0, 0.0);\n                    }\n                    else\n                    {\n                        fwd = vec3(0.0, 0.0, -1.0);\n                        up = vec3(0.0, 1.0, 0.0);\n                    }\n                }\n            }\n        }\n    }\n}\n\nLightSample fa_light_sample_n(int li, vec3 world_pos, vec3 n)\n{\n    int param = li;\n    int _851 = fa_light_base(param);\n    bool _855 = fa_mesh_fs_params[1].w > 4.5;\n    int param_1 = _851;\n    vec4 _859 = fa_light_texel(param_1);\n    int param_2 = _851 + 1;\n    vec4 _864 = fa_light_texel(param_2);\n    float _867 = _864.w;\n    float atten = 1.0;\n    float dist = 0.0;\n    fa_light_tint = vec3(1.0);\n    bool _879 = _855 && (_867 > 2.5);\n    fa_light_is_area = _879;\n    bool _881 = _867 < 0.5;\n    vec3 l;\n    if (_881)\n    {\n        l = normalize(_859.xyz);\n        if (_855)\n        {\n            int param_3 = _851 + 6;\n            vec4 _895 = fa_light_texel(param_3);\n            if (_895.z > 0.5)\n            {\n                int param_4 = _851 + 4;\n                vec4 _905 = fa_light_texel(param_4);\n                int param_5 = _851 + 5;\n                vec4 _910 = fa_light_texel(param_5);\n                vec2 param_6 = _895.xy;\n                vec2 param_7 = fract(vec2(dot(world_pos, _905.xyz) * _905.w, (-dot(world_pos, _910.xyz)) * _910.w) + vec2(0.5));\n                fa_light_tint = fa_cookie_sample(param_6, param_7);\n            }\n        }\n    }\n    else\n    {\n        vec3 _940 = _859.xyz;\n        vec3 _942 = _940 - world_pos;\n        vec3 to_light = _942;\n        float _945 = length(_942);\n        float reach = _945;\n        bool front = true;\n        if (_879)\n        {\n            int param_8 = _851 + 7;\n            reach = max(_945 - fa_light_texel(param_8).w, 0.0);\n            int param_9 = _851 + 4;\n            vec4 _969 = fa_light_texel(param_9);\n            int param_10 = _851 + 5;\n            vec4 _974 = fa_light_texel(param_10);\n            int param_11 = _851 + 6;\n            vec4 _979 = fa_light_texel(param_11);\n            float _980 = _979.w;\n            int param_12 = _851 + 2;\n            vec3 _987 = normalize(fa_light_texel(param_12).xyz);\n            bool _989 = _980 > 1.5;\n            bool _997;\n            if (!_989)\n            {\n                _997 = dot(_987, to_light) < 0.0;\n            }\n            else\n            {\n                _997 = _989;\n            }\n            front = _997;\n            vec3 r = vec3(0.0);\n            vec3 _1006 = fa_mesh_fs_params[0].xyz - world_pos;\n            bool _1010 = dot(n, n) > 0.5;\n            bool _1018;\n            if (_1010)\n            {\n                _1018 = dot(_1006, _1006) > 9.9999999600419720025001879548654e-13;\n            }\n            else\n            {\n                _1018 = _1010;\n            }\n            if (_1018)\n            {\n                r = reflect(-normalize(_1006), normalize(n));\n            }\n            vec3 param_13 = _940;\n            vec3 param_14 = _987;\n            vec3 param_15 = _969.xyz;\n            vec3 param_16 = _974.xyz;\n            float param_17 = _969.w;\n            float param_18 = _974.w;\n            float param_19 = _980;\n            vec3 param_20 = world_pos;\n            vec3 param_21 = r;\n            to_light = fa_area_point(param_13, param_14, param_15, param_16, param_17, param_18, param_19, param_20, param_21) - world_pos;\n        }\n        float _1054 = length(to_light);\n        dist = _1054;\n        l = to_light / vec3(max(_1054, 9.9999997473787516355514526367188e-05));\n        float _1068 = reach / max(_859.w, 0.001000000047497451305389404296875);\n        float _1074 = clamp(1.0 - (_1068 * _1068), 0.0, 1.0);\n        float _1076;\n        if (front)\n        {\n            _1076 = _1074 * _1074;\n        }\n        else\n        {\n            _1076 = 0.0;\n        }\n        atten = _1076;\n        bool _1087 = _867 < 2.5;\n        if ((_867 > 1.5) && _1087)\n        {\n            int param_22 = _851 + 2;\n            vec4 _1095 = fa_light_texel(param_22);\n            float _1105 = _1095.w;\n            int param_23 = _851 + 3;\n            vec4 _1110 = fa_light_texel(param_23);\n            float _1111 = _1110.x;\n            float cos_inner = _1111;\n            if (_1111 > 1.5)\n            {\n                cos_inner = mix(_1105, 1.0, 0.25);\n            }\n            atten *= smoothstep(_1105, cos_inner, dot(-l, normalize(_1095.xyz)));\n        }\n        if (_855 && (_867 < 1.5))\n        {\n            int param_24 = _851 + 6;\n            vec4 _1135 = fa_light_texel(param_24);\n            if (_1135.z > 0.5)\n            {\n                vec3 _1143 = -to_light;\n                int param_25 = _851 + 4;\n                int param_26 = _851 + 5;\n                vec3 _1157 = fa_light_texel(param_25).xyz;\n                vec3 _1161 = fa_light_texel(param_26).xyz;\n                vec3 _1170 = vec3(dot(_1143, _1157), dot(_1143, _1161), dot(_1143, cross(_1157, _1161)));\n                vec3 param_27 = _1170;\n                int _1174 = fa_cube_face(param_27);\n                int param_28 = _1174;\n                vec3 param_29;\n                vec3 param_30;\n                fa_cube_face_basis(param_28, param_29, param_30);\n                vec2 _1201 = vec2(dot(_1170, cross(param_29, param_30)), dot(_1170, param_30)) / vec2(max(dot(_1170, param_29), 9.9999997473787516355514526367188e-05));\n                int _1205 = _1174 / 3;\n                vec2 param_31 = _1135.xy + (vec2(float(_1174 - (_1205 * 3)), float(_1205)) * 256.0);\n                vec2 param_32 = vec2(0.5 + (0.5 * _1201.x), 0.5 - (0.5 * _1201.y));\n                fa_light_tint = fa_cookie_sample(param_31, param_32);\n            }\n            int param_33 = _851 + 7;\n            vec4 _1235 = fa_light_texel(param_33);\n            if (_1235.z > 0.5)\n            {\n                int param_34 = _851 + 2;\n                int param_35 = _851 + 4;\n                int param_36 = _851 + 5;\n                vec2 param_37 = _1235.xy;\n                vec3 param_38 = -l;\n                vec3 param_39 = normalize(fa_light_texel(param_34).xyz);\n                vec3 param_40 = fa_light_texel(param_35).xyz;\n                vec3 param_41 = fa_light_texel(param_36).xyz;\n                atten *= fa_ies_sample(param_37, param_38, param_39, param_40, param_41);\n            }\n        }\n        else\n        {\n            if (_855 && _1087)\n            {\n                int param_42 = _851 + 6;\n                vec4 _1282 = fa_light_texel(param_42);\n                int param_43 = _851 + 7;\n                vec4 _1287 = fa_light_texel(param_43);\n                bool _1290 = _1282.z > 0.5;\n                bool _1297;\n                if (!_1290)\n                {\n                    _1297 = _1287.z > 0.5;\n                }\n                else\n                {\n                    _1297 = _1290;\n                }\n                if (_1297)\n                {\n                    int param_44 = _851 + 2;\n                    vec4 _1304 = fa_light_texel(param_44);\n                    vec3 _1308 = normalize(_1304.xyz);\n                    int param_45 = _851 + 4;\n                    vec4 _1313 = fa_light_texel(param_45);\n                    int param_46 = _851 + 5;\n                    vec4 _1318 = fa_light_texel(param_46);\n                    if (_1290)\n                    {\n                        vec3 _1326 = -to_light;\n                        float _1333 = _1304.w;\n                        float _1349 = 0.5 / max(dot(_1326, _1308) * (sqrt(max(1.0 - (_1333 * _1333), 0.0)) / max(_1333, 0.001000000047497451305389404296875)), 9.9999997473787516355514526367188e-05);\n                        vec2 param_47 = _1282.xy;\n                        vec2 param_48 = vec2(0.5 + (dot(_1326, _1313.xyz) * _1349), 0.5 - (dot(_1326, _1318.xyz) * _1349));\n                        fa_light_tint = fa_cookie_sample(param_47, param_48);\n                    }\n                    if (_1287.z > 0.5)\n                    {\n                        vec2 param_49 = _1287.xy;\n                        vec3 param_50 = -l;\n                        vec3 param_51 = _1308;\n                        vec3 param_52 = _1313.xyz;\n                        vec3 param_53 = _1318.xyz;\n                        atten *= fa_ies_sample(param_49, param_50, param_51, param_52, param_53);\n                    }\n                }\n            }\n        }\n    }\n    vec3 _7370 = _864.xyz * atten;\n    if (_855)\n    {\n        _7370 *= fa_light_tint;\n    }\n    int _1417;\n    if (_881)\n    {\n        _1417 = 0;\n    }\n    else\n    {\n        _1417 = ((_867 > 1.5) && (_867 < 2.5)) ? 2 : 1;\n    }\n    return LightSample(l, _7370, atten, 1.0, dist, _1417);\n}\n\nfloat fa_shadow_depth(inout vec2 uv, vec4 rect)\n{\n    uv = clamp(uv, rect.xy, rect.zw);\n    return textureLod(fa_shadow_tex_fa_shadow_smp, uv, 0.0).x;\n}\n\nfloat fa_shadow_fetch(vec2 uv, vec4 rect, vec3 conv)\n{\n    vec2 param = uv;\n    vec4 param_1 = rect;\n    float _2206 = fa_shadow_depth(param, param_1);\n    float _2210;\n    if (conv.x < 0.5)\n    {\n        _2210 = _2206;\n    }\n    else\n    {\n        _2210 = (conv.y * conv.z) / (conv.z - (_2206 * (conv.z - conv.y)));\n    }\n    return _2210;\n}\n\nfloat fa_shadow_noise()\n{\n    return fract(52.98291778564453125 * fract(dot(gl_FragCoord.xy, vec2(0.067110560834407806396484375, 0.005837149918079376220703125))));\n}\n\nvec2 fa_shadow_vogel_turn(vec2 d)\n{\n    return vec2((d.x * (-0.737368881702423095703125)) - (d.y * 0.675490319728851318359375), (d.y * (-0.737368881702423095703125)) + (d.x * 0.675490319728851318359375));\n}\n\nfloat fa_shadow_filter(vec2 uv, vec4 rect, float zr, float texel_m, float unit, float reach, float plane, vec3 conv, int mode, float k)\n{\n    if (mode == 1)\n    {\n        vec2 param = uv;\n        vec4 param_1 = rect;\n        vec3 param_2 = conv;\n        return float(zr <= fa_shadow_fetch(param, param_1, param_2));\n    }\n    float _2256 = fa_shadow_noise() * 6.283185482025146484375;\n    vec2 _2262 = vec2(cos(_2256), sin(_2256));\n    vec2 dir = _2262;\n    float radius = 1.5;\n    if (mode == 2)\n    {\n        float _2271;\n        if (k < 0.0)\n        {\n            _2271 = (-k) / max(zr, 0.100000001490116119384765625);\n        }\n        else\n        {\n            _2271 = k;\n        }\n        float _2290 = clamp((_2271 * reach) / texel_m, 3.0, 12.0);\n        float sum = 0.0;\n        float cnt = 0.0;\n        for (int i = 0; i < 16; i++)\n        {\n            float _2309 = sqrt((float(i) + 0.5) * 0.0625) * _2290;\n            vec2 param_3 = uv + (dir * (fa_shadows[26].zw * _2309));\n            vec4 param_4 = rect;\n            vec3 param_5 = conv;\n            float _2323 = fa_shadow_fetch(param_3, param_4, param_5);\n            if (_2323 < (zr - (_2309 * plane)))\n            {\n                sum += _2323;\n                cnt += 1.0;\n            }\n            vec2 param_6 = dir;\n            dir = fa_shadow_vogel_turn(param_6);\n        }\n        if (cnt < 0.5)\n        {\n            return 1.0;\n        }\n        float _2351 = sum / cnt;\n        float _2361;\n        if (k < 0.0)\n        {\n            _2361 = (-k) / max(_2351, 0.0500000007450580596923828125);\n        }\n        else\n        {\n            _2361 = k;\n        }\n        radius = clamp(((max(zr - _2351, 0.0) * unit) * _2361) / texel_m, 1.5, 16.0);\n        dir = _2262;\n    }\n    float lit = 0.0;\n    int _2387 = (mode == 2) ? 24 : 16;\n    for (int i_1 = 0; i_1 < _2387; i_1++)\n    {\n        float _2406 = sqrt((float(i_1) + 0.5) / float(_2387)) * radius;\n        vec2 param_7 = uv + (dir * (fa_shadows[26].zw * _2406));\n        vec4 param_8 = rect;\n        vec3 param_9 = conv;\n        lit += float((zr - (_2406 * plane)) <= fa_shadow_fetch(param_7, param_8, param_9));\n        vec2 param_10 = dir;\n        dir = fa_shadow_vogel_turn(param_10);\n    }\n    return lit / float(_2387);\n}\n\nfloat fa_shadow_local(int li, vec3 lpos, vec3 world, vec3 n, vec3 l)\n{\n    bool _2611 = fa_mesh_fs_params[5].z < 0.5;\n    bool _2618;\n    if (!_2611)\n    {\n        _2618 = fa_shadows[29].x < 0.5;\n    }\n    else\n    {\n        _2618 = _2611;\n    }\n    if (_2618)\n    {\n        return 1.0;\n    }\n    int param = (int(fa_shadows[29].x + 0.5) - 1) + li;\n    vec4 _2631 = fa_light_texel(param);\n    float _2632 = _2631.x;\n    if (_2632 < 0.0)\n    {\n        return 1.0;\n    }\n    int _2641 = int(_2632 + 0.5);\n    int param_1 = _2641;\n    vec4 _2645 = fa_light_texel(param_1);\n    int param_2 = _2641 + 1;\n    vec4 _2650 = fa_light_texel(param_2);\n    float fade = 1.0;\n    float _2653 = _2645.y;\n    if (_2653 > 0.0)\n    {\n        float _2670 = 1.0 - smoothstep(0.75 * _2653, _2653, length(world - fa_shadows[27].xyz));\n        fade = _2670;\n        if (_2670 <= 0.0)\n        {\n            return 1.0;\n        }\n    }\n    int face = 0;\n    if (_2645.x > 1.5)\n    {\n        vec3 param_3 = world - lpos;\n        face = fa_cube_face(param_3);\n    }\n    int _2694 = (_2641 + 2) + (face * 6);\n    int param_4 = _2694;\n    int param_5 = _2694 + 1;\n    int param_6 = _2694 + 3;\n    vec4 _2708 = fa_light_texel(param_6);\n    int param_7 = _2694 + 4;\n    vec4 _2713 = fa_light_texel(param_7);\n    int param_8 = _2694 + 5;\n    vec4 _2718 = fa_light_texel(param_8);\n    float _2730 = _2718.x * max(dot(_2708, vec4(world, 1.0)), 0.001000000047497451305389404296875);\n    float _2735 = clamp(dot(n, l), 0.0, 1.0);\n    float _2758 = clamp(dot(n, _2708.xyz), -1.0, 1.0);\n    float _2777 = min(sqrt(1.0 - (_2758 * _2758)) / max(abs(dot(n, world - lpos)) / max(dot(_2708, vec4(world, 1.0)), 0.001000000047497451305389404296875), 0.20000000298023223876953125), 4.0);\n    float _2780 = _2650.y;\n    float _2782;\n    if (_2780 > 0.0)\n    {\n        _2782 = _2780;\n    }\n    else\n    {\n        _2782 = 1.5 * _2730;\n    }\n    vec4 _2802 = vec4(world + (n * (_2782 * sqrt(1.0 - (_2735 * _2735)))), 1.0);\n    float _2806 = dot(_2708, _2802);\n    float _2809 = _2718.y;\n    if (_2806 < _2809)\n    {\n        return 1.0;\n    }\n    vec2 _2824 = vec2(dot(fa_light_texel(param_4), _2802), dot(fa_light_texel(param_5), _2802)) / vec2(_2806);\n    float _2826 = _2824.x;\n    bool _2829 = _2826 < _2713.x;\n    bool _2838;\n    if (!_2829)\n    {\n        _2838 = _2826 > _2713.z;\n    }\n    else\n    {\n        _2838 = _2829;\n    }\n    bool _2847;\n    if (!_2838)\n    {\n        _2847 = _2824.y < _2713.y;\n    }\n    else\n    {\n        _2847 = _2838;\n    }\n    bool _2856;\n    if (!_2847)\n    {\n        _2856 = _2824.y > _2713.w;\n    }\n    else\n    {\n        _2856 = _2847;\n    }\n    if (_2856)\n    {\n        return 1.0;\n    }\n    float _2862 = _2650.x;\n    float _2864;\n    if (_2862 > 0.0)\n    {\n        _2864 = _2862;\n    }\n    else\n    {\n        _2864 = 1.5 * _2730;\n    }\n    vec2 param_9 = _2824;\n    vec4 param_10 = _2713;\n    float param_11 = _2806 - (_2864 * (1.0 + (0.5 * _2777)));\n    float param_12 = _2730;\n    float param_13 = 1.0;\n    float param_14 = _2718.z * 0.25;\n    float param_15 = (_2730 * min(_2777, 3.0)) * 0.5;\n    vec3 param_16 = vec3(1.0, _2809, _2718.z);\n    int param_17 = int(_2645.z + 0.5);\n    float param_18 = _2645.w;\n    return mix(1.0, fa_shadow_filter(param_9, param_10, param_11, param_12, param_13, param_14, param_15, param_16, param_17, param_18), fade);\n}\n\nfloat fa_shadow_local_rt(int li, vec3 lpos, vec3 world, vec3 n, vec3 l)\n{\n    bool _3371 = fa_mesh_fs_params[25].w > 0.5;\n    bool _3377;\n    if (_3371)\n    {\n        _3377 = fa_mesh_fs_params[5].z > 0.5;\n    }\n    else\n    {\n        _3377 = _3371;\n    }\n    bool _3383;\n    if (_3377)\n    {\n        _3383 = fa_shadows[29].x > 0.5;\n    }\n    else\n    {\n        _3383 = _3377;\n    }\n    if (_3383)\n    {\n        int param = (int(fa_shadows[29].x + 0.5) - 1) + li;\n        vec4 _3395 = fa_light_texel(param);\n        float _3396 = _3395.z;\n        if (_3396 > 0.5)\n        {\n            float _3409 = dot(fa_mesh_fs_params[29].xyz, world) + fa_mesh_fs_params[29].w;\n            float _3415 = ((0.00200000009499490261077880859375 * _3409) + 0.00999999977648258209228515625) + fa_rt_slope;\n            vec4 _3421 = vec4(world, 1.0);\n            float _3426 = dot(fa_mesh_fs_params[28], _3421);\n            if (_3426 > 9.9999997473787516355514526367188e-05)\n            {\n                vec2 _3443 = vec2(dot(fa_mesh_fs_params[26], _3421), dot(fa_mesh_fs_params[27], _3421)) / vec2(_3426);\n                float _3448 = (_3443.x * 0.5) + 0.5;\n                float _3452;\n                if (fa_mesh_fs_params[24].y > 0.5)\n                {\n                    _3452 = (_3443.y * 0.5) + 0.5;\n                }\n                else\n                {\n                    _3452 = 0.5 - (_3443.y * 0.5);\n                }\n                bool _3468 = _3448 >= 0.0;\n                bool _3474;\n                if (_3468)\n                {\n                    _3474 = _3448 < 1.0;\n                }\n                else\n                {\n                    _3474 = _3468;\n                }\n                bool _3480;\n                if (_3474)\n                {\n                    _3480 = _3452 >= 0.0;\n                }\n                else\n                {\n                    _3480 = _3474;\n                }\n                bool _3486;\n                if (_3480)\n                {\n                    _3486 = _3452 < 1.0;\n                }\n                else\n                {\n                    _3486 = _3480;\n                }\n                if (_3486)\n                {\n                    ivec2 _3503 = ivec2(fa_mesh_fs_params[24].zw) - ivec2(1);\n                    ivec2 _3504 = clamp(ivec2(vec2(_3448, _3452) * fa_mesh_fs_params[24].zw), ivec2(0), _3503);\n                    float _3508;\n                    if (_3396 < 1.5)\n                    {\n                        _3508 = 1.0;\n                    }\n                    else\n                    {\n                        _3508 = (_3396 < 2.5) ? 256.0 : 65536.0;\n                    }\n                    float best = 2.0;\n                    int _3530;\n                    int _3536;\n                    for (int k = 0; k < 9; k++)\n                    {\n                        if (k == 0)\n                        {\n                            _3530 = 4;\n                        }\n                        else\n                        {\n                            if (k <= 4)\n                            {\n                                _3536 = k - 1;\n                            }\n                            else\n                            {\n                                _3536 = k;\n                            }\n                            _3530 = _3536;\n                        }\n                        vec4 _3565 = texelFetch(fa_screen_tex_fa_shadow_smp, clamp(_3504 + ivec2((_3530 % 3) - 1, (_3530 / 3) - 1), ivec2(0), _3503), 0);\n                        bool _3568 = _3565.w > 0.5;\n                        bool _3578;\n                        if (_3568)\n                        {\n                            _3578 = abs(_3409 - _3565.x) <= _3415;\n                        }\n                        else\n                        {\n                            _3578 = _3568;\n                        }\n                        if (_3578)\n                        {\n                            best = min(best, mod(floor(_3565.z / _3508), 256.0) * 0.0039215688593685626983642578125);\n                            if (k == 0)\n                            {\n                                break;\n                            }\n                        }\n                    }\n                    if (best <= 1.0)\n                    {\n                        float _3605;\n                        if (fa_mesh_fs_params[25].z > 0.5)\n                        {\n                            int param_1 = li;\n                            vec3 param_2 = lpos;\n                            vec3 param_3 = world;\n                            vec3 param_4 = n;\n                            vec3 param_5 = l;\n                            _3605 = min(best, fa_shadow_local(param_1, param_2, param_3, param_4, param_5));\n                        }\n                        else\n                        {\n                            _3605 = best;\n                        }\n                        return _3605;\n                    }\n                }\n            }\n            float _3628;\n            if (fa_mesh_fs_params[25].z > 0.5)\n            {\n                int param_6 = li;\n                vec3 param_7 = lpos;\n                vec3 param_8 = world;\n                vec3 param_9 = n;\n                vec3 param_10 = l;\n                _3628 = fa_shadow_local(param_6, param_7, param_8, param_9, param_10);\n            }\n            else\n            {\n                _3628 = 1.0;\n            }\n            return _3628;\n        }\n    }\n    int param_11 = li;\n    vec3 param_12 = lpos;\n    vec3 param_13 = world;\n    vec3 param_14 = n;\n    vec3 param_15 = l;\n    return fa_shadow_local(param_11, param_12, param_13, param_14, param_15);\n}\n\nfloat fa_shadow_split_at(int i)\n{\n    float _2149;\n    if (i == 0)\n    {\n        _2149 = fa_shadows[24].x;\n    }\n    else\n    {\n        float _2165;\n        if (i == 1)\n        {\n            _2165 = fa_shadows[24].y;\n        }\n        else\n        {\n            float _2173;\n            if (i == 2)\n            {\n                _2173 = fa_shadows[24].z;\n            }\n            else\n            {\n                _2173 = fa_shadows[24].w;\n            }\n            _2165 = _2173;\n        }\n        _2149 = _2165;\n    }\n    return _2149;\n}\n\nfloat fa_shadow_cascade(int ci, vec3 world, vec3 n, vec3 l)\n{\n    float _2452 = max(fa_shadows[ci * 1 + 20].y, 0.001000000047497451305389404296875);\n    float _2457 = clamp(dot(n, l), 0.0, 1.0);\n    float _2463 = sqrt(1.0 - (_2457 * _2457));\n    float _2471 = min(_2463 / max(_2457, 0.20000000298023223876953125), 4.0);\n    float _2476;\n    if (fa_shadows[26].y > 0.0)\n    {\n        _2476 = fa_shadows[26].y;\n    }\n    else\n    {\n        _2476 = 1.5 * fa_shadows[ci * 1 + 20].x;\n    }\n    vec4 _2501 = mat4(fa_shadows[ci * 4 + 0], fa_shadows[ci * 4 + 1], fa_shadows[ci * 4 + 2], fa_shadows[ci * 4 + 3]) * vec4(world + (n * (_2476 * _2463)), 1.0);\n    float _2508 = _2501.x;\n    bool _2511 = _2508 < fa_shadows[ci * 1 + 16].x;\n    bool _2520;\n    if (!_2511)\n    {\n        _2520 = _2508 > fa_shadows[ci * 1 + 16].z;\n    }\n    else\n    {\n        _2520 = _2511;\n    }\n    bool _2529;\n    if (!_2520)\n    {\n        _2529 = _2501.y < fa_shadows[ci * 1 + 16].y;\n    }\n    else\n    {\n        _2529 = _2520;\n    }\n    bool _2538;\n    if (!_2529)\n    {\n        _2538 = _2501.y > fa_shadows[ci * 1 + 16].w;\n    }\n    else\n    {\n        _2538 = _2529;\n    }\n    bool _2545;\n    if (!_2538)\n    {\n        _2545 = _2501.z > 1.0;\n    }\n    else\n    {\n        _2545 = _2538;\n    }\n    if (_2545)\n    {\n        return -1.0;\n    }\n    float _2553;\n    if (fa_shadows[26].x > 0.0)\n    {\n        _2553 = fa_shadows[26].x;\n    }\n    else\n    {\n        _2553 = 1.5 * fa_shadows[ci * 1 + 20].x;\n    }\n    vec2 param = _2501.xy;\n    vec4 param_1 = fa_shadows[ci * 1 + 16];\n    float param_2 = _2501.z - ((_2553 * (1.0 + (0.5 * _2471))) / _2452);\n    float param_3 = fa_shadows[ci * 1 + 20].x;\n    float param_4 = _2452;\n    float param_5 = _2452 * 0.25;\n    float param_6 = ((fa_shadows[ci * 1 + 20].x * min(_2471, 3.0)) * 0.5) / _2452;\n    vec3 param_7 = vec3(0.0);\n    int param_8 = int(fa_shadows[25].z + 0.5);\n    float param_9 = fa_shadows[25].w;\n    return fa_shadow_filter(param, param_1, param_2, param_3, param_4, param_5, param_6, param_7, param_8, param_9);\n}\n\nfloat fa_shadow_sun(vec3 world, vec3 n, vec3 l)\n{\n    if (fa_mesh_fs_params[5].z < 0.5)\n    {\n        return 1.0;\n    }\n    int _2931 = int(fa_shadows[25].x + 0.5);\n    if (_2931 < 1)\n    {\n        return 1.0;\n    }\n    float _2946 = dot(world - fa_shadows[27].xyz, fa_shadows[28].xyz);\n    int param = _2931 - 1;\n    if (_2946 > fa_shadow_split_at(param))\n    {\n        return 1.0;\n    }\n    int ci = 0;\n    bool _2958 = _2931 > 1;\n    bool _2965;\n    if (_2958)\n    {\n        _2965 = _2946 > fa_shadows[24].x;\n    }\n    else\n    {\n        _2965 = _2958;\n    }\n    if (_2965)\n    {\n        ci = 1;\n    }\n    bool _2969 = _2931 > 2;\n    bool _2976;\n    if (_2969)\n    {\n        _2976 = _2946 > fa_shadows[24].y;\n    }\n    else\n    {\n        _2976 = _2969;\n    }\n    if (_2976)\n    {\n        ci = 2;\n    }\n    bool _2980 = _2931 > 3;\n    bool _2987;\n    if (_2980)\n    {\n        _2987 = _2946 > fa_shadows[24].z;\n    }\n    else\n    {\n        _2987 = _2980;\n    }\n    if (_2987)\n    {\n        ci = 3;\n    }\n    float s = -1.0;\n    float s2 = -1.0;\n    float t = 0.0;\n    int _2998 = min(_2931, 4);\n    float _3039;\n    for (int c = ci; c < _2998; c++)\n    {\n        int param_1 = c;\n        vec3 param_2 = world;\n        vec3 param_3 = n;\n        vec3 param_4 = l;\n        float _3018 = fa_shadow_cascade(param_1, param_2, param_3, param_4);\n        if (s >= 0.0)\n        {\n            s2 = _3018;\n            break;\n        }\n        if (_3018 < 0.0)\n        {\n            continue;\n        }\n        s = _3018;\n        ci = c;\n        if (fa_shadows[25].y > 0.0)\n        {\n            if (ci > 0)\n            {\n                int param_5 = ci - 1;\n                _3039 = fa_shadow_split_at(param_5);\n            }\n            else\n            {\n                _3039 = fa_shadows[28].w;\n            }\n            int param_6 = ci;\n            float _3058 = fa_shadows[25].y * max(fa_shadow_split_at(param_6) - _3039, 9.9999997473787516355514526367188e-05);\n            int param_7 = ci;\n            t = clamp((_2946 - (fa_shadow_split_at(param_7) - _3058)) / _3058, 0.0, 1.0);\n        }\n        if (t <= 0.0)\n        {\n            break;\n        }\n    }\n    if (s < 0.0)\n    {\n        return 1.0;\n    }\n    if (t > 0.0)\n    {\n        float _3090;\n        if ((ci + 1) < _2931)\n        {\n            _3090 = (s2 < 0.0) ? s : s2;\n        }\n        else\n        {\n            _3090 = 1.0;\n        }\n        s = mix(s, _3090, t);\n    }\n    return s;\n}\n\nfloat fa_shadow_factor(vec3 n, vec3 l)\n{\n    bool _3195 = fa_mesh_fs_params[25].y > 0.5;\n    bool _3201;\n    if (_3195)\n    {\n        _3201 = fa_mesh_fs_params[5].z > 0.5;\n    }\n    else\n    {\n        _3201 = _3195;\n    }\n    if (_3201)\n    {\n        float _3215 = dot(fa_mesh_fs_params[29].xyz, fa_world_pos) + fa_mesh_fs_params[29].w;\n        vec4 _3223 = vec4(fa_world_pos, 1.0);\n        float _3229 = dot(fa_mesh_fs_params[28], _3223);\n        if (_3229 > 9.9999997473787516355514526367188e-05)\n        {\n            vec2 _3248 = vec2(dot(fa_mesh_fs_params[26], _3223), dot(fa_mesh_fs_params[27], _3223)) / vec2(_3229);\n            float _3253 = (_3248.x * 0.5) + 0.5;\n            float _3257;\n            if (fa_mesh_fs_params[24].y > 0.5)\n            {\n                _3257 = (_3248.y * 0.5) + 0.5;\n            }\n            else\n            {\n                _3257 = 0.5 - (_3248.y * 0.5);\n            }\n            bool _3273 = _3253 >= 0.0;\n            bool _3279;\n            if (_3273)\n            {\n                _3279 = _3253 < 1.0;\n            }\n            else\n            {\n                _3279 = _3273;\n            }\n            bool _3285;\n            if (_3279)\n            {\n                _3285 = _3257 >= 0.0;\n            }\n            else\n            {\n                _3285 = _3279;\n            }\n            bool _3291;\n            if (_3285)\n            {\n                _3291 = _3257 < 1.0;\n            }\n            else\n            {\n                _3291 = _3285;\n            }\n            if (_3291)\n            {\n                vec4 _3317 = texelFetch(fa_screen_tex_fa_shadow_smp, clamp(ivec2(vec2(_3253, _3257) * fa_mesh_fs_params[24].zw), ivec2(0), ivec2(fa_mesh_fs_params[24].zw) - ivec2(1)), 0);\n                bool _3320 = _3317.w > 0.5;\n                bool _3336;\n                if (_3320)\n                {\n                    _3336 = abs(_3215 - _3317.x) <= (((0.00200000009499490261077880859375 * _3215) + 0.00999999977648258209228515625) + fa_rt_slope);\n                }\n                else\n                {\n                    _3336 = _3320;\n                }\n                if (_3336)\n                {\n                    float _3342;\n                    if (fa_mesh_fs_params[25].z > 0.5)\n                    {\n                        vec3 param = fa_world_pos;\n                        vec3 param_1 = n;\n                        vec3 param_2 = l;\n                        _3342 = min(_3317.y, fa_shadow_sun(param, param_1, param_2));\n                    }\n                    else\n                    {\n                        _3342 = _3317.y;\n                    }\n                    return _3342;\n                }\n            }\n        }\n    }\n    vec3 param_3 = fa_world_pos;\n    vec3 param_4 = n;\n    vec3 param_5 = l;\n    return fa_shadow_sun(param_3, param_4, param_5);\n}\n\nfloat fa_contact_shadow(int li, vec3 world, vec3 gn, vec3 l, float dist)\n{\n    bool _5183 = fa_mesh_fs_params[24].x < 0.5;\n    bool _5190;\n    if (!_5183)\n    {\n        _5190 = fa_shadows[29].x < 0.5;\n    }\n    else\n    {\n        _5190 = _5183;\n    }\n    if (_5190)\n    {\n        return 1.0;\n    }\n    int param = (int(fa_shadows[29].x + 0.5) - 1) + li;\n    vec4 _5203 = fa_light_texel(param);\n    float _5204 = _5203.y;\n    float len = _5204;\n    if (_5204 <= 0.0)\n    {\n        return 1.0;\n    }\n    float _5216 = length(world - fa_mesh_fs_params[0].xyz);\n    float _5225 = 1.0 - smoothstep(0.5 * fa_mesh_fs_params[25].x, fa_mesh_fs_params[25].x, _5216);\n    if (_5225 <= 0.0)\n    {\n        return 1.0;\n    }\n    float _5231 = len;\n    float _5234 = min(_5231, 0.89999997615814208984375 * dist);\n    len = _5234;\n    float _5239 = 0.004999999888241291046142578125 + (0.0030000000260770320892333984375 * _5216);\n    float _5244 = _5239 + (0.5 * _5234);\n    vec3 _5250 = world + (gn * _5239);\n    float _5252 = fa_shadow_noise();\n    float occ = 0.0;\n    float _5313;\n    for (int k = 0; k < 12; k++)\n    {\n        float _5267 = (float(k) + _5252) * 0.083333335816860198974609375;\n        vec3 _5275 = _5250 + (l * (_5267 * len));\n        vec4 _5281 = vec4(_5275, 1.0);\n        float _5286 = dot(fa_mesh_fs_params[28], _5281);\n        if (_5286 < 9.9999997473787516355514526367188e-05)\n        {\n            break;\n        }\n        vec2 _5304 = vec2(dot(fa_mesh_fs_params[26], _5281), dot(fa_mesh_fs_params[27], _5281)) / vec2(_5286);\n        float _5308 = _5304.x * 0.5;\n        float _5309 = _5308 + 0.5;\n        if (fa_mesh_fs_params[24].y > 0.5)\n        {\n            _5313 = (_5304.y * 0.5) + 0.5;\n        }\n        else\n        {\n            _5313 = 0.5 - (_5304.y * 0.5);\n        }\n        bool _5329 = _5309 < 0.0;\n        bool _5336;\n        if (!_5329)\n        {\n            _5336 = _5309 >= 1.0;\n        }\n        else\n        {\n            _5336 = _5329;\n        }\n        bool _5343;\n        if (!_5336)\n        {\n            _5343 = _5313 < 0.0;\n        }\n        else\n        {\n            _5343 = _5336;\n        }\n        bool _5350;\n        if (!_5343)\n        {\n            _5350 = _5313 >= 1.0;\n        }\n        else\n        {\n            _5350 = _5343;\n        }\n        if (_5350)\n        {\n            break;\n        }\n        vec4 _5374 = texelFetch(fa_screen_tex_fa_shadow_smp, clamp(ivec2(vec2(_5309, _5313) * fa_mesh_fs_params[24].zw), ivec2(0), ivec2(fa_mesh_fs_params[24].zw) - ivec2(1)), 0);\n        if (_5374.w < 0.5)\n        {\n            continue;\n        }\n        float _5392 = (dot(fa_mesh_fs_params[29].xyz, _5275) + fa_mesh_fs_params[29].w) - _5374.x;\n        if ((_5392 > _5239) && (_5392 < _5244))\n        {\n            occ = max(occ, (1.0 - (_5267 * _5267)) * smoothstep(0.0, 0.0500000007450580596923828125, min(min(_5309, 0.5 - _5308), min(_5313, 1.0 - _5313))));\n        }\n    }\n    return 1.0 - (occ * _5225);\n}\n\nLightSample fa_light_shadowed(int li, vec3 world_pos, vec3 gn)\n{\n    int param = li;\n    float _5524 = fa_baked_keep(param);\n    if (_5524 <= 0.0)\n    {\n        int param_1 = li;\n        return LightSample(vec3(0.0, 1.0, 0.0), vec3(0.0), 0.0, 1.0, 0.0, int(fa_light_type(param_1) + 0.5));\n    }\n    int param_2 = li;\n    vec3 param_3 = world_pos;\n    vec3 param_4 = gn;\n    LightSample _5550 = fa_light_sample_n(param_2, param_3, param_4);\n    vec3 _7503 = _5550.color;\n    float _7504 = _5550.attenuation;\n    float _7505 = _5550.shadow;\n    bool _5553 = _5550.type == 0;\n    if (_5553 && (li == 0))\n    {\n        vec3 param_5 = gn;\n        vec3 param_6 = _5550.direction;\n        float _5564 = fa_shadow_factor(param_5, param_6);\n        _7505 = _5564;\n        _7503 *= _5564;\n    }\n    else\n    {\n        bool _5575 = _5550.type != 0;\n        bool _5581;\n        if (_5575)\n        {\n            _5581 = _7504 > 0.0;\n        }\n        else\n        {\n            _5581 = _5575;\n        }\n        if (_5581)\n        {\n            int param_7 = li;\n            int param_8 = fa_light_base(param_7);\n            int param_9 = li;\n            vec3 param_10 = fa_light_texel(param_8).xyz;\n            vec3 param_11 = world_pos;\n            vec3 param_12 = gn;\n            vec3 param_13 = _5550.direction;\n            float _5600 = fa_shadow_local_rt(param_9, param_10, param_11, param_12, param_13);\n            _7505 = _5600;\n            _7503 *= _5600;\n        }\n    }\n    bool _5610 = fa_mesh_fs_params[24].x > 0.5;\n    bool _5616;\n    if (_5610)\n    {\n        _5616 = _7504 > 0.0;\n    }\n    else\n    {\n        _5616 = _5610;\n    }\n    if (_5616)\n    {\n        float _5623;\n        if (_5553)\n        {\n            _5623 = 1000000000.0;\n        }\n        else\n        {\n            _5623 = _5550._distance;\n        }\n        int param_14 = li;\n        vec3 param_15 = world_pos;\n        vec3 param_16 = gn;\n        vec3 param_17 = _5550.direction;\n        float param_18 = _5623;\n        float _5641 = fa_contact_shadow(param_14, param_15, param_16, param_17, param_18);\n        _7505 *= _5641;\n        _7503 *= _5641;\n    }\n    float _5654 = _7504;\n    float _5655 = _5654 * _5524;\n    _7504 = _5655;\n    vec3 _5659 = _7503;\n    vec3 _5660 = _5659 * _5524;\n    _7503 = _5660;\n    return LightSample(_5550.direction, _5660, _5655, _7505, _5550._distance, _5550.type);\n}\n\nvec3 light(SurfaceInput i, Surface s, LightSample l)\n{\n    return vec3(0.0);\n}\n\nvec3 fa_shadow_debug(vec3 color, vec3 world)\n{\n    if (fa_shadows[27].w < 0.5)\n    {\n        return color;\n    }\n    int _3118 = int(fa_shadows[25].x + 0.5);\n    float _3128 = dot(world - fa_shadows[27].xyz, fa_shadows[28].xyz);\n    vec3 tint = vec3(0.3499999940395355224609375);\n    bool _3133 = _3118 > 0;\n    bool _3142;\n    if (_3133)\n    {\n        int param = _3118 - 1;\n        _3142 = _3128 <= fa_shadow_split_at(param);\n    }\n    else\n    {\n        _3142 = _3133;\n    }\n    if (_3142)\n    {\n        tint = vec3(1.0, 0.1500000059604644775390625, 0.100000001490116119384765625);\n        bool _3148 = _3118 > 1;\n        bool _3155;\n        if (_3148)\n        {\n            _3155 = _3128 > fa_shadows[24].x;\n        }\n        else\n        {\n            _3155 = _3148;\n        }\n        if (_3155)\n        {\n            tint = vec3(0.100000001490116119384765625, 0.89999997615814208984375, 0.20000000298023223876953125);\n        }\n        bool _3161 = _3118 > 2;\n        bool _3168;\n        if (_3161)\n        {\n            _3168 = _3128 > fa_shadows[24].y;\n        }\n        else\n        {\n            _3168 = _3161;\n        }\n        if (_3168)\n        {\n            tint = vec3(0.1500000059604644775390625, 0.300000011920928955078125, 1.0);\n        }\n        bool _3174 = _3118 > 3;\n        bool _3181;\n        if (_3174)\n        {\n            _3181 = _3128 > fa_shadows[24].z;\n        }\n        else\n        {\n            _3181 = _3174;\n        }\n        if (_3181)\n        {\n            tint = vec3(1.0, 0.89999997615814208984375, 0.100000001490116119384765625);\n        }\n    }\n    return mix(color, tint, vec3(0.550000011920928955078125));\n}\n\nvoid main()\n{\n    fa_rt_slope = 0.0;\n    fa_inst_load();\n    vec3 _7188 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _7188 = -_7188;\n    }\n    vec3 _6811 = normalize(fa_mesh_fs_params[0].xyz - fa_world_pos);\n    vec3 param = fa_world_pos;\n    fa_cluster_begin(param);\n    SurfaceInput param_1 = SurfaceInput(fa_world_pos, _7188, fa_world_tangent, fa_uv, fa_vertex_color, _6811, gl_FrontFacing);\n    Surface _6819 = fa_standard_surface(param_1);\n    vec3 _7227 = _6819.albedo;\n    float _7228 = _6819.alpha;\n    vec3 _7229 = _6819.normal;\n    float _7230 = _6819.metallic;\n    float _7231 = _6819.roughness;\n    float _7232 = _6819.occlusion;\n    vec3 _7233 = _6819.emission;\n    float _7234 = _6819.clearcoat;\n    float _7235 = _6819.clearcoat_roughness;\n    vec3 _7236 = _6819.sheen_color;\n    float _7237 = _6819.sheen_roughness;\n    float _7238 = _6819.anisotropy;\n    float _7239 = _6819.anisotropy_rotation;\n    float _7240 = _6819.specular;\n    float _7241 = _6819.ior;\n    vec3 _7242 = _6819.specular_color;\n    float _7243 = _6819.transmission;\n    float _7244 = _6819.thickness;\n    vec3 _7245 = _6819.attenuation_color;\n    float _7246 = _6819.attenuation_distance;\n    SurfaceInput param_2 = SurfaceInput(fa_world_pos, _7188, fa_world_tangent, fa_uv, fa_vertex_color, _6811, gl_FrontFacing);\n    Surface param_3 = _6819;\n    surface(param_2, param_3);\n    _7227 = param_3.albedo;\n    _7228 = param_3.alpha;\n    _7229 = param_3.normal;\n    _7230 = param_3.metallic;\n    _7231 = param_3.roughness;\n    _7232 = param_3.occlusion;\n    _7233 = param_3.emission;\n    _7234 = param_3.clearcoat;\n    _7235 = param_3.clearcoat_roughness;\n    _7236 = param_3.sheen_color;\n    _7237 = param_3.sheen_roughness;\n    _7238 = param_3.anisotropy;\n    _7239 = param_3.anisotropy_rotation;\n    _7240 = param_3.specular;\n    _7241 = param_3.ior;\n    _7242 = param_3.specular_color;\n    _7243 = param_3.transmission;\n    _7244 = param_3.thickness;\n    _7245 = param_3.attenuation_color;\n    _7246 = param_3.attenuation_distance;\n    vec3 param_4 = fa_world_pos;\n    vec3 param_5 = _7188;\n    vec3 param_6 = param_3.albedo;\n    vec3 param_7 = param_3.normal;\n    fa_apply_decals(param_4, param_5, param_6, param_7);\n    _7227 = param_6;\n    _7229 = param_7;\n    vec3 result;\n    if (fa_mesh_fs_params[3].w > 0.5)\n    {\n        result = _7227;\n    }\n    else\n    {\n        vec3 _6858 = _7229;\n        vec3 _6859 = normalize(_6858);\n        _7229 = _6859;\n        vec3 param_8 = _6859;\n        SurfaceInput param_9 = SurfaceInput(fa_world_pos, _7188, fa_world_tangent, fa_uv, fa_vertex_color, _6811, gl_FrontFacing);\n        Surface param_10 = Surface(_7227, _7228, _7229, _7230, _7231, _7232, _7233, _7234, _7235, _7236, _7237, _7238, _7239, _7240, _7241, _7242, _7243, _7244, _7245, _7246);\n        vec3 param_11 = fa_indirect_diffuse(param_8);\n        vec3 lit = ambient(param_9, param_10, param_11);\n        int _6878 = fa_cl_ndir + fa_cl_local;\n        for (int ln = 0; ln < _6878; ln++)\n        {\n            int param_12 = ln;\n            int _6891 = fa_cl_light(param_12);\n            int param_13 = _6891;\n            if (fa_baked_keep(param_13) <= 0.0)\n            {\n                continue;\n            }\n            int param_14 = _6891;\n            vec3 param_15 = fa_world_pos;\n            vec3 param_16 = _7188;\n            LightSample _6907 = fa_light_shadowed(param_14, param_15, param_16);\n            SurfaceInput param_17 = SurfaceInput(fa_world_pos, _7188, fa_world_tangent, fa_uv, fa_vertex_color, _6811, gl_FrontFacing);\n            Surface param_18 = Surface(_7227, _7228, _7229, _7230, _7231, _7232, _7233, _7234, _7235, _7236, _7237, _7238, _7239, _7240, _7241, _7242, _7243, _7244, _7245, _7246);\n            LightSample param_19 = _6907;\n            lit += light(param_17, param_18, param_19);\n        }\n        result = lit;\n    }\n    vec3 _6922 = result;\n    vec3 _6923 = _6922 + _7233;\n    result = _6923;\n    vec3 param_20 = _6923;\n    vec3 param_21 = fa_world_pos;\n    result = fa_shadow_debug(param_20, param_21);\n    bool _6932 = fa_mesh_fs_params[7].w > 0.0;\n    bool _6939;\n    if (!_6932)\n    {\n        _6939 = fa_mesh_fs_params[8].y > 0.0;\n    }\n    else\n    {\n        _6939 = _6932;\n    }\n    if (_6939)\n    {\n        vec3 _6948 = fa_world_pos - fa_mesh_fs_params[0].xyz;\n        float _6954 = dot(_6948, fa_mesh_fs_params[9].xyz);\n        bool _6958 = fa_mesh_fs_params[9].w > 0.5;\n        float _6959;\n        if (_6958)\n        {\n            _6959 = _6954;\n        }\n        else\n        {\n            _6959 = length(_6948);\n        }\n        float _6971 = _6959 - fa_mesh_fs_params[8].x;\n        if (_6971 > 0.0)\n        {\n            float _6980 = fa_mesh_fs_params[7].w * _6971;\n            float tau = _6980 * _6980;\n            if (fa_mesh_fs_params[8].y > 0.0)\n            {\n                float _6996;\n                if (_6958)\n                {\n                    _6996 = fa_world_pos.y - (fa_mesh_fs_params[9].y * _6954);\n                }\n                else\n                {\n                    _6996 = fa_mesh_fs_params[0].y;\n                }\n                float _7017 = mix(_6996, fa_world_pos.y, clamp(fa_mesh_fs_params[8].x / _6959, 0.0, 1.0));\n                float _7021 = fa_world_pos.y - _7017;\n                float _7026 = _7017 - fa_mesh_fs_params[8].z;\n                float _7031 = fa_world_pos.y - fa_mesh_fs_params[8].z;\n                bool _7034 = _7026 <= 0.0;\n                bool _7035 = !_7034;\n                bool _7041;\n                if (_7035)\n                {\n                    _7041 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _7041 = _7034;\n                }\n                float _7042;\n                if (_7041)\n                {\n                    _7042 = fa_mesh_fs_params[8].y;\n                }\n                else\n                {\n                    _7042 = fa_mesh_fs_params[8].y * exp(-min(fa_mesh_fs_params[8].w * _7026, 80.0));\n                }\n                bool _7069;\n                if (_7035)\n                {\n                    _7069 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _7069 = _7034;\n                }\n                float _7070;\n                if (_7069)\n                {\n                    _7070 = fa_mesh_fs_params[8].y * _7026;\n                }\n                else\n                {\n                    _7070 = (fa_mesh_fs_params[8].y * (1.0 - exp(-min(fa_mesh_fs_params[8].w * _7026, 80.0)))) / fa_mesh_fs_params[8].w;\n                }\n                bool _7095 = _7031 <= 0.0;\n                bool _7102;\n                if (!_7095)\n                {\n                    _7102 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _7102 = _7095;\n                }\n                float _7103;\n                if (_7102)\n                {\n                    _7103 = fa_mesh_fs_params[8].y * _7031;\n                }\n                else\n                {\n                    _7103 = (fa_mesh_fs_params[8].y * (1.0 - exp(-min(fa_mesh_fs_params[8].w * _7031, 80.0)))) / fa_mesh_fs_params[8].w;\n                }\n                float _7130;\n                if (abs(_7021) < 0.001000000047497451305389404296875)\n                {\n                    _7130 = _7042;\n                }\n                else\n                {\n                    _7130 = (_7103 - _7070) / _7021;\n                }\n                tau += (_6971 * max(_7130, 0.0));\n            }\n            result = mix(result, fa_mesh_fs_params[7].xyz, vec3(clamp(1.0 - exp(-clamp(tau, 0.0, 80.0)), 0.0, 1.0)));\n        }\n    }\n    fa_frag_color = vec4(result, _7228);\n}\n\n",
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
            "size": 864,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_507",
            "glsl_uniforms": [
              {
                "type": "vec4",
                "array_count": 54,
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
            "inst_name": "_2159",
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
            "name": "fa_screen_tex_fa_shadow_smp",
            "view_name": "fa_screen_tex",
            "sampler_name": "fa_shadow_smp",
            "view_slot": 28,
            "sampler_slot": 1,
            "glsl_name": "fa_screen_tex_fa_shadow_smp"
          },
          {
            "slot": 11,
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
      "vs": "#version 430\n\nstruct VertexData\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 color;\n    vec3 object_pos;\n};\n\nuniform vec4 fa_mesh_vs_params[11];\nuniform vec4 fa_skin[192];\nlayout(location = 0) out vec3 fa_world_pos;\nlayout(location = 1) out vec3 fa_world_normal;\nlayout(location = 2) out vec4 fa_world_tangent;\nlayout(location = 3) out vec2 fa_uv;\nlayout(location = 4) out vec4 fa_vertex_color;\nlayout(location = 5) in vec4 fa_inst_m0;\nlayout(location = 6) in vec4 fa_inst_m1;\nlayout(location = 7) in vec4 fa_inst_m2;\nlayout(location = 8) in vec4 fa_inst_m3;\nlayout(location = 9) in vec4 fa_joints;\nlayout(location = 10) in vec4 fa_weights;\nlayout(location = 0) in vec3 fa_position;\nlayout(location = 1) in vec3 fa_normal;\nlayout(location = 3) in vec4 fa_tangent;\nlayout(location = 2) in vec2 fa_texcoord0;\nlayout(location = 4) in vec4 fa_color;\nlayout(location = 5) out vec3 fa_lm;\n\nvoid fa_inst_begin()\n{\n}\n\nmat4 fa_skin_matrix(vec4 joints, vec4 weights)\n{\n    vec4 r0 = vec4(0.0);\n    vec4 r1 = vec4(0.0);\n    vec4 r2 = vec4(0.0);\n    for (int i = 0; i < 4; i++)\n    {\n        int _174 = int((joints[i] * 255.0) + 0.5) * 3;\n        r0 += (fa_skin[_174 * 1 + 0] * weights[i]);\n        r1 += (fa_skin[(_174 + 1) * 1 + 0] * weights[i]);\n        r2 += (fa_skin[(_174 + 2) * 1 + 0] * weights[i]);\n    }\n    return mat4(vec4(r0.x, r1.x, r2.x, 0.0), vec4(r0.y, r1.y, r2.y, 0.0), vec4(r0.z, r1.z, r2.z, 0.0), vec4(r0.w, r1.w, r2.w, 1.0));\n}\n\nVertexData fa_vertex_data(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    vec3 _74 = cross(model[1].xyz, model[2].xyz);\n    float _80 = (dot(model[0].xyz, _74) < 0.0) ? (-1.0) : 1.0;\n    return VertexData((model * vec4(position, 1.0)).xyz, (((_74 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _80, vec4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _80), texcoord0 * fa_mesh_vs_params[8].xy, color, position);\n}\n\nvoid fa_shade_vertex(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    mat4 param = model;\n    vec3 param_1 = position;\n    vec3 param_2 = normal;\n    vec4 param_3 = tangent;\n    vec2 param_4 = texcoord0;\n    vec4 param_5 = color;\n    VertexData _273 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    vec3 _388 = _273.world_pos;\n    fa_world_pos = _388;\n    fa_world_normal = _273.world_normal;\n    fa_world_tangent = _273.world_tangent;\n    fa_uv = _273.uv;\n    fa_vertex_color = _273.color;\n    gl_Position = mat4(fa_mesh_vs_params[0], fa_mesh_vs_params[1], fa_mesh_vs_params[2], fa_mesh_vs_params[3]) * vec4(_388, 1.0);\n}\n\nvoid main()\n{\n    fa_inst_begin();\n    vec4 param = fa_joints;\n    vec4 param_1 = fa_weights;\n    mat4 param_2 = mat4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3) * fa_skin_matrix(param, param_1);\n    vec3 param_3 = fa_position;\n    vec3 param_4 = fa_normal;\n    vec4 param_5 = fa_tangent;\n    vec2 param_6 = fa_texcoord0;\n    vec4 param_7 = fa_color;\n    fa_shade_vertex(param_2, param_3, param_4, param_5, param_6, param_7);\n    fa_lm = vec3(0.0);\n}\n\n",
      "fs": "#version 430\n\nstruct SurfaceInput\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 vertex_color;\n    vec3 view_dir;\n    bool front_facing;\n};\n\nstruct LightSample\n{\n    vec3 direction;\n    vec3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct Surface\n{\n    vec3 albedo;\n    float alpha;\n    vec3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    vec3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    vec3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    vec3 specular_color;\n    float transmission;\n    float thickness;\n    vec3 attenuation_color;\n    float attenuation_distance;\n};\n\nstruct FaLayers\n{\n    bool on;\n    float f90;\n    float keep;\n    float base_scale;\n    float coat;\n    float coat_rough;\n    float coat_alpha;\n    float coat_a2;\n    vec3 nc;\n    float coat_ndv;\n    bool sheen_on;\n    vec3 sheen;\n    float sheen_rough;\n    float sheen_alpha;\n    float sheen_scale;\n    float sheen_e;\n    float aniso;\n    vec3 t;\n    vec3 b;\n    float at;\n    float ab;\n};\n\nconst float _4654[63] = float[](1.0, 1.0, 1.0, 0.4790000021457672119140625, 0.11699999868869781494140625, 0.01200000010430812835693359375, 0.0, 0.0, 0.0, 1.0, 1.0, 1.0, 0.578000009059906005859375, 0.19300000369548797607421875, 0.0350000001490116119384765625, 0.0030000000260770320892333984375, 0.0, 0.0, 1.0, 1.0, 1.0, 0.6740000247955322265625, 0.3459999859333038330078125, 0.1319999992847442626953125, 0.032999999821186065673828125, 0.0040000001899898052215576171875, 0.0, 0.971000015735626220703125, 0.954999983310699462890625, 0.828999996185302734375, 0.63999998569488525390625, 0.42599999904632568359375, 0.24500000476837158203125, 0.115000002086162567138671875, 0.037000000476837158203125, 0.0030000000260770320892333984375, 0.7469999790191650390625, 0.737999975681304931640625, 0.670000016689300537109375, 0.563000023365020751953125, 0.4309999942779541015625, 0.3039999902248382568359375, 0.1940000057220458984375, 0.1019999980926513671875, 0.0309999994933605194091796875, 0.614000022411346435546875, 0.609000027179718017578125, 0.566999971866607666015625, 0.499000012874603271484375, 0.412000000476837158203125, 0.32400000095367431640625, 0.240999996662139892578125, 0.162000000476837158203125, 0.087999999523162841796875, 0.538999974727630615234375, 0.535000026226043701171875, 0.505999982357025146484375, 0.4569999873638153076171875, 0.393999993801116943359375, 0.328999996185302734375, 0.2660000026226043701171875, 0.203999996185302734375, 0.14200000464916229248046875);\n\nuniform vec4 fa_mesh_fs_params[54];\nuniform vec4 fa_shadows[30];\nlayout(binding = 0) uniform sampler2D fa_light_tex_fa_shadow_smp;\nlayout(binding = 1) uniform sampler2D fa_tex_fa_smp;\nlayout(binding = 2) uniform sampler2D fa_normal_tex_fa_smp;\nlayout(binding = 3) uniform sampler2D fa_mr_tex_fa_smp;\nlayout(binding = 4) uniform sampler2D fa_occlusion_tex_fa_smp;\nlayout(binding = 5) uniform sampler2D fa_emissive_tex_fa_smp;\nlayout(binding = 6) uniform sampler2D fa_decal_tex_fa_env_smp;\nlayout(binding = 7) uniform sampler2D fa_lightmap_fa_env_smp;\nlayout(binding = 8) uniform sampler2D fa_probe_atlas_fa_env_smp;\nlayout(binding = 9) uniform sampler2D fa_light_atlas_fa_env_smp;\nlayout(binding = 10) uniform sampler2D fa_screen_tex_fa_shadow_smp;\nlayout(binding = 11) uniform sampler2D fa_shadow_tex_fa_shadow_smp;\n\nlayout(location = 0) in vec3 fa_world_pos;\nlayout(location = 5) in vec3 fa_lm;\nlayout(location = 1) in vec3 fa_world_normal;\nlayout(location = 2) in vec4 fa_world_tangent;\nlayout(location = 3) in vec2 fa_uv;\nlayout(location = 4) in vec4 fa_vertex_color;\nlayout(location = 0) out vec4 fa_frag_color;\nfloat fa_rt_slope;\nvec3 fa_light_tint;\nbool fa_light_is_area;\nint fa_cl_ndir;\nint fa_cl_slot;\nint fa_cl_local;\n\nvoid fa_inst_load()\n{\n}\n\nvec4 fa_light_texel(int t)\n{\n    return texelFetch(fa_light_tex_fa_shadow_smp, ivec2(t & 1023, t >> 10), 0);\n}\n\nvec4 fa_cluster_texel(vec3 world_pos)\n{\n    bool _1435 = fa_mesh_fs_params[19].x < 0.0;\n    bool _1442;\n    if (!_1435)\n    {\n        _1442 = fa_mesh_fs_params[19].w < 1.0;\n    }\n    else\n    {\n        _1442 = _1435;\n    }\n    bool _1450;\n    if (!_1442)\n    {\n        _1450 = fa_mesh_fs_params[18].x < 1.0;\n    }\n    else\n    {\n        _1450 = _1442;\n    }\n    bool _1457;\n    if (!_1450)\n    {\n        _1457 = fa_mesh_fs_params[18].y < 1.0;\n    }\n    else\n    {\n        _1457 = _1450;\n    }\n    bool _1464;\n    if (!_1457)\n    {\n        _1464 = fa_mesh_fs_params[19].y < 1.0;\n    }\n    else\n    {\n        _1464 = _1457;\n    }\n    if (_1464)\n    {\n        return vec4(0.0);\n    }\n    vec4 _1474 = vec4(world_pos, 1.0);\n    float _1480 = dot(fa_mesh_fs_params[16], _1474);\n    if (!(_1480 > 9.9999999747524270787835121154785e-07))\n    {\n        return vec4(0.0);\n    }\n    vec2 _1502 = vec2(dot(fa_mesh_fs_params[14], _1474), dot(fa_mesh_fs_params[15], _1474)) / vec2(_1480);\n    int _1506 = int(fa_mesh_fs_params[18].x);\n    int _1510 = int(fa_mesh_fs_params[18].y);\n    int param = (int(fa_mesh_fs_params[19].x) + (((clamp(int(floor(log2(max(dot(fa_mesh_fs_params[17].xyz, world_pos) + fa_mesh_fs_params[17].w, fa_mesh_fs_params[18].w) / fa_mesh_fs_params[18].w) * fa_mesh_fs_params[18].z)), 0, int(fa_mesh_fs_params[19].y) - 1) * _1510) + clamp(int(floor(((_1502.y * 0.5) + 0.5) * fa_mesh_fs_params[18].y)), 0, _1510 - 1)) * _1506)) + clamp(int(floor(((_1502.x * 0.5) + 0.5) * fa_mesh_fs_params[18].x)), 0, _1506 - 1);\n    return fa_light_texel(param);\n}\n\nivec2 fa_cluster_lookup(vec3 world_pos)\n{\n    vec3 param = world_pos;\n    vec4 _1586 = fa_cluster_texel(param);\n    return ivec2(int(_1586.x), int(_1586.y));\n}\n\nvoid fa_cluster_begin(vec3 world_pos)\n{\n    float _5469 = dot(fa_mesh_fs_params[29].xyz, world_pos) + fa_mesh_fs_params[29].w;\n    float _5472 = fwidth(_5469);\n    bool _5475 = fa_mesh_fs_params[25].y > 0.5;\n    bool _5482;\n    if (!_5475)\n    {\n        _5482 = fa_mesh_fs_params[25].w > 0.5;\n    }\n    else\n    {\n        _5482 = _5475;\n    }\n    if (_5482)\n    {\n        fa_rt_slope = min(1.5 * _5472, 0.100000001490116119384765625 * _5469);\n    }\n    fa_cl_ndir = int(fa_mesh_fs_params[19].z);\n    vec3 param = world_pos;\n    ivec2 _5498 = fa_cluster_lookup(param);\n    fa_cl_slot = _5498.x;\n    fa_cl_local = _5498.y;\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_linear_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvec3 fa_tex_fix(inout vec3 c, float mode)\n{\n    if (mode > 1.5)\n    {\n        vec3 param = c;\n        vec3 _5710 = fa_linear_to_srgb(param);\n        c = _5710;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            vec3 param_1 = c;\n            vec3 _5718 = fa_srgb_to_linear(param_1);\n            c = _5718;\n        }\n    }\n    return c;\n}\n\nvec3 fa_tangent_normal(SurfaceInput i, vec3 m)\n{\n    vec3 _390;\n    if (i.front_facing)\n    {\n        _390 = i.world_normal;\n    }\n    else\n    {\n        _390 = -i.world_normal;\n    }\n    vec3 _414 = normalize(i.world_tangent.xyz - (_390 * dot(_390, i.world_tangent.xyz)));\n    vec3 _441 = normalize(((_414 * m.x) + ((cross(_390, _414) * i.world_tangent.w) * m.y)) + (_390 * m.z));\n    vec3 _444;\n    if (i.front_facing)\n    {\n        _444 = _441;\n    }\n    else\n    {\n        _444 = -_441;\n    }\n    return _444;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    vec4 base_t = texture(fa_tex_fa_smp, i.uv, fa_mesh_fs_params[12].w);\n    float param = fa_mesh_fs_params[6].w;\n    float param_1 = 1.0;\n    vec3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    vec3 _5750 = fa_tex_fix(param_2, param_3);\n    vec4 _7738 = base_t;\n    _7738.x = _5750.x;\n    _7738.y = _5750.y;\n    _7738.z = _5750.z;\n    base_t = _7738;\n    vec4 _5764 = (_7738 * fa_mesh_fs_params[2]) * i.vertex_color;\n    vec3 _7523 = i.world_normal;\n    if (fa_mesh_fs_params[6].z > 0.5)\n    {\n        float param_4 = fa_mesh_fs_params[6].w;\n        float param_5 = 16.0;\n        vec3 param_6 = texture(fa_normal_tex_fa_smp, i.uv, fa_mesh_fs_params[12].w).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        vec3 _5798 = fa_tex_fix(param_6, param_7);\n        vec3 _5801 = (_5798 * 2.0) - vec3(1.0);\n        vec2 _5806 = _5801.xy * fa_mesh_fs_params[6].x;\n        vec3 _7746 = _5801;\n        _7746.x = _5806.x;\n        _7746.y = _5806.y;\n        SurfaceInput param_8 = i;\n        vec3 param_9 = _7746;\n        _7523 = fa_tangent_normal(param_8, param_9);\n    }\n    vec4 mrt = texture(fa_mr_tex_fa_smp, i.uv, fa_mesh_fs_params[12].w);\n    float param_10 = fa_mesh_fs_params[6].w;\n    float param_11 = 64.0;\n    vec3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    vec3 _5836 = fa_tex_fix(param_12, param_13);\n    vec4 _7749 = mrt;\n    _7749.x = _5836.x;\n    _7749.y = _5836.y;\n    _7749.z = _5836.z;\n    mrt = _7749;\n    vec4 _5866 = texture(fa_occlusion_tex_fa_smp, i.uv, fa_mesh_fs_params[12].w);\n    float param_14 = fa_mesh_fs_params[6].w;\n    float param_15 = 256.0;\n    vec3 param_16 = _5866.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    vec3 _5877 = fa_tex_fix(param_16, param_17);\n    float param_18 = fa_mesh_fs_params[6].w;\n    float param_19 = 4.0;\n    vec3 param_20 = texture(fa_emissive_tex_fa_smp, i.uv, fa_mesh_fs_params[12].w).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    vec3 _5909 = fa_tex_fix(param_20, param_21);\n    float _7528 = fa_mesh_fs_params[20].x;\n    float _7529 = fa_mesh_fs_params[20].y;\n    float _7532 = fa_mesh_fs_params[20].z;\n    float _7531 = fa_mesh_fs_params[21].w;\n    float _7534 = fa_mesh_fs_params[22].x;\n    if (fa_mesh_fs_params[22].z > 0.5)\n    {\n        if (mod(fa_mesh_fs_params[22].z, 2.0) > 0.5)\n        {\n            _7528 *= _5877.y;\n            _7529 *= _5877.z;\n            _7531 *= _5866.w;\n        }\n        if (fa_mesh_fs_params[22].z > 1.5)\n        {\n            _7532 *= mrt.x;\n            _7534 *= mrt.w;\n        }\n    }\n    return Surface(_5764.xyz, _5764.w, _7523, clamp(fa_mesh_fs_params[5].x * _5836.z, 0.0, 1.0), clamp(fa_mesh_fs_params[5].y * _5836.y, 0.0500000007450580596923828125, 1.0), 1.0 + (fa_mesh_fs_params[6].y * (_5877.x - 1.0)), fa_mesh_fs_params[3].xyz + (fa_mesh_fs_params[4].xyz * _5909), _7528, _7529, fa_mesh_fs_params[21].xyz, _7531, _7532, fa_mesh_fs_params[20].w, _7534, fa_mesh_fs_params[22].y, fa_mesh_fs_params[23].xyz, fa_mesh_fs_params[30].x, fa_mesh_fs_params[30].y, fa_mesh_fs_params[31].xyz, fa_mesh_fs_params[30].z);\n}\n\nvoid surface(SurfaceInput i, Surface s)\n{\n}\n\nvec4 fa_decal_tile(vec4 rect, vec2 uv, vec2 atlas, vec2 ddx, vec2 ddy)\n{\n    vec2 _1666 = rect.zw - rect.xy;\n    vec2 _1670 = _1666 * atlas;\n    vec2 _1674 = ddx * _1670;\n    vec2 _1678 = ddy * _1670;\n    return textureLod(fa_decal_tex_fa_env_smp, rect.xy + (clamp(uv, vec2(0.0), vec2(1.0)) * _1666), clamp(0.5 * log2(max(max(dot(_1674, _1674), dot(_1678, _1678)), 9.9999999392252902907785028219223e-09)), 0.0, 3.0));\n}\n\nvec3 fa_dc_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_dc_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvoid fa_apply_decals(vec3 world_pos, vec3 geo_normal, inout vec3 albedo, inout vec3 normal)\n{\n    bool _1711 = fa_mesh_fs_params[10].y < 0.5;\n    bool _1718;\n    if (!_1711)\n    {\n        _1718 = fa_mesh_fs_params[10].w < 0.5;\n    }\n    else\n    {\n        _1718 = _1711;\n    }\n    if (_1718)\n    {\n        return;\n    }\n    vec3 _1724 = dFdx(world_pos);\n    vec3 _1727 = dFdy(world_pos);\n    vec3 param = world_pos;\n    vec4 _1731 = fa_cluster_texel(param);\n    int _1735 = int(_1731.w);\n    if (_1735 < 1)\n    {\n        return;\n    }\n    int _1745 = int(fa_mesh_fs_params[10].y + 0.5);\n    int param_1 = _1745;\n    vec4 _1749 = fa_light_texel(param_1);\n    vec2 _1752 = _1749.yz;\n    int _1756 = int(_1749.w);\n    int param_2 = _1745 + 1;\n    vec4 _1761 = fa_light_texel(param_2);\n    float _1762 = _1761.x;\n    int _1768 = int(fa_mesh_fs_params[10].w + 0.5) - 1;\n    int _1772 = int(_1731.z);\n    vec3 _2037;\n    for (int k = 0; k < _1735; k++)\n    {\n        int _1785 = _1772 + k;\n        int param_3 = _1756 + (_1785 >> 2);\n        int _1802 = (_1745 + 2) + (int(fa_light_texel(param_3)[_1785 & 3]) * 7);\n        int param_4 = _1802 + 6;\n        vec4 _1807 = fa_light_texel(param_4);\n        if (((int(_1807.w + 0.5) >> _1768) & 1) == 0)\n        {\n            continue;\n        }\n        int param_5 = _1802;\n        vec4 _1822 = fa_light_texel(param_5);\n        int param_6 = _1802 + 1;\n        vec4 _1827 = fa_light_texel(param_6);\n        int param_7 = _1802 + 2;\n        vec4 _1832 = fa_light_texel(param_7);\n        vec3 _1835 = _1822.xyz;\n        float _1840 = dot(_1835, world_pos) + _1822.w;\n        vec3 _1842 = _1827.xyz;\n        float _1847 = dot(_1842, world_pos) + _1827.w;\n        vec3 _1849 = _1832.xyz;\n        float _1854 = dot(_1849, world_pos) + _1832.w;\n        bool _1859 = abs(_1840) > 0.5;\n        bool _1867;\n        if (!_1859)\n        {\n            _1867 = abs(_1847) > 0.5;\n        }\n        else\n        {\n            _1867 = _1859;\n        }\n        bool _1875;\n        if (!_1867)\n        {\n            _1875 = abs(_1854) > 0.5;\n        }\n        else\n        {\n            _1875 = _1867;\n        }\n        if (_1875)\n        {\n            continue;\n        }\n        float _1890 = clamp(dot(geo_normal, normalize(_1849)) * _1807.z, 0.0, 1.0);\n        if (_1890 <= 0.0)\n        {\n            continue;\n        }\n        float _1910 = (clamp((0.5 - abs(_1854)) * 10.0, 0.0, 1.0) * _1890) * _1807.x;\n        vec2 _1918 = vec2(_1840 + 0.5, 0.5 - _1847);\n        vec2 _1928 = vec2(dot(_1835, _1724), dot(_1842, _1724));\n        vec2 _1938 = vec2(dot(_1835, _1727), dot(_1842, _1727));\n        int param_8 = _1802 + 5;\n        vec4 _1943 = fa_light_texel(param_8);\n        int param_9 = _1802 + 3;\n        vec4 _1948 = fa_light_texel(param_9);\n        int param_10 = _1802 + 4;\n        vec4 _1953 = fa_light_texel(param_10);\n        float tex_a = 1.0;\n        vec3 col = _1943.xyz;\n        bool _1963 = _1948.z > _1948.x;\n        if (_1963)\n        {\n            vec4 param_11 = _1948;\n            vec2 param_12 = _1918;\n            vec2 param_13 = _1752;\n            vec2 param_14 = _1928;\n            vec2 param_15 = _1938;\n            vec4 tx = fa_decal_tile(param_11, param_12, param_13, param_14, param_15);\n            if ((_1762 > 0.5) && (_1762 < 1.5))\n            {\n                vec3 param_16 = tx.xyz;\n                vec3 _1989 = fa_dc_to_linear(param_16);\n                vec4 _7611 = tx;\n                _7611.x = _1989.x;\n                _7611.y = _1989.y;\n                _7611.z = _1989.z;\n                tx = _7611;\n            }\n            col *= tx.xyz;\n            tex_a = tx.w;\n        }\n        albedo = mix(albedo, col, vec3(clamp((_1910 * tex_a) * _1943.w, 0.0, 1.0)));\n        if (_1953.z > _1953.x)\n        {\n            vec4 param_17 = _1953;\n            vec2 param_18 = _1918;\n            vec2 param_19 = _1752;\n            vec2 param_20 = _1928;\n            vec2 param_21 = _1938;\n            vec4 _2033 = fa_decal_tile(param_17, param_18, param_19, param_20, param_21);\n            if (_1762 > 1.5)\n            {\n                vec3 param_22 = _2033.xyz;\n                vec3 _2043 = fa_dc_to_srgb(param_22);\n                _2037 = _2043;\n            }\n            else\n            {\n                _2037 = _2033.xyz;\n            }\n            vec3 _2052 = (_2037 * 2.0) - vec3(1.0);\n            vec2 _2057 = _2052.xy * _1807.y;\n            vec3 _2079 = (normalize(_1835) * _2057.x) + (normalize(_1842) * _2057.y);\n            vec3 _2082 = normalize(normal);\n            normal = normalize(mix(_2082, normalize((_2082 * max(_2052.z, 0.0500000007450580596923828125)) + (_2079 - (_2082 * dot(_2082, _2079)))), vec3(clamp(_1910 * (_1963 ? tex_a : 1.0), 0.0, 1.0))));\n        }\n    }\n}\n\nvec2 fa_atlas_size()\n{\n    return vec2(textureSize(fa_probe_atlas_fa_env_smp, 0));\n}\n\nvec3 fa_probe_sh_coef(vec2 origin, float res, int k)\n{\n    vec3 v = textureLod(fa_probe_atlas_fa_env_smp, (origin + vec2(float(k) + 0.5, res + 2.5)) / fa_atlas_size(), 0.0).xyz;\n    if (fa_mesh_fs_params[41].y > 0.5)\n    {\n        v = ((v * 255.0) - vec3(128.0)) * 0.03149606287479400634765625;\n    }\n    return v;\n}\n\nvec3 fa_sh_eval(vec3 c[9], vec3 n)\n{\n    vec3 _3750 = max((((c[0] * 0.2820948064327239990234375) + (((c[1] * (0.3257350027561187744140625 * n.y)) + (c[2] * (0.3257350027561187744140625 * n.z))) + (c[3] * (0.3257350027561187744140625 * n.x)))) + (((c[4] * ((0.2731371223926544189453125 * n.x) * n.y)) + (c[5] * ((0.2731371223926544189453125 * n.y) * n.z))) + (c[6] * (0.078847892582416534423828125 * (((3.0 * n.z) * n.z) - 1.0))))) + ((c[7] * ((0.2731371223926544189453125 * n.x) * n.z)) + (c[8] * (0.13656856119632720947265625 * ((n.x * n.x) - (n.y * n.y))))), vec3(0.0));\n    return _3750;\n}\n\nvec3 fa_ambient_light(vec3 n)\n{\n    float _4361 = (1.0 - fa_mesh_fs_params[42].w) - fa_mesh_fs_params[47].w;\n    vec3 amb = vec3(0.0);\n    bool _4366 = fa_mesh_fs_params[11].w > 0.5;\n    vec3 c[9];\n    for (int k = 0; k < 9; k++)\n    {\n        c[k] = vec3(0.0);\n    }\n    if (_4361 > 0.0005000000237487256526947021484375)\n    {\n        if (_4366)\n        {\n            for (int k_1 = 0; k_1 < 9; k_1++)\n            {\n                vec2 param = fa_mesh_fs_params[41].zw;\n                float param_1 = 128.0;\n                int param_2 = k_1;\n                c[k_1] = fa_probe_sh_coef(param, param_1, param_2) * _4361;\n            }\n        }\n        else\n        {\n            amb = fa_mesh_fs_params[1].xyz * _4361;\n        }\n    }\n    bool _4416 = fa_mesh_fs_params[42].w > 0.0;\n    if (_4416)\n    {\n        for (int k_2 = 0; k_2 < 9; k_2++)\n        {\n            vec2 param_3 = fa_mesh_fs_params[42].xy;\n            float param_4 = fa_mesh_fs_params[42].z;\n            int param_5 = k_2;\n            c[k_2] += (fa_probe_sh_coef(param_3, param_4, param_5) * fa_mesh_fs_params[42].w);\n        }\n    }\n    bool _4447 = fa_mesh_fs_params[47].w > 0.0;\n    if (_4447)\n    {\n        for (int k_3 = 0; k_3 < 9; k_3++)\n        {\n            vec2 param_6 = fa_mesh_fs_params[47].xy;\n            float param_7 = fa_mesh_fs_params[47].z;\n            int param_8 = k_3;\n            c[k_3] += (fa_probe_sh_coef(param_6, param_7, param_8) * fa_mesh_fs_params[47].w);\n        }\n    }\n    if ((_4366 || _4416) || _4447)\n    {\n        vec3 param_9[9] = c;\n        vec3 param_10 = n;\n        amb += fa_sh_eval(param_9, param_10);\n    }\n    return amb;\n}\n\nvec4 fa_gi_fetch(vec2 texel)\n{\n    return textureLod(fa_probe_atlas_fa_env_smp, texel / fa_atlas_size(), 0.0);\n}\n\nvec2 fa_oct_encode(vec3 d)\n{\n    vec3 _3770 = d / vec3(max((abs(d.x) + abs(d.y)) + abs(d.z), 9.9999999600419720025001879548654e-13));\n    float _3773 = _3770.x;\n    float _3775 = _3770.z;\n    vec2 e = vec2(_3773, _3775);\n    if (_3770.y < 0.0)\n    {\n        e = vec2((1.0 - abs(_3775)) * ((_3773 < 0.0) ? (-1.0) : 1.0), (1.0 - abs(_3773)) * ((_3775 < 0.0) ? (-1.0) : 1.0));\n    }\n    return e;\n}\n\nvec3 fa_gi_grid(int rec, vec3 n, vec3 v, out float cover)\n{\n    cover = 0.0;\n    int param = rec;\n    vec4 _6021 = fa_light_texel(param);\n    int param_1 = rec + 1;\n    vec4 _6026 = fa_light_texel(param_1);\n    int param_2 = rec + 2;\n    vec4 _6031 = fa_light_texel(param_2);\n    int param_3 = rec + 3;\n    vec4 _6036 = fa_light_texel(param_3);\n    bool _6039 = _6036.z < 0.5;\n    bool _6047;\n    if (!_6039)\n    {\n        _6047 = fa_atlas_size().y < 1155.0;\n    }\n    else\n    {\n        _6047 = _6039;\n    }\n    if (_6047)\n    {\n        return vec3(0.0);\n    }\n    float _6054 = max(_6021.w, 9.9999997473787516355514526367188e-05);\n    vec3 _6057 = _6026.xyz;\n    vec3 _6061 = _6021.xyz;\n    vec3 _6065 = (fa_world_pos - _6061) / vec3(_6054);\n    vec3 _6074 = min(_6065 + vec3(0.5), (_6057 - vec3(0.5)) - _6065);\n    float _6083 = min(_6074.x, min(_6074.y, _6074.z));\n    if (!(_6083 > 0.0))\n    {\n        return vec3(0.0);\n    }\n    vec3 _6098 = _6057 - vec3(1.0);\n    vec3 _6099 = clamp(_6065, vec3(0.0), _6098);\n    vec3 _6107 = min(floor(_6099), max(_6057 - vec3(2.0), vec3(0.0)));\n    vec3 _6111 = _6099 - _6107;\n    vec3 _6122 = fa_world_pos + (((n * 0.800000011920928955078125) + (v * 0.20000000298023223876953125)) * (0.20000000298023223876953125 * _6054));\n    int _6127 = int(_6031.y + 0.5);\n    float _6132 = 0.3257350027561187744140625 * n.y;\n    float _6136 = 0.3257350027561187744140625 * n.z;\n    float _6140 = 0.3257350027561187744140625 * n.x;\n    float _6147 = (0.2731371223926544189453125 * n.x) * n.y;\n    float _6154 = (0.2731371223926544189453125 * n.y) * n.z;\n    float _6163 = 0.078847892582416534423828125 * (((3.0 * n.z) * n.z) - 1.0);\n    float _6170 = (0.2731371223926544189453125 * n.x) * n.z;\n    float _6183 = 0.13656856119632720947265625 * ((n.x * n.x) - (n.y * n.y));\n    vec3 acc = vec3(0.0);\n    float wsum = 0.0;\n    int _6190 = 8 + int(_6036.w);\n    float _6217;\n    float _6230;\n    float _6244;\n    for (int k = 0; k < _6190; k++)\n    {\n        float _6203 = float(k & 1);\n        float _6207 = float((k >> 1) & 1);\n        float _6211 = float((k >> 2) & 1);\n        if (_6203 > 0.5)\n        {\n            _6217 = _6111.x;\n        }\n        else\n        {\n            _6217 = 1.0 - _6111.x;\n        }\n        if (_6207 > 0.5)\n        {\n            _6230 = _6111.y;\n        }\n        else\n        {\n            _6230 = 1.0 - _6111.y;\n        }\n        if (_6211 > 0.5)\n        {\n            _6244 = _6111.z;\n        }\n        else\n        {\n            _6244 = 1.0 - _6111.z;\n        }\n        float _6254 = (_6217 * _6230) * _6244;\n        if (!(_6254 > 0.0))\n        {\n            continue;\n        }\n        vec3 _6267 = min(_6107 + vec3(_6203, _6207, _6211), _6098);\n        int _6287 = int(((_6031.x + _6267.x) + (_6026.x * (_6267.y + (_6026.y * _6267.z)))) + 0.5);\n        vec2 _6302 = vec2(float(_6287 % _6127) * 10.0, 1024.0 + (float(_6287 / _6127) * 11.0));\n        vec2 param_4 = _6302 + vec2(9.5, 10.5);\n        vec4 _6310 = fa_gi_fetch(param_4);\n        bool _6313 = _6310.y < 0.5;\n        bool _6322;\n        if (!_6313)\n        {\n            _6322 = _6310.x > _6036.y;\n        }\n        else\n        {\n            _6322 = _6313;\n        }\n        if (_6322)\n        {\n            continue;\n        }\n        vec3 _6334 = _6122 - (_6061 + (_6267 * _6054));\n        float _6337 = length(_6334);\n        vec3 _6343 = _6334 / vec3(max(_6337, 9.9999997473787516355514526367188e-05));\n        float _6353 = max(9.9999997473787516355514526367188e-05, (dot(-_6343, n) + 1.0) * 0.5);\n        float w = _6254 * (_6353 * _6353);\n        vec3 param_5 = _6343;\n        vec2 param_6 = (_6302 + vec2(1.0)) + (((fa_oct_encode(param_5) * 0.5) + vec2(0.5)) * 8.0);\n        vec4 _6372 = fa_gi_fetch(param_6);\n        float _6379 = _6337 / max(_6031.z, 9.9999997473787516355514526367188e-05);\n        float _6382 = _6372.x;\n        if (_6379 > _6382)\n        {\n            float _6395 = max(_6372.y - (_6382 * _6382), 0.0);\n            float _6400 = _6379 - _6382;\n            float _6409 = _6395 / max(_6395 + (_6400 * _6400), 9.9999999600419720025001879548654e-13);\n            w *= ((_6409 * _6409) * _6409);\n        }\n        if (!(w > 0.0))\n        {\n            continue;\n        }\n        vec2 param_7 = _6302 + vec2(0.5, 10.5);\n        vec2 param_8 = _6302 + vec2(1.5, 10.5);\n        vec2 param_9 = _6302 + vec2(2.5, 10.5);\n        vec2 param_10 = _6302 + vec2(3.5, 10.5);\n        vec2 param_11 = _6302 + vec2(4.5, 10.5);\n        vec2 param_12 = _6302 + vec2(5.5, 10.5);\n        vec2 param_13 = _6302 + vec2(6.5, 10.5);\n        vec2 param_14 = _6302 + vec2(7.5, 10.5);\n        vec2 param_15 = _6302 + vec2(8.5, 10.5);\n        acc += ((((((((((fa_gi_fetch(param_7).xyz * 0.2820948064327239990234375) + (fa_gi_fetch(param_8).xyz * _6132)) + (fa_gi_fetch(param_9).xyz * _6136)) + (fa_gi_fetch(param_10).xyz * _6140)) + (fa_gi_fetch(param_11).xyz * _6147)) + (fa_gi_fetch(param_12).xyz * _6154)) + (fa_gi_fetch(param_13).xyz * _6163)) + (fa_gi_fetch(param_14).xyz * _6170)) + (fa_gi_fetch(param_15).xyz * _6183)) * w);\n        wsum += w;\n    }\n    if (!(wsum > 9.9999997473787516355514526367188e-06))\n    {\n        return vec3(0.0);\n    }\n    cover = smoothstep(0.0, 1.0, clamp(_6083 * 2.0, 0.0, 1.0)) * smoothstep(0.0, 0.0199999995529651641845703125, wsum);\n    float _6535;\n    if (fa_mesh_fs_params[52].z > 0.5)\n    {\n        _6535 = _6036.x;\n    }\n    else\n    {\n        _6535 = 1.0;\n    }\n    return max(acc / vec3(wsum), vec3(0.0)) * (_6031.w * _6535);\n}\n\nvec3 fa_gi_light(vec3 n, inout float left)\n{\n    left = 1.0;\n    vec3 acc = vec3(0.0);\n    vec3 _6559 = normalize(fa_mesh_fs_params[0].xyz - fa_world_pos);\n    int _6564 = int(fa_mesh_fs_params[52].x + 0.5);\n    int _6569 = int(fa_mesh_fs_params[52].y + 0.5);\n    float param_3;\n    for (int k = 0; (k < _6569) && (k < 8); k++)\n    {\n        int param = _6564 + (4 * k);\n        vec3 param_1 = n;\n        vec3 param_2 = _6559;\n        vec3 _6594 = fa_gi_grid(param, param_1, param_2, param_3);\n        float _6599 = param_3 * left;\n        acc += (_6594 * _6599);\n        left -= _6599;\n        if (left < 0.001000000047497451305389404296875)\n        {\n            left = 0.0;\n            break;\n        }\n    }\n    return acc;\n}\n\nvec3 fa_realtime_or_ambient(vec3 n)\n{\n    vec3 gi = vec3(0.0);\n    float left = 1.0;\n    if (fa_mesh_fs_params[52].y > 0.5)\n    {\n        vec3 param = n;\n        float param_1;\n        vec3 _6628 = fa_gi_light(param, param_1);\n        left = param_1;\n        gi = _6628;\n    }\n    if (left <= 0.0)\n    {\n        return gi;\n    }\n    vec3 param_2 = n;\n    return gi + (fa_ambient_light(param_2) * left);\n}\n\nvec3 fa_indirect_diffuse(vec3 n)\n{\n    if (fa_lm.z > 0.5)\n    {\n        return textureLod(fa_lightmap_fa_env_smp, fa_lm.xy, 0.0).xyz;\n    }\n    if (fa_mesh_fs_params[53].x > 0.5)\n    {\n        vec4 _6670 = vec4(fa_world_pos, 1.0);\n        vec2 _6689 = vec2(dot(fa_mesh_fs_params[26], _6670), dot(fa_mesh_fs_params[27], _6670)) / vec2(max(dot(fa_mesh_fs_params[28], _6670), 9.9999997473787516355514526367188e-05));\n        float _6698;\n        if (fa_mesh_fs_params[24].y > 0.5)\n        {\n            _6698 = (_6689.y * 0.5) + 0.5;\n        }\n        else\n        {\n            _6698 = 0.5 - (_6689.y * 0.5);\n        }\n        return texelFetch(fa_lightmap_fa_env_smp, clamp(ivec2(vec2((_6689.x * 0.5) + 0.5, _6698) * fa_mesh_fs_params[24].zw), ivec2(0), ivec2(fa_mesh_fs_params[24].zw) - ivec2(1)), 0).xyz;\n    }\n    if (fa_mesh_fs_params[32].w > 0.0)\n    {\n        vec3 c[9];\n        for (int k = 0; k < 9; k++)\n        {\n            c[k] = fa_mesh_fs_params[k * 1 + 32].xyz;\n        }\n        vec3 param = n;\n        vec3 param_1[9] = c;\n        vec3 param_2 = n;\n        return mix(fa_ambient_light(param), fa_sh_eval(param_1, param_2), vec3(clamp(fa_mesh_fs_params[32].w, 0.0, 1.0)));\n    }\n    vec3 param_3 = n;\n    return fa_realtime_or_ambient(param_3);\n}\n\nfloat fa_sheen_albedo(float ndv, float rough)\n{\n    float _4579 = min(sqrt(max(rough - 0.100000001490116119384765625, 0.0) * 1.111111164093017578125) * 6.0, 5.999000072479248046875);\n    float _4587 = min(sqrt(clamp(ndv, 0.0, 1.0)) * 8.0, 7.999000072479248046875);\n    int _4590 = int(_4579);\n    int _4593 = int(_4587);\n    float _4603 = _4587 - float(_4593);\n    int _4658 = (_4590 * 9) + _4593;\n    int _4678 = ((_4590 + 1) * 9) + _4593;\n    return mix(mix(_4654[_4658], _4654[_4658 + 1], _4603), mix(_4654[_4678], _4654[_4678 + 1], _4603), _4579 - float(_4590));\n}\n\nFaLayers fa_layers_setup(SurfaceInput i, Surface s, vec3 n, vec3 v, float metallic, float roughness, inout vec3 f0)\n{\n    bool _7382 = false;\n    float _7383 = 1.0;\n    float _7384 = 1.0;\n    float _7385 = 1.0;\n    float _7386 = 0.0;\n    float _7387 = 0.0;\n    float _7388 = 0.0;\n    float _7389 = 0.0;\n    float _7391 = 1.0;\n    bool _7392 = false;\n    vec3 _7393 = vec3(0.0);\n    float _7394 = 1.0;\n    float _7395 = 1.0;\n    float _7396 = 1.0;\n    float _7397 = 0.0;\n    float _7398 = 0.0;\n    vec3 _7399 = vec3(1.0, 0.0, 0.0);\n    vec3 _7400 = vec3(0.0, 0.0, 1.0);\n    float _7401 = 1.0;\n    float _7402 = 1.0;\n    float _4729 = clamp(s.specular, 0.0, 1.0);\n    float _4733 = clamp(s.ior, 1.0, 3.0);\n    bool _4738 = (_4729 != 1.0) || (_4733 != 1.5);\n    bool _4747;\n    if (!_4738)\n    {\n        _4747 = any(notEqual(s.specular_color, vec3(1.0)));\n    }\n    else\n    {\n        _4747 = _4738;\n    }\n    if (_4747)\n    {\n        float _4755 = (_4733 - 1.0) / (_4733 + 1.0);\n        f0 = mix(min(vec3(_4755 * _4755) * max(s.specular_color, vec3(0.0)), vec3(1.0)) * _4729, s.albedo, vec3(metallic));\n        _7383 = mix(_4729, 1.0, metallic);\n        _7382 = true;\n    }\n    float _4782 = clamp(s.clearcoat, 0.0, 1.0);\n    if (_4782 > 0.0)\n    {\n        float _4790 = clamp(s.clearcoat_roughness, 0.0500000007450580596923828125, 1.0);\n        _7386 = _4782;\n        _7387 = _4790;\n        float _4797 = _4790 * _4790;\n        _7388 = _4797;\n        _7389 = _4797 * _4797;\n        float _4809 = max(dot(i.world_normal, v), 9.9999997473787516355514526367188e-05);\n        _7391 = _4809;\n        _7384 = 1.0 - (_4782 * (0.039999999105930328369140625 + (0.959999978542327880859375 * pow(clamp(1.0 - _4809, 0.0, 1.0), 5.0))));\n        _7382 = true;\n    }\n    vec3 _4828 = max(s.sheen_color, vec3(0.0));\n    float _4837 = max(_4828.x, max(_4828.y, _4828.z));\n    if (_4837 > 0.0)\n    {\n        float _4845 = clamp(s.sheen_roughness, 0.100000001490116119384765625, 1.0);\n        _7392 = true;\n        _7393 = _4828;\n        _7394 = _4845;\n        _7395 = _4845 * _4845;\n        float param = max(dot(n, v), 9.9999997473787516355514526367188e-05);\n        float param_1 = _4845;\n        float _4862 = fa_sheen_albedo(param, param_1);\n        _7397 = _4862;\n        _7396 = 1.0 - min(_4837 * _4862, 1.0);\n        _7382 = true;\n    }\n    _7385 = _7384 * _7396;\n    float _4881 = clamp(s.anisotropy, -1.0, 1.0);\n    if (_4881 != 0.0)\n    {\n        vec3 _4896 = i.world_tangent.xyz - (n * dot(n, i.world_tangent.xyz));\n        vec3 t = _4896;\n        if (dot(_4896, _4896) < 9.9999999392252902907785028219223e-09)\n        {\n            bvec3 _4908 = bvec3(abs(n.y) < 0.9900000095367431640625);\n            t = cross(vec3(_4908.x ? vec3(0.0, 1.0, 0.0).x : vec3(1.0, 0.0, 0.0).x, _4908.y ? vec3(0.0, 1.0, 0.0).y : vec3(1.0, 0.0, 0.0).y, _4908.z ? vec3(0.0, 1.0, 0.0).z : vec3(1.0, 0.0, 0.0).z), n);\n        }\n        vec3 _4912 = t;\n        vec3 _4913 = normalize(_4912);\n        t = _4913;\n        vec3 _4938 = normalize((_4913 * cos(s.anisotropy_rotation)) + ((cross(n, _4913) * ((i.world_tangent.w < 0.0) ? (-1.0) : 1.0)) * sin(s.anisotropy_rotation)));\n        _7399 = _4938;\n        _7400 = cross(n, _4938);\n        float _4948 = roughness * roughness;\n        float _4954 = mix(_4948, 1.0, _4881 * _4881);\n        bool _4956 = _4881 > 0.0;\n        _7401 = _4956 ? _4954 : _4948;\n        _7402 = _4956 ? _4948 : _4954;\n        _7398 = _4881;\n        _7382 = true;\n    }\n    return FaLayers(_7382, _7383, _7384, _7385, _7386, _7387, _7388, _7389, i.world_normal, _7391, _7392, _7393, _7394, _7395, _7396, _7397, _7398, _7399, _7400, _7401, _7402);\n}\n\nvec2 fa_env_brdf(float rough, float ndv)\n{\n    vec4 _4511 = (vec4(-1.0, -0.0274999998509883880615234375, -0.572000026702880859375, 0.02199999988079071044921875) * rough) + vec4(1.0, 0.0425000004470348358154296875, 1.03999996185302734375, -0.039999999105930328369140625);\n    float _4514 = _4511.x;\n    return (vec2(-1.03999996185302734375, 1.03999996185302734375) * ((min(_4514 * _4514, exp2((-9.27999973297119140625) * ndv)) * _4514) + _4511.y)) + _4511.zw;\n}\n\nvec3 fa_probe_level(vec2 origin, float res, int lv, vec2 e)\n{\n    float _3822;\n    if (lv == 0)\n    {\n        _3822 = 0.0;\n    }\n    else\n    {\n        _3822 = res + 2.0;\n    }\n    float _3832;\n    if (lv == 0)\n    {\n        _3832 = 0.0;\n    }\n    else\n    {\n        _3832 = (res - (res / float(1 << max((lv - 1), 0)))) + (2.0 * float(lv - 1));\n    }\n    return textureLod(fa_probe_atlas_fa_env_smp, (((origin + vec2(_3822, _3832)) + vec2(1.0)) + (((e * 0.5) + vec2(0.5)) * (res / float(1 << lv)))) / fa_atlas_size(), 0.0).xyz;\n}\n\nvec3 fa_probe_radiance(vec2 origin, float res, vec3 d, float rough)\n{\n    float _3878;\n    if (res > 64.5)\n    {\n        _3878 = 5.0;\n    }\n    else\n    {\n        _3878 = (res > 32.5) ? 4.0 : 3.0;\n    }\n    float _3893 = clamp(rough, 0.0, 1.0) * (_3878 - 1.0);\n    int _3900 = int(min(floor(_3893), _3878 - 2.0));\n    float _3905 = _3893 - float(_3900);\n    vec3 param = d;\n    vec2 _3909 = fa_oct_encode(param);\n    vec2 param_1 = origin;\n    float param_2 = res;\n    int param_3 = _3900;\n    vec2 param_4 = _3909;\n    vec3 _3919 = fa_probe_level(param_1, param_2, param_3, param_4);\n    if (_3905 < 0.00200000009499490261077880859375)\n    {\n        return _3919;\n    }\n    vec2 param_5 = origin;\n    float param_6 = res;\n    int param_7 = _3900 + 1;\n    vec2 param_8 = _3909;\n    return mix(_3919, fa_probe_level(param_5, param_6, param_7, param_8), vec3(_3905));\n}\n\nvec3 fa_probe_box_dir(vec3 d, vec4 posw, vec4 bx, vec4 by, vec4 bz)\n{\n    if (posw.w < 0.5)\n    {\n        return d;\n    }\n    float _3990 = dot(bx.xyz, fa_world_pos) + bx.w;\n    float _3997 = dot(by.xyz, fa_world_pos) + by.w;\n    float _4004 = dot(bz.xyz, fa_world_pos) + bz.w;\n    float _4010 = dot(bx.xyz, d);\n    float _4014 = dot(by.xyz, d);\n    float _4018 = dot(bz.xyz, d);\n    float _4024;\n    if (_4010 > 9.9999999747524270787835121154785e-07)\n    {\n        _4024 = (1.0 - _3990) / _4010;\n    }\n    else\n    {\n        float _4038;\n        if (_4010 < (-9.9999999747524270787835121154785e-07))\n        {\n            _4038 = ((-1.0) - _3990) / _4010;\n        }\n        else\n        {\n            _4038 = 1000000015047466219876688855040.0;\n        }\n        _4024 = _4038;\n    }\n    float tx = _4024;\n    float _4055;\n    if (_4014 > 9.9999999747524270787835121154785e-07)\n    {\n        _4055 = (1.0 - _3997) / _4014;\n    }\n    else\n    {\n        float _4068;\n        if (_4014 < (-9.9999999747524270787835121154785e-07))\n        {\n            _4068 = ((-1.0) - _3997) / _4014;\n        }\n        else\n        {\n            _4068 = 1000000015047466219876688855040.0;\n        }\n        _4055 = _4068;\n    }\n    float ty = _4055;\n    float _4084;\n    if (_4018 > 9.9999999747524270787835121154785e-07)\n    {\n        _4084 = (1.0 - _4004) / _4018;\n    }\n    else\n    {\n        float _4097;\n        if (_4018 < (-9.9999999747524270787835121154785e-07))\n        {\n            _4097 = ((-1.0) - _4004) / _4018;\n        }\n        else\n        {\n            _4097 = 1000000015047466219876688855040.0;\n        }\n        _4084 = _4097;\n    }\n    float _4109 = tx;\n    float _4112 = (_4109 > 0.0) ? _4109 : 1000000015047466219876688855040.0;\n    tx = _4112;\n    float _4113 = ty;\n    float _4116 = (_4113 > 0.0) ? _4113 : 1000000015047466219876688855040.0;\n    ty = _4116;\n    float _4126 = min(_4112, min(_4116, (_4084 > 0.0) ? _4084 : 1000000015047466219876688855040.0));\n    if (_4126 > 100000001504746621987668885504.0)\n    {\n        return d;\n    }\n    vec3 _4142 = (fa_world_pos + (d * _4126)) - posw.xyz;\n    vec3 _4147;\n    if (dot(_4142, _4142) > 1.0000000133514319600180897396058e-10)\n    {\n        _4147 = normalize(_4142);\n    }\n    else\n    {\n        _4147 = d;\n    }\n    return _4147;\n}\n\nvec3 fa_probe_environment(vec4 tile, vec4 posw, vec4 bx, vec4 by, vec4 bz, inout vec3 d, float rough)\n{\n    vec3 param = d;\n    vec4 param_1 = posw;\n    vec4 param_2 = bx;\n    vec4 param_3 = by;\n    vec4 param_4 = bz;\n    d = fa_probe_box_dir(param, param_1, param_2, param_3, param_4);\n    vec2 param_5 = tile.xy;\n    float param_6 = tile.z;\n    vec3 param_7 = d;\n    float param_8 = rough;\n    return fa_probe_radiance(param_5, param_6, param_7, param_8);\n}\n\nvec3 fa_environment(vec3 d, float rough)\n{\n    float _4193 = (1.0 - fa_mesh_fs_params[42].w) - fa_mesh_fs_params[47].w;\n    vec3 outc = vec3(0.0);\n    if (_4193 > 0.0005000000237487256526947021484375)\n    {\n        vec3 base;\n        if (fa_mesh_fs_params[11].w > 0.5)\n        {\n            vec2 param = fa_mesh_fs_params[41].zw;\n            float param_1 = 128.0;\n            vec3 param_2 = d;\n            float param_3 = rough;\n            base = fa_probe_radiance(param, param_1, param_2, param_3);\n        }\n        else\n        {\n            float _4221 = rough * rough;\n            float _4252 = 0.60000002384185791015625 * _4221;\n            base = mix(mix(fa_mesh_fs_params[12].xyz * 0.550000011920928955078125, mix(fa_mesh_fs_params[12].xyz, fa_mesh_fs_params[11].xyz, vec3(pow(clamp(d.y * (1.0 - (0.699999988079071044921875 * _4221)), 0.0, 1.0), 0.550000011920928955078125))), vec3(smoothstep((-0.0500000007450580596923828125) - _4252, 0.0500000007450580596923828125 + _4252, d.y))), ((fa_mesh_fs_params[11].xyz + fa_mesh_fs_params[12].xyz) * 0.5) * 0.800000011920928955078125, vec3(_4221 * 0.60000002384185791015625));\n        }\n        outc = base * _4193;\n    }\n    if (fa_mesh_fs_params[42].w > 0.0)\n    {\n        vec4 param_4 = fa_mesh_fs_params[42];\n        vec4 param_5 = fa_mesh_fs_params[43];\n        vec4 param_6 = fa_mesh_fs_params[44];\n        vec4 param_7 = fa_mesh_fs_params[45];\n        vec4 param_8 = fa_mesh_fs_params[46];\n        vec3 param_9 = d;\n        float param_10 = rough;\n        vec3 _4311 = fa_probe_environment(param_4, param_5, param_6, param_7, param_8, param_9, param_10);\n        outc += (_4311 * fa_mesh_fs_params[42].w);\n    }\n    if (fa_mesh_fs_params[47].w > 0.0)\n    {\n        vec4 param_11 = fa_mesh_fs_params[47];\n        vec4 param_12 = fa_mesh_fs_params[48];\n        vec4 param_13 = fa_mesh_fs_params[49];\n        vec4 param_14 = fa_mesh_fs_params[50];\n        vec4 param_15 = fa_mesh_fs_params[51];\n        vec3 param_16 = d;\n        float param_17 = rough;\n        vec3 _4343 = fa_probe_environment(param_11, param_12, param_13, param_14, param_15, param_16, param_17);\n        outc += (_4343 * fa_mesh_fs_params[47].w);\n    }\n    return outc;\n}\n\nvec3 fa_layers_ibl(FaLayers L, vec3 n, vec3 v, vec3 f0, float roughness, float occlusion)\n{\n    vec3 rn = n;\n    if (L.aniso != 0.0)\n    {\n        vec3 _4989;\n        if (L.aniso >= 0.0)\n        {\n            _4989 = L.b;\n        }\n        else\n        {\n            _4989 = L.t;\n        }\n        rn = normalize(mix(n, cross(cross(_4989, v), _4989), vec3(abs(L.aniso) * smoothstep(0.0, 0.25, roughness))));\n    }\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05);\n    vec2 _5025 = fa_env_brdf(param, param_1);\n    vec3 param_2 = reflect(-v, rn);\n    float param_3 = roughness;\n    vec3 result = (fa_environment(param_2, param_3) * ((f0 * _5025.x) + (vec3(L.f90) * _5025.y))) * L.base_scale;\n    if (L.sheen_on)\n    {\n        vec3 param_4 = n;\n        float param_5 = L.sheen_rough;\n        result += ((L.sheen * (L.sheen_e * L.keep)) * fa_environment(param_4, param_5));\n    }\n    result *= occlusion;\n    if (L.coat > 0.0)\n    {\n        float param_6 = L.coat_rough;\n        float param_7 = L.coat_ndv;\n        vec2 _5083 = fa_env_brdf(param_6, param_7);\n        vec3 param_8 = reflect(-v, L.nc);\n        float param_9 = L.coat_rough;\n        result += (fa_environment(param_8, param_9) * (L.coat * ((0.039999999105930328369140625 * _5083.x) + _5083.y)));\n    }\n    return result;\n}\n\nvec3 fa_sky_reflection(vec3 n, vec3 v, vec3 f0, float roughness)\n{\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05);\n    vec2 _4553 = fa_env_brdf(param, param_1);\n    vec3 param_2 = reflect(-v, n);\n    float param_3 = roughness;\n    return fa_environment(param_2, param_3) * ((f0 * _4553.x) + vec3(_4553.y));\n}\n\nvec3 fa_sky_light(SurfaceInput i, Surface s)\n{\n    float _5112 = clamp(s.metallic, 0.0, 1.0);\n    float _5116 = clamp(s.roughness, 0.0500000007450580596923828125, 1.0);\n    vec3 _5123 = mix(vec3(0.039999999105930328369140625), s.albedo, vec3(_5112));\n    vec3 f0 = _5123;\n    vec3 _5127 = normalize(s.normal);\n    SurfaceInput param = i;\n    Surface param_1 = s;\n    vec3 param_2 = _5127;\n    vec3 param_3 = i.view_dir;\n    float param_4 = _5112;\n    float param_5 = _5116;\n    vec3 param_6 = _5123;\n    FaLayers _5144 = fa_layers_setup(param, param_1, param_2, param_3, param_4, param_5, param_6);\n    f0 = param_6;\n    if (_5144.on)\n    {\n        FaLayers param_7 = _5144;\n        vec3 param_8 = _5127;\n        vec3 param_9 = i.view_dir;\n        vec3 param_10 = f0;\n        float param_11 = _5116;\n        float param_12 = s.occlusion;\n        return fa_layers_ibl(param_7, param_8, param_9, param_10, param_11, param_12);\n    }\n    vec3 param_13 = _5127;\n    vec3 param_14 = i.view_dir;\n    vec3 param_15 = f0;\n    float param_16 = _5116;\n    return fa_sky_reflection(param_13, param_14, param_15, param_16) * s.occlusion;\n}\n\nvec3 ambient(SurfaceInput i, Surface s, vec3 ambientColor)\n{\n    SurfaceInput param = i;\n    Surface param_1 = s;\n    return fa_sky_light(param, param_1);\n}\n\nint fa_cluster_index(int slot, int n)\n{\n    int param = (int(fa_mesh_fs_params[19].x) + int(fa_mesh_fs_params[19].w)) + ((slot + n) >> 2);\n    vec4 t = fa_light_texel(param);\n    return int(t[(slot + n) & 3]);\n}\n\nint fa_cl_light(int n)\n{\n    if (n < fa_cl_ndir)\n    {\n        return n;\n    }\n    int param = fa_cl_slot;\n    int param_1 = n - fa_cl_ndir;\n    return fa_cluster_index(param, param_1);\n}\n\nint fa_light_base(int li)\n{\n    return li * ((fa_mesh_fs_params[1].w > 4.5) ? 8 : 4);\n}\n\nbool fa_light_baked(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 3;\n    return fa_light_texel(param_1).w > 0.5;\n}\n\nfloat fa_baked_keep(int li)\n{\n    float _5439;\n    if (fa_lm.z > 0.5)\n    {\n        _5439 = 0.0;\n    }\n    else\n    {\n        _5439 = 1.0 - clamp(fa_mesh_fs_params[32].w, 0.0, 1.0);\n    }\n    bool _5450 = _5439 < 1.0;\n    bool _5456;\n    if (_5450)\n    {\n        int param = li;\n        _5456 = fa_light_baked(param);\n    }\n    else\n    {\n        _5456 = _5450;\n    }\n    return _5456 ? _5439 : 1.0;\n}\n\nfloat fa_light_type(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 1;\n    return fa_light_texel(param_1).w;\n}\n\nvec3 fa_area_point(vec3 c, vec3 axis, vec3 ru, vec3 uu, float hx, float hy, float shape, vec3 p, vec3 r)\n{\n    bool _685 = dot(r, r) > 0.5;\n    if (shape > 1.5)\n    {\n        vec3 _698 = (c - (ru * hx)) - p;\n        vec3 _704 = ru * (2.0 * hx);\n        float _710 = max(dot(_704, _704), 9.9999999392252902907785028219223e-09);\n        float _714 = dot(_698, _704);\n        float t = clamp((-_714) / _710, 0.0, 1.0);\n        if (_685)\n        {\n            float _729 = dot(r, _704);\n            float _735 = _710 - (_729 * _729);\n            if (abs(_735) > (9.9999997473787516355514526367188e-06 * _710))\n            {\n                t = clamp(((dot(r, _698) * _729) - _714) / _735, 0.0, 1.0);\n            }\n        }\n        return (p + _698) + (_704 * t);\n    }\n    vec3 q = p;\n    float _767 = dot(r, axis);\n    bool _775;\n    if (_685)\n    {\n        _775 = abs(_767) > 9.9999997473787516355514526367188e-05;\n    }\n    else\n    {\n        _775 = _685;\n    }\n    if (_775)\n    {\n        float _785 = dot(c - p, axis) / _767;\n        if (_785 > 0.0)\n        {\n            q = p + (r * _785);\n        }\n    }\n    vec3 _798 = q - c;\n    vec2 xy = vec2(dot(_798, ru), dot(_798, uu));\n    if (shape > 0.5)\n    {\n        float _813 = length(xy);\n        if (_813 > hx)\n        {\n            xy *= (hx / _813);\n        }\n    }\n    else\n    {\n        xy = clamp(xy, vec2(-hx, -hy), vec2(hx, hy));\n    }\n    return (c + (ru * xy.x)) + (uu * xy.y);\n}\n\nvec4 fa_atlas_fetch(vec2 texel)\n{\n    return textureLod(fa_light_atlas_fa_env_smp, texel / vec2(textureSize(fa_light_atlas_fa_env_smp, 0)), 0.0);\n}\n\nvec3 fa_cookie_sample(vec2 tile_origin, vec2 uv)\n{\n    vec2 param = (tile_origin + vec2(1.0)) + (clamp(uv, vec2(0.0), vec2(1.0)) * 254.0);\n    return fa_atlas_fetch(param).xyz;\n}\n\nfloat fa_ies_sample(vec2 tile_origin, vec3 d, vec3 axis, vec3 right, vec3 up)\n{\n    float _605 = dot(d, right);\n    float _609 = dot(d, up);\n    float _620;\n    if (((_605 * _605) + (_609 * _609)) > 1.0000000133514319600180897396058e-10)\n    {\n        _620 = atan(_609, _605) * 0.15915493667125701904296875;\n    }\n    else\n    {\n        _620 = 0.0;\n    }\n    vec2 param = tile_origin + vec2(1.0 + ((_620 - floor(_620)) * 64.0), 1.0 + (acos(clamp(dot(d, axis), -1.0, 1.0)) * 10.18591594696044921875));\n    return fa_atlas_fetch(param).x;\n}\n\nint fa_cube_face(vec3 d)\n{\n    vec3 _456 = abs(d);\n    float _458 = _456.x;\n    float _460 = _456.y;\n    bool _461 = _458 >= _460;\n    bool _469;\n    if (_461)\n    {\n        _469 = _458 >= _456.z;\n    }\n    else\n    {\n        _469 = _461;\n    }\n    int _470;\n    if (_469)\n    {\n        _470 = (d.x > 0.0) ? 0 : 1;\n    }\n    else\n    {\n        int _484;\n        if (_460 >= _456.z)\n        {\n            _484 = (d.y > 0.0) ? 2 : 3;\n        }\n        else\n        {\n            _484 = (d.z > 0.0) ? 4 : 5;\n        }\n        _470 = _484;\n    }\n    return _470;\n}\n\nvoid fa_cube_face_basis(int f, out vec3 fwd, out vec3 up)\n{\n    if (f == 0)\n    {\n        fwd = vec3(1.0, 0.0, 0.0);\n        up = vec3(0.0, 1.0, 0.0);\n    }\n    else\n    {\n        if (f == 1)\n        {\n            fwd = vec3(-1.0, 0.0, 0.0);\n            up = vec3(0.0, 1.0, 0.0);\n        }\n        else\n        {\n            if (f == 2)\n            {\n                fwd = vec3(0.0, 1.0, 0.0);\n                up = vec3(0.0, 0.0, 1.0);\n            }\n            else\n            {\n                if (f == 3)\n                {\n                    fwd = vec3(0.0, -1.0, 0.0);\n                    up = vec3(0.0, 0.0, -1.0);\n                }\n                else\n                {\n                    if (f == 4)\n                    {\n                        fwd = vec3(0.0, 0.0, 1.0);\n                        up = vec3(0.0, 1.0, 0.0);\n                    }\n                    else\n                    {\n                        fwd = vec3(0.0, 0.0, -1.0);\n                        up = vec3(0.0, 1.0, 0.0);\n                    }\n                }\n            }\n        }\n    }\n}\n\nLightSample fa_light_sample_n(int li, vec3 world_pos, vec3 n)\n{\n    int param = li;\n    int _851 = fa_light_base(param);\n    bool _855 = fa_mesh_fs_params[1].w > 4.5;\n    int param_1 = _851;\n    vec4 _859 = fa_light_texel(param_1);\n    int param_2 = _851 + 1;\n    vec4 _864 = fa_light_texel(param_2);\n    float _867 = _864.w;\n    float atten = 1.0;\n    float dist = 0.0;\n    fa_light_tint = vec3(1.0);\n    bool _879 = _855 && (_867 > 2.5);\n    fa_light_is_area = _879;\n    bool _881 = _867 < 0.5;\n    vec3 l;\n    if (_881)\n    {\n        l = normalize(_859.xyz);\n        if (_855)\n        {\n            int param_3 = _851 + 6;\n            vec4 _895 = fa_light_texel(param_3);\n            if (_895.z > 0.5)\n            {\n                int param_4 = _851 + 4;\n                vec4 _905 = fa_light_texel(param_4);\n                int param_5 = _851 + 5;\n                vec4 _910 = fa_light_texel(param_5);\n                vec2 param_6 = _895.xy;\n                vec2 param_7 = fract(vec2(dot(world_pos, _905.xyz) * _905.w, (-dot(world_pos, _910.xyz)) * _910.w) + vec2(0.5));\n                fa_light_tint = fa_cookie_sample(param_6, param_7);\n            }\n        }\n    }\n    else\n    {\n        vec3 _940 = _859.xyz;\n        vec3 _942 = _940 - world_pos;\n        vec3 to_light = _942;\n        float _945 = length(_942);\n        float reach = _945;\n        bool front = true;\n        if (_879)\n        {\n            int param_8 = _851 + 7;\n            reach = max(_945 - fa_light_texel(param_8).w, 0.0);\n            int param_9 = _851 + 4;\n            vec4 _969 = fa_light_texel(param_9);\n            int param_10 = _851 + 5;\n            vec4 _974 = fa_light_texel(param_10);\n            int param_11 = _851 + 6;\n            vec4 _979 = fa_light_texel(param_11);\n            float _980 = _979.w;\n            int param_12 = _851 + 2;\n            vec3 _987 = normalize(fa_light_texel(param_12).xyz);\n            bool _989 = _980 > 1.5;\n            bool _997;\n            if (!_989)\n            {\n                _997 = dot(_987, to_light) < 0.0;\n            }\n            else\n            {\n                _997 = _989;\n            }\n            front = _997;\n            vec3 r = vec3(0.0);\n            vec3 _1006 = fa_mesh_fs_params[0].xyz - world_pos;\n            bool _1010 = dot(n, n) > 0.5;\n            bool _1018;\n            if (_1010)\n            {\n                _1018 = dot(_1006, _1006) > 9.9999999600419720025001879548654e-13;\n            }\n            else\n            {\n                _1018 = _1010;\n            }\n            if (_1018)\n            {\n                r = reflect(-normalize(_1006), normalize(n));\n            }\n            vec3 param_13 = _940;\n            vec3 param_14 = _987;\n            vec3 param_15 = _969.xyz;\n            vec3 param_16 = _974.xyz;\n            float param_17 = _969.w;\n            float param_18 = _974.w;\n            float param_19 = _980;\n            vec3 param_20 = world_pos;\n            vec3 param_21 = r;\n            to_light = fa_area_point(param_13, param_14, param_15, param_16, param_17, param_18, param_19, param_20, param_21) - world_pos;\n        }\n        float _1054 = length(to_light);\n        dist = _1054;\n        l = to_light / vec3(max(_1054, 9.9999997473787516355514526367188e-05));\n        float _1068 = reach / max(_859.w, 0.001000000047497451305389404296875);\n        float _1074 = clamp(1.0 - (_1068 * _1068), 0.0, 1.0);\n        float _1076;\n        if (front)\n        {\n            _1076 = _1074 * _1074;\n        }\n        else\n        {\n            _1076 = 0.0;\n        }\n        atten = _1076;\n        bool _1087 = _867 < 2.5;\n        if ((_867 > 1.5) && _1087)\n        {\n            int param_22 = _851 + 2;\n            vec4 _1095 = fa_light_texel(param_22);\n            float _1105 = _1095.w;\n            int param_23 = _851 + 3;\n            vec4 _1110 = fa_light_texel(param_23);\n            float _1111 = _1110.x;\n            float cos_inner = _1111;\n            if (_1111 > 1.5)\n            {\n                cos_inner = mix(_1105, 1.0, 0.25);\n            }\n            atten *= smoothstep(_1105, cos_inner, dot(-l, normalize(_1095.xyz)));\n        }\n        if (_855 && (_867 < 1.5))\n        {\n            int param_24 = _851 + 6;\n            vec4 _1135 = fa_light_texel(param_24);\n            if (_1135.z > 0.5)\n            {\n                vec3 _1143 = -to_light;\n                int param_25 = _851 + 4;\n                int param_26 = _851 + 5;\n                vec3 _1157 = fa_light_texel(param_25).xyz;\n                vec3 _1161 = fa_light_texel(param_26).xyz;\n                vec3 _1170 = vec3(dot(_1143, _1157), dot(_1143, _1161), dot(_1143, cross(_1157, _1161)));\n                vec3 param_27 = _1170;\n                int _1174 = fa_cube_face(param_27);\n                int param_28 = _1174;\n                vec3 param_29;\n                vec3 param_30;\n                fa_cube_face_basis(param_28, param_29, param_30);\n                vec2 _1201 = vec2(dot(_1170, cross(param_29, param_30)), dot(_1170, param_30)) / vec2(max(dot(_1170, param_29), 9.9999997473787516355514526367188e-05));\n                int _1205 = _1174 / 3;\n                vec2 param_31 = _1135.xy + (vec2(float(_1174 - (_1205 * 3)), float(_1205)) * 256.0);\n                vec2 param_32 = vec2(0.5 + (0.5 * _1201.x), 0.5 - (0.5 * _1201.y));\n                fa_light_tint = fa_cookie_sample(param_31, param_32);\n            }\n            int param_33 = _851 + 7;\n            vec4 _1235 = fa_light_texel(param_33);\n            if (_1235.z > 0.5)\n            {\n                int param_34 = _851 + 2;\n                int param_35 = _851 + 4;\n                int param_36 = _851 + 5;\n                vec2 param_37 = _1235.xy;\n                vec3 param_38 = -l;\n                vec3 param_39 = normalize(fa_light_texel(param_34).xyz);\n                vec3 param_40 = fa_light_texel(param_35).xyz;\n                vec3 param_41 = fa_light_texel(param_36).xyz;\n                atten *= fa_ies_sample(param_37, param_38, param_39, param_40, param_41);\n            }\n        }\n        else\n        {\n            if (_855 && _1087)\n            {\n                int param_42 = _851 + 6;\n                vec4 _1282 = fa_light_texel(param_42);\n                int param_43 = _851 + 7;\n                vec4 _1287 = fa_light_texel(param_43);\n                bool _1290 = _1282.z > 0.5;\n                bool _1297;\n                if (!_1290)\n                {\n                    _1297 = _1287.z > 0.5;\n                }\n                else\n                {\n                    _1297 = _1290;\n                }\n                if (_1297)\n                {\n                    int param_44 = _851 + 2;\n                    vec4 _1304 = fa_light_texel(param_44);\n                    vec3 _1308 = normalize(_1304.xyz);\n                    int param_45 = _851 + 4;\n                    vec4 _1313 = fa_light_texel(param_45);\n                    int param_46 = _851 + 5;\n                    vec4 _1318 = fa_light_texel(param_46);\n                    if (_1290)\n                    {\n                        vec3 _1326 = -to_light;\n                        float _1333 = _1304.w;\n                        float _1349 = 0.5 / max(dot(_1326, _1308) * (sqrt(max(1.0 - (_1333 * _1333), 0.0)) / max(_1333, 0.001000000047497451305389404296875)), 9.9999997473787516355514526367188e-05);\n                        vec2 param_47 = _1282.xy;\n                        vec2 param_48 = vec2(0.5 + (dot(_1326, _1313.xyz) * _1349), 0.5 - (dot(_1326, _1318.xyz) * _1349));\n                        fa_light_tint = fa_cookie_sample(param_47, param_48);\n                    }\n                    if (_1287.z > 0.5)\n                    {\n                        vec2 param_49 = _1287.xy;\n                        vec3 param_50 = -l;\n                        vec3 param_51 = _1308;\n                        vec3 param_52 = _1313.xyz;\n                        vec3 param_53 = _1318.xyz;\n                        atten *= fa_ies_sample(param_49, param_50, param_51, param_52, param_53);\n                    }\n                }\n            }\n        }\n    }\n    vec3 _7370 = _864.xyz * atten;\n    if (_855)\n    {\n        _7370 *= fa_light_tint;\n    }\n    int _1417;\n    if (_881)\n    {\n        _1417 = 0;\n    }\n    else\n    {\n        _1417 = ((_867 > 1.5) && (_867 < 2.5)) ? 2 : 1;\n    }\n    return LightSample(l, _7370, atten, 1.0, dist, _1417);\n}\n\nfloat fa_shadow_depth(inout vec2 uv, vec4 rect)\n{\n    uv = clamp(uv, rect.xy, rect.zw);\n    return textureLod(fa_shadow_tex_fa_shadow_smp, uv, 0.0).x;\n}\n\nfloat fa_shadow_fetch(vec2 uv, vec4 rect, vec3 conv)\n{\n    vec2 param = uv;\n    vec4 param_1 = rect;\n    float _2206 = fa_shadow_depth(param, param_1);\n    float _2210;\n    if (conv.x < 0.5)\n    {\n        _2210 = _2206;\n    }\n    else\n    {\n        _2210 = (conv.y * conv.z) / (conv.z - (_2206 * (conv.z - conv.y)));\n    }\n    return _2210;\n}\n\nfloat fa_shadow_noise()\n{\n    return fract(52.98291778564453125 * fract(dot(gl_FragCoord.xy, vec2(0.067110560834407806396484375, 0.005837149918079376220703125))));\n}\n\nvec2 fa_shadow_vogel_turn(vec2 d)\n{\n    return vec2((d.x * (-0.737368881702423095703125)) - (d.y * 0.675490319728851318359375), (d.y * (-0.737368881702423095703125)) + (d.x * 0.675490319728851318359375));\n}\n\nfloat fa_shadow_filter(vec2 uv, vec4 rect, float zr, float texel_m, float unit, float reach, float plane, vec3 conv, int mode, float k)\n{\n    if (mode == 1)\n    {\n        vec2 param = uv;\n        vec4 param_1 = rect;\n        vec3 param_2 = conv;\n        return float(zr <= fa_shadow_fetch(param, param_1, param_2));\n    }\n    float _2256 = fa_shadow_noise() * 6.283185482025146484375;\n    vec2 _2262 = vec2(cos(_2256), sin(_2256));\n    vec2 dir = _2262;\n    float radius = 1.5;\n    if (mode == 2)\n    {\n        float _2271;\n        if (k < 0.0)\n        {\n            _2271 = (-k) / max(zr, 0.100000001490116119384765625);\n        }\n        else\n        {\n            _2271 = k;\n        }\n        float _2290 = clamp((_2271 * reach) / texel_m, 3.0, 12.0);\n        float sum = 0.0;\n        float cnt = 0.0;\n        for (int i = 0; i < 16; i++)\n        {\n            float _2309 = sqrt((float(i) + 0.5) * 0.0625) * _2290;\n            vec2 param_3 = uv + (dir * (fa_shadows[26].zw * _2309));\n            vec4 param_4 = rect;\n            vec3 param_5 = conv;\n            float _2323 = fa_shadow_fetch(param_3, param_4, param_5);\n            if (_2323 < (zr - (_2309 * plane)))\n            {\n                sum += _2323;\n                cnt += 1.0;\n            }\n            vec2 param_6 = dir;\n            dir = fa_shadow_vogel_turn(param_6);\n        }\n        if (cnt < 0.5)\n        {\n            return 1.0;\n        }\n        float _2351 = sum / cnt;\n        float _2361;\n        if (k < 0.0)\n        {\n            _2361 = (-k) / max(_2351, 0.0500000007450580596923828125);\n        }\n        else\n        {\n            _2361 = k;\n        }\n        radius = clamp(((max(zr - _2351, 0.0) * unit) * _2361) / texel_m, 1.5, 16.0);\n        dir = _2262;\n    }\n    float lit = 0.0;\n    int _2387 = (mode == 2) ? 24 : 16;\n    for (int i_1 = 0; i_1 < _2387; i_1++)\n    {\n        float _2406 = sqrt((float(i_1) + 0.5) / float(_2387)) * radius;\n        vec2 param_7 = uv + (dir * (fa_shadows[26].zw * _2406));\n        vec4 param_8 = rect;\n        vec3 param_9 = conv;\n        lit += float((zr - (_2406 * plane)) <= fa_shadow_fetch(param_7, param_8, param_9));\n        vec2 param_10 = dir;\n        dir = fa_shadow_vogel_turn(param_10);\n    }\n    return lit / float(_2387);\n}\n\nfloat fa_shadow_local(int li, vec3 lpos, vec3 world, vec3 n, vec3 l)\n{\n    bool _2611 = fa_mesh_fs_params[5].z < 0.5;\n    bool _2618;\n    if (!_2611)\n    {\n        _2618 = fa_shadows[29].x < 0.5;\n    }\n    else\n    {\n        _2618 = _2611;\n    }\n    if (_2618)\n    {\n        return 1.0;\n    }\n    int param = (int(fa_shadows[29].x + 0.5) - 1) + li;\n    vec4 _2631 = fa_light_texel(param);\n    float _2632 = _2631.x;\n    if (_2632 < 0.0)\n    {\n        return 1.0;\n    }\n    int _2641 = int(_2632 + 0.5);\n    int param_1 = _2641;\n    vec4 _2645 = fa_light_texel(param_1);\n    int param_2 = _2641 + 1;\n    vec4 _2650 = fa_light_texel(param_2);\n    float fade = 1.0;\n    float _2653 = _2645.y;\n    if (_2653 > 0.0)\n    {\n        float _2670 = 1.0 - smoothstep(0.75 * _2653, _2653, length(world - fa_shadows[27].xyz));\n        fade = _2670;\n        if (_2670 <= 0.0)\n        {\n            return 1.0;\n        }\n    }\n    int face = 0;\n    if (_2645.x > 1.5)\n    {\n        vec3 param_3 = world - lpos;\n        face = fa_cube_face(param_3);\n    }\n    int _2694 = (_2641 + 2) + (face * 6);\n    int param_4 = _2694;\n    int param_5 = _2694 + 1;\n    int param_6 = _2694 + 3;\n    vec4 _2708 = fa_light_texel(param_6);\n    int param_7 = _2694 + 4;\n    vec4 _2713 = fa_light_texel(param_7);\n    int param_8 = _2694 + 5;\n    vec4 _2718 = fa_light_texel(param_8);\n    float _2730 = _2718.x * max(dot(_2708, vec4(world, 1.0)), 0.001000000047497451305389404296875);\n    float _2735 = clamp(dot(n, l), 0.0, 1.0);\n    float _2758 = clamp(dot(n, _2708.xyz), -1.0, 1.0);\n    float _2777 = min(sqrt(1.0 - (_2758 * _2758)) / max(abs(dot(n, world - lpos)) / max(dot(_2708, vec4(world, 1.0)), 0.001000000047497451305389404296875), 0.20000000298023223876953125), 4.0);\n    float _2780 = _2650.y;\n    float _2782;\n    if (_2780 > 0.0)\n    {\n        _2782 = _2780;\n    }\n    else\n    {\n        _2782 = 1.5 * _2730;\n    }\n    vec4 _2802 = vec4(world + (n * (_2782 * sqrt(1.0 - (_2735 * _2735)))), 1.0);\n    float _2806 = dot(_2708, _2802);\n    float _2809 = _2718.y;\n    if (_2806 < _2809)\n    {\n        return 1.0;\n    }\n    vec2 _2824 = vec2(dot(fa_light_texel(param_4), _2802), dot(fa_light_texel(param_5), _2802)) / vec2(_2806);\n    float _2826 = _2824.x;\n    bool _2829 = _2826 < _2713.x;\n    bool _2838;\n    if (!_2829)\n    {\n        _2838 = _2826 > _2713.z;\n    }\n    else\n    {\n        _2838 = _2829;\n    }\n    bool _2847;\n    if (!_2838)\n    {\n        _2847 = _2824.y < _2713.y;\n    }\n    else\n    {\n        _2847 = _2838;\n    }\n    bool _2856;\n    if (!_2847)\n    {\n        _2856 = _2824.y > _2713.w;\n    }\n    else\n    {\n        _2856 = _2847;\n    }\n    if (_2856)\n    {\n        return 1.0;\n    }\n    float _2862 = _2650.x;\n    float _2864;\n    if (_2862 > 0.0)\n    {\n        _2864 = _2862;\n    }\n    else\n    {\n        _2864 = 1.5 * _2730;\n    }\n    vec2 param_9 = _2824;\n    vec4 param_10 = _2713;\n    float param_11 = _2806 - (_2864 * (1.0 + (0.5 * _2777)));\n    float param_12 = _2730;\n    float param_13 = 1.0;\n    float param_14 = _2718.z * 0.25;\n    float param_15 = (_2730 * min(_2777, 3.0)) * 0.5;\n    vec3 param_16 = vec3(1.0, _2809, _2718.z);\n    int param_17 = int(_2645.z + 0.5);\n    float param_18 = _2645.w;\n    return mix(1.0, fa_shadow_filter(param_9, param_10, param_11, param_12, param_13, param_14, param_15, param_16, param_17, param_18), fade);\n}\n\nfloat fa_shadow_local_rt(int li, vec3 lpos, vec3 world, vec3 n, vec3 l)\n{\n    bool _3371 = fa_mesh_fs_params[25].w > 0.5;\n    bool _3377;\n    if (_3371)\n    {\n        _3377 = fa_mesh_fs_params[5].z > 0.5;\n    }\n    else\n    {\n        _3377 = _3371;\n    }\n    bool _3383;\n    if (_3377)\n    {\n        _3383 = fa_shadows[29].x > 0.5;\n    }\n    else\n    {\n        _3383 = _3377;\n    }\n    if (_3383)\n    {\n        int param = (int(fa_shadows[29].x + 0.5) - 1) + li;\n        vec4 _3395 = fa_light_texel(param);\n        float _3396 = _3395.z;\n        if (_3396 > 0.5)\n        {\n            float _3409 = dot(fa_mesh_fs_params[29].xyz, world) + fa_mesh_fs_params[29].w;\n            float _3415 = ((0.00200000009499490261077880859375 * _3409) + 0.00999999977648258209228515625) + fa_rt_slope;\n            vec4 _3421 = vec4(world, 1.0);\n            float _3426 = dot(fa_mesh_fs_params[28], _3421);\n            if (_3426 > 9.9999997473787516355514526367188e-05)\n            {\n                vec2 _3443 = vec2(dot(fa_mesh_fs_params[26], _3421), dot(fa_mesh_fs_params[27], _3421)) / vec2(_3426);\n                float _3448 = (_3443.x * 0.5) + 0.5;\n                float _3452;\n                if (fa_mesh_fs_params[24].y > 0.5)\n                {\n                    _3452 = (_3443.y * 0.5) + 0.5;\n                }\n                else\n                {\n                    _3452 = 0.5 - (_3443.y * 0.5);\n                }\n                bool _3468 = _3448 >= 0.0;\n                bool _3474;\n                if (_3468)\n                {\n                    _3474 = _3448 < 1.0;\n                }\n                else\n                {\n                    _3474 = _3468;\n                }\n                bool _3480;\n                if (_3474)\n                {\n                    _3480 = _3452 >= 0.0;\n                }\n                else\n                {\n                    _3480 = _3474;\n                }\n                bool _3486;\n                if (_3480)\n                {\n                    _3486 = _3452 < 1.0;\n                }\n                else\n                {\n                    _3486 = _3480;\n                }\n                if (_3486)\n                {\n                    ivec2 _3503 = ivec2(fa_mesh_fs_params[24].zw) - ivec2(1);\n                    ivec2 _3504 = clamp(ivec2(vec2(_3448, _3452) * fa_mesh_fs_params[24].zw), ivec2(0), _3503);\n                    float _3508;\n                    if (_3396 < 1.5)\n                    {\n                        _3508 = 1.0;\n                    }\n                    else\n                    {\n                        _3508 = (_3396 < 2.5) ? 256.0 : 65536.0;\n                    }\n                    float best = 2.0;\n                    int _3530;\n                    int _3536;\n                    for (int k = 0; k < 9; k++)\n                    {\n                        if (k == 0)\n                        {\n                            _3530 = 4;\n                        }\n                        else\n                        {\n                            if (k <= 4)\n                            {\n                                _3536 = k - 1;\n                            }\n                            else\n                            {\n                                _3536 = k;\n                            }\n                            _3530 = _3536;\n                        }\n                        vec4 _3565 = texelFetch(fa_screen_tex_fa_shadow_smp, clamp(_3504 + ivec2((_3530 % 3) - 1, (_3530 / 3) - 1), ivec2(0), _3503), 0);\n                        bool _3568 = _3565.w > 0.5;\n                        bool _3578;\n                        if (_3568)\n                        {\n                            _3578 = abs(_3409 - _3565.x) <= _3415;\n                        }\n                        else\n                        {\n                            _3578 = _3568;\n                        }\n                        if (_3578)\n                        {\n                            best = min(best, mod(floor(_3565.z / _3508), 256.0) * 0.0039215688593685626983642578125);\n                            if (k == 0)\n                            {\n                                break;\n                            }\n                        }\n                    }\n                    if (best <= 1.0)\n                    {\n                        float _3605;\n                        if (fa_mesh_fs_params[25].z > 0.5)\n                        {\n                            int param_1 = li;\n                            vec3 param_2 = lpos;\n                            vec3 param_3 = world;\n                            vec3 param_4 = n;\n                            vec3 param_5 = l;\n                            _3605 = min(best, fa_shadow_local(param_1, param_2, param_3, param_4, param_5));\n                        }\n                        else\n                        {\n                            _3605 = best;\n                        }\n                        return _3605;\n                    }\n                }\n            }\n            float _3628;\n            if (fa_mesh_fs_params[25].z > 0.5)\n            {\n                int param_6 = li;\n                vec3 param_7 = lpos;\n                vec3 param_8 = world;\n                vec3 param_9 = n;\n                vec3 param_10 = l;\n                _3628 = fa_shadow_local(param_6, param_7, param_8, param_9, param_10);\n            }\n            else\n            {\n                _3628 = 1.0;\n            }\n            return _3628;\n        }\n    }\n    int param_11 = li;\n    vec3 param_12 = lpos;\n    vec3 param_13 = world;\n    vec3 param_14 = n;\n    vec3 param_15 = l;\n    return fa_shadow_local(param_11, param_12, param_13, param_14, param_15);\n}\n\nfloat fa_shadow_split_at(int i)\n{\n    float _2149;\n    if (i == 0)\n    {\n        _2149 = fa_shadows[24].x;\n    }\n    else\n    {\n        float _2165;\n        if (i == 1)\n        {\n            _2165 = fa_shadows[24].y;\n        }\n        else\n        {\n            float _2173;\n            if (i == 2)\n            {\n                _2173 = fa_shadows[24].z;\n            }\n            else\n            {\n                _2173 = fa_shadows[24].w;\n            }\n            _2165 = _2173;\n        }\n        _2149 = _2165;\n    }\n    return _2149;\n}\n\nfloat fa_shadow_cascade(int ci, vec3 world, vec3 n, vec3 l)\n{\n    float _2452 = max(fa_shadows[ci * 1 + 20].y, 0.001000000047497451305389404296875);\n    float _2457 = clamp(dot(n, l), 0.0, 1.0);\n    float _2463 = sqrt(1.0 - (_2457 * _2457));\n    float _2471 = min(_2463 / max(_2457, 0.20000000298023223876953125), 4.0);\n    float _2476;\n    if (fa_shadows[26].y > 0.0)\n    {\n        _2476 = fa_shadows[26].y;\n    }\n    else\n    {\n        _2476 = 1.5 * fa_shadows[ci * 1 + 20].x;\n    }\n    vec4 _2501 = mat4(fa_shadows[ci * 4 + 0], fa_shadows[ci * 4 + 1], fa_shadows[ci * 4 + 2], fa_shadows[ci * 4 + 3]) * vec4(world + (n * (_2476 * _2463)), 1.0);\n    float _2508 = _2501.x;\n    bool _2511 = _2508 < fa_shadows[ci * 1 + 16].x;\n    bool _2520;\n    if (!_2511)\n    {\n        _2520 = _2508 > fa_shadows[ci * 1 + 16].z;\n    }\n    else\n    {\n        _2520 = _2511;\n    }\n    bool _2529;\n    if (!_2520)\n    {\n        _2529 = _2501.y < fa_shadows[ci * 1 + 16].y;\n    }\n    else\n    {\n        _2529 = _2520;\n    }\n    bool _2538;\n    if (!_2529)\n    {\n        _2538 = _2501.y > fa_shadows[ci * 1 + 16].w;\n    }\n    else\n    {\n        _2538 = _2529;\n    }\n    bool _2545;\n    if (!_2538)\n    {\n        _2545 = _2501.z > 1.0;\n    }\n    else\n    {\n        _2545 = _2538;\n    }\n    if (_2545)\n    {\n        return -1.0;\n    }\n    float _2553;\n    if (fa_shadows[26].x > 0.0)\n    {\n        _2553 = fa_shadows[26].x;\n    }\n    else\n    {\n        _2553 = 1.5 * fa_shadows[ci * 1 + 20].x;\n    }\n    vec2 param = _2501.xy;\n    vec4 param_1 = fa_shadows[ci * 1 + 16];\n    float param_2 = _2501.z - ((_2553 * (1.0 + (0.5 * _2471))) / _2452);\n    float param_3 = fa_shadows[ci * 1 + 20].x;\n    float param_4 = _2452;\n    float param_5 = _2452 * 0.25;\n    float param_6 = ((fa_shadows[ci * 1 + 20].x * min(_2471, 3.0)) * 0.5) / _2452;\n    vec3 param_7 = vec3(0.0);\n    int param_8 = int(fa_shadows[25].z + 0.5);\n    float param_9 = fa_shadows[25].w;\n    return fa_shadow_filter(param, param_1, param_2, param_3, param_4, param_5, param_6, param_7, param_8, param_9);\n}\n\nfloat fa_shadow_sun(vec3 world, vec3 n, vec3 l)\n{\n    if (fa_mesh_fs_params[5].z < 0.5)\n    {\n        return 1.0;\n    }\n    int _2931 = int(fa_shadows[25].x + 0.5);\n    if (_2931 < 1)\n    {\n        return 1.0;\n    }\n    float _2946 = dot(world - fa_shadows[27].xyz, fa_shadows[28].xyz);\n    int param = _2931 - 1;\n    if (_2946 > fa_shadow_split_at(param))\n    {\n        return 1.0;\n    }\n    int ci = 0;\n    bool _2958 = _2931 > 1;\n    bool _2965;\n    if (_2958)\n    {\n        _2965 = _2946 > fa_shadows[24].x;\n    }\n    else\n    {\n        _2965 = _2958;\n    }\n    if (_2965)\n    {\n        ci = 1;\n    }\n    bool _2969 = _2931 > 2;\n    bool _2976;\n    if (_2969)\n    {\n        _2976 = _2946 > fa_shadows[24].y;\n    }\n    else\n    {\n        _2976 = _2969;\n    }\n    if (_2976)\n    {\n        ci = 2;\n    }\n    bool _2980 = _2931 > 3;\n    bool _2987;\n    if (_2980)\n    {\n        _2987 = _2946 > fa_shadows[24].z;\n    }\n    else\n    {\n        _2987 = _2980;\n    }\n    if (_2987)\n    {\n        ci = 3;\n    }\n    float s = -1.0;\n    float s2 = -1.0;\n    float t = 0.0;\n    int _2998 = min(_2931, 4);\n    float _3039;\n    for (int c = ci; c < _2998; c++)\n    {\n        int param_1 = c;\n        vec3 param_2 = world;\n        vec3 param_3 = n;\n        vec3 param_4 = l;\n        float _3018 = fa_shadow_cascade(param_1, param_2, param_3, param_4);\n        if (s >= 0.0)\n        {\n            s2 = _3018;\n            break;\n        }\n        if (_3018 < 0.0)\n        {\n            continue;\n        }\n        s = _3018;\n        ci = c;\n        if (fa_shadows[25].y > 0.0)\n        {\n            if (ci > 0)\n            {\n                int param_5 = ci - 1;\n                _3039 = fa_shadow_split_at(param_5);\n            }\n            else\n            {\n                _3039 = fa_shadows[28].w;\n            }\n            int param_6 = ci;\n            float _3058 = fa_shadows[25].y * max(fa_shadow_split_at(param_6) - _3039, 9.9999997473787516355514526367188e-05);\n            int param_7 = ci;\n            t = clamp((_2946 - (fa_shadow_split_at(param_7) - _3058)) / _3058, 0.0, 1.0);\n        }\n        if (t <= 0.0)\n        {\n            break;\n        }\n    }\n    if (s < 0.0)\n    {\n        return 1.0;\n    }\n    if (t > 0.0)\n    {\n        float _3090;\n        if ((ci + 1) < _2931)\n        {\n            _3090 = (s2 < 0.0) ? s : s2;\n        }\n        else\n        {\n            _3090 = 1.0;\n        }\n        s = mix(s, _3090, t);\n    }\n    return s;\n}\n\nfloat fa_shadow_factor(vec3 n, vec3 l)\n{\n    bool _3195 = fa_mesh_fs_params[25].y > 0.5;\n    bool _3201;\n    if (_3195)\n    {\n        _3201 = fa_mesh_fs_params[5].z > 0.5;\n    }\n    else\n    {\n        _3201 = _3195;\n    }\n    if (_3201)\n    {\n        float _3215 = dot(fa_mesh_fs_params[29].xyz, fa_world_pos) + fa_mesh_fs_params[29].w;\n        vec4 _3223 = vec4(fa_world_pos, 1.0);\n        float _3229 = dot(fa_mesh_fs_params[28], _3223);\n        if (_3229 > 9.9999997473787516355514526367188e-05)\n        {\n            vec2 _3248 = vec2(dot(fa_mesh_fs_params[26], _3223), dot(fa_mesh_fs_params[27], _3223)) / vec2(_3229);\n            float _3253 = (_3248.x * 0.5) + 0.5;\n            float _3257;\n            if (fa_mesh_fs_params[24].y > 0.5)\n            {\n                _3257 = (_3248.y * 0.5) + 0.5;\n            }\n            else\n            {\n                _3257 = 0.5 - (_3248.y * 0.5);\n            }\n            bool _3273 = _3253 >= 0.0;\n            bool _3279;\n            if (_3273)\n            {\n                _3279 = _3253 < 1.0;\n            }\n            else\n            {\n                _3279 = _3273;\n            }\n            bool _3285;\n            if (_3279)\n            {\n                _3285 = _3257 >= 0.0;\n            }\n            else\n            {\n                _3285 = _3279;\n            }\n            bool _3291;\n            if (_3285)\n            {\n                _3291 = _3257 < 1.0;\n            }\n            else\n            {\n                _3291 = _3285;\n            }\n            if (_3291)\n            {\n                vec4 _3317 = texelFetch(fa_screen_tex_fa_shadow_smp, clamp(ivec2(vec2(_3253, _3257) * fa_mesh_fs_params[24].zw), ivec2(0), ivec2(fa_mesh_fs_params[24].zw) - ivec2(1)), 0);\n                bool _3320 = _3317.w > 0.5;\n                bool _3336;\n                if (_3320)\n                {\n                    _3336 = abs(_3215 - _3317.x) <= (((0.00200000009499490261077880859375 * _3215) + 0.00999999977648258209228515625) + fa_rt_slope);\n                }\n                else\n                {\n                    _3336 = _3320;\n                }\n                if (_3336)\n                {\n                    float _3342;\n                    if (fa_mesh_fs_params[25].z > 0.5)\n                    {\n                        vec3 param = fa_world_pos;\n                        vec3 param_1 = n;\n                        vec3 param_2 = l;\n                        _3342 = min(_3317.y, fa_shadow_sun(param, param_1, param_2));\n                    }\n                    else\n                    {\n                        _3342 = _3317.y;\n                    }\n                    return _3342;\n                }\n            }\n        }\n    }\n    vec3 param_3 = fa_world_pos;\n    vec3 param_4 = n;\n    vec3 param_5 = l;\n    return fa_shadow_sun(param_3, param_4, param_5);\n}\n\nfloat fa_contact_shadow(int li, vec3 world, vec3 gn, vec3 l, float dist)\n{\n    bool _5183 = fa_mesh_fs_params[24].x < 0.5;\n    bool _5190;\n    if (!_5183)\n    {\n        _5190 = fa_shadows[29].x < 0.5;\n    }\n    else\n    {\n        _5190 = _5183;\n    }\n    if (_5190)\n    {\n        return 1.0;\n    }\n    int param = (int(fa_shadows[29].x + 0.5) - 1) + li;\n    vec4 _5203 = fa_light_texel(param);\n    float _5204 = _5203.y;\n    float len = _5204;\n    if (_5204 <= 0.0)\n    {\n        return 1.0;\n    }\n    float _5216 = length(world - fa_mesh_fs_params[0].xyz);\n    float _5225 = 1.0 - smoothstep(0.5 * fa_mesh_fs_params[25].x, fa_mesh_fs_params[25].x, _5216);\n    if (_5225 <= 0.0)\n    {\n        return 1.0;\n    }\n    float _5231 = len;\n    float _5234 = min(_5231, 0.89999997615814208984375 * dist);\n    len = _5234;\n    float _5239 = 0.004999999888241291046142578125 + (0.0030000000260770320892333984375 * _5216);\n    float _5244 = _5239 + (0.5 * _5234);\n    vec3 _5250 = world + (gn * _5239);\n    float _5252 = fa_shadow_noise();\n    float occ = 0.0;\n    float _5313;\n    for (int k = 0; k < 12; k++)\n    {\n        float _5267 = (float(k) + _5252) * 0.083333335816860198974609375;\n        vec3 _5275 = _5250 + (l * (_5267 * len));\n        vec4 _5281 = vec4(_5275, 1.0);\n        float _5286 = dot(fa_mesh_fs_params[28], _5281);\n        if (_5286 < 9.9999997473787516355514526367188e-05)\n        {\n            break;\n        }\n        vec2 _5304 = vec2(dot(fa_mesh_fs_params[26], _5281), dot(fa_mesh_fs_params[27], _5281)) / vec2(_5286);\n        float _5308 = _5304.x * 0.5;\n        float _5309 = _5308 + 0.5;\n        if (fa_mesh_fs_params[24].y > 0.5)\n        {\n            _5313 = (_5304.y * 0.5) + 0.5;\n        }\n        else\n        {\n            _5313 = 0.5 - (_5304.y * 0.5);\n        }\n        bool _5329 = _5309 < 0.0;\n        bool _5336;\n        if (!_5329)\n        {\n            _5336 = _5309 >= 1.0;\n        }\n        else\n        {\n            _5336 = _5329;\n        }\n        bool _5343;\n        if (!_5336)\n        {\n            _5343 = _5313 < 0.0;\n        }\n        else\n        {\n            _5343 = _5336;\n        }\n        bool _5350;\n        if (!_5343)\n        {\n            _5350 = _5313 >= 1.0;\n        }\n        else\n        {\n            _5350 = _5343;\n        }\n        if (_5350)\n        {\n            break;\n        }\n        vec4 _5374 = texelFetch(fa_screen_tex_fa_shadow_smp, clamp(ivec2(vec2(_5309, _5313) * fa_mesh_fs_params[24].zw), ivec2(0), ivec2(fa_mesh_fs_params[24].zw) - ivec2(1)), 0);\n        if (_5374.w < 0.5)\n        {\n            continue;\n        }\n        float _5392 = (dot(fa_mesh_fs_params[29].xyz, _5275) + fa_mesh_fs_params[29].w) - _5374.x;\n        if ((_5392 > _5239) && (_5392 < _5244))\n        {\n            occ = max(occ, (1.0 - (_5267 * _5267)) * smoothstep(0.0, 0.0500000007450580596923828125, min(min(_5309, 0.5 - _5308), min(_5313, 1.0 - _5313))));\n        }\n    }\n    return 1.0 - (occ * _5225);\n}\n\nLightSample fa_light_shadowed(int li, vec3 world_pos, vec3 gn)\n{\n    int param = li;\n    float _5524 = fa_baked_keep(param);\n    if (_5524 <= 0.0)\n    {\n        int param_1 = li;\n        return LightSample(vec3(0.0, 1.0, 0.0), vec3(0.0), 0.0, 1.0, 0.0, int(fa_light_type(param_1) + 0.5));\n    }\n    int param_2 = li;\n    vec3 param_3 = world_pos;\n    vec3 param_4 = gn;\n    LightSample _5550 = fa_light_sample_n(param_2, param_3, param_4);\n    vec3 _7503 = _5550.color;\n    float _7504 = _5550.attenuation;\n    float _7505 = _5550.shadow;\n    bool _5553 = _5550.type == 0;\n    if (_5553 && (li == 0))\n    {\n        vec3 param_5 = gn;\n        vec3 param_6 = _5550.direction;\n        float _5564 = fa_shadow_factor(param_5, param_6);\n        _7505 = _5564;\n        _7503 *= _5564;\n    }\n    else\n    {\n        bool _5575 = _5550.type != 0;\n        bool _5581;\n        if (_5575)\n        {\n            _5581 = _7504 > 0.0;\n        }\n        else\n        {\n            _5581 = _5575;\n        }\n        if (_5581)\n        {\n            int param_7 = li;\n            int param_8 = fa_light_base(param_7);\n            int param_9 = li;\n            vec3 param_10 = fa_light_texel(param_8).xyz;\n            vec3 param_11 = world_pos;\n            vec3 param_12 = gn;\n            vec3 param_13 = _5550.direction;\n            float _5600 = fa_shadow_local_rt(param_9, param_10, param_11, param_12, param_13);\n            _7505 = _5600;\n            _7503 *= _5600;\n        }\n    }\n    bool _5610 = fa_mesh_fs_params[24].x > 0.5;\n    bool _5616;\n    if (_5610)\n    {\n        _5616 = _7504 > 0.0;\n    }\n    else\n    {\n        _5616 = _5610;\n    }\n    if (_5616)\n    {\n        float _5623;\n        if (_5553)\n        {\n            _5623 = 1000000000.0;\n        }\n        else\n        {\n            _5623 = _5550._distance;\n        }\n        int param_14 = li;\n        vec3 param_15 = world_pos;\n        vec3 param_16 = gn;\n        vec3 param_17 = _5550.direction;\n        float param_18 = _5623;\n        float _5641 = fa_contact_shadow(param_14, param_15, param_16, param_17, param_18);\n        _7505 *= _5641;\n        _7503 *= _5641;\n    }\n    float _5654 = _7504;\n    float _5655 = _5654 * _5524;\n    _7504 = _5655;\n    vec3 _5659 = _7503;\n    vec3 _5660 = _5659 * _5524;\n    _7503 = _5660;\n    return LightSample(_5550.direction, _5660, _5655, _7505, _5550._distance, _5550.type);\n}\n\nvec3 light(SurfaceInput i, Surface s, LightSample l)\n{\n    return vec3(0.0);\n}\n\nvec3 fa_shadow_debug(vec3 color, vec3 world)\n{\n    if (fa_shadows[27].w < 0.5)\n    {\n        return color;\n    }\n    int _3118 = int(fa_shadows[25].x + 0.5);\n    float _3128 = dot(world - fa_shadows[27].xyz, fa_shadows[28].xyz);\n    vec3 tint = vec3(0.3499999940395355224609375);\n    bool _3133 = _3118 > 0;\n    bool _3142;\n    if (_3133)\n    {\n        int param = _3118 - 1;\n        _3142 = _3128 <= fa_shadow_split_at(param);\n    }\n    else\n    {\n        _3142 = _3133;\n    }\n    if (_3142)\n    {\n        tint = vec3(1.0, 0.1500000059604644775390625, 0.100000001490116119384765625);\n        bool _3148 = _3118 > 1;\n        bool _3155;\n        if (_3148)\n        {\n            _3155 = _3128 > fa_shadows[24].x;\n        }\n        else\n        {\n            _3155 = _3148;\n        }\n        if (_3155)\n        {\n            tint = vec3(0.100000001490116119384765625, 0.89999997615814208984375, 0.20000000298023223876953125);\n        }\n        bool _3161 = _3118 > 2;\n        bool _3168;\n        if (_3161)\n        {\n            _3168 = _3128 > fa_shadows[24].y;\n        }\n        else\n        {\n            _3168 = _3161;\n        }\n        if (_3168)\n        {\n            tint = vec3(0.1500000059604644775390625, 0.300000011920928955078125, 1.0);\n        }\n        bool _3174 = _3118 > 3;\n        bool _3181;\n        if (_3174)\n        {\n            _3181 = _3128 > fa_shadows[24].z;\n        }\n        else\n        {\n            _3181 = _3174;\n        }\n        if (_3181)\n        {\n            tint = vec3(1.0, 0.89999997615814208984375, 0.100000001490116119384765625);\n        }\n    }\n    return mix(color, tint, vec3(0.550000011920928955078125));\n}\n\nvoid main()\n{\n    fa_rt_slope = 0.0;\n    fa_inst_load();\n    vec3 _7188 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _7188 = -_7188;\n    }\n    vec3 _6811 = normalize(fa_mesh_fs_params[0].xyz - fa_world_pos);\n    vec3 param = fa_world_pos;\n    fa_cluster_begin(param);\n    SurfaceInput param_1 = SurfaceInput(fa_world_pos, _7188, fa_world_tangent, fa_uv, fa_vertex_color, _6811, gl_FrontFacing);\n    Surface _6819 = fa_standard_surface(param_1);\n    vec3 _7227 = _6819.albedo;\n    float _7228 = _6819.alpha;\n    vec3 _7229 = _6819.normal;\n    float _7230 = _6819.metallic;\n    float _7231 = _6819.roughness;\n    float _7232 = _6819.occlusion;\n    vec3 _7233 = _6819.emission;\n    float _7234 = _6819.clearcoat;\n    float _7235 = _6819.clearcoat_roughness;\n    vec3 _7236 = _6819.sheen_color;\n    float _7237 = _6819.sheen_roughness;\n    float _7238 = _6819.anisotropy;\n    float _7239 = _6819.anisotropy_rotation;\n    float _7240 = _6819.specular;\n    float _7241 = _6819.ior;\n    vec3 _7242 = _6819.specular_color;\n    float _7243 = _6819.transmission;\n    float _7244 = _6819.thickness;\n    vec3 _7245 = _6819.attenuation_color;\n    float _7246 = _6819.attenuation_distance;\n    SurfaceInput param_2 = SurfaceInput(fa_world_pos, _7188, fa_world_tangent, fa_uv, fa_vertex_color, _6811, gl_FrontFacing);\n    Surface param_3 = _6819;\n    surface(param_2, param_3);\n    _7227 = param_3.albedo;\n    _7228 = param_3.alpha;\n    _7229 = param_3.normal;\n    _7230 = param_3.metallic;\n    _7231 = param_3.roughness;\n    _7232 = param_3.occlusion;\n    _7233 = param_3.emission;\n    _7234 = param_3.clearcoat;\n    _7235 = param_3.clearcoat_roughness;\n    _7236 = param_3.sheen_color;\n    _7237 = param_3.sheen_roughness;\n    _7238 = param_3.anisotropy;\n    _7239 = param_3.anisotropy_rotation;\n    _7240 = param_3.specular;\n    _7241 = param_3.ior;\n    _7242 = param_3.specular_color;\n    _7243 = param_3.transmission;\n    _7244 = param_3.thickness;\n    _7245 = param_3.attenuation_color;\n    _7246 = param_3.attenuation_distance;\n    vec3 param_4 = fa_world_pos;\n    vec3 param_5 = _7188;\n    vec3 param_6 = param_3.albedo;\n    vec3 param_7 = param_3.normal;\n    fa_apply_decals(param_4, param_5, param_6, param_7);\n    _7227 = param_6;\n    _7229 = param_7;\n    vec3 result;\n    if (fa_mesh_fs_params[3].w > 0.5)\n    {\n        result = _7227;\n    }\n    else\n    {\n        vec3 _6858 = _7229;\n        vec3 _6859 = normalize(_6858);\n        _7229 = _6859;\n        vec3 param_8 = _6859;\n        SurfaceInput param_9 = SurfaceInput(fa_world_pos, _7188, fa_world_tangent, fa_uv, fa_vertex_color, _6811, gl_FrontFacing);\n        Surface param_10 = Surface(_7227, _7228, _7229, _7230, _7231, _7232, _7233, _7234, _7235, _7236, _7237, _7238, _7239, _7240, _7241, _7242, _7243, _7244, _7245, _7246);\n        vec3 param_11 = fa_indirect_diffuse(param_8);\n        vec3 lit = ambient(param_9, param_10, param_11);\n        int _6878 = fa_cl_ndir + fa_cl_local;\n        for (int ln = 0; ln < _6878; ln++)\n        {\n            int param_12 = ln;\n            int _6891 = fa_cl_light(param_12);\n            int param_13 = _6891;\n            if (fa_baked_keep(param_13) <= 0.0)\n            {\n                continue;\n            }\n            int param_14 = _6891;\n            vec3 param_15 = fa_world_pos;\n            vec3 param_16 = _7188;\n            LightSample _6907 = fa_light_shadowed(param_14, param_15, param_16);\n            SurfaceInput param_17 = SurfaceInput(fa_world_pos, _7188, fa_world_tangent, fa_uv, fa_vertex_color, _6811, gl_FrontFacing);\n            Surface param_18 = Surface(_7227, _7228, _7229, _7230, _7231, _7232, _7233, _7234, _7235, _7236, _7237, _7238, _7239, _7240, _7241, _7242, _7243, _7244, _7245, _7246);\n            LightSample param_19 = _6907;\n            lit += light(param_17, param_18, param_19);\n        }\n        result = lit;\n    }\n    vec3 _6922 = result;\n    vec3 _6923 = _6922 + _7233;\n    result = _6923;\n    vec3 param_20 = _6923;\n    vec3 param_21 = fa_world_pos;\n    result = fa_shadow_debug(param_20, param_21);\n    bool _6932 = fa_mesh_fs_params[7].w > 0.0;\n    bool _6939;\n    if (!_6932)\n    {\n        _6939 = fa_mesh_fs_params[8].y > 0.0;\n    }\n    else\n    {\n        _6939 = _6932;\n    }\n    if (_6939)\n    {\n        vec3 _6948 = fa_world_pos - fa_mesh_fs_params[0].xyz;\n        float _6954 = dot(_6948, fa_mesh_fs_params[9].xyz);\n        bool _6958 = fa_mesh_fs_params[9].w > 0.5;\n        float _6959;\n        if (_6958)\n        {\n            _6959 = _6954;\n        }\n        else\n        {\n            _6959 = length(_6948);\n        }\n        float _6971 = _6959 - fa_mesh_fs_params[8].x;\n        if (_6971 > 0.0)\n        {\n            float _6980 = fa_mesh_fs_params[7].w * _6971;\n            float tau = _6980 * _6980;\n            if (fa_mesh_fs_params[8].y > 0.0)\n            {\n                float _6996;\n                if (_6958)\n                {\n                    _6996 = fa_world_pos.y - (fa_mesh_fs_params[9].y * _6954);\n                }\n                else\n                {\n                    _6996 = fa_mesh_fs_params[0].y;\n                }\n                float _7017 = mix(_6996, fa_world_pos.y, clamp(fa_mesh_fs_params[8].x / _6959, 0.0, 1.0));\n                float _7021 = fa_world_pos.y - _7017;\n                float _7026 = _7017 - fa_mesh_fs_params[8].z;\n                float _7031 = fa_world_pos.y - fa_mesh_fs_params[8].z;\n                bool _7034 = _7026 <= 0.0;\n                bool _7035 = !_7034;\n                bool _7041;\n                if (_7035)\n                {\n                    _7041 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _7041 = _7034;\n                }\n                float _7042;\n                if (_7041)\n                {\n                    _7042 = fa_mesh_fs_params[8].y;\n                }\n                else\n                {\n                    _7042 = fa_mesh_fs_params[8].y * exp(-min(fa_mesh_fs_params[8].w * _7026, 80.0));\n                }\n                bool _7069;\n                if (_7035)\n                {\n                    _7069 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _7069 = _7034;\n                }\n                float _7070;\n                if (_7069)\n                {\n                    _7070 = fa_mesh_fs_params[8].y * _7026;\n                }\n                else\n                {\n                    _7070 = (fa_mesh_fs_params[8].y * (1.0 - exp(-min(fa_mesh_fs_params[8].w * _7026, 80.0)))) / fa_mesh_fs_params[8].w;\n                }\n                bool _7095 = _7031 <= 0.0;\n                bool _7102;\n                if (!_7095)\n                {\n                    _7102 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _7102 = _7095;\n                }\n                float _7103;\n                if (_7102)\n                {\n                    _7103 = fa_mesh_fs_params[8].y * _7031;\n                }\n                else\n                {\n                    _7103 = (fa_mesh_fs_params[8].y * (1.0 - exp(-min(fa_mesh_fs_params[8].w * _7031, 80.0)))) / fa_mesh_fs_params[8].w;\n                }\n                float _7130;\n                if (abs(_7021) < 0.001000000047497451305389404296875)\n                {\n                    _7130 = _7042;\n                }\n                else\n                {\n                    _7130 = (_7103 - _7070) / _7021;\n                }\n                tau += (_6971 * max(_7130, 0.0));\n            }\n            result = mix(result, fa_mesh_fs_params[7].xyz, vec3(clamp(1.0 - exp(-clamp(tau, 0.0, 80.0)), 0.0, 1.0)));\n        }\n    }\n    fa_frag_color = vec4(result, _7228);\n}\n\n",
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
            "size": 864,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_507",
            "glsl_uniforms": [
              {
                "type": "vec4",
                "array_count": 54,
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
            "inst_name": "_2159",
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
            "name": "fa_screen_tex_fa_shadow_smp",
            "view_name": "fa_screen_tex",
            "sampler_name": "fa_shadow_smp",
            "view_slot": 28,
            "sampler_slot": 1,
            "glsl_name": "fa_screen_tex_fa_shadow_smp"
          },
          {
            "slot": 11,
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
      "vs": "#version 430\n\nstruct VertexData\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 color;\n    vec3 object_pos;\n};\n\nuniform vec4 fa_mesh_vs_params[11];\nuniform vec4 fa_vel_params[9];\nlayout(location = 0) out vec3 fa_world_pos;\nlayout(location = 1) out vec3 fa_world_normal;\nlayout(location = 2) out vec4 fa_world_tangent;\nlayout(location = 3) out vec2 fa_uv;\nlayout(location = 4) out vec4 fa_vertex_color;\nlayout(location = 5) out float fa_pre_depth;\nlayout(location = 6) out vec3 fa_pre_r0;\nlayout(location = 7) out vec3 fa_pre_r1;\nlayout(location = 8) out vec3 fa_pre_r2;\nlayout(location = 9) out vec3 fa_vel_cur;\nlayout(location = 10) out vec3 fa_vel_prev;\nlayout(location = 9) in vec4 fa_prev_r0;\nlayout(location = 10) in vec4 fa_prev_r1;\nlayout(location = 11) in vec4 fa_prev_r2;\nlayout(location = 5) in vec4 fa_inst_m0;\nlayout(location = 6) in vec4 fa_inst_m1;\nlayout(location = 7) in vec4 fa_inst_m2;\nlayout(location = 8) in vec4 fa_inst_m3;\nlayout(location = 0) in vec3 fa_position;\nlayout(location = 1) in vec3 fa_normal;\nlayout(location = 3) in vec4 fa_tangent;\nlayout(location = 2) in vec2 fa_texcoord0;\nlayout(location = 4) in vec4 fa_color;\nvec4 fa_vtime;\n\nvoid fa_inst_begin()\n{\n}\n\nvec4 fa_time_now()\n{\n    return fa_mesh_vs_params[9];\n}\n\nVertexData fa_vertex_data(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    vec3 _97 = cross(model[1].xyz, model[2].xyz);\n    float _101 = (dot(model[0].xyz, _97) < 0.0) ? (-1.0) : 1.0;\n    return VertexData((model * vec4(position, 1.0)).xyz, (((_97 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _101, vec4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _101), texcoord0 * fa_mesh_vs_params[8].xy, color, position);\n}\n\nmat4 fa_rows_to_mat4(vec4 r0, vec4 r1, vec4 r2)\n{\n    return mat4(vec4(r0.x, r1.x, r2.x, 0.0), vec4(r0.y, r1.y, r2.y, 0.0), vec4(r0.z, r1.z, r2.z, 0.0), vec4(r0.w, r1.w, r2.w, 1.0));\n}\n\nmat4 fa_prev_model()\n{\n    vec4 param = fa_prev_r0;\n    vec4 param_1 = fa_prev_r1;\n    vec4 param_2 = fa_prev_r2;\n    return fa_rows_to_mat4(param, param_1, param_2);\n}\n\nvoid fa_prepass_vertex(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color, bool has_prev)\n{\n    bool _231;\n    if (has_prev)\n    {\n        _231 = fa_vel_params[8].x > 0.5;\n    }\n    else\n    {\n        _231 = has_prev;\n    }\n    fa_vtime = fa_time_now();\n    mat4 param = model;\n    vec3 param_1 = position;\n    vec3 param_2 = normal;\n    vec4 param_3 = tangent;\n    vec2 param_4 = texcoord0;\n    vec4 param_5 = color;\n    VertexData _246 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    vec3 _455 = _246.world_pos;\n    mat4 _250 = mat4(fa_mesh_vs_params[4], fa_mesh_vs_params[5], fa_mesh_vs_params[6], fa_mesh_vs_params[7]);\n    vec4 _257 = vec4(_455, 1.0);\n    fa_world_pos = _455;\n    fa_world_normal = _246.world_normal;\n    fa_world_tangent = _246.world_tangent;\n    fa_uv = _246.uv;\n    fa_vertex_color = _246.color;\n    fa_pre_depth = -(_250 * _257).z;\n    fa_pre_r0 = vec3(_250[0].x, _250[1].x, _250[2].x);\n    fa_pre_r1 = vec3(_250[0].y, _250[1].y, _250[2].y);\n    fa_pre_r2 = vec3(_250[0].z, _250[1].z, _250[2].z);\n    gl_Position = mat4(fa_mesh_vs_params[0], fa_mesh_vs_params[1], fa_mesh_vs_params[2], fa_mesh_vs_params[3]) * _257;\n    fa_vel_cur = vec3(0.0, 0.0, 1.0);\n    fa_vel_prev = vec3(0.0);\n    if (_231)\n    {\n        vec4 _330 = vec4(position, 1.0);\n        fa_vel_cur = vec3((mat4(fa_vel_params[0], fa_vel_params[1], fa_vel_params[2], fa_vel_params[3]) * _257).xyw);\n        fa_vel_prev = vec3((mat4(fa_vel_params[4], fa_vel_params[5], fa_vel_params[6], fa_vel_params[7]) * vec4((_455 + (fa_prev_model() * _330).xyz) - (model * _330).xyz, 1.0)).xyw);\n    }\n}\n\nvoid main()\n{\n    fa_vtime = vec4(0.0);\n    fa_inst_begin();\n    mat4 param = mat4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3);\n    vec3 param_1 = fa_position;\n    vec3 param_2 = fa_normal;\n    vec4 param_3 = fa_tangent;\n    vec2 param_4 = fa_texcoord0;\n    vec4 param_5 = fa_color;\n    bool param_6 = true;\n    fa_prepass_vertex(param, param_1, param_2, param_3, param_4, param_5, param_6);\n}\n\n",
      "fs": "#version 430\n\nstruct SurfaceInput\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 vertex_color;\n    vec3 view_dir;\n    bool front_facing;\n};\n\nstruct Surface\n{\n    vec3 albedo;\n    float alpha;\n    vec3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    vec3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    vec3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    vec3 specular_color;\n    float transmission;\n    float thickness;\n    vec3 attenuation_color;\n    float attenuation_distance;\n};\n\nuniform vec4 fa_mesh_fs_params[54];\nlayout(binding = 0) uniform sampler2D fa_tex_fa_smp;\nlayout(binding = 1) uniform sampler2D fa_normal_tex_fa_smp;\nlayout(binding = 2) uniform sampler2D fa_mr_tex_fa_smp;\nlayout(binding = 3) uniform sampler2D fa_occlusion_tex_fa_smp;\nlayout(binding = 4) uniform sampler2D fa_emissive_tex_fa_smp;\n\nlayout(location = 0) in vec3 fa_world_pos;\nlayout(location = 1) in vec3 fa_world_normal;\nlayout(location = 2) in vec4 fa_world_tangent;\nlayout(location = 3) in vec2 fa_uv;\nlayout(location = 4) in vec4 fa_vertex_color;\nlayout(location = 6) in vec3 fa_pre_r0;\nlayout(location = 7) in vec3 fa_pre_r1;\nlayout(location = 8) in vec3 fa_pre_r2;\nlayout(location = 0) out vec4 fa_frag_color;\nlayout(location = 5) in float fa_pre_depth;\nlayout(location = 9) in vec3 fa_vel_cur;\nlayout(location = 10) in vec3 fa_vel_prev;\nlayout(location = 1) out vec2 fa_frag_velocity;\n\nvoid fa_inst_load()\n{\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nvec3 fa_linear_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_tex_fix(inout vec3 c, float mode)\n{\n    if (mode > 1.5)\n    {\n        vec3 param = c;\n        vec3 _172 = fa_linear_to_srgb(param);\n        c = _172;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            vec3 param_1 = c;\n            vec3 _181 = fa_srgb_to_linear(param_1);\n            c = _181;\n        }\n    }\n    return c;\n}\n\nvec3 fa_tangent_normal(SurfaceInput i, vec3 m)\n{\n    vec3 _56;\n    if (i.front_facing)\n    {\n        _56 = i.world_normal;\n    }\n    else\n    {\n        _56 = -i.world_normal;\n    }\n    vec3 _81 = normalize(i.world_tangent.xyz - (_56 * dot(_56, i.world_tangent.xyz)));\n    vec3 _109 = normalize(((_81 * m.x) + ((cross(_56, _81) * i.world_tangent.w) * m.y)) + (_56 * m.z));\n    vec3 _112;\n    if (i.front_facing)\n    {\n        _112 = _109;\n    }\n    else\n    {\n        _112 = -_109;\n    }\n    return _112;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    vec4 base_t = texture(fa_tex_fa_smp, i.uv, fa_mesh_fs_params[12].w);\n    float param = fa_mesh_fs_params[6].w;\n    float param_1 = 1.0;\n    vec3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    vec3 _230 = fa_tex_fix(param_2, param_3);\n    vec4 _889 = base_t;\n    _889.x = _230.x;\n    _889.y = _230.y;\n    _889.z = _230.z;\n    base_t = _889;\n    vec4 _246 = (_889 * fa_mesh_fs_params[2]) * i.vertex_color;\n    vec3 _844 = i.world_normal;\n    if (fa_mesh_fs_params[6].z > 0.5)\n    {\n        float param_4 = fa_mesh_fs_params[6].w;\n        float param_5 = 16.0;\n        vec3 param_6 = texture(fa_normal_tex_fa_smp, i.uv, fa_mesh_fs_params[12].w).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        vec3 _282 = fa_tex_fix(param_6, param_7);\n        vec3 _286 = (_282 * 2.0) - vec3(1.0);\n        vec2 _291 = _286.xy * fa_mesh_fs_params[6].x;\n        vec3 _897 = _286;\n        _897.x = _291.x;\n        _897.y = _291.y;\n        SurfaceInput param_8 = i;\n        vec3 param_9 = _897;\n        _844 = fa_tangent_normal(param_8, param_9);\n    }\n    vec4 mrt = texture(fa_mr_tex_fa_smp, i.uv, fa_mesh_fs_params[12].w);\n    float param_10 = fa_mesh_fs_params[6].w;\n    float param_11 = 64.0;\n    vec3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    vec3 _322 = fa_tex_fix(param_12, param_13);\n    vec4 _900 = mrt;\n    _900.x = _322.x;\n    _900.y = _322.y;\n    _900.z = _322.z;\n    mrt = _900;\n    vec4 _354 = texture(fa_occlusion_tex_fa_smp, i.uv, fa_mesh_fs_params[12].w);\n    float param_14 = fa_mesh_fs_params[6].w;\n    float param_15 = 256.0;\n    vec3 param_16 = _354.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    vec3 _366 = fa_tex_fix(param_16, param_17);\n    float param_18 = fa_mesh_fs_params[6].w;\n    float param_19 = 4.0;\n    vec3 param_20 = texture(fa_emissive_tex_fa_smp, i.uv, fa_mesh_fs_params[12].w).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    vec3 _398 = fa_tex_fix(param_20, param_21);\n    float _849 = fa_mesh_fs_params[20].x;\n    float _850 = fa_mesh_fs_params[20].y;\n    float _853 = fa_mesh_fs_params[20].z;\n    float _852 = fa_mesh_fs_params[21].w;\n    float _855 = fa_mesh_fs_params[22].x;\n    if (fa_mesh_fs_params[22].z > 0.5)\n    {\n        if (mod(fa_mesh_fs_params[22].z, 2.0) > 0.5)\n        {\n            _849 *= _366.y;\n            _850 *= _366.z;\n            _852 *= _354.w;\n        }\n        if (fa_mesh_fs_params[22].z > 1.5)\n        {\n            _853 *= mrt.x;\n            _855 *= mrt.w;\n        }\n    }\n    return Surface(_246.xyz, _246.w, _844, clamp(fa_mesh_fs_params[5].x * _322.z, 0.0, 1.0), clamp(fa_mesh_fs_params[5].y * _322.y, 0.0500000007450580596923828125, 1.0), 1.0 + (fa_mesh_fs_params[6].y * (_366.x - 1.0)), fa_mesh_fs_params[3].xyz + (fa_mesh_fs_params[4].xyz * _398), _849, _850, fa_mesh_fs_params[21].xyz, _852, _853, fa_mesh_fs_params[20].w, _855, fa_mesh_fs_params[22].y, fa_mesh_fs_params[23].xyz, fa_mesh_fs_params[30].x, fa_mesh_fs_params[30].y, fa_mesh_fs_params[31].xyz, fa_mesh_fs_params[30].z);\n}\n\nvoid surface(SurfaceInput i, Surface s)\n{\n}\n\nvoid main()\n{\n    fa_inst_load();\n    vec3 _739 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _739 = -_739;\n    }\n    vec3 _550 = normalize(fa_mesh_fs_params[0].xyz - fa_world_pos);\n    SurfaceInput param = SurfaceInput(fa_world_pos, _739, fa_world_tangent, fa_uv, fa_vertex_color, _550, gl_FrontFacing);\n    SurfaceInput param_1 = SurfaceInput(fa_world_pos, _739, fa_world_tangent, fa_uv, fa_vertex_color, _550, gl_FrontFacing);\n    Surface param_2 = fa_standard_surface(param);\n    surface(param_1, param_2);\n    vec3 _565 = normalize(param_2.normal);\n    vec3 _580 = normalize(vec3(dot(fa_pre_r0, _565), dot(fa_pre_r1, _565), dot(fa_pre_r2, _565)));\n    float _592 = _580.z;\n    vec2 e = _580.xy / vec2((abs(_580.x) + abs(_580.y)) + abs(_592));\n    if (_592 < 0.0)\n    {\n        e = (vec2(1.0) - abs(e.yx)) * vec2((e.x >= 0.0) ? 1.0 : (-1.0), (e.y >= 0.0) ? 1.0 : (-1.0));\n    }\n    fa_frag_color = vec4(min(fa_pre_depth, 60000.0), e, 1.0);\n    vec2 motion = vec2(1024.0);\n    bool _636 = fa_vel_cur.z > 9.9999997473787516355514526367188e-06;\n    bool _643;\n    if (_636)\n    {\n        _643 = fa_vel_prev.z > 9.9999997473787516355514526367188e-06;\n    }\n    else\n    {\n        _643 = _636;\n    }\n    if (_643)\n    {\n        motion = clamp(((vec2(fa_vel_prev.x, -fa_vel_prev.y) / vec2(fa_vel_prev.z)) * 0.5) - ((vec2(fa_vel_cur.x, -fa_vel_cur.y) / vec2(fa_vel_cur.z)) * 0.5), vec2(-4.0), vec2(4.0));\n    }\n    fa_frag_velocity = motion;\n}\n\n",
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
            "size": 864,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_214",
            "glsl_uniforms": [
              {
                "type": "vec4",
                "array_count": 54,
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
      "vs": "#version 430\n\nstruct VertexData\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 color;\n    vec3 object_pos;\n};\n\nuniform vec4 fa_mesh_vs_params[11];\nuniform vec4 fa_skin[192];\nuniform vec4 fa_vel_params[9];\nlayout(binding = 0) uniform sampler2D fa_prev_pal_tex_fa_prev_pal_smp;\n\nlayout(location = 0) out vec3 fa_world_pos;\nlayout(location = 1) out vec3 fa_world_normal;\nlayout(location = 2) out vec4 fa_world_tangent;\nlayout(location = 3) out vec2 fa_uv;\nlayout(location = 4) out vec4 fa_vertex_color;\nlayout(location = 5) out float fa_pre_depth;\nlayout(location = 6) out vec3 fa_pre_r0;\nlayout(location = 7) out vec3 fa_pre_r1;\nlayout(location = 8) out vec3 fa_pre_r2;\nlayout(location = 9) out vec3 fa_vel_cur;\nlayout(location = 10) out vec3 fa_vel_prev;\nlayout(location = 11) in vec4 fa_prev_r0;\nlayout(location = 12) in vec4 fa_prev_r1;\nlayout(location = 13) in vec4 fa_prev_r2;\nlayout(location = 9) in vec4 fa_joints;\nlayout(location = 10) in vec4 fa_weights;\nlayout(location = 5) in vec4 fa_inst_m0;\nlayout(location = 6) in vec4 fa_inst_m1;\nlayout(location = 7) in vec4 fa_inst_m2;\nlayout(location = 8) in vec4 fa_inst_m3;\nlayout(location = 0) in vec3 fa_position;\nlayout(location = 1) in vec3 fa_normal;\nlayout(location = 3) in vec4 fa_tangent;\nlayout(location = 2) in vec2 fa_texcoord0;\nlayout(location = 4) in vec4 fa_color;\nvec4 fa_vtime;\n\nvoid fa_inst_begin()\n{\n}\n\nmat4 fa_skin_matrix(vec4 joints, vec4 weights)\n{\n    vec4 r0 = vec4(0.0);\n    vec4 r1 = vec4(0.0);\n    vec4 r2 = vec4(0.0);\n    for (int i = 0; i < 4; i++)\n    {\n        int _204 = int((joints[i] * 255.0) + 0.5) * 3;\n        r0 += (fa_skin[_204 * 1 + 0] * weights[i]);\n        r1 += (fa_skin[(_204 + 1) * 1 + 0] * weights[i]);\n        r2 += (fa_skin[(_204 + 2) * 1 + 0] * weights[i]);\n    }\n    return mat4(vec4(r0.x, r1.x, r2.x, 0.0), vec4(r0.y, r1.y, r2.y, 0.0), vec4(r0.z, r1.z, r2.z, 0.0), vec4(r0.w, r1.w, r2.w, 1.0));\n}\n\nvec4 fa_time_now()\n{\n    return fa_mesh_vs_params[9];\n}\n\nVertexData fa_vertex_data(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    vec3 _113 = cross(model[1].xyz, model[2].xyz);\n    float _117 = (dot(model[0].xyz, _113) < 0.0) ? (-1.0) : 1.0;\n    return VertexData((model * vec4(position, 1.0)).xyz, (((_113 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _117, vec4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _117), texcoord0 * fa_mesh_vs_params[8].xy, color, position);\n}\n\nmat4 fa_rows_to_mat4(vec4 r0, vec4 r1, vec4 r2)\n{\n    return mat4(vec4(r0.x, r1.x, r2.x, 0.0), vec4(r0.y, r1.y, r2.y, 0.0), vec4(r0.z, r1.z, r2.z, 0.0), vec4(r0.w, r1.w, r2.w, 1.0));\n}\n\nvec4 fa_prev_pal_texel(int t)\n{\n    return texelFetch(fa_prev_pal_tex_fa_prev_pal_smp, ivec2(t & 1023, t >> 10), 0);\n}\n\nmat4 fa_prev_skin_matrix(vec4 joints, vec4 weights, int base)\n{\n    vec4 r0 = vec4(0.0);\n    vec4 r1 = vec4(0.0);\n    vec4 r2 = vec4(0.0);\n    for (int i = 0; i < 4; i++)\n    {\n        int _332 = base + (int((joints[i] * 255.0) + 0.5) * 3);\n        int param = _332;\n        r0 += (fa_prev_pal_texel(param) * weights[i]);\n        int param_1 = _332 + 1;\n        r1 += (fa_prev_pal_texel(param_1) * weights[i]);\n        int param_2 = _332 + 2;\n        r2 += (fa_prev_pal_texel(param_2) * weights[i]);\n    }\n    return mat4(vec4(r0.x, r1.x, r2.x, 0.0), vec4(r0.y, r1.y, r2.y, 0.0), vec4(r0.z, r1.z, r2.z, 0.0), vec4(r0.w, r1.w, r2.w, 1.0));\n}\n\nmat4 fa_prev_model()\n{\n    vec4 param = fa_prev_r0;\n    vec4 param_1 = fa_prev_r1;\n    vec4 param_2 = fa_prev_r2;\n    vec4 param_3 = fa_joints;\n    vec4 param_4 = fa_weights;\n    int param_5 = int(fa_vel_params[8].w + 0.5);\n    return fa_rows_to_mat4(param, param_1, param_2) * fa_prev_skin_matrix(param_3, param_4, param_5);\n}\n\nvoid fa_prepass_vertex(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color, bool has_prev)\n{\n    bool _475;\n    if (has_prev)\n    {\n        _475 = fa_vel_params[8].x > 0.5;\n    }\n    else\n    {\n        _475 = has_prev;\n    }\n    fa_vtime = fa_time_now();\n    mat4 param = model;\n    vec3 param_1 = position;\n    vec3 param_2 = normal;\n    vec4 param_3 = tangent;\n    vec2 param_4 = texcoord0;\n    vec4 param_5 = color;\n    VertexData _490 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    vec3 _720 = _490.world_pos;\n    mat4 _494 = mat4(fa_mesh_vs_params[4], fa_mesh_vs_params[5], fa_mesh_vs_params[6], fa_mesh_vs_params[7]);\n    vec4 _501 = vec4(_720, 1.0);\n    fa_world_pos = _720;\n    fa_world_normal = _490.world_normal;\n    fa_world_tangent = _490.world_tangent;\n    fa_uv = _490.uv;\n    fa_vertex_color = _490.color;\n    fa_pre_depth = -(_494 * _501).z;\n    fa_pre_r0 = vec3(_494[0].x, _494[1].x, _494[2].x);\n    fa_pre_r1 = vec3(_494[0].y, _494[1].y, _494[2].y);\n    fa_pre_r2 = vec3(_494[0].z, _494[1].z, _494[2].z);\n    gl_Position = mat4(fa_mesh_vs_params[0], fa_mesh_vs_params[1], fa_mesh_vs_params[2], fa_mesh_vs_params[3]) * _501;\n    fa_vel_cur = vec3(0.0, 0.0, 1.0);\n    fa_vel_prev = vec3(0.0);\n    if (_475)\n    {\n        vec4 _574 = vec4(position, 1.0);\n        fa_vel_cur = vec3((mat4(fa_vel_params[0], fa_vel_params[1], fa_vel_params[2], fa_vel_params[3]) * _501).xyw);\n        fa_vel_prev = vec3((mat4(fa_vel_params[4], fa_vel_params[5], fa_vel_params[6], fa_vel_params[7]) * vec4((_720 + (fa_prev_model() * _574).xyz) - (model * _574).xyz, 1.0)).xyw);\n    }\n}\n\nvoid main()\n{\n    fa_vtime = vec4(0.0);\n    fa_inst_begin();\n    vec4 param = fa_joints;\n    vec4 param_1 = fa_weights;\n    mat4 param_2 = mat4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3) * fa_skin_matrix(param, param_1);\n    vec3 param_3 = fa_position;\n    vec3 param_4 = fa_normal;\n    vec4 param_5 = fa_tangent;\n    vec2 param_6 = fa_texcoord0;\n    vec4 param_7 = fa_color;\n    bool param_8 = fa_vel_params[8].z > 0.5;\n    fa_prepass_vertex(param_2, param_3, param_4, param_5, param_6, param_7, param_8);\n}\n\n",
      "fs": "#version 430\n\nstruct SurfaceInput\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 vertex_color;\n    vec3 view_dir;\n    bool front_facing;\n};\n\nstruct Surface\n{\n    vec3 albedo;\n    float alpha;\n    vec3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    vec3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    vec3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    vec3 specular_color;\n    float transmission;\n    float thickness;\n    vec3 attenuation_color;\n    float attenuation_distance;\n};\n\nuniform vec4 fa_mesh_fs_params[54];\nlayout(binding = 0) uniform sampler2D fa_tex_fa_smp;\nlayout(binding = 1) uniform sampler2D fa_normal_tex_fa_smp;\nlayout(binding = 2) uniform sampler2D fa_mr_tex_fa_smp;\nlayout(binding = 3) uniform sampler2D fa_occlusion_tex_fa_smp;\nlayout(binding = 4) uniform sampler2D fa_emissive_tex_fa_smp;\n\nlayout(location = 0) in vec3 fa_world_pos;\nlayout(location = 1) in vec3 fa_world_normal;\nlayout(location = 2) in vec4 fa_world_tangent;\nlayout(location = 3) in vec2 fa_uv;\nlayout(location = 4) in vec4 fa_vertex_color;\nlayout(location = 6) in vec3 fa_pre_r0;\nlayout(location = 7) in vec3 fa_pre_r1;\nlayout(location = 8) in vec3 fa_pre_r2;\nlayout(location = 0) out vec4 fa_frag_color;\nlayout(location = 5) in float fa_pre_depth;\nlayout(location = 9) in vec3 fa_vel_cur;\nlayout(location = 10) in vec3 fa_vel_prev;\nlayout(location = 1) out vec2 fa_frag_velocity;\n\nvoid fa_inst_load()\n{\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nvec3 fa_linear_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_tex_fix(inout vec3 c, float mode)\n{\n    if (mode > 1.5)\n    {\n        vec3 param = c;\n        vec3 _172 = fa_linear_to_srgb(param);\n        c = _172;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            vec3 param_1 = c;\n            vec3 _181 = fa_srgb_to_linear(param_1);\n            c = _181;\n        }\n    }\n    return c;\n}\n\nvec3 fa_tangent_normal(SurfaceInput i, vec3 m)\n{\n    vec3 _56;\n    if (i.front_facing)\n    {\n        _56 = i.world_normal;\n    }\n    else\n    {\n        _56 = -i.world_normal;\n    }\n    vec3 _81 = normalize(i.world_tangent.xyz - (_56 * dot(_56, i.world_tangent.xyz)));\n    vec3 _109 = normalize(((_81 * m.x) + ((cross(_56, _81) * i.world_tangent.w) * m.y)) + (_56 * m.z));\n    vec3 _112;\n    if (i.front_facing)\n    {\n        _112 = _109;\n    }\n    else\n    {\n        _112 = -_109;\n    }\n    return _112;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    vec4 base_t = texture(fa_tex_fa_smp, i.uv, fa_mesh_fs_params[12].w);\n    float param = fa_mesh_fs_params[6].w;\n    float param_1 = 1.0;\n    vec3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    vec3 _230 = fa_tex_fix(param_2, param_3);\n    vec4 _889 = base_t;\n    _889.x = _230.x;\n    _889.y = _230.y;\n    _889.z = _230.z;\n    base_t = _889;\n    vec4 _246 = (_889 * fa_mesh_fs_params[2]) * i.vertex_color;\n    vec3 _844 = i.world_normal;\n    if (fa_mesh_fs_params[6].z > 0.5)\n    {\n        float param_4 = fa_mesh_fs_params[6].w;\n        float param_5 = 16.0;\n        vec3 param_6 = texture(fa_normal_tex_fa_smp, i.uv, fa_mesh_fs_params[12].w).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        vec3 _282 = fa_tex_fix(param_6, param_7);\n        vec3 _286 = (_282 * 2.0) - vec3(1.0);\n        vec2 _291 = _286.xy * fa_mesh_fs_params[6].x;\n        vec3 _897 = _286;\n        _897.x = _291.x;\n        _897.y = _291.y;\n        SurfaceInput param_8 = i;\n        vec3 param_9 = _897;\n        _844 = fa_tangent_normal(param_8, param_9);\n    }\n    vec4 mrt = texture(fa_mr_tex_fa_smp, i.uv, fa_mesh_fs_params[12].w);\n    float param_10 = fa_mesh_fs_params[6].w;\n    float param_11 = 64.0;\n    vec3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    vec3 _322 = fa_tex_fix(param_12, param_13);\n    vec4 _900 = mrt;\n    _900.x = _322.x;\n    _900.y = _322.y;\n    _900.z = _322.z;\n    mrt = _900;\n    vec4 _354 = texture(fa_occlusion_tex_fa_smp, i.uv, fa_mesh_fs_params[12].w);\n    float param_14 = fa_mesh_fs_params[6].w;\n    float param_15 = 256.0;\n    vec3 param_16 = _354.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    vec3 _366 = fa_tex_fix(param_16, param_17);\n    float param_18 = fa_mesh_fs_params[6].w;\n    float param_19 = 4.0;\n    vec3 param_20 = texture(fa_emissive_tex_fa_smp, i.uv, fa_mesh_fs_params[12].w).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    vec3 _398 = fa_tex_fix(param_20, param_21);\n    float _849 = fa_mesh_fs_params[20].x;\n    float _850 = fa_mesh_fs_params[20].y;\n    float _853 = fa_mesh_fs_params[20].z;\n    float _852 = fa_mesh_fs_params[21].w;\n    float _855 = fa_mesh_fs_params[22].x;\n    if (fa_mesh_fs_params[22].z > 0.5)\n    {\n        if (mod(fa_mesh_fs_params[22].z, 2.0) > 0.5)\n        {\n            _849 *= _366.y;\n            _850 *= _366.z;\n            _852 *= _354.w;\n        }\n        if (fa_mesh_fs_params[22].z > 1.5)\n        {\n            _853 *= mrt.x;\n            _855 *= mrt.w;\n        }\n    }\n    return Surface(_246.xyz, _246.w, _844, clamp(fa_mesh_fs_params[5].x * _322.z, 0.0, 1.0), clamp(fa_mesh_fs_params[5].y * _322.y, 0.0500000007450580596923828125, 1.0), 1.0 + (fa_mesh_fs_params[6].y * (_366.x - 1.0)), fa_mesh_fs_params[3].xyz + (fa_mesh_fs_params[4].xyz * _398), _849, _850, fa_mesh_fs_params[21].xyz, _852, _853, fa_mesh_fs_params[20].w, _855, fa_mesh_fs_params[22].y, fa_mesh_fs_params[23].xyz, fa_mesh_fs_params[30].x, fa_mesh_fs_params[30].y, fa_mesh_fs_params[31].xyz, fa_mesh_fs_params[30].z);\n}\n\nvoid surface(SurfaceInput i, Surface s)\n{\n}\n\nvoid main()\n{\n    fa_inst_load();\n    vec3 _739 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _739 = -_739;\n    }\n    vec3 _550 = normalize(fa_mesh_fs_params[0].xyz - fa_world_pos);\n    SurfaceInput param = SurfaceInput(fa_world_pos, _739, fa_world_tangent, fa_uv, fa_vertex_color, _550, gl_FrontFacing);\n    SurfaceInput param_1 = SurfaceInput(fa_world_pos, _739, fa_world_tangent, fa_uv, fa_vertex_color, _550, gl_FrontFacing);\n    Surface param_2 = fa_standard_surface(param);\n    surface(param_1, param_2);\n    vec3 _565 = normalize(param_2.normal);\n    vec3 _580 = normalize(vec3(dot(fa_pre_r0, _565), dot(fa_pre_r1, _565), dot(fa_pre_r2, _565)));\n    float _592 = _580.z;\n    vec2 e = _580.xy / vec2((abs(_580.x) + abs(_580.y)) + abs(_592));\n    if (_592 < 0.0)\n    {\n        e = (vec2(1.0) - abs(e.yx)) * vec2((e.x >= 0.0) ? 1.0 : (-1.0), (e.y >= 0.0) ? 1.0 : (-1.0));\n    }\n    fa_frag_color = vec4(min(fa_pre_depth, 60000.0), e, 1.0);\n    vec2 motion = vec2(1024.0);\n    bool _636 = fa_vel_cur.z > 9.9999997473787516355514526367188e-06;\n    bool _643;\n    if (_636)\n    {\n        _643 = fa_vel_prev.z > 9.9999997473787516355514526367188e-06;\n    }\n    else\n    {\n        _643 = _636;\n    }\n    if (_643)\n    {\n        motion = clamp(((vec2(fa_vel_prev.x, -fa_vel_prev.y) / vec2(fa_vel_prev.z)) * 0.5) - ((vec2(fa_vel_cur.x, -fa_vel_cur.y) / vec2(fa_vel_cur.z)) * 0.5), vec2(-4.0), vec2(4.0));\n    }\n    fa_frag_velocity = motion;\n}\n\n",
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
            "size": 864,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_214",
            "glsl_uniforms": [
              {
                "type": "vec4",
                "array_count": 54,
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
