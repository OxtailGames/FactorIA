{
  "format": "factoria.shader/1",
  "engine": "0.34.0",
  "template": "d5ad4ba00a2086cd5c3d6440d2be629e3ce9b0f8ede644c9a19112677c2fea28",
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
      "fs": "#version 430\n\nstruct SurfaceInput\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 vertex_color;\n    vec3 view_dir;\n    bool front_facing;\n};\n\nstruct LightSample\n{\n    vec3 direction;\n    vec3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct Surface\n{\n    vec3 albedo;\n    float alpha;\n    vec3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    vec3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    vec3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    vec3 specular_color;\n    float transmission;\n    float thickness;\n    vec3 attenuation_color;\n    float attenuation_distance;\n};\n\nstruct FaLayers\n{\n    bool on;\n    float f90;\n    float keep;\n    float base_scale;\n    float coat;\n    float coat_rough;\n    float coat_alpha;\n    float coat_a2;\n    vec3 nc;\n    float coat_ndv;\n    bool sheen_on;\n    vec3 sheen;\n    float sheen_rough;\n    float sheen_alpha;\n    float sheen_scale;\n    float sheen_e;\n    float aniso;\n    vec3 t;\n    vec3 b;\n    float at;\n    float ab;\n};\n\nconst float _4389[63] = float[](1.0, 1.0, 1.0, 0.4790000021457672119140625, 0.11699999868869781494140625, 0.01200000010430812835693359375, 0.0, 0.0, 0.0, 1.0, 1.0, 1.0, 0.578000009059906005859375, 0.19300000369548797607421875, 0.0350000001490116119384765625, 0.0030000000260770320892333984375, 0.0, 0.0, 1.0, 1.0, 1.0, 0.6740000247955322265625, 0.3459999859333038330078125, 0.1319999992847442626953125, 0.032999999821186065673828125, 0.0040000001899898052215576171875, 0.0, 0.971000015735626220703125, 0.954999983310699462890625, 0.828999996185302734375, 0.63999998569488525390625, 0.42599999904632568359375, 0.24500000476837158203125, 0.115000002086162567138671875, 0.037000000476837158203125, 0.0030000000260770320892333984375, 0.7469999790191650390625, 0.737999975681304931640625, 0.670000016689300537109375, 0.563000023365020751953125, 0.4309999942779541015625, 0.3039999902248382568359375, 0.1940000057220458984375, 0.1019999980926513671875, 0.0309999994933605194091796875, 0.614000022411346435546875, 0.609000027179718017578125, 0.566999971866607666015625, 0.499000012874603271484375, 0.412000000476837158203125, 0.32400000095367431640625, 0.240999996662139892578125, 0.162000000476837158203125, 0.087999999523162841796875, 0.538999974727630615234375, 0.535000026226043701171875, 0.505999982357025146484375, 0.4569999873638153076171875, 0.393999993801116943359375, 0.328999996185302734375, 0.2660000026226043701171875, 0.203999996185302734375, 0.14200000464916229248046875);\n\nuniform vec4 fa_mesh_fs_params[53];\nuniform vec4 fa_shadows[30];\nuniform vec4 fa_material[1];\nlayout(binding = 0) uniform sampler2D fa_light_tex_fa_shadow_smp;\nlayout(binding = 1) uniform sampler2D fa_tex_fa_smp;\nlayout(binding = 2) uniform sampler2D fa_normal_tex_fa_smp;\nlayout(binding = 3) uniform sampler2D fa_mr_tex_fa_smp;\nlayout(binding = 4) uniform sampler2D fa_occlusion_tex_fa_smp;\nlayout(binding = 5) uniform sampler2D fa_emissive_tex_fa_smp;\nlayout(binding = 6) uniform sampler2D mask_mask_smp;\nlayout(binding = 7) uniform sampler2D fa_decal_tex_fa_env_smp;\nlayout(binding = 8) uniform sampler2D fa_lightmap_fa_env_smp;\nlayout(binding = 9) uniform sampler2D fa_probe_atlas_fa_env_smp;\nlayout(binding = 10) uniform sampler2D fa_light_atlas_fa_env_smp;\nlayout(binding = 11) uniform sampler2D fa_shadow_tex_fa_shadow_smp;\nlayout(binding = 12) uniform sampler2D fa_screen_tex_fa_shadow_smp;\n\nlayout(location = 0) in vec3 fa_world_pos;\nlayout(location = 5) in vec3 fa_lm;\nlayout(location = 1) in vec3 fa_world_normal;\nlayout(location = 2) in vec4 fa_world_tangent;\nlayout(location = 3) in vec2 fa_uv;\nlayout(location = 4) in vec4 fa_vertex_color;\nlayout(location = 0) out vec4 fa_frag_color;\nvec3 fa_light_tint;\nbool fa_light_is_area;\nint fa_cl_ndir;\nint fa_cl_slot;\nint fa_cl_local;\n\nvoid fa_inst_load()\n{\n}\n\nvec4 fa_light_texel(int t)\n{\n    return texelFetch(fa_light_tex_fa_shadow_smp, ivec2(t & 1023, t >> 10), 0);\n}\n\nvec4 fa_cluster_texel(vec3 world_pos)\n{\n    bool _1628 = fa_mesh_fs_params[19].x < 0.0;\n    bool _1635;\n    if (!_1628)\n    {\n        _1635 = fa_mesh_fs_params[19].w < 1.0;\n    }\n    else\n    {\n        _1635 = _1628;\n    }\n    bool _1643;\n    if (!_1635)\n    {\n        _1643 = fa_mesh_fs_params[18].x < 1.0;\n    }\n    else\n    {\n        _1643 = _1635;\n    }\n    bool _1650;\n    if (!_1643)\n    {\n        _1650 = fa_mesh_fs_params[18].y < 1.0;\n    }\n    else\n    {\n        _1650 = _1643;\n    }\n    bool _1657;\n    if (!_1650)\n    {\n        _1657 = fa_mesh_fs_params[19].y < 1.0;\n    }\n    else\n    {\n        _1657 = _1650;\n    }\n    if (_1657)\n    {\n        return vec4(0.0);\n    }\n    vec4 _1667 = vec4(world_pos, 1.0);\n    float _1673 = dot(fa_mesh_fs_params[16], _1667);\n    if (!(_1673 > 9.9999999747524270787835121154785e-07))\n    {\n        return vec4(0.0);\n    }\n    vec2 _1695 = vec2(dot(fa_mesh_fs_params[14], _1667), dot(fa_mesh_fs_params[15], _1667)) / vec2(_1673);\n    int _1699 = int(fa_mesh_fs_params[18].x);\n    int _1703 = int(fa_mesh_fs_params[18].y);\n    int param = (int(fa_mesh_fs_params[19].x) + (((clamp(int(floor(log2(max(dot(fa_mesh_fs_params[17].xyz, world_pos) + fa_mesh_fs_params[17].w, fa_mesh_fs_params[18].w) / fa_mesh_fs_params[18].w) * fa_mesh_fs_params[18].z)), 0, int(fa_mesh_fs_params[19].y) - 1) * _1703) + clamp(int(floor(((_1695.y * 0.5) + 0.5) * fa_mesh_fs_params[18].y)), 0, _1703 - 1)) * _1699)) + clamp(int(floor(((_1695.x * 0.5) + 0.5) * fa_mesh_fs_params[18].x)), 0, _1699 - 1);\n    return fa_light_texel(param);\n}\n\nivec2 fa_cluster_lookup(vec3 world_pos)\n{\n    vec3 param = world_pos;\n    vec4 _1779 = fa_cluster_texel(param);\n    return ivec2(int(_1779.x), int(_1779.y));\n}\n\nvoid fa_cluster_begin(vec3 world_pos)\n{\n    fa_cl_ndir = int(fa_mesh_fs_params[19].z);\n    vec3 param = world_pos;\n    ivec2 _5864 = fa_cluster_lookup(param);\n    fa_cl_slot = _5864.x;\n    fa_cl_local = _5864.y;\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nvec3 fa_linear_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_tex_fix(inout vec3 c, float mode)\n{\n    if (mode > 1.5)\n    {\n        vec3 param = c;\n        vec3 _7034 = fa_linear_to_srgb(param);\n        c = _7034;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            vec3 param_1 = c;\n            vec3 _7042 = fa_srgb_to_linear(param_1);\n            c = _7042;\n        }\n    }\n    return c;\n}\n\nvec3 fa_tangent_normal(SurfaceInput i, vec3 m)\n{\n    vec3 _534;\n    if (i.front_facing)\n    {\n        _534 = i.world_normal;\n    }\n    else\n    {\n        _534 = -i.world_normal;\n    }\n    vec3 _558 = normalize(i.world_tangent.xyz - (_534 * dot(_534, i.world_tangent.xyz)));\n    vec3 _585 = normalize(((_558 * m.x) + ((cross(_534, _558) * i.world_tangent.w) * m.y)) + (_534 * m.z));\n    vec3 _588;\n    if (i.front_facing)\n    {\n        _588 = _585;\n    }\n    else\n    {\n        _588 = -_585;\n    }\n    return _588;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    vec4 base_t = texture(fa_tex_fa_smp, i.uv);\n    float param = fa_mesh_fs_params[6].w;\n    float param_1 = 1.0;\n    vec3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    vec3 _7073 = fa_tex_fix(param_2, param_3);\n    vec4 _9346 = base_t;\n    _9346.x = _7073.x;\n    _9346.y = _7073.y;\n    _9346.z = _7073.z;\n    base_t = _9346;\n    vec4 _7087 = (_9346 * fa_mesh_fs_params[2]) * i.vertex_color;\n    vec3 _9122 = i.world_normal;\n    if (fa_mesh_fs_params[6].z > 0.5)\n    {\n        float param_4 = fa_mesh_fs_params[6].w;\n        float param_5 = 16.0;\n        vec3 param_6 = texture(fa_normal_tex_fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        vec3 _7119 = fa_tex_fix(param_6, param_7);\n        vec3 _7122 = (_7119 * 2.0) - vec3(1.0);\n        vec2 _7127 = _7122.xy * fa_mesh_fs_params[6].x;\n        vec3 _9354 = _7122;\n        _9354.x = _7127.x;\n        _9354.y = _7127.y;\n        SurfaceInput param_8 = i;\n        vec3 param_9 = _9354;\n        _9122 = fa_tangent_normal(param_8, param_9);\n    }\n    vec4 mrt = texture(fa_mr_tex_fa_smp, i.uv);\n    float param_10 = fa_mesh_fs_params[6].w;\n    float param_11 = 64.0;\n    vec3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    vec3 _7155 = fa_tex_fix(param_12, param_13);\n    vec4 _9357 = mrt;\n    _9357.x = _7155.x;\n    _9357.y = _7155.y;\n    _9357.z = _7155.z;\n    mrt = _9357;\n    vec4 _7183 = texture(fa_occlusion_tex_fa_smp, i.uv);\n    float param_14 = fa_mesh_fs_params[6].w;\n    float param_15 = 256.0;\n    vec3 param_16 = _7183.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    vec3 _7194 = fa_tex_fix(param_16, param_17);\n    float param_18 = fa_mesh_fs_params[6].w;\n    float param_19 = 4.0;\n    vec3 param_20 = texture(fa_emissive_tex_fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    vec3 _7224 = fa_tex_fix(param_20, param_21);\n    float _9127 = fa_mesh_fs_params[20].x;\n    float _9128 = fa_mesh_fs_params[20].y;\n    float _9131 = fa_mesh_fs_params[20].z;\n    float _9130 = fa_mesh_fs_params[21].w;\n    float _9133 = fa_mesh_fs_params[22].x;\n    if (fa_mesh_fs_params[22].z > 0.5)\n    {\n        if (mod(fa_mesh_fs_params[22].z, 2.0) > 0.5)\n        {\n            _9127 *= _7194.y;\n            _9128 *= _7194.z;\n            _9130 *= _7183.w;\n        }\n        if (fa_mesh_fs_params[22].z > 1.5)\n        {\n            _9131 *= mrt.x;\n            _9133 *= mrt.w;\n        }\n    }\n    return Surface(_7087.xyz, _7087.w, _9122, clamp(fa_mesh_fs_params[5].x * _7155.z, 0.0, 1.0), clamp(fa_mesh_fs_params[5].y * _7155.y, 0.0500000007450580596923828125, 1.0), 1.0 + (fa_mesh_fs_params[6].y * (_7194.x - 1.0)), fa_mesh_fs_params[3].xyz + (fa_mesh_fs_params[4].xyz * _7224), _9127, _9128, fa_mesh_fs_params[21].xyz, _9130, _9131, fa_mesh_fs_params[20].w, _9133, fa_mesh_fs_params[22].y, fa_mesh_fs_params[23].xyz, fa_mesh_fs_params[30].x, fa_mesh_fs_params[30].y, fa_mesh_fs_params[31].xyz, fa_mesh_fs_params[30].z);\n}\n\nvoid surface(SurfaceInput i, inout Surface s)\n{\n    s.alpha = texture(mask_mask_smp, i.uv * 2.0).x;\n}\n\nvec4 fa_decal_tile(vec4 rect, vec2 uv, vec2 atlas, vec2 ddx, vec2 ddy)\n{\n    vec2 _1859 = rect.zw - rect.xy;\n    vec2 _1863 = _1859 * atlas;\n    vec2 _1867 = ddx * _1863;\n    vec2 _1871 = ddy * _1863;\n    return textureLod(fa_decal_tex_fa_env_smp, rect.xy + (clamp(uv, vec2(0.0), vec2(1.0)) * _1859), clamp(0.5 * log2(max(max(dot(_1867, _1867), dot(_1871, _1871)), 9.9999999392252902907785028219223e-09)), 0.0, 3.0));\n}\n\nvec3 fa_dc_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_dc_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvoid fa_apply_decals(vec3 world_pos, vec3 geo_normal, inout vec3 albedo, inout vec3 normal)\n{\n    bool _1904 = fa_mesh_fs_params[10].y < 0.5;\n    bool _1911;\n    if (!_1904)\n    {\n        _1911 = fa_mesh_fs_params[10].w < 0.5;\n    }\n    else\n    {\n        _1911 = _1904;\n    }\n    if (_1911)\n    {\n        return;\n    }\n    vec3 _1917 = dFdx(world_pos);\n    vec3 _1920 = dFdy(world_pos);\n    vec3 param = world_pos;\n    vec4 _1924 = fa_cluster_texel(param);\n    int _1928 = int(_1924.w);\n    if (_1928 < 1)\n    {\n        return;\n    }\n    int _1938 = int(fa_mesh_fs_params[10].y + 0.5);\n    int param_1 = _1938;\n    vec4 _1942 = fa_light_texel(param_1);\n    vec2 _1945 = _1942.yz;\n    int _1949 = int(_1942.w);\n    int param_2 = _1938 + 1;\n    vec4 _1954 = fa_light_texel(param_2);\n    float _1955 = _1954.x;\n    int _1961 = int(fa_mesh_fs_params[10].w + 0.5) - 1;\n    int _1965 = int(_1924.z);\n    vec3 _2230;\n    for (int k = 0; k < _1928; k++)\n    {\n        int _1978 = _1965 + k;\n        int param_3 = _1949 + (_1978 >> 2);\n        int _1995 = (_1938 + 2) + (int(fa_light_texel(param_3)[_1978 & 3]) * 7);\n        int param_4 = _1995 + 6;\n        vec4 _2000 = fa_light_texel(param_4);\n        if (((int(_2000.w + 0.5) >> _1961) & 1) == 0)\n        {\n            continue;\n        }\n        int param_5 = _1995;\n        vec4 _2015 = fa_light_texel(param_5);\n        int param_6 = _1995 + 1;\n        vec4 _2020 = fa_light_texel(param_6);\n        int param_7 = _1995 + 2;\n        vec4 _2025 = fa_light_texel(param_7);\n        vec3 _2028 = _2015.xyz;\n        float _2033 = dot(_2028, world_pos) + _2015.w;\n        vec3 _2035 = _2020.xyz;\n        float _2040 = dot(_2035, world_pos) + _2020.w;\n        vec3 _2042 = _2025.xyz;\n        float _2047 = dot(_2042, world_pos) + _2025.w;\n        bool _2052 = abs(_2033) > 0.5;\n        bool _2060;\n        if (!_2052)\n        {\n            _2060 = abs(_2040) > 0.5;\n        }\n        else\n        {\n            _2060 = _2052;\n        }\n        bool _2068;\n        if (!_2060)\n        {\n            _2068 = abs(_2047) > 0.5;\n        }\n        else\n        {\n            _2068 = _2060;\n        }\n        if (_2068)\n        {\n            continue;\n        }\n        float _2083 = clamp(dot(geo_normal, normalize(_2042)) * _2000.z, 0.0, 1.0);\n        if (_2083 <= 0.0)\n        {\n            continue;\n        }\n        float _2103 = (clamp((0.5 - abs(_2047)) * 10.0, 0.0, 1.0) * _2083) * _2000.x;\n        vec2 _2111 = vec2(_2033 + 0.5, 0.5 - _2040);\n        vec2 _2121 = vec2(dot(_2028, _1917), dot(_2035, _1917));\n        vec2 _2131 = vec2(dot(_2028, _1920), dot(_2035, _1920));\n        int param_8 = _1995 + 5;\n        vec4 _2136 = fa_light_texel(param_8);\n        int param_9 = _1995 + 3;\n        vec4 _2141 = fa_light_texel(param_9);\n        int param_10 = _1995 + 4;\n        vec4 _2146 = fa_light_texel(param_10);\n        float tex_a = 1.0;\n        vec3 col = _2136.xyz;\n        bool _2156 = _2141.z > _2141.x;\n        if (_2156)\n        {\n            vec4 param_11 = _2141;\n            vec2 param_12 = _2111;\n            vec2 param_13 = _1945;\n            vec2 param_14 = _2121;\n            vec2 param_15 = _2131;\n            vec4 tx = fa_decal_tile(param_11, param_12, param_13, param_14, param_15);\n            if ((_1955 > 0.5) && (_1955 < 1.5))\n            {\n                vec3 param_16 = tx.xyz;\n                vec3 _2182 = fa_dc_to_linear(param_16);\n                vec4 _9210 = tx;\n                _9210.x = _2182.x;\n                _9210.y = _2182.y;\n                _9210.z = _2182.z;\n                tx = _9210;\n            }\n            col *= tx.xyz;\n            tex_a = tx.w;\n        }\n        albedo = mix(albedo, col, vec3(clamp((_2103 * tex_a) * _2136.w, 0.0, 1.0)));\n        if (_2146.z > _2146.x)\n        {\n            vec4 param_17 = _2146;\n            vec2 param_18 = _2111;\n            vec2 param_19 = _1945;\n            vec2 param_20 = _2121;\n            vec2 param_21 = _2131;\n            vec4 _2226 = fa_decal_tile(param_17, param_18, param_19, param_20, param_21);\n            if (_1955 > 1.5)\n            {\n                vec3 param_22 = _2226.xyz;\n                vec3 _2236 = fa_dc_to_srgb(param_22);\n                _2230 = _2236;\n            }\n            else\n            {\n                _2230 = _2226.xyz;\n            }\n            vec3 _2245 = (_2230 * 2.0) - vec3(1.0);\n            vec2 _2250 = _2245.xy * _2000.y;\n            vec3 _2272 = (normalize(_2028) * _2250.x) + (normalize(_2035) * _2250.y);\n            vec3 _2275 = normalize(normal);\n            normal = normalize(mix(_2275, normalize((_2275 * max(_2245.z, 0.0500000007450580596923828125)) + (_2272 - (_2275 * dot(_2275, _2272)))), vec3(clamp(_2103 * (_2156 ? tex_a : 1.0), 0.0, 1.0))));\n        }\n    }\n}\n\nvoid fa_lod_dither()\n{\n    if (fa_mesh_fs_params[52].w != 0.0)\n    {\n        float _624 = fract(52.98291778564453125 * fract(dot(gl_FragCoord.xy, vec2(0.067110560834407806396484375, 0.005837149918079376220703125))));\n        bool _627;\n        if (fa_mesh_fs_params[52].w > 0.0)\n        {\n            _627 = _624 >= fa_mesh_fs_params[52].w;\n        }\n        else\n        {\n            _627 = _624 < (-fa_mesh_fs_params[52].w);\n        }\n        if (_627)\n        {\n            discard;\n        }\n    }\n}\n\nfloat fa_sheen_albedo(float ndv, float rough)\n{\n    float _4314 = min(sqrt(max(rough - 0.100000001490116119384765625, 0.0) * 1.111111164093017578125) * 6.0, 5.999000072479248046875);\n    float _4322 = min(sqrt(clamp(ndv, 0.0, 1.0)) * 8.0, 7.999000072479248046875);\n    int _4325 = int(_4314);\n    int _4328 = int(_4322);\n    float _4338 = _4322 - float(_4328);\n    int _4393 = (_4325 * 9) + _4328;\n    int _4413 = ((_4325 + 1) * 9) + _4328;\n    return mix(mix(_4389[_4393], _4389[_4393 + 1], _4338), mix(_4389[_4413], _4389[_4413 + 1], _4338), _4314 - float(_4325));\n}\n\nFaLayers fa_layers_setup(SurfaceInput i, Surface s, vec3 n, vec3 v, float metallic, float roughness, inout vec3 f0)\n{\n    bool _9045 = false;\n    float _9046 = 1.0;\n    float _9047 = 1.0;\n    float _9048 = 1.0;\n    float _9049 = 0.0;\n    float _9050 = 0.0;\n    float _9051 = 0.0;\n    float _9052 = 0.0;\n    float _9054 = 1.0;\n    bool _9055 = false;\n    vec3 _9056 = vec3(0.0);\n    float _9057 = 1.0;\n    float _9058 = 1.0;\n    float _9059 = 1.0;\n    float _9060 = 0.0;\n    float _9061 = 0.0;\n    vec3 _9062 = vec3(1.0, 0.0, 0.0);\n    vec3 _9063 = vec3(0.0, 0.0, 1.0);\n    float _9064 = 1.0;\n    float _9065 = 1.0;\n    float _4464 = clamp(s.specular, 0.0, 1.0);\n    float _4468 = clamp(s.ior, 1.0, 3.0);\n    bool _4473 = (_4464 != 1.0) || (_4468 != 1.5);\n    bool _4482;\n    if (!_4473)\n    {\n        _4482 = any(notEqual(s.specular_color, vec3(1.0)));\n    }\n    else\n    {\n        _4482 = _4473;\n    }\n    if (_4482)\n    {\n        float _4490 = (_4468 - 1.0) / (_4468 + 1.0);\n        f0 = mix(min(vec3(_4490 * _4490) * max(s.specular_color, vec3(0.0)), vec3(1.0)) * _4464, s.albedo, vec3(metallic));\n        _9046 = mix(_4464, 1.0, metallic);\n        _9045 = true;\n    }\n    float _4517 = clamp(s.clearcoat, 0.0, 1.0);\n    if (_4517 > 0.0)\n    {\n        float _4525 = clamp(s.clearcoat_roughness, 0.0500000007450580596923828125, 1.0);\n        _9049 = _4517;\n        _9050 = _4525;\n        float _4532 = _4525 * _4525;\n        _9051 = _4532;\n        _9052 = _4532 * _4532;\n        float _4544 = max(dot(i.world_normal, v), 9.9999997473787516355514526367188e-05);\n        _9054 = _4544;\n        _9047 = 1.0 - (_4517 * (0.039999999105930328369140625 + (0.959999978542327880859375 * pow(clamp(1.0 - _4544, 0.0, 1.0), 5.0))));\n        _9045 = true;\n    }\n    vec3 _4563 = max(s.sheen_color, vec3(0.0));\n    float _4572 = max(_4563.x, max(_4563.y, _4563.z));\n    if (_4572 > 0.0)\n    {\n        float _4580 = clamp(s.sheen_roughness, 0.100000001490116119384765625, 1.0);\n        _9055 = true;\n        _9056 = _4563;\n        _9057 = _4580;\n        _9058 = _4580 * _4580;\n        float param = max(dot(n, v), 9.9999997473787516355514526367188e-05);\n        float param_1 = _4580;\n        float _4597 = fa_sheen_albedo(param, param_1);\n        _9060 = _4597;\n        _9059 = 1.0 - min(_4572 * _4597, 1.0);\n        _9045 = true;\n    }\n    _9048 = _9047 * _9059;\n    float _4616 = clamp(s.anisotropy, -1.0, 1.0);\n    if (_4616 != 0.0)\n    {\n        vec3 _4631 = i.world_tangent.xyz - (n * dot(n, i.world_tangent.xyz));\n        vec3 t = _4631;\n        if (dot(_4631, _4631) < 9.9999999392252902907785028219223e-09)\n        {\n            bvec3 _4643 = bvec3(abs(n.y) < 0.9900000095367431640625);\n            t = cross(vec3(_4643.x ? vec3(0.0, 1.0, 0.0).x : vec3(1.0, 0.0, 0.0).x, _4643.y ? vec3(0.0, 1.0, 0.0).y : vec3(1.0, 0.0, 0.0).y, _4643.z ? vec3(0.0, 1.0, 0.0).z : vec3(1.0, 0.0, 0.0).z), n);\n        }\n        vec3 _4647 = t;\n        vec3 _4648 = normalize(_4647);\n        t = _4648;\n        vec3 _4673 = normalize((_4648 * cos(s.anisotropy_rotation)) + ((cross(n, _4648) * ((i.world_tangent.w < 0.0) ? (-1.0) : 1.0)) * sin(s.anisotropy_rotation)));\n        _9062 = _4673;\n        _9063 = cross(n, _4673);\n        float _4683 = roughness * roughness;\n        float _4689 = mix(_4683, 1.0, _4616 * _4616);\n        bool _4691 = _4616 > 0.0;\n        _9064 = _4691 ? _4689 : _4683;\n        _9065 = _4691 ? _4683 : _4689;\n        _9061 = _4616;\n        _9045 = true;\n    }\n    return FaLayers(_9045, _9046, _9047, _9048, _9049, _9050, _9051, _9052, i.world_normal, _9054, _9055, _9056, _9057, _9058, _9059, _9060, _9061, _9062, _9063, _9064, _9065);\n}\n\nvec2 fa_atlas_size()\n{\n    return vec2(textureSize(fa_probe_atlas_fa_env_smp, 0));\n}\n\nvec3 fa_probe_sh_coef(vec2 origin, float res, int k)\n{\n    vec3 v = textureLod(fa_probe_atlas_fa_env_smp, (origin + vec2(float(k) + 0.5, res + 2.5)) / fa_atlas_size(), 0.0).xyz;\n    if (fa_mesh_fs_params[41].y > 0.5)\n    {\n        v = ((v * 255.0) - vec3(128.0)) * 0.03149606287479400634765625;\n    }\n    return v;\n}\n\nvec3 fa_sh_eval(vec3 c[9], vec3 n)\n{\n    vec3 _3482 = max((((c[0] * 0.2820948064327239990234375) + (((c[1] * (0.3257350027561187744140625 * n.y)) + (c[2] * (0.3257350027561187744140625 * n.z))) + (c[3] * (0.3257350027561187744140625 * n.x)))) + (((c[4] * ((0.2731371223926544189453125 * n.x) * n.y)) + (c[5] * ((0.2731371223926544189453125 * n.y) * n.z))) + (c[6] * (0.078847892582416534423828125 * (((3.0 * n.z) * n.z) - 1.0))))) + ((c[7] * ((0.2731371223926544189453125 * n.x) * n.z)) + (c[8] * (0.13656856119632720947265625 * ((n.x * n.x) - (n.y * n.y))))), vec3(0.0));\n    return _3482;\n}\n\nvec3 fa_ambient_light(vec3 n)\n{\n    float _4095 = (1.0 - fa_mesh_fs_params[42].w) - fa_mesh_fs_params[47].w;\n    vec3 amb = vec3(0.0);\n    bool _4100 = fa_mesh_fs_params[11].w > 0.5;\n    vec3 c[9];\n    for (int k = 0; k < 9; k++)\n    {\n        c[k] = vec3(0.0);\n    }\n    if (_4095 > 0.0005000000237487256526947021484375)\n    {\n        if (_4100)\n        {\n            for (int k_1 = 0; k_1 < 9; k_1++)\n            {\n                vec2 param = fa_mesh_fs_params[41].zw;\n                float param_1 = 128.0;\n                int param_2 = k_1;\n                c[k_1] = fa_probe_sh_coef(param, param_1, param_2) * _4095;\n            }\n        }\n        else\n        {\n            amb = fa_mesh_fs_params[1].xyz * _4095;\n        }\n    }\n    bool _4151 = fa_mesh_fs_params[42].w > 0.0;\n    if (_4151)\n    {\n        for (int k_2 = 0; k_2 < 9; k_2++)\n        {\n            vec2 param_3 = fa_mesh_fs_params[42].xy;\n            float param_4 = fa_mesh_fs_params[42].z;\n            int param_5 = k_2;\n            c[k_2] += (fa_probe_sh_coef(param_3, param_4, param_5) * fa_mesh_fs_params[42].w);\n        }\n    }\n    bool _4182 = fa_mesh_fs_params[47].w > 0.0;\n    if (_4182)\n    {\n        for (int k_3 = 0; k_3 < 9; k_3++)\n        {\n            vec2 param_6 = fa_mesh_fs_params[47].xy;\n            float param_7 = fa_mesh_fs_params[47].z;\n            int param_8 = k_3;\n            c[k_3] += (fa_probe_sh_coef(param_6, param_7, param_8) * fa_mesh_fs_params[47].w);\n        }\n    }\n    if ((_4100 || _4151) || _4182)\n    {\n        vec3 param_9[9] = c;\n        vec3 param_10 = n;\n        amb += fa_sh_eval(param_9, param_10);\n    }\n    return amb;\n}\n\nvec4 fa_gi_fetch(vec2 texel)\n{\n    return textureLod(fa_probe_atlas_fa_env_smp, texel / fa_atlas_size(), 0.0);\n}\n\nvec2 fa_oct_encode(vec3 d)\n{\n    vec3 _3502 = d / vec3(max((abs(d.x) + abs(d.y)) + abs(d.z), 9.9999999600419720025001879548654e-13));\n    float _3505 = _3502.x;\n    float _3507 = _3502.z;\n    vec2 e = vec2(_3505, _3507);\n    if (_3502.y < 0.0)\n    {\n        e = vec2((1.0 - abs(_3507)) * ((_3505 < 0.0) ? (-1.0) : 1.0), (1.0 - abs(_3505)) * ((_3507 < 0.0) ? (-1.0) : 1.0));\n    }\n    return e;\n}\n\nvec3 fa_gi_grid(int rec, vec3 n, vec3 v, out float cover)\n{\n    cover = 0.0;\n    int param = rec;\n    vec4 _7334 = fa_light_texel(param);\n    int param_1 = rec + 1;\n    vec4 _7339 = fa_light_texel(param_1);\n    int param_2 = rec + 2;\n    vec4 _7344 = fa_light_texel(param_2);\n    int param_3 = rec + 3;\n    vec4 _7349 = fa_light_texel(param_3);\n    bool _7352 = _7349.z < 0.5;\n    bool _7360;\n    if (!_7352)\n    {\n        _7360 = fa_atlas_size().y < 1155.0;\n    }\n    else\n    {\n        _7360 = _7352;\n    }\n    if (_7360)\n    {\n        return vec3(0.0);\n    }\n    float _7367 = max(_7334.w, 9.9999997473787516355514526367188e-05);\n    vec3 _7370 = _7339.xyz;\n    vec3 _7374 = _7334.xyz;\n    vec3 _7378 = (fa_world_pos - _7374) / vec3(_7367);\n    vec3 _7387 = min(_7378 + vec3(0.5), (_7370 - vec3(0.5)) - _7378);\n    float _7396 = min(_7387.x, min(_7387.y, _7387.z));\n    if (!(_7396 > 0.0))\n    {\n        return vec3(0.0);\n    }\n    vec3 _7411 = _7370 - vec3(1.0);\n    vec3 _7412 = clamp(_7378, vec3(0.0), _7411);\n    vec3 _7420 = min(floor(_7412), max(_7370 - vec3(2.0), vec3(0.0)));\n    vec3 _7424 = _7412 - _7420;\n    vec3 _7435 = fa_world_pos + (((n * 0.800000011920928955078125) + (v * 0.20000000298023223876953125)) * (0.20000000298023223876953125 * _7367));\n    int _7440 = int(_7344.y + 0.5);\n    float _7445 = 0.3257350027561187744140625 * n.y;\n    float _7449 = 0.3257350027561187744140625 * n.z;\n    float _7453 = 0.3257350027561187744140625 * n.x;\n    float _7460 = (0.2731371223926544189453125 * n.x) * n.y;\n    float _7467 = (0.2731371223926544189453125 * n.y) * n.z;\n    float _7476 = 0.078847892582416534423828125 * (((3.0 * n.z) * n.z) - 1.0);\n    float _7483 = (0.2731371223926544189453125 * n.x) * n.z;\n    float _7496 = 0.13656856119632720947265625 * ((n.x * n.x) - (n.y * n.y));\n    vec3 acc = vec3(0.0);\n    float wsum = 0.0;\n    int _7503 = 8 + int(_7349.w);\n    float _7530;\n    float _7543;\n    float _7557;\n    for (int k = 0; k < _7503; k++)\n    {\n        float _7516 = float(k & 1);\n        float _7520 = float((k >> 1) & 1);\n        float _7524 = float((k >> 2) & 1);\n        if (_7516 > 0.5)\n        {\n            _7530 = _7424.x;\n        }\n        else\n        {\n            _7530 = 1.0 - _7424.x;\n        }\n        if (_7520 > 0.5)\n        {\n            _7543 = _7424.y;\n        }\n        else\n        {\n            _7543 = 1.0 - _7424.y;\n        }\n        if (_7524 > 0.5)\n        {\n            _7557 = _7424.z;\n        }\n        else\n        {\n            _7557 = 1.0 - _7424.z;\n        }\n        float _7567 = (_7530 * _7543) * _7557;\n        if (!(_7567 > 0.0))\n        {\n            continue;\n        }\n        vec3 _7580 = min(_7420 + vec3(_7516, _7520, _7524), _7411);\n        int _7600 = int(((_7344.x + _7580.x) + (_7339.x * (_7580.y + (_7339.y * _7580.z)))) + 0.5);\n        vec2 _7615 = vec2(float(_7600 % _7440) * 10.0, 1024.0 + (float(_7600 / _7440) * 11.0));\n        vec2 param_4 = _7615 + vec2(9.5, 10.5);\n        vec4 _7623 = fa_gi_fetch(param_4);\n        bool _7626 = _7623.y < 0.5;\n        bool _7635;\n        if (!_7626)\n        {\n            _7635 = _7623.x > _7349.y;\n        }\n        else\n        {\n            _7635 = _7626;\n        }\n        if (_7635)\n        {\n            continue;\n        }\n        vec3 _7647 = _7435 - (_7374 + (_7580 * _7367));\n        float _7650 = length(_7647);\n        vec3 _7656 = _7647 / vec3(max(_7650, 9.9999997473787516355514526367188e-05));\n        float _7666 = max(9.9999997473787516355514526367188e-05, (dot(-_7656, n) + 1.0) * 0.5);\n        float w = _7567 * (_7666 * _7666);\n        vec3 param_5 = _7656;\n        vec2 param_6 = (_7615 + vec2(1.0)) + (((fa_oct_encode(param_5) * 0.5) + vec2(0.5)) * 8.0);\n        vec4 _7685 = fa_gi_fetch(param_6);\n        float _7692 = _7650 / max(_7344.z, 9.9999997473787516355514526367188e-05);\n        float _7695 = _7685.x;\n        if (_7692 > _7695)\n        {\n            float _7708 = max(_7685.y - (_7695 * _7695), 0.0);\n            float _7713 = _7692 - _7695;\n            float _7722 = _7708 / max(_7708 + (_7713 * _7713), 9.9999999600419720025001879548654e-13);\n            w *= ((_7722 * _7722) * _7722);\n        }\n        if (!(w > 0.0))\n        {\n            continue;\n        }\n        vec2 param_7 = _7615 + vec2(0.5, 10.5);\n        vec2 param_8 = _7615 + vec2(1.5, 10.5);\n        vec2 param_9 = _7615 + vec2(2.5, 10.5);\n        vec2 param_10 = _7615 + vec2(3.5, 10.5);\n        vec2 param_11 = _7615 + vec2(4.5, 10.5);\n        vec2 param_12 = _7615 + vec2(5.5, 10.5);\n        vec2 param_13 = _7615 + vec2(6.5, 10.5);\n        vec2 param_14 = _7615 + vec2(7.5, 10.5);\n        vec2 param_15 = _7615 + vec2(8.5, 10.5);\n        acc += ((((((((((fa_gi_fetch(param_7).xyz * 0.2820948064327239990234375) + (fa_gi_fetch(param_8).xyz * _7445)) + (fa_gi_fetch(param_9).xyz * _7449)) + (fa_gi_fetch(param_10).xyz * _7453)) + (fa_gi_fetch(param_11).xyz * _7460)) + (fa_gi_fetch(param_12).xyz * _7467)) + (fa_gi_fetch(param_13).xyz * _7476)) + (fa_gi_fetch(param_14).xyz * _7483)) + (fa_gi_fetch(param_15).xyz * _7496)) * w);\n        wsum += w;\n    }\n    if (!(wsum > 9.9999997473787516355514526367188e-06))\n    {\n        return vec3(0.0);\n    }\n    cover = smoothstep(0.0, 1.0, clamp(_7396 * 2.0, 0.0, 1.0)) * smoothstep(0.0, 0.0199999995529651641845703125, wsum);\n    float _7846;\n    if (fa_mesh_fs_params[52].z > 0.5)\n    {\n        _7846 = _7349.x;\n    }\n    else\n    {\n        _7846 = 1.0;\n    }\n    return max(acc / vec3(wsum), vec3(0.0)) * (_7344.w * _7846);\n}\n\nvec3 fa_gi_light(vec3 n, inout float left)\n{\n    left = 1.0;\n    vec3 acc = vec3(0.0);\n    vec3 _7870 = normalize(fa_mesh_fs_params[0].xyz - fa_world_pos);\n    int _7875 = int(fa_mesh_fs_params[52].x + 0.5);\n    int _7880 = int(fa_mesh_fs_params[52].y + 0.5);\n    float param_3;\n    for (int k = 0; (k < _7880) && (k < 8); k++)\n    {\n        int param = _7875 + (4 * k);\n        vec3 param_1 = n;\n        vec3 param_2 = _7870;\n        vec3 _7905 = fa_gi_grid(param, param_1, param_2, param_3);\n        float _7910 = param_3 * left;\n        acc += (_7905 * _7910);\n        left -= _7910;\n        if (left < 0.001000000047497451305389404296875)\n        {\n            left = 0.0;\n            break;\n        }\n    }\n    return acc;\n}\n\nvec3 fa_realtime_or_ambient(vec3 n)\n{\n    vec3 gi = vec3(0.0);\n    float left = 1.0;\n    if (fa_mesh_fs_params[52].y > 0.5)\n    {\n        vec3 param = n;\n        float param_1;\n        vec3 _7939 = fa_gi_light(param, param_1);\n        left = param_1;\n        gi = _7939;\n    }\n    if (left <= 0.0)\n    {\n        return gi;\n    }\n    vec3 param_2 = n;\n    return gi + (fa_ambient_light(param_2) * left);\n}\n\nvec3 fa_indirect_diffuse(vec3 n)\n{\n    if (fa_lm.z > 0.5)\n    {\n        return textureLod(fa_lightmap_fa_env_smp, fa_lm.xy, 0.0).xyz;\n    }\n    if (fa_mesh_fs_params[32].w > 0.0)\n    {\n        vec3 c[9];\n        for (int k = 0; k < 9; k++)\n        {\n            c[k] = fa_mesh_fs_params[k * 1 + 32].xyz;\n        }\n        vec3 param = n;\n        vec3 param_1[9] = c;\n        vec3 param_2 = n;\n        return mix(fa_ambient_light(param), fa_sh_eval(param_1, param_2), vec3(clamp(fa_mesh_fs_params[32].w, 0.0, 1.0)));\n    }\n    vec3 param_3 = n;\n    return fa_realtime_or_ambient(param_3);\n}\n\nint fa_cluster_index(int slot, int n)\n{\n    int param = (int(fa_mesh_fs_params[19].x) + int(fa_mesh_fs_params[19].w)) + ((slot + n) >> 2);\n    vec4 t = fa_light_texel(param);\n    return int(t[(slot + n) & 3]);\n}\n\nint fa_cl_light(int n)\n{\n    if (n < fa_cl_ndir)\n    {\n        return n;\n    }\n    int param = fa_cl_slot;\n    int param_1 = n - fa_cl_ndir;\n    return fa_cluster_index(param, param_1);\n}\n\nint fa_light_base(int li)\n{\n    return li * ((fa_mesh_fs_params[1].w > 4.5) ? 8 : 4);\n}\n\nbool fa_light_baked(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 3;\n    return fa_light_texel(param_1).w > 0.5;\n}\n\nfloat fa_baked_keep(int li)\n{\n    float _5834;\n    if (fa_lm.z > 0.5)\n    {\n        _5834 = 0.0;\n    }\n    else\n    {\n        _5834 = 1.0 - clamp(fa_mesh_fs_params[32].w, 0.0, 1.0);\n    }\n    bool _5845 = _5834 < 1.0;\n    bool _5851;\n    if (_5845)\n    {\n        int param = li;\n        _5851 = fa_light_baked(param);\n    }\n    else\n    {\n        _5851 = _5845;\n    }\n    return _5851 ? _5834 : 1.0;\n}\n\nfloat fa_light_type(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 1;\n    return fa_light_texel(param_1).w;\n}\n\nvec4 fa_atlas_fetch(vec2 texel)\n{\n    return textureLod(fa_light_atlas_fa_env_smp, texel / vec2(textureSize(fa_light_atlas_fa_env_smp, 0)), 0.0);\n}\n\nvec3 fa_cookie_sample(vec2 tile_origin, vec2 uv)\n{\n    vec2 param = (tile_origin + vec2(1.0)) + (clamp(uv, vec2(0.0), vec2(1.0)) * 254.0);\n    return fa_atlas_fetch(param).xyz;\n}\n\nvec3 fa_area_point(vec3 c, vec3 axis, vec3 ru, vec3 uu, float hx, float hy, float shape, vec3 p, vec3 r)\n{\n    bool _877 = dot(r, r) > 0.5;\n    if (shape > 1.5)\n    {\n        vec3 _890 = (c - (ru * hx)) - p;\n        vec3 _896 = ru * (2.0 * hx);\n        float _902 = max(dot(_896, _896), 9.9999999392252902907785028219223e-09);\n        float _906 = dot(_890, _896);\n        float t = clamp((-_906) / _902, 0.0, 1.0);\n        if (_877)\n        {\n            float _921 = dot(r, _896);\n            float _927 = _902 - (_921 * _921);\n            if (abs(_927) > (9.9999997473787516355514526367188e-06 * _902))\n            {\n                t = clamp(((dot(r, _890) * _921) - _906) / _927, 0.0, 1.0);\n            }\n        }\n        return (p + _890) + (_896 * t);\n    }\n    vec3 q = p;\n    float _959 = dot(r, axis);\n    bool _967;\n    if (_877)\n    {\n        _967 = abs(_959) > 9.9999997473787516355514526367188e-05;\n    }\n    else\n    {\n        _967 = _877;\n    }\n    if (_967)\n    {\n        float _977 = dot(c - p, axis) / _959;\n        if (_977 > 0.0)\n        {\n            q = p + (r * _977);\n        }\n    }\n    vec3 _990 = q - c;\n    vec2 xy = vec2(dot(_990, ru), dot(_990, uu));\n    if (shape > 0.5)\n    {\n        float _1005 = length(xy);\n        if (_1005 > hx)\n        {\n            xy *= (hx / _1005);\n        }\n    }\n    else\n    {\n        xy = clamp(xy, vec2(-hx, -hy), vec2(hx, hy));\n    }\n    return (c + (ru * xy.x)) + (uu * xy.y);\n}\n\nint fa_cube_face(vec3 d)\n{\n    vec3 _644 = abs(d);\n    float _646 = _644.x;\n    float _648 = _644.y;\n    bool _649 = _646 >= _648;\n    bool _657;\n    if (_649)\n    {\n        _657 = _646 >= _644.z;\n    }\n    else\n    {\n        _657 = _649;\n    }\n    int _658;\n    if (_657)\n    {\n        _658 = (d.x > 0.0) ? 0 : 1;\n    }\n    else\n    {\n        int _672;\n        if (_648 >= _644.z)\n        {\n            _672 = (d.y > 0.0) ? 2 : 3;\n        }\n        else\n        {\n            _672 = (d.z > 0.0) ? 4 : 5;\n        }\n        _658 = _672;\n    }\n    return _658;\n}\n\nvoid fa_cube_face_basis(int f, out vec3 fwd, out vec3 up)\n{\n    if (f == 0)\n    {\n        fwd = vec3(1.0, 0.0, 0.0);\n        up = vec3(0.0, 1.0, 0.0);\n    }\n    else\n    {\n        if (f == 1)\n        {\n            fwd = vec3(-1.0, 0.0, 0.0);\n            up = vec3(0.0, 1.0, 0.0);\n        }\n        else\n        {\n            if (f == 2)\n            {\n                fwd = vec3(0.0, 1.0, 0.0);\n                up = vec3(0.0, 0.0, 1.0);\n            }\n            else\n            {\n                if (f == 3)\n                {\n                    fwd = vec3(0.0, -1.0, 0.0);\n                    up = vec3(0.0, 0.0, -1.0);\n                }\n                else\n                {\n                    if (f == 4)\n                    {\n                        fwd = vec3(0.0, 0.0, 1.0);\n                        up = vec3(0.0, 1.0, 0.0);\n                    }\n                    else\n                    {\n                        fwd = vec3(0.0, 0.0, -1.0);\n                        up = vec3(0.0, 1.0, 0.0);\n                    }\n                }\n            }\n        }\n    }\n}\n\nfloat fa_ies_sample(vec2 tile_origin, vec3 d, vec3 axis, vec3 right, vec3 up)\n{\n    float _797 = dot(d, right);\n    float _801 = dot(d, up);\n    float _812;\n    if (((_797 * _797) + (_801 * _801)) > 1.0000000133514319600180897396058e-10)\n    {\n        _812 = atan(_801, _797) * 0.15915493667125701904296875;\n    }\n    else\n    {\n        _812 = 0.0;\n    }\n    vec2 param = tile_origin + vec2(1.0 + ((_812 - floor(_812)) * 64.0), 1.0 + (acos(clamp(dot(d, axis), -1.0, 1.0)) * 10.18591594696044921875));\n    return fa_atlas_fetch(param).x;\n}\n\nLightSample fa_light_sample_n(int li, vec3 world_pos, vec3 n)\n{\n    int param = li;\n    int _1043 = fa_light_base(param);\n    bool _1047 = fa_mesh_fs_params[1].w > 4.5;\n    int param_1 = _1043;\n    vec4 _1051 = fa_light_texel(param_1);\n    int param_2 = _1043 + 1;\n    vec4 _1056 = fa_light_texel(param_2);\n    float _1059 = _1056.w;\n    float atten = 1.0;\n    float dist = 0.0;\n    fa_light_tint = vec3(1.0);\n    bool _1071 = _1047 && (_1059 > 2.5);\n    fa_light_is_area = _1071;\n    bool _1073 = _1059 < 0.5;\n    vec3 l;\n    if (_1073)\n    {\n        l = normalize(_1051.xyz);\n        if (_1047)\n        {\n            int param_3 = _1043 + 6;\n            vec4 _1087 = fa_light_texel(param_3);\n            if (_1087.z > 0.5)\n            {\n                int param_4 = _1043 + 4;\n                vec4 _1097 = fa_light_texel(param_4);\n                int param_5 = _1043 + 5;\n                vec4 _1102 = fa_light_texel(param_5);\n                vec2 param_6 = _1087.xy;\n                vec2 param_7 = fract(vec2(dot(world_pos, _1097.xyz) * _1097.w, (-dot(world_pos, _1102.xyz)) * _1102.w) + vec2(0.5));\n                fa_light_tint = fa_cookie_sample(param_6, param_7);\n            }\n        }\n    }\n    else\n    {\n        vec3 _1132 = _1051.xyz;\n        vec3 _1134 = _1132 - world_pos;\n        vec3 to_light = _1134;\n        float _1137 = length(_1134);\n        float reach = _1137;\n        bool front = true;\n        if (_1071)\n        {\n            int param_8 = _1043 + 7;\n            reach = max(_1137 - fa_light_texel(param_8).w, 0.0);\n            int param_9 = _1043 + 4;\n            vec4 _1161 = fa_light_texel(param_9);\n            int param_10 = _1043 + 5;\n            vec4 _1166 = fa_light_texel(param_10);\n            int param_11 = _1043 + 6;\n            vec4 _1171 = fa_light_texel(param_11);\n            float _1172 = _1171.w;\n            int param_12 = _1043 + 2;\n            vec3 _1179 = normalize(fa_light_texel(param_12).xyz);\n            bool _1181 = _1172 > 1.5;\n            bool _1189;\n            if (!_1181)\n            {\n                _1189 = dot(_1179, to_light) < 0.0;\n            }\n            else\n            {\n                _1189 = _1181;\n            }\n            front = _1189;\n            vec3 r = vec3(0.0);\n            vec3 _1198 = fa_mesh_fs_params[0].xyz - world_pos;\n            bool _1202 = dot(n, n) > 0.5;\n            bool _1210;\n            if (_1202)\n            {\n                _1210 = dot(_1198, _1198) > 9.9999999600419720025001879548654e-13;\n            }\n            else\n            {\n                _1210 = _1202;\n            }\n            if (_1210)\n            {\n                r = reflect(-normalize(_1198), normalize(n));\n            }\n            vec3 param_13 = _1132;\n            vec3 param_14 = _1179;\n            vec3 param_15 = _1161.xyz;\n            vec3 param_16 = _1166.xyz;\n            float param_17 = _1161.w;\n            float param_18 = _1166.w;\n            float param_19 = _1172;\n            vec3 param_20 = world_pos;\n            vec3 param_21 = r;\n            to_light = fa_area_point(param_13, param_14, param_15, param_16, param_17, param_18, param_19, param_20, param_21) - world_pos;\n        }\n        float _1246 = length(to_light);\n        dist = _1246;\n        l = to_light / vec3(max(_1246, 9.9999997473787516355514526367188e-05));\n        float _1260 = reach / max(_1051.w, 0.001000000047497451305389404296875);\n        float _1266 = clamp(1.0 - (_1260 * _1260), 0.0, 1.0);\n        float _1268;\n        if (front)\n        {\n            _1268 = _1266 * _1266;\n        }\n        else\n        {\n            _1268 = 0.0;\n        }\n        atten = _1268;\n        bool _1279 = _1059 < 2.5;\n        if ((_1059 > 1.5) && _1279)\n        {\n            int param_22 = _1043 + 2;\n            vec4 _1287 = fa_light_texel(param_22);\n            float _1297 = _1287.w;\n            int param_23 = _1043 + 3;\n            vec4 _1302 = fa_light_texel(param_23);\n            float _1303 = _1302.x;\n            float cos_inner = _1303;\n            if (_1303 > 1.5)\n            {\n                cos_inner = mix(_1297, 1.0, 0.25);\n            }\n            atten *= smoothstep(_1297, cos_inner, dot(-l, normalize(_1287.xyz)));\n        }\n        if (_1047 && (_1059 < 1.5))\n        {\n            int param_24 = _1043 + 6;\n            vec4 _1327 = fa_light_texel(param_24);\n            if (_1327.z > 0.5)\n            {\n                vec3 _1335 = -to_light;\n                int param_25 = _1043 + 4;\n                int param_26 = _1043 + 5;\n                vec3 _1349 = fa_light_texel(param_25).xyz;\n                vec3 _1353 = fa_light_texel(param_26).xyz;\n                vec3 _1362 = vec3(dot(_1335, _1349), dot(_1335, _1353), dot(_1335, cross(_1349, _1353)));\n                vec3 param_27 = _1362;\n                int _1366 = fa_cube_face(param_27);\n                int param_28 = _1366;\n                vec3 param_29;\n                vec3 param_30;\n                fa_cube_face_basis(param_28, param_29, param_30);\n                vec2 _1393 = vec2(dot(_1362, cross(param_29, param_30)), dot(_1362, param_30)) / vec2(max(dot(_1362, param_29), 9.9999997473787516355514526367188e-05));\n                int _1397 = _1366 / 3;\n                vec2 param_31 = _1327.xy + (vec2(float(_1366 - (_1397 * 3)), float(_1397)) * 256.0);\n                vec2 param_32 = vec2(0.5 + (0.5 * _1393.x), 0.5 - (0.5 * _1393.y));\n                fa_light_tint = fa_cookie_sample(param_31, param_32);\n            }\n            int param_33 = _1043 + 7;\n            vec4 _1427 = fa_light_texel(param_33);\n            if (_1427.z > 0.5)\n            {\n                int param_34 = _1043 + 2;\n                int param_35 = _1043 + 4;\n                int param_36 = _1043 + 5;\n                vec2 param_37 = _1427.xy;\n                vec3 param_38 = -l;\n                vec3 param_39 = normalize(fa_light_texel(param_34).xyz);\n                vec3 param_40 = fa_light_texel(param_35).xyz;\n                vec3 param_41 = fa_light_texel(param_36).xyz;\n                atten *= fa_ies_sample(param_37, param_38, param_39, param_40, param_41);\n            }\n        }\n        else\n        {\n            if (_1047 && _1279)\n            {\n                int param_42 = _1043 + 6;\n                vec4 _1474 = fa_light_texel(param_42);\n                int param_43 = _1043 + 7;\n                vec4 _1479 = fa_light_texel(param_43);\n                bool _1482 = _1474.z > 0.5;\n                bool _1489;\n                if (!_1482)\n                {\n                    _1489 = _1479.z > 0.5;\n                }\n                else\n                {\n                    _1489 = _1482;\n                }\n                if (_1489)\n                {\n                    int param_44 = _1043 + 2;\n                    vec4 _1496 = fa_light_texel(param_44);\n                    vec3 _1500 = normalize(_1496.xyz);\n                    int param_45 = _1043 + 4;\n                    vec4 _1505 = fa_light_texel(param_45);\n                    int param_46 = _1043 + 5;\n                    vec4 _1510 = fa_light_texel(param_46);\n                    if (_1482)\n                    {\n                        vec3 _1518 = -to_light;\n                        float _1525 = _1496.w;\n                        float _1541 = 0.5 / max(dot(_1518, _1500) * (sqrt(max(1.0 - (_1525 * _1525), 0.0)) / max(_1525, 0.001000000047497451305389404296875)), 9.9999997473787516355514526367188e-05);\n                        vec2 param_47 = _1474.xy;\n                        vec2 param_48 = vec2(0.5 + (dot(_1518, _1505.xyz) * _1541), 0.5 - (dot(_1518, _1510.xyz) * _1541));\n                        fa_light_tint = fa_cookie_sample(param_47, param_48);\n                    }\n                    if (_1479.z > 0.5)\n                    {\n                        vec2 param_49 = _1479.xy;\n                        vec3 param_50 = -l;\n                        vec3 param_51 = _1500;\n                        vec3 param_52 = _1505.xyz;\n                        vec3 param_53 = _1510.xyz;\n                        atten *= fa_ies_sample(param_49, param_50, param_51, param_52, param_53);\n                    }\n                }\n            }\n        }\n    }\n    vec3 _9033 = _1056.xyz * atten;\n    if (_1047)\n    {\n        _9033 *= fa_light_tint;\n    }\n    int _1610;\n    if (_1073)\n    {\n        _1610 = 0;\n    }\n    else\n    {\n        _1610 = ((_1059 > 1.5) && (_1059 < 2.5)) ? 2 : 1;\n    }\n    return LightSample(l, _9033, atten, 1.0, dist, _1610);\n}\n\nfloat fa_shadow_split_at(int i)\n{\n    float _2336;\n    if (i == 0)\n    {\n        _2336 = fa_shadows[24].x;\n    }\n    else\n    {\n        float _2352;\n        if (i == 1)\n        {\n            _2352 = fa_shadows[24].y;\n        }\n        else\n        {\n            float _2360;\n            if (i == 2)\n            {\n                _2360 = fa_shadows[24].z;\n            }\n            else\n            {\n                _2360 = fa_shadows[24].w;\n            }\n            _2352 = _2360;\n        }\n        _2336 = _2352;\n    }\n    return _2336;\n}\n\nfloat fa_shadow_depth(inout vec2 uv, vec4 rect)\n{\n    uv = clamp(uv, rect.xy, rect.zw);\n    return textureLod(fa_shadow_tex_fa_shadow_smp, uv, 0.0).x;\n}\n\nfloat fa_shadow_fetch(vec2 uv, vec4 rect, vec3 conv)\n{\n    vec2 param = uv;\n    vec4 param_1 = rect;\n    float _2393 = fa_shadow_depth(param, param_1);\n    float _2397;\n    if (conv.x < 0.5)\n    {\n        _2397 = _2393;\n    }\n    else\n    {\n        _2397 = (conv.y * conv.z) / (conv.z - (_2393 * (conv.z - conv.y)));\n    }\n    return _2397;\n}\n\nfloat fa_shadow_noise()\n{\n    return fract(52.98291778564453125 * fract(dot(gl_FragCoord.xy, vec2(0.067110560834407806396484375, 0.005837149918079376220703125))));\n}\n\nvec2 fa_shadow_vogel_turn(vec2 d)\n{\n    return vec2((d.x * (-0.737368881702423095703125)) - (d.y * 0.675490319728851318359375), (d.y * (-0.737368881702423095703125)) + (d.x * 0.675490319728851318359375));\n}\n\nfloat fa_shadow_filter(vec2 uv, vec4 rect, float zr, float texel_m, float unit, float reach, float plane, vec3 conv, int mode, float k)\n{\n    if (mode == 1)\n    {\n        vec2 param = uv;\n        vec4 param_1 = rect;\n        vec3 param_2 = conv;\n        return float(zr <= fa_shadow_fetch(param, param_1, param_2));\n    }\n    float _2443 = fa_shadow_noise() * 6.283185482025146484375;\n    vec2 _2449 = vec2(cos(_2443), sin(_2443));\n    vec2 dir = _2449;\n    float radius = 1.5;\n    if (mode == 2)\n    {\n        float _2458;\n        if (k < 0.0)\n        {\n            _2458 = (-k) / max(zr, 0.100000001490116119384765625);\n        }\n        else\n        {\n            _2458 = k;\n        }\n        float _2477 = clamp((_2458 * reach) / texel_m, 3.0, 12.0);\n        float sum = 0.0;\n        float cnt = 0.0;\n        for (int i = 0; i < 16; i++)\n        {\n            float _2496 = sqrt((float(i) + 0.5) * 0.0625) * _2477;\n            vec2 param_3 = uv + (dir * (fa_shadows[26].zw * _2496));\n            vec4 param_4 = rect;\n            vec3 param_5 = conv;\n            float _2510 = fa_shadow_fetch(param_3, param_4, param_5);\n            if (_2510 < (zr - (_2496 * plane)))\n            {\n                sum += _2510;\n                cnt += 1.0;\n            }\n            vec2 param_6 = dir;\n            dir = fa_shadow_vogel_turn(param_6);\n        }\n        if (cnt < 0.5)\n        {\n            return 1.0;\n        }\n        float _2538 = sum / cnt;\n        float _2548;\n        if (k < 0.0)\n        {\n            _2548 = (-k) / max(_2538, 0.0500000007450580596923828125);\n        }\n        else\n        {\n            _2548 = k;\n        }\n        radius = clamp(((max(zr - _2538, 0.0) * unit) * _2548) / texel_m, 1.5, 16.0);\n        dir = _2449;\n    }\n    float lit = 0.0;\n    int _2574 = (mode == 2) ? 24 : 16;\n    for (int i_1 = 0; i_1 < _2574; i_1++)\n    {\n        float _2593 = sqrt((float(i_1) + 0.5) / float(_2574)) * radius;\n        vec2 param_7 = uv + (dir * (fa_shadows[26].zw * _2593));\n        vec4 param_8 = rect;\n        vec3 param_9 = conv;\n        lit += float((zr - (_2593 * plane)) <= fa_shadow_fetch(param_7, param_8, param_9));\n        vec2 param_10 = dir;\n        dir = fa_shadow_vogel_turn(param_10);\n    }\n    return lit / float(_2574);\n}\n\nfloat fa_shadow_cascade(int ci, vec3 world, vec3 n, vec3 l)\n{\n    float _2639 = max(fa_shadows[ci * 1 + 20].y, 0.001000000047497451305389404296875);\n    float _2644 = clamp(dot(n, l), 0.0, 1.0);\n    float _2650 = sqrt(1.0 - (_2644 * _2644));\n    float _2658 = min(_2650 / max(_2644, 0.20000000298023223876953125), 4.0);\n    float _2663;\n    if (fa_shadows[26].y > 0.0)\n    {\n        _2663 = fa_shadows[26].y;\n    }\n    else\n    {\n        _2663 = 1.5 * fa_shadows[ci * 1 + 20].x;\n    }\n    vec4 _2688 = mat4(fa_shadows[ci * 4 + 0], fa_shadows[ci * 4 + 1], fa_shadows[ci * 4 + 2], fa_shadows[ci * 4 + 3]) * vec4(world + (n * (_2663 * _2650)), 1.0);\n    float _2695 = _2688.x;\n    bool _2698 = _2695 < fa_shadows[ci * 1 + 16].x;\n    bool _2707;\n    if (!_2698)\n    {\n        _2707 = _2695 > fa_shadows[ci * 1 + 16].z;\n    }\n    else\n    {\n        _2707 = _2698;\n    }\n    bool _2716;\n    if (!_2707)\n    {\n        _2716 = _2688.y < fa_shadows[ci * 1 + 16].y;\n    }\n    else\n    {\n        _2716 = _2707;\n    }\n    bool _2725;\n    if (!_2716)\n    {\n        _2725 = _2688.y > fa_shadows[ci * 1 + 16].w;\n    }\n    else\n    {\n        _2725 = _2716;\n    }\n    bool _2732;\n    if (!_2725)\n    {\n        _2732 = _2688.z > 1.0;\n    }\n    else\n    {\n        _2732 = _2725;\n    }\n    if (_2732)\n    {\n        return -1.0;\n    }\n    float _2740;\n    if (fa_shadows[26].x > 0.0)\n    {\n        _2740 = fa_shadows[26].x;\n    }\n    else\n    {\n        _2740 = 1.5 * fa_shadows[ci * 1 + 20].x;\n    }\n    vec2 param = _2688.xy;\n    vec4 param_1 = fa_shadows[ci * 1 + 16];\n    float param_2 = _2688.z - ((_2740 * (1.0 + (0.5 * _2658))) / _2639);\n    float param_3 = fa_shadows[ci * 1 + 20].x;\n    float param_4 = _2639;\n    float param_5 = _2639 * 0.25;\n    float param_6 = ((fa_shadows[ci * 1 + 20].x * min(_2658, 3.0)) * 0.5) / _2639;\n    vec3 param_7 = vec3(0.0);\n    int param_8 = int(fa_shadows[25].z + 0.5);\n    float param_9 = fa_shadows[25].w;\n    return fa_shadow_filter(param, param_1, param_2, param_3, param_4, param_5, param_6, param_7, param_8, param_9);\n}\n\nfloat fa_shadow_sun(vec3 world, vec3 n, vec3 l)\n{\n    if (fa_mesh_fs_params[5].z < 0.5)\n    {\n        return 1.0;\n    }\n    int _3118 = int(fa_shadows[25].x + 0.5);\n    if (_3118 < 1)\n    {\n        return 1.0;\n    }\n    float _3133 = dot(world - fa_shadows[27].xyz, fa_shadows[28].xyz);\n    int param = _3118 - 1;\n    if (_3133 > fa_shadow_split_at(param))\n    {\n        return 1.0;\n    }\n    int ci = 0;\n    bool _3145 = _3118 > 1;\n    bool _3152;\n    if (_3145)\n    {\n        _3152 = _3133 > fa_shadows[24].x;\n    }\n    else\n    {\n        _3152 = _3145;\n    }\n    if (_3152)\n    {\n        ci = 1;\n    }\n    bool _3156 = _3118 > 2;\n    bool _3163;\n    if (_3156)\n    {\n        _3163 = _3133 > fa_shadows[24].y;\n    }\n    else\n    {\n        _3163 = _3156;\n    }\n    if (_3163)\n    {\n        ci = 2;\n    }\n    bool _3167 = _3118 > 3;\n    bool _3174;\n    if (_3167)\n    {\n        _3174 = _3133 > fa_shadows[24].z;\n    }\n    else\n    {\n        _3174 = _3167;\n    }\n    if (_3174)\n    {\n        ci = 3;\n    }\n    float s = -1.0;\n    float s2 = -1.0;\n    float t = 0.0;\n    int _3185 = min(_3118, 4);\n    float _3226;\n    for (int c = ci; c < _3185; c++)\n    {\n        int param_1 = c;\n        vec3 param_2 = world;\n        vec3 param_3 = n;\n        vec3 param_4 = l;\n        float _3205 = fa_shadow_cascade(param_1, param_2, param_3, param_4);\n        if (s >= 0.0)\n        {\n            s2 = _3205;\n            break;\n        }\n        if (_3205 < 0.0)\n        {\n            continue;\n        }\n        s = _3205;\n        ci = c;\n        if (fa_shadows[25].y > 0.0)\n        {\n            if (ci > 0)\n            {\n                int param_5 = ci - 1;\n                _3226 = fa_shadow_split_at(param_5);\n            }\n            else\n            {\n                _3226 = fa_shadows[28].w;\n            }\n            int param_6 = ci;\n            float _3245 = fa_shadows[25].y * max(fa_shadow_split_at(param_6) - _3226, 9.9999997473787516355514526367188e-05);\n            int param_7 = ci;\n            t = clamp((_3133 - (fa_shadow_split_at(param_7) - _3245)) / _3245, 0.0, 1.0);\n        }\n        if (t <= 0.0)\n        {\n            break;\n        }\n    }\n    if (s < 0.0)\n    {\n        return 1.0;\n    }\n    if (t > 0.0)\n    {\n        float _3277;\n        if ((ci + 1) < _3118)\n        {\n            _3277 = (s2 < 0.0) ? s : s2;\n        }\n        else\n        {\n            _3277 = 1.0;\n        }\n        s = mix(s, _3277, t);\n    }\n    return s;\n}\n\nfloat fa_shadow_factor(vec3 n, vec3 l)\n{\n    vec3 param = fa_world_pos;\n    vec3 param_1 = n;\n    vec3 param_2 = l;\n    return fa_shadow_sun(param, param_1, param_2);\n}\n\nfloat fa_shadow_local(int li, vec3 lpos, vec3 world, vec3 n, vec3 l)\n{\n    bool _2798 = fa_mesh_fs_params[5].z < 0.5;\n    bool _2805;\n    if (!_2798)\n    {\n        _2805 = fa_shadows[29].x < 0.5;\n    }\n    else\n    {\n        _2805 = _2798;\n    }\n    if (_2805)\n    {\n        return 1.0;\n    }\n    int param = (int(fa_shadows[29].x + 0.5) - 1) + li;\n    vec4 _2818 = fa_light_texel(param);\n    float _2819 = _2818.x;\n    if (_2819 < 0.0)\n    {\n        return 1.0;\n    }\n    int _2828 = int(_2819 + 0.5);\n    int param_1 = _2828;\n    vec4 _2832 = fa_light_texel(param_1);\n    int param_2 = _2828 + 1;\n    vec4 _2837 = fa_light_texel(param_2);\n    float fade = 1.0;\n    float _2840 = _2832.y;\n    if (_2840 > 0.0)\n    {\n        float _2857 = 1.0 - smoothstep(0.75 * _2840, _2840, length(world - fa_shadows[27].xyz));\n        fade = _2857;\n        if (_2857 <= 0.0)\n        {\n            return 1.0;\n        }\n    }\n    int face = 0;\n    if (_2832.x > 1.5)\n    {\n        vec3 param_3 = world - lpos;\n        face = fa_cube_face(param_3);\n    }\n    int _2881 = (_2828 + 2) + (face * 6);\n    int param_4 = _2881;\n    int param_5 = _2881 + 1;\n    int param_6 = _2881 + 3;\n    vec4 _2895 = fa_light_texel(param_6);\n    int param_7 = _2881 + 4;\n    vec4 _2900 = fa_light_texel(param_7);\n    int param_8 = _2881 + 5;\n    vec4 _2905 = fa_light_texel(param_8);\n    float _2917 = _2905.x * max(dot(_2895, vec4(world, 1.0)), 0.001000000047497451305389404296875);\n    float _2922 = clamp(dot(n, l), 0.0, 1.0);\n    float _2945 = clamp(dot(n, _2895.xyz), -1.0, 1.0);\n    float _2964 = min(sqrt(1.0 - (_2945 * _2945)) / max(abs(dot(n, world - lpos)) / max(dot(_2895, vec4(world, 1.0)), 0.001000000047497451305389404296875), 0.20000000298023223876953125), 4.0);\n    float _2967 = _2837.y;\n    float _2969;\n    if (_2967 > 0.0)\n    {\n        _2969 = _2967;\n    }\n    else\n    {\n        _2969 = 1.5 * _2917;\n    }\n    vec4 _2989 = vec4(world + (n * (_2969 * sqrt(1.0 - (_2922 * _2922)))), 1.0);\n    float _2993 = dot(_2895, _2989);\n    float _2996 = _2905.y;\n    if (_2993 < _2996)\n    {\n        return 1.0;\n    }\n    vec2 _3011 = vec2(dot(fa_light_texel(param_4), _2989), dot(fa_light_texel(param_5), _2989)) / vec2(_2993);\n    float _3013 = _3011.x;\n    bool _3016 = _3013 < _2900.x;\n    bool _3025;\n    if (!_3016)\n    {\n        _3025 = _3013 > _2900.z;\n    }\n    else\n    {\n        _3025 = _3016;\n    }\n    bool _3034;\n    if (!_3025)\n    {\n        _3034 = _3011.y < _2900.y;\n    }\n    else\n    {\n        _3034 = _3025;\n    }\n    bool _3043;\n    if (!_3034)\n    {\n        _3043 = _3011.y > _2900.w;\n    }\n    else\n    {\n        _3043 = _3034;\n    }\n    if (_3043)\n    {\n        return 1.0;\n    }\n    float _3049 = _2837.x;\n    float _3051;\n    if (_3049 > 0.0)\n    {\n        _3051 = _3049;\n    }\n    else\n    {\n        _3051 = 1.5 * _2917;\n    }\n    vec2 param_9 = _3011;\n    vec4 param_10 = _2900;\n    float param_11 = _2993 - (_3051 * (1.0 + (0.5 * _2964)));\n    float param_12 = _2917;\n    float param_13 = 1.0;\n    float param_14 = _2905.z * 0.25;\n    float param_15 = (_2917 * min(_2964, 3.0)) * 0.5;\n    vec3 param_16 = vec3(1.0, _2996, _2905.z);\n    int param_17 = int(_2832.z + 0.5);\n    float param_18 = _2832.w;\n    return mix(1.0, fa_shadow_filter(param_9, param_10, param_11, param_12, param_13, param_14, param_15, param_16, param_17, param_18), fade);\n}\n\nfloat fa_contact_shadow(int li, vec3 world, vec3 gn, vec3 l, float dist)\n{\n    bool _5207 = fa_mesh_fs_params[24].x < 0.5;\n    bool _5214;\n    if (!_5207)\n    {\n        _5214 = fa_shadows[29].x < 0.5;\n    }\n    else\n    {\n        _5214 = _5207;\n    }\n    if (_5214)\n    {\n        return 1.0;\n    }\n    int param = (int(fa_shadows[29].x + 0.5) - 1) + li;\n    vec4 _5227 = fa_light_texel(param);\n    float _5228 = _5227.y;\n    float len = _5228;\n    if (_5228 <= 0.0)\n    {\n        return 1.0;\n    }\n    float _5240 = length(world - fa_mesh_fs_params[0].xyz);\n    float _5250 = 1.0 - smoothstep(0.5 * fa_mesh_fs_params[25].x, fa_mesh_fs_params[25].x, _5240);\n    if (_5250 <= 0.0)\n    {\n        return 1.0;\n    }\n    float _5256 = len;\n    float _5259 = min(_5256, 0.89999997615814208984375 * dist);\n    len = _5259;\n    float _5264 = 0.004999999888241291046142578125 + (0.0030000000260770320892333984375 * _5240);\n    float _5269 = _5264 + (0.5 * _5259);\n    vec3 _5275 = world + (gn * _5264);\n    float _5277 = fa_shadow_noise();\n    float occ = 0.0;\n    float _5341;\n    for (int k = 0; k < 12; k++)\n    {\n        float _5292 = (float(k) + _5277) * 0.083333335816860198974609375;\n        vec3 _5300 = _5275 + (l * (_5292 * len));\n        vec4 _5306 = vec4(_5300, 1.0);\n        float _5312 = dot(fa_mesh_fs_params[28], _5306);\n        if (_5312 < 9.9999997473787516355514526367188e-05)\n        {\n            break;\n        }\n        vec2 _5332 = vec2(dot(fa_mesh_fs_params[26], _5306), dot(fa_mesh_fs_params[27], _5306)) / vec2(_5312);\n        float _5336 = _5332.x * 0.5;\n        float _5337 = _5336 + 0.5;\n        if (fa_mesh_fs_params[24].y > 0.5)\n        {\n            _5341 = (_5332.y * 0.5) + 0.5;\n        }\n        else\n        {\n            _5341 = 0.5 - (_5332.y * 0.5);\n        }\n        bool _5357 = _5337 < 0.0;\n        bool _5364;\n        if (!_5357)\n        {\n            _5364 = _5337 >= 1.0;\n        }\n        else\n        {\n            _5364 = _5357;\n        }\n        bool _5371;\n        if (!_5364)\n        {\n            _5371 = _5341 < 0.0;\n        }\n        else\n        {\n            _5371 = _5364;\n        }\n        bool _5378;\n        if (!_5371)\n        {\n            _5378 = _5341 >= 1.0;\n        }\n        else\n        {\n            _5378 = _5371;\n        }\n        if (_5378)\n        {\n            break;\n        }\n        vec4 _5405 = texelFetch(fa_screen_tex_fa_shadow_smp, clamp(ivec2(vec2(_5337, _5341) * fa_mesh_fs_params[24].zw), ivec2(0), ivec2(fa_mesh_fs_params[24].zw) - ivec2(1)), 0);\n        if (_5405.w < 0.5)\n        {\n            continue;\n        }\n        float _5424 = (dot(fa_mesh_fs_params[29].xyz, _5300) + fa_mesh_fs_params[29].w) - _5405.x;\n        if ((_5424 > _5264) && (_5424 < _5269))\n        {\n            occ = max(occ, (1.0 - (_5292 * _5292)) * smoothstep(0.0, 0.0500000007450580596923828125, min(min(_5337, 0.5 - _5336), min(_5341, 1.0 - _5341))));\n        }\n    }\n    return 1.0 - (occ * _5250);\n}\n\nLightSample fa_light_shadowed(int li, vec3 world_pos, vec3 gn)\n{\n    int param = li;\n    float _5890 = fa_baked_keep(param);\n    if (_5890 <= 0.0)\n    {\n        int param_1 = li;\n        return LightSample(vec3(0.0, 1.0, 0.0), vec3(0.0), 0.0, 1.0, 0.0, int(fa_light_type(param_1) + 0.5));\n    }\n    int param_2 = li;\n    vec3 param_3 = world_pos;\n    vec3 param_4 = gn;\n    LightSample _5916 = fa_light_sample_n(param_2, param_3, param_4);\n    vec3 _9102 = _5916.color;\n    float _9103 = _5916.attenuation;\n    float _9104 = _5916.shadow;\n    bool _5919 = _5916.type == 0;\n    if (_5919 && (li == 0))\n    {\n        vec3 param_5 = gn;\n        vec3 param_6 = _5916.direction;\n        float _5930 = fa_shadow_factor(param_5, param_6);\n        _9104 = _5930;\n        _9102 *= _5930;\n    }\n    else\n    {\n        bool _5941 = _5916.type != 0;\n        bool _5947;\n        if (_5941)\n        {\n            _5947 = _9103 > 0.0;\n        }\n        else\n        {\n            _5947 = _5941;\n        }\n        if (_5947)\n        {\n            int param_7 = li;\n            int param_8 = fa_light_base(param_7);\n            int param_9 = li;\n            vec3 param_10 = fa_light_texel(param_8).xyz;\n            vec3 param_11 = world_pos;\n            vec3 param_12 = gn;\n            vec3 param_13 = _5916.direction;\n            float _5966 = fa_shadow_local(param_9, param_10, param_11, param_12, param_13);\n            _9104 = _5966;\n            _9102 *= _5966;\n        }\n    }\n    bool _5976 = fa_mesh_fs_params[24].x > 0.5;\n    bool _5982;\n    if (_5976)\n    {\n        _5982 = _9103 > 0.0;\n    }\n    else\n    {\n        _5982 = _5976;\n    }\n    if (_5982)\n    {\n        float _5989;\n        if (_5919)\n        {\n            _5989 = 1000000000.0;\n        }\n        else\n        {\n            _5989 = _5916._distance;\n        }\n        int param_14 = li;\n        vec3 param_15 = world_pos;\n        vec3 param_16 = gn;\n        vec3 param_17 = _5916.direction;\n        float param_18 = _5989;\n        float _6007 = fa_contact_shadow(param_14, param_15, param_16, param_17, param_18);\n        _9104 *= _6007;\n        _9102 *= _6007;\n    }\n    float _6020 = _9103;\n    float _6021 = _6020 * _5890;\n    _9103 = _6021;\n    vec3 _6025 = _9102;\n    vec3 _6026 = _6025 * _5890;\n    _9102 = _6026;\n    return LightSample(_5916.direction, _6026, _6021, _9104, _5916._distance, _5916.type);\n}\n\nvec3 fa_ltc_tangent(vec3 n, vec3 v)\n{\n    vec3 _6060 = v - (n * dot(v, n));\n    vec3 t = _6060;\n    float _6064 = dot(_6060, _6060);\n    float l2 = _6064;\n    if (_6064 < 1.0000000133514319600180897396058e-10)\n    {\n        vec3 _6074;\n        if (abs(n.z) < 0.999000012874603271484375)\n        {\n            _6074 = cross(n, vec3(0.0, 0.0, 1.0));\n        }\n        else\n        {\n            _6074 = cross(n, vec3(1.0, 0.0, 0.0));\n        }\n        t = _6074;\n        l2 = dot(_6074, _6074);\n    }\n    return t * inversesqrt(l2);\n}\n\nvec3 fa_ltc_local(vec3 t1, vec3 n, vec3 p)\n{\n    return vec3(dot(t1, p), dot(cross(n, t1), p), dot(n, p));\n}\n\nvec2 fa_ltc_uv(float roughness, float ndv)\n{\n    return ((vec2(clamp((roughness - 0.0500000007450580596923828125) * 1.0526316165924072265625, 0.0, 1.0), sqrt(clamp(1.0 - ndv, 0.0, 1.0))) * 63.0) + vec2(0.5)) * vec2(0.015625);\n}\n\nvec3 fa_oct_vertex(int j, vec3 pc, vec3 ex, vec3 ey)\n{\n    float _6461;\n    if ((j == 0) || (j == 7))\n    {\n        _6461 = 0.92387950420379638671875;\n    }\n    else\n    {\n        float _6471;\n        if ((j == 3) || (j == 4))\n        {\n            _6471 = -0.92387950420379638671875;\n        }\n        else\n        {\n            _6471 = ((j == 1) || (j == 6)) ? 0.3826834261417388916015625 : (-0.3826834261417388916015625);\n        }\n        _6461 = _6471;\n    }\n    float _6492;\n    if ((j == 1) || (j == 2))\n    {\n        _6492 = 0.92387950420379638671875;\n    }\n    else\n    {\n        float _6501;\n        if ((j == 5) || (j == 6))\n        {\n            _6501 = -0.92387950420379638671875;\n        }\n        else\n        {\n            _6501 = ((j == 0) || (j == 3)) ? 0.3826834261417388916015625 : (-0.3826834261417388916015625);\n        }\n        _6492 = _6501;\n    }\n    return (pc + (ex * _6461)) + (ey * _6492);\n}\n\nvec3 fa_ltc_edge_vector(vec3 a, vec3 b)\n{\n    float _6109 = dot(a, a);\n    float _6113 = dot(b, b);\n    if ((_6109 < 1.0000000195414813782625560981111e-24) || (_6113 < 1.0000000195414813782625560981111e-24))\n    {\n        return vec3(0.0);\n    }\n    vec3 _6127 = a * inversesqrt(_6109);\n    vec3 _6132 = b * inversesqrt(_6113);\n    float _6136 = dot(_6127, _6132);\n    float _6139 = abs(_6136);\n    float g = (((((((((((0.0416471660137176513671875 * _6139) - 0.1924748718738555908203125) * _6139) + 0.4179156124591827392578125) * _6139) - 0.616057217121124267578125) * _6139) + 0.777722418308258056640625) * _6139) - 0.999542415142059326171875) * _6139) + 1.570791721343994140625;\n    if (_6136 < 0.0)\n    {\n        g = (3.1415927410125732421875 * inversesqrt(max(1.0 - (_6136 * _6136), 1.0000000116860974230803549289703e-07))) - g;\n    }\n    return cross(_6127, _6132) * g;\n}\n\nvoid fa_ltc_clip_edge(vec3 a, vec3 b, inout vec3 sum, inout vec3 leave, inout vec3 enter, inout vec2 seen)\n{\n    bool _6196 = a.z > 0.0;\n    bool _6200 = b.z > 0.0;\n    if (_6196 && _6200)\n    {\n        vec3 param = a;\n        vec3 param_1 = b;\n        sum += fa_ltc_edge_vector(param, param_1);\n    }\n    else\n    {\n        if (_6196 != _6200)\n        {\n            vec3 _6235 = a + ((b - a) * (a.z / (a.z - b.z)));\n            _6235.z = 0.0;\n            if (_6196)\n            {\n                vec3 param_2 = a;\n                vec3 param_3 = _6235;\n                sum += fa_ltc_edge_vector(param_2, param_3);\n                leave = _6235;\n                seen.x = 1.0;\n            }\n            else\n            {\n                vec3 param_4 = _6235;\n                vec3 param_5 = b;\n                sum += fa_ltc_edge_vector(param_4, param_5);\n                enter = _6235;\n                seen.y = 1.0;\n            }\n        }\n    }\n}\n\nfloat fa_ltc_quad(vec4 abcd, vec3 p0, vec3 p1, vec3 p2, vec3 p3)\n{\n    vec3 _6284 = vec3((abcd.x * p0.x) + (abcd.y * p0.z), p0.y, (abcd.z * p0.x) + (abcd.w * p0.z));\n    vec3 _6310 = vec3((abcd.x * p1.x) + (abcd.y * p1.z), p1.y, (abcd.z * p1.x) + (abcd.w * p1.z));\n    vec3 _6336 = vec3((abcd.x * p2.x) + (abcd.y * p2.z), p2.y, (abcd.z * p2.x) + (abcd.w * p2.z));\n    vec3 _6362 = vec3((abcd.x * p3.x) + (abcd.y * p3.z), p3.y, (abcd.z * p3.x) + (abcd.w * p3.z));\n    vec3 sum = vec3(0.0);\n    vec3 leave = vec3(0.0);\n    vec3 enter = vec3(0.0);\n    vec3 param = _6284;\n    vec3 param_1 = _6310;\n    vec3 param_2 = vec3(0.0);\n    vec3 param_3 = vec3(0.0);\n    vec3 param_4 = vec3(0.0);\n    vec2 param_5 = vec2(0.0);\n    fa_ltc_clip_edge(param, param_1, param_2, param_3, param_4, param_5);\n    sum = param_2;\n    leave = param_3;\n    enter = param_4;\n    vec3 param_6 = _6310;\n    vec3 param_7 = _6336;\n    vec3 param_8 = param_2;\n    vec3 param_9 = param_3;\n    vec3 param_10 = param_4;\n    vec2 param_11 = param_5;\n    fa_ltc_clip_edge(param_6, param_7, param_8, param_9, param_10, param_11);\n    sum = param_8;\n    leave = param_9;\n    enter = param_10;\n    vec3 param_12 = _6336;\n    vec3 param_13 = _6362;\n    vec3 param_14 = param_8;\n    vec3 param_15 = param_9;\n    vec3 param_16 = param_10;\n    vec2 param_17 = param_11;\n    fa_ltc_clip_edge(param_12, param_13, param_14, param_15, param_16, param_17);\n    sum = param_14;\n    leave = param_15;\n    enter = param_16;\n    vec3 param_18 = _6362;\n    vec3 param_19 = _6284;\n    vec3 param_20 = param_14;\n    vec3 param_21 = param_15;\n    vec3 param_22 = param_16;\n    vec2 param_23 = param_17;\n    fa_ltc_clip_edge(param_18, param_19, param_20, param_21, param_22, param_23);\n    sum = param_20;\n    leave = param_21;\n    enter = param_22;\n    if ((param_23.x * param_23.y) > 0.5)\n    {\n        vec3 param_24 = leave;\n        vec3 param_25 = enter;\n        sum += fa_ltc_edge_vector(param_24, param_25);\n    }\n    return sum.z * 0.15915493667125701904296875;\n}\n\nvec2 fa_area_forms(vec4 m, float shape, vec3 pc, vec3 ex, vec3 ey)\n{\n    int _6530 = ((shape < 0.5) || (shape > 1.5)) ? 1 : 3;\n    vec2 sum = vec2(0.0);\n    int _6548;\n    for (int k = 0; k < (2 * _6530); k++)\n    {\n        bool _6545 = k >= _6530;\n        if (_6545)\n        {\n            _6548 = k - _6530;\n        }\n        else\n        {\n            _6548 = k;\n        }\n        vec3 p0 = (pc - ex) - ey;\n        vec3 p1 = (pc + ex) - ey;\n        vec3 p2 = (pc + ex) + ey;\n        vec3 p3 = (pc - ex) + ey;\n        if (_6530 == 3)\n        {\n            int param = 0;\n            vec3 param_1 = pc;\n            vec3 param_2 = ex;\n            vec3 param_3 = ey;\n            p0 = fa_oct_vertex(param, param_1, param_2, param_3);\n            int _6594 = 2 * _6548;\n            int param_4 = _6594 + 1;\n            vec3 param_5 = pc;\n            vec3 param_6 = ex;\n            vec3 param_7 = ey;\n            p1 = fa_oct_vertex(param_4, param_5, param_6, param_7);\n            int param_8 = _6594 + 2;\n            vec3 param_9 = pc;\n            vec3 param_10 = ex;\n            vec3 param_11 = ey;\n            p2 = fa_oct_vertex(param_8, param_9, param_10, param_11);\n            int param_12 = _6594 + 3;\n            vec3 param_13 = pc;\n            vec3 param_14 = ex;\n            vec3 param_15 = ey;\n            p3 = fa_oct_vertex(param_12, param_13, param_14, param_15);\n        }\n        bvec4 _6631 = bvec4(_6545);\n        vec4 param_16 = vec4(_6631.x ? m.x : vec4(1.0, 0.0, 0.0, 1.0).x, _6631.y ? m.y : vec4(1.0, 0.0, 0.0, 1.0).y, _6631.z ? m.z : vec4(1.0, 0.0, 0.0, 1.0).z, _6631.w ? m.w : vec4(1.0, 0.0, 0.0, 1.0).w);\n        vec3 param_17 = p0;\n        vec3 param_18 = p1;\n        vec3 param_19 = p2;\n        vec3 param_20 = p3;\n        float _6642 = fa_ltc_quad(param_16, param_17, param_18, param_19, param_20);\n        if (_6545)\n        {\n            vec2 _9329 = sum;\n            _9329.y = _9329.y + _6642;\n            sum = _9329;\n        }\n        else\n        {\n            vec2 _9332 = sum;\n            _9332.x = _9332.x + _6642;\n            sum = _9332;\n        }\n    }\n    return abs(sum);\n}\n\nvec3 fa_area_shade(int li, vec3 world_pos, vec3 n, vec3 v, vec3 diffuse_color, vec3 f0, float f90, float roughness, float ndv, float window)\n{\n    int param = li;\n    int _6666 = fa_light_base(param);\n    int param_1 = _6666;\n    int param_2 = _6666 + 1;\n    int param_3 = _6666 + 2;\n    int param_4 = _6666 + 4;\n    vec4 _6688 = fa_light_texel(param_4);\n    int param_5 = _6666 + 5;\n    vec4 _6693 = fa_light_texel(param_5);\n    int param_6 = _6666 + 6;\n    vec4 _6698 = fa_light_texel(param_6);\n    float _6699 = _6698.w;\n    vec3 _6704 = fa_light_texel(param_1).xyz - world_pos;\n    bool _6706 = _6699 < 1.5;\n    bool _6713;\n    if (_6706)\n    {\n        _6713 = dot(normalize(fa_light_texel(param_3).xyz), _6704) >= 0.0;\n    }\n    else\n    {\n        _6713 = _6706;\n    }\n    if (_6713)\n    {\n        return vec3(0.0);\n    }\n    bool _6722 = (_6699 > 0.5) && _6706;\n    float _6726 = _6722 ? 1.0539000034332275390625 : 1.0;\n    vec3 _6729 = _6688.xyz;\n    float _6731 = _6688.w;\n    vec3 _6737 = _6693.xyz;\n    float _6739 = _6693.w;\n    vec3 up = _6737 * (_6739 * _6726);\n    float _6745;\n    if (_6722)\n    {\n        _6745 = (3.1415927410125732421875 * _6731) * _6731;\n    }\n    else\n    {\n        _6745 = (4.0 * _6731) * _6739;\n    }\n    if (_6699 > 1.5)\n    {\n        vec3 _6771 = cross(_6729, -_6704);\n        vec3 perp = _6771;\n        float _6775 = dot(_6771, _6771);\n        vec3 _6778;\n        if (_6775 > 1.0000000133514319600180897396058e-10)\n        {\n            _6778 = perp * inversesqrt(_6775);\n        }\n        else\n        {\n            _6778 = _6737;\n        }\n        perp = _6778;\n        up = _6778 * _6739;\n    }\n    float _6799 = max(_6745, 9.9999999747524270787835121154785e-07);\n    vec3 param_7 = n;\n    vec3 param_8 = v;\n    vec3 _6809 = fa_ltc_tangent(param_7, param_8);\n    vec3 param_9 = _6809;\n    vec3 param_10 = n;\n    vec3 param_11 = _6704;\n    vec3 param_12 = _6809;\n    vec3 param_13 = n;\n    vec3 param_14 = _6729 * (_6731 * _6726);\n    vec3 param_15 = _6809;\n    vec3 param_16 = n;\n    vec3 param_17 = up;\n    float param_18 = roughness;\n    float param_19 = ndv;\n    vec2 _6840 = fa_ltc_uv(param_18, param_19) * 64.0;\n    vec2 param_20 = _6840;\n    vec2 param_21 = _6840 + vec2(64.0, 0.0);\n    vec4 _6850 = fa_atlas_fetch(param_21);\n    vec4 param_22 = fa_atlas_fetch(param_20);\n    float param_23 = _6699;\n    vec3 param_24 = fa_ltc_local(param_9, param_10, param_11);\n    vec3 param_25 = fa_ltc_local(param_12, param_13, param_14);\n    vec3 param_26 = fa_ltc_local(param_15, param_16, param_17);\n    vec2 _6862 = fa_area_forms(param_22, param_23, param_24, param_25, param_26);\n    return (((diffuse_color * _6862.x) + (((f0 * _6850.x) + ((vec3(f90) - f0) * _6850.y)) * _6862.y)) * fa_light_texel(param_2).xyz) * ((((3.1415927410125732421875 * dot(_6704, _6704)) + _6799) / _6799) * window);\n}\n\nvec3 fa_light_rgb(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 1;\n    return fa_light_texel(param_1).xyz;\n}\n\nfloat fa_d_charlie(float alpha, float ndh)\n{\n    float _4944 = 1.0 / alpha;\n    return ((2.0 + _4944) * pow(sqrt(max(1.0 - (ndh * ndh), 9.9999997473787516355514526367188e-05)), _4944)) * 0.15915493667125701904296875;\n}\n\nfloat fa_v_ashikhmin(float ndl, float ndv)\n{\n    return clamp(0.25 / max((ndl + ndv) - (ndl * ndv), 9.9999997473787516355514526367188e-05), 0.0, 1.0);\n}\n\nfloat fa_layers_coat(FaLayers L, vec3 l, vec3 h, float vdh)\n{\n    float _4979 = max(dot(L.nc, l), 0.0);\n    float _4985 = max(dot(L.nc, h), 0.0);\n    float _4994 = ((_4985 * _4985) * (L.coat_a2 - 1.0)) + 1.0;\n    return (((L.coat * (0.039999999105930328369140625 + (0.959999978542327880859375 * pow(clamp(1.0 - vdh, 0.0, 1.0), 5.0)))) * (((L.coat_a2 / ((3.1415927410125732421875 * _4994) * _4994)) * (0.5 / max(mix((2.0 * _4979) * L.coat_ndv, _4979 + L.coat_ndv, L.coat_alpha), 9.9999997473787516355514526367188e-05))) * 3.1415927410125732421875)) * step(9.9999997473787516355514526367188e-05, _4979)) * _4979;\n}\n\nvec3 fa_area_layers(FaLayers L, vec3 base, int li, vec3 n, vec3 v, vec3 l, float ndv, float window)\n{\n    float _6899;\n    if (L.sheen_on)\n    {\n        _6899 = L.sheen_scale;\n    }\n    else\n    {\n        _6899 = 1.0;\n    }\n    vec3 result = base * (L.keep * _6899);\n    vec3 _6912 = normalize(l + v);\n    int param = li;\n    vec3 _6923 = fa_light_rgb(param) * window;\n    if (L.sheen_on)\n    {\n        float _6932 = max(dot(n, l), 0.0);\n        float param_1 = L.sheen_alpha;\n        float param_2 = max(dot(n, _6912), 0.0);\n        float param_3 = _6932;\n        float param_4 = ndv;\n        result += ((L.sheen * _6923) * (((((fa_d_charlie(param_1, param_2) * fa_v_ashikhmin(param_3, param_4)) * 3.1415927410125732421875) * step(9.9999997473787516355514526367188e-05, _6932)) * _6932) * L.keep));\n    }\n    if (L.coat > 0.0)\n    {\n        FaLayers param_5 = L;\n        vec3 param_6 = l;\n        vec3 param_7 = _6912;\n        float param_8 = max(dot(v, _6912), 0.0);\n        result += (_6923 * fa_layers_coat(param_5, param_6, param_7, param_8));\n    }\n    return result;\n}\n\nfloat fa_d_ggx_aniso(float ndh, float tdh, float bdh, float at, float ab)\n{\n    float _4847 = tdh / at;\n    float _4851 = bdh / ab;\n    float _4863 = ((_4847 * _4847) + (_4851 * _4851)) + (ndh * ndh);\n    return 1.0 / ((((3.1415927410125732421875 * at) * ab) * _4863) * _4863);\n}\n\nfloat fa_lambda_ggx_aniso(float n, float t, float b, float at, float ab)\n{\n    return 0.5 * (sqrt(1.0 + (((((at * at) * t) * t) + (((ab * ab) * b) * b)) / max(n * n, 9.9999999392252902907785028219223e-09))) - 1.0);\n}\n\nfloat fa_v_ggx_aniso(float ndl, float ndv, float tdv, float bdv, float tdl, float bdl, float at, float ab)\n{\n    float param = ndv;\n    float param_1 = tdv;\n    float param_2 = bdv;\n    float param_3 = at;\n    float param_4 = ab;\n    float param_5 = ndl;\n    float param_6 = tdl;\n    float param_7 = bdl;\n    float param_8 = at;\n    float param_9 = ab;\n    return clamp(1.0 / ((4.0 * max(ndl * ndv, 9.9999997473787516355514526367188e-05)) * ((1.0 + fa_lambda_ggx_aniso(param, param_1, param_2, param_3, param_4)) + fa_lambda_ggx_aniso(param_5, param_6, param_7, param_8, param_9))), 0.0, 1.0);\n}\n\nvec3 fa_layers_light(FaLayers L, vec3 diffuse_color, vec3 f0, vec3 n, vec3 v, vec3 l, vec3 h, float ndl, float ndv, float ndh, float vdh, float alpha, float a2)\n{\n    float _5043 = step(9.9999997473787516355514526367188e-05, ndl);\n    float d_ggx;\n    float vis;\n    if (L.aniso != 0.0)\n    {\n        float param = ndh;\n        float param_1 = dot(L.t, h);\n        float param_2 = dot(L.b, h);\n        float param_3 = L.at;\n        float param_4 = L.ab;\n        d_ggx = fa_d_ggx_aniso(param, param_1, param_2, param_3, param_4);\n        float param_5 = ndl;\n        float param_6 = ndv;\n        float param_7 = dot(L.t, v);\n        float param_8 = dot(L.b, v);\n        float param_9 = dot(L.t, l);\n        float param_10 = dot(L.b, l);\n        float param_11 = L.at;\n        float param_12 = L.ab;\n        vis = fa_v_ggx_aniso(param_5, param_6, param_7, param_8, param_9, param_10, param_11, param_12);\n    }\n    else\n    {\n        float _5122 = ((ndh * ndh) * (a2 - 1.0)) + 1.0;\n        d_ggx = a2 / ((3.1415927410125732421875 * _5122) * _5122);\n        vis = 0.5 / max(mix((2.0 * ndl) * ndv, ndl + ndv, alpha), 9.9999997473787516355514526367188e-05);\n    }\n    vec3 base = diffuse_color + (((f0 + ((vec3(L.f90) - f0) * pow(clamp(1.0 - vdh, 0.0, 1.0), 5.0))) * ((d_ggx * vis) * 3.1415927410125732421875)) * _5043);\n    if (L.sheen_on)\n    {\n        float param_13 = L.sheen_alpha;\n        float param_14 = ndh;\n        float param_15 = ndl;\n        float param_16 = ndv;\n        base = (base * L.sheen_scale) + (L.sheen * (((fa_d_charlie(param_13, param_14) * fa_v_ashikhmin(param_15, param_16)) * 3.1415927410125732421875) * _5043));\n    }\n    vec3 result = base * (L.keep * ndl);\n    if (L.coat > 0.0)\n    {\n        FaLayers param_17 = L;\n        vec3 param_18 = l;\n        vec3 param_19 = h;\n        float param_20 = vdh;\n        result += vec3(fa_layers_coat(param_17, param_18, param_19, param_20));\n    }\n    return result;\n}\n\nvec2 fa_env_brdf(float rough, float ndv)\n{\n    vec4 _4246 = (vec4(-1.0, -0.0274999998509883880615234375, -0.572000026702880859375, 0.02199999988079071044921875) * rough) + vec4(1.0, 0.0425000004470348358154296875, 1.03999996185302734375, -0.039999999105930328369140625);\n    float _4249 = _4246.x;\n    return (vec2(-1.03999996185302734375, 1.03999996185302734375) * ((min(_4249 * _4249, exp2((-9.27999973297119140625) * ndv)) * _4249) + _4246.y)) + _4246.zw;\n}\n\nvec3 fa_probe_level(vec2 origin, float res, int lv, vec2 e)\n{\n    float _3554;\n    if (lv == 0)\n    {\n        _3554 = 0.0;\n    }\n    else\n    {\n        _3554 = res + 2.0;\n    }\n    float _3564;\n    if (lv == 0)\n    {\n        _3564 = 0.0;\n    }\n    else\n    {\n        _3564 = (res - (res / float(1 << max((lv - 1), 0)))) + (2.0 * float(lv - 1));\n    }\n    return textureLod(fa_probe_atlas_fa_env_smp, (((origin + vec2(_3554, _3564)) + vec2(1.0)) + (((e * 0.5) + vec2(0.5)) * (res / float(1 << lv)))) / fa_atlas_size(), 0.0).xyz;\n}\n\nvec3 fa_probe_radiance(vec2 origin, float res, vec3 d, float rough)\n{\n    float _3610;\n    if (res > 64.5)\n    {\n        _3610 = 5.0;\n    }\n    else\n    {\n        _3610 = (res > 32.5) ? 4.0 : 3.0;\n    }\n    float _3625 = clamp(rough, 0.0, 1.0) * (_3610 - 1.0);\n    int _3632 = int(min(floor(_3625), _3610 - 2.0));\n    float _3637 = _3625 - float(_3632);\n    vec3 param = d;\n    vec2 _3641 = fa_oct_encode(param);\n    vec2 param_1 = origin;\n    float param_2 = res;\n    int param_3 = _3632;\n    vec2 param_4 = _3641;\n    vec3 _3651 = fa_probe_level(param_1, param_2, param_3, param_4);\n    if (_3637 < 0.00200000009499490261077880859375)\n    {\n        return _3651;\n    }\n    vec2 param_5 = origin;\n    float param_6 = res;\n    int param_7 = _3632 + 1;\n    vec2 param_8 = _3641;\n    return mix(_3651, fa_probe_level(param_5, param_6, param_7, param_8), vec3(_3637));\n}\n\nvec3 fa_probe_box_dir(vec3 d, vec4 posw, vec4 bx, vec4 by, vec4 bz)\n{\n    if (posw.w < 0.5)\n    {\n        return d;\n    }\n    float _3724 = dot(bx.xyz, fa_world_pos) + bx.w;\n    float _3731 = dot(by.xyz, fa_world_pos) + by.w;\n    float _3738 = dot(bz.xyz, fa_world_pos) + bz.w;\n    float _3744 = dot(bx.xyz, d);\n    float _3748 = dot(by.xyz, d);\n    float _3752 = dot(bz.xyz, d);\n    float _3758;\n    if (_3744 > 9.9999999747524270787835121154785e-07)\n    {\n        _3758 = (1.0 - _3724) / _3744;\n    }\n    else\n    {\n        float _3772;\n        if (_3744 < (-9.9999999747524270787835121154785e-07))\n        {\n            _3772 = ((-1.0) - _3724) / _3744;\n        }\n        else\n        {\n            _3772 = 1000000015047466219876688855040.0;\n        }\n        _3758 = _3772;\n    }\n    float tx = _3758;\n    float _3789;\n    if (_3748 > 9.9999999747524270787835121154785e-07)\n    {\n        _3789 = (1.0 - _3731) / _3748;\n    }\n    else\n    {\n        float _3802;\n        if (_3748 < (-9.9999999747524270787835121154785e-07))\n        {\n            _3802 = ((-1.0) - _3731) / _3748;\n        }\n        else\n        {\n            _3802 = 1000000015047466219876688855040.0;\n        }\n        _3789 = _3802;\n    }\n    float ty = _3789;\n    float _3818;\n    if (_3752 > 9.9999999747524270787835121154785e-07)\n    {\n        _3818 = (1.0 - _3738) / _3752;\n    }\n    else\n    {\n        float _3831;\n        if (_3752 < (-9.9999999747524270787835121154785e-07))\n        {\n            _3831 = ((-1.0) - _3738) / _3752;\n        }\n        else\n        {\n            _3831 = 1000000015047466219876688855040.0;\n        }\n        _3818 = _3831;\n    }\n    float _3843 = tx;\n    float _3846 = (_3843 > 0.0) ? _3843 : 1000000015047466219876688855040.0;\n    tx = _3846;\n    float _3847 = ty;\n    float _3850 = (_3847 > 0.0) ? _3847 : 1000000015047466219876688855040.0;\n    ty = _3850;\n    float _3860 = min(_3846, min(_3850, (_3818 > 0.0) ? _3818 : 1000000015047466219876688855040.0));\n    if (_3860 > 100000001504746621987668885504.0)\n    {\n        return d;\n    }\n    vec3 _3876 = (fa_world_pos + (d * _3860)) - posw.xyz;\n    vec3 _3881;\n    if (dot(_3876, _3876) > 1.0000000133514319600180897396058e-10)\n    {\n        _3881 = normalize(_3876);\n    }\n    else\n    {\n        _3881 = d;\n    }\n    return _3881;\n}\n\nvec3 fa_probe_environment(vec4 tile, vec4 posw, vec4 bx, vec4 by, vec4 bz, inout vec3 d, float rough)\n{\n    vec3 param = d;\n    vec4 param_1 = posw;\n    vec4 param_2 = bx;\n    vec4 param_3 = by;\n    vec4 param_4 = bz;\n    d = fa_probe_box_dir(param, param_1, param_2, param_3, param_4);\n    vec2 param_5 = tile.xy;\n    float param_6 = tile.z;\n    vec3 param_7 = d;\n    float param_8 = rough;\n    return fa_probe_radiance(param_5, param_6, param_7, param_8);\n}\n\nvec3 fa_environment(vec3 d, float rough)\n{\n    float _3927 = (1.0 - fa_mesh_fs_params[42].w) - fa_mesh_fs_params[47].w;\n    vec3 outc = vec3(0.0);\n    if (_3927 > 0.0005000000237487256526947021484375)\n    {\n        vec3 base;\n        if (fa_mesh_fs_params[11].w > 0.5)\n        {\n            vec2 param = fa_mesh_fs_params[41].zw;\n            float param_1 = 128.0;\n            vec3 param_2 = d;\n            float param_3 = rough;\n            base = fa_probe_radiance(param, param_1, param_2, param_3);\n        }\n        else\n        {\n            float _3955 = rough * rough;\n            float _3986 = 0.60000002384185791015625 * _3955;\n            base = mix(mix(fa_mesh_fs_params[12].xyz * 0.550000011920928955078125, mix(fa_mesh_fs_params[12].xyz, fa_mesh_fs_params[11].xyz, vec3(pow(clamp(d.y * (1.0 - (0.699999988079071044921875 * _3955)), 0.0, 1.0), 0.550000011920928955078125))), vec3(smoothstep((-0.0500000007450580596923828125) - _3986, 0.0500000007450580596923828125 + _3986, d.y))), ((fa_mesh_fs_params[11].xyz + fa_mesh_fs_params[12].xyz) * 0.5) * 0.800000011920928955078125, vec3(_3955 * 0.60000002384185791015625));\n        }\n        outc = base * _3927;\n    }\n    if (fa_mesh_fs_params[42].w > 0.0)\n    {\n        vec4 param_4 = fa_mesh_fs_params[42];\n        vec4 param_5 = fa_mesh_fs_params[43];\n        vec4 param_6 = fa_mesh_fs_params[44];\n        vec4 param_7 = fa_mesh_fs_params[45];\n        vec4 param_8 = fa_mesh_fs_params[46];\n        vec3 param_9 = d;\n        float param_10 = rough;\n        vec3 _4045 = fa_probe_environment(param_4, param_5, param_6, param_7, param_8, param_9, param_10);\n        outc += (_4045 * fa_mesh_fs_params[42].w);\n    }\n    if (fa_mesh_fs_params[47].w > 0.0)\n    {\n        vec4 param_11 = fa_mesh_fs_params[47];\n        vec4 param_12 = fa_mesh_fs_params[48];\n        vec4 param_13 = fa_mesh_fs_params[49];\n        vec4 param_14 = fa_mesh_fs_params[50];\n        vec4 param_15 = fa_mesh_fs_params[51];\n        vec3 param_16 = d;\n        float param_17 = rough;\n        vec3 _4077 = fa_probe_environment(param_11, param_12, param_13, param_14, param_15, param_16, param_17);\n        outc += (_4077 * fa_mesh_fs_params[47].w);\n    }\n    return outc;\n}\n\nvec3 fa_layers_ibl(FaLayers L, vec3 n, vec3 v, vec3 f0, float roughness, float occlusion)\n{\n    vec3 rn = n;\n    if (L.aniso != 0.0)\n    {\n        vec3 _4724;\n        if (L.aniso >= 0.0)\n        {\n            _4724 = L.b;\n        }\n        else\n        {\n            _4724 = L.t;\n        }\n        rn = normalize(mix(n, cross(cross(_4724, v), _4724), vec3(abs(L.aniso) * smoothstep(0.0, 0.25, roughness))));\n    }\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05);\n    vec2 _4760 = fa_env_brdf(param, param_1);\n    vec3 param_2 = reflect(-v, rn);\n    float param_3 = roughness;\n    vec3 result = (fa_environment(param_2, param_3) * ((f0 * _4760.x) + (vec3(L.f90) * _4760.y))) * L.base_scale;\n    if (L.sheen_on)\n    {\n        vec3 param_4 = n;\n        float param_5 = L.sheen_rough;\n        result += ((L.sheen * (L.sheen_e * L.keep)) * fa_environment(param_4, param_5));\n    }\n    result *= occlusion;\n    if (L.coat > 0.0)\n    {\n        float param_6 = L.coat_rough;\n        float param_7 = L.coat_ndv;\n        vec2 _4818 = fa_env_brdf(param_6, param_7);\n        vec3 param_8 = reflect(-v, L.nc);\n        float param_9 = L.coat_rough;\n        result += (fa_environment(param_8, param_9) * (L.coat * ((0.039999999105930328369140625 * _4818.x) + _4818.y)));\n    }\n    return result;\n}\n\nvec3 fa_sky_reflection(vec3 n, vec3 v, vec3 f0, float roughness)\n{\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05);\n    vec2 _4288 = fa_env_brdf(param, param_1);\n    vec3 param_2 = reflect(-v, n);\n    float param_3 = roughness;\n    return fa_environment(param_2, param_3) * ((f0 * _4288.x) + vec3(_4288.y));\n}\n\nvec2 fa_xm_size(int k)\n{\n    return max(floor(fa_mesh_fs_params[24].zw / vec2(float(1 << k))), vec2(1.0));\n}\n\nvec2 fa_xm_origin(int k)\n{\n    if (k == 0)\n    {\n        return vec2(0.0);\n    }\n    float y = 0.0;\n    for (int j = 1; j < k; j++)\n    {\n        int param = j;\n        y += fa_xm_size(param).y;\n    }\n    return vec2(fa_mesh_fs_params[24].z, y);\n}\n\nvec3 fa_xm_texel(vec2 size, vec2 origin, vec2 p)\n{\n    return texelFetch(fa_screen_tex_fa_shadow_smp, ivec2(origin + clamp(p, vec2(0.0), size - vec2(1.0))), 0).xyz;\n}\n\nvec3 fa_xm_level(int k, vec2 uv)\n{\n    int param = k;\n    vec2 _5528 = fa_xm_size(param);\n    int param_1 = k;\n    vec2 _5532 = fa_xm_origin(param_1);\n    vec2 _5538 = (uv * _5528) - vec2(0.5);\n    vec2 _5541 = fract(_5538);\n    vec2 _5544 = floor(_5538);\n    vec2 param_2 = _5528;\n    vec2 param_3 = _5532;\n    vec2 param_4 = _5544;\n    vec2 param_5 = _5528;\n    vec2 param_6 = _5532;\n    vec2 param_7 = _5544 + vec2(1.0, 0.0);\n    vec2 param_8 = _5528;\n    vec2 param_9 = _5532;\n    vec2 param_10 = _5544 + vec2(0.0, 1.0);\n    vec2 param_11 = _5528;\n    vec2 param_12 = _5532;\n    vec2 param_13 = _5544 + vec2(1.0);\n    vec3 _5586 = vec3(_5541.x);\n    return mix(mix(fa_xm_texel(param_2, param_3, param_4), fa_xm_texel(param_5, param_6, param_7), _5586), mix(fa_xm_texel(param_8, param_9, param_10), fa_xm_texel(param_11, param_12, param_13), _5586), vec3(_5541.y));\n}\n\nvec3 fa_xm_sample(vec2 uv, float lod)\n{\n    float _5605 = max(fa_mesh_fs_params[31].w - 1.0, 0.0);\n    float _5609 = clamp(lod, 0.0, _5605);\n    int _5613 = int(floor(_5609));\n    int param = _5613;\n    vec2 param_1 = uv;\n    vec3 c = fa_xm_level(param, param_1);\n    float _5623 = float(_5613);\n    float _5624 = _5609 - _5623;\n    bool _5626 = _5624 > 0.001000000047497451305389404296875;\n    bool _5633;\n    if (_5626)\n    {\n        _5633 = _5623 < _5605;\n    }\n    else\n    {\n        _5633 = _5626;\n    }\n    if (_5633)\n    {\n        int param_2 = _5613 + 1;\n        vec2 param_3 = uv;\n        c = mix(c, fa_xm_level(param_2, param_3), vec3(_5624));\n    }\n    return c;\n}\n\nvec3 fa_transmitted(Surface s, vec3 n, vec3 v, float roughness, vec3 f0, float f90, float keep, float tr, inout float blend)\n{\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05);\n    vec2 _5659 = fa_env_brdf(param, param_1);\n    vec3 through = ((vec3(1.0) - clamp((f0 * _5659.x) + (vec3(f90) * _5659.y), vec3(0.0), vec3(1.0))) * s.albedo) * (tr * keep);\n    float _5687 = max(s.thickness, 0.0);\n    bool _5692 = _5687 > 0.0;\n    if ((s.attenuation_distance > 0.0) && _5692)\n    {\n        through *= exp((-((-log(clamp(s.attenuation_color, vec3(9.9999997473787516355514526367188e-05), vec3(1.0)))) / vec3(s.attenuation_distance))) * _5687);\n    }\n    bool _5717 = fa_mesh_fs_params[30].w > 1.5;\n    bool _5724;\n    if (!_5717)\n    {\n        _5724 = fa_mesh_fs_params[30].w < 0.5;\n    }\n    else\n    {\n        _5724 = _5717;\n    }\n    if (_5724)\n    {\n        blend = clamp(dot(through, vec3(0.3333333432674407958984375)), 0.0, 0.980000019073486328125);\n        return vec3(0.0);\n    }\n    vec3 world = fa_world_pos;\n    if (_5692)\n    {\n        world += (refract(-v, n, 1.0 / max(s.ior, 1.0)) * _5687);\n    }\n    vec4 _5759 = vec4(world, 1.0);\n    float _5764 = dot(fa_mesh_fs_params[28], _5759);\n    vec2 uv = vec2(0.5);\n    if (_5764 > 9.9999997473787516355514526367188e-05)\n    {\n        vec2 _5782 = vec2(dot(fa_mesh_fs_params[26], _5759), dot(fa_mesh_fs_params[27], _5759)) / vec2(_5764);\n        float _5790;\n        if (fa_mesh_fs_params[24].y > 0.5)\n        {\n            _5790 = (_5782.y * 0.5) + 0.5;\n        }\n        else\n        {\n            _5790 = 0.5 - (_5782.y * 0.5);\n        }\n        uv = vec2((_5782.x * 0.5) + 0.5, _5790);\n    }\n    vec2 param_2 = clamp(uv, vec2(0.0), vec2(1.0));\n    float param_3 = (clamp(roughness, 0.0, 1.0) * clamp((2.0 * s.ior) - 2.0, 0.0, 1.0)) * max(fa_mesh_fs_params[31].w - 1.0, 0.0);\n    return through * fa_xm_sample(param_2, param_3);\n}\n\nvec3 fa_shadow_debug(vec3 color, vec3 world)\n{\n    if (fa_shadows[27].w < 0.5)\n    {\n        return color;\n    }\n    int _3305 = int(fa_shadows[25].x + 0.5);\n    float _3315 = dot(world - fa_shadows[27].xyz, fa_shadows[28].xyz);\n    vec3 tint = vec3(0.3499999940395355224609375);\n    bool _3320 = _3305 > 0;\n    bool _3329;\n    if (_3320)\n    {\n        int param = _3305 - 1;\n        _3329 = _3315 <= fa_shadow_split_at(param);\n    }\n    else\n    {\n        _3329 = _3320;\n    }\n    if (_3329)\n    {\n        tint = vec3(1.0, 0.1500000059604644775390625, 0.100000001490116119384765625);\n        bool _3335 = _3305 > 1;\n        bool _3342;\n        if (_3335)\n        {\n            _3342 = _3315 > fa_shadows[24].x;\n        }\n        else\n        {\n            _3342 = _3335;\n        }\n        if (_3342)\n        {\n            tint = vec3(0.100000001490116119384765625, 0.89999997615814208984375, 0.20000000298023223876953125);\n        }\n        bool _3348 = _3305 > 2;\n        bool _3355;\n        if (_3348)\n        {\n            _3355 = _3315 > fa_shadows[24].y;\n        }\n        else\n        {\n            _3355 = _3348;\n        }\n        if (_3355)\n        {\n            tint = vec3(0.1500000059604644775390625, 0.300000011920928955078125, 1.0);\n        }\n        bool _3361 = _3305 > 3;\n        bool _3368;\n        if (_3361)\n        {\n            _3368 = _3315 > fa_shadows[24].z;\n        }\n        else\n        {\n            _3368 = _3361;\n        }\n        if (_3368)\n        {\n            tint = vec3(1.0, 0.89999997615814208984375, 0.100000001490116119384765625);\n        }\n    }\n    return mix(color, tint, vec3(0.550000011920928955078125));\n}\n\nvoid main()\n{\n    fa_inst_load();\n    vec3 _8761 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _8761 = -_8761;\n    }\n    vec3 _8047 = normalize(fa_mesh_fs_params[0].xyz - fa_world_pos);\n    vec3 param = fa_world_pos;\n    fa_cluster_begin(param);\n    SurfaceInput param_1 = SurfaceInput(fa_world_pos, _8761, fa_world_tangent, fa_uv, fa_vertex_color, _8047, gl_FrontFacing);\n    Surface _8055 = fa_standard_surface(param_1);\n    vec3 _8792 = _8055.albedo;\n    float _8793 = _8055.alpha;\n    vec3 _8794 = _8055.normal;\n    float _8795 = _8055.metallic;\n    float _8796 = _8055.roughness;\n    float _8797 = _8055.occlusion;\n    vec3 _8798 = _8055.emission;\n    float _8799 = _8055.clearcoat;\n    float _8800 = _8055.clearcoat_roughness;\n    vec3 _8801 = _8055.sheen_color;\n    float _8802 = _8055.sheen_roughness;\n    float _8803 = _8055.anisotropy;\n    float _8804 = _8055.anisotropy_rotation;\n    float _8805 = _8055.specular;\n    float _8806 = _8055.ior;\n    vec3 _8807 = _8055.specular_color;\n    float _8808 = _8055.transmission;\n    float _8809 = _8055.thickness;\n    vec3 _8810 = _8055.attenuation_color;\n    float _8811 = _8055.attenuation_distance;\n    SurfaceInput param_2 = SurfaceInput(fa_world_pos, _8761, fa_world_tangent, fa_uv, fa_vertex_color, _8047, gl_FrontFacing);\n    Surface param_3 = _8055;\n    surface(param_2, param_3);\n    _8792 = param_3.albedo;\n    _8793 = param_3.alpha;\n    _8794 = param_3.normal;\n    _8795 = param_3.metallic;\n    _8796 = param_3.roughness;\n    _8797 = param_3.occlusion;\n    _8798 = param_3.emission;\n    _8799 = param_3.clearcoat;\n    _8800 = param_3.clearcoat_roughness;\n    _8801 = param_3.sheen_color;\n    _8802 = param_3.sheen_roughness;\n    _8803 = param_3.anisotropy;\n    _8804 = param_3.anisotropy_rotation;\n    _8805 = param_3.specular;\n    _8806 = param_3.ior;\n    _8807 = param_3.specular_color;\n    _8808 = param_3.transmission;\n    _8809 = param_3.thickness;\n    _8810 = param_3.attenuation_color;\n    _8811 = param_3.attenuation_distance;\n    vec3 param_4 = fa_world_pos;\n    vec3 param_5 = _8761;\n    vec3 param_6 = param_3.albedo;\n    vec3 param_7 = param_3.normal;\n    fa_apply_decals(param_4, param_5, param_6, param_7);\n    _8792 = param_6;\n    _8794 = param_7;\n    if (_8793 < fa_material[0].x)\n    {\n        discard;\n    }\n    fa_lod_dither();\n    float fa_tr_blend = 0.0;\n    vec3 result;\n    if (fa_mesh_fs_params[3].w > 0.5)\n    {\n        result = _8792;\n    }\n    else\n    {\n        vec3 _8107 = normalize(_8794);\n        float _8114 = clamp(_8795, 0.0, 1.0);\n        float _8118 = clamp(_8796, 0.0500000007450580596923828125, 1.0);\n        float _8122 = _8118 * _8118;\n        float _8126 = _8122 * _8122;\n        float _8131 = max(dot(_8107, _8047), 9.9999997473787516355514526367188e-05);\n        float _8137 = 1.0 - _8114;\n        float _8138 = clamp(_8808, 0.0, 1.0) * _8137;\n        vec3 _8147 = (_8792 * _8137) * (1.0 - _8138);\n        vec3 _8154 = mix(vec3(0.039999999105930328369140625), _8792, vec3(_8114));\n        vec3 f0 = _8154;\n        SurfaceInput param_8 = SurfaceInput(fa_world_pos, _8761, fa_world_tangent, fa_uv, fa_vertex_color, _8047, gl_FrontFacing);\n        Surface param_9 = Surface(_8792, _8793, _8794, _8795, _8796, _8797, _8798, _8799, _8800, _8801, _8802, _8803, _8804, _8805, _8806, _8807, _8808, _8809, _8810, _8811);\n        vec3 param_10 = _8107;\n        vec3 param_11 = _8047;\n        float param_12 = _8114;\n        float param_13 = _8118;\n        vec3 param_14 = _8154;\n        FaLayers _8170 = fa_layers_setup(param_8, param_9, param_10, param_11, param_12, param_13, param_14);\n        f0 = param_14;\n        vec3 param_15 = _8107;\n        vec3 lit = (fa_indirect_diffuse(param_15) * _8147) * _8797;\n        if (_8170.on)\n        {\n            lit *= _8170.base_scale;\n        }\n        int _8192 = fa_cl_ndir + fa_cl_local;\n        float _8257;\n        for (int ln = 0; ln < _8192; ln++)\n        {\n            int param_16 = ln;\n            int _8205 = fa_cl_light(param_16);\n            int param_17 = _8205;\n            if (fa_baked_keep(param_17) <= 0.0)\n            {\n                continue;\n            }\n            int param_18 = _8205;\n            vec3 param_19 = fa_world_pos;\n            vec3 param_20 = _8761;\n            LightSample _8221 = fa_light_shadowed(param_18, param_19, param_20);\n            float _8229 = max(dot(_8107, _8221.direction), 0.0);\n            float _8235 = _8221.attenuation * _8221.shadow;\n            vec3 _8240 = normalize(_8221.direction + _8047);\n            float _8245 = max(dot(_8107, _8240), 0.0);\n            float _8250 = max(dot(_8047, _8240), 0.0);\n            if (fa_light_is_area)\n            {\n                if (_8170.on)\n                {\n                    _8257 = _8170.f90;\n                }\n                else\n                {\n                    _8257 = 1.0;\n                }\n                int param_21 = _8205;\n                vec3 param_22 = fa_world_pos;\n                vec3 param_23 = _8107;\n                vec3 param_24 = _8047;\n                vec3 param_25 = _8147;\n                vec3 param_26 = f0;\n                float param_27 = _8257;\n                float param_28 = _8118;\n                float param_29 = _8131;\n                float param_30 = _8235;\n                vec3 area = fa_area_shade(param_21, param_22, param_23, param_24, param_25, param_26, param_27, param_28, param_29, param_30);\n                if (_8170.on)\n                {\n                    FaLayers param_31 = _8170;\n                    vec3 param_32 = area;\n                    int param_33 = _8205;\n                    vec3 param_34 = _8107;\n                    vec3 param_35 = _8047;\n                    vec3 param_36 = _8221.direction;\n                    float param_37 = _8131;\n                    float param_38 = _8235;\n                    area = fa_area_layers(param_31, param_32, param_33, param_34, param_35, param_36, param_37, param_38);\n                }\n                lit += area;\n            }\n            else\n            {\n                if (_8170.on)\n                {\n                    FaLayers param_39 = _8170;\n                    vec3 param_40 = _8147;\n                    vec3 param_41 = f0;\n                    vec3 param_42 = _8107;\n                    vec3 param_43 = _8047;\n                    vec3 param_44 = _8221.direction;\n                    vec3 param_45 = _8240;\n                    float param_46 = _8229;\n                    float param_47 = _8131;\n                    float param_48 = _8245;\n                    float param_49 = _8250;\n                    float param_50 = _8122;\n                    float param_51 = _8126;\n                    int param_52 = _8205;\n                    lit += (fa_layers_light(param_39, param_40, param_41, param_42, param_43, param_44, param_45, param_46, param_47, param_48, param_49, param_50, param_51) * ((fa_light_rgb(param_52) * fa_light_tint) * _8235));\n                }\n                else\n                {\n                    float _8359 = ((_8245 * _8245) * (_8126 - 1.0)) + 1.0;\n                    int param_53 = _8205;\n                    lit += (((_8147 + (((f0 + ((vec3(1.0) - f0) * pow(1.0 - _8250, 5.0))) * (((_8126 / ((3.1415927410125732421875 * _8359) * _8359)) * (0.5 / max(mix((2.0 * _8229) * _8131, _8229 + _8131, _8122), 9.9999997473787516355514526367188e-05))) * 3.1415927410125732421875)) * step(9.9999997473787516355514526367188e-05, _8229))) * (fa_light_rgb(param_53) * fa_light_tint)) * (_8229 * _8235));\n                }\n            }\n        }\n        if (_8170.on)\n        {\n            FaLayers param_54 = _8170;\n            vec3 param_55 = _8107;\n            vec3 param_56 = _8047;\n            vec3 param_57 = f0;\n            float param_58 = _8118;\n            float param_59 = _8797;\n            lit += fa_layers_ibl(param_54, param_55, param_56, param_57, param_58, param_59);\n        }\n        else\n        {\n            vec3 param_60 = _8107;\n            vec3 param_61 = _8047;\n            vec3 param_62 = f0;\n            float param_63 = _8118;\n            lit += (fa_sky_reflection(param_60, param_61, param_62, param_63) * _8797);\n        }\n        if (_8138 > 0.0)\n        {\n            float _8457;\n            if (_8170.on)\n            {\n                _8457 = _8170.f90;\n            }\n            else\n            {\n                _8457 = 1.0;\n            }\n            float _8465;\n            if (_8170.on)\n            {\n                _8465 = _8170.base_scale;\n            }\n            else\n            {\n                _8465 = 1.0;\n            }\n            Surface param_64 = Surface(_8792, _8793, _8794, _8795, _8796, _8797, _8798, _8799, _8800, _8801, _8802, _8803, _8804, _8805, _8806, _8807, _8808, _8809, _8810, _8811);\n            vec3 param_65 = _8107;\n            vec3 param_66 = _8047;\n            float param_67 = _8118;\n            vec3 param_68 = f0;\n            float param_69 = _8457;\n            float param_70 = _8465;\n            float param_71 = _8138;\n            float param_72 = fa_tr_blend;\n            vec3 _8489 = fa_transmitted(param_64, param_65, param_66, param_67, param_68, param_69, param_70, param_71, param_72);\n            fa_tr_blend = param_72;\n            lit += _8489;\n        }\n        result = lit;\n    }\n    vec3 _8496 = result;\n    vec3 _8497 = _8496 + _8798;\n    result = _8497;\n    vec3 param_73 = _8497;\n    vec3 param_74 = fa_world_pos;\n    result = fa_shadow_debug(param_73, param_74);\n    bool _8506 = fa_mesh_fs_params[7].w > 0.0;\n    bool _8513;\n    if (!_8506)\n    {\n        _8513 = fa_mesh_fs_params[8].y > 0.0;\n    }\n    else\n    {\n        _8513 = _8506;\n    }\n    if (_8513)\n    {\n        vec3 _8522 = fa_world_pos - fa_mesh_fs_params[0].xyz;\n        float _8528 = dot(_8522, fa_mesh_fs_params[9].xyz);\n        bool _8532 = fa_mesh_fs_params[9].w > 0.5;\n        float _8533;\n        if (_8532)\n        {\n            _8533 = _8528;\n        }\n        else\n        {\n            _8533 = length(_8522);\n        }\n        float _8545 = _8533 - fa_mesh_fs_params[8].x;\n        if (_8545 > 0.0)\n        {\n            float _8554 = fa_mesh_fs_params[7].w * _8545;\n            float tau = _8554 * _8554;\n            if (fa_mesh_fs_params[8].y > 0.0)\n            {\n                float _8570;\n                if (_8532)\n                {\n                    _8570 = fa_world_pos.y - (fa_mesh_fs_params[9].y * _8528);\n                }\n                else\n                {\n                    _8570 = fa_mesh_fs_params[0].y;\n                }\n                float _8591 = mix(_8570, fa_world_pos.y, clamp(fa_mesh_fs_params[8].x / _8533, 0.0, 1.0));\n                float _8595 = fa_world_pos.y - _8591;\n                float _8600 = _8591 - fa_mesh_fs_params[8].z;\n                float _8605 = fa_world_pos.y - fa_mesh_fs_params[8].z;\n                bool _8608 = _8600 <= 0.0;\n                bool _8609 = !_8608;\n                bool _8615;\n                if (_8609)\n                {\n                    _8615 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _8615 = _8608;\n                }\n                float _8616;\n                if (_8615)\n                {\n                    _8616 = fa_mesh_fs_params[8].y;\n                }\n                else\n                {\n                    _8616 = fa_mesh_fs_params[8].y * exp(-min(fa_mesh_fs_params[8].w * _8600, 80.0));\n                }\n                bool _8643;\n                if (_8609)\n                {\n                    _8643 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _8643 = _8608;\n                }\n                float _8644;\n                if (_8643)\n                {\n                    _8644 = fa_mesh_fs_params[8].y * _8600;\n                }\n                else\n                {\n                    _8644 = (fa_mesh_fs_params[8].y * (1.0 - exp(-min(fa_mesh_fs_params[8].w * _8600, 80.0)))) / fa_mesh_fs_params[8].w;\n                }\n                bool _8669 = _8605 <= 0.0;\n                bool _8676;\n                if (!_8669)\n                {\n                    _8676 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _8676 = _8669;\n                }\n                float _8677;\n                if (_8676)\n                {\n                    _8677 = fa_mesh_fs_params[8].y * _8605;\n                }\n                else\n                {\n                    _8677 = (fa_mesh_fs_params[8].y * (1.0 - exp(-min(fa_mesh_fs_params[8].w * _8605, 80.0)))) / fa_mesh_fs_params[8].w;\n                }\n                float _8704;\n                if (abs(_8595) < 0.001000000047497451305389404296875)\n                {\n                    _8704 = _8616;\n                }\n                else\n                {\n                    _8704 = (_8677 - _8644) / _8595;\n                }\n                tau += (_8545 * max(_8704, 0.0));\n            }\n            result = mix(result, fa_mesh_fs_params[7].xyz, vec3(clamp(1.0 - exp(-clamp(tau, 0.0, 80.0)), 0.0, 1.0)));\n        }\n    }\n    if (fa_tr_blend > 0.0)\n    {\n        float _8740 = 1.0 - fa_tr_blend;\n        result /= vec3(_8740);\n        _8793 *= _8740;\n    }\n    fa_frag_color = vec4(result, _8793);\n}\n\n",
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
            "inst_name": "_602",
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
            "inst_name": "_2346",
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
            "inst_name": "_8083",
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
            "name": "fa_shadow_tex_fa_shadow_smp",
            "view_name": "fa_shadow_tex",
            "sampler_name": "fa_shadow_smp",
            "view_slot": 1,
            "sampler_slot": 1,
            "glsl_name": "fa_shadow_tex_fa_shadow_smp"
          },
          {
            "slot": 12,
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
      "vs": "#version 430\n\nstruct VertexData\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 color;\n    vec3 object_pos;\n};\n\nuniform vec4 fa_mesh_vs_params[11];\nuniform vec4 fa_skin[192];\nlayout(location = 0) out vec3 fa_world_pos;\nlayout(location = 1) out vec3 fa_world_normal;\nlayout(location = 2) out vec4 fa_world_tangent;\nlayout(location = 3) out vec2 fa_uv;\nlayout(location = 4) out vec4 fa_vertex_color;\nlayout(location = 5) in vec4 fa_inst_m0;\nlayout(location = 6) in vec4 fa_inst_m1;\nlayout(location = 7) in vec4 fa_inst_m2;\nlayout(location = 8) in vec4 fa_inst_m3;\nlayout(location = 9) in vec4 fa_joints;\nlayout(location = 10) in vec4 fa_weights;\nlayout(location = 0) in vec3 fa_position;\nlayout(location = 1) in vec3 fa_normal;\nlayout(location = 3) in vec4 fa_tangent;\nlayout(location = 2) in vec2 fa_texcoord0;\nlayout(location = 4) in vec4 fa_color;\nlayout(location = 5) out vec3 fa_lm;\n\nvoid fa_inst_begin()\n{\n}\n\nmat4 fa_skin_matrix(vec4 joints, vec4 weights)\n{\n    vec4 r0 = vec4(0.0);\n    vec4 r1 = vec4(0.0);\n    vec4 r2 = vec4(0.0);\n    for (int i = 0; i < 4; i++)\n    {\n        int _174 = int((joints[i] * 255.0) + 0.5) * 3;\n        r0 += (fa_skin[_174 * 1 + 0] * weights[i]);\n        r1 += (fa_skin[(_174 + 1) * 1 + 0] * weights[i]);\n        r2 += (fa_skin[(_174 + 2) * 1 + 0] * weights[i]);\n    }\n    return mat4(vec4(r0.x, r1.x, r2.x, 0.0), vec4(r0.y, r1.y, r2.y, 0.0), vec4(r0.z, r1.z, r2.z, 0.0), vec4(r0.w, r1.w, r2.w, 1.0));\n}\n\nVertexData fa_vertex_data(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    vec3 _74 = cross(model[1].xyz, model[2].xyz);\n    float _80 = (dot(model[0].xyz, _74) < 0.0) ? (-1.0) : 1.0;\n    return VertexData((model * vec4(position, 1.0)).xyz, (((_74 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _80, vec4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _80), texcoord0 * fa_mesh_vs_params[8].xy, color, position);\n}\n\nvoid fa_shade_vertex(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    mat4 param = model;\n    vec3 param_1 = position;\n    vec3 param_2 = normal;\n    vec4 param_3 = tangent;\n    vec2 param_4 = texcoord0;\n    vec4 param_5 = color;\n    VertexData _273 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    vec3 _397 = _273.world_pos;\n    fa_world_pos = _397;\n    fa_world_normal = _273.world_normal;\n    fa_world_tangent = _273.world_tangent;\n    fa_uv = _273.uv;\n    fa_vertex_color = _273.color;\n    gl_Position = mat4(fa_mesh_vs_params[0], fa_mesh_vs_params[1], fa_mesh_vs_params[2], fa_mesh_vs_params[3]) * vec4(_397, 1.0);\n}\n\nvoid main()\n{\n    fa_inst_begin();\n    vec4 param = fa_joints;\n    vec4 param_1 = fa_weights;\n    mat4 param_2 = mat4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3) * fa_skin_matrix(param, param_1);\n    vec3 param_3 = fa_position;\n    vec3 param_4 = fa_normal;\n    vec4 param_5 = fa_tangent;\n    vec2 param_6 = fa_texcoord0;\n    vec4 param_7 = fa_color;\n    fa_shade_vertex(param_2, param_3, param_4, param_5, param_6, param_7);\n    fa_lm = vec3(0.0);\n}\n\n",
      "fs": "#version 430\n\nstruct SurfaceInput\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 vertex_color;\n    vec3 view_dir;\n    bool front_facing;\n};\n\nstruct LightSample\n{\n    vec3 direction;\n    vec3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct Surface\n{\n    vec3 albedo;\n    float alpha;\n    vec3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    vec3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    vec3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    vec3 specular_color;\n    float transmission;\n    float thickness;\n    vec3 attenuation_color;\n    float attenuation_distance;\n};\n\nstruct FaLayers\n{\n    bool on;\n    float f90;\n    float keep;\n    float base_scale;\n    float coat;\n    float coat_rough;\n    float coat_alpha;\n    float coat_a2;\n    vec3 nc;\n    float coat_ndv;\n    bool sheen_on;\n    vec3 sheen;\n    float sheen_rough;\n    float sheen_alpha;\n    float sheen_scale;\n    float sheen_e;\n    float aniso;\n    vec3 t;\n    vec3 b;\n    float at;\n    float ab;\n};\n\nconst float _4389[63] = float[](1.0, 1.0, 1.0, 0.4790000021457672119140625, 0.11699999868869781494140625, 0.01200000010430812835693359375, 0.0, 0.0, 0.0, 1.0, 1.0, 1.0, 0.578000009059906005859375, 0.19300000369548797607421875, 0.0350000001490116119384765625, 0.0030000000260770320892333984375, 0.0, 0.0, 1.0, 1.0, 1.0, 0.6740000247955322265625, 0.3459999859333038330078125, 0.1319999992847442626953125, 0.032999999821186065673828125, 0.0040000001899898052215576171875, 0.0, 0.971000015735626220703125, 0.954999983310699462890625, 0.828999996185302734375, 0.63999998569488525390625, 0.42599999904632568359375, 0.24500000476837158203125, 0.115000002086162567138671875, 0.037000000476837158203125, 0.0030000000260770320892333984375, 0.7469999790191650390625, 0.737999975681304931640625, 0.670000016689300537109375, 0.563000023365020751953125, 0.4309999942779541015625, 0.3039999902248382568359375, 0.1940000057220458984375, 0.1019999980926513671875, 0.0309999994933605194091796875, 0.614000022411346435546875, 0.609000027179718017578125, 0.566999971866607666015625, 0.499000012874603271484375, 0.412000000476837158203125, 0.32400000095367431640625, 0.240999996662139892578125, 0.162000000476837158203125, 0.087999999523162841796875, 0.538999974727630615234375, 0.535000026226043701171875, 0.505999982357025146484375, 0.4569999873638153076171875, 0.393999993801116943359375, 0.328999996185302734375, 0.2660000026226043701171875, 0.203999996185302734375, 0.14200000464916229248046875);\n\nuniform vec4 fa_mesh_fs_params[53];\nuniform vec4 fa_shadows[30];\nuniform vec4 fa_material[1];\nlayout(binding = 0) uniform sampler2D fa_light_tex_fa_shadow_smp;\nlayout(binding = 1) uniform sampler2D fa_tex_fa_smp;\nlayout(binding = 2) uniform sampler2D fa_normal_tex_fa_smp;\nlayout(binding = 3) uniform sampler2D fa_mr_tex_fa_smp;\nlayout(binding = 4) uniform sampler2D fa_occlusion_tex_fa_smp;\nlayout(binding = 5) uniform sampler2D fa_emissive_tex_fa_smp;\nlayout(binding = 6) uniform sampler2D mask_mask_smp;\nlayout(binding = 7) uniform sampler2D fa_decal_tex_fa_env_smp;\nlayout(binding = 8) uniform sampler2D fa_lightmap_fa_env_smp;\nlayout(binding = 9) uniform sampler2D fa_probe_atlas_fa_env_smp;\nlayout(binding = 10) uniform sampler2D fa_light_atlas_fa_env_smp;\nlayout(binding = 11) uniform sampler2D fa_shadow_tex_fa_shadow_smp;\nlayout(binding = 12) uniform sampler2D fa_screen_tex_fa_shadow_smp;\n\nlayout(location = 0) in vec3 fa_world_pos;\nlayout(location = 5) in vec3 fa_lm;\nlayout(location = 1) in vec3 fa_world_normal;\nlayout(location = 2) in vec4 fa_world_tangent;\nlayout(location = 3) in vec2 fa_uv;\nlayout(location = 4) in vec4 fa_vertex_color;\nlayout(location = 0) out vec4 fa_frag_color;\nvec3 fa_light_tint;\nbool fa_light_is_area;\nint fa_cl_ndir;\nint fa_cl_slot;\nint fa_cl_local;\n\nvoid fa_inst_load()\n{\n}\n\nvec4 fa_light_texel(int t)\n{\n    return texelFetch(fa_light_tex_fa_shadow_smp, ivec2(t & 1023, t >> 10), 0);\n}\n\nvec4 fa_cluster_texel(vec3 world_pos)\n{\n    bool _1628 = fa_mesh_fs_params[19].x < 0.0;\n    bool _1635;\n    if (!_1628)\n    {\n        _1635 = fa_mesh_fs_params[19].w < 1.0;\n    }\n    else\n    {\n        _1635 = _1628;\n    }\n    bool _1643;\n    if (!_1635)\n    {\n        _1643 = fa_mesh_fs_params[18].x < 1.0;\n    }\n    else\n    {\n        _1643 = _1635;\n    }\n    bool _1650;\n    if (!_1643)\n    {\n        _1650 = fa_mesh_fs_params[18].y < 1.0;\n    }\n    else\n    {\n        _1650 = _1643;\n    }\n    bool _1657;\n    if (!_1650)\n    {\n        _1657 = fa_mesh_fs_params[19].y < 1.0;\n    }\n    else\n    {\n        _1657 = _1650;\n    }\n    if (_1657)\n    {\n        return vec4(0.0);\n    }\n    vec4 _1667 = vec4(world_pos, 1.0);\n    float _1673 = dot(fa_mesh_fs_params[16], _1667);\n    if (!(_1673 > 9.9999999747524270787835121154785e-07))\n    {\n        return vec4(0.0);\n    }\n    vec2 _1695 = vec2(dot(fa_mesh_fs_params[14], _1667), dot(fa_mesh_fs_params[15], _1667)) / vec2(_1673);\n    int _1699 = int(fa_mesh_fs_params[18].x);\n    int _1703 = int(fa_mesh_fs_params[18].y);\n    int param = (int(fa_mesh_fs_params[19].x) + (((clamp(int(floor(log2(max(dot(fa_mesh_fs_params[17].xyz, world_pos) + fa_mesh_fs_params[17].w, fa_mesh_fs_params[18].w) / fa_mesh_fs_params[18].w) * fa_mesh_fs_params[18].z)), 0, int(fa_mesh_fs_params[19].y) - 1) * _1703) + clamp(int(floor(((_1695.y * 0.5) + 0.5) * fa_mesh_fs_params[18].y)), 0, _1703 - 1)) * _1699)) + clamp(int(floor(((_1695.x * 0.5) + 0.5) * fa_mesh_fs_params[18].x)), 0, _1699 - 1);\n    return fa_light_texel(param);\n}\n\nivec2 fa_cluster_lookup(vec3 world_pos)\n{\n    vec3 param = world_pos;\n    vec4 _1779 = fa_cluster_texel(param);\n    return ivec2(int(_1779.x), int(_1779.y));\n}\n\nvoid fa_cluster_begin(vec3 world_pos)\n{\n    fa_cl_ndir = int(fa_mesh_fs_params[19].z);\n    vec3 param = world_pos;\n    ivec2 _5864 = fa_cluster_lookup(param);\n    fa_cl_slot = _5864.x;\n    fa_cl_local = _5864.y;\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nvec3 fa_linear_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_tex_fix(inout vec3 c, float mode)\n{\n    if (mode > 1.5)\n    {\n        vec3 param = c;\n        vec3 _7034 = fa_linear_to_srgb(param);\n        c = _7034;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            vec3 param_1 = c;\n            vec3 _7042 = fa_srgb_to_linear(param_1);\n            c = _7042;\n        }\n    }\n    return c;\n}\n\nvec3 fa_tangent_normal(SurfaceInput i, vec3 m)\n{\n    vec3 _534;\n    if (i.front_facing)\n    {\n        _534 = i.world_normal;\n    }\n    else\n    {\n        _534 = -i.world_normal;\n    }\n    vec3 _558 = normalize(i.world_tangent.xyz - (_534 * dot(_534, i.world_tangent.xyz)));\n    vec3 _585 = normalize(((_558 * m.x) + ((cross(_534, _558) * i.world_tangent.w) * m.y)) + (_534 * m.z));\n    vec3 _588;\n    if (i.front_facing)\n    {\n        _588 = _585;\n    }\n    else\n    {\n        _588 = -_585;\n    }\n    return _588;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    vec4 base_t = texture(fa_tex_fa_smp, i.uv);\n    float param = fa_mesh_fs_params[6].w;\n    float param_1 = 1.0;\n    vec3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    vec3 _7073 = fa_tex_fix(param_2, param_3);\n    vec4 _9346 = base_t;\n    _9346.x = _7073.x;\n    _9346.y = _7073.y;\n    _9346.z = _7073.z;\n    base_t = _9346;\n    vec4 _7087 = (_9346 * fa_mesh_fs_params[2]) * i.vertex_color;\n    vec3 _9122 = i.world_normal;\n    if (fa_mesh_fs_params[6].z > 0.5)\n    {\n        float param_4 = fa_mesh_fs_params[6].w;\n        float param_5 = 16.0;\n        vec3 param_6 = texture(fa_normal_tex_fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        vec3 _7119 = fa_tex_fix(param_6, param_7);\n        vec3 _7122 = (_7119 * 2.0) - vec3(1.0);\n        vec2 _7127 = _7122.xy * fa_mesh_fs_params[6].x;\n        vec3 _9354 = _7122;\n        _9354.x = _7127.x;\n        _9354.y = _7127.y;\n        SurfaceInput param_8 = i;\n        vec3 param_9 = _9354;\n        _9122 = fa_tangent_normal(param_8, param_9);\n    }\n    vec4 mrt = texture(fa_mr_tex_fa_smp, i.uv);\n    float param_10 = fa_mesh_fs_params[6].w;\n    float param_11 = 64.0;\n    vec3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    vec3 _7155 = fa_tex_fix(param_12, param_13);\n    vec4 _9357 = mrt;\n    _9357.x = _7155.x;\n    _9357.y = _7155.y;\n    _9357.z = _7155.z;\n    mrt = _9357;\n    vec4 _7183 = texture(fa_occlusion_tex_fa_smp, i.uv);\n    float param_14 = fa_mesh_fs_params[6].w;\n    float param_15 = 256.0;\n    vec3 param_16 = _7183.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    vec3 _7194 = fa_tex_fix(param_16, param_17);\n    float param_18 = fa_mesh_fs_params[6].w;\n    float param_19 = 4.0;\n    vec3 param_20 = texture(fa_emissive_tex_fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    vec3 _7224 = fa_tex_fix(param_20, param_21);\n    float _9127 = fa_mesh_fs_params[20].x;\n    float _9128 = fa_mesh_fs_params[20].y;\n    float _9131 = fa_mesh_fs_params[20].z;\n    float _9130 = fa_mesh_fs_params[21].w;\n    float _9133 = fa_mesh_fs_params[22].x;\n    if (fa_mesh_fs_params[22].z > 0.5)\n    {\n        if (mod(fa_mesh_fs_params[22].z, 2.0) > 0.5)\n        {\n            _9127 *= _7194.y;\n            _9128 *= _7194.z;\n            _9130 *= _7183.w;\n        }\n        if (fa_mesh_fs_params[22].z > 1.5)\n        {\n            _9131 *= mrt.x;\n            _9133 *= mrt.w;\n        }\n    }\n    return Surface(_7087.xyz, _7087.w, _9122, clamp(fa_mesh_fs_params[5].x * _7155.z, 0.0, 1.0), clamp(fa_mesh_fs_params[5].y * _7155.y, 0.0500000007450580596923828125, 1.0), 1.0 + (fa_mesh_fs_params[6].y * (_7194.x - 1.0)), fa_mesh_fs_params[3].xyz + (fa_mesh_fs_params[4].xyz * _7224), _9127, _9128, fa_mesh_fs_params[21].xyz, _9130, _9131, fa_mesh_fs_params[20].w, _9133, fa_mesh_fs_params[22].y, fa_mesh_fs_params[23].xyz, fa_mesh_fs_params[30].x, fa_mesh_fs_params[30].y, fa_mesh_fs_params[31].xyz, fa_mesh_fs_params[30].z);\n}\n\nvoid surface(SurfaceInput i, inout Surface s)\n{\n    s.alpha = texture(mask_mask_smp, i.uv * 2.0).x;\n}\n\nvec4 fa_decal_tile(vec4 rect, vec2 uv, vec2 atlas, vec2 ddx, vec2 ddy)\n{\n    vec2 _1859 = rect.zw - rect.xy;\n    vec2 _1863 = _1859 * atlas;\n    vec2 _1867 = ddx * _1863;\n    vec2 _1871 = ddy * _1863;\n    return textureLod(fa_decal_tex_fa_env_smp, rect.xy + (clamp(uv, vec2(0.0), vec2(1.0)) * _1859), clamp(0.5 * log2(max(max(dot(_1867, _1867), dot(_1871, _1871)), 9.9999999392252902907785028219223e-09)), 0.0, 3.0));\n}\n\nvec3 fa_dc_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_dc_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvoid fa_apply_decals(vec3 world_pos, vec3 geo_normal, inout vec3 albedo, inout vec3 normal)\n{\n    bool _1904 = fa_mesh_fs_params[10].y < 0.5;\n    bool _1911;\n    if (!_1904)\n    {\n        _1911 = fa_mesh_fs_params[10].w < 0.5;\n    }\n    else\n    {\n        _1911 = _1904;\n    }\n    if (_1911)\n    {\n        return;\n    }\n    vec3 _1917 = dFdx(world_pos);\n    vec3 _1920 = dFdy(world_pos);\n    vec3 param = world_pos;\n    vec4 _1924 = fa_cluster_texel(param);\n    int _1928 = int(_1924.w);\n    if (_1928 < 1)\n    {\n        return;\n    }\n    int _1938 = int(fa_mesh_fs_params[10].y + 0.5);\n    int param_1 = _1938;\n    vec4 _1942 = fa_light_texel(param_1);\n    vec2 _1945 = _1942.yz;\n    int _1949 = int(_1942.w);\n    int param_2 = _1938 + 1;\n    vec4 _1954 = fa_light_texel(param_2);\n    float _1955 = _1954.x;\n    int _1961 = int(fa_mesh_fs_params[10].w + 0.5) - 1;\n    int _1965 = int(_1924.z);\n    vec3 _2230;\n    for (int k = 0; k < _1928; k++)\n    {\n        int _1978 = _1965 + k;\n        int param_3 = _1949 + (_1978 >> 2);\n        int _1995 = (_1938 + 2) + (int(fa_light_texel(param_3)[_1978 & 3]) * 7);\n        int param_4 = _1995 + 6;\n        vec4 _2000 = fa_light_texel(param_4);\n        if (((int(_2000.w + 0.5) >> _1961) & 1) == 0)\n        {\n            continue;\n        }\n        int param_5 = _1995;\n        vec4 _2015 = fa_light_texel(param_5);\n        int param_6 = _1995 + 1;\n        vec4 _2020 = fa_light_texel(param_6);\n        int param_7 = _1995 + 2;\n        vec4 _2025 = fa_light_texel(param_7);\n        vec3 _2028 = _2015.xyz;\n        float _2033 = dot(_2028, world_pos) + _2015.w;\n        vec3 _2035 = _2020.xyz;\n        float _2040 = dot(_2035, world_pos) + _2020.w;\n        vec3 _2042 = _2025.xyz;\n        float _2047 = dot(_2042, world_pos) + _2025.w;\n        bool _2052 = abs(_2033) > 0.5;\n        bool _2060;\n        if (!_2052)\n        {\n            _2060 = abs(_2040) > 0.5;\n        }\n        else\n        {\n            _2060 = _2052;\n        }\n        bool _2068;\n        if (!_2060)\n        {\n            _2068 = abs(_2047) > 0.5;\n        }\n        else\n        {\n            _2068 = _2060;\n        }\n        if (_2068)\n        {\n            continue;\n        }\n        float _2083 = clamp(dot(geo_normal, normalize(_2042)) * _2000.z, 0.0, 1.0);\n        if (_2083 <= 0.0)\n        {\n            continue;\n        }\n        float _2103 = (clamp((0.5 - abs(_2047)) * 10.0, 0.0, 1.0) * _2083) * _2000.x;\n        vec2 _2111 = vec2(_2033 + 0.5, 0.5 - _2040);\n        vec2 _2121 = vec2(dot(_2028, _1917), dot(_2035, _1917));\n        vec2 _2131 = vec2(dot(_2028, _1920), dot(_2035, _1920));\n        int param_8 = _1995 + 5;\n        vec4 _2136 = fa_light_texel(param_8);\n        int param_9 = _1995 + 3;\n        vec4 _2141 = fa_light_texel(param_9);\n        int param_10 = _1995 + 4;\n        vec4 _2146 = fa_light_texel(param_10);\n        float tex_a = 1.0;\n        vec3 col = _2136.xyz;\n        bool _2156 = _2141.z > _2141.x;\n        if (_2156)\n        {\n            vec4 param_11 = _2141;\n            vec2 param_12 = _2111;\n            vec2 param_13 = _1945;\n            vec2 param_14 = _2121;\n            vec2 param_15 = _2131;\n            vec4 tx = fa_decal_tile(param_11, param_12, param_13, param_14, param_15);\n            if ((_1955 > 0.5) && (_1955 < 1.5))\n            {\n                vec3 param_16 = tx.xyz;\n                vec3 _2182 = fa_dc_to_linear(param_16);\n                vec4 _9210 = tx;\n                _9210.x = _2182.x;\n                _9210.y = _2182.y;\n                _9210.z = _2182.z;\n                tx = _9210;\n            }\n            col *= tx.xyz;\n            tex_a = tx.w;\n        }\n        albedo = mix(albedo, col, vec3(clamp((_2103 * tex_a) * _2136.w, 0.0, 1.0)));\n        if (_2146.z > _2146.x)\n        {\n            vec4 param_17 = _2146;\n            vec2 param_18 = _2111;\n            vec2 param_19 = _1945;\n            vec2 param_20 = _2121;\n            vec2 param_21 = _2131;\n            vec4 _2226 = fa_decal_tile(param_17, param_18, param_19, param_20, param_21);\n            if (_1955 > 1.5)\n            {\n                vec3 param_22 = _2226.xyz;\n                vec3 _2236 = fa_dc_to_srgb(param_22);\n                _2230 = _2236;\n            }\n            else\n            {\n                _2230 = _2226.xyz;\n            }\n            vec3 _2245 = (_2230 * 2.0) - vec3(1.0);\n            vec2 _2250 = _2245.xy * _2000.y;\n            vec3 _2272 = (normalize(_2028) * _2250.x) + (normalize(_2035) * _2250.y);\n            vec3 _2275 = normalize(normal);\n            normal = normalize(mix(_2275, normalize((_2275 * max(_2245.z, 0.0500000007450580596923828125)) + (_2272 - (_2275 * dot(_2275, _2272)))), vec3(clamp(_2103 * (_2156 ? tex_a : 1.0), 0.0, 1.0))));\n        }\n    }\n}\n\nvoid fa_lod_dither()\n{\n    if (fa_mesh_fs_params[52].w != 0.0)\n    {\n        float _624 = fract(52.98291778564453125 * fract(dot(gl_FragCoord.xy, vec2(0.067110560834407806396484375, 0.005837149918079376220703125))));\n        bool _627;\n        if (fa_mesh_fs_params[52].w > 0.0)\n        {\n            _627 = _624 >= fa_mesh_fs_params[52].w;\n        }\n        else\n        {\n            _627 = _624 < (-fa_mesh_fs_params[52].w);\n        }\n        if (_627)\n        {\n            discard;\n        }\n    }\n}\n\nfloat fa_sheen_albedo(float ndv, float rough)\n{\n    float _4314 = min(sqrt(max(rough - 0.100000001490116119384765625, 0.0) * 1.111111164093017578125) * 6.0, 5.999000072479248046875);\n    float _4322 = min(sqrt(clamp(ndv, 0.0, 1.0)) * 8.0, 7.999000072479248046875);\n    int _4325 = int(_4314);\n    int _4328 = int(_4322);\n    float _4338 = _4322 - float(_4328);\n    int _4393 = (_4325 * 9) + _4328;\n    int _4413 = ((_4325 + 1) * 9) + _4328;\n    return mix(mix(_4389[_4393], _4389[_4393 + 1], _4338), mix(_4389[_4413], _4389[_4413 + 1], _4338), _4314 - float(_4325));\n}\n\nFaLayers fa_layers_setup(SurfaceInput i, Surface s, vec3 n, vec3 v, float metallic, float roughness, inout vec3 f0)\n{\n    bool _9045 = false;\n    float _9046 = 1.0;\n    float _9047 = 1.0;\n    float _9048 = 1.0;\n    float _9049 = 0.0;\n    float _9050 = 0.0;\n    float _9051 = 0.0;\n    float _9052 = 0.0;\n    float _9054 = 1.0;\n    bool _9055 = false;\n    vec3 _9056 = vec3(0.0);\n    float _9057 = 1.0;\n    float _9058 = 1.0;\n    float _9059 = 1.0;\n    float _9060 = 0.0;\n    float _9061 = 0.0;\n    vec3 _9062 = vec3(1.0, 0.0, 0.0);\n    vec3 _9063 = vec3(0.0, 0.0, 1.0);\n    float _9064 = 1.0;\n    float _9065 = 1.0;\n    float _4464 = clamp(s.specular, 0.0, 1.0);\n    float _4468 = clamp(s.ior, 1.0, 3.0);\n    bool _4473 = (_4464 != 1.0) || (_4468 != 1.5);\n    bool _4482;\n    if (!_4473)\n    {\n        _4482 = any(notEqual(s.specular_color, vec3(1.0)));\n    }\n    else\n    {\n        _4482 = _4473;\n    }\n    if (_4482)\n    {\n        float _4490 = (_4468 - 1.0) / (_4468 + 1.0);\n        f0 = mix(min(vec3(_4490 * _4490) * max(s.specular_color, vec3(0.0)), vec3(1.0)) * _4464, s.albedo, vec3(metallic));\n        _9046 = mix(_4464, 1.0, metallic);\n        _9045 = true;\n    }\n    float _4517 = clamp(s.clearcoat, 0.0, 1.0);\n    if (_4517 > 0.0)\n    {\n        float _4525 = clamp(s.clearcoat_roughness, 0.0500000007450580596923828125, 1.0);\n        _9049 = _4517;\n        _9050 = _4525;\n        float _4532 = _4525 * _4525;\n        _9051 = _4532;\n        _9052 = _4532 * _4532;\n        float _4544 = max(dot(i.world_normal, v), 9.9999997473787516355514526367188e-05);\n        _9054 = _4544;\n        _9047 = 1.0 - (_4517 * (0.039999999105930328369140625 + (0.959999978542327880859375 * pow(clamp(1.0 - _4544, 0.0, 1.0), 5.0))));\n        _9045 = true;\n    }\n    vec3 _4563 = max(s.sheen_color, vec3(0.0));\n    float _4572 = max(_4563.x, max(_4563.y, _4563.z));\n    if (_4572 > 0.0)\n    {\n        float _4580 = clamp(s.sheen_roughness, 0.100000001490116119384765625, 1.0);\n        _9055 = true;\n        _9056 = _4563;\n        _9057 = _4580;\n        _9058 = _4580 * _4580;\n        float param = max(dot(n, v), 9.9999997473787516355514526367188e-05);\n        float param_1 = _4580;\n        float _4597 = fa_sheen_albedo(param, param_1);\n        _9060 = _4597;\n        _9059 = 1.0 - min(_4572 * _4597, 1.0);\n        _9045 = true;\n    }\n    _9048 = _9047 * _9059;\n    float _4616 = clamp(s.anisotropy, -1.0, 1.0);\n    if (_4616 != 0.0)\n    {\n        vec3 _4631 = i.world_tangent.xyz - (n * dot(n, i.world_tangent.xyz));\n        vec3 t = _4631;\n        if (dot(_4631, _4631) < 9.9999999392252902907785028219223e-09)\n        {\n            bvec3 _4643 = bvec3(abs(n.y) < 0.9900000095367431640625);\n            t = cross(vec3(_4643.x ? vec3(0.0, 1.0, 0.0).x : vec3(1.0, 0.0, 0.0).x, _4643.y ? vec3(0.0, 1.0, 0.0).y : vec3(1.0, 0.0, 0.0).y, _4643.z ? vec3(0.0, 1.0, 0.0).z : vec3(1.0, 0.0, 0.0).z), n);\n        }\n        vec3 _4647 = t;\n        vec3 _4648 = normalize(_4647);\n        t = _4648;\n        vec3 _4673 = normalize((_4648 * cos(s.anisotropy_rotation)) + ((cross(n, _4648) * ((i.world_tangent.w < 0.0) ? (-1.0) : 1.0)) * sin(s.anisotropy_rotation)));\n        _9062 = _4673;\n        _9063 = cross(n, _4673);\n        float _4683 = roughness * roughness;\n        float _4689 = mix(_4683, 1.0, _4616 * _4616);\n        bool _4691 = _4616 > 0.0;\n        _9064 = _4691 ? _4689 : _4683;\n        _9065 = _4691 ? _4683 : _4689;\n        _9061 = _4616;\n        _9045 = true;\n    }\n    return FaLayers(_9045, _9046, _9047, _9048, _9049, _9050, _9051, _9052, i.world_normal, _9054, _9055, _9056, _9057, _9058, _9059, _9060, _9061, _9062, _9063, _9064, _9065);\n}\n\nvec2 fa_atlas_size()\n{\n    return vec2(textureSize(fa_probe_atlas_fa_env_smp, 0));\n}\n\nvec3 fa_probe_sh_coef(vec2 origin, float res, int k)\n{\n    vec3 v = textureLod(fa_probe_atlas_fa_env_smp, (origin + vec2(float(k) + 0.5, res + 2.5)) / fa_atlas_size(), 0.0).xyz;\n    if (fa_mesh_fs_params[41].y > 0.5)\n    {\n        v = ((v * 255.0) - vec3(128.0)) * 0.03149606287479400634765625;\n    }\n    return v;\n}\n\nvec3 fa_sh_eval(vec3 c[9], vec3 n)\n{\n    vec3 _3482 = max((((c[0] * 0.2820948064327239990234375) + (((c[1] * (0.3257350027561187744140625 * n.y)) + (c[2] * (0.3257350027561187744140625 * n.z))) + (c[3] * (0.3257350027561187744140625 * n.x)))) + (((c[4] * ((0.2731371223926544189453125 * n.x) * n.y)) + (c[5] * ((0.2731371223926544189453125 * n.y) * n.z))) + (c[6] * (0.078847892582416534423828125 * (((3.0 * n.z) * n.z) - 1.0))))) + ((c[7] * ((0.2731371223926544189453125 * n.x) * n.z)) + (c[8] * (0.13656856119632720947265625 * ((n.x * n.x) - (n.y * n.y))))), vec3(0.0));\n    return _3482;\n}\n\nvec3 fa_ambient_light(vec3 n)\n{\n    float _4095 = (1.0 - fa_mesh_fs_params[42].w) - fa_mesh_fs_params[47].w;\n    vec3 amb = vec3(0.0);\n    bool _4100 = fa_mesh_fs_params[11].w > 0.5;\n    vec3 c[9];\n    for (int k = 0; k < 9; k++)\n    {\n        c[k] = vec3(0.0);\n    }\n    if (_4095 > 0.0005000000237487256526947021484375)\n    {\n        if (_4100)\n        {\n            for (int k_1 = 0; k_1 < 9; k_1++)\n            {\n                vec2 param = fa_mesh_fs_params[41].zw;\n                float param_1 = 128.0;\n                int param_2 = k_1;\n                c[k_1] = fa_probe_sh_coef(param, param_1, param_2) * _4095;\n            }\n        }\n        else\n        {\n            amb = fa_mesh_fs_params[1].xyz * _4095;\n        }\n    }\n    bool _4151 = fa_mesh_fs_params[42].w > 0.0;\n    if (_4151)\n    {\n        for (int k_2 = 0; k_2 < 9; k_2++)\n        {\n            vec2 param_3 = fa_mesh_fs_params[42].xy;\n            float param_4 = fa_mesh_fs_params[42].z;\n            int param_5 = k_2;\n            c[k_2] += (fa_probe_sh_coef(param_3, param_4, param_5) * fa_mesh_fs_params[42].w);\n        }\n    }\n    bool _4182 = fa_mesh_fs_params[47].w > 0.0;\n    if (_4182)\n    {\n        for (int k_3 = 0; k_3 < 9; k_3++)\n        {\n            vec2 param_6 = fa_mesh_fs_params[47].xy;\n            float param_7 = fa_mesh_fs_params[47].z;\n            int param_8 = k_3;\n            c[k_3] += (fa_probe_sh_coef(param_6, param_7, param_8) * fa_mesh_fs_params[47].w);\n        }\n    }\n    if ((_4100 || _4151) || _4182)\n    {\n        vec3 param_9[9] = c;\n        vec3 param_10 = n;\n        amb += fa_sh_eval(param_9, param_10);\n    }\n    return amb;\n}\n\nvec4 fa_gi_fetch(vec2 texel)\n{\n    return textureLod(fa_probe_atlas_fa_env_smp, texel / fa_atlas_size(), 0.0);\n}\n\nvec2 fa_oct_encode(vec3 d)\n{\n    vec3 _3502 = d / vec3(max((abs(d.x) + abs(d.y)) + abs(d.z), 9.9999999600419720025001879548654e-13));\n    float _3505 = _3502.x;\n    float _3507 = _3502.z;\n    vec2 e = vec2(_3505, _3507);\n    if (_3502.y < 0.0)\n    {\n        e = vec2((1.0 - abs(_3507)) * ((_3505 < 0.0) ? (-1.0) : 1.0), (1.0 - abs(_3505)) * ((_3507 < 0.0) ? (-1.0) : 1.0));\n    }\n    return e;\n}\n\nvec3 fa_gi_grid(int rec, vec3 n, vec3 v, out float cover)\n{\n    cover = 0.0;\n    int param = rec;\n    vec4 _7334 = fa_light_texel(param);\n    int param_1 = rec + 1;\n    vec4 _7339 = fa_light_texel(param_1);\n    int param_2 = rec + 2;\n    vec4 _7344 = fa_light_texel(param_2);\n    int param_3 = rec + 3;\n    vec4 _7349 = fa_light_texel(param_3);\n    bool _7352 = _7349.z < 0.5;\n    bool _7360;\n    if (!_7352)\n    {\n        _7360 = fa_atlas_size().y < 1155.0;\n    }\n    else\n    {\n        _7360 = _7352;\n    }\n    if (_7360)\n    {\n        return vec3(0.0);\n    }\n    float _7367 = max(_7334.w, 9.9999997473787516355514526367188e-05);\n    vec3 _7370 = _7339.xyz;\n    vec3 _7374 = _7334.xyz;\n    vec3 _7378 = (fa_world_pos - _7374) / vec3(_7367);\n    vec3 _7387 = min(_7378 + vec3(0.5), (_7370 - vec3(0.5)) - _7378);\n    float _7396 = min(_7387.x, min(_7387.y, _7387.z));\n    if (!(_7396 > 0.0))\n    {\n        return vec3(0.0);\n    }\n    vec3 _7411 = _7370 - vec3(1.0);\n    vec3 _7412 = clamp(_7378, vec3(0.0), _7411);\n    vec3 _7420 = min(floor(_7412), max(_7370 - vec3(2.0), vec3(0.0)));\n    vec3 _7424 = _7412 - _7420;\n    vec3 _7435 = fa_world_pos + (((n * 0.800000011920928955078125) + (v * 0.20000000298023223876953125)) * (0.20000000298023223876953125 * _7367));\n    int _7440 = int(_7344.y + 0.5);\n    float _7445 = 0.3257350027561187744140625 * n.y;\n    float _7449 = 0.3257350027561187744140625 * n.z;\n    float _7453 = 0.3257350027561187744140625 * n.x;\n    float _7460 = (0.2731371223926544189453125 * n.x) * n.y;\n    float _7467 = (0.2731371223926544189453125 * n.y) * n.z;\n    float _7476 = 0.078847892582416534423828125 * (((3.0 * n.z) * n.z) - 1.0);\n    float _7483 = (0.2731371223926544189453125 * n.x) * n.z;\n    float _7496 = 0.13656856119632720947265625 * ((n.x * n.x) - (n.y * n.y));\n    vec3 acc = vec3(0.0);\n    float wsum = 0.0;\n    int _7503 = 8 + int(_7349.w);\n    float _7530;\n    float _7543;\n    float _7557;\n    for (int k = 0; k < _7503; k++)\n    {\n        float _7516 = float(k & 1);\n        float _7520 = float((k >> 1) & 1);\n        float _7524 = float((k >> 2) & 1);\n        if (_7516 > 0.5)\n        {\n            _7530 = _7424.x;\n        }\n        else\n        {\n            _7530 = 1.0 - _7424.x;\n        }\n        if (_7520 > 0.5)\n        {\n            _7543 = _7424.y;\n        }\n        else\n        {\n            _7543 = 1.0 - _7424.y;\n        }\n        if (_7524 > 0.5)\n        {\n            _7557 = _7424.z;\n        }\n        else\n        {\n            _7557 = 1.0 - _7424.z;\n        }\n        float _7567 = (_7530 * _7543) * _7557;\n        if (!(_7567 > 0.0))\n        {\n            continue;\n        }\n        vec3 _7580 = min(_7420 + vec3(_7516, _7520, _7524), _7411);\n        int _7600 = int(((_7344.x + _7580.x) + (_7339.x * (_7580.y + (_7339.y * _7580.z)))) + 0.5);\n        vec2 _7615 = vec2(float(_7600 % _7440) * 10.0, 1024.0 + (float(_7600 / _7440) * 11.0));\n        vec2 param_4 = _7615 + vec2(9.5, 10.5);\n        vec4 _7623 = fa_gi_fetch(param_4);\n        bool _7626 = _7623.y < 0.5;\n        bool _7635;\n        if (!_7626)\n        {\n            _7635 = _7623.x > _7349.y;\n        }\n        else\n        {\n            _7635 = _7626;\n        }\n        if (_7635)\n        {\n            continue;\n        }\n        vec3 _7647 = _7435 - (_7374 + (_7580 * _7367));\n        float _7650 = length(_7647);\n        vec3 _7656 = _7647 / vec3(max(_7650, 9.9999997473787516355514526367188e-05));\n        float _7666 = max(9.9999997473787516355514526367188e-05, (dot(-_7656, n) + 1.0) * 0.5);\n        float w = _7567 * (_7666 * _7666);\n        vec3 param_5 = _7656;\n        vec2 param_6 = (_7615 + vec2(1.0)) + (((fa_oct_encode(param_5) * 0.5) + vec2(0.5)) * 8.0);\n        vec4 _7685 = fa_gi_fetch(param_6);\n        float _7692 = _7650 / max(_7344.z, 9.9999997473787516355514526367188e-05);\n        float _7695 = _7685.x;\n        if (_7692 > _7695)\n        {\n            float _7708 = max(_7685.y - (_7695 * _7695), 0.0);\n            float _7713 = _7692 - _7695;\n            float _7722 = _7708 / max(_7708 + (_7713 * _7713), 9.9999999600419720025001879548654e-13);\n            w *= ((_7722 * _7722) * _7722);\n        }\n        if (!(w > 0.0))\n        {\n            continue;\n        }\n        vec2 param_7 = _7615 + vec2(0.5, 10.5);\n        vec2 param_8 = _7615 + vec2(1.5, 10.5);\n        vec2 param_9 = _7615 + vec2(2.5, 10.5);\n        vec2 param_10 = _7615 + vec2(3.5, 10.5);\n        vec2 param_11 = _7615 + vec2(4.5, 10.5);\n        vec2 param_12 = _7615 + vec2(5.5, 10.5);\n        vec2 param_13 = _7615 + vec2(6.5, 10.5);\n        vec2 param_14 = _7615 + vec2(7.5, 10.5);\n        vec2 param_15 = _7615 + vec2(8.5, 10.5);\n        acc += ((((((((((fa_gi_fetch(param_7).xyz * 0.2820948064327239990234375) + (fa_gi_fetch(param_8).xyz * _7445)) + (fa_gi_fetch(param_9).xyz * _7449)) + (fa_gi_fetch(param_10).xyz * _7453)) + (fa_gi_fetch(param_11).xyz * _7460)) + (fa_gi_fetch(param_12).xyz * _7467)) + (fa_gi_fetch(param_13).xyz * _7476)) + (fa_gi_fetch(param_14).xyz * _7483)) + (fa_gi_fetch(param_15).xyz * _7496)) * w);\n        wsum += w;\n    }\n    if (!(wsum > 9.9999997473787516355514526367188e-06))\n    {\n        return vec3(0.0);\n    }\n    cover = smoothstep(0.0, 1.0, clamp(_7396 * 2.0, 0.0, 1.0)) * smoothstep(0.0, 0.0199999995529651641845703125, wsum);\n    float _7846;\n    if (fa_mesh_fs_params[52].z > 0.5)\n    {\n        _7846 = _7349.x;\n    }\n    else\n    {\n        _7846 = 1.0;\n    }\n    return max(acc / vec3(wsum), vec3(0.0)) * (_7344.w * _7846);\n}\n\nvec3 fa_gi_light(vec3 n, inout float left)\n{\n    left = 1.0;\n    vec3 acc = vec3(0.0);\n    vec3 _7870 = normalize(fa_mesh_fs_params[0].xyz - fa_world_pos);\n    int _7875 = int(fa_mesh_fs_params[52].x + 0.5);\n    int _7880 = int(fa_mesh_fs_params[52].y + 0.5);\n    float param_3;\n    for (int k = 0; (k < _7880) && (k < 8); k++)\n    {\n        int param = _7875 + (4 * k);\n        vec3 param_1 = n;\n        vec3 param_2 = _7870;\n        vec3 _7905 = fa_gi_grid(param, param_1, param_2, param_3);\n        float _7910 = param_3 * left;\n        acc += (_7905 * _7910);\n        left -= _7910;\n        if (left < 0.001000000047497451305389404296875)\n        {\n            left = 0.0;\n            break;\n        }\n    }\n    return acc;\n}\n\nvec3 fa_realtime_or_ambient(vec3 n)\n{\n    vec3 gi = vec3(0.0);\n    float left = 1.0;\n    if (fa_mesh_fs_params[52].y > 0.5)\n    {\n        vec3 param = n;\n        float param_1;\n        vec3 _7939 = fa_gi_light(param, param_1);\n        left = param_1;\n        gi = _7939;\n    }\n    if (left <= 0.0)\n    {\n        return gi;\n    }\n    vec3 param_2 = n;\n    return gi + (fa_ambient_light(param_2) * left);\n}\n\nvec3 fa_indirect_diffuse(vec3 n)\n{\n    if (fa_lm.z > 0.5)\n    {\n        return textureLod(fa_lightmap_fa_env_smp, fa_lm.xy, 0.0).xyz;\n    }\n    if (fa_mesh_fs_params[32].w > 0.0)\n    {\n        vec3 c[9];\n        for (int k = 0; k < 9; k++)\n        {\n            c[k] = fa_mesh_fs_params[k * 1 + 32].xyz;\n        }\n        vec3 param = n;\n        vec3 param_1[9] = c;\n        vec3 param_2 = n;\n        return mix(fa_ambient_light(param), fa_sh_eval(param_1, param_2), vec3(clamp(fa_mesh_fs_params[32].w, 0.0, 1.0)));\n    }\n    vec3 param_3 = n;\n    return fa_realtime_or_ambient(param_3);\n}\n\nint fa_cluster_index(int slot, int n)\n{\n    int param = (int(fa_mesh_fs_params[19].x) + int(fa_mesh_fs_params[19].w)) + ((slot + n) >> 2);\n    vec4 t = fa_light_texel(param);\n    return int(t[(slot + n) & 3]);\n}\n\nint fa_cl_light(int n)\n{\n    if (n < fa_cl_ndir)\n    {\n        return n;\n    }\n    int param = fa_cl_slot;\n    int param_1 = n - fa_cl_ndir;\n    return fa_cluster_index(param, param_1);\n}\n\nint fa_light_base(int li)\n{\n    return li * ((fa_mesh_fs_params[1].w > 4.5) ? 8 : 4);\n}\n\nbool fa_light_baked(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 3;\n    return fa_light_texel(param_1).w > 0.5;\n}\n\nfloat fa_baked_keep(int li)\n{\n    float _5834;\n    if (fa_lm.z > 0.5)\n    {\n        _5834 = 0.0;\n    }\n    else\n    {\n        _5834 = 1.0 - clamp(fa_mesh_fs_params[32].w, 0.0, 1.0);\n    }\n    bool _5845 = _5834 < 1.0;\n    bool _5851;\n    if (_5845)\n    {\n        int param = li;\n        _5851 = fa_light_baked(param);\n    }\n    else\n    {\n        _5851 = _5845;\n    }\n    return _5851 ? _5834 : 1.0;\n}\n\nfloat fa_light_type(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 1;\n    return fa_light_texel(param_1).w;\n}\n\nvec4 fa_atlas_fetch(vec2 texel)\n{\n    return textureLod(fa_light_atlas_fa_env_smp, texel / vec2(textureSize(fa_light_atlas_fa_env_smp, 0)), 0.0);\n}\n\nvec3 fa_cookie_sample(vec2 tile_origin, vec2 uv)\n{\n    vec2 param = (tile_origin + vec2(1.0)) + (clamp(uv, vec2(0.0), vec2(1.0)) * 254.0);\n    return fa_atlas_fetch(param).xyz;\n}\n\nvec3 fa_area_point(vec3 c, vec3 axis, vec3 ru, vec3 uu, float hx, float hy, float shape, vec3 p, vec3 r)\n{\n    bool _877 = dot(r, r) > 0.5;\n    if (shape > 1.5)\n    {\n        vec3 _890 = (c - (ru * hx)) - p;\n        vec3 _896 = ru * (2.0 * hx);\n        float _902 = max(dot(_896, _896), 9.9999999392252902907785028219223e-09);\n        float _906 = dot(_890, _896);\n        float t = clamp((-_906) / _902, 0.0, 1.0);\n        if (_877)\n        {\n            float _921 = dot(r, _896);\n            float _927 = _902 - (_921 * _921);\n            if (abs(_927) > (9.9999997473787516355514526367188e-06 * _902))\n            {\n                t = clamp(((dot(r, _890) * _921) - _906) / _927, 0.0, 1.0);\n            }\n        }\n        return (p + _890) + (_896 * t);\n    }\n    vec3 q = p;\n    float _959 = dot(r, axis);\n    bool _967;\n    if (_877)\n    {\n        _967 = abs(_959) > 9.9999997473787516355514526367188e-05;\n    }\n    else\n    {\n        _967 = _877;\n    }\n    if (_967)\n    {\n        float _977 = dot(c - p, axis) / _959;\n        if (_977 > 0.0)\n        {\n            q = p + (r * _977);\n        }\n    }\n    vec3 _990 = q - c;\n    vec2 xy = vec2(dot(_990, ru), dot(_990, uu));\n    if (shape > 0.5)\n    {\n        float _1005 = length(xy);\n        if (_1005 > hx)\n        {\n            xy *= (hx / _1005);\n        }\n    }\n    else\n    {\n        xy = clamp(xy, vec2(-hx, -hy), vec2(hx, hy));\n    }\n    return (c + (ru * xy.x)) + (uu * xy.y);\n}\n\nint fa_cube_face(vec3 d)\n{\n    vec3 _644 = abs(d);\n    float _646 = _644.x;\n    float _648 = _644.y;\n    bool _649 = _646 >= _648;\n    bool _657;\n    if (_649)\n    {\n        _657 = _646 >= _644.z;\n    }\n    else\n    {\n        _657 = _649;\n    }\n    int _658;\n    if (_657)\n    {\n        _658 = (d.x > 0.0) ? 0 : 1;\n    }\n    else\n    {\n        int _672;\n        if (_648 >= _644.z)\n        {\n            _672 = (d.y > 0.0) ? 2 : 3;\n        }\n        else\n        {\n            _672 = (d.z > 0.0) ? 4 : 5;\n        }\n        _658 = _672;\n    }\n    return _658;\n}\n\nvoid fa_cube_face_basis(int f, out vec3 fwd, out vec3 up)\n{\n    if (f == 0)\n    {\n        fwd = vec3(1.0, 0.0, 0.0);\n        up = vec3(0.0, 1.0, 0.0);\n    }\n    else\n    {\n        if (f == 1)\n        {\n            fwd = vec3(-1.0, 0.0, 0.0);\n            up = vec3(0.0, 1.0, 0.0);\n        }\n        else\n        {\n            if (f == 2)\n            {\n                fwd = vec3(0.0, 1.0, 0.0);\n                up = vec3(0.0, 0.0, 1.0);\n            }\n            else\n            {\n                if (f == 3)\n                {\n                    fwd = vec3(0.0, -1.0, 0.0);\n                    up = vec3(0.0, 0.0, -1.0);\n                }\n                else\n                {\n                    if (f == 4)\n                    {\n                        fwd = vec3(0.0, 0.0, 1.0);\n                        up = vec3(0.0, 1.0, 0.0);\n                    }\n                    else\n                    {\n                        fwd = vec3(0.0, 0.0, -1.0);\n                        up = vec3(0.0, 1.0, 0.0);\n                    }\n                }\n            }\n        }\n    }\n}\n\nfloat fa_ies_sample(vec2 tile_origin, vec3 d, vec3 axis, vec3 right, vec3 up)\n{\n    float _797 = dot(d, right);\n    float _801 = dot(d, up);\n    float _812;\n    if (((_797 * _797) + (_801 * _801)) > 1.0000000133514319600180897396058e-10)\n    {\n        _812 = atan(_801, _797) * 0.15915493667125701904296875;\n    }\n    else\n    {\n        _812 = 0.0;\n    }\n    vec2 param = tile_origin + vec2(1.0 + ((_812 - floor(_812)) * 64.0), 1.0 + (acos(clamp(dot(d, axis), -1.0, 1.0)) * 10.18591594696044921875));\n    return fa_atlas_fetch(param).x;\n}\n\nLightSample fa_light_sample_n(int li, vec3 world_pos, vec3 n)\n{\n    int param = li;\n    int _1043 = fa_light_base(param);\n    bool _1047 = fa_mesh_fs_params[1].w > 4.5;\n    int param_1 = _1043;\n    vec4 _1051 = fa_light_texel(param_1);\n    int param_2 = _1043 + 1;\n    vec4 _1056 = fa_light_texel(param_2);\n    float _1059 = _1056.w;\n    float atten = 1.0;\n    float dist = 0.0;\n    fa_light_tint = vec3(1.0);\n    bool _1071 = _1047 && (_1059 > 2.5);\n    fa_light_is_area = _1071;\n    bool _1073 = _1059 < 0.5;\n    vec3 l;\n    if (_1073)\n    {\n        l = normalize(_1051.xyz);\n        if (_1047)\n        {\n            int param_3 = _1043 + 6;\n            vec4 _1087 = fa_light_texel(param_3);\n            if (_1087.z > 0.5)\n            {\n                int param_4 = _1043 + 4;\n                vec4 _1097 = fa_light_texel(param_4);\n                int param_5 = _1043 + 5;\n                vec4 _1102 = fa_light_texel(param_5);\n                vec2 param_6 = _1087.xy;\n                vec2 param_7 = fract(vec2(dot(world_pos, _1097.xyz) * _1097.w, (-dot(world_pos, _1102.xyz)) * _1102.w) + vec2(0.5));\n                fa_light_tint = fa_cookie_sample(param_6, param_7);\n            }\n        }\n    }\n    else\n    {\n        vec3 _1132 = _1051.xyz;\n        vec3 _1134 = _1132 - world_pos;\n        vec3 to_light = _1134;\n        float _1137 = length(_1134);\n        float reach = _1137;\n        bool front = true;\n        if (_1071)\n        {\n            int param_8 = _1043 + 7;\n            reach = max(_1137 - fa_light_texel(param_8).w, 0.0);\n            int param_9 = _1043 + 4;\n            vec4 _1161 = fa_light_texel(param_9);\n            int param_10 = _1043 + 5;\n            vec4 _1166 = fa_light_texel(param_10);\n            int param_11 = _1043 + 6;\n            vec4 _1171 = fa_light_texel(param_11);\n            float _1172 = _1171.w;\n            int param_12 = _1043 + 2;\n            vec3 _1179 = normalize(fa_light_texel(param_12).xyz);\n            bool _1181 = _1172 > 1.5;\n            bool _1189;\n            if (!_1181)\n            {\n                _1189 = dot(_1179, to_light) < 0.0;\n            }\n            else\n            {\n                _1189 = _1181;\n            }\n            front = _1189;\n            vec3 r = vec3(0.0);\n            vec3 _1198 = fa_mesh_fs_params[0].xyz - world_pos;\n            bool _1202 = dot(n, n) > 0.5;\n            bool _1210;\n            if (_1202)\n            {\n                _1210 = dot(_1198, _1198) > 9.9999999600419720025001879548654e-13;\n            }\n            else\n            {\n                _1210 = _1202;\n            }\n            if (_1210)\n            {\n                r = reflect(-normalize(_1198), normalize(n));\n            }\n            vec3 param_13 = _1132;\n            vec3 param_14 = _1179;\n            vec3 param_15 = _1161.xyz;\n            vec3 param_16 = _1166.xyz;\n            float param_17 = _1161.w;\n            float param_18 = _1166.w;\n            float param_19 = _1172;\n            vec3 param_20 = world_pos;\n            vec3 param_21 = r;\n            to_light = fa_area_point(param_13, param_14, param_15, param_16, param_17, param_18, param_19, param_20, param_21) - world_pos;\n        }\n        float _1246 = length(to_light);\n        dist = _1246;\n        l = to_light / vec3(max(_1246, 9.9999997473787516355514526367188e-05));\n        float _1260 = reach / max(_1051.w, 0.001000000047497451305389404296875);\n        float _1266 = clamp(1.0 - (_1260 * _1260), 0.0, 1.0);\n        float _1268;\n        if (front)\n        {\n            _1268 = _1266 * _1266;\n        }\n        else\n        {\n            _1268 = 0.0;\n        }\n        atten = _1268;\n        bool _1279 = _1059 < 2.5;\n        if ((_1059 > 1.5) && _1279)\n        {\n            int param_22 = _1043 + 2;\n            vec4 _1287 = fa_light_texel(param_22);\n            float _1297 = _1287.w;\n            int param_23 = _1043 + 3;\n            vec4 _1302 = fa_light_texel(param_23);\n            float _1303 = _1302.x;\n            float cos_inner = _1303;\n            if (_1303 > 1.5)\n            {\n                cos_inner = mix(_1297, 1.0, 0.25);\n            }\n            atten *= smoothstep(_1297, cos_inner, dot(-l, normalize(_1287.xyz)));\n        }\n        if (_1047 && (_1059 < 1.5))\n        {\n            int param_24 = _1043 + 6;\n            vec4 _1327 = fa_light_texel(param_24);\n            if (_1327.z > 0.5)\n            {\n                vec3 _1335 = -to_light;\n                int param_25 = _1043 + 4;\n                int param_26 = _1043 + 5;\n                vec3 _1349 = fa_light_texel(param_25).xyz;\n                vec3 _1353 = fa_light_texel(param_26).xyz;\n                vec3 _1362 = vec3(dot(_1335, _1349), dot(_1335, _1353), dot(_1335, cross(_1349, _1353)));\n                vec3 param_27 = _1362;\n                int _1366 = fa_cube_face(param_27);\n                int param_28 = _1366;\n                vec3 param_29;\n                vec3 param_30;\n                fa_cube_face_basis(param_28, param_29, param_30);\n                vec2 _1393 = vec2(dot(_1362, cross(param_29, param_30)), dot(_1362, param_30)) / vec2(max(dot(_1362, param_29), 9.9999997473787516355514526367188e-05));\n                int _1397 = _1366 / 3;\n                vec2 param_31 = _1327.xy + (vec2(float(_1366 - (_1397 * 3)), float(_1397)) * 256.0);\n                vec2 param_32 = vec2(0.5 + (0.5 * _1393.x), 0.5 - (0.5 * _1393.y));\n                fa_light_tint = fa_cookie_sample(param_31, param_32);\n            }\n            int param_33 = _1043 + 7;\n            vec4 _1427 = fa_light_texel(param_33);\n            if (_1427.z > 0.5)\n            {\n                int param_34 = _1043 + 2;\n                int param_35 = _1043 + 4;\n                int param_36 = _1043 + 5;\n                vec2 param_37 = _1427.xy;\n                vec3 param_38 = -l;\n                vec3 param_39 = normalize(fa_light_texel(param_34).xyz);\n                vec3 param_40 = fa_light_texel(param_35).xyz;\n                vec3 param_41 = fa_light_texel(param_36).xyz;\n                atten *= fa_ies_sample(param_37, param_38, param_39, param_40, param_41);\n            }\n        }\n        else\n        {\n            if (_1047 && _1279)\n            {\n                int param_42 = _1043 + 6;\n                vec4 _1474 = fa_light_texel(param_42);\n                int param_43 = _1043 + 7;\n                vec4 _1479 = fa_light_texel(param_43);\n                bool _1482 = _1474.z > 0.5;\n                bool _1489;\n                if (!_1482)\n                {\n                    _1489 = _1479.z > 0.5;\n                }\n                else\n                {\n                    _1489 = _1482;\n                }\n                if (_1489)\n                {\n                    int param_44 = _1043 + 2;\n                    vec4 _1496 = fa_light_texel(param_44);\n                    vec3 _1500 = normalize(_1496.xyz);\n                    int param_45 = _1043 + 4;\n                    vec4 _1505 = fa_light_texel(param_45);\n                    int param_46 = _1043 + 5;\n                    vec4 _1510 = fa_light_texel(param_46);\n                    if (_1482)\n                    {\n                        vec3 _1518 = -to_light;\n                        float _1525 = _1496.w;\n                        float _1541 = 0.5 / max(dot(_1518, _1500) * (sqrt(max(1.0 - (_1525 * _1525), 0.0)) / max(_1525, 0.001000000047497451305389404296875)), 9.9999997473787516355514526367188e-05);\n                        vec2 param_47 = _1474.xy;\n                        vec2 param_48 = vec2(0.5 + (dot(_1518, _1505.xyz) * _1541), 0.5 - (dot(_1518, _1510.xyz) * _1541));\n                        fa_light_tint = fa_cookie_sample(param_47, param_48);\n                    }\n                    if (_1479.z > 0.5)\n                    {\n                        vec2 param_49 = _1479.xy;\n                        vec3 param_50 = -l;\n                        vec3 param_51 = _1500;\n                        vec3 param_52 = _1505.xyz;\n                        vec3 param_53 = _1510.xyz;\n                        atten *= fa_ies_sample(param_49, param_50, param_51, param_52, param_53);\n                    }\n                }\n            }\n        }\n    }\n    vec3 _9033 = _1056.xyz * atten;\n    if (_1047)\n    {\n        _9033 *= fa_light_tint;\n    }\n    int _1610;\n    if (_1073)\n    {\n        _1610 = 0;\n    }\n    else\n    {\n        _1610 = ((_1059 > 1.5) && (_1059 < 2.5)) ? 2 : 1;\n    }\n    return LightSample(l, _9033, atten, 1.0, dist, _1610);\n}\n\nfloat fa_shadow_split_at(int i)\n{\n    float _2336;\n    if (i == 0)\n    {\n        _2336 = fa_shadows[24].x;\n    }\n    else\n    {\n        float _2352;\n        if (i == 1)\n        {\n            _2352 = fa_shadows[24].y;\n        }\n        else\n        {\n            float _2360;\n            if (i == 2)\n            {\n                _2360 = fa_shadows[24].z;\n            }\n            else\n            {\n                _2360 = fa_shadows[24].w;\n            }\n            _2352 = _2360;\n        }\n        _2336 = _2352;\n    }\n    return _2336;\n}\n\nfloat fa_shadow_depth(inout vec2 uv, vec4 rect)\n{\n    uv = clamp(uv, rect.xy, rect.zw);\n    return textureLod(fa_shadow_tex_fa_shadow_smp, uv, 0.0).x;\n}\n\nfloat fa_shadow_fetch(vec2 uv, vec4 rect, vec3 conv)\n{\n    vec2 param = uv;\n    vec4 param_1 = rect;\n    float _2393 = fa_shadow_depth(param, param_1);\n    float _2397;\n    if (conv.x < 0.5)\n    {\n        _2397 = _2393;\n    }\n    else\n    {\n        _2397 = (conv.y * conv.z) / (conv.z - (_2393 * (conv.z - conv.y)));\n    }\n    return _2397;\n}\n\nfloat fa_shadow_noise()\n{\n    return fract(52.98291778564453125 * fract(dot(gl_FragCoord.xy, vec2(0.067110560834407806396484375, 0.005837149918079376220703125))));\n}\n\nvec2 fa_shadow_vogel_turn(vec2 d)\n{\n    return vec2((d.x * (-0.737368881702423095703125)) - (d.y * 0.675490319728851318359375), (d.y * (-0.737368881702423095703125)) + (d.x * 0.675490319728851318359375));\n}\n\nfloat fa_shadow_filter(vec2 uv, vec4 rect, float zr, float texel_m, float unit, float reach, float plane, vec3 conv, int mode, float k)\n{\n    if (mode == 1)\n    {\n        vec2 param = uv;\n        vec4 param_1 = rect;\n        vec3 param_2 = conv;\n        return float(zr <= fa_shadow_fetch(param, param_1, param_2));\n    }\n    float _2443 = fa_shadow_noise() * 6.283185482025146484375;\n    vec2 _2449 = vec2(cos(_2443), sin(_2443));\n    vec2 dir = _2449;\n    float radius = 1.5;\n    if (mode == 2)\n    {\n        float _2458;\n        if (k < 0.0)\n        {\n            _2458 = (-k) / max(zr, 0.100000001490116119384765625);\n        }\n        else\n        {\n            _2458 = k;\n        }\n        float _2477 = clamp((_2458 * reach) / texel_m, 3.0, 12.0);\n        float sum = 0.0;\n        float cnt = 0.0;\n        for (int i = 0; i < 16; i++)\n        {\n            float _2496 = sqrt((float(i) + 0.5) * 0.0625) * _2477;\n            vec2 param_3 = uv + (dir * (fa_shadows[26].zw * _2496));\n            vec4 param_4 = rect;\n            vec3 param_5 = conv;\n            float _2510 = fa_shadow_fetch(param_3, param_4, param_5);\n            if (_2510 < (zr - (_2496 * plane)))\n            {\n                sum += _2510;\n                cnt += 1.0;\n            }\n            vec2 param_6 = dir;\n            dir = fa_shadow_vogel_turn(param_6);\n        }\n        if (cnt < 0.5)\n        {\n            return 1.0;\n        }\n        float _2538 = sum / cnt;\n        float _2548;\n        if (k < 0.0)\n        {\n            _2548 = (-k) / max(_2538, 0.0500000007450580596923828125);\n        }\n        else\n        {\n            _2548 = k;\n        }\n        radius = clamp(((max(zr - _2538, 0.0) * unit) * _2548) / texel_m, 1.5, 16.0);\n        dir = _2449;\n    }\n    float lit = 0.0;\n    int _2574 = (mode == 2) ? 24 : 16;\n    for (int i_1 = 0; i_1 < _2574; i_1++)\n    {\n        float _2593 = sqrt((float(i_1) + 0.5) / float(_2574)) * radius;\n        vec2 param_7 = uv + (dir * (fa_shadows[26].zw * _2593));\n        vec4 param_8 = rect;\n        vec3 param_9 = conv;\n        lit += float((zr - (_2593 * plane)) <= fa_shadow_fetch(param_7, param_8, param_9));\n        vec2 param_10 = dir;\n        dir = fa_shadow_vogel_turn(param_10);\n    }\n    return lit / float(_2574);\n}\n\nfloat fa_shadow_cascade(int ci, vec3 world, vec3 n, vec3 l)\n{\n    float _2639 = max(fa_shadows[ci * 1 + 20].y, 0.001000000047497451305389404296875);\n    float _2644 = clamp(dot(n, l), 0.0, 1.0);\n    float _2650 = sqrt(1.0 - (_2644 * _2644));\n    float _2658 = min(_2650 / max(_2644, 0.20000000298023223876953125), 4.0);\n    float _2663;\n    if (fa_shadows[26].y > 0.0)\n    {\n        _2663 = fa_shadows[26].y;\n    }\n    else\n    {\n        _2663 = 1.5 * fa_shadows[ci * 1 + 20].x;\n    }\n    vec4 _2688 = mat4(fa_shadows[ci * 4 + 0], fa_shadows[ci * 4 + 1], fa_shadows[ci * 4 + 2], fa_shadows[ci * 4 + 3]) * vec4(world + (n * (_2663 * _2650)), 1.0);\n    float _2695 = _2688.x;\n    bool _2698 = _2695 < fa_shadows[ci * 1 + 16].x;\n    bool _2707;\n    if (!_2698)\n    {\n        _2707 = _2695 > fa_shadows[ci * 1 + 16].z;\n    }\n    else\n    {\n        _2707 = _2698;\n    }\n    bool _2716;\n    if (!_2707)\n    {\n        _2716 = _2688.y < fa_shadows[ci * 1 + 16].y;\n    }\n    else\n    {\n        _2716 = _2707;\n    }\n    bool _2725;\n    if (!_2716)\n    {\n        _2725 = _2688.y > fa_shadows[ci * 1 + 16].w;\n    }\n    else\n    {\n        _2725 = _2716;\n    }\n    bool _2732;\n    if (!_2725)\n    {\n        _2732 = _2688.z > 1.0;\n    }\n    else\n    {\n        _2732 = _2725;\n    }\n    if (_2732)\n    {\n        return -1.0;\n    }\n    float _2740;\n    if (fa_shadows[26].x > 0.0)\n    {\n        _2740 = fa_shadows[26].x;\n    }\n    else\n    {\n        _2740 = 1.5 * fa_shadows[ci * 1 + 20].x;\n    }\n    vec2 param = _2688.xy;\n    vec4 param_1 = fa_shadows[ci * 1 + 16];\n    float param_2 = _2688.z - ((_2740 * (1.0 + (0.5 * _2658))) / _2639);\n    float param_3 = fa_shadows[ci * 1 + 20].x;\n    float param_4 = _2639;\n    float param_5 = _2639 * 0.25;\n    float param_6 = ((fa_shadows[ci * 1 + 20].x * min(_2658, 3.0)) * 0.5) / _2639;\n    vec3 param_7 = vec3(0.0);\n    int param_8 = int(fa_shadows[25].z + 0.5);\n    float param_9 = fa_shadows[25].w;\n    return fa_shadow_filter(param, param_1, param_2, param_3, param_4, param_5, param_6, param_7, param_8, param_9);\n}\n\nfloat fa_shadow_sun(vec3 world, vec3 n, vec3 l)\n{\n    if (fa_mesh_fs_params[5].z < 0.5)\n    {\n        return 1.0;\n    }\n    int _3118 = int(fa_shadows[25].x + 0.5);\n    if (_3118 < 1)\n    {\n        return 1.0;\n    }\n    float _3133 = dot(world - fa_shadows[27].xyz, fa_shadows[28].xyz);\n    int param = _3118 - 1;\n    if (_3133 > fa_shadow_split_at(param))\n    {\n        return 1.0;\n    }\n    int ci = 0;\n    bool _3145 = _3118 > 1;\n    bool _3152;\n    if (_3145)\n    {\n        _3152 = _3133 > fa_shadows[24].x;\n    }\n    else\n    {\n        _3152 = _3145;\n    }\n    if (_3152)\n    {\n        ci = 1;\n    }\n    bool _3156 = _3118 > 2;\n    bool _3163;\n    if (_3156)\n    {\n        _3163 = _3133 > fa_shadows[24].y;\n    }\n    else\n    {\n        _3163 = _3156;\n    }\n    if (_3163)\n    {\n        ci = 2;\n    }\n    bool _3167 = _3118 > 3;\n    bool _3174;\n    if (_3167)\n    {\n        _3174 = _3133 > fa_shadows[24].z;\n    }\n    else\n    {\n        _3174 = _3167;\n    }\n    if (_3174)\n    {\n        ci = 3;\n    }\n    float s = -1.0;\n    float s2 = -1.0;\n    float t = 0.0;\n    int _3185 = min(_3118, 4);\n    float _3226;\n    for (int c = ci; c < _3185; c++)\n    {\n        int param_1 = c;\n        vec3 param_2 = world;\n        vec3 param_3 = n;\n        vec3 param_4 = l;\n        float _3205 = fa_shadow_cascade(param_1, param_2, param_3, param_4);\n        if (s >= 0.0)\n        {\n            s2 = _3205;\n            break;\n        }\n        if (_3205 < 0.0)\n        {\n            continue;\n        }\n        s = _3205;\n        ci = c;\n        if (fa_shadows[25].y > 0.0)\n        {\n            if (ci > 0)\n            {\n                int param_5 = ci - 1;\n                _3226 = fa_shadow_split_at(param_5);\n            }\n            else\n            {\n                _3226 = fa_shadows[28].w;\n            }\n            int param_6 = ci;\n            float _3245 = fa_shadows[25].y * max(fa_shadow_split_at(param_6) - _3226, 9.9999997473787516355514526367188e-05);\n            int param_7 = ci;\n            t = clamp((_3133 - (fa_shadow_split_at(param_7) - _3245)) / _3245, 0.0, 1.0);\n        }\n        if (t <= 0.0)\n        {\n            break;\n        }\n    }\n    if (s < 0.0)\n    {\n        return 1.0;\n    }\n    if (t > 0.0)\n    {\n        float _3277;\n        if ((ci + 1) < _3118)\n        {\n            _3277 = (s2 < 0.0) ? s : s2;\n        }\n        else\n        {\n            _3277 = 1.0;\n        }\n        s = mix(s, _3277, t);\n    }\n    return s;\n}\n\nfloat fa_shadow_factor(vec3 n, vec3 l)\n{\n    vec3 param = fa_world_pos;\n    vec3 param_1 = n;\n    vec3 param_2 = l;\n    return fa_shadow_sun(param, param_1, param_2);\n}\n\nfloat fa_shadow_local(int li, vec3 lpos, vec3 world, vec3 n, vec3 l)\n{\n    bool _2798 = fa_mesh_fs_params[5].z < 0.5;\n    bool _2805;\n    if (!_2798)\n    {\n        _2805 = fa_shadows[29].x < 0.5;\n    }\n    else\n    {\n        _2805 = _2798;\n    }\n    if (_2805)\n    {\n        return 1.0;\n    }\n    int param = (int(fa_shadows[29].x + 0.5) - 1) + li;\n    vec4 _2818 = fa_light_texel(param);\n    float _2819 = _2818.x;\n    if (_2819 < 0.0)\n    {\n        return 1.0;\n    }\n    int _2828 = int(_2819 + 0.5);\n    int param_1 = _2828;\n    vec4 _2832 = fa_light_texel(param_1);\n    int param_2 = _2828 + 1;\n    vec4 _2837 = fa_light_texel(param_2);\n    float fade = 1.0;\n    float _2840 = _2832.y;\n    if (_2840 > 0.0)\n    {\n        float _2857 = 1.0 - smoothstep(0.75 * _2840, _2840, length(world - fa_shadows[27].xyz));\n        fade = _2857;\n        if (_2857 <= 0.0)\n        {\n            return 1.0;\n        }\n    }\n    int face = 0;\n    if (_2832.x > 1.5)\n    {\n        vec3 param_3 = world - lpos;\n        face = fa_cube_face(param_3);\n    }\n    int _2881 = (_2828 + 2) + (face * 6);\n    int param_4 = _2881;\n    int param_5 = _2881 + 1;\n    int param_6 = _2881 + 3;\n    vec4 _2895 = fa_light_texel(param_6);\n    int param_7 = _2881 + 4;\n    vec4 _2900 = fa_light_texel(param_7);\n    int param_8 = _2881 + 5;\n    vec4 _2905 = fa_light_texel(param_8);\n    float _2917 = _2905.x * max(dot(_2895, vec4(world, 1.0)), 0.001000000047497451305389404296875);\n    float _2922 = clamp(dot(n, l), 0.0, 1.0);\n    float _2945 = clamp(dot(n, _2895.xyz), -1.0, 1.0);\n    float _2964 = min(sqrt(1.0 - (_2945 * _2945)) / max(abs(dot(n, world - lpos)) / max(dot(_2895, vec4(world, 1.0)), 0.001000000047497451305389404296875), 0.20000000298023223876953125), 4.0);\n    float _2967 = _2837.y;\n    float _2969;\n    if (_2967 > 0.0)\n    {\n        _2969 = _2967;\n    }\n    else\n    {\n        _2969 = 1.5 * _2917;\n    }\n    vec4 _2989 = vec4(world + (n * (_2969 * sqrt(1.0 - (_2922 * _2922)))), 1.0);\n    float _2993 = dot(_2895, _2989);\n    float _2996 = _2905.y;\n    if (_2993 < _2996)\n    {\n        return 1.0;\n    }\n    vec2 _3011 = vec2(dot(fa_light_texel(param_4), _2989), dot(fa_light_texel(param_5), _2989)) / vec2(_2993);\n    float _3013 = _3011.x;\n    bool _3016 = _3013 < _2900.x;\n    bool _3025;\n    if (!_3016)\n    {\n        _3025 = _3013 > _2900.z;\n    }\n    else\n    {\n        _3025 = _3016;\n    }\n    bool _3034;\n    if (!_3025)\n    {\n        _3034 = _3011.y < _2900.y;\n    }\n    else\n    {\n        _3034 = _3025;\n    }\n    bool _3043;\n    if (!_3034)\n    {\n        _3043 = _3011.y > _2900.w;\n    }\n    else\n    {\n        _3043 = _3034;\n    }\n    if (_3043)\n    {\n        return 1.0;\n    }\n    float _3049 = _2837.x;\n    float _3051;\n    if (_3049 > 0.0)\n    {\n        _3051 = _3049;\n    }\n    else\n    {\n        _3051 = 1.5 * _2917;\n    }\n    vec2 param_9 = _3011;\n    vec4 param_10 = _2900;\n    float param_11 = _2993 - (_3051 * (1.0 + (0.5 * _2964)));\n    float param_12 = _2917;\n    float param_13 = 1.0;\n    float param_14 = _2905.z * 0.25;\n    float param_15 = (_2917 * min(_2964, 3.0)) * 0.5;\n    vec3 param_16 = vec3(1.0, _2996, _2905.z);\n    int param_17 = int(_2832.z + 0.5);\n    float param_18 = _2832.w;\n    return mix(1.0, fa_shadow_filter(param_9, param_10, param_11, param_12, param_13, param_14, param_15, param_16, param_17, param_18), fade);\n}\n\nfloat fa_contact_shadow(int li, vec3 world, vec3 gn, vec3 l, float dist)\n{\n    bool _5207 = fa_mesh_fs_params[24].x < 0.5;\n    bool _5214;\n    if (!_5207)\n    {\n        _5214 = fa_shadows[29].x < 0.5;\n    }\n    else\n    {\n        _5214 = _5207;\n    }\n    if (_5214)\n    {\n        return 1.0;\n    }\n    int param = (int(fa_shadows[29].x + 0.5) - 1) + li;\n    vec4 _5227 = fa_light_texel(param);\n    float _5228 = _5227.y;\n    float len = _5228;\n    if (_5228 <= 0.0)\n    {\n        return 1.0;\n    }\n    float _5240 = length(world - fa_mesh_fs_params[0].xyz);\n    float _5250 = 1.0 - smoothstep(0.5 * fa_mesh_fs_params[25].x, fa_mesh_fs_params[25].x, _5240);\n    if (_5250 <= 0.0)\n    {\n        return 1.0;\n    }\n    float _5256 = len;\n    float _5259 = min(_5256, 0.89999997615814208984375 * dist);\n    len = _5259;\n    float _5264 = 0.004999999888241291046142578125 + (0.0030000000260770320892333984375 * _5240);\n    float _5269 = _5264 + (0.5 * _5259);\n    vec3 _5275 = world + (gn * _5264);\n    float _5277 = fa_shadow_noise();\n    float occ = 0.0;\n    float _5341;\n    for (int k = 0; k < 12; k++)\n    {\n        float _5292 = (float(k) + _5277) * 0.083333335816860198974609375;\n        vec3 _5300 = _5275 + (l * (_5292 * len));\n        vec4 _5306 = vec4(_5300, 1.0);\n        float _5312 = dot(fa_mesh_fs_params[28], _5306);\n        if (_5312 < 9.9999997473787516355514526367188e-05)\n        {\n            break;\n        }\n        vec2 _5332 = vec2(dot(fa_mesh_fs_params[26], _5306), dot(fa_mesh_fs_params[27], _5306)) / vec2(_5312);\n        float _5336 = _5332.x * 0.5;\n        float _5337 = _5336 + 0.5;\n        if (fa_mesh_fs_params[24].y > 0.5)\n        {\n            _5341 = (_5332.y * 0.5) + 0.5;\n        }\n        else\n        {\n            _5341 = 0.5 - (_5332.y * 0.5);\n        }\n        bool _5357 = _5337 < 0.0;\n        bool _5364;\n        if (!_5357)\n        {\n            _5364 = _5337 >= 1.0;\n        }\n        else\n        {\n            _5364 = _5357;\n        }\n        bool _5371;\n        if (!_5364)\n        {\n            _5371 = _5341 < 0.0;\n        }\n        else\n        {\n            _5371 = _5364;\n        }\n        bool _5378;\n        if (!_5371)\n        {\n            _5378 = _5341 >= 1.0;\n        }\n        else\n        {\n            _5378 = _5371;\n        }\n        if (_5378)\n        {\n            break;\n        }\n        vec4 _5405 = texelFetch(fa_screen_tex_fa_shadow_smp, clamp(ivec2(vec2(_5337, _5341) * fa_mesh_fs_params[24].zw), ivec2(0), ivec2(fa_mesh_fs_params[24].zw) - ivec2(1)), 0);\n        if (_5405.w < 0.5)\n        {\n            continue;\n        }\n        float _5424 = (dot(fa_mesh_fs_params[29].xyz, _5300) + fa_mesh_fs_params[29].w) - _5405.x;\n        if ((_5424 > _5264) && (_5424 < _5269))\n        {\n            occ = max(occ, (1.0 - (_5292 * _5292)) * smoothstep(0.0, 0.0500000007450580596923828125, min(min(_5337, 0.5 - _5336), min(_5341, 1.0 - _5341))));\n        }\n    }\n    return 1.0 - (occ * _5250);\n}\n\nLightSample fa_light_shadowed(int li, vec3 world_pos, vec3 gn)\n{\n    int param = li;\n    float _5890 = fa_baked_keep(param);\n    if (_5890 <= 0.0)\n    {\n        int param_1 = li;\n        return LightSample(vec3(0.0, 1.0, 0.0), vec3(0.0), 0.0, 1.0, 0.0, int(fa_light_type(param_1) + 0.5));\n    }\n    int param_2 = li;\n    vec3 param_3 = world_pos;\n    vec3 param_4 = gn;\n    LightSample _5916 = fa_light_sample_n(param_2, param_3, param_4);\n    vec3 _9102 = _5916.color;\n    float _9103 = _5916.attenuation;\n    float _9104 = _5916.shadow;\n    bool _5919 = _5916.type == 0;\n    if (_5919 && (li == 0))\n    {\n        vec3 param_5 = gn;\n        vec3 param_6 = _5916.direction;\n        float _5930 = fa_shadow_factor(param_5, param_6);\n        _9104 = _5930;\n        _9102 *= _5930;\n    }\n    else\n    {\n        bool _5941 = _5916.type != 0;\n        bool _5947;\n        if (_5941)\n        {\n            _5947 = _9103 > 0.0;\n        }\n        else\n        {\n            _5947 = _5941;\n        }\n        if (_5947)\n        {\n            int param_7 = li;\n            int param_8 = fa_light_base(param_7);\n            int param_9 = li;\n            vec3 param_10 = fa_light_texel(param_8).xyz;\n            vec3 param_11 = world_pos;\n            vec3 param_12 = gn;\n            vec3 param_13 = _5916.direction;\n            float _5966 = fa_shadow_local(param_9, param_10, param_11, param_12, param_13);\n            _9104 = _5966;\n            _9102 *= _5966;\n        }\n    }\n    bool _5976 = fa_mesh_fs_params[24].x > 0.5;\n    bool _5982;\n    if (_5976)\n    {\n        _5982 = _9103 > 0.0;\n    }\n    else\n    {\n        _5982 = _5976;\n    }\n    if (_5982)\n    {\n        float _5989;\n        if (_5919)\n        {\n            _5989 = 1000000000.0;\n        }\n        else\n        {\n            _5989 = _5916._distance;\n        }\n        int param_14 = li;\n        vec3 param_15 = world_pos;\n        vec3 param_16 = gn;\n        vec3 param_17 = _5916.direction;\n        float param_18 = _5989;\n        float _6007 = fa_contact_shadow(param_14, param_15, param_16, param_17, param_18);\n        _9104 *= _6007;\n        _9102 *= _6007;\n    }\n    float _6020 = _9103;\n    float _6021 = _6020 * _5890;\n    _9103 = _6021;\n    vec3 _6025 = _9102;\n    vec3 _6026 = _6025 * _5890;\n    _9102 = _6026;\n    return LightSample(_5916.direction, _6026, _6021, _9104, _5916._distance, _5916.type);\n}\n\nvec3 fa_ltc_tangent(vec3 n, vec3 v)\n{\n    vec3 _6060 = v - (n * dot(v, n));\n    vec3 t = _6060;\n    float _6064 = dot(_6060, _6060);\n    float l2 = _6064;\n    if (_6064 < 1.0000000133514319600180897396058e-10)\n    {\n        vec3 _6074;\n        if (abs(n.z) < 0.999000012874603271484375)\n        {\n            _6074 = cross(n, vec3(0.0, 0.0, 1.0));\n        }\n        else\n        {\n            _6074 = cross(n, vec3(1.0, 0.0, 0.0));\n        }\n        t = _6074;\n        l2 = dot(_6074, _6074);\n    }\n    return t * inversesqrt(l2);\n}\n\nvec3 fa_ltc_local(vec3 t1, vec3 n, vec3 p)\n{\n    return vec3(dot(t1, p), dot(cross(n, t1), p), dot(n, p));\n}\n\nvec2 fa_ltc_uv(float roughness, float ndv)\n{\n    return ((vec2(clamp((roughness - 0.0500000007450580596923828125) * 1.0526316165924072265625, 0.0, 1.0), sqrt(clamp(1.0 - ndv, 0.0, 1.0))) * 63.0) + vec2(0.5)) * vec2(0.015625);\n}\n\nvec3 fa_oct_vertex(int j, vec3 pc, vec3 ex, vec3 ey)\n{\n    float _6461;\n    if ((j == 0) || (j == 7))\n    {\n        _6461 = 0.92387950420379638671875;\n    }\n    else\n    {\n        float _6471;\n        if ((j == 3) || (j == 4))\n        {\n            _6471 = -0.92387950420379638671875;\n        }\n        else\n        {\n            _6471 = ((j == 1) || (j == 6)) ? 0.3826834261417388916015625 : (-0.3826834261417388916015625);\n        }\n        _6461 = _6471;\n    }\n    float _6492;\n    if ((j == 1) || (j == 2))\n    {\n        _6492 = 0.92387950420379638671875;\n    }\n    else\n    {\n        float _6501;\n        if ((j == 5) || (j == 6))\n        {\n            _6501 = -0.92387950420379638671875;\n        }\n        else\n        {\n            _6501 = ((j == 0) || (j == 3)) ? 0.3826834261417388916015625 : (-0.3826834261417388916015625);\n        }\n        _6492 = _6501;\n    }\n    return (pc + (ex * _6461)) + (ey * _6492);\n}\n\nvec3 fa_ltc_edge_vector(vec3 a, vec3 b)\n{\n    float _6109 = dot(a, a);\n    float _6113 = dot(b, b);\n    if ((_6109 < 1.0000000195414813782625560981111e-24) || (_6113 < 1.0000000195414813782625560981111e-24))\n    {\n        return vec3(0.0);\n    }\n    vec3 _6127 = a * inversesqrt(_6109);\n    vec3 _6132 = b * inversesqrt(_6113);\n    float _6136 = dot(_6127, _6132);\n    float _6139 = abs(_6136);\n    float g = (((((((((((0.0416471660137176513671875 * _6139) - 0.1924748718738555908203125) * _6139) + 0.4179156124591827392578125) * _6139) - 0.616057217121124267578125) * _6139) + 0.777722418308258056640625) * _6139) - 0.999542415142059326171875) * _6139) + 1.570791721343994140625;\n    if (_6136 < 0.0)\n    {\n        g = (3.1415927410125732421875 * inversesqrt(max(1.0 - (_6136 * _6136), 1.0000000116860974230803549289703e-07))) - g;\n    }\n    return cross(_6127, _6132) * g;\n}\n\nvoid fa_ltc_clip_edge(vec3 a, vec3 b, inout vec3 sum, inout vec3 leave, inout vec3 enter, inout vec2 seen)\n{\n    bool _6196 = a.z > 0.0;\n    bool _6200 = b.z > 0.0;\n    if (_6196 && _6200)\n    {\n        vec3 param = a;\n        vec3 param_1 = b;\n        sum += fa_ltc_edge_vector(param, param_1);\n    }\n    else\n    {\n        if (_6196 != _6200)\n        {\n            vec3 _6235 = a + ((b - a) * (a.z / (a.z - b.z)));\n            _6235.z = 0.0;\n            if (_6196)\n            {\n                vec3 param_2 = a;\n                vec3 param_3 = _6235;\n                sum += fa_ltc_edge_vector(param_2, param_3);\n                leave = _6235;\n                seen.x = 1.0;\n            }\n            else\n            {\n                vec3 param_4 = _6235;\n                vec3 param_5 = b;\n                sum += fa_ltc_edge_vector(param_4, param_5);\n                enter = _6235;\n                seen.y = 1.0;\n            }\n        }\n    }\n}\n\nfloat fa_ltc_quad(vec4 abcd, vec3 p0, vec3 p1, vec3 p2, vec3 p3)\n{\n    vec3 _6284 = vec3((abcd.x * p0.x) + (abcd.y * p0.z), p0.y, (abcd.z * p0.x) + (abcd.w * p0.z));\n    vec3 _6310 = vec3((abcd.x * p1.x) + (abcd.y * p1.z), p1.y, (abcd.z * p1.x) + (abcd.w * p1.z));\n    vec3 _6336 = vec3((abcd.x * p2.x) + (abcd.y * p2.z), p2.y, (abcd.z * p2.x) + (abcd.w * p2.z));\n    vec3 _6362 = vec3((abcd.x * p3.x) + (abcd.y * p3.z), p3.y, (abcd.z * p3.x) + (abcd.w * p3.z));\n    vec3 sum = vec3(0.0);\n    vec3 leave = vec3(0.0);\n    vec3 enter = vec3(0.0);\n    vec3 param = _6284;\n    vec3 param_1 = _6310;\n    vec3 param_2 = vec3(0.0);\n    vec3 param_3 = vec3(0.0);\n    vec3 param_4 = vec3(0.0);\n    vec2 param_5 = vec2(0.0);\n    fa_ltc_clip_edge(param, param_1, param_2, param_3, param_4, param_5);\n    sum = param_2;\n    leave = param_3;\n    enter = param_4;\n    vec3 param_6 = _6310;\n    vec3 param_7 = _6336;\n    vec3 param_8 = param_2;\n    vec3 param_9 = param_3;\n    vec3 param_10 = param_4;\n    vec2 param_11 = param_5;\n    fa_ltc_clip_edge(param_6, param_7, param_8, param_9, param_10, param_11);\n    sum = param_8;\n    leave = param_9;\n    enter = param_10;\n    vec3 param_12 = _6336;\n    vec3 param_13 = _6362;\n    vec3 param_14 = param_8;\n    vec3 param_15 = param_9;\n    vec3 param_16 = param_10;\n    vec2 param_17 = param_11;\n    fa_ltc_clip_edge(param_12, param_13, param_14, param_15, param_16, param_17);\n    sum = param_14;\n    leave = param_15;\n    enter = param_16;\n    vec3 param_18 = _6362;\n    vec3 param_19 = _6284;\n    vec3 param_20 = param_14;\n    vec3 param_21 = param_15;\n    vec3 param_22 = param_16;\n    vec2 param_23 = param_17;\n    fa_ltc_clip_edge(param_18, param_19, param_20, param_21, param_22, param_23);\n    sum = param_20;\n    leave = param_21;\n    enter = param_22;\n    if ((param_23.x * param_23.y) > 0.5)\n    {\n        vec3 param_24 = leave;\n        vec3 param_25 = enter;\n        sum += fa_ltc_edge_vector(param_24, param_25);\n    }\n    return sum.z * 0.15915493667125701904296875;\n}\n\nvec2 fa_area_forms(vec4 m, float shape, vec3 pc, vec3 ex, vec3 ey)\n{\n    int _6530 = ((shape < 0.5) || (shape > 1.5)) ? 1 : 3;\n    vec2 sum = vec2(0.0);\n    int _6548;\n    for (int k = 0; k < (2 * _6530); k++)\n    {\n        bool _6545 = k >= _6530;\n        if (_6545)\n        {\n            _6548 = k - _6530;\n        }\n        else\n        {\n            _6548 = k;\n        }\n        vec3 p0 = (pc - ex) - ey;\n        vec3 p1 = (pc + ex) - ey;\n        vec3 p2 = (pc + ex) + ey;\n        vec3 p3 = (pc - ex) + ey;\n        if (_6530 == 3)\n        {\n            int param = 0;\n            vec3 param_1 = pc;\n            vec3 param_2 = ex;\n            vec3 param_3 = ey;\n            p0 = fa_oct_vertex(param, param_1, param_2, param_3);\n            int _6594 = 2 * _6548;\n            int param_4 = _6594 + 1;\n            vec3 param_5 = pc;\n            vec3 param_6 = ex;\n            vec3 param_7 = ey;\n            p1 = fa_oct_vertex(param_4, param_5, param_6, param_7);\n            int param_8 = _6594 + 2;\n            vec3 param_9 = pc;\n            vec3 param_10 = ex;\n            vec3 param_11 = ey;\n            p2 = fa_oct_vertex(param_8, param_9, param_10, param_11);\n            int param_12 = _6594 + 3;\n            vec3 param_13 = pc;\n            vec3 param_14 = ex;\n            vec3 param_15 = ey;\n            p3 = fa_oct_vertex(param_12, param_13, param_14, param_15);\n        }\n        bvec4 _6631 = bvec4(_6545);\n        vec4 param_16 = vec4(_6631.x ? m.x : vec4(1.0, 0.0, 0.0, 1.0).x, _6631.y ? m.y : vec4(1.0, 0.0, 0.0, 1.0).y, _6631.z ? m.z : vec4(1.0, 0.0, 0.0, 1.0).z, _6631.w ? m.w : vec4(1.0, 0.0, 0.0, 1.0).w);\n        vec3 param_17 = p0;\n        vec3 param_18 = p1;\n        vec3 param_19 = p2;\n        vec3 param_20 = p3;\n        float _6642 = fa_ltc_quad(param_16, param_17, param_18, param_19, param_20);\n        if (_6545)\n        {\n            vec2 _9329 = sum;\n            _9329.y = _9329.y + _6642;\n            sum = _9329;\n        }\n        else\n        {\n            vec2 _9332 = sum;\n            _9332.x = _9332.x + _6642;\n            sum = _9332;\n        }\n    }\n    return abs(sum);\n}\n\nvec3 fa_area_shade(int li, vec3 world_pos, vec3 n, vec3 v, vec3 diffuse_color, vec3 f0, float f90, float roughness, float ndv, float window)\n{\n    int param = li;\n    int _6666 = fa_light_base(param);\n    int param_1 = _6666;\n    int param_2 = _6666 + 1;\n    int param_3 = _6666 + 2;\n    int param_4 = _6666 + 4;\n    vec4 _6688 = fa_light_texel(param_4);\n    int param_5 = _6666 + 5;\n    vec4 _6693 = fa_light_texel(param_5);\n    int param_6 = _6666 + 6;\n    vec4 _6698 = fa_light_texel(param_6);\n    float _6699 = _6698.w;\n    vec3 _6704 = fa_light_texel(param_1).xyz - world_pos;\n    bool _6706 = _6699 < 1.5;\n    bool _6713;\n    if (_6706)\n    {\n        _6713 = dot(normalize(fa_light_texel(param_3).xyz), _6704) >= 0.0;\n    }\n    else\n    {\n        _6713 = _6706;\n    }\n    if (_6713)\n    {\n        return vec3(0.0);\n    }\n    bool _6722 = (_6699 > 0.5) && _6706;\n    float _6726 = _6722 ? 1.0539000034332275390625 : 1.0;\n    vec3 _6729 = _6688.xyz;\n    float _6731 = _6688.w;\n    vec3 _6737 = _6693.xyz;\n    float _6739 = _6693.w;\n    vec3 up = _6737 * (_6739 * _6726);\n    float _6745;\n    if (_6722)\n    {\n        _6745 = (3.1415927410125732421875 * _6731) * _6731;\n    }\n    else\n    {\n        _6745 = (4.0 * _6731) * _6739;\n    }\n    if (_6699 > 1.5)\n    {\n        vec3 _6771 = cross(_6729, -_6704);\n        vec3 perp = _6771;\n        float _6775 = dot(_6771, _6771);\n        vec3 _6778;\n        if (_6775 > 1.0000000133514319600180897396058e-10)\n        {\n            _6778 = perp * inversesqrt(_6775);\n        }\n        else\n        {\n            _6778 = _6737;\n        }\n        perp = _6778;\n        up = _6778 * _6739;\n    }\n    float _6799 = max(_6745, 9.9999999747524270787835121154785e-07);\n    vec3 param_7 = n;\n    vec3 param_8 = v;\n    vec3 _6809 = fa_ltc_tangent(param_7, param_8);\n    vec3 param_9 = _6809;\n    vec3 param_10 = n;\n    vec3 param_11 = _6704;\n    vec3 param_12 = _6809;\n    vec3 param_13 = n;\n    vec3 param_14 = _6729 * (_6731 * _6726);\n    vec3 param_15 = _6809;\n    vec3 param_16 = n;\n    vec3 param_17 = up;\n    float param_18 = roughness;\n    float param_19 = ndv;\n    vec2 _6840 = fa_ltc_uv(param_18, param_19) * 64.0;\n    vec2 param_20 = _6840;\n    vec2 param_21 = _6840 + vec2(64.0, 0.0);\n    vec4 _6850 = fa_atlas_fetch(param_21);\n    vec4 param_22 = fa_atlas_fetch(param_20);\n    float param_23 = _6699;\n    vec3 param_24 = fa_ltc_local(param_9, param_10, param_11);\n    vec3 param_25 = fa_ltc_local(param_12, param_13, param_14);\n    vec3 param_26 = fa_ltc_local(param_15, param_16, param_17);\n    vec2 _6862 = fa_area_forms(param_22, param_23, param_24, param_25, param_26);\n    return (((diffuse_color * _6862.x) + (((f0 * _6850.x) + ((vec3(f90) - f0) * _6850.y)) * _6862.y)) * fa_light_texel(param_2).xyz) * ((((3.1415927410125732421875 * dot(_6704, _6704)) + _6799) / _6799) * window);\n}\n\nvec3 fa_light_rgb(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 1;\n    return fa_light_texel(param_1).xyz;\n}\n\nfloat fa_d_charlie(float alpha, float ndh)\n{\n    float _4944 = 1.0 / alpha;\n    return ((2.0 + _4944) * pow(sqrt(max(1.0 - (ndh * ndh), 9.9999997473787516355514526367188e-05)), _4944)) * 0.15915493667125701904296875;\n}\n\nfloat fa_v_ashikhmin(float ndl, float ndv)\n{\n    return clamp(0.25 / max((ndl + ndv) - (ndl * ndv), 9.9999997473787516355514526367188e-05), 0.0, 1.0);\n}\n\nfloat fa_layers_coat(FaLayers L, vec3 l, vec3 h, float vdh)\n{\n    float _4979 = max(dot(L.nc, l), 0.0);\n    float _4985 = max(dot(L.nc, h), 0.0);\n    float _4994 = ((_4985 * _4985) * (L.coat_a2 - 1.0)) + 1.0;\n    return (((L.coat * (0.039999999105930328369140625 + (0.959999978542327880859375 * pow(clamp(1.0 - vdh, 0.0, 1.0), 5.0)))) * (((L.coat_a2 / ((3.1415927410125732421875 * _4994) * _4994)) * (0.5 / max(mix((2.0 * _4979) * L.coat_ndv, _4979 + L.coat_ndv, L.coat_alpha), 9.9999997473787516355514526367188e-05))) * 3.1415927410125732421875)) * step(9.9999997473787516355514526367188e-05, _4979)) * _4979;\n}\n\nvec3 fa_area_layers(FaLayers L, vec3 base, int li, vec3 n, vec3 v, vec3 l, float ndv, float window)\n{\n    float _6899;\n    if (L.sheen_on)\n    {\n        _6899 = L.sheen_scale;\n    }\n    else\n    {\n        _6899 = 1.0;\n    }\n    vec3 result = base * (L.keep * _6899);\n    vec3 _6912 = normalize(l + v);\n    int param = li;\n    vec3 _6923 = fa_light_rgb(param) * window;\n    if (L.sheen_on)\n    {\n        float _6932 = max(dot(n, l), 0.0);\n        float param_1 = L.sheen_alpha;\n        float param_2 = max(dot(n, _6912), 0.0);\n        float param_3 = _6932;\n        float param_4 = ndv;\n        result += ((L.sheen * _6923) * (((((fa_d_charlie(param_1, param_2) * fa_v_ashikhmin(param_3, param_4)) * 3.1415927410125732421875) * step(9.9999997473787516355514526367188e-05, _6932)) * _6932) * L.keep));\n    }\n    if (L.coat > 0.0)\n    {\n        FaLayers param_5 = L;\n        vec3 param_6 = l;\n        vec3 param_7 = _6912;\n        float param_8 = max(dot(v, _6912), 0.0);\n        result += (_6923 * fa_layers_coat(param_5, param_6, param_7, param_8));\n    }\n    return result;\n}\n\nfloat fa_d_ggx_aniso(float ndh, float tdh, float bdh, float at, float ab)\n{\n    float _4847 = tdh / at;\n    float _4851 = bdh / ab;\n    float _4863 = ((_4847 * _4847) + (_4851 * _4851)) + (ndh * ndh);\n    return 1.0 / ((((3.1415927410125732421875 * at) * ab) * _4863) * _4863);\n}\n\nfloat fa_lambda_ggx_aniso(float n, float t, float b, float at, float ab)\n{\n    return 0.5 * (sqrt(1.0 + (((((at * at) * t) * t) + (((ab * ab) * b) * b)) / max(n * n, 9.9999999392252902907785028219223e-09))) - 1.0);\n}\n\nfloat fa_v_ggx_aniso(float ndl, float ndv, float tdv, float bdv, float tdl, float bdl, float at, float ab)\n{\n    float param = ndv;\n    float param_1 = tdv;\n    float param_2 = bdv;\n    float param_3 = at;\n    float param_4 = ab;\n    float param_5 = ndl;\n    float param_6 = tdl;\n    float param_7 = bdl;\n    float param_8 = at;\n    float param_9 = ab;\n    return clamp(1.0 / ((4.0 * max(ndl * ndv, 9.9999997473787516355514526367188e-05)) * ((1.0 + fa_lambda_ggx_aniso(param, param_1, param_2, param_3, param_4)) + fa_lambda_ggx_aniso(param_5, param_6, param_7, param_8, param_9))), 0.0, 1.0);\n}\n\nvec3 fa_layers_light(FaLayers L, vec3 diffuse_color, vec3 f0, vec3 n, vec3 v, vec3 l, vec3 h, float ndl, float ndv, float ndh, float vdh, float alpha, float a2)\n{\n    float _5043 = step(9.9999997473787516355514526367188e-05, ndl);\n    float d_ggx;\n    float vis;\n    if (L.aniso != 0.0)\n    {\n        float param = ndh;\n        float param_1 = dot(L.t, h);\n        float param_2 = dot(L.b, h);\n        float param_3 = L.at;\n        float param_4 = L.ab;\n        d_ggx = fa_d_ggx_aniso(param, param_1, param_2, param_3, param_4);\n        float param_5 = ndl;\n        float param_6 = ndv;\n        float param_7 = dot(L.t, v);\n        float param_8 = dot(L.b, v);\n        float param_9 = dot(L.t, l);\n        float param_10 = dot(L.b, l);\n        float param_11 = L.at;\n        float param_12 = L.ab;\n        vis = fa_v_ggx_aniso(param_5, param_6, param_7, param_8, param_9, param_10, param_11, param_12);\n    }\n    else\n    {\n        float _5122 = ((ndh * ndh) * (a2 - 1.0)) + 1.0;\n        d_ggx = a2 / ((3.1415927410125732421875 * _5122) * _5122);\n        vis = 0.5 / max(mix((2.0 * ndl) * ndv, ndl + ndv, alpha), 9.9999997473787516355514526367188e-05);\n    }\n    vec3 base = diffuse_color + (((f0 + ((vec3(L.f90) - f0) * pow(clamp(1.0 - vdh, 0.0, 1.0), 5.0))) * ((d_ggx * vis) * 3.1415927410125732421875)) * _5043);\n    if (L.sheen_on)\n    {\n        float param_13 = L.sheen_alpha;\n        float param_14 = ndh;\n        float param_15 = ndl;\n        float param_16 = ndv;\n        base = (base * L.sheen_scale) + (L.sheen * (((fa_d_charlie(param_13, param_14) * fa_v_ashikhmin(param_15, param_16)) * 3.1415927410125732421875) * _5043));\n    }\n    vec3 result = base * (L.keep * ndl);\n    if (L.coat > 0.0)\n    {\n        FaLayers param_17 = L;\n        vec3 param_18 = l;\n        vec3 param_19 = h;\n        float param_20 = vdh;\n        result += vec3(fa_layers_coat(param_17, param_18, param_19, param_20));\n    }\n    return result;\n}\n\nvec2 fa_env_brdf(float rough, float ndv)\n{\n    vec4 _4246 = (vec4(-1.0, -0.0274999998509883880615234375, -0.572000026702880859375, 0.02199999988079071044921875) * rough) + vec4(1.0, 0.0425000004470348358154296875, 1.03999996185302734375, -0.039999999105930328369140625);\n    float _4249 = _4246.x;\n    return (vec2(-1.03999996185302734375, 1.03999996185302734375) * ((min(_4249 * _4249, exp2((-9.27999973297119140625) * ndv)) * _4249) + _4246.y)) + _4246.zw;\n}\n\nvec3 fa_probe_level(vec2 origin, float res, int lv, vec2 e)\n{\n    float _3554;\n    if (lv == 0)\n    {\n        _3554 = 0.0;\n    }\n    else\n    {\n        _3554 = res + 2.0;\n    }\n    float _3564;\n    if (lv == 0)\n    {\n        _3564 = 0.0;\n    }\n    else\n    {\n        _3564 = (res - (res / float(1 << max((lv - 1), 0)))) + (2.0 * float(lv - 1));\n    }\n    return textureLod(fa_probe_atlas_fa_env_smp, (((origin + vec2(_3554, _3564)) + vec2(1.0)) + (((e * 0.5) + vec2(0.5)) * (res / float(1 << lv)))) / fa_atlas_size(), 0.0).xyz;\n}\n\nvec3 fa_probe_radiance(vec2 origin, float res, vec3 d, float rough)\n{\n    float _3610;\n    if (res > 64.5)\n    {\n        _3610 = 5.0;\n    }\n    else\n    {\n        _3610 = (res > 32.5) ? 4.0 : 3.0;\n    }\n    float _3625 = clamp(rough, 0.0, 1.0) * (_3610 - 1.0);\n    int _3632 = int(min(floor(_3625), _3610 - 2.0));\n    float _3637 = _3625 - float(_3632);\n    vec3 param = d;\n    vec2 _3641 = fa_oct_encode(param);\n    vec2 param_1 = origin;\n    float param_2 = res;\n    int param_3 = _3632;\n    vec2 param_4 = _3641;\n    vec3 _3651 = fa_probe_level(param_1, param_2, param_3, param_4);\n    if (_3637 < 0.00200000009499490261077880859375)\n    {\n        return _3651;\n    }\n    vec2 param_5 = origin;\n    float param_6 = res;\n    int param_7 = _3632 + 1;\n    vec2 param_8 = _3641;\n    return mix(_3651, fa_probe_level(param_5, param_6, param_7, param_8), vec3(_3637));\n}\n\nvec3 fa_probe_box_dir(vec3 d, vec4 posw, vec4 bx, vec4 by, vec4 bz)\n{\n    if (posw.w < 0.5)\n    {\n        return d;\n    }\n    float _3724 = dot(bx.xyz, fa_world_pos) + bx.w;\n    float _3731 = dot(by.xyz, fa_world_pos) + by.w;\n    float _3738 = dot(bz.xyz, fa_world_pos) + bz.w;\n    float _3744 = dot(bx.xyz, d);\n    float _3748 = dot(by.xyz, d);\n    float _3752 = dot(bz.xyz, d);\n    float _3758;\n    if (_3744 > 9.9999999747524270787835121154785e-07)\n    {\n        _3758 = (1.0 - _3724) / _3744;\n    }\n    else\n    {\n        float _3772;\n        if (_3744 < (-9.9999999747524270787835121154785e-07))\n        {\n            _3772 = ((-1.0) - _3724) / _3744;\n        }\n        else\n        {\n            _3772 = 1000000015047466219876688855040.0;\n        }\n        _3758 = _3772;\n    }\n    float tx = _3758;\n    float _3789;\n    if (_3748 > 9.9999999747524270787835121154785e-07)\n    {\n        _3789 = (1.0 - _3731) / _3748;\n    }\n    else\n    {\n        float _3802;\n        if (_3748 < (-9.9999999747524270787835121154785e-07))\n        {\n            _3802 = ((-1.0) - _3731) / _3748;\n        }\n        else\n        {\n            _3802 = 1000000015047466219876688855040.0;\n        }\n        _3789 = _3802;\n    }\n    float ty = _3789;\n    float _3818;\n    if (_3752 > 9.9999999747524270787835121154785e-07)\n    {\n        _3818 = (1.0 - _3738) / _3752;\n    }\n    else\n    {\n        float _3831;\n        if (_3752 < (-9.9999999747524270787835121154785e-07))\n        {\n            _3831 = ((-1.0) - _3738) / _3752;\n        }\n        else\n        {\n            _3831 = 1000000015047466219876688855040.0;\n        }\n        _3818 = _3831;\n    }\n    float _3843 = tx;\n    float _3846 = (_3843 > 0.0) ? _3843 : 1000000015047466219876688855040.0;\n    tx = _3846;\n    float _3847 = ty;\n    float _3850 = (_3847 > 0.0) ? _3847 : 1000000015047466219876688855040.0;\n    ty = _3850;\n    float _3860 = min(_3846, min(_3850, (_3818 > 0.0) ? _3818 : 1000000015047466219876688855040.0));\n    if (_3860 > 100000001504746621987668885504.0)\n    {\n        return d;\n    }\n    vec3 _3876 = (fa_world_pos + (d * _3860)) - posw.xyz;\n    vec3 _3881;\n    if (dot(_3876, _3876) > 1.0000000133514319600180897396058e-10)\n    {\n        _3881 = normalize(_3876);\n    }\n    else\n    {\n        _3881 = d;\n    }\n    return _3881;\n}\n\nvec3 fa_probe_environment(vec4 tile, vec4 posw, vec4 bx, vec4 by, vec4 bz, inout vec3 d, float rough)\n{\n    vec3 param = d;\n    vec4 param_1 = posw;\n    vec4 param_2 = bx;\n    vec4 param_3 = by;\n    vec4 param_4 = bz;\n    d = fa_probe_box_dir(param, param_1, param_2, param_3, param_4);\n    vec2 param_5 = tile.xy;\n    float param_6 = tile.z;\n    vec3 param_7 = d;\n    float param_8 = rough;\n    return fa_probe_radiance(param_5, param_6, param_7, param_8);\n}\n\nvec3 fa_environment(vec3 d, float rough)\n{\n    float _3927 = (1.0 - fa_mesh_fs_params[42].w) - fa_mesh_fs_params[47].w;\n    vec3 outc = vec3(0.0);\n    if (_3927 > 0.0005000000237487256526947021484375)\n    {\n        vec3 base;\n        if (fa_mesh_fs_params[11].w > 0.5)\n        {\n            vec2 param = fa_mesh_fs_params[41].zw;\n            float param_1 = 128.0;\n            vec3 param_2 = d;\n            float param_3 = rough;\n            base = fa_probe_radiance(param, param_1, param_2, param_3);\n        }\n        else\n        {\n            float _3955 = rough * rough;\n            float _3986 = 0.60000002384185791015625 * _3955;\n            base = mix(mix(fa_mesh_fs_params[12].xyz * 0.550000011920928955078125, mix(fa_mesh_fs_params[12].xyz, fa_mesh_fs_params[11].xyz, vec3(pow(clamp(d.y * (1.0 - (0.699999988079071044921875 * _3955)), 0.0, 1.0), 0.550000011920928955078125))), vec3(smoothstep((-0.0500000007450580596923828125) - _3986, 0.0500000007450580596923828125 + _3986, d.y))), ((fa_mesh_fs_params[11].xyz + fa_mesh_fs_params[12].xyz) * 0.5) * 0.800000011920928955078125, vec3(_3955 * 0.60000002384185791015625));\n        }\n        outc = base * _3927;\n    }\n    if (fa_mesh_fs_params[42].w > 0.0)\n    {\n        vec4 param_4 = fa_mesh_fs_params[42];\n        vec4 param_5 = fa_mesh_fs_params[43];\n        vec4 param_6 = fa_mesh_fs_params[44];\n        vec4 param_7 = fa_mesh_fs_params[45];\n        vec4 param_8 = fa_mesh_fs_params[46];\n        vec3 param_9 = d;\n        float param_10 = rough;\n        vec3 _4045 = fa_probe_environment(param_4, param_5, param_6, param_7, param_8, param_9, param_10);\n        outc += (_4045 * fa_mesh_fs_params[42].w);\n    }\n    if (fa_mesh_fs_params[47].w > 0.0)\n    {\n        vec4 param_11 = fa_mesh_fs_params[47];\n        vec4 param_12 = fa_mesh_fs_params[48];\n        vec4 param_13 = fa_mesh_fs_params[49];\n        vec4 param_14 = fa_mesh_fs_params[50];\n        vec4 param_15 = fa_mesh_fs_params[51];\n        vec3 param_16 = d;\n        float param_17 = rough;\n        vec3 _4077 = fa_probe_environment(param_11, param_12, param_13, param_14, param_15, param_16, param_17);\n        outc += (_4077 * fa_mesh_fs_params[47].w);\n    }\n    return outc;\n}\n\nvec3 fa_layers_ibl(FaLayers L, vec3 n, vec3 v, vec3 f0, float roughness, float occlusion)\n{\n    vec3 rn = n;\n    if (L.aniso != 0.0)\n    {\n        vec3 _4724;\n        if (L.aniso >= 0.0)\n        {\n            _4724 = L.b;\n        }\n        else\n        {\n            _4724 = L.t;\n        }\n        rn = normalize(mix(n, cross(cross(_4724, v), _4724), vec3(abs(L.aniso) * smoothstep(0.0, 0.25, roughness))));\n    }\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05);\n    vec2 _4760 = fa_env_brdf(param, param_1);\n    vec3 param_2 = reflect(-v, rn);\n    float param_3 = roughness;\n    vec3 result = (fa_environment(param_2, param_3) * ((f0 * _4760.x) + (vec3(L.f90) * _4760.y))) * L.base_scale;\n    if (L.sheen_on)\n    {\n        vec3 param_4 = n;\n        float param_5 = L.sheen_rough;\n        result += ((L.sheen * (L.sheen_e * L.keep)) * fa_environment(param_4, param_5));\n    }\n    result *= occlusion;\n    if (L.coat > 0.0)\n    {\n        float param_6 = L.coat_rough;\n        float param_7 = L.coat_ndv;\n        vec2 _4818 = fa_env_brdf(param_6, param_7);\n        vec3 param_8 = reflect(-v, L.nc);\n        float param_9 = L.coat_rough;\n        result += (fa_environment(param_8, param_9) * (L.coat * ((0.039999999105930328369140625 * _4818.x) + _4818.y)));\n    }\n    return result;\n}\n\nvec3 fa_sky_reflection(vec3 n, vec3 v, vec3 f0, float roughness)\n{\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05);\n    vec2 _4288 = fa_env_brdf(param, param_1);\n    vec3 param_2 = reflect(-v, n);\n    float param_3 = roughness;\n    return fa_environment(param_2, param_3) * ((f0 * _4288.x) + vec3(_4288.y));\n}\n\nvec2 fa_xm_size(int k)\n{\n    return max(floor(fa_mesh_fs_params[24].zw / vec2(float(1 << k))), vec2(1.0));\n}\n\nvec2 fa_xm_origin(int k)\n{\n    if (k == 0)\n    {\n        return vec2(0.0);\n    }\n    float y = 0.0;\n    for (int j = 1; j < k; j++)\n    {\n        int param = j;\n        y += fa_xm_size(param).y;\n    }\n    return vec2(fa_mesh_fs_params[24].z, y);\n}\n\nvec3 fa_xm_texel(vec2 size, vec2 origin, vec2 p)\n{\n    return texelFetch(fa_screen_tex_fa_shadow_smp, ivec2(origin + clamp(p, vec2(0.0), size - vec2(1.0))), 0).xyz;\n}\n\nvec3 fa_xm_level(int k, vec2 uv)\n{\n    int param = k;\n    vec2 _5528 = fa_xm_size(param);\n    int param_1 = k;\n    vec2 _5532 = fa_xm_origin(param_1);\n    vec2 _5538 = (uv * _5528) - vec2(0.5);\n    vec2 _5541 = fract(_5538);\n    vec2 _5544 = floor(_5538);\n    vec2 param_2 = _5528;\n    vec2 param_3 = _5532;\n    vec2 param_4 = _5544;\n    vec2 param_5 = _5528;\n    vec2 param_6 = _5532;\n    vec2 param_7 = _5544 + vec2(1.0, 0.0);\n    vec2 param_8 = _5528;\n    vec2 param_9 = _5532;\n    vec2 param_10 = _5544 + vec2(0.0, 1.0);\n    vec2 param_11 = _5528;\n    vec2 param_12 = _5532;\n    vec2 param_13 = _5544 + vec2(1.0);\n    vec3 _5586 = vec3(_5541.x);\n    return mix(mix(fa_xm_texel(param_2, param_3, param_4), fa_xm_texel(param_5, param_6, param_7), _5586), mix(fa_xm_texel(param_8, param_9, param_10), fa_xm_texel(param_11, param_12, param_13), _5586), vec3(_5541.y));\n}\n\nvec3 fa_xm_sample(vec2 uv, float lod)\n{\n    float _5605 = max(fa_mesh_fs_params[31].w - 1.0, 0.0);\n    float _5609 = clamp(lod, 0.0, _5605);\n    int _5613 = int(floor(_5609));\n    int param = _5613;\n    vec2 param_1 = uv;\n    vec3 c = fa_xm_level(param, param_1);\n    float _5623 = float(_5613);\n    float _5624 = _5609 - _5623;\n    bool _5626 = _5624 > 0.001000000047497451305389404296875;\n    bool _5633;\n    if (_5626)\n    {\n        _5633 = _5623 < _5605;\n    }\n    else\n    {\n        _5633 = _5626;\n    }\n    if (_5633)\n    {\n        int param_2 = _5613 + 1;\n        vec2 param_3 = uv;\n        c = mix(c, fa_xm_level(param_2, param_3), vec3(_5624));\n    }\n    return c;\n}\n\nvec3 fa_transmitted(Surface s, vec3 n, vec3 v, float roughness, vec3 f0, float f90, float keep, float tr, inout float blend)\n{\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05);\n    vec2 _5659 = fa_env_brdf(param, param_1);\n    vec3 through = ((vec3(1.0) - clamp((f0 * _5659.x) + (vec3(f90) * _5659.y), vec3(0.0), vec3(1.0))) * s.albedo) * (tr * keep);\n    float _5687 = max(s.thickness, 0.0);\n    bool _5692 = _5687 > 0.0;\n    if ((s.attenuation_distance > 0.0) && _5692)\n    {\n        through *= exp((-((-log(clamp(s.attenuation_color, vec3(9.9999997473787516355514526367188e-05), vec3(1.0)))) / vec3(s.attenuation_distance))) * _5687);\n    }\n    bool _5717 = fa_mesh_fs_params[30].w > 1.5;\n    bool _5724;\n    if (!_5717)\n    {\n        _5724 = fa_mesh_fs_params[30].w < 0.5;\n    }\n    else\n    {\n        _5724 = _5717;\n    }\n    if (_5724)\n    {\n        blend = clamp(dot(through, vec3(0.3333333432674407958984375)), 0.0, 0.980000019073486328125);\n        return vec3(0.0);\n    }\n    vec3 world = fa_world_pos;\n    if (_5692)\n    {\n        world += (refract(-v, n, 1.0 / max(s.ior, 1.0)) * _5687);\n    }\n    vec4 _5759 = vec4(world, 1.0);\n    float _5764 = dot(fa_mesh_fs_params[28], _5759);\n    vec2 uv = vec2(0.5);\n    if (_5764 > 9.9999997473787516355514526367188e-05)\n    {\n        vec2 _5782 = vec2(dot(fa_mesh_fs_params[26], _5759), dot(fa_mesh_fs_params[27], _5759)) / vec2(_5764);\n        float _5790;\n        if (fa_mesh_fs_params[24].y > 0.5)\n        {\n            _5790 = (_5782.y * 0.5) + 0.5;\n        }\n        else\n        {\n            _5790 = 0.5 - (_5782.y * 0.5);\n        }\n        uv = vec2((_5782.x * 0.5) + 0.5, _5790);\n    }\n    vec2 param_2 = clamp(uv, vec2(0.0), vec2(1.0));\n    float param_3 = (clamp(roughness, 0.0, 1.0) * clamp((2.0 * s.ior) - 2.0, 0.0, 1.0)) * max(fa_mesh_fs_params[31].w - 1.0, 0.0);\n    return through * fa_xm_sample(param_2, param_3);\n}\n\nvec3 fa_shadow_debug(vec3 color, vec3 world)\n{\n    if (fa_shadows[27].w < 0.5)\n    {\n        return color;\n    }\n    int _3305 = int(fa_shadows[25].x + 0.5);\n    float _3315 = dot(world - fa_shadows[27].xyz, fa_shadows[28].xyz);\n    vec3 tint = vec3(0.3499999940395355224609375);\n    bool _3320 = _3305 > 0;\n    bool _3329;\n    if (_3320)\n    {\n        int param = _3305 - 1;\n        _3329 = _3315 <= fa_shadow_split_at(param);\n    }\n    else\n    {\n        _3329 = _3320;\n    }\n    if (_3329)\n    {\n        tint = vec3(1.0, 0.1500000059604644775390625, 0.100000001490116119384765625);\n        bool _3335 = _3305 > 1;\n        bool _3342;\n        if (_3335)\n        {\n            _3342 = _3315 > fa_shadows[24].x;\n        }\n        else\n        {\n            _3342 = _3335;\n        }\n        if (_3342)\n        {\n            tint = vec3(0.100000001490116119384765625, 0.89999997615814208984375, 0.20000000298023223876953125);\n        }\n        bool _3348 = _3305 > 2;\n        bool _3355;\n        if (_3348)\n        {\n            _3355 = _3315 > fa_shadows[24].y;\n        }\n        else\n        {\n            _3355 = _3348;\n        }\n        if (_3355)\n        {\n            tint = vec3(0.1500000059604644775390625, 0.300000011920928955078125, 1.0);\n        }\n        bool _3361 = _3305 > 3;\n        bool _3368;\n        if (_3361)\n        {\n            _3368 = _3315 > fa_shadows[24].z;\n        }\n        else\n        {\n            _3368 = _3361;\n        }\n        if (_3368)\n        {\n            tint = vec3(1.0, 0.89999997615814208984375, 0.100000001490116119384765625);\n        }\n    }\n    return mix(color, tint, vec3(0.550000011920928955078125));\n}\n\nvoid main()\n{\n    fa_inst_load();\n    vec3 _8761 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _8761 = -_8761;\n    }\n    vec3 _8047 = normalize(fa_mesh_fs_params[0].xyz - fa_world_pos);\n    vec3 param = fa_world_pos;\n    fa_cluster_begin(param);\n    SurfaceInput param_1 = SurfaceInput(fa_world_pos, _8761, fa_world_tangent, fa_uv, fa_vertex_color, _8047, gl_FrontFacing);\n    Surface _8055 = fa_standard_surface(param_1);\n    vec3 _8792 = _8055.albedo;\n    float _8793 = _8055.alpha;\n    vec3 _8794 = _8055.normal;\n    float _8795 = _8055.metallic;\n    float _8796 = _8055.roughness;\n    float _8797 = _8055.occlusion;\n    vec3 _8798 = _8055.emission;\n    float _8799 = _8055.clearcoat;\n    float _8800 = _8055.clearcoat_roughness;\n    vec3 _8801 = _8055.sheen_color;\n    float _8802 = _8055.sheen_roughness;\n    float _8803 = _8055.anisotropy;\n    float _8804 = _8055.anisotropy_rotation;\n    float _8805 = _8055.specular;\n    float _8806 = _8055.ior;\n    vec3 _8807 = _8055.specular_color;\n    float _8808 = _8055.transmission;\n    float _8809 = _8055.thickness;\n    vec3 _8810 = _8055.attenuation_color;\n    float _8811 = _8055.attenuation_distance;\n    SurfaceInput param_2 = SurfaceInput(fa_world_pos, _8761, fa_world_tangent, fa_uv, fa_vertex_color, _8047, gl_FrontFacing);\n    Surface param_3 = _8055;\n    surface(param_2, param_3);\n    _8792 = param_3.albedo;\n    _8793 = param_3.alpha;\n    _8794 = param_3.normal;\n    _8795 = param_3.metallic;\n    _8796 = param_3.roughness;\n    _8797 = param_3.occlusion;\n    _8798 = param_3.emission;\n    _8799 = param_3.clearcoat;\n    _8800 = param_3.clearcoat_roughness;\n    _8801 = param_3.sheen_color;\n    _8802 = param_3.sheen_roughness;\n    _8803 = param_3.anisotropy;\n    _8804 = param_3.anisotropy_rotation;\n    _8805 = param_3.specular;\n    _8806 = param_3.ior;\n    _8807 = param_3.specular_color;\n    _8808 = param_3.transmission;\n    _8809 = param_3.thickness;\n    _8810 = param_3.attenuation_color;\n    _8811 = param_3.attenuation_distance;\n    vec3 param_4 = fa_world_pos;\n    vec3 param_5 = _8761;\n    vec3 param_6 = param_3.albedo;\n    vec3 param_7 = param_3.normal;\n    fa_apply_decals(param_4, param_5, param_6, param_7);\n    _8792 = param_6;\n    _8794 = param_7;\n    if (_8793 < fa_material[0].x)\n    {\n        discard;\n    }\n    fa_lod_dither();\n    float fa_tr_blend = 0.0;\n    vec3 result;\n    if (fa_mesh_fs_params[3].w > 0.5)\n    {\n        result = _8792;\n    }\n    else\n    {\n        vec3 _8107 = normalize(_8794);\n        float _8114 = clamp(_8795, 0.0, 1.0);\n        float _8118 = clamp(_8796, 0.0500000007450580596923828125, 1.0);\n        float _8122 = _8118 * _8118;\n        float _8126 = _8122 * _8122;\n        float _8131 = max(dot(_8107, _8047), 9.9999997473787516355514526367188e-05);\n        float _8137 = 1.0 - _8114;\n        float _8138 = clamp(_8808, 0.0, 1.0) * _8137;\n        vec3 _8147 = (_8792 * _8137) * (1.0 - _8138);\n        vec3 _8154 = mix(vec3(0.039999999105930328369140625), _8792, vec3(_8114));\n        vec3 f0 = _8154;\n        SurfaceInput param_8 = SurfaceInput(fa_world_pos, _8761, fa_world_tangent, fa_uv, fa_vertex_color, _8047, gl_FrontFacing);\n        Surface param_9 = Surface(_8792, _8793, _8794, _8795, _8796, _8797, _8798, _8799, _8800, _8801, _8802, _8803, _8804, _8805, _8806, _8807, _8808, _8809, _8810, _8811);\n        vec3 param_10 = _8107;\n        vec3 param_11 = _8047;\n        float param_12 = _8114;\n        float param_13 = _8118;\n        vec3 param_14 = _8154;\n        FaLayers _8170 = fa_layers_setup(param_8, param_9, param_10, param_11, param_12, param_13, param_14);\n        f0 = param_14;\n        vec3 param_15 = _8107;\n        vec3 lit = (fa_indirect_diffuse(param_15) * _8147) * _8797;\n        if (_8170.on)\n        {\n            lit *= _8170.base_scale;\n        }\n        int _8192 = fa_cl_ndir + fa_cl_local;\n        float _8257;\n        for (int ln = 0; ln < _8192; ln++)\n        {\n            int param_16 = ln;\n            int _8205 = fa_cl_light(param_16);\n            int param_17 = _8205;\n            if (fa_baked_keep(param_17) <= 0.0)\n            {\n                continue;\n            }\n            int param_18 = _8205;\n            vec3 param_19 = fa_world_pos;\n            vec3 param_20 = _8761;\n            LightSample _8221 = fa_light_shadowed(param_18, param_19, param_20);\n            float _8229 = max(dot(_8107, _8221.direction), 0.0);\n            float _8235 = _8221.attenuation * _8221.shadow;\n            vec3 _8240 = normalize(_8221.direction + _8047);\n            float _8245 = max(dot(_8107, _8240), 0.0);\n            float _8250 = max(dot(_8047, _8240), 0.0);\n            if (fa_light_is_area)\n            {\n                if (_8170.on)\n                {\n                    _8257 = _8170.f90;\n                }\n                else\n                {\n                    _8257 = 1.0;\n                }\n                int param_21 = _8205;\n                vec3 param_22 = fa_world_pos;\n                vec3 param_23 = _8107;\n                vec3 param_24 = _8047;\n                vec3 param_25 = _8147;\n                vec3 param_26 = f0;\n                float param_27 = _8257;\n                float param_28 = _8118;\n                float param_29 = _8131;\n                float param_30 = _8235;\n                vec3 area = fa_area_shade(param_21, param_22, param_23, param_24, param_25, param_26, param_27, param_28, param_29, param_30);\n                if (_8170.on)\n                {\n                    FaLayers param_31 = _8170;\n                    vec3 param_32 = area;\n                    int param_33 = _8205;\n                    vec3 param_34 = _8107;\n                    vec3 param_35 = _8047;\n                    vec3 param_36 = _8221.direction;\n                    float param_37 = _8131;\n                    float param_38 = _8235;\n                    area = fa_area_layers(param_31, param_32, param_33, param_34, param_35, param_36, param_37, param_38);\n                }\n                lit += area;\n            }\n            else\n            {\n                if (_8170.on)\n                {\n                    FaLayers param_39 = _8170;\n                    vec3 param_40 = _8147;\n                    vec3 param_41 = f0;\n                    vec3 param_42 = _8107;\n                    vec3 param_43 = _8047;\n                    vec3 param_44 = _8221.direction;\n                    vec3 param_45 = _8240;\n                    float param_46 = _8229;\n                    float param_47 = _8131;\n                    float param_48 = _8245;\n                    float param_49 = _8250;\n                    float param_50 = _8122;\n                    float param_51 = _8126;\n                    int param_52 = _8205;\n                    lit += (fa_layers_light(param_39, param_40, param_41, param_42, param_43, param_44, param_45, param_46, param_47, param_48, param_49, param_50, param_51) * ((fa_light_rgb(param_52) * fa_light_tint) * _8235));\n                }\n                else\n                {\n                    float _8359 = ((_8245 * _8245) * (_8126 - 1.0)) + 1.0;\n                    int param_53 = _8205;\n                    lit += (((_8147 + (((f0 + ((vec3(1.0) - f0) * pow(1.0 - _8250, 5.0))) * (((_8126 / ((3.1415927410125732421875 * _8359) * _8359)) * (0.5 / max(mix((2.0 * _8229) * _8131, _8229 + _8131, _8122), 9.9999997473787516355514526367188e-05))) * 3.1415927410125732421875)) * step(9.9999997473787516355514526367188e-05, _8229))) * (fa_light_rgb(param_53) * fa_light_tint)) * (_8229 * _8235));\n                }\n            }\n        }\n        if (_8170.on)\n        {\n            FaLayers param_54 = _8170;\n            vec3 param_55 = _8107;\n            vec3 param_56 = _8047;\n            vec3 param_57 = f0;\n            float param_58 = _8118;\n            float param_59 = _8797;\n            lit += fa_layers_ibl(param_54, param_55, param_56, param_57, param_58, param_59);\n        }\n        else\n        {\n            vec3 param_60 = _8107;\n            vec3 param_61 = _8047;\n            vec3 param_62 = f0;\n            float param_63 = _8118;\n            lit += (fa_sky_reflection(param_60, param_61, param_62, param_63) * _8797);\n        }\n        if (_8138 > 0.0)\n        {\n            float _8457;\n            if (_8170.on)\n            {\n                _8457 = _8170.f90;\n            }\n            else\n            {\n                _8457 = 1.0;\n            }\n            float _8465;\n            if (_8170.on)\n            {\n                _8465 = _8170.base_scale;\n            }\n            else\n            {\n                _8465 = 1.0;\n            }\n            Surface param_64 = Surface(_8792, _8793, _8794, _8795, _8796, _8797, _8798, _8799, _8800, _8801, _8802, _8803, _8804, _8805, _8806, _8807, _8808, _8809, _8810, _8811);\n            vec3 param_65 = _8107;\n            vec3 param_66 = _8047;\n            float param_67 = _8118;\n            vec3 param_68 = f0;\n            float param_69 = _8457;\n            float param_70 = _8465;\n            float param_71 = _8138;\n            float param_72 = fa_tr_blend;\n            vec3 _8489 = fa_transmitted(param_64, param_65, param_66, param_67, param_68, param_69, param_70, param_71, param_72);\n            fa_tr_blend = param_72;\n            lit += _8489;\n        }\n        result = lit;\n    }\n    vec3 _8496 = result;\n    vec3 _8497 = _8496 + _8798;\n    result = _8497;\n    vec3 param_73 = _8497;\n    vec3 param_74 = fa_world_pos;\n    result = fa_shadow_debug(param_73, param_74);\n    bool _8506 = fa_mesh_fs_params[7].w > 0.0;\n    bool _8513;\n    if (!_8506)\n    {\n        _8513 = fa_mesh_fs_params[8].y > 0.0;\n    }\n    else\n    {\n        _8513 = _8506;\n    }\n    if (_8513)\n    {\n        vec3 _8522 = fa_world_pos - fa_mesh_fs_params[0].xyz;\n        float _8528 = dot(_8522, fa_mesh_fs_params[9].xyz);\n        bool _8532 = fa_mesh_fs_params[9].w > 0.5;\n        float _8533;\n        if (_8532)\n        {\n            _8533 = _8528;\n        }\n        else\n        {\n            _8533 = length(_8522);\n        }\n        float _8545 = _8533 - fa_mesh_fs_params[8].x;\n        if (_8545 > 0.0)\n        {\n            float _8554 = fa_mesh_fs_params[7].w * _8545;\n            float tau = _8554 * _8554;\n            if (fa_mesh_fs_params[8].y > 0.0)\n            {\n                float _8570;\n                if (_8532)\n                {\n                    _8570 = fa_world_pos.y - (fa_mesh_fs_params[9].y * _8528);\n                }\n                else\n                {\n                    _8570 = fa_mesh_fs_params[0].y;\n                }\n                float _8591 = mix(_8570, fa_world_pos.y, clamp(fa_mesh_fs_params[8].x / _8533, 0.0, 1.0));\n                float _8595 = fa_world_pos.y - _8591;\n                float _8600 = _8591 - fa_mesh_fs_params[8].z;\n                float _8605 = fa_world_pos.y - fa_mesh_fs_params[8].z;\n                bool _8608 = _8600 <= 0.0;\n                bool _8609 = !_8608;\n                bool _8615;\n                if (_8609)\n                {\n                    _8615 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _8615 = _8608;\n                }\n                float _8616;\n                if (_8615)\n                {\n                    _8616 = fa_mesh_fs_params[8].y;\n                }\n                else\n                {\n                    _8616 = fa_mesh_fs_params[8].y * exp(-min(fa_mesh_fs_params[8].w * _8600, 80.0));\n                }\n                bool _8643;\n                if (_8609)\n                {\n                    _8643 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _8643 = _8608;\n                }\n                float _8644;\n                if (_8643)\n                {\n                    _8644 = fa_mesh_fs_params[8].y * _8600;\n                }\n                else\n                {\n                    _8644 = (fa_mesh_fs_params[8].y * (1.0 - exp(-min(fa_mesh_fs_params[8].w * _8600, 80.0)))) / fa_mesh_fs_params[8].w;\n                }\n                bool _8669 = _8605 <= 0.0;\n                bool _8676;\n                if (!_8669)\n                {\n                    _8676 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _8676 = _8669;\n                }\n                float _8677;\n                if (_8676)\n                {\n                    _8677 = fa_mesh_fs_params[8].y * _8605;\n                }\n                else\n                {\n                    _8677 = (fa_mesh_fs_params[8].y * (1.0 - exp(-min(fa_mesh_fs_params[8].w * _8605, 80.0)))) / fa_mesh_fs_params[8].w;\n                }\n                float _8704;\n                if (abs(_8595) < 0.001000000047497451305389404296875)\n                {\n                    _8704 = _8616;\n                }\n                else\n                {\n                    _8704 = (_8677 - _8644) / _8595;\n                }\n                tau += (_8545 * max(_8704, 0.0));\n            }\n            result = mix(result, fa_mesh_fs_params[7].xyz, vec3(clamp(1.0 - exp(-clamp(tau, 0.0, 80.0)), 0.0, 1.0)));\n        }\n    }\n    if (fa_tr_blend > 0.0)\n    {\n        float _8740 = 1.0 - fa_tr_blend;\n        result /= vec3(_8740);\n        _8793 *= _8740;\n    }\n    fa_frag_color = vec4(result, _8793);\n}\n\n",
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
            "inst_name": "_602",
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
            "inst_name": "_2346",
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
            "inst_name": "_8083",
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
            "name": "fa_shadow_tex_fa_shadow_smp",
            "view_name": "fa_shadow_tex",
            "sampler_name": "fa_shadow_smp",
            "view_slot": 1,
            "sampler_slot": 1,
            "glsl_name": "fa_shadow_tex_fa_shadow_smp"
          },
          {
            "slot": 12,
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
      "vs": "#version 430\n\nstruct VertexData\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 color;\n    vec3 object_pos;\n};\n\nuniform vec4 fa_mesh_vs_params[11];\nlayout(location = 0) out vec3 fa_world_pos;\nlayout(location = 1) out vec3 fa_world_normal;\nlayout(location = 2) out vec4 fa_world_tangent;\nlayout(location = 3) out vec2 fa_uv;\nlayout(location = 4) out vec4 fa_vertex_color;\nlayout(location = 5) out float fa_pre_depth;\nlayout(location = 6) out vec3 fa_pre_r0;\nlayout(location = 7) out vec3 fa_pre_r1;\nlayout(location = 8) out vec3 fa_pre_r2;\nlayout(location = 5) in vec4 fa_inst_m0;\nlayout(location = 6) in vec4 fa_inst_m1;\nlayout(location = 7) in vec4 fa_inst_m2;\nlayout(location = 8) in vec4 fa_inst_m3;\nlayout(location = 0) in vec3 fa_position;\nlayout(location = 1) in vec3 fa_normal;\nlayout(location = 3) in vec4 fa_tangent;\nlayout(location = 2) in vec2 fa_texcoord0;\nlayout(location = 4) in vec4 fa_color;\n\nvoid fa_inst_begin()\n{\n}\n\nVertexData fa_vertex_data(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    vec3 _69 = cross(model[1].xyz, model[2].xyz);\n    float _75 = (dot(model[0].xyz, _69) < 0.0) ? (-1.0) : 1.0;\n    return VertexData((model * vec4(position, 1.0)).xyz, (((_69 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _75, vec4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _75), texcoord0 * fa_mesh_vs_params[8].xy, color, position);\n}\n\nvoid fa_prepass_vertex(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    mat4 param = model;\n    vec3 param_1 = position;\n    vec3 param_2 = normal;\n    vec4 param_3 = tangent;\n    vec2 param_4 = texcoord0;\n    vec4 param_5 = color;\n    VertexData _160 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    vec3 _308 = _160.world_pos;\n    mat4 _164 = mat4(fa_mesh_vs_params[4], fa_mesh_vs_params[5], fa_mesh_vs_params[6], fa_mesh_vs_params[7]);\n    vec4 _171 = vec4(_308, 1.0);\n    fa_world_pos = _308;\n    fa_world_normal = _160.world_normal;\n    fa_world_tangent = _160.world_tangent;\n    fa_uv = _160.uv;\n    fa_vertex_color = _160.color;\n    fa_pre_depth = -(_164 * _171).z;\n    fa_pre_r0 = vec3(_164[0].x, _164[1].x, _164[2].x);\n    fa_pre_r1 = vec3(_164[0].y, _164[1].y, _164[2].y);\n    fa_pre_r2 = vec3(_164[0].z, _164[1].z, _164[2].z);\n    gl_Position = mat4(fa_mesh_vs_params[0], fa_mesh_vs_params[1], fa_mesh_vs_params[2], fa_mesh_vs_params[3]) * _171;\n}\n\nvoid main()\n{\n    fa_inst_begin();\n    mat4 param = mat4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3);\n    vec3 param_1 = fa_position;\n    vec3 param_2 = fa_normal;\n    vec4 param_3 = fa_tangent;\n    vec2 param_4 = fa_texcoord0;\n    vec4 param_5 = fa_color;\n    fa_prepass_vertex(param, param_1, param_2, param_3, param_4, param_5);\n}\n\n",
      "fs": "#version 430\n\nstruct SurfaceInput\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 vertex_color;\n    vec3 view_dir;\n    bool front_facing;\n};\n\nstruct Surface\n{\n    vec3 albedo;\n    float alpha;\n    vec3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    vec3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    vec3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    vec3 specular_color;\n    float transmission;\n    float thickness;\n    vec3 attenuation_color;\n    float attenuation_distance;\n};\n\nuniform vec4 fa_mesh_fs_params[53];\nuniform vec4 fa_material[1];\nlayout(binding = 0) uniform sampler2D fa_tex_fa_smp;\nlayout(binding = 1) uniform sampler2D fa_normal_tex_fa_smp;\nlayout(binding = 2) uniform sampler2D fa_mr_tex_fa_smp;\nlayout(binding = 3) uniform sampler2D fa_occlusion_tex_fa_smp;\nlayout(binding = 4) uniform sampler2D fa_emissive_tex_fa_smp;\nlayout(binding = 5) uniform sampler2D mask_mask_smp;\n\nlayout(location = 0) in vec3 fa_world_pos;\nlayout(location = 1) in vec3 fa_world_normal;\nlayout(location = 2) in vec4 fa_world_tangent;\nlayout(location = 3) in vec2 fa_uv;\nlayout(location = 4) in vec4 fa_vertex_color;\nlayout(location = 6) in vec3 fa_pre_r0;\nlayout(location = 7) in vec3 fa_pre_r1;\nlayout(location = 8) in vec3 fa_pre_r2;\nlayout(location = 0) out vec4 fa_frag_color;\nlayout(location = 5) in float fa_pre_depth;\n\nvoid fa_inst_load()\n{\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nvec3 fa_linear_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_tex_fix(inout vec3 c, float mode)\n{\n    if (mode > 1.5)\n    {\n        vec3 param = c;\n        vec3 _237 = fa_linear_to_srgb(param);\n        c = _237;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            vec3 param_1 = c;\n            vec3 _246 = fa_srgb_to_linear(param_1);\n            c = _246;\n        }\n    }\n    return c;\n}\n\nvec3 fa_tangent_normal(SurfaceInput i, vec3 m)\n{\n    vec3 _58;\n    if (i.front_facing)\n    {\n        _58 = i.world_normal;\n    }\n    else\n    {\n        _58 = -i.world_normal;\n    }\n    vec3 _83 = normalize(i.world_tangent.xyz - (_58 * dot(_58, i.world_tangent.xyz)));\n    vec3 _111 = normalize(((_83 * m.x) + ((cross(_58, _83) * i.world_tangent.w) * m.y)) + (_58 * m.z));\n    vec3 _114;\n    if (i.front_facing)\n    {\n        _114 = _111;\n    }\n    else\n    {\n        _114 = -_111;\n    }\n    return _114;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    vec4 base_t = texture(fa_tex_fa_smp, i.uv);\n    float param = fa_mesh_fs_params[6].w;\n    float param_1 = 1.0;\n    vec3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    vec3 _279 = fa_tex_fix(param_2, param_3);\n    vec4 _840 = base_t;\n    _840.x = _279.x;\n    _840.y = _279.y;\n    _840.z = _279.z;\n    base_t = _840;\n    vec4 _295 = (_840 * fa_mesh_fs_params[2]) * i.vertex_color;\n    vec3 _795 = i.world_normal;\n    if (fa_mesh_fs_params[6].z > 0.5)\n    {\n        float param_4 = fa_mesh_fs_params[6].w;\n        float param_5 = 16.0;\n        vec3 param_6 = texture(fa_normal_tex_fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        vec3 _329 = fa_tex_fix(param_6, param_7);\n        vec3 _332 = (_329 * 2.0) - vec3(1.0);\n        vec2 _337 = _332.xy * fa_mesh_fs_params[6].x;\n        vec3 _848 = _332;\n        _848.x = _337.x;\n        _848.y = _337.y;\n        SurfaceInput param_8 = i;\n        vec3 param_9 = _848;\n        _795 = fa_tangent_normal(param_8, param_9);\n    }\n    vec4 mrt = texture(fa_mr_tex_fa_smp, i.uv);\n    float param_10 = fa_mesh_fs_params[6].w;\n    float param_11 = 64.0;\n    vec3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    vec3 _366 = fa_tex_fix(param_12, param_13);\n    vec4 _851 = mrt;\n    _851.x = _366.x;\n    _851.y = _366.y;\n    _851.z = _366.z;\n    mrt = _851;\n    vec4 _396 = texture(fa_occlusion_tex_fa_smp, i.uv);\n    float param_14 = fa_mesh_fs_params[6].w;\n    float param_15 = 256.0;\n    vec3 param_16 = _396.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    vec3 _408 = fa_tex_fix(param_16, param_17);\n    float param_18 = fa_mesh_fs_params[6].w;\n    float param_19 = 4.0;\n    vec3 param_20 = texture(fa_emissive_tex_fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    vec3 _438 = fa_tex_fix(param_20, param_21);\n    float _800 = fa_mesh_fs_params[20].x;\n    float _801 = fa_mesh_fs_params[20].y;\n    float _804 = fa_mesh_fs_params[20].z;\n    float _803 = fa_mesh_fs_params[21].w;\n    float _806 = fa_mesh_fs_params[22].x;\n    if (fa_mesh_fs_params[22].z > 0.5)\n    {\n        if (mod(fa_mesh_fs_params[22].z, 2.0) > 0.5)\n        {\n            _800 *= _408.y;\n            _801 *= _408.z;\n            _803 *= _396.w;\n        }\n        if (fa_mesh_fs_params[22].z > 1.5)\n        {\n            _804 *= mrt.x;\n            _806 *= mrt.w;\n        }\n    }\n    return Surface(_295.xyz, _295.w, _795, clamp(fa_mesh_fs_params[5].x * _366.z, 0.0, 1.0), clamp(fa_mesh_fs_params[5].y * _366.y, 0.0500000007450580596923828125, 1.0), 1.0 + (fa_mesh_fs_params[6].y * (_408.x - 1.0)), fa_mesh_fs_params[3].xyz + (fa_mesh_fs_params[4].xyz * _438), _800, _801, fa_mesh_fs_params[21].xyz, _803, _804, fa_mesh_fs_params[20].w, _806, fa_mesh_fs_params[22].y, fa_mesh_fs_params[23].xyz, fa_mesh_fs_params[30].x, fa_mesh_fs_params[30].y, fa_mesh_fs_params[31].xyz, fa_mesh_fs_params[30].z);\n}\n\nvoid surface(SurfaceInput i, inout Surface s)\n{\n    s.alpha = texture(mask_mask_smp, i.uv * 2.0).x;\n}\n\nvoid fa_lod_dither()\n{\n    if (fa_mesh_fs_params[52].w != 0.0)\n    {\n        float _151 = fract(52.98291778564453125 * fract(dot(gl_FragCoord.xy, vec2(0.067110560834407806396484375, 0.005837149918079376220703125))));\n        bool _154;\n        if (fa_mesh_fs_params[52].w > 0.0)\n        {\n            _154 = _151 >= fa_mesh_fs_params[52].w;\n        }\n        else\n        {\n            _154 = _151 < (-fa_mesh_fs_params[52].w);\n        }\n        if (_154)\n        {\n            discard;\n        }\n    }\n}\n\nvoid main()\n{\n    fa_inst_load();\n    vec3 _690 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _690 = -_690;\n    }\n    vec3 _590 = normalize(fa_mesh_fs_params[0].xyz - fa_world_pos);\n    SurfaceInput param = SurfaceInput(fa_world_pos, _690, fa_world_tangent, fa_uv, fa_vertex_color, _590, gl_FrontFacing);\n    Surface _595 = fa_standard_surface(param);\n    vec3 _714 = _595.normal;\n    SurfaceInput param_1 = SurfaceInput(fa_world_pos, _690, fa_world_tangent, fa_uv, fa_vertex_color, _590, gl_FrontFacing);\n    Surface param_2 = _595;\n    surface(param_1, param_2);\n    _714 = param_2.normal;\n    if (param_2.alpha < fa_material[0].x)\n    {\n        discard;\n    }\n    fa_lod_dither();\n    vec3 _617 = normalize(_714);\n    vec3 _632 = normalize(vec3(dot(fa_pre_r0, _617), dot(fa_pre_r1, _617), dot(fa_pre_r2, _617)));\n    float _644 = _632.z;\n    vec2 e = _632.xy / vec2((abs(_632.x) + abs(_632.y)) + abs(_644));\n    if (_644 < 0.0)\n    {\n        e = (vec2(1.0) - abs(e.yx)) * vec2((e.x >= 0.0) ? 1.0 : (-1.0), (e.y >= 0.0) ? 1.0 : (-1.0));\n    }\n    fa_frag_color = vec4(min(fa_pre_depth, 60000.0), e, 1.0);\n}\n\n",
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
          },
          {
            "slot": 5,
            "stage": "fragment",
            "size": 16,
            "struct_name": "fa_material",
            "inst_name": "_606",
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
      "vs": "#version 430\n\nstruct VertexData\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 color;\n    vec3 object_pos;\n};\n\nuniform vec4 fa_mesh_vs_params[11];\nuniform vec4 fa_skin[192];\nlayout(location = 0) out vec3 fa_world_pos;\nlayout(location = 1) out vec3 fa_world_normal;\nlayout(location = 2) out vec4 fa_world_tangent;\nlayout(location = 3) out vec2 fa_uv;\nlayout(location = 4) out vec4 fa_vertex_color;\nlayout(location = 5) out float fa_pre_depth;\nlayout(location = 6) out vec3 fa_pre_r0;\nlayout(location = 7) out vec3 fa_pre_r1;\nlayout(location = 8) out vec3 fa_pre_r2;\nlayout(location = 5) in vec4 fa_inst_m0;\nlayout(location = 6) in vec4 fa_inst_m1;\nlayout(location = 7) in vec4 fa_inst_m2;\nlayout(location = 8) in vec4 fa_inst_m3;\nlayout(location = 9) in vec4 fa_joints;\nlayout(location = 10) in vec4 fa_weights;\nlayout(location = 0) in vec3 fa_position;\nlayout(location = 1) in vec3 fa_normal;\nlayout(location = 3) in vec4 fa_tangent;\nlayout(location = 2) in vec2 fa_texcoord0;\nlayout(location = 4) in vec4 fa_color;\n\nvoid fa_inst_begin()\n{\n}\n\nmat4 fa_skin_matrix(vec4 joints, vec4 weights)\n{\n    vec4 r0 = vec4(0.0);\n    vec4 r1 = vec4(0.0);\n    vec4 r2 = vec4(0.0);\n    for (int i = 0; i < 4; i++)\n    {\n        int _174 = int((joints[i] * 255.0) + 0.5) * 3;\n        r0 += (fa_skin[_174 * 1 + 0] * weights[i]);\n        r1 += (fa_skin[(_174 + 1) * 1 + 0] * weights[i]);\n        r2 += (fa_skin[(_174 + 2) * 1 + 0] * weights[i]);\n    }\n    return mat4(vec4(r0.x, r1.x, r2.x, 0.0), vec4(r0.y, r1.y, r2.y, 0.0), vec4(r0.z, r1.z, r2.z, 0.0), vec4(r0.w, r1.w, r2.w, 1.0));\n}\n\nVertexData fa_vertex_data(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    vec3 _74 = cross(model[1].xyz, model[2].xyz);\n    float _80 = (dot(model[0].xyz, _74) < 0.0) ? (-1.0) : 1.0;\n    return VertexData((model * vec4(position, 1.0)).xyz, (((_74 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _80, vec4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _80), texcoord0 * fa_mesh_vs_params[8].xy, color, position);\n}\n\nvoid fa_prepass_vertex(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    mat4 param = model;\n    vec3 param_1 = position;\n    vec3 param_2 = normal;\n    vec4 param_3 = tangent;\n    vec2 param_4 = texcoord0;\n    vec4 param_5 = color;\n    VertexData _273 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    vec3 _429 = _273.world_pos;\n    mat4 _277 = mat4(fa_mesh_vs_params[4], fa_mesh_vs_params[5], fa_mesh_vs_params[6], fa_mesh_vs_params[7]);\n    vec4 _284 = vec4(_429, 1.0);\n    fa_world_pos = _429;\n    fa_world_normal = _273.world_normal;\n    fa_world_tangent = _273.world_tangent;\n    fa_uv = _273.uv;\n    fa_vertex_color = _273.color;\n    fa_pre_depth = -(_277 * _284).z;\n    fa_pre_r0 = vec3(_277[0].x, _277[1].x, _277[2].x);\n    fa_pre_r1 = vec3(_277[0].y, _277[1].y, _277[2].y);\n    fa_pre_r2 = vec3(_277[0].z, _277[1].z, _277[2].z);\n    gl_Position = mat4(fa_mesh_vs_params[0], fa_mesh_vs_params[1], fa_mesh_vs_params[2], fa_mesh_vs_params[3]) * _284;\n}\n\nvoid main()\n{\n    fa_inst_begin();\n    vec4 param = fa_joints;\n    vec4 param_1 = fa_weights;\n    mat4 param_2 = mat4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3) * fa_skin_matrix(param, param_1);\n    vec3 param_3 = fa_position;\n    vec3 param_4 = fa_normal;\n    vec4 param_5 = fa_tangent;\n    vec2 param_6 = fa_texcoord0;\n    vec4 param_7 = fa_color;\n    fa_prepass_vertex(param_2, param_3, param_4, param_5, param_6, param_7);\n}\n\n",
      "fs": "#version 430\n\nstruct SurfaceInput\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 vertex_color;\n    vec3 view_dir;\n    bool front_facing;\n};\n\nstruct Surface\n{\n    vec3 albedo;\n    float alpha;\n    vec3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    vec3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    vec3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    vec3 specular_color;\n    float transmission;\n    float thickness;\n    vec3 attenuation_color;\n    float attenuation_distance;\n};\n\nuniform vec4 fa_mesh_fs_params[53];\nuniform vec4 fa_material[1];\nlayout(binding = 0) uniform sampler2D fa_tex_fa_smp;\nlayout(binding = 1) uniform sampler2D fa_normal_tex_fa_smp;\nlayout(binding = 2) uniform sampler2D fa_mr_tex_fa_smp;\nlayout(binding = 3) uniform sampler2D fa_occlusion_tex_fa_smp;\nlayout(binding = 4) uniform sampler2D fa_emissive_tex_fa_smp;\nlayout(binding = 5) uniform sampler2D mask_mask_smp;\n\nlayout(location = 0) in vec3 fa_world_pos;\nlayout(location = 1) in vec3 fa_world_normal;\nlayout(location = 2) in vec4 fa_world_tangent;\nlayout(location = 3) in vec2 fa_uv;\nlayout(location = 4) in vec4 fa_vertex_color;\nlayout(location = 6) in vec3 fa_pre_r0;\nlayout(location = 7) in vec3 fa_pre_r1;\nlayout(location = 8) in vec3 fa_pre_r2;\nlayout(location = 0) out vec4 fa_frag_color;\nlayout(location = 5) in float fa_pre_depth;\n\nvoid fa_inst_load()\n{\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nvec3 fa_linear_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_tex_fix(inout vec3 c, float mode)\n{\n    if (mode > 1.5)\n    {\n        vec3 param = c;\n        vec3 _237 = fa_linear_to_srgb(param);\n        c = _237;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            vec3 param_1 = c;\n            vec3 _246 = fa_srgb_to_linear(param_1);\n            c = _246;\n        }\n    }\n    return c;\n}\n\nvec3 fa_tangent_normal(SurfaceInput i, vec3 m)\n{\n    vec3 _58;\n    if (i.front_facing)\n    {\n        _58 = i.world_normal;\n    }\n    else\n    {\n        _58 = -i.world_normal;\n    }\n    vec3 _83 = normalize(i.world_tangent.xyz - (_58 * dot(_58, i.world_tangent.xyz)));\n    vec3 _111 = normalize(((_83 * m.x) + ((cross(_58, _83) * i.world_tangent.w) * m.y)) + (_58 * m.z));\n    vec3 _114;\n    if (i.front_facing)\n    {\n        _114 = _111;\n    }\n    else\n    {\n        _114 = -_111;\n    }\n    return _114;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    vec4 base_t = texture(fa_tex_fa_smp, i.uv);\n    float param = fa_mesh_fs_params[6].w;\n    float param_1 = 1.0;\n    vec3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    vec3 _279 = fa_tex_fix(param_2, param_3);\n    vec4 _840 = base_t;\n    _840.x = _279.x;\n    _840.y = _279.y;\n    _840.z = _279.z;\n    base_t = _840;\n    vec4 _295 = (_840 * fa_mesh_fs_params[2]) * i.vertex_color;\n    vec3 _795 = i.world_normal;\n    if (fa_mesh_fs_params[6].z > 0.5)\n    {\n        float param_4 = fa_mesh_fs_params[6].w;\n        float param_5 = 16.0;\n        vec3 param_6 = texture(fa_normal_tex_fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        vec3 _329 = fa_tex_fix(param_6, param_7);\n        vec3 _332 = (_329 * 2.0) - vec3(1.0);\n        vec2 _337 = _332.xy * fa_mesh_fs_params[6].x;\n        vec3 _848 = _332;\n        _848.x = _337.x;\n        _848.y = _337.y;\n        SurfaceInput param_8 = i;\n        vec3 param_9 = _848;\n        _795 = fa_tangent_normal(param_8, param_9);\n    }\n    vec4 mrt = texture(fa_mr_tex_fa_smp, i.uv);\n    float param_10 = fa_mesh_fs_params[6].w;\n    float param_11 = 64.0;\n    vec3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    vec3 _366 = fa_tex_fix(param_12, param_13);\n    vec4 _851 = mrt;\n    _851.x = _366.x;\n    _851.y = _366.y;\n    _851.z = _366.z;\n    mrt = _851;\n    vec4 _396 = texture(fa_occlusion_tex_fa_smp, i.uv);\n    float param_14 = fa_mesh_fs_params[6].w;\n    float param_15 = 256.0;\n    vec3 param_16 = _396.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    vec3 _408 = fa_tex_fix(param_16, param_17);\n    float param_18 = fa_mesh_fs_params[6].w;\n    float param_19 = 4.0;\n    vec3 param_20 = texture(fa_emissive_tex_fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    vec3 _438 = fa_tex_fix(param_20, param_21);\n    float _800 = fa_mesh_fs_params[20].x;\n    float _801 = fa_mesh_fs_params[20].y;\n    float _804 = fa_mesh_fs_params[20].z;\n    float _803 = fa_mesh_fs_params[21].w;\n    float _806 = fa_mesh_fs_params[22].x;\n    if (fa_mesh_fs_params[22].z > 0.5)\n    {\n        if (mod(fa_mesh_fs_params[22].z, 2.0) > 0.5)\n        {\n            _800 *= _408.y;\n            _801 *= _408.z;\n            _803 *= _396.w;\n        }\n        if (fa_mesh_fs_params[22].z > 1.5)\n        {\n            _804 *= mrt.x;\n            _806 *= mrt.w;\n        }\n    }\n    return Surface(_295.xyz, _295.w, _795, clamp(fa_mesh_fs_params[5].x * _366.z, 0.0, 1.0), clamp(fa_mesh_fs_params[5].y * _366.y, 0.0500000007450580596923828125, 1.0), 1.0 + (fa_mesh_fs_params[6].y * (_408.x - 1.0)), fa_mesh_fs_params[3].xyz + (fa_mesh_fs_params[4].xyz * _438), _800, _801, fa_mesh_fs_params[21].xyz, _803, _804, fa_mesh_fs_params[20].w, _806, fa_mesh_fs_params[22].y, fa_mesh_fs_params[23].xyz, fa_mesh_fs_params[30].x, fa_mesh_fs_params[30].y, fa_mesh_fs_params[31].xyz, fa_mesh_fs_params[30].z);\n}\n\nvoid surface(SurfaceInput i, inout Surface s)\n{\n    s.alpha = texture(mask_mask_smp, i.uv * 2.0).x;\n}\n\nvoid fa_lod_dither()\n{\n    if (fa_mesh_fs_params[52].w != 0.0)\n    {\n        float _151 = fract(52.98291778564453125 * fract(dot(gl_FragCoord.xy, vec2(0.067110560834407806396484375, 0.005837149918079376220703125))));\n        bool _154;\n        if (fa_mesh_fs_params[52].w > 0.0)\n        {\n            _154 = _151 >= fa_mesh_fs_params[52].w;\n        }\n        else\n        {\n            _154 = _151 < (-fa_mesh_fs_params[52].w);\n        }\n        if (_154)\n        {\n            discard;\n        }\n    }\n}\n\nvoid main()\n{\n    fa_inst_load();\n    vec3 _690 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _690 = -_690;\n    }\n    vec3 _590 = normalize(fa_mesh_fs_params[0].xyz - fa_world_pos);\n    SurfaceInput param = SurfaceInput(fa_world_pos, _690, fa_world_tangent, fa_uv, fa_vertex_color, _590, gl_FrontFacing);\n    Surface _595 = fa_standard_surface(param);\n    vec3 _714 = _595.normal;\n    SurfaceInput param_1 = SurfaceInput(fa_world_pos, _690, fa_world_tangent, fa_uv, fa_vertex_color, _590, gl_FrontFacing);\n    Surface param_2 = _595;\n    surface(param_1, param_2);\n    _714 = param_2.normal;\n    if (param_2.alpha < fa_material[0].x)\n    {\n        discard;\n    }\n    fa_lod_dither();\n    vec3 _617 = normalize(_714);\n    vec3 _632 = normalize(vec3(dot(fa_pre_r0, _617), dot(fa_pre_r1, _617), dot(fa_pre_r2, _617)));\n    float _644 = _632.z;\n    vec2 e = _632.xy / vec2((abs(_632.x) + abs(_632.y)) + abs(_644));\n    if (_644 < 0.0)\n    {\n        e = (vec2(1.0) - abs(e.yx)) * vec2((e.x >= 0.0) ? 1.0 : (-1.0), (e.y >= 0.0) ? 1.0 : (-1.0));\n    }\n    fa_frag_color = vec4(min(fa_pre_depth, 60000.0), e, 1.0);\n}\n\n",
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
          },
          {
            "slot": 5,
            "stage": "fragment",
            "size": 16,
            "struct_name": "fa_material",
            "inst_name": "_606",
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
    "shadow": {
      "vs": "#version 430\n\nstruct VertexData\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 color;\n    vec3 object_pos;\n};\n\nuniform vec4 fa_mesh_vs_params[11];\nlayout(location = 1) in vec4 fa_inst_m0;\nlayout(location = 2) in vec4 fa_inst_m1;\nlayout(location = 3) in vec4 fa_inst_m2;\nlayout(location = 4) in vec4 fa_inst_m3;\nlayout(location = 0) in vec3 fa_position;\nlayout(location = 5) in vec3 fa_normal;\nlayout(location = 7) in vec4 fa_tangent;\nlayout(location = 6) in vec2 fa_texcoord0;\nlayout(location = 8) in vec4 fa_color;\nlayout(location = 0) out vec3 fa_world_pos;\nlayout(location = 1) out vec3 fa_world_normal;\nlayout(location = 2) out vec4 fa_world_tangent;\nlayout(location = 3) out vec2 fa_uv;\nlayout(location = 4) out vec4 fa_vertex_color;\n\nvoid fa_inst_begin()\n{\n}\n\nVertexData fa_vertex_data(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    vec3 _60 = cross(model[1].xyz, model[2].xyz);\n    float _66 = (dot(model[0].xyz, _60) < 0.0) ? (-1.0) : 1.0;\n    return VertexData((model * vec4(position, 1.0)).xyz, (((_60 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _66, vec4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _66), texcoord0 * fa_mesh_vs_params[8].xy, color, position);\n}\n\nvoid main()\n{\n    fa_inst_begin();\n    mat4 param = mat4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3);\n    vec3 param_1 = fa_position;\n    vec3 param_2 = fa_normal;\n    vec4 param_3 = fa_tangent;\n    vec2 param_4 = fa_texcoord0;\n    vec4 param_5 = fa_color;\n    VertexData _190 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    vec3 _239 = _190.world_pos;\n    fa_world_pos = _239;\n    fa_world_normal = _190.world_normal;\n    fa_world_tangent = _190.world_tangent;\n    fa_uv = _190.uv;\n    fa_vertex_color = _190.color;\n    gl_Position = mat4(fa_mesh_vs_params[4], fa_mesh_vs_params[5], fa_mesh_vs_params[6], fa_mesh_vs_params[7]) * vec4(_239, 1.0);\n}\n\n",
      "fs": "#version 430\n\nstruct SurfaceInput\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 vertex_color;\n    vec3 view_dir;\n    bool front_facing;\n};\n\nstruct Surface\n{\n    vec3 albedo;\n    float alpha;\n    vec3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    vec3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    vec3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    vec3 specular_color;\n    float transmission;\n    float thickness;\n    vec3 attenuation_color;\n    float attenuation_distance;\n};\n\nuniform vec4 fa_mesh_fs_params[53];\nuniform vec4 fa_material[1];\nlayout(binding = 0) uniform sampler2D fa_tex_fa_smp;\nlayout(binding = 1) uniform sampler2D fa_normal_tex_fa_smp;\nlayout(binding = 2) uniform sampler2D fa_mr_tex_fa_smp;\nlayout(binding = 3) uniform sampler2D fa_occlusion_tex_fa_smp;\nlayout(binding = 4) uniform sampler2D fa_emissive_tex_fa_smp;\nlayout(binding = 5) uniform sampler2D mask_mask_smp;\n\nlayout(location = 0) in vec3 fa_world_pos;\nlayout(location = 1) in vec3 fa_world_normal;\nlayout(location = 2) in vec4 fa_world_tangent;\nlayout(location = 3) in vec2 fa_uv;\nlayout(location = 4) in vec4 fa_vertex_color;\nlayout(location = 0) out vec4 fa_frag_color;\n\nvoid fa_inst_load()\n{\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nvec3 fa_linear_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_tex_fix(inout vec3 c, float mode)\n{\n    if (mode > 1.5)\n    {\n        vec3 param = c;\n        vec3 _191 = fa_linear_to_srgb(param);\n        c = _191;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            vec3 param_1 = c;\n            vec3 _200 = fa_srgb_to_linear(param_1);\n            c = _200;\n        }\n    }\n    return c;\n}\n\nvec3 fa_tangent_normal(SurfaceInput i, vec3 m)\n{\n    vec3 _56;\n    if (i.front_facing)\n    {\n        _56 = i.world_normal;\n    }\n    else\n    {\n        _56 = -i.world_normal;\n    }\n    vec3 _81 = normalize(i.world_tangent.xyz - (_56 * dot(_56, i.world_tangent.xyz)));\n    vec3 _109 = normalize(((_81 * m.x) + ((cross(_56, _81) * i.world_tangent.w) * m.y)) + (_56 * m.z));\n    vec3 _112;\n    if (i.front_facing)\n    {\n        _112 = _109;\n    }\n    else\n    {\n        _112 = -_109;\n    }\n    return _112;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    vec4 base_t = texture(fa_tex_fa_smp, i.uv);\n    float param = fa_mesh_fs_params[6].w;\n    float param_1 = 1.0;\n    vec3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    vec3 _239 = fa_tex_fix(param_2, param_3);\n    vec4 _734 = base_t;\n    _734.x = _239.x;\n    _734.y = _239.y;\n    _734.z = _239.z;\n    base_t = _734;\n    vec4 _255 = (_734 * fa_mesh_fs_params[2]) * i.vertex_color;\n    vec3 _695 = i.world_normal;\n    if (fa_mesh_fs_params[6].z > 0.5)\n    {\n        float param_4 = fa_mesh_fs_params[6].w;\n        float param_5 = 16.0;\n        vec3 param_6 = texture(fa_normal_tex_fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        vec3 _289 = fa_tex_fix(param_6, param_7);\n        vec3 _292 = (_289 * 2.0) - vec3(1.0);\n        vec2 _297 = _292.xy * fa_mesh_fs_params[6].x;\n        vec3 _742 = _292;\n        _742.x = _297.x;\n        _742.y = _297.y;\n        SurfaceInput param_8 = i;\n        vec3 param_9 = _742;\n        _695 = fa_tangent_normal(param_8, param_9);\n    }\n    vec4 mrt = texture(fa_mr_tex_fa_smp, i.uv);\n    float param_10 = fa_mesh_fs_params[6].w;\n    float param_11 = 64.0;\n    vec3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    vec3 _326 = fa_tex_fix(param_12, param_13);\n    vec4 _745 = mrt;\n    _745.x = _326.x;\n    _745.y = _326.y;\n    _745.z = _326.z;\n    mrt = _745;\n    vec4 _356 = texture(fa_occlusion_tex_fa_smp, i.uv);\n    float param_14 = fa_mesh_fs_params[6].w;\n    float param_15 = 256.0;\n    vec3 param_16 = _356.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    vec3 _368 = fa_tex_fix(param_16, param_17);\n    float param_18 = fa_mesh_fs_params[6].w;\n    float param_19 = 4.0;\n    vec3 param_20 = texture(fa_emissive_tex_fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    vec3 _398 = fa_tex_fix(param_20, param_21);\n    float _700 = fa_mesh_fs_params[20].x;\n    float _701 = fa_mesh_fs_params[20].y;\n    float _704 = fa_mesh_fs_params[20].z;\n    float _703 = fa_mesh_fs_params[21].w;\n    float _706 = fa_mesh_fs_params[22].x;\n    if (fa_mesh_fs_params[22].z > 0.5)\n    {\n        if (mod(fa_mesh_fs_params[22].z, 2.0) > 0.5)\n        {\n            _700 *= _368.y;\n            _701 *= _368.z;\n            _703 *= _356.w;\n        }\n        if (fa_mesh_fs_params[22].z > 1.5)\n        {\n            _704 *= mrt.x;\n            _706 *= mrt.w;\n        }\n    }\n    return Surface(_255.xyz, _255.w, _695, clamp(fa_mesh_fs_params[5].x * _326.z, 0.0, 1.0), clamp(fa_mesh_fs_params[5].y * _326.y, 0.0500000007450580596923828125, 1.0), 1.0 + (fa_mesh_fs_params[6].y * (_368.x - 1.0)), fa_mesh_fs_params[3].xyz + (fa_mesh_fs_params[4].xyz * _398), _700, _701, fa_mesh_fs_params[21].xyz, _703, _704, fa_mesh_fs_params[20].w, _706, fa_mesh_fs_params[22].y, fa_mesh_fs_params[23].xyz, fa_mesh_fs_params[30].x, fa_mesh_fs_params[30].y, fa_mesh_fs_params[31].xyz, fa_mesh_fs_params[30].z);\n}\n\nvoid surface(SurfaceInput i, inout Surface s)\n{\n    s.alpha = texture(mask_mask_smp, i.uv * 2.0).x;\n}\n\nvoid main()\n{\n    fa_inst_load();\n    vec3 _590 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _590 = -_590;\n    }\n    vec3 _551 = normalize(fa_mesh_fs_params[0].xyz - fa_world_pos);\n    SurfaceInput param = SurfaceInput(fa_world_pos, _590, fa_world_tangent, fa_uv, fa_vertex_color, _551, gl_FrontFacing);\n    SurfaceInput param_1 = SurfaceInput(fa_world_pos, _590, fa_world_tangent, fa_uv, fa_vertex_color, _551, gl_FrontFacing);\n    Surface param_2 = fa_standard_surface(param);\n    surface(param_1, param_2);\n    if (param_2.alpha < fa_material[0].x)\n    {\n        discard;\n    }\n    fa_frag_color = vec4(gl_FragCoord.z, 0.0, 0.0, 1.0);\n}\n\n",
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
            "size": 848,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_227",
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
            "inst_name": "_567",
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
      "fs": "#version 430\n\nstruct SurfaceInput\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 vertex_color;\n    vec3 view_dir;\n    bool front_facing;\n};\n\nstruct Surface\n{\n    vec3 albedo;\n    float alpha;\n    vec3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    vec3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    vec3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    vec3 specular_color;\n    float transmission;\n    float thickness;\n    vec3 attenuation_color;\n    float attenuation_distance;\n};\n\nuniform vec4 fa_mesh_fs_params[53];\nuniform vec4 fa_material[1];\nlayout(binding = 0) uniform sampler2D fa_tex_fa_smp;\nlayout(binding = 1) uniform sampler2D fa_normal_tex_fa_smp;\nlayout(binding = 2) uniform sampler2D fa_mr_tex_fa_smp;\nlayout(binding = 3) uniform sampler2D fa_occlusion_tex_fa_smp;\nlayout(binding = 4) uniform sampler2D fa_emissive_tex_fa_smp;\nlayout(binding = 5) uniform sampler2D mask_mask_smp;\n\nlayout(location = 0) in vec3 fa_world_pos;\nlayout(location = 1) in vec3 fa_world_normal;\nlayout(location = 2) in vec4 fa_world_tangent;\nlayout(location = 3) in vec2 fa_uv;\nlayout(location = 4) in vec4 fa_vertex_color;\nlayout(location = 0) out vec4 fa_frag_color;\n\nvoid fa_inst_load()\n{\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nvec3 fa_linear_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_tex_fix(inout vec3 c, float mode)\n{\n    if (mode > 1.5)\n    {\n        vec3 param = c;\n        vec3 _191 = fa_linear_to_srgb(param);\n        c = _191;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            vec3 param_1 = c;\n            vec3 _200 = fa_srgb_to_linear(param_1);\n            c = _200;\n        }\n    }\n    return c;\n}\n\nvec3 fa_tangent_normal(SurfaceInput i, vec3 m)\n{\n    vec3 _56;\n    if (i.front_facing)\n    {\n        _56 = i.world_normal;\n    }\n    else\n    {\n        _56 = -i.world_normal;\n    }\n    vec3 _81 = normalize(i.world_tangent.xyz - (_56 * dot(_56, i.world_tangent.xyz)));\n    vec3 _109 = normalize(((_81 * m.x) + ((cross(_56, _81) * i.world_tangent.w) * m.y)) + (_56 * m.z));\n    vec3 _112;\n    if (i.front_facing)\n    {\n        _112 = _109;\n    }\n    else\n    {\n        _112 = -_109;\n    }\n    return _112;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    vec4 base_t = texture(fa_tex_fa_smp, i.uv);\n    float param = fa_mesh_fs_params[6].w;\n    float param_1 = 1.0;\n    vec3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    vec3 _239 = fa_tex_fix(param_2, param_3);\n    vec4 _734 = base_t;\n    _734.x = _239.x;\n    _734.y = _239.y;\n    _734.z = _239.z;\n    base_t = _734;\n    vec4 _255 = (_734 * fa_mesh_fs_params[2]) * i.vertex_color;\n    vec3 _695 = i.world_normal;\n    if (fa_mesh_fs_params[6].z > 0.5)\n    {\n        float param_4 = fa_mesh_fs_params[6].w;\n        float param_5 = 16.0;\n        vec3 param_6 = texture(fa_normal_tex_fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        vec3 _289 = fa_tex_fix(param_6, param_7);\n        vec3 _292 = (_289 * 2.0) - vec3(1.0);\n        vec2 _297 = _292.xy * fa_mesh_fs_params[6].x;\n        vec3 _742 = _292;\n        _742.x = _297.x;\n        _742.y = _297.y;\n        SurfaceInput param_8 = i;\n        vec3 param_9 = _742;\n        _695 = fa_tangent_normal(param_8, param_9);\n    }\n    vec4 mrt = texture(fa_mr_tex_fa_smp, i.uv);\n    float param_10 = fa_mesh_fs_params[6].w;\n    float param_11 = 64.0;\n    vec3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    vec3 _326 = fa_tex_fix(param_12, param_13);\n    vec4 _745 = mrt;\n    _745.x = _326.x;\n    _745.y = _326.y;\n    _745.z = _326.z;\n    mrt = _745;\n    vec4 _356 = texture(fa_occlusion_tex_fa_smp, i.uv);\n    float param_14 = fa_mesh_fs_params[6].w;\n    float param_15 = 256.0;\n    vec3 param_16 = _356.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    vec3 _368 = fa_tex_fix(param_16, param_17);\n    float param_18 = fa_mesh_fs_params[6].w;\n    float param_19 = 4.0;\n    vec3 param_20 = texture(fa_emissive_tex_fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    vec3 _398 = fa_tex_fix(param_20, param_21);\n    float _700 = fa_mesh_fs_params[20].x;\n    float _701 = fa_mesh_fs_params[20].y;\n    float _704 = fa_mesh_fs_params[20].z;\n    float _703 = fa_mesh_fs_params[21].w;\n    float _706 = fa_mesh_fs_params[22].x;\n    if (fa_mesh_fs_params[22].z > 0.5)\n    {\n        if (mod(fa_mesh_fs_params[22].z, 2.0) > 0.5)\n        {\n            _700 *= _368.y;\n            _701 *= _368.z;\n            _703 *= _356.w;\n        }\n        if (fa_mesh_fs_params[22].z > 1.5)\n        {\n            _704 *= mrt.x;\n            _706 *= mrt.w;\n        }\n    }\n    return Surface(_255.xyz, _255.w, _695, clamp(fa_mesh_fs_params[5].x * _326.z, 0.0, 1.0), clamp(fa_mesh_fs_params[5].y * _326.y, 0.0500000007450580596923828125, 1.0), 1.0 + (fa_mesh_fs_params[6].y * (_368.x - 1.0)), fa_mesh_fs_params[3].xyz + (fa_mesh_fs_params[4].xyz * _398), _700, _701, fa_mesh_fs_params[21].xyz, _703, _704, fa_mesh_fs_params[20].w, _706, fa_mesh_fs_params[22].y, fa_mesh_fs_params[23].xyz, fa_mesh_fs_params[30].x, fa_mesh_fs_params[30].y, fa_mesh_fs_params[31].xyz, fa_mesh_fs_params[30].z);\n}\n\nvoid surface(SurfaceInput i, inout Surface s)\n{\n    s.alpha = texture(mask_mask_smp, i.uv * 2.0).x;\n}\n\nvoid main()\n{\n    fa_inst_load();\n    vec3 _590 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _590 = -_590;\n    }\n    vec3 _551 = normalize(fa_mesh_fs_params[0].xyz - fa_world_pos);\n    SurfaceInput param = SurfaceInput(fa_world_pos, _590, fa_world_tangent, fa_uv, fa_vertex_color, _551, gl_FrontFacing);\n    SurfaceInput param_1 = SurfaceInput(fa_world_pos, _590, fa_world_tangent, fa_uv, fa_vertex_color, _551, gl_FrontFacing);\n    Surface param_2 = fa_standard_surface(param);\n    surface(param_1, param_2);\n    if (param_2.alpha < fa_material[0].x)\n    {\n        discard;\n    }\n    fa_frag_color = vec4(gl_FragCoord.z, 0.0, 0.0, 1.0);\n}\n\n",
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
            "size": 848,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_227",
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
            "inst_name": "_567",
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
