{
  "format": "factoria.shader/1",
  "engine": "0.38.0",
  "template": "4f7d190a643df7eea422f9bce37d2bb8920145f92f7e586baf62c54f579868ea",
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
      "fs": "#version 430\n\nstruct SurfaceInput\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 vertex_color;\n    vec3 view_dir;\n    bool front_facing;\n};\n\nstruct LightSample\n{\n    vec3 direction;\n    vec3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct Surface\n{\n    vec3 albedo;\n    float alpha;\n    vec3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    vec3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    vec3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    vec3 specular_color;\n    float transmission;\n    float thickness;\n    vec3 attenuation_color;\n    float attenuation_distance;\n};\n\nstruct FaLayers\n{\n    bool on;\n    float f90;\n    float keep;\n    float base_scale;\n    float coat;\n    float coat_rough;\n    float coat_alpha;\n    float coat_a2;\n    vec3 nc;\n    float coat_ndv;\n    bool sheen_on;\n    vec3 sheen;\n    float sheen_rough;\n    float sheen_alpha;\n    float sheen_scale;\n    float sheen_e;\n    float aniso;\n    vec3 t;\n    vec3 b;\n    float at;\n    float ab;\n};\n\nconst float _4850[63] = float[](1.0, 1.0, 1.0, 0.4790000021457672119140625, 0.11699999868869781494140625, 0.01200000010430812835693359375, 0.0, 0.0, 0.0, 1.0, 1.0, 1.0, 0.578000009059906005859375, 0.19300000369548797607421875, 0.0350000001490116119384765625, 0.0030000000260770320892333984375, 0.0, 0.0, 1.0, 1.0, 1.0, 0.6740000247955322265625, 0.3459999859333038330078125, 0.1319999992847442626953125, 0.032999999821186065673828125, 0.0040000001899898052215576171875, 0.0, 0.971000015735626220703125, 0.954999983310699462890625, 0.828999996185302734375, 0.63999998569488525390625, 0.42599999904632568359375, 0.24500000476837158203125, 0.115000002086162567138671875, 0.037000000476837158203125, 0.0030000000260770320892333984375, 0.7469999790191650390625, 0.737999975681304931640625, 0.670000016689300537109375, 0.563000023365020751953125, 0.4309999942779541015625, 0.3039999902248382568359375, 0.1940000057220458984375, 0.1019999980926513671875, 0.0309999994933605194091796875, 0.614000022411346435546875, 0.609000027179718017578125, 0.566999971866607666015625, 0.499000012874603271484375, 0.412000000476837158203125, 0.32400000095367431640625, 0.240999996662139892578125, 0.162000000476837158203125, 0.087999999523162841796875, 0.538999974727630615234375, 0.535000026226043701171875, 0.505999982357025146484375, 0.4569999873638153076171875, 0.393999993801116943359375, 0.328999996185302734375, 0.2660000026226043701171875, 0.203999996185302734375, 0.14200000464916229248046875);\n\nuniform vec4 fa_mesh_fs_params[54];\nuniform vec4 fa_shadows[30];\nuniform vec4 fa_material[1];\nlayout(binding = 0) uniform sampler2D fa_light_tex_fa_shadow_smp;\nlayout(binding = 1) uniform sampler2D fa_tex_fa_smp;\nlayout(binding = 2) uniform sampler2D fa_normal_tex_fa_smp;\nlayout(binding = 3) uniform sampler2D fa_mr_tex_fa_smp;\nlayout(binding = 4) uniform sampler2D fa_occlusion_tex_fa_smp;\nlayout(binding = 5) uniform sampler2D fa_emissive_tex_fa_smp;\nlayout(binding = 6) uniform sampler2D mask_mask_smp;\nlayout(binding = 7) uniform sampler2D fa_decal_tex_fa_env_smp;\nlayout(binding = 8) uniform sampler2D fa_lightmap_fa_env_smp;\nlayout(binding = 9) uniform sampler2D fa_probe_atlas_fa_env_smp;\nlayout(binding = 10) uniform sampler2D fa_light_atlas_fa_env_smp;\nlayout(binding = 11) uniform sampler2D fa_screen_tex_fa_shadow_smp;\nlayout(binding = 12) uniform sampler2D fa_shadow_tex_fa_shadow_smp;\n\nlayout(location = 0) in vec3 fa_world_pos;\nlayout(location = 5) in vec3 fa_lm;\nlayout(location = 1) in vec3 fa_world_normal;\nlayout(location = 2) in vec4 fa_world_tangent;\nlayout(location = 3) in vec2 fa_uv;\nlayout(location = 4) in vec4 fa_vertex_color;\nlayout(location = 0) out vec4 fa_frag_color;\nfloat fa_rt_slope;\nvec3 fa_light_tint;\nbool fa_light_is_area;\nint fa_cl_ndir;\nint fa_cl_slot;\nint fa_cl_local;\n\nvoid fa_inst_load()\n{\n}\n\nvec4 fa_light_texel(int t)\n{\n    return texelFetch(fa_light_tex_fa_shadow_smp, ivec2(t & 1023, t >> 10), 0);\n}\n\nvec4 fa_cluster_texel(vec3 world_pos)\n{\n    bool _1637 = fa_mesh_fs_params[19].x < 0.0;\n    bool _1644;\n    if (!_1637)\n    {\n        _1644 = fa_mesh_fs_params[19].w < 1.0;\n    }\n    else\n    {\n        _1644 = _1637;\n    }\n    bool _1652;\n    if (!_1644)\n    {\n        _1652 = fa_mesh_fs_params[18].x < 1.0;\n    }\n    else\n    {\n        _1652 = _1644;\n    }\n    bool _1659;\n    if (!_1652)\n    {\n        _1659 = fa_mesh_fs_params[18].y < 1.0;\n    }\n    else\n    {\n        _1659 = _1652;\n    }\n    bool _1666;\n    if (!_1659)\n    {\n        _1666 = fa_mesh_fs_params[19].y < 1.0;\n    }\n    else\n    {\n        _1666 = _1659;\n    }\n    if (_1666)\n    {\n        return vec4(0.0);\n    }\n    vec4 _1676 = vec4(world_pos, 1.0);\n    float _1682 = dot(fa_mesh_fs_params[16], _1676);\n    if (!(_1682 > 9.9999999747524270787835121154785e-07))\n    {\n        return vec4(0.0);\n    }\n    vec2 _1704 = vec2(dot(fa_mesh_fs_params[14], _1676), dot(fa_mesh_fs_params[15], _1676)) / vec2(_1682);\n    int _1708 = int(fa_mesh_fs_params[18].x);\n    int _1712 = int(fa_mesh_fs_params[18].y);\n    int param = (int(fa_mesh_fs_params[19].x) + (((clamp(int(floor(log2(max(dot(fa_mesh_fs_params[17].xyz, world_pos) + fa_mesh_fs_params[17].w, fa_mesh_fs_params[18].w) / fa_mesh_fs_params[18].w) * fa_mesh_fs_params[18].z)), 0, int(fa_mesh_fs_params[19].y) - 1) * _1712) + clamp(int(floor(((_1704.y * 0.5) + 0.5) * fa_mesh_fs_params[18].y)), 0, _1712 - 1)) * _1708)) + clamp(int(floor(((_1704.x * 0.5) + 0.5) * fa_mesh_fs_params[18].x)), 0, _1708 - 1);\n    return fa_light_texel(param);\n}\n\nivec2 fa_cluster_lookup(vec3 world_pos)\n{\n    vec3 param = world_pos;\n    vec4 _1788 = fa_cluster_texel(param);\n    return ivec2(int(_1788.x), int(_1788.y));\n}\n\nvoid fa_cluster_begin(vec3 world_pos)\n{\n    float _6484 = dot(fa_mesh_fs_params[29].xyz, world_pos) + fa_mesh_fs_params[29].w;\n    float _6487 = fwidth(_6484);\n    bool _6490 = fa_mesh_fs_params[25].y > 0.5;\n    bool _6497;\n    if (!_6490)\n    {\n        _6497 = fa_mesh_fs_params[25].w > 0.5;\n    }\n    else\n    {\n        _6497 = _6490;\n    }\n    if (_6497)\n    {\n        fa_rt_slope = min(1.5 * _6487, 0.100000001490116119384765625 * _6484);\n    }\n    fa_cl_ndir = int(fa_mesh_fs_params[19].z);\n    vec3 param = world_pos;\n    ivec2 _6513 = fa_cluster_lookup(param);\n    fa_cl_slot = _6513.x;\n    fa_cl_local = _6513.y;\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nvec3 fa_linear_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_tex_fix(inout vec3 c, float mode)\n{\n    if (mode > 1.5)\n    {\n        vec3 param = c;\n        vec3 _7683 = fa_linear_to_srgb(param);\n        c = _7683;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            vec3 param_1 = c;\n            vec3 _7691 = fa_srgb_to_linear(param_1);\n            c = _7691;\n        }\n    }\n    return c;\n}\n\nvec3 fa_tangent_normal(SurfaceInput i, vec3 m)\n{\n    vec3 _544;\n    if (i.front_facing)\n    {\n        _544 = i.world_normal;\n    }\n    else\n    {\n        _544 = -i.world_normal;\n    }\n    vec3 _568 = normalize(i.world_tangent.xyz - (_544 * dot(_544, i.world_tangent.xyz)));\n    vec3 _595 = normalize(((_568 * m.x) + ((cross(_544, _568) * i.world_tangent.w) * m.y)) + (_544 * m.z));\n    vec3 _598;\n    if (i.front_facing)\n    {\n        _598 = _595;\n    }\n    else\n    {\n        _598 = -_595;\n    }\n    return _598;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    vec4 base_t = texture(fa_tex_fa_smp, i.uv, fa_mesh_fs_params[12].w);\n    float param = fa_mesh_fs_params[6].w;\n    float param_1 = 1.0;\n    vec3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    vec3 _7723 = fa_tex_fix(param_2, param_3);\n    vec4 _10105 = base_t;\n    _10105.x = _7723.x;\n    _10105.y = _7723.y;\n    _10105.z = _7723.z;\n    base_t = _10105;\n    vec4 _7737 = (_10105 * fa_mesh_fs_params[2]) * i.vertex_color;\n    vec3 _9855 = i.world_normal;\n    if (fa_mesh_fs_params[6].z > 0.5)\n    {\n        float param_4 = fa_mesh_fs_params[6].w;\n        float param_5 = 16.0;\n        vec3 param_6 = texture(fa_normal_tex_fa_smp, i.uv, fa_mesh_fs_params[12].w).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        vec3 _7771 = fa_tex_fix(param_6, param_7);\n        vec3 _7774 = (_7771 * 2.0) - vec3(1.0);\n        vec2 _7779 = _7774.xy * fa_mesh_fs_params[6].x;\n        vec3 _10113 = _7774;\n        _10113.x = _7779.x;\n        _10113.y = _7779.y;\n        SurfaceInput param_8 = i;\n        vec3 param_9 = _10113;\n        _9855 = fa_tangent_normal(param_8, param_9);\n    }\n    vec4 mrt = texture(fa_mr_tex_fa_smp, i.uv, fa_mesh_fs_params[12].w);\n    float param_10 = fa_mesh_fs_params[6].w;\n    float param_11 = 64.0;\n    vec3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    vec3 _7809 = fa_tex_fix(param_12, param_13);\n    vec4 _10116 = mrt;\n    _10116.x = _7809.x;\n    _10116.y = _7809.y;\n    _10116.z = _7809.z;\n    mrt = _10116;\n    vec4 _7839 = texture(fa_occlusion_tex_fa_smp, i.uv, fa_mesh_fs_params[12].w);\n    float param_14 = fa_mesh_fs_params[6].w;\n    float param_15 = 256.0;\n    vec3 param_16 = _7839.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    vec3 _7850 = fa_tex_fix(param_16, param_17);\n    float param_18 = fa_mesh_fs_params[6].w;\n    float param_19 = 4.0;\n    vec3 param_20 = texture(fa_emissive_tex_fa_smp, i.uv, fa_mesh_fs_params[12].w).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    vec3 _7882 = fa_tex_fix(param_20, param_21);\n    float _9860 = fa_mesh_fs_params[20].x;\n    float _9861 = fa_mesh_fs_params[20].y;\n    float _9864 = fa_mesh_fs_params[20].z;\n    float _9863 = fa_mesh_fs_params[21].w;\n    float _9866 = fa_mesh_fs_params[22].x;\n    if (fa_mesh_fs_params[22].z > 0.5)\n    {\n        if (mod(fa_mesh_fs_params[22].z, 2.0) > 0.5)\n        {\n            _9860 *= _7850.y;\n            _9861 *= _7850.z;\n            _9863 *= _7839.w;\n        }\n        if (fa_mesh_fs_params[22].z > 1.5)\n        {\n            _9864 *= mrt.x;\n            _9866 *= mrt.w;\n        }\n    }\n    return Surface(_7737.xyz, _7737.w, _9855, clamp(fa_mesh_fs_params[5].x * _7809.z, 0.0, 1.0), clamp(fa_mesh_fs_params[5].y * _7809.y, 0.0500000007450580596923828125, 1.0), 1.0 + (fa_mesh_fs_params[6].y * (_7850.x - 1.0)), fa_mesh_fs_params[3].xyz + (fa_mesh_fs_params[4].xyz * _7882), _9860, _9861, fa_mesh_fs_params[21].xyz, _9863, _9864, fa_mesh_fs_params[20].w, _9866, fa_mesh_fs_params[22].y, fa_mesh_fs_params[23].xyz, fa_mesh_fs_params[30].x, fa_mesh_fs_params[30].y, fa_mesh_fs_params[31].xyz, fa_mesh_fs_params[30].z);\n}\n\nvoid surface(SurfaceInput i, inout Surface s)\n{\n    s.alpha = texture(mask_mask_smp, i.uv * 2.0).x;\n}\n\nvec4 fa_decal_tile(vec4 rect, vec2 uv, vec2 atlas, vec2 ddx, vec2 ddy)\n{\n    vec2 _1868 = rect.zw - rect.xy;\n    vec2 _1872 = _1868 * atlas;\n    vec2 _1876 = ddx * _1872;\n    vec2 _1880 = ddy * _1872;\n    return textureLod(fa_decal_tex_fa_env_smp, rect.xy + (clamp(uv, vec2(0.0), vec2(1.0)) * _1868), clamp(0.5 * log2(max(max(dot(_1876, _1876), dot(_1880, _1880)), 9.9999999392252902907785028219223e-09)), 0.0, 3.0));\n}\n\nvec3 fa_dc_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_dc_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvoid fa_apply_decals(vec3 world_pos, vec3 geo_normal, inout vec3 albedo, inout vec3 normal)\n{\n    bool _1913 = fa_mesh_fs_params[10].y < 0.5;\n    bool _1920;\n    if (!_1913)\n    {\n        _1920 = fa_mesh_fs_params[10].w < 0.5;\n    }\n    else\n    {\n        _1920 = _1913;\n    }\n    if (_1920)\n    {\n        return;\n    }\n    vec3 _1926 = dFdx(world_pos);\n    vec3 _1929 = dFdy(world_pos);\n    vec3 param = world_pos;\n    vec4 _1933 = fa_cluster_texel(param);\n    int _1937 = int(_1933.w);\n    if (_1937 < 1)\n    {\n        return;\n    }\n    int _1947 = int(fa_mesh_fs_params[10].y + 0.5);\n    int param_1 = _1947;\n    vec4 _1951 = fa_light_texel(param_1);\n    vec2 _1954 = _1951.yz;\n    int _1958 = int(_1951.w);\n    int param_2 = _1947 + 1;\n    vec4 _1963 = fa_light_texel(param_2);\n    float _1964 = _1963.x;\n    int _1970 = int(fa_mesh_fs_params[10].w + 0.5) - 1;\n    int _1974 = int(_1933.z);\n    vec3 _2239;\n    for (int k = 0; k < _1937; k++)\n    {\n        int _1987 = _1974 + k;\n        int param_3 = _1958 + (_1987 >> 2);\n        int _2004 = (_1947 + 2) + (int(fa_light_texel(param_3)[_1987 & 3]) * 7);\n        int param_4 = _2004 + 6;\n        vec4 _2009 = fa_light_texel(param_4);\n        if (((int(_2009.w + 0.5) >> _1970) & 1) == 0)\n        {\n            continue;\n        }\n        int param_5 = _2004;\n        vec4 _2024 = fa_light_texel(param_5);\n        int param_6 = _2004 + 1;\n        vec4 _2029 = fa_light_texel(param_6);\n        int param_7 = _2004 + 2;\n        vec4 _2034 = fa_light_texel(param_7);\n        vec3 _2037 = _2024.xyz;\n        float _2042 = dot(_2037, world_pos) + _2024.w;\n        vec3 _2044 = _2029.xyz;\n        float _2049 = dot(_2044, world_pos) + _2029.w;\n        vec3 _2051 = _2034.xyz;\n        float _2056 = dot(_2051, world_pos) + _2034.w;\n        bool _2061 = abs(_2042) > 0.5;\n        bool _2069;\n        if (!_2061)\n        {\n            _2069 = abs(_2049) > 0.5;\n        }\n        else\n        {\n            _2069 = _2061;\n        }\n        bool _2077;\n        if (!_2069)\n        {\n            _2077 = abs(_2056) > 0.5;\n        }\n        else\n        {\n            _2077 = _2069;\n        }\n        if (_2077)\n        {\n            continue;\n        }\n        float _2092 = clamp(dot(geo_normal, normalize(_2051)) * _2009.z, 0.0, 1.0);\n        if (_2092 <= 0.0)\n        {\n            continue;\n        }\n        float _2112 = (clamp((0.5 - abs(_2056)) * 10.0, 0.0, 1.0) * _2092) * _2009.x;\n        vec2 _2120 = vec2(_2042 + 0.5, 0.5 - _2049);\n        vec2 _2130 = vec2(dot(_2037, _1926), dot(_2044, _1926));\n        vec2 _2140 = vec2(dot(_2037, _1929), dot(_2044, _1929));\n        int param_8 = _2004 + 5;\n        vec4 _2145 = fa_light_texel(param_8);\n        int param_9 = _2004 + 3;\n        vec4 _2150 = fa_light_texel(param_9);\n        int param_10 = _2004 + 4;\n        vec4 _2155 = fa_light_texel(param_10);\n        float tex_a = 1.0;\n        vec3 col = _2145.xyz;\n        bool _2165 = _2150.z > _2150.x;\n        if (_2165)\n        {\n            vec4 param_11 = _2150;\n            vec2 param_12 = _2120;\n            vec2 param_13 = _1954;\n            vec2 param_14 = _2130;\n            vec2 param_15 = _2140;\n            vec4 tx = fa_decal_tile(param_11, param_12, param_13, param_14, param_15);\n            if ((_1964 > 0.5) && (_1964 < 1.5))\n            {\n                vec3 param_16 = tx.xyz;\n                vec3 _2191 = fa_dc_to_linear(param_16);\n                vec4 _9943 = tx;\n                _9943.x = _2191.x;\n                _9943.y = _2191.y;\n                _9943.z = _2191.z;\n                tx = _9943;\n            }\n            col *= tx.xyz;\n            tex_a = tx.w;\n        }\n        albedo = mix(albedo, col, vec3(clamp((_2112 * tex_a) * _2145.w, 0.0, 1.0)));\n        if (_2155.z > _2155.x)\n        {\n            vec4 param_17 = _2155;\n            vec2 param_18 = _2120;\n            vec2 param_19 = _1954;\n            vec2 param_20 = _2130;\n            vec2 param_21 = _2140;\n            vec4 _2235 = fa_decal_tile(param_17, param_18, param_19, param_20, param_21);\n            if (_1964 > 1.5)\n            {\n                vec3 param_22 = _2235.xyz;\n                vec3 _2245 = fa_dc_to_srgb(param_22);\n                _2239 = _2245;\n            }\n            else\n            {\n                _2239 = _2235.xyz;\n            }\n            vec3 _2254 = (_2239 * 2.0) - vec3(1.0);\n            vec2 _2259 = _2254.xy * _2009.y;\n            vec3 _2281 = (normalize(_2037) * _2259.x) + (normalize(_2044) * _2259.y);\n            vec3 _2284 = normalize(normal);\n            normal = normalize(mix(_2284, normalize((_2284 * max(_2254.z, 0.0500000007450580596923828125)) + (_2281 - (_2284 * dot(_2284, _2281)))), vec3(clamp(_2112 * (_2165 ? tex_a : 1.0), 0.0, 1.0))));\n        }\n    }\n}\n\nvoid fa_lod_dither()\n{\n    if (fa_mesh_fs_params[52].w != 0.0)\n    {\n        float _633 = fract(52.98291778564453125 * fract(dot(gl_FragCoord.xy, vec2(0.067110560834407806396484375, 0.005837149918079376220703125))));\n        bool _636;\n        if (fa_mesh_fs_params[52].w > 0.0)\n        {\n            _636 = _633 >= fa_mesh_fs_params[52].w;\n        }\n        else\n        {\n            _636 = _633 < (-fa_mesh_fs_params[52].w);\n        }\n        if (_636)\n        {\n            discard;\n        }\n    }\n}\n\nfloat fa_sheen_albedo(float ndv, float rough)\n{\n    float _4775 = min(sqrt(max(rough - 0.100000001490116119384765625, 0.0) * 1.111111164093017578125) * 6.0, 5.999000072479248046875);\n    float _4783 = min(sqrt(clamp(ndv, 0.0, 1.0)) * 8.0, 7.999000072479248046875);\n    int _4786 = int(_4775);\n    int _4789 = int(_4783);\n    float _4799 = _4783 - float(_4789);\n    int _4854 = (_4786 * 9) + _4789;\n    int _4874 = ((_4786 + 1) * 9) + _4789;\n    return mix(mix(_4850[_4854], _4850[_4854 + 1], _4799), mix(_4850[_4874], _4850[_4874 + 1], _4799), _4775 - float(_4786));\n}\n\nFaLayers fa_layers_setup(SurfaceInput i, Surface s, vec3 n, vec3 v, float metallic, float roughness, inout vec3 f0)\n{\n    bool _9778 = false;\n    float _9779 = 1.0;\n    float _9780 = 1.0;\n    float _9781 = 1.0;\n    float _9782 = 0.0;\n    float _9783 = 0.0;\n    float _9784 = 0.0;\n    float _9785 = 0.0;\n    float _9787 = 1.0;\n    bool _9788 = false;\n    vec3 _9789 = vec3(0.0);\n    float _9790 = 1.0;\n    float _9791 = 1.0;\n    float _9792 = 1.0;\n    float _9793 = 0.0;\n    float _9794 = 0.0;\n    vec3 _9795 = vec3(1.0, 0.0, 0.0);\n    vec3 _9796 = vec3(0.0, 0.0, 1.0);\n    float _9797 = 1.0;\n    float _9798 = 1.0;\n    float _4925 = clamp(s.specular, 0.0, 1.0);\n    float _4929 = clamp(s.ior, 1.0, 3.0);\n    bool _4934 = (_4925 != 1.0) || (_4929 != 1.5);\n    bool _4943;\n    if (!_4934)\n    {\n        _4943 = any(notEqual(s.specular_color, vec3(1.0)));\n    }\n    else\n    {\n        _4943 = _4934;\n    }\n    if (_4943)\n    {\n        float _4951 = (_4929 - 1.0) / (_4929 + 1.0);\n        f0 = mix(min(vec3(_4951 * _4951) * max(s.specular_color, vec3(0.0)), vec3(1.0)) * _4925, s.albedo, vec3(metallic));\n        _9779 = mix(_4925, 1.0, metallic);\n        _9778 = true;\n    }\n    float _4978 = clamp(s.clearcoat, 0.0, 1.0);\n    if (_4978 > 0.0)\n    {\n        float _4986 = clamp(s.clearcoat_roughness, 0.0500000007450580596923828125, 1.0);\n        _9782 = _4978;\n        _9783 = _4986;\n        float _4993 = _4986 * _4986;\n        _9784 = _4993;\n        _9785 = _4993 * _4993;\n        float _5005 = max(dot(i.world_normal, v), 9.9999997473787516355514526367188e-05);\n        _9787 = _5005;\n        _9780 = 1.0 - (_4978 * (0.039999999105930328369140625 + (0.959999978542327880859375 * pow(clamp(1.0 - _5005, 0.0, 1.0), 5.0))));\n        _9778 = true;\n    }\n    vec3 _5024 = max(s.sheen_color, vec3(0.0));\n    float _5033 = max(_5024.x, max(_5024.y, _5024.z));\n    if (_5033 > 0.0)\n    {\n        float _5041 = clamp(s.sheen_roughness, 0.100000001490116119384765625, 1.0);\n        _9788 = true;\n        _9789 = _5024;\n        _9790 = _5041;\n        _9791 = _5041 * _5041;\n        float param = max(dot(n, v), 9.9999997473787516355514526367188e-05);\n        float param_1 = _5041;\n        float _5058 = fa_sheen_albedo(param, param_1);\n        _9793 = _5058;\n        _9792 = 1.0 - min(_5033 * _5058, 1.0);\n        _9778 = true;\n    }\n    _9781 = _9780 * _9792;\n    float _5077 = clamp(s.anisotropy, -1.0, 1.0);\n    if (_5077 != 0.0)\n    {\n        vec3 _5092 = i.world_tangent.xyz - (n * dot(n, i.world_tangent.xyz));\n        vec3 t = _5092;\n        if (dot(_5092, _5092) < 9.9999999392252902907785028219223e-09)\n        {\n            bvec3 _5104 = bvec3(abs(n.y) < 0.9900000095367431640625);\n            t = cross(vec3(_5104.x ? vec3(0.0, 1.0, 0.0).x : vec3(1.0, 0.0, 0.0).x, _5104.y ? vec3(0.0, 1.0, 0.0).y : vec3(1.0, 0.0, 0.0).y, _5104.z ? vec3(0.0, 1.0, 0.0).z : vec3(1.0, 0.0, 0.0).z), n);\n        }\n        vec3 _5108 = t;\n        vec3 _5109 = normalize(_5108);\n        t = _5109;\n        vec3 _5134 = normalize((_5109 * cos(s.anisotropy_rotation)) + ((cross(n, _5109) * ((i.world_tangent.w < 0.0) ? (-1.0) : 1.0)) * sin(s.anisotropy_rotation)));\n        _9795 = _5134;\n        _9796 = cross(n, _5134);\n        float _5144 = roughness * roughness;\n        float _5150 = mix(_5144, 1.0, _5077 * _5077);\n        bool _5152 = _5077 > 0.0;\n        _9797 = _5152 ? _5150 : _5144;\n        _9798 = _5152 ? _5144 : _5150;\n        _9794 = _5077;\n        _9778 = true;\n    }\n    return FaLayers(_9778, _9779, _9780, _9781, _9782, _9783, _9784, _9785, i.world_normal, _9787, _9788, _9789, _9790, _9791, _9792, _9793, _9794, _9795, _9796, _9797, _9798);\n}\n\nvec2 fa_atlas_size()\n{\n    return vec2(textureSize(fa_probe_atlas_fa_env_smp, 0));\n}\n\nvec3 fa_probe_sh_coef(vec2 origin, float res, int k)\n{\n    vec3 v = textureLod(fa_probe_atlas_fa_env_smp, (origin + vec2(float(k) + 0.5, res + 2.5)) / fa_atlas_size(), 0.0).xyz;\n    if (fa_mesh_fs_params[41].y > 0.5)\n    {\n        v = ((v * 255.0) - vec3(128.0)) * 0.03149606287479400634765625;\n    }\n    return v;\n}\n\nvec3 fa_sh_eval(vec3 c[9], vec3 n)\n{\n    vec3 _3946 = max((((c[0] * 0.2820948064327239990234375) + (((c[1] * (0.3257350027561187744140625 * n.y)) + (c[2] * (0.3257350027561187744140625 * n.z))) + (c[3] * (0.3257350027561187744140625 * n.x)))) + (((c[4] * ((0.2731371223926544189453125 * n.x) * n.y)) + (c[5] * ((0.2731371223926544189453125 * n.y) * n.z))) + (c[6] * (0.078847892582416534423828125 * (((3.0 * n.z) * n.z) - 1.0))))) + ((c[7] * ((0.2731371223926544189453125 * n.x) * n.z)) + (c[8] * (0.13656856119632720947265625 * ((n.x * n.x) - (n.y * n.y))))), vec3(0.0));\n    return _3946;\n}\n\nvec3 fa_ambient_light(vec3 n)\n{\n    float _4557 = (1.0 - fa_mesh_fs_params[42].w) - fa_mesh_fs_params[47].w;\n    vec3 amb = vec3(0.0);\n    bool _4562 = fa_mesh_fs_params[11].w > 0.5;\n    vec3 c[9];\n    for (int k = 0; k < 9; k++)\n    {\n        c[k] = vec3(0.0);\n    }\n    if (_4557 > 0.0005000000237487256526947021484375)\n    {\n        if (_4562)\n        {\n            for (int k_1 = 0; k_1 < 9; k_1++)\n            {\n                vec2 param = fa_mesh_fs_params[41].zw;\n                float param_1 = 128.0;\n                int param_2 = k_1;\n                c[k_1] = fa_probe_sh_coef(param, param_1, param_2) * _4557;\n            }\n        }\n        else\n        {\n            amb = fa_mesh_fs_params[1].xyz * _4557;\n        }\n    }\n    bool _4612 = fa_mesh_fs_params[42].w > 0.0;\n    if (_4612)\n    {\n        for (int k_2 = 0; k_2 < 9; k_2++)\n        {\n            vec2 param_3 = fa_mesh_fs_params[42].xy;\n            float param_4 = fa_mesh_fs_params[42].z;\n            int param_5 = k_2;\n            c[k_2] += (fa_probe_sh_coef(param_3, param_4, param_5) * fa_mesh_fs_params[42].w);\n        }\n    }\n    bool _4643 = fa_mesh_fs_params[47].w > 0.0;\n    if (_4643)\n    {\n        for (int k_3 = 0; k_3 < 9; k_3++)\n        {\n            vec2 param_6 = fa_mesh_fs_params[47].xy;\n            float param_7 = fa_mesh_fs_params[47].z;\n            int param_8 = k_3;\n            c[k_3] += (fa_probe_sh_coef(param_6, param_7, param_8) * fa_mesh_fs_params[47].w);\n        }\n    }\n    if ((_4562 || _4612) || _4643)\n    {\n        vec3 param_9[9] = c;\n        vec3 param_10 = n;\n        amb += fa_sh_eval(param_9, param_10);\n    }\n    return amb;\n}\n\nvec4 fa_gi_fetch(vec2 texel)\n{\n    return textureLod(fa_probe_atlas_fa_env_smp, texel / fa_atlas_size(), 0.0);\n}\n\nvec2 fa_oct_encode(vec3 d)\n{\n    vec3 _3966 = d / vec3(max((abs(d.x) + abs(d.y)) + abs(d.z), 9.9999999600419720025001879548654e-13));\n    float _3969 = _3966.x;\n    float _3971 = _3966.z;\n    vec2 e = vec2(_3969, _3971);\n    if (_3966.y < 0.0)\n    {\n        e = vec2((1.0 - abs(_3971)) * ((_3969 < 0.0) ? (-1.0) : 1.0), (1.0 - abs(_3969)) * ((_3971 < 0.0) ? (-1.0) : 1.0));\n    }\n    return e;\n}\n\nvec3 fa_gi_grid(int rec, vec3 n, vec3 v, out float cover)\n{\n    cover = 0.0;\n    int param = rec;\n    vec4 _7992 = fa_light_texel(param);\n    int param_1 = rec + 1;\n    vec4 _7997 = fa_light_texel(param_1);\n    int param_2 = rec + 2;\n    vec4 _8002 = fa_light_texel(param_2);\n    int param_3 = rec + 3;\n    vec4 _8007 = fa_light_texel(param_3);\n    bool _8010 = _8007.z < 0.5;\n    bool _8018;\n    if (!_8010)\n    {\n        _8018 = fa_atlas_size().y < 1155.0;\n    }\n    else\n    {\n        _8018 = _8010;\n    }\n    if (_8018)\n    {\n        return vec3(0.0);\n    }\n    float _8025 = max(_7992.w, 9.9999997473787516355514526367188e-05);\n    vec3 _8028 = _7997.xyz;\n    vec3 _8032 = _7992.xyz;\n    vec3 _8036 = (fa_world_pos - _8032) / vec3(_8025);\n    vec3 _8045 = min(_8036 + vec3(0.5), (_8028 - vec3(0.5)) - _8036);\n    float _8054 = min(_8045.x, min(_8045.y, _8045.z));\n    if (!(_8054 > 0.0))\n    {\n        return vec3(0.0);\n    }\n    vec3 _8069 = _8028 - vec3(1.0);\n    vec3 _8070 = clamp(_8036, vec3(0.0), _8069);\n    vec3 _8078 = min(floor(_8070), max(_8028 - vec3(2.0), vec3(0.0)));\n    vec3 _8082 = _8070 - _8078;\n    vec3 _8093 = fa_world_pos + (((n * 0.800000011920928955078125) + (v * 0.20000000298023223876953125)) * (0.20000000298023223876953125 * _8025));\n    int _8098 = int(_8002.y + 0.5);\n    float _8103 = 0.3257350027561187744140625 * n.y;\n    float _8107 = 0.3257350027561187744140625 * n.z;\n    float _8111 = 0.3257350027561187744140625 * n.x;\n    float _8118 = (0.2731371223926544189453125 * n.x) * n.y;\n    float _8125 = (0.2731371223926544189453125 * n.y) * n.z;\n    float _8134 = 0.078847892582416534423828125 * (((3.0 * n.z) * n.z) - 1.0);\n    float _8141 = (0.2731371223926544189453125 * n.x) * n.z;\n    float _8154 = 0.13656856119632720947265625 * ((n.x * n.x) - (n.y * n.y));\n    vec3 acc = vec3(0.0);\n    float wsum = 0.0;\n    int _8161 = 8 + int(_8007.w);\n    float _8188;\n    float _8201;\n    float _8215;\n    for (int k = 0; k < _8161; k++)\n    {\n        float _8174 = float(k & 1);\n        float _8178 = float((k >> 1) & 1);\n        float _8182 = float((k >> 2) & 1);\n        if (_8174 > 0.5)\n        {\n            _8188 = _8082.x;\n        }\n        else\n        {\n            _8188 = 1.0 - _8082.x;\n        }\n        if (_8178 > 0.5)\n        {\n            _8201 = _8082.y;\n        }\n        else\n        {\n            _8201 = 1.0 - _8082.y;\n        }\n        if (_8182 > 0.5)\n        {\n            _8215 = _8082.z;\n        }\n        else\n        {\n            _8215 = 1.0 - _8082.z;\n        }\n        float _8225 = (_8188 * _8201) * _8215;\n        if (!(_8225 > 0.0))\n        {\n            continue;\n        }\n        vec3 _8238 = min(_8078 + vec3(_8174, _8178, _8182), _8069);\n        int _8258 = int(((_8002.x + _8238.x) + (_7997.x * (_8238.y + (_7997.y * _8238.z)))) + 0.5);\n        vec2 _8273 = vec2(float(_8258 % _8098) * 10.0, 1024.0 + (float(_8258 / _8098) * 11.0));\n        vec2 param_4 = _8273 + vec2(9.5, 10.5);\n        vec4 _8281 = fa_gi_fetch(param_4);\n        bool _8284 = _8281.y < 0.5;\n        bool _8293;\n        if (!_8284)\n        {\n            _8293 = _8281.x > _8007.y;\n        }\n        else\n        {\n            _8293 = _8284;\n        }\n        if (_8293)\n        {\n            continue;\n        }\n        vec3 _8305 = _8093 - (_8032 + (_8238 * _8025));\n        float _8308 = length(_8305);\n        vec3 _8314 = _8305 / vec3(max(_8308, 9.9999997473787516355514526367188e-05));\n        float _8324 = max(9.9999997473787516355514526367188e-05, (dot(-_8314, n) + 1.0) * 0.5);\n        float w = _8225 * (_8324 * _8324);\n        vec3 param_5 = _8314;\n        vec2 param_6 = (_8273 + vec2(1.0)) + (((fa_oct_encode(param_5) * 0.5) + vec2(0.5)) * 8.0);\n        vec4 _8343 = fa_gi_fetch(param_6);\n        float _8350 = _8308 / max(_8002.z, 9.9999997473787516355514526367188e-05);\n        float _8353 = _8343.x;\n        if (_8350 > _8353)\n        {\n            float _8366 = max(_8343.y - (_8353 * _8353), 0.0);\n            float _8371 = _8350 - _8353;\n            float _8380 = _8366 / max(_8366 + (_8371 * _8371), 9.9999999600419720025001879548654e-13);\n            w *= ((_8380 * _8380) * _8380);\n        }\n        if (!(w > 0.0))\n        {\n            continue;\n        }\n        vec2 param_7 = _8273 + vec2(0.5, 10.5);\n        vec2 param_8 = _8273 + vec2(1.5, 10.5);\n        vec2 param_9 = _8273 + vec2(2.5, 10.5);\n        vec2 param_10 = _8273 + vec2(3.5, 10.5);\n        vec2 param_11 = _8273 + vec2(4.5, 10.5);\n        vec2 param_12 = _8273 + vec2(5.5, 10.5);\n        vec2 param_13 = _8273 + vec2(6.5, 10.5);\n        vec2 param_14 = _8273 + vec2(7.5, 10.5);\n        vec2 param_15 = _8273 + vec2(8.5, 10.5);\n        acc += ((((((((((fa_gi_fetch(param_7).xyz * 0.2820948064327239990234375) + (fa_gi_fetch(param_8).xyz * _8103)) + (fa_gi_fetch(param_9).xyz * _8107)) + (fa_gi_fetch(param_10).xyz * _8111)) + (fa_gi_fetch(param_11).xyz * _8118)) + (fa_gi_fetch(param_12).xyz * _8125)) + (fa_gi_fetch(param_13).xyz * _8134)) + (fa_gi_fetch(param_14).xyz * _8141)) + (fa_gi_fetch(param_15).xyz * _8154)) * w);\n        wsum += w;\n    }\n    if (!(wsum > 9.9999997473787516355514526367188e-06))\n    {\n        return vec3(0.0);\n    }\n    cover = smoothstep(0.0, 1.0, clamp(_8054 * 2.0, 0.0, 1.0)) * smoothstep(0.0, 0.0199999995529651641845703125, wsum);\n    float _8504;\n    if (fa_mesh_fs_params[52].z > 0.5)\n    {\n        _8504 = _8007.x;\n    }\n    else\n    {\n        _8504 = 1.0;\n    }\n    return max(acc / vec3(wsum), vec3(0.0)) * (_8002.w * _8504);\n}\n\nvec3 fa_gi_light(vec3 n, inout float left)\n{\n    left = 1.0;\n    vec3 acc = vec3(0.0);\n    vec3 _8528 = normalize(fa_mesh_fs_params[0].xyz - fa_world_pos);\n    int _8533 = int(fa_mesh_fs_params[52].x + 0.5);\n    int _8538 = int(fa_mesh_fs_params[52].y + 0.5);\n    float param_3;\n    for (int k = 0; (k < _8538) && (k < 8); k++)\n    {\n        int param = _8533 + (4 * k);\n        vec3 param_1 = n;\n        vec3 param_2 = _8528;\n        vec3 _8563 = fa_gi_grid(param, param_1, param_2, param_3);\n        float _8568 = param_3 * left;\n        acc += (_8563 * _8568);\n        left -= _8568;\n        if (left < 0.001000000047497451305389404296875)\n        {\n            left = 0.0;\n            break;\n        }\n    }\n    return acc;\n}\n\nvec3 fa_realtime_or_ambient(vec3 n)\n{\n    vec3 gi = vec3(0.0);\n    float left = 1.0;\n    if (fa_mesh_fs_params[52].y > 0.5)\n    {\n        vec3 param = n;\n        float param_1;\n        vec3 _8597 = fa_gi_light(param, param_1);\n        left = param_1;\n        gi = _8597;\n    }\n    if (left <= 0.0)\n    {\n        return gi;\n    }\n    vec3 param_2 = n;\n    return gi + (fa_ambient_light(param_2) * left);\n}\n\nvec3 fa_indirect_diffuse(vec3 n)\n{\n    if (fa_lm.z > 0.5)\n    {\n        return textureLod(fa_lightmap_fa_env_smp, fa_lm.xy, 0.0).xyz;\n    }\n    if (fa_mesh_fs_params[53].x > 0.5)\n    {\n        vec4 _8639 = vec4(fa_world_pos, 1.0);\n        vec2 _8658 = vec2(dot(fa_mesh_fs_params[26], _8639), dot(fa_mesh_fs_params[27], _8639)) / vec2(max(dot(fa_mesh_fs_params[28], _8639), 9.9999997473787516355514526367188e-05));\n        float _8667;\n        if (fa_mesh_fs_params[24].y > 0.5)\n        {\n            _8667 = (_8658.y * 0.5) + 0.5;\n        }\n        else\n        {\n            _8667 = 0.5 - (_8658.y * 0.5);\n        }\n        return texelFetch(fa_lightmap_fa_env_smp, clamp(ivec2(vec2((_8658.x * 0.5) + 0.5, _8667) * fa_mesh_fs_params[24].zw), ivec2(0), ivec2(fa_mesh_fs_params[24].zw) - ivec2(1)), 0).xyz;\n    }\n    if (fa_mesh_fs_params[32].w > 0.0)\n    {\n        vec3 c[9];\n        for (int k = 0; k < 9; k++)\n        {\n            c[k] = fa_mesh_fs_params[k * 1 + 32].xyz;\n        }\n        vec3 param = n;\n        vec3 param_1[9] = c;\n        vec3 param_2 = n;\n        return mix(fa_ambient_light(param), fa_sh_eval(param_1, param_2), vec3(clamp(fa_mesh_fs_params[32].w, 0.0, 1.0)));\n    }\n    vec3 param_3 = n;\n    return fa_realtime_or_ambient(param_3);\n}\n\nint fa_cluster_index(int slot, int n)\n{\n    int param = (int(fa_mesh_fs_params[19].x) + int(fa_mesh_fs_params[19].w)) + ((slot + n) >> 2);\n    vec4 t = fa_light_texel(param);\n    return int(t[(slot + n) & 3]);\n}\n\nint fa_cl_light(int n)\n{\n    if (n < fa_cl_ndir)\n    {\n        return n;\n    }\n    int param = fa_cl_slot;\n    int param_1 = n - fa_cl_ndir;\n    return fa_cluster_index(param, param_1);\n}\n\nint fa_light_base(int li)\n{\n    return li * ((fa_mesh_fs_params[1].w > 4.5) ? 8 : 4);\n}\n\nbool fa_light_baked(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 3;\n    return fa_light_texel(param_1).w > 0.5;\n}\n\nfloat fa_baked_keep(int li)\n{\n    float _6454;\n    if (fa_lm.z > 0.5)\n    {\n        _6454 = 0.0;\n    }\n    else\n    {\n        _6454 = 1.0 - clamp(fa_mesh_fs_params[32].w, 0.0, 1.0);\n    }\n    bool _6465 = _6454 < 1.0;\n    bool _6471;\n    if (_6465)\n    {\n        int param = li;\n        _6471 = fa_light_baked(param);\n    }\n    else\n    {\n        _6471 = _6465;\n    }\n    return _6471 ? _6454 : 1.0;\n}\n\nfloat fa_light_type(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 1;\n    return fa_light_texel(param_1).w;\n}\n\nvec4 fa_atlas_fetch(vec2 texel)\n{\n    return textureLod(fa_light_atlas_fa_env_smp, texel / vec2(textureSize(fa_light_atlas_fa_env_smp, 0)), 0.0);\n}\n\nvec3 fa_cookie_sample(vec2 tile_origin, vec2 uv)\n{\n    vec2 param = (tile_origin + vec2(1.0)) + (clamp(uv, vec2(0.0), vec2(1.0)) * 254.0);\n    return fa_atlas_fetch(param).xyz;\n}\n\nvec3 fa_area_point(vec3 c, vec3 axis, vec3 ru, vec3 uu, float hx, float hy, float shape, vec3 p, vec3 r)\n{\n    bool _886 = dot(r, r) > 0.5;\n    if (shape > 1.5)\n    {\n        vec3 _899 = (c - (ru * hx)) - p;\n        vec3 _905 = ru * (2.0 * hx);\n        float _911 = max(dot(_905, _905), 9.9999999392252902907785028219223e-09);\n        float _915 = dot(_899, _905);\n        float t = clamp((-_915) / _911, 0.0, 1.0);\n        if (_886)\n        {\n            float _930 = dot(r, _905);\n            float _936 = _911 - (_930 * _930);\n            if (abs(_936) > (9.9999997473787516355514526367188e-06 * _911))\n            {\n                t = clamp(((dot(r, _899) * _930) - _915) / _936, 0.0, 1.0);\n            }\n        }\n        return (p + _899) + (_905 * t);\n    }\n    vec3 q = p;\n    float _968 = dot(r, axis);\n    bool _976;\n    if (_886)\n    {\n        _976 = abs(_968) > 9.9999997473787516355514526367188e-05;\n    }\n    else\n    {\n        _976 = _886;\n    }\n    if (_976)\n    {\n        float _986 = dot(c - p, axis) / _968;\n        if (_986 > 0.0)\n        {\n            q = p + (r * _986);\n        }\n    }\n    vec3 _999 = q - c;\n    vec2 xy = vec2(dot(_999, ru), dot(_999, uu));\n    if (shape > 0.5)\n    {\n        float _1014 = length(xy);\n        if (_1014 > hx)\n        {\n            xy *= (hx / _1014);\n        }\n    }\n    else\n    {\n        xy = clamp(xy, vec2(-hx, -hy), vec2(hx, hy));\n    }\n    return (c + (ru * xy.x)) + (uu * xy.y);\n}\n\nint fa_cube_face(vec3 d)\n{\n    vec3 _653 = abs(d);\n    float _655 = _653.x;\n    float _657 = _653.y;\n    bool _658 = _655 >= _657;\n    bool _666;\n    if (_658)\n    {\n        _666 = _655 >= _653.z;\n    }\n    else\n    {\n        _666 = _658;\n    }\n    int _667;\n    if (_666)\n    {\n        _667 = (d.x > 0.0) ? 0 : 1;\n    }\n    else\n    {\n        int _681;\n        if (_657 >= _653.z)\n        {\n            _681 = (d.y > 0.0) ? 2 : 3;\n        }\n        else\n        {\n            _681 = (d.z > 0.0) ? 4 : 5;\n        }\n        _667 = _681;\n    }\n    return _667;\n}\n\nvoid fa_cube_face_basis(int f, out vec3 fwd, out vec3 up)\n{\n    if (f == 0)\n    {\n        fwd = vec3(1.0, 0.0, 0.0);\n        up = vec3(0.0, 1.0, 0.0);\n    }\n    else\n    {\n        if (f == 1)\n        {\n            fwd = vec3(-1.0, 0.0, 0.0);\n            up = vec3(0.0, 1.0, 0.0);\n        }\n        else\n        {\n            if (f == 2)\n            {\n                fwd = vec3(0.0, 1.0, 0.0);\n                up = vec3(0.0, 0.0, 1.0);\n            }\n            else\n            {\n                if (f == 3)\n                {\n                    fwd = vec3(0.0, -1.0, 0.0);\n                    up = vec3(0.0, 0.0, -1.0);\n                }\n                else\n                {\n                    if (f == 4)\n                    {\n                        fwd = vec3(0.0, 0.0, 1.0);\n                        up = vec3(0.0, 1.0, 0.0);\n                    }\n                    else\n                    {\n                        fwd = vec3(0.0, 0.0, -1.0);\n                        up = vec3(0.0, 1.0, 0.0);\n                    }\n                }\n            }\n        }\n    }\n}\n\nfloat fa_ies_sample(vec2 tile_origin, vec3 d, vec3 axis, vec3 right, vec3 up)\n{\n    float _806 = dot(d, right);\n    float _810 = dot(d, up);\n    float _821;\n    if (((_806 * _806) + (_810 * _810)) > 1.0000000133514319600180897396058e-10)\n    {\n        _821 = atan(_810, _806) * 0.15915493667125701904296875;\n    }\n    else\n    {\n        _821 = 0.0;\n    }\n    vec2 param = tile_origin + vec2(1.0 + ((_821 - floor(_821)) * 64.0), 1.0 + (acos(clamp(dot(d, axis), -1.0, 1.0)) * 10.18591594696044921875));\n    return fa_atlas_fetch(param).x;\n}\n\nLightSample fa_light_sample_n(int li, vec3 world_pos, vec3 n)\n{\n    int param = li;\n    int _1052 = fa_light_base(param);\n    bool _1056 = fa_mesh_fs_params[1].w > 4.5;\n    int param_1 = _1052;\n    vec4 _1060 = fa_light_texel(param_1);\n    int param_2 = _1052 + 1;\n    vec4 _1065 = fa_light_texel(param_2);\n    float _1068 = _1065.w;\n    float atten = 1.0;\n    float dist = 0.0;\n    fa_light_tint = vec3(1.0);\n    bool _1080 = _1056 && (_1068 > 2.5);\n    fa_light_is_area = _1080;\n    bool _1082 = _1068 < 0.5;\n    vec3 l;\n    if (_1082)\n    {\n        l = normalize(_1060.xyz);\n        if (_1056)\n        {\n            int param_3 = _1052 + 6;\n            vec4 _1096 = fa_light_texel(param_3);\n            if (_1096.z > 0.5)\n            {\n                int param_4 = _1052 + 4;\n                vec4 _1106 = fa_light_texel(param_4);\n                int param_5 = _1052 + 5;\n                vec4 _1111 = fa_light_texel(param_5);\n                vec2 param_6 = _1096.xy;\n                vec2 param_7 = fract(vec2(dot(world_pos, _1106.xyz) * _1106.w, (-dot(world_pos, _1111.xyz)) * _1111.w) + vec2(0.5));\n                fa_light_tint = fa_cookie_sample(param_6, param_7);\n            }\n        }\n    }\n    else\n    {\n        vec3 _1141 = _1060.xyz;\n        vec3 _1143 = _1141 - world_pos;\n        vec3 to_light = _1143;\n        float _1146 = length(_1143);\n        float reach = _1146;\n        bool front = true;\n        if (_1080)\n        {\n            int param_8 = _1052 + 7;\n            reach = max(_1146 - fa_light_texel(param_8).w, 0.0);\n            int param_9 = _1052 + 4;\n            vec4 _1170 = fa_light_texel(param_9);\n            int param_10 = _1052 + 5;\n            vec4 _1175 = fa_light_texel(param_10);\n            int param_11 = _1052 + 6;\n            vec4 _1180 = fa_light_texel(param_11);\n            float _1181 = _1180.w;\n            int param_12 = _1052 + 2;\n            vec3 _1188 = normalize(fa_light_texel(param_12).xyz);\n            bool _1190 = _1181 > 1.5;\n            bool _1198;\n            if (!_1190)\n            {\n                _1198 = dot(_1188, to_light) < 0.0;\n            }\n            else\n            {\n                _1198 = _1190;\n            }\n            front = _1198;\n            vec3 r = vec3(0.0);\n            vec3 _1207 = fa_mesh_fs_params[0].xyz - world_pos;\n            bool _1211 = dot(n, n) > 0.5;\n            bool _1219;\n            if (_1211)\n            {\n                _1219 = dot(_1207, _1207) > 9.9999999600419720025001879548654e-13;\n            }\n            else\n            {\n                _1219 = _1211;\n            }\n            if (_1219)\n            {\n                r = reflect(-normalize(_1207), normalize(n));\n            }\n            vec3 param_13 = _1141;\n            vec3 param_14 = _1188;\n            vec3 param_15 = _1170.xyz;\n            vec3 param_16 = _1175.xyz;\n            float param_17 = _1170.w;\n            float param_18 = _1175.w;\n            float param_19 = _1181;\n            vec3 param_20 = world_pos;\n            vec3 param_21 = r;\n            to_light = fa_area_point(param_13, param_14, param_15, param_16, param_17, param_18, param_19, param_20, param_21) - world_pos;\n        }\n        float _1255 = length(to_light);\n        dist = _1255;\n        l = to_light / vec3(max(_1255, 9.9999997473787516355514526367188e-05));\n        float _1269 = reach / max(_1060.w, 0.001000000047497451305389404296875);\n        float _1275 = clamp(1.0 - (_1269 * _1269), 0.0, 1.0);\n        float _1277;\n        if (front)\n        {\n            _1277 = _1275 * _1275;\n        }\n        else\n        {\n            _1277 = 0.0;\n        }\n        atten = _1277;\n        bool _1288 = _1068 < 2.5;\n        if ((_1068 > 1.5) && _1288)\n        {\n            int param_22 = _1052 + 2;\n            vec4 _1296 = fa_light_texel(param_22);\n            float _1306 = _1296.w;\n            int param_23 = _1052 + 3;\n            vec4 _1311 = fa_light_texel(param_23);\n            float _1312 = _1311.x;\n            float cos_inner = _1312;\n            if (_1312 > 1.5)\n            {\n                cos_inner = mix(_1306, 1.0, 0.25);\n            }\n            atten *= smoothstep(_1306, cos_inner, dot(-l, normalize(_1296.xyz)));\n        }\n        if (_1056 && (_1068 < 1.5))\n        {\n            int param_24 = _1052 + 6;\n            vec4 _1336 = fa_light_texel(param_24);\n            if (_1336.z > 0.5)\n            {\n                vec3 _1344 = -to_light;\n                int param_25 = _1052 + 4;\n                int param_26 = _1052 + 5;\n                vec3 _1358 = fa_light_texel(param_25).xyz;\n                vec3 _1362 = fa_light_texel(param_26).xyz;\n                vec3 _1371 = vec3(dot(_1344, _1358), dot(_1344, _1362), dot(_1344, cross(_1358, _1362)));\n                vec3 param_27 = _1371;\n                int _1375 = fa_cube_face(param_27);\n                int param_28 = _1375;\n                vec3 param_29;\n                vec3 param_30;\n                fa_cube_face_basis(param_28, param_29, param_30);\n                vec2 _1402 = vec2(dot(_1371, cross(param_29, param_30)), dot(_1371, param_30)) / vec2(max(dot(_1371, param_29), 9.9999997473787516355514526367188e-05));\n                int _1406 = _1375 / 3;\n                vec2 param_31 = _1336.xy + (vec2(float(_1375 - (_1406 * 3)), float(_1406)) * 256.0);\n                vec2 param_32 = vec2(0.5 + (0.5 * _1402.x), 0.5 - (0.5 * _1402.y));\n                fa_light_tint = fa_cookie_sample(param_31, param_32);\n            }\n            int param_33 = _1052 + 7;\n            vec4 _1436 = fa_light_texel(param_33);\n            if (_1436.z > 0.5)\n            {\n                int param_34 = _1052 + 2;\n                int param_35 = _1052 + 4;\n                int param_36 = _1052 + 5;\n                vec2 param_37 = _1436.xy;\n                vec3 param_38 = -l;\n                vec3 param_39 = normalize(fa_light_texel(param_34).xyz);\n                vec3 param_40 = fa_light_texel(param_35).xyz;\n                vec3 param_41 = fa_light_texel(param_36).xyz;\n                atten *= fa_ies_sample(param_37, param_38, param_39, param_40, param_41);\n            }\n        }\n        else\n        {\n            if (_1056 && _1288)\n            {\n                int param_42 = _1052 + 6;\n                vec4 _1483 = fa_light_texel(param_42);\n                int param_43 = _1052 + 7;\n                vec4 _1488 = fa_light_texel(param_43);\n                bool _1491 = _1483.z > 0.5;\n                bool _1498;\n                if (!_1491)\n                {\n                    _1498 = _1488.z > 0.5;\n                }\n                else\n                {\n                    _1498 = _1491;\n                }\n                if (_1498)\n                {\n                    int param_44 = _1052 + 2;\n                    vec4 _1505 = fa_light_texel(param_44);\n                    vec3 _1509 = normalize(_1505.xyz);\n                    int param_45 = _1052 + 4;\n                    vec4 _1514 = fa_light_texel(param_45);\n                    int param_46 = _1052 + 5;\n                    vec4 _1519 = fa_light_texel(param_46);\n                    if (_1491)\n                    {\n                        vec3 _1527 = -to_light;\n                        float _1534 = _1505.w;\n                        float _1550 = 0.5 / max(dot(_1527, _1509) * (sqrt(max(1.0 - (_1534 * _1534), 0.0)) / max(_1534, 0.001000000047497451305389404296875)), 9.9999997473787516355514526367188e-05);\n                        vec2 param_47 = _1483.xy;\n                        vec2 param_48 = vec2(0.5 + (dot(_1527, _1514.xyz) * _1550), 0.5 - (dot(_1527, _1519.xyz) * _1550));\n                        fa_light_tint = fa_cookie_sample(param_47, param_48);\n                    }\n                    if (_1488.z > 0.5)\n                    {\n                        vec2 param_49 = _1488.xy;\n                        vec3 param_50 = -l;\n                        vec3 param_51 = _1509;\n                        vec3 param_52 = _1514.xyz;\n                        vec3 param_53 = _1519.xyz;\n                        atten *= fa_ies_sample(param_49, param_50, param_51, param_52, param_53);\n                    }\n                }\n            }\n        }\n    }\n    vec3 _9766 = _1065.xyz * atten;\n    if (_1056)\n    {\n        _9766 *= fa_light_tint;\n    }\n    int _1619;\n    if (_1082)\n    {\n        _1619 = 0;\n    }\n    else\n    {\n        _1619 = ((_1068 > 1.5) && (_1068 < 2.5)) ? 2 : 1;\n    }\n    return LightSample(l, _9766, atten, 1.0, dist, _1619);\n}\n\nfloat fa_shadow_split_at(int i)\n{\n    float _2345;\n    if (i == 0)\n    {\n        _2345 = fa_shadows[24].x;\n    }\n    else\n    {\n        float _2361;\n        if (i == 1)\n        {\n            _2361 = fa_shadows[24].y;\n        }\n        else\n        {\n            float _2369;\n            if (i == 2)\n            {\n                _2369 = fa_shadows[24].z;\n            }\n            else\n            {\n                _2369 = fa_shadows[24].w;\n            }\n            _2361 = _2369;\n        }\n        _2345 = _2361;\n    }\n    return _2345;\n}\n\nfloat fa_shadow_depth(inout vec2 uv, vec4 rect)\n{\n    uv = clamp(uv, rect.xy, rect.zw);\n    return textureLod(fa_shadow_tex_fa_shadow_smp, uv, 0.0).x;\n}\n\nfloat fa_shadow_fetch(vec2 uv, vec4 rect, vec3 conv)\n{\n    vec2 param = uv;\n    vec4 param_1 = rect;\n    float _2402 = fa_shadow_depth(param, param_1);\n    float _2406;\n    if (conv.x < 0.5)\n    {\n        _2406 = _2402;\n    }\n    else\n    {\n        _2406 = (conv.y * conv.z) / (conv.z - (_2402 * (conv.z - conv.y)));\n    }\n    return _2406;\n}\n\nfloat fa_shadow_noise()\n{\n    return fract(52.98291778564453125 * fract(dot(gl_FragCoord.xy, vec2(0.067110560834407806396484375, 0.005837149918079376220703125))));\n}\n\nvec2 fa_shadow_vogel_turn(vec2 d)\n{\n    return vec2((d.x * (-0.737368881702423095703125)) - (d.y * 0.675490319728851318359375), (d.y * (-0.737368881702423095703125)) + (d.x * 0.675490319728851318359375));\n}\n\nfloat fa_shadow_filter(vec2 uv, vec4 rect, float zr, float texel_m, float unit, float reach, float plane, vec3 conv, int mode, float k)\n{\n    if (mode == 1)\n    {\n        vec2 param = uv;\n        vec4 param_1 = rect;\n        vec3 param_2 = conv;\n        return float(zr <= fa_shadow_fetch(param, param_1, param_2));\n    }\n    float _2452 = fa_shadow_noise() * 6.283185482025146484375;\n    vec2 _2458 = vec2(cos(_2452), sin(_2452));\n    vec2 dir = _2458;\n    float radius = 1.5;\n    if (mode == 2)\n    {\n        float _2467;\n        if (k < 0.0)\n        {\n            _2467 = (-k) / max(zr, 0.100000001490116119384765625);\n        }\n        else\n        {\n            _2467 = k;\n        }\n        float _2486 = clamp((_2467 * reach) / texel_m, 3.0, 12.0);\n        float sum = 0.0;\n        float cnt = 0.0;\n        for (int i = 0; i < 16; i++)\n        {\n            float _2505 = sqrt((float(i) + 0.5) * 0.0625) * _2486;\n            vec2 param_3 = uv + (dir * (fa_shadows[26].zw * _2505));\n            vec4 param_4 = rect;\n            vec3 param_5 = conv;\n            float _2519 = fa_shadow_fetch(param_3, param_4, param_5);\n            if (_2519 < (zr - (_2505 * plane)))\n            {\n                sum += _2519;\n                cnt += 1.0;\n            }\n            vec2 param_6 = dir;\n            dir = fa_shadow_vogel_turn(param_6);\n        }\n        if (cnt < 0.5)\n        {\n            return 1.0;\n        }\n        float _2547 = sum / cnt;\n        float _2557;\n        if (k < 0.0)\n        {\n            _2557 = (-k) / max(_2547, 0.0500000007450580596923828125);\n        }\n        else\n        {\n            _2557 = k;\n        }\n        radius = clamp(((max(zr - _2547, 0.0) * unit) * _2557) / texel_m, 1.5, 16.0);\n        dir = _2458;\n    }\n    float lit = 0.0;\n    int _2583 = (mode == 2) ? 24 : 16;\n    for (int i_1 = 0; i_1 < _2583; i_1++)\n    {\n        float _2602 = sqrt((float(i_1) + 0.5) / float(_2583)) * radius;\n        vec2 param_7 = uv + (dir * (fa_shadows[26].zw * _2602));\n        vec4 param_8 = rect;\n        vec3 param_9 = conv;\n        lit += float((zr - (_2602 * plane)) <= fa_shadow_fetch(param_7, param_8, param_9));\n        vec2 param_10 = dir;\n        dir = fa_shadow_vogel_turn(param_10);\n    }\n    return lit / float(_2583);\n}\n\nfloat fa_shadow_cascade(int ci, vec3 world, vec3 n, vec3 l)\n{\n    float _2648 = max(fa_shadows[ci * 1 + 20].y, 0.001000000047497451305389404296875);\n    float _2653 = clamp(dot(n, l), 0.0, 1.0);\n    float _2659 = sqrt(1.0 - (_2653 * _2653));\n    float _2667 = min(_2659 / max(_2653, 0.20000000298023223876953125), 4.0);\n    float _2672;\n    if (fa_shadows[26].y > 0.0)\n    {\n        _2672 = fa_shadows[26].y;\n    }\n    else\n    {\n        _2672 = 1.5 * fa_shadows[ci * 1 + 20].x;\n    }\n    vec4 _2697 = mat4(fa_shadows[ci * 4 + 0], fa_shadows[ci * 4 + 1], fa_shadows[ci * 4 + 2], fa_shadows[ci * 4 + 3]) * vec4(world + (n * (_2672 * _2659)), 1.0);\n    float _2704 = _2697.x;\n    bool _2707 = _2704 < fa_shadows[ci * 1 + 16].x;\n    bool _2716;\n    if (!_2707)\n    {\n        _2716 = _2704 > fa_shadows[ci * 1 + 16].z;\n    }\n    else\n    {\n        _2716 = _2707;\n    }\n    bool _2725;\n    if (!_2716)\n    {\n        _2725 = _2697.y < fa_shadows[ci * 1 + 16].y;\n    }\n    else\n    {\n        _2725 = _2716;\n    }\n    bool _2734;\n    if (!_2725)\n    {\n        _2734 = _2697.y > fa_shadows[ci * 1 + 16].w;\n    }\n    else\n    {\n        _2734 = _2725;\n    }\n    bool _2741;\n    if (!_2734)\n    {\n        _2741 = _2697.z > 1.0;\n    }\n    else\n    {\n        _2741 = _2734;\n    }\n    if (_2741)\n    {\n        return -1.0;\n    }\n    float _2749;\n    if (fa_shadows[26].x > 0.0)\n    {\n        _2749 = fa_shadows[26].x;\n    }\n    else\n    {\n        _2749 = 1.5 * fa_shadows[ci * 1 + 20].x;\n    }\n    vec2 param = _2697.xy;\n    vec4 param_1 = fa_shadows[ci * 1 + 16];\n    float param_2 = _2697.z - ((_2749 * (1.0 + (0.5 * _2667))) / _2648);\n    float param_3 = fa_shadows[ci * 1 + 20].x;\n    float param_4 = _2648;\n    float param_5 = _2648 * 0.25;\n    float param_6 = ((fa_shadows[ci * 1 + 20].x * min(_2667, 3.0)) * 0.5) / _2648;\n    vec3 param_7 = vec3(0.0);\n    int param_8 = int(fa_shadows[25].z + 0.5);\n    float param_9 = fa_shadows[25].w;\n    return fa_shadow_filter(param, param_1, param_2, param_3, param_4, param_5, param_6, param_7, param_8, param_9);\n}\n\nfloat fa_shadow_sun(vec3 world, vec3 n, vec3 l)\n{\n    if (fa_mesh_fs_params[5].z < 0.5)\n    {\n        return 1.0;\n    }\n    int _3127 = int(fa_shadows[25].x + 0.5);\n    if (_3127 < 1)\n    {\n        return 1.0;\n    }\n    float _3142 = dot(world - fa_shadows[27].xyz, fa_shadows[28].xyz);\n    int param = _3127 - 1;\n    if (_3142 > fa_shadow_split_at(param))\n    {\n        return 1.0;\n    }\n    int ci = 0;\n    bool _3154 = _3127 > 1;\n    bool _3161;\n    if (_3154)\n    {\n        _3161 = _3142 > fa_shadows[24].x;\n    }\n    else\n    {\n        _3161 = _3154;\n    }\n    if (_3161)\n    {\n        ci = 1;\n    }\n    bool _3165 = _3127 > 2;\n    bool _3172;\n    if (_3165)\n    {\n        _3172 = _3142 > fa_shadows[24].y;\n    }\n    else\n    {\n        _3172 = _3165;\n    }\n    if (_3172)\n    {\n        ci = 2;\n    }\n    bool _3176 = _3127 > 3;\n    bool _3183;\n    if (_3176)\n    {\n        _3183 = _3142 > fa_shadows[24].z;\n    }\n    else\n    {\n        _3183 = _3176;\n    }\n    if (_3183)\n    {\n        ci = 3;\n    }\n    float s = -1.0;\n    float s2 = -1.0;\n    float t = 0.0;\n    int _3194 = min(_3127, 4);\n    float _3235;\n    for (int c = ci; c < _3194; c++)\n    {\n        int param_1 = c;\n        vec3 param_2 = world;\n        vec3 param_3 = n;\n        vec3 param_4 = l;\n        float _3214 = fa_shadow_cascade(param_1, param_2, param_3, param_4);\n        if (s >= 0.0)\n        {\n            s2 = _3214;\n            break;\n        }\n        if (_3214 < 0.0)\n        {\n            continue;\n        }\n        s = _3214;\n        ci = c;\n        if (fa_shadows[25].y > 0.0)\n        {\n            if (ci > 0)\n            {\n                int param_5 = ci - 1;\n                _3235 = fa_shadow_split_at(param_5);\n            }\n            else\n            {\n                _3235 = fa_shadows[28].w;\n            }\n            int param_6 = ci;\n            float _3254 = fa_shadows[25].y * max(fa_shadow_split_at(param_6) - _3235, 9.9999997473787516355514526367188e-05);\n            int param_7 = ci;\n            t = clamp((_3142 - (fa_shadow_split_at(param_7) - _3254)) / _3254, 0.0, 1.0);\n        }\n        if (t <= 0.0)\n        {\n            break;\n        }\n    }\n    if (s < 0.0)\n    {\n        return 1.0;\n    }\n    if (t > 0.0)\n    {\n        float _3286;\n        if ((ci + 1) < _3127)\n        {\n            _3286 = (s2 < 0.0) ? s : s2;\n        }\n        else\n        {\n            _3286 = 1.0;\n        }\n        s = mix(s, _3286, t);\n    }\n    return s;\n}\n\nfloat fa_shadow_factor(vec3 n, vec3 l)\n{\n    bool _3391 = fa_mesh_fs_params[25].y > 0.5;\n    bool _3397;\n    if (_3391)\n    {\n        _3397 = fa_mesh_fs_params[5].z > 0.5;\n    }\n    else\n    {\n        _3397 = _3391;\n    }\n    if (_3397)\n    {\n        float _3411 = dot(fa_mesh_fs_params[29].xyz, fa_world_pos) + fa_mesh_fs_params[29].w;\n        vec4 _3419 = vec4(fa_world_pos, 1.0);\n        float _3425 = dot(fa_mesh_fs_params[28], _3419);\n        if (_3425 > 9.9999997473787516355514526367188e-05)\n        {\n            vec2 _3444 = vec2(dot(fa_mesh_fs_params[26], _3419), dot(fa_mesh_fs_params[27], _3419)) / vec2(_3425);\n            float _3449 = (_3444.x * 0.5) + 0.5;\n            float _3453;\n            if (fa_mesh_fs_params[24].y > 0.5)\n            {\n                _3453 = (_3444.y * 0.5) + 0.5;\n            }\n            else\n            {\n                _3453 = 0.5 - (_3444.y * 0.5);\n            }\n            bool _3469 = _3449 >= 0.0;\n            bool _3475;\n            if (_3469)\n            {\n                _3475 = _3449 < 1.0;\n            }\n            else\n            {\n                _3475 = _3469;\n            }\n            bool _3481;\n            if (_3475)\n            {\n                _3481 = _3453 >= 0.0;\n            }\n            else\n            {\n                _3481 = _3475;\n            }\n            bool _3487;\n            if (_3481)\n            {\n                _3487 = _3453 < 1.0;\n            }\n            else\n            {\n                _3487 = _3481;\n            }\n            if (_3487)\n            {\n                vec4 _3513 = texelFetch(fa_screen_tex_fa_shadow_smp, clamp(ivec2(vec2(_3449, _3453) * fa_mesh_fs_params[24].zw), ivec2(0), ivec2(fa_mesh_fs_params[24].zw) - ivec2(1)), 0);\n                bool _3516 = _3513.w > 0.5;\n                bool _3532;\n                if (_3516)\n                {\n                    _3532 = abs(_3411 - _3513.x) <= (((0.00200000009499490261077880859375 * _3411) + 0.00999999977648258209228515625) + fa_rt_slope);\n                }\n                else\n                {\n                    _3532 = _3516;\n                }\n                if (_3532)\n                {\n                    float _3538;\n                    if (fa_mesh_fs_params[25].z > 0.5)\n                    {\n                        vec3 param = fa_world_pos;\n                        vec3 param_1 = n;\n                        vec3 param_2 = l;\n                        _3538 = min(_3513.y, fa_shadow_sun(param, param_1, param_2));\n                    }\n                    else\n                    {\n                        _3538 = _3513.y;\n                    }\n                    return _3538;\n                }\n            }\n        }\n    }\n    vec3 param_3 = fa_world_pos;\n    vec3 param_4 = n;\n    vec3 param_5 = l;\n    return fa_shadow_sun(param_3, param_4, param_5);\n}\n\nfloat fa_shadow_local(int li, vec3 lpos, vec3 world, vec3 n, vec3 l)\n{\n    bool _2807 = fa_mesh_fs_params[5].z < 0.5;\n    bool _2814;\n    if (!_2807)\n    {\n        _2814 = fa_shadows[29].x < 0.5;\n    }\n    else\n    {\n        _2814 = _2807;\n    }\n    if (_2814)\n    {\n        return 1.0;\n    }\n    int param = (int(fa_shadows[29].x + 0.5) - 1) + li;\n    vec4 _2827 = fa_light_texel(param);\n    float _2828 = _2827.x;\n    if (_2828 < 0.0)\n    {\n        return 1.0;\n    }\n    int _2837 = int(_2828 + 0.5);\n    int param_1 = _2837;\n    vec4 _2841 = fa_light_texel(param_1);\n    int param_2 = _2837 + 1;\n    vec4 _2846 = fa_light_texel(param_2);\n    float fade = 1.0;\n    float _2849 = _2841.y;\n    if (_2849 > 0.0)\n    {\n        float _2866 = 1.0 - smoothstep(0.75 * _2849, _2849, length(world - fa_shadows[27].xyz));\n        fade = _2866;\n        if (_2866 <= 0.0)\n        {\n            return 1.0;\n        }\n    }\n    int face = 0;\n    if (_2841.x > 1.5)\n    {\n        vec3 param_3 = world - lpos;\n        face = fa_cube_face(param_3);\n    }\n    int _2890 = (_2837 + 2) + (face * 6);\n    int param_4 = _2890;\n    int param_5 = _2890 + 1;\n    int param_6 = _2890 + 3;\n    vec4 _2904 = fa_light_texel(param_6);\n    int param_7 = _2890 + 4;\n    vec4 _2909 = fa_light_texel(param_7);\n    int param_8 = _2890 + 5;\n    vec4 _2914 = fa_light_texel(param_8);\n    float _2926 = _2914.x * max(dot(_2904, vec4(world, 1.0)), 0.001000000047497451305389404296875);\n    float _2931 = clamp(dot(n, l), 0.0, 1.0);\n    float _2954 = clamp(dot(n, _2904.xyz), -1.0, 1.0);\n    float _2973 = min(sqrt(1.0 - (_2954 * _2954)) / max(abs(dot(n, world - lpos)) / max(dot(_2904, vec4(world, 1.0)), 0.001000000047497451305389404296875), 0.20000000298023223876953125), 4.0);\n    float _2976 = _2846.y;\n    float _2978;\n    if (_2976 > 0.0)\n    {\n        _2978 = _2976;\n    }\n    else\n    {\n        _2978 = 1.5 * _2926;\n    }\n    vec4 _2998 = vec4(world + (n * (_2978 * sqrt(1.0 - (_2931 * _2931)))), 1.0);\n    float _3002 = dot(_2904, _2998);\n    float _3005 = _2914.y;\n    if (_3002 < _3005)\n    {\n        return 1.0;\n    }\n    vec2 _3020 = vec2(dot(fa_light_texel(param_4), _2998), dot(fa_light_texel(param_5), _2998)) / vec2(_3002);\n    float _3022 = _3020.x;\n    bool _3025 = _3022 < _2909.x;\n    bool _3034;\n    if (!_3025)\n    {\n        _3034 = _3022 > _2909.z;\n    }\n    else\n    {\n        _3034 = _3025;\n    }\n    bool _3043;\n    if (!_3034)\n    {\n        _3043 = _3020.y < _2909.y;\n    }\n    else\n    {\n        _3043 = _3034;\n    }\n    bool _3052;\n    if (!_3043)\n    {\n        _3052 = _3020.y > _2909.w;\n    }\n    else\n    {\n        _3052 = _3043;\n    }\n    if (_3052)\n    {\n        return 1.0;\n    }\n    float _3058 = _2846.x;\n    float _3060;\n    if (_3058 > 0.0)\n    {\n        _3060 = _3058;\n    }\n    else\n    {\n        _3060 = 1.5 * _2926;\n    }\n    vec2 param_9 = _3020;\n    vec4 param_10 = _2909;\n    float param_11 = _3002 - (_3060 * (1.0 + (0.5 * _2973)));\n    float param_12 = _2926;\n    float param_13 = 1.0;\n    float param_14 = _2914.z * 0.25;\n    float param_15 = (_2926 * min(_2973, 3.0)) * 0.5;\n    vec3 param_16 = vec3(1.0, _3005, _2914.z);\n    int param_17 = int(_2841.z + 0.5);\n    float param_18 = _2841.w;\n    return mix(1.0, fa_shadow_filter(param_9, param_10, param_11, param_12, param_13, param_14, param_15, param_16, param_17, param_18), fade);\n}\n\nfloat fa_shadow_local_rt(int li, vec3 lpos, vec3 world, vec3 n, vec3 l)\n{\n    bool _3567 = fa_mesh_fs_params[25].w > 0.5;\n    bool _3573;\n    if (_3567)\n    {\n        _3573 = fa_mesh_fs_params[5].z > 0.5;\n    }\n    else\n    {\n        _3573 = _3567;\n    }\n    bool _3579;\n    if (_3573)\n    {\n        _3579 = fa_shadows[29].x > 0.5;\n    }\n    else\n    {\n        _3579 = _3573;\n    }\n    if (_3579)\n    {\n        int param = (int(fa_shadows[29].x + 0.5) - 1) + li;\n        vec4 _3591 = fa_light_texel(param);\n        float _3592 = _3591.z;\n        if (_3592 > 0.5)\n        {\n            float _3605 = dot(fa_mesh_fs_params[29].xyz, world) + fa_mesh_fs_params[29].w;\n            float _3611 = ((0.00200000009499490261077880859375 * _3605) + 0.00999999977648258209228515625) + fa_rt_slope;\n            vec4 _3617 = vec4(world, 1.0);\n            float _3622 = dot(fa_mesh_fs_params[28], _3617);\n            if (_3622 > 9.9999997473787516355514526367188e-05)\n            {\n                vec2 _3639 = vec2(dot(fa_mesh_fs_params[26], _3617), dot(fa_mesh_fs_params[27], _3617)) / vec2(_3622);\n                float _3644 = (_3639.x * 0.5) + 0.5;\n                float _3648;\n                if (fa_mesh_fs_params[24].y > 0.5)\n                {\n                    _3648 = (_3639.y * 0.5) + 0.5;\n                }\n                else\n                {\n                    _3648 = 0.5 - (_3639.y * 0.5);\n                }\n                bool _3664 = _3644 >= 0.0;\n                bool _3670;\n                if (_3664)\n                {\n                    _3670 = _3644 < 1.0;\n                }\n                else\n                {\n                    _3670 = _3664;\n                }\n                bool _3676;\n                if (_3670)\n                {\n                    _3676 = _3648 >= 0.0;\n                }\n                else\n                {\n                    _3676 = _3670;\n                }\n                bool _3682;\n                if (_3676)\n                {\n                    _3682 = _3648 < 1.0;\n                }\n                else\n                {\n                    _3682 = _3676;\n                }\n                if (_3682)\n                {\n                    ivec2 _3699 = ivec2(fa_mesh_fs_params[24].zw) - ivec2(1);\n                    ivec2 _3700 = clamp(ivec2(vec2(_3644, _3648) * fa_mesh_fs_params[24].zw), ivec2(0), _3699);\n                    float _3704;\n                    if (_3592 < 1.5)\n                    {\n                        _3704 = 1.0;\n                    }\n                    else\n                    {\n                        _3704 = (_3592 < 2.5) ? 256.0 : 65536.0;\n                    }\n                    float best = 2.0;\n                    int _3726;\n                    int _3732;\n                    for (int k = 0; k < 9; k++)\n                    {\n                        if (k == 0)\n                        {\n                            _3726 = 4;\n                        }\n                        else\n                        {\n                            if (k <= 4)\n                            {\n                                _3732 = k - 1;\n                            }\n                            else\n                            {\n                                _3732 = k;\n                            }\n                            _3726 = _3732;\n                        }\n                        vec4 _3761 = texelFetch(fa_screen_tex_fa_shadow_smp, clamp(_3700 + ivec2((_3726 % 3) - 1, (_3726 / 3) - 1), ivec2(0), _3699), 0);\n                        bool _3764 = _3761.w > 0.5;\n                        bool _3774;\n                        if (_3764)\n                        {\n                            _3774 = abs(_3605 - _3761.x) <= _3611;\n                        }\n                        else\n                        {\n                            _3774 = _3764;\n                        }\n                        if (_3774)\n                        {\n                            best = min(best, mod(floor(_3761.z / _3704), 256.0) * 0.0039215688593685626983642578125);\n                            if (k == 0)\n                            {\n                                break;\n                            }\n                        }\n                    }\n                    if (best <= 1.0)\n                    {\n                        float _3801;\n                        if (fa_mesh_fs_params[25].z > 0.5)\n                        {\n                            int param_1 = li;\n                            vec3 param_2 = lpos;\n                            vec3 param_3 = world;\n                            vec3 param_4 = n;\n                            vec3 param_5 = l;\n                            _3801 = min(best, fa_shadow_local(param_1, param_2, param_3, param_4, param_5));\n                        }\n                        else\n                        {\n                            _3801 = best;\n                        }\n                        return _3801;\n                    }\n                }\n            }\n            float _3824;\n            if (fa_mesh_fs_params[25].z > 0.5)\n            {\n                int param_6 = li;\n                vec3 param_7 = lpos;\n                vec3 param_8 = world;\n                vec3 param_9 = n;\n                vec3 param_10 = l;\n                _3824 = fa_shadow_local(param_6, param_7, param_8, param_9, param_10);\n            }\n            else\n            {\n                _3824 = 1.0;\n            }\n            return _3824;\n        }\n    }\n    int param_11 = li;\n    vec3 param_12 = lpos;\n    vec3 param_13 = world;\n    vec3 param_14 = n;\n    vec3 param_15 = l;\n    return fa_shadow_local(param_11, param_12, param_13, param_14, param_15);\n}\n\nfloat fa_contact_shadow(int li, vec3 world, vec3 gn, vec3 l, float dist)\n{\n    bool _5668 = fa_mesh_fs_params[24].x < 0.5;\n    bool _5675;\n    if (!_5668)\n    {\n        _5675 = fa_shadows[29].x < 0.5;\n    }\n    else\n    {\n        _5675 = _5668;\n    }\n    if (_5675)\n    {\n        return 1.0;\n    }\n    int param = (int(fa_shadows[29].x + 0.5) - 1) + li;\n    vec4 _5688 = fa_light_texel(param);\n    float _5689 = _5688.y;\n    float len = _5689;\n    if (_5689 <= 0.0)\n    {\n        return 1.0;\n    }\n    float _5701 = length(world - fa_mesh_fs_params[0].xyz);\n    float _5710 = 1.0 - smoothstep(0.5 * fa_mesh_fs_params[25].x, fa_mesh_fs_params[25].x, _5701);\n    if (_5710 <= 0.0)\n    {\n        return 1.0;\n    }\n    float _5716 = len;\n    float _5719 = min(_5716, 0.89999997615814208984375 * dist);\n    len = _5719;\n    float _5724 = 0.004999999888241291046142578125 + (0.0030000000260770320892333984375 * _5701);\n    float _5729 = _5724 + (0.5 * _5719);\n    vec3 _5735 = world + (gn * _5724);\n    float _5737 = fa_shadow_noise();\n    float occ = 0.0;\n    float _5798;\n    for (int k = 0; k < 12; k++)\n    {\n        float _5752 = (float(k) + _5737) * 0.083333335816860198974609375;\n        vec3 _5760 = _5735 + (l * (_5752 * len));\n        vec4 _5766 = vec4(_5760, 1.0);\n        float _5771 = dot(fa_mesh_fs_params[28], _5766);\n        if (_5771 < 9.9999997473787516355514526367188e-05)\n        {\n            break;\n        }\n        vec2 _5789 = vec2(dot(fa_mesh_fs_params[26], _5766), dot(fa_mesh_fs_params[27], _5766)) / vec2(_5771);\n        float _5793 = _5789.x * 0.5;\n        float _5794 = _5793 + 0.5;\n        if (fa_mesh_fs_params[24].y > 0.5)\n        {\n            _5798 = (_5789.y * 0.5) + 0.5;\n        }\n        else\n        {\n            _5798 = 0.5 - (_5789.y * 0.5);\n        }\n        bool _5814 = _5794 < 0.0;\n        bool _5821;\n        if (!_5814)\n        {\n            _5821 = _5794 >= 1.0;\n        }\n        else\n        {\n            _5821 = _5814;\n        }\n        bool _5828;\n        if (!_5821)\n        {\n            _5828 = _5798 < 0.0;\n        }\n        else\n        {\n            _5828 = _5821;\n        }\n        bool _5835;\n        if (!_5828)\n        {\n            _5835 = _5798 >= 1.0;\n        }\n        else\n        {\n            _5835 = _5828;\n        }\n        if (_5835)\n        {\n            break;\n        }\n        vec4 _5859 = texelFetch(fa_screen_tex_fa_shadow_smp, clamp(ivec2(vec2(_5794, _5798) * fa_mesh_fs_params[24].zw), ivec2(0), ivec2(fa_mesh_fs_params[24].zw) - ivec2(1)), 0);\n        if (_5859.w < 0.5)\n        {\n            continue;\n        }\n        float _5877 = (dot(fa_mesh_fs_params[29].xyz, _5760) + fa_mesh_fs_params[29].w) - _5859.x;\n        if ((_5877 > _5724) && (_5877 < _5729))\n        {\n            occ = max(occ, (1.0 - (_5752 * _5752)) * smoothstep(0.0, 0.0500000007450580596923828125, min(min(_5794, 0.5 - _5793), min(_5798, 1.0 - _5798))));\n        }\n    }\n    return 1.0 - (occ * _5710);\n}\n\nLightSample fa_light_shadowed(int li, vec3 world_pos, vec3 gn)\n{\n    int param = li;\n    float _6539 = fa_baked_keep(param);\n    if (_6539 <= 0.0)\n    {\n        int param_1 = li;\n        return LightSample(vec3(0.0, 1.0, 0.0), vec3(0.0), 0.0, 1.0, 0.0, int(fa_light_type(param_1) + 0.5));\n    }\n    int param_2 = li;\n    vec3 param_3 = world_pos;\n    vec3 param_4 = gn;\n    LightSample _6565 = fa_light_sample_n(param_2, param_3, param_4);\n    vec3 _9835 = _6565.color;\n    float _9836 = _6565.attenuation;\n    float _9837 = _6565.shadow;\n    bool _6568 = _6565.type == 0;\n    if (_6568 && (li == 0))\n    {\n        vec3 param_5 = gn;\n        vec3 param_6 = _6565.direction;\n        float _6579 = fa_shadow_factor(param_5, param_6);\n        _9837 = _6579;\n        _9835 *= _6579;\n    }\n    else\n    {\n        bool _6590 = _6565.type != 0;\n        bool _6596;\n        if (_6590)\n        {\n            _6596 = _9836 > 0.0;\n        }\n        else\n        {\n            _6596 = _6590;\n        }\n        if (_6596)\n        {\n            int param_7 = li;\n            int param_8 = fa_light_base(param_7);\n            int param_9 = li;\n            vec3 param_10 = fa_light_texel(param_8).xyz;\n            vec3 param_11 = world_pos;\n            vec3 param_12 = gn;\n            vec3 param_13 = _6565.direction;\n            float _6615 = fa_shadow_local_rt(param_9, param_10, param_11, param_12, param_13);\n            _9837 = _6615;\n            _9835 *= _6615;\n        }\n    }\n    bool _6625 = fa_mesh_fs_params[24].x > 0.5;\n    bool _6631;\n    if (_6625)\n    {\n        _6631 = _9836 > 0.0;\n    }\n    else\n    {\n        _6631 = _6625;\n    }\n    if (_6631)\n    {\n        float _6638;\n        if (_6568)\n        {\n            _6638 = 1000000000.0;\n        }\n        else\n        {\n            _6638 = _6565._distance;\n        }\n        int param_14 = li;\n        vec3 param_15 = world_pos;\n        vec3 param_16 = gn;\n        vec3 param_17 = _6565.direction;\n        float param_18 = _6638;\n        float _6656 = fa_contact_shadow(param_14, param_15, param_16, param_17, param_18);\n        _9837 *= _6656;\n        _9835 *= _6656;\n    }\n    float _6669 = _9836;\n    float _6670 = _6669 * _6539;\n    _9836 = _6670;\n    vec3 _6674 = _9835;\n    vec3 _6675 = _6674 * _6539;\n    _9835 = _6675;\n    return LightSample(_6565.direction, _6675, _6670, _9837, _6565._distance, _6565.type);\n}\n\nvec3 fa_ltc_tangent(vec3 n, vec3 v)\n{\n    vec3 _6709 = v - (n * dot(v, n));\n    vec3 t = _6709;\n    float _6713 = dot(_6709, _6709);\n    float l2 = _6713;\n    if (_6713 < 1.0000000133514319600180897396058e-10)\n    {\n        vec3 _6723;\n        if (abs(n.z) < 0.999000012874603271484375)\n        {\n            _6723 = cross(n, vec3(0.0, 0.0, 1.0));\n        }\n        else\n        {\n            _6723 = cross(n, vec3(1.0, 0.0, 0.0));\n        }\n        t = _6723;\n        l2 = dot(_6723, _6723);\n    }\n    return t * inversesqrt(l2);\n}\n\nvec3 fa_ltc_local(vec3 t1, vec3 n, vec3 p)\n{\n    return vec3(dot(t1, p), dot(cross(n, t1), p), dot(n, p));\n}\n\nvec2 fa_ltc_uv(float roughness, float ndv)\n{\n    return ((vec2(clamp((roughness - 0.0500000007450580596923828125) * 1.0526316165924072265625, 0.0, 1.0), sqrt(clamp(1.0 - ndv, 0.0, 1.0))) * 63.0) + vec2(0.5)) * vec2(0.015625);\n}\n\nvec3 fa_oct_vertex(int j, vec3 pc, vec3 ex, vec3 ey)\n{\n    float _7110;\n    if ((j == 0) || (j == 7))\n    {\n        _7110 = 0.92387950420379638671875;\n    }\n    else\n    {\n        float _7120;\n        if ((j == 3) || (j == 4))\n        {\n            _7120 = -0.92387950420379638671875;\n        }\n        else\n        {\n            _7120 = ((j == 1) || (j == 6)) ? 0.3826834261417388916015625 : (-0.3826834261417388916015625);\n        }\n        _7110 = _7120;\n    }\n    float _7141;\n    if ((j == 1) || (j == 2))\n    {\n        _7141 = 0.92387950420379638671875;\n    }\n    else\n    {\n        float _7150;\n        if ((j == 5) || (j == 6))\n        {\n            _7150 = -0.92387950420379638671875;\n        }\n        else\n        {\n            _7150 = ((j == 0) || (j == 3)) ? 0.3826834261417388916015625 : (-0.3826834261417388916015625);\n        }\n        _7141 = _7150;\n    }\n    return (pc + (ex * _7110)) + (ey * _7141);\n}\n\nvec3 fa_ltc_edge_vector(vec3 a, vec3 b)\n{\n    float _6758 = dot(a, a);\n    float _6762 = dot(b, b);\n    if ((_6758 < 1.0000000195414813782625560981111e-24) || (_6762 < 1.0000000195414813782625560981111e-24))\n    {\n        return vec3(0.0);\n    }\n    vec3 _6776 = a * inversesqrt(_6758);\n    vec3 _6781 = b * inversesqrt(_6762);\n    float _6785 = dot(_6776, _6781);\n    float _6788 = abs(_6785);\n    float g = (((((((((((0.0416471660137176513671875 * _6788) - 0.1924748718738555908203125) * _6788) + 0.4179156124591827392578125) * _6788) - 0.616057217121124267578125) * _6788) + 0.777722418308258056640625) * _6788) - 0.999542415142059326171875) * _6788) + 1.570791721343994140625;\n    if (_6785 < 0.0)\n    {\n        g = (3.1415927410125732421875 * inversesqrt(max(1.0 - (_6785 * _6785), 1.0000000116860974230803549289703e-07))) - g;\n    }\n    return cross(_6776, _6781) * g;\n}\n\nvoid fa_ltc_clip_edge(vec3 a, vec3 b, inout vec3 sum, inout vec3 leave, inout vec3 enter, inout vec2 seen)\n{\n    bool _6845 = a.z > 0.0;\n    bool _6849 = b.z > 0.0;\n    if (_6845 && _6849)\n    {\n        vec3 param = a;\n        vec3 param_1 = b;\n        sum += fa_ltc_edge_vector(param, param_1);\n    }\n    else\n    {\n        if (_6845 != _6849)\n        {\n            vec3 _6884 = a + ((b - a) * (a.z / (a.z - b.z)));\n            _6884.z = 0.0;\n            if (_6845)\n            {\n                vec3 param_2 = a;\n                vec3 param_3 = _6884;\n                sum += fa_ltc_edge_vector(param_2, param_3);\n                leave = _6884;\n                seen.x = 1.0;\n            }\n            else\n            {\n                vec3 param_4 = _6884;\n                vec3 param_5 = b;\n                sum += fa_ltc_edge_vector(param_4, param_5);\n                enter = _6884;\n                seen.y = 1.0;\n            }\n        }\n    }\n}\n\nfloat fa_ltc_quad(vec4 abcd, vec3 p0, vec3 p1, vec3 p2, vec3 p3)\n{\n    vec3 _6933 = vec3((abcd.x * p0.x) + (abcd.y * p0.z), p0.y, (abcd.z * p0.x) + (abcd.w * p0.z));\n    vec3 _6959 = vec3((abcd.x * p1.x) + (abcd.y * p1.z), p1.y, (abcd.z * p1.x) + (abcd.w * p1.z));\n    vec3 _6985 = vec3((abcd.x * p2.x) + (abcd.y * p2.z), p2.y, (abcd.z * p2.x) + (abcd.w * p2.z));\n    vec3 _7011 = vec3((abcd.x * p3.x) + (abcd.y * p3.z), p3.y, (abcd.z * p3.x) + (abcd.w * p3.z));\n    vec3 sum = vec3(0.0);\n    vec3 leave = vec3(0.0);\n    vec3 enter = vec3(0.0);\n    vec3 param = _6933;\n    vec3 param_1 = _6959;\n    vec3 param_2 = vec3(0.0);\n    vec3 param_3 = vec3(0.0);\n    vec3 param_4 = vec3(0.0);\n    vec2 param_5 = vec2(0.0);\n    fa_ltc_clip_edge(param, param_1, param_2, param_3, param_4, param_5);\n    sum = param_2;\n    leave = param_3;\n    enter = param_4;\n    vec3 param_6 = _6959;\n    vec3 param_7 = _6985;\n    vec3 param_8 = param_2;\n    vec3 param_9 = param_3;\n    vec3 param_10 = param_4;\n    vec2 param_11 = param_5;\n    fa_ltc_clip_edge(param_6, param_7, param_8, param_9, param_10, param_11);\n    sum = param_8;\n    leave = param_9;\n    enter = param_10;\n    vec3 param_12 = _6985;\n    vec3 param_13 = _7011;\n    vec3 param_14 = param_8;\n    vec3 param_15 = param_9;\n    vec3 param_16 = param_10;\n    vec2 param_17 = param_11;\n    fa_ltc_clip_edge(param_12, param_13, param_14, param_15, param_16, param_17);\n    sum = param_14;\n    leave = param_15;\n    enter = param_16;\n    vec3 param_18 = _7011;\n    vec3 param_19 = _6933;\n    vec3 param_20 = param_14;\n    vec3 param_21 = param_15;\n    vec3 param_22 = param_16;\n    vec2 param_23 = param_17;\n    fa_ltc_clip_edge(param_18, param_19, param_20, param_21, param_22, param_23);\n    sum = param_20;\n    leave = param_21;\n    enter = param_22;\n    if ((param_23.x * param_23.y) > 0.5)\n    {\n        vec3 param_24 = leave;\n        vec3 param_25 = enter;\n        sum += fa_ltc_edge_vector(param_24, param_25);\n    }\n    return sum.z * 0.15915493667125701904296875;\n}\n\nvec2 fa_area_forms(vec4 m, float shape, vec3 pc, vec3 ex, vec3 ey)\n{\n    int _7179 = ((shape < 0.5) || (shape > 1.5)) ? 1 : 3;\n    vec2 sum = vec2(0.0);\n    int _7197;\n    for (int k = 0; k < (2 * _7179); k++)\n    {\n        bool _7194 = k >= _7179;\n        if (_7194)\n        {\n            _7197 = k - _7179;\n        }\n        else\n        {\n            _7197 = k;\n        }\n        vec3 p0 = (pc - ex) - ey;\n        vec3 p1 = (pc + ex) - ey;\n        vec3 p2 = (pc + ex) + ey;\n        vec3 p3 = (pc - ex) + ey;\n        if (_7179 == 3)\n        {\n            int param = 0;\n            vec3 param_1 = pc;\n            vec3 param_2 = ex;\n            vec3 param_3 = ey;\n            p0 = fa_oct_vertex(param, param_1, param_2, param_3);\n            int _7243 = 2 * _7197;\n            int param_4 = _7243 + 1;\n            vec3 param_5 = pc;\n            vec3 param_6 = ex;\n            vec3 param_7 = ey;\n            p1 = fa_oct_vertex(param_4, param_5, param_6, param_7);\n            int param_8 = _7243 + 2;\n            vec3 param_9 = pc;\n            vec3 param_10 = ex;\n            vec3 param_11 = ey;\n            p2 = fa_oct_vertex(param_8, param_9, param_10, param_11);\n            int param_12 = _7243 + 3;\n            vec3 param_13 = pc;\n            vec3 param_14 = ex;\n            vec3 param_15 = ey;\n            p3 = fa_oct_vertex(param_12, param_13, param_14, param_15);\n        }\n        bvec4 _7280 = bvec4(_7194);\n        vec4 param_16 = vec4(_7280.x ? m.x : vec4(1.0, 0.0, 0.0, 1.0).x, _7280.y ? m.y : vec4(1.0, 0.0, 0.0, 1.0).y, _7280.z ? m.z : vec4(1.0, 0.0, 0.0, 1.0).z, _7280.w ? m.w : vec4(1.0, 0.0, 0.0, 1.0).w);\n        vec3 param_17 = p0;\n        vec3 param_18 = p1;\n        vec3 param_19 = p2;\n        vec3 param_20 = p3;\n        float _7291 = fa_ltc_quad(param_16, param_17, param_18, param_19, param_20);\n        if (_7194)\n        {\n            vec2 _10088 = sum;\n            _10088.y = _10088.y + _7291;\n            sum = _10088;\n        }\n        else\n        {\n            vec2 _10091 = sum;\n            _10091.x = _10091.x + _7291;\n            sum = _10091;\n        }\n    }\n    return abs(sum);\n}\n\nvec3 fa_area_shade(int li, vec3 world_pos, vec3 n, vec3 v, vec3 diffuse_color, vec3 f0, float f90, float roughness, float ndv, float window)\n{\n    int param = li;\n    int _7315 = fa_light_base(param);\n    int param_1 = _7315;\n    int param_2 = _7315 + 1;\n    int param_3 = _7315 + 2;\n    int param_4 = _7315 + 4;\n    vec4 _7337 = fa_light_texel(param_4);\n    int param_5 = _7315 + 5;\n    vec4 _7342 = fa_light_texel(param_5);\n    int param_6 = _7315 + 6;\n    vec4 _7347 = fa_light_texel(param_6);\n    float _7348 = _7347.w;\n    vec3 _7353 = fa_light_texel(param_1).xyz - world_pos;\n    bool _7355 = _7348 < 1.5;\n    bool _7362;\n    if (_7355)\n    {\n        _7362 = dot(normalize(fa_light_texel(param_3).xyz), _7353) >= 0.0;\n    }\n    else\n    {\n        _7362 = _7355;\n    }\n    if (_7362)\n    {\n        return vec3(0.0);\n    }\n    bool _7371 = (_7348 > 0.5) && _7355;\n    float _7375 = _7371 ? 1.0539000034332275390625 : 1.0;\n    vec3 _7378 = _7337.xyz;\n    float _7380 = _7337.w;\n    vec3 _7386 = _7342.xyz;\n    float _7388 = _7342.w;\n    vec3 up = _7386 * (_7388 * _7375);\n    float _7394;\n    if (_7371)\n    {\n        _7394 = (3.1415927410125732421875 * _7380) * _7380;\n    }\n    else\n    {\n        _7394 = (4.0 * _7380) * _7388;\n    }\n    if (_7348 > 1.5)\n    {\n        vec3 _7420 = cross(_7378, -_7353);\n        vec3 perp = _7420;\n        float _7424 = dot(_7420, _7420);\n        vec3 _7427;\n        if (_7424 > 1.0000000133514319600180897396058e-10)\n        {\n            _7427 = perp * inversesqrt(_7424);\n        }\n        else\n        {\n            _7427 = _7386;\n        }\n        perp = _7427;\n        up = _7427 * _7388;\n    }\n    float _7448 = max(_7394, 9.9999999747524270787835121154785e-07);\n    vec3 param_7 = n;\n    vec3 param_8 = v;\n    vec3 _7458 = fa_ltc_tangent(param_7, param_8);\n    vec3 param_9 = _7458;\n    vec3 param_10 = n;\n    vec3 param_11 = _7353;\n    vec3 param_12 = _7458;\n    vec3 param_13 = n;\n    vec3 param_14 = _7378 * (_7380 * _7375);\n    vec3 param_15 = _7458;\n    vec3 param_16 = n;\n    vec3 param_17 = up;\n    float param_18 = roughness;\n    float param_19 = ndv;\n    vec2 _7489 = fa_ltc_uv(param_18, param_19) * 64.0;\n    vec2 param_20 = _7489;\n    vec2 param_21 = _7489 + vec2(64.0, 0.0);\n    vec4 _7499 = fa_atlas_fetch(param_21);\n    vec4 param_22 = fa_atlas_fetch(param_20);\n    float param_23 = _7348;\n    vec3 param_24 = fa_ltc_local(param_9, param_10, param_11);\n    vec3 param_25 = fa_ltc_local(param_12, param_13, param_14);\n    vec3 param_26 = fa_ltc_local(param_15, param_16, param_17);\n    vec2 _7511 = fa_area_forms(param_22, param_23, param_24, param_25, param_26);\n    return (((diffuse_color * _7511.x) + (((f0 * _7499.x) + ((vec3(f90) - f0) * _7499.y)) * _7511.y)) * fa_light_texel(param_2).xyz) * ((((3.1415927410125732421875 * dot(_7353, _7353)) + _7448) / _7448) * window);\n}\n\nvec3 fa_light_rgb(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 1;\n    return fa_light_texel(param_1).xyz;\n}\n\nfloat fa_d_charlie(float alpha, float ndh)\n{\n    float _5405 = 1.0 / alpha;\n    return ((2.0 + _5405) * pow(sqrt(max(1.0 - (ndh * ndh), 9.9999997473787516355514526367188e-05)), _5405)) * 0.15915493667125701904296875;\n}\n\nfloat fa_v_ashikhmin(float ndl, float ndv)\n{\n    return clamp(0.25 / max((ndl + ndv) - (ndl * ndv), 9.9999997473787516355514526367188e-05), 0.0, 1.0);\n}\n\nfloat fa_layers_coat(FaLayers L, vec3 l, vec3 h, float vdh)\n{\n    float _5440 = max(dot(L.nc, l), 0.0);\n    float _5446 = max(dot(L.nc, h), 0.0);\n    float _5455 = ((_5446 * _5446) * (L.coat_a2 - 1.0)) + 1.0;\n    return (((L.coat * (0.039999999105930328369140625 + (0.959999978542327880859375 * pow(clamp(1.0 - vdh, 0.0, 1.0), 5.0)))) * (((L.coat_a2 / ((3.1415927410125732421875 * _5455) * _5455)) * (0.5 / max(mix((2.0 * _5440) * L.coat_ndv, _5440 + L.coat_ndv, L.coat_alpha), 9.9999997473787516355514526367188e-05))) * 3.1415927410125732421875)) * step(9.9999997473787516355514526367188e-05, _5440)) * _5440;\n}\n\nvec3 fa_area_layers(FaLayers L, vec3 base, int li, vec3 n, vec3 v, vec3 l, float ndv, float window)\n{\n    float _7548;\n    if (L.sheen_on)\n    {\n        _7548 = L.sheen_scale;\n    }\n    else\n    {\n        _7548 = 1.0;\n    }\n    vec3 result = base * (L.keep * _7548);\n    vec3 _7561 = normalize(l + v);\n    int param = li;\n    vec3 _7572 = fa_light_rgb(param) * window;\n    if (L.sheen_on)\n    {\n        float _7581 = max(dot(n, l), 0.0);\n        float param_1 = L.sheen_alpha;\n        float param_2 = max(dot(n, _7561), 0.0);\n        float param_3 = _7581;\n        float param_4 = ndv;\n        result += ((L.sheen * _7572) * (((((fa_d_charlie(param_1, param_2) * fa_v_ashikhmin(param_3, param_4)) * 3.1415927410125732421875) * step(9.9999997473787516355514526367188e-05, _7581)) * _7581) * L.keep));\n    }\n    if (L.coat > 0.0)\n    {\n        FaLayers param_5 = L;\n        vec3 param_6 = l;\n        vec3 param_7 = _7561;\n        float param_8 = max(dot(v, _7561), 0.0);\n        result += (_7572 * fa_layers_coat(param_5, param_6, param_7, param_8));\n    }\n    return result;\n}\n\nfloat fa_d_ggx_aniso(float ndh, float tdh, float bdh, float at, float ab)\n{\n    float _5308 = tdh / at;\n    float _5312 = bdh / ab;\n    float _5324 = ((_5308 * _5308) + (_5312 * _5312)) + (ndh * ndh);\n    return 1.0 / ((((3.1415927410125732421875 * at) * ab) * _5324) * _5324);\n}\n\nfloat fa_lambda_ggx_aniso(float n, float t, float b, float at, float ab)\n{\n    return 0.5 * (sqrt(1.0 + (((((at * at) * t) * t) + (((ab * ab) * b) * b)) / max(n * n, 9.9999999392252902907785028219223e-09))) - 1.0);\n}\n\nfloat fa_v_ggx_aniso(float ndl, float ndv, float tdv, float bdv, float tdl, float bdl, float at, float ab)\n{\n    float param = ndv;\n    float param_1 = tdv;\n    float param_2 = bdv;\n    float param_3 = at;\n    float param_4 = ab;\n    float param_5 = ndl;\n    float param_6 = tdl;\n    float param_7 = bdl;\n    float param_8 = at;\n    float param_9 = ab;\n    return clamp(1.0 / ((4.0 * max(ndl * ndv, 9.9999997473787516355514526367188e-05)) * ((1.0 + fa_lambda_ggx_aniso(param, param_1, param_2, param_3, param_4)) + fa_lambda_ggx_aniso(param_5, param_6, param_7, param_8, param_9))), 0.0, 1.0);\n}\n\nvec3 fa_layers_light(FaLayers L, vec3 diffuse_color, vec3 f0, vec3 n, vec3 v, vec3 l, vec3 h, float ndl, float ndv, float ndh, float vdh, float alpha, float a2)\n{\n    float _5504 = step(9.9999997473787516355514526367188e-05, ndl);\n    float d_ggx;\n    float vis;\n    if (L.aniso != 0.0)\n    {\n        float param = ndh;\n        float param_1 = dot(L.t, h);\n        float param_2 = dot(L.b, h);\n        float param_3 = L.at;\n        float param_4 = L.ab;\n        d_ggx = fa_d_ggx_aniso(param, param_1, param_2, param_3, param_4);\n        float param_5 = ndl;\n        float param_6 = ndv;\n        float param_7 = dot(L.t, v);\n        float param_8 = dot(L.b, v);\n        float param_9 = dot(L.t, l);\n        float param_10 = dot(L.b, l);\n        float param_11 = L.at;\n        float param_12 = L.ab;\n        vis = fa_v_ggx_aniso(param_5, param_6, param_7, param_8, param_9, param_10, param_11, param_12);\n    }\n    else\n    {\n        float _5583 = ((ndh * ndh) * (a2 - 1.0)) + 1.0;\n        d_ggx = a2 / ((3.1415927410125732421875 * _5583) * _5583);\n        vis = 0.5 / max(mix((2.0 * ndl) * ndv, ndl + ndv, alpha), 9.9999997473787516355514526367188e-05);\n    }\n    vec3 base = diffuse_color + (((f0 + ((vec3(L.f90) - f0) * pow(clamp(1.0 - vdh, 0.0, 1.0), 5.0))) * ((d_ggx * vis) * 3.1415927410125732421875)) * _5504);\n    if (L.sheen_on)\n    {\n        float param_13 = L.sheen_alpha;\n        float param_14 = ndh;\n        float param_15 = ndl;\n        float param_16 = ndv;\n        base = (base * L.sheen_scale) + (L.sheen * (((fa_d_charlie(param_13, param_14) * fa_v_ashikhmin(param_15, param_16)) * 3.1415927410125732421875) * _5504));\n    }\n    vec3 result = base * (L.keep * ndl);\n    if (L.coat > 0.0)\n    {\n        FaLayers param_17 = L;\n        vec3 param_18 = l;\n        vec3 param_19 = h;\n        float param_20 = vdh;\n        result += vec3(fa_layers_coat(param_17, param_18, param_19, param_20));\n    }\n    return result;\n}\n\nvec2 fa_env_brdf(float rough, float ndv)\n{\n    vec4 _4707 = (vec4(-1.0, -0.0274999998509883880615234375, -0.572000026702880859375, 0.02199999988079071044921875) * rough) + vec4(1.0, 0.0425000004470348358154296875, 1.03999996185302734375, -0.039999999105930328369140625);\n    float _4710 = _4707.x;\n    return (vec2(-1.03999996185302734375, 1.03999996185302734375) * ((min(_4710 * _4710, exp2((-9.27999973297119140625) * ndv)) * _4710) + _4707.y)) + _4707.zw;\n}\n\nvec3 fa_probe_level(vec2 origin, float res, int lv, vec2 e)\n{\n    float _4018;\n    if (lv == 0)\n    {\n        _4018 = 0.0;\n    }\n    else\n    {\n        _4018 = res + 2.0;\n    }\n    float _4028;\n    if (lv == 0)\n    {\n        _4028 = 0.0;\n    }\n    else\n    {\n        _4028 = (res - (res / float(1 << max((lv - 1), 0)))) + (2.0 * float(lv - 1));\n    }\n    return textureLod(fa_probe_atlas_fa_env_smp, (((origin + vec2(_4018, _4028)) + vec2(1.0)) + (((e * 0.5) + vec2(0.5)) * (res / float(1 << lv)))) / fa_atlas_size(), 0.0).xyz;\n}\n\nvec3 fa_probe_radiance(vec2 origin, float res, vec3 d, float rough)\n{\n    float _4074;\n    if (res > 64.5)\n    {\n        _4074 = 5.0;\n    }\n    else\n    {\n        _4074 = (res > 32.5) ? 4.0 : 3.0;\n    }\n    float _4089 = clamp(rough, 0.0, 1.0) * (_4074 - 1.0);\n    int _4096 = int(min(floor(_4089), _4074 - 2.0));\n    float _4101 = _4089 - float(_4096);\n    vec3 param = d;\n    vec2 _4105 = fa_oct_encode(param);\n    vec2 param_1 = origin;\n    float param_2 = res;\n    int param_3 = _4096;\n    vec2 param_4 = _4105;\n    vec3 _4115 = fa_probe_level(param_1, param_2, param_3, param_4);\n    if (_4101 < 0.00200000009499490261077880859375)\n    {\n        return _4115;\n    }\n    vec2 param_5 = origin;\n    float param_6 = res;\n    int param_7 = _4096 + 1;\n    vec2 param_8 = _4105;\n    return mix(_4115, fa_probe_level(param_5, param_6, param_7, param_8), vec3(_4101));\n}\n\nvec3 fa_probe_box_dir(vec3 d, vec4 posw, vec4 bx, vec4 by, vec4 bz)\n{\n    if (posw.w < 0.5)\n    {\n        return d;\n    }\n    float _4186 = dot(bx.xyz, fa_world_pos) + bx.w;\n    float _4193 = dot(by.xyz, fa_world_pos) + by.w;\n    float _4200 = dot(bz.xyz, fa_world_pos) + bz.w;\n    float _4206 = dot(bx.xyz, d);\n    float _4210 = dot(by.xyz, d);\n    float _4214 = dot(bz.xyz, d);\n    float _4220;\n    if (_4206 > 9.9999999747524270787835121154785e-07)\n    {\n        _4220 = (1.0 - _4186) / _4206;\n    }\n    else\n    {\n        float _4234;\n        if (_4206 < (-9.9999999747524270787835121154785e-07))\n        {\n            _4234 = ((-1.0) - _4186) / _4206;\n        }\n        else\n        {\n            _4234 = 1000000015047466219876688855040.0;\n        }\n        _4220 = _4234;\n    }\n    float tx = _4220;\n    float _4251;\n    if (_4210 > 9.9999999747524270787835121154785e-07)\n    {\n        _4251 = (1.0 - _4193) / _4210;\n    }\n    else\n    {\n        float _4264;\n        if (_4210 < (-9.9999999747524270787835121154785e-07))\n        {\n            _4264 = ((-1.0) - _4193) / _4210;\n        }\n        else\n        {\n            _4264 = 1000000015047466219876688855040.0;\n        }\n        _4251 = _4264;\n    }\n    float ty = _4251;\n    float _4280;\n    if (_4214 > 9.9999999747524270787835121154785e-07)\n    {\n        _4280 = (1.0 - _4200) / _4214;\n    }\n    else\n    {\n        float _4293;\n        if (_4214 < (-9.9999999747524270787835121154785e-07))\n        {\n            _4293 = ((-1.0) - _4200) / _4214;\n        }\n        else\n        {\n            _4293 = 1000000015047466219876688855040.0;\n        }\n        _4280 = _4293;\n    }\n    float _4305 = tx;\n    float _4308 = (_4305 > 0.0) ? _4305 : 1000000015047466219876688855040.0;\n    tx = _4308;\n    float _4309 = ty;\n    float _4312 = (_4309 > 0.0) ? _4309 : 1000000015047466219876688855040.0;\n    ty = _4312;\n    float _4322 = min(_4308, min(_4312, (_4280 > 0.0) ? _4280 : 1000000015047466219876688855040.0));\n    if (_4322 > 100000001504746621987668885504.0)\n    {\n        return d;\n    }\n    vec3 _4338 = (fa_world_pos + (d * _4322)) - posw.xyz;\n    vec3 _4343;\n    if (dot(_4338, _4338) > 1.0000000133514319600180897396058e-10)\n    {\n        _4343 = normalize(_4338);\n    }\n    else\n    {\n        _4343 = d;\n    }\n    return _4343;\n}\n\nvec3 fa_probe_environment(vec4 tile, vec4 posw, vec4 bx, vec4 by, vec4 bz, inout vec3 d, float rough)\n{\n    vec3 param = d;\n    vec4 param_1 = posw;\n    vec4 param_2 = bx;\n    vec4 param_3 = by;\n    vec4 param_4 = bz;\n    d = fa_probe_box_dir(param, param_1, param_2, param_3, param_4);\n    vec2 param_5 = tile.xy;\n    float param_6 = tile.z;\n    vec3 param_7 = d;\n    float param_8 = rough;\n    return fa_probe_radiance(param_5, param_6, param_7, param_8);\n}\n\nvec3 fa_environment(vec3 d, float rough)\n{\n    float _4389 = (1.0 - fa_mesh_fs_params[42].w) - fa_mesh_fs_params[47].w;\n    vec3 outc = vec3(0.0);\n    if (_4389 > 0.0005000000237487256526947021484375)\n    {\n        vec3 base;\n        if (fa_mesh_fs_params[11].w > 0.5)\n        {\n            vec2 param = fa_mesh_fs_params[41].zw;\n            float param_1 = 128.0;\n            vec3 param_2 = d;\n            float param_3 = rough;\n            base = fa_probe_radiance(param, param_1, param_2, param_3);\n        }\n        else\n        {\n            float _4417 = rough * rough;\n            float _4448 = 0.60000002384185791015625 * _4417;\n            base = mix(mix(fa_mesh_fs_params[12].xyz * 0.550000011920928955078125, mix(fa_mesh_fs_params[12].xyz, fa_mesh_fs_params[11].xyz, vec3(pow(clamp(d.y * (1.0 - (0.699999988079071044921875 * _4417)), 0.0, 1.0), 0.550000011920928955078125))), vec3(smoothstep((-0.0500000007450580596923828125) - _4448, 0.0500000007450580596923828125 + _4448, d.y))), ((fa_mesh_fs_params[11].xyz + fa_mesh_fs_params[12].xyz) * 0.5) * 0.800000011920928955078125, vec3(_4417 * 0.60000002384185791015625));\n        }\n        outc = base * _4389;\n    }\n    if (fa_mesh_fs_params[42].w > 0.0)\n    {\n        vec4 param_4 = fa_mesh_fs_params[42];\n        vec4 param_5 = fa_mesh_fs_params[43];\n        vec4 param_6 = fa_mesh_fs_params[44];\n        vec4 param_7 = fa_mesh_fs_params[45];\n        vec4 param_8 = fa_mesh_fs_params[46];\n        vec3 param_9 = d;\n        float param_10 = rough;\n        vec3 _4507 = fa_probe_environment(param_4, param_5, param_6, param_7, param_8, param_9, param_10);\n        outc += (_4507 * fa_mesh_fs_params[42].w);\n    }\n    if (fa_mesh_fs_params[47].w > 0.0)\n    {\n        vec4 param_11 = fa_mesh_fs_params[47];\n        vec4 param_12 = fa_mesh_fs_params[48];\n        vec4 param_13 = fa_mesh_fs_params[49];\n        vec4 param_14 = fa_mesh_fs_params[50];\n        vec4 param_15 = fa_mesh_fs_params[51];\n        vec3 param_16 = d;\n        float param_17 = rough;\n        vec3 _4539 = fa_probe_environment(param_11, param_12, param_13, param_14, param_15, param_16, param_17);\n        outc += (_4539 * fa_mesh_fs_params[47].w);\n    }\n    return outc;\n}\n\nvec3 fa_layers_ibl(FaLayers L, vec3 n, vec3 v, vec3 f0, float roughness, float occlusion)\n{\n    vec3 rn = n;\n    if (L.aniso != 0.0)\n    {\n        vec3 _5185;\n        if (L.aniso >= 0.0)\n        {\n            _5185 = L.b;\n        }\n        else\n        {\n            _5185 = L.t;\n        }\n        rn = normalize(mix(n, cross(cross(_5185, v), _5185), vec3(abs(L.aniso) * smoothstep(0.0, 0.25, roughness))));\n    }\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05);\n    vec2 _5221 = fa_env_brdf(param, param_1);\n    vec3 param_2 = reflect(-v, rn);\n    float param_3 = roughness;\n    vec3 result = (fa_environment(param_2, param_3) * ((f0 * _5221.x) + (vec3(L.f90) * _5221.y))) * L.base_scale;\n    if (L.sheen_on)\n    {\n        vec3 param_4 = n;\n        float param_5 = L.sheen_rough;\n        result += ((L.sheen * (L.sheen_e * L.keep)) * fa_environment(param_4, param_5));\n    }\n    result *= occlusion;\n    if (L.coat > 0.0)\n    {\n        float param_6 = L.coat_rough;\n        float param_7 = L.coat_ndv;\n        vec2 _5279 = fa_env_brdf(param_6, param_7);\n        vec3 param_8 = reflect(-v, L.nc);\n        float param_9 = L.coat_rough;\n        result += (fa_environment(param_8, param_9) * (L.coat * ((0.039999999105930328369140625 * _5279.x) + _5279.y)));\n    }\n    return result;\n}\n\nvec3 fa_sky_reflection(vec3 n, vec3 v, vec3 f0, float roughness)\n{\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05);\n    vec2 _4749 = fa_env_brdf(param, param_1);\n    vec3 param_2 = reflect(-v, n);\n    float param_3 = roughness;\n    return fa_environment(param_2, param_3) * ((f0 * _4749.x) + vec3(_4749.y));\n}\n\nvec2 fa_xm_size(int k)\n{\n    return max(floor(fa_mesh_fs_params[24].zw / vec2(float(1 << k))), vec2(1.0));\n}\n\nvec2 fa_xm_origin(int k)\n{\n    if (k == 0)\n    {\n        return vec2(0.0);\n    }\n    float y = 0.0;\n    for (int j = 1; j < k; j++)\n    {\n        int param = j;\n        y += fa_xm_size(param).y;\n    }\n    return vec2(fa_mesh_fs_params[24].z, y);\n}\n\nvec3 fa_xm_texel(vec2 size, vec2 origin, vec2 p)\n{\n    return texelFetch(fa_screen_tex_fa_shadow_smp, ivec2(origin + clamp(p, vec2(0.0), size - vec2(1.0))), 0).xyz;\n}\n\nvec3 fa_xm_level(int k, vec2 uv)\n{\n    int param = k;\n    vec2 _5981 = fa_xm_size(param);\n    int param_1 = k;\n    vec2 _5985 = fa_xm_origin(param_1);\n    vec2 _5991 = (uv * _5981) - vec2(0.5);\n    vec2 _5994 = fract(_5991);\n    vec2 _5997 = floor(_5991);\n    vec2 param_2 = _5981;\n    vec2 param_3 = _5985;\n    vec2 param_4 = _5997;\n    vec2 param_5 = _5981;\n    vec2 param_6 = _5985;\n    vec2 param_7 = _5997 + vec2(1.0, 0.0);\n    vec2 param_8 = _5981;\n    vec2 param_9 = _5985;\n    vec2 param_10 = _5997 + vec2(0.0, 1.0);\n    vec2 param_11 = _5981;\n    vec2 param_12 = _5985;\n    vec2 param_13 = _5997 + vec2(1.0);\n    vec3 _6039 = vec3(_5994.x);\n    return mix(mix(fa_xm_texel(param_2, param_3, param_4), fa_xm_texel(param_5, param_6, param_7), _6039), mix(fa_xm_texel(param_8, param_9, param_10), fa_xm_texel(param_11, param_12, param_13), _6039), vec3(_5994.y));\n}\n\nvec3 fa_xm_sample(vec2 uv, float lod)\n{\n    float _6058 = max(fa_mesh_fs_params[31].w - 1.0, 0.0);\n    float _6062 = clamp(lod, 0.0, _6058);\n    int _6066 = int(floor(_6062));\n    int param = _6066;\n    vec2 param_1 = uv;\n    vec3 c = fa_xm_level(param, param_1);\n    float _6076 = float(_6066);\n    float _6077 = _6062 - _6076;\n    bool _6079 = _6077 > 0.001000000047497451305389404296875;\n    bool _6086;\n    if (_6079)\n    {\n        _6086 = _6076 < _6058;\n    }\n    else\n    {\n        _6086 = _6079;\n    }\n    if (_6086)\n    {\n        int param_2 = _6066 + 1;\n        vec2 param_3 = uv;\n        c = mix(c, fa_xm_level(param_2, param_3), vec3(_6077));\n    }\n    return c;\n}\n\nvec3 fa_transmitted(Surface s, vec3 n, vec3 v, float roughness, vec3 f0, float f90, float keep, float tr, inout float blend)\n{\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05);\n    vec2 _6112 = fa_env_brdf(param, param_1);\n    vec3 _6136 = ((vec3(1.0) - clamp((f0 * _6112.x) + (vec3(f90) * _6112.y), vec3(0.0), vec3(1.0))) * s.albedo) * (tr * keep);\n    vec3 through = _6136;\n    float _6142 = max(s.thickness, 0.0);\n    bool _6147 = _6142 > 0.0;\n    if ((s.attenuation_distance > 0.0) && _6147)\n    {\n        through *= exp((-((-log(clamp(s.attenuation_color, vec3(9.9999997473787516355514526367188e-05), vec3(1.0)))) / vec3(s.attenuation_distance))) * _6142);\n    }\n    bool _6172 = fa_mesh_fs_params[30].w > 1.5;\n    bool _6178;\n    if (_6172)\n    {\n        _6178 = fa_mesh_fs_params[30].w < 2.5;\n    }\n    else\n    {\n        _6178 = _6172;\n    }\n    bool _6185;\n    if (!_6178)\n    {\n        _6185 = fa_mesh_fs_params[30].w < 0.5;\n    }\n    else\n    {\n        _6185 = _6178;\n    }\n    if (_6185)\n    {\n        blend = clamp(dot(through, vec3(0.3333333432674407958984375)), 0.0, 0.980000019073486328125);\n        return vec3(0.0);\n    }\n    vec4 _6200 = vec4(fa_world_pos, 1.0);\n    float _6205 = dot(fa_mesh_fs_params[28], _6200);\n    vec2 uv0 = vec2(0.5);\n    if (_6205 > 9.9999997473787516355514526367188e-05)\n    {\n        vec2 _6223 = vec2(dot(fa_mesh_fs_params[26], _6200), dot(fa_mesh_fs_params[27], _6200)) / vec2(_6205);\n        float _6231;\n        if (fa_mesh_fs_params[24].y > 0.5)\n        {\n            _6231 = (_6223.y * 0.5) + 0.5;\n        }\n        else\n        {\n            _6231 = 0.5 - (_6223.y * 0.5);\n        }\n        uv0 = vec2((_6223.x * 0.5) + 0.5, _6231);\n    }\n    if (fa_mesh_fs_params[30].w > 2.5)\n    {\n        int param_2 = 0;\n        vec2 _6252 = fa_xm_size(param_2);\n        vec2 _6260 = floor(clamp(uv0, vec2(0.0), vec2(0.99989998340606689453125)) * _6252);\n        if (texelFetch(fa_screen_tex_fa_shadow_smp, ivec2(_6260), 0).w > 0.5)\n        {\n            int _6280 = int(floor((clamp(roughness, 0.0, 1.0) * 2.0) + 0.5));\n            vec3 acc = vec3(0.0);\n            float cnt = 0.0;\n            for (int dy = -2; dy <= 2; dy++)\n            {\n                for (int dx = -2; dx <= 2; dx++)\n                {\n                    bool _6303 = abs(dx) > _6280;\n                    bool _6311;\n                    if (!_6303)\n                    {\n                        _6311 = abs(dy) > _6280;\n                    }\n                    else\n                    {\n                        _6311 = _6303;\n                    }\n                    if (_6311)\n                    {\n                        continue;\n                    }\n                    vec4 _6332 = texelFetch(fa_screen_tex_fa_shadow_smp, ivec2(clamp(_6260 + vec2(float(dx), float(dy)), vec2(0.0), _6252 - vec2(1.0))), 0);\n                    if (_6332.w > 0.5)\n                    {\n                        acc += _6332.xyz;\n                        cnt += 1.0;\n                    }\n                }\n            }\n            return _6136 * (acc / vec3(max(cnt, 1.0)));\n        }\n    }\n    vec2 uv = uv0;\n    if (_6147)\n    {\n        vec4 _6380 = vec4(fa_world_pos + (refract(-v, n, 1.0 / max(s.ior, 1.0)) * _6142), 1.0);\n        float _6385 = dot(fa_mesh_fs_params[28], _6380);\n        uv = vec2(0.5);\n        if (_6385 > 9.9999997473787516355514526367188e-05)\n        {\n            vec2 _6402 = vec2(dot(fa_mesh_fs_params[26], _6380), dot(fa_mesh_fs_params[27], _6380)) / vec2(_6385);\n            float _6410;\n            if (fa_mesh_fs_params[24].y > 0.5)\n            {\n                _6410 = (_6402.y * 0.5) + 0.5;\n            }\n            else\n            {\n                _6410 = 0.5 - (_6402.y * 0.5);\n            }\n            uv = vec2((_6402.x * 0.5) + 0.5, _6410);\n        }\n    }\n    vec2 param_3 = clamp(uv, vec2(0.0), vec2(1.0));\n    float param_4 = (clamp(roughness, 0.0, 1.0) * clamp((2.0 * s.ior) - 2.0, 0.0, 1.0)) * max(fa_mesh_fs_params[31].w - 1.0, 0.0);\n    return through * fa_xm_sample(param_3, param_4);\n}\n\nvec3 fa_shadow_debug(vec3 color, vec3 world)\n{\n    if (fa_shadows[27].w < 0.5)\n    {\n        return color;\n    }\n    int _3314 = int(fa_shadows[25].x + 0.5);\n    float _3324 = dot(world - fa_shadows[27].xyz, fa_shadows[28].xyz);\n    vec3 tint = vec3(0.3499999940395355224609375);\n    bool _3329 = _3314 > 0;\n    bool _3338;\n    if (_3329)\n    {\n        int param = _3314 - 1;\n        _3338 = _3324 <= fa_shadow_split_at(param);\n    }\n    else\n    {\n        _3338 = _3329;\n    }\n    if (_3338)\n    {\n        tint = vec3(1.0, 0.1500000059604644775390625, 0.100000001490116119384765625);\n        bool _3344 = _3314 > 1;\n        bool _3351;\n        if (_3344)\n        {\n            _3351 = _3324 > fa_shadows[24].x;\n        }\n        else\n        {\n            _3351 = _3344;\n        }\n        if (_3351)\n        {\n            tint = vec3(0.100000001490116119384765625, 0.89999997615814208984375, 0.20000000298023223876953125);\n        }\n        bool _3357 = _3314 > 2;\n        bool _3364;\n        if (_3357)\n        {\n            _3364 = _3324 > fa_shadows[24].y;\n        }\n        else\n        {\n            _3364 = _3357;\n        }\n        if (_3364)\n        {\n            tint = vec3(0.1500000059604644775390625, 0.300000011920928955078125, 1.0);\n        }\n        bool _3370 = _3314 > 3;\n        bool _3377;\n        if (_3370)\n        {\n            _3377 = _3324 > fa_shadows[24].z;\n        }\n        else\n        {\n            _3377 = _3370;\n        }\n        if (_3377)\n        {\n            tint = vec3(1.0, 0.89999997615814208984375, 0.100000001490116119384765625);\n        }\n    }\n    return mix(color, tint, vec3(0.550000011920928955078125));\n}\n\nvoid main()\n{\n    fa_rt_slope = 0.0;\n    fa_inst_load();\n    vec3 _9494 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _9494 = -_9494;\n    }\n    vec3 _8780 = normalize(fa_mesh_fs_params[0].xyz - fa_world_pos);\n    vec3 param = fa_world_pos;\n    fa_cluster_begin(param);\n    SurfaceInput param_1 = SurfaceInput(fa_world_pos, _9494, fa_world_tangent, fa_uv, fa_vertex_color, _8780, gl_FrontFacing);\n    Surface _8788 = fa_standard_surface(param_1);\n    vec3 _9525 = _8788.albedo;\n    float _9526 = _8788.alpha;\n    vec3 _9527 = _8788.normal;\n    float _9528 = _8788.metallic;\n    float _9529 = _8788.roughness;\n    float _9530 = _8788.occlusion;\n    vec3 _9531 = _8788.emission;\n    float _9532 = _8788.clearcoat;\n    float _9533 = _8788.clearcoat_roughness;\n    vec3 _9534 = _8788.sheen_color;\n    float _9535 = _8788.sheen_roughness;\n    float _9536 = _8788.anisotropy;\n    float _9537 = _8788.anisotropy_rotation;\n    float _9538 = _8788.specular;\n    float _9539 = _8788.ior;\n    vec3 _9540 = _8788.specular_color;\n    float _9541 = _8788.transmission;\n    float _9542 = _8788.thickness;\n    vec3 _9543 = _8788.attenuation_color;\n    float _9544 = _8788.attenuation_distance;\n    SurfaceInput param_2 = SurfaceInput(fa_world_pos, _9494, fa_world_tangent, fa_uv, fa_vertex_color, _8780, gl_FrontFacing);\n    Surface param_3 = _8788;\n    surface(param_2, param_3);\n    _9525 = param_3.albedo;\n    _9526 = param_3.alpha;\n    _9527 = param_3.normal;\n    _9528 = param_3.metallic;\n    _9529 = param_3.roughness;\n    _9530 = param_3.occlusion;\n    _9531 = param_3.emission;\n    _9532 = param_3.clearcoat;\n    _9533 = param_3.clearcoat_roughness;\n    _9534 = param_3.sheen_color;\n    _9535 = param_3.sheen_roughness;\n    _9536 = param_3.anisotropy;\n    _9537 = param_3.anisotropy_rotation;\n    _9538 = param_3.specular;\n    _9539 = param_3.ior;\n    _9540 = param_3.specular_color;\n    _9541 = param_3.transmission;\n    _9542 = param_3.thickness;\n    _9543 = param_3.attenuation_color;\n    _9544 = param_3.attenuation_distance;\n    vec3 param_4 = fa_world_pos;\n    vec3 param_5 = _9494;\n    vec3 param_6 = param_3.albedo;\n    vec3 param_7 = param_3.normal;\n    fa_apply_decals(param_4, param_5, param_6, param_7);\n    _9525 = param_6;\n    _9527 = param_7;\n    if (_9526 < fa_material[0].x)\n    {\n        discard;\n    }\n    fa_lod_dither();\n    float fa_tr_blend = 0.0;\n    vec3 result;\n    if (fa_mesh_fs_params[3].w > 0.5)\n    {\n        result = _9525;\n    }\n    else\n    {\n        vec3 _8840 = normalize(_9527);\n        float _8847 = clamp(_9528, 0.0, 1.0);\n        float _8851 = clamp(_9529, 0.0500000007450580596923828125, 1.0);\n        float _8855 = _8851 * _8851;\n        float _8859 = _8855 * _8855;\n        float _8864 = max(dot(_8840, _8780), 9.9999997473787516355514526367188e-05);\n        float _8870 = 1.0 - _8847;\n        float _8871 = clamp(_9541, 0.0, 1.0) * _8870;\n        vec3 _8880 = (_9525 * _8870) * (1.0 - _8871);\n        vec3 _8887 = mix(vec3(0.039999999105930328369140625), _9525, vec3(_8847));\n        vec3 f0 = _8887;\n        SurfaceInput param_8 = SurfaceInput(fa_world_pos, _9494, fa_world_tangent, fa_uv, fa_vertex_color, _8780, gl_FrontFacing);\n        Surface param_9 = Surface(_9525, _9526, _9527, _9528, _9529, _9530, _9531, _9532, _9533, _9534, _9535, _9536, _9537, _9538, _9539, _9540, _9541, _9542, _9543, _9544);\n        vec3 param_10 = _8840;\n        vec3 param_11 = _8780;\n        float param_12 = _8847;\n        float param_13 = _8851;\n        vec3 param_14 = _8887;\n        FaLayers _8903 = fa_layers_setup(param_8, param_9, param_10, param_11, param_12, param_13, param_14);\n        f0 = param_14;\n        vec3 param_15 = _8840;\n        vec3 lit = (fa_indirect_diffuse(param_15) * _8880) * _9530;\n        if (_8903.on)\n        {\n            lit *= _8903.base_scale;\n        }\n        int _8925 = fa_cl_ndir + fa_cl_local;\n        float _8990;\n        for (int ln = 0; ln < _8925; ln++)\n        {\n            int param_16 = ln;\n            int _8938 = fa_cl_light(param_16);\n            int param_17 = _8938;\n            if (fa_baked_keep(param_17) <= 0.0)\n            {\n                continue;\n            }\n            int param_18 = _8938;\n            vec3 param_19 = fa_world_pos;\n            vec3 param_20 = _9494;\n            LightSample _8954 = fa_light_shadowed(param_18, param_19, param_20);\n            float _8962 = max(dot(_8840, _8954.direction), 0.0);\n            float _8968 = _8954.attenuation * _8954.shadow;\n            vec3 _8973 = normalize(_8954.direction + _8780);\n            float _8978 = max(dot(_8840, _8973), 0.0);\n            float _8983 = max(dot(_8780, _8973), 0.0);\n            if (fa_light_is_area)\n            {\n                if (_8903.on)\n                {\n                    _8990 = _8903.f90;\n                }\n                else\n                {\n                    _8990 = 1.0;\n                }\n                int param_21 = _8938;\n                vec3 param_22 = fa_world_pos;\n                vec3 param_23 = _8840;\n                vec3 param_24 = _8780;\n                vec3 param_25 = _8880;\n                vec3 param_26 = f0;\n                float param_27 = _8990;\n                float param_28 = _8851;\n                float param_29 = _8864;\n                float param_30 = _8968;\n                vec3 area = fa_area_shade(param_21, param_22, param_23, param_24, param_25, param_26, param_27, param_28, param_29, param_30);\n                if (_8903.on)\n                {\n                    FaLayers param_31 = _8903;\n                    vec3 param_32 = area;\n                    int param_33 = _8938;\n                    vec3 param_34 = _8840;\n                    vec3 param_35 = _8780;\n                    vec3 param_36 = _8954.direction;\n                    float param_37 = _8864;\n                    float param_38 = _8968;\n                    area = fa_area_layers(param_31, param_32, param_33, param_34, param_35, param_36, param_37, param_38);\n                }\n                lit += area;\n            }\n            else\n            {\n                if (_8903.on)\n                {\n                    FaLayers param_39 = _8903;\n                    vec3 param_40 = _8880;\n                    vec3 param_41 = f0;\n                    vec3 param_42 = _8840;\n                    vec3 param_43 = _8780;\n                    vec3 param_44 = _8954.direction;\n                    vec3 param_45 = _8973;\n                    float param_46 = _8962;\n                    float param_47 = _8864;\n                    float param_48 = _8978;\n                    float param_49 = _8983;\n                    float param_50 = _8855;\n                    float param_51 = _8859;\n                    int param_52 = _8938;\n                    lit += (fa_layers_light(param_39, param_40, param_41, param_42, param_43, param_44, param_45, param_46, param_47, param_48, param_49, param_50, param_51) * ((fa_light_rgb(param_52) * fa_light_tint) * _8968));\n                }\n                else\n                {\n                    float _9092 = ((_8978 * _8978) * (_8859 - 1.0)) + 1.0;\n                    int param_53 = _8938;\n                    lit += (((_8880 + (((f0 + ((vec3(1.0) - f0) * pow(1.0 - _8983, 5.0))) * (((_8859 / ((3.1415927410125732421875 * _9092) * _9092)) * (0.5 / max(mix((2.0 * _8962) * _8864, _8962 + _8864, _8855), 9.9999997473787516355514526367188e-05))) * 3.1415927410125732421875)) * step(9.9999997473787516355514526367188e-05, _8962))) * (fa_light_rgb(param_53) * fa_light_tint)) * (_8962 * _8968));\n                }\n            }\n        }\n        if (_8903.on)\n        {\n            FaLayers param_54 = _8903;\n            vec3 param_55 = _8840;\n            vec3 param_56 = _8780;\n            vec3 param_57 = f0;\n            float param_58 = _8851;\n            float param_59 = _9530;\n            lit += fa_layers_ibl(param_54, param_55, param_56, param_57, param_58, param_59);\n        }\n        else\n        {\n            vec3 param_60 = _8840;\n            vec3 param_61 = _8780;\n            vec3 param_62 = f0;\n            float param_63 = _8851;\n            lit += (fa_sky_reflection(param_60, param_61, param_62, param_63) * _9530);\n        }\n        if (_8871 > 0.0)\n        {\n            float _9190;\n            if (_8903.on)\n            {\n                _9190 = _8903.f90;\n            }\n            else\n            {\n                _9190 = 1.0;\n            }\n            float _9198;\n            if (_8903.on)\n            {\n                _9198 = _8903.base_scale;\n            }\n            else\n            {\n                _9198 = 1.0;\n            }\n            Surface param_64 = Surface(_9525, _9526, _9527, _9528, _9529, _9530, _9531, _9532, _9533, _9534, _9535, _9536, _9537, _9538, _9539, _9540, _9541, _9542, _9543, _9544);\n            vec3 param_65 = _8840;\n            vec3 param_66 = _8780;\n            float param_67 = _8851;\n            vec3 param_68 = f0;\n            float param_69 = _9190;\n            float param_70 = _9198;\n            float param_71 = _8871;\n            float param_72 = fa_tr_blend;\n            vec3 _9222 = fa_transmitted(param_64, param_65, param_66, param_67, param_68, param_69, param_70, param_71, param_72);\n            fa_tr_blend = param_72;\n            lit += _9222;\n        }\n        result = lit;\n    }\n    vec3 _9229 = result;\n    vec3 _9230 = _9229 + _9531;\n    result = _9230;\n    vec3 param_73 = _9230;\n    vec3 param_74 = fa_world_pos;\n    result = fa_shadow_debug(param_73, param_74);\n    bool _9239 = fa_mesh_fs_params[7].w > 0.0;\n    bool _9246;\n    if (!_9239)\n    {\n        _9246 = fa_mesh_fs_params[8].y > 0.0;\n    }\n    else\n    {\n        _9246 = _9239;\n    }\n    if (_9246)\n    {\n        vec3 _9255 = fa_world_pos - fa_mesh_fs_params[0].xyz;\n        float _9261 = dot(_9255, fa_mesh_fs_params[9].xyz);\n        bool _9265 = fa_mesh_fs_params[9].w > 0.5;\n        float _9266;\n        if (_9265)\n        {\n            _9266 = _9261;\n        }\n        else\n        {\n            _9266 = length(_9255);\n        }\n        float _9278 = _9266 - fa_mesh_fs_params[8].x;\n        if (_9278 > 0.0)\n        {\n            float _9287 = fa_mesh_fs_params[7].w * _9278;\n            float tau = _9287 * _9287;\n            if (fa_mesh_fs_params[8].y > 0.0)\n            {\n                float _9303;\n                if (_9265)\n                {\n                    _9303 = fa_world_pos.y - (fa_mesh_fs_params[9].y * _9261);\n                }\n                else\n                {\n                    _9303 = fa_mesh_fs_params[0].y;\n                }\n                float _9324 = mix(_9303, fa_world_pos.y, clamp(fa_mesh_fs_params[8].x / _9266, 0.0, 1.0));\n                float _9328 = fa_world_pos.y - _9324;\n                float _9333 = _9324 - fa_mesh_fs_params[8].z;\n                float _9338 = fa_world_pos.y - fa_mesh_fs_params[8].z;\n                bool _9341 = _9333 <= 0.0;\n                bool _9342 = !_9341;\n                bool _9348;\n                if (_9342)\n                {\n                    _9348 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _9348 = _9341;\n                }\n                float _9349;\n                if (_9348)\n                {\n                    _9349 = fa_mesh_fs_params[8].y;\n                }\n                else\n                {\n                    _9349 = fa_mesh_fs_params[8].y * exp(-min(fa_mesh_fs_params[8].w * _9333, 80.0));\n                }\n                bool _9376;\n                if (_9342)\n                {\n                    _9376 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _9376 = _9341;\n                }\n                float _9377;\n                if (_9376)\n                {\n                    _9377 = fa_mesh_fs_params[8].y * _9333;\n                }\n                else\n                {\n                    _9377 = (fa_mesh_fs_params[8].y * (1.0 - exp(-min(fa_mesh_fs_params[8].w * _9333, 80.0)))) / fa_mesh_fs_params[8].w;\n                }\n                bool _9402 = _9338 <= 0.0;\n                bool _9409;\n                if (!_9402)\n                {\n                    _9409 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _9409 = _9402;\n                }\n                float _9410;\n                if (_9409)\n                {\n                    _9410 = fa_mesh_fs_params[8].y * _9338;\n                }\n                else\n                {\n                    _9410 = (fa_mesh_fs_params[8].y * (1.0 - exp(-min(fa_mesh_fs_params[8].w * _9338, 80.0)))) / fa_mesh_fs_params[8].w;\n                }\n                float _9437;\n                if (abs(_9328) < 0.001000000047497451305389404296875)\n                {\n                    _9437 = _9349;\n                }\n                else\n                {\n                    _9437 = (_9410 - _9377) / _9328;\n                }\n                tau += (_9278 * max(_9437, 0.0));\n            }\n            result = mix(result, fa_mesh_fs_params[7].xyz, vec3(clamp(1.0 - exp(-clamp(tau, 0.0, 80.0)), 0.0, 1.0)));\n        }\n    }\n    if (fa_tr_blend > 0.0)\n    {\n        float _9473 = 1.0 - fa_tr_blend;\n        result /= vec3(_9473);\n        _9526 *= _9473;\n    }\n    fa_frag_color = vec4(result, _9526);\n}\n\n",
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
            "inst_name": "_612",
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
            "inst_name": "_2355",
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
            "inst_name": "_8816",
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
      "fs": "#version 430\n\nstruct SurfaceInput\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 vertex_color;\n    vec3 view_dir;\n    bool front_facing;\n};\n\nstruct LightSample\n{\n    vec3 direction;\n    vec3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct Surface\n{\n    vec3 albedo;\n    float alpha;\n    vec3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    vec3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    vec3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    vec3 specular_color;\n    float transmission;\n    float thickness;\n    vec3 attenuation_color;\n    float attenuation_distance;\n};\n\nstruct FaLayers\n{\n    bool on;\n    float f90;\n    float keep;\n    float base_scale;\n    float coat;\n    float coat_rough;\n    float coat_alpha;\n    float coat_a2;\n    vec3 nc;\n    float coat_ndv;\n    bool sheen_on;\n    vec3 sheen;\n    float sheen_rough;\n    float sheen_alpha;\n    float sheen_scale;\n    float sheen_e;\n    float aniso;\n    vec3 t;\n    vec3 b;\n    float at;\n    float ab;\n};\n\nconst float _4850[63] = float[](1.0, 1.0, 1.0, 0.4790000021457672119140625, 0.11699999868869781494140625, 0.01200000010430812835693359375, 0.0, 0.0, 0.0, 1.0, 1.0, 1.0, 0.578000009059906005859375, 0.19300000369548797607421875, 0.0350000001490116119384765625, 0.0030000000260770320892333984375, 0.0, 0.0, 1.0, 1.0, 1.0, 0.6740000247955322265625, 0.3459999859333038330078125, 0.1319999992847442626953125, 0.032999999821186065673828125, 0.0040000001899898052215576171875, 0.0, 0.971000015735626220703125, 0.954999983310699462890625, 0.828999996185302734375, 0.63999998569488525390625, 0.42599999904632568359375, 0.24500000476837158203125, 0.115000002086162567138671875, 0.037000000476837158203125, 0.0030000000260770320892333984375, 0.7469999790191650390625, 0.737999975681304931640625, 0.670000016689300537109375, 0.563000023365020751953125, 0.4309999942779541015625, 0.3039999902248382568359375, 0.1940000057220458984375, 0.1019999980926513671875, 0.0309999994933605194091796875, 0.614000022411346435546875, 0.609000027179718017578125, 0.566999971866607666015625, 0.499000012874603271484375, 0.412000000476837158203125, 0.32400000095367431640625, 0.240999996662139892578125, 0.162000000476837158203125, 0.087999999523162841796875, 0.538999974727630615234375, 0.535000026226043701171875, 0.505999982357025146484375, 0.4569999873638153076171875, 0.393999993801116943359375, 0.328999996185302734375, 0.2660000026226043701171875, 0.203999996185302734375, 0.14200000464916229248046875);\n\nuniform vec4 fa_mesh_fs_params[54];\nuniform vec4 fa_shadows[30];\nuniform vec4 fa_material[1];\nlayout(binding = 0) uniform sampler2D fa_light_tex_fa_shadow_smp;\nlayout(binding = 1) uniform sampler2D fa_tex_fa_smp;\nlayout(binding = 2) uniform sampler2D fa_normal_tex_fa_smp;\nlayout(binding = 3) uniform sampler2D fa_mr_tex_fa_smp;\nlayout(binding = 4) uniform sampler2D fa_occlusion_tex_fa_smp;\nlayout(binding = 5) uniform sampler2D fa_emissive_tex_fa_smp;\nlayout(binding = 6) uniform sampler2D mask_mask_smp;\nlayout(binding = 7) uniform sampler2D fa_decal_tex_fa_env_smp;\nlayout(binding = 8) uniform sampler2D fa_lightmap_fa_env_smp;\nlayout(binding = 9) uniform sampler2D fa_probe_atlas_fa_env_smp;\nlayout(binding = 10) uniform sampler2D fa_light_atlas_fa_env_smp;\nlayout(binding = 11) uniform sampler2D fa_screen_tex_fa_shadow_smp;\nlayout(binding = 12) uniform sampler2D fa_shadow_tex_fa_shadow_smp;\n\nlayout(location = 0) in vec3 fa_world_pos;\nlayout(location = 5) in vec3 fa_lm;\nlayout(location = 1) in vec3 fa_world_normal;\nlayout(location = 2) in vec4 fa_world_tangent;\nlayout(location = 3) in vec2 fa_uv;\nlayout(location = 4) in vec4 fa_vertex_color;\nlayout(location = 0) out vec4 fa_frag_color;\nfloat fa_rt_slope;\nvec3 fa_light_tint;\nbool fa_light_is_area;\nint fa_cl_ndir;\nint fa_cl_slot;\nint fa_cl_local;\n\nvoid fa_inst_load()\n{\n}\n\nvec4 fa_light_texel(int t)\n{\n    return texelFetch(fa_light_tex_fa_shadow_smp, ivec2(t & 1023, t >> 10), 0);\n}\n\nvec4 fa_cluster_texel(vec3 world_pos)\n{\n    bool _1637 = fa_mesh_fs_params[19].x < 0.0;\n    bool _1644;\n    if (!_1637)\n    {\n        _1644 = fa_mesh_fs_params[19].w < 1.0;\n    }\n    else\n    {\n        _1644 = _1637;\n    }\n    bool _1652;\n    if (!_1644)\n    {\n        _1652 = fa_mesh_fs_params[18].x < 1.0;\n    }\n    else\n    {\n        _1652 = _1644;\n    }\n    bool _1659;\n    if (!_1652)\n    {\n        _1659 = fa_mesh_fs_params[18].y < 1.0;\n    }\n    else\n    {\n        _1659 = _1652;\n    }\n    bool _1666;\n    if (!_1659)\n    {\n        _1666 = fa_mesh_fs_params[19].y < 1.0;\n    }\n    else\n    {\n        _1666 = _1659;\n    }\n    if (_1666)\n    {\n        return vec4(0.0);\n    }\n    vec4 _1676 = vec4(world_pos, 1.0);\n    float _1682 = dot(fa_mesh_fs_params[16], _1676);\n    if (!(_1682 > 9.9999999747524270787835121154785e-07))\n    {\n        return vec4(0.0);\n    }\n    vec2 _1704 = vec2(dot(fa_mesh_fs_params[14], _1676), dot(fa_mesh_fs_params[15], _1676)) / vec2(_1682);\n    int _1708 = int(fa_mesh_fs_params[18].x);\n    int _1712 = int(fa_mesh_fs_params[18].y);\n    int param = (int(fa_mesh_fs_params[19].x) + (((clamp(int(floor(log2(max(dot(fa_mesh_fs_params[17].xyz, world_pos) + fa_mesh_fs_params[17].w, fa_mesh_fs_params[18].w) / fa_mesh_fs_params[18].w) * fa_mesh_fs_params[18].z)), 0, int(fa_mesh_fs_params[19].y) - 1) * _1712) + clamp(int(floor(((_1704.y * 0.5) + 0.5) * fa_mesh_fs_params[18].y)), 0, _1712 - 1)) * _1708)) + clamp(int(floor(((_1704.x * 0.5) + 0.5) * fa_mesh_fs_params[18].x)), 0, _1708 - 1);\n    return fa_light_texel(param);\n}\n\nivec2 fa_cluster_lookup(vec3 world_pos)\n{\n    vec3 param = world_pos;\n    vec4 _1788 = fa_cluster_texel(param);\n    return ivec2(int(_1788.x), int(_1788.y));\n}\n\nvoid fa_cluster_begin(vec3 world_pos)\n{\n    float _6484 = dot(fa_mesh_fs_params[29].xyz, world_pos) + fa_mesh_fs_params[29].w;\n    float _6487 = fwidth(_6484);\n    bool _6490 = fa_mesh_fs_params[25].y > 0.5;\n    bool _6497;\n    if (!_6490)\n    {\n        _6497 = fa_mesh_fs_params[25].w > 0.5;\n    }\n    else\n    {\n        _6497 = _6490;\n    }\n    if (_6497)\n    {\n        fa_rt_slope = min(1.5 * _6487, 0.100000001490116119384765625 * _6484);\n    }\n    fa_cl_ndir = int(fa_mesh_fs_params[19].z);\n    vec3 param = world_pos;\n    ivec2 _6513 = fa_cluster_lookup(param);\n    fa_cl_slot = _6513.x;\n    fa_cl_local = _6513.y;\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nvec3 fa_linear_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_tex_fix(inout vec3 c, float mode)\n{\n    if (mode > 1.5)\n    {\n        vec3 param = c;\n        vec3 _7683 = fa_linear_to_srgb(param);\n        c = _7683;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            vec3 param_1 = c;\n            vec3 _7691 = fa_srgb_to_linear(param_1);\n            c = _7691;\n        }\n    }\n    return c;\n}\n\nvec3 fa_tangent_normal(SurfaceInput i, vec3 m)\n{\n    vec3 _544;\n    if (i.front_facing)\n    {\n        _544 = i.world_normal;\n    }\n    else\n    {\n        _544 = -i.world_normal;\n    }\n    vec3 _568 = normalize(i.world_tangent.xyz - (_544 * dot(_544, i.world_tangent.xyz)));\n    vec3 _595 = normalize(((_568 * m.x) + ((cross(_544, _568) * i.world_tangent.w) * m.y)) + (_544 * m.z));\n    vec3 _598;\n    if (i.front_facing)\n    {\n        _598 = _595;\n    }\n    else\n    {\n        _598 = -_595;\n    }\n    return _598;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    vec4 base_t = texture(fa_tex_fa_smp, i.uv, fa_mesh_fs_params[12].w);\n    float param = fa_mesh_fs_params[6].w;\n    float param_1 = 1.0;\n    vec3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    vec3 _7723 = fa_tex_fix(param_2, param_3);\n    vec4 _10105 = base_t;\n    _10105.x = _7723.x;\n    _10105.y = _7723.y;\n    _10105.z = _7723.z;\n    base_t = _10105;\n    vec4 _7737 = (_10105 * fa_mesh_fs_params[2]) * i.vertex_color;\n    vec3 _9855 = i.world_normal;\n    if (fa_mesh_fs_params[6].z > 0.5)\n    {\n        float param_4 = fa_mesh_fs_params[6].w;\n        float param_5 = 16.0;\n        vec3 param_6 = texture(fa_normal_tex_fa_smp, i.uv, fa_mesh_fs_params[12].w).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        vec3 _7771 = fa_tex_fix(param_6, param_7);\n        vec3 _7774 = (_7771 * 2.0) - vec3(1.0);\n        vec2 _7779 = _7774.xy * fa_mesh_fs_params[6].x;\n        vec3 _10113 = _7774;\n        _10113.x = _7779.x;\n        _10113.y = _7779.y;\n        SurfaceInput param_8 = i;\n        vec3 param_9 = _10113;\n        _9855 = fa_tangent_normal(param_8, param_9);\n    }\n    vec4 mrt = texture(fa_mr_tex_fa_smp, i.uv, fa_mesh_fs_params[12].w);\n    float param_10 = fa_mesh_fs_params[6].w;\n    float param_11 = 64.0;\n    vec3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    vec3 _7809 = fa_tex_fix(param_12, param_13);\n    vec4 _10116 = mrt;\n    _10116.x = _7809.x;\n    _10116.y = _7809.y;\n    _10116.z = _7809.z;\n    mrt = _10116;\n    vec4 _7839 = texture(fa_occlusion_tex_fa_smp, i.uv, fa_mesh_fs_params[12].w);\n    float param_14 = fa_mesh_fs_params[6].w;\n    float param_15 = 256.0;\n    vec3 param_16 = _7839.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    vec3 _7850 = fa_tex_fix(param_16, param_17);\n    float param_18 = fa_mesh_fs_params[6].w;\n    float param_19 = 4.0;\n    vec3 param_20 = texture(fa_emissive_tex_fa_smp, i.uv, fa_mesh_fs_params[12].w).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    vec3 _7882 = fa_tex_fix(param_20, param_21);\n    float _9860 = fa_mesh_fs_params[20].x;\n    float _9861 = fa_mesh_fs_params[20].y;\n    float _9864 = fa_mesh_fs_params[20].z;\n    float _9863 = fa_mesh_fs_params[21].w;\n    float _9866 = fa_mesh_fs_params[22].x;\n    if (fa_mesh_fs_params[22].z > 0.5)\n    {\n        if (mod(fa_mesh_fs_params[22].z, 2.0) > 0.5)\n        {\n            _9860 *= _7850.y;\n            _9861 *= _7850.z;\n            _9863 *= _7839.w;\n        }\n        if (fa_mesh_fs_params[22].z > 1.5)\n        {\n            _9864 *= mrt.x;\n            _9866 *= mrt.w;\n        }\n    }\n    return Surface(_7737.xyz, _7737.w, _9855, clamp(fa_mesh_fs_params[5].x * _7809.z, 0.0, 1.0), clamp(fa_mesh_fs_params[5].y * _7809.y, 0.0500000007450580596923828125, 1.0), 1.0 + (fa_mesh_fs_params[6].y * (_7850.x - 1.0)), fa_mesh_fs_params[3].xyz + (fa_mesh_fs_params[4].xyz * _7882), _9860, _9861, fa_mesh_fs_params[21].xyz, _9863, _9864, fa_mesh_fs_params[20].w, _9866, fa_mesh_fs_params[22].y, fa_mesh_fs_params[23].xyz, fa_mesh_fs_params[30].x, fa_mesh_fs_params[30].y, fa_mesh_fs_params[31].xyz, fa_mesh_fs_params[30].z);\n}\n\nvoid surface(SurfaceInput i, inout Surface s)\n{\n    s.alpha = texture(mask_mask_smp, i.uv * 2.0).x;\n}\n\nvec4 fa_decal_tile(vec4 rect, vec2 uv, vec2 atlas, vec2 ddx, vec2 ddy)\n{\n    vec2 _1868 = rect.zw - rect.xy;\n    vec2 _1872 = _1868 * atlas;\n    vec2 _1876 = ddx * _1872;\n    vec2 _1880 = ddy * _1872;\n    return textureLod(fa_decal_tex_fa_env_smp, rect.xy + (clamp(uv, vec2(0.0), vec2(1.0)) * _1868), clamp(0.5 * log2(max(max(dot(_1876, _1876), dot(_1880, _1880)), 9.9999999392252902907785028219223e-09)), 0.0, 3.0));\n}\n\nvec3 fa_dc_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_dc_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvoid fa_apply_decals(vec3 world_pos, vec3 geo_normal, inout vec3 albedo, inout vec3 normal)\n{\n    bool _1913 = fa_mesh_fs_params[10].y < 0.5;\n    bool _1920;\n    if (!_1913)\n    {\n        _1920 = fa_mesh_fs_params[10].w < 0.5;\n    }\n    else\n    {\n        _1920 = _1913;\n    }\n    if (_1920)\n    {\n        return;\n    }\n    vec3 _1926 = dFdx(world_pos);\n    vec3 _1929 = dFdy(world_pos);\n    vec3 param = world_pos;\n    vec4 _1933 = fa_cluster_texel(param);\n    int _1937 = int(_1933.w);\n    if (_1937 < 1)\n    {\n        return;\n    }\n    int _1947 = int(fa_mesh_fs_params[10].y + 0.5);\n    int param_1 = _1947;\n    vec4 _1951 = fa_light_texel(param_1);\n    vec2 _1954 = _1951.yz;\n    int _1958 = int(_1951.w);\n    int param_2 = _1947 + 1;\n    vec4 _1963 = fa_light_texel(param_2);\n    float _1964 = _1963.x;\n    int _1970 = int(fa_mesh_fs_params[10].w + 0.5) - 1;\n    int _1974 = int(_1933.z);\n    vec3 _2239;\n    for (int k = 0; k < _1937; k++)\n    {\n        int _1987 = _1974 + k;\n        int param_3 = _1958 + (_1987 >> 2);\n        int _2004 = (_1947 + 2) + (int(fa_light_texel(param_3)[_1987 & 3]) * 7);\n        int param_4 = _2004 + 6;\n        vec4 _2009 = fa_light_texel(param_4);\n        if (((int(_2009.w + 0.5) >> _1970) & 1) == 0)\n        {\n            continue;\n        }\n        int param_5 = _2004;\n        vec4 _2024 = fa_light_texel(param_5);\n        int param_6 = _2004 + 1;\n        vec4 _2029 = fa_light_texel(param_6);\n        int param_7 = _2004 + 2;\n        vec4 _2034 = fa_light_texel(param_7);\n        vec3 _2037 = _2024.xyz;\n        float _2042 = dot(_2037, world_pos) + _2024.w;\n        vec3 _2044 = _2029.xyz;\n        float _2049 = dot(_2044, world_pos) + _2029.w;\n        vec3 _2051 = _2034.xyz;\n        float _2056 = dot(_2051, world_pos) + _2034.w;\n        bool _2061 = abs(_2042) > 0.5;\n        bool _2069;\n        if (!_2061)\n        {\n            _2069 = abs(_2049) > 0.5;\n        }\n        else\n        {\n            _2069 = _2061;\n        }\n        bool _2077;\n        if (!_2069)\n        {\n            _2077 = abs(_2056) > 0.5;\n        }\n        else\n        {\n            _2077 = _2069;\n        }\n        if (_2077)\n        {\n            continue;\n        }\n        float _2092 = clamp(dot(geo_normal, normalize(_2051)) * _2009.z, 0.0, 1.0);\n        if (_2092 <= 0.0)\n        {\n            continue;\n        }\n        float _2112 = (clamp((0.5 - abs(_2056)) * 10.0, 0.0, 1.0) * _2092) * _2009.x;\n        vec2 _2120 = vec2(_2042 + 0.5, 0.5 - _2049);\n        vec2 _2130 = vec2(dot(_2037, _1926), dot(_2044, _1926));\n        vec2 _2140 = vec2(dot(_2037, _1929), dot(_2044, _1929));\n        int param_8 = _2004 + 5;\n        vec4 _2145 = fa_light_texel(param_8);\n        int param_9 = _2004 + 3;\n        vec4 _2150 = fa_light_texel(param_9);\n        int param_10 = _2004 + 4;\n        vec4 _2155 = fa_light_texel(param_10);\n        float tex_a = 1.0;\n        vec3 col = _2145.xyz;\n        bool _2165 = _2150.z > _2150.x;\n        if (_2165)\n        {\n            vec4 param_11 = _2150;\n            vec2 param_12 = _2120;\n            vec2 param_13 = _1954;\n            vec2 param_14 = _2130;\n            vec2 param_15 = _2140;\n            vec4 tx = fa_decal_tile(param_11, param_12, param_13, param_14, param_15);\n            if ((_1964 > 0.5) && (_1964 < 1.5))\n            {\n                vec3 param_16 = tx.xyz;\n                vec3 _2191 = fa_dc_to_linear(param_16);\n                vec4 _9943 = tx;\n                _9943.x = _2191.x;\n                _9943.y = _2191.y;\n                _9943.z = _2191.z;\n                tx = _9943;\n            }\n            col *= tx.xyz;\n            tex_a = tx.w;\n        }\n        albedo = mix(albedo, col, vec3(clamp((_2112 * tex_a) * _2145.w, 0.0, 1.0)));\n        if (_2155.z > _2155.x)\n        {\n            vec4 param_17 = _2155;\n            vec2 param_18 = _2120;\n            vec2 param_19 = _1954;\n            vec2 param_20 = _2130;\n            vec2 param_21 = _2140;\n            vec4 _2235 = fa_decal_tile(param_17, param_18, param_19, param_20, param_21);\n            if (_1964 > 1.5)\n            {\n                vec3 param_22 = _2235.xyz;\n                vec3 _2245 = fa_dc_to_srgb(param_22);\n                _2239 = _2245;\n            }\n            else\n            {\n                _2239 = _2235.xyz;\n            }\n            vec3 _2254 = (_2239 * 2.0) - vec3(1.0);\n            vec2 _2259 = _2254.xy * _2009.y;\n            vec3 _2281 = (normalize(_2037) * _2259.x) + (normalize(_2044) * _2259.y);\n            vec3 _2284 = normalize(normal);\n            normal = normalize(mix(_2284, normalize((_2284 * max(_2254.z, 0.0500000007450580596923828125)) + (_2281 - (_2284 * dot(_2284, _2281)))), vec3(clamp(_2112 * (_2165 ? tex_a : 1.0), 0.0, 1.0))));\n        }\n    }\n}\n\nvoid fa_lod_dither()\n{\n    if (fa_mesh_fs_params[52].w != 0.0)\n    {\n        float _633 = fract(52.98291778564453125 * fract(dot(gl_FragCoord.xy, vec2(0.067110560834407806396484375, 0.005837149918079376220703125))));\n        bool _636;\n        if (fa_mesh_fs_params[52].w > 0.0)\n        {\n            _636 = _633 >= fa_mesh_fs_params[52].w;\n        }\n        else\n        {\n            _636 = _633 < (-fa_mesh_fs_params[52].w);\n        }\n        if (_636)\n        {\n            discard;\n        }\n    }\n}\n\nfloat fa_sheen_albedo(float ndv, float rough)\n{\n    float _4775 = min(sqrt(max(rough - 0.100000001490116119384765625, 0.0) * 1.111111164093017578125) * 6.0, 5.999000072479248046875);\n    float _4783 = min(sqrt(clamp(ndv, 0.0, 1.0)) * 8.0, 7.999000072479248046875);\n    int _4786 = int(_4775);\n    int _4789 = int(_4783);\n    float _4799 = _4783 - float(_4789);\n    int _4854 = (_4786 * 9) + _4789;\n    int _4874 = ((_4786 + 1) * 9) + _4789;\n    return mix(mix(_4850[_4854], _4850[_4854 + 1], _4799), mix(_4850[_4874], _4850[_4874 + 1], _4799), _4775 - float(_4786));\n}\n\nFaLayers fa_layers_setup(SurfaceInput i, Surface s, vec3 n, vec3 v, float metallic, float roughness, inout vec3 f0)\n{\n    bool _9778 = false;\n    float _9779 = 1.0;\n    float _9780 = 1.0;\n    float _9781 = 1.0;\n    float _9782 = 0.0;\n    float _9783 = 0.0;\n    float _9784 = 0.0;\n    float _9785 = 0.0;\n    float _9787 = 1.0;\n    bool _9788 = false;\n    vec3 _9789 = vec3(0.0);\n    float _9790 = 1.0;\n    float _9791 = 1.0;\n    float _9792 = 1.0;\n    float _9793 = 0.0;\n    float _9794 = 0.0;\n    vec3 _9795 = vec3(1.0, 0.0, 0.0);\n    vec3 _9796 = vec3(0.0, 0.0, 1.0);\n    float _9797 = 1.0;\n    float _9798 = 1.0;\n    float _4925 = clamp(s.specular, 0.0, 1.0);\n    float _4929 = clamp(s.ior, 1.0, 3.0);\n    bool _4934 = (_4925 != 1.0) || (_4929 != 1.5);\n    bool _4943;\n    if (!_4934)\n    {\n        _4943 = any(notEqual(s.specular_color, vec3(1.0)));\n    }\n    else\n    {\n        _4943 = _4934;\n    }\n    if (_4943)\n    {\n        float _4951 = (_4929 - 1.0) / (_4929 + 1.0);\n        f0 = mix(min(vec3(_4951 * _4951) * max(s.specular_color, vec3(0.0)), vec3(1.0)) * _4925, s.albedo, vec3(metallic));\n        _9779 = mix(_4925, 1.0, metallic);\n        _9778 = true;\n    }\n    float _4978 = clamp(s.clearcoat, 0.0, 1.0);\n    if (_4978 > 0.0)\n    {\n        float _4986 = clamp(s.clearcoat_roughness, 0.0500000007450580596923828125, 1.0);\n        _9782 = _4978;\n        _9783 = _4986;\n        float _4993 = _4986 * _4986;\n        _9784 = _4993;\n        _9785 = _4993 * _4993;\n        float _5005 = max(dot(i.world_normal, v), 9.9999997473787516355514526367188e-05);\n        _9787 = _5005;\n        _9780 = 1.0 - (_4978 * (0.039999999105930328369140625 + (0.959999978542327880859375 * pow(clamp(1.0 - _5005, 0.0, 1.0), 5.0))));\n        _9778 = true;\n    }\n    vec3 _5024 = max(s.sheen_color, vec3(0.0));\n    float _5033 = max(_5024.x, max(_5024.y, _5024.z));\n    if (_5033 > 0.0)\n    {\n        float _5041 = clamp(s.sheen_roughness, 0.100000001490116119384765625, 1.0);\n        _9788 = true;\n        _9789 = _5024;\n        _9790 = _5041;\n        _9791 = _5041 * _5041;\n        float param = max(dot(n, v), 9.9999997473787516355514526367188e-05);\n        float param_1 = _5041;\n        float _5058 = fa_sheen_albedo(param, param_1);\n        _9793 = _5058;\n        _9792 = 1.0 - min(_5033 * _5058, 1.0);\n        _9778 = true;\n    }\n    _9781 = _9780 * _9792;\n    float _5077 = clamp(s.anisotropy, -1.0, 1.0);\n    if (_5077 != 0.0)\n    {\n        vec3 _5092 = i.world_tangent.xyz - (n * dot(n, i.world_tangent.xyz));\n        vec3 t = _5092;\n        if (dot(_5092, _5092) < 9.9999999392252902907785028219223e-09)\n        {\n            bvec3 _5104 = bvec3(abs(n.y) < 0.9900000095367431640625);\n            t = cross(vec3(_5104.x ? vec3(0.0, 1.0, 0.0).x : vec3(1.0, 0.0, 0.0).x, _5104.y ? vec3(0.0, 1.0, 0.0).y : vec3(1.0, 0.0, 0.0).y, _5104.z ? vec3(0.0, 1.0, 0.0).z : vec3(1.0, 0.0, 0.0).z), n);\n        }\n        vec3 _5108 = t;\n        vec3 _5109 = normalize(_5108);\n        t = _5109;\n        vec3 _5134 = normalize((_5109 * cos(s.anisotropy_rotation)) + ((cross(n, _5109) * ((i.world_tangent.w < 0.0) ? (-1.0) : 1.0)) * sin(s.anisotropy_rotation)));\n        _9795 = _5134;\n        _9796 = cross(n, _5134);\n        float _5144 = roughness * roughness;\n        float _5150 = mix(_5144, 1.0, _5077 * _5077);\n        bool _5152 = _5077 > 0.0;\n        _9797 = _5152 ? _5150 : _5144;\n        _9798 = _5152 ? _5144 : _5150;\n        _9794 = _5077;\n        _9778 = true;\n    }\n    return FaLayers(_9778, _9779, _9780, _9781, _9782, _9783, _9784, _9785, i.world_normal, _9787, _9788, _9789, _9790, _9791, _9792, _9793, _9794, _9795, _9796, _9797, _9798);\n}\n\nvec2 fa_atlas_size()\n{\n    return vec2(textureSize(fa_probe_atlas_fa_env_smp, 0));\n}\n\nvec3 fa_probe_sh_coef(vec2 origin, float res, int k)\n{\n    vec3 v = textureLod(fa_probe_atlas_fa_env_smp, (origin + vec2(float(k) + 0.5, res + 2.5)) / fa_atlas_size(), 0.0).xyz;\n    if (fa_mesh_fs_params[41].y > 0.5)\n    {\n        v = ((v * 255.0) - vec3(128.0)) * 0.03149606287479400634765625;\n    }\n    return v;\n}\n\nvec3 fa_sh_eval(vec3 c[9], vec3 n)\n{\n    vec3 _3946 = max((((c[0] * 0.2820948064327239990234375) + (((c[1] * (0.3257350027561187744140625 * n.y)) + (c[2] * (0.3257350027561187744140625 * n.z))) + (c[3] * (0.3257350027561187744140625 * n.x)))) + (((c[4] * ((0.2731371223926544189453125 * n.x) * n.y)) + (c[5] * ((0.2731371223926544189453125 * n.y) * n.z))) + (c[6] * (0.078847892582416534423828125 * (((3.0 * n.z) * n.z) - 1.0))))) + ((c[7] * ((0.2731371223926544189453125 * n.x) * n.z)) + (c[8] * (0.13656856119632720947265625 * ((n.x * n.x) - (n.y * n.y))))), vec3(0.0));\n    return _3946;\n}\n\nvec3 fa_ambient_light(vec3 n)\n{\n    float _4557 = (1.0 - fa_mesh_fs_params[42].w) - fa_mesh_fs_params[47].w;\n    vec3 amb = vec3(0.0);\n    bool _4562 = fa_mesh_fs_params[11].w > 0.5;\n    vec3 c[9];\n    for (int k = 0; k < 9; k++)\n    {\n        c[k] = vec3(0.0);\n    }\n    if (_4557 > 0.0005000000237487256526947021484375)\n    {\n        if (_4562)\n        {\n            for (int k_1 = 0; k_1 < 9; k_1++)\n            {\n                vec2 param = fa_mesh_fs_params[41].zw;\n                float param_1 = 128.0;\n                int param_2 = k_1;\n                c[k_1] = fa_probe_sh_coef(param, param_1, param_2) * _4557;\n            }\n        }\n        else\n        {\n            amb = fa_mesh_fs_params[1].xyz * _4557;\n        }\n    }\n    bool _4612 = fa_mesh_fs_params[42].w > 0.0;\n    if (_4612)\n    {\n        for (int k_2 = 0; k_2 < 9; k_2++)\n        {\n            vec2 param_3 = fa_mesh_fs_params[42].xy;\n            float param_4 = fa_mesh_fs_params[42].z;\n            int param_5 = k_2;\n            c[k_2] += (fa_probe_sh_coef(param_3, param_4, param_5) * fa_mesh_fs_params[42].w);\n        }\n    }\n    bool _4643 = fa_mesh_fs_params[47].w > 0.0;\n    if (_4643)\n    {\n        for (int k_3 = 0; k_3 < 9; k_3++)\n        {\n            vec2 param_6 = fa_mesh_fs_params[47].xy;\n            float param_7 = fa_mesh_fs_params[47].z;\n            int param_8 = k_3;\n            c[k_3] += (fa_probe_sh_coef(param_6, param_7, param_8) * fa_mesh_fs_params[47].w);\n        }\n    }\n    if ((_4562 || _4612) || _4643)\n    {\n        vec3 param_9[9] = c;\n        vec3 param_10 = n;\n        amb += fa_sh_eval(param_9, param_10);\n    }\n    return amb;\n}\n\nvec4 fa_gi_fetch(vec2 texel)\n{\n    return textureLod(fa_probe_atlas_fa_env_smp, texel / fa_atlas_size(), 0.0);\n}\n\nvec2 fa_oct_encode(vec3 d)\n{\n    vec3 _3966 = d / vec3(max((abs(d.x) + abs(d.y)) + abs(d.z), 9.9999999600419720025001879548654e-13));\n    float _3969 = _3966.x;\n    float _3971 = _3966.z;\n    vec2 e = vec2(_3969, _3971);\n    if (_3966.y < 0.0)\n    {\n        e = vec2((1.0 - abs(_3971)) * ((_3969 < 0.0) ? (-1.0) : 1.0), (1.0 - abs(_3969)) * ((_3971 < 0.0) ? (-1.0) : 1.0));\n    }\n    return e;\n}\n\nvec3 fa_gi_grid(int rec, vec3 n, vec3 v, out float cover)\n{\n    cover = 0.0;\n    int param = rec;\n    vec4 _7992 = fa_light_texel(param);\n    int param_1 = rec + 1;\n    vec4 _7997 = fa_light_texel(param_1);\n    int param_2 = rec + 2;\n    vec4 _8002 = fa_light_texel(param_2);\n    int param_3 = rec + 3;\n    vec4 _8007 = fa_light_texel(param_3);\n    bool _8010 = _8007.z < 0.5;\n    bool _8018;\n    if (!_8010)\n    {\n        _8018 = fa_atlas_size().y < 1155.0;\n    }\n    else\n    {\n        _8018 = _8010;\n    }\n    if (_8018)\n    {\n        return vec3(0.0);\n    }\n    float _8025 = max(_7992.w, 9.9999997473787516355514526367188e-05);\n    vec3 _8028 = _7997.xyz;\n    vec3 _8032 = _7992.xyz;\n    vec3 _8036 = (fa_world_pos - _8032) / vec3(_8025);\n    vec3 _8045 = min(_8036 + vec3(0.5), (_8028 - vec3(0.5)) - _8036);\n    float _8054 = min(_8045.x, min(_8045.y, _8045.z));\n    if (!(_8054 > 0.0))\n    {\n        return vec3(0.0);\n    }\n    vec3 _8069 = _8028 - vec3(1.0);\n    vec3 _8070 = clamp(_8036, vec3(0.0), _8069);\n    vec3 _8078 = min(floor(_8070), max(_8028 - vec3(2.0), vec3(0.0)));\n    vec3 _8082 = _8070 - _8078;\n    vec3 _8093 = fa_world_pos + (((n * 0.800000011920928955078125) + (v * 0.20000000298023223876953125)) * (0.20000000298023223876953125 * _8025));\n    int _8098 = int(_8002.y + 0.5);\n    float _8103 = 0.3257350027561187744140625 * n.y;\n    float _8107 = 0.3257350027561187744140625 * n.z;\n    float _8111 = 0.3257350027561187744140625 * n.x;\n    float _8118 = (0.2731371223926544189453125 * n.x) * n.y;\n    float _8125 = (0.2731371223926544189453125 * n.y) * n.z;\n    float _8134 = 0.078847892582416534423828125 * (((3.0 * n.z) * n.z) - 1.0);\n    float _8141 = (0.2731371223926544189453125 * n.x) * n.z;\n    float _8154 = 0.13656856119632720947265625 * ((n.x * n.x) - (n.y * n.y));\n    vec3 acc = vec3(0.0);\n    float wsum = 0.0;\n    int _8161 = 8 + int(_8007.w);\n    float _8188;\n    float _8201;\n    float _8215;\n    for (int k = 0; k < _8161; k++)\n    {\n        float _8174 = float(k & 1);\n        float _8178 = float((k >> 1) & 1);\n        float _8182 = float((k >> 2) & 1);\n        if (_8174 > 0.5)\n        {\n            _8188 = _8082.x;\n        }\n        else\n        {\n            _8188 = 1.0 - _8082.x;\n        }\n        if (_8178 > 0.5)\n        {\n            _8201 = _8082.y;\n        }\n        else\n        {\n            _8201 = 1.0 - _8082.y;\n        }\n        if (_8182 > 0.5)\n        {\n            _8215 = _8082.z;\n        }\n        else\n        {\n            _8215 = 1.0 - _8082.z;\n        }\n        float _8225 = (_8188 * _8201) * _8215;\n        if (!(_8225 > 0.0))\n        {\n            continue;\n        }\n        vec3 _8238 = min(_8078 + vec3(_8174, _8178, _8182), _8069);\n        int _8258 = int(((_8002.x + _8238.x) + (_7997.x * (_8238.y + (_7997.y * _8238.z)))) + 0.5);\n        vec2 _8273 = vec2(float(_8258 % _8098) * 10.0, 1024.0 + (float(_8258 / _8098) * 11.0));\n        vec2 param_4 = _8273 + vec2(9.5, 10.5);\n        vec4 _8281 = fa_gi_fetch(param_4);\n        bool _8284 = _8281.y < 0.5;\n        bool _8293;\n        if (!_8284)\n        {\n            _8293 = _8281.x > _8007.y;\n        }\n        else\n        {\n            _8293 = _8284;\n        }\n        if (_8293)\n        {\n            continue;\n        }\n        vec3 _8305 = _8093 - (_8032 + (_8238 * _8025));\n        float _8308 = length(_8305);\n        vec3 _8314 = _8305 / vec3(max(_8308, 9.9999997473787516355514526367188e-05));\n        float _8324 = max(9.9999997473787516355514526367188e-05, (dot(-_8314, n) + 1.0) * 0.5);\n        float w = _8225 * (_8324 * _8324);\n        vec3 param_5 = _8314;\n        vec2 param_6 = (_8273 + vec2(1.0)) + (((fa_oct_encode(param_5) * 0.5) + vec2(0.5)) * 8.0);\n        vec4 _8343 = fa_gi_fetch(param_6);\n        float _8350 = _8308 / max(_8002.z, 9.9999997473787516355514526367188e-05);\n        float _8353 = _8343.x;\n        if (_8350 > _8353)\n        {\n            float _8366 = max(_8343.y - (_8353 * _8353), 0.0);\n            float _8371 = _8350 - _8353;\n            float _8380 = _8366 / max(_8366 + (_8371 * _8371), 9.9999999600419720025001879548654e-13);\n            w *= ((_8380 * _8380) * _8380);\n        }\n        if (!(w > 0.0))\n        {\n            continue;\n        }\n        vec2 param_7 = _8273 + vec2(0.5, 10.5);\n        vec2 param_8 = _8273 + vec2(1.5, 10.5);\n        vec2 param_9 = _8273 + vec2(2.5, 10.5);\n        vec2 param_10 = _8273 + vec2(3.5, 10.5);\n        vec2 param_11 = _8273 + vec2(4.5, 10.5);\n        vec2 param_12 = _8273 + vec2(5.5, 10.5);\n        vec2 param_13 = _8273 + vec2(6.5, 10.5);\n        vec2 param_14 = _8273 + vec2(7.5, 10.5);\n        vec2 param_15 = _8273 + vec2(8.5, 10.5);\n        acc += ((((((((((fa_gi_fetch(param_7).xyz * 0.2820948064327239990234375) + (fa_gi_fetch(param_8).xyz * _8103)) + (fa_gi_fetch(param_9).xyz * _8107)) + (fa_gi_fetch(param_10).xyz * _8111)) + (fa_gi_fetch(param_11).xyz * _8118)) + (fa_gi_fetch(param_12).xyz * _8125)) + (fa_gi_fetch(param_13).xyz * _8134)) + (fa_gi_fetch(param_14).xyz * _8141)) + (fa_gi_fetch(param_15).xyz * _8154)) * w);\n        wsum += w;\n    }\n    if (!(wsum > 9.9999997473787516355514526367188e-06))\n    {\n        return vec3(0.0);\n    }\n    cover = smoothstep(0.0, 1.0, clamp(_8054 * 2.0, 0.0, 1.0)) * smoothstep(0.0, 0.0199999995529651641845703125, wsum);\n    float _8504;\n    if (fa_mesh_fs_params[52].z > 0.5)\n    {\n        _8504 = _8007.x;\n    }\n    else\n    {\n        _8504 = 1.0;\n    }\n    return max(acc / vec3(wsum), vec3(0.0)) * (_8002.w * _8504);\n}\n\nvec3 fa_gi_light(vec3 n, inout float left)\n{\n    left = 1.0;\n    vec3 acc = vec3(0.0);\n    vec3 _8528 = normalize(fa_mesh_fs_params[0].xyz - fa_world_pos);\n    int _8533 = int(fa_mesh_fs_params[52].x + 0.5);\n    int _8538 = int(fa_mesh_fs_params[52].y + 0.5);\n    float param_3;\n    for (int k = 0; (k < _8538) && (k < 8); k++)\n    {\n        int param = _8533 + (4 * k);\n        vec3 param_1 = n;\n        vec3 param_2 = _8528;\n        vec3 _8563 = fa_gi_grid(param, param_1, param_2, param_3);\n        float _8568 = param_3 * left;\n        acc += (_8563 * _8568);\n        left -= _8568;\n        if (left < 0.001000000047497451305389404296875)\n        {\n            left = 0.0;\n            break;\n        }\n    }\n    return acc;\n}\n\nvec3 fa_realtime_or_ambient(vec3 n)\n{\n    vec3 gi = vec3(0.0);\n    float left = 1.0;\n    if (fa_mesh_fs_params[52].y > 0.5)\n    {\n        vec3 param = n;\n        float param_1;\n        vec3 _8597 = fa_gi_light(param, param_1);\n        left = param_1;\n        gi = _8597;\n    }\n    if (left <= 0.0)\n    {\n        return gi;\n    }\n    vec3 param_2 = n;\n    return gi + (fa_ambient_light(param_2) * left);\n}\n\nvec3 fa_indirect_diffuse(vec3 n)\n{\n    if (fa_lm.z > 0.5)\n    {\n        return textureLod(fa_lightmap_fa_env_smp, fa_lm.xy, 0.0).xyz;\n    }\n    if (fa_mesh_fs_params[53].x > 0.5)\n    {\n        vec4 _8639 = vec4(fa_world_pos, 1.0);\n        vec2 _8658 = vec2(dot(fa_mesh_fs_params[26], _8639), dot(fa_mesh_fs_params[27], _8639)) / vec2(max(dot(fa_mesh_fs_params[28], _8639), 9.9999997473787516355514526367188e-05));\n        float _8667;\n        if (fa_mesh_fs_params[24].y > 0.5)\n        {\n            _8667 = (_8658.y * 0.5) + 0.5;\n        }\n        else\n        {\n            _8667 = 0.5 - (_8658.y * 0.5);\n        }\n        return texelFetch(fa_lightmap_fa_env_smp, clamp(ivec2(vec2((_8658.x * 0.5) + 0.5, _8667) * fa_mesh_fs_params[24].zw), ivec2(0), ivec2(fa_mesh_fs_params[24].zw) - ivec2(1)), 0).xyz;\n    }\n    if (fa_mesh_fs_params[32].w > 0.0)\n    {\n        vec3 c[9];\n        for (int k = 0; k < 9; k++)\n        {\n            c[k] = fa_mesh_fs_params[k * 1 + 32].xyz;\n        }\n        vec3 param = n;\n        vec3 param_1[9] = c;\n        vec3 param_2 = n;\n        return mix(fa_ambient_light(param), fa_sh_eval(param_1, param_2), vec3(clamp(fa_mesh_fs_params[32].w, 0.0, 1.0)));\n    }\n    vec3 param_3 = n;\n    return fa_realtime_or_ambient(param_3);\n}\n\nint fa_cluster_index(int slot, int n)\n{\n    int param = (int(fa_mesh_fs_params[19].x) + int(fa_mesh_fs_params[19].w)) + ((slot + n) >> 2);\n    vec4 t = fa_light_texel(param);\n    return int(t[(slot + n) & 3]);\n}\n\nint fa_cl_light(int n)\n{\n    if (n < fa_cl_ndir)\n    {\n        return n;\n    }\n    int param = fa_cl_slot;\n    int param_1 = n - fa_cl_ndir;\n    return fa_cluster_index(param, param_1);\n}\n\nint fa_light_base(int li)\n{\n    return li * ((fa_mesh_fs_params[1].w > 4.5) ? 8 : 4);\n}\n\nbool fa_light_baked(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 3;\n    return fa_light_texel(param_1).w > 0.5;\n}\n\nfloat fa_baked_keep(int li)\n{\n    float _6454;\n    if (fa_lm.z > 0.5)\n    {\n        _6454 = 0.0;\n    }\n    else\n    {\n        _6454 = 1.0 - clamp(fa_mesh_fs_params[32].w, 0.0, 1.0);\n    }\n    bool _6465 = _6454 < 1.0;\n    bool _6471;\n    if (_6465)\n    {\n        int param = li;\n        _6471 = fa_light_baked(param);\n    }\n    else\n    {\n        _6471 = _6465;\n    }\n    return _6471 ? _6454 : 1.0;\n}\n\nfloat fa_light_type(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 1;\n    return fa_light_texel(param_1).w;\n}\n\nvec4 fa_atlas_fetch(vec2 texel)\n{\n    return textureLod(fa_light_atlas_fa_env_smp, texel / vec2(textureSize(fa_light_atlas_fa_env_smp, 0)), 0.0);\n}\n\nvec3 fa_cookie_sample(vec2 tile_origin, vec2 uv)\n{\n    vec2 param = (tile_origin + vec2(1.0)) + (clamp(uv, vec2(0.0), vec2(1.0)) * 254.0);\n    return fa_atlas_fetch(param).xyz;\n}\n\nvec3 fa_area_point(vec3 c, vec3 axis, vec3 ru, vec3 uu, float hx, float hy, float shape, vec3 p, vec3 r)\n{\n    bool _886 = dot(r, r) > 0.5;\n    if (shape > 1.5)\n    {\n        vec3 _899 = (c - (ru * hx)) - p;\n        vec3 _905 = ru * (2.0 * hx);\n        float _911 = max(dot(_905, _905), 9.9999999392252902907785028219223e-09);\n        float _915 = dot(_899, _905);\n        float t = clamp((-_915) / _911, 0.0, 1.0);\n        if (_886)\n        {\n            float _930 = dot(r, _905);\n            float _936 = _911 - (_930 * _930);\n            if (abs(_936) > (9.9999997473787516355514526367188e-06 * _911))\n            {\n                t = clamp(((dot(r, _899) * _930) - _915) / _936, 0.0, 1.0);\n            }\n        }\n        return (p + _899) + (_905 * t);\n    }\n    vec3 q = p;\n    float _968 = dot(r, axis);\n    bool _976;\n    if (_886)\n    {\n        _976 = abs(_968) > 9.9999997473787516355514526367188e-05;\n    }\n    else\n    {\n        _976 = _886;\n    }\n    if (_976)\n    {\n        float _986 = dot(c - p, axis) / _968;\n        if (_986 > 0.0)\n        {\n            q = p + (r * _986);\n        }\n    }\n    vec3 _999 = q - c;\n    vec2 xy = vec2(dot(_999, ru), dot(_999, uu));\n    if (shape > 0.5)\n    {\n        float _1014 = length(xy);\n        if (_1014 > hx)\n        {\n            xy *= (hx / _1014);\n        }\n    }\n    else\n    {\n        xy = clamp(xy, vec2(-hx, -hy), vec2(hx, hy));\n    }\n    return (c + (ru * xy.x)) + (uu * xy.y);\n}\n\nint fa_cube_face(vec3 d)\n{\n    vec3 _653 = abs(d);\n    float _655 = _653.x;\n    float _657 = _653.y;\n    bool _658 = _655 >= _657;\n    bool _666;\n    if (_658)\n    {\n        _666 = _655 >= _653.z;\n    }\n    else\n    {\n        _666 = _658;\n    }\n    int _667;\n    if (_666)\n    {\n        _667 = (d.x > 0.0) ? 0 : 1;\n    }\n    else\n    {\n        int _681;\n        if (_657 >= _653.z)\n        {\n            _681 = (d.y > 0.0) ? 2 : 3;\n        }\n        else\n        {\n            _681 = (d.z > 0.0) ? 4 : 5;\n        }\n        _667 = _681;\n    }\n    return _667;\n}\n\nvoid fa_cube_face_basis(int f, out vec3 fwd, out vec3 up)\n{\n    if (f == 0)\n    {\n        fwd = vec3(1.0, 0.0, 0.0);\n        up = vec3(0.0, 1.0, 0.0);\n    }\n    else\n    {\n        if (f == 1)\n        {\n            fwd = vec3(-1.0, 0.0, 0.0);\n            up = vec3(0.0, 1.0, 0.0);\n        }\n        else\n        {\n            if (f == 2)\n            {\n                fwd = vec3(0.0, 1.0, 0.0);\n                up = vec3(0.0, 0.0, 1.0);\n            }\n            else\n            {\n                if (f == 3)\n                {\n                    fwd = vec3(0.0, -1.0, 0.0);\n                    up = vec3(0.0, 0.0, -1.0);\n                }\n                else\n                {\n                    if (f == 4)\n                    {\n                        fwd = vec3(0.0, 0.0, 1.0);\n                        up = vec3(0.0, 1.0, 0.0);\n                    }\n                    else\n                    {\n                        fwd = vec3(0.0, 0.0, -1.0);\n                        up = vec3(0.0, 1.0, 0.0);\n                    }\n                }\n            }\n        }\n    }\n}\n\nfloat fa_ies_sample(vec2 tile_origin, vec3 d, vec3 axis, vec3 right, vec3 up)\n{\n    float _806 = dot(d, right);\n    float _810 = dot(d, up);\n    float _821;\n    if (((_806 * _806) + (_810 * _810)) > 1.0000000133514319600180897396058e-10)\n    {\n        _821 = atan(_810, _806) * 0.15915493667125701904296875;\n    }\n    else\n    {\n        _821 = 0.0;\n    }\n    vec2 param = tile_origin + vec2(1.0 + ((_821 - floor(_821)) * 64.0), 1.0 + (acos(clamp(dot(d, axis), -1.0, 1.0)) * 10.18591594696044921875));\n    return fa_atlas_fetch(param).x;\n}\n\nLightSample fa_light_sample_n(int li, vec3 world_pos, vec3 n)\n{\n    int param = li;\n    int _1052 = fa_light_base(param);\n    bool _1056 = fa_mesh_fs_params[1].w > 4.5;\n    int param_1 = _1052;\n    vec4 _1060 = fa_light_texel(param_1);\n    int param_2 = _1052 + 1;\n    vec4 _1065 = fa_light_texel(param_2);\n    float _1068 = _1065.w;\n    float atten = 1.0;\n    float dist = 0.0;\n    fa_light_tint = vec3(1.0);\n    bool _1080 = _1056 && (_1068 > 2.5);\n    fa_light_is_area = _1080;\n    bool _1082 = _1068 < 0.5;\n    vec3 l;\n    if (_1082)\n    {\n        l = normalize(_1060.xyz);\n        if (_1056)\n        {\n            int param_3 = _1052 + 6;\n            vec4 _1096 = fa_light_texel(param_3);\n            if (_1096.z > 0.5)\n            {\n                int param_4 = _1052 + 4;\n                vec4 _1106 = fa_light_texel(param_4);\n                int param_5 = _1052 + 5;\n                vec4 _1111 = fa_light_texel(param_5);\n                vec2 param_6 = _1096.xy;\n                vec2 param_7 = fract(vec2(dot(world_pos, _1106.xyz) * _1106.w, (-dot(world_pos, _1111.xyz)) * _1111.w) + vec2(0.5));\n                fa_light_tint = fa_cookie_sample(param_6, param_7);\n            }\n        }\n    }\n    else\n    {\n        vec3 _1141 = _1060.xyz;\n        vec3 _1143 = _1141 - world_pos;\n        vec3 to_light = _1143;\n        float _1146 = length(_1143);\n        float reach = _1146;\n        bool front = true;\n        if (_1080)\n        {\n            int param_8 = _1052 + 7;\n            reach = max(_1146 - fa_light_texel(param_8).w, 0.0);\n            int param_9 = _1052 + 4;\n            vec4 _1170 = fa_light_texel(param_9);\n            int param_10 = _1052 + 5;\n            vec4 _1175 = fa_light_texel(param_10);\n            int param_11 = _1052 + 6;\n            vec4 _1180 = fa_light_texel(param_11);\n            float _1181 = _1180.w;\n            int param_12 = _1052 + 2;\n            vec3 _1188 = normalize(fa_light_texel(param_12).xyz);\n            bool _1190 = _1181 > 1.5;\n            bool _1198;\n            if (!_1190)\n            {\n                _1198 = dot(_1188, to_light) < 0.0;\n            }\n            else\n            {\n                _1198 = _1190;\n            }\n            front = _1198;\n            vec3 r = vec3(0.0);\n            vec3 _1207 = fa_mesh_fs_params[0].xyz - world_pos;\n            bool _1211 = dot(n, n) > 0.5;\n            bool _1219;\n            if (_1211)\n            {\n                _1219 = dot(_1207, _1207) > 9.9999999600419720025001879548654e-13;\n            }\n            else\n            {\n                _1219 = _1211;\n            }\n            if (_1219)\n            {\n                r = reflect(-normalize(_1207), normalize(n));\n            }\n            vec3 param_13 = _1141;\n            vec3 param_14 = _1188;\n            vec3 param_15 = _1170.xyz;\n            vec3 param_16 = _1175.xyz;\n            float param_17 = _1170.w;\n            float param_18 = _1175.w;\n            float param_19 = _1181;\n            vec3 param_20 = world_pos;\n            vec3 param_21 = r;\n            to_light = fa_area_point(param_13, param_14, param_15, param_16, param_17, param_18, param_19, param_20, param_21) - world_pos;\n        }\n        float _1255 = length(to_light);\n        dist = _1255;\n        l = to_light / vec3(max(_1255, 9.9999997473787516355514526367188e-05));\n        float _1269 = reach / max(_1060.w, 0.001000000047497451305389404296875);\n        float _1275 = clamp(1.0 - (_1269 * _1269), 0.0, 1.0);\n        float _1277;\n        if (front)\n        {\n            _1277 = _1275 * _1275;\n        }\n        else\n        {\n            _1277 = 0.0;\n        }\n        atten = _1277;\n        bool _1288 = _1068 < 2.5;\n        if ((_1068 > 1.5) && _1288)\n        {\n            int param_22 = _1052 + 2;\n            vec4 _1296 = fa_light_texel(param_22);\n            float _1306 = _1296.w;\n            int param_23 = _1052 + 3;\n            vec4 _1311 = fa_light_texel(param_23);\n            float _1312 = _1311.x;\n            float cos_inner = _1312;\n            if (_1312 > 1.5)\n            {\n                cos_inner = mix(_1306, 1.0, 0.25);\n            }\n            atten *= smoothstep(_1306, cos_inner, dot(-l, normalize(_1296.xyz)));\n        }\n        if (_1056 && (_1068 < 1.5))\n        {\n            int param_24 = _1052 + 6;\n            vec4 _1336 = fa_light_texel(param_24);\n            if (_1336.z > 0.5)\n            {\n                vec3 _1344 = -to_light;\n                int param_25 = _1052 + 4;\n                int param_26 = _1052 + 5;\n                vec3 _1358 = fa_light_texel(param_25).xyz;\n                vec3 _1362 = fa_light_texel(param_26).xyz;\n                vec3 _1371 = vec3(dot(_1344, _1358), dot(_1344, _1362), dot(_1344, cross(_1358, _1362)));\n                vec3 param_27 = _1371;\n                int _1375 = fa_cube_face(param_27);\n                int param_28 = _1375;\n                vec3 param_29;\n                vec3 param_30;\n                fa_cube_face_basis(param_28, param_29, param_30);\n                vec2 _1402 = vec2(dot(_1371, cross(param_29, param_30)), dot(_1371, param_30)) / vec2(max(dot(_1371, param_29), 9.9999997473787516355514526367188e-05));\n                int _1406 = _1375 / 3;\n                vec2 param_31 = _1336.xy + (vec2(float(_1375 - (_1406 * 3)), float(_1406)) * 256.0);\n                vec2 param_32 = vec2(0.5 + (0.5 * _1402.x), 0.5 - (0.5 * _1402.y));\n                fa_light_tint = fa_cookie_sample(param_31, param_32);\n            }\n            int param_33 = _1052 + 7;\n            vec4 _1436 = fa_light_texel(param_33);\n            if (_1436.z > 0.5)\n            {\n                int param_34 = _1052 + 2;\n                int param_35 = _1052 + 4;\n                int param_36 = _1052 + 5;\n                vec2 param_37 = _1436.xy;\n                vec3 param_38 = -l;\n                vec3 param_39 = normalize(fa_light_texel(param_34).xyz);\n                vec3 param_40 = fa_light_texel(param_35).xyz;\n                vec3 param_41 = fa_light_texel(param_36).xyz;\n                atten *= fa_ies_sample(param_37, param_38, param_39, param_40, param_41);\n            }\n        }\n        else\n        {\n            if (_1056 && _1288)\n            {\n                int param_42 = _1052 + 6;\n                vec4 _1483 = fa_light_texel(param_42);\n                int param_43 = _1052 + 7;\n                vec4 _1488 = fa_light_texel(param_43);\n                bool _1491 = _1483.z > 0.5;\n                bool _1498;\n                if (!_1491)\n                {\n                    _1498 = _1488.z > 0.5;\n                }\n                else\n                {\n                    _1498 = _1491;\n                }\n                if (_1498)\n                {\n                    int param_44 = _1052 + 2;\n                    vec4 _1505 = fa_light_texel(param_44);\n                    vec3 _1509 = normalize(_1505.xyz);\n                    int param_45 = _1052 + 4;\n                    vec4 _1514 = fa_light_texel(param_45);\n                    int param_46 = _1052 + 5;\n                    vec4 _1519 = fa_light_texel(param_46);\n                    if (_1491)\n                    {\n                        vec3 _1527 = -to_light;\n                        float _1534 = _1505.w;\n                        float _1550 = 0.5 / max(dot(_1527, _1509) * (sqrt(max(1.0 - (_1534 * _1534), 0.0)) / max(_1534, 0.001000000047497451305389404296875)), 9.9999997473787516355514526367188e-05);\n                        vec2 param_47 = _1483.xy;\n                        vec2 param_48 = vec2(0.5 + (dot(_1527, _1514.xyz) * _1550), 0.5 - (dot(_1527, _1519.xyz) * _1550));\n                        fa_light_tint = fa_cookie_sample(param_47, param_48);\n                    }\n                    if (_1488.z > 0.5)\n                    {\n                        vec2 param_49 = _1488.xy;\n                        vec3 param_50 = -l;\n                        vec3 param_51 = _1509;\n                        vec3 param_52 = _1514.xyz;\n                        vec3 param_53 = _1519.xyz;\n                        atten *= fa_ies_sample(param_49, param_50, param_51, param_52, param_53);\n                    }\n                }\n            }\n        }\n    }\n    vec3 _9766 = _1065.xyz * atten;\n    if (_1056)\n    {\n        _9766 *= fa_light_tint;\n    }\n    int _1619;\n    if (_1082)\n    {\n        _1619 = 0;\n    }\n    else\n    {\n        _1619 = ((_1068 > 1.5) && (_1068 < 2.5)) ? 2 : 1;\n    }\n    return LightSample(l, _9766, atten, 1.0, dist, _1619);\n}\n\nfloat fa_shadow_split_at(int i)\n{\n    float _2345;\n    if (i == 0)\n    {\n        _2345 = fa_shadows[24].x;\n    }\n    else\n    {\n        float _2361;\n        if (i == 1)\n        {\n            _2361 = fa_shadows[24].y;\n        }\n        else\n        {\n            float _2369;\n            if (i == 2)\n            {\n                _2369 = fa_shadows[24].z;\n            }\n            else\n            {\n                _2369 = fa_shadows[24].w;\n            }\n            _2361 = _2369;\n        }\n        _2345 = _2361;\n    }\n    return _2345;\n}\n\nfloat fa_shadow_depth(inout vec2 uv, vec4 rect)\n{\n    uv = clamp(uv, rect.xy, rect.zw);\n    return textureLod(fa_shadow_tex_fa_shadow_smp, uv, 0.0).x;\n}\n\nfloat fa_shadow_fetch(vec2 uv, vec4 rect, vec3 conv)\n{\n    vec2 param = uv;\n    vec4 param_1 = rect;\n    float _2402 = fa_shadow_depth(param, param_1);\n    float _2406;\n    if (conv.x < 0.5)\n    {\n        _2406 = _2402;\n    }\n    else\n    {\n        _2406 = (conv.y * conv.z) / (conv.z - (_2402 * (conv.z - conv.y)));\n    }\n    return _2406;\n}\n\nfloat fa_shadow_noise()\n{\n    return fract(52.98291778564453125 * fract(dot(gl_FragCoord.xy, vec2(0.067110560834407806396484375, 0.005837149918079376220703125))));\n}\n\nvec2 fa_shadow_vogel_turn(vec2 d)\n{\n    return vec2((d.x * (-0.737368881702423095703125)) - (d.y * 0.675490319728851318359375), (d.y * (-0.737368881702423095703125)) + (d.x * 0.675490319728851318359375));\n}\n\nfloat fa_shadow_filter(vec2 uv, vec4 rect, float zr, float texel_m, float unit, float reach, float plane, vec3 conv, int mode, float k)\n{\n    if (mode == 1)\n    {\n        vec2 param = uv;\n        vec4 param_1 = rect;\n        vec3 param_2 = conv;\n        return float(zr <= fa_shadow_fetch(param, param_1, param_2));\n    }\n    float _2452 = fa_shadow_noise() * 6.283185482025146484375;\n    vec2 _2458 = vec2(cos(_2452), sin(_2452));\n    vec2 dir = _2458;\n    float radius = 1.5;\n    if (mode == 2)\n    {\n        float _2467;\n        if (k < 0.0)\n        {\n            _2467 = (-k) / max(zr, 0.100000001490116119384765625);\n        }\n        else\n        {\n            _2467 = k;\n        }\n        float _2486 = clamp((_2467 * reach) / texel_m, 3.0, 12.0);\n        float sum = 0.0;\n        float cnt = 0.0;\n        for (int i = 0; i < 16; i++)\n        {\n            float _2505 = sqrt((float(i) + 0.5) * 0.0625) * _2486;\n            vec2 param_3 = uv + (dir * (fa_shadows[26].zw * _2505));\n            vec4 param_4 = rect;\n            vec3 param_5 = conv;\n            float _2519 = fa_shadow_fetch(param_3, param_4, param_5);\n            if (_2519 < (zr - (_2505 * plane)))\n            {\n                sum += _2519;\n                cnt += 1.0;\n            }\n            vec2 param_6 = dir;\n            dir = fa_shadow_vogel_turn(param_6);\n        }\n        if (cnt < 0.5)\n        {\n            return 1.0;\n        }\n        float _2547 = sum / cnt;\n        float _2557;\n        if (k < 0.0)\n        {\n            _2557 = (-k) / max(_2547, 0.0500000007450580596923828125);\n        }\n        else\n        {\n            _2557 = k;\n        }\n        radius = clamp(((max(zr - _2547, 0.0) * unit) * _2557) / texel_m, 1.5, 16.0);\n        dir = _2458;\n    }\n    float lit = 0.0;\n    int _2583 = (mode == 2) ? 24 : 16;\n    for (int i_1 = 0; i_1 < _2583; i_1++)\n    {\n        float _2602 = sqrt((float(i_1) + 0.5) / float(_2583)) * radius;\n        vec2 param_7 = uv + (dir * (fa_shadows[26].zw * _2602));\n        vec4 param_8 = rect;\n        vec3 param_9 = conv;\n        lit += float((zr - (_2602 * plane)) <= fa_shadow_fetch(param_7, param_8, param_9));\n        vec2 param_10 = dir;\n        dir = fa_shadow_vogel_turn(param_10);\n    }\n    return lit / float(_2583);\n}\n\nfloat fa_shadow_cascade(int ci, vec3 world, vec3 n, vec3 l)\n{\n    float _2648 = max(fa_shadows[ci * 1 + 20].y, 0.001000000047497451305389404296875);\n    float _2653 = clamp(dot(n, l), 0.0, 1.0);\n    float _2659 = sqrt(1.0 - (_2653 * _2653));\n    float _2667 = min(_2659 / max(_2653, 0.20000000298023223876953125), 4.0);\n    float _2672;\n    if (fa_shadows[26].y > 0.0)\n    {\n        _2672 = fa_shadows[26].y;\n    }\n    else\n    {\n        _2672 = 1.5 * fa_shadows[ci * 1 + 20].x;\n    }\n    vec4 _2697 = mat4(fa_shadows[ci * 4 + 0], fa_shadows[ci * 4 + 1], fa_shadows[ci * 4 + 2], fa_shadows[ci * 4 + 3]) * vec4(world + (n * (_2672 * _2659)), 1.0);\n    float _2704 = _2697.x;\n    bool _2707 = _2704 < fa_shadows[ci * 1 + 16].x;\n    bool _2716;\n    if (!_2707)\n    {\n        _2716 = _2704 > fa_shadows[ci * 1 + 16].z;\n    }\n    else\n    {\n        _2716 = _2707;\n    }\n    bool _2725;\n    if (!_2716)\n    {\n        _2725 = _2697.y < fa_shadows[ci * 1 + 16].y;\n    }\n    else\n    {\n        _2725 = _2716;\n    }\n    bool _2734;\n    if (!_2725)\n    {\n        _2734 = _2697.y > fa_shadows[ci * 1 + 16].w;\n    }\n    else\n    {\n        _2734 = _2725;\n    }\n    bool _2741;\n    if (!_2734)\n    {\n        _2741 = _2697.z > 1.0;\n    }\n    else\n    {\n        _2741 = _2734;\n    }\n    if (_2741)\n    {\n        return -1.0;\n    }\n    float _2749;\n    if (fa_shadows[26].x > 0.0)\n    {\n        _2749 = fa_shadows[26].x;\n    }\n    else\n    {\n        _2749 = 1.5 * fa_shadows[ci * 1 + 20].x;\n    }\n    vec2 param = _2697.xy;\n    vec4 param_1 = fa_shadows[ci * 1 + 16];\n    float param_2 = _2697.z - ((_2749 * (1.0 + (0.5 * _2667))) / _2648);\n    float param_3 = fa_shadows[ci * 1 + 20].x;\n    float param_4 = _2648;\n    float param_5 = _2648 * 0.25;\n    float param_6 = ((fa_shadows[ci * 1 + 20].x * min(_2667, 3.0)) * 0.5) / _2648;\n    vec3 param_7 = vec3(0.0);\n    int param_8 = int(fa_shadows[25].z + 0.5);\n    float param_9 = fa_shadows[25].w;\n    return fa_shadow_filter(param, param_1, param_2, param_3, param_4, param_5, param_6, param_7, param_8, param_9);\n}\n\nfloat fa_shadow_sun(vec3 world, vec3 n, vec3 l)\n{\n    if (fa_mesh_fs_params[5].z < 0.5)\n    {\n        return 1.0;\n    }\n    int _3127 = int(fa_shadows[25].x + 0.5);\n    if (_3127 < 1)\n    {\n        return 1.0;\n    }\n    float _3142 = dot(world - fa_shadows[27].xyz, fa_shadows[28].xyz);\n    int param = _3127 - 1;\n    if (_3142 > fa_shadow_split_at(param))\n    {\n        return 1.0;\n    }\n    int ci = 0;\n    bool _3154 = _3127 > 1;\n    bool _3161;\n    if (_3154)\n    {\n        _3161 = _3142 > fa_shadows[24].x;\n    }\n    else\n    {\n        _3161 = _3154;\n    }\n    if (_3161)\n    {\n        ci = 1;\n    }\n    bool _3165 = _3127 > 2;\n    bool _3172;\n    if (_3165)\n    {\n        _3172 = _3142 > fa_shadows[24].y;\n    }\n    else\n    {\n        _3172 = _3165;\n    }\n    if (_3172)\n    {\n        ci = 2;\n    }\n    bool _3176 = _3127 > 3;\n    bool _3183;\n    if (_3176)\n    {\n        _3183 = _3142 > fa_shadows[24].z;\n    }\n    else\n    {\n        _3183 = _3176;\n    }\n    if (_3183)\n    {\n        ci = 3;\n    }\n    float s = -1.0;\n    float s2 = -1.0;\n    float t = 0.0;\n    int _3194 = min(_3127, 4);\n    float _3235;\n    for (int c = ci; c < _3194; c++)\n    {\n        int param_1 = c;\n        vec3 param_2 = world;\n        vec3 param_3 = n;\n        vec3 param_4 = l;\n        float _3214 = fa_shadow_cascade(param_1, param_2, param_3, param_4);\n        if (s >= 0.0)\n        {\n            s2 = _3214;\n            break;\n        }\n        if (_3214 < 0.0)\n        {\n            continue;\n        }\n        s = _3214;\n        ci = c;\n        if (fa_shadows[25].y > 0.0)\n        {\n            if (ci > 0)\n            {\n                int param_5 = ci - 1;\n                _3235 = fa_shadow_split_at(param_5);\n            }\n            else\n            {\n                _3235 = fa_shadows[28].w;\n            }\n            int param_6 = ci;\n            float _3254 = fa_shadows[25].y * max(fa_shadow_split_at(param_6) - _3235, 9.9999997473787516355514526367188e-05);\n            int param_7 = ci;\n            t = clamp((_3142 - (fa_shadow_split_at(param_7) - _3254)) / _3254, 0.0, 1.0);\n        }\n        if (t <= 0.0)\n        {\n            break;\n        }\n    }\n    if (s < 0.0)\n    {\n        return 1.0;\n    }\n    if (t > 0.0)\n    {\n        float _3286;\n        if ((ci + 1) < _3127)\n        {\n            _3286 = (s2 < 0.0) ? s : s2;\n        }\n        else\n        {\n            _3286 = 1.0;\n        }\n        s = mix(s, _3286, t);\n    }\n    return s;\n}\n\nfloat fa_shadow_factor(vec3 n, vec3 l)\n{\n    bool _3391 = fa_mesh_fs_params[25].y > 0.5;\n    bool _3397;\n    if (_3391)\n    {\n        _3397 = fa_mesh_fs_params[5].z > 0.5;\n    }\n    else\n    {\n        _3397 = _3391;\n    }\n    if (_3397)\n    {\n        float _3411 = dot(fa_mesh_fs_params[29].xyz, fa_world_pos) + fa_mesh_fs_params[29].w;\n        vec4 _3419 = vec4(fa_world_pos, 1.0);\n        float _3425 = dot(fa_mesh_fs_params[28], _3419);\n        if (_3425 > 9.9999997473787516355514526367188e-05)\n        {\n            vec2 _3444 = vec2(dot(fa_mesh_fs_params[26], _3419), dot(fa_mesh_fs_params[27], _3419)) / vec2(_3425);\n            float _3449 = (_3444.x * 0.5) + 0.5;\n            float _3453;\n            if (fa_mesh_fs_params[24].y > 0.5)\n            {\n                _3453 = (_3444.y * 0.5) + 0.5;\n            }\n            else\n            {\n                _3453 = 0.5 - (_3444.y * 0.5);\n            }\n            bool _3469 = _3449 >= 0.0;\n            bool _3475;\n            if (_3469)\n            {\n                _3475 = _3449 < 1.0;\n            }\n            else\n            {\n                _3475 = _3469;\n            }\n            bool _3481;\n            if (_3475)\n            {\n                _3481 = _3453 >= 0.0;\n            }\n            else\n            {\n                _3481 = _3475;\n            }\n            bool _3487;\n            if (_3481)\n            {\n                _3487 = _3453 < 1.0;\n            }\n            else\n            {\n                _3487 = _3481;\n            }\n            if (_3487)\n            {\n                vec4 _3513 = texelFetch(fa_screen_tex_fa_shadow_smp, clamp(ivec2(vec2(_3449, _3453) * fa_mesh_fs_params[24].zw), ivec2(0), ivec2(fa_mesh_fs_params[24].zw) - ivec2(1)), 0);\n                bool _3516 = _3513.w > 0.5;\n                bool _3532;\n                if (_3516)\n                {\n                    _3532 = abs(_3411 - _3513.x) <= (((0.00200000009499490261077880859375 * _3411) + 0.00999999977648258209228515625) + fa_rt_slope);\n                }\n                else\n                {\n                    _3532 = _3516;\n                }\n                if (_3532)\n                {\n                    float _3538;\n                    if (fa_mesh_fs_params[25].z > 0.5)\n                    {\n                        vec3 param = fa_world_pos;\n                        vec3 param_1 = n;\n                        vec3 param_2 = l;\n                        _3538 = min(_3513.y, fa_shadow_sun(param, param_1, param_2));\n                    }\n                    else\n                    {\n                        _3538 = _3513.y;\n                    }\n                    return _3538;\n                }\n            }\n        }\n    }\n    vec3 param_3 = fa_world_pos;\n    vec3 param_4 = n;\n    vec3 param_5 = l;\n    return fa_shadow_sun(param_3, param_4, param_5);\n}\n\nfloat fa_shadow_local(int li, vec3 lpos, vec3 world, vec3 n, vec3 l)\n{\n    bool _2807 = fa_mesh_fs_params[5].z < 0.5;\n    bool _2814;\n    if (!_2807)\n    {\n        _2814 = fa_shadows[29].x < 0.5;\n    }\n    else\n    {\n        _2814 = _2807;\n    }\n    if (_2814)\n    {\n        return 1.0;\n    }\n    int param = (int(fa_shadows[29].x + 0.5) - 1) + li;\n    vec4 _2827 = fa_light_texel(param);\n    float _2828 = _2827.x;\n    if (_2828 < 0.0)\n    {\n        return 1.0;\n    }\n    int _2837 = int(_2828 + 0.5);\n    int param_1 = _2837;\n    vec4 _2841 = fa_light_texel(param_1);\n    int param_2 = _2837 + 1;\n    vec4 _2846 = fa_light_texel(param_2);\n    float fade = 1.0;\n    float _2849 = _2841.y;\n    if (_2849 > 0.0)\n    {\n        float _2866 = 1.0 - smoothstep(0.75 * _2849, _2849, length(world - fa_shadows[27].xyz));\n        fade = _2866;\n        if (_2866 <= 0.0)\n        {\n            return 1.0;\n        }\n    }\n    int face = 0;\n    if (_2841.x > 1.5)\n    {\n        vec3 param_3 = world - lpos;\n        face = fa_cube_face(param_3);\n    }\n    int _2890 = (_2837 + 2) + (face * 6);\n    int param_4 = _2890;\n    int param_5 = _2890 + 1;\n    int param_6 = _2890 + 3;\n    vec4 _2904 = fa_light_texel(param_6);\n    int param_7 = _2890 + 4;\n    vec4 _2909 = fa_light_texel(param_7);\n    int param_8 = _2890 + 5;\n    vec4 _2914 = fa_light_texel(param_8);\n    float _2926 = _2914.x * max(dot(_2904, vec4(world, 1.0)), 0.001000000047497451305389404296875);\n    float _2931 = clamp(dot(n, l), 0.0, 1.0);\n    float _2954 = clamp(dot(n, _2904.xyz), -1.0, 1.0);\n    float _2973 = min(sqrt(1.0 - (_2954 * _2954)) / max(abs(dot(n, world - lpos)) / max(dot(_2904, vec4(world, 1.0)), 0.001000000047497451305389404296875), 0.20000000298023223876953125), 4.0);\n    float _2976 = _2846.y;\n    float _2978;\n    if (_2976 > 0.0)\n    {\n        _2978 = _2976;\n    }\n    else\n    {\n        _2978 = 1.5 * _2926;\n    }\n    vec4 _2998 = vec4(world + (n * (_2978 * sqrt(1.0 - (_2931 * _2931)))), 1.0);\n    float _3002 = dot(_2904, _2998);\n    float _3005 = _2914.y;\n    if (_3002 < _3005)\n    {\n        return 1.0;\n    }\n    vec2 _3020 = vec2(dot(fa_light_texel(param_4), _2998), dot(fa_light_texel(param_5), _2998)) / vec2(_3002);\n    float _3022 = _3020.x;\n    bool _3025 = _3022 < _2909.x;\n    bool _3034;\n    if (!_3025)\n    {\n        _3034 = _3022 > _2909.z;\n    }\n    else\n    {\n        _3034 = _3025;\n    }\n    bool _3043;\n    if (!_3034)\n    {\n        _3043 = _3020.y < _2909.y;\n    }\n    else\n    {\n        _3043 = _3034;\n    }\n    bool _3052;\n    if (!_3043)\n    {\n        _3052 = _3020.y > _2909.w;\n    }\n    else\n    {\n        _3052 = _3043;\n    }\n    if (_3052)\n    {\n        return 1.0;\n    }\n    float _3058 = _2846.x;\n    float _3060;\n    if (_3058 > 0.0)\n    {\n        _3060 = _3058;\n    }\n    else\n    {\n        _3060 = 1.5 * _2926;\n    }\n    vec2 param_9 = _3020;\n    vec4 param_10 = _2909;\n    float param_11 = _3002 - (_3060 * (1.0 + (0.5 * _2973)));\n    float param_12 = _2926;\n    float param_13 = 1.0;\n    float param_14 = _2914.z * 0.25;\n    float param_15 = (_2926 * min(_2973, 3.0)) * 0.5;\n    vec3 param_16 = vec3(1.0, _3005, _2914.z);\n    int param_17 = int(_2841.z + 0.5);\n    float param_18 = _2841.w;\n    return mix(1.0, fa_shadow_filter(param_9, param_10, param_11, param_12, param_13, param_14, param_15, param_16, param_17, param_18), fade);\n}\n\nfloat fa_shadow_local_rt(int li, vec3 lpos, vec3 world, vec3 n, vec3 l)\n{\n    bool _3567 = fa_mesh_fs_params[25].w > 0.5;\n    bool _3573;\n    if (_3567)\n    {\n        _3573 = fa_mesh_fs_params[5].z > 0.5;\n    }\n    else\n    {\n        _3573 = _3567;\n    }\n    bool _3579;\n    if (_3573)\n    {\n        _3579 = fa_shadows[29].x > 0.5;\n    }\n    else\n    {\n        _3579 = _3573;\n    }\n    if (_3579)\n    {\n        int param = (int(fa_shadows[29].x + 0.5) - 1) + li;\n        vec4 _3591 = fa_light_texel(param);\n        float _3592 = _3591.z;\n        if (_3592 > 0.5)\n        {\n            float _3605 = dot(fa_mesh_fs_params[29].xyz, world) + fa_mesh_fs_params[29].w;\n            float _3611 = ((0.00200000009499490261077880859375 * _3605) + 0.00999999977648258209228515625) + fa_rt_slope;\n            vec4 _3617 = vec4(world, 1.0);\n            float _3622 = dot(fa_mesh_fs_params[28], _3617);\n            if (_3622 > 9.9999997473787516355514526367188e-05)\n            {\n                vec2 _3639 = vec2(dot(fa_mesh_fs_params[26], _3617), dot(fa_mesh_fs_params[27], _3617)) / vec2(_3622);\n                float _3644 = (_3639.x * 0.5) + 0.5;\n                float _3648;\n                if (fa_mesh_fs_params[24].y > 0.5)\n                {\n                    _3648 = (_3639.y * 0.5) + 0.5;\n                }\n                else\n                {\n                    _3648 = 0.5 - (_3639.y * 0.5);\n                }\n                bool _3664 = _3644 >= 0.0;\n                bool _3670;\n                if (_3664)\n                {\n                    _3670 = _3644 < 1.0;\n                }\n                else\n                {\n                    _3670 = _3664;\n                }\n                bool _3676;\n                if (_3670)\n                {\n                    _3676 = _3648 >= 0.0;\n                }\n                else\n                {\n                    _3676 = _3670;\n                }\n                bool _3682;\n                if (_3676)\n                {\n                    _3682 = _3648 < 1.0;\n                }\n                else\n                {\n                    _3682 = _3676;\n                }\n                if (_3682)\n                {\n                    ivec2 _3699 = ivec2(fa_mesh_fs_params[24].zw) - ivec2(1);\n                    ivec2 _3700 = clamp(ivec2(vec2(_3644, _3648) * fa_mesh_fs_params[24].zw), ivec2(0), _3699);\n                    float _3704;\n                    if (_3592 < 1.5)\n                    {\n                        _3704 = 1.0;\n                    }\n                    else\n                    {\n                        _3704 = (_3592 < 2.5) ? 256.0 : 65536.0;\n                    }\n                    float best = 2.0;\n                    int _3726;\n                    int _3732;\n                    for (int k = 0; k < 9; k++)\n                    {\n                        if (k == 0)\n                        {\n                            _3726 = 4;\n                        }\n                        else\n                        {\n                            if (k <= 4)\n                            {\n                                _3732 = k - 1;\n                            }\n                            else\n                            {\n                                _3732 = k;\n                            }\n                            _3726 = _3732;\n                        }\n                        vec4 _3761 = texelFetch(fa_screen_tex_fa_shadow_smp, clamp(_3700 + ivec2((_3726 % 3) - 1, (_3726 / 3) - 1), ivec2(0), _3699), 0);\n                        bool _3764 = _3761.w > 0.5;\n                        bool _3774;\n                        if (_3764)\n                        {\n                            _3774 = abs(_3605 - _3761.x) <= _3611;\n                        }\n                        else\n                        {\n                            _3774 = _3764;\n                        }\n                        if (_3774)\n                        {\n                            best = min(best, mod(floor(_3761.z / _3704), 256.0) * 0.0039215688593685626983642578125);\n                            if (k == 0)\n                            {\n                                break;\n                            }\n                        }\n                    }\n                    if (best <= 1.0)\n                    {\n                        float _3801;\n                        if (fa_mesh_fs_params[25].z > 0.5)\n                        {\n                            int param_1 = li;\n                            vec3 param_2 = lpos;\n                            vec3 param_3 = world;\n                            vec3 param_4 = n;\n                            vec3 param_5 = l;\n                            _3801 = min(best, fa_shadow_local(param_1, param_2, param_3, param_4, param_5));\n                        }\n                        else\n                        {\n                            _3801 = best;\n                        }\n                        return _3801;\n                    }\n                }\n            }\n            float _3824;\n            if (fa_mesh_fs_params[25].z > 0.5)\n            {\n                int param_6 = li;\n                vec3 param_7 = lpos;\n                vec3 param_8 = world;\n                vec3 param_9 = n;\n                vec3 param_10 = l;\n                _3824 = fa_shadow_local(param_6, param_7, param_8, param_9, param_10);\n            }\n            else\n            {\n                _3824 = 1.0;\n            }\n            return _3824;\n        }\n    }\n    int param_11 = li;\n    vec3 param_12 = lpos;\n    vec3 param_13 = world;\n    vec3 param_14 = n;\n    vec3 param_15 = l;\n    return fa_shadow_local(param_11, param_12, param_13, param_14, param_15);\n}\n\nfloat fa_contact_shadow(int li, vec3 world, vec3 gn, vec3 l, float dist)\n{\n    bool _5668 = fa_mesh_fs_params[24].x < 0.5;\n    bool _5675;\n    if (!_5668)\n    {\n        _5675 = fa_shadows[29].x < 0.5;\n    }\n    else\n    {\n        _5675 = _5668;\n    }\n    if (_5675)\n    {\n        return 1.0;\n    }\n    int param = (int(fa_shadows[29].x + 0.5) - 1) + li;\n    vec4 _5688 = fa_light_texel(param);\n    float _5689 = _5688.y;\n    float len = _5689;\n    if (_5689 <= 0.0)\n    {\n        return 1.0;\n    }\n    float _5701 = length(world - fa_mesh_fs_params[0].xyz);\n    float _5710 = 1.0 - smoothstep(0.5 * fa_mesh_fs_params[25].x, fa_mesh_fs_params[25].x, _5701);\n    if (_5710 <= 0.0)\n    {\n        return 1.0;\n    }\n    float _5716 = len;\n    float _5719 = min(_5716, 0.89999997615814208984375 * dist);\n    len = _5719;\n    float _5724 = 0.004999999888241291046142578125 + (0.0030000000260770320892333984375 * _5701);\n    float _5729 = _5724 + (0.5 * _5719);\n    vec3 _5735 = world + (gn * _5724);\n    float _5737 = fa_shadow_noise();\n    float occ = 0.0;\n    float _5798;\n    for (int k = 0; k < 12; k++)\n    {\n        float _5752 = (float(k) + _5737) * 0.083333335816860198974609375;\n        vec3 _5760 = _5735 + (l * (_5752 * len));\n        vec4 _5766 = vec4(_5760, 1.0);\n        float _5771 = dot(fa_mesh_fs_params[28], _5766);\n        if (_5771 < 9.9999997473787516355514526367188e-05)\n        {\n            break;\n        }\n        vec2 _5789 = vec2(dot(fa_mesh_fs_params[26], _5766), dot(fa_mesh_fs_params[27], _5766)) / vec2(_5771);\n        float _5793 = _5789.x * 0.5;\n        float _5794 = _5793 + 0.5;\n        if (fa_mesh_fs_params[24].y > 0.5)\n        {\n            _5798 = (_5789.y * 0.5) + 0.5;\n        }\n        else\n        {\n            _5798 = 0.5 - (_5789.y * 0.5);\n        }\n        bool _5814 = _5794 < 0.0;\n        bool _5821;\n        if (!_5814)\n        {\n            _5821 = _5794 >= 1.0;\n        }\n        else\n        {\n            _5821 = _5814;\n        }\n        bool _5828;\n        if (!_5821)\n        {\n            _5828 = _5798 < 0.0;\n        }\n        else\n        {\n            _5828 = _5821;\n        }\n        bool _5835;\n        if (!_5828)\n        {\n            _5835 = _5798 >= 1.0;\n        }\n        else\n        {\n            _5835 = _5828;\n        }\n        if (_5835)\n        {\n            break;\n        }\n        vec4 _5859 = texelFetch(fa_screen_tex_fa_shadow_smp, clamp(ivec2(vec2(_5794, _5798) * fa_mesh_fs_params[24].zw), ivec2(0), ivec2(fa_mesh_fs_params[24].zw) - ivec2(1)), 0);\n        if (_5859.w < 0.5)\n        {\n            continue;\n        }\n        float _5877 = (dot(fa_mesh_fs_params[29].xyz, _5760) + fa_mesh_fs_params[29].w) - _5859.x;\n        if ((_5877 > _5724) && (_5877 < _5729))\n        {\n            occ = max(occ, (1.0 - (_5752 * _5752)) * smoothstep(0.0, 0.0500000007450580596923828125, min(min(_5794, 0.5 - _5793), min(_5798, 1.0 - _5798))));\n        }\n    }\n    return 1.0 - (occ * _5710);\n}\n\nLightSample fa_light_shadowed(int li, vec3 world_pos, vec3 gn)\n{\n    int param = li;\n    float _6539 = fa_baked_keep(param);\n    if (_6539 <= 0.0)\n    {\n        int param_1 = li;\n        return LightSample(vec3(0.0, 1.0, 0.0), vec3(0.0), 0.0, 1.0, 0.0, int(fa_light_type(param_1) + 0.5));\n    }\n    int param_2 = li;\n    vec3 param_3 = world_pos;\n    vec3 param_4 = gn;\n    LightSample _6565 = fa_light_sample_n(param_2, param_3, param_4);\n    vec3 _9835 = _6565.color;\n    float _9836 = _6565.attenuation;\n    float _9837 = _6565.shadow;\n    bool _6568 = _6565.type == 0;\n    if (_6568 && (li == 0))\n    {\n        vec3 param_5 = gn;\n        vec3 param_6 = _6565.direction;\n        float _6579 = fa_shadow_factor(param_5, param_6);\n        _9837 = _6579;\n        _9835 *= _6579;\n    }\n    else\n    {\n        bool _6590 = _6565.type != 0;\n        bool _6596;\n        if (_6590)\n        {\n            _6596 = _9836 > 0.0;\n        }\n        else\n        {\n            _6596 = _6590;\n        }\n        if (_6596)\n        {\n            int param_7 = li;\n            int param_8 = fa_light_base(param_7);\n            int param_9 = li;\n            vec3 param_10 = fa_light_texel(param_8).xyz;\n            vec3 param_11 = world_pos;\n            vec3 param_12 = gn;\n            vec3 param_13 = _6565.direction;\n            float _6615 = fa_shadow_local_rt(param_9, param_10, param_11, param_12, param_13);\n            _9837 = _6615;\n            _9835 *= _6615;\n        }\n    }\n    bool _6625 = fa_mesh_fs_params[24].x > 0.5;\n    bool _6631;\n    if (_6625)\n    {\n        _6631 = _9836 > 0.0;\n    }\n    else\n    {\n        _6631 = _6625;\n    }\n    if (_6631)\n    {\n        float _6638;\n        if (_6568)\n        {\n            _6638 = 1000000000.0;\n        }\n        else\n        {\n            _6638 = _6565._distance;\n        }\n        int param_14 = li;\n        vec3 param_15 = world_pos;\n        vec3 param_16 = gn;\n        vec3 param_17 = _6565.direction;\n        float param_18 = _6638;\n        float _6656 = fa_contact_shadow(param_14, param_15, param_16, param_17, param_18);\n        _9837 *= _6656;\n        _9835 *= _6656;\n    }\n    float _6669 = _9836;\n    float _6670 = _6669 * _6539;\n    _9836 = _6670;\n    vec3 _6674 = _9835;\n    vec3 _6675 = _6674 * _6539;\n    _9835 = _6675;\n    return LightSample(_6565.direction, _6675, _6670, _9837, _6565._distance, _6565.type);\n}\n\nvec3 fa_ltc_tangent(vec3 n, vec3 v)\n{\n    vec3 _6709 = v - (n * dot(v, n));\n    vec3 t = _6709;\n    float _6713 = dot(_6709, _6709);\n    float l2 = _6713;\n    if (_6713 < 1.0000000133514319600180897396058e-10)\n    {\n        vec3 _6723;\n        if (abs(n.z) < 0.999000012874603271484375)\n        {\n            _6723 = cross(n, vec3(0.0, 0.0, 1.0));\n        }\n        else\n        {\n            _6723 = cross(n, vec3(1.0, 0.0, 0.0));\n        }\n        t = _6723;\n        l2 = dot(_6723, _6723);\n    }\n    return t * inversesqrt(l2);\n}\n\nvec3 fa_ltc_local(vec3 t1, vec3 n, vec3 p)\n{\n    return vec3(dot(t1, p), dot(cross(n, t1), p), dot(n, p));\n}\n\nvec2 fa_ltc_uv(float roughness, float ndv)\n{\n    return ((vec2(clamp((roughness - 0.0500000007450580596923828125) * 1.0526316165924072265625, 0.0, 1.0), sqrt(clamp(1.0 - ndv, 0.0, 1.0))) * 63.0) + vec2(0.5)) * vec2(0.015625);\n}\n\nvec3 fa_oct_vertex(int j, vec3 pc, vec3 ex, vec3 ey)\n{\n    float _7110;\n    if ((j == 0) || (j == 7))\n    {\n        _7110 = 0.92387950420379638671875;\n    }\n    else\n    {\n        float _7120;\n        if ((j == 3) || (j == 4))\n        {\n            _7120 = -0.92387950420379638671875;\n        }\n        else\n        {\n            _7120 = ((j == 1) || (j == 6)) ? 0.3826834261417388916015625 : (-0.3826834261417388916015625);\n        }\n        _7110 = _7120;\n    }\n    float _7141;\n    if ((j == 1) || (j == 2))\n    {\n        _7141 = 0.92387950420379638671875;\n    }\n    else\n    {\n        float _7150;\n        if ((j == 5) || (j == 6))\n        {\n            _7150 = -0.92387950420379638671875;\n        }\n        else\n        {\n            _7150 = ((j == 0) || (j == 3)) ? 0.3826834261417388916015625 : (-0.3826834261417388916015625);\n        }\n        _7141 = _7150;\n    }\n    return (pc + (ex * _7110)) + (ey * _7141);\n}\n\nvec3 fa_ltc_edge_vector(vec3 a, vec3 b)\n{\n    float _6758 = dot(a, a);\n    float _6762 = dot(b, b);\n    if ((_6758 < 1.0000000195414813782625560981111e-24) || (_6762 < 1.0000000195414813782625560981111e-24))\n    {\n        return vec3(0.0);\n    }\n    vec3 _6776 = a * inversesqrt(_6758);\n    vec3 _6781 = b * inversesqrt(_6762);\n    float _6785 = dot(_6776, _6781);\n    float _6788 = abs(_6785);\n    float g = (((((((((((0.0416471660137176513671875 * _6788) - 0.1924748718738555908203125) * _6788) + 0.4179156124591827392578125) * _6788) - 0.616057217121124267578125) * _6788) + 0.777722418308258056640625) * _6788) - 0.999542415142059326171875) * _6788) + 1.570791721343994140625;\n    if (_6785 < 0.0)\n    {\n        g = (3.1415927410125732421875 * inversesqrt(max(1.0 - (_6785 * _6785), 1.0000000116860974230803549289703e-07))) - g;\n    }\n    return cross(_6776, _6781) * g;\n}\n\nvoid fa_ltc_clip_edge(vec3 a, vec3 b, inout vec3 sum, inout vec3 leave, inout vec3 enter, inout vec2 seen)\n{\n    bool _6845 = a.z > 0.0;\n    bool _6849 = b.z > 0.0;\n    if (_6845 && _6849)\n    {\n        vec3 param = a;\n        vec3 param_1 = b;\n        sum += fa_ltc_edge_vector(param, param_1);\n    }\n    else\n    {\n        if (_6845 != _6849)\n        {\n            vec3 _6884 = a + ((b - a) * (a.z / (a.z - b.z)));\n            _6884.z = 0.0;\n            if (_6845)\n            {\n                vec3 param_2 = a;\n                vec3 param_3 = _6884;\n                sum += fa_ltc_edge_vector(param_2, param_3);\n                leave = _6884;\n                seen.x = 1.0;\n            }\n            else\n            {\n                vec3 param_4 = _6884;\n                vec3 param_5 = b;\n                sum += fa_ltc_edge_vector(param_4, param_5);\n                enter = _6884;\n                seen.y = 1.0;\n            }\n        }\n    }\n}\n\nfloat fa_ltc_quad(vec4 abcd, vec3 p0, vec3 p1, vec3 p2, vec3 p3)\n{\n    vec3 _6933 = vec3((abcd.x * p0.x) + (abcd.y * p0.z), p0.y, (abcd.z * p0.x) + (abcd.w * p0.z));\n    vec3 _6959 = vec3((abcd.x * p1.x) + (abcd.y * p1.z), p1.y, (abcd.z * p1.x) + (abcd.w * p1.z));\n    vec3 _6985 = vec3((abcd.x * p2.x) + (abcd.y * p2.z), p2.y, (abcd.z * p2.x) + (abcd.w * p2.z));\n    vec3 _7011 = vec3((abcd.x * p3.x) + (abcd.y * p3.z), p3.y, (abcd.z * p3.x) + (abcd.w * p3.z));\n    vec3 sum = vec3(0.0);\n    vec3 leave = vec3(0.0);\n    vec3 enter = vec3(0.0);\n    vec3 param = _6933;\n    vec3 param_1 = _6959;\n    vec3 param_2 = vec3(0.0);\n    vec3 param_3 = vec3(0.0);\n    vec3 param_4 = vec3(0.0);\n    vec2 param_5 = vec2(0.0);\n    fa_ltc_clip_edge(param, param_1, param_2, param_3, param_4, param_5);\n    sum = param_2;\n    leave = param_3;\n    enter = param_4;\n    vec3 param_6 = _6959;\n    vec3 param_7 = _6985;\n    vec3 param_8 = param_2;\n    vec3 param_9 = param_3;\n    vec3 param_10 = param_4;\n    vec2 param_11 = param_5;\n    fa_ltc_clip_edge(param_6, param_7, param_8, param_9, param_10, param_11);\n    sum = param_8;\n    leave = param_9;\n    enter = param_10;\n    vec3 param_12 = _6985;\n    vec3 param_13 = _7011;\n    vec3 param_14 = param_8;\n    vec3 param_15 = param_9;\n    vec3 param_16 = param_10;\n    vec2 param_17 = param_11;\n    fa_ltc_clip_edge(param_12, param_13, param_14, param_15, param_16, param_17);\n    sum = param_14;\n    leave = param_15;\n    enter = param_16;\n    vec3 param_18 = _7011;\n    vec3 param_19 = _6933;\n    vec3 param_20 = param_14;\n    vec3 param_21 = param_15;\n    vec3 param_22 = param_16;\n    vec2 param_23 = param_17;\n    fa_ltc_clip_edge(param_18, param_19, param_20, param_21, param_22, param_23);\n    sum = param_20;\n    leave = param_21;\n    enter = param_22;\n    if ((param_23.x * param_23.y) > 0.5)\n    {\n        vec3 param_24 = leave;\n        vec3 param_25 = enter;\n        sum += fa_ltc_edge_vector(param_24, param_25);\n    }\n    return sum.z * 0.15915493667125701904296875;\n}\n\nvec2 fa_area_forms(vec4 m, float shape, vec3 pc, vec3 ex, vec3 ey)\n{\n    int _7179 = ((shape < 0.5) || (shape > 1.5)) ? 1 : 3;\n    vec2 sum = vec2(0.0);\n    int _7197;\n    for (int k = 0; k < (2 * _7179); k++)\n    {\n        bool _7194 = k >= _7179;\n        if (_7194)\n        {\n            _7197 = k - _7179;\n        }\n        else\n        {\n            _7197 = k;\n        }\n        vec3 p0 = (pc - ex) - ey;\n        vec3 p1 = (pc + ex) - ey;\n        vec3 p2 = (pc + ex) + ey;\n        vec3 p3 = (pc - ex) + ey;\n        if (_7179 == 3)\n        {\n            int param = 0;\n            vec3 param_1 = pc;\n            vec3 param_2 = ex;\n            vec3 param_3 = ey;\n            p0 = fa_oct_vertex(param, param_1, param_2, param_3);\n            int _7243 = 2 * _7197;\n            int param_4 = _7243 + 1;\n            vec3 param_5 = pc;\n            vec3 param_6 = ex;\n            vec3 param_7 = ey;\n            p1 = fa_oct_vertex(param_4, param_5, param_6, param_7);\n            int param_8 = _7243 + 2;\n            vec3 param_9 = pc;\n            vec3 param_10 = ex;\n            vec3 param_11 = ey;\n            p2 = fa_oct_vertex(param_8, param_9, param_10, param_11);\n            int param_12 = _7243 + 3;\n            vec3 param_13 = pc;\n            vec3 param_14 = ex;\n            vec3 param_15 = ey;\n            p3 = fa_oct_vertex(param_12, param_13, param_14, param_15);\n        }\n        bvec4 _7280 = bvec4(_7194);\n        vec4 param_16 = vec4(_7280.x ? m.x : vec4(1.0, 0.0, 0.0, 1.0).x, _7280.y ? m.y : vec4(1.0, 0.0, 0.0, 1.0).y, _7280.z ? m.z : vec4(1.0, 0.0, 0.0, 1.0).z, _7280.w ? m.w : vec4(1.0, 0.0, 0.0, 1.0).w);\n        vec3 param_17 = p0;\n        vec3 param_18 = p1;\n        vec3 param_19 = p2;\n        vec3 param_20 = p3;\n        float _7291 = fa_ltc_quad(param_16, param_17, param_18, param_19, param_20);\n        if (_7194)\n        {\n            vec2 _10088 = sum;\n            _10088.y = _10088.y + _7291;\n            sum = _10088;\n        }\n        else\n        {\n            vec2 _10091 = sum;\n            _10091.x = _10091.x + _7291;\n            sum = _10091;\n        }\n    }\n    return abs(sum);\n}\n\nvec3 fa_area_shade(int li, vec3 world_pos, vec3 n, vec3 v, vec3 diffuse_color, vec3 f0, float f90, float roughness, float ndv, float window)\n{\n    int param = li;\n    int _7315 = fa_light_base(param);\n    int param_1 = _7315;\n    int param_2 = _7315 + 1;\n    int param_3 = _7315 + 2;\n    int param_4 = _7315 + 4;\n    vec4 _7337 = fa_light_texel(param_4);\n    int param_5 = _7315 + 5;\n    vec4 _7342 = fa_light_texel(param_5);\n    int param_6 = _7315 + 6;\n    vec4 _7347 = fa_light_texel(param_6);\n    float _7348 = _7347.w;\n    vec3 _7353 = fa_light_texel(param_1).xyz - world_pos;\n    bool _7355 = _7348 < 1.5;\n    bool _7362;\n    if (_7355)\n    {\n        _7362 = dot(normalize(fa_light_texel(param_3).xyz), _7353) >= 0.0;\n    }\n    else\n    {\n        _7362 = _7355;\n    }\n    if (_7362)\n    {\n        return vec3(0.0);\n    }\n    bool _7371 = (_7348 > 0.5) && _7355;\n    float _7375 = _7371 ? 1.0539000034332275390625 : 1.0;\n    vec3 _7378 = _7337.xyz;\n    float _7380 = _7337.w;\n    vec3 _7386 = _7342.xyz;\n    float _7388 = _7342.w;\n    vec3 up = _7386 * (_7388 * _7375);\n    float _7394;\n    if (_7371)\n    {\n        _7394 = (3.1415927410125732421875 * _7380) * _7380;\n    }\n    else\n    {\n        _7394 = (4.0 * _7380) * _7388;\n    }\n    if (_7348 > 1.5)\n    {\n        vec3 _7420 = cross(_7378, -_7353);\n        vec3 perp = _7420;\n        float _7424 = dot(_7420, _7420);\n        vec3 _7427;\n        if (_7424 > 1.0000000133514319600180897396058e-10)\n        {\n            _7427 = perp * inversesqrt(_7424);\n        }\n        else\n        {\n            _7427 = _7386;\n        }\n        perp = _7427;\n        up = _7427 * _7388;\n    }\n    float _7448 = max(_7394, 9.9999999747524270787835121154785e-07);\n    vec3 param_7 = n;\n    vec3 param_8 = v;\n    vec3 _7458 = fa_ltc_tangent(param_7, param_8);\n    vec3 param_9 = _7458;\n    vec3 param_10 = n;\n    vec3 param_11 = _7353;\n    vec3 param_12 = _7458;\n    vec3 param_13 = n;\n    vec3 param_14 = _7378 * (_7380 * _7375);\n    vec3 param_15 = _7458;\n    vec3 param_16 = n;\n    vec3 param_17 = up;\n    float param_18 = roughness;\n    float param_19 = ndv;\n    vec2 _7489 = fa_ltc_uv(param_18, param_19) * 64.0;\n    vec2 param_20 = _7489;\n    vec2 param_21 = _7489 + vec2(64.0, 0.0);\n    vec4 _7499 = fa_atlas_fetch(param_21);\n    vec4 param_22 = fa_atlas_fetch(param_20);\n    float param_23 = _7348;\n    vec3 param_24 = fa_ltc_local(param_9, param_10, param_11);\n    vec3 param_25 = fa_ltc_local(param_12, param_13, param_14);\n    vec3 param_26 = fa_ltc_local(param_15, param_16, param_17);\n    vec2 _7511 = fa_area_forms(param_22, param_23, param_24, param_25, param_26);\n    return (((diffuse_color * _7511.x) + (((f0 * _7499.x) + ((vec3(f90) - f0) * _7499.y)) * _7511.y)) * fa_light_texel(param_2).xyz) * ((((3.1415927410125732421875 * dot(_7353, _7353)) + _7448) / _7448) * window);\n}\n\nvec3 fa_light_rgb(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 1;\n    return fa_light_texel(param_1).xyz;\n}\n\nfloat fa_d_charlie(float alpha, float ndh)\n{\n    float _5405 = 1.0 / alpha;\n    return ((2.0 + _5405) * pow(sqrt(max(1.0 - (ndh * ndh), 9.9999997473787516355514526367188e-05)), _5405)) * 0.15915493667125701904296875;\n}\n\nfloat fa_v_ashikhmin(float ndl, float ndv)\n{\n    return clamp(0.25 / max((ndl + ndv) - (ndl * ndv), 9.9999997473787516355514526367188e-05), 0.0, 1.0);\n}\n\nfloat fa_layers_coat(FaLayers L, vec3 l, vec3 h, float vdh)\n{\n    float _5440 = max(dot(L.nc, l), 0.0);\n    float _5446 = max(dot(L.nc, h), 0.0);\n    float _5455 = ((_5446 * _5446) * (L.coat_a2 - 1.0)) + 1.0;\n    return (((L.coat * (0.039999999105930328369140625 + (0.959999978542327880859375 * pow(clamp(1.0 - vdh, 0.0, 1.0), 5.0)))) * (((L.coat_a2 / ((3.1415927410125732421875 * _5455) * _5455)) * (0.5 / max(mix((2.0 * _5440) * L.coat_ndv, _5440 + L.coat_ndv, L.coat_alpha), 9.9999997473787516355514526367188e-05))) * 3.1415927410125732421875)) * step(9.9999997473787516355514526367188e-05, _5440)) * _5440;\n}\n\nvec3 fa_area_layers(FaLayers L, vec3 base, int li, vec3 n, vec3 v, vec3 l, float ndv, float window)\n{\n    float _7548;\n    if (L.sheen_on)\n    {\n        _7548 = L.sheen_scale;\n    }\n    else\n    {\n        _7548 = 1.0;\n    }\n    vec3 result = base * (L.keep * _7548);\n    vec3 _7561 = normalize(l + v);\n    int param = li;\n    vec3 _7572 = fa_light_rgb(param) * window;\n    if (L.sheen_on)\n    {\n        float _7581 = max(dot(n, l), 0.0);\n        float param_1 = L.sheen_alpha;\n        float param_2 = max(dot(n, _7561), 0.0);\n        float param_3 = _7581;\n        float param_4 = ndv;\n        result += ((L.sheen * _7572) * (((((fa_d_charlie(param_1, param_2) * fa_v_ashikhmin(param_3, param_4)) * 3.1415927410125732421875) * step(9.9999997473787516355514526367188e-05, _7581)) * _7581) * L.keep));\n    }\n    if (L.coat > 0.0)\n    {\n        FaLayers param_5 = L;\n        vec3 param_6 = l;\n        vec3 param_7 = _7561;\n        float param_8 = max(dot(v, _7561), 0.0);\n        result += (_7572 * fa_layers_coat(param_5, param_6, param_7, param_8));\n    }\n    return result;\n}\n\nfloat fa_d_ggx_aniso(float ndh, float tdh, float bdh, float at, float ab)\n{\n    float _5308 = tdh / at;\n    float _5312 = bdh / ab;\n    float _5324 = ((_5308 * _5308) + (_5312 * _5312)) + (ndh * ndh);\n    return 1.0 / ((((3.1415927410125732421875 * at) * ab) * _5324) * _5324);\n}\n\nfloat fa_lambda_ggx_aniso(float n, float t, float b, float at, float ab)\n{\n    return 0.5 * (sqrt(1.0 + (((((at * at) * t) * t) + (((ab * ab) * b) * b)) / max(n * n, 9.9999999392252902907785028219223e-09))) - 1.0);\n}\n\nfloat fa_v_ggx_aniso(float ndl, float ndv, float tdv, float bdv, float tdl, float bdl, float at, float ab)\n{\n    float param = ndv;\n    float param_1 = tdv;\n    float param_2 = bdv;\n    float param_3 = at;\n    float param_4 = ab;\n    float param_5 = ndl;\n    float param_6 = tdl;\n    float param_7 = bdl;\n    float param_8 = at;\n    float param_9 = ab;\n    return clamp(1.0 / ((4.0 * max(ndl * ndv, 9.9999997473787516355514526367188e-05)) * ((1.0 + fa_lambda_ggx_aniso(param, param_1, param_2, param_3, param_4)) + fa_lambda_ggx_aniso(param_5, param_6, param_7, param_8, param_9))), 0.0, 1.0);\n}\n\nvec3 fa_layers_light(FaLayers L, vec3 diffuse_color, vec3 f0, vec3 n, vec3 v, vec3 l, vec3 h, float ndl, float ndv, float ndh, float vdh, float alpha, float a2)\n{\n    float _5504 = step(9.9999997473787516355514526367188e-05, ndl);\n    float d_ggx;\n    float vis;\n    if (L.aniso != 0.0)\n    {\n        float param = ndh;\n        float param_1 = dot(L.t, h);\n        float param_2 = dot(L.b, h);\n        float param_3 = L.at;\n        float param_4 = L.ab;\n        d_ggx = fa_d_ggx_aniso(param, param_1, param_2, param_3, param_4);\n        float param_5 = ndl;\n        float param_6 = ndv;\n        float param_7 = dot(L.t, v);\n        float param_8 = dot(L.b, v);\n        float param_9 = dot(L.t, l);\n        float param_10 = dot(L.b, l);\n        float param_11 = L.at;\n        float param_12 = L.ab;\n        vis = fa_v_ggx_aniso(param_5, param_6, param_7, param_8, param_9, param_10, param_11, param_12);\n    }\n    else\n    {\n        float _5583 = ((ndh * ndh) * (a2 - 1.0)) + 1.0;\n        d_ggx = a2 / ((3.1415927410125732421875 * _5583) * _5583);\n        vis = 0.5 / max(mix((2.0 * ndl) * ndv, ndl + ndv, alpha), 9.9999997473787516355514526367188e-05);\n    }\n    vec3 base = diffuse_color + (((f0 + ((vec3(L.f90) - f0) * pow(clamp(1.0 - vdh, 0.0, 1.0), 5.0))) * ((d_ggx * vis) * 3.1415927410125732421875)) * _5504);\n    if (L.sheen_on)\n    {\n        float param_13 = L.sheen_alpha;\n        float param_14 = ndh;\n        float param_15 = ndl;\n        float param_16 = ndv;\n        base = (base * L.sheen_scale) + (L.sheen * (((fa_d_charlie(param_13, param_14) * fa_v_ashikhmin(param_15, param_16)) * 3.1415927410125732421875) * _5504));\n    }\n    vec3 result = base * (L.keep * ndl);\n    if (L.coat > 0.0)\n    {\n        FaLayers param_17 = L;\n        vec3 param_18 = l;\n        vec3 param_19 = h;\n        float param_20 = vdh;\n        result += vec3(fa_layers_coat(param_17, param_18, param_19, param_20));\n    }\n    return result;\n}\n\nvec2 fa_env_brdf(float rough, float ndv)\n{\n    vec4 _4707 = (vec4(-1.0, -0.0274999998509883880615234375, -0.572000026702880859375, 0.02199999988079071044921875) * rough) + vec4(1.0, 0.0425000004470348358154296875, 1.03999996185302734375, -0.039999999105930328369140625);\n    float _4710 = _4707.x;\n    return (vec2(-1.03999996185302734375, 1.03999996185302734375) * ((min(_4710 * _4710, exp2((-9.27999973297119140625) * ndv)) * _4710) + _4707.y)) + _4707.zw;\n}\n\nvec3 fa_probe_level(vec2 origin, float res, int lv, vec2 e)\n{\n    float _4018;\n    if (lv == 0)\n    {\n        _4018 = 0.0;\n    }\n    else\n    {\n        _4018 = res + 2.0;\n    }\n    float _4028;\n    if (lv == 0)\n    {\n        _4028 = 0.0;\n    }\n    else\n    {\n        _4028 = (res - (res / float(1 << max((lv - 1), 0)))) + (2.0 * float(lv - 1));\n    }\n    return textureLod(fa_probe_atlas_fa_env_smp, (((origin + vec2(_4018, _4028)) + vec2(1.0)) + (((e * 0.5) + vec2(0.5)) * (res / float(1 << lv)))) / fa_atlas_size(), 0.0).xyz;\n}\n\nvec3 fa_probe_radiance(vec2 origin, float res, vec3 d, float rough)\n{\n    float _4074;\n    if (res > 64.5)\n    {\n        _4074 = 5.0;\n    }\n    else\n    {\n        _4074 = (res > 32.5) ? 4.0 : 3.0;\n    }\n    float _4089 = clamp(rough, 0.0, 1.0) * (_4074 - 1.0);\n    int _4096 = int(min(floor(_4089), _4074 - 2.0));\n    float _4101 = _4089 - float(_4096);\n    vec3 param = d;\n    vec2 _4105 = fa_oct_encode(param);\n    vec2 param_1 = origin;\n    float param_2 = res;\n    int param_3 = _4096;\n    vec2 param_4 = _4105;\n    vec3 _4115 = fa_probe_level(param_1, param_2, param_3, param_4);\n    if (_4101 < 0.00200000009499490261077880859375)\n    {\n        return _4115;\n    }\n    vec2 param_5 = origin;\n    float param_6 = res;\n    int param_7 = _4096 + 1;\n    vec2 param_8 = _4105;\n    return mix(_4115, fa_probe_level(param_5, param_6, param_7, param_8), vec3(_4101));\n}\n\nvec3 fa_probe_box_dir(vec3 d, vec4 posw, vec4 bx, vec4 by, vec4 bz)\n{\n    if (posw.w < 0.5)\n    {\n        return d;\n    }\n    float _4186 = dot(bx.xyz, fa_world_pos) + bx.w;\n    float _4193 = dot(by.xyz, fa_world_pos) + by.w;\n    float _4200 = dot(bz.xyz, fa_world_pos) + bz.w;\n    float _4206 = dot(bx.xyz, d);\n    float _4210 = dot(by.xyz, d);\n    float _4214 = dot(bz.xyz, d);\n    float _4220;\n    if (_4206 > 9.9999999747524270787835121154785e-07)\n    {\n        _4220 = (1.0 - _4186) / _4206;\n    }\n    else\n    {\n        float _4234;\n        if (_4206 < (-9.9999999747524270787835121154785e-07))\n        {\n            _4234 = ((-1.0) - _4186) / _4206;\n        }\n        else\n        {\n            _4234 = 1000000015047466219876688855040.0;\n        }\n        _4220 = _4234;\n    }\n    float tx = _4220;\n    float _4251;\n    if (_4210 > 9.9999999747524270787835121154785e-07)\n    {\n        _4251 = (1.0 - _4193) / _4210;\n    }\n    else\n    {\n        float _4264;\n        if (_4210 < (-9.9999999747524270787835121154785e-07))\n        {\n            _4264 = ((-1.0) - _4193) / _4210;\n        }\n        else\n        {\n            _4264 = 1000000015047466219876688855040.0;\n        }\n        _4251 = _4264;\n    }\n    float ty = _4251;\n    float _4280;\n    if (_4214 > 9.9999999747524270787835121154785e-07)\n    {\n        _4280 = (1.0 - _4200) / _4214;\n    }\n    else\n    {\n        float _4293;\n        if (_4214 < (-9.9999999747524270787835121154785e-07))\n        {\n            _4293 = ((-1.0) - _4200) / _4214;\n        }\n        else\n        {\n            _4293 = 1000000015047466219876688855040.0;\n        }\n        _4280 = _4293;\n    }\n    float _4305 = tx;\n    float _4308 = (_4305 > 0.0) ? _4305 : 1000000015047466219876688855040.0;\n    tx = _4308;\n    float _4309 = ty;\n    float _4312 = (_4309 > 0.0) ? _4309 : 1000000015047466219876688855040.0;\n    ty = _4312;\n    float _4322 = min(_4308, min(_4312, (_4280 > 0.0) ? _4280 : 1000000015047466219876688855040.0));\n    if (_4322 > 100000001504746621987668885504.0)\n    {\n        return d;\n    }\n    vec3 _4338 = (fa_world_pos + (d * _4322)) - posw.xyz;\n    vec3 _4343;\n    if (dot(_4338, _4338) > 1.0000000133514319600180897396058e-10)\n    {\n        _4343 = normalize(_4338);\n    }\n    else\n    {\n        _4343 = d;\n    }\n    return _4343;\n}\n\nvec3 fa_probe_environment(vec4 tile, vec4 posw, vec4 bx, vec4 by, vec4 bz, inout vec3 d, float rough)\n{\n    vec3 param = d;\n    vec4 param_1 = posw;\n    vec4 param_2 = bx;\n    vec4 param_3 = by;\n    vec4 param_4 = bz;\n    d = fa_probe_box_dir(param, param_1, param_2, param_3, param_4);\n    vec2 param_5 = tile.xy;\n    float param_6 = tile.z;\n    vec3 param_7 = d;\n    float param_8 = rough;\n    return fa_probe_radiance(param_5, param_6, param_7, param_8);\n}\n\nvec3 fa_environment(vec3 d, float rough)\n{\n    float _4389 = (1.0 - fa_mesh_fs_params[42].w) - fa_mesh_fs_params[47].w;\n    vec3 outc = vec3(0.0);\n    if (_4389 > 0.0005000000237487256526947021484375)\n    {\n        vec3 base;\n        if (fa_mesh_fs_params[11].w > 0.5)\n        {\n            vec2 param = fa_mesh_fs_params[41].zw;\n            float param_1 = 128.0;\n            vec3 param_2 = d;\n            float param_3 = rough;\n            base = fa_probe_radiance(param, param_1, param_2, param_3);\n        }\n        else\n        {\n            float _4417 = rough * rough;\n            float _4448 = 0.60000002384185791015625 * _4417;\n            base = mix(mix(fa_mesh_fs_params[12].xyz * 0.550000011920928955078125, mix(fa_mesh_fs_params[12].xyz, fa_mesh_fs_params[11].xyz, vec3(pow(clamp(d.y * (1.0 - (0.699999988079071044921875 * _4417)), 0.0, 1.0), 0.550000011920928955078125))), vec3(smoothstep((-0.0500000007450580596923828125) - _4448, 0.0500000007450580596923828125 + _4448, d.y))), ((fa_mesh_fs_params[11].xyz + fa_mesh_fs_params[12].xyz) * 0.5) * 0.800000011920928955078125, vec3(_4417 * 0.60000002384185791015625));\n        }\n        outc = base * _4389;\n    }\n    if (fa_mesh_fs_params[42].w > 0.0)\n    {\n        vec4 param_4 = fa_mesh_fs_params[42];\n        vec4 param_5 = fa_mesh_fs_params[43];\n        vec4 param_6 = fa_mesh_fs_params[44];\n        vec4 param_7 = fa_mesh_fs_params[45];\n        vec4 param_8 = fa_mesh_fs_params[46];\n        vec3 param_9 = d;\n        float param_10 = rough;\n        vec3 _4507 = fa_probe_environment(param_4, param_5, param_6, param_7, param_8, param_9, param_10);\n        outc += (_4507 * fa_mesh_fs_params[42].w);\n    }\n    if (fa_mesh_fs_params[47].w > 0.0)\n    {\n        vec4 param_11 = fa_mesh_fs_params[47];\n        vec4 param_12 = fa_mesh_fs_params[48];\n        vec4 param_13 = fa_mesh_fs_params[49];\n        vec4 param_14 = fa_mesh_fs_params[50];\n        vec4 param_15 = fa_mesh_fs_params[51];\n        vec3 param_16 = d;\n        float param_17 = rough;\n        vec3 _4539 = fa_probe_environment(param_11, param_12, param_13, param_14, param_15, param_16, param_17);\n        outc += (_4539 * fa_mesh_fs_params[47].w);\n    }\n    return outc;\n}\n\nvec3 fa_layers_ibl(FaLayers L, vec3 n, vec3 v, vec3 f0, float roughness, float occlusion)\n{\n    vec3 rn = n;\n    if (L.aniso != 0.0)\n    {\n        vec3 _5185;\n        if (L.aniso >= 0.0)\n        {\n            _5185 = L.b;\n        }\n        else\n        {\n            _5185 = L.t;\n        }\n        rn = normalize(mix(n, cross(cross(_5185, v), _5185), vec3(abs(L.aniso) * smoothstep(0.0, 0.25, roughness))));\n    }\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05);\n    vec2 _5221 = fa_env_brdf(param, param_1);\n    vec3 param_2 = reflect(-v, rn);\n    float param_3 = roughness;\n    vec3 result = (fa_environment(param_2, param_3) * ((f0 * _5221.x) + (vec3(L.f90) * _5221.y))) * L.base_scale;\n    if (L.sheen_on)\n    {\n        vec3 param_4 = n;\n        float param_5 = L.sheen_rough;\n        result += ((L.sheen * (L.sheen_e * L.keep)) * fa_environment(param_4, param_5));\n    }\n    result *= occlusion;\n    if (L.coat > 0.0)\n    {\n        float param_6 = L.coat_rough;\n        float param_7 = L.coat_ndv;\n        vec2 _5279 = fa_env_brdf(param_6, param_7);\n        vec3 param_8 = reflect(-v, L.nc);\n        float param_9 = L.coat_rough;\n        result += (fa_environment(param_8, param_9) * (L.coat * ((0.039999999105930328369140625 * _5279.x) + _5279.y)));\n    }\n    return result;\n}\n\nvec3 fa_sky_reflection(vec3 n, vec3 v, vec3 f0, float roughness)\n{\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05);\n    vec2 _4749 = fa_env_brdf(param, param_1);\n    vec3 param_2 = reflect(-v, n);\n    float param_3 = roughness;\n    return fa_environment(param_2, param_3) * ((f0 * _4749.x) + vec3(_4749.y));\n}\n\nvec2 fa_xm_size(int k)\n{\n    return max(floor(fa_mesh_fs_params[24].zw / vec2(float(1 << k))), vec2(1.0));\n}\n\nvec2 fa_xm_origin(int k)\n{\n    if (k == 0)\n    {\n        return vec2(0.0);\n    }\n    float y = 0.0;\n    for (int j = 1; j < k; j++)\n    {\n        int param = j;\n        y += fa_xm_size(param).y;\n    }\n    return vec2(fa_mesh_fs_params[24].z, y);\n}\n\nvec3 fa_xm_texel(vec2 size, vec2 origin, vec2 p)\n{\n    return texelFetch(fa_screen_tex_fa_shadow_smp, ivec2(origin + clamp(p, vec2(0.0), size - vec2(1.0))), 0).xyz;\n}\n\nvec3 fa_xm_level(int k, vec2 uv)\n{\n    int param = k;\n    vec2 _5981 = fa_xm_size(param);\n    int param_1 = k;\n    vec2 _5985 = fa_xm_origin(param_1);\n    vec2 _5991 = (uv * _5981) - vec2(0.5);\n    vec2 _5994 = fract(_5991);\n    vec2 _5997 = floor(_5991);\n    vec2 param_2 = _5981;\n    vec2 param_3 = _5985;\n    vec2 param_4 = _5997;\n    vec2 param_5 = _5981;\n    vec2 param_6 = _5985;\n    vec2 param_7 = _5997 + vec2(1.0, 0.0);\n    vec2 param_8 = _5981;\n    vec2 param_9 = _5985;\n    vec2 param_10 = _5997 + vec2(0.0, 1.0);\n    vec2 param_11 = _5981;\n    vec2 param_12 = _5985;\n    vec2 param_13 = _5997 + vec2(1.0);\n    vec3 _6039 = vec3(_5994.x);\n    return mix(mix(fa_xm_texel(param_2, param_3, param_4), fa_xm_texel(param_5, param_6, param_7), _6039), mix(fa_xm_texel(param_8, param_9, param_10), fa_xm_texel(param_11, param_12, param_13), _6039), vec3(_5994.y));\n}\n\nvec3 fa_xm_sample(vec2 uv, float lod)\n{\n    float _6058 = max(fa_mesh_fs_params[31].w - 1.0, 0.0);\n    float _6062 = clamp(lod, 0.0, _6058);\n    int _6066 = int(floor(_6062));\n    int param = _6066;\n    vec2 param_1 = uv;\n    vec3 c = fa_xm_level(param, param_1);\n    float _6076 = float(_6066);\n    float _6077 = _6062 - _6076;\n    bool _6079 = _6077 > 0.001000000047497451305389404296875;\n    bool _6086;\n    if (_6079)\n    {\n        _6086 = _6076 < _6058;\n    }\n    else\n    {\n        _6086 = _6079;\n    }\n    if (_6086)\n    {\n        int param_2 = _6066 + 1;\n        vec2 param_3 = uv;\n        c = mix(c, fa_xm_level(param_2, param_3), vec3(_6077));\n    }\n    return c;\n}\n\nvec3 fa_transmitted(Surface s, vec3 n, vec3 v, float roughness, vec3 f0, float f90, float keep, float tr, inout float blend)\n{\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05);\n    vec2 _6112 = fa_env_brdf(param, param_1);\n    vec3 _6136 = ((vec3(1.0) - clamp((f0 * _6112.x) + (vec3(f90) * _6112.y), vec3(0.0), vec3(1.0))) * s.albedo) * (tr * keep);\n    vec3 through = _6136;\n    float _6142 = max(s.thickness, 0.0);\n    bool _6147 = _6142 > 0.0;\n    if ((s.attenuation_distance > 0.0) && _6147)\n    {\n        through *= exp((-((-log(clamp(s.attenuation_color, vec3(9.9999997473787516355514526367188e-05), vec3(1.0)))) / vec3(s.attenuation_distance))) * _6142);\n    }\n    bool _6172 = fa_mesh_fs_params[30].w > 1.5;\n    bool _6178;\n    if (_6172)\n    {\n        _6178 = fa_mesh_fs_params[30].w < 2.5;\n    }\n    else\n    {\n        _6178 = _6172;\n    }\n    bool _6185;\n    if (!_6178)\n    {\n        _6185 = fa_mesh_fs_params[30].w < 0.5;\n    }\n    else\n    {\n        _6185 = _6178;\n    }\n    if (_6185)\n    {\n        blend = clamp(dot(through, vec3(0.3333333432674407958984375)), 0.0, 0.980000019073486328125);\n        return vec3(0.0);\n    }\n    vec4 _6200 = vec4(fa_world_pos, 1.0);\n    float _6205 = dot(fa_mesh_fs_params[28], _6200);\n    vec2 uv0 = vec2(0.5);\n    if (_6205 > 9.9999997473787516355514526367188e-05)\n    {\n        vec2 _6223 = vec2(dot(fa_mesh_fs_params[26], _6200), dot(fa_mesh_fs_params[27], _6200)) / vec2(_6205);\n        float _6231;\n        if (fa_mesh_fs_params[24].y > 0.5)\n        {\n            _6231 = (_6223.y * 0.5) + 0.5;\n        }\n        else\n        {\n            _6231 = 0.5 - (_6223.y * 0.5);\n        }\n        uv0 = vec2((_6223.x * 0.5) + 0.5, _6231);\n    }\n    if (fa_mesh_fs_params[30].w > 2.5)\n    {\n        int param_2 = 0;\n        vec2 _6252 = fa_xm_size(param_2);\n        vec2 _6260 = floor(clamp(uv0, vec2(0.0), vec2(0.99989998340606689453125)) * _6252);\n        if (texelFetch(fa_screen_tex_fa_shadow_smp, ivec2(_6260), 0).w > 0.5)\n        {\n            int _6280 = int(floor((clamp(roughness, 0.0, 1.0) * 2.0) + 0.5));\n            vec3 acc = vec3(0.0);\n            float cnt = 0.0;\n            for (int dy = -2; dy <= 2; dy++)\n            {\n                for (int dx = -2; dx <= 2; dx++)\n                {\n                    bool _6303 = abs(dx) > _6280;\n                    bool _6311;\n                    if (!_6303)\n                    {\n                        _6311 = abs(dy) > _6280;\n                    }\n                    else\n                    {\n                        _6311 = _6303;\n                    }\n                    if (_6311)\n                    {\n                        continue;\n                    }\n                    vec4 _6332 = texelFetch(fa_screen_tex_fa_shadow_smp, ivec2(clamp(_6260 + vec2(float(dx), float(dy)), vec2(0.0), _6252 - vec2(1.0))), 0);\n                    if (_6332.w > 0.5)\n                    {\n                        acc += _6332.xyz;\n                        cnt += 1.0;\n                    }\n                }\n            }\n            return _6136 * (acc / vec3(max(cnt, 1.0)));\n        }\n    }\n    vec2 uv = uv0;\n    if (_6147)\n    {\n        vec4 _6380 = vec4(fa_world_pos + (refract(-v, n, 1.0 / max(s.ior, 1.0)) * _6142), 1.0);\n        float _6385 = dot(fa_mesh_fs_params[28], _6380);\n        uv = vec2(0.5);\n        if (_6385 > 9.9999997473787516355514526367188e-05)\n        {\n            vec2 _6402 = vec2(dot(fa_mesh_fs_params[26], _6380), dot(fa_mesh_fs_params[27], _6380)) / vec2(_6385);\n            float _6410;\n            if (fa_mesh_fs_params[24].y > 0.5)\n            {\n                _6410 = (_6402.y * 0.5) + 0.5;\n            }\n            else\n            {\n                _6410 = 0.5 - (_6402.y * 0.5);\n            }\n            uv = vec2((_6402.x * 0.5) + 0.5, _6410);\n        }\n    }\n    vec2 param_3 = clamp(uv, vec2(0.0), vec2(1.0));\n    float param_4 = (clamp(roughness, 0.0, 1.0) * clamp((2.0 * s.ior) - 2.0, 0.0, 1.0)) * max(fa_mesh_fs_params[31].w - 1.0, 0.0);\n    return through * fa_xm_sample(param_3, param_4);\n}\n\nvec3 fa_shadow_debug(vec3 color, vec3 world)\n{\n    if (fa_shadows[27].w < 0.5)\n    {\n        return color;\n    }\n    int _3314 = int(fa_shadows[25].x + 0.5);\n    float _3324 = dot(world - fa_shadows[27].xyz, fa_shadows[28].xyz);\n    vec3 tint = vec3(0.3499999940395355224609375);\n    bool _3329 = _3314 > 0;\n    bool _3338;\n    if (_3329)\n    {\n        int param = _3314 - 1;\n        _3338 = _3324 <= fa_shadow_split_at(param);\n    }\n    else\n    {\n        _3338 = _3329;\n    }\n    if (_3338)\n    {\n        tint = vec3(1.0, 0.1500000059604644775390625, 0.100000001490116119384765625);\n        bool _3344 = _3314 > 1;\n        bool _3351;\n        if (_3344)\n        {\n            _3351 = _3324 > fa_shadows[24].x;\n        }\n        else\n        {\n            _3351 = _3344;\n        }\n        if (_3351)\n        {\n            tint = vec3(0.100000001490116119384765625, 0.89999997615814208984375, 0.20000000298023223876953125);\n        }\n        bool _3357 = _3314 > 2;\n        bool _3364;\n        if (_3357)\n        {\n            _3364 = _3324 > fa_shadows[24].y;\n        }\n        else\n        {\n            _3364 = _3357;\n        }\n        if (_3364)\n        {\n            tint = vec3(0.1500000059604644775390625, 0.300000011920928955078125, 1.0);\n        }\n        bool _3370 = _3314 > 3;\n        bool _3377;\n        if (_3370)\n        {\n            _3377 = _3324 > fa_shadows[24].z;\n        }\n        else\n        {\n            _3377 = _3370;\n        }\n        if (_3377)\n        {\n            tint = vec3(1.0, 0.89999997615814208984375, 0.100000001490116119384765625);\n        }\n    }\n    return mix(color, tint, vec3(0.550000011920928955078125));\n}\n\nvoid main()\n{\n    fa_rt_slope = 0.0;\n    fa_inst_load();\n    vec3 _9494 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _9494 = -_9494;\n    }\n    vec3 _8780 = normalize(fa_mesh_fs_params[0].xyz - fa_world_pos);\n    vec3 param = fa_world_pos;\n    fa_cluster_begin(param);\n    SurfaceInput param_1 = SurfaceInput(fa_world_pos, _9494, fa_world_tangent, fa_uv, fa_vertex_color, _8780, gl_FrontFacing);\n    Surface _8788 = fa_standard_surface(param_1);\n    vec3 _9525 = _8788.albedo;\n    float _9526 = _8788.alpha;\n    vec3 _9527 = _8788.normal;\n    float _9528 = _8788.metallic;\n    float _9529 = _8788.roughness;\n    float _9530 = _8788.occlusion;\n    vec3 _9531 = _8788.emission;\n    float _9532 = _8788.clearcoat;\n    float _9533 = _8788.clearcoat_roughness;\n    vec3 _9534 = _8788.sheen_color;\n    float _9535 = _8788.sheen_roughness;\n    float _9536 = _8788.anisotropy;\n    float _9537 = _8788.anisotropy_rotation;\n    float _9538 = _8788.specular;\n    float _9539 = _8788.ior;\n    vec3 _9540 = _8788.specular_color;\n    float _9541 = _8788.transmission;\n    float _9542 = _8788.thickness;\n    vec3 _9543 = _8788.attenuation_color;\n    float _9544 = _8788.attenuation_distance;\n    SurfaceInput param_2 = SurfaceInput(fa_world_pos, _9494, fa_world_tangent, fa_uv, fa_vertex_color, _8780, gl_FrontFacing);\n    Surface param_3 = _8788;\n    surface(param_2, param_3);\n    _9525 = param_3.albedo;\n    _9526 = param_3.alpha;\n    _9527 = param_3.normal;\n    _9528 = param_3.metallic;\n    _9529 = param_3.roughness;\n    _9530 = param_3.occlusion;\n    _9531 = param_3.emission;\n    _9532 = param_3.clearcoat;\n    _9533 = param_3.clearcoat_roughness;\n    _9534 = param_3.sheen_color;\n    _9535 = param_3.sheen_roughness;\n    _9536 = param_3.anisotropy;\n    _9537 = param_3.anisotropy_rotation;\n    _9538 = param_3.specular;\n    _9539 = param_3.ior;\n    _9540 = param_3.specular_color;\n    _9541 = param_3.transmission;\n    _9542 = param_3.thickness;\n    _9543 = param_3.attenuation_color;\n    _9544 = param_3.attenuation_distance;\n    vec3 param_4 = fa_world_pos;\n    vec3 param_5 = _9494;\n    vec3 param_6 = param_3.albedo;\n    vec3 param_7 = param_3.normal;\n    fa_apply_decals(param_4, param_5, param_6, param_7);\n    _9525 = param_6;\n    _9527 = param_7;\n    if (_9526 < fa_material[0].x)\n    {\n        discard;\n    }\n    fa_lod_dither();\n    float fa_tr_blend = 0.0;\n    vec3 result;\n    if (fa_mesh_fs_params[3].w > 0.5)\n    {\n        result = _9525;\n    }\n    else\n    {\n        vec3 _8840 = normalize(_9527);\n        float _8847 = clamp(_9528, 0.0, 1.0);\n        float _8851 = clamp(_9529, 0.0500000007450580596923828125, 1.0);\n        float _8855 = _8851 * _8851;\n        float _8859 = _8855 * _8855;\n        float _8864 = max(dot(_8840, _8780), 9.9999997473787516355514526367188e-05);\n        float _8870 = 1.0 - _8847;\n        float _8871 = clamp(_9541, 0.0, 1.0) * _8870;\n        vec3 _8880 = (_9525 * _8870) * (1.0 - _8871);\n        vec3 _8887 = mix(vec3(0.039999999105930328369140625), _9525, vec3(_8847));\n        vec3 f0 = _8887;\n        SurfaceInput param_8 = SurfaceInput(fa_world_pos, _9494, fa_world_tangent, fa_uv, fa_vertex_color, _8780, gl_FrontFacing);\n        Surface param_9 = Surface(_9525, _9526, _9527, _9528, _9529, _9530, _9531, _9532, _9533, _9534, _9535, _9536, _9537, _9538, _9539, _9540, _9541, _9542, _9543, _9544);\n        vec3 param_10 = _8840;\n        vec3 param_11 = _8780;\n        float param_12 = _8847;\n        float param_13 = _8851;\n        vec3 param_14 = _8887;\n        FaLayers _8903 = fa_layers_setup(param_8, param_9, param_10, param_11, param_12, param_13, param_14);\n        f0 = param_14;\n        vec3 param_15 = _8840;\n        vec3 lit = (fa_indirect_diffuse(param_15) * _8880) * _9530;\n        if (_8903.on)\n        {\n            lit *= _8903.base_scale;\n        }\n        int _8925 = fa_cl_ndir + fa_cl_local;\n        float _8990;\n        for (int ln = 0; ln < _8925; ln++)\n        {\n            int param_16 = ln;\n            int _8938 = fa_cl_light(param_16);\n            int param_17 = _8938;\n            if (fa_baked_keep(param_17) <= 0.0)\n            {\n                continue;\n            }\n            int param_18 = _8938;\n            vec3 param_19 = fa_world_pos;\n            vec3 param_20 = _9494;\n            LightSample _8954 = fa_light_shadowed(param_18, param_19, param_20);\n            float _8962 = max(dot(_8840, _8954.direction), 0.0);\n            float _8968 = _8954.attenuation * _8954.shadow;\n            vec3 _8973 = normalize(_8954.direction + _8780);\n            float _8978 = max(dot(_8840, _8973), 0.0);\n            float _8983 = max(dot(_8780, _8973), 0.0);\n            if (fa_light_is_area)\n            {\n                if (_8903.on)\n                {\n                    _8990 = _8903.f90;\n                }\n                else\n                {\n                    _8990 = 1.0;\n                }\n                int param_21 = _8938;\n                vec3 param_22 = fa_world_pos;\n                vec3 param_23 = _8840;\n                vec3 param_24 = _8780;\n                vec3 param_25 = _8880;\n                vec3 param_26 = f0;\n                float param_27 = _8990;\n                float param_28 = _8851;\n                float param_29 = _8864;\n                float param_30 = _8968;\n                vec3 area = fa_area_shade(param_21, param_22, param_23, param_24, param_25, param_26, param_27, param_28, param_29, param_30);\n                if (_8903.on)\n                {\n                    FaLayers param_31 = _8903;\n                    vec3 param_32 = area;\n                    int param_33 = _8938;\n                    vec3 param_34 = _8840;\n                    vec3 param_35 = _8780;\n                    vec3 param_36 = _8954.direction;\n                    float param_37 = _8864;\n                    float param_38 = _8968;\n                    area = fa_area_layers(param_31, param_32, param_33, param_34, param_35, param_36, param_37, param_38);\n                }\n                lit += area;\n            }\n            else\n            {\n                if (_8903.on)\n                {\n                    FaLayers param_39 = _8903;\n                    vec3 param_40 = _8880;\n                    vec3 param_41 = f0;\n                    vec3 param_42 = _8840;\n                    vec3 param_43 = _8780;\n                    vec3 param_44 = _8954.direction;\n                    vec3 param_45 = _8973;\n                    float param_46 = _8962;\n                    float param_47 = _8864;\n                    float param_48 = _8978;\n                    float param_49 = _8983;\n                    float param_50 = _8855;\n                    float param_51 = _8859;\n                    int param_52 = _8938;\n                    lit += (fa_layers_light(param_39, param_40, param_41, param_42, param_43, param_44, param_45, param_46, param_47, param_48, param_49, param_50, param_51) * ((fa_light_rgb(param_52) * fa_light_tint) * _8968));\n                }\n                else\n                {\n                    float _9092 = ((_8978 * _8978) * (_8859 - 1.0)) + 1.0;\n                    int param_53 = _8938;\n                    lit += (((_8880 + (((f0 + ((vec3(1.0) - f0) * pow(1.0 - _8983, 5.0))) * (((_8859 / ((3.1415927410125732421875 * _9092) * _9092)) * (0.5 / max(mix((2.0 * _8962) * _8864, _8962 + _8864, _8855), 9.9999997473787516355514526367188e-05))) * 3.1415927410125732421875)) * step(9.9999997473787516355514526367188e-05, _8962))) * (fa_light_rgb(param_53) * fa_light_tint)) * (_8962 * _8968));\n                }\n            }\n        }\n        if (_8903.on)\n        {\n            FaLayers param_54 = _8903;\n            vec3 param_55 = _8840;\n            vec3 param_56 = _8780;\n            vec3 param_57 = f0;\n            float param_58 = _8851;\n            float param_59 = _9530;\n            lit += fa_layers_ibl(param_54, param_55, param_56, param_57, param_58, param_59);\n        }\n        else\n        {\n            vec3 param_60 = _8840;\n            vec3 param_61 = _8780;\n            vec3 param_62 = f0;\n            float param_63 = _8851;\n            lit += (fa_sky_reflection(param_60, param_61, param_62, param_63) * _9530);\n        }\n        if (_8871 > 0.0)\n        {\n            float _9190;\n            if (_8903.on)\n            {\n                _9190 = _8903.f90;\n            }\n            else\n            {\n                _9190 = 1.0;\n            }\n            float _9198;\n            if (_8903.on)\n            {\n                _9198 = _8903.base_scale;\n            }\n            else\n            {\n                _9198 = 1.0;\n            }\n            Surface param_64 = Surface(_9525, _9526, _9527, _9528, _9529, _9530, _9531, _9532, _9533, _9534, _9535, _9536, _9537, _9538, _9539, _9540, _9541, _9542, _9543, _9544);\n            vec3 param_65 = _8840;\n            vec3 param_66 = _8780;\n            float param_67 = _8851;\n            vec3 param_68 = f0;\n            float param_69 = _9190;\n            float param_70 = _9198;\n            float param_71 = _8871;\n            float param_72 = fa_tr_blend;\n            vec3 _9222 = fa_transmitted(param_64, param_65, param_66, param_67, param_68, param_69, param_70, param_71, param_72);\n            fa_tr_blend = param_72;\n            lit += _9222;\n        }\n        result = lit;\n    }\n    vec3 _9229 = result;\n    vec3 _9230 = _9229 + _9531;\n    result = _9230;\n    vec3 param_73 = _9230;\n    vec3 param_74 = fa_world_pos;\n    result = fa_shadow_debug(param_73, param_74);\n    bool _9239 = fa_mesh_fs_params[7].w > 0.0;\n    bool _9246;\n    if (!_9239)\n    {\n        _9246 = fa_mesh_fs_params[8].y > 0.0;\n    }\n    else\n    {\n        _9246 = _9239;\n    }\n    if (_9246)\n    {\n        vec3 _9255 = fa_world_pos - fa_mesh_fs_params[0].xyz;\n        float _9261 = dot(_9255, fa_mesh_fs_params[9].xyz);\n        bool _9265 = fa_mesh_fs_params[9].w > 0.5;\n        float _9266;\n        if (_9265)\n        {\n            _9266 = _9261;\n        }\n        else\n        {\n            _9266 = length(_9255);\n        }\n        float _9278 = _9266 - fa_mesh_fs_params[8].x;\n        if (_9278 > 0.0)\n        {\n            float _9287 = fa_mesh_fs_params[7].w * _9278;\n            float tau = _9287 * _9287;\n            if (fa_mesh_fs_params[8].y > 0.0)\n            {\n                float _9303;\n                if (_9265)\n                {\n                    _9303 = fa_world_pos.y - (fa_mesh_fs_params[9].y * _9261);\n                }\n                else\n                {\n                    _9303 = fa_mesh_fs_params[0].y;\n                }\n                float _9324 = mix(_9303, fa_world_pos.y, clamp(fa_mesh_fs_params[8].x / _9266, 0.0, 1.0));\n                float _9328 = fa_world_pos.y - _9324;\n                float _9333 = _9324 - fa_mesh_fs_params[8].z;\n                float _9338 = fa_world_pos.y - fa_mesh_fs_params[8].z;\n                bool _9341 = _9333 <= 0.0;\n                bool _9342 = !_9341;\n                bool _9348;\n                if (_9342)\n                {\n                    _9348 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _9348 = _9341;\n                }\n                float _9349;\n                if (_9348)\n                {\n                    _9349 = fa_mesh_fs_params[8].y;\n                }\n                else\n                {\n                    _9349 = fa_mesh_fs_params[8].y * exp(-min(fa_mesh_fs_params[8].w * _9333, 80.0));\n                }\n                bool _9376;\n                if (_9342)\n                {\n                    _9376 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _9376 = _9341;\n                }\n                float _9377;\n                if (_9376)\n                {\n                    _9377 = fa_mesh_fs_params[8].y * _9333;\n                }\n                else\n                {\n                    _9377 = (fa_mesh_fs_params[8].y * (1.0 - exp(-min(fa_mesh_fs_params[8].w * _9333, 80.0)))) / fa_mesh_fs_params[8].w;\n                }\n                bool _9402 = _9338 <= 0.0;\n                bool _9409;\n                if (!_9402)\n                {\n                    _9409 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _9409 = _9402;\n                }\n                float _9410;\n                if (_9409)\n                {\n                    _9410 = fa_mesh_fs_params[8].y * _9338;\n                }\n                else\n                {\n                    _9410 = (fa_mesh_fs_params[8].y * (1.0 - exp(-min(fa_mesh_fs_params[8].w * _9338, 80.0)))) / fa_mesh_fs_params[8].w;\n                }\n                float _9437;\n                if (abs(_9328) < 0.001000000047497451305389404296875)\n                {\n                    _9437 = _9349;\n                }\n                else\n                {\n                    _9437 = (_9410 - _9377) / _9328;\n                }\n                tau += (_9278 * max(_9437, 0.0));\n            }\n            result = mix(result, fa_mesh_fs_params[7].xyz, vec3(clamp(1.0 - exp(-clamp(tau, 0.0, 80.0)), 0.0, 1.0)));\n        }\n    }\n    if (fa_tr_blend > 0.0)\n    {\n        float _9473 = 1.0 - fa_tr_blend;\n        result /= vec3(_9473);\n        _9526 *= _9473;\n    }\n    fa_frag_color = vec4(result, _9526);\n}\n\n",
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
            "inst_name": "_612",
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
            "inst_name": "_2355",
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
            "inst_name": "_8816",
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
