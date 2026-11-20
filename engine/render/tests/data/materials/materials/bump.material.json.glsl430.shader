{
  "format": "factoria.shader/1",
  "engine": "0.32.0",
  "template": "c074417cc32d65946d9fd800b8e1855ea5fc09e97e16038fe5558a6cb62d2704",
  "slang": "glsl430",
  "params": [
    "lift"
  ],
  "textures": [
    "height"
  ],
  "programs": {
    "mesh": {
      "vs": "#version 430\n\nstruct VertexData\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 color;\n    vec3 object_pos;\n};\n\nuniform vec4 fa_material_vs[1];\nuniform vec4 fa_mesh_vs_params[11];\nlayout(binding = 0) uniform sampler2D fa_vs_height_fa_vs_height_smp;\n\nlayout(location = 0) out vec3 fa_world_pos;\nlayout(location = 1) out vec3 fa_world_normal;\nlayout(location = 2) out vec4 fa_world_tangent;\nlayout(location = 3) out vec2 fa_uv;\nlayout(location = 4) out vec4 fa_vertex_color;\nlayout(location = 5) in vec4 fa_inst_m0;\nlayout(location = 6) in vec4 fa_inst_m1;\nlayout(location = 7) in vec4 fa_inst_m2;\nlayout(location = 8) in vec4 fa_inst_m3;\nlayout(location = 0) in vec3 fa_position;\nlayout(location = 1) in vec3 fa_normal;\nlayout(location = 3) in vec4 fa_tangent;\nlayout(location = 2) in vec2 fa_texcoord0;\nlayout(location = 4) in vec4 fa_color;\nlayout(location = 5) out vec3 fa_lm;\n\nvoid fa_inst_begin()\n{\n}\n\nVertexData fa_vertex_data(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    vec3 _103 = cross(model[1].xyz, model[2].xyz);\n    float _108 = (dot(model[0].xyz, _103) < 0.0) ? (-1.0) : 1.0;\n    return VertexData((model * vec4(position, 1.0)).xyz, (((_103 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _108, vec4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _108), texcoord0 * fa_mesh_vs_params[8].xy, color, position);\n}\n\nvoid vertex(inout VertexData v)\n{\n    v.world_pos.y += (textureLod(fa_vs_height_fa_vs_height_smp, v.uv, 0.0).x * fa_material_vs[0].x);\n}\n\nvoid fa_shade_vertex(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    mat4 param = model;\n    vec3 param_1 = position;\n    vec3 param_2 = normal;\n    vec4 param_3 = tangent;\n    vec2 param_4 = texcoord0;\n    vec4 param_5 = color;\n    VertexData param_6 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    vertex(param_6);\n    fa_world_pos = param_6.world_pos;\n    fa_world_normal = param_6.world_normal;\n    fa_world_tangent = param_6.world_tangent;\n    fa_uv = param_6.uv;\n    fa_vertex_color = param_6.color;\n    gl_Position = mat4(fa_mesh_vs_params[0], fa_mesh_vs_params[1], fa_mesh_vs_params[2], fa_mesh_vs_params[3]) * vec4(param_6.world_pos, 1.0);\n}\n\nvoid main()\n{\n    fa_inst_begin();\n    mat4 param = mat4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3);\n    vec3 param_1 = fa_position;\n    vec3 param_2 = fa_normal;\n    vec4 param_3 = fa_tangent;\n    vec2 param_4 = fa_texcoord0;\n    vec4 param_5 = fa_color;\n    fa_shade_vertex(param, param_1, param_2, param_3, param_4, param_5);\n    fa_lm = vec3(0.0);\n}\n\n",
      "fs": "#version 430\n\nstruct SurfaceInput\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 vertex_color;\n    vec3 view_dir;\n    bool front_facing;\n};\n\nstruct LightSample\n{\n    vec3 direction;\n    vec3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct Surface\n{\n    vec3 albedo;\n    float alpha;\n    vec3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    vec3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    vec3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    vec3 specular_color;\n    float transmission;\n    float thickness;\n    vec3 attenuation_color;\n    float attenuation_distance;\n};\n\nstruct FaLayers\n{\n    bool on;\n    float f90;\n    float keep;\n    float base_scale;\n    float coat;\n    float coat_rough;\n    float coat_alpha;\n    float coat_a2;\n    vec3 nc;\n    float coat_ndv;\n    bool sheen_on;\n    vec3 sheen;\n    float sheen_rough;\n    float sheen_alpha;\n    float sheen_scale;\n    float sheen_e;\n    float aniso;\n    vec3 t;\n    vec3 b;\n    float at;\n    float ab;\n};\n\nconst float _4320[63] = float[](1.0, 1.0, 1.0, 0.4790000021457672119140625, 0.11699999868869781494140625, 0.01200000010430812835693359375, 0.0, 0.0, 0.0, 1.0, 1.0, 1.0, 0.578000009059906005859375, 0.19300000369548797607421875, 0.0350000001490116119384765625, 0.0030000000260770320892333984375, 0.0, 0.0, 1.0, 1.0, 1.0, 0.6740000247955322265625, 0.3459999859333038330078125, 0.1319999992847442626953125, 0.032999999821186065673828125, 0.0040000001899898052215576171875, 0.0, 0.971000015735626220703125, 0.954999983310699462890625, 0.828999996185302734375, 0.63999998569488525390625, 0.42599999904632568359375, 0.24500000476837158203125, 0.115000002086162567138671875, 0.037000000476837158203125, 0.0030000000260770320892333984375, 0.7469999790191650390625, 0.737999975681304931640625, 0.670000016689300537109375, 0.563000023365020751953125, 0.4309999942779541015625, 0.3039999902248382568359375, 0.1940000057220458984375, 0.1019999980926513671875, 0.0309999994933605194091796875, 0.614000022411346435546875, 0.609000027179718017578125, 0.566999971866607666015625, 0.499000012874603271484375, 0.412000000476837158203125, 0.32400000095367431640625, 0.240999996662139892578125, 0.162000000476837158203125, 0.087999999523162841796875, 0.538999974727630615234375, 0.535000026226043701171875, 0.505999982357025146484375, 0.4569999873638153076171875, 0.393999993801116943359375, 0.328999996185302734375, 0.2660000026226043701171875, 0.203999996185302734375, 0.14200000464916229248046875);\n\nuniform vec4 fa_mesh_fs_params[52];\nuniform vec4 fa_shadows[30];\nlayout(binding = 0) uniform sampler2D fa_light_tex_fa_shadow_smp;\nlayout(binding = 1) uniform sampler2D fa_tex_fa_smp;\nlayout(binding = 2) uniform sampler2D fa_normal_tex_fa_smp;\nlayout(binding = 3) uniform sampler2D fa_mr_tex_fa_smp;\nlayout(binding = 4) uniform sampler2D fa_occlusion_tex_fa_smp;\nlayout(binding = 5) uniform sampler2D fa_emissive_tex_fa_smp;\nlayout(binding = 6) uniform sampler2D height_height_smp;\nlayout(binding = 7) uniform sampler2D fa_decal_tex_fa_env_smp;\nlayout(binding = 8) uniform sampler2D fa_lightmap_fa_env_smp;\nlayout(binding = 9) uniform sampler2D fa_probe_atlas_fa_env_smp;\nlayout(binding = 10) uniform sampler2D fa_light_atlas_fa_env_smp;\nlayout(binding = 11) uniform sampler2D fa_shadow_tex_fa_shadow_smp;\nlayout(binding = 12) uniform sampler2D fa_screen_tex_fa_shadow_smp;\n\nlayout(location = 0) in vec3 fa_world_pos;\nlayout(location = 5) in vec3 fa_lm;\nlayout(location = 1) in vec3 fa_world_normal;\nlayout(location = 2) in vec4 fa_world_tangent;\nlayout(location = 3) in vec2 fa_uv;\nlayout(location = 4) in vec4 fa_vertex_color;\nlayout(location = 0) out vec4 fa_frag_color;\nvec3 fa_light_tint;\nbool fa_light_is_area;\nint fa_cl_ndir;\nint fa_cl_slot;\nint fa_cl_local;\n\nvoid fa_inst_load()\n{\n}\n\nvec4 fa_light_texel(int t)\n{\n    return texelFetch(fa_light_tex_fa_shadow_smp, ivec2(t & 1023, t >> 10), 0);\n}\n\nvec4 fa_cluster_texel(vec3 world_pos)\n{\n    bool _1575 = fa_mesh_fs_params[19].x < 0.0;\n    bool _1582;\n    if (!_1575)\n    {\n        _1582 = fa_mesh_fs_params[19].w < 1.0;\n    }\n    else\n    {\n        _1582 = _1575;\n    }\n    bool _1590;\n    if (!_1582)\n    {\n        _1590 = fa_mesh_fs_params[18].x < 1.0;\n    }\n    else\n    {\n        _1590 = _1582;\n    }\n    bool _1597;\n    if (!_1590)\n    {\n        _1597 = fa_mesh_fs_params[18].y < 1.0;\n    }\n    else\n    {\n        _1597 = _1590;\n    }\n    bool _1604;\n    if (!_1597)\n    {\n        _1604 = fa_mesh_fs_params[19].y < 1.0;\n    }\n    else\n    {\n        _1604 = _1597;\n    }\n    if (_1604)\n    {\n        return vec4(0.0);\n    }\n    vec4 _1614 = vec4(world_pos, 1.0);\n    float _1620 = dot(fa_mesh_fs_params[16], _1614);\n    if (!(_1620 > 9.9999999747524270787835121154785e-07))\n    {\n        return vec4(0.0);\n    }\n    vec2 _1642 = vec2(dot(fa_mesh_fs_params[14], _1614), dot(fa_mesh_fs_params[15], _1614)) / vec2(_1620);\n    int _1646 = int(fa_mesh_fs_params[18].x);\n    int _1650 = int(fa_mesh_fs_params[18].y);\n    int param = (int(fa_mesh_fs_params[19].x) + (((clamp(int(floor(log2(max(dot(fa_mesh_fs_params[17].xyz, world_pos) + fa_mesh_fs_params[17].w, fa_mesh_fs_params[18].w) / fa_mesh_fs_params[18].w) * fa_mesh_fs_params[18].z)), 0, int(fa_mesh_fs_params[19].y) - 1) * _1650) + clamp(int(floor(((_1642.y * 0.5) + 0.5) * fa_mesh_fs_params[18].y)), 0, _1650 - 1)) * _1646)) + clamp(int(floor(((_1642.x * 0.5) + 0.5) * fa_mesh_fs_params[18].x)), 0, _1646 - 1);\n    return fa_light_texel(param);\n}\n\nivec2 fa_cluster_lookup(vec3 world_pos)\n{\n    vec3 param = world_pos;\n    vec4 _1726 = fa_cluster_texel(param);\n    return ivec2(int(_1726.x), int(_1726.y));\n}\n\nvoid fa_cluster_begin(vec3 world_pos)\n{\n    fa_cl_ndir = int(fa_mesh_fs_params[19].z);\n    vec3 param = world_pos;\n    ivec2 _5781 = fa_cluster_lookup(param);\n    fa_cl_slot = _5781.x;\n    fa_cl_local = _5781.y;\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nvec3 fa_linear_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_tex_fix(inout vec3 c, float mode)\n{\n    if (mode > 1.5)\n    {\n        vec3 param = c;\n        vec3 _6928 = fa_linear_to_srgb(param);\n        c = _6928;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            vec3 param_1 = c;\n            vec3 _6936 = fa_srgb_to_linear(param_1);\n            c = _6936;\n        }\n    }\n    return c;\n}\n\nvec3 fa_tangent_normal(SurfaceInput i, vec3 m)\n{\n    vec3 _519;\n    if (i.front_facing)\n    {\n        _519 = i.world_normal;\n    }\n    else\n    {\n        _519 = -i.world_normal;\n    }\n    vec3 _543 = normalize(i.world_tangent.xyz - (_519 * dot(_519, i.world_tangent.xyz)));\n    vec3 _570 = normalize(((_543 * m.x) + ((cross(_519, _543) * i.world_tangent.w) * m.y)) + (_519 * m.z));\n    vec3 _573;\n    if (i.front_facing)\n    {\n        _573 = _570;\n    }\n    else\n    {\n        _573 = -_570;\n    }\n    return _573;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    vec4 base_t = texture(fa_tex_fa_smp, i.uv);\n    float param = fa_mesh_fs_params[6].w;\n    float param_1 = 1.0;\n    vec3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    vec3 _6967 = fa_tex_fix(param_2, param_3);\n    vec4 _8593 = base_t;\n    _8593.x = _6967.x;\n    _8593.y = _6967.y;\n    _8593.z = _6967.z;\n    base_t = _8593;\n    vec4 _6981 = (_8593 * fa_mesh_fs_params[2]) * i.vertex_color;\n    vec3 _8377 = i.world_normal;\n    if (fa_mesh_fs_params[6].z > 0.5)\n    {\n        float param_4 = fa_mesh_fs_params[6].w;\n        float param_5 = 16.0;\n        vec3 param_6 = texture(fa_normal_tex_fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        vec3 _7013 = fa_tex_fix(param_6, param_7);\n        vec3 _7016 = (_7013 * 2.0) - vec3(1.0);\n        vec2 _7021 = _7016.xy * fa_mesh_fs_params[6].x;\n        vec3 _8601 = _7016;\n        _8601.x = _7021.x;\n        _8601.y = _7021.y;\n        SurfaceInput param_8 = i;\n        vec3 param_9 = _8601;\n        _8377 = fa_tangent_normal(param_8, param_9);\n    }\n    vec4 mrt = texture(fa_mr_tex_fa_smp, i.uv);\n    float param_10 = fa_mesh_fs_params[6].w;\n    float param_11 = 64.0;\n    vec3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    vec3 _7049 = fa_tex_fix(param_12, param_13);\n    vec4 _8604 = mrt;\n    _8604.x = _7049.x;\n    _8604.y = _7049.y;\n    _8604.z = _7049.z;\n    mrt = _8604;\n    vec4 _7077 = texture(fa_occlusion_tex_fa_smp, i.uv);\n    float param_14 = fa_mesh_fs_params[6].w;\n    float param_15 = 256.0;\n    vec3 param_16 = _7077.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    vec3 _7088 = fa_tex_fix(param_16, param_17);\n    float param_18 = fa_mesh_fs_params[6].w;\n    float param_19 = 4.0;\n    vec3 param_20 = texture(fa_emissive_tex_fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    vec3 _7118 = fa_tex_fix(param_20, param_21);\n    float _8382 = fa_mesh_fs_params[20].x;\n    float _8383 = fa_mesh_fs_params[20].y;\n    float _8386 = fa_mesh_fs_params[20].z;\n    float _8385 = fa_mesh_fs_params[21].w;\n    float _8388 = fa_mesh_fs_params[22].x;\n    if (fa_mesh_fs_params[22].z > 0.5)\n    {\n        if (mod(fa_mesh_fs_params[22].z, 2.0) > 0.5)\n        {\n            _8382 *= _7088.y;\n            _8383 *= _7088.z;\n            _8385 *= _7077.w;\n        }\n        if (fa_mesh_fs_params[22].z > 1.5)\n        {\n            _8386 *= mrt.x;\n            _8388 *= mrt.w;\n        }\n    }\n    return Surface(_6981.xyz, _6981.w, _8377, clamp(fa_mesh_fs_params[5].x * _7049.z, 0.0, 1.0), clamp(fa_mesh_fs_params[5].y * _7049.y, 0.0500000007450580596923828125, 1.0), 1.0 + (fa_mesh_fs_params[6].y * (_7088.x - 1.0)), fa_mesh_fs_params[3].xyz + (fa_mesh_fs_params[4].xyz * _7118), _8382, _8383, fa_mesh_fs_params[21].xyz, _8385, _8386, fa_mesh_fs_params[20].w, _8388, fa_mesh_fs_params[22].y, fa_mesh_fs_params[23].xyz, fa_mesh_fs_params[30].x, fa_mesh_fs_params[30].y, fa_mesh_fs_params[31].xyz, fa_mesh_fs_params[30].z);\n}\n\nvoid surface(SurfaceInput i, inout Surface s)\n{\n    s.albedo *= mix(0.5, 1.0, texture(height_height_smp, i.uv).x);\n}\n\nvec4 fa_decal_tile(vec4 rect, vec2 uv, vec2 atlas, vec2 ddx, vec2 ddy)\n{\n    vec2 _1806 = rect.zw - rect.xy;\n    vec2 _1810 = _1806 * atlas;\n    vec2 _1814 = ddx * _1810;\n    vec2 _1818 = ddy * _1810;\n    return textureLod(fa_decal_tex_fa_env_smp, rect.xy + (clamp(uv, vec2(0.0), vec2(1.0)) * _1806), clamp(0.5 * log2(max(max(dot(_1814, _1814), dot(_1818, _1818)), 9.9999999392252902907785028219223e-09)), 0.0, 4.0));\n}\n\nvec3 fa_dc_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_dc_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvoid fa_apply_decals(vec3 world_pos, vec3 geo_normal, inout vec3 albedo, inout vec3 normal)\n{\n    bool _1851 = fa_mesh_fs_params[10].y < 0.5;\n    bool _1858;\n    if (!_1851)\n    {\n        _1858 = fa_mesh_fs_params[10].w < 0.5;\n    }\n    else\n    {\n        _1858 = _1851;\n    }\n    if (_1858)\n    {\n        return;\n    }\n    vec3 _1864 = dFdx(world_pos);\n    vec3 _1867 = dFdy(world_pos);\n    vec3 param = world_pos;\n    vec4 _1871 = fa_cluster_texel(param);\n    int _1875 = int(_1871.w);\n    if (_1875 < 1)\n    {\n        return;\n    }\n    int _1885 = int(fa_mesh_fs_params[10].y + 0.5);\n    int param_1 = _1885;\n    vec4 _1889 = fa_light_texel(param_1);\n    vec2 _1892 = _1889.yz;\n    int _1896 = int(_1889.w);\n    int param_2 = _1885 + 1;\n    vec4 _1901 = fa_light_texel(param_2);\n    float _1902 = _1901.x;\n    int _1908 = int(fa_mesh_fs_params[10].w + 0.5) - 1;\n    int _1912 = int(_1871.z);\n    vec3 _2177;\n    for (int k = 0; k < _1875; k++)\n    {\n        int _1925 = _1912 + k;\n        int param_3 = _1896 + (_1925 >> 2);\n        int _1942 = (_1885 + 2) + (int(fa_light_texel(param_3)[_1925 & 3]) * 7);\n        int param_4 = _1942 + 6;\n        vec4 _1947 = fa_light_texel(param_4);\n        if (((int(_1947.w + 0.5) >> _1908) & 1) == 0)\n        {\n            continue;\n        }\n        int param_5 = _1942;\n        vec4 _1962 = fa_light_texel(param_5);\n        int param_6 = _1942 + 1;\n        vec4 _1967 = fa_light_texel(param_6);\n        int param_7 = _1942 + 2;\n        vec4 _1972 = fa_light_texel(param_7);\n        vec3 _1975 = _1962.xyz;\n        float _1980 = dot(_1975, world_pos) + _1962.w;\n        vec3 _1982 = _1967.xyz;\n        float _1987 = dot(_1982, world_pos) + _1967.w;\n        vec3 _1989 = _1972.xyz;\n        float _1994 = dot(_1989, world_pos) + _1972.w;\n        bool _1999 = abs(_1980) > 0.5;\n        bool _2007;\n        if (!_1999)\n        {\n            _2007 = abs(_1987) > 0.5;\n        }\n        else\n        {\n            _2007 = _1999;\n        }\n        bool _2015;\n        if (!_2007)\n        {\n            _2015 = abs(_1994) > 0.5;\n        }\n        else\n        {\n            _2015 = _2007;\n        }\n        if (_2015)\n        {\n            continue;\n        }\n        float _2030 = clamp(dot(geo_normal, normalize(_1989)) * _1947.z, 0.0, 1.0);\n        if (_2030 <= 0.0)\n        {\n            continue;\n        }\n        float _2050 = (clamp((0.5 - abs(_1994)) * 10.0, 0.0, 1.0) * _2030) * _1947.x;\n        vec2 _2058 = vec2(_1980 + 0.5, 0.5 - _1987);\n        vec2 _2068 = vec2(dot(_1975, _1864), dot(_1982, _1864));\n        vec2 _2078 = vec2(dot(_1975, _1867), dot(_1982, _1867));\n        int param_8 = _1942 + 5;\n        vec4 _2083 = fa_light_texel(param_8);\n        int param_9 = _1942 + 3;\n        vec4 _2088 = fa_light_texel(param_9);\n        int param_10 = _1942 + 4;\n        vec4 _2093 = fa_light_texel(param_10);\n        float tex_a = 1.0;\n        vec3 col = _2083.xyz;\n        bool _2103 = _2088.z > _2088.x;\n        if (_2103)\n        {\n            vec4 param_11 = _2088;\n            vec2 param_12 = _2058;\n            vec2 param_13 = _1892;\n            vec2 param_14 = _2068;\n            vec2 param_15 = _2078;\n            vec4 tx = fa_decal_tile(param_11, param_12, param_13, param_14, param_15);\n            if ((_1902 > 0.5) && (_1902 < 1.5))\n            {\n                vec3 param_16 = tx.xyz;\n                vec3 _2129 = fa_dc_to_linear(param_16);\n                vec4 _8465 = tx;\n                _8465.x = _2129.x;\n                _8465.y = _2129.y;\n                _8465.z = _2129.z;\n                tx = _8465;\n            }\n            col *= tx.xyz;\n            tex_a = tx.w;\n        }\n        albedo = mix(albedo, col, vec3(clamp((_2050 * tex_a) * _2083.w, 0.0, 1.0)));\n        if (_2093.z > _2093.x)\n        {\n            vec4 param_17 = _2093;\n            vec2 param_18 = _2058;\n            vec2 param_19 = _1892;\n            vec2 param_20 = _2068;\n            vec2 param_21 = _2078;\n            vec4 _2173 = fa_decal_tile(param_17, param_18, param_19, param_20, param_21);\n            if (_1902 > 1.5)\n            {\n                vec3 param_22 = _2173.xyz;\n                vec3 _2183 = fa_dc_to_srgb(param_22);\n                _2177 = _2183;\n            }\n            else\n            {\n                _2177 = _2173.xyz;\n            }\n            vec3 _2192 = (_2177 * 2.0) - vec3(1.0);\n            vec2 _2197 = _2192.xy * _1947.y;\n            vec3 _2219 = (normalize(_1975) * _2197.x) + (normalize(_1982) * _2197.y);\n            vec3 _2222 = normalize(normal);\n            normal = normalize(mix(_2222, normalize((_2222 * max(_2192.z, 0.0500000007450580596923828125)) + (_2219 - (_2222 * dot(_2222, _2219)))), vec3(clamp(_2050 * (_2103 ? tex_a : 1.0), 0.0, 1.0))));\n        }\n    }\n}\n\nfloat fa_sheen_albedo(float ndv, float rough)\n{\n    float _4246 = min(sqrt(max(rough - 0.100000001490116119384765625, 0.0) * 1.111111164093017578125) * 6.0, 5.999000072479248046875);\n    float _4253 = min(sqrt(clamp(ndv, 0.0, 1.0)) * 8.0, 7.999000072479248046875);\n    int _4256 = int(_4246);\n    int _4259 = int(_4253);\n    float _4269 = _4253 - float(_4259);\n    int _4324 = (_4256 * 9) + _4259;\n    int _4344 = ((_4256 + 1) * 9) + _4259;\n    return mix(mix(_4320[_4324], _4320[_4324 + 1], _4269), mix(_4320[_4344], _4320[_4344 + 1], _4269), _4246 - float(_4256));\n}\n\nFaLayers fa_layers_setup(SurfaceInput i, Surface s, vec3 n, vec3 v, float metallic, float roughness, inout vec3 f0)\n{\n    bool _8300 = false;\n    float _8301 = 1.0;\n    float _8302 = 1.0;\n    float _8303 = 1.0;\n    float _8304 = 0.0;\n    float _8305 = 0.0;\n    float _8306 = 0.0;\n    float _8307 = 0.0;\n    float _8309 = 1.0;\n    bool _8310 = false;\n    vec3 _8311 = vec3(0.0);\n    float _8312 = 1.0;\n    float _8313 = 1.0;\n    float _8314 = 1.0;\n    float _8315 = 0.0;\n    float _8316 = 0.0;\n    vec3 _8317 = vec3(1.0, 0.0, 0.0);\n    vec3 _8318 = vec3(0.0, 0.0, 1.0);\n    float _8319 = 1.0;\n    float _8320 = 1.0;\n    float _4395 = clamp(s.specular, 0.0, 1.0);\n    float _4399 = clamp(s.ior, 1.0, 3.0);\n    bool _4404 = (_4395 != 1.0) || (_4399 != 1.5);\n    bool _4413;\n    if (!_4404)\n    {\n        _4413 = any(notEqual(s.specular_color, vec3(1.0)));\n    }\n    else\n    {\n        _4413 = _4404;\n    }\n    if (_4413)\n    {\n        float _4421 = (_4399 - 1.0) / (_4399 + 1.0);\n        f0 = mix(min(vec3(_4421 * _4421) * max(s.specular_color, vec3(0.0)), vec3(1.0)) * _4395, s.albedo, vec3(metallic));\n        _8301 = mix(_4395, 1.0, metallic);\n        _8300 = true;\n    }\n    float _4448 = clamp(s.clearcoat, 0.0, 1.0);\n    if (_4448 > 0.0)\n    {\n        float _4456 = clamp(s.clearcoat_roughness, 0.0500000007450580596923828125, 1.0);\n        _8304 = _4448;\n        _8305 = _4456;\n        float _4463 = _4456 * _4456;\n        _8306 = _4463;\n        _8307 = _4463 * _4463;\n        float _4475 = max(dot(i.world_normal, v), 9.9999997473787516355514526367188e-05);\n        _8309 = _4475;\n        _8302 = 1.0 - (_4448 * (0.039999999105930328369140625 + (0.959999978542327880859375 * pow(clamp(1.0 - _4475, 0.0, 1.0), 5.0))));\n        _8300 = true;\n    }\n    vec3 _4494 = max(s.sheen_color, vec3(0.0));\n    float _4503 = max(_4494.x, max(_4494.y, _4494.z));\n    if (_4503 > 0.0)\n    {\n        float _4511 = clamp(s.sheen_roughness, 0.100000001490116119384765625, 1.0);\n        _8310 = true;\n        _8311 = _4494;\n        _8312 = _4511;\n        _8313 = _4511 * _4511;\n        float param = max(dot(n, v), 9.9999997473787516355514526367188e-05);\n        float param_1 = _4511;\n        float _4528 = fa_sheen_albedo(param, param_1);\n        _8315 = _4528;\n        _8314 = 1.0 - min(_4503 * _4528, 1.0);\n        _8300 = true;\n    }\n    _8303 = _8302 * _8314;\n    float _4547 = clamp(s.anisotropy, -1.0, 1.0);\n    if (_4547 != 0.0)\n    {\n        vec3 _4562 = i.world_tangent.xyz - (n * dot(n, i.world_tangent.xyz));\n        vec3 t = _4562;\n        if (dot(_4562, _4562) < 9.9999999392252902907785028219223e-09)\n        {\n            bvec3 _4574 = bvec3(abs(n.y) < 0.9900000095367431640625);\n            t = cross(vec3(_4574.x ? vec3(0.0, 1.0, 0.0).x : vec3(1.0, 0.0, 0.0).x, _4574.y ? vec3(0.0, 1.0, 0.0).y : vec3(1.0, 0.0, 0.0).y, _4574.z ? vec3(0.0, 1.0, 0.0).z : vec3(1.0, 0.0, 0.0).z), n);\n        }\n        vec3 _4578 = t;\n        vec3 _4579 = normalize(_4578);\n        t = _4579;\n        vec3 _4604 = normalize((_4579 * cos(s.anisotropy_rotation)) + ((cross(n, _4579) * ((i.world_tangent.w < 0.0) ? (-1.0) : 1.0)) * sin(s.anisotropy_rotation)));\n        _8317 = _4604;\n        _8318 = cross(n, _4604);\n        float _4614 = roughness * roughness;\n        float _4620 = mix(_4614, 1.0, _4547 * _4547);\n        bool _4622 = _4547 > 0.0;\n        _8319 = _4622 ? _4620 : _4614;\n        _8320 = _4622 ? _4614 : _4620;\n        _8316 = _4547;\n        _8300 = true;\n    }\n    return FaLayers(_8300, _8301, _8302, _8303, _8304, _8305, _8306, _8307, i.world_normal, _8309, _8310, _8311, _8312, _8313, _8314, _8315, _8316, _8317, _8318, _8319, _8320);\n}\n\nvec2 fa_atlas_size()\n{\n    return vec2(textureSize(fa_probe_atlas_fa_env_smp, 0));\n}\n\nvec3 fa_probe_sh_coef(vec2 origin, float res, int k)\n{\n    vec3 v = textureLod(fa_probe_atlas_fa_env_smp, (origin + vec2(float(k) + 0.5, res + 2.5)) / fa_atlas_size(), 0.0).xyz;\n    if (fa_mesh_fs_params[41].y > 0.5)\n    {\n        v = (v - vec3(0.5)) * 8.0;\n    }\n    return v;\n}\n\nvec3 fa_sh_eval(vec3 c[9], vec3 n)\n{\n    vec3 _3417 = max((((c[0] * 0.2820948064327239990234375) + (((c[1] * (0.3257350027561187744140625 * n.y)) + (c[2] * (0.3257350027561187744140625 * n.z))) + (c[3] * (0.3257350027561187744140625 * n.x)))) + (((c[4] * ((0.2731371223926544189453125 * n.x) * n.y)) + (c[5] * ((0.2731371223926544189453125 * n.y) * n.z))) + (c[6] * (0.078847892582416534423828125 * (((3.0 * n.z) * n.z) - 1.0))))) + ((c[7] * ((0.2731371223926544189453125 * n.x) * n.z)) + (c[8] * (0.13656856119632720947265625 * ((n.x * n.x) - (n.y * n.y))))), vec3(0.0));\n    return _3417;\n}\n\nvec3 fa_ambient_light(vec3 n)\n{\n    float _4027 = (1.0 - fa_mesh_fs_params[42].w) - fa_mesh_fs_params[47].w;\n    vec3 amb = vec3(0.0);\n    bool _4032 = fa_mesh_fs_params[11].w > 0.5;\n    vec3 c[9];\n    for (int k = 0; k < 9; k++)\n    {\n        c[k] = vec3(0.0);\n    }\n    if (_4027 > 0.0005000000237487256526947021484375)\n    {\n        if (_4032)\n        {\n            for (int k_1 = 0; k_1 < 9; k_1++)\n            {\n                vec2 param = fa_mesh_fs_params[41].zw;\n                float param_1 = 128.0;\n                int param_2 = k_1;\n                c[k_1] = fa_probe_sh_coef(param, param_1, param_2) * _4027;\n            }\n        }\n        else\n        {\n            amb = fa_mesh_fs_params[1].xyz * _4027;\n        }\n    }\n    bool _4083 = fa_mesh_fs_params[42].w > 0.0;\n    if (_4083)\n    {\n        for (int k_2 = 0; k_2 < 9; k_2++)\n        {\n            vec2 param_3 = fa_mesh_fs_params[42].xy;\n            float param_4 = fa_mesh_fs_params[42].z;\n            int param_5 = k_2;\n            c[k_2] += (fa_probe_sh_coef(param_3, param_4, param_5) * fa_mesh_fs_params[42].w);\n        }\n    }\n    bool _4114 = fa_mesh_fs_params[47].w > 0.0;\n    if (_4114)\n    {\n        for (int k_3 = 0; k_3 < 9; k_3++)\n        {\n            vec2 param_6 = fa_mesh_fs_params[47].xy;\n            float param_7 = fa_mesh_fs_params[47].z;\n            int param_8 = k_3;\n            c[k_3] += (fa_probe_sh_coef(param_6, param_7, param_8) * fa_mesh_fs_params[47].w);\n        }\n    }\n    if ((_4032 || _4083) || _4114)\n    {\n        vec3 param_9[9] = c;\n        vec3 param_10 = n;\n        amb += fa_sh_eval(param_9, param_10);\n    }\n    return amb;\n}\n\nvec3 fa_indirect_diffuse(vec3 n)\n{\n    if (fa_lm.z > 0.5)\n    {\n        return textureLod(fa_lightmap_fa_env_smp, fa_lm.xy, 0.0).xyz;\n    }\n    if (fa_mesh_fs_params[32].w > 0.0)\n    {\n        vec3 c[9];\n        for (int k = 0; k < 9; k++)\n        {\n            c[k] = fa_mesh_fs_params[k * 1 + 32].xyz;\n        }\n        vec3 param = n;\n        vec3 param_1[9] = c;\n        vec3 param_2 = n;\n        return mix(fa_ambient_light(param), fa_sh_eval(param_1, param_2), vec3(clamp(fa_mesh_fs_params[32].w, 0.0, 1.0)));\n    }\n    vec3 param_3 = n;\n    return fa_ambient_light(param_3);\n}\n\nint fa_cluster_index(int slot, int n)\n{\n    int param = (int(fa_mesh_fs_params[19].x) + int(fa_mesh_fs_params[19].w)) + ((slot + n) >> 2);\n    vec4 t = fa_light_texel(param);\n    return int(t[(slot + n) & 3]);\n}\n\nint fa_cl_light(int n)\n{\n    if (n < fa_cl_ndir)\n    {\n        return n;\n    }\n    int param = fa_cl_slot;\n    int param_1 = n - fa_cl_ndir;\n    return fa_cluster_index(param, param_1);\n}\n\nint fa_light_base(int li)\n{\n    return li * ((fa_mesh_fs_params[1].w > 4.5) ? 8 : 4);\n}\n\nbool fa_light_baked(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 3;\n    return fa_light_texel(param_1).w > 0.5;\n}\n\nfloat fa_baked_keep(int li)\n{\n    float _5751;\n    if (fa_lm.z > 0.5)\n    {\n        _5751 = 0.0;\n    }\n    else\n    {\n        _5751 = 1.0 - clamp(fa_mesh_fs_params[32].w, 0.0, 1.0);\n    }\n    bool _5762 = _5751 < 1.0;\n    bool _5768;\n    if (_5762)\n    {\n        int param = li;\n        _5768 = fa_light_baked(param);\n    }\n    else\n    {\n        _5768 = _5762;\n    }\n    return _5768 ? _5751 : 1.0;\n}\n\nfloat fa_light_type(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 1;\n    return fa_light_texel(param_1).w;\n}\n\nvec4 fa_atlas_fetch(vec2 texel)\n{\n    return textureLod(fa_light_atlas_fa_env_smp, texel / vec2(textureSize(fa_light_atlas_fa_env_smp, 0)), 0.0);\n}\n\nvec3 fa_cookie_sample(vec2 tile_origin, vec2 uv)\n{\n    vec2 param = (tile_origin + vec2(1.0)) + (clamp(uv, vec2(0.0), vec2(1.0)) * 254.0);\n    return fa_atlas_fetch(param).xyz;\n}\n\nvec3 fa_area_point(vec3 c, vec3 axis, vec3 ru, vec3 uu, float hx, float hy, float shape, vec3 p, vec3 r)\n{\n    bool _824 = dot(r, r) > 0.5;\n    if (shape > 1.5)\n    {\n        vec3 _837 = (c - (ru * hx)) - p;\n        vec3 _843 = ru * (2.0 * hx);\n        float _849 = max(dot(_843, _843), 9.9999999392252902907785028219223e-09);\n        float _853 = dot(_837, _843);\n        float t = clamp((-_853) / _849, 0.0, 1.0);\n        if (_824)\n        {\n            float _868 = dot(r, _843);\n            float _874 = _849 - (_868 * _868);\n            if (abs(_874) > (9.9999997473787516355514526367188e-06 * _849))\n            {\n                t = clamp(((dot(r, _837) * _868) - _853) / _874, 0.0, 1.0);\n            }\n        }\n        return (p + _837) + (_843 * t);\n    }\n    vec3 q = p;\n    float _906 = dot(r, axis);\n    bool _914;\n    if (_824)\n    {\n        _914 = abs(_906) > 9.9999997473787516355514526367188e-05;\n    }\n    else\n    {\n        _914 = _824;\n    }\n    if (_914)\n    {\n        float _924 = dot(c - p, axis) / _906;\n        if (_924 > 0.0)\n        {\n            q = p + (r * _924);\n        }\n    }\n    vec3 _937 = q - c;\n    vec2 xy = vec2(dot(_937, ru), dot(_937, uu));\n    if (shape > 0.5)\n    {\n        float _952 = length(xy);\n        if (_952 > hx)\n        {\n            xy *= (hx / _952);\n        }\n    }\n    else\n    {\n        xy = clamp(xy, vec2(-hx, -hy), vec2(hx, hy));\n    }\n    return (c + (ru * xy.x)) + (uu * xy.y);\n}\n\nint fa_cube_face(vec3 d)\n{\n    vec3 _585 = abs(d);\n    float _587 = _585.x;\n    float _589 = _585.y;\n    bool _590 = _587 >= _589;\n    bool _598;\n    if (_590)\n    {\n        _598 = _587 >= _585.z;\n    }\n    else\n    {\n        _598 = _590;\n    }\n    int _599;\n    if (_598)\n    {\n        _599 = (d.x > 0.0) ? 0 : 1;\n    }\n    else\n    {\n        int _614;\n        if (_589 >= _585.z)\n        {\n            _614 = (d.y > 0.0) ? 2 : 3;\n        }\n        else\n        {\n            _614 = (d.z > 0.0) ? 4 : 5;\n        }\n        _599 = _614;\n    }\n    return _599;\n}\n\nvoid fa_cube_face_basis(int f, out vec3 fwd, out vec3 up)\n{\n    if (f == 0)\n    {\n        fwd = vec3(1.0, 0.0, 0.0);\n        up = vec3(0.0, 1.0, 0.0);\n    }\n    else\n    {\n        if (f == 1)\n        {\n            fwd = vec3(-1.0, 0.0, 0.0);\n            up = vec3(0.0, 1.0, 0.0);\n        }\n        else\n        {\n            if (f == 2)\n            {\n                fwd = vec3(0.0, 1.0, 0.0);\n                up = vec3(0.0, 0.0, 1.0);\n            }\n            else\n            {\n                if (f == 3)\n                {\n                    fwd = vec3(0.0, -1.0, 0.0);\n                    up = vec3(0.0, 0.0, -1.0);\n                }\n                else\n                {\n                    if (f == 4)\n                    {\n                        fwd = vec3(0.0, 0.0, 1.0);\n                        up = vec3(0.0, 1.0, 0.0);\n                    }\n                    else\n                    {\n                        fwd = vec3(0.0, 0.0, -1.0);\n                        up = vec3(0.0, 1.0, 0.0);\n                    }\n                }\n            }\n        }\n    }\n}\n\nfloat fa_ies_sample(vec2 tile_origin, vec3 d, vec3 axis, vec3 right, vec3 up)\n{\n    float _744 = dot(d, right);\n    float _748 = dot(d, up);\n    float _759;\n    if (((_744 * _744) + (_748 * _748)) > 1.0000000133514319600180897396058e-10)\n    {\n        _759 = atan(_748, _744) * 0.15915493667125701904296875;\n    }\n    else\n    {\n        _759 = 0.0;\n    }\n    vec2 param = tile_origin + vec2(1.0 + ((_759 - floor(_759)) * 64.0), 1.0 + (acos(clamp(dot(d, axis), -1.0, 1.0)) * 10.18591594696044921875));\n    return fa_atlas_fetch(param).x;\n}\n\nLightSample fa_light_sample_n(int li, vec3 world_pos, vec3 n)\n{\n    int param = li;\n    int _990 = fa_light_base(param);\n    bool _994 = fa_mesh_fs_params[1].w > 4.5;\n    int param_1 = _990;\n    vec4 _998 = fa_light_texel(param_1);\n    int param_2 = _990 + 1;\n    vec4 _1003 = fa_light_texel(param_2);\n    float _1006 = _1003.w;\n    float atten = 1.0;\n    float dist = 0.0;\n    fa_light_tint = vec3(1.0);\n    bool _1018 = _994 && (_1006 > 2.5);\n    fa_light_is_area = _1018;\n    bool _1020 = _1006 < 0.5;\n    vec3 l;\n    if (_1020)\n    {\n        l = normalize(_998.xyz);\n        if (_994)\n        {\n            int param_3 = _990 + 6;\n            vec4 _1034 = fa_light_texel(param_3);\n            if (_1034.z > 0.5)\n            {\n                int param_4 = _990 + 4;\n                vec4 _1044 = fa_light_texel(param_4);\n                int param_5 = _990 + 5;\n                vec4 _1049 = fa_light_texel(param_5);\n                vec2 param_6 = _1034.xy;\n                vec2 param_7 = fract(vec2(dot(world_pos, _1044.xyz) * _1044.w, (-dot(world_pos, _1049.xyz)) * _1049.w) + vec2(0.5));\n                fa_light_tint = fa_cookie_sample(param_6, param_7);\n            }\n        }\n    }\n    else\n    {\n        vec3 _1079 = _998.xyz;\n        vec3 _1081 = _1079 - world_pos;\n        vec3 to_light = _1081;\n        float _1084 = length(_1081);\n        float reach = _1084;\n        bool front = true;\n        if (_1018)\n        {\n            int param_8 = _990 + 7;\n            reach = max(_1084 - fa_light_texel(param_8).w, 0.0);\n            int param_9 = _990 + 4;\n            vec4 _1108 = fa_light_texel(param_9);\n            int param_10 = _990 + 5;\n            vec4 _1113 = fa_light_texel(param_10);\n            int param_11 = _990 + 6;\n            vec4 _1118 = fa_light_texel(param_11);\n            float _1119 = _1118.w;\n            int param_12 = _990 + 2;\n            vec3 _1126 = normalize(fa_light_texel(param_12).xyz);\n            bool _1128 = _1119 > 1.5;\n            bool _1136;\n            if (!_1128)\n            {\n                _1136 = dot(_1126, to_light) < 0.0;\n            }\n            else\n            {\n                _1136 = _1128;\n            }\n            front = _1136;\n            vec3 r = vec3(0.0);\n            vec3 _1145 = fa_mesh_fs_params[0].xyz - world_pos;\n            bool _1149 = dot(n, n) > 0.5;\n            bool _1157;\n            if (_1149)\n            {\n                _1157 = dot(_1145, _1145) > 9.9999999600419720025001879548654e-13;\n            }\n            else\n            {\n                _1157 = _1149;\n            }\n            if (_1157)\n            {\n                r = reflect(-normalize(_1145), normalize(n));\n            }\n            vec3 param_13 = _1079;\n            vec3 param_14 = _1126;\n            vec3 param_15 = _1108.xyz;\n            vec3 param_16 = _1113.xyz;\n            float param_17 = _1108.w;\n            float param_18 = _1113.w;\n            float param_19 = _1119;\n            vec3 param_20 = world_pos;\n            vec3 param_21 = r;\n            to_light = fa_area_point(param_13, param_14, param_15, param_16, param_17, param_18, param_19, param_20, param_21) - world_pos;\n        }\n        float _1193 = length(to_light);\n        dist = _1193;\n        l = to_light / vec3(max(_1193, 9.9999997473787516355514526367188e-05));\n        float _1207 = reach / max(_998.w, 0.001000000047497451305389404296875);\n        float _1213 = clamp(1.0 - (_1207 * _1207), 0.0, 1.0);\n        float _1215;\n        if (front)\n        {\n            _1215 = _1213 * _1213;\n        }\n        else\n        {\n            _1215 = 0.0;\n        }\n        atten = _1215;\n        bool _1226 = _1006 < 2.5;\n        if ((_1006 > 1.5) && _1226)\n        {\n            int param_22 = _990 + 2;\n            vec4 _1234 = fa_light_texel(param_22);\n            float _1244 = _1234.w;\n            int param_23 = _990 + 3;\n            vec4 _1249 = fa_light_texel(param_23);\n            float _1250 = _1249.x;\n            float cos_inner = _1250;\n            if (_1250 > 1.5)\n            {\n                cos_inner = mix(_1244, 1.0, 0.25);\n            }\n            atten *= smoothstep(_1244, cos_inner, dot(-l, normalize(_1234.xyz)));\n        }\n        if (_994 && (_1006 < 1.5))\n        {\n            int param_24 = _990 + 6;\n            vec4 _1274 = fa_light_texel(param_24);\n            if (_1274.z > 0.5)\n            {\n                vec3 _1282 = -to_light;\n                int param_25 = _990 + 4;\n                int param_26 = _990 + 5;\n                vec3 _1296 = fa_light_texel(param_25).xyz;\n                vec3 _1300 = fa_light_texel(param_26).xyz;\n                vec3 _1309 = vec3(dot(_1282, _1296), dot(_1282, _1300), dot(_1282, cross(_1296, _1300)));\n                vec3 param_27 = _1309;\n                int _1313 = fa_cube_face(param_27);\n                int param_28 = _1313;\n                vec3 param_29;\n                vec3 param_30;\n                fa_cube_face_basis(param_28, param_29, param_30);\n                vec2 _1340 = vec2(dot(_1309, cross(param_29, param_30)), dot(_1309, param_30)) / vec2(max(dot(_1309, param_29), 9.9999997473787516355514526367188e-05));\n                int _1344 = _1313 / 3;\n                vec2 param_31 = _1274.xy + (vec2(float(_1313 - (_1344 * 3)), float(_1344)) * 256.0);\n                vec2 param_32 = vec2(0.5 + (0.5 * _1340.x), 0.5 - (0.5 * _1340.y));\n                fa_light_tint = fa_cookie_sample(param_31, param_32);\n            }\n            int param_33 = _990 + 7;\n            vec4 _1374 = fa_light_texel(param_33);\n            if (_1374.z > 0.5)\n            {\n                int param_34 = _990 + 2;\n                int param_35 = _990 + 4;\n                int param_36 = _990 + 5;\n                vec2 param_37 = _1374.xy;\n                vec3 param_38 = -l;\n                vec3 param_39 = normalize(fa_light_texel(param_34).xyz);\n                vec3 param_40 = fa_light_texel(param_35).xyz;\n                vec3 param_41 = fa_light_texel(param_36).xyz;\n                atten *= fa_ies_sample(param_37, param_38, param_39, param_40, param_41);\n            }\n        }\n        else\n        {\n            if (_994 && _1226)\n            {\n                int param_42 = _990 + 6;\n                vec4 _1421 = fa_light_texel(param_42);\n                int param_43 = _990 + 7;\n                vec4 _1426 = fa_light_texel(param_43);\n                bool _1429 = _1421.z > 0.5;\n                bool _1436;\n                if (!_1429)\n                {\n                    _1436 = _1426.z > 0.5;\n                }\n                else\n                {\n                    _1436 = _1429;\n                }\n                if (_1436)\n                {\n                    int param_44 = _990 + 2;\n                    vec4 _1443 = fa_light_texel(param_44);\n                    vec3 _1447 = normalize(_1443.xyz);\n                    int param_45 = _990 + 4;\n                    vec4 _1452 = fa_light_texel(param_45);\n                    int param_46 = _990 + 5;\n                    vec4 _1457 = fa_light_texel(param_46);\n                    if (_1429)\n                    {\n                        vec3 _1465 = -to_light;\n                        float _1472 = _1443.w;\n                        float _1488 = 0.5 / max(dot(_1465, _1447) * (sqrt(max(1.0 - (_1472 * _1472), 0.0)) / max(_1472, 0.001000000047497451305389404296875)), 9.9999997473787516355514526367188e-05);\n                        vec2 param_47 = _1421.xy;\n                        vec2 param_48 = vec2(0.5 + (dot(_1465, _1452.xyz) * _1488), 0.5 - (dot(_1465, _1457.xyz) * _1488));\n                        fa_light_tint = fa_cookie_sample(param_47, param_48);\n                    }\n                    if (_1426.z > 0.5)\n                    {\n                        vec2 param_49 = _1426.xy;\n                        vec3 param_50 = -l;\n                        vec3 param_51 = _1447;\n                        vec3 param_52 = _1452.xyz;\n                        vec3 param_53 = _1457.xyz;\n                        atten *= fa_ies_sample(param_49, param_50, param_51, param_52, param_53);\n                    }\n                }\n            }\n        }\n    }\n    vec3 _8288 = _1003.xyz * atten;\n    if (_994)\n    {\n        _8288 *= fa_light_tint;\n    }\n    int _1557;\n    if (_1020)\n    {\n        _1557 = 0;\n    }\n    else\n    {\n        _1557 = ((_1006 > 1.5) && (_1006 < 2.5)) ? 2 : 1;\n    }\n    return LightSample(l, _8288, atten, 1.0, dist, _1557);\n}\n\nfloat fa_shadow_split_at(int i)\n{\n    float _2294;\n    if (i == 0)\n    {\n        _2294 = fa_shadows[24].x;\n    }\n    else\n    {\n        float _2310;\n        if (i == 1)\n        {\n            _2310 = fa_shadows[24].y;\n        }\n        else\n        {\n            float _2318;\n            if (i == 2)\n            {\n                _2318 = fa_shadows[24].z;\n            }\n            else\n            {\n                _2318 = fa_shadows[24].w;\n            }\n            _2310 = _2318;\n        }\n        _2294 = _2310;\n    }\n    return _2294;\n}\n\nfloat fa_shadow_depth(inout vec2 uv, vec4 rect)\n{\n    uv = clamp(uv, rect.xy, rect.zw);\n    return textureLod(fa_shadow_tex_fa_shadow_smp, uv, 0.0).x;\n}\n\nfloat fa_shadow_fetch(vec2 uv, vec4 rect, vec3 conv)\n{\n    vec2 param = uv;\n    vec4 param_1 = rect;\n    float _2351 = fa_shadow_depth(param, param_1);\n    float _2355;\n    if (conv.x < 0.5)\n    {\n        _2355 = _2351;\n    }\n    else\n    {\n        _2355 = (conv.y * conv.z) / (conv.z - (_2351 * (conv.z - conv.y)));\n    }\n    return _2355;\n}\n\nfloat fa_shadow_noise()\n{\n    return fract(52.98291778564453125 * fract(dot(gl_FragCoord.xy, vec2(0.067110560834407806396484375, 0.005837149918079376220703125))));\n}\n\nvec2 fa_shadow_vogel(int k, int n, float phi)\n{\n    float _2282 = (float(k) * 2.3999631404876708984375) + phi;\n    return vec2(cos(_2282), sin(_2282)) * sqrt((float(k) + 0.5) / float(n));\n}\n\nfloat fa_shadow_filter(vec2 uv, vec4 rect, float zr, float texel_m, float unit, float reach, float plane, vec3 conv, int mode, float k)\n{\n    if (mode == 1)\n    {\n        vec2 param = uv;\n        vec4 param_1 = rect;\n        vec3 param_2 = conv;\n        return float(zr <= fa_shadow_fetch(param, param_1, param_2));\n    }\n    float _2401 = fa_shadow_noise() * 6.283185482025146484375;\n    float radius = 1.5;\n    if (mode == 2)\n    {\n        float _2410;\n        if (k < 0.0)\n        {\n            _2410 = (-k) / max(zr, 0.100000001490116119384765625);\n        }\n        else\n        {\n            _2410 = k;\n        }\n        float _2430 = clamp((_2410 * reach) / texel_m, 3.0, 12.0);\n        float sum = 0.0;\n        float cnt = 0.0;\n        for (int i = 0; i < 16; i++)\n        {\n            int param_3 = i;\n            int param_4 = 16;\n            float param_5 = _2401;\n            vec2 _2449 = fa_shadow_vogel(param_3, param_4, param_5) * _2430;\n            vec2 param_6 = uv + (_2449 * fa_shadows[26].zw);\n            vec4 param_7 = rect;\n            vec3 param_8 = conv;\n            float _2461 = fa_shadow_fetch(param_6, param_7, param_8);\n            if (_2461 < (zr - (length(_2449) * plane)))\n            {\n                sum += _2461;\n                cnt += 1.0;\n            }\n        }\n        if (cnt < 0.5)\n        {\n            return 1.0;\n        }\n        float _2487 = sum / cnt;\n        float _2497;\n        if (k < 0.0)\n        {\n            _2497 = (-k) / max(_2487, 0.0500000007450580596923828125);\n        }\n        else\n        {\n            _2497 = k;\n        }\n        radius = clamp(((max(zr - _2487, 0.0) * unit) * _2497) / texel_m, 1.5, 16.0);\n    }\n    float lit = 0.0;\n    int _2519 = (mode == 2) ? 24 : 16;\n    for (int i_1 = 0; i_1 < _2519; i_1++)\n    {\n        int param_9 = i_1;\n        int param_10 = _2519;\n        float param_11 = _2401;\n        vec2 _2538 = fa_shadow_vogel(param_9, param_10, param_11) * radius;\n        vec2 param_12 = uv + (_2538 * fa_shadows[26].zw);\n        vec4 param_13 = rect;\n        vec3 param_14 = conv;\n        lit += float((zr - (length(_2538) * plane)) <= fa_shadow_fetch(param_12, param_13, param_14));\n    }\n    return lit / float(_2519);\n}\n\nfloat fa_shadow_cascade(int ci, vec3 world, vec3 n, vec3 l)\n{\n    float _2580 = max(fa_shadows[ci * 1 + 20].y, 0.001000000047497451305389404296875);\n    float _2585 = clamp(dot(n, l), 0.0, 1.0);\n    float _2591 = sqrt(1.0 - (_2585 * _2585));\n    float _2598 = min(_2591 / max(_2585, 0.20000000298023223876953125), 4.0);\n    float _2603;\n    if (fa_shadows[26].y > 0.0)\n    {\n        _2603 = fa_shadows[26].y;\n    }\n    else\n    {\n        _2603 = 1.5 * fa_shadows[ci * 1 + 20].x;\n    }\n    vec4 _2628 = mat4(fa_shadows[ci * 4 + 0], fa_shadows[ci * 4 + 1], fa_shadows[ci * 4 + 2], fa_shadows[ci * 4 + 3]) * vec4(world + (n * (_2603 * _2591)), 1.0);\n    float _2635 = _2628.x;\n    bool _2638 = _2635 < fa_shadows[ci * 1 + 16].x;\n    bool _2647;\n    if (!_2638)\n    {\n        _2647 = _2635 > fa_shadows[ci * 1 + 16].z;\n    }\n    else\n    {\n        _2647 = _2638;\n    }\n    bool _2656;\n    if (!_2647)\n    {\n        _2656 = _2628.y < fa_shadows[ci * 1 + 16].y;\n    }\n    else\n    {\n        _2656 = _2647;\n    }\n    bool _2665;\n    if (!_2656)\n    {\n        _2665 = _2628.y > fa_shadows[ci * 1 + 16].w;\n    }\n    else\n    {\n        _2665 = _2656;\n    }\n    bool _2672;\n    if (!_2665)\n    {\n        _2672 = _2628.z > 1.0;\n    }\n    else\n    {\n        _2672 = _2665;\n    }\n    if (_2672)\n    {\n        return -1.0;\n    }\n    float _2680;\n    if (fa_shadows[26].x > 0.0)\n    {\n        _2680 = fa_shadows[26].x;\n    }\n    else\n    {\n        _2680 = 1.5 * fa_shadows[ci * 1 + 20].x;\n    }\n    vec2 param = _2628.xy;\n    vec4 param_1 = fa_shadows[ci * 1 + 16];\n    float param_2 = _2628.z - ((_2680 * (1.0 + (0.5 * _2598))) / _2580);\n    float param_3 = fa_shadows[ci * 1 + 20].x;\n    float param_4 = _2580;\n    float param_5 = _2580 * 0.25;\n    float param_6 = ((fa_shadows[ci * 1 + 20].x * min(_2598, 3.0)) * 0.5) / _2580;\n    vec3 param_7 = vec3(0.0);\n    int param_8 = int(fa_shadows[25].z + 0.5);\n    float param_9 = fa_shadows[25].w;\n    return fa_shadow_filter(param, param_1, param_2, param_3, param_4, param_5, param_6, param_7, param_8, param_9);\n}\n\nfloat fa_shadow_sun(vec3 world, vec3 n, vec3 l)\n{\n    if (fa_mesh_fs_params[5].z < 0.5)\n    {\n        return 1.0;\n    }\n    int _3058 = int(fa_shadows[25].x + 0.5);\n    if (_3058 < 1)\n    {\n        return 1.0;\n    }\n    float _3073 = dot(world - fa_shadows[27].xyz, fa_shadows[28].xyz);\n    int param = _3058 - 1;\n    if (_3073 > fa_shadow_split_at(param))\n    {\n        return 1.0;\n    }\n    int ci = 0;\n    bool _3085 = _3058 > 1;\n    bool _3092;\n    if (_3085)\n    {\n        _3092 = _3073 > fa_shadows[24].x;\n    }\n    else\n    {\n        _3092 = _3085;\n    }\n    if (_3092)\n    {\n        ci = 1;\n    }\n    bool _3096 = _3058 > 2;\n    bool _3103;\n    if (_3096)\n    {\n        _3103 = _3073 > fa_shadows[24].y;\n    }\n    else\n    {\n        _3103 = _3096;\n    }\n    if (_3103)\n    {\n        ci = 2;\n    }\n    bool _3107 = _3058 > 3;\n    bool _3114;\n    if (_3107)\n    {\n        _3114 = _3073 > fa_shadows[24].z;\n    }\n    else\n    {\n        _3114 = _3107;\n    }\n    if (_3114)\n    {\n        ci = 3;\n    }\n    float s = -1.0;\n    for (int k = 0; k < 4; k++)\n    {\n        if (ci >= _3058)\n        {\n            break;\n        }\n        int param_1 = ci;\n        vec3 param_2 = world;\n        vec3 param_3 = n;\n        vec3 param_4 = l;\n        float _3140 = fa_shadow_cascade(param_1, param_2, param_3, param_4);\n        s = _3140;\n        if (_3140 >= 0.0)\n        {\n            break;\n        }\n        ci++;\n    }\n    if (s < 0.0)\n    {\n        return 1.0;\n    }\n    if (fa_shadows[25].y > 0.0)\n    {\n        float _3165;\n        if (ci > 0)\n        {\n            int param_5 = ci - 1;\n            _3165 = fa_shadow_split_at(param_5);\n        }\n        else\n        {\n            _3165 = fa_shadows[28].w;\n        }\n        int param_6 = ci;\n        float _3184 = fa_shadows[25].y * max(fa_shadow_split_at(param_6) - _3165, 9.9999997473787516355514526367188e-05);\n        int param_7 = ci;\n        float _3195 = clamp((_3073 - (fa_shadow_split_at(param_7) - _3184)) / _3184, 0.0, 1.0);\n        if (_3195 > 0.0)\n        {\n            float s2 = 1.0;\n            if ((ci + 1) < _3058)\n            {\n                int param_8 = ci + 1;\n                vec3 param_9 = world;\n                vec3 param_10 = n;\n                vec3 param_11 = l;\n                float _3216 = fa_shadow_cascade(param_8, param_9, param_10, param_11);\n                s2 = _3216;\n                if (_3216 < 0.0)\n                {\n                    s2 = s;\n                }\n            }\n            s = mix(s, s2, _3195);\n        }\n    }\n    return s;\n}\n\nfloat fa_shadow_factor(vec3 n, vec3 l)\n{\n    vec3 param = fa_world_pos;\n    vec3 param_1 = n;\n    vec3 param_2 = l;\n    return fa_shadow_sun(param, param_1, param_2);\n}\n\nfloat fa_shadow_local(int li, vec3 lpos, vec3 world, vec3 n, vec3 l)\n{\n    bool _2738 = fa_mesh_fs_params[5].z < 0.5;\n    bool _2745;\n    if (!_2738)\n    {\n        _2745 = fa_shadows[29].x < 0.5;\n    }\n    else\n    {\n        _2745 = _2738;\n    }\n    if (_2745)\n    {\n        return 1.0;\n    }\n    int param = (int(fa_shadows[29].x + 0.5) - 1) + li;\n    vec4 _2758 = fa_light_texel(param);\n    float _2759 = _2758.x;\n    if (_2759 < 0.0)\n    {\n        return 1.0;\n    }\n    int _2768 = int(_2759 + 0.5);\n    int param_1 = _2768;\n    vec4 _2772 = fa_light_texel(param_1);\n    int param_2 = _2768 + 1;\n    vec4 _2777 = fa_light_texel(param_2);\n    float fade = 1.0;\n    float _2780 = _2772.y;\n    if (_2780 > 0.0)\n    {\n        float _2797 = 1.0 - smoothstep(0.75 * _2780, _2780, length(world - fa_shadows[27].xyz));\n        fade = _2797;\n        if (_2797 <= 0.0)\n        {\n            return 1.0;\n        }\n    }\n    int face = 0;\n    if (_2772.x > 1.5)\n    {\n        vec3 param_3 = world - lpos;\n        face = fa_cube_face(param_3);\n    }\n    int _2821 = (_2768 + 2) + (face * 6);\n    int param_4 = _2821;\n    int param_5 = _2821 + 1;\n    int param_6 = _2821 + 3;\n    vec4 _2835 = fa_light_texel(param_6);\n    int param_7 = _2821 + 4;\n    vec4 _2840 = fa_light_texel(param_7);\n    int param_8 = _2821 + 5;\n    vec4 _2845 = fa_light_texel(param_8);\n    float _2857 = _2845.x * max(dot(_2835, vec4(world, 1.0)), 0.001000000047497451305389404296875);\n    float _2862 = clamp(dot(n, l), 0.0, 1.0);\n    float _2885 = clamp(dot(n, _2835.xyz), -1.0, 1.0);\n    float _2904 = min(sqrt(1.0 - (_2885 * _2885)) / max(abs(dot(n, world - lpos)) / max(dot(_2835, vec4(world, 1.0)), 0.001000000047497451305389404296875), 0.20000000298023223876953125), 4.0);\n    float _2907 = _2777.y;\n    float _2909;\n    if (_2907 > 0.0)\n    {\n        _2909 = _2907;\n    }\n    else\n    {\n        _2909 = 1.5 * _2857;\n    }\n    vec4 _2929 = vec4(world + (n * (_2909 * sqrt(1.0 - (_2862 * _2862)))), 1.0);\n    float _2933 = dot(_2835, _2929);\n    float _2936 = _2845.y;\n    if (_2933 < _2936)\n    {\n        return 1.0;\n    }\n    vec2 _2951 = vec2(dot(fa_light_texel(param_4), _2929), dot(fa_light_texel(param_5), _2929)) / vec2(_2933);\n    float _2953 = _2951.x;\n    bool _2956 = _2953 < _2840.x;\n    bool _2965;\n    if (!_2956)\n    {\n        _2965 = _2953 > _2840.z;\n    }\n    else\n    {\n        _2965 = _2956;\n    }\n    bool _2974;\n    if (!_2965)\n    {\n        _2974 = _2951.y < _2840.y;\n    }\n    else\n    {\n        _2974 = _2965;\n    }\n    bool _2983;\n    if (!_2974)\n    {\n        _2983 = _2951.y > _2840.w;\n    }\n    else\n    {\n        _2983 = _2974;\n    }\n    if (_2983)\n    {\n        return 1.0;\n    }\n    float _2989 = _2777.x;\n    float _2991;\n    if (_2989 > 0.0)\n    {\n        _2991 = _2989;\n    }\n    else\n    {\n        _2991 = 1.5 * _2857;\n    }\n    vec2 param_9 = _2951;\n    vec4 param_10 = _2840;\n    float param_11 = _2933 - (_2991 * (1.0 + (0.5 * _2904)));\n    float param_12 = _2857;\n    float param_13 = 1.0;\n    float param_14 = _2845.z * 0.25;\n    float param_15 = (_2857 * min(_2904, 3.0)) * 0.5;\n    vec3 param_16 = vec3(1.0, _2936, _2845.z);\n    int param_17 = int(_2772.z + 0.5);\n    float param_18 = _2772.w;\n    return mix(1.0, fa_shadow_filter(param_9, param_10, param_11, param_12, param_13, param_14, param_15, param_16, param_17, param_18), fade);\n}\n\nfloat fa_contact_shadow(int li, vec3 world, vec3 gn, vec3 l, float dist)\n{\n    bool _5132 = fa_mesh_fs_params[24].x < 0.5;\n    bool _5139;\n    if (!_5132)\n    {\n        _5139 = fa_shadows[29].x < 0.5;\n    }\n    else\n    {\n        _5139 = _5132;\n    }\n    if (_5139)\n    {\n        return 1.0;\n    }\n    int param = (int(fa_shadows[29].x + 0.5) - 1) + li;\n    vec4 _5152 = fa_light_texel(param);\n    float _5153 = _5152.y;\n    float len = _5153;\n    if (_5153 <= 0.0)\n    {\n        return 1.0;\n    }\n    float _5165 = length(world - fa_mesh_fs_params[0].xyz);\n    float _5175 = 1.0 - smoothstep(0.5 * fa_mesh_fs_params[25].x, fa_mesh_fs_params[25].x, _5165);\n    if (_5175 <= 0.0)\n    {\n        return 1.0;\n    }\n    float _5181 = len;\n    float _5184 = min(_5181, 0.89999997615814208984375 * dist);\n    len = _5184;\n    float _5189 = 0.004999999888241291046142578125 + (0.0030000000260770320892333984375 * _5165);\n    float _5194 = _5189 + (0.5 * _5184);\n    vec3 _5200 = world + (gn * _5189);\n    float _5202 = fa_shadow_noise();\n    float occ = 0.0;\n    float _5266;\n    for (int k = 0; k < 12; k++)\n    {\n        float _5217 = (float(k) + _5202) * 0.083333335816860198974609375;\n        vec3 _5225 = _5200 + (l * (_5217 * len));\n        vec4 _5231 = vec4(_5225, 1.0);\n        float _5237 = dot(fa_mesh_fs_params[28], _5231);\n        if (_5237 < 9.9999997473787516355514526367188e-05)\n        {\n            break;\n        }\n        vec2 _5257 = vec2(dot(fa_mesh_fs_params[26], _5231), dot(fa_mesh_fs_params[27], _5231)) / vec2(_5237);\n        float _5261 = _5257.x * 0.5;\n        float _5262 = _5261 + 0.5;\n        if (fa_mesh_fs_params[24].y > 0.5)\n        {\n            _5266 = (_5257.y * 0.5) + 0.5;\n        }\n        else\n        {\n            _5266 = 0.5 - (_5257.y * 0.5);\n        }\n        bool _5282 = _5262 < 0.0;\n        bool _5289;\n        if (!_5282)\n        {\n            _5289 = _5262 >= 1.0;\n        }\n        else\n        {\n            _5289 = _5282;\n        }\n        bool _5296;\n        if (!_5289)\n        {\n            _5296 = _5266 < 0.0;\n        }\n        else\n        {\n            _5296 = _5289;\n        }\n        bool _5303;\n        if (!_5296)\n        {\n            _5303 = _5266 >= 1.0;\n        }\n        else\n        {\n            _5303 = _5296;\n        }\n        if (_5303)\n        {\n            break;\n        }\n        vec4 _5322 = texelFetch(fa_screen_tex_fa_shadow_smp, ivec2(vec2(_5262, _5266) * fa_mesh_fs_params[24].zw), 0);\n        if (_5322.w < 0.5)\n        {\n            continue;\n        }\n        float _5341 = (dot(fa_mesh_fs_params[29].xyz, _5225) + fa_mesh_fs_params[29].w) - _5322.x;\n        if ((_5341 > _5189) && (_5341 < _5194))\n        {\n            occ = max(occ, (1.0 - (_5217 * _5217)) * smoothstep(0.0, 0.0500000007450580596923828125, min(min(_5262, 0.5 - _5261), min(_5266, 1.0 - _5266))));\n        }\n    }\n    return 1.0 - (occ * _5175);\n}\n\nLightSample fa_light_shadowed(int li, vec3 world_pos, vec3 gn)\n{\n    int param = li;\n    float _5807 = fa_baked_keep(param);\n    if (_5807 <= 0.0)\n    {\n        int param_1 = li;\n        return LightSample(vec3(0.0, 1.0, 0.0), vec3(0.0), 0.0, 1.0, 0.0, int(fa_light_type(param_1) + 0.5));\n    }\n    int param_2 = li;\n    vec3 param_3 = world_pos;\n    vec3 param_4 = gn;\n    LightSample _5833 = fa_light_sample_n(param_2, param_3, param_4);\n    vec3 _8357 = _5833.color;\n    float _8358 = _5833.attenuation;\n    float _8359 = _5833.shadow;\n    bool _5836 = _5833.type == 0;\n    if (_5836 && (li == 0))\n    {\n        vec3 param_5 = gn;\n        vec3 param_6 = _5833.direction;\n        float _5847 = fa_shadow_factor(param_5, param_6);\n        _8359 = _5847;\n        _8357 *= _5847;\n    }\n    else\n    {\n        bool _5858 = _5833.type != 0;\n        bool _5864;\n        if (_5858)\n        {\n            _5864 = _8358 > 0.0;\n        }\n        else\n        {\n            _5864 = _5858;\n        }\n        if (_5864)\n        {\n            int param_7 = li;\n            int param_8 = fa_light_base(param_7);\n            int param_9 = li;\n            vec3 param_10 = fa_light_texel(param_8).xyz;\n            vec3 param_11 = world_pos;\n            vec3 param_12 = gn;\n            vec3 param_13 = _5833.direction;\n            float _5883 = fa_shadow_local(param_9, param_10, param_11, param_12, param_13);\n            _8359 = _5883;\n            _8357 *= _5883;\n        }\n    }\n    bool _5893 = fa_mesh_fs_params[24].x > 0.5;\n    bool _5899;\n    if (_5893)\n    {\n        _5899 = _8358 > 0.0;\n    }\n    else\n    {\n        _5899 = _5893;\n    }\n    if (_5899)\n    {\n        float _5906;\n        if (_5836)\n        {\n            _5906 = 1000000000.0;\n        }\n        else\n        {\n            _5906 = _5833._distance;\n        }\n        int param_14 = li;\n        vec3 param_15 = world_pos;\n        vec3 param_16 = gn;\n        vec3 param_17 = _5833.direction;\n        float param_18 = _5906;\n        float _5924 = fa_contact_shadow(param_14, param_15, param_16, param_17, param_18);\n        _8359 *= _5924;\n        _8357 *= _5924;\n    }\n    float _5937 = _8358;\n    float _5938 = _5937 * _5807;\n    _8358 = _5938;\n    vec3 _5942 = _8357;\n    vec3 _5943 = _5942 * _5807;\n    _8357 = _5943;\n    return LightSample(_5833.direction, _5943, _5938, _8359, _5833._distance, _5833.type);\n}\n\nvec3 fa_ltc_tangent(vec3 n, vec3 v)\n{\n    vec3 _5977 = v - (n * dot(v, n));\n    vec3 t = _5977;\n    float _5981 = dot(_5977, _5977);\n    float l2 = _5981;\n    if (_5981 < 1.0000000133514319600180897396058e-10)\n    {\n        vec3 _5991;\n        if (abs(n.z) < 0.999000012874603271484375)\n        {\n            _5991 = cross(n, vec3(0.0, 0.0, 1.0));\n        }\n        else\n        {\n            _5991 = cross(n, vec3(1.0, 0.0, 0.0));\n        }\n        t = _5991;\n        l2 = dot(_5991, _5991);\n    }\n    return t * inversesqrt(l2);\n}\n\nvec3 fa_ltc_local(vec3 t1, vec3 n, vec3 p)\n{\n    return vec3(dot(t1, p), dot(cross(n, t1), p), dot(n, p));\n}\n\nvec3 fa_ltc_edge_vector(vec3 a, vec3 b)\n{\n    float _6026 = dot(a, a);\n    float _6030 = dot(b, b);\n    if ((_6026 < 1.0000000195414813782625560981111e-24) || (_6030 < 1.0000000195414813782625560981111e-24))\n    {\n        return vec3(0.0);\n    }\n    vec3 _6044 = a * inversesqrt(_6026);\n    vec3 _6049 = b * inversesqrt(_6030);\n    float _6053 = dot(_6044, _6049);\n    float _6056 = abs(_6053);\n    float g = (((((((((((0.0416471660137176513671875 * _6056) - 0.1924748718738555908203125) * _6056) + 0.4179156124591827392578125) * _6056) - 0.616057217121124267578125) * _6056) + 0.777722418308258056640625) * _6056) - 0.999542415142059326171875) * _6056) + 1.570791721343994140625;\n    if (_6053 < 0.0)\n    {\n        g = (3.1415927410125732421875 * inversesqrt(max(1.0 - (_6053 * _6053), 1.0000000116860974230803549289703e-07))) - g;\n    }\n    return cross(_6044, _6049) * g;\n}\n\nvoid fa_ltc_clip_edge(vec3 a, vec3 b, inout vec3 sum, inout vec3 leave, inout vec3 enter, inout vec2 seen)\n{\n    bool _6113 = a.z > 0.0;\n    bool _6117 = b.z > 0.0;\n    if (_6113 && _6117)\n    {\n        vec3 param = a;\n        vec3 param_1 = b;\n        sum += fa_ltc_edge_vector(param, param_1);\n    }\n    else\n    {\n        if (_6113 != _6117)\n        {\n            vec3 _6152 = a + ((b - a) * (a.z / (a.z - b.z)));\n            _6152.z = 0.0;\n            if (_6113)\n            {\n                vec3 param_2 = a;\n                vec3 param_3 = _6152;\n                sum += fa_ltc_edge_vector(param_2, param_3);\n                leave = _6152;\n                seen.x = 1.0;\n            }\n            else\n            {\n                vec3 param_4 = _6152;\n                vec3 param_5 = b;\n                sum += fa_ltc_edge_vector(param_4, param_5);\n                enter = _6152;\n                seen.y = 1.0;\n            }\n        }\n    }\n}\n\nfloat fa_ltc_quad(vec4 abcd, vec3 p0, vec3 p1, vec3 p2, vec3 p3)\n{\n    vec3 _6201 = vec3((abcd.x * p0.x) + (abcd.y * p0.z), p0.y, (abcd.z * p0.x) + (abcd.w * p0.z));\n    vec3 _6227 = vec3((abcd.x * p1.x) + (abcd.y * p1.z), p1.y, (abcd.z * p1.x) + (abcd.w * p1.z));\n    vec3 _6253 = vec3((abcd.x * p2.x) + (abcd.y * p2.z), p2.y, (abcd.z * p2.x) + (abcd.w * p2.z));\n    vec3 _6279 = vec3((abcd.x * p3.x) + (abcd.y * p3.z), p3.y, (abcd.z * p3.x) + (abcd.w * p3.z));\n    vec3 sum = vec3(0.0);\n    vec3 leave = vec3(0.0);\n    vec3 enter = vec3(0.0);\n    vec3 param = _6201;\n    vec3 param_1 = _6227;\n    vec3 param_2 = vec3(0.0);\n    vec3 param_3 = vec3(0.0);\n    vec3 param_4 = vec3(0.0);\n    vec2 param_5 = vec2(0.0);\n    fa_ltc_clip_edge(param, param_1, param_2, param_3, param_4, param_5);\n    sum = param_2;\n    leave = param_3;\n    enter = param_4;\n    vec3 param_6 = _6227;\n    vec3 param_7 = _6253;\n    vec3 param_8 = param_2;\n    vec3 param_9 = param_3;\n    vec3 param_10 = param_4;\n    vec2 param_11 = param_5;\n    fa_ltc_clip_edge(param_6, param_7, param_8, param_9, param_10, param_11);\n    sum = param_8;\n    leave = param_9;\n    enter = param_10;\n    vec3 param_12 = _6253;\n    vec3 param_13 = _6279;\n    vec3 param_14 = param_8;\n    vec3 param_15 = param_9;\n    vec3 param_16 = param_10;\n    vec2 param_17 = param_11;\n    fa_ltc_clip_edge(param_12, param_13, param_14, param_15, param_16, param_17);\n    sum = param_14;\n    leave = param_15;\n    enter = param_16;\n    vec3 param_18 = _6279;\n    vec3 param_19 = _6201;\n    vec3 param_20 = param_14;\n    vec3 param_21 = param_15;\n    vec3 param_22 = param_16;\n    vec2 param_23 = param_17;\n    fa_ltc_clip_edge(param_18, param_19, param_20, param_21, param_22, param_23);\n    sum = param_20;\n    leave = param_21;\n    enter = param_22;\n    if ((param_23.x * param_23.y) > 0.5)\n    {\n        vec3 param_24 = leave;\n        vec3 param_25 = enter;\n        sum += fa_ltc_edge_vector(param_24, param_25);\n    }\n    return sum.z * 0.15915493667125701904296875;\n}\n\nfloat fa_ltc_rect(vec4 abcd, vec3 center, vec3 ex, vec3 ey)\n{\n    vec4 param = abcd;\n    vec3 param_1 = (center - ex) - ey;\n    vec3 param_2 = (center + ex) - ey;\n    vec3 param_3 = (center + ex) + ey;\n    vec3 param_4 = (center - ex) + ey;\n    return abs(fa_ltc_quad(param, param_1, param_2, param_3, param_4));\n}\n\nfloat fa_area_form(vec4 m, float shape, vec3 pc, vec3 ex, vec3 ey)\n{\n    if ((shape < 0.5) || (shape > 1.5))\n    {\n        vec4 param = m;\n        vec3 param_1 = pc;\n        vec3 param_2 = ex;\n        vec3 param_3 = ey;\n        return fa_ltc_rect(param, param_1, param_2, param_3);\n    }\n    vec3 _6428 = (pc + (ex * 0.92387950420379638671875)) + (ey * 0.3826834261417388916015625);\n    vec3 _6452 = (pc - (ex * 0.92387950420379638671875)) + (ey * 0.3826834261417388916015625);\n    vec3 _6468 = (pc - (ex * 0.3826834261417388916015625)) - (ey * 0.92387950420379638671875);\n    vec4 param_4 = m;\n    vec3 param_5 = _6428;\n    vec3 param_6 = (pc + (ex * 0.3826834261417388916015625)) + (ey * 0.92387950420379638671875);\n    vec3 param_7 = (pc - (ex * 0.3826834261417388916015625)) + (ey * 0.92387950420379638671875);\n    vec3 param_8 = _6452;\n    vec4 param_9 = m;\n    vec3 param_10 = _6428;\n    vec3 param_11 = _6452;\n    vec3 param_12 = (pc - (ex * 0.92387950420379638671875)) - (ey * 0.3826834261417388916015625);\n    vec3 param_13 = _6468;\n    vec4 param_14 = m;\n    vec3 param_15 = _6428;\n    vec3 param_16 = _6468;\n    vec3 param_17 = (pc + (ex * 0.3826834261417388916015625)) - (ey * 0.92387950420379638671875);\n    vec3 param_18 = (pc + (ex * 0.92387950420379638671875)) - (ey * 0.3826834261417388916015625);\n    return abs((fa_ltc_quad(param_4, param_5, param_6, param_7, param_8) + fa_ltc_quad(param_9, param_10, param_11, param_12, param_13)) + fa_ltc_quad(param_14, param_15, param_16, param_17, param_18));\n}\n\nvec2 fa_ltc_uv(float roughness, float ndv)\n{\n    return ((vec2(clamp((roughness - 0.0500000007450580596923828125) * 1.0526316165924072265625, 0.0, 1.0), sqrt(clamp(1.0 - ndv, 0.0, 1.0))) * 63.0) + vec2(0.5)) * vec2(0.015625);\n}\n\nvec3 fa_area_shade(int li, vec3 world_pos, vec3 n, vec3 v, vec3 diffuse_color, vec3 f0, float f90, float roughness, float ndv, float window)\n{\n    int param = li;\n    int _6526 = fa_light_base(param);\n    int param_1 = _6526;\n    int param_2 = _6526 + 1;\n    int param_3 = _6526 + 2;\n    int param_4 = _6526 + 4;\n    vec4 _6548 = fa_light_texel(param_4);\n    int param_5 = _6526 + 5;\n    vec4 _6553 = fa_light_texel(param_5);\n    int param_6 = _6526 + 6;\n    vec4 _6558 = fa_light_texel(param_6);\n    float _6559 = _6558.w;\n    vec3 _6564 = fa_light_texel(param_1).xyz - world_pos;\n    bool _6566 = _6559 < 1.5;\n    bool _6573;\n    if (_6566)\n    {\n        _6573 = dot(normalize(fa_light_texel(param_3).xyz), _6564) >= 0.0;\n    }\n    else\n    {\n        _6573 = _6566;\n    }\n    if (_6573)\n    {\n        return vec3(0.0);\n    }\n    bool _6582 = (_6559 > 0.5) && _6566;\n    float _6586 = _6582 ? 1.0539000034332275390625 : 1.0;\n    vec3 _6589 = _6548.xyz;\n    float _6591 = _6548.w;\n    vec3 _6597 = _6553.xyz;\n    float _6599 = _6553.w;\n    vec3 up = _6597 * (_6599 * _6586);\n    float _6605;\n    if (_6582)\n    {\n        _6605 = (3.1415927410125732421875 * _6591) * _6591;\n    }\n    else\n    {\n        _6605 = (4.0 * _6591) * _6599;\n    }\n    if (_6559 > 1.5)\n    {\n        vec3 _6631 = cross(_6589, -_6564);\n        vec3 perp = _6631;\n        float _6635 = dot(_6631, _6631);\n        vec3 _6638;\n        if (_6635 > 1.0000000133514319600180897396058e-10)\n        {\n            _6638 = perp * inversesqrt(_6635);\n        }\n        else\n        {\n            _6638 = _6597;\n        }\n        perp = _6638;\n        up = _6638 * _6599;\n    }\n    float _6659 = max(_6605, 9.9999999747524270787835121154785e-07);\n    vec3 param_7 = n;\n    vec3 param_8 = v;\n    vec3 _6669 = fa_ltc_tangent(param_7, param_8);\n    vec3 param_9 = _6669;\n    vec3 param_10 = n;\n    vec3 param_11 = _6564;\n    vec3 _6677 = fa_ltc_local(param_9, param_10, param_11);\n    vec3 param_12 = _6669;\n    vec3 param_13 = n;\n    vec3 param_14 = _6589 * (_6591 * _6586);\n    vec3 _6685 = fa_ltc_local(param_12, param_13, param_14);\n    vec3 param_15 = _6669;\n    vec3 param_16 = n;\n    vec3 param_17 = up;\n    vec3 _6693 = fa_ltc_local(param_15, param_16, param_17);\n    vec4 param_18 = vec4(1.0, 0.0, 0.0, 1.0);\n    float param_19 = _6559;\n    vec3 param_20 = _6677;\n    vec3 param_21 = _6685;\n    vec3 param_22 = _6693;\n    float param_23 = roughness;\n    float param_24 = ndv;\n    vec2 _6712 = fa_ltc_uv(param_23, param_24) * 64.0;\n    vec2 param_25 = _6712;\n    vec2 param_26 = _6712 + vec2(64.0, 0.0);\n    vec4 _6722 = fa_atlas_fetch(param_26);\n    vec4 param_27 = fa_atlas_fetch(param_25);\n    float param_28 = _6559;\n    vec3 param_29 = _6677;\n    vec3 param_30 = _6685;\n    vec3 param_31 = _6693;\n    return (((diffuse_color * fa_area_form(param_18, param_19, param_20, param_21, param_22)) + (((f0 * _6722.x) + ((vec3(f90) - f0) * _6722.y)) * fa_area_form(param_27, param_28, param_29, param_30, param_31))) * fa_light_texel(param_2).xyz) * ((((3.1415927410125732421875 * dot(_6564, _6564)) + _6659) / _6659) * window);\n}\n\nvec3 fa_light_rgb(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 1;\n    return fa_light_texel(param_1).xyz;\n}\n\nfloat fa_d_charlie(float alpha, float ndh)\n{\n    float _4869 = 1.0 / alpha;\n    return ((2.0 + _4869) * pow(sqrt(max(1.0 - (ndh * ndh), 9.9999997473787516355514526367188e-05)), _4869)) * 0.15915493667125701904296875;\n}\n\nfloat fa_v_ashikhmin(float ndl, float ndv)\n{\n    return clamp(0.25 / max((ndl + ndv) - (ndl * ndv), 9.9999997473787516355514526367188e-05), 0.0, 1.0);\n}\n\nfloat fa_layers_coat(FaLayers L, vec3 l, vec3 h, float vdh)\n{\n    float _4904 = max(dot(L.nc, l), 0.0);\n    float _4910 = max(dot(L.nc, h), 0.0);\n    float _4919 = ((_4910 * _4910) * (L.coat_a2 - 1.0)) + 1.0;\n    return (((L.coat * (0.039999999105930328369140625 + (0.959999978542327880859375 * pow(clamp(1.0 - vdh, 0.0, 1.0), 5.0)))) * (((L.coat_a2 / ((3.1415927410125732421875 * _4919) * _4919)) * (0.5 / max(mix((2.0 * _4904) * L.coat_ndv, _4904 + L.coat_ndv, L.coat_alpha), 9.9999997473787516355514526367188e-05))) * 3.1415927410125732421875)) * step(9.9999997473787516355514526367188e-05, _4904)) * _4904;\n}\n\nvec3 fa_area_layers(FaLayers L, int li, vec3 world_pos, vec3 n, vec3 v, vec3 l, vec3 diffuse_color, vec3 f0, float roughness, float ndv, float window)\n{\n    int param = li;\n    vec3 param_1 = world_pos;\n    vec3 param_2 = n;\n    vec3 param_3 = v;\n    vec3 param_4 = diffuse_color;\n    vec3 param_5 = f0;\n    float param_6 = L.f90;\n    float param_7 = roughness;\n    float param_8 = ndv;\n    float param_9 = window;\n    float _6790;\n    if (L.sheen_on)\n    {\n        _6790 = L.sheen_scale;\n    }\n    else\n    {\n        _6790 = 1.0;\n    }\n    vec3 result = fa_area_shade(param, param_1, param_2, param_3, param_4, param_5, param_6, param_7, param_8, param_9) * (L.keep * _6790);\n    vec3 _6803 = normalize(l + v);\n    int param_10 = li;\n    vec3 _6814 = fa_light_rgb(param_10) * window;\n    if (L.sheen_on)\n    {\n        float _6823 = max(dot(n, l), 0.0);\n        float param_11 = L.sheen_alpha;\n        float param_12 = max(dot(n, _6803), 0.0);\n        float param_13 = _6823;\n        float param_14 = ndv;\n        result += ((L.sheen * _6814) * (((((fa_d_charlie(param_11, param_12) * fa_v_ashikhmin(param_13, param_14)) * 3.1415927410125732421875) * step(9.9999997473787516355514526367188e-05, _6823)) * _6823) * L.keep));\n    }\n    if (L.coat > 0.0)\n    {\n        FaLayers param_15 = L;\n        vec3 param_16 = l;\n        vec3 param_17 = _6803;\n        float param_18 = max(dot(v, _6803), 0.0);\n        result += (_6814 * fa_layers_coat(param_15, param_16, param_17, param_18));\n    }\n    return result;\n}\n\nfloat fa_d_ggx_aniso(float ndh, float tdh, float bdh, float at, float ab)\n{\n    float _4772 = tdh / at;\n    float _4776 = bdh / ab;\n    float _4788 = ((_4772 * _4772) + (_4776 * _4776)) + (ndh * ndh);\n    return 1.0 / ((((3.1415927410125732421875 * at) * ab) * _4788) * _4788);\n}\n\nfloat fa_lambda_ggx_aniso(float n, float t, float b, float at, float ab)\n{\n    return 0.5 * (sqrt(1.0 + (((((at * at) * t) * t) + (((ab * ab) * b) * b)) / max(n * n, 9.9999999392252902907785028219223e-09))) - 1.0);\n}\n\nfloat fa_v_ggx_aniso(float ndl, float ndv, float tdv, float bdv, float tdl, float bdl, float at, float ab)\n{\n    float param = ndv;\n    float param_1 = tdv;\n    float param_2 = bdv;\n    float param_3 = at;\n    float param_4 = ab;\n    float param_5 = ndl;\n    float param_6 = tdl;\n    float param_7 = bdl;\n    float param_8 = at;\n    float param_9 = ab;\n    return clamp(1.0 / ((4.0 * max(ndl * ndv, 9.9999997473787516355514526367188e-05)) * ((1.0 + fa_lambda_ggx_aniso(param, param_1, param_2, param_3, param_4)) + fa_lambda_ggx_aniso(param_5, param_6, param_7, param_8, param_9))), 0.0, 1.0);\n}\n\nvec3 fa_layers_light(FaLayers L, vec3 diffuse_color, vec3 f0, vec3 n, vec3 v, vec3 l, vec3 h, float ndl, float ndv, float ndh, float vdh, float alpha, float a2)\n{\n    float _4968 = step(9.9999997473787516355514526367188e-05, ndl);\n    float d_ggx;\n    float vis;\n    if (L.aniso != 0.0)\n    {\n        float param = ndh;\n        float param_1 = dot(L.t, h);\n        float param_2 = dot(L.b, h);\n        float param_3 = L.at;\n        float param_4 = L.ab;\n        d_ggx = fa_d_ggx_aniso(param, param_1, param_2, param_3, param_4);\n        float param_5 = ndl;\n        float param_6 = ndv;\n        float param_7 = dot(L.t, v);\n        float param_8 = dot(L.b, v);\n        float param_9 = dot(L.t, l);\n        float param_10 = dot(L.b, l);\n        float param_11 = L.at;\n        float param_12 = L.ab;\n        vis = fa_v_ggx_aniso(param_5, param_6, param_7, param_8, param_9, param_10, param_11, param_12);\n    }\n    else\n    {\n        float _5047 = ((ndh * ndh) * (a2 - 1.0)) + 1.0;\n        d_ggx = a2 / ((3.1415927410125732421875 * _5047) * _5047);\n        vis = 0.5 / max(mix((2.0 * ndl) * ndv, ndl + ndv, alpha), 9.9999997473787516355514526367188e-05);\n    }\n    vec3 base = diffuse_color + (((f0 + ((vec3(L.f90) - f0) * pow(clamp(1.0 - vdh, 0.0, 1.0), 5.0))) * ((d_ggx * vis) * 3.1415927410125732421875)) * _4968);\n    if (L.sheen_on)\n    {\n        float param_13 = L.sheen_alpha;\n        float param_14 = ndh;\n        float param_15 = ndl;\n        float param_16 = ndv;\n        base = (base * L.sheen_scale) + (L.sheen * (((fa_d_charlie(param_13, param_14) * fa_v_ashikhmin(param_15, param_16)) * 3.1415927410125732421875) * _4968));\n    }\n    vec3 result = base * (L.keep * ndl);\n    if (L.coat > 0.0)\n    {\n        FaLayers param_17 = L;\n        vec3 param_18 = l;\n        vec3 param_19 = h;\n        float param_20 = vdh;\n        result += vec3(fa_layers_coat(param_17, param_18, param_19, param_20));\n    }\n    return result;\n}\n\nvec2 fa_env_brdf(float rough, float ndv)\n{\n    vec4 _4178 = (vec4(-1.0, -0.0274999998509883880615234375, -0.572000026702880859375, 0.02199999988079071044921875) * rough) + vec4(1.0, 0.0425000004470348358154296875, 1.03999996185302734375, -0.039999999105930328369140625);\n    float _4181 = _4178.x;\n    return (vec2(-1.03999996185302734375, 1.03999996185302734375) * ((min(_4181 * _4181, exp2((-9.27999973297119140625) * ndv)) * _4181) + _4178.y)) + _4178.zw;\n}\n\nvec2 fa_oct_encode(vec3 d)\n{\n    vec3 _3437 = d / vec3(max((abs(d.x) + abs(d.y)) + abs(d.z), 9.9999999600419720025001879548654e-13));\n    float _3440 = _3437.x;\n    float _3442 = _3437.z;\n    vec2 e = vec2(_3440, _3442);\n    if (_3437.y < 0.0)\n    {\n        e = vec2((1.0 - abs(_3442)) * ((_3440 < 0.0) ? (-1.0) : 1.0), (1.0 - abs(_3440)) * ((_3442 < 0.0) ? (-1.0) : 1.0));\n    }\n    return e;\n}\n\nvec3 fa_probe_level(vec2 origin, float res, int lv, vec2 e)\n{\n    float _3489;\n    if (lv == 0)\n    {\n        _3489 = 0.0;\n    }\n    else\n    {\n        _3489 = res + 2.0;\n    }\n    float _3499;\n    if (lv == 0)\n    {\n        _3499 = 0.0;\n    }\n    else\n    {\n        _3499 = (res - (res / float(1 << (lv - 1)))) + (2.0 * float(lv - 1));\n    }\n    return textureLod(fa_probe_atlas_fa_env_smp, (((origin + vec2(_3489, _3499)) + vec2(1.0)) + (((e * 0.5) + vec2(0.5)) * (res / float(1 << lv)))) / fa_atlas_size(), 0.0).xyz;\n}\n\nvec3 fa_probe_radiance(vec2 origin, float res, vec3 d, float rough)\n{\n    float _3544;\n    if (res > 64.5)\n    {\n        _3544 = 5.0;\n    }\n    else\n    {\n        _3544 = (res > 32.5) ? 4.0 : 3.0;\n    }\n    float _3559 = clamp(rough, 0.0, 1.0) * (_3544 - 1.0);\n    int _3566 = int(min(floor(_3559), _3544 - 2.0));\n    float _3571 = _3559 - float(_3566);\n    vec3 param = d;\n    vec2 _3575 = fa_oct_encode(param);\n    vec2 param_1 = origin;\n    float param_2 = res;\n    int param_3 = _3566;\n    vec2 param_4 = _3575;\n    vec3 _3585 = fa_probe_level(param_1, param_2, param_3, param_4);\n    if (_3571 < 0.00200000009499490261077880859375)\n    {\n        return _3585;\n    }\n    vec2 param_5 = origin;\n    float param_6 = res;\n    int param_7 = _3566 + 1;\n    vec2 param_8 = _3575;\n    return mix(_3585, fa_probe_level(param_5, param_6, param_7, param_8), vec3(_3571));\n}\n\nvec3 fa_probe_box_dir(vec3 d, vec4 posw, vec4 bx, vec4 by, vec4 bz)\n{\n    if (posw.w < 0.5)\n    {\n        return d;\n    }\n    float _3655 = dot(bx.xyz, fa_world_pos) + bx.w;\n    float _3662 = dot(by.xyz, fa_world_pos) + by.w;\n    float _3669 = dot(bz.xyz, fa_world_pos) + bz.w;\n    float _3675 = dot(bx.xyz, d);\n    float _3679 = dot(by.xyz, d);\n    float _3683 = dot(bz.xyz, d);\n    float _3689;\n    if (_3675 > 9.9999999747524270787835121154785e-07)\n    {\n        _3689 = (1.0 - _3655) / _3675;\n    }\n    else\n    {\n        float _3703;\n        if (_3675 < (-9.9999999747524270787835121154785e-07))\n        {\n            _3703 = ((-1.0) - _3655) / _3675;\n        }\n        else\n        {\n            _3703 = 1000000015047466219876688855040.0;\n        }\n        _3689 = _3703;\n    }\n    float tx = _3689;\n    float _3720;\n    if (_3679 > 9.9999999747524270787835121154785e-07)\n    {\n        _3720 = (1.0 - _3662) / _3679;\n    }\n    else\n    {\n        float _3733;\n        if (_3679 < (-9.9999999747524270787835121154785e-07))\n        {\n            _3733 = ((-1.0) - _3662) / _3679;\n        }\n        else\n        {\n            _3733 = 1000000015047466219876688855040.0;\n        }\n        _3720 = _3733;\n    }\n    float ty = _3720;\n    float _3749;\n    if (_3683 > 9.9999999747524270787835121154785e-07)\n    {\n        _3749 = (1.0 - _3669) / _3683;\n    }\n    else\n    {\n        float _3762;\n        if (_3683 < (-9.9999999747524270787835121154785e-07))\n        {\n            _3762 = ((-1.0) - _3669) / _3683;\n        }\n        else\n        {\n            _3762 = 1000000015047466219876688855040.0;\n        }\n        _3749 = _3762;\n    }\n    float _3774 = tx;\n    float _3777 = (_3774 > 0.0) ? _3774 : 1000000015047466219876688855040.0;\n    tx = _3777;\n    float _3778 = ty;\n    float _3781 = (_3778 > 0.0) ? _3778 : 1000000015047466219876688855040.0;\n    ty = _3781;\n    float _3791 = min(_3777, min(_3781, (_3749 > 0.0) ? _3749 : 1000000015047466219876688855040.0));\n    if (_3791 > 100000001504746621987668885504.0)\n    {\n        return d;\n    }\n    vec3 _3807 = (fa_world_pos + (d * _3791)) - posw.xyz;\n    vec3 _3812;\n    if (dot(_3807, _3807) > 1.0000000133514319600180897396058e-10)\n    {\n        _3812 = normalize(_3807);\n    }\n    else\n    {\n        _3812 = d;\n    }\n    return _3812;\n}\n\nvec3 fa_probe_environment(vec4 tile, vec4 posw, vec4 bx, vec4 by, vec4 bz, inout vec3 d, float rough)\n{\n    vec3 param = d;\n    vec4 param_1 = posw;\n    vec4 param_2 = bx;\n    vec4 param_3 = by;\n    vec4 param_4 = bz;\n    d = fa_probe_box_dir(param, param_1, param_2, param_3, param_4);\n    vec2 param_5 = tile.xy;\n    float param_6 = tile.z;\n    vec3 param_7 = d;\n    float param_8 = rough;\n    return fa_probe_radiance(param_5, param_6, param_7, param_8);\n}\n\nvec3 fa_environment(vec3 d, float rough)\n{\n    float _3858 = (1.0 - fa_mesh_fs_params[42].w) - fa_mesh_fs_params[47].w;\n    vec3 outc = vec3(0.0);\n    if (_3858 > 0.0005000000237487256526947021484375)\n    {\n        vec3 base;\n        if (fa_mesh_fs_params[11].w > 0.5)\n        {\n            vec2 param = fa_mesh_fs_params[41].zw;\n            float param_1 = 128.0;\n            vec3 param_2 = d;\n            float param_3 = rough;\n            base = fa_probe_radiance(param, param_1, param_2, param_3);\n        }\n        else\n        {\n            float _3887 = rough * rough;\n            float _3918 = 0.60000002384185791015625 * _3887;\n            base = mix(mix(fa_mesh_fs_params[12].xyz * 0.550000011920928955078125, mix(fa_mesh_fs_params[12].xyz, fa_mesh_fs_params[11].xyz, vec3(pow(clamp(d.y * (1.0 - (0.699999988079071044921875 * _3887)), 0.0, 1.0), 0.550000011920928955078125))), vec3(smoothstep((-0.0500000007450580596923828125) - _3918, 0.0500000007450580596923828125 + _3918, d.y))), ((fa_mesh_fs_params[11].xyz + fa_mesh_fs_params[12].xyz) * 0.5) * 0.800000011920928955078125, vec3(_3887 * 0.60000002384185791015625));\n        }\n        outc = base * _3858;\n    }\n    if (fa_mesh_fs_params[42].w > 0.0)\n    {\n        vec4 param_4 = fa_mesh_fs_params[42];\n        vec4 param_5 = fa_mesh_fs_params[43];\n        vec4 param_6 = fa_mesh_fs_params[44];\n        vec4 param_7 = fa_mesh_fs_params[45];\n        vec4 param_8 = fa_mesh_fs_params[46];\n        vec3 param_9 = d;\n        float param_10 = rough;\n        vec3 _3977 = fa_probe_environment(param_4, param_5, param_6, param_7, param_8, param_9, param_10);\n        outc += (_3977 * fa_mesh_fs_params[42].w);\n    }\n    if (fa_mesh_fs_params[47].w > 0.0)\n    {\n        vec4 param_11 = fa_mesh_fs_params[47];\n        vec4 param_12 = fa_mesh_fs_params[48];\n        vec4 param_13 = fa_mesh_fs_params[49];\n        vec4 param_14 = fa_mesh_fs_params[50];\n        vec4 param_15 = fa_mesh_fs_params[51];\n        vec3 param_16 = d;\n        float param_17 = rough;\n        vec3 _4009 = fa_probe_environment(param_11, param_12, param_13, param_14, param_15, param_16, param_17);\n        outc += (_4009 * fa_mesh_fs_params[47].w);\n    }\n    return outc;\n}\n\nvec3 fa_layers_ibl(FaLayers L, vec3 n, vec3 v, vec3 f0, float roughness)\n{\n    vec3 rn = n;\n    if (L.aniso != 0.0)\n    {\n        vec3 _4655;\n        if (L.aniso >= 0.0)\n        {\n            _4655 = L.b;\n        }\n        else\n        {\n            _4655 = L.t;\n        }\n        rn = normalize(mix(n, cross(cross(_4655, v), _4655), vec3(abs(L.aniso))));\n    }\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05);\n    vec2 _4688 = fa_env_brdf(param, param_1);\n    vec3 param_2 = reflect(-v, rn);\n    float param_3 = roughness;\n    vec3 result = (fa_environment(param_2, param_3) * ((f0 * _4688.x) + (vec3(L.f90) * _4688.y))) * L.base_scale;\n    if (L.sheen_on)\n    {\n        vec3 param_4 = n;\n        float param_5 = L.sheen_rough;\n        result += ((L.sheen * (L.sheen_e * L.keep)) * fa_environment(param_4, param_5));\n    }\n    if (L.coat > 0.0)\n    {\n        float param_6 = L.coat_rough;\n        float param_7 = L.coat_ndv;\n        vec2 _4743 = fa_env_brdf(param_6, param_7);\n        vec3 param_8 = reflect(-v, L.nc);\n        float param_9 = L.coat_rough;\n        result += (fa_environment(param_8, param_9) * (L.coat * ((0.039999999105930328369140625 * _4743.x) + _4743.y)));\n    }\n    return result;\n}\n\nvec3 fa_sky_reflection(vec3 n, vec3 v, vec3 f0, float roughness)\n{\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05);\n    vec2 _4220 = fa_env_brdf(param, param_1);\n    vec3 param_2 = reflect(-v, n);\n    float param_3 = roughness;\n    return fa_environment(param_2, param_3) * ((f0 * _4220.x) + vec3(_4220.y));\n}\n\nvec2 fa_xm_size(int k)\n{\n    return max(floor(fa_mesh_fs_params[24].zw / vec2(exp2(float(k)))), vec2(1.0));\n}\n\nvec2 fa_xm_origin(int k)\n{\n    if (k == 0)\n    {\n        return vec2(0.0);\n    }\n    float y = 0.0;\n    for (int j = 1; j < k; j++)\n    {\n        int param = j;\n        y += fa_xm_size(param).y;\n    }\n    return vec2(fa_mesh_fs_params[24].z, y);\n}\n\nvec3 fa_xm_texel(vec2 size, vec2 origin, vec2 p)\n{\n    return texelFetch(fa_screen_tex_fa_shadow_smp, ivec2(origin + clamp(p, vec2(0.0), size - vec2(1.0))), 0).xyz;\n}\n\nvec3 fa_xm_level(int k, vec2 uv)\n{\n    int param = k;\n    vec2 _5445 = fa_xm_size(param);\n    int param_1 = k;\n    vec2 _5449 = fa_xm_origin(param_1);\n    vec2 _5455 = (uv * _5445) - vec2(0.5);\n    vec2 _5458 = fract(_5455);\n    vec2 _5461 = floor(_5455);\n    vec2 param_2 = _5445;\n    vec2 param_3 = _5449;\n    vec2 param_4 = _5461;\n    vec2 param_5 = _5445;\n    vec2 param_6 = _5449;\n    vec2 param_7 = _5461 + vec2(1.0, 0.0);\n    vec2 param_8 = _5445;\n    vec2 param_9 = _5449;\n    vec2 param_10 = _5461 + vec2(0.0, 1.0);\n    vec2 param_11 = _5445;\n    vec2 param_12 = _5449;\n    vec2 param_13 = _5461 + vec2(1.0);\n    vec3 _5503 = vec3(_5458.x);\n    return mix(mix(fa_xm_texel(param_2, param_3, param_4), fa_xm_texel(param_5, param_6, param_7), _5503), mix(fa_xm_texel(param_8, param_9, param_10), fa_xm_texel(param_11, param_12, param_13), _5503), vec3(_5458.y));\n}\n\nvec3 fa_xm_sample(vec2 uv, float lod)\n{\n    float _5522 = max(fa_mesh_fs_params[31].w - 1.0, 0.0);\n    float _5526 = clamp(lod, 0.0, _5522);\n    int _5530 = int(floor(_5526));\n    int param = _5530;\n    vec2 param_1 = uv;\n    vec3 c = fa_xm_level(param, param_1);\n    float _5540 = float(_5530);\n    float _5541 = _5526 - _5540;\n    bool _5543 = _5541 > 0.001000000047497451305389404296875;\n    bool _5550;\n    if (_5543)\n    {\n        _5550 = _5540 < _5522;\n    }\n    else\n    {\n        _5550 = _5543;\n    }\n    if (_5550)\n    {\n        int param_2 = _5530 + 1;\n        vec2 param_3 = uv;\n        c = mix(c, fa_xm_level(param_2, param_3), vec3(_5541));\n    }\n    return c;\n}\n\nvec3 fa_transmitted(Surface s, vec3 n, vec3 v, float roughness, vec3 f0, float f90, float keep, float tr, inout float blend)\n{\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05);\n    vec2 _5576 = fa_env_brdf(param, param_1);\n    vec3 through = ((vec3(1.0) - clamp((f0 * _5576.x) + (vec3(f90) * _5576.y), vec3(0.0), vec3(1.0))) * s.albedo) * (tr * keep);\n    float _5604 = max(s.thickness, 0.0);\n    bool _5609 = _5604 > 0.0;\n    if ((s.attenuation_distance > 0.0) && _5609)\n    {\n        through *= exp((-((-log(clamp(s.attenuation_color, vec3(9.9999997473787516355514526367188e-05), vec3(1.0)))) / vec3(s.attenuation_distance))) * _5604);\n    }\n    bool _5634 = fa_mesh_fs_params[30].w > 1.5;\n    bool _5641;\n    if (!_5634)\n    {\n        _5641 = fa_mesh_fs_params[30].w < 0.5;\n    }\n    else\n    {\n        _5641 = _5634;\n    }\n    if (_5641)\n    {\n        blend = clamp(dot(through, vec3(0.3333333432674407958984375)), 0.0, 0.980000019073486328125);\n        return vec3(0.0);\n    }\n    vec3 world = fa_world_pos;\n    if (_5609)\n    {\n        world += (refract(-v, n, 1.0 / max(s.ior, 1.0)) * _5604);\n    }\n    vec4 _5676 = vec4(world, 1.0);\n    float _5681 = dot(fa_mesh_fs_params[28], _5676);\n    vec2 uv = vec2(0.5);\n    if (_5681 > 9.9999997473787516355514526367188e-05)\n    {\n        vec2 _5699 = vec2(dot(fa_mesh_fs_params[26], _5676), dot(fa_mesh_fs_params[27], _5676)) / vec2(_5681);\n        float _5707;\n        if (fa_mesh_fs_params[24].y > 0.5)\n        {\n            _5707 = (_5699.y * 0.5) + 0.5;\n        }\n        else\n        {\n            _5707 = 0.5 - (_5699.y * 0.5);\n        }\n        uv = vec2((_5699.x * 0.5) + 0.5, _5707);\n    }\n    vec2 param_2 = clamp(uv, vec2(0.0), vec2(1.0));\n    float param_3 = (clamp(roughness, 0.0, 1.0) * clamp((2.0 * s.ior) - 2.0, 0.0, 1.0)) * max(fa_mesh_fs_params[31].w - 1.0, 0.0);\n    return through * fa_xm_sample(param_2, param_3);\n}\n\nvec3 fa_shadow_debug(vec3 color, vec3 world)\n{\n    if (fa_shadows[27].w < 0.5)\n    {\n        return color;\n    }\n    int _3240 = int(fa_shadows[25].x + 0.5);\n    float _3250 = dot(world - fa_shadows[27].xyz, fa_shadows[28].xyz);\n    vec3 tint = vec3(0.3499999940395355224609375);\n    bool _3255 = _3240 > 0;\n    bool _3264;\n    if (_3255)\n    {\n        int param = _3240 - 1;\n        _3264 = _3250 <= fa_shadow_split_at(param);\n    }\n    else\n    {\n        _3264 = _3255;\n    }\n    if (_3264)\n    {\n        tint = vec3(1.0, 0.1500000059604644775390625, 0.100000001490116119384765625);\n        bool _3270 = _3240 > 1;\n        bool _3277;\n        if (_3270)\n        {\n            _3277 = _3250 > fa_shadows[24].x;\n        }\n        else\n        {\n            _3277 = _3270;\n        }\n        if (_3277)\n        {\n            tint = vec3(0.100000001490116119384765625, 0.89999997615814208984375, 0.20000000298023223876953125);\n        }\n        bool _3283 = _3240 > 2;\n        bool _3290;\n        if (_3283)\n        {\n            _3290 = _3250 > fa_shadows[24].y;\n        }\n        else\n        {\n            _3290 = _3283;\n        }\n        if (_3290)\n        {\n            tint = vec3(0.1500000059604644775390625, 0.300000011920928955078125, 1.0);\n        }\n        bool _3296 = _3240 > 3;\n        bool _3303;\n        if (_3296)\n        {\n            _3303 = _3250 > fa_shadows[24].z;\n        }\n        else\n        {\n            _3303 = _3296;\n        }\n        if (_3303)\n        {\n            tint = vec3(1.0, 0.89999997615814208984375, 0.100000001490116119384765625);\n        }\n    }\n    return mix(color, tint, vec3(0.550000011920928955078125));\n}\n\nvoid main()\n{\n    fa_inst_load();\n    vec3 _8016 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _8016 = -_8016;\n    }\n    vec3 _7308 = normalize(fa_mesh_fs_params[0].xyz - fa_world_pos);\n    vec3 param = fa_world_pos;\n    fa_cluster_begin(param);\n    SurfaceInput param_1 = SurfaceInput(fa_world_pos, _8016, fa_world_tangent, fa_uv, fa_vertex_color, _7308, gl_FrontFacing);\n    Surface _7316 = fa_standard_surface(param_1);\n    vec3 _8047 = _7316.albedo;\n    float _8048 = _7316.alpha;\n    vec3 _8049 = _7316.normal;\n    float _8050 = _7316.metallic;\n    float _8051 = _7316.roughness;\n    float _8052 = _7316.occlusion;\n    vec3 _8053 = _7316.emission;\n    float _8054 = _7316.clearcoat;\n    float _8055 = _7316.clearcoat_roughness;\n    vec3 _8056 = _7316.sheen_color;\n    float _8057 = _7316.sheen_roughness;\n    float _8058 = _7316.anisotropy;\n    float _8059 = _7316.anisotropy_rotation;\n    float _8060 = _7316.specular;\n    float _8061 = _7316.ior;\n    vec3 _8062 = _7316.specular_color;\n    float _8063 = _7316.transmission;\n    float _8064 = _7316.thickness;\n    vec3 _8065 = _7316.attenuation_color;\n    float _8066 = _7316.attenuation_distance;\n    SurfaceInput param_2 = SurfaceInput(fa_world_pos, _8016, fa_world_tangent, fa_uv, fa_vertex_color, _7308, gl_FrontFacing);\n    Surface param_3 = _7316;\n    surface(param_2, param_3);\n    _8047 = param_3.albedo;\n    _8048 = param_3.alpha;\n    _8049 = param_3.normal;\n    _8050 = param_3.metallic;\n    _8051 = param_3.roughness;\n    _8052 = param_3.occlusion;\n    _8053 = param_3.emission;\n    _8054 = param_3.clearcoat;\n    _8055 = param_3.clearcoat_roughness;\n    _8056 = param_3.sheen_color;\n    _8057 = param_3.sheen_roughness;\n    _8058 = param_3.anisotropy;\n    _8059 = param_3.anisotropy_rotation;\n    _8060 = param_3.specular;\n    _8061 = param_3.ior;\n    _8062 = param_3.specular_color;\n    _8063 = param_3.transmission;\n    _8064 = param_3.thickness;\n    _8065 = param_3.attenuation_color;\n    _8066 = param_3.attenuation_distance;\n    vec3 param_4 = fa_world_pos;\n    vec3 param_5 = _8016;\n    vec3 param_6 = param_3.albedo;\n    vec3 param_7 = param_3.normal;\n    fa_apply_decals(param_4, param_5, param_6, param_7);\n    _8047 = param_6;\n    _8049 = param_7;\n    float fa_tr_blend = 0.0;\n    vec3 result;\n    if (fa_mesh_fs_params[3].w > 0.5)\n    {\n        result = _8047;\n    }\n    else\n    {\n        vec3 _7356 = normalize(_8049);\n        float _7363 = clamp(_8050, 0.0, 1.0);\n        float _7367 = clamp(_8051, 0.0500000007450580596923828125, 1.0);\n        float _7371 = _7367 * _7367;\n        float _7375 = _7371 * _7371;\n        float _7380 = max(dot(_7356, _7308), 9.9999997473787516355514526367188e-05);\n        float _7386 = 1.0 - _7363;\n        float _7387 = clamp(_8063, 0.0, 1.0) * _7386;\n        vec3 _7396 = (_8047 * _7386) * (1.0 - _7387);\n        vec3 _7403 = mix(vec3(0.039999999105930328369140625), _8047, vec3(_7363));\n        vec3 f0 = _7403;\n        SurfaceInput param_8 = SurfaceInput(fa_world_pos, _8016, fa_world_tangent, fa_uv, fa_vertex_color, _7308, gl_FrontFacing);\n        Surface param_9 = Surface(_8047, _8048, _8049, _8050, _8051, _8052, _8053, _8054, _8055, _8056, _8057, _8058, _8059, _8060, _8061, _8062, _8063, _8064, _8065, _8066);\n        vec3 param_10 = _7356;\n        vec3 param_11 = _7308;\n        float param_12 = _7363;\n        float param_13 = _7367;\n        vec3 param_14 = _7403;\n        FaLayers _7419 = fa_layers_setup(param_8, param_9, param_10, param_11, param_12, param_13, param_14);\n        f0 = param_14;\n        vec3 param_15 = _7356;\n        vec3 lit = (fa_indirect_diffuse(param_15) * _7396) * _8052;\n        if (_7419.on)\n        {\n            lit *= _7419.base_scale;\n        }\n        int _7441 = fa_cl_ndir + fa_cl_local;\n        for (int ln = 0; ln < _7441; ln++)\n        {\n            int param_16 = ln;\n            int _7454 = fa_cl_light(param_16);\n            int param_17 = _7454;\n            if (fa_baked_keep(param_17) <= 0.0)\n            {\n                continue;\n            }\n            int param_18 = _7454;\n            vec3 param_19 = fa_world_pos;\n            vec3 param_20 = _8016;\n            LightSample _7470 = fa_light_shadowed(param_18, param_19, param_20);\n            float _7478 = max(dot(_7356, _7470.direction), 0.0);\n            float _7484 = _7470.attenuation * _7470.shadow;\n            vec3 _7489 = normalize(_7470.direction + _7308);\n            float _7494 = max(dot(_7356, _7489), 0.0);\n            float _7499 = max(dot(_7308, _7489), 0.0);\n            bool _7506;\n            if (fa_light_is_area)\n            {\n                _7506 = !_7419.on;\n            }\n            else\n            {\n                _7506 = fa_light_is_area;\n            }\n            if (_7506)\n            {\n                int param_21 = _7454;\n                vec3 param_22 = fa_world_pos;\n                vec3 param_23 = _7356;\n                vec3 param_24 = _7308;\n                vec3 param_25 = _7396;\n                vec3 param_26 = f0;\n                float param_27 = 1.0;\n                float param_28 = _7367;\n                float param_29 = _7380;\n                float param_30 = _7484;\n                lit += fa_area_shade(param_21, param_22, param_23, param_24, param_25, param_26, param_27, param_28, param_29, param_30);\n            }\n            else\n            {\n                if (fa_light_is_area)\n                {\n                    FaLayers param_31 = _7419;\n                    int param_32 = _7454;\n                    vec3 param_33 = fa_world_pos;\n                    vec3 param_34 = _7356;\n                    vec3 param_35 = _7308;\n                    vec3 param_36 = _7470.direction;\n                    vec3 param_37 = _7396;\n                    vec3 param_38 = f0;\n                    float param_39 = _7367;\n                    float param_40 = _7380;\n                    float param_41 = _7484;\n                    lit += fa_area_layers(param_31, param_32, param_33, param_34, param_35, param_36, param_37, param_38, param_39, param_40, param_41);\n                }\n                else\n                {\n                    if (_7419.on)\n                    {\n                        FaLayers param_42 = _7419;\n                        vec3 param_43 = _7396;\n                        vec3 param_44 = f0;\n                        vec3 param_45 = _7356;\n                        vec3 param_46 = _7308;\n                        vec3 param_47 = _7470.direction;\n                        vec3 param_48 = _7489;\n                        float param_49 = _7478;\n                        float param_50 = _7380;\n                        float param_51 = _7494;\n                        float param_52 = _7499;\n                        float param_53 = _7371;\n                        float param_54 = _7375;\n                        int param_55 = _7454;\n                        lit += (fa_layers_light(param_42, param_43, param_44, param_45, param_46, param_47, param_48, param_49, param_50, param_51, param_52, param_53, param_54) * ((fa_light_rgb(param_55) * fa_light_tint) * _7484));\n                    }\n                    else\n                    {\n                        float _7612 = ((_7494 * _7494) * (_7375 - 1.0)) + 1.0;\n                        int param_56 = _7454;\n                        lit += (((_7396 + (((f0 + ((vec3(1.0) - f0) * pow(1.0 - _7499, 5.0))) * (((_7375 / ((3.1415927410125732421875 * _7612) * _7612)) * (0.5 / max(mix((2.0 * _7478) * _7380, _7478 + _7380, _7371), 9.9999997473787516355514526367188e-05))) * 3.1415927410125732421875)) * step(9.9999997473787516355514526367188e-05, _7478))) * (fa_light_rgb(param_56) * fa_light_tint)) * (_7478 * _7484));\n                    }\n                }\n            }\n        }\n        if (_7419.on)\n        {\n            FaLayers param_57 = _7419;\n            vec3 param_58 = _7356;\n            vec3 param_59 = _7308;\n            vec3 param_60 = f0;\n            float param_61 = _7367;\n            lit += (fa_layers_ibl(param_57, param_58, param_59, param_60, param_61) * _8052);\n        }\n        else\n        {\n            vec3 param_62 = _7356;\n            vec3 param_63 = _7308;\n            vec3 param_64 = f0;\n            float param_65 = _7367;\n            lit += (fa_sky_reflection(param_62, param_63, param_64, param_65) * _8052);\n        }\n        if (_7387 > 0.0)\n        {\n            float _7710;\n            if (_7419.on)\n            {\n                _7710 = _7419.f90;\n            }\n            else\n            {\n                _7710 = 1.0;\n            }\n            float _7718;\n            if (_7419.on)\n            {\n                _7718 = _7419.base_scale;\n            }\n            else\n            {\n                _7718 = 1.0;\n            }\n            Surface param_66 = Surface(_8047, _8048, _8049, _8050, _8051, _8052, _8053, _8054, _8055, _8056, _8057, _8058, _8059, _8060, _8061, _8062, _8063, _8064, _8065, _8066);\n            vec3 param_67 = _7356;\n            vec3 param_68 = _7308;\n            float param_69 = _7367;\n            vec3 param_70 = f0;\n            float param_71 = _7710;\n            float param_72 = _7718;\n            float param_73 = _7387;\n            float param_74 = fa_tr_blend;\n            vec3 _7742 = fa_transmitted(param_66, param_67, param_68, param_69, param_70, param_71, param_72, param_73, param_74);\n            fa_tr_blend = param_74;\n            lit += _7742;\n        }\n        result = lit;\n    }\n    vec3 _7749 = result;\n    vec3 _7750 = _7749 + _8053;\n    result = _7750;\n    vec3 param_75 = _7750;\n    vec3 param_76 = fa_world_pos;\n    result = fa_shadow_debug(param_75, param_76);\n    bool _7759 = fa_mesh_fs_params[7].w > 0.0;\n    bool _7766;\n    if (!_7759)\n    {\n        _7766 = fa_mesh_fs_params[8].y > 0.0;\n    }\n    else\n    {\n        _7766 = _7759;\n    }\n    if (_7766)\n    {\n        vec3 _7775 = fa_world_pos - fa_mesh_fs_params[0].xyz;\n        float _7781 = dot(_7775, fa_mesh_fs_params[9].xyz);\n        bool _7785 = fa_mesh_fs_params[9].w > 0.5;\n        float _7786;\n        if (_7785)\n        {\n            _7786 = _7781;\n        }\n        else\n        {\n            _7786 = length(_7775);\n        }\n        float _7798 = _7786 - fa_mesh_fs_params[8].x;\n        if (_7798 > 0.0)\n        {\n            float _7807 = fa_mesh_fs_params[7].w * _7798;\n            float tau = _7807 * _7807;\n            if (fa_mesh_fs_params[8].y > 0.0)\n            {\n                float _7823;\n                if (_7785)\n                {\n                    _7823 = fa_world_pos.y - (fa_mesh_fs_params[9].y * _7781);\n                }\n                else\n                {\n                    _7823 = fa_mesh_fs_params[0].y;\n                }\n                float _7844 = mix(_7823, fa_world_pos.y, clamp(fa_mesh_fs_params[8].x / _7786, 0.0, 1.0));\n                float _7848 = fa_world_pos.y - _7844;\n                float _7853 = _7844 - fa_mesh_fs_params[8].z;\n                float _7858 = fa_world_pos.y - fa_mesh_fs_params[8].z;\n                bool _7861 = _7853 <= 0.0;\n                bool _7862 = !_7861;\n                bool _7868;\n                if (_7862)\n                {\n                    _7868 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _7868 = _7861;\n                }\n                float _7869;\n                if (_7868)\n                {\n                    _7869 = fa_mesh_fs_params[8].y;\n                }\n                else\n                {\n                    _7869 = fa_mesh_fs_params[8].y * exp(-min(fa_mesh_fs_params[8].w * _7853, 80.0));\n                }\n                bool _7896;\n                if (_7862)\n                {\n                    _7896 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _7896 = _7861;\n                }\n                float _7897;\n                if (_7896)\n                {\n                    _7897 = fa_mesh_fs_params[8].y * _7853;\n                }\n                else\n                {\n                    _7897 = (fa_mesh_fs_params[8].y * (1.0 - exp(-min(fa_mesh_fs_params[8].w * _7853, 80.0)))) / fa_mesh_fs_params[8].w;\n                }\n                bool _7922 = _7858 <= 0.0;\n                bool _7929;\n                if (!_7922)\n                {\n                    _7929 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _7929 = _7922;\n                }\n                float _7930;\n                if (_7929)\n                {\n                    _7930 = fa_mesh_fs_params[8].y * _7858;\n                }\n                else\n                {\n                    _7930 = (fa_mesh_fs_params[8].y * (1.0 - exp(-min(fa_mesh_fs_params[8].w * _7858, 80.0)))) / fa_mesh_fs_params[8].w;\n                }\n                float _7957;\n                if (abs(_7848) < 0.001000000047497451305389404296875)\n                {\n                    _7957 = _7869;\n                }\n                else\n                {\n                    _7957 = (_7930 - _7897) / _7848;\n                }\n                tau += (_7798 * max(_7957, 0.0));\n            }\n            result = mix(result, fa_mesh_fs_params[7].xyz, vec3(clamp(1.0 - exp(-clamp(tau, 0.0, 80.0)), 0.0, 1.0)));\n        }\n    }\n    if (fa_tr_blend > 0.0)\n    {\n        float _7993 = 1.0 - fa_tr_blend;\n        result /= vec3(_7993);\n        _8048 *= _7993;\n    }\n    fa_frag_color = vec4(result, _8048);\n}\n\n",
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
            "slot": 4,
            "stage": "vertex",
            "size": 16,
            "struct_name": "fa_material_vs",
            "inst_name": "_63",
            "glsl_uniforms": [
              {
                "type": "vec4",
                "array_count": 1,
                "offset": 0,
                "glsl_name": "fa_material_vs"
              }
            ]
          },
          {
            "slot": 0,
            "stage": "vertex",
            "size": 176,
            "struct_name": "fa_mesh_vs_params",
            "inst_name": "_160",
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
            "size": 832,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_637",
            "glsl_uniforms": [
              {
                "type": "vec4",
                "array_count": 52,
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
            "inst_name": "_2304",
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
              "slot": 6,
              "stage": "fragment",
              "name": "height",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float"
            }
          },
          {
            "texture": {
              "slot": 10,
              "stage": "vertex",
              "name": "fa_vs_height",
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
            "slot": 6,
            "stage": "vertex",
            "name": "fa_vs_height_smp",
            "sampler_type": "filtering"
          },
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
            "name": "height_smp",
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
            "name": "fa_vs_height_fa_vs_height_smp",
            "view_name": "fa_vs_height",
            "sampler_name": "fa_vs_height_smp",
            "view_slot": 10,
            "sampler_slot": 6,
            "glsl_name": "fa_vs_height_fa_vs_height_smp"
          },
          {
            "slot": 1,
            "stage": "fragment",
            "name": "fa_light_tex_fa_shadow_smp",
            "view_name": "fa_light_tex",
            "sampler_name": "fa_shadow_smp",
            "view_slot": 24,
            "sampler_slot": 1,
            "glsl_name": "fa_light_tex_fa_shadow_smp"
          },
          {
            "slot": 2,
            "stage": "fragment",
            "name": "fa_tex_fa_smp",
            "view_name": "fa_tex",
            "sampler_name": "fa_smp",
            "view_slot": 0,
            "sampler_slot": 0,
            "glsl_name": "fa_tex_fa_smp"
          },
          {
            "slot": 3,
            "stage": "fragment",
            "name": "fa_normal_tex_fa_smp",
            "view_name": "fa_normal_tex",
            "sampler_name": "fa_smp",
            "view_slot": 2,
            "sampler_slot": 0,
            "glsl_name": "fa_normal_tex_fa_smp"
          },
          {
            "slot": 4,
            "stage": "fragment",
            "name": "fa_mr_tex_fa_smp",
            "view_name": "fa_mr_tex",
            "sampler_name": "fa_smp",
            "view_slot": 3,
            "sampler_slot": 0,
            "glsl_name": "fa_mr_tex_fa_smp"
          },
          {
            "slot": 5,
            "stage": "fragment",
            "name": "fa_occlusion_tex_fa_smp",
            "view_name": "fa_occlusion_tex",
            "sampler_name": "fa_smp",
            "view_slot": 4,
            "sampler_slot": 0,
            "glsl_name": "fa_occlusion_tex_fa_smp"
          },
          {
            "slot": 6,
            "stage": "fragment",
            "name": "fa_emissive_tex_fa_smp",
            "view_name": "fa_emissive_tex",
            "sampler_name": "fa_smp",
            "view_slot": 5,
            "sampler_slot": 0,
            "glsl_name": "fa_emissive_tex_fa_smp"
          },
          {
            "slot": 7,
            "stage": "fragment",
            "name": "height_height_smp",
            "view_name": "height",
            "sampler_name": "height_smp",
            "view_slot": 6,
            "sampler_slot": 2,
            "glsl_name": "height_height_smp"
          },
          {
            "slot": 8,
            "stage": "fragment",
            "name": "fa_decal_tex_fa_env_smp",
            "view_name": "fa_decal_tex",
            "sampler_name": "fa_env_smp",
            "view_slot": 27,
            "sampler_slot": 10,
            "glsl_name": "fa_decal_tex_fa_env_smp"
          },
          {
            "slot": 9,
            "stage": "fragment",
            "name": "fa_lightmap_fa_env_smp",
            "view_name": "fa_lightmap",
            "sampler_name": "fa_env_smp",
            "view_slot": 26,
            "sampler_slot": 10,
            "glsl_name": "fa_lightmap_fa_env_smp"
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
          },
          {
            "slot": 11,
            "stage": "fragment",
            "name": "fa_light_atlas_fa_env_smp",
            "view_name": "fa_light_atlas",
            "sampler_name": "fa_env_smp",
            "view_slot": 25,
            "sampler_slot": 10,
            "glsl_name": "fa_light_atlas_fa_env_smp"
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
          },
          {
            "slot": 13,
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
      "vs": "#version 430\n\nstruct VertexData\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 color;\n    vec3 object_pos;\n};\n\nuniform vec4 fa_material_vs[1];\nuniform vec4 fa_mesh_vs_params[11];\nuniform vec4 fa_skin[192];\nlayout(binding = 0) uniform sampler2D fa_vs_height_fa_vs_height_smp;\n\nlayout(location = 0) out vec3 fa_world_pos;\nlayout(location = 1) out vec3 fa_world_normal;\nlayout(location = 2) out vec4 fa_world_tangent;\nlayout(location = 3) out vec2 fa_uv;\nlayout(location = 4) out vec4 fa_vertex_color;\nlayout(location = 5) in vec4 fa_inst_m0;\nlayout(location = 6) in vec4 fa_inst_m1;\nlayout(location = 7) in vec4 fa_inst_m2;\nlayout(location = 8) in vec4 fa_inst_m3;\nlayout(location = 9) in vec4 fa_joints;\nlayout(location = 10) in vec4 fa_weights;\nlayout(location = 0) in vec3 fa_position;\nlayout(location = 1) in vec3 fa_normal;\nlayout(location = 3) in vec4 fa_tangent;\nlayout(location = 2) in vec2 fa_texcoord0;\nlayout(location = 4) in vec4 fa_color;\nlayout(location = 5) out vec3 fa_lm;\n\nvoid fa_inst_begin()\n{\n}\n\nmat4 fa_skin_matrix(vec4 joints, vec4 weights)\n{\n    vec4 r0 = vec4(0.0);\n    vec4 r1 = vec4(0.0);\n    vec4 r2 = vec4(0.0);\n    for (int i = 0; i < 4; i++)\n    {\n        int _203 = int((joints[i] * 255.0) + 0.5) * 3;\n        r0 += (fa_skin[_203 * 1 + 0] * weights[i]);\n        r1 += (fa_skin[(_203 + 1) * 1 + 0] * weights[i]);\n        r2 += (fa_skin[(_203 + 2) * 1 + 0] * weights[i]);\n    }\n    return mat4(vec4(r0.x, r1.x, r2.x, 0.0), vec4(r0.y, r1.y, r2.y, 0.0), vec4(r0.z, r1.z, r2.z, 0.0), vec4(r0.w, r1.w, r2.w, 1.0));\n}\n\nVertexData fa_vertex_data(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    vec3 _108 = cross(model[1].xyz, model[2].xyz);\n    float _113 = (dot(model[0].xyz, _108) < 0.0) ? (-1.0) : 1.0;\n    return VertexData((model * vec4(position, 1.0)).xyz, (((_108 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _113, vec4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _113), texcoord0 * fa_mesh_vs_params[8].xy, color, position);\n}\n\nvoid vertex(inout VertexData v)\n{\n    v.world_pos.y += (textureLod(fa_vs_height_fa_vs_height_smp, v.uv, 0.0).x * fa_material_vs[0].x);\n}\n\nvoid fa_shade_vertex(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    mat4 param = model;\n    vec3 param_1 = position;\n    vec3 param_2 = normal;\n    vec4 param_3 = tangent;\n    vec2 param_4 = texcoord0;\n    vec4 param_5 = color;\n    VertexData param_6 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    vertex(param_6);\n    fa_world_pos = param_6.world_pos;\n    fa_world_normal = param_6.world_normal;\n    fa_world_tangent = param_6.world_tangent;\n    fa_uv = param_6.uv;\n    fa_vertex_color = param_6.color;\n    gl_Position = mat4(fa_mesh_vs_params[0], fa_mesh_vs_params[1], fa_mesh_vs_params[2], fa_mesh_vs_params[3]) * vec4(param_6.world_pos, 1.0);\n}\n\nvoid main()\n{\n    fa_inst_begin();\n    vec4 param = fa_joints;\n    vec4 param_1 = fa_weights;\n    mat4 param_2 = mat4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3) * fa_skin_matrix(param, param_1);\n    vec3 param_3 = fa_position;\n    vec3 param_4 = fa_normal;\n    vec4 param_5 = fa_tangent;\n    vec2 param_6 = fa_texcoord0;\n    vec4 param_7 = fa_color;\n    fa_shade_vertex(param_2, param_3, param_4, param_5, param_6, param_7);\n    fa_lm = vec3(0.0);\n}\n\n",
      "fs": "#version 430\n\nstruct SurfaceInput\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 vertex_color;\n    vec3 view_dir;\n    bool front_facing;\n};\n\nstruct LightSample\n{\n    vec3 direction;\n    vec3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct Surface\n{\n    vec3 albedo;\n    float alpha;\n    vec3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    vec3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    vec3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    vec3 specular_color;\n    float transmission;\n    float thickness;\n    vec3 attenuation_color;\n    float attenuation_distance;\n};\n\nstruct FaLayers\n{\n    bool on;\n    float f90;\n    float keep;\n    float base_scale;\n    float coat;\n    float coat_rough;\n    float coat_alpha;\n    float coat_a2;\n    vec3 nc;\n    float coat_ndv;\n    bool sheen_on;\n    vec3 sheen;\n    float sheen_rough;\n    float sheen_alpha;\n    float sheen_scale;\n    float sheen_e;\n    float aniso;\n    vec3 t;\n    vec3 b;\n    float at;\n    float ab;\n};\n\nconst float _4320[63] = float[](1.0, 1.0, 1.0, 0.4790000021457672119140625, 0.11699999868869781494140625, 0.01200000010430812835693359375, 0.0, 0.0, 0.0, 1.0, 1.0, 1.0, 0.578000009059906005859375, 0.19300000369548797607421875, 0.0350000001490116119384765625, 0.0030000000260770320892333984375, 0.0, 0.0, 1.0, 1.0, 1.0, 0.6740000247955322265625, 0.3459999859333038330078125, 0.1319999992847442626953125, 0.032999999821186065673828125, 0.0040000001899898052215576171875, 0.0, 0.971000015735626220703125, 0.954999983310699462890625, 0.828999996185302734375, 0.63999998569488525390625, 0.42599999904632568359375, 0.24500000476837158203125, 0.115000002086162567138671875, 0.037000000476837158203125, 0.0030000000260770320892333984375, 0.7469999790191650390625, 0.737999975681304931640625, 0.670000016689300537109375, 0.563000023365020751953125, 0.4309999942779541015625, 0.3039999902248382568359375, 0.1940000057220458984375, 0.1019999980926513671875, 0.0309999994933605194091796875, 0.614000022411346435546875, 0.609000027179718017578125, 0.566999971866607666015625, 0.499000012874603271484375, 0.412000000476837158203125, 0.32400000095367431640625, 0.240999996662139892578125, 0.162000000476837158203125, 0.087999999523162841796875, 0.538999974727630615234375, 0.535000026226043701171875, 0.505999982357025146484375, 0.4569999873638153076171875, 0.393999993801116943359375, 0.328999996185302734375, 0.2660000026226043701171875, 0.203999996185302734375, 0.14200000464916229248046875);\n\nuniform vec4 fa_mesh_fs_params[52];\nuniform vec4 fa_shadows[30];\nlayout(binding = 0) uniform sampler2D fa_light_tex_fa_shadow_smp;\nlayout(binding = 1) uniform sampler2D fa_tex_fa_smp;\nlayout(binding = 2) uniform sampler2D fa_normal_tex_fa_smp;\nlayout(binding = 3) uniform sampler2D fa_mr_tex_fa_smp;\nlayout(binding = 4) uniform sampler2D fa_occlusion_tex_fa_smp;\nlayout(binding = 5) uniform sampler2D fa_emissive_tex_fa_smp;\nlayout(binding = 6) uniform sampler2D height_height_smp;\nlayout(binding = 7) uniform sampler2D fa_decal_tex_fa_env_smp;\nlayout(binding = 8) uniform sampler2D fa_lightmap_fa_env_smp;\nlayout(binding = 9) uniform sampler2D fa_probe_atlas_fa_env_smp;\nlayout(binding = 10) uniform sampler2D fa_light_atlas_fa_env_smp;\nlayout(binding = 11) uniform sampler2D fa_shadow_tex_fa_shadow_smp;\nlayout(binding = 12) uniform sampler2D fa_screen_tex_fa_shadow_smp;\n\nlayout(location = 0) in vec3 fa_world_pos;\nlayout(location = 5) in vec3 fa_lm;\nlayout(location = 1) in vec3 fa_world_normal;\nlayout(location = 2) in vec4 fa_world_tangent;\nlayout(location = 3) in vec2 fa_uv;\nlayout(location = 4) in vec4 fa_vertex_color;\nlayout(location = 0) out vec4 fa_frag_color;\nvec3 fa_light_tint;\nbool fa_light_is_area;\nint fa_cl_ndir;\nint fa_cl_slot;\nint fa_cl_local;\n\nvoid fa_inst_load()\n{\n}\n\nvec4 fa_light_texel(int t)\n{\n    return texelFetch(fa_light_tex_fa_shadow_smp, ivec2(t & 1023, t >> 10), 0);\n}\n\nvec4 fa_cluster_texel(vec3 world_pos)\n{\n    bool _1575 = fa_mesh_fs_params[19].x < 0.0;\n    bool _1582;\n    if (!_1575)\n    {\n        _1582 = fa_mesh_fs_params[19].w < 1.0;\n    }\n    else\n    {\n        _1582 = _1575;\n    }\n    bool _1590;\n    if (!_1582)\n    {\n        _1590 = fa_mesh_fs_params[18].x < 1.0;\n    }\n    else\n    {\n        _1590 = _1582;\n    }\n    bool _1597;\n    if (!_1590)\n    {\n        _1597 = fa_mesh_fs_params[18].y < 1.0;\n    }\n    else\n    {\n        _1597 = _1590;\n    }\n    bool _1604;\n    if (!_1597)\n    {\n        _1604 = fa_mesh_fs_params[19].y < 1.0;\n    }\n    else\n    {\n        _1604 = _1597;\n    }\n    if (_1604)\n    {\n        return vec4(0.0);\n    }\n    vec4 _1614 = vec4(world_pos, 1.0);\n    float _1620 = dot(fa_mesh_fs_params[16], _1614);\n    if (!(_1620 > 9.9999999747524270787835121154785e-07))\n    {\n        return vec4(0.0);\n    }\n    vec2 _1642 = vec2(dot(fa_mesh_fs_params[14], _1614), dot(fa_mesh_fs_params[15], _1614)) / vec2(_1620);\n    int _1646 = int(fa_mesh_fs_params[18].x);\n    int _1650 = int(fa_mesh_fs_params[18].y);\n    int param = (int(fa_mesh_fs_params[19].x) + (((clamp(int(floor(log2(max(dot(fa_mesh_fs_params[17].xyz, world_pos) + fa_mesh_fs_params[17].w, fa_mesh_fs_params[18].w) / fa_mesh_fs_params[18].w) * fa_mesh_fs_params[18].z)), 0, int(fa_mesh_fs_params[19].y) - 1) * _1650) + clamp(int(floor(((_1642.y * 0.5) + 0.5) * fa_mesh_fs_params[18].y)), 0, _1650 - 1)) * _1646)) + clamp(int(floor(((_1642.x * 0.5) + 0.5) * fa_mesh_fs_params[18].x)), 0, _1646 - 1);\n    return fa_light_texel(param);\n}\n\nivec2 fa_cluster_lookup(vec3 world_pos)\n{\n    vec3 param = world_pos;\n    vec4 _1726 = fa_cluster_texel(param);\n    return ivec2(int(_1726.x), int(_1726.y));\n}\n\nvoid fa_cluster_begin(vec3 world_pos)\n{\n    fa_cl_ndir = int(fa_mesh_fs_params[19].z);\n    vec3 param = world_pos;\n    ivec2 _5781 = fa_cluster_lookup(param);\n    fa_cl_slot = _5781.x;\n    fa_cl_local = _5781.y;\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nvec3 fa_linear_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_tex_fix(inout vec3 c, float mode)\n{\n    if (mode > 1.5)\n    {\n        vec3 param = c;\n        vec3 _6928 = fa_linear_to_srgb(param);\n        c = _6928;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            vec3 param_1 = c;\n            vec3 _6936 = fa_srgb_to_linear(param_1);\n            c = _6936;\n        }\n    }\n    return c;\n}\n\nvec3 fa_tangent_normal(SurfaceInput i, vec3 m)\n{\n    vec3 _519;\n    if (i.front_facing)\n    {\n        _519 = i.world_normal;\n    }\n    else\n    {\n        _519 = -i.world_normal;\n    }\n    vec3 _543 = normalize(i.world_tangent.xyz - (_519 * dot(_519, i.world_tangent.xyz)));\n    vec3 _570 = normalize(((_543 * m.x) + ((cross(_519, _543) * i.world_tangent.w) * m.y)) + (_519 * m.z));\n    vec3 _573;\n    if (i.front_facing)\n    {\n        _573 = _570;\n    }\n    else\n    {\n        _573 = -_570;\n    }\n    return _573;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    vec4 base_t = texture(fa_tex_fa_smp, i.uv);\n    float param = fa_mesh_fs_params[6].w;\n    float param_1 = 1.0;\n    vec3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    vec3 _6967 = fa_tex_fix(param_2, param_3);\n    vec4 _8593 = base_t;\n    _8593.x = _6967.x;\n    _8593.y = _6967.y;\n    _8593.z = _6967.z;\n    base_t = _8593;\n    vec4 _6981 = (_8593 * fa_mesh_fs_params[2]) * i.vertex_color;\n    vec3 _8377 = i.world_normal;\n    if (fa_mesh_fs_params[6].z > 0.5)\n    {\n        float param_4 = fa_mesh_fs_params[6].w;\n        float param_5 = 16.0;\n        vec3 param_6 = texture(fa_normal_tex_fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        vec3 _7013 = fa_tex_fix(param_6, param_7);\n        vec3 _7016 = (_7013 * 2.0) - vec3(1.0);\n        vec2 _7021 = _7016.xy * fa_mesh_fs_params[6].x;\n        vec3 _8601 = _7016;\n        _8601.x = _7021.x;\n        _8601.y = _7021.y;\n        SurfaceInput param_8 = i;\n        vec3 param_9 = _8601;\n        _8377 = fa_tangent_normal(param_8, param_9);\n    }\n    vec4 mrt = texture(fa_mr_tex_fa_smp, i.uv);\n    float param_10 = fa_mesh_fs_params[6].w;\n    float param_11 = 64.0;\n    vec3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    vec3 _7049 = fa_tex_fix(param_12, param_13);\n    vec4 _8604 = mrt;\n    _8604.x = _7049.x;\n    _8604.y = _7049.y;\n    _8604.z = _7049.z;\n    mrt = _8604;\n    vec4 _7077 = texture(fa_occlusion_tex_fa_smp, i.uv);\n    float param_14 = fa_mesh_fs_params[6].w;\n    float param_15 = 256.0;\n    vec3 param_16 = _7077.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    vec3 _7088 = fa_tex_fix(param_16, param_17);\n    float param_18 = fa_mesh_fs_params[6].w;\n    float param_19 = 4.0;\n    vec3 param_20 = texture(fa_emissive_tex_fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    vec3 _7118 = fa_tex_fix(param_20, param_21);\n    float _8382 = fa_mesh_fs_params[20].x;\n    float _8383 = fa_mesh_fs_params[20].y;\n    float _8386 = fa_mesh_fs_params[20].z;\n    float _8385 = fa_mesh_fs_params[21].w;\n    float _8388 = fa_mesh_fs_params[22].x;\n    if (fa_mesh_fs_params[22].z > 0.5)\n    {\n        if (mod(fa_mesh_fs_params[22].z, 2.0) > 0.5)\n        {\n            _8382 *= _7088.y;\n            _8383 *= _7088.z;\n            _8385 *= _7077.w;\n        }\n        if (fa_mesh_fs_params[22].z > 1.5)\n        {\n            _8386 *= mrt.x;\n            _8388 *= mrt.w;\n        }\n    }\n    return Surface(_6981.xyz, _6981.w, _8377, clamp(fa_mesh_fs_params[5].x * _7049.z, 0.0, 1.0), clamp(fa_mesh_fs_params[5].y * _7049.y, 0.0500000007450580596923828125, 1.0), 1.0 + (fa_mesh_fs_params[6].y * (_7088.x - 1.0)), fa_mesh_fs_params[3].xyz + (fa_mesh_fs_params[4].xyz * _7118), _8382, _8383, fa_mesh_fs_params[21].xyz, _8385, _8386, fa_mesh_fs_params[20].w, _8388, fa_mesh_fs_params[22].y, fa_mesh_fs_params[23].xyz, fa_mesh_fs_params[30].x, fa_mesh_fs_params[30].y, fa_mesh_fs_params[31].xyz, fa_mesh_fs_params[30].z);\n}\n\nvoid surface(SurfaceInput i, inout Surface s)\n{\n    s.albedo *= mix(0.5, 1.0, texture(height_height_smp, i.uv).x);\n}\n\nvec4 fa_decal_tile(vec4 rect, vec2 uv, vec2 atlas, vec2 ddx, vec2 ddy)\n{\n    vec2 _1806 = rect.zw - rect.xy;\n    vec2 _1810 = _1806 * atlas;\n    vec2 _1814 = ddx * _1810;\n    vec2 _1818 = ddy * _1810;\n    return textureLod(fa_decal_tex_fa_env_smp, rect.xy + (clamp(uv, vec2(0.0), vec2(1.0)) * _1806), clamp(0.5 * log2(max(max(dot(_1814, _1814), dot(_1818, _1818)), 9.9999999392252902907785028219223e-09)), 0.0, 4.0));\n}\n\nvec3 fa_dc_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_dc_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvoid fa_apply_decals(vec3 world_pos, vec3 geo_normal, inout vec3 albedo, inout vec3 normal)\n{\n    bool _1851 = fa_mesh_fs_params[10].y < 0.5;\n    bool _1858;\n    if (!_1851)\n    {\n        _1858 = fa_mesh_fs_params[10].w < 0.5;\n    }\n    else\n    {\n        _1858 = _1851;\n    }\n    if (_1858)\n    {\n        return;\n    }\n    vec3 _1864 = dFdx(world_pos);\n    vec3 _1867 = dFdy(world_pos);\n    vec3 param = world_pos;\n    vec4 _1871 = fa_cluster_texel(param);\n    int _1875 = int(_1871.w);\n    if (_1875 < 1)\n    {\n        return;\n    }\n    int _1885 = int(fa_mesh_fs_params[10].y + 0.5);\n    int param_1 = _1885;\n    vec4 _1889 = fa_light_texel(param_1);\n    vec2 _1892 = _1889.yz;\n    int _1896 = int(_1889.w);\n    int param_2 = _1885 + 1;\n    vec4 _1901 = fa_light_texel(param_2);\n    float _1902 = _1901.x;\n    int _1908 = int(fa_mesh_fs_params[10].w + 0.5) - 1;\n    int _1912 = int(_1871.z);\n    vec3 _2177;\n    for (int k = 0; k < _1875; k++)\n    {\n        int _1925 = _1912 + k;\n        int param_3 = _1896 + (_1925 >> 2);\n        int _1942 = (_1885 + 2) + (int(fa_light_texel(param_3)[_1925 & 3]) * 7);\n        int param_4 = _1942 + 6;\n        vec4 _1947 = fa_light_texel(param_4);\n        if (((int(_1947.w + 0.5) >> _1908) & 1) == 0)\n        {\n            continue;\n        }\n        int param_5 = _1942;\n        vec4 _1962 = fa_light_texel(param_5);\n        int param_6 = _1942 + 1;\n        vec4 _1967 = fa_light_texel(param_6);\n        int param_7 = _1942 + 2;\n        vec4 _1972 = fa_light_texel(param_7);\n        vec3 _1975 = _1962.xyz;\n        float _1980 = dot(_1975, world_pos) + _1962.w;\n        vec3 _1982 = _1967.xyz;\n        float _1987 = dot(_1982, world_pos) + _1967.w;\n        vec3 _1989 = _1972.xyz;\n        float _1994 = dot(_1989, world_pos) + _1972.w;\n        bool _1999 = abs(_1980) > 0.5;\n        bool _2007;\n        if (!_1999)\n        {\n            _2007 = abs(_1987) > 0.5;\n        }\n        else\n        {\n            _2007 = _1999;\n        }\n        bool _2015;\n        if (!_2007)\n        {\n            _2015 = abs(_1994) > 0.5;\n        }\n        else\n        {\n            _2015 = _2007;\n        }\n        if (_2015)\n        {\n            continue;\n        }\n        float _2030 = clamp(dot(geo_normal, normalize(_1989)) * _1947.z, 0.0, 1.0);\n        if (_2030 <= 0.0)\n        {\n            continue;\n        }\n        float _2050 = (clamp((0.5 - abs(_1994)) * 10.0, 0.0, 1.0) * _2030) * _1947.x;\n        vec2 _2058 = vec2(_1980 + 0.5, 0.5 - _1987);\n        vec2 _2068 = vec2(dot(_1975, _1864), dot(_1982, _1864));\n        vec2 _2078 = vec2(dot(_1975, _1867), dot(_1982, _1867));\n        int param_8 = _1942 + 5;\n        vec4 _2083 = fa_light_texel(param_8);\n        int param_9 = _1942 + 3;\n        vec4 _2088 = fa_light_texel(param_9);\n        int param_10 = _1942 + 4;\n        vec4 _2093 = fa_light_texel(param_10);\n        float tex_a = 1.0;\n        vec3 col = _2083.xyz;\n        bool _2103 = _2088.z > _2088.x;\n        if (_2103)\n        {\n            vec4 param_11 = _2088;\n            vec2 param_12 = _2058;\n            vec2 param_13 = _1892;\n            vec2 param_14 = _2068;\n            vec2 param_15 = _2078;\n            vec4 tx = fa_decal_tile(param_11, param_12, param_13, param_14, param_15);\n            if ((_1902 > 0.5) && (_1902 < 1.5))\n            {\n                vec3 param_16 = tx.xyz;\n                vec3 _2129 = fa_dc_to_linear(param_16);\n                vec4 _8465 = tx;\n                _8465.x = _2129.x;\n                _8465.y = _2129.y;\n                _8465.z = _2129.z;\n                tx = _8465;\n            }\n            col *= tx.xyz;\n            tex_a = tx.w;\n        }\n        albedo = mix(albedo, col, vec3(clamp((_2050 * tex_a) * _2083.w, 0.0, 1.0)));\n        if (_2093.z > _2093.x)\n        {\n            vec4 param_17 = _2093;\n            vec2 param_18 = _2058;\n            vec2 param_19 = _1892;\n            vec2 param_20 = _2068;\n            vec2 param_21 = _2078;\n            vec4 _2173 = fa_decal_tile(param_17, param_18, param_19, param_20, param_21);\n            if (_1902 > 1.5)\n            {\n                vec3 param_22 = _2173.xyz;\n                vec3 _2183 = fa_dc_to_srgb(param_22);\n                _2177 = _2183;\n            }\n            else\n            {\n                _2177 = _2173.xyz;\n            }\n            vec3 _2192 = (_2177 * 2.0) - vec3(1.0);\n            vec2 _2197 = _2192.xy * _1947.y;\n            vec3 _2219 = (normalize(_1975) * _2197.x) + (normalize(_1982) * _2197.y);\n            vec3 _2222 = normalize(normal);\n            normal = normalize(mix(_2222, normalize((_2222 * max(_2192.z, 0.0500000007450580596923828125)) + (_2219 - (_2222 * dot(_2222, _2219)))), vec3(clamp(_2050 * (_2103 ? tex_a : 1.0), 0.0, 1.0))));\n        }\n    }\n}\n\nfloat fa_sheen_albedo(float ndv, float rough)\n{\n    float _4246 = min(sqrt(max(rough - 0.100000001490116119384765625, 0.0) * 1.111111164093017578125) * 6.0, 5.999000072479248046875);\n    float _4253 = min(sqrt(clamp(ndv, 0.0, 1.0)) * 8.0, 7.999000072479248046875);\n    int _4256 = int(_4246);\n    int _4259 = int(_4253);\n    float _4269 = _4253 - float(_4259);\n    int _4324 = (_4256 * 9) + _4259;\n    int _4344 = ((_4256 + 1) * 9) + _4259;\n    return mix(mix(_4320[_4324], _4320[_4324 + 1], _4269), mix(_4320[_4344], _4320[_4344 + 1], _4269), _4246 - float(_4256));\n}\n\nFaLayers fa_layers_setup(SurfaceInput i, Surface s, vec3 n, vec3 v, float metallic, float roughness, inout vec3 f0)\n{\n    bool _8300 = false;\n    float _8301 = 1.0;\n    float _8302 = 1.0;\n    float _8303 = 1.0;\n    float _8304 = 0.0;\n    float _8305 = 0.0;\n    float _8306 = 0.0;\n    float _8307 = 0.0;\n    float _8309 = 1.0;\n    bool _8310 = false;\n    vec3 _8311 = vec3(0.0);\n    float _8312 = 1.0;\n    float _8313 = 1.0;\n    float _8314 = 1.0;\n    float _8315 = 0.0;\n    float _8316 = 0.0;\n    vec3 _8317 = vec3(1.0, 0.0, 0.0);\n    vec3 _8318 = vec3(0.0, 0.0, 1.0);\n    float _8319 = 1.0;\n    float _8320 = 1.0;\n    float _4395 = clamp(s.specular, 0.0, 1.0);\n    float _4399 = clamp(s.ior, 1.0, 3.0);\n    bool _4404 = (_4395 != 1.0) || (_4399 != 1.5);\n    bool _4413;\n    if (!_4404)\n    {\n        _4413 = any(notEqual(s.specular_color, vec3(1.0)));\n    }\n    else\n    {\n        _4413 = _4404;\n    }\n    if (_4413)\n    {\n        float _4421 = (_4399 - 1.0) / (_4399 + 1.0);\n        f0 = mix(min(vec3(_4421 * _4421) * max(s.specular_color, vec3(0.0)), vec3(1.0)) * _4395, s.albedo, vec3(metallic));\n        _8301 = mix(_4395, 1.0, metallic);\n        _8300 = true;\n    }\n    float _4448 = clamp(s.clearcoat, 0.0, 1.0);\n    if (_4448 > 0.0)\n    {\n        float _4456 = clamp(s.clearcoat_roughness, 0.0500000007450580596923828125, 1.0);\n        _8304 = _4448;\n        _8305 = _4456;\n        float _4463 = _4456 * _4456;\n        _8306 = _4463;\n        _8307 = _4463 * _4463;\n        float _4475 = max(dot(i.world_normal, v), 9.9999997473787516355514526367188e-05);\n        _8309 = _4475;\n        _8302 = 1.0 - (_4448 * (0.039999999105930328369140625 + (0.959999978542327880859375 * pow(clamp(1.0 - _4475, 0.0, 1.0), 5.0))));\n        _8300 = true;\n    }\n    vec3 _4494 = max(s.sheen_color, vec3(0.0));\n    float _4503 = max(_4494.x, max(_4494.y, _4494.z));\n    if (_4503 > 0.0)\n    {\n        float _4511 = clamp(s.sheen_roughness, 0.100000001490116119384765625, 1.0);\n        _8310 = true;\n        _8311 = _4494;\n        _8312 = _4511;\n        _8313 = _4511 * _4511;\n        float param = max(dot(n, v), 9.9999997473787516355514526367188e-05);\n        float param_1 = _4511;\n        float _4528 = fa_sheen_albedo(param, param_1);\n        _8315 = _4528;\n        _8314 = 1.0 - min(_4503 * _4528, 1.0);\n        _8300 = true;\n    }\n    _8303 = _8302 * _8314;\n    float _4547 = clamp(s.anisotropy, -1.0, 1.0);\n    if (_4547 != 0.0)\n    {\n        vec3 _4562 = i.world_tangent.xyz - (n * dot(n, i.world_tangent.xyz));\n        vec3 t = _4562;\n        if (dot(_4562, _4562) < 9.9999999392252902907785028219223e-09)\n        {\n            bvec3 _4574 = bvec3(abs(n.y) < 0.9900000095367431640625);\n            t = cross(vec3(_4574.x ? vec3(0.0, 1.0, 0.0).x : vec3(1.0, 0.0, 0.0).x, _4574.y ? vec3(0.0, 1.0, 0.0).y : vec3(1.0, 0.0, 0.0).y, _4574.z ? vec3(0.0, 1.0, 0.0).z : vec3(1.0, 0.0, 0.0).z), n);\n        }\n        vec3 _4578 = t;\n        vec3 _4579 = normalize(_4578);\n        t = _4579;\n        vec3 _4604 = normalize((_4579 * cos(s.anisotropy_rotation)) + ((cross(n, _4579) * ((i.world_tangent.w < 0.0) ? (-1.0) : 1.0)) * sin(s.anisotropy_rotation)));\n        _8317 = _4604;\n        _8318 = cross(n, _4604);\n        float _4614 = roughness * roughness;\n        float _4620 = mix(_4614, 1.0, _4547 * _4547);\n        bool _4622 = _4547 > 0.0;\n        _8319 = _4622 ? _4620 : _4614;\n        _8320 = _4622 ? _4614 : _4620;\n        _8316 = _4547;\n        _8300 = true;\n    }\n    return FaLayers(_8300, _8301, _8302, _8303, _8304, _8305, _8306, _8307, i.world_normal, _8309, _8310, _8311, _8312, _8313, _8314, _8315, _8316, _8317, _8318, _8319, _8320);\n}\n\nvec2 fa_atlas_size()\n{\n    return vec2(textureSize(fa_probe_atlas_fa_env_smp, 0));\n}\n\nvec3 fa_probe_sh_coef(vec2 origin, float res, int k)\n{\n    vec3 v = textureLod(fa_probe_atlas_fa_env_smp, (origin + vec2(float(k) + 0.5, res + 2.5)) / fa_atlas_size(), 0.0).xyz;\n    if (fa_mesh_fs_params[41].y > 0.5)\n    {\n        v = (v - vec3(0.5)) * 8.0;\n    }\n    return v;\n}\n\nvec3 fa_sh_eval(vec3 c[9], vec3 n)\n{\n    vec3 _3417 = max((((c[0] * 0.2820948064327239990234375) + (((c[1] * (0.3257350027561187744140625 * n.y)) + (c[2] * (0.3257350027561187744140625 * n.z))) + (c[3] * (0.3257350027561187744140625 * n.x)))) + (((c[4] * ((0.2731371223926544189453125 * n.x) * n.y)) + (c[5] * ((0.2731371223926544189453125 * n.y) * n.z))) + (c[6] * (0.078847892582416534423828125 * (((3.0 * n.z) * n.z) - 1.0))))) + ((c[7] * ((0.2731371223926544189453125 * n.x) * n.z)) + (c[8] * (0.13656856119632720947265625 * ((n.x * n.x) - (n.y * n.y))))), vec3(0.0));\n    return _3417;\n}\n\nvec3 fa_ambient_light(vec3 n)\n{\n    float _4027 = (1.0 - fa_mesh_fs_params[42].w) - fa_mesh_fs_params[47].w;\n    vec3 amb = vec3(0.0);\n    bool _4032 = fa_mesh_fs_params[11].w > 0.5;\n    vec3 c[9];\n    for (int k = 0; k < 9; k++)\n    {\n        c[k] = vec3(0.0);\n    }\n    if (_4027 > 0.0005000000237487256526947021484375)\n    {\n        if (_4032)\n        {\n            for (int k_1 = 0; k_1 < 9; k_1++)\n            {\n                vec2 param = fa_mesh_fs_params[41].zw;\n                float param_1 = 128.0;\n                int param_2 = k_1;\n                c[k_1] = fa_probe_sh_coef(param, param_1, param_2) * _4027;\n            }\n        }\n        else\n        {\n            amb = fa_mesh_fs_params[1].xyz * _4027;\n        }\n    }\n    bool _4083 = fa_mesh_fs_params[42].w > 0.0;\n    if (_4083)\n    {\n        for (int k_2 = 0; k_2 < 9; k_2++)\n        {\n            vec2 param_3 = fa_mesh_fs_params[42].xy;\n            float param_4 = fa_mesh_fs_params[42].z;\n            int param_5 = k_2;\n            c[k_2] += (fa_probe_sh_coef(param_3, param_4, param_5) * fa_mesh_fs_params[42].w);\n        }\n    }\n    bool _4114 = fa_mesh_fs_params[47].w > 0.0;\n    if (_4114)\n    {\n        for (int k_3 = 0; k_3 < 9; k_3++)\n        {\n            vec2 param_6 = fa_mesh_fs_params[47].xy;\n            float param_7 = fa_mesh_fs_params[47].z;\n            int param_8 = k_3;\n            c[k_3] += (fa_probe_sh_coef(param_6, param_7, param_8) * fa_mesh_fs_params[47].w);\n        }\n    }\n    if ((_4032 || _4083) || _4114)\n    {\n        vec3 param_9[9] = c;\n        vec3 param_10 = n;\n        amb += fa_sh_eval(param_9, param_10);\n    }\n    return amb;\n}\n\nvec3 fa_indirect_diffuse(vec3 n)\n{\n    if (fa_lm.z > 0.5)\n    {\n        return textureLod(fa_lightmap_fa_env_smp, fa_lm.xy, 0.0).xyz;\n    }\n    if (fa_mesh_fs_params[32].w > 0.0)\n    {\n        vec3 c[9];\n        for (int k = 0; k < 9; k++)\n        {\n            c[k] = fa_mesh_fs_params[k * 1 + 32].xyz;\n        }\n        vec3 param = n;\n        vec3 param_1[9] = c;\n        vec3 param_2 = n;\n        return mix(fa_ambient_light(param), fa_sh_eval(param_1, param_2), vec3(clamp(fa_mesh_fs_params[32].w, 0.0, 1.0)));\n    }\n    vec3 param_3 = n;\n    return fa_ambient_light(param_3);\n}\n\nint fa_cluster_index(int slot, int n)\n{\n    int param = (int(fa_mesh_fs_params[19].x) + int(fa_mesh_fs_params[19].w)) + ((slot + n) >> 2);\n    vec4 t = fa_light_texel(param);\n    return int(t[(slot + n) & 3]);\n}\n\nint fa_cl_light(int n)\n{\n    if (n < fa_cl_ndir)\n    {\n        return n;\n    }\n    int param = fa_cl_slot;\n    int param_1 = n - fa_cl_ndir;\n    return fa_cluster_index(param, param_1);\n}\n\nint fa_light_base(int li)\n{\n    return li * ((fa_mesh_fs_params[1].w > 4.5) ? 8 : 4);\n}\n\nbool fa_light_baked(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 3;\n    return fa_light_texel(param_1).w > 0.5;\n}\n\nfloat fa_baked_keep(int li)\n{\n    float _5751;\n    if (fa_lm.z > 0.5)\n    {\n        _5751 = 0.0;\n    }\n    else\n    {\n        _5751 = 1.0 - clamp(fa_mesh_fs_params[32].w, 0.0, 1.0);\n    }\n    bool _5762 = _5751 < 1.0;\n    bool _5768;\n    if (_5762)\n    {\n        int param = li;\n        _5768 = fa_light_baked(param);\n    }\n    else\n    {\n        _5768 = _5762;\n    }\n    return _5768 ? _5751 : 1.0;\n}\n\nfloat fa_light_type(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 1;\n    return fa_light_texel(param_1).w;\n}\n\nvec4 fa_atlas_fetch(vec2 texel)\n{\n    return textureLod(fa_light_atlas_fa_env_smp, texel / vec2(textureSize(fa_light_atlas_fa_env_smp, 0)), 0.0);\n}\n\nvec3 fa_cookie_sample(vec2 tile_origin, vec2 uv)\n{\n    vec2 param = (tile_origin + vec2(1.0)) + (clamp(uv, vec2(0.0), vec2(1.0)) * 254.0);\n    return fa_atlas_fetch(param).xyz;\n}\n\nvec3 fa_area_point(vec3 c, vec3 axis, vec3 ru, vec3 uu, float hx, float hy, float shape, vec3 p, vec3 r)\n{\n    bool _824 = dot(r, r) > 0.5;\n    if (shape > 1.5)\n    {\n        vec3 _837 = (c - (ru * hx)) - p;\n        vec3 _843 = ru * (2.0 * hx);\n        float _849 = max(dot(_843, _843), 9.9999999392252902907785028219223e-09);\n        float _853 = dot(_837, _843);\n        float t = clamp((-_853) / _849, 0.0, 1.0);\n        if (_824)\n        {\n            float _868 = dot(r, _843);\n            float _874 = _849 - (_868 * _868);\n            if (abs(_874) > (9.9999997473787516355514526367188e-06 * _849))\n            {\n                t = clamp(((dot(r, _837) * _868) - _853) / _874, 0.0, 1.0);\n            }\n        }\n        return (p + _837) + (_843 * t);\n    }\n    vec3 q = p;\n    float _906 = dot(r, axis);\n    bool _914;\n    if (_824)\n    {\n        _914 = abs(_906) > 9.9999997473787516355514526367188e-05;\n    }\n    else\n    {\n        _914 = _824;\n    }\n    if (_914)\n    {\n        float _924 = dot(c - p, axis) / _906;\n        if (_924 > 0.0)\n        {\n            q = p + (r * _924);\n        }\n    }\n    vec3 _937 = q - c;\n    vec2 xy = vec2(dot(_937, ru), dot(_937, uu));\n    if (shape > 0.5)\n    {\n        float _952 = length(xy);\n        if (_952 > hx)\n        {\n            xy *= (hx / _952);\n        }\n    }\n    else\n    {\n        xy = clamp(xy, vec2(-hx, -hy), vec2(hx, hy));\n    }\n    return (c + (ru * xy.x)) + (uu * xy.y);\n}\n\nint fa_cube_face(vec3 d)\n{\n    vec3 _585 = abs(d);\n    float _587 = _585.x;\n    float _589 = _585.y;\n    bool _590 = _587 >= _589;\n    bool _598;\n    if (_590)\n    {\n        _598 = _587 >= _585.z;\n    }\n    else\n    {\n        _598 = _590;\n    }\n    int _599;\n    if (_598)\n    {\n        _599 = (d.x > 0.0) ? 0 : 1;\n    }\n    else\n    {\n        int _614;\n        if (_589 >= _585.z)\n        {\n            _614 = (d.y > 0.0) ? 2 : 3;\n        }\n        else\n        {\n            _614 = (d.z > 0.0) ? 4 : 5;\n        }\n        _599 = _614;\n    }\n    return _599;\n}\n\nvoid fa_cube_face_basis(int f, out vec3 fwd, out vec3 up)\n{\n    if (f == 0)\n    {\n        fwd = vec3(1.0, 0.0, 0.0);\n        up = vec3(0.0, 1.0, 0.0);\n    }\n    else\n    {\n        if (f == 1)\n        {\n            fwd = vec3(-1.0, 0.0, 0.0);\n            up = vec3(0.0, 1.0, 0.0);\n        }\n        else\n        {\n            if (f == 2)\n            {\n                fwd = vec3(0.0, 1.0, 0.0);\n                up = vec3(0.0, 0.0, 1.0);\n            }\n            else\n            {\n                if (f == 3)\n                {\n                    fwd = vec3(0.0, -1.0, 0.0);\n                    up = vec3(0.0, 0.0, -1.0);\n                }\n                else\n                {\n                    if (f == 4)\n                    {\n                        fwd = vec3(0.0, 0.0, 1.0);\n                        up = vec3(0.0, 1.0, 0.0);\n                    }\n                    else\n                    {\n                        fwd = vec3(0.0, 0.0, -1.0);\n                        up = vec3(0.0, 1.0, 0.0);\n                    }\n                }\n            }\n        }\n    }\n}\n\nfloat fa_ies_sample(vec2 tile_origin, vec3 d, vec3 axis, vec3 right, vec3 up)\n{\n    float _744 = dot(d, right);\n    float _748 = dot(d, up);\n    float _759;\n    if (((_744 * _744) + (_748 * _748)) > 1.0000000133514319600180897396058e-10)\n    {\n        _759 = atan(_748, _744) * 0.15915493667125701904296875;\n    }\n    else\n    {\n        _759 = 0.0;\n    }\n    vec2 param = tile_origin + vec2(1.0 + ((_759 - floor(_759)) * 64.0), 1.0 + (acos(clamp(dot(d, axis), -1.0, 1.0)) * 10.18591594696044921875));\n    return fa_atlas_fetch(param).x;\n}\n\nLightSample fa_light_sample_n(int li, vec3 world_pos, vec3 n)\n{\n    int param = li;\n    int _990 = fa_light_base(param);\n    bool _994 = fa_mesh_fs_params[1].w > 4.5;\n    int param_1 = _990;\n    vec4 _998 = fa_light_texel(param_1);\n    int param_2 = _990 + 1;\n    vec4 _1003 = fa_light_texel(param_2);\n    float _1006 = _1003.w;\n    float atten = 1.0;\n    float dist = 0.0;\n    fa_light_tint = vec3(1.0);\n    bool _1018 = _994 && (_1006 > 2.5);\n    fa_light_is_area = _1018;\n    bool _1020 = _1006 < 0.5;\n    vec3 l;\n    if (_1020)\n    {\n        l = normalize(_998.xyz);\n        if (_994)\n        {\n            int param_3 = _990 + 6;\n            vec4 _1034 = fa_light_texel(param_3);\n            if (_1034.z > 0.5)\n            {\n                int param_4 = _990 + 4;\n                vec4 _1044 = fa_light_texel(param_4);\n                int param_5 = _990 + 5;\n                vec4 _1049 = fa_light_texel(param_5);\n                vec2 param_6 = _1034.xy;\n                vec2 param_7 = fract(vec2(dot(world_pos, _1044.xyz) * _1044.w, (-dot(world_pos, _1049.xyz)) * _1049.w) + vec2(0.5));\n                fa_light_tint = fa_cookie_sample(param_6, param_7);\n            }\n        }\n    }\n    else\n    {\n        vec3 _1079 = _998.xyz;\n        vec3 _1081 = _1079 - world_pos;\n        vec3 to_light = _1081;\n        float _1084 = length(_1081);\n        float reach = _1084;\n        bool front = true;\n        if (_1018)\n        {\n            int param_8 = _990 + 7;\n            reach = max(_1084 - fa_light_texel(param_8).w, 0.0);\n            int param_9 = _990 + 4;\n            vec4 _1108 = fa_light_texel(param_9);\n            int param_10 = _990 + 5;\n            vec4 _1113 = fa_light_texel(param_10);\n            int param_11 = _990 + 6;\n            vec4 _1118 = fa_light_texel(param_11);\n            float _1119 = _1118.w;\n            int param_12 = _990 + 2;\n            vec3 _1126 = normalize(fa_light_texel(param_12).xyz);\n            bool _1128 = _1119 > 1.5;\n            bool _1136;\n            if (!_1128)\n            {\n                _1136 = dot(_1126, to_light) < 0.0;\n            }\n            else\n            {\n                _1136 = _1128;\n            }\n            front = _1136;\n            vec3 r = vec3(0.0);\n            vec3 _1145 = fa_mesh_fs_params[0].xyz - world_pos;\n            bool _1149 = dot(n, n) > 0.5;\n            bool _1157;\n            if (_1149)\n            {\n                _1157 = dot(_1145, _1145) > 9.9999999600419720025001879548654e-13;\n            }\n            else\n            {\n                _1157 = _1149;\n            }\n            if (_1157)\n            {\n                r = reflect(-normalize(_1145), normalize(n));\n            }\n            vec3 param_13 = _1079;\n            vec3 param_14 = _1126;\n            vec3 param_15 = _1108.xyz;\n            vec3 param_16 = _1113.xyz;\n            float param_17 = _1108.w;\n            float param_18 = _1113.w;\n            float param_19 = _1119;\n            vec3 param_20 = world_pos;\n            vec3 param_21 = r;\n            to_light = fa_area_point(param_13, param_14, param_15, param_16, param_17, param_18, param_19, param_20, param_21) - world_pos;\n        }\n        float _1193 = length(to_light);\n        dist = _1193;\n        l = to_light / vec3(max(_1193, 9.9999997473787516355514526367188e-05));\n        float _1207 = reach / max(_998.w, 0.001000000047497451305389404296875);\n        float _1213 = clamp(1.0 - (_1207 * _1207), 0.0, 1.0);\n        float _1215;\n        if (front)\n        {\n            _1215 = _1213 * _1213;\n        }\n        else\n        {\n            _1215 = 0.0;\n        }\n        atten = _1215;\n        bool _1226 = _1006 < 2.5;\n        if ((_1006 > 1.5) && _1226)\n        {\n            int param_22 = _990 + 2;\n            vec4 _1234 = fa_light_texel(param_22);\n            float _1244 = _1234.w;\n            int param_23 = _990 + 3;\n            vec4 _1249 = fa_light_texel(param_23);\n            float _1250 = _1249.x;\n            float cos_inner = _1250;\n            if (_1250 > 1.5)\n            {\n                cos_inner = mix(_1244, 1.0, 0.25);\n            }\n            atten *= smoothstep(_1244, cos_inner, dot(-l, normalize(_1234.xyz)));\n        }\n        if (_994 && (_1006 < 1.5))\n        {\n            int param_24 = _990 + 6;\n            vec4 _1274 = fa_light_texel(param_24);\n            if (_1274.z > 0.5)\n            {\n                vec3 _1282 = -to_light;\n                int param_25 = _990 + 4;\n                int param_26 = _990 + 5;\n                vec3 _1296 = fa_light_texel(param_25).xyz;\n                vec3 _1300 = fa_light_texel(param_26).xyz;\n                vec3 _1309 = vec3(dot(_1282, _1296), dot(_1282, _1300), dot(_1282, cross(_1296, _1300)));\n                vec3 param_27 = _1309;\n                int _1313 = fa_cube_face(param_27);\n                int param_28 = _1313;\n                vec3 param_29;\n                vec3 param_30;\n                fa_cube_face_basis(param_28, param_29, param_30);\n                vec2 _1340 = vec2(dot(_1309, cross(param_29, param_30)), dot(_1309, param_30)) / vec2(max(dot(_1309, param_29), 9.9999997473787516355514526367188e-05));\n                int _1344 = _1313 / 3;\n                vec2 param_31 = _1274.xy + (vec2(float(_1313 - (_1344 * 3)), float(_1344)) * 256.0);\n                vec2 param_32 = vec2(0.5 + (0.5 * _1340.x), 0.5 - (0.5 * _1340.y));\n                fa_light_tint = fa_cookie_sample(param_31, param_32);\n            }\n            int param_33 = _990 + 7;\n            vec4 _1374 = fa_light_texel(param_33);\n            if (_1374.z > 0.5)\n            {\n                int param_34 = _990 + 2;\n                int param_35 = _990 + 4;\n                int param_36 = _990 + 5;\n                vec2 param_37 = _1374.xy;\n                vec3 param_38 = -l;\n                vec3 param_39 = normalize(fa_light_texel(param_34).xyz);\n                vec3 param_40 = fa_light_texel(param_35).xyz;\n                vec3 param_41 = fa_light_texel(param_36).xyz;\n                atten *= fa_ies_sample(param_37, param_38, param_39, param_40, param_41);\n            }\n        }\n        else\n        {\n            if (_994 && _1226)\n            {\n                int param_42 = _990 + 6;\n                vec4 _1421 = fa_light_texel(param_42);\n                int param_43 = _990 + 7;\n                vec4 _1426 = fa_light_texel(param_43);\n                bool _1429 = _1421.z > 0.5;\n                bool _1436;\n                if (!_1429)\n                {\n                    _1436 = _1426.z > 0.5;\n                }\n                else\n                {\n                    _1436 = _1429;\n                }\n                if (_1436)\n                {\n                    int param_44 = _990 + 2;\n                    vec4 _1443 = fa_light_texel(param_44);\n                    vec3 _1447 = normalize(_1443.xyz);\n                    int param_45 = _990 + 4;\n                    vec4 _1452 = fa_light_texel(param_45);\n                    int param_46 = _990 + 5;\n                    vec4 _1457 = fa_light_texel(param_46);\n                    if (_1429)\n                    {\n                        vec3 _1465 = -to_light;\n                        float _1472 = _1443.w;\n                        float _1488 = 0.5 / max(dot(_1465, _1447) * (sqrt(max(1.0 - (_1472 * _1472), 0.0)) / max(_1472, 0.001000000047497451305389404296875)), 9.9999997473787516355514526367188e-05);\n                        vec2 param_47 = _1421.xy;\n                        vec2 param_48 = vec2(0.5 + (dot(_1465, _1452.xyz) * _1488), 0.5 - (dot(_1465, _1457.xyz) * _1488));\n                        fa_light_tint = fa_cookie_sample(param_47, param_48);\n                    }\n                    if (_1426.z > 0.5)\n                    {\n                        vec2 param_49 = _1426.xy;\n                        vec3 param_50 = -l;\n                        vec3 param_51 = _1447;\n                        vec3 param_52 = _1452.xyz;\n                        vec3 param_53 = _1457.xyz;\n                        atten *= fa_ies_sample(param_49, param_50, param_51, param_52, param_53);\n                    }\n                }\n            }\n        }\n    }\n    vec3 _8288 = _1003.xyz * atten;\n    if (_994)\n    {\n        _8288 *= fa_light_tint;\n    }\n    int _1557;\n    if (_1020)\n    {\n        _1557 = 0;\n    }\n    else\n    {\n        _1557 = ((_1006 > 1.5) && (_1006 < 2.5)) ? 2 : 1;\n    }\n    return LightSample(l, _8288, atten, 1.0, dist, _1557);\n}\n\nfloat fa_shadow_split_at(int i)\n{\n    float _2294;\n    if (i == 0)\n    {\n        _2294 = fa_shadows[24].x;\n    }\n    else\n    {\n        float _2310;\n        if (i == 1)\n        {\n            _2310 = fa_shadows[24].y;\n        }\n        else\n        {\n            float _2318;\n            if (i == 2)\n            {\n                _2318 = fa_shadows[24].z;\n            }\n            else\n            {\n                _2318 = fa_shadows[24].w;\n            }\n            _2310 = _2318;\n        }\n        _2294 = _2310;\n    }\n    return _2294;\n}\n\nfloat fa_shadow_depth(inout vec2 uv, vec4 rect)\n{\n    uv = clamp(uv, rect.xy, rect.zw);\n    return textureLod(fa_shadow_tex_fa_shadow_smp, uv, 0.0).x;\n}\n\nfloat fa_shadow_fetch(vec2 uv, vec4 rect, vec3 conv)\n{\n    vec2 param = uv;\n    vec4 param_1 = rect;\n    float _2351 = fa_shadow_depth(param, param_1);\n    float _2355;\n    if (conv.x < 0.5)\n    {\n        _2355 = _2351;\n    }\n    else\n    {\n        _2355 = (conv.y * conv.z) / (conv.z - (_2351 * (conv.z - conv.y)));\n    }\n    return _2355;\n}\n\nfloat fa_shadow_noise()\n{\n    return fract(52.98291778564453125 * fract(dot(gl_FragCoord.xy, vec2(0.067110560834407806396484375, 0.005837149918079376220703125))));\n}\n\nvec2 fa_shadow_vogel(int k, int n, float phi)\n{\n    float _2282 = (float(k) * 2.3999631404876708984375) + phi;\n    return vec2(cos(_2282), sin(_2282)) * sqrt((float(k) + 0.5) / float(n));\n}\n\nfloat fa_shadow_filter(vec2 uv, vec4 rect, float zr, float texel_m, float unit, float reach, float plane, vec3 conv, int mode, float k)\n{\n    if (mode == 1)\n    {\n        vec2 param = uv;\n        vec4 param_1 = rect;\n        vec3 param_2 = conv;\n        return float(zr <= fa_shadow_fetch(param, param_1, param_2));\n    }\n    float _2401 = fa_shadow_noise() * 6.283185482025146484375;\n    float radius = 1.5;\n    if (mode == 2)\n    {\n        float _2410;\n        if (k < 0.0)\n        {\n            _2410 = (-k) / max(zr, 0.100000001490116119384765625);\n        }\n        else\n        {\n            _2410 = k;\n        }\n        float _2430 = clamp((_2410 * reach) / texel_m, 3.0, 12.0);\n        float sum = 0.0;\n        float cnt = 0.0;\n        for (int i = 0; i < 16; i++)\n        {\n            int param_3 = i;\n            int param_4 = 16;\n            float param_5 = _2401;\n            vec2 _2449 = fa_shadow_vogel(param_3, param_4, param_5) * _2430;\n            vec2 param_6 = uv + (_2449 * fa_shadows[26].zw);\n            vec4 param_7 = rect;\n            vec3 param_8 = conv;\n            float _2461 = fa_shadow_fetch(param_6, param_7, param_8);\n            if (_2461 < (zr - (length(_2449) * plane)))\n            {\n                sum += _2461;\n                cnt += 1.0;\n            }\n        }\n        if (cnt < 0.5)\n        {\n            return 1.0;\n        }\n        float _2487 = sum / cnt;\n        float _2497;\n        if (k < 0.0)\n        {\n            _2497 = (-k) / max(_2487, 0.0500000007450580596923828125);\n        }\n        else\n        {\n            _2497 = k;\n        }\n        radius = clamp(((max(zr - _2487, 0.0) * unit) * _2497) / texel_m, 1.5, 16.0);\n    }\n    float lit = 0.0;\n    int _2519 = (mode == 2) ? 24 : 16;\n    for (int i_1 = 0; i_1 < _2519; i_1++)\n    {\n        int param_9 = i_1;\n        int param_10 = _2519;\n        float param_11 = _2401;\n        vec2 _2538 = fa_shadow_vogel(param_9, param_10, param_11) * radius;\n        vec2 param_12 = uv + (_2538 * fa_shadows[26].zw);\n        vec4 param_13 = rect;\n        vec3 param_14 = conv;\n        lit += float((zr - (length(_2538) * plane)) <= fa_shadow_fetch(param_12, param_13, param_14));\n    }\n    return lit / float(_2519);\n}\n\nfloat fa_shadow_cascade(int ci, vec3 world, vec3 n, vec3 l)\n{\n    float _2580 = max(fa_shadows[ci * 1 + 20].y, 0.001000000047497451305389404296875);\n    float _2585 = clamp(dot(n, l), 0.0, 1.0);\n    float _2591 = sqrt(1.0 - (_2585 * _2585));\n    float _2598 = min(_2591 / max(_2585, 0.20000000298023223876953125), 4.0);\n    float _2603;\n    if (fa_shadows[26].y > 0.0)\n    {\n        _2603 = fa_shadows[26].y;\n    }\n    else\n    {\n        _2603 = 1.5 * fa_shadows[ci * 1 + 20].x;\n    }\n    vec4 _2628 = mat4(fa_shadows[ci * 4 + 0], fa_shadows[ci * 4 + 1], fa_shadows[ci * 4 + 2], fa_shadows[ci * 4 + 3]) * vec4(world + (n * (_2603 * _2591)), 1.0);\n    float _2635 = _2628.x;\n    bool _2638 = _2635 < fa_shadows[ci * 1 + 16].x;\n    bool _2647;\n    if (!_2638)\n    {\n        _2647 = _2635 > fa_shadows[ci * 1 + 16].z;\n    }\n    else\n    {\n        _2647 = _2638;\n    }\n    bool _2656;\n    if (!_2647)\n    {\n        _2656 = _2628.y < fa_shadows[ci * 1 + 16].y;\n    }\n    else\n    {\n        _2656 = _2647;\n    }\n    bool _2665;\n    if (!_2656)\n    {\n        _2665 = _2628.y > fa_shadows[ci * 1 + 16].w;\n    }\n    else\n    {\n        _2665 = _2656;\n    }\n    bool _2672;\n    if (!_2665)\n    {\n        _2672 = _2628.z > 1.0;\n    }\n    else\n    {\n        _2672 = _2665;\n    }\n    if (_2672)\n    {\n        return -1.0;\n    }\n    float _2680;\n    if (fa_shadows[26].x > 0.0)\n    {\n        _2680 = fa_shadows[26].x;\n    }\n    else\n    {\n        _2680 = 1.5 * fa_shadows[ci * 1 + 20].x;\n    }\n    vec2 param = _2628.xy;\n    vec4 param_1 = fa_shadows[ci * 1 + 16];\n    float param_2 = _2628.z - ((_2680 * (1.0 + (0.5 * _2598))) / _2580);\n    float param_3 = fa_shadows[ci * 1 + 20].x;\n    float param_4 = _2580;\n    float param_5 = _2580 * 0.25;\n    float param_6 = ((fa_shadows[ci * 1 + 20].x * min(_2598, 3.0)) * 0.5) / _2580;\n    vec3 param_7 = vec3(0.0);\n    int param_8 = int(fa_shadows[25].z + 0.5);\n    float param_9 = fa_shadows[25].w;\n    return fa_shadow_filter(param, param_1, param_2, param_3, param_4, param_5, param_6, param_7, param_8, param_9);\n}\n\nfloat fa_shadow_sun(vec3 world, vec3 n, vec3 l)\n{\n    if (fa_mesh_fs_params[5].z < 0.5)\n    {\n        return 1.0;\n    }\n    int _3058 = int(fa_shadows[25].x + 0.5);\n    if (_3058 < 1)\n    {\n        return 1.0;\n    }\n    float _3073 = dot(world - fa_shadows[27].xyz, fa_shadows[28].xyz);\n    int param = _3058 - 1;\n    if (_3073 > fa_shadow_split_at(param))\n    {\n        return 1.0;\n    }\n    int ci = 0;\n    bool _3085 = _3058 > 1;\n    bool _3092;\n    if (_3085)\n    {\n        _3092 = _3073 > fa_shadows[24].x;\n    }\n    else\n    {\n        _3092 = _3085;\n    }\n    if (_3092)\n    {\n        ci = 1;\n    }\n    bool _3096 = _3058 > 2;\n    bool _3103;\n    if (_3096)\n    {\n        _3103 = _3073 > fa_shadows[24].y;\n    }\n    else\n    {\n        _3103 = _3096;\n    }\n    if (_3103)\n    {\n        ci = 2;\n    }\n    bool _3107 = _3058 > 3;\n    bool _3114;\n    if (_3107)\n    {\n        _3114 = _3073 > fa_shadows[24].z;\n    }\n    else\n    {\n        _3114 = _3107;\n    }\n    if (_3114)\n    {\n        ci = 3;\n    }\n    float s = -1.0;\n    for (int k = 0; k < 4; k++)\n    {\n        if (ci >= _3058)\n        {\n            break;\n        }\n        int param_1 = ci;\n        vec3 param_2 = world;\n        vec3 param_3 = n;\n        vec3 param_4 = l;\n        float _3140 = fa_shadow_cascade(param_1, param_2, param_3, param_4);\n        s = _3140;\n        if (_3140 >= 0.0)\n        {\n            break;\n        }\n        ci++;\n    }\n    if (s < 0.0)\n    {\n        return 1.0;\n    }\n    if (fa_shadows[25].y > 0.0)\n    {\n        float _3165;\n        if (ci > 0)\n        {\n            int param_5 = ci - 1;\n            _3165 = fa_shadow_split_at(param_5);\n        }\n        else\n        {\n            _3165 = fa_shadows[28].w;\n        }\n        int param_6 = ci;\n        float _3184 = fa_shadows[25].y * max(fa_shadow_split_at(param_6) - _3165, 9.9999997473787516355514526367188e-05);\n        int param_7 = ci;\n        float _3195 = clamp((_3073 - (fa_shadow_split_at(param_7) - _3184)) / _3184, 0.0, 1.0);\n        if (_3195 > 0.0)\n        {\n            float s2 = 1.0;\n            if ((ci + 1) < _3058)\n            {\n                int param_8 = ci + 1;\n                vec3 param_9 = world;\n                vec3 param_10 = n;\n                vec3 param_11 = l;\n                float _3216 = fa_shadow_cascade(param_8, param_9, param_10, param_11);\n                s2 = _3216;\n                if (_3216 < 0.0)\n                {\n                    s2 = s;\n                }\n            }\n            s = mix(s, s2, _3195);\n        }\n    }\n    return s;\n}\n\nfloat fa_shadow_factor(vec3 n, vec3 l)\n{\n    vec3 param = fa_world_pos;\n    vec3 param_1 = n;\n    vec3 param_2 = l;\n    return fa_shadow_sun(param, param_1, param_2);\n}\n\nfloat fa_shadow_local(int li, vec3 lpos, vec3 world, vec3 n, vec3 l)\n{\n    bool _2738 = fa_mesh_fs_params[5].z < 0.5;\n    bool _2745;\n    if (!_2738)\n    {\n        _2745 = fa_shadows[29].x < 0.5;\n    }\n    else\n    {\n        _2745 = _2738;\n    }\n    if (_2745)\n    {\n        return 1.0;\n    }\n    int param = (int(fa_shadows[29].x + 0.5) - 1) + li;\n    vec4 _2758 = fa_light_texel(param);\n    float _2759 = _2758.x;\n    if (_2759 < 0.0)\n    {\n        return 1.0;\n    }\n    int _2768 = int(_2759 + 0.5);\n    int param_1 = _2768;\n    vec4 _2772 = fa_light_texel(param_1);\n    int param_2 = _2768 + 1;\n    vec4 _2777 = fa_light_texel(param_2);\n    float fade = 1.0;\n    float _2780 = _2772.y;\n    if (_2780 > 0.0)\n    {\n        float _2797 = 1.0 - smoothstep(0.75 * _2780, _2780, length(world - fa_shadows[27].xyz));\n        fade = _2797;\n        if (_2797 <= 0.0)\n        {\n            return 1.0;\n        }\n    }\n    int face = 0;\n    if (_2772.x > 1.5)\n    {\n        vec3 param_3 = world - lpos;\n        face = fa_cube_face(param_3);\n    }\n    int _2821 = (_2768 + 2) + (face * 6);\n    int param_4 = _2821;\n    int param_5 = _2821 + 1;\n    int param_6 = _2821 + 3;\n    vec4 _2835 = fa_light_texel(param_6);\n    int param_7 = _2821 + 4;\n    vec4 _2840 = fa_light_texel(param_7);\n    int param_8 = _2821 + 5;\n    vec4 _2845 = fa_light_texel(param_8);\n    float _2857 = _2845.x * max(dot(_2835, vec4(world, 1.0)), 0.001000000047497451305389404296875);\n    float _2862 = clamp(dot(n, l), 0.0, 1.0);\n    float _2885 = clamp(dot(n, _2835.xyz), -1.0, 1.0);\n    float _2904 = min(sqrt(1.0 - (_2885 * _2885)) / max(abs(dot(n, world - lpos)) / max(dot(_2835, vec4(world, 1.0)), 0.001000000047497451305389404296875), 0.20000000298023223876953125), 4.0);\n    float _2907 = _2777.y;\n    float _2909;\n    if (_2907 > 0.0)\n    {\n        _2909 = _2907;\n    }\n    else\n    {\n        _2909 = 1.5 * _2857;\n    }\n    vec4 _2929 = vec4(world + (n * (_2909 * sqrt(1.0 - (_2862 * _2862)))), 1.0);\n    float _2933 = dot(_2835, _2929);\n    float _2936 = _2845.y;\n    if (_2933 < _2936)\n    {\n        return 1.0;\n    }\n    vec2 _2951 = vec2(dot(fa_light_texel(param_4), _2929), dot(fa_light_texel(param_5), _2929)) / vec2(_2933);\n    float _2953 = _2951.x;\n    bool _2956 = _2953 < _2840.x;\n    bool _2965;\n    if (!_2956)\n    {\n        _2965 = _2953 > _2840.z;\n    }\n    else\n    {\n        _2965 = _2956;\n    }\n    bool _2974;\n    if (!_2965)\n    {\n        _2974 = _2951.y < _2840.y;\n    }\n    else\n    {\n        _2974 = _2965;\n    }\n    bool _2983;\n    if (!_2974)\n    {\n        _2983 = _2951.y > _2840.w;\n    }\n    else\n    {\n        _2983 = _2974;\n    }\n    if (_2983)\n    {\n        return 1.0;\n    }\n    float _2989 = _2777.x;\n    float _2991;\n    if (_2989 > 0.0)\n    {\n        _2991 = _2989;\n    }\n    else\n    {\n        _2991 = 1.5 * _2857;\n    }\n    vec2 param_9 = _2951;\n    vec4 param_10 = _2840;\n    float param_11 = _2933 - (_2991 * (1.0 + (0.5 * _2904)));\n    float param_12 = _2857;\n    float param_13 = 1.0;\n    float param_14 = _2845.z * 0.25;\n    float param_15 = (_2857 * min(_2904, 3.0)) * 0.5;\n    vec3 param_16 = vec3(1.0, _2936, _2845.z);\n    int param_17 = int(_2772.z + 0.5);\n    float param_18 = _2772.w;\n    return mix(1.0, fa_shadow_filter(param_9, param_10, param_11, param_12, param_13, param_14, param_15, param_16, param_17, param_18), fade);\n}\n\nfloat fa_contact_shadow(int li, vec3 world, vec3 gn, vec3 l, float dist)\n{\n    bool _5132 = fa_mesh_fs_params[24].x < 0.5;\n    bool _5139;\n    if (!_5132)\n    {\n        _5139 = fa_shadows[29].x < 0.5;\n    }\n    else\n    {\n        _5139 = _5132;\n    }\n    if (_5139)\n    {\n        return 1.0;\n    }\n    int param = (int(fa_shadows[29].x + 0.5) - 1) + li;\n    vec4 _5152 = fa_light_texel(param);\n    float _5153 = _5152.y;\n    float len = _5153;\n    if (_5153 <= 0.0)\n    {\n        return 1.0;\n    }\n    float _5165 = length(world - fa_mesh_fs_params[0].xyz);\n    float _5175 = 1.0 - smoothstep(0.5 * fa_mesh_fs_params[25].x, fa_mesh_fs_params[25].x, _5165);\n    if (_5175 <= 0.0)\n    {\n        return 1.0;\n    }\n    float _5181 = len;\n    float _5184 = min(_5181, 0.89999997615814208984375 * dist);\n    len = _5184;\n    float _5189 = 0.004999999888241291046142578125 + (0.0030000000260770320892333984375 * _5165);\n    float _5194 = _5189 + (0.5 * _5184);\n    vec3 _5200 = world + (gn * _5189);\n    float _5202 = fa_shadow_noise();\n    float occ = 0.0;\n    float _5266;\n    for (int k = 0; k < 12; k++)\n    {\n        float _5217 = (float(k) + _5202) * 0.083333335816860198974609375;\n        vec3 _5225 = _5200 + (l * (_5217 * len));\n        vec4 _5231 = vec4(_5225, 1.0);\n        float _5237 = dot(fa_mesh_fs_params[28], _5231);\n        if (_5237 < 9.9999997473787516355514526367188e-05)\n        {\n            break;\n        }\n        vec2 _5257 = vec2(dot(fa_mesh_fs_params[26], _5231), dot(fa_mesh_fs_params[27], _5231)) / vec2(_5237);\n        float _5261 = _5257.x * 0.5;\n        float _5262 = _5261 + 0.5;\n        if (fa_mesh_fs_params[24].y > 0.5)\n        {\n            _5266 = (_5257.y * 0.5) + 0.5;\n        }\n        else\n        {\n            _5266 = 0.5 - (_5257.y * 0.5);\n        }\n        bool _5282 = _5262 < 0.0;\n        bool _5289;\n        if (!_5282)\n        {\n            _5289 = _5262 >= 1.0;\n        }\n        else\n        {\n            _5289 = _5282;\n        }\n        bool _5296;\n        if (!_5289)\n        {\n            _5296 = _5266 < 0.0;\n        }\n        else\n        {\n            _5296 = _5289;\n        }\n        bool _5303;\n        if (!_5296)\n        {\n            _5303 = _5266 >= 1.0;\n        }\n        else\n        {\n            _5303 = _5296;\n        }\n        if (_5303)\n        {\n            break;\n        }\n        vec4 _5322 = texelFetch(fa_screen_tex_fa_shadow_smp, ivec2(vec2(_5262, _5266) * fa_mesh_fs_params[24].zw), 0);\n        if (_5322.w < 0.5)\n        {\n            continue;\n        }\n        float _5341 = (dot(fa_mesh_fs_params[29].xyz, _5225) + fa_mesh_fs_params[29].w) - _5322.x;\n        if ((_5341 > _5189) && (_5341 < _5194))\n        {\n            occ = max(occ, (1.0 - (_5217 * _5217)) * smoothstep(0.0, 0.0500000007450580596923828125, min(min(_5262, 0.5 - _5261), min(_5266, 1.0 - _5266))));\n        }\n    }\n    return 1.0 - (occ * _5175);\n}\n\nLightSample fa_light_shadowed(int li, vec3 world_pos, vec3 gn)\n{\n    int param = li;\n    float _5807 = fa_baked_keep(param);\n    if (_5807 <= 0.0)\n    {\n        int param_1 = li;\n        return LightSample(vec3(0.0, 1.0, 0.0), vec3(0.0), 0.0, 1.0, 0.0, int(fa_light_type(param_1) + 0.5));\n    }\n    int param_2 = li;\n    vec3 param_3 = world_pos;\n    vec3 param_4 = gn;\n    LightSample _5833 = fa_light_sample_n(param_2, param_3, param_4);\n    vec3 _8357 = _5833.color;\n    float _8358 = _5833.attenuation;\n    float _8359 = _5833.shadow;\n    bool _5836 = _5833.type == 0;\n    if (_5836 && (li == 0))\n    {\n        vec3 param_5 = gn;\n        vec3 param_6 = _5833.direction;\n        float _5847 = fa_shadow_factor(param_5, param_6);\n        _8359 = _5847;\n        _8357 *= _5847;\n    }\n    else\n    {\n        bool _5858 = _5833.type != 0;\n        bool _5864;\n        if (_5858)\n        {\n            _5864 = _8358 > 0.0;\n        }\n        else\n        {\n            _5864 = _5858;\n        }\n        if (_5864)\n        {\n            int param_7 = li;\n            int param_8 = fa_light_base(param_7);\n            int param_9 = li;\n            vec3 param_10 = fa_light_texel(param_8).xyz;\n            vec3 param_11 = world_pos;\n            vec3 param_12 = gn;\n            vec3 param_13 = _5833.direction;\n            float _5883 = fa_shadow_local(param_9, param_10, param_11, param_12, param_13);\n            _8359 = _5883;\n            _8357 *= _5883;\n        }\n    }\n    bool _5893 = fa_mesh_fs_params[24].x > 0.5;\n    bool _5899;\n    if (_5893)\n    {\n        _5899 = _8358 > 0.0;\n    }\n    else\n    {\n        _5899 = _5893;\n    }\n    if (_5899)\n    {\n        float _5906;\n        if (_5836)\n        {\n            _5906 = 1000000000.0;\n        }\n        else\n        {\n            _5906 = _5833._distance;\n        }\n        int param_14 = li;\n        vec3 param_15 = world_pos;\n        vec3 param_16 = gn;\n        vec3 param_17 = _5833.direction;\n        float param_18 = _5906;\n        float _5924 = fa_contact_shadow(param_14, param_15, param_16, param_17, param_18);\n        _8359 *= _5924;\n        _8357 *= _5924;\n    }\n    float _5937 = _8358;\n    float _5938 = _5937 * _5807;\n    _8358 = _5938;\n    vec3 _5942 = _8357;\n    vec3 _5943 = _5942 * _5807;\n    _8357 = _5943;\n    return LightSample(_5833.direction, _5943, _5938, _8359, _5833._distance, _5833.type);\n}\n\nvec3 fa_ltc_tangent(vec3 n, vec3 v)\n{\n    vec3 _5977 = v - (n * dot(v, n));\n    vec3 t = _5977;\n    float _5981 = dot(_5977, _5977);\n    float l2 = _5981;\n    if (_5981 < 1.0000000133514319600180897396058e-10)\n    {\n        vec3 _5991;\n        if (abs(n.z) < 0.999000012874603271484375)\n        {\n            _5991 = cross(n, vec3(0.0, 0.0, 1.0));\n        }\n        else\n        {\n            _5991 = cross(n, vec3(1.0, 0.0, 0.0));\n        }\n        t = _5991;\n        l2 = dot(_5991, _5991);\n    }\n    return t * inversesqrt(l2);\n}\n\nvec3 fa_ltc_local(vec3 t1, vec3 n, vec3 p)\n{\n    return vec3(dot(t1, p), dot(cross(n, t1), p), dot(n, p));\n}\n\nvec3 fa_ltc_edge_vector(vec3 a, vec3 b)\n{\n    float _6026 = dot(a, a);\n    float _6030 = dot(b, b);\n    if ((_6026 < 1.0000000195414813782625560981111e-24) || (_6030 < 1.0000000195414813782625560981111e-24))\n    {\n        return vec3(0.0);\n    }\n    vec3 _6044 = a * inversesqrt(_6026);\n    vec3 _6049 = b * inversesqrt(_6030);\n    float _6053 = dot(_6044, _6049);\n    float _6056 = abs(_6053);\n    float g = (((((((((((0.0416471660137176513671875 * _6056) - 0.1924748718738555908203125) * _6056) + 0.4179156124591827392578125) * _6056) - 0.616057217121124267578125) * _6056) + 0.777722418308258056640625) * _6056) - 0.999542415142059326171875) * _6056) + 1.570791721343994140625;\n    if (_6053 < 0.0)\n    {\n        g = (3.1415927410125732421875 * inversesqrt(max(1.0 - (_6053 * _6053), 1.0000000116860974230803549289703e-07))) - g;\n    }\n    return cross(_6044, _6049) * g;\n}\n\nvoid fa_ltc_clip_edge(vec3 a, vec3 b, inout vec3 sum, inout vec3 leave, inout vec3 enter, inout vec2 seen)\n{\n    bool _6113 = a.z > 0.0;\n    bool _6117 = b.z > 0.0;\n    if (_6113 && _6117)\n    {\n        vec3 param = a;\n        vec3 param_1 = b;\n        sum += fa_ltc_edge_vector(param, param_1);\n    }\n    else\n    {\n        if (_6113 != _6117)\n        {\n            vec3 _6152 = a + ((b - a) * (a.z / (a.z - b.z)));\n            _6152.z = 0.0;\n            if (_6113)\n            {\n                vec3 param_2 = a;\n                vec3 param_3 = _6152;\n                sum += fa_ltc_edge_vector(param_2, param_3);\n                leave = _6152;\n                seen.x = 1.0;\n            }\n            else\n            {\n                vec3 param_4 = _6152;\n                vec3 param_5 = b;\n                sum += fa_ltc_edge_vector(param_4, param_5);\n                enter = _6152;\n                seen.y = 1.0;\n            }\n        }\n    }\n}\n\nfloat fa_ltc_quad(vec4 abcd, vec3 p0, vec3 p1, vec3 p2, vec3 p3)\n{\n    vec3 _6201 = vec3((abcd.x * p0.x) + (abcd.y * p0.z), p0.y, (abcd.z * p0.x) + (abcd.w * p0.z));\n    vec3 _6227 = vec3((abcd.x * p1.x) + (abcd.y * p1.z), p1.y, (abcd.z * p1.x) + (abcd.w * p1.z));\n    vec3 _6253 = vec3((abcd.x * p2.x) + (abcd.y * p2.z), p2.y, (abcd.z * p2.x) + (abcd.w * p2.z));\n    vec3 _6279 = vec3((abcd.x * p3.x) + (abcd.y * p3.z), p3.y, (abcd.z * p3.x) + (abcd.w * p3.z));\n    vec3 sum = vec3(0.0);\n    vec3 leave = vec3(0.0);\n    vec3 enter = vec3(0.0);\n    vec3 param = _6201;\n    vec3 param_1 = _6227;\n    vec3 param_2 = vec3(0.0);\n    vec3 param_3 = vec3(0.0);\n    vec3 param_4 = vec3(0.0);\n    vec2 param_5 = vec2(0.0);\n    fa_ltc_clip_edge(param, param_1, param_2, param_3, param_4, param_5);\n    sum = param_2;\n    leave = param_3;\n    enter = param_4;\n    vec3 param_6 = _6227;\n    vec3 param_7 = _6253;\n    vec3 param_8 = param_2;\n    vec3 param_9 = param_3;\n    vec3 param_10 = param_4;\n    vec2 param_11 = param_5;\n    fa_ltc_clip_edge(param_6, param_7, param_8, param_9, param_10, param_11);\n    sum = param_8;\n    leave = param_9;\n    enter = param_10;\n    vec3 param_12 = _6253;\n    vec3 param_13 = _6279;\n    vec3 param_14 = param_8;\n    vec3 param_15 = param_9;\n    vec3 param_16 = param_10;\n    vec2 param_17 = param_11;\n    fa_ltc_clip_edge(param_12, param_13, param_14, param_15, param_16, param_17);\n    sum = param_14;\n    leave = param_15;\n    enter = param_16;\n    vec3 param_18 = _6279;\n    vec3 param_19 = _6201;\n    vec3 param_20 = param_14;\n    vec3 param_21 = param_15;\n    vec3 param_22 = param_16;\n    vec2 param_23 = param_17;\n    fa_ltc_clip_edge(param_18, param_19, param_20, param_21, param_22, param_23);\n    sum = param_20;\n    leave = param_21;\n    enter = param_22;\n    if ((param_23.x * param_23.y) > 0.5)\n    {\n        vec3 param_24 = leave;\n        vec3 param_25 = enter;\n        sum += fa_ltc_edge_vector(param_24, param_25);\n    }\n    return sum.z * 0.15915493667125701904296875;\n}\n\nfloat fa_ltc_rect(vec4 abcd, vec3 center, vec3 ex, vec3 ey)\n{\n    vec4 param = abcd;\n    vec3 param_1 = (center - ex) - ey;\n    vec3 param_2 = (center + ex) - ey;\n    vec3 param_3 = (center + ex) + ey;\n    vec3 param_4 = (center - ex) + ey;\n    return abs(fa_ltc_quad(param, param_1, param_2, param_3, param_4));\n}\n\nfloat fa_area_form(vec4 m, float shape, vec3 pc, vec3 ex, vec3 ey)\n{\n    if ((shape < 0.5) || (shape > 1.5))\n    {\n        vec4 param = m;\n        vec3 param_1 = pc;\n        vec3 param_2 = ex;\n        vec3 param_3 = ey;\n        return fa_ltc_rect(param, param_1, param_2, param_3);\n    }\n    vec3 _6428 = (pc + (ex * 0.92387950420379638671875)) + (ey * 0.3826834261417388916015625);\n    vec3 _6452 = (pc - (ex * 0.92387950420379638671875)) + (ey * 0.3826834261417388916015625);\n    vec3 _6468 = (pc - (ex * 0.3826834261417388916015625)) - (ey * 0.92387950420379638671875);\n    vec4 param_4 = m;\n    vec3 param_5 = _6428;\n    vec3 param_6 = (pc + (ex * 0.3826834261417388916015625)) + (ey * 0.92387950420379638671875);\n    vec3 param_7 = (pc - (ex * 0.3826834261417388916015625)) + (ey * 0.92387950420379638671875);\n    vec3 param_8 = _6452;\n    vec4 param_9 = m;\n    vec3 param_10 = _6428;\n    vec3 param_11 = _6452;\n    vec3 param_12 = (pc - (ex * 0.92387950420379638671875)) - (ey * 0.3826834261417388916015625);\n    vec3 param_13 = _6468;\n    vec4 param_14 = m;\n    vec3 param_15 = _6428;\n    vec3 param_16 = _6468;\n    vec3 param_17 = (pc + (ex * 0.3826834261417388916015625)) - (ey * 0.92387950420379638671875);\n    vec3 param_18 = (pc + (ex * 0.92387950420379638671875)) - (ey * 0.3826834261417388916015625);\n    return abs((fa_ltc_quad(param_4, param_5, param_6, param_7, param_8) + fa_ltc_quad(param_9, param_10, param_11, param_12, param_13)) + fa_ltc_quad(param_14, param_15, param_16, param_17, param_18));\n}\n\nvec2 fa_ltc_uv(float roughness, float ndv)\n{\n    return ((vec2(clamp((roughness - 0.0500000007450580596923828125) * 1.0526316165924072265625, 0.0, 1.0), sqrt(clamp(1.0 - ndv, 0.0, 1.0))) * 63.0) + vec2(0.5)) * vec2(0.015625);\n}\n\nvec3 fa_area_shade(int li, vec3 world_pos, vec3 n, vec3 v, vec3 diffuse_color, vec3 f0, float f90, float roughness, float ndv, float window)\n{\n    int param = li;\n    int _6526 = fa_light_base(param);\n    int param_1 = _6526;\n    int param_2 = _6526 + 1;\n    int param_3 = _6526 + 2;\n    int param_4 = _6526 + 4;\n    vec4 _6548 = fa_light_texel(param_4);\n    int param_5 = _6526 + 5;\n    vec4 _6553 = fa_light_texel(param_5);\n    int param_6 = _6526 + 6;\n    vec4 _6558 = fa_light_texel(param_6);\n    float _6559 = _6558.w;\n    vec3 _6564 = fa_light_texel(param_1).xyz - world_pos;\n    bool _6566 = _6559 < 1.5;\n    bool _6573;\n    if (_6566)\n    {\n        _6573 = dot(normalize(fa_light_texel(param_3).xyz), _6564) >= 0.0;\n    }\n    else\n    {\n        _6573 = _6566;\n    }\n    if (_6573)\n    {\n        return vec3(0.0);\n    }\n    bool _6582 = (_6559 > 0.5) && _6566;\n    float _6586 = _6582 ? 1.0539000034332275390625 : 1.0;\n    vec3 _6589 = _6548.xyz;\n    float _6591 = _6548.w;\n    vec3 _6597 = _6553.xyz;\n    float _6599 = _6553.w;\n    vec3 up = _6597 * (_6599 * _6586);\n    float _6605;\n    if (_6582)\n    {\n        _6605 = (3.1415927410125732421875 * _6591) * _6591;\n    }\n    else\n    {\n        _6605 = (4.0 * _6591) * _6599;\n    }\n    if (_6559 > 1.5)\n    {\n        vec3 _6631 = cross(_6589, -_6564);\n        vec3 perp = _6631;\n        float _6635 = dot(_6631, _6631);\n        vec3 _6638;\n        if (_6635 > 1.0000000133514319600180897396058e-10)\n        {\n            _6638 = perp * inversesqrt(_6635);\n        }\n        else\n        {\n            _6638 = _6597;\n        }\n        perp = _6638;\n        up = _6638 * _6599;\n    }\n    float _6659 = max(_6605, 9.9999999747524270787835121154785e-07);\n    vec3 param_7 = n;\n    vec3 param_8 = v;\n    vec3 _6669 = fa_ltc_tangent(param_7, param_8);\n    vec3 param_9 = _6669;\n    vec3 param_10 = n;\n    vec3 param_11 = _6564;\n    vec3 _6677 = fa_ltc_local(param_9, param_10, param_11);\n    vec3 param_12 = _6669;\n    vec3 param_13 = n;\n    vec3 param_14 = _6589 * (_6591 * _6586);\n    vec3 _6685 = fa_ltc_local(param_12, param_13, param_14);\n    vec3 param_15 = _6669;\n    vec3 param_16 = n;\n    vec3 param_17 = up;\n    vec3 _6693 = fa_ltc_local(param_15, param_16, param_17);\n    vec4 param_18 = vec4(1.0, 0.0, 0.0, 1.0);\n    float param_19 = _6559;\n    vec3 param_20 = _6677;\n    vec3 param_21 = _6685;\n    vec3 param_22 = _6693;\n    float param_23 = roughness;\n    float param_24 = ndv;\n    vec2 _6712 = fa_ltc_uv(param_23, param_24) * 64.0;\n    vec2 param_25 = _6712;\n    vec2 param_26 = _6712 + vec2(64.0, 0.0);\n    vec4 _6722 = fa_atlas_fetch(param_26);\n    vec4 param_27 = fa_atlas_fetch(param_25);\n    float param_28 = _6559;\n    vec3 param_29 = _6677;\n    vec3 param_30 = _6685;\n    vec3 param_31 = _6693;\n    return (((diffuse_color * fa_area_form(param_18, param_19, param_20, param_21, param_22)) + (((f0 * _6722.x) + ((vec3(f90) - f0) * _6722.y)) * fa_area_form(param_27, param_28, param_29, param_30, param_31))) * fa_light_texel(param_2).xyz) * ((((3.1415927410125732421875 * dot(_6564, _6564)) + _6659) / _6659) * window);\n}\n\nvec3 fa_light_rgb(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 1;\n    return fa_light_texel(param_1).xyz;\n}\n\nfloat fa_d_charlie(float alpha, float ndh)\n{\n    float _4869 = 1.0 / alpha;\n    return ((2.0 + _4869) * pow(sqrt(max(1.0 - (ndh * ndh), 9.9999997473787516355514526367188e-05)), _4869)) * 0.15915493667125701904296875;\n}\n\nfloat fa_v_ashikhmin(float ndl, float ndv)\n{\n    return clamp(0.25 / max((ndl + ndv) - (ndl * ndv), 9.9999997473787516355514526367188e-05), 0.0, 1.0);\n}\n\nfloat fa_layers_coat(FaLayers L, vec3 l, vec3 h, float vdh)\n{\n    float _4904 = max(dot(L.nc, l), 0.0);\n    float _4910 = max(dot(L.nc, h), 0.0);\n    float _4919 = ((_4910 * _4910) * (L.coat_a2 - 1.0)) + 1.0;\n    return (((L.coat * (0.039999999105930328369140625 + (0.959999978542327880859375 * pow(clamp(1.0 - vdh, 0.0, 1.0), 5.0)))) * (((L.coat_a2 / ((3.1415927410125732421875 * _4919) * _4919)) * (0.5 / max(mix((2.0 * _4904) * L.coat_ndv, _4904 + L.coat_ndv, L.coat_alpha), 9.9999997473787516355514526367188e-05))) * 3.1415927410125732421875)) * step(9.9999997473787516355514526367188e-05, _4904)) * _4904;\n}\n\nvec3 fa_area_layers(FaLayers L, int li, vec3 world_pos, vec3 n, vec3 v, vec3 l, vec3 diffuse_color, vec3 f0, float roughness, float ndv, float window)\n{\n    int param = li;\n    vec3 param_1 = world_pos;\n    vec3 param_2 = n;\n    vec3 param_3 = v;\n    vec3 param_4 = diffuse_color;\n    vec3 param_5 = f0;\n    float param_6 = L.f90;\n    float param_7 = roughness;\n    float param_8 = ndv;\n    float param_9 = window;\n    float _6790;\n    if (L.sheen_on)\n    {\n        _6790 = L.sheen_scale;\n    }\n    else\n    {\n        _6790 = 1.0;\n    }\n    vec3 result = fa_area_shade(param, param_1, param_2, param_3, param_4, param_5, param_6, param_7, param_8, param_9) * (L.keep * _6790);\n    vec3 _6803 = normalize(l + v);\n    int param_10 = li;\n    vec3 _6814 = fa_light_rgb(param_10) * window;\n    if (L.sheen_on)\n    {\n        float _6823 = max(dot(n, l), 0.0);\n        float param_11 = L.sheen_alpha;\n        float param_12 = max(dot(n, _6803), 0.0);\n        float param_13 = _6823;\n        float param_14 = ndv;\n        result += ((L.sheen * _6814) * (((((fa_d_charlie(param_11, param_12) * fa_v_ashikhmin(param_13, param_14)) * 3.1415927410125732421875) * step(9.9999997473787516355514526367188e-05, _6823)) * _6823) * L.keep));\n    }\n    if (L.coat > 0.0)\n    {\n        FaLayers param_15 = L;\n        vec3 param_16 = l;\n        vec3 param_17 = _6803;\n        float param_18 = max(dot(v, _6803), 0.0);\n        result += (_6814 * fa_layers_coat(param_15, param_16, param_17, param_18));\n    }\n    return result;\n}\n\nfloat fa_d_ggx_aniso(float ndh, float tdh, float bdh, float at, float ab)\n{\n    float _4772 = tdh / at;\n    float _4776 = bdh / ab;\n    float _4788 = ((_4772 * _4772) + (_4776 * _4776)) + (ndh * ndh);\n    return 1.0 / ((((3.1415927410125732421875 * at) * ab) * _4788) * _4788);\n}\n\nfloat fa_lambda_ggx_aniso(float n, float t, float b, float at, float ab)\n{\n    return 0.5 * (sqrt(1.0 + (((((at * at) * t) * t) + (((ab * ab) * b) * b)) / max(n * n, 9.9999999392252902907785028219223e-09))) - 1.0);\n}\n\nfloat fa_v_ggx_aniso(float ndl, float ndv, float tdv, float bdv, float tdl, float bdl, float at, float ab)\n{\n    float param = ndv;\n    float param_1 = tdv;\n    float param_2 = bdv;\n    float param_3 = at;\n    float param_4 = ab;\n    float param_5 = ndl;\n    float param_6 = tdl;\n    float param_7 = bdl;\n    float param_8 = at;\n    float param_9 = ab;\n    return clamp(1.0 / ((4.0 * max(ndl * ndv, 9.9999997473787516355514526367188e-05)) * ((1.0 + fa_lambda_ggx_aniso(param, param_1, param_2, param_3, param_4)) + fa_lambda_ggx_aniso(param_5, param_6, param_7, param_8, param_9))), 0.0, 1.0);\n}\n\nvec3 fa_layers_light(FaLayers L, vec3 diffuse_color, vec3 f0, vec3 n, vec3 v, vec3 l, vec3 h, float ndl, float ndv, float ndh, float vdh, float alpha, float a2)\n{\n    float _4968 = step(9.9999997473787516355514526367188e-05, ndl);\n    float d_ggx;\n    float vis;\n    if (L.aniso != 0.0)\n    {\n        float param = ndh;\n        float param_1 = dot(L.t, h);\n        float param_2 = dot(L.b, h);\n        float param_3 = L.at;\n        float param_4 = L.ab;\n        d_ggx = fa_d_ggx_aniso(param, param_1, param_2, param_3, param_4);\n        float param_5 = ndl;\n        float param_6 = ndv;\n        float param_7 = dot(L.t, v);\n        float param_8 = dot(L.b, v);\n        float param_9 = dot(L.t, l);\n        float param_10 = dot(L.b, l);\n        float param_11 = L.at;\n        float param_12 = L.ab;\n        vis = fa_v_ggx_aniso(param_5, param_6, param_7, param_8, param_9, param_10, param_11, param_12);\n    }\n    else\n    {\n        float _5047 = ((ndh * ndh) * (a2 - 1.0)) + 1.0;\n        d_ggx = a2 / ((3.1415927410125732421875 * _5047) * _5047);\n        vis = 0.5 / max(mix((2.0 * ndl) * ndv, ndl + ndv, alpha), 9.9999997473787516355514526367188e-05);\n    }\n    vec3 base = diffuse_color + (((f0 + ((vec3(L.f90) - f0) * pow(clamp(1.0 - vdh, 0.0, 1.0), 5.0))) * ((d_ggx * vis) * 3.1415927410125732421875)) * _4968);\n    if (L.sheen_on)\n    {\n        float param_13 = L.sheen_alpha;\n        float param_14 = ndh;\n        float param_15 = ndl;\n        float param_16 = ndv;\n        base = (base * L.sheen_scale) + (L.sheen * (((fa_d_charlie(param_13, param_14) * fa_v_ashikhmin(param_15, param_16)) * 3.1415927410125732421875) * _4968));\n    }\n    vec3 result = base * (L.keep * ndl);\n    if (L.coat > 0.0)\n    {\n        FaLayers param_17 = L;\n        vec3 param_18 = l;\n        vec3 param_19 = h;\n        float param_20 = vdh;\n        result += vec3(fa_layers_coat(param_17, param_18, param_19, param_20));\n    }\n    return result;\n}\n\nvec2 fa_env_brdf(float rough, float ndv)\n{\n    vec4 _4178 = (vec4(-1.0, -0.0274999998509883880615234375, -0.572000026702880859375, 0.02199999988079071044921875) * rough) + vec4(1.0, 0.0425000004470348358154296875, 1.03999996185302734375, -0.039999999105930328369140625);\n    float _4181 = _4178.x;\n    return (vec2(-1.03999996185302734375, 1.03999996185302734375) * ((min(_4181 * _4181, exp2((-9.27999973297119140625) * ndv)) * _4181) + _4178.y)) + _4178.zw;\n}\n\nvec2 fa_oct_encode(vec3 d)\n{\n    vec3 _3437 = d / vec3(max((abs(d.x) + abs(d.y)) + abs(d.z), 9.9999999600419720025001879548654e-13));\n    float _3440 = _3437.x;\n    float _3442 = _3437.z;\n    vec2 e = vec2(_3440, _3442);\n    if (_3437.y < 0.0)\n    {\n        e = vec2((1.0 - abs(_3442)) * ((_3440 < 0.0) ? (-1.0) : 1.0), (1.0 - abs(_3440)) * ((_3442 < 0.0) ? (-1.0) : 1.0));\n    }\n    return e;\n}\n\nvec3 fa_probe_level(vec2 origin, float res, int lv, vec2 e)\n{\n    float _3489;\n    if (lv == 0)\n    {\n        _3489 = 0.0;\n    }\n    else\n    {\n        _3489 = res + 2.0;\n    }\n    float _3499;\n    if (lv == 0)\n    {\n        _3499 = 0.0;\n    }\n    else\n    {\n        _3499 = (res - (res / float(1 << (lv - 1)))) + (2.0 * float(lv - 1));\n    }\n    return textureLod(fa_probe_atlas_fa_env_smp, (((origin + vec2(_3489, _3499)) + vec2(1.0)) + (((e * 0.5) + vec2(0.5)) * (res / float(1 << lv)))) / fa_atlas_size(), 0.0).xyz;\n}\n\nvec3 fa_probe_radiance(vec2 origin, float res, vec3 d, float rough)\n{\n    float _3544;\n    if (res > 64.5)\n    {\n        _3544 = 5.0;\n    }\n    else\n    {\n        _3544 = (res > 32.5) ? 4.0 : 3.0;\n    }\n    float _3559 = clamp(rough, 0.0, 1.0) * (_3544 - 1.0);\n    int _3566 = int(min(floor(_3559), _3544 - 2.0));\n    float _3571 = _3559 - float(_3566);\n    vec3 param = d;\n    vec2 _3575 = fa_oct_encode(param);\n    vec2 param_1 = origin;\n    float param_2 = res;\n    int param_3 = _3566;\n    vec2 param_4 = _3575;\n    vec3 _3585 = fa_probe_level(param_1, param_2, param_3, param_4);\n    if (_3571 < 0.00200000009499490261077880859375)\n    {\n        return _3585;\n    }\n    vec2 param_5 = origin;\n    float param_6 = res;\n    int param_7 = _3566 + 1;\n    vec2 param_8 = _3575;\n    return mix(_3585, fa_probe_level(param_5, param_6, param_7, param_8), vec3(_3571));\n}\n\nvec3 fa_probe_box_dir(vec3 d, vec4 posw, vec4 bx, vec4 by, vec4 bz)\n{\n    if (posw.w < 0.5)\n    {\n        return d;\n    }\n    float _3655 = dot(bx.xyz, fa_world_pos) + bx.w;\n    float _3662 = dot(by.xyz, fa_world_pos) + by.w;\n    float _3669 = dot(bz.xyz, fa_world_pos) + bz.w;\n    float _3675 = dot(bx.xyz, d);\n    float _3679 = dot(by.xyz, d);\n    float _3683 = dot(bz.xyz, d);\n    float _3689;\n    if (_3675 > 9.9999999747524270787835121154785e-07)\n    {\n        _3689 = (1.0 - _3655) / _3675;\n    }\n    else\n    {\n        float _3703;\n        if (_3675 < (-9.9999999747524270787835121154785e-07))\n        {\n            _3703 = ((-1.0) - _3655) / _3675;\n        }\n        else\n        {\n            _3703 = 1000000015047466219876688855040.0;\n        }\n        _3689 = _3703;\n    }\n    float tx = _3689;\n    float _3720;\n    if (_3679 > 9.9999999747524270787835121154785e-07)\n    {\n        _3720 = (1.0 - _3662) / _3679;\n    }\n    else\n    {\n        float _3733;\n        if (_3679 < (-9.9999999747524270787835121154785e-07))\n        {\n            _3733 = ((-1.0) - _3662) / _3679;\n        }\n        else\n        {\n            _3733 = 1000000015047466219876688855040.0;\n        }\n        _3720 = _3733;\n    }\n    float ty = _3720;\n    float _3749;\n    if (_3683 > 9.9999999747524270787835121154785e-07)\n    {\n        _3749 = (1.0 - _3669) / _3683;\n    }\n    else\n    {\n        float _3762;\n        if (_3683 < (-9.9999999747524270787835121154785e-07))\n        {\n            _3762 = ((-1.0) - _3669) / _3683;\n        }\n        else\n        {\n            _3762 = 1000000015047466219876688855040.0;\n        }\n        _3749 = _3762;\n    }\n    float _3774 = tx;\n    float _3777 = (_3774 > 0.0) ? _3774 : 1000000015047466219876688855040.0;\n    tx = _3777;\n    float _3778 = ty;\n    float _3781 = (_3778 > 0.0) ? _3778 : 1000000015047466219876688855040.0;\n    ty = _3781;\n    float _3791 = min(_3777, min(_3781, (_3749 > 0.0) ? _3749 : 1000000015047466219876688855040.0));\n    if (_3791 > 100000001504746621987668885504.0)\n    {\n        return d;\n    }\n    vec3 _3807 = (fa_world_pos + (d * _3791)) - posw.xyz;\n    vec3 _3812;\n    if (dot(_3807, _3807) > 1.0000000133514319600180897396058e-10)\n    {\n        _3812 = normalize(_3807);\n    }\n    else\n    {\n        _3812 = d;\n    }\n    return _3812;\n}\n\nvec3 fa_probe_environment(vec4 tile, vec4 posw, vec4 bx, vec4 by, vec4 bz, inout vec3 d, float rough)\n{\n    vec3 param = d;\n    vec4 param_1 = posw;\n    vec4 param_2 = bx;\n    vec4 param_3 = by;\n    vec4 param_4 = bz;\n    d = fa_probe_box_dir(param, param_1, param_2, param_3, param_4);\n    vec2 param_5 = tile.xy;\n    float param_6 = tile.z;\n    vec3 param_7 = d;\n    float param_8 = rough;\n    return fa_probe_radiance(param_5, param_6, param_7, param_8);\n}\n\nvec3 fa_environment(vec3 d, float rough)\n{\n    float _3858 = (1.0 - fa_mesh_fs_params[42].w) - fa_mesh_fs_params[47].w;\n    vec3 outc = vec3(0.0);\n    if (_3858 > 0.0005000000237487256526947021484375)\n    {\n        vec3 base;\n        if (fa_mesh_fs_params[11].w > 0.5)\n        {\n            vec2 param = fa_mesh_fs_params[41].zw;\n            float param_1 = 128.0;\n            vec3 param_2 = d;\n            float param_3 = rough;\n            base = fa_probe_radiance(param, param_1, param_2, param_3);\n        }\n        else\n        {\n            float _3887 = rough * rough;\n            float _3918 = 0.60000002384185791015625 * _3887;\n            base = mix(mix(fa_mesh_fs_params[12].xyz * 0.550000011920928955078125, mix(fa_mesh_fs_params[12].xyz, fa_mesh_fs_params[11].xyz, vec3(pow(clamp(d.y * (1.0 - (0.699999988079071044921875 * _3887)), 0.0, 1.0), 0.550000011920928955078125))), vec3(smoothstep((-0.0500000007450580596923828125) - _3918, 0.0500000007450580596923828125 + _3918, d.y))), ((fa_mesh_fs_params[11].xyz + fa_mesh_fs_params[12].xyz) * 0.5) * 0.800000011920928955078125, vec3(_3887 * 0.60000002384185791015625));\n        }\n        outc = base * _3858;\n    }\n    if (fa_mesh_fs_params[42].w > 0.0)\n    {\n        vec4 param_4 = fa_mesh_fs_params[42];\n        vec4 param_5 = fa_mesh_fs_params[43];\n        vec4 param_6 = fa_mesh_fs_params[44];\n        vec4 param_7 = fa_mesh_fs_params[45];\n        vec4 param_8 = fa_mesh_fs_params[46];\n        vec3 param_9 = d;\n        float param_10 = rough;\n        vec3 _3977 = fa_probe_environment(param_4, param_5, param_6, param_7, param_8, param_9, param_10);\n        outc += (_3977 * fa_mesh_fs_params[42].w);\n    }\n    if (fa_mesh_fs_params[47].w > 0.0)\n    {\n        vec4 param_11 = fa_mesh_fs_params[47];\n        vec4 param_12 = fa_mesh_fs_params[48];\n        vec4 param_13 = fa_mesh_fs_params[49];\n        vec4 param_14 = fa_mesh_fs_params[50];\n        vec4 param_15 = fa_mesh_fs_params[51];\n        vec3 param_16 = d;\n        float param_17 = rough;\n        vec3 _4009 = fa_probe_environment(param_11, param_12, param_13, param_14, param_15, param_16, param_17);\n        outc += (_4009 * fa_mesh_fs_params[47].w);\n    }\n    return outc;\n}\n\nvec3 fa_layers_ibl(FaLayers L, vec3 n, vec3 v, vec3 f0, float roughness)\n{\n    vec3 rn = n;\n    if (L.aniso != 0.0)\n    {\n        vec3 _4655;\n        if (L.aniso >= 0.0)\n        {\n            _4655 = L.b;\n        }\n        else\n        {\n            _4655 = L.t;\n        }\n        rn = normalize(mix(n, cross(cross(_4655, v), _4655), vec3(abs(L.aniso))));\n    }\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05);\n    vec2 _4688 = fa_env_brdf(param, param_1);\n    vec3 param_2 = reflect(-v, rn);\n    float param_3 = roughness;\n    vec3 result = (fa_environment(param_2, param_3) * ((f0 * _4688.x) + (vec3(L.f90) * _4688.y))) * L.base_scale;\n    if (L.sheen_on)\n    {\n        vec3 param_4 = n;\n        float param_5 = L.sheen_rough;\n        result += ((L.sheen * (L.sheen_e * L.keep)) * fa_environment(param_4, param_5));\n    }\n    if (L.coat > 0.0)\n    {\n        float param_6 = L.coat_rough;\n        float param_7 = L.coat_ndv;\n        vec2 _4743 = fa_env_brdf(param_6, param_7);\n        vec3 param_8 = reflect(-v, L.nc);\n        float param_9 = L.coat_rough;\n        result += (fa_environment(param_8, param_9) * (L.coat * ((0.039999999105930328369140625 * _4743.x) + _4743.y)));\n    }\n    return result;\n}\n\nvec3 fa_sky_reflection(vec3 n, vec3 v, vec3 f0, float roughness)\n{\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05);\n    vec2 _4220 = fa_env_brdf(param, param_1);\n    vec3 param_2 = reflect(-v, n);\n    float param_3 = roughness;\n    return fa_environment(param_2, param_3) * ((f0 * _4220.x) + vec3(_4220.y));\n}\n\nvec2 fa_xm_size(int k)\n{\n    return max(floor(fa_mesh_fs_params[24].zw / vec2(exp2(float(k)))), vec2(1.0));\n}\n\nvec2 fa_xm_origin(int k)\n{\n    if (k == 0)\n    {\n        return vec2(0.0);\n    }\n    float y = 0.0;\n    for (int j = 1; j < k; j++)\n    {\n        int param = j;\n        y += fa_xm_size(param).y;\n    }\n    return vec2(fa_mesh_fs_params[24].z, y);\n}\n\nvec3 fa_xm_texel(vec2 size, vec2 origin, vec2 p)\n{\n    return texelFetch(fa_screen_tex_fa_shadow_smp, ivec2(origin + clamp(p, vec2(0.0), size - vec2(1.0))), 0).xyz;\n}\n\nvec3 fa_xm_level(int k, vec2 uv)\n{\n    int param = k;\n    vec2 _5445 = fa_xm_size(param);\n    int param_1 = k;\n    vec2 _5449 = fa_xm_origin(param_1);\n    vec2 _5455 = (uv * _5445) - vec2(0.5);\n    vec2 _5458 = fract(_5455);\n    vec2 _5461 = floor(_5455);\n    vec2 param_2 = _5445;\n    vec2 param_3 = _5449;\n    vec2 param_4 = _5461;\n    vec2 param_5 = _5445;\n    vec2 param_6 = _5449;\n    vec2 param_7 = _5461 + vec2(1.0, 0.0);\n    vec2 param_8 = _5445;\n    vec2 param_9 = _5449;\n    vec2 param_10 = _5461 + vec2(0.0, 1.0);\n    vec2 param_11 = _5445;\n    vec2 param_12 = _5449;\n    vec2 param_13 = _5461 + vec2(1.0);\n    vec3 _5503 = vec3(_5458.x);\n    return mix(mix(fa_xm_texel(param_2, param_3, param_4), fa_xm_texel(param_5, param_6, param_7), _5503), mix(fa_xm_texel(param_8, param_9, param_10), fa_xm_texel(param_11, param_12, param_13), _5503), vec3(_5458.y));\n}\n\nvec3 fa_xm_sample(vec2 uv, float lod)\n{\n    float _5522 = max(fa_mesh_fs_params[31].w - 1.0, 0.0);\n    float _5526 = clamp(lod, 0.0, _5522);\n    int _5530 = int(floor(_5526));\n    int param = _5530;\n    vec2 param_1 = uv;\n    vec3 c = fa_xm_level(param, param_1);\n    float _5540 = float(_5530);\n    float _5541 = _5526 - _5540;\n    bool _5543 = _5541 > 0.001000000047497451305389404296875;\n    bool _5550;\n    if (_5543)\n    {\n        _5550 = _5540 < _5522;\n    }\n    else\n    {\n        _5550 = _5543;\n    }\n    if (_5550)\n    {\n        int param_2 = _5530 + 1;\n        vec2 param_3 = uv;\n        c = mix(c, fa_xm_level(param_2, param_3), vec3(_5541));\n    }\n    return c;\n}\n\nvec3 fa_transmitted(Surface s, vec3 n, vec3 v, float roughness, vec3 f0, float f90, float keep, float tr, inout float blend)\n{\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05);\n    vec2 _5576 = fa_env_brdf(param, param_1);\n    vec3 through = ((vec3(1.0) - clamp((f0 * _5576.x) + (vec3(f90) * _5576.y), vec3(0.0), vec3(1.0))) * s.albedo) * (tr * keep);\n    float _5604 = max(s.thickness, 0.0);\n    bool _5609 = _5604 > 0.0;\n    if ((s.attenuation_distance > 0.0) && _5609)\n    {\n        through *= exp((-((-log(clamp(s.attenuation_color, vec3(9.9999997473787516355514526367188e-05), vec3(1.0)))) / vec3(s.attenuation_distance))) * _5604);\n    }\n    bool _5634 = fa_mesh_fs_params[30].w > 1.5;\n    bool _5641;\n    if (!_5634)\n    {\n        _5641 = fa_mesh_fs_params[30].w < 0.5;\n    }\n    else\n    {\n        _5641 = _5634;\n    }\n    if (_5641)\n    {\n        blend = clamp(dot(through, vec3(0.3333333432674407958984375)), 0.0, 0.980000019073486328125);\n        return vec3(0.0);\n    }\n    vec3 world = fa_world_pos;\n    if (_5609)\n    {\n        world += (refract(-v, n, 1.0 / max(s.ior, 1.0)) * _5604);\n    }\n    vec4 _5676 = vec4(world, 1.0);\n    float _5681 = dot(fa_mesh_fs_params[28], _5676);\n    vec2 uv = vec2(0.5);\n    if (_5681 > 9.9999997473787516355514526367188e-05)\n    {\n        vec2 _5699 = vec2(dot(fa_mesh_fs_params[26], _5676), dot(fa_mesh_fs_params[27], _5676)) / vec2(_5681);\n        float _5707;\n        if (fa_mesh_fs_params[24].y > 0.5)\n        {\n            _5707 = (_5699.y * 0.5) + 0.5;\n        }\n        else\n        {\n            _5707 = 0.5 - (_5699.y * 0.5);\n        }\n        uv = vec2((_5699.x * 0.5) + 0.5, _5707);\n    }\n    vec2 param_2 = clamp(uv, vec2(0.0), vec2(1.0));\n    float param_3 = (clamp(roughness, 0.0, 1.0) * clamp((2.0 * s.ior) - 2.0, 0.0, 1.0)) * max(fa_mesh_fs_params[31].w - 1.0, 0.0);\n    return through * fa_xm_sample(param_2, param_3);\n}\n\nvec3 fa_shadow_debug(vec3 color, vec3 world)\n{\n    if (fa_shadows[27].w < 0.5)\n    {\n        return color;\n    }\n    int _3240 = int(fa_shadows[25].x + 0.5);\n    float _3250 = dot(world - fa_shadows[27].xyz, fa_shadows[28].xyz);\n    vec3 tint = vec3(0.3499999940395355224609375);\n    bool _3255 = _3240 > 0;\n    bool _3264;\n    if (_3255)\n    {\n        int param = _3240 - 1;\n        _3264 = _3250 <= fa_shadow_split_at(param);\n    }\n    else\n    {\n        _3264 = _3255;\n    }\n    if (_3264)\n    {\n        tint = vec3(1.0, 0.1500000059604644775390625, 0.100000001490116119384765625);\n        bool _3270 = _3240 > 1;\n        bool _3277;\n        if (_3270)\n        {\n            _3277 = _3250 > fa_shadows[24].x;\n        }\n        else\n        {\n            _3277 = _3270;\n        }\n        if (_3277)\n        {\n            tint = vec3(0.100000001490116119384765625, 0.89999997615814208984375, 0.20000000298023223876953125);\n        }\n        bool _3283 = _3240 > 2;\n        bool _3290;\n        if (_3283)\n        {\n            _3290 = _3250 > fa_shadows[24].y;\n        }\n        else\n        {\n            _3290 = _3283;\n        }\n        if (_3290)\n        {\n            tint = vec3(0.1500000059604644775390625, 0.300000011920928955078125, 1.0);\n        }\n        bool _3296 = _3240 > 3;\n        bool _3303;\n        if (_3296)\n        {\n            _3303 = _3250 > fa_shadows[24].z;\n        }\n        else\n        {\n            _3303 = _3296;\n        }\n        if (_3303)\n        {\n            tint = vec3(1.0, 0.89999997615814208984375, 0.100000001490116119384765625);\n        }\n    }\n    return mix(color, tint, vec3(0.550000011920928955078125));\n}\n\nvoid main()\n{\n    fa_inst_load();\n    vec3 _8016 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _8016 = -_8016;\n    }\n    vec3 _7308 = normalize(fa_mesh_fs_params[0].xyz - fa_world_pos);\n    vec3 param = fa_world_pos;\n    fa_cluster_begin(param);\n    SurfaceInput param_1 = SurfaceInput(fa_world_pos, _8016, fa_world_tangent, fa_uv, fa_vertex_color, _7308, gl_FrontFacing);\n    Surface _7316 = fa_standard_surface(param_1);\n    vec3 _8047 = _7316.albedo;\n    float _8048 = _7316.alpha;\n    vec3 _8049 = _7316.normal;\n    float _8050 = _7316.metallic;\n    float _8051 = _7316.roughness;\n    float _8052 = _7316.occlusion;\n    vec3 _8053 = _7316.emission;\n    float _8054 = _7316.clearcoat;\n    float _8055 = _7316.clearcoat_roughness;\n    vec3 _8056 = _7316.sheen_color;\n    float _8057 = _7316.sheen_roughness;\n    float _8058 = _7316.anisotropy;\n    float _8059 = _7316.anisotropy_rotation;\n    float _8060 = _7316.specular;\n    float _8061 = _7316.ior;\n    vec3 _8062 = _7316.specular_color;\n    float _8063 = _7316.transmission;\n    float _8064 = _7316.thickness;\n    vec3 _8065 = _7316.attenuation_color;\n    float _8066 = _7316.attenuation_distance;\n    SurfaceInput param_2 = SurfaceInput(fa_world_pos, _8016, fa_world_tangent, fa_uv, fa_vertex_color, _7308, gl_FrontFacing);\n    Surface param_3 = _7316;\n    surface(param_2, param_3);\n    _8047 = param_3.albedo;\n    _8048 = param_3.alpha;\n    _8049 = param_3.normal;\n    _8050 = param_3.metallic;\n    _8051 = param_3.roughness;\n    _8052 = param_3.occlusion;\n    _8053 = param_3.emission;\n    _8054 = param_3.clearcoat;\n    _8055 = param_3.clearcoat_roughness;\n    _8056 = param_3.sheen_color;\n    _8057 = param_3.sheen_roughness;\n    _8058 = param_3.anisotropy;\n    _8059 = param_3.anisotropy_rotation;\n    _8060 = param_3.specular;\n    _8061 = param_3.ior;\n    _8062 = param_3.specular_color;\n    _8063 = param_3.transmission;\n    _8064 = param_3.thickness;\n    _8065 = param_3.attenuation_color;\n    _8066 = param_3.attenuation_distance;\n    vec3 param_4 = fa_world_pos;\n    vec3 param_5 = _8016;\n    vec3 param_6 = param_3.albedo;\n    vec3 param_7 = param_3.normal;\n    fa_apply_decals(param_4, param_5, param_6, param_7);\n    _8047 = param_6;\n    _8049 = param_7;\n    float fa_tr_blend = 0.0;\n    vec3 result;\n    if (fa_mesh_fs_params[3].w > 0.5)\n    {\n        result = _8047;\n    }\n    else\n    {\n        vec3 _7356 = normalize(_8049);\n        float _7363 = clamp(_8050, 0.0, 1.0);\n        float _7367 = clamp(_8051, 0.0500000007450580596923828125, 1.0);\n        float _7371 = _7367 * _7367;\n        float _7375 = _7371 * _7371;\n        float _7380 = max(dot(_7356, _7308), 9.9999997473787516355514526367188e-05);\n        float _7386 = 1.0 - _7363;\n        float _7387 = clamp(_8063, 0.0, 1.0) * _7386;\n        vec3 _7396 = (_8047 * _7386) * (1.0 - _7387);\n        vec3 _7403 = mix(vec3(0.039999999105930328369140625), _8047, vec3(_7363));\n        vec3 f0 = _7403;\n        SurfaceInput param_8 = SurfaceInput(fa_world_pos, _8016, fa_world_tangent, fa_uv, fa_vertex_color, _7308, gl_FrontFacing);\n        Surface param_9 = Surface(_8047, _8048, _8049, _8050, _8051, _8052, _8053, _8054, _8055, _8056, _8057, _8058, _8059, _8060, _8061, _8062, _8063, _8064, _8065, _8066);\n        vec3 param_10 = _7356;\n        vec3 param_11 = _7308;\n        float param_12 = _7363;\n        float param_13 = _7367;\n        vec3 param_14 = _7403;\n        FaLayers _7419 = fa_layers_setup(param_8, param_9, param_10, param_11, param_12, param_13, param_14);\n        f0 = param_14;\n        vec3 param_15 = _7356;\n        vec3 lit = (fa_indirect_diffuse(param_15) * _7396) * _8052;\n        if (_7419.on)\n        {\n            lit *= _7419.base_scale;\n        }\n        int _7441 = fa_cl_ndir + fa_cl_local;\n        for (int ln = 0; ln < _7441; ln++)\n        {\n            int param_16 = ln;\n            int _7454 = fa_cl_light(param_16);\n            int param_17 = _7454;\n            if (fa_baked_keep(param_17) <= 0.0)\n            {\n                continue;\n            }\n            int param_18 = _7454;\n            vec3 param_19 = fa_world_pos;\n            vec3 param_20 = _8016;\n            LightSample _7470 = fa_light_shadowed(param_18, param_19, param_20);\n            float _7478 = max(dot(_7356, _7470.direction), 0.0);\n            float _7484 = _7470.attenuation * _7470.shadow;\n            vec3 _7489 = normalize(_7470.direction + _7308);\n            float _7494 = max(dot(_7356, _7489), 0.0);\n            float _7499 = max(dot(_7308, _7489), 0.0);\n            bool _7506;\n            if (fa_light_is_area)\n            {\n                _7506 = !_7419.on;\n            }\n            else\n            {\n                _7506 = fa_light_is_area;\n            }\n            if (_7506)\n            {\n                int param_21 = _7454;\n                vec3 param_22 = fa_world_pos;\n                vec3 param_23 = _7356;\n                vec3 param_24 = _7308;\n                vec3 param_25 = _7396;\n                vec3 param_26 = f0;\n                float param_27 = 1.0;\n                float param_28 = _7367;\n                float param_29 = _7380;\n                float param_30 = _7484;\n                lit += fa_area_shade(param_21, param_22, param_23, param_24, param_25, param_26, param_27, param_28, param_29, param_30);\n            }\n            else\n            {\n                if (fa_light_is_area)\n                {\n                    FaLayers param_31 = _7419;\n                    int param_32 = _7454;\n                    vec3 param_33 = fa_world_pos;\n                    vec3 param_34 = _7356;\n                    vec3 param_35 = _7308;\n                    vec3 param_36 = _7470.direction;\n                    vec3 param_37 = _7396;\n                    vec3 param_38 = f0;\n                    float param_39 = _7367;\n                    float param_40 = _7380;\n                    float param_41 = _7484;\n                    lit += fa_area_layers(param_31, param_32, param_33, param_34, param_35, param_36, param_37, param_38, param_39, param_40, param_41);\n                }\n                else\n                {\n                    if (_7419.on)\n                    {\n                        FaLayers param_42 = _7419;\n                        vec3 param_43 = _7396;\n                        vec3 param_44 = f0;\n                        vec3 param_45 = _7356;\n                        vec3 param_46 = _7308;\n                        vec3 param_47 = _7470.direction;\n                        vec3 param_48 = _7489;\n                        float param_49 = _7478;\n                        float param_50 = _7380;\n                        float param_51 = _7494;\n                        float param_52 = _7499;\n                        float param_53 = _7371;\n                        float param_54 = _7375;\n                        int param_55 = _7454;\n                        lit += (fa_layers_light(param_42, param_43, param_44, param_45, param_46, param_47, param_48, param_49, param_50, param_51, param_52, param_53, param_54) * ((fa_light_rgb(param_55) * fa_light_tint) * _7484));\n                    }\n                    else\n                    {\n                        float _7612 = ((_7494 * _7494) * (_7375 - 1.0)) + 1.0;\n                        int param_56 = _7454;\n                        lit += (((_7396 + (((f0 + ((vec3(1.0) - f0) * pow(1.0 - _7499, 5.0))) * (((_7375 / ((3.1415927410125732421875 * _7612) * _7612)) * (0.5 / max(mix((2.0 * _7478) * _7380, _7478 + _7380, _7371), 9.9999997473787516355514526367188e-05))) * 3.1415927410125732421875)) * step(9.9999997473787516355514526367188e-05, _7478))) * (fa_light_rgb(param_56) * fa_light_tint)) * (_7478 * _7484));\n                    }\n                }\n            }\n        }\n        if (_7419.on)\n        {\n            FaLayers param_57 = _7419;\n            vec3 param_58 = _7356;\n            vec3 param_59 = _7308;\n            vec3 param_60 = f0;\n            float param_61 = _7367;\n            lit += (fa_layers_ibl(param_57, param_58, param_59, param_60, param_61) * _8052);\n        }\n        else\n        {\n            vec3 param_62 = _7356;\n            vec3 param_63 = _7308;\n            vec3 param_64 = f0;\n            float param_65 = _7367;\n            lit += (fa_sky_reflection(param_62, param_63, param_64, param_65) * _8052);\n        }\n        if (_7387 > 0.0)\n        {\n            float _7710;\n            if (_7419.on)\n            {\n                _7710 = _7419.f90;\n            }\n            else\n            {\n                _7710 = 1.0;\n            }\n            float _7718;\n            if (_7419.on)\n            {\n                _7718 = _7419.base_scale;\n            }\n            else\n            {\n                _7718 = 1.0;\n            }\n            Surface param_66 = Surface(_8047, _8048, _8049, _8050, _8051, _8052, _8053, _8054, _8055, _8056, _8057, _8058, _8059, _8060, _8061, _8062, _8063, _8064, _8065, _8066);\n            vec3 param_67 = _7356;\n            vec3 param_68 = _7308;\n            float param_69 = _7367;\n            vec3 param_70 = f0;\n            float param_71 = _7710;\n            float param_72 = _7718;\n            float param_73 = _7387;\n            float param_74 = fa_tr_blend;\n            vec3 _7742 = fa_transmitted(param_66, param_67, param_68, param_69, param_70, param_71, param_72, param_73, param_74);\n            fa_tr_blend = param_74;\n            lit += _7742;\n        }\n        result = lit;\n    }\n    vec3 _7749 = result;\n    vec3 _7750 = _7749 + _8053;\n    result = _7750;\n    vec3 param_75 = _7750;\n    vec3 param_76 = fa_world_pos;\n    result = fa_shadow_debug(param_75, param_76);\n    bool _7759 = fa_mesh_fs_params[7].w > 0.0;\n    bool _7766;\n    if (!_7759)\n    {\n        _7766 = fa_mesh_fs_params[8].y > 0.0;\n    }\n    else\n    {\n        _7766 = _7759;\n    }\n    if (_7766)\n    {\n        vec3 _7775 = fa_world_pos - fa_mesh_fs_params[0].xyz;\n        float _7781 = dot(_7775, fa_mesh_fs_params[9].xyz);\n        bool _7785 = fa_mesh_fs_params[9].w > 0.5;\n        float _7786;\n        if (_7785)\n        {\n            _7786 = _7781;\n        }\n        else\n        {\n            _7786 = length(_7775);\n        }\n        float _7798 = _7786 - fa_mesh_fs_params[8].x;\n        if (_7798 > 0.0)\n        {\n            float _7807 = fa_mesh_fs_params[7].w * _7798;\n            float tau = _7807 * _7807;\n            if (fa_mesh_fs_params[8].y > 0.0)\n            {\n                float _7823;\n                if (_7785)\n                {\n                    _7823 = fa_world_pos.y - (fa_mesh_fs_params[9].y * _7781);\n                }\n                else\n                {\n                    _7823 = fa_mesh_fs_params[0].y;\n                }\n                float _7844 = mix(_7823, fa_world_pos.y, clamp(fa_mesh_fs_params[8].x / _7786, 0.0, 1.0));\n                float _7848 = fa_world_pos.y - _7844;\n                float _7853 = _7844 - fa_mesh_fs_params[8].z;\n                float _7858 = fa_world_pos.y - fa_mesh_fs_params[8].z;\n                bool _7861 = _7853 <= 0.0;\n                bool _7862 = !_7861;\n                bool _7868;\n                if (_7862)\n                {\n                    _7868 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _7868 = _7861;\n                }\n                float _7869;\n                if (_7868)\n                {\n                    _7869 = fa_mesh_fs_params[8].y;\n                }\n                else\n                {\n                    _7869 = fa_mesh_fs_params[8].y * exp(-min(fa_mesh_fs_params[8].w * _7853, 80.0));\n                }\n                bool _7896;\n                if (_7862)\n                {\n                    _7896 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _7896 = _7861;\n                }\n                float _7897;\n                if (_7896)\n                {\n                    _7897 = fa_mesh_fs_params[8].y * _7853;\n                }\n                else\n                {\n                    _7897 = (fa_mesh_fs_params[8].y * (1.0 - exp(-min(fa_mesh_fs_params[8].w * _7853, 80.0)))) / fa_mesh_fs_params[8].w;\n                }\n                bool _7922 = _7858 <= 0.0;\n                bool _7929;\n                if (!_7922)\n                {\n                    _7929 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _7929 = _7922;\n                }\n                float _7930;\n                if (_7929)\n                {\n                    _7930 = fa_mesh_fs_params[8].y * _7858;\n                }\n                else\n                {\n                    _7930 = (fa_mesh_fs_params[8].y * (1.0 - exp(-min(fa_mesh_fs_params[8].w * _7858, 80.0)))) / fa_mesh_fs_params[8].w;\n                }\n                float _7957;\n                if (abs(_7848) < 0.001000000047497451305389404296875)\n                {\n                    _7957 = _7869;\n                }\n                else\n                {\n                    _7957 = (_7930 - _7897) / _7848;\n                }\n                tau += (_7798 * max(_7957, 0.0));\n            }\n            result = mix(result, fa_mesh_fs_params[7].xyz, vec3(clamp(1.0 - exp(-clamp(tau, 0.0, 80.0)), 0.0, 1.0)));\n        }\n    }\n    if (fa_tr_blend > 0.0)\n    {\n        float _7993 = 1.0 - fa_tr_blend;\n        result /= vec3(_7993);\n        _8048 *= _7993;\n    }\n    fa_frag_color = vec4(result, _8048);\n}\n\n",
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
            "slot": 4,
            "stage": "vertex",
            "size": 16,
            "struct_name": "fa_material_vs",
            "inst_name": "_68",
            "glsl_uniforms": [
              {
                "type": "vec4",
                "array_count": 1,
                "offset": 0,
                "glsl_name": "fa_material_vs"
              }
            ]
          },
          {
            "slot": 0,
            "stage": "vertex",
            "size": 176,
            "struct_name": "fa_mesh_vs_params",
            "inst_name": "_165",
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
            "inst_name": "_212",
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
            "size": 832,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_637",
            "glsl_uniforms": [
              {
                "type": "vec4",
                "array_count": 52,
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
            "inst_name": "_2304",
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
              "slot": 6,
              "stage": "fragment",
              "name": "height",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float"
            }
          },
          {
            "texture": {
              "slot": 10,
              "stage": "vertex",
              "name": "fa_vs_height",
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
            "slot": 6,
            "stage": "vertex",
            "name": "fa_vs_height_smp",
            "sampler_type": "filtering"
          },
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
            "name": "height_smp",
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
            "name": "fa_vs_height_fa_vs_height_smp",
            "view_name": "fa_vs_height",
            "sampler_name": "fa_vs_height_smp",
            "view_slot": 10,
            "sampler_slot": 6,
            "glsl_name": "fa_vs_height_fa_vs_height_smp"
          },
          {
            "slot": 1,
            "stage": "fragment",
            "name": "fa_light_tex_fa_shadow_smp",
            "view_name": "fa_light_tex",
            "sampler_name": "fa_shadow_smp",
            "view_slot": 24,
            "sampler_slot": 1,
            "glsl_name": "fa_light_tex_fa_shadow_smp"
          },
          {
            "slot": 2,
            "stage": "fragment",
            "name": "fa_tex_fa_smp",
            "view_name": "fa_tex",
            "sampler_name": "fa_smp",
            "view_slot": 0,
            "sampler_slot": 0,
            "glsl_name": "fa_tex_fa_smp"
          },
          {
            "slot": 3,
            "stage": "fragment",
            "name": "fa_normal_tex_fa_smp",
            "view_name": "fa_normal_tex",
            "sampler_name": "fa_smp",
            "view_slot": 2,
            "sampler_slot": 0,
            "glsl_name": "fa_normal_tex_fa_smp"
          },
          {
            "slot": 4,
            "stage": "fragment",
            "name": "fa_mr_tex_fa_smp",
            "view_name": "fa_mr_tex",
            "sampler_name": "fa_smp",
            "view_slot": 3,
            "sampler_slot": 0,
            "glsl_name": "fa_mr_tex_fa_smp"
          },
          {
            "slot": 5,
            "stage": "fragment",
            "name": "fa_occlusion_tex_fa_smp",
            "view_name": "fa_occlusion_tex",
            "sampler_name": "fa_smp",
            "view_slot": 4,
            "sampler_slot": 0,
            "glsl_name": "fa_occlusion_tex_fa_smp"
          },
          {
            "slot": 6,
            "stage": "fragment",
            "name": "fa_emissive_tex_fa_smp",
            "view_name": "fa_emissive_tex",
            "sampler_name": "fa_smp",
            "view_slot": 5,
            "sampler_slot": 0,
            "glsl_name": "fa_emissive_tex_fa_smp"
          },
          {
            "slot": 7,
            "stage": "fragment",
            "name": "height_height_smp",
            "view_name": "height",
            "sampler_name": "height_smp",
            "view_slot": 6,
            "sampler_slot": 2,
            "glsl_name": "height_height_smp"
          },
          {
            "slot": 8,
            "stage": "fragment",
            "name": "fa_decal_tex_fa_env_smp",
            "view_name": "fa_decal_tex",
            "sampler_name": "fa_env_smp",
            "view_slot": 27,
            "sampler_slot": 10,
            "glsl_name": "fa_decal_tex_fa_env_smp"
          },
          {
            "slot": 9,
            "stage": "fragment",
            "name": "fa_lightmap_fa_env_smp",
            "view_name": "fa_lightmap",
            "sampler_name": "fa_env_smp",
            "view_slot": 26,
            "sampler_slot": 10,
            "glsl_name": "fa_lightmap_fa_env_smp"
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
          },
          {
            "slot": 11,
            "stage": "fragment",
            "name": "fa_light_atlas_fa_env_smp",
            "view_name": "fa_light_atlas",
            "sampler_name": "fa_env_smp",
            "view_slot": 25,
            "sampler_slot": 10,
            "glsl_name": "fa_light_atlas_fa_env_smp"
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
          },
          {
            "slot": 13,
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
      "vs": "#version 430\n\nstruct VertexData\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 color;\n    vec3 object_pos;\n};\n\nuniform vec4 fa_material_vs[1];\nuniform vec4 fa_mesh_vs_params[11];\nlayout(binding = 0) uniform sampler2D fa_vs_height_fa_vs_height_smp;\n\nlayout(location = 0) out vec3 fa_world_pos;\nlayout(location = 1) out vec3 fa_world_normal;\nlayout(location = 2) out vec4 fa_world_tangent;\nlayout(location = 3) out vec2 fa_uv;\nlayout(location = 4) out vec4 fa_vertex_color;\nlayout(location = 5) out float fa_pre_depth;\nlayout(location = 6) out vec3 fa_pre_r0;\nlayout(location = 7) out vec3 fa_pre_r1;\nlayout(location = 8) out vec3 fa_pre_r2;\nlayout(location = 5) in vec4 fa_inst_m0;\nlayout(location = 6) in vec4 fa_inst_m1;\nlayout(location = 7) in vec4 fa_inst_m2;\nlayout(location = 8) in vec4 fa_inst_m3;\nlayout(location = 0) in vec3 fa_position;\nlayout(location = 1) in vec3 fa_normal;\nlayout(location = 3) in vec4 fa_tangent;\nlayout(location = 2) in vec2 fa_texcoord0;\nlayout(location = 4) in vec4 fa_color;\n\nvoid fa_inst_begin()\n{\n}\n\nVertexData fa_vertex_data(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    vec3 _103 = cross(model[1].xyz, model[2].xyz);\n    float _108 = (dot(model[0].xyz, _103) < 0.0) ? (-1.0) : 1.0;\n    return VertexData((model * vec4(position, 1.0)).xyz, (((_103 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _108, vec4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _108), texcoord0 * fa_mesh_vs_params[8].xy, color, position);\n}\n\nvoid vertex(inout VertexData v)\n{\n    v.world_pos.y += (textureLod(fa_vs_height_fa_vs_height_smp, v.uv, 0.0).x * fa_material_vs[0].x);\n}\n\nvoid fa_prepass_vertex(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    mat4 param = model;\n    vec3 param_1 = position;\n    vec3 param_2 = normal;\n    vec4 param_3 = tangent;\n    vec2 param_4 = texcoord0;\n    vec4 param_5 = color;\n    VertexData param_6 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    vertex(param_6);\n    mat4 _197 = mat4(fa_mesh_vs_params[4], fa_mesh_vs_params[5], fa_mesh_vs_params[6], fa_mesh_vs_params[7]);\n    vec4 _204 = vec4(param_6.world_pos, 1.0);\n    fa_world_pos = param_6.world_pos;\n    fa_world_normal = param_6.world_normal;\n    fa_world_tangent = param_6.world_tangent;\n    fa_uv = param_6.uv;\n    fa_vertex_color = param_6.color;\n    fa_pre_depth = -(_197 * _204).z;\n    fa_pre_r0 = vec3(_197[0].x, _197[1].x, _197[2].x);\n    fa_pre_r1 = vec3(_197[0].y, _197[1].y, _197[2].y);\n    fa_pre_r2 = vec3(_197[0].z, _197[1].z, _197[2].z);\n    gl_Position = mat4(fa_mesh_vs_params[0], fa_mesh_vs_params[1], fa_mesh_vs_params[2], fa_mesh_vs_params[3]) * _204;\n}\n\nvoid main()\n{\n    fa_inst_begin();\n    mat4 param = mat4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3);\n    vec3 param_1 = fa_position;\n    vec3 param_2 = fa_normal;\n    vec4 param_3 = fa_tangent;\n    vec2 param_4 = fa_texcoord0;\n    vec4 param_5 = fa_color;\n    fa_prepass_vertex(param, param_1, param_2, param_3, param_4, param_5);\n}\n\n",
      "fs": "#version 430\n\nstruct SurfaceInput\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 vertex_color;\n    vec3 view_dir;\n    bool front_facing;\n};\n\nstruct Surface\n{\n    vec3 albedo;\n    float alpha;\n    vec3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    vec3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    vec3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    vec3 specular_color;\n    float transmission;\n    float thickness;\n    vec3 attenuation_color;\n    float attenuation_distance;\n};\n\nuniform vec4 fa_mesh_fs_params[52];\nlayout(binding = 0) uniform sampler2D fa_tex_fa_smp;\nlayout(binding = 1) uniform sampler2D fa_normal_tex_fa_smp;\nlayout(binding = 2) uniform sampler2D fa_mr_tex_fa_smp;\nlayout(binding = 3) uniform sampler2D fa_occlusion_tex_fa_smp;\nlayout(binding = 4) uniform sampler2D fa_emissive_tex_fa_smp;\nlayout(binding = 5) uniform sampler2D height_height_smp;\n\nlayout(location = 0) in vec3 fa_world_pos;\nlayout(location = 1) in vec3 fa_world_normal;\nlayout(location = 2) in vec4 fa_world_tangent;\nlayout(location = 3) in vec2 fa_uv;\nlayout(location = 4) in vec4 fa_vertex_color;\nlayout(location = 6) in vec3 fa_pre_r0;\nlayout(location = 7) in vec3 fa_pre_r1;\nlayout(location = 8) in vec3 fa_pre_r2;\nlayout(location = 0) out vec4 fa_frag_color;\nlayout(location = 5) in float fa_pre_depth;\n\nvoid fa_inst_load()\n{\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nvec3 fa_linear_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_tex_fix(inout vec3 c, float mode)\n{\n    if (mode > 1.5)\n    {\n        vec3 param = c;\n        vec3 _196 = fa_linear_to_srgb(param);\n        c = _196;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            vec3 param_1 = c;\n            vec3 _204 = fa_srgb_to_linear(param_1);\n            c = _204;\n        }\n    }\n    return c;\n}\n\nvec3 fa_tangent_normal(SurfaceInput i, vec3 m)\n{\n    vec3 _56;\n    if (i.front_facing)\n    {\n        _56 = i.world_normal;\n    }\n    else\n    {\n        _56 = -i.world_normal;\n    }\n    vec3 _81 = normalize(i.world_tangent.xyz - (_56 * dot(_56, i.world_tangent.xyz)));\n    vec3 _109 = normalize(((_81 * m.x) + ((cross(_56, _81) * i.world_tangent.w) * m.y)) + (_56 * m.z));\n    vec3 _112;\n    if (i.front_facing)\n    {\n        _112 = _109;\n    }\n    else\n    {\n        _112 = -_109;\n    }\n    return _112;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    vec4 base_t = texture(fa_tex_fa_smp, i.uv);\n    float param = fa_mesh_fs_params[6].w;\n    float param_1 = 1.0;\n    vec3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    vec3 _242 = fa_tex_fix(param_2, param_3);\n    vec4 _795 = base_t;\n    _795.x = _242.x;\n    _795.y = _242.y;\n    _795.z = _242.z;\n    base_t = _795;\n    vec4 _258 = (_795 * fa_mesh_fs_params[2]) * i.vertex_color;\n    vec3 _750 = i.world_normal;\n    if (fa_mesh_fs_params[6].z > 0.5)\n    {\n        float param_4 = fa_mesh_fs_params[6].w;\n        float param_5 = 16.0;\n        vec3 param_6 = texture(fa_normal_tex_fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        vec3 _291 = fa_tex_fix(param_6, param_7);\n        vec3 _295 = (_291 * 2.0) - vec3(1.0);\n        vec2 _300 = _295.xy * fa_mesh_fs_params[6].x;\n        vec3 _803 = _295;\n        _803.x = _300.x;\n        _803.y = _300.y;\n        SurfaceInput param_8 = i;\n        vec3 param_9 = _803;\n        _750 = fa_tangent_normal(param_8, param_9);\n    }\n    vec4 mrt = texture(fa_mr_tex_fa_smp, i.uv);\n    float param_10 = fa_mesh_fs_params[6].w;\n    float param_11 = 64.0;\n    vec3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    vec3 _329 = fa_tex_fix(param_12, param_13);\n    vec4 _806 = mrt;\n    _806.x = _329.x;\n    _806.y = _329.y;\n    _806.z = _329.z;\n    mrt = _806;\n    vec4 _359 = texture(fa_occlusion_tex_fa_smp, i.uv);\n    float param_14 = fa_mesh_fs_params[6].w;\n    float param_15 = 256.0;\n    vec3 param_16 = _359.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    vec3 _371 = fa_tex_fix(param_16, param_17);\n    float param_18 = fa_mesh_fs_params[6].w;\n    float param_19 = 4.0;\n    vec3 param_20 = texture(fa_emissive_tex_fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    vec3 _401 = fa_tex_fix(param_20, param_21);\n    float _755 = fa_mesh_fs_params[20].x;\n    float _756 = fa_mesh_fs_params[20].y;\n    float _759 = fa_mesh_fs_params[20].z;\n    float _758 = fa_mesh_fs_params[21].w;\n    float _761 = fa_mesh_fs_params[22].x;\n    if (fa_mesh_fs_params[22].z > 0.5)\n    {\n        if (mod(fa_mesh_fs_params[22].z, 2.0) > 0.5)\n        {\n            _755 *= _371.y;\n            _756 *= _371.z;\n            _758 *= _359.w;\n        }\n        if (fa_mesh_fs_params[22].z > 1.5)\n        {\n            _759 *= mrt.x;\n            _761 *= mrt.w;\n        }\n    }\n    return Surface(_258.xyz, _258.w, _750, clamp(fa_mesh_fs_params[5].x * _329.z, 0.0, 1.0), clamp(fa_mesh_fs_params[5].y * _329.y, 0.0500000007450580596923828125, 1.0), 1.0 + (fa_mesh_fs_params[6].y * (_371.x - 1.0)), fa_mesh_fs_params[3].xyz + (fa_mesh_fs_params[4].xyz * _401), _755, _756, fa_mesh_fs_params[21].xyz, _758, _759, fa_mesh_fs_params[20].w, _761, fa_mesh_fs_params[22].y, fa_mesh_fs_params[23].xyz, fa_mesh_fs_params[30].x, fa_mesh_fs_params[30].y, fa_mesh_fs_params[31].xyz, fa_mesh_fs_params[30].z);\n}\n\nvoid surface(SurfaceInput i, inout Surface s)\n{\n    s.albedo *= mix(0.5, 1.0, texture(height_height_smp, i.uv).x);\n}\n\nvoid main()\n{\n    fa_inst_load();\n    vec3 _645 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _645 = -_645;\n    }\n    vec3 _554 = normalize(fa_mesh_fs_params[0].xyz - fa_world_pos);\n    SurfaceInput param = SurfaceInput(fa_world_pos, _645, fa_world_tangent, fa_uv, fa_vertex_color, _554, gl_FrontFacing);\n    SurfaceInput param_1 = SurfaceInput(fa_world_pos, _645, fa_world_tangent, fa_uv, fa_vertex_color, _554, gl_FrontFacing);\n    Surface param_2 = fa_standard_surface(param);\n    surface(param_1, param_2);\n    vec3 _569 = normalize(param_2.normal);\n    vec3 _584 = normalize(vec3(dot(fa_pre_r0, _569), dot(fa_pre_r1, _569), dot(fa_pre_r2, _569)));\n    float _596 = _584.z;\n    vec2 e = _584.xy / vec2((abs(_584.x) + abs(_584.y)) + abs(_596));\n    if (_596 < 0.0)\n    {\n        e = (vec2(1.0) - abs(e.yx)) * vec2((e.x >= 0.0) ? 1.0 : (-1.0), (e.y >= 0.0) ? 1.0 : (-1.0));\n    }\n    fa_frag_color = vec4(min(fa_pre_depth, 60000.0), e, 1.0);\n}\n\n",
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
            "slot": 4,
            "stage": "vertex",
            "size": 16,
            "struct_name": "fa_material_vs",
            "inst_name": "_63",
            "glsl_uniforms": [
              {
                "type": "vec4",
                "array_count": 1,
                "offset": 0,
                "glsl_name": "fa_material_vs"
              }
            ]
          },
          {
            "slot": 0,
            "stage": "vertex",
            "size": 176,
            "struct_name": "fa_mesh_vs_params",
            "inst_name": "_160",
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
            "size": 832,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_231",
            "glsl_uniforms": [
              {
                "type": "vec4",
                "array_count": 52,
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
              "slot": 6,
              "stage": "fragment",
              "name": "height",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float"
            }
          },
          {
            "texture": {
              "slot": 10,
              "stage": "vertex",
              "name": "fa_vs_height",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float"
            }
          }
        ],
        "samplers": [
          {
            "slot": 6,
            "stage": "vertex",
            "name": "fa_vs_height_smp",
            "sampler_type": "filtering"
          },
          {
            "slot": 2,
            "stage": "fragment",
            "name": "height_smp",
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
            "name": "fa_vs_height_fa_vs_height_smp",
            "view_name": "fa_vs_height",
            "sampler_name": "fa_vs_height_smp",
            "view_slot": 10,
            "sampler_slot": 6,
            "glsl_name": "fa_vs_height_fa_vs_height_smp"
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
            "name": "height_height_smp",
            "view_name": "height",
            "sampler_name": "height_smp",
            "view_slot": 6,
            "sampler_slot": 2,
            "glsl_name": "height_height_smp"
          }
        ]
      }
    },
    "prepass_skin": {
      "vs": "#version 430\n\nstruct VertexData\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 color;\n    vec3 object_pos;\n};\n\nuniform vec4 fa_material_vs[1];\nuniform vec4 fa_mesh_vs_params[11];\nuniform vec4 fa_skin[192];\nlayout(binding = 0) uniform sampler2D fa_vs_height_fa_vs_height_smp;\n\nlayout(location = 0) out vec3 fa_world_pos;\nlayout(location = 1) out vec3 fa_world_normal;\nlayout(location = 2) out vec4 fa_world_tangent;\nlayout(location = 3) out vec2 fa_uv;\nlayout(location = 4) out vec4 fa_vertex_color;\nlayout(location = 5) out float fa_pre_depth;\nlayout(location = 6) out vec3 fa_pre_r0;\nlayout(location = 7) out vec3 fa_pre_r1;\nlayout(location = 8) out vec3 fa_pre_r2;\nlayout(location = 5) in vec4 fa_inst_m0;\nlayout(location = 6) in vec4 fa_inst_m1;\nlayout(location = 7) in vec4 fa_inst_m2;\nlayout(location = 8) in vec4 fa_inst_m3;\nlayout(location = 9) in vec4 fa_joints;\nlayout(location = 10) in vec4 fa_weights;\nlayout(location = 0) in vec3 fa_position;\nlayout(location = 1) in vec3 fa_normal;\nlayout(location = 3) in vec4 fa_tangent;\nlayout(location = 2) in vec2 fa_texcoord0;\nlayout(location = 4) in vec4 fa_color;\n\nvoid fa_inst_begin()\n{\n}\n\nmat4 fa_skin_matrix(vec4 joints, vec4 weights)\n{\n    vec4 r0 = vec4(0.0);\n    vec4 r1 = vec4(0.0);\n    vec4 r2 = vec4(0.0);\n    for (int i = 0; i < 4; i++)\n    {\n        int _203 = int((joints[i] * 255.0) + 0.5) * 3;\n        r0 += (fa_skin[_203 * 1 + 0] * weights[i]);\n        r1 += (fa_skin[(_203 + 1) * 1 + 0] * weights[i]);\n        r2 += (fa_skin[(_203 + 2) * 1 + 0] * weights[i]);\n    }\n    return mat4(vec4(r0.x, r1.x, r2.x, 0.0), vec4(r0.y, r1.y, r2.y, 0.0), vec4(r0.z, r1.z, r2.z, 0.0), vec4(r0.w, r1.w, r2.w, 1.0));\n}\n\nVertexData fa_vertex_data(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    vec3 _108 = cross(model[1].xyz, model[2].xyz);\n    float _113 = (dot(model[0].xyz, _108) < 0.0) ? (-1.0) : 1.0;\n    return VertexData((model * vec4(position, 1.0)).xyz, (((_108 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _113, vec4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _113), texcoord0 * fa_mesh_vs_params[8].xy, color, position);\n}\n\nvoid vertex(inout VertexData v)\n{\n    v.world_pos.y += (textureLod(fa_vs_height_fa_vs_height_smp, v.uv, 0.0).x * fa_material_vs[0].x);\n}\n\nvoid fa_prepass_vertex(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    mat4 param = model;\n    vec3 param_1 = position;\n    vec3 param_2 = normal;\n    vec4 param_3 = tangent;\n    vec2 param_4 = texcoord0;\n    vec4 param_5 = color;\n    VertexData param_6 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    vertex(param_6);\n    mat4 _310 = mat4(fa_mesh_vs_params[4], fa_mesh_vs_params[5], fa_mesh_vs_params[6], fa_mesh_vs_params[7]);\n    vec4 _317 = vec4(param_6.world_pos, 1.0);\n    fa_world_pos = param_6.world_pos;\n    fa_world_normal = param_6.world_normal;\n    fa_world_tangent = param_6.world_tangent;\n    fa_uv = param_6.uv;\n    fa_vertex_color = param_6.color;\n    fa_pre_depth = -(_310 * _317).z;\n    fa_pre_r0 = vec3(_310[0].x, _310[1].x, _310[2].x);\n    fa_pre_r1 = vec3(_310[0].y, _310[1].y, _310[2].y);\n    fa_pre_r2 = vec3(_310[0].z, _310[1].z, _310[2].z);\n    gl_Position = mat4(fa_mesh_vs_params[0], fa_mesh_vs_params[1], fa_mesh_vs_params[2], fa_mesh_vs_params[3]) * _317;\n}\n\nvoid main()\n{\n    fa_inst_begin();\n    vec4 param = fa_joints;\n    vec4 param_1 = fa_weights;\n    mat4 param_2 = mat4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3) * fa_skin_matrix(param, param_1);\n    vec3 param_3 = fa_position;\n    vec3 param_4 = fa_normal;\n    vec4 param_5 = fa_tangent;\n    vec2 param_6 = fa_texcoord0;\n    vec4 param_7 = fa_color;\n    fa_prepass_vertex(param_2, param_3, param_4, param_5, param_6, param_7);\n}\n\n",
      "fs": "#version 430\n\nstruct SurfaceInput\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 vertex_color;\n    vec3 view_dir;\n    bool front_facing;\n};\n\nstruct Surface\n{\n    vec3 albedo;\n    float alpha;\n    vec3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    vec3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    vec3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    vec3 specular_color;\n    float transmission;\n    float thickness;\n    vec3 attenuation_color;\n    float attenuation_distance;\n};\n\nuniform vec4 fa_mesh_fs_params[52];\nlayout(binding = 0) uniform sampler2D fa_tex_fa_smp;\nlayout(binding = 1) uniform sampler2D fa_normal_tex_fa_smp;\nlayout(binding = 2) uniform sampler2D fa_mr_tex_fa_smp;\nlayout(binding = 3) uniform sampler2D fa_occlusion_tex_fa_smp;\nlayout(binding = 4) uniform sampler2D fa_emissive_tex_fa_smp;\nlayout(binding = 5) uniform sampler2D height_height_smp;\n\nlayout(location = 0) in vec3 fa_world_pos;\nlayout(location = 1) in vec3 fa_world_normal;\nlayout(location = 2) in vec4 fa_world_tangent;\nlayout(location = 3) in vec2 fa_uv;\nlayout(location = 4) in vec4 fa_vertex_color;\nlayout(location = 6) in vec3 fa_pre_r0;\nlayout(location = 7) in vec3 fa_pre_r1;\nlayout(location = 8) in vec3 fa_pre_r2;\nlayout(location = 0) out vec4 fa_frag_color;\nlayout(location = 5) in float fa_pre_depth;\n\nvoid fa_inst_load()\n{\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nvec3 fa_linear_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_tex_fix(inout vec3 c, float mode)\n{\n    if (mode > 1.5)\n    {\n        vec3 param = c;\n        vec3 _196 = fa_linear_to_srgb(param);\n        c = _196;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            vec3 param_1 = c;\n            vec3 _204 = fa_srgb_to_linear(param_1);\n            c = _204;\n        }\n    }\n    return c;\n}\n\nvec3 fa_tangent_normal(SurfaceInput i, vec3 m)\n{\n    vec3 _56;\n    if (i.front_facing)\n    {\n        _56 = i.world_normal;\n    }\n    else\n    {\n        _56 = -i.world_normal;\n    }\n    vec3 _81 = normalize(i.world_tangent.xyz - (_56 * dot(_56, i.world_tangent.xyz)));\n    vec3 _109 = normalize(((_81 * m.x) + ((cross(_56, _81) * i.world_tangent.w) * m.y)) + (_56 * m.z));\n    vec3 _112;\n    if (i.front_facing)\n    {\n        _112 = _109;\n    }\n    else\n    {\n        _112 = -_109;\n    }\n    return _112;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    vec4 base_t = texture(fa_tex_fa_smp, i.uv);\n    float param = fa_mesh_fs_params[6].w;\n    float param_1 = 1.0;\n    vec3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    vec3 _242 = fa_tex_fix(param_2, param_3);\n    vec4 _795 = base_t;\n    _795.x = _242.x;\n    _795.y = _242.y;\n    _795.z = _242.z;\n    base_t = _795;\n    vec4 _258 = (_795 * fa_mesh_fs_params[2]) * i.vertex_color;\n    vec3 _750 = i.world_normal;\n    if (fa_mesh_fs_params[6].z > 0.5)\n    {\n        float param_4 = fa_mesh_fs_params[6].w;\n        float param_5 = 16.0;\n        vec3 param_6 = texture(fa_normal_tex_fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        vec3 _291 = fa_tex_fix(param_6, param_7);\n        vec3 _295 = (_291 * 2.0) - vec3(1.0);\n        vec2 _300 = _295.xy * fa_mesh_fs_params[6].x;\n        vec3 _803 = _295;\n        _803.x = _300.x;\n        _803.y = _300.y;\n        SurfaceInput param_8 = i;\n        vec3 param_9 = _803;\n        _750 = fa_tangent_normal(param_8, param_9);\n    }\n    vec4 mrt = texture(fa_mr_tex_fa_smp, i.uv);\n    float param_10 = fa_mesh_fs_params[6].w;\n    float param_11 = 64.0;\n    vec3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    vec3 _329 = fa_tex_fix(param_12, param_13);\n    vec4 _806 = mrt;\n    _806.x = _329.x;\n    _806.y = _329.y;\n    _806.z = _329.z;\n    mrt = _806;\n    vec4 _359 = texture(fa_occlusion_tex_fa_smp, i.uv);\n    float param_14 = fa_mesh_fs_params[6].w;\n    float param_15 = 256.0;\n    vec3 param_16 = _359.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    vec3 _371 = fa_tex_fix(param_16, param_17);\n    float param_18 = fa_mesh_fs_params[6].w;\n    float param_19 = 4.0;\n    vec3 param_20 = texture(fa_emissive_tex_fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    vec3 _401 = fa_tex_fix(param_20, param_21);\n    float _755 = fa_mesh_fs_params[20].x;\n    float _756 = fa_mesh_fs_params[20].y;\n    float _759 = fa_mesh_fs_params[20].z;\n    float _758 = fa_mesh_fs_params[21].w;\n    float _761 = fa_mesh_fs_params[22].x;\n    if (fa_mesh_fs_params[22].z > 0.5)\n    {\n        if (mod(fa_mesh_fs_params[22].z, 2.0) > 0.5)\n        {\n            _755 *= _371.y;\n            _756 *= _371.z;\n            _758 *= _359.w;\n        }\n        if (fa_mesh_fs_params[22].z > 1.5)\n        {\n            _759 *= mrt.x;\n            _761 *= mrt.w;\n        }\n    }\n    return Surface(_258.xyz, _258.w, _750, clamp(fa_mesh_fs_params[5].x * _329.z, 0.0, 1.0), clamp(fa_mesh_fs_params[5].y * _329.y, 0.0500000007450580596923828125, 1.0), 1.0 + (fa_mesh_fs_params[6].y * (_371.x - 1.0)), fa_mesh_fs_params[3].xyz + (fa_mesh_fs_params[4].xyz * _401), _755, _756, fa_mesh_fs_params[21].xyz, _758, _759, fa_mesh_fs_params[20].w, _761, fa_mesh_fs_params[22].y, fa_mesh_fs_params[23].xyz, fa_mesh_fs_params[30].x, fa_mesh_fs_params[30].y, fa_mesh_fs_params[31].xyz, fa_mesh_fs_params[30].z);\n}\n\nvoid surface(SurfaceInput i, inout Surface s)\n{\n    s.albedo *= mix(0.5, 1.0, texture(height_height_smp, i.uv).x);\n}\n\nvoid main()\n{\n    fa_inst_load();\n    vec3 _645 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _645 = -_645;\n    }\n    vec3 _554 = normalize(fa_mesh_fs_params[0].xyz - fa_world_pos);\n    SurfaceInput param = SurfaceInput(fa_world_pos, _645, fa_world_tangent, fa_uv, fa_vertex_color, _554, gl_FrontFacing);\n    SurfaceInput param_1 = SurfaceInput(fa_world_pos, _645, fa_world_tangent, fa_uv, fa_vertex_color, _554, gl_FrontFacing);\n    Surface param_2 = fa_standard_surface(param);\n    surface(param_1, param_2);\n    vec3 _569 = normalize(param_2.normal);\n    vec3 _584 = normalize(vec3(dot(fa_pre_r0, _569), dot(fa_pre_r1, _569), dot(fa_pre_r2, _569)));\n    float _596 = _584.z;\n    vec2 e = _584.xy / vec2((abs(_584.x) + abs(_584.y)) + abs(_596));\n    if (_596 < 0.0)\n    {\n        e = (vec2(1.0) - abs(e.yx)) * vec2((e.x >= 0.0) ? 1.0 : (-1.0), (e.y >= 0.0) ? 1.0 : (-1.0));\n    }\n    fa_frag_color = vec4(min(fa_pre_depth, 60000.0), e, 1.0);\n}\n\n",
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
            "slot": 4,
            "stage": "vertex",
            "size": 16,
            "struct_name": "fa_material_vs",
            "inst_name": "_68",
            "glsl_uniforms": [
              {
                "type": "vec4",
                "array_count": 1,
                "offset": 0,
                "glsl_name": "fa_material_vs"
              }
            ]
          },
          {
            "slot": 0,
            "stage": "vertex",
            "size": 176,
            "struct_name": "fa_mesh_vs_params",
            "inst_name": "_165",
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
            "inst_name": "_212",
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
            "size": 832,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_231",
            "glsl_uniforms": [
              {
                "type": "vec4",
                "array_count": 52,
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
              "slot": 6,
              "stage": "fragment",
              "name": "height",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float"
            }
          },
          {
            "texture": {
              "slot": 10,
              "stage": "vertex",
              "name": "fa_vs_height",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float"
            }
          }
        ],
        "samplers": [
          {
            "slot": 6,
            "stage": "vertex",
            "name": "fa_vs_height_smp",
            "sampler_type": "filtering"
          },
          {
            "slot": 2,
            "stage": "fragment",
            "name": "height_smp",
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
            "name": "fa_vs_height_fa_vs_height_smp",
            "view_name": "fa_vs_height",
            "sampler_name": "fa_vs_height_smp",
            "view_slot": 10,
            "sampler_slot": 6,
            "glsl_name": "fa_vs_height_fa_vs_height_smp"
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
            "name": "height_height_smp",
            "view_name": "height",
            "sampler_name": "height_smp",
            "view_slot": 6,
            "sampler_slot": 2,
            "glsl_name": "height_height_smp"
          }
        ]
      }
    },
    "shadow": {
      "vs": "#version 430\n\nstruct VertexData\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 color;\n    vec3 object_pos;\n};\n\nuniform vec4 fa_material_vs[1];\nuniform vec4 fa_mesh_vs_params[11];\nlayout(binding = 0) uniform sampler2D fa_vs_height_fa_vs_height_smp;\n\nlayout(location = 1) in vec4 fa_inst_m0;\nlayout(location = 2) in vec4 fa_inst_m1;\nlayout(location = 3) in vec4 fa_inst_m2;\nlayout(location = 4) in vec4 fa_inst_m3;\nlayout(location = 0) in vec3 fa_position;\nlayout(location = 5) in vec3 fa_normal;\nlayout(location = 7) in vec4 fa_tangent;\nlayout(location = 6) in vec2 fa_texcoord0;\nlayout(location = 8) in vec4 fa_color;\n\nvoid fa_inst_begin()\n{\n}\n\nVertexData fa_vertex_data(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    vec3 _94 = cross(model[1].xyz, model[2].xyz);\n    float _99 = (dot(model[0].xyz, _94) < 0.0) ? (-1.0) : 1.0;\n    return VertexData((model * vec4(position, 1.0)).xyz, (((_94 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _99, vec4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _99), texcoord0 * fa_mesh_vs_params[8].xy, color, position);\n}\n\nvoid vertex(inout VertexData v)\n{\n    v.world_pos.y += (textureLod(fa_vs_height_fa_vs_height_smp, v.uv, 0.0).x * fa_material_vs[0].x);\n}\n\nvoid main()\n{\n    fa_inst_begin();\n    mat4 param = mat4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3);\n    vec3 param_1 = fa_position;\n    vec3 param_2 = fa_normal;\n    vec4 param_3 = fa_tangent;\n    vec2 param_4 = fa_texcoord0;\n    vec4 param_5 = fa_color;\n    VertexData param_6 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    vertex(param_6);\n    gl_Position = mat4(fa_mesh_vs_params[4], fa_mesh_vs_params[5], fa_mesh_vs_params[6], fa_mesh_vs_params[7]) * vec4(param_6.world_pos, 1.0);\n}\n\n",
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
          }
        ],
        "uniform_blocks": [
          {
            "slot": 4,
            "stage": "vertex",
            "size": 16,
            "struct_name": "fa_material_vs",
            "inst_name": "_54",
            "glsl_uniforms": [
              {
                "type": "vec4",
                "array_count": 1,
                "offset": 0,
                "glsl_name": "fa_material_vs"
              }
            ]
          },
          {
            "slot": 0,
            "stage": "vertex",
            "size": 176,
            "struct_name": "fa_mesh_vs_params",
            "inst_name": "_151",
            "glsl_uniforms": [
              {
                "type": "vec4",
                "array_count": 11,
                "offset": 0,
                "glsl_name": "fa_mesh_vs_params"
              }
            ]
          }
        ],
        "views": [
          {
            "texture": {
              "slot": 10,
              "stage": "vertex",
              "name": "fa_vs_height",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float"
            }
          }
        ],
        "samplers": [
          {
            "slot": 6,
            "stage": "vertex",
            "name": "fa_vs_height_smp",
            "sampler_type": "filtering"
          }
        ],
        "texture_sampler_pairs": [
          {
            "slot": 0,
            "stage": "vertex",
            "name": "fa_vs_height_fa_vs_height_smp",
            "view_name": "fa_vs_height",
            "sampler_name": "fa_vs_height_smp",
            "view_slot": 10,
            "sampler_slot": 6,
            "glsl_name": "fa_vs_height_fa_vs_height_smp"
          }
        ]
      }
    },
    "shadow_skin": {
      "vs": "#version 430\n\nstruct VertexData\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 color;\n    vec3 object_pos;\n};\n\nuniform vec4 fa_material_vs[1];\nuniform vec4 fa_mesh_vs_params[11];\nuniform vec4 fa_skin[192];\nlayout(binding = 0) uniform sampler2D fa_vs_height_fa_vs_height_smp;\n\nlayout(location = 1) in vec4 fa_inst_m0;\nlayout(location = 2) in vec4 fa_inst_m1;\nlayout(location = 3) in vec4 fa_inst_m2;\nlayout(location = 4) in vec4 fa_inst_m3;\nlayout(location = 5) in vec4 fa_joints;\nlayout(location = 6) in vec4 fa_weights;\nlayout(location = 0) in vec3 fa_position;\nlayout(location = 7) in vec3 fa_normal;\nlayout(location = 9) in vec4 fa_tangent;\nlayout(location = 8) in vec2 fa_texcoord0;\nlayout(location = 10) in vec4 fa_color;\n\nmat4 fa_skin_matrix(vec4 joints, vec4 weights)\n{\n    vec4 r0 = vec4(0.0);\n    vec4 r1 = vec4(0.0);\n    vec4 r2 = vec4(0.0);\n    for (int i = 0; i < 4; i++)\n    {\n        int _194 = int((joints[i] * 255.0) + 0.5) * 3;\n        r0 += (fa_skin[_194 * 1 + 0] * weights[i]);\n        r1 += (fa_skin[(_194 + 1) * 1 + 0] * weights[i]);\n        r2 += (fa_skin[(_194 + 2) * 1 + 0] * weights[i]);\n    }\n    return mat4(vec4(r0.x, r1.x, r2.x, 0.0), vec4(r0.y, r1.y, r2.y, 0.0), vec4(r0.z, r1.z, r2.z, 0.0), vec4(r0.w, r1.w, r2.w, 1.0));\n}\n\nvoid fa_inst_begin()\n{\n}\n\nVertexData fa_vertex_data(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    vec3 _99 = cross(model[1].xyz, model[2].xyz);\n    float _104 = (dot(model[0].xyz, _99) < 0.0) ? (-1.0) : 1.0;\n    return VertexData((model * vec4(position, 1.0)).xyz, (((_99 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _104, vec4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _104), texcoord0 * fa_mesh_vs_params[8].xy, color, position);\n}\n\nvoid vertex(inout VertexData v)\n{\n    v.world_pos.y += (textureLod(fa_vs_height_fa_vs_height_smp, v.uv, 0.0).x * fa_material_vs[0].x);\n}\n\nvoid main()\n{\n    vec4 param = fa_joints;\n    vec4 param_1 = fa_weights;\n    fa_inst_begin();\n    mat4 param_2 = mat4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3) * fa_skin_matrix(param, param_1);\n    vec3 param_3 = fa_position;\n    vec3 param_4 = fa_normal;\n    vec4 param_5 = fa_tangent;\n    vec2 param_6 = fa_texcoord0;\n    vec4 param_7 = fa_color;\n    VertexData param_8 = fa_vertex_data(param_2, param_3, param_4, param_5, param_6, param_7);\n    vertex(param_8);\n    gl_Position = mat4(fa_mesh_vs_params[4], fa_mesh_vs_params[5], fa_mesh_vs_params[6], fa_mesh_vs_params[7]) * vec4(param_8.world_pos, 1.0);\n}\n\n",
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
          }
        ],
        "uniform_blocks": [
          {
            "slot": 4,
            "stage": "vertex",
            "size": 16,
            "struct_name": "fa_material_vs",
            "inst_name": "_59",
            "glsl_uniforms": [
              {
                "type": "vec4",
                "array_count": 1,
                "offset": 0,
                "glsl_name": "fa_material_vs"
              }
            ]
          },
          {
            "slot": 0,
            "stage": "vertex",
            "size": 176,
            "struct_name": "fa_mesh_vs_params",
            "inst_name": "_156",
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
            "inst_name": "_203",
            "glsl_uniforms": [
              {
                "type": "vec4",
                "array_count": 192,
                "offset": 0,
                "glsl_name": "fa_skin"
              }
            ]
          }
        ],
        "views": [
          {
            "texture": {
              "slot": 10,
              "stage": "vertex",
              "name": "fa_vs_height",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float"
            }
          }
        ],
        "samplers": [
          {
            "slot": 6,
            "stage": "vertex",
            "name": "fa_vs_height_smp",
            "sampler_type": "filtering"
          }
        ],
        "texture_sampler_pairs": [
          {
            "slot": 0,
            "stage": "vertex",
            "name": "fa_vs_height_fa_vs_height_smp",
            "view_name": "fa_vs_height",
            "sampler_name": "fa_vs_height_smp",
            "view_slot": 10,
            "sampler_slot": 6,
            "glsl_name": "fa_vs_height_fa_vs_height_smp"
          }
        ]
      }
    }
  }
}
