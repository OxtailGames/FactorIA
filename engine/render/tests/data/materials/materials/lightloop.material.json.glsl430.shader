{
  "format": "factoria.shader/1",
  "engine": "0.35.2",
  "template": "fa8167552b2b36a7f7f7aabbbfd121188850db007da21e603f0701c03f2dab1c",
  "slang": "glsl430",
  "params": [
    "dark",
    "skyAmount"
  ],
  "textures": [],
  "programs": {
    "mesh": {
      "vs": "#version 430\n\nstruct VertexData\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 color;\n    vec3 object_pos;\n};\n\nuniform vec4 fa_mesh_vs_params[11];\nlayout(location = 0) out vec3 fa_world_pos;\nlayout(location = 1) out vec3 fa_world_normal;\nlayout(location = 2) out vec4 fa_world_tangent;\nlayout(location = 3) out vec2 fa_uv;\nlayout(location = 4) out vec4 fa_vertex_color;\nlayout(location = 5) in vec4 fa_inst_m0;\nlayout(location = 6) in vec4 fa_inst_m1;\nlayout(location = 7) in vec4 fa_inst_m2;\nlayout(location = 8) in vec4 fa_inst_m3;\nlayout(location = 0) in vec3 fa_position;\nlayout(location = 1) in vec3 fa_normal;\nlayout(location = 3) in vec4 fa_tangent;\nlayout(location = 2) in vec2 fa_texcoord0;\nlayout(location = 4) in vec4 fa_color;\nlayout(location = 5) out vec3 fa_lm;\n\nvoid fa_inst_begin()\n{\n}\n\nVertexData fa_vertex_data(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    vec3 _69 = cross(model[1].xyz, model[2].xyz);\n    float _75 = (dot(model[0].xyz, _69) < 0.0) ? (-1.0) : 1.0;\n    return VertexData((model * vec4(position, 1.0)).xyz, (((_69 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _75, vec4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _75), texcoord0 * fa_mesh_vs_params[8].xy, color, position);\n}\n\nvoid fa_shade_vertex(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    mat4 param = model;\n    vec3 param_1 = position;\n    vec3 param_2 = normal;\n    vec4 param_3 = tangent;\n    vec2 param_4 = texcoord0;\n    vec4 param_5 = color;\n    VertexData _160 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    vec3 _270 = _160.world_pos;\n    fa_world_pos = _270;\n    fa_world_normal = _160.world_normal;\n    fa_world_tangent = _160.world_tangent;\n    fa_uv = _160.uv;\n    fa_vertex_color = _160.color;\n    gl_Position = mat4(fa_mesh_vs_params[0], fa_mesh_vs_params[1], fa_mesh_vs_params[2], fa_mesh_vs_params[3]) * vec4(_270, 1.0);\n}\n\nvoid main()\n{\n    fa_inst_begin();\n    mat4 param = mat4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3);\n    vec3 param_1 = fa_position;\n    vec3 param_2 = fa_normal;\n    vec4 param_3 = fa_tangent;\n    vec2 param_4 = fa_texcoord0;\n    vec4 param_5 = fa_color;\n    fa_shade_vertex(param, param_1, param_2, param_3, param_4, param_5);\n    fa_lm = vec3(0.0);\n}\n\n",
      "fs": "#version 430\n\nstruct SurfaceInput\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 vertex_color;\n    vec3 view_dir;\n    bool front_facing;\n};\n\nstruct LightSample\n{\n    vec3 direction;\n    vec3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct Surface\n{\n    vec3 albedo;\n    float alpha;\n    vec3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    vec3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    vec3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    vec3 specular_color;\n    float transmission;\n    float thickness;\n    vec3 attenuation_color;\n    float attenuation_distance;\n};\n\nstruct FaLayers\n{\n    bool on;\n    float f90;\n    float keep;\n    float base_scale;\n    float coat;\n    float coat_rough;\n    float coat_alpha;\n    float coat_a2;\n    vec3 nc;\n    float coat_ndv;\n    bool sheen_on;\n    vec3 sheen;\n    float sheen_rough;\n    float sheen_alpha;\n    float sheen_scale;\n    float sheen_e;\n    float aniso;\n    vec3 t;\n    vec3 b;\n    float at;\n    float ab;\n};\n\nconst float _3890[63] = float[](1.0, 1.0, 1.0, 0.4790000021457672119140625, 0.11699999868869781494140625, 0.01200000010430812835693359375, 0.0, 0.0, 0.0, 1.0, 1.0, 1.0, 0.578000009059906005859375, 0.19300000369548797607421875, 0.0350000001490116119384765625, 0.0030000000260770320892333984375, 0.0, 0.0, 1.0, 1.0, 1.0, 0.6740000247955322265625, 0.3459999859333038330078125, 0.1319999992847442626953125, 0.032999999821186065673828125, 0.0040000001899898052215576171875, 0.0, 0.971000015735626220703125, 0.954999983310699462890625, 0.828999996185302734375, 0.63999998569488525390625, 0.42599999904632568359375, 0.24500000476837158203125, 0.115000002086162567138671875, 0.037000000476837158203125, 0.0030000000260770320892333984375, 0.7469999790191650390625, 0.737999975681304931640625, 0.670000016689300537109375, 0.563000023365020751953125, 0.4309999942779541015625, 0.3039999902248382568359375, 0.1940000057220458984375, 0.1019999980926513671875, 0.0309999994933605194091796875, 0.614000022411346435546875, 0.609000027179718017578125, 0.566999971866607666015625, 0.499000012874603271484375, 0.412000000476837158203125, 0.32400000095367431640625, 0.240999996662139892578125, 0.162000000476837158203125, 0.087999999523162841796875, 0.538999974727630615234375, 0.535000026226043701171875, 0.505999982357025146484375, 0.4569999873638153076171875, 0.393999993801116943359375, 0.328999996185302734375, 0.2660000026226043701171875, 0.203999996185302734375, 0.14200000464916229248046875);\n\nuniform vec4 fa_mesh_fs_params[53];\nuniform vec4 fa_shadows[30];\nuniform vec4 fa_material[2];\nlayout(binding = 0) uniform sampler2D fa_light_tex_fa_shadow_smp;\nlayout(binding = 1) uniform sampler2D fa_tex_fa_smp;\nlayout(binding = 2) uniform sampler2D fa_normal_tex_fa_smp;\nlayout(binding = 3) uniform sampler2D fa_mr_tex_fa_smp;\nlayout(binding = 4) uniform sampler2D fa_occlusion_tex_fa_smp;\nlayout(binding = 5) uniform sampler2D fa_emissive_tex_fa_smp;\nlayout(binding = 6) uniform sampler2D fa_decal_tex_fa_env_smp;\nlayout(binding = 7) uniform sampler2D fa_light_atlas_fa_env_smp;\nlayout(binding = 8) uniform sampler2D fa_shadow_tex_fa_shadow_smp;\nlayout(binding = 9) uniform sampler2D fa_screen_tex_fa_shadow_smp;\nlayout(binding = 10) uniform sampler2D fa_probe_atlas_fa_env_smp;\n\nlayout(location = 0) in vec3 fa_world_pos;\nlayout(location = 5) in vec3 fa_lm;\nlayout(location = 1) in vec3 fa_world_normal;\nlayout(location = 2) in vec4 fa_world_tangent;\nlayout(location = 3) in vec2 fa_uv;\nlayout(location = 4) in vec4 fa_vertex_color;\nlayout(location = 0) out vec4 fa_frag_color;\nvec3 fa_light_tint;\nbool fa_light_is_area;\nint fa_cl_ndir;\nint fa_cl_slot;\nint fa_cl_local;\n\nvoid fa_inst_load()\n{\n}\n\nvec4 fa_light_texel(int t)\n{\n    return texelFetch(fa_light_tex_fa_shadow_smp, ivec2(t & 1023, t >> 10), 0);\n}\n\nvec4 fa_cluster_texel(vec3 world_pos)\n{\n    bool _1397 = fa_mesh_fs_params[19].x < 0.0;\n    bool _1404;\n    if (!_1397)\n    {\n        _1404 = fa_mesh_fs_params[19].w < 1.0;\n    }\n    else\n    {\n        _1404 = _1397;\n    }\n    bool _1412;\n    if (!_1404)\n    {\n        _1412 = fa_mesh_fs_params[18].x < 1.0;\n    }\n    else\n    {\n        _1412 = _1404;\n    }\n    bool _1419;\n    if (!_1412)\n    {\n        _1419 = fa_mesh_fs_params[18].y < 1.0;\n    }\n    else\n    {\n        _1419 = _1412;\n    }\n    bool _1426;\n    if (!_1419)\n    {\n        _1426 = fa_mesh_fs_params[19].y < 1.0;\n    }\n    else\n    {\n        _1426 = _1419;\n    }\n    if (_1426)\n    {\n        return vec4(0.0);\n    }\n    vec4 _1436 = vec4(world_pos, 1.0);\n    float _1442 = dot(fa_mesh_fs_params[16], _1436);\n    if (!(_1442 > 9.9999999747524270787835121154785e-07))\n    {\n        return vec4(0.0);\n    }\n    vec2 _1464 = vec2(dot(fa_mesh_fs_params[14], _1436), dot(fa_mesh_fs_params[15], _1436)) / vec2(_1442);\n    int _1468 = int(fa_mesh_fs_params[18].x);\n    int _1472 = int(fa_mesh_fs_params[18].y);\n    int param = (int(fa_mesh_fs_params[19].x) + (((clamp(int(floor(log2(max(dot(fa_mesh_fs_params[17].xyz, world_pos) + fa_mesh_fs_params[17].w, fa_mesh_fs_params[18].w) / fa_mesh_fs_params[18].w) * fa_mesh_fs_params[18].z)), 0, int(fa_mesh_fs_params[19].y) - 1) * _1472) + clamp(int(floor(((_1464.y * 0.5) + 0.5) * fa_mesh_fs_params[18].y)), 0, _1472 - 1)) * _1468)) + clamp(int(floor(((_1464.x * 0.5) + 0.5) * fa_mesh_fs_params[18].x)), 0, _1468 - 1);\n    return fa_light_texel(param);\n}\n\nivec2 fa_cluster_lookup(vec3 world_pos)\n{\n    vec3 param = world_pos;\n    vec4 _1548 = fa_cluster_texel(param);\n    return ivec2(int(_1548.x), int(_1548.y));\n}\n\nvoid fa_cluster_begin(vec3 world_pos)\n{\n    fa_cl_ndir = int(fa_mesh_fs_params[19].z);\n    vec3 param = world_pos;\n    ivec2 _4724 = fa_cluster_lookup(param);\n    fa_cl_slot = _4724.x;\n    fa_cl_local = _4724.y;\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_linear_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvec3 fa_tex_fix(inout vec3 c, float mode)\n{\n    if (mode > 1.5)\n    {\n        vec3 param = c;\n        vec3 _5101 = fa_linear_to_srgb(param);\n        c = _5101;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            vec3 param_1 = c;\n            vec3 _5109 = fa_srgb_to_linear(param_1);\n            c = _5109;\n        }\n    }\n    return c;\n}\n\nvec3 fa_tangent_normal(SurfaceInput i, vec3 m)\n{\n    vec3 _348;\n    if (i.front_facing)\n    {\n        _348 = i.world_normal;\n    }\n    else\n    {\n        _348 = -i.world_normal;\n    }\n    vec3 _372 = normalize(i.world_tangent.xyz - (_348 * dot(_348, i.world_tangent.xyz)));\n    vec3 _400 = normalize(((_372 * m.x) + ((cross(_348, _372) * i.world_tangent.w) * m.y)) + (_348 * m.z));\n    vec3 _403;\n    if (i.front_facing)\n    {\n        _403 = _400;\n    }\n    else\n    {\n        _403 = -_400;\n    }\n    return _403;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    vec4 base_t = texture(fa_tex_fa_smp, i.uv);\n    float param = fa_mesh_fs_params[6].w;\n    float param_1 = 1.0;\n    vec3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    vec3 _5140 = fa_tex_fix(param_2, param_3);\n    vec4 _6279 = base_t;\n    _6279.x = _5140.x;\n    _6279.y = _5140.y;\n    _6279.z = _5140.z;\n    base_t = _6279;\n    vec4 _5154 = (_6279 * fa_mesh_fs_params[2]) * i.vertex_color;\n    vec3 _6085 = i.world_normal;\n    if (fa_mesh_fs_params[6].z > 0.5)\n    {\n        float param_4 = fa_mesh_fs_params[6].w;\n        float param_5 = 16.0;\n        vec3 param_6 = texture(fa_normal_tex_fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        vec3 _5186 = fa_tex_fix(param_6, param_7);\n        vec3 _5189 = (_5186 * 2.0) - vec3(1.0);\n        vec2 _5194 = _5189.xy * fa_mesh_fs_params[6].x;\n        vec3 _6287 = _5189;\n        _6287.x = _5194.x;\n        _6287.y = _5194.y;\n        SurfaceInput param_8 = i;\n        vec3 param_9 = _6287;\n        _6085 = fa_tangent_normal(param_8, param_9);\n    }\n    vec4 mrt = texture(fa_mr_tex_fa_smp, i.uv);\n    float param_10 = fa_mesh_fs_params[6].w;\n    float param_11 = 64.0;\n    vec3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    vec3 _5222 = fa_tex_fix(param_12, param_13);\n    vec4 _6290 = mrt;\n    _6290.x = _5222.x;\n    _6290.y = _5222.y;\n    _6290.z = _5222.z;\n    mrt = _6290;\n    vec4 _5250 = texture(fa_occlusion_tex_fa_smp, i.uv);\n    float param_14 = fa_mesh_fs_params[6].w;\n    float param_15 = 256.0;\n    vec3 param_16 = _5250.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    vec3 _5261 = fa_tex_fix(param_16, param_17);\n    float param_18 = fa_mesh_fs_params[6].w;\n    float param_19 = 4.0;\n    vec3 param_20 = texture(fa_emissive_tex_fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    vec3 _5291 = fa_tex_fix(param_20, param_21);\n    float _6090 = fa_mesh_fs_params[20].x;\n    float _6091 = fa_mesh_fs_params[20].y;\n    float _6094 = fa_mesh_fs_params[20].z;\n    float _6093 = fa_mesh_fs_params[21].w;\n    float _6096 = fa_mesh_fs_params[22].x;\n    if (fa_mesh_fs_params[22].z > 0.5)\n    {\n        if (mod(fa_mesh_fs_params[22].z, 2.0) > 0.5)\n        {\n            _6090 *= _5261.y;\n            _6091 *= _5261.z;\n            _6093 *= _5250.w;\n        }\n        if (fa_mesh_fs_params[22].z > 1.5)\n        {\n            _6094 *= mrt.x;\n            _6096 *= mrt.w;\n        }\n    }\n    return Surface(_5154.xyz, _5154.w, _6085, clamp(fa_mesh_fs_params[5].x * _5222.z, 0.0, 1.0), clamp(fa_mesh_fs_params[5].y * _5222.y, 0.0500000007450580596923828125, 1.0), 1.0 + (fa_mesh_fs_params[6].y * (_5261.x - 1.0)), fa_mesh_fs_params[3].xyz + (fa_mesh_fs_params[4].xyz * _5291), _6090, _6091, fa_mesh_fs_params[21].xyz, _6093, _6094, fa_mesh_fs_params[20].w, _6096, fa_mesh_fs_params[22].y, fa_mesh_fs_params[23].xyz, fa_mesh_fs_params[30].x, fa_mesh_fs_params[30].y, fa_mesh_fs_params[31].xyz, fa_mesh_fs_params[30].z);\n}\n\nvoid surface(SurfaceInput i, Surface s)\n{\n}\n\nvec4 fa_decal_tile(vec4 rect, vec2 uv, vec2 atlas, vec2 ddx, vec2 ddy)\n{\n    vec2 _1628 = rect.zw - rect.xy;\n    vec2 _1632 = _1628 * atlas;\n    vec2 _1636 = ddx * _1632;\n    vec2 _1640 = ddy * _1632;\n    return textureLod(fa_decal_tex_fa_env_smp, rect.xy + (clamp(uv, vec2(0.0), vec2(1.0)) * _1628), clamp(0.5 * log2(max(max(dot(_1636, _1636), dot(_1640, _1640)), 9.9999999392252902907785028219223e-09)), 0.0, 3.0));\n}\n\nvec3 fa_dc_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_dc_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvoid fa_apply_decals(vec3 world_pos, vec3 geo_normal, inout vec3 albedo, inout vec3 normal)\n{\n    bool _1673 = fa_mesh_fs_params[10].y < 0.5;\n    bool _1680;\n    if (!_1673)\n    {\n        _1680 = fa_mesh_fs_params[10].w < 0.5;\n    }\n    else\n    {\n        _1680 = _1673;\n    }\n    if (_1680)\n    {\n        return;\n    }\n    vec3 _1686 = dFdx(world_pos);\n    vec3 _1689 = dFdy(world_pos);\n    vec3 param = world_pos;\n    vec4 _1693 = fa_cluster_texel(param);\n    int _1697 = int(_1693.w);\n    if (_1697 < 1)\n    {\n        return;\n    }\n    int _1707 = int(fa_mesh_fs_params[10].y + 0.5);\n    int param_1 = _1707;\n    vec4 _1711 = fa_light_texel(param_1);\n    vec2 _1714 = _1711.yz;\n    int _1718 = int(_1711.w);\n    int param_2 = _1707 + 1;\n    vec4 _1723 = fa_light_texel(param_2);\n    float _1724 = _1723.x;\n    int _1730 = int(fa_mesh_fs_params[10].w + 0.5) - 1;\n    int _1734 = int(_1693.z);\n    vec3 _1999;\n    for (int k = 0; k < _1697; k++)\n    {\n        int _1747 = _1734 + k;\n        int param_3 = _1718 + (_1747 >> 2);\n        int _1764 = (_1707 + 2) + (int(fa_light_texel(param_3)[_1747 & 3]) * 7);\n        int param_4 = _1764 + 6;\n        vec4 _1769 = fa_light_texel(param_4);\n        if (((int(_1769.w + 0.5) >> _1730) & 1) == 0)\n        {\n            continue;\n        }\n        int param_5 = _1764;\n        vec4 _1784 = fa_light_texel(param_5);\n        int param_6 = _1764 + 1;\n        vec4 _1789 = fa_light_texel(param_6);\n        int param_7 = _1764 + 2;\n        vec4 _1794 = fa_light_texel(param_7);\n        vec3 _1797 = _1784.xyz;\n        float _1802 = dot(_1797, world_pos) + _1784.w;\n        vec3 _1804 = _1789.xyz;\n        float _1809 = dot(_1804, world_pos) + _1789.w;\n        vec3 _1811 = _1794.xyz;\n        float _1816 = dot(_1811, world_pos) + _1794.w;\n        bool _1821 = abs(_1802) > 0.5;\n        bool _1829;\n        if (!_1821)\n        {\n            _1829 = abs(_1809) > 0.5;\n        }\n        else\n        {\n            _1829 = _1821;\n        }\n        bool _1837;\n        if (!_1829)\n        {\n            _1837 = abs(_1816) > 0.5;\n        }\n        else\n        {\n            _1837 = _1829;\n        }\n        if (_1837)\n        {\n            continue;\n        }\n        float _1852 = clamp(dot(geo_normal, normalize(_1811)) * _1769.z, 0.0, 1.0);\n        if (_1852 <= 0.0)\n        {\n            continue;\n        }\n        float _1872 = (clamp((0.5 - abs(_1816)) * 10.0, 0.0, 1.0) * _1852) * _1769.x;\n        vec2 _1880 = vec2(_1802 + 0.5, 0.5 - _1809);\n        vec2 _1890 = vec2(dot(_1797, _1686), dot(_1804, _1686));\n        vec2 _1900 = vec2(dot(_1797, _1689), dot(_1804, _1689));\n        int param_8 = _1764 + 5;\n        vec4 _1905 = fa_light_texel(param_8);\n        int param_9 = _1764 + 3;\n        vec4 _1910 = fa_light_texel(param_9);\n        int param_10 = _1764 + 4;\n        vec4 _1915 = fa_light_texel(param_10);\n        float tex_a = 1.0;\n        vec3 col = _1905.xyz;\n        bool _1925 = _1910.z > _1910.x;\n        if (_1925)\n        {\n            vec4 param_11 = _1910;\n            vec2 param_12 = _1880;\n            vec2 param_13 = _1714;\n            vec2 param_14 = _1890;\n            vec2 param_15 = _1900;\n            vec4 tx = fa_decal_tile(param_11, param_12, param_13, param_14, param_15);\n            if ((_1724 > 0.5) && (_1724 < 1.5))\n            {\n                vec3 param_16 = tx.xyz;\n                vec3 _1951 = fa_dc_to_linear(param_16);\n                vec4 _6173 = tx;\n                _6173.x = _1951.x;\n                _6173.y = _1951.y;\n                _6173.z = _1951.z;\n                tx = _6173;\n            }\n            col *= tx.xyz;\n            tex_a = tx.w;\n        }\n        albedo = mix(albedo, col, vec3(clamp((_1872 * tex_a) * _1905.w, 0.0, 1.0)));\n        if (_1915.z > _1915.x)\n        {\n            vec4 param_17 = _1915;\n            vec2 param_18 = _1880;\n            vec2 param_19 = _1714;\n            vec2 param_20 = _1890;\n            vec2 param_21 = _1900;\n            vec4 _1995 = fa_decal_tile(param_17, param_18, param_19, param_20, param_21);\n            if (_1724 > 1.5)\n            {\n                vec3 param_22 = _1995.xyz;\n                vec3 _2005 = fa_dc_to_srgb(param_22);\n                _1999 = _2005;\n            }\n            else\n            {\n                _1999 = _1995.xyz;\n            }\n            vec3 _2014 = (_1999 * 2.0) - vec3(1.0);\n            vec2 _2019 = _2014.xy * _1769.y;\n            vec3 _2041 = (normalize(_1797) * _2019.x) + (normalize(_1804) * _2019.y);\n            vec3 _2044 = normalize(normal);\n            normal = normalize(mix(_2044, normalize((_2044 * max(_2014.z, 0.0500000007450580596923828125)) + (_2041 - (_2044 * dot(_2044, _2041)))), vec3(clamp(_1872 * (_1925 ? tex_a : 1.0), 0.0, 1.0))));\n        }\n    }\n}\n\nint fa_light_count()\n{\n    return fa_cl_ndir + fa_cl_local;\n}\n\nLightSample fa_no_light()\n{\n    return LightSample(vec3(0.0, 1.0, 0.0), vec3(0.0), 0.0, 1.0, 0.0, 0);\n}\n\nint fa_cluster_index(int slot, int n)\n{\n    int param = (int(fa_mesh_fs_params[19].x) + int(fa_mesh_fs_params[19].w)) + ((slot + n) >> 2);\n    vec4 t = fa_light_texel(param);\n    return int(t[(slot + n) & 3]);\n}\n\nint fa_cl_light(int n)\n{\n    if (n < fa_cl_ndir)\n    {\n        return n;\n    }\n    int param = fa_cl_slot;\n    int param_1 = n - fa_cl_ndir;\n    return fa_cluster_index(param, param_1);\n}\n\nint fa_light_base(int li)\n{\n    return li * ((fa_mesh_fs_params[1].w > 4.5) ? 8 : 4);\n}\n\nbool fa_light_baked(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 3;\n    return fa_light_texel(param_1).w > 0.5;\n}\n\nfloat fa_baked_keep(int li)\n{\n    float _4694;\n    if (fa_lm.z > 0.5)\n    {\n        _4694 = 0.0;\n    }\n    else\n    {\n        _4694 = 1.0 - clamp(fa_mesh_fs_params[32].w, 0.0, 1.0);\n    }\n    bool _4705 = _4694 < 1.0;\n    bool _4711;\n    if (_4705)\n    {\n        int param = li;\n        _4711 = fa_light_baked(param);\n    }\n    else\n    {\n        _4711 = _4705;\n    }\n    return _4711 ? _4694 : 1.0;\n}\n\nvec3 fa_area_point(vec3 c, vec3 axis, vec3 ru, vec3 uu, float hx, float hy, float shape, vec3 p, vec3 r)\n{\n    bool _646 = dot(r, r) > 0.5;\n    if (shape > 1.5)\n    {\n        vec3 _659 = (c - (ru * hx)) - p;\n        vec3 _665 = ru * (2.0 * hx);\n        float _671 = max(dot(_665, _665), 9.9999999392252902907785028219223e-09);\n        float _675 = dot(_659, _665);\n        float t = clamp((-_675) / _671, 0.0, 1.0);\n        if (_646)\n        {\n            float _690 = dot(r, _665);\n            float _696 = _671 - (_690 * _690);\n            if (abs(_696) > (9.9999997473787516355514526367188e-06 * _671))\n            {\n                t = clamp(((dot(r, _659) * _690) - _675) / _696, 0.0, 1.0);\n            }\n        }\n        return (p + _659) + (_665 * t);\n    }\n    vec3 q = p;\n    float _728 = dot(r, axis);\n    bool _736;\n    if (_646)\n    {\n        _736 = abs(_728) > 9.9999997473787516355514526367188e-05;\n    }\n    else\n    {\n        _736 = _646;\n    }\n    if (_736)\n    {\n        float _746 = dot(c - p, axis) / _728;\n        if (_746 > 0.0)\n        {\n            q = p + (r * _746);\n        }\n    }\n    vec3 _759 = q - c;\n    vec2 xy = vec2(dot(_759, ru), dot(_759, uu));\n    if (shape > 0.5)\n    {\n        float _774 = length(xy);\n        if (_774 > hx)\n        {\n            xy *= (hx / _774);\n        }\n    }\n    else\n    {\n        xy = clamp(xy, vec2(-hx, -hy), vec2(hx, hy));\n    }\n    return (c + (ru * xy.x)) + (uu * xy.y);\n}\n\nvec4 fa_atlas_fetch(vec2 texel)\n{\n    return textureLod(fa_light_atlas_fa_env_smp, texel / vec2(textureSize(fa_light_atlas_fa_env_smp, 0)), 0.0);\n}\n\nvec3 fa_cookie_sample(vec2 tile_origin, vec2 uv)\n{\n    vec2 param = (tile_origin + vec2(1.0)) + (clamp(uv, vec2(0.0), vec2(1.0)) * 254.0);\n    return fa_atlas_fetch(param).xyz;\n}\n\nfloat fa_ies_sample(vec2 tile_origin, vec3 d, vec3 axis, vec3 right, vec3 up)\n{\n    float _566 = dot(d, right);\n    float _570 = dot(d, up);\n    float _581;\n    if (((_566 * _566) + (_570 * _570)) > 1.0000000133514319600180897396058e-10)\n    {\n        _581 = atan(_570, _566) * 0.15915493667125701904296875;\n    }\n    else\n    {\n        _581 = 0.0;\n    }\n    vec2 param = tile_origin + vec2(1.0 + ((_581 - floor(_581)) * 64.0), 1.0 + (acos(clamp(dot(d, axis), -1.0, 1.0)) * 10.18591594696044921875));\n    return fa_atlas_fetch(param).x;\n}\n\nint fa_cube_face(vec3 d)\n{\n    vec3 _415 = abs(d);\n    float _417 = _415.x;\n    float _419 = _415.y;\n    bool _420 = _417 >= _419;\n    bool _428;\n    if (_420)\n    {\n        _428 = _417 >= _415.z;\n    }\n    else\n    {\n        _428 = _420;\n    }\n    int _429;\n    if (_428)\n    {\n        _429 = (d.x > 0.0) ? 0 : 1;\n    }\n    else\n    {\n        int _444;\n        if (_419 >= _415.z)\n        {\n            _444 = (d.y > 0.0) ? 2 : 3;\n        }\n        else\n        {\n            _444 = (d.z > 0.0) ? 4 : 5;\n        }\n        _429 = _444;\n    }\n    return _429;\n}\n\nvoid fa_cube_face_basis(int f, out vec3 fwd, out vec3 up)\n{\n    if (f == 0)\n    {\n        fwd = vec3(1.0, 0.0, 0.0);\n        up = vec3(0.0, 1.0, 0.0);\n    }\n    else\n    {\n        if (f == 1)\n        {\n            fwd = vec3(-1.0, 0.0, 0.0);\n            up = vec3(0.0, 1.0, 0.0);\n        }\n        else\n        {\n            if (f == 2)\n            {\n                fwd = vec3(0.0, 1.0, 0.0);\n                up = vec3(0.0, 0.0, 1.0);\n            }\n            else\n            {\n                if (f == 3)\n                {\n                    fwd = vec3(0.0, -1.0, 0.0);\n                    up = vec3(0.0, 0.0, -1.0);\n                }\n                else\n                {\n                    if (f == 4)\n                    {\n                        fwd = vec3(0.0, 0.0, 1.0);\n                        up = vec3(0.0, 1.0, 0.0);\n                    }\n                    else\n                    {\n                        fwd = vec3(0.0, 0.0, -1.0);\n                        up = vec3(0.0, 1.0, 0.0);\n                    }\n                }\n            }\n        }\n    }\n}\n\nLightSample fa_light_sample_n(int li, vec3 world_pos, vec3 n)\n{\n    int param = li;\n    int _812 = fa_light_base(param);\n    bool _816 = fa_mesh_fs_params[1].w > 4.5;\n    int param_1 = _812;\n    vec4 _820 = fa_light_texel(param_1);\n    int param_2 = _812 + 1;\n    vec4 _825 = fa_light_texel(param_2);\n    float _828 = _825.w;\n    float atten = 1.0;\n    float dist = 0.0;\n    fa_light_tint = vec3(1.0);\n    bool _840 = _816 && (_828 > 2.5);\n    fa_light_is_area = _840;\n    bool _842 = _828 < 0.5;\n    vec3 l;\n    if (_842)\n    {\n        l = normalize(_820.xyz);\n        if (_816)\n        {\n            int param_3 = _812 + 6;\n            vec4 _856 = fa_light_texel(param_3);\n            if (_856.z > 0.5)\n            {\n                int param_4 = _812 + 4;\n                vec4 _866 = fa_light_texel(param_4);\n                int param_5 = _812 + 5;\n                vec4 _871 = fa_light_texel(param_5);\n                vec2 param_6 = _856.xy;\n                vec2 param_7 = fract(vec2(dot(world_pos, _866.xyz) * _866.w, (-dot(world_pos, _871.xyz)) * _871.w) + vec2(0.5));\n                fa_light_tint = fa_cookie_sample(param_6, param_7);\n            }\n        }\n    }\n    else\n    {\n        vec3 _901 = _820.xyz;\n        vec3 _903 = _901 - world_pos;\n        vec3 to_light = _903;\n        float _906 = length(_903);\n        float reach = _906;\n        bool front = true;\n        if (_840)\n        {\n            int param_8 = _812 + 7;\n            reach = max(_906 - fa_light_texel(param_8).w, 0.0);\n            int param_9 = _812 + 4;\n            vec4 _930 = fa_light_texel(param_9);\n            int param_10 = _812 + 5;\n            vec4 _935 = fa_light_texel(param_10);\n            int param_11 = _812 + 6;\n            vec4 _940 = fa_light_texel(param_11);\n            float _941 = _940.w;\n            int param_12 = _812 + 2;\n            vec3 _948 = normalize(fa_light_texel(param_12).xyz);\n            bool _950 = _941 > 1.5;\n            bool _958;\n            if (!_950)\n            {\n                _958 = dot(_948, to_light) < 0.0;\n            }\n            else\n            {\n                _958 = _950;\n            }\n            front = _958;\n            vec3 r = vec3(0.0);\n            vec3 _967 = fa_mesh_fs_params[0].xyz - world_pos;\n            bool _971 = dot(n, n) > 0.5;\n            bool _979;\n            if (_971)\n            {\n                _979 = dot(_967, _967) > 9.9999999600419720025001879548654e-13;\n            }\n            else\n            {\n                _979 = _971;\n            }\n            if (_979)\n            {\n                r = reflect(-normalize(_967), normalize(n));\n            }\n            vec3 param_13 = _901;\n            vec3 param_14 = _948;\n            vec3 param_15 = _930.xyz;\n            vec3 param_16 = _935.xyz;\n            float param_17 = _930.w;\n            float param_18 = _935.w;\n            float param_19 = _941;\n            vec3 param_20 = world_pos;\n            vec3 param_21 = r;\n            to_light = fa_area_point(param_13, param_14, param_15, param_16, param_17, param_18, param_19, param_20, param_21) - world_pos;\n        }\n        float _1015 = length(to_light);\n        dist = _1015;\n        l = to_light / vec3(max(_1015, 9.9999997473787516355514526367188e-05));\n        float _1029 = reach / max(_820.w, 0.001000000047497451305389404296875);\n        float _1035 = clamp(1.0 - (_1029 * _1029), 0.0, 1.0);\n        float _1037;\n        if (front)\n        {\n            _1037 = _1035 * _1035;\n        }\n        else\n        {\n            _1037 = 0.0;\n        }\n        atten = _1037;\n        bool _1048 = _828 < 2.5;\n        if ((_828 > 1.5) && _1048)\n        {\n            int param_22 = _812 + 2;\n            vec4 _1056 = fa_light_texel(param_22);\n            float _1066 = _1056.w;\n            int param_23 = _812 + 3;\n            vec4 _1071 = fa_light_texel(param_23);\n            float _1072 = _1071.x;\n            float cos_inner = _1072;\n            if (_1072 > 1.5)\n            {\n                cos_inner = mix(_1066, 1.0, 0.25);\n            }\n            atten *= smoothstep(_1066, cos_inner, dot(-l, normalize(_1056.xyz)));\n        }\n        if (_816 && (_828 < 1.5))\n        {\n            int param_24 = _812 + 6;\n            vec4 _1096 = fa_light_texel(param_24);\n            if (_1096.z > 0.5)\n            {\n                vec3 _1104 = -to_light;\n                int param_25 = _812 + 4;\n                int param_26 = _812 + 5;\n                vec3 _1118 = fa_light_texel(param_25).xyz;\n                vec3 _1122 = fa_light_texel(param_26).xyz;\n                vec3 _1131 = vec3(dot(_1104, _1118), dot(_1104, _1122), dot(_1104, cross(_1118, _1122)));\n                vec3 param_27 = _1131;\n                int _1135 = fa_cube_face(param_27);\n                int param_28 = _1135;\n                vec3 param_29;\n                vec3 param_30;\n                fa_cube_face_basis(param_28, param_29, param_30);\n                vec2 _1162 = vec2(dot(_1131, cross(param_29, param_30)), dot(_1131, param_30)) / vec2(max(dot(_1131, param_29), 9.9999997473787516355514526367188e-05));\n                int _1166 = _1135 / 3;\n                vec2 param_31 = _1096.xy + (vec2(float(_1135 - (_1166 * 3)), float(_1166)) * 256.0);\n                vec2 param_32 = vec2(0.5 + (0.5 * _1162.x), 0.5 - (0.5 * _1162.y));\n                fa_light_tint = fa_cookie_sample(param_31, param_32);\n            }\n            int param_33 = _812 + 7;\n            vec4 _1196 = fa_light_texel(param_33);\n            if (_1196.z > 0.5)\n            {\n                int param_34 = _812 + 2;\n                int param_35 = _812 + 4;\n                int param_36 = _812 + 5;\n                vec2 param_37 = _1196.xy;\n                vec3 param_38 = -l;\n                vec3 param_39 = normalize(fa_light_texel(param_34).xyz);\n                vec3 param_40 = fa_light_texel(param_35).xyz;\n                vec3 param_41 = fa_light_texel(param_36).xyz;\n                atten *= fa_ies_sample(param_37, param_38, param_39, param_40, param_41);\n            }\n        }\n        else\n        {\n            if (_816 && _1048)\n            {\n                int param_42 = _812 + 6;\n                vec4 _1243 = fa_light_texel(param_42);\n                int param_43 = _812 + 7;\n                vec4 _1248 = fa_light_texel(param_43);\n                bool _1251 = _1243.z > 0.5;\n                bool _1258;\n                if (!_1251)\n                {\n                    _1258 = _1248.z > 0.5;\n                }\n                else\n                {\n                    _1258 = _1251;\n                }\n                if (_1258)\n                {\n                    int param_44 = _812 + 2;\n                    vec4 _1265 = fa_light_texel(param_44);\n                    vec3 _1269 = normalize(_1265.xyz);\n                    int param_45 = _812 + 4;\n                    vec4 _1274 = fa_light_texel(param_45);\n                    int param_46 = _812 + 5;\n                    vec4 _1279 = fa_light_texel(param_46);\n                    if (_1251)\n                    {\n                        vec3 _1287 = -to_light;\n                        float _1294 = _1265.w;\n                        float _1310 = 0.5 / max(dot(_1287, _1269) * (sqrt(max(1.0 - (_1294 * _1294), 0.0)) / max(_1294, 0.001000000047497451305389404296875)), 9.9999997473787516355514526367188e-05);\n                        vec2 param_47 = _1243.xy;\n                        vec2 param_48 = vec2(0.5 + (dot(_1287, _1274.xyz) * _1310), 0.5 - (dot(_1287, _1279.xyz) * _1310));\n                        fa_light_tint = fa_cookie_sample(param_47, param_48);\n                    }\n                    if (_1248.z > 0.5)\n                    {\n                        vec2 param_49 = _1248.xy;\n                        vec3 param_50 = -l;\n                        vec3 param_51 = _1269;\n                        vec3 param_52 = _1274.xyz;\n                        vec3 param_53 = _1279.xyz;\n                        atten *= fa_ies_sample(param_49, param_50, param_51, param_52, param_53);\n                    }\n                }\n            }\n        }\n    }\n    vec3 _5891 = _825.xyz * atten;\n    if (_816)\n    {\n        _5891 *= fa_light_tint;\n    }\n    int _1379;\n    if (_842)\n    {\n        _1379 = 0;\n    }\n    else\n    {\n        _1379 = ((_828 > 1.5) && (_828 < 2.5)) ? 2 : 1;\n    }\n    return LightSample(l, _5891, atten, 1.0, dist, _1379);\n}\n\nLightSample fa_light_unshadowed(int n, SurfaceInput i)\n{\n    bool _4923 = n < 0;\n    bool _4930;\n    if (!_4923)\n    {\n        _4930 = n >= fa_light_count();\n    }\n    else\n    {\n        _4930 = _4923;\n    }\n    if (_4930)\n    {\n        return fa_no_light();\n    }\n    int param = n;\n    int _4938 = fa_cl_light(param);\n    int param_1 = _4938;\n    float _4942 = fa_baked_keep(param_1);\n    if (_4942 <= 0.0)\n    {\n        return fa_no_light();\n    }\n    int param_2 = _4938;\n    vec3 param_3 = i.world_pos;\n    vec3 param_4 = i.world_normal;\n    LightSample _4958 = fa_light_sample_n(param_2, param_3, param_4);\n    return LightSample(_4958.direction, _4958.color * _4942, _4958.attenuation * _4942, _4958.shadow, _4958._distance, _4958.type);\n}\n\nfloat fa_light_type(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 1;\n    return fa_light_texel(param_1).w;\n}\n\nfloat fa_shadow_depth(inout vec2 uv, vec4 rect)\n{\n    uv = clamp(uv, rect.xy, rect.zw);\n    return textureLod(fa_shadow_tex_fa_shadow_smp, uv, 0.0).x;\n}\n\nfloat fa_shadow_fetch(vec2 uv, vec4 rect, vec3 conv)\n{\n    vec2 param = uv;\n    vec4 param_1 = rect;\n    float _2168 = fa_shadow_depth(param, param_1);\n    float _2172;\n    if (conv.x < 0.5)\n    {\n        _2172 = _2168;\n    }\n    else\n    {\n        _2172 = (conv.y * conv.z) / (conv.z - (_2168 * (conv.z - conv.y)));\n    }\n    return _2172;\n}\n\nfloat fa_shadow_noise()\n{\n    return fract(52.98291778564453125 * fract(dot(gl_FragCoord.xy, vec2(0.067110560834407806396484375, 0.005837149918079376220703125))));\n}\n\nvec2 fa_shadow_vogel_turn(vec2 d)\n{\n    return vec2((d.x * (-0.737368881702423095703125)) - (d.y * 0.675490319728851318359375), (d.y * (-0.737368881702423095703125)) + (d.x * 0.675490319728851318359375));\n}\n\nfloat fa_shadow_filter(vec2 uv, vec4 rect, float zr, float texel_m, float unit, float reach, float plane, vec3 conv, int mode, float k)\n{\n    if (mode == 1)\n    {\n        vec2 param = uv;\n        vec4 param_1 = rect;\n        vec3 param_2 = conv;\n        return float(zr <= fa_shadow_fetch(param, param_1, param_2));\n    }\n    float _2218 = fa_shadow_noise() * 6.283185482025146484375;\n    vec2 _2224 = vec2(cos(_2218), sin(_2218));\n    vec2 dir = _2224;\n    float radius = 1.5;\n    if (mode == 2)\n    {\n        float _2233;\n        if (k < 0.0)\n        {\n            _2233 = (-k) / max(zr, 0.100000001490116119384765625);\n        }\n        else\n        {\n            _2233 = k;\n        }\n        float _2252 = clamp((_2233 * reach) / texel_m, 3.0, 12.0);\n        float sum = 0.0;\n        float cnt = 0.0;\n        for (int i = 0; i < 16; i++)\n        {\n            float _2271 = sqrt((float(i) + 0.5) * 0.0625) * _2252;\n            vec2 param_3 = uv + (dir * (fa_shadows[26].zw * _2271));\n            vec4 param_4 = rect;\n            vec3 param_5 = conv;\n            float _2285 = fa_shadow_fetch(param_3, param_4, param_5);\n            if (_2285 < (zr - (_2271 * plane)))\n            {\n                sum += _2285;\n                cnt += 1.0;\n            }\n            vec2 param_6 = dir;\n            dir = fa_shadow_vogel_turn(param_6);\n        }\n        if (cnt < 0.5)\n        {\n            return 1.0;\n        }\n        float _2313 = sum / cnt;\n        float _2323;\n        if (k < 0.0)\n        {\n            _2323 = (-k) / max(_2313, 0.0500000007450580596923828125);\n        }\n        else\n        {\n            _2323 = k;\n        }\n        radius = clamp(((max(zr - _2313, 0.0) * unit) * _2323) / texel_m, 1.5, 16.0);\n        dir = _2224;\n    }\n    float lit = 0.0;\n    int _2349 = (mode == 2) ? 24 : 16;\n    for (int i_1 = 0; i_1 < _2349; i_1++)\n    {\n        float _2368 = sqrt((float(i_1) + 0.5) / float(_2349)) * radius;\n        vec2 param_7 = uv + (dir * (fa_shadows[26].zw * _2368));\n        vec4 param_8 = rect;\n        vec3 param_9 = conv;\n        lit += float((zr - (_2368 * plane)) <= fa_shadow_fetch(param_7, param_8, param_9));\n        vec2 param_10 = dir;\n        dir = fa_shadow_vogel_turn(param_10);\n    }\n    return lit / float(_2349);\n}\n\nfloat fa_shadow_local(int li, vec3 lpos, vec3 world, vec3 n, vec3 l)\n{\n    bool _2573 = fa_mesh_fs_params[5].z < 0.5;\n    bool _2580;\n    if (!_2573)\n    {\n        _2580 = fa_shadows[29].x < 0.5;\n    }\n    else\n    {\n        _2580 = _2573;\n    }\n    if (_2580)\n    {\n        return 1.0;\n    }\n    int param = (int(fa_shadows[29].x + 0.5) - 1) + li;\n    vec4 _2593 = fa_light_texel(param);\n    float _2594 = _2593.x;\n    if (_2594 < 0.0)\n    {\n        return 1.0;\n    }\n    int _2603 = int(_2594 + 0.5);\n    int param_1 = _2603;\n    vec4 _2607 = fa_light_texel(param_1);\n    int param_2 = _2603 + 1;\n    vec4 _2612 = fa_light_texel(param_2);\n    float fade = 1.0;\n    float _2615 = _2607.y;\n    if (_2615 > 0.0)\n    {\n        float _2632 = 1.0 - smoothstep(0.75 * _2615, _2615, length(world - fa_shadows[27].xyz));\n        fade = _2632;\n        if (_2632 <= 0.0)\n        {\n            return 1.0;\n        }\n    }\n    int face = 0;\n    if (_2607.x > 1.5)\n    {\n        vec3 param_3 = world - lpos;\n        face = fa_cube_face(param_3);\n    }\n    int _2656 = (_2603 + 2) + (face * 6);\n    int param_4 = _2656;\n    int param_5 = _2656 + 1;\n    int param_6 = _2656 + 3;\n    vec4 _2670 = fa_light_texel(param_6);\n    int param_7 = _2656 + 4;\n    vec4 _2675 = fa_light_texel(param_7);\n    int param_8 = _2656 + 5;\n    vec4 _2680 = fa_light_texel(param_8);\n    float _2692 = _2680.x * max(dot(_2670, vec4(world, 1.0)), 0.001000000047497451305389404296875);\n    float _2697 = clamp(dot(n, l), 0.0, 1.0);\n    float _2720 = clamp(dot(n, _2670.xyz), -1.0, 1.0);\n    float _2739 = min(sqrt(1.0 - (_2720 * _2720)) / max(abs(dot(n, world - lpos)) / max(dot(_2670, vec4(world, 1.0)), 0.001000000047497451305389404296875), 0.20000000298023223876953125), 4.0);\n    float _2742 = _2612.y;\n    float _2744;\n    if (_2742 > 0.0)\n    {\n        _2744 = _2742;\n    }\n    else\n    {\n        _2744 = 1.5 * _2692;\n    }\n    vec4 _2764 = vec4(world + (n * (_2744 * sqrt(1.0 - (_2697 * _2697)))), 1.0);\n    float _2768 = dot(_2670, _2764);\n    float _2771 = _2680.y;\n    if (_2768 < _2771)\n    {\n        return 1.0;\n    }\n    vec2 _2786 = vec2(dot(fa_light_texel(param_4), _2764), dot(fa_light_texel(param_5), _2764)) / vec2(_2768);\n    float _2788 = _2786.x;\n    bool _2791 = _2788 < _2675.x;\n    bool _2800;\n    if (!_2791)\n    {\n        _2800 = _2788 > _2675.z;\n    }\n    else\n    {\n        _2800 = _2791;\n    }\n    bool _2809;\n    if (!_2800)\n    {\n        _2809 = _2786.y < _2675.y;\n    }\n    else\n    {\n        _2809 = _2800;\n    }\n    bool _2818;\n    if (!_2809)\n    {\n        _2818 = _2786.y > _2675.w;\n    }\n    else\n    {\n        _2818 = _2809;\n    }\n    if (_2818)\n    {\n        return 1.0;\n    }\n    float _2824 = _2612.x;\n    float _2826;\n    if (_2824 > 0.0)\n    {\n        _2826 = _2824;\n    }\n    else\n    {\n        _2826 = 1.5 * _2692;\n    }\n    vec2 param_9 = _2786;\n    vec4 param_10 = _2675;\n    float param_11 = _2768 - (_2826 * (1.0 + (0.5 * _2739)));\n    float param_12 = _2692;\n    float param_13 = 1.0;\n    float param_14 = _2680.z * 0.25;\n    float param_15 = (_2692 * min(_2739, 3.0)) * 0.5;\n    vec3 param_16 = vec3(1.0, _2771, _2680.z);\n    int param_17 = int(_2607.z + 0.5);\n    float param_18 = _2607.w;\n    return mix(1.0, fa_shadow_filter(param_9, param_10, param_11, param_12, param_13, param_14, param_15, param_16, param_17, param_18), fade);\n}\n\nfloat fa_shadow_split_at(int i)\n{\n    float _2111;\n    if (i == 0)\n    {\n        _2111 = fa_shadows[24].x;\n    }\n    else\n    {\n        float _2127;\n        if (i == 1)\n        {\n            _2127 = fa_shadows[24].y;\n        }\n        else\n        {\n            float _2135;\n            if (i == 2)\n            {\n                _2135 = fa_shadows[24].z;\n            }\n            else\n            {\n                _2135 = fa_shadows[24].w;\n            }\n            _2127 = _2135;\n        }\n        _2111 = _2127;\n    }\n    return _2111;\n}\n\nfloat fa_shadow_cascade(int ci, vec3 world, vec3 n, vec3 l)\n{\n    float _2414 = max(fa_shadows[ci * 1 + 20].y, 0.001000000047497451305389404296875);\n    float _2419 = clamp(dot(n, l), 0.0, 1.0);\n    float _2425 = sqrt(1.0 - (_2419 * _2419));\n    float _2433 = min(_2425 / max(_2419, 0.20000000298023223876953125), 4.0);\n    float _2438;\n    if (fa_shadows[26].y > 0.0)\n    {\n        _2438 = fa_shadows[26].y;\n    }\n    else\n    {\n        _2438 = 1.5 * fa_shadows[ci * 1 + 20].x;\n    }\n    vec4 _2463 = mat4(fa_shadows[ci * 4 + 0], fa_shadows[ci * 4 + 1], fa_shadows[ci * 4 + 2], fa_shadows[ci * 4 + 3]) * vec4(world + (n * (_2438 * _2425)), 1.0);\n    float _2470 = _2463.x;\n    bool _2473 = _2470 < fa_shadows[ci * 1 + 16].x;\n    bool _2482;\n    if (!_2473)\n    {\n        _2482 = _2470 > fa_shadows[ci * 1 + 16].z;\n    }\n    else\n    {\n        _2482 = _2473;\n    }\n    bool _2491;\n    if (!_2482)\n    {\n        _2491 = _2463.y < fa_shadows[ci * 1 + 16].y;\n    }\n    else\n    {\n        _2491 = _2482;\n    }\n    bool _2500;\n    if (!_2491)\n    {\n        _2500 = _2463.y > fa_shadows[ci * 1 + 16].w;\n    }\n    else\n    {\n        _2500 = _2491;\n    }\n    bool _2507;\n    if (!_2500)\n    {\n        _2507 = _2463.z > 1.0;\n    }\n    else\n    {\n        _2507 = _2500;\n    }\n    if (_2507)\n    {\n        return -1.0;\n    }\n    float _2515;\n    if (fa_shadows[26].x > 0.0)\n    {\n        _2515 = fa_shadows[26].x;\n    }\n    else\n    {\n        _2515 = 1.5 * fa_shadows[ci * 1 + 20].x;\n    }\n    vec2 param = _2463.xy;\n    vec4 param_1 = fa_shadows[ci * 1 + 16];\n    float param_2 = _2463.z - ((_2515 * (1.0 + (0.5 * _2433))) / _2414);\n    float param_3 = fa_shadows[ci * 1 + 20].x;\n    float param_4 = _2414;\n    float param_5 = _2414 * 0.25;\n    float param_6 = ((fa_shadows[ci * 1 + 20].x * min(_2433, 3.0)) * 0.5) / _2414;\n    vec3 param_7 = vec3(0.0);\n    int param_8 = int(fa_shadows[25].z + 0.5);\n    float param_9 = fa_shadows[25].w;\n    return fa_shadow_filter(param, param_1, param_2, param_3, param_4, param_5, param_6, param_7, param_8, param_9);\n}\n\nfloat fa_shadow_sun(vec3 world, vec3 n, vec3 l)\n{\n    if (fa_mesh_fs_params[5].z < 0.5)\n    {\n        return 1.0;\n    }\n    int _2893 = int(fa_shadows[25].x + 0.5);\n    if (_2893 < 1)\n    {\n        return 1.0;\n    }\n    float _2908 = dot(world - fa_shadows[27].xyz, fa_shadows[28].xyz);\n    int param = _2893 - 1;\n    if (_2908 > fa_shadow_split_at(param))\n    {\n        return 1.0;\n    }\n    int ci = 0;\n    bool _2920 = _2893 > 1;\n    bool _2927;\n    if (_2920)\n    {\n        _2927 = _2908 > fa_shadows[24].x;\n    }\n    else\n    {\n        _2927 = _2920;\n    }\n    if (_2927)\n    {\n        ci = 1;\n    }\n    bool _2931 = _2893 > 2;\n    bool _2938;\n    if (_2931)\n    {\n        _2938 = _2908 > fa_shadows[24].y;\n    }\n    else\n    {\n        _2938 = _2931;\n    }\n    if (_2938)\n    {\n        ci = 2;\n    }\n    bool _2942 = _2893 > 3;\n    bool _2949;\n    if (_2942)\n    {\n        _2949 = _2908 > fa_shadows[24].z;\n    }\n    else\n    {\n        _2949 = _2942;\n    }\n    if (_2949)\n    {\n        ci = 3;\n    }\n    float s = -1.0;\n    float s2 = -1.0;\n    float t = 0.0;\n    int _2960 = min(_2893, 4);\n    float _3001;\n    for (int c = ci; c < _2960; c++)\n    {\n        int param_1 = c;\n        vec3 param_2 = world;\n        vec3 param_3 = n;\n        vec3 param_4 = l;\n        float _2980 = fa_shadow_cascade(param_1, param_2, param_3, param_4);\n        if (s >= 0.0)\n        {\n            s2 = _2980;\n            break;\n        }\n        if (_2980 < 0.0)\n        {\n            continue;\n        }\n        s = _2980;\n        ci = c;\n        if (fa_shadows[25].y > 0.0)\n        {\n            if (ci > 0)\n            {\n                int param_5 = ci - 1;\n                _3001 = fa_shadow_split_at(param_5);\n            }\n            else\n            {\n                _3001 = fa_shadows[28].w;\n            }\n            int param_6 = ci;\n            float _3020 = fa_shadows[25].y * max(fa_shadow_split_at(param_6) - _3001, 9.9999997473787516355514526367188e-05);\n            int param_7 = ci;\n            t = clamp((_2908 - (fa_shadow_split_at(param_7) - _3020)) / _3020, 0.0, 1.0);\n        }\n        if (t <= 0.0)\n        {\n            break;\n        }\n    }\n    if (s < 0.0)\n    {\n        return 1.0;\n    }\n    if (t > 0.0)\n    {\n        float _3052;\n        if ((ci + 1) < _2893)\n        {\n            _3052 = (s2 < 0.0) ? s : s2;\n        }\n        else\n        {\n            _3052 = 1.0;\n        }\n        s = mix(s, _3052, t);\n    }\n    return s;\n}\n\nfloat fa_shadow_factor(vec3 n, vec3 l)\n{\n    vec3 param = fa_world_pos;\n    vec3 param_1 = n;\n    vec3 param_2 = l;\n    return fa_shadow_sun(param, param_1, param_2);\n}\n\nfloat fa_contact_shadow(int li, vec3 world, vec3 gn, vec3 l, float dist)\n{\n    bool _4430 = fa_mesh_fs_params[24].x < 0.5;\n    bool _4437;\n    if (!_4430)\n    {\n        _4437 = fa_shadows[29].x < 0.5;\n    }\n    else\n    {\n        _4437 = _4430;\n    }\n    if (_4437)\n    {\n        return 1.0;\n    }\n    int param = (int(fa_shadows[29].x + 0.5) - 1) + li;\n    vec4 _4450 = fa_light_texel(param);\n    float _4451 = _4450.y;\n    float len = _4451;\n    if (_4451 <= 0.0)\n    {\n        return 1.0;\n    }\n    float _4463 = length(world - fa_mesh_fs_params[0].xyz);\n    float _4473 = 1.0 - smoothstep(0.5 * fa_mesh_fs_params[25].x, fa_mesh_fs_params[25].x, _4463);\n    if (_4473 <= 0.0)\n    {\n        return 1.0;\n    }\n    float _4479 = len;\n    float _4482 = min(_4479, 0.89999997615814208984375 * dist);\n    len = _4482;\n    float _4487 = 0.004999999888241291046142578125 + (0.0030000000260770320892333984375 * _4463);\n    float _4492 = _4487 + (0.5 * _4482);\n    vec3 _4498 = world + (gn * _4487);\n    float _4500 = fa_shadow_noise();\n    float occ = 0.0;\n    float _4564;\n    for (int k = 0; k < 12; k++)\n    {\n        float _4515 = (float(k) + _4500) * 0.083333335816860198974609375;\n        vec3 _4523 = _4498 + (l * (_4515 * len));\n        vec4 _4529 = vec4(_4523, 1.0);\n        float _4535 = dot(fa_mesh_fs_params[28], _4529);\n        if (_4535 < 9.9999997473787516355514526367188e-05)\n        {\n            break;\n        }\n        vec2 _4555 = vec2(dot(fa_mesh_fs_params[26], _4529), dot(fa_mesh_fs_params[27], _4529)) / vec2(_4535);\n        float _4559 = _4555.x * 0.5;\n        float _4560 = _4559 + 0.5;\n        if (fa_mesh_fs_params[24].y > 0.5)\n        {\n            _4564 = (_4555.y * 0.5) + 0.5;\n        }\n        else\n        {\n            _4564 = 0.5 - (_4555.y * 0.5);\n        }\n        bool _4580 = _4560 < 0.0;\n        bool _4587;\n        if (!_4580)\n        {\n            _4587 = _4560 >= 1.0;\n        }\n        else\n        {\n            _4587 = _4580;\n        }\n        bool _4594;\n        if (!_4587)\n        {\n            _4594 = _4564 < 0.0;\n        }\n        else\n        {\n            _4594 = _4587;\n        }\n        bool _4601;\n        if (!_4594)\n        {\n            _4601 = _4564 >= 1.0;\n        }\n        else\n        {\n            _4601 = _4594;\n        }\n        if (_4601)\n        {\n            break;\n        }\n        vec4 _4628 = texelFetch(fa_screen_tex_fa_shadow_smp, clamp(ivec2(vec2(_4560, _4564) * fa_mesh_fs_params[24].zw), ivec2(0), ivec2(fa_mesh_fs_params[24].zw) - ivec2(1)), 0);\n        if (_4628.w < 0.5)\n        {\n            continue;\n        }\n        float _4647 = (dot(fa_mesh_fs_params[29].xyz, _4523) + fa_mesh_fs_params[29].w) - _4628.x;\n        if ((_4647 > _4487) && (_4647 < _4492))\n        {\n            occ = max(occ, (1.0 - (_4515 * _4515)) * smoothstep(0.0, 0.0500000007450580596923828125, min(min(_4560, 0.5 - _4559), min(_4564, 1.0 - _4564))));\n        }\n    }\n    return 1.0 - (occ * _4473);\n}\n\nLightSample fa_light_shadowed(int li, vec3 world_pos, vec3 gn)\n{\n    int param = li;\n    float _4750 = fa_baked_keep(param);\n    if (_4750 <= 0.0)\n    {\n        int param_1 = li;\n        return LightSample(vec3(0.0, 1.0, 0.0), vec3(0.0), 0.0, 1.0, 0.0, int(fa_light_type(param_1) + 0.5));\n    }\n    int param_2 = li;\n    vec3 param_3 = world_pos;\n    vec3 param_4 = gn;\n    LightSample _4776 = fa_light_sample_n(param_2, param_3, param_4);\n    vec3 _6037 = _4776.color;\n    float _6038 = _4776.attenuation;\n    float _6039 = _4776.shadow;\n    bool _4779 = _4776.type == 0;\n    if (_4779 && (li == 0))\n    {\n        vec3 param_5 = gn;\n        vec3 param_6 = _4776.direction;\n        float _4790 = fa_shadow_factor(param_5, param_6);\n        _6039 = _4790;\n        _6037 *= _4790;\n    }\n    else\n    {\n        bool _4801 = _4776.type != 0;\n        bool _4807;\n        if (_4801)\n        {\n            _4807 = _6038 > 0.0;\n        }\n        else\n        {\n            _4807 = _4801;\n        }\n        if (_4807)\n        {\n            int param_7 = li;\n            int param_8 = fa_light_base(param_7);\n            int param_9 = li;\n            vec3 param_10 = fa_light_texel(param_8).xyz;\n            vec3 param_11 = world_pos;\n            vec3 param_12 = gn;\n            vec3 param_13 = _4776.direction;\n            float _4826 = fa_shadow_local(param_9, param_10, param_11, param_12, param_13);\n            _6039 = _4826;\n            _6037 *= _4826;\n        }\n    }\n    bool _4836 = fa_mesh_fs_params[24].x > 0.5;\n    bool _4842;\n    if (_4836)\n    {\n        _4842 = _6038 > 0.0;\n    }\n    else\n    {\n        _4842 = _4836;\n    }\n    if (_4842)\n    {\n        float _4849;\n        if (_4779)\n        {\n            _4849 = 1000000000.0;\n        }\n        else\n        {\n            _4849 = _4776._distance;\n        }\n        int param_14 = li;\n        vec3 param_15 = world_pos;\n        vec3 param_16 = gn;\n        vec3 param_17 = _4776.direction;\n        float param_18 = _4849;\n        float _4867 = fa_contact_shadow(param_14, param_15, param_16, param_17, param_18);\n        _6039 *= _4867;\n        _6037 *= _4867;\n    }\n    float _4880 = _6038;\n    float _4881 = _4880 * _4750;\n    _6038 = _4881;\n    vec3 _4885 = _6037;\n    vec3 _4886 = _4885 * _4750;\n    _6037 = _4886;\n    return LightSample(_4776.direction, _4886, _4881, _6039, _4776._distance, _4776.type);\n}\n\nLightSample fa_light(int n, SurfaceInput i)\n{\n    bool _4897 = n < 0;\n    bool _4904;\n    if (!_4897)\n    {\n        _4904 = n >= fa_light_count();\n    }\n    else\n    {\n        _4904 = _4897;\n    }\n    if (_4904)\n    {\n        return fa_no_light();\n    }\n    int param = n;\n    int param_1 = fa_cl_light(param);\n    vec3 param_2 = i.world_pos;\n    vec3 param_3 = i.world_normal;\n    LightSample _4919 = fa_light_shadowed(param_1, param_2, param_3);\n    return _4919;\n}\n\nfloat fa_sheen_albedo(float ndv, float rough)\n{\n    float _3815 = min(sqrt(max(rough - 0.100000001490116119384765625, 0.0) * 1.111111164093017578125) * 6.0, 5.999000072479248046875);\n    float _3823 = min(sqrt(clamp(ndv, 0.0, 1.0)) * 8.0, 7.999000072479248046875);\n    int _3826 = int(_3815);\n    int _3829 = int(_3823);\n    float _3839 = _3823 - float(_3829);\n    int _3895 = (_3826 * 9) + _3829;\n    int _3915 = ((_3826 + 1) * 9) + _3829;\n    return mix(mix(_3890[_3895], _3890[_3895 + 1], _3839), mix(_3890[_3915], _3890[_3915 + 1], _3839), _3815 - float(_3826));\n}\n\nFaLayers fa_layers_setup(SurfaceInput i, Surface s, vec3 n, vec3 v, float metallic, float roughness, inout vec3 f0)\n{\n    bool _5903 = false;\n    float _5904 = 1.0;\n    float _5905 = 1.0;\n    float _5906 = 1.0;\n    float _5907 = 0.0;\n    float _5908 = 0.0;\n    float _5909 = 0.0;\n    float _5910 = 0.0;\n    float _5912 = 1.0;\n    bool _5913 = false;\n    vec3 _5914 = vec3(0.0);\n    float _5915 = 1.0;\n    float _5916 = 1.0;\n    float _5917 = 1.0;\n    float _5918 = 0.0;\n    float _5919 = 0.0;\n    vec3 _5920 = vec3(1.0, 0.0, 0.0);\n    vec3 _5921 = vec3(0.0, 0.0, 1.0);\n    float _5922 = 1.0;\n    float _5923 = 1.0;\n    float _3966 = clamp(s.specular, 0.0, 1.0);\n    float _3970 = clamp(s.ior, 1.0, 3.0);\n    bool _3975 = (_3966 != 1.0) || (_3970 != 1.5);\n    bool _3984;\n    if (!_3975)\n    {\n        _3984 = any(notEqual(s.specular_color, vec3(1.0)));\n    }\n    else\n    {\n        _3984 = _3975;\n    }\n    if (_3984)\n    {\n        float _3992 = (_3970 - 1.0) / (_3970 + 1.0);\n        f0 = mix(min(vec3(_3992 * _3992) * max(s.specular_color, vec3(0.0)), vec3(1.0)) * _3966, s.albedo, vec3(metallic));\n        _5904 = mix(_3966, 1.0, metallic);\n        _5903 = true;\n    }\n    float _4019 = clamp(s.clearcoat, 0.0, 1.0);\n    if (_4019 > 0.0)\n    {\n        float _4027 = clamp(s.clearcoat_roughness, 0.0500000007450580596923828125, 1.0);\n        _5907 = _4019;\n        _5908 = _4027;\n        float _4034 = _4027 * _4027;\n        _5909 = _4034;\n        _5910 = _4034 * _4034;\n        float _4046 = max(dot(i.world_normal, v), 9.9999997473787516355514526367188e-05);\n        _5912 = _4046;\n        _5905 = 1.0 - (_4019 * (0.039999999105930328369140625 + (0.959999978542327880859375 * pow(clamp(1.0 - _4046, 0.0, 1.0), 5.0))));\n        _5903 = true;\n    }\n    vec3 _4065 = max(s.sheen_color, vec3(0.0));\n    float _4074 = max(_4065.x, max(_4065.y, _4065.z));\n    if (_4074 > 0.0)\n    {\n        float _4082 = clamp(s.sheen_roughness, 0.100000001490116119384765625, 1.0);\n        _5913 = true;\n        _5914 = _4065;\n        _5915 = _4082;\n        _5916 = _4082 * _4082;\n        float param = max(dot(n, v), 9.9999997473787516355514526367188e-05);\n        float param_1 = _4082;\n        float _4099 = fa_sheen_albedo(param, param_1);\n        _5918 = _4099;\n        _5917 = 1.0 - min(_4074 * _4099, 1.0);\n        _5903 = true;\n    }\n    _5906 = _5905 * _5917;\n    float _4118 = clamp(s.anisotropy, -1.0, 1.0);\n    if (_4118 != 0.0)\n    {\n        vec3 _4133 = i.world_tangent.xyz - (n * dot(n, i.world_tangent.xyz));\n        vec3 t = _4133;\n        if (dot(_4133, _4133) < 9.9999999392252902907785028219223e-09)\n        {\n            bvec3 _4145 = bvec3(abs(n.y) < 0.9900000095367431640625);\n            t = cross(vec3(_4145.x ? vec3(0.0, 1.0, 0.0).x : vec3(1.0, 0.0, 0.0).x, _4145.y ? vec3(0.0, 1.0, 0.0).y : vec3(1.0, 0.0, 0.0).y, _4145.z ? vec3(0.0, 1.0, 0.0).z : vec3(1.0, 0.0, 0.0).z), n);\n        }\n        vec3 _4149 = t;\n        vec3 _4150 = normalize(_4149);\n        t = _4150;\n        vec3 _4175 = normalize((_4150 * cos(s.anisotropy_rotation)) + ((cross(n, _4150) * ((i.world_tangent.w < 0.0) ? (-1.0) : 1.0)) * sin(s.anisotropy_rotation)));\n        _5920 = _4175;\n        _5921 = cross(n, _4175);\n        float _4185 = roughness * roughness;\n        float _4191 = mix(_4185, 1.0, _4118 * _4118);\n        bool _4193 = _4118 > 0.0;\n        _5922 = _4193 ? _4191 : _4185;\n        _5923 = _4193 ? _4185 : _4191;\n        _5919 = _4118;\n        _5903 = true;\n    }\n    return FaLayers(_5903, _5904, _5905, _5906, _5907, _5908, _5909, _5910, i.world_normal, _5912, _5913, _5914, _5915, _5916, _5917, _5918, _5919, _5920, _5921, _5922, _5923);\n}\n\nvec2 fa_env_brdf(float rough, float ndv)\n{\n    vec4 _3747 = (vec4(-1.0, -0.0274999998509883880615234375, -0.572000026702880859375, 0.02199999988079071044921875) * rough) + vec4(1.0, 0.0425000004470348358154296875, 1.03999996185302734375, -0.039999999105930328369140625);\n    float _3750 = _3747.x;\n    return (vec2(-1.03999996185302734375, 1.03999996185302734375) * ((min(_3750 * _3750, exp2((-9.27999973297119140625) * ndv)) * _3750) + _3747.y)) + _3747.zw;\n}\n\nvec2 fa_oct_encode(vec3 d)\n{\n    vec3 _3182 = d / vec3(max((abs(d.x) + abs(d.y)) + abs(d.z), 9.9999999600419720025001879548654e-13));\n    float _3185 = _3182.x;\n    float _3187 = _3182.z;\n    vec2 e = vec2(_3185, _3187);\n    if (_3182.y < 0.0)\n    {\n        e = vec2((1.0 - abs(_3187)) * ((_3185 < 0.0) ? (-1.0) : 1.0), (1.0 - abs(_3185)) * ((_3187 < 0.0) ? (-1.0) : 1.0));\n    }\n    return e;\n}\n\nvec2 fa_atlas_size()\n{\n    return vec2(textureSize(fa_probe_atlas_fa_env_smp, 0));\n}\n\nvec3 fa_probe_level(vec2 origin, float res, int lv, vec2 e)\n{\n    float _3234;\n    if (lv == 0)\n    {\n        _3234 = 0.0;\n    }\n    else\n    {\n        _3234 = res + 2.0;\n    }\n    float _3244;\n    if (lv == 0)\n    {\n        _3244 = 0.0;\n    }\n    else\n    {\n        _3244 = (res - (res / float(1 << max((lv - 1), 0)))) + (2.0 * float(lv - 1));\n    }\n    return textureLod(fa_probe_atlas_fa_env_smp, (((origin + vec2(_3234, _3244)) + vec2(1.0)) + (((e * 0.5) + vec2(0.5)) * (res / float(1 << lv)))) / fa_atlas_size(), 0.0).xyz;\n}\n\nvec3 fa_probe_radiance(vec2 origin, float res, vec3 d, float rough)\n{\n    float _3290;\n    if (res > 64.5)\n    {\n        _3290 = 5.0;\n    }\n    else\n    {\n        _3290 = (res > 32.5) ? 4.0 : 3.0;\n    }\n    float _3305 = clamp(rough, 0.0, 1.0) * (_3290 - 1.0);\n    int _3312 = int(min(floor(_3305), _3290 - 2.0));\n    float _3317 = _3305 - float(_3312);\n    vec3 param = d;\n    vec2 _3321 = fa_oct_encode(param);\n    vec2 param_1 = origin;\n    float param_2 = res;\n    int param_3 = _3312;\n    vec2 param_4 = _3321;\n    vec3 _3331 = fa_probe_level(param_1, param_2, param_3, param_4);\n    if (_3317 < 0.00200000009499490261077880859375)\n    {\n        return _3331;\n    }\n    vec2 param_5 = origin;\n    float param_6 = res;\n    int param_7 = _3312 + 1;\n    vec2 param_8 = _3321;\n    return mix(_3331, fa_probe_level(param_5, param_6, param_7, param_8), vec3(_3317));\n}\n\nvec3 fa_probe_box_dir(vec3 d, vec4 posw, vec4 bx, vec4 by, vec4 bz)\n{\n    if (posw.w < 0.5)\n    {\n        return d;\n    }\n    float _3369 = dot(bx.xyz, fa_world_pos) + bx.w;\n    float _3376 = dot(by.xyz, fa_world_pos) + by.w;\n    float _3383 = dot(bz.xyz, fa_world_pos) + bz.w;\n    float _3389 = dot(bx.xyz, d);\n    float _3393 = dot(by.xyz, d);\n    float _3397 = dot(bz.xyz, d);\n    float _3403;\n    if (_3389 > 9.9999999747524270787835121154785e-07)\n    {\n        _3403 = (1.0 - _3369) / _3389;\n    }\n    else\n    {\n        float _3417;\n        if (_3389 < (-9.9999999747524270787835121154785e-07))\n        {\n            _3417 = ((-1.0) - _3369) / _3389;\n        }\n        else\n        {\n            _3417 = 1000000015047466219876688855040.0;\n        }\n        _3403 = _3417;\n    }\n    float tx = _3403;\n    float _3434;\n    if (_3393 > 9.9999999747524270787835121154785e-07)\n    {\n        _3434 = (1.0 - _3376) / _3393;\n    }\n    else\n    {\n        float _3447;\n        if (_3393 < (-9.9999999747524270787835121154785e-07))\n        {\n            _3447 = ((-1.0) - _3376) / _3393;\n        }\n        else\n        {\n            _3447 = 1000000015047466219876688855040.0;\n        }\n        _3434 = _3447;\n    }\n    float ty = _3434;\n    float _3463;\n    if (_3397 > 9.9999999747524270787835121154785e-07)\n    {\n        _3463 = (1.0 - _3383) / _3397;\n    }\n    else\n    {\n        float _3476;\n        if (_3397 < (-9.9999999747524270787835121154785e-07))\n        {\n            _3476 = ((-1.0) - _3383) / _3397;\n        }\n        else\n        {\n            _3476 = 1000000015047466219876688855040.0;\n        }\n        _3463 = _3476;\n    }\n    float _3488 = tx;\n    float _3491 = (_3488 > 0.0) ? _3488 : 1000000015047466219876688855040.0;\n    tx = _3491;\n    float _3492 = ty;\n    float _3495 = (_3492 > 0.0) ? _3492 : 1000000015047466219876688855040.0;\n    ty = _3495;\n    float _3505 = min(_3491, min(_3495, (_3463 > 0.0) ? _3463 : 1000000015047466219876688855040.0));\n    if (_3505 > 100000001504746621987668885504.0)\n    {\n        return d;\n    }\n    vec3 _3521 = (fa_world_pos + (d * _3505)) - posw.xyz;\n    vec3 _3526;\n    if (dot(_3521, _3521) > 1.0000000133514319600180897396058e-10)\n    {\n        _3526 = normalize(_3521);\n    }\n    else\n    {\n        _3526 = d;\n    }\n    return _3526;\n}\n\nvec3 fa_probe_environment(vec4 tile, vec4 posw, vec4 bx, vec4 by, vec4 bz, inout vec3 d, float rough)\n{\n    vec3 param = d;\n    vec4 param_1 = posw;\n    vec4 param_2 = bx;\n    vec4 param_3 = by;\n    vec4 param_4 = bz;\n    d = fa_probe_box_dir(param, param_1, param_2, param_3, param_4);\n    vec2 param_5 = tile.xy;\n    float param_6 = tile.z;\n    vec3 param_7 = d;\n    float param_8 = rough;\n    return fa_probe_radiance(param_5, param_6, param_7, param_8);\n}\n\nvec3 fa_environment(vec3 d, float rough)\n{\n    float _3572 = (1.0 - fa_mesh_fs_params[42].w) - fa_mesh_fs_params[47].w;\n    vec3 outc = vec3(0.0);\n    if (_3572 > 0.0005000000237487256526947021484375)\n    {\n        vec3 base;\n        if (fa_mesh_fs_params[11].w > 0.5)\n        {\n            vec2 param = fa_mesh_fs_params[41].zw;\n            float param_1 = 128.0;\n            vec3 param_2 = d;\n            float param_3 = rough;\n            base = fa_probe_radiance(param, param_1, param_2, param_3);\n        }\n        else\n        {\n            float _3602 = rough * rough;\n            float _3633 = 0.60000002384185791015625 * _3602;\n            base = mix(mix(fa_mesh_fs_params[12].xyz * 0.550000011920928955078125, mix(fa_mesh_fs_params[12].xyz, fa_mesh_fs_params[11].xyz, vec3(pow(clamp(d.y * (1.0 - (0.699999988079071044921875 * _3602)), 0.0, 1.0), 0.550000011920928955078125))), vec3(smoothstep((-0.0500000007450580596923828125) - _3633, 0.0500000007450580596923828125 + _3633, d.y))), ((fa_mesh_fs_params[11].xyz + fa_mesh_fs_params[12].xyz) * 0.5) * 0.800000011920928955078125, vec3(_3602 * 0.60000002384185791015625));\n        }\n        outc = base * _3572;\n    }\n    if (fa_mesh_fs_params[42].w > 0.0)\n    {\n        vec4 param_4 = fa_mesh_fs_params[42];\n        vec4 param_5 = fa_mesh_fs_params[43];\n        vec4 param_6 = fa_mesh_fs_params[44];\n        vec4 param_7 = fa_mesh_fs_params[45];\n        vec4 param_8 = fa_mesh_fs_params[46];\n        vec3 param_9 = d;\n        float param_10 = rough;\n        vec3 _3692 = fa_probe_environment(param_4, param_5, param_6, param_7, param_8, param_9, param_10);\n        outc += (_3692 * fa_mesh_fs_params[42].w);\n    }\n    if (fa_mesh_fs_params[47].w > 0.0)\n    {\n        vec4 param_11 = fa_mesh_fs_params[47];\n        vec4 param_12 = fa_mesh_fs_params[48];\n        vec4 param_13 = fa_mesh_fs_params[49];\n        vec4 param_14 = fa_mesh_fs_params[50];\n        vec4 param_15 = fa_mesh_fs_params[51];\n        vec3 param_16 = d;\n        float param_17 = rough;\n        vec3 _3724 = fa_probe_environment(param_11, param_12, param_13, param_14, param_15, param_16, param_17);\n        outc += (_3724 * fa_mesh_fs_params[47].w);\n    }\n    return outc;\n}\n\nvec3 fa_layers_ibl(FaLayers L, vec3 n, vec3 v, vec3 f0, float roughness, float occlusion)\n{\n    vec3 rn = n;\n    if (L.aniso != 0.0)\n    {\n        vec3 _4226;\n        if (L.aniso >= 0.0)\n        {\n            _4226 = L.b;\n        }\n        else\n        {\n            _4226 = L.t;\n        }\n        rn = normalize(mix(n, cross(cross(_4226, v), _4226), vec3(abs(L.aniso) * smoothstep(0.0, 0.25, roughness))));\n    }\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05);\n    vec2 _4262 = fa_env_brdf(param, param_1);\n    vec3 param_2 = reflect(-v, rn);\n    float param_3 = roughness;\n    vec3 result = (fa_environment(param_2, param_3) * ((f0 * _4262.x) + (vec3(L.f90) * _4262.y))) * L.base_scale;\n    if (L.sheen_on)\n    {\n        vec3 param_4 = n;\n        float param_5 = L.sheen_rough;\n        result += ((L.sheen * (L.sheen_e * L.keep)) * fa_environment(param_4, param_5));\n    }\n    result *= occlusion;\n    if (L.coat > 0.0)\n    {\n        float param_6 = L.coat_rough;\n        float param_7 = L.coat_ndv;\n        vec2 _4320 = fa_env_brdf(param_6, param_7);\n        vec3 param_8 = reflect(-v, L.nc);\n        float param_9 = L.coat_rough;\n        result += (fa_environment(param_8, param_9) * (L.coat * ((0.039999999105930328369140625 * _4320.x) + _4320.y)));\n    }\n    return result;\n}\n\nvec3 fa_sky_reflection(vec3 n, vec3 v, vec3 f0, float roughness)\n{\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05);\n    vec2 _3789 = fa_env_brdf(param, param_1);\n    vec3 param_2 = reflect(-v, n);\n    float param_3 = roughness;\n    return fa_environment(param_2, param_3) * ((f0 * _3789.x) + vec3(_3789.y));\n}\n\nvec3 fa_sky_light(SurfaceInput i, Surface s)\n{\n    float _4359 = clamp(s.metallic, 0.0, 1.0);\n    float _4363 = clamp(s.roughness, 0.0500000007450580596923828125, 1.0);\n    vec3 _4370 = mix(vec3(0.039999999105930328369140625), s.albedo, vec3(_4359));\n    vec3 f0 = _4370;\n    vec3 _4374 = normalize(s.normal);\n    SurfaceInput param = i;\n    Surface param_1 = s;\n    vec3 param_2 = _4374;\n    vec3 param_3 = i.view_dir;\n    float param_4 = _4359;\n    float param_5 = _4363;\n    vec3 param_6 = _4370;\n    FaLayers _4391 = fa_layers_setup(param, param_1, param_2, param_3, param_4, param_5, param_6);\n    f0 = param_6;\n    if (_4391.on)\n    {\n        FaLayers param_7 = _4391;\n        vec3 param_8 = _4374;\n        vec3 param_9 = i.view_dir;\n        vec3 param_10 = f0;\n        float param_11 = _4363;\n        float param_12 = s.occlusion;\n        return fa_layers_ibl(param_7, param_8, param_9, param_10, param_11, param_12);\n    }\n    vec3 param_13 = _4374;\n    vec3 param_14 = i.view_dir;\n    vec3 param_15 = f0;\n    float param_16 = _4363;\n    return fa_sky_reflection(param_13, param_14, param_15, param_16) * s.occlusion;\n}\n\nvec3 lighting(SurfaceInput i, Surface s)\n{\n    int best = -1;\n    float bestPower = 0.0;\n    for (int n = 0; n < fa_light_count(); n++)\n    {\n        int param = n;\n        SurfaceInput param_1 = i;\n        LightSample _4989 = fa_light_unshadowed(param, param_1);\n        float _4997 = dot(_4989.color, vec3(0.2989999949932098388671875, 0.58700001239776611328125, 0.114000000059604644775390625));\n        if (_4997 > bestPower)\n        {\n            bestPower = _4997;\n            best = n;\n        }\n    }\n    vec3 lit = (fa_mesh_fs_params[1].xyz * s.albedo) * s.occlusion;\n    if (best >= 0)\n    {\n        int param_2 = best;\n        SurfaceInput param_3 = i;\n        LightSample _5026 = fa_light(param_2, param_3);\n        float _5034;\n        if (dot(s.normal, _5026.direction) > 0.5)\n        {\n            _5034 = 1.0;\n        }\n        else\n        {\n            _5034 = fa_material[0].x;\n        }\n        lit += ((s.albedo * _5026.color) * _5034);\n    }\n    SurfaceInput param_4 = i;\n    Surface param_5 = s;\n    return lit + (fa_sky_light(param_4, param_5) * fa_material[1].x);\n}\n\nvec3 fa_shadow_debug(vec3 color, vec3 world)\n{\n    if (fa_shadows[27].w < 0.5)\n    {\n        return color;\n    }\n    int _3080 = int(fa_shadows[25].x + 0.5);\n    float _3090 = dot(world - fa_shadows[27].xyz, fa_shadows[28].xyz);\n    vec3 tint = vec3(0.3499999940395355224609375);\n    bool _3095 = _3080 > 0;\n    bool _3104;\n    if (_3095)\n    {\n        int param = _3080 - 1;\n        _3104 = _3090 <= fa_shadow_split_at(param);\n    }\n    else\n    {\n        _3104 = _3095;\n    }\n    if (_3104)\n    {\n        tint = vec3(1.0, 0.1500000059604644775390625, 0.100000001490116119384765625);\n        bool _3110 = _3080 > 1;\n        bool _3117;\n        if (_3110)\n        {\n            _3117 = _3090 > fa_shadows[24].x;\n        }\n        else\n        {\n            _3117 = _3110;\n        }\n        if (_3117)\n        {\n            tint = vec3(0.100000001490116119384765625, 0.89999997615814208984375, 0.20000000298023223876953125);\n        }\n        bool _3123 = _3080 > 2;\n        bool _3130;\n        if (_3123)\n        {\n            _3130 = _3090 > fa_shadows[24].y;\n        }\n        else\n        {\n            _3130 = _3123;\n        }\n        if (_3130)\n        {\n            tint = vec3(0.1500000059604644775390625, 0.300000011920928955078125, 1.0);\n        }\n        bool _3136 = _3080 > 3;\n        bool _3143;\n        if (_3136)\n        {\n            _3143 = _3090 > fa_shadows[24].z;\n        }\n        else\n        {\n            _3143 = _3136;\n        }\n        if (_3143)\n        {\n            tint = vec3(1.0, 0.89999997615814208984375, 0.100000001490116119384765625);\n        }\n    }\n    return mix(color, tint, vec3(0.550000011920928955078125));\n}\n\nvoid main()\n{\n    fa_inst_load();\n    vec3 _5757 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _5757 = -_5757;\n    }\n    vec3 _5427 = normalize(fa_mesh_fs_params[0].xyz - fa_world_pos);\n    vec3 param = fa_world_pos;\n    fa_cluster_begin(param);\n    SurfaceInput param_1 = SurfaceInput(fa_world_pos, _5757, fa_world_tangent, fa_uv, fa_vertex_color, _5427, gl_FrontFacing);\n    Surface _5435 = fa_standard_surface(param_1);\n    vec3 _5788 = _5435.albedo;\n    float _5789 = _5435.alpha;\n    vec3 _5790 = _5435.normal;\n    float _5791 = _5435.metallic;\n    float _5792 = _5435.roughness;\n    float _5793 = _5435.occlusion;\n    vec3 _5794 = _5435.emission;\n    float _5795 = _5435.clearcoat;\n    float _5796 = _5435.clearcoat_roughness;\n    vec3 _5797 = _5435.sheen_color;\n    float _5798 = _5435.sheen_roughness;\n    float _5799 = _5435.anisotropy;\n    float _5800 = _5435.anisotropy_rotation;\n    float _5801 = _5435.specular;\n    float _5802 = _5435.ior;\n    vec3 _5803 = _5435.specular_color;\n    float _5804 = _5435.transmission;\n    float _5805 = _5435.thickness;\n    vec3 _5806 = _5435.attenuation_color;\n    float _5807 = _5435.attenuation_distance;\n    SurfaceInput param_2 = SurfaceInput(fa_world_pos, _5757, fa_world_tangent, fa_uv, fa_vertex_color, _5427, gl_FrontFacing);\n    Surface param_3 = _5435;\n    surface(param_2, param_3);\n    _5788 = param_3.albedo;\n    _5789 = param_3.alpha;\n    _5790 = param_3.normal;\n    _5791 = param_3.metallic;\n    _5792 = param_3.roughness;\n    _5793 = param_3.occlusion;\n    _5794 = param_3.emission;\n    _5795 = param_3.clearcoat;\n    _5796 = param_3.clearcoat_roughness;\n    _5797 = param_3.sheen_color;\n    _5798 = param_3.sheen_roughness;\n    _5799 = param_3.anisotropy;\n    _5800 = param_3.anisotropy_rotation;\n    _5801 = param_3.specular;\n    _5802 = param_3.ior;\n    _5803 = param_3.specular_color;\n    _5804 = param_3.transmission;\n    _5805 = param_3.thickness;\n    _5806 = param_3.attenuation_color;\n    _5807 = param_3.attenuation_distance;\n    vec3 param_4 = fa_world_pos;\n    vec3 param_5 = _5757;\n    vec3 param_6 = param_3.albedo;\n    vec3 param_7 = param_3.normal;\n    fa_apply_decals(param_4, param_5, param_6, param_7);\n    _5788 = param_6;\n    _5790 = param_7;\n    vec3 result;\n    if (fa_mesh_fs_params[3].w > 0.5)\n    {\n        result = _5788;\n    }\n    else\n    {\n        vec3 _5474 = _5790;\n        vec3 _5475 = normalize(_5474);\n        _5790 = _5475;\n        SurfaceInput param_8 = SurfaceInput(fa_world_pos, _5757, fa_world_tangent, fa_uv, fa_vertex_color, _5427, gl_FrontFacing);\n        Surface param_9 = Surface(_5788, _5789, _5475, _5791, _5792, _5793, _5794, _5795, _5796, _5797, _5798, _5799, _5800, _5801, _5802, _5803, _5804, _5805, _5806, _5807);\n        vec3 _5486 = lighting(param_8, param_9);\n        result = _5486;\n    }\n    vec3 _5490 = result;\n    vec3 _5491 = _5490 + _5794;\n    result = _5491;\n    vec3 param_10 = _5491;\n    vec3 param_11 = fa_world_pos;\n    result = fa_shadow_debug(param_10, param_11);\n    bool _5500 = fa_mesh_fs_params[7].w > 0.0;\n    bool _5507;\n    if (!_5500)\n    {\n        _5507 = fa_mesh_fs_params[8].y > 0.0;\n    }\n    else\n    {\n        _5507 = _5500;\n    }\n    if (_5507)\n    {\n        vec3 _5516 = fa_world_pos - fa_mesh_fs_params[0].xyz;\n        float _5522 = dot(_5516, fa_mesh_fs_params[9].xyz);\n        bool _5526 = fa_mesh_fs_params[9].w > 0.5;\n        float _5527;\n        if (_5526)\n        {\n            _5527 = _5522;\n        }\n        else\n        {\n            _5527 = length(_5516);\n        }\n        float _5539 = _5527 - fa_mesh_fs_params[8].x;\n        if (_5539 > 0.0)\n        {\n            float _5548 = fa_mesh_fs_params[7].w * _5539;\n            float tau = _5548 * _5548;\n            if (fa_mesh_fs_params[8].y > 0.0)\n            {\n                float _5564;\n                if (_5526)\n                {\n                    _5564 = fa_world_pos.y - (fa_mesh_fs_params[9].y * _5522);\n                }\n                else\n                {\n                    _5564 = fa_mesh_fs_params[0].y;\n                }\n                float _5585 = mix(_5564, fa_world_pos.y, clamp(fa_mesh_fs_params[8].x / _5527, 0.0, 1.0));\n                float _5589 = fa_world_pos.y - _5585;\n                float _5594 = _5585 - fa_mesh_fs_params[8].z;\n                float _5599 = fa_world_pos.y - fa_mesh_fs_params[8].z;\n                bool _5602 = _5594 <= 0.0;\n                bool _5603 = !_5602;\n                bool _5609;\n                if (_5603)\n                {\n                    _5609 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _5609 = _5602;\n                }\n                float _5610;\n                if (_5609)\n                {\n                    _5610 = fa_mesh_fs_params[8].y;\n                }\n                else\n                {\n                    _5610 = fa_mesh_fs_params[8].y * exp(-min(fa_mesh_fs_params[8].w * _5594, 80.0));\n                }\n                bool _5637;\n                if (_5603)\n                {\n                    _5637 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _5637 = _5602;\n                }\n                float _5638;\n                if (_5637)\n                {\n                    _5638 = fa_mesh_fs_params[8].y * _5594;\n                }\n                else\n                {\n                    _5638 = (fa_mesh_fs_params[8].y * (1.0 - exp(-min(fa_mesh_fs_params[8].w * _5594, 80.0)))) / fa_mesh_fs_params[8].w;\n                }\n                bool _5663 = _5599 <= 0.0;\n                bool _5670;\n                if (!_5663)\n                {\n                    _5670 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _5670 = _5663;\n                }\n                float _5671;\n                if (_5670)\n                {\n                    _5671 = fa_mesh_fs_params[8].y * _5599;\n                }\n                else\n                {\n                    _5671 = (fa_mesh_fs_params[8].y * (1.0 - exp(-min(fa_mesh_fs_params[8].w * _5599, 80.0)))) / fa_mesh_fs_params[8].w;\n                }\n                float _5698;\n                if (abs(_5589) < 0.001000000047497451305389404296875)\n                {\n                    _5698 = _5610;\n                }\n                else\n                {\n                    _5698 = (_5671 - _5638) / _5589;\n                }\n                tau += (_5539 * max(_5698, 0.0));\n            }\n            result = mix(result, fa_mesh_fs_params[7].xyz, vec3(clamp(1.0 - exp(-clamp(tau, 0.0, 80.0)), 0.0, 1.0)));\n        }\n    }\n    fa_frag_color = vec4(result, _5789);\n}\n\n",
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
            "inst_name": "_468",
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
            "inst_name": "_2121",
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
            "inst_name": "_5040",
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
      "vs": "#version 430\n\nstruct VertexData\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 color;\n    vec3 object_pos;\n};\n\nuniform vec4 fa_mesh_vs_params[11];\nuniform vec4 fa_skin[192];\nlayout(location = 0) out vec3 fa_world_pos;\nlayout(location = 1) out vec3 fa_world_normal;\nlayout(location = 2) out vec4 fa_world_tangent;\nlayout(location = 3) out vec2 fa_uv;\nlayout(location = 4) out vec4 fa_vertex_color;\nlayout(location = 5) in vec4 fa_inst_m0;\nlayout(location = 6) in vec4 fa_inst_m1;\nlayout(location = 7) in vec4 fa_inst_m2;\nlayout(location = 8) in vec4 fa_inst_m3;\nlayout(location = 9) in vec4 fa_joints;\nlayout(location = 10) in vec4 fa_weights;\nlayout(location = 0) in vec3 fa_position;\nlayout(location = 1) in vec3 fa_normal;\nlayout(location = 3) in vec4 fa_tangent;\nlayout(location = 2) in vec2 fa_texcoord0;\nlayout(location = 4) in vec4 fa_color;\nlayout(location = 5) out vec3 fa_lm;\n\nvoid fa_inst_begin()\n{\n}\n\nmat4 fa_skin_matrix_at(vec4 joints, vec4 weights, int base)\n{\n    vec4 r0 = vec4(0.0);\n    vec4 r1 = vec4(0.0);\n    vec4 r2 = vec4(0.0);\n    for (int i = 0; i < 4; i++)\n    {\n        int _182 = base + (int((joints[i] * 255.0) + 0.5) * 3);\n        r0 += (fa_skin[_182 * 1 + 0] * weights[i]);\n        r1 += (fa_skin[(_182 + 1) * 1 + 0] * weights[i]);\n        r2 += (fa_skin[(_182 + 2) * 1 + 0] * weights[i]);\n    }\n    return mat4(vec4(r0.x, r1.x, r2.x, 0.0), vec4(r0.y, r1.y, r2.y, 0.0), vec4(r0.z, r1.z, r2.z, 0.0), vec4(r0.w, r1.w, r2.w, 1.0));\n}\n\nmat4 fa_skin_matrix(vec4 joints, vec4 weights)\n{\n    vec4 param = joints;\n    vec4 param_1 = weights;\n    int param_2 = 0;\n    return fa_skin_matrix_at(param, param_1, param_2);\n}\n\nVertexData fa_vertex_data(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    vec3 _81 = cross(model[1].xyz, model[2].xyz);\n    float _87 = (dot(model[0].xyz, _81) < 0.0) ? (-1.0) : 1.0;\n    return VertexData((model * vec4(position, 1.0)).xyz, (((_81 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _87, vec4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _87), texcoord0 * fa_mesh_vs_params[8].xy, color, position);\n}\n\nvoid fa_shade_vertex(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    mat4 param = model;\n    vec3 param_1 = position;\n    vec3 param_2 = normal;\n    vec4 param_3 = tangent;\n    vec2 param_4 = texcoord0;\n    vec4 param_5 = color;\n    VertexData _289 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    vec3 _407 = _289.world_pos;\n    fa_world_pos = _407;\n    fa_world_normal = _289.world_normal;\n    fa_world_tangent = _289.world_tangent;\n    fa_uv = _289.uv;\n    fa_vertex_color = _289.color;\n    gl_Position = mat4(fa_mesh_vs_params[0], fa_mesh_vs_params[1], fa_mesh_vs_params[2], fa_mesh_vs_params[3]) * vec4(_407, 1.0);\n}\n\nvoid main()\n{\n    fa_inst_begin();\n    vec4 param = fa_joints;\n    vec4 param_1 = fa_weights;\n    mat4 param_2 = mat4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3) * fa_skin_matrix(param, param_1);\n    vec3 param_3 = fa_position;\n    vec3 param_4 = fa_normal;\n    vec4 param_5 = fa_tangent;\n    vec2 param_6 = fa_texcoord0;\n    vec4 param_7 = fa_color;\n    fa_shade_vertex(param_2, param_3, param_4, param_5, param_6, param_7);\n    fa_lm = vec3(0.0);\n}\n\n",
      "fs": "#version 430\n\nstruct SurfaceInput\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 vertex_color;\n    vec3 view_dir;\n    bool front_facing;\n};\n\nstruct LightSample\n{\n    vec3 direction;\n    vec3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct Surface\n{\n    vec3 albedo;\n    float alpha;\n    vec3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    vec3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    vec3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    vec3 specular_color;\n    float transmission;\n    float thickness;\n    vec3 attenuation_color;\n    float attenuation_distance;\n};\n\nstruct FaLayers\n{\n    bool on;\n    float f90;\n    float keep;\n    float base_scale;\n    float coat;\n    float coat_rough;\n    float coat_alpha;\n    float coat_a2;\n    vec3 nc;\n    float coat_ndv;\n    bool sheen_on;\n    vec3 sheen;\n    float sheen_rough;\n    float sheen_alpha;\n    float sheen_scale;\n    float sheen_e;\n    float aniso;\n    vec3 t;\n    vec3 b;\n    float at;\n    float ab;\n};\n\nconst float _3890[63] = float[](1.0, 1.0, 1.0, 0.4790000021457672119140625, 0.11699999868869781494140625, 0.01200000010430812835693359375, 0.0, 0.0, 0.0, 1.0, 1.0, 1.0, 0.578000009059906005859375, 0.19300000369548797607421875, 0.0350000001490116119384765625, 0.0030000000260770320892333984375, 0.0, 0.0, 1.0, 1.0, 1.0, 0.6740000247955322265625, 0.3459999859333038330078125, 0.1319999992847442626953125, 0.032999999821186065673828125, 0.0040000001899898052215576171875, 0.0, 0.971000015735626220703125, 0.954999983310699462890625, 0.828999996185302734375, 0.63999998569488525390625, 0.42599999904632568359375, 0.24500000476837158203125, 0.115000002086162567138671875, 0.037000000476837158203125, 0.0030000000260770320892333984375, 0.7469999790191650390625, 0.737999975681304931640625, 0.670000016689300537109375, 0.563000023365020751953125, 0.4309999942779541015625, 0.3039999902248382568359375, 0.1940000057220458984375, 0.1019999980926513671875, 0.0309999994933605194091796875, 0.614000022411346435546875, 0.609000027179718017578125, 0.566999971866607666015625, 0.499000012874603271484375, 0.412000000476837158203125, 0.32400000095367431640625, 0.240999996662139892578125, 0.162000000476837158203125, 0.087999999523162841796875, 0.538999974727630615234375, 0.535000026226043701171875, 0.505999982357025146484375, 0.4569999873638153076171875, 0.393999993801116943359375, 0.328999996185302734375, 0.2660000026226043701171875, 0.203999996185302734375, 0.14200000464916229248046875);\n\nuniform vec4 fa_mesh_fs_params[53];\nuniform vec4 fa_shadows[30];\nuniform vec4 fa_material[2];\nlayout(binding = 0) uniform sampler2D fa_light_tex_fa_shadow_smp;\nlayout(binding = 1) uniform sampler2D fa_tex_fa_smp;\nlayout(binding = 2) uniform sampler2D fa_normal_tex_fa_smp;\nlayout(binding = 3) uniform sampler2D fa_mr_tex_fa_smp;\nlayout(binding = 4) uniform sampler2D fa_occlusion_tex_fa_smp;\nlayout(binding = 5) uniform sampler2D fa_emissive_tex_fa_smp;\nlayout(binding = 6) uniform sampler2D fa_decal_tex_fa_env_smp;\nlayout(binding = 7) uniform sampler2D fa_light_atlas_fa_env_smp;\nlayout(binding = 8) uniform sampler2D fa_shadow_tex_fa_shadow_smp;\nlayout(binding = 9) uniform sampler2D fa_screen_tex_fa_shadow_smp;\nlayout(binding = 10) uniform sampler2D fa_probe_atlas_fa_env_smp;\n\nlayout(location = 0) in vec3 fa_world_pos;\nlayout(location = 5) in vec3 fa_lm;\nlayout(location = 1) in vec3 fa_world_normal;\nlayout(location = 2) in vec4 fa_world_tangent;\nlayout(location = 3) in vec2 fa_uv;\nlayout(location = 4) in vec4 fa_vertex_color;\nlayout(location = 0) out vec4 fa_frag_color;\nvec3 fa_light_tint;\nbool fa_light_is_area;\nint fa_cl_ndir;\nint fa_cl_slot;\nint fa_cl_local;\n\nvoid fa_inst_load()\n{\n}\n\nvec4 fa_light_texel(int t)\n{\n    return texelFetch(fa_light_tex_fa_shadow_smp, ivec2(t & 1023, t >> 10), 0);\n}\n\nvec4 fa_cluster_texel(vec3 world_pos)\n{\n    bool _1397 = fa_mesh_fs_params[19].x < 0.0;\n    bool _1404;\n    if (!_1397)\n    {\n        _1404 = fa_mesh_fs_params[19].w < 1.0;\n    }\n    else\n    {\n        _1404 = _1397;\n    }\n    bool _1412;\n    if (!_1404)\n    {\n        _1412 = fa_mesh_fs_params[18].x < 1.0;\n    }\n    else\n    {\n        _1412 = _1404;\n    }\n    bool _1419;\n    if (!_1412)\n    {\n        _1419 = fa_mesh_fs_params[18].y < 1.0;\n    }\n    else\n    {\n        _1419 = _1412;\n    }\n    bool _1426;\n    if (!_1419)\n    {\n        _1426 = fa_mesh_fs_params[19].y < 1.0;\n    }\n    else\n    {\n        _1426 = _1419;\n    }\n    if (_1426)\n    {\n        return vec4(0.0);\n    }\n    vec4 _1436 = vec4(world_pos, 1.0);\n    float _1442 = dot(fa_mesh_fs_params[16], _1436);\n    if (!(_1442 > 9.9999999747524270787835121154785e-07))\n    {\n        return vec4(0.0);\n    }\n    vec2 _1464 = vec2(dot(fa_mesh_fs_params[14], _1436), dot(fa_mesh_fs_params[15], _1436)) / vec2(_1442);\n    int _1468 = int(fa_mesh_fs_params[18].x);\n    int _1472 = int(fa_mesh_fs_params[18].y);\n    int param = (int(fa_mesh_fs_params[19].x) + (((clamp(int(floor(log2(max(dot(fa_mesh_fs_params[17].xyz, world_pos) + fa_mesh_fs_params[17].w, fa_mesh_fs_params[18].w) / fa_mesh_fs_params[18].w) * fa_mesh_fs_params[18].z)), 0, int(fa_mesh_fs_params[19].y) - 1) * _1472) + clamp(int(floor(((_1464.y * 0.5) + 0.5) * fa_mesh_fs_params[18].y)), 0, _1472 - 1)) * _1468)) + clamp(int(floor(((_1464.x * 0.5) + 0.5) * fa_mesh_fs_params[18].x)), 0, _1468 - 1);\n    return fa_light_texel(param);\n}\n\nivec2 fa_cluster_lookup(vec3 world_pos)\n{\n    vec3 param = world_pos;\n    vec4 _1548 = fa_cluster_texel(param);\n    return ivec2(int(_1548.x), int(_1548.y));\n}\n\nvoid fa_cluster_begin(vec3 world_pos)\n{\n    fa_cl_ndir = int(fa_mesh_fs_params[19].z);\n    vec3 param = world_pos;\n    ivec2 _4724 = fa_cluster_lookup(param);\n    fa_cl_slot = _4724.x;\n    fa_cl_local = _4724.y;\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_linear_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvec3 fa_tex_fix(inout vec3 c, float mode)\n{\n    if (mode > 1.5)\n    {\n        vec3 param = c;\n        vec3 _5101 = fa_linear_to_srgb(param);\n        c = _5101;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            vec3 param_1 = c;\n            vec3 _5109 = fa_srgb_to_linear(param_1);\n            c = _5109;\n        }\n    }\n    return c;\n}\n\nvec3 fa_tangent_normal(SurfaceInput i, vec3 m)\n{\n    vec3 _348;\n    if (i.front_facing)\n    {\n        _348 = i.world_normal;\n    }\n    else\n    {\n        _348 = -i.world_normal;\n    }\n    vec3 _372 = normalize(i.world_tangent.xyz - (_348 * dot(_348, i.world_tangent.xyz)));\n    vec3 _400 = normalize(((_372 * m.x) + ((cross(_348, _372) * i.world_tangent.w) * m.y)) + (_348 * m.z));\n    vec3 _403;\n    if (i.front_facing)\n    {\n        _403 = _400;\n    }\n    else\n    {\n        _403 = -_400;\n    }\n    return _403;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    vec4 base_t = texture(fa_tex_fa_smp, i.uv);\n    float param = fa_mesh_fs_params[6].w;\n    float param_1 = 1.0;\n    vec3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    vec3 _5140 = fa_tex_fix(param_2, param_3);\n    vec4 _6279 = base_t;\n    _6279.x = _5140.x;\n    _6279.y = _5140.y;\n    _6279.z = _5140.z;\n    base_t = _6279;\n    vec4 _5154 = (_6279 * fa_mesh_fs_params[2]) * i.vertex_color;\n    vec3 _6085 = i.world_normal;\n    if (fa_mesh_fs_params[6].z > 0.5)\n    {\n        float param_4 = fa_mesh_fs_params[6].w;\n        float param_5 = 16.0;\n        vec3 param_6 = texture(fa_normal_tex_fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        vec3 _5186 = fa_tex_fix(param_6, param_7);\n        vec3 _5189 = (_5186 * 2.0) - vec3(1.0);\n        vec2 _5194 = _5189.xy * fa_mesh_fs_params[6].x;\n        vec3 _6287 = _5189;\n        _6287.x = _5194.x;\n        _6287.y = _5194.y;\n        SurfaceInput param_8 = i;\n        vec3 param_9 = _6287;\n        _6085 = fa_tangent_normal(param_8, param_9);\n    }\n    vec4 mrt = texture(fa_mr_tex_fa_smp, i.uv);\n    float param_10 = fa_mesh_fs_params[6].w;\n    float param_11 = 64.0;\n    vec3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    vec3 _5222 = fa_tex_fix(param_12, param_13);\n    vec4 _6290 = mrt;\n    _6290.x = _5222.x;\n    _6290.y = _5222.y;\n    _6290.z = _5222.z;\n    mrt = _6290;\n    vec4 _5250 = texture(fa_occlusion_tex_fa_smp, i.uv);\n    float param_14 = fa_mesh_fs_params[6].w;\n    float param_15 = 256.0;\n    vec3 param_16 = _5250.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    vec3 _5261 = fa_tex_fix(param_16, param_17);\n    float param_18 = fa_mesh_fs_params[6].w;\n    float param_19 = 4.0;\n    vec3 param_20 = texture(fa_emissive_tex_fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    vec3 _5291 = fa_tex_fix(param_20, param_21);\n    float _6090 = fa_mesh_fs_params[20].x;\n    float _6091 = fa_mesh_fs_params[20].y;\n    float _6094 = fa_mesh_fs_params[20].z;\n    float _6093 = fa_mesh_fs_params[21].w;\n    float _6096 = fa_mesh_fs_params[22].x;\n    if (fa_mesh_fs_params[22].z > 0.5)\n    {\n        if (mod(fa_mesh_fs_params[22].z, 2.0) > 0.5)\n        {\n            _6090 *= _5261.y;\n            _6091 *= _5261.z;\n            _6093 *= _5250.w;\n        }\n        if (fa_mesh_fs_params[22].z > 1.5)\n        {\n            _6094 *= mrt.x;\n            _6096 *= mrt.w;\n        }\n    }\n    return Surface(_5154.xyz, _5154.w, _6085, clamp(fa_mesh_fs_params[5].x * _5222.z, 0.0, 1.0), clamp(fa_mesh_fs_params[5].y * _5222.y, 0.0500000007450580596923828125, 1.0), 1.0 + (fa_mesh_fs_params[6].y * (_5261.x - 1.0)), fa_mesh_fs_params[3].xyz + (fa_mesh_fs_params[4].xyz * _5291), _6090, _6091, fa_mesh_fs_params[21].xyz, _6093, _6094, fa_mesh_fs_params[20].w, _6096, fa_mesh_fs_params[22].y, fa_mesh_fs_params[23].xyz, fa_mesh_fs_params[30].x, fa_mesh_fs_params[30].y, fa_mesh_fs_params[31].xyz, fa_mesh_fs_params[30].z);\n}\n\nvoid surface(SurfaceInput i, Surface s)\n{\n}\n\nvec4 fa_decal_tile(vec4 rect, vec2 uv, vec2 atlas, vec2 ddx, vec2 ddy)\n{\n    vec2 _1628 = rect.zw - rect.xy;\n    vec2 _1632 = _1628 * atlas;\n    vec2 _1636 = ddx * _1632;\n    vec2 _1640 = ddy * _1632;\n    return textureLod(fa_decal_tex_fa_env_smp, rect.xy + (clamp(uv, vec2(0.0), vec2(1.0)) * _1628), clamp(0.5 * log2(max(max(dot(_1636, _1636), dot(_1640, _1640)), 9.9999999392252902907785028219223e-09)), 0.0, 3.0));\n}\n\nvec3 fa_dc_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_dc_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvoid fa_apply_decals(vec3 world_pos, vec3 geo_normal, inout vec3 albedo, inout vec3 normal)\n{\n    bool _1673 = fa_mesh_fs_params[10].y < 0.5;\n    bool _1680;\n    if (!_1673)\n    {\n        _1680 = fa_mesh_fs_params[10].w < 0.5;\n    }\n    else\n    {\n        _1680 = _1673;\n    }\n    if (_1680)\n    {\n        return;\n    }\n    vec3 _1686 = dFdx(world_pos);\n    vec3 _1689 = dFdy(world_pos);\n    vec3 param = world_pos;\n    vec4 _1693 = fa_cluster_texel(param);\n    int _1697 = int(_1693.w);\n    if (_1697 < 1)\n    {\n        return;\n    }\n    int _1707 = int(fa_mesh_fs_params[10].y + 0.5);\n    int param_1 = _1707;\n    vec4 _1711 = fa_light_texel(param_1);\n    vec2 _1714 = _1711.yz;\n    int _1718 = int(_1711.w);\n    int param_2 = _1707 + 1;\n    vec4 _1723 = fa_light_texel(param_2);\n    float _1724 = _1723.x;\n    int _1730 = int(fa_mesh_fs_params[10].w + 0.5) - 1;\n    int _1734 = int(_1693.z);\n    vec3 _1999;\n    for (int k = 0; k < _1697; k++)\n    {\n        int _1747 = _1734 + k;\n        int param_3 = _1718 + (_1747 >> 2);\n        int _1764 = (_1707 + 2) + (int(fa_light_texel(param_3)[_1747 & 3]) * 7);\n        int param_4 = _1764 + 6;\n        vec4 _1769 = fa_light_texel(param_4);\n        if (((int(_1769.w + 0.5) >> _1730) & 1) == 0)\n        {\n            continue;\n        }\n        int param_5 = _1764;\n        vec4 _1784 = fa_light_texel(param_5);\n        int param_6 = _1764 + 1;\n        vec4 _1789 = fa_light_texel(param_6);\n        int param_7 = _1764 + 2;\n        vec4 _1794 = fa_light_texel(param_7);\n        vec3 _1797 = _1784.xyz;\n        float _1802 = dot(_1797, world_pos) + _1784.w;\n        vec3 _1804 = _1789.xyz;\n        float _1809 = dot(_1804, world_pos) + _1789.w;\n        vec3 _1811 = _1794.xyz;\n        float _1816 = dot(_1811, world_pos) + _1794.w;\n        bool _1821 = abs(_1802) > 0.5;\n        bool _1829;\n        if (!_1821)\n        {\n            _1829 = abs(_1809) > 0.5;\n        }\n        else\n        {\n            _1829 = _1821;\n        }\n        bool _1837;\n        if (!_1829)\n        {\n            _1837 = abs(_1816) > 0.5;\n        }\n        else\n        {\n            _1837 = _1829;\n        }\n        if (_1837)\n        {\n            continue;\n        }\n        float _1852 = clamp(dot(geo_normal, normalize(_1811)) * _1769.z, 0.0, 1.0);\n        if (_1852 <= 0.0)\n        {\n            continue;\n        }\n        float _1872 = (clamp((0.5 - abs(_1816)) * 10.0, 0.0, 1.0) * _1852) * _1769.x;\n        vec2 _1880 = vec2(_1802 + 0.5, 0.5 - _1809);\n        vec2 _1890 = vec2(dot(_1797, _1686), dot(_1804, _1686));\n        vec2 _1900 = vec2(dot(_1797, _1689), dot(_1804, _1689));\n        int param_8 = _1764 + 5;\n        vec4 _1905 = fa_light_texel(param_8);\n        int param_9 = _1764 + 3;\n        vec4 _1910 = fa_light_texel(param_9);\n        int param_10 = _1764 + 4;\n        vec4 _1915 = fa_light_texel(param_10);\n        float tex_a = 1.0;\n        vec3 col = _1905.xyz;\n        bool _1925 = _1910.z > _1910.x;\n        if (_1925)\n        {\n            vec4 param_11 = _1910;\n            vec2 param_12 = _1880;\n            vec2 param_13 = _1714;\n            vec2 param_14 = _1890;\n            vec2 param_15 = _1900;\n            vec4 tx = fa_decal_tile(param_11, param_12, param_13, param_14, param_15);\n            if ((_1724 > 0.5) && (_1724 < 1.5))\n            {\n                vec3 param_16 = tx.xyz;\n                vec3 _1951 = fa_dc_to_linear(param_16);\n                vec4 _6173 = tx;\n                _6173.x = _1951.x;\n                _6173.y = _1951.y;\n                _6173.z = _1951.z;\n                tx = _6173;\n            }\n            col *= tx.xyz;\n            tex_a = tx.w;\n        }\n        albedo = mix(albedo, col, vec3(clamp((_1872 * tex_a) * _1905.w, 0.0, 1.0)));\n        if (_1915.z > _1915.x)\n        {\n            vec4 param_17 = _1915;\n            vec2 param_18 = _1880;\n            vec2 param_19 = _1714;\n            vec2 param_20 = _1890;\n            vec2 param_21 = _1900;\n            vec4 _1995 = fa_decal_tile(param_17, param_18, param_19, param_20, param_21);\n            if (_1724 > 1.5)\n            {\n                vec3 param_22 = _1995.xyz;\n                vec3 _2005 = fa_dc_to_srgb(param_22);\n                _1999 = _2005;\n            }\n            else\n            {\n                _1999 = _1995.xyz;\n            }\n            vec3 _2014 = (_1999 * 2.0) - vec3(1.0);\n            vec2 _2019 = _2014.xy * _1769.y;\n            vec3 _2041 = (normalize(_1797) * _2019.x) + (normalize(_1804) * _2019.y);\n            vec3 _2044 = normalize(normal);\n            normal = normalize(mix(_2044, normalize((_2044 * max(_2014.z, 0.0500000007450580596923828125)) + (_2041 - (_2044 * dot(_2044, _2041)))), vec3(clamp(_1872 * (_1925 ? tex_a : 1.0), 0.0, 1.0))));\n        }\n    }\n}\n\nint fa_light_count()\n{\n    return fa_cl_ndir + fa_cl_local;\n}\n\nLightSample fa_no_light()\n{\n    return LightSample(vec3(0.0, 1.0, 0.0), vec3(0.0), 0.0, 1.0, 0.0, 0);\n}\n\nint fa_cluster_index(int slot, int n)\n{\n    int param = (int(fa_mesh_fs_params[19].x) + int(fa_mesh_fs_params[19].w)) + ((slot + n) >> 2);\n    vec4 t = fa_light_texel(param);\n    return int(t[(slot + n) & 3]);\n}\n\nint fa_cl_light(int n)\n{\n    if (n < fa_cl_ndir)\n    {\n        return n;\n    }\n    int param = fa_cl_slot;\n    int param_1 = n - fa_cl_ndir;\n    return fa_cluster_index(param, param_1);\n}\n\nint fa_light_base(int li)\n{\n    return li * ((fa_mesh_fs_params[1].w > 4.5) ? 8 : 4);\n}\n\nbool fa_light_baked(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 3;\n    return fa_light_texel(param_1).w > 0.5;\n}\n\nfloat fa_baked_keep(int li)\n{\n    float _4694;\n    if (fa_lm.z > 0.5)\n    {\n        _4694 = 0.0;\n    }\n    else\n    {\n        _4694 = 1.0 - clamp(fa_mesh_fs_params[32].w, 0.0, 1.0);\n    }\n    bool _4705 = _4694 < 1.0;\n    bool _4711;\n    if (_4705)\n    {\n        int param = li;\n        _4711 = fa_light_baked(param);\n    }\n    else\n    {\n        _4711 = _4705;\n    }\n    return _4711 ? _4694 : 1.0;\n}\n\nvec3 fa_area_point(vec3 c, vec3 axis, vec3 ru, vec3 uu, float hx, float hy, float shape, vec3 p, vec3 r)\n{\n    bool _646 = dot(r, r) > 0.5;\n    if (shape > 1.5)\n    {\n        vec3 _659 = (c - (ru * hx)) - p;\n        vec3 _665 = ru * (2.0 * hx);\n        float _671 = max(dot(_665, _665), 9.9999999392252902907785028219223e-09);\n        float _675 = dot(_659, _665);\n        float t = clamp((-_675) / _671, 0.0, 1.0);\n        if (_646)\n        {\n            float _690 = dot(r, _665);\n            float _696 = _671 - (_690 * _690);\n            if (abs(_696) > (9.9999997473787516355514526367188e-06 * _671))\n            {\n                t = clamp(((dot(r, _659) * _690) - _675) / _696, 0.0, 1.0);\n            }\n        }\n        return (p + _659) + (_665 * t);\n    }\n    vec3 q = p;\n    float _728 = dot(r, axis);\n    bool _736;\n    if (_646)\n    {\n        _736 = abs(_728) > 9.9999997473787516355514526367188e-05;\n    }\n    else\n    {\n        _736 = _646;\n    }\n    if (_736)\n    {\n        float _746 = dot(c - p, axis) / _728;\n        if (_746 > 0.0)\n        {\n            q = p + (r * _746);\n        }\n    }\n    vec3 _759 = q - c;\n    vec2 xy = vec2(dot(_759, ru), dot(_759, uu));\n    if (shape > 0.5)\n    {\n        float _774 = length(xy);\n        if (_774 > hx)\n        {\n            xy *= (hx / _774);\n        }\n    }\n    else\n    {\n        xy = clamp(xy, vec2(-hx, -hy), vec2(hx, hy));\n    }\n    return (c + (ru * xy.x)) + (uu * xy.y);\n}\n\nvec4 fa_atlas_fetch(vec2 texel)\n{\n    return textureLod(fa_light_atlas_fa_env_smp, texel / vec2(textureSize(fa_light_atlas_fa_env_smp, 0)), 0.0);\n}\n\nvec3 fa_cookie_sample(vec2 tile_origin, vec2 uv)\n{\n    vec2 param = (tile_origin + vec2(1.0)) + (clamp(uv, vec2(0.0), vec2(1.0)) * 254.0);\n    return fa_atlas_fetch(param).xyz;\n}\n\nfloat fa_ies_sample(vec2 tile_origin, vec3 d, vec3 axis, vec3 right, vec3 up)\n{\n    float _566 = dot(d, right);\n    float _570 = dot(d, up);\n    float _581;\n    if (((_566 * _566) + (_570 * _570)) > 1.0000000133514319600180897396058e-10)\n    {\n        _581 = atan(_570, _566) * 0.15915493667125701904296875;\n    }\n    else\n    {\n        _581 = 0.0;\n    }\n    vec2 param = tile_origin + vec2(1.0 + ((_581 - floor(_581)) * 64.0), 1.0 + (acos(clamp(dot(d, axis), -1.0, 1.0)) * 10.18591594696044921875));\n    return fa_atlas_fetch(param).x;\n}\n\nint fa_cube_face(vec3 d)\n{\n    vec3 _415 = abs(d);\n    float _417 = _415.x;\n    float _419 = _415.y;\n    bool _420 = _417 >= _419;\n    bool _428;\n    if (_420)\n    {\n        _428 = _417 >= _415.z;\n    }\n    else\n    {\n        _428 = _420;\n    }\n    int _429;\n    if (_428)\n    {\n        _429 = (d.x > 0.0) ? 0 : 1;\n    }\n    else\n    {\n        int _444;\n        if (_419 >= _415.z)\n        {\n            _444 = (d.y > 0.0) ? 2 : 3;\n        }\n        else\n        {\n            _444 = (d.z > 0.0) ? 4 : 5;\n        }\n        _429 = _444;\n    }\n    return _429;\n}\n\nvoid fa_cube_face_basis(int f, out vec3 fwd, out vec3 up)\n{\n    if (f == 0)\n    {\n        fwd = vec3(1.0, 0.0, 0.0);\n        up = vec3(0.0, 1.0, 0.0);\n    }\n    else\n    {\n        if (f == 1)\n        {\n            fwd = vec3(-1.0, 0.0, 0.0);\n            up = vec3(0.0, 1.0, 0.0);\n        }\n        else\n        {\n            if (f == 2)\n            {\n                fwd = vec3(0.0, 1.0, 0.0);\n                up = vec3(0.0, 0.0, 1.0);\n            }\n            else\n            {\n                if (f == 3)\n                {\n                    fwd = vec3(0.0, -1.0, 0.0);\n                    up = vec3(0.0, 0.0, -1.0);\n                }\n                else\n                {\n                    if (f == 4)\n                    {\n                        fwd = vec3(0.0, 0.0, 1.0);\n                        up = vec3(0.0, 1.0, 0.0);\n                    }\n                    else\n                    {\n                        fwd = vec3(0.0, 0.0, -1.0);\n                        up = vec3(0.0, 1.0, 0.0);\n                    }\n                }\n            }\n        }\n    }\n}\n\nLightSample fa_light_sample_n(int li, vec3 world_pos, vec3 n)\n{\n    int param = li;\n    int _812 = fa_light_base(param);\n    bool _816 = fa_mesh_fs_params[1].w > 4.5;\n    int param_1 = _812;\n    vec4 _820 = fa_light_texel(param_1);\n    int param_2 = _812 + 1;\n    vec4 _825 = fa_light_texel(param_2);\n    float _828 = _825.w;\n    float atten = 1.0;\n    float dist = 0.0;\n    fa_light_tint = vec3(1.0);\n    bool _840 = _816 && (_828 > 2.5);\n    fa_light_is_area = _840;\n    bool _842 = _828 < 0.5;\n    vec3 l;\n    if (_842)\n    {\n        l = normalize(_820.xyz);\n        if (_816)\n        {\n            int param_3 = _812 + 6;\n            vec4 _856 = fa_light_texel(param_3);\n            if (_856.z > 0.5)\n            {\n                int param_4 = _812 + 4;\n                vec4 _866 = fa_light_texel(param_4);\n                int param_5 = _812 + 5;\n                vec4 _871 = fa_light_texel(param_5);\n                vec2 param_6 = _856.xy;\n                vec2 param_7 = fract(vec2(dot(world_pos, _866.xyz) * _866.w, (-dot(world_pos, _871.xyz)) * _871.w) + vec2(0.5));\n                fa_light_tint = fa_cookie_sample(param_6, param_7);\n            }\n        }\n    }\n    else\n    {\n        vec3 _901 = _820.xyz;\n        vec3 _903 = _901 - world_pos;\n        vec3 to_light = _903;\n        float _906 = length(_903);\n        float reach = _906;\n        bool front = true;\n        if (_840)\n        {\n            int param_8 = _812 + 7;\n            reach = max(_906 - fa_light_texel(param_8).w, 0.0);\n            int param_9 = _812 + 4;\n            vec4 _930 = fa_light_texel(param_9);\n            int param_10 = _812 + 5;\n            vec4 _935 = fa_light_texel(param_10);\n            int param_11 = _812 + 6;\n            vec4 _940 = fa_light_texel(param_11);\n            float _941 = _940.w;\n            int param_12 = _812 + 2;\n            vec3 _948 = normalize(fa_light_texel(param_12).xyz);\n            bool _950 = _941 > 1.5;\n            bool _958;\n            if (!_950)\n            {\n                _958 = dot(_948, to_light) < 0.0;\n            }\n            else\n            {\n                _958 = _950;\n            }\n            front = _958;\n            vec3 r = vec3(0.0);\n            vec3 _967 = fa_mesh_fs_params[0].xyz - world_pos;\n            bool _971 = dot(n, n) > 0.5;\n            bool _979;\n            if (_971)\n            {\n                _979 = dot(_967, _967) > 9.9999999600419720025001879548654e-13;\n            }\n            else\n            {\n                _979 = _971;\n            }\n            if (_979)\n            {\n                r = reflect(-normalize(_967), normalize(n));\n            }\n            vec3 param_13 = _901;\n            vec3 param_14 = _948;\n            vec3 param_15 = _930.xyz;\n            vec3 param_16 = _935.xyz;\n            float param_17 = _930.w;\n            float param_18 = _935.w;\n            float param_19 = _941;\n            vec3 param_20 = world_pos;\n            vec3 param_21 = r;\n            to_light = fa_area_point(param_13, param_14, param_15, param_16, param_17, param_18, param_19, param_20, param_21) - world_pos;\n        }\n        float _1015 = length(to_light);\n        dist = _1015;\n        l = to_light / vec3(max(_1015, 9.9999997473787516355514526367188e-05));\n        float _1029 = reach / max(_820.w, 0.001000000047497451305389404296875);\n        float _1035 = clamp(1.0 - (_1029 * _1029), 0.0, 1.0);\n        float _1037;\n        if (front)\n        {\n            _1037 = _1035 * _1035;\n        }\n        else\n        {\n            _1037 = 0.0;\n        }\n        atten = _1037;\n        bool _1048 = _828 < 2.5;\n        if ((_828 > 1.5) && _1048)\n        {\n            int param_22 = _812 + 2;\n            vec4 _1056 = fa_light_texel(param_22);\n            float _1066 = _1056.w;\n            int param_23 = _812 + 3;\n            vec4 _1071 = fa_light_texel(param_23);\n            float _1072 = _1071.x;\n            float cos_inner = _1072;\n            if (_1072 > 1.5)\n            {\n                cos_inner = mix(_1066, 1.0, 0.25);\n            }\n            atten *= smoothstep(_1066, cos_inner, dot(-l, normalize(_1056.xyz)));\n        }\n        if (_816 && (_828 < 1.5))\n        {\n            int param_24 = _812 + 6;\n            vec4 _1096 = fa_light_texel(param_24);\n            if (_1096.z > 0.5)\n            {\n                vec3 _1104 = -to_light;\n                int param_25 = _812 + 4;\n                int param_26 = _812 + 5;\n                vec3 _1118 = fa_light_texel(param_25).xyz;\n                vec3 _1122 = fa_light_texel(param_26).xyz;\n                vec3 _1131 = vec3(dot(_1104, _1118), dot(_1104, _1122), dot(_1104, cross(_1118, _1122)));\n                vec3 param_27 = _1131;\n                int _1135 = fa_cube_face(param_27);\n                int param_28 = _1135;\n                vec3 param_29;\n                vec3 param_30;\n                fa_cube_face_basis(param_28, param_29, param_30);\n                vec2 _1162 = vec2(dot(_1131, cross(param_29, param_30)), dot(_1131, param_30)) / vec2(max(dot(_1131, param_29), 9.9999997473787516355514526367188e-05));\n                int _1166 = _1135 / 3;\n                vec2 param_31 = _1096.xy + (vec2(float(_1135 - (_1166 * 3)), float(_1166)) * 256.0);\n                vec2 param_32 = vec2(0.5 + (0.5 * _1162.x), 0.5 - (0.5 * _1162.y));\n                fa_light_tint = fa_cookie_sample(param_31, param_32);\n            }\n            int param_33 = _812 + 7;\n            vec4 _1196 = fa_light_texel(param_33);\n            if (_1196.z > 0.5)\n            {\n                int param_34 = _812 + 2;\n                int param_35 = _812 + 4;\n                int param_36 = _812 + 5;\n                vec2 param_37 = _1196.xy;\n                vec3 param_38 = -l;\n                vec3 param_39 = normalize(fa_light_texel(param_34).xyz);\n                vec3 param_40 = fa_light_texel(param_35).xyz;\n                vec3 param_41 = fa_light_texel(param_36).xyz;\n                atten *= fa_ies_sample(param_37, param_38, param_39, param_40, param_41);\n            }\n        }\n        else\n        {\n            if (_816 && _1048)\n            {\n                int param_42 = _812 + 6;\n                vec4 _1243 = fa_light_texel(param_42);\n                int param_43 = _812 + 7;\n                vec4 _1248 = fa_light_texel(param_43);\n                bool _1251 = _1243.z > 0.5;\n                bool _1258;\n                if (!_1251)\n                {\n                    _1258 = _1248.z > 0.5;\n                }\n                else\n                {\n                    _1258 = _1251;\n                }\n                if (_1258)\n                {\n                    int param_44 = _812 + 2;\n                    vec4 _1265 = fa_light_texel(param_44);\n                    vec3 _1269 = normalize(_1265.xyz);\n                    int param_45 = _812 + 4;\n                    vec4 _1274 = fa_light_texel(param_45);\n                    int param_46 = _812 + 5;\n                    vec4 _1279 = fa_light_texel(param_46);\n                    if (_1251)\n                    {\n                        vec3 _1287 = -to_light;\n                        float _1294 = _1265.w;\n                        float _1310 = 0.5 / max(dot(_1287, _1269) * (sqrt(max(1.0 - (_1294 * _1294), 0.0)) / max(_1294, 0.001000000047497451305389404296875)), 9.9999997473787516355514526367188e-05);\n                        vec2 param_47 = _1243.xy;\n                        vec2 param_48 = vec2(0.5 + (dot(_1287, _1274.xyz) * _1310), 0.5 - (dot(_1287, _1279.xyz) * _1310));\n                        fa_light_tint = fa_cookie_sample(param_47, param_48);\n                    }\n                    if (_1248.z > 0.5)\n                    {\n                        vec2 param_49 = _1248.xy;\n                        vec3 param_50 = -l;\n                        vec3 param_51 = _1269;\n                        vec3 param_52 = _1274.xyz;\n                        vec3 param_53 = _1279.xyz;\n                        atten *= fa_ies_sample(param_49, param_50, param_51, param_52, param_53);\n                    }\n                }\n            }\n        }\n    }\n    vec3 _5891 = _825.xyz * atten;\n    if (_816)\n    {\n        _5891 *= fa_light_tint;\n    }\n    int _1379;\n    if (_842)\n    {\n        _1379 = 0;\n    }\n    else\n    {\n        _1379 = ((_828 > 1.5) && (_828 < 2.5)) ? 2 : 1;\n    }\n    return LightSample(l, _5891, atten, 1.0, dist, _1379);\n}\n\nLightSample fa_light_unshadowed(int n, SurfaceInput i)\n{\n    bool _4923 = n < 0;\n    bool _4930;\n    if (!_4923)\n    {\n        _4930 = n >= fa_light_count();\n    }\n    else\n    {\n        _4930 = _4923;\n    }\n    if (_4930)\n    {\n        return fa_no_light();\n    }\n    int param = n;\n    int _4938 = fa_cl_light(param);\n    int param_1 = _4938;\n    float _4942 = fa_baked_keep(param_1);\n    if (_4942 <= 0.0)\n    {\n        return fa_no_light();\n    }\n    int param_2 = _4938;\n    vec3 param_3 = i.world_pos;\n    vec3 param_4 = i.world_normal;\n    LightSample _4958 = fa_light_sample_n(param_2, param_3, param_4);\n    return LightSample(_4958.direction, _4958.color * _4942, _4958.attenuation * _4942, _4958.shadow, _4958._distance, _4958.type);\n}\n\nfloat fa_light_type(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 1;\n    return fa_light_texel(param_1).w;\n}\n\nfloat fa_shadow_depth(inout vec2 uv, vec4 rect)\n{\n    uv = clamp(uv, rect.xy, rect.zw);\n    return textureLod(fa_shadow_tex_fa_shadow_smp, uv, 0.0).x;\n}\n\nfloat fa_shadow_fetch(vec2 uv, vec4 rect, vec3 conv)\n{\n    vec2 param = uv;\n    vec4 param_1 = rect;\n    float _2168 = fa_shadow_depth(param, param_1);\n    float _2172;\n    if (conv.x < 0.5)\n    {\n        _2172 = _2168;\n    }\n    else\n    {\n        _2172 = (conv.y * conv.z) / (conv.z - (_2168 * (conv.z - conv.y)));\n    }\n    return _2172;\n}\n\nfloat fa_shadow_noise()\n{\n    return fract(52.98291778564453125 * fract(dot(gl_FragCoord.xy, vec2(0.067110560834407806396484375, 0.005837149918079376220703125))));\n}\n\nvec2 fa_shadow_vogel_turn(vec2 d)\n{\n    return vec2((d.x * (-0.737368881702423095703125)) - (d.y * 0.675490319728851318359375), (d.y * (-0.737368881702423095703125)) + (d.x * 0.675490319728851318359375));\n}\n\nfloat fa_shadow_filter(vec2 uv, vec4 rect, float zr, float texel_m, float unit, float reach, float plane, vec3 conv, int mode, float k)\n{\n    if (mode == 1)\n    {\n        vec2 param = uv;\n        vec4 param_1 = rect;\n        vec3 param_2 = conv;\n        return float(zr <= fa_shadow_fetch(param, param_1, param_2));\n    }\n    float _2218 = fa_shadow_noise() * 6.283185482025146484375;\n    vec2 _2224 = vec2(cos(_2218), sin(_2218));\n    vec2 dir = _2224;\n    float radius = 1.5;\n    if (mode == 2)\n    {\n        float _2233;\n        if (k < 0.0)\n        {\n            _2233 = (-k) / max(zr, 0.100000001490116119384765625);\n        }\n        else\n        {\n            _2233 = k;\n        }\n        float _2252 = clamp((_2233 * reach) / texel_m, 3.0, 12.0);\n        float sum = 0.0;\n        float cnt = 0.0;\n        for (int i = 0; i < 16; i++)\n        {\n            float _2271 = sqrt((float(i) + 0.5) * 0.0625) * _2252;\n            vec2 param_3 = uv + (dir * (fa_shadows[26].zw * _2271));\n            vec4 param_4 = rect;\n            vec3 param_5 = conv;\n            float _2285 = fa_shadow_fetch(param_3, param_4, param_5);\n            if (_2285 < (zr - (_2271 * plane)))\n            {\n                sum += _2285;\n                cnt += 1.0;\n            }\n            vec2 param_6 = dir;\n            dir = fa_shadow_vogel_turn(param_6);\n        }\n        if (cnt < 0.5)\n        {\n            return 1.0;\n        }\n        float _2313 = sum / cnt;\n        float _2323;\n        if (k < 0.0)\n        {\n            _2323 = (-k) / max(_2313, 0.0500000007450580596923828125);\n        }\n        else\n        {\n            _2323 = k;\n        }\n        radius = clamp(((max(zr - _2313, 0.0) * unit) * _2323) / texel_m, 1.5, 16.0);\n        dir = _2224;\n    }\n    float lit = 0.0;\n    int _2349 = (mode == 2) ? 24 : 16;\n    for (int i_1 = 0; i_1 < _2349; i_1++)\n    {\n        float _2368 = sqrt((float(i_1) + 0.5) / float(_2349)) * radius;\n        vec2 param_7 = uv + (dir * (fa_shadows[26].zw * _2368));\n        vec4 param_8 = rect;\n        vec3 param_9 = conv;\n        lit += float((zr - (_2368 * plane)) <= fa_shadow_fetch(param_7, param_8, param_9));\n        vec2 param_10 = dir;\n        dir = fa_shadow_vogel_turn(param_10);\n    }\n    return lit / float(_2349);\n}\n\nfloat fa_shadow_local(int li, vec3 lpos, vec3 world, vec3 n, vec3 l)\n{\n    bool _2573 = fa_mesh_fs_params[5].z < 0.5;\n    bool _2580;\n    if (!_2573)\n    {\n        _2580 = fa_shadows[29].x < 0.5;\n    }\n    else\n    {\n        _2580 = _2573;\n    }\n    if (_2580)\n    {\n        return 1.0;\n    }\n    int param = (int(fa_shadows[29].x + 0.5) - 1) + li;\n    vec4 _2593 = fa_light_texel(param);\n    float _2594 = _2593.x;\n    if (_2594 < 0.0)\n    {\n        return 1.0;\n    }\n    int _2603 = int(_2594 + 0.5);\n    int param_1 = _2603;\n    vec4 _2607 = fa_light_texel(param_1);\n    int param_2 = _2603 + 1;\n    vec4 _2612 = fa_light_texel(param_2);\n    float fade = 1.0;\n    float _2615 = _2607.y;\n    if (_2615 > 0.0)\n    {\n        float _2632 = 1.0 - smoothstep(0.75 * _2615, _2615, length(world - fa_shadows[27].xyz));\n        fade = _2632;\n        if (_2632 <= 0.0)\n        {\n            return 1.0;\n        }\n    }\n    int face = 0;\n    if (_2607.x > 1.5)\n    {\n        vec3 param_3 = world - lpos;\n        face = fa_cube_face(param_3);\n    }\n    int _2656 = (_2603 + 2) + (face * 6);\n    int param_4 = _2656;\n    int param_5 = _2656 + 1;\n    int param_6 = _2656 + 3;\n    vec4 _2670 = fa_light_texel(param_6);\n    int param_7 = _2656 + 4;\n    vec4 _2675 = fa_light_texel(param_7);\n    int param_8 = _2656 + 5;\n    vec4 _2680 = fa_light_texel(param_8);\n    float _2692 = _2680.x * max(dot(_2670, vec4(world, 1.0)), 0.001000000047497451305389404296875);\n    float _2697 = clamp(dot(n, l), 0.0, 1.0);\n    float _2720 = clamp(dot(n, _2670.xyz), -1.0, 1.0);\n    float _2739 = min(sqrt(1.0 - (_2720 * _2720)) / max(abs(dot(n, world - lpos)) / max(dot(_2670, vec4(world, 1.0)), 0.001000000047497451305389404296875), 0.20000000298023223876953125), 4.0);\n    float _2742 = _2612.y;\n    float _2744;\n    if (_2742 > 0.0)\n    {\n        _2744 = _2742;\n    }\n    else\n    {\n        _2744 = 1.5 * _2692;\n    }\n    vec4 _2764 = vec4(world + (n * (_2744 * sqrt(1.0 - (_2697 * _2697)))), 1.0);\n    float _2768 = dot(_2670, _2764);\n    float _2771 = _2680.y;\n    if (_2768 < _2771)\n    {\n        return 1.0;\n    }\n    vec2 _2786 = vec2(dot(fa_light_texel(param_4), _2764), dot(fa_light_texel(param_5), _2764)) / vec2(_2768);\n    float _2788 = _2786.x;\n    bool _2791 = _2788 < _2675.x;\n    bool _2800;\n    if (!_2791)\n    {\n        _2800 = _2788 > _2675.z;\n    }\n    else\n    {\n        _2800 = _2791;\n    }\n    bool _2809;\n    if (!_2800)\n    {\n        _2809 = _2786.y < _2675.y;\n    }\n    else\n    {\n        _2809 = _2800;\n    }\n    bool _2818;\n    if (!_2809)\n    {\n        _2818 = _2786.y > _2675.w;\n    }\n    else\n    {\n        _2818 = _2809;\n    }\n    if (_2818)\n    {\n        return 1.0;\n    }\n    float _2824 = _2612.x;\n    float _2826;\n    if (_2824 > 0.0)\n    {\n        _2826 = _2824;\n    }\n    else\n    {\n        _2826 = 1.5 * _2692;\n    }\n    vec2 param_9 = _2786;\n    vec4 param_10 = _2675;\n    float param_11 = _2768 - (_2826 * (1.0 + (0.5 * _2739)));\n    float param_12 = _2692;\n    float param_13 = 1.0;\n    float param_14 = _2680.z * 0.25;\n    float param_15 = (_2692 * min(_2739, 3.0)) * 0.5;\n    vec3 param_16 = vec3(1.0, _2771, _2680.z);\n    int param_17 = int(_2607.z + 0.5);\n    float param_18 = _2607.w;\n    return mix(1.0, fa_shadow_filter(param_9, param_10, param_11, param_12, param_13, param_14, param_15, param_16, param_17, param_18), fade);\n}\n\nfloat fa_shadow_split_at(int i)\n{\n    float _2111;\n    if (i == 0)\n    {\n        _2111 = fa_shadows[24].x;\n    }\n    else\n    {\n        float _2127;\n        if (i == 1)\n        {\n            _2127 = fa_shadows[24].y;\n        }\n        else\n        {\n            float _2135;\n            if (i == 2)\n            {\n                _2135 = fa_shadows[24].z;\n            }\n            else\n            {\n                _2135 = fa_shadows[24].w;\n            }\n            _2127 = _2135;\n        }\n        _2111 = _2127;\n    }\n    return _2111;\n}\n\nfloat fa_shadow_cascade(int ci, vec3 world, vec3 n, vec3 l)\n{\n    float _2414 = max(fa_shadows[ci * 1 + 20].y, 0.001000000047497451305389404296875);\n    float _2419 = clamp(dot(n, l), 0.0, 1.0);\n    float _2425 = sqrt(1.0 - (_2419 * _2419));\n    float _2433 = min(_2425 / max(_2419, 0.20000000298023223876953125), 4.0);\n    float _2438;\n    if (fa_shadows[26].y > 0.0)\n    {\n        _2438 = fa_shadows[26].y;\n    }\n    else\n    {\n        _2438 = 1.5 * fa_shadows[ci * 1 + 20].x;\n    }\n    vec4 _2463 = mat4(fa_shadows[ci * 4 + 0], fa_shadows[ci * 4 + 1], fa_shadows[ci * 4 + 2], fa_shadows[ci * 4 + 3]) * vec4(world + (n * (_2438 * _2425)), 1.0);\n    float _2470 = _2463.x;\n    bool _2473 = _2470 < fa_shadows[ci * 1 + 16].x;\n    bool _2482;\n    if (!_2473)\n    {\n        _2482 = _2470 > fa_shadows[ci * 1 + 16].z;\n    }\n    else\n    {\n        _2482 = _2473;\n    }\n    bool _2491;\n    if (!_2482)\n    {\n        _2491 = _2463.y < fa_shadows[ci * 1 + 16].y;\n    }\n    else\n    {\n        _2491 = _2482;\n    }\n    bool _2500;\n    if (!_2491)\n    {\n        _2500 = _2463.y > fa_shadows[ci * 1 + 16].w;\n    }\n    else\n    {\n        _2500 = _2491;\n    }\n    bool _2507;\n    if (!_2500)\n    {\n        _2507 = _2463.z > 1.0;\n    }\n    else\n    {\n        _2507 = _2500;\n    }\n    if (_2507)\n    {\n        return -1.0;\n    }\n    float _2515;\n    if (fa_shadows[26].x > 0.0)\n    {\n        _2515 = fa_shadows[26].x;\n    }\n    else\n    {\n        _2515 = 1.5 * fa_shadows[ci * 1 + 20].x;\n    }\n    vec2 param = _2463.xy;\n    vec4 param_1 = fa_shadows[ci * 1 + 16];\n    float param_2 = _2463.z - ((_2515 * (1.0 + (0.5 * _2433))) / _2414);\n    float param_3 = fa_shadows[ci * 1 + 20].x;\n    float param_4 = _2414;\n    float param_5 = _2414 * 0.25;\n    float param_6 = ((fa_shadows[ci * 1 + 20].x * min(_2433, 3.0)) * 0.5) / _2414;\n    vec3 param_7 = vec3(0.0);\n    int param_8 = int(fa_shadows[25].z + 0.5);\n    float param_9 = fa_shadows[25].w;\n    return fa_shadow_filter(param, param_1, param_2, param_3, param_4, param_5, param_6, param_7, param_8, param_9);\n}\n\nfloat fa_shadow_sun(vec3 world, vec3 n, vec3 l)\n{\n    if (fa_mesh_fs_params[5].z < 0.5)\n    {\n        return 1.0;\n    }\n    int _2893 = int(fa_shadows[25].x + 0.5);\n    if (_2893 < 1)\n    {\n        return 1.0;\n    }\n    float _2908 = dot(world - fa_shadows[27].xyz, fa_shadows[28].xyz);\n    int param = _2893 - 1;\n    if (_2908 > fa_shadow_split_at(param))\n    {\n        return 1.0;\n    }\n    int ci = 0;\n    bool _2920 = _2893 > 1;\n    bool _2927;\n    if (_2920)\n    {\n        _2927 = _2908 > fa_shadows[24].x;\n    }\n    else\n    {\n        _2927 = _2920;\n    }\n    if (_2927)\n    {\n        ci = 1;\n    }\n    bool _2931 = _2893 > 2;\n    bool _2938;\n    if (_2931)\n    {\n        _2938 = _2908 > fa_shadows[24].y;\n    }\n    else\n    {\n        _2938 = _2931;\n    }\n    if (_2938)\n    {\n        ci = 2;\n    }\n    bool _2942 = _2893 > 3;\n    bool _2949;\n    if (_2942)\n    {\n        _2949 = _2908 > fa_shadows[24].z;\n    }\n    else\n    {\n        _2949 = _2942;\n    }\n    if (_2949)\n    {\n        ci = 3;\n    }\n    float s = -1.0;\n    float s2 = -1.0;\n    float t = 0.0;\n    int _2960 = min(_2893, 4);\n    float _3001;\n    for (int c = ci; c < _2960; c++)\n    {\n        int param_1 = c;\n        vec3 param_2 = world;\n        vec3 param_3 = n;\n        vec3 param_4 = l;\n        float _2980 = fa_shadow_cascade(param_1, param_2, param_3, param_4);\n        if (s >= 0.0)\n        {\n            s2 = _2980;\n            break;\n        }\n        if (_2980 < 0.0)\n        {\n            continue;\n        }\n        s = _2980;\n        ci = c;\n        if (fa_shadows[25].y > 0.0)\n        {\n            if (ci > 0)\n            {\n                int param_5 = ci - 1;\n                _3001 = fa_shadow_split_at(param_5);\n            }\n            else\n            {\n                _3001 = fa_shadows[28].w;\n            }\n            int param_6 = ci;\n            float _3020 = fa_shadows[25].y * max(fa_shadow_split_at(param_6) - _3001, 9.9999997473787516355514526367188e-05);\n            int param_7 = ci;\n            t = clamp((_2908 - (fa_shadow_split_at(param_7) - _3020)) / _3020, 0.0, 1.0);\n        }\n        if (t <= 0.0)\n        {\n            break;\n        }\n    }\n    if (s < 0.0)\n    {\n        return 1.0;\n    }\n    if (t > 0.0)\n    {\n        float _3052;\n        if ((ci + 1) < _2893)\n        {\n            _3052 = (s2 < 0.0) ? s : s2;\n        }\n        else\n        {\n            _3052 = 1.0;\n        }\n        s = mix(s, _3052, t);\n    }\n    return s;\n}\n\nfloat fa_shadow_factor(vec3 n, vec3 l)\n{\n    vec3 param = fa_world_pos;\n    vec3 param_1 = n;\n    vec3 param_2 = l;\n    return fa_shadow_sun(param, param_1, param_2);\n}\n\nfloat fa_contact_shadow(int li, vec3 world, vec3 gn, vec3 l, float dist)\n{\n    bool _4430 = fa_mesh_fs_params[24].x < 0.5;\n    bool _4437;\n    if (!_4430)\n    {\n        _4437 = fa_shadows[29].x < 0.5;\n    }\n    else\n    {\n        _4437 = _4430;\n    }\n    if (_4437)\n    {\n        return 1.0;\n    }\n    int param = (int(fa_shadows[29].x + 0.5) - 1) + li;\n    vec4 _4450 = fa_light_texel(param);\n    float _4451 = _4450.y;\n    float len = _4451;\n    if (_4451 <= 0.0)\n    {\n        return 1.0;\n    }\n    float _4463 = length(world - fa_mesh_fs_params[0].xyz);\n    float _4473 = 1.0 - smoothstep(0.5 * fa_mesh_fs_params[25].x, fa_mesh_fs_params[25].x, _4463);\n    if (_4473 <= 0.0)\n    {\n        return 1.0;\n    }\n    float _4479 = len;\n    float _4482 = min(_4479, 0.89999997615814208984375 * dist);\n    len = _4482;\n    float _4487 = 0.004999999888241291046142578125 + (0.0030000000260770320892333984375 * _4463);\n    float _4492 = _4487 + (0.5 * _4482);\n    vec3 _4498 = world + (gn * _4487);\n    float _4500 = fa_shadow_noise();\n    float occ = 0.0;\n    float _4564;\n    for (int k = 0; k < 12; k++)\n    {\n        float _4515 = (float(k) + _4500) * 0.083333335816860198974609375;\n        vec3 _4523 = _4498 + (l * (_4515 * len));\n        vec4 _4529 = vec4(_4523, 1.0);\n        float _4535 = dot(fa_mesh_fs_params[28], _4529);\n        if (_4535 < 9.9999997473787516355514526367188e-05)\n        {\n            break;\n        }\n        vec2 _4555 = vec2(dot(fa_mesh_fs_params[26], _4529), dot(fa_mesh_fs_params[27], _4529)) / vec2(_4535);\n        float _4559 = _4555.x * 0.5;\n        float _4560 = _4559 + 0.5;\n        if (fa_mesh_fs_params[24].y > 0.5)\n        {\n            _4564 = (_4555.y * 0.5) + 0.5;\n        }\n        else\n        {\n            _4564 = 0.5 - (_4555.y * 0.5);\n        }\n        bool _4580 = _4560 < 0.0;\n        bool _4587;\n        if (!_4580)\n        {\n            _4587 = _4560 >= 1.0;\n        }\n        else\n        {\n            _4587 = _4580;\n        }\n        bool _4594;\n        if (!_4587)\n        {\n            _4594 = _4564 < 0.0;\n        }\n        else\n        {\n            _4594 = _4587;\n        }\n        bool _4601;\n        if (!_4594)\n        {\n            _4601 = _4564 >= 1.0;\n        }\n        else\n        {\n            _4601 = _4594;\n        }\n        if (_4601)\n        {\n            break;\n        }\n        vec4 _4628 = texelFetch(fa_screen_tex_fa_shadow_smp, clamp(ivec2(vec2(_4560, _4564) * fa_mesh_fs_params[24].zw), ivec2(0), ivec2(fa_mesh_fs_params[24].zw) - ivec2(1)), 0);\n        if (_4628.w < 0.5)\n        {\n            continue;\n        }\n        float _4647 = (dot(fa_mesh_fs_params[29].xyz, _4523) + fa_mesh_fs_params[29].w) - _4628.x;\n        if ((_4647 > _4487) && (_4647 < _4492))\n        {\n            occ = max(occ, (1.0 - (_4515 * _4515)) * smoothstep(0.0, 0.0500000007450580596923828125, min(min(_4560, 0.5 - _4559), min(_4564, 1.0 - _4564))));\n        }\n    }\n    return 1.0 - (occ * _4473);\n}\n\nLightSample fa_light_shadowed(int li, vec3 world_pos, vec3 gn)\n{\n    int param = li;\n    float _4750 = fa_baked_keep(param);\n    if (_4750 <= 0.0)\n    {\n        int param_1 = li;\n        return LightSample(vec3(0.0, 1.0, 0.0), vec3(0.0), 0.0, 1.0, 0.0, int(fa_light_type(param_1) + 0.5));\n    }\n    int param_2 = li;\n    vec3 param_3 = world_pos;\n    vec3 param_4 = gn;\n    LightSample _4776 = fa_light_sample_n(param_2, param_3, param_4);\n    vec3 _6037 = _4776.color;\n    float _6038 = _4776.attenuation;\n    float _6039 = _4776.shadow;\n    bool _4779 = _4776.type == 0;\n    if (_4779 && (li == 0))\n    {\n        vec3 param_5 = gn;\n        vec3 param_6 = _4776.direction;\n        float _4790 = fa_shadow_factor(param_5, param_6);\n        _6039 = _4790;\n        _6037 *= _4790;\n    }\n    else\n    {\n        bool _4801 = _4776.type != 0;\n        bool _4807;\n        if (_4801)\n        {\n            _4807 = _6038 > 0.0;\n        }\n        else\n        {\n            _4807 = _4801;\n        }\n        if (_4807)\n        {\n            int param_7 = li;\n            int param_8 = fa_light_base(param_7);\n            int param_9 = li;\n            vec3 param_10 = fa_light_texel(param_8).xyz;\n            vec3 param_11 = world_pos;\n            vec3 param_12 = gn;\n            vec3 param_13 = _4776.direction;\n            float _4826 = fa_shadow_local(param_9, param_10, param_11, param_12, param_13);\n            _6039 = _4826;\n            _6037 *= _4826;\n        }\n    }\n    bool _4836 = fa_mesh_fs_params[24].x > 0.5;\n    bool _4842;\n    if (_4836)\n    {\n        _4842 = _6038 > 0.0;\n    }\n    else\n    {\n        _4842 = _4836;\n    }\n    if (_4842)\n    {\n        float _4849;\n        if (_4779)\n        {\n            _4849 = 1000000000.0;\n        }\n        else\n        {\n            _4849 = _4776._distance;\n        }\n        int param_14 = li;\n        vec3 param_15 = world_pos;\n        vec3 param_16 = gn;\n        vec3 param_17 = _4776.direction;\n        float param_18 = _4849;\n        float _4867 = fa_contact_shadow(param_14, param_15, param_16, param_17, param_18);\n        _6039 *= _4867;\n        _6037 *= _4867;\n    }\n    float _4880 = _6038;\n    float _4881 = _4880 * _4750;\n    _6038 = _4881;\n    vec3 _4885 = _6037;\n    vec3 _4886 = _4885 * _4750;\n    _6037 = _4886;\n    return LightSample(_4776.direction, _4886, _4881, _6039, _4776._distance, _4776.type);\n}\n\nLightSample fa_light(int n, SurfaceInput i)\n{\n    bool _4897 = n < 0;\n    bool _4904;\n    if (!_4897)\n    {\n        _4904 = n >= fa_light_count();\n    }\n    else\n    {\n        _4904 = _4897;\n    }\n    if (_4904)\n    {\n        return fa_no_light();\n    }\n    int param = n;\n    int param_1 = fa_cl_light(param);\n    vec3 param_2 = i.world_pos;\n    vec3 param_3 = i.world_normal;\n    LightSample _4919 = fa_light_shadowed(param_1, param_2, param_3);\n    return _4919;\n}\n\nfloat fa_sheen_albedo(float ndv, float rough)\n{\n    float _3815 = min(sqrt(max(rough - 0.100000001490116119384765625, 0.0) * 1.111111164093017578125) * 6.0, 5.999000072479248046875);\n    float _3823 = min(sqrt(clamp(ndv, 0.0, 1.0)) * 8.0, 7.999000072479248046875);\n    int _3826 = int(_3815);\n    int _3829 = int(_3823);\n    float _3839 = _3823 - float(_3829);\n    int _3895 = (_3826 * 9) + _3829;\n    int _3915 = ((_3826 + 1) * 9) + _3829;\n    return mix(mix(_3890[_3895], _3890[_3895 + 1], _3839), mix(_3890[_3915], _3890[_3915 + 1], _3839), _3815 - float(_3826));\n}\n\nFaLayers fa_layers_setup(SurfaceInput i, Surface s, vec3 n, vec3 v, float metallic, float roughness, inout vec3 f0)\n{\n    bool _5903 = false;\n    float _5904 = 1.0;\n    float _5905 = 1.0;\n    float _5906 = 1.0;\n    float _5907 = 0.0;\n    float _5908 = 0.0;\n    float _5909 = 0.0;\n    float _5910 = 0.0;\n    float _5912 = 1.0;\n    bool _5913 = false;\n    vec3 _5914 = vec3(0.0);\n    float _5915 = 1.0;\n    float _5916 = 1.0;\n    float _5917 = 1.0;\n    float _5918 = 0.0;\n    float _5919 = 0.0;\n    vec3 _5920 = vec3(1.0, 0.0, 0.0);\n    vec3 _5921 = vec3(0.0, 0.0, 1.0);\n    float _5922 = 1.0;\n    float _5923 = 1.0;\n    float _3966 = clamp(s.specular, 0.0, 1.0);\n    float _3970 = clamp(s.ior, 1.0, 3.0);\n    bool _3975 = (_3966 != 1.0) || (_3970 != 1.5);\n    bool _3984;\n    if (!_3975)\n    {\n        _3984 = any(notEqual(s.specular_color, vec3(1.0)));\n    }\n    else\n    {\n        _3984 = _3975;\n    }\n    if (_3984)\n    {\n        float _3992 = (_3970 - 1.0) / (_3970 + 1.0);\n        f0 = mix(min(vec3(_3992 * _3992) * max(s.specular_color, vec3(0.0)), vec3(1.0)) * _3966, s.albedo, vec3(metallic));\n        _5904 = mix(_3966, 1.0, metallic);\n        _5903 = true;\n    }\n    float _4019 = clamp(s.clearcoat, 0.0, 1.0);\n    if (_4019 > 0.0)\n    {\n        float _4027 = clamp(s.clearcoat_roughness, 0.0500000007450580596923828125, 1.0);\n        _5907 = _4019;\n        _5908 = _4027;\n        float _4034 = _4027 * _4027;\n        _5909 = _4034;\n        _5910 = _4034 * _4034;\n        float _4046 = max(dot(i.world_normal, v), 9.9999997473787516355514526367188e-05);\n        _5912 = _4046;\n        _5905 = 1.0 - (_4019 * (0.039999999105930328369140625 + (0.959999978542327880859375 * pow(clamp(1.0 - _4046, 0.0, 1.0), 5.0))));\n        _5903 = true;\n    }\n    vec3 _4065 = max(s.sheen_color, vec3(0.0));\n    float _4074 = max(_4065.x, max(_4065.y, _4065.z));\n    if (_4074 > 0.0)\n    {\n        float _4082 = clamp(s.sheen_roughness, 0.100000001490116119384765625, 1.0);\n        _5913 = true;\n        _5914 = _4065;\n        _5915 = _4082;\n        _5916 = _4082 * _4082;\n        float param = max(dot(n, v), 9.9999997473787516355514526367188e-05);\n        float param_1 = _4082;\n        float _4099 = fa_sheen_albedo(param, param_1);\n        _5918 = _4099;\n        _5917 = 1.0 - min(_4074 * _4099, 1.0);\n        _5903 = true;\n    }\n    _5906 = _5905 * _5917;\n    float _4118 = clamp(s.anisotropy, -1.0, 1.0);\n    if (_4118 != 0.0)\n    {\n        vec3 _4133 = i.world_tangent.xyz - (n * dot(n, i.world_tangent.xyz));\n        vec3 t = _4133;\n        if (dot(_4133, _4133) < 9.9999999392252902907785028219223e-09)\n        {\n            bvec3 _4145 = bvec3(abs(n.y) < 0.9900000095367431640625);\n            t = cross(vec3(_4145.x ? vec3(0.0, 1.0, 0.0).x : vec3(1.0, 0.0, 0.0).x, _4145.y ? vec3(0.0, 1.0, 0.0).y : vec3(1.0, 0.0, 0.0).y, _4145.z ? vec3(0.0, 1.0, 0.0).z : vec3(1.0, 0.0, 0.0).z), n);\n        }\n        vec3 _4149 = t;\n        vec3 _4150 = normalize(_4149);\n        t = _4150;\n        vec3 _4175 = normalize((_4150 * cos(s.anisotropy_rotation)) + ((cross(n, _4150) * ((i.world_tangent.w < 0.0) ? (-1.0) : 1.0)) * sin(s.anisotropy_rotation)));\n        _5920 = _4175;\n        _5921 = cross(n, _4175);\n        float _4185 = roughness * roughness;\n        float _4191 = mix(_4185, 1.0, _4118 * _4118);\n        bool _4193 = _4118 > 0.0;\n        _5922 = _4193 ? _4191 : _4185;\n        _5923 = _4193 ? _4185 : _4191;\n        _5919 = _4118;\n        _5903 = true;\n    }\n    return FaLayers(_5903, _5904, _5905, _5906, _5907, _5908, _5909, _5910, i.world_normal, _5912, _5913, _5914, _5915, _5916, _5917, _5918, _5919, _5920, _5921, _5922, _5923);\n}\n\nvec2 fa_env_brdf(float rough, float ndv)\n{\n    vec4 _3747 = (vec4(-1.0, -0.0274999998509883880615234375, -0.572000026702880859375, 0.02199999988079071044921875) * rough) + vec4(1.0, 0.0425000004470348358154296875, 1.03999996185302734375, -0.039999999105930328369140625);\n    float _3750 = _3747.x;\n    return (vec2(-1.03999996185302734375, 1.03999996185302734375) * ((min(_3750 * _3750, exp2((-9.27999973297119140625) * ndv)) * _3750) + _3747.y)) + _3747.zw;\n}\n\nvec2 fa_oct_encode(vec3 d)\n{\n    vec3 _3182 = d / vec3(max((abs(d.x) + abs(d.y)) + abs(d.z), 9.9999999600419720025001879548654e-13));\n    float _3185 = _3182.x;\n    float _3187 = _3182.z;\n    vec2 e = vec2(_3185, _3187);\n    if (_3182.y < 0.0)\n    {\n        e = vec2((1.0 - abs(_3187)) * ((_3185 < 0.0) ? (-1.0) : 1.0), (1.0 - abs(_3185)) * ((_3187 < 0.0) ? (-1.0) : 1.0));\n    }\n    return e;\n}\n\nvec2 fa_atlas_size()\n{\n    return vec2(textureSize(fa_probe_atlas_fa_env_smp, 0));\n}\n\nvec3 fa_probe_level(vec2 origin, float res, int lv, vec2 e)\n{\n    float _3234;\n    if (lv == 0)\n    {\n        _3234 = 0.0;\n    }\n    else\n    {\n        _3234 = res + 2.0;\n    }\n    float _3244;\n    if (lv == 0)\n    {\n        _3244 = 0.0;\n    }\n    else\n    {\n        _3244 = (res - (res / float(1 << max((lv - 1), 0)))) + (2.0 * float(lv - 1));\n    }\n    return textureLod(fa_probe_atlas_fa_env_smp, (((origin + vec2(_3234, _3244)) + vec2(1.0)) + (((e * 0.5) + vec2(0.5)) * (res / float(1 << lv)))) / fa_atlas_size(), 0.0).xyz;\n}\n\nvec3 fa_probe_radiance(vec2 origin, float res, vec3 d, float rough)\n{\n    float _3290;\n    if (res > 64.5)\n    {\n        _3290 = 5.0;\n    }\n    else\n    {\n        _3290 = (res > 32.5) ? 4.0 : 3.0;\n    }\n    float _3305 = clamp(rough, 0.0, 1.0) * (_3290 - 1.0);\n    int _3312 = int(min(floor(_3305), _3290 - 2.0));\n    float _3317 = _3305 - float(_3312);\n    vec3 param = d;\n    vec2 _3321 = fa_oct_encode(param);\n    vec2 param_1 = origin;\n    float param_2 = res;\n    int param_3 = _3312;\n    vec2 param_4 = _3321;\n    vec3 _3331 = fa_probe_level(param_1, param_2, param_3, param_4);\n    if (_3317 < 0.00200000009499490261077880859375)\n    {\n        return _3331;\n    }\n    vec2 param_5 = origin;\n    float param_6 = res;\n    int param_7 = _3312 + 1;\n    vec2 param_8 = _3321;\n    return mix(_3331, fa_probe_level(param_5, param_6, param_7, param_8), vec3(_3317));\n}\n\nvec3 fa_probe_box_dir(vec3 d, vec4 posw, vec4 bx, vec4 by, vec4 bz)\n{\n    if (posw.w < 0.5)\n    {\n        return d;\n    }\n    float _3369 = dot(bx.xyz, fa_world_pos) + bx.w;\n    float _3376 = dot(by.xyz, fa_world_pos) + by.w;\n    float _3383 = dot(bz.xyz, fa_world_pos) + bz.w;\n    float _3389 = dot(bx.xyz, d);\n    float _3393 = dot(by.xyz, d);\n    float _3397 = dot(bz.xyz, d);\n    float _3403;\n    if (_3389 > 9.9999999747524270787835121154785e-07)\n    {\n        _3403 = (1.0 - _3369) / _3389;\n    }\n    else\n    {\n        float _3417;\n        if (_3389 < (-9.9999999747524270787835121154785e-07))\n        {\n            _3417 = ((-1.0) - _3369) / _3389;\n        }\n        else\n        {\n            _3417 = 1000000015047466219876688855040.0;\n        }\n        _3403 = _3417;\n    }\n    float tx = _3403;\n    float _3434;\n    if (_3393 > 9.9999999747524270787835121154785e-07)\n    {\n        _3434 = (1.0 - _3376) / _3393;\n    }\n    else\n    {\n        float _3447;\n        if (_3393 < (-9.9999999747524270787835121154785e-07))\n        {\n            _3447 = ((-1.0) - _3376) / _3393;\n        }\n        else\n        {\n            _3447 = 1000000015047466219876688855040.0;\n        }\n        _3434 = _3447;\n    }\n    float ty = _3434;\n    float _3463;\n    if (_3397 > 9.9999999747524270787835121154785e-07)\n    {\n        _3463 = (1.0 - _3383) / _3397;\n    }\n    else\n    {\n        float _3476;\n        if (_3397 < (-9.9999999747524270787835121154785e-07))\n        {\n            _3476 = ((-1.0) - _3383) / _3397;\n        }\n        else\n        {\n            _3476 = 1000000015047466219876688855040.0;\n        }\n        _3463 = _3476;\n    }\n    float _3488 = tx;\n    float _3491 = (_3488 > 0.0) ? _3488 : 1000000015047466219876688855040.0;\n    tx = _3491;\n    float _3492 = ty;\n    float _3495 = (_3492 > 0.0) ? _3492 : 1000000015047466219876688855040.0;\n    ty = _3495;\n    float _3505 = min(_3491, min(_3495, (_3463 > 0.0) ? _3463 : 1000000015047466219876688855040.0));\n    if (_3505 > 100000001504746621987668885504.0)\n    {\n        return d;\n    }\n    vec3 _3521 = (fa_world_pos + (d * _3505)) - posw.xyz;\n    vec3 _3526;\n    if (dot(_3521, _3521) > 1.0000000133514319600180897396058e-10)\n    {\n        _3526 = normalize(_3521);\n    }\n    else\n    {\n        _3526 = d;\n    }\n    return _3526;\n}\n\nvec3 fa_probe_environment(vec4 tile, vec4 posw, vec4 bx, vec4 by, vec4 bz, inout vec3 d, float rough)\n{\n    vec3 param = d;\n    vec4 param_1 = posw;\n    vec4 param_2 = bx;\n    vec4 param_3 = by;\n    vec4 param_4 = bz;\n    d = fa_probe_box_dir(param, param_1, param_2, param_3, param_4);\n    vec2 param_5 = tile.xy;\n    float param_6 = tile.z;\n    vec3 param_7 = d;\n    float param_8 = rough;\n    return fa_probe_radiance(param_5, param_6, param_7, param_8);\n}\n\nvec3 fa_environment(vec3 d, float rough)\n{\n    float _3572 = (1.0 - fa_mesh_fs_params[42].w) - fa_mesh_fs_params[47].w;\n    vec3 outc = vec3(0.0);\n    if (_3572 > 0.0005000000237487256526947021484375)\n    {\n        vec3 base;\n        if (fa_mesh_fs_params[11].w > 0.5)\n        {\n            vec2 param = fa_mesh_fs_params[41].zw;\n            float param_1 = 128.0;\n            vec3 param_2 = d;\n            float param_3 = rough;\n            base = fa_probe_radiance(param, param_1, param_2, param_3);\n        }\n        else\n        {\n            float _3602 = rough * rough;\n            float _3633 = 0.60000002384185791015625 * _3602;\n            base = mix(mix(fa_mesh_fs_params[12].xyz * 0.550000011920928955078125, mix(fa_mesh_fs_params[12].xyz, fa_mesh_fs_params[11].xyz, vec3(pow(clamp(d.y * (1.0 - (0.699999988079071044921875 * _3602)), 0.0, 1.0), 0.550000011920928955078125))), vec3(smoothstep((-0.0500000007450580596923828125) - _3633, 0.0500000007450580596923828125 + _3633, d.y))), ((fa_mesh_fs_params[11].xyz + fa_mesh_fs_params[12].xyz) * 0.5) * 0.800000011920928955078125, vec3(_3602 * 0.60000002384185791015625));\n        }\n        outc = base * _3572;\n    }\n    if (fa_mesh_fs_params[42].w > 0.0)\n    {\n        vec4 param_4 = fa_mesh_fs_params[42];\n        vec4 param_5 = fa_mesh_fs_params[43];\n        vec4 param_6 = fa_mesh_fs_params[44];\n        vec4 param_7 = fa_mesh_fs_params[45];\n        vec4 param_8 = fa_mesh_fs_params[46];\n        vec3 param_9 = d;\n        float param_10 = rough;\n        vec3 _3692 = fa_probe_environment(param_4, param_5, param_6, param_7, param_8, param_9, param_10);\n        outc += (_3692 * fa_mesh_fs_params[42].w);\n    }\n    if (fa_mesh_fs_params[47].w > 0.0)\n    {\n        vec4 param_11 = fa_mesh_fs_params[47];\n        vec4 param_12 = fa_mesh_fs_params[48];\n        vec4 param_13 = fa_mesh_fs_params[49];\n        vec4 param_14 = fa_mesh_fs_params[50];\n        vec4 param_15 = fa_mesh_fs_params[51];\n        vec3 param_16 = d;\n        float param_17 = rough;\n        vec3 _3724 = fa_probe_environment(param_11, param_12, param_13, param_14, param_15, param_16, param_17);\n        outc += (_3724 * fa_mesh_fs_params[47].w);\n    }\n    return outc;\n}\n\nvec3 fa_layers_ibl(FaLayers L, vec3 n, vec3 v, vec3 f0, float roughness, float occlusion)\n{\n    vec3 rn = n;\n    if (L.aniso != 0.0)\n    {\n        vec3 _4226;\n        if (L.aniso >= 0.0)\n        {\n            _4226 = L.b;\n        }\n        else\n        {\n            _4226 = L.t;\n        }\n        rn = normalize(mix(n, cross(cross(_4226, v), _4226), vec3(abs(L.aniso) * smoothstep(0.0, 0.25, roughness))));\n    }\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05);\n    vec2 _4262 = fa_env_brdf(param, param_1);\n    vec3 param_2 = reflect(-v, rn);\n    float param_3 = roughness;\n    vec3 result = (fa_environment(param_2, param_3) * ((f0 * _4262.x) + (vec3(L.f90) * _4262.y))) * L.base_scale;\n    if (L.sheen_on)\n    {\n        vec3 param_4 = n;\n        float param_5 = L.sheen_rough;\n        result += ((L.sheen * (L.sheen_e * L.keep)) * fa_environment(param_4, param_5));\n    }\n    result *= occlusion;\n    if (L.coat > 0.0)\n    {\n        float param_6 = L.coat_rough;\n        float param_7 = L.coat_ndv;\n        vec2 _4320 = fa_env_brdf(param_6, param_7);\n        vec3 param_8 = reflect(-v, L.nc);\n        float param_9 = L.coat_rough;\n        result += (fa_environment(param_8, param_9) * (L.coat * ((0.039999999105930328369140625 * _4320.x) + _4320.y)));\n    }\n    return result;\n}\n\nvec3 fa_sky_reflection(vec3 n, vec3 v, vec3 f0, float roughness)\n{\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05);\n    vec2 _3789 = fa_env_brdf(param, param_1);\n    vec3 param_2 = reflect(-v, n);\n    float param_3 = roughness;\n    return fa_environment(param_2, param_3) * ((f0 * _3789.x) + vec3(_3789.y));\n}\n\nvec3 fa_sky_light(SurfaceInput i, Surface s)\n{\n    float _4359 = clamp(s.metallic, 0.0, 1.0);\n    float _4363 = clamp(s.roughness, 0.0500000007450580596923828125, 1.0);\n    vec3 _4370 = mix(vec3(0.039999999105930328369140625), s.albedo, vec3(_4359));\n    vec3 f0 = _4370;\n    vec3 _4374 = normalize(s.normal);\n    SurfaceInput param = i;\n    Surface param_1 = s;\n    vec3 param_2 = _4374;\n    vec3 param_3 = i.view_dir;\n    float param_4 = _4359;\n    float param_5 = _4363;\n    vec3 param_6 = _4370;\n    FaLayers _4391 = fa_layers_setup(param, param_1, param_2, param_3, param_4, param_5, param_6);\n    f0 = param_6;\n    if (_4391.on)\n    {\n        FaLayers param_7 = _4391;\n        vec3 param_8 = _4374;\n        vec3 param_9 = i.view_dir;\n        vec3 param_10 = f0;\n        float param_11 = _4363;\n        float param_12 = s.occlusion;\n        return fa_layers_ibl(param_7, param_8, param_9, param_10, param_11, param_12);\n    }\n    vec3 param_13 = _4374;\n    vec3 param_14 = i.view_dir;\n    vec3 param_15 = f0;\n    float param_16 = _4363;\n    return fa_sky_reflection(param_13, param_14, param_15, param_16) * s.occlusion;\n}\n\nvec3 lighting(SurfaceInput i, Surface s)\n{\n    int best = -1;\n    float bestPower = 0.0;\n    for (int n = 0; n < fa_light_count(); n++)\n    {\n        int param = n;\n        SurfaceInput param_1 = i;\n        LightSample _4989 = fa_light_unshadowed(param, param_1);\n        float _4997 = dot(_4989.color, vec3(0.2989999949932098388671875, 0.58700001239776611328125, 0.114000000059604644775390625));\n        if (_4997 > bestPower)\n        {\n            bestPower = _4997;\n            best = n;\n        }\n    }\n    vec3 lit = (fa_mesh_fs_params[1].xyz * s.albedo) * s.occlusion;\n    if (best >= 0)\n    {\n        int param_2 = best;\n        SurfaceInput param_3 = i;\n        LightSample _5026 = fa_light(param_2, param_3);\n        float _5034;\n        if (dot(s.normal, _5026.direction) > 0.5)\n        {\n            _5034 = 1.0;\n        }\n        else\n        {\n            _5034 = fa_material[0].x;\n        }\n        lit += ((s.albedo * _5026.color) * _5034);\n    }\n    SurfaceInput param_4 = i;\n    Surface param_5 = s;\n    return lit + (fa_sky_light(param_4, param_5) * fa_material[1].x);\n}\n\nvec3 fa_shadow_debug(vec3 color, vec3 world)\n{\n    if (fa_shadows[27].w < 0.5)\n    {\n        return color;\n    }\n    int _3080 = int(fa_shadows[25].x + 0.5);\n    float _3090 = dot(world - fa_shadows[27].xyz, fa_shadows[28].xyz);\n    vec3 tint = vec3(0.3499999940395355224609375);\n    bool _3095 = _3080 > 0;\n    bool _3104;\n    if (_3095)\n    {\n        int param = _3080 - 1;\n        _3104 = _3090 <= fa_shadow_split_at(param);\n    }\n    else\n    {\n        _3104 = _3095;\n    }\n    if (_3104)\n    {\n        tint = vec3(1.0, 0.1500000059604644775390625, 0.100000001490116119384765625);\n        bool _3110 = _3080 > 1;\n        bool _3117;\n        if (_3110)\n        {\n            _3117 = _3090 > fa_shadows[24].x;\n        }\n        else\n        {\n            _3117 = _3110;\n        }\n        if (_3117)\n        {\n            tint = vec3(0.100000001490116119384765625, 0.89999997615814208984375, 0.20000000298023223876953125);\n        }\n        bool _3123 = _3080 > 2;\n        bool _3130;\n        if (_3123)\n        {\n            _3130 = _3090 > fa_shadows[24].y;\n        }\n        else\n        {\n            _3130 = _3123;\n        }\n        if (_3130)\n        {\n            tint = vec3(0.1500000059604644775390625, 0.300000011920928955078125, 1.0);\n        }\n        bool _3136 = _3080 > 3;\n        bool _3143;\n        if (_3136)\n        {\n            _3143 = _3090 > fa_shadows[24].z;\n        }\n        else\n        {\n            _3143 = _3136;\n        }\n        if (_3143)\n        {\n            tint = vec3(1.0, 0.89999997615814208984375, 0.100000001490116119384765625);\n        }\n    }\n    return mix(color, tint, vec3(0.550000011920928955078125));\n}\n\nvoid main()\n{\n    fa_inst_load();\n    vec3 _5757 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _5757 = -_5757;\n    }\n    vec3 _5427 = normalize(fa_mesh_fs_params[0].xyz - fa_world_pos);\n    vec3 param = fa_world_pos;\n    fa_cluster_begin(param);\n    SurfaceInput param_1 = SurfaceInput(fa_world_pos, _5757, fa_world_tangent, fa_uv, fa_vertex_color, _5427, gl_FrontFacing);\n    Surface _5435 = fa_standard_surface(param_1);\n    vec3 _5788 = _5435.albedo;\n    float _5789 = _5435.alpha;\n    vec3 _5790 = _5435.normal;\n    float _5791 = _5435.metallic;\n    float _5792 = _5435.roughness;\n    float _5793 = _5435.occlusion;\n    vec3 _5794 = _5435.emission;\n    float _5795 = _5435.clearcoat;\n    float _5796 = _5435.clearcoat_roughness;\n    vec3 _5797 = _5435.sheen_color;\n    float _5798 = _5435.sheen_roughness;\n    float _5799 = _5435.anisotropy;\n    float _5800 = _5435.anisotropy_rotation;\n    float _5801 = _5435.specular;\n    float _5802 = _5435.ior;\n    vec3 _5803 = _5435.specular_color;\n    float _5804 = _5435.transmission;\n    float _5805 = _5435.thickness;\n    vec3 _5806 = _5435.attenuation_color;\n    float _5807 = _5435.attenuation_distance;\n    SurfaceInput param_2 = SurfaceInput(fa_world_pos, _5757, fa_world_tangent, fa_uv, fa_vertex_color, _5427, gl_FrontFacing);\n    Surface param_3 = _5435;\n    surface(param_2, param_3);\n    _5788 = param_3.albedo;\n    _5789 = param_3.alpha;\n    _5790 = param_3.normal;\n    _5791 = param_3.metallic;\n    _5792 = param_3.roughness;\n    _5793 = param_3.occlusion;\n    _5794 = param_3.emission;\n    _5795 = param_3.clearcoat;\n    _5796 = param_3.clearcoat_roughness;\n    _5797 = param_3.sheen_color;\n    _5798 = param_3.sheen_roughness;\n    _5799 = param_3.anisotropy;\n    _5800 = param_3.anisotropy_rotation;\n    _5801 = param_3.specular;\n    _5802 = param_3.ior;\n    _5803 = param_3.specular_color;\n    _5804 = param_3.transmission;\n    _5805 = param_3.thickness;\n    _5806 = param_3.attenuation_color;\n    _5807 = param_3.attenuation_distance;\n    vec3 param_4 = fa_world_pos;\n    vec3 param_5 = _5757;\n    vec3 param_6 = param_3.albedo;\n    vec3 param_7 = param_3.normal;\n    fa_apply_decals(param_4, param_5, param_6, param_7);\n    _5788 = param_6;\n    _5790 = param_7;\n    vec3 result;\n    if (fa_mesh_fs_params[3].w > 0.5)\n    {\n        result = _5788;\n    }\n    else\n    {\n        vec3 _5474 = _5790;\n        vec3 _5475 = normalize(_5474);\n        _5790 = _5475;\n        SurfaceInput param_8 = SurfaceInput(fa_world_pos, _5757, fa_world_tangent, fa_uv, fa_vertex_color, _5427, gl_FrontFacing);\n        Surface param_9 = Surface(_5788, _5789, _5475, _5791, _5792, _5793, _5794, _5795, _5796, _5797, _5798, _5799, _5800, _5801, _5802, _5803, _5804, _5805, _5806, _5807);\n        vec3 _5486 = lighting(param_8, param_9);\n        result = _5486;\n    }\n    vec3 _5490 = result;\n    vec3 _5491 = _5490 + _5794;\n    result = _5491;\n    vec3 param_10 = _5491;\n    vec3 param_11 = fa_world_pos;\n    result = fa_shadow_debug(param_10, param_11);\n    bool _5500 = fa_mesh_fs_params[7].w > 0.0;\n    bool _5507;\n    if (!_5500)\n    {\n        _5507 = fa_mesh_fs_params[8].y > 0.0;\n    }\n    else\n    {\n        _5507 = _5500;\n    }\n    if (_5507)\n    {\n        vec3 _5516 = fa_world_pos - fa_mesh_fs_params[0].xyz;\n        float _5522 = dot(_5516, fa_mesh_fs_params[9].xyz);\n        bool _5526 = fa_mesh_fs_params[9].w > 0.5;\n        float _5527;\n        if (_5526)\n        {\n            _5527 = _5522;\n        }\n        else\n        {\n            _5527 = length(_5516);\n        }\n        float _5539 = _5527 - fa_mesh_fs_params[8].x;\n        if (_5539 > 0.0)\n        {\n            float _5548 = fa_mesh_fs_params[7].w * _5539;\n            float tau = _5548 * _5548;\n            if (fa_mesh_fs_params[8].y > 0.0)\n            {\n                float _5564;\n                if (_5526)\n                {\n                    _5564 = fa_world_pos.y - (fa_mesh_fs_params[9].y * _5522);\n                }\n                else\n                {\n                    _5564 = fa_mesh_fs_params[0].y;\n                }\n                float _5585 = mix(_5564, fa_world_pos.y, clamp(fa_mesh_fs_params[8].x / _5527, 0.0, 1.0));\n                float _5589 = fa_world_pos.y - _5585;\n                float _5594 = _5585 - fa_mesh_fs_params[8].z;\n                float _5599 = fa_world_pos.y - fa_mesh_fs_params[8].z;\n                bool _5602 = _5594 <= 0.0;\n                bool _5603 = !_5602;\n                bool _5609;\n                if (_5603)\n                {\n                    _5609 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _5609 = _5602;\n                }\n                float _5610;\n                if (_5609)\n                {\n                    _5610 = fa_mesh_fs_params[8].y;\n                }\n                else\n                {\n                    _5610 = fa_mesh_fs_params[8].y * exp(-min(fa_mesh_fs_params[8].w * _5594, 80.0));\n                }\n                bool _5637;\n                if (_5603)\n                {\n                    _5637 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _5637 = _5602;\n                }\n                float _5638;\n                if (_5637)\n                {\n                    _5638 = fa_mesh_fs_params[8].y * _5594;\n                }\n                else\n                {\n                    _5638 = (fa_mesh_fs_params[8].y * (1.0 - exp(-min(fa_mesh_fs_params[8].w * _5594, 80.0)))) / fa_mesh_fs_params[8].w;\n                }\n                bool _5663 = _5599 <= 0.0;\n                bool _5670;\n                if (!_5663)\n                {\n                    _5670 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _5670 = _5663;\n                }\n                float _5671;\n                if (_5670)\n                {\n                    _5671 = fa_mesh_fs_params[8].y * _5599;\n                }\n                else\n                {\n                    _5671 = (fa_mesh_fs_params[8].y * (1.0 - exp(-min(fa_mesh_fs_params[8].w * _5599, 80.0)))) / fa_mesh_fs_params[8].w;\n                }\n                float _5698;\n                if (abs(_5589) < 0.001000000047497451305389404296875)\n                {\n                    _5698 = _5610;\n                }\n                else\n                {\n                    _5698 = (_5671 - _5638) / _5589;\n                }\n                tau += (_5539 * max(_5698, 0.0));\n            }\n            result = mix(result, fa_mesh_fs_params[7].xyz, vec3(clamp(1.0 - exp(-clamp(tau, 0.0, 80.0)), 0.0, 1.0)));\n        }\n    }\n    fa_frag_color = vec4(result, _5789);\n}\n\n",
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
            "inst_name": "_143",
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
            "inst_name": "_191",
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
            "inst_name": "_468",
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
            "inst_name": "_2121",
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
            "inst_name": "_5040",
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
      "vs": "#version 430\n\nstruct VertexData\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 color;\n    vec3 object_pos;\n};\n\nuniform vec4 fa_mesh_vs_params[11];\nuniform vec4 fa_vel_params[9];\nlayout(location = 0) out vec3 fa_world_pos;\nlayout(location = 1) out vec3 fa_world_normal;\nlayout(location = 2) out vec4 fa_world_tangent;\nlayout(location = 3) out vec2 fa_uv;\nlayout(location = 4) out vec4 fa_vertex_color;\nlayout(location = 5) out float fa_pre_depth;\nlayout(location = 6) out vec3 fa_pre_r0;\nlayout(location = 7) out vec3 fa_pre_r1;\nlayout(location = 8) out vec3 fa_pre_r2;\nlayout(location = 9) out vec3 fa_vel_cur;\nlayout(location = 10) out vec3 fa_vel_prev;\nlayout(location = 5) in vec4 fa_inst_m0;\nlayout(location = 6) in vec4 fa_inst_m1;\nlayout(location = 7) in vec4 fa_inst_m2;\nlayout(location = 8) in vec4 fa_inst_m3;\nlayout(location = 9) in vec4 fa_prev_r0;\nlayout(location = 10) in vec4 fa_prev_r1;\nlayout(location = 11) in vec4 fa_prev_r2;\nlayout(location = 0) in vec3 fa_position;\nlayout(location = 1) in vec3 fa_normal;\nlayout(location = 3) in vec4 fa_tangent;\nlayout(location = 2) in vec2 fa_texcoord0;\nlayout(location = 4) in vec4 fa_color;\nvec4 fa_vtime;\n\nvoid fa_inst_begin()\n{\n}\n\nmat4 fa_rows_to_mat4(vec4 r0, vec4 r1, vec4 r2)\n{\n    return mat4(vec4(r0.x, r1.x, r2.x, 0.0), vec4(r0.y, r1.y, r2.y, 0.0), vec4(r0.z, r1.z, r2.z, 0.0), vec4(r0.w, r1.w, r2.w, 1.0));\n}\n\nvec4 fa_time_now()\n{\n    return fa_mesh_vs_params[9];\n}\n\nVertexData fa_vertex_data(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    vec3 _95 = cross(model[1].xyz, model[2].xyz);\n    float _99 = (dot(model[0].xyz, _95) < 0.0) ? (-1.0) : 1.0;\n    return VertexData((model * vec4(position, 1.0)).xyz, (((_95 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _99, vec4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _99), texcoord0 * fa_mesh_vs_params[8].xy, color, position);\n}\n\nvoid fa_prepass_vertex(mat4 model, mat4 prev_model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color, bool has_prev)\n{\n    bool _229;\n    if (has_prev)\n    {\n        _229 = fa_vel_params[8].x > 0.5;\n    }\n    else\n    {\n        _229 = has_prev;\n    }\n    fa_vtime = fa_time_now();\n    mat4 param = model;\n    vec3 param_1 = position;\n    vec3 param_2 = normal;\n    vec4 param_3 = tangent;\n    vec2 param_4 = texcoord0;\n    vec4 param_5 = color;\n    VertexData _244 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    vec3 _453 = _244.world_pos;\n    mat4 _248 = mat4(fa_mesh_vs_params[4], fa_mesh_vs_params[5], fa_mesh_vs_params[6], fa_mesh_vs_params[7]);\n    vec4 _255 = vec4(_453, 1.0);\n    fa_world_pos = _453;\n    fa_world_normal = _244.world_normal;\n    fa_world_tangent = _244.world_tangent;\n    fa_uv = _244.uv;\n    fa_vertex_color = _244.color;\n    fa_pre_depth = -(_248 * _255).z;\n    fa_pre_r0 = vec3(_248[0].x, _248[1].x, _248[2].x);\n    fa_pre_r1 = vec3(_248[0].y, _248[1].y, _248[2].y);\n    fa_pre_r2 = vec3(_248[0].z, _248[1].z, _248[2].z);\n    gl_Position = mat4(fa_mesh_vs_params[0], fa_mesh_vs_params[1], fa_mesh_vs_params[2], fa_mesh_vs_params[3]) * _255;\n    fa_vel_cur = vec3(0.0, 0.0, 1.0);\n    fa_vel_prev = vec3(0.0);\n    if (_229)\n    {\n        vec4 _326 = vec4(position, 1.0);\n        fa_vel_cur = vec3((mat4(fa_vel_params[0], fa_vel_params[1], fa_vel_params[2], fa_vel_params[3]) * _255).xyw);\n        fa_vel_prev = vec3((mat4(fa_vel_params[4], fa_vel_params[5], fa_vel_params[6], fa_vel_params[7]) * vec4((_453 + (prev_model * _326).xyz) - (model * _326).xyz, 1.0)).xyw);\n    }\n}\n\nvoid main()\n{\n    fa_vtime = vec4(0.0);\n    fa_inst_begin();\n    vec4 param = fa_prev_r0;\n    vec4 param_1 = fa_prev_r1;\n    vec4 param_2 = fa_prev_r2;\n    mat4 param_3 = mat4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3);\n    mat4 param_4 = fa_rows_to_mat4(param, param_1, param_2);\n    vec3 param_5 = fa_position;\n    vec3 param_6 = fa_normal;\n    vec4 param_7 = fa_tangent;\n    vec2 param_8 = fa_texcoord0;\n    vec4 param_9 = fa_color;\n    bool param_10 = true;\n    fa_prepass_vertex(param_3, param_4, param_5, param_6, param_7, param_8, param_9, param_10);\n}\n\n",
      "fs": "#version 430\n\nstruct SurfaceInput\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 vertex_color;\n    vec3 view_dir;\n    bool front_facing;\n};\n\nstruct Surface\n{\n    vec3 albedo;\n    float alpha;\n    vec3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    vec3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    vec3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    vec3 specular_color;\n    float transmission;\n    float thickness;\n    vec3 attenuation_color;\n    float attenuation_distance;\n};\n\nuniform vec4 fa_mesh_fs_params[53];\nlayout(binding = 0) uniform sampler2D fa_tex_fa_smp;\nlayout(binding = 1) uniform sampler2D fa_normal_tex_fa_smp;\nlayout(binding = 2) uniform sampler2D fa_mr_tex_fa_smp;\nlayout(binding = 3) uniform sampler2D fa_occlusion_tex_fa_smp;\nlayout(binding = 4) uniform sampler2D fa_emissive_tex_fa_smp;\n\nlayout(location = 0) in vec3 fa_world_pos;\nlayout(location = 1) in vec3 fa_world_normal;\nlayout(location = 2) in vec4 fa_world_tangent;\nlayout(location = 3) in vec2 fa_uv;\nlayout(location = 4) in vec4 fa_vertex_color;\nlayout(location = 6) in vec3 fa_pre_r0;\nlayout(location = 7) in vec3 fa_pre_r1;\nlayout(location = 8) in vec3 fa_pre_r2;\nlayout(location = 0) out vec4 fa_frag_color;\nlayout(location = 5) in float fa_pre_depth;\nlayout(location = 9) in vec3 fa_vel_cur;\nlayout(location = 10) in vec3 fa_vel_prev;\nlayout(location = 1) out vec2 fa_frag_velocity;\n\nvoid fa_inst_load()\n{\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nvec3 fa_linear_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_tex_fix(inout vec3 c, float mode)\n{\n    if (mode > 1.5)\n    {\n        vec3 param = c;\n        vec3 _172 = fa_linear_to_srgb(param);\n        c = _172;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            vec3 param_1 = c;\n            vec3 _181 = fa_srgb_to_linear(param_1);\n            c = _181;\n        }\n    }\n    return c;\n}\n\nvec3 fa_tangent_normal(SurfaceInput i, vec3 m)\n{\n    vec3 _56;\n    if (i.front_facing)\n    {\n        _56 = i.world_normal;\n    }\n    else\n    {\n        _56 = -i.world_normal;\n    }\n    vec3 _81 = normalize(i.world_tangent.xyz - (_56 * dot(_56, i.world_tangent.xyz)));\n    vec3 _109 = normalize(((_81 * m.x) + ((cross(_56, _81) * i.world_tangent.w) * m.y)) + (_56 * m.z));\n    vec3 _112;\n    if (i.front_facing)\n    {\n        _112 = _109;\n    }\n    else\n    {\n        _112 = -_109;\n    }\n    return _112;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    vec4 base_t = texture(fa_tex_fa_smp, i.uv);\n    float param = fa_mesh_fs_params[6].w;\n    float param_1 = 1.0;\n    vec3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    vec3 _227 = fa_tex_fix(param_2, param_3);\n    vec4 _882 = base_t;\n    _882.x = _227.x;\n    _882.y = _227.y;\n    _882.z = _227.z;\n    base_t = _882;\n    vec4 _243 = (_882 * fa_mesh_fs_params[2]) * i.vertex_color;\n    vec3 _837 = i.world_normal;\n    if (fa_mesh_fs_params[6].z > 0.5)\n    {\n        float param_4 = fa_mesh_fs_params[6].w;\n        float param_5 = 16.0;\n        vec3 param_6 = texture(fa_normal_tex_fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        vec3 _277 = fa_tex_fix(param_6, param_7);\n        vec3 _281 = (_277 * 2.0) - vec3(1.0);\n        vec2 _286 = _281.xy * fa_mesh_fs_params[6].x;\n        vec3 _890 = _281;\n        _890.x = _286.x;\n        _890.y = _286.y;\n        SurfaceInput param_8 = i;\n        vec3 param_9 = _890;\n        _837 = fa_tangent_normal(param_8, param_9);\n    }\n    vec4 mrt = texture(fa_mr_tex_fa_smp, i.uv);\n    float param_10 = fa_mesh_fs_params[6].w;\n    float param_11 = 64.0;\n    vec3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    vec3 _315 = fa_tex_fix(param_12, param_13);\n    vec4 _893 = mrt;\n    _893.x = _315.x;\n    _893.y = _315.y;\n    _893.z = _315.z;\n    mrt = _893;\n    vec4 _345 = texture(fa_occlusion_tex_fa_smp, i.uv);\n    float param_14 = fa_mesh_fs_params[6].w;\n    float param_15 = 256.0;\n    vec3 param_16 = _345.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    vec3 _357 = fa_tex_fix(param_16, param_17);\n    float param_18 = fa_mesh_fs_params[6].w;\n    float param_19 = 4.0;\n    vec3 param_20 = texture(fa_emissive_tex_fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    vec3 _387 = fa_tex_fix(param_20, param_21);\n    float _842 = fa_mesh_fs_params[20].x;\n    float _843 = fa_mesh_fs_params[20].y;\n    float _846 = fa_mesh_fs_params[20].z;\n    float _845 = fa_mesh_fs_params[21].w;\n    float _848 = fa_mesh_fs_params[22].x;\n    if (fa_mesh_fs_params[22].z > 0.5)\n    {\n        if (mod(fa_mesh_fs_params[22].z, 2.0) > 0.5)\n        {\n            _842 *= _357.y;\n            _843 *= _357.z;\n            _845 *= _345.w;\n        }\n        if (fa_mesh_fs_params[22].z > 1.5)\n        {\n            _846 *= mrt.x;\n            _848 *= mrt.w;\n        }\n    }\n    return Surface(_243.xyz, _243.w, _837, clamp(fa_mesh_fs_params[5].x * _315.z, 0.0, 1.0), clamp(fa_mesh_fs_params[5].y * _315.y, 0.0500000007450580596923828125, 1.0), 1.0 + (fa_mesh_fs_params[6].y * (_357.x - 1.0)), fa_mesh_fs_params[3].xyz + (fa_mesh_fs_params[4].xyz * _387), _842, _843, fa_mesh_fs_params[21].xyz, _845, _846, fa_mesh_fs_params[20].w, _848, fa_mesh_fs_params[22].y, fa_mesh_fs_params[23].xyz, fa_mesh_fs_params[30].x, fa_mesh_fs_params[30].y, fa_mesh_fs_params[31].xyz, fa_mesh_fs_params[30].z);\n}\n\nvoid surface(SurfaceInput i, Surface s)\n{\n}\n\nvoid main()\n{\n    fa_inst_load();\n    vec3 _732 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _732 = -_732;\n    }\n    vec3 _540 = normalize(fa_mesh_fs_params[0].xyz - fa_world_pos);\n    SurfaceInput param = SurfaceInput(fa_world_pos, _732, fa_world_tangent, fa_uv, fa_vertex_color, _540, gl_FrontFacing);\n    SurfaceInput param_1 = SurfaceInput(fa_world_pos, _732, fa_world_tangent, fa_uv, fa_vertex_color, _540, gl_FrontFacing);\n    Surface param_2 = fa_standard_surface(param);\n    surface(param_1, param_2);\n    vec3 _555 = normalize(param_2.normal);\n    vec3 _570 = normalize(vec3(dot(fa_pre_r0, _555), dot(fa_pre_r1, _555), dot(fa_pre_r2, _555)));\n    float _582 = _570.z;\n    vec2 e = _570.xy / vec2((abs(_570.x) + abs(_570.y)) + abs(_582));\n    if (_582 < 0.0)\n    {\n        e = (vec2(1.0) - abs(e.yx)) * vec2((e.x >= 0.0) ? 1.0 : (-1.0), (e.y >= 0.0) ? 1.0 : (-1.0));\n    }\n    fa_frag_color = vec4(min(fa_pre_depth, 60000.0), e, 1.0);\n    vec2 motion = vec2(1024.0);\n    bool _626 = fa_vel_cur.z > 9.9999997473787516355514526367188e-06;\n    bool _633;\n    if (_626)\n    {\n        _633 = fa_vel_prev.z > 9.9999997473787516355514526367188e-06;\n    }\n    else\n    {\n        _633 = _626;\n    }\n    if (_633)\n    {\n        motion = clamp(((vec2(fa_vel_prev.x, -fa_vel_prev.y) / vec2(fa_vel_prev.z)) * 0.5) - ((vec2(fa_vel_cur.x, -fa_vel_cur.y) / vec2(fa_vel_cur.z)) * 0.5), vec2(-4.0), vec2(4.0));\n    }\n    fa_frag_velocity = motion;\n}\n\n",
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
            "inst_name": "_55",
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
            "inst_name": "_223",
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
      "vs": "#version 430\n\nstruct VertexData\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 color;\n    vec3 object_pos;\n};\n\nuniform vec4 fa_mesh_vs_params[11];\nuniform vec4 fa_skin[192];\nuniform vec4 fa_vel_params[9];\nlayout(location = 0) out vec3 fa_world_pos;\nlayout(location = 1) out vec3 fa_world_normal;\nlayout(location = 2) out vec4 fa_world_tangent;\nlayout(location = 3) out vec2 fa_uv;\nlayout(location = 4) out vec4 fa_vertex_color;\nlayout(location = 5) out float fa_pre_depth;\nlayout(location = 6) out vec3 fa_pre_r0;\nlayout(location = 7) out vec3 fa_pre_r1;\nlayout(location = 8) out vec3 fa_pre_r2;\nlayout(location = 9) out vec3 fa_vel_cur;\nlayout(location = 10) out vec3 fa_vel_prev;\nlayout(location = 5) in vec4 fa_inst_m0;\nlayout(location = 6) in vec4 fa_inst_m1;\nlayout(location = 7) in vec4 fa_inst_m2;\nlayout(location = 8) in vec4 fa_inst_m3;\nlayout(location = 9) in vec4 fa_joints;\nlayout(location = 10) in vec4 fa_weights;\nlayout(location = 11) in vec4 fa_prev_r0;\nlayout(location = 12) in vec4 fa_prev_r1;\nlayout(location = 13) in vec4 fa_prev_r2;\nlayout(location = 0) in vec3 fa_position;\nlayout(location = 1) in vec3 fa_normal;\nlayout(location = 3) in vec4 fa_tangent;\nlayout(location = 2) in vec2 fa_texcoord0;\nlayout(location = 4) in vec4 fa_color;\nvec4 fa_vtime;\n\nvoid fa_inst_begin()\n{\n}\n\nmat4 fa_skin_matrix_at(vec4 joints, vec4 weights, int base)\n{\n    vec4 r0 = vec4(0.0);\n    vec4 r1 = vec4(0.0);\n    vec4 r2 = vec4(0.0);\n    for (int i = 0; i < 4; i++)\n    {\n        int _200 = base + (int((joints[i] * 255.0) + 0.5) * 3);\n        r0 += (fa_skin[_200 * 1 + 0] * weights[i]);\n        r1 += (fa_skin[(_200 + 1) * 1 + 0] * weights[i]);\n        r2 += (fa_skin[(_200 + 2) * 1 + 0] * weights[i]);\n    }\n    return mat4(vec4(r0.x, r1.x, r2.x, 0.0), vec4(r0.y, r1.y, r2.y, 0.0), vec4(r0.z, r1.z, r2.z, 0.0), vec4(r0.w, r1.w, r2.w, 1.0));\n}\n\nmat4 fa_skin_matrix(vec4 joints, vec4 weights)\n{\n    vec4 param = joints;\n    vec4 param_1 = weights;\n    int param_2 = 0;\n    return fa_skin_matrix_at(param, param_1, param_2);\n}\n\nmat4 fa_rows_to_mat4(vec4 r0, vec4 r1, vec4 r2)\n{\n    return mat4(vec4(r0.x, r1.x, r2.x, 0.0), vec4(r0.y, r1.y, r2.y, 0.0), vec4(r0.z, r1.z, r2.z, 0.0), vec4(r0.w, r1.w, r2.w, 1.0));\n}\n\nvec4 fa_time_now()\n{\n    return fa_mesh_vs_params[9];\n}\n\nVertexData fa_vertex_data(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    vec3 _107 = cross(model[1].xyz, model[2].xyz);\n    float _111 = (dot(model[0].xyz, _107) < 0.0) ? (-1.0) : 1.0;\n    return VertexData((model * vec4(position, 1.0)).xyz, (((_107 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _111, vec4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _111), texcoord0 * fa_mesh_vs_params[8].xy, color, position);\n}\n\nvoid fa_prepass_vertex(mat4 model, mat4 prev_model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color, bool has_prev)\n{\n    bool _356;\n    if (has_prev)\n    {\n        _356 = fa_vel_params[8].x > 0.5;\n    }\n    else\n    {\n        _356 = has_prev;\n    }\n    fa_vtime = fa_time_now();\n    mat4 param = model;\n    vec3 param_1 = position;\n    vec3 param_2 = normal;\n    vec4 param_3 = tangent;\n    vec2 param_4 = texcoord0;\n    vec4 param_5 = color;\n    VertexData _371 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    vec3 _598 = _371.world_pos;\n    mat4 _375 = mat4(fa_mesh_vs_params[4], fa_mesh_vs_params[5], fa_mesh_vs_params[6], fa_mesh_vs_params[7]);\n    vec4 _382 = vec4(_598, 1.0);\n    fa_world_pos = _598;\n    fa_world_normal = _371.world_normal;\n    fa_world_tangent = _371.world_tangent;\n    fa_uv = _371.uv;\n    fa_vertex_color = _371.color;\n    fa_pre_depth = -(_375 * _382).z;\n    fa_pre_r0 = vec3(_375[0].x, _375[1].x, _375[2].x);\n    fa_pre_r1 = vec3(_375[0].y, _375[1].y, _375[2].y);\n    fa_pre_r2 = vec3(_375[0].z, _375[1].z, _375[2].z);\n    gl_Position = mat4(fa_mesh_vs_params[0], fa_mesh_vs_params[1], fa_mesh_vs_params[2], fa_mesh_vs_params[3]) * _382;\n    fa_vel_cur = vec3(0.0, 0.0, 1.0);\n    fa_vel_prev = vec3(0.0);\n    if (_356)\n    {\n        vec4 _453 = vec4(position, 1.0);\n        fa_vel_cur = vec3((mat4(fa_vel_params[0], fa_vel_params[1], fa_vel_params[2], fa_vel_params[3]) * _382).xyw);\n        fa_vel_prev = vec3((mat4(fa_vel_params[4], fa_vel_params[5], fa_vel_params[6], fa_vel_params[7]) * vec4((_598 + (prev_model * _453).xyz) - (model * _453).xyz, 1.0)).xyw);\n    }\n}\n\nvoid main()\n{\n    fa_vtime = vec4(0.0);\n    fa_inst_begin();\n    vec4 param = fa_joints;\n    vec4 param_1 = fa_weights;\n    vec4 param_2 = fa_prev_r0;\n    vec4 param_3 = fa_prev_r1;\n    vec4 param_4 = fa_prev_r2;\n    vec4 param_5 = fa_joints;\n    vec4 param_6 = fa_weights;\n    int param_7 = 96;\n    mat4 param_8 = mat4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3) * fa_skin_matrix(param, param_1);\n    mat4 param_9 = fa_rows_to_mat4(param_2, param_3, param_4) * fa_skin_matrix_at(param_5, param_6, param_7);\n    vec3 param_10 = fa_position;\n    vec3 param_11 = fa_normal;\n    vec4 param_12 = fa_tangent;\n    vec2 param_13 = fa_texcoord0;\n    vec4 param_14 = fa_color;\n    bool param_15 = fa_vel_params[8].z > 0.5;\n    fa_prepass_vertex(param_8, param_9, param_10, param_11, param_12, param_13, param_14, param_15);\n}\n\n",
      "fs": "#version 430\n\nstruct SurfaceInput\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 vertex_color;\n    vec3 view_dir;\n    bool front_facing;\n};\n\nstruct Surface\n{\n    vec3 albedo;\n    float alpha;\n    vec3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    vec3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    vec3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    vec3 specular_color;\n    float transmission;\n    float thickness;\n    vec3 attenuation_color;\n    float attenuation_distance;\n};\n\nuniform vec4 fa_mesh_fs_params[53];\nlayout(binding = 0) uniform sampler2D fa_tex_fa_smp;\nlayout(binding = 1) uniform sampler2D fa_normal_tex_fa_smp;\nlayout(binding = 2) uniform sampler2D fa_mr_tex_fa_smp;\nlayout(binding = 3) uniform sampler2D fa_occlusion_tex_fa_smp;\nlayout(binding = 4) uniform sampler2D fa_emissive_tex_fa_smp;\n\nlayout(location = 0) in vec3 fa_world_pos;\nlayout(location = 1) in vec3 fa_world_normal;\nlayout(location = 2) in vec4 fa_world_tangent;\nlayout(location = 3) in vec2 fa_uv;\nlayout(location = 4) in vec4 fa_vertex_color;\nlayout(location = 6) in vec3 fa_pre_r0;\nlayout(location = 7) in vec3 fa_pre_r1;\nlayout(location = 8) in vec3 fa_pre_r2;\nlayout(location = 0) out vec4 fa_frag_color;\nlayout(location = 5) in float fa_pre_depth;\nlayout(location = 9) in vec3 fa_vel_cur;\nlayout(location = 10) in vec3 fa_vel_prev;\nlayout(location = 1) out vec2 fa_frag_velocity;\n\nvoid fa_inst_load()\n{\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nvec3 fa_linear_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_tex_fix(inout vec3 c, float mode)\n{\n    if (mode > 1.5)\n    {\n        vec3 param = c;\n        vec3 _172 = fa_linear_to_srgb(param);\n        c = _172;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            vec3 param_1 = c;\n            vec3 _181 = fa_srgb_to_linear(param_1);\n            c = _181;\n        }\n    }\n    return c;\n}\n\nvec3 fa_tangent_normal(SurfaceInput i, vec3 m)\n{\n    vec3 _56;\n    if (i.front_facing)\n    {\n        _56 = i.world_normal;\n    }\n    else\n    {\n        _56 = -i.world_normal;\n    }\n    vec3 _81 = normalize(i.world_tangent.xyz - (_56 * dot(_56, i.world_tangent.xyz)));\n    vec3 _109 = normalize(((_81 * m.x) + ((cross(_56, _81) * i.world_tangent.w) * m.y)) + (_56 * m.z));\n    vec3 _112;\n    if (i.front_facing)\n    {\n        _112 = _109;\n    }\n    else\n    {\n        _112 = -_109;\n    }\n    return _112;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    vec4 base_t = texture(fa_tex_fa_smp, i.uv);\n    float param = fa_mesh_fs_params[6].w;\n    float param_1 = 1.0;\n    vec3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    vec3 _227 = fa_tex_fix(param_2, param_3);\n    vec4 _882 = base_t;\n    _882.x = _227.x;\n    _882.y = _227.y;\n    _882.z = _227.z;\n    base_t = _882;\n    vec4 _243 = (_882 * fa_mesh_fs_params[2]) * i.vertex_color;\n    vec3 _837 = i.world_normal;\n    if (fa_mesh_fs_params[6].z > 0.5)\n    {\n        float param_4 = fa_mesh_fs_params[6].w;\n        float param_5 = 16.0;\n        vec3 param_6 = texture(fa_normal_tex_fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        vec3 _277 = fa_tex_fix(param_6, param_7);\n        vec3 _281 = (_277 * 2.0) - vec3(1.0);\n        vec2 _286 = _281.xy * fa_mesh_fs_params[6].x;\n        vec3 _890 = _281;\n        _890.x = _286.x;\n        _890.y = _286.y;\n        SurfaceInput param_8 = i;\n        vec3 param_9 = _890;\n        _837 = fa_tangent_normal(param_8, param_9);\n    }\n    vec4 mrt = texture(fa_mr_tex_fa_smp, i.uv);\n    float param_10 = fa_mesh_fs_params[6].w;\n    float param_11 = 64.0;\n    vec3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    vec3 _315 = fa_tex_fix(param_12, param_13);\n    vec4 _893 = mrt;\n    _893.x = _315.x;\n    _893.y = _315.y;\n    _893.z = _315.z;\n    mrt = _893;\n    vec4 _345 = texture(fa_occlusion_tex_fa_smp, i.uv);\n    float param_14 = fa_mesh_fs_params[6].w;\n    float param_15 = 256.0;\n    vec3 param_16 = _345.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    vec3 _357 = fa_tex_fix(param_16, param_17);\n    float param_18 = fa_mesh_fs_params[6].w;\n    float param_19 = 4.0;\n    vec3 param_20 = texture(fa_emissive_tex_fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    vec3 _387 = fa_tex_fix(param_20, param_21);\n    float _842 = fa_mesh_fs_params[20].x;\n    float _843 = fa_mesh_fs_params[20].y;\n    float _846 = fa_mesh_fs_params[20].z;\n    float _845 = fa_mesh_fs_params[21].w;\n    float _848 = fa_mesh_fs_params[22].x;\n    if (fa_mesh_fs_params[22].z > 0.5)\n    {\n        if (mod(fa_mesh_fs_params[22].z, 2.0) > 0.5)\n        {\n            _842 *= _357.y;\n            _843 *= _357.z;\n            _845 *= _345.w;\n        }\n        if (fa_mesh_fs_params[22].z > 1.5)\n        {\n            _846 *= mrt.x;\n            _848 *= mrt.w;\n        }\n    }\n    return Surface(_243.xyz, _243.w, _837, clamp(fa_mesh_fs_params[5].x * _315.z, 0.0, 1.0), clamp(fa_mesh_fs_params[5].y * _315.y, 0.0500000007450580596923828125, 1.0), 1.0 + (fa_mesh_fs_params[6].y * (_357.x - 1.0)), fa_mesh_fs_params[3].xyz + (fa_mesh_fs_params[4].xyz * _387), _842, _843, fa_mesh_fs_params[21].xyz, _845, _846, fa_mesh_fs_params[20].w, _848, fa_mesh_fs_params[22].y, fa_mesh_fs_params[23].xyz, fa_mesh_fs_params[30].x, fa_mesh_fs_params[30].y, fa_mesh_fs_params[31].xyz, fa_mesh_fs_params[30].z);\n}\n\nvoid surface(SurfaceInput i, Surface s)\n{\n}\n\nvoid main()\n{\n    fa_inst_load();\n    vec3 _732 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _732 = -_732;\n    }\n    vec3 _540 = normalize(fa_mesh_fs_params[0].xyz - fa_world_pos);\n    SurfaceInput param = SurfaceInput(fa_world_pos, _732, fa_world_tangent, fa_uv, fa_vertex_color, _540, gl_FrontFacing);\n    SurfaceInput param_1 = SurfaceInput(fa_world_pos, _732, fa_world_tangent, fa_uv, fa_vertex_color, _540, gl_FrontFacing);\n    Surface param_2 = fa_standard_surface(param);\n    surface(param_1, param_2);\n    vec3 _555 = normalize(param_2.normal);\n    vec3 _570 = normalize(vec3(dot(fa_pre_r0, _555), dot(fa_pre_r1, _555), dot(fa_pre_r2, _555)));\n    float _582 = _570.z;\n    vec2 e = _570.xy / vec2((abs(_570.x) + abs(_570.y)) + abs(_582));\n    if (_582 < 0.0)\n    {\n        e = (vec2(1.0) - abs(e.yx)) * vec2((e.x >= 0.0) ? 1.0 : (-1.0), (e.y >= 0.0) ? 1.0 : (-1.0));\n    }\n    fa_frag_color = vec4(min(fa_pre_depth, 60000.0), e, 1.0);\n    vec2 motion = vec2(1024.0);\n    bool _626 = fa_vel_cur.z > 9.9999997473787516355514526367188e-06;\n    bool _633;\n    if (_626)\n    {\n        _633 = fa_vel_prev.z > 9.9999997473787516355514526367188e-06;\n    }\n    else\n    {\n        _633 = _626;\n    }\n    if (_633)\n    {\n        motion = clamp(((vec2(fa_vel_prev.x, -fa_vel_prev.y) / vec2(fa_vel_prev.z)) * 0.5) - ((vec2(fa_vel_cur.x, -fa_vel_cur.y) / vec2(fa_vel_cur.z)) * 0.5), vec2(-4.0), vec2(4.0));\n    }\n    fa_frag_velocity = motion;\n}\n\n",
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
            "inst_name": "_68",
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
            "inst_name": "_209",
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
            "inst_name": "_351",
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
