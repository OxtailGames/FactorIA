{
  "format": "factoria.shader/1",
  "engine": "0.39.0",
  "template": "4694fb4be9bed2a7c5475af904870ae4995eb283e1c27e15e0192dfe0c2b2256",
  "slang": "glsl430",
  "params": [
    "alphaCutoff"
  ],
  "textures": [
    "mask"
  ],
  "programs": {
    "mesh": {
      "vs": "#version 430\n\nstruct VertexData\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 color;\n    vec3 object_pos;\n};\n\nuniform vec4 fa_mesh_vs_params[11];\nlayout(location = 0) out vec3 fa_world_pos;\nlayout(location = 1) out vec3 fa_world_normal;\nlayout(location = 2) out vec4 fa_world_tangent;\nlayout(location = 3) out vec2 fa_uv;\nlayout(location = 4) out vec4 fa_vertex_color;\nlayout(location = 5) in vec4 fa_inst_m0;\nlayout(location = 6) in vec4 fa_inst_m1;\nlayout(location = 7) in vec4 fa_inst_m2;\nlayout(location = 8) in vec4 fa_inst_m3;\nlayout(location = 0) in vec3 fa_position;\nlayout(location = 1) in vec3 fa_normal;\nlayout(location = 3) in vec4 fa_tangent;\nlayout(location = 2) in vec2 fa_texcoord0;\nlayout(location = 4) in vec4 fa_color;\nlayout(location = 5) out vec3 fa_lm;\n\nvoid fa_inst_begin()\n{\n}\n\nVertexData fa_vertex_data(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    vec3 _69 = cross(model[1].xyz, model[2].xyz);\n    float _75 = (dot(model[0].xyz, _69) < 0.0) ? (-1.0) : 1.0;\n    return VertexData((model * vec4(position, 1.0)).xyz, (((_69 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _75, vec4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _75), texcoord0 * fa_mesh_vs_params[8].xy, color, position);\n}\n\nvoid fa_shade_vertex(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    mat4 param = model;\n    vec3 param_1 = position;\n    vec3 param_2 = normal;\n    vec4 param_3 = tangent;\n    vec2 param_4 = texcoord0;\n    vec4 param_5 = color;\n    VertexData _160 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    vec3 _276 = _160.world_pos;\n    fa_world_pos = _276;\n    fa_world_normal = _160.world_normal;\n    fa_world_tangent = _160.world_tangent;\n    fa_uv = _160.uv;\n    fa_vertex_color = _160.color;\n    gl_Position = mat4(fa_mesh_vs_params[0], fa_mesh_vs_params[1], fa_mesh_vs_params[2], fa_mesh_vs_params[3]) * vec4(_276, 1.0);\n}\n\nvoid main()\n{\n    fa_inst_begin();\n    mat4 param = mat4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3);\n    vec3 param_1 = fa_position;\n    vec3 param_2 = fa_normal;\n    vec4 param_3 = fa_tangent;\n    vec2 param_4 = fa_texcoord0;\n    vec4 param_5 = fa_color;\n    fa_shade_vertex(param, param_1, param_2, param_3, param_4, param_5);\n    fa_lm = vec3(0.0);\n}\n\n",
      "fs": "#version 430\n\nstruct SurfaceInput\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 vertex_color;\n    vec3 view_dir;\n    bool front_facing;\n};\n\nstruct LightSample\n{\n    vec3 direction;\n    vec3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct Surface\n{\n    vec3 albedo;\n    float alpha;\n    vec3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    vec3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    vec3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    vec3 specular_color;\n    float transmission;\n    float thickness;\n    vec3 attenuation_color;\n    float attenuation_distance;\n};\n\nstruct FaLayers\n{\n    bool on;\n    float f90;\n    float keep;\n    float base_scale;\n    float coat;\n    float coat_rough;\n    float coat_alpha;\n    float coat_a2;\n    vec3 nc;\n    float coat_ndv;\n    bool sheen_on;\n    vec3 sheen;\n    float sheen_rough;\n    float sheen_alpha;\n    float sheen_scale;\n    float sheen_e;\n    float aniso;\n    vec3 t;\n    vec3 b;\n    float at;\n    float ab;\n};\n\nconst float _4970[63] = float[](1.0, 1.0, 1.0, 0.4790000021457672119140625, 0.11699999868869781494140625, 0.01200000010430812835693359375, 0.0, 0.0, 0.0, 1.0, 1.0, 1.0, 0.578000009059906005859375, 0.19300000369548797607421875, 0.0350000001490116119384765625, 0.0030000000260770320892333984375, 0.0, 0.0, 1.0, 1.0, 1.0, 0.6740000247955322265625, 0.3459999859333038330078125, 0.1319999992847442626953125, 0.032999999821186065673828125, 0.0040000001899898052215576171875, 0.0, 0.971000015735626220703125, 0.954999983310699462890625, 0.828999996185302734375, 0.63999998569488525390625, 0.42599999904632568359375, 0.24500000476837158203125, 0.115000002086162567138671875, 0.037000000476837158203125, 0.0030000000260770320892333984375, 0.7469999790191650390625, 0.737999975681304931640625, 0.670000016689300537109375, 0.563000023365020751953125, 0.4309999942779541015625, 0.3039999902248382568359375, 0.1940000057220458984375, 0.1019999980926513671875, 0.0309999994933605194091796875, 0.614000022411346435546875, 0.609000027179718017578125, 0.566999971866607666015625, 0.499000012874603271484375, 0.412000000476837158203125, 0.32400000095367431640625, 0.240999996662139892578125, 0.162000000476837158203125, 0.087999999523162841796875, 0.538999974727630615234375, 0.535000026226043701171875, 0.505999982357025146484375, 0.4569999873638153076171875, 0.393999993801116943359375, 0.328999996185302734375, 0.2660000026226043701171875, 0.203999996185302734375, 0.14200000464916229248046875);\n\nuniform vec4 fa_mesh_fs_params[54];\nuniform vec4 fa_shadows[30];\nuniform vec4 fa_material[1];\nlayout(binding = 0) uniform sampler2D fa_light_tex_fa_shadow_smp;\nlayout(binding = 1) uniform sampler2D fa_tex_fa_smp;\nlayout(binding = 2) uniform sampler2D fa_normal_tex_fa_smp;\nlayout(binding = 3) uniform sampler2D fa_mr_tex_fa_smp;\nlayout(binding = 4) uniform sampler2D fa_occlusion_tex_fa_smp;\nlayout(binding = 5) uniform sampler2D fa_emissive_tex_fa_smp;\nlayout(binding = 6) uniform sampler2D mask_mask_smp;\nlayout(binding = 7) uniform sampler2D fa_decal_tex_fa_env_smp;\nlayout(binding = 8) uniform sampler2D fa_lightmap_fa_env_smp;\nlayout(binding = 9) uniform sampler2D fa_probe_atlas_fa_env_smp;\nlayout(binding = 10) uniform sampler2D fa_light_atlas_fa_env_smp;\nlayout(binding = 11) uniform sampler2D fa_screen_tex_fa_shadow_smp;\nlayout(binding = 12) uniform sampler2D fa_shadow_tex_fa_shadow_smp;\n\nlayout(location = 0) in vec3 fa_world_pos;\nlayout(location = 5) in vec3 fa_lm;\nlayout(location = 1) in vec3 fa_world_normal;\nlayout(location = 2) in vec4 fa_world_tangent;\nlayout(location = 3) in vec2 fa_uv;\nlayout(location = 4) in vec4 fa_vertex_color;\nlayout(location = 0) out vec4 fa_frag_color;\nfloat fa_rt_slope;\nvec3 fa_light_tint;\nbool fa_light_is_area;\nint fa_cl_ndir;\nint fa_cl_slot;\nint fa_cl_local;\n\nvoid fa_inst_load()\n{\n}\n\nvec4 fa_light_texel(int t)\n{\n    return texelFetch(fa_light_tex_fa_shadow_smp, ivec2(t & 1023, t >> 10), 0);\n}\n\nvec4 fa_cluster_texel(vec3 world_pos)\n{\n    bool _1647 = fa_mesh_fs_params[19].x < 0.0;\n    bool _1654;\n    if (!_1647)\n    {\n        _1654 = fa_mesh_fs_params[19].w < 1.0;\n    }\n    else\n    {\n        _1654 = _1647;\n    }\n    bool _1662;\n    if (!_1654)\n    {\n        _1662 = fa_mesh_fs_params[18].x < 1.0;\n    }\n    else\n    {\n        _1662 = _1654;\n    }\n    bool _1669;\n    if (!_1662)\n    {\n        _1669 = fa_mesh_fs_params[18].y < 1.0;\n    }\n    else\n    {\n        _1669 = _1662;\n    }\n    bool _1676;\n    if (!_1669)\n    {\n        _1676 = fa_mesh_fs_params[19].y < 1.0;\n    }\n    else\n    {\n        _1676 = _1669;\n    }\n    if (_1676)\n    {\n        return vec4(0.0);\n    }\n    vec4 _1686 = vec4(world_pos, 1.0);\n    float _1692 = dot(fa_mesh_fs_params[16], _1686);\n    if (!(_1692 > 9.9999999747524270787835121154785e-07))\n    {\n        return vec4(0.0);\n    }\n    vec2 _1714 = vec2(dot(fa_mesh_fs_params[14], _1686), dot(fa_mesh_fs_params[15], _1686)) / vec2(_1692);\n    int _1718 = int(fa_mesh_fs_params[18].x);\n    int _1722 = int(fa_mesh_fs_params[18].y);\n    int param = (int(fa_mesh_fs_params[19].x) + (((clamp(int(floor(log2(max(dot(fa_mesh_fs_params[17].xyz, world_pos) + fa_mesh_fs_params[17].w, fa_mesh_fs_params[18].w) / fa_mesh_fs_params[18].w) * fa_mesh_fs_params[18].z)), 0, int(fa_mesh_fs_params[19].y) - 1) * _1722) + clamp(int(floor(((_1714.y * 0.5) + 0.5) * fa_mesh_fs_params[18].y)), 0, _1722 - 1)) * _1718)) + clamp(int(floor(((_1714.x * 0.5) + 0.5) * fa_mesh_fs_params[18].x)), 0, _1718 - 1);\n    return fa_light_texel(param);\n}\n\nivec2 fa_cluster_lookup(vec3 world_pos)\n{\n    vec3 param = world_pos;\n    vec4 _1798 = fa_cluster_texel(param);\n    return ivec2(int(_1798.x), int(_1798.y));\n}\n\nvoid fa_cluster_begin(vec3 world_pos)\n{\n    float _6604 = dot(fa_mesh_fs_params[29].xyz, world_pos) + fa_mesh_fs_params[29].w;\n    float _6607 = fwidth(_6604);\n    bool _6610 = fa_mesh_fs_params[25].y > 0.5;\n    bool _6617;\n    if (!_6610)\n    {\n        _6617 = fa_mesh_fs_params[25].w > 0.5;\n    }\n    else\n    {\n        _6617 = _6610;\n    }\n    if (_6617)\n    {\n        fa_rt_slope = min(1.5 * _6607, 0.100000001490116119384765625 * _6604);\n    }\n    fa_cl_ndir = int(fa_mesh_fs_params[19].z);\n    vec3 param = world_pos;\n    ivec2 _6633 = fa_cluster_lookup(param);\n    fa_cl_slot = _6633.x;\n    fa_cl_local = _6633.y;\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nvec3 fa_linear_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_tex_fix(inout vec3 c, float mode)\n{\n    if (mode > 1.5)\n    {\n        vec3 param = c;\n        vec3 _7803 = fa_linear_to_srgb(param);\n        c = _7803;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            vec3 param_1 = c;\n            vec3 _7811 = fa_srgb_to_linear(param_1);\n            c = _7811;\n        }\n    }\n    return c;\n}\n\nvec3 fa_tangent_normal(SurfaceInput i, vec3 m)\n{\n    vec3 _554;\n    if (i.front_facing)\n    {\n        _554 = i.world_normal;\n    }\n    else\n    {\n        _554 = -i.world_normal;\n    }\n    vec3 _578 = normalize(i.world_tangent.xyz - (_554 * dot(_554, i.world_tangent.xyz)));\n    vec3 _605 = normalize(((_578 * m.x) + ((cross(_554, _578) * i.world_tangent.w) * m.y)) + (_554 * m.z));\n    vec3 _608;\n    if (i.front_facing)\n    {\n        _608 = _605;\n    }\n    else\n    {\n        _608 = -_605;\n    }\n    return _608;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    vec4 base_t = texture(fa_tex_fa_smp, i.uv, fa_mesh_fs_params[12].w);\n    float param = fa_mesh_fs_params[6].w;\n    float param_1 = 1.0;\n    vec3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    vec3 _7843 = fa_tex_fix(param_2, param_3);\n    vec4 _10228 = base_t;\n    _10228.x = _7843.x;\n    _10228.y = _7843.y;\n    _10228.z = _7843.z;\n    base_t = _10228;\n    vec4 _7857 = (_10228 * fa_mesh_fs_params[2]) * i.vertex_color;\n    vec3 _9975 = i.world_normal;\n    if (fa_mesh_fs_params[6].z > 0.5)\n    {\n        float param_4 = fa_mesh_fs_params[6].w;\n        float param_5 = 16.0;\n        vec3 param_6 = texture(fa_normal_tex_fa_smp, i.uv, fa_mesh_fs_params[12].w).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        vec3 _7891 = fa_tex_fix(param_6, param_7);\n        vec3 _7894 = (_7891 * 2.0) - vec3(1.0);\n        vec2 _7899 = _7894.xy * fa_mesh_fs_params[6].x;\n        vec3 _10236 = _7894;\n        _10236.x = _7899.x;\n        _10236.y = _7899.y;\n        SurfaceInput param_8 = i;\n        vec3 param_9 = _10236;\n        _9975 = fa_tangent_normal(param_8, param_9);\n    }\n    vec4 mrt = texture(fa_mr_tex_fa_smp, i.uv, fa_mesh_fs_params[12].w);\n    float param_10 = fa_mesh_fs_params[6].w;\n    float param_11 = 64.0;\n    vec3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    vec3 _7929 = fa_tex_fix(param_12, param_13);\n    vec4 _10239 = mrt;\n    _10239.x = _7929.x;\n    _10239.y = _7929.y;\n    _10239.z = _7929.z;\n    mrt = _10239;\n    vec4 _7959 = texture(fa_occlusion_tex_fa_smp, i.uv, fa_mesh_fs_params[12].w);\n    float param_14 = fa_mesh_fs_params[6].w;\n    float param_15 = 256.0;\n    vec3 param_16 = _7959.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    vec3 _7970 = fa_tex_fix(param_16, param_17);\n    float param_18 = fa_mesh_fs_params[6].w;\n    float param_19 = 4.0;\n    vec3 param_20 = texture(fa_emissive_tex_fa_smp, i.uv, fa_mesh_fs_params[12].w).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    vec3 _8002 = fa_tex_fix(param_20, param_21);\n    float _9980 = fa_mesh_fs_params[20].x;\n    float _9981 = fa_mesh_fs_params[20].y;\n    float _9984 = fa_mesh_fs_params[20].z;\n    float _9983 = fa_mesh_fs_params[21].w;\n    float _9986 = fa_mesh_fs_params[22].x;\n    if (fa_mesh_fs_params[22].z > 0.5)\n    {\n        if (mod(fa_mesh_fs_params[22].z, 2.0) > 0.5)\n        {\n            _9980 *= _7970.y;\n            _9981 *= _7970.z;\n            _9983 *= _7959.w;\n        }\n        if (fa_mesh_fs_params[22].z > 1.5)\n        {\n            _9984 *= mrt.x;\n            _9986 *= mrt.w;\n        }\n    }\n    return Surface(_7857.xyz, _7857.w, _9975, clamp(fa_mesh_fs_params[5].x * _7929.z, 0.0, 1.0), clamp(fa_mesh_fs_params[5].y * _7929.y, 0.0500000007450580596923828125, 1.0), 1.0 + (fa_mesh_fs_params[6].y * (_7970.x - 1.0)), fa_mesh_fs_params[3].xyz + (fa_mesh_fs_params[4].xyz * _8002), _9980, _9981, fa_mesh_fs_params[21].xyz, _9983, _9984, fa_mesh_fs_params[20].w, _9986, fa_mesh_fs_params[22].y, fa_mesh_fs_params[23].xyz, fa_mesh_fs_params[30].x, fa_mesh_fs_params[30].y, fa_mesh_fs_params[31].xyz, fa_mesh_fs_params[30].z);\n}\n\nvoid surface(SurfaceInput i, inout Surface s)\n{\n    s.alpha = texture(mask_mask_smp, i.uv * 2.0).x;\n}\n\nvec4 fa_decal_tile(vec4 rect, vec2 uv, vec2 atlas, vec2 ddx, vec2 ddy)\n{\n    vec2 _1878 = rect.zw - rect.xy;\n    vec2 _1882 = _1878 * atlas;\n    vec2 _1886 = ddx * _1882;\n    vec2 _1890 = ddy * _1882;\n    return textureLod(fa_decal_tex_fa_env_smp, rect.xy + (clamp(uv, vec2(0.0), vec2(1.0)) * _1878), clamp(0.5 * log2(max(max(dot(_1886, _1886), dot(_1890, _1890)), 9.9999999392252902907785028219223e-09)), 0.0, 3.0));\n}\n\nvec3 fa_dc_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_dc_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvoid fa_apply_decals(vec3 world_pos, vec3 geo_normal, inout vec3 albedo, inout vec3 normal)\n{\n    bool _1923 = fa_mesh_fs_params[10].y < 0.5;\n    bool _1930;\n    if (!_1923)\n    {\n        _1930 = fa_mesh_fs_params[10].w < 0.5;\n    }\n    else\n    {\n        _1930 = _1923;\n    }\n    if (_1930)\n    {\n        return;\n    }\n    vec3 _1936 = dFdx(world_pos);\n    vec3 _1939 = dFdy(world_pos);\n    vec3 param = world_pos;\n    vec4 _1943 = fa_cluster_texel(param);\n    int _1947 = int(_1943.w);\n    if (_1947 < 1)\n    {\n        return;\n    }\n    int _1957 = int(fa_mesh_fs_params[10].y + 0.5);\n    int param_1 = _1957;\n    vec4 _1961 = fa_light_texel(param_1);\n    vec2 _1964 = _1961.yz;\n    int _1968 = int(_1961.w);\n    int param_2 = _1957 + 1;\n    vec4 _1973 = fa_light_texel(param_2);\n    float _1974 = _1973.x;\n    int _1980 = int(fa_mesh_fs_params[10].w + 0.5) - 1;\n    int _1984 = int(_1943.z);\n    vec3 _2249;\n    for (int k = 0; k < _1947; k++)\n    {\n        int _1997 = _1984 + k;\n        int param_3 = _1968 + (_1997 >> 2);\n        int _2014 = (_1957 + 2) + (int(fa_light_texel(param_3)[_1997 & 3]) * 7);\n        int param_4 = _2014 + 6;\n        vec4 _2019 = fa_light_texel(param_4);\n        if (((int(_2019.w + 0.5) >> _1980) & 1) == 0)\n        {\n            continue;\n        }\n        int param_5 = _2014;\n        vec4 _2034 = fa_light_texel(param_5);\n        int param_6 = _2014 + 1;\n        vec4 _2039 = fa_light_texel(param_6);\n        int param_7 = _2014 + 2;\n        vec4 _2044 = fa_light_texel(param_7);\n        vec3 _2047 = _2034.xyz;\n        float _2052 = dot(_2047, world_pos) + _2034.w;\n        vec3 _2054 = _2039.xyz;\n        float _2059 = dot(_2054, world_pos) + _2039.w;\n        vec3 _2061 = _2044.xyz;\n        float _2066 = dot(_2061, world_pos) + _2044.w;\n        bool _2071 = abs(_2052) > 0.5;\n        bool _2079;\n        if (!_2071)\n        {\n            _2079 = abs(_2059) > 0.5;\n        }\n        else\n        {\n            _2079 = _2071;\n        }\n        bool _2087;\n        if (!_2079)\n        {\n            _2087 = abs(_2066) > 0.5;\n        }\n        else\n        {\n            _2087 = _2079;\n        }\n        if (_2087)\n        {\n            continue;\n        }\n        float _2102 = clamp(dot(geo_normal, normalize(_2061)) * _2019.z, 0.0, 1.0);\n        if (_2102 <= 0.0)\n        {\n            continue;\n        }\n        float _2122 = (clamp((0.5 - abs(_2066)) * 10.0, 0.0, 1.0) * _2102) * _2019.x;\n        vec2 _2130 = vec2(_2052 + 0.5, 0.5 - _2059);\n        vec2 _2140 = vec2(dot(_2047, _1936), dot(_2054, _1936));\n        vec2 _2150 = vec2(dot(_2047, _1939), dot(_2054, _1939));\n        int param_8 = _2014 + 5;\n        vec4 _2155 = fa_light_texel(param_8);\n        int param_9 = _2014 + 3;\n        vec4 _2160 = fa_light_texel(param_9);\n        int param_10 = _2014 + 4;\n        vec4 _2165 = fa_light_texel(param_10);\n        float tex_a = 1.0;\n        vec3 col = _2155.xyz;\n        bool _2175 = _2160.z > _2160.x;\n        if (_2175)\n        {\n            vec4 param_11 = _2160;\n            vec2 param_12 = _2130;\n            vec2 param_13 = _1964;\n            vec2 param_14 = _2140;\n            vec2 param_15 = _2150;\n            vec4 tx = fa_decal_tile(param_11, param_12, param_13, param_14, param_15);\n            if ((_1974 > 0.5) && (_1974 < 1.5))\n            {\n                vec3 param_16 = tx.xyz;\n                vec3 _2201 = fa_dc_to_linear(param_16);\n                vec4 _10063 = tx;\n                _10063.x = _2201.x;\n                _10063.y = _2201.y;\n                _10063.z = _2201.z;\n                tx = _10063;\n            }\n            col *= tx.xyz;\n            tex_a = tx.w;\n        }\n        albedo = mix(albedo, col, vec3(clamp((_2122 * tex_a) * _2155.w, 0.0, 1.0)));\n        if (_2165.z > _2165.x)\n        {\n            vec4 param_17 = _2165;\n            vec2 param_18 = _2130;\n            vec2 param_19 = _1964;\n            vec2 param_20 = _2140;\n            vec2 param_21 = _2150;\n            vec4 _2245 = fa_decal_tile(param_17, param_18, param_19, param_20, param_21);\n            if (_1974 > 1.5)\n            {\n                vec3 param_22 = _2245.xyz;\n                vec3 _2255 = fa_dc_to_srgb(param_22);\n                _2249 = _2255;\n            }\n            else\n            {\n                _2249 = _2245.xyz;\n            }\n            vec3 _2264 = (_2249 * 2.0) - vec3(1.0);\n            vec2 _2269 = _2264.xy * _2019.y;\n            vec3 _2291 = (normalize(_2047) * _2269.x) + (normalize(_2054) * _2269.y);\n            vec3 _2294 = normalize(normal);\n            normal = normalize(mix(_2294, normalize((_2294 * max(_2264.z, 0.0500000007450580596923828125)) + (_2291 - (_2294 * dot(_2294, _2291)))), vec3(clamp(_2122 * (_2175 ? tex_a : 1.0), 0.0, 1.0))));\n        }\n    }\n}\n\nvoid fa_lod_dither()\n{\n    if (fa_mesh_fs_params[52].w != 0.0)\n    {\n        float _643 = fract(52.98291778564453125 * fract(dot(gl_FragCoord.xy, vec2(0.067110560834407806396484375, 0.005837149918079376220703125))));\n        bool _646;\n        if (fa_mesh_fs_params[52].w > 0.0)\n        {\n            _646 = _643 >= fa_mesh_fs_params[52].w;\n        }\n        else\n        {\n            _646 = _643 < (-fa_mesh_fs_params[52].w);\n        }\n        if (_646)\n        {\n            discard;\n        }\n    }\n}\n\nfloat fa_sheen_albedo(float ndv, float rough)\n{\n    float _4895 = min(sqrt(max(rough - 0.100000001490116119384765625, 0.0) * 1.111111164093017578125) * 6.0, 5.999000072479248046875);\n    float _4903 = min(sqrt(clamp(ndv, 0.0, 1.0)) * 8.0, 7.999000072479248046875);\n    int _4906 = int(_4895);\n    int _4909 = int(_4903);\n    float _4919 = _4903 - float(_4909);\n    int _4974 = (_4906 * 9) + _4909;\n    int _4994 = ((_4906 + 1) * 9) + _4909;\n    return mix(mix(_4970[_4974], _4970[_4974 + 1], _4919), mix(_4970[_4994], _4970[_4994 + 1], _4919), _4895 - float(_4906));\n}\n\nFaLayers fa_layers_setup(SurfaceInput i, Surface s, vec3 n, vec3 v, float metallic, float roughness, inout vec3 f0)\n{\n    bool _9898 = false;\n    float _9899 = 1.0;\n    float _9900 = 1.0;\n    float _9901 = 1.0;\n    float _9902 = 0.0;\n    float _9903 = 0.0;\n    float _9904 = 0.0;\n    float _9905 = 0.0;\n    float _9907 = 1.0;\n    bool _9908 = false;\n    vec3 _9909 = vec3(0.0);\n    float _9910 = 1.0;\n    float _9911 = 1.0;\n    float _9912 = 1.0;\n    float _9913 = 0.0;\n    float _9914 = 0.0;\n    vec3 _9915 = vec3(1.0, 0.0, 0.0);\n    vec3 _9916 = vec3(0.0, 0.0, 1.0);\n    float _9917 = 1.0;\n    float _9918 = 1.0;\n    float _5045 = clamp(s.specular, 0.0, 1.0);\n    float _5049 = clamp(s.ior, 1.0, 3.0);\n    bool _5054 = (_5045 != 1.0) || (_5049 != 1.5);\n    bool _5063;\n    if (!_5054)\n    {\n        _5063 = any(notEqual(s.specular_color, vec3(1.0)));\n    }\n    else\n    {\n        _5063 = _5054;\n    }\n    if (_5063)\n    {\n        float _5071 = (_5049 - 1.0) / (_5049 + 1.0);\n        f0 = mix(min(vec3(_5071 * _5071) * max(s.specular_color, vec3(0.0)), vec3(1.0)) * _5045, s.albedo, vec3(metallic));\n        _9899 = mix(_5045, 1.0, metallic);\n        _9898 = true;\n    }\n    float _5098 = clamp(s.clearcoat, 0.0, 1.0);\n    if (_5098 > 0.0)\n    {\n        float _5106 = clamp(s.clearcoat_roughness, 0.0500000007450580596923828125, 1.0);\n        _9902 = _5098;\n        _9903 = _5106;\n        float _5113 = _5106 * _5106;\n        _9904 = _5113;\n        _9905 = _5113 * _5113;\n        float _5125 = max(dot(i.world_normal, v), 9.9999997473787516355514526367188e-05);\n        _9907 = _5125;\n        _9900 = 1.0 - (_5098 * (0.039999999105930328369140625 + (0.959999978542327880859375 * pow(clamp(1.0 - _5125, 0.0, 1.0), 5.0))));\n        _9898 = true;\n    }\n    vec3 _5144 = max(s.sheen_color, vec3(0.0));\n    float _5153 = max(_5144.x, max(_5144.y, _5144.z));\n    if (_5153 > 0.0)\n    {\n        float _5161 = clamp(s.sheen_roughness, 0.100000001490116119384765625, 1.0);\n        _9908 = true;\n        _9909 = _5144;\n        _9910 = _5161;\n        _9911 = _5161 * _5161;\n        float param = max(dot(n, v), 9.9999997473787516355514526367188e-05);\n        float param_1 = _5161;\n        float _5178 = fa_sheen_albedo(param, param_1);\n        _9913 = _5178;\n        _9912 = 1.0 - min(_5153 * _5178, 1.0);\n        _9898 = true;\n    }\n    _9901 = _9900 * _9912;\n    float _5197 = clamp(s.anisotropy, -1.0, 1.0);\n    if (_5197 != 0.0)\n    {\n        vec3 _5212 = i.world_tangent.xyz - (n * dot(n, i.world_tangent.xyz));\n        vec3 t = _5212;\n        if (dot(_5212, _5212) < 9.9999999392252902907785028219223e-09)\n        {\n            bvec3 _5224 = bvec3(abs(n.y) < 0.9900000095367431640625);\n            t = cross(vec3(_5224.x ? vec3(0.0, 1.0, 0.0).x : vec3(1.0, 0.0, 0.0).x, _5224.y ? vec3(0.0, 1.0, 0.0).y : vec3(1.0, 0.0, 0.0).y, _5224.z ? vec3(0.0, 1.0, 0.0).z : vec3(1.0, 0.0, 0.0).z), n);\n        }\n        vec3 _5228 = t;\n        vec3 _5229 = normalize(_5228);\n        t = _5229;\n        vec3 _5254 = normalize((_5229 * cos(s.anisotropy_rotation)) + ((cross(n, _5229) * ((i.world_tangent.w < 0.0) ? (-1.0) : 1.0)) * sin(s.anisotropy_rotation)));\n        _9915 = _5254;\n        _9916 = cross(n, _5254);\n        float _5264 = roughness * roughness;\n        float _5270 = mix(_5264, 1.0, _5197 * _5197);\n        bool _5272 = _5197 > 0.0;\n        _9917 = _5272 ? _5270 : _5264;\n        _9918 = _5272 ? _5264 : _5270;\n        _9914 = _5197;\n        _9898 = true;\n    }\n    return FaLayers(_9898, _9899, _9900, _9901, _9902, _9903, _9904, _9905, i.world_normal, _9907, _9908, _9909, _9910, _9911, _9912, _9913, _9914, _9915, _9916, _9917, _9918);\n}\n\nvec2 fa_atlas_size()\n{\n    return vec2(textureSize(fa_probe_atlas_fa_env_smp, 0));\n}\n\nvec3 fa_probe_sh_coef(vec2 origin, float res, int k)\n{\n    vec3 v = textureLod(fa_probe_atlas_fa_env_smp, (origin + vec2(float(k) + 0.5, res + 2.5)) / fa_atlas_size(), 0.0).xyz;\n    if (fa_mesh_fs_params[41].y > 0.5)\n    {\n        v = ((v * 255.0) - vec3(128.0)) * 0.03149606287479400634765625;\n    }\n    return v;\n}\n\nvec3 fa_sh_eval(vec3 c[9], vec3 n)\n{\n    vec3 _4065 = max((((c[0] * 0.2820948064327239990234375) + (((c[1] * (0.3257350027561187744140625 * n.y)) + (c[2] * (0.3257350027561187744140625 * n.z))) + (c[3] * (0.3257350027561187744140625 * n.x)))) + (((c[4] * ((0.2731371223926544189453125 * n.x) * n.y)) + (c[5] * ((0.2731371223926544189453125 * n.y) * n.z))) + (c[6] * (0.078847892582416534423828125 * (((3.0 * n.z) * n.z) - 1.0))))) + ((c[7] * ((0.2731371223926544189453125 * n.x) * n.z)) + (c[8] * (0.13656856119632720947265625 * ((n.x * n.x) - (n.y * n.y))))), vec3(0.0));\n    return _4065;\n}\n\nvec3 fa_ambient_light(vec3 n)\n{\n    float _4676 = (1.0 - fa_mesh_fs_params[42].w) - fa_mesh_fs_params[47].w;\n    vec3 amb = vec3(0.0);\n    bool _4681 = fa_mesh_fs_params[11].w > 0.5;\n    vec3 c[9];\n    for (int k = 0; k < 9; k++)\n    {\n        c[k] = vec3(0.0);\n    }\n    if (_4676 > 0.0005000000237487256526947021484375)\n    {\n        if (_4681)\n        {\n            for (int k_1 = 0; k_1 < 9; k_1++)\n            {\n                vec2 param = fa_mesh_fs_params[41].zw;\n                float param_1 = 128.0;\n                int param_2 = k_1;\n                c[k_1] = fa_probe_sh_coef(param, param_1, param_2) * _4676;\n            }\n        }\n        else\n        {\n            amb = fa_mesh_fs_params[1].xyz * _4676;\n        }\n    }\n    bool _4732 = fa_mesh_fs_params[42].w > 0.0;\n    if (_4732)\n    {\n        for (int k_2 = 0; k_2 < 9; k_2++)\n        {\n            vec2 param_3 = fa_mesh_fs_params[42].xy;\n            float param_4 = fa_mesh_fs_params[42].z;\n            int param_5 = k_2;\n            c[k_2] += (fa_probe_sh_coef(param_3, param_4, param_5) * fa_mesh_fs_params[42].w);\n        }\n    }\n    bool _4763 = fa_mesh_fs_params[47].w > 0.0;\n    if (_4763)\n    {\n        for (int k_3 = 0; k_3 < 9; k_3++)\n        {\n            vec2 param_6 = fa_mesh_fs_params[47].xy;\n            float param_7 = fa_mesh_fs_params[47].z;\n            int param_8 = k_3;\n            c[k_3] += (fa_probe_sh_coef(param_6, param_7, param_8) * fa_mesh_fs_params[47].w);\n        }\n    }\n    if ((_4681 || _4732) || _4763)\n    {\n        vec3 param_9[9] = c;\n        vec3 param_10 = n;\n        amb += fa_sh_eval(param_9, param_10);\n    }\n    return amb;\n}\n\nvec4 fa_gi_fetch(vec2 texel)\n{\n    return textureLod(fa_probe_atlas_fa_env_smp, texel / fa_atlas_size(), 0.0);\n}\n\nvec2 fa_oct_encode(vec3 d)\n{\n    vec3 _4085 = d / vec3(max((abs(d.x) + abs(d.y)) + abs(d.z), 9.9999999600419720025001879548654e-13));\n    float _4088 = _4085.x;\n    float _4090 = _4085.z;\n    vec2 e = vec2(_4088, _4090);\n    if (_4085.y < 0.0)\n    {\n        e = vec2((1.0 - abs(_4090)) * ((_4088 < 0.0) ? (-1.0) : 1.0), (1.0 - abs(_4088)) * ((_4090 < 0.0) ? (-1.0) : 1.0));\n    }\n    return e;\n}\n\nvec3 fa_gi_grid(int rec, vec3 n, vec3 v, out float cover)\n{\n    cover = 0.0;\n    int param = rec;\n    vec4 _8112 = fa_light_texel(param);\n    int param_1 = rec + 1;\n    vec4 _8117 = fa_light_texel(param_1);\n    int param_2 = rec + 2;\n    vec4 _8122 = fa_light_texel(param_2);\n    int param_3 = rec + 3;\n    vec4 _8127 = fa_light_texel(param_3);\n    bool _8130 = _8127.z < 0.5;\n    bool _8138;\n    if (!_8130)\n    {\n        _8138 = fa_atlas_size().y < 1155.0;\n    }\n    else\n    {\n        _8138 = _8130;\n    }\n    if (_8138)\n    {\n        return vec3(0.0);\n    }\n    float _8145 = max(_8112.w, 9.9999997473787516355514526367188e-05);\n    vec3 _8148 = _8117.xyz;\n    vec3 _8152 = _8112.xyz;\n    vec3 _8156 = (fa_world_pos - _8152) / vec3(_8145);\n    vec3 _8165 = min(_8156 + vec3(0.5), (_8148 - vec3(0.5)) - _8156);\n    float _8174 = min(_8165.x, min(_8165.y, _8165.z));\n    if (!(_8174 > 0.0))\n    {\n        return vec3(0.0);\n    }\n    vec3 _8189 = _8148 - vec3(1.0);\n    vec3 _8190 = clamp(_8156, vec3(0.0), _8189);\n    vec3 _8198 = min(floor(_8190), max(_8148 - vec3(2.0), vec3(0.0)));\n    vec3 _8202 = _8190 - _8198;\n    vec3 _8213 = fa_world_pos + (((n * 0.800000011920928955078125) + (v * 0.20000000298023223876953125)) * (0.20000000298023223876953125 * _8145));\n    int _8218 = int(_8122.y + 0.5);\n    float _8223 = 0.3257350027561187744140625 * n.y;\n    float _8227 = 0.3257350027561187744140625 * n.z;\n    float _8231 = 0.3257350027561187744140625 * n.x;\n    float _8238 = (0.2731371223926544189453125 * n.x) * n.y;\n    float _8245 = (0.2731371223926544189453125 * n.y) * n.z;\n    float _8254 = 0.078847892582416534423828125 * (((3.0 * n.z) * n.z) - 1.0);\n    float _8261 = (0.2731371223926544189453125 * n.x) * n.z;\n    float _8274 = 0.13656856119632720947265625 * ((n.x * n.x) - (n.y * n.y));\n    vec3 acc = vec3(0.0);\n    float wsum = 0.0;\n    int _8281 = 8 + int(_8127.w);\n    float _8308;\n    float _8321;\n    float _8335;\n    for (int k = 0; k < _8281; k++)\n    {\n        float _8294 = float(k & 1);\n        float _8298 = float((k >> 1) & 1);\n        float _8302 = float((k >> 2) & 1);\n        if (_8294 > 0.5)\n        {\n            _8308 = _8202.x;\n        }\n        else\n        {\n            _8308 = 1.0 - _8202.x;\n        }\n        if (_8298 > 0.5)\n        {\n            _8321 = _8202.y;\n        }\n        else\n        {\n            _8321 = 1.0 - _8202.y;\n        }\n        if (_8302 > 0.5)\n        {\n            _8335 = _8202.z;\n        }\n        else\n        {\n            _8335 = 1.0 - _8202.z;\n        }\n        float _8345 = (_8308 * _8321) * _8335;\n        if (!(_8345 > 0.0))\n        {\n            continue;\n        }\n        vec3 _8358 = min(_8198 + vec3(_8294, _8298, _8302), _8189);\n        int _8378 = int(((_8122.x + _8358.x) + (_8117.x * (_8358.y + (_8117.y * _8358.z)))) + 0.5);\n        vec2 _8393 = vec2(float(_8378 % _8218) * 10.0, 1024.0 + (float(_8378 / _8218) * 11.0));\n        vec2 param_4 = _8393 + vec2(9.5, 10.5);\n        vec4 _8401 = fa_gi_fetch(param_4);\n        bool _8404 = _8401.y < 0.5;\n        bool _8413;\n        if (!_8404)\n        {\n            _8413 = _8401.x > _8127.y;\n        }\n        else\n        {\n            _8413 = _8404;\n        }\n        if (_8413)\n        {\n            continue;\n        }\n        vec3 _8425 = _8213 - (_8152 + (_8358 * _8145));\n        float _8428 = length(_8425);\n        vec3 _8434 = _8425 / vec3(max(_8428, 9.9999997473787516355514526367188e-05));\n        float _8444 = max(9.9999997473787516355514526367188e-05, (dot(-_8434, n) + 1.0) * 0.5);\n        float w = _8345 * (_8444 * _8444);\n        vec3 param_5 = _8434;\n        vec2 param_6 = (_8393 + vec2(1.0)) + (((fa_oct_encode(param_5) * 0.5) + vec2(0.5)) * 8.0);\n        vec4 _8463 = fa_gi_fetch(param_6);\n        float _8470 = _8428 / max(_8122.z, 9.9999997473787516355514526367188e-05);\n        float _8473 = _8463.x;\n        if (_8470 > _8473)\n        {\n            float _8486 = max(_8463.y - (_8473 * _8473), 0.0);\n            float _8491 = _8470 - _8473;\n            float _8500 = _8486 / max(_8486 + (_8491 * _8491), 9.9999999600419720025001879548654e-13);\n            w *= ((_8500 * _8500) * _8500);\n        }\n        if (!(w > 0.0))\n        {\n            continue;\n        }\n        vec2 param_7 = _8393 + vec2(0.5, 10.5);\n        vec2 param_8 = _8393 + vec2(1.5, 10.5);\n        vec2 param_9 = _8393 + vec2(2.5, 10.5);\n        vec2 param_10 = _8393 + vec2(3.5, 10.5);\n        vec2 param_11 = _8393 + vec2(4.5, 10.5);\n        vec2 param_12 = _8393 + vec2(5.5, 10.5);\n        vec2 param_13 = _8393 + vec2(6.5, 10.5);\n        vec2 param_14 = _8393 + vec2(7.5, 10.5);\n        vec2 param_15 = _8393 + vec2(8.5, 10.5);\n        acc += ((((((((((fa_gi_fetch(param_7).xyz * 0.2820948064327239990234375) + (fa_gi_fetch(param_8).xyz * _8223)) + (fa_gi_fetch(param_9).xyz * _8227)) + (fa_gi_fetch(param_10).xyz * _8231)) + (fa_gi_fetch(param_11).xyz * _8238)) + (fa_gi_fetch(param_12).xyz * _8245)) + (fa_gi_fetch(param_13).xyz * _8254)) + (fa_gi_fetch(param_14).xyz * _8261)) + (fa_gi_fetch(param_15).xyz * _8274)) * w);\n        wsum += w;\n    }\n    if (!(wsum > 9.9999997473787516355514526367188e-06))\n    {\n        return vec3(0.0);\n    }\n    cover = smoothstep(0.0, 1.0, clamp(_8174 * 2.0, 0.0, 1.0)) * smoothstep(0.0, 0.0199999995529651641845703125, wsum);\n    float _8624;\n    if (fa_mesh_fs_params[52].z > 0.5)\n    {\n        _8624 = _8127.x;\n    }\n    else\n    {\n        _8624 = 1.0;\n    }\n    return max(acc / vec3(wsum), vec3(0.0)) * (_8122.w * _8624);\n}\n\nvec3 fa_gi_light(vec3 n, inout float left)\n{\n    left = 1.0;\n    vec3 acc = vec3(0.0);\n    vec3 _8648 = normalize(fa_mesh_fs_params[0].xyz - fa_world_pos);\n    int _8653 = int(fa_mesh_fs_params[52].x + 0.5);\n    int _8658 = int(fa_mesh_fs_params[52].y + 0.5);\n    float param_3;\n    for (int k = 0; (k < _8658) && (k < 8); k++)\n    {\n        int param = _8653 + (4 * k);\n        vec3 param_1 = n;\n        vec3 param_2 = _8648;\n        vec3 _8683 = fa_gi_grid(param, param_1, param_2, param_3);\n        float _8688 = param_3 * left;\n        acc += (_8683 * _8688);\n        left -= _8688;\n        if (left < 0.001000000047497451305389404296875)\n        {\n            left = 0.0;\n            break;\n        }\n    }\n    return acc;\n}\n\nvec3 fa_realtime_or_ambient(vec3 n)\n{\n    vec3 gi = vec3(0.0);\n    float left = 1.0;\n    if (fa_mesh_fs_params[52].y > 0.5)\n    {\n        vec3 param = n;\n        float param_1;\n        vec3 _8717 = fa_gi_light(param, param_1);\n        left = param_1;\n        gi = _8717;\n    }\n    if (left <= 0.0)\n    {\n        return gi;\n    }\n    vec3 param_2 = n;\n    return gi + (fa_ambient_light(param_2) * left);\n}\n\nvec3 fa_indirect_diffuse(vec3 n)\n{\n    if (fa_lm.z > 0.5)\n    {\n        return textureLod(fa_lightmap_fa_env_smp, fa_lm.xy, 0.0).xyz;\n    }\n    if (fa_mesh_fs_params[53].x > 0.5)\n    {\n        vec4 _8759 = vec4(fa_world_pos, 1.0);\n        vec2 _8778 = vec2(dot(fa_mesh_fs_params[26], _8759), dot(fa_mesh_fs_params[27], _8759)) / vec2(max(dot(fa_mesh_fs_params[28], _8759), 9.9999997473787516355514526367188e-05));\n        float _8787;\n        if (fa_mesh_fs_params[24].y > 0.5)\n        {\n            _8787 = (_8778.y * 0.5) + 0.5;\n        }\n        else\n        {\n            _8787 = 0.5 - (_8778.y * 0.5);\n        }\n        return texelFetch(fa_lightmap_fa_env_smp, clamp(ivec2(vec2((_8778.x * 0.5) + 0.5, _8787) * fa_mesh_fs_params[24].zw), ivec2(0), ivec2(fa_mesh_fs_params[24].zw) - ivec2(1)), 0).xyz;\n    }\n    if (fa_mesh_fs_params[32].w > 0.0)\n    {\n        vec3 c[9];\n        for (int k = 0; k < 9; k++)\n        {\n            c[k] = fa_mesh_fs_params[k * 1 + 32].xyz;\n        }\n        vec3 param = n;\n        vec3 param_1[9] = c;\n        vec3 param_2 = n;\n        return mix(fa_ambient_light(param), fa_sh_eval(param_1, param_2), vec3(clamp(fa_mesh_fs_params[32].w, 0.0, 1.0)));\n    }\n    vec3 param_3 = n;\n    return fa_realtime_or_ambient(param_3);\n}\n\nint fa_cluster_index(int slot, int n)\n{\n    int param = (int(fa_mesh_fs_params[19].x) + int(fa_mesh_fs_params[19].w)) + ((slot + n) >> 2);\n    vec4 t = fa_light_texel(param);\n    return int(t[(slot + n) & 3]);\n}\n\nint fa_cl_light(int n)\n{\n    if (n < fa_cl_ndir)\n    {\n        return n;\n    }\n    int param = fa_cl_slot;\n    int param_1 = n - fa_cl_ndir;\n    return fa_cluster_index(param, param_1);\n}\n\nint fa_light_base(int li)\n{\n    return li * ((fa_mesh_fs_params[1].w > 4.5) ? 8 : 4);\n}\n\nbool fa_light_baked(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 3;\n    return fa_light_texel(param_1).w > 0.5;\n}\n\nfloat fa_baked_keep(int li)\n{\n    float _6574;\n    if (fa_lm.z > 0.5)\n    {\n        _6574 = 0.0;\n    }\n    else\n    {\n        _6574 = 1.0 - clamp(fa_mesh_fs_params[32].w, 0.0, 1.0);\n    }\n    bool _6585 = _6574 < 1.0;\n    bool _6591;\n    if (_6585)\n    {\n        int param = li;\n        _6591 = fa_light_baked(param);\n    }\n    else\n    {\n        _6591 = _6585;\n    }\n    return _6591 ? _6574 : 1.0;\n}\n\nfloat fa_light_type(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 1;\n    return fa_light_texel(param_1).w;\n}\n\nvec4 fa_atlas_fetch(vec2 texel)\n{\n    return textureLod(fa_light_atlas_fa_env_smp, texel / vec2(textureSize(fa_light_atlas_fa_env_smp, 0)), 0.0);\n}\n\nvec3 fa_cookie_sample(vec2 tile_origin, vec2 uv)\n{\n    vec2 param = (tile_origin + vec2(1.0)) + (clamp(uv, vec2(0.0), vec2(1.0)) * 254.0);\n    return fa_atlas_fetch(param).xyz;\n}\n\nvec3 fa_area_point(vec3 c, vec3 axis, vec3 ru, vec3 uu, float hx, float hy, float shape, vec3 p, vec3 r)\n{\n    bool _896 = dot(r, r) > 0.5;\n    if (shape > 1.5)\n    {\n        vec3 _909 = (c - (ru * hx)) - p;\n        vec3 _915 = ru * (2.0 * hx);\n        float _921 = max(dot(_915, _915), 9.9999999392252902907785028219223e-09);\n        float _925 = dot(_909, _915);\n        float t = clamp((-_925) / _921, 0.0, 1.0);\n        if (_896)\n        {\n            float _940 = dot(r, _915);\n            float _946 = _921 - (_940 * _940);\n            if (abs(_946) > (9.9999997473787516355514526367188e-06 * _921))\n            {\n                t = clamp(((dot(r, _909) * _940) - _925) / _946, 0.0, 1.0);\n            }\n        }\n        return (p + _909) + (_915 * t);\n    }\n    vec3 q = p;\n    float _978 = dot(r, axis);\n    bool _986;\n    if (_896)\n    {\n        _986 = abs(_978) > 9.9999997473787516355514526367188e-05;\n    }\n    else\n    {\n        _986 = _896;\n    }\n    if (_986)\n    {\n        float _996 = dot(c - p, axis) / _978;\n        if (_996 > 0.0)\n        {\n            q = p + (r * _996);\n        }\n    }\n    vec3 _1009 = q - c;\n    vec2 xy = vec2(dot(_1009, ru), dot(_1009, uu));\n    if (shape > 0.5)\n    {\n        float _1024 = length(xy);\n        if (_1024 > hx)\n        {\n            xy *= (hx / _1024);\n        }\n    }\n    else\n    {\n        xy = clamp(xy, vec2(-hx, -hy), vec2(hx, hy));\n    }\n    return (c + (ru * xy.x)) + (uu * xy.y);\n}\n\nint fa_cube_face(vec3 d)\n{\n    vec3 _663 = abs(d);\n    float _665 = _663.x;\n    float _667 = _663.y;\n    bool _668 = _665 >= _667;\n    bool _676;\n    if (_668)\n    {\n        _676 = _665 >= _663.z;\n    }\n    else\n    {\n        _676 = _668;\n    }\n    int _677;\n    if (_676)\n    {\n        _677 = (d.x > 0.0) ? 0 : 1;\n    }\n    else\n    {\n        int _691;\n        if (_667 >= _663.z)\n        {\n            _691 = (d.y > 0.0) ? 2 : 3;\n        }\n        else\n        {\n            _691 = (d.z > 0.0) ? 4 : 5;\n        }\n        _677 = _691;\n    }\n    return _677;\n}\n\nvoid fa_cube_face_basis(int f, out vec3 fwd, out vec3 up)\n{\n    if (f == 0)\n    {\n        fwd = vec3(1.0, 0.0, 0.0);\n        up = vec3(0.0, 1.0, 0.0);\n    }\n    else\n    {\n        if (f == 1)\n        {\n            fwd = vec3(-1.0, 0.0, 0.0);\n            up = vec3(0.0, 1.0, 0.0);\n        }\n        else\n        {\n            if (f == 2)\n            {\n                fwd = vec3(0.0, 1.0, 0.0);\n                up = vec3(0.0, 0.0, 1.0);\n            }\n            else\n            {\n                if (f == 3)\n                {\n                    fwd = vec3(0.0, -1.0, 0.0);\n                    up = vec3(0.0, 0.0, -1.0);\n                }\n                else\n                {\n                    if (f == 4)\n                    {\n                        fwd = vec3(0.0, 0.0, 1.0);\n                        up = vec3(0.0, 1.0, 0.0);\n                    }\n                    else\n                    {\n                        fwd = vec3(0.0, 0.0, -1.0);\n                        up = vec3(0.0, 1.0, 0.0);\n                    }\n                }\n            }\n        }\n    }\n}\n\nfloat fa_ies_sample(vec2 tile_origin, vec3 d, vec3 axis, vec3 right, vec3 up)\n{\n    float _816 = dot(d, right);\n    float _820 = dot(d, up);\n    float _831;\n    if (((_816 * _816) + (_820 * _820)) > 1.0000000133514319600180897396058e-10)\n    {\n        _831 = atan(_820, _816) * 0.15915493667125701904296875;\n    }\n    else\n    {\n        _831 = 0.0;\n    }\n    vec2 param = tile_origin + vec2(1.0 + ((_831 - floor(_831)) * 64.0), 1.0 + (acos(clamp(dot(d, axis), -1.0, 1.0)) * 10.18591594696044921875));\n    return fa_atlas_fetch(param).x;\n}\n\nLightSample fa_light_sample_n(int li, vec3 world_pos, vec3 n)\n{\n    int param = li;\n    int _1062 = fa_light_base(param);\n    bool _1066 = fa_mesh_fs_params[1].w > 4.5;\n    int param_1 = _1062;\n    vec4 _1070 = fa_light_texel(param_1);\n    int param_2 = _1062 + 1;\n    vec4 _1075 = fa_light_texel(param_2);\n    float _1078 = _1075.w;\n    float atten = 1.0;\n    float dist = 0.0;\n    fa_light_tint = vec3(1.0);\n    bool _1090 = _1066 && (_1078 > 2.5);\n    fa_light_is_area = _1090;\n    bool _1092 = _1078 < 0.5;\n    vec3 l;\n    if (_1092)\n    {\n        l = normalize(_1070.xyz);\n        if (_1066)\n        {\n            int param_3 = _1062 + 6;\n            vec4 _1106 = fa_light_texel(param_3);\n            if (_1106.z > 0.5)\n            {\n                int param_4 = _1062 + 4;\n                vec4 _1116 = fa_light_texel(param_4);\n                int param_5 = _1062 + 5;\n                vec4 _1121 = fa_light_texel(param_5);\n                vec2 param_6 = _1106.xy;\n                vec2 param_7 = fract(vec2(dot(world_pos, _1116.xyz) * _1116.w, (-dot(world_pos, _1121.xyz)) * _1121.w) + vec2(0.5));\n                fa_light_tint = fa_cookie_sample(param_6, param_7);\n            }\n        }\n    }\n    else\n    {\n        vec3 _1151 = _1070.xyz;\n        vec3 _1153 = _1151 - world_pos;\n        vec3 to_light = _1153;\n        float _1156 = length(_1153);\n        float reach = _1156;\n        bool front = true;\n        if (_1090)\n        {\n            int param_8 = _1062 + 7;\n            reach = max(_1156 - fa_light_texel(param_8).w, 0.0);\n            int param_9 = _1062 + 4;\n            vec4 _1180 = fa_light_texel(param_9);\n            int param_10 = _1062 + 5;\n            vec4 _1185 = fa_light_texel(param_10);\n            int param_11 = _1062 + 6;\n            vec4 _1190 = fa_light_texel(param_11);\n            float _1191 = _1190.w;\n            int param_12 = _1062 + 2;\n            vec3 _1198 = normalize(fa_light_texel(param_12).xyz);\n            bool _1200 = _1191 > 1.5;\n            bool _1208;\n            if (!_1200)\n            {\n                _1208 = dot(_1198, to_light) < 0.0;\n            }\n            else\n            {\n                _1208 = _1200;\n            }\n            front = _1208;\n            vec3 r = vec3(0.0);\n            vec3 _1217 = fa_mesh_fs_params[0].xyz - world_pos;\n            bool _1221 = dot(n, n) > 0.5;\n            bool _1229;\n            if (_1221)\n            {\n                _1229 = dot(_1217, _1217) > 9.9999999600419720025001879548654e-13;\n            }\n            else\n            {\n                _1229 = _1221;\n            }\n            if (_1229)\n            {\n                r = reflect(-normalize(_1217), normalize(n));\n            }\n            vec3 param_13 = _1151;\n            vec3 param_14 = _1198;\n            vec3 param_15 = _1180.xyz;\n            vec3 param_16 = _1185.xyz;\n            float param_17 = _1180.w;\n            float param_18 = _1185.w;\n            float param_19 = _1191;\n            vec3 param_20 = world_pos;\n            vec3 param_21 = r;\n            to_light = fa_area_point(param_13, param_14, param_15, param_16, param_17, param_18, param_19, param_20, param_21) - world_pos;\n        }\n        float _1265 = length(to_light);\n        dist = _1265;\n        l = to_light / vec3(max(_1265, 9.9999997473787516355514526367188e-05));\n        float _1279 = reach / max(_1070.w, 0.001000000047497451305389404296875);\n        float _1285 = clamp(1.0 - (_1279 * _1279), 0.0, 1.0);\n        float _1287;\n        if (front)\n        {\n            _1287 = _1285 * _1285;\n        }\n        else\n        {\n            _1287 = 0.0;\n        }\n        atten = _1287;\n        bool _1298 = _1078 < 2.5;\n        if ((_1078 > 1.5) && _1298)\n        {\n            int param_22 = _1062 + 2;\n            vec4 _1306 = fa_light_texel(param_22);\n            float _1316 = _1306.w;\n            int param_23 = _1062 + 3;\n            vec4 _1321 = fa_light_texel(param_23);\n            float _1322 = _1321.x;\n            float cos_inner = _1322;\n            if (_1322 > 1.5)\n            {\n                cos_inner = mix(_1316, 1.0, 0.25);\n            }\n            atten *= smoothstep(_1316, cos_inner, dot(-l, normalize(_1306.xyz)));\n        }\n        if (_1066 && (_1078 < 1.5))\n        {\n            int param_24 = _1062 + 6;\n            vec4 _1346 = fa_light_texel(param_24);\n            if (_1346.z > 0.5)\n            {\n                vec3 _1354 = -to_light;\n                int param_25 = _1062 + 4;\n                int param_26 = _1062 + 5;\n                vec3 _1368 = fa_light_texel(param_25).xyz;\n                vec3 _1372 = fa_light_texel(param_26).xyz;\n                vec3 _1381 = vec3(dot(_1354, _1368), dot(_1354, _1372), dot(_1354, cross(_1368, _1372)));\n                vec3 param_27 = _1381;\n                int _1385 = fa_cube_face(param_27);\n                int param_28 = _1385;\n                vec3 param_29;\n                vec3 param_30;\n                fa_cube_face_basis(param_28, param_29, param_30);\n                vec2 _1412 = vec2(dot(_1381, cross(param_29, param_30)), dot(_1381, param_30)) / vec2(max(dot(_1381, param_29), 9.9999997473787516355514526367188e-05));\n                int _1416 = _1385 / 3;\n                vec2 param_31 = _1346.xy + (vec2(float(_1385 - (_1416 * 3)), float(_1416)) * 256.0);\n                vec2 param_32 = vec2(0.5 + (0.5 * _1412.x), 0.5 - (0.5 * _1412.y));\n                fa_light_tint = fa_cookie_sample(param_31, param_32);\n            }\n            int param_33 = _1062 + 7;\n            vec4 _1446 = fa_light_texel(param_33);\n            if (_1446.z > 0.5)\n            {\n                int param_34 = _1062 + 2;\n                int param_35 = _1062 + 4;\n                int param_36 = _1062 + 5;\n                vec2 param_37 = _1446.xy;\n                vec3 param_38 = -l;\n                vec3 param_39 = normalize(fa_light_texel(param_34).xyz);\n                vec3 param_40 = fa_light_texel(param_35).xyz;\n                vec3 param_41 = fa_light_texel(param_36).xyz;\n                atten *= fa_ies_sample(param_37, param_38, param_39, param_40, param_41);\n            }\n        }\n        else\n        {\n            if (_1066 && _1298)\n            {\n                int param_42 = _1062 + 6;\n                vec4 _1493 = fa_light_texel(param_42);\n                int param_43 = _1062 + 7;\n                vec4 _1498 = fa_light_texel(param_43);\n                bool _1501 = _1493.z > 0.5;\n                bool _1508;\n                if (!_1501)\n                {\n                    _1508 = _1498.z > 0.5;\n                }\n                else\n                {\n                    _1508 = _1501;\n                }\n                if (_1508)\n                {\n                    int param_44 = _1062 + 2;\n                    vec4 _1515 = fa_light_texel(param_44);\n                    vec3 _1519 = normalize(_1515.xyz);\n                    int param_45 = _1062 + 4;\n                    vec4 _1524 = fa_light_texel(param_45);\n                    int param_46 = _1062 + 5;\n                    vec4 _1529 = fa_light_texel(param_46);\n                    if (_1501)\n                    {\n                        vec3 _1537 = -to_light;\n                        float _1544 = _1515.w;\n                        float _1560 = 0.5 / max(dot(_1537, _1519) * (sqrt(max(1.0 - (_1544 * _1544), 0.0)) / max(_1544, 0.001000000047497451305389404296875)), 9.9999997473787516355514526367188e-05);\n                        vec2 param_47 = _1493.xy;\n                        vec2 param_48 = vec2(0.5 + (dot(_1537, _1524.xyz) * _1560), 0.5 - (dot(_1537, _1529.xyz) * _1560));\n                        fa_light_tint = fa_cookie_sample(param_47, param_48);\n                    }\n                    if (_1498.z > 0.5)\n                    {\n                        vec2 param_49 = _1498.xy;\n                        vec3 param_50 = -l;\n                        vec3 param_51 = _1519;\n                        vec3 param_52 = _1524.xyz;\n                        vec3 param_53 = _1529.xyz;\n                        atten *= fa_ies_sample(param_49, param_50, param_51, param_52, param_53);\n                    }\n                }\n            }\n        }\n    }\n    vec3 _9886 = _1075.xyz * atten;\n    if (_1066)\n    {\n        _9886 *= fa_light_tint;\n    }\n    int _1629;\n    if (_1092)\n    {\n        _1629 = 0;\n    }\n    else\n    {\n        _1629 = ((_1078 > 1.5) && (_1078 < 2.5)) ? 2 : 1;\n    }\n    return LightSample(l, _9886, atten, 1.0, dist, _1629);\n}\n\nfloat fa_shadow_split_at(int i)\n{\n    float _2355;\n    if (i == 0)\n    {\n        _2355 = fa_shadows[24].x;\n    }\n    else\n    {\n        float _2371;\n        if (i == 1)\n        {\n            _2371 = fa_shadows[24].y;\n        }\n        else\n        {\n            float _2379;\n            if (i == 2)\n            {\n                _2379 = fa_shadows[24].z;\n            }\n            else\n            {\n                _2379 = fa_shadows[24].w;\n            }\n            _2371 = _2379;\n        }\n        _2355 = _2371;\n    }\n    return _2355;\n}\n\nfloat fa_shadow_depth(inout vec2 uv, vec4 rect)\n{\n    uv = clamp(uv, rect.xy, rect.zw);\n    return textureLod(fa_shadow_tex_fa_shadow_smp, uv, 0.0).x;\n}\n\nfloat fa_shadow_fetch(vec2 uv, vec4 rect, vec3 conv)\n{\n    vec2 param = uv;\n    vec4 param_1 = rect;\n    float _2412 = fa_shadow_depth(param, param_1);\n    float _2416;\n    if (conv.x < 0.5)\n    {\n        _2416 = _2412;\n    }\n    else\n    {\n        _2416 = (conv.y * conv.z) / (conv.z - (_2412 * (conv.z - conv.y)));\n    }\n    return _2416;\n}\n\nfloat fa_shadow_noise()\n{\n    return fract(52.98291778564453125 * fract(dot(gl_FragCoord.xy, vec2(0.067110560834407806396484375, 0.005837149918079376220703125))));\n}\n\nvec2 fa_shadow_vogel_turn(vec2 d)\n{\n    return vec2((d.x * (-0.737368881702423095703125)) - (d.y * 0.675490319728851318359375), (d.y * (-0.737368881702423095703125)) + (d.x * 0.675490319728851318359375));\n}\n\nfloat fa_shadow_filter(vec2 uv, vec4 rect, float zr, float texel_m, float unit, float reach, float plane, vec3 conv, int mode, float k)\n{\n    if (mode == 1)\n    {\n        vec2 param = uv;\n        vec4 param_1 = rect;\n        vec3 param_2 = conv;\n        return float(zr <= fa_shadow_fetch(param, param_1, param_2));\n    }\n    float _2462 = fa_shadow_noise() * 6.283185482025146484375;\n    vec2 _2468 = vec2(cos(_2462), sin(_2462));\n    vec2 dir = _2468;\n    float radius = 1.5;\n    if (mode == 2)\n    {\n        float _2477;\n        if (k < 0.0)\n        {\n            _2477 = (-k) / max(zr, 0.100000001490116119384765625);\n        }\n        else\n        {\n            _2477 = k;\n        }\n        float _2496 = clamp((_2477 * reach) / texel_m, 3.0, 12.0);\n        float sum = 0.0;\n        float cnt = 0.0;\n        for (int i = 0; i < 16; i++)\n        {\n            float _2515 = sqrt((float(i) + 0.5) * 0.0625) * _2496;\n            vec2 param_3 = uv + (dir * (fa_shadows[26].zw * _2515));\n            vec4 param_4 = rect;\n            vec3 param_5 = conv;\n            float _2529 = fa_shadow_fetch(param_3, param_4, param_5);\n            if (_2529 < (zr - (_2515 * plane)))\n            {\n                sum += _2529;\n                cnt += 1.0;\n            }\n            vec2 param_6 = dir;\n            dir = fa_shadow_vogel_turn(param_6);\n        }\n        if (cnt < 0.5)\n        {\n            return 1.0;\n        }\n        float _2557 = sum / cnt;\n        float _2567;\n        if (k < 0.0)\n        {\n            _2567 = (-k) / max(_2557, 0.0500000007450580596923828125);\n        }\n        else\n        {\n            _2567 = k;\n        }\n        radius = clamp(((max(zr - _2557, 0.0) * unit) * _2567) / texel_m, 1.5, 16.0);\n        dir = _2468;\n    }\n    float lit = 0.0;\n    int _2593 = (mode == 2) ? 24 : 16;\n    for (int i_1 = 0; i_1 < _2593; i_1++)\n    {\n        float _2612 = sqrt((float(i_1) + 0.5) / float(_2593)) * radius;\n        vec2 param_7 = uv + (dir * (fa_shadows[26].zw * _2612));\n        vec4 param_8 = rect;\n        vec3 param_9 = conv;\n        lit += float((zr - (_2612 * plane)) <= fa_shadow_fetch(param_7, param_8, param_9));\n        vec2 param_10 = dir;\n        dir = fa_shadow_vogel_turn(param_10);\n    }\n    return lit / float(_2593);\n}\n\nfloat fa_shadow_cascade(int ci, vec3 world, vec3 n, vec3 l)\n{\n    float _2658 = max(fa_shadows[ci * 1 + 20].y, 0.001000000047497451305389404296875);\n    float _2663 = clamp(dot(n, l), 0.0, 1.0);\n    float _2669 = sqrt(1.0 - (_2663 * _2663));\n    float _2677 = min(_2669 / max(_2663, 0.20000000298023223876953125), 4.0);\n    float _2682;\n    if (fa_shadows[26].y > 0.0)\n    {\n        _2682 = fa_shadows[26].y;\n    }\n    else\n    {\n        _2682 = 1.5 * fa_shadows[ci * 1 + 20].x;\n    }\n    vec4 _2707 = mat4(fa_shadows[ci * 4 + 0], fa_shadows[ci * 4 + 1], fa_shadows[ci * 4 + 2], fa_shadows[ci * 4 + 3]) * vec4(world + (n * (_2682 * _2669)), 1.0);\n    float _2714 = _2707.x;\n    bool _2717 = _2714 < fa_shadows[ci * 1 + 16].x;\n    bool _2726;\n    if (!_2717)\n    {\n        _2726 = _2714 > fa_shadows[ci * 1 + 16].z;\n    }\n    else\n    {\n        _2726 = _2717;\n    }\n    bool _2735;\n    if (!_2726)\n    {\n        _2735 = _2707.y < fa_shadows[ci * 1 + 16].y;\n    }\n    else\n    {\n        _2735 = _2726;\n    }\n    bool _2744;\n    if (!_2735)\n    {\n        _2744 = _2707.y > fa_shadows[ci * 1 + 16].w;\n    }\n    else\n    {\n        _2744 = _2735;\n    }\n    bool _2751;\n    if (!_2744)\n    {\n        _2751 = _2707.z > 1.0;\n    }\n    else\n    {\n        _2751 = _2744;\n    }\n    if (_2751)\n    {\n        return -1.0;\n    }\n    float _2759;\n    if (fa_shadows[26].x > 0.0)\n    {\n        _2759 = fa_shadows[26].x;\n    }\n    else\n    {\n        _2759 = 1.5 * fa_shadows[ci * 1 + 20].x;\n    }\n    vec2 param = _2707.xy;\n    vec4 param_1 = fa_shadows[ci * 1 + 16];\n    float param_2 = _2707.z - ((_2759 * (1.0 + (0.5 * _2677))) / _2658);\n    float param_3 = fa_shadows[ci * 1 + 20].x;\n    float param_4 = _2658;\n    float param_5 = _2658 * 0.25;\n    float param_6 = ((fa_shadows[ci * 1 + 20].x * min(_2677, 3.0)) * 0.5) / _2658;\n    vec3 param_7 = vec3(0.0);\n    int param_8 = int(fa_shadows[25].z + 0.5);\n    float param_9 = fa_shadows[25].w;\n    return fa_shadow_filter(param, param_1, param_2, param_3, param_4, param_5, param_6, param_7, param_8, param_9);\n}\n\nfloat fa_shadow_sun(vec3 world, vec3 n, vec3 l)\n{\n    if (fa_mesh_fs_params[5].z < 0.5)\n    {\n        return 1.0;\n    }\n    int _3137 = int(fa_shadows[25].x + 0.5);\n    if (_3137 < 1)\n    {\n        return 1.0;\n    }\n    float _3152 = dot(world - fa_shadows[27].xyz, fa_shadows[28].xyz);\n    int param = _3137 - 1;\n    if (_3152 > fa_shadow_split_at(param))\n    {\n        return 1.0;\n    }\n    int ci = 0;\n    bool _3164 = _3137 > 1;\n    bool _3171;\n    if (_3164)\n    {\n        _3171 = _3152 > fa_shadows[24].x;\n    }\n    else\n    {\n        _3171 = _3164;\n    }\n    if (_3171)\n    {\n        ci = 1;\n    }\n    bool _3175 = _3137 > 2;\n    bool _3182;\n    if (_3175)\n    {\n        _3182 = _3152 > fa_shadows[24].y;\n    }\n    else\n    {\n        _3182 = _3175;\n    }\n    if (_3182)\n    {\n        ci = 2;\n    }\n    bool _3186 = _3137 > 3;\n    bool _3193;\n    if (_3186)\n    {\n        _3193 = _3152 > fa_shadows[24].z;\n    }\n    else\n    {\n        _3193 = _3186;\n    }\n    if (_3193)\n    {\n        ci = 3;\n    }\n    float s = -1.0;\n    float s2 = -1.0;\n    float t = 0.0;\n    int _3204 = min(_3137, 4);\n    float _3245;\n    for (int c = ci; c < _3204; c++)\n    {\n        int param_1 = c;\n        vec3 param_2 = world;\n        vec3 param_3 = n;\n        vec3 param_4 = l;\n        float _3224 = fa_shadow_cascade(param_1, param_2, param_3, param_4);\n        if (s >= 0.0)\n        {\n            s2 = _3224;\n            break;\n        }\n        if (_3224 < 0.0)\n        {\n            continue;\n        }\n        s = _3224;\n        ci = c;\n        if (fa_shadows[25].y > 0.0)\n        {\n            if (ci > 0)\n            {\n                int param_5 = ci - 1;\n                _3245 = fa_shadow_split_at(param_5);\n            }\n            else\n            {\n                _3245 = fa_shadows[28].w;\n            }\n            int param_6 = ci;\n            float _3264 = fa_shadows[25].y * max(fa_shadow_split_at(param_6) - _3245, 9.9999997473787516355514526367188e-05);\n            int param_7 = ci;\n            t = clamp((_3152 - (fa_shadow_split_at(param_7) - _3264)) / _3264, 0.0, 1.0);\n        }\n        if (t <= 0.0)\n        {\n            break;\n        }\n    }\n    if (s < 0.0)\n    {\n        return 1.0;\n    }\n    if (t > 0.0)\n    {\n        float _3296;\n        if ((ci + 1) < _3137)\n        {\n            _3296 = (s2 < 0.0) ? s : s2;\n        }\n        else\n        {\n            _3296 = 1.0;\n        }\n        s = mix(s, _3296, t);\n    }\n    return s;\n}\n\nfloat fa_shadow_factor(vec3 n, vec3 l)\n{\n    bool _3401 = fa_mesh_fs_params[25].y > 0.5;\n    bool _3407;\n    if (_3401)\n    {\n        _3407 = fa_mesh_fs_params[5].z > 0.5;\n    }\n    else\n    {\n        _3407 = _3401;\n    }\n    if (_3407)\n    {\n        float _3421 = dot(fa_mesh_fs_params[29].xyz, fa_world_pos) + fa_mesh_fs_params[29].w;\n        vec4 _3429 = vec4(fa_world_pos, 1.0);\n        float _3435 = dot(fa_mesh_fs_params[28], _3429);\n        if (_3435 > 9.9999997473787516355514526367188e-05)\n        {\n            vec2 _3454 = vec2(dot(fa_mesh_fs_params[26], _3429), dot(fa_mesh_fs_params[27], _3429)) / vec2(_3435);\n            float _3459 = (_3454.x * 0.5) + 0.5;\n            float _3463;\n            if (fa_mesh_fs_params[24].y > 0.5)\n            {\n                _3463 = (_3454.y * 0.5) + 0.5;\n            }\n            else\n            {\n                _3463 = 0.5 - (_3454.y * 0.5);\n            }\n            bool _3479 = _3459 >= 0.0;\n            bool _3485;\n            if (_3479)\n            {\n                _3485 = _3459 < 1.0;\n            }\n            else\n            {\n                _3485 = _3479;\n            }\n            bool _3491;\n            if (_3485)\n            {\n                _3491 = _3463 >= 0.0;\n            }\n            else\n            {\n                _3491 = _3485;\n            }\n            bool _3497;\n            if (_3491)\n            {\n                _3497 = _3463 < 1.0;\n            }\n            else\n            {\n                _3497 = _3491;\n            }\n            if (_3497)\n            {\n                vec4 _3522 = texelFetch(fa_screen_tex_fa_shadow_smp, clamp(ivec2(vec2(_3459, _3463) * fa_mesh_fs_params[24].zw), ivec2(0), ivec2(fa_mesh_fs_params[24].zw) - ivec2(1)), 0);\n                bool _3525 = _3522.w > 0.5;\n                bool _3541;\n                if (_3525)\n                {\n                    _3541 = abs(_3421 - _3522.x) <= (((0.00200000009499490261077880859375 * _3421) + 0.00999999977648258209228515625) + fa_rt_slope);\n                }\n                else\n                {\n                    _3541 = _3525;\n                }\n                if (_3541)\n                {\n                    float _3547;\n                    if (fa_mesh_fs_params[25].z > 0.5)\n                    {\n                        vec3 param = fa_world_pos;\n                        vec3 param_1 = n;\n                        vec3 param_2 = l;\n                        _3547 = min(_3522.y, fa_shadow_sun(param, param_1, param_2));\n                    }\n                    else\n                    {\n                        _3547 = _3522.y;\n                    }\n                    return _3547;\n                }\n            }\n        }\n    }\n    vec3 param_3 = fa_world_pos;\n    vec3 param_4 = n;\n    vec3 param_5 = l;\n    return fa_shadow_sun(param_3, param_4, param_5);\n}\n\nfloat fa_rt_local_tap(ivec2 p, ivec2 size, float d, float tol, float div, inout float best)\n{\n    vec4 _3584 = texelFetch(fa_screen_tex_fa_shadow_smp, clamp(p, ivec2(0), size - ivec2(1)), 0);\n    bool _3587 = _3584.w > 0.5;\n    bool _3597;\n    if (_3587)\n    {\n        _3597 = abs(d - _3584.x) <= tol;\n    }\n    else\n    {\n        _3597 = _3587;\n    }\n    if (_3597)\n    {\n        best = min(best, mod(floor(_3584.z / div), 256.0) * 0.0039215688593685626983642578125);\n    }\n    return best;\n}\n\nfloat fa_shadow_local(int li, vec3 lpos, vec3 world, vec3 n, vec3 l)\n{\n    bool _2817 = fa_mesh_fs_params[5].z < 0.5;\n    bool _2824;\n    if (!_2817)\n    {\n        _2824 = fa_shadows[29].x < 0.5;\n    }\n    else\n    {\n        _2824 = _2817;\n    }\n    if (_2824)\n    {\n        return 1.0;\n    }\n    int param = (int(fa_shadows[29].x + 0.5) - 1) + li;\n    vec4 _2837 = fa_light_texel(param);\n    float _2838 = _2837.x;\n    if (_2838 < 0.0)\n    {\n        return 1.0;\n    }\n    int _2847 = int(_2838 + 0.5);\n    int param_1 = _2847;\n    vec4 _2851 = fa_light_texel(param_1);\n    int param_2 = _2847 + 1;\n    vec4 _2856 = fa_light_texel(param_2);\n    float fade = 1.0;\n    float _2859 = _2851.y;\n    if (_2859 > 0.0)\n    {\n        float _2876 = 1.0 - smoothstep(0.75 * _2859, _2859, length(world - fa_shadows[27].xyz));\n        fade = _2876;\n        if (_2876 <= 0.0)\n        {\n            return 1.0;\n        }\n    }\n    int face = 0;\n    if (_2851.x > 1.5)\n    {\n        vec3 param_3 = world - lpos;\n        face = fa_cube_face(param_3);\n    }\n    int _2900 = (_2847 + 2) + (face * 6);\n    int param_4 = _2900;\n    int param_5 = _2900 + 1;\n    int param_6 = _2900 + 3;\n    vec4 _2914 = fa_light_texel(param_6);\n    int param_7 = _2900 + 4;\n    vec4 _2919 = fa_light_texel(param_7);\n    int param_8 = _2900 + 5;\n    vec4 _2924 = fa_light_texel(param_8);\n    float _2936 = _2924.x * max(dot(_2914, vec4(world, 1.0)), 0.001000000047497451305389404296875);\n    float _2941 = clamp(dot(n, l), 0.0, 1.0);\n    float _2964 = clamp(dot(n, _2914.xyz), -1.0, 1.0);\n    float _2983 = min(sqrt(1.0 - (_2964 * _2964)) / max(abs(dot(n, world - lpos)) / max(dot(_2914, vec4(world, 1.0)), 0.001000000047497451305389404296875), 0.20000000298023223876953125), 4.0);\n    float _2986 = _2856.y;\n    float _2988;\n    if (_2986 > 0.0)\n    {\n        _2988 = _2986;\n    }\n    else\n    {\n        _2988 = 1.5 * _2936;\n    }\n    vec4 _3008 = vec4(world + (n * (_2988 * sqrt(1.0 - (_2941 * _2941)))), 1.0);\n    float _3012 = dot(_2914, _3008);\n    float _3015 = _2924.y;\n    if (_3012 < _3015)\n    {\n        return 1.0;\n    }\n    vec2 _3030 = vec2(dot(fa_light_texel(param_4), _3008), dot(fa_light_texel(param_5), _3008)) / vec2(_3012);\n    float _3032 = _3030.x;\n    bool _3035 = _3032 < _2919.x;\n    bool _3044;\n    if (!_3035)\n    {\n        _3044 = _3032 > _2919.z;\n    }\n    else\n    {\n        _3044 = _3035;\n    }\n    bool _3053;\n    if (!_3044)\n    {\n        _3053 = _3030.y < _2919.y;\n    }\n    else\n    {\n        _3053 = _3044;\n    }\n    bool _3062;\n    if (!_3053)\n    {\n        _3062 = _3030.y > _2919.w;\n    }\n    else\n    {\n        _3062 = _3053;\n    }\n    if (_3062)\n    {\n        return 1.0;\n    }\n    float _3068 = _2856.x;\n    float _3070;\n    if (_3068 > 0.0)\n    {\n        _3070 = _3068;\n    }\n    else\n    {\n        _3070 = 1.5 * _2936;\n    }\n    vec2 param_9 = _3030;\n    vec4 param_10 = _2919;\n    float param_11 = _3012 - (_3070 * (1.0 + (0.5 * _2983)));\n    float param_12 = _2936;\n    float param_13 = 1.0;\n    float param_14 = _2924.z * 0.25;\n    float param_15 = (_2936 * min(_2983, 3.0)) * 0.5;\n    vec3 param_16 = vec3(1.0, _3015, _2924.z);\n    int param_17 = int(_2851.z + 0.5);\n    float param_18 = _2851.w;\n    return mix(1.0, fa_shadow_filter(param_9, param_10, param_11, param_12, param_13, param_14, param_15, param_16, param_17, param_18), fade);\n}\n\nfloat fa_shadow_local_rt(int li, vec3 lpos, vec3 world, vec3 n, vec3 l)\n{\n    bool _3615 = fa_mesh_fs_params[25].w > 0.5;\n    bool _3621;\n    if (_3615)\n    {\n        _3621 = fa_mesh_fs_params[5].z > 0.5;\n    }\n    else\n    {\n        _3621 = _3615;\n    }\n    bool _3627;\n    if (_3621)\n    {\n        _3627 = fa_shadows[29].x > 0.5;\n    }\n    else\n    {\n        _3627 = _3621;\n    }\n    if (_3627)\n    {\n        int param = (int(fa_shadows[29].x + 0.5) - 1) + li;\n        vec4 _3639 = fa_light_texel(param);\n        float _3640 = _3639.z;\n        if (_3640 > 0.5)\n        {\n            float _3653 = dot(fa_mesh_fs_params[29].xyz, world) + fa_mesh_fs_params[29].w;\n            float _3659 = ((0.00200000009499490261077880859375 * _3653) + 0.00999999977648258209228515625) + fa_rt_slope;\n            vec4 _3665 = vec4(world, 1.0);\n            float _3670 = dot(fa_mesh_fs_params[28], _3665);\n            if (_3670 > 9.9999997473787516355514526367188e-05)\n            {\n                vec2 _3687 = vec2(dot(fa_mesh_fs_params[26], _3665), dot(fa_mesh_fs_params[27], _3665)) / vec2(_3670);\n                float _3692 = (_3687.x * 0.5) + 0.5;\n                float _3696;\n                if (fa_mesh_fs_params[24].y > 0.5)\n                {\n                    _3696 = (_3687.y * 0.5) + 0.5;\n                }\n                else\n                {\n                    _3696 = 0.5 - (_3687.y * 0.5);\n                }\n                bool _3712 = _3692 >= 0.0;\n                bool _3718;\n                if (_3712)\n                {\n                    _3718 = _3692 < 1.0;\n                }\n                else\n                {\n                    _3718 = _3712;\n                }\n                bool _3724;\n                if (_3718)\n                {\n                    _3724 = _3696 >= 0.0;\n                }\n                else\n                {\n                    _3724 = _3718;\n                }\n                bool _3730;\n                if (_3724)\n                {\n                    _3730 = _3696 < 1.0;\n                }\n                else\n                {\n                    _3730 = _3724;\n                }\n                if (_3730)\n                {\n                    ivec2 _3737 = ivec2(fa_mesh_fs_params[24].zw);\n                    ivec2 _3748 = clamp(ivec2(vec2(_3692, _3696) * fa_mesh_fs_params[24].zw), ivec2(0), _3737 - ivec2(1));\n                    float _3752;\n                    if (_3640 < 1.5)\n                    {\n                        _3752 = 1.0;\n                    }\n                    else\n                    {\n                        _3752 = (_3640 < 2.5) ? 256.0 : 65536.0;\n                    }\n                    float best = 2.0;\n                    vec4 _3768 = texelFetch(fa_screen_tex_fa_shadow_smp, _3748, 0);\n                    bool _3771 = _3768.w > 0.5;\n                    bool _3781;\n                    if (_3771)\n                    {\n                        _3781 = abs(_3653 - _3768.x) <= _3659;\n                    }\n                    else\n                    {\n                        _3781 = _3771;\n                    }\n                    if (_3781)\n                    {\n                        best = mod(floor(_3768.z / _3752), 256.0) * 0.0039215688593685626983642578125;\n                    }\n                    else\n                    {\n                        ivec2 param_1 = _3748 + ivec2(-1);\n                        ivec2 param_2 = _3737;\n                        float param_3 = _3653;\n                        float param_4 = _3659;\n                        float param_5 = _3752;\n                        float param_6 = best;\n                        float _3807 = fa_rt_local_tap(param_1, param_2, param_3, param_4, param_5, param_6);\n                        best = _3807;\n                        ivec2 param_7 = _3748 + ivec2(0, -1);\n                        ivec2 param_8 = _3737;\n                        float param_9 = _3653;\n                        float param_10 = _3659;\n                        float param_11 = _3752;\n                        float param_12 = _3807;\n                        float _3822 = fa_rt_local_tap(param_7, param_8, param_9, param_10, param_11, param_12);\n                        best = _3822;\n                        ivec2 param_13 = _3748 + ivec2(1, -1);\n                        ivec2 param_14 = _3737;\n                        float param_15 = _3653;\n                        float param_16 = _3659;\n                        float param_17 = _3752;\n                        float param_18 = _3822;\n                        float _3837 = fa_rt_local_tap(param_13, param_14, param_15, param_16, param_17, param_18);\n                        best = _3837;\n                        ivec2 param_19 = _3748 + ivec2(-1, 0);\n                        ivec2 param_20 = _3737;\n                        float param_21 = _3653;\n                        float param_22 = _3659;\n                        float param_23 = _3752;\n                        float param_24 = _3837;\n                        float _3852 = fa_rt_local_tap(param_19, param_20, param_21, param_22, param_23, param_24);\n                        best = _3852;\n                        ivec2 param_25 = _3748 + ivec2(1, 0);\n                        ivec2 param_26 = _3737;\n                        float param_27 = _3653;\n                        float param_28 = _3659;\n                        float param_29 = _3752;\n                        float param_30 = _3852;\n                        float _3867 = fa_rt_local_tap(param_25, param_26, param_27, param_28, param_29, param_30);\n                        best = _3867;\n                        ivec2 param_31 = _3748 + ivec2(-1, 1);\n                        ivec2 param_32 = _3737;\n                        float param_33 = _3653;\n                        float param_34 = _3659;\n                        float param_35 = _3752;\n                        float param_36 = _3867;\n                        float _3882 = fa_rt_local_tap(param_31, param_32, param_33, param_34, param_35, param_36);\n                        best = _3882;\n                        ivec2 param_37 = _3748 + ivec2(0, 1);\n                        ivec2 param_38 = _3737;\n                        float param_39 = _3653;\n                        float param_40 = _3659;\n                        float param_41 = _3752;\n                        float param_42 = _3882;\n                        float _3897 = fa_rt_local_tap(param_37, param_38, param_39, param_40, param_41, param_42);\n                        best = _3897;\n                        ivec2 param_43 = _3748 + ivec2(1);\n                        ivec2 param_44 = _3737;\n                        float param_45 = _3653;\n                        float param_46 = _3659;\n                        float param_47 = _3752;\n                        float param_48 = _3897;\n                        float _3912 = fa_rt_local_tap(param_43, param_44, param_45, param_46, param_47, param_48);\n                        best = _3912;\n                    }\n                    if (best <= 1.0)\n                    {\n                        float _3920;\n                        if (fa_mesh_fs_params[25].z > 0.5)\n                        {\n                            int param_49 = li;\n                            vec3 param_50 = lpos;\n                            vec3 param_51 = world;\n                            vec3 param_52 = n;\n                            vec3 param_53 = l;\n                            _3920 = min(best, fa_shadow_local(param_49, param_50, param_51, param_52, param_53));\n                        }\n                        else\n                        {\n                            _3920 = best;\n                        }\n                        return _3920;\n                    }\n                }\n            }\n            float _3943;\n            if (fa_mesh_fs_params[25].z > 0.5)\n            {\n                int param_54 = li;\n                vec3 param_55 = lpos;\n                vec3 param_56 = world;\n                vec3 param_57 = n;\n                vec3 param_58 = l;\n                _3943 = fa_shadow_local(param_54, param_55, param_56, param_57, param_58);\n            }\n            else\n            {\n                _3943 = 1.0;\n            }\n            return _3943;\n        }\n    }\n    int param_59 = li;\n    vec3 param_60 = lpos;\n    vec3 param_61 = world;\n    vec3 param_62 = n;\n    vec3 param_63 = l;\n    return fa_shadow_local(param_59, param_60, param_61, param_62, param_63);\n}\n\nfloat fa_contact_shadow(int li, vec3 world, vec3 gn, vec3 l, float dist)\n{\n    bool _5788 = fa_mesh_fs_params[24].x < 0.5;\n    bool _5795;\n    if (!_5788)\n    {\n        _5795 = fa_shadows[29].x < 0.5;\n    }\n    else\n    {\n        _5795 = _5788;\n    }\n    if (_5795)\n    {\n        return 1.0;\n    }\n    int param = (int(fa_shadows[29].x + 0.5) - 1) + li;\n    vec4 _5808 = fa_light_texel(param);\n    float _5809 = _5808.y;\n    float len = _5809;\n    if (_5809 <= 0.0)\n    {\n        return 1.0;\n    }\n    float _5821 = length(world - fa_mesh_fs_params[0].xyz);\n    float _5830 = 1.0 - smoothstep(0.5 * fa_mesh_fs_params[25].x, fa_mesh_fs_params[25].x, _5821);\n    if (_5830 <= 0.0)\n    {\n        return 1.0;\n    }\n    float _5836 = len;\n    float _5839 = min(_5836, 0.89999997615814208984375 * dist);\n    len = _5839;\n    float _5844 = 0.004999999888241291046142578125 + (0.0030000000260770320892333984375 * _5821);\n    float _5849 = _5844 + (0.5 * _5839);\n    vec3 _5855 = world + (gn * _5844);\n    float _5857 = fa_shadow_noise();\n    float occ = 0.0;\n    float _5918;\n    for (int k = 0; k < 12; k++)\n    {\n        float _5872 = (float(k) + _5857) * 0.083333335816860198974609375;\n        vec3 _5880 = _5855 + (l * (_5872 * len));\n        vec4 _5886 = vec4(_5880, 1.0);\n        float _5891 = dot(fa_mesh_fs_params[28], _5886);\n        if (_5891 < 9.9999997473787516355514526367188e-05)\n        {\n            break;\n        }\n        vec2 _5909 = vec2(dot(fa_mesh_fs_params[26], _5886), dot(fa_mesh_fs_params[27], _5886)) / vec2(_5891);\n        float _5913 = _5909.x * 0.5;\n        float _5914 = _5913 + 0.5;\n        if (fa_mesh_fs_params[24].y > 0.5)\n        {\n            _5918 = (_5909.y * 0.5) + 0.5;\n        }\n        else\n        {\n            _5918 = 0.5 - (_5909.y * 0.5);\n        }\n        bool _5934 = _5914 < 0.0;\n        bool _5941;\n        if (!_5934)\n        {\n            _5941 = _5914 >= 1.0;\n        }\n        else\n        {\n            _5941 = _5934;\n        }\n        bool _5948;\n        if (!_5941)\n        {\n            _5948 = _5918 < 0.0;\n        }\n        else\n        {\n            _5948 = _5941;\n        }\n        bool _5955;\n        if (!_5948)\n        {\n            _5955 = _5918 >= 1.0;\n        }\n        else\n        {\n            _5955 = _5948;\n        }\n        if (_5955)\n        {\n            break;\n        }\n        vec4 _5979 = texelFetch(fa_screen_tex_fa_shadow_smp, clamp(ivec2(vec2(_5914, _5918) * fa_mesh_fs_params[24].zw), ivec2(0), ivec2(fa_mesh_fs_params[24].zw) - ivec2(1)), 0);\n        if (_5979.w < 0.5)\n        {\n            continue;\n        }\n        float _5997 = (dot(fa_mesh_fs_params[29].xyz, _5880) + fa_mesh_fs_params[29].w) - _5979.x;\n        if ((_5997 > _5844) && (_5997 < _5849))\n        {\n            occ = max(occ, (1.0 - (_5872 * _5872)) * smoothstep(0.0, 0.0500000007450580596923828125, min(min(_5914, 0.5 - _5913), min(_5918, 1.0 - _5918))));\n        }\n    }\n    return 1.0 - (occ * _5830);\n}\n\nLightSample fa_light_shadowed(int li, vec3 world_pos, vec3 gn)\n{\n    int param = li;\n    float _6659 = fa_baked_keep(param);\n    if (_6659 <= 0.0)\n    {\n        int param_1 = li;\n        return LightSample(vec3(0.0, 1.0, 0.0), vec3(0.0), 0.0, 1.0, 0.0, int(fa_light_type(param_1) + 0.5));\n    }\n    int param_2 = li;\n    vec3 param_3 = world_pos;\n    vec3 param_4 = gn;\n    LightSample _6685 = fa_light_sample_n(param_2, param_3, param_4);\n    vec3 _9955 = _6685.color;\n    float _9956 = _6685.attenuation;\n    float _9957 = _6685.shadow;\n    bool _6688 = _6685.type == 0;\n    if (_6688 && (li == 0))\n    {\n        vec3 param_5 = gn;\n        vec3 param_6 = _6685.direction;\n        float _6699 = fa_shadow_factor(param_5, param_6);\n        _9957 = _6699;\n        _9955 *= _6699;\n    }\n    else\n    {\n        bool _6710 = _6685.type != 0;\n        bool _6716;\n        if (_6710)\n        {\n            _6716 = _9956 > 0.0;\n        }\n        else\n        {\n            _6716 = _6710;\n        }\n        if (_6716)\n        {\n            int param_7 = li;\n            int param_8 = fa_light_base(param_7);\n            int param_9 = li;\n            vec3 param_10 = fa_light_texel(param_8).xyz;\n            vec3 param_11 = world_pos;\n            vec3 param_12 = gn;\n            vec3 param_13 = _6685.direction;\n            float _6735 = fa_shadow_local_rt(param_9, param_10, param_11, param_12, param_13);\n            _9957 = _6735;\n            _9955 *= _6735;\n        }\n    }\n    bool _6745 = fa_mesh_fs_params[24].x > 0.5;\n    bool _6751;\n    if (_6745)\n    {\n        _6751 = _9956 > 0.0;\n    }\n    else\n    {\n        _6751 = _6745;\n    }\n    if (_6751)\n    {\n        float _6758;\n        if (_6688)\n        {\n            _6758 = 1000000000.0;\n        }\n        else\n        {\n            _6758 = _6685._distance;\n        }\n        int param_14 = li;\n        vec3 param_15 = world_pos;\n        vec3 param_16 = gn;\n        vec3 param_17 = _6685.direction;\n        float param_18 = _6758;\n        float _6776 = fa_contact_shadow(param_14, param_15, param_16, param_17, param_18);\n        _9957 *= _6776;\n        _9955 *= _6776;\n    }\n    float _6789 = _9956;\n    float _6790 = _6789 * _6659;\n    _9956 = _6790;\n    vec3 _6794 = _9955;\n    vec3 _6795 = _6794 * _6659;\n    _9955 = _6795;\n    return LightSample(_6685.direction, _6795, _6790, _9957, _6685._distance, _6685.type);\n}\n\nvec3 fa_ltc_tangent(vec3 n, vec3 v)\n{\n    vec3 _6829 = v - (n * dot(v, n));\n    vec3 t = _6829;\n    float _6833 = dot(_6829, _6829);\n    float l2 = _6833;\n    if (_6833 < 1.0000000133514319600180897396058e-10)\n    {\n        vec3 _6843;\n        if (abs(n.z) < 0.999000012874603271484375)\n        {\n            _6843 = cross(n, vec3(0.0, 0.0, 1.0));\n        }\n        else\n        {\n            _6843 = cross(n, vec3(1.0, 0.0, 0.0));\n        }\n        t = _6843;\n        l2 = dot(_6843, _6843);\n    }\n    return t * inversesqrt(l2);\n}\n\nvec3 fa_ltc_local(vec3 t1, vec3 n, vec3 p)\n{\n    return vec3(dot(t1, p), dot(cross(n, t1), p), dot(n, p));\n}\n\nvec2 fa_ltc_uv(float roughness, float ndv)\n{\n    return ((vec2(clamp((roughness - 0.0500000007450580596923828125) * 1.0526316165924072265625, 0.0, 1.0), sqrt(clamp(1.0 - ndv, 0.0, 1.0))) * 63.0) + vec2(0.5)) * vec2(0.015625);\n}\n\nvec3 fa_oct_vertex(int j, vec3 pc, vec3 ex, vec3 ey)\n{\n    float _7230;\n    if ((j == 0) || (j == 7))\n    {\n        _7230 = 0.92387950420379638671875;\n    }\n    else\n    {\n        float _7240;\n        if ((j == 3) || (j == 4))\n        {\n            _7240 = -0.92387950420379638671875;\n        }\n        else\n        {\n            _7240 = ((j == 1) || (j == 6)) ? 0.3826834261417388916015625 : (-0.3826834261417388916015625);\n        }\n        _7230 = _7240;\n    }\n    float _7261;\n    if ((j == 1) || (j == 2))\n    {\n        _7261 = 0.92387950420379638671875;\n    }\n    else\n    {\n        float _7270;\n        if ((j == 5) || (j == 6))\n        {\n            _7270 = -0.92387950420379638671875;\n        }\n        else\n        {\n            _7270 = ((j == 0) || (j == 3)) ? 0.3826834261417388916015625 : (-0.3826834261417388916015625);\n        }\n        _7261 = _7270;\n    }\n    return (pc + (ex * _7230)) + (ey * _7261);\n}\n\nvec3 fa_ltc_edge_vector(vec3 a, vec3 b)\n{\n    float _6878 = dot(a, a);\n    float _6882 = dot(b, b);\n    if ((_6878 < 1.0000000195414813782625560981111e-24) || (_6882 < 1.0000000195414813782625560981111e-24))\n    {\n        return vec3(0.0);\n    }\n    vec3 _6896 = a * inversesqrt(_6878);\n    vec3 _6901 = b * inversesqrt(_6882);\n    float _6905 = dot(_6896, _6901);\n    float _6908 = abs(_6905);\n    float g = (((((((((((0.0416471660137176513671875 * _6908) - 0.1924748718738555908203125) * _6908) + 0.4179156124591827392578125) * _6908) - 0.616057217121124267578125) * _6908) + 0.777722418308258056640625) * _6908) - 0.999542415142059326171875) * _6908) + 1.570791721343994140625;\n    if (_6905 < 0.0)\n    {\n        g = (3.1415927410125732421875 * inversesqrt(max(1.0 - (_6905 * _6905), 1.0000000116860974230803549289703e-07))) - g;\n    }\n    return cross(_6896, _6901) * g;\n}\n\nvoid fa_ltc_clip_edge(vec3 a, vec3 b, inout vec3 sum, inout vec3 leave, inout vec3 enter, inout vec2 seen)\n{\n    bool _6965 = a.z > 0.0;\n    bool _6969 = b.z > 0.0;\n    if (_6965 && _6969)\n    {\n        vec3 param = a;\n        vec3 param_1 = b;\n        sum += fa_ltc_edge_vector(param, param_1);\n    }\n    else\n    {\n        if (_6965 != _6969)\n        {\n            vec3 _7004 = a + ((b - a) * (a.z / (a.z - b.z)));\n            _7004.z = 0.0;\n            if (_6965)\n            {\n                vec3 param_2 = a;\n                vec3 param_3 = _7004;\n                sum += fa_ltc_edge_vector(param_2, param_3);\n                leave = _7004;\n                seen.x = 1.0;\n            }\n            else\n            {\n                vec3 param_4 = _7004;\n                vec3 param_5 = b;\n                sum += fa_ltc_edge_vector(param_4, param_5);\n                enter = _7004;\n                seen.y = 1.0;\n            }\n        }\n    }\n}\n\nfloat fa_ltc_quad(vec4 abcd, vec3 p0, vec3 p1, vec3 p2, vec3 p3)\n{\n    vec3 _7053 = vec3((abcd.x * p0.x) + (abcd.y * p0.z), p0.y, (abcd.z * p0.x) + (abcd.w * p0.z));\n    vec3 _7079 = vec3((abcd.x * p1.x) + (abcd.y * p1.z), p1.y, (abcd.z * p1.x) + (abcd.w * p1.z));\n    vec3 _7105 = vec3((abcd.x * p2.x) + (abcd.y * p2.z), p2.y, (abcd.z * p2.x) + (abcd.w * p2.z));\n    vec3 _7131 = vec3((abcd.x * p3.x) + (abcd.y * p3.z), p3.y, (abcd.z * p3.x) + (abcd.w * p3.z));\n    vec3 sum = vec3(0.0);\n    vec3 leave = vec3(0.0);\n    vec3 enter = vec3(0.0);\n    vec3 param = _7053;\n    vec3 param_1 = _7079;\n    vec3 param_2 = vec3(0.0);\n    vec3 param_3 = vec3(0.0);\n    vec3 param_4 = vec3(0.0);\n    vec2 param_5 = vec2(0.0);\n    fa_ltc_clip_edge(param, param_1, param_2, param_3, param_4, param_5);\n    sum = param_2;\n    leave = param_3;\n    enter = param_4;\n    vec3 param_6 = _7079;\n    vec3 param_7 = _7105;\n    vec3 param_8 = param_2;\n    vec3 param_9 = param_3;\n    vec3 param_10 = param_4;\n    vec2 param_11 = param_5;\n    fa_ltc_clip_edge(param_6, param_7, param_8, param_9, param_10, param_11);\n    sum = param_8;\n    leave = param_9;\n    enter = param_10;\n    vec3 param_12 = _7105;\n    vec3 param_13 = _7131;\n    vec3 param_14 = param_8;\n    vec3 param_15 = param_9;\n    vec3 param_16 = param_10;\n    vec2 param_17 = param_11;\n    fa_ltc_clip_edge(param_12, param_13, param_14, param_15, param_16, param_17);\n    sum = param_14;\n    leave = param_15;\n    enter = param_16;\n    vec3 param_18 = _7131;\n    vec3 param_19 = _7053;\n    vec3 param_20 = param_14;\n    vec3 param_21 = param_15;\n    vec3 param_22 = param_16;\n    vec2 param_23 = param_17;\n    fa_ltc_clip_edge(param_18, param_19, param_20, param_21, param_22, param_23);\n    sum = param_20;\n    leave = param_21;\n    enter = param_22;\n    if ((param_23.x * param_23.y) > 0.5)\n    {\n        vec3 param_24 = leave;\n        vec3 param_25 = enter;\n        sum += fa_ltc_edge_vector(param_24, param_25);\n    }\n    return sum.z * 0.15915493667125701904296875;\n}\n\nvec2 fa_area_forms(vec4 m, float shape, vec3 pc, vec3 ex, vec3 ey)\n{\n    int _7299 = ((shape < 0.5) || (shape > 1.5)) ? 1 : 3;\n    vec2 sum = vec2(0.0);\n    int _7317;\n    for (int k = 0; k < (2 * _7299); k++)\n    {\n        bool _7314 = k >= _7299;\n        if (_7314)\n        {\n            _7317 = k - _7299;\n        }\n        else\n        {\n            _7317 = k;\n        }\n        vec3 p0 = (pc - ex) - ey;\n        vec3 p1 = (pc + ex) - ey;\n        vec3 p2 = (pc + ex) + ey;\n        vec3 p3 = (pc - ex) + ey;\n        if (_7299 == 3)\n        {\n            int param = 0;\n            vec3 param_1 = pc;\n            vec3 param_2 = ex;\n            vec3 param_3 = ey;\n            p0 = fa_oct_vertex(param, param_1, param_2, param_3);\n            int _7363 = 2 * _7317;\n            int param_4 = _7363 + 1;\n            vec3 param_5 = pc;\n            vec3 param_6 = ex;\n            vec3 param_7 = ey;\n            p1 = fa_oct_vertex(param_4, param_5, param_6, param_7);\n            int param_8 = _7363 + 2;\n            vec3 param_9 = pc;\n            vec3 param_10 = ex;\n            vec3 param_11 = ey;\n            p2 = fa_oct_vertex(param_8, param_9, param_10, param_11);\n            int param_12 = _7363 + 3;\n            vec3 param_13 = pc;\n            vec3 param_14 = ex;\n            vec3 param_15 = ey;\n            p3 = fa_oct_vertex(param_12, param_13, param_14, param_15);\n        }\n        bvec4 _7400 = bvec4(_7314);\n        vec4 param_16 = vec4(_7400.x ? m.x : vec4(1.0, 0.0, 0.0, 1.0).x, _7400.y ? m.y : vec4(1.0, 0.0, 0.0, 1.0).y, _7400.z ? m.z : vec4(1.0, 0.0, 0.0, 1.0).z, _7400.w ? m.w : vec4(1.0, 0.0, 0.0, 1.0).w);\n        vec3 param_17 = p0;\n        vec3 param_18 = p1;\n        vec3 param_19 = p2;\n        vec3 param_20 = p3;\n        float _7411 = fa_ltc_quad(param_16, param_17, param_18, param_19, param_20);\n        if (_7314)\n        {\n            vec2 _10211 = sum;\n            _10211.y = _10211.y + _7411;\n            sum = _10211;\n        }\n        else\n        {\n            vec2 _10214 = sum;\n            _10214.x = _10214.x + _7411;\n            sum = _10214;\n        }\n    }\n    return abs(sum);\n}\n\nvec3 fa_area_shade(int li, vec3 world_pos, vec3 n, vec3 v, vec3 diffuse_color, vec3 f0, float f90, float roughness, float ndv, float window)\n{\n    int param = li;\n    int _7435 = fa_light_base(param);\n    int param_1 = _7435;\n    int param_2 = _7435 + 1;\n    int param_3 = _7435 + 2;\n    int param_4 = _7435 + 4;\n    vec4 _7457 = fa_light_texel(param_4);\n    int param_5 = _7435 + 5;\n    vec4 _7462 = fa_light_texel(param_5);\n    int param_6 = _7435 + 6;\n    vec4 _7467 = fa_light_texel(param_6);\n    float _7468 = _7467.w;\n    vec3 _7473 = fa_light_texel(param_1).xyz - world_pos;\n    bool _7475 = _7468 < 1.5;\n    bool _7482;\n    if (_7475)\n    {\n        _7482 = dot(normalize(fa_light_texel(param_3).xyz), _7473) >= 0.0;\n    }\n    else\n    {\n        _7482 = _7475;\n    }\n    if (_7482)\n    {\n        return vec3(0.0);\n    }\n    bool _7491 = (_7468 > 0.5) && _7475;\n    float _7495 = _7491 ? 1.0539000034332275390625 : 1.0;\n    vec3 _7498 = _7457.xyz;\n    float _7500 = _7457.w;\n    vec3 _7506 = _7462.xyz;\n    float _7508 = _7462.w;\n    vec3 up = _7506 * (_7508 * _7495);\n    float _7514;\n    if (_7491)\n    {\n        _7514 = (3.1415927410125732421875 * _7500) * _7500;\n    }\n    else\n    {\n        _7514 = (4.0 * _7500) * _7508;\n    }\n    if (_7468 > 1.5)\n    {\n        vec3 _7540 = cross(_7498, -_7473);\n        vec3 perp = _7540;\n        float _7544 = dot(_7540, _7540);\n        vec3 _7547;\n        if (_7544 > 1.0000000133514319600180897396058e-10)\n        {\n            _7547 = perp * inversesqrt(_7544);\n        }\n        else\n        {\n            _7547 = _7506;\n        }\n        perp = _7547;\n        up = _7547 * _7508;\n    }\n    float _7568 = max(_7514, 9.9999999747524270787835121154785e-07);\n    vec3 param_7 = n;\n    vec3 param_8 = v;\n    vec3 _7578 = fa_ltc_tangent(param_7, param_8);\n    vec3 param_9 = _7578;\n    vec3 param_10 = n;\n    vec3 param_11 = _7473;\n    vec3 param_12 = _7578;\n    vec3 param_13 = n;\n    vec3 param_14 = _7498 * (_7500 * _7495);\n    vec3 param_15 = _7578;\n    vec3 param_16 = n;\n    vec3 param_17 = up;\n    float param_18 = roughness;\n    float param_19 = ndv;\n    vec2 _7609 = fa_ltc_uv(param_18, param_19) * 64.0;\n    vec2 param_20 = _7609;\n    vec2 param_21 = _7609 + vec2(64.0, 0.0);\n    vec4 _7619 = fa_atlas_fetch(param_21);\n    vec4 param_22 = fa_atlas_fetch(param_20);\n    float param_23 = _7468;\n    vec3 param_24 = fa_ltc_local(param_9, param_10, param_11);\n    vec3 param_25 = fa_ltc_local(param_12, param_13, param_14);\n    vec3 param_26 = fa_ltc_local(param_15, param_16, param_17);\n    vec2 _7631 = fa_area_forms(param_22, param_23, param_24, param_25, param_26);\n    return (((diffuse_color * _7631.x) + (((f0 * _7619.x) + ((vec3(f90) - f0) * _7619.y)) * _7631.y)) * fa_light_texel(param_2).xyz) * ((((3.1415927410125732421875 * dot(_7473, _7473)) + _7568) / _7568) * window);\n}\n\nvec3 fa_light_rgb(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 1;\n    return fa_light_texel(param_1).xyz;\n}\n\nfloat fa_d_charlie(float alpha, float ndh)\n{\n    float _5525 = 1.0 / alpha;\n    return ((2.0 + _5525) * pow(sqrt(max(1.0 - (ndh * ndh), 9.9999997473787516355514526367188e-05)), _5525)) * 0.15915493667125701904296875;\n}\n\nfloat fa_v_ashikhmin(float ndl, float ndv)\n{\n    return clamp(0.25 / max((ndl + ndv) - (ndl * ndv), 9.9999997473787516355514526367188e-05), 0.0, 1.0);\n}\n\nfloat fa_layers_coat(FaLayers L, vec3 l, vec3 h, float vdh)\n{\n    float _5560 = max(dot(L.nc, l), 0.0);\n    float _5566 = max(dot(L.nc, h), 0.0);\n    float _5575 = ((_5566 * _5566) * (L.coat_a2 - 1.0)) + 1.0;\n    return (((L.coat * (0.039999999105930328369140625 + (0.959999978542327880859375 * pow(clamp(1.0 - vdh, 0.0, 1.0), 5.0)))) * (((L.coat_a2 / ((3.1415927410125732421875 * _5575) * _5575)) * (0.5 / max(mix((2.0 * _5560) * L.coat_ndv, _5560 + L.coat_ndv, L.coat_alpha), 9.9999997473787516355514526367188e-05))) * 3.1415927410125732421875)) * step(9.9999997473787516355514526367188e-05, _5560)) * _5560;\n}\n\nvec3 fa_area_layers(FaLayers L, vec3 base, int li, vec3 n, vec3 v, vec3 l, float ndv, float window)\n{\n    float _7668;\n    if (L.sheen_on)\n    {\n        _7668 = L.sheen_scale;\n    }\n    else\n    {\n        _7668 = 1.0;\n    }\n    vec3 result = base * (L.keep * _7668);\n    vec3 _7681 = normalize(l + v);\n    int param = li;\n    vec3 _7692 = fa_light_rgb(param) * window;\n    if (L.sheen_on)\n    {\n        float _7701 = max(dot(n, l), 0.0);\n        float param_1 = L.sheen_alpha;\n        float param_2 = max(dot(n, _7681), 0.0);\n        float param_3 = _7701;\n        float param_4 = ndv;\n        result += ((L.sheen * _7692) * (((((fa_d_charlie(param_1, param_2) * fa_v_ashikhmin(param_3, param_4)) * 3.1415927410125732421875) * step(9.9999997473787516355514526367188e-05, _7701)) * _7701) * L.keep));\n    }\n    if (L.coat > 0.0)\n    {\n        FaLayers param_5 = L;\n        vec3 param_6 = l;\n        vec3 param_7 = _7681;\n        float param_8 = max(dot(v, _7681), 0.0);\n        result += (_7692 * fa_layers_coat(param_5, param_6, param_7, param_8));\n    }\n    return result;\n}\n\nfloat fa_d_ggx_aniso(float ndh, float tdh, float bdh, float at, float ab)\n{\n    float _5428 = tdh / at;\n    float _5432 = bdh / ab;\n    float _5444 = ((_5428 * _5428) + (_5432 * _5432)) + (ndh * ndh);\n    return 1.0 / ((((3.1415927410125732421875 * at) * ab) * _5444) * _5444);\n}\n\nfloat fa_lambda_ggx_aniso(float n, float t, float b, float at, float ab)\n{\n    return 0.5 * (sqrt(1.0 + (((((at * at) * t) * t) + (((ab * ab) * b) * b)) / max(n * n, 9.9999999392252902907785028219223e-09))) - 1.0);\n}\n\nfloat fa_v_ggx_aniso(float ndl, float ndv, float tdv, float bdv, float tdl, float bdl, float at, float ab)\n{\n    float param = ndv;\n    float param_1 = tdv;\n    float param_2 = bdv;\n    float param_3 = at;\n    float param_4 = ab;\n    float param_5 = ndl;\n    float param_6 = tdl;\n    float param_7 = bdl;\n    float param_8 = at;\n    float param_9 = ab;\n    return clamp(1.0 / ((4.0 * max(ndl * ndv, 9.9999997473787516355514526367188e-05)) * ((1.0 + fa_lambda_ggx_aniso(param, param_1, param_2, param_3, param_4)) + fa_lambda_ggx_aniso(param_5, param_6, param_7, param_8, param_9))), 0.0, 1.0);\n}\n\nvec3 fa_layers_light(FaLayers L, vec3 diffuse_color, vec3 f0, vec3 n, vec3 v, vec3 l, vec3 h, float ndl, float ndv, float ndh, float vdh, float alpha, float a2)\n{\n    float _5624 = step(9.9999997473787516355514526367188e-05, ndl);\n    float d_ggx;\n    float vis;\n    if (L.aniso != 0.0)\n    {\n        float param = ndh;\n        float param_1 = dot(L.t, h);\n        float param_2 = dot(L.b, h);\n        float param_3 = L.at;\n        float param_4 = L.ab;\n        d_ggx = fa_d_ggx_aniso(param, param_1, param_2, param_3, param_4);\n        float param_5 = ndl;\n        float param_6 = ndv;\n        float param_7 = dot(L.t, v);\n        float param_8 = dot(L.b, v);\n        float param_9 = dot(L.t, l);\n        float param_10 = dot(L.b, l);\n        float param_11 = L.at;\n        float param_12 = L.ab;\n        vis = fa_v_ggx_aniso(param_5, param_6, param_7, param_8, param_9, param_10, param_11, param_12);\n    }\n    else\n    {\n        float _5703 = ((ndh * ndh) * (a2 - 1.0)) + 1.0;\n        d_ggx = a2 / ((3.1415927410125732421875 * _5703) * _5703);\n        vis = 0.5 / max(mix((2.0 * ndl) * ndv, ndl + ndv, alpha), 9.9999997473787516355514526367188e-05);\n    }\n    vec3 base = diffuse_color + (((f0 + ((vec3(L.f90) - f0) * pow(clamp(1.0 - vdh, 0.0, 1.0), 5.0))) * ((d_ggx * vis) * 3.1415927410125732421875)) * _5624);\n    if (L.sheen_on)\n    {\n        float param_13 = L.sheen_alpha;\n        float param_14 = ndh;\n        float param_15 = ndl;\n        float param_16 = ndv;\n        base = (base * L.sheen_scale) + (L.sheen * (((fa_d_charlie(param_13, param_14) * fa_v_ashikhmin(param_15, param_16)) * 3.1415927410125732421875) * _5624));\n    }\n    vec3 result = base * (L.keep * ndl);\n    if (L.coat > 0.0)\n    {\n        FaLayers param_17 = L;\n        vec3 param_18 = l;\n        vec3 param_19 = h;\n        float param_20 = vdh;\n        result += vec3(fa_layers_coat(param_17, param_18, param_19, param_20));\n    }\n    return result;\n}\n\nvec2 fa_env_brdf(float rough, float ndv)\n{\n    vec4 _4827 = (vec4(-1.0, -0.0274999998509883880615234375, -0.572000026702880859375, 0.02199999988079071044921875) * rough) + vec4(1.0, 0.0425000004470348358154296875, 1.03999996185302734375, -0.039999999105930328369140625);\n    float _4830 = _4827.x;\n    return (vec2(-1.03999996185302734375, 1.03999996185302734375) * ((min(_4830 * _4830, exp2((-9.27999973297119140625) * ndv)) * _4830) + _4827.y)) + _4827.zw;\n}\n\nvec3 fa_probe_level(vec2 origin, float res, int lv, vec2 e)\n{\n    float _4137;\n    if (lv == 0)\n    {\n        _4137 = 0.0;\n    }\n    else\n    {\n        _4137 = res + 2.0;\n    }\n    float _4147;\n    if (lv == 0)\n    {\n        _4147 = 0.0;\n    }\n    else\n    {\n        _4147 = (res - (res / float(1 << max((lv - 1), 0)))) + (2.0 * float(lv - 1));\n    }\n    return textureLod(fa_probe_atlas_fa_env_smp, (((origin + vec2(_4137, _4147)) + vec2(1.0)) + (((e * 0.5) + vec2(0.5)) * (res / float(1 << lv)))) / fa_atlas_size(), 0.0).xyz;\n}\n\nvec3 fa_probe_radiance(vec2 origin, float res, vec3 d, float rough)\n{\n    float _4193;\n    if (res > 64.5)\n    {\n        _4193 = 5.0;\n    }\n    else\n    {\n        _4193 = (res > 32.5) ? 4.0 : 3.0;\n    }\n    float _4208 = clamp(rough, 0.0, 1.0) * (_4193 - 1.0);\n    int _4215 = int(min(floor(_4208), _4193 - 2.0));\n    float _4220 = _4208 - float(_4215);\n    vec3 param = d;\n    vec2 _4224 = fa_oct_encode(param);\n    vec2 param_1 = origin;\n    float param_2 = res;\n    int param_3 = _4215;\n    vec2 param_4 = _4224;\n    vec3 _4234 = fa_probe_level(param_1, param_2, param_3, param_4);\n    if (_4220 < 0.00200000009499490261077880859375)\n    {\n        return _4234;\n    }\n    vec2 param_5 = origin;\n    float param_6 = res;\n    int param_7 = _4215 + 1;\n    vec2 param_8 = _4224;\n    return mix(_4234, fa_probe_level(param_5, param_6, param_7, param_8), vec3(_4220));\n}\n\nvec3 fa_probe_box_dir(vec3 d, vec4 posw, vec4 bx, vec4 by, vec4 bz)\n{\n    if (posw.w < 0.5)\n    {\n        return d;\n    }\n    float _4305 = dot(bx.xyz, fa_world_pos) + bx.w;\n    float _4312 = dot(by.xyz, fa_world_pos) + by.w;\n    float _4319 = dot(bz.xyz, fa_world_pos) + bz.w;\n    float _4325 = dot(bx.xyz, d);\n    float _4329 = dot(by.xyz, d);\n    float _4333 = dot(bz.xyz, d);\n    float _4339;\n    if (_4325 > 9.9999999747524270787835121154785e-07)\n    {\n        _4339 = (1.0 - _4305) / _4325;\n    }\n    else\n    {\n        float _4353;\n        if (_4325 < (-9.9999999747524270787835121154785e-07))\n        {\n            _4353 = ((-1.0) - _4305) / _4325;\n        }\n        else\n        {\n            _4353 = 1000000015047466219876688855040.0;\n        }\n        _4339 = _4353;\n    }\n    float tx = _4339;\n    float _4370;\n    if (_4329 > 9.9999999747524270787835121154785e-07)\n    {\n        _4370 = (1.0 - _4312) / _4329;\n    }\n    else\n    {\n        float _4383;\n        if (_4329 < (-9.9999999747524270787835121154785e-07))\n        {\n            _4383 = ((-1.0) - _4312) / _4329;\n        }\n        else\n        {\n            _4383 = 1000000015047466219876688855040.0;\n        }\n        _4370 = _4383;\n    }\n    float ty = _4370;\n    float _4399;\n    if (_4333 > 9.9999999747524270787835121154785e-07)\n    {\n        _4399 = (1.0 - _4319) / _4333;\n    }\n    else\n    {\n        float _4412;\n        if (_4333 < (-9.9999999747524270787835121154785e-07))\n        {\n            _4412 = ((-1.0) - _4319) / _4333;\n        }\n        else\n        {\n            _4412 = 1000000015047466219876688855040.0;\n        }\n        _4399 = _4412;\n    }\n    float _4424 = tx;\n    float _4427 = (_4424 > 0.0) ? _4424 : 1000000015047466219876688855040.0;\n    tx = _4427;\n    float _4428 = ty;\n    float _4431 = (_4428 > 0.0) ? _4428 : 1000000015047466219876688855040.0;\n    ty = _4431;\n    float _4441 = min(_4427, min(_4431, (_4399 > 0.0) ? _4399 : 1000000015047466219876688855040.0));\n    if (_4441 > 100000001504746621987668885504.0)\n    {\n        return d;\n    }\n    vec3 _4457 = (fa_world_pos + (d * _4441)) - posw.xyz;\n    vec3 _4462;\n    if (dot(_4457, _4457) > 1.0000000133514319600180897396058e-10)\n    {\n        _4462 = normalize(_4457);\n    }\n    else\n    {\n        _4462 = d;\n    }\n    return _4462;\n}\n\nvec3 fa_probe_environment(vec4 tile, vec4 posw, vec4 bx, vec4 by, vec4 bz, inout vec3 d, float rough)\n{\n    vec3 param = d;\n    vec4 param_1 = posw;\n    vec4 param_2 = bx;\n    vec4 param_3 = by;\n    vec4 param_4 = bz;\n    d = fa_probe_box_dir(param, param_1, param_2, param_3, param_4);\n    vec2 param_5 = tile.xy;\n    float param_6 = tile.z;\n    vec3 param_7 = d;\n    float param_8 = rough;\n    return fa_probe_radiance(param_5, param_6, param_7, param_8);\n}\n\nvec3 fa_environment(vec3 d, float rough)\n{\n    float _4508 = (1.0 - fa_mesh_fs_params[42].w) - fa_mesh_fs_params[47].w;\n    vec3 outc = vec3(0.0);\n    if (_4508 > 0.0005000000237487256526947021484375)\n    {\n        vec3 base;\n        if (fa_mesh_fs_params[11].w > 0.5)\n        {\n            vec2 param = fa_mesh_fs_params[41].zw;\n            float param_1 = 128.0;\n            vec3 param_2 = d;\n            float param_3 = rough;\n            base = fa_probe_radiance(param, param_1, param_2, param_3);\n        }\n        else\n        {\n            float _4536 = rough * rough;\n            float _4567 = 0.60000002384185791015625 * _4536;\n            base = mix(mix(fa_mesh_fs_params[12].xyz * 0.550000011920928955078125, mix(fa_mesh_fs_params[12].xyz, fa_mesh_fs_params[11].xyz, vec3(pow(clamp(d.y * (1.0 - (0.699999988079071044921875 * _4536)), 0.0, 1.0), 0.550000011920928955078125))), vec3(smoothstep((-0.0500000007450580596923828125) - _4567, 0.0500000007450580596923828125 + _4567, d.y))), ((fa_mesh_fs_params[11].xyz + fa_mesh_fs_params[12].xyz) * 0.5) * 0.800000011920928955078125, vec3(_4536 * 0.60000002384185791015625));\n        }\n        outc = base * _4508;\n    }\n    if (fa_mesh_fs_params[42].w > 0.0)\n    {\n        vec4 param_4 = fa_mesh_fs_params[42];\n        vec4 param_5 = fa_mesh_fs_params[43];\n        vec4 param_6 = fa_mesh_fs_params[44];\n        vec4 param_7 = fa_mesh_fs_params[45];\n        vec4 param_8 = fa_mesh_fs_params[46];\n        vec3 param_9 = d;\n        float param_10 = rough;\n        vec3 _4626 = fa_probe_environment(param_4, param_5, param_6, param_7, param_8, param_9, param_10);\n        outc += (_4626 * fa_mesh_fs_params[42].w);\n    }\n    if (fa_mesh_fs_params[47].w > 0.0)\n    {\n        vec4 param_11 = fa_mesh_fs_params[47];\n        vec4 param_12 = fa_mesh_fs_params[48];\n        vec4 param_13 = fa_mesh_fs_params[49];\n        vec4 param_14 = fa_mesh_fs_params[50];\n        vec4 param_15 = fa_mesh_fs_params[51];\n        vec3 param_16 = d;\n        float param_17 = rough;\n        vec3 _4658 = fa_probe_environment(param_11, param_12, param_13, param_14, param_15, param_16, param_17);\n        outc += (_4658 * fa_mesh_fs_params[47].w);\n    }\n    return outc;\n}\n\nvec3 fa_layers_ibl(FaLayers L, vec3 n, vec3 v, vec3 f0, float roughness, float occlusion)\n{\n    vec3 rn = n;\n    if (L.aniso != 0.0)\n    {\n        vec3 _5305;\n        if (L.aniso >= 0.0)\n        {\n            _5305 = L.b;\n        }\n        else\n        {\n            _5305 = L.t;\n        }\n        rn = normalize(mix(n, cross(cross(_5305, v), _5305), vec3(abs(L.aniso) * smoothstep(0.0, 0.25, roughness))));\n    }\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05);\n    vec2 _5341 = fa_env_brdf(param, param_1);\n    vec3 param_2 = reflect(-v, rn);\n    float param_3 = roughness;\n    vec3 result = (fa_environment(param_2, param_3) * ((f0 * _5341.x) + (vec3(L.f90) * _5341.y))) * L.base_scale;\n    if (L.sheen_on)\n    {\n        vec3 param_4 = n;\n        float param_5 = L.sheen_rough;\n        result += ((L.sheen * (L.sheen_e * L.keep)) * fa_environment(param_4, param_5));\n    }\n    result *= occlusion;\n    if (L.coat > 0.0)\n    {\n        float param_6 = L.coat_rough;\n        float param_7 = L.coat_ndv;\n        vec2 _5399 = fa_env_brdf(param_6, param_7);\n        vec3 param_8 = reflect(-v, L.nc);\n        float param_9 = L.coat_rough;\n        result += (fa_environment(param_8, param_9) * (L.coat * ((0.039999999105930328369140625 * _5399.x) + _5399.y)));\n    }\n    return result;\n}\n\nvec3 fa_sky_reflection(vec3 n, vec3 v, vec3 f0, float roughness)\n{\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05);\n    vec2 _4869 = fa_env_brdf(param, param_1);\n    vec3 param_2 = reflect(-v, n);\n    float param_3 = roughness;\n    return fa_environment(param_2, param_3) * ((f0 * _4869.x) + vec3(_4869.y));\n}\n\nvec2 fa_xm_size(int k)\n{\n    return max(floor(fa_mesh_fs_params[24].zw / vec2(float(1 << k))), vec2(1.0));\n}\n\nvec2 fa_xm_origin(int k)\n{\n    if (k == 0)\n    {\n        return vec2(0.0);\n    }\n    float y = 0.0;\n    for (int j = 1; j < k; j++)\n    {\n        int param = j;\n        y += fa_xm_size(param).y;\n    }\n    return vec2(fa_mesh_fs_params[24].z, y);\n}\n\nvec3 fa_xm_texel(vec2 size, vec2 origin, vec2 p)\n{\n    return texelFetch(fa_screen_tex_fa_shadow_smp, ivec2(origin + clamp(p, vec2(0.0), size - vec2(1.0))), 0).xyz;\n}\n\nvec3 fa_xm_level(int k, vec2 uv)\n{\n    int param = k;\n    vec2 _6101 = fa_xm_size(param);\n    int param_1 = k;\n    vec2 _6105 = fa_xm_origin(param_1);\n    vec2 _6111 = (uv * _6101) - vec2(0.5);\n    vec2 _6114 = fract(_6111);\n    vec2 _6117 = floor(_6111);\n    vec2 param_2 = _6101;\n    vec2 param_3 = _6105;\n    vec2 param_4 = _6117;\n    vec2 param_5 = _6101;\n    vec2 param_6 = _6105;\n    vec2 param_7 = _6117 + vec2(1.0, 0.0);\n    vec2 param_8 = _6101;\n    vec2 param_9 = _6105;\n    vec2 param_10 = _6117 + vec2(0.0, 1.0);\n    vec2 param_11 = _6101;\n    vec2 param_12 = _6105;\n    vec2 param_13 = _6117 + vec2(1.0);\n    vec3 _6159 = vec3(_6114.x);\n    return mix(mix(fa_xm_texel(param_2, param_3, param_4), fa_xm_texel(param_5, param_6, param_7), _6159), mix(fa_xm_texel(param_8, param_9, param_10), fa_xm_texel(param_11, param_12, param_13), _6159), vec3(_6114.y));\n}\n\nvec3 fa_xm_sample(vec2 uv, float lod)\n{\n    float _6178 = max(fa_mesh_fs_params[31].w - 1.0, 0.0);\n    float _6182 = clamp(lod, 0.0, _6178);\n    int _6186 = int(floor(_6182));\n    int param = _6186;\n    vec2 param_1 = uv;\n    vec3 c = fa_xm_level(param, param_1);\n    float _6196 = float(_6186);\n    float _6197 = _6182 - _6196;\n    bool _6199 = _6197 > 0.001000000047497451305389404296875;\n    bool _6206;\n    if (_6199)\n    {\n        _6206 = _6196 < _6178;\n    }\n    else\n    {\n        _6206 = _6199;\n    }\n    if (_6206)\n    {\n        int param_2 = _6186 + 1;\n        vec2 param_3 = uv;\n        c = mix(c, fa_xm_level(param_2, param_3), vec3(_6197));\n    }\n    return c;\n}\n\nvec3 fa_transmitted(Surface s, vec3 n, vec3 v, float roughness, vec3 f0, float f90, float keep, float tr, inout float blend)\n{\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05);\n    vec2 _6232 = fa_env_brdf(param, param_1);\n    vec3 _6256 = ((vec3(1.0) - clamp((f0 * _6232.x) + (vec3(f90) * _6232.y), vec3(0.0), vec3(1.0))) * s.albedo) * (tr * keep);\n    vec3 through = _6256;\n    float _6262 = max(s.thickness, 0.0);\n    bool _6267 = _6262 > 0.0;\n    if ((s.attenuation_distance > 0.0) && _6267)\n    {\n        through *= exp((-((-log(clamp(s.attenuation_color, vec3(9.9999997473787516355514526367188e-05), vec3(1.0)))) / vec3(s.attenuation_distance))) * _6262);\n    }\n    bool _6292 = fa_mesh_fs_params[30].w > 1.5;\n    bool _6298;\n    if (_6292)\n    {\n        _6298 = fa_mesh_fs_params[30].w < 2.5;\n    }\n    else\n    {\n        _6298 = _6292;\n    }\n    bool _6305;\n    if (!_6298)\n    {\n        _6305 = fa_mesh_fs_params[30].w < 0.5;\n    }\n    else\n    {\n        _6305 = _6298;\n    }\n    if (_6305)\n    {\n        blend = clamp(dot(through, vec3(0.3333333432674407958984375)), 0.0, 0.980000019073486328125);\n        return vec3(0.0);\n    }\n    vec4 _6320 = vec4(fa_world_pos, 1.0);\n    float _6325 = dot(fa_mesh_fs_params[28], _6320);\n    vec2 uv0 = vec2(0.5);\n    if (_6325 > 9.9999997473787516355514526367188e-05)\n    {\n        vec2 _6343 = vec2(dot(fa_mesh_fs_params[26], _6320), dot(fa_mesh_fs_params[27], _6320)) / vec2(_6325);\n        float _6351;\n        if (fa_mesh_fs_params[24].y > 0.5)\n        {\n            _6351 = (_6343.y * 0.5) + 0.5;\n        }\n        else\n        {\n            _6351 = 0.5 - (_6343.y * 0.5);\n        }\n        uv0 = vec2((_6343.x * 0.5) + 0.5, _6351);\n    }\n    if (fa_mesh_fs_params[30].w > 2.5)\n    {\n        int param_2 = 0;\n        vec2 _6372 = fa_xm_size(param_2);\n        vec2 _6380 = floor(clamp(uv0, vec2(0.0), vec2(0.99989998340606689453125)) * _6372);\n        if (texelFetch(fa_screen_tex_fa_shadow_smp, ivec2(_6380), 0).w > 0.5)\n        {\n            int _6400 = int(floor((clamp(roughness, 0.0, 1.0) * 2.0) + 0.5));\n            vec3 acc = vec3(0.0);\n            float cnt = 0.0;\n            for (int dy = -2; dy <= 2; dy++)\n            {\n                for (int dx = -2; dx <= 2; dx++)\n                {\n                    bool _6423 = abs(dx) > _6400;\n                    bool _6431;\n                    if (!_6423)\n                    {\n                        _6431 = abs(dy) > _6400;\n                    }\n                    else\n                    {\n                        _6431 = _6423;\n                    }\n                    if (_6431)\n                    {\n                        continue;\n                    }\n                    vec4 _6452 = texelFetch(fa_screen_tex_fa_shadow_smp, ivec2(clamp(_6380 + vec2(float(dx), float(dy)), vec2(0.0), _6372 - vec2(1.0))), 0);\n                    if (_6452.w > 0.5)\n                    {\n                        acc += _6452.xyz;\n                        cnt += 1.0;\n                    }\n                }\n            }\n            return _6256 * (acc / vec3(max(cnt, 1.0)));\n        }\n    }\n    vec2 uv = uv0;\n    if (_6267)\n    {\n        vec4 _6500 = vec4(fa_world_pos + (refract(-v, n, 1.0 / max(s.ior, 1.0)) * _6262), 1.0);\n        float _6505 = dot(fa_mesh_fs_params[28], _6500);\n        uv = vec2(0.5);\n        if (_6505 > 9.9999997473787516355514526367188e-05)\n        {\n            vec2 _6522 = vec2(dot(fa_mesh_fs_params[26], _6500), dot(fa_mesh_fs_params[27], _6500)) / vec2(_6505);\n            float _6530;\n            if (fa_mesh_fs_params[24].y > 0.5)\n            {\n                _6530 = (_6522.y * 0.5) + 0.5;\n            }\n            else\n            {\n                _6530 = 0.5 - (_6522.y * 0.5);\n            }\n            uv = vec2((_6522.x * 0.5) + 0.5, _6530);\n        }\n    }\n    vec2 param_3 = clamp(uv, vec2(0.0), vec2(1.0));\n    float param_4 = (clamp(roughness, 0.0, 1.0) * clamp((2.0 * s.ior) - 2.0, 0.0, 1.0)) * max(fa_mesh_fs_params[31].w - 1.0, 0.0);\n    return through * fa_xm_sample(param_3, param_4);\n}\n\nvec3 fa_shadow_debug(vec3 color, vec3 world)\n{\n    if (fa_shadows[27].w < 0.5)\n    {\n        return color;\n    }\n    int _3324 = int(fa_shadows[25].x + 0.5);\n    float _3334 = dot(world - fa_shadows[27].xyz, fa_shadows[28].xyz);\n    vec3 tint = vec3(0.3499999940395355224609375);\n    bool _3339 = _3324 > 0;\n    bool _3348;\n    if (_3339)\n    {\n        int param = _3324 - 1;\n        _3348 = _3334 <= fa_shadow_split_at(param);\n    }\n    else\n    {\n        _3348 = _3339;\n    }\n    if (_3348)\n    {\n        tint = vec3(1.0, 0.1500000059604644775390625, 0.100000001490116119384765625);\n        bool _3354 = _3324 > 1;\n        bool _3361;\n        if (_3354)\n        {\n            _3361 = _3334 > fa_shadows[24].x;\n        }\n        else\n        {\n            _3361 = _3354;\n        }\n        if (_3361)\n        {\n            tint = vec3(0.100000001490116119384765625, 0.89999997615814208984375, 0.20000000298023223876953125);\n        }\n        bool _3367 = _3324 > 2;\n        bool _3374;\n        if (_3367)\n        {\n            _3374 = _3334 > fa_shadows[24].y;\n        }\n        else\n        {\n            _3374 = _3367;\n        }\n        if (_3374)\n        {\n            tint = vec3(0.1500000059604644775390625, 0.300000011920928955078125, 1.0);\n        }\n        bool _3380 = _3324 > 3;\n        bool _3387;\n        if (_3380)\n        {\n            _3387 = _3334 > fa_shadows[24].z;\n        }\n        else\n        {\n            _3387 = _3380;\n        }\n        if (_3387)\n        {\n            tint = vec3(1.0, 0.89999997615814208984375, 0.100000001490116119384765625);\n        }\n    }\n    return mix(color, tint, vec3(0.550000011920928955078125));\n}\n\nvoid main()\n{\n    fa_rt_slope = 0.0;\n    fa_inst_load();\n    vec3 _9614 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _9614 = -_9614;\n    }\n    vec3 _8900 = normalize(fa_mesh_fs_params[0].xyz - fa_world_pos);\n    vec3 param = fa_world_pos;\n    fa_cluster_begin(param);\n    SurfaceInput param_1 = SurfaceInput(fa_world_pos, _9614, fa_world_tangent, fa_uv, fa_vertex_color, _8900, gl_FrontFacing);\n    Surface _8908 = fa_standard_surface(param_1);\n    vec3 _9645 = _8908.albedo;\n    float _9646 = _8908.alpha;\n    vec3 _9647 = _8908.normal;\n    float _9648 = _8908.metallic;\n    float _9649 = _8908.roughness;\n    float _9650 = _8908.occlusion;\n    vec3 _9651 = _8908.emission;\n    float _9652 = _8908.clearcoat;\n    float _9653 = _8908.clearcoat_roughness;\n    vec3 _9654 = _8908.sheen_color;\n    float _9655 = _8908.sheen_roughness;\n    float _9656 = _8908.anisotropy;\n    float _9657 = _8908.anisotropy_rotation;\n    float _9658 = _8908.specular;\n    float _9659 = _8908.ior;\n    vec3 _9660 = _8908.specular_color;\n    float _9661 = _8908.transmission;\n    float _9662 = _8908.thickness;\n    vec3 _9663 = _8908.attenuation_color;\n    float _9664 = _8908.attenuation_distance;\n    SurfaceInput param_2 = SurfaceInput(fa_world_pos, _9614, fa_world_tangent, fa_uv, fa_vertex_color, _8900, gl_FrontFacing);\n    Surface param_3 = _8908;\n    surface(param_2, param_3);\n    _9645 = param_3.albedo;\n    _9646 = param_3.alpha;\n    _9647 = param_3.normal;\n    _9648 = param_3.metallic;\n    _9649 = param_3.roughness;\n    _9650 = param_3.occlusion;\n    _9651 = param_3.emission;\n    _9652 = param_3.clearcoat;\n    _9653 = param_3.clearcoat_roughness;\n    _9654 = param_3.sheen_color;\n    _9655 = param_3.sheen_roughness;\n    _9656 = param_3.anisotropy;\n    _9657 = param_3.anisotropy_rotation;\n    _9658 = param_3.specular;\n    _9659 = param_3.ior;\n    _9660 = param_3.specular_color;\n    _9661 = param_3.transmission;\n    _9662 = param_3.thickness;\n    _9663 = param_3.attenuation_color;\n    _9664 = param_3.attenuation_distance;\n    vec3 param_4 = fa_world_pos;\n    vec3 param_5 = _9614;\n    vec3 param_6 = param_3.albedo;\n    vec3 param_7 = param_3.normal;\n    fa_apply_decals(param_4, param_5, param_6, param_7);\n    _9645 = param_6;\n    _9647 = param_7;\n    if (_9646 < fa_material[0].x)\n    {\n        discard;\n    }\n    fa_lod_dither();\n    float fa_tr_blend = 0.0;\n    vec3 result;\n    if (fa_mesh_fs_params[3].w > 0.5)\n    {\n        result = _9645;\n    }\n    else\n    {\n        vec3 _8960 = normalize(_9647);\n        float _8967 = clamp(_9648, 0.0, 1.0);\n        float _8971 = clamp(_9649, 0.0500000007450580596923828125, 1.0);\n        float _8975 = _8971 * _8971;\n        float _8979 = _8975 * _8975;\n        float _8984 = max(dot(_8960, _8900), 9.9999997473787516355514526367188e-05);\n        float _8990 = 1.0 - _8967;\n        float _8991 = clamp(_9661, 0.0, 1.0) * _8990;\n        vec3 _9000 = (_9645 * _8990) * (1.0 - _8991);\n        vec3 _9007 = mix(vec3(0.039999999105930328369140625), _9645, vec3(_8967));\n        vec3 f0 = _9007;\n        SurfaceInput param_8 = SurfaceInput(fa_world_pos, _9614, fa_world_tangent, fa_uv, fa_vertex_color, _8900, gl_FrontFacing);\n        Surface param_9 = Surface(_9645, _9646, _9647, _9648, _9649, _9650, _9651, _9652, _9653, _9654, _9655, _9656, _9657, _9658, _9659, _9660, _9661, _9662, _9663, _9664);\n        vec3 param_10 = _8960;\n        vec3 param_11 = _8900;\n        float param_12 = _8967;\n        float param_13 = _8971;\n        vec3 param_14 = _9007;\n        FaLayers _9023 = fa_layers_setup(param_8, param_9, param_10, param_11, param_12, param_13, param_14);\n        f0 = param_14;\n        vec3 param_15 = _8960;\n        vec3 lit = (fa_indirect_diffuse(param_15) * _9000) * _9650;\n        if (_9023.on)\n        {\n            lit *= _9023.base_scale;\n        }\n        int _9045 = fa_cl_ndir + fa_cl_local;\n        float _9110;\n        for (int ln = 0; ln < _9045; ln++)\n        {\n            int param_16 = ln;\n            int _9058 = fa_cl_light(param_16);\n            int param_17 = _9058;\n            if (fa_baked_keep(param_17) <= 0.0)\n            {\n                continue;\n            }\n            int param_18 = _9058;\n            vec3 param_19 = fa_world_pos;\n            vec3 param_20 = _9614;\n            LightSample _9074 = fa_light_shadowed(param_18, param_19, param_20);\n            float _9082 = max(dot(_8960, _9074.direction), 0.0);\n            float _9088 = _9074.attenuation * _9074.shadow;\n            vec3 _9093 = normalize(_9074.direction + _8900);\n            float _9098 = max(dot(_8960, _9093), 0.0);\n            float _9103 = max(dot(_8900, _9093), 0.0);\n            if (fa_light_is_area)\n            {\n                if (_9023.on)\n                {\n                    _9110 = _9023.f90;\n                }\n                else\n                {\n                    _9110 = 1.0;\n                }\n                int param_21 = _9058;\n                vec3 param_22 = fa_world_pos;\n                vec3 param_23 = _8960;\n                vec3 param_24 = _8900;\n                vec3 param_25 = _9000;\n                vec3 param_26 = f0;\n                float param_27 = _9110;\n                float param_28 = _8971;\n                float param_29 = _8984;\n                float param_30 = _9088;\n                vec3 area = fa_area_shade(param_21, param_22, param_23, param_24, param_25, param_26, param_27, param_28, param_29, param_30);\n                if (_9023.on)\n                {\n                    FaLayers param_31 = _9023;\n                    vec3 param_32 = area;\n                    int param_33 = _9058;\n                    vec3 param_34 = _8960;\n                    vec3 param_35 = _8900;\n                    vec3 param_36 = _9074.direction;\n                    float param_37 = _8984;\n                    float param_38 = _9088;\n                    area = fa_area_layers(param_31, param_32, param_33, param_34, param_35, param_36, param_37, param_38);\n                }\n                lit += area;\n            }\n            else\n            {\n                if (_9023.on)\n                {\n                    FaLayers param_39 = _9023;\n                    vec3 param_40 = _9000;\n                    vec3 param_41 = f0;\n                    vec3 param_42 = _8960;\n                    vec3 param_43 = _8900;\n                    vec3 param_44 = _9074.direction;\n                    vec3 param_45 = _9093;\n                    float param_46 = _9082;\n                    float param_47 = _8984;\n                    float param_48 = _9098;\n                    float param_49 = _9103;\n                    float param_50 = _8975;\n                    float param_51 = _8979;\n                    int param_52 = _9058;\n                    lit += (fa_layers_light(param_39, param_40, param_41, param_42, param_43, param_44, param_45, param_46, param_47, param_48, param_49, param_50, param_51) * ((fa_light_rgb(param_52) * fa_light_tint) * _9088));\n                }\n                else\n                {\n                    float _9212 = ((_9098 * _9098) * (_8979 - 1.0)) + 1.0;\n                    int param_53 = _9058;\n                    lit += (((_9000 + (((f0 + ((vec3(1.0) - f0) * pow(1.0 - _9103, 5.0))) * (((_8979 / ((3.1415927410125732421875 * _9212) * _9212)) * (0.5 / max(mix((2.0 * _9082) * _8984, _9082 + _8984, _8975), 9.9999997473787516355514526367188e-05))) * 3.1415927410125732421875)) * step(9.9999997473787516355514526367188e-05, _9082))) * (fa_light_rgb(param_53) * fa_light_tint)) * (_9082 * _9088));\n                }\n            }\n        }\n        if (_9023.on)\n        {\n            FaLayers param_54 = _9023;\n            vec3 param_55 = _8960;\n            vec3 param_56 = _8900;\n            vec3 param_57 = f0;\n            float param_58 = _8971;\n            float param_59 = _9650;\n            lit += fa_layers_ibl(param_54, param_55, param_56, param_57, param_58, param_59);\n        }\n        else\n        {\n            vec3 param_60 = _8960;\n            vec3 param_61 = _8900;\n            vec3 param_62 = f0;\n            float param_63 = _8971;\n            lit += (fa_sky_reflection(param_60, param_61, param_62, param_63) * _9650);\n        }\n        if (_8991 > 0.0)\n        {\n            float _9310;\n            if (_9023.on)\n            {\n                _9310 = _9023.f90;\n            }\n            else\n            {\n                _9310 = 1.0;\n            }\n            float _9318;\n            if (_9023.on)\n            {\n                _9318 = _9023.base_scale;\n            }\n            else\n            {\n                _9318 = 1.0;\n            }\n            Surface param_64 = Surface(_9645, _9646, _9647, _9648, _9649, _9650, _9651, _9652, _9653, _9654, _9655, _9656, _9657, _9658, _9659, _9660, _9661, _9662, _9663, _9664);\n            vec3 param_65 = _8960;\n            vec3 param_66 = _8900;\n            float param_67 = _8971;\n            vec3 param_68 = f0;\n            float param_69 = _9310;\n            float param_70 = _9318;\n            float param_71 = _8991;\n            float param_72 = fa_tr_blend;\n            vec3 _9342 = fa_transmitted(param_64, param_65, param_66, param_67, param_68, param_69, param_70, param_71, param_72);\n            fa_tr_blend = param_72;\n            lit += _9342;\n        }\n        result = lit;\n    }\n    vec3 _9349 = result;\n    vec3 _9350 = _9349 + _9651;\n    result = _9350;\n    vec3 param_73 = _9350;\n    vec3 param_74 = fa_world_pos;\n    result = fa_shadow_debug(param_73, param_74);\n    bool _9359 = fa_mesh_fs_params[7].w > 0.0;\n    bool _9366;\n    if (!_9359)\n    {\n        _9366 = fa_mesh_fs_params[8].y > 0.0;\n    }\n    else\n    {\n        _9366 = _9359;\n    }\n    if (_9366)\n    {\n        vec3 _9375 = fa_world_pos - fa_mesh_fs_params[0].xyz;\n        float _9381 = dot(_9375, fa_mesh_fs_params[9].xyz);\n        bool _9385 = fa_mesh_fs_params[9].w > 0.5;\n        float _9386;\n        if (_9385)\n        {\n            _9386 = _9381;\n        }\n        else\n        {\n            _9386 = length(_9375);\n        }\n        float _9398 = _9386 - fa_mesh_fs_params[8].x;\n        if (_9398 > 0.0)\n        {\n            float _9407 = fa_mesh_fs_params[7].w * _9398;\n            float tau = _9407 * _9407;\n            if (fa_mesh_fs_params[8].y > 0.0)\n            {\n                float _9423;\n                if (_9385)\n                {\n                    _9423 = fa_world_pos.y - (fa_mesh_fs_params[9].y * _9381);\n                }\n                else\n                {\n                    _9423 = fa_mesh_fs_params[0].y;\n                }\n                float _9444 = mix(_9423, fa_world_pos.y, clamp(fa_mesh_fs_params[8].x / _9386, 0.0, 1.0));\n                float _9448 = fa_world_pos.y - _9444;\n                float _9453 = _9444 - fa_mesh_fs_params[8].z;\n                float _9458 = fa_world_pos.y - fa_mesh_fs_params[8].z;\n                bool _9461 = _9453 <= 0.0;\n                bool _9462 = !_9461;\n                bool _9468;\n                if (_9462)\n                {\n                    _9468 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _9468 = _9461;\n                }\n                float _9469;\n                if (_9468)\n                {\n                    _9469 = fa_mesh_fs_params[8].y;\n                }\n                else\n                {\n                    _9469 = fa_mesh_fs_params[8].y * exp(-min(fa_mesh_fs_params[8].w * _9453, 80.0));\n                }\n                bool _9496;\n                if (_9462)\n                {\n                    _9496 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _9496 = _9461;\n                }\n                float _9497;\n                if (_9496)\n                {\n                    _9497 = fa_mesh_fs_params[8].y * _9453;\n                }\n                else\n                {\n                    _9497 = (fa_mesh_fs_params[8].y * (1.0 - exp(-min(fa_mesh_fs_params[8].w * _9453, 80.0)))) / fa_mesh_fs_params[8].w;\n                }\n                bool _9522 = _9458 <= 0.0;\n                bool _9529;\n                if (!_9522)\n                {\n                    _9529 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _9529 = _9522;\n                }\n                float _9530;\n                if (_9529)\n                {\n                    _9530 = fa_mesh_fs_params[8].y * _9458;\n                }\n                else\n                {\n                    _9530 = (fa_mesh_fs_params[8].y * (1.0 - exp(-min(fa_mesh_fs_params[8].w * _9458, 80.0)))) / fa_mesh_fs_params[8].w;\n                }\n                float _9557;\n                if (abs(_9448) < 0.001000000047497451305389404296875)\n                {\n                    _9557 = _9469;\n                }\n                else\n                {\n                    _9557 = (_9530 - _9497) / _9448;\n                }\n                tau += (_9398 * max(_9557, 0.0));\n            }\n            result = mix(result, fa_mesh_fs_params[7].xyz, vec3(clamp(1.0 - exp(-clamp(tau, 0.0, 80.0)), 0.0, 1.0)));\n        }\n    }\n    if (fa_tr_blend > 0.0)\n    {\n        float _9593 = 1.0 - fa_tr_blend;\n        result /= vec3(_9593);\n        _9646 *= _9593;\n    }\n    fa_frag_color = vec4(result, _9646);\n}\n\n",
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
            "inst_name": "_622",
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
            "inst_name": "_2365",
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
            "inst_name": "_8936",
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
              "slot": 6,
              "stage": "fragment",
              "name": "mask",
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
            "slot": 2,
            "stage": "fragment",
            "name": "mask_smp",
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
            "name": "mask_mask_smp",
            "view_name": "mask",
            "sampler_name": "mask_smp",
            "view_slot": 6,
            "sampler_slot": 2,
            "glsl_name": "mask_mask_smp"
          },
          {
            "slot": 7,
            "stage": "fragment",
            "name": "fa_decal_tex_fa_env_smp",
            "view_name": "fa_decal_tex",
            "sampler_name": "fa_env_smp",
            "view_slot": 27,
            "sampler_slot": 10,
            "glsl_name": "fa_decal_tex_fa_env_smp"
          },
          {
            "slot": 8,
            "stage": "fragment",
            "name": "fa_lightmap_fa_env_smp",
            "view_name": "fa_lightmap",
            "sampler_name": "fa_env_smp",
            "view_slot": 26,
            "sampler_slot": 10,
            "glsl_name": "fa_lightmap_fa_env_smp"
          },
          {
            "slot": 9,
            "stage": "fragment",
            "name": "fa_probe_atlas_fa_env_smp",
            "view_name": "fa_probe_atlas",
            "sampler_name": "fa_env_smp",
            "view_slot": 14,
            "sampler_slot": 10,
            "glsl_name": "fa_probe_atlas_fa_env_smp"
          },
          {
            "slot": 10,
            "stage": "fragment",
            "name": "fa_light_atlas_fa_env_smp",
            "view_name": "fa_light_atlas",
            "sampler_name": "fa_env_smp",
            "view_slot": 25,
            "sampler_slot": 10,
            "glsl_name": "fa_light_atlas_fa_env_smp"
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
          },
          {
            "slot": 12,
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
      "vs": "#version 430\n\nstruct VertexData\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 color;\n    vec3 object_pos;\n};\n\nuniform vec4 fa_mesh_vs_params[11];\nuniform vec4 fa_skin[192];\nlayout(location = 0) out vec3 fa_world_pos;\nlayout(location = 1) out vec3 fa_world_normal;\nlayout(location = 2) out vec4 fa_world_tangent;\nlayout(location = 3) out vec2 fa_uv;\nlayout(location = 4) out vec4 fa_vertex_color;\nlayout(location = 5) in vec4 fa_inst_m0;\nlayout(location = 6) in vec4 fa_inst_m1;\nlayout(location = 7) in vec4 fa_inst_m2;\nlayout(location = 8) in vec4 fa_inst_m3;\nlayout(location = 9) in vec4 fa_joints;\nlayout(location = 10) in vec4 fa_weights;\nlayout(location = 0) in vec3 fa_position;\nlayout(location = 1) in vec3 fa_normal;\nlayout(location = 3) in vec4 fa_tangent;\nlayout(location = 2) in vec2 fa_texcoord0;\nlayout(location = 4) in vec4 fa_color;\nlayout(location = 5) out vec3 fa_lm;\n\nvoid fa_inst_begin()\n{\n}\n\nmat4 fa_skin_matrix(vec4 joints, vec4 weights)\n{\n    vec4 r0 = vec4(0.0);\n    vec4 r1 = vec4(0.0);\n    vec4 r2 = vec4(0.0);\n    for (int i = 0; i < 4; i++)\n    {\n        int _174 = int((joints[i] * 255.0) + 0.5) * 3;\n        r0 += (fa_skin[_174 * 1 + 0] * weights[i]);\n        r1 += (fa_skin[(_174 + 1) * 1 + 0] * weights[i]);\n        r2 += (fa_skin[(_174 + 2) * 1 + 0] * weights[i]);\n    }\n    return mat4(vec4(r0.x, r1.x, r2.x, 0.0), vec4(r0.y, r1.y, r2.y, 0.0), vec4(r0.z, r1.z, r2.z, 0.0), vec4(r0.w, r1.w, r2.w, 1.0));\n}\n\nVertexData fa_vertex_data(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    vec3 _74 = cross(model[1].xyz, model[2].xyz);\n    float _80 = (dot(model[0].xyz, _74) < 0.0) ? (-1.0) : 1.0;\n    return VertexData((model * vec4(position, 1.0)).xyz, (((_74 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _80, vec4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _80), texcoord0 * fa_mesh_vs_params[8].xy, color, position);\n}\n\nvoid fa_shade_vertex(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    mat4 param = model;\n    vec3 param_1 = position;\n    vec3 param_2 = normal;\n    vec4 param_3 = tangent;\n    vec2 param_4 = texcoord0;\n    vec4 param_5 = color;\n    VertexData _273 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    vec3 _397 = _273.world_pos;\n    fa_world_pos = _397;\n    fa_world_normal = _273.world_normal;\n    fa_world_tangent = _273.world_tangent;\n    fa_uv = _273.uv;\n    fa_vertex_color = _273.color;\n    gl_Position = mat4(fa_mesh_vs_params[0], fa_mesh_vs_params[1], fa_mesh_vs_params[2], fa_mesh_vs_params[3]) * vec4(_397, 1.0);\n}\n\nvoid main()\n{\n    fa_inst_begin();\n    vec4 param = fa_joints;\n    vec4 param_1 = fa_weights;\n    mat4 param_2 = mat4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3) * fa_skin_matrix(param, param_1);\n    vec3 param_3 = fa_position;\n    vec3 param_4 = fa_normal;\n    vec4 param_5 = fa_tangent;\n    vec2 param_6 = fa_texcoord0;\n    vec4 param_7 = fa_color;\n    fa_shade_vertex(param_2, param_3, param_4, param_5, param_6, param_7);\n    fa_lm = vec3(0.0);\n}\n\n",
      "fs": "#version 430\n\nstruct SurfaceInput\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 vertex_color;\n    vec3 view_dir;\n    bool front_facing;\n};\n\nstruct LightSample\n{\n    vec3 direction;\n    vec3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct Surface\n{\n    vec3 albedo;\n    float alpha;\n    vec3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    vec3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    vec3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    vec3 specular_color;\n    float transmission;\n    float thickness;\n    vec3 attenuation_color;\n    float attenuation_distance;\n};\n\nstruct FaLayers\n{\n    bool on;\n    float f90;\n    float keep;\n    float base_scale;\n    float coat;\n    float coat_rough;\n    float coat_alpha;\n    float coat_a2;\n    vec3 nc;\n    float coat_ndv;\n    bool sheen_on;\n    vec3 sheen;\n    float sheen_rough;\n    float sheen_alpha;\n    float sheen_scale;\n    float sheen_e;\n    float aniso;\n    vec3 t;\n    vec3 b;\n    float at;\n    float ab;\n};\n\nconst float _4970[63] = float[](1.0, 1.0, 1.0, 0.4790000021457672119140625, 0.11699999868869781494140625, 0.01200000010430812835693359375, 0.0, 0.0, 0.0, 1.0, 1.0, 1.0, 0.578000009059906005859375, 0.19300000369548797607421875, 0.0350000001490116119384765625, 0.0030000000260770320892333984375, 0.0, 0.0, 1.0, 1.0, 1.0, 0.6740000247955322265625, 0.3459999859333038330078125, 0.1319999992847442626953125, 0.032999999821186065673828125, 0.0040000001899898052215576171875, 0.0, 0.971000015735626220703125, 0.954999983310699462890625, 0.828999996185302734375, 0.63999998569488525390625, 0.42599999904632568359375, 0.24500000476837158203125, 0.115000002086162567138671875, 0.037000000476837158203125, 0.0030000000260770320892333984375, 0.7469999790191650390625, 0.737999975681304931640625, 0.670000016689300537109375, 0.563000023365020751953125, 0.4309999942779541015625, 0.3039999902248382568359375, 0.1940000057220458984375, 0.1019999980926513671875, 0.0309999994933605194091796875, 0.614000022411346435546875, 0.609000027179718017578125, 0.566999971866607666015625, 0.499000012874603271484375, 0.412000000476837158203125, 0.32400000095367431640625, 0.240999996662139892578125, 0.162000000476837158203125, 0.087999999523162841796875, 0.538999974727630615234375, 0.535000026226043701171875, 0.505999982357025146484375, 0.4569999873638153076171875, 0.393999993801116943359375, 0.328999996185302734375, 0.2660000026226043701171875, 0.203999996185302734375, 0.14200000464916229248046875);\n\nuniform vec4 fa_mesh_fs_params[54];\nuniform vec4 fa_shadows[30];\nuniform vec4 fa_material[1];\nlayout(binding = 0) uniform sampler2D fa_light_tex_fa_shadow_smp;\nlayout(binding = 1) uniform sampler2D fa_tex_fa_smp;\nlayout(binding = 2) uniform sampler2D fa_normal_tex_fa_smp;\nlayout(binding = 3) uniform sampler2D fa_mr_tex_fa_smp;\nlayout(binding = 4) uniform sampler2D fa_occlusion_tex_fa_smp;\nlayout(binding = 5) uniform sampler2D fa_emissive_tex_fa_smp;\nlayout(binding = 6) uniform sampler2D mask_mask_smp;\nlayout(binding = 7) uniform sampler2D fa_decal_tex_fa_env_smp;\nlayout(binding = 8) uniform sampler2D fa_lightmap_fa_env_smp;\nlayout(binding = 9) uniform sampler2D fa_probe_atlas_fa_env_smp;\nlayout(binding = 10) uniform sampler2D fa_light_atlas_fa_env_smp;\nlayout(binding = 11) uniform sampler2D fa_screen_tex_fa_shadow_smp;\nlayout(binding = 12) uniform sampler2D fa_shadow_tex_fa_shadow_smp;\n\nlayout(location = 0) in vec3 fa_world_pos;\nlayout(location = 5) in vec3 fa_lm;\nlayout(location = 1) in vec3 fa_world_normal;\nlayout(location = 2) in vec4 fa_world_tangent;\nlayout(location = 3) in vec2 fa_uv;\nlayout(location = 4) in vec4 fa_vertex_color;\nlayout(location = 0) out vec4 fa_frag_color;\nfloat fa_rt_slope;\nvec3 fa_light_tint;\nbool fa_light_is_area;\nint fa_cl_ndir;\nint fa_cl_slot;\nint fa_cl_local;\n\nvoid fa_inst_load()\n{\n}\n\nvec4 fa_light_texel(int t)\n{\n    return texelFetch(fa_light_tex_fa_shadow_smp, ivec2(t & 1023, t >> 10), 0);\n}\n\nvec4 fa_cluster_texel(vec3 world_pos)\n{\n    bool _1647 = fa_mesh_fs_params[19].x < 0.0;\n    bool _1654;\n    if (!_1647)\n    {\n        _1654 = fa_mesh_fs_params[19].w < 1.0;\n    }\n    else\n    {\n        _1654 = _1647;\n    }\n    bool _1662;\n    if (!_1654)\n    {\n        _1662 = fa_mesh_fs_params[18].x < 1.0;\n    }\n    else\n    {\n        _1662 = _1654;\n    }\n    bool _1669;\n    if (!_1662)\n    {\n        _1669 = fa_mesh_fs_params[18].y < 1.0;\n    }\n    else\n    {\n        _1669 = _1662;\n    }\n    bool _1676;\n    if (!_1669)\n    {\n        _1676 = fa_mesh_fs_params[19].y < 1.0;\n    }\n    else\n    {\n        _1676 = _1669;\n    }\n    if (_1676)\n    {\n        return vec4(0.0);\n    }\n    vec4 _1686 = vec4(world_pos, 1.0);\n    float _1692 = dot(fa_mesh_fs_params[16], _1686);\n    if (!(_1692 > 9.9999999747524270787835121154785e-07))\n    {\n        return vec4(0.0);\n    }\n    vec2 _1714 = vec2(dot(fa_mesh_fs_params[14], _1686), dot(fa_mesh_fs_params[15], _1686)) / vec2(_1692);\n    int _1718 = int(fa_mesh_fs_params[18].x);\n    int _1722 = int(fa_mesh_fs_params[18].y);\n    int param = (int(fa_mesh_fs_params[19].x) + (((clamp(int(floor(log2(max(dot(fa_mesh_fs_params[17].xyz, world_pos) + fa_mesh_fs_params[17].w, fa_mesh_fs_params[18].w) / fa_mesh_fs_params[18].w) * fa_mesh_fs_params[18].z)), 0, int(fa_mesh_fs_params[19].y) - 1) * _1722) + clamp(int(floor(((_1714.y * 0.5) + 0.5) * fa_mesh_fs_params[18].y)), 0, _1722 - 1)) * _1718)) + clamp(int(floor(((_1714.x * 0.5) + 0.5) * fa_mesh_fs_params[18].x)), 0, _1718 - 1);\n    return fa_light_texel(param);\n}\n\nivec2 fa_cluster_lookup(vec3 world_pos)\n{\n    vec3 param = world_pos;\n    vec4 _1798 = fa_cluster_texel(param);\n    return ivec2(int(_1798.x), int(_1798.y));\n}\n\nvoid fa_cluster_begin(vec3 world_pos)\n{\n    float _6604 = dot(fa_mesh_fs_params[29].xyz, world_pos) + fa_mesh_fs_params[29].w;\n    float _6607 = fwidth(_6604);\n    bool _6610 = fa_mesh_fs_params[25].y > 0.5;\n    bool _6617;\n    if (!_6610)\n    {\n        _6617 = fa_mesh_fs_params[25].w > 0.5;\n    }\n    else\n    {\n        _6617 = _6610;\n    }\n    if (_6617)\n    {\n        fa_rt_slope = min(1.5 * _6607, 0.100000001490116119384765625 * _6604);\n    }\n    fa_cl_ndir = int(fa_mesh_fs_params[19].z);\n    vec3 param = world_pos;\n    ivec2 _6633 = fa_cluster_lookup(param);\n    fa_cl_slot = _6633.x;\n    fa_cl_local = _6633.y;\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nvec3 fa_linear_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_tex_fix(inout vec3 c, float mode)\n{\n    if (mode > 1.5)\n    {\n        vec3 param = c;\n        vec3 _7803 = fa_linear_to_srgb(param);\n        c = _7803;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            vec3 param_1 = c;\n            vec3 _7811 = fa_srgb_to_linear(param_1);\n            c = _7811;\n        }\n    }\n    return c;\n}\n\nvec3 fa_tangent_normal(SurfaceInput i, vec3 m)\n{\n    vec3 _554;\n    if (i.front_facing)\n    {\n        _554 = i.world_normal;\n    }\n    else\n    {\n        _554 = -i.world_normal;\n    }\n    vec3 _578 = normalize(i.world_tangent.xyz - (_554 * dot(_554, i.world_tangent.xyz)));\n    vec3 _605 = normalize(((_578 * m.x) + ((cross(_554, _578) * i.world_tangent.w) * m.y)) + (_554 * m.z));\n    vec3 _608;\n    if (i.front_facing)\n    {\n        _608 = _605;\n    }\n    else\n    {\n        _608 = -_605;\n    }\n    return _608;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    vec4 base_t = texture(fa_tex_fa_smp, i.uv, fa_mesh_fs_params[12].w);\n    float param = fa_mesh_fs_params[6].w;\n    float param_1 = 1.0;\n    vec3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    vec3 _7843 = fa_tex_fix(param_2, param_3);\n    vec4 _10228 = base_t;\n    _10228.x = _7843.x;\n    _10228.y = _7843.y;\n    _10228.z = _7843.z;\n    base_t = _10228;\n    vec4 _7857 = (_10228 * fa_mesh_fs_params[2]) * i.vertex_color;\n    vec3 _9975 = i.world_normal;\n    if (fa_mesh_fs_params[6].z > 0.5)\n    {\n        float param_4 = fa_mesh_fs_params[6].w;\n        float param_5 = 16.0;\n        vec3 param_6 = texture(fa_normal_tex_fa_smp, i.uv, fa_mesh_fs_params[12].w).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        vec3 _7891 = fa_tex_fix(param_6, param_7);\n        vec3 _7894 = (_7891 * 2.0) - vec3(1.0);\n        vec2 _7899 = _7894.xy * fa_mesh_fs_params[6].x;\n        vec3 _10236 = _7894;\n        _10236.x = _7899.x;\n        _10236.y = _7899.y;\n        SurfaceInput param_8 = i;\n        vec3 param_9 = _10236;\n        _9975 = fa_tangent_normal(param_8, param_9);\n    }\n    vec4 mrt = texture(fa_mr_tex_fa_smp, i.uv, fa_mesh_fs_params[12].w);\n    float param_10 = fa_mesh_fs_params[6].w;\n    float param_11 = 64.0;\n    vec3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    vec3 _7929 = fa_tex_fix(param_12, param_13);\n    vec4 _10239 = mrt;\n    _10239.x = _7929.x;\n    _10239.y = _7929.y;\n    _10239.z = _7929.z;\n    mrt = _10239;\n    vec4 _7959 = texture(fa_occlusion_tex_fa_smp, i.uv, fa_mesh_fs_params[12].w);\n    float param_14 = fa_mesh_fs_params[6].w;\n    float param_15 = 256.0;\n    vec3 param_16 = _7959.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    vec3 _7970 = fa_tex_fix(param_16, param_17);\n    float param_18 = fa_mesh_fs_params[6].w;\n    float param_19 = 4.0;\n    vec3 param_20 = texture(fa_emissive_tex_fa_smp, i.uv, fa_mesh_fs_params[12].w).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    vec3 _8002 = fa_tex_fix(param_20, param_21);\n    float _9980 = fa_mesh_fs_params[20].x;\n    float _9981 = fa_mesh_fs_params[20].y;\n    float _9984 = fa_mesh_fs_params[20].z;\n    float _9983 = fa_mesh_fs_params[21].w;\n    float _9986 = fa_mesh_fs_params[22].x;\n    if (fa_mesh_fs_params[22].z > 0.5)\n    {\n        if (mod(fa_mesh_fs_params[22].z, 2.0) > 0.5)\n        {\n            _9980 *= _7970.y;\n            _9981 *= _7970.z;\n            _9983 *= _7959.w;\n        }\n        if (fa_mesh_fs_params[22].z > 1.5)\n        {\n            _9984 *= mrt.x;\n            _9986 *= mrt.w;\n        }\n    }\n    return Surface(_7857.xyz, _7857.w, _9975, clamp(fa_mesh_fs_params[5].x * _7929.z, 0.0, 1.0), clamp(fa_mesh_fs_params[5].y * _7929.y, 0.0500000007450580596923828125, 1.0), 1.0 + (fa_mesh_fs_params[6].y * (_7970.x - 1.0)), fa_mesh_fs_params[3].xyz + (fa_mesh_fs_params[4].xyz * _8002), _9980, _9981, fa_mesh_fs_params[21].xyz, _9983, _9984, fa_mesh_fs_params[20].w, _9986, fa_mesh_fs_params[22].y, fa_mesh_fs_params[23].xyz, fa_mesh_fs_params[30].x, fa_mesh_fs_params[30].y, fa_mesh_fs_params[31].xyz, fa_mesh_fs_params[30].z);\n}\n\nvoid surface(SurfaceInput i, inout Surface s)\n{\n    s.alpha = texture(mask_mask_smp, i.uv * 2.0).x;\n}\n\nvec4 fa_decal_tile(vec4 rect, vec2 uv, vec2 atlas, vec2 ddx, vec2 ddy)\n{\n    vec2 _1878 = rect.zw - rect.xy;\n    vec2 _1882 = _1878 * atlas;\n    vec2 _1886 = ddx * _1882;\n    vec2 _1890 = ddy * _1882;\n    return textureLod(fa_decal_tex_fa_env_smp, rect.xy + (clamp(uv, vec2(0.0), vec2(1.0)) * _1878), clamp(0.5 * log2(max(max(dot(_1886, _1886), dot(_1890, _1890)), 9.9999999392252902907785028219223e-09)), 0.0, 3.0));\n}\n\nvec3 fa_dc_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_dc_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvoid fa_apply_decals(vec3 world_pos, vec3 geo_normal, inout vec3 albedo, inout vec3 normal)\n{\n    bool _1923 = fa_mesh_fs_params[10].y < 0.5;\n    bool _1930;\n    if (!_1923)\n    {\n        _1930 = fa_mesh_fs_params[10].w < 0.5;\n    }\n    else\n    {\n        _1930 = _1923;\n    }\n    if (_1930)\n    {\n        return;\n    }\n    vec3 _1936 = dFdx(world_pos);\n    vec3 _1939 = dFdy(world_pos);\n    vec3 param = world_pos;\n    vec4 _1943 = fa_cluster_texel(param);\n    int _1947 = int(_1943.w);\n    if (_1947 < 1)\n    {\n        return;\n    }\n    int _1957 = int(fa_mesh_fs_params[10].y + 0.5);\n    int param_1 = _1957;\n    vec4 _1961 = fa_light_texel(param_1);\n    vec2 _1964 = _1961.yz;\n    int _1968 = int(_1961.w);\n    int param_2 = _1957 + 1;\n    vec4 _1973 = fa_light_texel(param_2);\n    float _1974 = _1973.x;\n    int _1980 = int(fa_mesh_fs_params[10].w + 0.5) - 1;\n    int _1984 = int(_1943.z);\n    vec3 _2249;\n    for (int k = 0; k < _1947; k++)\n    {\n        int _1997 = _1984 + k;\n        int param_3 = _1968 + (_1997 >> 2);\n        int _2014 = (_1957 + 2) + (int(fa_light_texel(param_3)[_1997 & 3]) * 7);\n        int param_4 = _2014 + 6;\n        vec4 _2019 = fa_light_texel(param_4);\n        if (((int(_2019.w + 0.5) >> _1980) & 1) == 0)\n        {\n            continue;\n        }\n        int param_5 = _2014;\n        vec4 _2034 = fa_light_texel(param_5);\n        int param_6 = _2014 + 1;\n        vec4 _2039 = fa_light_texel(param_6);\n        int param_7 = _2014 + 2;\n        vec4 _2044 = fa_light_texel(param_7);\n        vec3 _2047 = _2034.xyz;\n        float _2052 = dot(_2047, world_pos) + _2034.w;\n        vec3 _2054 = _2039.xyz;\n        float _2059 = dot(_2054, world_pos) + _2039.w;\n        vec3 _2061 = _2044.xyz;\n        float _2066 = dot(_2061, world_pos) + _2044.w;\n        bool _2071 = abs(_2052) > 0.5;\n        bool _2079;\n        if (!_2071)\n        {\n            _2079 = abs(_2059) > 0.5;\n        }\n        else\n        {\n            _2079 = _2071;\n        }\n        bool _2087;\n        if (!_2079)\n        {\n            _2087 = abs(_2066) > 0.5;\n        }\n        else\n        {\n            _2087 = _2079;\n        }\n        if (_2087)\n        {\n            continue;\n        }\n        float _2102 = clamp(dot(geo_normal, normalize(_2061)) * _2019.z, 0.0, 1.0);\n        if (_2102 <= 0.0)\n        {\n            continue;\n        }\n        float _2122 = (clamp((0.5 - abs(_2066)) * 10.0, 0.0, 1.0) * _2102) * _2019.x;\n        vec2 _2130 = vec2(_2052 + 0.5, 0.5 - _2059);\n        vec2 _2140 = vec2(dot(_2047, _1936), dot(_2054, _1936));\n        vec2 _2150 = vec2(dot(_2047, _1939), dot(_2054, _1939));\n        int param_8 = _2014 + 5;\n        vec4 _2155 = fa_light_texel(param_8);\n        int param_9 = _2014 + 3;\n        vec4 _2160 = fa_light_texel(param_9);\n        int param_10 = _2014 + 4;\n        vec4 _2165 = fa_light_texel(param_10);\n        float tex_a = 1.0;\n        vec3 col = _2155.xyz;\n        bool _2175 = _2160.z > _2160.x;\n        if (_2175)\n        {\n            vec4 param_11 = _2160;\n            vec2 param_12 = _2130;\n            vec2 param_13 = _1964;\n            vec2 param_14 = _2140;\n            vec2 param_15 = _2150;\n            vec4 tx = fa_decal_tile(param_11, param_12, param_13, param_14, param_15);\n            if ((_1974 > 0.5) && (_1974 < 1.5))\n            {\n                vec3 param_16 = tx.xyz;\n                vec3 _2201 = fa_dc_to_linear(param_16);\n                vec4 _10063 = tx;\n                _10063.x = _2201.x;\n                _10063.y = _2201.y;\n                _10063.z = _2201.z;\n                tx = _10063;\n            }\n            col *= tx.xyz;\n            tex_a = tx.w;\n        }\n        albedo = mix(albedo, col, vec3(clamp((_2122 * tex_a) * _2155.w, 0.0, 1.0)));\n        if (_2165.z > _2165.x)\n        {\n            vec4 param_17 = _2165;\n            vec2 param_18 = _2130;\n            vec2 param_19 = _1964;\n            vec2 param_20 = _2140;\n            vec2 param_21 = _2150;\n            vec4 _2245 = fa_decal_tile(param_17, param_18, param_19, param_20, param_21);\n            if (_1974 > 1.5)\n            {\n                vec3 param_22 = _2245.xyz;\n                vec3 _2255 = fa_dc_to_srgb(param_22);\n                _2249 = _2255;\n            }\n            else\n            {\n                _2249 = _2245.xyz;\n            }\n            vec3 _2264 = (_2249 * 2.0) - vec3(1.0);\n            vec2 _2269 = _2264.xy * _2019.y;\n            vec3 _2291 = (normalize(_2047) * _2269.x) + (normalize(_2054) * _2269.y);\n            vec3 _2294 = normalize(normal);\n            normal = normalize(mix(_2294, normalize((_2294 * max(_2264.z, 0.0500000007450580596923828125)) + (_2291 - (_2294 * dot(_2294, _2291)))), vec3(clamp(_2122 * (_2175 ? tex_a : 1.0), 0.0, 1.0))));\n        }\n    }\n}\n\nvoid fa_lod_dither()\n{\n    if (fa_mesh_fs_params[52].w != 0.0)\n    {\n        float _643 = fract(52.98291778564453125 * fract(dot(gl_FragCoord.xy, vec2(0.067110560834407806396484375, 0.005837149918079376220703125))));\n        bool _646;\n        if (fa_mesh_fs_params[52].w > 0.0)\n        {\n            _646 = _643 >= fa_mesh_fs_params[52].w;\n        }\n        else\n        {\n            _646 = _643 < (-fa_mesh_fs_params[52].w);\n        }\n        if (_646)\n        {\n            discard;\n        }\n    }\n}\n\nfloat fa_sheen_albedo(float ndv, float rough)\n{\n    float _4895 = min(sqrt(max(rough - 0.100000001490116119384765625, 0.0) * 1.111111164093017578125) * 6.0, 5.999000072479248046875);\n    float _4903 = min(sqrt(clamp(ndv, 0.0, 1.0)) * 8.0, 7.999000072479248046875);\n    int _4906 = int(_4895);\n    int _4909 = int(_4903);\n    float _4919 = _4903 - float(_4909);\n    int _4974 = (_4906 * 9) + _4909;\n    int _4994 = ((_4906 + 1) * 9) + _4909;\n    return mix(mix(_4970[_4974], _4970[_4974 + 1], _4919), mix(_4970[_4994], _4970[_4994 + 1], _4919), _4895 - float(_4906));\n}\n\nFaLayers fa_layers_setup(SurfaceInput i, Surface s, vec3 n, vec3 v, float metallic, float roughness, inout vec3 f0)\n{\n    bool _9898 = false;\n    float _9899 = 1.0;\n    float _9900 = 1.0;\n    float _9901 = 1.0;\n    float _9902 = 0.0;\n    float _9903 = 0.0;\n    float _9904 = 0.0;\n    float _9905 = 0.0;\n    float _9907 = 1.0;\n    bool _9908 = false;\n    vec3 _9909 = vec3(0.0);\n    float _9910 = 1.0;\n    float _9911 = 1.0;\n    float _9912 = 1.0;\n    float _9913 = 0.0;\n    float _9914 = 0.0;\n    vec3 _9915 = vec3(1.0, 0.0, 0.0);\n    vec3 _9916 = vec3(0.0, 0.0, 1.0);\n    float _9917 = 1.0;\n    float _9918 = 1.0;\n    float _5045 = clamp(s.specular, 0.0, 1.0);\n    float _5049 = clamp(s.ior, 1.0, 3.0);\n    bool _5054 = (_5045 != 1.0) || (_5049 != 1.5);\n    bool _5063;\n    if (!_5054)\n    {\n        _5063 = any(notEqual(s.specular_color, vec3(1.0)));\n    }\n    else\n    {\n        _5063 = _5054;\n    }\n    if (_5063)\n    {\n        float _5071 = (_5049 - 1.0) / (_5049 + 1.0);\n        f0 = mix(min(vec3(_5071 * _5071) * max(s.specular_color, vec3(0.0)), vec3(1.0)) * _5045, s.albedo, vec3(metallic));\n        _9899 = mix(_5045, 1.0, metallic);\n        _9898 = true;\n    }\n    float _5098 = clamp(s.clearcoat, 0.0, 1.0);\n    if (_5098 > 0.0)\n    {\n        float _5106 = clamp(s.clearcoat_roughness, 0.0500000007450580596923828125, 1.0);\n        _9902 = _5098;\n        _9903 = _5106;\n        float _5113 = _5106 * _5106;\n        _9904 = _5113;\n        _9905 = _5113 * _5113;\n        float _5125 = max(dot(i.world_normal, v), 9.9999997473787516355514526367188e-05);\n        _9907 = _5125;\n        _9900 = 1.0 - (_5098 * (0.039999999105930328369140625 + (0.959999978542327880859375 * pow(clamp(1.0 - _5125, 0.0, 1.0), 5.0))));\n        _9898 = true;\n    }\n    vec3 _5144 = max(s.sheen_color, vec3(0.0));\n    float _5153 = max(_5144.x, max(_5144.y, _5144.z));\n    if (_5153 > 0.0)\n    {\n        float _5161 = clamp(s.sheen_roughness, 0.100000001490116119384765625, 1.0);\n        _9908 = true;\n        _9909 = _5144;\n        _9910 = _5161;\n        _9911 = _5161 * _5161;\n        float param = max(dot(n, v), 9.9999997473787516355514526367188e-05);\n        float param_1 = _5161;\n        float _5178 = fa_sheen_albedo(param, param_1);\n        _9913 = _5178;\n        _9912 = 1.0 - min(_5153 * _5178, 1.0);\n        _9898 = true;\n    }\n    _9901 = _9900 * _9912;\n    float _5197 = clamp(s.anisotropy, -1.0, 1.0);\n    if (_5197 != 0.0)\n    {\n        vec3 _5212 = i.world_tangent.xyz - (n * dot(n, i.world_tangent.xyz));\n        vec3 t = _5212;\n        if (dot(_5212, _5212) < 9.9999999392252902907785028219223e-09)\n        {\n            bvec3 _5224 = bvec3(abs(n.y) < 0.9900000095367431640625);\n            t = cross(vec3(_5224.x ? vec3(0.0, 1.0, 0.0).x : vec3(1.0, 0.0, 0.0).x, _5224.y ? vec3(0.0, 1.0, 0.0).y : vec3(1.0, 0.0, 0.0).y, _5224.z ? vec3(0.0, 1.0, 0.0).z : vec3(1.0, 0.0, 0.0).z), n);\n        }\n        vec3 _5228 = t;\n        vec3 _5229 = normalize(_5228);\n        t = _5229;\n        vec3 _5254 = normalize((_5229 * cos(s.anisotropy_rotation)) + ((cross(n, _5229) * ((i.world_tangent.w < 0.0) ? (-1.0) : 1.0)) * sin(s.anisotropy_rotation)));\n        _9915 = _5254;\n        _9916 = cross(n, _5254);\n        float _5264 = roughness * roughness;\n        float _5270 = mix(_5264, 1.0, _5197 * _5197);\n        bool _5272 = _5197 > 0.0;\n        _9917 = _5272 ? _5270 : _5264;\n        _9918 = _5272 ? _5264 : _5270;\n        _9914 = _5197;\n        _9898 = true;\n    }\n    return FaLayers(_9898, _9899, _9900, _9901, _9902, _9903, _9904, _9905, i.world_normal, _9907, _9908, _9909, _9910, _9911, _9912, _9913, _9914, _9915, _9916, _9917, _9918);\n}\n\nvec2 fa_atlas_size()\n{\n    return vec2(textureSize(fa_probe_atlas_fa_env_smp, 0));\n}\n\nvec3 fa_probe_sh_coef(vec2 origin, float res, int k)\n{\n    vec3 v = textureLod(fa_probe_atlas_fa_env_smp, (origin + vec2(float(k) + 0.5, res + 2.5)) / fa_atlas_size(), 0.0).xyz;\n    if (fa_mesh_fs_params[41].y > 0.5)\n    {\n        v = ((v * 255.0) - vec3(128.0)) * 0.03149606287479400634765625;\n    }\n    return v;\n}\n\nvec3 fa_sh_eval(vec3 c[9], vec3 n)\n{\n    vec3 _4065 = max((((c[0] * 0.2820948064327239990234375) + (((c[1] * (0.3257350027561187744140625 * n.y)) + (c[2] * (0.3257350027561187744140625 * n.z))) + (c[3] * (0.3257350027561187744140625 * n.x)))) + (((c[4] * ((0.2731371223926544189453125 * n.x) * n.y)) + (c[5] * ((0.2731371223926544189453125 * n.y) * n.z))) + (c[6] * (0.078847892582416534423828125 * (((3.0 * n.z) * n.z) - 1.0))))) + ((c[7] * ((0.2731371223926544189453125 * n.x) * n.z)) + (c[8] * (0.13656856119632720947265625 * ((n.x * n.x) - (n.y * n.y))))), vec3(0.0));\n    return _4065;\n}\n\nvec3 fa_ambient_light(vec3 n)\n{\n    float _4676 = (1.0 - fa_mesh_fs_params[42].w) - fa_mesh_fs_params[47].w;\n    vec3 amb = vec3(0.0);\n    bool _4681 = fa_mesh_fs_params[11].w > 0.5;\n    vec3 c[9];\n    for (int k = 0; k < 9; k++)\n    {\n        c[k] = vec3(0.0);\n    }\n    if (_4676 > 0.0005000000237487256526947021484375)\n    {\n        if (_4681)\n        {\n            for (int k_1 = 0; k_1 < 9; k_1++)\n            {\n                vec2 param = fa_mesh_fs_params[41].zw;\n                float param_1 = 128.0;\n                int param_2 = k_1;\n                c[k_1] = fa_probe_sh_coef(param, param_1, param_2) * _4676;\n            }\n        }\n        else\n        {\n            amb = fa_mesh_fs_params[1].xyz * _4676;\n        }\n    }\n    bool _4732 = fa_mesh_fs_params[42].w > 0.0;\n    if (_4732)\n    {\n        for (int k_2 = 0; k_2 < 9; k_2++)\n        {\n            vec2 param_3 = fa_mesh_fs_params[42].xy;\n            float param_4 = fa_mesh_fs_params[42].z;\n            int param_5 = k_2;\n            c[k_2] += (fa_probe_sh_coef(param_3, param_4, param_5) * fa_mesh_fs_params[42].w);\n        }\n    }\n    bool _4763 = fa_mesh_fs_params[47].w > 0.0;\n    if (_4763)\n    {\n        for (int k_3 = 0; k_3 < 9; k_3++)\n        {\n            vec2 param_6 = fa_mesh_fs_params[47].xy;\n            float param_7 = fa_mesh_fs_params[47].z;\n            int param_8 = k_3;\n            c[k_3] += (fa_probe_sh_coef(param_6, param_7, param_8) * fa_mesh_fs_params[47].w);\n        }\n    }\n    if ((_4681 || _4732) || _4763)\n    {\n        vec3 param_9[9] = c;\n        vec3 param_10 = n;\n        amb += fa_sh_eval(param_9, param_10);\n    }\n    return amb;\n}\n\nvec4 fa_gi_fetch(vec2 texel)\n{\n    return textureLod(fa_probe_atlas_fa_env_smp, texel / fa_atlas_size(), 0.0);\n}\n\nvec2 fa_oct_encode(vec3 d)\n{\n    vec3 _4085 = d / vec3(max((abs(d.x) + abs(d.y)) + abs(d.z), 9.9999999600419720025001879548654e-13));\n    float _4088 = _4085.x;\n    float _4090 = _4085.z;\n    vec2 e = vec2(_4088, _4090);\n    if (_4085.y < 0.0)\n    {\n        e = vec2((1.0 - abs(_4090)) * ((_4088 < 0.0) ? (-1.0) : 1.0), (1.0 - abs(_4088)) * ((_4090 < 0.0) ? (-1.0) : 1.0));\n    }\n    return e;\n}\n\nvec3 fa_gi_grid(int rec, vec3 n, vec3 v, out float cover)\n{\n    cover = 0.0;\n    int param = rec;\n    vec4 _8112 = fa_light_texel(param);\n    int param_1 = rec + 1;\n    vec4 _8117 = fa_light_texel(param_1);\n    int param_2 = rec + 2;\n    vec4 _8122 = fa_light_texel(param_2);\n    int param_3 = rec + 3;\n    vec4 _8127 = fa_light_texel(param_3);\n    bool _8130 = _8127.z < 0.5;\n    bool _8138;\n    if (!_8130)\n    {\n        _8138 = fa_atlas_size().y < 1155.0;\n    }\n    else\n    {\n        _8138 = _8130;\n    }\n    if (_8138)\n    {\n        return vec3(0.0);\n    }\n    float _8145 = max(_8112.w, 9.9999997473787516355514526367188e-05);\n    vec3 _8148 = _8117.xyz;\n    vec3 _8152 = _8112.xyz;\n    vec3 _8156 = (fa_world_pos - _8152) / vec3(_8145);\n    vec3 _8165 = min(_8156 + vec3(0.5), (_8148 - vec3(0.5)) - _8156);\n    float _8174 = min(_8165.x, min(_8165.y, _8165.z));\n    if (!(_8174 > 0.0))\n    {\n        return vec3(0.0);\n    }\n    vec3 _8189 = _8148 - vec3(1.0);\n    vec3 _8190 = clamp(_8156, vec3(0.0), _8189);\n    vec3 _8198 = min(floor(_8190), max(_8148 - vec3(2.0), vec3(0.0)));\n    vec3 _8202 = _8190 - _8198;\n    vec3 _8213 = fa_world_pos + (((n * 0.800000011920928955078125) + (v * 0.20000000298023223876953125)) * (0.20000000298023223876953125 * _8145));\n    int _8218 = int(_8122.y + 0.5);\n    float _8223 = 0.3257350027561187744140625 * n.y;\n    float _8227 = 0.3257350027561187744140625 * n.z;\n    float _8231 = 0.3257350027561187744140625 * n.x;\n    float _8238 = (0.2731371223926544189453125 * n.x) * n.y;\n    float _8245 = (0.2731371223926544189453125 * n.y) * n.z;\n    float _8254 = 0.078847892582416534423828125 * (((3.0 * n.z) * n.z) - 1.0);\n    float _8261 = (0.2731371223926544189453125 * n.x) * n.z;\n    float _8274 = 0.13656856119632720947265625 * ((n.x * n.x) - (n.y * n.y));\n    vec3 acc = vec3(0.0);\n    float wsum = 0.0;\n    int _8281 = 8 + int(_8127.w);\n    float _8308;\n    float _8321;\n    float _8335;\n    for (int k = 0; k < _8281; k++)\n    {\n        float _8294 = float(k & 1);\n        float _8298 = float((k >> 1) & 1);\n        float _8302 = float((k >> 2) & 1);\n        if (_8294 > 0.5)\n        {\n            _8308 = _8202.x;\n        }\n        else\n        {\n            _8308 = 1.0 - _8202.x;\n        }\n        if (_8298 > 0.5)\n        {\n            _8321 = _8202.y;\n        }\n        else\n        {\n            _8321 = 1.0 - _8202.y;\n        }\n        if (_8302 > 0.5)\n        {\n            _8335 = _8202.z;\n        }\n        else\n        {\n            _8335 = 1.0 - _8202.z;\n        }\n        float _8345 = (_8308 * _8321) * _8335;\n        if (!(_8345 > 0.0))\n        {\n            continue;\n        }\n        vec3 _8358 = min(_8198 + vec3(_8294, _8298, _8302), _8189);\n        int _8378 = int(((_8122.x + _8358.x) + (_8117.x * (_8358.y + (_8117.y * _8358.z)))) + 0.5);\n        vec2 _8393 = vec2(float(_8378 % _8218) * 10.0, 1024.0 + (float(_8378 / _8218) * 11.0));\n        vec2 param_4 = _8393 + vec2(9.5, 10.5);\n        vec4 _8401 = fa_gi_fetch(param_4);\n        bool _8404 = _8401.y < 0.5;\n        bool _8413;\n        if (!_8404)\n        {\n            _8413 = _8401.x > _8127.y;\n        }\n        else\n        {\n            _8413 = _8404;\n        }\n        if (_8413)\n        {\n            continue;\n        }\n        vec3 _8425 = _8213 - (_8152 + (_8358 * _8145));\n        float _8428 = length(_8425);\n        vec3 _8434 = _8425 / vec3(max(_8428, 9.9999997473787516355514526367188e-05));\n        float _8444 = max(9.9999997473787516355514526367188e-05, (dot(-_8434, n) + 1.0) * 0.5);\n        float w = _8345 * (_8444 * _8444);\n        vec3 param_5 = _8434;\n        vec2 param_6 = (_8393 + vec2(1.0)) + (((fa_oct_encode(param_5) * 0.5) + vec2(0.5)) * 8.0);\n        vec4 _8463 = fa_gi_fetch(param_6);\n        float _8470 = _8428 / max(_8122.z, 9.9999997473787516355514526367188e-05);\n        float _8473 = _8463.x;\n        if (_8470 > _8473)\n        {\n            float _8486 = max(_8463.y - (_8473 * _8473), 0.0);\n            float _8491 = _8470 - _8473;\n            float _8500 = _8486 / max(_8486 + (_8491 * _8491), 9.9999999600419720025001879548654e-13);\n            w *= ((_8500 * _8500) * _8500);\n        }\n        if (!(w > 0.0))\n        {\n            continue;\n        }\n        vec2 param_7 = _8393 + vec2(0.5, 10.5);\n        vec2 param_8 = _8393 + vec2(1.5, 10.5);\n        vec2 param_9 = _8393 + vec2(2.5, 10.5);\n        vec2 param_10 = _8393 + vec2(3.5, 10.5);\n        vec2 param_11 = _8393 + vec2(4.5, 10.5);\n        vec2 param_12 = _8393 + vec2(5.5, 10.5);\n        vec2 param_13 = _8393 + vec2(6.5, 10.5);\n        vec2 param_14 = _8393 + vec2(7.5, 10.5);\n        vec2 param_15 = _8393 + vec2(8.5, 10.5);\n        acc += ((((((((((fa_gi_fetch(param_7).xyz * 0.2820948064327239990234375) + (fa_gi_fetch(param_8).xyz * _8223)) + (fa_gi_fetch(param_9).xyz * _8227)) + (fa_gi_fetch(param_10).xyz * _8231)) + (fa_gi_fetch(param_11).xyz * _8238)) + (fa_gi_fetch(param_12).xyz * _8245)) + (fa_gi_fetch(param_13).xyz * _8254)) + (fa_gi_fetch(param_14).xyz * _8261)) + (fa_gi_fetch(param_15).xyz * _8274)) * w);\n        wsum += w;\n    }\n    if (!(wsum > 9.9999997473787516355514526367188e-06))\n    {\n        return vec3(0.0);\n    }\n    cover = smoothstep(0.0, 1.0, clamp(_8174 * 2.0, 0.0, 1.0)) * smoothstep(0.0, 0.0199999995529651641845703125, wsum);\n    float _8624;\n    if (fa_mesh_fs_params[52].z > 0.5)\n    {\n        _8624 = _8127.x;\n    }\n    else\n    {\n        _8624 = 1.0;\n    }\n    return max(acc / vec3(wsum), vec3(0.0)) * (_8122.w * _8624);\n}\n\nvec3 fa_gi_light(vec3 n, inout float left)\n{\n    left = 1.0;\n    vec3 acc = vec3(0.0);\n    vec3 _8648 = normalize(fa_mesh_fs_params[0].xyz - fa_world_pos);\n    int _8653 = int(fa_mesh_fs_params[52].x + 0.5);\n    int _8658 = int(fa_mesh_fs_params[52].y + 0.5);\n    float param_3;\n    for (int k = 0; (k < _8658) && (k < 8); k++)\n    {\n        int param = _8653 + (4 * k);\n        vec3 param_1 = n;\n        vec3 param_2 = _8648;\n        vec3 _8683 = fa_gi_grid(param, param_1, param_2, param_3);\n        float _8688 = param_3 * left;\n        acc += (_8683 * _8688);\n        left -= _8688;\n        if (left < 0.001000000047497451305389404296875)\n        {\n            left = 0.0;\n            break;\n        }\n    }\n    return acc;\n}\n\nvec3 fa_realtime_or_ambient(vec3 n)\n{\n    vec3 gi = vec3(0.0);\n    float left = 1.0;\n    if (fa_mesh_fs_params[52].y > 0.5)\n    {\n        vec3 param = n;\n        float param_1;\n        vec3 _8717 = fa_gi_light(param, param_1);\n        left = param_1;\n        gi = _8717;\n    }\n    if (left <= 0.0)\n    {\n        return gi;\n    }\n    vec3 param_2 = n;\n    return gi + (fa_ambient_light(param_2) * left);\n}\n\nvec3 fa_indirect_diffuse(vec3 n)\n{\n    if (fa_lm.z > 0.5)\n    {\n        return textureLod(fa_lightmap_fa_env_smp, fa_lm.xy, 0.0).xyz;\n    }\n    if (fa_mesh_fs_params[53].x > 0.5)\n    {\n        vec4 _8759 = vec4(fa_world_pos, 1.0);\n        vec2 _8778 = vec2(dot(fa_mesh_fs_params[26], _8759), dot(fa_mesh_fs_params[27], _8759)) / vec2(max(dot(fa_mesh_fs_params[28], _8759), 9.9999997473787516355514526367188e-05));\n        float _8787;\n        if (fa_mesh_fs_params[24].y > 0.5)\n        {\n            _8787 = (_8778.y * 0.5) + 0.5;\n        }\n        else\n        {\n            _8787 = 0.5 - (_8778.y * 0.5);\n        }\n        return texelFetch(fa_lightmap_fa_env_smp, clamp(ivec2(vec2((_8778.x * 0.5) + 0.5, _8787) * fa_mesh_fs_params[24].zw), ivec2(0), ivec2(fa_mesh_fs_params[24].zw) - ivec2(1)), 0).xyz;\n    }\n    if (fa_mesh_fs_params[32].w > 0.0)\n    {\n        vec3 c[9];\n        for (int k = 0; k < 9; k++)\n        {\n            c[k] = fa_mesh_fs_params[k * 1 + 32].xyz;\n        }\n        vec3 param = n;\n        vec3 param_1[9] = c;\n        vec3 param_2 = n;\n        return mix(fa_ambient_light(param), fa_sh_eval(param_1, param_2), vec3(clamp(fa_mesh_fs_params[32].w, 0.0, 1.0)));\n    }\n    vec3 param_3 = n;\n    return fa_realtime_or_ambient(param_3);\n}\n\nint fa_cluster_index(int slot, int n)\n{\n    int param = (int(fa_mesh_fs_params[19].x) + int(fa_mesh_fs_params[19].w)) + ((slot + n) >> 2);\n    vec4 t = fa_light_texel(param);\n    return int(t[(slot + n) & 3]);\n}\n\nint fa_cl_light(int n)\n{\n    if (n < fa_cl_ndir)\n    {\n        return n;\n    }\n    int param = fa_cl_slot;\n    int param_1 = n - fa_cl_ndir;\n    return fa_cluster_index(param, param_1);\n}\n\nint fa_light_base(int li)\n{\n    return li * ((fa_mesh_fs_params[1].w > 4.5) ? 8 : 4);\n}\n\nbool fa_light_baked(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 3;\n    return fa_light_texel(param_1).w > 0.5;\n}\n\nfloat fa_baked_keep(int li)\n{\n    float _6574;\n    if (fa_lm.z > 0.5)\n    {\n        _6574 = 0.0;\n    }\n    else\n    {\n        _6574 = 1.0 - clamp(fa_mesh_fs_params[32].w, 0.0, 1.0);\n    }\n    bool _6585 = _6574 < 1.0;\n    bool _6591;\n    if (_6585)\n    {\n        int param = li;\n        _6591 = fa_light_baked(param);\n    }\n    else\n    {\n        _6591 = _6585;\n    }\n    return _6591 ? _6574 : 1.0;\n}\n\nfloat fa_light_type(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 1;\n    return fa_light_texel(param_1).w;\n}\n\nvec4 fa_atlas_fetch(vec2 texel)\n{\n    return textureLod(fa_light_atlas_fa_env_smp, texel / vec2(textureSize(fa_light_atlas_fa_env_smp, 0)), 0.0);\n}\n\nvec3 fa_cookie_sample(vec2 tile_origin, vec2 uv)\n{\n    vec2 param = (tile_origin + vec2(1.0)) + (clamp(uv, vec2(0.0), vec2(1.0)) * 254.0);\n    return fa_atlas_fetch(param).xyz;\n}\n\nvec3 fa_area_point(vec3 c, vec3 axis, vec3 ru, vec3 uu, float hx, float hy, float shape, vec3 p, vec3 r)\n{\n    bool _896 = dot(r, r) > 0.5;\n    if (shape > 1.5)\n    {\n        vec3 _909 = (c - (ru * hx)) - p;\n        vec3 _915 = ru * (2.0 * hx);\n        float _921 = max(dot(_915, _915), 9.9999999392252902907785028219223e-09);\n        float _925 = dot(_909, _915);\n        float t = clamp((-_925) / _921, 0.0, 1.0);\n        if (_896)\n        {\n            float _940 = dot(r, _915);\n            float _946 = _921 - (_940 * _940);\n            if (abs(_946) > (9.9999997473787516355514526367188e-06 * _921))\n            {\n                t = clamp(((dot(r, _909) * _940) - _925) / _946, 0.0, 1.0);\n            }\n        }\n        return (p + _909) + (_915 * t);\n    }\n    vec3 q = p;\n    float _978 = dot(r, axis);\n    bool _986;\n    if (_896)\n    {\n        _986 = abs(_978) > 9.9999997473787516355514526367188e-05;\n    }\n    else\n    {\n        _986 = _896;\n    }\n    if (_986)\n    {\n        float _996 = dot(c - p, axis) / _978;\n        if (_996 > 0.0)\n        {\n            q = p + (r * _996);\n        }\n    }\n    vec3 _1009 = q - c;\n    vec2 xy = vec2(dot(_1009, ru), dot(_1009, uu));\n    if (shape > 0.5)\n    {\n        float _1024 = length(xy);\n        if (_1024 > hx)\n        {\n            xy *= (hx / _1024);\n        }\n    }\n    else\n    {\n        xy = clamp(xy, vec2(-hx, -hy), vec2(hx, hy));\n    }\n    return (c + (ru * xy.x)) + (uu * xy.y);\n}\n\nint fa_cube_face(vec3 d)\n{\n    vec3 _663 = abs(d);\n    float _665 = _663.x;\n    float _667 = _663.y;\n    bool _668 = _665 >= _667;\n    bool _676;\n    if (_668)\n    {\n        _676 = _665 >= _663.z;\n    }\n    else\n    {\n        _676 = _668;\n    }\n    int _677;\n    if (_676)\n    {\n        _677 = (d.x > 0.0) ? 0 : 1;\n    }\n    else\n    {\n        int _691;\n        if (_667 >= _663.z)\n        {\n            _691 = (d.y > 0.0) ? 2 : 3;\n        }\n        else\n        {\n            _691 = (d.z > 0.0) ? 4 : 5;\n        }\n        _677 = _691;\n    }\n    return _677;\n}\n\nvoid fa_cube_face_basis(int f, out vec3 fwd, out vec3 up)\n{\n    if (f == 0)\n    {\n        fwd = vec3(1.0, 0.0, 0.0);\n        up = vec3(0.0, 1.0, 0.0);\n    }\n    else\n    {\n        if (f == 1)\n        {\n            fwd = vec3(-1.0, 0.0, 0.0);\n            up = vec3(0.0, 1.0, 0.0);\n        }\n        else\n        {\n            if (f == 2)\n            {\n                fwd = vec3(0.0, 1.0, 0.0);\n                up = vec3(0.0, 0.0, 1.0);\n            }\n            else\n            {\n                if (f == 3)\n                {\n                    fwd = vec3(0.0, -1.0, 0.0);\n                    up = vec3(0.0, 0.0, -1.0);\n                }\n                else\n                {\n                    if (f == 4)\n                    {\n                        fwd = vec3(0.0, 0.0, 1.0);\n                        up = vec3(0.0, 1.0, 0.0);\n                    }\n                    else\n                    {\n                        fwd = vec3(0.0, 0.0, -1.0);\n                        up = vec3(0.0, 1.0, 0.0);\n                    }\n                }\n            }\n        }\n    }\n}\n\nfloat fa_ies_sample(vec2 tile_origin, vec3 d, vec3 axis, vec3 right, vec3 up)\n{\n    float _816 = dot(d, right);\n    float _820 = dot(d, up);\n    float _831;\n    if (((_816 * _816) + (_820 * _820)) > 1.0000000133514319600180897396058e-10)\n    {\n        _831 = atan(_820, _816) * 0.15915493667125701904296875;\n    }\n    else\n    {\n        _831 = 0.0;\n    }\n    vec2 param = tile_origin + vec2(1.0 + ((_831 - floor(_831)) * 64.0), 1.0 + (acos(clamp(dot(d, axis), -1.0, 1.0)) * 10.18591594696044921875));\n    return fa_atlas_fetch(param).x;\n}\n\nLightSample fa_light_sample_n(int li, vec3 world_pos, vec3 n)\n{\n    int param = li;\n    int _1062 = fa_light_base(param);\n    bool _1066 = fa_mesh_fs_params[1].w > 4.5;\n    int param_1 = _1062;\n    vec4 _1070 = fa_light_texel(param_1);\n    int param_2 = _1062 + 1;\n    vec4 _1075 = fa_light_texel(param_2);\n    float _1078 = _1075.w;\n    float atten = 1.0;\n    float dist = 0.0;\n    fa_light_tint = vec3(1.0);\n    bool _1090 = _1066 && (_1078 > 2.5);\n    fa_light_is_area = _1090;\n    bool _1092 = _1078 < 0.5;\n    vec3 l;\n    if (_1092)\n    {\n        l = normalize(_1070.xyz);\n        if (_1066)\n        {\n            int param_3 = _1062 + 6;\n            vec4 _1106 = fa_light_texel(param_3);\n            if (_1106.z > 0.5)\n            {\n                int param_4 = _1062 + 4;\n                vec4 _1116 = fa_light_texel(param_4);\n                int param_5 = _1062 + 5;\n                vec4 _1121 = fa_light_texel(param_5);\n                vec2 param_6 = _1106.xy;\n                vec2 param_7 = fract(vec2(dot(world_pos, _1116.xyz) * _1116.w, (-dot(world_pos, _1121.xyz)) * _1121.w) + vec2(0.5));\n                fa_light_tint = fa_cookie_sample(param_6, param_7);\n            }\n        }\n    }\n    else\n    {\n        vec3 _1151 = _1070.xyz;\n        vec3 _1153 = _1151 - world_pos;\n        vec3 to_light = _1153;\n        float _1156 = length(_1153);\n        float reach = _1156;\n        bool front = true;\n        if (_1090)\n        {\n            int param_8 = _1062 + 7;\n            reach = max(_1156 - fa_light_texel(param_8).w, 0.0);\n            int param_9 = _1062 + 4;\n            vec4 _1180 = fa_light_texel(param_9);\n            int param_10 = _1062 + 5;\n            vec4 _1185 = fa_light_texel(param_10);\n            int param_11 = _1062 + 6;\n            vec4 _1190 = fa_light_texel(param_11);\n            float _1191 = _1190.w;\n            int param_12 = _1062 + 2;\n            vec3 _1198 = normalize(fa_light_texel(param_12).xyz);\n            bool _1200 = _1191 > 1.5;\n            bool _1208;\n            if (!_1200)\n            {\n                _1208 = dot(_1198, to_light) < 0.0;\n            }\n            else\n            {\n                _1208 = _1200;\n            }\n            front = _1208;\n            vec3 r = vec3(0.0);\n            vec3 _1217 = fa_mesh_fs_params[0].xyz - world_pos;\n            bool _1221 = dot(n, n) > 0.5;\n            bool _1229;\n            if (_1221)\n            {\n                _1229 = dot(_1217, _1217) > 9.9999999600419720025001879548654e-13;\n            }\n            else\n            {\n                _1229 = _1221;\n            }\n            if (_1229)\n            {\n                r = reflect(-normalize(_1217), normalize(n));\n            }\n            vec3 param_13 = _1151;\n            vec3 param_14 = _1198;\n            vec3 param_15 = _1180.xyz;\n            vec3 param_16 = _1185.xyz;\n            float param_17 = _1180.w;\n            float param_18 = _1185.w;\n            float param_19 = _1191;\n            vec3 param_20 = world_pos;\n            vec3 param_21 = r;\n            to_light = fa_area_point(param_13, param_14, param_15, param_16, param_17, param_18, param_19, param_20, param_21) - world_pos;\n        }\n        float _1265 = length(to_light);\n        dist = _1265;\n        l = to_light / vec3(max(_1265, 9.9999997473787516355514526367188e-05));\n        float _1279 = reach / max(_1070.w, 0.001000000047497451305389404296875);\n        float _1285 = clamp(1.0 - (_1279 * _1279), 0.0, 1.0);\n        float _1287;\n        if (front)\n        {\n            _1287 = _1285 * _1285;\n        }\n        else\n        {\n            _1287 = 0.0;\n        }\n        atten = _1287;\n        bool _1298 = _1078 < 2.5;\n        if ((_1078 > 1.5) && _1298)\n        {\n            int param_22 = _1062 + 2;\n            vec4 _1306 = fa_light_texel(param_22);\n            float _1316 = _1306.w;\n            int param_23 = _1062 + 3;\n            vec4 _1321 = fa_light_texel(param_23);\n            float _1322 = _1321.x;\n            float cos_inner = _1322;\n            if (_1322 > 1.5)\n            {\n                cos_inner = mix(_1316, 1.0, 0.25);\n            }\n            atten *= smoothstep(_1316, cos_inner, dot(-l, normalize(_1306.xyz)));\n        }\n        if (_1066 && (_1078 < 1.5))\n        {\n            int param_24 = _1062 + 6;\n            vec4 _1346 = fa_light_texel(param_24);\n            if (_1346.z > 0.5)\n            {\n                vec3 _1354 = -to_light;\n                int param_25 = _1062 + 4;\n                int param_26 = _1062 + 5;\n                vec3 _1368 = fa_light_texel(param_25).xyz;\n                vec3 _1372 = fa_light_texel(param_26).xyz;\n                vec3 _1381 = vec3(dot(_1354, _1368), dot(_1354, _1372), dot(_1354, cross(_1368, _1372)));\n                vec3 param_27 = _1381;\n                int _1385 = fa_cube_face(param_27);\n                int param_28 = _1385;\n                vec3 param_29;\n                vec3 param_30;\n                fa_cube_face_basis(param_28, param_29, param_30);\n                vec2 _1412 = vec2(dot(_1381, cross(param_29, param_30)), dot(_1381, param_30)) / vec2(max(dot(_1381, param_29), 9.9999997473787516355514526367188e-05));\n                int _1416 = _1385 / 3;\n                vec2 param_31 = _1346.xy + (vec2(float(_1385 - (_1416 * 3)), float(_1416)) * 256.0);\n                vec2 param_32 = vec2(0.5 + (0.5 * _1412.x), 0.5 - (0.5 * _1412.y));\n                fa_light_tint = fa_cookie_sample(param_31, param_32);\n            }\n            int param_33 = _1062 + 7;\n            vec4 _1446 = fa_light_texel(param_33);\n            if (_1446.z > 0.5)\n            {\n                int param_34 = _1062 + 2;\n                int param_35 = _1062 + 4;\n                int param_36 = _1062 + 5;\n                vec2 param_37 = _1446.xy;\n                vec3 param_38 = -l;\n                vec3 param_39 = normalize(fa_light_texel(param_34).xyz);\n                vec3 param_40 = fa_light_texel(param_35).xyz;\n                vec3 param_41 = fa_light_texel(param_36).xyz;\n                atten *= fa_ies_sample(param_37, param_38, param_39, param_40, param_41);\n            }\n        }\n        else\n        {\n            if (_1066 && _1298)\n            {\n                int param_42 = _1062 + 6;\n                vec4 _1493 = fa_light_texel(param_42);\n                int param_43 = _1062 + 7;\n                vec4 _1498 = fa_light_texel(param_43);\n                bool _1501 = _1493.z > 0.5;\n                bool _1508;\n                if (!_1501)\n                {\n                    _1508 = _1498.z > 0.5;\n                }\n                else\n                {\n                    _1508 = _1501;\n                }\n                if (_1508)\n                {\n                    int param_44 = _1062 + 2;\n                    vec4 _1515 = fa_light_texel(param_44);\n                    vec3 _1519 = normalize(_1515.xyz);\n                    int param_45 = _1062 + 4;\n                    vec4 _1524 = fa_light_texel(param_45);\n                    int param_46 = _1062 + 5;\n                    vec4 _1529 = fa_light_texel(param_46);\n                    if (_1501)\n                    {\n                        vec3 _1537 = -to_light;\n                        float _1544 = _1515.w;\n                        float _1560 = 0.5 / max(dot(_1537, _1519) * (sqrt(max(1.0 - (_1544 * _1544), 0.0)) / max(_1544, 0.001000000047497451305389404296875)), 9.9999997473787516355514526367188e-05);\n                        vec2 param_47 = _1493.xy;\n                        vec2 param_48 = vec2(0.5 + (dot(_1537, _1524.xyz) * _1560), 0.5 - (dot(_1537, _1529.xyz) * _1560));\n                        fa_light_tint = fa_cookie_sample(param_47, param_48);\n                    }\n                    if (_1498.z > 0.5)\n                    {\n                        vec2 param_49 = _1498.xy;\n                        vec3 param_50 = -l;\n                        vec3 param_51 = _1519;\n                        vec3 param_52 = _1524.xyz;\n                        vec3 param_53 = _1529.xyz;\n                        atten *= fa_ies_sample(param_49, param_50, param_51, param_52, param_53);\n                    }\n                }\n            }\n        }\n    }\n    vec3 _9886 = _1075.xyz * atten;\n    if (_1066)\n    {\n        _9886 *= fa_light_tint;\n    }\n    int _1629;\n    if (_1092)\n    {\n        _1629 = 0;\n    }\n    else\n    {\n        _1629 = ((_1078 > 1.5) && (_1078 < 2.5)) ? 2 : 1;\n    }\n    return LightSample(l, _9886, atten, 1.0, dist, _1629);\n}\n\nfloat fa_shadow_split_at(int i)\n{\n    float _2355;\n    if (i == 0)\n    {\n        _2355 = fa_shadows[24].x;\n    }\n    else\n    {\n        float _2371;\n        if (i == 1)\n        {\n            _2371 = fa_shadows[24].y;\n        }\n        else\n        {\n            float _2379;\n            if (i == 2)\n            {\n                _2379 = fa_shadows[24].z;\n            }\n            else\n            {\n                _2379 = fa_shadows[24].w;\n            }\n            _2371 = _2379;\n        }\n        _2355 = _2371;\n    }\n    return _2355;\n}\n\nfloat fa_shadow_depth(inout vec2 uv, vec4 rect)\n{\n    uv = clamp(uv, rect.xy, rect.zw);\n    return textureLod(fa_shadow_tex_fa_shadow_smp, uv, 0.0).x;\n}\n\nfloat fa_shadow_fetch(vec2 uv, vec4 rect, vec3 conv)\n{\n    vec2 param = uv;\n    vec4 param_1 = rect;\n    float _2412 = fa_shadow_depth(param, param_1);\n    float _2416;\n    if (conv.x < 0.5)\n    {\n        _2416 = _2412;\n    }\n    else\n    {\n        _2416 = (conv.y * conv.z) / (conv.z - (_2412 * (conv.z - conv.y)));\n    }\n    return _2416;\n}\n\nfloat fa_shadow_noise()\n{\n    return fract(52.98291778564453125 * fract(dot(gl_FragCoord.xy, vec2(0.067110560834407806396484375, 0.005837149918079376220703125))));\n}\n\nvec2 fa_shadow_vogel_turn(vec2 d)\n{\n    return vec2((d.x * (-0.737368881702423095703125)) - (d.y * 0.675490319728851318359375), (d.y * (-0.737368881702423095703125)) + (d.x * 0.675490319728851318359375));\n}\n\nfloat fa_shadow_filter(vec2 uv, vec4 rect, float zr, float texel_m, float unit, float reach, float plane, vec3 conv, int mode, float k)\n{\n    if (mode == 1)\n    {\n        vec2 param = uv;\n        vec4 param_1 = rect;\n        vec3 param_2 = conv;\n        return float(zr <= fa_shadow_fetch(param, param_1, param_2));\n    }\n    float _2462 = fa_shadow_noise() * 6.283185482025146484375;\n    vec2 _2468 = vec2(cos(_2462), sin(_2462));\n    vec2 dir = _2468;\n    float radius = 1.5;\n    if (mode == 2)\n    {\n        float _2477;\n        if (k < 0.0)\n        {\n            _2477 = (-k) / max(zr, 0.100000001490116119384765625);\n        }\n        else\n        {\n            _2477 = k;\n        }\n        float _2496 = clamp((_2477 * reach) / texel_m, 3.0, 12.0);\n        float sum = 0.0;\n        float cnt = 0.0;\n        for (int i = 0; i < 16; i++)\n        {\n            float _2515 = sqrt((float(i) + 0.5) * 0.0625) * _2496;\n            vec2 param_3 = uv + (dir * (fa_shadows[26].zw * _2515));\n            vec4 param_4 = rect;\n            vec3 param_5 = conv;\n            float _2529 = fa_shadow_fetch(param_3, param_4, param_5);\n            if (_2529 < (zr - (_2515 * plane)))\n            {\n                sum += _2529;\n                cnt += 1.0;\n            }\n            vec2 param_6 = dir;\n            dir = fa_shadow_vogel_turn(param_6);\n        }\n        if (cnt < 0.5)\n        {\n            return 1.0;\n        }\n        float _2557 = sum / cnt;\n        float _2567;\n        if (k < 0.0)\n        {\n            _2567 = (-k) / max(_2557, 0.0500000007450580596923828125);\n        }\n        else\n        {\n            _2567 = k;\n        }\n        radius = clamp(((max(zr - _2557, 0.0) * unit) * _2567) / texel_m, 1.5, 16.0);\n        dir = _2468;\n    }\n    float lit = 0.0;\n    int _2593 = (mode == 2) ? 24 : 16;\n    for (int i_1 = 0; i_1 < _2593; i_1++)\n    {\n        float _2612 = sqrt((float(i_1) + 0.5) / float(_2593)) * radius;\n        vec2 param_7 = uv + (dir * (fa_shadows[26].zw * _2612));\n        vec4 param_8 = rect;\n        vec3 param_9 = conv;\n        lit += float((zr - (_2612 * plane)) <= fa_shadow_fetch(param_7, param_8, param_9));\n        vec2 param_10 = dir;\n        dir = fa_shadow_vogel_turn(param_10);\n    }\n    return lit / float(_2593);\n}\n\nfloat fa_shadow_cascade(int ci, vec3 world, vec3 n, vec3 l)\n{\n    float _2658 = max(fa_shadows[ci * 1 + 20].y, 0.001000000047497451305389404296875);\n    float _2663 = clamp(dot(n, l), 0.0, 1.0);\n    float _2669 = sqrt(1.0 - (_2663 * _2663));\n    float _2677 = min(_2669 / max(_2663, 0.20000000298023223876953125), 4.0);\n    float _2682;\n    if (fa_shadows[26].y > 0.0)\n    {\n        _2682 = fa_shadows[26].y;\n    }\n    else\n    {\n        _2682 = 1.5 * fa_shadows[ci * 1 + 20].x;\n    }\n    vec4 _2707 = mat4(fa_shadows[ci * 4 + 0], fa_shadows[ci * 4 + 1], fa_shadows[ci * 4 + 2], fa_shadows[ci * 4 + 3]) * vec4(world + (n * (_2682 * _2669)), 1.0);\n    float _2714 = _2707.x;\n    bool _2717 = _2714 < fa_shadows[ci * 1 + 16].x;\n    bool _2726;\n    if (!_2717)\n    {\n        _2726 = _2714 > fa_shadows[ci * 1 + 16].z;\n    }\n    else\n    {\n        _2726 = _2717;\n    }\n    bool _2735;\n    if (!_2726)\n    {\n        _2735 = _2707.y < fa_shadows[ci * 1 + 16].y;\n    }\n    else\n    {\n        _2735 = _2726;\n    }\n    bool _2744;\n    if (!_2735)\n    {\n        _2744 = _2707.y > fa_shadows[ci * 1 + 16].w;\n    }\n    else\n    {\n        _2744 = _2735;\n    }\n    bool _2751;\n    if (!_2744)\n    {\n        _2751 = _2707.z > 1.0;\n    }\n    else\n    {\n        _2751 = _2744;\n    }\n    if (_2751)\n    {\n        return -1.0;\n    }\n    float _2759;\n    if (fa_shadows[26].x > 0.0)\n    {\n        _2759 = fa_shadows[26].x;\n    }\n    else\n    {\n        _2759 = 1.5 * fa_shadows[ci * 1 + 20].x;\n    }\n    vec2 param = _2707.xy;\n    vec4 param_1 = fa_shadows[ci * 1 + 16];\n    float param_2 = _2707.z - ((_2759 * (1.0 + (0.5 * _2677))) / _2658);\n    float param_3 = fa_shadows[ci * 1 + 20].x;\n    float param_4 = _2658;\n    float param_5 = _2658 * 0.25;\n    float param_6 = ((fa_shadows[ci * 1 + 20].x * min(_2677, 3.0)) * 0.5) / _2658;\n    vec3 param_7 = vec3(0.0);\n    int param_8 = int(fa_shadows[25].z + 0.5);\n    float param_9 = fa_shadows[25].w;\n    return fa_shadow_filter(param, param_1, param_2, param_3, param_4, param_5, param_6, param_7, param_8, param_9);\n}\n\nfloat fa_shadow_sun(vec3 world, vec3 n, vec3 l)\n{\n    if (fa_mesh_fs_params[5].z < 0.5)\n    {\n        return 1.0;\n    }\n    int _3137 = int(fa_shadows[25].x + 0.5);\n    if (_3137 < 1)\n    {\n        return 1.0;\n    }\n    float _3152 = dot(world - fa_shadows[27].xyz, fa_shadows[28].xyz);\n    int param = _3137 - 1;\n    if (_3152 > fa_shadow_split_at(param))\n    {\n        return 1.0;\n    }\n    int ci = 0;\n    bool _3164 = _3137 > 1;\n    bool _3171;\n    if (_3164)\n    {\n        _3171 = _3152 > fa_shadows[24].x;\n    }\n    else\n    {\n        _3171 = _3164;\n    }\n    if (_3171)\n    {\n        ci = 1;\n    }\n    bool _3175 = _3137 > 2;\n    bool _3182;\n    if (_3175)\n    {\n        _3182 = _3152 > fa_shadows[24].y;\n    }\n    else\n    {\n        _3182 = _3175;\n    }\n    if (_3182)\n    {\n        ci = 2;\n    }\n    bool _3186 = _3137 > 3;\n    bool _3193;\n    if (_3186)\n    {\n        _3193 = _3152 > fa_shadows[24].z;\n    }\n    else\n    {\n        _3193 = _3186;\n    }\n    if (_3193)\n    {\n        ci = 3;\n    }\n    float s = -1.0;\n    float s2 = -1.0;\n    float t = 0.0;\n    int _3204 = min(_3137, 4);\n    float _3245;\n    for (int c = ci; c < _3204; c++)\n    {\n        int param_1 = c;\n        vec3 param_2 = world;\n        vec3 param_3 = n;\n        vec3 param_4 = l;\n        float _3224 = fa_shadow_cascade(param_1, param_2, param_3, param_4);\n        if (s >= 0.0)\n        {\n            s2 = _3224;\n            break;\n        }\n        if (_3224 < 0.0)\n        {\n            continue;\n        }\n        s = _3224;\n        ci = c;\n        if (fa_shadows[25].y > 0.0)\n        {\n            if (ci > 0)\n            {\n                int param_5 = ci - 1;\n                _3245 = fa_shadow_split_at(param_5);\n            }\n            else\n            {\n                _3245 = fa_shadows[28].w;\n            }\n            int param_6 = ci;\n            float _3264 = fa_shadows[25].y * max(fa_shadow_split_at(param_6) - _3245, 9.9999997473787516355514526367188e-05);\n            int param_7 = ci;\n            t = clamp((_3152 - (fa_shadow_split_at(param_7) - _3264)) / _3264, 0.0, 1.0);\n        }\n        if (t <= 0.0)\n        {\n            break;\n        }\n    }\n    if (s < 0.0)\n    {\n        return 1.0;\n    }\n    if (t > 0.0)\n    {\n        float _3296;\n        if ((ci + 1) < _3137)\n        {\n            _3296 = (s2 < 0.0) ? s : s2;\n        }\n        else\n        {\n            _3296 = 1.0;\n        }\n        s = mix(s, _3296, t);\n    }\n    return s;\n}\n\nfloat fa_shadow_factor(vec3 n, vec3 l)\n{\n    bool _3401 = fa_mesh_fs_params[25].y > 0.5;\n    bool _3407;\n    if (_3401)\n    {\n        _3407 = fa_mesh_fs_params[5].z > 0.5;\n    }\n    else\n    {\n        _3407 = _3401;\n    }\n    if (_3407)\n    {\n        float _3421 = dot(fa_mesh_fs_params[29].xyz, fa_world_pos) + fa_mesh_fs_params[29].w;\n        vec4 _3429 = vec4(fa_world_pos, 1.0);\n        float _3435 = dot(fa_mesh_fs_params[28], _3429);\n        if (_3435 > 9.9999997473787516355514526367188e-05)\n        {\n            vec2 _3454 = vec2(dot(fa_mesh_fs_params[26], _3429), dot(fa_mesh_fs_params[27], _3429)) / vec2(_3435);\n            float _3459 = (_3454.x * 0.5) + 0.5;\n            float _3463;\n            if (fa_mesh_fs_params[24].y > 0.5)\n            {\n                _3463 = (_3454.y * 0.5) + 0.5;\n            }\n            else\n            {\n                _3463 = 0.5 - (_3454.y * 0.5);\n            }\n            bool _3479 = _3459 >= 0.0;\n            bool _3485;\n            if (_3479)\n            {\n                _3485 = _3459 < 1.0;\n            }\n            else\n            {\n                _3485 = _3479;\n            }\n            bool _3491;\n            if (_3485)\n            {\n                _3491 = _3463 >= 0.0;\n            }\n            else\n            {\n                _3491 = _3485;\n            }\n            bool _3497;\n            if (_3491)\n            {\n                _3497 = _3463 < 1.0;\n            }\n            else\n            {\n                _3497 = _3491;\n            }\n            if (_3497)\n            {\n                vec4 _3522 = texelFetch(fa_screen_tex_fa_shadow_smp, clamp(ivec2(vec2(_3459, _3463) * fa_mesh_fs_params[24].zw), ivec2(0), ivec2(fa_mesh_fs_params[24].zw) - ivec2(1)), 0);\n                bool _3525 = _3522.w > 0.5;\n                bool _3541;\n                if (_3525)\n                {\n                    _3541 = abs(_3421 - _3522.x) <= (((0.00200000009499490261077880859375 * _3421) + 0.00999999977648258209228515625) + fa_rt_slope);\n                }\n                else\n                {\n                    _3541 = _3525;\n                }\n                if (_3541)\n                {\n                    float _3547;\n                    if (fa_mesh_fs_params[25].z > 0.5)\n                    {\n                        vec3 param = fa_world_pos;\n                        vec3 param_1 = n;\n                        vec3 param_2 = l;\n                        _3547 = min(_3522.y, fa_shadow_sun(param, param_1, param_2));\n                    }\n                    else\n                    {\n                        _3547 = _3522.y;\n                    }\n                    return _3547;\n                }\n            }\n        }\n    }\n    vec3 param_3 = fa_world_pos;\n    vec3 param_4 = n;\n    vec3 param_5 = l;\n    return fa_shadow_sun(param_3, param_4, param_5);\n}\n\nfloat fa_rt_local_tap(ivec2 p, ivec2 size, float d, float tol, float div, inout float best)\n{\n    vec4 _3584 = texelFetch(fa_screen_tex_fa_shadow_smp, clamp(p, ivec2(0), size - ivec2(1)), 0);\n    bool _3587 = _3584.w > 0.5;\n    bool _3597;\n    if (_3587)\n    {\n        _3597 = abs(d - _3584.x) <= tol;\n    }\n    else\n    {\n        _3597 = _3587;\n    }\n    if (_3597)\n    {\n        best = min(best, mod(floor(_3584.z / div), 256.0) * 0.0039215688593685626983642578125);\n    }\n    return best;\n}\n\nfloat fa_shadow_local(int li, vec3 lpos, vec3 world, vec3 n, vec3 l)\n{\n    bool _2817 = fa_mesh_fs_params[5].z < 0.5;\n    bool _2824;\n    if (!_2817)\n    {\n        _2824 = fa_shadows[29].x < 0.5;\n    }\n    else\n    {\n        _2824 = _2817;\n    }\n    if (_2824)\n    {\n        return 1.0;\n    }\n    int param = (int(fa_shadows[29].x + 0.5) - 1) + li;\n    vec4 _2837 = fa_light_texel(param);\n    float _2838 = _2837.x;\n    if (_2838 < 0.0)\n    {\n        return 1.0;\n    }\n    int _2847 = int(_2838 + 0.5);\n    int param_1 = _2847;\n    vec4 _2851 = fa_light_texel(param_1);\n    int param_2 = _2847 + 1;\n    vec4 _2856 = fa_light_texel(param_2);\n    float fade = 1.0;\n    float _2859 = _2851.y;\n    if (_2859 > 0.0)\n    {\n        float _2876 = 1.0 - smoothstep(0.75 * _2859, _2859, length(world - fa_shadows[27].xyz));\n        fade = _2876;\n        if (_2876 <= 0.0)\n        {\n            return 1.0;\n        }\n    }\n    int face = 0;\n    if (_2851.x > 1.5)\n    {\n        vec3 param_3 = world - lpos;\n        face = fa_cube_face(param_3);\n    }\n    int _2900 = (_2847 + 2) + (face * 6);\n    int param_4 = _2900;\n    int param_5 = _2900 + 1;\n    int param_6 = _2900 + 3;\n    vec4 _2914 = fa_light_texel(param_6);\n    int param_7 = _2900 + 4;\n    vec4 _2919 = fa_light_texel(param_7);\n    int param_8 = _2900 + 5;\n    vec4 _2924 = fa_light_texel(param_8);\n    float _2936 = _2924.x * max(dot(_2914, vec4(world, 1.0)), 0.001000000047497451305389404296875);\n    float _2941 = clamp(dot(n, l), 0.0, 1.0);\n    float _2964 = clamp(dot(n, _2914.xyz), -1.0, 1.0);\n    float _2983 = min(sqrt(1.0 - (_2964 * _2964)) / max(abs(dot(n, world - lpos)) / max(dot(_2914, vec4(world, 1.0)), 0.001000000047497451305389404296875), 0.20000000298023223876953125), 4.0);\n    float _2986 = _2856.y;\n    float _2988;\n    if (_2986 > 0.0)\n    {\n        _2988 = _2986;\n    }\n    else\n    {\n        _2988 = 1.5 * _2936;\n    }\n    vec4 _3008 = vec4(world + (n * (_2988 * sqrt(1.0 - (_2941 * _2941)))), 1.0);\n    float _3012 = dot(_2914, _3008);\n    float _3015 = _2924.y;\n    if (_3012 < _3015)\n    {\n        return 1.0;\n    }\n    vec2 _3030 = vec2(dot(fa_light_texel(param_4), _3008), dot(fa_light_texel(param_5), _3008)) / vec2(_3012);\n    float _3032 = _3030.x;\n    bool _3035 = _3032 < _2919.x;\n    bool _3044;\n    if (!_3035)\n    {\n        _3044 = _3032 > _2919.z;\n    }\n    else\n    {\n        _3044 = _3035;\n    }\n    bool _3053;\n    if (!_3044)\n    {\n        _3053 = _3030.y < _2919.y;\n    }\n    else\n    {\n        _3053 = _3044;\n    }\n    bool _3062;\n    if (!_3053)\n    {\n        _3062 = _3030.y > _2919.w;\n    }\n    else\n    {\n        _3062 = _3053;\n    }\n    if (_3062)\n    {\n        return 1.0;\n    }\n    float _3068 = _2856.x;\n    float _3070;\n    if (_3068 > 0.0)\n    {\n        _3070 = _3068;\n    }\n    else\n    {\n        _3070 = 1.5 * _2936;\n    }\n    vec2 param_9 = _3030;\n    vec4 param_10 = _2919;\n    float param_11 = _3012 - (_3070 * (1.0 + (0.5 * _2983)));\n    float param_12 = _2936;\n    float param_13 = 1.0;\n    float param_14 = _2924.z * 0.25;\n    float param_15 = (_2936 * min(_2983, 3.0)) * 0.5;\n    vec3 param_16 = vec3(1.0, _3015, _2924.z);\n    int param_17 = int(_2851.z + 0.5);\n    float param_18 = _2851.w;\n    return mix(1.0, fa_shadow_filter(param_9, param_10, param_11, param_12, param_13, param_14, param_15, param_16, param_17, param_18), fade);\n}\n\nfloat fa_shadow_local_rt(int li, vec3 lpos, vec3 world, vec3 n, vec3 l)\n{\n    bool _3615 = fa_mesh_fs_params[25].w > 0.5;\n    bool _3621;\n    if (_3615)\n    {\n        _3621 = fa_mesh_fs_params[5].z > 0.5;\n    }\n    else\n    {\n        _3621 = _3615;\n    }\n    bool _3627;\n    if (_3621)\n    {\n        _3627 = fa_shadows[29].x > 0.5;\n    }\n    else\n    {\n        _3627 = _3621;\n    }\n    if (_3627)\n    {\n        int param = (int(fa_shadows[29].x + 0.5) - 1) + li;\n        vec4 _3639 = fa_light_texel(param);\n        float _3640 = _3639.z;\n        if (_3640 > 0.5)\n        {\n            float _3653 = dot(fa_mesh_fs_params[29].xyz, world) + fa_mesh_fs_params[29].w;\n            float _3659 = ((0.00200000009499490261077880859375 * _3653) + 0.00999999977648258209228515625) + fa_rt_slope;\n            vec4 _3665 = vec4(world, 1.0);\n            float _3670 = dot(fa_mesh_fs_params[28], _3665);\n            if (_3670 > 9.9999997473787516355514526367188e-05)\n            {\n                vec2 _3687 = vec2(dot(fa_mesh_fs_params[26], _3665), dot(fa_mesh_fs_params[27], _3665)) / vec2(_3670);\n                float _3692 = (_3687.x * 0.5) + 0.5;\n                float _3696;\n                if (fa_mesh_fs_params[24].y > 0.5)\n                {\n                    _3696 = (_3687.y * 0.5) + 0.5;\n                }\n                else\n                {\n                    _3696 = 0.5 - (_3687.y * 0.5);\n                }\n                bool _3712 = _3692 >= 0.0;\n                bool _3718;\n                if (_3712)\n                {\n                    _3718 = _3692 < 1.0;\n                }\n                else\n                {\n                    _3718 = _3712;\n                }\n                bool _3724;\n                if (_3718)\n                {\n                    _3724 = _3696 >= 0.0;\n                }\n                else\n                {\n                    _3724 = _3718;\n                }\n                bool _3730;\n                if (_3724)\n                {\n                    _3730 = _3696 < 1.0;\n                }\n                else\n                {\n                    _3730 = _3724;\n                }\n                if (_3730)\n                {\n                    ivec2 _3737 = ivec2(fa_mesh_fs_params[24].zw);\n                    ivec2 _3748 = clamp(ivec2(vec2(_3692, _3696) * fa_mesh_fs_params[24].zw), ivec2(0), _3737 - ivec2(1));\n                    float _3752;\n                    if (_3640 < 1.5)\n                    {\n                        _3752 = 1.0;\n                    }\n                    else\n                    {\n                        _3752 = (_3640 < 2.5) ? 256.0 : 65536.0;\n                    }\n                    float best = 2.0;\n                    vec4 _3768 = texelFetch(fa_screen_tex_fa_shadow_smp, _3748, 0);\n                    bool _3771 = _3768.w > 0.5;\n                    bool _3781;\n                    if (_3771)\n                    {\n                        _3781 = abs(_3653 - _3768.x) <= _3659;\n                    }\n                    else\n                    {\n                        _3781 = _3771;\n                    }\n                    if (_3781)\n                    {\n                        best = mod(floor(_3768.z / _3752), 256.0) * 0.0039215688593685626983642578125;\n                    }\n                    else\n                    {\n                        ivec2 param_1 = _3748 + ivec2(-1);\n                        ivec2 param_2 = _3737;\n                        float param_3 = _3653;\n                        float param_4 = _3659;\n                        float param_5 = _3752;\n                        float param_6 = best;\n                        float _3807 = fa_rt_local_tap(param_1, param_2, param_3, param_4, param_5, param_6);\n                        best = _3807;\n                        ivec2 param_7 = _3748 + ivec2(0, -1);\n                        ivec2 param_8 = _3737;\n                        float param_9 = _3653;\n                        float param_10 = _3659;\n                        float param_11 = _3752;\n                        float param_12 = _3807;\n                        float _3822 = fa_rt_local_tap(param_7, param_8, param_9, param_10, param_11, param_12);\n                        best = _3822;\n                        ivec2 param_13 = _3748 + ivec2(1, -1);\n                        ivec2 param_14 = _3737;\n                        float param_15 = _3653;\n                        float param_16 = _3659;\n                        float param_17 = _3752;\n                        float param_18 = _3822;\n                        float _3837 = fa_rt_local_tap(param_13, param_14, param_15, param_16, param_17, param_18);\n                        best = _3837;\n                        ivec2 param_19 = _3748 + ivec2(-1, 0);\n                        ivec2 param_20 = _3737;\n                        float param_21 = _3653;\n                        float param_22 = _3659;\n                        float param_23 = _3752;\n                        float param_24 = _3837;\n                        float _3852 = fa_rt_local_tap(param_19, param_20, param_21, param_22, param_23, param_24);\n                        best = _3852;\n                        ivec2 param_25 = _3748 + ivec2(1, 0);\n                        ivec2 param_26 = _3737;\n                        float param_27 = _3653;\n                        float param_28 = _3659;\n                        float param_29 = _3752;\n                        float param_30 = _3852;\n                        float _3867 = fa_rt_local_tap(param_25, param_26, param_27, param_28, param_29, param_30);\n                        best = _3867;\n                        ivec2 param_31 = _3748 + ivec2(-1, 1);\n                        ivec2 param_32 = _3737;\n                        float param_33 = _3653;\n                        float param_34 = _3659;\n                        float param_35 = _3752;\n                        float param_36 = _3867;\n                        float _3882 = fa_rt_local_tap(param_31, param_32, param_33, param_34, param_35, param_36);\n                        best = _3882;\n                        ivec2 param_37 = _3748 + ivec2(0, 1);\n                        ivec2 param_38 = _3737;\n                        float param_39 = _3653;\n                        float param_40 = _3659;\n                        float param_41 = _3752;\n                        float param_42 = _3882;\n                        float _3897 = fa_rt_local_tap(param_37, param_38, param_39, param_40, param_41, param_42);\n                        best = _3897;\n                        ivec2 param_43 = _3748 + ivec2(1);\n                        ivec2 param_44 = _3737;\n                        float param_45 = _3653;\n                        float param_46 = _3659;\n                        float param_47 = _3752;\n                        float param_48 = _3897;\n                        float _3912 = fa_rt_local_tap(param_43, param_44, param_45, param_46, param_47, param_48);\n                        best = _3912;\n                    }\n                    if (best <= 1.0)\n                    {\n                        float _3920;\n                        if (fa_mesh_fs_params[25].z > 0.5)\n                        {\n                            int param_49 = li;\n                            vec3 param_50 = lpos;\n                            vec3 param_51 = world;\n                            vec3 param_52 = n;\n                            vec3 param_53 = l;\n                            _3920 = min(best, fa_shadow_local(param_49, param_50, param_51, param_52, param_53));\n                        }\n                        else\n                        {\n                            _3920 = best;\n                        }\n                        return _3920;\n                    }\n                }\n            }\n            float _3943;\n            if (fa_mesh_fs_params[25].z > 0.5)\n            {\n                int param_54 = li;\n                vec3 param_55 = lpos;\n                vec3 param_56 = world;\n                vec3 param_57 = n;\n                vec3 param_58 = l;\n                _3943 = fa_shadow_local(param_54, param_55, param_56, param_57, param_58);\n            }\n            else\n            {\n                _3943 = 1.0;\n            }\n            return _3943;\n        }\n    }\n    int param_59 = li;\n    vec3 param_60 = lpos;\n    vec3 param_61 = world;\n    vec3 param_62 = n;\n    vec3 param_63 = l;\n    return fa_shadow_local(param_59, param_60, param_61, param_62, param_63);\n}\n\nfloat fa_contact_shadow(int li, vec3 world, vec3 gn, vec3 l, float dist)\n{\n    bool _5788 = fa_mesh_fs_params[24].x < 0.5;\n    bool _5795;\n    if (!_5788)\n    {\n        _5795 = fa_shadows[29].x < 0.5;\n    }\n    else\n    {\n        _5795 = _5788;\n    }\n    if (_5795)\n    {\n        return 1.0;\n    }\n    int param = (int(fa_shadows[29].x + 0.5) - 1) + li;\n    vec4 _5808 = fa_light_texel(param);\n    float _5809 = _5808.y;\n    float len = _5809;\n    if (_5809 <= 0.0)\n    {\n        return 1.0;\n    }\n    float _5821 = length(world - fa_mesh_fs_params[0].xyz);\n    float _5830 = 1.0 - smoothstep(0.5 * fa_mesh_fs_params[25].x, fa_mesh_fs_params[25].x, _5821);\n    if (_5830 <= 0.0)\n    {\n        return 1.0;\n    }\n    float _5836 = len;\n    float _5839 = min(_5836, 0.89999997615814208984375 * dist);\n    len = _5839;\n    float _5844 = 0.004999999888241291046142578125 + (0.0030000000260770320892333984375 * _5821);\n    float _5849 = _5844 + (0.5 * _5839);\n    vec3 _5855 = world + (gn * _5844);\n    float _5857 = fa_shadow_noise();\n    float occ = 0.0;\n    float _5918;\n    for (int k = 0; k < 12; k++)\n    {\n        float _5872 = (float(k) + _5857) * 0.083333335816860198974609375;\n        vec3 _5880 = _5855 + (l * (_5872 * len));\n        vec4 _5886 = vec4(_5880, 1.0);\n        float _5891 = dot(fa_mesh_fs_params[28], _5886);\n        if (_5891 < 9.9999997473787516355514526367188e-05)\n        {\n            break;\n        }\n        vec2 _5909 = vec2(dot(fa_mesh_fs_params[26], _5886), dot(fa_mesh_fs_params[27], _5886)) / vec2(_5891);\n        float _5913 = _5909.x * 0.5;\n        float _5914 = _5913 + 0.5;\n        if (fa_mesh_fs_params[24].y > 0.5)\n        {\n            _5918 = (_5909.y * 0.5) + 0.5;\n        }\n        else\n        {\n            _5918 = 0.5 - (_5909.y * 0.5);\n        }\n        bool _5934 = _5914 < 0.0;\n        bool _5941;\n        if (!_5934)\n        {\n            _5941 = _5914 >= 1.0;\n        }\n        else\n        {\n            _5941 = _5934;\n        }\n        bool _5948;\n        if (!_5941)\n        {\n            _5948 = _5918 < 0.0;\n        }\n        else\n        {\n            _5948 = _5941;\n        }\n        bool _5955;\n        if (!_5948)\n        {\n            _5955 = _5918 >= 1.0;\n        }\n        else\n        {\n            _5955 = _5948;\n        }\n        if (_5955)\n        {\n            break;\n        }\n        vec4 _5979 = texelFetch(fa_screen_tex_fa_shadow_smp, clamp(ivec2(vec2(_5914, _5918) * fa_mesh_fs_params[24].zw), ivec2(0), ivec2(fa_mesh_fs_params[24].zw) - ivec2(1)), 0);\n        if (_5979.w < 0.5)\n        {\n            continue;\n        }\n        float _5997 = (dot(fa_mesh_fs_params[29].xyz, _5880) + fa_mesh_fs_params[29].w) - _5979.x;\n        if ((_5997 > _5844) && (_5997 < _5849))\n        {\n            occ = max(occ, (1.0 - (_5872 * _5872)) * smoothstep(0.0, 0.0500000007450580596923828125, min(min(_5914, 0.5 - _5913), min(_5918, 1.0 - _5918))));\n        }\n    }\n    return 1.0 - (occ * _5830);\n}\n\nLightSample fa_light_shadowed(int li, vec3 world_pos, vec3 gn)\n{\n    int param = li;\n    float _6659 = fa_baked_keep(param);\n    if (_6659 <= 0.0)\n    {\n        int param_1 = li;\n        return LightSample(vec3(0.0, 1.0, 0.0), vec3(0.0), 0.0, 1.0, 0.0, int(fa_light_type(param_1) + 0.5));\n    }\n    int param_2 = li;\n    vec3 param_3 = world_pos;\n    vec3 param_4 = gn;\n    LightSample _6685 = fa_light_sample_n(param_2, param_3, param_4);\n    vec3 _9955 = _6685.color;\n    float _9956 = _6685.attenuation;\n    float _9957 = _6685.shadow;\n    bool _6688 = _6685.type == 0;\n    if (_6688 && (li == 0))\n    {\n        vec3 param_5 = gn;\n        vec3 param_6 = _6685.direction;\n        float _6699 = fa_shadow_factor(param_5, param_6);\n        _9957 = _6699;\n        _9955 *= _6699;\n    }\n    else\n    {\n        bool _6710 = _6685.type != 0;\n        bool _6716;\n        if (_6710)\n        {\n            _6716 = _9956 > 0.0;\n        }\n        else\n        {\n            _6716 = _6710;\n        }\n        if (_6716)\n        {\n            int param_7 = li;\n            int param_8 = fa_light_base(param_7);\n            int param_9 = li;\n            vec3 param_10 = fa_light_texel(param_8).xyz;\n            vec3 param_11 = world_pos;\n            vec3 param_12 = gn;\n            vec3 param_13 = _6685.direction;\n            float _6735 = fa_shadow_local_rt(param_9, param_10, param_11, param_12, param_13);\n            _9957 = _6735;\n            _9955 *= _6735;\n        }\n    }\n    bool _6745 = fa_mesh_fs_params[24].x > 0.5;\n    bool _6751;\n    if (_6745)\n    {\n        _6751 = _9956 > 0.0;\n    }\n    else\n    {\n        _6751 = _6745;\n    }\n    if (_6751)\n    {\n        float _6758;\n        if (_6688)\n        {\n            _6758 = 1000000000.0;\n        }\n        else\n        {\n            _6758 = _6685._distance;\n        }\n        int param_14 = li;\n        vec3 param_15 = world_pos;\n        vec3 param_16 = gn;\n        vec3 param_17 = _6685.direction;\n        float param_18 = _6758;\n        float _6776 = fa_contact_shadow(param_14, param_15, param_16, param_17, param_18);\n        _9957 *= _6776;\n        _9955 *= _6776;\n    }\n    float _6789 = _9956;\n    float _6790 = _6789 * _6659;\n    _9956 = _6790;\n    vec3 _6794 = _9955;\n    vec3 _6795 = _6794 * _6659;\n    _9955 = _6795;\n    return LightSample(_6685.direction, _6795, _6790, _9957, _6685._distance, _6685.type);\n}\n\nvec3 fa_ltc_tangent(vec3 n, vec3 v)\n{\n    vec3 _6829 = v - (n * dot(v, n));\n    vec3 t = _6829;\n    float _6833 = dot(_6829, _6829);\n    float l2 = _6833;\n    if (_6833 < 1.0000000133514319600180897396058e-10)\n    {\n        vec3 _6843;\n        if (abs(n.z) < 0.999000012874603271484375)\n        {\n            _6843 = cross(n, vec3(0.0, 0.0, 1.0));\n        }\n        else\n        {\n            _6843 = cross(n, vec3(1.0, 0.0, 0.0));\n        }\n        t = _6843;\n        l2 = dot(_6843, _6843);\n    }\n    return t * inversesqrt(l2);\n}\n\nvec3 fa_ltc_local(vec3 t1, vec3 n, vec3 p)\n{\n    return vec3(dot(t1, p), dot(cross(n, t1), p), dot(n, p));\n}\n\nvec2 fa_ltc_uv(float roughness, float ndv)\n{\n    return ((vec2(clamp((roughness - 0.0500000007450580596923828125) * 1.0526316165924072265625, 0.0, 1.0), sqrt(clamp(1.0 - ndv, 0.0, 1.0))) * 63.0) + vec2(0.5)) * vec2(0.015625);\n}\n\nvec3 fa_oct_vertex(int j, vec3 pc, vec3 ex, vec3 ey)\n{\n    float _7230;\n    if ((j == 0) || (j == 7))\n    {\n        _7230 = 0.92387950420379638671875;\n    }\n    else\n    {\n        float _7240;\n        if ((j == 3) || (j == 4))\n        {\n            _7240 = -0.92387950420379638671875;\n        }\n        else\n        {\n            _7240 = ((j == 1) || (j == 6)) ? 0.3826834261417388916015625 : (-0.3826834261417388916015625);\n        }\n        _7230 = _7240;\n    }\n    float _7261;\n    if ((j == 1) || (j == 2))\n    {\n        _7261 = 0.92387950420379638671875;\n    }\n    else\n    {\n        float _7270;\n        if ((j == 5) || (j == 6))\n        {\n            _7270 = -0.92387950420379638671875;\n        }\n        else\n        {\n            _7270 = ((j == 0) || (j == 3)) ? 0.3826834261417388916015625 : (-0.3826834261417388916015625);\n        }\n        _7261 = _7270;\n    }\n    return (pc + (ex * _7230)) + (ey * _7261);\n}\n\nvec3 fa_ltc_edge_vector(vec3 a, vec3 b)\n{\n    float _6878 = dot(a, a);\n    float _6882 = dot(b, b);\n    if ((_6878 < 1.0000000195414813782625560981111e-24) || (_6882 < 1.0000000195414813782625560981111e-24))\n    {\n        return vec3(0.0);\n    }\n    vec3 _6896 = a * inversesqrt(_6878);\n    vec3 _6901 = b * inversesqrt(_6882);\n    float _6905 = dot(_6896, _6901);\n    float _6908 = abs(_6905);\n    float g = (((((((((((0.0416471660137176513671875 * _6908) - 0.1924748718738555908203125) * _6908) + 0.4179156124591827392578125) * _6908) - 0.616057217121124267578125) * _6908) + 0.777722418308258056640625) * _6908) - 0.999542415142059326171875) * _6908) + 1.570791721343994140625;\n    if (_6905 < 0.0)\n    {\n        g = (3.1415927410125732421875 * inversesqrt(max(1.0 - (_6905 * _6905), 1.0000000116860974230803549289703e-07))) - g;\n    }\n    return cross(_6896, _6901) * g;\n}\n\nvoid fa_ltc_clip_edge(vec3 a, vec3 b, inout vec3 sum, inout vec3 leave, inout vec3 enter, inout vec2 seen)\n{\n    bool _6965 = a.z > 0.0;\n    bool _6969 = b.z > 0.0;\n    if (_6965 && _6969)\n    {\n        vec3 param = a;\n        vec3 param_1 = b;\n        sum += fa_ltc_edge_vector(param, param_1);\n    }\n    else\n    {\n        if (_6965 != _6969)\n        {\n            vec3 _7004 = a + ((b - a) * (a.z / (a.z - b.z)));\n            _7004.z = 0.0;\n            if (_6965)\n            {\n                vec3 param_2 = a;\n                vec3 param_3 = _7004;\n                sum += fa_ltc_edge_vector(param_2, param_3);\n                leave = _7004;\n                seen.x = 1.0;\n            }\n            else\n            {\n                vec3 param_4 = _7004;\n                vec3 param_5 = b;\n                sum += fa_ltc_edge_vector(param_4, param_5);\n                enter = _7004;\n                seen.y = 1.0;\n            }\n        }\n    }\n}\n\nfloat fa_ltc_quad(vec4 abcd, vec3 p0, vec3 p1, vec3 p2, vec3 p3)\n{\n    vec3 _7053 = vec3((abcd.x * p0.x) + (abcd.y * p0.z), p0.y, (abcd.z * p0.x) + (abcd.w * p0.z));\n    vec3 _7079 = vec3((abcd.x * p1.x) + (abcd.y * p1.z), p1.y, (abcd.z * p1.x) + (abcd.w * p1.z));\n    vec3 _7105 = vec3((abcd.x * p2.x) + (abcd.y * p2.z), p2.y, (abcd.z * p2.x) + (abcd.w * p2.z));\n    vec3 _7131 = vec3((abcd.x * p3.x) + (abcd.y * p3.z), p3.y, (abcd.z * p3.x) + (abcd.w * p3.z));\n    vec3 sum = vec3(0.0);\n    vec3 leave = vec3(0.0);\n    vec3 enter = vec3(0.0);\n    vec3 param = _7053;\n    vec3 param_1 = _7079;\n    vec3 param_2 = vec3(0.0);\n    vec3 param_3 = vec3(0.0);\n    vec3 param_4 = vec3(0.0);\n    vec2 param_5 = vec2(0.0);\n    fa_ltc_clip_edge(param, param_1, param_2, param_3, param_4, param_5);\n    sum = param_2;\n    leave = param_3;\n    enter = param_4;\n    vec3 param_6 = _7079;\n    vec3 param_7 = _7105;\n    vec3 param_8 = param_2;\n    vec3 param_9 = param_3;\n    vec3 param_10 = param_4;\n    vec2 param_11 = param_5;\n    fa_ltc_clip_edge(param_6, param_7, param_8, param_9, param_10, param_11);\n    sum = param_8;\n    leave = param_9;\n    enter = param_10;\n    vec3 param_12 = _7105;\n    vec3 param_13 = _7131;\n    vec3 param_14 = param_8;\n    vec3 param_15 = param_9;\n    vec3 param_16 = param_10;\n    vec2 param_17 = param_11;\n    fa_ltc_clip_edge(param_12, param_13, param_14, param_15, param_16, param_17);\n    sum = param_14;\n    leave = param_15;\n    enter = param_16;\n    vec3 param_18 = _7131;\n    vec3 param_19 = _7053;\n    vec3 param_20 = param_14;\n    vec3 param_21 = param_15;\n    vec3 param_22 = param_16;\n    vec2 param_23 = param_17;\n    fa_ltc_clip_edge(param_18, param_19, param_20, param_21, param_22, param_23);\n    sum = param_20;\n    leave = param_21;\n    enter = param_22;\n    if ((param_23.x * param_23.y) > 0.5)\n    {\n        vec3 param_24 = leave;\n        vec3 param_25 = enter;\n        sum += fa_ltc_edge_vector(param_24, param_25);\n    }\n    return sum.z * 0.15915493667125701904296875;\n}\n\nvec2 fa_area_forms(vec4 m, float shape, vec3 pc, vec3 ex, vec3 ey)\n{\n    int _7299 = ((shape < 0.5) || (shape > 1.5)) ? 1 : 3;\n    vec2 sum = vec2(0.0);\n    int _7317;\n    for (int k = 0; k < (2 * _7299); k++)\n    {\n        bool _7314 = k >= _7299;\n        if (_7314)\n        {\n            _7317 = k - _7299;\n        }\n        else\n        {\n            _7317 = k;\n        }\n        vec3 p0 = (pc - ex) - ey;\n        vec3 p1 = (pc + ex) - ey;\n        vec3 p2 = (pc + ex) + ey;\n        vec3 p3 = (pc - ex) + ey;\n        if (_7299 == 3)\n        {\n            int param = 0;\n            vec3 param_1 = pc;\n            vec3 param_2 = ex;\n            vec3 param_3 = ey;\n            p0 = fa_oct_vertex(param, param_1, param_2, param_3);\n            int _7363 = 2 * _7317;\n            int param_4 = _7363 + 1;\n            vec3 param_5 = pc;\n            vec3 param_6 = ex;\n            vec3 param_7 = ey;\n            p1 = fa_oct_vertex(param_4, param_5, param_6, param_7);\n            int param_8 = _7363 + 2;\n            vec3 param_9 = pc;\n            vec3 param_10 = ex;\n            vec3 param_11 = ey;\n            p2 = fa_oct_vertex(param_8, param_9, param_10, param_11);\n            int param_12 = _7363 + 3;\n            vec3 param_13 = pc;\n            vec3 param_14 = ex;\n            vec3 param_15 = ey;\n            p3 = fa_oct_vertex(param_12, param_13, param_14, param_15);\n        }\n        bvec4 _7400 = bvec4(_7314);\n        vec4 param_16 = vec4(_7400.x ? m.x : vec4(1.0, 0.0, 0.0, 1.0).x, _7400.y ? m.y : vec4(1.0, 0.0, 0.0, 1.0).y, _7400.z ? m.z : vec4(1.0, 0.0, 0.0, 1.0).z, _7400.w ? m.w : vec4(1.0, 0.0, 0.0, 1.0).w);\n        vec3 param_17 = p0;\n        vec3 param_18 = p1;\n        vec3 param_19 = p2;\n        vec3 param_20 = p3;\n        float _7411 = fa_ltc_quad(param_16, param_17, param_18, param_19, param_20);\n        if (_7314)\n        {\n            vec2 _10211 = sum;\n            _10211.y = _10211.y + _7411;\n            sum = _10211;\n        }\n        else\n        {\n            vec2 _10214 = sum;\n            _10214.x = _10214.x + _7411;\n            sum = _10214;\n        }\n    }\n    return abs(sum);\n}\n\nvec3 fa_area_shade(int li, vec3 world_pos, vec3 n, vec3 v, vec3 diffuse_color, vec3 f0, float f90, float roughness, float ndv, float window)\n{\n    int param = li;\n    int _7435 = fa_light_base(param);\n    int param_1 = _7435;\n    int param_2 = _7435 + 1;\n    int param_3 = _7435 + 2;\n    int param_4 = _7435 + 4;\n    vec4 _7457 = fa_light_texel(param_4);\n    int param_5 = _7435 + 5;\n    vec4 _7462 = fa_light_texel(param_5);\n    int param_6 = _7435 + 6;\n    vec4 _7467 = fa_light_texel(param_6);\n    float _7468 = _7467.w;\n    vec3 _7473 = fa_light_texel(param_1).xyz - world_pos;\n    bool _7475 = _7468 < 1.5;\n    bool _7482;\n    if (_7475)\n    {\n        _7482 = dot(normalize(fa_light_texel(param_3).xyz), _7473) >= 0.0;\n    }\n    else\n    {\n        _7482 = _7475;\n    }\n    if (_7482)\n    {\n        return vec3(0.0);\n    }\n    bool _7491 = (_7468 > 0.5) && _7475;\n    float _7495 = _7491 ? 1.0539000034332275390625 : 1.0;\n    vec3 _7498 = _7457.xyz;\n    float _7500 = _7457.w;\n    vec3 _7506 = _7462.xyz;\n    float _7508 = _7462.w;\n    vec3 up = _7506 * (_7508 * _7495);\n    float _7514;\n    if (_7491)\n    {\n        _7514 = (3.1415927410125732421875 * _7500) * _7500;\n    }\n    else\n    {\n        _7514 = (4.0 * _7500) * _7508;\n    }\n    if (_7468 > 1.5)\n    {\n        vec3 _7540 = cross(_7498, -_7473);\n        vec3 perp = _7540;\n        float _7544 = dot(_7540, _7540);\n        vec3 _7547;\n        if (_7544 > 1.0000000133514319600180897396058e-10)\n        {\n            _7547 = perp * inversesqrt(_7544);\n        }\n        else\n        {\n            _7547 = _7506;\n        }\n        perp = _7547;\n        up = _7547 * _7508;\n    }\n    float _7568 = max(_7514, 9.9999999747524270787835121154785e-07);\n    vec3 param_7 = n;\n    vec3 param_8 = v;\n    vec3 _7578 = fa_ltc_tangent(param_7, param_8);\n    vec3 param_9 = _7578;\n    vec3 param_10 = n;\n    vec3 param_11 = _7473;\n    vec3 param_12 = _7578;\n    vec3 param_13 = n;\n    vec3 param_14 = _7498 * (_7500 * _7495);\n    vec3 param_15 = _7578;\n    vec3 param_16 = n;\n    vec3 param_17 = up;\n    float param_18 = roughness;\n    float param_19 = ndv;\n    vec2 _7609 = fa_ltc_uv(param_18, param_19) * 64.0;\n    vec2 param_20 = _7609;\n    vec2 param_21 = _7609 + vec2(64.0, 0.0);\n    vec4 _7619 = fa_atlas_fetch(param_21);\n    vec4 param_22 = fa_atlas_fetch(param_20);\n    float param_23 = _7468;\n    vec3 param_24 = fa_ltc_local(param_9, param_10, param_11);\n    vec3 param_25 = fa_ltc_local(param_12, param_13, param_14);\n    vec3 param_26 = fa_ltc_local(param_15, param_16, param_17);\n    vec2 _7631 = fa_area_forms(param_22, param_23, param_24, param_25, param_26);\n    return (((diffuse_color * _7631.x) + (((f0 * _7619.x) + ((vec3(f90) - f0) * _7619.y)) * _7631.y)) * fa_light_texel(param_2).xyz) * ((((3.1415927410125732421875 * dot(_7473, _7473)) + _7568) / _7568) * window);\n}\n\nvec3 fa_light_rgb(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 1;\n    return fa_light_texel(param_1).xyz;\n}\n\nfloat fa_d_charlie(float alpha, float ndh)\n{\n    float _5525 = 1.0 / alpha;\n    return ((2.0 + _5525) * pow(sqrt(max(1.0 - (ndh * ndh), 9.9999997473787516355514526367188e-05)), _5525)) * 0.15915493667125701904296875;\n}\n\nfloat fa_v_ashikhmin(float ndl, float ndv)\n{\n    return clamp(0.25 / max((ndl + ndv) - (ndl * ndv), 9.9999997473787516355514526367188e-05), 0.0, 1.0);\n}\n\nfloat fa_layers_coat(FaLayers L, vec3 l, vec3 h, float vdh)\n{\n    float _5560 = max(dot(L.nc, l), 0.0);\n    float _5566 = max(dot(L.nc, h), 0.0);\n    float _5575 = ((_5566 * _5566) * (L.coat_a2 - 1.0)) + 1.0;\n    return (((L.coat * (0.039999999105930328369140625 + (0.959999978542327880859375 * pow(clamp(1.0 - vdh, 0.0, 1.0), 5.0)))) * (((L.coat_a2 / ((3.1415927410125732421875 * _5575) * _5575)) * (0.5 / max(mix((2.0 * _5560) * L.coat_ndv, _5560 + L.coat_ndv, L.coat_alpha), 9.9999997473787516355514526367188e-05))) * 3.1415927410125732421875)) * step(9.9999997473787516355514526367188e-05, _5560)) * _5560;\n}\n\nvec3 fa_area_layers(FaLayers L, vec3 base, int li, vec3 n, vec3 v, vec3 l, float ndv, float window)\n{\n    float _7668;\n    if (L.sheen_on)\n    {\n        _7668 = L.sheen_scale;\n    }\n    else\n    {\n        _7668 = 1.0;\n    }\n    vec3 result = base * (L.keep * _7668);\n    vec3 _7681 = normalize(l + v);\n    int param = li;\n    vec3 _7692 = fa_light_rgb(param) * window;\n    if (L.sheen_on)\n    {\n        float _7701 = max(dot(n, l), 0.0);\n        float param_1 = L.sheen_alpha;\n        float param_2 = max(dot(n, _7681), 0.0);\n        float param_3 = _7701;\n        float param_4 = ndv;\n        result += ((L.sheen * _7692) * (((((fa_d_charlie(param_1, param_2) * fa_v_ashikhmin(param_3, param_4)) * 3.1415927410125732421875) * step(9.9999997473787516355514526367188e-05, _7701)) * _7701) * L.keep));\n    }\n    if (L.coat > 0.0)\n    {\n        FaLayers param_5 = L;\n        vec3 param_6 = l;\n        vec3 param_7 = _7681;\n        float param_8 = max(dot(v, _7681), 0.0);\n        result += (_7692 * fa_layers_coat(param_5, param_6, param_7, param_8));\n    }\n    return result;\n}\n\nfloat fa_d_ggx_aniso(float ndh, float tdh, float bdh, float at, float ab)\n{\n    float _5428 = tdh / at;\n    float _5432 = bdh / ab;\n    float _5444 = ((_5428 * _5428) + (_5432 * _5432)) + (ndh * ndh);\n    return 1.0 / ((((3.1415927410125732421875 * at) * ab) * _5444) * _5444);\n}\n\nfloat fa_lambda_ggx_aniso(float n, float t, float b, float at, float ab)\n{\n    return 0.5 * (sqrt(1.0 + (((((at * at) * t) * t) + (((ab * ab) * b) * b)) / max(n * n, 9.9999999392252902907785028219223e-09))) - 1.0);\n}\n\nfloat fa_v_ggx_aniso(float ndl, float ndv, float tdv, float bdv, float tdl, float bdl, float at, float ab)\n{\n    float param = ndv;\n    float param_1 = tdv;\n    float param_2 = bdv;\n    float param_3 = at;\n    float param_4 = ab;\n    float param_5 = ndl;\n    float param_6 = tdl;\n    float param_7 = bdl;\n    float param_8 = at;\n    float param_9 = ab;\n    return clamp(1.0 / ((4.0 * max(ndl * ndv, 9.9999997473787516355514526367188e-05)) * ((1.0 + fa_lambda_ggx_aniso(param, param_1, param_2, param_3, param_4)) + fa_lambda_ggx_aniso(param_5, param_6, param_7, param_8, param_9))), 0.0, 1.0);\n}\n\nvec3 fa_layers_light(FaLayers L, vec3 diffuse_color, vec3 f0, vec3 n, vec3 v, vec3 l, vec3 h, float ndl, float ndv, float ndh, float vdh, float alpha, float a2)\n{\n    float _5624 = step(9.9999997473787516355514526367188e-05, ndl);\n    float d_ggx;\n    float vis;\n    if (L.aniso != 0.0)\n    {\n        float param = ndh;\n        float param_1 = dot(L.t, h);\n        float param_2 = dot(L.b, h);\n        float param_3 = L.at;\n        float param_4 = L.ab;\n        d_ggx = fa_d_ggx_aniso(param, param_1, param_2, param_3, param_4);\n        float param_5 = ndl;\n        float param_6 = ndv;\n        float param_7 = dot(L.t, v);\n        float param_8 = dot(L.b, v);\n        float param_9 = dot(L.t, l);\n        float param_10 = dot(L.b, l);\n        float param_11 = L.at;\n        float param_12 = L.ab;\n        vis = fa_v_ggx_aniso(param_5, param_6, param_7, param_8, param_9, param_10, param_11, param_12);\n    }\n    else\n    {\n        float _5703 = ((ndh * ndh) * (a2 - 1.0)) + 1.0;\n        d_ggx = a2 / ((3.1415927410125732421875 * _5703) * _5703);\n        vis = 0.5 / max(mix((2.0 * ndl) * ndv, ndl + ndv, alpha), 9.9999997473787516355514526367188e-05);\n    }\n    vec3 base = diffuse_color + (((f0 + ((vec3(L.f90) - f0) * pow(clamp(1.0 - vdh, 0.0, 1.0), 5.0))) * ((d_ggx * vis) * 3.1415927410125732421875)) * _5624);\n    if (L.sheen_on)\n    {\n        float param_13 = L.sheen_alpha;\n        float param_14 = ndh;\n        float param_15 = ndl;\n        float param_16 = ndv;\n        base = (base * L.sheen_scale) + (L.sheen * (((fa_d_charlie(param_13, param_14) * fa_v_ashikhmin(param_15, param_16)) * 3.1415927410125732421875) * _5624));\n    }\n    vec3 result = base * (L.keep * ndl);\n    if (L.coat > 0.0)\n    {\n        FaLayers param_17 = L;\n        vec3 param_18 = l;\n        vec3 param_19 = h;\n        float param_20 = vdh;\n        result += vec3(fa_layers_coat(param_17, param_18, param_19, param_20));\n    }\n    return result;\n}\n\nvec2 fa_env_brdf(float rough, float ndv)\n{\n    vec4 _4827 = (vec4(-1.0, -0.0274999998509883880615234375, -0.572000026702880859375, 0.02199999988079071044921875) * rough) + vec4(1.0, 0.0425000004470348358154296875, 1.03999996185302734375, -0.039999999105930328369140625);\n    float _4830 = _4827.x;\n    return (vec2(-1.03999996185302734375, 1.03999996185302734375) * ((min(_4830 * _4830, exp2((-9.27999973297119140625) * ndv)) * _4830) + _4827.y)) + _4827.zw;\n}\n\nvec3 fa_probe_level(vec2 origin, float res, int lv, vec2 e)\n{\n    float _4137;\n    if (lv == 0)\n    {\n        _4137 = 0.0;\n    }\n    else\n    {\n        _4137 = res + 2.0;\n    }\n    float _4147;\n    if (lv == 0)\n    {\n        _4147 = 0.0;\n    }\n    else\n    {\n        _4147 = (res - (res / float(1 << max((lv - 1), 0)))) + (2.0 * float(lv - 1));\n    }\n    return textureLod(fa_probe_atlas_fa_env_smp, (((origin + vec2(_4137, _4147)) + vec2(1.0)) + (((e * 0.5) + vec2(0.5)) * (res / float(1 << lv)))) / fa_atlas_size(), 0.0).xyz;\n}\n\nvec3 fa_probe_radiance(vec2 origin, float res, vec3 d, float rough)\n{\n    float _4193;\n    if (res > 64.5)\n    {\n        _4193 = 5.0;\n    }\n    else\n    {\n        _4193 = (res > 32.5) ? 4.0 : 3.0;\n    }\n    float _4208 = clamp(rough, 0.0, 1.0) * (_4193 - 1.0);\n    int _4215 = int(min(floor(_4208), _4193 - 2.0));\n    float _4220 = _4208 - float(_4215);\n    vec3 param = d;\n    vec2 _4224 = fa_oct_encode(param);\n    vec2 param_1 = origin;\n    float param_2 = res;\n    int param_3 = _4215;\n    vec2 param_4 = _4224;\n    vec3 _4234 = fa_probe_level(param_1, param_2, param_3, param_4);\n    if (_4220 < 0.00200000009499490261077880859375)\n    {\n        return _4234;\n    }\n    vec2 param_5 = origin;\n    float param_6 = res;\n    int param_7 = _4215 + 1;\n    vec2 param_8 = _4224;\n    return mix(_4234, fa_probe_level(param_5, param_6, param_7, param_8), vec3(_4220));\n}\n\nvec3 fa_probe_box_dir(vec3 d, vec4 posw, vec4 bx, vec4 by, vec4 bz)\n{\n    if (posw.w < 0.5)\n    {\n        return d;\n    }\n    float _4305 = dot(bx.xyz, fa_world_pos) + bx.w;\n    float _4312 = dot(by.xyz, fa_world_pos) + by.w;\n    float _4319 = dot(bz.xyz, fa_world_pos) + bz.w;\n    float _4325 = dot(bx.xyz, d);\n    float _4329 = dot(by.xyz, d);\n    float _4333 = dot(bz.xyz, d);\n    float _4339;\n    if (_4325 > 9.9999999747524270787835121154785e-07)\n    {\n        _4339 = (1.0 - _4305) / _4325;\n    }\n    else\n    {\n        float _4353;\n        if (_4325 < (-9.9999999747524270787835121154785e-07))\n        {\n            _4353 = ((-1.0) - _4305) / _4325;\n        }\n        else\n        {\n            _4353 = 1000000015047466219876688855040.0;\n        }\n        _4339 = _4353;\n    }\n    float tx = _4339;\n    float _4370;\n    if (_4329 > 9.9999999747524270787835121154785e-07)\n    {\n        _4370 = (1.0 - _4312) / _4329;\n    }\n    else\n    {\n        float _4383;\n        if (_4329 < (-9.9999999747524270787835121154785e-07))\n        {\n            _4383 = ((-1.0) - _4312) / _4329;\n        }\n        else\n        {\n            _4383 = 1000000015047466219876688855040.0;\n        }\n        _4370 = _4383;\n    }\n    float ty = _4370;\n    float _4399;\n    if (_4333 > 9.9999999747524270787835121154785e-07)\n    {\n        _4399 = (1.0 - _4319) / _4333;\n    }\n    else\n    {\n        float _4412;\n        if (_4333 < (-9.9999999747524270787835121154785e-07))\n        {\n            _4412 = ((-1.0) - _4319) / _4333;\n        }\n        else\n        {\n            _4412 = 1000000015047466219876688855040.0;\n        }\n        _4399 = _4412;\n    }\n    float _4424 = tx;\n    float _4427 = (_4424 > 0.0) ? _4424 : 1000000015047466219876688855040.0;\n    tx = _4427;\n    float _4428 = ty;\n    float _4431 = (_4428 > 0.0) ? _4428 : 1000000015047466219876688855040.0;\n    ty = _4431;\n    float _4441 = min(_4427, min(_4431, (_4399 > 0.0) ? _4399 : 1000000015047466219876688855040.0));\n    if (_4441 > 100000001504746621987668885504.0)\n    {\n        return d;\n    }\n    vec3 _4457 = (fa_world_pos + (d * _4441)) - posw.xyz;\n    vec3 _4462;\n    if (dot(_4457, _4457) > 1.0000000133514319600180897396058e-10)\n    {\n        _4462 = normalize(_4457);\n    }\n    else\n    {\n        _4462 = d;\n    }\n    return _4462;\n}\n\nvec3 fa_probe_environment(vec4 tile, vec4 posw, vec4 bx, vec4 by, vec4 bz, inout vec3 d, float rough)\n{\n    vec3 param = d;\n    vec4 param_1 = posw;\n    vec4 param_2 = bx;\n    vec4 param_3 = by;\n    vec4 param_4 = bz;\n    d = fa_probe_box_dir(param, param_1, param_2, param_3, param_4);\n    vec2 param_5 = tile.xy;\n    float param_6 = tile.z;\n    vec3 param_7 = d;\n    float param_8 = rough;\n    return fa_probe_radiance(param_5, param_6, param_7, param_8);\n}\n\nvec3 fa_environment(vec3 d, float rough)\n{\n    float _4508 = (1.0 - fa_mesh_fs_params[42].w) - fa_mesh_fs_params[47].w;\n    vec3 outc = vec3(0.0);\n    if (_4508 > 0.0005000000237487256526947021484375)\n    {\n        vec3 base;\n        if (fa_mesh_fs_params[11].w > 0.5)\n        {\n            vec2 param = fa_mesh_fs_params[41].zw;\n            float param_1 = 128.0;\n            vec3 param_2 = d;\n            float param_3 = rough;\n            base = fa_probe_radiance(param, param_1, param_2, param_3);\n        }\n        else\n        {\n            float _4536 = rough * rough;\n            float _4567 = 0.60000002384185791015625 * _4536;\n            base = mix(mix(fa_mesh_fs_params[12].xyz * 0.550000011920928955078125, mix(fa_mesh_fs_params[12].xyz, fa_mesh_fs_params[11].xyz, vec3(pow(clamp(d.y * (1.0 - (0.699999988079071044921875 * _4536)), 0.0, 1.0), 0.550000011920928955078125))), vec3(smoothstep((-0.0500000007450580596923828125) - _4567, 0.0500000007450580596923828125 + _4567, d.y))), ((fa_mesh_fs_params[11].xyz + fa_mesh_fs_params[12].xyz) * 0.5) * 0.800000011920928955078125, vec3(_4536 * 0.60000002384185791015625));\n        }\n        outc = base * _4508;\n    }\n    if (fa_mesh_fs_params[42].w > 0.0)\n    {\n        vec4 param_4 = fa_mesh_fs_params[42];\n        vec4 param_5 = fa_mesh_fs_params[43];\n        vec4 param_6 = fa_mesh_fs_params[44];\n        vec4 param_7 = fa_mesh_fs_params[45];\n        vec4 param_8 = fa_mesh_fs_params[46];\n        vec3 param_9 = d;\n        float param_10 = rough;\n        vec3 _4626 = fa_probe_environment(param_4, param_5, param_6, param_7, param_8, param_9, param_10);\n        outc += (_4626 * fa_mesh_fs_params[42].w);\n    }\n    if (fa_mesh_fs_params[47].w > 0.0)\n    {\n        vec4 param_11 = fa_mesh_fs_params[47];\n        vec4 param_12 = fa_mesh_fs_params[48];\n        vec4 param_13 = fa_mesh_fs_params[49];\n        vec4 param_14 = fa_mesh_fs_params[50];\n        vec4 param_15 = fa_mesh_fs_params[51];\n        vec3 param_16 = d;\n        float param_17 = rough;\n        vec3 _4658 = fa_probe_environment(param_11, param_12, param_13, param_14, param_15, param_16, param_17);\n        outc += (_4658 * fa_mesh_fs_params[47].w);\n    }\n    return outc;\n}\n\nvec3 fa_layers_ibl(FaLayers L, vec3 n, vec3 v, vec3 f0, float roughness, float occlusion)\n{\n    vec3 rn = n;\n    if (L.aniso != 0.0)\n    {\n        vec3 _5305;\n        if (L.aniso >= 0.0)\n        {\n            _5305 = L.b;\n        }\n        else\n        {\n            _5305 = L.t;\n        }\n        rn = normalize(mix(n, cross(cross(_5305, v), _5305), vec3(abs(L.aniso) * smoothstep(0.0, 0.25, roughness))));\n    }\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05);\n    vec2 _5341 = fa_env_brdf(param, param_1);\n    vec3 param_2 = reflect(-v, rn);\n    float param_3 = roughness;\n    vec3 result = (fa_environment(param_2, param_3) * ((f0 * _5341.x) + (vec3(L.f90) * _5341.y))) * L.base_scale;\n    if (L.sheen_on)\n    {\n        vec3 param_4 = n;\n        float param_5 = L.sheen_rough;\n        result += ((L.sheen * (L.sheen_e * L.keep)) * fa_environment(param_4, param_5));\n    }\n    result *= occlusion;\n    if (L.coat > 0.0)\n    {\n        float param_6 = L.coat_rough;\n        float param_7 = L.coat_ndv;\n        vec2 _5399 = fa_env_brdf(param_6, param_7);\n        vec3 param_8 = reflect(-v, L.nc);\n        float param_9 = L.coat_rough;\n        result += (fa_environment(param_8, param_9) * (L.coat * ((0.039999999105930328369140625 * _5399.x) + _5399.y)));\n    }\n    return result;\n}\n\nvec3 fa_sky_reflection(vec3 n, vec3 v, vec3 f0, float roughness)\n{\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05);\n    vec2 _4869 = fa_env_brdf(param, param_1);\n    vec3 param_2 = reflect(-v, n);\n    float param_3 = roughness;\n    return fa_environment(param_2, param_3) * ((f0 * _4869.x) + vec3(_4869.y));\n}\n\nvec2 fa_xm_size(int k)\n{\n    return max(floor(fa_mesh_fs_params[24].zw / vec2(float(1 << k))), vec2(1.0));\n}\n\nvec2 fa_xm_origin(int k)\n{\n    if (k == 0)\n    {\n        return vec2(0.0);\n    }\n    float y = 0.0;\n    for (int j = 1; j < k; j++)\n    {\n        int param = j;\n        y += fa_xm_size(param).y;\n    }\n    return vec2(fa_mesh_fs_params[24].z, y);\n}\n\nvec3 fa_xm_texel(vec2 size, vec2 origin, vec2 p)\n{\n    return texelFetch(fa_screen_tex_fa_shadow_smp, ivec2(origin + clamp(p, vec2(0.0), size - vec2(1.0))), 0).xyz;\n}\n\nvec3 fa_xm_level(int k, vec2 uv)\n{\n    int param = k;\n    vec2 _6101 = fa_xm_size(param);\n    int param_1 = k;\n    vec2 _6105 = fa_xm_origin(param_1);\n    vec2 _6111 = (uv * _6101) - vec2(0.5);\n    vec2 _6114 = fract(_6111);\n    vec2 _6117 = floor(_6111);\n    vec2 param_2 = _6101;\n    vec2 param_3 = _6105;\n    vec2 param_4 = _6117;\n    vec2 param_5 = _6101;\n    vec2 param_6 = _6105;\n    vec2 param_7 = _6117 + vec2(1.0, 0.0);\n    vec2 param_8 = _6101;\n    vec2 param_9 = _6105;\n    vec2 param_10 = _6117 + vec2(0.0, 1.0);\n    vec2 param_11 = _6101;\n    vec2 param_12 = _6105;\n    vec2 param_13 = _6117 + vec2(1.0);\n    vec3 _6159 = vec3(_6114.x);\n    return mix(mix(fa_xm_texel(param_2, param_3, param_4), fa_xm_texel(param_5, param_6, param_7), _6159), mix(fa_xm_texel(param_8, param_9, param_10), fa_xm_texel(param_11, param_12, param_13), _6159), vec3(_6114.y));\n}\n\nvec3 fa_xm_sample(vec2 uv, float lod)\n{\n    float _6178 = max(fa_mesh_fs_params[31].w - 1.0, 0.0);\n    float _6182 = clamp(lod, 0.0, _6178);\n    int _6186 = int(floor(_6182));\n    int param = _6186;\n    vec2 param_1 = uv;\n    vec3 c = fa_xm_level(param, param_1);\n    float _6196 = float(_6186);\n    float _6197 = _6182 - _6196;\n    bool _6199 = _6197 > 0.001000000047497451305389404296875;\n    bool _6206;\n    if (_6199)\n    {\n        _6206 = _6196 < _6178;\n    }\n    else\n    {\n        _6206 = _6199;\n    }\n    if (_6206)\n    {\n        int param_2 = _6186 + 1;\n        vec2 param_3 = uv;\n        c = mix(c, fa_xm_level(param_2, param_3), vec3(_6197));\n    }\n    return c;\n}\n\nvec3 fa_transmitted(Surface s, vec3 n, vec3 v, float roughness, vec3 f0, float f90, float keep, float tr, inout float blend)\n{\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05);\n    vec2 _6232 = fa_env_brdf(param, param_1);\n    vec3 _6256 = ((vec3(1.0) - clamp((f0 * _6232.x) + (vec3(f90) * _6232.y), vec3(0.0), vec3(1.0))) * s.albedo) * (tr * keep);\n    vec3 through = _6256;\n    float _6262 = max(s.thickness, 0.0);\n    bool _6267 = _6262 > 0.0;\n    if ((s.attenuation_distance > 0.0) && _6267)\n    {\n        through *= exp((-((-log(clamp(s.attenuation_color, vec3(9.9999997473787516355514526367188e-05), vec3(1.0)))) / vec3(s.attenuation_distance))) * _6262);\n    }\n    bool _6292 = fa_mesh_fs_params[30].w > 1.5;\n    bool _6298;\n    if (_6292)\n    {\n        _6298 = fa_mesh_fs_params[30].w < 2.5;\n    }\n    else\n    {\n        _6298 = _6292;\n    }\n    bool _6305;\n    if (!_6298)\n    {\n        _6305 = fa_mesh_fs_params[30].w < 0.5;\n    }\n    else\n    {\n        _6305 = _6298;\n    }\n    if (_6305)\n    {\n        blend = clamp(dot(through, vec3(0.3333333432674407958984375)), 0.0, 0.980000019073486328125);\n        return vec3(0.0);\n    }\n    vec4 _6320 = vec4(fa_world_pos, 1.0);\n    float _6325 = dot(fa_mesh_fs_params[28], _6320);\n    vec2 uv0 = vec2(0.5);\n    if (_6325 > 9.9999997473787516355514526367188e-05)\n    {\n        vec2 _6343 = vec2(dot(fa_mesh_fs_params[26], _6320), dot(fa_mesh_fs_params[27], _6320)) / vec2(_6325);\n        float _6351;\n        if (fa_mesh_fs_params[24].y > 0.5)\n        {\n            _6351 = (_6343.y * 0.5) + 0.5;\n        }\n        else\n        {\n            _6351 = 0.5 - (_6343.y * 0.5);\n        }\n        uv0 = vec2((_6343.x * 0.5) + 0.5, _6351);\n    }\n    if (fa_mesh_fs_params[30].w > 2.5)\n    {\n        int param_2 = 0;\n        vec2 _6372 = fa_xm_size(param_2);\n        vec2 _6380 = floor(clamp(uv0, vec2(0.0), vec2(0.99989998340606689453125)) * _6372);\n        if (texelFetch(fa_screen_tex_fa_shadow_smp, ivec2(_6380), 0).w > 0.5)\n        {\n            int _6400 = int(floor((clamp(roughness, 0.0, 1.0) * 2.0) + 0.5));\n            vec3 acc = vec3(0.0);\n            float cnt = 0.0;\n            for (int dy = -2; dy <= 2; dy++)\n            {\n                for (int dx = -2; dx <= 2; dx++)\n                {\n                    bool _6423 = abs(dx) > _6400;\n                    bool _6431;\n                    if (!_6423)\n                    {\n                        _6431 = abs(dy) > _6400;\n                    }\n                    else\n                    {\n                        _6431 = _6423;\n                    }\n                    if (_6431)\n                    {\n                        continue;\n                    }\n                    vec4 _6452 = texelFetch(fa_screen_tex_fa_shadow_smp, ivec2(clamp(_6380 + vec2(float(dx), float(dy)), vec2(0.0), _6372 - vec2(1.0))), 0);\n                    if (_6452.w > 0.5)\n                    {\n                        acc += _6452.xyz;\n                        cnt += 1.0;\n                    }\n                }\n            }\n            return _6256 * (acc / vec3(max(cnt, 1.0)));\n        }\n    }\n    vec2 uv = uv0;\n    if (_6267)\n    {\n        vec4 _6500 = vec4(fa_world_pos + (refract(-v, n, 1.0 / max(s.ior, 1.0)) * _6262), 1.0);\n        float _6505 = dot(fa_mesh_fs_params[28], _6500);\n        uv = vec2(0.5);\n        if (_6505 > 9.9999997473787516355514526367188e-05)\n        {\n            vec2 _6522 = vec2(dot(fa_mesh_fs_params[26], _6500), dot(fa_mesh_fs_params[27], _6500)) / vec2(_6505);\n            float _6530;\n            if (fa_mesh_fs_params[24].y > 0.5)\n            {\n                _6530 = (_6522.y * 0.5) + 0.5;\n            }\n            else\n            {\n                _6530 = 0.5 - (_6522.y * 0.5);\n            }\n            uv = vec2((_6522.x * 0.5) + 0.5, _6530);\n        }\n    }\n    vec2 param_3 = clamp(uv, vec2(0.0), vec2(1.0));\n    float param_4 = (clamp(roughness, 0.0, 1.0) * clamp((2.0 * s.ior) - 2.0, 0.0, 1.0)) * max(fa_mesh_fs_params[31].w - 1.0, 0.0);\n    return through * fa_xm_sample(param_3, param_4);\n}\n\nvec3 fa_shadow_debug(vec3 color, vec3 world)\n{\n    if (fa_shadows[27].w < 0.5)\n    {\n        return color;\n    }\n    int _3324 = int(fa_shadows[25].x + 0.5);\n    float _3334 = dot(world - fa_shadows[27].xyz, fa_shadows[28].xyz);\n    vec3 tint = vec3(0.3499999940395355224609375);\n    bool _3339 = _3324 > 0;\n    bool _3348;\n    if (_3339)\n    {\n        int param = _3324 - 1;\n        _3348 = _3334 <= fa_shadow_split_at(param);\n    }\n    else\n    {\n        _3348 = _3339;\n    }\n    if (_3348)\n    {\n        tint = vec3(1.0, 0.1500000059604644775390625, 0.100000001490116119384765625);\n        bool _3354 = _3324 > 1;\n        bool _3361;\n        if (_3354)\n        {\n            _3361 = _3334 > fa_shadows[24].x;\n        }\n        else\n        {\n            _3361 = _3354;\n        }\n        if (_3361)\n        {\n            tint = vec3(0.100000001490116119384765625, 0.89999997615814208984375, 0.20000000298023223876953125);\n        }\n        bool _3367 = _3324 > 2;\n        bool _3374;\n        if (_3367)\n        {\n            _3374 = _3334 > fa_shadows[24].y;\n        }\n        else\n        {\n            _3374 = _3367;\n        }\n        if (_3374)\n        {\n            tint = vec3(0.1500000059604644775390625, 0.300000011920928955078125, 1.0);\n        }\n        bool _3380 = _3324 > 3;\n        bool _3387;\n        if (_3380)\n        {\n            _3387 = _3334 > fa_shadows[24].z;\n        }\n        else\n        {\n            _3387 = _3380;\n        }\n        if (_3387)\n        {\n            tint = vec3(1.0, 0.89999997615814208984375, 0.100000001490116119384765625);\n        }\n    }\n    return mix(color, tint, vec3(0.550000011920928955078125));\n}\n\nvoid main()\n{\n    fa_rt_slope = 0.0;\n    fa_inst_load();\n    vec3 _9614 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _9614 = -_9614;\n    }\n    vec3 _8900 = normalize(fa_mesh_fs_params[0].xyz - fa_world_pos);\n    vec3 param = fa_world_pos;\n    fa_cluster_begin(param);\n    SurfaceInput param_1 = SurfaceInput(fa_world_pos, _9614, fa_world_tangent, fa_uv, fa_vertex_color, _8900, gl_FrontFacing);\n    Surface _8908 = fa_standard_surface(param_1);\n    vec3 _9645 = _8908.albedo;\n    float _9646 = _8908.alpha;\n    vec3 _9647 = _8908.normal;\n    float _9648 = _8908.metallic;\n    float _9649 = _8908.roughness;\n    float _9650 = _8908.occlusion;\n    vec3 _9651 = _8908.emission;\n    float _9652 = _8908.clearcoat;\n    float _9653 = _8908.clearcoat_roughness;\n    vec3 _9654 = _8908.sheen_color;\n    float _9655 = _8908.sheen_roughness;\n    float _9656 = _8908.anisotropy;\n    float _9657 = _8908.anisotropy_rotation;\n    float _9658 = _8908.specular;\n    float _9659 = _8908.ior;\n    vec3 _9660 = _8908.specular_color;\n    float _9661 = _8908.transmission;\n    float _9662 = _8908.thickness;\n    vec3 _9663 = _8908.attenuation_color;\n    float _9664 = _8908.attenuation_distance;\n    SurfaceInput param_2 = SurfaceInput(fa_world_pos, _9614, fa_world_tangent, fa_uv, fa_vertex_color, _8900, gl_FrontFacing);\n    Surface param_3 = _8908;\n    surface(param_2, param_3);\n    _9645 = param_3.albedo;\n    _9646 = param_3.alpha;\n    _9647 = param_3.normal;\n    _9648 = param_3.metallic;\n    _9649 = param_3.roughness;\n    _9650 = param_3.occlusion;\n    _9651 = param_3.emission;\n    _9652 = param_3.clearcoat;\n    _9653 = param_3.clearcoat_roughness;\n    _9654 = param_3.sheen_color;\n    _9655 = param_3.sheen_roughness;\n    _9656 = param_3.anisotropy;\n    _9657 = param_3.anisotropy_rotation;\n    _9658 = param_3.specular;\n    _9659 = param_3.ior;\n    _9660 = param_3.specular_color;\n    _9661 = param_3.transmission;\n    _9662 = param_3.thickness;\n    _9663 = param_3.attenuation_color;\n    _9664 = param_3.attenuation_distance;\n    vec3 param_4 = fa_world_pos;\n    vec3 param_5 = _9614;\n    vec3 param_6 = param_3.albedo;\n    vec3 param_7 = param_3.normal;\n    fa_apply_decals(param_4, param_5, param_6, param_7);\n    _9645 = param_6;\n    _9647 = param_7;\n    if (_9646 < fa_material[0].x)\n    {\n        discard;\n    }\n    fa_lod_dither();\n    float fa_tr_blend = 0.0;\n    vec3 result;\n    if (fa_mesh_fs_params[3].w > 0.5)\n    {\n        result = _9645;\n    }\n    else\n    {\n        vec3 _8960 = normalize(_9647);\n        float _8967 = clamp(_9648, 0.0, 1.0);\n        float _8971 = clamp(_9649, 0.0500000007450580596923828125, 1.0);\n        float _8975 = _8971 * _8971;\n        float _8979 = _8975 * _8975;\n        float _8984 = max(dot(_8960, _8900), 9.9999997473787516355514526367188e-05);\n        float _8990 = 1.0 - _8967;\n        float _8991 = clamp(_9661, 0.0, 1.0) * _8990;\n        vec3 _9000 = (_9645 * _8990) * (1.0 - _8991);\n        vec3 _9007 = mix(vec3(0.039999999105930328369140625), _9645, vec3(_8967));\n        vec3 f0 = _9007;\n        SurfaceInput param_8 = SurfaceInput(fa_world_pos, _9614, fa_world_tangent, fa_uv, fa_vertex_color, _8900, gl_FrontFacing);\n        Surface param_9 = Surface(_9645, _9646, _9647, _9648, _9649, _9650, _9651, _9652, _9653, _9654, _9655, _9656, _9657, _9658, _9659, _9660, _9661, _9662, _9663, _9664);\n        vec3 param_10 = _8960;\n        vec3 param_11 = _8900;\n        float param_12 = _8967;\n        float param_13 = _8971;\n        vec3 param_14 = _9007;\n        FaLayers _9023 = fa_layers_setup(param_8, param_9, param_10, param_11, param_12, param_13, param_14);\n        f0 = param_14;\n        vec3 param_15 = _8960;\n        vec3 lit = (fa_indirect_diffuse(param_15) * _9000) * _9650;\n        if (_9023.on)\n        {\n            lit *= _9023.base_scale;\n        }\n        int _9045 = fa_cl_ndir + fa_cl_local;\n        float _9110;\n        for (int ln = 0; ln < _9045; ln++)\n        {\n            int param_16 = ln;\n            int _9058 = fa_cl_light(param_16);\n            int param_17 = _9058;\n            if (fa_baked_keep(param_17) <= 0.0)\n            {\n                continue;\n            }\n            int param_18 = _9058;\n            vec3 param_19 = fa_world_pos;\n            vec3 param_20 = _9614;\n            LightSample _9074 = fa_light_shadowed(param_18, param_19, param_20);\n            float _9082 = max(dot(_8960, _9074.direction), 0.0);\n            float _9088 = _9074.attenuation * _9074.shadow;\n            vec3 _9093 = normalize(_9074.direction + _8900);\n            float _9098 = max(dot(_8960, _9093), 0.0);\n            float _9103 = max(dot(_8900, _9093), 0.0);\n            if (fa_light_is_area)\n            {\n                if (_9023.on)\n                {\n                    _9110 = _9023.f90;\n                }\n                else\n                {\n                    _9110 = 1.0;\n                }\n                int param_21 = _9058;\n                vec3 param_22 = fa_world_pos;\n                vec3 param_23 = _8960;\n                vec3 param_24 = _8900;\n                vec3 param_25 = _9000;\n                vec3 param_26 = f0;\n                float param_27 = _9110;\n                float param_28 = _8971;\n                float param_29 = _8984;\n                float param_30 = _9088;\n                vec3 area = fa_area_shade(param_21, param_22, param_23, param_24, param_25, param_26, param_27, param_28, param_29, param_30);\n                if (_9023.on)\n                {\n                    FaLayers param_31 = _9023;\n                    vec3 param_32 = area;\n                    int param_33 = _9058;\n                    vec3 param_34 = _8960;\n                    vec3 param_35 = _8900;\n                    vec3 param_36 = _9074.direction;\n                    float param_37 = _8984;\n                    float param_38 = _9088;\n                    area = fa_area_layers(param_31, param_32, param_33, param_34, param_35, param_36, param_37, param_38);\n                }\n                lit += area;\n            }\n            else\n            {\n                if (_9023.on)\n                {\n                    FaLayers param_39 = _9023;\n                    vec3 param_40 = _9000;\n                    vec3 param_41 = f0;\n                    vec3 param_42 = _8960;\n                    vec3 param_43 = _8900;\n                    vec3 param_44 = _9074.direction;\n                    vec3 param_45 = _9093;\n                    float param_46 = _9082;\n                    float param_47 = _8984;\n                    float param_48 = _9098;\n                    float param_49 = _9103;\n                    float param_50 = _8975;\n                    float param_51 = _8979;\n                    int param_52 = _9058;\n                    lit += (fa_layers_light(param_39, param_40, param_41, param_42, param_43, param_44, param_45, param_46, param_47, param_48, param_49, param_50, param_51) * ((fa_light_rgb(param_52) * fa_light_tint) * _9088));\n                }\n                else\n                {\n                    float _9212 = ((_9098 * _9098) * (_8979 - 1.0)) + 1.0;\n                    int param_53 = _9058;\n                    lit += (((_9000 + (((f0 + ((vec3(1.0) - f0) * pow(1.0 - _9103, 5.0))) * (((_8979 / ((3.1415927410125732421875 * _9212) * _9212)) * (0.5 / max(mix((2.0 * _9082) * _8984, _9082 + _8984, _8975), 9.9999997473787516355514526367188e-05))) * 3.1415927410125732421875)) * step(9.9999997473787516355514526367188e-05, _9082))) * (fa_light_rgb(param_53) * fa_light_tint)) * (_9082 * _9088));\n                }\n            }\n        }\n        if (_9023.on)\n        {\n            FaLayers param_54 = _9023;\n            vec3 param_55 = _8960;\n            vec3 param_56 = _8900;\n            vec3 param_57 = f0;\n            float param_58 = _8971;\n            float param_59 = _9650;\n            lit += fa_layers_ibl(param_54, param_55, param_56, param_57, param_58, param_59);\n        }\n        else\n        {\n            vec3 param_60 = _8960;\n            vec3 param_61 = _8900;\n            vec3 param_62 = f0;\n            float param_63 = _8971;\n            lit += (fa_sky_reflection(param_60, param_61, param_62, param_63) * _9650);\n        }\n        if (_8991 > 0.0)\n        {\n            float _9310;\n            if (_9023.on)\n            {\n                _9310 = _9023.f90;\n            }\n            else\n            {\n                _9310 = 1.0;\n            }\n            float _9318;\n            if (_9023.on)\n            {\n                _9318 = _9023.base_scale;\n            }\n            else\n            {\n                _9318 = 1.0;\n            }\n            Surface param_64 = Surface(_9645, _9646, _9647, _9648, _9649, _9650, _9651, _9652, _9653, _9654, _9655, _9656, _9657, _9658, _9659, _9660, _9661, _9662, _9663, _9664);\n            vec3 param_65 = _8960;\n            vec3 param_66 = _8900;\n            float param_67 = _8971;\n            vec3 param_68 = f0;\n            float param_69 = _9310;\n            float param_70 = _9318;\n            float param_71 = _8991;\n            float param_72 = fa_tr_blend;\n            vec3 _9342 = fa_transmitted(param_64, param_65, param_66, param_67, param_68, param_69, param_70, param_71, param_72);\n            fa_tr_blend = param_72;\n            lit += _9342;\n        }\n        result = lit;\n    }\n    vec3 _9349 = result;\n    vec3 _9350 = _9349 + _9651;\n    result = _9350;\n    vec3 param_73 = _9350;\n    vec3 param_74 = fa_world_pos;\n    result = fa_shadow_debug(param_73, param_74);\n    bool _9359 = fa_mesh_fs_params[7].w > 0.0;\n    bool _9366;\n    if (!_9359)\n    {\n        _9366 = fa_mesh_fs_params[8].y > 0.0;\n    }\n    else\n    {\n        _9366 = _9359;\n    }\n    if (_9366)\n    {\n        vec3 _9375 = fa_world_pos - fa_mesh_fs_params[0].xyz;\n        float _9381 = dot(_9375, fa_mesh_fs_params[9].xyz);\n        bool _9385 = fa_mesh_fs_params[9].w > 0.5;\n        float _9386;\n        if (_9385)\n        {\n            _9386 = _9381;\n        }\n        else\n        {\n            _9386 = length(_9375);\n        }\n        float _9398 = _9386 - fa_mesh_fs_params[8].x;\n        if (_9398 > 0.0)\n        {\n            float _9407 = fa_mesh_fs_params[7].w * _9398;\n            float tau = _9407 * _9407;\n            if (fa_mesh_fs_params[8].y > 0.0)\n            {\n                float _9423;\n                if (_9385)\n                {\n                    _9423 = fa_world_pos.y - (fa_mesh_fs_params[9].y * _9381);\n                }\n                else\n                {\n                    _9423 = fa_mesh_fs_params[0].y;\n                }\n                float _9444 = mix(_9423, fa_world_pos.y, clamp(fa_mesh_fs_params[8].x / _9386, 0.0, 1.0));\n                float _9448 = fa_world_pos.y - _9444;\n                float _9453 = _9444 - fa_mesh_fs_params[8].z;\n                float _9458 = fa_world_pos.y - fa_mesh_fs_params[8].z;\n                bool _9461 = _9453 <= 0.0;\n                bool _9462 = !_9461;\n                bool _9468;\n                if (_9462)\n                {\n                    _9468 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _9468 = _9461;\n                }\n                float _9469;\n                if (_9468)\n                {\n                    _9469 = fa_mesh_fs_params[8].y;\n                }\n                else\n                {\n                    _9469 = fa_mesh_fs_params[8].y * exp(-min(fa_mesh_fs_params[8].w * _9453, 80.0));\n                }\n                bool _9496;\n                if (_9462)\n                {\n                    _9496 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _9496 = _9461;\n                }\n                float _9497;\n                if (_9496)\n                {\n                    _9497 = fa_mesh_fs_params[8].y * _9453;\n                }\n                else\n                {\n                    _9497 = (fa_mesh_fs_params[8].y * (1.0 - exp(-min(fa_mesh_fs_params[8].w * _9453, 80.0)))) / fa_mesh_fs_params[8].w;\n                }\n                bool _9522 = _9458 <= 0.0;\n                bool _9529;\n                if (!_9522)\n                {\n                    _9529 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _9529 = _9522;\n                }\n                float _9530;\n                if (_9529)\n                {\n                    _9530 = fa_mesh_fs_params[8].y * _9458;\n                }\n                else\n                {\n                    _9530 = (fa_mesh_fs_params[8].y * (1.0 - exp(-min(fa_mesh_fs_params[8].w * _9458, 80.0)))) / fa_mesh_fs_params[8].w;\n                }\n                float _9557;\n                if (abs(_9448) < 0.001000000047497451305389404296875)\n                {\n                    _9557 = _9469;\n                }\n                else\n                {\n                    _9557 = (_9530 - _9497) / _9448;\n                }\n                tau += (_9398 * max(_9557, 0.0));\n            }\n            result = mix(result, fa_mesh_fs_params[7].xyz, vec3(clamp(1.0 - exp(-clamp(tau, 0.0, 80.0)), 0.0, 1.0)));\n        }\n    }\n    if (fa_tr_blend > 0.0)\n    {\n        float _9593 = 1.0 - fa_tr_blend;\n        result /= vec3(_9593);\n        _9646 *= _9593;\n    }\n    fa_frag_color = vec4(result, _9646);\n}\n\n",
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
            "inst_name": "_622",
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
            "inst_name": "_2365",
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
            "inst_name": "_8936",
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
              "slot": 6,
              "stage": "fragment",
              "name": "mask",
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
            "slot": 2,
            "stage": "fragment",
            "name": "mask_smp",
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
            "name": "mask_mask_smp",
            "view_name": "mask",
            "sampler_name": "mask_smp",
            "view_slot": 6,
            "sampler_slot": 2,
            "glsl_name": "mask_mask_smp"
          },
          {
            "slot": 7,
            "stage": "fragment",
            "name": "fa_decal_tex_fa_env_smp",
            "view_name": "fa_decal_tex",
            "sampler_name": "fa_env_smp",
            "view_slot": 27,
            "sampler_slot": 10,
            "glsl_name": "fa_decal_tex_fa_env_smp"
          },
          {
            "slot": 8,
            "stage": "fragment",
            "name": "fa_lightmap_fa_env_smp",
            "view_name": "fa_lightmap",
            "sampler_name": "fa_env_smp",
            "view_slot": 26,
            "sampler_slot": 10,
            "glsl_name": "fa_lightmap_fa_env_smp"
          },
          {
            "slot": 9,
            "stage": "fragment",
            "name": "fa_probe_atlas_fa_env_smp",
            "view_name": "fa_probe_atlas",
            "sampler_name": "fa_env_smp",
            "view_slot": 14,
            "sampler_slot": 10,
            "glsl_name": "fa_probe_atlas_fa_env_smp"
          },
          {
            "slot": 10,
            "stage": "fragment",
            "name": "fa_light_atlas_fa_env_smp",
            "view_name": "fa_light_atlas",
            "sampler_name": "fa_env_smp",
            "view_slot": 25,
            "sampler_slot": 10,
            "glsl_name": "fa_light_atlas_fa_env_smp"
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
          },
          {
            "slot": 12,
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
      "vs": "#version 430\n\nstruct VertexData\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 color;\n    vec3 object_pos;\n};\n\nuniform vec4 fa_mesh_vs_params[11];\nuniform vec4 fa_vel_params[9];\nlayout(location = 0) out vec3 fa_world_pos;\nlayout(location = 1) out vec3 fa_world_normal;\nlayout(location = 2) out vec4 fa_world_tangent;\nlayout(location = 3) out vec2 fa_uv;\nlayout(location = 4) out vec4 fa_vertex_color;\nlayout(location = 5) out float fa_pre_depth;\nlayout(location = 6) out vec3 fa_pre_r0;\nlayout(location = 7) out vec3 fa_pre_r1;\nlayout(location = 8) out vec3 fa_pre_r2;\nlayout(location = 9) out vec3 fa_vel_cur;\nlayout(location = 10) out vec3 fa_vel_prev;\nlayout(location = 9) in vec4 fa_prev_r0;\nlayout(location = 10) in vec4 fa_prev_r1;\nlayout(location = 11) in vec4 fa_prev_r2;\nlayout(location = 5) in vec4 fa_inst_m0;\nlayout(location = 6) in vec4 fa_inst_m1;\nlayout(location = 7) in vec4 fa_inst_m2;\nlayout(location = 8) in vec4 fa_inst_m3;\nlayout(location = 0) in vec3 fa_position;\nlayout(location = 1) in vec3 fa_normal;\nlayout(location = 3) in vec4 fa_tangent;\nlayout(location = 2) in vec2 fa_texcoord0;\nlayout(location = 4) in vec4 fa_color;\nvec4 fa_vtime;\n\nvoid fa_inst_begin()\n{\n}\n\nvec4 fa_time_now()\n{\n    return fa_mesh_vs_params[9];\n}\n\nVertexData fa_vertex_data(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    vec3 _97 = cross(model[1].xyz, model[2].xyz);\n    float _101 = (dot(model[0].xyz, _97) < 0.0) ? (-1.0) : 1.0;\n    return VertexData((model * vec4(position, 1.0)).xyz, (((_97 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _101, vec4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _101), texcoord0 * fa_mesh_vs_params[8].xy, color, position);\n}\n\nmat4 fa_rows_to_mat4(vec4 r0, vec4 r1, vec4 r2)\n{\n    return mat4(vec4(r0.x, r1.x, r2.x, 0.0), vec4(r0.y, r1.y, r2.y, 0.0), vec4(r0.z, r1.z, r2.z, 0.0), vec4(r0.w, r1.w, r2.w, 1.0));\n}\n\nmat4 fa_prev_model()\n{\n    vec4 param = fa_prev_r0;\n    vec4 param_1 = fa_prev_r1;\n    vec4 param_2 = fa_prev_r2;\n    return fa_rows_to_mat4(param, param_1, param_2);\n}\n\nvoid fa_prepass_vertex(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color, bool has_prev)\n{\n    bool _231;\n    if (has_prev)\n    {\n        _231 = fa_vel_params[8].x > 0.5;\n    }\n    else\n    {\n        _231 = has_prev;\n    }\n    fa_vtime = fa_time_now();\n    mat4 param = model;\n    vec3 param_1 = position;\n    vec3 param_2 = normal;\n    vec4 param_3 = tangent;\n    vec2 param_4 = texcoord0;\n    vec4 param_5 = color;\n    VertexData _246 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    vec3 _464 = _246.world_pos;\n    mat4 _250 = mat4(fa_mesh_vs_params[4], fa_mesh_vs_params[5], fa_mesh_vs_params[6], fa_mesh_vs_params[7]);\n    vec4 _257 = vec4(_464, 1.0);\n    fa_world_pos = _464;\n    fa_world_normal = _246.world_normal;\n    fa_world_tangent = _246.world_tangent;\n    fa_uv = _246.uv;\n    fa_vertex_color = _246.color;\n    fa_pre_depth = -(_250 * _257).z;\n    fa_pre_r0 = vec3(_250[0].x, _250[1].x, _250[2].x);\n    fa_pre_r1 = vec3(_250[0].y, _250[1].y, _250[2].y);\n    fa_pre_r2 = vec3(_250[0].z, _250[1].z, _250[2].z);\n    gl_Position = mat4(fa_mesh_vs_params[0], fa_mesh_vs_params[1], fa_mesh_vs_params[2], fa_mesh_vs_params[3]) * _257;\n    fa_vel_cur = vec3(0.0, 0.0, 1.0);\n    fa_vel_prev = vec3(0.0);\n    if (_231)\n    {\n        vec4 _330 = vec4(position, 1.0);\n        fa_vel_cur = vec3((mat4(fa_vel_params[0], fa_vel_params[1], fa_vel_params[2], fa_vel_params[3]) * _257).xyw);\n        fa_vel_prev = vec3((mat4(fa_vel_params[4], fa_vel_params[5], fa_vel_params[6], fa_vel_params[7]) * vec4((_464 + (fa_prev_model() * _330).xyz) - (model * _330).xyz, 1.0)).xyw);\n    }\n}\n\nvoid main()\n{\n    fa_vtime = vec4(0.0);\n    fa_inst_begin();\n    mat4 param = mat4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3);\n    vec3 param_1 = fa_position;\n    vec3 param_2 = fa_normal;\n    vec4 param_3 = fa_tangent;\n    vec2 param_4 = fa_texcoord0;\n    vec4 param_5 = fa_color;\n    bool param_6 = true;\n    fa_prepass_vertex(param, param_1, param_2, param_3, param_4, param_5, param_6);\n}\n\n",
      "fs": "#version 430\n\nstruct SurfaceInput\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 vertex_color;\n    vec3 view_dir;\n    bool front_facing;\n};\n\nstruct Surface\n{\n    vec3 albedo;\n    float alpha;\n    vec3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    vec3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    vec3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    vec3 specular_color;\n    float transmission;\n    float thickness;\n    vec3 attenuation_color;\n    float attenuation_distance;\n};\n\nuniform vec4 fa_mesh_fs_params[54];\nuniform vec4 fa_material[1];\nlayout(binding = 0) uniform sampler2D fa_tex_fa_smp;\nlayout(binding = 1) uniform sampler2D fa_normal_tex_fa_smp;\nlayout(binding = 2) uniform sampler2D fa_mr_tex_fa_smp;\nlayout(binding = 3) uniform sampler2D fa_occlusion_tex_fa_smp;\nlayout(binding = 4) uniform sampler2D fa_emissive_tex_fa_smp;\nlayout(binding = 5) uniform sampler2D mask_mask_smp;\n\nlayout(location = 0) in vec3 fa_world_pos;\nlayout(location = 1) in vec3 fa_world_normal;\nlayout(location = 2) in vec4 fa_world_tangent;\nlayout(location = 3) in vec2 fa_uv;\nlayout(location = 4) in vec4 fa_vertex_color;\nlayout(location = 6) in vec3 fa_pre_r0;\nlayout(location = 7) in vec3 fa_pre_r1;\nlayout(location = 8) in vec3 fa_pre_r2;\nlayout(location = 0) out vec4 fa_frag_color;\nlayout(location = 5) in float fa_pre_depth;\nlayout(location = 9) in vec3 fa_vel_cur;\nlayout(location = 10) in vec3 fa_vel_prev;\nlayout(location = 1) out vec2 fa_frag_velocity;\n\nvoid fa_inst_load()\n{\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nvec3 fa_linear_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_tex_fix(inout vec3 c, float mode)\n{\n    if (mode > 1.5)\n    {\n        vec3 param = c;\n        vec3 _237 = fa_linear_to_srgb(param);\n        c = _237;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            vec3 param_1 = c;\n            vec3 _246 = fa_srgb_to_linear(param_1);\n            c = _246;\n        }\n    }\n    return c;\n}\n\nvec3 fa_tangent_normal(SurfaceInput i, vec3 m)\n{\n    vec3 _58;\n    if (i.front_facing)\n    {\n        _58 = i.world_normal;\n    }\n    else\n    {\n        _58 = -i.world_normal;\n    }\n    vec3 _83 = normalize(i.world_tangent.xyz - (_58 * dot(_58, i.world_tangent.xyz)));\n    vec3 _111 = normalize(((_83 * m.x) + ((cross(_58, _83) * i.world_tangent.w) * m.y)) + (_58 * m.z));\n    vec3 _114;\n    if (i.front_facing)\n    {\n        _114 = _111;\n    }\n    else\n    {\n        _114 = -_111;\n    }\n    return _114;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    vec4 base_t = texture(fa_tex_fa_smp, i.uv, fa_mesh_fs_params[12].w);\n    float param = fa_mesh_fs_params[6].w;\n    float param_1 = 1.0;\n    vec3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    vec3 _282 = fa_tex_fix(param_2, param_3);\n    vec4 _901 = base_t;\n    _901.x = _282.x;\n    _901.y = _282.y;\n    _901.z = _282.z;\n    base_t = _901;\n    vec4 _298 = (_901 * fa_mesh_fs_params[2]) * i.vertex_color;\n    vec3 _856 = i.world_normal;\n    if (fa_mesh_fs_params[6].z > 0.5)\n    {\n        float param_4 = fa_mesh_fs_params[6].w;\n        float param_5 = 16.0;\n        vec3 param_6 = texture(fa_normal_tex_fa_smp, i.uv, fa_mesh_fs_params[12].w).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        vec3 _334 = fa_tex_fix(param_6, param_7);\n        vec3 _337 = (_334 * 2.0) - vec3(1.0);\n        vec2 _342 = _337.xy * fa_mesh_fs_params[6].x;\n        vec3 _909 = _337;\n        _909.x = _342.x;\n        _909.y = _342.y;\n        SurfaceInput param_8 = i;\n        vec3 param_9 = _909;\n        _856 = fa_tangent_normal(param_8, param_9);\n    }\n    vec4 mrt = texture(fa_mr_tex_fa_smp, i.uv, fa_mesh_fs_params[12].w);\n    float param_10 = fa_mesh_fs_params[6].w;\n    float param_11 = 64.0;\n    vec3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    vec3 _373 = fa_tex_fix(param_12, param_13);\n    vec4 _912 = mrt;\n    _912.x = _373.x;\n    _912.y = _373.y;\n    _912.z = _373.z;\n    mrt = _912;\n    vec4 _405 = texture(fa_occlusion_tex_fa_smp, i.uv, fa_mesh_fs_params[12].w);\n    float param_14 = fa_mesh_fs_params[6].w;\n    float param_15 = 256.0;\n    vec3 param_16 = _405.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    vec3 _417 = fa_tex_fix(param_16, param_17);\n    float param_18 = fa_mesh_fs_params[6].w;\n    float param_19 = 4.0;\n    vec3 param_20 = texture(fa_emissive_tex_fa_smp, i.uv, fa_mesh_fs_params[12].w).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    vec3 _449 = fa_tex_fix(param_20, param_21);\n    float _861 = fa_mesh_fs_params[20].x;\n    float _862 = fa_mesh_fs_params[20].y;\n    float _865 = fa_mesh_fs_params[20].z;\n    float _864 = fa_mesh_fs_params[21].w;\n    float _867 = fa_mesh_fs_params[22].x;\n    if (fa_mesh_fs_params[22].z > 0.5)\n    {\n        if (mod(fa_mesh_fs_params[22].z, 2.0) > 0.5)\n        {\n            _861 *= _417.y;\n            _862 *= _417.z;\n            _864 *= _405.w;\n        }\n        if (fa_mesh_fs_params[22].z > 1.5)\n        {\n            _865 *= mrt.x;\n            _867 *= mrt.w;\n        }\n    }\n    return Surface(_298.xyz, _298.w, _856, clamp(fa_mesh_fs_params[5].x * _373.z, 0.0, 1.0), clamp(fa_mesh_fs_params[5].y * _373.y, 0.0500000007450580596923828125, 1.0), 1.0 + (fa_mesh_fs_params[6].y * (_417.x - 1.0)), fa_mesh_fs_params[3].xyz + (fa_mesh_fs_params[4].xyz * _449), _861, _862, fa_mesh_fs_params[21].xyz, _864, _865, fa_mesh_fs_params[20].w, _867, fa_mesh_fs_params[22].y, fa_mesh_fs_params[23].xyz, fa_mesh_fs_params[30].x, fa_mesh_fs_params[30].y, fa_mesh_fs_params[31].xyz, fa_mesh_fs_params[30].z);\n}\n\nvoid surface(SurfaceInput i, inout Surface s)\n{\n    s.alpha = texture(mask_mask_smp, i.uv * 2.0).x;\n}\n\nvoid fa_lod_dither()\n{\n    if (fa_mesh_fs_params[52].w != 0.0)\n    {\n        float _151 = fract(52.98291778564453125 * fract(dot(gl_FragCoord.xy, vec2(0.067110560834407806396484375, 0.005837149918079376220703125))));\n        bool _154;\n        if (fa_mesh_fs_params[52].w > 0.0)\n        {\n            _154 = _151 >= fa_mesh_fs_params[52].w;\n        }\n        else\n        {\n            _154 = _151 < (-fa_mesh_fs_params[52].w);\n        }\n        if (_154)\n        {\n            discard;\n        }\n    }\n}\n\nvoid main()\n{\n    fa_inst_load();\n    vec3 _751 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _751 = -_751;\n    }\n    vec3 _600 = normalize(fa_mesh_fs_params[0].xyz - fa_world_pos);\n    SurfaceInput param = SurfaceInput(fa_world_pos, _751, fa_world_tangent, fa_uv, fa_vertex_color, _600, gl_FrontFacing);\n    Surface _605 = fa_standard_surface(param);\n    vec3 _775 = _605.normal;\n    SurfaceInput param_1 = SurfaceInput(fa_world_pos, _751, fa_world_tangent, fa_uv, fa_vertex_color, _600, gl_FrontFacing);\n    Surface param_2 = _605;\n    surface(param_1, param_2);\n    _775 = param_2.normal;\n    if (param_2.alpha < fa_material[0].x)\n    {\n        discard;\n    }\n    fa_lod_dither();\n    vec3 _627 = normalize(_775);\n    vec3 _642 = normalize(vec3(dot(fa_pre_r0, _627), dot(fa_pre_r1, _627), dot(fa_pre_r2, _627)));\n    float _654 = _642.z;\n    vec2 e = _642.xy / vec2((abs(_642.x) + abs(_642.y)) + abs(_654));\n    if (_654 < 0.0)\n    {\n        e = (vec2(1.0) - abs(e.yx)) * vec2((e.x >= 0.0) ? 1.0 : (-1.0), (e.y >= 0.0) ? 1.0 : (-1.0));\n    }\n    fa_frag_color = vec4(min(fa_pre_depth, 60000.0), e, 1.0);\n    vec2 motion = vec2(1024.0);\n    bool _698 = fa_vel_cur.z > 9.9999997473787516355514526367188e-06;\n    bool _705;\n    if (_698)\n    {\n        _705 = fa_vel_prev.z > 9.9999997473787516355514526367188e-06;\n    }\n    else\n    {\n        _705 = _698;\n    }\n    if (_705)\n    {\n        motion = clamp(((vec2(fa_vel_prev.x, -fa_vel_prev.y) / vec2(fa_vel_prev.z)) * 0.5) - ((vec2(fa_vel_cur.x, -fa_vel_cur.y) / vec2(fa_vel_cur.z)) * 0.5), vec2(-4.0), vec2(4.0));\n    }\n    fa_frag_velocity = motion;\n}\n\n",
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
            "inst_name": "_129",
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
            "slot": 5,
            "stage": "fragment",
            "size": 16,
            "struct_name": "fa_material",
            "inst_name": "_616",
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
          },
          {
            "texture": {
              "slot": 6,
              "stage": "fragment",
              "name": "mask",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float"
            }
          }
        ],
        "samplers": [
          {
            "slot": 2,
            "stage": "fragment",
            "name": "mask_smp",
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
          },
          {
            "slot": 5,
            "stage": "fragment",
            "name": "mask_mask_smp",
            "view_name": "mask",
            "sampler_name": "mask_smp",
            "view_slot": 6,
            "sampler_slot": 2,
            "glsl_name": "mask_mask_smp"
          }
        ]
      }
    },
    "prepass_skin": {
      "vs": "#version 430\n\nstruct VertexData\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 color;\n    vec3 object_pos;\n};\n\nuniform vec4 fa_mesh_vs_params[11];\nuniform vec4 fa_skin[192];\nuniform vec4 fa_vel_params[9];\nlayout(binding = 0) uniform sampler2D fa_prev_pal_tex_fa_prev_pal_smp;\n\nlayout(location = 0) out vec3 fa_world_pos;\nlayout(location = 1) out vec3 fa_world_normal;\nlayout(location = 2) out vec4 fa_world_tangent;\nlayout(location = 3) out vec2 fa_uv;\nlayout(location = 4) out vec4 fa_vertex_color;\nlayout(location = 5) out float fa_pre_depth;\nlayout(location = 6) out vec3 fa_pre_r0;\nlayout(location = 7) out vec3 fa_pre_r1;\nlayout(location = 8) out vec3 fa_pre_r2;\nlayout(location = 9) out vec3 fa_vel_cur;\nlayout(location = 10) out vec3 fa_vel_prev;\nlayout(location = 11) in vec4 fa_prev_r0;\nlayout(location = 12) in vec4 fa_prev_r1;\nlayout(location = 13) in vec4 fa_prev_r2;\nlayout(location = 9) in vec4 fa_joints;\nlayout(location = 10) in vec4 fa_weights;\nlayout(location = 5) in vec4 fa_inst_m0;\nlayout(location = 6) in vec4 fa_inst_m1;\nlayout(location = 7) in vec4 fa_inst_m2;\nlayout(location = 8) in vec4 fa_inst_m3;\nlayout(location = 0) in vec3 fa_position;\nlayout(location = 1) in vec3 fa_normal;\nlayout(location = 3) in vec4 fa_tangent;\nlayout(location = 2) in vec2 fa_texcoord0;\nlayout(location = 4) in vec4 fa_color;\nvec4 fa_vtime;\n\nvoid fa_inst_begin()\n{\n}\n\nmat4 fa_skin_matrix(vec4 joints, vec4 weights)\n{\n    vec4 r0 = vec4(0.0);\n    vec4 r1 = vec4(0.0);\n    vec4 r2 = vec4(0.0);\n    for (int i = 0; i < 4; i++)\n    {\n        int _204 = int((joints[i] * 255.0) + 0.5) * 3;\n        r0 += (fa_skin[_204 * 1 + 0] * weights[i]);\n        r1 += (fa_skin[(_204 + 1) * 1 + 0] * weights[i]);\n        r2 += (fa_skin[(_204 + 2) * 1 + 0] * weights[i]);\n    }\n    return mat4(vec4(r0.x, r1.x, r2.x, 0.0), vec4(r0.y, r1.y, r2.y, 0.0), vec4(r0.z, r1.z, r2.z, 0.0), vec4(r0.w, r1.w, r2.w, 1.0));\n}\n\nvec4 fa_time_now()\n{\n    return fa_mesh_vs_params[9];\n}\n\nVertexData fa_vertex_data(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    vec3 _113 = cross(model[1].xyz, model[2].xyz);\n    float _117 = (dot(model[0].xyz, _113) < 0.0) ? (-1.0) : 1.0;\n    return VertexData((model * vec4(position, 1.0)).xyz, (((_113 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _117, vec4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _117), texcoord0 * fa_mesh_vs_params[8].xy, color, position);\n}\n\nmat4 fa_rows_to_mat4(vec4 r0, vec4 r1, vec4 r2)\n{\n    return mat4(vec4(r0.x, r1.x, r2.x, 0.0), vec4(r0.y, r1.y, r2.y, 0.0), vec4(r0.z, r1.z, r2.z, 0.0), vec4(r0.w, r1.w, r2.w, 1.0));\n}\n\nvec4 fa_prev_pal_texel(int t)\n{\n    return texelFetch(fa_prev_pal_tex_fa_prev_pal_smp, ivec2(t & 1023, t >> 10), 0);\n}\n\nmat4 fa_prev_skin_matrix(vec4 joints, vec4 weights, int base)\n{\n    vec4 r0 = vec4(0.0);\n    vec4 r1 = vec4(0.0);\n    vec4 r2 = vec4(0.0);\n    for (int i = 0; i < 4; i++)\n    {\n        int _332 = base + (int((joints[i] * 255.0) + 0.5) * 3);\n        int param = _332;\n        r0 += (fa_prev_pal_texel(param) * weights[i]);\n        int param_1 = _332 + 1;\n        r1 += (fa_prev_pal_texel(param_1) * weights[i]);\n        int param_2 = _332 + 2;\n        r2 += (fa_prev_pal_texel(param_2) * weights[i]);\n    }\n    return mat4(vec4(r0.x, r1.x, r2.x, 0.0), vec4(r0.y, r1.y, r2.y, 0.0), vec4(r0.z, r1.z, r2.z, 0.0), vec4(r0.w, r1.w, r2.w, 1.0));\n}\n\nmat4 fa_prev_model()\n{\n    vec4 param = fa_prev_r0;\n    vec4 param_1 = fa_prev_r1;\n    vec4 param_2 = fa_prev_r2;\n    vec4 param_3 = fa_joints;\n    vec4 param_4 = fa_weights;\n    int param_5 = int(fa_vel_params[8].w + 0.5);\n    return fa_rows_to_mat4(param, param_1, param_2) * fa_prev_skin_matrix(param_3, param_4, param_5);\n}\n\nvoid fa_prepass_vertex(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color, bool has_prev)\n{\n    bool _475;\n    if (has_prev)\n    {\n        _475 = fa_vel_params[8].x > 0.5;\n    }\n    else\n    {\n        _475 = has_prev;\n    }\n    fa_vtime = fa_time_now();\n    mat4 param = model;\n    vec3 param_1 = position;\n    vec3 param_2 = normal;\n    vec4 param_3 = tangent;\n    vec2 param_4 = texcoord0;\n    vec4 param_5 = color;\n    VertexData _490 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    vec3 _725 = _490.world_pos;\n    mat4 _494 = mat4(fa_mesh_vs_params[4], fa_mesh_vs_params[5], fa_mesh_vs_params[6], fa_mesh_vs_params[7]);\n    vec4 _501 = vec4(_725, 1.0);\n    fa_world_pos = _725;\n    fa_world_normal = _490.world_normal;\n    fa_world_tangent = _490.world_tangent;\n    fa_uv = _490.uv;\n    fa_vertex_color = _490.color;\n    fa_pre_depth = -(_494 * _501).z;\n    fa_pre_r0 = vec3(_494[0].x, _494[1].x, _494[2].x);\n    fa_pre_r1 = vec3(_494[0].y, _494[1].y, _494[2].y);\n    fa_pre_r2 = vec3(_494[0].z, _494[1].z, _494[2].z);\n    gl_Position = mat4(fa_mesh_vs_params[0], fa_mesh_vs_params[1], fa_mesh_vs_params[2], fa_mesh_vs_params[3]) * _501;\n    fa_vel_cur = vec3(0.0, 0.0, 1.0);\n    fa_vel_prev = vec3(0.0);\n    if (_475)\n    {\n        vec4 _574 = vec4(position, 1.0);\n        fa_vel_cur = vec3((mat4(fa_vel_params[0], fa_vel_params[1], fa_vel_params[2], fa_vel_params[3]) * _501).xyw);\n        fa_vel_prev = vec3((mat4(fa_vel_params[4], fa_vel_params[5], fa_vel_params[6], fa_vel_params[7]) * vec4((_725 + (fa_prev_model() * _574).xyz) - (model * _574).xyz, 1.0)).xyw);\n    }\n}\n\nvoid main()\n{\n    fa_vtime = vec4(0.0);\n    fa_inst_begin();\n    vec4 param = fa_joints;\n    vec4 param_1 = fa_weights;\n    mat4 param_2 = mat4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3) * fa_skin_matrix(param, param_1);\n    vec3 param_3 = fa_position;\n    vec3 param_4 = fa_normal;\n    vec4 param_5 = fa_tangent;\n    vec2 param_6 = fa_texcoord0;\n    vec4 param_7 = fa_color;\n    bool param_8 = fa_vel_params[8].z > 0.5;\n    fa_prepass_vertex(param_2, param_3, param_4, param_5, param_6, param_7, param_8);\n}\n\n",
      "fs": "#version 430\n\nstruct SurfaceInput\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 vertex_color;\n    vec3 view_dir;\n    bool front_facing;\n};\n\nstruct Surface\n{\n    vec3 albedo;\n    float alpha;\n    vec3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    vec3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    vec3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    vec3 specular_color;\n    float transmission;\n    float thickness;\n    vec3 attenuation_color;\n    float attenuation_distance;\n};\n\nuniform vec4 fa_mesh_fs_params[54];\nuniform vec4 fa_material[1];\nlayout(binding = 0) uniform sampler2D fa_tex_fa_smp;\nlayout(binding = 1) uniform sampler2D fa_normal_tex_fa_smp;\nlayout(binding = 2) uniform sampler2D fa_mr_tex_fa_smp;\nlayout(binding = 3) uniform sampler2D fa_occlusion_tex_fa_smp;\nlayout(binding = 4) uniform sampler2D fa_emissive_tex_fa_smp;\nlayout(binding = 5) uniform sampler2D mask_mask_smp;\n\nlayout(location = 0) in vec3 fa_world_pos;\nlayout(location = 1) in vec3 fa_world_normal;\nlayout(location = 2) in vec4 fa_world_tangent;\nlayout(location = 3) in vec2 fa_uv;\nlayout(location = 4) in vec4 fa_vertex_color;\nlayout(location = 6) in vec3 fa_pre_r0;\nlayout(location = 7) in vec3 fa_pre_r1;\nlayout(location = 8) in vec3 fa_pre_r2;\nlayout(location = 0) out vec4 fa_frag_color;\nlayout(location = 5) in float fa_pre_depth;\nlayout(location = 9) in vec3 fa_vel_cur;\nlayout(location = 10) in vec3 fa_vel_prev;\nlayout(location = 1) out vec2 fa_frag_velocity;\n\nvoid fa_inst_load()\n{\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nvec3 fa_linear_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_tex_fix(inout vec3 c, float mode)\n{\n    if (mode > 1.5)\n    {\n        vec3 param = c;\n        vec3 _237 = fa_linear_to_srgb(param);\n        c = _237;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            vec3 param_1 = c;\n            vec3 _246 = fa_srgb_to_linear(param_1);\n            c = _246;\n        }\n    }\n    return c;\n}\n\nvec3 fa_tangent_normal(SurfaceInput i, vec3 m)\n{\n    vec3 _58;\n    if (i.front_facing)\n    {\n        _58 = i.world_normal;\n    }\n    else\n    {\n        _58 = -i.world_normal;\n    }\n    vec3 _83 = normalize(i.world_tangent.xyz - (_58 * dot(_58, i.world_tangent.xyz)));\n    vec3 _111 = normalize(((_83 * m.x) + ((cross(_58, _83) * i.world_tangent.w) * m.y)) + (_58 * m.z));\n    vec3 _114;\n    if (i.front_facing)\n    {\n        _114 = _111;\n    }\n    else\n    {\n        _114 = -_111;\n    }\n    return _114;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    vec4 base_t = texture(fa_tex_fa_smp, i.uv, fa_mesh_fs_params[12].w);\n    float param = fa_mesh_fs_params[6].w;\n    float param_1 = 1.0;\n    vec3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    vec3 _282 = fa_tex_fix(param_2, param_3);\n    vec4 _901 = base_t;\n    _901.x = _282.x;\n    _901.y = _282.y;\n    _901.z = _282.z;\n    base_t = _901;\n    vec4 _298 = (_901 * fa_mesh_fs_params[2]) * i.vertex_color;\n    vec3 _856 = i.world_normal;\n    if (fa_mesh_fs_params[6].z > 0.5)\n    {\n        float param_4 = fa_mesh_fs_params[6].w;\n        float param_5 = 16.0;\n        vec3 param_6 = texture(fa_normal_tex_fa_smp, i.uv, fa_mesh_fs_params[12].w).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        vec3 _334 = fa_tex_fix(param_6, param_7);\n        vec3 _337 = (_334 * 2.0) - vec3(1.0);\n        vec2 _342 = _337.xy * fa_mesh_fs_params[6].x;\n        vec3 _909 = _337;\n        _909.x = _342.x;\n        _909.y = _342.y;\n        SurfaceInput param_8 = i;\n        vec3 param_9 = _909;\n        _856 = fa_tangent_normal(param_8, param_9);\n    }\n    vec4 mrt = texture(fa_mr_tex_fa_smp, i.uv, fa_mesh_fs_params[12].w);\n    float param_10 = fa_mesh_fs_params[6].w;\n    float param_11 = 64.0;\n    vec3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    vec3 _373 = fa_tex_fix(param_12, param_13);\n    vec4 _912 = mrt;\n    _912.x = _373.x;\n    _912.y = _373.y;\n    _912.z = _373.z;\n    mrt = _912;\n    vec4 _405 = texture(fa_occlusion_tex_fa_smp, i.uv, fa_mesh_fs_params[12].w);\n    float param_14 = fa_mesh_fs_params[6].w;\n    float param_15 = 256.0;\n    vec3 param_16 = _405.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    vec3 _417 = fa_tex_fix(param_16, param_17);\n    float param_18 = fa_mesh_fs_params[6].w;\n    float param_19 = 4.0;\n    vec3 param_20 = texture(fa_emissive_tex_fa_smp, i.uv, fa_mesh_fs_params[12].w).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    vec3 _449 = fa_tex_fix(param_20, param_21);\n    float _861 = fa_mesh_fs_params[20].x;\n    float _862 = fa_mesh_fs_params[20].y;\n    float _865 = fa_mesh_fs_params[20].z;\n    float _864 = fa_mesh_fs_params[21].w;\n    float _867 = fa_mesh_fs_params[22].x;\n    if (fa_mesh_fs_params[22].z > 0.5)\n    {\n        if (mod(fa_mesh_fs_params[22].z, 2.0) > 0.5)\n        {\n            _861 *= _417.y;\n            _862 *= _417.z;\n            _864 *= _405.w;\n        }\n        if (fa_mesh_fs_params[22].z > 1.5)\n        {\n            _865 *= mrt.x;\n            _867 *= mrt.w;\n        }\n    }\n    return Surface(_298.xyz, _298.w, _856, clamp(fa_mesh_fs_params[5].x * _373.z, 0.0, 1.0), clamp(fa_mesh_fs_params[5].y * _373.y, 0.0500000007450580596923828125, 1.0), 1.0 + (fa_mesh_fs_params[6].y * (_417.x - 1.0)), fa_mesh_fs_params[3].xyz + (fa_mesh_fs_params[4].xyz * _449), _861, _862, fa_mesh_fs_params[21].xyz, _864, _865, fa_mesh_fs_params[20].w, _867, fa_mesh_fs_params[22].y, fa_mesh_fs_params[23].xyz, fa_mesh_fs_params[30].x, fa_mesh_fs_params[30].y, fa_mesh_fs_params[31].xyz, fa_mesh_fs_params[30].z);\n}\n\nvoid surface(SurfaceInput i, inout Surface s)\n{\n    s.alpha = texture(mask_mask_smp, i.uv * 2.0).x;\n}\n\nvoid fa_lod_dither()\n{\n    if (fa_mesh_fs_params[52].w != 0.0)\n    {\n        float _151 = fract(52.98291778564453125 * fract(dot(gl_FragCoord.xy, vec2(0.067110560834407806396484375, 0.005837149918079376220703125))));\n        bool _154;\n        if (fa_mesh_fs_params[52].w > 0.0)\n        {\n            _154 = _151 >= fa_mesh_fs_params[52].w;\n        }\n        else\n        {\n            _154 = _151 < (-fa_mesh_fs_params[52].w);\n        }\n        if (_154)\n        {\n            discard;\n        }\n    }\n}\n\nvoid main()\n{\n    fa_inst_load();\n    vec3 _751 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _751 = -_751;\n    }\n    vec3 _600 = normalize(fa_mesh_fs_params[0].xyz - fa_world_pos);\n    SurfaceInput param = SurfaceInput(fa_world_pos, _751, fa_world_tangent, fa_uv, fa_vertex_color, _600, gl_FrontFacing);\n    Surface _605 = fa_standard_surface(param);\n    vec3 _775 = _605.normal;\n    SurfaceInput param_1 = SurfaceInput(fa_world_pos, _751, fa_world_tangent, fa_uv, fa_vertex_color, _600, gl_FrontFacing);\n    Surface param_2 = _605;\n    surface(param_1, param_2);\n    _775 = param_2.normal;\n    if (param_2.alpha < fa_material[0].x)\n    {\n        discard;\n    }\n    fa_lod_dither();\n    vec3 _627 = normalize(_775);\n    vec3 _642 = normalize(vec3(dot(fa_pre_r0, _627), dot(fa_pre_r1, _627), dot(fa_pre_r2, _627)));\n    float _654 = _642.z;\n    vec2 e = _642.xy / vec2((abs(_642.x) + abs(_642.y)) + abs(_654));\n    if (_654 < 0.0)\n    {\n        e = (vec2(1.0) - abs(e.yx)) * vec2((e.x >= 0.0) ? 1.0 : (-1.0), (e.y >= 0.0) ? 1.0 : (-1.0));\n    }\n    fa_frag_color = vec4(min(fa_pre_depth, 60000.0), e, 1.0);\n    vec2 motion = vec2(1024.0);\n    bool _698 = fa_vel_cur.z > 9.9999997473787516355514526367188e-06;\n    bool _705;\n    if (_698)\n    {\n        _705 = fa_vel_prev.z > 9.9999997473787516355514526367188e-06;\n    }\n    else\n    {\n        _705 = _698;\n    }\n    if (_705)\n    {\n        motion = clamp(((vec2(fa_vel_prev.x, -fa_vel_prev.y) / vec2(fa_vel_prev.z)) * 0.5) - ((vec2(fa_vel_cur.x, -fa_vel_cur.y) / vec2(fa_vel_cur.z)) * 0.5), vec2(-4.0), vec2(4.0));\n    }\n    fa_frag_velocity = motion;\n}\n\n",
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
            "inst_name": "_129",
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
            "slot": 5,
            "stage": "fragment",
            "size": 16,
            "struct_name": "fa_material",
            "inst_name": "_616",
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
          },
          {
            "texture": {
              "slot": 6,
              "stage": "fragment",
              "name": "mask",
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
            "slot": 2,
            "stage": "fragment",
            "name": "mask_smp",
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
          },
          {
            "slot": 6,
            "stage": "fragment",
            "name": "mask_mask_smp",
            "view_name": "mask",
            "sampler_name": "mask_smp",
            "view_slot": 6,
            "sampler_slot": 2,
            "glsl_name": "mask_mask_smp"
          }
        ]
      }
    },
    "shadow": {
      "vs": "#version 430\n\nstruct VertexData\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 color;\n    vec3 object_pos;\n};\n\nuniform vec4 fa_mesh_vs_params[11];\nlayout(location = 1) in vec4 fa_inst_m0;\nlayout(location = 2) in vec4 fa_inst_m1;\nlayout(location = 3) in vec4 fa_inst_m2;\nlayout(location = 4) in vec4 fa_inst_m3;\nlayout(location = 0) in vec3 fa_position;\nlayout(location = 5) in vec3 fa_normal;\nlayout(location = 7) in vec4 fa_tangent;\nlayout(location = 6) in vec2 fa_texcoord0;\nlayout(location = 8) in vec4 fa_color;\nlayout(location = 0) out vec3 fa_world_pos;\nlayout(location = 1) out vec3 fa_world_normal;\nlayout(location = 2) out vec4 fa_world_tangent;\nlayout(location = 3) out vec2 fa_uv;\nlayout(location = 4) out vec4 fa_vertex_color;\n\nvoid fa_inst_begin()\n{\n}\n\nVertexData fa_vertex_data(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    vec3 _60 = cross(model[1].xyz, model[2].xyz);\n    float _66 = (dot(model[0].xyz, _60) < 0.0) ? (-1.0) : 1.0;\n    return VertexData((model * vec4(position, 1.0)).xyz, (((_60 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _66, vec4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _66), texcoord0 * fa_mesh_vs_params[8].xy, color, position);\n}\n\nvoid main()\n{\n    fa_inst_begin();\n    mat4 param = mat4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3);\n    vec3 param_1 = fa_position;\n    vec3 param_2 = fa_normal;\n    vec4 param_3 = fa_tangent;\n    vec2 param_4 = fa_texcoord0;\n    vec4 param_5 = fa_color;\n    VertexData _190 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    vec3 _239 = _190.world_pos;\n    fa_world_pos = _239;\n    fa_world_normal = _190.world_normal;\n    fa_world_tangent = _190.world_tangent;\n    fa_uv = _190.uv;\n    fa_vertex_color = _190.color;\n    gl_Position = mat4(fa_mesh_vs_params[4], fa_mesh_vs_params[5], fa_mesh_vs_params[6], fa_mesh_vs_params[7]) * vec4(_239, 1.0);\n}\n\n",
      "fs": "#version 430\n\nstruct SurfaceInput\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 vertex_color;\n    vec3 view_dir;\n    bool front_facing;\n};\n\nstruct Surface\n{\n    vec3 albedo;\n    float alpha;\n    vec3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    vec3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    vec3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    vec3 specular_color;\n    float transmission;\n    float thickness;\n    vec3 attenuation_color;\n    float attenuation_distance;\n};\n\nuniform vec4 fa_mesh_fs_params[54];\nuniform vec4 fa_material[1];\nlayout(binding = 0) uniform sampler2D fa_tex_fa_smp;\nlayout(binding = 1) uniform sampler2D fa_normal_tex_fa_smp;\nlayout(binding = 2) uniform sampler2D fa_mr_tex_fa_smp;\nlayout(binding = 3) uniform sampler2D fa_occlusion_tex_fa_smp;\nlayout(binding = 4) uniform sampler2D fa_emissive_tex_fa_smp;\nlayout(binding = 5) uniform sampler2D mask_mask_smp;\n\nlayout(location = 0) in vec3 fa_world_pos;\nlayout(location = 1) in vec3 fa_world_normal;\nlayout(location = 2) in vec4 fa_world_tangent;\nlayout(location = 3) in vec2 fa_uv;\nlayout(location = 4) in vec4 fa_vertex_color;\nlayout(location = 0) out vec4 fa_frag_color;\n\nvoid fa_inst_load()\n{\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nvec3 fa_linear_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_tex_fix(inout vec3 c, float mode)\n{\n    if (mode > 1.5)\n    {\n        vec3 param = c;\n        vec3 _191 = fa_linear_to_srgb(param);\n        c = _191;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            vec3 param_1 = c;\n            vec3 _200 = fa_srgb_to_linear(param_1);\n            c = _200;\n        }\n    }\n    return c;\n}\n\nvec3 fa_tangent_normal(SurfaceInput i, vec3 m)\n{\n    vec3 _56;\n    if (i.front_facing)\n    {\n        _56 = i.world_normal;\n    }\n    else\n    {\n        _56 = -i.world_normal;\n    }\n    vec3 _81 = normalize(i.world_tangent.xyz - (_56 * dot(_56, i.world_tangent.xyz)));\n    vec3 _109 = normalize(((_81 * m.x) + ((cross(_56, _81) * i.world_tangent.w) * m.y)) + (_56 * m.z));\n    vec3 _112;\n    if (i.front_facing)\n    {\n        _112 = _109;\n    }\n    else\n    {\n        _112 = -_109;\n    }\n    return _112;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    vec4 base_t = texture(fa_tex_fa_smp, i.uv, fa_mesh_fs_params[12].w);\n    float param = fa_mesh_fs_params[6].w;\n    float param_1 = 1.0;\n    vec3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    vec3 _242 = fa_tex_fix(param_2, param_3);\n    vec4 _744 = base_t;\n    _744.x = _242.x;\n    _744.y = _242.y;\n    _744.z = _242.z;\n    base_t = _744;\n    vec4 _258 = (_744 * fa_mesh_fs_params[2]) * i.vertex_color;\n    vec3 _705 = i.world_normal;\n    if (fa_mesh_fs_params[6].z > 0.5)\n    {\n        float param_4 = fa_mesh_fs_params[6].w;\n        float param_5 = 16.0;\n        vec3 param_6 = texture(fa_normal_tex_fa_smp, i.uv, fa_mesh_fs_params[12].w).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        vec3 _294 = fa_tex_fix(param_6, param_7);\n        vec3 _297 = (_294 * 2.0) - vec3(1.0);\n        vec2 _302 = _297.xy * fa_mesh_fs_params[6].x;\n        vec3 _752 = _297;\n        _752.x = _302.x;\n        _752.y = _302.y;\n        SurfaceInput param_8 = i;\n        vec3 param_9 = _752;\n        _705 = fa_tangent_normal(param_8, param_9);\n    }\n    vec4 mrt = texture(fa_mr_tex_fa_smp, i.uv, fa_mesh_fs_params[12].w);\n    float param_10 = fa_mesh_fs_params[6].w;\n    float param_11 = 64.0;\n    vec3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    vec3 _333 = fa_tex_fix(param_12, param_13);\n    vec4 _755 = mrt;\n    _755.x = _333.x;\n    _755.y = _333.y;\n    _755.z = _333.z;\n    mrt = _755;\n    vec4 _365 = texture(fa_occlusion_tex_fa_smp, i.uv, fa_mesh_fs_params[12].w);\n    float param_14 = fa_mesh_fs_params[6].w;\n    float param_15 = 256.0;\n    vec3 param_16 = _365.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    vec3 _377 = fa_tex_fix(param_16, param_17);\n    float param_18 = fa_mesh_fs_params[6].w;\n    float param_19 = 4.0;\n    vec3 param_20 = texture(fa_emissive_tex_fa_smp, i.uv, fa_mesh_fs_params[12].w).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    vec3 _409 = fa_tex_fix(param_20, param_21);\n    float _710 = fa_mesh_fs_params[20].x;\n    float _711 = fa_mesh_fs_params[20].y;\n    float _714 = fa_mesh_fs_params[20].z;\n    float _713 = fa_mesh_fs_params[21].w;\n    float _716 = fa_mesh_fs_params[22].x;\n    if (fa_mesh_fs_params[22].z > 0.5)\n    {\n        if (mod(fa_mesh_fs_params[22].z, 2.0) > 0.5)\n        {\n            _710 *= _377.y;\n            _711 *= _377.z;\n            _713 *= _365.w;\n        }\n        if (fa_mesh_fs_params[22].z > 1.5)\n        {\n            _714 *= mrt.x;\n            _716 *= mrt.w;\n        }\n    }\n    return Surface(_258.xyz, _258.w, _705, clamp(fa_mesh_fs_params[5].x * _333.z, 0.0, 1.0), clamp(fa_mesh_fs_params[5].y * _333.y, 0.0500000007450580596923828125, 1.0), 1.0 + (fa_mesh_fs_params[6].y * (_377.x - 1.0)), fa_mesh_fs_params[3].xyz + (fa_mesh_fs_params[4].xyz * _409), _710, _711, fa_mesh_fs_params[21].xyz, _713, _714, fa_mesh_fs_params[20].w, _716, fa_mesh_fs_params[22].y, fa_mesh_fs_params[23].xyz, fa_mesh_fs_params[30].x, fa_mesh_fs_params[30].y, fa_mesh_fs_params[31].xyz, fa_mesh_fs_params[30].z);\n}\n\nvoid surface(SurfaceInput i, inout Surface s)\n{\n    s.alpha = texture(mask_mask_smp, i.uv * 2.0).x;\n}\n\nvoid main()\n{\n    fa_inst_load();\n    vec3 _600 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _600 = -_600;\n    }\n    vec3 _561 = normalize(fa_mesh_fs_params[0].xyz - fa_world_pos);\n    SurfaceInput param = SurfaceInput(fa_world_pos, _600, fa_world_tangent, fa_uv, fa_vertex_color, _561, gl_FrontFacing);\n    SurfaceInput param_1 = SurfaceInput(fa_world_pos, _600, fa_world_tangent, fa_uv, fa_vertex_color, _561, gl_FrontFacing);\n    Surface param_2 = fa_standard_surface(param);\n    surface(param_1, param_2);\n    if (param_2.alpha < fa_material[0].x)\n    {\n        discard;\n    }\n    fa_frag_color = vec4(gl_FragCoord.z, 0.0, 0.0, 1.0);\n}\n\n",
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
          }
        ],
        "uniform_blocks": [
          {
            "slot": 0,
            "stage": "vertex",
            "size": 176,
            "struct_name": "fa_mesh_vs_params",
            "inst_name": "_122",
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
            "inst_name": "_226",
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
            "slot": 5,
            "stage": "fragment",
            "size": 16,
            "struct_name": "fa_material",
            "inst_name": "_577",
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
          },
          {
            "texture": {
              "slot": 6,
              "stage": "fragment",
              "name": "mask",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float"
            }
          }
        ],
        "samplers": [
          {
            "slot": 2,
            "stage": "fragment",
            "name": "mask_smp",
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
          },
          {
            "slot": 5,
            "stage": "fragment",
            "name": "mask_mask_smp",
            "view_name": "mask",
            "sampler_name": "mask_smp",
            "view_slot": 6,
            "sampler_slot": 2,
            "glsl_name": "mask_mask_smp"
          }
        ]
      }
    },
    "shadow_skin": {
      "vs": "#version 430\n\nstruct VertexData\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 color;\n    vec3 object_pos;\n};\n\nuniform vec4 fa_mesh_vs_params[11];\nuniform vec4 fa_skin[192];\nlayout(location = 1) in vec4 fa_inst_m0;\nlayout(location = 2) in vec4 fa_inst_m1;\nlayout(location = 3) in vec4 fa_inst_m2;\nlayout(location = 4) in vec4 fa_inst_m3;\nlayout(location = 5) in vec4 fa_joints;\nlayout(location = 6) in vec4 fa_weights;\nlayout(location = 0) in vec3 fa_position;\nlayout(location = 7) in vec3 fa_normal;\nlayout(location = 9) in vec4 fa_tangent;\nlayout(location = 8) in vec2 fa_texcoord0;\nlayout(location = 10) in vec4 fa_color;\nlayout(location = 0) out vec3 fa_world_pos;\nlayout(location = 1) out vec3 fa_world_normal;\nlayout(location = 2) out vec4 fa_world_tangent;\nlayout(location = 3) out vec2 fa_uv;\nlayout(location = 4) out vec4 fa_vertex_color;\n\nmat4 fa_skin_matrix(vec4 joints, vec4 weights)\n{\n    vec4 r0 = vec4(0.0);\n    vec4 r1 = vec4(0.0);\n    vec4 r2 = vec4(0.0);\n    for (int i = 0; i < 4; i++)\n    {\n        int _165 = int((joints[i] * 255.0) + 0.5) * 3;\n        r0 += (fa_skin[_165 * 1 + 0] * weights[i]);\n        r1 += (fa_skin[(_165 + 1) * 1 + 0] * weights[i]);\n        r2 += (fa_skin[(_165 + 2) * 1 + 0] * weights[i]);\n    }\n    return mat4(vec4(r0.x, r1.x, r2.x, 0.0), vec4(r0.y, r1.y, r2.y, 0.0), vec4(r0.z, r1.z, r2.z, 0.0), vec4(r0.w, r1.w, r2.w, 1.0));\n}\n\nvoid fa_inst_begin()\n{\n}\n\nVertexData fa_vertex_data(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    vec3 _65 = cross(model[1].xyz, model[2].xyz);\n    float _71 = (dot(model[0].xyz, _65) < 0.0) ? (-1.0) : 1.0;\n    return VertexData((model * vec4(position, 1.0)).xyz, (((_65 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _71, vec4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _71), texcoord0 * fa_mesh_vs_params[8].xy, color, position);\n}\n\nvoid main()\n{\n    vec4 param = fa_joints;\n    vec4 param_1 = fa_weights;\n    fa_inst_begin();\n    mat4 param_2 = mat4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3) * fa_skin_matrix(param, param_1);\n    vec3 param_3 = fa_position;\n    vec3 param_4 = fa_normal;\n    vec4 param_5 = fa_tangent;\n    vec2 param_6 = fa_texcoord0;\n    vec4 param_7 = fa_color;\n    VertexData _311 = fa_vertex_data(param_2, param_3, param_4, param_5, param_6, param_7);\n    vec3 _360 = _311.world_pos;\n    fa_world_pos = _360;\n    fa_world_normal = _311.world_normal;\n    fa_world_tangent = _311.world_tangent;\n    fa_uv = _311.uv;\n    fa_vertex_color = _311.color;\n    gl_Position = mat4(fa_mesh_vs_params[4], fa_mesh_vs_params[5], fa_mesh_vs_params[6], fa_mesh_vs_params[7]) * vec4(_360, 1.0);\n}\n\n",
      "fs": "#version 430\n\nstruct SurfaceInput\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 vertex_color;\n    vec3 view_dir;\n    bool front_facing;\n};\n\nstruct Surface\n{\n    vec3 albedo;\n    float alpha;\n    vec3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    vec3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    vec3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    vec3 specular_color;\n    float transmission;\n    float thickness;\n    vec3 attenuation_color;\n    float attenuation_distance;\n};\n\nuniform vec4 fa_mesh_fs_params[54];\nuniform vec4 fa_material[1];\nlayout(binding = 0) uniform sampler2D fa_tex_fa_smp;\nlayout(binding = 1) uniform sampler2D fa_normal_tex_fa_smp;\nlayout(binding = 2) uniform sampler2D fa_mr_tex_fa_smp;\nlayout(binding = 3) uniform sampler2D fa_occlusion_tex_fa_smp;\nlayout(binding = 4) uniform sampler2D fa_emissive_tex_fa_smp;\nlayout(binding = 5) uniform sampler2D mask_mask_smp;\n\nlayout(location = 0) in vec3 fa_world_pos;\nlayout(location = 1) in vec3 fa_world_normal;\nlayout(location = 2) in vec4 fa_world_tangent;\nlayout(location = 3) in vec2 fa_uv;\nlayout(location = 4) in vec4 fa_vertex_color;\nlayout(location = 0) out vec4 fa_frag_color;\n\nvoid fa_inst_load()\n{\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nvec3 fa_linear_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_tex_fix(inout vec3 c, float mode)\n{\n    if (mode > 1.5)\n    {\n        vec3 param = c;\n        vec3 _191 = fa_linear_to_srgb(param);\n        c = _191;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            vec3 param_1 = c;\n            vec3 _200 = fa_srgb_to_linear(param_1);\n            c = _200;\n        }\n    }\n    return c;\n}\n\nvec3 fa_tangent_normal(SurfaceInput i, vec3 m)\n{\n    vec3 _56;\n    if (i.front_facing)\n    {\n        _56 = i.world_normal;\n    }\n    else\n    {\n        _56 = -i.world_normal;\n    }\n    vec3 _81 = normalize(i.world_tangent.xyz - (_56 * dot(_56, i.world_tangent.xyz)));\n    vec3 _109 = normalize(((_81 * m.x) + ((cross(_56, _81) * i.world_tangent.w) * m.y)) + (_56 * m.z));\n    vec3 _112;\n    if (i.front_facing)\n    {\n        _112 = _109;\n    }\n    else\n    {\n        _112 = -_109;\n    }\n    return _112;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    vec4 base_t = texture(fa_tex_fa_smp, i.uv, fa_mesh_fs_params[12].w);\n    float param = fa_mesh_fs_params[6].w;\n    float param_1 = 1.0;\n    vec3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    vec3 _242 = fa_tex_fix(param_2, param_3);\n    vec4 _744 = base_t;\n    _744.x = _242.x;\n    _744.y = _242.y;\n    _744.z = _242.z;\n    base_t = _744;\n    vec4 _258 = (_744 * fa_mesh_fs_params[2]) * i.vertex_color;\n    vec3 _705 = i.world_normal;\n    if (fa_mesh_fs_params[6].z > 0.5)\n    {\n        float param_4 = fa_mesh_fs_params[6].w;\n        float param_5 = 16.0;\n        vec3 param_6 = texture(fa_normal_tex_fa_smp, i.uv, fa_mesh_fs_params[12].w).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        vec3 _294 = fa_tex_fix(param_6, param_7);\n        vec3 _297 = (_294 * 2.0) - vec3(1.0);\n        vec2 _302 = _297.xy * fa_mesh_fs_params[6].x;\n        vec3 _752 = _297;\n        _752.x = _302.x;\n        _752.y = _302.y;\n        SurfaceInput param_8 = i;\n        vec3 param_9 = _752;\n        _705 = fa_tangent_normal(param_8, param_9);\n    }\n    vec4 mrt = texture(fa_mr_tex_fa_smp, i.uv, fa_mesh_fs_params[12].w);\n    float param_10 = fa_mesh_fs_params[6].w;\n    float param_11 = 64.0;\n    vec3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    vec3 _333 = fa_tex_fix(param_12, param_13);\n    vec4 _755 = mrt;\n    _755.x = _333.x;\n    _755.y = _333.y;\n    _755.z = _333.z;\n    mrt = _755;\n    vec4 _365 = texture(fa_occlusion_tex_fa_smp, i.uv, fa_mesh_fs_params[12].w);\n    float param_14 = fa_mesh_fs_params[6].w;\n    float param_15 = 256.0;\n    vec3 param_16 = _365.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    vec3 _377 = fa_tex_fix(param_16, param_17);\n    float param_18 = fa_mesh_fs_params[6].w;\n    float param_19 = 4.0;\n    vec3 param_20 = texture(fa_emissive_tex_fa_smp, i.uv, fa_mesh_fs_params[12].w).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    vec3 _409 = fa_tex_fix(param_20, param_21);\n    float _710 = fa_mesh_fs_params[20].x;\n    float _711 = fa_mesh_fs_params[20].y;\n    float _714 = fa_mesh_fs_params[20].z;\n    float _713 = fa_mesh_fs_params[21].w;\n    float _716 = fa_mesh_fs_params[22].x;\n    if (fa_mesh_fs_params[22].z > 0.5)\n    {\n        if (mod(fa_mesh_fs_params[22].z, 2.0) > 0.5)\n        {\n            _710 *= _377.y;\n            _711 *= _377.z;\n            _713 *= _365.w;\n        }\n        if (fa_mesh_fs_params[22].z > 1.5)\n        {\n            _714 *= mrt.x;\n            _716 *= mrt.w;\n        }\n    }\n    return Surface(_258.xyz, _258.w, _705, clamp(fa_mesh_fs_params[5].x * _333.z, 0.0, 1.0), clamp(fa_mesh_fs_params[5].y * _333.y, 0.0500000007450580596923828125, 1.0), 1.0 + (fa_mesh_fs_params[6].y * (_377.x - 1.0)), fa_mesh_fs_params[3].xyz + (fa_mesh_fs_params[4].xyz * _409), _710, _711, fa_mesh_fs_params[21].xyz, _713, _714, fa_mesh_fs_params[20].w, _716, fa_mesh_fs_params[22].y, fa_mesh_fs_params[23].xyz, fa_mesh_fs_params[30].x, fa_mesh_fs_params[30].y, fa_mesh_fs_params[31].xyz, fa_mesh_fs_params[30].z);\n}\n\nvoid surface(SurfaceInput i, inout Surface s)\n{\n    s.alpha = texture(mask_mask_smp, i.uv * 2.0).x;\n}\n\nvoid main()\n{\n    fa_inst_load();\n    vec3 _600 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _600 = -_600;\n    }\n    vec3 _561 = normalize(fa_mesh_fs_params[0].xyz - fa_world_pos);\n    SurfaceInput param = SurfaceInput(fa_world_pos, _600, fa_world_tangent, fa_uv, fa_vertex_color, _561, gl_FrontFacing);\n    SurfaceInput param_1 = SurfaceInput(fa_world_pos, _600, fa_world_tangent, fa_uv, fa_vertex_color, _561, gl_FrontFacing);\n    Surface param_2 = fa_standard_surface(param);\n    surface(param_1, param_2);\n    if (param_2.alpha < fa_material[0].x)\n    {\n        discard;\n    }\n    fa_frag_color = vec4(gl_FragCoord.z, 0.0, 0.0, 1.0);\n}\n\n",
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
          }
        ],
        "uniform_blocks": [
          {
            "slot": 0,
            "stage": "vertex",
            "size": 176,
            "struct_name": "fa_mesh_vs_params",
            "inst_name": "_127",
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
            "inst_name": "_174",
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
            "inst_name": "_226",
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
            "slot": 5,
            "stage": "fragment",
            "size": 16,
            "struct_name": "fa_material",
            "inst_name": "_577",
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
          },
          {
            "texture": {
              "slot": 6,
              "stage": "fragment",
              "name": "mask",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float"
            }
          }
        ],
        "samplers": [
          {
            "slot": 2,
            "stage": "fragment",
            "name": "mask_smp",
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
          },
          {
            "slot": 5,
            "stage": "fragment",
            "name": "mask_mask_smp",
            "view_name": "mask",
            "sampler_name": "mask_smp",
            "view_slot": 6,
            "sampler_slot": 2,
            "glsl_name": "mask_mask_smp"
          }
        ]
      }
    }
  }
}
