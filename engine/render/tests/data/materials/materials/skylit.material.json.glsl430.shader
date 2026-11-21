{
  "format": "factoria.shader/1",
  "engine": "0.32.0",
  "template": "4a8331d4c52f4add9385ad09f3cee754aeec6a52a5c8c810972e182590f5426b",
  "slang": "glsl430",
  "params": [],
  "textures": [],
  "programs": {
    "mesh": {
      "vs": "#version 430\n\nstruct VertexData\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 color;\n    vec3 object_pos;\n};\n\nuniform vec4 fa_mesh_vs_params[11];\nlayout(location = 0) out vec3 fa_world_pos;\nlayout(location = 1) out vec3 fa_world_normal;\nlayout(location = 2) out vec4 fa_world_tangent;\nlayout(location = 3) out vec2 fa_uv;\nlayout(location = 4) out vec4 fa_vertex_color;\nlayout(location = 5) in vec4 fa_inst_m0;\nlayout(location = 6) in vec4 fa_inst_m1;\nlayout(location = 7) in vec4 fa_inst_m2;\nlayout(location = 8) in vec4 fa_inst_m3;\nlayout(location = 0) in vec3 fa_position;\nlayout(location = 1) in vec3 fa_normal;\nlayout(location = 3) in vec4 fa_tangent;\nlayout(location = 2) in vec2 fa_texcoord0;\nlayout(location = 4) in vec4 fa_color;\nlayout(location = 5) out vec3 fa_lm;\n\nvoid fa_inst_begin()\n{\n}\n\nVertexData fa_vertex_data(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    vec3 _69 = cross(model[1].xyz, model[2].xyz);\n    float _75 = (dot(model[0].xyz, _69) < 0.0) ? (-1.0) : 1.0;\n    return VertexData((model * vec4(position, 1.0)).xyz, (((_69 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _75, vec4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _75), texcoord0 * fa_mesh_vs_params[8].xy, color, position);\n}\n\nvoid fa_shade_vertex(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    mat4 param = model;\n    vec3 param_1 = position;\n    vec3 param_2 = normal;\n    vec4 param_3 = tangent;\n    vec2 param_4 = texcoord0;\n    vec4 param_5 = color;\n    VertexData _160 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    vec3 _267 = _160.world_pos;\n    fa_world_pos = _267;\n    fa_world_normal = _160.world_normal;\n    fa_world_tangent = _160.world_tangent;\n    fa_uv = _160.uv;\n    fa_vertex_color = _160.color;\n    gl_Position = mat4(fa_mesh_vs_params[0], fa_mesh_vs_params[1], fa_mesh_vs_params[2], fa_mesh_vs_params[3]) * vec4(_267, 1.0);\n}\n\nvoid main()\n{\n    fa_inst_begin();\n    mat4 param = mat4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3);\n    vec3 param_1 = fa_position;\n    vec3 param_2 = fa_normal;\n    vec4 param_3 = fa_tangent;\n    vec2 param_4 = fa_texcoord0;\n    vec4 param_5 = fa_color;\n    fa_shade_vertex(param, param_1, param_2, param_3, param_4, param_5);\n    fa_lm = vec3(0.0);\n}\n\n",
      "fs": "#version 430\n\nstruct SurfaceInput\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 vertex_color;\n    vec3 view_dir;\n    bool front_facing;\n};\n\nstruct LightSample\n{\n    vec3 direction;\n    vec3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct Surface\n{\n    vec3 albedo;\n    float alpha;\n    vec3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    vec3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    vec3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    vec3 specular_color;\n    float transmission;\n    float thickness;\n    vec3 attenuation_color;\n    float attenuation_distance;\n};\n\nstruct FaLayers\n{\n    bool on;\n    float f90;\n    float keep;\n    float base_scale;\n    float coat;\n    float coat_rough;\n    float coat_alpha;\n    float coat_a2;\n    vec3 nc;\n    float coat_ndv;\n    bool sheen_on;\n    vec3 sheen;\n    float sheen_rough;\n    float sheen_alpha;\n    float sheen_scale;\n    float sheen_e;\n    float aniso;\n    vec3 t;\n    vec3 b;\n    float at;\n    float ab;\n};\n\nconst float _4172[63] = float[](1.0, 1.0, 1.0, 0.4790000021457672119140625, 0.11699999868869781494140625, 0.01200000010430812835693359375, 0.0, 0.0, 0.0, 1.0, 1.0, 1.0, 0.578000009059906005859375, 0.19300000369548797607421875, 0.0350000001490116119384765625, 0.0030000000260770320892333984375, 0.0, 0.0, 1.0, 1.0, 1.0, 0.6740000247955322265625, 0.3459999859333038330078125, 0.1319999992847442626953125, 0.032999999821186065673828125, 0.0040000001899898052215576171875, 0.0, 0.971000015735626220703125, 0.954999983310699462890625, 0.828999996185302734375, 0.63999998569488525390625, 0.42599999904632568359375, 0.24500000476837158203125, 0.115000002086162567138671875, 0.037000000476837158203125, 0.0030000000260770320892333984375, 0.7469999790191650390625, 0.737999975681304931640625, 0.670000016689300537109375, 0.563000023365020751953125, 0.4309999942779541015625, 0.3039999902248382568359375, 0.1940000057220458984375, 0.1019999980926513671875, 0.0309999994933605194091796875, 0.614000022411346435546875, 0.609000027179718017578125, 0.566999971866607666015625, 0.499000012874603271484375, 0.412000000476837158203125, 0.32400000095367431640625, 0.240999996662139892578125, 0.162000000476837158203125, 0.087999999523162841796875, 0.538999974727630615234375, 0.535000026226043701171875, 0.505999982357025146484375, 0.4569999873638153076171875, 0.393999993801116943359375, 0.328999996185302734375, 0.2660000026226043701171875, 0.203999996185302734375, 0.14200000464916229248046875);\n\nuniform vec4 fa_mesh_fs_params[53];\nuniform vec4 fa_shadows[30];\nlayout(binding = 0) uniform sampler2D fa_light_tex_fa_shadow_smp;\nlayout(binding = 1) uniform sampler2D fa_tex_fa_smp;\nlayout(binding = 2) uniform sampler2D fa_normal_tex_fa_smp;\nlayout(binding = 3) uniform sampler2D fa_mr_tex_fa_smp;\nlayout(binding = 4) uniform sampler2D fa_occlusion_tex_fa_smp;\nlayout(binding = 5) uniform sampler2D fa_emissive_tex_fa_smp;\nlayout(binding = 6) uniform sampler2D fa_decal_tex_fa_env_smp;\nlayout(binding = 7) uniform sampler2D fa_lightmap_fa_env_smp;\nlayout(binding = 8) uniform sampler2D fa_probe_atlas_fa_env_smp;\nlayout(binding = 9) uniform sampler2D fa_light_atlas_fa_env_smp;\nlayout(binding = 10) uniform sampler2D fa_shadow_tex_fa_shadow_smp;\nlayout(binding = 11) uniform sampler2D fa_screen_tex_fa_shadow_smp;\n\nlayout(location = 0) in vec3 fa_world_pos;\nlayout(location = 5) in vec3 fa_lm;\nlayout(location = 1) in vec3 fa_world_normal;\nlayout(location = 2) in vec4 fa_world_tangent;\nlayout(location = 3) in vec2 fa_uv;\nlayout(location = 4) in vec4 fa_vertex_color;\nlayout(location = 0) out vec4 fa_frag_color;\nvec3 fa_light_tint;\nbool fa_light_is_area;\nint fa_cl_ndir;\nint fa_cl_slot;\nint fa_cl_local;\n\nvoid fa_inst_load()\n{\n}\n\nvec4 fa_light_texel(int t)\n{\n    return texelFetch(fa_light_tex_fa_shadow_smp, ivec2(t & 1023, t >> 10), 0);\n}\n\nvec4 fa_cluster_texel(vec3 world_pos)\n{\n    bool _1427 = fa_mesh_fs_params[19].x < 0.0;\n    bool _1434;\n    if (!_1427)\n    {\n        _1434 = fa_mesh_fs_params[19].w < 1.0;\n    }\n    else\n    {\n        _1434 = _1427;\n    }\n    bool _1442;\n    if (!_1434)\n    {\n        _1442 = fa_mesh_fs_params[18].x < 1.0;\n    }\n    else\n    {\n        _1442 = _1434;\n    }\n    bool _1449;\n    if (!_1442)\n    {\n        _1449 = fa_mesh_fs_params[18].y < 1.0;\n    }\n    else\n    {\n        _1449 = _1442;\n    }\n    bool _1456;\n    if (!_1449)\n    {\n        _1456 = fa_mesh_fs_params[19].y < 1.0;\n    }\n    else\n    {\n        _1456 = _1449;\n    }\n    if (_1456)\n    {\n        return vec4(0.0);\n    }\n    vec4 _1466 = vec4(world_pos, 1.0);\n    float _1472 = dot(fa_mesh_fs_params[16], _1466);\n    if (!(_1472 > 9.9999999747524270787835121154785e-07))\n    {\n        return vec4(0.0);\n    }\n    vec2 _1494 = vec2(dot(fa_mesh_fs_params[14], _1466), dot(fa_mesh_fs_params[15], _1466)) / vec2(_1472);\n    int _1498 = int(fa_mesh_fs_params[18].x);\n    int _1502 = int(fa_mesh_fs_params[18].y);\n    int param = (int(fa_mesh_fs_params[19].x) + (((clamp(int(floor(log2(max(dot(fa_mesh_fs_params[17].xyz, world_pos) + fa_mesh_fs_params[17].w, fa_mesh_fs_params[18].w) / fa_mesh_fs_params[18].w) * fa_mesh_fs_params[18].z)), 0, int(fa_mesh_fs_params[19].y) - 1) * _1502) + clamp(int(floor(((_1494.y * 0.5) + 0.5) * fa_mesh_fs_params[18].y)), 0, _1502 - 1)) * _1498)) + clamp(int(floor(((_1494.x * 0.5) + 0.5) * fa_mesh_fs_params[18].x)), 0, _1498 - 1);\n    return fa_light_texel(param);\n}\n\nivec2 fa_cluster_lookup(vec3 world_pos)\n{\n    vec3 param = world_pos;\n    vec4 _1578 = fa_cluster_texel(param);\n    return ivec2(int(_1578.x), int(_1578.y));\n}\n\nvoid fa_cluster_begin(vec3 world_pos)\n{\n    fa_cl_ndir = int(fa_mesh_fs_params[19].z);\n    vec3 param = world_pos;\n    ivec2 _4981 = fa_cluster_lookup(param);\n    fa_cl_slot = _4981.x;\n    fa_cl_local = _4981.y;\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_linear_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvec3 fa_tex_fix(inout vec3 c, float mode)\n{\n    if (mode > 1.5)\n    {\n        vec3 param = c;\n        vec3 _5193 = fa_linear_to_srgb(param);\n        c = _5193;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            vec3 param_1 = c;\n            vec3 _5201 = fa_srgb_to_linear(param_1);\n            c = _5201;\n        }\n    }\n    return c;\n}\n\nvec3 fa_tangent_normal(SurfaceInput i, vec3 m)\n{\n    vec3 _381;\n    if (i.front_facing)\n    {\n        _381 = i.world_normal;\n    }\n    else\n    {\n        _381 = -i.world_normal;\n    }\n    vec3 _405 = normalize(i.world_tangent.xyz - (_381 * dot(_381, i.world_tangent.xyz)));\n    vec3 _432 = normalize(((_405 * m.x) + ((cross(_381, _405) * i.world_tangent.w) * m.y)) + (_381 * m.z));\n    vec3 _435;\n    if (i.front_facing)\n    {\n        _435 = _432;\n    }\n    else\n    {\n        _435 = -_432;\n    }\n    return _435;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    vec4 base_t = texture(fa_tex_fa_smp, i.uv);\n    float param = fa_mesh_fs_params[6].w;\n    float param_1 = 1.0;\n    vec3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    vec3 _5232 = fa_tex_fix(param_2, param_3);\n    vec4 _7051 = base_t;\n    _7051.x = _5232.x;\n    _7051.y = _5232.y;\n    _7051.z = _5232.z;\n    base_t = _7051;\n    vec4 _5246 = (_7051 * fa_mesh_fs_params[2]) * i.vertex_color;\n    vec3 _6857 = i.world_normal;\n    if (fa_mesh_fs_params[6].z > 0.5)\n    {\n        float param_4 = fa_mesh_fs_params[6].w;\n        float param_5 = 16.0;\n        vec3 param_6 = texture(fa_normal_tex_fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        vec3 _5278 = fa_tex_fix(param_6, param_7);\n        vec3 _5281 = (_5278 * 2.0) - vec3(1.0);\n        vec2 _5286 = _5281.xy * fa_mesh_fs_params[6].x;\n        vec3 _7059 = _5281;\n        _7059.x = _5286.x;\n        _7059.y = _5286.y;\n        SurfaceInput param_8 = i;\n        vec3 param_9 = _7059;\n        _6857 = fa_tangent_normal(param_8, param_9);\n    }\n    vec4 mrt = texture(fa_mr_tex_fa_smp, i.uv);\n    float param_10 = fa_mesh_fs_params[6].w;\n    float param_11 = 64.0;\n    vec3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    vec3 _5314 = fa_tex_fix(param_12, param_13);\n    vec4 _7062 = mrt;\n    _7062.x = _5314.x;\n    _7062.y = _5314.y;\n    _7062.z = _5314.z;\n    mrt = _7062;\n    vec4 _5342 = texture(fa_occlusion_tex_fa_smp, i.uv);\n    float param_14 = fa_mesh_fs_params[6].w;\n    float param_15 = 256.0;\n    vec3 param_16 = _5342.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    vec3 _5353 = fa_tex_fix(param_16, param_17);\n    float param_18 = fa_mesh_fs_params[6].w;\n    float param_19 = 4.0;\n    vec3 param_20 = texture(fa_emissive_tex_fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    vec3 _5383 = fa_tex_fix(param_20, param_21);\n    float _6862 = fa_mesh_fs_params[20].x;\n    float _6863 = fa_mesh_fs_params[20].y;\n    float _6866 = fa_mesh_fs_params[20].z;\n    float _6865 = fa_mesh_fs_params[21].w;\n    float _6868 = fa_mesh_fs_params[22].x;\n    if (fa_mesh_fs_params[22].z > 0.5)\n    {\n        if (mod(fa_mesh_fs_params[22].z, 2.0) > 0.5)\n        {\n            _6862 *= _5353.y;\n            _6863 *= _5353.z;\n            _6865 *= _5342.w;\n        }\n        if (fa_mesh_fs_params[22].z > 1.5)\n        {\n            _6866 *= mrt.x;\n            _6868 *= mrt.w;\n        }\n    }\n    return Surface(_5246.xyz, _5246.w, _6857, clamp(fa_mesh_fs_params[5].x * _5314.z, 0.0, 1.0), clamp(fa_mesh_fs_params[5].y * _5314.y, 0.0500000007450580596923828125, 1.0), 1.0 + (fa_mesh_fs_params[6].y * (_5353.x - 1.0)), fa_mesh_fs_params[3].xyz + (fa_mesh_fs_params[4].xyz * _5383), _6862, _6863, fa_mesh_fs_params[21].xyz, _6865, _6866, fa_mesh_fs_params[20].w, _6868, fa_mesh_fs_params[22].y, fa_mesh_fs_params[23].xyz, fa_mesh_fs_params[30].x, fa_mesh_fs_params[30].y, fa_mesh_fs_params[31].xyz, fa_mesh_fs_params[30].z);\n}\n\nvoid surface(SurfaceInput i, Surface s)\n{\n}\n\nvec4 fa_decal_tile(vec4 rect, vec2 uv, vec2 atlas, vec2 ddx, vec2 ddy)\n{\n    vec2 _1658 = rect.zw - rect.xy;\n    vec2 _1662 = _1658 * atlas;\n    vec2 _1666 = ddx * _1662;\n    vec2 _1670 = ddy * _1662;\n    return textureLod(fa_decal_tex_fa_env_smp, rect.xy + (clamp(uv, vec2(0.0), vec2(1.0)) * _1658), clamp(0.5 * log2(max(max(dot(_1666, _1666), dot(_1670, _1670)), 9.9999999392252902907785028219223e-09)), 0.0, 4.0));\n}\n\nvec3 fa_dc_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_dc_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvoid fa_apply_decals(vec3 world_pos, vec3 geo_normal, inout vec3 albedo, inout vec3 normal)\n{\n    bool _1703 = fa_mesh_fs_params[10].y < 0.5;\n    bool _1710;\n    if (!_1703)\n    {\n        _1710 = fa_mesh_fs_params[10].w < 0.5;\n    }\n    else\n    {\n        _1710 = _1703;\n    }\n    if (_1710)\n    {\n        return;\n    }\n    vec3 _1716 = dFdx(world_pos);\n    vec3 _1719 = dFdy(world_pos);\n    vec3 param = world_pos;\n    vec4 _1723 = fa_cluster_texel(param);\n    int _1727 = int(_1723.w);\n    if (_1727 < 1)\n    {\n        return;\n    }\n    int _1737 = int(fa_mesh_fs_params[10].y + 0.5);\n    int param_1 = _1737;\n    vec4 _1741 = fa_light_texel(param_1);\n    vec2 _1744 = _1741.yz;\n    int _1748 = int(_1741.w);\n    int param_2 = _1737 + 1;\n    vec4 _1753 = fa_light_texel(param_2);\n    float _1754 = _1753.x;\n    int _1760 = int(fa_mesh_fs_params[10].w + 0.5) - 1;\n    int _1764 = int(_1723.z);\n    vec3 _2029;\n    for (int k = 0; k < _1727; k++)\n    {\n        int _1777 = _1764 + k;\n        int param_3 = _1748 + (_1777 >> 2);\n        int _1794 = (_1737 + 2) + (int(fa_light_texel(param_3)[_1777 & 3]) * 7);\n        int param_4 = _1794 + 6;\n        vec4 _1799 = fa_light_texel(param_4);\n        if (((int(_1799.w + 0.5) >> _1760) & 1) == 0)\n        {\n            continue;\n        }\n        int param_5 = _1794;\n        vec4 _1814 = fa_light_texel(param_5);\n        int param_6 = _1794 + 1;\n        vec4 _1819 = fa_light_texel(param_6);\n        int param_7 = _1794 + 2;\n        vec4 _1824 = fa_light_texel(param_7);\n        vec3 _1827 = _1814.xyz;\n        float _1832 = dot(_1827, world_pos) + _1814.w;\n        vec3 _1834 = _1819.xyz;\n        float _1839 = dot(_1834, world_pos) + _1819.w;\n        vec3 _1841 = _1824.xyz;\n        float _1846 = dot(_1841, world_pos) + _1824.w;\n        bool _1851 = abs(_1832) > 0.5;\n        bool _1859;\n        if (!_1851)\n        {\n            _1859 = abs(_1839) > 0.5;\n        }\n        else\n        {\n            _1859 = _1851;\n        }\n        bool _1867;\n        if (!_1859)\n        {\n            _1867 = abs(_1846) > 0.5;\n        }\n        else\n        {\n            _1867 = _1859;\n        }\n        if (_1867)\n        {\n            continue;\n        }\n        float _1882 = clamp(dot(geo_normal, normalize(_1841)) * _1799.z, 0.0, 1.0);\n        if (_1882 <= 0.0)\n        {\n            continue;\n        }\n        float _1902 = (clamp((0.5 - abs(_1846)) * 10.0, 0.0, 1.0) * _1882) * _1799.x;\n        vec2 _1910 = vec2(_1832 + 0.5, 0.5 - _1839);\n        vec2 _1920 = vec2(dot(_1827, _1716), dot(_1834, _1716));\n        vec2 _1930 = vec2(dot(_1827, _1719), dot(_1834, _1719));\n        int param_8 = _1794 + 5;\n        vec4 _1935 = fa_light_texel(param_8);\n        int param_9 = _1794 + 3;\n        vec4 _1940 = fa_light_texel(param_9);\n        int param_10 = _1794 + 4;\n        vec4 _1945 = fa_light_texel(param_10);\n        float tex_a = 1.0;\n        vec3 col = _1935.xyz;\n        bool _1955 = _1940.z > _1940.x;\n        if (_1955)\n        {\n            vec4 param_11 = _1940;\n            vec2 param_12 = _1910;\n            vec2 param_13 = _1744;\n            vec2 param_14 = _1920;\n            vec2 param_15 = _1930;\n            vec4 tx = fa_decal_tile(param_11, param_12, param_13, param_14, param_15);\n            if ((_1754 > 0.5) && (_1754 < 1.5))\n            {\n                vec3 param_16 = tx.xyz;\n                vec3 _1981 = fa_dc_to_linear(param_16);\n                vec4 _6945 = tx;\n                _6945.x = _1981.x;\n                _6945.y = _1981.y;\n                _6945.z = _1981.z;\n                tx = _6945;\n            }\n            col *= tx.xyz;\n            tex_a = tx.w;\n        }\n        albedo = mix(albedo, col, vec3(clamp((_1902 * tex_a) * _1935.w, 0.0, 1.0)));\n        if (_1945.z > _1945.x)\n        {\n            vec4 param_17 = _1945;\n            vec2 param_18 = _1910;\n            vec2 param_19 = _1744;\n            vec2 param_20 = _1920;\n            vec2 param_21 = _1930;\n            vec4 _2025 = fa_decal_tile(param_17, param_18, param_19, param_20, param_21);\n            if (_1754 > 1.5)\n            {\n                vec3 param_22 = _2025.xyz;\n                vec3 _2035 = fa_dc_to_srgb(param_22);\n                _2029 = _2035;\n            }\n            else\n            {\n                _2029 = _2025.xyz;\n            }\n            vec3 _2044 = (_2029 * 2.0) - vec3(1.0);\n            vec2 _2049 = _2044.xy * _1799.y;\n            vec3 _2071 = (normalize(_1827) * _2049.x) + (normalize(_1834) * _2049.y);\n            vec3 _2074 = normalize(normal);\n            normal = normalize(mix(_2074, normalize((_2074 * max(_2044.z, 0.0500000007450580596923828125)) + (_2071 - (_2074 * dot(_2074, _2071)))), vec3(clamp(_1902 * (_1955 ? tex_a : 1.0), 0.0, 1.0))));\n        }\n    }\n}\n\nvec3 fa_sh_eval(vec3 c[9], vec3 n)\n{\n    vec3 _3269 = max((((c[0] * 0.2820948064327239990234375) + (((c[1] * (0.3257350027561187744140625 * n.y)) + (c[2] * (0.3257350027561187744140625 * n.z))) + (c[3] * (0.3257350027561187744140625 * n.x)))) + (((c[4] * ((0.2731371223926544189453125 * n.x) * n.y)) + (c[5] * ((0.2731371223926544189453125 * n.y) * n.z))) + (c[6] * (0.078847892582416534423828125 * (((3.0 * n.z) * n.z) - 1.0))))) + ((c[7] * ((0.2731371223926544189453125 * n.x) * n.z)) + (c[8] * (0.13656856119632720947265625 * ((n.x * n.x) - (n.y * n.y))))), vec3(0.0));\n    return _3269;\n}\n\nvec2 fa_atlas_size()\n{\n    return vec2(textureSize(fa_probe_atlas_fa_env_smp, 0));\n}\n\nvec4 fa_gi_fetch(vec2 texel)\n{\n    return textureLod(fa_probe_atlas_fa_env_smp, texel / fa_atlas_size(), 0.0);\n}\n\nvec2 fa_oct_encode(vec3 d)\n{\n    vec3 _3289 = d / vec3(max((abs(d.x) + abs(d.y)) + abs(d.z), 9.9999999600419720025001879548654e-13));\n    float _3292 = _3289.x;\n    float _3294 = _3289.z;\n    vec2 e = vec2(_3292, _3294);\n    if (_3289.y < 0.0)\n    {\n        e = vec2((1.0 - abs(_3294)) * ((_3292 < 0.0) ? (-1.0) : 1.0), (1.0 - abs(_3292)) * ((_3294 < 0.0) ? (-1.0) : 1.0));\n    }\n    return e;\n}\n\nvec3 fa_gi_grid(int rec, vec3 n, vec3 v, out float cover)\n{\n    cover = 0.0;\n    int param = rec;\n    vec4 _5495 = fa_light_texel(param);\n    int param_1 = rec + 1;\n    vec4 _5500 = fa_light_texel(param_1);\n    int param_2 = rec + 2;\n    vec4 _5505 = fa_light_texel(param_2);\n    int param_3 = rec + 3;\n    vec4 _5510 = fa_light_texel(param_3);\n    bool _5513 = _5510.z < 0.5;\n    bool _5521;\n    if (!_5513)\n    {\n        _5521 = fa_atlas_size().y < 1155.0;\n    }\n    else\n    {\n        _5521 = _5513;\n    }\n    if (_5521)\n    {\n        return vec3(0.0);\n    }\n    float _5528 = max(_5495.w, 9.9999997473787516355514526367188e-05);\n    vec3 _5531 = _5500.xyz;\n    vec3 _5535 = _5495.xyz;\n    vec3 _5539 = (fa_world_pos - _5535) / vec3(_5528);\n    vec3 _5548 = min(_5539 + vec3(0.5), (_5531 - vec3(0.5)) - _5539);\n    float _5557 = min(_5548.x, min(_5548.y, _5548.z));\n    if (!(_5557 > 0.0))\n    {\n        return vec3(0.0);\n    }\n    vec3 _5572 = _5531 - vec3(1.0);\n    vec3 _5573 = clamp(_5539, vec3(0.0), _5572);\n    vec3 _5581 = min(floor(_5573), max(_5531 - vec3(2.0), vec3(0.0)));\n    vec3 _5585 = _5573 - _5581;\n    vec3 _5596 = fa_world_pos + (((n * 0.800000011920928955078125) + (v * 0.20000000298023223876953125)) * (0.20000000298023223876953125 * _5528));\n    int _5601 = int(_5505.y + 0.5);\n    vec3 sh[9];\n    for (int k = 0; k < 9; k++)\n    {\n        sh[k] = vec3(0.0);\n    }\n    float wsum = 0.0;\n    int _5619 = int(_5510.w);\n    int _5620 = 8 + _5619;\n    int _5625 = 9 + _5619;\n    float _5652;\n    float _5665;\n    float _5679;\n    for (int k_1 = 0; k_1 < _5620; k_1++)\n    {\n        float _5638 = float(k_1 & 1);\n        float _5642 = float((k_1 >> 1) & 1);\n        float _5646 = float((k_1 >> 2) & 1);\n        if (_5638 > 0.5)\n        {\n            _5652 = _5585.x;\n        }\n        else\n        {\n            _5652 = 1.0 - _5585.x;\n        }\n        if (_5642 > 0.5)\n        {\n            _5665 = _5585.y;\n        }\n        else\n        {\n            _5665 = 1.0 - _5585.y;\n        }\n        if (_5646 > 0.5)\n        {\n            _5679 = _5585.z;\n        }\n        else\n        {\n            _5679 = 1.0 - _5585.z;\n        }\n        float _5689 = (_5652 * _5665) * _5679;\n        if (!(_5689 > 0.0))\n        {\n            continue;\n        }\n        vec3 _5702 = min(_5581 + vec3(_5638, _5642, _5646), _5572);\n        int _5722 = int(((_5505.x + _5702.x) + (_5500.x * (_5702.y + (_5500.y * _5702.z)))) + 0.5);\n        vec2 _5737 = vec2(float(_5722 % _5601) * 10.0, 1024.0 + (float(_5722 / _5601) * 11.0));\n        vec2 param_4 = _5737 + vec2(9.5, 10.5);\n        vec4 _5745 = fa_gi_fetch(param_4);\n        bool _5748 = _5745.y < 0.5;\n        bool _5757;\n        if (!_5748)\n        {\n            _5757 = _5745.x > _5510.y;\n        }\n        else\n        {\n            _5757 = _5748;\n        }\n        if (_5757)\n        {\n            continue;\n        }\n        vec3 _5769 = _5596 - (_5535 + (_5702 * _5528));\n        float _5772 = length(_5769);\n        vec3 _5778 = _5769 / vec3(max(_5772, 9.9999997473787516355514526367188e-05));\n        float _5788 = max(9.9999997473787516355514526367188e-05, (dot(-_5778, n) + 1.0) * 0.5);\n        float w = _5689 * (_5788 * _5788);\n        vec3 param_5 = _5778;\n        vec2 param_6 = (_5737 + vec2(1.0)) + (((fa_oct_encode(param_5) * 0.5) + vec2(0.5)) * 8.0);\n        vec4 _5807 = fa_gi_fetch(param_6);\n        float _5814 = _5772 / max(_5505.z, 9.9999997473787516355514526367188e-05);\n        float _5817 = _5807.x;\n        if (_5814 > _5817)\n        {\n            float _5830 = max(_5807.y - (_5817 * _5817), 0.0);\n            float _5835 = _5814 - _5817;\n            float _5844 = _5830 / max(_5830 + (_5835 * _5835), 9.9999999600419720025001879548654e-13);\n            w *= ((_5844 * _5844) * _5844);\n        }\n        if (!(w > 0.0))\n        {\n            continue;\n        }\n        for (int c = 0; c < _5625; c++)\n        {\n            vec2 param_7 = _5737 + vec2(float(c) + 0.5, 10.5);\n            sh[c] += (fa_gi_fetch(param_7).xyz * w);\n        }\n        wsum += w;\n    }\n    if (!(wsum > 9.9999997473787516355514526367188e-06))\n    {\n        return vec3(0.0);\n    }\n    for (int c_1 = 0; c_1 < 9; c_1++)\n    {\n        sh[c_1] /= vec3(wsum);\n    }\n    cover = smoothstep(0.0, 1.0, clamp(_5557 * 2.0, 0.0, 1.0)) * smoothstep(0.0, 0.0199999995529651641845703125, wsum);\n    float _5925;\n    if (fa_mesh_fs_params[52].z > 0.5)\n    {\n        _5925 = _5510.x;\n    }\n    else\n    {\n        _5925 = 1.0;\n    }\n    vec3 param_8[9] = sh;\n    vec3 param_9 = n;\n    return fa_sh_eval(param_8, param_9) * (_5505.w * _5925);\n}\n\nvec3 fa_gi_light(vec3 n, inout float left)\n{\n    left = 1.0;\n    vec3 acc = vec3(0.0);\n    vec3 _5949 = normalize(fa_mesh_fs_params[0].xyz - fa_world_pos);\n    int _5954 = int(fa_mesh_fs_params[52].x + 0.5);\n    int _5959 = int(fa_mesh_fs_params[52].y + 0.5);\n    float param_3;\n    for (int k = 0; (k < _5959) && (k < 8); k++)\n    {\n        int param = _5954 + (4 * k);\n        vec3 param_1 = n;\n        vec3 param_2 = _5949;\n        vec3 _5984 = fa_gi_grid(param, param_1, param_2, param_3);\n        float _5989 = param_3 * left;\n        acc += (_5984 * _5989);\n        left -= _5989;\n        if (left < 0.001000000047497451305389404296875)\n        {\n            left = 0.0;\n            break;\n        }\n    }\n    return acc;\n}\n\nvec3 fa_probe_sh_coef(vec2 origin, float res, int k)\n{\n    vec3 v = textureLod(fa_probe_atlas_fa_env_smp, (origin + vec2(float(k) + 0.5, res + 2.5)) / fa_atlas_size(), 0.0).xyz;\n    if (fa_mesh_fs_params[41].y > 0.5)\n    {\n        v = (v - vec3(0.5)) * 8.0;\n    }\n    return v;\n}\n\nvec3 fa_ambient_light(vec3 n)\n{\n    float _3879 = (1.0 - fa_mesh_fs_params[42].w) - fa_mesh_fs_params[47].w;\n    vec3 amb = vec3(0.0);\n    bool _3884 = fa_mesh_fs_params[11].w > 0.5;\n    vec3 c[9];\n    for (int k = 0; k < 9; k++)\n    {\n        c[k] = vec3(0.0);\n    }\n    if (_3879 > 0.0005000000237487256526947021484375)\n    {\n        if (_3884)\n        {\n            for (int k_1 = 0; k_1 < 9; k_1++)\n            {\n                vec2 param = fa_mesh_fs_params[41].zw;\n                float param_1 = 128.0;\n                int param_2 = k_1;\n                c[k_1] = fa_probe_sh_coef(param, param_1, param_2) * _3879;\n            }\n        }\n        else\n        {\n            amb = fa_mesh_fs_params[1].xyz * _3879;\n        }\n    }\n    bool _3935 = fa_mesh_fs_params[42].w > 0.0;\n    if (_3935)\n    {\n        for (int k_2 = 0; k_2 < 9; k_2++)\n        {\n            vec2 param_3 = fa_mesh_fs_params[42].xy;\n            float param_4 = fa_mesh_fs_params[42].z;\n            int param_5 = k_2;\n            c[k_2] += (fa_probe_sh_coef(param_3, param_4, param_5) * fa_mesh_fs_params[42].w);\n        }\n    }\n    bool _3966 = fa_mesh_fs_params[47].w > 0.0;\n    if (_3966)\n    {\n        for (int k_3 = 0; k_3 < 9; k_3++)\n        {\n            vec2 param_6 = fa_mesh_fs_params[47].xy;\n            float param_7 = fa_mesh_fs_params[47].z;\n            int param_8 = k_3;\n            c[k_3] += (fa_probe_sh_coef(param_6, param_7, param_8) * fa_mesh_fs_params[47].w);\n        }\n    }\n    if ((_3884 || _3935) || _3966)\n    {\n        vec3 param_9[9] = c;\n        vec3 param_10 = n;\n        amb += fa_sh_eval(param_9, param_10);\n    }\n    return amb;\n}\n\nvec3 fa_realtime_or_ambient(vec3 n)\n{\n    if (fa_mesh_fs_params[52].y > 0.5)\n    {\n        vec3 param = n;\n        float param_1;\n        vec3 _6018 = fa_gi_light(param, param_1);\n        if (param_1 < 0.999000012874603271484375)\n        {\n            vec3 _6027;\n            if (param_1 > 0.0)\n            {\n                vec3 param_2 = n;\n                _6027 = _6018 + (fa_ambient_light(param_2) * param_1);\n            }\n            else\n            {\n                _6027 = _6018;\n            }\n            return _6027;\n        }\n    }\n    vec3 param_3 = n;\n    return fa_ambient_light(param_3);\n}\n\nvec3 fa_indirect_diffuse(vec3 n)\n{\n    if (fa_lm.z > 0.5)\n    {\n        return textureLod(fa_lightmap_fa_env_smp, fa_lm.xy, 0.0).xyz;\n    }\n    if (fa_mesh_fs_params[32].w > 0.0)\n    {\n        vec3 c[9];\n        for (int k = 0; k < 9; k++)\n        {\n            c[k] = fa_mesh_fs_params[k * 1 + 32].xyz;\n        }\n        vec3 param[9] = c;\n        vec3 param_1 = n;\n        vec3 _6089 = fa_sh_eval(param, param_1);\n        if (fa_mesh_fs_params[32].w >= 1.0)\n        {\n            return _6089;\n        }\n        vec3 param_2 = n;\n        return mix(fa_realtime_or_ambient(param_2), _6089, vec3(clamp(fa_mesh_fs_params[32].w, 0.0, 1.0)));\n    }\n    vec3 param_3 = n;\n    return fa_realtime_or_ambient(param_3);\n}\n\nfloat fa_sheen_albedo(float ndv, float rough)\n{\n    float _4098 = min(sqrt(max(rough - 0.100000001490116119384765625, 0.0) * 1.111111164093017578125) * 6.0, 5.999000072479248046875);\n    float _4105 = min(sqrt(clamp(ndv, 0.0, 1.0)) * 8.0, 7.999000072479248046875);\n    int _4108 = int(_4098);\n    int _4111 = int(_4105);\n    float _4121 = _4105 - float(_4111);\n    int _4176 = (_4108 * 9) + _4111;\n    int _4196 = ((_4108 + 1) * 9) + _4111;\n    return mix(mix(_4172[_4176], _4172[_4176 + 1], _4121), mix(_4172[_4196], _4172[_4196 + 1], _4121), _4098 - float(_4108));\n}\n\nFaLayers fa_layers_setup(SurfaceInput i, Surface s, vec3 n, vec3 v, float metallic, float roughness, inout vec3 f0)\n{\n    bool _6716 = false;\n    float _6717 = 1.0;\n    float _6718 = 1.0;\n    float _6719 = 1.0;\n    float _6720 = 0.0;\n    float _6721 = 0.0;\n    float _6722 = 0.0;\n    float _6723 = 0.0;\n    float _6725 = 1.0;\n    bool _6726 = false;\n    vec3 _6727 = vec3(0.0);\n    float _6728 = 1.0;\n    float _6729 = 1.0;\n    float _6730 = 1.0;\n    float _6731 = 0.0;\n    float _6732 = 0.0;\n    vec3 _6733 = vec3(1.0, 0.0, 0.0);\n    vec3 _6734 = vec3(0.0, 0.0, 1.0);\n    float _6735 = 1.0;\n    float _6736 = 1.0;\n    float _4247 = clamp(s.specular, 0.0, 1.0);\n    float _4251 = clamp(s.ior, 1.0, 3.0);\n    bool _4256 = (_4247 != 1.0) || (_4251 != 1.5);\n    bool _4265;\n    if (!_4256)\n    {\n        _4265 = any(notEqual(s.specular_color, vec3(1.0)));\n    }\n    else\n    {\n        _4265 = _4256;\n    }\n    if (_4265)\n    {\n        float _4273 = (_4251 - 1.0) / (_4251 + 1.0);\n        f0 = mix(min(vec3(_4273 * _4273) * max(s.specular_color, vec3(0.0)), vec3(1.0)) * _4247, s.albedo, vec3(metallic));\n        _6717 = mix(_4247, 1.0, metallic);\n        _6716 = true;\n    }\n    float _4300 = clamp(s.clearcoat, 0.0, 1.0);\n    if (_4300 > 0.0)\n    {\n        float _4308 = clamp(s.clearcoat_roughness, 0.0500000007450580596923828125, 1.0);\n        _6720 = _4300;\n        _6721 = _4308;\n        float _4315 = _4308 * _4308;\n        _6722 = _4315;\n        _6723 = _4315 * _4315;\n        float _4327 = max(dot(i.world_normal, v), 9.9999997473787516355514526367188e-05);\n        _6725 = _4327;\n        _6718 = 1.0 - (_4300 * (0.039999999105930328369140625 + (0.959999978542327880859375 * pow(clamp(1.0 - _4327, 0.0, 1.0), 5.0))));\n        _6716 = true;\n    }\n    vec3 _4346 = max(s.sheen_color, vec3(0.0));\n    float _4355 = max(_4346.x, max(_4346.y, _4346.z));\n    if (_4355 > 0.0)\n    {\n        float _4363 = clamp(s.sheen_roughness, 0.100000001490116119384765625, 1.0);\n        _6726 = true;\n        _6727 = _4346;\n        _6728 = _4363;\n        _6729 = _4363 * _4363;\n        float param = max(dot(n, v), 9.9999997473787516355514526367188e-05);\n        float param_1 = _4363;\n        float _4380 = fa_sheen_albedo(param, param_1);\n        _6731 = _4380;\n        _6730 = 1.0 - min(_4355 * _4380, 1.0);\n        _6716 = true;\n    }\n    _6719 = _6718 * _6730;\n    float _4399 = clamp(s.anisotropy, -1.0, 1.0);\n    if (_4399 != 0.0)\n    {\n        vec3 _4414 = i.world_tangent.xyz - (n * dot(n, i.world_tangent.xyz));\n        vec3 t = _4414;\n        if (dot(_4414, _4414) < 9.9999999392252902907785028219223e-09)\n        {\n            bvec3 _4426 = bvec3(abs(n.y) < 0.9900000095367431640625);\n            t = cross(vec3(_4426.x ? vec3(0.0, 1.0, 0.0).x : vec3(1.0, 0.0, 0.0).x, _4426.y ? vec3(0.0, 1.0, 0.0).y : vec3(1.0, 0.0, 0.0).y, _4426.z ? vec3(0.0, 1.0, 0.0).z : vec3(1.0, 0.0, 0.0).z), n);\n        }\n        vec3 _4430 = t;\n        vec3 _4431 = normalize(_4430);\n        t = _4431;\n        vec3 _4456 = normalize((_4431 * cos(s.anisotropy_rotation)) + ((cross(n, _4431) * ((i.world_tangent.w < 0.0) ? (-1.0) : 1.0)) * sin(s.anisotropy_rotation)));\n        _6733 = _4456;\n        _6734 = cross(n, _4456);\n        float _4466 = roughness * roughness;\n        float _4472 = mix(_4466, 1.0, _4399 * _4399);\n        bool _4474 = _4399 > 0.0;\n        _6735 = _4474 ? _4472 : _4466;\n        _6736 = _4474 ? _4466 : _4472;\n        _6732 = _4399;\n        _6716 = true;\n    }\n    return FaLayers(_6716, _6717, _6718, _6719, _6720, _6721, _6722, _6723, i.world_normal, _6725, _6726, _6727, _6728, _6729, _6730, _6731, _6732, _6733, _6734, _6735, _6736);\n}\n\nvec2 fa_env_brdf(float rough, float ndv)\n{\n    vec4 _4030 = (vec4(-1.0, -0.0274999998509883880615234375, -0.572000026702880859375, 0.02199999988079071044921875) * rough) + vec4(1.0, 0.0425000004470348358154296875, 1.03999996185302734375, -0.039999999105930328369140625);\n    float _4033 = _4030.x;\n    return (vec2(-1.03999996185302734375, 1.03999996185302734375) * ((min(_4033 * _4033, exp2((-9.27999973297119140625) * ndv)) * _4033) + _4030.y)) + _4030.zw;\n}\n\nvec3 fa_probe_level(vec2 origin, float res, int lv, vec2 e)\n{\n    float _3341;\n    if (lv == 0)\n    {\n        _3341 = 0.0;\n    }\n    else\n    {\n        _3341 = res + 2.0;\n    }\n    float _3351;\n    if (lv == 0)\n    {\n        _3351 = 0.0;\n    }\n    else\n    {\n        _3351 = (res - (res / float(1 << (lv - 1)))) + (2.0 * float(lv - 1));\n    }\n    return textureLod(fa_probe_atlas_fa_env_smp, (((origin + vec2(_3341, _3351)) + vec2(1.0)) + (((e * 0.5) + vec2(0.5)) * (res / float(1 << lv)))) / fa_atlas_size(), 0.0).xyz;\n}\n\nvec3 fa_probe_radiance(vec2 origin, float res, vec3 d, float rough)\n{\n    float _3396;\n    if (res > 64.5)\n    {\n        _3396 = 5.0;\n    }\n    else\n    {\n        _3396 = (res > 32.5) ? 4.0 : 3.0;\n    }\n    float _3411 = clamp(rough, 0.0, 1.0) * (_3396 - 1.0);\n    int _3418 = int(min(floor(_3411), _3396 - 2.0));\n    float _3423 = _3411 - float(_3418);\n    vec3 param = d;\n    vec2 _3427 = fa_oct_encode(param);\n    vec2 param_1 = origin;\n    float param_2 = res;\n    int param_3 = _3418;\n    vec2 param_4 = _3427;\n    vec3 _3437 = fa_probe_level(param_1, param_2, param_3, param_4);\n    if (_3423 < 0.00200000009499490261077880859375)\n    {\n        return _3437;\n    }\n    vec2 param_5 = origin;\n    float param_6 = res;\n    int param_7 = _3418 + 1;\n    vec2 param_8 = _3427;\n    return mix(_3437, fa_probe_level(param_5, param_6, param_7, param_8), vec3(_3423));\n}\n\nvec3 fa_probe_box_dir(vec3 d, vec4 posw, vec4 bx, vec4 by, vec4 bz)\n{\n    if (posw.w < 0.5)\n    {\n        return d;\n    }\n    float _3507 = dot(bx.xyz, fa_world_pos) + bx.w;\n    float _3514 = dot(by.xyz, fa_world_pos) + by.w;\n    float _3521 = dot(bz.xyz, fa_world_pos) + bz.w;\n    float _3527 = dot(bx.xyz, d);\n    float _3531 = dot(by.xyz, d);\n    float _3535 = dot(bz.xyz, d);\n    float _3541;\n    if (_3527 > 9.9999999747524270787835121154785e-07)\n    {\n        _3541 = (1.0 - _3507) / _3527;\n    }\n    else\n    {\n        float _3555;\n        if (_3527 < (-9.9999999747524270787835121154785e-07))\n        {\n            _3555 = ((-1.0) - _3507) / _3527;\n        }\n        else\n        {\n            _3555 = 1000000015047466219876688855040.0;\n        }\n        _3541 = _3555;\n    }\n    float tx = _3541;\n    float _3572;\n    if (_3531 > 9.9999999747524270787835121154785e-07)\n    {\n        _3572 = (1.0 - _3514) / _3531;\n    }\n    else\n    {\n        float _3585;\n        if (_3531 < (-9.9999999747524270787835121154785e-07))\n        {\n            _3585 = ((-1.0) - _3514) / _3531;\n        }\n        else\n        {\n            _3585 = 1000000015047466219876688855040.0;\n        }\n        _3572 = _3585;\n    }\n    float ty = _3572;\n    float _3601;\n    if (_3535 > 9.9999999747524270787835121154785e-07)\n    {\n        _3601 = (1.0 - _3521) / _3535;\n    }\n    else\n    {\n        float _3614;\n        if (_3535 < (-9.9999999747524270787835121154785e-07))\n        {\n            _3614 = ((-1.0) - _3521) / _3535;\n        }\n        else\n        {\n            _3614 = 1000000015047466219876688855040.0;\n        }\n        _3601 = _3614;\n    }\n    float _3626 = tx;\n    float _3629 = (_3626 > 0.0) ? _3626 : 1000000015047466219876688855040.0;\n    tx = _3629;\n    float _3630 = ty;\n    float _3633 = (_3630 > 0.0) ? _3630 : 1000000015047466219876688855040.0;\n    ty = _3633;\n    float _3643 = min(_3629, min(_3633, (_3601 > 0.0) ? _3601 : 1000000015047466219876688855040.0));\n    if (_3643 > 100000001504746621987668885504.0)\n    {\n        return d;\n    }\n    vec3 _3659 = (fa_world_pos + (d * _3643)) - posw.xyz;\n    vec3 _3664;\n    if (dot(_3659, _3659) > 1.0000000133514319600180897396058e-10)\n    {\n        _3664 = normalize(_3659);\n    }\n    else\n    {\n        _3664 = d;\n    }\n    return _3664;\n}\n\nvec3 fa_probe_environment(vec4 tile, vec4 posw, vec4 bx, vec4 by, vec4 bz, inout vec3 d, float rough)\n{\n    vec3 param = d;\n    vec4 param_1 = posw;\n    vec4 param_2 = bx;\n    vec4 param_3 = by;\n    vec4 param_4 = bz;\n    d = fa_probe_box_dir(param, param_1, param_2, param_3, param_4);\n    vec2 param_5 = tile.xy;\n    float param_6 = tile.z;\n    vec3 param_7 = d;\n    float param_8 = rough;\n    return fa_probe_radiance(param_5, param_6, param_7, param_8);\n}\n\nvec3 fa_environment(vec3 d, float rough)\n{\n    float _3710 = (1.0 - fa_mesh_fs_params[42].w) - fa_mesh_fs_params[47].w;\n    vec3 outc = vec3(0.0);\n    if (_3710 > 0.0005000000237487256526947021484375)\n    {\n        vec3 base;\n        if (fa_mesh_fs_params[11].w > 0.5)\n        {\n            vec2 param = fa_mesh_fs_params[41].zw;\n            float param_1 = 128.0;\n            vec3 param_2 = d;\n            float param_3 = rough;\n            base = fa_probe_radiance(param, param_1, param_2, param_3);\n        }\n        else\n        {\n            float _3739 = rough * rough;\n            float _3770 = 0.60000002384185791015625 * _3739;\n            base = mix(mix(fa_mesh_fs_params[12].xyz * 0.550000011920928955078125, mix(fa_mesh_fs_params[12].xyz, fa_mesh_fs_params[11].xyz, vec3(pow(clamp(d.y * (1.0 - (0.699999988079071044921875 * _3739)), 0.0, 1.0), 0.550000011920928955078125))), vec3(smoothstep((-0.0500000007450580596923828125) - _3770, 0.0500000007450580596923828125 + _3770, d.y))), ((fa_mesh_fs_params[11].xyz + fa_mesh_fs_params[12].xyz) * 0.5) * 0.800000011920928955078125, vec3(_3739 * 0.60000002384185791015625));\n        }\n        outc = base * _3710;\n    }\n    if (fa_mesh_fs_params[42].w > 0.0)\n    {\n        vec4 param_4 = fa_mesh_fs_params[42];\n        vec4 param_5 = fa_mesh_fs_params[43];\n        vec4 param_6 = fa_mesh_fs_params[44];\n        vec4 param_7 = fa_mesh_fs_params[45];\n        vec4 param_8 = fa_mesh_fs_params[46];\n        vec3 param_9 = d;\n        float param_10 = rough;\n        vec3 _3829 = fa_probe_environment(param_4, param_5, param_6, param_7, param_8, param_9, param_10);\n        outc += (_3829 * fa_mesh_fs_params[42].w);\n    }\n    if (fa_mesh_fs_params[47].w > 0.0)\n    {\n        vec4 param_11 = fa_mesh_fs_params[47];\n        vec4 param_12 = fa_mesh_fs_params[48];\n        vec4 param_13 = fa_mesh_fs_params[49];\n        vec4 param_14 = fa_mesh_fs_params[50];\n        vec4 param_15 = fa_mesh_fs_params[51];\n        vec3 param_16 = d;\n        float param_17 = rough;\n        vec3 _3861 = fa_probe_environment(param_11, param_12, param_13, param_14, param_15, param_16, param_17);\n        outc += (_3861 * fa_mesh_fs_params[47].w);\n    }\n    return outc;\n}\n\nvec3 fa_layers_ibl(FaLayers L, vec3 n, vec3 v, vec3 f0, float roughness)\n{\n    vec3 rn = n;\n    if (L.aniso != 0.0)\n    {\n        vec3 _4507;\n        if (L.aniso >= 0.0)\n        {\n            _4507 = L.b;\n        }\n        else\n        {\n            _4507 = L.t;\n        }\n        rn = normalize(mix(n, cross(cross(_4507, v), _4507), vec3(abs(L.aniso))));\n    }\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05);\n    vec2 _4540 = fa_env_brdf(param, param_1);\n    vec3 param_2 = reflect(-v, rn);\n    float param_3 = roughness;\n    vec3 result = (fa_environment(param_2, param_3) * ((f0 * _4540.x) + (vec3(L.f90) * _4540.y))) * L.base_scale;\n    if (L.sheen_on)\n    {\n        vec3 param_4 = n;\n        float param_5 = L.sheen_rough;\n        result += ((L.sheen * (L.sheen_e * L.keep)) * fa_environment(param_4, param_5));\n    }\n    if (L.coat > 0.0)\n    {\n        float param_6 = L.coat_rough;\n        float param_7 = L.coat_ndv;\n        vec2 _4595 = fa_env_brdf(param_6, param_7);\n        vec3 param_8 = reflect(-v, L.nc);\n        float param_9 = L.coat_rough;\n        result += (fa_environment(param_8, param_9) * (L.coat * ((0.039999999105930328369140625 * _4595.x) + _4595.y)));\n    }\n    return result;\n}\n\nvec3 fa_sky_reflection(vec3 n, vec3 v, vec3 f0, float roughness)\n{\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05);\n    vec2 _4072 = fa_env_brdf(param, param_1);\n    vec3 param_2 = reflect(-v, n);\n    float param_3 = roughness;\n    return fa_environment(param_2, param_3) * ((f0 * _4072.x) + vec3(_4072.y));\n}\n\nvec3 fa_sky_light(SurfaceInput i, Surface s)\n{\n    float _4624 = clamp(s.metallic, 0.0, 1.0);\n    float _4628 = clamp(s.roughness, 0.0500000007450580596923828125, 1.0);\n    vec3 _4635 = mix(vec3(0.039999999105930328369140625), s.albedo, vec3(_4624));\n    vec3 f0 = _4635;\n    vec3 _4639 = normalize(s.normal);\n    SurfaceInput param = i;\n    Surface param_1 = s;\n    vec3 param_2 = _4639;\n    vec3 param_3 = i.view_dir;\n    float param_4 = _4624;\n    float param_5 = _4628;\n    vec3 param_6 = _4635;\n    FaLayers _4656 = fa_layers_setup(param, param_1, param_2, param_3, param_4, param_5, param_6);\n    f0 = param_6;\n    if (_4656.on)\n    {\n        FaLayers param_7 = _4656;\n        vec3 param_8 = _4639;\n        vec3 param_9 = i.view_dir;\n        vec3 param_10 = f0;\n        float param_11 = _4628;\n        return fa_layers_ibl(param_7, param_8, param_9, param_10, param_11) * s.occlusion;\n    }\n    vec3 param_12 = _4639;\n    vec3 param_13 = i.view_dir;\n    vec3 param_14 = f0;\n    float param_15 = _4628;\n    return fa_sky_reflection(param_12, param_13, param_14, param_15) * s.occlusion;\n}\n\nvec3 ambient(SurfaceInput i, Surface s, vec3 ambientColor)\n{\n    SurfaceInput param = i;\n    Surface param_1 = s;\n    return fa_sky_light(param, param_1);\n}\n\nint fa_cluster_index(int slot, int n)\n{\n    int param = (int(fa_mesh_fs_params[19].x) + int(fa_mesh_fs_params[19].w)) + ((slot + n) >> 2);\n    vec4 t = fa_light_texel(param);\n    return int(t[(slot + n) & 3]);\n}\n\nint fa_cl_light(int n)\n{\n    if (n < fa_cl_ndir)\n    {\n        return n;\n    }\n    int param = fa_cl_slot;\n    int param_1 = n - fa_cl_ndir;\n    return fa_cluster_index(param, param_1);\n}\n\nint fa_light_base(int li)\n{\n    return li * ((fa_mesh_fs_params[1].w > 4.5) ? 8 : 4);\n}\n\nbool fa_light_baked(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 3;\n    return fa_light_texel(param_1).w > 0.5;\n}\n\nfloat fa_baked_keep(int li)\n{\n    float _4951;\n    if (fa_lm.z > 0.5)\n    {\n        _4951 = 0.0;\n    }\n    else\n    {\n        _4951 = 1.0 - clamp(fa_mesh_fs_params[32].w, 0.0, 1.0);\n    }\n    bool _4962 = _4951 < 1.0;\n    bool _4968;\n    if (_4962)\n    {\n        int param = li;\n        _4968 = fa_light_baked(param);\n    }\n    else\n    {\n        _4968 = _4962;\n    }\n    return _4968 ? _4951 : 1.0;\n}\n\nfloat fa_light_type(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 1;\n    return fa_light_texel(param_1).w;\n}\n\nvec3 fa_area_point(vec3 c, vec3 axis, vec3 ru, vec3 uu, float hx, float hy, float shape, vec3 p, vec3 r)\n{\n    bool _677 = dot(r, r) > 0.5;\n    if (shape > 1.5)\n    {\n        vec3 _690 = (c - (ru * hx)) - p;\n        vec3 _696 = ru * (2.0 * hx);\n        float _702 = max(dot(_696, _696), 9.9999999392252902907785028219223e-09);\n        float _706 = dot(_690, _696);\n        float t = clamp((-_706) / _702, 0.0, 1.0);\n        if (_677)\n        {\n            float _721 = dot(r, _696);\n            float _727 = _702 - (_721 * _721);\n            if (abs(_727) > (9.9999997473787516355514526367188e-06 * _702))\n            {\n                t = clamp(((dot(r, _690) * _721) - _706) / _727, 0.0, 1.0);\n            }\n        }\n        return (p + _690) + (_696 * t);\n    }\n    vec3 q = p;\n    float _759 = dot(r, axis);\n    bool _767;\n    if (_677)\n    {\n        _767 = abs(_759) > 9.9999997473787516355514526367188e-05;\n    }\n    else\n    {\n        _767 = _677;\n    }\n    if (_767)\n    {\n        float _777 = dot(c - p, axis) / _759;\n        if (_777 > 0.0)\n        {\n            q = p + (r * _777);\n        }\n    }\n    vec3 _790 = q - c;\n    vec2 xy = vec2(dot(_790, ru), dot(_790, uu));\n    if (shape > 0.5)\n    {\n        float _805 = length(xy);\n        if (_805 > hx)\n        {\n            xy *= (hx / _805);\n        }\n    }\n    else\n    {\n        xy = clamp(xy, vec2(-hx, -hy), vec2(hx, hy));\n    }\n    return (c + (ru * xy.x)) + (uu * xy.y);\n}\n\nvec4 fa_atlas_fetch(vec2 texel)\n{\n    return textureLod(fa_light_atlas_fa_env_smp, texel / vec2(textureSize(fa_light_atlas_fa_env_smp, 0)), 0.0);\n}\n\nvec3 fa_cookie_sample(vec2 tile_origin, vec2 uv)\n{\n    vec2 param = (tile_origin + vec2(1.0)) + (clamp(uv, vec2(0.0), vec2(1.0)) * 254.0);\n    return fa_atlas_fetch(param).xyz;\n}\n\nfloat fa_ies_sample(vec2 tile_origin, vec3 d, vec3 axis, vec3 right, vec3 up)\n{\n    float _597 = dot(d, right);\n    float _601 = dot(d, up);\n    float _612;\n    if (((_597 * _597) + (_601 * _601)) > 1.0000000133514319600180897396058e-10)\n    {\n        _612 = atan(_601, _597) * 0.15915493667125701904296875;\n    }\n    else\n    {\n        _612 = 0.0;\n    }\n    vec2 param = tile_origin + vec2(1.0 + ((_612 - floor(_612)) * 64.0), 1.0 + (acos(clamp(dot(d, axis), -1.0, 1.0)) * 10.18591594696044921875));\n    return fa_atlas_fetch(param).x;\n}\n\nint fa_cube_face(vec3 d)\n{\n    vec3 _447 = abs(d);\n    float _449 = _447.x;\n    float _451 = _447.y;\n    bool _452 = _449 >= _451;\n    bool _460;\n    if (_452)\n    {\n        _460 = _449 >= _447.z;\n    }\n    else\n    {\n        _460 = _452;\n    }\n    int _461;\n    if (_460)\n    {\n        _461 = (d.x > 0.0) ? 0 : 1;\n    }\n    else\n    {\n        int _476;\n        if (_451 >= _447.z)\n        {\n            _476 = (d.y > 0.0) ? 2 : 3;\n        }\n        else\n        {\n            _476 = (d.z > 0.0) ? 4 : 5;\n        }\n        _461 = _476;\n    }\n    return _461;\n}\n\nvoid fa_cube_face_basis(int f, out vec3 fwd, out vec3 up)\n{\n    if (f == 0)\n    {\n        fwd = vec3(1.0, 0.0, 0.0);\n        up = vec3(0.0, 1.0, 0.0);\n    }\n    else\n    {\n        if (f == 1)\n        {\n            fwd = vec3(-1.0, 0.0, 0.0);\n            up = vec3(0.0, 1.0, 0.0);\n        }\n        else\n        {\n            if (f == 2)\n            {\n                fwd = vec3(0.0, 1.0, 0.0);\n                up = vec3(0.0, 0.0, 1.0);\n            }\n            else\n            {\n                if (f == 3)\n                {\n                    fwd = vec3(0.0, -1.0, 0.0);\n                    up = vec3(0.0, 0.0, -1.0);\n                }\n                else\n                {\n                    if (f == 4)\n                    {\n                        fwd = vec3(0.0, 0.0, 1.0);\n                        up = vec3(0.0, 1.0, 0.0);\n                    }\n                    else\n                    {\n                        fwd = vec3(0.0, 0.0, -1.0);\n                        up = vec3(0.0, 1.0, 0.0);\n                    }\n                }\n            }\n        }\n    }\n}\n\nLightSample fa_light_sample_n(int li, vec3 world_pos, vec3 n)\n{\n    int param = li;\n    int _843 = fa_light_base(param);\n    bool _847 = fa_mesh_fs_params[1].w > 4.5;\n    int param_1 = _843;\n    vec4 _851 = fa_light_texel(param_1);\n    int param_2 = _843 + 1;\n    vec4 _856 = fa_light_texel(param_2);\n    float _859 = _856.w;\n    float atten = 1.0;\n    float dist = 0.0;\n    fa_light_tint = vec3(1.0);\n    bool _871 = _847 && (_859 > 2.5);\n    fa_light_is_area = _871;\n    bool _873 = _859 < 0.5;\n    vec3 l;\n    if (_873)\n    {\n        l = normalize(_851.xyz);\n        if (_847)\n        {\n            int param_3 = _843 + 6;\n            vec4 _887 = fa_light_texel(param_3);\n            if (_887.z > 0.5)\n            {\n                int param_4 = _843 + 4;\n                vec4 _897 = fa_light_texel(param_4);\n                int param_5 = _843 + 5;\n                vec4 _902 = fa_light_texel(param_5);\n                vec2 param_6 = _887.xy;\n                vec2 param_7 = fract(vec2(dot(world_pos, _897.xyz) * _897.w, (-dot(world_pos, _902.xyz)) * _902.w) + vec2(0.5));\n                fa_light_tint = fa_cookie_sample(param_6, param_7);\n            }\n        }\n    }\n    else\n    {\n        vec3 _932 = _851.xyz;\n        vec3 _934 = _932 - world_pos;\n        vec3 to_light = _934;\n        float _937 = length(_934);\n        float reach = _937;\n        bool front = true;\n        if (_871)\n        {\n            int param_8 = _843 + 7;\n            reach = max(_937 - fa_light_texel(param_8).w, 0.0);\n            int param_9 = _843 + 4;\n            vec4 _961 = fa_light_texel(param_9);\n            int param_10 = _843 + 5;\n            vec4 _966 = fa_light_texel(param_10);\n            int param_11 = _843 + 6;\n            vec4 _971 = fa_light_texel(param_11);\n            float _972 = _971.w;\n            int param_12 = _843 + 2;\n            vec3 _979 = normalize(fa_light_texel(param_12).xyz);\n            bool _981 = _972 > 1.5;\n            bool _989;\n            if (!_981)\n            {\n                _989 = dot(_979, to_light) < 0.0;\n            }\n            else\n            {\n                _989 = _981;\n            }\n            front = _989;\n            vec3 r = vec3(0.0);\n            vec3 _998 = fa_mesh_fs_params[0].xyz - world_pos;\n            bool _1002 = dot(n, n) > 0.5;\n            bool _1010;\n            if (_1002)\n            {\n                _1010 = dot(_998, _998) > 9.9999999600419720025001879548654e-13;\n            }\n            else\n            {\n                _1010 = _1002;\n            }\n            if (_1010)\n            {\n                r = reflect(-normalize(_998), normalize(n));\n            }\n            vec3 param_13 = _932;\n            vec3 param_14 = _979;\n            vec3 param_15 = _961.xyz;\n            vec3 param_16 = _966.xyz;\n            float param_17 = _961.w;\n            float param_18 = _966.w;\n            float param_19 = _972;\n            vec3 param_20 = world_pos;\n            vec3 param_21 = r;\n            to_light = fa_area_point(param_13, param_14, param_15, param_16, param_17, param_18, param_19, param_20, param_21) - world_pos;\n        }\n        float _1046 = length(to_light);\n        dist = _1046;\n        l = to_light / vec3(max(_1046, 9.9999997473787516355514526367188e-05));\n        float _1060 = reach / max(_851.w, 0.001000000047497451305389404296875);\n        float _1066 = clamp(1.0 - (_1060 * _1060), 0.0, 1.0);\n        float _1068;\n        if (front)\n        {\n            _1068 = _1066 * _1066;\n        }\n        else\n        {\n            _1068 = 0.0;\n        }\n        atten = _1068;\n        bool _1079 = _859 < 2.5;\n        if ((_859 > 1.5) && _1079)\n        {\n            int param_22 = _843 + 2;\n            vec4 _1087 = fa_light_texel(param_22);\n            float _1097 = _1087.w;\n            int param_23 = _843 + 3;\n            vec4 _1102 = fa_light_texel(param_23);\n            float _1103 = _1102.x;\n            float cos_inner = _1103;\n            if (_1103 > 1.5)\n            {\n                cos_inner = mix(_1097, 1.0, 0.25);\n            }\n            atten *= smoothstep(_1097, cos_inner, dot(-l, normalize(_1087.xyz)));\n        }\n        if (_847 && (_859 < 1.5))\n        {\n            int param_24 = _843 + 6;\n            vec4 _1127 = fa_light_texel(param_24);\n            if (_1127.z > 0.5)\n            {\n                vec3 _1135 = -to_light;\n                int param_25 = _843 + 4;\n                int param_26 = _843 + 5;\n                vec3 _1149 = fa_light_texel(param_25).xyz;\n                vec3 _1153 = fa_light_texel(param_26).xyz;\n                vec3 _1162 = vec3(dot(_1135, _1149), dot(_1135, _1153), dot(_1135, cross(_1149, _1153)));\n                vec3 param_27 = _1162;\n                int _1166 = fa_cube_face(param_27);\n                int param_28 = _1166;\n                vec3 param_29;\n                vec3 param_30;\n                fa_cube_face_basis(param_28, param_29, param_30);\n                vec2 _1193 = vec2(dot(_1162, cross(param_29, param_30)), dot(_1162, param_30)) / vec2(max(dot(_1162, param_29), 9.9999997473787516355514526367188e-05));\n                int _1197 = _1166 / 3;\n                vec2 param_31 = _1127.xy + (vec2(float(_1166 - (_1197 * 3)), float(_1197)) * 256.0);\n                vec2 param_32 = vec2(0.5 + (0.5 * _1193.x), 0.5 - (0.5 * _1193.y));\n                fa_light_tint = fa_cookie_sample(param_31, param_32);\n            }\n            int param_33 = _843 + 7;\n            vec4 _1227 = fa_light_texel(param_33);\n            if (_1227.z > 0.5)\n            {\n                int param_34 = _843 + 2;\n                int param_35 = _843 + 4;\n                int param_36 = _843 + 5;\n                vec2 param_37 = _1227.xy;\n                vec3 param_38 = -l;\n                vec3 param_39 = normalize(fa_light_texel(param_34).xyz);\n                vec3 param_40 = fa_light_texel(param_35).xyz;\n                vec3 param_41 = fa_light_texel(param_36).xyz;\n                atten *= fa_ies_sample(param_37, param_38, param_39, param_40, param_41);\n            }\n        }\n        else\n        {\n            if (_847 && _1079)\n            {\n                int param_42 = _843 + 6;\n                vec4 _1274 = fa_light_texel(param_42);\n                int param_43 = _843 + 7;\n                vec4 _1279 = fa_light_texel(param_43);\n                bool _1282 = _1274.z > 0.5;\n                bool _1289;\n                if (!_1282)\n                {\n                    _1289 = _1279.z > 0.5;\n                }\n                else\n                {\n                    _1289 = _1282;\n                }\n                if (_1289)\n                {\n                    int param_44 = _843 + 2;\n                    vec4 _1296 = fa_light_texel(param_44);\n                    vec3 _1300 = normalize(_1296.xyz);\n                    int param_45 = _843 + 4;\n                    vec4 _1305 = fa_light_texel(param_45);\n                    int param_46 = _843 + 5;\n                    vec4 _1310 = fa_light_texel(param_46);\n                    if (_1282)\n                    {\n                        vec3 _1318 = -to_light;\n                        float _1325 = _1296.w;\n                        float _1341 = 0.5 / max(dot(_1318, _1300) * (sqrt(max(1.0 - (_1325 * _1325), 0.0)) / max(_1325, 0.001000000047497451305389404296875)), 9.9999997473787516355514526367188e-05);\n                        vec2 param_47 = _1274.xy;\n                        vec2 param_48 = vec2(0.5 + (dot(_1318, _1305.xyz) * _1341), 0.5 - (dot(_1318, _1310.xyz) * _1341));\n                        fa_light_tint = fa_cookie_sample(param_47, param_48);\n                    }\n                    if (_1279.z > 0.5)\n                    {\n                        vec2 param_49 = _1279.xy;\n                        vec3 param_50 = -l;\n                        vec3 param_51 = _1300;\n                        vec3 param_52 = _1305.xyz;\n                        vec3 param_53 = _1310.xyz;\n                        atten *= fa_ies_sample(param_49, param_50, param_51, param_52, param_53);\n                    }\n                }\n            }\n        }\n    }\n    vec3 _6704 = _856.xyz * atten;\n    if (_847)\n    {\n        _6704 *= fa_light_tint;\n    }\n    int _1409;\n    if (_873)\n    {\n        _1409 = 0;\n    }\n    else\n    {\n        _1409 = ((_859 > 1.5) && (_859 < 2.5)) ? 2 : 1;\n    }\n    return LightSample(l, _6704, atten, 1.0, dist, _1409);\n}\n\nfloat fa_shadow_depth(inout vec2 uv, vec4 rect)\n{\n    uv = clamp(uv, rect.xy, rect.zw);\n    return textureLod(fa_shadow_tex_fa_shadow_smp, uv, 0.0).x;\n}\n\nfloat fa_shadow_fetch(vec2 uv, vec4 rect, vec3 conv)\n{\n    vec2 param = uv;\n    vec4 param_1 = rect;\n    float _2203 = fa_shadow_depth(param, param_1);\n    float _2207;\n    if (conv.x < 0.5)\n    {\n        _2207 = _2203;\n    }\n    else\n    {\n        _2207 = (conv.y * conv.z) / (conv.z - (_2203 * (conv.z - conv.y)));\n    }\n    return _2207;\n}\n\nfloat fa_shadow_noise()\n{\n    return fract(52.98291778564453125 * fract(dot(gl_FragCoord.xy, vec2(0.067110560834407806396484375, 0.005837149918079376220703125))));\n}\n\nvec2 fa_shadow_vogel(int k, int n, float phi)\n{\n    float _2134 = (float(k) * 2.3999631404876708984375) + phi;\n    return vec2(cos(_2134), sin(_2134)) * sqrt((float(k) + 0.5) / float(n));\n}\n\nfloat fa_shadow_filter(vec2 uv, vec4 rect, float zr, float texel_m, float unit, float reach, float plane, vec3 conv, int mode, float k)\n{\n    if (mode == 1)\n    {\n        vec2 param = uv;\n        vec4 param_1 = rect;\n        vec3 param_2 = conv;\n        return float(zr <= fa_shadow_fetch(param, param_1, param_2));\n    }\n    float _2253 = fa_shadow_noise() * 6.283185482025146484375;\n    float radius = 1.5;\n    if (mode == 2)\n    {\n        float _2262;\n        if (k < 0.0)\n        {\n            _2262 = (-k) / max(zr, 0.100000001490116119384765625);\n        }\n        else\n        {\n            _2262 = k;\n        }\n        float _2282 = clamp((_2262 * reach) / texel_m, 3.0, 12.0);\n        float sum = 0.0;\n        float cnt = 0.0;\n        for (int i = 0; i < 16; i++)\n        {\n            int param_3 = i;\n            int param_4 = 16;\n            float param_5 = _2253;\n            vec2 _2301 = fa_shadow_vogel(param_3, param_4, param_5) * _2282;\n            vec2 param_6 = uv + (_2301 * fa_shadows[26].zw);\n            vec4 param_7 = rect;\n            vec3 param_8 = conv;\n            float _2313 = fa_shadow_fetch(param_6, param_7, param_8);\n            if (_2313 < (zr - (length(_2301) * plane)))\n            {\n                sum += _2313;\n                cnt += 1.0;\n            }\n        }\n        if (cnt < 0.5)\n        {\n            return 1.0;\n        }\n        float _2339 = sum / cnt;\n        float _2349;\n        if (k < 0.0)\n        {\n            _2349 = (-k) / max(_2339, 0.0500000007450580596923828125);\n        }\n        else\n        {\n            _2349 = k;\n        }\n        radius = clamp(((max(zr - _2339, 0.0) * unit) * _2349) / texel_m, 1.5, 16.0);\n    }\n    float lit = 0.0;\n    int _2371 = (mode == 2) ? 24 : 16;\n    for (int i_1 = 0; i_1 < _2371; i_1++)\n    {\n        int param_9 = i_1;\n        int param_10 = _2371;\n        float param_11 = _2253;\n        vec2 _2390 = fa_shadow_vogel(param_9, param_10, param_11) * radius;\n        vec2 param_12 = uv + (_2390 * fa_shadows[26].zw);\n        vec4 param_13 = rect;\n        vec3 param_14 = conv;\n        lit += float((zr - (length(_2390) * plane)) <= fa_shadow_fetch(param_12, param_13, param_14));\n    }\n    return lit / float(_2371);\n}\n\nfloat fa_shadow_local(int li, vec3 lpos, vec3 world, vec3 n, vec3 l)\n{\n    bool _2590 = fa_mesh_fs_params[5].z < 0.5;\n    bool _2597;\n    if (!_2590)\n    {\n        _2597 = fa_shadows[29].x < 0.5;\n    }\n    else\n    {\n        _2597 = _2590;\n    }\n    if (_2597)\n    {\n        return 1.0;\n    }\n    int param = (int(fa_shadows[29].x + 0.5) - 1) + li;\n    vec4 _2610 = fa_light_texel(param);\n    float _2611 = _2610.x;\n    if (_2611 < 0.0)\n    {\n        return 1.0;\n    }\n    int _2620 = int(_2611 + 0.5);\n    int param_1 = _2620;\n    vec4 _2624 = fa_light_texel(param_1);\n    int param_2 = _2620 + 1;\n    vec4 _2629 = fa_light_texel(param_2);\n    float fade = 1.0;\n    float _2632 = _2624.y;\n    if (_2632 > 0.0)\n    {\n        float _2649 = 1.0 - smoothstep(0.75 * _2632, _2632, length(world - fa_shadows[27].xyz));\n        fade = _2649;\n        if (_2649 <= 0.0)\n        {\n            return 1.0;\n        }\n    }\n    int face = 0;\n    if (_2624.x > 1.5)\n    {\n        vec3 param_3 = world - lpos;\n        face = fa_cube_face(param_3);\n    }\n    int _2673 = (_2620 + 2) + (face * 6);\n    int param_4 = _2673;\n    int param_5 = _2673 + 1;\n    int param_6 = _2673 + 3;\n    vec4 _2687 = fa_light_texel(param_6);\n    int param_7 = _2673 + 4;\n    vec4 _2692 = fa_light_texel(param_7);\n    int param_8 = _2673 + 5;\n    vec4 _2697 = fa_light_texel(param_8);\n    float _2709 = _2697.x * max(dot(_2687, vec4(world, 1.0)), 0.001000000047497451305389404296875);\n    float _2714 = clamp(dot(n, l), 0.0, 1.0);\n    float _2737 = clamp(dot(n, _2687.xyz), -1.0, 1.0);\n    float _2756 = min(sqrt(1.0 - (_2737 * _2737)) / max(abs(dot(n, world - lpos)) / max(dot(_2687, vec4(world, 1.0)), 0.001000000047497451305389404296875), 0.20000000298023223876953125), 4.0);\n    float _2759 = _2629.y;\n    float _2761;\n    if (_2759 > 0.0)\n    {\n        _2761 = _2759;\n    }\n    else\n    {\n        _2761 = 1.5 * _2709;\n    }\n    vec4 _2781 = vec4(world + (n * (_2761 * sqrt(1.0 - (_2714 * _2714)))), 1.0);\n    float _2785 = dot(_2687, _2781);\n    float _2788 = _2697.y;\n    if (_2785 < _2788)\n    {\n        return 1.0;\n    }\n    vec2 _2803 = vec2(dot(fa_light_texel(param_4), _2781), dot(fa_light_texel(param_5), _2781)) / vec2(_2785);\n    float _2805 = _2803.x;\n    bool _2808 = _2805 < _2692.x;\n    bool _2817;\n    if (!_2808)\n    {\n        _2817 = _2805 > _2692.z;\n    }\n    else\n    {\n        _2817 = _2808;\n    }\n    bool _2826;\n    if (!_2817)\n    {\n        _2826 = _2803.y < _2692.y;\n    }\n    else\n    {\n        _2826 = _2817;\n    }\n    bool _2835;\n    if (!_2826)\n    {\n        _2835 = _2803.y > _2692.w;\n    }\n    else\n    {\n        _2835 = _2826;\n    }\n    if (_2835)\n    {\n        return 1.0;\n    }\n    float _2841 = _2629.x;\n    float _2843;\n    if (_2841 > 0.0)\n    {\n        _2843 = _2841;\n    }\n    else\n    {\n        _2843 = 1.5 * _2709;\n    }\n    vec2 param_9 = _2803;\n    vec4 param_10 = _2692;\n    float param_11 = _2785 - (_2843 * (1.0 + (0.5 * _2756)));\n    float param_12 = _2709;\n    float param_13 = 1.0;\n    float param_14 = _2697.z * 0.25;\n    float param_15 = (_2709 * min(_2756, 3.0)) * 0.5;\n    vec3 param_16 = vec3(1.0, _2788, _2697.z);\n    int param_17 = int(_2624.z + 0.5);\n    float param_18 = _2624.w;\n    return mix(1.0, fa_shadow_filter(param_9, param_10, param_11, param_12, param_13, param_14, param_15, param_16, param_17, param_18), fade);\n}\n\nfloat fa_shadow_split_at(int i)\n{\n    float _2146;\n    if (i == 0)\n    {\n        _2146 = fa_shadows[24].x;\n    }\n    else\n    {\n        float _2162;\n        if (i == 1)\n        {\n            _2162 = fa_shadows[24].y;\n        }\n        else\n        {\n            float _2170;\n            if (i == 2)\n            {\n                _2170 = fa_shadows[24].z;\n            }\n            else\n            {\n                _2170 = fa_shadows[24].w;\n            }\n            _2162 = _2170;\n        }\n        _2146 = _2162;\n    }\n    return _2146;\n}\n\nfloat fa_shadow_cascade(int ci, vec3 world, vec3 n, vec3 l)\n{\n    float _2432 = max(fa_shadows[ci * 1 + 20].y, 0.001000000047497451305389404296875);\n    float _2437 = clamp(dot(n, l), 0.0, 1.0);\n    float _2443 = sqrt(1.0 - (_2437 * _2437));\n    float _2450 = min(_2443 / max(_2437, 0.20000000298023223876953125), 4.0);\n    float _2455;\n    if (fa_shadows[26].y > 0.0)\n    {\n        _2455 = fa_shadows[26].y;\n    }\n    else\n    {\n        _2455 = 1.5 * fa_shadows[ci * 1 + 20].x;\n    }\n    vec4 _2480 = mat4(fa_shadows[ci * 4 + 0], fa_shadows[ci * 4 + 1], fa_shadows[ci * 4 + 2], fa_shadows[ci * 4 + 3]) * vec4(world + (n * (_2455 * _2443)), 1.0);\n    float _2487 = _2480.x;\n    bool _2490 = _2487 < fa_shadows[ci * 1 + 16].x;\n    bool _2499;\n    if (!_2490)\n    {\n        _2499 = _2487 > fa_shadows[ci * 1 + 16].z;\n    }\n    else\n    {\n        _2499 = _2490;\n    }\n    bool _2508;\n    if (!_2499)\n    {\n        _2508 = _2480.y < fa_shadows[ci * 1 + 16].y;\n    }\n    else\n    {\n        _2508 = _2499;\n    }\n    bool _2517;\n    if (!_2508)\n    {\n        _2517 = _2480.y > fa_shadows[ci * 1 + 16].w;\n    }\n    else\n    {\n        _2517 = _2508;\n    }\n    bool _2524;\n    if (!_2517)\n    {\n        _2524 = _2480.z > 1.0;\n    }\n    else\n    {\n        _2524 = _2517;\n    }\n    if (_2524)\n    {\n        return -1.0;\n    }\n    float _2532;\n    if (fa_shadows[26].x > 0.0)\n    {\n        _2532 = fa_shadows[26].x;\n    }\n    else\n    {\n        _2532 = 1.5 * fa_shadows[ci * 1 + 20].x;\n    }\n    vec2 param = _2480.xy;\n    vec4 param_1 = fa_shadows[ci * 1 + 16];\n    float param_2 = _2480.z - ((_2532 * (1.0 + (0.5 * _2450))) / _2432);\n    float param_3 = fa_shadows[ci * 1 + 20].x;\n    float param_4 = _2432;\n    float param_5 = _2432 * 0.25;\n    float param_6 = ((fa_shadows[ci * 1 + 20].x * min(_2450, 3.0)) * 0.5) / _2432;\n    vec3 param_7 = vec3(0.0);\n    int param_8 = int(fa_shadows[25].z + 0.5);\n    float param_9 = fa_shadows[25].w;\n    return fa_shadow_filter(param, param_1, param_2, param_3, param_4, param_5, param_6, param_7, param_8, param_9);\n}\n\nfloat fa_shadow_sun(vec3 world, vec3 n, vec3 l)\n{\n    if (fa_mesh_fs_params[5].z < 0.5)\n    {\n        return 1.0;\n    }\n    int _2910 = int(fa_shadows[25].x + 0.5);\n    if (_2910 < 1)\n    {\n        return 1.0;\n    }\n    float _2925 = dot(world - fa_shadows[27].xyz, fa_shadows[28].xyz);\n    int param = _2910 - 1;\n    if (_2925 > fa_shadow_split_at(param))\n    {\n        return 1.0;\n    }\n    int ci = 0;\n    bool _2937 = _2910 > 1;\n    bool _2944;\n    if (_2937)\n    {\n        _2944 = _2925 > fa_shadows[24].x;\n    }\n    else\n    {\n        _2944 = _2937;\n    }\n    if (_2944)\n    {\n        ci = 1;\n    }\n    bool _2948 = _2910 > 2;\n    bool _2955;\n    if (_2948)\n    {\n        _2955 = _2925 > fa_shadows[24].y;\n    }\n    else\n    {\n        _2955 = _2948;\n    }\n    if (_2955)\n    {\n        ci = 2;\n    }\n    bool _2959 = _2910 > 3;\n    bool _2966;\n    if (_2959)\n    {\n        _2966 = _2925 > fa_shadows[24].z;\n    }\n    else\n    {\n        _2966 = _2959;\n    }\n    if (_2966)\n    {\n        ci = 3;\n    }\n    float s = -1.0;\n    for (int k = 0; k < 4; k++)\n    {\n        if (ci >= _2910)\n        {\n            break;\n        }\n        int param_1 = ci;\n        vec3 param_2 = world;\n        vec3 param_3 = n;\n        vec3 param_4 = l;\n        float _2992 = fa_shadow_cascade(param_1, param_2, param_3, param_4);\n        s = _2992;\n        if (_2992 >= 0.0)\n        {\n            break;\n        }\n        ci++;\n    }\n    if (s < 0.0)\n    {\n        return 1.0;\n    }\n    if (fa_shadows[25].y > 0.0)\n    {\n        float _3017;\n        if (ci > 0)\n        {\n            int param_5 = ci - 1;\n            _3017 = fa_shadow_split_at(param_5);\n        }\n        else\n        {\n            _3017 = fa_shadows[28].w;\n        }\n        int param_6 = ci;\n        float _3036 = fa_shadows[25].y * max(fa_shadow_split_at(param_6) - _3017, 9.9999997473787516355514526367188e-05);\n        int param_7 = ci;\n        float _3047 = clamp((_2925 - (fa_shadow_split_at(param_7) - _3036)) / _3036, 0.0, 1.0);\n        if (_3047 > 0.0)\n        {\n            float s2 = 1.0;\n            if ((ci + 1) < _2910)\n            {\n                int param_8 = ci + 1;\n                vec3 param_9 = world;\n                vec3 param_10 = n;\n                vec3 param_11 = l;\n                float _3068 = fa_shadow_cascade(param_8, param_9, param_10, param_11);\n                s2 = _3068;\n                if (_3068 < 0.0)\n                {\n                    s2 = s;\n                }\n            }\n            s = mix(s, s2, _3047);\n        }\n    }\n    return s;\n}\n\nfloat fa_shadow_factor(vec3 n, vec3 l)\n{\n    vec3 param = fa_world_pos;\n    vec3 param_1 = n;\n    vec3 param_2 = l;\n    return fa_shadow_sun(param, param_1, param_2);\n}\n\nfloat fa_contact_shadow(int li, vec3 world, vec3 gn, vec3 l, float dist)\n{\n    bool _4695 = fa_mesh_fs_params[24].x < 0.5;\n    bool _4702;\n    if (!_4695)\n    {\n        _4702 = fa_shadows[29].x < 0.5;\n    }\n    else\n    {\n        _4702 = _4695;\n    }\n    if (_4702)\n    {\n        return 1.0;\n    }\n    int param = (int(fa_shadows[29].x + 0.5) - 1) + li;\n    vec4 _4715 = fa_light_texel(param);\n    float _4716 = _4715.y;\n    float len = _4716;\n    if (_4716 <= 0.0)\n    {\n        return 1.0;\n    }\n    float _4728 = length(world - fa_mesh_fs_params[0].xyz);\n    float _4738 = 1.0 - smoothstep(0.5 * fa_mesh_fs_params[25].x, fa_mesh_fs_params[25].x, _4728);\n    if (_4738 <= 0.0)\n    {\n        return 1.0;\n    }\n    float _4744 = len;\n    float _4747 = min(_4744, 0.89999997615814208984375 * dist);\n    len = _4747;\n    float _4752 = 0.004999999888241291046142578125 + (0.0030000000260770320892333984375 * _4728);\n    float _4757 = _4752 + (0.5 * _4747);\n    vec3 _4763 = world + (gn * _4752);\n    float _4765 = fa_shadow_noise();\n    float occ = 0.0;\n    float _4829;\n    for (int k = 0; k < 12; k++)\n    {\n        float _4780 = (float(k) + _4765) * 0.083333335816860198974609375;\n        vec3 _4788 = _4763 + (l * (_4780 * len));\n        vec4 _4794 = vec4(_4788, 1.0);\n        float _4800 = dot(fa_mesh_fs_params[28], _4794);\n        if (_4800 < 9.9999997473787516355514526367188e-05)\n        {\n            break;\n        }\n        vec2 _4820 = vec2(dot(fa_mesh_fs_params[26], _4794), dot(fa_mesh_fs_params[27], _4794)) / vec2(_4800);\n        float _4824 = _4820.x * 0.5;\n        float _4825 = _4824 + 0.5;\n        if (fa_mesh_fs_params[24].y > 0.5)\n        {\n            _4829 = (_4820.y * 0.5) + 0.5;\n        }\n        else\n        {\n            _4829 = 0.5 - (_4820.y * 0.5);\n        }\n        bool _4845 = _4825 < 0.0;\n        bool _4852;\n        if (!_4845)\n        {\n            _4852 = _4825 >= 1.0;\n        }\n        else\n        {\n            _4852 = _4845;\n        }\n        bool _4859;\n        if (!_4852)\n        {\n            _4859 = _4829 < 0.0;\n        }\n        else\n        {\n            _4859 = _4852;\n        }\n        bool _4866;\n        if (!_4859)\n        {\n            _4866 = _4829 >= 1.0;\n        }\n        else\n        {\n            _4866 = _4859;\n        }\n        if (_4866)\n        {\n            break;\n        }\n        vec4 _4885 = texelFetch(fa_screen_tex_fa_shadow_smp, ivec2(vec2(_4825, _4829) * fa_mesh_fs_params[24].zw), 0);\n        if (_4885.w < 0.5)\n        {\n            continue;\n        }\n        float _4904 = (dot(fa_mesh_fs_params[29].xyz, _4788) + fa_mesh_fs_params[29].w) - _4885.x;\n        if ((_4904 > _4752) && (_4904 < _4757))\n        {\n            occ = max(occ, (1.0 - (_4780 * _4780)) * smoothstep(0.0, 0.0500000007450580596923828125, min(min(_4825, 0.5 - _4824), min(_4829, 1.0 - _4829))));\n        }\n    }\n    return 1.0 - (occ * _4738);\n}\n\nLightSample fa_light_shadowed(int li, vec3 world_pos, vec3 gn)\n{\n    int param = li;\n    float _5007 = fa_baked_keep(param);\n    if (_5007 <= 0.0)\n    {\n        int param_1 = li;\n        return LightSample(vec3(0.0, 1.0, 0.0), vec3(0.0), 0.0, 1.0, 0.0, int(fa_light_type(param_1) + 0.5));\n    }\n    int param_2 = li;\n    vec3 param_3 = world_pos;\n    vec3 param_4 = gn;\n    LightSample _5033 = fa_light_sample_n(param_2, param_3, param_4);\n    vec3 _6837 = _5033.color;\n    float _6838 = _5033.attenuation;\n    float _6839 = _5033.shadow;\n    bool _5036 = _5033.type == 0;\n    if (_5036 && (li == 0))\n    {\n        vec3 param_5 = gn;\n        vec3 param_6 = _5033.direction;\n        float _5047 = fa_shadow_factor(param_5, param_6);\n        _6839 = _5047;\n        _6837 *= _5047;\n    }\n    else\n    {\n        bool _5058 = _5033.type != 0;\n        bool _5064;\n        if (_5058)\n        {\n            _5064 = _6838 > 0.0;\n        }\n        else\n        {\n            _5064 = _5058;\n        }\n        if (_5064)\n        {\n            int param_7 = li;\n            int param_8 = fa_light_base(param_7);\n            int param_9 = li;\n            vec3 param_10 = fa_light_texel(param_8).xyz;\n            vec3 param_11 = world_pos;\n            vec3 param_12 = gn;\n            vec3 param_13 = _5033.direction;\n            float _5083 = fa_shadow_local(param_9, param_10, param_11, param_12, param_13);\n            _6839 = _5083;\n            _6837 *= _5083;\n        }\n    }\n    bool _5093 = fa_mesh_fs_params[24].x > 0.5;\n    bool _5099;\n    if (_5093)\n    {\n        _5099 = _6838 > 0.0;\n    }\n    else\n    {\n        _5099 = _5093;\n    }\n    if (_5099)\n    {\n        float _5106;\n        if (_5036)\n        {\n            _5106 = 1000000000.0;\n        }\n        else\n        {\n            _5106 = _5033._distance;\n        }\n        int param_14 = li;\n        vec3 param_15 = world_pos;\n        vec3 param_16 = gn;\n        vec3 param_17 = _5033.direction;\n        float param_18 = _5106;\n        float _5124 = fa_contact_shadow(param_14, param_15, param_16, param_17, param_18);\n        _6839 *= _5124;\n        _6837 *= _5124;\n    }\n    float _5137 = _6838;\n    float _5138 = _5137 * _5007;\n    _6838 = _5138;\n    vec3 _5142 = _6837;\n    vec3 _5143 = _5142 * _5007;\n    _6837 = _5143;\n    return LightSample(_5033.direction, _5143, _5138, _6839, _5033._distance, _5033.type);\n}\n\nvec3 light(SurfaceInput i, Surface s, LightSample l)\n{\n    return vec3(0.0);\n}\n\nvec3 fa_shadow_debug(vec3 color, vec3 world)\n{\n    if (fa_shadows[27].w < 0.5)\n    {\n        return color;\n    }\n    int _3092 = int(fa_shadows[25].x + 0.5);\n    float _3102 = dot(world - fa_shadows[27].xyz, fa_shadows[28].xyz);\n    vec3 tint = vec3(0.3499999940395355224609375);\n    bool _3107 = _3092 > 0;\n    bool _3116;\n    if (_3107)\n    {\n        int param = _3092 - 1;\n        _3116 = _3102 <= fa_shadow_split_at(param);\n    }\n    else\n    {\n        _3116 = _3107;\n    }\n    if (_3116)\n    {\n        tint = vec3(1.0, 0.1500000059604644775390625, 0.100000001490116119384765625);\n        bool _3122 = _3092 > 1;\n        bool _3129;\n        if (_3122)\n        {\n            _3129 = _3102 > fa_shadows[24].x;\n        }\n        else\n        {\n            _3129 = _3122;\n        }\n        if (_3129)\n        {\n            tint = vec3(0.100000001490116119384765625, 0.89999997615814208984375, 0.20000000298023223876953125);\n        }\n        bool _3135 = _3092 > 2;\n        bool _3142;\n        if (_3135)\n        {\n            _3142 = _3102 > fa_shadows[24].y;\n        }\n        else\n        {\n            _3142 = _3135;\n        }\n        if (_3142)\n        {\n            tint = vec3(0.1500000059604644775390625, 0.300000011920928955078125, 1.0);\n        }\n        bool _3148 = _3092 > 3;\n        bool _3155;\n        if (_3148)\n        {\n            _3155 = _3102 > fa_shadows[24].z;\n        }\n        else\n        {\n            _3155 = _3148;\n        }\n        if (_3155)\n        {\n            tint = vec3(1.0, 0.89999997615814208984375, 0.100000001490116119384765625);\n        }\n    }\n    return mix(color, tint, vec3(0.550000011920928955078125));\n}\n\nvoid main()\n{\n    fa_inst_load();\n    vec3 _6522 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _6522 = -_6522;\n    }\n    vec3 _6146 = normalize(fa_mesh_fs_params[0].xyz - fa_world_pos);\n    vec3 param = fa_world_pos;\n    fa_cluster_begin(param);\n    SurfaceInput param_1 = SurfaceInput(fa_world_pos, _6522, fa_world_tangent, fa_uv, fa_vertex_color, _6146, gl_FrontFacing);\n    Surface _6154 = fa_standard_surface(param_1);\n    vec3 _6561 = _6154.albedo;\n    float _6562 = _6154.alpha;\n    vec3 _6563 = _6154.normal;\n    float _6564 = _6154.metallic;\n    float _6565 = _6154.roughness;\n    float _6566 = _6154.occlusion;\n    vec3 _6567 = _6154.emission;\n    float _6568 = _6154.clearcoat;\n    float _6569 = _6154.clearcoat_roughness;\n    vec3 _6570 = _6154.sheen_color;\n    float _6571 = _6154.sheen_roughness;\n    float _6572 = _6154.anisotropy;\n    float _6573 = _6154.anisotropy_rotation;\n    float _6574 = _6154.specular;\n    float _6575 = _6154.ior;\n    vec3 _6576 = _6154.specular_color;\n    float _6577 = _6154.transmission;\n    float _6578 = _6154.thickness;\n    vec3 _6579 = _6154.attenuation_color;\n    float _6580 = _6154.attenuation_distance;\n    SurfaceInput param_2 = SurfaceInput(fa_world_pos, _6522, fa_world_tangent, fa_uv, fa_vertex_color, _6146, gl_FrontFacing);\n    Surface param_3 = _6154;\n    surface(param_2, param_3);\n    _6561 = param_3.albedo;\n    _6562 = param_3.alpha;\n    _6563 = param_3.normal;\n    _6564 = param_3.metallic;\n    _6565 = param_3.roughness;\n    _6566 = param_3.occlusion;\n    _6567 = param_3.emission;\n    _6568 = param_3.clearcoat;\n    _6569 = param_3.clearcoat_roughness;\n    _6570 = param_3.sheen_color;\n    _6571 = param_3.sheen_roughness;\n    _6572 = param_3.anisotropy;\n    _6573 = param_3.anisotropy_rotation;\n    _6574 = param_3.specular;\n    _6575 = param_3.ior;\n    _6576 = param_3.specular_color;\n    _6577 = param_3.transmission;\n    _6578 = param_3.thickness;\n    _6579 = param_3.attenuation_color;\n    _6580 = param_3.attenuation_distance;\n    vec3 param_4 = fa_world_pos;\n    vec3 param_5 = _6522;\n    vec3 param_6 = param_3.albedo;\n    vec3 param_7 = param_3.normal;\n    fa_apply_decals(param_4, param_5, param_6, param_7);\n    _6561 = param_6;\n    _6563 = param_7;\n    vec3 result;\n    if (fa_mesh_fs_params[3].w > 0.5)\n    {\n        result = _6561;\n    }\n    else\n    {\n        vec3 _6193 = _6563;\n        vec3 _6194 = normalize(_6193);\n        _6563 = _6194;\n        vec3 param_8 = _6194;\n        SurfaceInput param_9 = SurfaceInput(fa_world_pos, _6522, fa_world_tangent, fa_uv, fa_vertex_color, _6146, gl_FrontFacing);\n        Surface param_10 = Surface(_6561, _6562, _6563, _6564, _6565, _6566, _6567, _6568, _6569, _6570, _6571, _6572, _6573, _6574, _6575, _6576, _6577, _6578, _6579, _6580);\n        vec3 param_11 = fa_indirect_diffuse(param_8);\n        vec3 lit = ambient(param_9, param_10, param_11);\n        int _6213 = fa_cl_ndir + fa_cl_local;\n        for (int ln = 0; ln < _6213; ln++)\n        {\n            int param_12 = ln;\n            int _6226 = fa_cl_light(param_12);\n            int param_13 = _6226;\n            if (fa_baked_keep(param_13) <= 0.0)\n            {\n                continue;\n            }\n            int param_14 = _6226;\n            vec3 param_15 = fa_world_pos;\n            vec3 param_16 = _6522;\n            LightSample _6242 = fa_light_shadowed(param_14, param_15, param_16);\n            SurfaceInput param_17 = SurfaceInput(fa_world_pos, _6522, fa_world_tangent, fa_uv, fa_vertex_color, _6146, gl_FrontFacing);\n            Surface param_18 = Surface(_6561, _6562, _6563, _6564, _6565, _6566, _6567, _6568, _6569, _6570, _6571, _6572, _6573, _6574, _6575, _6576, _6577, _6578, _6579, _6580);\n            LightSample param_19 = _6242;\n            lit += light(param_17, param_18, param_19);\n        }\n        result = lit;\n    }\n    vec3 _6257 = result;\n    vec3 _6258 = _6257 + _6567;\n    result = _6258;\n    vec3 param_20 = _6258;\n    vec3 param_21 = fa_world_pos;\n    result = fa_shadow_debug(param_20, param_21);\n    bool _6267 = fa_mesh_fs_params[7].w > 0.0;\n    bool _6274;\n    if (!_6267)\n    {\n        _6274 = fa_mesh_fs_params[8].y > 0.0;\n    }\n    else\n    {\n        _6274 = _6267;\n    }\n    if (_6274)\n    {\n        vec3 _6283 = fa_world_pos - fa_mesh_fs_params[0].xyz;\n        float _6289 = dot(_6283, fa_mesh_fs_params[9].xyz);\n        bool _6293 = fa_mesh_fs_params[9].w > 0.5;\n        float _6294;\n        if (_6293)\n        {\n            _6294 = _6289;\n        }\n        else\n        {\n            _6294 = length(_6283);\n        }\n        float _6306 = _6294 - fa_mesh_fs_params[8].x;\n        if (_6306 > 0.0)\n        {\n            float _6315 = fa_mesh_fs_params[7].w * _6306;\n            float tau = _6315 * _6315;\n            if (fa_mesh_fs_params[8].y > 0.0)\n            {\n                float _6331;\n                if (_6293)\n                {\n                    _6331 = fa_world_pos.y - (fa_mesh_fs_params[9].y * _6289);\n                }\n                else\n                {\n                    _6331 = fa_mesh_fs_params[0].y;\n                }\n                float _6352 = mix(_6331, fa_world_pos.y, clamp(fa_mesh_fs_params[8].x / _6294, 0.0, 1.0));\n                float _6356 = fa_world_pos.y - _6352;\n                float _6361 = _6352 - fa_mesh_fs_params[8].z;\n                float _6366 = fa_world_pos.y - fa_mesh_fs_params[8].z;\n                bool _6369 = _6361 <= 0.0;\n                bool _6370 = !_6369;\n                bool _6376;\n                if (_6370)\n                {\n                    _6376 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _6376 = _6369;\n                }\n                float _6377;\n                if (_6376)\n                {\n                    _6377 = fa_mesh_fs_params[8].y;\n                }\n                else\n                {\n                    _6377 = fa_mesh_fs_params[8].y * exp(-min(fa_mesh_fs_params[8].w * _6361, 80.0));\n                }\n                bool _6404;\n                if (_6370)\n                {\n                    _6404 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _6404 = _6369;\n                }\n                float _6405;\n                if (_6404)\n                {\n                    _6405 = fa_mesh_fs_params[8].y * _6361;\n                }\n                else\n                {\n                    _6405 = (fa_mesh_fs_params[8].y * (1.0 - exp(-min(fa_mesh_fs_params[8].w * _6361, 80.0)))) / fa_mesh_fs_params[8].w;\n                }\n                bool _6430 = _6366 <= 0.0;\n                bool _6437;\n                if (!_6430)\n                {\n                    _6437 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _6437 = _6430;\n                }\n                float _6438;\n                if (_6437)\n                {\n                    _6438 = fa_mesh_fs_params[8].y * _6366;\n                }\n                else\n                {\n                    _6438 = (fa_mesh_fs_params[8].y * (1.0 - exp(-min(fa_mesh_fs_params[8].w * _6366, 80.0)))) / fa_mesh_fs_params[8].w;\n                }\n                float _6465;\n                if (abs(_6356) < 0.001000000047497451305389404296875)\n                {\n                    _6465 = _6377;\n                }\n                else\n                {\n                    _6465 = (_6438 - _6405) / _6356;\n                }\n                tau += (_6306 * max(_6465, 0.0));\n            }\n            result = mix(result, fa_mesh_fs_params[7].xyz, vec3(clamp(1.0 - exp(-clamp(tau, 0.0, 80.0)), 0.0, 1.0)));\n        }\n    }\n    fa_frag_color = vec4(result, _6562);\n}\n\n",
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
            "inst_name": "_499",
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
            "inst_name": "_2156",
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
      "vs": "#version 430\n\nstruct VertexData\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 color;\n    vec3 object_pos;\n};\n\nuniform vec4 fa_mesh_vs_params[11];\nuniform vec4 fa_skin[192];\nlayout(location = 0) out vec3 fa_world_pos;\nlayout(location = 1) out vec3 fa_world_normal;\nlayout(location = 2) out vec4 fa_world_tangent;\nlayout(location = 3) out vec2 fa_uv;\nlayout(location = 4) out vec4 fa_vertex_color;\nlayout(location = 5) in vec4 fa_inst_m0;\nlayout(location = 6) in vec4 fa_inst_m1;\nlayout(location = 7) in vec4 fa_inst_m2;\nlayout(location = 8) in vec4 fa_inst_m3;\nlayout(location = 9) in vec4 fa_joints;\nlayout(location = 10) in vec4 fa_weights;\nlayout(location = 0) in vec3 fa_position;\nlayout(location = 1) in vec3 fa_normal;\nlayout(location = 3) in vec4 fa_tangent;\nlayout(location = 2) in vec2 fa_texcoord0;\nlayout(location = 4) in vec4 fa_color;\nlayout(location = 5) out vec3 fa_lm;\n\nvoid fa_inst_begin()\n{\n}\n\nmat4 fa_skin_matrix(vec4 joints, vec4 weights)\n{\n    vec4 r0 = vec4(0.0);\n    vec4 r1 = vec4(0.0);\n    vec4 r2 = vec4(0.0);\n    for (int i = 0; i < 4; i++)\n    {\n        int _174 = int((joints[i] * 255.0) + 0.5) * 3;\n        r0 += (fa_skin[_174 * 1 + 0] * weights[i]);\n        r1 += (fa_skin[(_174 + 1) * 1 + 0] * weights[i]);\n        r2 += (fa_skin[(_174 + 2) * 1 + 0] * weights[i]);\n    }\n    return mat4(vec4(r0.x, r1.x, r2.x, 0.0), vec4(r0.y, r1.y, r2.y, 0.0), vec4(r0.z, r1.z, r2.z, 0.0), vec4(r0.w, r1.w, r2.w, 1.0));\n}\n\nVertexData fa_vertex_data(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    vec3 _74 = cross(model[1].xyz, model[2].xyz);\n    float _80 = (dot(model[0].xyz, _74) < 0.0) ? (-1.0) : 1.0;\n    return VertexData((model * vec4(position, 1.0)).xyz, (((_74 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _80, vec4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _80), texcoord0 * fa_mesh_vs_params[8].xy, color, position);\n}\n\nvoid fa_shade_vertex(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    mat4 param = model;\n    vec3 param_1 = position;\n    vec3 param_2 = normal;\n    vec4 param_3 = tangent;\n    vec2 param_4 = texcoord0;\n    vec4 param_5 = color;\n    VertexData _273 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    vec3 _388 = _273.world_pos;\n    fa_world_pos = _388;\n    fa_world_normal = _273.world_normal;\n    fa_world_tangent = _273.world_tangent;\n    fa_uv = _273.uv;\n    fa_vertex_color = _273.color;\n    gl_Position = mat4(fa_mesh_vs_params[0], fa_mesh_vs_params[1], fa_mesh_vs_params[2], fa_mesh_vs_params[3]) * vec4(_388, 1.0);\n}\n\nvoid main()\n{\n    fa_inst_begin();\n    vec4 param = fa_joints;\n    vec4 param_1 = fa_weights;\n    mat4 param_2 = mat4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3) * fa_skin_matrix(param, param_1);\n    vec3 param_3 = fa_position;\n    vec3 param_4 = fa_normal;\n    vec4 param_5 = fa_tangent;\n    vec2 param_6 = fa_texcoord0;\n    vec4 param_7 = fa_color;\n    fa_shade_vertex(param_2, param_3, param_4, param_5, param_6, param_7);\n    fa_lm = vec3(0.0);\n}\n\n",
      "fs": "#version 430\n\nstruct SurfaceInput\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 vertex_color;\n    vec3 view_dir;\n    bool front_facing;\n};\n\nstruct LightSample\n{\n    vec3 direction;\n    vec3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct Surface\n{\n    vec3 albedo;\n    float alpha;\n    vec3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    vec3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    vec3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    vec3 specular_color;\n    float transmission;\n    float thickness;\n    vec3 attenuation_color;\n    float attenuation_distance;\n};\n\nstruct FaLayers\n{\n    bool on;\n    float f90;\n    float keep;\n    float base_scale;\n    float coat;\n    float coat_rough;\n    float coat_alpha;\n    float coat_a2;\n    vec3 nc;\n    float coat_ndv;\n    bool sheen_on;\n    vec3 sheen;\n    float sheen_rough;\n    float sheen_alpha;\n    float sheen_scale;\n    float sheen_e;\n    float aniso;\n    vec3 t;\n    vec3 b;\n    float at;\n    float ab;\n};\n\nconst float _4172[63] = float[](1.0, 1.0, 1.0, 0.4790000021457672119140625, 0.11699999868869781494140625, 0.01200000010430812835693359375, 0.0, 0.0, 0.0, 1.0, 1.0, 1.0, 0.578000009059906005859375, 0.19300000369548797607421875, 0.0350000001490116119384765625, 0.0030000000260770320892333984375, 0.0, 0.0, 1.0, 1.0, 1.0, 0.6740000247955322265625, 0.3459999859333038330078125, 0.1319999992847442626953125, 0.032999999821186065673828125, 0.0040000001899898052215576171875, 0.0, 0.971000015735626220703125, 0.954999983310699462890625, 0.828999996185302734375, 0.63999998569488525390625, 0.42599999904632568359375, 0.24500000476837158203125, 0.115000002086162567138671875, 0.037000000476837158203125, 0.0030000000260770320892333984375, 0.7469999790191650390625, 0.737999975681304931640625, 0.670000016689300537109375, 0.563000023365020751953125, 0.4309999942779541015625, 0.3039999902248382568359375, 0.1940000057220458984375, 0.1019999980926513671875, 0.0309999994933605194091796875, 0.614000022411346435546875, 0.609000027179718017578125, 0.566999971866607666015625, 0.499000012874603271484375, 0.412000000476837158203125, 0.32400000095367431640625, 0.240999996662139892578125, 0.162000000476837158203125, 0.087999999523162841796875, 0.538999974727630615234375, 0.535000026226043701171875, 0.505999982357025146484375, 0.4569999873638153076171875, 0.393999993801116943359375, 0.328999996185302734375, 0.2660000026226043701171875, 0.203999996185302734375, 0.14200000464916229248046875);\n\nuniform vec4 fa_mesh_fs_params[53];\nuniform vec4 fa_shadows[30];\nlayout(binding = 0) uniform sampler2D fa_light_tex_fa_shadow_smp;\nlayout(binding = 1) uniform sampler2D fa_tex_fa_smp;\nlayout(binding = 2) uniform sampler2D fa_normal_tex_fa_smp;\nlayout(binding = 3) uniform sampler2D fa_mr_tex_fa_smp;\nlayout(binding = 4) uniform sampler2D fa_occlusion_tex_fa_smp;\nlayout(binding = 5) uniform sampler2D fa_emissive_tex_fa_smp;\nlayout(binding = 6) uniform sampler2D fa_decal_tex_fa_env_smp;\nlayout(binding = 7) uniform sampler2D fa_lightmap_fa_env_smp;\nlayout(binding = 8) uniform sampler2D fa_probe_atlas_fa_env_smp;\nlayout(binding = 9) uniform sampler2D fa_light_atlas_fa_env_smp;\nlayout(binding = 10) uniform sampler2D fa_shadow_tex_fa_shadow_smp;\nlayout(binding = 11) uniform sampler2D fa_screen_tex_fa_shadow_smp;\n\nlayout(location = 0) in vec3 fa_world_pos;\nlayout(location = 5) in vec3 fa_lm;\nlayout(location = 1) in vec3 fa_world_normal;\nlayout(location = 2) in vec4 fa_world_tangent;\nlayout(location = 3) in vec2 fa_uv;\nlayout(location = 4) in vec4 fa_vertex_color;\nlayout(location = 0) out vec4 fa_frag_color;\nvec3 fa_light_tint;\nbool fa_light_is_area;\nint fa_cl_ndir;\nint fa_cl_slot;\nint fa_cl_local;\n\nvoid fa_inst_load()\n{\n}\n\nvec4 fa_light_texel(int t)\n{\n    return texelFetch(fa_light_tex_fa_shadow_smp, ivec2(t & 1023, t >> 10), 0);\n}\n\nvec4 fa_cluster_texel(vec3 world_pos)\n{\n    bool _1427 = fa_mesh_fs_params[19].x < 0.0;\n    bool _1434;\n    if (!_1427)\n    {\n        _1434 = fa_mesh_fs_params[19].w < 1.0;\n    }\n    else\n    {\n        _1434 = _1427;\n    }\n    bool _1442;\n    if (!_1434)\n    {\n        _1442 = fa_mesh_fs_params[18].x < 1.0;\n    }\n    else\n    {\n        _1442 = _1434;\n    }\n    bool _1449;\n    if (!_1442)\n    {\n        _1449 = fa_mesh_fs_params[18].y < 1.0;\n    }\n    else\n    {\n        _1449 = _1442;\n    }\n    bool _1456;\n    if (!_1449)\n    {\n        _1456 = fa_mesh_fs_params[19].y < 1.0;\n    }\n    else\n    {\n        _1456 = _1449;\n    }\n    if (_1456)\n    {\n        return vec4(0.0);\n    }\n    vec4 _1466 = vec4(world_pos, 1.0);\n    float _1472 = dot(fa_mesh_fs_params[16], _1466);\n    if (!(_1472 > 9.9999999747524270787835121154785e-07))\n    {\n        return vec4(0.0);\n    }\n    vec2 _1494 = vec2(dot(fa_mesh_fs_params[14], _1466), dot(fa_mesh_fs_params[15], _1466)) / vec2(_1472);\n    int _1498 = int(fa_mesh_fs_params[18].x);\n    int _1502 = int(fa_mesh_fs_params[18].y);\n    int param = (int(fa_mesh_fs_params[19].x) + (((clamp(int(floor(log2(max(dot(fa_mesh_fs_params[17].xyz, world_pos) + fa_mesh_fs_params[17].w, fa_mesh_fs_params[18].w) / fa_mesh_fs_params[18].w) * fa_mesh_fs_params[18].z)), 0, int(fa_mesh_fs_params[19].y) - 1) * _1502) + clamp(int(floor(((_1494.y * 0.5) + 0.5) * fa_mesh_fs_params[18].y)), 0, _1502 - 1)) * _1498)) + clamp(int(floor(((_1494.x * 0.5) + 0.5) * fa_mesh_fs_params[18].x)), 0, _1498 - 1);\n    return fa_light_texel(param);\n}\n\nivec2 fa_cluster_lookup(vec3 world_pos)\n{\n    vec3 param = world_pos;\n    vec4 _1578 = fa_cluster_texel(param);\n    return ivec2(int(_1578.x), int(_1578.y));\n}\n\nvoid fa_cluster_begin(vec3 world_pos)\n{\n    fa_cl_ndir = int(fa_mesh_fs_params[19].z);\n    vec3 param = world_pos;\n    ivec2 _4981 = fa_cluster_lookup(param);\n    fa_cl_slot = _4981.x;\n    fa_cl_local = _4981.y;\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_linear_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvec3 fa_tex_fix(inout vec3 c, float mode)\n{\n    if (mode > 1.5)\n    {\n        vec3 param = c;\n        vec3 _5193 = fa_linear_to_srgb(param);\n        c = _5193;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            vec3 param_1 = c;\n            vec3 _5201 = fa_srgb_to_linear(param_1);\n            c = _5201;\n        }\n    }\n    return c;\n}\n\nvec3 fa_tangent_normal(SurfaceInput i, vec3 m)\n{\n    vec3 _381;\n    if (i.front_facing)\n    {\n        _381 = i.world_normal;\n    }\n    else\n    {\n        _381 = -i.world_normal;\n    }\n    vec3 _405 = normalize(i.world_tangent.xyz - (_381 * dot(_381, i.world_tangent.xyz)));\n    vec3 _432 = normalize(((_405 * m.x) + ((cross(_381, _405) * i.world_tangent.w) * m.y)) + (_381 * m.z));\n    vec3 _435;\n    if (i.front_facing)\n    {\n        _435 = _432;\n    }\n    else\n    {\n        _435 = -_432;\n    }\n    return _435;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    vec4 base_t = texture(fa_tex_fa_smp, i.uv);\n    float param = fa_mesh_fs_params[6].w;\n    float param_1 = 1.0;\n    vec3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    vec3 _5232 = fa_tex_fix(param_2, param_3);\n    vec4 _7051 = base_t;\n    _7051.x = _5232.x;\n    _7051.y = _5232.y;\n    _7051.z = _5232.z;\n    base_t = _7051;\n    vec4 _5246 = (_7051 * fa_mesh_fs_params[2]) * i.vertex_color;\n    vec3 _6857 = i.world_normal;\n    if (fa_mesh_fs_params[6].z > 0.5)\n    {\n        float param_4 = fa_mesh_fs_params[6].w;\n        float param_5 = 16.0;\n        vec3 param_6 = texture(fa_normal_tex_fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        vec3 _5278 = fa_tex_fix(param_6, param_7);\n        vec3 _5281 = (_5278 * 2.0) - vec3(1.0);\n        vec2 _5286 = _5281.xy * fa_mesh_fs_params[6].x;\n        vec3 _7059 = _5281;\n        _7059.x = _5286.x;\n        _7059.y = _5286.y;\n        SurfaceInput param_8 = i;\n        vec3 param_9 = _7059;\n        _6857 = fa_tangent_normal(param_8, param_9);\n    }\n    vec4 mrt = texture(fa_mr_tex_fa_smp, i.uv);\n    float param_10 = fa_mesh_fs_params[6].w;\n    float param_11 = 64.0;\n    vec3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    vec3 _5314 = fa_tex_fix(param_12, param_13);\n    vec4 _7062 = mrt;\n    _7062.x = _5314.x;\n    _7062.y = _5314.y;\n    _7062.z = _5314.z;\n    mrt = _7062;\n    vec4 _5342 = texture(fa_occlusion_tex_fa_smp, i.uv);\n    float param_14 = fa_mesh_fs_params[6].w;\n    float param_15 = 256.0;\n    vec3 param_16 = _5342.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    vec3 _5353 = fa_tex_fix(param_16, param_17);\n    float param_18 = fa_mesh_fs_params[6].w;\n    float param_19 = 4.0;\n    vec3 param_20 = texture(fa_emissive_tex_fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    vec3 _5383 = fa_tex_fix(param_20, param_21);\n    float _6862 = fa_mesh_fs_params[20].x;\n    float _6863 = fa_mesh_fs_params[20].y;\n    float _6866 = fa_mesh_fs_params[20].z;\n    float _6865 = fa_mesh_fs_params[21].w;\n    float _6868 = fa_mesh_fs_params[22].x;\n    if (fa_mesh_fs_params[22].z > 0.5)\n    {\n        if (mod(fa_mesh_fs_params[22].z, 2.0) > 0.5)\n        {\n            _6862 *= _5353.y;\n            _6863 *= _5353.z;\n            _6865 *= _5342.w;\n        }\n        if (fa_mesh_fs_params[22].z > 1.5)\n        {\n            _6866 *= mrt.x;\n            _6868 *= mrt.w;\n        }\n    }\n    return Surface(_5246.xyz, _5246.w, _6857, clamp(fa_mesh_fs_params[5].x * _5314.z, 0.0, 1.0), clamp(fa_mesh_fs_params[5].y * _5314.y, 0.0500000007450580596923828125, 1.0), 1.0 + (fa_mesh_fs_params[6].y * (_5353.x - 1.0)), fa_mesh_fs_params[3].xyz + (fa_mesh_fs_params[4].xyz * _5383), _6862, _6863, fa_mesh_fs_params[21].xyz, _6865, _6866, fa_mesh_fs_params[20].w, _6868, fa_mesh_fs_params[22].y, fa_mesh_fs_params[23].xyz, fa_mesh_fs_params[30].x, fa_mesh_fs_params[30].y, fa_mesh_fs_params[31].xyz, fa_mesh_fs_params[30].z);\n}\n\nvoid surface(SurfaceInput i, Surface s)\n{\n}\n\nvec4 fa_decal_tile(vec4 rect, vec2 uv, vec2 atlas, vec2 ddx, vec2 ddy)\n{\n    vec2 _1658 = rect.zw - rect.xy;\n    vec2 _1662 = _1658 * atlas;\n    vec2 _1666 = ddx * _1662;\n    vec2 _1670 = ddy * _1662;\n    return textureLod(fa_decal_tex_fa_env_smp, rect.xy + (clamp(uv, vec2(0.0), vec2(1.0)) * _1658), clamp(0.5 * log2(max(max(dot(_1666, _1666), dot(_1670, _1670)), 9.9999999392252902907785028219223e-09)), 0.0, 4.0));\n}\n\nvec3 fa_dc_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_dc_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvoid fa_apply_decals(vec3 world_pos, vec3 geo_normal, inout vec3 albedo, inout vec3 normal)\n{\n    bool _1703 = fa_mesh_fs_params[10].y < 0.5;\n    bool _1710;\n    if (!_1703)\n    {\n        _1710 = fa_mesh_fs_params[10].w < 0.5;\n    }\n    else\n    {\n        _1710 = _1703;\n    }\n    if (_1710)\n    {\n        return;\n    }\n    vec3 _1716 = dFdx(world_pos);\n    vec3 _1719 = dFdy(world_pos);\n    vec3 param = world_pos;\n    vec4 _1723 = fa_cluster_texel(param);\n    int _1727 = int(_1723.w);\n    if (_1727 < 1)\n    {\n        return;\n    }\n    int _1737 = int(fa_mesh_fs_params[10].y + 0.5);\n    int param_1 = _1737;\n    vec4 _1741 = fa_light_texel(param_1);\n    vec2 _1744 = _1741.yz;\n    int _1748 = int(_1741.w);\n    int param_2 = _1737 + 1;\n    vec4 _1753 = fa_light_texel(param_2);\n    float _1754 = _1753.x;\n    int _1760 = int(fa_mesh_fs_params[10].w + 0.5) - 1;\n    int _1764 = int(_1723.z);\n    vec3 _2029;\n    for (int k = 0; k < _1727; k++)\n    {\n        int _1777 = _1764 + k;\n        int param_3 = _1748 + (_1777 >> 2);\n        int _1794 = (_1737 + 2) + (int(fa_light_texel(param_3)[_1777 & 3]) * 7);\n        int param_4 = _1794 + 6;\n        vec4 _1799 = fa_light_texel(param_4);\n        if (((int(_1799.w + 0.5) >> _1760) & 1) == 0)\n        {\n            continue;\n        }\n        int param_5 = _1794;\n        vec4 _1814 = fa_light_texel(param_5);\n        int param_6 = _1794 + 1;\n        vec4 _1819 = fa_light_texel(param_6);\n        int param_7 = _1794 + 2;\n        vec4 _1824 = fa_light_texel(param_7);\n        vec3 _1827 = _1814.xyz;\n        float _1832 = dot(_1827, world_pos) + _1814.w;\n        vec3 _1834 = _1819.xyz;\n        float _1839 = dot(_1834, world_pos) + _1819.w;\n        vec3 _1841 = _1824.xyz;\n        float _1846 = dot(_1841, world_pos) + _1824.w;\n        bool _1851 = abs(_1832) > 0.5;\n        bool _1859;\n        if (!_1851)\n        {\n            _1859 = abs(_1839) > 0.5;\n        }\n        else\n        {\n            _1859 = _1851;\n        }\n        bool _1867;\n        if (!_1859)\n        {\n            _1867 = abs(_1846) > 0.5;\n        }\n        else\n        {\n            _1867 = _1859;\n        }\n        if (_1867)\n        {\n            continue;\n        }\n        float _1882 = clamp(dot(geo_normal, normalize(_1841)) * _1799.z, 0.0, 1.0);\n        if (_1882 <= 0.0)\n        {\n            continue;\n        }\n        float _1902 = (clamp((0.5 - abs(_1846)) * 10.0, 0.0, 1.0) * _1882) * _1799.x;\n        vec2 _1910 = vec2(_1832 + 0.5, 0.5 - _1839);\n        vec2 _1920 = vec2(dot(_1827, _1716), dot(_1834, _1716));\n        vec2 _1930 = vec2(dot(_1827, _1719), dot(_1834, _1719));\n        int param_8 = _1794 + 5;\n        vec4 _1935 = fa_light_texel(param_8);\n        int param_9 = _1794 + 3;\n        vec4 _1940 = fa_light_texel(param_9);\n        int param_10 = _1794 + 4;\n        vec4 _1945 = fa_light_texel(param_10);\n        float tex_a = 1.0;\n        vec3 col = _1935.xyz;\n        bool _1955 = _1940.z > _1940.x;\n        if (_1955)\n        {\n            vec4 param_11 = _1940;\n            vec2 param_12 = _1910;\n            vec2 param_13 = _1744;\n            vec2 param_14 = _1920;\n            vec2 param_15 = _1930;\n            vec4 tx = fa_decal_tile(param_11, param_12, param_13, param_14, param_15);\n            if ((_1754 > 0.5) && (_1754 < 1.5))\n            {\n                vec3 param_16 = tx.xyz;\n                vec3 _1981 = fa_dc_to_linear(param_16);\n                vec4 _6945 = tx;\n                _6945.x = _1981.x;\n                _6945.y = _1981.y;\n                _6945.z = _1981.z;\n                tx = _6945;\n            }\n            col *= tx.xyz;\n            tex_a = tx.w;\n        }\n        albedo = mix(albedo, col, vec3(clamp((_1902 * tex_a) * _1935.w, 0.0, 1.0)));\n        if (_1945.z > _1945.x)\n        {\n            vec4 param_17 = _1945;\n            vec2 param_18 = _1910;\n            vec2 param_19 = _1744;\n            vec2 param_20 = _1920;\n            vec2 param_21 = _1930;\n            vec4 _2025 = fa_decal_tile(param_17, param_18, param_19, param_20, param_21);\n            if (_1754 > 1.5)\n            {\n                vec3 param_22 = _2025.xyz;\n                vec3 _2035 = fa_dc_to_srgb(param_22);\n                _2029 = _2035;\n            }\n            else\n            {\n                _2029 = _2025.xyz;\n            }\n            vec3 _2044 = (_2029 * 2.0) - vec3(1.0);\n            vec2 _2049 = _2044.xy * _1799.y;\n            vec3 _2071 = (normalize(_1827) * _2049.x) + (normalize(_1834) * _2049.y);\n            vec3 _2074 = normalize(normal);\n            normal = normalize(mix(_2074, normalize((_2074 * max(_2044.z, 0.0500000007450580596923828125)) + (_2071 - (_2074 * dot(_2074, _2071)))), vec3(clamp(_1902 * (_1955 ? tex_a : 1.0), 0.0, 1.0))));\n        }\n    }\n}\n\nvec3 fa_sh_eval(vec3 c[9], vec3 n)\n{\n    vec3 _3269 = max((((c[0] * 0.2820948064327239990234375) + (((c[1] * (0.3257350027561187744140625 * n.y)) + (c[2] * (0.3257350027561187744140625 * n.z))) + (c[3] * (0.3257350027561187744140625 * n.x)))) + (((c[4] * ((0.2731371223926544189453125 * n.x) * n.y)) + (c[5] * ((0.2731371223926544189453125 * n.y) * n.z))) + (c[6] * (0.078847892582416534423828125 * (((3.0 * n.z) * n.z) - 1.0))))) + ((c[7] * ((0.2731371223926544189453125 * n.x) * n.z)) + (c[8] * (0.13656856119632720947265625 * ((n.x * n.x) - (n.y * n.y))))), vec3(0.0));\n    return _3269;\n}\n\nvec2 fa_atlas_size()\n{\n    return vec2(textureSize(fa_probe_atlas_fa_env_smp, 0));\n}\n\nvec4 fa_gi_fetch(vec2 texel)\n{\n    return textureLod(fa_probe_atlas_fa_env_smp, texel / fa_atlas_size(), 0.0);\n}\n\nvec2 fa_oct_encode(vec3 d)\n{\n    vec3 _3289 = d / vec3(max((abs(d.x) + abs(d.y)) + abs(d.z), 9.9999999600419720025001879548654e-13));\n    float _3292 = _3289.x;\n    float _3294 = _3289.z;\n    vec2 e = vec2(_3292, _3294);\n    if (_3289.y < 0.0)\n    {\n        e = vec2((1.0 - abs(_3294)) * ((_3292 < 0.0) ? (-1.0) : 1.0), (1.0 - abs(_3292)) * ((_3294 < 0.0) ? (-1.0) : 1.0));\n    }\n    return e;\n}\n\nvec3 fa_gi_grid(int rec, vec3 n, vec3 v, out float cover)\n{\n    cover = 0.0;\n    int param = rec;\n    vec4 _5495 = fa_light_texel(param);\n    int param_1 = rec + 1;\n    vec4 _5500 = fa_light_texel(param_1);\n    int param_2 = rec + 2;\n    vec4 _5505 = fa_light_texel(param_2);\n    int param_3 = rec + 3;\n    vec4 _5510 = fa_light_texel(param_3);\n    bool _5513 = _5510.z < 0.5;\n    bool _5521;\n    if (!_5513)\n    {\n        _5521 = fa_atlas_size().y < 1155.0;\n    }\n    else\n    {\n        _5521 = _5513;\n    }\n    if (_5521)\n    {\n        return vec3(0.0);\n    }\n    float _5528 = max(_5495.w, 9.9999997473787516355514526367188e-05);\n    vec3 _5531 = _5500.xyz;\n    vec3 _5535 = _5495.xyz;\n    vec3 _5539 = (fa_world_pos - _5535) / vec3(_5528);\n    vec3 _5548 = min(_5539 + vec3(0.5), (_5531 - vec3(0.5)) - _5539);\n    float _5557 = min(_5548.x, min(_5548.y, _5548.z));\n    if (!(_5557 > 0.0))\n    {\n        return vec3(0.0);\n    }\n    vec3 _5572 = _5531 - vec3(1.0);\n    vec3 _5573 = clamp(_5539, vec3(0.0), _5572);\n    vec3 _5581 = min(floor(_5573), max(_5531 - vec3(2.0), vec3(0.0)));\n    vec3 _5585 = _5573 - _5581;\n    vec3 _5596 = fa_world_pos + (((n * 0.800000011920928955078125) + (v * 0.20000000298023223876953125)) * (0.20000000298023223876953125 * _5528));\n    int _5601 = int(_5505.y + 0.5);\n    vec3 sh[9];\n    for (int k = 0; k < 9; k++)\n    {\n        sh[k] = vec3(0.0);\n    }\n    float wsum = 0.0;\n    int _5619 = int(_5510.w);\n    int _5620 = 8 + _5619;\n    int _5625 = 9 + _5619;\n    float _5652;\n    float _5665;\n    float _5679;\n    for (int k_1 = 0; k_1 < _5620; k_1++)\n    {\n        float _5638 = float(k_1 & 1);\n        float _5642 = float((k_1 >> 1) & 1);\n        float _5646 = float((k_1 >> 2) & 1);\n        if (_5638 > 0.5)\n        {\n            _5652 = _5585.x;\n        }\n        else\n        {\n            _5652 = 1.0 - _5585.x;\n        }\n        if (_5642 > 0.5)\n        {\n            _5665 = _5585.y;\n        }\n        else\n        {\n            _5665 = 1.0 - _5585.y;\n        }\n        if (_5646 > 0.5)\n        {\n            _5679 = _5585.z;\n        }\n        else\n        {\n            _5679 = 1.0 - _5585.z;\n        }\n        float _5689 = (_5652 * _5665) * _5679;\n        if (!(_5689 > 0.0))\n        {\n            continue;\n        }\n        vec3 _5702 = min(_5581 + vec3(_5638, _5642, _5646), _5572);\n        int _5722 = int(((_5505.x + _5702.x) + (_5500.x * (_5702.y + (_5500.y * _5702.z)))) + 0.5);\n        vec2 _5737 = vec2(float(_5722 % _5601) * 10.0, 1024.0 + (float(_5722 / _5601) * 11.0));\n        vec2 param_4 = _5737 + vec2(9.5, 10.5);\n        vec4 _5745 = fa_gi_fetch(param_4);\n        bool _5748 = _5745.y < 0.5;\n        bool _5757;\n        if (!_5748)\n        {\n            _5757 = _5745.x > _5510.y;\n        }\n        else\n        {\n            _5757 = _5748;\n        }\n        if (_5757)\n        {\n            continue;\n        }\n        vec3 _5769 = _5596 - (_5535 + (_5702 * _5528));\n        float _5772 = length(_5769);\n        vec3 _5778 = _5769 / vec3(max(_5772, 9.9999997473787516355514526367188e-05));\n        float _5788 = max(9.9999997473787516355514526367188e-05, (dot(-_5778, n) + 1.0) * 0.5);\n        float w = _5689 * (_5788 * _5788);\n        vec3 param_5 = _5778;\n        vec2 param_6 = (_5737 + vec2(1.0)) + (((fa_oct_encode(param_5) * 0.5) + vec2(0.5)) * 8.0);\n        vec4 _5807 = fa_gi_fetch(param_6);\n        float _5814 = _5772 / max(_5505.z, 9.9999997473787516355514526367188e-05);\n        float _5817 = _5807.x;\n        if (_5814 > _5817)\n        {\n            float _5830 = max(_5807.y - (_5817 * _5817), 0.0);\n            float _5835 = _5814 - _5817;\n            float _5844 = _5830 / max(_5830 + (_5835 * _5835), 9.9999999600419720025001879548654e-13);\n            w *= ((_5844 * _5844) * _5844);\n        }\n        if (!(w > 0.0))\n        {\n            continue;\n        }\n        for (int c = 0; c < _5625; c++)\n        {\n            vec2 param_7 = _5737 + vec2(float(c) + 0.5, 10.5);\n            sh[c] += (fa_gi_fetch(param_7).xyz * w);\n        }\n        wsum += w;\n    }\n    if (!(wsum > 9.9999997473787516355514526367188e-06))\n    {\n        return vec3(0.0);\n    }\n    for (int c_1 = 0; c_1 < 9; c_1++)\n    {\n        sh[c_1] /= vec3(wsum);\n    }\n    cover = smoothstep(0.0, 1.0, clamp(_5557 * 2.0, 0.0, 1.0)) * smoothstep(0.0, 0.0199999995529651641845703125, wsum);\n    float _5925;\n    if (fa_mesh_fs_params[52].z > 0.5)\n    {\n        _5925 = _5510.x;\n    }\n    else\n    {\n        _5925 = 1.0;\n    }\n    vec3 param_8[9] = sh;\n    vec3 param_9 = n;\n    return fa_sh_eval(param_8, param_9) * (_5505.w * _5925);\n}\n\nvec3 fa_gi_light(vec3 n, inout float left)\n{\n    left = 1.0;\n    vec3 acc = vec3(0.0);\n    vec3 _5949 = normalize(fa_mesh_fs_params[0].xyz - fa_world_pos);\n    int _5954 = int(fa_mesh_fs_params[52].x + 0.5);\n    int _5959 = int(fa_mesh_fs_params[52].y + 0.5);\n    float param_3;\n    for (int k = 0; (k < _5959) && (k < 8); k++)\n    {\n        int param = _5954 + (4 * k);\n        vec3 param_1 = n;\n        vec3 param_2 = _5949;\n        vec3 _5984 = fa_gi_grid(param, param_1, param_2, param_3);\n        float _5989 = param_3 * left;\n        acc += (_5984 * _5989);\n        left -= _5989;\n        if (left < 0.001000000047497451305389404296875)\n        {\n            left = 0.0;\n            break;\n        }\n    }\n    return acc;\n}\n\nvec3 fa_probe_sh_coef(vec2 origin, float res, int k)\n{\n    vec3 v = textureLod(fa_probe_atlas_fa_env_smp, (origin + vec2(float(k) + 0.5, res + 2.5)) / fa_atlas_size(), 0.0).xyz;\n    if (fa_mesh_fs_params[41].y > 0.5)\n    {\n        v = (v - vec3(0.5)) * 8.0;\n    }\n    return v;\n}\n\nvec3 fa_ambient_light(vec3 n)\n{\n    float _3879 = (1.0 - fa_mesh_fs_params[42].w) - fa_mesh_fs_params[47].w;\n    vec3 amb = vec3(0.0);\n    bool _3884 = fa_mesh_fs_params[11].w > 0.5;\n    vec3 c[9];\n    for (int k = 0; k < 9; k++)\n    {\n        c[k] = vec3(0.0);\n    }\n    if (_3879 > 0.0005000000237487256526947021484375)\n    {\n        if (_3884)\n        {\n            for (int k_1 = 0; k_1 < 9; k_1++)\n            {\n                vec2 param = fa_mesh_fs_params[41].zw;\n                float param_1 = 128.0;\n                int param_2 = k_1;\n                c[k_1] = fa_probe_sh_coef(param, param_1, param_2) * _3879;\n            }\n        }\n        else\n        {\n            amb = fa_mesh_fs_params[1].xyz * _3879;\n        }\n    }\n    bool _3935 = fa_mesh_fs_params[42].w > 0.0;\n    if (_3935)\n    {\n        for (int k_2 = 0; k_2 < 9; k_2++)\n        {\n            vec2 param_3 = fa_mesh_fs_params[42].xy;\n            float param_4 = fa_mesh_fs_params[42].z;\n            int param_5 = k_2;\n            c[k_2] += (fa_probe_sh_coef(param_3, param_4, param_5) * fa_mesh_fs_params[42].w);\n        }\n    }\n    bool _3966 = fa_mesh_fs_params[47].w > 0.0;\n    if (_3966)\n    {\n        for (int k_3 = 0; k_3 < 9; k_3++)\n        {\n            vec2 param_6 = fa_mesh_fs_params[47].xy;\n            float param_7 = fa_mesh_fs_params[47].z;\n            int param_8 = k_3;\n            c[k_3] += (fa_probe_sh_coef(param_6, param_7, param_8) * fa_mesh_fs_params[47].w);\n        }\n    }\n    if ((_3884 || _3935) || _3966)\n    {\n        vec3 param_9[9] = c;\n        vec3 param_10 = n;\n        amb += fa_sh_eval(param_9, param_10);\n    }\n    return amb;\n}\n\nvec3 fa_realtime_or_ambient(vec3 n)\n{\n    if (fa_mesh_fs_params[52].y > 0.5)\n    {\n        vec3 param = n;\n        float param_1;\n        vec3 _6018 = fa_gi_light(param, param_1);\n        if (param_1 < 0.999000012874603271484375)\n        {\n            vec3 _6027;\n            if (param_1 > 0.0)\n            {\n                vec3 param_2 = n;\n                _6027 = _6018 + (fa_ambient_light(param_2) * param_1);\n            }\n            else\n            {\n                _6027 = _6018;\n            }\n            return _6027;\n        }\n    }\n    vec3 param_3 = n;\n    return fa_ambient_light(param_3);\n}\n\nvec3 fa_indirect_diffuse(vec3 n)\n{\n    if (fa_lm.z > 0.5)\n    {\n        return textureLod(fa_lightmap_fa_env_smp, fa_lm.xy, 0.0).xyz;\n    }\n    if (fa_mesh_fs_params[32].w > 0.0)\n    {\n        vec3 c[9];\n        for (int k = 0; k < 9; k++)\n        {\n            c[k] = fa_mesh_fs_params[k * 1 + 32].xyz;\n        }\n        vec3 param[9] = c;\n        vec3 param_1 = n;\n        vec3 _6089 = fa_sh_eval(param, param_1);\n        if (fa_mesh_fs_params[32].w >= 1.0)\n        {\n            return _6089;\n        }\n        vec3 param_2 = n;\n        return mix(fa_realtime_or_ambient(param_2), _6089, vec3(clamp(fa_mesh_fs_params[32].w, 0.0, 1.0)));\n    }\n    vec3 param_3 = n;\n    return fa_realtime_or_ambient(param_3);\n}\n\nfloat fa_sheen_albedo(float ndv, float rough)\n{\n    float _4098 = min(sqrt(max(rough - 0.100000001490116119384765625, 0.0) * 1.111111164093017578125) * 6.0, 5.999000072479248046875);\n    float _4105 = min(sqrt(clamp(ndv, 0.0, 1.0)) * 8.0, 7.999000072479248046875);\n    int _4108 = int(_4098);\n    int _4111 = int(_4105);\n    float _4121 = _4105 - float(_4111);\n    int _4176 = (_4108 * 9) + _4111;\n    int _4196 = ((_4108 + 1) * 9) + _4111;\n    return mix(mix(_4172[_4176], _4172[_4176 + 1], _4121), mix(_4172[_4196], _4172[_4196 + 1], _4121), _4098 - float(_4108));\n}\n\nFaLayers fa_layers_setup(SurfaceInput i, Surface s, vec3 n, vec3 v, float metallic, float roughness, inout vec3 f0)\n{\n    bool _6716 = false;\n    float _6717 = 1.0;\n    float _6718 = 1.0;\n    float _6719 = 1.0;\n    float _6720 = 0.0;\n    float _6721 = 0.0;\n    float _6722 = 0.0;\n    float _6723 = 0.0;\n    float _6725 = 1.0;\n    bool _6726 = false;\n    vec3 _6727 = vec3(0.0);\n    float _6728 = 1.0;\n    float _6729 = 1.0;\n    float _6730 = 1.0;\n    float _6731 = 0.0;\n    float _6732 = 0.0;\n    vec3 _6733 = vec3(1.0, 0.0, 0.0);\n    vec3 _6734 = vec3(0.0, 0.0, 1.0);\n    float _6735 = 1.0;\n    float _6736 = 1.0;\n    float _4247 = clamp(s.specular, 0.0, 1.0);\n    float _4251 = clamp(s.ior, 1.0, 3.0);\n    bool _4256 = (_4247 != 1.0) || (_4251 != 1.5);\n    bool _4265;\n    if (!_4256)\n    {\n        _4265 = any(notEqual(s.specular_color, vec3(1.0)));\n    }\n    else\n    {\n        _4265 = _4256;\n    }\n    if (_4265)\n    {\n        float _4273 = (_4251 - 1.0) / (_4251 + 1.0);\n        f0 = mix(min(vec3(_4273 * _4273) * max(s.specular_color, vec3(0.0)), vec3(1.0)) * _4247, s.albedo, vec3(metallic));\n        _6717 = mix(_4247, 1.0, metallic);\n        _6716 = true;\n    }\n    float _4300 = clamp(s.clearcoat, 0.0, 1.0);\n    if (_4300 > 0.0)\n    {\n        float _4308 = clamp(s.clearcoat_roughness, 0.0500000007450580596923828125, 1.0);\n        _6720 = _4300;\n        _6721 = _4308;\n        float _4315 = _4308 * _4308;\n        _6722 = _4315;\n        _6723 = _4315 * _4315;\n        float _4327 = max(dot(i.world_normal, v), 9.9999997473787516355514526367188e-05);\n        _6725 = _4327;\n        _6718 = 1.0 - (_4300 * (0.039999999105930328369140625 + (0.959999978542327880859375 * pow(clamp(1.0 - _4327, 0.0, 1.0), 5.0))));\n        _6716 = true;\n    }\n    vec3 _4346 = max(s.sheen_color, vec3(0.0));\n    float _4355 = max(_4346.x, max(_4346.y, _4346.z));\n    if (_4355 > 0.0)\n    {\n        float _4363 = clamp(s.sheen_roughness, 0.100000001490116119384765625, 1.0);\n        _6726 = true;\n        _6727 = _4346;\n        _6728 = _4363;\n        _6729 = _4363 * _4363;\n        float param = max(dot(n, v), 9.9999997473787516355514526367188e-05);\n        float param_1 = _4363;\n        float _4380 = fa_sheen_albedo(param, param_1);\n        _6731 = _4380;\n        _6730 = 1.0 - min(_4355 * _4380, 1.0);\n        _6716 = true;\n    }\n    _6719 = _6718 * _6730;\n    float _4399 = clamp(s.anisotropy, -1.0, 1.0);\n    if (_4399 != 0.0)\n    {\n        vec3 _4414 = i.world_tangent.xyz - (n * dot(n, i.world_tangent.xyz));\n        vec3 t = _4414;\n        if (dot(_4414, _4414) < 9.9999999392252902907785028219223e-09)\n        {\n            bvec3 _4426 = bvec3(abs(n.y) < 0.9900000095367431640625);\n            t = cross(vec3(_4426.x ? vec3(0.0, 1.0, 0.0).x : vec3(1.0, 0.0, 0.0).x, _4426.y ? vec3(0.0, 1.0, 0.0).y : vec3(1.0, 0.0, 0.0).y, _4426.z ? vec3(0.0, 1.0, 0.0).z : vec3(1.0, 0.0, 0.0).z), n);\n        }\n        vec3 _4430 = t;\n        vec3 _4431 = normalize(_4430);\n        t = _4431;\n        vec3 _4456 = normalize((_4431 * cos(s.anisotropy_rotation)) + ((cross(n, _4431) * ((i.world_tangent.w < 0.0) ? (-1.0) : 1.0)) * sin(s.anisotropy_rotation)));\n        _6733 = _4456;\n        _6734 = cross(n, _4456);\n        float _4466 = roughness * roughness;\n        float _4472 = mix(_4466, 1.0, _4399 * _4399);\n        bool _4474 = _4399 > 0.0;\n        _6735 = _4474 ? _4472 : _4466;\n        _6736 = _4474 ? _4466 : _4472;\n        _6732 = _4399;\n        _6716 = true;\n    }\n    return FaLayers(_6716, _6717, _6718, _6719, _6720, _6721, _6722, _6723, i.world_normal, _6725, _6726, _6727, _6728, _6729, _6730, _6731, _6732, _6733, _6734, _6735, _6736);\n}\n\nvec2 fa_env_brdf(float rough, float ndv)\n{\n    vec4 _4030 = (vec4(-1.0, -0.0274999998509883880615234375, -0.572000026702880859375, 0.02199999988079071044921875) * rough) + vec4(1.0, 0.0425000004470348358154296875, 1.03999996185302734375, -0.039999999105930328369140625);\n    float _4033 = _4030.x;\n    return (vec2(-1.03999996185302734375, 1.03999996185302734375) * ((min(_4033 * _4033, exp2((-9.27999973297119140625) * ndv)) * _4033) + _4030.y)) + _4030.zw;\n}\n\nvec3 fa_probe_level(vec2 origin, float res, int lv, vec2 e)\n{\n    float _3341;\n    if (lv == 0)\n    {\n        _3341 = 0.0;\n    }\n    else\n    {\n        _3341 = res + 2.0;\n    }\n    float _3351;\n    if (lv == 0)\n    {\n        _3351 = 0.0;\n    }\n    else\n    {\n        _3351 = (res - (res / float(1 << (lv - 1)))) + (2.0 * float(lv - 1));\n    }\n    return textureLod(fa_probe_atlas_fa_env_smp, (((origin + vec2(_3341, _3351)) + vec2(1.0)) + (((e * 0.5) + vec2(0.5)) * (res / float(1 << lv)))) / fa_atlas_size(), 0.0).xyz;\n}\n\nvec3 fa_probe_radiance(vec2 origin, float res, vec3 d, float rough)\n{\n    float _3396;\n    if (res > 64.5)\n    {\n        _3396 = 5.0;\n    }\n    else\n    {\n        _3396 = (res > 32.5) ? 4.0 : 3.0;\n    }\n    float _3411 = clamp(rough, 0.0, 1.0) * (_3396 - 1.0);\n    int _3418 = int(min(floor(_3411), _3396 - 2.0));\n    float _3423 = _3411 - float(_3418);\n    vec3 param = d;\n    vec2 _3427 = fa_oct_encode(param);\n    vec2 param_1 = origin;\n    float param_2 = res;\n    int param_3 = _3418;\n    vec2 param_4 = _3427;\n    vec3 _3437 = fa_probe_level(param_1, param_2, param_3, param_4);\n    if (_3423 < 0.00200000009499490261077880859375)\n    {\n        return _3437;\n    }\n    vec2 param_5 = origin;\n    float param_6 = res;\n    int param_7 = _3418 + 1;\n    vec2 param_8 = _3427;\n    return mix(_3437, fa_probe_level(param_5, param_6, param_7, param_8), vec3(_3423));\n}\n\nvec3 fa_probe_box_dir(vec3 d, vec4 posw, vec4 bx, vec4 by, vec4 bz)\n{\n    if (posw.w < 0.5)\n    {\n        return d;\n    }\n    float _3507 = dot(bx.xyz, fa_world_pos) + bx.w;\n    float _3514 = dot(by.xyz, fa_world_pos) + by.w;\n    float _3521 = dot(bz.xyz, fa_world_pos) + bz.w;\n    float _3527 = dot(bx.xyz, d);\n    float _3531 = dot(by.xyz, d);\n    float _3535 = dot(bz.xyz, d);\n    float _3541;\n    if (_3527 > 9.9999999747524270787835121154785e-07)\n    {\n        _3541 = (1.0 - _3507) / _3527;\n    }\n    else\n    {\n        float _3555;\n        if (_3527 < (-9.9999999747524270787835121154785e-07))\n        {\n            _3555 = ((-1.0) - _3507) / _3527;\n        }\n        else\n        {\n            _3555 = 1000000015047466219876688855040.0;\n        }\n        _3541 = _3555;\n    }\n    float tx = _3541;\n    float _3572;\n    if (_3531 > 9.9999999747524270787835121154785e-07)\n    {\n        _3572 = (1.0 - _3514) / _3531;\n    }\n    else\n    {\n        float _3585;\n        if (_3531 < (-9.9999999747524270787835121154785e-07))\n        {\n            _3585 = ((-1.0) - _3514) / _3531;\n        }\n        else\n        {\n            _3585 = 1000000015047466219876688855040.0;\n        }\n        _3572 = _3585;\n    }\n    float ty = _3572;\n    float _3601;\n    if (_3535 > 9.9999999747524270787835121154785e-07)\n    {\n        _3601 = (1.0 - _3521) / _3535;\n    }\n    else\n    {\n        float _3614;\n        if (_3535 < (-9.9999999747524270787835121154785e-07))\n        {\n            _3614 = ((-1.0) - _3521) / _3535;\n        }\n        else\n        {\n            _3614 = 1000000015047466219876688855040.0;\n        }\n        _3601 = _3614;\n    }\n    float _3626 = tx;\n    float _3629 = (_3626 > 0.0) ? _3626 : 1000000015047466219876688855040.0;\n    tx = _3629;\n    float _3630 = ty;\n    float _3633 = (_3630 > 0.0) ? _3630 : 1000000015047466219876688855040.0;\n    ty = _3633;\n    float _3643 = min(_3629, min(_3633, (_3601 > 0.0) ? _3601 : 1000000015047466219876688855040.0));\n    if (_3643 > 100000001504746621987668885504.0)\n    {\n        return d;\n    }\n    vec3 _3659 = (fa_world_pos + (d * _3643)) - posw.xyz;\n    vec3 _3664;\n    if (dot(_3659, _3659) > 1.0000000133514319600180897396058e-10)\n    {\n        _3664 = normalize(_3659);\n    }\n    else\n    {\n        _3664 = d;\n    }\n    return _3664;\n}\n\nvec3 fa_probe_environment(vec4 tile, vec4 posw, vec4 bx, vec4 by, vec4 bz, inout vec3 d, float rough)\n{\n    vec3 param = d;\n    vec4 param_1 = posw;\n    vec4 param_2 = bx;\n    vec4 param_3 = by;\n    vec4 param_4 = bz;\n    d = fa_probe_box_dir(param, param_1, param_2, param_3, param_4);\n    vec2 param_5 = tile.xy;\n    float param_6 = tile.z;\n    vec3 param_7 = d;\n    float param_8 = rough;\n    return fa_probe_radiance(param_5, param_6, param_7, param_8);\n}\n\nvec3 fa_environment(vec3 d, float rough)\n{\n    float _3710 = (1.0 - fa_mesh_fs_params[42].w) - fa_mesh_fs_params[47].w;\n    vec3 outc = vec3(0.0);\n    if (_3710 > 0.0005000000237487256526947021484375)\n    {\n        vec3 base;\n        if (fa_mesh_fs_params[11].w > 0.5)\n        {\n            vec2 param = fa_mesh_fs_params[41].zw;\n            float param_1 = 128.0;\n            vec3 param_2 = d;\n            float param_3 = rough;\n            base = fa_probe_radiance(param, param_1, param_2, param_3);\n        }\n        else\n        {\n            float _3739 = rough * rough;\n            float _3770 = 0.60000002384185791015625 * _3739;\n            base = mix(mix(fa_mesh_fs_params[12].xyz * 0.550000011920928955078125, mix(fa_mesh_fs_params[12].xyz, fa_mesh_fs_params[11].xyz, vec3(pow(clamp(d.y * (1.0 - (0.699999988079071044921875 * _3739)), 0.0, 1.0), 0.550000011920928955078125))), vec3(smoothstep((-0.0500000007450580596923828125) - _3770, 0.0500000007450580596923828125 + _3770, d.y))), ((fa_mesh_fs_params[11].xyz + fa_mesh_fs_params[12].xyz) * 0.5) * 0.800000011920928955078125, vec3(_3739 * 0.60000002384185791015625));\n        }\n        outc = base * _3710;\n    }\n    if (fa_mesh_fs_params[42].w > 0.0)\n    {\n        vec4 param_4 = fa_mesh_fs_params[42];\n        vec4 param_5 = fa_mesh_fs_params[43];\n        vec4 param_6 = fa_mesh_fs_params[44];\n        vec4 param_7 = fa_mesh_fs_params[45];\n        vec4 param_8 = fa_mesh_fs_params[46];\n        vec3 param_9 = d;\n        float param_10 = rough;\n        vec3 _3829 = fa_probe_environment(param_4, param_5, param_6, param_7, param_8, param_9, param_10);\n        outc += (_3829 * fa_mesh_fs_params[42].w);\n    }\n    if (fa_mesh_fs_params[47].w > 0.0)\n    {\n        vec4 param_11 = fa_mesh_fs_params[47];\n        vec4 param_12 = fa_mesh_fs_params[48];\n        vec4 param_13 = fa_mesh_fs_params[49];\n        vec4 param_14 = fa_mesh_fs_params[50];\n        vec4 param_15 = fa_mesh_fs_params[51];\n        vec3 param_16 = d;\n        float param_17 = rough;\n        vec3 _3861 = fa_probe_environment(param_11, param_12, param_13, param_14, param_15, param_16, param_17);\n        outc += (_3861 * fa_mesh_fs_params[47].w);\n    }\n    return outc;\n}\n\nvec3 fa_layers_ibl(FaLayers L, vec3 n, vec3 v, vec3 f0, float roughness)\n{\n    vec3 rn = n;\n    if (L.aniso != 0.0)\n    {\n        vec3 _4507;\n        if (L.aniso >= 0.0)\n        {\n            _4507 = L.b;\n        }\n        else\n        {\n            _4507 = L.t;\n        }\n        rn = normalize(mix(n, cross(cross(_4507, v), _4507), vec3(abs(L.aniso))));\n    }\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05);\n    vec2 _4540 = fa_env_brdf(param, param_1);\n    vec3 param_2 = reflect(-v, rn);\n    float param_3 = roughness;\n    vec3 result = (fa_environment(param_2, param_3) * ((f0 * _4540.x) + (vec3(L.f90) * _4540.y))) * L.base_scale;\n    if (L.sheen_on)\n    {\n        vec3 param_4 = n;\n        float param_5 = L.sheen_rough;\n        result += ((L.sheen * (L.sheen_e * L.keep)) * fa_environment(param_4, param_5));\n    }\n    if (L.coat > 0.0)\n    {\n        float param_6 = L.coat_rough;\n        float param_7 = L.coat_ndv;\n        vec2 _4595 = fa_env_brdf(param_6, param_7);\n        vec3 param_8 = reflect(-v, L.nc);\n        float param_9 = L.coat_rough;\n        result += (fa_environment(param_8, param_9) * (L.coat * ((0.039999999105930328369140625 * _4595.x) + _4595.y)));\n    }\n    return result;\n}\n\nvec3 fa_sky_reflection(vec3 n, vec3 v, vec3 f0, float roughness)\n{\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05);\n    vec2 _4072 = fa_env_brdf(param, param_1);\n    vec3 param_2 = reflect(-v, n);\n    float param_3 = roughness;\n    return fa_environment(param_2, param_3) * ((f0 * _4072.x) + vec3(_4072.y));\n}\n\nvec3 fa_sky_light(SurfaceInput i, Surface s)\n{\n    float _4624 = clamp(s.metallic, 0.0, 1.0);\n    float _4628 = clamp(s.roughness, 0.0500000007450580596923828125, 1.0);\n    vec3 _4635 = mix(vec3(0.039999999105930328369140625), s.albedo, vec3(_4624));\n    vec3 f0 = _4635;\n    vec3 _4639 = normalize(s.normal);\n    SurfaceInput param = i;\n    Surface param_1 = s;\n    vec3 param_2 = _4639;\n    vec3 param_3 = i.view_dir;\n    float param_4 = _4624;\n    float param_5 = _4628;\n    vec3 param_6 = _4635;\n    FaLayers _4656 = fa_layers_setup(param, param_1, param_2, param_3, param_4, param_5, param_6);\n    f0 = param_6;\n    if (_4656.on)\n    {\n        FaLayers param_7 = _4656;\n        vec3 param_8 = _4639;\n        vec3 param_9 = i.view_dir;\n        vec3 param_10 = f0;\n        float param_11 = _4628;\n        return fa_layers_ibl(param_7, param_8, param_9, param_10, param_11) * s.occlusion;\n    }\n    vec3 param_12 = _4639;\n    vec3 param_13 = i.view_dir;\n    vec3 param_14 = f0;\n    float param_15 = _4628;\n    return fa_sky_reflection(param_12, param_13, param_14, param_15) * s.occlusion;\n}\n\nvec3 ambient(SurfaceInput i, Surface s, vec3 ambientColor)\n{\n    SurfaceInput param = i;\n    Surface param_1 = s;\n    return fa_sky_light(param, param_1);\n}\n\nint fa_cluster_index(int slot, int n)\n{\n    int param = (int(fa_mesh_fs_params[19].x) + int(fa_mesh_fs_params[19].w)) + ((slot + n) >> 2);\n    vec4 t = fa_light_texel(param);\n    return int(t[(slot + n) & 3]);\n}\n\nint fa_cl_light(int n)\n{\n    if (n < fa_cl_ndir)\n    {\n        return n;\n    }\n    int param = fa_cl_slot;\n    int param_1 = n - fa_cl_ndir;\n    return fa_cluster_index(param, param_1);\n}\n\nint fa_light_base(int li)\n{\n    return li * ((fa_mesh_fs_params[1].w > 4.5) ? 8 : 4);\n}\n\nbool fa_light_baked(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 3;\n    return fa_light_texel(param_1).w > 0.5;\n}\n\nfloat fa_baked_keep(int li)\n{\n    float _4951;\n    if (fa_lm.z > 0.5)\n    {\n        _4951 = 0.0;\n    }\n    else\n    {\n        _4951 = 1.0 - clamp(fa_mesh_fs_params[32].w, 0.0, 1.0);\n    }\n    bool _4962 = _4951 < 1.0;\n    bool _4968;\n    if (_4962)\n    {\n        int param = li;\n        _4968 = fa_light_baked(param);\n    }\n    else\n    {\n        _4968 = _4962;\n    }\n    return _4968 ? _4951 : 1.0;\n}\n\nfloat fa_light_type(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 1;\n    return fa_light_texel(param_1).w;\n}\n\nvec3 fa_area_point(vec3 c, vec3 axis, vec3 ru, vec3 uu, float hx, float hy, float shape, vec3 p, vec3 r)\n{\n    bool _677 = dot(r, r) > 0.5;\n    if (shape > 1.5)\n    {\n        vec3 _690 = (c - (ru * hx)) - p;\n        vec3 _696 = ru * (2.0 * hx);\n        float _702 = max(dot(_696, _696), 9.9999999392252902907785028219223e-09);\n        float _706 = dot(_690, _696);\n        float t = clamp((-_706) / _702, 0.0, 1.0);\n        if (_677)\n        {\n            float _721 = dot(r, _696);\n            float _727 = _702 - (_721 * _721);\n            if (abs(_727) > (9.9999997473787516355514526367188e-06 * _702))\n            {\n                t = clamp(((dot(r, _690) * _721) - _706) / _727, 0.0, 1.0);\n            }\n        }\n        return (p + _690) + (_696 * t);\n    }\n    vec3 q = p;\n    float _759 = dot(r, axis);\n    bool _767;\n    if (_677)\n    {\n        _767 = abs(_759) > 9.9999997473787516355514526367188e-05;\n    }\n    else\n    {\n        _767 = _677;\n    }\n    if (_767)\n    {\n        float _777 = dot(c - p, axis) / _759;\n        if (_777 > 0.0)\n        {\n            q = p + (r * _777);\n        }\n    }\n    vec3 _790 = q - c;\n    vec2 xy = vec2(dot(_790, ru), dot(_790, uu));\n    if (shape > 0.5)\n    {\n        float _805 = length(xy);\n        if (_805 > hx)\n        {\n            xy *= (hx / _805);\n        }\n    }\n    else\n    {\n        xy = clamp(xy, vec2(-hx, -hy), vec2(hx, hy));\n    }\n    return (c + (ru * xy.x)) + (uu * xy.y);\n}\n\nvec4 fa_atlas_fetch(vec2 texel)\n{\n    return textureLod(fa_light_atlas_fa_env_smp, texel / vec2(textureSize(fa_light_atlas_fa_env_smp, 0)), 0.0);\n}\n\nvec3 fa_cookie_sample(vec2 tile_origin, vec2 uv)\n{\n    vec2 param = (tile_origin + vec2(1.0)) + (clamp(uv, vec2(0.0), vec2(1.0)) * 254.0);\n    return fa_atlas_fetch(param).xyz;\n}\n\nfloat fa_ies_sample(vec2 tile_origin, vec3 d, vec3 axis, vec3 right, vec3 up)\n{\n    float _597 = dot(d, right);\n    float _601 = dot(d, up);\n    float _612;\n    if (((_597 * _597) + (_601 * _601)) > 1.0000000133514319600180897396058e-10)\n    {\n        _612 = atan(_601, _597) * 0.15915493667125701904296875;\n    }\n    else\n    {\n        _612 = 0.0;\n    }\n    vec2 param = tile_origin + vec2(1.0 + ((_612 - floor(_612)) * 64.0), 1.0 + (acos(clamp(dot(d, axis), -1.0, 1.0)) * 10.18591594696044921875));\n    return fa_atlas_fetch(param).x;\n}\n\nint fa_cube_face(vec3 d)\n{\n    vec3 _447 = abs(d);\n    float _449 = _447.x;\n    float _451 = _447.y;\n    bool _452 = _449 >= _451;\n    bool _460;\n    if (_452)\n    {\n        _460 = _449 >= _447.z;\n    }\n    else\n    {\n        _460 = _452;\n    }\n    int _461;\n    if (_460)\n    {\n        _461 = (d.x > 0.0) ? 0 : 1;\n    }\n    else\n    {\n        int _476;\n        if (_451 >= _447.z)\n        {\n            _476 = (d.y > 0.0) ? 2 : 3;\n        }\n        else\n        {\n            _476 = (d.z > 0.0) ? 4 : 5;\n        }\n        _461 = _476;\n    }\n    return _461;\n}\n\nvoid fa_cube_face_basis(int f, out vec3 fwd, out vec3 up)\n{\n    if (f == 0)\n    {\n        fwd = vec3(1.0, 0.0, 0.0);\n        up = vec3(0.0, 1.0, 0.0);\n    }\n    else\n    {\n        if (f == 1)\n        {\n            fwd = vec3(-1.0, 0.0, 0.0);\n            up = vec3(0.0, 1.0, 0.0);\n        }\n        else\n        {\n            if (f == 2)\n            {\n                fwd = vec3(0.0, 1.0, 0.0);\n                up = vec3(0.0, 0.0, 1.0);\n            }\n            else\n            {\n                if (f == 3)\n                {\n                    fwd = vec3(0.0, -1.0, 0.0);\n                    up = vec3(0.0, 0.0, -1.0);\n                }\n                else\n                {\n                    if (f == 4)\n                    {\n                        fwd = vec3(0.0, 0.0, 1.0);\n                        up = vec3(0.0, 1.0, 0.0);\n                    }\n                    else\n                    {\n                        fwd = vec3(0.0, 0.0, -1.0);\n                        up = vec3(0.0, 1.0, 0.0);\n                    }\n                }\n            }\n        }\n    }\n}\n\nLightSample fa_light_sample_n(int li, vec3 world_pos, vec3 n)\n{\n    int param = li;\n    int _843 = fa_light_base(param);\n    bool _847 = fa_mesh_fs_params[1].w > 4.5;\n    int param_1 = _843;\n    vec4 _851 = fa_light_texel(param_1);\n    int param_2 = _843 + 1;\n    vec4 _856 = fa_light_texel(param_2);\n    float _859 = _856.w;\n    float atten = 1.0;\n    float dist = 0.0;\n    fa_light_tint = vec3(1.0);\n    bool _871 = _847 && (_859 > 2.5);\n    fa_light_is_area = _871;\n    bool _873 = _859 < 0.5;\n    vec3 l;\n    if (_873)\n    {\n        l = normalize(_851.xyz);\n        if (_847)\n        {\n            int param_3 = _843 + 6;\n            vec4 _887 = fa_light_texel(param_3);\n            if (_887.z > 0.5)\n            {\n                int param_4 = _843 + 4;\n                vec4 _897 = fa_light_texel(param_4);\n                int param_5 = _843 + 5;\n                vec4 _902 = fa_light_texel(param_5);\n                vec2 param_6 = _887.xy;\n                vec2 param_7 = fract(vec2(dot(world_pos, _897.xyz) * _897.w, (-dot(world_pos, _902.xyz)) * _902.w) + vec2(0.5));\n                fa_light_tint = fa_cookie_sample(param_6, param_7);\n            }\n        }\n    }\n    else\n    {\n        vec3 _932 = _851.xyz;\n        vec3 _934 = _932 - world_pos;\n        vec3 to_light = _934;\n        float _937 = length(_934);\n        float reach = _937;\n        bool front = true;\n        if (_871)\n        {\n            int param_8 = _843 + 7;\n            reach = max(_937 - fa_light_texel(param_8).w, 0.0);\n            int param_9 = _843 + 4;\n            vec4 _961 = fa_light_texel(param_9);\n            int param_10 = _843 + 5;\n            vec4 _966 = fa_light_texel(param_10);\n            int param_11 = _843 + 6;\n            vec4 _971 = fa_light_texel(param_11);\n            float _972 = _971.w;\n            int param_12 = _843 + 2;\n            vec3 _979 = normalize(fa_light_texel(param_12).xyz);\n            bool _981 = _972 > 1.5;\n            bool _989;\n            if (!_981)\n            {\n                _989 = dot(_979, to_light) < 0.0;\n            }\n            else\n            {\n                _989 = _981;\n            }\n            front = _989;\n            vec3 r = vec3(0.0);\n            vec3 _998 = fa_mesh_fs_params[0].xyz - world_pos;\n            bool _1002 = dot(n, n) > 0.5;\n            bool _1010;\n            if (_1002)\n            {\n                _1010 = dot(_998, _998) > 9.9999999600419720025001879548654e-13;\n            }\n            else\n            {\n                _1010 = _1002;\n            }\n            if (_1010)\n            {\n                r = reflect(-normalize(_998), normalize(n));\n            }\n            vec3 param_13 = _932;\n            vec3 param_14 = _979;\n            vec3 param_15 = _961.xyz;\n            vec3 param_16 = _966.xyz;\n            float param_17 = _961.w;\n            float param_18 = _966.w;\n            float param_19 = _972;\n            vec3 param_20 = world_pos;\n            vec3 param_21 = r;\n            to_light = fa_area_point(param_13, param_14, param_15, param_16, param_17, param_18, param_19, param_20, param_21) - world_pos;\n        }\n        float _1046 = length(to_light);\n        dist = _1046;\n        l = to_light / vec3(max(_1046, 9.9999997473787516355514526367188e-05));\n        float _1060 = reach / max(_851.w, 0.001000000047497451305389404296875);\n        float _1066 = clamp(1.0 - (_1060 * _1060), 0.0, 1.0);\n        float _1068;\n        if (front)\n        {\n            _1068 = _1066 * _1066;\n        }\n        else\n        {\n            _1068 = 0.0;\n        }\n        atten = _1068;\n        bool _1079 = _859 < 2.5;\n        if ((_859 > 1.5) && _1079)\n        {\n            int param_22 = _843 + 2;\n            vec4 _1087 = fa_light_texel(param_22);\n            float _1097 = _1087.w;\n            int param_23 = _843 + 3;\n            vec4 _1102 = fa_light_texel(param_23);\n            float _1103 = _1102.x;\n            float cos_inner = _1103;\n            if (_1103 > 1.5)\n            {\n                cos_inner = mix(_1097, 1.0, 0.25);\n            }\n            atten *= smoothstep(_1097, cos_inner, dot(-l, normalize(_1087.xyz)));\n        }\n        if (_847 && (_859 < 1.5))\n        {\n            int param_24 = _843 + 6;\n            vec4 _1127 = fa_light_texel(param_24);\n            if (_1127.z > 0.5)\n            {\n                vec3 _1135 = -to_light;\n                int param_25 = _843 + 4;\n                int param_26 = _843 + 5;\n                vec3 _1149 = fa_light_texel(param_25).xyz;\n                vec3 _1153 = fa_light_texel(param_26).xyz;\n                vec3 _1162 = vec3(dot(_1135, _1149), dot(_1135, _1153), dot(_1135, cross(_1149, _1153)));\n                vec3 param_27 = _1162;\n                int _1166 = fa_cube_face(param_27);\n                int param_28 = _1166;\n                vec3 param_29;\n                vec3 param_30;\n                fa_cube_face_basis(param_28, param_29, param_30);\n                vec2 _1193 = vec2(dot(_1162, cross(param_29, param_30)), dot(_1162, param_30)) / vec2(max(dot(_1162, param_29), 9.9999997473787516355514526367188e-05));\n                int _1197 = _1166 / 3;\n                vec2 param_31 = _1127.xy + (vec2(float(_1166 - (_1197 * 3)), float(_1197)) * 256.0);\n                vec2 param_32 = vec2(0.5 + (0.5 * _1193.x), 0.5 - (0.5 * _1193.y));\n                fa_light_tint = fa_cookie_sample(param_31, param_32);\n            }\n            int param_33 = _843 + 7;\n            vec4 _1227 = fa_light_texel(param_33);\n            if (_1227.z > 0.5)\n            {\n                int param_34 = _843 + 2;\n                int param_35 = _843 + 4;\n                int param_36 = _843 + 5;\n                vec2 param_37 = _1227.xy;\n                vec3 param_38 = -l;\n                vec3 param_39 = normalize(fa_light_texel(param_34).xyz);\n                vec3 param_40 = fa_light_texel(param_35).xyz;\n                vec3 param_41 = fa_light_texel(param_36).xyz;\n                atten *= fa_ies_sample(param_37, param_38, param_39, param_40, param_41);\n            }\n        }\n        else\n        {\n            if (_847 && _1079)\n            {\n                int param_42 = _843 + 6;\n                vec4 _1274 = fa_light_texel(param_42);\n                int param_43 = _843 + 7;\n                vec4 _1279 = fa_light_texel(param_43);\n                bool _1282 = _1274.z > 0.5;\n                bool _1289;\n                if (!_1282)\n                {\n                    _1289 = _1279.z > 0.5;\n                }\n                else\n                {\n                    _1289 = _1282;\n                }\n                if (_1289)\n                {\n                    int param_44 = _843 + 2;\n                    vec4 _1296 = fa_light_texel(param_44);\n                    vec3 _1300 = normalize(_1296.xyz);\n                    int param_45 = _843 + 4;\n                    vec4 _1305 = fa_light_texel(param_45);\n                    int param_46 = _843 + 5;\n                    vec4 _1310 = fa_light_texel(param_46);\n                    if (_1282)\n                    {\n                        vec3 _1318 = -to_light;\n                        float _1325 = _1296.w;\n                        float _1341 = 0.5 / max(dot(_1318, _1300) * (sqrt(max(1.0 - (_1325 * _1325), 0.0)) / max(_1325, 0.001000000047497451305389404296875)), 9.9999997473787516355514526367188e-05);\n                        vec2 param_47 = _1274.xy;\n                        vec2 param_48 = vec2(0.5 + (dot(_1318, _1305.xyz) * _1341), 0.5 - (dot(_1318, _1310.xyz) * _1341));\n                        fa_light_tint = fa_cookie_sample(param_47, param_48);\n                    }\n                    if (_1279.z > 0.5)\n                    {\n                        vec2 param_49 = _1279.xy;\n                        vec3 param_50 = -l;\n                        vec3 param_51 = _1300;\n                        vec3 param_52 = _1305.xyz;\n                        vec3 param_53 = _1310.xyz;\n                        atten *= fa_ies_sample(param_49, param_50, param_51, param_52, param_53);\n                    }\n                }\n            }\n        }\n    }\n    vec3 _6704 = _856.xyz * atten;\n    if (_847)\n    {\n        _6704 *= fa_light_tint;\n    }\n    int _1409;\n    if (_873)\n    {\n        _1409 = 0;\n    }\n    else\n    {\n        _1409 = ((_859 > 1.5) && (_859 < 2.5)) ? 2 : 1;\n    }\n    return LightSample(l, _6704, atten, 1.0, dist, _1409);\n}\n\nfloat fa_shadow_depth(inout vec2 uv, vec4 rect)\n{\n    uv = clamp(uv, rect.xy, rect.zw);\n    return textureLod(fa_shadow_tex_fa_shadow_smp, uv, 0.0).x;\n}\n\nfloat fa_shadow_fetch(vec2 uv, vec4 rect, vec3 conv)\n{\n    vec2 param = uv;\n    vec4 param_1 = rect;\n    float _2203 = fa_shadow_depth(param, param_1);\n    float _2207;\n    if (conv.x < 0.5)\n    {\n        _2207 = _2203;\n    }\n    else\n    {\n        _2207 = (conv.y * conv.z) / (conv.z - (_2203 * (conv.z - conv.y)));\n    }\n    return _2207;\n}\n\nfloat fa_shadow_noise()\n{\n    return fract(52.98291778564453125 * fract(dot(gl_FragCoord.xy, vec2(0.067110560834407806396484375, 0.005837149918079376220703125))));\n}\n\nvec2 fa_shadow_vogel(int k, int n, float phi)\n{\n    float _2134 = (float(k) * 2.3999631404876708984375) + phi;\n    return vec2(cos(_2134), sin(_2134)) * sqrt((float(k) + 0.5) / float(n));\n}\n\nfloat fa_shadow_filter(vec2 uv, vec4 rect, float zr, float texel_m, float unit, float reach, float plane, vec3 conv, int mode, float k)\n{\n    if (mode == 1)\n    {\n        vec2 param = uv;\n        vec4 param_1 = rect;\n        vec3 param_2 = conv;\n        return float(zr <= fa_shadow_fetch(param, param_1, param_2));\n    }\n    float _2253 = fa_shadow_noise() * 6.283185482025146484375;\n    float radius = 1.5;\n    if (mode == 2)\n    {\n        float _2262;\n        if (k < 0.0)\n        {\n            _2262 = (-k) / max(zr, 0.100000001490116119384765625);\n        }\n        else\n        {\n            _2262 = k;\n        }\n        float _2282 = clamp((_2262 * reach) / texel_m, 3.0, 12.0);\n        float sum = 0.0;\n        float cnt = 0.0;\n        for (int i = 0; i < 16; i++)\n        {\n            int param_3 = i;\n            int param_4 = 16;\n            float param_5 = _2253;\n            vec2 _2301 = fa_shadow_vogel(param_3, param_4, param_5) * _2282;\n            vec2 param_6 = uv + (_2301 * fa_shadows[26].zw);\n            vec4 param_7 = rect;\n            vec3 param_8 = conv;\n            float _2313 = fa_shadow_fetch(param_6, param_7, param_8);\n            if (_2313 < (zr - (length(_2301) * plane)))\n            {\n                sum += _2313;\n                cnt += 1.0;\n            }\n        }\n        if (cnt < 0.5)\n        {\n            return 1.0;\n        }\n        float _2339 = sum / cnt;\n        float _2349;\n        if (k < 0.0)\n        {\n            _2349 = (-k) / max(_2339, 0.0500000007450580596923828125);\n        }\n        else\n        {\n            _2349 = k;\n        }\n        radius = clamp(((max(zr - _2339, 0.0) * unit) * _2349) / texel_m, 1.5, 16.0);\n    }\n    float lit = 0.0;\n    int _2371 = (mode == 2) ? 24 : 16;\n    for (int i_1 = 0; i_1 < _2371; i_1++)\n    {\n        int param_9 = i_1;\n        int param_10 = _2371;\n        float param_11 = _2253;\n        vec2 _2390 = fa_shadow_vogel(param_9, param_10, param_11) * radius;\n        vec2 param_12 = uv + (_2390 * fa_shadows[26].zw);\n        vec4 param_13 = rect;\n        vec3 param_14 = conv;\n        lit += float((zr - (length(_2390) * plane)) <= fa_shadow_fetch(param_12, param_13, param_14));\n    }\n    return lit / float(_2371);\n}\n\nfloat fa_shadow_local(int li, vec3 lpos, vec3 world, vec3 n, vec3 l)\n{\n    bool _2590 = fa_mesh_fs_params[5].z < 0.5;\n    bool _2597;\n    if (!_2590)\n    {\n        _2597 = fa_shadows[29].x < 0.5;\n    }\n    else\n    {\n        _2597 = _2590;\n    }\n    if (_2597)\n    {\n        return 1.0;\n    }\n    int param = (int(fa_shadows[29].x + 0.5) - 1) + li;\n    vec4 _2610 = fa_light_texel(param);\n    float _2611 = _2610.x;\n    if (_2611 < 0.0)\n    {\n        return 1.0;\n    }\n    int _2620 = int(_2611 + 0.5);\n    int param_1 = _2620;\n    vec4 _2624 = fa_light_texel(param_1);\n    int param_2 = _2620 + 1;\n    vec4 _2629 = fa_light_texel(param_2);\n    float fade = 1.0;\n    float _2632 = _2624.y;\n    if (_2632 > 0.0)\n    {\n        float _2649 = 1.0 - smoothstep(0.75 * _2632, _2632, length(world - fa_shadows[27].xyz));\n        fade = _2649;\n        if (_2649 <= 0.0)\n        {\n            return 1.0;\n        }\n    }\n    int face = 0;\n    if (_2624.x > 1.5)\n    {\n        vec3 param_3 = world - lpos;\n        face = fa_cube_face(param_3);\n    }\n    int _2673 = (_2620 + 2) + (face * 6);\n    int param_4 = _2673;\n    int param_5 = _2673 + 1;\n    int param_6 = _2673 + 3;\n    vec4 _2687 = fa_light_texel(param_6);\n    int param_7 = _2673 + 4;\n    vec4 _2692 = fa_light_texel(param_7);\n    int param_8 = _2673 + 5;\n    vec4 _2697 = fa_light_texel(param_8);\n    float _2709 = _2697.x * max(dot(_2687, vec4(world, 1.0)), 0.001000000047497451305389404296875);\n    float _2714 = clamp(dot(n, l), 0.0, 1.0);\n    float _2737 = clamp(dot(n, _2687.xyz), -1.0, 1.0);\n    float _2756 = min(sqrt(1.0 - (_2737 * _2737)) / max(abs(dot(n, world - lpos)) / max(dot(_2687, vec4(world, 1.0)), 0.001000000047497451305389404296875), 0.20000000298023223876953125), 4.0);\n    float _2759 = _2629.y;\n    float _2761;\n    if (_2759 > 0.0)\n    {\n        _2761 = _2759;\n    }\n    else\n    {\n        _2761 = 1.5 * _2709;\n    }\n    vec4 _2781 = vec4(world + (n * (_2761 * sqrt(1.0 - (_2714 * _2714)))), 1.0);\n    float _2785 = dot(_2687, _2781);\n    float _2788 = _2697.y;\n    if (_2785 < _2788)\n    {\n        return 1.0;\n    }\n    vec2 _2803 = vec2(dot(fa_light_texel(param_4), _2781), dot(fa_light_texel(param_5), _2781)) / vec2(_2785);\n    float _2805 = _2803.x;\n    bool _2808 = _2805 < _2692.x;\n    bool _2817;\n    if (!_2808)\n    {\n        _2817 = _2805 > _2692.z;\n    }\n    else\n    {\n        _2817 = _2808;\n    }\n    bool _2826;\n    if (!_2817)\n    {\n        _2826 = _2803.y < _2692.y;\n    }\n    else\n    {\n        _2826 = _2817;\n    }\n    bool _2835;\n    if (!_2826)\n    {\n        _2835 = _2803.y > _2692.w;\n    }\n    else\n    {\n        _2835 = _2826;\n    }\n    if (_2835)\n    {\n        return 1.0;\n    }\n    float _2841 = _2629.x;\n    float _2843;\n    if (_2841 > 0.0)\n    {\n        _2843 = _2841;\n    }\n    else\n    {\n        _2843 = 1.5 * _2709;\n    }\n    vec2 param_9 = _2803;\n    vec4 param_10 = _2692;\n    float param_11 = _2785 - (_2843 * (1.0 + (0.5 * _2756)));\n    float param_12 = _2709;\n    float param_13 = 1.0;\n    float param_14 = _2697.z * 0.25;\n    float param_15 = (_2709 * min(_2756, 3.0)) * 0.5;\n    vec3 param_16 = vec3(1.0, _2788, _2697.z);\n    int param_17 = int(_2624.z + 0.5);\n    float param_18 = _2624.w;\n    return mix(1.0, fa_shadow_filter(param_9, param_10, param_11, param_12, param_13, param_14, param_15, param_16, param_17, param_18), fade);\n}\n\nfloat fa_shadow_split_at(int i)\n{\n    float _2146;\n    if (i == 0)\n    {\n        _2146 = fa_shadows[24].x;\n    }\n    else\n    {\n        float _2162;\n        if (i == 1)\n        {\n            _2162 = fa_shadows[24].y;\n        }\n        else\n        {\n            float _2170;\n            if (i == 2)\n            {\n                _2170 = fa_shadows[24].z;\n            }\n            else\n            {\n                _2170 = fa_shadows[24].w;\n            }\n            _2162 = _2170;\n        }\n        _2146 = _2162;\n    }\n    return _2146;\n}\n\nfloat fa_shadow_cascade(int ci, vec3 world, vec3 n, vec3 l)\n{\n    float _2432 = max(fa_shadows[ci * 1 + 20].y, 0.001000000047497451305389404296875);\n    float _2437 = clamp(dot(n, l), 0.0, 1.0);\n    float _2443 = sqrt(1.0 - (_2437 * _2437));\n    float _2450 = min(_2443 / max(_2437, 0.20000000298023223876953125), 4.0);\n    float _2455;\n    if (fa_shadows[26].y > 0.0)\n    {\n        _2455 = fa_shadows[26].y;\n    }\n    else\n    {\n        _2455 = 1.5 * fa_shadows[ci * 1 + 20].x;\n    }\n    vec4 _2480 = mat4(fa_shadows[ci * 4 + 0], fa_shadows[ci * 4 + 1], fa_shadows[ci * 4 + 2], fa_shadows[ci * 4 + 3]) * vec4(world + (n * (_2455 * _2443)), 1.0);\n    float _2487 = _2480.x;\n    bool _2490 = _2487 < fa_shadows[ci * 1 + 16].x;\n    bool _2499;\n    if (!_2490)\n    {\n        _2499 = _2487 > fa_shadows[ci * 1 + 16].z;\n    }\n    else\n    {\n        _2499 = _2490;\n    }\n    bool _2508;\n    if (!_2499)\n    {\n        _2508 = _2480.y < fa_shadows[ci * 1 + 16].y;\n    }\n    else\n    {\n        _2508 = _2499;\n    }\n    bool _2517;\n    if (!_2508)\n    {\n        _2517 = _2480.y > fa_shadows[ci * 1 + 16].w;\n    }\n    else\n    {\n        _2517 = _2508;\n    }\n    bool _2524;\n    if (!_2517)\n    {\n        _2524 = _2480.z > 1.0;\n    }\n    else\n    {\n        _2524 = _2517;\n    }\n    if (_2524)\n    {\n        return -1.0;\n    }\n    float _2532;\n    if (fa_shadows[26].x > 0.0)\n    {\n        _2532 = fa_shadows[26].x;\n    }\n    else\n    {\n        _2532 = 1.5 * fa_shadows[ci * 1 + 20].x;\n    }\n    vec2 param = _2480.xy;\n    vec4 param_1 = fa_shadows[ci * 1 + 16];\n    float param_2 = _2480.z - ((_2532 * (1.0 + (0.5 * _2450))) / _2432);\n    float param_3 = fa_shadows[ci * 1 + 20].x;\n    float param_4 = _2432;\n    float param_5 = _2432 * 0.25;\n    float param_6 = ((fa_shadows[ci * 1 + 20].x * min(_2450, 3.0)) * 0.5) / _2432;\n    vec3 param_7 = vec3(0.0);\n    int param_8 = int(fa_shadows[25].z + 0.5);\n    float param_9 = fa_shadows[25].w;\n    return fa_shadow_filter(param, param_1, param_2, param_3, param_4, param_5, param_6, param_7, param_8, param_9);\n}\n\nfloat fa_shadow_sun(vec3 world, vec3 n, vec3 l)\n{\n    if (fa_mesh_fs_params[5].z < 0.5)\n    {\n        return 1.0;\n    }\n    int _2910 = int(fa_shadows[25].x + 0.5);\n    if (_2910 < 1)\n    {\n        return 1.0;\n    }\n    float _2925 = dot(world - fa_shadows[27].xyz, fa_shadows[28].xyz);\n    int param = _2910 - 1;\n    if (_2925 > fa_shadow_split_at(param))\n    {\n        return 1.0;\n    }\n    int ci = 0;\n    bool _2937 = _2910 > 1;\n    bool _2944;\n    if (_2937)\n    {\n        _2944 = _2925 > fa_shadows[24].x;\n    }\n    else\n    {\n        _2944 = _2937;\n    }\n    if (_2944)\n    {\n        ci = 1;\n    }\n    bool _2948 = _2910 > 2;\n    bool _2955;\n    if (_2948)\n    {\n        _2955 = _2925 > fa_shadows[24].y;\n    }\n    else\n    {\n        _2955 = _2948;\n    }\n    if (_2955)\n    {\n        ci = 2;\n    }\n    bool _2959 = _2910 > 3;\n    bool _2966;\n    if (_2959)\n    {\n        _2966 = _2925 > fa_shadows[24].z;\n    }\n    else\n    {\n        _2966 = _2959;\n    }\n    if (_2966)\n    {\n        ci = 3;\n    }\n    float s = -1.0;\n    for (int k = 0; k < 4; k++)\n    {\n        if (ci >= _2910)\n        {\n            break;\n        }\n        int param_1 = ci;\n        vec3 param_2 = world;\n        vec3 param_3 = n;\n        vec3 param_4 = l;\n        float _2992 = fa_shadow_cascade(param_1, param_2, param_3, param_4);\n        s = _2992;\n        if (_2992 >= 0.0)\n        {\n            break;\n        }\n        ci++;\n    }\n    if (s < 0.0)\n    {\n        return 1.0;\n    }\n    if (fa_shadows[25].y > 0.0)\n    {\n        float _3017;\n        if (ci > 0)\n        {\n            int param_5 = ci - 1;\n            _3017 = fa_shadow_split_at(param_5);\n        }\n        else\n        {\n            _3017 = fa_shadows[28].w;\n        }\n        int param_6 = ci;\n        float _3036 = fa_shadows[25].y * max(fa_shadow_split_at(param_6) - _3017, 9.9999997473787516355514526367188e-05);\n        int param_7 = ci;\n        float _3047 = clamp((_2925 - (fa_shadow_split_at(param_7) - _3036)) / _3036, 0.0, 1.0);\n        if (_3047 > 0.0)\n        {\n            float s2 = 1.0;\n            if ((ci + 1) < _2910)\n            {\n                int param_8 = ci + 1;\n                vec3 param_9 = world;\n                vec3 param_10 = n;\n                vec3 param_11 = l;\n                float _3068 = fa_shadow_cascade(param_8, param_9, param_10, param_11);\n                s2 = _3068;\n                if (_3068 < 0.0)\n                {\n                    s2 = s;\n                }\n            }\n            s = mix(s, s2, _3047);\n        }\n    }\n    return s;\n}\n\nfloat fa_shadow_factor(vec3 n, vec3 l)\n{\n    vec3 param = fa_world_pos;\n    vec3 param_1 = n;\n    vec3 param_2 = l;\n    return fa_shadow_sun(param, param_1, param_2);\n}\n\nfloat fa_contact_shadow(int li, vec3 world, vec3 gn, vec3 l, float dist)\n{\n    bool _4695 = fa_mesh_fs_params[24].x < 0.5;\n    bool _4702;\n    if (!_4695)\n    {\n        _4702 = fa_shadows[29].x < 0.5;\n    }\n    else\n    {\n        _4702 = _4695;\n    }\n    if (_4702)\n    {\n        return 1.0;\n    }\n    int param = (int(fa_shadows[29].x + 0.5) - 1) + li;\n    vec4 _4715 = fa_light_texel(param);\n    float _4716 = _4715.y;\n    float len = _4716;\n    if (_4716 <= 0.0)\n    {\n        return 1.0;\n    }\n    float _4728 = length(world - fa_mesh_fs_params[0].xyz);\n    float _4738 = 1.0 - smoothstep(0.5 * fa_mesh_fs_params[25].x, fa_mesh_fs_params[25].x, _4728);\n    if (_4738 <= 0.0)\n    {\n        return 1.0;\n    }\n    float _4744 = len;\n    float _4747 = min(_4744, 0.89999997615814208984375 * dist);\n    len = _4747;\n    float _4752 = 0.004999999888241291046142578125 + (0.0030000000260770320892333984375 * _4728);\n    float _4757 = _4752 + (0.5 * _4747);\n    vec3 _4763 = world + (gn * _4752);\n    float _4765 = fa_shadow_noise();\n    float occ = 0.0;\n    float _4829;\n    for (int k = 0; k < 12; k++)\n    {\n        float _4780 = (float(k) + _4765) * 0.083333335816860198974609375;\n        vec3 _4788 = _4763 + (l * (_4780 * len));\n        vec4 _4794 = vec4(_4788, 1.0);\n        float _4800 = dot(fa_mesh_fs_params[28], _4794);\n        if (_4800 < 9.9999997473787516355514526367188e-05)\n        {\n            break;\n        }\n        vec2 _4820 = vec2(dot(fa_mesh_fs_params[26], _4794), dot(fa_mesh_fs_params[27], _4794)) / vec2(_4800);\n        float _4824 = _4820.x * 0.5;\n        float _4825 = _4824 + 0.5;\n        if (fa_mesh_fs_params[24].y > 0.5)\n        {\n            _4829 = (_4820.y * 0.5) + 0.5;\n        }\n        else\n        {\n            _4829 = 0.5 - (_4820.y * 0.5);\n        }\n        bool _4845 = _4825 < 0.0;\n        bool _4852;\n        if (!_4845)\n        {\n            _4852 = _4825 >= 1.0;\n        }\n        else\n        {\n            _4852 = _4845;\n        }\n        bool _4859;\n        if (!_4852)\n        {\n            _4859 = _4829 < 0.0;\n        }\n        else\n        {\n            _4859 = _4852;\n        }\n        bool _4866;\n        if (!_4859)\n        {\n            _4866 = _4829 >= 1.0;\n        }\n        else\n        {\n            _4866 = _4859;\n        }\n        if (_4866)\n        {\n            break;\n        }\n        vec4 _4885 = texelFetch(fa_screen_tex_fa_shadow_smp, ivec2(vec2(_4825, _4829) * fa_mesh_fs_params[24].zw), 0);\n        if (_4885.w < 0.5)\n        {\n            continue;\n        }\n        float _4904 = (dot(fa_mesh_fs_params[29].xyz, _4788) + fa_mesh_fs_params[29].w) - _4885.x;\n        if ((_4904 > _4752) && (_4904 < _4757))\n        {\n            occ = max(occ, (1.0 - (_4780 * _4780)) * smoothstep(0.0, 0.0500000007450580596923828125, min(min(_4825, 0.5 - _4824), min(_4829, 1.0 - _4829))));\n        }\n    }\n    return 1.0 - (occ * _4738);\n}\n\nLightSample fa_light_shadowed(int li, vec3 world_pos, vec3 gn)\n{\n    int param = li;\n    float _5007 = fa_baked_keep(param);\n    if (_5007 <= 0.0)\n    {\n        int param_1 = li;\n        return LightSample(vec3(0.0, 1.0, 0.0), vec3(0.0), 0.0, 1.0, 0.0, int(fa_light_type(param_1) + 0.5));\n    }\n    int param_2 = li;\n    vec3 param_3 = world_pos;\n    vec3 param_4 = gn;\n    LightSample _5033 = fa_light_sample_n(param_2, param_3, param_4);\n    vec3 _6837 = _5033.color;\n    float _6838 = _5033.attenuation;\n    float _6839 = _5033.shadow;\n    bool _5036 = _5033.type == 0;\n    if (_5036 && (li == 0))\n    {\n        vec3 param_5 = gn;\n        vec3 param_6 = _5033.direction;\n        float _5047 = fa_shadow_factor(param_5, param_6);\n        _6839 = _5047;\n        _6837 *= _5047;\n    }\n    else\n    {\n        bool _5058 = _5033.type != 0;\n        bool _5064;\n        if (_5058)\n        {\n            _5064 = _6838 > 0.0;\n        }\n        else\n        {\n            _5064 = _5058;\n        }\n        if (_5064)\n        {\n            int param_7 = li;\n            int param_8 = fa_light_base(param_7);\n            int param_9 = li;\n            vec3 param_10 = fa_light_texel(param_8).xyz;\n            vec3 param_11 = world_pos;\n            vec3 param_12 = gn;\n            vec3 param_13 = _5033.direction;\n            float _5083 = fa_shadow_local(param_9, param_10, param_11, param_12, param_13);\n            _6839 = _5083;\n            _6837 *= _5083;\n        }\n    }\n    bool _5093 = fa_mesh_fs_params[24].x > 0.5;\n    bool _5099;\n    if (_5093)\n    {\n        _5099 = _6838 > 0.0;\n    }\n    else\n    {\n        _5099 = _5093;\n    }\n    if (_5099)\n    {\n        float _5106;\n        if (_5036)\n        {\n            _5106 = 1000000000.0;\n        }\n        else\n        {\n            _5106 = _5033._distance;\n        }\n        int param_14 = li;\n        vec3 param_15 = world_pos;\n        vec3 param_16 = gn;\n        vec3 param_17 = _5033.direction;\n        float param_18 = _5106;\n        float _5124 = fa_contact_shadow(param_14, param_15, param_16, param_17, param_18);\n        _6839 *= _5124;\n        _6837 *= _5124;\n    }\n    float _5137 = _6838;\n    float _5138 = _5137 * _5007;\n    _6838 = _5138;\n    vec3 _5142 = _6837;\n    vec3 _5143 = _5142 * _5007;\n    _6837 = _5143;\n    return LightSample(_5033.direction, _5143, _5138, _6839, _5033._distance, _5033.type);\n}\n\nvec3 light(SurfaceInput i, Surface s, LightSample l)\n{\n    return vec3(0.0);\n}\n\nvec3 fa_shadow_debug(vec3 color, vec3 world)\n{\n    if (fa_shadows[27].w < 0.5)\n    {\n        return color;\n    }\n    int _3092 = int(fa_shadows[25].x + 0.5);\n    float _3102 = dot(world - fa_shadows[27].xyz, fa_shadows[28].xyz);\n    vec3 tint = vec3(0.3499999940395355224609375);\n    bool _3107 = _3092 > 0;\n    bool _3116;\n    if (_3107)\n    {\n        int param = _3092 - 1;\n        _3116 = _3102 <= fa_shadow_split_at(param);\n    }\n    else\n    {\n        _3116 = _3107;\n    }\n    if (_3116)\n    {\n        tint = vec3(1.0, 0.1500000059604644775390625, 0.100000001490116119384765625);\n        bool _3122 = _3092 > 1;\n        bool _3129;\n        if (_3122)\n        {\n            _3129 = _3102 > fa_shadows[24].x;\n        }\n        else\n        {\n            _3129 = _3122;\n        }\n        if (_3129)\n        {\n            tint = vec3(0.100000001490116119384765625, 0.89999997615814208984375, 0.20000000298023223876953125);\n        }\n        bool _3135 = _3092 > 2;\n        bool _3142;\n        if (_3135)\n        {\n            _3142 = _3102 > fa_shadows[24].y;\n        }\n        else\n        {\n            _3142 = _3135;\n        }\n        if (_3142)\n        {\n            tint = vec3(0.1500000059604644775390625, 0.300000011920928955078125, 1.0);\n        }\n        bool _3148 = _3092 > 3;\n        bool _3155;\n        if (_3148)\n        {\n            _3155 = _3102 > fa_shadows[24].z;\n        }\n        else\n        {\n            _3155 = _3148;\n        }\n        if (_3155)\n        {\n            tint = vec3(1.0, 0.89999997615814208984375, 0.100000001490116119384765625);\n        }\n    }\n    return mix(color, tint, vec3(0.550000011920928955078125));\n}\n\nvoid main()\n{\n    fa_inst_load();\n    vec3 _6522 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _6522 = -_6522;\n    }\n    vec3 _6146 = normalize(fa_mesh_fs_params[0].xyz - fa_world_pos);\n    vec3 param = fa_world_pos;\n    fa_cluster_begin(param);\n    SurfaceInput param_1 = SurfaceInput(fa_world_pos, _6522, fa_world_tangent, fa_uv, fa_vertex_color, _6146, gl_FrontFacing);\n    Surface _6154 = fa_standard_surface(param_1);\n    vec3 _6561 = _6154.albedo;\n    float _6562 = _6154.alpha;\n    vec3 _6563 = _6154.normal;\n    float _6564 = _6154.metallic;\n    float _6565 = _6154.roughness;\n    float _6566 = _6154.occlusion;\n    vec3 _6567 = _6154.emission;\n    float _6568 = _6154.clearcoat;\n    float _6569 = _6154.clearcoat_roughness;\n    vec3 _6570 = _6154.sheen_color;\n    float _6571 = _6154.sheen_roughness;\n    float _6572 = _6154.anisotropy;\n    float _6573 = _6154.anisotropy_rotation;\n    float _6574 = _6154.specular;\n    float _6575 = _6154.ior;\n    vec3 _6576 = _6154.specular_color;\n    float _6577 = _6154.transmission;\n    float _6578 = _6154.thickness;\n    vec3 _6579 = _6154.attenuation_color;\n    float _6580 = _6154.attenuation_distance;\n    SurfaceInput param_2 = SurfaceInput(fa_world_pos, _6522, fa_world_tangent, fa_uv, fa_vertex_color, _6146, gl_FrontFacing);\n    Surface param_3 = _6154;\n    surface(param_2, param_3);\n    _6561 = param_3.albedo;\n    _6562 = param_3.alpha;\n    _6563 = param_3.normal;\n    _6564 = param_3.metallic;\n    _6565 = param_3.roughness;\n    _6566 = param_3.occlusion;\n    _6567 = param_3.emission;\n    _6568 = param_3.clearcoat;\n    _6569 = param_3.clearcoat_roughness;\n    _6570 = param_3.sheen_color;\n    _6571 = param_3.sheen_roughness;\n    _6572 = param_3.anisotropy;\n    _6573 = param_3.anisotropy_rotation;\n    _6574 = param_3.specular;\n    _6575 = param_3.ior;\n    _6576 = param_3.specular_color;\n    _6577 = param_3.transmission;\n    _6578 = param_3.thickness;\n    _6579 = param_3.attenuation_color;\n    _6580 = param_3.attenuation_distance;\n    vec3 param_4 = fa_world_pos;\n    vec3 param_5 = _6522;\n    vec3 param_6 = param_3.albedo;\n    vec3 param_7 = param_3.normal;\n    fa_apply_decals(param_4, param_5, param_6, param_7);\n    _6561 = param_6;\n    _6563 = param_7;\n    vec3 result;\n    if (fa_mesh_fs_params[3].w > 0.5)\n    {\n        result = _6561;\n    }\n    else\n    {\n        vec3 _6193 = _6563;\n        vec3 _6194 = normalize(_6193);\n        _6563 = _6194;\n        vec3 param_8 = _6194;\n        SurfaceInput param_9 = SurfaceInput(fa_world_pos, _6522, fa_world_tangent, fa_uv, fa_vertex_color, _6146, gl_FrontFacing);\n        Surface param_10 = Surface(_6561, _6562, _6563, _6564, _6565, _6566, _6567, _6568, _6569, _6570, _6571, _6572, _6573, _6574, _6575, _6576, _6577, _6578, _6579, _6580);\n        vec3 param_11 = fa_indirect_diffuse(param_8);\n        vec3 lit = ambient(param_9, param_10, param_11);\n        int _6213 = fa_cl_ndir + fa_cl_local;\n        for (int ln = 0; ln < _6213; ln++)\n        {\n            int param_12 = ln;\n            int _6226 = fa_cl_light(param_12);\n            int param_13 = _6226;\n            if (fa_baked_keep(param_13) <= 0.0)\n            {\n                continue;\n            }\n            int param_14 = _6226;\n            vec3 param_15 = fa_world_pos;\n            vec3 param_16 = _6522;\n            LightSample _6242 = fa_light_shadowed(param_14, param_15, param_16);\n            SurfaceInput param_17 = SurfaceInput(fa_world_pos, _6522, fa_world_tangent, fa_uv, fa_vertex_color, _6146, gl_FrontFacing);\n            Surface param_18 = Surface(_6561, _6562, _6563, _6564, _6565, _6566, _6567, _6568, _6569, _6570, _6571, _6572, _6573, _6574, _6575, _6576, _6577, _6578, _6579, _6580);\n            LightSample param_19 = _6242;\n            lit += light(param_17, param_18, param_19);\n        }\n        result = lit;\n    }\n    vec3 _6257 = result;\n    vec3 _6258 = _6257 + _6567;\n    result = _6258;\n    vec3 param_20 = _6258;\n    vec3 param_21 = fa_world_pos;\n    result = fa_shadow_debug(param_20, param_21);\n    bool _6267 = fa_mesh_fs_params[7].w > 0.0;\n    bool _6274;\n    if (!_6267)\n    {\n        _6274 = fa_mesh_fs_params[8].y > 0.0;\n    }\n    else\n    {\n        _6274 = _6267;\n    }\n    if (_6274)\n    {\n        vec3 _6283 = fa_world_pos - fa_mesh_fs_params[0].xyz;\n        float _6289 = dot(_6283, fa_mesh_fs_params[9].xyz);\n        bool _6293 = fa_mesh_fs_params[9].w > 0.5;\n        float _6294;\n        if (_6293)\n        {\n            _6294 = _6289;\n        }\n        else\n        {\n            _6294 = length(_6283);\n        }\n        float _6306 = _6294 - fa_mesh_fs_params[8].x;\n        if (_6306 > 0.0)\n        {\n            float _6315 = fa_mesh_fs_params[7].w * _6306;\n            float tau = _6315 * _6315;\n            if (fa_mesh_fs_params[8].y > 0.0)\n            {\n                float _6331;\n                if (_6293)\n                {\n                    _6331 = fa_world_pos.y - (fa_mesh_fs_params[9].y * _6289);\n                }\n                else\n                {\n                    _6331 = fa_mesh_fs_params[0].y;\n                }\n                float _6352 = mix(_6331, fa_world_pos.y, clamp(fa_mesh_fs_params[8].x / _6294, 0.0, 1.0));\n                float _6356 = fa_world_pos.y - _6352;\n                float _6361 = _6352 - fa_mesh_fs_params[8].z;\n                float _6366 = fa_world_pos.y - fa_mesh_fs_params[8].z;\n                bool _6369 = _6361 <= 0.0;\n                bool _6370 = !_6369;\n                bool _6376;\n                if (_6370)\n                {\n                    _6376 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _6376 = _6369;\n                }\n                float _6377;\n                if (_6376)\n                {\n                    _6377 = fa_mesh_fs_params[8].y;\n                }\n                else\n                {\n                    _6377 = fa_mesh_fs_params[8].y * exp(-min(fa_mesh_fs_params[8].w * _6361, 80.0));\n                }\n                bool _6404;\n                if (_6370)\n                {\n                    _6404 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _6404 = _6369;\n                }\n                float _6405;\n                if (_6404)\n                {\n                    _6405 = fa_mesh_fs_params[8].y * _6361;\n                }\n                else\n                {\n                    _6405 = (fa_mesh_fs_params[8].y * (1.0 - exp(-min(fa_mesh_fs_params[8].w * _6361, 80.0)))) / fa_mesh_fs_params[8].w;\n                }\n                bool _6430 = _6366 <= 0.0;\n                bool _6437;\n                if (!_6430)\n                {\n                    _6437 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _6437 = _6430;\n                }\n                float _6438;\n                if (_6437)\n                {\n                    _6438 = fa_mesh_fs_params[8].y * _6366;\n                }\n                else\n                {\n                    _6438 = (fa_mesh_fs_params[8].y * (1.0 - exp(-min(fa_mesh_fs_params[8].w * _6366, 80.0)))) / fa_mesh_fs_params[8].w;\n                }\n                float _6465;\n                if (abs(_6356) < 0.001000000047497451305389404296875)\n                {\n                    _6465 = _6377;\n                }\n                else\n                {\n                    _6465 = (_6438 - _6405) / _6356;\n                }\n                tau += (_6306 * max(_6465, 0.0));\n            }\n            result = mix(result, fa_mesh_fs_params[7].xyz, vec3(clamp(1.0 - exp(-clamp(tau, 0.0, 80.0)), 0.0, 1.0)));\n        }\n    }\n    fa_frag_color = vec4(result, _6562);\n}\n\n",
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
            "inst_name": "_499",
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
            "inst_name": "_2156",
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
      "vs": "#version 430\n\nstruct VertexData\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 color;\n    vec3 object_pos;\n};\n\nuniform vec4 fa_mesh_vs_params[11];\nlayout(location = 0) out vec3 fa_world_pos;\nlayout(location = 1) out vec3 fa_world_normal;\nlayout(location = 2) out vec4 fa_world_tangent;\nlayout(location = 3) out vec2 fa_uv;\nlayout(location = 4) out vec4 fa_vertex_color;\nlayout(location = 5) out float fa_pre_depth;\nlayout(location = 6) out vec3 fa_pre_r0;\nlayout(location = 7) out vec3 fa_pre_r1;\nlayout(location = 8) out vec3 fa_pre_r2;\nlayout(location = 5) in vec4 fa_inst_m0;\nlayout(location = 6) in vec4 fa_inst_m1;\nlayout(location = 7) in vec4 fa_inst_m2;\nlayout(location = 8) in vec4 fa_inst_m3;\nlayout(location = 0) in vec3 fa_position;\nlayout(location = 1) in vec3 fa_normal;\nlayout(location = 3) in vec4 fa_tangent;\nlayout(location = 2) in vec2 fa_texcoord0;\nlayout(location = 4) in vec4 fa_color;\n\nvoid fa_inst_begin()\n{\n}\n\nVertexData fa_vertex_data(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    vec3 _69 = cross(model[1].xyz, model[2].xyz);\n    float _75 = (dot(model[0].xyz, _69) < 0.0) ? (-1.0) : 1.0;\n    return VertexData((model * vec4(position, 1.0)).xyz, (((_69 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _75, vec4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _75), texcoord0 * fa_mesh_vs_params[8].xy, color, position);\n}\n\nvoid fa_prepass_vertex(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    mat4 param = model;\n    vec3 param_1 = position;\n    vec3 param_2 = normal;\n    vec4 param_3 = tangent;\n    vec2 param_4 = texcoord0;\n    vec4 param_5 = color;\n    VertexData _160 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    vec3 _299 = _160.world_pos;\n    mat4 _164 = mat4(fa_mesh_vs_params[4], fa_mesh_vs_params[5], fa_mesh_vs_params[6], fa_mesh_vs_params[7]);\n    vec4 _171 = vec4(_299, 1.0);\n    fa_world_pos = _299;\n    fa_world_normal = _160.world_normal;\n    fa_world_tangent = _160.world_tangent;\n    fa_uv = _160.uv;\n    fa_vertex_color = _160.color;\n    fa_pre_depth = -(_164 * _171).z;\n    fa_pre_r0 = vec3(_164[0].x, _164[1].x, _164[2].x);\n    fa_pre_r1 = vec3(_164[0].y, _164[1].y, _164[2].y);\n    fa_pre_r2 = vec3(_164[0].z, _164[1].z, _164[2].z);\n    gl_Position = mat4(fa_mesh_vs_params[0], fa_mesh_vs_params[1], fa_mesh_vs_params[2], fa_mesh_vs_params[3]) * _171;\n}\n\nvoid main()\n{\n    fa_inst_begin();\n    mat4 param = mat4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3);\n    vec3 param_1 = fa_position;\n    vec3 param_2 = fa_normal;\n    vec4 param_3 = fa_tangent;\n    vec2 param_4 = fa_texcoord0;\n    vec4 param_5 = fa_color;\n    fa_prepass_vertex(param, param_1, param_2, param_3, param_4, param_5);\n}\n\n",
      "fs": "#version 430\n\nstruct SurfaceInput\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 vertex_color;\n    vec3 view_dir;\n    bool front_facing;\n};\n\nstruct Surface\n{\n    vec3 albedo;\n    float alpha;\n    vec3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    vec3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    vec3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    vec3 specular_color;\n    float transmission;\n    float thickness;\n    vec3 attenuation_color;\n    float attenuation_distance;\n};\n\nuniform vec4 fa_mesh_fs_params[53];\nlayout(binding = 0) uniform sampler2D fa_tex_fa_smp;\nlayout(binding = 1) uniform sampler2D fa_normal_tex_fa_smp;\nlayout(binding = 2) uniform sampler2D fa_mr_tex_fa_smp;\nlayout(binding = 3) uniform sampler2D fa_occlusion_tex_fa_smp;\nlayout(binding = 4) uniform sampler2D fa_emissive_tex_fa_smp;\n\nlayout(location = 0) in vec3 fa_world_pos;\nlayout(location = 1) in vec3 fa_world_normal;\nlayout(location = 2) in vec4 fa_world_tangent;\nlayout(location = 3) in vec2 fa_uv;\nlayout(location = 4) in vec4 fa_vertex_color;\nlayout(location = 6) in vec3 fa_pre_r0;\nlayout(location = 7) in vec3 fa_pre_r1;\nlayout(location = 8) in vec3 fa_pre_r2;\nlayout(location = 0) out vec4 fa_frag_color;\nlayout(location = 5) in float fa_pre_depth;\n\nvoid fa_inst_load()\n{\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nvec3 fa_linear_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_tex_fix(inout vec3 c, float mode)\n{\n    if (mode > 1.5)\n    {\n        vec3 param = c;\n        vec3 _172 = fa_linear_to_srgb(param);\n        c = _172;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            vec3 param_1 = c;\n            vec3 _181 = fa_srgb_to_linear(param_1);\n            c = _181;\n        }\n    }\n    return c;\n}\n\nvec3 fa_tangent_normal(SurfaceInput i, vec3 m)\n{\n    vec3 _56;\n    if (i.front_facing)\n    {\n        _56 = i.world_normal;\n    }\n    else\n    {\n        _56 = -i.world_normal;\n    }\n    vec3 _81 = normalize(i.world_tangent.xyz - (_56 * dot(_56, i.world_tangent.xyz)));\n    vec3 _109 = normalize(((_81 * m.x) + ((cross(_56, _81) * i.world_tangent.w) * m.y)) + (_56 * m.z));\n    vec3 _112;\n    if (i.front_facing)\n    {\n        _112 = _109;\n    }\n    else\n    {\n        _112 = -_109;\n    }\n    return _112;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    vec4 base_t = texture(fa_tex_fa_smp, i.uv);\n    float param = fa_mesh_fs_params[6].w;\n    float param_1 = 1.0;\n    vec3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    vec3 _227 = fa_tex_fix(param_2, param_3);\n    vec4 _828 = base_t;\n    _828.x = _227.x;\n    _828.y = _227.y;\n    _828.z = _227.z;\n    base_t = _828;\n    vec4 _243 = (_828 * fa_mesh_fs_params[2]) * i.vertex_color;\n    vec3 _783 = i.world_normal;\n    if (fa_mesh_fs_params[6].z > 0.5)\n    {\n        float param_4 = fa_mesh_fs_params[6].w;\n        float param_5 = 16.0;\n        vec3 param_6 = texture(fa_normal_tex_fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        vec3 _277 = fa_tex_fix(param_6, param_7);\n        vec3 _281 = (_277 * 2.0) - vec3(1.0);\n        vec2 _286 = _281.xy * fa_mesh_fs_params[6].x;\n        vec3 _836 = _281;\n        _836.x = _286.x;\n        _836.y = _286.y;\n        SurfaceInput param_8 = i;\n        vec3 param_9 = _836;\n        _783 = fa_tangent_normal(param_8, param_9);\n    }\n    vec4 mrt = texture(fa_mr_tex_fa_smp, i.uv);\n    float param_10 = fa_mesh_fs_params[6].w;\n    float param_11 = 64.0;\n    vec3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    vec3 _315 = fa_tex_fix(param_12, param_13);\n    vec4 _839 = mrt;\n    _839.x = _315.x;\n    _839.y = _315.y;\n    _839.z = _315.z;\n    mrt = _839;\n    vec4 _345 = texture(fa_occlusion_tex_fa_smp, i.uv);\n    float param_14 = fa_mesh_fs_params[6].w;\n    float param_15 = 256.0;\n    vec3 param_16 = _345.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    vec3 _357 = fa_tex_fix(param_16, param_17);\n    float param_18 = fa_mesh_fs_params[6].w;\n    float param_19 = 4.0;\n    vec3 param_20 = texture(fa_emissive_tex_fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    vec3 _387 = fa_tex_fix(param_20, param_21);\n    float _788 = fa_mesh_fs_params[20].x;\n    float _789 = fa_mesh_fs_params[20].y;\n    float _792 = fa_mesh_fs_params[20].z;\n    float _791 = fa_mesh_fs_params[21].w;\n    float _794 = fa_mesh_fs_params[22].x;\n    if (fa_mesh_fs_params[22].z > 0.5)\n    {\n        if (mod(fa_mesh_fs_params[22].z, 2.0) > 0.5)\n        {\n            _788 *= _357.y;\n            _789 *= _357.z;\n            _791 *= _345.w;\n        }\n        if (fa_mesh_fs_params[22].z > 1.5)\n        {\n            _792 *= mrt.x;\n            _794 *= mrt.w;\n        }\n    }\n    return Surface(_243.xyz, _243.w, _783, clamp(fa_mesh_fs_params[5].x * _315.z, 0.0, 1.0), clamp(fa_mesh_fs_params[5].y * _315.y, 0.0500000007450580596923828125, 1.0), 1.0 + (fa_mesh_fs_params[6].y * (_357.x - 1.0)), fa_mesh_fs_params[3].xyz + (fa_mesh_fs_params[4].xyz * _387), _788, _789, fa_mesh_fs_params[21].xyz, _791, _792, fa_mesh_fs_params[20].w, _794, fa_mesh_fs_params[22].y, fa_mesh_fs_params[23].xyz, fa_mesh_fs_params[30].x, fa_mesh_fs_params[30].y, fa_mesh_fs_params[31].xyz, fa_mesh_fs_params[30].z);\n}\n\nvoid surface(SurfaceInput i, Surface s)\n{\n}\n\nvoid main()\n{\n    fa_inst_load();\n    vec3 _678 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _678 = -_678;\n    }\n    vec3 _540 = normalize(fa_mesh_fs_params[0].xyz - fa_world_pos);\n    SurfaceInput param = SurfaceInput(fa_world_pos, _678, fa_world_tangent, fa_uv, fa_vertex_color, _540, gl_FrontFacing);\n    SurfaceInput param_1 = SurfaceInput(fa_world_pos, _678, fa_world_tangent, fa_uv, fa_vertex_color, _540, gl_FrontFacing);\n    Surface param_2 = fa_standard_surface(param);\n    surface(param_1, param_2);\n    vec3 _555 = normalize(param_2.normal);\n    vec3 _570 = normalize(vec3(dot(fa_pre_r0, _555), dot(fa_pre_r1, _555), dot(fa_pre_r2, _555)));\n    float _582 = _570.z;\n    vec2 e = _570.xy / vec2((abs(_570.x) + abs(_570.y)) + abs(_582));\n    if (_582 < 0.0)\n    {\n        e = (vec2(1.0) - abs(e.yx)) * vec2((e.x >= 0.0) ? 1.0 : (-1.0), (e.y >= 0.0) ? 1.0 : (-1.0));\n    }\n    fa_frag_color = vec4(min(fa_pre_depth, 60000.0), e, 1.0);\n}\n\n",
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
            "inst_name": "_215",
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
      "vs": "#version 430\n\nstruct VertexData\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 color;\n    vec3 object_pos;\n};\n\nuniform vec4 fa_mesh_vs_params[11];\nuniform vec4 fa_skin[192];\nlayout(location = 0) out vec3 fa_world_pos;\nlayout(location = 1) out vec3 fa_world_normal;\nlayout(location = 2) out vec4 fa_world_tangent;\nlayout(location = 3) out vec2 fa_uv;\nlayout(location = 4) out vec4 fa_vertex_color;\nlayout(location = 5) out float fa_pre_depth;\nlayout(location = 6) out vec3 fa_pre_r0;\nlayout(location = 7) out vec3 fa_pre_r1;\nlayout(location = 8) out vec3 fa_pre_r2;\nlayout(location = 5) in vec4 fa_inst_m0;\nlayout(location = 6) in vec4 fa_inst_m1;\nlayout(location = 7) in vec4 fa_inst_m2;\nlayout(location = 8) in vec4 fa_inst_m3;\nlayout(location = 9) in vec4 fa_joints;\nlayout(location = 10) in vec4 fa_weights;\nlayout(location = 0) in vec3 fa_position;\nlayout(location = 1) in vec3 fa_normal;\nlayout(location = 3) in vec4 fa_tangent;\nlayout(location = 2) in vec2 fa_texcoord0;\nlayout(location = 4) in vec4 fa_color;\n\nvoid fa_inst_begin()\n{\n}\n\nmat4 fa_skin_matrix(vec4 joints, vec4 weights)\n{\n    vec4 r0 = vec4(0.0);\n    vec4 r1 = vec4(0.0);\n    vec4 r2 = vec4(0.0);\n    for (int i = 0; i < 4; i++)\n    {\n        int _174 = int((joints[i] * 255.0) + 0.5) * 3;\n        r0 += (fa_skin[_174 * 1 + 0] * weights[i]);\n        r1 += (fa_skin[(_174 + 1) * 1 + 0] * weights[i]);\n        r2 += (fa_skin[(_174 + 2) * 1 + 0] * weights[i]);\n    }\n    return mat4(vec4(r0.x, r1.x, r2.x, 0.0), vec4(r0.y, r1.y, r2.y, 0.0), vec4(r0.z, r1.z, r2.z, 0.0), vec4(r0.w, r1.w, r2.w, 1.0));\n}\n\nVertexData fa_vertex_data(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    vec3 _74 = cross(model[1].xyz, model[2].xyz);\n    float _80 = (dot(model[0].xyz, _74) < 0.0) ? (-1.0) : 1.0;\n    return VertexData((model * vec4(position, 1.0)).xyz, (((_74 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _80, vec4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _80), texcoord0 * fa_mesh_vs_params[8].xy, color, position);\n}\n\nvoid fa_prepass_vertex(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    mat4 param = model;\n    vec3 param_1 = position;\n    vec3 param_2 = normal;\n    vec4 param_3 = tangent;\n    vec2 param_4 = texcoord0;\n    vec4 param_5 = color;\n    VertexData _273 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    vec3 _420 = _273.world_pos;\n    mat4 _277 = mat4(fa_mesh_vs_params[4], fa_mesh_vs_params[5], fa_mesh_vs_params[6], fa_mesh_vs_params[7]);\n    vec4 _284 = vec4(_420, 1.0);\n    fa_world_pos = _420;\n    fa_world_normal = _273.world_normal;\n    fa_world_tangent = _273.world_tangent;\n    fa_uv = _273.uv;\n    fa_vertex_color = _273.color;\n    fa_pre_depth = -(_277 * _284).z;\n    fa_pre_r0 = vec3(_277[0].x, _277[1].x, _277[2].x);\n    fa_pre_r1 = vec3(_277[0].y, _277[1].y, _277[2].y);\n    fa_pre_r2 = vec3(_277[0].z, _277[1].z, _277[2].z);\n    gl_Position = mat4(fa_mesh_vs_params[0], fa_mesh_vs_params[1], fa_mesh_vs_params[2], fa_mesh_vs_params[3]) * _284;\n}\n\nvoid main()\n{\n    fa_inst_begin();\n    vec4 param = fa_joints;\n    vec4 param_1 = fa_weights;\n    mat4 param_2 = mat4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3) * fa_skin_matrix(param, param_1);\n    vec3 param_3 = fa_position;\n    vec3 param_4 = fa_normal;\n    vec4 param_5 = fa_tangent;\n    vec2 param_6 = fa_texcoord0;\n    vec4 param_7 = fa_color;\n    fa_prepass_vertex(param_2, param_3, param_4, param_5, param_6, param_7);\n}\n\n",
      "fs": "#version 430\n\nstruct SurfaceInput\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 vertex_color;\n    vec3 view_dir;\n    bool front_facing;\n};\n\nstruct Surface\n{\n    vec3 albedo;\n    float alpha;\n    vec3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    vec3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    vec3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    vec3 specular_color;\n    float transmission;\n    float thickness;\n    vec3 attenuation_color;\n    float attenuation_distance;\n};\n\nuniform vec4 fa_mesh_fs_params[53];\nlayout(binding = 0) uniform sampler2D fa_tex_fa_smp;\nlayout(binding = 1) uniform sampler2D fa_normal_tex_fa_smp;\nlayout(binding = 2) uniform sampler2D fa_mr_tex_fa_smp;\nlayout(binding = 3) uniform sampler2D fa_occlusion_tex_fa_smp;\nlayout(binding = 4) uniform sampler2D fa_emissive_tex_fa_smp;\n\nlayout(location = 0) in vec3 fa_world_pos;\nlayout(location = 1) in vec3 fa_world_normal;\nlayout(location = 2) in vec4 fa_world_tangent;\nlayout(location = 3) in vec2 fa_uv;\nlayout(location = 4) in vec4 fa_vertex_color;\nlayout(location = 6) in vec3 fa_pre_r0;\nlayout(location = 7) in vec3 fa_pre_r1;\nlayout(location = 8) in vec3 fa_pre_r2;\nlayout(location = 0) out vec4 fa_frag_color;\nlayout(location = 5) in float fa_pre_depth;\n\nvoid fa_inst_load()\n{\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nvec3 fa_linear_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_tex_fix(inout vec3 c, float mode)\n{\n    if (mode > 1.5)\n    {\n        vec3 param = c;\n        vec3 _172 = fa_linear_to_srgb(param);\n        c = _172;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            vec3 param_1 = c;\n            vec3 _181 = fa_srgb_to_linear(param_1);\n            c = _181;\n        }\n    }\n    return c;\n}\n\nvec3 fa_tangent_normal(SurfaceInput i, vec3 m)\n{\n    vec3 _56;\n    if (i.front_facing)\n    {\n        _56 = i.world_normal;\n    }\n    else\n    {\n        _56 = -i.world_normal;\n    }\n    vec3 _81 = normalize(i.world_tangent.xyz - (_56 * dot(_56, i.world_tangent.xyz)));\n    vec3 _109 = normalize(((_81 * m.x) + ((cross(_56, _81) * i.world_tangent.w) * m.y)) + (_56 * m.z));\n    vec3 _112;\n    if (i.front_facing)\n    {\n        _112 = _109;\n    }\n    else\n    {\n        _112 = -_109;\n    }\n    return _112;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    vec4 base_t = texture(fa_tex_fa_smp, i.uv);\n    float param = fa_mesh_fs_params[6].w;\n    float param_1 = 1.0;\n    vec3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    vec3 _227 = fa_tex_fix(param_2, param_3);\n    vec4 _828 = base_t;\n    _828.x = _227.x;\n    _828.y = _227.y;\n    _828.z = _227.z;\n    base_t = _828;\n    vec4 _243 = (_828 * fa_mesh_fs_params[2]) * i.vertex_color;\n    vec3 _783 = i.world_normal;\n    if (fa_mesh_fs_params[6].z > 0.5)\n    {\n        float param_4 = fa_mesh_fs_params[6].w;\n        float param_5 = 16.0;\n        vec3 param_6 = texture(fa_normal_tex_fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        vec3 _277 = fa_tex_fix(param_6, param_7);\n        vec3 _281 = (_277 * 2.0) - vec3(1.0);\n        vec2 _286 = _281.xy * fa_mesh_fs_params[6].x;\n        vec3 _836 = _281;\n        _836.x = _286.x;\n        _836.y = _286.y;\n        SurfaceInput param_8 = i;\n        vec3 param_9 = _836;\n        _783 = fa_tangent_normal(param_8, param_9);\n    }\n    vec4 mrt = texture(fa_mr_tex_fa_smp, i.uv);\n    float param_10 = fa_mesh_fs_params[6].w;\n    float param_11 = 64.0;\n    vec3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    vec3 _315 = fa_tex_fix(param_12, param_13);\n    vec4 _839 = mrt;\n    _839.x = _315.x;\n    _839.y = _315.y;\n    _839.z = _315.z;\n    mrt = _839;\n    vec4 _345 = texture(fa_occlusion_tex_fa_smp, i.uv);\n    float param_14 = fa_mesh_fs_params[6].w;\n    float param_15 = 256.0;\n    vec3 param_16 = _345.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    vec3 _357 = fa_tex_fix(param_16, param_17);\n    float param_18 = fa_mesh_fs_params[6].w;\n    float param_19 = 4.0;\n    vec3 param_20 = texture(fa_emissive_tex_fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    vec3 _387 = fa_tex_fix(param_20, param_21);\n    float _788 = fa_mesh_fs_params[20].x;\n    float _789 = fa_mesh_fs_params[20].y;\n    float _792 = fa_mesh_fs_params[20].z;\n    float _791 = fa_mesh_fs_params[21].w;\n    float _794 = fa_mesh_fs_params[22].x;\n    if (fa_mesh_fs_params[22].z > 0.5)\n    {\n        if (mod(fa_mesh_fs_params[22].z, 2.0) > 0.5)\n        {\n            _788 *= _357.y;\n            _789 *= _357.z;\n            _791 *= _345.w;\n        }\n        if (fa_mesh_fs_params[22].z > 1.5)\n        {\n            _792 *= mrt.x;\n            _794 *= mrt.w;\n        }\n    }\n    return Surface(_243.xyz, _243.w, _783, clamp(fa_mesh_fs_params[5].x * _315.z, 0.0, 1.0), clamp(fa_mesh_fs_params[5].y * _315.y, 0.0500000007450580596923828125, 1.0), 1.0 + (fa_mesh_fs_params[6].y * (_357.x - 1.0)), fa_mesh_fs_params[3].xyz + (fa_mesh_fs_params[4].xyz * _387), _788, _789, fa_mesh_fs_params[21].xyz, _791, _792, fa_mesh_fs_params[20].w, _794, fa_mesh_fs_params[22].y, fa_mesh_fs_params[23].xyz, fa_mesh_fs_params[30].x, fa_mesh_fs_params[30].y, fa_mesh_fs_params[31].xyz, fa_mesh_fs_params[30].z);\n}\n\nvoid surface(SurfaceInput i, Surface s)\n{\n}\n\nvoid main()\n{\n    fa_inst_load();\n    vec3 _678 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _678 = -_678;\n    }\n    vec3 _540 = normalize(fa_mesh_fs_params[0].xyz - fa_world_pos);\n    SurfaceInput param = SurfaceInput(fa_world_pos, _678, fa_world_tangent, fa_uv, fa_vertex_color, _540, gl_FrontFacing);\n    SurfaceInput param_1 = SurfaceInput(fa_world_pos, _678, fa_world_tangent, fa_uv, fa_vertex_color, _540, gl_FrontFacing);\n    Surface param_2 = fa_standard_surface(param);\n    surface(param_1, param_2);\n    vec3 _555 = normalize(param_2.normal);\n    vec3 _570 = normalize(vec3(dot(fa_pre_r0, _555), dot(fa_pre_r1, _555), dot(fa_pre_r2, _555)));\n    float _582 = _570.z;\n    vec2 e = _570.xy / vec2((abs(_570.x) + abs(_570.y)) + abs(_582));\n    if (_582 < 0.0)\n    {\n        e = (vec2(1.0) - abs(e.yx)) * vec2((e.x >= 0.0) ? 1.0 : (-1.0), (e.y >= 0.0) ? 1.0 : (-1.0));\n    }\n    fa_frag_color = vec4(min(fa_pre_depth, 60000.0), e, 1.0);\n}\n\n",
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
            "inst_name": "_215",
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
