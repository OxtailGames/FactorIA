{
  "format": "factoria.shader/1",
  "engine": "0.38.0",
  "template": "f75e5e0880dc820037ae0c93c059e5f4f012f6ae7d85cbb082650e666c2ae84b",
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
      "fs": "#version 430\n\nstruct SurfaceInput\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 vertex_color;\n    vec3 view_dir;\n    bool front_facing;\n};\n\nstruct LightSample\n{\n    vec3 direction;\n    vec3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct Surface\n{\n    vec3 albedo;\n    float alpha;\n    vec3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    vec3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    vec3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    vec3 specular_color;\n    float transmission;\n    float thickness;\n    vec3 attenuation_color;\n    float attenuation_distance;\n};\n\nstruct FaLayers\n{\n    bool on;\n    float f90;\n    float keep;\n    float base_scale;\n    float coat;\n    float coat_rough;\n    float coat_alpha;\n    float coat_a2;\n    vec3 nc;\n    float coat_ndv;\n    bool sheen_on;\n    vec3 sheen;\n    float sheen_rough;\n    float sheen_alpha;\n    float sheen_scale;\n    float sheen_e;\n    float aniso;\n    vec3 t;\n    vec3 b;\n    float at;\n    float ab;\n};\n\nconst float _4819[63] = float[](1.0, 1.0, 1.0, 0.4790000021457672119140625, 0.11699999868869781494140625, 0.01200000010430812835693359375, 0.0, 0.0, 0.0, 1.0, 1.0, 1.0, 0.578000009059906005859375, 0.19300000369548797607421875, 0.0350000001490116119384765625, 0.0030000000260770320892333984375, 0.0, 0.0, 1.0, 1.0, 1.0, 0.6740000247955322265625, 0.3459999859333038330078125, 0.1319999992847442626953125, 0.032999999821186065673828125, 0.0040000001899898052215576171875, 0.0, 0.971000015735626220703125, 0.954999983310699462890625, 0.828999996185302734375, 0.63999998569488525390625, 0.42599999904632568359375, 0.24500000476837158203125, 0.115000002086162567138671875, 0.037000000476837158203125, 0.0030000000260770320892333984375, 0.7469999790191650390625, 0.737999975681304931640625, 0.670000016689300537109375, 0.563000023365020751953125, 0.4309999942779541015625, 0.3039999902248382568359375, 0.1940000057220458984375, 0.1019999980926513671875, 0.0309999994933605194091796875, 0.614000022411346435546875, 0.609000027179718017578125, 0.566999971866607666015625, 0.499000012874603271484375, 0.412000000476837158203125, 0.32400000095367431640625, 0.240999996662139892578125, 0.162000000476837158203125, 0.087999999523162841796875, 0.538999974727630615234375, 0.535000026226043701171875, 0.505999982357025146484375, 0.4569999873638153076171875, 0.393999993801116943359375, 0.328999996185302734375, 0.2660000026226043701171875, 0.203999996185302734375, 0.14200000464916229248046875);\n\nuniform vec4 fa_mesh_fs_params[53];\nuniform vec4 fa_shadows[30];\nlayout(binding = 0) uniform sampler2D fa_light_tex_fa_shadow_smp;\nlayout(binding = 1) uniform sampler2D fa_tex_fa_smp;\nlayout(binding = 2) uniform sampler2D fa_normal_tex_fa_smp;\nlayout(binding = 3) uniform sampler2D fa_mr_tex_fa_smp;\nlayout(binding = 4) uniform sampler2D fa_occlusion_tex_fa_smp;\nlayout(binding = 5) uniform sampler2D fa_emissive_tex_fa_smp;\nlayout(binding = 6) uniform sampler2D height_height_smp;\nlayout(binding = 7) uniform sampler2D fa_decal_tex_fa_env_smp;\nlayout(binding = 8) uniform sampler2D fa_lightmap_fa_env_smp;\nlayout(binding = 9) uniform sampler2D fa_probe_atlas_fa_env_smp;\nlayout(binding = 10) uniform sampler2D fa_light_atlas_fa_env_smp;\nlayout(binding = 11) uniform sampler2D fa_screen_tex_fa_shadow_smp;\nlayout(binding = 12) uniform sampler2D fa_shadow_tex_fa_shadow_smp;\n\nlayout(location = 0) in vec3 fa_world_pos;\nlayout(location = 5) in vec3 fa_lm;\nlayout(location = 1) in vec3 fa_world_normal;\nlayout(location = 2) in vec4 fa_world_tangent;\nlayout(location = 3) in vec2 fa_uv;\nlayout(location = 4) in vec4 fa_vertex_color;\nlayout(location = 0) out vec4 fa_frag_color;\nvec3 fa_light_tint;\nbool fa_light_is_area;\nint fa_cl_ndir;\nint fa_cl_slot;\nint fa_cl_local;\n\nvoid fa_inst_load()\n{\n}\n\nvec4 fa_light_texel(int t)\n{\n    return texelFetch(fa_light_tex_fa_shadow_smp, ivec2(t & 1023, t >> 10), 0);\n}\n\nvec4 fa_cluster_texel(vec3 world_pos)\n{\n    bool _1595 = fa_mesh_fs_params[19].x < 0.0;\n    bool _1602;\n    if (!_1595)\n    {\n        _1602 = fa_mesh_fs_params[19].w < 1.0;\n    }\n    else\n    {\n        _1602 = _1595;\n    }\n    bool _1610;\n    if (!_1602)\n    {\n        _1610 = fa_mesh_fs_params[18].x < 1.0;\n    }\n    else\n    {\n        _1610 = _1602;\n    }\n    bool _1617;\n    if (!_1610)\n    {\n        _1617 = fa_mesh_fs_params[18].y < 1.0;\n    }\n    else\n    {\n        _1617 = _1610;\n    }\n    bool _1624;\n    if (!_1617)\n    {\n        _1624 = fa_mesh_fs_params[19].y < 1.0;\n    }\n    else\n    {\n        _1624 = _1617;\n    }\n    if (_1624)\n    {\n        return vec4(0.0);\n    }\n    vec4 _1634 = vec4(world_pos, 1.0);\n    float _1640 = dot(fa_mesh_fs_params[16], _1634);\n    if (!(_1640 > 9.9999999747524270787835121154785e-07))\n    {\n        return vec4(0.0);\n    }\n    vec2 _1662 = vec2(dot(fa_mesh_fs_params[14], _1634), dot(fa_mesh_fs_params[15], _1634)) / vec2(_1640);\n    int _1666 = int(fa_mesh_fs_params[18].x);\n    int _1670 = int(fa_mesh_fs_params[18].y);\n    int param = (int(fa_mesh_fs_params[19].x) + (((clamp(int(floor(log2(max(dot(fa_mesh_fs_params[17].xyz, world_pos) + fa_mesh_fs_params[17].w, fa_mesh_fs_params[18].w) / fa_mesh_fs_params[18].w) * fa_mesh_fs_params[18].z)), 0, int(fa_mesh_fs_params[19].y) - 1) * _1670) + clamp(int(floor(((_1662.y * 0.5) + 0.5) * fa_mesh_fs_params[18].y)), 0, _1670 - 1)) * _1666)) + clamp(int(floor(((_1662.x * 0.5) + 0.5) * fa_mesh_fs_params[18].x)), 0, _1666 - 1);\n    return fa_light_texel(param);\n}\n\nivec2 fa_cluster_lookup(vec3 world_pos)\n{\n    vec3 param = world_pos;\n    vec4 _1746 = fa_cluster_texel(param);\n    return ivec2(int(_1746.x), int(_1746.y));\n}\n\nvoid fa_cluster_begin(vec3 world_pos)\n{\n    fa_cl_ndir = int(fa_mesh_fs_params[19].z);\n    vec3 param = world_pos;\n    ivec2 _6286 = fa_cluster_lookup(param);\n    fa_cl_slot = _6286.x;\n    fa_cl_local = _6286.y;\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nvec3 fa_linear_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_tex_fix(inout vec3 c, float mode)\n{\n    if (mode > 1.5)\n    {\n        vec3 param = c;\n        vec3 _7459 = fa_linear_to_srgb(param);\n        c = _7459;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            vec3 param_1 = c;\n            vec3 _7467 = fa_srgb_to_linear(param_1);\n            c = _7467;\n        }\n    }\n    return c;\n}\n\nvec3 fa_tangent_normal(SurfaceInput i, vec3 m)\n{\n    vec3 _539;\n    if (i.front_facing)\n    {\n        _539 = i.world_normal;\n    }\n    else\n    {\n        _539 = -i.world_normal;\n    }\n    vec3 _563 = normalize(i.world_tangent.xyz - (_539 * dot(_539, i.world_tangent.xyz)));\n    vec3 _590 = normalize(((_563 * m.x) + ((cross(_539, _563) * i.world_tangent.w) * m.y)) + (_539 * m.z));\n    vec3 _593;\n    if (i.front_facing)\n    {\n        _593 = _590;\n    }\n    else\n    {\n        _593 = -_590;\n    }\n    return _593;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    vec4 base_t = texture(fa_tex_fa_smp, i.uv, fa_mesh_fs_params[12].w);\n    float param = fa_mesh_fs_params[6].w;\n    float param_1 = 1.0;\n    vec3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    vec3 _7499 = fa_tex_fix(param_2, param_3);\n    vec4 _9793 = base_t;\n    _9793.x = _7499.x;\n    _9793.y = _7499.y;\n    _9793.z = _7499.z;\n    base_t = _9793;\n    vec4 _7513 = (_9793 * fa_mesh_fs_params[2]) * i.vertex_color;\n    vec3 _9548 = i.world_normal;\n    if (fa_mesh_fs_params[6].z > 0.5)\n    {\n        float param_4 = fa_mesh_fs_params[6].w;\n        float param_5 = 16.0;\n        vec3 param_6 = texture(fa_normal_tex_fa_smp, i.uv, fa_mesh_fs_params[12].w).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        vec3 _7547 = fa_tex_fix(param_6, param_7);\n        vec3 _7550 = (_7547 * 2.0) - vec3(1.0);\n        vec2 _7555 = _7550.xy * fa_mesh_fs_params[6].x;\n        vec3 _9801 = _7550;\n        _9801.x = _7555.x;\n        _9801.y = _7555.y;\n        SurfaceInput param_8 = i;\n        vec3 param_9 = _9801;\n        _9548 = fa_tangent_normal(param_8, param_9);\n    }\n    vec4 mrt = texture(fa_mr_tex_fa_smp, i.uv, fa_mesh_fs_params[12].w);\n    float param_10 = fa_mesh_fs_params[6].w;\n    float param_11 = 64.0;\n    vec3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    vec3 _7585 = fa_tex_fix(param_12, param_13);\n    vec4 _9804 = mrt;\n    _9804.x = _7585.x;\n    _9804.y = _7585.y;\n    _9804.z = _7585.z;\n    mrt = _9804;\n    vec4 _7615 = texture(fa_occlusion_tex_fa_smp, i.uv, fa_mesh_fs_params[12].w);\n    float param_14 = fa_mesh_fs_params[6].w;\n    float param_15 = 256.0;\n    vec3 param_16 = _7615.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    vec3 _7626 = fa_tex_fix(param_16, param_17);\n    float param_18 = fa_mesh_fs_params[6].w;\n    float param_19 = 4.0;\n    vec3 param_20 = texture(fa_emissive_tex_fa_smp, i.uv, fa_mesh_fs_params[12].w).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    vec3 _7658 = fa_tex_fix(param_20, param_21);\n    float _9553 = fa_mesh_fs_params[20].x;\n    float _9554 = fa_mesh_fs_params[20].y;\n    float _9557 = fa_mesh_fs_params[20].z;\n    float _9556 = fa_mesh_fs_params[21].w;\n    float _9559 = fa_mesh_fs_params[22].x;\n    if (fa_mesh_fs_params[22].z > 0.5)\n    {\n        if (mod(fa_mesh_fs_params[22].z, 2.0) > 0.5)\n        {\n            _9553 *= _7626.y;\n            _9554 *= _7626.z;\n            _9556 *= _7615.w;\n        }\n        if (fa_mesh_fs_params[22].z > 1.5)\n        {\n            _9557 *= mrt.x;\n            _9559 *= mrt.w;\n        }\n    }\n    return Surface(_7513.xyz, _7513.w, _9548, clamp(fa_mesh_fs_params[5].x * _7585.z, 0.0, 1.0), clamp(fa_mesh_fs_params[5].y * _7585.y, 0.0500000007450580596923828125, 1.0), 1.0 + (fa_mesh_fs_params[6].y * (_7626.x - 1.0)), fa_mesh_fs_params[3].xyz + (fa_mesh_fs_params[4].xyz * _7658), _9553, _9554, fa_mesh_fs_params[21].xyz, _9556, _9557, fa_mesh_fs_params[20].w, _9559, fa_mesh_fs_params[22].y, fa_mesh_fs_params[23].xyz, fa_mesh_fs_params[30].x, fa_mesh_fs_params[30].y, fa_mesh_fs_params[31].xyz, fa_mesh_fs_params[30].z);\n}\n\nvoid surface(SurfaceInput i, inout Surface s)\n{\n    s.albedo *= mix(0.5, 1.0, texture(height_height_smp, i.uv).x);\n}\n\nvec4 fa_decal_tile(vec4 rect, vec2 uv, vec2 atlas, vec2 ddx, vec2 ddy)\n{\n    vec2 _1826 = rect.zw - rect.xy;\n    vec2 _1830 = _1826 * atlas;\n    vec2 _1834 = ddx * _1830;\n    vec2 _1838 = ddy * _1830;\n    return textureLod(fa_decal_tex_fa_env_smp, rect.xy + (clamp(uv, vec2(0.0), vec2(1.0)) * _1826), clamp(0.5 * log2(max(max(dot(_1834, _1834), dot(_1838, _1838)), 9.9999999392252902907785028219223e-09)), 0.0, 3.0));\n}\n\nvec3 fa_dc_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_dc_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvoid fa_apply_decals(vec3 world_pos, vec3 geo_normal, inout vec3 albedo, inout vec3 normal)\n{\n    bool _1871 = fa_mesh_fs_params[10].y < 0.5;\n    bool _1878;\n    if (!_1871)\n    {\n        _1878 = fa_mesh_fs_params[10].w < 0.5;\n    }\n    else\n    {\n        _1878 = _1871;\n    }\n    if (_1878)\n    {\n        return;\n    }\n    vec3 _1884 = dFdx(world_pos);\n    vec3 _1887 = dFdy(world_pos);\n    vec3 param = world_pos;\n    vec4 _1891 = fa_cluster_texel(param);\n    int _1895 = int(_1891.w);\n    if (_1895 < 1)\n    {\n        return;\n    }\n    int _1905 = int(fa_mesh_fs_params[10].y + 0.5);\n    int param_1 = _1905;\n    vec4 _1909 = fa_light_texel(param_1);\n    vec2 _1912 = _1909.yz;\n    int _1916 = int(_1909.w);\n    int param_2 = _1905 + 1;\n    vec4 _1921 = fa_light_texel(param_2);\n    float _1922 = _1921.x;\n    int _1928 = int(fa_mesh_fs_params[10].w + 0.5) - 1;\n    int _1932 = int(_1891.z);\n    vec3 _2197;\n    for (int k = 0; k < _1895; k++)\n    {\n        int _1945 = _1932 + k;\n        int param_3 = _1916 + (_1945 >> 2);\n        int _1962 = (_1905 + 2) + (int(fa_light_texel(param_3)[_1945 & 3]) * 7);\n        int param_4 = _1962 + 6;\n        vec4 _1967 = fa_light_texel(param_4);\n        if (((int(_1967.w + 0.5) >> _1928) & 1) == 0)\n        {\n            continue;\n        }\n        int param_5 = _1962;\n        vec4 _1982 = fa_light_texel(param_5);\n        int param_6 = _1962 + 1;\n        vec4 _1987 = fa_light_texel(param_6);\n        int param_7 = _1962 + 2;\n        vec4 _1992 = fa_light_texel(param_7);\n        vec3 _1995 = _1982.xyz;\n        float _2000 = dot(_1995, world_pos) + _1982.w;\n        vec3 _2002 = _1987.xyz;\n        float _2007 = dot(_2002, world_pos) + _1987.w;\n        vec3 _2009 = _1992.xyz;\n        float _2014 = dot(_2009, world_pos) + _1992.w;\n        bool _2019 = abs(_2000) > 0.5;\n        bool _2027;\n        if (!_2019)\n        {\n            _2027 = abs(_2007) > 0.5;\n        }\n        else\n        {\n            _2027 = _2019;\n        }\n        bool _2035;\n        if (!_2027)\n        {\n            _2035 = abs(_2014) > 0.5;\n        }\n        else\n        {\n            _2035 = _2027;\n        }\n        if (_2035)\n        {\n            continue;\n        }\n        float _2050 = clamp(dot(geo_normal, normalize(_2009)) * _1967.z, 0.0, 1.0);\n        if (_2050 <= 0.0)\n        {\n            continue;\n        }\n        float _2070 = (clamp((0.5 - abs(_2014)) * 10.0, 0.0, 1.0) * _2050) * _1967.x;\n        vec2 _2078 = vec2(_2000 + 0.5, 0.5 - _2007);\n        vec2 _2088 = vec2(dot(_1995, _1884), dot(_2002, _1884));\n        vec2 _2098 = vec2(dot(_1995, _1887), dot(_2002, _1887));\n        int param_8 = _1962 + 5;\n        vec4 _2103 = fa_light_texel(param_8);\n        int param_9 = _1962 + 3;\n        vec4 _2108 = fa_light_texel(param_9);\n        int param_10 = _1962 + 4;\n        vec4 _2113 = fa_light_texel(param_10);\n        float tex_a = 1.0;\n        vec3 col = _2103.xyz;\n        bool _2123 = _2108.z > _2108.x;\n        if (_2123)\n        {\n            vec4 param_11 = _2108;\n            vec2 param_12 = _2078;\n            vec2 param_13 = _1912;\n            vec2 param_14 = _2088;\n            vec2 param_15 = _2098;\n            vec4 tx = fa_decal_tile(param_11, param_12, param_13, param_14, param_15);\n            if ((_1922 > 0.5) && (_1922 < 1.5))\n            {\n                vec3 param_16 = tx.xyz;\n                vec3 _2149 = fa_dc_to_linear(param_16);\n                vec4 _9636 = tx;\n                _9636.x = _2149.x;\n                _9636.y = _2149.y;\n                _9636.z = _2149.z;\n                tx = _9636;\n            }\n            col *= tx.xyz;\n            tex_a = tx.w;\n        }\n        albedo = mix(albedo, col, vec3(clamp((_2070 * tex_a) * _2103.w, 0.0, 1.0)));\n        if (_2113.z > _2113.x)\n        {\n            vec4 param_17 = _2113;\n            vec2 param_18 = _2078;\n            vec2 param_19 = _1912;\n            vec2 param_20 = _2088;\n            vec2 param_21 = _2098;\n            vec4 _2193 = fa_decal_tile(param_17, param_18, param_19, param_20, param_21);\n            if (_1922 > 1.5)\n            {\n                vec3 param_22 = _2193.xyz;\n                vec3 _2203 = fa_dc_to_srgb(param_22);\n                _2197 = _2203;\n            }\n            else\n            {\n                _2197 = _2193.xyz;\n            }\n            vec3 _2212 = (_2197 * 2.0) - vec3(1.0);\n            vec2 _2217 = _2212.xy * _1967.y;\n            vec3 _2239 = (normalize(_1995) * _2217.x) + (normalize(_2002) * _2217.y);\n            vec3 _2242 = normalize(normal);\n            normal = normalize(mix(_2242, normalize((_2242 * max(_2212.z, 0.0500000007450580596923828125)) + (_2239 - (_2242 * dot(_2242, _2239)))), vec3(clamp(_2070 * (_2123 ? tex_a : 1.0), 0.0, 1.0))));\n        }\n    }\n}\n\nfloat fa_sheen_albedo(float ndv, float rough)\n{\n    float _4744 = min(sqrt(max(rough - 0.100000001490116119384765625, 0.0) * 1.111111164093017578125) * 6.0, 5.999000072479248046875);\n    float _4752 = min(sqrt(clamp(ndv, 0.0, 1.0)) * 8.0, 7.999000072479248046875);\n    int _4755 = int(_4744);\n    int _4758 = int(_4752);\n    float _4768 = _4752 - float(_4758);\n    int _4823 = (_4755 * 9) + _4758;\n    int _4843 = ((_4755 + 1) * 9) + _4758;\n    return mix(mix(_4819[_4823], _4819[_4823 + 1], _4768), mix(_4819[_4843], _4819[_4843 + 1], _4768), _4744 - float(_4755));\n}\n\nFaLayers fa_layers_setup(SurfaceInput i, Surface s, vec3 n, vec3 v, float metallic, float roughness, inout vec3 f0)\n{\n    bool _9471 = false;\n    float _9472 = 1.0;\n    float _9473 = 1.0;\n    float _9474 = 1.0;\n    float _9475 = 0.0;\n    float _9476 = 0.0;\n    float _9477 = 0.0;\n    float _9478 = 0.0;\n    float _9480 = 1.0;\n    bool _9481 = false;\n    vec3 _9482 = vec3(0.0);\n    float _9483 = 1.0;\n    float _9484 = 1.0;\n    float _9485 = 1.0;\n    float _9486 = 0.0;\n    float _9487 = 0.0;\n    vec3 _9488 = vec3(1.0, 0.0, 0.0);\n    vec3 _9489 = vec3(0.0, 0.0, 1.0);\n    float _9490 = 1.0;\n    float _9491 = 1.0;\n    float _4894 = clamp(s.specular, 0.0, 1.0);\n    float _4898 = clamp(s.ior, 1.0, 3.0);\n    bool _4903 = (_4894 != 1.0) || (_4898 != 1.5);\n    bool _4912;\n    if (!_4903)\n    {\n        _4912 = any(notEqual(s.specular_color, vec3(1.0)));\n    }\n    else\n    {\n        _4912 = _4903;\n    }\n    if (_4912)\n    {\n        float _4920 = (_4898 - 1.0) / (_4898 + 1.0);\n        f0 = mix(min(vec3(_4920 * _4920) * max(s.specular_color, vec3(0.0)), vec3(1.0)) * _4894, s.albedo, vec3(metallic));\n        _9472 = mix(_4894, 1.0, metallic);\n        _9471 = true;\n    }\n    float _4947 = clamp(s.clearcoat, 0.0, 1.0);\n    if (_4947 > 0.0)\n    {\n        float _4955 = clamp(s.clearcoat_roughness, 0.0500000007450580596923828125, 1.0);\n        _9475 = _4947;\n        _9476 = _4955;\n        float _4962 = _4955 * _4955;\n        _9477 = _4962;\n        _9478 = _4962 * _4962;\n        float _4974 = max(dot(i.world_normal, v), 9.9999997473787516355514526367188e-05);\n        _9480 = _4974;\n        _9473 = 1.0 - (_4947 * (0.039999999105930328369140625 + (0.959999978542327880859375 * pow(clamp(1.0 - _4974, 0.0, 1.0), 5.0))));\n        _9471 = true;\n    }\n    vec3 _4993 = max(s.sheen_color, vec3(0.0));\n    float _5002 = max(_4993.x, max(_4993.y, _4993.z));\n    if (_5002 > 0.0)\n    {\n        float _5010 = clamp(s.sheen_roughness, 0.100000001490116119384765625, 1.0);\n        _9481 = true;\n        _9482 = _4993;\n        _9483 = _5010;\n        _9484 = _5010 * _5010;\n        float param = max(dot(n, v), 9.9999997473787516355514526367188e-05);\n        float param_1 = _5010;\n        float _5027 = fa_sheen_albedo(param, param_1);\n        _9486 = _5027;\n        _9485 = 1.0 - min(_5002 * _5027, 1.0);\n        _9471 = true;\n    }\n    _9474 = _9473 * _9485;\n    float _5046 = clamp(s.anisotropy, -1.0, 1.0);\n    if (_5046 != 0.0)\n    {\n        vec3 _5061 = i.world_tangent.xyz - (n * dot(n, i.world_tangent.xyz));\n        vec3 t = _5061;\n        if (dot(_5061, _5061) < 9.9999999392252902907785028219223e-09)\n        {\n            bvec3 _5073 = bvec3(abs(n.y) < 0.9900000095367431640625);\n            t = cross(vec3(_5073.x ? vec3(0.0, 1.0, 0.0).x : vec3(1.0, 0.0, 0.0).x, _5073.y ? vec3(0.0, 1.0, 0.0).y : vec3(1.0, 0.0, 0.0).y, _5073.z ? vec3(0.0, 1.0, 0.0).z : vec3(1.0, 0.0, 0.0).z), n);\n        }\n        vec3 _5077 = t;\n        vec3 _5078 = normalize(_5077);\n        t = _5078;\n        vec3 _5103 = normalize((_5078 * cos(s.anisotropy_rotation)) + ((cross(n, _5078) * ((i.world_tangent.w < 0.0) ? (-1.0) : 1.0)) * sin(s.anisotropy_rotation)));\n        _9488 = _5103;\n        _9489 = cross(n, _5103);\n        float _5113 = roughness * roughness;\n        float _5119 = mix(_5113, 1.0, _5046 * _5046);\n        bool _5121 = _5046 > 0.0;\n        _9490 = _5121 ? _5119 : _5113;\n        _9491 = _5121 ? _5113 : _5119;\n        _9487 = _5046;\n        _9471 = true;\n    }\n    return FaLayers(_9471, _9472, _9473, _9474, _9475, _9476, _9477, _9478, i.world_normal, _9480, _9481, _9482, _9483, _9484, _9485, _9486, _9487, _9488, _9489, _9490, _9491);\n}\n\nvec2 fa_atlas_size()\n{\n    return vec2(textureSize(fa_probe_atlas_fa_env_smp, 0));\n}\n\nvec3 fa_probe_sh_coef(vec2 origin, float res, int k)\n{\n    vec3 v = textureLod(fa_probe_atlas_fa_env_smp, (origin + vec2(float(k) + 0.5, res + 2.5)) / fa_atlas_size(), 0.0).xyz;\n    if (fa_mesh_fs_params[41].y > 0.5)\n    {\n        v = ((v * 255.0) - vec3(128.0)) * 0.03149606287479400634765625;\n    }\n    return v;\n}\n\nvec3 fa_sh_eval(vec3 c[9], vec3 n)\n{\n    vec3 _3914 = max((((c[0] * 0.2820948064327239990234375) + (((c[1] * (0.3257350027561187744140625 * n.y)) + (c[2] * (0.3257350027561187744140625 * n.z))) + (c[3] * (0.3257350027561187744140625 * n.x)))) + (((c[4] * ((0.2731371223926544189453125 * n.x) * n.y)) + (c[5] * ((0.2731371223926544189453125 * n.y) * n.z))) + (c[6] * (0.078847892582416534423828125 * (((3.0 * n.z) * n.z) - 1.0))))) + ((c[7] * ((0.2731371223926544189453125 * n.x) * n.z)) + (c[8] * (0.13656856119632720947265625 * ((n.x * n.x) - (n.y * n.y))))), vec3(0.0));\n    return _3914;\n}\n\nvec3 fa_ambient_light(vec3 n)\n{\n    float _4525 = (1.0 - fa_mesh_fs_params[42].w) - fa_mesh_fs_params[47].w;\n    vec3 amb = vec3(0.0);\n    bool _4530 = fa_mesh_fs_params[11].w > 0.5;\n    vec3 c[9];\n    for (int k = 0; k < 9; k++)\n    {\n        c[k] = vec3(0.0);\n    }\n    if (_4525 > 0.0005000000237487256526947021484375)\n    {\n        if (_4530)\n        {\n            for (int k_1 = 0; k_1 < 9; k_1++)\n            {\n                vec2 param = fa_mesh_fs_params[41].zw;\n                float param_1 = 128.0;\n                int param_2 = k_1;\n                c[k_1] = fa_probe_sh_coef(param, param_1, param_2) * _4525;\n            }\n        }\n        else\n        {\n            amb = fa_mesh_fs_params[1].xyz * _4525;\n        }\n    }\n    bool _4581 = fa_mesh_fs_params[42].w > 0.0;\n    if (_4581)\n    {\n        for (int k_2 = 0; k_2 < 9; k_2++)\n        {\n            vec2 param_3 = fa_mesh_fs_params[42].xy;\n            float param_4 = fa_mesh_fs_params[42].z;\n            int param_5 = k_2;\n            c[k_2] += (fa_probe_sh_coef(param_3, param_4, param_5) * fa_mesh_fs_params[42].w);\n        }\n    }\n    bool _4612 = fa_mesh_fs_params[47].w > 0.0;\n    if (_4612)\n    {\n        for (int k_3 = 0; k_3 < 9; k_3++)\n        {\n            vec2 param_6 = fa_mesh_fs_params[47].xy;\n            float param_7 = fa_mesh_fs_params[47].z;\n            int param_8 = k_3;\n            c[k_3] += (fa_probe_sh_coef(param_6, param_7, param_8) * fa_mesh_fs_params[47].w);\n        }\n    }\n    if ((_4530 || _4581) || _4612)\n    {\n        vec3 param_9[9] = c;\n        vec3 param_10 = n;\n        amb += fa_sh_eval(param_9, param_10);\n    }\n    return amb;\n}\n\nvec4 fa_gi_fetch(vec2 texel)\n{\n    return textureLod(fa_probe_atlas_fa_env_smp, texel / fa_atlas_size(), 0.0);\n}\n\nvec2 fa_oct_encode(vec3 d)\n{\n    vec3 _3934 = d / vec3(max((abs(d.x) + abs(d.y)) + abs(d.z), 9.9999999600419720025001879548654e-13));\n    float _3937 = _3934.x;\n    float _3939 = _3934.z;\n    vec2 e = vec2(_3937, _3939);\n    if (_3934.y < 0.0)\n    {\n        e = vec2((1.0 - abs(_3939)) * ((_3937 < 0.0) ? (-1.0) : 1.0), (1.0 - abs(_3937)) * ((_3939 < 0.0) ? (-1.0) : 1.0));\n    }\n    return e;\n}\n\nvec3 fa_gi_grid(int rec, vec3 n, vec3 v, out float cover)\n{\n    cover = 0.0;\n    int param = rec;\n    vec4 _7768 = fa_light_texel(param);\n    int param_1 = rec + 1;\n    vec4 _7773 = fa_light_texel(param_1);\n    int param_2 = rec + 2;\n    vec4 _7778 = fa_light_texel(param_2);\n    int param_3 = rec + 3;\n    vec4 _7783 = fa_light_texel(param_3);\n    bool _7786 = _7783.z < 0.5;\n    bool _7794;\n    if (!_7786)\n    {\n        _7794 = fa_atlas_size().y < 1155.0;\n    }\n    else\n    {\n        _7794 = _7786;\n    }\n    if (_7794)\n    {\n        return vec3(0.0);\n    }\n    float _7801 = max(_7768.w, 9.9999997473787516355514526367188e-05);\n    vec3 _7804 = _7773.xyz;\n    vec3 _7808 = _7768.xyz;\n    vec3 _7812 = (fa_world_pos - _7808) / vec3(_7801);\n    vec3 _7821 = min(_7812 + vec3(0.5), (_7804 - vec3(0.5)) - _7812);\n    float _7830 = min(_7821.x, min(_7821.y, _7821.z));\n    if (!(_7830 > 0.0))\n    {\n        return vec3(0.0);\n    }\n    vec3 _7845 = _7804 - vec3(1.0);\n    vec3 _7846 = clamp(_7812, vec3(0.0), _7845);\n    vec3 _7854 = min(floor(_7846), max(_7804 - vec3(2.0), vec3(0.0)));\n    vec3 _7858 = _7846 - _7854;\n    vec3 _7869 = fa_world_pos + (((n * 0.800000011920928955078125) + (v * 0.20000000298023223876953125)) * (0.20000000298023223876953125 * _7801));\n    int _7874 = int(_7778.y + 0.5);\n    float _7879 = 0.3257350027561187744140625 * n.y;\n    float _7883 = 0.3257350027561187744140625 * n.z;\n    float _7887 = 0.3257350027561187744140625 * n.x;\n    float _7894 = (0.2731371223926544189453125 * n.x) * n.y;\n    float _7901 = (0.2731371223926544189453125 * n.y) * n.z;\n    float _7910 = 0.078847892582416534423828125 * (((3.0 * n.z) * n.z) - 1.0);\n    float _7917 = (0.2731371223926544189453125 * n.x) * n.z;\n    float _7930 = 0.13656856119632720947265625 * ((n.x * n.x) - (n.y * n.y));\n    vec3 acc = vec3(0.0);\n    float wsum = 0.0;\n    int _7937 = 8 + int(_7783.w);\n    float _7964;\n    float _7977;\n    float _7991;\n    for (int k = 0; k < _7937; k++)\n    {\n        float _7950 = float(k & 1);\n        float _7954 = float((k >> 1) & 1);\n        float _7958 = float((k >> 2) & 1);\n        if (_7950 > 0.5)\n        {\n            _7964 = _7858.x;\n        }\n        else\n        {\n            _7964 = 1.0 - _7858.x;\n        }\n        if (_7954 > 0.5)\n        {\n            _7977 = _7858.y;\n        }\n        else\n        {\n            _7977 = 1.0 - _7858.y;\n        }\n        if (_7958 > 0.5)\n        {\n            _7991 = _7858.z;\n        }\n        else\n        {\n            _7991 = 1.0 - _7858.z;\n        }\n        float _8001 = (_7964 * _7977) * _7991;\n        if (!(_8001 > 0.0))\n        {\n            continue;\n        }\n        vec3 _8014 = min(_7854 + vec3(_7950, _7954, _7958), _7845);\n        int _8034 = int(((_7778.x + _8014.x) + (_7773.x * (_8014.y + (_7773.y * _8014.z)))) + 0.5);\n        vec2 _8049 = vec2(float(_8034 % _7874) * 10.0, 1024.0 + (float(_8034 / _7874) * 11.0));\n        vec2 param_4 = _8049 + vec2(9.5, 10.5);\n        vec4 _8057 = fa_gi_fetch(param_4);\n        bool _8060 = _8057.y < 0.5;\n        bool _8069;\n        if (!_8060)\n        {\n            _8069 = _8057.x > _7783.y;\n        }\n        else\n        {\n            _8069 = _8060;\n        }\n        if (_8069)\n        {\n            continue;\n        }\n        vec3 _8081 = _7869 - (_7808 + (_8014 * _7801));\n        float _8084 = length(_8081);\n        vec3 _8090 = _8081 / vec3(max(_8084, 9.9999997473787516355514526367188e-05));\n        float _8100 = max(9.9999997473787516355514526367188e-05, (dot(-_8090, n) + 1.0) * 0.5);\n        float w = _8001 * (_8100 * _8100);\n        vec3 param_5 = _8090;\n        vec2 param_6 = (_8049 + vec2(1.0)) + (((fa_oct_encode(param_5) * 0.5) + vec2(0.5)) * 8.0);\n        vec4 _8119 = fa_gi_fetch(param_6);\n        float _8126 = _8084 / max(_7778.z, 9.9999997473787516355514526367188e-05);\n        float _8129 = _8119.x;\n        if (_8126 > _8129)\n        {\n            float _8142 = max(_8119.y - (_8129 * _8129), 0.0);\n            float _8147 = _8126 - _8129;\n            float _8156 = _8142 / max(_8142 + (_8147 * _8147), 9.9999999600419720025001879548654e-13);\n            w *= ((_8156 * _8156) * _8156);\n        }\n        if (!(w > 0.0))\n        {\n            continue;\n        }\n        vec2 param_7 = _8049 + vec2(0.5, 10.5);\n        vec2 param_8 = _8049 + vec2(1.5, 10.5);\n        vec2 param_9 = _8049 + vec2(2.5, 10.5);\n        vec2 param_10 = _8049 + vec2(3.5, 10.5);\n        vec2 param_11 = _8049 + vec2(4.5, 10.5);\n        vec2 param_12 = _8049 + vec2(5.5, 10.5);\n        vec2 param_13 = _8049 + vec2(6.5, 10.5);\n        vec2 param_14 = _8049 + vec2(7.5, 10.5);\n        vec2 param_15 = _8049 + vec2(8.5, 10.5);\n        acc += ((((((((((fa_gi_fetch(param_7).xyz * 0.2820948064327239990234375) + (fa_gi_fetch(param_8).xyz * _7879)) + (fa_gi_fetch(param_9).xyz * _7883)) + (fa_gi_fetch(param_10).xyz * _7887)) + (fa_gi_fetch(param_11).xyz * _7894)) + (fa_gi_fetch(param_12).xyz * _7901)) + (fa_gi_fetch(param_13).xyz * _7910)) + (fa_gi_fetch(param_14).xyz * _7917)) + (fa_gi_fetch(param_15).xyz * _7930)) * w);\n        wsum += w;\n    }\n    if (!(wsum > 9.9999997473787516355514526367188e-06))\n    {\n        return vec3(0.0);\n    }\n    cover = smoothstep(0.0, 1.0, clamp(_7830 * 2.0, 0.0, 1.0)) * smoothstep(0.0, 0.0199999995529651641845703125, wsum);\n    float _8281;\n    if (fa_mesh_fs_params[52].z > 0.5)\n    {\n        _8281 = _7783.x;\n    }\n    else\n    {\n        _8281 = 1.0;\n    }\n    return max(acc / vec3(wsum), vec3(0.0)) * (_7778.w * _8281);\n}\n\nvec3 fa_gi_light(vec3 n, inout float left)\n{\n    left = 1.0;\n    vec3 acc = vec3(0.0);\n    vec3 _8305 = normalize(fa_mesh_fs_params[0].xyz - fa_world_pos);\n    int _8310 = int(fa_mesh_fs_params[52].x + 0.5);\n    int _8315 = int(fa_mesh_fs_params[52].y + 0.5);\n    float param_3;\n    for (int k = 0; (k < _8315) && (k < 8); k++)\n    {\n        int param = _8310 + (4 * k);\n        vec3 param_1 = n;\n        vec3 param_2 = _8305;\n        vec3 _8340 = fa_gi_grid(param, param_1, param_2, param_3);\n        float _8345 = param_3 * left;\n        acc += (_8340 * _8345);\n        left -= _8345;\n        if (left < 0.001000000047497451305389404296875)\n        {\n            left = 0.0;\n            break;\n        }\n    }\n    return acc;\n}\n\nvec3 fa_realtime_or_ambient(vec3 n)\n{\n    vec3 gi = vec3(0.0);\n    float left = 1.0;\n    if (fa_mesh_fs_params[52].y > 0.5)\n    {\n        vec3 param = n;\n        float param_1;\n        vec3 _8374 = fa_gi_light(param, param_1);\n        left = param_1;\n        gi = _8374;\n    }\n    if (left <= 0.0)\n    {\n        return gi;\n    }\n    vec3 param_2 = n;\n    return gi + (fa_ambient_light(param_2) * left);\n}\n\nvec3 fa_indirect_diffuse(vec3 n)\n{\n    if (fa_lm.z > 0.5)\n    {\n        return textureLod(fa_lightmap_fa_env_smp, fa_lm.xy, 0.0).xyz;\n    }\n    if (fa_mesh_fs_params[32].w > 0.0)\n    {\n        vec3 c[9];\n        for (int k = 0; k < 9; k++)\n        {\n            c[k] = fa_mesh_fs_params[k * 1 + 32].xyz;\n        }\n        vec3 param = n;\n        vec3 param_1[9] = c;\n        vec3 param_2 = n;\n        return mix(fa_ambient_light(param), fa_sh_eval(param_1, param_2), vec3(clamp(fa_mesh_fs_params[32].w, 0.0, 1.0)));\n    }\n    vec3 param_3 = n;\n    return fa_realtime_or_ambient(param_3);\n}\n\nint fa_cluster_index(int slot, int n)\n{\n    int param = (int(fa_mesh_fs_params[19].x) + int(fa_mesh_fs_params[19].w)) + ((slot + n) >> 2);\n    vec4 t = fa_light_texel(param);\n    return int(t[(slot + n) & 3]);\n}\n\nint fa_cl_light(int n)\n{\n    if (n < fa_cl_ndir)\n    {\n        return n;\n    }\n    int param = fa_cl_slot;\n    int param_1 = n - fa_cl_ndir;\n    return fa_cluster_index(param, param_1);\n}\n\nint fa_light_base(int li)\n{\n    return li * ((fa_mesh_fs_params[1].w > 4.5) ? 8 : 4);\n}\n\nbool fa_light_baked(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 3;\n    return fa_light_texel(param_1).w > 0.5;\n}\n\nfloat fa_baked_keep(int li)\n{\n    float _6256;\n    if (fa_lm.z > 0.5)\n    {\n        _6256 = 0.0;\n    }\n    else\n    {\n        _6256 = 1.0 - clamp(fa_mesh_fs_params[32].w, 0.0, 1.0);\n    }\n    bool _6267 = _6256 < 1.0;\n    bool _6273;\n    if (_6267)\n    {\n        int param = li;\n        _6273 = fa_light_baked(param);\n    }\n    else\n    {\n        _6273 = _6267;\n    }\n    return _6273 ? _6256 : 1.0;\n}\n\nfloat fa_light_type(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 1;\n    return fa_light_texel(param_1).w;\n}\n\nvec4 fa_atlas_fetch(vec2 texel)\n{\n    return textureLod(fa_light_atlas_fa_env_smp, texel / vec2(textureSize(fa_light_atlas_fa_env_smp, 0)), 0.0);\n}\n\nvec3 fa_cookie_sample(vec2 tile_origin, vec2 uv)\n{\n    vec2 param = (tile_origin + vec2(1.0)) + (clamp(uv, vec2(0.0), vec2(1.0)) * 254.0);\n    return fa_atlas_fetch(param).xyz;\n}\n\nvec3 fa_area_point(vec3 c, vec3 axis, vec3 ru, vec3 uu, float hx, float hy, float shape, vec3 p, vec3 r)\n{\n    bool _844 = dot(r, r) > 0.5;\n    if (shape > 1.5)\n    {\n        vec3 _857 = (c - (ru * hx)) - p;\n        vec3 _863 = ru * (2.0 * hx);\n        float _869 = max(dot(_863, _863), 9.9999999392252902907785028219223e-09);\n        float _873 = dot(_857, _863);\n        float t = clamp((-_873) / _869, 0.0, 1.0);\n        if (_844)\n        {\n            float _888 = dot(r, _863);\n            float _894 = _869 - (_888 * _888);\n            if (abs(_894) > (9.9999997473787516355514526367188e-06 * _869))\n            {\n                t = clamp(((dot(r, _857) * _888) - _873) / _894, 0.0, 1.0);\n            }\n        }\n        return (p + _857) + (_863 * t);\n    }\n    vec3 q = p;\n    float _926 = dot(r, axis);\n    bool _934;\n    if (_844)\n    {\n        _934 = abs(_926) > 9.9999997473787516355514526367188e-05;\n    }\n    else\n    {\n        _934 = _844;\n    }\n    if (_934)\n    {\n        float _944 = dot(c - p, axis) / _926;\n        if (_944 > 0.0)\n        {\n            q = p + (r * _944);\n        }\n    }\n    vec3 _957 = q - c;\n    vec2 xy = vec2(dot(_957, ru), dot(_957, uu));\n    if (shape > 0.5)\n    {\n        float _972 = length(xy);\n        if (_972 > hx)\n        {\n            xy *= (hx / _972);\n        }\n    }\n    else\n    {\n        xy = clamp(xy, vec2(-hx, -hy), vec2(hx, hy));\n    }\n    return (c + (ru * xy.x)) + (uu * xy.y);\n}\n\nint fa_cube_face(vec3 d)\n{\n    vec3 _605 = abs(d);\n    float _607 = _605.x;\n    float _609 = _605.y;\n    bool _610 = _607 >= _609;\n    bool _618;\n    if (_610)\n    {\n        _618 = _607 >= _605.z;\n    }\n    else\n    {\n        _618 = _610;\n    }\n    int _619;\n    if (_618)\n    {\n        _619 = (d.x > 0.0) ? 0 : 1;\n    }\n    else\n    {\n        int _634;\n        if (_609 >= _605.z)\n        {\n            _634 = (d.y > 0.0) ? 2 : 3;\n        }\n        else\n        {\n            _634 = (d.z > 0.0) ? 4 : 5;\n        }\n        _619 = _634;\n    }\n    return _619;\n}\n\nvoid fa_cube_face_basis(int f, out vec3 fwd, out vec3 up)\n{\n    if (f == 0)\n    {\n        fwd = vec3(1.0, 0.0, 0.0);\n        up = vec3(0.0, 1.0, 0.0);\n    }\n    else\n    {\n        if (f == 1)\n        {\n            fwd = vec3(-1.0, 0.0, 0.0);\n            up = vec3(0.0, 1.0, 0.0);\n        }\n        else\n        {\n            if (f == 2)\n            {\n                fwd = vec3(0.0, 1.0, 0.0);\n                up = vec3(0.0, 0.0, 1.0);\n            }\n            else\n            {\n                if (f == 3)\n                {\n                    fwd = vec3(0.0, -1.0, 0.0);\n                    up = vec3(0.0, 0.0, -1.0);\n                }\n                else\n                {\n                    if (f == 4)\n                    {\n                        fwd = vec3(0.0, 0.0, 1.0);\n                        up = vec3(0.0, 1.0, 0.0);\n                    }\n                    else\n                    {\n                        fwd = vec3(0.0, 0.0, -1.0);\n                        up = vec3(0.0, 1.0, 0.0);\n                    }\n                }\n            }\n        }\n    }\n}\n\nfloat fa_ies_sample(vec2 tile_origin, vec3 d, vec3 axis, vec3 right, vec3 up)\n{\n    float _764 = dot(d, right);\n    float _768 = dot(d, up);\n    float _779;\n    if (((_764 * _764) + (_768 * _768)) > 1.0000000133514319600180897396058e-10)\n    {\n        _779 = atan(_768, _764) * 0.15915493667125701904296875;\n    }\n    else\n    {\n        _779 = 0.0;\n    }\n    vec2 param = tile_origin + vec2(1.0 + ((_779 - floor(_779)) * 64.0), 1.0 + (acos(clamp(dot(d, axis), -1.0, 1.0)) * 10.18591594696044921875));\n    return fa_atlas_fetch(param).x;\n}\n\nLightSample fa_light_sample_n(int li, vec3 world_pos, vec3 n)\n{\n    int param = li;\n    int _1010 = fa_light_base(param);\n    bool _1014 = fa_mesh_fs_params[1].w > 4.5;\n    int param_1 = _1010;\n    vec4 _1018 = fa_light_texel(param_1);\n    int param_2 = _1010 + 1;\n    vec4 _1023 = fa_light_texel(param_2);\n    float _1026 = _1023.w;\n    float atten = 1.0;\n    float dist = 0.0;\n    fa_light_tint = vec3(1.0);\n    bool _1038 = _1014 && (_1026 > 2.5);\n    fa_light_is_area = _1038;\n    bool _1040 = _1026 < 0.5;\n    vec3 l;\n    if (_1040)\n    {\n        l = normalize(_1018.xyz);\n        if (_1014)\n        {\n            int param_3 = _1010 + 6;\n            vec4 _1054 = fa_light_texel(param_3);\n            if (_1054.z > 0.5)\n            {\n                int param_4 = _1010 + 4;\n                vec4 _1064 = fa_light_texel(param_4);\n                int param_5 = _1010 + 5;\n                vec4 _1069 = fa_light_texel(param_5);\n                vec2 param_6 = _1054.xy;\n                vec2 param_7 = fract(vec2(dot(world_pos, _1064.xyz) * _1064.w, (-dot(world_pos, _1069.xyz)) * _1069.w) + vec2(0.5));\n                fa_light_tint = fa_cookie_sample(param_6, param_7);\n            }\n        }\n    }\n    else\n    {\n        vec3 _1099 = _1018.xyz;\n        vec3 _1101 = _1099 - world_pos;\n        vec3 to_light = _1101;\n        float _1104 = length(_1101);\n        float reach = _1104;\n        bool front = true;\n        if (_1038)\n        {\n            int param_8 = _1010 + 7;\n            reach = max(_1104 - fa_light_texel(param_8).w, 0.0);\n            int param_9 = _1010 + 4;\n            vec4 _1128 = fa_light_texel(param_9);\n            int param_10 = _1010 + 5;\n            vec4 _1133 = fa_light_texel(param_10);\n            int param_11 = _1010 + 6;\n            vec4 _1138 = fa_light_texel(param_11);\n            float _1139 = _1138.w;\n            int param_12 = _1010 + 2;\n            vec3 _1146 = normalize(fa_light_texel(param_12).xyz);\n            bool _1148 = _1139 > 1.5;\n            bool _1156;\n            if (!_1148)\n            {\n                _1156 = dot(_1146, to_light) < 0.0;\n            }\n            else\n            {\n                _1156 = _1148;\n            }\n            front = _1156;\n            vec3 r = vec3(0.0);\n            vec3 _1165 = fa_mesh_fs_params[0].xyz - world_pos;\n            bool _1169 = dot(n, n) > 0.5;\n            bool _1177;\n            if (_1169)\n            {\n                _1177 = dot(_1165, _1165) > 9.9999999600419720025001879548654e-13;\n            }\n            else\n            {\n                _1177 = _1169;\n            }\n            if (_1177)\n            {\n                r = reflect(-normalize(_1165), normalize(n));\n            }\n            vec3 param_13 = _1099;\n            vec3 param_14 = _1146;\n            vec3 param_15 = _1128.xyz;\n            vec3 param_16 = _1133.xyz;\n            float param_17 = _1128.w;\n            float param_18 = _1133.w;\n            float param_19 = _1139;\n            vec3 param_20 = world_pos;\n            vec3 param_21 = r;\n            to_light = fa_area_point(param_13, param_14, param_15, param_16, param_17, param_18, param_19, param_20, param_21) - world_pos;\n        }\n        float _1213 = length(to_light);\n        dist = _1213;\n        l = to_light / vec3(max(_1213, 9.9999997473787516355514526367188e-05));\n        float _1227 = reach / max(_1018.w, 0.001000000047497451305389404296875);\n        float _1233 = clamp(1.0 - (_1227 * _1227), 0.0, 1.0);\n        float _1235;\n        if (front)\n        {\n            _1235 = _1233 * _1233;\n        }\n        else\n        {\n            _1235 = 0.0;\n        }\n        atten = _1235;\n        bool _1246 = _1026 < 2.5;\n        if ((_1026 > 1.5) && _1246)\n        {\n            int param_22 = _1010 + 2;\n            vec4 _1254 = fa_light_texel(param_22);\n            float _1264 = _1254.w;\n            int param_23 = _1010 + 3;\n            vec4 _1269 = fa_light_texel(param_23);\n            float _1270 = _1269.x;\n            float cos_inner = _1270;\n            if (_1270 > 1.5)\n            {\n                cos_inner = mix(_1264, 1.0, 0.25);\n            }\n            atten *= smoothstep(_1264, cos_inner, dot(-l, normalize(_1254.xyz)));\n        }\n        if (_1014 && (_1026 < 1.5))\n        {\n            int param_24 = _1010 + 6;\n            vec4 _1294 = fa_light_texel(param_24);\n            if (_1294.z > 0.5)\n            {\n                vec3 _1302 = -to_light;\n                int param_25 = _1010 + 4;\n                int param_26 = _1010 + 5;\n                vec3 _1316 = fa_light_texel(param_25).xyz;\n                vec3 _1320 = fa_light_texel(param_26).xyz;\n                vec3 _1329 = vec3(dot(_1302, _1316), dot(_1302, _1320), dot(_1302, cross(_1316, _1320)));\n                vec3 param_27 = _1329;\n                int _1333 = fa_cube_face(param_27);\n                int param_28 = _1333;\n                vec3 param_29;\n                vec3 param_30;\n                fa_cube_face_basis(param_28, param_29, param_30);\n                vec2 _1360 = vec2(dot(_1329, cross(param_29, param_30)), dot(_1329, param_30)) / vec2(max(dot(_1329, param_29), 9.9999997473787516355514526367188e-05));\n                int _1364 = _1333 / 3;\n                vec2 param_31 = _1294.xy + (vec2(float(_1333 - (_1364 * 3)), float(_1364)) * 256.0);\n                vec2 param_32 = vec2(0.5 + (0.5 * _1360.x), 0.5 - (0.5 * _1360.y));\n                fa_light_tint = fa_cookie_sample(param_31, param_32);\n            }\n            int param_33 = _1010 + 7;\n            vec4 _1394 = fa_light_texel(param_33);\n            if (_1394.z > 0.5)\n            {\n                int param_34 = _1010 + 2;\n                int param_35 = _1010 + 4;\n                int param_36 = _1010 + 5;\n                vec2 param_37 = _1394.xy;\n                vec3 param_38 = -l;\n                vec3 param_39 = normalize(fa_light_texel(param_34).xyz);\n                vec3 param_40 = fa_light_texel(param_35).xyz;\n                vec3 param_41 = fa_light_texel(param_36).xyz;\n                atten *= fa_ies_sample(param_37, param_38, param_39, param_40, param_41);\n            }\n        }\n        else\n        {\n            if (_1014 && _1246)\n            {\n                int param_42 = _1010 + 6;\n                vec4 _1441 = fa_light_texel(param_42);\n                int param_43 = _1010 + 7;\n                vec4 _1446 = fa_light_texel(param_43);\n                bool _1449 = _1441.z > 0.5;\n                bool _1456;\n                if (!_1449)\n                {\n                    _1456 = _1446.z > 0.5;\n                }\n                else\n                {\n                    _1456 = _1449;\n                }\n                if (_1456)\n                {\n                    int param_44 = _1010 + 2;\n                    vec4 _1463 = fa_light_texel(param_44);\n                    vec3 _1467 = normalize(_1463.xyz);\n                    int param_45 = _1010 + 4;\n                    vec4 _1472 = fa_light_texel(param_45);\n                    int param_46 = _1010 + 5;\n                    vec4 _1477 = fa_light_texel(param_46);\n                    if (_1449)\n                    {\n                        vec3 _1485 = -to_light;\n                        float _1492 = _1463.w;\n                        float _1508 = 0.5 / max(dot(_1485, _1467) * (sqrt(max(1.0 - (_1492 * _1492), 0.0)) / max(_1492, 0.001000000047497451305389404296875)), 9.9999997473787516355514526367188e-05);\n                        vec2 param_47 = _1441.xy;\n                        vec2 param_48 = vec2(0.5 + (dot(_1485, _1472.xyz) * _1508), 0.5 - (dot(_1485, _1477.xyz) * _1508));\n                        fa_light_tint = fa_cookie_sample(param_47, param_48);\n                    }\n                    if (_1446.z > 0.5)\n                    {\n                        vec2 param_49 = _1446.xy;\n                        vec3 param_50 = -l;\n                        vec3 param_51 = _1467;\n                        vec3 param_52 = _1472.xyz;\n                        vec3 param_53 = _1477.xyz;\n                        atten *= fa_ies_sample(param_49, param_50, param_51, param_52, param_53);\n                    }\n                }\n            }\n        }\n    }\n    vec3 _9459 = _1023.xyz * atten;\n    if (_1014)\n    {\n        _9459 *= fa_light_tint;\n    }\n    int _1577;\n    if (_1040)\n    {\n        _1577 = 0;\n    }\n    else\n    {\n        _1577 = ((_1026 > 1.5) && (_1026 < 2.5)) ? 2 : 1;\n    }\n    return LightSample(l, _9459, atten, 1.0, dist, _1577);\n}\n\nfloat fa_shadow_split_at(int i)\n{\n    float _2309;\n    if (i == 0)\n    {\n        _2309 = fa_shadows[24].x;\n    }\n    else\n    {\n        float _2325;\n        if (i == 1)\n        {\n            _2325 = fa_shadows[24].y;\n        }\n        else\n        {\n            float _2333;\n            if (i == 2)\n            {\n                _2333 = fa_shadows[24].z;\n            }\n            else\n            {\n                _2333 = fa_shadows[24].w;\n            }\n            _2325 = _2333;\n        }\n        _2309 = _2325;\n    }\n    return _2309;\n}\n\nfloat fa_shadow_depth(inout vec2 uv, vec4 rect)\n{\n    uv = clamp(uv, rect.xy, rect.zw);\n    return textureLod(fa_shadow_tex_fa_shadow_smp, uv, 0.0).x;\n}\n\nfloat fa_shadow_fetch(vec2 uv, vec4 rect, vec3 conv)\n{\n    vec2 param = uv;\n    vec4 param_1 = rect;\n    float _2366 = fa_shadow_depth(param, param_1);\n    float _2370;\n    if (conv.x < 0.5)\n    {\n        _2370 = _2366;\n    }\n    else\n    {\n        _2370 = (conv.y * conv.z) / (conv.z - (_2366 * (conv.z - conv.y)));\n    }\n    return _2370;\n}\n\nfloat fa_shadow_noise()\n{\n    return fract(52.98291778564453125 * fract(dot(gl_FragCoord.xy, vec2(0.067110560834407806396484375, 0.005837149918079376220703125))));\n}\n\nvec2 fa_shadow_vogel_turn(vec2 d)\n{\n    return vec2((d.x * (-0.737368881702423095703125)) - (d.y * 0.675490319728851318359375), (d.y * (-0.737368881702423095703125)) + (d.x * 0.675490319728851318359375));\n}\n\nfloat fa_shadow_filter(vec2 uv, vec4 rect, float zr, float texel_m, float unit, float reach, float plane, vec3 conv, int mode, float k)\n{\n    if (mode == 1)\n    {\n        vec2 param = uv;\n        vec4 param_1 = rect;\n        vec3 param_2 = conv;\n        return float(zr <= fa_shadow_fetch(param, param_1, param_2));\n    }\n    float _2416 = fa_shadow_noise() * 6.283185482025146484375;\n    vec2 _2422 = vec2(cos(_2416), sin(_2416));\n    vec2 dir = _2422;\n    float radius = 1.5;\n    if (mode == 2)\n    {\n        float _2431;\n        if (k < 0.0)\n        {\n            _2431 = (-k) / max(zr, 0.100000001490116119384765625);\n        }\n        else\n        {\n            _2431 = k;\n        }\n        float _2450 = clamp((_2431 * reach) / texel_m, 3.0, 12.0);\n        float sum = 0.0;\n        float cnt = 0.0;\n        for (int i = 0; i < 16; i++)\n        {\n            float _2469 = sqrt((float(i) + 0.5) * 0.0625) * _2450;\n            vec2 param_3 = uv + (dir * (fa_shadows[26].zw * _2469));\n            vec4 param_4 = rect;\n            vec3 param_5 = conv;\n            float _2483 = fa_shadow_fetch(param_3, param_4, param_5);\n            if (_2483 < (zr - (_2469 * plane)))\n            {\n                sum += _2483;\n                cnt += 1.0;\n            }\n            vec2 param_6 = dir;\n            dir = fa_shadow_vogel_turn(param_6);\n        }\n        if (cnt < 0.5)\n        {\n            return 1.0;\n        }\n        float _2511 = sum / cnt;\n        float _2521;\n        if (k < 0.0)\n        {\n            _2521 = (-k) / max(_2511, 0.0500000007450580596923828125);\n        }\n        else\n        {\n            _2521 = k;\n        }\n        radius = clamp(((max(zr - _2511, 0.0) * unit) * _2521) / texel_m, 1.5, 16.0);\n        dir = _2422;\n    }\n    float lit = 0.0;\n    int _2547 = (mode == 2) ? 24 : 16;\n    for (int i_1 = 0; i_1 < _2547; i_1++)\n    {\n        float _2566 = sqrt((float(i_1) + 0.5) / float(_2547)) * radius;\n        vec2 param_7 = uv + (dir * (fa_shadows[26].zw * _2566));\n        vec4 param_8 = rect;\n        vec3 param_9 = conv;\n        lit += float((zr - (_2566 * plane)) <= fa_shadow_fetch(param_7, param_8, param_9));\n        vec2 param_10 = dir;\n        dir = fa_shadow_vogel_turn(param_10);\n    }\n    return lit / float(_2547);\n}\n\nfloat fa_shadow_cascade(int ci, vec3 world, vec3 n, vec3 l)\n{\n    float _2612 = max(fa_shadows[ci * 1 + 20].y, 0.001000000047497451305389404296875);\n    float _2617 = clamp(dot(n, l), 0.0, 1.0);\n    float _2623 = sqrt(1.0 - (_2617 * _2617));\n    float _2631 = min(_2623 / max(_2617, 0.20000000298023223876953125), 4.0);\n    float _2636;\n    if (fa_shadows[26].y > 0.0)\n    {\n        _2636 = fa_shadows[26].y;\n    }\n    else\n    {\n        _2636 = 1.5 * fa_shadows[ci * 1 + 20].x;\n    }\n    vec4 _2661 = mat4(fa_shadows[ci * 4 + 0], fa_shadows[ci * 4 + 1], fa_shadows[ci * 4 + 2], fa_shadows[ci * 4 + 3]) * vec4(world + (n * (_2636 * _2623)), 1.0);\n    float _2668 = _2661.x;\n    bool _2671 = _2668 < fa_shadows[ci * 1 + 16].x;\n    bool _2680;\n    if (!_2671)\n    {\n        _2680 = _2668 > fa_shadows[ci * 1 + 16].z;\n    }\n    else\n    {\n        _2680 = _2671;\n    }\n    bool _2689;\n    if (!_2680)\n    {\n        _2689 = _2661.y < fa_shadows[ci * 1 + 16].y;\n    }\n    else\n    {\n        _2689 = _2680;\n    }\n    bool _2698;\n    if (!_2689)\n    {\n        _2698 = _2661.y > fa_shadows[ci * 1 + 16].w;\n    }\n    else\n    {\n        _2698 = _2689;\n    }\n    bool _2705;\n    if (!_2698)\n    {\n        _2705 = _2661.z > 1.0;\n    }\n    else\n    {\n        _2705 = _2698;\n    }\n    if (_2705)\n    {\n        return -1.0;\n    }\n    float _2713;\n    if (fa_shadows[26].x > 0.0)\n    {\n        _2713 = fa_shadows[26].x;\n    }\n    else\n    {\n        _2713 = 1.5 * fa_shadows[ci * 1 + 20].x;\n    }\n    vec2 param = _2661.xy;\n    vec4 param_1 = fa_shadows[ci * 1 + 16];\n    float param_2 = _2661.z - ((_2713 * (1.0 + (0.5 * _2631))) / _2612);\n    float param_3 = fa_shadows[ci * 1 + 20].x;\n    float param_4 = _2612;\n    float param_5 = _2612 * 0.25;\n    float param_6 = ((fa_shadows[ci * 1 + 20].x * min(_2631, 3.0)) * 0.5) / _2612;\n    vec3 param_7 = vec3(0.0);\n    int param_8 = int(fa_shadows[25].z + 0.5);\n    float param_9 = fa_shadows[25].w;\n    return fa_shadow_filter(param, param_1, param_2, param_3, param_4, param_5, param_6, param_7, param_8, param_9);\n}\n\nfloat fa_shadow_sun(vec3 world, vec3 n, vec3 l)\n{\n    if (fa_mesh_fs_params[5].z < 0.5)\n    {\n        return 1.0;\n    }\n    int _3091 = int(fa_shadows[25].x + 0.5);\n    if (_3091 < 1)\n    {\n        return 1.0;\n    }\n    float _3106 = dot(world - fa_shadows[27].xyz, fa_shadows[28].xyz);\n    int param = _3091 - 1;\n    if (_3106 > fa_shadow_split_at(param))\n    {\n        return 1.0;\n    }\n    int ci = 0;\n    bool _3118 = _3091 > 1;\n    bool _3125;\n    if (_3118)\n    {\n        _3125 = _3106 > fa_shadows[24].x;\n    }\n    else\n    {\n        _3125 = _3118;\n    }\n    if (_3125)\n    {\n        ci = 1;\n    }\n    bool _3129 = _3091 > 2;\n    bool _3136;\n    if (_3129)\n    {\n        _3136 = _3106 > fa_shadows[24].y;\n    }\n    else\n    {\n        _3136 = _3129;\n    }\n    if (_3136)\n    {\n        ci = 2;\n    }\n    bool _3140 = _3091 > 3;\n    bool _3147;\n    if (_3140)\n    {\n        _3147 = _3106 > fa_shadows[24].z;\n    }\n    else\n    {\n        _3147 = _3140;\n    }\n    if (_3147)\n    {\n        ci = 3;\n    }\n    float s = -1.0;\n    float s2 = -1.0;\n    float t = 0.0;\n    int _3158 = min(_3091, 4);\n    float _3199;\n    for (int c = ci; c < _3158; c++)\n    {\n        int param_1 = c;\n        vec3 param_2 = world;\n        vec3 param_3 = n;\n        vec3 param_4 = l;\n        float _3178 = fa_shadow_cascade(param_1, param_2, param_3, param_4);\n        if (s >= 0.0)\n        {\n            s2 = _3178;\n            break;\n        }\n        if (_3178 < 0.0)\n        {\n            continue;\n        }\n        s = _3178;\n        ci = c;\n        if (fa_shadows[25].y > 0.0)\n        {\n            if (ci > 0)\n            {\n                int param_5 = ci - 1;\n                _3199 = fa_shadow_split_at(param_5);\n            }\n            else\n            {\n                _3199 = fa_shadows[28].w;\n            }\n            int param_6 = ci;\n            float _3218 = fa_shadows[25].y * max(fa_shadow_split_at(param_6) - _3199, 9.9999997473787516355514526367188e-05);\n            int param_7 = ci;\n            t = clamp((_3106 - (fa_shadow_split_at(param_7) - _3218)) / _3218, 0.0, 1.0);\n        }\n        if (t <= 0.0)\n        {\n            break;\n        }\n    }\n    if (s < 0.0)\n    {\n        return 1.0;\n    }\n    if (t > 0.0)\n    {\n        float _3250;\n        if ((ci + 1) < _3091)\n        {\n            _3250 = (s2 < 0.0) ? s : s2;\n        }\n        else\n        {\n            _3250 = 1.0;\n        }\n        s = mix(s, _3250, t);\n    }\n    return s;\n}\n\nfloat fa_shadow_factor(vec3 n, vec3 l)\n{\n    bool _3355 = fa_mesh_fs_params[25].y > 0.5;\n    bool _3361;\n    if (_3355)\n    {\n        _3361 = fa_mesh_fs_params[5].z > 0.5;\n    }\n    else\n    {\n        _3361 = _3355;\n    }\n    if (_3361)\n    {\n        float _3375 = dot(fa_mesh_fs_params[29].xyz, fa_world_pos) + fa_mesh_fs_params[29].w;\n        float _3378 = fwidth(_3375);\n        vec4 _3388 = vec4(fa_world_pos, 1.0);\n        float _3394 = dot(fa_mesh_fs_params[28], _3388);\n        if (_3394 > 9.9999997473787516355514526367188e-05)\n        {\n            vec2 _3413 = vec2(dot(fa_mesh_fs_params[26], _3388), dot(fa_mesh_fs_params[27], _3388)) / vec2(_3394);\n            float _3418 = (_3413.x * 0.5) + 0.5;\n            float _3422;\n            if (fa_mesh_fs_params[24].y > 0.5)\n            {\n                _3422 = (_3413.y * 0.5) + 0.5;\n            }\n            else\n            {\n                _3422 = 0.5 - (_3413.y * 0.5);\n            }\n            bool _3438 = _3418 >= 0.0;\n            bool _3444;\n            if (_3438)\n            {\n                _3444 = _3418 < 1.0;\n            }\n            else\n            {\n                _3444 = _3438;\n            }\n            bool _3450;\n            if (_3444)\n            {\n                _3450 = _3422 >= 0.0;\n            }\n            else\n            {\n                _3450 = _3444;\n            }\n            bool _3456;\n            if (_3450)\n            {\n                _3456 = _3422 < 1.0;\n            }\n            else\n            {\n                _3456 = _3450;\n            }\n            if (_3456)\n            {\n                vec4 _3482 = texelFetch(fa_screen_tex_fa_shadow_smp, clamp(ivec2(vec2(_3418, _3422) * fa_mesh_fs_params[24].zw), ivec2(0), ivec2(fa_mesh_fs_params[24].zw) - ivec2(1)), 0);\n                bool _3485 = _3482.w > 0.5;\n                bool _3501;\n                if (_3485)\n                {\n                    _3501 = abs(_3375 - _3482.x) <= (((0.00200000009499490261077880859375 * _3375) + 0.00999999977648258209228515625) + min(1.5 * _3378, 0.100000001490116119384765625 * _3375));\n                }\n                else\n                {\n                    _3501 = _3485;\n                }\n                if (_3501)\n                {\n                    float _3507;\n                    if (fa_mesh_fs_params[25].z > 0.5)\n                    {\n                        vec3 param = fa_world_pos;\n                        vec3 param_1 = n;\n                        vec3 param_2 = l;\n                        _3507 = min(_3482.y, fa_shadow_sun(param, param_1, param_2));\n                    }\n                    else\n                    {\n                        _3507 = _3482.y;\n                    }\n                    return _3507;\n                }\n            }\n        }\n    }\n    vec3 param_3 = fa_world_pos;\n    vec3 param_4 = n;\n    vec3 param_5 = l;\n    return fa_shadow_sun(param_3, param_4, param_5);\n}\n\nfloat fa_shadow_local(int li, vec3 lpos, vec3 world, vec3 n, vec3 l)\n{\n    bool _2771 = fa_mesh_fs_params[5].z < 0.5;\n    bool _2778;\n    if (!_2771)\n    {\n        _2778 = fa_shadows[29].x < 0.5;\n    }\n    else\n    {\n        _2778 = _2771;\n    }\n    if (_2778)\n    {\n        return 1.0;\n    }\n    int param = (int(fa_shadows[29].x + 0.5) - 1) + li;\n    vec4 _2791 = fa_light_texel(param);\n    float _2792 = _2791.x;\n    if (_2792 < 0.0)\n    {\n        return 1.0;\n    }\n    int _2801 = int(_2792 + 0.5);\n    int param_1 = _2801;\n    vec4 _2805 = fa_light_texel(param_1);\n    int param_2 = _2801 + 1;\n    vec4 _2810 = fa_light_texel(param_2);\n    float fade = 1.0;\n    float _2813 = _2805.y;\n    if (_2813 > 0.0)\n    {\n        float _2830 = 1.0 - smoothstep(0.75 * _2813, _2813, length(world - fa_shadows[27].xyz));\n        fade = _2830;\n        if (_2830 <= 0.0)\n        {\n            return 1.0;\n        }\n    }\n    int face = 0;\n    if (_2805.x > 1.5)\n    {\n        vec3 param_3 = world - lpos;\n        face = fa_cube_face(param_3);\n    }\n    int _2854 = (_2801 + 2) + (face * 6);\n    int param_4 = _2854;\n    int param_5 = _2854 + 1;\n    int param_6 = _2854 + 3;\n    vec4 _2868 = fa_light_texel(param_6);\n    int param_7 = _2854 + 4;\n    vec4 _2873 = fa_light_texel(param_7);\n    int param_8 = _2854 + 5;\n    vec4 _2878 = fa_light_texel(param_8);\n    float _2890 = _2878.x * max(dot(_2868, vec4(world, 1.0)), 0.001000000047497451305389404296875);\n    float _2895 = clamp(dot(n, l), 0.0, 1.0);\n    float _2918 = clamp(dot(n, _2868.xyz), -1.0, 1.0);\n    float _2937 = min(sqrt(1.0 - (_2918 * _2918)) / max(abs(dot(n, world - lpos)) / max(dot(_2868, vec4(world, 1.0)), 0.001000000047497451305389404296875), 0.20000000298023223876953125), 4.0);\n    float _2940 = _2810.y;\n    float _2942;\n    if (_2940 > 0.0)\n    {\n        _2942 = _2940;\n    }\n    else\n    {\n        _2942 = 1.5 * _2890;\n    }\n    vec4 _2962 = vec4(world + (n * (_2942 * sqrt(1.0 - (_2895 * _2895)))), 1.0);\n    float _2966 = dot(_2868, _2962);\n    float _2969 = _2878.y;\n    if (_2966 < _2969)\n    {\n        return 1.0;\n    }\n    vec2 _2984 = vec2(dot(fa_light_texel(param_4), _2962), dot(fa_light_texel(param_5), _2962)) / vec2(_2966);\n    float _2986 = _2984.x;\n    bool _2989 = _2986 < _2873.x;\n    bool _2998;\n    if (!_2989)\n    {\n        _2998 = _2986 > _2873.z;\n    }\n    else\n    {\n        _2998 = _2989;\n    }\n    bool _3007;\n    if (!_2998)\n    {\n        _3007 = _2984.y < _2873.y;\n    }\n    else\n    {\n        _3007 = _2998;\n    }\n    bool _3016;\n    if (!_3007)\n    {\n        _3016 = _2984.y > _2873.w;\n    }\n    else\n    {\n        _3016 = _3007;\n    }\n    if (_3016)\n    {\n        return 1.0;\n    }\n    float _3022 = _2810.x;\n    float _3024;\n    if (_3022 > 0.0)\n    {\n        _3024 = _3022;\n    }\n    else\n    {\n        _3024 = 1.5 * _2890;\n    }\n    vec2 param_9 = _2984;\n    vec4 param_10 = _2873;\n    float param_11 = _2966 - (_3024 * (1.0 + (0.5 * _2937)));\n    float param_12 = _2890;\n    float param_13 = 1.0;\n    float param_14 = _2878.z * 0.25;\n    float param_15 = (_2890 * min(_2937, 3.0)) * 0.5;\n    vec3 param_16 = vec3(1.0, _2969, _2878.z);\n    int param_17 = int(_2805.z + 0.5);\n    float param_18 = _2805.w;\n    return mix(1.0, fa_shadow_filter(param_9, param_10, param_11, param_12, param_13, param_14, param_15, param_16, param_17, param_18), fade);\n}\n\nfloat fa_shadow_local_rt(int li, vec3 lpos, vec3 world, vec3 n, vec3 l)\n{\n    bool _3536 = fa_mesh_fs_params[25].w > 0.5;\n    bool _3542;\n    if (_3536)\n    {\n        _3542 = fa_mesh_fs_params[5].z > 0.5;\n    }\n    else\n    {\n        _3542 = _3536;\n    }\n    bool _3548;\n    if (_3542)\n    {\n        _3548 = fa_shadows[29].x > 0.5;\n    }\n    else\n    {\n        _3548 = _3542;\n    }\n    if (_3548)\n    {\n        int param = (int(fa_shadows[29].x + 0.5) - 1) + li;\n        vec4 _3560 = fa_light_texel(param);\n        float _3561 = _3560.z;\n        if (_3561 > 0.5)\n        {\n            float _3574 = dot(fa_mesh_fs_params[29].xyz, world) + fa_mesh_fs_params[29].w;\n            float _3577 = fwidth(_3574);\n            float _3581 = min(1.5 * _3577, 0.100000001490116119384765625 * _3574);\n            vec4 _3587 = vec4(world, 1.0);\n            float _3592 = dot(fa_mesh_fs_params[28], _3587);\n            if (_3592 > 9.9999997473787516355514526367188e-05)\n            {\n                vec2 _3609 = vec2(dot(fa_mesh_fs_params[26], _3587), dot(fa_mesh_fs_params[27], _3587)) / vec2(_3592);\n                float _3614 = (_3609.x * 0.5) + 0.5;\n                float _3618;\n                if (fa_mesh_fs_params[24].y > 0.5)\n                {\n                    _3618 = (_3609.y * 0.5) + 0.5;\n                }\n                else\n                {\n                    _3618 = 0.5 - (_3609.y * 0.5);\n                }\n                bool _3634 = _3614 >= 0.0;\n                bool _3640;\n                if (_3634)\n                {\n                    _3640 = _3614 < 1.0;\n                }\n                else\n                {\n                    _3640 = _3634;\n                }\n                bool _3646;\n                if (_3640)\n                {\n                    _3646 = _3618 >= 0.0;\n                }\n                else\n                {\n                    _3646 = _3640;\n                }\n                bool _3652;\n                if (_3646)\n                {\n                    _3652 = _3618 < 1.0;\n                }\n                else\n                {\n                    _3652 = _3646;\n                }\n                if (_3652)\n                {\n                    ivec2 _3669 = ivec2(fa_mesh_fs_params[24].zw) - ivec2(1);\n                    ivec2 _3670 = clamp(ivec2(vec2(_3614, _3618) * fa_mesh_fs_params[24].zw), ivec2(0), _3669);\n                    ivec2 _3682;\n                    ivec2 _3688;\n                    ivec2 _3695;\n                    float _3746;\n                    float _3767;\n                    for (int k = 0; k < 5; k++)\n                    {\n                        if (k == 0)\n                        {\n                            _3682 = ivec2(0);\n                        }\n                        else\n                        {\n                            if (k == 1)\n                            {\n                                _3688 = ivec2(1, 0);\n                            }\n                            else\n                            {\n                                if (k == 2)\n                                {\n                                    _3695 = ivec2(-1, 0);\n                                }\n                                else\n                                {\n                                    bvec2 _3706 = bvec2(k == 3);\n                                    _3695 = ivec2(_3706.x ? ivec2(0, 1).x : ivec2(0, -1).x, _3706.y ? ivec2(0, 1).y : ivec2(0, -1).y);\n                                }\n                                _3688 = _3695;\n                            }\n                            _3682 = _3688;\n                        }\n                        vec4 _3723 = texelFetch(fa_screen_tex_fa_shadow_smp, clamp(_3670 + _3682, ivec2(0), _3669), 0);\n                        bool _3726 = _3723.w > 0.5;\n                        bool _3740;\n                        if (_3726)\n                        {\n                            _3740 = abs(_3574 - _3723.x) <= (((0.00200000009499490261077880859375 * _3574) + 0.00999999977648258209228515625) + _3581);\n                        }\n                        else\n                        {\n                            _3740 = _3726;\n                        }\n                        if (_3740)\n                        {\n                            if (_3561 < 1.5)\n                            {\n                                _3746 = 1.0;\n                            }\n                            else\n                            {\n                                _3746 = (_3561 < 2.5) ? 256.0 : 65536.0;\n                            }\n                            float _3763 = mod(floor(_3723.z / _3746), 256.0) * 0.0039215688593685626983642578125;\n                            if (fa_mesh_fs_params[25].z > 0.5)\n                            {\n                                int param_1 = li;\n                                vec3 param_2 = lpos;\n                                vec3 param_3 = world;\n                                vec3 param_4 = n;\n                                vec3 param_5 = l;\n                                _3767 = min(_3763, fa_shadow_local(param_1, param_2, param_3, param_4, param_5));\n                            }\n                            else\n                            {\n                                _3767 = _3763;\n                            }\n                            return _3767;\n                        }\n                    }\n                }\n            }\n            float _3792;\n            if (fa_mesh_fs_params[25].z > 0.5)\n            {\n                int param_6 = li;\n                vec3 param_7 = lpos;\n                vec3 param_8 = world;\n                vec3 param_9 = n;\n                vec3 param_10 = l;\n                _3792 = fa_shadow_local(param_6, param_7, param_8, param_9, param_10);\n            }\n            else\n            {\n                _3792 = 1.0;\n            }\n            return _3792;\n        }\n    }\n    int param_11 = li;\n    vec3 param_12 = lpos;\n    vec3 param_13 = world;\n    vec3 param_14 = n;\n    vec3 param_15 = l;\n    return fa_shadow_local(param_11, param_12, param_13, param_14, param_15);\n}\n\nfloat fa_contact_shadow(int li, vec3 world, vec3 gn, vec3 l, float dist)\n{\n    bool _5637 = fa_mesh_fs_params[24].x < 0.5;\n    bool _5644;\n    if (!_5637)\n    {\n        _5644 = fa_shadows[29].x < 0.5;\n    }\n    else\n    {\n        _5644 = _5637;\n    }\n    if (_5644)\n    {\n        return 1.0;\n    }\n    int param = (int(fa_shadows[29].x + 0.5) - 1) + li;\n    vec4 _5657 = fa_light_texel(param);\n    float _5658 = _5657.y;\n    float len = _5658;\n    if (_5658 <= 0.0)\n    {\n        return 1.0;\n    }\n    float _5670 = length(world - fa_mesh_fs_params[0].xyz);\n    float _5679 = 1.0 - smoothstep(0.5 * fa_mesh_fs_params[25].x, fa_mesh_fs_params[25].x, _5670);\n    if (_5679 <= 0.0)\n    {\n        return 1.0;\n    }\n    float _5685 = len;\n    float _5688 = min(_5685, 0.89999997615814208984375 * dist);\n    len = _5688;\n    float _5693 = 0.004999999888241291046142578125 + (0.0030000000260770320892333984375 * _5670);\n    float _5698 = _5693 + (0.5 * _5688);\n    vec3 _5704 = world + (gn * _5693);\n    float _5706 = fa_shadow_noise();\n    float occ = 0.0;\n    float _5767;\n    for (int k = 0; k < 12; k++)\n    {\n        float _5721 = (float(k) + _5706) * 0.083333335816860198974609375;\n        vec3 _5729 = _5704 + (l * (_5721 * len));\n        vec4 _5735 = vec4(_5729, 1.0);\n        float _5740 = dot(fa_mesh_fs_params[28], _5735);\n        if (_5740 < 9.9999997473787516355514526367188e-05)\n        {\n            break;\n        }\n        vec2 _5758 = vec2(dot(fa_mesh_fs_params[26], _5735), dot(fa_mesh_fs_params[27], _5735)) / vec2(_5740);\n        float _5762 = _5758.x * 0.5;\n        float _5763 = _5762 + 0.5;\n        if (fa_mesh_fs_params[24].y > 0.5)\n        {\n            _5767 = (_5758.y * 0.5) + 0.5;\n        }\n        else\n        {\n            _5767 = 0.5 - (_5758.y * 0.5);\n        }\n        bool _5783 = _5763 < 0.0;\n        bool _5790;\n        if (!_5783)\n        {\n            _5790 = _5763 >= 1.0;\n        }\n        else\n        {\n            _5790 = _5783;\n        }\n        bool _5797;\n        if (!_5790)\n        {\n            _5797 = _5767 < 0.0;\n        }\n        else\n        {\n            _5797 = _5790;\n        }\n        bool _5804;\n        if (!_5797)\n        {\n            _5804 = _5767 >= 1.0;\n        }\n        else\n        {\n            _5804 = _5797;\n        }\n        if (_5804)\n        {\n            break;\n        }\n        vec4 _5828 = texelFetch(fa_screen_tex_fa_shadow_smp, clamp(ivec2(vec2(_5763, _5767) * fa_mesh_fs_params[24].zw), ivec2(0), ivec2(fa_mesh_fs_params[24].zw) - ivec2(1)), 0);\n        if (_5828.w < 0.5)\n        {\n            continue;\n        }\n        float _5846 = (dot(fa_mesh_fs_params[29].xyz, _5729) + fa_mesh_fs_params[29].w) - _5828.x;\n        if ((_5846 > _5693) && (_5846 < _5698))\n        {\n            occ = max(occ, (1.0 - (_5721 * _5721)) * smoothstep(0.0, 0.0500000007450580596923828125, min(min(_5763, 0.5 - _5762), min(_5767, 1.0 - _5767))));\n        }\n    }\n    return 1.0 - (occ * _5679);\n}\n\nLightSample fa_light_shadowed(int li, vec3 world_pos, vec3 gn)\n{\n    int param = li;\n    float _6312 = fa_baked_keep(param);\n    if (_6312 <= 0.0)\n    {\n        int param_1 = li;\n        return LightSample(vec3(0.0, 1.0, 0.0), vec3(0.0), 0.0, 1.0, 0.0, int(fa_light_type(param_1) + 0.5));\n    }\n    int param_2 = li;\n    vec3 param_3 = world_pos;\n    vec3 param_4 = gn;\n    LightSample _6338 = fa_light_sample_n(param_2, param_3, param_4);\n    vec3 _9528 = _6338.color;\n    float _9529 = _6338.attenuation;\n    float _9530 = _6338.shadow;\n    bool _6341 = _6338.type == 0;\n    if (_6341 && (li == 0))\n    {\n        vec3 param_5 = gn;\n        vec3 param_6 = _6338.direction;\n        float _6352 = fa_shadow_factor(param_5, param_6);\n        _9530 = _6352;\n        _9528 *= _6352;\n    }\n    else\n    {\n        bool _6363 = _6338.type != 0;\n        bool _6369;\n        if (_6363)\n        {\n            _6369 = _9529 > 0.0;\n        }\n        else\n        {\n            _6369 = _6363;\n        }\n        if (_6369)\n        {\n            int param_7 = li;\n            int param_8 = fa_light_base(param_7);\n            int param_9 = li;\n            vec3 param_10 = fa_light_texel(param_8).xyz;\n            vec3 param_11 = world_pos;\n            vec3 param_12 = gn;\n            vec3 param_13 = _6338.direction;\n            float _6388 = fa_shadow_local_rt(param_9, param_10, param_11, param_12, param_13);\n            _9530 = _6388;\n            _9528 *= _6388;\n        }\n    }\n    bool _6398 = fa_mesh_fs_params[24].x > 0.5;\n    bool _6404;\n    if (_6398)\n    {\n        _6404 = _9529 > 0.0;\n    }\n    else\n    {\n        _6404 = _6398;\n    }\n    if (_6404)\n    {\n        float _6411;\n        if (_6341)\n        {\n            _6411 = 1000000000.0;\n        }\n        else\n        {\n            _6411 = _6338._distance;\n        }\n        int param_14 = li;\n        vec3 param_15 = world_pos;\n        vec3 param_16 = gn;\n        vec3 param_17 = _6338.direction;\n        float param_18 = _6411;\n        float _6429 = fa_contact_shadow(param_14, param_15, param_16, param_17, param_18);\n        _9530 *= _6429;\n        _9528 *= _6429;\n    }\n    float _6442 = _9529;\n    float _6443 = _6442 * _6312;\n    _9529 = _6443;\n    vec3 _6447 = _9528;\n    vec3 _6448 = _6447 * _6312;\n    _9528 = _6448;\n    return LightSample(_6338.direction, _6448, _6443, _9530, _6338._distance, _6338.type);\n}\n\nvec3 fa_ltc_tangent(vec3 n, vec3 v)\n{\n    vec3 _6482 = v - (n * dot(v, n));\n    vec3 t = _6482;\n    float _6486 = dot(_6482, _6482);\n    float l2 = _6486;\n    if (_6486 < 1.0000000133514319600180897396058e-10)\n    {\n        vec3 _6496;\n        if (abs(n.z) < 0.999000012874603271484375)\n        {\n            _6496 = cross(n, vec3(0.0, 0.0, 1.0));\n        }\n        else\n        {\n            _6496 = cross(n, vec3(1.0, 0.0, 0.0));\n        }\n        t = _6496;\n        l2 = dot(_6496, _6496);\n    }\n    return t * inversesqrt(l2);\n}\n\nvec3 fa_ltc_local(vec3 t1, vec3 n, vec3 p)\n{\n    return vec3(dot(t1, p), dot(cross(n, t1), p), dot(n, p));\n}\n\nvec2 fa_ltc_uv(float roughness, float ndv)\n{\n    return ((vec2(clamp((roughness - 0.0500000007450580596923828125) * 1.0526316165924072265625, 0.0, 1.0), sqrt(clamp(1.0 - ndv, 0.0, 1.0))) * 63.0) + vec2(0.5)) * vec2(0.015625);\n}\n\nvec3 fa_oct_vertex(int j, vec3 pc, vec3 ex, vec3 ey)\n{\n    float _6883;\n    if ((j == 0) || (j == 7))\n    {\n        _6883 = 0.92387950420379638671875;\n    }\n    else\n    {\n        float _6893;\n        if ((j == 3) || (j == 4))\n        {\n            _6893 = -0.92387950420379638671875;\n        }\n        else\n        {\n            _6893 = ((j == 1) || (j == 6)) ? 0.3826834261417388916015625 : (-0.3826834261417388916015625);\n        }\n        _6883 = _6893;\n    }\n    float _6914;\n    if ((j == 1) || (j == 2))\n    {\n        _6914 = 0.92387950420379638671875;\n    }\n    else\n    {\n        float _6923;\n        if ((j == 5) || (j == 6))\n        {\n            _6923 = -0.92387950420379638671875;\n        }\n        else\n        {\n            _6923 = ((j == 0) || (j == 3)) ? 0.3826834261417388916015625 : (-0.3826834261417388916015625);\n        }\n        _6914 = _6923;\n    }\n    return (pc + (ex * _6883)) + (ey * _6914);\n}\n\nvec3 fa_ltc_edge_vector(vec3 a, vec3 b)\n{\n    float _6531 = dot(a, a);\n    float _6535 = dot(b, b);\n    if ((_6531 < 1.0000000195414813782625560981111e-24) || (_6535 < 1.0000000195414813782625560981111e-24))\n    {\n        return vec3(0.0);\n    }\n    vec3 _6549 = a * inversesqrt(_6531);\n    vec3 _6554 = b * inversesqrt(_6535);\n    float _6558 = dot(_6549, _6554);\n    float _6561 = abs(_6558);\n    float g = (((((((((((0.0416471660137176513671875 * _6561) - 0.1924748718738555908203125) * _6561) + 0.4179156124591827392578125) * _6561) - 0.616057217121124267578125) * _6561) + 0.777722418308258056640625) * _6561) - 0.999542415142059326171875) * _6561) + 1.570791721343994140625;\n    if (_6558 < 0.0)\n    {\n        g = (3.1415927410125732421875 * inversesqrt(max(1.0 - (_6558 * _6558), 1.0000000116860974230803549289703e-07))) - g;\n    }\n    return cross(_6549, _6554) * g;\n}\n\nvoid fa_ltc_clip_edge(vec3 a, vec3 b, inout vec3 sum, inout vec3 leave, inout vec3 enter, inout vec2 seen)\n{\n    bool _6618 = a.z > 0.0;\n    bool _6622 = b.z > 0.0;\n    if (_6618 && _6622)\n    {\n        vec3 param = a;\n        vec3 param_1 = b;\n        sum += fa_ltc_edge_vector(param, param_1);\n    }\n    else\n    {\n        if (_6618 != _6622)\n        {\n            vec3 _6657 = a + ((b - a) * (a.z / (a.z - b.z)));\n            _6657.z = 0.0;\n            if (_6618)\n            {\n                vec3 param_2 = a;\n                vec3 param_3 = _6657;\n                sum += fa_ltc_edge_vector(param_2, param_3);\n                leave = _6657;\n                seen.x = 1.0;\n            }\n            else\n            {\n                vec3 param_4 = _6657;\n                vec3 param_5 = b;\n                sum += fa_ltc_edge_vector(param_4, param_5);\n                enter = _6657;\n                seen.y = 1.0;\n            }\n        }\n    }\n}\n\nfloat fa_ltc_quad(vec4 abcd, vec3 p0, vec3 p1, vec3 p2, vec3 p3)\n{\n    vec3 _6706 = vec3((abcd.x * p0.x) + (abcd.y * p0.z), p0.y, (abcd.z * p0.x) + (abcd.w * p0.z));\n    vec3 _6732 = vec3((abcd.x * p1.x) + (abcd.y * p1.z), p1.y, (abcd.z * p1.x) + (abcd.w * p1.z));\n    vec3 _6758 = vec3((abcd.x * p2.x) + (abcd.y * p2.z), p2.y, (abcd.z * p2.x) + (abcd.w * p2.z));\n    vec3 _6784 = vec3((abcd.x * p3.x) + (abcd.y * p3.z), p3.y, (abcd.z * p3.x) + (abcd.w * p3.z));\n    vec3 sum = vec3(0.0);\n    vec3 leave = vec3(0.0);\n    vec3 enter = vec3(0.0);\n    vec3 param = _6706;\n    vec3 param_1 = _6732;\n    vec3 param_2 = vec3(0.0);\n    vec3 param_3 = vec3(0.0);\n    vec3 param_4 = vec3(0.0);\n    vec2 param_5 = vec2(0.0);\n    fa_ltc_clip_edge(param, param_1, param_2, param_3, param_4, param_5);\n    sum = param_2;\n    leave = param_3;\n    enter = param_4;\n    vec3 param_6 = _6732;\n    vec3 param_7 = _6758;\n    vec3 param_8 = param_2;\n    vec3 param_9 = param_3;\n    vec3 param_10 = param_4;\n    vec2 param_11 = param_5;\n    fa_ltc_clip_edge(param_6, param_7, param_8, param_9, param_10, param_11);\n    sum = param_8;\n    leave = param_9;\n    enter = param_10;\n    vec3 param_12 = _6758;\n    vec3 param_13 = _6784;\n    vec3 param_14 = param_8;\n    vec3 param_15 = param_9;\n    vec3 param_16 = param_10;\n    vec2 param_17 = param_11;\n    fa_ltc_clip_edge(param_12, param_13, param_14, param_15, param_16, param_17);\n    sum = param_14;\n    leave = param_15;\n    enter = param_16;\n    vec3 param_18 = _6784;\n    vec3 param_19 = _6706;\n    vec3 param_20 = param_14;\n    vec3 param_21 = param_15;\n    vec3 param_22 = param_16;\n    vec2 param_23 = param_17;\n    fa_ltc_clip_edge(param_18, param_19, param_20, param_21, param_22, param_23);\n    sum = param_20;\n    leave = param_21;\n    enter = param_22;\n    if ((param_23.x * param_23.y) > 0.5)\n    {\n        vec3 param_24 = leave;\n        vec3 param_25 = enter;\n        sum += fa_ltc_edge_vector(param_24, param_25);\n    }\n    return sum.z * 0.15915493667125701904296875;\n}\n\nvec2 fa_area_forms(vec4 m, float shape, vec3 pc, vec3 ex, vec3 ey)\n{\n    int _6952 = ((shape < 0.5) || (shape > 1.5)) ? 1 : 3;\n    vec2 sum = vec2(0.0);\n    int _6970;\n    for (int k = 0; k < (2 * _6952); k++)\n    {\n        bool _6967 = k >= _6952;\n        if (_6967)\n        {\n            _6970 = k - _6952;\n        }\n        else\n        {\n            _6970 = k;\n        }\n        vec3 p0 = (pc - ex) - ey;\n        vec3 p1 = (pc + ex) - ey;\n        vec3 p2 = (pc + ex) + ey;\n        vec3 p3 = (pc - ex) + ey;\n        if (_6952 == 3)\n        {\n            int param = 0;\n            vec3 param_1 = pc;\n            vec3 param_2 = ex;\n            vec3 param_3 = ey;\n            p0 = fa_oct_vertex(param, param_1, param_2, param_3);\n            int _7016 = 2 * _6970;\n            int param_4 = _7016 + 1;\n            vec3 param_5 = pc;\n            vec3 param_6 = ex;\n            vec3 param_7 = ey;\n            p1 = fa_oct_vertex(param_4, param_5, param_6, param_7);\n            int param_8 = _7016 + 2;\n            vec3 param_9 = pc;\n            vec3 param_10 = ex;\n            vec3 param_11 = ey;\n            p2 = fa_oct_vertex(param_8, param_9, param_10, param_11);\n            int param_12 = _7016 + 3;\n            vec3 param_13 = pc;\n            vec3 param_14 = ex;\n            vec3 param_15 = ey;\n            p3 = fa_oct_vertex(param_12, param_13, param_14, param_15);\n        }\n        bvec4 _7053 = bvec4(_6967);\n        vec4 param_16 = vec4(_7053.x ? m.x : vec4(1.0, 0.0, 0.0, 1.0).x, _7053.y ? m.y : vec4(1.0, 0.0, 0.0, 1.0).y, _7053.z ? m.z : vec4(1.0, 0.0, 0.0, 1.0).z, _7053.w ? m.w : vec4(1.0, 0.0, 0.0, 1.0).w);\n        vec3 param_17 = p0;\n        vec3 param_18 = p1;\n        vec3 param_19 = p2;\n        vec3 param_20 = p3;\n        float _7064 = fa_ltc_quad(param_16, param_17, param_18, param_19, param_20);\n        if (_6967)\n        {\n            vec2 _9776 = sum;\n            _9776.y = _9776.y + _7064;\n            sum = _9776;\n        }\n        else\n        {\n            vec2 _9779 = sum;\n            _9779.x = _9779.x + _7064;\n            sum = _9779;\n        }\n    }\n    return abs(sum);\n}\n\nvec3 fa_area_shade(int li, vec3 world_pos, vec3 n, vec3 v, vec3 diffuse_color, vec3 f0, float f90, float roughness, float ndv, float window)\n{\n    int param = li;\n    int _7088 = fa_light_base(param);\n    int param_1 = _7088;\n    int param_2 = _7088 + 1;\n    int param_3 = _7088 + 2;\n    int param_4 = _7088 + 4;\n    vec4 _7110 = fa_light_texel(param_4);\n    int param_5 = _7088 + 5;\n    vec4 _7115 = fa_light_texel(param_5);\n    int param_6 = _7088 + 6;\n    vec4 _7120 = fa_light_texel(param_6);\n    float _7121 = _7120.w;\n    vec3 _7126 = fa_light_texel(param_1).xyz - world_pos;\n    bool _7128 = _7121 < 1.5;\n    bool _7135;\n    if (_7128)\n    {\n        _7135 = dot(normalize(fa_light_texel(param_3).xyz), _7126) >= 0.0;\n    }\n    else\n    {\n        _7135 = _7128;\n    }\n    if (_7135)\n    {\n        return vec3(0.0);\n    }\n    bool _7144 = (_7121 > 0.5) && _7128;\n    float _7148 = _7144 ? 1.0539000034332275390625 : 1.0;\n    vec3 _7151 = _7110.xyz;\n    float _7153 = _7110.w;\n    vec3 _7159 = _7115.xyz;\n    float _7161 = _7115.w;\n    vec3 up = _7159 * (_7161 * _7148);\n    float _7167;\n    if (_7144)\n    {\n        _7167 = (3.1415927410125732421875 * _7153) * _7153;\n    }\n    else\n    {\n        _7167 = (4.0 * _7153) * _7161;\n    }\n    if (_7121 > 1.5)\n    {\n        vec3 _7193 = cross(_7151, -_7126);\n        vec3 perp = _7193;\n        float _7197 = dot(_7193, _7193);\n        vec3 _7200;\n        if (_7197 > 1.0000000133514319600180897396058e-10)\n        {\n            _7200 = perp * inversesqrt(_7197);\n        }\n        else\n        {\n            _7200 = _7159;\n        }\n        perp = _7200;\n        up = _7200 * _7161;\n    }\n    float _7221 = max(_7167, 9.9999999747524270787835121154785e-07);\n    vec3 param_7 = n;\n    vec3 param_8 = v;\n    vec3 _7231 = fa_ltc_tangent(param_7, param_8);\n    vec3 param_9 = _7231;\n    vec3 param_10 = n;\n    vec3 param_11 = _7126;\n    vec3 param_12 = _7231;\n    vec3 param_13 = n;\n    vec3 param_14 = _7151 * (_7153 * _7148);\n    vec3 param_15 = _7231;\n    vec3 param_16 = n;\n    vec3 param_17 = up;\n    float param_18 = roughness;\n    float param_19 = ndv;\n    vec2 _7262 = fa_ltc_uv(param_18, param_19) * 64.0;\n    vec2 param_20 = _7262;\n    vec2 param_21 = _7262 + vec2(64.0, 0.0);\n    vec4 _7272 = fa_atlas_fetch(param_21);\n    vec4 param_22 = fa_atlas_fetch(param_20);\n    float param_23 = _7121;\n    vec3 param_24 = fa_ltc_local(param_9, param_10, param_11);\n    vec3 param_25 = fa_ltc_local(param_12, param_13, param_14);\n    vec3 param_26 = fa_ltc_local(param_15, param_16, param_17);\n    vec2 _7284 = fa_area_forms(param_22, param_23, param_24, param_25, param_26);\n    return (((diffuse_color * _7284.x) + (((f0 * _7272.x) + ((vec3(f90) - f0) * _7272.y)) * _7284.y)) * fa_light_texel(param_2).xyz) * ((((3.1415927410125732421875 * dot(_7126, _7126)) + _7221) / _7221) * window);\n}\n\nvec3 fa_light_rgb(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 1;\n    return fa_light_texel(param_1).xyz;\n}\n\nfloat fa_d_charlie(float alpha, float ndh)\n{\n    float _5374 = 1.0 / alpha;\n    return ((2.0 + _5374) * pow(sqrt(max(1.0 - (ndh * ndh), 9.9999997473787516355514526367188e-05)), _5374)) * 0.15915493667125701904296875;\n}\n\nfloat fa_v_ashikhmin(float ndl, float ndv)\n{\n    return clamp(0.25 / max((ndl + ndv) - (ndl * ndv), 9.9999997473787516355514526367188e-05), 0.0, 1.0);\n}\n\nfloat fa_layers_coat(FaLayers L, vec3 l, vec3 h, float vdh)\n{\n    float _5409 = max(dot(L.nc, l), 0.0);\n    float _5415 = max(dot(L.nc, h), 0.0);\n    float _5424 = ((_5415 * _5415) * (L.coat_a2 - 1.0)) + 1.0;\n    return (((L.coat * (0.039999999105930328369140625 + (0.959999978542327880859375 * pow(clamp(1.0 - vdh, 0.0, 1.0), 5.0)))) * (((L.coat_a2 / ((3.1415927410125732421875 * _5424) * _5424)) * (0.5 / max(mix((2.0 * _5409) * L.coat_ndv, _5409 + L.coat_ndv, L.coat_alpha), 9.9999997473787516355514526367188e-05))) * 3.1415927410125732421875)) * step(9.9999997473787516355514526367188e-05, _5409)) * _5409;\n}\n\nvec3 fa_area_layers(FaLayers L, vec3 base, int li, vec3 n, vec3 v, vec3 l, float ndv, float window)\n{\n    float _7321;\n    if (L.sheen_on)\n    {\n        _7321 = L.sheen_scale;\n    }\n    else\n    {\n        _7321 = 1.0;\n    }\n    vec3 result = base * (L.keep * _7321);\n    vec3 _7334 = normalize(l + v);\n    int param = li;\n    vec3 _7345 = fa_light_rgb(param) * window;\n    if (L.sheen_on)\n    {\n        float _7354 = max(dot(n, l), 0.0);\n        float param_1 = L.sheen_alpha;\n        float param_2 = max(dot(n, _7334), 0.0);\n        float param_3 = _7354;\n        float param_4 = ndv;\n        result += ((L.sheen * _7345) * (((((fa_d_charlie(param_1, param_2) * fa_v_ashikhmin(param_3, param_4)) * 3.1415927410125732421875) * step(9.9999997473787516355514526367188e-05, _7354)) * _7354) * L.keep));\n    }\n    if (L.coat > 0.0)\n    {\n        FaLayers param_5 = L;\n        vec3 param_6 = l;\n        vec3 param_7 = _7334;\n        float param_8 = max(dot(v, _7334), 0.0);\n        result += (_7345 * fa_layers_coat(param_5, param_6, param_7, param_8));\n    }\n    return result;\n}\n\nfloat fa_d_ggx_aniso(float ndh, float tdh, float bdh, float at, float ab)\n{\n    float _5277 = tdh / at;\n    float _5281 = bdh / ab;\n    float _5293 = ((_5277 * _5277) + (_5281 * _5281)) + (ndh * ndh);\n    return 1.0 / ((((3.1415927410125732421875 * at) * ab) * _5293) * _5293);\n}\n\nfloat fa_lambda_ggx_aniso(float n, float t, float b, float at, float ab)\n{\n    return 0.5 * (sqrt(1.0 + (((((at * at) * t) * t) + (((ab * ab) * b) * b)) / max(n * n, 9.9999999392252902907785028219223e-09))) - 1.0);\n}\n\nfloat fa_v_ggx_aniso(float ndl, float ndv, float tdv, float bdv, float tdl, float bdl, float at, float ab)\n{\n    float param = ndv;\n    float param_1 = tdv;\n    float param_2 = bdv;\n    float param_3 = at;\n    float param_4 = ab;\n    float param_5 = ndl;\n    float param_6 = tdl;\n    float param_7 = bdl;\n    float param_8 = at;\n    float param_9 = ab;\n    return clamp(1.0 / ((4.0 * max(ndl * ndv, 9.9999997473787516355514526367188e-05)) * ((1.0 + fa_lambda_ggx_aniso(param, param_1, param_2, param_3, param_4)) + fa_lambda_ggx_aniso(param_5, param_6, param_7, param_8, param_9))), 0.0, 1.0);\n}\n\nvec3 fa_layers_light(FaLayers L, vec3 diffuse_color, vec3 f0, vec3 n, vec3 v, vec3 l, vec3 h, float ndl, float ndv, float ndh, float vdh, float alpha, float a2)\n{\n    float _5473 = step(9.9999997473787516355514526367188e-05, ndl);\n    float d_ggx;\n    float vis;\n    if (L.aniso != 0.0)\n    {\n        float param = ndh;\n        float param_1 = dot(L.t, h);\n        float param_2 = dot(L.b, h);\n        float param_3 = L.at;\n        float param_4 = L.ab;\n        d_ggx = fa_d_ggx_aniso(param, param_1, param_2, param_3, param_4);\n        float param_5 = ndl;\n        float param_6 = ndv;\n        float param_7 = dot(L.t, v);\n        float param_8 = dot(L.b, v);\n        float param_9 = dot(L.t, l);\n        float param_10 = dot(L.b, l);\n        float param_11 = L.at;\n        float param_12 = L.ab;\n        vis = fa_v_ggx_aniso(param_5, param_6, param_7, param_8, param_9, param_10, param_11, param_12);\n    }\n    else\n    {\n        float _5552 = ((ndh * ndh) * (a2 - 1.0)) + 1.0;\n        d_ggx = a2 / ((3.1415927410125732421875 * _5552) * _5552);\n        vis = 0.5 / max(mix((2.0 * ndl) * ndv, ndl + ndv, alpha), 9.9999997473787516355514526367188e-05);\n    }\n    vec3 base = diffuse_color + (((f0 + ((vec3(L.f90) - f0) * pow(clamp(1.0 - vdh, 0.0, 1.0), 5.0))) * ((d_ggx * vis) * 3.1415927410125732421875)) * _5473);\n    if (L.sheen_on)\n    {\n        float param_13 = L.sheen_alpha;\n        float param_14 = ndh;\n        float param_15 = ndl;\n        float param_16 = ndv;\n        base = (base * L.sheen_scale) + (L.sheen * (((fa_d_charlie(param_13, param_14) * fa_v_ashikhmin(param_15, param_16)) * 3.1415927410125732421875) * _5473));\n    }\n    vec3 result = base * (L.keep * ndl);\n    if (L.coat > 0.0)\n    {\n        FaLayers param_17 = L;\n        vec3 param_18 = l;\n        vec3 param_19 = h;\n        float param_20 = vdh;\n        result += vec3(fa_layers_coat(param_17, param_18, param_19, param_20));\n    }\n    return result;\n}\n\nvec2 fa_env_brdf(float rough, float ndv)\n{\n    vec4 _4676 = (vec4(-1.0, -0.0274999998509883880615234375, -0.572000026702880859375, 0.02199999988079071044921875) * rough) + vec4(1.0, 0.0425000004470348358154296875, 1.03999996185302734375, -0.039999999105930328369140625);\n    float _4679 = _4676.x;\n    return (vec2(-1.03999996185302734375, 1.03999996185302734375) * ((min(_4679 * _4679, exp2((-9.27999973297119140625) * ndv)) * _4679) + _4676.y)) + _4676.zw;\n}\n\nvec3 fa_probe_level(vec2 origin, float res, int lv, vec2 e)\n{\n    float _3986;\n    if (lv == 0)\n    {\n        _3986 = 0.0;\n    }\n    else\n    {\n        _3986 = res + 2.0;\n    }\n    float _3996;\n    if (lv == 0)\n    {\n        _3996 = 0.0;\n    }\n    else\n    {\n        _3996 = (res - (res / float(1 << max((lv - 1), 0)))) + (2.0 * float(lv - 1));\n    }\n    return textureLod(fa_probe_atlas_fa_env_smp, (((origin + vec2(_3986, _3996)) + vec2(1.0)) + (((e * 0.5) + vec2(0.5)) * (res / float(1 << lv)))) / fa_atlas_size(), 0.0).xyz;\n}\n\nvec3 fa_probe_radiance(vec2 origin, float res, vec3 d, float rough)\n{\n    float _4042;\n    if (res > 64.5)\n    {\n        _4042 = 5.0;\n    }\n    else\n    {\n        _4042 = (res > 32.5) ? 4.0 : 3.0;\n    }\n    float _4057 = clamp(rough, 0.0, 1.0) * (_4042 - 1.0);\n    int _4064 = int(min(floor(_4057), _4042 - 2.0));\n    float _4069 = _4057 - float(_4064);\n    vec3 param = d;\n    vec2 _4073 = fa_oct_encode(param);\n    vec2 param_1 = origin;\n    float param_2 = res;\n    int param_3 = _4064;\n    vec2 param_4 = _4073;\n    vec3 _4083 = fa_probe_level(param_1, param_2, param_3, param_4);\n    if (_4069 < 0.00200000009499490261077880859375)\n    {\n        return _4083;\n    }\n    vec2 param_5 = origin;\n    float param_6 = res;\n    int param_7 = _4064 + 1;\n    vec2 param_8 = _4073;\n    return mix(_4083, fa_probe_level(param_5, param_6, param_7, param_8), vec3(_4069));\n}\n\nvec3 fa_probe_box_dir(vec3 d, vec4 posw, vec4 bx, vec4 by, vec4 bz)\n{\n    if (posw.w < 0.5)\n    {\n        return d;\n    }\n    float _4154 = dot(bx.xyz, fa_world_pos) + bx.w;\n    float _4161 = dot(by.xyz, fa_world_pos) + by.w;\n    float _4168 = dot(bz.xyz, fa_world_pos) + bz.w;\n    float _4174 = dot(bx.xyz, d);\n    float _4178 = dot(by.xyz, d);\n    float _4182 = dot(bz.xyz, d);\n    float _4188;\n    if (_4174 > 9.9999999747524270787835121154785e-07)\n    {\n        _4188 = (1.0 - _4154) / _4174;\n    }\n    else\n    {\n        float _4202;\n        if (_4174 < (-9.9999999747524270787835121154785e-07))\n        {\n            _4202 = ((-1.0) - _4154) / _4174;\n        }\n        else\n        {\n            _4202 = 1000000015047466219876688855040.0;\n        }\n        _4188 = _4202;\n    }\n    float tx = _4188;\n    float _4219;\n    if (_4178 > 9.9999999747524270787835121154785e-07)\n    {\n        _4219 = (1.0 - _4161) / _4178;\n    }\n    else\n    {\n        float _4232;\n        if (_4178 < (-9.9999999747524270787835121154785e-07))\n        {\n            _4232 = ((-1.0) - _4161) / _4178;\n        }\n        else\n        {\n            _4232 = 1000000015047466219876688855040.0;\n        }\n        _4219 = _4232;\n    }\n    float ty = _4219;\n    float _4248;\n    if (_4182 > 9.9999999747524270787835121154785e-07)\n    {\n        _4248 = (1.0 - _4168) / _4182;\n    }\n    else\n    {\n        float _4261;\n        if (_4182 < (-9.9999999747524270787835121154785e-07))\n        {\n            _4261 = ((-1.0) - _4168) / _4182;\n        }\n        else\n        {\n            _4261 = 1000000015047466219876688855040.0;\n        }\n        _4248 = _4261;\n    }\n    float _4273 = tx;\n    float _4276 = (_4273 > 0.0) ? _4273 : 1000000015047466219876688855040.0;\n    tx = _4276;\n    float _4277 = ty;\n    float _4280 = (_4277 > 0.0) ? _4277 : 1000000015047466219876688855040.0;\n    ty = _4280;\n    float _4290 = min(_4276, min(_4280, (_4248 > 0.0) ? _4248 : 1000000015047466219876688855040.0));\n    if (_4290 > 100000001504746621987668885504.0)\n    {\n        return d;\n    }\n    vec3 _4306 = (fa_world_pos + (d * _4290)) - posw.xyz;\n    vec3 _4311;\n    if (dot(_4306, _4306) > 1.0000000133514319600180897396058e-10)\n    {\n        _4311 = normalize(_4306);\n    }\n    else\n    {\n        _4311 = d;\n    }\n    return _4311;\n}\n\nvec3 fa_probe_environment(vec4 tile, vec4 posw, vec4 bx, vec4 by, vec4 bz, inout vec3 d, float rough)\n{\n    vec3 param = d;\n    vec4 param_1 = posw;\n    vec4 param_2 = bx;\n    vec4 param_3 = by;\n    vec4 param_4 = bz;\n    d = fa_probe_box_dir(param, param_1, param_2, param_3, param_4);\n    vec2 param_5 = tile.xy;\n    float param_6 = tile.z;\n    vec3 param_7 = d;\n    float param_8 = rough;\n    return fa_probe_radiance(param_5, param_6, param_7, param_8);\n}\n\nvec3 fa_environment(vec3 d, float rough)\n{\n    float _4357 = (1.0 - fa_mesh_fs_params[42].w) - fa_mesh_fs_params[47].w;\n    vec3 outc = vec3(0.0);\n    if (_4357 > 0.0005000000237487256526947021484375)\n    {\n        vec3 base;\n        if (fa_mesh_fs_params[11].w > 0.5)\n        {\n            vec2 param = fa_mesh_fs_params[41].zw;\n            float param_1 = 128.0;\n            vec3 param_2 = d;\n            float param_3 = rough;\n            base = fa_probe_radiance(param, param_1, param_2, param_3);\n        }\n        else\n        {\n            float _4385 = rough * rough;\n            float _4416 = 0.60000002384185791015625 * _4385;\n            base = mix(mix(fa_mesh_fs_params[12].xyz * 0.550000011920928955078125, mix(fa_mesh_fs_params[12].xyz, fa_mesh_fs_params[11].xyz, vec3(pow(clamp(d.y * (1.0 - (0.699999988079071044921875 * _4385)), 0.0, 1.0), 0.550000011920928955078125))), vec3(smoothstep((-0.0500000007450580596923828125) - _4416, 0.0500000007450580596923828125 + _4416, d.y))), ((fa_mesh_fs_params[11].xyz + fa_mesh_fs_params[12].xyz) * 0.5) * 0.800000011920928955078125, vec3(_4385 * 0.60000002384185791015625));\n        }\n        outc = base * _4357;\n    }\n    if (fa_mesh_fs_params[42].w > 0.0)\n    {\n        vec4 param_4 = fa_mesh_fs_params[42];\n        vec4 param_5 = fa_mesh_fs_params[43];\n        vec4 param_6 = fa_mesh_fs_params[44];\n        vec4 param_7 = fa_mesh_fs_params[45];\n        vec4 param_8 = fa_mesh_fs_params[46];\n        vec3 param_9 = d;\n        float param_10 = rough;\n        vec3 _4475 = fa_probe_environment(param_4, param_5, param_6, param_7, param_8, param_9, param_10);\n        outc += (_4475 * fa_mesh_fs_params[42].w);\n    }\n    if (fa_mesh_fs_params[47].w > 0.0)\n    {\n        vec4 param_11 = fa_mesh_fs_params[47];\n        vec4 param_12 = fa_mesh_fs_params[48];\n        vec4 param_13 = fa_mesh_fs_params[49];\n        vec4 param_14 = fa_mesh_fs_params[50];\n        vec4 param_15 = fa_mesh_fs_params[51];\n        vec3 param_16 = d;\n        float param_17 = rough;\n        vec3 _4507 = fa_probe_environment(param_11, param_12, param_13, param_14, param_15, param_16, param_17);\n        outc += (_4507 * fa_mesh_fs_params[47].w);\n    }\n    return outc;\n}\n\nvec3 fa_layers_ibl(FaLayers L, vec3 n, vec3 v, vec3 f0, float roughness, float occlusion)\n{\n    vec3 rn = n;\n    if (L.aniso != 0.0)\n    {\n        vec3 _5154;\n        if (L.aniso >= 0.0)\n        {\n            _5154 = L.b;\n        }\n        else\n        {\n            _5154 = L.t;\n        }\n        rn = normalize(mix(n, cross(cross(_5154, v), _5154), vec3(abs(L.aniso) * smoothstep(0.0, 0.25, roughness))));\n    }\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05);\n    vec2 _5190 = fa_env_brdf(param, param_1);\n    vec3 param_2 = reflect(-v, rn);\n    float param_3 = roughness;\n    vec3 result = (fa_environment(param_2, param_3) * ((f0 * _5190.x) + (vec3(L.f90) * _5190.y))) * L.base_scale;\n    if (L.sheen_on)\n    {\n        vec3 param_4 = n;\n        float param_5 = L.sheen_rough;\n        result += ((L.sheen * (L.sheen_e * L.keep)) * fa_environment(param_4, param_5));\n    }\n    result *= occlusion;\n    if (L.coat > 0.0)\n    {\n        float param_6 = L.coat_rough;\n        float param_7 = L.coat_ndv;\n        vec2 _5248 = fa_env_brdf(param_6, param_7);\n        vec3 param_8 = reflect(-v, L.nc);\n        float param_9 = L.coat_rough;\n        result += (fa_environment(param_8, param_9) * (L.coat * ((0.039999999105930328369140625 * _5248.x) + _5248.y)));\n    }\n    return result;\n}\n\nvec3 fa_sky_reflection(vec3 n, vec3 v, vec3 f0, float roughness)\n{\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05);\n    vec2 _4718 = fa_env_brdf(param, param_1);\n    vec3 param_2 = reflect(-v, n);\n    float param_3 = roughness;\n    return fa_environment(param_2, param_3) * ((f0 * _4718.x) + vec3(_4718.y));\n}\n\nvec2 fa_xm_size(int k)\n{\n    return max(floor(fa_mesh_fs_params[24].zw / vec2(float(1 << k))), vec2(1.0));\n}\n\nvec2 fa_xm_origin(int k)\n{\n    if (k == 0)\n    {\n        return vec2(0.0);\n    }\n    float y = 0.0;\n    for (int j = 1; j < k; j++)\n    {\n        int param = j;\n        y += fa_xm_size(param).y;\n    }\n    return vec2(fa_mesh_fs_params[24].z, y);\n}\n\nvec3 fa_xm_texel(vec2 size, vec2 origin, vec2 p)\n{\n    return texelFetch(fa_screen_tex_fa_shadow_smp, ivec2(origin + clamp(p, vec2(0.0), size - vec2(1.0))), 0).xyz;\n}\n\nvec3 fa_xm_level(int k, vec2 uv)\n{\n    int param = k;\n    vec2 _5950 = fa_xm_size(param);\n    int param_1 = k;\n    vec2 _5954 = fa_xm_origin(param_1);\n    vec2 _5960 = (uv * _5950) - vec2(0.5);\n    vec2 _5963 = fract(_5960);\n    vec2 _5966 = floor(_5960);\n    vec2 param_2 = _5950;\n    vec2 param_3 = _5954;\n    vec2 param_4 = _5966;\n    vec2 param_5 = _5950;\n    vec2 param_6 = _5954;\n    vec2 param_7 = _5966 + vec2(1.0, 0.0);\n    vec2 param_8 = _5950;\n    vec2 param_9 = _5954;\n    vec2 param_10 = _5966 + vec2(0.0, 1.0);\n    vec2 param_11 = _5950;\n    vec2 param_12 = _5954;\n    vec2 param_13 = _5966 + vec2(1.0);\n    vec3 _6008 = vec3(_5963.x);\n    return mix(mix(fa_xm_texel(param_2, param_3, param_4), fa_xm_texel(param_5, param_6, param_7), _6008), mix(fa_xm_texel(param_8, param_9, param_10), fa_xm_texel(param_11, param_12, param_13), _6008), vec3(_5963.y));\n}\n\nvec3 fa_xm_sample(vec2 uv, float lod)\n{\n    float _6027 = max(fa_mesh_fs_params[31].w - 1.0, 0.0);\n    float _6031 = clamp(lod, 0.0, _6027);\n    int _6035 = int(floor(_6031));\n    int param = _6035;\n    vec2 param_1 = uv;\n    vec3 c = fa_xm_level(param, param_1);\n    float _6045 = float(_6035);\n    float _6046 = _6031 - _6045;\n    bool _6048 = _6046 > 0.001000000047497451305389404296875;\n    bool _6055;\n    if (_6048)\n    {\n        _6055 = _6045 < _6027;\n    }\n    else\n    {\n        _6055 = _6048;\n    }\n    if (_6055)\n    {\n        int param_2 = _6035 + 1;\n        vec2 param_3 = uv;\n        c = mix(c, fa_xm_level(param_2, param_3), vec3(_6046));\n    }\n    return c;\n}\n\nvec3 fa_transmitted(Surface s, vec3 n, vec3 v, float roughness, vec3 f0, float f90, float keep, float tr, inout float blend)\n{\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05);\n    vec2 _6081 = fa_env_brdf(param, param_1);\n    vec3 through = ((vec3(1.0) - clamp((f0 * _6081.x) + (vec3(f90) * _6081.y), vec3(0.0), vec3(1.0))) * s.albedo) * (tr * keep);\n    float _6109 = max(s.thickness, 0.0);\n    bool _6114 = _6109 > 0.0;\n    if ((s.attenuation_distance > 0.0) && _6114)\n    {\n        through *= exp((-((-log(clamp(s.attenuation_color, vec3(9.9999997473787516355514526367188e-05), vec3(1.0)))) / vec3(s.attenuation_distance))) * _6109);\n    }\n    bool _6139 = fa_mesh_fs_params[30].w > 1.5;\n    bool _6146;\n    if (!_6139)\n    {\n        _6146 = fa_mesh_fs_params[30].w < 0.5;\n    }\n    else\n    {\n        _6146 = _6139;\n    }\n    if (_6146)\n    {\n        blend = clamp(dot(through, vec3(0.3333333432674407958984375)), 0.0, 0.980000019073486328125);\n        return vec3(0.0);\n    }\n    vec3 world = fa_world_pos;\n    if (_6114)\n    {\n        world += (refract(-v, n, 1.0 / max(s.ior, 1.0)) * _6109);\n    }\n    vec4 _6181 = vec4(world, 1.0);\n    float _6186 = dot(fa_mesh_fs_params[28], _6181);\n    vec2 uv = vec2(0.5);\n    if (_6186 > 9.9999997473787516355514526367188e-05)\n    {\n        vec2 _6204 = vec2(dot(fa_mesh_fs_params[26], _6181), dot(fa_mesh_fs_params[27], _6181)) / vec2(_6186);\n        float _6212;\n        if (fa_mesh_fs_params[24].y > 0.5)\n        {\n            _6212 = (_6204.y * 0.5) + 0.5;\n        }\n        else\n        {\n            _6212 = 0.5 - (_6204.y * 0.5);\n        }\n        uv = vec2((_6204.x * 0.5) + 0.5, _6212);\n    }\n    vec2 param_2 = clamp(uv, vec2(0.0), vec2(1.0));\n    float param_3 = (clamp(roughness, 0.0, 1.0) * clamp((2.0 * s.ior) - 2.0, 0.0, 1.0)) * max(fa_mesh_fs_params[31].w - 1.0, 0.0);\n    return through * fa_xm_sample(param_2, param_3);\n}\n\nvec3 fa_shadow_debug(vec3 color, vec3 world)\n{\n    if (fa_shadows[27].w < 0.5)\n    {\n        return color;\n    }\n    int _3278 = int(fa_shadows[25].x + 0.5);\n    float _3288 = dot(world - fa_shadows[27].xyz, fa_shadows[28].xyz);\n    vec3 tint = vec3(0.3499999940395355224609375);\n    bool _3293 = _3278 > 0;\n    bool _3302;\n    if (_3293)\n    {\n        int param = _3278 - 1;\n        _3302 = _3288 <= fa_shadow_split_at(param);\n    }\n    else\n    {\n        _3302 = _3293;\n    }\n    if (_3302)\n    {\n        tint = vec3(1.0, 0.1500000059604644775390625, 0.100000001490116119384765625);\n        bool _3308 = _3278 > 1;\n        bool _3315;\n        if (_3308)\n        {\n            _3315 = _3288 > fa_shadows[24].x;\n        }\n        else\n        {\n            _3315 = _3308;\n        }\n        if (_3315)\n        {\n            tint = vec3(0.100000001490116119384765625, 0.89999997615814208984375, 0.20000000298023223876953125);\n        }\n        bool _3321 = _3278 > 2;\n        bool _3328;\n        if (_3321)\n        {\n            _3328 = _3288 > fa_shadows[24].y;\n        }\n        else\n        {\n            _3328 = _3321;\n        }\n        if (_3328)\n        {\n            tint = vec3(0.1500000059604644775390625, 0.300000011920928955078125, 1.0);\n        }\n        bool _3334 = _3278 > 3;\n        bool _3341;\n        if (_3334)\n        {\n            _3341 = _3288 > fa_shadows[24].z;\n        }\n        else\n        {\n            _3341 = _3334;\n        }\n        if (_3341)\n        {\n            tint = vec3(1.0, 0.89999997615814208984375, 0.100000001490116119384765625);\n        }\n    }\n    return mix(color, tint, vec3(0.550000011920928955078125));\n}\n\nvoid main()\n{\n    fa_inst_load();\n    vec3 _9187 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _9187 = -_9187;\n    }\n    vec3 _8482 = normalize(fa_mesh_fs_params[0].xyz - fa_world_pos);\n    vec3 param = fa_world_pos;\n    fa_cluster_begin(param);\n    SurfaceInput param_1 = SurfaceInput(fa_world_pos, _9187, fa_world_tangent, fa_uv, fa_vertex_color, _8482, gl_FrontFacing);\n    Surface _8490 = fa_standard_surface(param_1);\n    vec3 _9218 = _8490.albedo;\n    float _9219 = _8490.alpha;\n    vec3 _9220 = _8490.normal;\n    float _9221 = _8490.metallic;\n    float _9222 = _8490.roughness;\n    float _9223 = _8490.occlusion;\n    vec3 _9224 = _8490.emission;\n    float _9225 = _8490.clearcoat;\n    float _9226 = _8490.clearcoat_roughness;\n    vec3 _9227 = _8490.sheen_color;\n    float _9228 = _8490.sheen_roughness;\n    float _9229 = _8490.anisotropy;\n    float _9230 = _8490.anisotropy_rotation;\n    float _9231 = _8490.specular;\n    float _9232 = _8490.ior;\n    vec3 _9233 = _8490.specular_color;\n    float _9234 = _8490.transmission;\n    float _9235 = _8490.thickness;\n    vec3 _9236 = _8490.attenuation_color;\n    float _9237 = _8490.attenuation_distance;\n    SurfaceInput param_2 = SurfaceInput(fa_world_pos, _9187, fa_world_tangent, fa_uv, fa_vertex_color, _8482, gl_FrontFacing);\n    Surface param_3 = _8490;\n    surface(param_2, param_3);\n    _9218 = param_3.albedo;\n    _9219 = param_3.alpha;\n    _9220 = param_3.normal;\n    _9221 = param_3.metallic;\n    _9222 = param_3.roughness;\n    _9223 = param_3.occlusion;\n    _9224 = param_3.emission;\n    _9225 = param_3.clearcoat;\n    _9226 = param_3.clearcoat_roughness;\n    _9227 = param_3.sheen_color;\n    _9228 = param_3.sheen_roughness;\n    _9229 = param_3.anisotropy;\n    _9230 = param_3.anisotropy_rotation;\n    _9231 = param_3.specular;\n    _9232 = param_3.ior;\n    _9233 = param_3.specular_color;\n    _9234 = param_3.transmission;\n    _9235 = param_3.thickness;\n    _9236 = param_3.attenuation_color;\n    _9237 = param_3.attenuation_distance;\n    vec3 param_4 = fa_world_pos;\n    vec3 param_5 = _9187;\n    vec3 param_6 = param_3.albedo;\n    vec3 param_7 = param_3.normal;\n    fa_apply_decals(param_4, param_5, param_6, param_7);\n    _9218 = param_6;\n    _9220 = param_7;\n    float fa_tr_blend = 0.0;\n    vec3 result;\n    if (fa_mesh_fs_params[3].w > 0.5)\n    {\n        result = _9218;\n    }\n    else\n    {\n        vec3 _8530 = normalize(_9220);\n        float _8537 = clamp(_9221, 0.0, 1.0);\n        float _8541 = clamp(_9222, 0.0500000007450580596923828125, 1.0);\n        float _8545 = _8541 * _8541;\n        float _8549 = _8545 * _8545;\n        float _8554 = max(dot(_8530, _8482), 9.9999997473787516355514526367188e-05);\n        float _8560 = 1.0 - _8537;\n        float _8561 = clamp(_9234, 0.0, 1.0) * _8560;\n        vec3 _8570 = (_9218 * _8560) * (1.0 - _8561);\n        vec3 _8577 = mix(vec3(0.039999999105930328369140625), _9218, vec3(_8537));\n        vec3 f0 = _8577;\n        SurfaceInput param_8 = SurfaceInput(fa_world_pos, _9187, fa_world_tangent, fa_uv, fa_vertex_color, _8482, gl_FrontFacing);\n        Surface param_9 = Surface(_9218, _9219, _9220, _9221, _9222, _9223, _9224, _9225, _9226, _9227, _9228, _9229, _9230, _9231, _9232, _9233, _9234, _9235, _9236, _9237);\n        vec3 param_10 = _8530;\n        vec3 param_11 = _8482;\n        float param_12 = _8537;\n        float param_13 = _8541;\n        vec3 param_14 = _8577;\n        FaLayers _8593 = fa_layers_setup(param_8, param_9, param_10, param_11, param_12, param_13, param_14);\n        f0 = param_14;\n        vec3 param_15 = _8530;\n        vec3 lit = (fa_indirect_diffuse(param_15) * _8570) * _9223;\n        if (_8593.on)\n        {\n            lit *= _8593.base_scale;\n        }\n        int _8615 = fa_cl_ndir + fa_cl_local;\n        float _8680;\n        for (int ln = 0; ln < _8615; ln++)\n        {\n            int param_16 = ln;\n            int _8628 = fa_cl_light(param_16);\n            int param_17 = _8628;\n            if (fa_baked_keep(param_17) <= 0.0)\n            {\n                continue;\n            }\n            int param_18 = _8628;\n            vec3 param_19 = fa_world_pos;\n            vec3 param_20 = _9187;\n            LightSample _8644 = fa_light_shadowed(param_18, param_19, param_20);\n            float _8652 = max(dot(_8530, _8644.direction), 0.0);\n            float _8658 = _8644.attenuation * _8644.shadow;\n            vec3 _8663 = normalize(_8644.direction + _8482);\n            float _8668 = max(dot(_8530, _8663), 0.0);\n            float _8673 = max(dot(_8482, _8663), 0.0);\n            if (fa_light_is_area)\n            {\n                if (_8593.on)\n                {\n                    _8680 = _8593.f90;\n                }\n                else\n                {\n                    _8680 = 1.0;\n                }\n                int param_21 = _8628;\n                vec3 param_22 = fa_world_pos;\n                vec3 param_23 = _8530;\n                vec3 param_24 = _8482;\n                vec3 param_25 = _8570;\n                vec3 param_26 = f0;\n                float param_27 = _8680;\n                float param_28 = _8541;\n                float param_29 = _8554;\n                float param_30 = _8658;\n                vec3 area = fa_area_shade(param_21, param_22, param_23, param_24, param_25, param_26, param_27, param_28, param_29, param_30);\n                if (_8593.on)\n                {\n                    FaLayers param_31 = _8593;\n                    vec3 param_32 = area;\n                    int param_33 = _8628;\n                    vec3 param_34 = _8530;\n                    vec3 param_35 = _8482;\n                    vec3 param_36 = _8644.direction;\n                    float param_37 = _8554;\n                    float param_38 = _8658;\n                    area = fa_area_layers(param_31, param_32, param_33, param_34, param_35, param_36, param_37, param_38);\n                }\n                lit += area;\n            }\n            else\n            {\n                if (_8593.on)\n                {\n                    FaLayers param_39 = _8593;\n                    vec3 param_40 = _8570;\n                    vec3 param_41 = f0;\n                    vec3 param_42 = _8530;\n                    vec3 param_43 = _8482;\n                    vec3 param_44 = _8644.direction;\n                    vec3 param_45 = _8663;\n                    float param_46 = _8652;\n                    float param_47 = _8554;\n                    float param_48 = _8668;\n                    float param_49 = _8673;\n                    float param_50 = _8545;\n                    float param_51 = _8549;\n                    int param_52 = _8628;\n                    lit += (fa_layers_light(param_39, param_40, param_41, param_42, param_43, param_44, param_45, param_46, param_47, param_48, param_49, param_50, param_51) * ((fa_light_rgb(param_52) * fa_light_tint) * _8658));\n                }\n                else\n                {\n                    float _8782 = ((_8668 * _8668) * (_8549 - 1.0)) + 1.0;\n                    int param_53 = _8628;\n                    lit += (((_8570 + (((f0 + ((vec3(1.0) - f0) * pow(1.0 - _8673, 5.0))) * (((_8549 / ((3.1415927410125732421875 * _8782) * _8782)) * (0.5 / max(mix((2.0 * _8652) * _8554, _8652 + _8554, _8545), 9.9999997473787516355514526367188e-05))) * 3.1415927410125732421875)) * step(9.9999997473787516355514526367188e-05, _8652))) * (fa_light_rgb(param_53) * fa_light_tint)) * (_8652 * _8658));\n                }\n            }\n        }\n        if (_8593.on)\n        {\n            FaLayers param_54 = _8593;\n            vec3 param_55 = _8530;\n            vec3 param_56 = _8482;\n            vec3 param_57 = f0;\n            float param_58 = _8541;\n            float param_59 = _9223;\n            lit += fa_layers_ibl(param_54, param_55, param_56, param_57, param_58, param_59);\n        }\n        else\n        {\n            vec3 param_60 = _8530;\n            vec3 param_61 = _8482;\n            vec3 param_62 = f0;\n            float param_63 = _8541;\n            lit += (fa_sky_reflection(param_60, param_61, param_62, param_63) * _9223);\n        }\n        if (_8561 > 0.0)\n        {\n            float _8880;\n            if (_8593.on)\n            {\n                _8880 = _8593.f90;\n            }\n            else\n            {\n                _8880 = 1.0;\n            }\n            float _8888;\n            if (_8593.on)\n            {\n                _8888 = _8593.base_scale;\n            }\n            else\n            {\n                _8888 = 1.0;\n            }\n            Surface param_64 = Surface(_9218, _9219, _9220, _9221, _9222, _9223, _9224, _9225, _9226, _9227, _9228, _9229, _9230, _9231, _9232, _9233, _9234, _9235, _9236, _9237);\n            vec3 param_65 = _8530;\n            vec3 param_66 = _8482;\n            float param_67 = _8541;\n            vec3 param_68 = f0;\n            float param_69 = _8880;\n            float param_70 = _8888;\n            float param_71 = _8561;\n            float param_72 = fa_tr_blend;\n            vec3 _8912 = fa_transmitted(param_64, param_65, param_66, param_67, param_68, param_69, param_70, param_71, param_72);\n            fa_tr_blend = param_72;\n            lit += _8912;\n        }\n        result = lit;\n    }\n    vec3 _8919 = result;\n    vec3 _8920 = _8919 + _9224;\n    result = _8920;\n    vec3 param_73 = _8920;\n    vec3 param_74 = fa_world_pos;\n    result = fa_shadow_debug(param_73, param_74);\n    bool _8929 = fa_mesh_fs_params[7].w > 0.0;\n    bool _8936;\n    if (!_8929)\n    {\n        _8936 = fa_mesh_fs_params[8].y > 0.0;\n    }\n    else\n    {\n        _8936 = _8929;\n    }\n    if (_8936)\n    {\n        vec3 _8945 = fa_world_pos - fa_mesh_fs_params[0].xyz;\n        float _8951 = dot(_8945, fa_mesh_fs_params[9].xyz);\n        bool _8955 = fa_mesh_fs_params[9].w > 0.5;\n        float _8956;\n        if (_8955)\n        {\n            _8956 = _8951;\n        }\n        else\n        {\n            _8956 = length(_8945);\n        }\n        float _8968 = _8956 - fa_mesh_fs_params[8].x;\n        if (_8968 > 0.0)\n        {\n            float _8977 = fa_mesh_fs_params[7].w * _8968;\n            float tau = _8977 * _8977;\n            if (fa_mesh_fs_params[8].y > 0.0)\n            {\n                float _8993;\n                if (_8955)\n                {\n                    _8993 = fa_world_pos.y - (fa_mesh_fs_params[9].y * _8951);\n                }\n                else\n                {\n                    _8993 = fa_mesh_fs_params[0].y;\n                }\n                float _9014 = mix(_8993, fa_world_pos.y, clamp(fa_mesh_fs_params[8].x / _8956, 0.0, 1.0));\n                float _9018 = fa_world_pos.y - _9014;\n                float _9023 = _9014 - fa_mesh_fs_params[8].z;\n                float _9028 = fa_world_pos.y - fa_mesh_fs_params[8].z;\n                bool _9031 = _9023 <= 0.0;\n                bool _9032 = !_9031;\n                bool _9038;\n                if (_9032)\n                {\n                    _9038 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _9038 = _9031;\n                }\n                float _9039;\n                if (_9038)\n                {\n                    _9039 = fa_mesh_fs_params[8].y;\n                }\n                else\n                {\n                    _9039 = fa_mesh_fs_params[8].y * exp(-min(fa_mesh_fs_params[8].w * _9023, 80.0));\n                }\n                bool _9066;\n                if (_9032)\n                {\n                    _9066 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _9066 = _9031;\n                }\n                float _9067;\n                if (_9066)\n                {\n                    _9067 = fa_mesh_fs_params[8].y * _9023;\n                }\n                else\n                {\n                    _9067 = (fa_mesh_fs_params[8].y * (1.0 - exp(-min(fa_mesh_fs_params[8].w * _9023, 80.0)))) / fa_mesh_fs_params[8].w;\n                }\n                bool _9092 = _9028 <= 0.0;\n                bool _9099;\n                if (!_9092)\n                {\n                    _9099 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _9099 = _9092;\n                }\n                float _9100;\n                if (_9099)\n                {\n                    _9100 = fa_mesh_fs_params[8].y * _9028;\n                }\n                else\n                {\n                    _9100 = (fa_mesh_fs_params[8].y * (1.0 - exp(-min(fa_mesh_fs_params[8].w * _9028, 80.0)))) / fa_mesh_fs_params[8].w;\n                }\n                float _9127;\n                if (abs(_9018) < 0.001000000047497451305389404296875)\n                {\n                    _9127 = _9039;\n                }\n                else\n                {\n                    _9127 = (_9100 - _9067) / _9018;\n                }\n                tau += (_8968 * max(_9127, 0.0));\n            }\n            result = mix(result, fa_mesh_fs_params[7].xyz, vec3(clamp(1.0 - exp(-clamp(tau, 0.0, 80.0)), 0.0, 1.0)));\n        }\n    }\n    if (fa_tr_blend > 0.0)\n    {\n        float _9163 = 1.0 - fa_tr_blend;\n        result /= vec3(_9163);\n        _9219 *= _9163;\n    }\n    fa_frag_color = vec4(result, _9219);\n}\n\n",
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
            "size": 848,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_657",
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
            "inst_name": "_2319",
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
            "name": "fa_screen_tex_fa_shadow_smp",
            "view_name": "fa_screen_tex",
            "sampler_name": "fa_shadow_smp",
            "view_slot": 28,
            "sampler_slot": 1,
            "glsl_name": "fa_screen_tex_fa_shadow_smp"
          },
          {
            "slot": 13,
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
      "vs": "#version 430\n\nstruct VertexData\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 color;\n    vec3 object_pos;\n};\n\nuniform vec4 fa_material_vs[1];\nuniform vec4 fa_mesh_vs_params[11];\nuniform vec4 fa_skin[192];\nlayout(binding = 0) uniform sampler2D fa_vs_height_fa_vs_height_smp;\n\nlayout(location = 0) out vec3 fa_world_pos;\nlayout(location = 1) out vec3 fa_world_normal;\nlayout(location = 2) out vec4 fa_world_tangent;\nlayout(location = 3) out vec2 fa_uv;\nlayout(location = 4) out vec4 fa_vertex_color;\nlayout(location = 5) in vec4 fa_inst_m0;\nlayout(location = 6) in vec4 fa_inst_m1;\nlayout(location = 7) in vec4 fa_inst_m2;\nlayout(location = 8) in vec4 fa_inst_m3;\nlayout(location = 9) in vec4 fa_joints;\nlayout(location = 10) in vec4 fa_weights;\nlayout(location = 0) in vec3 fa_position;\nlayout(location = 1) in vec3 fa_normal;\nlayout(location = 3) in vec4 fa_tangent;\nlayout(location = 2) in vec2 fa_texcoord0;\nlayout(location = 4) in vec4 fa_color;\nlayout(location = 5) out vec3 fa_lm;\n\nvoid fa_inst_begin()\n{\n}\n\nmat4 fa_skin_matrix(vec4 joints, vec4 weights)\n{\n    vec4 r0 = vec4(0.0);\n    vec4 r1 = vec4(0.0);\n    vec4 r2 = vec4(0.0);\n    for (int i = 0; i < 4; i++)\n    {\n        int _203 = int((joints[i] * 255.0) + 0.5) * 3;\n        r0 += (fa_skin[_203 * 1 + 0] * weights[i]);\n        r1 += (fa_skin[(_203 + 1) * 1 + 0] * weights[i]);\n        r2 += (fa_skin[(_203 + 2) * 1 + 0] * weights[i]);\n    }\n    return mat4(vec4(r0.x, r1.x, r2.x, 0.0), vec4(r0.y, r1.y, r2.y, 0.0), vec4(r0.z, r1.z, r2.z, 0.0), vec4(r0.w, r1.w, r2.w, 1.0));\n}\n\nVertexData fa_vertex_data(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    vec3 _108 = cross(model[1].xyz, model[2].xyz);\n    float _113 = (dot(model[0].xyz, _108) < 0.0) ? (-1.0) : 1.0;\n    return VertexData((model * vec4(position, 1.0)).xyz, (((_108 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _113, vec4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _113), texcoord0 * fa_mesh_vs_params[8].xy, color, position);\n}\n\nvoid vertex(inout VertexData v)\n{\n    v.world_pos.y += (textureLod(fa_vs_height_fa_vs_height_smp, v.uv, 0.0).x * fa_material_vs[0].x);\n}\n\nvoid fa_shade_vertex(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    mat4 param = model;\n    vec3 param_1 = position;\n    vec3 param_2 = normal;\n    vec4 param_3 = tangent;\n    vec2 param_4 = texcoord0;\n    vec4 param_5 = color;\n    VertexData param_6 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    vertex(param_6);\n    fa_world_pos = param_6.world_pos;\n    fa_world_normal = param_6.world_normal;\n    fa_world_tangent = param_6.world_tangent;\n    fa_uv = param_6.uv;\n    fa_vertex_color = param_6.color;\n    gl_Position = mat4(fa_mesh_vs_params[0], fa_mesh_vs_params[1], fa_mesh_vs_params[2], fa_mesh_vs_params[3]) * vec4(param_6.world_pos, 1.0);\n}\n\nvoid main()\n{\n    fa_inst_begin();\n    vec4 param = fa_joints;\n    vec4 param_1 = fa_weights;\n    mat4 param_2 = mat4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3) * fa_skin_matrix(param, param_1);\n    vec3 param_3 = fa_position;\n    vec3 param_4 = fa_normal;\n    vec4 param_5 = fa_tangent;\n    vec2 param_6 = fa_texcoord0;\n    vec4 param_7 = fa_color;\n    fa_shade_vertex(param_2, param_3, param_4, param_5, param_6, param_7);\n    fa_lm = vec3(0.0);\n}\n\n",
      "fs": "#version 430\n\nstruct SurfaceInput\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 vertex_color;\n    vec3 view_dir;\n    bool front_facing;\n};\n\nstruct LightSample\n{\n    vec3 direction;\n    vec3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct Surface\n{\n    vec3 albedo;\n    float alpha;\n    vec3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    vec3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    vec3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    vec3 specular_color;\n    float transmission;\n    float thickness;\n    vec3 attenuation_color;\n    float attenuation_distance;\n};\n\nstruct FaLayers\n{\n    bool on;\n    float f90;\n    float keep;\n    float base_scale;\n    float coat;\n    float coat_rough;\n    float coat_alpha;\n    float coat_a2;\n    vec3 nc;\n    float coat_ndv;\n    bool sheen_on;\n    vec3 sheen;\n    float sheen_rough;\n    float sheen_alpha;\n    float sheen_scale;\n    float sheen_e;\n    float aniso;\n    vec3 t;\n    vec3 b;\n    float at;\n    float ab;\n};\n\nconst float _4819[63] = float[](1.0, 1.0, 1.0, 0.4790000021457672119140625, 0.11699999868869781494140625, 0.01200000010430812835693359375, 0.0, 0.0, 0.0, 1.0, 1.0, 1.0, 0.578000009059906005859375, 0.19300000369548797607421875, 0.0350000001490116119384765625, 0.0030000000260770320892333984375, 0.0, 0.0, 1.0, 1.0, 1.0, 0.6740000247955322265625, 0.3459999859333038330078125, 0.1319999992847442626953125, 0.032999999821186065673828125, 0.0040000001899898052215576171875, 0.0, 0.971000015735626220703125, 0.954999983310699462890625, 0.828999996185302734375, 0.63999998569488525390625, 0.42599999904632568359375, 0.24500000476837158203125, 0.115000002086162567138671875, 0.037000000476837158203125, 0.0030000000260770320892333984375, 0.7469999790191650390625, 0.737999975681304931640625, 0.670000016689300537109375, 0.563000023365020751953125, 0.4309999942779541015625, 0.3039999902248382568359375, 0.1940000057220458984375, 0.1019999980926513671875, 0.0309999994933605194091796875, 0.614000022411346435546875, 0.609000027179718017578125, 0.566999971866607666015625, 0.499000012874603271484375, 0.412000000476837158203125, 0.32400000095367431640625, 0.240999996662139892578125, 0.162000000476837158203125, 0.087999999523162841796875, 0.538999974727630615234375, 0.535000026226043701171875, 0.505999982357025146484375, 0.4569999873638153076171875, 0.393999993801116943359375, 0.328999996185302734375, 0.2660000026226043701171875, 0.203999996185302734375, 0.14200000464916229248046875);\n\nuniform vec4 fa_mesh_fs_params[53];\nuniform vec4 fa_shadows[30];\nlayout(binding = 0) uniform sampler2D fa_light_tex_fa_shadow_smp;\nlayout(binding = 1) uniform sampler2D fa_tex_fa_smp;\nlayout(binding = 2) uniform sampler2D fa_normal_tex_fa_smp;\nlayout(binding = 3) uniform sampler2D fa_mr_tex_fa_smp;\nlayout(binding = 4) uniform sampler2D fa_occlusion_tex_fa_smp;\nlayout(binding = 5) uniform sampler2D fa_emissive_tex_fa_smp;\nlayout(binding = 6) uniform sampler2D height_height_smp;\nlayout(binding = 7) uniform sampler2D fa_decal_tex_fa_env_smp;\nlayout(binding = 8) uniform sampler2D fa_lightmap_fa_env_smp;\nlayout(binding = 9) uniform sampler2D fa_probe_atlas_fa_env_smp;\nlayout(binding = 10) uniform sampler2D fa_light_atlas_fa_env_smp;\nlayout(binding = 11) uniform sampler2D fa_screen_tex_fa_shadow_smp;\nlayout(binding = 12) uniform sampler2D fa_shadow_tex_fa_shadow_smp;\n\nlayout(location = 0) in vec3 fa_world_pos;\nlayout(location = 5) in vec3 fa_lm;\nlayout(location = 1) in vec3 fa_world_normal;\nlayout(location = 2) in vec4 fa_world_tangent;\nlayout(location = 3) in vec2 fa_uv;\nlayout(location = 4) in vec4 fa_vertex_color;\nlayout(location = 0) out vec4 fa_frag_color;\nvec3 fa_light_tint;\nbool fa_light_is_area;\nint fa_cl_ndir;\nint fa_cl_slot;\nint fa_cl_local;\n\nvoid fa_inst_load()\n{\n}\n\nvec4 fa_light_texel(int t)\n{\n    return texelFetch(fa_light_tex_fa_shadow_smp, ivec2(t & 1023, t >> 10), 0);\n}\n\nvec4 fa_cluster_texel(vec3 world_pos)\n{\n    bool _1595 = fa_mesh_fs_params[19].x < 0.0;\n    bool _1602;\n    if (!_1595)\n    {\n        _1602 = fa_mesh_fs_params[19].w < 1.0;\n    }\n    else\n    {\n        _1602 = _1595;\n    }\n    bool _1610;\n    if (!_1602)\n    {\n        _1610 = fa_mesh_fs_params[18].x < 1.0;\n    }\n    else\n    {\n        _1610 = _1602;\n    }\n    bool _1617;\n    if (!_1610)\n    {\n        _1617 = fa_mesh_fs_params[18].y < 1.0;\n    }\n    else\n    {\n        _1617 = _1610;\n    }\n    bool _1624;\n    if (!_1617)\n    {\n        _1624 = fa_mesh_fs_params[19].y < 1.0;\n    }\n    else\n    {\n        _1624 = _1617;\n    }\n    if (_1624)\n    {\n        return vec4(0.0);\n    }\n    vec4 _1634 = vec4(world_pos, 1.0);\n    float _1640 = dot(fa_mesh_fs_params[16], _1634);\n    if (!(_1640 > 9.9999999747524270787835121154785e-07))\n    {\n        return vec4(0.0);\n    }\n    vec2 _1662 = vec2(dot(fa_mesh_fs_params[14], _1634), dot(fa_mesh_fs_params[15], _1634)) / vec2(_1640);\n    int _1666 = int(fa_mesh_fs_params[18].x);\n    int _1670 = int(fa_mesh_fs_params[18].y);\n    int param = (int(fa_mesh_fs_params[19].x) + (((clamp(int(floor(log2(max(dot(fa_mesh_fs_params[17].xyz, world_pos) + fa_mesh_fs_params[17].w, fa_mesh_fs_params[18].w) / fa_mesh_fs_params[18].w) * fa_mesh_fs_params[18].z)), 0, int(fa_mesh_fs_params[19].y) - 1) * _1670) + clamp(int(floor(((_1662.y * 0.5) + 0.5) * fa_mesh_fs_params[18].y)), 0, _1670 - 1)) * _1666)) + clamp(int(floor(((_1662.x * 0.5) + 0.5) * fa_mesh_fs_params[18].x)), 0, _1666 - 1);\n    return fa_light_texel(param);\n}\n\nivec2 fa_cluster_lookup(vec3 world_pos)\n{\n    vec3 param = world_pos;\n    vec4 _1746 = fa_cluster_texel(param);\n    return ivec2(int(_1746.x), int(_1746.y));\n}\n\nvoid fa_cluster_begin(vec3 world_pos)\n{\n    fa_cl_ndir = int(fa_mesh_fs_params[19].z);\n    vec3 param = world_pos;\n    ivec2 _6286 = fa_cluster_lookup(param);\n    fa_cl_slot = _6286.x;\n    fa_cl_local = _6286.y;\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nvec3 fa_linear_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_tex_fix(inout vec3 c, float mode)\n{\n    if (mode > 1.5)\n    {\n        vec3 param = c;\n        vec3 _7459 = fa_linear_to_srgb(param);\n        c = _7459;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            vec3 param_1 = c;\n            vec3 _7467 = fa_srgb_to_linear(param_1);\n            c = _7467;\n        }\n    }\n    return c;\n}\n\nvec3 fa_tangent_normal(SurfaceInput i, vec3 m)\n{\n    vec3 _539;\n    if (i.front_facing)\n    {\n        _539 = i.world_normal;\n    }\n    else\n    {\n        _539 = -i.world_normal;\n    }\n    vec3 _563 = normalize(i.world_tangent.xyz - (_539 * dot(_539, i.world_tangent.xyz)));\n    vec3 _590 = normalize(((_563 * m.x) + ((cross(_539, _563) * i.world_tangent.w) * m.y)) + (_539 * m.z));\n    vec3 _593;\n    if (i.front_facing)\n    {\n        _593 = _590;\n    }\n    else\n    {\n        _593 = -_590;\n    }\n    return _593;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    vec4 base_t = texture(fa_tex_fa_smp, i.uv, fa_mesh_fs_params[12].w);\n    float param = fa_mesh_fs_params[6].w;\n    float param_1 = 1.0;\n    vec3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    vec3 _7499 = fa_tex_fix(param_2, param_3);\n    vec4 _9793 = base_t;\n    _9793.x = _7499.x;\n    _9793.y = _7499.y;\n    _9793.z = _7499.z;\n    base_t = _9793;\n    vec4 _7513 = (_9793 * fa_mesh_fs_params[2]) * i.vertex_color;\n    vec3 _9548 = i.world_normal;\n    if (fa_mesh_fs_params[6].z > 0.5)\n    {\n        float param_4 = fa_mesh_fs_params[6].w;\n        float param_5 = 16.0;\n        vec3 param_6 = texture(fa_normal_tex_fa_smp, i.uv, fa_mesh_fs_params[12].w).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        vec3 _7547 = fa_tex_fix(param_6, param_7);\n        vec3 _7550 = (_7547 * 2.0) - vec3(1.0);\n        vec2 _7555 = _7550.xy * fa_mesh_fs_params[6].x;\n        vec3 _9801 = _7550;\n        _9801.x = _7555.x;\n        _9801.y = _7555.y;\n        SurfaceInput param_8 = i;\n        vec3 param_9 = _9801;\n        _9548 = fa_tangent_normal(param_8, param_9);\n    }\n    vec4 mrt = texture(fa_mr_tex_fa_smp, i.uv, fa_mesh_fs_params[12].w);\n    float param_10 = fa_mesh_fs_params[6].w;\n    float param_11 = 64.0;\n    vec3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    vec3 _7585 = fa_tex_fix(param_12, param_13);\n    vec4 _9804 = mrt;\n    _9804.x = _7585.x;\n    _9804.y = _7585.y;\n    _9804.z = _7585.z;\n    mrt = _9804;\n    vec4 _7615 = texture(fa_occlusion_tex_fa_smp, i.uv, fa_mesh_fs_params[12].w);\n    float param_14 = fa_mesh_fs_params[6].w;\n    float param_15 = 256.0;\n    vec3 param_16 = _7615.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    vec3 _7626 = fa_tex_fix(param_16, param_17);\n    float param_18 = fa_mesh_fs_params[6].w;\n    float param_19 = 4.0;\n    vec3 param_20 = texture(fa_emissive_tex_fa_smp, i.uv, fa_mesh_fs_params[12].w).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    vec3 _7658 = fa_tex_fix(param_20, param_21);\n    float _9553 = fa_mesh_fs_params[20].x;\n    float _9554 = fa_mesh_fs_params[20].y;\n    float _9557 = fa_mesh_fs_params[20].z;\n    float _9556 = fa_mesh_fs_params[21].w;\n    float _9559 = fa_mesh_fs_params[22].x;\n    if (fa_mesh_fs_params[22].z > 0.5)\n    {\n        if (mod(fa_mesh_fs_params[22].z, 2.0) > 0.5)\n        {\n            _9553 *= _7626.y;\n            _9554 *= _7626.z;\n            _9556 *= _7615.w;\n        }\n        if (fa_mesh_fs_params[22].z > 1.5)\n        {\n            _9557 *= mrt.x;\n            _9559 *= mrt.w;\n        }\n    }\n    return Surface(_7513.xyz, _7513.w, _9548, clamp(fa_mesh_fs_params[5].x * _7585.z, 0.0, 1.0), clamp(fa_mesh_fs_params[5].y * _7585.y, 0.0500000007450580596923828125, 1.0), 1.0 + (fa_mesh_fs_params[6].y * (_7626.x - 1.0)), fa_mesh_fs_params[3].xyz + (fa_mesh_fs_params[4].xyz * _7658), _9553, _9554, fa_mesh_fs_params[21].xyz, _9556, _9557, fa_mesh_fs_params[20].w, _9559, fa_mesh_fs_params[22].y, fa_mesh_fs_params[23].xyz, fa_mesh_fs_params[30].x, fa_mesh_fs_params[30].y, fa_mesh_fs_params[31].xyz, fa_mesh_fs_params[30].z);\n}\n\nvoid surface(SurfaceInput i, inout Surface s)\n{\n    s.albedo *= mix(0.5, 1.0, texture(height_height_smp, i.uv).x);\n}\n\nvec4 fa_decal_tile(vec4 rect, vec2 uv, vec2 atlas, vec2 ddx, vec2 ddy)\n{\n    vec2 _1826 = rect.zw - rect.xy;\n    vec2 _1830 = _1826 * atlas;\n    vec2 _1834 = ddx * _1830;\n    vec2 _1838 = ddy * _1830;\n    return textureLod(fa_decal_tex_fa_env_smp, rect.xy + (clamp(uv, vec2(0.0), vec2(1.0)) * _1826), clamp(0.5 * log2(max(max(dot(_1834, _1834), dot(_1838, _1838)), 9.9999999392252902907785028219223e-09)), 0.0, 3.0));\n}\n\nvec3 fa_dc_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_dc_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvoid fa_apply_decals(vec3 world_pos, vec3 geo_normal, inout vec3 albedo, inout vec3 normal)\n{\n    bool _1871 = fa_mesh_fs_params[10].y < 0.5;\n    bool _1878;\n    if (!_1871)\n    {\n        _1878 = fa_mesh_fs_params[10].w < 0.5;\n    }\n    else\n    {\n        _1878 = _1871;\n    }\n    if (_1878)\n    {\n        return;\n    }\n    vec3 _1884 = dFdx(world_pos);\n    vec3 _1887 = dFdy(world_pos);\n    vec3 param = world_pos;\n    vec4 _1891 = fa_cluster_texel(param);\n    int _1895 = int(_1891.w);\n    if (_1895 < 1)\n    {\n        return;\n    }\n    int _1905 = int(fa_mesh_fs_params[10].y + 0.5);\n    int param_1 = _1905;\n    vec4 _1909 = fa_light_texel(param_1);\n    vec2 _1912 = _1909.yz;\n    int _1916 = int(_1909.w);\n    int param_2 = _1905 + 1;\n    vec4 _1921 = fa_light_texel(param_2);\n    float _1922 = _1921.x;\n    int _1928 = int(fa_mesh_fs_params[10].w + 0.5) - 1;\n    int _1932 = int(_1891.z);\n    vec3 _2197;\n    for (int k = 0; k < _1895; k++)\n    {\n        int _1945 = _1932 + k;\n        int param_3 = _1916 + (_1945 >> 2);\n        int _1962 = (_1905 + 2) + (int(fa_light_texel(param_3)[_1945 & 3]) * 7);\n        int param_4 = _1962 + 6;\n        vec4 _1967 = fa_light_texel(param_4);\n        if (((int(_1967.w + 0.5) >> _1928) & 1) == 0)\n        {\n            continue;\n        }\n        int param_5 = _1962;\n        vec4 _1982 = fa_light_texel(param_5);\n        int param_6 = _1962 + 1;\n        vec4 _1987 = fa_light_texel(param_6);\n        int param_7 = _1962 + 2;\n        vec4 _1992 = fa_light_texel(param_7);\n        vec3 _1995 = _1982.xyz;\n        float _2000 = dot(_1995, world_pos) + _1982.w;\n        vec3 _2002 = _1987.xyz;\n        float _2007 = dot(_2002, world_pos) + _1987.w;\n        vec3 _2009 = _1992.xyz;\n        float _2014 = dot(_2009, world_pos) + _1992.w;\n        bool _2019 = abs(_2000) > 0.5;\n        bool _2027;\n        if (!_2019)\n        {\n            _2027 = abs(_2007) > 0.5;\n        }\n        else\n        {\n            _2027 = _2019;\n        }\n        bool _2035;\n        if (!_2027)\n        {\n            _2035 = abs(_2014) > 0.5;\n        }\n        else\n        {\n            _2035 = _2027;\n        }\n        if (_2035)\n        {\n            continue;\n        }\n        float _2050 = clamp(dot(geo_normal, normalize(_2009)) * _1967.z, 0.0, 1.0);\n        if (_2050 <= 0.0)\n        {\n            continue;\n        }\n        float _2070 = (clamp((0.5 - abs(_2014)) * 10.0, 0.0, 1.0) * _2050) * _1967.x;\n        vec2 _2078 = vec2(_2000 + 0.5, 0.5 - _2007);\n        vec2 _2088 = vec2(dot(_1995, _1884), dot(_2002, _1884));\n        vec2 _2098 = vec2(dot(_1995, _1887), dot(_2002, _1887));\n        int param_8 = _1962 + 5;\n        vec4 _2103 = fa_light_texel(param_8);\n        int param_9 = _1962 + 3;\n        vec4 _2108 = fa_light_texel(param_9);\n        int param_10 = _1962 + 4;\n        vec4 _2113 = fa_light_texel(param_10);\n        float tex_a = 1.0;\n        vec3 col = _2103.xyz;\n        bool _2123 = _2108.z > _2108.x;\n        if (_2123)\n        {\n            vec4 param_11 = _2108;\n            vec2 param_12 = _2078;\n            vec2 param_13 = _1912;\n            vec2 param_14 = _2088;\n            vec2 param_15 = _2098;\n            vec4 tx = fa_decal_tile(param_11, param_12, param_13, param_14, param_15);\n            if ((_1922 > 0.5) && (_1922 < 1.5))\n            {\n                vec3 param_16 = tx.xyz;\n                vec3 _2149 = fa_dc_to_linear(param_16);\n                vec4 _9636 = tx;\n                _9636.x = _2149.x;\n                _9636.y = _2149.y;\n                _9636.z = _2149.z;\n                tx = _9636;\n            }\n            col *= tx.xyz;\n            tex_a = tx.w;\n        }\n        albedo = mix(albedo, col, vec3(clamp((_2070 * tex_a) * _2103.w, 0.0, 1.0)));\n        if (_2113.z > _2113.x)\n        {\n            vec4 param_17 = _2113;\n            vec2 param_18 = _2078;\n            vec2 param_19 = _1912;\n            vec2 param_20 = _2088;\n            vec2 param_21 = _2098;\n            vec4 _2193 = fa_decal_tile(param_17, param_18, param_19, param_20, param_21);\n            if (_1922 > 1.5)\n            {\n                vec3 param_22 = _2193.xyz;\n                vec3 _2203 = fa_dc_to_srgb(param_22);\n                _2197 = _2203;\n            }\n            else\n            {\n                _2197 = _2193.xyz;\n            }\n            vec3 _2212 = (_2197 * 2.0) - vec3(1.0);\n            vec2 _2217 = _2212.xy * _1967.y;\n            vec3 _2239 = (normalize(_1995) * _2217.x) + (normalize(_2002) * _2217.y);\n            vec3 _2242 = normalize(normal);\n            normal = normalize(mix(_2242, normalize((_2242 * max(_2212.z, 0.0500000007450580596923828125)) + (_2239 - (_2242 * dot(_2242, _2239)))), vec3(clamp(_2070 * (_2123 ? tex_a : 1.0), 0.0, 1.0))));\n        }\n    }\n}\n\nfloat fa_sheen_albedo(float ndv, float rough)\n{\n    float _4744 = min(sqrt(max(rough - 0.100000001490116119384765625, 0.0) * 1.111111164093017578125) * 6.0, 5.999000072479248046875);\n    float _4752 = min(sqrt(clamp(ndv, 0.0, 1.0)) * 8.0, 7.999000072479248046875);\n    int _4755 = int(_4744);\n    int _4758 = int(_4752);\n    float _4768 = _4752 - float(_4758);\n    int _4823 = (_4755 * 9) + _4758;\n    int _4843 = ((_4755 + 1) * 9) + _4758;\n    return mix(mix(_4819[_4823], _4819[_4823 + 1], _4768), mix(_4819[_4843], _4819[_4843 + 1], _4768), _4744 - float(_4755));\n}\n\nFaLayers fa_layers_setup(SurfaceInput i, Surface s, vec3 n, vec3 v, float metallic, float roughness, inout vec3 f0)\n{\n    bool _9471 = false;\n    float _9472 = 1.0;\n    float _9473 = 1.0;\n    float _9474 = 1.0;\n    float _9475 = 0.0;\n    float _9476 = 0.0;\n    float _9477 = 0.0;\n    float _9478 = 0.0;\n    float _9480 = 1.0;\n    bool _9481 = false;\n    vec3 _9482 = vec3(0.0);\n    float _9483 = 1.0;\n    float _9484 = 1.0;\n    float _9485 = 1.0;\n    float _9486 = 0.0;\n    float _9487 = 0.0;\n    vec3 _9488 = vec3(1.0, 0.0, 0.0);\n    vec3 _9489 = vec3(0.0, 0.0, 1.0);\n    float _9490 = 1.0;\n    float _9491 = 1.0;\n    float _4894 = clamp(s.specular, 0.0, 1.0);\n    float _4898 = clamp(s.ior, 1.0, 3.0);\n    bool _4903 = (_4894 != 1.0) || (_4898 != 1.5);\n    bool _4912;\n    if (!_4903)\n    {\n        _4912 = any(notEqual(s.specular_color, vec3(1.0)));\n    }\n    else\n    {\n        _4912 = _4903;\n    }\n    if (_4912)\n    {\n        float _4920 = (_4898 - 1.0) / (_4898 + 1.0);\n        f0 = mix(min(vec3(_4920 * _4920) * max(s.specular_color, vec3(0.0)), vec3(1.0)) * _4894, s.albedo, vec3(metallic));\n        _9472 = mix(_4894, 1.0, metallic);\n        _9471 = true;\n    }\n    float _4947 = clamp(s.clearcoat, 0.0, 1.0);\n    if (_4947 > 0.0)\n    {\n        float _4955 = clamp(s.clearcoat_roughness, 0.0500000007450580596923828125, 1.0);\n        _9475 = _4947;\n        _9476 = _4955;\n        float _4962 = _4955 * _4955;\n        _9477 = _4962;\n        _9478 = _4962 * _4962;\n        float _4974 = max(dot(i.world_normal, v), 9.9999997473787516355514526367188e-05);\n        _9480 = _4974;\n        _9473 = 1.0 - (_4947 * (0.039999999105930328369140625 + (0.959999978542327880859375 * pow(clamp(1.0 - _4974, 0.0, 1.0), 5.0))));\n        _9471 = true;\n    }\n    vec3 _4993 = max(s.sheen_color, vec3(0.0));\n    float _5002 = max(_4993.x, max(_4993.y, _4993.z));\n    if (_5002 > 0.0)\n    {\n        float _5010 = clamp(s.sheen_roughness, 0.100000001490116119384765625, 1.0);\n        _9481 = true;\n        _9482 = _4993;\n        _9483 = _5010;\n        _9484 = _5010 * _5010;\n        float param = max(dot(n, v), 9.9999997473787516355514526367188e-05);\n        float param_1 = _5010;\n        float _5027 = fa_sheen_albedo(param, param_1);\n        _9486 = _5027;\n        _9485 = 1.0 - min(_5002 * _5027, 1.0);\n        _9471 = true;\n    }\n    _9474 = _9473 * _9485;\n    float _5046 = clamp(s.anisotropy, -1.0, 1.0);\n    if (_5046 != 0.0)\n    {\n        vec3 _5061 = i.world_tangent.xyz - (n * dot(n, i.world_tangent.xyz));\n        vec3 t = _5061;\n        if (dot(_5061, _5061) < 9.9999999392252902907785028219223e-09)\n        {\n            bvec3 _5073 = bvec3(abs(n.y) < 0.9900000095367431640625);\n            t = cross(vec3(_5073.x ? vec3(0.0, 1.0, 0.0).x : vec3(1.0, 0.0, 0.0).x, _5073.y ? vec3(0.0, 1.0, 0.0).y : vec3(1.0, 0.0, 0.0).y, _5073.z ? vec3(0.0, 1.0, 0.0).z : vec3(1.0, 0.0, 0.0).z), n);\n        }\n        vec3 _5077 = t;\n        vec3 _5078 = normalize(_5077);\n        t = _5078;\n        vec3 _5103 = normalize((_5078 * cos(s.anisotropy_rotation)) + ((cross(n, _5078) * ((i.world_tangent.w < 0.0) ? (-1.0) : 1.0)) * sin(s.anisotropy_rotation)));\n        _9488 = _5103;\n        _9489 = cross(n, _5103);\n        float _5113 = roughness * roughness;\n        float _5119 = mix(_5113, 1.0, _5046 * _5046);\n        bool _5121 = _5046 > 0.0;\n        _9490 = _5121 ? _5119 : _5113;\n        _9491 = _5121 ? _5113 : _5119;\n        _9487 = _5046;\n        _9471 = true;\n    }\n    return FaLayers(_9471, _9472, _9473, _9474, _9475, _9476, _9477, _9478, i.world_normal, _9480, _9481, _9482, _9483, _9484, _9485, _9486, _9487, _9488, _9489, _9490, _9491);\n}\n\nvec2 fa_atlas_size()\n{\n    return vec2(textureSize(fa_probe_atlas_fa_env_smp, 0));\n}\n\nvec3 fa_probe_sh_coef(vec2 origin, float res, int k)\n{\n    vec3 v = textureLod(fa_probe_atlas_fa_env_smp, (origin + vec2(float(k) + 0.5, res + 2.5)) / fa_atlas_size(), 0.0).xyz;\n    if (fa_mesh_fs_params[41].y > 0.5)\n    {\n        v = ((v * 255.0) - vec3(128.0)) * 0.03149606287479400634765625;\n    }\n    return v;\n}\n\nvec3 fa_sh_eval(vec3 c[9], vec3 n)\n{\n    vec3 _3914 = max((((c[0] * 0.2820948064327239990234375) + (((c[1] * (0.3257350027561187744140625 * n.y)) + (c[2] * (0.3257350027561187744140625 * n.z))) + (c[3] * (0.3257350027561187744140625 * n.x)))) + (((c[4] * ((0.2731371223926544189453125 * n.x) * n.y)) + (c[5] * ((0.2731371223926544189453125 * n.y) * n.z))) + (c[6] * (0.078847892582416534423828125 * (((3.0 * n.z) * n.z) - 1.0))))) + ((c[7] * ((0.2731371223926544189453125 * n.x) * n.z)) + (c[8] * (0.13656856119632720947265625 * ((n.x * n.x) - (n.y * n.y))))), vec3(0.0));\n    return _3914;\n}\n\nvec3 fa_ambient_light(vec3 n)\n{\n    float _4525 = (1.0 - fa_mesh_fs_params[42].w) - fa_mesh_fs_params[47].w;\n    vec3 amb = vec3(0.0);\n    bool _4530 = fa_mesh_fs_params[11].w > 0.5;\n    vec3 c[9];\n    for (int k = 0; k < 9; k++)\n    {\n        c[k] = vec3(0.0);\n    }\n    if (_4525 > 0.0005000000237487256526947021484375)\n    {\n        if (_4530)\n        {\n            for (int k_1 = 0; k_1 < 9; k_1++)\n            {\n                vec2 param = fa_mesh_fs_params[41].zw;\n                float param_1 = 128.0;\n                int param_2 = k_1;\n                c[k_1] = fa_probe_sh_coef(param, param_1, param_2) * _4525;\n            }\n        }\n        else\n        {\n            amb = fa_mesh_fs_params[1].xyz * _4525;\n        }\n    }\n    bool _4581 = fa_mesh_fs_params[42].w > 0.0;\n    if (_4581)\n    {\n        for (int k_2 = 0; k_2 < 9; k_2++)\n        {\n            vec2 param_3 = fa_mesh_fs_params[42].xy;\n            float param_4 = fa_mesh_fs_params[42].z;\n            int param_5 = k_2;\n            c[k_2] += (fa_probe_sh_coef(param_3, param_4, param_5) * fa_mesh_fs_params[42].w);\n        }\n    }\n    bool _4612 = fa_mesh_fs_params[47].w > 0.0;\n    if (_4612)\n    {\n        for (int k_3 = 0; k_3 < 9; k_3++)\n        {\n            vec2 param_6 = fa_mesh_fs_params[47].xy;\n            float param_7 = fa_mesh_fs_params[47].z;\n            int param_8 = k_3;\n            c[k_3] += (fa_probe_sh_coef(param_6, param_7, param_8) * fa_mesh_fs_params[47].w);\n        }\n    }\n    if ((_4530 || _4581) || _4612)\n    {\n        vec3 param_9[9] = c;\n        vec3 param_10 = n;\n        amb += fa_sh_eval(param_9, param_10);\n    }\n    return amb;\n}\n\nvec4 fa_gi_fetch(vec2 texel)\n{\n    return textureLod(fa_probe_atlas_fa_env_smp, texel / fa_atlas_size(), 0.0);\n}\n\nvec2 fa_oct_encode(vec3 d)\n{\n    vec3 _3934 = d / vec3(max((abs(d.x) + abs(d.y)) + abs(d.z), 9.9999999600419720025001879548654e-13));\n    float _3937 = _3934.x;\n    float _3939 = _3934.z;\n    vec2 e = vec2(_3937, _3939);\n    if (_3934.y < 0.0)\n    {\n        e = vec2((1.0 - abs(_3939)) * ((_3937 < 0.0) ? (-1.0) : 1.0), (1.0 - abs(_3937)) * ((_3939 < 0.0) ? (-1.0) : 1.0));\n    }\n    return e;\n}\n\nvec3 fa_gi_grid(int rec, vec3 n, vec3 v, out float cover)\n{\n    cover = 0.0;\n    int param = rec;\n    vec4 _7768 = fa_light_texel(param);\n    int param_1 = rec + 1;\n    vec4 _7773 = fa_light_texel(param_1);\n    int param_2 = rec + 2;\n    vec4 _7778 = fa_light_texel(param_2);\n    int param_3 = rec + 3;\n    vec4 _7783 = fa_light_texel(param_3);\n    bool _7786 = _7783.z < 0.5;\n    bool _7794;\n    if (!_7786)\n    {\n        _7794 = fa_atlas_size().y < 1155.0;\n    }\n    else\n    {\n        _7794 = _7786;\n    }\n    if (_7794)\n    {\n        return vec3(0.0);\n    }\n    float _7801 = max(_7768.w, 9.9999997473787516355514526367188e-05);\n    vec3 _7804 = _7773.xyz;\n    vec3 _7808 = _7768.xyz;\n    vec3 _7812 = (fa_world_pos - _7808) / vec3(_7801);\n    vec3 _7821 = min(_7812 + vec3(0.5), (_7804 - vec3(0.5)) - _7812);\n    float _7830 = min(_7821.x, min(_7821.y, _7821.z));\n    if (!(_7830 > 0.0))\n    {\n        return vec3(0.0);\n    }\n    vec3 _7845 = _7804 - vec3(1.0);\n    vec3 _7846 = clamp(_7812, vec3(0.0), _7845);\n    vec3 _7854 = min(floor(_7846), max(_7804 - vec3(2.0), vec3(0.0)));\n    vec3 _7858 = _7846 - _7854;\n    vec3 _7869 = fa_world_pos + (((n * 0.800000011920928955078125) + (v * 0.20000000298023223876953125)) * (0.20000000298023223876953125 * _7801));\n    int _7874 = int(_7778.y + 0.5);\n    float _7879 = 0.3257350027561187744140625 * n.y;\n    float _7883 = 0.3257350027561187744140625 * n.z;\n    float _7887 = 0.3257350027561187744140625 * n.x;\n    float _7894 = (0.2731371223926544189453125 * n.x) * n.y;\n    float _7901 = (0.2731371223926544189453125 * n.y) * n.z;\n    float _7910 = 0.078847892582416534423828125 * (((3.0 * n.z) * n.z) - 1.0);\n    float _7917 = (0.2731371223926544189453125 * n.x) * n.z;\n    float _7930 = 0.13656856119632720947265625 * ((n.x * n.x) - (n.y * n.y));\n    vec3 acc = vec3(0.0);\n    float wsum = 0.0;\n    int _7937 = 8 + int(_7783.w);\n    float _7964;\n    float _7977;\n    float _7991;\n    for (int k = 0; k < _7937; k++)\n    {\n        float _7950 = float(k & 1);\n        float _7954 = float((k >> 1) & 1);\n        float _7958 = float((k >> 2) & 1);\n        if (_7950 > 0.5)\n        {\n            _7964 = _7858.x;\n        }\n        else\n        {\n            _7964 = 1.0 - _7858.x;\n        }\n        if (_7954 > 0.5)\n        {\n            _7977 = _7858.y;\n        }\n        else\n        {\n            _7977 = 1.0 - _7858.y;\n        }\n        if (_7958 > 0.5)\n        {\n            _7991 = _7858.z;\n        }\n        else\n        {\n            _7991 = 1.0 - _7858.z;\n        }\n        float _8001 = (_7964 * _7977) * _7991;\n        if (!(_8001 > 0.0))\n        {\n            continue;\n        }\n        vec3 _8014 = min(_7854 + vec3(_7950, _7954, _7958), _7845);\n        int _8034 = int(((_7778.x + _8014.x) + (_7773.x * (_8014.y + (_7773.y * _8014.z)))) + 0.5);\n        vec2 _8049 = vec2(float(_8034 % _7874) * 10.0, 1024.0 + (float(_8034 / _7874) * 11.0));\n        vec2 param_4 = _8049 + vec2(9.5, 10.5);\n        vec4 _8057 = fa_gi_fetch(param_4);\n        bool _8060 = _8057.y < 0.5;\n        bool _8069;\n        if (!_8060)\n        {\n            _8069 = _8057.x > _7783.y;\n        }\n        else\n        {\n            _8069 = _8060;\n        }\n        if (_8069)\n        {\n            continue;\n        }\n        vec3 _8081 = _7869 - (_7808 + (_8014 * _7801));\n        float _8084 = length(_8081);\n        vec3 _8090 = _8081 / vec3(max(_8084, 9.9999997473787516355514526367188e-05));\n        float _8100 = max(9.9999997473787516355514526367188e-05, (dot(-_8090, n) + 1.0) * 0.5);\n        float w = _8001 * (_8100 * _8100);\n        vec3 param_5 = _8090;\n        vec2 param_6 = (_8049 + vec2(1.0)) + (((fa_oct_encode(param_5) * 0.5) + vec2(0.5)) * 8.0);\n        vec4 _8119 = fa_gi_fetch(param_6);\n        float _8126 = _8084 / max(_7778.z, 9.9999997473787516355514526367188e-05);\n        float _8129 = _8119.x;\n        if (_8126 > _8129)\n        {\n            float _8142 = max(_8119.y - (_8129 * _8129), 0.0);\n            float _8147 = _8126 - _8129;\n            float _8156 = _8142 / max(_8142 + (_8147 * _8147), 9.9999999600419720025001879548654e-13);\n            w *= ((_8156 * _8156) * _8156);\n        }\n        if (!(w > 0.0))\n        {\n            continue;\n        }\n        vec2 param_7 = _8049 + vec2(0.5, 10.5);\n        vec2 param_8 = _8049 + vec2(1.5, 10.5);\n        vec2 param_9 = _8049 + vec2(2.5, 10.5);\n        vec2 param_10 = _8049 + vec2(3.5, 10.5);\n        vec2 param_11 = _8049 + vec2(4.5, 10.5);\n        vec2 param_12 = _8049 + vec2(5.5, 10.5);\n        vec2 param_13 = _8049 + vec2(6.5, 10.5);\n        vec2 param_14 = _8049 + vec2(7.5, 10.5);\n        vec2 param_15 = _8049 + vec2(8.5, 10.5);\n        acc += ((((((((((fa_gi_fetch(param_7).xyz * 0.2820948064327239990234375) + (fa_gi_fetch(param_8).xyz * _7879)) + (fa_gi_fetch(param_9).xyz * _7883)) + (fa_gi_fetch(param_10).xyz * _7887)) + (fa_gi_fetch(param_11).xyz * _7894)) + (fa_gi_fetch(param_12).xyz * _7901)) + (fa_gi_fetch(param_13).xyz * _7910)) + (fa_gi_fetch(param_14).xyz * _7917)) + (fa_gi_fetch(param_15).xyz * _7930)) * w);\n        wsum += w;\n    }\n    if (!(wsum > 9.9999997473787516355514526367188e-06))\n    {\n        return vec3(0.0);\n    }\n    cover = smoothstep(0.0, 1.0, clamp(_7830 * 2.0, 0.0, 1.0)) * smoothstep(0.0, 0.0199999995529651641845703125, wsum);\n    float _8281;\n    if (fa_mesh_fs_params[52].z > 0.5)\n    {\n        _8281 = _7783.x;\n    }\n    else\n    {\n        _8281 = 1.0;\n    }\n    return max(acc / vec3(wsum), vec3(0.0)) * (_7778.w * _8281);\n}\n\nvec3 fa_gi_light(vec3 n, inout float left)\n{\n    left = 1.0;\n    vec3 acc = vec3(0.0);\n    vec3 _8305 = normalize(fa_mesh_fs_params[0].xyz - fa_world_pos);\n    int _8310 = int(fa_mesh_fs_params[52].x + 0.5);\n    int _8315 = int(fa_mesh_fs_params[52].y + 0.5);\n    float param_3;\n    for (int k = 0; (k < _8315) && (k < 8); k++)\n    {\n        int param = _8310 + (4 * k);\n        vec3 param_1 = n;\n        vec3 param_2 = _8305;\n        vec3 _8340 = fa_gi_grid(param, param_1, param_2, param_3);\n        float _8345 = param_3 * left;\n        acc += (_8340 * _8345);\n        left -= _8345;\n        if (left < 0.001000000047497451305389404296875)\n        {\n            left = 0.0;\n            break;\n        }\n    }\n    return acc;\n}\n\nvec3 fa_realtime_or_ambient(vec3 n)\n{\n    vec3 gi = vec3(0.0);\n    float left = 1.0;\n    if (fa_mesh_fs_params[52].y > 0.5)\n    {\n        vec3 param = n;\n        float param_1;\n        vec3 _8374 = fa_gi_light(param, param_1);\n        left = param_1;\n        gi = _8374;\n    }\n    if (left <= 0.0)\n    {\n        return gi;\n    }\n    vec3 param_2 = n;\n    return gi + (fa_ambient_light(param_2) * left);\n}\n\nvec3 fa_indirect_diffuse(vec3 n)\n{\n    if (fa_lm.z > 0.5)\n    {\n        return textureLod(fa_lightmap_fa_env_smp, fa_lm.xy, 0.0).xyz;\n    }\n    if (fa_mesh_fs_params[32].w > 0.0)\n    {\n        vec3 c[9];\n        for (int k = 0; k < 9; k++)\n        {\n            c[k] = fa_mesh_fs_params[k * 1 + 32].xyz;\n        }\n        vec3 param = n;\n        vec3 param_1[9] = c;\n        vec3 param_2 = n;\n        return mix(fa_ambient_light(param), fa_sh_eval(param_1, param_2), vec3(clamp(fa_mesh_fs_params[32].w, 0.0, 1.0)));\n    }\n    vec3 param_3 = n;\n    return fa_realtime_or_ambient(param_3);\n}\n\nint fa_cluster_index(int slot, int n)\n{\n    int param = (int(fa_mesh_fs_params[19].x) + int(fa_mesh_fs_params[19].w)) + ((slot + n) >> 2);\n    vec4 t = fa_light_texel(param);\n    return int(t[(slot + n) & 3]);\n}\n\nint fa_cl_light(int n)\n{\n    if (n < fa_cl_ndir)\n    {\n        return n;\n    }\n    int param = fa_cl_slot;\n    int param_1 = n - fa_cl_ndir;\n    return fa_cluster_index(param, param_1);\n}\n\nint fa_light_base(int li)\n{\n    return li * ((fa_mesh_fs_params[1].w > 4.5) ? 8 : 4);\n}\n\nbool fa_light_baked(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 3;\n    return fa_light_texel(param_1).w > 0.5;\n}\n\nfloat fa_baked_keep(int li)\n{\n    float _6256;\n    if (fa_lm.z > 0.5)\n    {\n        _6256 = 0.0;\n    }\n    else\n    {\n        _6256 = 1.0 - clamp(fa_mesh_fs_params[32].w, 0.0, 1.0);\n    }\n    bool _6267 = _6256 < 1.0;\n    bool _6273;\n    if (_6267)\n    {\n        int param = li;\n        _6273 = fa_light_baked(param);\n    }\n    else\n    {\n        _6273 = _6267;\n    }\n    return _6273 ? _6256 : 1.0;\n}\n\nfloat fa_light_type(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 1;\n    return fa_light_texel(param_1).w;\n}\n\nvec4 fa_atlas_fetch(vec2 texel)\n{\n    return textureLod(fa_light_atlas_fa_env_smp, texel / vec2(textureSize(fa_light_atlas_fa_env_smp, 0)), 0.0);\n}\n\nvec3 fa_cookie_sample(vec2 tile_origin, vec2 uv)\n{\n    vec2 param = (tile_origin + vec2(1.0)) + (clamp(uv, vec2(0.0), vec2(1.0)) * 254.0);\n    return fa_atlas_fetch(param).xyz;\n}\n\nvec3 fa_area_point(vec3 c, vec3 axis, vec3 ru, vec3 uu, float hx, float hy, float shape, vec3 p, vec3 r)\n{\n    bool _844 = dot(r, r) > 0.5;\n    if (shape > 1.5)\n    {\n        vec3 _857 = (c - (ru * hx)) - p;\n        vec3 _863 = ru * (2.0 * hx);\n        float _869 = max(dot(_863, _863), 9.9999999392252902907785028219223e-09);\n        float _873 = dot(_857, _863);\n        float t = clamp((-_873) / _869, 0.0, 1.0);\n        if (_844)\n        {\n            float _888 = dot(r, _863);\n            float _894 = _869 - (_888 * _888);\n            if (abs(_894) > (9.9999997473787516355514526367188e-06 * _869))\n            {\n                t = clamp(((dot(r, _857) * _888) - _873) / _894, 0.0, 1.0);\n            }\n        }\n        return (p + _857) + (_863 * t);\n    }\n    vec3 q = p;\n    float _926 = dot(r, axis);\n    bool _934;\n    if (_844)\n    {\n        _934 = abs(_926) > 9.9999997473787516355514526367188e-05;\n    }\n    else\n    {\n        _934 = _844;\n    }\n    if (_934)\n    {\n        float _944 = dot(c - p, axis) / _926;\n        if (_944 > 0.0)\n        {\n            q = p + (r * _944);\n        }\n    }\n    vec3 _957 = q - c;\n    vec2 xy = vec2(dot(_957, ru), dot(_957, uu));\n    if (shape > 0.5)\n    {\n        float _972 = length(xy);\n        if (_972 > hx)\n        {\n            xy *= (hx / _972);\n        }\n    }\n    else\n    {\n        xy = clamp(xy, vec2(-hx, -hy), vec2(hx, hy));\n    }\n    return (c + (ru * xy.x)) + (uu * xy.y);\n}\n\nint fa_cube_face(vec3 d)\n{\n    vec3 _605 = abs(d);\n    float _607 = _605.x;\n    float _609 = _605.y;\n    bool _610 = _607 >= _609;\n    bool _618;\n    if (_610)\n    {\n        _618 = _607 >= _605.z;\n    }\n    else\n    {\n        _618 = _610;\n    }\n    int _619;\n    if (_618)\n    {\n        _619 = (d.x > 0.0) ? 0 : 1;\n    }\n    else\n    {\n        int _634;\n        if (_609 >= _605.z)\n        {\n            _634 = (d.y > 0.0) ? 2 : 3;\n        }\n        else\n        {\n            _634 = (d.z > 0.0) ? 4 : 5;\n        }\n        _619 = _634;\n    }\n    return _619;\n}\n\nvoid fa_cube_face_basis(int f, out vec3 fwd, out vec3 up)\n{\n    if (f == 0)\n    {\n        fwd = vec3(1.0, 0.0, 0.0);\n        up = vec3(0.0, 1.0, 0.0);\n    }\n    else\n    {\n        if (f == 1)\n        {\n            fwd = vec3(-1.0, 0.0, 0.0);\n            up = vec3(0.0, 1.0, 0.0);\n        }\n        else\n        {\n            if (f == 2)\n            {\n                fwd = vec3(0.0, 1.0, 0.0);\n                up = vec3(0.0, 0.0, 1.0);\n            }\n            else\n            {\n                if (f == 3)\n                {\n                    fwd = vec3(0.0, -1.0, 0.0);\n                    up = vec3(0.0, 0.0, -1.0);\n                }\n                else\n                {\n                    if (f == 4)\n                    {\n                        fwd = vec3(0.0, 0.0, 1.0);\n                        up = vec3(0.0, 1.0, 0.0);\n                    }\n                    else\n                    {\n                        fwd = vec3(0.0, 0.0, -1.0);\n                        up = vec3(0.0, 1.0, 0.0);\n                    }\n                }\n            }\n        }\n    }\n}\n\nfloat fa_ies_sample(vec2 tile_origin, vec3 d, vec3 axis, vec3 right, vec3 up)\n{\n    float _764 = dot(d, right);\n    float _768 = dot(d, up);\n    float _779;\n    if (((_764 * _764) + (_768 * _768)) > 1.0000000133514319600180897396058e-10)\n    {\n        _779 = atan(_768, _764) * 0.15915493667125701904296875;\n    }\n    else\n    {\n        _779 = 0.0;\n    }\n    vec2 param = tile_origin + vec2(1.0 + ((_779 - floor(_779)) * 64.0), 1.0 + (acos(clamp(dot(d, axis), -1.0, 1.0)) * 10.18591594696044921875));\n    return fa_atlas_fetch(param).x;\n}\n\nLightSample fa_light_sample_n(int li, vec3 world_pos, vec3 n)\n{\n    int param = li;\n    int _1010 = fa_light_base(param);\n    bool _1014 = fa_mesh_fs_params[1].w > 4.5;\n    int param_1 = _1010;\n    vec4 _1018 = fa_light_texel(param_1);\n    int param_2 = _1010 + 1;\n    vec4 _1023 = fa_light_texel(param_2);\n    float _1026 = _1023.w;\n    float atten = 1.0;\n    float dist = 0.0;\n    fa_light_tint = vec3(1.0);\n    bool _1038 = _1014 && (_1026 > 2.5);\n    fa_light_is_area = _1038;\n    bool _1040 = _1026 < 0.5;\n    vec3 l;\n    if (_1040)\n    {\n        l = normalize(_1018.xyz);\n        if (_1014)\n        {\n            int param_3 = _1010 + 6;\n            vec4 _1054 = fa_light_texel(param_3);\n            if (_1054.z > 0.5)\n            {\n                int param_4 = _1010 + 4;\n                vec4 _1064 = fa_light_texel(param_4);\n                int param_5 = _1010 + 5;\n                vec4 _1069 = fa_light_texel(param_5);\n                vec2 param_6 = _1054.xy;\n                vec2 param_7 = fract(vec2(dot(world_pos, _1064.xyz) * _1064.w, (-dot(world_pos, _1069.xyz)) * _1069.w) + vec2(0.5));\n                fa_light_tint = fa_cookie_sample(param_6, param_7);\n            }\n        }\n    }\n    else\n    {\n        vec3 _1099 = _1018.xyz;\n        vec3 _1101 = _1099 - world_pos;\n        vec3 to_light = _1101;\n        float _1104 = length(_1101);\n        float reach = _1104;\n        bool front = true;\n        if (_1038)\n        {\n            int param_8 = _1010 + 7;\n            reach = max(_1104 - fa_light_texel(param_8).w, 0.0);\n            int param_9 = _1010 + 4;\n            vec4 _1128 = fa_light_texel(param_9);\n            int param_10 = _1010 + 5;\n            vec4 _1133 = fa_light_texel(param_10);\n            int param_11 = _1010 + 6;\n            vec4 _1138 = fa_light_texel(param_11);\n            float _1139 = _1138.w;\n            int param_12 = _1010 + 2;\n            vec3 _1146 = normalize(fa_light_texel(param_12).xyz);\n            bool _1148 = _1139 > 1.5;\n            bool _1156;\n            if (!_1148)\n            {\n                _1156 = dot(_1146, to_light) < 0.0;\n            }\n            else\n            {\n                _1156 = _1148;\n            }\n            front = _1156;\n            vec3 r = vec3(0.0);\n            vec3 _1165 = fa_mesh_fs_params[0].xyz - world_pos;\n            bool _1169 = dot(n, n) > 0.5;\n            bool _1177;\n            if (_1169)\n            {\n                _1177 = dot(_1165, _1165) > 9.9999999600419720025001879548654e-13;\n            }\n            else\n            {\n                _1177 = _1169;\n            }\n            if (_1177)\n            {\n                r = reflect(-normalize(_1165), normalize(n));\n            }\n            vec3 param_13 = _1099;\n            vec3 param_14 = _1146;\n            vec3 param_15 = _1128.xyz;\n            vec3 param_16 = _1133.xyz;\n            float param_17 = _1128.w;\n            float param_18 = _1133.w;\n            float param_19 = _1139;\n            vec3 param_20 = world_pos;\n            vec3 param_21 = r;\n            to_light = fa_area_point(param_13, param_14, param_15, param_16, param_17, param_18, param_19, param_20, param_21) - world_pos;\n        }\n        float _1213 = length(to_light);\n        dist = _1213;\n        l = to_light / vec3(max(_1213, 9.9999997473787516355514526367188e-05));\n        float _1227 = reach / max(_1018.w, 0.001000000047497451305389404296875);\n        float _1233 = clamp(1.0 - (_1227 * _1227), 0.0, 1.0);\n        float _1235;\n        if (front)\n        {\n            _1235 = _1233 * _1233;\n        }\n        else\n        {\n            _1235 = 0.0;\n        }\n        atten = _1235;\n        bool _1246 = _1026 < 2.5;\n        if ((_1026 > 1.5) && _1246)\n        {\n            int param_22 = _1010 + 2;\n            vec4 _1254 = fa_light_texel(param_22);\n            float _1264 = _1254.w;\n            int param_23 = _1010 + 3;\n            vec4 _1269 = fa_light_texel(param_23);\n            float _1270 = _1269.x;\n            float cos_inner = _1270;\n            if (_1270 > 1.5)\n            {\n                cos_inner = mix(_1264, 1.0, 0.25);\n            }\n            atten *= smoothstep(_1264, cos_inner, dot(-l, normalize(_1254.xyz)));\n        }\n        if (_1014 && (_1026 < 1.5))\n        {\n            int param_24 = _1010 + 6;\n            vec4 _1294 = fa_light_texel(param_24);\n            if (_1294.z > 0.5)\n            {\n                vec3 _1302 = -to_light;\n                int param_25 = _1010 + 4;\n                int param_26 = _1010 + 5;\n                vec3 _1316 = fa_light_texel(param_25).xyz;\n                vec3 _1320 = fa_light_texel(param_26).xyz;\n                vec3 _1329 = vec3(dot(_1302, _1316), dot(_1302, _1320), dot(_1302, cross(_1316, _1320)));\n                vec3 param_27 = _1329;\n                int _1333 = fa_cube_face(param_27);\n                int param_28 = _1333;\n                vec3 param_29;\n                vec3 param_30;\n                fa_cube_face_basis(param_28, param_29, param_30);\n                vec2 _1360 = vec2(dot(_1329, cross(param_29, param_30)), dot(_1329, param_30)) / vec2(max(dot(_1329, param_29), 9.9999997473787516355514526367188e-05));\n                int _1364 = _1333 / 3;\n                vec2 param_31 = _1294.xy + (vec2(float(_1333 - (_1364 * 3)), float(_1364)) * 256.0);\n                vec2 param_32 = vec2(0.5 + (0.5 * _1360.x), 0.5 - (0.5 * _1360.y));\n                fa_light_tint = fa_cookie_sample(param_31, param_32);\n            }\n            int param_33 = _1010 + 7;\n            vec4 _1394 = fa_light_texel(param_33);\n            if (_1394.z > 0.5)\n            {\n                int param_34 = _1010 + 2;\n                int param_35 = _1010 + 4;\n                int param_36 = _1010 + 5;\n                vec2 param_37 = _1394.xy;\n                vec3 param_38 = -l;\n                vec3 param_39 = normalize(fa_light_texel(param_34).xyz);\n                vec3 param_40 = fa_light_texel(param_35).xyz;\n                vec3 param_41 = fa_light_texel(param_36).xyz;\n                atten *= fa_ies_sample(param_37, param_38, param_39, param_40, param_41);\n            }\n        }\n        else\n        {\n            if (_1014 && _1246)\n            {\n                int param_42 = _1010 + 6;\n                vec4 _1441 = fa_light_texel(param_42);\n                int param_43 = _1010 + 7;\n                vec4 _1446 = fa_light_texel(param_43);\n                bool _1449 = _1441.z > 0.5;\n                bool _1456;\n                if (!_1449)\n                {\n                    _1456 = _1446.z > 0.5;\n                }\n                else\n                {\n                    _1456 = _1449;\n                }\n                if (_1456)\n                {\n                    int param_44 = _1010 + 2;\n                    vec4 _1463 = fa_light_texel(param_44);\n                    vec3 _1467 = normalize(_1463.xyz);\n                    int param_45 = _1010 + 4;\n                    vec4 _1472 = fa_light_texel(param_45);\n                    int param_46 = _1010 + 5;\n                    vec4 _1477 = fa_light_texel(param_46);\n                    if (_1449)\n                    {\n                        vec3 _1485 = -to_light;\n                        float _1492 = _1463.w;\n                        float _1508 = 0.5 / max(dot(_1485, _1467) * (sqrt(max(1.0 - (_1492 * _1492), 0.0)) / max(_1492, 0.001000000047497451305389404296875)), 9.9999997473787516355514526367188e-05);\n                        vec2 param_47 = _1441.xy;\n                        vec2 param_48 = vec2(0.5 + (dot(_1485, _1472.xyz) * _1508), 0.5 - (dot(_1485, _1477.xyz) * _1508));\n                        fa_light_tint = fa_cookie_sample(param_47, param_48);\n                    }\n                    if (_1446.z > 0.5)\n                    {\n                        vec2 param_49 = _1446.xy;\n                        vec3 param_50 = -l;\n                        vec3 param_51 = _1467;\n                        vec3 param_52 = _1472.xyz;\n                        vec3 param_53 = _1477.xyz;\n                        atten *= fa_ies_sample(param_49, param_50, param_51, param_52, param_53);\n                    }\n                }\n            }\n        }\n    }\n    vec3 _9459 = _1023.xyz * atten;\n    if (_1014)\n    {\n        _9459 *= fa_light_tint;\n    }\n    int _1577;\n    if (_1040)\n    {\n        _1577 = 0;\n    }\n    else\n    {\n        _1577 = ((_1026 > 1.5) && (_1026 < 2.5)) ? 2 : 1;\n    }\n    return LightSample(l, _9459, atten, 1.0, dist, _1577);\n}\n\nfloat fa_shadow_split_at(int i)\n{\n    float _2309;\n    if (i == 0)\n    {\n        _2309 = fa_shadows[24].x;\n    }\n    else\n    {\n        float _2325;\n        if (i == 1)\n        {\n            _2325 = fa_shadows[24].y;\n        }\n        else\n        {\n            float _2333;\n            if (i == 2)\n            {\n                _2333 = fa_shadows[24].z;\n            }\n            else\n            {\n                _2333 = fa_shadows[24].w;\n            }\n            _2325 = _2333;\n        }\n        _2309 = _2325;\n    }\n    return _2309;\n}\n\nfloat fa_shadow_depth(inout vec2 uv, vec4 rect)\n{\n    uv = clamp(uv, rect.xy, rect.zw);\n    return textureLod(fa_shadow_tex_fa_shadow_smp, uv, 0.0).x;\n}\n\nfloat fa_shadow_fetch(vec2 uv, vec4 rect, vec3 conv)\n{\n    vec2 param = uv;\n    vec4 param_1 = rect;\n    float _2366 = fa_shadow_depth(param, param_1);\n    float _2370;\n    if (conv.x < 0.5)\n    {\n        _2370 = _2366;\n    }\n    else\n    {\n        _2370 = (conv.y * conv.z) / (conv.z - (_2366 * (conv.z - conv.y)));\n    }\n    return _2370;\n}\n\nfloat fa_shadow_noise()\n{\n    return fract(52.98291778564453125 * fract(dot(gl_FragCoord.xy, vec2(0.067110560834407806396484375, 0.005837149918079376220703125))));\n}\n\nvec2 fa_shadow_vogel_turn(vec2 d)\n{\n    return vec2((d.x * (-0.737368881702423095703125)) - (d.y * 0.675490319728851318359375), (d.y * (-0.737368881702423095703125)) + (d.x * 0.675490319728851318359375));\n}\n\nfloat fa_shadow_filter(vec2 uv, vec4 rect, float zr, float texel_m, float unit, float reach, float plane, vec3 conv, int mode, float k)\n{\n    if (mode == 1)\n    {\n        vec2 param = uv;\n        vec4 param_1 = rect;\n        vec3 param_2 = conv;\n        return float(zr <= fa_shadow_fetch(param, param_1, param_2));\n    }\n    float _2416 = fa_shadow_noise() * 6.283185482025146484375;\n    vec2 _2422 = vec2(cos(_2416), sin(_2416));\n    vec2 dir = _2422;\n    float radius = 1.5;\n    if (mode == 2)\n    {\n        float _2431;\n        if (k < 0.0)\n        {\n            _2431 = (-k) / max(zr, 0.100000001490116119384765625);\n        }\n        else\n        {\n            _2431 = k;\n        }\n        float _2450 = clamp((_2431 * reach) / texel_m, 3.0, 12.0);\n        float sum = 0.0;\n        float cnt = 0.0;\n        for (int i = 0; i < 16; i++)\n        {\n            float _2469 = sqrt((float(i) + 0.5) * 0.0625) * _2450;\n            vec2 param_3 = uv + (dir * (fa_shadows[26].zw * _2469));\n            vec4 param_4 = rect;\n            vec3 param_5 = conv;\n            float _2483 = fa_shadow_fetch(param_3, param_4, param_5);\n            if (_2483 < (zr - (_2469 * plane)))\n            {\n                sum += _2483;\n                cnt += 1.0;\n            }\n            vec2 param_6 = dir;\n            dir = fa_shadow_vogel_turn(param_6);\n        }\n        if (cnt < 0.5)\n        {\n            return 1.0;\n        }\n        float _2511 = sum / cnt;\n        float _2521;\n        if (k < 0.0)\n        {\n            _2521 = (-k) / max(_2511, 0.0500000007450580596923828125);\n        }\n        else\n        {\n            _2521 = k;\n        }\n        radius = clamp(((max(zr - _2511, 0.0) * unit) * _2521) / texel_m, 1.5, 16.0);\n        dir = _2422;\n    }\n    float lit = 0.0;\n    int _2547 = (mode == 2) ? 24 : 16;\n    for (int i_1 = 0; i_1 < _2547; i_1++)\n    {\n        float _2566 = sqrt((float(i_1) + 0.5) / float(_2547)) * radius;\n        vec2 param_7 = uv + (dir * (fa_shadows[26].zw * _2566));\n        vec4 param_8 = rect;\n        vec3 param_9 = conv;\n        lit += float((zr - (_2566 * plane)) <= fa_shadow_fetch(param_7, param_8, param_9));\n        vec2 param_10 = dir;\n        dir = fa_shadow_vogel_turn(param_10);\n    }\n    return lit / float(_2547);\n}\n\nfloat fa_shadow_cascade(int ci, vec3 world, vec3 n, vec3 l)\n{\n    float _2612 = max(fa_shadows[ci * 1 + 20].y, 0.001000000047497451305389404296875);\n    float _2617 = clamp(dot(n, l), 0.0, 1.0);\n    float _2623 = sqrt(1.0 - (_2617 * _2617));\n    float _2631 = min(_2623 / max(_2617, 0.20000000298023223876953125), 4.0);\n    float _2636;\n    if (fa_shadows[26].y > 0.0)\n    {\n        _2636 = fa_shadows[26].y;\n    }\n    else\n    {\n        _2636 = 1.5 * fa_shadows[ci * 1 + 20].x;\n    }\n    vec4 _2661 = mat4(fa_shadows[ci * 4 + 0], fa_shadows[ci * 4 + 1], fa_shadows[ci * 4 + 2], fa_shadows[ci * 4 + 3]) * vec4(world + (n * (_2636 * _2623)), 1.0);\n    float _2668 = _2661.x;\n    bool _2671 = _2668 < fa_shadows[ci * 1 + 16].x;\n    bool _2680;\n    if (!_2671)\n    {\n        _2680 = _2668 > fa_shadows[ci * 1 + 16].z;\n    }\n    else\n    {\n        _2680 = _2671;\n    }\n    bool _2689;\n    if (!_2680)\n    {\n        _2689 = _2661.y < fa_shadows[ci * 1 + 16].y;\n    }\n    else\n    {\n        _2689 = _2680;\n    }\n    bool _2698;\n    if (!_2689)\n    {\n        _2698 = _2661.y > fa_shadows[ci * 1 + 16].w;\n    }\n    else\n    {\n        _2698 = _2689;\n    }\n    bool _2705;\n    if (!_2698)\n    {\n        _2705 = _2661.z > 1.0;\n    }\n    else\n    {\n        _2705 = _2698;\n    }\n    if (_2705)\n    {\n        return -1.0;\n    }\n    float _2713;\n    if (fa_shadows[26].x > 0.0)\n    {\n        _2713 = fa_shadows[26].x;\n    }\n    else\n    {\n        _2713 = 1.5 * fa_shadows[ci * 1 + 20].x;\n    }\n    vec2 param = _2661.xy;\n    vec4 param_1 = fa_shadows[ci * 1 + 16];\n    float param_2 = _2661.z - ((_2713 * (1.0 + (0.5 * _2631))) / _2612);\n    float param_3 = fa_shadows[ci * 1 + 20].x;\n    float param_4 = _2612;\n    float param_5 = _2612 * 0.25;\n    float param_6 = ((fa_shadows[ci * 1 + 20].x * min(_2631, 3.0)) * 0.5) / _2612;\n    vec3 param_7 = vec3(0.0);\n    int param_8 = int(fa_shadows[25].z + 0.5);\n    float param_9 = fa_shadows[25].w;\n    return fa_shadow_filter(param, param_1, param_2, param_3, param_4, param_5, param_6, param_7, param_8, param_9);\n}\n\nfloat fa_shadow_sun(vec3 world, vec3 n, vec3 l)\n{\n    if (fa_mesh_fs_params[5].z < 0.5)\n    {\n        return 1.0;\n    }\n    int _3091 = int(fa_shadows[25].x + 0.5);\n    if (_3091 < 1)\n    {\n        return 1.0;\n    }\n    float _3106 = dot(world - fa_shadows[27].xyz, fa_shadows[28].xyz);\n    int param = _3091 - 1;\n    if (_3106 > fa_shadow_split_at(param))\n    {\n        return 1.0;\n    }\n    int ci = 0;\n    bool _3118 = _3091 > 1;\n    bool _3125;\n    if (_3118)\n    {\n        _3125 = _3106 > fa_shadows[24].x;\n    }\n    else\n    {\n        _3125 = _3118;\n    }\n    if (_3125)\n    {\n        ci = 1;\n    }\n    bool _3129 = _3091 > 2;\n    bool _3136;\n    if (_3129)\n    {\n        _3136 = _3106 > fa_shadows[24].y;\n    }\n    else\n    {\n        _3136 = _3129;\n    }\n    if (_3136)\n    {\n        ci = 2;\n    }\n    bool _3140 = _3091 > 3;\n    bool _3147;\n    if (_3140)\n    {\n        _3147 = _3106 > fa_shadows[24].z;\n    }\n    else\n    {\n        _3147 = _3140;\n    }\n    if (_3147)\n    {\n        ci = 3;\n    }\n    float s = -1.0;\n    float s2 = -1.0;\n    float t = 0.0;\n    int _3158 = min(_3091, 4);\n    float _3199;\n    for (int c = ci; c < _3158; c++)\n    {\n        int param_1 = c;\n        vec3 param_2 = world;\n        vec3 param_3 = n;\n        vec3 param_4 = l;\n        float _3178 = fa_shadow_cascade(param_1, param_2, param_3, param_4);\n        if (s >= 0.0)\n        {\n            s2 = _3178;\n            break;\n        }\n        if (_3178 < 0.0)\n        {\n            continue;\n        }\n        s = _3178;\n        ci = c;\n        if (fa_shadows[25].y > 0.0)\n        {\n            if (ci > 0)\n            {\n                int param_5 = ci - 1;\n                _3199 = fa_shadow_split_at(param_5);\n            }\n            else\n            {\n                _3199 = fa_shadows[28].w;\n            }\n            int param_6 = ci;\n            float _3218 = fa_shadows[25].y * max(fa_shadow_split_at(param_6) - _3199, 9.9999997473787516355514526367188e-05);\n            int param_7 = ci;\n            t = clamp((_3106 - (fa_shadow_split_at(param_7) - _3218)) / _3218, 0.0, 1.0);\n        }\n        if (t <= 0.0)\n        {\n            break;\n        }\n    }\n    if (s < 0.0)\n    {\n        return 1.0;\n    }\n    if (t > 0.0)\n    {\n        float _3250;\n        if ((ci + 1) < _3091)\n        {\n            _3250 = (s2 < 0.0) ? s : s2;\n        }\n        else\n        {\n            _3250 = 1.0;\n        }\n        s = mix(s, _3250, t);\n    }\n    return s;\n}\n\nfloat fa_shadow_factor(vec3 n, vec3 l)\n{\n    bool _3355 = fa_mesh_fs_params[25].y > 0.5;\n    bool _3361;\n    if (_3355)\n    {\n        _3361 = fa_mesh_fs_params[5].z > 0.5;\n    }\n    else\n    {\n        _3361 = _3355;\n    }\n    if (_3361)\n    {\n        float _3375 = dot(fa_mesh_fs_params[29].xyz, fa_world_pos) + fa_mesh_fs_params[29].w;\n        float _3378 = fwidth(_3375);\n        vec4 _3388 = vec4(fa_world_pos, 1.0);\n        float _3394 = dot(fa_mesh_fs_params[28], _3388);\n        if (_3394 > 9.9999997473787516355514526367188e-05)\n        {\n            vec2 _3413 = vec2(dot(fa_mesh_fs_params[26], _3388), dot(fa_mesh_fs_params[27], _3388)) / vec2(_3394);\n            float _3418 = (_3413.x * 0.5) + 0.5;\n            float _3422;\n            if (fa_mesh_fs_params[24].y > 0.5)\n            {\n                _3422 = (_3413.y * 0.5) + 0.5;\n            }\n            else\n            {\n                _3422 = 0.5 - (_3413.y * 0.5);\n            }\n            bool _3438 = _3418 >= 0.0;\n            bool _3444;\n            if (_3438)\n            {\n                _3444 = _3418 < 1.0;\n            }\n            else\n            {\n                _3444 = _3438;\n            }\n            bool _3450;\n            if (_3444)\n            {\n                _3450 = _3422 >= 0.0;\n            }\n            else\n            {\n                _3450 = _3444;\n            }\n            bool _3456;\n            if (_3450)\n            {\n                _3456 = _3422 < 1.0;\n            }\n            else\n            {\n                _3456 = _3450;\n            }\n            if (_3456)\n            {\n                vec4 _3482 = texelFetch(fa_screen_tex_fa_shadow_smp, clamp(ivec2(vec2(_3418, _3422) * fa_mesh_fs_params[24].zw), ivec2(0), ivec2(fa_mesh_fs_params[24].zw) - ivec2(1)), 0);\n                bool _3485 = _3482.w > 0.5;\n                bool _3501;\n                if (_3485)\n                {\n                    _3501 = abs(_3375 - _3482.x) <= (((0.00200000009499490261077880859375 * _3375) + 0.00999999977648258209228515625) + min(1.5 * _3378, 0.100000001490116119384765625 * _3375));\n                }\n                else\n                {\n                    _3501 = _3485;\n                }\n                if (_3501)\n                {\n                    float _3507;\n                    if (fa_mesh_fs_params[25].z > 0.5)\n                    {\n                        vec3 param = fa_world_pos;\n                        vec3 param_1 = n;\n                        vec3 param_2 = l;\n                        _3507 = min(_3482.y, fa_shadow_sun(param, param_1, param_2));\n                    }\n                    else\n                    {\n                        _3507 = _3482.y;\n                    }\n                    return _3507;\n                }\n            }\n        }\n    }\n    vec3 param_3 = fa_world_pos;\n    vec3 param_4 = n;\n    vec3 param_5 = l;\n    return fa_shadow_sun(param_3, param_4, param_5);\n}\n\nfloat fa_shadow_local(int li, vec3 lpos, vec3 world, vec3 n, vec3 l)\n{\n    bool _2771 = fa_mesh_fs_params[5].z < 0.5;\n    bool _2778;\n    if (!_2771)\n    {\n        _2778 = fa_shadows[29].x < 0.5;\n    }\n    else\n    {\n        _2778 = _2771;\n    }\n    if (_2778)\n    {\n        return 1.0;\n    }\n    int param = (int(fa_shadows[29].x + 0.5) - 1) + li;\n    vec4 _2791 = fa_light_texel(param);\n    float _2792 = _2791.x;\n    if (_2792 < 0.0)\n    {\n        return 1.0;\n    }\n    int _2801 = int(_2792 + 0.5);\n    int param_1 = _2801;\n    vec4 _2805 = fa_light_texel(param_1);\n    int param_2 = _2801 + 1;\n    vec4 _2810 = fa_light_texel(param_2);\n    float fade = 1.0;\n    float _2813 = _2805.y;\n    if (_2813 > 0.0)\n    {\n        float _2830 = 1.0 - smoothstep(0.75 * _2813, _2813, length(world - fa_shadows[27].xyz));\n        fade = _2830;\n        if (_2830 <= 0.0)\n        {\n            return 1.0;\n        }\n    }\n    int face = 0;\n    if (_2805.x > 1.5)\n    {\n        vec3 param_3 = world - lpos;\n        face = fa_cube_face(param_3);\n    }\n    int _2854 = (_2801 + 2) + (face * 6);\n    int param_4 = _2854;\n    int param_5 = _2854 + 1;\n    int param_6 = _2854 + 3;\n    vec4 _2868 = fa_light_texel(param_6);\n    int param_7 = _2854 + 4;\n    vec4 _2873 = fa_light_texel(param_7);\n    int param_8 = _2854 + 5;\n    vec4 _2878 = fa_light_texel(param_8);\n    float _2890 = _2878.x * max(dot(_2868, vec4(world, 1.0)), 0.001000000047497451305389404296875);\n    float _2895 = clamp(dot(n, l), 0.0, 1.0);\n    float _2918 = clamp(dot(n, _2868.xyz), -1.0, 1.0);\n    float _2937 = min(sqrt(1.0 - (_2918 * _2918)) / max(abs(dot(n, world - lpos)) / max(dot(_2868, vec4(world, 1.0)), 0.001000000047497451305389404296875), 0.20000000298023223876953125), 4.0);\n    float _2940 = _2810.y;\n    float _2942;\n    if (_2940 > 0.0)\n    {\n        _2942 = _2940;\n    }\n    else\n    {\n        _2942 = 1.5 * _2890;\n    }\n    vec4 _2962 = vec4(world + (n * (_2942 * sqrt(1.0 - (_2895 * _2895)))), 1.0);\n    float _2966 = dot(_2868, _2962);\n    float _2969 = _2878.y;\n    if (_2966 < _2969)\n    {\n        return 1.0;\n    }\n    vec2 _2984 = vec2(dot(fa_light_texel(param_4), _2962), dot(fa_light_texel(param_5), _2962)) / vec2(_2966);\n    float _2986 = _2984.x;\n    bool _2989 = _2986 < _2873.x;\n    bool _2998;\n    if (!_2989)\n    {\n        _2998 = _2986 > _2873.z;\n    }\n    else\n    {\n        _2998 = _2989;\n    }\n    bool _3007;\n    if (!_2998)\n    {\n        _3007 = _2984.y < _2873.y;\n    }\n    else\n    {\n        _3007 = _2998;\n    }\n    bool _3016;\n    if (!_3007)\n    {\n        _3016 = _2984.y > _2873.w;\n    }\n    else\n    {\n        _3016 = _3007;\n    }\n    if (_3016)\n    {\n        return 1.0;\n    }\n    float _3022 = _2810.x;\n    float _3024;\n    if (_3022 > 0.0)\n    {\n        _3024 = _3022;\n    }\n    else\n    {\n        _3024 = 1.5 * _2890;\n    }\n    vec2 param_9 = _2984;\n    vec4 param_10 = _2873;\n    float param_11 = _2966 - (_3024 * (1.0 + (0.5 * _2937)));\n    float param_12 = _2890;\n    float param_13 = 1.0;\n    float param_14 = _2878.z * 0.25;\n    float param_15 = (_2890 * min(_2937, 3.0)) * 0.5;\n    vec3 param_16 = vec3(1.0, _2969, _2878.z);\n    int param_17 = int(_2805.z + 0.5);\n    float param_18 = _2805.w;\n    return mix(1.0, fa_shadow_filter(param_9, param_10, param_11, param_12, param_13, param_14, param_15, param_16, param_17, param_18), fade);\n}\n\nfloat fa_shadow_local_rt(int li, vec3 lpos, vec3 world, vec3 n, vec3 l)\n{\n    bool _3536 = fa_mesh_fs_params[25].w > 0.5;\n    bool _3542;\n    if (_3536)\n    {\n        _3542 = fa_mesh_fs_params[5].z > 0.5;\n    }\n    else\n    {\n        _3542 = _3536;\n    }\n    bool _3548;\n    if (_3542)\n    {\n        _3548 = fa_shadows[29].x > 0.5;\n    }\n    else\n    {\n        _3548 = _3542;\n    }\n    if (_3548)\n    {\n        int param = (int(fa_shadows[29].x + 0.5) - 1) + li;\n        vec4 _3560 = fa_light_texel(param);\n        float _3561 = _3560.z;\n        if (_3561 > 0.5)\n        {\n            float _3574 = dot(fa_mesh_fs_params[29].xyz, world) + fa_mesh_fs_params[29].w;\n            float _3577 = fwidth(_3574);\n            float _3581 = min(1.5 * _3577, 0.100000001490116119384765625 * _3574);\n            vec4 _3587 = vec4(world, 1.0);\n            float _3592 = dot(fa_mesh_fs_params[28], _3587);\n            if (_3592 > 9.9999997473787516355514526367188e-05)\n            {\n                vec2 _3609 = vec2(dot(fa_mesh_fs_params[26], _3587), dot(fa_mesh_fs_params[27], _3587)) / vec2(_3592);\n                float _3614 = (_3609.x * 0.5) + 0.5;\n                float _3618;\n                if (fa_mesh_fs_params[24].y > 0.5)\n                {\n                    _3618 = (_3609.y * 0.5) + 0.5;\n                }\n                else\n                {\n                    _3618 = 0.5 - (_3609.y * 0.5);\n                }\n                bool _3634 = _3614 >= 0.0;\n                bool _3640;\n                if (_3634)\n                {\n                    _3640 = _3614 < 1.0;\n                }\n                else\n                {\n                    _3640 = _3634;\n                }\n                bool _3646;\n                if (_3640)\n                {\n                    _3646 = _3618 >= 0.0;\n                }\n                else\n                {\n                    _3646 = _3640;\n                }\n                bool _3652;\n                if (_3646)\n                {\n                    _3652 = _3618 < 1.0;\n                }\n                else\n                {\n                    _3652 = _3646;\n                }\n                if (_3652)\n                {\n                    ivec2 _3669 = ivec2(fa_mesh_fs_params[24].zw) - ivec2(1);\n                    ivec2 _3670 = clamp(ivec2(vec2(_3614, _3618) * fa_mesh_fs_params[24].zw), ivec2(0), _3669);\n                    ivec2 _3682;\n                    ivec2 _3688;\n                    ivec2 _3695;\n                    float _3746;\n                    float _3767;\n                    for (int k = 0; k < 5; k++)\n                    {\n                        if (k == 0)\n                        {\n                            _3682 = ivec2(0);\n                        }\n                        else\n                        {\n                            if (k == 1)\n                            {\n                                _3688 = ivec2(1, 0);\n                            }\n                            else\n                            {\n                                if (k == 2)\n                                {\n                                    _3695 = ivec2(-1, 0);\n                                }\n                                else\n                                {\n                                    bvec2 _3706 = bvec2(k == 3);\n                                    _3695 = ivec2(_3706.x ? ivec2(0, 1).x : ivec2(0, -1).x, _3706.y ? ivec2(0, 1).y : ivec2(0, -1).y);\n                                }\n                                _3688 = _3695;\n                            }\n                            _3682 = _3688;\n                        }\n                        vec4 _3723 = texelFetch(fa_screen_tex_fa_shadow_smp, clamp(_3670 + _3682, ivec2(0), _3669), 0);\n                        bool _3726 = _3723.w > 0.5;\n                        bool _3740;\n                        if (_3726)\n                        {\n                            _3740 = abs(_3574 - _3723.x) <= (((0.00200000009499490261077880859375 * _3574) + 0.00999999977648258209228515625) + _3581);\n                        }\n                        else\n                        {\n                            _3740 = _3726;\n                        }\n                        if (_3740)\n                        {\n                            if (_3561 < 1.5)\n                            {\n                                _3746 = 1.0;\n                            }\n                            else\n                            {\n                                _3746 = (_3561 < 2.5) ? 256.0 : 65536.0;\n                            }\n                            float _3763 = mod(floor(_3723.z / _3746), 256.0) * 0.0039215688593685626983642578125;\n                            if (fa_mesh_fs_params[25].z > 0.5)\n                            {\n                                int param_1 = li;\n                                vec3 param_2 = lpos;\n                                vec3 param_3 = world;\n                                vec3 param_4 = n;\n                                vec3 param_5 = l;\n                                _3767 = min(_3763, fa_shadow_local(param_1, param_2, param_3, param_4, param_5));\n                            }\n                            else\n                            {\n                                _3767 = _3763;\n                            }\n                            return _3767;\n                        }\n                    }\n                }\n            }\n            float _3792;\n            if (fa_mesh_fs_params[25].z > 0.5)\n            {\n                int param_6 = li;\n                vec3 param_7 = lpos;\n                vec3 param_8 = world;\n                vec3 param_9 = n;\n                vec3 param_10 = l;\n                _3792 = fa_shadow_local(param_6, param_7, param_8, param_9, param_10);\n            }\n            else\n            {\n                _3792 = 1.0;\n            }\n            return _3792;\n        }\n    }\n    int param_11 = li;\n    vec3 param_12 = lpos;\n    vec3 param_13 = world;\n    vec3 param_14 = n;\n    vec3 param_15 = l;\n    return fa_shadow_local(param_11, param_12, param_13, param_14, param_15);\n}\n\nfloat fa_contact_shadow(int li, vec3 world, vec3 gn, vec3 l, float dist)\n{\n    bool _5637 = fa_mesh_fs_params[24].x < 0.5;\n    bool _5644;\n    if (!_5637)\n    {\n        _5644 = fa_shadows[29].x < 0.5;\n    }\n    else\n    {\n        _5644 = _5637;\n    }\n    if (_5644)\n    {\n        return 1.0;\n    }\n    int param = (int(fa_shadows[29].x + 0.5) - 1) + li;\n    vec4 _5657 = fa_light_texel(param);\n    float _5658 = _5657.y;\n    float len = _5658;\n    if (_5658 <= 0.0)\n    {\n        return 1.0;\n    }\n    float _5670 = length(world - fa_mesh_fs_params[0].xyz);\n    float _5679 = 1.0 - smoothstep(0.5 * fa_mesh_fs_params[25].x, fa_mesh_fs_params[25].x, _5670);\n    if (_5679 <= 0.0)\n    {\n        return 1.0;\n    }\n    float _5685 = len;\n    float _5688 = min(_5685, 0.89999997615814208984375 * dist);\n    len = _5688;\n    float _5693 = 0.004999999888241291046142578125 + (0.0030000000260770320892333984375 * _5670);\n    float _5698 = _5693 + (0.5 * _5688);\n    vec3 _5704 = world + (gn * _5693);\n    float _5706 = fa_shadow_noise();\n    float occ = 0.0;\n    float _5767;\n    for (int k = 0; k < 12; k++)\n    {\n        float _5721 = (float(k) + _5706) * 0.083333335816860198974609375;\n        vec3 _5729 = _5704 + (l * (_5721 * len));\n        vec4 _5735 = vec4(_5729, 1.0);\n        float _5740 = dot(fa_mesh_fs_params[28], _5735);\n        if (_5740 < 9.9999997473787516355514526367188e-05)\n        {\n            break;\n        }\n        vec2 _5758 = vec2(dot(fa_mesh_fs_params[26], _5735), dot(fa_mesh_fs_params[27], _5735)) / vec2(_5740);\n        float _5762 = _5758.x * 0.5;\n        float _5763 = _5762 + 0.5;\n        if (fa_mesh_fs_params[24].y > 0.5)\n        {\n            _5767 = (_5758.y * 0.5) + 0.5;\n        }\n        else\n        {\n            _5767 = 0.5 - (_5758.y * 0.5);\n        }\n        bool _5783 = _5763 < 0.0;\n        bool _5790;\n        if (!_5783)\n        {\n            _5790 = _5763 >= 1.0;\n        }\n        else\n        {\n            _5790 = _5783;\n        }\n        bool _5797;\n        if (!_5790)\n        {\n            _5797 = _5767 < 0.0;\n        }\n        else\n        {\n            _5797 = _5790;\n        }\n        bool _5804;\n        if (!_5797)\n        {\n            _5804 = _5767 >= 1.0;\n        }\n        else\n        {\n            _5804 = _5797;\n        }\n        if (_5804)\n        {\n            break;\n        }\n        vec4 _5828 = texelFetch(fa_screen_tex_fa_shadow_smp, clamp(ivec2(vec2(_5763, _5767) * fa_mesh_fs_params[24].zw), ivec2(0), ivec2(fa_mesh_fs_params[24].zw) - ivec2(1)), 0);\n        if (_5828.w < 0.5)\n        {\n            continue;\n        }\n        float _5846 = (dot(fa_mesh_fs_params[29].xyz, _5729) + fa_mesh_fs_params[29].w) - _5828.x;\n        if ((_5846 > _5693) && (_5846 < _5698))\n        {\n            occ = max(occ, (1.0 - (_5721 * _5721)) * smoothstep(0.0, 0.0500000007450580596923828125, min(min(_5763, 0.5 - _5762), min(_5767, 1.0 - _5767))));\n        }\n    }\n    return 1.0 - (occ * _5679);\n}\n\nLightSample fa_light_shadowed(int li, vec3 world_pos, vec3 gn)\n{\n    int param = li;\n    float _6312 = fa_baked_keep(param);\n    if (_6312 <= 0.0)\n    {\n        int param_1 = li;\n        return LightSample(vec3(0.0, 1.0, 0.0), vec3(0.0), 0.0, 1.0, 0.0, int(fa_light_type(param_1) + 0.5));\n    }\n    int param_2 = li;\n    vec3 param_3 = world_pos;\n    vec3 param_4 = gn;\n    LightSample _6338 = fa_light_sample_n(param_2, param_3, param_4);\n    vec3 _9528 = _6338.color;\n    float _9529 = _6338.attenuation;\n    float _9530 = _6338.shadow;\n    bool _6341 = _6338.type == 0;\n    if (_6341 && (li == 0))\n    {\n        vec3 param_5 = gn;\n        vec3 param_6 = _6338.direction;\n        float _6352 = fa_shadow_factor(param_5, param_6);\n        _9530 = _6352;\n        _9528 *= _6352;\n    }\n    else\n    {\n        bool _6363 = _6338.type != 0;\n        bool _6369;\n        if (_6363)\n        {\n            _6369 = _9529 > 0.0;\n        }\n        else\n        {\n            _6369 = _6363;\n        }\n        if (_6369)\n        {\n            int param_7 = li;\n            int param_8 = fa_light_base(param_7);\n            int param_9 = li;\n            vec3 param_10 = fa_light_texel(param_8).xyz;\n            vec3 param_11 = world_pos;\n            vec3 param_12 = gn;\n            vec3 param_13 = _6338.direction;\n            float _6388 = fa_shadow_local_rt(param_9, param_10, param_11, param_12, param_13);\n            _9530 = _6388;\n            _9528 *= _6388;\n        }\n    }\n    bool _6398 = fa_mesh_fs_params[24].x > 0.5;\n    bool _6404;\n    if (_6398)\n    {\n        _6404 = _9529 > 0.0;\n    }\n    else\n    {\n        _6404 = _6398;\n    }\n    if (_6404)\n    {\n        float _6411;\n        if (_6341)\n        {\n            _6411 = 1000000000.0;\n        }\n        else\n        {\n            _6411 = _6338._distance;\n        }\n        int param_14 = li;\n        vec3 param_15 = world_pos;\n        vec3 param_16 = gn;\n        vec3 param_17 = _6338.direction;\n        float param_18 = _6411;\n        float _6429 = fa_contact_shadow(param_14, param_15, param_16, param_17, param_18);\n        _9530 *= _6429;\n        _9528 *= _6429;\n    }\n    float _6442 = _9529;\n    float _6443 = _6442 * _6312;\n    _9529 = _6443;\n    vec3 _6447 = _9528;\n    vec3 _6448 = _6447 * _6312;\n    _9528 = _6448;\n    return LightSample(_6338.direction, _6448, _6443, _9530, _6338._distance, _6338.type);\n}\n\nvec3 fa_ltc_tangent(vec3 n, vec3 v)\n{\n    vec3 _6482 = v - (n * dot(v, n));\n    vec3 t = _6482;\n    float _6486 = dot(_6482, _6482);\n    float l2 = _6486;\n    if (_6486 < 1.0000000133514319600180897396058e-10)\n    {\n        vec3 _6496;\n        if (abs(n.z) < 0.999000012874603271484375)\n        {\n            _6496 = cross(n, vec3(0.0, 0.0, 1.0));\n        }\n        else\n        {\n            _6496 = cross(n, vec3(1.0, 0.0, 0.0));\n        }\n        t = _6496;\n        l2 = dot(_6496, _6496);\n    }\n    return t * inversesqrt(l2);\n}\n\nvec3 fa_ltc_local(vec3 t1, vec3 n, vec3 p)\n{\n    return vec3(dot(t1, p), dot(cross(n, t1), p), dot(n, p));\n}\n\nvec2 fa_ltc_uv(float roughness, float ndv)\n{\n    return ((vec2(clamp((roughness - 0.0500000007450580596923828125) * 1.0526316165924072265625, 0.0, 1.0), sqrt(clamp(1.0 - ndv, 0.0, 1.0))) * 63.0) + vec2(0.5)) * vec2(0.015625);\n}\n\nvec3 fa_oct_vertex(int j, vec3 pc, vec3 ex, vec3 ey)\n{\n    float _6883;\n    if ((j == 0) || (j == 7))\n    {\n        _6883 = 0.92387950420379638671875;\n    }\n    else\n    {\n        float _6893;\n        if ((j == 3) || (j == 4))\n        {\n            _6893 = -0.92387950420379638671875;\n        }\n        else\n        {\n            _6893 = ((j == 1) || (j == 6)) ? 0.3826834261417388916015625 : (-0.3826834261417388916015625);\n        }\n        _6883 = _6893;\n    }\n    float _6914;\n    if ((j == 1) || (j == 2))\n    {\n        _6914 = 0.92387950420379638671875;\n    }\n    else\n    {\n        float _6923;\n        if ((j == 5) || (j == 6))\n        {\n            _6923 = -0.92387950420379638671875;\n        }\n        else\n        {\n            _6923 = ((j == 0) || (j == 3)) ? 0.3826834261417388916015625 : (-0.3826834261417388916015625);\n        }\n        _6914 = _6923;\n    }\n    return (pc + (ex * _6883)) + (ey * _6914);\n}\n\nvec3 fa_ltc_edge_vector(vec3 a, vec3 b)\n{\n    float _6531 = dot(a, a);\n    float _6535 = dot(b, b);\n    if ((_6531 < 1.0000000195414813782625560981111e-24) || (_6535 < 1.0000000195414813782625560981111e-24))\n    {\n        return vec3(0.0);\n    }\n    vec3 _6549 = a * inversesqrt(_6531);\n    vec3 _6554 = b * inversesqrt(_6535);\n    float _6558 = dot(_6549, _6554);\n    float _6561 = abs(_6558);\n    float g = (((((((((((0.0416471660137176513671875 * _6561) - 0.1924748718738555908203125) * _6561) + 0.4179156124591827392578125) * _6561) - 0.616057217121124267578125) * _6561) + 0.777722418308258056640625) * _6561) - 0.999542415142059326171875) * _6561) + 1.570791721343994140625;\n    if (_6558 < 0.0)\n    {\n        g = (3.1415927410125732421875 * inversesqrt(max(1.0 - (_6558 * _6558), 1.0000000116860974230803549289703e-07))) - g;\n    }\n    return cross(_6549, _6554) * g;\n}\n\nvoid fa_ltc_clip_edge(vec3 a, vec3 b, inout vec3 sum, inout vec3 leave, inout vec3 enter, inout vec2 seen)\n{\n    bool _6618 = a.z > 0.0;\n    bool _6622 = b.z > 0.0;\n    if (_6618 && _6622)\n    {\n        vec3 param = a;\n        vec3 param_1 = b;\n        sum += fa_ltc_edge_vector(param, param_1);\n    }\n    else\n    {\n        if (_6618 != _6622)\n        {\n            vec3 _6657 = a + ((b - a) * (a.z / (a.z - b.z)));\n            _6657.z = 0.0;\n            if (_6618)\n            {\n                vec3 param_2 = a;\n                vec3 param_3 = _6657;\n                sum += fa_ltc_edge_vector(param_2, param_3);\n                leave = _6657;\n                seen.x = 1.0;\n            }\n            else\n            {\n                vec3 param_4 = _6657;\n                vec3 param_5 = b;\n                sum += fa_ltc_edge_vector(param_4, param_5);\n                enter = _6657;\n                seen.y = 1.0;\n            }\n        }\n    }\n}\n\nfloat fa_ltc_quad(vec4 abcd, vec3 p0, vec3 p1, vec3 p2, vec3 p3)\n{\n    vec3 _6706 = vec3((abcd.x * p0.x) + (abcd.y * p0.z), p0.y, (abcd.z * p0.x) + (abcd.w * p0.z));\n    vec3 _6732 = vec3((abcd.x * p1.x) + (abcd.y * p1.z), p1.y, (abcd.z * p1.x) + (abcd.w * p1.z));\n    vec3 _6758 = vec3((abcd.x * p2.x) + (abcd.y * p2.z), p2.y, (abcd.z * p2.x) + (abcd.w * p2.z));\n    vec3 _6784 = vec3((abcd.x * p3.x) + (abcd.y * p3.z), p3.y, (abcd.z * p3.x) + (abcd.w * p3.z));\n    vec3 sum = vec3(0.0);\n    vec3 leave = vec3(0.0);\n    vec3 enter = vec3(0.0);\n    vec3 param = _6706;\n    vec3 param_1 = _6732;\n    vec3 param_2 = vec3(0.0);\n    vec3 param_3 = vec3(0.0);\n    vec3 param_4 = vec3(0.0);\n    vec2 param_5 = vec2(0.0);\n    fa_ltc_clip_edge(param, param_1, param_2, param_3, param_4, param_5);\n    sum = param_2;\n    leave = param_3;\n    enter = param_4;\n    vec3 param_6 = _6732;\n    vec3 param_7 = _6758;\n    vec3 param_8 = param_2;\n    vec3 param_9 = param_3;\n    vec3 param_10 = param_4;\n    vec2 param_11 = param_5;\n    fa_ltc_clip_edge(param_6, param_7, param_8, param_9, param_10, param_11);\n    sum = param_8;\n    leave = param_9;\n    enter = param_10;\n    vec3 param_12 = _6758;\n    vec3 param_13 = _6784;\n    vec3 param_14 = param_8;\n    vec3 param_15 = param_9;\n    vec3 param_16 = param_10;\n    vec2 param_17 = param_11;\n    fa_ltc_clip_edge(param_12, param_13, param_14, param_15, param_16, param_17);\n    sum = param_14;\n    leave = param_15;\n    enter = param_16;\n    vec3 param_18 = _6784;\n    vec3 param_19 = _6706;\n    vec3 param_20 = param_14;\n    vec3 param_21 = param_15;\n    vec3 param_22 = param_16;\n    vec2 param_23 = param_17;\n    fa_ltc_clip_edge(param_18, param_19, param_20, param_21, param_22, param_23);\n    sum = param_20;\n    leave = param_21;\n    enter = param_22;\n    if ((param_23.x * param_23.y) > 0.5)\n    {\n        vec3 param_24 = leave;\n        vec3 param_25 = enter;\n        sum += fa_ltc_edge_vector(param_24, param_25);\n    }\n    return sum.z * 0.15915493667125701904296875;\n}\n\nvec2 fa_area_forms(vec4 m, float shape, vec3 pc, vec3 ex, vec3 ey)\n{\n    int _6952 = ((shape < 0.5) || (shape > 1.5)) ? 1 : 3;\n    vec2 sum = vec2(0.0);\n    int _6970;\n    for (int k = 0; k < (2 * _6952); k++)\n    {\n        bool _6967 = k >= _6952;\n        if (_6967)\n        {\n            _6970 = k - _6952;\n        }\n        else\n        {\n            _6970 = k;\n        }\n        vec3 p0 = (pc - ex) - ey;\n        vec3 p1 = (pc + ex) - ey;\n        vec3 p2 = (pc + ex) + ey;\n        vec3 p3 = (pc - ex) + ey;\n        if (_6952 == 3)\n        {\n            int param = 0;\n            vec3 param_1 = pc;\n            vec3 param_2 = ex;\n            vec3 param_3 = ey;\n            p0 = fa_oct_vertex(param, param_1, param_2, param_3);\n            int _7016 = 2 * _6970;\n            int param_4 = _7016 + 1;\n            vec3 param_5 = pc;\n            vec3 param_6 = ex;\n            vec3 param_7 = ey;\n            p1 = fa_oct_vertex(param_4, param_5, param_6, param_7);\n            int param_8 = _7016 + 2;\n            vec3 param_9 = pc;\n            vec3 param_10 = ex;\n            vec3 param_11 = ey;\n            p2 = fa_oct_vertex(param_8, param_9, param_10, param_11);\n            int param_12 = _7016 + 3;\n            vec3 param_13 = pc;\n            vec3 param_14 = ex;\n            vec3 param_15 = ey;\n            p3 = fa_oct_vertex(param_12, param_13, param_14, param_15);\n        }\n        bvec4 _7053 = bvec4(_6967);\n        vec4 param_16 = vec4(_7053.x ? m.x : vec4(1.0, 0.0, 0.0, 1.0).x, _7053.y ? m.y : vec4(1.0, 0.0, 0.0, 1.0).y, _7053.z ? m.z : vec4(1.0, 0.0, 0.0, 1.0).z, _7053.w ? m.w : vec4(1.0, 0.0, 0.0, 1.0).w);\n        vec3 param_17 = p0;\n        vec3 param_18 = p1;\n        vec3 param_19 = p2;\n        vec3 param_20 = p3;\n        float _7064 = fa_ltc_quad(param_16, param_17, param_18, param_19, param_20);\n        if (_6967)\n        {\n            vec2 _9776 = sum;\n            _9776.y = _9776.y + _7064;\n            sum = _9776;\n        }\n        else\n        {\n            vec2 _9779 = sum;\n            _9779.x = _9779.x + _7064;\n            sum = _9779;\n        }\n    }\n    return abs(sum);\n}\n\nvec3 fa_area_shade(int li, vec3 world_pos, vec3 n, vec3 v, vec3 diffuse_color, vec3 f0, float f90, float roughness, float ndv, float window)\n{\n    int param = li;\n    int _7088 = fa_light_base(param);\n    int param_1 = _7088;\n    int param_2 = _7088 + 1;\n    int param_3 = _7088 + 2;\n    int param_4 = _7088 + 4;\n    vec4 _7110 = fa_light_texel(param_4);\n    int param_5 = _7088 + 5;\n    vec4 _7115 = fa_light_texel(param_5);\n    int param_6 = _7088 + 6;\n    vec4 _7120 = fa_light_texel(param_6);\n    float _7121 = _7120.w;\n    vec3 _7126 = fa_light_texel(param_1).xyz - world_pos;\n    bool _7128 = _7121 < 1.5;\n    bool _7135;\n    if (_7128)\n    {\n        _7135 = dot(normalize(fa_light_texel(param_3).xyz), _7126) >= 0.0;\n    }\n    else\n    {\n        _7135 = _7128;\n    }\n    if (_7135)\n    {\n        return vec3(0.0);\n    }\n    bool _7144 = (_7121 > 0.5) && _7128;\n    float _7148 = _7144 ? 1.0539000034332275390625 : 1.0;\n    vec3 _7151 = _7110.xyz;\n    float _7153 = _7110.w;\n    vec3 _7159 = _7115.xyz;\n    float _7161 = _7115.w;\n    vec3 up = _7159 * (_7161 * _7148);\n    float _7167;\n    if (_7144)\n    {\n        _7167 = (3.1415927410125732421875 * _7153) * _7153;\n    }\n    else\n    {\n        _7167 = (4.0 * _7153) * _7161;\n    }\n    if (_7121 > 1.5)\n    {\n        vec3 _7193 = cross(_7151, -_7126);\n        vec3 perp = _7193;\n        float _7197 = dot(_7193, _7193);\n        vec3 _7200;\n        if (_7197 > 1.0000000133514319600180897396058e-10)\n        {\n            _7200 = perp * inversesqrt(_7197);\n        }\n        else\n        {\n            _7200 = _7159;\n        }\n        perp = _7200;\n        up = _7200 * _7161;\n    }\n    float _7221 = max(_7167, 9.9999999747524270787835121154785e-07);\n    vec3 param_7 = n;\n    vec3 param_8 = v;\n    vec3 _7231 = fa_ltc_tangent(param_7, param_8);\n    vec3 param_9 = _7231;\n    vec3 param_10 = n;\n    vec3 param_11 = _7126;\n    vec3 param_12 = _7231;\n    vec3 param_13 = n;\n    vec3 param_14 = _7151 * (_7153 * _7148);\n    vec3 param_15 = _7231;\n    vec3 param_16 = n;\n    vec3 param_17 = up;\n    float param_18 = roughness;\n    float param_19 = ndv;\n    vec2 _7262 = fa_ltc_uv(param_18, param_19) * 64.0;\n    vec2 param_20 = _7262;\n    vec2 param_21 = _7262 + vec2(64.0, 0.0);\n    vec4 _7272 = fa_atlas_fetch(param_21);\n    vec4 param_22 = fa_atlas_fetch(param_20);\n    float param_23 = _7121;\n    vec3 param_24 = fa_ltc_local(param_9, param_10, param_11);\n    vec3 param_25 = fa_ltc_local(param_12, param_13, param_14);\n    vec3 param_26 = fa_ltc_local(param_15, param_16, param_17);\n    vec2 _7284 = fa_area_forms(param_22, param_23, param_24, param_25, param_26);\n    return (((diffuse_color * _7284.x) + (((f0 * _7272.x) + ((vec3(f90) - f0) * _7272.y)) * _7284.y)) * fa_light_texel(param_2).xyz) * ((((3.1415927410125732421875 * dot(_7126, _7126)) + _7221) / _7221) * window);\n}\n\nvec3 fa_light_rgb(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 1;\n    return fa_light_texel(param_1).xyz;\n}\n\nfloat fa_d_charlie(float alpha, float ndh)\n{\n    float _5374 = 1.0 / alpha;\n    return ((2.0 + _5374) * pow(sqrt(max(1.0 - (ndh * ndh), 9.9999997473787516355514526367188e-05)), _5374)) * 0.15915493667125701904296875;\n}\n\nfloat fa_v_ashikhmin(float ndl, float ndv)\n{\n    return clamp(0.25 / max((ndl + ndv) - (ndl * ndv), 9.9999997473787516355514526367188e-05), 0.0, 1.0);\n}\n\nfloat fa_layers_coat(FaLayers L, vec3 l, vec3 h, float vdh)\n{\n    float _5409 = max(dot(L.nc, l), 0.0);\n    float _5415 = max(dot(L.nc, h), 0.0);\n    float _5424 = ((_5415 * _5415) * (L.coat_a2 - 1.0)) + 1.0;\n    return (((L.coat * (0.039999999105930328369140625 + (0.959999978542327880859375 * pow(clamp(1.0 - vdh, 0.0, 1.0), 5.0)))) * (((L.coat_a2 / ((3.1415927410125732421875 * _5424) * _5424)) * (0.5 / max(mix((2.0 * _5409) * L.coat_ndv, _5409 + L.coat_ndv, L.coat_alpha), 9.9999997473787516355514526367188e-05))) * 3.1415927410125732421875)) * step(9.9999997473787516355514526367188e-05, _5409)) * _5409;\n}\n\nvec3 fa_area_layers(FaLayers L, vec3 base, int li, vec3 n, vec3 v, vec3 l, float ndv, float window)\n{\n    float _7321;\n    if (L.sheen_on)\n    {\n        _7321 = L.sheen_scale;\n    }\n    else\n    {\n        _7321 = 1.0;\n    }\n    vec3 result = base * (L.keep * _7321);\n    vec3 _7334 = normalize(l + v);\n    int param = li;\n    vec3 _7345 = fa_light_rgb(param) * window;\n    if (L.sheen_on)\n    {\n        float _7354 = max(dot(n, l), 0.0);\n        float param_1 = L.sheen_alpha;\n        float param_2 = max(dot(n, _7334), 0.0);\n        float param_3 = _7354;\n        float param_4 = ndv;\n        result += ((L.sheen * _7345) * (((((fa_d_charlie(param_1, param_2) * fa_v_ashikhmin(param_3, param_4)) * 3.1415927410125732421875) * step(9.9999997473787516355514526367188e-05, _7354)) * _7354) * L.keep));\n    }\n    if (L.coat > 0.0)\n    {\n        FaLayers param_5 = L;\n        vec3 param_6 = l;\n        vec3 param_7 = _7334;\n        float param_8 = max(dot(v, _7334), 0.0);\n        result += (_7345 * fa_layers_coat(param_5, param_6, param_7, param_8));\n    }\n    return result;\n}\n\nfloat fa_d_ggx_aniso(float ndh, float tdh, float bdh, float at, float ab)\n{\n    float _5277 = tdh / at;\n    float _5281 = bdh / ab;\n    float _5293 = ((_5277 * _5277) + (_5281 * _5281)) + (ndh * ndh);\n    return 1.0 / ((((3.1415927410125732421875 * at) * ab) * _5293) * _5293);\n}\n\nfloat fa_lambda_ggx_aniso(float n, float t, float b, float at, float ab)\n{\n    return 0.5 * (sqrt(1.0 + (((((at * at) * t) * t) + (((ab * ab) * b) * b)) / max(n * n, 9.9999999392252902907785028219223e-09))) - 1.0);\n}\n\nfloat fa_v_ggx_aniso(float ndl, float ndv, float tdv, float bdv, float tdl, float bdl, float at, float ab)\n{\n    float param = ndv;\n    float param_1 = tdv;\n    float param_2 = bdv;\n    float param_3 = at;\n    float param_4 = ab;\n    float param_5 = ndl;\n    float param_6 = tdl;\n    float param_7 = bdl;\n    float param_8 = at;\n    float param_9 = ab;\n    return clamp(1.0 / ((4.0 * max(ndl * ndv, 9.9999997473787516355514526367188e-05)) * ((1.0 + fa_lambda_ggx_aniso(param, param_1, param_2, param_3, param_4)) + fa_lambda_ggx_aniso(param_5, param_6, param_7, param_8, param_9))), 0.0, 1.0);\n}\n\nvec3 fa_layers_light(FaLayers L, vec3 diffuse_color, vec3 f0, vec3 n, vec3 v, vec3 l, vec3 h, float ndl, float ndv, float ndh, float vdh, float alpha, float a2)\n{\n    float _5473 = step(9.9999997473787516355514526367188e-05, ndl);\n    float d_ggx;\n    float vis;\n    if (L.aniso != 0.0)\n    {\n        float param = ndh;\n        float param_1 = dot(L.t, h);\n        float param_2 = dot(L.b, h);\n        float param_3 = L.at;\n        float param_4 = L.ab;\n        d_ggx = fa_d_ggx_aniso(param, param_1, param_2, param_3, param_4);\n        float param_5 = ndl;\n        float param_6 = ndv;\n        float param_7 = dot(L.t, v);\n        float param_8 = dot(L.b, v);\n        float param_9 = dot(L.t, l);\n        float param_10 = dot(L.b, l);\n        float param_11 = L.at;\n        float param_12 = L.ab;\n        vis = fa_v_ggx_aniso(param_5, param_6, param_7, param_8, param_9, param_10, param_11, param_12);\n    }\n    else\n    {\n        float _5552 = ((ndh * ndh) * (a2 - 1.0)) + 1.0;\n        d_ggx = a2 / ((3.1415927410125732421875 * _5552) * _5552);\n        vis = 0.5 / max(mix((2.0 * ndl) * ndv, ndl + ndv, alpha), 9.9999997473787516355514526367188e-05);\n    }\n    vec3 base = diffuse_color + (((f0 + ((vec3(L.f90) - f0) * pow(clamp(1.0 - vdh, 0.0, 1.0), 5.0))) * ((d_ggx * vis) * 3.1415927410125732421875)) * _5473);\n    if (L.sheen_on)\n    {\n        float param_13 = L.sheen_alpha;\n        float param_14 = ndh;\n        float param_15 = ndl;\n        float param_16 = ndv;\n        base = (base * L.sheen_scale) + (L.sheen * (((fa_d_charlie(param_13, param_14) * fa_v_ashikhmin(param_15, param_16)) * 3.1415927410125732421875) * _5473));\n    }\n    vec3 result = base * (L.keep * ndl);\n    if (L.coat > 0.0)\n    {\n        FaLayers param_17 = L;\n        vec3 param_18 = l;\n        vec3 param_19 = h;\n        float param_20 = vdh;\n        result += vec3(fa_layers_coat(param_17, param_18, param_19, param_20));\n    }\n    return result;\n}\n\nvec2 fa_env_brdf(float rough, float ndv)\n{\n    vec4 _4676 = (vec4(-1.0, -0.0274999998509883880615234375, -0.572000026702880859375, 0.02199999988079071044921875) * rough) + vec4(1.0, 0.0425000004470348358154296875, 1.03999996185302734375, -0.039999999105930328369140625);\n    float _4679 = _4676.x;\n    return (vec2(-1.03999996185302734375, 1.03999996185302734375) * ((min(_4679 * _4679, exp2((-9.27999973297119140625) * ndv)) * _4679) + _4676.y)) + _4676.zw;\n}\n\nvec3 fa_probe_level(vec2 origin, float res, int lv, vec2 e)\n{\n    float _3986;\n    if (lv == 0)\n    {\n        _3986 = 0.0;\n    }\n    else\n    {\n        _3986 = res + 2.0;\n    }\n    float _3996;\n    if (lv == 0)\n    {\n        _3996 = 0.0;\n    }\n    else\n    {\n        _3996 = (res - (res / float(1 << max((lv - 1), 0)))) + (2.0 * float(lv - 1));\n    }\n    return textureLod(fa_probe_atlas_fa_env_smp, (((origin + vec2(_3986, _3996)) + vec2(1.0)) + (((e * 0.5) + vec2(0.5)) * (res / float(1 << lv)))) / fa_atlas_size(), 0.0).xyz;\n}\n\nvec3 fa_probe_radiance(vec2 origin, float res, vec3 d, float rough)\n{\n    float _4042;\n    if (res > 64.5)\n    {\n        _4042 = 5.0;\n    }\n    else\n    {\n        _4042 = (res > 32.5) ? 4.0 : 3.0;\n    }\n    float _4057 = clamp(rough, 0.0, 1.0) * (_4042 - 1.0);\n    int _4064 = int(min(floor(_4057), _4042 - 2.0));\n    float _4069 = _4057 - float(_4064);\n    vec3 param = d;\n    vec2 _4073 = fa_oct_encode(param);\n    vec2 param_1 = origin;\n    float param_2 = res;\n    int param_3 = _4064;\n    vec2 param_4 = _4073;\n    vec3 _4083 = fa_probe_level(param_1, param_2, param_3, param_4);\n    if (_4069 < 0.00200000009499490261077880859375)\n    {\n        return _4083;\n    }\n    vec2 param_5 = origin;\n    float param_6 = res;\n    int param_7 = _4064 + 1;\n    vec2 param_8 = _4073;\n    return mix(_4083, fa_probe_level(param_5, param_6, param_7, param_8), vec3(_4069));\n}\n\nvec3 fa_probe_box_dir(vec3 d, vec4 posw, vec4 bx, vec4 by, vec4 bz)\n{\n    if (posw.w < 0.5)\n    {\n        return d;\n    }\n    float _4154 = dot(bx.xyz, fa_world_pos) + bx.w;\n    float _4161 = dot(by.xyz, fa_world_pos) + by.w;\n    float _4168 = dot(bz.xyz, fa_world_pos) + bz.w;\n    float _4174 = dot(bx.xyz, d);\n    float _4178 = dot(by.xyz, d);\n    float _4182 = dot(bz.xyz, d);\n    float _4188;\n    if (_4174 > 9.9999999747524270787835121154785e-07)\n    {\n        _4188 = (1.0 - _4154) / _4174;\n    }\n    else\n    {\n        float _4202;\n        if (_4174 < (-9.9999999747524270787835121154785e-07))\n        {\n            _4202 = ((-1.0) - _4154) / _4174;\n        }\n        else\n        {\n            _4202 = 1000000015047466219876688855040.0;\n        }\n        _4188 = _4202;\n    }\n    float tx = _4188;\n    float _4219;\n    if (_4178 > 9.9999999747524270787835121154785e-07)\n    {\n        _4219 = (1.0 - _4161) / _4178;\n    }\n    else\n    {\n        float _4232;\n        if (_4178 < (-9.9999999747524270787835121154785e-07))\n        {\n            _4232 = ((-1.0) - _4161) / _4178;\n        }\n        else\n        {\n            _4232 = 1000000015047466219876688855040.0;\n        }\n        _4219 = _4232;\n    }\n    float ty = _4219;\n    float _4248;\n    if (_4182 > 9.9999999747524270787835121154785e-07)\n    {\n        _4248 = (1.0 - _4168) / _4182;\n    }\n    else\n    {\n        float _4261;\n        if (_4182 < (-9.9999999747524270787835121154785e-07))\n        {\n            _4261 = ((-1.0) - _4168) / _4182;\n        }\n        else\n        {\n            _4261 = 1000000015047466219876688855040.0;\n        }\n        _4248 = _4261;\n    }\n    float _4273 = tx;\n    float _4276 = (_4273 > 0.0) ? _4273 : 1000000015047466219876688855040.0;\n    tx = _4276;\n    float _4277 = ty;\n    float _4280 = (_4277 > 0.0) ? _4277 : 1000000015047466219876688855040.0;\n    ty = _4280;\n    float _4290 = min(_4276, min(_4280, (_4248 > 0.0) ? _4248 : 1000000015047466219876688855040.0));\n    if (_4290 > 100000001504746621987668885504.0)\n    {\n        return d;\n    }\n    vec3 _4306 = (fa_world_pos + (d * _4290)) - posw.xyz;\n    vec3 _4311;\n    if (dot(_4306, _4306) > 1.0000000133514319600180897396058e-10)\n    {\n        _4311 = normalize(_4306);\n    }\n    else\n    {\n        _4311 = d;\n    }\n    return _4311;\n}\n\nvec3 fa_probe_environment(vec4 tile, vec4 posw, vec4 bx, vec4 by, vec4 bz, inout vec3 d, float rough)\n{\n    vec3 param = d;\n    vec4 param_1 = posw;\n    vec4 param_2 = bx;\n    vec4 param_3 = by;\n    vec4 param_4 = bz;\n    d = fa_probe_box_dir(param, param_1, param_2, param_3, param_4);\n    vec2 param_5 = tile.xy;\n    float param_6 = tile.z;\n    vec3 param_7 = d;\n    float param_8 = rough;\n    return fa_probe_radiance(param_5, param_6, param_7, param_8);\n}\n\nvec3 fa_environment(vec3 d, float rough)\n{\n    float _4357 = (1.0 - fa_mesh_fs_params[42].w) - fa_mesh_fs_params[47].w;\n    vec3 outc = vec3(0.0);\n    if (_4357 > 0.0005000000237487256526947021484375)\n    {\n        vec3 base;\n        if (fa_mesh_fs_params[11].w > 0.5)\n        {\n            vec2 param = fa_mesh_fs_params[41].zw;\n            float param_1 = 128.0;\n            vec3 param_2 = d;\n            float param_3 = rough;\n            base = fa_probe_radiance(param, param_1, param_2, param_3);\n        }\n        else\n        {\n            float _4385 = rough * rough;\n            float _4416 = 0.60000002384185791015625 * _4385;\n            base = mix(mix(fa_mesh_fs_params[12].xyz * 0.550000011920928955078125, mix(fa_mesh_fs_params[12].xyz, fa_mesh_fs_params[11].xyz, vec3(pow(clamp(d.y * (1.0 - (0.699999988079071044921875 * _4385)), 0.0, 1.0), 0.550000011920928955078125))), vec3(smoothstep((-0.0500000007450580596923828125) - _4416, 0.0500000007450580596923828125 + _4416, d.y))), ((fa_mesh_fs_params[11].xyz + fa_mesh_fs_params[12].xyz) * 0.5) * 0.800000011920928955078125, vec3(_4385 * 0.60000002384185791015625));\n        }\n        outc = base * _4357;\n    }\n    if (fa_mesh_fs_params[42].w > 0.0)\n    {\n        vec4 param_4 = fa_mesh_fs_params[42];\n        vec4 param_5 = fa_mesh_fs_params[43];\n        vec4 param_6 = fa_mesh_fs_params[44];\n        vec4 param_7 = fa_mesh_fs_params[45];\n        vec4 param_8 = fa_mesh_fs_params[46];\n        vec3 param_9 = d;\n        float param_10 = rough;\n        vec3 _4475 = fa_probe_environment(param_4, param_5, param_6, param_7, param_8, param_9, param_10);\n        outc += (_4475 * fa_mesh_fs_params[42].w);\n    }\n    if (fa_mesh_fs_params[47].w > 0.0)\n    {\n        vec4 param_11 = fa_mesh_fs_params[47];\n        vec4 param_12 = fa_mesh_fs_params[48];\n        vec4 param_13 = fa_mesh_fs_params[49];\n        vec4 param_14 = fa_mesh_fs_params[50];\n        vec4 param_15 = fa_mesh_fs_params[51];\n        vec3 param_16 = d;\n        float param_17 = rough;\n        vec3 _4507 = fa_probe_environment(param_11, param_12, param_13, param_14, param_15, param_16, param_17);\n        outc += (_4507 * fa_mesh_fs_params[47].w);\n    }\n    return outc;\n}\n\nvec3 fa_layers_ibl(FaLayers L, vec3 n, vec3 v, vec3 f0, float roughness, float occlusion)\n{\n    vec3 rn = n;\n    if (L.aniso != 0.0)\n    {\n        vec3 _5154;\n        if (L.aniso >= 0.0)\n        {\n            _5154 = L.b;\n        }\n        else\n        {\n            _5154 = L.t;\n        }\n        rn = normalize(mix(n, cross(cross(_5154, v), _5154), vec3(abs(L.aniso) * smoothstep(0.0, 0.25, roughness))));\n    }\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05);\n    vec2 _5190 = fa_env_brdf(param, param_1);\n    vec3 param_2 = reflect(-v, rn);\n    float param_3 = roughness;\n    vec3 result = (fa_environment(param_2, param_3) * ((f0 * _5190.x) + (vec3(L.f90) * _5190.y))) * L.base_scale;\n    if (L.sheen_on)\n    {\n        vec3 param_4 = n;\n        float param_5 = L.sheen_rough;\n        result += ((L.sheen * (L.sheen_e * L.keep)) * fa_environment(param_4, param_5));\n    }\n    result *= occlusion;\n    if (L.coat > 0.0)\n    {\n        float param_6 = L.coat_rough;\n        float param_7 = L.coat_ndv;\n        vec2 _5248 = fa_env_brdf(param_6, param_7);\n        vec3 param_8 = reflect(-v, L.nc);\n        float param_9 = L.coat_rough;\n        result += (fa_environment(param_8, param_9) * (L.coat * ((0.039999999105930328369140625 * _5248.x) + _5248.y)));\n    }\n    return result;\n}\n\nvec3 fa_sky_reflection(vec3 n, vec3 v, vec3 f0, float roughness)\n{\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05);\n    vec2 _4718 = fa_env_brdf(param, param_1);\n    vec3 param_2 = reflect(-v, n);\n    float param_3 = roughness;\n    return fa_environment(param_2, param_3) * ((f0 * _4718.x) + vec3(_4718.y));\n}\n\nvec2 fa_xm_size(int k)\n{\n    return max(floor(fa_mesh_fs_params[24].zw / vec2(float(1 << k))), vec2(1.0));\n}\n\nvec2 fa_xm_origin(int k)\n{\n    if (k == 0)\n    {\n        return vec2(0.0);\n    }\n    float y = 0.0;\n    for (int j = 1; j < k; j++)\n    {\n        int param = j;\n        y += fa_xm_size(param).y;\n    }\n    return vec2(fa_mesh_fs_params[24].z, y);\n}\n\nvec3 fa_xm_texel(vec2 size, vec2 origin, vec2 p)\n{\n    return texelFetch(fa_screen_tex_fa_shadow_smp, ivec2(origin + clamp(p, vec2(0.0), size - vec2(1.0))), 0).xyz;\n}\n\nvec3 fa_xm_level(int k, vec2 uv)\n{\n    int param = k;\n    vec2 _5950 = fa_xm_size(param);\n    int param_1 = k;\n    vec2 _5954 = fa_xm_origin(param_1);\n    vec2 _5960 = (uv * _5950) - vec2(0.5);\n    vec2 _5963 = fract(_5960);\n    vec2 _5966 = floor(_5960);\n    vec2 param_2 = _5950;\n    vec2 param_3 = _5954;\n    vec2 param_4 = _5966;\n    vec2 param_5 = _5950;\n    vec2 param_6 = _5954;\n    vec2 param_7 = _5966 + vec2(1.0, 0.0);\n    vec2 param_8 = _5950;\n    vec2 param_9 = _5954;\n    vec2 param_10 = _5966 + vec2(0.0, 1.0);\n    vec2 param_11 = _5950;\n    vec2 param_12 = _5954;\n    vec2 param_13 = _5966 + vec2(1.0);\n    vec3 _6008 = vec3(_5963.x);\n    return mix(mix(fa_xm_texel(param_2, param_3, param_4), fa_xm_texel(param_5, param_6, param_7), _6008), mix(fa_xm_texel(param_8, param_9, param_10), fa_xm_texel(param_11, param_12, param_13), _6008), vec3(_5963.y));\n}\n\nvec3 fa_xm_sample(vec2 uv, float lod)\n{\n    float _6027 = max(fa_mesh_fs_params[31].w - 1.0, 0.0);\n    float _6031 = clamp(lod, 0.0, _6027);\n    int _6035 = int(floor(_6031));\n    int param = _6035;\n    vec2 param_1 = uv;\n    vec3 c = fa_xm_level(param, param_1);\n    float _6045 = float(_6035);\n    float _6046 = _6031 - _6045;\n    bool _6048 = _6046 > 0.001000000047497451305389404296875;\n    bool _6055;\n    if (_6048)\n    {\n        _6055 = _6045 < _6027;\n    }\n    else\n    {\n        _6055 = _6048;\n    }\n    if (_6055)\n    {\n        int param_2 = _6035 + 1;\n        vec2 param_3 = uv;\n        c = mix(c, fa_xm_level(param_2, param_3), vec3(_6046));\n    }\n    return c;\n}\n\nvec3 fa_transmitted(Surface s, vec3 n, vec3 v, float roughness, vec3 f0, float f90, float keep, float tr, inout float blend)\n{\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05);\n    vec2 _6081 = fa_env_brdf(param, param_1);\n    vec3 through = ((vec3(1.0) - clamp((f0 * _6081.x) + (vec3(f90) * _6081.y), vec3(0.0), vec3(1.0))) * s.albedo) * (tr * keep);\n    float _6109 = max(s.thickness, 0.0);\n    bool _6114 = _6109 > 0.0;\n    if ((s.attenuation_distance > 0.0) && _6114)\n    {\n        through *= exp((-((-log(clamp(s.attenuation_color, vec3(9.9999997473787516355514526367188e-05), vec3(1.0)))) / vec3(s.attenuation_distance))) * _6109);\n    }\n    bool _6139 = fa_mesh_fs_params[30].w > 1.5;\n    bool _6146;\n    if (!_6139)\n    {\n        _6146 = fa_mesh_fs_params[30].w < 0.5;\n    }\n    else\n    {\n        _6146 = _6139;\n    }\n    if (_6146)\n    {\n        blend = clamp(dot(through, vec3(0.3333333432674407958984375)), 0.0, 0.980000019073486328125);\n        return vec3(0.0);\n    }\n    vec3 world = fa_world_pos;\n    if (_6114)\n    {\n        world += (refract(-v, n, 1.0 / max(s.ior, 1.0)) * _6109);\n    }\n    vec4 _6181 = vec4(world, 1.0);\n    float _6186 = dot(fa_mesh_fs_params[28], _6181);\n    vec2 uv = vec2(0.5);\n    if (_6186 > 9.9999997473787516355514526367188e-05)\n    {\n        vec2 _6204 = vec2(dot(fa_mesh_fs_params[26], _6181), dot(fa_mesh_fs_params[27], _6181)) / vec2(_6186);\n        float _6212;\n        if (fa_mesh_fs_params[24].y > 0.5)\n        {\n            _6212 = (_6204.y * 0.5) + 0.5;\n        }\n        else\n        {\n            _6212 = 0.5 - (_6204.y * 0.5);\n        }\n        uv = vec2((_6204.x * 0.5) + 0.5, _6212);\n    }\n    vec2 param_2 = clamp(uv, vec2(0.0), vec2(1.0));\n    float param_3 = (clamp(roughness, 0.0, 1.0) * clamp((2.0 * s.ior) - 2.0, 0.0, 1.0)) * max(fa_mesh_fs_params[31].w - 1.0, 0.0);\n    return through * fa_xm_sample(param_2, param_3);\n}\n\nvec3 fa_shadow_debug(vec3 color, vec3 world)\n{\n    if (fa_shadows[27].w < 0.5)\n    {\n        return color;\n    }\n    int _3278 = int(fa_shadows[25].x + 0.5);\n    float _3288 = dot(world - fa_shadows[27].xyz, fa_shadows[28].xyz);\n    vec3 tint = vec3(0.3499999940395355224609375);\n    bool _3293 = _3278 > 0;\n    bool _3302;\n    if (_3293)\n    {\n        int param = _3278 - 1;\n        _3302 = _3288 <= fa_shadow_split_at(param);\n    }\n    else\n    {\n        _3302 = _3293;\n    }\n    if (_3302)\n    {\n        tint = vec3(1.0, 0.1500000059604644775390625, 0.100000001490116119384765625);\n        bool _3308 = _3278 > 1;\n        bool _3315;\n        if (_3308)\n        {\n            _3315 = _3288 > fa_shadows[24].x;\n        }\n        else\n        {\n            _3315 = _3308;\n        }\n        if (_3315)\n        {\n            tint = vec3(0.100000001490116119384765625, 0.89999997615814208984375, 0.20000000298023223876953125);\n        }\n        bool _3321 = _3278 > 2;\n        bool _3328;\n        if (_3321)\n        {\n            _3328 = _3288 > fa_shadows[24].y;\n        }\n        else\n        {\n            _3328 = _3321;\n        }\n        if (_3328)\n        {\n            tint = vec3(0.1500000059604644775390625, 0.300000011920928955078125, 1.0);\n        }\n        bool _3334 = _3278 > 3;\n        bool _3341;\n        if (_3334)\n        {\n            _3341 = _3288 > fa_shadows[24].z;\n        }\n        else\n        {\n            _3341 = _3334;\n        }\n        if (_3341)\n        {\n            tint = vec3(1.0, 0.89999997615814208984375, 0.100000001490116119384765625);\n        }\n    }\n    return mix(color, tint, vec3(0.550000011920928955078125));\n}\n\nvoid main()\n{\n    fa_inst_load();\n    vec3 _9187 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _9187 = -_9187;\n    }\n    vec3 _8482 = normalize(fa_mesh_fs_params[0].xyz - fa_world_pos);\n    vec3 param = fa_world_pos;\n    fa_cluster_begin(param);\n    SurfaceInput param_1 = SurfaceInput(fa_world_pos, _9187, fa_world_tangent, fa_uv, fa_vertex_color, _8482, gl_FrontFacing);\n    Surface _8490 = fa_standard_surface(param_1);\n    vec3 _9218 = _8490.albedo;\n    float _9219 = _8490.alpha;\n    vec3 _9220 = _8490.normal;\n    float _9221 = _8490.metallic;\n    float _9222 = _8490.roughness;\n    float _9223 = _8490.occlusion;\n    vec3 _9224 = _8490.emission;\n    float _9225 = _8490.clearcoat;\n    float _9226 = _8490.clearcoat_roughness;\n    vec3 _9227 = _8490.sheen_color;\n    float _9228 = _8490.sheen_roughness;\n    float _9229 = _8490.anisotropy;\n    float _9230 = _8490.anisotropy_rotation;\n    float _9231 = _8490.specular;\n    float _9232 = _8490.ior;\n    vec3 _9233 = _8490.specular_color;\n    float _9234 = _8490.transmission;\n    float _9235 = _8490.thickness;\n    vec3 _9236 = _8490.attenuation_color;\n    float _9237 = _8490.attenuation_distance;\n    SurfaceInput param_2 = SurfaceInput(fa_world_pos, _9187, fa_world_tangent, fa_uv, fa_vertex_color, _8482, gl_FrontFacing);\n    Surface param_3 = _8490;\n    surface(param_2, param_3);\n    _9218 = param_3.albedo;\n    _9219 = param_3.alpha;\n    _9220 = param_3.normal;\n    _9221 = param_3.metallic;\n    _9222 = param_3.roughness;\n    _9223 = param_3.occlusion;\n    _9224 = param_3.emission;\n    _9225 = param_3.clearcoat;\n    _9226 = param_3.clearcoat_roughness;\n    _9227 = param_3.sheen_color;\n    _9228 = param_3.sheen_roughness;\n    _9229 = param_3.anisotropy;\n    _9230 = param_3.anisotropy_rotation;\n    _9231 = param_3.specular;\n    _9232 = param_3.ior;\n    _9233 = param_3.specular_color;\n    _9234 = param_3.transmission;\n    _9235 = param_3.thickness;\n    _9236 = param_3.attenuation_color;\n    _9237 = param_3.attenuation_distance;\n    vec3 param_4 = fa_world_pos;\n    vec3 param_5 = _9187;\n    vec3 param_6 = param_3.albedo;\n    vec3 param_7 = param_3.normal;\n    fa_apply_decals(param_4, param_5, param_6, param_7);\n    _9218 = param_6;\n    _9220 = param_7;\n    float fa_tr_blend = 0.0;\n    vec3 result;\n    if (fa_mesh_fs_params[3].w > 0.5)\n    {\n        result = _9218;\n    }\n    else\n    {\n        vec3 _8530 = normalize(_9220);\n        float _8537 = clamp(_9221, 0.0, 1.0);\n        float _8541 = clamp(_9222, 0.0500000007450580596923828125, 1.0);\n        float _8545 = _8541 * _8541;\n        float _8549 = _8545 * _8545;\n        float _8554 = max(dot(_8530, _8482), 9.9999997473787516355514526367188e-05);\n        float _8560 = 1.0 - _8537;\n        float _8561 = clamp(_9234, 0.0, 1.0) * _8560;\n        vec3 _8570 = (_9218 * _8560) * (1.0 - _8561);\n        vec3 _8577 = mix(vec3(0.039999999105930328369140625), _9218, vec3(_8537));\n        vec3 f0 = _8577;\n        SurfaceInput param_8 = SurfaceInput(fa_world_pos, _9187, fa_world_tangent, fa_uv, fa_vertex_color, _8482, gl_FrontFacing);\n        Surface param_9 = Surface(_9218, _9219, _9220, _9221, _9222, _9223, _9224, _9225, _9226, _9227, _9228, _9229, _9230, _9231, _9232, _9233, _9234, _9235, _9236, _9237);\n        vec3 param_10 = _8530;\n        vec3 param_11 = _8482;\n        float param_12 = _8537;\n        float param_13 = _8541;\n        vec3 param_14 = _8577;\n        FaLayers _8593 = fa_layers_setup(param_8, param_9, param_10, param_11, param_12, param_13, param_14);\n        f0 = param_14;\n        vec3 param_15 = _8530;\n        vec3 lit = (fa_indirect_diffuse(param_15) * _8570) * _9223;\n        if (_8593.on)\n        {\n            lit *= _8593.base_scale;\n        }\n        int _8615 = fa_cl_ndir + fa_cl_local;\n        float _8680;\n        for (int ln = 0; ln < _8615; ln++)\n        {\n            int param_16 = ln;\n            int _8628 = fa_cl_light(param_16);\n            int param_17 = _8628;\n            if (fa_baked_keep(param_17) <= 0.0)\n            {\n                continue;\n            }\n            int param_18 = _8628;\n            vec3 param_19 = fa_world_pos;\n            vec3 param_20 = _9187;\n            LightSample _8644 = fa_light_shadowed(param_18, param_19, param_20);\n            float _8652 = max(dot(_8530, _8644.direction), 0.0);\n            float _8658 = _8644.attenuation * _8644.shadow;\n            vec3 _8663 = normalize(_8644.direction + _8482);\n            float _8668 = max(dot(_8530, _8663), 0.0);\n            float _8673 = max(dot(_8482, _8663), 0.0);\n            if (fa_light_is_area)\n            {\n                if (_8593.on)\n                {\n                    _8680 = _8593.f90;\n                }\n                else\n                {\n                    _8680 = 1.0;\n                }\n                int param_21 = _8628;\n                vec3 param_22 = fa_world_pos;\n                vec3 param_23 = _8530;\n                vec3 param_24 = _8482;\n                vec3 param_25 = _8570;\n                vec3 param_26 = f0;\n                float param_27 = _8680;\n                float param_28 = _8541;\n                float param_29 = _8554;\n                float param_30 = _8658;\n                vec3 area = fa_area_shade(param_21, param_22, param_23, param_24, param_25, param_26, param_27, param_28, param_29, param_30);\n                if (_8593.on)\n                {\n                    FaLayers param_31 = _8593;\n                    vec3 param_32 = area;\n                    int param_33 = _8628;\n                    vec3 param_34 = _8530;\n                    vec3 param_35 = _8482;\n                    vec3 param_36 = _8644.direction;\n                    float param_37 = _8554;\n                    float param_38 = _8658;\n                    area = fa_area_layers(param_31, param_32, param_33, param_34, param_35, param_36, param_37, param_38);\n                }\n                lit += area;\n            }\n            else\n            {\n                if (_8593.on)\n                {\n                    FaLayers param_39 = _8593;\n                    vec3 param_40 = _8570;\n                    vec3 param_41 = f0;\n                    vec3 param_42 = _8530;\n                    vec3 param_43 = _8482;\n                    vec3 param_44 = _8644.direction;\n                    vec3 param_45 = _8663;\n                    float param_46 = _8652;\n                    float param_47 = _8554;\n                    float param_48 = _8668;\n                    float param_49 = _8673;\n                    float param_50 = _8545;\n                    float param_51 = _8549;\n                    int param_52 = _8628;\n                    lit += (fa_layers_light(param_39, param_40, param_41, param_42, param_43, param_44, param_45, param_46, param_47, param_48, param_49, param_50, param_51) * ((fa_light_rgb(param_52) * fa_light_tint) * _8658));\n                }\n                else\n                {\n                    float _8782 = ((_8668 * _8668) * (_8549 - 1.0)) + 1.0;\n                    int param_53 = _8628;\n                    lit += (((_8570 + (((f0 + ((vec3(1.0) - f0) * pow(1.0 - _8673, 5.0))) * (((_8549 / ((3.1415927410125732421875 * _8782) * _8782)) * (0.5 / max(mix((2.0 * _8652) * _8554, _8652 + _8554, _8545), 9.9999997473787516355514526367188e-05))) * 3.1415927410125732421875)) * step(9.9999997473787516355514526367188e-05, _8652))) * (fa_light_rgb(param_53) * fa_light_tint)) * (_8652 * _8658));\n                }\n            }\n        }\n        if (_8593.on)\n        {\n            FaLayers param_54 = _8593;\n            vec3 param_55 = _8530;\n            vec3 param_56 = _8482;\n            vec3 param_57 = f0;\n            float param_58 = _8541;\n            float param_59 = _9223;\n            lit += fa_layers_ibl(param_54, param_55, param_56, param_57, param_58, param_59);\n        }\n        else\n        {\n            vec3 param_60 = _8530;\n            vec3 param_61 = _8482;\n            vec3 param_62 = f0;\n            float param_63 = _8541;\n            lit += (fa_sky_reflection(param_60, param_61, param_62, param_63) * _9223);\n        }\n        if (_8561 > 0.0)\n        {\n            float _8880;\n            if (_8593.on)\n            {\n                _8880 = _8593.f90;\n            }\n            else\n            {\n                _8880 = 1.0;\n            }\n            float _8888;\n            if (_8593.on)\n            {\n                _8888 = _8593.base_scale;\n            }\n            else\n            {\n                _8888 = 1.0;\n            }\n            Surface param_64 = Surface(_9218, _9219, _9220, _9221, _9222, _9223, _9224, _9225, _9226, _9227, _9228, _9229, _9230, _9231, _9232, _9233, _9234, _9235, _9236, _9237);\n            vec3 param_65 = _8530;\n            vec3 param_66 = _8482;\n            float param_67 = _8541;\n            vec3 param_68 = f0;\n            float param_69 = _8880;\n            float param_70 = _8888;\n            float param_71 = _8561;\n            float param_72 = fa_tr_blend;\n            vec3 _8912 = fa_transmitted(param_64, param_65, param_66, param_67, param_68, param_69, param_70, param_71, param_72);\n            fa_tr_blend = param_72;\n            lit += _8912;\n        }\n        result = lit;\n    }\n    vec3 _8919 = result;\n    vec3 _8920 = _8919 + _9224;\n    result = _8920;\n    vec3 param_73 = _8920;\n    vec3 param_74 = fa_world_pos;\n    result = fa_shadow_debug(param_73, param_74);\n    bool _8929 = fa_mesh_fs_params[7].w > 0.0;\n    bool _8936;\n    if (!_8929)\n    {\n        _8936 = fa_mesh_fs_params[8].y > 0.0;\n    }\n    else\n    {\n        _8936 = _8929;\n    }\n    if (_8936)\n    {\n        vec3 _8945 = fa_world_pos - fa_mesh_fs_params[0].xyz;\n        float _8951 = dot(_8945, fa_mesh_fs_params[9].xyz);\n        bool _8955 = fa_mesh_fs_params[9].w > 0.5;\n        float _8956;\n        if (_8955)\n        {\n            _8956 = _8951;\n        }\n        else\n        {\n            _8956 = length(_8945);\n        }\n        float _8968 = _8956 - fa_mesh_fs_params[8].x;\n        if (_8968 > 0.0)\n        {\n            float _8977 = fa_mesh_fs_params[7].w * _8968;\n            float tau = _8977 * _8977;\n            if (fa_mesh_fs_params[8].y > 0.0)\n            {\n                float _8993;\n                if (_8955)\n                {\n                    _8993 = fa_world_pos.y - (fa_mesh_fs_params[9].y * _8951);\n                }\n                else\n                {\n                    _8993 = fa_mesh_fs_params[0].y;\n                }\n                float _9014 = mix(_8993, fa_world_pos.y, clamp(fa_mesh_fs_params[8].x / _8956, 0.0, 1.0));\n                float _9018 = fa_world_pos.y - _9014;\n                float _9023 = _9014 - fa_mesh_fs_params[8].z;\n                float _9028 = fa_world_pos.y - fa_mesh_fs_params[8].z;\n                bool _9031 = _9023 <= 0.0;\n                bool _9032 = !_9031;\n                bool _9038;\n                if (_9032)\n                {\n                    _9038 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _9038 = _9031;\n                }\n                float _9039;\n                if (_9038)\n                {\n                    _9039 = fa_mesh_fs_params[8].y;\n                }\n                else\n                {\n                    _9039 = fa_mesh_fs_params[8].y * exp(-min(fa_mesh_fs_params[8].w * _9023, 80.0));\n                }\n                bool _9066;\n                if (_9032)\n                {\n                    _9066 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _9066 = _9031;\n                }\n                float _9067;\n                if (_9066)\n                {\n                    _9067 = fa_mesh_fs_params[8].y * _9023;\n                }\n                else\n                {\n                    _9067 = (fa_mesh_fs_params[8].y * (1.0 - exp(-min(fa_mesh_fs_params[8].w * _9023, 80.0)))) / fa_mesh_fs_params[8].w;\n                }\n                bool _9092 = _9028 <= 0.0;\n                bool _9099;\n                if (!_9092)\n                {\n                    _9099 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _9099 = _9092;\n                }\n                float _9100;\n                if (_9099)\n                {\n                    _9100 = fa_mesh_fs_params[8].y * _9028;\n                }\n                else\n                {\n                    _9100 = (fa_mesh_fs_params[8].y * (1.0 - exp(-min(fa_mesh_fs_params[8].w * _9028, 80.0)))) / fa_mesh_fs_params[8].w;\n                }\n                float _9127;\n                if (abs(_9018) < 0.001000000047497451305389404296875)\n                {\n                    _9127 = _9039;\n                }\n                else\n                {\n                    _9127 = (_9100 - _9067) / _9018;\n                }\n                tau += (_8968 * max(_9127, 0.0));\n            }\n            result = mix(result, fa_mesh_fs_params[7].xyz, vec3(clamp(1.0 - exp(-clamp(tau, 0.0, 80.0)), 0.0, 1.0)));\n        }\n    }\n    if (fa_tr_blend > 0.0)\n    {\n        float _9163 = 1.0 - fa_tr_blend;\n        result /= vec3(_9163);\n        _9219 *= _9163;\n    }\n    fa_frag_color = vec4(result, _9219);\n}\n\n",
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
            "size": 848,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_657",
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
            "inst_name": "_2319",
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
            "name": "fa_screen_tex_fa_shadow_smp",
            "view_name": "fa_screen_tex",
            "sampler_name": "fa_shadow_smp",
            "view_slot": 28,
            "sampler_slot": 1,
            "glsl_name": "fa_screen_tex_fa_shadow_smp"
          },
          {
            "slot": 13,
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
      "vs": "#version 430\n\nstruct VertexData\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 color;\n    vec3 object_pos;\n};\n\nuniform vec4 fa_mesh_vs_params[11];\nuniform vec4 fa_material_vs[1];\nuniform vec4 fa_vel_params[9];\nlayout(binding = 0) uniform sampler2D fa_vs_height_fa_vs_height_smp;\n\nlayout(location = 0) out vec3 fa_world_pos;\nlayout(location = 1) out vec3 fa_world_normal;\nlayout(location = 2) out vec4 fa_world_tangent;\nlayout(location = 3) out vec2 fa_uv;\nlayout(location = 4) out vec4 fa_vertex_color;\nlayout(location = 5) out float fa_pre_depth;\nlayout(location = 6) out vec3 fa_pre_r0;\nlayout(location = 7) out vec3 fa_pre_r1;\nlayout(location = 8) out vec3 fa_pre_r2;\nlayout(location = 9) out vec3 fa_vel_cur;\nlayout(location = 10) out vec3 fa_vel_prev;\nlayout(location = 9) in vec4 fa_prev_r0;\nlayout(location = 10) in vec4 fa_prev_r1;\nlayout(location = 11) in vec4 fa_prev_r2;\nlayout(location = 5) in vec4 fa_inst_m0;\nlayout(location = 6) in vec4 fa_inst_m1;\nlayout(location = 7) in vec4 fa_inst_m2;\nlayout(location = 8) in vec4 fa_inst_m3;\nlayout(location = 0) in vec3 fa_position;\nlayout(location = 1) in vec3 fa_normal;\nlayout(location = 3) in vec4 fa_tangent;\nlayout(location = 2) in vec2 fa_texcoord0;\nlayout(location = 4) in vec4 fa_color;\nvec4 fa_vtime;\n\nvoid fa_inst_begin()\n{\n}\n\nvec4 fa_time_now()\n{\n    return fa_mesh_vs_params[9];\n}\n\nVertexData fa_vertex_data(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    vec3 _129 = cross(model[1].xyz, model[2].xyz);\n    float _133 = (dot(model[0].xyz, _129) < 0.0) ? (-1.0) : 1.0;\n    return VertexData((model * vec4(position, 1.0)).xyz, (((_129 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _133, vec4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _133), texcoord0 * fa_mesh_vs_params[8].xy, color, position);\n}\n\nvoid vertex(inout VertexData v)\n{\n    v.world_pos.y += (textureLod(fa_vs_height_fa_vs_height_smp, v.uv, 0.0).x * fa_material_vs[0].x);\n}\n\nmat4 fa_rows_to_mat4(vec4 r0, vec4 r1, vec4 r2)\n{\n    return mat4(vec4(r0.x, r1.x, r2.x, 0.0), vec4(r0.y, r1.y, r2.y, 0.0), vec4(r0.z, r1.z, r2.z, 0.0), vec4(r0.w, r1.w, r2.w, 1.0));\n}\n\nmat4 fa_prev_model()\n{\n    vec4 param = fa_prev_r0;\n    vec4 param_1 = fa_prev_r1;\n    vec4 param_2 = fa_prev_r2;\n    return fa_rows_to_mat4(param, param_1, param_2);\n}\n\nvoid fa_prepass_vertex(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color, bool has_prev)\n{\n    bool _259;\n    if (has_prev)\n    {\n        _259 = fa_vel_params[8].x > 0.5;\n    }\n    else\n    {\n        _259 = has_prev;\n    }\n    fa_vtime = fa_time_now();\n    mat4 param = model;\n    vec3 param_1 = position;\n    vec3 param_2 = normal;\n    vec4 param_3 = tangent;\n    vec2 param_4 = texcoord0;\n    vec4 param_5 = color;\n    VertexData param_6 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    vertex(param_6);\n    mat4 _282 = mat4(fa_mesh_vs_params[4], fa_mesh_vs_params[5], fa_mesh_vs_params[6], fa_mesh_vs_params[7]);\n    vec4 _289 = vec4(param_6.world_pos, 1.0);\n    fa_world_pos = param_6.world_pos;\n    fa_world_normal = param_6.world_normal;\n    fa_world_tangent = param_6.world_tangent;\n    fa_uv = param_6.uv;\n    fa_vertex_color = param_6.color;\n    fa_pre_depth = -(_282 * _289).z;\n    fa_pre_r0 = vec3(_282[0].x, _282[1].x, _282[2].x);\n    fa_pre_r1 = vec3(_282[0].y, _282[1].y, _282[2].y);\n    fa_pre_r2 = vec3(_282[0].z, _282[1].z, _282[2].z);\n    gl_Position = mat4(fa_mesh_vs_params[0], fa_mesh_vs_params[1], fa_mesh_vs_params[2], fa_mesh_vs_params[3]) * _289;\n    fa_vel_cur = vec3(0.0, 0.0, 1.0);\n    fa_vel_prev = vec3(0.0);\n    if (_259)\n    {\n        fa_vtime.x = fa_vel_params[8].y;\n        mat4 param_7 = fa_prev_model();\n        vec3 param_8 = position;\n        vec3 param_9 = normal;\n        vec4 param_10 = tangent;\n        vec2 param_11 = texcoord0;\n        vec4 param_12 = color;\n        VertexData param_13 = fa_vertex_data(param_7, param_8, param_9, param_10, param_11, param_12);\n        vertex(param_13);\n        fa_vel_cur = vec3((mat4(fa_vel_params[0], fa_vel_params[1], fa_vel_params[2], fa_vel_params[3]) * _289).xyw);\n        fa_vel_prev = vec3((mat4(fa_vel_params[4], fa_vel_params[5], fa_vel_params[6], fa_vel_params[7]) * vec4(param_13.world_pos, 1.0)).xyw);\n    }\n}\n\nvoid main()\n{\n    fa_vtime = vec4(0.0);\n    fa_inst_begin();\n    mat4 param = mat4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3);\n    vec3 param_1 = fa_position;\n    vec3 param_2 = fa_normal;\n    vec4 param_3 = fa_tangent;\n    vec2 param_4 = fa_texcoord0;\n    vec4 param_5 = fa_color;\n    bool param_6 = true;\n    fa_prepass_vertex(param, param_1, param_2, param_3, param_4, param_5, param_6);\n}\n\n",
      "fs": "#version 430\n\nstruct SurfaceInput\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 vertex_color;\n    vec3 view_dir;\n    bool front_facing;\n};\n\nstruct Surface\n{\n    vec3 albedo;\n    float alpha;\n    vec3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    vec3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    vec3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    vec3 specular_color;\n    float transmission;\n    float thickness;\n    vec3 attenuation_color;\n    float attenuation_distance;\n};\n\nuniform vec4 fa_mesh_fs_params[53];\nlayout(binding = 0) uniform sampler2D fa_tex_fa_smp;\nlayout(binding = 1) uniform sampler2D fa_normal_tex_fa_smp;\nlayout(binding = 2) uniform sampler2D fa_mr_tex_fa_smp;\nlayout(binding = 3) uniform sampler2D fa_occlusion_tex_fa_smp;\nlayout(binding = 4) uniform sampler2D fa_emissive_tex_fa_smp;\nlayout(binding = 5) uniform sampler2D height_height_smp;\n\nlayout(location = 0) in vec3 fa_world_pos;\nlayout(location = 1) in vec3 fa_world_normal;\nlayout(location = 2) in vec4 fa_world_tangent;\nlayout(location = 3) in vec2 fa_uv;\nlayout(location = 4) in vec4 fa_vertex_color;\nlayout(location = 6) in vec3 fa_pre_r0;\nlayout(location = 7) in vec3 fa_pre_r1;\nlayout(location = 8) in vec3 fa_pre_r2;\nlayout(location = 0) out vec4 fa_frag_color;\nlayout(location = 5) in float fa_pre_depth;\nlayout(location = 9) in vec3 fa_vel_cur;\nlayout(location = 10) in vec3 fa_vel_prev;\nlayout(location = 1) out vec2 fa_frag_velocity;\n\nvoid fa_inst_load()\n{\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nvec3 fa_linear_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_tex_fix(inout vec3 c, float mode)\n{\n    if (mode > 1.5)\n    {\n        vec3 param = c;\n        vec3 _196 = fa_linear_to_srgb(param);\n        c = _196;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            vec3 param_1 = c;\n            vec3 _204 = fa_srgb_to_linear(param_1);\n            c = _204;\n        }\n    }\n    return c;\n}\n\nvec3 fa_tangent_normal(SurfaceInput i, vec3 m)\n{\n    vec3 _56;\n    if (i.front_facing)\n    {\n        _56 = i.world_normal;\n    }\n    else\n    {\n        _56 = -i.world_normal;\n    }\n    vec3 _81 = normalize(i.world_tangent.xyz - (_56 * dot(_56, i.world_tangent.xyz)));\n    vec3 _109 = normalize(((_81 * m.x) + ((cross(_56, _81) * i.world_tangent.w) * m.y)) + (_56 * m.z));\n    vec3 _112;\n    if (i.front_facing)\n    {\n        _112 = _109;\n    }\n    else\n    {\n        _112 = -_109;\n    }\n    return _112;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    vec4 base_t = texture(fa_tex_fa_smp, i.uv, fa_mesh_fs_params[12].w);\n    float param = fa_mesh_fs_params[6].w;\n    float param_1 = 1.0;\n    vec3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    vec3 _245 = fa_tex_fix(param_2, param_3);\n    vec4 _856 = base_t;\n    _856.x = _245.x;\n    _856.y = _245.y;\n    _856.z = _245.z;\n    base_t = _856;\n    vec4 _261 = (_856 * fa_mesh_fs_params[2]) * i.vertex_color;\n    vec3 _811 = i.world_normal;\n    if (fa_mesh_fs_params[6].z > 0.5)\n    {\n        float param_4 = fa_mesh_fs_params[6].w;\n        float param_5 = 16.0;\n        vec3 param_6 = texture(fa_normal_tex_fa_smp, i.uv, fa_mesh_fs_params[12].w).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        vec3 _296 = fa_tex_fix(param_6, param_7);\n        vec3 _300 = (_296 * 2.0) - vec3(1.0);\n        vec2 _305 = _300.xy * fa_mesh_fs_params[6].x;\n        vec3 _864 = _300;\n        _864.x = _305.x;\n        _864.y = _305.y;\n        SurfaceInput param_8 = i;\n        vec3 param_9 = _864;\n        _811 = fa_tangent_normal(param_8, param_9);\n    }\n    vec4 mrt = texture(fa_mr_tex_fa_smp, i.uv, fa_mesh_fs_params[12].w);\n    float param_10 = fa_mesh_fs_params[6].w;\n    float param_11 = 64.0;\n    vec3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    vec3 _336 = fa_tex_fix(param_12, param_13);\n    vec4 _867 = mrt;\n    _867.x = _336.x;\n    _867.y = _336.y;\n    _867.z = _336.z;\n    mrt = _867;\n    vec4 _368 = texture(fa_occlusion_tex_fa_smp, i.uv, fa_mesh_fs_params[12].w);\n    float param_14 = fa_mesh_fs_params[6].w;\n    float param_15 = 256.0;\n    vec3 param_16 = _368.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    vec3 _380 = fa_tex_fix(param_16, param_17);\n    float param_18 = fa_mesh_fs_params[6].w;\n    float param_19 = 4.0;\n    vec3 param_20 = texture(fa_emissive_tex_fa_smp, i.uv, fa_mesh_fs_params[12].w).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    vec3 _412 = fa_tex_fix(param_20, param_21);\n    float _816 = fa_mesh_fs_params[20].x;\n    float _817 = fa_mesh_fs_params[20].y;\n    float _820 = fa_mesh_fs_params[20].z;\n    float _819 = fa_mesh_fs_params[21].w;\n    float _822 = fa_mesh_fs_params[22].x;\n    if (fa_mesh_fs_params[22].z > 0.5)\n    {\n        if (mod(fa_mesh_fs_params[22].z, 2.0) > 0.5)\n        {\n            _816 *= _380.y;\n            _817 *= _380.z;\n            _819 *= _368.w;\n        }\n        if (fa_mesh_fs_params[22].z > 1.5)\n        {\n            _820 *= mrt.x;\n            _822 *= mrt.w;\n        }\n    }\n    return Surface(_261.xyz, _261.w, _811, clamp(fa_mesh_fs_params[5].x * _336.z, 0.0, 1.0), clamp(fa_mesh_fs_params[5].y * _336.y, 0.0500000007450580596923828125, 1.0), 1.0 + (fa_mesh_fs_params[6].y * (_380.x - 1.0)), fa_mesh_fs_params[3].xyz + (fa_mesh_fs_params[4].xyz * _412), _816, _817, fa_mesh_fs_params[21].xyz, _819, _820, fa_mesh_fs_params[20].w, _822, fa_mesh_fs_params[22].y, fa_mesh_fs_params[23].xyz, fa_mesh_fs_params[30].x, fa_mesh_fs_params[30].y, fa_mesh_fs_params[31].xyz, fa_mesh_fs_params[30].z);\n}\n\nvoid surface(SurfaceInput i, inout Surface s)\n{\n    s.albedo *= mix(0.5, 1.0, texture(height_height_smp, i.uv).x);\n}\n\nvoid main()\n{\n    fa_inst_load();\n    vec3 _706 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _706 = -_706;\n    }\n    vec3 _564 = normalize(fa_mesh_fs_params[0].xyz - fa_world_pos);\n    SurfaceInput param = SurfaceInput(fa_world_pos, _706, fa_world_tangent, fa_uv, fa_vertex_color, _564, gl_FrontFacing);\n    SurfaceInput param_1 = SurfaceInput(fa_world_pos, _706, fa_world_tangent, fa_uv, fa_vertex_color, _564, gl_FrontFacing);\n    Surface param_2 = fa_standard_surface(param);\n    surface(param_1, param_2);\n    vec3 _579 = normalize(param_2.normal);\n    vec3 _594 = normalize(vec3(dot(fa_pre_r0, _579), dot(fa_pre_r1, _579), dot(fa_pre_r2, _579)));\n    float _606 = _594.z;\n    vec2 e = _594.xy / vec2((abs(_594.x) + abs(_594.y)) + abs(_606));\n    if (_606 < 0.0)\n    {\n        e = (vec2(1.0) - abs(e.yx)) * vec2((e.x >= 0.0) ? 1.0 : (-1.0), (e.y >= 0.0) ? 1.0 : (-1.0));\n    }\n    fa_frag_color = vec4(min(fa_pre_depth, 60000.0), e, 1.0);\n    vec2 motion = vec2(1024.0);\n    bool _650 = fa_vel_cur.z > 9.9999997473787516355514526367188e-06;\n    bool _657;\n    if (_650)\n    {\n        _657 = fa_vel_prev.z > 9.9999997473787516355514526367188e-06;\n    }\n    else\n    {\n        _657 = _650;\n    }\n    if (_657)\n    {\n        motion = clamp(((vec2(fa_vel_prev.x, -fa_vel_prev.y) / vec2(fa_vel_prev.z)) * 0.5) - ((vec2(fa_vel_cur.x, -fa_vel_cur.y) / vec2(fa_vel_cur.z)) * 0.5), vec2(-4.0), vec2(4.0));\n    }\n    fa_frag_velocity = motion;\n}\n\n",
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
            "inst_name": "_62",
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
            "slot": 4,
            "stage": "vertex",
            "size": 16,
            "struct_name": "fa_material_vs",
            "inst_name": "_89",
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
            "slot": 2,
            "stage": "vertex",
            "size": 144,
            "struct_name": "fa_vel_params",
            "inst_name": "_254",
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
            "inst_name": "_230",
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
      "vs": "#version 430\n\nstruct VertexData\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 color;\n    vec3 object_pos;\n};\n\nuniform vec4 fa_mesh_vs_params[11];\nuniform vec4 fa_material_vs[1];\nuniform vec4 fa_skin[192];\nuniform vec4 fa_vel_params[9];\nlayout(binding = 0) uniform sampler2D fa_vs_height_fa_vs_height_smp;\nlayout(binding = 1) uniform sampler2D fa_prev_pal_tex_fa_prev_pal_smp;\n\nlayout(location = 0) out vec3 fa_world_pos;\nlayout(location = 1) out vec3 fa_world_normal;\nlayout(location = 2) out vec4 fa_world_tangent;\nlayout(location = 3) out vec2 fa_uv;\nlayout(location = 4) out vec4 fa_vertex_color;\nlayout(location = 5) out float fa_pre_depth;\nlayout(location = 6) out vec3 fa_pre_r0;\nlayout(location = 7) out vec3 fa_pre_r1;\nlayout(location = 8) out vec3 fa_pre_r2;\nlayout(location = 9) out vec3 fa_vel_cur;\nlayout(location = 10) out vec3 fa_vel_prev;\nlayout(location = 11) in vec4 fa_prev_r0;\nlayout(location = 12) in vec4 fa_prev_r1;\nlayout(location = 13) in vec4 fa_prev_r2;\nlayout(location = 9) in vec4 fa_joints;\nlayout(location = 10) in vec4 fa_weights;\nlayout(location = 5) in vec4 fa_inst_m0;\nlayout(location = 6) in vec4 fa_inst_m1;\nlayout(location = 7) in vec4 fa_inst_m2;\nlayout(location = 8) in vec4 fa_inst_m3;\nlayout(location = 0) in vec3 fa_position;\nlayout(location = 1) in vec3 fa_normal;\nlayout(location = 3) in vec4 fa_tangent;\nlayout(location = 2) in vec2 fa_texcoord0;\nlayout(location = 4) in vec4 fa_color;\nvec4 fa_vtime;\n\nvoid fa_inst_begin()\n{\n}\n\nmat4 fa_skin_matrix(vec4 joints, vec4 weights)\n{\n    vec4 r0 = vec4(0.0);\n    vec4 r1 = vec4(0.0);\n    vec4 r2 = vec4(0.0);\n    for (int i = 0; i < 4; i++)\n    {\n        int _233 = int((joints[i] * 255.0) + 0.5) * 3;\n        r0 += (fa_skin[_233 * 1 + 0] * weights[i]);\n        r1 += (fa_skin[(_233 + 1) * 1 + 0] * weights[i]);\n        r2 += (fa_skin[(_233 + 2) * 1 + 0] * weights[i]);\n    }\n    return mat4(vec4(r0.x, r1.x, r2.x, 0.0), vec4(r0.y, r1.y, r2.y, 0.0), vec4(r0.z, r1.z, r2.z, 0.0), vec4(r0.w, r1.w, r2.w, 1.0));\n}\n\nvec4 fa_time_now()\n{\n    return fa_mesh_vs_params[9];\n}\n\nVertexData fa_vertex_data(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    vec3 _145 = cross(model[1].xyz, model[2].xyz);\n    float _149 = (dot(model[0].xyz, _145) < 0.0) ? (-1.0) : 1.0;\n    return VertexData((model * vec4(position, 1.0)).xyz, (((_145 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _149, vec4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _149), texcoord0 * fa_mesh_vs_params[8].xy, color, position);\n}\n\nvoid vertex(inout VertexData v)\n{\n    v.world_pos.y += (textureLod(fa_vs_height_fa_vs_height_smp, v.uv, 0.0).x * fa_material_vs[0].x);\n}\n\nmat4 fa_rows_to_mat4(vec4 r0, vec4 r1, vec4 r2)\n{\n    return mat4(vec4(r0.x, r1.x, r2.x, 0.0), vec4(r0.y, r1.y, r2.y, 0.0), vec4(r0.z, r1.z, r2.z, 0.0), vec4(r0.w, r1.w, r2.w, 1.0));\n}\n\nvec4 fa_prev_pal_texel(int t)\n{\n    return texelFetch(fa_prev_pal_tex_fa_prev_pal_smp, ivec2(t & 1023, t >> 10), 0);\n}\n\nmat4 fa_prev_skin_matrix(vec4 joints, vec4 weights, int base)\n{\n    vec4 r0 = vec4(0.0);\n    vec4 r1 = vec4(0.0);\n    vec4 r2 = vec4(0.0);\n    for (int i = 0; i < 4; i++)\n    {\n        int _356 = base + (int((joints[i] * 255.0) + 0.5) * 3);\n        int param = _356;\n        r0 += (fa_prev_pal_texel(param) * weights[i]);\n        int param_1 = _356 + 1;\n        r1 += (fa_prev_pal_texel(param_1) * weights[i]);\n        int param_2 = _356 + 2;\n        r2 += (fa_prev_pal_texel(param_2) * weights[i]);\n    }\n    return mat4(vec4(r0.x, r1.x, r2.x, 0.0), vec4(r0.y, r1.y, r2.y, 0.0), vec4(r0.z, r1.z, r2.z, 0.0), vec4(r0.w, r1.w, r2.w, 1.0));\n}\n\nmat4 fa_prev_model()\n{\n    vec4 param = fa_prev_r0;\n    vec4 param_1 = fa_prev_r1;\n    vec4 param_2 = fa_prev_r2;\n    vec4 param_3 = fa_joints;\n    vec4 param_4 = fa_weights;\n    int param_5 = int(fa_vel_params[8].w + 0.5);\n    return fa_rows_to_mat4(param, param_1, param_2) * fa_prev_skin_matrix(param_3, param_4, param_5);\n}\n\nvoid fa_prepass_vertex(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color, bool has_prev)\n{\n    bool _498;\n    if (has_prev)\n    {\n        _498 = fa_vel_params[8].x > 0.5;\n    }\n    else\n    {\n        _498 = has_prev;\n    }\n    fa_vtime = fa_time_now();\n    mat4 param = model;\n    vec3 param_1 = position;\n    vec3 param_2 = normal;\n    vec4 param_3 = tangent;\n    vec2 param_4 = texcoord0;\n    vec4 param_5 = color;\n    VertexData param_6 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    vertex(param_6);\n    mat4 _521 = mat4(fa_mesh_vs_params[4], fa_mesh_vs_params[5], fa_mesh_vs_params[6], fa_mesh_vs_params[7]);\n    vec4 _528 = vec4(param_6.world_pos, 1.0);\n    fa_world_pos = param_6.world_pos;\n    fa_world_normal = param_6.world_normal;\n    fa_world_tangent = param_6.world_tangent;\n    fa_uv = param_6.uv;\n    fa_vertex_color = param_6.color;\n    fa_pre_depth = -(_521 * _528).z;\n    fa_pre_r0 = vec3(_521[0].x, _521[1].x, _521[2].x);\n    fa_pre_r1 = vec3(_521[0].y, _521[1].y, _521[2].y);\n    fa_pre_r2 = vec3(_521[0].z, _521[1].z, _521[2].z);\n    gl_Position = mat4(fa_mesh_vs_params[0], fa_mesh_vs_params[1], fa_mesh_vs_params[2], fa_mesh_vs_params[3]) * _528;\n    fa_vel_cur = vec3(0.0, 0.0, 1.0);\n    fa_vel_prev = vec3(0.0);\n    if (_498)\n    {\n        fa_vtime.x = fa_vel_params[8].y;\n        mat4 param_7 = fa_prev_model();\n        vec3 param_8 = position;\n        vec3 param_9 = normal;\n        vec4 param_10 = tangent;\n        vec2 param_11 = texcoord0;\n        vec4 param_12 = color;\n        VertexData param_13 = fa_vertex_data(param_7, param_8, param_9, param_10, param_11, param_12);\n        vertex(param_13);\n        fa_vel_cur = vec3((mat4(fa_vel_params[0], fa_vel_params[1], fa_vel_params[2], fa_vel_params[3]) * _528).xyw);\n        fa_vel_prev = vec3((mat4(fa_vel_params[4], fa_vel_params[5], fa_vel_params[6], fa_vel_params[7]) * vec4(param_13.world_pos, 1.0)).xyw);\n    }\n}\n\nvoid main()\n{\n    fa_vtime = vec4(0.0);\n    fa_inst_begin();\n    vec4 param = fa_joints;\n    vec4 param_1 = fa_weights;\n    mat4 param_2 = mat4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3) * fa_skin_matrix(param, param_1);\n    vec3 param_3 = fa_position;\n    vec3 param_4 = fa_normal;\n    vec4 param_5 = fa_tangent;\n    vec2 param_6 = fa_texcoord0;\n    vec4 param_7 = fa_color;\n    bool param_8 = fa_vel_params[8].z > 0.5;\n    fa_prepass_vertex(param_2, param_3, param_4, param_5, param_6, param_7, param_8);\n}\n\n",
      "fs": "#version 430\n\nstruct SurfaceInput\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 vertex_color;\n    vec3 view_dir;\n    bool front_facing;\n};\n\nstruct Surface\n{\n    vec3 albedo;\n    float alpha;\n    vec3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    vec3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    vec3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    vec3 specular_color;\n    float transmission;\n    float thickness;\n    vec3 attenuation_color;\n    float attenuation_distance;\n};\n\nuniform vec4 fa_mesh_fs_params[53];\nlayout(binding = 0) uniform sampler2D fa_tex_fa_smp;\nlayout(binding = 1) uniform sampler2D fa_normal_tex_fa_smp;\nlayout(binding = 2) uniform sampler2D fa_mr_tex_fa_smp;\nlayout(binding = 3) uniform sampler2D fa_occlusion_tex_fa_smp;\nlayout(binding = 4) uniform sampler2D fa_emissive_tex_fa_smp;\nlayout(binding = 5) uniform sampler2D height_height_smp;\n\nlayout(location = 0) in vec3 fa_world_pos;\nlayout(location = 1) in vec3 fa_world_normal;\nlayout(location = 2) in vec4 fa_world_tangent;\nlayout(location = 3) in vec2 fa_uv;\nlayout(location = 4) in vec4 fa_vertex_color;\nlayout(location = 6) in vec3 fa_pre_r0;\nlayout(location = 7) in vec3 fa_pre_r1;\nlayout(location = 8) in vec3 fa_pre_r2;\nlayout(location = 0) out vec4 fa_frag_color;\nlayout(location = 5) in float fa_pre_depth;\nlayout(location = 9) in vec3 fa_vel_cur;\nlayout(location = 10) in vec3 fa_vel_prev;\nlayout(location = 1) out vec2 fa_frag_velocity;\n\nvoid fa_inst_load()\n{\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nvec3 fa_linear_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_tex_fix(inout vec3 c, float mode)\n{\n    if (mode > 1.5)\n    {\n        vec3 param = c;\n        vec3 _196 = fa_linear_to_srgb(param);\n        c = _196;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            vec3 param_1 = c;\n            vec3 _204 = fa_srgb_to_linear(param_1);\n            c = _204;\n        }\n    }\n    return c;\n}\n\nvec3 fa_tangent_normal(SurfaceInput i, vec3 m)\n{\n    vec3 _56;\n    if (i.front_facing)\n    {\n        _56 = i.world_normal;\n    }\n    else\n    {\n        _56 = -i.world_normal;\n    }\n    vec3 _81 = normalize(i.world_tangent.xyz - (_56 * dot(_56, i.world_tangent.xyz)));\n    vec3 _109 = normalize(((_81 * m.x) + ((cross(_56, _81) * i.world_tangent.w) * m.y)) + (_56 * m.z));\n    vec3 _112;\n    if (i.front_facing)\n    {\n        _112 = _109;\n    }\n    else\n    {\n        _112 = -_109;\n    }\n    return _112;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    vec4 base_t = texture(fa_tex_fa_smp, i.uv, fa_mesh_fs_params[12].w);\n    float param = fa_mesh_fs_params[6].w;\n    float param_1 = 1.0;\n    vec3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    vec3 _245 = fa_tex_fix(param_2, param_3);\n    vec4 _856 = base_t;\n    _856.x = _245.x;\n    _856.y = _245.y;\n    _856.z = _245.z;\n    base_t = _856;\n    vec4 _261 = (_856 * fa_mesh_fs_params[2]) * i.vertex_color;\n    vec3 _811 = i.world_normal;\n    if (fa_mesh_fs_params[6].z > 0.5)\n    {\n        float param_4 = fa_mesh_fs_params[6].w;\n        float param_5 = 16.0;\n        vec3 param_6 = texture(fa_normal_tex_fa_smp, i.uv, fa_mesh_fs_params[12].w).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        vec3 _296 = fa_tex_fix(param_6, param_7);\n        vec3 _300 = (_296 * 2.0) - vec3(1.0);\n        vec2 _305 = _300.xy * fa_mesh_fs_params[6].x;\n        vec3 _864 = _300;\n        _864.x = _305.x;\n        _864.y = _305.y;\n        SurfaceInput param_8 = i;\n        vec3 param_9 = _864;\n        _811 = fa_tangent_normal(param_8, param_9);\n    }\n    vec4 mrt = texture(fa_mr_tex_fa_smp, i.uv, fa_mesh_fs_params[12].w);\n    float param_10 = fa_mesh_fs_params[6].w;\n    float param_11 = 64.0;\n    vec3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    vec3 _336 = fa_tex_fix(param_12, param_13);\n    vec4 _867 = mrt;\n    _867.x = _336.x;\n    _867.y = _336.y;\n    _867.z = _336.z;\n    mrt = _867;\n    vec4 _368 = texture(fa_occlusion_tex_fa_smp, i.uv, fa_mesh_fs_params[12].w);\n    float param_14 = fa_mesh_fs_params[6].w;\n    float param_15 = 256.0;\n    vec3 param_16 = _368.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    vec3 _380 = fa_tex_fix(param_16, param_17);\n    float param_18 = fa_mesh_fs_params[6].w;\n    float param_19 = 4.0;\n    vec3 param_20 = texture(fa_emissive_tex_fa_smp, i.uv, fa_mesh_fs_params[12].w).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    vec3 _412 = fa_tex_fix(param_20, param_21);\n    float _816 = fa_mesh_fs_params[20].x;\n    float _817 = fa_mesh_fs_params[20].y;\n    float _820 = fa_mesh_fs_params[20].z;\n    float _819 = fa_mesh_fs_params[21].w;\n    float _822 = fa_mesh_fs_params[22].x;\n    if (fa_mesh_fs_params[22].z > 0.5)\n    {\n        if (mod(fa_mesh_fs_params[22].z, 2.0) > 0.5)\n        {\n            _816 *= _380.y;\n            _817 *= _380.z;\n            _819 *= _368.w;\n        }\n        if (fa_mesh_fs_params[22].z > 1.5)\n        {\n            _820 *= mrt.x;\n            _822 *= mrt.w;\n        }\n    }\n    return Surface(_261.xyz, _261.w, _811, clamp(fa_mesh_fs_params[5].x * _336.z, 0.0, 1.0), clamp(fa_mesh_fs_params[5].y * _336.y, 0.0500000007450580596923828125, 1.0), 1.0 + (fa_mesh_fs_params[6].y * (_380.x - 1.0)), fa_mesh_fs_params[3].xyz + (fa_mesh_fs_params[4].xyz * _412), _816, _817, fa_mesh_fs_params[21].xyz, _819, _820, fa_mesh_fs_params[20].w, _822, fa_mesh_fs_params[22].y, fa_mesh_fs_params[23].xyz, fa_mesh_fs_params[30].x, fa_mesh_fs_params[30].y, fa_mesh_fs_params[31].xyz, fa_mesh_fs_params[30].z);\n}\n\nvoid surface(SurfaceInput i, inout Surface s)\n{\n    s.albedo *= mix(0.5, 1.0, texture(height_height_smp, i.uv).x);\n}\n\nvoid main()\n{\n    fa_inst_load();\n    vec3 _706 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _706 = -_706;\n    }\n    vec3 _564 = normalize(fa_mesh_fs_params[0].xyz - fa_world_pos);\n    SurfaceInput param = SurfaceInput(fa_world_pos, _706, fa_world_tangent, fa_uv, fa_vertex_color, _564, gl_FrontFacing);\n    SurfaceInput param_1 = SurfaceInput(fa_world_pos, _706, fa_world_tangent, fa_uv, fa_vertex_color, _564, gl_FrontFacing);\n    Surface param_2 = fa_standard_surface(param);\n    surface(param_1, param_2);\n    vec3 _579 = normalize(param_2.normal);\n    vec3 _594 = normalize(vec3(dot(fa_pre_r0, _579), dot(fa_pre_r1, _579), dot(fa_pre_r2, _579)));\n    float _606 = _594.z;\n    vec2 e = _594.xy / vec2((abs(_594.x) + abs(_594.y)) + abs(_606));\n    if (_606 < 0.0)\n    {\n        e = (vec2(1.0) - abs(e.yx)) * vec2((e.x >= 0.0) ? 1.0 : (-1.0), (e.y >= 0.0) ? 1.0 : (-1.0));\n    }\n    fa_frag_color = vec4(min(fa_pre_depth, 60000.0), e, 1.0);\n    vec2 motion = vec2(1024.0);\n    bool _650 = fa_vel_cur.z > 9.9999997473787516355514526367188e-06;\n    bool _657;\n    if (_650)\n    {\n        _657 = fa_vel_prev.z > 9.9999997473787516355514526367188e-06;\n    }\n    else\n    {\n        _657 = _650;\n    }\n    if (_657)\n    {\n        motion = clamp(((vec2(fa_vel_prev.x, -fa_vel_prev.y) / vec2(fa_vel_prev.z)) * 0.5) - ((vec2(fa_vel_cur.x, -fa_vel_cur.y) / vec2(fa_vel_cur.z)) * 0.5), vec2(-4.0), vec2(4.0));\n    }\n    fa_frag_velocity = motion;\n}\n\n",
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
            "inst_name": "_79",
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
            "slot": 4,
            "stage": "vertex",
            "size": 16,
            "struct_name": "fa_material_vs",
            "inst_name": "_105",
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
            "slot": 3,
            "stage": "vertex",
            "size": 3072,
            "struct_name": "fa_skin",
            "inst_name": "_242",
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
            "inst_name": "_494",
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
            "inst_name": "_230",
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
            "slot": 6,
            "stage": "vertex",
            "name": "fa_vs_height_smp",
            "sampler_type": "filtering"
          },
          {
            "slot": 11,
            "stage": "vertex",
            "name": "fa_prev_pal_smp",
            "sampler_type": "nonfiltering"
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
            "stage": "vertex",
            "name": "fa_prev_pal_tex_fa_prev_pal_smp",
            "view_name": "fa_prev_pal_tex",
            "sampler_name": "fa_prev_pal_smp",
            "view_slot": 29,
            "sampler_slot": 11,
            "glsl_name": "fa_prev_pal_tex_fa_prev_pal_smp"
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
