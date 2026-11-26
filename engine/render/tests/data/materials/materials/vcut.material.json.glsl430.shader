{
  "format": "factoria.shader/1",
  "engine": "0.38.0",
  "template": "fb558641ba41b387123470d76b096bf8c235ebdf6b030355e6627097d00c66b9",
  "slang": "glsl430",
  "params": [
    "alphaCutoff"
  ],
  "textures": [],
  "programs": {
    "mesh": {
      "vs": "#version 430\n\nstruct VertexData\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 color;\n    vec3 object_pos;\n};\n\nuniform vec4 fa_mesh_vs_params[11];\nlayout(location = 0) out vec3 fa_world_pos;\nlayout(location = 1) out vec3 fa_world_normal;\nlayout(location = 2) out vec4 fa_world_tangent;\nlayout(location = 3) out vec2 fa_uv;\nlayout(location = 4) out vec4 fa_vertex_color;\nlayout(location = 5) in vec4 fa_inst_m0;\nlayout(location = 6) in vec4 fa_inst_m1;\nlayout(location = 7) in vec4 fa_inst_m2;\nlayout(location = 8) in vec4 fa_inst_m3;\nlayout(location = 0) in vec3 fa_position;\nlayout(location = 1) in vec3 fa_normal;\nlayout(location = 3) in vec4 fa_tangent;\nlayout(location = 2) in vec2 fa_texcoord0;\nlayout(location = 4) in vec4 fa_color;\nlayout(location = 5) out vec3 fa_lm;\n\nvoid fa_inst_begin()\n{\n}\n\nVertexData fa_vertex_data(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    vec3 _69 = cross(model[1].xyz, model[2].xyz);\n    float _75 = (dot(model[0].xyz, _69) < 0.0) ? (-1.0) : 1.0;\n    return VertexData((model * vec4(position, 1.0)).xyz, (((_69 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _75, vec4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _75), texcoord0 * fa_mesh_vs_params[8].xy, color, position);\n}\n\nvoid fa_shade_vertex(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    mat4 param = model;\n    vec3 param_1 = position;\n    vec3 param_2 = normal;\n    vec4 param_3 = tangent;\n    vec2 param_4 = texcoord0;\n    vec4 param_5 = color;\n    VertexData _160 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    vec3 _270 = _160.world_pos;\n    fa_world_pos = _270;\n    fa_world_normal = _160.world_normal;\n    fa_world_tangent = _160.world_tangent;\n    fa_uv = _160.uv;\n    fa_vertex_color = _160.color;\n    gl_Position = mat4(fa_mesh_vs_params[0], fa_mesh_vs_params[1], fa_mesh_vs_params[2], fa_mesh_vs_params[3]) * vec4(_270, 1.0);\n}\n\nvoid main()\n{\n    fa_inst_begin();\n    mat4 param = mat4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3);\n    vec3 param_1 = fa_position;\n    vec3 param_2 = fa_normal;\n    vec4 param_3 = fa_tangent;\n    vec2 param_4 = fa_texcoord0;\n    vec4 param_5 = fa_color;\n    fa_shade_vertex(param, param_1, param_2, param_3, param_4, param_5);\n    fa_lm = vec3(0.0);\n}\n\n",
      "fs": "#version 430\n\nstruct SurfaceInput\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 vertex_color;\n    vec3 view_dir;\n    bool front_facing;\n};\n\nstruct LightSample\n{\n    vec3 direction;\n    vec3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct Surface\n{\n    vec3 albedo;\n    float alpha;\n    vec3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    vec3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    vec3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    vec3 specular_color;\n    float transmission;\n    float thickness;\n    vec3 attenuation_color;\n    float attenuation_distance;\n};\n\nstruct FaLayers\n{\n    bool on;\n    float f90;\n    float keep;\n    float base_scale;\n    float coat;\n    float coat_rough;\n    float coat_alpha;\n    float coat_a2;\n    vec3 nc;\n    float coat_ndv;\n    bool sheen_on;\n    vec3 sheen;\n    float sheen_rough;\n    float sheen_alpha;\n    float sheen_scale;\n    float sheen_e;\n    float aniso;\n    vec3 t;\n    vec3 b;\n    float at;\n    float ab;\n};\n\nconst float _4559[63] = float[](1.0, 1.0, 1.0, 0.4790000021457672119140625, 0.11699999868869781494140625, 0.01200000010430812835693359375, 0.0, 0.0, 0.0, 1.0, 1.0, 1.0, 0.578000009059906005859375, 0.19300000369548797607421875, 0.0350000001490116119384765625, 0.0030000000260770320892333984375, 0.0, 0.0, 1.0, 1.0, 1.0, 0.6740000247955322265625, 0.3459999859333038330078125, 0.1319999992847442626953125, 0.032999999821186065673828125, 0.0040000001899898052215576171875, 0.0, 0.971000015735626220703125, 0.954999983310699462890625, 0.828999996185302734375, 0.63999998569488525390625, 0.42599999904632568359375, 0.24500000476837158203125, 0.115000002086162567138671875, 0.037000000476837158203125, 0.0030000000260770320892333984375, 0.7469999790191650390625, 0.737999975681304931640625, 0.670000016689300537109375, 0.563000023365020751953125, 0.4309999942779541015625, 0.3039999902248382568359375, 0.1940000057220458984375, 0.1019999980926513671875, 0.0309999994933605194091796875, 0.614000022411346435546875, 0.609000027179718017578125, 0.566999971866607666015625, 0.499000012874603271484375, 0.412000000476837158203125, 0.32400000095367431640625, 0.240999996662139892578125, 0.162000000476837158203125, 0.087999999523162841796875, 0.538999974727630615234375, 0.535000026226043701171875, 0.505999982357025146484375, 0.4569999873638153076171875, 0.393999993801116943359375, 0.328999996185302734375, 0.2660000026226043701171875, 0.203999996185302734375, 0.14200000464916229248046875);\n\nuniform vec4 fa_mesh_fs_params[53];\nuniform vec4 fa_shadows[30];\nuniform vec4 fa_material[1];\nlayout(binding = 0) uniform sampler2D fa_light_tex_fa_shadow_smp;\nlayout(binding = 1) uniform sampler2D fa_tex_fa_smp;\nlayout(binding = 2) uniform sampler2D fa_normal_tex_fa_smp;\nlayout(binding = 3) uniform sampler2D fa_mr_tex_fa_smp;\nlayout(binding = 4) uniform sampler2D fa_occlusion_tex_fa_smp;\nlayout(binding = 5) uniform sampler2D fa_emissive_tex_fa_smp;\nlayout(binding = 6) uniform sampler2D fa_decal_tex_fa_env_smp;\nlayout(binding = 7) uniform sampler2D fa_lightmap_fa_env_smp;\nlayout(binding = 8) uniform sampler2D fa_probe_atlas_fa_env_smp;\nlayout(binding = 9) uniform sampler2D fa_light_atlas_fa_env_smp;\nlayout(binding = 10) uniform sampler2D fa_screen_tex_fa_shadow_smp;\nlayout(binding = 11) uniform sampler2D fa_shadow_tex_fa_shadow_smp;\n\nlayout(location = 0) in vec3 fa_world_pos;\nlayout(location = 5) in vec3 fa_lm;\nlayout(location = 1) in vec3 fa_world_normal;\nlayout(location = 2) in vec4 fa_world_tangent;\nlayout(location = 3) in vec2 fa_uv;\nlayout(location = 4) in vec4 fa_vertex_color;\nlayout(location = 0) out vec4 fa_frag_color;\nvec3 fa_light_tint;\nbool fa_light_is_area;\nint fa_cl_ndir;\nint fa_cl_slot;\nint fa_cl_local;\n\nvoid fa_inst_load()\n{\n}\n\nvec4 fa_light_texel(int t)\n{\n    return texelFetch(fa_light_tex_fa_shadow_smp, ivec2(t & 1023, t >> 10), 0);\n}\n\nvec4 fa_cluster_texel(vec3 world_pos)\n{\n    bool _1628 = fa_mesh_fs_params[19].x < 0.0;\n    bool _1635;\n    if (!_1628)\n    {\n        _1635 = fa_mesh_fs_params[19].w < 1.0;\n    }\n    else\n    {\n        _1635 = _1628;\n    }\n    bool _1643;\n    if (!_1635)\n    {\n        _1643 = fa_mesh_fs_params[18].x < 1.0;\n    }\n    else\n    {\n        _1643 = _1635;\n    }\n    bool _1650;\n    if (!_1643)\n    {\n        _1650 = fa_mesh_fs_params[18].y < 1.0;\n    }\n    else\n    {\n        _1650 = _1643;\n    }\n    bool _1657;\n    if (!_1650)\n    {\n        _1657 = fa_mesh_fs_params[19].y < 1.0;\n    }\n    else\n    {\n        _1657 = _1650;\n    }\n    if (_1657)\n    {\n        return vec4(0.0);\n    }\n    vec4 _1667 = vec4(world_pos, 1.0);\n    float _1673 = dot(fa_mesh_fs_params[16], _1667);\n    if (!(_1673 > 9.9999999747524270787835121154785e-07))\n    {\n        return vec4(0.0);\n    }\n    vec2 _1695 = vec2(dot(fa_mesh_fs_params[14], _1667), dot(fa_mesh_fs_params[15], _1667)) / vec2(_1673);\n    int _1699 = int(fa_mesh_fs_params[18].x);\n    int _1703 = int(fa_mesh_fs_params[18].y);\n    int param = (int(fa_mesh_fs_params[19].x) + (((clamp(int(floor(log2(max(dot(fa_mesh_fs_params[17].xyz, world_pos) + fa_mesh_fs_params[17].w, fa_mesh_fs_params[18].w) / fa_mesh_fs_params[18].w) * fa_mesh_fs_params[18].z)), 0, int(fa_mesh_fs_params[19].y) - 1) * _1703) + clamp(int(floor(((_1695.y * 0.5) + 0.5) * fa_mesh_fs_params[18].y)), 0, _1703 - 1)) * _1699)) + clamp(int(floor(((_1695.x * 0.5) + 0.5) * fa_mesh_fs_params[18].x)), 0, _1699 - 1);\n    return fa_light_texel(param);\n}\n\nivec2 fa_cluster_lookup(vec3 world_pos)\n{\n    vec3 param = world_pos;\n    vec4 _1779 = fa_cluster_texel(param);\n    return ivec2(int(_1779.x), int(_1779.y));\n}\n\nvoid fa_cluster_begin(vec3 world_pos)\n{\n    fa_cl_ndir = int(fa_mesh_fs_params[19].z);\n    vec3 param = world_pos;\n    ivec2 _6193 = fa_cluster_lookup(param);\n    fa_cl_slot = _6193.x;\n    fa_cl_local = _6193.y;\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nvec3 fa_linear_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_tex_fix(inout vec3 c, float mode)\n{\n    if (mode > 1.5)\n    {\n        vec3 param = c;\n        vec3 _7352 = fa_linear_to_srgb(param);\n        c = _7352;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            vec3 param_1 = c;\n            vec3 _7360 = fa_srgb_to_linear(param_1);\n            c = _7360;\n        }\n    }\n    return c;\n}\n\nvec3 fa_tangent_normal(SurfaceInput i, vec3 m)\n{\n    vec3 _534;\n    if (i.front_facing)\n    {\n        _534 = i.world_normal;\n    }\n    else\n    {\n        _534 = -i.world_normal;\n    }\n    vec3 _558 = normalize(i.world_tangent.xyz - (_534 * dot(_534, i.world_tangent.xyz)));\n    vec3 _585 = normalize(((_558 * m.x) + ((cross(_534, _558) * i.world_tangent.w) * m.y)) + (_534 * m.z));\n    vec3 _588;\n    if (i.front_facing)\n    {\n        _588 = _585;\n    }\n    else\n    {\n        _588 = -_585;\n    }\n    return _588;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    vec4 base_t = texture(fa_tex_fa_smp, i.uv, fa_mesh_fs_params[12].w);\n    float param = fa_mesh_fs_params[6].w;\n    float param_1 = 1.0;\n    vec3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    vec3 _7392 = fa_tex_fix(param_2, param_3);\n    vec4 _9689 = base_t;\n    _9689.x = _7392.x;\n    _9689.y = _7392.y;\n    _9689.z = _7392.z;\n    base_t = _9689;\n    vec4 _7406 = (_9689 * fa_mesh_fs_params[2]) * i.vertex_color;\n    vec3 _9449 = i.world_normal;\n    if (fa_mesh_fs_params[6].z > 0.5)\n    {\n        float param_4 = fa_mesh_fs_params[6].w;\n        float param_5 = 16.0;\n        vec3 param_6 = texture(fa_normal_tex_fa_smp, i.uv, fa_mesh_fs_params[12].w).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        vec3 _7440 = fa_tex_fix(param_6, param_7);\n        vec3 _7443 = (_7440 * 2.0) - vec3(1.0);\n        vec2 _7448 = _7443.xy * fa_mesh_fs_params[6].x;\n        vec3 _9697 = _7443;\n        _9697.x = _7448.x;\n        _9697.y = _7448.y;\n        SurfaceInput param_8 = i;\n        vec3 param_9 = _9697;\n        _9449 = fa_tangent_normal(param_8, param_9);\n    }\n    vec4 mrt = texture(fa_mr_tex_fa_smp, i.uv, fa_mesh_fs_params[12].w);\n    float param_10 = fa_mesh_fs_params[6].w;\n    float param_11 = 64.0;\n    vec3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    vec3 _7478 = fa_tex_fix(param_12, param_13);\n    vec4 _9700 = mrt;\n    _9700.x = _7478.x;\n    _9700.y = _7478.y;\n    _9700.z = _7478.z;\n    mrt = _9700;\n    vec4 _7508 = texture(fa_occlusion_tex_fa_smp, i.uv, fa_mesh_fs_params[12].w);\n    float param_14 = fa_mesh_fs_params[6].w;\n    float param_15 = 256.0;\n    vec3 param_16 = _7508.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    vec3 _7519 = fa_tex_fix(param_16, param_17);\n    float param_18 = fa_mesh_fs_params[6].w;\n    float param_19 = 4.0;\n    vec3 param_20 = texture(fa_emissive_tex_fa_smp, i.uv, fa_mesh_fs_params[12].w).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    vec3 _7551 = fa_tex_fix(param_20, param_21);\n    float _9454 = fa_mesh_fs_params[20].x;\n    float _9455 = fa_mesh_fs_params[20].y;\n    float _9458 = fa_mesh_fs_params[20].z;\n    float _9457 = fa_mesh_fs_params[21].w;\n    float _9460 = fa_mesh_fs_params[22].x;\n    if (fa_mesh_fs_params[22].z > 0.5)\n    {\n        if (mod(fa_mesh_fs_params[22].z, 2.0) > 0.5)\n        {\n            _9454 *= _7519.y;\n            _9455 *= _7519.z;\n            _9457 *= _7508.w;\n        }\n        if (fa_mesh_fs_params[22].z > 1.5)\n        {\n            _9458 *= mrt.x;\n            _9460 *= mrt.w;\n        }\n    }\n    return Surface(_7406.xyz, _7406.w, _9449, clamp(fa_mesh_fs_params[5].x * _7478.z, 0.0, 1.0), clamp(fa_mesh_fs_params[5].y * _7478.y, 0.0500000007450580596923828125, 1.0), 1.0 + (fa_mesh_fs_params[6].y * (_7519.x - 1.0)), fa_mesh_fs_params[3].xyz + (fa_mesh_fs_params[4].xyz * _7551), _9454, _9455, fa_mesh_fs_params[21].xyz, _9457, _9458, fa_mesh_fs_params[20].w, _9460, fa_mesh_fs_params[22].y, fa_mesh_fs_params[23].xyz, fa_mesh_fs_params[30].x, fa_mesh_fs_params[30].y, fa_mesh_fs_params[31].xyz, fa_mesh_fs_params[30].z);\n}\n\nvoid surface(SurfaceInput i, Surface s)\n{\n}\n\nvec4 fa_decal_tile(vec4 rect, vec2 uv, vec2 atlas, vec2 ddx, vec2 ddy)\n{\n    vec2 _1859 = rect.zw - rect.xy;\n    vec2 _1863 = _1859 * atlas;\n    vec2 _1867 = ddx * _1863;\n    vec2 _1871 = ddy * _1863;\n    return textureLod(fa_decal_tex_fa_env_smp, rect.xy + (clamp(uv, vec2(0.0), vec2(1.0)) * _1859), clamp(0.5 * log2(max(max(dot(_1867, _1867), dot(_1871, _1871)), 9.9999999392252902907785028219223e-09)), 0.0, 3.0));\n}\n\nvec3 fa_dc_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_dc_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvoid fa_apply_decals(vec3 world_pos, vec3 geo_normal, inout vec3 albedo, inout vec3 normal)\n{\n    bool _1904 = fa_mesh_fs_params[10].y < 0.5;\n    bool _1911;\n    if (!_1904)\n    {\n        _1911 = fa_mesh_fs_params[10].w < 0.5;\n    }\n    else\n    {\n        _1911 = _1904;\n    }\n    if (_1911)\n    {\n        return;\n    }\n    vec3 _1917 = dFdx(world_pos);\n    vec3 _1920 = dFdy(world_pos);\n    vec3 param = world_pos;\n    vec4 _1924 = fa_cluster_texel(param);\n    int _1928 = int(_1924.w);\n    if (_1928 < 1)\n    {\n        return;\n    }\n    int _1938 = int(fa_mesh_fs_params[10].y + 0.5);\n    int param_1 = _1938;\n    vec4 _1942 = fa_light_texel(param_1);\n    vec2 _1945 = _1942.yz;\n    int _1949 = int(_1942.w);\n    int param_2 = _1938 + 1;\n    vec4 _1954 = fa_light_texel(param_2);\n    float _1955 = _1954.x;\n    int _1961 = int(fa_mesh_fs_params[10].w + 0.5) - 1;\n    int _1965 = int(_1924.z);\n    vec3 _2230;\n    for (int k = 0; k < _1928; k++)\n    {\n        int _1978 = _1965 + k;\n        int param_3 = _1949 + (_1978 >> 2);\n        int _1995 = (_1938 + 2) + (int(fa_light_texel(param_3)[_1978 & 3]) * 7);\n        int param_4 = _1995 + 6;\n        vec4 _2000 = fa_light_texel(param_4);\n        if (((int(_2000.w + 0.5) >> _1961) & 1) == 0)\n        {\n            continue;\n        }\n        int param_5 = _1995;\n        vec4 _2015 = fa_light_texel(param_5);\n        int param_6 = _1995 + 1;\n        vec4 _2020 = fa_light_texel(param_6);\n        int param_7 = _1995 + 2;\n        vec4 _2025 = fa_light_texel(param_7);\n        vec3 _2028 = _2015.xyz;\n        float _2033 = dot(_2028, world_pos) + _2015.w;\n        vec3 _2035 = _2020.xyz;\n        float _2040 = dot(_2035, world_pos) + _2020.w;\n        vec3 _2042 = _2025.xyz;\n        float _2047 = dot(_2042, world_pos) + _2025.w;\n        bool _2052 = abs(_2033) > 0.5;\n        bool _2060;\n        if (!_2052)\n        {\n            _2060 = abs(_2040) > 0.5;\n        }\n        else\n        {\n            _2060 = _2052;\n        }\n        bool _2068;\n        if (!_2060)\n        {\n            _2068 = abs(_2047) > 0.5;\n        }\n        else\n        {\n            _2068 = _2060;\n        }\n        if (_2068)\n        {\n            continue;\n        }\n        float _2083 = clamp(dot(geo_normal, normalize(_2042)) * _2000.z, 0.0, 1.0);\n        if (_2083 <= 0.0)\n        {\n            continue;\n        }\n        float _2103 = (clamp((0.5 - abs(_2047)) * 10.0, 0.0, 1.0) * _2083) * _2000.x;\n        vec2 _2111 = vec2(_2033 + 0.5, 0.5 - _2040);\n        vec2 _2121 = vec2(dot(_2028, _1917), dot(_2035, _1917));\n        vec2 _2131 = vec2(dot(_2028, _1920), dot(_2035, _1920));\n        int param_8 = _1995 + 5;\n        vec4 _2136 = fa_light_texel(param_8);\n        int param_9 = _1995 + 3;\n        vec4 _2141 = fa_light_texel(param_9);\n        int param_10 = _1995 + 4;\n        vec4 _2146 = fa_light_texel(param_10);\n        float tex_a = 1.0;\n        vec3 col = _2136.xyz;\n        bool _2156 = _2141.z > _2141.x;\n        if (_2156)\n        {\n            vec4 param_11 = _2141;\n            vec2 param_12 = _2111;\n            vec2 param_13 = _1945;\n            vec2 param_14 = _2121;\n            vec2 param_15 = _2131;\n            vec4 tx = fa_decal_tile(param_11, param_12, param_13, param_14, param_15);\n            if ((_1955 > 0.5) && (_1955 < 1.5))\n            {\n                vec3 param_16 = tx.xyz;\n                vec3 _2182 = fa_dc_to_linear(param_16);\n                vec4 _9537 = tx;\n                _9537.x = _2182.x;\n                _9537.y = _2182.y;\n                _9537.z = _2182.z;\n                tx = _9537;\n            }\n            col *= tx.xyz;\n            tex_a = tx.w;\n        }\n        albedo = mix(albedo, col, vec3(clamp((_2103 * tex_a) * _2136.w, 0.0, 1.0)));\n        if (_2146.z > _2146.x)\n        {\n            vec4 param_17 = _2146;\n            vec2 param_18 = _2111;\n            vec2 param_19 = _1945;\n            vec2 param_20 = _2121;\n            vec2 param_21 = _2131;\n            vec4 _2226 = fa_decal_tile(param_17, param_18, param_19, param_20, param_21);\n            if (_1955 > 1.5)\n            {\n                vec3 param_22 = _2226.xyz;\n                vec3 _2236 = fa_dc_to_srgb(param_22);\n                _2230 = _2236;\n            }\n            else\n            {\n                _2230 = _2226.xyz;\n            }\n            vec3 _2245 = (_2230 * 2.0) - vec3(1.0);\n            vec2 _2250 = _2245.xy * _2000.y;\n            vec3 _2272 = (normalize(_2028) * _2250.x) + (normalize(_2035) * _2250.y);\n            vec3 _2275 = normalize(normal);\n            normal = normalize(mix(_2275, normalize((_2275 * max(_2245.z, 0.0500000007450580596923828125)) + (_2272 - (_2275 * dot(_2275, _2272)))), vec3(clamp(_2103 * (_2156 ? tex_a : 1.0), 0.0, 1.0))));\n        }\n    }\n}\n\nvoid fa_lod_dither()\n{\n    if (fa_mesh_fs_params[52].w != 0.0)\n    {\n        float _624 = fract(52.98291778564453125 * fract(dot(gl_FragCoord.xy, vec2(0.067110560834407806396484375, 0.005837149918079376220703125))));\n        bool _627;\n        if (fa_mesh_fs_params[52].w > 0.0)\n        {\n            _627 = _624 >= fa_mesh_fs_params[52].w;\n        }\n        else\n        {\n            _627 = _624 < (-fa_mesh_fs_params[52].w);\n        }\n        if (_627)\n        {\n            discard;\n        }\n    }\n}\n\nfloat fa_sheen_albedo(float ndv, float rough)\n{\n    float _4484 = min(sqrt(max(rough - 0.100000001490116119384765625, 0.0) * 1.111111164093017578125) * 6.0, 5.999000072479248046875);\n    float _4492 = min(sqrt(clamp(ndv, 0.0, 1.0)) * 8.0, 7.999000072479248046875);\n    int _4495 = int(_4484);\n    int _4498 = int(_4492);\n    float _4508 = _4492 - float(_4498);\n    int _4563 = (_4495 * 9) + _4498;\n    int _4583 = ((_4495 + 1) * 9) + _4498;\n    return mix(mix(_4559[_4563], _4559[_4563 + 1], _4508), mix(_4559[_4583], _4559[_4583 + 1], _4508), _4484 - float(_4495));\n}\n\nFaLayers fa_layers_setup(SurfaceInput i, Surface s, vec3 n, vec3 v, float metallic, float roughness, inout vec3 f0)\n{\n    bool _9372 = false;\n    float _9373 = 1.0;\n    float _9374 = 1.0;\n    float _9375 = 1.0;\n    float _9376 = 0.0;\n    float _9377 = 0.0;\n    float _9378 = 0.0;\n    float _9379 = 0.0;\n    float _9381 = 1.0;\n    bool _9382 = false;\n    vec3 _9383 = vec3(0.0);\n    float _9384 = 1.0;\n    float _9385 = 1.0;\n    float _9386 = 1.0;\n    float _9387 = 0.0;\n    float _9388 = 0.0;\n    vec3 _9389 = vec3(1.0, 0.0, 0.0);\n    vec3 _9390 = vec3(0.0, 0.0, 1.0);\n    float _9391 = 1.0;\n    float _9392 = 1.0;\n    float _4634 = clamp(s.specular, 0.0, 1.0);\n    float _4638 = clamp(s.ior, 1.0, 3.0);\n    bool _4643 = (_4634 != 1.0) || (_4638 != 1.5);\n    bool _4652;\n    if (!_4643)\n    {\n        _4652 = any(notEqual(s.specular_color, vec3(1.0)));\n    }\n    else\n    {\n        _4652 = _4643;\n    }\n    if (_4652)\n    {\n        float _4660 = (_4638 - 1.0) / (_4638 + 1.0);\n        f0 = mix(min(vec3(_4660 * _4660) * max(s.specular_color, vec3(0.0)), vec3(1.0)) * _4634, s.albedo, vec3(metallic));\n        _9373 = mix(_4634, 1.0, metallic);\n        _9372 = true;\n    }\n    float _4687 = clamp(s.clearcoat, 0.0, 1.0);\n    if (_4687 > 0.0)\n    {\n        float _4695 = clamp(s.clearcoat_roughness, 0.0500000007450580596923828125, 1.0);\n        _9376 = _4687;\n        _9377 = _4695;\n        float _4702 = _4695 * _4695;\n        _9378 = _4702;\n        _9379 = _4702 * _4702;\n        float _4714 = max(dot(i.world_normal, v), 9.9999997473787516355514526367188e-05);\n        _9381 = _4714;\n        _9374 = 1.0 - (_4687 * (0.039999999105930328369140625 + (0.959999978542327880859375 * pow(clamp(1.0 - _4714, 0.0, 1.0), 5.0))));\n        _9372 = true;\n    }\n    vec3 _4733 = max(s.sheen_color, vec3(0.0));\n    float _4742 = max(_4733.x, max(_4733.y, _4733.z));\n    if (_4742 > 0.0)\n    {\n        float _4750 = clamp(s.sheen_roughness, 0.100000001490116119384765625, 1.0);\n        _9382 = true;\n        _9383 = _4733;\n        _9384 = _4750;\n        _9385 = _4750 * _4750;\n        float param = max(dot(n, v), 9.9999997473787516355514526367188e-05);\n        float param_1 = _4750;\n        float _4767 = fa_sheen_albedo(param, param_1);\n        _9387 = _4767;\n        _9386 = 1.0 - min(_4742 * _4767, 1.0);\n        _9372 = true;\n    }\n    _9375 = _9374 * _9386;\n    float _4786 = clamp(s.anisotropy, -1.0, 1.0);\n    if (_4786 != 0.0)\n    {\n        vec3 _4801 = i.world_tangent.xyz - (n * dot(n, i.world_tangent.xyz));\n        vec3 t = _4801;\n        if (dot(_4801, _4801) < 9.9999999392252902907785028219223e-09)\n        {\n            bvec3 _4813 = bvec3(abs(n.y) < 0.9900000095367431640625);\n            t = cross(vec3(_4813.x ? vec3(0.0, 1.0, 0.0).x : vec3(1.0, 0.0, 0.0).x, _4813.y ? vec3(0.0, 1.0, 0.0).y : vec3(1.0, 0.0, 0.0).y, _4813.z ? vec3(0.0, 1.0, 0.0).z : vec3(1.0, 0.0, 0.0).z), n);\n        }\n        vec3 _4817 = t;\n        vec3 _4818 = normalize(_4817);\n        t = _4818;\n        vec3 _4843 = normalize((_4818 * cos(s.anisotropy_rotation)) + ((cross(n, _4818) * ((i.world_tangent.w < 0.0) ? (-1.0) : 1.0)) * sin(s.anisotropy_rotation)));\n        _9389 = _4843;\n        _9390 = cross(n, _4843);\n        float _4853 = roughness * roughness;\n        float _4859 = mix(_4853, 1.0, _4786 * _4786);\n        bool _4861 = _4786 > 0.0;\n        _9391 = _4861 ? _4859 : _4853;\n        _9392 = _4861 ? _4853 : _4859;\n        _9388 = _4786;\n        _9372 = true;\n    }\n    return FaLayers(_9372, _9373, _9374, _9375, _9376, _9377, _9378, _9379, i.world_normal, _9381, _9382, _9383, _9384, _9385, _9386, _9387, _9388, _9389, _9390, _9391, _9392);\n}\n\nvec2 fa_atlas_size()\n{\n    return vec2(textureSize(fa_probe_atlas_fa_env_smp, 0));\n}\n\nvec3 fa_probe_sh_coef(vec2 origin, float res, int k)\n{\n    vec3 v = textureLod(fa_probe_atlas_fa_env_smp, (origin + vec2(float(k) + 0.5, res + 2.5)) / fa_atlas_size(), 0.0).xyz;\n    if (fa_mesh_fs_params[41].y > 0.5)\n    {\n        v = ((v * 255.0) - vec3(128.0)) * 0.03149606287479400634765625;\n    }\n    return v;\n}\n\nvec3 fa_sh_eval(vec3 c[9], vec3 n)\n{\n    vec3 _3653 = max((((c[0] * 0.2820948064327239990234375) + (((c[1] * (0.3257350027561187744140625 * n.y)) + (c[2] * (0.3257350027561187744140625 * n.z))) + (c[3] * (0.3257350027561187744140625 * n.x)))) + (((c[4] * ((0.2731371223926544189453125 * n.x) * n.y)) + (c[5] * ((0.2731371223926544189453125 * n.y) * n.z))) + (c[6] * (0.078847892582416534423828125 * (((3.0 * n.z) * n.z) - 1.0))))) + ((c[7] * ((0.2731371223926544189453125 * n.x) * n.z)) + (c[8] * (0.13656856119632720947265625 * ((n.x * n.x) - (n.y * n.y))))), vec3(0.0));\n    return _3653;\n}\n\nvec3 fa_ambient_light(vec3 n)\n{\n    float _4265 = (1.0 - fa_mesh_fs_params[42].w) - fa_mesh_fs_params[47].w;\n    vec3 amb = vec3(0.0);\n    bool _4270 = fa_mesh_fs_params[11].w > 0.5;\n    vec3 c[9];\n    for (int k = 0; k < 9; k++)\n    {\n        c[k] = vec3(0.0);\n    }\n    if (_4265 > 0.0005000000237487256526947021484375)\n    {\n        if (_4270)\n        {\n            for (int k_1 = 0; k_1 < 9; k_1++)\n            {\n                vec2 param = fa_mesh_fs_params[41].zw;\n                float param_1 = 128.0;\n                int param_2 = k_1;\n                c[k_1] = fa_probe_sh_coef(param, param_1, param_2) * _4265;\n            }\n        }\n        else\n        {\n            amb = fa_mesh_fs_params[1].xyz * _4265;\n        }\n    }\n    bool _4321 = fa_mesh_fs_params[42].w > 0.0;\n    if (_4321)\n    {\n        for (int k_2 = 0; k_2 < 9; k_2++)\n        {\n            vec2 param_3 = fa_mesh_fs_params[42].xy;\n            float param_4 = fa_mesh_fs_params[42].z;\n            int param_5 = k_2;\n            c[k_2] += (fa_probe_sh_coef(param_3, param_4, param_5) * fa_mesh_fs_params[42].w);\n        }\n    }\n    bool _4352 = fa_mesh_fs_params[47].w > 0.0;\n    if (_4352)\n    {\n        for (int k_3 = 0; k_3 < 9; k_3++)\n        {\n            vec2 param_6 = fa_mesh_fs_params[47].xy;\n            float param_7 = fa_mesh_fs_params[47].z;\n            int param_8 = k_3;\n            c[k_3] += (fa_probe_sh_coef(param_6, param_7, param_8) * fa_mesh_fs_params[47].w);\n        }\n    }\n    if ((_4270 || _4321) || _4352)\n    {\n        vec3 param_9[9] = c;\n        vec3 param_10 = n;\n        amb += fa_sh_eval(param_9, param_10);\n    }\n    return amb;\n}\n\nvec4 fa_gi_fetch(vec2 texel)\n{\n    return textureLod(fa_probe_atlas_fa_env_smp, texel / fa_atlas_size(), 0.0);\n}\n\nvec2 fa_oct_encode(vec3 d)\n{\n    vec3 _3673 = d / vec3(max((abs(d.x) + abs(d.y)) + abs(d.z), 9.9999999600419720025001879548654e-13));\n    float _3676 = _3673.x;\n    float _3678 = _3673.z;\n    vec2 e = vec2(_3676, _3678);\n    if (_3673.y < 0.0)\n    {\n        e = vec2((1.0 - abs(_3678)) * ((_3676 < 0.0) ? (-1.0) : 1.0), (1.0 - abs(_3676)) * ((_3678 < 0.0) ? (-1.0) : 1.0));\n    }\n    return e;\n}\n\nvec3 fa_gi_grid(int rec, vec3 n, vec3 v, out float cover)\n{\n    cover = 0.0;\n    int param = rec;\n    vec4 _7661 = fa_light_texel(param);\n    int param_1 = rec + 1;\n    vec4 _7666 = fa_light_texel(param_1);\n    int param_2 = rec + 2;\n    vec4 _7671 = fa_light_texel(param_2);\n    int param_3 = rec + 3;\n    vec4 _7676 = fa_light_texel(param_3);\n    bool _7679 = _7676.z < 0.5;\n    bool _7687;\n    if (!_7679)\n    {\n        _7687 = fa_atlas_size().y < 1155.0;\n    }\n    else\n    {\n        _7687 = _7679;\n    }\n    if (_7687)\n    {\n        return vec3(0.0);\n    }\n    float _7694 = max(_7661.w, 9.9999997473787516355514526367188e-05);\n    vec3 _7697 = _7666.xyz;\n    vec3 _7701 = _7661.xyz;\n    vec3 _7705 = (fa_world_pos - _7701) / vec3(_7694);\n    vec3 _7714 = min(_7705 + vec3(0.5), (_7697 - vec3(0.5)) - _7705);\n    float _7723 = min(_7714.x, min(_7714.y, _7714.z));\n    if (!(_7723 > 0.0))\n    {\n        return vec3(0.0);\n    }\n    vec3 _7738 = _7697 - vec3(1.0);\n    vec3 _7739 = clamp(_7705, vec3(0.0), _7738);\n    vec3 _7747 = min(floor(_7739), max(_7697 - vec3(2.0), vec3(0.0)));\n    vec3 _7751 = _7739 - _7747;\n    vec3 _7762 = fa_world_pos + (((n * 0.800000011920928955078125) + (v * 0.20000000298023223876953125)) * (0.20000000298023223876953125 * _7694));\n    int _7767 = int(_7671.y + 0.5);\n    float _7772 = 0.3257350027561187744140625 * n.y;\n    float _7776 = 0.3257350027561187744140625 * n.z;\n    float _7780 = 0.3257350027561187744140625 * n.x;\n    float _7787 = (0.2731371223926544189453125 * n.x) * n.y;\n    float _7794 = (0.2731371223926544189453125 * n.y) * n.z;\n    float _7803 = 0.078847892582416534423828125 * (((3.0 * n.z) * n.z) - 1.0);\n    float _7810 = (0.2731371223926544189453125 * n.x) * n.z;\n    float _7823 = 0.13656856119632720947265625 * ((n.x * n.x) - (n.y * n.y));\n    vec3 acc = vec3(0.0);\n    float wsum = 0.0;\n    int _7830 = 8 + int(_7676.w);\n    float _7857;\n    float _7870;\n    float _7884;\n    for (int k = 0; k < _7830; k++)\n    {\n        float _7843 = float(k & 1);\n        float _7847 = float((k >> 1) & 1);\n        float _7851 = float((k >> 2) & 1);\n        if (_7843 > 0.5)\n        {\n            _7857 = _7751.x;\n        }\n        else\n        {\n            _7857 = 1.0 - _7751.x;\n        }\n        if (_7847 > 0.5)\n        {\n            _7870 = _7751.y;\n        }\n        else\n        {\n            _7870 = 1.0 - _7751.y;\n        }\n        if (_7851 > 0.5)\n        {\n            _7884 = _7751.z;\n        }\n        else\n        {\n            _7884 = 1.0 - _7751.z;\n        }\n        float _7894 = (_7857 * _7870) * _7884;\n        if (!(_7894 > 0.0))\n        {\n            continue;\n        }\n        vec3 _7907 = min(_7747 + vec3(_7843, _7847, _7851), _7738);\n        int _7927 = int(((_7671.x + _7907.x) + (_7666.x * (_7907.y + (_7666.y * _7907.z)))) + 0.5);\n        vec2 _7942 = vec2(float(_7927 % _7767) * 10.0, 1024.0 + (float(_7927 / _7767) * 11.0));\n        vec2 param_4 = _7942 + vec2(9.5, 10.5);\n        vec4 _7950 = fa_gi_fetch(param_4);\n        bool _7953 = _7950.y < 0.5;\n        bool _7962;\n        if (!_7953)\n        {\n            _7962 = _7950.x > _7676.y;\n        }\n        else\n        {\n            _7962 = _7953;\n        }\n        if (_7962)\n        {\n            continue;\n        }\n        vec3 _7974 = _7762 - (_7701 + (_7907 * _7694));\n        float _7977 = length(_7974);\n        vec3 _7983 = _7974 / vec3(max(_7977, 9.9999997473787516355514526367188e-05));\n        float _7993 = max(9.9999997473787516355514526367188e-05, (dot(-_7983, n) + 1.0) * 0.5);\n        float w = _7894 * (_7993 * _7993);\n        vec3 param_5 = _7983;\n        vec2 param_6 = (_7942 + vec2(1.0)) + (((fa_oct_encode(param_5) * 0.5) + vec2(0.5)) * 8.0);\n        vec4 _8012 = fa_gi_fetch(param_6);\n        float _8019 = _7977 / max(_7671.z, 9.9999997473787516355514526367188e-05);\n        float _8022 = _8012.x;\n        if (_8019 > _8022)\n        {\n            float _8035 = max(_8012.y - (_8022 * _8022), 0.0);\n            float _8040 = _8019 - _8022;\n            float _8049 = _8035 / max(_8035 + (_8040 * _8040), 9.9999999600419720025001879548654e-13);\n            w *= ((_8049 * _8049) * _8049);\n        }\n        if (!(w > 0.0))\n        {\n            continue;\n        }\n        vec2 param_7 = _7942 + vec2(0.5, 10.5);\n        vec2 param_8 = _7942 + vec2(1.5, 10.5);\n        vec2 param_9 = _7942 + vec2(2.5, 10.5);\n        vec2 param_10 = _7942 + vec2(3.5, 10.5);\n        vec2 param_11 = _7942 + vec2(4.5, 10.5);\n        vec2 param_12 = _7942 + vec2(5.5, 10.5);\n        vec2 param_13 = _7942 + vec2(6.5, 10.5);\n        vec2 param_14 = _7942 + vec2(7.5, 10.5);\n        vec2 param_15 = _7942 + vec2(8.5, 10.5);\n        acc += ((((((((((fa_gi_fetch(param_7).xyz * 0.2820948064327239990234375) + (fa_gi_fetch(param_8).xyz * _7772)) + (fa_gi_fetch(param_9).xyz * _7776)) + (fa_gi_fetch(param_10).xyz * _7780)) + (fa_gi_fetch(param_11).xyz * _7787)) + (fa_gi_fetch(param_12).xyz * _7794)) + (fa_gi_fetch(param_13).xyz * _7803)) + (fa_gi_fetch(param_14).xyz * _7810)) + (fa_gi_fetch(param_15).xyz * _7823)) * w);\n        wsum += w;\n    }\n    if (!(wsum > 9.9999997473787516355514526367188e-06))\n    {\n        return vec3(0.0);\n    }\n    cover = smoothstep(0.0, 1.0, clamp(_7723 * 2.0, 0.0, 1.0)) * smoothstep(0.0, 0.0199999995529651641845703125, wsum);\n    float _8173;\n    if (fa_mesh_fs_params[52].z > 0.5)\n    {\n        _8173 = _7676.x;\n    }\n    else\n    {\n        _8173 = 1.0;\n    }\n    return max(acc / vec3(wsum), vec3(0.0)) * (_7671.w * _8173);\n}\n\nvec3 fa_gi_light(vec3 n, inout float left)\n{\n    left = 1.0;\n    vec3 acc = vec3(0.0);\n    vec3 _8197 = normalize(fa_mesh_fs_params[0].xyz - fa_world_pos);\n    int _8202 = int(fa_mesh_fs_params[52].x + 0.5);\n    int _8207 = int(fa_mesh_fs_params[52].y + 0.5);\n    float param_3;\n    for (int k = 0; (k < _8207) && (k < 8); k++)\n    {\n        int param = _8202 + (4 * k);\n        vec3 param_1 = n;\n        vec3 param_2 = _8197;\n        vec3 _8232 = fa_gi_grid(param, param_1, param_2, param_3);\n        float _8237 = param_3 * left;\n        acc += (_8232 * _8237);\n        left -= _8237;\n        if (left < 0.001000000047497451305389404296875)\n        {\n            left = 0.0;\n            break;\n        }\n    }\n    return acc;\n}\n\nvec3 fa_realtime_or_ambient(vec3 n)\n{\n    vec3 gi = vec3(0.0);\n    float left = 1.0;\n    if (fa_mesh_fs_params[52].y > 0.5)\n    {\n        vec3 param = n;\n        float param_1;\n        vec3 _8266 = fa_gi_light(param, param_1);\n        left = param_1;\n        gi = _8266;\n    }\n    if (left <= 0.0)\n    {\n        return gi;\n    }\n    vec3 param_2 = n;\n    return gi + (fa_ambient_light(param_2) * left);\n}\n\nvec3 fa_indirect_diffuse(vec3 n)\n{\n    if (fa_lm.z > 0.5)\n    {\n        return textureLod(fa_lightmap_fa_env_smp, fa_lm.xy, 0.0).xyz;\n    }\n    if (fa_mesh_fs_params[32].w > 0.0)\n    {\n        vec3 c[9];\n        for (int k = 0; k < 9; k++)\n        {\n            c[k] = fa_mesh_fs_params[k * 1 + 32].xyz;\n        }\n        vec3 param = n;\n        vec3 param_1[9] = c;\n        vec3 param_2 = n;\n        return mix(fa_ambient_light(param), fa_sh_eval(param_1, param_2), vec3(clamp(fa_mesh_fs_params[32].w, 0.0, 1.0)));\n    }\n    vec3 param_3 = n;\n    return fa_realtime_or_ambient(param_3);\n}\n\nint fa_cluster_index(int slot, int n)\n{\n    int param = (int(fa_mesh_fs_params[19].x) + int(fa_mesh_fs_params[19].w)) + ((slot + n) >> 2);\n    vec4 t = fa_light_texel(param);\n    return int(t[(slot + n) & 3]);\n}\n\nint fa_cl_light(int n)\n{\n    if (n < fa_cl_ndir)\n    {\n        return n;\n    }\n    int param = fa_cl_slot;\n    int param_1 = n - fa_cl_ndir;\n    return fa_cluster_index(param, param_1);\n}\n\nint fa_light_base(int li)\n{\n    return li * ((fa_mesh_fs_params[1].w > 4.5) ? 8 : 4);\n}\n\nbool fa_light_baked(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 3;\n    return fa_light_texel(param_1).w > 0.5;\n}\n\nfloat fa_baked_keep(int li)\n{\n    float _6163;\n    if (fa_lm.z > 0.5)\n    {\n        _6163 = 0.0;\n    }\n    else\n    {\n        _6163 = 1.0 - clamp(fa_mesh_fs_params[32].w, 0.0, 1.0);\n    }\n    bool _6174 = _6163 < 1.0;\n    bool _6180;\n    if (_6174)\n    {\n        int param = li;\n        _6180 = fa_light_baked(param);\n    }\n    else\n    {\n        _6180 = _6174;\n    }\n    return _6180 ? _6163 : 1.0;\n}\n\nfloat fa_light_type(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 1;\n    return fa_light_texel(param_1).w;\n}\n\nvec4 fa_atlas_fetch(vec2 texel)\n{\n    return textureLod(fa_light_atlas_fa_env_smp, texel / vec2(textureSize(fa_light_atlas_fa_env_smp, 0)), 0.0);\n}\n\nvec3 fa_cookie_sample(vec2 tile_origin, vec2 uv)\n{\n    vec2 param = (tile_origin + vec2(1.0)) + (clamp(uv, vec2(0.0), vec2(1.0)) * 254.0);\n    return fa_atlas_fetch(param).xyz;\n}\n\nvec3 fa_area_point(vec3 c, vec3 axis, vec3 ru, vec3 uu, float hx, float hy, float shape, vec3 p, vec3 r)\n{\n    bool _877 = dot(r, r) > 0.5;\n    if (shape > 1.5)\n    {\n        vec3 _890 = (c - (ru * hx)) - p;\n        vec3 _896 = ru * (2.0 * hx);\n        float _902 = max(dot(_896, _896), 9.9999999392252902907785028219223e-09);\n        float _906 = dot(_890, _896);\n        float t = clamp((-_906) / _902, 0.0, 1.0);\n        if (_877)\n        {\n            float _921 = dot(r, _896);\n            float _927 = _902 - (_921 * _921);\n            if (abs(_927) > (9.9999997473787516355514526367188e-06 * _902))\n            {\n                t = clamp(((dot(r, _890) * _921) - _906) / _927, 0.0, 1.0);\n            }\n        }\n        return (p + _890) + (_896 * t);\n    }\n    vec3 q = p;\n    float _959 = dot(r, axis);\n    bool _967;\n    if (_877)\n    {\n        _967 = abs(_959) > 9.9999997473787516355514526367188e-05;\n    }\n    else\n    {\n        _967 = _877;\n    }\n    if (_967)\n    {\n        float _977 = dot(c - p, axis) / _959;\n        if (_977 > 0.0)\n        {\n            q = p + (r * _977);\n        }\n    }\n    vec3 _990 = q - c;\n    vec2 xy = vec2(dot(_990, ru), dot(_990, uu));\n    if (shape > 0.5)\n    {\n        float _1005 = length(xy);\n        if (_1005 > hx)\n        {\n            xy *= (hx / _1005);\n        }\n    }\n    else\n    {\n        xy = clamp(xy, vec2(-hx, -hy), vec2(hx, hy));\n    }\n    return (c + (ru * xy.x)) + (uu * xy.y);\n}\n\nint fa_cube_face(vec3 d)\n{\n    vec3 _644 = abs(d);\n    float _646 = _644.x;\n    float _648 = _644.y;\n    bool _649 = _646 >= _648;\n    bool _657;\n    if (_649)\n    {\n        _657 = _646 >= _644.z;\n    }\n    else\n    {\n        _657 = _649;\n    }\n    int _658;\n    if (_657)\n    {\n        _658 = (d.x > 0.0) ? 0 : 1;\n    }\n    else\n    {\n        int _672;\n        if (_648 >= _644.z)\n        {\n            _672 = (d.y > 0.0) ? 2 : 3;\n        }\n        else\n        {\n            _672 = (d.z > 0.0) ? 4 : 5;\n        }\n        _658 = _672;\n    }\n    return _658;\n}\n\nvoid fa_cube_face_basis(int f, out vec3 fwd, out vec3 up)\n{\n    if (f == 0)\n    {\n        fwd = vec3(1.0, 0.0, 0.0);\n        up = vec3(0.0, 1.0, 0.0);\n    }\n    else\n    {\n        if (f == 1)\n        {\n            fwd = vec3(-1.0, 0.0, 0.0);\n            up = vec3(0.0, 1.0, 0.0);\n        }\n        else\n        {\n            if (f == 2)\n            {\n                fwd = vec3(0.0, 1.0, 0.0);\n                up = vec3(0.0, 0.0, 1.0);\n            }\n            else\n            {\n                if (f == 3)\n                {\n                    fwd = vec3(0.0, -1.0, 0.0);\n                    up = vec3(0.0, 0.0, -1.0);\n                }\n                else\n                {\n                    if (f == 4)\n                    {\n                        fwd = vec3(0.0, 0.0, 1.0);\n                        up = vec3(0.0, 1.0, 0.0);\n                    }\n                    else\n                    {\n                        fwd = vec3(0.0, 0.0, -1.0);\n                        up = vec3(0.0, 1.0, 0.0);\n                    }\n                }\n            }\n        }\n    }\n}\n\nfloat fa_ies_sample(vec2 tile_origin, vec3 d, vec3 axis, vec3 right, vec3 up)\n{\n    float _797 = dot(d, right);\n    float _801 = dot(d, up);\n    float _812;\n    if (((_797 * _797) + (_801 * _801)) > 1.0000000133514319600180897396058e-10)\n    {\n        _812 = atan(_801, _797) * 0.15915493667125701904296875;\n    }\n    else\n    {\n        _812 = 0.0;\n    }\n    vec2 param = tile_origin + vec2(1.0 + ((_812 - floor(_812)) * 64.0), 1.0 + (acos(clamp(dot(d, axis), -1.0, 1.0)) * 10.18591594696044921875));\n    return fa_atlas_fetch(param).x;\n}\n\nLightSample fa_light_sample_n(int li, vec3 world_pos, vec3 n)\n{\n    int param = li;\n    int _1043 = fa_light_base(param);\n    bool _1047 = fa_mesh_fs_params[1].w > 4.5;\n    int param_1 = _1043;\n    vec4 _1051 = fa_light_texel(param_1);\n    int param_2 = _1043 + 1;\n    vec4 _1056 = fa_light_texel(param_2);\n    float _1059 = _1056.w;\n    float atten = 1.0;\n    float dist = 0.0;\n    fa_light_tint = vec3(1.0);\n    bool _1071 = _1047 && (_1059 > 2.5);\n    fa_light_is_area = _1071;\n    bool _1073 = _1059 < 0.5;\n    vec3 l;\n    if (_1073)\n    {\n        l = normalize(_1051.xyz);\n        if (_1047)\n        {\n            int param_3 = _1043 + 6;\n            vec4 _1087 = fa_light_texel(param_3);\n            if (_1087.z > 0.5)\n            {\n                int param_4 = _1043 + 4;\n                vec4 _1097 = fa_light_texel(param_4);\n                int param_5 = _1043 + 5;\n                vec4 _1102 = fa_light_texel(param_5);\n                vec2 param_6 = _1087.xy;\n                vec2 param_7 = fract(vec2(dot(world_pos, _1097.xyz) * _1097.w, (-dot(world_pos, _1102.xyz)) * _1102.w) + vec2(0.5));\n                fa_light_tint = fa_cookie_sample(param_6, param_7);\n            }\n        }\n    }\n    else\n    {\n        vec3 _1132 = _1051.xyz;\n        vec3 _1134 = _1132 - world_pos;\n        vec3 to_light = _1134;\n        float _1137 = length(_1134);\n        float reach = _1137;\n        bool front = true;\n        if (_1071)\n        {\n            int param_8 = _1043 + 7;\n            reach = max(_1137 - fa_light_texel(param_8).w, 0.0);\n            int param_9 = _1043 + 4;\n            vec4 _1161 = fa_light_texel(param_9);\n            int param_10 = _1043 + 5;\n            vec4 _1166 = fa_light_texel(param_10);\n            int param_11 = _1043 + 6;\n            vec4 _1171 = fa_light_texel(param_11);\n            float _1172 = _1171.w;\n            int param_12 = _1043 + 2;\n            vec3 _1179 = normalize(fa_light_texel(param_12).xyz);\n            bool _1181 = _1172 > 1.5;\n            bool _1189;\n            if (!_1181)\n            {\n                _1189 = dot(_1179, to_light) < 0.0;\n            }\n            else\n            {\n                _1189 = _1181;\n            }\n            front = _1189;\n            vec3 r = vec3(0.0);\n            vec3 _1198 = fa_mesh_fs_params[0].xyz - world_pos;\n            bool _1202 = dot(n, n) > 0.5;\n            bool _1210;\n            if (_1202)\n            {\n                _1210 = dot(_1198, _1198) > 9.9999999600419720025001879548654e-13;\n            }\n            else\n            {\n                _1210 = _1202;\n            }\n            if (_1210)\n            {\n                r = reflect(-normalize(_1198), normalize(n));\n            }\n            vec3 param_13 = _1132;\n            vec3 param_14 = _1179;\n            vec3 param_15 = _1161.xyz;\n            vec3 param_16 = _1166.xyz;\n            float param_17 = _1161.w;\n            float param_18 = _1166.w;\n            float param_19 = _1172;\n            vec3 param_20 = world_pos;\n            vec3 param_21 = r;\n            to_light = fa_area_point(param_13, param_14, param_15, param_16, param_17, param_18, param_19, param_20, param_21) - world_pos;\n        }\n        float _1246 = length(to_light);\n        dist = _1246;\n        l = to_light / vec3(max(_1246, 9.9999997473787516355514526367188e-05));\n        float _1260 = reach / max(_1051.w, 0.001000000047497451305389404296875);\n        float _1266 = clamp(1.0 - (_1260 * _1260), 0.0, 1.0);\n        float _1268;\n        if (front)\n        {\n            _1268 = _1266 * _1266;\n        }\n        else\n        {\n            _1268 = 0.0;\n        }\n        atten = _1268;\n        bool _1279 = _1059 < 2.5;\n        if ((_1059 > 1.5) && _1279)\n        {\n            int param_22 = _1043 + 2;\n            vec4 _1287 = fa_light_texel(param_22);\n            float _1297 = _1287.w;\n            int param_23 = _1043 + 3;\n            vec4 _1302 = fa_light_texel(param_23);\n            float _1303 = _1302.x;\n            float cos_inner = _1303;\n            if (_1303 > 1.5)\n            {\n                cos_inner = mix(_1297, 1.0, 0.25);\n            }\n            atten *= smoothstep(_1297, cos_inner, dot(-l, normalize(_1287.xyz)));\n        }\n        if (_1047 && (_1059 < 1.5))\n        {\n            int param_24 = _1043 + 6;\n            vec4 _1327 = fa_light_texel(param_24);\n            if (_1327.z > 0.5)\n            {\n                vec3 _1335 = -to_light;\n                int param_25 = _1043 + 4;\n                int param_26 = _1043 + 5;\n                vec3 _1349 = fa_light_texel(param_25).xyz;\n                vec3 _1353 = fa_light_texel(param_26).xyz;\n                vec3 _1362 = vec3(dot(_1335, _1349), dot(_1335, _1353), dot(_1335, cross(_1349, _1353)));\n                vec3 param_27 = _1362;\n                int _1366 = fa_cube_face(param_27);\n                int param_28 = _1366;\n                vec3 param_29;\n                vec3 param_30;\n                fa_cube_face_basis(param_28, param_29, param_30);\n                vec2 _1393 = vec2(dot(_1362, cross(param_29, param_30)), dot(_1362, param_30)) / vec2(max(dot(_1362, param_29), 9.9999997473787516355514526367188e-05));\n                int _1397 = _1366 / 3;\n                vec2 param_31 = _1327.xy + (vec2(float(_1366 - (_1397 * 3)), float(_1397)) * 256.0);\n                vec2 param_32 = vec2(0.5 + (0.5 * _1393.x), 0.5 - (0.5 * _1393.y));\n                fa_light_tint = fa_cookie_sample(param_31, param_32);\n            }\n            int param_33 = _1043 + 7;\n            vec4 _1427 = fa_light_texel(param_33);\n            if (_1427.z > 0.5)\n            {\n                int param_34 = _1043 + 2;\n                int param_35 = _1043 + 4;\n                int param_36 = _1043 + 5;\n                vec2 param_37 = _1427.xy;\n                vec3 param_38 = -l;\n                vec3 param_39 = normalize(fa_light_texel(param_34).xyz);\n                vec3 param_40 = fa_light_texel(param_35).xyz;\n                vec3 param_41 = fa_light_texel(param_36).xyz;\n                atten *= fa_ies_sample(param_37, param_38, param_39, param_40, param_41);\n            }\n        }\n        else\n        {\n            if (_1047 && _1279)\n            {\n                int param_42 = _1043 + 6;\n                vec4 _1474 = fa_light_texel(param_42);\n                int param_43 = _1043 + 7;\n                vec4 _1479 = fa_light_texel(param_43);\n                bool _1482 = _1474.z > 0.5;\n                bool _1489;\n                if (!_1482)\n                {\n                    _1489 = _1479.z > 0.5;\n                }\n                else\n                {\n                    _1489 = _1482;\n                }\n                if (_1489)\n                {\n                    int param_44 = _1043 + 2;\n                    vec4 _1496 = fa_light_texel(param_44);\n                    vec3 _1500 = normalize(_1496.xyz);\n                    int param_45 = _1043 + 4;\n                    vec4 _1505 = fa_light_texel(param_45);\n                    int param_46 = _1043 + 5;\n                    vec4 _1510 = fa_light_texel(param_46);\n                    if (_1482)\n                    {\n                        vec3 _1518 = -to_light;\n                        float _1525 = _1496.w;\n                        float _1541 = 0.5 / max(dot(_1518, _1500) * (sqrt(max(1.0 - (_1525 * _1525), 0.0)) / max(_1525, 0.001000000047497451305389404296875)), 9.9999997473787516355514526367188e-05);\n                        vec2 param_47 = _1474.xy;\n                        vec2 param_48 = vec2(0.5 + (dot(_1518, _1505.xyz) * _1541), 0.5 - (dot(_1518, _1510.xyz) * _1541));\n                        fa_light_tint = fa_cookie_sample(param_47, param_48);\n                    }\n                    if (_1479.z > 0.5)\n                    {\n                        vec2 param_49 = _1479.xy;\n                        vec3 param_50 = -l;\n                        vec3 param_51 = _1500;\n                        vec3 param_52 = _1505.xyz;\n                        vec3 param_53 = _1510.xyz;\n                        atten *= fa_ies_sample(param_49, param_50, param_51, param_52, param_53);\n                    }\n                }\n            }\n        }\n    }\n    vec3 _9360 = _1056.xyz * atten;\n    if (_1047)\n    {\n        _9360 *= fa_light_tint;\n    }\n    int _1610;\n    if (_1073)\n    {\n        _1610 = 0;\n    }\n    else\n    {\n        _1610 = ((_1059 > 1.5) && (_1059 < 2.5)) ? 2 : 1;\n    }\n    return LightSample(l, _9360, atten, 1.0, dist, _1610);\n}\n\nfloat fa_shadow_split_at(int i)\n{\n    float _2336;\n    if (i == 0)\n    {\n        _2336 = fa_shadows[24].x;\n    }\n    else\n    {\n        float _2352;\n        if (i == 1)\n        {\n            _2352 = fa_shadows[24].y;\n        }\n        else\n        {\n            float _2360;\n            if (i == 2)\n            {\n                _2360 = fa_shadows[24].z;\n            }\n            else\n            {\n                _2360 = fa_shadows[24].w;\n            }\n            _2352 = _2360;\n        }\n        _2336 = _2352;\n    }\n    return _2336;\n}\n\nfloat fa_shadow_depth(inout vec2 uv, vec4 rect)\n{\n    uv = clamp(uv, rect.xy, rect.zw);\n    return textureLod(fa_shadow_tex_fa_shadow_smp, uv, 0.0).x;\n}\n\nfloat fa_shadow_fetch(vec2 uv, vec4 rect, vec3 conv)\n{\n    vec2 param = uv;\n    vec4 param_1 = rect;\n    float _2393 = fa_shadow_depth(param, param_1);\n    float _2397;\n    if (conv.x < 0.5)\n    {\n        _2397 = _2393;\n    }\n    else\n    {\n        _2397 = (conv.y * conv.z) / (conv.z - (_2393 * (conv.z - conv.y)));\n    }\n    return _2397;\n}\n\nfloat fa_shadow_noise()\n{\n    return fract(52.98291778564453125 * fract(dot(gl_FragCoord.xy, vec2(0.067110560834407806396484375, 0.005837149918079376220703125))));\n}\n\nvec2 fa_shadow_vogel_turn(vec2 d)\n{\n    return vec2((d.x * (-0.737368881702423095703125)) - (d.y * 0.675490319728851318359375), (d.y * (-0.737368881702423095703125)) + (d.x * 0.675490319728851318359375));\n}\n\nfloat fa_shadow_filter(vec2 uv, vec4 rect, float zr, float texel_m, float unit, float reach, float plane, vec3 conv, int mode, float k)\n{\n    if (mode == 1)\n    {\n        vec2 param = uv;\n        vec4 param_1 = rect;\n        vec3 param_2 = conv;\n        return float(zr <= fa_shadow_fetch(param, param_1, param_2));\n    }\n    float _2443 = fa_shadow_noise() * 6.283185482025146484375;\n    vec2 _2449 = vec2(cos(_2443), sin(_2443));\n    vec2 dir = _2449;\n    float radius = 1.5;\n    if (mode == 2)\n    {\n        float _2458;\n        if (k < 0.0)\n        {\n            _2458 = (-k) / max(zr, 0.100000001490116119384765625);\n        }\n        else\n        {\n            _2458 = k;\n        }\n        float _2477 = clamp((_2458 * reach) / texel_m, 3.0, 12.0);\n        float sum = 0.0;\n        float cnt = 0.0;\n        for (int i = 0; i < 16; i++)\n        {\n            float _2496 = sqrt((float(i) + 0.5) * 0.0625) * _2477;\n            vec2 param_3 = uv + (dir * (fa_shadows[26].zw * _2496));\n            vec4 param_4 = rect;\n            vec3 param_5 = conv;\n            float _2510 = fa_shadow_fetch(param_3, param_4, param_5);\n            if (_2510 < (zr - (_2496 * plane)))\n            {\n                sum += _2510;\n                cnt += 1.0;\n            }\n            vec2 param_6 = dir;\n            dir = fa_shadow_vogel_turn(param_6);\n        }\n        if (cnt < 0.5)\n        {\n            return 1.0;\n        }\n        float _2538 = sum / cnt;\n        float _2548;\n        if (k < 0.0)\n        {\n            _2548 = (-k) / max(_2538, 0.0500000007450580596923828125);\n        }\n        else\n        {\n            _2548 = k;\n        }\n        radius = clamp(((max(zr - _2538, 0.0) * unit) * _2548) / texel_m, 1.5, 16.0);\n        dir = _2449;\n    }\n    float lit = 0.0;\n    int _2574 = (mode == 2) ? 24 : 16;\n    for (int i_1 = 0; i_1 < _2574; i_1++)\n    {\n        float _2593 = sqrt((float(i_1) + 0.5) / float(_2574)) * radius;\n        vec2 param_7 = uv + (dir * (fa_shadows[26].zw * _2593));\n        vec4 param_8 = rect;\n        vec3 param_9 = conv;\n        lit += float((zr - (_2593 * plane)) <= fa_shadow_fetch(param_7, param_8, param_9));\n        vec2 param_10 = dir;\n        dir = fa_shadow_vogel_turn(param_10);\n    }\n    return lit / float(_2574);\n}\n\nfloat fa_shadow_cascade(int ci, vec3 world, vec3 n, vec3 l)\n{\n    float _2639 = max(fa_shadows[ci * 1 + 20].y, 0.001000000047497451305389404296875);\n    float _2644 = clamp(dot(n, l), 0.0, 1.0);\n    float _2650 = sqrt(1.0 - (_2644 * _2644));\n    float _2658 = min(_2650 / max(_2644, 0.20000000298023223876953125), 4.0);\n    float _2663;\n    if (fa_shadows[26].y > 0.0)\n    {\n        _2663 = fa_shadows[26].y;\n    }\n    else\n    {\n        _2663 = 1.5 * fa_shadows[ci * 1 + 20].x;\n    }\n    vec4 _2688 = mat4(fa_shadows[ci * 4 + 0], fa_shadows[ci * 4 + 1], fa_shadows[ci * 4 + 2], fa_shadows[ci * 4 + 3]) * vec4(world + (n * (_2663 * _2650)), 1.0);\n    float _2695 = _2688.x;\n    bool _2698 = _2695 < fa_shadows[ci * 1 + 16].x;\n    bool _2707;\n    if (!_2698)\n    {\n        _2707 = _2695 > fa_shadows[ci * 1 + 16].z;\n    }\n    else\n    {\n        _2707 = _2698;\n    }\n    bool _2716;\n    if (!_2707)\n    {\n        _2716 = _2688.y < fa_shadows[ci * 1 + 16].y;\n    }\n    else\n    {\n        _2716 = _2707;\n    }\n    bool _2725;\n    if (!_2716)\n    {\n        _2725 = _2688.y > fa_shadows[ci * 1 + 16].w;\n    }\n    else\n    {\n        _2725 = _2716;\n    }\n    bool _2732;\n    if (!_2725)\n    {\n        _2732 = _2688.z > 1.0;\n    }\n    else\n    {\n        _2732 = _2725;\n    }\n    if (_2732)\n    {\n        return -1.0;\n    }\n    float _2740;\n    if (fa_shadows[26].x > 0.0)\n    {\n        _2740 = fa_shadows[26].x;\n    }\n    else\n    {\n        _2740 = 1.5 * fa_shadows[ci * 1 + 20].x;\n    }\n    vec2 param = _2688.xy;\n    vec4 param_1 = fa_shadows[ci * 1 + 16];\n    float param_2 = _2688.z - ((_2740 * (1.0 + (0.5 * _2658))) / _2639);\n    float param_3 = fa_shadows[ci * 1 + 20].x;\n    float param_4 = _2639;\n    float param_5 = _2639 * 0.25;\n    float param_6 = ((fa_shadows[ci * 1 + 20].x * min(_2658, 3.0)) * 0.5) / _2639;\n    vec3 param_7 = vec3(0.0);\n    int param_8 = int(fa_shadows[25].z + 0.5);\n    float param_9 = fa_shadows[25].w;\n    return fa_shadow_filter(param, param_1, param_2, param_3, param_4, param_5, param_6, param_7, param_8, param_9);\n}\n\nfloat fa_shadow_sun(vec3 world, vec3 n, vec3 l)\n{\n    if (fa_mesh_fs_params[5].z < 0.5)\n    {\n        return 1.0;\n    }\n    int _3118 = int(fa_shadows[25].x + 0.5);\n    if (_3118 < 1)\n    {\n        return 1.0;\n    }\n    float _3133 = dot(world - fa_shadows[27].xyz, fa_shadows[28].xyz);\n    int param = _3118 - 1;\n    if (_3133 > fa_shadow_split_at(param))\n    {\n        return 1.0;\n    }\n    int ci = 0;\n    bool _3145 = _3118 > 1;\n    bool _3152;\n    if (_3145)\n    {\n        _3152 = _3133 > fa_shadows[24].x;\n    }\n    else\n    {\n        _3152 = _3145;\n    }\n    if (_3152)\n    {\n        ci = 1;\n    }\n    bool _3156 = _3118 > 2;\n    bool _3163;\n    if (_3156)\n    {\n        _3163 = _3133 > fa_shadows[24].y;\n    }\n    else\n    {\n        _3163 = _3156;\n    }\n    if (_3163)\n    {\n        ci = 2;\n    }\n    bool _3167 = _3118 > 3;\n    bool _3174;\n    if (_3167)\n    {\n        _3174 = _3133 > fa_shadows[24].z;\n    }\n    else\n    {\n        _3174 = _3167;\n    }\n    if (_3174)\n    {\n        ci = 3;\n    }\n    float s = -1.0;\n    float s2 = -1.0;\n    float t = 0.0;\n    int _3185 = min(_3118, 4);\n    float _3226;\n    for (int c = ci; c < _3185; c++)\n    {\n        int param_1 = c;\n        vec3 param_2 = world;\n        vec3 param_3 = n;\n        vec3 param_4 = l;\n        float _3205 = fa_shadow_cascade(param_1, param_2, param_3, param_4);\n        if (s >= 0.0)\n        {\n            s2 = _3205;\n            break;\n        }\n        if (_3205 < 0.0)\n        {\n            continue;\n        }\n        s = _3205;\n        ci = c;\n        if (fa_shadows[25].y > 0.0)\n        {\n            if (ci > 0)\n            {\n                int param_5 = ci - 1;\n                _3226 = fa_shadow_split_at(param_5);\n            }\n            else\n            {\n                _3226 = fa_shadows[28].w;\n            }\n            int param_6 = ci;\n            float _3245 = fa_shadows[25].y * max(fa_shadow_split_at(param_6) - _3226, 9.9999997473787516355514526367188e-05);\n            int param_7 = ci;\n            t = clamp((_3133 - (fa_shadow_split_at(param_7) - _3245)) / _3245, 0.0, 1.0);\n        }\n        if (t <= 0.0)\n        {\n            break;\n        }\n    }\n    if (s < 0.0)\n    {\n        return 1.0;\n    }\n    if (t > 0.0)\n    {\n        float _3277;\n        if ((ci + 1) < _3118)\n        {\n            _3277 = (s2 < 0.0) ? s : s2;\n        }\n        else\n        {\n            _3277 = 1.0;\n        }\n        s = mix(s, _3277, t);\n    }\n    return s;\n}\n\nfloat fa_shadow_factor(vec3 n, vec3 l)\n{\n    bool _3382 = fa_mesh_fs_params[25].y > 0.5;\n    bool _3388;\n    if (_3382)\n    {\n        _3388 = fa_mesh_fs_params[5].z > 0.5;\n    }\n    else\n    {\n        _3388 = _3382;\n    }\n    if (_3388)\n    {\n        float _3402 = dot(fa_mesh_fs_params[29].xyz, fa_world_pos) + fa_mesh_fs_params[29].w;\n        float _3405 = fwidth(_3402);\n        vec4 _3415 = vec4(fa_world_pos, 1.0);\n        float _3421 = dot(fa_mesh_fs_params[28], _3415);\n        if (_3421 > 9.9999997473787516355514526367188e-05)\n        {\n            vec2 _3440 = vec2(dot(fa_mesh_fs_params[26], _3415), dot(fa_mesh_fs_params[27], _3415)) / vec2(_3421);\n            float _3445 = (_3440.x * 0.5) + 0.5;\n            float _3449;\n            if (fa_mesh_fs_params[24].y > 0.5)\n            {\n                _3449 = (_3440.y * 0.5) + 0.5;\n            }\n            else\n            {\n                _3449 = 0.5 - (_3440.y * 0.5);\n            }\n            bool _3465 = _3445 >= 0.0;\n            bool _3471;\n            if (_3465)\n            {\n                _3471 = _3445 < 1.0;\n            }\n            else\n            {\n                _3471 = _3465;\n            }\n            bool _3477;\n            if (_3471)\n            {\n                _3477 = _3449 >= 0.0;\n            }\n            else\n            {\n                _3477 = _3471;\n            }\n            bool _3483;\n            if (_3477)\n            {\n                _3483 = _3449 < 1.0;\n            }\n            else\n            {\n                _3483 = _3477;\n            }\n            if (_3483)\n            {\n                vec4 _3509 = texelFetch(fa_screen_tex_fa_shadow_smp, clamp(ivec2(vec2(_3445, _3449) * fa_mesh_fs_params[24].zw), ivec2(0), ivec2(fa_mesh_fs_params[24].zw) - ivec2(1)), 0);\n                bool _3512 = _3509.w > 0.5;\n                bool _3528;\n                if (_3512)\n                {\n                    _3528 = abs(_3402 - _3509.x) <= (((0.00200000009499490261077880859375 * _3402) + 0.00999999977648258209228515625) + min(1.5 * _3405, 0.100000001490116119384765625 * _3402));\n                }\n                else\n                {\n                    _3528 = _3512;\n                }\n                if (_3528)\n                {\n                    float _3534;\n                    if (fa_mesh_fs_params[25].z > 0.5)\n                    {\n                        vec3 param = fa_world_pos;\n                        vec3 param_1 = n;\n                        vec3 param_2 = l;\n                        _3534 = min(_3509.y, fa_shadow_sun(param, param_1, param_2));\n                    }\n                    else\n                    {\n                        _3534 = _3509.y;\n                    }\n                    return _3534;\n                }\n            }\n        }\n    }\n    vec3 param_3 = fa_world_pos;\n    vec3 param_4 = n;\n    vec3 param_5 = l;\n    return fa_shadow_sun(param_3, param_4, param_5);\n}\n\nfloat fa_shadow_local(int li, vec3 lpos, vec3 world, vec3 n, vec3 l)\n{\n    bool _2798 = fa_mesh_fs_params[5].z < 0.5;\n    bool _2805;\n    if (!_2798)\n    {\n        _2805 = fa_shadows[29].x < 0.5;\n    }\n    else\n    {\n        _2805 = _2798;\n    }\n    if (_2805)\n    {\n        return 1.0;\n    }\n    int param = (int(fa_shadows[29].x + 0.5) - 1) + li;\n    vec4 _2818 = fa_light_texel(param);\n    float _2819 = _2818.x;\n    if (_2819 < 0.0)\n    {\n        return 1.0;\n    }\n    int _2828 = int(_2819 + 0.5);\n    int param_1 = _2828;\n    vec4 _2832 = fa_light_texel(param_1);\n    int param_2 = _2828 + 1;\n    vec4 _2837 = fa_light_texel(param_2);\n    float fade = 1.0;\n    float _2840 = _2832.y;\n    if (_2840 > 0.0)\n    {\n        float _2857 = 1.0 - smoothstep(0.75 * _2840, _2840, length(world - fa_shadows[27].xyz));\n        fade = _2857;\n        if (_2857 <= 0.0)\n        {\n            return 1.0;\n        }\n    }\n    int face = 0;\n    if (_2832.x > 1.5)\n    {\n        vec3 param_3 = world - lpos;\n        face = fa_cube_face(param_3);\n    }\n    int _2881 = (_2828 + 2) + (face * 6);\n    int param_4 = _2881;\n    int param_5 = _2881 + 1;\n    int param_6 = _2881 + 3;\n    vec4 _2895 = fa_light_texel(param_6);\n    int param_7 = _2881 + 4;\n    vec4 _2900 = fa_light_texel(param_7);\n    int param_8 = _2881 + 5;\n    vec4 _2905 = fa_light_texel(param_8);\n    float _2917 = _2905.x * max(dot(_2895, vec4(world, 1.0)), 0.001000000047497451305389404296875);\n    float _2922 = clamp(dot(n, l), 0.0, 1.0);\n    float _2945 = clamp(dot(n, _2895.xyz), -1.0, 1.0);\n    float _2964 = min(sqrt(1.0 - (_2945 * _2945)) / max(abs(dot(n, world - lpos)) / max(dot(_2895, vec4(world, 1.0)), 0.001000000047497451305389404296875), 0.20000000298023223876953125), 4.0);\n    float _2967 = _2837.y;\n    float _2969;\n    if (_2967 > 0.0)\n    {\n        _2969 = _2967;\n    }\n    else\n    {\n        _2969 = 1.5 * _2917;\n    }\n    vec4 _2989 = vec4(world + (n * (_2969 * sqrt(1.0 - (_2922 * _2922)))), 1.0);\n    float _2993 = dot(_2895, _2989);\n    float _2996 = _2905.y;\n    if (_2993 < _2996)\n    {\n        return 1.0;\n    }\n    vec2 _3011 = vec2(dot(fa_light_texel(param_4), _2989), dot(fa_light_texel(param_5), _2989)) / vec2(_2993);\n    float _3013 = _3011.x;\n    bool _3016 = _3013 < _2900.x;\n    bool _3025;\n    if (!_3016)\n    {\n        _3025 = _3013 > _2900.z;\n    }\n    else\n    {\n        _3025 = _3016;\n    }\n    bool _3034;\n    if (!_3025)\n    {\n        _3034 = _3011.y < _2900.y;\n    }\n    else\n    {\n        _3034 = _3025;\n    }\n    bool _3043;\n    if (!_3034)\n    {\n        _3043 = _3011.y > _2900.w;\n    }\n    else\n    {\n        _3043 = _3034;\n    }\n    if (_3043)\n    {\n        return 1.0;\n    }\n    float _3049 = _2837.x;\n    float _3051;\n    if (_3049 > 0.0)\n    {\n        _3051 = _3049;\n    }\n    else\n    {\n        _3051 = 1.5 * _2917;\n    }\n    vec2 param_9 = _3011;\n    vec4 param_10 = _2900;\n    float param_11 = _2993 - (_3051 * (1.0 + (0.5 * _2964)));\n    float param_12 = _2917;\n    float param_13 = 1.0;\n    float param_14 = _2905.z * 0.25;\n    float param_15 = (_2917 * min(_2964, 3.0)) * 0.5;\n    vec3 param_16 = vec3(1.0, _2996, _2905.z);\n    int param_17 = int(_2832.z + 0.5);\n    float param_18 = _2832.w;\n    return mix(1.0, fa_shadow_filter(param_9, param_10, param_11, param_12, param_13, param_14, param_15, param_16, param_17, param_18), fade);\n}\n\nfloat fa_contact_shadow(int li, vec3 world, vec3 gn, vec3 l, float dist)\n{\n    bool _5377 = fa_mesh_fs_params[24].x < 0.5;\n    bool _5384;\n    if (!_5377)\n    {\n        _5384 = fa_shadows[29].x < 0.5;\n    }\n    else\n    {\n        _5384 = _5377;\n    }\n    if (_5384)\n    {\n        return 1.0;\n    }\n    int param = (int(fa_shadows[29].x + 0.5) - 1) + li;\n    vec4 _5397 = fa_light_texel(param);\n    float _5398 = _5397.y;\n    float len = _5398;\n    if (_5398 <= 0.0)\n    {\n        return 1.0;\n    }\n    float _5410 = length(world - fa_mesh_fs_params[0].xyz);\n    float _5419 = 1.0 - smoothstep(0.5 * fa_mesh_fs_params[25].x, fa_mesh_fs_params[25].x, _5410);\n    if (_5419 <= 0.0)\n    {\n        return 1.0;\n    }\n    float _5425 = len;\n    float _5428 = min(_5425, 0.89999997615814208984375 * dist);\n    len = _5428;\n    float _5433 = 0.004999999888241291046142578125 + (0.0030000000260770320892333984375 * _5410);\n    float _5438 = _5433 + (0.5 * _5428);\n    vec3 _5444 = world + (gn * _5433);\n    float _5446 = fa_shadow_noise();\n    float occ = 0.0;\n    float _5507;\n    for (int k = 0; k < 12; k++)\n    {\n        float _5461 = (float(k) + _5446) * 0.083333335816860198974609375;\n        vec3 _5469 = _5444 + (l * (_5461 * len));\n        vec4 _5475 = vec4(_5469, 1.0);\n        float _5480 = dot(fa_mesh_fs_params[28], _5475);\n        if (_5480 < 9.9999997473787516355514526367188e-05)\n        {\n            break;\n        }\n        vec2 _5498 = vec2(dot(fa_mesh_fs_params[26], _5475), dot(fa_mesh_fs_params[27], _5475)) / vec2(_5480);\n        float _5502 = _5498.x * 0.5;\n        float _5503 = _5502 + 0.5;\n        if (fa_mesh_fs_params[24].y > 0.5)\n        {\n            _5507 = (_5498.y * 0.5) + 0.5;\n        }\n        else\n        {\n            _5507 = 0.5 - (_5498.y * 0.5);\n        }\n        bool _5523 = _5503 < 0.0;\n        bool _5530;\n        if (!_5523)\n        {\n            _5530 = _5503 >= 1.0;\n        }\n        else\n        {\n            _5530 = _5523;\n        }\n        bool _5537;\n        if (!_5530)\n        {\n            _5537 = _5507 < 0.0;\n        }\n        else\n        {\n            _5537 = _5530;\n        }\n        bool _5544;\n        if (!_5537)\n        {\n            _5544 = _5507 >= 1.0;\n        }\n        else\n        {\n            _5544 = _5537;\n        }\n        if (_5544)\n        {\n            break;\n        }\n        vec4 _5568 = texelFetch(fa_screen_tex_fa_shadow_smp, clamp(ivec2(vec2(_5503, _5507) * fa_mesh_fs_params[24].zw), ivec2(0), ivec2(fa_mesh_fs_params[24].zw) - ivec2(1)), 0);\n        if (_5568.w < 0.5)\n        {\n            continue;\n        }\n        float _5586 = (dot(fa_mesh_fs_params[29].xyz, _5469) + fa_mesh_fs_params[29].w) - _5568.x;\n        if ((_5586 > _5433) && (_5586 < _5438))\n        {\n            occ = max(occ, (1.0 - (_5461 * _5461)) * smoothstep(0.0, 0.0500000007450580596923828125, min(min(_5503, 0.5 - _5502), min(_5507, 1.0 - _5507))));\n        }\n    }\n    return 1.0 - (occ * _5419);\n}\n\nLightSample fa_light_shadowed(int li, vec3 world_pos, vec3 gn)\n{\n    int param = li;\n    float _6219 = fa_baked_keep(param);\n    if (_6219 <= 0.0)\n    {\n        int param_1 = li;\n        return LightSample(vec3(0.0, 1.0, 0.0), vec3(0.0), 0.0, 1.0, 0.0, int(fa_light_type(param_1) + 0.5));\n    }\n    int param_2 = li;\n    vec3 param_3 = world_pos;\n    vec3 param_4 = gn;\n    LightSample _6245 = fa_light_sample_n(param_2, param_3, param_4);\n    vec3 _9429 = _6245.color;\n    float _9430 = _6245.attenuation;\n    float _9431 = _6245.shadow;\n    bool _6248 = _6245.type == 0;\n    if (_6248 && (li == 0))\n    {\n        vec3 param_5 = gn;\n        vec3 param_6 = _6245.direction;\n        float _6259 = fa_shadow_factor(param_5, param_6);\n        _9431 = _6259;\n        _9429 *= _6259;\n    }\n    else\n    {\n        bool _6270 = _6245.type != 0;\n        bool _6276;\n        if (_6270)\n        {\n            _6276 = _9430 > 0.0;\n        }\n        else\n        {\n            _6276 = _6270;\n        }\n        if (_6276)\n        {\n            int param_7 = li;\n            int param_8 = fa_light_base(param_7);\n            int param_9 = li;\n            vec3 param_10 = fa_light_texel(param_8).xyz;\n            vec3 param_11 = world_pos;\n            vec3 param_12 = gn;\n            vec3 param_13 = _6245.direction;\n            float _6295 = fa_shadow_local(param_9, param_10, param_11, param_12, param_13);\n            _9431 = _6295;\n            _9429 *= _6295;\n        }\n    }\n    bool _6305 = fa_mesh_fs_params[24].x > 0.5;\n    bool _6311;\n    if (_6305)\n    {\n        _6311 = _9430 > 0.0;\n    }\n    else\n    {\n        _6311 = _6305;\n    }\n    if (_6311)\n    {\n        float _6318;\n        if (_6248)\n        {\n            _6318 = 1000000000.0;\n        }\n        else\n        {\n            _6318 = _6245._distance;\n        }\n        int param_14 = li;\n        vec3 param_15 = world_pos;\n        vec3 param_16 = gn;\n        vec3 param_17 = _6245.direction;\n        float param_18 = _6318;\n        float _6336 = fa_contact_shadow(param_14, param_15, param_16, param_17, param_18);\n        _9431 *= _6336;\n        _9429 *= _6336;\n    }\n    float _6349 = _9430;\n    float _6350 = _6349 * _6219;\n    _9430 = _6350;\n    vec3 _6354 = _9429;\n    vec3 _6355 = _6354 * _6219;\n    _9429 = _6355;\n    return LightSample(_6245.direction, _6355, _6350, _9431, _6245._distance, _6245.type);\n}\n\nvec3 fa_ltc_tangent(vec3 n, vec3 v)\n{\n    vec3 _6389 = v - (n * dot(v, n));\n    vec3 t = _6389;\n    float _6393 = dot(_6389, _6389);\n    float l2 = _6393;\n    if (_6393 < 1.0000000133514319600180897396058e-10)\n    {\n        vec3 _6403;\n        if (abs(n.z) < 0.999000012874603271484375)\n        {\n            _6403 = cross(n, vec3(0.0, 0.0, 1.0));\n        }\n        else\n        {\n            _6403 = cross(n, vec3(1.0, 0.0, 0.0));\n        }\n        t = _6403;\n        l2 = dot(_6403, _6403);\n    }\n    return t * inversesqrt(l2);\n}\n\nvec3 fa_ltc_local(vec3 t1, vec3 n, vec3 p)\n{\n    return vec3(dot(t1, p), dot(cross(n, t1), p), dot(n, p));\n}\n\nvec2 fa_ltc_uv(float roughness, float ndv)\n{\n    return ((vec2(clamp((roughness - 0.0500000007450580596923828125) * 1.0526316165924072265625, 0.0, 1.0), sqrt(clamp(1.0 - ndv, 0.0, 1.0))) * 63.0) + vec2(0.5)) * vec2(0.015625);\n}\n\nvec3 fa_oct_vertex(int j, vec3 pc, vec3 ex, vec3 ey)\n{\n    float _6790;\n    if ((j == 0) || (j == 7))\n    {\n        _6790 = 0.92387950420379638671875;\n    }\n    else\n    {\n        float _6800;\n        if ((j == 3) || (j == 4))\n        {\n            _6800 = -0.92387950420379638671875;\n        }\n        else\n        {\n            _6800 = ((j == 1) || (j == 6)) ? 0.3826834261417388916015625 : (-0.3826834261417388916015625);\n        }\n        _6790 = _6800;\n    }\n    float _6821;\n    if ((j == 1) || (j == 2))\n    {\n        _6821 = 0.92387950420379638671875;\n    }\n    else\n    {\n        float _6830;\n        if ((j == 5) || (j == 6))\n        {\n            _6830 = -0.92387950420379638671875;\n        }\n        else\n        {\n            _6830 = ((j == 0) || (j == 3)) ? 0.3826834261417388916015625 : (-0.3826834261417388916015625);\n        }\n        _6821 = _6830;\n    }\n    return (pc + (ex * _6790)) + (ey * _6821);\n}\n\nvec3 fa_ltc_edge_vector(vec3 a, vec3 b)\n{\n    float _6438 = dot(a, a);\n    float _6442 = dot(b, b);\n    if ((_6438 < 1.0000000195414813782625560981111e-24) || (_6442 < 1.0000000195414813782625560981111e-24))\n    {\n        return vec3(0.0);\n    }\n    vec3 _6456 = a * inversesqrt(_6438);\n    vec3 _6461 = b * inversesqrt(_6442);\n    float _6465 = dot(_6456, _6461);\n    float _6468 = abs(_6465);\n    float g = (((((((((((0.0416471660137176513671875 * _6468) - 0.1924748718738555908203125) * _6468) + 0.4179156124591827392578125) * _6468) - 0.616057217121124267578125) * _6468) + 0.777722418308258056640625) * _6468) - 0.999542415142059326171875) * _6468) + 1.570791721343994140625;\n    if (_6465 < 0.0)\n    {\n        g = (3.1415927410125732421875 * inversesqrt(max(1.0 - (_6465 * _6465), 1.0000000116860974230803549289703e-07))) - g;\n    }\n    return cross(_6456, _6461) * g;\n}\n\nvoid fa_ltc_clip_edge(vec3 a, vec3 b, inout vec3 sum, inout vec3 leave, inout vec3 enter, inout vec2 seen)\n{\n    bool _6525 = a.z > 0.0;\n    bool _6529 = b.z > 0.0;\n    if (_6525 && _6529)\n    {\n        vec3 param = a;\n        vec3 param_1 = b;\n        sum += fa_ltc_edge_vector(param, param_1);\n    }\n    else\n    {\n        if (_6525 != _6529)\n        {\n            vec3 _6564 = a + ((b - a) * (a.z / (a.z - b.z)));\n            _6564.z = 0.0;\n            if (_6525)\n            {\n                vec3 param_2 = a;\n                vec3 param_3 = _6564;\n                sum += fa_ltc_edge_vector(param_2, param_3);\n                leave = _6564;\n                seen.x = 1.0;\n            }\n            else\n            {\n                vec3 param_4 = _6564;\n                vec3 param_5 = b;\n                sum += fa_ltc_edge_vector(param_4, param_5);\n                enter = _6564;\n                seen.y = 1.0;\n            }\n        }\n    }\n}\n\nfloat fa_ltc_quad(vec4 abcd, vec3 p0, vec3 p1, vec3 p2, vec3 p3)\n{\n    vec3 _6613 = vec3((abcd.x * p0.x) + (abcd.y * p0.z), p0.y, (abcd.z * p0.x) + (abcd.w * p0.z));\n    vec3 _6639 = vec3((abcd.x * p1.x) + (abcd.y * p1.z), p1.y, (abcd.z * p1.x) + (abcd.w * p1.z));\n    vec3 _6665 = vec3((abcd.x * p2.x) + (abcd.y * p2.z), p2.y, (abcd.z * p2.x) + (abcd.w * p2.z));\n    vec3 _6691 = vec3((abcd.x * p3.x) + (abcd.y * p3.z), p3.y, (abcd.z * p3.x) + (abcd.w * p3.z));\n    vec3 sum = vec3(0.0);\n    vec3 leave = vec3(0.0);\n    vec3 enter = vec3(0.0);\n    vec3 param = _6613;\n    vec3 param_1 = _6639;\n    vec3 param_2 = vec3(0.0);\n    vec3 param_3 = vec3(0.0);\n    vec3 param_4 = vec3(0.0);\n    vec2 param_5 = vec2(0.0);\n    fa_ltc_clip_edge(param, param_1, param_2, param_3, param_4, param_5);\n    sum = param_2;\n    leave = param_3;\n    enter = param_4;\n    vec3 param_6 = _6639;\n    vec3 param_7 = _6665;\n    vec3 param_8 = param_2;\n    vec3 param_9 = param_3;\n    vec3 param_10 = param_4;\n    vec2 param_11 = param_5;\n    fa_ltc_clip_edge(param_6, param_7, param_8, param_9, param_10, param_11);\n    sum = param_8;\n    leave = param_9;\n    enter = param_10;\n    vec3 param_12 = _6665;\n    vec3 param_13 = _6691;\n    vec3 param_14 = param_8;\n    vec3 param_15 = param_9;\n    vec3 param_16 = param_10;\n    vec2 param_17 = param_11;\n    fa_ltc_clip_edge(param_12, param_13, param_14, param_15, param_16, param_17);\n    sum = param_14;\n    leave = param_15;\n    enter = param_16;\n    vec3 param_18 = _6691;\n    vec3 param_19 = _6613;\n    vec3 param_20 = param_14;\n    vec3 param_21 = param_15;\n    vec3 param_22 = param_16;\n    vec2 param_23 = param_17;\n    fa_ltc_clip_edge(param_18, param_19, param_20, param_21, param_22, param_23);\n    sum = param_20;\n    leave = param_21;\n    enter = param_22;\n    if ((param_23.x * param_23.y) > 0.5)\n    {\n        vec3 param_24 = leave;\n        vec3 param_25 = enter;\n        sum += fa_ltc_edge_vector(param_24, param_25);\n    }\n    return sum.z * 0.15915493667125701904296875;\n}\n\nvec2 fa_area_forms(vec4 m, float shape, vec3 pc, vec3 ex, vec3 ey)\n{\n    int _6859 = ((shape < 0.5) || (shape > 1.5)) ? 1 : 3;\n    vec2 sum = vec2(0.0);\n    int _6877;\n    for (int k = 0; k < (2 * _6859); k++)\n    {\n        bool _6874 = k >= _6859;\n        if (_6874)\n        {\n            _6877 = k - _6859;\n        }\n        else\n        {\n            _6877 = k;\n        }\n        vec3 p0 = (pc - ex) - ey;\n        vec3 p1 = (pc + ex) - ey;\n        vec3 p2 = (pc + ex) + ey;\n        vec3 p3 = (pc - ex) + ey;\n        if (_6859 == 3)\n        {\n            int param = 0;\n            vec3 param_1 = pc;\n            vec3 param_2 = ex;\n            vec3 param_3 = ey;\n            p0 = fa_oct_vertex(param, param_1, param_2, param_3);\n            int _6923 = 2 * _6877;\n            int param_4 = _6923 + 1;\n            vec3 param_5 = pc;\n            vec3 param_6 = ex;\n            vec3 param_7 = ey;\n            p1 = fa_oct_vertex(param_4, param_5, param_6, param_7);\n            int param_8 = _6923 + 2;\n            vec3 param_9 = pc;\n            vec3 param_10 = ex;\n            vec3 param_11 = ey;\n            p2 = fa_oct_vertex(param_8, param_9, param_10, param_11);\n            int param_12 = _6923 + 3;\n            vec3 param_13 = pc;\n            vec3 param_14 = ex;\n            vec3 param_15 = ey;\n            p3 = fa_oct_vertex(param_12, param_13, param_14, param_15);\n        }\n        bvec4 _6960 = bvec4(_6874);\n        vec4 param_16 = vec4(_6960.x ? m.x : vec4(1.0, 0.0, 0.0, 1.0).x, _6960.y ? m.y : vec4(1.0, 0.0, 0.0, 1.0).y, _6960.z ? m.z : vec4(1.0, 0.0, 0.0, 1.0).z, _6960.w ? m.w : vec4(1.0, 0.0, 0.0, 1.0).w);\n        vec3 param_17 = p0;\n        vec3 param_18 = p1;\n        vec3 param_19 = p2;\n        vec3 param_20 = p3;\n        float _6971 = fa_ltc_quad(param_16, param_17, param_18, param_19, param_20);\n        if (_6874)\n        {\n            vec2 _9672 = sum;\n            _9672.y = _9672.y + _6971;\n            sum = _9672;\n        }\n        else\n        {\n            vec2 _9675 = sum;\n            _9675.x = _9675.x + _6971;\n            sum = _9675;\n        }\n    }\n    return abs(sum);\n}\n\nvec3 fa_area_shade(int li, vec3 world_pos, vec3 n, vec3 v, vec3 diffuse_color, vec3 f0, float f90, float roughness, float ndv, float window)\n{\n    int param = li;\n    int _6995 = fa_light_base(param);\n    int param_1 = _6995;\n    int param_2 = _6995 + 1;\n    int param_3 = _6995 + 2;\n    int param_4 = _6995 + 4;\n    vec4 _7017 = fa_light_texel(param_4);\n    int param_5 = _6995 + 5;\n    vec4 _7022 = fa_light_texel(param_5);\n    int param_6 = _6995 + 6;\n    vec4 _7027 = fa_light_texel(param_6);\n    float _7028 = _7027.w;\n    vec3 _7033 = fa_light_texel(param_1).xyz - world_pos;\n    bool _7035 = _7028 < 1.5;\n    bool _7042;\n    if (_7035)\n    {\n        _7042 = dot(normalize(fa_light_texel(param_3).xyz), _7033) >= 0.0;\n    }\n    else\n    {\n        _7042 = _7035;\n    }\n    if (_7042)\n    {\n        return vec3(0.0);\n    }\n    bool _7051 = (_7028 > 0.5) && _7035;\n    float _7055 = _7051 ? 1.0539000034332275390625 : 1.0;\n    vec3 _7058 = _7017.xyz;\n    float _7060 = _7017.w;\n    vec3 _7066 = _7022.xyz;\n    float _7068 = _7022.w;\n    vec3 up = _7066 * (_7068 * _7055);\n    float _7074;\n    if (_7051)\n    {\n        _7074 = (3.1415927410125732421875 * _7060) * _7060;\n    }\n    else\n    {\n        _7074 = (4.0 * _7060) * _7068;\n    }\n    if (_7028 > 1.5)\n    {\n        vec3 _7100 = cross(_7058, -_7033);\n        vec3 perp = _7100;\n        float _7104 = dot(_7100, _7100);\n        vec3 _7107;\n        if (_7104 > 1.0000000133514319600180897396058e-10)\n        {\n            _7107 = perp * inversesqrt(_7104);\n        }\n        else\n        {\n            _7107 = _7066;\n        }\n        perp = _7107;\n        up = _7107 * _7068;\n    }\n    float _7128 = max(_7074, 9.9999999747524270787835121154785e-07);\n    vec3 param_7 = n;\n    vec3 param_8 = v;\n    vec3 _7138 = fa_ltc_tangent(param_7, param_8);\n    vec3 param_9 = _7138;\n    vec3 param_10 = n;\n    vec3 param_11 = _7033;\n    vec3 param_12 = _7138;\n    vec3 param_13 = n;\n    vec3 param_14 = _7058 * (_7060 * _7055);\n    vec3 param_15 = _7138;\n    vec3 param_16 = n;\n    vec3 param_17 = up;\n    float param_18 = roughness;\n    float param_19 = ndv;\n    vec2 _7169 = fa_ltc_uv(param_18, param_19) * 64.0;\n    vec2 param_20 = _7169;\n    vec2 param_21 = _7169 + vec2(64.0, 0.0);\n    vec4 _7179 = fa_atlas_fetch(param_21);\n    vec4 param_22 = fa_atlas_fetch(param_20);\n    float param_23 = _7028;\n    vec3 param_24 = fa_ltc_local(param_9, param_10, param_11);\n    vec3 param_25 = fa_ltc_local(param_12, param_13, param_14);\n    vec3 param_26 = fa_ltc_local(param_15, param_16, param_17);\n    vec2 _7191 = fa_area_forms(param_22, param_23, param_24, param_25, param_26);\n    return (((diffuse_color * _7191.x) + (((f0 * _7179.x) + ((vec3(f90) - f0) * _7179.y)) * _7191.y)) * fa_light_texel(param_2).xyz) * ((((3.1415927410125732421875 * dot(_7033, _7033)) + _7128) / _7128) * window);\n}\n\nvec3 fa_light_rgb(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 1;\n    return fa_light_texel(param_1).xyz;\n}\n\nfloat fa_d_charlie(float alpha, float ndh)\n{\n    float _5114 = 1.0 / alpha;\n    return ((2.0 + _5114) * pow(sqrt(max(1.0 - (ndh * ndh), 9.9999997473787516355514526367188e-05)), _5114)) * 0.15915493667125701904296875;\n}\n\nfloat fa_v_ashikhmin(float ndl, float ndv)\n{\n    return clamp(0.25 / max((ndl + ndv) - (ndl * ndv), 9.9999997473787516355514526367188e-05), 0.0, 1.0);\n}\n\nfloat fa_layers_coat(FaLayers L, vec3 l, vec3 h, float vdh)\n{\n    float _5149 = max(dot(L.nc, l), 0.0);\n    float _5155 = max(dot(L.nc, h), 0.0);\n    float _5164 = ((_5155 * _5155) * (L.coat_a2 - 1.0)) + 1.0;\n    return (((L.coat * (0.039999999105930328369140625 + (0.959999978542327880859375 * pow(clamp(1.0 - vdh, 0.0, 1.0), 5.0)))) * (((L.coat_a2 / ((3.1415927410125732421875 * _5164) * _5164)) * (0.5 / max(mix((2.0 * _5149) * L.coat_ndv, _5149 + L.coat_ndv, L.coat_alpha), 9.9999997473787516355514526367188e-05))) * 3.1415927410125732421875)) * step(9.9999997473787516355514526367188e-05, _5149)) * _5149;\n}\n\nvec3 fa_area_layers(FaLayers L, vec3 base, int li, vec3 n, vec3 v, vec3 l, float ndv, float window)\n{\n    float _7228;\n    if (L.sheen_on)\n    {\n        _7228 = L.sheen_scale;\n    }\n    else\n    {\n        _7228 = 1.0;\n    }\n    vec3 result = base * (L.keep * _7228);\n    vec3 _7241 = normalize(l + v);\n    int param = li;\n    vec3 _7252 = fa_light_rgb(param) * window;\n    if (L.sheen_on)\n    {\n        float _7261 = max(dot(n, l), 0.0);\n        float param_1 = L.sheen_alpha;\n        float param_2 = max(dot(n, _7241), 0.0);\n        float param_3 = _7261;\n        float param_4 = ndv;\n        result += ((L.sheen * _7252) * (((((fa_d_charlie(param_1, param_2) * fa_v_ashikhmin(param_3, param_4)) * 3.1415927410125732421875) * step(9.9999997473787516355514526367188e-05, _7261)) * _7261) * L.keep));\n    }\n    if (L.coat > 0.0)\n    {\n        FaLayers param_5 = L;\n        vec3 param_6 = l;\n        vec3 param_7 = _7241;\n        float param_8 = max(dot(v, _7241), 0.0);\n        result += (_7252 * fa_layers_coat(param_5, param_6, param_7, param_8));\n    }\n    return result;\n}\n\nfloat fa_d_ggx_aniso(float ndh, float tdh, float bdh, float at, float ab)\n{\n    float _5017 = tdh / at;\n    float _5021 = bdh / ab;\n    float _5033 = ((_5017 * _5017) + (_5021 * _5021)) + (ndh * ndh);\n    return 1.0 / ((((3.1415927410125732421875 * at) * ab) * _5033) * _5033);\n}\n\nfloat fa_lambda_ggx_aniso(float n, float t, float b, float at, float ab)\n{\n    return 0.5 * (sqrt(1.0 + (((((at * at) * t) * t) + (((ab * ab) * b) * b)) / max(n * n, 9.9999999392252902907785028219223e-09))) - 1.0);\n}\n\nfloat fa_v_ggx_aniso(float ndl, float ndv, float tdv, float bdv, float tdl, float bdl, float at, float ab)\n{\n    float param = ndv;\n    float param_1 = tdv;\n    float param_2 = bdv;\n    float param_3 = at;\n    float param_4 = ab;\n    float param_5 = ndl;\n    float param_6 = tdl;\n    float param_7 = bdl;\n    float param_8 = at;\n    float param_9 = ab;\n    return clamp(1.0 / ((4.0 * max(ndl * ndv, 9.9999997473787516355514526367188e-05)) * ((1.0 + fa_lambda_ggx_aniso(param, param_1, param_2, param_3, param_4)) + fa_lambda_ggx_aniso(param_5, param_6, param_7, param_8, param_9))), 0.0, 1.0);\n}\n\nvec3 fa_layers_light(FaLayers L, vec3 diffuse_color, vec3 f0, vec3 n, vec3 v, vec3 l, vec3 h, float ndl, float ndv, float ndh, float vdh, float alpha, float a2)\n{\n    float _5213 = step(9.9999997473787516355514526367188e-05, ndl);\n    float d_ggx;\n    float vis;\n    if (L.aniso != 0.0)\n    {\n        float param = ndh;\n        float param_1 = dot(L.t, h);\n        float param_2 = dot(L.b, h);\n        float param_3 = L.at;\n        float param_4 = L.ab;\n        d_ggx = fa_d_ggx_aniso(param, param_1, param_2, param_3, param_4);\n        float param_5 = ndl;\n        float param_6 = ndv;\n        float param_7 = dot(L.t, v);\n        float param_8 = dot(L.b, v);\n        float param_9 = dot(L.t, l);\n        float param_10 = dot(L.b, l);\n        float param_11 = L.at;\n        float param_12 = L.ab;\n        vis = fa_v_ggx_aniso(param_5, param_6, param_7, param_8, param_9, param_10, param_11, param_12);\n    }\n    else\n    {\n        float _5292 = ((ndh * ndh) * (a2 - 1.0)) + 1.0;\n        d_ggx = a2 / ((3.1415927410125732421875 * _5292) * _5292);\n        vis = 0.5 / max(mix((2.0 * ndl) * ndv, ndl + ndv, alpha), 9.9999997473787516355514526367188e-05);\n    }\n    vec3 base = diffuse_color + (((f0 + ((vec3(L.f90) - f0) * pow(clamp(1.0 - vdh, 0.0, 1.0), 5.0))) * ((d_ggx * vis) * 3.1415927410125732421875)) * _5213);\n    if (L.sheen_on)\n    {\n        float param_13 = L.sheen_alpha;\n        float param_14 = ndh;\n        float param_15 = ndl;\n        float param_16 = ndv;\n        base = (base * L.sheen_scale) + (L.sheen * (((fa_d_charlie(param_13, param_14) * fa_v_ashikhmin(param_15, param_16)) * 3.1415927410125732421875) * _5213));\n    }\n    vec3 result = base * (L.keep * ndl);\n    if (L.coat > 0.0)\n    {\n        FaLayers param_17 = L;\n        vec3 param_18 = l;\n        vec3 param_19 = h;\n        float param_20 = vdh;\n        result += vec3(fa_layers_coat(param_17, param_18, param_19, param_20));\n    }\n    return result;\n}\n\nvec2 fa_env_brdf(float rough, float ndv)\n{\n    vec4 _4416 = (vec4(-1.0, -0.0274999998509883880615234375, -0.572000026702880859375, 0.02199999988079071044921875) * rough) + vec4(1.0, 0.0425000004470348358154296875, 1.03999996185302734375, -0.039999999105930328369140625);\n    float _4419 = _4416.x;\n    return (vec2(-1.03999996185302734375, 1.03999996185302734375) * ((min(_4419 * _4419, exp2((-9.27999973297119140625) * ndv)) * _4419) + _4416.y)) + _4416.zw;\n}\n\nvec3 fa_probe_level(vec2 origin, float res, int lv, vec2 e)\n{\n    float _3725;\n    if (lv == 0)\n    {\n        _3725 = 0.0;\n    }\n    else\n    {\n        _3725 = res + 2.0;\n    }\n    float _3735;\n    if (lv == 0)\n    {\n        _3735 = 0.0;\n    }\n    else\n    {\n        _3735 = (res - (res / float(1 << max((lv - 1), 0)))) + (2.0 * float(lv - 1));\n    }\n    return textureLod(fa_probe_atlas_fa_env_smp, (((origin + vec2(_3725, _3735)) + vec2(1.0)) + (((e * 0.5) + vec2(0.5)) * (res / float(1 << lv)))) / fa_atlas_size(), 0.0).xyz;\n}\n\nvec3 fa_probe_radiance(vec2 origin, float res, vec3 d, float rough)\n{\n    float _3781;\n    if (res > 64.5)\n    {\n        _3781 = 5.0;\n    }\n    else\n    {\n        _3781 = (res > 32.5) ? 4.0 : 3.0;\n    }\n    float _3796 = clamp(rough, 0.0, 1.0) * (_3781 - 1.0);\n    int _3803 = int(min(floor(_3796), _3781 - 2.0));\n    float _3808 = _3796 - float(_3803);\n    vec3 param = d;\n    vec2 _3812 = fa_oct_encode(param);\n    vec2 param_1 = origin;\n    float param_2 = res;\n    int param_3 = _3803;\n    vec2 param_4 = _3812;\n    vec3 _3822 = fa_probe_level(param_1, param_2, param_3, param_4);\n    if (_3808 < 0.00200000009499490261077880859375)\n    {\n        return _3822;\n    }\n    vec2 param_5 = origin;\n    float param_6 = res;\n    int param_7 = _3803 + 1;\n    vec2 param_8 = _3812;\n    return mix(_3822, fa_probe_level(param_5, param_6, param_7, param_8), vec3(_3808));\n}\n\nvec3 fa_probe_box_dir(vec3 d, vec4 posw, vec4 bx, vec4 by, vec4 bz)\n{\n    if (posw.w < 0.5)\n    {\n        return d;\n    }\n    float _3894 = dot(bx.xyz, fa_world_pos) + bx.w;\n    float _3901 = dot(by.xyz, fa_world_pos) + by.w;\n    float _3908 = dot(bz.xyz, fa_world_pos) + bz.w;\n    float _3914 = dot(bx.xyz, d);\n    float _3918 = dot(by.xyz, d);\n    float _3922 = dot(bz.xyz, d);\n    float _3928;\n    if (_3914 > 9.9999999747524270787835121154785e-07)\n    {\n        _3928 = (1.0 - _3894) / _3914;\n    }\n    else\n    {\n        float _3942;\n        if (_3914 < (-9.9999999747524270787835121154785e-07))\n        {\n            _3942 = ((-1.0) - _3894) / _3914;\n        }\n        else\n        {\n            _3942 = 1000000015047466219876688855040.0;\n        }\n        _3928 = _3942;\n    }\n    float tx = _3928;\n    float _3959;\n    if (_3918 > 9.9999999747524270787835121154785e-07)\n    {\n        _3959 = (1.0 - _3901) / _3918;\n    }\n    else\n    {\n        float _3972;\n        if (_3918 < (-9.9999999747524270787835121154785e-07))\n        {\n            _3972 = ((-1.0) - _3901) / _3918;\n        }\n        else\n        {\n            _3972 = 1000000015047466219876688855040.0;\n        }\n        _3959 = _3972;\n    }\n    float ty = _3959;\n    float _3988;\n    if (_3922 > 9.9999999747524270787835121154785e-07)\n    {\n        _3988 = (1.0 - _3908) / _3922;\n    }\n    else\n    {\n        float _4001;\n        if (_3922 < (-9.9999999747524270787835121154785e-07))\n        {\n            _4001 = ((-1.0) - _3908) / _3922;\n        }\n        else\n        {\n            _4001 = 1000000015047466219876688855040.0;\n        }\n        _3988 = _4001;\n    }\n    float _4013 = tx;\n    float _4016 = (_4013 > 0.0) ? _4013 : 1000000015047466219876688855040.0;\n    tx = _4016;\n    float _4017 = ty;\n    float _4020 = (_4017 > 0.0) ? _4017 : 1000000015047466219876688855040.0;\n    ty = _4020;\n    float _4030 = min(_4016, min(_4020, (_3988 > 0.0) ? _3988 : 1000000015047466219876688855040.0));\n    if (_4030 > 100000001504746621987668885504.0)\n    {\n        return d;\n    }\n    vec3 _4046 = (fa_world_pos + (d * _4030)) - posw.xyz;\n    vec3 _4051;\n    if (dot(_4046, _4046) > 1.0000000133514319600180897396058e-10)\n    {\n        _4051 = normalize(_4046);\n    }\n    else\n    {\n        _4051 = d;\n    }\n    return _4051;\n}\n\nvec3 fa_probe_environment(vec4 tile, vec4 posw, vec4 bx, vec4 by, vec4 bz, inout vec3 d, float rough)\n{\n    vec3 param = d;\n    vec4 param_1 = posw;\n    vec4 param_2 = bx;\n    vec4 param_3 = by;\n    vec4 param_4 = bz;\n    d = fa_probe_box_dir(param, param_1, param_2, param_3, param_4);\n    vec2 param_5 = tile.xy;\n    float param_6 = tile.z;\n    vec3 param_7 = d;\n    float param_8 = rough;\n    return fa_probe_radiance(param_5, param_6, param_7, param_8);\n}\n\nvec3 fa_environment(vec3 d, float rough)\n{\n    float _4097 = (1.0 - fa_mesh_fs_params[42].w) - fa_mesh_fs_params[47].w;\n    vec3 outc = vec3(0.0);\n    if (_4097 > 0.0005000000237487256526947021484375)\n    {\n        vec3 base;\n        if (fa_mesh_fs_params[11].w > 0.5)\n        {\n            vec2 param = fa_mesh_fs_params[41].zw;\n            float param_1 = 128.0;\n            vec3 param_2 = d;\n            float param_3 = rough;\n            base = fa_probe_radiance(param, param_1, param_2, param_3);\n        }\n        else\n        {\n            float _4125 = rough * rough;\n            float _4156 = 0.60000002384185791015625 * _4125;\n            base = mix(mix(fa_mesh_fs_params[12].xyz * 0.550000011920928955078125, mix(fa_mesh_fs_params[12].xyz, fa_mesh_fs_params[11].xyz, vec3(pow(clamp(d.y * (1.0 - (0.699999988079071044921875 * _4125)), 0.0, 1.0), 0.550000011920928955078125))), vec3(smoothstep((-0.0500000007450580596923828125) - _4156, 0.0500000007450580596923828125 + _4156, d.y))), ((fa_mesh_fs_params[11].xyz + fa_mesh_fs_params[12].xyz) * 0.5) * 0.800000011920928955078125, vec3(_4125 * 0.60000002384185791015625));\n        }\n        outc = base * _4097;\n    }\n    if (fa_mesh_fs_params[42].w > 0.0)\n    {\n        vec4 param_4 = fa_mesh_fs_params[42];\n        vec4 param_5 = fa_mesh_fs_params[43];\n        vec4 param_6 = fa_mesh_fs_params[44];\n        vec4 param_7 = fa_mesh_fs_params[45];\n        vec4 param_8 = fa_mesh_fs_params[46];\n        vec3 param_9 = d;\n        float param_10 = rough;\n        vec3 _4215 = fa_probe_environment(param_4, param_5, param_6, param_7, param_8, param_9, param_10);\n        outc += (_4215 * fa_mesh_fs_params[42].w);\n    }\n    if (fa_mesh_fs_params[47].w > 0.0)\n    {\n        vec4 param_11 = fa_mesh_fs_params[47];\n        vec4 param_12 = fa_mesh_fs_params[48];\n        vec4 param_13 = fa_mesh_fs_params[49];\n        vec4 param_14 = fa_mesh_fs_params[50];\n        vec4 param_15 = fa_mesh_fs_params[51];\n        vec3 param_16 = d;\n        float param_17 = rough;\n        vec3 _4247 = fa_probe_environment(param_11, param_12, param_13, param_14, param_15, param_16, param_17);\n        outc += (_4247 * fa_mesh_fs_params[47].w);\n    }\n    return outc;\n}\n\nvec3 fa_layers_ibl(FaLayers L, vec3 n, vec3 v, vec3 f0, float roughness, float occlusion)\n{\n    vec3 rn = n;\n    if (L.aniso != 0.0)\n    {\n        vec3 _4894;\n        if (L.aniso >= 0.0)\n        {\n            _4894 = L.b;\n        }\n        else\n        {\n            _4894 = L.t;\n        }\n        rn = normalize(mix(n, cross(cross(_4894, v), _4894), vec3(abs(L.aniso) * smoothstep(0.0, 0.25, roughness))));\n    }\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05);\n    vec2 _4930 = fa_env_brdf(param, param_1);\n    vec3 param_2 = reflect(-v, rn);\n    float param_3 = roughness;\n    vec3 result = (fa_environment(param_2, param_3) * ((f0 * _4930.x) + (vec3(L.f90) * _4930.y))) * L.base_scale;\n    if (L.sheen_on)\n    {\n        vec3 param_4 = n;\n        float param_5 = L.sheen_rough;\n        result += ((L.sheen * (L.sheen_e * L.keep)) * fa_environment(param_4, param_5));\n    }\n    result *= occlusion;\n    if (L.coat > 0.0)\n    {\n        float param_6 = L.coat_rough;\n        float param_7 = L.coat_ndv;\n        vec2 _4988 = fa_env_brdf(param_6, param_7);\n        vec3 param_8 = reflect(-v, L.nc);\n        float param_9 = L.coat_rough;\n        result += (fa_environment(param_8, param_9) * (L.coat * ((0.039999999105930328369140625 * _4988.x) + _4988.y)));\n    }\n    return result;\n}\n\nvec3 fa_sky_reflection(vec3 n, vec3 v, vec3 f0, float roughness)\n{\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05);\n    vec2 _4458 = fa_env_brdf(param, param_1);\n    vec3 param_2 = reflect(-v, n);\n    float param_3 = roughness;\n    return fa_environment(param_2, param_3) * ((f0 * _4458.x) + vec3(_4458.y));\n}\n\nvec2 fa_xm_size(int k)\n{\n    return max(floor(fa_mesh_fs_params[24].zw / vec2(float(1 << k))), vec2(1.0));\n}\n\nvec2 fa_xm_origin(int k)\n{\n    if (k == 0)\n    {\n        return vec2(0.0);\n    }\n    float y = 0.0;\n    for (int j = 1; j < k; j++)\n    {\n        int param = j;\n        y += fa_xm_size(param).y;\n    }\n    return vec2(fa_mesh_fs_params[24].z, y);\n}\n\nvec3 fa_xm_texel(vec2 size, vec2 origin, vec2 p)\n{\n    return texelFetch(fa_screen_tex_fa_shadow_smp, ivec2(origin + clamp(p, vec2(0.0), size - vec2(1.0))), 0).xyz;\n}\n\nvec3 fa_xm_level(int k, vec2 uv)\n{\n    int param = k;\n    vec2 _5690 = fa_xm_size(param);\n    int param_1 = k;\n    vec2 _5694 = fa_xm_origin(param_1);\n    vec2 _5700 = (uv * _5690) - vec2(0.5);\n    vec2 _5703 = fract(_5700);\n    vec2 _5706 = floor(_5700);\n    vec2 param_2 = _5690;\n    vec2 param_3 = _5694;\n    vec2 param_4 = _5706;\n    vec2 param_5 = _5690;\n    vec2 param_6 = _5694;\n    vec2 param_7 = _5706 + vec2(1.0, 0.0);\n    vec2 param_8 = _5690;\n    vec2 param_9 = _5694;\n    vec2 param_10 = _5706 + vec2(0.0, 1.0);\n    vec2 param_11 = _5690;\n    vec2 param_12 = _5694;\n    vec2 param_13 = _5706 + vec2(1.0);\n    vec3 _5748 = vec3(_5703.x);\n    return mix(mix(fa_xm_texel(param_2, param_3, param_4), fa_xm_texel(param_5, param_6, param_7), _5748), mix(fa_xm_texel(param_8, param_9, param_10), fa_xm_texel(param_11, param_12, param_13), _5748), vec3(_5703.y));\n}\n\nvec3 fa_xm_sample(vec2 uv, float lod)\n{\n    float _5767 = max(fa_mesh_fs_params[31].w - 1.0, 0.0);\n    float _5771 = clamp(lod, 0.0, _5767);\n    int _5775 = int(floor(_5771));\n    int param = _5775;\n    vec2 param_1 = uv;\n    vec3 c = fa_xm_level(param, param_1);\n    float _5785 = float(_5775);\n    float _5786 = _5771 - _5785;\n    bool _5788 = _5786 > 0.001000000047497451305389404296875;\n    bool _5795;\n    if (_5788)\n    {\n        _5795 = _5785 < _5767;\n    }\n    else\n    {\n        _5795 = _5788;\n    }\n    if (_5795)\n    {\n        int param_2 = _5775 + 1;\n        vec2 param_3 = uv;\n        c = mix(c, fa_xm_level(param_2, param_3), vec3(_5786));\n    }\n    return c;\n}\n\nvec3 fa_transmitted(Surface s, vec3 n, vec3 v, float roughness, vec3 f0, float f90, float keep, float tr, inout float blend)\n{\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05);\n    vec2 _5821 = fa_env_brdf(param, param_1);\n    vec3 _5845 = ((vec3(1.0) - clamp((f0 * _5821.x) + (vec3(f90) * _5821.y), vec3(0.0), vec3(1.0))) * s.albedo) * (tr * keep);\n    vec3 through = _5845;\n    float _5851 = max(s.thickness, 0.0);\n    bool _5856 = _5851 > 0.0;\n    if ((s.attenuation_distance > 0.0) && _5856)\n    {\n        through *= exp((-((-log(clamp(s.attenuation_color, vec3(9.9999997473787516355514526367188e-05), vec3(1.0)))) / vec3(s.attenuation_distance))) * _5851);\n    }\n    bool _5881 = fa_mesh_fs_params[30].w > 1.5;\n    bool _5887;\n    if (_5881)\n    {\n        _5887 = fa_mesh_fs_params[30].w < 2.5;\n    }\n    else\n    {\n        _5887 = _5881;\n    }\n    bool _5894;\n    if (!_5887)\n    {\n        _5894 = fa_mesh_fs_params[30].w < 0.5;\n    }\n    else\n    {\n        _5894 = _5887;\n    }\n    if (_5894)\n    {\n        blend = clamp(dot(through, vec3(0.3333333432674407958984375)), 0.0, 0.980000019073486328125);\n        return vec3(0.0);\n    }\n    vec4 _5909 = vec4(fa_world_pos, 1.0);\n    float _5914 = dot(fa_mesh_fs_params[28], _5909);\n    vec2 uv0 = vec2(0.5);\n    if (_5914 > 9.9999997473787516355514526367188e-05)\n    {\n        vec2 _5932 = vec2(dot(fa_mesh_fs_params[26], _5909), dot(fa_mesh_fs_params[27], _5909)) / vec2(_5914);\n        float _5940;\n        if (fa_mesh_fs_params[24].y > 0.5)\n        {\n            _5940 = (_5932.y * 0.5) + 0.5;\n        }\n        else\n        {\n            _5940 = 0.5 - (_5932.y * 0.5);\n        }\n        uv0 = vec2((_5932.x * 0.5) + 0.5, _5940);\n    }\n    if (fa_mesh_fs_params[30].w > 2.5)\n    {\n        int param_2 = 0;\n        vec2 _5961 = fa_xm_size(param_2);\n        vec2 _5969 = floor(clamp(uv0, vec2(0.0), vec2(0.99989998340606689453125)) * _5961);\n        if (texelFetch(fa_screen_tex_fa_shadow_smp, ivec2(_5969), 0).w > 0.5)\n        {\n            int _5989 = int(floor((clamp(roughness, 0.0, 1.0) * 2.0) + 0.5));\n            vec3 acc = vec3(0.0);\n            float cnt = 0.0;\n            for (int dy = -2; dy <= 2; dy++)\n            {\n                for (int dx = -2; dx <= 2; dx++)\n                {\n                    bool _6012 = abs(dx) > _5989;\n                    bool _6020;\n                    if (!_6012)\n                    {\n                        _6020 = abs(dy) > _5989;\n                    }\n                    else\n                    {\n                        _6020 = _6012;\n                    }\n                    if (_6020)\n                    {\n                        continue;\n                    }\n                    vec4 _6041 = texelFetch(fa_screen_tex_fa_shadow_smp, ivec2(clamp(_5969 + vec2(float(dx), float(dy)), vec2(0.0), _5961 - vec2(1.0))), 0);\n                    if (_6041.w > 0.5)\n                    {\n                        acc += _6041.xyz;\n                        cnt += 1.0;\n                    }\n                }\n            }\n            return _5845 * (acc / vec3(max(cnt, 1.0)));\n        }\n    }\n    vec2 uv = uv0;\n    if (_5856)\n    {\n        vec4 _6089 = vec4(fa_world_pos + (refract(-v, n, 1.0 / max(s.ior, 1.0)) * _5851), 1.0);\n        float _6094 = dot(fa_mesh_fs_params[28], _6089);\n        uv = vec2(0.5);\n        if (_6094 > 9.9999997473787516355514526367188e-05)\n        {\n            vec2 _6111 = vec2(dot(fa_mesh_fs_params[26], _6089), dot(fa_mesh_fs_params[27], _6089)) / vec2(_6094);\n            float _6119;\n            if (fa_mesh_fs_params[24].y > 0.5)\n            {\n                _6119 = (_6111.y * 0.5) + 0.5;\n            }\n            else\n            {\n                _6119 = 0.5 - (_6111.y * 0.5);\n            }\n            uv = vec2((_6111.x * 0.5) + 0.5, _6119);\n        }\n    }\n    vec2 param_3 = clamp(uv, vec2(0.0), vec2(1.0));\n    float param_4 = (clamp(roughness, 0.0, 1.0) * clamp((2.0 * s.ior) - 2.0, 0.0, 1.0)) * max(fa_mesh_fs_params[31].w - 1.0, 0.0);\n    return through * fa_xm_sample(param_3, param_4);\n}\n\nvec3 fa_shadow_debug(vec3 color, vec3 world)\n{\n    if (fa_shadows[27].w < 0.5)\n    {\n        return color;\n    }\n    int _3305 = int(fa_shadows[25].x + 0.5);\n    float _3315 = dot(world - fa_shadows[27].xyz, fa_shadows[28].xyz);\n    vec3 tint = vec3(0.3499999940395355224609375);\n    bool _3320 = _3305 > 0;\n    bool _3329;\n    if (_3320)\n    {\n        int param = _3305 - 1;\n        _3329 = _3315 <= fa_shadow_split_at(param);\n    }\n    else\n    {\n        _3329 = _3320;\n    }\n    if (_3329)\n    {\n        tint = vec3(1.0, 0.1500000059604644775390625, 0.100000001490116119384765625);\n        bool _3335 = _3305 > 1;\n        bool _3342;\n        if (_3335)\n        {\n            _3342 = _3315 > fa_shadows[24].x;\n        }\n        else\n        {\n            _3342 = _3335;\n        }\n        if (_3342)\n        {\n            tint = vec3(0.100000001490116119384765625, 0.89999997615814208984375, 0.20000000298023223876953125);\n        }\n        bool _3348 = _3305 > 2;\n        bool _3355;\n        if (_3348)\n        {\n            _3355 = _3315 > fa_shadows[24].y;\n        }\n        else\n        {\n            _3355 = _3348;\n        }\n        if (_3355)\n        {\n            tint = vec3(0.1500000059604644775390625, 0.300000011920928955078125, 1.0);\n        }\n        bool _3361 = _3305 > 3;\n        bool _3368;\n        if (_3361)\n        {\n            _3368 = _3315 > fa_shadows[24].z;\n        }\n        else\n        {\n            _3368 = _3361;\n        }\n        if (_3368)\n        {\n            tint = vec3(1.0, 0.89999997615814208984375, 0.100000001490116119384765625);\n        }\n    }\n    return mix(color, tint, vec3(0.550000011920928955078125));\n}\n\nvoid main()\n{\n    fa_inst_load();\n    vec3 _9088 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _9088 = -_9088;\n    }\n    vec3 _8374 = normalize(fa_mesh_fs_params[0].xyz - fa_world_pos);\n    vec3 param = fa_world_pos;\n    fa_cluster_begin(param);\n    SurfaceInput param_1 = SurfaceInput(fa_world_pos, _9088, fa_world_tangent, fa_uv, fa_vertex_color, _8374, gl_FrontFacing);\n    Surface _8382 = fa_standard_surface(param_1);\n    vec3 _9119 = _8382.albedo;\n    float _9120 = _8382.alpha;\n    vec3 _9121 = _8382.normal;\n    float _9122 = _8382.metallic;\n    float _9123 = _8382.roughness;\n    float _9124 = _8382.occlusion;\n    vec3 _9125 = _8382.emission;\n    float _9126 = _8382.clearcoat;\n    float _9127 = _8382.clearcoat_roughness;\n    vec3 _9128 = _8382.sheen_color;\n    float _9129 = _8382.sheen_roughness;\n    float _9130 = _8382.anisotropy;\n    float _9131 = _8382.anisotropy_rotation;\n    float _9132 = _8382.specular;\n    float _9133 = _8382.ior;\n    vec3 _9134 = _8382.specular_color;\n    float _9135 = _8382.transmission;\n    float _9136 = _8382.thickness;\n    vec3 _9137 = _8382.attenuation_color;\n    float _9138 = _8382.attenuation_distance;\n    SurfaceInput param_2 = SurfaceInput(fa_world_pos, _9088, fa_world_tangent, fa_uv, fa_vertex_color, _8374, gl_FrontFacing);\n    Surface param_3 = _8382;\n    surface(param_2, param_3);\n    _9119 = param_3.albedo;\n    _9120 = param_3.alpha;\n    _9121 = param_3.normal;\n    _9122 = param_3.metallic;\n    _9123 = param_3.roughness;\n    _9124 = param_3.occlusion;\n    _9125 = param_3.emission;\n    _9126 = param_3.clearcoat;\n    _9127 = param_3.clearcoat_roughness;\n    _9128 = param_3.sheen_color;\n    _9129 = param_3.sheen_roughness;\n    _9130 = param_3.anisotropy;\n    _9131 = param_3.anisotropy_rotation;\n    _9132 = param_3.specular;\n    _9133 = param_3.ior;\n    _9134 = param_3.specular_color;\n    _9135 = param_3.transmission;\n    _9136 = param_3.thickness;\n    _9137 = param_3.attenuation_color;\n    _9138 = param_3.attenuation_distance;\n    vec3 param_4 = fa_world_pos;\n    vec3 param_5 = _9088;\n    vec3 param_6 = param_3.albedo;\n    vec3 param_7 = param_3.normal;\n    fa_apply_decals(param_4, param_5, param_6, param_7);\n    _9119 = param_6;\n    _9121 = param_7;\n    if (_9120 < fa_material[0].x)\n    {\n        discard;\n    }\n    fa_lod_dither();\n    float fa_tr_blend = 0.0;\n    vec3 result;\n    if (fa_mesh_fs_params[3].w > 0.5)\n    {\n        result = _9119;\n    }\n    else\n    {\n        vec3 _8434 = normalize(_9121);\n        float _8441 = clamp(_9122, 0.0, 1.0);\n        float _8445 = clamp(_9123, 0.0500000007450580596923828125, 1.0);\n        float _8449 = _8445 * _8445;\n        float _8453 = _8449 * _8449;\n        float _8458 = max(dot(_8434, _8374), 9.9999997473787516355514526367188e-05);\n        float _8464 = 1.0 - _8441;\n        float _8465 = clamp(_9135, 0.0, 1.0) * _8464;\n        vec3 _8474 = (_9119 * _8464) * (1.0 - _8465);\n        vec3 _8481 = mix(vec3(0.039999999105930328369140625), _9119, vec3(_8441));\n        vec3 f0 = _8481;\n        SurfaceInput param_8 = SurfaceInput(fa_world_pos, _9088, fa_world_tangent, fa_uv, fa_vertex_color, _8374, gl_FrontFacing);\n        Surface param_9 = Surface(_9119, _9120, _9121, _9122, _9123, _9124, _9125, _9126, _9127, _9128, _9129, _9130, _9131, _9132, _9133, _9134, _9135, _9136, _9137, _9138);\n        vec3 param_10 = _8434;\n        vec3 param_11 = _8374;\n        float param_12 = _8441;\n        float param_13 = _8445;\n        vec3 param_14 = _8481;\n        FaLayers _8497 = fa_layers_setup(param_8, param_9, param_10, param_11, param_12, param_13, param_14);\n        f0 = param_14;\n        vec3 param_15 = _8434;\n        vec3 lit = (fa_indirect_diffuse(param_15) * _8474) * _9124;\n        if (_8497.on)\n        {\n            lit *= _8497.base_scale;\n        }\n        int _8519 = fa_cl_ndir + fa_cl_local;\n        float _8584;\n        for (int ln = 0; ln < _8519; ln++)\n        {\n            int param_16 = ln;\n            int _8532 = fa_cl_light(param_16);\n            int param_17 = _8532;\n            if (fa_baked_keep(param_17) <= 0.0)\n            {\n                continue;\n            }\n            int param_18 = _8532;\n            vec3 param_19 = fa_world_pos;\n            vec3 param_20 = _9088;\n            LightSample _8548 = fa_light_shadowed(param_18, param_19, param_20);\n            float _8556 = max(dot(_8434, _8548.direction), 0.0);\n            float _8562 = _8548.attenuation * _8548.shadow;\n            vec3 _8567 = normalize(_8548.direction + _8374);\n            float _8572 = max(dot(_8434, _8567), 0.0);\n            float _8577 = max(dot(_8374, _8567), 0.0);\n            if (fa_light_is_area)\n            {\n                if (_8497.on)\n                {\n                    _8584 = _8497.f90;\n                }\n                else\n                {\n                    _8584 = 1.0;\n                }\n                int param_21 = _8532;\n                vec3 param_22 = fa_world_pos;\n                vec3 param_23 = _8434;\n                vec3 param_24 = _8374;\n                vec3 param_25 = _8474;\n                vec3 param_26 = f0;\n                float param_27 = _8584;\n                float param_28 = _8445;\n                float param_29 = _8458;\n                float param_30 = _8562;\n                vec3 area = fa_area_shade(param_21, param_22, param_23, param_24, param_25, param_26, param_27, param_28, param_29, param_30);\n                if (_8497.on)\n                {\n                    FaLayers param_31 = _8497;\n                    vec3 param_32 = area;\n                    int param_33 = _8532;\n                    vec3 param_34 = _8434;\n                    vec3 param_35 = _8374;\n                    vec3 param_36 = _8548.direction;\n                    float param_37 = _8458;\n                    float param_38 = _8562;\n                    area = fa_area_layers(param_31, param_32, param_33, param_34, param_35, param_36, param_37, param_38);\n                }\n                lit += area;\n            }\n            else\n            {\n                if (_8497.on)\n                {\n                    FaLayers param_39 = _8497;\n                    vec3 param_40 = _8474;\n                    vec3 param_41 = f0;\n                    vec3 param_42 = _8434;\n                    vec3 param_43 = _8374;\n                    vec3 param_44 = _8548.direction;\n                    vec3 param_45 = _8567;\n                    float param_46 = _8556;\n                    float param_47 = _8458;\n                    float param_48 = _8572;\n                    float param_49 = _8577;\n                    float param_50 = _8449;\n                    float param_51 = _8453;\n                    int param_52 = _8532;\n                    lit += (fa_layers_light(param_39, param_40, param_41, param_42, param_43, param_44, param_45, param_46, param_47, param_48, param_49, param_50, param_51) * ((fa_light_rgb(param_52) * fa_light_tint) * _8562));\n                }\n                else\n                {\n                    float _8686 = ((_8572 * _8572) * (_8453 - 1.0)) + 1.0;\n                    int param_53 = _8532;\n                    lit += (((_8474 + (((f0 + ((vec3(1.0) - f0) * pow(1.0 - _8577, 5.0))) * (((_8453 / ((3.1415927410125732421875 * _8686) * _8686)) * (0.5 / max(mix((2.0 * _8556) * _8458, _8556 + _8458, _8449), 9.9999997473787516355514526367188e-05))) * 3.1415927410125732421875)) * step(9.9999997473787516355514526367188e-05, _8556))) * (fa_light_rgb(param_53) * fa_light_tint)) * (_8556 * _8562));\n                }\n            }\n        }\n        if (_8497.on)\n        {\n            FaLayers param_54 = _8497;\n            vec3 param_55 = _8434;\n            vec3 param_56 = _8374;\n            vec3 param_57 = f0;\n            float param_58 = _8445;\n            float param_59 = _9124;\n            lit += fa_layers_ibl(param_54, param_55, param_56, param_57, param_58, param_59);\n        }\n        else\n        {\n            vec3 param_60 = _8434;\n            vec3 param_61 = _8374;\n            vec3 param_62 = f0;\n            float param_63 = _8445;\n            lit += (fa_sky_reflection(param_60, param_61, param_62, param_63) * _9124);\n        }\n        if (_8465 > 0.0)\n        {\n            float _8784;\n            if (_8497.on)\n            {\n                _8784 = _8497.f90;\n            }\n            else\n            {\n                _8784 = 1.0;\n            }\n            float _8792;\n            if (_8497.on)\n            {\n                _8792 = _8497.base_scale;\n            }\n            else\n            {\n                _8792 = 1.0;\n            }\n            Surface param_64 = Surface(_9119, _9120, _9121, _9122, _9123, _9124, _9125, _9126, _9127, _9128, _9129, _9130, _9131, _9132, _9133, _9134, _9135, _9136, _9137, _9138);\n            vec3 param_65 = _8434;\n            vec3 param_66 = _8374;\n            float param_67 = _8445;\n            vec3 param_68 = f0;\n            float param_69 = _8784;\n            float param_70 = _8792;\n            float param_71 = _8465;\n            float param_72 = fa_tr_blend;\n            vec3 _8816 = fa_transmitted(param_64, param_65, param_66, param_67, param_68, param_69, param_70, param_71, param_72);\n            fa_tr_blend = param_72;\n            lit += _8816;\n        }\n        result = lit;\n    }\n    vec3 _8823 = result;\n    vec3 _8824 = _8823 + _9125;\n    result = _8824;\n    vec3 param_73 = _8824;\n    vec3 param_74 = fa_world_pos;\n    result = fa_shadow_debug(param_73, param_74);\n    bool _8833 = fa_mesh_fs_params[7].w > 0.0;\n    bool _8840;\n    if (!_8833)\n    {\n        _8840 = fa_mesh_fs_params[8].y > 0.0;\n    }\n    else\n    {\n        _8840 = _8833;\n    }\n    if (_8840)\n    {\n        vec3 _8849 = fa_world_pos - fa_mesh_fs_params[0].xyz;\n        float _8855 = dot(_8849, fa_mesh_fs_params[9].xyz);\n        bool _8859 = fa_mesh_fs_params[9].w > 0.5;\n        float _8860;\n        if (_8859)\n        {\n            _8860 = _8855;\n        }\n        else\n        {\n            _8860 = length(_8849);\n        }\n        float _8872 = _8860 - fa_mesh_fs_params[8].x;\n        if (_8872 > 0.0)\n        {\n            float _8881 = fa_mesh_fs_params[7].w * _8872;\n            float tau = _8881 * _8881;\n            if (fa_mesh_fs_params[8].y > 0.0)\n            {\n                float _8897;\n                if (_8859)\n                {\n                    _8897 = fa_world_pos.y - (fa_mesh_fs_params[9].y * _8855);\n                }\n                else\n                {\n                    _8897 = fa_mesh_fs_params[0].y;\n                }\n                float _8918 = mix(_8897, fa_world_pos.y, clamp(fa_mesh_fs_params[8].x / _8860, 0.0, 1.0));\n                float _8922 = fa_world_pos.y - _8918;\n                float _8927 = _8918 - fa_mesh_fs_params[8].z;\n                float _8932 = fa_world_pos.y - fa_mesh_fs_params[8].z;\n                bool _8935 = _8927 <= 0.0;\n                bool _8936 = !_8935;\n                bool _8942;\n                if (_8936)\n                {\n                    _8942 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _8942 = _8935;\n                }\n                float _8943;\n                if (_8942)\n                {\n                    _8943 = fa_mesh_fs_params[8].y;\n                }\n                else\n                {\n                    _8943 = fa_mesh_fs_params[8].y * exp(-min(fa_mesh_fs_params[8].w * _8927, 80.0));\n                }\n                bool _8970;\n                if (_8936)\n                {\n                    _8970 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _8970 = _8935;\n                }\n                float _8971;\n                if (_8970)\n                {\n                    _8971 = fa_mesh_fs_params[8].y * _8927;\n                }\n                else\n                {\n                    _8971 = (fa_mesh_fs_params[8].y * (1.0 - exp(-min(fa_mesh_fs_params[8].w * _8927, 80.0)))) / fa_mesh_fs_params[8].w;\n                }\n                bool _8996 = _8932 <= 0.0;\n                bool _9003;\n                if (!_8996)\n                {\n                    _9003 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _9003 = _8996;\n                }\n                float _9004;\n                if (_9003)\n                {\n                    _9004 = fa_mesh_fs_params[8].y * _8932;\n                }\n                else\n                {\n                    _9004 = (fa_mesh_fs_params[8].y * (1.0 - exp(-min(fa_mesh_fs_params[8].w * _8932, 80.0)))) / fa_mesh_fs_params[8].w;\n                }\n                float _9031;\n                if (abs(_8922) < 0.001000000047497451305389404296875)\n                {\n                    _9031 = _8943;\n                }\n                else\n                {\n                    _9031 = (_9004 - _8971) / _8922;\n                }\n                tau += (_8872 * max(_9031, 0.0));\n            }\n            result = mix(result, fa_mesh_fs_params[7].xyz, vec3(clamp(1.0 - exp(-clamp(tau, 0.0, 80.0)), 0.0, 1.0)));\n        }\n    }\n    if (fa_tr_blend > 0.0)\n    {\n        float _9067 = 1.0 - fa_tr_blend;\n        result /= vec3(_9067);\n        _9120 *= _9067;\n    }\n    fa_frag_color = vec4(result, _9120);\n}\n\n",
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
            "inst_name": "_8410",
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
      "vs": "#version 430\n\nstruct VertexData\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 color;\n    vec3 object_pos;\n};\n\nuniform vec4 fa_mesh_vs_params[11];\nuniform vec4 fa_skin[192];\nlayout(location = 0) out vec3 fa_world_pos;\nlayout(location = 1) out vec3 fa_world_normal;\nlayout(location = 2) out vec4 fa_world_tangent;\nlayout(location = 3) out vec2 fa_uv;\nlayout(location = 4) out vec4 fa_vertex_color;\nlayout(location = 5) in vec4 fa_inst_m0;\nlayout(location = 6) in vec4 fa_inst_m1;\nlayout(location = 7) in vec4 fa_inst_m2;\nlayout(location = 8) in vec4 fa_inst_m3;\nlayout(location = 9) in vec4 fa_joints;\nlayout(location = 10) in vec4 fa_weights;\nlayout(location = 0) in vec3 fa_position;\nlayout(location = 1) in vec3 fa_normal;\nlayout(location = 3) in vec4 fa_tangent;\nlayout(location = 2) in vec2 fa_texcoord0;\nlayout(location = 4) in vec4 fa_color;\nlayout(location = 5) out vec3 fa_lm;\n\nvoid fa_inst_begin()\n{\n}\n\nmat4 fa_skin_matrix(vec4 joints, vec4 weights)\n{\n    vec4 r0 = vec4(0.0);\n    vec4 r1 = vec4(0.0);\n    vec4 r2 = vec4(0.0);\n    for (int i = 0; i < 4; i++)\n    {\n        int _174 = int((joints[i] * 255.0) + 0.5) * 3;\n        r0 += (fa_skin[_174 * 1 + 0] * weights[i]);\n        r1 += (fa_skin[(_174 + 1) * 1 + 0] * weights[i]);\n        r2 += (fa_skin[(_174 + 2) * 1 + 0] * weights[i]);\n    }\n    return mat4(vec4(r0.x, r1.x, r2.x, 0.0), vec4(r0.y, r1.y, r2.y, 0.0), vec4(r0.z, r1.z, r2.z, 0.0), vec4(r0.w, r1.w, r2.w, 1.0));\n}\n\nVertexData fa_vertex_data(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    vec3 _74 = cross(model[1].xyz, model[2].xyz);\n    float _80 = (dot(model[0].xyz, _74) < 0.0) ? (-1.0) : 1.0;\n    return VertexData((model * vec4(position, 1.0)).xyz, (((_74 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _80, vec4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _80), texcoord0 * fa_mesh_vs_params[8].xy, color, position);\n}\n\nvoid fa_shade_vertex(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    mat4 param = model;\n    vec3 param_1 = position;\n    vec3 param_2 = normal;\n    vec4 param_3 = tangent;\n    vec2 param_4 = texcoord0;\n    vec4 param_5 = color;\n    VertexData _273 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    vec3 _391 = _273.world_pos;\n    fa_world_pos = _391;\n    fa_world_normal = _273.world_normal;\n    fa_world_tangent = _273.world_tangent;\n    fa_uv = _273.uv;\n    fa_vertex_color = _273.color;\n    gl_Position = mat4(fa_mesh_vs_params[0], fa_mesh_vs_params[1], fa_mesh_vs_params[2], fa_mesh_vs_params[3]) * vec4(_391, 1.0);\n}\n\nvoid main()\n{\n    fa_inst_begin();\n    vec4 param = fa_joints;\n    vec4 param_1 = fa_weights;\n    mat4 param_2 = mat4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3) * fa_skin_matrix(param, param_1);\n    vec3 param_3 = fa_position;\n    vec3 param_4 = fa_normal;\n    vec4 param_5 = fa_tangent;\n    vec2 param_6 = fa_texcoord0;\n    vec4 param_7 = fa_color;\n    fa_shade_vertex(param_2, param_3, param_4, param_5, param_6, param_7);\n    fa_lm = vec3(0.0);\n}\n\n",
      "fs": "#version 430\n\nstruct SurfaceInput\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 vertex_color;\n    vec3 view_dir;\n    bool front_facing;\n};\n\nstruct LightSample\n{\n    vec3 direction;\n    vec3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct Surface\n{\n    vec3 albedo;\n    float alpha;\n    vec3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    vec3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    vec3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    vec3 specular_color;\n    float transmission;\n    float thickness;\n    vec3 attenuation_color;\n    float attenuation_distance;\n};\n\nstruct FaLayers\n{\n    bool on;\n    float f90;\n    float keep;\n    float base_scale;\n    float coat;\n    float coat_rough;\n    float coat_alpha;\n    float coat_a2;\n    vec3 nc;\n    float coat_ndv;\n    bool sheen_on;\n    vec3 sheen;\n    float sheen_rough;\n    float sheen_alpha;\n    float sheen_scale;\n    float sheen_e;\n    float aniso;\n    vec3 t;\n    vec3 b;\n    float at;\n    float ab;\n};\n\nconst float _4559[63] = float[](1.0, 1.0, 1.0, 0.4790000021457672119140625, 0.11699999868869781494140625, 0.01200000010430812835693359375, 0.0, 0.0, 0.0, 1.0, 1.0, 1.0, 0.578000009059906005859375, 0.19300000369548797607421875, 0.0350000001490116119384765625, 0.0030000000260770320892333984375, 0.0, 0.0, 1.0, 1.0, 1.0, 0.6740000247955322265625, 0.3459999859333038330078125, 0.1319999992847442626953125, 0.032999999821186065673828125, 0.0040000001899898052215576171875, 0.0, 0.971000015735626220703125, 0.954999983310699462890625, 0.828999996185302734375, 0.63999998569488525390625, 0.42599999904632568359375, 0.24500000476837158203125, 0.115000002086162567138671875, 0.037000000476837158203125, 0.0030000000260770320892333984375, 0.7469999790191650390625, 0.737999975681304931640625, 0.670000016689300537109375, 0.563000023365020751953125, 0.4309999942779541015625, 0.3039999902248382568359375, 0.1940000057220458984375, 0.1019999980926513671875, 0.0309999994933605194091796875, 0.614000022411346435546875, 0.609000027179718017578125, 0.566999971866607666015625, 0.499000012874603271484375, 0.412000000476837158203125, 0.32400000095367431640625, 0.240999996662139892578125, 0.162000000476837158203125, 0.087999999523162841796875, 0.538999974727630615234375, 0.535000026226043701171875, 0.505999982357025146484375, 0.4569999873638153076171875, 0.393999993801116943359375, 0.328999996185302734375, 0.2660000026226043701171875, 0.203999996185302734375, 0.14200000464916229248046875);\n\nuniform vec4 fa_mesh_fs_params[53];\nuniform vec4 fa_shadows[30];\nuniform vec4 fa_material[1];\nlayout(binding = 0) uniform sampler2D fa_light_tex_fa_shadow_smp;\nlayout(binding = 1) uniform sampler2D fa_tex_fa_smp;\nlayout(binding = 2) uniform sampler2D fa_normal_tex_fa_smp;\nlayout(binding = 3) uniform sampler2D fa_mr_tex_fa_smp;\nlayout(binding = 4) uniform sampler2D fa_occlusion_tex_fa_smp;\nlayout(binding = 5) uniform sampler2D fa_emissive_tex_fa_smp;\nlayout(binding = 6) uniform sampler2D fa_decal_tex_fa_env_smp;\nlayout(binding = 7) uniform sampler2D fa_lightmap_fa_env_smp;\nlayout(binding = 8) uniform sampler2D fa_probe_atlas_fa_env_smp;\nlayout(binding = 9) uniform sampler2D fa_light_atlas_fa_env_smp;\nlayout(binding = 10) uniform sampler2D fa_screen_tex_fa_shadow_smp;\nlayout(binding = 11) uniform sampler2D fa_shadow_tex_fa_shadow_smp;\n\nlayout(location = 0) in vec3 fa_world_pos;\nlayout(location = 5) in vec3 fa_lm;\nlayout(location = 1) in vec3 fa_world_normal;\nlayout(location = 2) in vec4 fa_world_tangent;\nlayout(location = 3) in vec2 fa_uv;\nlayout(location = 4) in vec4 fa_vertex_color;\nlayout(location = 0) out vec4 fa_frag_color;\nvec3 fa_light_tint;\nbool fa_light_is_area;\nint fa_cl_ndir;\nint fa_cl_slot;\nint fa_cl_local;\n\nvoid fa_inst_load()\n{\n}\n\nvec4 fa_light_texel(int t)\n{\n    return texelFetch(fa_light_tex_fa_shadow_smp, ivec2(t & 1023, t >> 10), 0);\n}\n\nvec4 fa_cluster_texel(vec3 world_pos)\n{\n    bool _1628 = fa_mesh_fs_params[19].x < 0.0;\n    bool _1635;\n    if (!_1628)\n    {\n        _1635 = fa_mesh_fs_params[19].w < 1.0;\n    }\n    else\n    {\n        _1635 = _1628;\n    }\n    bool _1643;\n    if (!_1635)\n    {\n        _1643 = fa_mesh_fs_params[18].x < 1.0;\n    }\n    else\n    {\n        _1643 = _1635;\n    }\n    bool _1650;\n    if (!_1643)\n    {\n        _1650 = fa_mesh_fs_params[18].y < 1.0;\n    }\n    else\n    {\n        _1650 = _1643;\n    }\n    bool _1657;\n    if (!_1650)\n    {\n        _1657 = fa_mesh_fs_params[19].y < 1.0;\n    }\n    else\n    {\n        _1657 = _1650;\n    }\n    if (_1657)\n    {\n        return vec4(0.0);\n    }\n    vec4 _1667 = vec4(world_pos, 1.0);\n    float _1673 = dot(fa_mesh_fs_params[16], _1667);\n    if (!(_1673 > 9.9999999747524270787835121154785e-07))\n    {\n        return vec4(0.0);\n    }\n    vec2 _1695 = vec2(dot(fa_mesh_fs_params[14], _1667), dot(fa_mesh_fs_params[15], _1667)) / vec2(_1673);\n    int _1699 = int(fa_mesh_fs_params[18].x);\n    int _1703 = int(fa_mesh_fs_params[18].y);\n    int param = (int(fa_mesh_fs_params[19].x) + (((clamp(int(floor(log2(max(dot(fa_mesh_fs_params[17].xyz, world_pos) + fa_mesh_fs_params[17].w, fa_mesh_fs_params[18].w) / fa_mesh_fs_params[18].w) * fa_mesh_fs_params[18].z)), 0, int(fa_mesh_fs_params[19].y) - 1) * _1703) + clamp(int(floor(((_1695.y * 0.5) + 0.5) * fa_mesh_fs_params[18].y)), 0, _1703 - 1)) * _1699)) + clamp(int(floor(((_1695.x * 0.5) + 0.5) * fa_mesh_fs_params[18].x)), 0, _1699 - 1);\n    return fa_light_texel(param);\n}\n\nivec2 fa_cluster_lookup(vec3 world_pos)\n{\n    vec3 param = world_pos;\n    vec4 _1779 = fa_cluster_texel(param);\n    return ivec2(int(_1779.x), int(_1779.y));\n}\n\nvoid fa_cluster_begin(vec3 world_pos)\n{\n    fa_cl_ndir = int(fa_mesh_fs_params[19].z);\n    vec3 param = world_pos;\n    ivec2 _6193 = fa_cluster_lookup(param);\n    fa_cl_slot = _6193.x;\n    fa_cl_local = _6193.y;\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nvec3 fa_linear_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_tex_fix(inout vec3 c, float mode)\n{\n    if (mode > 1.5)\n    {\n        vec3 param = c;\n        vec3 _7352 = fa_linear_to_srgb(param);\n        c = _7352;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            vec3 param_1 = c;\n            vec3 _7360 = fa_srgb_to_linear(param_1);\n            c = _7360;\n        }\n    }\n    return c;\n}\n\nvec3 fa_tangent_normal(SurfaceInput i, vec3 m)\n{\n    vec3 _534;\n    if (i.front_facing)\n    {\n        _534 = i.world_normal;\n    }\n    else\n    {\n        _534 = -i.world_normal;\n    }\n    vec3 _558 = normalize(i.world_tangent.xyz - (_534 * dot(_534, i.world_tangent.xyz)));\n    vec3 _585 = normalize(((_558 * m.x) + ((cross(_534, _558) * i.world_tangent.w) * m.y)) + (_534 * m.z));\n    vec3 _588;\n    if (i.front_facing)\n    {\n        _588 = _585;\n    }\n    else\n    {\n        _588 = -_585;\n    }\n    return _588;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    vec4 base_t = texture(fa_tex_fa_smp, i.uv, fa_mesh_fs_params[12].w);\n    float param = fa_mesh_fs_params[6].w;\n    float param_1 = 1.0;\n    vec3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    vec3 _7392 = fa_tex_fix(param_2, param_3);\n    vec4 _9689 = base_t;\n    _9689.x = _7392.x;\n    _9689.y = _7392.y;\n    _9689.z = _7392.z;\n    base_t = _9689;\n    vec4 _7406 = (_9689 * fa_mesh_fs_params[2]) * i.vertex_color;\n    vec3 _9449 = i.world_normal;\n    if (fa_mesh_fs_params[6].z > 0.5)\n    {\n        float param_4 = fa_mesh_fs_params[6].w;\n        float param_5 = 16.0;\n        vec3 param_6 = texture(fa_normal_tex_fa_smp, i.uv, fa_mesh_fs_params[12].w).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        vec3 _7440 = fa_tex_fix(param_6, param_7);\n        vec3 _7443 = (_7440 * 2.0) - vec3(1.0);\n        vec2 _7448 = _7443.xy * fa_mesh_fs_params[6].x;\n        vec3 _9697 = _7443;\n        _9697.x = _7448.x;\n        _9697.y = _7448.y;\n        SurfaceInput param_8 = i;\n        vec3 param_9 = _9697;\n        _9449 = fa_tangent_normal(param_8, param_9);\n    }\n    vec4 mrt = texture(fa_mr_tex_fa_smp, i.uv, fa_mesh_fs_params[12].w);\n    float param_10 = fa_mesh_fs_params[6].w;\n    float param_11 = 64.0;\n    vec3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    vec3 _7478 = fa_tex_fix(param_12, param_13);\n    vec4 _9700 = mrt;\n    _9700.x = _7478.x;\n    _9700.y = _7478.y;\n    _9700.z = _7478.z;\n    mrt = _9700;\n    vec4 _7508 = texture(fa_occlusion_tex_fa_smp, i.uv, fa_mesh_fs_params[12].w);\n    float param_14 = fa_mesh_fs_params[6].w;\n    float param_15 = 256.0;\n    vec3 param_16 = _7508.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    vec3 _7519 = fa_tex_fix(param_16, param_17);\n    float param_18 = fa_mesh_fs_params[6].w;\n    float param_19 = 4.0;\n    vec3 param_20 = texture(fa_emissive_tex_fa_smp, i.uv, fa_mesh_fs_params[12].w).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    vec3 _7551 = fa_tex_fix(param_20, param_21);\n    float _9454 = fa_mesh_fs_params[20].x;\n    float _9455 = fa_mesh_fs_params[20].y;\n    float _9458 = fa_mesh_fs_params[20].z;\n    float _9457 = fa_mesh_fs_params[21].w;\n    float _9460 = fa_mesh_fs_params[22].x;\n    if (fa_mesh_fs_params[22].z > 0.5)\n    {\n        if (mod(fa_mesh_fs_params[22].z, 2.0) > 0.5)\n        {\n            _9454 *= _7519.y;\n            _9455 *= _7519.z;\n            _9457 *= _7508.w;\n        }\n        if (fa_mesh_fs_params[22].z > 1.5)\n        {\n            _9458 *= mrt.x;\n            _9460 *= mrt.w;\n        }\n    }\n    return Surface(_7406.xyz, _7406.w, _9449, clamp(fa_mesh_fs_params[5].x * _7478.z, 0.0, 1.0), clamp(fa_mesh_fs_params[5].y * _7478.y, 0.0500000007450580596923828125, 1.0), 1.0 + (fa_mesh_fs_params[6].y * (_7519.x - 1.0)), fa_mesh_fs_params[3].xyz + (fa_mesh_fs_params[4].xyz * _7551), _9454, _9455, fa_mesh_fs_params[21].xyz, _9457, _9458, fa_mesh_fs_params[20].w, _9460, fa_mesh_fs_params[22].y, fa_mesh_fs_params[23].xyz, fa_mesh_fs_params[30].x, fa_mesh_fs_params[30].y, fa_mesh_fs_params[31].xyz, fa_mesh_fs_params[30].z);\n}\n\nvoid surface(SurfaceInput i, Surface s)\n{\n}\n\nvec4 fa_decal_tile(vec4 rect, vec2 uv, vec2 atlas, vec2 ddx, vec2 ddy)\n{\n    vec2 _1859 = rect.zw - rect.xy;\n    vec2 _1863 = _1859 * atlas;\n    vec2 _1867 = ddx * _1863;\n    vec2 _1871 = ddy * _1863;\n    return textureLod(fa_decal_tex_fa_env_smp, rect.xy + (clamp(uv, vec2(0.0), vec2(1.0)) * _1859), clamp(0.5 * log2(max(max(dot(_1867, _1867), dot(_1871, _1871)), 9.9999999392252902907785028219223e-09)), 0.0, 3.0));\n}\n\nvec3 fa_dc_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_dc_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvoid fa_apply_decals(vec3 world_pos, vec3 geo_normal, inout vec3 albedo, inout vec3 normal)\n{\n    bool _1904 = fa_mesh_fs_params[10].y < 0.5;\n    bool _1911;\n    if (!_1904)\n    {\n        _1911 = fa_mesh_fs_params[10].w < 0.5;\n    }\n    else\n    {\n        _1911 = _1904;\n    }\n    if (_1911)\n    {\n        return;\n    }\n    vec3 _1917 = dFdx(world_pos);\n    vec3 _1920 = dFdy(world_pos);\n    vec3 param = world_pos;\n    vec4 _1924 = fa_cluster_texel(param);\n    int _1928 = int(_1924.w);\n    if (_1928 < 1)\n    {\n        return;\n    }\n    int _1938 = int(fa_mesh_fs_params[10].y + 0.5);\n    int param_1 = _1938;\n    vec4 _1942 = fa_light_texel(param_1);\n    vec2 _1945 = _1942.yz;\n    int _1949 = int(_1942.w);\n    int param_2 = _1938 + 1;\n    vec4 _1954 = fa_light_texel(param_2);\n    float _1955 = _1954.x;\n    int _1961 = int(fa_mesh_fs_params[10].w + 0.5) - 1;\n    int _1965 = int(_1924.z);\n    vec3 _2230;\n    for (int k = 0; k < _1928; k++)\n    {\n        int _1978 = _1965 + k;\n        int param_3 = _1949 + (_1978 >> 2);\n        int _1995 = (_1938 + 2) + (int(fa_light_texel(param_3)[_1978 & 3]) * 7);\n        int param_4 = _1995 + 6;\n        vec4 _2000 = fa_light_texel(param_4);\n        if (((int(_2000.w + 0.5) >> _1961) & 1) == 0)\n        {\n            continue;\n        }\n        int param_5 = _1995;\n        vec4 _2015 = fa_light_texel(param_5);\n        int param_6 = _1995 + 1;\n        vec4 _2020 = fa_light_texel(param_6);\n        int param_7 = _1995 + 2;\n        vec4 _2025 = fa_light_texel(param_7);\n        vec3 _2028 = _2015.xyz;\n        float _2033 = dot(_2028, world_pos) + _2015.w;\n        vec3 _2035 = _2020.xyz;\n        float _2040 = dot(_2035, world_pos) + _2020.w;\n        vec3 _2042 = _2025.xyz;\n        float _2047 = dot(_2042, world_pos) + _2025.w;\n        bool _2052 = abs(_2033) > 0.5;\n        bool _2060;\n        if (!_2052)\n        {\n            _2060 = abs(_2040) > 0.5;\n        }\n        else\n        {\n            _2060 = _2052;\n        }\n        bool _2068;\n        if (!_2060)\n        {\n            _2068 = abs(_2047) > 0.5;\n        }\n        else\n        {\n            _2068 = _2060;\n        }\n        if (_2068)\n        {\n            continue;\n        }\n        float _2083 = clamp(dot(geo_normal, normalize(_2042)) * _2000.z, 0.0, 1.0);\n        if (_2083 <= 0.0)\n        {\n            continue;\n        }\n        float _2103 = (clamp((0.5 - abs(_2047)) * 10.0, 0.0, 1.0) * _2083) * _2000.x;\n        vec2 _2111 = vec2(_2033 + 0.5, 0.5 - _2040);\n        vec2 _2121 = vec2(dot(_2028, _1917), dot(_2035, _1917));\n        vec2 _2131 = vec2(dot(_2028, _1920), dot(_2035, _1920));\n        int param_8 = _1995 + 5;\n        vec4 _2136 = fa_light_texel(param_8);\n        int param_9 = _1995 + 3;\n        vec4 _2141 = fa_light_texel(param_9);\n        int param_10 = _1995 + 4;\n        vec4 _2146 = fa_light_texel(param_10);\n        float tex_a = 1.0;\n        vec3 col = _2136.xyz;\n        bool _2156 = _2141.z > _2141.x;\n        if (_2156)\n        {\n            vec4 param_11 = _2141;\n            vec2 param_12 = _2111;\n            vec2 param_13 = _1945;\n            vec2 param_14 = _2121;\n            vec2 param_15 = _2131;\n            vec4 tx = fa_decal_tile(param_11, param_12, param_13, param_14, param_15);\n            if ((_1955 > 0.5) && (_1955 < 1.5))\n            {\n                vec3 param_16 = tx.xyz;\n                vec3 _2182 = fa_dc_to_linear(param_16);\n                vec4 _9537 = tx;\n                _9537.x = _2182.x;\n                _9537.y = _2182.y;\n                _9537.z = _2182.z;\n                tx = _9537;\n            }\n            col *= tx.xyz;\n            tex_a = tx.w;\n        }\n        albedo = mix(albedo, col, vec3(clamp((_2103 * tex_a) * _2136.w, 0.0, 1.0)));\n        if (_2146.z > _2146.x)\n        {\n            vec4 param_17 = _2146;\n            vec2 param_18 = _2111;\n            vec2 param_19 = _1945;\n            vec2 param_20 = _2121;\n            vec2 param_21 = _2131;\n            vec4 _2226 = fa_decal_tile(param_17, param_18, param_19, param_20, param_21);\n            if (_1955 > 1.5)\n            {\n                vec3 param_22 = _2226.xyz;\n                vec3 _2236 = fa_dc_to_srgb(param_22);\n                _2230 = _2236;\n            }\n            else\n            {\n                _2230 = _2226.xyz;\n            }\n            vec3 _2245 = (_2230 * 2.0) - vec3(1.0);\n            vec2 _2250 = _2245.xy * _2000.y;\n            vec3 _2272 = (normalize(_2028) * _2250.x) + (normalize(_2035) * _2250.y);\n            vec3 _2275 = normalize(normal);\n            normal = normalize(mix(_2275, normalize((_2275 * max(_2245.z, 0.0500000007450580596923828125)) + (_2272 - (_2275 * dot(_2275, _2272)))), vec3(clamp(_2103 * (_2156 ? tex_a : 1.0), 0.0, 1.0))));\n        }\n    }\n}\n\nvoid fa_lod_dither()\n{\n    if (fa_mesh_fs_params[52].w != 0.0)\n    {\n        float _624 = fract(52.98291778564453125 * fract(dot(gl_FragCoord.xy, vec2(0.067110560834407806396484375, 0.005837149918079376220703125))));\n        bool _627;\n        if (fa_mesh_fs_params[52].w > 0.0)\n        {\n            _627 = _624 >= fa_mesh_fs_params[52].w;\n        }\n        else\n        {\n            _627 = _624 < (-fa_mesh_fs_params[52].w);\n        }\n        if (_627)\n        {\n            discard;\n        }\n    }\n}\n\nfloat fa_sheen_albedo(float ndv, float rough)\n{\n    float _4484 = min(sqrt(max(rough - 0.100000001490116119384765625, 0.0) * 1.111111164093017578125) * 6.0, 5.999000072479248046875);\n    float _4492 = min(sqrt(clamp(ndv, 0.0, 1.0)) * 8.0, 7.999000072479248046875);\n    int _4495 = int(_4484);\n    int _4498 = int(_4492);\n    float _4508 = _4492 - float(_4498);\n    int _4563 = (_4495 * 9) + _4498;\n    int _4583 = ((_4495 + 1) * 9) + _4498;\n    return mix(mix(_4559[_4563], _4559[_4563 + 1], _4508), mix(_4559[_4583], _4559[_4583 + 1], _4508), _4484 - float(_4495));\n}\n\nFaLayers fa_layers_setup(SurfaceInput i, Surface s, vec3 n, vec3 v, float metallic, float roughness, inout vec3 f0)\n{\n    bool _9372 = false;\n    float _9373 = 1.0;\n    float _9374 = 1.0;\n    float _9375 = 1.0;\n    float _9376 = 0.0;\n    float _9377 = 0.0;\n    float _9378 = 0.0;\n    float _9379 = 0.0;\n    float _9381 = 1.0;\n    bool _9382 = false;\n    vec3 _9383 = vec3(0.0);\n    float _9384 = 1.0;\n    float _9385 = 1.0;\n    float _9386 = 1.0;\n    float _9387 = 0.0;\n    float _9388 = 0.0;\n    vec3 _9389 = vec3(1.0, 0.0, 0.0);\n    vec3 _9390 = vec3(0.0, 0.0, 1.0);\n    float _9391 = 1.0;\n    float _9392 = 1.0;\n    float _4634 = clamp(s.specular, 0.0, 1.0);\n    float _4638 = clamp(s.ior, 1.0, 3.0);\n    bool _4643 = (_4634 != 1.0) || (_4638 != 1.5);\n    bool _4652;\n    if (!_4643)\n    {\n        _4652 = any(notEqual(s.specular_color, vec3(1.0)));\n    }\n    else\n    {\n        _4652 = _4643;\n    }\n    if (_4652)\n    {\n        float _4660 = (_4638 - 1.0) / (_4638 + 1.0);\n        f0 = mix(min(vec3(_4660 * _4660) * max(s.specular_color, vec3(0.0)), vec3(1.0)) * _4634, s.albedo, vec3(metallic));\n        _9373 = mix(_4634, 1.0, metallic);\n        _9372 = true;\n    }\n    float _4687 = clamp(s.clearcoat, 0.0, 1.0);\n    if (_4687 > 0.0)\n    {\n        float _4695 = clamp(s.clearcoat_roughness, 0.0500000007450580596923828125, 1.0);\n        _9376 = _4687;\n        _9377 = _4695;\n        float _4702 = _4695 * _4695;\n        _9378 = _4702;\n        _9379 = _4702 * _4702;\n        float _4714 = max(dot(i.world_normal, v), 9.9999997473787516355514526367188e-05);\n        _9381 = _4714;\n        _9374 = 1.0 - (_4687 * (0.039999999105930328369140625 + (0.959999978542327880859375 * pow(clamp(1.0 - _4714, 0.0, 1.0), 5.0))));\n        _9372 = true;\n    }\n    vec3 _4733 = max(s.sheen_color, vec3(0.0));\n    float _4742 = max(_4733.x, max(_4733.y, _4733.z));\n    if (_4742 > 0.0)\n    {\n        float _4750 = clamp(s.sheen_roughness, 0.100000001490116119384765625, 1.0);\n        _9382 = true;\n        _9383 = _4733;\n        _9384 = _4750;\n        _9385 = _4750 * _4750;\n        float param = max(dot(n, v), 9.9999997473787516355514526367188e-05);\n        float param_1 = _4750;\n        float _4767 = fa_sheen_albedo(param, param_1);\n        _9387 = _4767;\n        _9386 = 1.0 - min(_4742 * _4767, 1.0);\n        _9372 = true;\n    }\n    _9375 = _9374 * _9386;\n    float _4786 = clamp(s.anisotropy, -1.0, 1.0);\n    if (_4786 != 0.0)\n    {\n        vec3 _4801 = i.world_tangent.xyz - (n * dot(n, i.world_tangent.xyz));\n        vec3 t = _4801;\n        if (dot(_4801, _4801) < 9.9999999392252902907785028219223e-09)\n        {\n            bvec3 _4813 = bvec3(abs(n.y) < 0.9900000095367431640625);\n            t = cross(vec3(_4813.x ? vec3(0.0, 1.0, 0.0).x : vec3(1.0, 0.0, 0.0).x, _4813.y ? vec3(0.0, 1.0, 0.0).y : vec3(1.0, 0.0, 0.0).y, _4813.z ? vec3(0.0, 1.0, 0.0).z : vec3(1.0, 0.0, 0.0).z), n);\n        }\n        vec3 _4817 = t;\n        vec3 _4818 = normalize(_4817);\n        t = _4818;\n        vec3 _4843 = normalize((_4818 * cos(s.anisotropy_rotation)) + ((cross(n, _4818) * ((i.world_tangent.w < 0.0) ? (-1.0) : 1.0)) * sin(s.anisotropy_rotation)));\n        _9389 = _4843;\n        _9390 = cross(n, _4843);\n        float _4853 = roughness * roughness;\n        float _4859 = mix(_4853, 1.0, _4786 * _4786);\n        bool _4861 = _4786 > 0.0;\n        _9391 = _4861 ? _4859 : _4853;\n        _9392 = _4861 ? _4853 : _4859;\n        _9388 = _4786;\n        _9372 = true;\n    }\n    return FaLayers(_9372, _9373, _9374, _9375, _9376, _9377, _9378, _9379, i.world_normal, _9381, _9382, _9383, _9384, _9385, _9386, _9387, _9388, _9389, _9390, _9391, _9392);\n}\n\nvec2 fa_atlas_size()\n{\n    return vec2(textureSize(fa_probe_atlas_fa_env_smp, 0));\n}\n\nvec3 fa_probe_sh_coef(vec2 origin, float res, int k)\n{\n    vec3 v = textureLod(fa_probe_atlas_fa_env_smp, (origin + vec2(float(k) + 0.5, res + 2.5)) / fa_atlas_size(), 0.0).xyz;\n    if (fa_mesh_fs_params[41].y > 0.5)\n    {\n        v = ((v * 255.0) - vec3(128.0)) * 0.03149606287479400634765625;\n    }\n    return v;\n}\n\nvec3 fa_sh_eval(vec3 c[9], vec3 n)\n{\n    vec3 _3653 = max((((c[0] * 0.2820948064327239990234375) + (((c[1] * (0.3257350027561187744140625 * n.y)) + (c[2] * (0.3257350027561187744140625 * n.z))) + (c[3] * (0.3257350027561187744140625 * n.x)))) + (((c[4] * ((0.2731371223926544189453125 * n.x) * n.y)) + (c[5] * ((0.2731371223926544189453125 * n.y) * n.z))) + (c[6] * (0.078847892582416534423828125 * (((3.0 * n.z) * n.z) - 1.0))))) + ((c[7] * ((0.2731371223926544189453125 * n.x) * n.z)) + (c[8] * (0.13656856119632720947265625 * ((n.x * n.x) - (n.y * n.y))))), vec3(0.0));\n    return _3653;\n}\n\nvec3 fa_ambient_light(vec3 n)\n{\n    float _4265 = (1.0 - fa_mesh_fs_params[42].w) - fa_mesh_fs_params[47].w;\n    vec3 amb = vec3(0.0);\n    bool _4270 = fa_mesh_fs_params[11].w > 0.5;\n    vec3 c[9];\n    for (int k = 0; k < 9; k++)\n    {\n        c[k] = vec3(0.0);\n    }\n    if (_4265 > 0.0005000000237487256526947021484375)\n    {\n        if (_4270)\n        {\n            for (int k_1 = 0; k_1 < 9; k_1++)\n            {\n                vec2 param = fa_mesh_fs_params[41].zw;\n                float param_1 = 128.0;\n                int param_2 = k_1;\n                c[k_1] = fa_probe_sh_coef(param, param_1, param_2) * _4265;\n            }\n        }\n        else\n        {\n            amb = fa_mesh_fs_params[1].xyz * _4265;\n        }\n    }\n    bool _4321 = fa_mesh_fs_params[42].w > 0.0;\n    if (_4321)\n    {\n        for (int k_2 = 0; k_2 < 9; k_2++)\n        {\n            vec2 param_3 = fa_mesh_fs_params[42].xy;\n            float param_4 = fa_mesh_fs_params[42].z;\n            int param_5 = k_2;\n            c[k_2] += (fa_probe_sh_coef(param_3, param_4, param_5) * fa_mesh_fs_params[42].w);\n        }\n    }\n    bool _4352 = fa_mesh_fs_params[47].w > 0.0;\n    if (_4352)\n    {\n        for (int k_3 = 0; k_3 < 9; k_3++)\n        {\n            vec2 param_6 = fa_mesh_fs_params[47].xy;\n            float param_7 = fa_mesh_fs_params[47].z;\n            int param_8 = k_3;\n            c[k_3] += (fa_probe_sh_coef(param_6, param_7, param_8) * fa_mesh_fs_params[47].w);\n        }\n    }\n    if ((_4270 || _4321) || _4352)\n    {\n        vec3 param_9[9] = c;\n        vec3 param_10 = n;\n        amb += fa_sh_eval(param_9, param_10);\n    }\n    return amb;\n}\n\nvec4 fa_gi_fetch(vec2 texel)\n{\n    return textureLod(fa_probe_atlas_fa_env_smp, texel / fa_atlas_size(), 0.0);\n}\n\nvec2 fa_oct_encode(vec3 d)\n{\n    vec3 _3673 = d / vec3(max((abs(d.x) + abs(d.y)) + abs(d.z), 9.9999999600419720025001879548654e-13));\n    float _3676 = _3673.x;\n    float _3678 = _3673.z;\n    vec2 e = vec2(_3676, _3678);\n    if (_3673.y < 0.0)\n    {\n        e = vec2((1.0 - abs(_3678)) * ((_3676 < 0.0) ? (-1.0) : 1.0), (1.0 - abs(_3676)) * ((_3678 < 0.0) ? (-1.0) : 1.0));\n    }\n    return e;\n}\n\nvec3 fa_gi_grid(int rec, vec3 n, vec3 v, out float cover)\n{\n    cover = 0.0;\n    int param = rec;\n    vec4 _7661 = fa_light_texel(param);\n    int param_1 = rec + 1;\n    vec4 _7666 = fa_light_texel(param_1);\n    int param_2 = rec + 2;\n    vec4 _7671 = fa_light_texel(param_2);\n    int param_3 = rec + 3;\n    vec4 _7676 = fa_light_texel(param_3);\n    bool _7679 = _7676.z < 0.5;\n    bool _7687;\n    if (!_7679)\n    {\n        _7687 = fa_atlas_size().y < 1155.0;\n    }\n    else\n    {\n        _7687 = _7679;\n    }\n    if (_7687)\n    {\n        return vec3(0.0);\n    }\n    float _7694 = max(_7661.w, 9.9999997473787516355514526367188e-05);\n    vec3 _7697 = _7666.xyz;\n    vec3 _7701 = _7661.xyz;\n    vec3 _7705 = (fa_world_pos - _7701) / vec3(_7694);\n    vec3 _7714 = min(_7705 + vec3(0.5), (_7697 - vec3(0.5)) - _7705);\n    float _7723 = min(_7714.x, min(_7714.y, _7714.z));\n    if (!(_7723 > 0.0))\n    {\n        return vec3(0.0);\n    }\n    vec3 _7738 = _7697 - vec3(1.0);\n    vec3 _7739 = clamp(_7705, vec3(0.0), _7738);\n    vec3 _7747 = min(floor(_7739), max(_7697 - vec3(2.0), vec3(0.0)));\n    vec3 _7751 = _7739 - _7747;\n    vec3 _7762 = fa_world_pos + (((n * 0.800000011920928955078125) + (v * 0.20000000298023223876953125)) * (0.20000000298023223876953125 * _7694));\n    int _7767 = int(_7671.y + 0.5);\n    float _7772 = 0.3257350027561187744140625 * n.y;\n    float _7776 = 0.3257350027561187744140625 * n.z;\n    float _7780 = 0.3257350027561187744140625 * n.x;\n    float _7787 = (0.2731371223926544189453125 * n.x) * n.y;\n    float _7794 = (0.2731371223926544189453125 * n.y) * n.z;\n    float _7803 = 0.078847892582416534423828125 * (((3.0 * n.z) * n.z) - 1.0);\n    float _7810 = (0.2731371223926544189453125 * n.x) * n.z;\n    float _7823 = 0.13656856119632720947265625 * ((n.x * n.x) - (n.y * n.y));\n    vec3 acc = vec3(0.0);\n    float wsum = 0.0;\n    int _7830 = 8 + int(_7676.w);\n    float _7857;\n    float _7870;\n    float _7884;\n    for (int k = 0; k < _7830; k++)\n    {\n        float _7843 = float(k & 1);\n        float _7847 = float((k >> 1) & 1);\n        float _7851 = float((k >> 2) & 1);\n        if (_7843 > 0.5)\n        {\n            _7857 = _7751.x;\n        }\n        else\n        {\n            _7857 = 1.0 - _7751.x;\n        }\n        if (_7847 > 0.5)\n        {\n            _7870 = _7751.y;\n        }\n        else\n        {\n            _7870 = 1.0 - _7751.y;\n        }\n        if (_7851 > 0.5)\n        {\n            _7884 = _7751.z;\n        }\n        else\n        {\n            _7884 = 1.0 - _7751.z;\n        }\n        float _7894 = (_7857 * _7870) * _7884;\n        if (!(_7894 > 0.0))\n        {\n            continue;\n        }\n        vec3 _7907 = min(_7747 + vec3(_7843, _7847, _7851), _7738);\n        int _7927 = int(((_7671.x + _7907.x) + (_7666.x * (_7907.y + (_7666.y * _7907.z)))) + 0.5);\n        vec2 _7942 = vec2(float(_7927 % _7767) * 10.0, 1024.0 + (float(_7927 / _7767) * 11.0));\n        vec2 param_4 = _7942 + vec2(9.5, 10.5);\n        vec4 _7950 = fa_gi_fetch(param_4);\n        bool _7953 = _7950.y < 0.5;\n        bool _7962;\n        if (!_7953)\n        {\n            _7962 = _7950.x > _7676.y;\n        }\n        else\n        {\n            _7962 = _7953;\n        }\n        if (_7962)\n        {\n            continue;\n        }\n        vec3 _7974 = _7762 - (_7701 + (_7907 * _7694));\n        float _7977 = length(_7974);\n        vec3 _7983 = _7974 / vec3(max(_7977, 9.9999997473787516355514526367188e-05));\n        float _7993 = max(9.9999997473787516355514526367188e-05, (dot(-_7983, n) + 1.0) * 0.5);\n        float w = _7894 * (_7993 * _7993);\n        vec3 param_5 = _7983;\n        vec2 param_6 = (_7942 + vec2(1.0)) + (((fa_oct_encode(param_5) * 0.5) + vec2(0.5)) * 8.0);\n        vec4 _8012 = fa_gi_fetch(param_6);\n        float _8019 = _7977 / max(_7671.z, 9.9999997473787516355514526367188e-05);\n        float _8022 = _8012.x;\n        if (_8019 > _8022)\n        {\n            float _8035 = max(_8012.y - (_8022 * _8022), 0.0);\n            float _8040 = _8019 - _8022;\n            float _8049 = _8035 / max(_8035 + (_8040 * _8040), 9.9999999600419720025001879548654e-13);\n            w *= ((_8049 * _8049) * _8049);\n        }\n        if (!(w > 0.0))\n        {\n            continue;\n        }\n        vec2 param_7 = _7942 + vec2(0.5, 10.5);\n        vec2 param_8 = _7942 + vec2(1.5, 10.5);\n        vec2 param_9 = _7942 + vec2(2.5, 10.5);\n        vec2 param_10 = _7942 + vec2(3.5, 10.5);\n        vec2 param_11 = _7942 + vec2(4.5, 10.5);\n        vec2 param_12 = _7942 + vec2(5.5, 10.5);\n        vec2 param_13 = _7942 + vec2(6.5, 10.5);\n        vec2 param_14 = _7942 + vec2(7.5, 10.5);\n        vec2 param_15 = _7942 + vec2(8.5, 10.5);\n        acc += ((((((((((fa_gi_fetch(param_7).xyz * 0.2820948064327239990234375) + (fa_gi_fetch(param_8).xyz * _7772)) + (fa_gi_fetch(param_9).xyz * _7776)) + (fa_gi_fetch(param_10).xyz * _7780)) + (fa_gi_fetch(param_11).xyz * _7787)) + (fa_gi_fetch(param_12).xyz * _7794)) + (fa_gi_fetch(param_13).xyz * _7803)) + (fa_gi_fetch(param_14).xyz * _7810)) + (fa_gi_fetch(param_15).xyz * _7823)) * w);\n        wsum += w;\n    }\n    if (!(wsum > 9.9999997473787516355514526367188e-06))\n    {\n        return vec3(0.0);\n    }\n    cover = smoothstep(0.0, 1.0, clamp(_7723 * 2.0, 0.0, 1.0)) * smoothstep(0.0, 0.0199999995529651641845703125, wsum);\n    float _8173;\n    if (fa_mesh_fs_params[52].z > 0.5)\n    {\n        _8173 = _7676.x;\n    }\n    else\n    {\n        _8173 = 1.0;\n    }\n    return max(acc / vec3(wsum), vec3(0.0)) * (_7671.w * _8173);\n}\n\nvec3 fa_gi_light(vec3 n, inout float left)\n{\n    left = 1.0;\n    vec3 acc = vec3(0.0);\n    vec3 _8197 = normalize(fa_mesh_fs_params[0].xyz - fa_world_pos);\n    int _8202 = int(fa_mesh_fs_params[52].x + 0.5);\n    int _8207 = int(fa_mesh_fs_params[52].y + 0.5);\n    float param_3;\n    for (int k = 0; (k < _8207) && (k < 8); k++)\n    {\n        int param = _8202 + (4 * k);\n        vec3 param_1 = n;\n        vec3 param_2 = _8197;\n        vec3 _8232 = fa_gi_grid(param, param_1, param_2, param_3);\n        float _8237 = param_3 * left;\n        acc += (_8232 * _8237);\n        left -= _8237;\n        if (left < 0.001000000047497451305389404296875)\n        {\n            left = 0.0;\n            break;\n        }\n    }\n    return acc;\n}\n\nvec3 fa_realtime_or_ambient(vec3 n)\n{\n    vec3 gi = vec3(0.0);\n    float left = 1.0;\n    if (fa_mesh_fs_params[52].y > 0.5)\n    {\n        vec3 param = n;\n        float param_1;\n        vec3 _8266 = fa_gi_light(param, param_1);\n        left = param_1;\n        gi = _8266;\n    }\n    if (left <= 0.0)\n    {\n        return gi;\n    }\n    vec3 param_2 = n;\n    return gi + (fa_ambient_light(param_2) * left);\n}\n\nvec3 fa_indirect_diffuse(vec3 n)\n{\n    if (fa_lm.z > 0.5)\n    {\n        return textureLod(fa_lightmap_fa_env_smp, fa_lm.xy, 0.0).xyz;\n    }\n    if (fa_mesh_fs_params[32].w > 0.0)\n    {\n        vec3 c[9];\n        for (int k = 0; k < 9; k++)\n        {\n            c[k] = fa_mesh_fs_params[k * 1 + 32].xyz;\n        }\n        vec3 param = n;\n        vec3 param_1[9] = c;\n        vec3 param_2 = n;\n        return mix(fa_ambient_light(param), fa_sh_eval(param_1, param_2), vec3(clamp(fa_mesh_fs_params[32].w, 0.0, 1.0)));\n    }\n    vec3 param_3 = n;\n    return fa_realtime_or_ambient(param_3);\n}\n\nint fa_cluster_index(int slot, int n)\n{\n    int param = (int(fa_mesh_fs_params[19].x) + int(fa_mesh_fs_params[19].w)) + ((slot + n) >> 2);\n    vec4 t = fa_light_texel(param);\n    return int(t[(slot + n) & 3]);\n}\n\nint fa_cl_light(int n)\n{\n    if (n < fa_cl_ndir)\n    {\n        return n;\n    }\n    int param = fa_cl_slot;\n    int param_1 = n - fa_cl_ndir;\n    return fa_cluster_index(param, param_1);\n}\n\nint fa_light_base(int li)\n{\n    return li * ((fa_mesh_fs_params[1].w > 4.5) ? 8 : 4);\n}\n\nbool fa_light_baked(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 3;\n    return fa_light_texel(param_1).w > 0.5;\n}\n\nfloat fa_baked_keep(int li)\n{\n    float _6163;\n    if (fa_lm.z > 0.5)\n    {\n        _6163 = 0.0;\n    }\n    else\n    {\n        _6163 = 1.0 - clamp(fa_mesh_fs_params[32].w, 0.0, 1.0);\n    }\n    bool _6174 = _6163 < 1.0;\n    bool _6180;\n    if (_6174)\n    {\n        int param = li;\n        _6180 = fa_light_baked(param);\n    }\n    else\n    {\n        _6180 = _6174;\n    }\n    return _6180 ? _6163 : 1.0;\n}\n\nfloat fa_light_type(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 1;\n    return fa_light_texel(param_1).w;\n}\n\nvec4 fa_atlas_fetch(vec2 texel)\n{\n    return textureLod(fa_light_atlas_fa_env_smp, texel / vec2(textureSize(fa_light_atlas_fa_env_smp, 0)), 0.0);\n}\n\nvec3 fa_cookie_sample(vec2 tile_origin, vec2 uv)\n{\n    vec2 param = (tile_origin + vec2(1.0)) + (clamp(uv, vec2(0.0), vec2(1.0)) * 254.0);\n    return fa_atlas_fetch(param).xyz;\n}\n\nvec3 fa_area_point(vec3 c, vec3 axis, vec3 ru, vec3 uu, float hx, float hy, float shape, vec3 p, vec3 r)\n{\n    bool _877 = dot(r, r) > 0.5;\n    if (shape > 1.5)\n    {\n        vec3 _890 = (c - (ru * hx)) - p;\n        vec3 _896 = ru * (2.0 * hx);\n        float _902 = max(dot(_896, _896), 9.9999999392252902907785028219223e-09);\n        float _906 = dot(_890, _896);\n        float t = clamp((-_906) / _902, 0.0, 1.0);\n        if (_877)\n        {\n            float _921 = dot(r, _896);\n            float _927 = _902 - (_921 * _921);\n            if (abs(_927) > (9.9999997473787516355514526367188e-06 * _902))\n            {\n                t = clamp(((dot(r, _890) * _921) - _906) / _927, 0.0, 1.0);\n            }\n        }\n        return (p + _890) + (_896 * t);\n    }\n    vec3 q = p;\n    float _959 = dot(r, axis);\n    bool _967;\n    if (_877)\n    {\n        _967 = abs(_959) > 9.9999997473787516355514526367188e-05;\n    }\n    else\n    {\n        _967 = _877;\n    }\n    if (_967)\n    {\n        float _977 = dot(c - p, axis) / _959;\n        if (_977 > 0.0)\n        {\n            q = p + (r * _977);\n        }\n    }\n    vec3 _990 = q - c;\n    vec2 xy = vec2(dot(_990, ru), dot(_990, uu));\n    if (shape > 0.5)\n    {\n        float _1005 = length(xy);\n        if (_1005 > hx)\n        {\n            xy *= (hx / _1005);\n        }\n    }\n    else\n    {\n        xy = clamp(xy, vec2(-hx, -hy), vec2(hx, hy));\n    }\n    return (c + (ru * xy.x)) + (uu * xy.y);\n}\n\nint fa_cube_face(vec3 d)\n{\n    vec3 _644 = abs(d);\n    float _646 = _644.x;\n    float _648 = _644.y;\n    bool _649 = _646 >= _648;\n    bool _657;\n    if (_649)\n    {\n        _657 = _646 >= _644.z;\n    }\n    else\n    {\n        _657 = _649;\n    }\n    int _658;\n    if (_657)\n    {\n        _658 = (d.x > 0.0) ? 0 : 1;\n    }\n    else\n    {\n        int _672;\n        if (_648 >= _644.z)\n        {\n            _672 = (d.y > 0.0) ? 2 : 3;\n        }\n        else\n        {\n            _672 = (d.z > 0.0) ? 4 : 5;\n        }\n        _658 = _672;\n    }\n    return _658;\n}\n\nvoid fa_cube_face_basis(int f, out vec3 fwd, out vec3 up)\n{\n    if (f == 0)\n    {\n        fwd = vec3(1.0, 0.0, 0.0);\n        up = vec3(0.0, 1.0, 0.0);\n    }\n    else\n    {\n        if (f == 1)\n        {\n            fwd = vec3(-1.0, 0.0, 0.0);\n            up = vec3(0.0, 1.0, 0.0);\n        }\n        else\n        {\n            if (f == 2)\n            {\n                fwd = vec3(0.0, 1.0, 0.0);\n                up = vec3(0.0, 0.0, 1.0);\n            }\n            else\n            {\n                if (f == 3)\n                {\n                    fwd = vec3(0.0, -1.0, 0.0);\n                    up = vec3(0.0, 0.0, -1.0);\n                }\n                else\n                {\n                    if (f == 4)\n                    {\n                        fwd = vec3(0.0, 0.0, 1.0);\n                        up = vec3(0.0, 1.0, 0.0);\n                    }\n                    else\n                    {\n                        fwd = vec3(0.0, 0.0, -1.0);\n                        up = vec3(0.0, 1.0, 0.0);\n                    }\n                }\n            }\n        }\n    }\n}\n\nfloat fa_ies_sample(vec2 tile_origin, vec3 d, vec3 axis, vec3 right, vec3 up)\n{\n    float _797 = dot(d, right);\n    float _801 = dot(d, up);\n    float _812;\n    if (((_797 * _797) + (_801 * _801)) > 1.0000000133514319600180897396058e-10)\n    {\n        _812 = atan(_801, _797) * 0.15915493667125701904296875;\n    }\n    else\n    {\n        _812 = 0.0;\n    }\n    vec2 param = tile_origin + vec2(1.0 + ((_812 - floor(_812)) * 64.0), 1.0 + (acos(clamp(dot(d, axis), -1.0, 1.0)) * 10.18591594696044921875));\n    return fa_atlas_fetch(param).x;\n}\n\nLightSample fa_light_sample_n(int li, vec3 world_pos, vec3 n)\n{\n    int param = li;\n    int _1043 = fa_light_base(param);\n    bool _1047 = fa_mesh_fs_params[1].w > 4.5;\n    int param_1 = _1043;\n    vec4 _1051 = fa_light_texel(param_1);\n    int param_2 = _1043 + 1;\n    vec4 _1056 = fa_light_texel(param_2);\n    float _1059 = _1056.w;\n    float atten = 1.0;\n    float dist = 0.0;\n    fa_light_tint = vec3(1.0);\n    bool _1071 = _1047 && (_1059 > 2.5);\n    fa_light_is_area = _1071;\n    bool _1073 = _1059 < 0.5;\n    vec3 l;\n    if (_1073)\n    {\n        l = normalize(_1051.xyz);\n        if (_1047)\n        {\n            int param_3 = _1043 + 6;\n            vec4 _1087 = fa_light_texel(param_3);\n            if (_1087.z > 0.5)\n            {\n                int param_4 = _1043 + 4;\n                vec4 _1097 = fa_light_texel(param_4);\n                int param_5 = _1043 + 5;\n                vec4 _1102 = fa_light_texel(param_5);\n                vec2 param_6 = _1087.xy;\n                vec2 param_7 = fract(vec2(dot(world_pos, _1097.xyz) * _1097.w, (-dot(world_pos, _1102.xyz)) * _1102.w) + vec2(0.5));\n                fa_light_tint = fa_cookie_sample(param_6, param_7);\n            }\n        }\n    }\n    else\n    {\n        vec3 _1132 = _1051.xyz;\n        vec3 _1134 = _1132 - world_pos;\n        vec3 to_light = _1134;\n        float _1137 = length(_1134);\n        float reach = _1137;\n        bool front = true;\n        if (_1071)\n        {\n            int param_8 = _1043 + 7;\n            reach = max(_1137 - fa_light_texel(param_8).w, 0.0);\n            int param_9 = _1043 + 4;\n            vec4 _1161 = fa_light_texel(param_9);\n            int param_10 = _1043 + 5;\n            vec4 _1166 = fa_light_texel(param_10);\n            int param_11 = _1043 + 6;\n            vec4 _1171 = fa_light_texel(param_11);\n            float _1172 = _1171.w;\n            int param_12 = _1043 + 2;\n            vec3 _1179 = normalize(fa_light_texel(param_12).xyz);\n            bool _1181 = _1172 > 1.5;\n            bool _1189;\n            if (!_1181)\n            {\n                _1189 = dot(_1179, to_light) < 0.0;\n            }\n            else\n            {\n                _1189 = _1181;\n            }\n            front = _1189;\n            vec3 r = vec3(0.0);\n            vec3 _1198 = fa_mesh_fs_params[0].xyz - world_pos;\n            bool _1202 = dot(n, n) > 0.5;\n            bool _1210;\n            if (_1202)\n            {\n                _1210 = dot(_1198, _1198) > 9.9999999600419720025001879548654e-13;\n            }\n            else\n            {\n                _1210 = _1202;\n            }\n            if (_1210)\n            {\n                r = reflect(-normalize(_1198), normalize(n));\n            }\n            vec3 param_13 = _1132;\n            vec3 param_14 = _1179;\n            vec3 param_15 = _1161.xyz;\n            vec3 param_16 = _1166.xyz;\n            float param_17 = _1161.w;\n            float param_18 = _1166.w;\n            float param_19 = _1172;\n            vec3 param_20 = world_pos;\n            vec3 param_21 = r;\n            to_light = fa_area_point(param_13, param_14, param_15, param_16, param_17, param_18, param_19, param_20, param_21) - world_pos;\n        }\n        float _1246 = length(to_light);\n        dist = _1246;\n        l = to_light / vec3(max(_1246, 9.9999997473787516355514526367188e-05));\n        float _1260 = reach / max(_1051.w, 0.001000000047497451305389404296875);\n        float _1266 = clamp(1.0 - (_1260 * _1260), 0.0, 1.0);\n        float _1268;\n        if (front)\n        {\n            _1268 = _1266 * _1266;\n        }\n        else\n        {\n            _1268 = 0.0;\n        }\n        atten = _1268;\n        bool _1279 = _1059 < 2.5;\n        if ((_1059 > 1.5) && _1279)\n        {\n            int param_22 = _1043 + 2;\n            vec4 _1287 = fa_light_texel(param_22);\n            float _1297 = _1287.w;\n            int param_23 = _1043 + 3;\n            vec4 _1302 = fa_light_texel(param_23);\n            float _1303 = _1302.x;\n            float cos_inner = _1303;\n            if (_1303 > 1.5)\n            {\n                cos_inner = mix(_1297, 1.0, 0.25);\n            }\n            atten *= smoothstep(_1297, cos_inner, dot(-l, normalize(_1287.xyz)));\n        }\n        if (_1047 && (_1059 < 1.5))\n        {\n            int param_24 = _1043 + 6;\n            vec4 _1327 = fa_light_texel(param_24);\n            if (_1327.z > 0.5)\n            {\n                vec3 _1335 = -to_light;\n                int param_25 = _1043 + 4;\n                int param_26 = _1043 + 5;\n                vec3 _1349 = fa_light_texel(param_25).xyz;\n                vec3 _1353 = fa_light_texel(param_26).xyz;\n                vec3 _1362 = vec3(dot(_1335, _1349), dot(_1335, _1353), dot(_1335, cross(_1349, _1353)));\n                vec3 param_27 = _1362;\n                int _1366 = fa_cube_face(param_27);\n                int param_28 = _1366;\n                vec3 param_29;\n                vec3 param_30;\n                fa_cube_face_basis(param_28, param_29, param_30);\n                vec2 _1393 = vec2(dot(_1362, cross(param_29, param_30)), dot(_1362, param_30)) / vec2(max(dot(_1362, param_29), 9.9999997473787516355514526367188e-05));\n                int _1397 = _1366 / 3;\n                vec2 param_31 = _1327.xy + (vec2(float(_1366 - (_1397 * 3)), float(_1397)) * 256.0);\n                vec2 param_32 = vec2(0.5 + (0.5 * _1393.x), 0.5 - (0.5 * _1393.y));\n                fa_light_tint = fa_cookie_sample(param_31, param_32);\n            }\n            int param_33 = _1043 + 7;\n            vec4 _1427 = fa_light_texel(param_33);\n            if (_1427.z > 0.5)\n            {\n                int param_34 = _1043 + 2;\n                int param_35 = _1043 + 4;\n                int param_36 = _1043 + 5;\n                vec2 param_37 = _1427.xy;\n                vec3 param_38 = -l;\n                vec3 param_39 = normalize(fa_light_texel(param_34).xyz);\n                vec3 param_40 = fa_light_texel(param_35).xyz;\n                vec3 param_41 = fa_light_texel(param_36).xyz;\n                atten *= fa_ies_sample(param_37, param_38, param_39, param_40, param_41);\n            }\n        }\n        else\n        {\n            if (_1047 && _1279)\n            {\n                int param_42 = _1043 + 6;\n                vec4 _1474 = fa_light_texel(param_42);\n                int param_43 = _1043 + 7;\n                vec4 _1479 = fa_light_texel(param_43);\n                bool _1482 = _1474.z > 0.5;\n                bool _1489;\n                if (!_1482)\n                {\n                    _1489 = _1479.z > 0.5;\n                }\n                else\n                {\n                    _1489 = _1482;\n                }\n                if (_1489)\n                {\n                    int param_44 = _1043 + 2;\n                    vec4 _1496 = fa_light_texel(param_44);\n                    vec3 _1500 = normalize(_1496.xyz);\n                    int param_45 = _1043 + 4;\n                    vec4 _1505 = fa_light_texel(param_45);\n                    int param_46 = _1043 + 5;\n                    vec4 _1510 = fa_light_texel(param_46);\n                    if (_1482)\n                    {\n                        vec3 _1518 = -to_light;\n                        float _1525 = _1496.w;\n                        float _1541 = 0.5 / max(dot(_1518, _1500) * (sqrt(max(1.0 - (_1525 * _1525), 0.0)) / max(_1525, 0.001000000047497451305389404296875)), 9.9999997473787516355514526367188e-05);\n                        vec2 param_47 = _1474.xy;\n                        vec2 param_48 = vec2(0.5 + (dot(_1518, _1505.xyz) * _1541), 0.5 - (dot(_1518, _1510.xyz) * _1541));\n                        fa_light_tint = fa_cookie_sample(param_47, param_48);\n                    }\n                    if (_1479.z > 0.5)\n                    {\n                        vec2 param_49 = _1479.xy;\n                        vec3 param_50 = -l;\n                        vec3 param_51 = _1500;\n                        vec3 param_52 = _1505.xyz;\n                        vec3 param_53 = _1510.xyz;\n                        atten *= fa_ies_sample(param_49, param_50, param_51, param_52, param_53);\n                    }\n                }\n            }\n        }\n    }\n    vec3 _9360 = _1056.xyz * atten;\n    if (_1047)\n    {\n        _9360 *= fa_light_tint;\n    }\n    int _1610;\n    if (_1073)\n    {\n        _1610 = 0;\n    }\n    else\n    {\n        _1610 = ((_1059 > 1.5) && (_1059 < 2.5)) ? 2 : 1;\n    }\n    return LightSample(l, _9360, atten, 1.0, dist, _1610);\n}\n\nfloat fa_shadow_split_at(int i)\n{\n    float _2336;\n    if (i == 0)\n    {\n        _2336 = fa_shadows[24].x;\n    }\n    else\n    {\n        float _2352;\n        if (i == 1)\n        {\n            _2352 = fa_shadows[24].y;\n        }\n        else\n        {\n            float _2360;\n            if (i == 2)\n            {\n                _2360 = fa_shadows[24].z;\n            }\n            else\n            {\n                _2360 = fa_shadows[24].w;\n            }\n            _2352 = _2360;\n        }\n        _2336 = _2352;\n    }\n    return _2336;\n}\n\nfloat fa_shadow_depth(inout vec2 uv, vec4 rect)\n{\n    uv = clamp(uv, rect.xy, rect.zw);\n    return textureLod(fa_shadow_tex_fa_shadow_smp, uv, 0.0).x;\n}\n\nfloat fa_shadow_fetch(vec2 uv, vec4 rect, vec3 conv)\n{\n    vec2 param = uv;\n    vec4 param_1 = rect;\n    float _2393 = fa_shadow_depth(param, param_1);\n    float _2397;\n    if (conv.x < 0.5)\n    {\n        _2397 = _2393;\n    }\n    else\n    {\n        _2397 = (conv.y * conv.z) / (conv.z - (_2393 * (conv.z - conv.y)));\n    }\n    return _2397;\n}\n\nfloat fa_shadow_noise()\n{\n    return fract(52.98291778564453125 * fract(dot(gl_FragCoord.xy, vec2(0.067110560834407806396484375, 0.005837149918079376220703125))));\n}\n\nvec2 fa_shadow_vogel_turn(vec2 d)\n{\n    return vec2((d.x * (-0.737368881702423095703125)) - (d.y * 0.675490319728851318359375), (d.y * (-0.737368881702423095703125)) + (d.x * 0.675490319728851318359375));\n}\n\nfloat fa_shadow_filter(vec2 uv, vec4 rect, float zr, float texel_m, float unit, float reach, float plane, vec3 conv, int mode, float k)\n{\n    if (mode == 1)\n    {\n        vec2 param = uv;\n        vec4 param_1 = rect;\n        vec3 param_2 = conv;\n        return float(zr <= fa_shadow_fetch(param, param_1, param_2));\n    }\n    float _2443 = fa_shadow_noise() * 6.283185482025146484375;\n    vec2 _2449 = vec2(cos(_2443), sin(_2443));\n    vec2 dir = _2449;\n    float radius = 1.5;\n    if (mode == 2)\n    {\n        float _2458;\n        if (k < 0.0)\n        {\n            _2458 = (-k) / max(zr, 0.100000001490116119384765625);\n        }\n        else\n        {\n            _2458 = k;\n        }\n        float _2477 = clamp((_2458 * reach) / texel_m, 3.0, 12.0);\n        float sum = 0.0;\n        float cnt = 0.0;\n        for (int i = 0; i < 16; i++)\n        {\n            float _2496 = sqrt((float(i) + 0.5) * 0.0625) * _2477;\n            vec2 param_3 = uv + (dir * (fa_shadows[26].zw * _2496));\n            vec4 param_4 = rect;\n            vec3 param_5 = conv;\n            float _2510 = fa_shadow_fetch(param_3, param_4, param_5);\n            if (_2510 < (zr - (_2496 * plane)))\n            {\n                sum += _2510;\n                cnt += 1.0;\n            }\n            vec2 param_6 = dir;\n            dir = fa_shadow_vogel_turn(param_6);\n        }\n        if (cnt < 0.5)\n        {\n            return 1.0;\n        }\n        float _2538 = sum / cnt;\n        float _2548;\n        if (k < 0.0)\n        {\n            _2548 = (-k) / max(_2538, 0.0500000007450580596923828125);\n        }\n        else\n        {\n            _2548 = k;\n        }\n        radius = clamp(((max(zr - _2538, 0.0) * unit) * _2548) / texel_m, 1.5, 16.0);\n        dir = _2449;\n    }\n    float lit = 0.0;\n    int _2574 = (mode == 2) ? 24 : 16;\n    for (int i_1 = 0; i_1 < _2574; i_1++)\n    {\n        float _2593 = sqrt((float(i_1) + 0.5) / float(_2574)) * radius;\n        vec2 param_7 = uv + (dir * (fa_shadows[26].zw * _2593));\n        vec4 param_8 = rect;\n        vec3 param_9 = conv;\n        lit += float((zr - (_2593 * plane)) <= fa_shadow_fetch(param_7, param_8, param_9));\n        vec2 param_10 = dir;\n        dir = fa_shadow_vogel_turn(param_10);\n    }\n    return lit / float(_2574);\n}\n\nfloat fa_shadow_cascade(int ci, vec3 world, vec3 n, vec3 l)\n{\n    float _2639 = max(fa_shadows[ci * 1 + 20].y, 0.001000000047497451305389404296875);\n    float _2644 = clamp(dot(n, l), 0.0, 1.0);\n    float _2650 = sqrt(1.0 - (_2644 * _2644));\n    float _2658 = min(_2650 / max(_2644, 0.20000000298023223876953125), 4.0);\n    float _2663;\n    if (fa_shadows[26].y > 0.0)\n    {\n        _2663 = fa_shadows[26].y;\n    }\n    else\n    {\n        _2663 = 1.5 * fa_shadows[ci * 1 + 20].x;\n    }\n    vec4 _2688 = mat4(fa_shadows[ci * 4 + 0], fa_shadows[ci * 4 + 1], fa_shadows[ci * 4 + 2], fa_shadows[ci * 4 + 3]) * vec4(world + (n * (_2663 * _2650)), 1.0);\n    float _2695 = _2688.x;\n    bool _2698 = _2695 < fa_shadows[ci * 1 + 16].x;\n    bool _2707;\n    if (!_2698)\n    {\n        _2707 = _2695 > fa_shadows[ci * 1 + 16].z;\n    }\n    else\n    {\n        _2707 = _2698;\n    }\n    bool _2716;\n    if (!_2707)\n    {\n        _2716 = _2688.y < fa_shadows[ci * 1 + 16].y;\n    }\n    else\n    {\n        _2716 = _2707;\n    }\n    bool _2725;\n    if (!_2716)\n    {\n        _2725 = _2688.y > fa_shadows[ci * 1 + 16].w;\n    }\n    else\n    {\n        _2725 = _2716;\n    }\n    bool _2732;\n    if (!_2725)\n    {\n        _2732 = _2688.z > 1.0;\n    }\n    else\n    {\n        _2732 = _2725;\n    }\n    if (_2732)\n    {\n        return -1.0;\n    }\n    float _2740;\n    if (fa_shadows[26].x > 0.0)\n    {\n        _2740 = fa_shadows[26].x;\n    }\n    else\n    {\n        _2740 = 1.5 * fa_shadows[ci * 1 + 20].x;\n    }\n    vec2 param = _2688.xy;\n    vec4 param_1 = fa_shadows[ci * 1 + 16];\n    float param_2 = _2688.z - ((_2740 * (1.0 + (0.5 * _2658))) / _2639);\n    float param_3 = fa_shadows[ci * 1 + 20].x;\n    float param_4 = _2639;\n    float param_5 = _2639 * 0.25;\n    float param_6 = ((fa_shadows[ci * 1 + 20].x * min(_2658, 3.0)) * 0.5) / _2639;\n    vec3 param_7 = vec3(0.0);\n    int param_8 = int(fa_shadows[25].z + 0.5);\n    float param_9 = fa_shadows[25].w;\n    return fa_shadow_filter(param, param_1, param_2, param_3, param_4, param_5, param_6, param_7, param_8, param_9);\n}\n\nfloat fa_shadow_sun(vec3 world, vec3 n, vec3 l)\n{\n    if (fa_mesh_fs_params[5].z < 0.5)\n    {\n        return 1.0;\n    }\n    int _3118 = int(fa_shadows[25].x + 0.5);\n    if (_3118 < 1)\n    {\n        return 1.0;\n    }\n    float _3133 = dot(world - fa_shadows[27].xyz, fa_shadows[28].xyz);\n    int param = _3118 - 1;\n    if (_3133 > fa_shadow_split_at(param))\n    {\n        return 1.0;\n    }\n    int ci = 0;\n    bool _3145 = _3118 > 1;\n    bool _3152;\n    if (_3145)\n    {\n        _3152 = _3133 > fa_shadows[24].x;\n    }\n    else\n    {\n        _3152 = _3145;\n    }\n    if (_3152)\n    {\n        ci = 1;\n    }\n    bool _3156 = _3118 > 2;\n    bool _3163;\n    if (_3156)\n    {\n        _3163 = _3133 > fa_shadows[24].y;\n    }\n    else\n    {\n        _3163 = _3156;\n    }\n    if (_3163)\n    {\n        ci = 2;\n    }\n    bool _3167 = _3118 > 3;\n    bool _3174;\n    if (_3167)\n    {\n        _3174 = _3133 > fa_shadows[24].z;\n    }\n    else\n    {\n        _3174 = _3167;\n    }\n    if (_3174)\n    {\n        ci = 3;\n    }\n    float s = -1.0;\n    float s2 = -1.0;\n    float t = 0.0;\n    int _3185 = min(_3118, 4);\n    float _3226;\n    for (int c = ci; c < _3185; c++)\n    {\n        int param_1 = c;\n        vec3 param_2 = world;\n        vec3 param_3 = n;\n        vec3 param_4 = l;\n        float _3205 = fa_shadow_cascade(param_1, param_2, param_3, param_4);\n        if (s >= 0.0)\n        {\n            s2 = _3205;\n            break;\n        }\n        if (_3205 < 0.0)\n        {\n            continue;\n        }\n        s = _3205;\n        ci = c;\n        if (fa_shadows[25].y > 0.0)\n        {\n            if (ci > 0)\n            {\n                int param_5 = ci - 1;\n                _3226 = fa_shadow_split_at(param_5);\n            }\n            else\n            {\n                _3226 = fa_shadows[28].w;\n            }\n            int param_6 = ci;\n            float _3245 = fa_shadows[25].y * max(fa_shadow_split_at(param_6) - _3226, 9.9999997473787516355514526367188e-05);\n            int param_7 = ci;\n            t = clamp((_3133 - (fa_shadow_split_at(param_7) - _3245)) / _3245, 0.0, 1.0);\n        }\n        if (t <= 0.0)\n        {\n            break;\n        }\n    }\n    if (s < 0.0)\n    {\n        return 1.0;\n    }\n    if (t > 0.0)\n    {\n        float _3277;\n        if ((ci + 1) < _3118)\n        {\n            _3277 = (s2 < 0.0) ? s : s2;\n        }\n        else\n        {\n            _3277 = 1.0;\n        }\n        s = mix(s, _3277, t);\n    }\n    return s;\n}\n\nfloat fa_shadow_factor(vec3 n, vec3 l)\n{\n    bool _3382 = fa_mesh_fs_params[25].y > 0.5;\n    bool _3388;\n    if (_3382)\n    {\n        _3388 = fa_mesh_fs_params[5].z > 0.5;\n    }\n    else\n    {\n        _3388 = _3382;\n    }\n    if (_3388)\n    {\n        float _3402 = dot(fa_mesh_fs_params[29].xyz, fa_world_pos) + fa_mesh_fs_params[29].w;\n        float _3405 = fwidth(_3402);\n        vec4 _3415 = vec4(fa_world_pos, 1.0);\n        float _3421 = dot(fa_mesh_fs_params[28], _3415);\n        if (_3421 > 9.9999997473787516355514526367188e-05)\n        {\n            vec2 _3440 = vec2(dot(fa_mesh_fs_params[26], _3415), dot(fa_mesh_fs_params[27], _3415)) / vec2(_3421);\n            float _3445 = (_3440.x * 0.5) + 0.5;\n            float _3449;\n            if (fa_mesh_fs_params[24].y > 0.5)\n            {\n                _3449 = (_3440.y * 0.5) + 0.5;\n            }\n            else\n            {\n                _3449 = 0.5 - (_3440.y * 0.5);\n            }\n            bool _3465 = _3445 >= 0.0;\n            bool _3471;\n            if (_3465)\n            {\n                _3471 = _3445 < 1.0;\n            }\n            else\n            {\n                _3471 = _3465;\n            }\n            bool _3477;\n            if (_3471)\n            {\n                _3477 = _3449 >= 0.0;\n            }\n            else\n            {\n                _3477 = _3471;\n            }\n            bool _3483;\n            if (_3477)\n            {\n                _3483 = _3449 < 1.0;\n            }\n            else\n            {\n                _3483 = _3477;\n            }\n            if (_3483)\n            {\n                vec4 _3509 = texelFetch(fa_screen_tex_fa_shadow_smp, clamp(ivec2(vec2(_3445, _3449) * fa_mesh_fs_params[24].zw), ivec2(0), ivec2(fa_mesh_fs_params[24].zw) - ivec2(1)), 0);\n                bool _3512 = _3509.w > 0.5;\n                bool _3528;\n                if (_3512)\n                {\n                    _3528 = abs(_3402 - _3509.x) <= (((0.00200000009499490261077880859375 * _3402) + 0.00999999977648258209228515625) + min(1.5 * _3405, 0.100000001490116119384765625 * _3402));\n                }\n                else\n                {\n                    _3528 = _3512;\n                }\n                if (_3528)\n                {\n                    float _3534;\n                    if (fa_mesh_fs_params[25].z > 0.5)\n                    {\n                        vec3 param = fa_world_pos;\n                        vec3 param_1 = n;\n                        vec3 param_2 = l;\n                        _3534 = min(_3509.y, fa_shadow_sun(param, param_1, param_2));\n                    }\n                    else\n                    {\n                        _3534 = _3509.y;\n                    }\n                    return _3534;\n                }\n            }\n        }\n    }\n    vec3 param_3 = fa_world_pos;\n    vec3 param_4 = n;\n    vec3 param_5 = l;\n    return fa_shadow_sun(param_3, param_4, param_5);\n}\n\nfloat fa_shadow_local(int li, vec3 lpos, vec3 world, vec3 n, vec3 l)\n{\n    bool _2798 = fa_mesh_fs_params[5].z < 0.5;\n    bool _2805;\n    if (!_2798)\n    {\n        _2805 = fa_shadows[29].x < 0.5;\n    }\n    else\n    {\n        _2805 = _2798;\n    }\n    if (_2805)\n    {\n        return 1.0;\n    }\n    int param = (int(fa_shadows[29].x + 0.5) - 1) + li;\n    vec4 _2818 = fa_light_texel(param);\n    float _2819 = _2818.x;\n    if (_2819 < 0.0)\n    {\n        return 1.0;\n    }\n    int _2828 = int(_2819 + 0.5);\n    int param_1 = _2828;\n    vec4 _2832 = fa_light_texel(param_1);\n    int param_2 = _2828 + 1;\n    vec4 _2837 = fa_light_texel(param_2);\n    float fade = 1.0;\n    float _2840 = _2832.y;\n    if (_2840 > 0.0)\n    {\n        float _2857 = 1.0 - smoothstep(0.75 * _2840, _2840, length(world - fa_shadows[27].xyz));\n        fade = _2857;\n        if (_2857 <= 0.0)\n        {\n            return 1.0;\n        }\n    }\n    int face = 0;\n    if (_2832.x > 1.5)\n    {\n        vec3 param_3 = world - lpos;\n        face = fa_cube_face(param_3);\n    }\n    int _2881 = (_2828 + 2) + (face * 6);\n    int param_4 = _2881;\n    int param_5 = _2881 + 1;\n    int param_6 = _2881 + 3;\n    vec4 _2895 = fa_light_texel(param_6);\n    int param_7 = _2881 + 4;\n    vec4 _2900 = fa_light_texel(param_7);\n    int param_8 = _2881 + 5;\n    vec4 _2905 = fa_light_texel(param_8);\n    float _2917 = _2905.x * max(dot(_2895, vec4(world, 1.0)), 0.001000000047497451305389404296875);\n    float _2922 = clamp(dot(n, l), 0.0, 1.0);\n    float _2945 = clamp(dot(n, _2895.xyz), -1.0, 1.0);\n    float _2964 = min(sqrt(1.0 - (_2945 * _2945)) / max(abs(dot(n, world - lpos)) / max(dot(_2895, vec4(world, 1.0)), 0.001000000047497451305389404296875), 0.20000000298023223876953125), 4.0);\n    float _2967 = _2837.y;\n    float _2969;\n    if (_2967 > 0.0)\n    {\n        _2969 = _2967;\n    }\n    else\n    {\n        _2969 = 1.5 * _2917;\n    }\n    vec4 _2989 = vec4(world + (n * (_2969 * sqrt(1.0 - (_2922 * _2922)))), 1.0);\n    float _2993 = dot(_2895, _2989);\n    float _2996 = _2905.y;\n    if (_2993 < _2996)\n    {\n        return 1.0;\n    }\n    vec2 _3011 = vec2(dot(fa_light_texel(param_4), _2989), dot(fa_light_texel(param_5), _2989)) / vec2(_2993);\n    float _3013 = _3011.x;\n    bool _3016 = _3013 < _2900.x;\n    bool _3025;\n    if (!_3016)\n    {\n        _3025 = _3013 > _2900.z;\n    }\n    else\n    {\n        _3025 = _3016;\n    }\n    bool _3034;\n    if (!_3025)\n    {\n        _3034 = _3011.y < _2900.y;\n    }\n    else\n    {\n        _3034 = _3025;\n    }\n    bool _3043;\n    if (!_3034)\n    {\n        _3043 = _3011.y > _2900.w;\n    }\n    else\n    {\n        _3043 = _3034;\n    }\n    if (_3043)\n    {\n        return 1.0;\n    }\n    float _3049 = _2837.x;\n    float _3051;\n    if (_3049 > 0.0)\n    {\n        _3051 = _3049;\n    }\n    else\n    {\n        _3051 = 1.5 * _2917;\n    }\n    vec2 param_9 = _3011;\n    vec4 param_10 = _2900;\n    float param_11 = _2993 - (_3051 * (1.0 + (0.5 * _2964)));\n    float param_12 = _2917;\n    float param_13 = 1.0;\n    float param_14 = _2905.z * 0.25;\n    float param_15 = (_2917 * min(_2964, 3.0)) * 0.5;\n    vec3 param_16 = vec3(1.0, _2996, _2905.z);\n    int param_17 = int(_2832.z + 0.5);\n    float param_18 = _2832.w;\n    return mix(1.0, fa_shadow_filter(param_9, param_10, param_11, param_12, param_13, param_14, param_15, param_16, param_17, param_18), fade);\n}\n\nfloat fa_contact_shadow(int li, vec3 world, vec3 gn, vec3 l, float dist)\n{\n    bool _5377 = fa_mesh_fs_params[24].x < 0.5;\n    bool _5384;\n    if (!_5377)\n    {\n        _5384 = fa_shadows[29].x < 0.5;\n    }\n    else\n    {\n        _5384 = _5377;\n    }\n    if (_5384)\n    {\n        return 1.0;\n    }\n    int param = (int(fa_shadows[29].x + 0.5) - 1) + li;\n    vec4 _5397 = fa_light_texel(param);\n    float _5398 = _5397.y;\n    float len = _5398;\n    if (_5398 <= 0.0)\n    {\n        return 1.0;\n    }\n    float _5410 = length(world - fa_mesh_fs_params[0].xyz);\n    float _5419 = 1.0 - smoothstep(0.5 * fa_mesh_fs_params[25].x, fa_mesh_fs_params[25].x, _5410);\n    if (_5419 <= 0.0)\n    {\n        return 1.0;\n    }\n    float _5425 = len;\n    float _5428 = min(_5425, 0.89999997615814208984375 * dist);\n    len = _5428;\n    float _5433 = 0.004999999888241291046142578125 + (0.0030000000260770320892333984375 * _5410);\n    float _5438 = _5433 + (0.5 * _5428);\n    vec3 _5444 = world + (gn * _5433);\n    float _5446 = fa_shadow_noise();\n    float occ = 0.0;\n    float _5507;\n    for (int k = 0; k < 12; k++)\n    {\n        float _5461 = (float(k) + _5446) * 0.083333335816860198974609375;\n        vec3 _5469 = _5444 + (l * (_5461 * len));\n        vec4 _5475 = vec4(_5469, 1.0);\n        float _5480 = dot(fa_mesh_fs_params[28], _5475);\n        if (_5480 < 9.9999997473787516355514526367188e-05)\n        {\n            break;\n        }\n        vec2 _5498 = vec2(dot(fa_mesh_fs_params[26], _5475), dot(fa_mesh_fs_params[27], _5475)) / vec2(_5480);\n        float _5502 = _5498.x * 0.5;\n        float _5503 = _5502 + 0.5;\n        if (fa_mesh_fs_params[24].y > 0.5)\n        {\n            _5507 = (_5498.y * 0.5) + 0.5;\n        }\n        else\n        {\n            _5507 = 0.5 - (_5498.y * 0.5);\n        }\n        bool _5523 = _5503 < 0.0;\n        bool _5530;\n        if (!_5523)\n        {\n            _5530 = _5503 >= 1.0;\n        }\n        else\n        {\n            _5530 = _5523;\n        }\n        bool _5537;\n        if (!_5530)\n        {\n            _5537 = _5507 < 0.0;\n        }\n        else\n        {\n            _5537 = _5530;\n        }\n        bool _5544;\n        if (!_5537)\n        {\n            _5544 = _5507 >= 1.0;\n        }\n        else\n        {\n            _5544 = _5537;\n        }\n        if (_5544)\n        {\n            break;\n        }\n        vec4 _5568 = texelFetch(fa_screen_tex_fa_shadow_smp, clamp(ivec2(vec2(_5503, _5507) * fa_mesh_fs_params[24].zw), ivec2(0), ivec2(fa_mesh_fs_params[24].zw) - ivec2(1)), 0);\n        if (_5568.w < 0.5)\n        {\n            continue;\n        }\n        float _5586 = (dot(fa_mesh_fs_params[29].xyz, _5469) + fa_mesh_fs_params[29].w) - _5568.x;\n        if ((_5586 > _5433) && (_5586 < _5438))\n        {\n            occ = max(occ, (1.0 - (_5461 * _5461)) * smoothstep(0.0, 0.0500000007450580596923828125, min(min(_5503, 0.5 - _5502), min(_5507, 1.0 - _5507))));\n        }\n    }\n    return 1.0 - (occ * _5419);\n}\n\nLightSample fa_light_shadowed(int li, vec3 world_pos, vec3 gn)\n{\n    int param = li;\n    float _6219 = fa_baked_keep(param);\n    if (_6219 <= 0.0)\n    {\n        int param_1 = li;\n        return LightSample(vec3(0.0, 1.0, 0.0), vec3(0.0), 0.0, 1.0, 0.0, int(fa_light_type(param_1) + 0.5));\n    }\n    int param_2 = li;\n    vec3 param_3 = world_pos;\n    vec3 param_4 = gn;\n    LightSample _6245 = fa_light_sample_n(param_2, param_3, param_4);\n    vec3 _9429 = _6245.color;\n    float _9430 = _6245.attenuation;\n    float _9431 = _6245.shadow;\n    bool _6248 = _6245.type == 0;\n    if (_6248 && (li == 0))\n    {\n        vec3 param_5 = gn;\n        vec3 param_6 = _6245.direction;\n        float _6259 = fa_shadow_factor(param_5, param_6);\n        _9431 = _6259;\n        _9429 *= _6259;\n    }\n    else\n    {\n        bool _6270 = _6245.type != 0;\n        bool _6276;\n        if (_6270)\n        {\n            _6276 = _9430 > 0.0;\n        }\n        else\n        {\n            _6276 = _6270;\n        }\n        if (_6276)\n        {\n            int param_7 = li;\n            int param_8 = fa_light_base(param_7);\n            int param_9 = li;\n            vec3 param_10 = fa_light_texel(param_8).xyz;\n            vec3 param_11 = world_pos;\n            vec3 param_12 = gn;\n            vec3 param_13 = _6245.direction;\n            float _6295 = fa_shadow_local(param_9, param_10, param_11, param_12, param_13);\n            _9431 = _6295;\n            _9429 *= _6295;\n        }\n    }\n    bool _6305 = fa_mesh_fs_params[24].x > 0.5;\n    bool _6311;\n    if (_6305)\n    {\n        _6311 = _9430 > 0.0;\n    }\n    else\n    {\n        _6311 = _6305;\n    }\n    if (_6311)\n    {\n        float _6318;\n        if (_6248)\n        {\n            _6318 = 1000000000.0;\n        }\n        else\n        {\n            _6318 = _6245._distance;\n        }\n        int param_14 = li;\n        vec3 param_15 = world_pos;\n        vec3 param_16 = gn;\n        vec3 param_17 = _6245.direction;\n        float param_18 = _6318;\n        float _6336 = fa_contact_shadow(param_14, param_15, param_16, param_17, param_18);\n        _9431 *= _6336;\n        _9429 *= _6336;\n    }\n    float _6349 = _9430;\n    float _6350 = _6349 * _6219;\n    _9430 = _6350;\n    vec3 _6354 = _9429;\n    vec3 _6355 = _6354 * _6219;\n    _9429 = _6355;\n    return LightSample(_6245.direction, _6355, _6350, _9431, _6245._distance, _6245.type);\n}\n\nvec3 fa_ltc_tangent(vec3 n, vec3 v)\n{\n    vec3 _6389 = v - (n * dot(v, n));\n    vec3 t = _6389;\n    float _6393 = dot(_6389, _6389);\n    float l2 = _6393;\n    if (_6393 < 1.0000000133514319600180897396058e-10)\n    {\n        vec3 _6403;\n        if (abs(n.z) < 0.999000012874603271484375)\n        {\n            _6403 = cross(n, vec3(0.0, 0.0, 1.0));\n        }\n        else\n        {\n            _6403 = cross(n, vec3(1.0, 0.0, 0.0));\n        }\n        t = _6403;\n        l2 = dot(_6403, _6403);\n    }\n    return t * inversesqrt(l2);\n}\n\nvec3 fa_ltc_local(vec3 t1, vec3 n, vec3 p)\n{\n    return vec3(dot(t1, p), dot(cross(n, t1), p), dot(n, p));\n}\n\nvec2 fa_ltc_uv(float roughness, float ndv)\n{\n    return ((vec2(clamp((roughness - 0.0500000007450580596923828125) * 1.0526316165924072265625, 0.0, 1.0), sqrt(clamp(1.0 - ndv, 0.0, 1.0))) * 63.0) + vec2(0.5)) * vec2(0.015625);\n}\n\nvec3 fa_oct_vertex(int j, vec3 pc, vec3 ex, vec3 ey)\n{\n    float _6790;\n    if ((j == 0) || (j == 7))\n    {\n        _6790 = 0.92387950420379638671875;\n    }\n    else\n    {\n        float _6800;\n        if ((j == 3) || (j == 4))\n        {\n            _6800 = -0.92387950420379638671875;\n        }\n        else\n        {\n            _6800 = ((j == 1) || (j == 6)) ? 0.3826834261417388916015625 : (-0.3826834261417388916015625);\n        }\n        _6790 = _6800;\n    }\n    float _6821;\n    if ((j == 1) || (j == 2))\n    {\n        _6821 = 0.92387950420379638671875;\n    }\n    else\n    {\n        float _6830;\n        if ((j == 5) || (j == 6))\n        {\n            _6830 = -0.92387950420379638671875;\n        }\n        else\n        {\n            _6830 = ((j == 0) || (j == 3)) ? 0.3826834261417388916015625 : (-0.3826834261417388916015625);\n        }\n        _6821 = _6830;\n    }\n    return (pc + (ex * _6790)) + (ey * _6821);\n}\n\nvec3 fa_ltc_edge_vector(vec3 a, vec3 b)\n{\n    float _6438 = dot(a, a);\n    float _6442 = dot(b, b);\n    if ((_6438 < 1.0000000195414813782625560981111e-24) || (_6442 < 1.0000000195414813782625560981111e-24))\n    {\n        return vec3(0.0);\n    }\n    vec3 _6456 = a * inversesqrt(_6438);\n    vec3 _6461 = b * inversesqrt(_6442);\n    float _6465 = dot(_6456, _6461);\n    float _6468 = abs(_6465);\n    float g = (((((((((((0.0416471660137176513671875 * _6468) - 0.1924748718738555908203125) * _6468) + 0.4179156124591827392578125) * _6468) - 0.616057217121124267578125) * _6468) + 0.777722418308258056640625) * _6468) - 0.999542415142059326171875) * _6468) + 1.570791721343994140625;\n    if (_6465 < 0.0)\n    {\n        g = (3.1415927410125732421875 * inversesqrt(max(1.0 - (_6465 * _6465), 1.0000000116860974230803549289703e-07))) - g;\n    }\n    return cross(_6456, _6461) * g;\n}\n\nvoid fa_ltc_clip_edge(vec3 a, vec3 b, inout vec3 sum, inout vec3 leave, inout vec3 enter, inout vec2 seen)\n{\n    bool _6525 = a.z > 0.0;\n    bool _6529 = b.z > 0.0;\n    if (_6525 && _6529)\n    {\n        vec3 param = a;\n        vec3 param_1 = b;\n        sum += fa_ltc_edge_vector(param, param_1);\n    }\n    else\n    {\n        if (_6525 != _6529)\n        {\n            vec3 _6564 = a + ((b - a) * (a.z / (a.z - b.z)));\n            _6564.z = 0.0;\n            if (_6525)\n            {\n                vec3 param_2 = a;\n                vec3 param_3 = _6564;\n                sum += fa_ltc_edge_vector(param_2, param_3);\n                leave = _6564;\n                seen.x = 1.0;\n            }\n            else\n            {\n                vec3 param_4 = _6564;\n                vec3 param_5 = b;\n                sum += fa_ltc_edge_vector(param_4, param_5);\n                enter = _6564;\n                seen.y = 1.0;\n            }\n        }\n    }\n}\n\nfloat fa_ltc_quad(vec4 abcd, vec3 p0, vec3 p1, vec3 p2, vec3 p3)\n{\n    vec3 _6613 = vec3((abcd.x * p0.x) + (abcd.y * p0.z), p0.y, (abcd.z * p0.x) + (abcd.w * p0.z));\n    vec3 _6639 = vec3((abcd.x * p1.x) + (abcd.y * p1.z), p1.y, (abcd.z * p1.x) + (abcd.w * p1.z));\n    vec3 _6665 = vec3((abcd.x * p2.x) + (abcd.y * p2.z), p2.y, (abcd.z * p2.x) + (abcd.w * p2.z));\n    vec3 _6691 = vec3((abcd.x * p3.x) + (abcd.y * p3.z), p3.y, (abcd.z * p3.x) + (abcd.w * p3.z));\n    vec3 sum = vec3(0.0);\n    vec3 leave = vec3(0.0);\n    vec3 enter = vec3(0.0);\n    vec3 param = _6613;\n    vec3 param_1 = _6639;\n    vec3 param_2 = vec3(0.0);\n    vec3 param_3 = vec3(0.0);\n    vec3 param_4 = vec3(0.0);\n    vec2 param_5 = vec2(0.0);\n    fa_ltc_clip_edge(param, param_1, param_2, param_3, param_4, param_5);\n    sum = param_2;\n    leave = param_3;\n    enter = param_4;\n    vec3 param_6 = _6639;\n    vec3 param_7 = _6665;\n    vec3 param_8 = param_2;\n    vec3 param_9 = param_3;\n    vec3 param_10 = param_4;\n    vec2 param_11 = param_5;\n    fa_ltc_clip_edge(param_6, param_7, param_8, param_9, param_10, param_11);\n    sum = param_8;\n    leave = param_9;\n    enter = param_10;\n    vec3 param_12 = _6665;\n    vec3 param_13 = _6691;\n    vec3 param_14 = param_8;\n    vec3 param_15 = param_9;\n    vec3 param_16 = param_10;\n    vec2 param_17 = param_11;\n    fa_ltc_clip_edge(param_12, param_13, param_14, param_15, param_16, param_17);\n    sum = param_14;\n    leave = param_15;\n    enter = param_16;\n    vec3 param_18 = _6691;\n    vec3 param_19 = _6613;\n    vec3 param_20 = param_14;\n    vec3 param_21 = param_15;\n    vec3 param_22 = param_16;\n    vec2 param_23 = param_17;\n    fa_ltc_clip_edge(param_18, param_19, param_20, param_21, param_22, param_23);\n    sum = param_20;\n    leave = param_21;\n    enter = param_22;\n    if ((param_23.x * param_23.y) > 0.5)\n    {\n        vec3 param_24 = leave;\n        vec3 param_25 = enter;\n        sum += fa_ltc_edge_vector(param_24, param_25);\n    }\n    return sum.z * 0.15915493667125701904296875;\n}\n\nvec2 fa_area_forms(vec4 m, float shape, vec3 pc, vec3 ex, vec3 ey)\n{\n    int _6859 = ((shape < 0.5) || (shape > 1.5)) ? 1 : 3;\n    vec2 sum = vec2(0.0);\n    int _6877;\n    for (int k = 0; k < (2 * _6859); k++)\n    {\n        bool _6874 = k >= _6859;\n        if (_6874)\n        {\n            _6877 = k - _6859;\n        }\n        else\n        {\n            _6877 = k;\n        }\n        vec3 p0 = (pc - ex) - ey;\n        vec3 p1 = (pc + ex) - ey;\n        vec3 p2 = (pc + ex) + ey;\n        vec3 p3 = (pc - ex) + ey;\n        if (_6859 == 3)\n        {\n            int param = 0;\n            vec3 param_1 = pc;\n            vec3 param_2 = ex;\n            vec3 param_3 = ey;\n            p0 = fa_oct_vertex(param, param_1, param_2, param_3);\n            int _6923 = 2 * _6877;\n            int param_4 = _6923 + 1;\n            vec3 param_5 = pc;\n            vec3 param_6 = ex;\n            vec3 param_7 = ey;\n            p1 = fa_oct_vertex(param_4, param_5, param_6, param_7);\n            int param_8 = _6923 + 2;\n            vec3 param_9 = pc;\n            vec3 param_10 = ex;\n            vec3 param_11 = ey;\n            p2 = fa_oct_vertex(param_8, param_9, param_10, param_11);\n            int param_12 = _6923 + 3;\n            vec3 param_13 = pc;\n            vec3 param_14 = ex;\n            vec3 param_15 = ey;\n            p3 = fa_oct_vertex(param_12, param_13, param_14, param_15);\n        }\n        bvec4 _6960 = bvec4(_6874);\n        vec4 param_16 = vec4(_6960.x ? m.x : vec4(1.0, 0.0, 0.0, 1.0).x, _6960.y ? m.y : vec4(1.0, 0.0, 0.0, 1.0).y, _6960.z ? m.z : vec4(1.0, 0.0, 0.0, 1.0).z, _6960.w ? m.w : vec4(1.0, 0.0, 0.0, 1.0).w);\n        vec3 param_17 = p0;\n        vec3 param_18 = p1;\n        vec3 param_19 = p2;\n        vec3 param_20 = p3;\n        float _6971 = fa_ltc_quad(param_16, param_17, param_18, param_19, param_20);\n        if (_6874)\n        {\n            vec2 _9672 = sum;\n            _9672.y = _9672.y + _6971;\n            sum = _9672;\n        }\n        else\n        {\n            vec2 _9675 = sum;\n            _9675.x = _9675.x + _6971;\n            sum = _9675;\n        }\n    }\n    return abs(sum);\n}\n\nvec3 fa_area_shade(int li, vec3 world_pos, vec3 n, vec3 v, vec3 diffuse_color, vec3 f0, float f90, float roughness, float ndv, float window)\n{\n    int param = li;\n    int _6995 = fa_light_base(param);\n    int param_1 = _6995;\n    int param_2 = _6995 + 1;\n    int param_3 = _6995 + 2;\n    int param_4 = _6995 + 4;\n    vec4 _7017 = fa_light_texel(param_4);\n    int param_5 = _6995 + 5;\n    vec4 _7022 = fa_light_texel(param_5);\n    int param_6 = _6995 + 6;\n    vec4 _7027 = fa_light_texel(param_6);\n    float _7028 = _7027.w;\n    vec3 _7033 = fa_light_texel(param_1).xyz - world_pos;\n    bool _7035 = _7028 < 1.5;\n    bool _7042;\n    if (_7035)\n    {\n        _7042 = dot(normalize(fa_light_texel(param_3).xyz), _7033) >= 0.0;\n    }\n    else\n    {\n        _7042 = _7035;\n    }\n    if (_7042)\n    {\n        return vec3(0.0);\n    }\n    bool _7051 = (_7028 > 0.5) && _7035;\n    float _7055 = _7051 ? 1.0539000034332275390625 : 1.0;\n    vec3 _7058 = _7017.xyz;\n    float _7060 = _7017.w;\n    vec3 _7066 = _7022.xyz;\n    float _7068 = _7022.w;\n    vec3 up = _7066 * (_7068 * _7055);\n    float _7074;\n    if (_7051)\n    {\n        _7074 = (3.1415927410125732421875 * _7060) * _7060;\n    }\n    else\n    {\n        _7074 = (4.0 * _7060) * _7068;\n    }\n    if (_7028 > 1.5)\n    {\n        vec3 _7100 = cross(_7058, -_7033);\n        vec3 perp = _7100;\n        float _7104 = dot(_7100, _7100);\n        vec3 _7107;\n        if (_7104 > 1.0000000133514319600180897396058e-10)\n        {\n            _7107 = perp * inversesqrt(_7104);\n        }\n        else\n        {\n            _7107 = _7066;\n        }\n        perp = _7107;\n        up = _7107 * _7068;\n    }\n    float _7128 = max(_7074, 9.9999999747524270787835121154785e-07);\n    vec3 param_7 = n;\n    vec3 param_8 = v;\n    vec3 _7138 = fa_ltc_tangent(param_7, param_8);\n    vec3 param_9 = _7138;\n    vec3 param_10 = n;\n    vec3 param_11 = _7033;\n    vec3 param_12 = _7138;\n    vec3 param_13 = n;\n    vec3 param_14 = _7058 * (_7060 * _7055);\n    vec3 param_15 = _7138;\n    vec3 param_16 = n;\n    vec3 param_17 = up;\n    float param_18 = roughness;\n    float param_19 = ndv;\n    vec2 _7169 = fa_ltc_uv(param_18, param_19) * 64.0;\n    vec2 param_20 = _7169;\n    vec2 param_21 = _7169 + vec2(64.0, 0.0);\n    vec4 _7179 = fa_atlas_fetch(param_21);\n    vec4 param_22 = fa_atlas_fetch(param_20);\n    float param_23 = _7028;\n    vec3 param_24 = fa_ltc_local(param_9, param_10, param_11);\n    vec3 param_25 = fa_ltc_local(param_12, param_13, param_14);\n    vec3 param_26 = fa_ltc_local(param_15, param_16, param_17);\n    vec2 _7191 = fa_area_forms(param_22, param_23, param_24, param_25, param_26);\n    return (((diffuse_color * _7191.x) + (((f0 * _7179.x) + ((vec3(f90) - f0) * _7179.y)) * _7191.y)) * fa_light_texel(param_2).xyz) * ((((3.1415927410125732421875 * dot(_7033, _7033)) + _7128) / _7128) * window);\n}\n\nvec3 fa_light_rgb(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 1;\n    return fa_light_texel(param_1).xyz;\n}\n\nfloat fa_d_charlie(float alpha, float ndh)\n{\n    float _5114 = 1.0 / alpha;\n    return ((2.0 + _5114) * pow(sqrt(max(1.0 - (ndh * ndh), 9.9999997473787516355514526367188e-05)), _5114)) * 0.15915493667125701904296875;\n}\n\nfloat fa_v_ashikhmin(float ndl, float ndv)\n{\n    return clamp(0.25 / max((ndl + ndv) - (ndl * ndv), 9.9999997473787516355514526367188e-05), 0.0, 1.0);\n}\n\nfloat fa_layers_coat(FaLayers L, vec3 l, vec3 h, float vdh)\n{\n    float _5149 = max(dot(L.nc, l), 0.0);\n    float _5155 = max(dot(L.nc, h), 0.0);\n    float _5164 = ((_5155 * _5155) * (L.coat_a2 - 1.0)) + 1.0;\n    return (((L.coat * (0.039999999105930328369140625 + (0.959999978542327880859375 * pow(clamp(1.0 - vdh, 0.0, 1.0), 5.0)))) * (((L.coat_a2 / ((3.1415927410125732421875 * _5164) * _5164)) * (0.5 / max(mix((2.0 * _5149) * L.coat_ndv, _5149 + L.coat_ndv, L.coat_alpha), 9.9999997473787516355514526367188e-05))) * 3.1415927410125732421875)) * step(9.9999997473787516355514526367188e-05, _5149)) * _5149;\n}\n\nvec3 fa_area_layers(FaLayers L, vec3 base, int li, vec3 n, vec3 v, vec3 l, float ndv, float window)\n{\n    float _7228;\n    if (L.sheen_on)\n    {\n        _7228 = L.sheen_scale;\n    }\n    else\n    {\n        _7228 = 1.0;\n    }\n    vec3 result = base * (L.keep * _7228);\n    vec3 _7241 = normalize(l + v);\n    int param = li;\n    vec3 _7252 = fa_light_rgb(param) * window;\n    if (L.sheen_on)\n    {\n        float _7261 = max(dot(n, l), 0.0);\n        float param_1 = L.sheen_alpha;\n        float param_2 = max(dot(n, _7241), 0.0);\n        float param_3 = _7261;\n        float param_4 = ndv;\n        result += ((L.sheen * _7252) * (((((fa_d_charlie(param_1, param_2) * fa_v_ashikhmin(param_3, param_4)) * 3.1415927410125732421875) * step(9.9999997473787516355514526367188e-05, _7261)) * _7261) * L.keep));\n    }\n    if (L.coat > 0.0)\n    {\n        FaLayers param_5 = L;\n        vec3 param_6 = l;\n        vec3 param_7 = _7241;\n        float param_8 = max(dot(v, _7241), 0.0);\n        result += (_7252 * fa_layers_coat(param_5, param_6, param_7, param_8));\n    }\n    return result;\n}\n\nfloat fa_d_ggx_aniso(float ndh, float tdh, float bdh, float at, float ab)\n{\n    float _5017 = tdh / at;\n    float _5021 = bdh / ab;\n    float _5033 = ((_5017 * _5017) + (_5021 * _5021)) + (ndh * ndh);\n    return 1.0 / ((((3.1415927410125732421875 * at) * ab) * _5033) * _5033);\n}\n\nfloat fa_lambda_ggx_aniso(float n, float t, float b, float at, float ab)\n{\n    return 0.5 * (sqrt(1.0 + (((((at * at) * t) * t) + (((ab * ab) * b) * b)) / max(n * n, 9.9999999392252902907785028219223e-09))) - 1.0);\n}\n\nfloat fa_v_ggx_aniso(float ndl, float ndv, float tdv, float bdv, float tdl, float bdl, float at, float ab)\n{\n    float param = ndv;\n    float param_1 = tdv;\n    float param_2 = bdv;\n    float param_3 = at;\n    float param_4 = ab;\n    float param_5 = ndl;\n    float param_6 = tdl;\n    float param_7 = bdl;\n    float param_8 = at;\n    float param_9 = ab;\n    return clamp(1.0 / ((4.0 * max(ndl * ndv, 9.9999997473787516355514526367188e-05)) * ((1.0 + fa_lambda_ggx_aniso(param, param_1, param_2, param_3, param_4)) + fa_lambda_ggx_aniso(param_5, param_6, param_7, param_8, param_9))), 0.0, 1.0);\n}\n\nvec3 fa_layers_light(FaLayers L, vec3 diffuse_color, vec3 f0, vec3 n, vec3 v, vec3 l, vec3 h, float ndl, float ndv, float ndh, float vdh, float alpha, float a2)\n{\n    float _5213 = step(9.9999997473787516355514526367188e-05, ndl);\n    float d_ggx;\n    float vis;\n    if (L.aniso != 0.0)\n    {\n        float param = ndh;\n        float param_1 = dot(L.t, h);\n        float param_2 = dot(L.b, h);\n        float param_3 = L.at;\n        float param_4 = L.ab;\n        d_ggx = fa_d_ggx_aniso(param, param_1, param_2, param_3, param_4);\n        float param_5 = ndl;\n        float param_6 = ndv;\n        float param_7 = dot(L.t, v);\n        float param_8 = dot(L.b, v);\n        float param_9 = dot(L.t, l);\n        float param_10 = dot(L.b, l);\n        float param_11 = L.at;\n        float param_12 = L.ab;\n        vis = fa_v_ggx_aniso(param_5, param_6, param_7, param_8, param_9, param_10, param_11, param_12);\n    }\n    else\n    {\n        float _5292 = ((ndh * ndh) * (a2 - 1.0)) + 1.0;\n        d_ggx = a2 / ((3.1415927410125732421875 * _5292) * _5292);\n        vis = 0.5 / max(mix((2.0 * ndl) * ndv, ndl + ndv, alpha), 9.9999997473787516355514526367188e-05);\n    }\n    vec3 base = diffuse_color + (((f0 + ((vec3(L.f90) - f0) * pow(clamp(1.0 - vdh, 0.0, 1.0), 5.0))) * ((d_ggx * vis) * 3.1415927410125732421875)) * _5213);\n    if (L.sheen_on)\n    {\n        float param_13 = L.sheen_alpha;\n        float param_14 = ndh;\n        float param_15 = ndl;\n        float param_16 = ndv;\n        base = (base * L.sheen_scale) + (L.sheen * (((fa_d_charlie(param_13, param_14) * fa_v_ashikhmin(param_15, param_16)) * 3.1415927410125732421875) * _5213));\n    }\n    vec3 result = base * (L.keep * ndl);\n    if (L.coat > 0.0)\n    {\n        FaLayers param_17 = L;\n        vec3 param_18 = l;\n        vec3 param_19 = h;\n        float param_20 = vdh;\n        result += vec3(fa_layers_coat(param_17, param_18, param_19, param_20));\n    }\n    return result;\n}\n\nvec2 fa_env_brdf(float rough, float ndv)\n{\n    vec4 _4416 = (vec4(-1.0, -0.0274999998509883880615234375, -0.572000026702880859375, 0.02199999988079071044921875) * rough) + vec4(1.0, 0.0425000004470348358154296875, 1.03999996185302734375, -0.039999999105930328369140625);\n    float _4419 = _4416.x;\n    return (vec2(-1.03999996185302734375, 1.03999996185302734375) * ((min(_4419 * _4419, exp2((-9.27999973297119140625) * ndv)) * _4419) + _4416.y)) + _4416.zw;\n}\n\nvec3 fa_probe_level(vec2 origin, float res, int lv, vec2 e)\n{\n    float _3725;\n    if (lv == 0)\n    {\n        _3725 = 0.0;\n    }\n    else\n    {\n        _3725 = res + 2.0;\n    }\n    float _3735;\n    if (lv == 0)\n    {\n        _3735 = 0.0;\n    }\n    else\n    {\n        _3735 = (res - (res / float(1 << max((lv - 1), 0)))) + (2.0 * float(lv - 1));\n    }\n    return textureLod(fa_probe_atlas_fa_env_smp, (((origin + vec2(_3725, _3735)) + vec2(1.0)) + (((e * 0.5) + vec2(0.5)) * (res / float(1 << lv)))) / fa_atlas_size(), 0.0).xyz;\n}\n\nvec3 fa_probe_radiance(vec2 origin, float res, vec3 d, float rough)\n{\n    float _3781;\n    if (res > 64.5)\n    {\n        _3781 = 5.0;\n    }\n    else\n    {\n        _3781 = (res > 32.5) ? 4.0 : 3.0;\n    }\n    float _3796 = clamp(rough, 0.0, 1.0) * (_3781 - 1.0);\n    int _3803 = int(min(floor(_3796), _3781 - 2.0));\n    float _3808 = _3796 - float(_3803);\n    vec3 param = d;\n    vec2 _3812 = fa_oct_encode(param);\n    vec2 param_1 = origin;\n    float param_2 = res;\n    int param_3 = _3803;\n    vec2 param_4 = _3812;\n    vec3 _3822 = fa_probe_level(param_1, param_2, param_3, param_4);\n    if (_3808 < 0.00200000009499490261077880859375)\n    {\n        return _3822;\n    }\n    vec2 param_5 = origin;\n    float param_6 = res;\n    int param_7 = _3803 + 1;\n    vec2 param_8 = _3812;\n    return mix(_3822, fa_probe_level(param_5, param_6, param_7, param_8), vec3(_3808));\n}\n\nvec3 fa_probe_box_dir(vec3 d, vec4 posw, vec4 bx, vec4 by, vec4 bz)\n{\n    if (posw.w < 0.5)\n    {\n        return d;\n    }\n    float _3894 = dot(bx.xyz, fa_world_pos) + bx.w;\n    float _3901 = dot(by.xyz, fa_world_pos) + by.w;\n    float _3908 = dot(bz.xyz, fa_world_pos) + bz.w;\n    float _3914 = dot(bx.xyz, d);\n    float _3918 = dot(by.xyz, d);\n    float _3922 = dot(bz.xyz, d);\n    float _3928;\n    if (_3914 > 9.9999999747524270787835121154785e-07)\n    {\n        _3928 = (1.0 - _3894) / _3914;\n    }\n    else\n    {\n        float _3942;\n        if (_3914 < (-9.9999999747524270787835121154785e-07))\n        {\n            _3942 = ((-1.0) - _3894) / _3914;\n        }\n        else\n        {\n            _3942 = 1000000015047466219876688855040.0;\n        }\n        _3928 = _3942;\n    }\n    float tx = _3928;\n    float _3959;\n    if (_3918 > 9.9999999747524270787835121154785e-07)\n    {\n        _3959 = (1.0 - _3901) / _3918;\n    }\n    else\n    {\n        float _3972;\n        if (_3918 < (-9.9999999747524270787835121154785e-07))\n        {\n            _3972 = ((-1.0) - _3901) / _3918;\n        }\n        else\n        {\n            _3972 = 1000000015047466219876688855040.0;\n        }\n        _3959 = _3972;\n    }\n    float ty = _3959;\n    float _3988;\n    if (_3922 > 9.9999999747524270787835121154785e-07)\n    {\n        _3988 = (1.0 - _3908) / _3922;\n    }\n    else\n    {\n        float _4001;\n        if (_3922 < (-9.9999999747524270787835121154785e-07))\n        {\n            _4001 = ((-1.0) - _3908) / _3922;\n        }\n        else\n        {\n            _4001 = 1000000015047466219876688855040.0;\n        }\n        _3988 = _4001;\n    }\n    float _4013 = tx;\n    float _4016 = (_4013 > 0.0) ? _4013 : 1000000015047466219876688855040.0;\n    tx = _4016;\n    float _4017 = ty;\n    float _4020 = (_4017 > 0.0) ? _4017 : 1000000015047466219876688855040.0;\n    ty = _4020;\n    float _4030 = min(_4016, min(_4020, (_3988 > 0.0) ? _3988 : 1000000015047466219876688855040.0));\n    if (_4030 > 100000001504746621987668885504.0)\n    {\n        return d;\n    }\n    vec3 _4046 = (fa_world_pos + (d * _4030)) - posw.xyz;\n    vec3 _4051;\n    if (dot(_4046, _4046) > 1.0000000133514319600180897396058e-10)\n    {\n        _4051 = normalize(_4046);\n    }\n    else\n    {\n        _4051 = d;\n    }\n    return _4051;\n}\n\nvec3 fa_probe_environment(vec4 tile, vec4 posw, vec4 bx, vec4 by, vec4 bz, inout vec3 d, float rough)\n{\n    vec3 param = d;\n    vec4 param_1 = posw;\n    vec4 param_2 = bx;\n    vec4 param_3 = by;\n    vec4 param_4 = bz;\n    d = fa_probe_box_dir(param, param_1, param_2, param_3, param_4);\n    vec2 param_5 = tile.xy;\n    float param_6 = tile.z;\n    vec3 param_7 = d;\n    float param_8 = rough;\n    return fa_probe_radiance(param_5, param_6, param_7, param_8);\n}\n\nvec3 fa_environment(vec3 d, float rough)\n{\n    float _4097 = (1.0 - fa_mesh_fs_params[42].w) - fa_mesh_fs_params[47].w;\n    vec3 outc = vec3(0.0);\n    if (_4097 > 0.0005000000237487256526947021484375)\n    {\n        vec3 base;\n        if (fa_mesh_fs_params[11].w > 0.5)\n        {\n            vec2 param = fa_mesh_fs_params[41].zw;\n            float param_1 = 128.0;\n            vec3 param_2 = d;\n            float param_3 = rough;\n            base = fa_probe_radiance(param, param_1, param_2, param_3);\n        }\n        else\n        {\n            float _4125 = rough * rough;\n            float _4156 = 0.60000002384185791015625 * _4125;\n            base = mix(mix(fa_mesh_fs_params[12].xyz * 0.550000011920928955078125, mix(fa_mesh_fs_params[12].xyz, fa_mesh_fs_params[11].xyz, vec3(pow(clamp(d.y * (1.0 - (0.699999988079071044921875 * _4125)), 0.0, 1.0), 0.550000011920928955078125))), vec3(smoothstep((-0.0500000007450580596923828125) - _4156, 0.0500000007450580596923828125 + _4156, d.y))), ((fa_mesh_fs_params[11].xyz + fa_mesh_fs_params[12].xyz) * 0.5) * 0.800000011920928955078125, vec3(_4125 * 0.60000002384185791015625));\n        }\n        outc = base * _4097;\n    }\n    if (fa_mesh_fs_params[42].w > 0.0)\n    {\n        vec4 param_4 = fa_mesh_fs_params[42];\n        vec4 param_5 = fa_mesh_fs_params[43];\n        vec4 param_6 = fa_mesh_fs_params[44];\n        vec4 param_7 = fa_mesh_fs_params[45];\n        vec4 param_8 = fa_mesh_fs_params[46];\n        vec3 param_9 = d;\n        float param_10 = rough;\n        vec3 _4215 = fa_probe_environment(param_4, param_5, param_6, param_7, param_8, param_9, param_10);\n        outc += (_4215 * fa_mesh_fs_params[42].w);\n    }\n    if (fa_mesh_fs_params[47].w > 0.0)\n    {\n        vec4 param_11 = fa_mesh_fs_params[47];\n        vec4 param_12 = fa_mesh_fs_params[48];\n        vec4 param_13 = fa_mesh_fs_params[49];\n        vec4 param_14 = fa_mesh_fs_params[50];\n        vec4 param_15 = fa_mesh_fs_params[51];\n        vec3 param_16 = d;\n        float param_17 = rough;\n        vec3 _4247 = fa_probe_environment(param_11, param_12, param_13, param_14, param_15, param_16, param_17);\n        outc += (_4247 * fa_mesh_fs_params[47].w);\n    }\n    return outc;\n}\n\nvec3 fa_layers_ibl(FaLayers L, vec3 n, vec3 v, vec3 f0, float roughness, float occlusion)\n{\n    vec3 rn = n;\n    if (L.aniso != 0.0)\n    {\n        vec3 _4894;\n        if (L.aniso >= 0.0)\n        {\n            _4894 = L.b;\n        }\n        else\n        {\n            _4894 = L.t;\n        }\n        rn = normalize(mix(n, cross(cross(_4894, v), _4894), vec3(abs(L.aniso) * smoothstep(0.0, 0.25, roughness))));\n    }\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05);\n    vec2 _4930 = fa_env_brdf(param, param_1);\n    vec3 param_2 = reflect(-v, rn);\n    float param_3 = roughness;\n    vec3 result = (fa_environment(param_2, param_3) * ((f0 * _4930.x) + (vec3(L.f90) * _4930.y))) * L.base_scale;\n    if (L.sheen_on)\n    {\n        vec3 param_4 = n;\n        float param_5 = L.sheen_rough;\n        result += ((L.sheen * (L.sheen_e * L.keep)) * fa_environment(param_4, param_5));\n    }\n    result *= occlusion;\n    if (L.coat > 0.0)\n    {\n        float param_6 = L.coat_rough;\n        float param_7 = L.coat_ndv;\n        vec2 _4988 = fa_env_brdf(param_6, param_7);\n        vec3 param_8 = reflect(-v, L.nc);\n        float param_9 = L.coat_rough;\n        result += (fa_environment(param_8, param_9) * (L.coat * ((0.039999999105930328369140625 * _4988.x) + _4988.y)));\n    }\n    return result;\n}\n\nvec3 fa_sky_reflection(vec3 n, vec3 v, vec3 f0, float roughness)\n{\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05);\n    vec2 _4458 = fa_env_brdf(param, param_1);\n    vec3 param_2 = reflect(-v, n);\n    float param_3 = roughness;\n    return fa_environment(param_2, param_3) * ((f0 * _4458.x) + vec3(_4458.y));\n}\n\nvec2 fa_xm_size(int k)\n{\n    return max(floor(fa_mesh_fs_params[24].zw / vec2(float(1 << k))), vec2(1.0));\n}\n\nvec2 fa_xm_origin(int k)\n{\n    if (k == 0)\n    {\n        return vec2(0.0);\n    }\n    float y = 0.0;\n    for (int j = 1; j < k; j++)\n    {\n        int param = j;\n        y += fa_xm_size(param).y;\n    }\n    return vec2(fa_mesh_fs_params[24].z, y);\n}\n\nvec3 fa_xm_texel(vec2 size, vec2 origin, vec2 p)\n{\n    return texelFetch(fa_screen_tex_fa_shadow_smp, ivec2(origin + clamp(p, vec2(0.0), size - vec2(1.0))), 0).xyz;\n}\n\nvec3 fa_xm_level(int k, vec2 uv)\n{\n    int param = k;\n    vec2 _5690 = fa_xm_size(param);\n    int param_1 = k;\n    vec2 _5694 = fa_xm_origin(param_1);\n    vec2 _5700 = (uv * _5690) - vec2(0.5);\n    vec2 _5703 = fract(_5700);\n    vec2 _5706 = floor(_5700);\n    vec2 param_2 = _5690;\n    vec2 param_3 = _5694;\n    vec2 param_4 = _5706;\n    vec2 param_5 = _5690;\n    vec2 param_6 = _5694;\n    vec2 param_7 = _5706 + vec2(1.0, 0.0);\n    vec2 param_8 = _5690;\n    vec2 param_9 = _5694;\n    vec2 param_10 = _5706 + vec2(0.0, 1.0);\n    vec2 param_11 = _5690;\n    vec2 param_12 = _5694;\n    vec2 param_13 = _5706 + vec2(1.0);\n    vec3 _5748 = vec3(_5703.x);\n    return mix(mix(fa_xm_texel(param_2, param_3, param_4), fa_xm_texel(param_5, param_6, param_7), _5748), mix(fa_xm_texel(param_8, param_9, param_10), fa_xm_texel(param_11, param_12, param_13), _5748), vec3(_5703.y));\n}\n\nvec3 fa_xm_sample(vec2 uv, float lod)\n{\n    float _5767 = max(fa_mesh_fs_params[31].w - 1.0, 0.0);\n    float _5771 = clamp(lod, 0.0, _5767);\n    int _5775 = int(floor(_5771));\n    int param = _5775;\n    vec2 param_1 = uv;\n    vec3 c = fa_xm_level(param, param_1);\n    float _5785 = float(_5775);\n    float _5786 = _5771 - _5785;\n    bool _5788 = _5786 > 0.001000000047497451305389404296875;\n    bool _5795;\n    if (_5788)\n    {\n        _5795 = _5785 < _5767;\n    }\n    else\n    {\n        _5795 = _5788;\n    }\n    if (_5795)\n    {\n        int param_2 = _5775 + 1;\n        vec2 param_3 = uv;\n        c = mix(c, fa_xm_level(param_2, param_3), vec3(_5786));\n    }\n    return c;\n}\n\nvec3 fa_transmitted(Surface s, vec3 n, vec3 v, float roughness, vec3 f0, float f90, float keep, float tr, inout float blend)\n{\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05);\n    vec2 _5821 = fa_env_brdf(param, param_1);\n    vec3 _5845 = ((vec3(1.0) - clamp((f0 * _5821.x) + (vec3(f90) * _5821.y), vec3(0.0), vec3(1.0))) * s.albedo) * (tr * keep);\n    vec3 through = _5845;\n    float _5851 = max(s.thickness, 0.0);\n    bool _5856 = _5851 > 0.0;\n    if ((s.attenuation_distance > 0.0) && _5856)\n    {\n        through *= exp((-((-log(clamp(s.attenuation_color, vec3(9.9999997473787516355514526367188e-05), vec3(1.0)))) / vec3(s.attenuation_distance))) * _5851);\n    }\n    bool _5881 = fa_mesh_fs_params[30].w > 1.5;\n    bool _5887;\n    if (_5881)\n    {\n        _5887 = fa_mesh_fs_params[30].w < 2.5;\n    }\n    else\n    {\n        _5887 = _5881;\n    }\n    bool _5894;\n    if (!_5887)\n    {\n        _5894 = fa_mesh_fs_params[30].w < 0.5;\n    }\n    else\n    {\n        _5894 = _5887;\n    }\n    if (_5894)\n    {\n        blend = clamp(dot(through, vec3(0.3333333432674407958984375)), 0.0, 0.980000019073486328125);\n        return vec3(0.0);\n    }\n    vec4 _5909 = vec4(fa_world_pos, 1.0);\n    float _5914 = dot(fa_mesh_fs_params[28], _5909);\n    vec2 uv0 = vec2(0.5);\n    if (_5914 > 9.9999997473787516355514526367188e-05)\n    {\n        vec2 _5932 = vec2(dot(fa_mesh_fs_params[26], _5909), dot(fa_mesh_fs_params[27], _5909)) / vec2(_5914);\n        float _5940;\n        if (fa_mesh_fs_params[24].y > 0.5)\n        {\n            _5940 = (_5932.y * 0.5) + 0.5;\n        }\n        else\n        {\n            _5940 = 0.5 - (_5932.y * 0.5);\n        }\n        uv0 = vec2((_5932.x * 0.5) + 0.5, _5940);\n    }\n    if (fa_mesh_fs_params[30].w > 2.5)\n    {\n        int param_2 = 0;\n        vec2 _5961 = fa_xm_size(param_2);\n        vec2 _5969 = floor(clamp(uv0, vec2(0.0), vec2(0.99989998340606689453125)) * _5961);\n        if (texelFetch(fa_screen_tex_fa_shadow_smp, ivec2(_5969), 0).w > 0.5)\n        {\n            int _5989 = int(floor((clamp(roughness, 0.0, 1.0) * 2.0) + 0.5));\n            vec3 acc = vec3(0.0);\n            float cnt = 0.0;\n            for (int dy = -2; dy <= 2; dy++)\n            {\n                for (int dx = -2; dx <= 2; dx++)\n                {\n                    bool _6012 = abs(dx) > _5989;\n                    bool _6020;\n                    if (!_6012)\n                    {\n                        _6020 = abs(dy) > _5989;\n                    }\n                    else\n                    {\n                        _6020 = _6012;\n                    }\n                    if (_6020)\n                    {\n                        continue;\n                    }\n                    vec4 _6041 = texelFetch(fa_screen_tex_fa_shadow_smp, ivec2(clamp(_5969 + vec2(float(dx), float(dy)), vec2(0.0), _5961 - vec2(1.0))), 0);\n                    if (_6041.w > 0.5)\n                    {\n                        acc += _6041.xyz;\n                        cnt += 1.0;\n                    }\n                }\n            }\n            return _5845 * (acc / vec3(max(cnt, 1.0)));\n        }\n    }\n    vec2 uv = uv0;\n    if (_5856)\n    {\n        vec4 _6089 = vec4(fa_world_pos + (refract(-v, n, 1.0 / max(s.ior, 1.0)) * _5851), 1.0);\n        float _6094 = dot(fa_mesh_fs_params[28], _6089);\n        uv = vec2(0.5);\n        if (_6094 > 9.9999997473787516355514526367188e-05)\n        {\n            vec2 _6111 = vec2(dot(fa_mesh_fs_params[26], _6089), dot(fa_mesh_fs_params[27], _6089)) / vec2(_6094);\n            float _6119;\n            if (fa_mesh_fs_params[24].y > 0.5)\n            {\n                _6119 = (_6111.y * 0.5) + 0.5;\n            }\n            else\n            {\n                _6119 = 0.5 - (_6111.y * 0.5);\n            }\n            uv = vec2((_6111.x * 0.5) + 0.5, _6119);\n        }\n    }\n    vec2 param_3 = clamp(uv, vec2(0.0), vec2(1.0));\n    float param_4 = (clamp(roughness, 0.0, 1.0) * clamp((2.0 * s.ior) - 2.0, 0.0, 1.0)) * max(fa_mesh_fs_params[31].w - 1.0, 0.0);\n    return through * fa_xm_sample(param_3, param_4);\n}\n\nvec3 fa_shadow_debug(vec3 color, vec3 world)\n{\n    if (fa_shadows[27].w < 0.5)\n    {\n        return color;\n    }\n    int _3305 = int(fa_shadows[25].x + 0.5);\n    float _3315 = dot(world - fa_shadows[27].xyz, fa_shadows[28].xyz);\n    vec3 tint = vec3(0.3499999940395355224609375);\n    bool _3320 = _3305 > 0;\n    bool _3329;\n    if (_3320)\n    {\n        int param = _3305 - 1;\n        _3329 = _3315 <= fa_shadow_split_at(param);\n    }\n    else\n    {\n        _3329 = _3320;\n    }\n    if (_3329)\n    {\n        tint = vec3(1.0, 0.1500000059604644775390625, 0.100000001490116119384765625);\n        bool _3335 = _3305 > 1;\n        bool _3342;\n        if (_3335)\n        {\n            _3342 = _3315 > fa_shadows[24].x;\n        }\n        else\n        {\n            _3342 = _3335;\n        }\n        if (_3342)\n        {\n            tint = vec3(0.100000001490116119384765625, 0.89999997615814208984375, 0.20000000298023223876953125);\n        }\n        bool _3348 = _3305 > 2;\n        bool _3355;\n        if (_3348)\n        {\n            _3355 = _3315 > fa_shadows[24].y;\n        }\n        else\n        {\n            _3355 = _3348;\n        }\n        if (_3355)\n        {\n            tint = vec3(0.1500000059604644775390625, 0.300000011920928955078125, 1.0);\n        }\n        bool _3361 = _3305 > 3;\n        bool _3368;\n        if (_3361)\n        {\n            _3368 = _3315 > fa_shadows[24].z;\n        }\n        else\n        {\n            _3368 = _3361;\n        }\n        if (_3368)\n        {\n            tint = vec3(1.0, 0.89999997615814208984375, 0.100000001490116119384765625);\n        }\n    }\n    return mix(color, tint, vec3(0.550000011920928955078125));\n}\n\nvoid main()\n{\n    fa_inst_load();\n    vec3 _9088 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _9088 = -_9088;\n    }\n    vec3 _8374 = normalize(fa_mesh_fs_params[0].xyz - fa_world_pos);\n    vec3 param = fa_world_pos;\n    fa_cluster_begin(param);\n    SurfaceInput param_1 = SurfaceInput(fa_world_pos, _9088, fa_world_tangent, fa_uv, fa_vertex_color, _8374, gl_FrontFacing);\n    Surface _8382 = fa_standard_surface(param_1);\n    vec3 _9119 = _8382.albedo;\n    float _9120 = _8382.alpha;\n    vec3 _9121 = _8382.normal;\n    float _9122 = _8382.metallic;\n    float _9123 = _8382.roughness;\n    float _9124 = _8382.occlusion;\n    vec3 _9125 = _8382.emission;\n    float _9126 = _8382.clearcoat;\n    float _9127 = _8382.clearcoat_roughness;\n    vec3 _9128 = _8382.sheen_color;\n    float _9129 = _8382.sheen_roughness;\n    float _9130 = _8382.anisotropy;\n    float _9131 = _8382.anisotropy_rotation;\n    float _9132 = _8382.specular;\n    float _9133 = _8382.ior;\n    vec3 _9134 = _8382.specular_color;\n    float _9135 = _8382.transmission;\n    float _9136 = _8382.thickness;\n    vec3 _9137 = _8382.attenuation_color;\n    float _9138 = _8382.attenuation_distance;\n    SurfaceInput param_2 = SurfaceInput(fa_world_pos, _9088, fa_world_tangent, fa_uv, fa_vertex_color, _8374, gl_FrontFacing);\n    Surface param_3 = _8382;\n    surface(param_2, param_3);\n    _9119 = param_3.albedo;\n    _9120 = param_3.alpha;\n    _9121 = param_3.normal;\n    _9122 = param_3.metallic;\n    _9123 = param_3.roughness;\n    _9124 = param_3.occlusion;\n    _9125 = param_3.emission;\n    _9126 = param_3.clearcoat;\n    _9127 = param_3.clearcoat_roughness;\n    _9128 = param_3.sheen_color;\n    _9129 = param_3.sheen_roughness;\n    _9130 = param_3.anisotropy;\n    _9131 = param_3.anisotropy_rotation;\n    _9132 = param_3.specular;\n    _9133 = param_3.ior;\n    _9134 = param_3.specular_color;\n    _9135 = param_3.transmission;\n    _9136 = param_3.thickness;\n    _9137 = param_3.attenuation_color;\n    _9138 = param_3.attenuation_distance;\n    vec3 param_4 = fa_world_pos;\n    vec3 param_5 = _9088;\n    vec3 param_6 = param_3.albedo;\n    vec3 param_7 = param_3.normal;\n    fa_apply_decals(param_4, param_5, param_6, param_7);\n    _9119 = param_6;\n    _9121 = param_7;\n    if (_9120 < fa_material[0].x)\n    {\n        discard;\n    }\n    fa_lod_dither();\n    float fa_tr_blend = 0.0;\n    vec3 result;\n    if (fa_mesh_fs_params[3].w > 0.5)\n    {\n        result = _9119;\n    }\n    else\n    {\n        vec3 _8434 = normalize(_9121);\n        float _8441 = clamp(_9122, 0.0, 1.0);\n        float _8445 = clamp(_9123, 0.0500000007450580596923828125, 1.0);\n        float _8449 = _8445 * _8445;\n        float _8453 = _8449 * _8449;\n        float _8458 = max(dot(_8434, _8374), 9.9999997473787516355514526367188e-05);\n        float _8464 = 1.0 - _8441;\n        float _8465 = clamp(_9135, 0.0, 1.0) * _8464;\n        vec3 _8474 = (_9119 * _8464) * (1.0 - _8465);\n        vec3 _8481 = mix(vec3(0.039999999105930328369140625), _9119, vec3(_8441));\n        vec3 f0 = _8481;\n        SurfaceInput param_8 = SurfaceInput(fa_world_pos, _9088, fa_world_tangent, fa_uv, fa_vertex_color, _8374, gl_FrontFacing);\n        Surface param_9 = Surface(_9119, _9120, _9121, _9122, _9123, _9124, _9125, _9126, _9127, _9128, _9129, _9130, _9131, _9132, _9133, _9134, _9135, _9136, _9137, _9138);\n        vec3 param_10 = _8434;\n        vec3 param_11 = _8374;\n        float param_12 = _8441;\n        float param_13 = _8445;\n        vec3 param_14 = _8481;\n        FaLayers _8497 = fa_layers_setup(param_8, param_9, param_10, param_11, param_12, param_13, param_14);\n        f0 = param_14;\n        vec3 param_15 = _8434;\n        vec3 lit = (fa_indirect_diffuse(param_15) * _8474) * _9124;\n        if (_8497.on)\n        {\n            lit *= _8497.base_scale;\n        }\n        int _8519 = fa_cl_ndir + fa_cl_local;\n        float _8584;\n        for (int ln = 0; ln < _8519; ln++)\n        {\n            int param_16 = ln;\n            int _8532 = fa_cl_light(param_16);\n            int param_17 = _8532;\n            if (fa_baked_keep(param_17) <= 0.0)\n            {\n                continue;\n            }\n            int param_18 = _8532;\n            vec3 param_19 = fa_world_pos;\n            vec3 param_20 = _9088;\n            LightSample _8548 = fa_light_shadowed(param_18, param_19, param_20);\n            float _8556 = max(dot(_8434, _8548.direction), 0.0);\n            float _8562 = _8548.attenuation * _8548.shadow;\n            vec3 _8567 = normalize(_8548.direction + _8374);\n            float _8572 = max(dot(_8434, _8567), 0.0);\n            float _8577 = max(dot(_8374, _8567), 0.0);\n            if (fa_light_is_area)\n            {\n                if (_8497.on)\n                {\n                    _8584 = _8497.f90;\n                }\n                else\n                {\n                    _8584 = 1.0;\n                }\n                int param_21 = _8532;\n                vec3 param_22 = fa_world_pos;\n                vec3 param_23 = _8434;\n                vec3 param_24 = _8374;\n                vec3 param_25 = _8474;\n                vec3 param_26 = f0;\n                float param_27 = _8584;\n                float param_28 = _8445;\n                float param_29 = _8458;\n                float param_30 = _8562;\n                vec3 area = fa_area_shade(param_21, param_22, param_23, param_24, param_25, param_26, param_27, param_28, param_29, param_30);\n                if (_8497.on)\n                {\n                    FaLayers param_31 = _8497;\n                    vec3 param_32 = area;\n                    int param_33 = _8532;\n                    vec3 param_34 = _8434;\n                    vec3 param_35 = _8374;\n                    vec3 param_36 = _8548.direction;\n                    float param_37 = _8458;\n                    float param_38 = _8562;\n                    area = fa_area_layers(param_31, param_32, param_33, param_34, param_35, param_36, param_37, param_38);\n                }\n                lit += area;\n            }\n            else\n            {\n                if (_8497.on)\n                {\n                    FaLayers param_39 = _8497;\n                    vec3 param_40 = _8474;\n                    vec3 param_41 = f0;\n                    vec3 param_42 = _8434;\n                    vec3 param_43 = _8374;\n                    vec3 param_44 = _8548.direction;\n                    vec3 param_45 = _8567;\n                    float param_46 = _8556;\n                    float param_47 = _8458;\n                    float param_48 = _8572;\n                    float param_49 = _8577;\n                    float param_50 = _8449;\n                    float param_51 = _8453;\n                    int param_52 = _8532;\n                    lit += (fa_layers_light(param_39, param_40, param_41, param_42, param_43, param_44, param_45, param_46, param_47, param_48, param_49, param_50, param_51) * ((fa_light_rgb(param_52) * fa_light_tint) * _8562));\n                }\n                else\n                {\n                    float _8686 = ((_8572 * _8572) * (_8453 - 1.0)) + 1.0;\n                    int param_53 = _8532;\n                    lit += (((_8474 + (((f0 + ((vec3(1.0) - f0) * pow(1.0 - _8577, 5.0))) * (((_8453 / ((3.1415927410125732421875 * _8686) * _8686)) * (0.5 / max(mix((2.0 * _8556) * _8458, _8556 + _8458, _8449), 9.9999997473787516355514526367188e-05))) * 3.1415927410125732421875)) * step(9.9999997473787516355514526367188e-05, _8556))) * (fa_light_rgb(param_53) * fa_light_tint)) * (_8556 * _8562));\n                }\n            }\n        }\n        if (_8497.on)\n        {\n            FaLayers param_54 = _8497;\n            vec3 param_55 = _8434;\n            vec3 param_56 = _8374;\n            vec3 param_57 = f0;\n            float param_58 = _8445;\n            float param_59 = _9124;\n            lit += fa_layers_ibl(param_54, param_55, param_56, param_57, param_58, param_59);\n        }\n        else\n        {\n            vec3 param_60 = _8434;\n            vec3 param_61 = _8374;\n            vec3 param_62 = f0;\n            float param_63 = _8445;\n            lit += (fa_sky_reflection(param_60, param_61, param_62, param_63) * _9124);\n        }\n        if (_8465 > 0.0)\n        {\n            float _8784;\n            if (_8497.on)\n            {\n                _8784 = _8497.f90;\n            }\n            else\n            {\n                _8784 = 1.0;\n            }\n            float _8792;\n            if (_8497.on)\n            {\n                _8792 = _8497.base_scale;\n            }\n            else\n            {\n                _8792 = 1.0;\n            }\n            Surface param_64 = Surface(_9119, _9120, _9121, _9122, _9123, _9124, _9125, _9126, _9127, _9128, _9129, _9130, _9131, _9132, _9133, _9134, _9135, _9136, _9137, _9138);\n            vec3 param_65 = _8434;\n            vec3 param_66 = _8374;\n            float param_67 = _8445;\n            vec3 param_68 = f0;\n            float param_69 = _8784;\n            float param_70 = _8792;\n            float param_71 = _8465;\n            float param_72 = fa_tr_blend;\n            vec3 _8816 = fa_transmitted(param_64, param_65, param_66, param_67, param_68, param_69, param_70, param_71, param_72);\n            fa_tr_blend = param_72;\n            lit += _8816;\n        }\n        result = lit;\n    }\n    vec3 _8823 = result;\n    vec3 _8824 = _8823 + _9125;\n    result = _8824;\n    vec3 param_73 = _8824;\n    vec3 param_74 = fa_world_pos;\n    result = fa_shadow_debug(param_73, param_74);\n    bool _8833 = fa_mesh_fs_params[7].w > 0.0;\n    bool _8840;\n    if (!_8833)\n    {\n        _8840 = fa_mesh_fs_params[8].y > 0.0;\n    }\n    else\n    {\n        _8840 = _8833;\n    }\n    if (_8840)\n    {\n        vec3 _8849 = fa_world_pos - fa_mesh_fs_params[0].xyz;\n        float _8855 = dot(_8849, fa_mesh_fs_params[9].xyz);\n        bool _8859 = fa_mesh_fs_params[9].w > 0.5;\n        float _8860;\n        if (_8859)\n        {\n            _8860 = _8855;\n        }\n        else\n        {\n            _8860 = length(_8849);\n        }\n        float _8872 = _8860 - fa_mesh_fs_params[8].x;\n        if (_8872 > 0.0)\n        {\n            float _8881 = fa_mesh_fs_params[7].w * _8872;\n            float tau = _8881 * _8881;\n            if (fa_mesh_fs_params[8].y > 0.0)\n            {\n                float _8897;\n                if (_8859)\n                {\n                    _8897 = fa_world_pos.y - (fa_mesh_fs_params[9].y * _8855);\n                }\n                else\n                {\n                    _8897 = fa_mesh_fs_params[0].y;\n                }\n                float _8918 = mix(_8897, fa_world_pos.y, clamp(fa_mesh_fs_params[8].x / _8860, 0.0, 1.0));\n                float _8922 = fa_world_pos.y - _8918;\n                float _8927 = _8918 - fa_mesh_fs_params[8].z;\n                float _8932 = fa_world_pos.y - fa_mesh_fs_params[8].z;\n                bool _8935 = _8927 <= 0.0;\n                bool _8936 = !_8935;\n                bool _8942;\n                if (_8936)\n                {\n                    _8942 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _8942 = _8935;\n                }\n                float _8943;\n                if (_8942)\n                {\n                    _8943 = fa_mesh_fs_params[8].y;\n                }\n                else\n                {\n                    _8943 = fa_mesh_fs_params[8].y * exp(-min(fa_mesh_fs_params[8].w * _8927, 80.0));\n                }\n                bool _8970;\n                if (_8936)\n                {\n                    _8970 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _8970 = _8935;\n                }\n                float _8971;\n                if (_8970)\n                {\n                    _8971 = fa_mesh_fs_params[8].y * _8927;\n                }\n                else\n                {\n                    _8971 = (fa_mesh_fs_params[8].y * (1.0 - exp(-min(fa_mesh_fs_params[8].w * _8927, 80.0)))) / fa_mesh_fs_params[8].w;\n                }\n                bool _8996 = _8932 <= 0.0;\n                bool _9003;\n                if (!_8996)\n                {\n                    _9003 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _9003 = _8996;\n                }\n                float _9004;\n                if (_9003)\n                {\n                    _9004 = fa_mesh_fs_params[8].y * _8932;\n                }\n                else\n                {\n                    _9004 = (fa_mesh_fs_params[8].y * (1.0 - exp(-min(fa_mesh_fs_params[8].w * _8932, 80.0)))) / fa_mesh_fs_params[8].w;\n                }\n                float _9031;\n                if (abs(_8922) < 0.001000000047497451305389404296875)\n                {\n                    _9031 = _8943;\n                }\n                else\n                {\n                    _9031 = (_9004 - _8971) / _8922;\n                }\n                tau += (_8872 * max(_9031, 0.0));\n            }\n            result = mix(result, fa_mesh_fs_params[7].xyz, vec3(clamp(1.0 - exp(-clamp(tau, 0.0, 80.0)), 0.0, 1.0)));\n        }\n    }\n    if (fa_tr_blend > 0.0)\n    {\n        float _9067 = 1.0 - fa_tr_blend;\n        result /= vec3(_9067);\n        _9120 *= _9067;\n    }\n    fa_frag_color = vec4(result, _9120);\n}\n\n",
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
            "inst_name": "_8410",
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
      "vs": "#version 430\n\nstruct VertexData\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 color;\n    vec3 object_pos;\n};\n\nuniform vec4 fa_mesh_vs_params[11];\nuniform vec4 fa_vel_params[9];\nlayout(location = 0) out vec3 fa_world_pos;\nlayout(location = 1) out vec3 fa_world_normal;\nlayout(location = 2) out vec4 fa_world_tangent;\nlayout(location = 3) out vec2 fa_uv;\nlayout(location = 4) out vec4 fa_vertex_color;\nlayout(location = 5) out float fa_pre_depth;\nlayout(location = 6) out vec3 fa_pre_r0;\nlayout(location = 7) out vec3 fa_pre_r1;\nlayout(location = 8) out vec3 fa_pre_r2;\nlayout(location = 9) out vec3 fa_vel_cur;\nlayout(location = 10) out vec3 fa_vel_prev;\nlayout(location = 9) in vec4 fa_prev_r0;\nlayout(location = 10) in vec4 fa_prev_r1;\nlayout(location = 11) in vec4 fa_prev_r2;\nlayout(location = 5) in vec4 fa_inst_m0;\nlayout(location = 6) in vec4 fa_inst_m1;\nlayout(location = 7) in vec4 fa_inst_m2;\nlayout(location = 8) in vec4 fa_inst_m3;\nlayout(location = 0) in vec3 fa_position;\nlayout(location = 1) in vec3 fa_normal;\nlayout(location = 3) in vec4 fa_tangent;\nlayout(location = 2) in vec2 fa_texcoord0;\nlayout(location = 4) in vec4 fa_color;\nvec4 fa_vtime;\n\nvoid fa_inst_begin()\n{\n}\n\nvec4 fa_time_now()\n{\n    return fa_mesh_vs_params[9];\n}\n\nVertexData fa_vertex_data(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    vec3 _97 = cross(model[1].xyz, model[2].xyz);\n    float _101 = (dot(model[0].xyz, _97) < 0.0) ? (-1.0) : 1.0;\n    return VertexData((model * vec4(position, 1.0)).xyz, (((_97 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _101, vec4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _101), texcoord0 * fa_mesh_vs_params[8].xy, color, position);\n}\n\nmat4 fa_rows_to_mat4(vec4 r0, vec4 r1, vec4 r2)\n{\n    return mat4(vec4(r0.x, r1.x, r2.x, 0.0), vec4(r0.y, r1.y, r2.y, 0.0), vec4(r0.z, r1.z, r2.z, 0.0), vec4(r0.w, r1.w, r2.w, 1.0));\n}\n\nmat4 fa_prev_model()\n{\n    vec4 param = fa_prev_r0;\n    vec4 param_1 = fa_prev_r1;\n    vec4 param_2 = fa_prev_r2;\n    return fa_rows_to_mat4(param, param_1, param_2);\n}\n\nvoid fa_prepass_vertex(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color, bool has_prev)\n{\n    bool _231;\n    if (has_prev)\n    {\n        _231 = fa_vel_params[8].x > 0.5;\n    }\n    else\n    {\n        _231 = has_prev;\n    }\n    fa_vtime = fa_time_now();\n    mat4 param = model;\n    vec3 param_1 = position;\n    vec3 param_2 = normal;\n    vec4 param_3 = tangent;\n    vec2 param_4 = texcoord0;\n    vec4 param_5 = color;\n    VertexData _246 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    vec3 _458 = _246.world_pos;\n    mat4 _250 = mat4(fa_mesh_vs_params[4], fa_mesh_vs_params[5], fa_mesh_vs_params[6], fa_mesh_vs_params[7]);\n    vec4 _257 = vec4(_458, 1.0);\n    fa_world_pos = _458;\n    fa_world_normal = _246.world_normal;\n    fa_world_tangent = _246.world_tangent;\n    fa_uv = _246.uv;\n    fa_vertex_color = _246.color;\n    fa_pre_depth = -(_250 * _257).z;\n    fa_pre_r0 = vec3(_250[0].x, _250[1].x, _250[2].x);\n    fa_pre_r1 = vec3(_250[0].y, _250[1].y, _250[2].y);\n    fa_pre_r2 = vec3(_250[0].z, _250[1].z, _250[2].z);\n    gl_Position = mat4(fa_mesh_vs_params[0], fa_mesh_vs_params[1], fa_mesh_vs_params[2], fa_mesh_vs_params[3]) * _257;\n    fa_vel_cur = vec3(0.0, 0.0, 1.0);\n    fa_vel_prev = vec3(0.0);\n    if (_231)\n    {\n        vec4 _330 = vec4(position, 1.0);\n        fa_vel_cur = vec3((mat4(fa_vel_params[0], fa_vel_params[1], fa_vel_params[2], fa_vel_params[3]) * _257).xyw);\n        fa_vel_prev = vec3((mat4(fa_vel_params[4], fa_vel_params[5], fa_vel_params[6], fa_vel_params[7]) * vec4((_458 + (fa_prev_model() * _330).xyz) - (model * _330).xyz, 1.0)).xyw);\n    }\n}\n\nvoid main()\n{\n    fa_vtime = vec4(0.0);\n    fa_inst_begin();\n    mat4 param = mat4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3);\n    vec3 param_1 = fa_position;\n    vec3 param_2 = fa_normal;\n    vec4 param_3 = fa_tangent;\n    vec2 param_4 = fa_texcoord0;\n    vec4 param_5 = fa_color;\n    bool param_6 = true;\n    fa_prepass_vertex(param, param_1, param_2, param_3, param_4, param_5, param_6);\n}\n\n",
      "fs": "#version 430\n\nstruct SurfaceInput\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 vertex_color;\n    vec3 view_dir;\n    bool front_facing;\n};\n\nstruct Surface\n{\n    vec3 albedo;\n    float alpha;\n    vec3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    vec3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    vec3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    vec3 specular_color;\n    float transmission;\n    float thickness;\n    vec3 attenuation_color;\n    float attenuation_distance;\n};\n\nuniform vec4 fa_mesh_fs_params[53];\nuniform vec4 fa_material[1];\nlayout(binding = 0) uniform sampler2D fa_tex_fa_smp;\nlayout(binding = 1) uniform sampler2D fa_normal_tex_fa_smp;\nlayout(binding = 2) uniform sampler2D fa_mr_tex_fa_smp;\nlayout(binding = 3) uniform sampler2D fa_occlusion_tex_fa_smp;\nlayout(binding = 4) uniform sampler2D fa_emissive_tex_fa_smp;\n\nlayout(location = 0) in vec3 fa_world_pos;\nlayout(location = 1) in vec3 fa_world_normal;\nlayout(location = 2) in vec4 fa_world_tangent;\nlayout(location = 3) in vec2 fa_uv;\nlayout(location = 4) in vec4 fa_vertex_color;\nlayout(location = 6) in vec3 fa_pre_r0;\nlayout(location = 7) in vec3 fa_pre_r1;\nlayout(location = 8) in vec3 fa_pre_r2;\nlayout(location = 0) out vec4 fa_frag_color;\nlayout(location = 5) in float fa_pre_depth;\nlayout(location = 9) in vec3 fa_vel_cur;\nlayout(location = 10) in vec3 fa_vel_prev;\nlayout(location = 1) out vec2 fa_frag_velocity;\n\nvoid fa_inst_load()\n{\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nvec3 fa_linear_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_tex_fix(inout vec3 c, float mode)\n{\n    if (mode > 1.5)\n    {\n        vec3 param = c;\n        vec3 _218 = fa_linear_to_srgb(param);\n        c = _218;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            vec3 param_1 = c;\n            vec3 _227 = fa_srgb_to_linear(param_1);\n            c = _227;\n        }\n    }\n    return c;\n}\n\nvec3 fa_tangent_normal(SurfaceInput i, vec3 m)\n{\n    vec3 _58;\n    if (i.front_facing)\n    {\n        _58 = i.world_normal;\n    }\n    else\n    {\n        _58 = -i.world_normal;\n    }\n    vec3 _83 = normalize(i.world_tangent.xyz - (_58 * dot(_58, i.world_tangent.xyz)));\n    vec3 _111 = normalize(((_83 * m.x) + ((cross(_58, _83) * i.world_tangent.w) * m.y)) + (_58 * m.z));\n    vec3 _114;\n    if (i.front_facing)\n    {\n        _114 = _111;\n    }\n    else\n    {\n        _114 = -_111;\n    }\n    return _114;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    vec4 base_t = texture(fa_tex_fa_smp, i.uv, fa_mesh_fs_params[12].w);\n    float param = fa_mesh_fs_params[6].w;\n    float param_1 = 1.0;\n    vec3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    vec3 _270 = fa_tex_fix(param_2, param_3);\n    vec4 _890 = base_t;\n    _890.x = _270.x;\n    _890.y = _270.y;\n    _890.z = _270.z;\n    base_t = _890;\n    vec4 _286 = (_890 * fa_mesh_fs_params[2]) * i.vertex_color;\n    vec3 _845 = i.world_normal;\n    if (fa_mesh_fs_params[6].z > 0.5)\n    {\n        float param_4 = fa_mesh_fs_params[6].w;\n        float param_5 = 16.0;\n        vec3 param_6 = texture(fa_normal_tex_fa_smp, i.uv, fa_mesh_fs_params[12].w).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        vec3 _322 = fa_tex_fix(param_6, param_7);\n        vec3 _326 = (_322 * 2.0) - vec3(1.0);\n        vec2 _331 = _326.xy * fa_mesh_fs_params[6].x;\n        vec3 _898 = _326;\n        _898.x = _331.x;\n        _898.y = _331.y;\n        SurfaceInput param_8 = i;\n        vec3 param_9 = _898;\n        _845 = fa_tangent_normal(param_8, param_9);\n    }\n    vec4 mrt = texture(fa_mr_tex_fa_smp, i.uv, fa_mesh_fs_params[12].w);\n    float param_10 = fa_mesh_fs_params[6].w;\n    float param_11 = 64.0;\n    vec3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    vec3 _362 = fa_tex_fix(param_12, param_13);\n    vec4 _901 = mrt;\n    _901.x = _362.x;\n    _901.y = _362.y;\n    _901.z = _362.z;\n    mrt = _901;\n    vec4 _394 = texture(fa_occlusion_tex_fa_smp, i.uv, fa_mesh_fs_params[12].w);\n    float param_14 = fa_mesh_fs_params[6].w;\n    float param_15 = 256.0;\n    vec3 param_16 = _394.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    vec3 _406 = fa_tex_fix(param_16, param_17);\n    float param_18 = fa_mesh_fs_params[6].w;\n    float param_19 = 4.0;\n    vec3 param_20 = texture(fa_emissive_tex_fa_smp, i.uv, fa_mesh_fs_params[12].w).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    vec3 _438 = fa_tex_fix(param_20, param_21);\n    float _850 = fa_mesh_fs_params[20].x;\n    float _851 = fa_mesh_fs_params[20].y;\n    float _854 = fa_mesh_fs_params[20].z;\n    float _853 = fa_mesh_fs_params[21].w;\n    float _856 = fa_mesh_fs_params[22].x;\n    if (fa_mesh_fs_params[22].z > 0.5)\n    {\n        if (mod(fa_mesh_fs_params[22].z, 2.0) > 0.5)\n        {\n            _850 *= _406.y;\n            _851 *= _406.z;\n            _853 *= _394.w;\n        }\n        if (fa_mesh_fs_params[22].z > 1.5)\n        {\n            _854 *= mrt.x;\n            _856 *= mrt.w;\n        }\n    }\n    return Surface(_286.xyz, _286.w, _845, clamp(fa_mesh_fs_params[5].x * _362.z, 0.0, 1.0), clamp(fa_mesh_fs_params[5].y * _362.y, 0.0500000007450580596923828125, 1.0), 1.0 + (fa_mesh_fs_params[6].y * (_406.x - 1.0)), fa_mesh_fs_params[3].xyz + (fa_mesh_fs_params[4].xyz * _438), _850, _851, fa_mesh_fs_params[21].xyz, _853, _854, fa_mesh_fs_params[20].w, _856, fa_mesh_fs_params[22].y, fa_mesh_fs_params[23].xyz, fa_mesh_fs_params[30].x, fa_mesh_fs_params[30].y, fa_mesh_fs_params[31].xyz, fa_mesh_fs_params[30].z);\n}\n\nvoid surface(SurfaceInput i, Surface s)\n{\n}\n\nvoid fa_lod_dither()\n{\n    if (fa_mesh_fs_params[52].w != 0.0)\n    {\n        float _151 = fract(52.98291778564453125 * fract(dot(gl_FragCoord.xy, vec2(0.067110560834407806396484375, 0.005837149918079376220703125))));\n        bool _154;\n        if (fa_mesh_fs_params[52].w > 0.0)\n        {\n            _154 = _151 >= fa_mesh_fs_params[52].w;\n        }\n        else\n        {\n            _154 = _151 < (-fa_mesh_fs_params[52].w);\n        }\n        if (_154)\n        {\n            discard;\n        }\n    }\n}\n\nvoid main()\n{\n    fa_inst_load();\n    vec3 _740 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _740 = -_740;\n    }\n    vec3 _589 = normalize(fa_mesh_fs_params[0].xyz - fa_world_pos);\n    SurfaceInput param = SurfaceInput(fa_world_pos, _740, fa_world_tangent, fa_uv, fa_vertex_color, _589, gl_FrontFacing);\n    Surface _594 = fa_standard_surface(param);\n    vec3 _764 = _594.normal;\n    SurfaceInput param_1 = SurfaceInput(fa_world_pos, _740, fa_world_tangent, fa_uv, fa_vertex_color, _589, gl_FrontFacing);\n    Surface param_2 = _594;\n    surface(param_1, param_2);\n    _764 = param_2.normal;\n    if (param_2.alpha < fa_material[0].x)\n    {\n        discard;\n    }\n    fa_lod_dither();\n    vec3 _616 = normalize(_764);\n    vec3 _631 = normalize(vec3(dot(fa_pre_r0, _616), dot(fa_pre_r1, _616), dot(fa_pre_r2, _616)));\n    float _643 = _631.z;\n    vec2 e = _631.xy / vec2((abs(_631.x) + abs(_631.y)) + abs(_643));\n    if (_643 < 0.0)\n    {\n        e = (vec2(1.0) - abs(e.yx)) * vec2((e.x >= 0.0) ? 1.0 : (-1.0), (e.y >= 0.0) ? 1.0 : (-1.0));\n    }\n    fa_frag_color = vec4(min(fa_pre_depth, 60000.0), e, 1.0);\n    vec2 motion = vec2(1024.0);\n    bool _687 = fa_vel_cur.z > 9.9999997473787516355514526367188e-06;\n    bool _694;\n    if (_687)\n    {\n        _694 = fa_vel_prev.z > 9.9999997473787516355514526367188e-06;\n    }\n    else\n    {\n        _694 = _687;\n    }\n    if (_694)\n    {\n        motion = clamp(((vec2(fa_vel_prev.x, -fa_vel_prev.y) / vec2(fa_vel_prev.z)) * 0.5) - ((vec2(fa_vel_cur.x, -fa_vel_cur.y) / vec2(fa_vel_cur.z)) * 0.5), vec2(-4.0), vec2(4.0));\n    }\n    fa_frag_velocity = motion;\n}\n\n",
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
            "inst_name": "_605",
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
      "fs": "#version 430\n\nstruct SurfaceInput\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 vertex_color;\n    vec3 view_dir;\n    bool front_facing;\n};\n\nstruct Surface\n{\n    vec3 albedo;\n    float alpha;\n    vec3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    vec3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    vec3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    vec3 specular_color;\n    float transmission;\n    float thickness;\n    vec3 attenuation_color;\n    float attenuation_distance;\n};\n\nuniform vec4 fa_mesh_fs_params[53];\nuniform vec4 fa_material[1];\nlayout(binding = 0) uniform sampler2D fa_tex_fa_smp;\nlayout(binding = 1) uniform sampler2D fa_normal_tex_fa_smp;\nlayout(binding = 2) uniform sampler2D fa_mr_tex_fa_smp;\nlayout(binding = 3) uniform sampler2D fa_occlusion_tex_fa_smp;\nlayout(binding = 4) uniform sampler2D fa_emissive_tex_fa_smp;\n\nlayout(location = 0) in vec3 fa_world_pos;\nlayout(location = 1) in vec3 fa_world_normal;\nlayout(location = 2) in vec4 fa_world_tangent;\nlayout(location = 3) in vec2 fa_uv;\nlayout(location = 4) in vec4 fa_vertex_color;\nlayout(location = 6) in vec3 fa_pre_r0;\nlayout(location = 7) in vec3 fa_pre_r1;\nlayout(location = 8) in vec3 fa_pre_r2;\nlayout(location = 0) out vec4 fa_frag_color;\nlayout(location = 5) in float fa_pre_depth;\nlayout(location = 9) in vec3 fa_vel_cur;\nlayout(location = 10) in vec3 fa_vel_prev;\nlayout(location = 1) out vec2 fa_frag_velocity;\n\nvoid fa_inst_load()\n{\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nvec3 fa_linear_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_tex_fix(inout vec3 c, float mode)\n{\n    if (mode > 1.5)\n    {\n        vec3 param = c;\n        vec3 _218 = fa_linear_to_srgb(param);\n        c = _218;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            vec3 param_1 = c;\n            vec3 _227 = fa_srgb_to_linear(param_1);\n            c = _227;\n        }\n    }\n    return c;\n}\n\nvec3 fa_tangent_normal(SurfaceInput i, vec3 m)\n{\n    vec3 _58;\n    if (i.front_facing)\n    {\n        _58 = i.world_normal;\n    }\n    else\n    {\n        _58 = -i.world_normal;\n    }\n    vec3 _83 = normalize(i.world_tangent.xyz - (_58 * dot(_58, i.world_tangent.xyz)));\n    vec3 _111 = normalize(((_83 * m.x) + ((cross(_58, _83) * i.world_tangent.w) * m.y)) + (_58 * m.z));\n    vec3 _114;\n    if (i.front_facing)\n    {\n        _114 = _111;\n    }\n    else\n    {\n        _114 = -_111;\n    }\n    return _114;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    vec4 base_t = texture(fa_tex_fa_smp, i.uv, fa_mesh_fs_params[12].w);\n    float param = fa_mesh_fs_params[6].w;\n    float param_1 = 1.0;\n    vec3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    vec3 _270 = fa_tex_fix(param_2, param_3);\n    vec4 _890 = base_t;\n    _890.x = _270.x;\n    _890.y = _270.y;\n    _890.z = _270.z;\n    base_t = _890;\n    vec4 _286 = (_890 * fa_mesh_fs_params[2]) * i.vertex_color;\n    vec3 _845 = i.world_normal;\n    if (fa_mesh_fs_params[6].z > 0.5)\n    {\n        float param_4 = fa_mesh_fs_params[6].w;\n        float param_5 = 16.0;\n        vec3 param_6 = texture(fa_normal_tex_fa_smp, i.uv, fa_mesh_fs_params[12].w).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        vec3 _322 = fa_tex_fix(param_6, param_7);\n        vec3 _326 = (_322 * 2.0) - vec3(1.0);\n        vec2 _331 = _326.xy * fa_mesh_fs_params[6].x;\n        vec3 _898 = _326;\n        _898.x = _331.x;\n        _898.y = _331.y;\n        SurfaceInput param_8 = i;\n        vec3 param_9 = _898;\n        _845 = fa_tangent_normal(param_8, param_9);\n    }\n    vec4 mrt = texture(fa_mr_tex_fa_smp, i.uv, fa_mesh_fs_params[12].w);\n    float param_10 = fa_mesh_fs_params[6].w;\n    float param_11 = 64.0;\n    vec3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    vec3 _362 = fa_tex_fix(param_12, param_13);\n    vec4 _901 = mrt;\n    _901.x = _362.x;\n    _901.y = _362.y;\n    _901.z = _362.z;\n    mrt = _901;\n    vec4 _394 = texture(fa_occlusion_tex_fa_smp, i.uv, fa_mesh_fs_params[12].w);\n    float param_14 = fa_mesh_fs_params[6].w;\n    float param_15 = 256.0;\n    vec3 param_16 = _394.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    vec3 _406 = fa_tex_fix(param_16, param_17);\n    float param_18 = fa_mesh_fs_params[6].w;\n    float param_19 = 4.0;\n    vec3 param_20 = texture(fa_emissive_tex_fa_smp, i.uv, fa_mesh_fs_params[12].w).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    vec3 _438 = fa_tex_fix(param_20, param_21);\n    float _850 = fa_mesh_fs_params[20].x;\n    float _851 = fa_mesh_fs_params[20].y;\n    float _854 = fa_mesh_fs_params[20].z;\n    float _853 = fa_mesh_fs_params[21].w;\n    float _856 = fa_mesh_fs_params[22].x;\n    if (fa_mesh_fs_params[22].z > 0.5)\n    {\n        if (mod(fa_mesh_fs_params[22].z, 2.0) > 0.5)\n        {\n            _850 *= _406.y;\n            _851 *= _406.z;\n            _853 *= _394.w;\n        }\n        if (fa_mesh_fs_params[22].z > 1.5)\n        {\n            _854 *= mrt.x;\n            _856 *= mrt.w;\n        }\n    }\n    return Surface(_286.xyz, _286.w, _845, clamp(fa_mesh_fs_params[5].x * _362.z, 0.0, 1.0), clamp(fa_mesh_fs_params[5].y * _362.y, 0.0500000007450580596923828125, 1.0), 1.0 + (fa_mesh_fs_params[6].y * (_406.x - 1.0)), fa_mesh_fs_params[3].xyz + (fa_mesh_fs_params[4].xyz * _438), _850, _851, fa_mesh_fs_params[21].xyz, _853, _854, fa_mesh_fs_params[20].w, _856, fa_mesh_fs_params[22].y, fa_mesh_fs_params[23].xyz, fa_mesh_fs_params[30].x, fa_mesh_fs_params[30].y, fa_mesh_fs_params[31].xyz, fa_mesh_fs_params[30].z);\n}\n\nvoid surface(SurfaceInput i, Surface s)\n{\n}\n\nvoid fa_lod_dither()\n{\n    if (fa_mesh_fs_params[52].w != 0.0)\n    {\n        float _151 = fract(52.98291778564453125 * fract(dot(gl_FragCoord.xy, vec2(0.067110560834407806396484375, 0.005837149918079376220703125))));\n        bool _154;\n        if (fa_mesh_fs_params[52].w > 0.0)\n        {\n            _154 = _151 >= fa_mesh_fs_params[52].w;\n        }\n        else\n        {\n            _154 = _151 < (-fa_mesh_fs_params[52].w);\n        }\n        if (_154)\n        {\n            discard;\n        }\n    }\n}\n\nvoid main()\n{\n    fa_inst_load();\n    vec3 _740 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _740 = -_740;\n    }\n    vec3 _589 = normalize(fa_mesh_fs_params[0].xyz - fa_world_pos);\n    SurfaceInput param = SurfaceInput(fa_world_pos, _740, fa_world_tangent, fa_uv, fa_vertex_color, _589, gl_FrontFacing);\n    Surface _594 = fa_standard_surface(param);\n    vec3 _764 = _594.normal;\n    SurfaceInput param_1 = SurfaceInput(fa_world_pos, _740, fa_world_tangent, fa_uv, fa_vertex_color, _589, gl_FrontFacing);\n    Surface param_2 = _594;\n    surface(param_1, param_2);\n    _764 = param_2.normal;\n    if (param_2.alpha < fa_material[0].x)\n    {\n        discard;\n    }\n    fa_lod_dither();\n    vec3 _616 = normalize(_764);\n    vec3 _631 = normalize(vec3(dot(fa_pre_r0, _616), dot(fa_pre_r1, _616), dot(fa_pre_r2, _616)));\n    float _643 = _631.z;\n    vec2 e = _631.xy / vec2((abs(_631.x) + abs(_631.y)) + abs(_643));\n    if (_643 < 0.0)\n    {\n        e = (vec2(1.0) - abs(e.yx)) * vec2((e.x >= 0.0) ? 1.0 : (-1.0), (e.y >= 0.0) ? 1.0 : (-1.0));\n    }\n    fa_frag_color = vec4(min(fa_pre_depth, 60000.0), e, 1.0);\n    vec2 motion = vec2(1024.0);\n    bool _687 = fa_vel_cur.z > 9.9999997473787516355514526367188e-06;\n    bool _694;\n    if (_687)\n    {\n        _694 = fa_vel_prev.z > 9.9999997473787516355514526367188e-06;\n    }\n    else\n    {\n        _694 = _687;\n    }\n    if (_694)\n    {\n        motion = clamp(((vec2(fa_vel_prev.x, -fa_vel_prev.y) / vec2(fa_vel_prev.z)) * 0.5) - ((vec2(fa_vel_cur.x, -fa_vel_cur.y) / vec2(fa_vel_cur.z)) * 0.5), vec2(-4.0), vec2(4.0));\n    }\n    fa_frag_velocity = motion;\n}\n\n",
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
            "inst_name": "_605",
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
    },
    "shadow": {
      "vs": "#version 430\n\nstruct VertexData\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 color;\n    vec3 object_pos;\n};\n\nuniform vec4 fa_mesh_vs_params[11];\nlayout(location = 1) in vec4 fa_inst_m0;\nlayout(location = 2) in vec4 fa_inst_m1;\nlayout(location = 3) in vec4 fa_inst_m2;\nlayout(location = 4) in vec4 fa_inst_m3;\nlayout(location = 0) in vec3 fa_position;\nlayout(location = 5) in vec3 fa_normal;\nlayout(location = 7) in vec4 fa_tangent;\nlayout(location = 6) in vec2 fa_texcoord0;\nlayout(location = 8) in vec4 fa_color;\nlayout(location = 0) out vec3 fa_world_pos;\nlayout(location = 1) out vec3 fa_world_normal;\nlayout(location = 2) out vec4 fa_world_tangent;\nlayout(location = 3) out vec2 fa_uv;\nlayout(location = 4) out vec4 fa_vertex_color;\n\nvoid fa_inst_begin()\n{\n}\n\nVertexData fa_vertex_data(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    vec3 _60 = cross(model[1].xyz, model[2].xyz);\n    float _66 = (dot(model[0].xyz, _60) < 0.0) ? (-1.0) : 1.0;\n    return VertexData((model * vec4(position, 1.0)).xyz, (((_60 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _66, vec4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _66), texcoord0 * fa_mesh_vs_params[8].xy, color, position);\n}\n\nvoid main()\n{\n    fa_inst_begin();\n    mat4 param = mat4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3);\n    vec3 param_1 = fa_position;\n    vec3 param_2 = fa_normal;\n    vec4 param_3 = fa_tangent;\n    vec2 param_4 = fa_texcoord0;\n    vec4 param_5 = fa_color;\n    VertexData _190 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    vec3 _233 = _190.world_pos;\n    fa_world_pos = _233;\n    fa_world_normal = _190.world_normal;\n    fa_world_tangent = _190.world_tangent;\n    fa_uv = _190.uv;\n    fa_vertex_color = _190.color;\n    gl_Position = mat4(fa_mesh_vs_params[4], fa_mesh_vs_params[5], fa_mesh_vs_params[6], fa_mesh_vs_params[7]) * vec4(_233, 1.0);\n}\n\n",
      "fs": "#version 430\n\nstruct SurfaceInput\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 vertex_color;\n    vec3 view_dir;\n    bool front_facing;\n};\n\nstruct Surface\n{\n    vec3 albedo;\n    float alpha;\n    vec3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    vec3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    vec3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    vec3 specular_color;\n    float transmission;\n    float thickness;\n    vec3 attenuation_color;\n    float attenuation_distance;\n};\n\nuniform vec4 fa_mesh_fs_params[53];\nuniform vec4 fa_material[1];\nlayout(binding = 0) uniform sampler2D fa_tex_fa_smp;\nlayout(binding = 1) uniform sampler2D fa_normal_tex_fa_smp;\nlayout(binding = 2) uniform sampler2D fa_mr_tex_fa_smp;\nlayout(binding = 3) uniform sampler2D fa_occlusion_tex_fa_smp;\nlayout(binding = 4) uniform sampler2D fa_emissive_tex_fa_smp;\n\nlayout(location = 0) in vec3 fa_world_pos;\nlayout(location = 1) in vec3 fa_world_normal;\nlayout(location = 2) in vec4 fa_world_tangent;\nlayout(location = 3) in vec2 fa_uv;\nlayout(location = 4) in vec4 fa_vertex_color;\nlayout(location = 0) out vec4 fa_frag_color;\n\nvoid fa_inst_load()\n{\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nvec3 fa_linear_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_tex_fix(inout vec3 c, float mode)\n{\n    if (mode > 1.5)\n    {\n        vec3 param = c;\n        vec3 _172 = fa_linear_to_srgb(param);\n        c = _172;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            vec3 param_1 = c;\n            vec3 _181 = fa_srgb_to_linear(param_1);\n            c = _181;\n        }\n    }\n    return c;\n}\n\nvec3 fa_tangent_normal(SurfaceInput i, vec3 m)\n{\n    vec3 _56;\n    if (i.front_facing)\n    {\n        _56 = i.world_normal;\n    }\n    else\n    {\n        _56 = -i.world_normal;\n    }\n    vec3 _81 = normalize(i.world_tangent.xyz - (_56 * dot(_56, i.world_tangent.xyz)));\n    vec3 _109 = normalize(((_81 * m.x) + ((cross(_56, _81) * i.world_tangent.w) * m.y)) + (_56 * m.z));\n    vec3 _112;\n    if (i.front_facing)\n    {\n        _112 = _109;\n    }\n    else\n    {\n        _112 = -_109;\n    }\n    return _112;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    vec4 base_t = texture(fa_tex_fa_smp, i.uv, fa_mesh_fs_params[12].w);\n    float param = fa_mesh_fs_params[6].w;\n    float param_1 = 1.0;\n    vec3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    vec3 _230 = fa_tex_fix(param_2, param_3);\n    vec4 _733 = base_t;\n    _733.x = _230.x;\n    _733.y = _230.y;\n    _733.z = _230.z;\n    base_t = _733;\n    vec4 _246 = (_733 * fa_mesh_fs_params[2]) * i.vertex_color;\n    vec3 _694 = i.world_normal;\n    if (fa_mesh_fs_params[6].z > 0.5)\n    {\n        float param_4 = fa_mesh_fs_params[6].w;\n        float param_5 = 16.0;\n        vec3 param_6 = texture(fa_normal_tex_fa_smp, i.uv, fa_mesh_fs_params[12].w).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        vec3 _282 = fa_tex_fix(param_6, param_7);\n        vec3 _286 = (_282 * 2.0) - vec3(1.0);\n        vec2 _291 = _286.xy * fa_mesh_fs_params[6].x;\n        vec3 _741 = _286;\n        _741.x = _291.x;\n        _741.y = _291.y;\n        SurfaceInput param_8 = i;\n        vec3 param_9 = _741;\n        _694 = fa_tangent_normal(param_8, param_9);\n    }\n    vec4 mrt = texture(fa_mr_tex_fa_smp, i.uv, fa_mesh_fs_params[12].w);\n    float param_10 = fa_mesh_fs_params[6].w;\n    float param_11 = 64.0;\n    vec3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    vec3 _322 = fa_tex_fix(param_12, param_13);\n    vec4 _744 = mrt;\n    _744.x = _322.x;\n    _744.y = _322.y;\n    _744.z = _322.z;\n    mrt = _744;\n    vec4 _354 = texture(fa_occlusion_tex_fa_smp, i.uv, fa_mesh_fs_params[12].w);\n    float param_14 = fa_mesh_fs_params[6].w;\n    float param_15 = 256.0;\n    vec3 param_16 = _354.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    vec3 _366 = fa_tex_fix(param_16, param_17);\n    float param_18 = fa_mesh_fs_params[6].w;\n    float param_19 = 4.0;\n    vec3 param_20 = texture(fa_emissive_tex_fa_smp, i.uv, fa_mesh_fs_params[12].w).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    vec3 _398 = fa_tex_fix(param_20, param_21);\n    float _699 = fa_mesh_fs_params[20].x;\n    float _700 = fa_mesh_fs_params[20].y;\n    float _703 = fa_mesh_fs_params[20].z;\n    float _702 = fa_mesh_fs_params[21].w;\n    float _705 = fa_mesh_fs_params[22].x;\n    if (fa_mesh_fs_params[22].z > 0.5)\n    {\n        if (mod(fa_mesh_fs_params[22].z, 2.0) > 0.5)\n        {\n            _699 *= _366.y;\n            _700 *= _366.z;\n            _702 *= _354.w;\n        }\n        if (fa_mesh_fs_params[22].z > 1.5)\n        {\n            _703 *= mrt.x;\n            _705 *= mrt.w;\n        }\n    }\n    return Surface(_246.xyz, _246.w, _694, clamp(fa_mesh_fs_params[5].x * _322.z, 0.0, 1.0), clamp(fa_mesh_fs_params[5].y * _322.y, 0.0500000007450580596923828125, 1.0), 1.0 + (fa_mesh_fs_params[6].y * (_366.x - 1.0)), fa_mesh_fs_params[3].xyz + (fa_mesh_fs_params[4].xyz * _398), _699, _700, fa_mesh_fs_params[21].xyz, _702, _703, fa_mesh_fs_params[20].w, _705, fa_mesh_fs_params[22].y, fa_mesh_fs_params[23].xyz, fa_mesh_fs_params[30].x, fa_mesh_fs_params[30].y, fa_mesh_fs_params[31].xyz, fa_mesh_fs_params[30].z);\n}\n\nvoid surface(SurfaceInput i, Surface s)\n{\n}\n\nvoid main()\n{\n    fa_inst_load();\n    vec3 _589 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _589 = -_589;\n    }\n    vec3 _550 = normalize(fa_mesh_fs_params[0].xyz - fa_world_pos);\n    SurfaceInput param = SurfaceInput(fa_world_pos, _589, fa_world_tangent, fa_uv, fa_vertex_color, _550, gl_FrontFacing);\n    SurfaceInput param_1 = SurfaceInput(fa_world_pos, _589, fa_world_tangent, fa_uv, fa_vertex_color, _550, gl_FrontFacing);\n    Surface param_2 = fa_standard_surface(param);\n    surface(param_1, param_2);\n    if (param_2.alpha < fa_material[0].x)\n    {\n        discard;\n    }\n    fa_frag_color = vec4(gl_FragCoord.z, 0.0, 0.0, 1.0);\n}\n\n",
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
            "inst_name": "_214",
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
            "inst_name": "_566",
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
    "shadow_skin": {
      "vs": "#version 430\n\nstruct VertexData\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 color;\n    vec3 object_pos;\n};\n\nuniform vec4 fa_mesh_vs_params[11];\nuniform vec4 fa_skin[192];\nlayout(location = 1) in vec4 fa_inst_m0;\nlayout(location = 2) in vec4 fa_inst_m1;\nlayout(location = 3) in vec4 fa_inst_m2;\nlayout(location = 4) in vec4 fa_inst_m3;\nlayout(location = 5) in vec4 fa_joints;\nlayout(location = 6) in vec4 fa_weights;\nlayout(location = 0) in vec3 fa_position;\nlayout(location = 7) in vec3 fa_normal;\nlayout(location = 9) in vec4 fa_tangent;\nlayout(location = 8) in vec2 fa_texcoord0;\nlayout(location = 10) in vec4 fa_color;\nlayout(location = 0) out vec3 fa_world_pos;\nlayout(location = 1) out vec3 fa_world_normal;\nlayout(location = 2) out vec4 fa_world_tangent;\nlayout(location = 3) out vec2 fa_uv;\nlayout(location = 4) out vec4 fa_vertex_color;\n\nmat4 fa_skin_matrix(vec4 joints, vec4 weights)\n{\n    vec4 r0 = vec4(0.0);\n    vec4 r1 = vec4(0.0);\n    vec4 r2 = vec4(0.0);\n    for (int i = 0; i < 4; i++)\n    {\n        int _165 = int((joints[i] * 255.0) + 0.5) * 3;\n        r0 += (fa_skin[_165 * 1 + 0] * weights[i]);\n        r1 += (fa_skin[(_165 + 1) * 1 + 0] * weights[i]);\n        r2 += (fa_skin[(_165 + 2) * 1 + 0] * weights[i]);\n    }\n    return mat4(vec4(r0.x, r1.x, r2.x, 0.0), vec4(r0.y, r1.y, r2.y, 0.0), vec4(r0.z, r1.z, r2.z, 0.0), vec4(r0.w, r1.w, r2.w, 1.0));\n}\n\nvoid fa_inst_begin()\n{\n}\n\nVertexData fa_vertex_data(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    vec3 _65 = cross(model[1].xyz, model[2].xyz);\n    float _71 = (dot(model[0].xyz, _65) < 0.0) ? (-1.0) : 1.0;\n    return VertexData((model * vec4(position, 1.0)).xyz, (((_65 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _71, vec4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _71), texcoord0 * fa_mesh_vs_params[8].xy, color, position);\n}\n\nvoid main()\n{\n    vec4 param = fa_joints;\n    vec4 param_1 = fa_weights;\n    fa_inst_begin();\n    mat4 param_2 = mat4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3) * fa_skin_matrix(param, param_1);\n    vec3 param_3 = fa_position;\n    vec3 param_4 = fa_normal;\n    vec4 param_5 = fa_tangent;\n    vec2 param_6 = fa_texcoord0;\n    vec4 param_7 = fa_color;\n    VertexData _311 = fa_vertex_data(param_2, param_3, param_4, param_5, param_6, param_7);\n    vec3 _354 = _311.world_pos;\n    fa_world_pos = _354;\n    fa_world_normal = _311.world_normal;\n    fa_world_tangent = _311.world_tangent;\n    fa_uv = _311.uv;\n    fa_vertex_color = _311.color;\n    gl_Position = mat4(fa_mesh_vs_params[4], fa_mesh_vs_params[5], fa_mesh_vs_params[6], fa_mesh_vs_params[7]) * vec4(_354, 1.0);\n}\n\n",
      "fs": "#version 430\n\nstruct SurfaceInput\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 vertex_color;\n    vec3 view_dir;\n    bool front_facing;\n};\n\nstruct Surface\n{\n    vec3 albedo;\n    float alpha;\n    vec3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    vec3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    vec3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    vec3 specular_color;\n    float transmission;\n    float thickness;\n    vec3 attenuation_color;\n    float attenuation_distance;\n};\n\nuniform vec4 fa_mesh_fs_params[53];\nuniform vec4 fa_material[1];\nlayout(binding = 0) uniform sampler2D fa_tex_fa_smp;\nlayout(binding = 1) uniform sampler2D fa_normal_tex_fa_smp;\nlayout(binding = 2) uniform sampler2D fa_mr_tex_fa_smp;\nlayout(binding = 3) uniform sampler2D fa_occlusion_tex_fa_smp;\nlayout(binding = 4) uniform sampler2D fa_emissive_tex_fa_smp;\n\nlayout(location = 0) in vec3 fa_world_pos;\nlayout(location = 1) in vec3 fa_world_normal;\nlayout(location = 2) in vec4 fa_world_tangent;\nlayout(location = 3) in vec2 fa_uv;\nlayout(location = 4) in vec4 fa_vertex_color;\nlayout(location = 0) out vec4 fa_frag_color;\n\nvoid fa_inst_load()\n{\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nvec3 fa_linear_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_tex_fix(inout vec3 c, float mode)\n{\n    if (mode > 1.5)\n    {\n        vec3 param = c;\n        vec3 _172 = fa_linear_to_srgb(param);\n        c = _172;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            vec3 param_1 = c;\n            vec3 _181 = fa_srgb_to_linear(param_1);\n            c = _181;\n        }\n    }\n    return c;\n}\n\nvec3 fa_tangent_normal(SurfaceInput i, vec3 m)\n{\n    vec3 _56;\n    if (i.front_facing)\n    {\n        _56 = i.world_normal;\n    }\n    else\n    {\n        _56 = -i.world_normal;\n    }\n    vec3 _81 = normalize(i.world_tangent.xyz - (_56 * dot(_56, i.world_tangent.xyz)));\n    vec3 _109 = normalize(((_81 * m.x) + ((cross(_56, _81) * i.world_tangent.w) * m.y)) + (_56 * m.z));\n    vec3 _112;\n    if (i.front_facing)\n    {\n        _112 = _109;\n    }\n    else\n    {\n        _112 = -_109;\n    }\n    return _112;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    vec4 base_t = texture(fa_tex_fa_smp, i.uv, fa_mesh_fs_params[12].w);\n    float param = fa_mesh_fs_params[6].w;\n    float param_1 = 1.0;\n    vec3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    vec3 _230 = fa_tex_fix(param_2, param_3);\n    vec4 _733 = base_t;\n    _733.x = _230.x;\n    _733.y = _230.y;\n    _733.z = _230.z;\n    base_t = _733;\n    vec4 _246 = (_733 * fa_mesh_fs_params[2]) * i.vertex_color;\n    vec3 _694 = i.world_normal;\n    if (fa_mesh_fs_params[6].z > 0.5)\n    {\n        float param_4 = fa_mesh_fs_params[6].w;\n        float param_5 = 16.0;\n        vec3 param_6 = texture(fa_normal_tex_fa_smp, i.uv, fa_mesh_fs_params[12].w).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        vec3 _282 = fa_tex_fix(param_6, param_7);\n        vec3 _286 = (_282 * 2.0) - vec3(1.0);\n        vec2 _291 = _286.xy * fa_mesh_fs_params[6].x;\n        vec3 _741 = _286;\n        _741.x = _291.x;\n        _741.y = _291.y;\n        SurfaceInput param_8 = i;\n        vec3 param_9 = _741;\n        _694 = fa_tangent_normal(param_8, param_9);\n    }\n    vec4 mrt = texture(fa_mr_tex_fa_smp, i.uv, fa_mesh_fs_params[12].w);\n    float param_10 = fa_mesh_fs_params[6].w;\n    float param_11 = 64.0;\n    vec3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    vec3 _322 = fa_tex_fix(param_12, param_13);\n    vec4 _744 = mrt;\n    _744.x = _322.x;\n    _744.y = _322.y;\n    _744.z = _322.z;\n    mrt = _744;\n    vec4 _354 = texture(fa_occlusion_tex_fa_smp, i.uv, fa_mesh_fs_params[12].w);\n    float param_14 = fa_mesh_fs_params[6].w;\n    float param_15 = 256.0;\n    vec3 param_16 = _354.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    vec3 _366 = fa_tex_fix(param_16, param_17);\n    float param_18 = fa_mesh_fs_params[6].w;\n    float param_19 = 4.0;\n    vec3 param_20 = texture(fa_emissive_tex_fa_smp, i.uv, fa_mesh_fs_params[12].w).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    vec3 _398 = fa_tex_fix(param_20, param_21);\n    float _699 = fa_mesh_fs_params[20].x;\n    float _700 = fa_mesh_fs_params[20].y;\n    float _703 = fa_mesh_fs_params[20].z;\n    float _702 = fa_mesh_fs_params[21].w;\n    float _705 = fa_mesh_fs_params[22].x;\n    if (fa_mesh_fs_params[22].z > 0.5)\n    {\n        if (mod(fa_mesh_fs_params[22].z, 2.0) > 0.5)\n        {\n            _699 *= _366.y;\n            _700 *= _366.z;\n            _702 *= _354.w;\n        }\n        if (fa_mesh_fs_params[22].z > 1.5)\n        {\n            _703 *= mrt.x;\n            _705 *= mrt.w;\n        }\n    }\n    return Surface(_246.xyz, _246.w, _694, clamp(fa_mesh_fs_params[5].x * _322.z, 0.0, 1.0), clamp(fa_mesh_fs_params[5].y * _322.y, 0.0500000007450580596923828125, 1.0), 1.0 + (fa_mesh_fs_params[6].y * (_366.x - 1.0)), fa_mesh_fs_params[3].xyz + (fa_mesh_fs_params[4].xyz * _398), _699, _700, fa_mesh_fs_params[21].xyz, _702, _703, fa_mesh_fs_params[20].w, _705, fa_mesh_fs_params[22].y, fa_mesh_fs_params[23].xyz, fa_mesh_fs_params[30].x, fa_mesh_fs_params[30].y, fa_mesh_fs_params[31].xyz, fa_mesh_fs_params[30].z);\n}\n\nvoid surface(SurfaceInput i, Surface s)\n{\n}\n\nvoid main()\n{\n    fa_inst_load();\n    vec3 _589 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _589 = -_589;\n    }\n    vec3 _550 = normalize(fa_mesh_fs_params[0].xyz - fa_world_pos);\n    SurfaceInput param = SurfaceInput(fa_world_pos, _589, fa_world_tangent, fa_uv, fa_vertex_color, _550, gl_FrontFacing);\n    SurfaceInput param_1 = SurfaceInput(fa_world_pos, _589, fa_world_tangent, fa_uv, fa_vertex_color, _550, gl_FrontFacing);\n    Surface param_2 = fa_standard_surface(param);\n    surface(param_1, param_2);\n    if (param_2.alpha < fa_material[0].x)\n    {\n        discard;\n    }\n    fa_frag_color = vec4(gl_FragCoord.z, 0.0, 0.0, 1.0);\n}\n\n",
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
            "inst_name": "_214",
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
            "inst_name": "_566",
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
