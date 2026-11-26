{
  "format": "factoria.shader/1",
  "engine": "0.38.0",
  "template": "7dfc96845a84a2e1eeb941c4a325b3e44f1dd63d04807d1dd0da2d9b2c3c7186",
  "slang": "glsl430",
  "params": [
    "dark",
    "skyAmount"
  ],
  "textures": [],
  "programs": {
    "mesh": {
      "vs": "#version 430\n\nstruct VertexData\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 color;\n    vec3 object_pos;\n};\n\nuniform vec4 fa_mesh_vs_params[11];\nlayout(location = 0) out vec3 fa_world_pos;\nlayout(location = 1) out vec3 fa_world_normal;\nlayout(location = 2) out vec4 fa_world_tangent;\nlayout(location = 3) out vec2 fa_uv;\nlayout(location = 4) out vec4 fa_vertex_color;\nlayout(location = 5) in vec4 fa_inst_m0;\nlayout(location = 6) in vec4 fa_inst_m1;\nlayout(location = 7) in vec4 fa_inst_m2;\nlayout(location = 8) in vec4 fa_inst_m3;\nlayout(location = 0) in vec3 fa_position;\nlayout(location = 1) in vec3 fa_normal;\nlayout(location = 3) in vec4 fa_tangent;\nlayout(location = 2) in vec2 fa_texcoord0;\nlayout(location = 4) in vec4 fa_color;\nlayout(location = 5) out vec3 fa_lm;\n\nvoid fa_inst_begin()\n{\n}\n\nVertexData fa_vertex_data(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    vec3 _69 = cross(model[1].xyz, model[2].xyz);\n    float _75 = (dot(model[0].xyz, _69) < 0.0) ? (-1.0) : 1.0;\n    return VertexData((model * vec4(position, 1.0)).xyz, (((_69 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _75, vec4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _75), texcoord0 * fa_mesh_vs_params[8].xy, color, position);\n}\n\nvoid fa_shade_vertex(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    mat4 param = model;\n    vec3 param_1 = position;\n    vec3 param_2 = normal;\n    vec4 param_3 = tangent;\n    vec2 param_4 = texcoord0;\n    vec4 param_5 = color;\n    VertexData _160 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    vec3 _270 = _160.world_pos;\n    fa_world_pos = _270;\n    fa_world_normal = _160.world_normal;\n    fa_world_tangent = _160.world_tangent;\n    fa_uv = _160.uv;\n    fa_vertex_color = _160.color;\n    gl_Position = mat4(fa_mesh_vs_params[0], fa_mesh_vs_params[1], fa_mesh_vs_params[2], fa_mesh_vs_params[3]) * vec4(_270, 1.0);\n}\n\nvoid main()\n{\n    fa_inst_begin();\n    mat4 param = mat4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3);\n    vec3 param_1 = fa_position;\n    vec3 param_2 = fa_normal;\n    vec4 param_3 = fa_tangent;\n    vec2 param_4 = fa_texcoord0;\n    vec4 param_5 = fa_color;\n    fa_shade_vertex(param, param_1, param_2, param_3, param_4, param_5);\n    fa_lm = vec3(0.0);\n}\n\n",
      "fs": "#version 430\n\nstruct SurfaceInput\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 vertex_color;\n    vec3 view_dir;\n    bool front_facing;\n};\n\nstruct LightSample\n{\n    vec3 direction;\n    vec3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct Surface\n{\n    vec3 albedo;\n    float alpha;\n    vec3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    vec3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    vec3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    vec3 specular_color;\n    float transmission;\n    float thickness;\n    vec3 attenuation_color;\n    float attenuation_distance;\n};\n\nstruct FaLayers\n{\n    bool on;\n    float f90;\n    float keep;\n    float base_scale;\n    float coat;\n    float coat_rough;\n    float coat_alpha;\n    float coat_a2;\n    vec3 nc;\n    float coat_ndv;\n    bool sheen_on;\n    vec3 sheen;\n    float sheen_rough;\n    float sheen_alpha;\n    float sheen_scale;\n    float sheen_e;\n    float aniso;\n    vec3 t;\n    vec3 b;\n    float at;\n    float ab;\n};\n\nconst float _4033[63] = float[](1.0, 1.0, 1.0, 0.4790000021457672119140625, 0.11699999868869781494140625, 0.01200000010430812835693359375, 0.0, 0.0, 0.0, 1.0, 1.0, 1.0, 0.578000009059906005859375, 0.19300000369548797607421875, 0.0350000001490116119384765625, 0.0030000000260770320892333984375, 0.0, 0.0, 1.0, 1.0, 1.0, 0.6740000247955322265625, 0.3459999859333038330078125, 0.1319999992847442626953125, 0.032999999821186065673828125, 0.0040000001899898052215576171875, 0.0, 0.971000015735626220703125, 0.954999983310699462890625, 0.828999996185302734375, 0.63999998569488525390625, 0.42599999904632568359375, 0.24500000476837158203125, 0.115000002086162567138671875, 0.037000000476837158203125, 0.0030000000260770320892333984375, 0.7469999790191650390625, 0.737999975681304931640625, 0.670000016689300537109375, 0.563000023365020751953125, 0.4309999942779541015625, 0.3039999902248382568359375, 0.1940000057220458984375, 0.1019999980926513671875, 0.0309999994933605194091796875, 0.614000022411346435546875, 0.609000027179718017578125, 0.566999971866607666015625, 0.499000012874603271484375, 0.412000000476837158203125, 0.32400000095367431640625, 0.240999996662139892578125, 0.162000000476837158203125, 0.087999999523162841796875, 0.538999974727630615234375, 0.535000026226043701171875, 0.505999982357025146484375, 0.4569999873638153076171875, 0.393999993801116943359375, 0.328999996185302734375, 0.2660000026226043701171875, 0.203999996185302734375, 0.14200000464916229248046875);\n\nuniform vec4 fa_mesh_fs_params[53];\nuniform vec4 fa_shadows[30];\nuniform vec4 fa_material[2];\nlayout(binding = 0) uniform sampler2D fa_light_tex_fa_shadow_smp;\nlayout(binding = 1) uniform sampler2D fa_tex_fa_smp;\nlayout(binding = 2) uniform sampler2D fa_normal_tex_fa_smp;\nlayout(binding = 3) uniform sampler2D fa_mr_tex_fa_smp;\nlayout(binding = 4) uniform sampler2D fa_occlusion_tex_fa_smp;\nlayout(binding = 5) uniform sampler2D fa_emissive_tex_fa_smp;\nlayout(binding = 6) uniform sampler2D fa_decal_tex_fa_env_smp;\nlayout(binding = 7) uniform sampler2D fa_light_atlas_fa_env_smp;\nlayout(binding = 8) uniform sampler2D fa_shadow_tex_fa_shadow_smp;\nlayout(binding = 9) uniform sampler2D fa_screen_tex_fa_shadow_smp;\nlayout(binding = 10) uniform sampler2D fa_probe_atlas_fa_env_smp;\n\nlayout(location = 0) in vec3 fa_world_pos;\nlayout(location = 5) in vec3 fa_lm;\nlayout(location = 1) in vec3 fa_world_normal;\nlayout(location = 2) in vec4 fa_world_tangent;\nlayout(location = 3) in vec2 fa_uv;\nlayout(location = 4) in vec4 fa_vertex_color;\nlayout(location = 0) out vec4 fa_frag_color;\nvec3 fa_light_tint;\nbool fa_light_is_area;\nint fa_cl_ndir;\nint fa_cl_slot;\nint fa_cl_local;\n\nvoid fa_inst_load()\n{\n}\n\nvec4 fa_light_texel(int t)\n{\n    return texelFetch(fa_light_tex_fa_shadow_smp, ivec2(t & 1023, t >> 10), 0);\n}\n\nvec4 fa_cluster_texel(vec3 world_pos)\n{\n    bool _1397 = fa_mesh_fs_params[19].x < 0.0;\n    bool _1404;\n    if (!_1397)\n    {\n        _1404 = fa_mesh_fs_params[19].w < 1.0;\n    }\n    else\n    {\n        _1404 = _1397;\n    }\n    bool _1412;\n    if (!_1404)\n    {\n        _1412 = fa_mesh_fs_params[18].x < 1.0;\n    }\n    else\n    {\n        _1412 = _1404;\n    }\n    bool _1419;\n    if (!_1412)\n    {\n        _1419 = fa_mesh_fs_params[18].y < 1.0;\n    }\n    else\n    {\n        _1419 = _1412;\n    }\n    bool _1426;\n    if (!_1419)\n    {\n        _1426 = fa_mesh_fs_params[19].y < 1.0;\n    }\n    else\n    {\n        _1426 = _1419;\n    }\n    if (_1426)\n    {\n        return vec4(0.0);\n    }\n    vec4 _1436 = vec4(world_pos, 1.0);\n    float _1442 = dot(fa_mesh_fs_params[16], _1436);\n    if (!(_1442 > 9.9999999747524270787835121154785e-07))\n    {\n        return vec4(0.0);\n    }\n    vec2 _1464 = vec2(dot(fa_mesh_fs_params[14], _1436), dot(fa_mesh_fs_params[15], _1436)) / vec2(_1442);\n    int _1468 = int(fa_mesh_fs_params[18].x);\n    int _1472 = int(fa_mesh_fs_params[18].y);\n    int param = (int(fa_mesh_fs_params[19].x) + (((clamp(int(floor(log2(max(dot(fa_mesh_fs_params[17].xyz, world_pos) + fa_mesh_fs_params[17].w, fa_mesh_fs_params[18].w) / fa_mesh_fs_params[18].w) * fa_mesh_fs_params[18].z)), 0, int(fa_mesh_fs_params[19].y) - 1) * _1472) + clamp(int(floor(((_1464.y * 0.5) + 0.5) * fa_mesh_fs_params[18].y)), 0, _1472 - 1)) * _1468)) + clamp(int(floor(((_1464.x * 0.5) + 0.5) * fa_mesh_fs_params[18].x)), 0, _1468 - 1);\n    return fa_light_texel(param);\n}\n\nivec2 fa_cluster_lookup(vec3 world_pos)\n{\n    vec3 param = world_pos;\n    vec4 _1548 = fa_cluster_texel(param);\n    return ivec2(int(_1548.x), int(_1548.y));\n}\n\nvoid fa_cluster_begin(vec3 world_pos)\n{\n    fa_cl_ndir = int(fa_mesh_fs_params[19].z);\n    vec3 param = world_pos;\n    ivec2 _4859 = fa_cluster_lookup(param);\n    fa_cl_slot = _4859.x;\n    fa_cl_local = _4859.y;\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_linear_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvec3 fa_tex_fix(inout vec3 c, float mode)\n{\n    if (mode > 1.5)\n    {\n        vec3 param = c;\n        vec3 _5236 = fa_linear_to_srgb(param);\n        c = _5236;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            vec3 param_1 = c;\n            vec3 _5244 = fa_srgb_to_linear(param_1);\n            c = _5244;\n        }\n    }\n    return c;\n}\n\nvec3 fa_tangent_normal(SurfaceInput i, vec3 m)\n{\n    vec3 _348;\n    if (i.front_facing)\n    {\n        _348 = i.world_normal;\n    }\n    else\n    {\n        _348 = -i.world_normal;\n    }\n    vec3 _372 = normalize(i.world_tangent.xyz - (_348 * dot(_348, i.world_tangent.xyz)));\n    vec3 _400 = normalize(((_372 * m.x) + ((cross(_348, _372) * i.world_tangent.w) * m.y)) + (_348 * m.z));\n    vec3 _403;\n    if (i.front_facing)\n    {\n        _403 = _400;\n    }\n    else\n    {\n        _403 = -_400;\n    }\n    return _403;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    vec4 base_t = texture(fa_tex_fa_smp, i.uv, fa_mesh_fs_params[12].w);\n    float param = fa_mesh_fs_params[6].w;\n    float param_1 = 1.0;\n    vec3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    vec3 _5276 = fa_tex_fix(param_2, param_3);\n    vec4 _6433 = base_t;\n    _6433.x = _5276.x;\n    _6433.y = _5276.y;\n    _6433.z = _5276.z;\n    base_t = _6433;\n    vec4 _5290 = (_6433 * fa_mesh_fs_params[2]) * i.vertex_color;\n    vec3 _6229 = i.world_normal;\n    if (fa_mesh_fs_params[6].z > 0.5)\n    {\n        float param_4 = fa_mesh_fs_params[6].w;\n        float param_5 = 16.0;\n        vec3 param_6 = texture(fa_normal_tex_fa_smp, i.uv, fa_mesh_fs_params[12].w).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        vec3 _5324 = fa_tex_fix(param_6, param_7);\n        vec3 _5327 = (_5324 * 2.0) - vec3(1.0);\n        vec2 _5332 = _5327.xy * fa_mesh_fs_params[6].x;\n        vec3 _6441 = _5327;\n        _6441.x = _5332.x;\n        _6441.y = _5332.y;\n        SurfaceInput param_8 = i;\n        vec3 param_9 = _6441;\n        _6229 = fa_tangent_normal(param_8, param_9);\n    }\n    vec4 mrt = texture(fa_mr_tex_fa_smp, i.uv, fa_mesh_fs_params[12].w);\n    float param_10 = fa_mesh_fs_params[6].w;\n    float param_11 = 64.0;\n    vec3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    vec3 _5362 = fa_tex_fix(param_12, param_13);\n    vec4 _6444 = mrt;\n    _6444.x = _5362.x;\n    _6444.y = _5362.y;\n    _6444.z = _5362.z;\n    mrt = _6444;\n    vec4 _5392 = texture(fa_occlusion_tex_fa_smp, i.uv, fa_mesh_fs_params[12].w);\n    float param_14 = fa_mesh_fs_params[6].w;\n    float param_15 = 256.0;\n    vec3 param_16 = _5392.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    vec3 _5403 = fa_tex_fix(param_16, param_17);\n    float param_18 = fa_mesh_fs_params[6].w;\n    float param_19 = 4.0;\n    vec3 param_20 = texture(fa_emissive_tex_fa_smp, i.uv, fa_mesh_fs_params[12].w).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    vec3 _5435 = fa_tex_fix(param_20, param_21);\n    float _6234 = fa_mesh_fs_params[20].x;\n    float _6235 = fa_mesh_fs_params[20].y;\n    float _6238 = fa_mesh_fs_params[20].z;\n    float _6237 = fa_mesh_fs_params[21].w;\n    float _6240 = fa_mesh_fs_params[22].x;\n    if (fa_mesh_fs_params[22].z > 0.5)\n    {\n        if (mod(fa_mesh_fs_params[22].z, 2.0) > 0.5)\n        {\n            _6234 *= _5403.y;\n            _6235 *= _5403.z;\n            _6237 *= _5392.w;\n        }\n        if (fa_mesh_fs_params[22].z > 1.5)\n        {\n            _6238 *= mrt.x;\n            _6240 *= mrt.w;\n        }\n    }\n    return Surface(_5290.xyz, _5290.w, _6229, clamp(fa_mesh_fs_params[5].x * _5362.z, 0.0, 1.0), clamp(fa_mesh_fs_params[5].y * _5362.y, 0.0500000007450580596923828125, 1.0), 1.0 + (fa_mesh_fs_params[6].y * (_5403.x - 1.0)), fa_mesh_fs_params[3].xyz + (fa_mesh_fs_params[4].xyz * _5435), _6234, _6235, fa_mesh_fs_params[21].xyz, _6237, _6238, fa_mesh_fs_params[20].w, _6240, fa_mesh_fs_params[22].y, fa_mesh_fs_params[23].xyz, fa_mesh_fs_params[30].x, fa_mesh_fs_params[30].y, fa_mesh_fs_params[31].xyz, fa_mesh_fs_params[30].z);\n}\n\nvoid surface(SurfaceInput i, Surface s)\n{\n}\n\nvec4 fa_decal_tile(vec4 rect, vec2 uv, vec2 atlas, vec2 ddx, vec2 ddy)\n{\n    vec2 _1628 = rect.zw - rect.xy;\n    vec2 _1632 = _1628 * atlas;\n    vec2 _1636 = ddx * _1632;\n    vec2 _1640 = ddy * _1632;\n    return textureLod(fa_decal_tex_fa_env_smp, rect.xy + (clamp(uv, vec2(0.0), vec2(1.0)) * _1628), clamp(0.5 * log2(max(max(dot(_1636, _1636), dot(_1640, _1640)), 9.9999999392252902907785028219223e-09)), 0.0, 3.0));\n}\n\nvec3 fa_dc_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_dc_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvoid fa_apply_decals(vec3 world_pos, vec3 geo_normal, inout vec3 albedo, inout vec3 normal)\n{\n    bool _1673 = fa_mesh_fs_params[10].y < 0.5;\n    bool _1680;\n    if (!_1673)\n    {\n        _1680 = fa_mesh_fs_params[10].w < 0.5;\n    }\n    else\n    {\n        _1680 = _1673;\n    }\n    if (_1680)\n    {\n        return;\n    }\n    vec3 _1686 = dFdx(world_pos);\n    vec3 _1689 = dFdy(world_pos);\n    vec3 param = world_pos;\n    vec4 _1693 = fa_cluster_texel(param);\n    int _1697 = int(_1693.w);\n    if (_1697 < 1)\n    {\n        return;\n    }\n    int _1707 = int(fa_mesh_fs_params[10].y + 0.5);\n    int param_1 = _1707;\n    vec4 _1711 = fa_light_texel(param_1);\n    vec2 _1714 = _1711.yz;\n    int _1718 = int(_1711.w);\n    int param_2 = _1707 + 1;\n    vec4 _1723 = fa_light_texel(param_2);\n    float _1724 = _1723.x;\n    int _1730 = int(fa_mesh_fs_params[10].w + 0.5) - 1;\n    int _1734 = int(_1693.z);\n    vec3 _1999;\n    for (int k = 0; k < _1697; k++)\n    {\n        int _1747 = _1734 + k;\n        int param_3 = _1718 + (_1747 >> 2);\n        int _1764 = (_1707 + 2) + (int(fa_light_texel(param_3)[_1747 & 3]) * 7);\n        int param_4 = _1764 + 6;\n        vec4 _1769 = fa_light_texel(param_4);\n        if (((int(_1769.w + 0.5) >> _1730) & 1) == 0)\n        {\n            continue;\n        }\n        int param_5 = _1764;\n        vec4 _1784 = fa_light_texel(param_5);\n        int param_6 = _1764 + 1;\n        vec4 _1789 = fa_light_texel(param_6);\n        int param_7 = _1764 + 2;\n        vec4 _1794 = fa_light_texel(param_7);\n        vec3 _1797 = _1784.xyz;\n        float _1802 = dot(_1797, world_pos) + _1784.w;\n        vec3 _1804 = _1789.xyz;\n        float _1809 = dot(_1804, world_pos) + _1789.w;\n        vec3 _1811 = _1794.xyz;\n        float _1816 = dot(_1811, world_pos) + _1794.w;\n        bool _1821 = abs(_1802) > 0.5;\n        bool _1829;\n        if (!_1821)\n        {\n            _1829 = abs(_1809) > 0.5;\n        }\n        else\n        {\n            _1829 = _1821;\n        }\n        bool _1837;\n        if (!_1829)\n        {\n            _1837 = abs(_1816) > 0.5;\n        }\n        else\n        {\n            _1837 = _1829;\n        }\n        if (_1837)\n        {\n            continue;\n        }\n        float _1852 = clamp(dot(geo_normal, normalize(_1811)) * _1769.z, 0.0, 1.0);\n        if (_1852 <= 0.0)\n        {\n            continue;\n        }\n        float _1872 = (clamp((0.5 - abs(_1816)) * 10.0, 0.0, 1.0) * _1852) * _1769.x;\n        vec2 _1880 = vec2(_1802 + 0.5, 0.5 - _1809);\n        vec2 _1890 = vec2(dot(_1797, _1686), dot(_1804, _1686));\n        vec2 _1900 = vec2(dot(_1797, _1689), dot(_1804, _1689));\n        int param_8 = _1764 + 5;\n        vec4 _1905 = fa_light_texel(param_8);\n        int param_9 = _1764 + 3;\n        vec4 _1910 = fa_light_texel(param_9);\n        int param_10 = _1764 + 4;\n        vec4 _1915 = fa_light_texel(param_10);\n        float tex_a = 1.0;\n        vec3 col = _1905.xyz;\n        bool _1925 = _1910.z > _1910.x;\n        if (_1925)\n        {\n            vec4 param_11 = _1910;\n            vec2 param_12 = _1880;\n            vec2 param_13 = _1714;\n            vec2 param_14 = _1890;\n            vec2 param_15 = _1900;\n            vec4 tx = fa_decal_tile(param_11, param_12, param_13, param_14, param_15);\n            if ((_1724 > 0.5) && (_1724 < 1.5))\n            {\n                vec3 param_16 = tx.xyz;\n                vec3 _1951 = fa_dc_to_linear(param_16);\n                vec4 _6317 = tx;\n                _6317.x = _1951.x;\n                _6317.y = _1951.y;\n                _6317.z = _1951.z;\n                tx = _6317;\n            }\n            col *= tx.xyz;\n            tex_a = tx.w;\n        }\n        albedo = mix(albedo, col, vec3(clamp((_1872 * tex_a) * _1905.w, 0.0, 1.0)));\n        if (_1915.z > _1915.x)\n        {\n            vec4 param_17 = _1915;\n            vec2 param_18 = _1880;\n            vec2 param_19 = _1714;\n            vec2 param_20 = _1890;\n            vec2 param_21 = _1900;\n            vec4 _1995 = fa_decal_tile(param_17, param_18, param_19, param_20, param_21);\n            if (_1724 > 1.5)\n            {\n                vec3 param_22 = _1995.xyz;\n                vec3 _2005 = fa_dc_to_srgb(param_22);\n                _1999 = _2005;\n            }\n            else\n            {\n                _1999 = _1995.xyz;\n            }\n            vec3 _2014 = (_1999 * 2.0) - vec3(1.0);\n            vec2 _2019 = _2014.xy * _1769.y;\n            vec3 _2041 = (normalize(_1797) * _2019.x) + (normalize(_1804) * _2019.y);\n            vec3 _2044 = normalize(normal);\n            normal = normalize(mix(_2044, normalize((_2044 * max(_2014.z, 0.0500000007450580596923828125)) + (_2041 - (_2044 * dot(_2044, _2041)))), vec3(clamp(_1872 * (_1925 ? tex_a : 1.0), 0.0, 1.0))));\n        }\n    }\n}\n\nint fa_light_count()\n{\n    return fa_cl_ndir + fa_cl_local;\n}\n\nLightSample fa_no_light()\n{\n    return LightSample(vec3(0.0, 1.0, 0.0), vec3(0.0), 0.0, 1.0, 0.0, 0);\n}\n\nint fa_cluster_index(int slot, int n)\n{\n    int param = (int(fa_mesh_fs_params[19].x) + int(fa_mesh_fs_params[19].w)) + ((slot + n) >> 2);\n    vec4 t = fa_light_texel(param);\n    return int(t[(slot + n) & 3]);\n}\n\nint fa_cl_light(int n)\n{\n    if (n < fa_cl_ndir)\n    {\n        return n;\n    }\n    int param = fa_cl_slot;\n    int param_1 = n - fa_cl_ndir;\n    return fa_cluster_index(param, param_1);\n}\n\nint fa_light_base(int li)\n{\n    return li * ((fa_mesh_fs_params[1].w > 4.5) ? 8 : 4);\n}\n\nbool fa_light_baked(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 3;\n    return fa_light_texel(param_1).w > 0.5;\n}\n\nfloat fa_baked_keep(int li)\n{\n    float _4829;\n    if (fa_lm.z > 0.5)\n    {\n        _4829 = 0.0;\n    }\n    else\n    {\n        _4829 = 1.0 - clamp(fa_mesh_fs_params[32].w, 0.0, 1.0);\n    }\n    bool _4840 = _4829 < 1.0;\n    bool _4846;\n    if (_4840)\n    {\n        int param = li;\n        _4846 = fa_light_baked(param);\n    }\n    else\n    {\n        _4846 = _4840;\n    }\n    return _4846 ? _4829 : 1.0;\n}\n\nvec3 fa_area_point(vec3 c, vec3 axis, vec3 ru, vec3 uu, float hx, float hy, float shape, vec3 p, vec3 r)\n{\n    bool _646 = dot(r, r) > 0.5;\n    if (shape > 1.5)\n    {\n        vec3 _659 = (c - (ru * hx)) - p;\n        vec3 _665 = ru * (2.0 * hx);\n        float _671 = max(dot(_665, _665), 9.9999999392252902907785028219223e-09);\n        float _675 = dot(_659, _665);\n        float t = clamp((-_675) / _671, 0.0, 1.0);\n        if (_646)\n        {\n            float _690 = dot(r, _665);\n            float _696 = _671 - (_690 * _690);\n            if (abs(_696) > (9.9999997473787516355514526367188e-06 * _671))\n            {\n                t = clamp(((dot(r, _659) * _690) - _675) / _696, 0.0, 1.0);\n            }\n        }\n        return (p + _659) + (_665 * t);\n    }\n    vec3 q = p;\n    float _728 = dot(r, axis);\n    bool _736;\n    if (_646)\n    {\n        _736 = abs(_728) > 9.9999997473787516355514526367188e-05;\n    }\n    else\n    {\n        _736 = _646;\n    }\n    if (_736)\n    {\n        float _746 = dot(c - p, axis) / _728;\n        if (_746 > 0.0)\n        {\n            q = p + (r * _746);\n        }\n    }\n    vec3 _759 = q - c;\n    vec2 xy = vec2(dot(_759, ru), dot(_759, uu));\n    if (shape > 0.5)\n    {\n        float _774 = length(xy);\n        if (_774 > hx)\n        {\n            xy *= (hx / _774);\n        }\n    }\n    else\n    {\n        xy = clamp(xy, vec2(-hx, -hy), vec2(hx, hy));\n    }\n    return (c + (ru * xy.x)) + (uu * xy.y);\n}\n\nvec4 fa_atlas_fetch(vec2 texel)\n{\n    return textureLod(fa_light_atlas_fa_env_smp, texel / vec2(textureSize(fa_light_atlas_fa_env_smp, 0)), 0.0);\n}\n\nvec3 fa_cookie_sample(vec2 tile_origin, vec2 uv)\n{\n    vec2 param = (tile_origin + vec2(1.0)) + (clamp(uv, vec2(0.0), vec2(1.0)) * 254.0);\n    return fa_atlas_fetch(param).xyz;\n}\n\nfloat fa_ies_sample(vec2 tile_origin, vec3 d, vec3 axis, vec3 right, vec3 up)\n{\n    float _566 = dot(d, right);\n    float _570 = dot(d, up);\n    float _581;\n    if (((_566 * _566) + (_570 * _570)) > 1.0000000133514319600180897396058e-10)\n    {\n        _581 = atan(_570, _566) * 0.15915493667125701904296875;\n    }\n    else\n    {\n        _581 = 0.0;\n    }\n    vec2 param = tile_origin + vec2(1.0 + ((_581 - floor(_581)) * 64.0), 1.0 + (acos(clamp(dot(d, axis), -1.0, 1.0)) * 10.18591594696044921875));\n    return fa_atlas_fetch(param).x;\n}\n\nint fa_cube_face(vec3 d)\n{\n    vec3 _415 = abs(d);\n    float _417 = _415.x;\n    float _419 = _415.y;\n    bool _420 = _417 >= _419;\n    bool _428;\n    if (_420)\n    {\n        _428 = _417 >= _415.z;\n    }\n    else\n    {\n        _428 = _420;\n    }\n    int _429;\n    if (_428)\n    {\n        _429 = (d.x > 0.0) ? 0 : 1;\n    }\n    else\n    {\n        int _444;\n        if (_419 >= _415.z)\n        {\n            _444 = (d.y > 0.0) ? 2 : 3;\n        }\n        else\n        {\n            _444 = (d.z > 0.0) ? 4 : 5;\n        }\n        _429 = _444;\n    }\n    return _429;\n}\n\nvoid fa_cube_face_basis(int f, out vec3 fwd, out vec3 up)\n{\n    if (f == 0)\n    {\n        fwd = vec3(1.0, 0.0, 0.0);\n        up = vec3(0.0, 1.0, 0.0);\n    }\n    else\n    {\n        if (f == 1)\n        {\n            fwd = vec3(-1.0, 0.0, 0.0);\n            up = vec3(0.0, 1.0, 0.0);\n        }\n        else\n        {\n            if (f == 2)\n            {\n                fwd = vec3(0.0, 1.0, 0.0);\n                up = vec3(0.0, 0.0, 1.0);\n            }\n            else\n            {\n                if (f == 3)\n                {\n                    fwd = vec3(0.0, -1.0, 0.0);\n                    up = vec3(0.0, 0.0, -1.0);\n                }\n                else\n                {\n                    if (f == 4)\n                    {\n                        fwd = vec3(0.0, 0.0, 1.0);\n                        up = vec3(0.0, 1.0, 0.0);\n                    }\n                    else\n                    {\n                        fwd = vec3(0.0, 0.0, -1.0);\n                        up = vec3(0.0, 1.0, 0.0);\n                    }\n                }\n            }\n        }\n    }\n}\n\nLightSample fa_light_sample_n(int li, vec3 world_pos, vec3 n)\n{\n    int param = li;\n    int _812 = fa_light_base(param);\n    bool _816 = fa_mesh_fs_params[1].w > 4.5;\n    int param_1 = _812;\n    vec4 _820 = fa_light_texel(param_1);\n    int param_2 = _812 + 1;\n    vec4 _825 = fa_light_texel(param_2);\n    float _828 = _825.w;\n    float atten = 1.0;\n    float dist = 0.0;\n    fa_light_tint = vec3(1.0);\n    bool _840 = _816 && (_828 > 2.5);\n    fa_light_is_area = _840;\n    bool _842 = _828 < 0.5;\n    vec3 l;\n    if (_842)\n    {\n        l = normalize(_820.xyz);\n        if (_816)\n        {\n            int param_3 = _812 + 6;\n            vec4 _856 = fa_light_texel(param_3);\n            if (_856.z > 0.5)\n            {\n                int param_4 = _812 + 4;\n                vec4 _866 = fa_light_texel(param_4);\n                int param_5 = _812 + 5;\n                vec4 _871 = fa_light_texel(param_5);\n                vec2 param_6 = _856.xy;\n                vec2 param_7 = fract(vec2(dot(world_pos, _866.xyz) * _866.w, (-dot(world_pos, _871.xyz)) * _871.w) + vec2(0.5));\n                fa_light_tint = fa_cookie_sample(param_6, param_7);\n            }\n        }\n    }\n    else\n    {\n        vec3 _901 = _820.xyz;\n        vec3 _903 = _901 - world_pos;\n        vec3 to_light = _903;\n        float _906 = length(_903);\n        float reach = _906;\n        bool front = true;\n        if (_840)\n        {\n            int param_8 = _812 + 7;\n            reach = max(_906 - fa_light_texel(param_8).w, 0.0);\n            int param_9 = _812 + 4;\n            vec4 _930 = fa_light_texel(param_9);\n            int param_10 = _812 + 5;\n            vec4 _935 = fa_light_texel(param_10);\n            int param_11 = _812 + 6;\n            vec4 _940 = fa_light_texel(param_11);\n            float _941 = _940.w;\n            int param_12 = _812 + 2;\n            vec3 _948 = normalize(fa_light_texel(param_12).xyz);\n            bool _950 = _941 > 1.5;\n            bool _958;\n            if (!_950)\n            {\n                _958 = dot(_948, to_light) < 0.0;\n            }\n            else\n            {\n                _958 = _950;\n            }\n            front = _958;\n            vec3 r = vec3(0.0);\n            vec3 _967 = fa_mesh_fs_params[0].xyz - world_pos;\n            bool _971 = dot(n, n) > 0.5;\n            bool _979;\n            if (_971)\n            {\n                _979 = dot(_967, _967) > 9.9999999600419720025001879548654e-13;\n            }\n            else\n            {\n                _979 = _971;\n            }\n            if (_979)\n            {\n                r = reflect(-normalize(_967), normalize(n));\n            }\n            vec3 param_13 = _901;\n            vec3 param_14 = _948;\n            vec3 param_15 = _930.xyz;\n            vec3 param_16 = _935.xyz;\n            float param_17 = _930.w;\n            float param_18 = _935.w;\n            float param_19 = _941;\n            vec3 param_20 = world_pos;\n            vec3 param_21 = r;\n            to_light = fa_area_point(param_13, param_14, param_15, param_16, param_17, param_18, param_19, param_20, param_21) - world_pos;\n        }\n        float _1015 = length(to_light);\n        dist = _1015;\n        l = to_light / vec3(max(_1015, 9.9999997473787516355514526367188e-05));\n        float _1029 = reach / max(_820.w, 0.001000000047497451305389404296875);\n        float _1035 = clamp(1.0 - (_1029 * _1029), 0.0, 1.0);\n        float _1037;\n        if (front)\n        {\n            _1037 = _1035 * _1035;\n        }\n        else\n        {\n            _1037 = 0.0;\n        }\n        atten = _1037;\n        bool _1048 = _828 < 2.5;\n        if ((_828 > 1.5) && _1048)\n        {\n            int param_22 = _812 + 2;\n            vec4 _1056 = fa_light_texel(param_22);\n            float _1066 = _1056.w;\n            int param_23 = _812 + 3;\n            vec4 _1071 = fa_light_texel(param_23);\n            float _1072 = _1071.x;\n            float cos_inner = _1072;\n            if (_1072 > 1.5)\n            {\n                cos_inner = mix(_1066, 1.0, 0.25);\n            }\n            atten *= smoothstep(_1066, cos_inner, dot(-l, normalize(_1056.xyz)));\n        }\n        if (_816 && (_828 < 1.5))\n        {\n            int param_24 = _812 + 6;\n            vec4 _1096 = fa_light_texel(param_24);\n            if (_1096.z > 0.5)\n            {\n                vec3 _1104 = -to_light;\n                int param_25 = _812 + 4;\n                int param_26 = _812 + 5;\n                vec3 _1118 = fa_light_texel(param_25).xyz;\n                vec3 _1122 = fa_light_texel(param_26).xyz;\n                vec3 _1131 = vec3(dot(_1104, _1118), dot(_1104, _1122), dot(_1104, cross(_1118, _1122)));\n                vec3 param_27 = _1131;\n                int _1135 = fa_cube_face(param_27);\n                int param_28 = _1135;\n                vec3 param_29;\n                vec3 param_30;\n                fa_cube_face_basis(param_28, param_29, param_30);\n                vec2 _1162 = vec2(dot(_1131, cross(param_29, param_30)), dot(_1131, param_30)) / vec2(max(dot(_1131, param_29), 9.9999997473787516355514526367188e-05));\n                int _1166 = _1135 / 3;\n                vec2 param_31 = _1096.xy + (vec2(float(_1135 - (_1166 * 3)), float(_1166)) * 256.0);\n                vec2 param_32 = vec2(0.5 + (0.5 * _1162.x), 0.5 - (0.5 * _1162.y));\n                fa_light_tint = fa_cookie_sample(param_31, param_32);\n            }\n            int param_33 = _812 + 7;\n            vec4 _1196 = fa_light_texel(param_33);\n            if (_1196.z > 0.5)\n            {\n                int param_34 = _812 + 2;\n                int param_35 = _812 + 4;\n                int param_36 = _812 + 5;\n                vec2 param_37 = _1196.xy;\n                vec3 param_38 = -l;\n                vec3 param_39 = normalize(fa_light_texel(param_34).xyz);\n                vec3 param_40 = fa_light_texel(param_35).xyz;\n                vec3 param_41 = fa_light_texel(param_36).xyz;\n                atten *= fa_ies_sample(param_37, param_38, param_39, param_40, param_41);\n            }\n        }\n        else\n        {\n            if (_816 && _1048)\n            {\n                int param_42 = _812 + 6;\n                vec4 _1243 = fa_light_texel(param_42);\n                int param_43 = _812 + 7;\n                vec4 _1248 = fa_light_texel(param_43);\n                bool _1251 = _1243.z > 0.5;\n                bool _1258;\n                if (!_1251)\n                {\n                    _1258 = _1248.z > 0.5;\n                }\n                else\n                {\n                    _1258 = _1251;\n                }\n                if (_1258)\n                {\n                    int param_44 = _812 + 2;\n                    vec4 _1265 = fa_light_texel(param_44);\n                    vec3 _1269 = normalize(_1265.xyz);\n                    int param_45 = _812 + 4;\n                    vec4 _1274 = fa_light_texel(param_45);\n                    int param_46 = _812 + 5;\n                    vec4 _1279 = fa_light_texel(param_46);\n                    if (_1251)\n                    {\n                        vec3 _1287 = -to_light;\n                        float _1294 = _1265.w;\n                        float _1310 = 0.5 / max(dot(_1287, _1269) * (sqrt(max(1.0 - (_1294 * _1294), 0.0)) / max(_1294, 0.001000000047497451305389404296875)), 9.9999997473787516355514526367188e-05);\n                        vec2 param_47 = _1243.xy;\n                        vec2 param_48 = vec2(0.5 + (dot(_1287, _1274.xyz) * _1310), 0.5 - (dot(_1287, _1279.xyz) * _1310));\n                        fa_light_tint = fa_cookie_sample(param_47, param_48);\n                    }\n                    if (_1248.z > 0.5)\n                    {\n                        vec2 param_49 = _1248.xy;\n                        vec3 param_50 = -l;\n                        vec3 param_51 = _1269;\n                        vec3 param_52 = _1274.xyz;\n                        vec3 param_53 = _1279.xyz;\n                        atten *= fa_ies_sample(param_49, param_50, param_51, param_52, param_53);\n                    }\n                }\n            }\n        }\n    }\n    vec3 _6035 = _825.xyz * atten;\n    if (_816)\n    {\n        _6035 *= fa_light_tint;\n    }\n    int _1379;\n    if (_842)\n    {\n        _1379 = 0;\n    }\n    else\n    {\n        _1379 = ((_828 > 1.5) && (_828 < 2.5)) ? 2 : 1;\n    }\n    return LightSample(l, _6035, atten, 1.0, dist, _1379);\n}\n\nLightSample fa_light_unshadowed(int n, SurfaceInput i)\n{\n    bool _5058 = n < 0;\n    bool _5065;\n    if (!_5058)\n    {\n        _5065 = n >= fa_light_count();\n    }\n    else\n    {\n        _5065 = _5058;\n    }\n    if (_5065)\n    {\n        return fa_no_light();\n    }\n    int param = n;\n    int _5073 = fa_cl_light(param);\n    int param_1 = _5073;\n    float _5077 = fa_baked_keep(param_1);\n    if (_5077 <= 0.0)\n    {\n        return fa_no_light();\n    }\n    int param_2 = _5073;\n    vec3 param_3 = i.world_pos;\n    vec3 param_4 = i.world_normal;\n    LightSample _5093 = fa_light_sample_n(param_2, param_3, param_4);\n    return LightSample(_5093.direction, _5093.color * _5077, _5093.attenuation * _5077, _5093.shadow, _5093._distance, _5093.type);\n}\n\nfloat fa_light_type(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 1;\n    return fa_light_texel(param_1).w;\n}\n\nfloat fa_shadow_depth(inout vec2 uv, vec4 rect)\n{\n    uv = clamp(uv, rect.xy, rect.zw);\n    return textureLod(fa_shadow_tex_fa_shadow_smp, uv, 0.0).x;\n}\n\nfloat fa_shadow_fetch(vec2 uv, vec4 rect, vec3 conv)\n{\n    vec2 param = uv;\n    vec4 param_1 = rect;\n    float _2168 = fa_shadow_depth(param, param_1);\n    float _2172;\n    if (conv.x < 0.5)\n    {\n        _2172 = _2168;\n    }\n    else\n    {\n        _2172 = (conv.y * conv.z) / (conv.z - (_2168 * (conv.z - conv.y)));\n    }\n    return _2172;\n}\n\nfloat fa_shadow_noise()\n{\n    return fract(52.98291778564453125 * fract(dot(gl_FragCoord.xy, vec2(0.067110560834407806396484375, 0.005837149918079376220703125))));\n}\n\nvec2 fa_shadow_vogel_turn(vec2 d)\n{\n    return vec2((d.x * (-0.737368881702423095703125)) - (d.y * 0.675490319728851318359375), (d.y * (-0.737368881702423095703125)) + (d.x * 0.675490319728851318359375));\n}\n\nfloat fa_shadow_filter(vec2 uv, vec4 rect, float zr, float texel_m, float unit, float reach, float plane, vec3 conv, int mode, float k)\n{\n    if (mode == 1)\n    {\n        vec2 param = uv;\n        vec4 param_1 = rect;\n        vec3 param_2 = conv;\n        return float(zr <= fa_shadow_fetch(param, param_1, param_2));\n    }\n    float _2218 = fa_shadow_noise() * 6.283185482025146484375;\n    vec2 _2224 = vec2(cos(_2218), sin(_2218));\n    vec2 dir = _2224;\n    float radius = 1.5;\n    if (mode == 2)\n    {\n        float _2233;\n        if (k < 0.0)\n        {\n            _2233 = (-k) / max(zr, 0.100000001490116119384765625);\n        }\n        else\n        {\n            _2233 = k;\n        }\n        float _2252 = clamp((_2233 * reach) / texel_m, 3.0, 12.0);\n        float sum = 0.0;\n        float cnt = 0.0;\n        for (int i = 0; i < 16; i++)\n        {\n            float _2271 = sqrt((float(i) + 0.5) * 0.0625) * _2252;\n            vec2 param_3 = uv + (dir * (fa_shadows[26].zw * _2271));\n            vec4 param_4 = rect;\n            vec3 param_5 = conv;\n            float _2285 = fa_shadow_fetch(param_3, param_4, param_5);\n            if (_2285 < (zr - (_2271 * plane)))\n            {\n                sum += _2285;\n                cnt += 1.0;\n            }\n            vec2 param_6 = dir;\n            dir = fa_shadow_vogel_turn(param_6);\n        }\n        if (cnt < 0.5)\n        {\n            return 1.0;\n        }\n        float _2313 = sum / cnt;\n        float _2323;\n        if (k < 0.0)\n        {\n            _2323 = (-k) / max(_2313, 0.0500000007450580596923828125);\n        }\n        else\n        {\n            _2323 = k;\n        }\n        radius = clamp(((max(zr - _2313, 0.0) * unit) * _2323) / texel_m, 1.5, 16.0);\n        dir = _2224;\n    }\n    float lit = 0.0;\n    int _2349 = (mode == 2) ? 24 : 16;\n    for (int i_1 = 0; i_1 < _2349; i_1++)\n    {\n        float _2368 = sqrt((float(i_1) + 0.5) / float(_2349)) * radius;\n        vec2 param_7 = uv + (dir * (fa_shadows[26].zw * _2368));\n        vec4 param_8 = rect;\n        vec3 param_9 = conv;\n        lit += float((zr - (_2368 * plane)) <= fa_shadow_fetch(param_7, param_8, param_9));\n        vec2 param_10 = dir;\n        dir = fa_shadow_vogel_turn(param_10);\n    }\n    return lit / float(_2349);\n}\n\nfloat fa_shadow_local(int li, vec3 lpos, vec3 world, vec3 n, vec3 l)\n{\n    bool _2573 = fa_mesh_fs_params[5].z < 0.5;\n    bool _2580;\n    if (!_2573)\n    {\n        _2580 = fa_shadows[29].x < 0.5;\n    }\n    else\n    {\n        _2580 = _2573;\n    }\n    if (_2580)\n    {\n        return 1.0;\n    }\n    int param = (int(fa_shadows[29].x + 0.5) - 1) + li;\n    vec4 _2593 = fa_light_texel(param);\n    float _2594 = _2593.x;\n    if (_2594 < 0.0)\n    {\n        return 1.0;\n    }\n    int _2603 = int(_2594 + 0.5);\n    int param_1 = _2603;\n    vec4 _2607 = fa_light_texel(param_1);\n    int param_2 = _2603 + 1;\n    vec4 _2612 = fa_light_texel(param_2);\n    float fade = 1.0;\n    float _2615 = _2607.y;\n    if (_2615 > 0.0)\n    {\n        float _2632 = 1.0 - smoothstep(0.75 * _2615, _2615, length(world - fa_shadows[27].xyz));\n        fade = _2632;\n        if (_2632 <= 0.0)\n        {\n            return 1.0;\n        }\n    }\n    int face = 0;\n    if (_2607.x > 1.5)\n    {\n        vec3 param_3 = world - lpos;\n        face = fa_cube_face(param_3);\n    }\n    int _2656 = (_2603 + 2) + (face * 6);\n    int param_4 = _2656;\n    int param_5 = _2656 + 1;\n    int param_6 = _2656 + 3;\n    vec4 _2670 = fa_light_texel(param_6);\n    int param_7 = _2656 + 4;\n    vec4 _2675 = fa_light_texel(param_7);\n    int param_8 = _2656 + 5;\n    vec4 _2680 = fa_light_texel(param_8);\n    float _2692 = _2680.x * max(dot(_2670, vec4(world, 1.0)), 0.001000000047497451305389404296875);\n    float _2697 = clamp(dot(n, l), 0.0, 1.0);\n    float _2720 = clamp(dot(n, _2670.xyz), -1.0, 1.0);\n    float _2739 = min(sqrt(1.0 - (_2720 * _2720)) / max(abs(dot(n, world - lpos)) / max(dot(_2670, vec4(world, 1.0)), 0.001000000047497451305389404296875), 0.20000000298023223876953125), 4.0);\n    float _2742 = _2612.y;\n    float _2744;\n    if (_2742 > 0.0)\n    {\n        _2744 = _2742;\n    }\n    else\n    {\n        _2744 = 1.5 * _2692;\n    }\n    vec4 _2764 = vec4(world + (n * (_2744 * sqrt(1.0 - (_2697 * _2697)))), 1.0);\n    float _2768 = dot(_2670, _2764);\n    float _2771 = _2680.y;\n    if (_2768 < _2771)\n    {\n        return 1.0;\n    }\n    vec2 _2786 = vec2(dot(fa_light_texel(param_4), _2764), dot(fa_light_texel(param_5), _2764)) / vec2(_2768);\n    float _2788 = _2786.x;\n    bool _2791 = _2788 < _2675.x;\n    bool _2800;\n    if (!_2791)\n    {\n        _2800 = _2788 > _2675.z;\n    }\n    else\n    {\n        _2800 = _2791;\n    }\n    bool _2809;\n    if (!_2800)\n    {\n        _2809 = _2786.y < _2675.y;\n    }\n    else\n    {\n        _2809 = _2800;\n    }\n    bool _2818;\n    if (!_2809)\n    {\n        _2818 = _2786.y > _2675.w;\n    }\n    else\n    {\n        _2818 = _2809;\n    }\n    if (_2818)\n    {\n        return 1.0;\n    }\n    float _2824 = _2612.x;\n    float _2826;\n    if (_2824 > 0.0)\n    {\n        _2826 = _2824;\n    }\n    else\n    {\n        _2826 = 1.5 * _2692;\n    }\n    vec2 param_9 = _2786;\n    vec4 param_10 = _2675;\n    float param_11 = _2768 - (_2826 * (1.0 + (0.5 * _2739)));\n    float param_12 = _2692;\n    float param_13 = 1.0;\n    float param_14 = _2680.z * 0.25;\n    float param_15 = (_2692 * min(_2739, 3.0)) * 0.5;\n    vec3 param_16 = vec3(1.0, _2771, _2680.z);\n    int param_17 = int(_2607.z + 0.5);\n    float param_18 = _2607.w;\n    return mix(1.0, fa_shadow_filter(param_9, param_10, param_11, param_12, param_13, param_14, param_15, param_16, param_17, param_18), fade);\n}\n\nfloat fa_shadow_split_at(int i)\n{\n    float _2111;\n    if (i == 0)\n    {\n        _2111 = fa_shadows[24].x;\n    }\n    else\n    {\n        float _2127;\n        if (i == 1)\n        {\n            _2127 = fa_shadows[24].y;\n        }\n        else\n        {\n            float _2135;\n            if (i == 2)\n            {\n                _2135 = fa_shadows[24].z;\n            }\n            else\n            {\n                _2135 = fa_shadows[24].w;\n            }\n            _2127 = _2135;\n        }\n        _2111 = _2127;\n    }\n    return _2111;\n}\n\nfloat fa_shadow_cascade(int ci, vec3 world, vec3 n, vec3 l)\n{\n    float _2414 = max(fa_shadows[ci * 1 + 20].y, 0.001000000047497451305389404296875);\n    float _2419 = clamp(dot(n, l), 0.0, 1.0);\n    float _2425 = sqrt(1.0 - (_2419 * _2419));\n    float _2433 = min(_2425 / max(_2419, 0.20000000298023223876953125), 4.0);\n    float _2438;\n    if (fa_shadows[26].y > 0.0)\n    {\n        _2438 = fa_shadows[26].y;\n    }\n    else\n    {\n        _2438 = 1.5 * fa_shadows[ci * 1 + 20].x;\n    }\n    vec4 _2463 = mat4(fa_shadows[ci * 4 + 0], fa_shadows[ci * 4 + 1], fa_shadows[ci * 4 + 2], fa_shadows[ci * 4 + 3]) * vec4(world + (n * (_2438 * _2425)), 1.0);\n    float _2470 = _2463.x;\n    bool _2473 = _2470 < fa_shadows[ci * 1 + 16].x;\n    bool _2482;\n    if (!_2473)\n    {\n        _2482 = _2470 > fa_shadows[ci * 1 + 16].z;\n    }\n    else\n    {\n        _2482 = _2473;\n    }\n    bool _2491;\n    if (!_2482)\n    {\n        _2491 = _2463.y < fa_shadows[ci * 1 + 16].y;\n    }\n    else\n    {\n        _2491 = _2482;\n    }\n    bool _2500;\n    if (!_2491)\n    {\n        _2500 = _2463.y > fa_shadows[ci * 1 + 16].w;\n    }\n    else\n    {\n        _2500 = _2491;\n    }\n    bool _2507;\n    if (!_2500)\n    {\n        _2507 = _2463.z > 1.0;\n    }\n    else\n    {\n        _2507 = _2500;\n    }\n    if (_2507)\n    {\n        return -1.0;\n    }\n    float _2515;\n    if (fa_shadows[26].x > 0.0)\n    {\n        _2515 = fa_shadows[26].x;\n    }\n    else\n    {\n        _2515 = 1.5 * fa_shadows[ci * 1 + 20].x;\n    }\n    vec2 param = _2463.xy;\n    vec4 param_1 = fa_shadows[ci * 1 + 16];\n    float param_2 = _2463.z - ((_2515 * (1.0 + (0.5 * _2433))) / _2414);\n    float param_3 = fa_shadows[ci * 1 + 20].x;\n    float param_4 = _2414;\n    float param_5 = _2414 * 0.25;\n    float param_6 = ((fa_shadows[ci * 1 + 20].x * min(_2433, 3.0)) * 0.5) / _2414;\n    vec3 param_7 = vec3(0.0);\n    int param_8 = int(fa_shadows[25].z + 0.5);\n    float param_9 = fa_shadows[25].w;\n    return fa_shadow_filter(param, param_1, param_2, param_3, param_4, param_5, param_6, param_7, param_8, param_9);\n}\n\nfloat fa_shadow_sun(vec3 world, vec3 n, vec3 l)\n{\n    if (fa_mesh_fs_params[5].z < 0.5)\n    {\n        return 1.0;\n    }\n    int _2893 = int(fa_shadows[25].x + 0.5);\n    if (_2893 < 1)\n    {\n        return 1.0;\n    }\n    float _2908 = dot(world - fa_shadows[27].xyz, fa_shadows[28].xyz);\n    int param = _2893 - 1;\n    if (_2908 > fa_shadow_split_at(param))\n    {\n        return 1.0;\n    }\n    int ci = 0;\n    bool _2920 = _2893 > 1;\n    bool _2927;\n    if (_2920)\n    {\n        _2927 = _2908 > fa_shadows[24].x;\n    }\n    else\n    {\n        _2927 = _2920;\n    }\n    if (_2927)\n    {\n        ci = 1;\n    }\n    bool _2931 = _2893 > 2;\n    bool _2938;\n    if (_2931)\n    {\n        _2938 = _2908 > fa_shadows[24].y;\n    }\n    else\n    {\n        _2938 = _2931;\n    }\n    if (_2938)\n    {\n        ci = 2;\n    }\n    bool _2942 = _2893 > 3;\n    bool _2949;\n    if (_2942)\n    {\n        _2949 = _2908 > fa_shadows[24].z;\n    }\n    else\n    {\n        _2949 = _2942;\n    }\n    if (_2949)\n    {\n        ci = 3;\n    }\n    float s = -1.0;\n    float s2 = -1.0;\n    float t = 0.0;\n    int _2960 = min(_2893, 4);\n    float _3001;\n    for (int c = ci; c < _2960; c++)\n    {\n        int param_1 = c;\n        vec3 param_2 = world;\n        vec3 param_3 = n;\n        vec3 param_4 = l;\n        float _2980 = fa_shadow_cascade(param_1, param_2, param_3, param_4);\n        if (s >= 0.0)\n        {\n            s2 = _2980;\n            break;\n        }\n        if (_2980 < 0.0)\n        {\n            continue;\n        }\n        s = _2980;\n        ci = c;\n        if (fa_shadows[25].y > 0.0)\n        {\n            if (ci > 0)\n            {\n                int param_5 = ci - 1;\n                _3001 = fa_shadow_split_at(param_5);\n            }\n            else\n            {\n                _3001 = fa_shadows[28].w;\n            }\n            int param_6 = ci;\n            float _3020 = fa_shadows[25].y * max(fa_shadow_split_at(param_6) - _3001, 9.9999997473787516355514526367188e-05);\n            int param_7 = ci;\n            t = clamp((_2908 - (fa_shadow_split_at(param_7) - _3020)) / _3020, 0.0, 1.0);\n        }\n        if (t <= 0.0)\n        {\n            break;\n        }\n    }\n    if (s < 0.0)\n    {\n        return 1.0;\n    }\n    if (t > 0.0)\n    {\n        float _3052;\n        if ((ci + 1) < _2893)\n        {\n            _3052 = (s2 < 0.0) ? s : s2;\n        }\n        else\n        {\n            _3052 = 1.0;\n        }\n        s = mix(s, _3052, t);\n    }\n    return s;\n}\n\nfloat fa_shadow_factor(vec3 n, vec3 l)\n{\n    bool _3157 = fa_mesh_fs_params[25].y > 0.5;\n    bool _3163;\n    if (_3157)\n    {\n        _3163 = fa_mesh_fs_params[5].z > 0.5;\n    }\n    else\n    {\n        _3163 = _3157;\n    }\n    if (_3163)\n    {\n        vec4 _3173 = vec4(fa_world_pos, 1.0);\n        float _3179 = dot(fa_mesh_fs_params[28], _3173);\n        if (_3179 > 9.9999997473787516355514526367188e-05)\n        {\n            vec2 _3198 = vec2(dot(fa_mesh_fs_params[26], _3173), dot(fa_mesh_fs_params[27], _3173)) / vec2(_3179);\n            float _3203 = (_3198.x * 0.5) + 0.5;\n            float _3207;\n            if (fa_mesh_fs_params[24].y > 0.5)\n            {\n                _3207 = (_3198.y * 0.5) + 0.5;\n            }\n            else\n            {\n                _3207 = 0.5 - (_3198.y * 0.5);\n            }\n            bool _3223 = _3203 >= 0.0;\n            bool _3229;\n            if (_3223)\n            {\n                _3229 = _3203 < 1.0;\n            }\n            else\n            {\n                _3229 = _3223;\n            }\n            bool _3235;\n            if (_3229)\n            {\n                _3235 = _3207 >= 0.0;\n            }\n            else\n            {\n                _3235 = _3229;\n            }\n            bool _3241;\n            if (_3235)\n            {\n                _3241 = _3207 < 1.0;\n            }\n            else\n            {\n                _3241 = _3235;\n            }\n            if (_3241)\n            {\n                vec4 _3267 = texelFetch(fa_screen_tex_fa_shadow_smp, clamp(ivec2(vec2(_3203, _3207) * fa_mesh_fs_params[24].zw), ivec2(0), ivec2(fa_mesh_fs_params[24].zw) - ivec2(1)), 0);\n                float _3277 = dot(fa_mesh_fs_params[29].xyz, fa_world_pos) + fa_mesh_fs_params[29].w;\n                bool _3280 = _3267.w > 0.5;\n                bool _3294;\n                if (_3280)\n                {\n                    _3294 = abs(_3277 - _3267.x) <= ((0.00200000009499490261077880859375 * _3277) + 0.00999999977648258209228515625);\n                }\n                else\n                {\n                    _3294 = _3280;\n                }\n                if (_3294)\n                {\n                    return _3267.y;\n                }\n            }\n        }\n    }\n    vec3 param = fa_world_pos;\n    vec3 param_1 = n;\n    vec3 param_2 = l;\n    return fa_shadow_sun(param, param_1, param_2);\n}\n\nfloat fa_contact_shadow(int li, vec3 world, vec3 gn, vec3 l, float dist)\n{\n    bool _4573 = fa_mesh_fs_params[24].x < 0.5;\n    bool _4580;\n    if (!_4573)\n    {\n        _4580 = fa_shadows[29].x < 0.5;\n    }\n    else\n    {\n        _4580 = _4573;\n    }\n    if (_4580)\n    {\n        return 1.0;\n    }\n    int param = (int(fa_shadows[29].x + 0.5) - 1) + li;\n    vec4 _4593 = fa_light_texel(param);\n    float _4594 = _4593.y;\n    float len = _4594;\n    if (_4594 <= 0.0)\n    {\n        return 1.0;\n    }\n    float _4606 = length(world - fa_mesh_fs_params[0].xyz);\n    float _4615 = 1.0 - smoothstep(0.5 * fa_mesh_fs_params[25].x, fa_mesh_fs_params[25].x, _4606);\n    if (_4615 <= 0.0)\n    {\n        return 1.0;\n    }\n    float _4621 = len;\n    float _4624 = min(_4621, 0.89999997615814208984375 * dist);\n    len = _4624;\n    float _4629 = 0.004999999888241291046142578125 + (0.0030000000260770320892333984375 * _4606);\n    float _4634 = _4629 + (0.5 * _4624);\n    vec3 _4640 = world + (gn * _4629);\n    float _4642 = fa_shadow_noise();\n    float occ = 0.0;\n    float _4703;\n    for (int k = 0; k < 12; k++)\n    {\n        float _4657 = (float(k) + _4642) * 0.083333335816860198974609375;\n        vec3 _4665 = _4640 + (l * (_4657 * len));\n        vec4 _4671 = vec4(_4665, 1.0);\n        float _4676 = dot(fa_mesh_fs_params[28], _4671);\n        if (_4676 < 9.9999997473787516355514526367188e-05)\n        {\n            break;\n        }\n        vec2 _4694 = vec2(dot(fa_mesh_fs_params[26], _4671), dot(fa_mesh_fs_params[27], _4671)) / vec2(_4676);\n        float _4698 = _4694.x * 0.5;\n        float _4699 = _4698 + 0.5;\n        if (fa_mesh_fs_params[24].y > 0.5)\n        {\n            _4703 = (_4694.y * 0.5) + 0.5;\n        }\n        else\n        {\n            _4703 = 0.5 - (_4694.y * 0.5);\n        }\n        bool _4719 = _4699 < 0.0;\n        bool _4726;\n        if (!_4719)\n        {\n            _4726 = _4699 >= 1.0;\n        }\n        else\n        {\n            _4726 = _4719;\n        }\n        bool _4733;\n        if (!_4726)\n        {\n            _4733 = _4703 < 0.0;\n        }\n        else\n        {\n            _4733 = _4726;\n        }\n        bool _4740;\n        if (!_4733)\n        {\n            _4740 = _4703 >= 1.0;\n        }\n        else\n        {\n            _4740 = _4733;\n        }\n        if (_4740)\n        {\n            break;\n        }\n        vec4 _4764 = texelFetch(fa_screen_tex_fa_shadow_smp, clamp(ivec2(vec2(_4699, _4703) * fa_mesh_fs_params[24].zw), ivec2(0), ivec2(fa_mesh_fs_params[24].zw) - ivec2(1)), 0);\n        if (_4764.w < 0.5)\n        {\n            continue;\n        }\n        float _4782 = (dot(fa_mesh_fs_params[29].xyz, _4665) + fa_mesh_fs_params[29].w) - _4764.x;\n        if ((_4782 > _4629) && (_4782 < _4634))\n        {\n            occ = max(occ, (1.0 - (_4657 * _4657)) * smoothstep(0.0, 0.0500000007450580596923828125, min(min(_4699, 0.5 - _4698), min(_4703, 1.0 - _4703))));\n        }\n    }\n    return 1.0 - (occ * _4615);\n}\n\nLightSample fa_light_shadowed(int li, vec3 world_pos, vec3 gn)\n{\n    int param = li;\n    float _4885 = fa_baked_keep(param);\n    if (_4885 <= 0.0)\n    {\n        int param_1 = li;\n        return LightSample(vec3(0.0, 1.0, 0.0), vec3(0.0), 0.0, 1.0, 0.0, int(fa_light_type(param_1) + 0.5));\n    }\n    int param_2 = li;\n    vec3 param_3 = world_pos;\n    vec3 param_4 = gn;\n    LightSample _4911 = fa_light_sample_n(param_2, param_3, param_4);\n    vec3 _6181 = _4911.color;\n    float _6182 = _4911.attenuation;\n    float _6183 = _4911.shadow;\n    bool _4914 = _4911.type == 0;\n    if (_4914 && (li == 0))\n    {\n        vec3 param_5 = gn;\n        vec3 param_6 = _4911.direction;\n        float _4925 = fa_shadow_factor(param_5, param_6);\n        _6183 = _4925;\n        _6181 *= _4925;\n    }\n    else\n    {\n        bool _4936 = _4911.type != 0;\n        bool _4942;\n        if (_4936)\n        {\n            _4942 = _6182 > 0.0;\n        }\n        else\n        {\n            _4942 = _4936;\n        }\n        if (_4942)\n        {\n            int param_7 = li;\n            int param_8 = fa_light_base(param_7);\n            int param_9 = li;\n            vec3 param_10 = fa_light_texel(param_8).xyz;\n            vec3 param_11 = world_pos;\n            vec3 param_12 = gn;\n            vec3 param_13 = _4911.direction;\n            float _4961 = fa_shadow_local(param_9, param_10, param_11, param_12, param_13);\n            _6183 = _4961;\n            _6181 *= _4961;\n        }\n    }\n    bool _4971 = fa_mesh_fs_params[24].x > 0.5;\n    bool _4977;\n    if (_4971)\n    {\n        _4977 = _6182 > 0.0;\n    }\n    else\n    {\n        _4977 = _4971;\n    }\n    if (_4977)\n    {\n        float _4984;\n        if (_4914)\n        {\n            _4984 = 1000000000.0;\n        }\n        else\n        {\n            _4984 = _4911._distance;\n        }\n        int param_14 = li;\n        vec3 param_15 = world_pos;\n        vec3 param_16 = gn;\n        vec3 param_17 = _4911.direction;\n        float param_18 = _4984;\n        float _5002 = fa_contact_shadow(param_14, param_15, param_16, param_17, param_18);\n        _6183 *= _5002;\n        _6181 *= _5002;\n    }\n    float _5015 = _6182;\n    float _5016 = _5015 * _4885;\n    _6182 = _5016;\n    vec3 _5020 = _6181;\n    vec3 _5021 = _5020 * _4885;\n    _6181 = _5021;\n    return LightSample(_4911.direction, _5021, _5016, _6183, _4911._distance, _4911.type);\n}\n\nLightSample fa_light(int n, SurfaceInput i)\n{\n    bool _5032 = n < 0;\n    bool _5039;\n    if (!_5032)\n    {\n        _5039 = n >= fa_light_count();\n    }\n    else\n    {\n        _5039 = _5032;\n    }\n    if (_5039)\n    {\n        return fa_no_light();\n    }\n    int param = n;\n    int param_1 = fa_cl_light(param);\n    vec3 param_2 = i.world_pos;\n    vec3 param_3 = i.world_normal;\n    LightSample _5054 = fa_light_shadowed(param_1, param_2, param_3);\n    return _5054;\n}\n\nfloat fa_sheen_albedo(float ndv, float rough)\n{\n    float _3958 = min(sqrt(max(rough - 0.100000001490116119384765625, 0.0) * 1.111111164093017578125) * 6.0, 5.999000072479248046875);\n    float _3966 = min(sqrt(clamp(ndv, 0.0, 1.0)) * 8.0, 7.999000072479248046875);\n    int _3969 = int(_3958);\n    int _3972 = int(_3966);\n    float _3982 = _3966 - float(_3972);\n    int _4038 = (_3969 * 9) + _3972;\n    int _4058 = ((_3969 + 1) * 9) + _3972;\n    return mix(mix(_4033[_4038], _4033[_4038 + 1], _3982), mix(_4033[_4058], _4033[_4058 + 1], _3982), _3958 - float(_3969));\n}\n\nFaLayers fa_layers_setup(SurfaceInput i, Surface s, vec3 n, vec3 v, float metallic, float roughness, inout vec3 f0)\n{\n    bool _6047 = false;\n    float _6048 = 1.0;\n    float _6049 = 1.0;\n    float _6050 = 1.0;\n    float _6051 = 0.0;\n    float _6052 = 0.0;\n    float _6053 = 0.0;\n    float _6054 = 0.0;\n    float _6056 = 1.0;\n    bool _6057 = false;\n    vec3 _6058 = vec3(0.0);\n    float _6059 = 1.0;\n    float _6060 = 1.0;\n    float _6061 = 1.0;\n    float _6062 = 0.0;\n    float _6063 = 0.0;\n    vec3 _6064 = vec3(1.0, 0.0, 0.0);\n    vec3 _6065 = vec3(0.0, 0.0, 1.0);\n    float _6066 = 1.0;\n    float _6067 = 1.0;\n    float _4109 = clamp(s.specular, 0.0, 1.0);\n    float _4113 = clamp(s.ior, 1.0, 3.0);\n    bool _4118 = (_4109 != 1.0) || (_4113 != 1.5);\n    bool _4127;\n    if (!_4118)\n    {\n        _4127 = any(notEqual(s.specular_color, vec3(1.0)));\n    }\n    else\n    {\n        _4127 = _4118;\n    }\n    if (_4127)\n    {\n        float _4135 = (_4113 - 1.0) / (_4113 + 1.0);\n        f0 = mix(min(vec3(_4135 * _4135) * max(s.specular_color, vec3(0.0)), vec3(1.0)) * _4109, s.albedo, vec3(metallic));\n        _6048 = mix(_4109, 1.0, metallic);\n        _6047 = true;\n    }\n    float _4162 = clamp(s.clearcoat, 0.0, 1.0);\n    if (_4162 > 0.0)\n    {\n        float _4170 = clamp(s.clearcoat_roughness, 0.0500000007450580596923828125, 1.0);\n        _6051 = _4162;\n        _6052 = _4170;\n        float _4177 = _4170 * _4170;\n        _6053 = _4177;\n        _6054 = _4177 * _4177;\n        float _4189 = max(dot(i.world_normal, v), 9.9999997473787516355514526367188e-05);\n        _6056 = _4189;\n        _6049 = 1.0 - (_4162 * (0.039999999105930328369140625 + (0.959999978542327880859375 * pow(clamp(1.0 - _4189, 0.0, 1.0), 5.0))));\n        _6047 = true;\n    }\n    vec3 _4208 = max(s.sheen_color, vec3(0.0));\n    float _4217 = max(_4208.x, max(_4208.y, _4208.z));\n    if (_4217 > 0.0)\n    {\n        float _4225 = clamp(s.sheen_roughness, 0.100000001490116119384765625, 1.0);\n        _6057 = true;\n        _6058 = _4208;\n        _6059 = _4225;\n        _6060 = _4225 * _4225;\n        float param = max(dot(n, v), 9.9999997473787516355514526367188e-05);\n        float param_1 = _4225;\n        float _4242 = fa_sheen_albedo(param, param_1);\n        _6062 = _4242;\n        _6061 = 1.0 - min(_4217 * _4242, 1.0);\n        _6047 = true;\n    }\n    _6050 = _6049 * _6061;\n    float _4261 = clamp(s.anisotropy, -1.0, 1.0);\n    if (_4261 != 0.0)\n    {\n        vec3 _4276 = i.world_tangent.xyz - (n * dot(n, i.world_tangent.xyz));\n        vec3 t = _4276;\n        if (dot(_4276, _4276) < 9.9999999392252902907785028219223e-09)\n        {\n            bvec3 _4288 = bvec3(abs(n.y) < 0.9900000095367431640625);\n            t = cross(vec3(_4288.x ? vec3(0.0, 1.0, 0.0).x : vec3(1.0, 0.0, 0.0).x, _4288.y ? vec3(0.0, 1.0, 0.0).y : vec3(1.0, 0.0, 0.0).y, _4288.z ? vec3(0.0, 1.0, 0.0).z : vec3(1.0, 0.0, 0.0).z), n);\n        }\n        vec3 _4292 = t;\n        vec3 _4293 = normalize(_4292);\n        t = _4293;\n        vec3 _4318 = normalize((_4293 * cos(s.anisotropy_rotation)) + ((cross(n, _4293) * ((i.world_tangent.w < 0.0) ? (-1.0) : 1.0)) * sin(s.anisotropy_rotation)));\n        _6064 = _4318;\n        _6065 = cross(n, _4318);\n        float _4328 = roughness * roughness;\n        float _4334 = mix(_4328, 1.0, _4261 * _4261);\n        bool _4336 = _4261 > 0.0;\n        _6066 = _4336 ? _4334 : _4328;\n        _6067 = _4336 ? _4328 : _4334;\n        _6063 = _4261;\n        _6047 = true;\n    }\n    return FaLayers(_6047, _6048, _6049, _6050, _6051, _6052, _6053, _6054, i.world_normal, _6056, _6057, _6058, _6059, _6060, _6061, _6062, _6063, _6064, _6065, _6066, _6067);\n}\n\nvec2 fa_env_brdf(float rough, float ndv)\n{\n    vec4 _3890 = (vec4(-1.0, -0.0274999998509883880615234375, -0.572000026702880859375, 0.02199999988079071044921875) * rough) + vec4(1.0, 0.0425000004470348358154296875, 1.03999996185302734375, -0.039999999105930328369140625);\n    float _3893 = _3890.x;\n    return (vec2(-1.03999996185302734375, 1.03999996185302734375) * ((min(_3893 * _3893, exp2((-9.27999973297119140625) * ndv)) * _3893) + _3890.y)) + _3890.zw;\n}\n\nvec2 fa_oct_encode(vec3 d)\n{\n    vec3 _3326 = d / vec3(max((abs(d.x) + abs(d.y)) + abs(d.z), 9.9999999600419720025001879548654e-13));\n    float _3329 = _3326.x;\n    float _3331 = _3326.z;\n    vec2 e = vec2(_3329, _3331);\n    if (_3326.y < 0.0)\n    {\n        e = vec2((1.0 - abs(_3331)) * ((_3329 < 0.0) ? (-1.0) : 1.0), (1.0 - abs(_3329)) * ((_3331 < 0.0) ? (-1.0) : 1.0));\n    }\n    return e;\n}\n\nvec2 fa_atlas_size()\n{\n    return vec2(textureSize(fa_probe_atlas_fa_env_smp, 0));\n}\n\nvec3 fa_probe_level(vec2 origin, float res, int lv, vec2 e)\n{\n    float _3378;\n    if (lv == 0)\n    {\n        _3378 = 0.0;\n    }\n    else\n    {\n        _3378 = res + 2.0;\n    }\n    float _3388;\n    if (lv == 0)\n    {\n        _3388 = 0.0;\n    }\n    else\n    {\n        _3388 = (res - (res / float(1 << max((lv - 1), 0)))) + (2.0 * float(lv - 1));\n    }\n    return textureLod(fa_probe_atlas_fa_env_smp, (((origin + vec2(_3378, _3388)) + vec2(1.0)) + (((e * 0.5) + vec2(0.5)) * (res / float(1 << lv)))) / fa_atlas_size(), 0.0).xyz;\n}\n\nvec3 fa_probe_radiance(vec2 origin, float res, vec3 d, float rough)\n{\n    float _3434;\n    if (res > 64.5)\n    {\n        _3434 = 5.0;\n    }\n    else\n    {\n        _3434 = (res > 32.5) ? 4.0 : 3.0;\n    }\n    float _3449 = clamp(rough, 0.0, 1.0) * (_3434 - 1.0);\n    int _3456 = int(min(floor(_3449), _3434 - 2.0));\n    float _3461 = _3449 - float(_3456);\n    vec3 param = d;\n    vec2 _3465 = fa_oct_encode(param);\n    vec2 param_1 = origin;\n    float param_2 = res;\n    int param_3 = _3456;\n    vec2 param_4 = _3465;\n    vec3 _3475 = fa_probe_level(param_1, param_2, param_3, param_4);\n    if (_3461 < 0.00200000009499490261077880859375)\n    {\n        return _3475;\n    }\n    vec2 param_5 = origin;\n    float param_6 = res;\n    int param_7 = _3456 + 1;\n    vec2 param_8 = _3465;\n    return mix(_3475, fa_probe_level(param_5, param_6, param_7, param_8), vec3(_3461));\n}\n\nvec3 fa_probe_box_dir(vec3 d, vec4 posw, vec4 bx, vec4 by, vec4 bz)\n{\n    if (posw.w < 0.5)\n    {\n        return d;\n    }\n    float _3512 = dot(bx.xyz, fa_world_pos) + bx.w;\n    float _3519 = dot(by.xyz, fa_world_pos) + by.w;\n    float _3526 = dot(bz.xyz, fa_world_pos) + bz.w;\n    float _3532 = dot(bx.xyz, d);\n    float _3536 = dot(by.xyz, d);\n    float _3540 = dot(bz.xyz, d);\n    float _3546;\n    if (_3532 > 9.9999999747524270787835121154785e-07)\n    {\n        _3546 = (1.0 - _3512) / _3532;\n    }\n    else\n    {\n        float _3560;\n        if (_3532 < (-9.9999999747524270787835121154785e-07))\n        {\n            _3560 = ((-1.0) - _3512) / _3532;\n        }\n        else\n        {\n            _3560 = 1000000015047466219876688855040.0;\n        }\n        _3546 = _3560;\n    }\n    float tx = _3546;\n    float _3577;\n    if (_3536 > 9.9999999747524270787835121154785e-07)\n    {\n        _3577 = (1.0 - _3519) / _3536;\n    }\n    else\n    {\n        float _3590;\n        if (_3536 < (-9.9999999747524270787835121154785e-07))\n        {\n            _3590 = ((-1.0) - _3519) / _3536;\n        }\n        else\n        {\n            _3590 = 1000000015047466219876688855040.0;\n        }\n        _3577 = _3590;\n    }\n    float ty = _3577;\n    float _3606;\n    if (_3540 > 9.9999999747524270787835121154785e-07)\n    {\n        _3606 = (1.0 - _3526) / _3540;\n    }\n    else\n    {\n        float _3619;\n        if (_3540 < (-9.9999999747524270787835121154785e-07))\n        {\n            _3619 = ((-1.0) - _3526) / _3540;\n        }\n        else\n        {\n            _3619 = 1000000015047466219876688855040.0;\n        }\n        _3606 = _3619;\n    }\n    float _3631 = tx;\n    float _3634 = (_3631 > 0.0) ? _3631 : 1000000015047466219876688855040.0;\n    tx = _3634;\n    float _3635 = ty;\n    float _3638 = (_3635 > 0.0) ? _3635 : 1000000015047466219876688855040.0;\n    ty = _3638;\n    float _3648 = min(_3634, min(_3638, (_3606 > 0.0) ? _3606 : 1000000015047466219876688855040.0));\n    if (_3648 > 100000001504746621987668885504.0)\n    {\n        return d;\n    }\n    vec3 _3664 = (fa_world_pos + (d * _3648)) - posw.xyz;\n    vec3 _3669;\n    if (dot(_3664, _3664) > 1.0000000133514319600180897396058e-10)\n    {\n        _3669 = normalize(_3664);\n    }\n    else\n    {\n        _3669 = d;\n    }\n    return _3669;\n}\n\nvec3 fa_probe_environment(vec4 tile, vec4 posw, vec4 bx, vec4 by, vec4 bz, inout vec3 d, float rough)\n{\n    vec3 param = d;\n    vec4 param_1 = posw;\n    vec4 param_2 = bx;\n    vec4 param_3 = by;\n    vec4 param_4 = bz;\n    d = fa_probe_box_dir(param, param_1, param_2, param_3, param_4);\n    vec2 param_5 = tile.xy;\n    float param_6 = tile.z;\n    vec3 param_7 = d;\n    float param_8 = rough;\n    return fa_probe_radiance(param_5, param_6, param_7, param_8);\n}\n\nvec3 fa_environment(vec3 d, float rough)\n{\n    float _3715 = (1.0 - fa_mesh_fs_params[42].w) - fa_mesh_fs_params[47].w;\n    vec3 outc = vec3(0.0);\n    if (_3715 > 0.0005000000237487256526947021484375)\n    {\n        vec3 base;\n        if (fa_mesh_fs_params[11].w > 0.5)\n        {\n            vec2 param = fa_mesh_fs_params[41].zw;\n            float param_1 = 128.0;\n            vec3 param_2 = d;\n            float param_3 = rough;\n            base = fa_probe_radiance(param, param_1, param_2, param_3);\n        }\n        else\n        {\n            float _3745 = rough * rough;\n            float _3776 = 0.60000002384185791015625 * _3745;\n            base = mix(mix(fa_mesh_fs_params[12].xyz * 0.550000011920928955078125, mix(fa_mesh_fs_params[12].xyz, fa_mesh_fs_params[11].xyz, vec3(pow(clamp(d.y * (1.0 - (0.699999988079071044921875 * _3745)), 0.0, 1.0), 0.550000011920928955078125))), vec3(smoothstep((-0.0500000007450580596923828125) - _3776, 0.0500000007450580596923828125 + _3776, d.y))), ((fa_mesh_fs_params[11].xyz + fa_mesh_fs_params[12].xyz) * 0.5) * 0.800000011920928955078125, vec3(_3745 * 0.60000002384185791015625));\n        }\n        outc = base * _3715;\n    }\n    if (fa_mesh_fs_params[42].w > 0.0)\n    {\n        vec4 param_4 = fa_mesh_fs_params[42];\n        vec4 param_5 = fa_mesh_fs_params[43];\n        vec4 param_6 = fa_mesh_fs_params[44];\n        vec4 param_7 = fa_mesh_fs_params[45];\n        vec4 param_8 = fa_mesh_fs_params[46];\n        vec3 param_9 = d;\n        float param_10 = rough;\n        vec3 _3835 = fa_probe_environment(param_4, param_5, param_6, param_7, param_8, param_9, param_10);\n        outc += (_3835 * fa_mesh_fs_params[42].w);\n    }\n    if (fa_mesh_fs_params[47].w > 0.0)\n    {\n        vec4 param_11 = fa_mesh_fs_params[47];\n        vec4 param_12 = fa_mesh_fs_params[48];\n        vec4 param_13 = fa_mesh_fs_params[49];\n        vec4 param_14 = fa_mesh_fs_params[50];\n        vec4 param_15 = fa_mesh_fs_params[51];\n        vec3 param_16 = d;\n        float param_17 = rough;\n        vec3 _3867 = fa_probe_environment(param_11, param_12, param_13, param_14, param_15, param_16, param_17);\n        outc += (_3867 * fa_mesh_fs_params[47].w);\n    }\n    return outc;\n}\n\nvec3 fa_layers_ibl(FaLayers L, vec3 n, vec3 v, vec3 f0, float roughness, float occlusion)\n{\n    vec3 rn = n;\n    if (L.aniso != 0.0)\n    {\n        vec3 _4369;\n        if (L.aniso >= 0.0)\n        {\n            _4369 = L.b;\n        }\n        else\n        {\n            _4369 = L.t;\n        }\n        rn = normalize(mix(n, cross(cross(_4369, v), _4369), vec3(abs(L.aniso) * smoothstep(0.0, 0.25, roughness))));\n    }\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05);\n    vec2 _4405 = fa_env_brdf(param, param_1);\n    vec3 param_2 = reflect(-v, rn);\n    float param_3 = roughness;\n    vec3 result = (fa_environment(param_2, param_3) * ((f0 * _4405.x) + (vec3(L.f90) * _4405.y))) * L.base_scale;\n    if (L.sheen_on)\n    {\n        vec3 param_4 = n;\n        float param_5 = L.sheen_rough;\n        result += ((L.sheen * (L.sheen_e * L.keep)) * fa_environment(param_4, param_5));\n    }\n    result *= occlusion;\n    if (L.coat > 0.0)\n    {\n        float param_6 = L.coat_rough;\n        float param_7 = L.coat_ndv;\n        vec2 _4463 = fa_env_brdf(param_6, param_7);\n        vec3 param_8 = reflect(-v, L.nc);\n        float param_9 = L.coat_rough;\n        result += (fa_environment(param_8, param_9) * (L.coat * ((0.039999999105930328369140625 * _4463.x) + _4463.y)));\n    }\n    return result;\n}\n\nvec3 fa_sky_reflection(vec3 n, vec3 v, vec3 f0, float roughness)\n{\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05);\n    vec2 _3932 = fa_env_brdf(param, param_1);\n    vec3 param_2 = reflect(-v, n);\n    float param_3 = roughness;\n    return fa_environment(param_2, param_3) * ((f0 * _3932.x) + vec3(_3932.y));\n}\n\nvec3 fa_sky_light(SurfaceInput i, Surface s)\n{\n    float _4502 = clamp(s.metallic, 0.0, 1.0);\n    float _4506 = clamp(s.roughness, 0.0500000007450580596923828125, 1.0);\n    vec3 _4513 = mix(vec3(0.039999999105930328369140625), s.albedo, vec3(_4502));\n    vec3 f0 = _4513;\n    vec3 _4517 = normalize(s.normal);\n    SurfaceInput param = i;\n    Surface param_1 = s;\n    vec3 param_2 = _4517;\n    vec3 param_3 = i.view_dir;\n    float param_4 = _4502;\n    float param_5 = _4506;\n    vec3 param_6 = _4513;\n    FaLayers _4534 = fa_layers_setup(param, param_1, param_2, param_3, param_4, param_5, param_6);\n    f0 = param_6;\n    if (_4534.on)\n    {\n        FaLayers param_7 = _4534;\n        vec3 param_8 = _4517;\n        vec3 param_9 = i.view_dir;\n        vec3 param_10 = f0;\n        float param_11 = _4506;\n        float param_12 = s.occlusion;\n        return fa_layers_ibl(param_7, param_8, param_9, param_10, param_11, param_12);\n    }\n    vec3 param_13 = _4517;\n    vec3 param_14 = i.view_dir;\n    vec3 param_15 = f0;\n    float param_16 = _4506;\n    return fa_sky_reflection(param_13, param_14, param_15, param_16) * s.occlusion;\n}\n\nvec3 lighting(SurfaceInput i, Surface s)\n{\n    int best = -1;\n    float bestPower = 0.0;\n    for (int n = 0; n < fa_light_count(); n++)\n    {\n        int param = n;\n        SurfaceInput param_1 = i;\n        LightSample _5124 = fa_light_unshadowed(param, param_1);\n        float _5132 = dot(_5124.color, vec3(0.2989999949932098388671875, 0.58700001239776611328125, 0.114000000059604644775390625));\n        if (_5132 > bestPower)\n        {\n            bestPower = _5132;\n            best = n;\n        }\n    }\n    vec3 lit = (fa_mesh_fs_params[1].xyz * s.albedo) * s.occlusion;\n    if (best >= 0)\n    {\n        int param_2 = best;\n        SurfaceInput param_3 = i;\n        LightSample _5161 = fa_light(param_2, param_3);\n        float _5169;\n        if (dot(s.normal, _5161.direction) > 0.5)\n        {\n            _5169 = 1.0;\n        }\n        else\n        {\n            _5169 = fa_material[0].x;\n        }\n        lit += ((s.albedo * _5161.color) * _5169);\n    }\n    SurfaceInput param_4 = i;\n    Surface param_5 = s;\n    return lit + (fa_sky_light(param_4, param_5) * fa_material[1].x);\n}\n\nvec3 fa_shadow_debug(vec3 color, vec3 world)\n{\n    if (fa_shadows[27].w < 0.5)\n    {\n        return color;\n    }\n    int _3080 = int(fa_shadows[25].x + 0.5);\n    float _3090 = dot(world - fa_shadows[27].xyz, fa_shadows[28].xyz);\n    vec3 tint = vec3(0.3499999940395355224609375);\n    bool _3095 = _3080 > 0;\n    bool _3104;\n    if (_3095)\n    {\n        int param = _3080 - 1;\n        _3104 = _3090 <= fa_shadow_split_at(param);\n    }\n    else\n    {\n        _3104 = _3095;\n    }\n    if (_3104)\n    {\n        tint = vec3(1.0, 0.1500000059604644775390625, 0.100000001490116119384765625);\n        bool _3110 = _3080 > 1;\n        bool _3117;\n        if (_3110)\n        {\n            _3117 = _3090 > fa_shadows[24].x;\n        }\n        else\n        {\n            _3117 = _3110;\n        }\n        if (_3117)\n        {\n            tint = vec3(0.100000001490116119384765625, 0.89999997615814208984375, 0.20000000298023223876953125);\n        }\n        bool _3123 = _3080 > 2;\n        bool _3130;\n        if (_3123)\n        {\n            _3130 = _3090 > fa_shadows[24].y;\n        }\n        else\n        {\n            _3130 = _3123;\n        }\n        if (_3130)\n        {\n            tint = vec3(0.1500000059604644775390625, 0.300000011920928955078125, 1.0);\n        }\n        bool _3136 = _3080 > 3;\n        bool _3143;\n        if (_3136)\n        {\n            _3143 = _3090 > fa_shadows[24].z;\n        }\n        else\n        {\n            _3143 = _3136;\n        }\n        if (_3143)\n        {\n            tint = vec3(1.0, 0.89999997615814208984375, 0.100000001490116119384765625);\n        }\n    }\n    return mix(color, tint, vec3(0.550000011920928955078125));\n}\n\nvoid main()\n{\n    fa_inst_load();\n    vec3 _5901 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _5901 = -_5901;\n    }\n    vec3 _5571 = normalize(fa_mesh_fs_params[0].xyz - fa_world_pos);\n    vec3 param = fa_world_pos;\n    fa_cluster_begin(param);\n    SurfaceInput param_1 = SurfaceInput(fa_world_pos, _5901, fa_world_tangent, fa_uv, fa_vertex_color, _5571, gl_FrontFacing);\n    Surface _5579 = fa_standard_surface(param_1);\n    vec3 _5932 = _5579.albedo;\n    float _5933 = _5579.alpha;\n    vec3 _5934 = _5579.normal;\n    float _5935 = _5579.metallic;\n    float _5936 = _5579.roughness;\n    float _5937 = _5579.occlusion;\n    vec3 _5938 = _5579.emission;\n    float _5939 = _5579.clearcoat;\n    float _5940 = _5579.clearcoat_roughness;\n    vec3 _5941 = _5579.sheen_color;\n    float _5942 = _5579.sheen_roughness;\n    float _5943 = _5579.anisotropy;\n    float _5944 = _5579.anisotropy_rotation;\n    float _5945 = _5579.specular;\n    float _5946 = _5579.ior;\n    vec3 _5947 = _5579.specular_color;\n    float _5948 = _5579.transmission;\n    float _5949 = _5579.thickness;\n    vec3 _5950 = _5579.attenuation_color;\n    float _5951 = _5579.attenuation_distance;\n    SurfaceInput param_2 = SurfaceInput(fa_world_pos, _5901, fa_world_tangent, fa_uv, fa_vertex_color, _5571, gl_FrontFacing);\n    Surface param_3 = _5579;\n    surface(param_2, param_3);\n    _5932 = param_3.albedo;\n    _5933 = param_3.alpha;\n    _5934 = param_3.normal;\n    _5935 = param_3.metallic;\n    _5936 = param_3.roughness;\n    _5937 = param_3.occlusion;\n    _5938 = param_3.emission;\n    _5939 = param_3.clearcoat;\n    _5940 = param_3.clearcoat_roughness;\n    _5941 = param_3.sheen_color;\n    _5942 = param_3.sheen_roughness;\n    _5943 = param_3.anisotropy;\n    _5944 = param_3.anisotropy_rotation;\n    _5945 = param_3.specular;\n    _5946 = param_3.ior;\n    _5947 = param_3.specular_color;\n    _5948 = param_3.transmission;\n    _5949 = param_3.thickness;\n    _5950 = param_3.attenuation_color;\n    _5951 = param_3.attenuation_distance;\n    vec3 param_4 = fa_world_pos;\n    vec3 param_5 = _5901;\n    vec3 param_6 = param_3.albedo;\n    vec3 param_7 = param_3.normal;\n    fa_apply_decals(param_4, param_5, param_6, param_7);\n    _5932 = param_6;\n    _5934 = param_7;\n    vec3 result;\n    if (fa_mesh_fs_params[3].w > 0.5)\n    {\n        result = _5932;\n    }\n    else\n    {\n        vec3 _5618 = _5934;\n        vec3 _5619 = normalize(_5618);\n        _5934 = _5619;\n        SurfaceInput param_8 = SurfaceInput(fa_world_pos, _5901, fa_world_tangent, fa_uv, fa_vertex_color, _5571, gl_FrontFacing);\n        Surface param_9 = Surface(_5932, _5933, _5619, _5935, _5936, _5937, _5938, _5939, _5940, _5941, _5942, _5943, _5944, _5945, _5946, _5947, _5948, _5949, _5950, _5951);\n        vec3 _5630 = lighting(param_8, param_9);\n        result = _5630;\n    }\n    vec3 _5634 = result;\n    vec3 _5635 = _5634 + _5938;\n    result = _5635;\n    vec3 param_10 = _5635;\n    vec3 param_11 = fa_world_pos;\n    result = fa_shadow_debug(param_10, param_11);\n    bool _5644 = fa_mesh_fs_params[7].w > 0.0;\n    bool _5651;\n    if (!_5644)\n    {\n        _5651 = fa_mesh_fs_params[8].y > 0.0;\n    }\n    else\n    {\n        _5651 = _5644;\n    }\n    if (_5651)\n    {\n        vec3 _5660 = fa_world_pos - fa_mesh_fs_params[0].xyz;\n        float _5666 = dot(_5660, fa_mesh_fs_params[9].xyz);\n        bool _5670 = fa_mesh_fs_params[9].w > 0.5;\n        float _5671;\n        if (_5670)\n        {\n            _5671 = _5666;\n        }\n        else\n        {\n            _5671 = length(_5660);\n        }\n        float _5683 = _5671 - fa_mesh_fs_params[8].x;\n        if (_5683 > 0.0)\n        {\n            float _5692 = fa_mesh_fs_params[7].w * _5683;\n            float tau = _5692 * _5692;\n            if (fa_mesh_fs_params[8].y > 0.0)\n            {\n                float _5708;\n                if (_5670)\n                {\n                    _5708 = fa_world_pos.y - (fa_mesh_fs_params[9].y * _5666);\n                }\n                else\n                {\n                    _5708 = fa_mesh_fs_params[0].y;\n                }\n                float _5729 = mix(_5708, fa_world_pos.y, clamp(fa_mesh_fs_params[8].x / _5671, 0.0, 1.0));\n                float _5733 = fa_world_pos.y - _5729;\n                float _5738 = _5729 - fa_mesh_fs_params[8].z;\n                float _5743 = fa_world_pos.y - fa_mesh_fs_params[8].z;\n                bool _5746 = _5738 <= 0.0;\n                bool _5747 = !_5746;\n                bool _5753;\n                if (_5747)\n                {\n                    _5753 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _5753 = _5746;\n                }\n                float _5754;\n                if (_5753)\n                {\n                    _5754 = fa_mesh_fs_params[8].y;\n                }\n                else\n                {\n                    _5754 = fa_mesh_fs_params[8].y * exp(-min(fa_mesh_fs_params[8].w * _5738, 80.0));\n                }\n                bool _5781;\n                if (_5747)\n                {\n                    _5781 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _5781 = _5746;\n                }\n                float _5782;\n                if (_5781)\n                {\n                    _5782 = fa_mesh_fs_params[8].y * _5738;\n                }\n                else\n                {\n                    _5782 = (fa_mesh_fs_params[8].y * (1.0 - exp(-min(fa_mesh_fs_params[8].w * _5738, 80.0)))) / fa_mesh_fs_params[8].w;\n                }\n                bool _5807 = _5743 <= 0.0;\n                bool _5814;\n                if (!_5807)\n                {\n                    _5814 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _5814 = _5807;\n                }\n                float _5815;\n                if (_5814)\n                {\n                    _5815 = fa_mesh_fs_params[8].y * _5743;\n                }\n                else\n                {\n                    _5815 = (fa_mesh_fs_params[8].y * (1.0 - exp(-min(fa_mesh_fs_params[8].w * _5743, 80.0)))) / fa_mesh_fs_params[8].w;\n                }\n                float _5842;\n                if (abs(_5733) < 0.001000000047497451305389404296875)\n                {\n                    _5842 = _5754;\n                }\n                else\n                {\n                    _5842 = (_5815 - _5782) / _5733;\n                }\n                tau += (_5683 * max(_5842, 0.0));\n            }\n            result = mix(result, fa_mesh_fs_params[7].xyz, vec3(clamp(1.0 - exp(-clamp(tau, 0.0, 80.0)), 0.0, 1.0)));\n        }\n    }\n    fa_frag_color = vec4(result, _5933);\n}\n\n",
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
            "inst_name": "_5175",
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
      "vs": "#version 430\n\nstruct VertexData\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 color;\n    vec3 object_pos;\n};\n\nuniform vec4 fa_mesh_vs_params[11];\nuniform vec4 fa_skin[192];\nlayout(location = 0) out vec3 fa_world_pos;\nlayout(location = 1) out vec3 fa_world_normal;\nlayout(location = 2) out vec4 fa_world_tangent;\nlayout(location = 3) out vec2 fa_uv;\nlayout(location = 4) out vec4 fa_vertex_color;\nlayout(location = 5) in vec4 fa_inst_m0;\nlayout(location = 6) in vec4 fa_inst_m1;\nlayout(location = 7) in vec4 fa_inst_m2;\nlayout(location = 8) in vec4 fa_inst_m3;\nlayout(location = 9) in vec4 fa_joints;\nlayout(location = 10) in vec4 fa_weights;\nlayout(location = 0) in vec3 fa_position;\nlayout(location = 1) in vec3 fa_normal;\nlayout(location = 3) in vec4 fa_tangent;\nlayout(location = 2) in vec2 fa_texcoord0;\nlayout(location = 4) in vec4 fa_color;\nlayout(location = 5) out vec3 fa_lm;\n\nvoid fa_inst_begin()\n{\n}\n\nmat4 fa_skin_matrix(vec4 joints, vec4 weights)\n{\n    vec4 r0 = vec4(0.0);\n    vec4 r1 = vec4(0.0);\n    vec4 r2 = vec4(0.0);\n    for (int i = 0; i < 4; i++)\n    {\n        int _174 = int((joints[i] * 255.0) + 0.5) * 3;\n        r0 += (fa_skin[_174 * 1 + 0] * weights[i]);\n        r1 += (fa_skin[(_174 + 1) * 1 + 0] * weights[i]);\n        r2 += (fa_skin[(_174 + 2) * 1 + 0] * weights[i]);\n    }\n    return mat4(vec4(r0.x, r1.x, r2.x, 0.0), vec4(r0.y, r1.y, r2.y, 0.0), vec4(r0.z, r1.z, r2.z, 0.0), vec4(r0.w, r1.w, r2.w, 1.0));\n}\n\nVertexData fa_vertex_data(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    vec3 _74 = cross(model[1].xyz, model[2].xyz);\n    float _80 = (dot(model[0].xyz, _74) < 0.0) ? (-1.0) : 1.0;\n    return VertexData((model * vec4(position, 1.0)).xyz, (((_74 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _80, vec4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _80), texcoord0 * fa_mesh_vs_params[8].xy, color, position);\n}\n\nvoid fa_shade_vertex(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    mat4 param = model;\n    vec3 param_1 = position;\n    vec3 param_2 = normal;\n    vec4 param_3 = tangent;\n    vec2 param_4 = texcoord0;\n    vec4 param_5 = color;\n    VertexData _273 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    vec3 _391 = _273.world_pos;\n    fa_world_pos = _391;\n    fa_world_normal = _273.world_normal;\n    fa_world_tangent = _273.world_tangent;\n    fa_uv = _273.uv;\n    fa_vertex_color = _273.color;\n    gl_Position = mat4(fa_mesh_vs_params[0], fa_mesh_vs_params[1], fa_mesh_vs_params[2], fa_mesh_vs_params[3]) * vec4(_391, 1.0);\n}\n\nvoid main()\n{\n    fa_inst_begin();\n    vec4 param = fa_joints;\n    vec4 param_1 = fa_weights;\n    mat4 param_2 = mat4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3) * fa_skin_matrix(param, param_1);\n    vec3 param_3 = fa_position;\n    vec3 param_4 = fa_normal;\n    vec4 param_5 = fa_tangent;\n    vec2 param_6 = fa_texcoord0;\n    vec4 param_7 = fa_color;\n    fa_shade_vertex(param_2, param_3, param_4, param_5, param_6, param_7);\n    fa_lm = vec3(0.0);\n}\n\n",
      "fs": "#version 430\n\nstruct SurfaceInput\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 vertex_color;\n    vec3 view_dir;\n    bool front_facing;\n};\n\nstruct LightSample\n{\n    vec3 direction;\n    vec3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct Surface\n{\n    vec3 albedo;\n    float alpha;\n    vec3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    vec3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    vec3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    vec3 specular_color;\n    float transmission;\n    float thickness;\n    vec3 attenuation_color;\n    float attenuation_distance;\n};\n\nstruct FaLayers\n{\n    bool on;\n    float f90;\n    float keep;\n    float base_scale;\n    float coat;\n    float coat_rough;\n    float coat_alpha;\n    float coat_a2;\n    vec3 nc;\n    float coat_ndv;\n    bool sheen_on;\n    vec3 sheen;\n    float sheen_rough;\n    float sheen_alpha;\n    float sheen_scale;\n    float sheen_e;\n    float aniso;\n    vec3 t;\n    vec3 b;\n    float at;\n    float ab;\n};\n\nconst float _4033[63] = float[](1.0, 1.0, 1.0, 0.4790000021457672119140625, 0.11699999868869781494140625, 0.01200000010430812835693359375, 0.0, 0.0, 0.0, 1.0, 1.0, 1.0, 0.578000009059906005859375, 0.19300000369548797607421875, 0.0350000001490116119384765625, 0.0030000000260770320892333984375, 0.0, 0.0, 1.0, 1.0, 1.0, 0.6740000247955322265625, 0.3459999859333038330078125, 0.1319999992847442626953125, 0.032999999821186065673828125, 0.0040000001899898052215576171875, 0.0, 0.971000015735626220703125, 0.954999983310699462890625, 0.828999996185302734375, 0.63999998569488525390625, 0.42599999904632568359375, 0.24500000476837158203125, 0.115000002086162567138671875, 0.037000000476837158203125, 0.0030000000260770320892333984375, 0.7469999790191650390625, 0.737999975681304931640625, 0.670000016689300537109375, 0.563000023365020751953125, 0.4309999942779541015625, 0.3039999902248382568359375, 0.1940000057220458984375, 0.1019999980926513671875, 0.0309999994933605194091796875, 0.614000022411346435546875, 0.609000027179718017578125, 0.566999971866607666015625, 0.499000012874603271484375, 0.412000000476837158203125, 0.32400000095367431640625, 0.240999996662139892578125, 0.162000000476837158203125, 0.087999999523162841796875, 0.538999974727630615234375, 0.535000026226043701171875, 0.505999982357025146484375, 0.4569999873638153076171875, 0.393999993801116943359375, 0.328999996185302734375, 0.2660000026226043701171875, 0.203999996185302734375, 0.14200000464916229248046875);\n\nuniform vec4 fa_mesh_fs_params[53];\nuniform vec4 fa_shadows[30];\nuniform vec4 fa_material[2];\nlayout(binding = 0) uniform sampler2D fa_light_tex_fa_shadow_smp;\nlayout(binding = 1) uniform sampler2D fa_tex_fa_smp;\nlayout(binding = 2) uniform sampler2D fa_normal_tex_fa_smp;\nlayout(binding = 3) uniform sampler2D fa_mr_tex_fa_smp;\nlayout(binding = 4) uniform sampler2D fa_occlusion_tex_fa_smp;\nlayout(binding = 5) uniform sampler2D fa_emissive_tex_fa_smp;\nlayout(binding = 6) uniform sampler2D fa_decal_tex_fa_env_smp;\nlayout(binding = 7) uniform sampler2D fa_light_atlas_fa_env_smp;\nlayout(binding = 8) uniform sampler2D fa_shadow_tex_fa_shadow_smp;\nlayout(binding = 9) uniform sampler2D fa_screen_tex_fa_shadow_smp;\nlayout(binding = 10) uniform sampler2D fa_probe_atlas_fa_env_smp;\n\nlayout(location = 0) in vec3 fa_world_pos;\nlayout(location = 5) in vec3 fa_lm;\nlayout(location = 1) in vec3 fa_world_normal;\nlayout(location = 2) in vec4 fa_world_tangent;\nlayout(location = 3) in vec2 fa_uv;\nlayout(location = 4) in vec4 fa_vertex_color;\nlayout(location = 0) out vec4 fa_frag_color;\nvec3 fa_light_tint;\nbool fa_light_is_area;\nint fa_cl_ndir;\nint fa_cl_slot;\nint fa_cl_local;\n\nvoid fa_inst_load()\n{\n}\n\nvec4 fa_light_texel(int t)\n{\n    return texelFetch(fa_light_tex_fa_shadow_smp, ivec2(t & 1023, t >> 10), 0);\n}\n\nvec4 fa_cluster_texel(vec3 world_pos)\n{\n    bool _1397 = fa_mesh_fs_params[19].x < 0.0;\n    bool _1404;\n    if (!_1397)\n    {\n        _1404 = fa_mesh_fs_params[19].w < 1.0;\n    }\n    else\n    {\n        _1404 = _1397;\n    }\n    bool _1412;\n    if (!_1404)\n    {\n        _1412 = fa_mesh_fs_params[18].x < 1.0;\n    }\n    else\n    {\n        _1412 = _1404;\n    }\n    bool _1419;\n    if (!_1412)\n    {\n        _1419 = fa_mesh_fs_params[18].y < 1.0;\n    }\n    else\n    {\n        _1419 = _1412;\n    }\n    bool _1426;\n    if (!_1419)\n    {\n        _1426 = fa_mesh_fs_params[19].y < 1.0;\n    }\n    else\n    {\n        _1426 = _1419;\n    }\n    if (_1426)\n    {\n        return vec4(0.0);\n    }\n    vec4 _1436 = vec4(world_pos, 1.0);\n    float _1442 = dot(fa_mesh_fs_params[16], _1436);\n    if (!(_1442 > 9.9999999747524270787835121154785e-07))\n    {\n        return vec4(0.0);\n    }\n    vec2 _1464 = vec2(dot(fa_mesh_fs_params[14], _1436), dot(fa_mesh_fs_params[15], _1436)) / vec2(_1442);\n    int _1468 = int(fa_mesh_fs_params[18].x);\n    int _1472 = int(fa_mesh_fs_params[18].y);\n    int param = (int(fa_mesh_fs_params[19].x) + (((clamp(int(floor(log2(max(dot(fa_mesh_fs_params[17].xyz, world_pos) + fa_mesh_fs_params[17].w, fa_mesh_fs_params[18].w) / fa_mesh_fs_params[18].w) * fa_mesh_fs_params[18].z)), 0, int(fa_mesh_fs_params[19].y) - 1) * _1472) + clamp(int(floor(((_1464.y * 0.5) + 0.5) * fa_mesh_fs_params[18].y)), 0, _1472 - 1)) * _1468)) + clamp(int(floor(((_1464.x * 0.5) + 0.5) * fa_mesh_fs_params[18].x)), 0, _1468 - 1);\n    return fa_light_texel(param);\n}\n\nivec2 fa_cluster_lookup(vec3 world_pos)\n{\n    vec3 param = world_pos;\n    vec4 _1548 = fa_cluster_texel(param);\n    return ivec2(int(_1548.x), int(_1548.y));\n}\n\nvoid fa_cluster_begin(vec3 world_pos)\n{\n    fa_cl_ndir = int(fa_mesh_fs_params[19].z);\n    vec3 param = world_pos;\n    ivec2 _4859 = fa_cluster_lookup(param);\n    fa_cl_slot = _4859.x;\n    fa_cl_local = _4859.y;\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_linear_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvec3 fa_tex_fix(inout vec3 c, float mode)\n{\n    if (mode > 1.5)\n    {\n        vec3 param = c;\n        vec3 _5236 = fa_linear_to_srgb(param);\n        c = _5236;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            vec3 param_1 = c;\n            vec3 _5244 = fa_srgb_to_linear(param_1);\n            c = _5244;\n        }\n    }\n    return c;\n}\n\nvec3 fa_tangent_normal(SurfaceInput i, vec3 m)\n{\n    vec3 _348;\n    if (i.front_facing)\n    {\n        _348 = i.world_normal;\n    }\n    else\n    {\n        _348 = -i.world_normal;\n    }\n    vec3 _372 = normalize(i.world_tangent.xyz - (_348 * dot(_348, i.world_tangent.xyz)));\n    vec3 _400 = normalize(((_372 * m.x) + ((cross(_348, _372) * i.world_tangent.w) * m.y)) + (_348 * m.z));\n    vec3 _403;\n    if (i.front_facing)\n    {\n        _403 = _400;\n    }\n    else\n    {\n        _403 = -_400;\n    }\n    return _403;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    vec4 base_t = texture(fa_tex_fa_smp, i.uv, fa_mesh_fs_params[12].w);\n    float param = fa_mesh_fs_params[6].w;\n    float param_1 = 1.0;\n    vec3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    vec3 _5276 = fa_tex_fix(param_2, param_3);\n    vec4 _6433 = base_t;\n    _6433.x = _5276.x;\n    _6433.y = _5276.y;\n    _6433.z = _5276.z;\n    base_t = _6433;\n    vec4 _5290 = (_6433 * fa_mesh_fs_params[2]) * i.vertex_color;\n    vec3 _6229 = i.world_normal;\n    if (fa_mesh_fs_params[6].z > 0.5)\n    {\n        float param_4 = fa_mesh_fs_params[6].w;\n        float param_5 = 16.0;\n        vec3 param_6 = texture(fa_normal_tex_fa_smp, i.uv, fa_mesh_fs_params[12].w).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        vec3 _5324 = fa_tex_fix(param_6, param_7);\n        vec3 _5327 = (_5324 * 2.0) - vec3(1.0);\n        vec2 _5332 = _5327.xy * fa_mesh_fs_params[6].x;\n        vec3 _6441 = _5327;\n        _6441.x = _5332.x;\n        _6441.y = _5332.y;\n        SurfaceInput param_8 = i;\n        vec3 param_9 = _6441;\n        _6229 = fa_tangent_normal(param_8, param_9);\n    }\n    vec4 mrt = texture(fa_mr_tex_fa_smp, i.uv, fa_mesh_fs_params[12].w);\n    float param_10 = fa_mesh_fs_params[6].w;\n    float param_11 = 64.0;\n    vec3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    vec3 _5362 = fa_tex_fix(param_12, param_13);\n    vec4 _6444 = mrt;\n    _6444.x = _5362.x;\n    _6444.y = _5362.y;\n    _6444.z = _5362.z;\n    mrt = _6444;\n    vec4 _5392 = texture(fa_occlusion_tex_fa_smp, i.uv, fa_mesh_fs_params[12].w);\n    float param_14 = fa_mesh_fs_params[6].w;\n    float param_15 = 256.0;\n    vec3 param_16 = _5392.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    vec3 _5403 = fa_tex_fix(param_16, param_17);\n    float param_18 = fa_mesh_fs_params[6].w;\n    float param_19 = 4.0;\n    vec3 param_20 = texture(fa_emissive_tex_fa_smp, i.uv, fa_mesh_fs_params[12].w).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    vec3 _5435 = fa_tex_fix(param_20, param_21);\n    float _6234 = fa_mesh_fs_params[20].x;\n    float _6235 = fa_mesh_fs_params[20].y;\n    float _6238 = fa_mesh_fs_params[20].z;\n    float _6237 = fa_mesh_fs_params[21].w;\n    float _6240 = fa_mesh_fs_params[22].x;\n    if (fa_mesh_fs_params[22].z > 0.5)\n    {\n        if (mod(fa_mesh_fs_params[22].z, 2.0) > 0.5)\n        {\n            _6234 *= _5403.y;\n            _6235 *= _5403.z;\n            _6237 *= _5392.w;\n        }\n        if (fa_mesh_fs_params[22].z > 1.5)\n        {\n            _6238 *= mrt.x;\n            _6240 *= mrt.w;\n        }\n    }\n    return Surface(_5290.xyz, _5290.w, _6229, clamp(fa_mesh_fs_params[5].x * _5362.z, 0.0, 1.0), clamp(fa_mesh_fs_params[5].y * _5362.y, 0.0500000007450580596923828125, 1.0), 1.0 + (fa_mesh_fs_params[6].y * (_5403.x - 1.0)), fa_mesh_fs_params[3].xyz + (fa_mesh_fs_params[4].xyz * _5435), _6234, _6235, fa_mesh_fs_params[21].xyz, _6237, _6238, fa_mesh_fs_params[20].w, _6240, fa_mesh_fs_params[22].y, fa_mesh_fs_params[23].xyz, fa_mesh_fs_params[30].x, fa_mesh_fs_params[30].y, fa_mesh_fs_params[31].xyz, fa_mesh_fs_params[30].z);\n}\n\nvoid surface(SurfaceInput i, Surface s)\n{\n}\n\nvec4 fa_decal_tile(vec4 rect, vec2 uv, vec2 atlas, vec2 ddx, vec2 ddy)\n{\n    vec2 _1628 = rect.zw - rect.xy;\n    vec2 _1632 = _1628 * atlas;\n    vec2 _1636 = ddx * _1632;\n    vec2 _1640 = ddy * _1632;\n    return textureLod(fa_decal_tex_fa_env_smp, rect.xy + (clamp(uv, vec2(0.0), vec2(1.0)) * _1628), clamp(0.5 * log2(max(max(dot(_1636, _1636), dot(_1640, _1640)), 9.9999999392252902907785028219223e-09)), 0.0, 3.0));\n}\n\nvec3 fa_dc_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_dc_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvoid fa_apply_decals(vec3 world_pos, vec3 geo_normal, inout vec3 albedo, inout vec3 normal)\n{\n    bool _1673 = fa_mesh_fs_params[10].y < 0.5;\n    bool _1680;\n    if (!_1673)\n    {\n        _1680 = fa_mesh_fs_params[10].w < 0.5;\n    }\n    else\n    {\n        _1680 = _1673;\n    }\n    if (_1680)\n    {\n        return;\n    }\n    vec3 _1686 = dFdx(world_pos);\n    vec3 _1689 = dFdy(world_pos);\n    vec3 param = world_pos;\n    vec4 _1693 = fa_cluster_texel(param);\n    int _1697 = int(_1693.w);\n    if (_1697 < 1)\n    {\n        return;\n    }\n    int _1707 = int(fa_mesh_fs_params[10].y + 0.5);\n    int param_1 = _1707;\n    vec4 _1711 = fa_light_texel(param_1);\n    vec2 _1714 = _1711.yz;\n    int _1718 = int(_1711.w);\n    int param_2 = _1707 + 1;\n    vec4 _1723 = fa_light_texel(param_2);\n    float _1724 = _1723.x;\n    int _1730 = int(fa_mesh_fs_params[10].w + 0.5) - 1;\n    int _1734 = int(_1693.z);\n    vec3 _1999;\n    for (int k = 0; k < _1697; k++)\n    {\n        int _1747 = _1734 + k;\n        int param_3 = _1718 + (_1747 >> 2);\n        int _1764 = (_1707 + 2) + (int(fa_light_texel(param_3)[_1747 & 3]) * 7);\n        int param_4 = _1764 + 6;\n        vec4 _1769 = fa_light_texel(param_4);\n        if (((int(_1769.w + 0.5) >> _1730) & 1) == 0)\n        {\n            continue;\n        }\n        int param_5 = _1764;\n        vec4 _1784 = fa_light_texel(param_5);\n        int param_6 = _1764 + 1;\n        vec4 _1789 = fa_light_texel(param_6);\n        int param_7 = _1764 + 2;\n        vec4 _1794 = fa_light_texel(param_7);\n        vec3 _1797 = _1784.xyz;\n        float _1802 = dot(_1797, world_pos) + _1784.w;\n        vec3 _1804 = _1789.xyz;\n        float _1809 = dot(_1804, world_pos) + _1789.w;\n        vec3 _1811 = _1794.xyz;\n        float _1816 = dot(_1811, world_pos) + _1794.w;\n        bool _1821 = abs(_1802) > 0.5;\n        bool _1829;\n        if (!_1821)\n        {\n            _1829 = abs(_1809) > 0.5;\n        }\n        else\n        {\n            _1829 = _1821;\n        }\n        bool _1837;\n        if (!_1829)\n        {\n            _1837 = abs(_1816) > 0.5;\n        }\n        else\n        {\n            _1837 = _1829;\n        }\n        if (_1837)\n        {\n            continue;\n        }\n        float _1852 = clamp(dot(geo_normal, normalize(_1811)) * _1769.z, 0.0, 1.0);\n        if (_1852 <= 0.0)\n        {\n            continue;\n        }\n        float _1872 = (clamp((0.5 - abs(_1816)) * 10.0, 0.0, 1.0) * _1852) * _1769.x;\n        vec2 _1880 = vec2(_1802 + 0.5, 0.5 - _1809);\n        vec2 _1890 = vec2(dot(_1797, _1686), dot(_1804, _1686));\n        vec2 _1900 = vec2(dot(_1797, _1689), dot(_1804, _1689));\n        int param_8 = _1764 + 5;\n        vec4 _1905 = fa_light_texel(param_8);\n        int param_9 = _1764 + 3;\n        vec4 _1910 = fa_light_texel(param_9);\n        int param_10 = _1764 + 4;\n        vec4 _1915 = fa_light_texel(param_10);\n        float tex_a = 1.0;\n        vec3 col = _1905.xyz;\n        bool _1925 = _1910.z > _1910.x;\n        if (_1925)\n        {\n            vec4 param_11 = _1910;\n            vec2 param_12 = _1880;\n            vec2 param_13 = _1714;\n            vec2 param_14 = _1890;\n            vec2 param_15 = _1900;\n            vec4 tx = fa_decal_tile(param_11, param_12, param_13, param_14, param_15);\n            if ((_1724 > 0.5) && (_1724 < 1.5))\n            {\n                vec3 param_16 = tx.xyz;\n                vec3 _1951 = fa_dc_to_linear(param_16);\n                vec4 _6317 = tx;\n                _6317.x = _1951.x;\n                _6317.y = _1951.y;\n                _6317.z = _1951.z;\n                tx = _6317;\n            }\n            col *= tx.xyz;\n            tex_a = tx.w;\n        }\n        albedo = mix(albedo, col, vec3(clamp((_1872 * tex_a) * _1905.w, 0.0, 1.0)));\n        if (_1915.z > _1915.x)\n        {\n            vec4 param_17 = _1915;\n            vec2 param_18 = _1880;\n            vec2 param_19 = _1714;\n            vec2 param_20 = _1890;\n            vec2 param_21 = _1900;\n            vec4 _1995 = fa_decal_tile(param_17, param_18, param_19, param_20, param_21);\n            if (_1724 > 1.5)\n            {\n                vec3 param_22 = _1995.xyz;\n                vec3 _2005 = fa_dc_to_srgb(param_22);\n                _1999 = _2005;\n            }\n            else\n            {\n                _1999 = _1995.xyz;\n            }\n            vec3 _2014 = (_1999 * 2.0) - vec3(1.0);\n            vec2 _2019 = _2014.xy * _1769.y;\n            vec3 _2041 = (normalize(_1797) * _2019.x) + (normalize(_1804) * _2019.y);\n            vec3 _2044 = normalize(normal);\n            normal = normalize(mix(_2044, normalize((_2044 * max(_2014.z, 0.0500000007450580596923828125)) + (_2041 - (_2044 * dot(_2044, _2041)))), vec3(clamp(_1872 * (_1925 ? tex_a : 1.0), 0.0, 1.0))));\n        }\n    }\n}\n\nint fa_light_count()\n{\n    return fa_cl_ndir + fa_cl_local;\n}\n\nLightSample fa_no_light()\n{\n    return LightSample(vec3(0.0, 1.0, 0.0), vec3(0.0), 0.0, 1.0, 0.0, 0);\n}\n\nint fa_cluster_index(int slot, int n)\n{\n    int param = (int(fa_mesh_fs_params[19].x) + int(fa_mesh_fs_params[19].w)) + ((slot + n) >> 2);\n    vec4 t = fa_light_texel(param);\n    return int(t[(slot + n) & 3]);\n}\n\nint fa_cl_light(int n)\n{\n    if (n < fa_cl_ndir)\n    {\n        return n;\n    }\n    int param = fa_cl_slot;\n    int param_1 = n - fa_cl_ndir;\n    return fa_cluster_index(param, param_1);\n}\n\nint fa_light_base(int li)\n{\n    return li * ((fa_mesh_fs_params[1].w > 4.5) ? 8 : 4);\n}\n\nbool fa_light_baked(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 3;\n    return fa_light_texel(param_1).w > 0.5;\n}\n\nfloat fa_baked_keep(int li)\n{\n    float _4829;\n    if (fa_lm.z > 0.5)\n    {\n        _4829 = 0.0;\n    }\n    else\n    {\n        _4829 = 1.0 - clamp(fa_mesh_fs_params[32].w, 0.0, 1.0);\n    }\n    bool _4840 = _4829 < 1.0;\n    bool _4846;\n    if (_4840)\n    {\n        int param = li;\n        _4846 = fa_light_baked(param);\n    }\n    else\n    {\n        _4846 = _4840;\n    }\n    return _4846 ? _4829 : 1.0;\n}\n\nvec3 fa_area_point(vec3 c, vec3 axis, vec3 ru, vec3 uu, float hx, float hy, float shape, vec3 p, vec3 r)\n{\n    bool _646 = dot(r, r) > 0.5;\n    if (shape > 1.5)\n    {\n        vec3 _659 = (c - (ru * hx)) - p;\n        vec3 _665 = ru * (2.0 * hx);\n        float _671 = max(dot(_665, _665), 9.9999999392252902907785028219223e-09);\n        float _675 = dot(_659, _665);\n        float t = clamp((-_675) / _671, 0.0, 1.0);\n        if (_646)\n        {\n            float _690 = dot(r, _665);\n            float _696 = _671 - (_690 * _690);\n            if (abs(_696) > (9.9999997473787516355514526367188e-06 * _671))\n            {\n                t = clamp(((dot(r, _659) * _690) - _675) / _696, 0.0, 1.0);\n            }\n        }\n        return (p + _659) + (_665 * t);\n    }\n    vec3 q = p;\n    float _728 = dot(r, axis);\n    bool _736;\n    if (_646)\n    {\n        _736 = abs(_728) > 9.9999997473787516355514526367188e-05;\n    }\n    else\n    {\n        _736 = _646;\n    }\n    if (_736)\n    {\n        float _746 = dot(c - p, axis) / _728;\n        if (_746 > 0.0)\n        {\n            q = p + (r * _746);\n        }\n    }\n    vec3 _759 = q - c;\n    vec2 xy = vec2(dot(_759, ru), dot(_759, uu));\n    if (shape > 0.5)\n    {\n        float _774 = length(xy);\n        if (_774 > hx)\n        {\n            xy *= (hx / _774);\n        }\n    }\n    else\n    {\n        xy = clamp(xy, vec2(-hx, -hy), vec2(hx, hy));\n    }\n    return (c + (ru * xy.x)) + (uu * xy.y);\n}\n\nvec4 fa_atlas_fetch(vec2 texel)\n{\n    return textureLod(fa_light_atlas_fa_env_smp, texel / vec2(textureSize(fa_light_atlas_fa_env_smp, 0)), 0.0);\n}\n\nvec3 fa_cookie_sample(vec2 tile_origin, vec2 uv)\n{\n    vec2 param = (tile_origin + vec2(1.0)) + (clamp(uv, vec2(0.0), vec2(1.0)) * 254.0);\n    return fa_atlas_fetch(param).xyz;\n}\n\nfloat fa_ies_sample(vec2 tile_origin, vec3 d, vec3 axis, vec3 right, vec3 up)\n{\n    float _566 = dot(d, right);\n    float _570 = dot(d, up);\n    float _581;\n    if (((_566 * _566) + (_570 * _570)) > 1.0000000133514319600180897396058e-10)\n    {\n        _581 = atan(_570, _566) * 0.15915493667125701904296875;\n    }\n    else\n    {\n        _581 = 0.0;\n    }\n    vec2 param = tile_origin + vec2(1.0 + ((_581 - floor(_581)) * 64.0), 1.0 + (acos(clamp(dot(d, axis), -1.0, 1.0)) * 10.18591594696044921875));\n    return fa_atlas_fetch(param).x;\n}\n\nint fa_cube_face(vec3 d)\n{\n    vec3 _415 = abs(d);\n    float _417 = _415.x;\n    float _419 = _415.y;\n    bool _420 = _417 >= _419;\n    bool _428;\n    if (_420)\n    {\n        _428 = _417 >= _415.z;\n    }\n    else\n    {\n        _428 = _420;\n    }\n    int _429;\n    if (_428)\n    {\n        _429 = (d.x > 0.0) ? 0 : 1;\n    }\n    else\n    {\n        int _444;\n        if (_419 >= _415.z)\n        {\n            _444 = (d.y > 0.0) ? 2 : 3;\n        }\n        else\n        {\n            _444 = (d.z > 0.0) ? 4 : 5;\n        }\n        _429 = _444;\n    }\n    return _429;\n}\n\nvoid fa_cube_face_basis(int f, out vec3 fwd, out vec3 up)\n{\n    if (f == 0)\n    {\n        fwd = vec3(1.0, 0.0, 0.0);\n        up = vec3(0.0, 1.0, 0.0);\n    }\n    else\n    {\n        if (f == 1)\n        {\n            fwd = vec3(-1.0, 0.0, 0.0);\n            up = vec3(0.0, 1.0, 0.0);\n        }\n        else\n        {\n            if (f == 2)\n            {\n                fwd = vec3(0.0, 1.0, 0.0);\n                up = vec3(0.0, 0.0, 1.0);\n            }\n            else\n            {\n                if (f == 3)\n                {\n                    fwd = vec3(0.0, -1.0, 0.0);\n                    up = vec3(0.0, 0.0, -1.0);\n                }\n                else\n                {\n                    if (f == 4)\n                    {\n                        fwd = vec3(0.0, 0.0, 1.0);\n                        up = vec3(0.0, 1.0, 0.0);\n                    }\n                    else\n                    {\n                        fwd = vec3(0.0, 0.0, -1.0);\n                        up = vec3(0.0, 1.0, 0.0);\n                    }\n                }\n            }\n        }\n    }\n}\n\nLightSample fa_light_sample_n(int li, vec3 world_pos, vec3 n)\n{\n    int param = li;\n    int _812 = fa_light_base(param);\n    bool _816 = fa_mesh_fs_params[1].w > 4.5;\n    int param_1 = _812;\n    vec4 _820 = fa_light_texel(param_1);\n    int param_2 = _812 + 1;\n    vec4 _825 = fa_light_texel(param_2);\n    float _828 = _825.w;\n    float atten = 1.0;\n    float dist = 0.0;\n    fa_light_tint = vec3(1.0);\n    bool _840 = _816 && (_828 > 2.5);\n    fa_light_is_area = _840;\n    bool _842 = _828 < 0.5;\n    vec3 l;\n    if (_842)\n    {\n        l = normalize(_820.xyz);\n        if (_816)\n        {\n            int param_3 = _812 + 6;\n            vec4 _856 = fa_light_texel(param_3);\n            if (_856.z > 0.5)\n            {\n                int param_4 = _812 + 4;\n                vec4 _866 = fa_light_texel(param_4);\n                int param_5 = _812 + 5;\n                vec4 _871 = fa_light_texel(param_5);\n                vec2 param_6 = _856.xy;\n                vec2 param_7 = fract(vec2(dot(world_pos, _866.xyz) * _866.w, (-dot(world_pos, _871.xyz)) * _871.w) + vec2(0.5));\n                fa_light_tint = fa_cookie_sample(param_6, param_7);\n            }\n        }\n    }\n    else\n    {\n        vec3 _901 = _820.xyz;\n        vec3 _903 = _901 - world_pos;\n        vec3 to_light = _903;\n        float _906 = length(_903);\n        float reach = _906;\n        bool front = true;\n        if (_840)\n        {\n            int param_8 = _812 + 7;\n            reach = max(_906 - fa_light_texel(param_8).w, 0.0);\n            int param_9 = _812 + 4;\n            vec4 _930 = fa_light_texel(param_9);\n            int param_10 = _812 + 5;\n            vec4 _935 = fa_light_texel(param_10);\n            int param_11 = _812 + 6;\n            vec4 _940 = fa_light_texel(param_11);\n            float _941 = _940.w;\n            int param_12 = _812 + 2;\n            vec3 _948 = normalize(fa_light_texel(param_12).xyz);\n            bool _950 = _941 > 1.5;\n            bool _958;\n            if (!_950)\n            {\n                _958 = dot(_948, to_light) < 0.0;\n            }\n            else\n            {\n                _958 = _950;\n            }\n            front = _958;\n            vec3 r = vec3(0.0);\n            vec3 _967 = fa_mesh_fs_params[0].xyz - world_pos;\n            bool _971 = dot(n, n) > 0.5;\n            bool _979;\n            if (_971)\n            {\n                _979 = dot(_967, _967) > 9.9999999600419720025001879548654e-13;\n            }\n            else\n            {\n                _979 = _971;\n            }\n            if (_979)\n            {\n                r = reflect(-normalize(_967), normalize(n));\n            }\n            vec3 param_13 = _901;\n            vec3 param_14 = _948;\n            vec3 param_15 = _930.xyz;\n            vec3 param_16 = _935.xyz;\n            float param_17 = _930.w;\n            float param_18 = _935.w;\n            float param_19 = _941;\n            vec3 param_20 = world_pos;\n            vec3 param_21 = r;\n            to_light = fa_area_point(param_13, param_14, param_15, param_16, param_17, param_18, param_19, param_20, param_21) - world_pos;\n        }\n        float _1015 = length(to_light);\n        dist = _1015;\n        l = to_light / vec3(max(_1015, 9.9999997473787516355514526367188e-05));\n        float _1029 = reach / max(_820.w, 0.001000000047497451305389404296875);\n        float _1035 = clamp(1.0 - (_1029 * _1029), 0.0, 1.0);\n        float _1037;\n        if (front)\n        {\n            _1037 = _1035 * _1035;\n        }\n        else\n        {\n            _1037 = 0.0;\n        }\n        atten = _1037;\n        bool _1048 = _828 < 2.5;\n        if ((_828 > 1.5) && _1048)\n        {\n            int param_22 = _812 + 2;\n            vec4 _1056 = fa_light_texel(param_22);\n            float _1066 = _1056.w;\n            int param_23 = _812 + 3;\n            vec4 _1071 = fa_light_texel(param_23);\n            float _1072 = _1071.x;\n            float cos_inner = _1072;\n            if (_1072 > 1.5)\n            {\n                cos_inner = mix(_1066, 1.0, 0.25);\n            }\n            atten *= smoothstep(_1066, cos_inner, dot(-l, normalize(_1056.xyz)));\n        }\n        if (_816 && (_828 < 1.5))\n        {\n            int param_24 = _812 + 6;\n            vec4 _1096 = fa_light_texel(param_24);\n            if (_1096.z > 0.5)\n            {\n                vec3 _1104 = -to_light;\n                int param_25 = _812 + 4;\n                int param_26 = _812 + 5;\n                vec3 _1118 = fa_light_texel(param_25).xyz;\n                vec3 _1122 = fa_light_texel(param_26).xyz;\n                vec3 _1131 = vec3(dot(_1104, _1118), dot(_1104, _1122), dot(_1104, cross(_1118, _1122)));\n                vec3 param_27 = _1131;\n                int _1135 = fa_cube_face(param_27);\n                int param_28 = _1135;\n                vec3 param_29;\n                vec3 param_30;\n                fa_cube_face_basis(param_28, param_29, param_30);\n                vec2 _1162 = vec2(dot(_1131, cross(param_29, param_30)), dot(_1131, param_30)) / vec2(max(dot(_1131, param_29), 9.9999997473787516355514526367188e-05));\n                int _1166 = _1135 / 3;\n                vec2 param_31 = _1096.xy + (vec2(float(_1135 - (_1166 * 3)), float(_1166)) * 256.0);\n                vec2 param_32 = vec2(0.5 + (0.5 * _1162.x), 0.5 - (0.5 * _1162.y));\n                fa_light_tint = fa_cookie_sample(param_31, param_32);\n            }\n            int param_33 = _812 + 7;\n            vec4 _1196 = fa_light_texel(param_33);\n            if (_1196.z > 0.5)\n            {\n                int param_34 = _812 + 2;\n                int param_35 = _812 + 4;\n                int param_36 = _812 + 5;\n                vec2 param_37 = _1196.xy;\n                vec3 param_38 = -l;\n                vec3 param_39 = normalize(fa_light_texel(param_34).xyz);\n                vec3 param_40 = fa_light_texel(param_35).xyz;\n                vec3 param_41 = fa_light_texel(param_36).xyz;\n                atten *= fa_ies_sample(param_37, param_38, param_39, param_40, param_41);\n            }\n        }\n        else\n        {\n            if (_816 && _1048)\n            {\n                int param_42 = _812 + 6;\n                vec4 _1243 = fa_light_texel(param_42);\n                int param_43 = _812 + 7;\n                vec4 _1248 = fa_light_texel(param_43);\n                bool _1251 = _1243.z > 0.5;\n                bool _1258;\n                if (!_1251)\n                {\n                    _1258 = _1248.z > 0.5;\n                }\n                else\n                {\n                    _1258 = _1251;\n                }\n                if (_1258)\n                {\n                    int param_44 = _812 + 2;\n                    vec4 _1265 = fa_light_texel(param_44);\n                    vec3 _1269 = normalize(_1265.xyz);\n                    int param_45 = _812 + 4;\n                    vec4 _1274 = fa_light_texel(param_45);\n                    int param_46 = _812 + 5;\n                    vec4 _1279 = fa_light_texel(param_46);\n                    if (_1251)\n                    {\n                        vec3 _1287 = -to_light;\n                        float _1294 = _1265.w;\n                        float _1310 = 0.5 / max(dot(_1287, _1269) * (sqrt(max(1.0 - (_1294 * _1294), 0.0)) / max(_1294, 0.001000000047497451305389404296875)), 9.9999997473787516355514526367188e-05);\n                        vec2 param_47 = _1243.xy;\n                        vec2 param_48 = vec2(0.5 + (dot(_1287, _1274.xyz) * _1310), 0.5 - (dot(_1287, _1279.xyz) * _1310));\n                        fa_light_tint = fa_cookie_sample(param_47, param_48);\n                    }\n                    if (_1248.z > 0.5)\n                    {\n                        vec2 param_49 = _1248.xy;\n                        vec3 param_50 = -l;\n                        vec3 param_51 = _1269;\n                        vec3 param_52 = _1274.xyz;\n                        vec3 param_53 = _1279.xyz;\n                        atten *= fa_ies_sample(param_49, param_50, param_51, param_52, param_53);\n                    }\n                }\n            }\n        }\n    }\n    vec3 _6035 = _825.xyz * atten;\n    if (_816)\n    {\n        _6035 *= fa_light_tint;\n    }\n    int _1379;\n    if (_842)\n    {\n        _1379 = 0;\n    }\n    else\n    {\n        _1379 = ((_828 > 1.5) && (_828 < 2.5)) ? 2 : 1;\n    }\n    return LightSample(l, _6035, atten, 1.0, dist, _1379);\n}\n\nLightSample fa_light_unshadowed(int n, SurfaceInput i)\n{\n    bool _5058 = n < 0;\n    bool _5065;\n    if (!_5058)\n    {\n        _5065 = n >= fa_light_count();\n    }\n    else\n    {\n        _5065 = _5058;\n    }\n    if (_5065)\n    {\n        return fa_no_light();\n    }\n    int param = n;\n    int _5073 = fa_cl_light(param);\n    int param_1 = _5073;\n    float _5077 = fa_baked_keep(param_1);\n    if (_5077 <= 0.0)\n    {\n        return fa_no_light();\n    }\n    int param_2 = _5073;\n    vec3 param_3 = i.world_pos;\n    vec3 param_4 = i.world_normal;\n    LightSample _5093 = fa_light_sample_n(param_2, param_3, param_4);\n    return LightSample(_5093.direction, _5093.color * _5077, _5093.attenuation * _5077, _5093.shadow, _5093._distance, _5093.type);\n}\n\nfloat fa_light_type(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 1;\n    return fa_light_texel(param_1).w;\n}\n\nfloat fa_shadow_depth(inout vec2 uv, vec4 rect)\n{\n    uv = clamp(uv, rect.xy, rect.zw);\n    return textureLod(fa_shadow_tex_fa_shadow_smp, uv, 0.0).x;\n}\n\nfloat fa_shadow_fetch(vec2 uv, vec4 rect, vec3 conv)\n{\n    vec2 param = uv;\n    vec4 param_1 = rect;\n    float _2168 = fa_shadow_depth(param, param_1);\n    float _2172;\n    if (conv.x < 0.5)\n    {\n        _2172 = _2168;\n    }\n    else\n    {\n        _2172 = (conv.y * conv.z) / (conv.z - (_2168 * (conv.z - conv.y)));\n    }\n    return _2172;\n}\n\nfloat fa_shadow_noise()\n{\n    return fract(52.98291778564453125 * fract(dot(gl_FragCoord.xy, vec2(0.067110560834407806396484375, 0.005837149918079376220703125))));\n}\n\nvec2 fa_shadow_vogel_turn(vec2 d)\n{\n    return vec2((d.x * (-0.737368881702423095703125)) - (d.y * 0.675490319728851318359375), (d.y * (-0.737368881702423095703125)) + (d.x * 0.675490319728851318359375));\n}\n\nfloat fa_shadow_filter(vec2 uv, vec4 rect, float zr, float texel_m, float unit, float reach, float plane, vec3 conv, int mode, float k)\n{\n    if (mode == 1)\n    {\n        vec2 param = uv;\n        vec4 param_1 = rect;\n        vec3 param_2 = conv;\n        return float(zr <= fa_shadow_fetch(param, param_1, param_2));\n    }\n    float _2218 = fa_shadow_noise() * 6.283185482025146484375;\n    vec2 _2224 = vec2(cos(_2218), sin(_2218));\n    vec2 dir = _2224;\n    float radius = 1.5;\n    if (mode == 2)\n    {\n        float _2233;\n        if (k < 0.0)\n        {\n            _2233 = (-k) / max(zr, 0.100000001490116119384765625);\n        }\n        else\n        {\n            _2233 = k;\n        }\n        float _2252 = clamp((_2233 * reach) / texel_m, 3.0, 12.0);\n        float sum = 0.0;\n        float cnt = 0.0;\n        for (int i = 0; i < 16; i++)\n        {\n            float _2271 = sqrt((float(i) + 0.5) * 0.0625) * _2252;\n            vec2 param_3 = uv + (dir * (fa_shadows[26].zw * _2271));\n            vec4 param_4 = rect;\n            vec3 param_5 = conv;\n            float _2285 = fa_shadow_fetch(param_3, param_4, param_5);\n            if (_2285 < (zr - (_2271 * plane)))\n            {\n                sum += _2285;\n                cnt += 1.0;\n            }\n            vec2 param_6 = dir;\n            dir = fa_shadow_vogel_turn(param_6);\n        }\n        if (cnt < 0.5)\n        {\n            return 1.0;\n        }\n        float _2313 = sum / cnt;\n        float _2323;\n        if (k < 0.0)\n        {\n            _2323 = (-k) / max(_2313, 0.0500000007450580596923828125);\n        }\n        else\n        {\n            _2323 = k;\n        }\n        radius = clamp(((max(zr - _2313, 0.0) * unit) * _2323) / texel_m, 1.5, 16.0);\n        dir = _2224;\n    }\n    float lit = 0.0;\n    int _2349 = (mode == 2) ? 24 : 16;\n    for (int i_1 = 0; i_1 < _2349; i_1++)\n    {\n        float _2368 = sqrt((float(i_1) + 0.5) / float(_2349)) * radius;\n        vec2 param_7 = uv + (dir * (fa_shadows[26].zw * _2368));\n        vec4 param_8 = rect;\n        vec3 param_9 = conv;\n        lit += float((zr - (_2368 * plane)) <= fa_shadow_fetch(param_7, param_8, param_9));\n        vec2 param_10 = dir;\n        dir = fa_shadow_vogel_turn(param_10);\n    }\n    return lit / float(_2349);\n}\n\nfloat fa_shadow_local(int li, vec3 lpos, vec3 world, vec3 n, vec3 l)\n{\n    bool _2573 = fa_mesh_fs_params[5].z < 0.5;\n    bool _2580;\n    if (!_2573)\n    {\n        _2580 = fa_shadows[29].x < 0.5;\n    }\n    else\n    {\n        _2580 = _2573;\n    }\n    if (_2580)\n    {\n        return 1.0;\n    }\n    int param = (int(fa_shadows[29].x + 0.5) - 1) + li;\n    vec4 _2593 = fa_light_texel(param);\n    float _2594 = _2593.x;\n    if (_2594 < 0.0)\n    {\n        return 1.0;\n    }\n    int _2603 = int(_2594 + 0.5);\n    int param_1 = _2603;\n    vec4 _2607 = fa_light_texel(param_1);\n    int param_2 = _2603 + 1;\n    vec4 _2612 = fa_light_texel(param_2);\n    float fade = 1.0;\n    float _2615 = _2607.y;\n    if (_2615 > 0.0)\n    {\n        float _2632 = 1.0 - smoothstep(0.75 * _2615, _2615, length(world - fa_shadows[27].xyz));\n        fade = _2632;\n        if (_2632 <= 0.0)\n        {\n            return 1.0;\n        }\n    }\n    int face = 0;\n    if (_2607.x > 1.5)\n    {\n        vec3 param_3 = world - lpos;\n        face = fa_cube_face(param_3);\n    }\n    int _2656 = (_2603 + 2) + (face * 6);\n    int param_4 = _2656;\n    int param_5 = _2656 + 1;\n    int param_6 = _2656 + 3;\n    vec4 _2670 = fa_light_texel(param_6);\n    int param_7 = _2656 + 4;\n    vec4 _2675 = fa_light_texel(param_7);\n    int param_8 = _2656 + 5;\n    vec4 _2680 = fa_light_texel(param_8);\n    float _2692 = _2680.x * max(dot(_2670, vec4(world, 1.0)), 0.001000000047497451305389404296875);\n    float _2697 = clamp(dot(n, l), 0.0, 1.0);\n    float _2720 = clamp(dot(n, _2670.xyz), -1.0, 1.0);\n    float _2739 = min(sqrt(1.0 - (_2720 * _2720)) / max(abs(dot(n, world - lpos)) / max(dot(_2670, vec4(world, 1.0)), 0.001000000047497451305389404296875), 0.20000000298023223876953125), 4.0);\n    float _2742 = _2612.y;\n    float _2744;\n    if (_2742 > 0.0)\n    {\n        _2744 = _2742;\n    }\n    else\n    {\n        _2744 = 1.5 * _2692;\n    }\n    vec4 _2764 = vec4(world + (n * (_2744 * sqrt(1.0 - (_2697 * _2697)))), 1.0);\n    float _2768 = dot(_2670, _2764);\n    float _2771 = _2680.y;\n    if (_2768 < _2771)\n    {\n        return 1.0;\n    }\n    vec2 _2786 = vec2(dot(fa_light_texel(param_4), _2764), dot(fa_light_texel(param_5), _2764)) / vec2(_2768);\n    float _2788 = _2786.x;\n    bool _2791 = _2788 < _2675.x;\n    bool _2800;\n    if (!_2791)\n    {\n        _2800 = _2788 > _2675.z;\n    }\n    else\n    {\n        _2800 = _2791;\n    }\n    bool _2809;\n    if (!_2800)\n    {\n        _2809 = _2786.y < _2675.y;\n    }\n    else\n    {\n        _2809 = _2800;\n    }\n    bool _2818;\n    if (!_2809)\n    {\n        _2818 = _2786.y > _2675.w;\n    }\n    else\n    {\n        _2818 = _2809;\n    }\n    if (_2818)\n    {\n        return 1.0;\n    }\n    float _2824 = _2612.x;\n    float _2826;\n    if (_2824 > 0.0)\n    {\n        _2826 = _2824;\n    }\n    else\n    {\n        _2826 = 1.5 * _2692;\n    }\n    vec2 param_9 = _2786;\n    vec4 param_10 = _2675;\n    float param_11 = _2768 - (_2826 * (1.0 + (0.5 * _2739)));\n    float param_12 = _2692;\n    float param_13 = 1.0;\n    float param_14 = _2680.z * 0.25;\n    float param_15 = (_2692 * min(_2739, 3.0)) * 0.5;\n    vec3 param_16 = vec3(1.0, _2771, _2680.z);\n    int param_17 = int(_2607.z + 0.5);\n    float param_18 = _2607.w;\n    return mix(1.0, fa_shadow_filter(param_9, param_10, param_11, param_12, param_13, param_14, param_15, param_16, param_17, param_18), fade);\n}\n\nfloat fa_shadow_split_at(int i)\n{\n    float _2111;\n    if (i == 0)\n    {\n        _2111 = fa_shadows[24].x;\n    }\n    else\n    {\n        float _2127;\n        if (i == 1)\n        {\n            _2127 = fa_shadows[24].y;\n        }\n        else\n        {\n            float _2135;\n            if (i == 2)\n            {\n                _2135 = fa_shadows[24].z;\n            }\n            else\n            {\n                _2135 = fa_shadows[24].w;\n            }\n            _2127 = _2135;\n        }\n        _2111 = _2127;\n    }\n    return _2111;\n}\n\nfloat fa_shadow_cascade(int ci, vec3 world, vec3 n, vec3 l)\n{\n    float _2414 = max(fa_shadows[ci * 1 + 20].y, 0.001000000047497451305389404296875);\n    float _2419 = clamp(dot(n, l), 0.0, 1.0);\n    float _2425 = sqrt(1.0 - (_2419 * _2419));\n    float _2433 = min(_2425 / max(_2419, 0.20000000298023223876953125), 4.0);\n    float _2438;\n    if (fa_shadows[26].y > 0.0)\n    {\n        _2438 = fa_shadows[26].y;\n    }\n    else\n    {\n        _2438 = 1.5 * fa_shadows[ci * 1 + 20].x;\n    }\n    vec4 _2463 = mat4(fa_shadows[ci * 4 + 0], fa_shadows[ci * 4 + 1], fa_shadows[ci * 4 + 2], fa_shadows[ci * 4 + 3]) * vec4(world + (n * (_2438 * _2425)), 1.0);\n    float _2470 = _2463.x;\n    bool _2473 = _2470 < fa_shadows[ci * 1 + 16].x;\n    bool _2482;\n    if (!_2473)\n    {\n        _2482 = _2470 > fa_shadows[ci * 1 + 16].z;\n    }\n    else\n    {\n        _2482 = _2473;\n    }\n    bool _2491;\n    if (!_2482)\n    {\n        _2491 = _2463.y < fa_shadows[ci * 1 + 16].y;\n    }\n    else\n    {\n        _2491 = _2482;\n    }\n    bool _2500;\n    if (!_2491)\n    {\n        _2500 = _2463.y > fa_shadows[ci * 1 + 16].w;\n    }\n    else\n    {\n        _2500 = _2491;\n    }\n    bool _2507;\n    if (!_2500)\n    {\n        _2507 = _2463.z > 1.0;\n    }\n    else\n    {\n        _2507 = _2500;\n    }\n    if (_2507)\n    {\n        return -1.0;\n    }\n    float _2515;\n    if (fa_shadows[26].x > 0.0)\n    {\n        _2515 = fa_shadows[26].x;\n    }\n    else\n    {\n        _2515 = 1.5 * fa_shadows[ci * 1 + 20].x;\n    }\n    vec2 param = _2463.xy;\n    vec4 param_1 = fa_shadows[ci * 1 + 16];\n    float param_2 = _2463.z - ((_2515 * (1.0 + (0.5 * _2433))) / _2414);\n    float param_3 = fa_shadows[ci * 1 + 20].x;\n    float param_4 = _2414;\n    float param_5 = _2414 * 0.25;\n    float param_6 = ((fa_shadows[ci * 1 + 20].x * min(_2433, 3.0)) * 0.5) / _2414;\n    vec3 param_7 = vec3(0.0);\n    int param_8 = int(fa_shadows[25].z + 0.5);\n    float param_9 = fa_shadows[25].w;\n    return fa_shadow_filter(param, param_1, param_2, param_3, param_4, param_5, param_6, param_7, param_8, param_9);\n}\n\nfloat fa_shadow_sun(vec3 world, vec3 n, vec3 l)\n{\n    if (fa_mesh_fs_params[5].z < 0.5)\n    {\n        return 1.0;\n    }\n    int _2893 = int(fa_shadows[25].x + 0.5);\n    if (_2893 < 1)\n    {\n        return 1.0;\n    }\n    float _2908 = dot(world - fa_shadows[27].xyz, fa_shadows[28].xyz);\n    int param = _2893 - 1;\n    if (_2908 > fa_shadow_split_at(param))\n    {\n        return 1.0;\n    }\n    int ci = 0;\n    bool _2920 = _2893 > 1;\n    bool _2927;\n    if (_2920)\n    {\n        _2927 = _2908 > fa_shadows[24].x;\n    }\n    else\n    {\n        _2927 = _2920;\n    }\n    if (_2927)\n    {\n        ci = 1;\n    }\n    bool _2931 = _2893 > 2;\n    bool _2938;\n    if (_2931)\n    {\n        _2938 = _2908 > fa_shadows[24].y;\n    }\n    else\n    {\n        _2938 = _2931;\n    }\n    if (_2938)\n    {\n        ci = 2;\n    }\n    bool _2942 = _2893 > 3;\n    bool _2949;\n    if (_2942)\n    {\n        _2949 = _2908 > fa_shadows[24].z;\n    }\n    else\n    {\n        _2949 = _2942;\n    }\n    if (_2949)\n    {\n        ci = 3;\n    }\n    float s = -1.0;\n    float s2 = -1.0;\n    float t = 0.0;\n    int _2960 = min(_2893, 4);\n    float _3001;\n    for (int c = ci; c < _2960; c++)\n    {\n        int param_1 = c;\n        vec3 param_2 = world;\n        vec3 param_3 = n;\n        vec3 param_4 = l;\n        float _2980 = fa_shadow_cascade(param_1, param_2, param_3, param_4);\n        if (s >= 0.0)\n        {\n            s2 = _2980;\n            break;\n        }\n        if (_2980 < 0.0)\n        {\n            continue;\n        }\n        s = _2980;\n        ci = c;\n        if (fa_shadows[25].y > 0.0)\n        {\n            if (ci > 0)\n            {\n                int param_5 = ci - 1;\n                _3001 = fa_shadow_split_at(param_5);\n            }\n            else\n            {\n                _3001 = fa_shadows[28].w;\n            }\n            int param_6 = ci;\n            float _3020 = fa_shadows[25].y * max(fa_shadow_split_at(param_6) - _3001, 9.9999997473787516355514526367188e-05);\n            int param_7 = ci;\n            t = clamp((_2908 - (fa_shadow_split_at(param_7) - _3020)) / _3020, 0.0, 1.0);\n        }\n        if (t <= 0.0)\n        {\n            break;\n        }\n    }\n    if (s < 0.0)\n    {\n        return 1.0;\n    }\n    if (t > 0.0)\n    {\n        float _3052;\n        if ((ci + 1) < _2893)\n        {\n            _3052 = (s2 < 0.0) ? s : s2;\n        }\n        else\n        {\n            _3052 = 1.0;\n        }\n        s = mix(s, _3052, t);\n    }\n    return s;\n}\n\nfloat fa_shadow_factor(vec3 n, vec3 l)\n{\n    bool _3157 = fa_mesh_fs_params[25].y > 0.5;\n    bool _3163;\n    if (_3157)\n    {\n        _3163 = fa_mesh_fs_params[5].z > 0.5;\n    }\n    else\n    {\n        _3163 = _3157;\n    }\n    if (_3163)\n    {\n        vec4 _3173 = vec4(fa_world_pos, 1.0);\n        float _3179 = dot(fa_mesh_fs_params[28], _3173);\n        if (_3179 > 9.9999997473787516355514526367188e-05)\n        {\n            vec2 _3198 = vec2(dot(fa_mesh_fs_params[26], _3173), dot(fa_mesh_fs_params[27], _3173)) / vec2(_3179);\n            float _3203 = (_3198.x * 0.5) + 0.5;\n            float _3207;\n            if (fa_mesh_fs_params[24].y > 0.5)\n            {\n                _3207 = (_3198.y * 0.5) + 0.5;\n            }\n            else\n            {\n                _3207 = 0.5 - (_3198.y * 0.5);\n            }\n            bool _3223 = _3203 >= 0.0;\n            bool _3229;\n            if (_3223)\n            {\n                _3229 = _3203 < 1.0;\n            }\n            else\n            {\n                _3229 = _3223;\n            }\n            bool _3235;\n            if (_3229)\n            {\n                _3235 = _3207 >= 0.0;\n            }\n            else\n            {\n                _3235 = _3229;\n            }\n            bool _3241;\n            if (_3235)\n            {\n                _3241 = _3207 < 1.0;\n            }\n            else\n            {\n                _3241 = _3235;\n            }\n            if (_3241)\n            {\n                vec4 _3267 = texelFetch(fa_screen_tex_fa_shadow_smp, clamp(ivec2(vec2(_3203, _3207) * fa_mesh_fs_params[24].zw), ivec2(0), ivec2(fa_mesh_fs_params[24].zw) - ivec2(1)), 0);\n                float _3277 = dot(fa_mesh_fs_params[29].xyz, fa_world_pos) + fa_mesh_fs_params[29].w;\n                bool _3280 = _3267.w > 0.5;\n                bool _3294;\n                if (_3280)\n                {\n                    _3294 = abs(_3277 - _3267.x) <= ((0.00200000009499490261077880859375 * _3277) + 0.00999999977648258209228515625);\n                }\n                else\n                {\n                    _3294 = _3280;\n                }\n                if (_3294)\n                {\n                    return _3267.y;\n                }\n            }\n        }\n    }\n    vec3 param = fa_world_pos;\n    vec3 param_1 = n;\n    vec3 param_2 = l;\n    return fa_shadow_sun(param, param_1, param_2);\n}\n\nfloat fa_contact_shadow(int li, vec3 world, vec3 gn, vec3 l, float dist)\n{\n    bool _4573 = fa_mesh_fs_params[24].x < 0.5;\n    bool _4580;\n    if (!_4573)\n    {\n        _4580 = fa_shadows[29].x < 0.5;\n    }\n    else\n    {\n        _4580 = _4573;\n    }\n    if (_4580)\n    {\n        return 1.0;\n    }\n    int param = (int(fa_shadows[29].x + 0.5) - 1) + li;\n    vec4 _4593 = fa_light_texel(param);\n    float _4594 = _4593.y;\n    float len = _4594;\n    if (_4594 <= 0.0)\n    {\n        return 1.0;\n    }\n    float _4606 = length(world - fa_mesh_fs_params[0].xyz);\n    float _4615 = 1.0 - smoothstep(0.5 * fa_mesh_fs_params[25].x, fa_mesh_fs_params[25].x, _4606);\n    if (_4615 <= 0.0)\n    {\n        return 1.0;\n    }\n    float _4621 = len;\n    float _4624 = min(_4621, 0.89999997615814208984375 * dist);\n    len = _4624;\n    float _4629 = 0.004999999888241291046142578125 + (0.0030000000260770320892333984375 * _4606);\n    float _4634 = _4629 + (0.5 * _4624);\n    vec3 _4640 = world + (gn * _4629);\n    float _4642 = fa_shadow_noise();\n    float occ = 0.0;\n    float _4703;\n    for (int k = 0; k < 12; k++)\n    {\n        float _4657 = (float(k) + _4642) * 0.083333335816860198974609375;\n        vec3 _4665 = _4640 + (l * (_4657 * len));\n        vec4 _4671 = vec4(_4665, 1.0);\n        float _4676 = dot(fa_mesh_fs_params[28], _4671);\n        if (_4676 < 9.9999997473787516355514526367188e-05)\n        {\n            break;\n        }\n        vec2 _4694 = vec2(dot(fa_mesh_fs_params[26], _4671), dot(fa_mesh_fs_params[27], _4671)) / vec2(_4676);\n        float _4698 = _4694.x * 0.5;\n        float _4699 = _4698 + 0.5;\n        if (fa_mesh_fs_params[24].y > 0.5)\n        {\n            _4703 = (_4694.y * 0.5) + 0.5;\n        }\n        else\n        {\n            _4703 = 0.5 - (_4694.y * 0.5);\n        }\n        bool _4719 = _4699 < 0.0;\n        bool _4726;\n        if (!_4719)\n        {\n            _4726 = _4699 >= 1.0;\n        }\n        else\n        {\n            _4726 = _4719;\n        }\n        bool _4733;\n        if (!_4726)\n        {\n            _4733 = _4703 < 0.0;\n        }\n        else\n        {\n            _4733 = _4726;\n        }\n        bool _4740;\n        if (!_4733)\n        {\n            _4740 = _4703 >= 1.0;\n        }\n        else\n        {\n            _4740 = _4733;\n        }\n        if (_4740)\n        {\n            break;\n        }\n        vec4 _4764 = texelFetch(fa_screen_tex_fa_shadow_smp, clamp(ivec2(vec2(_4699, _4703) * fa_mesh_fs_params[24].zw), ivec2(0), ivec2(fa_mesh_fs_params[24].zw) - ivec2(1)), 0);\n        if (_4764.w < 0.5)\n        {\n            continue;\n        }\n        float _4782 = (dot(fa_mesh_fs_params[29].xyz, _4665) + fa_mesh_fs_params[29].w) - _4764.x;\n        if ((_4782 > _4629) && (_4782 < _4634))\n        {\n            occ = max(occ, (1.0 - (_4657 * _4657)) * smoothstep(0.0, 0.0500000007450580596923828125, min(min(_4699, 0.5 - _4698), min(_4703, 1.0 - _4703))));\n        }\n    }\n    return 1.0 - (occ * _4615);\n}\n\nLightSample fa_light_shadowed(int li, vec3 world_pos, vec3 gn)\n{\n    int param = li;\n    float _4885 = fa_baked_keep(param);\n    if (_4885 <= 0.0)\n    {\n        int param_1 = li;\n        return LightSample(vec3(0.0, 1.0, 0.0), vec3(0.0), 0.0, 1.0, 0.0, int(fa_light_type(param_1) + 0.5));\n    }\n    int param_2 = li;\n    vec3 param_3 = world_pos;\n    vec3 param_4 = gn;\n    LightSample _4911 = fa_light_sample_n(param_2, param_3, param_4);\n    vec3 _6181 = _4911.color;\n    float _6182 = _4911.attenuation;\n    float _6183 = _4911.shadow;\n    bool _4914 = _4911.type == 0;\n    if (_4914 && (li == 0))\n    {\n        vec3 param_5 = gn;\n        vec3 param_6 = _4911.direction;\n        float _4925 = fa_shadow_factor(param_5, param_6);\n        _6183 = _4925;\n        _6181 *= _4925;\n    }\n    else\n    {\n        bool _4936 = _4911.type != 0;\n        bool _4942;\n        if (_4936)\n        {\n            _4942 = _6182 > 0.0;\n        }\n        else\n        {\n            _4942 = _4936;\n        }\n        if (_4942)\n        {\n            int param_7 = li;\n            int param_8 = fa_light_base(param_7);\n            int param_9 = li;\n            vec3 param_10 = fa_light_texel(param_8).xyz;\n            vec3 param_11 = world_pos;\n            vec3 param_12 = gn;\n            vec3 param_13 = _4911.direction;\n            float _4961 = fa_shadow_local(param_9, param_10, param_11, param_12, param_13);\n            _6183 = _4961;\n            _6181 *= _4961;\n        }\n    }\n    bool _4971 = fa_mesh_fs_params[24].x > 0.5;\n    bool _4977;\n    if (_4971)\n    {\n        _4977 = _6182 > 0.0;\n    }\n    else\n    {\n        _4977 = _4971;\n    }\n    if (_4977)\n    {\n        float _4984;\n        if (_4914)\n        {\n            _4984 = 1000000000.0;\n        }\n        else\n        {\n            _4984 = _4911._distance;\n        }\n        int param_14 = li;\n        vec3 param_15 = world_pos;\n        vec3 param_16 = gn;\n        vec3 param_17 = _4911.direction;\n        float param_18 = _4984;\n        float _5002 = fa_contact_shadow(param_14, param_15, param_16, param_17, param_18);\n        _6183 *= _5002;\n        _6181 *= _5002;\n    }\n    float _5015 = _6182;\n    float _5016 = _5015 * _4885;\n    _6182 = _5016;\n    vec3 _5020 = _6181;\n    vec3 _5021 = _5020 * _4885;\n    _6181 = _5021;\n    return LightSample(_4911.direction, _5021, _5016, _6183, _4911._distance, _4911.type);\n}\n\nLightSample fa_light(int n, SurfaceInput i)\n{\n    bool _5032 = n < 0;\n    bool _5039;\n    if (!_5032)\n    {\n        _5039 = n >= fa_light_count();\n    }\n    else\n    {\n        _5039 = _5032;\n    }\n    if (_5039)\n    {\n        return fa_no_light();\n    }\n    int param = n;\n    int param_1 = fa_cl_light(param);\n    vec3 param_2 = i.world_pos;\n    vec3 param_3 = i.world_normal;\n    LightSample _5054 = fa_light_shadowed(param_1, param_2, param_3);\n    return _5054;\n}\n\nfloat fa_sheen_albedo(float ndv, float rough)\n{\n    float _3958 = min(sqrt(max(rough - 0.100000001490116119384765625, 0.0) * 1.111111164093017578125) * 6.0, 5.999000072479248046875);\n    float _3966 = min(sqrt(clamp(ndv, 0.0, 1.0)) * 8.0, 7.999000072479248046875);\n    int _3969 = int(_3958);\n    int _3972 = int(_3966);\n    float _3982 = _3966 - float(_3972);\n    int _4038 = (_3969 * 9) + _3972;\n    int _4058 = ((_3969 + 1) * 9) + _3972;\n    return mix(mix(_4033[_4038], _4033[_4038 + 1], _3982), mix(_4033[_4058], _4033[_4058 + 1], _3982), _3958 - float(_3969));\n}\n\nFaLayers fa_layers_setup(SurfaceInput i, Surface s, vec3 n, vec3 v, float metallic, float roughness, inout vec3 f0)\n{\n    bool _6047 = false;\n    float _6048 = 1.0;\n    float _6049 = 1.0;\n    float _6050 = 1.0;\n    float _6051 = 0.0;\n    float _6052 = 0.0;\n    float _6053 = 0.0;\n    float _6054 = 0.0;\n    float _6056 = 1.0;\n    bool _6057 = false;\n    vec3 _6058 = vec3(0.0);\n    float _6059 = 1.0;\n    float _6060 = 1.0;\n    float _6061 = 1.0;\n    float _6062 = 0.0;\n    float _6063 = 0.0;\n    vec3 _6064 = vec3(1.0, 0.0, 0.0);\n    vec3 _6065 = vec3(0.0, 0.0, 1.0);\n    float _6066 = 1.0;\n    float _6067 = 1.0;\n    float _4109 = clamp(s.specular, 0.0, 1.0);\n    float _4113 = clamp(s.ior, 1.0, 3.0);\n    bool _4118 = (_4109 != 1.0) || (_4113 != 1.5);\n    bool _4127;\n    if (!_4118)\n    {\n        _4127 = any(notEqual(s.specular_color, vec3(1.0)));\n    }\n    else\n    {\n        _4127 = _4118;\n    }\n    if (_4127)\n    {\n        float _4135 = (_4113 - 1.0) / (_4113 + 1.0);\n        f0 = mix(min(vec3(_4135 * _4135) * max(s.specular_color, vec3(0.0)), vec3(1.0)) * _4109, s.albedo, vec3(metallic));\n        _6048 = mix(_4109, 1.0, metallic);\n        _6047 = true;\n    }\n    float _4162 = clamp(s.clearcoat, 0.0, 1.0);\n    if (_4162 > 0.0)\n    {\n        float _4170 = clamp(s.clearcoat_roughness, 0.0500000007450580596923828125, 1.0);\n        _6051 = _4162;\n        _6052 = _4170;\n        float _4177 = _4170 * _4170;\n        _6053 = _4177;\n        _6054 = _4177 * _4177;\n        float _4189 = max(dot(i.world_normal, v), 9.9999997473787516355514526367188e-05);\n        _6056 = _4189;\n        _6049 = 1.0 - (_4162 * (0.039999999105930328369140625 + (0.959999978542327880859375 * pow(clamp(1.0 - _4189, 0.0, 1.0), 5.0))));\n        _6047 = true;\n    }\n    vec3 _4208 = max(s.sheen_color, vec3(0.0));\n    float _4217 = max(_4208.x, max(_4208.y, _4208.z));\n    if (_4217 > 0.0)\n    {\n        float _4225 = clamp(s.sheen_roughness, 0.100000001490116119384765625, 1.0);\n        _6057 = true;\n        _6058 = _4208;\n        _6059 = _4225;\n        _6060 = _4225 * _4225;\n        float param = max(dot(n, v), 9.9999997473787516355514526367188e-05);\n        float param_1 = _4225;\n        float _4242 = fa_sheen_albedo(param, param_1);\n        _6062 = _4242;\n        _6061 = 1.0 - min(_4217 * _4242, 1.0);\n        _6047 = true;\n    }\n    _6050 = _6049 * _6061;\n    float _4261 = clamp(s.anisotropy, -1.0, 1.0);\n    if (_4261 != 0.0)\n    {\n        vec3 _4276 = i.world_tangent.xyz - (n * dot(n, i.world_tangent.xyz));\n        vec3 t = _4276;\n        if (dot(_4276, _4276) < 9.9999999392252902907785028219223e-09)\n        {\n            bvec3 _4288 = bvec3(abs(n.y) < 0.9900000095367431640625);\n            t = cross(vec3(_4288.x ? vec3(0.0, 1.0, 0.0).x : vec3(1.0, 0.0, 0.0).x, _4288.y ? vec3(0.0, 1.0, 0.0).y : vec3(1.0, 0.0, 0.0).y, _4288.z ? vec3(0.0, 1.0, 0.0).z : vec3(1.0, 0.0, 0.0).z), n);\n        }\n        vec3 _4292 = t;\n        vec3 _4293 = normalize(_4292);\n        t = _4293;\n        vec3 _4318 = normalize((_4293 * cos(s.anisotropy_rotation)) + ((cross(n, _4293) * ((i.world_tangent.w < 0.0) ? (-1.0) : 1.0)) * sin(s.anisotropy_rotation)));\n        _6064 = _4318;\n        _6065 = cross(n, _4318);\n        float _4328 = roughness * roughness;\n        float _4334 = mix(_4328, 1.0, _4261 * _4261);\n        bool _4336 = _4261 > 0.0;\n        _6066 = _4336 ? _4334 : _4328;\n        _6067 = _4336 ? _4328 : _4334;\n        _6063 = _4261;\n        _6047 = true;\n    }\n    return FaLayers(_6047, _6048, _6049, _6050, _6051, _6052, _6053, _6054, i.world_normal, _6056, _6057, _6058, _6059, _6060, _6061, _6062, _6063, _6064, _6065, _6066, _6067);\n}\n\nvec2 fa_env_brdf(float rough, float ndv)\n{\n    vec4 _3890 = (vec4(-1.0, -0.0274999998509883880615234375, -0.572000026702880859375, 0.02199999988079071044921875) * rough) + vec4(1.0, 0.0425000004470348358154296875, 1.03999996185302734375, -0.039999999105930328369140625);\n    float _3893 = _3890.x;\n    return (vec2(-1.03999996185302734375, 1.03999996185302734375) * ((min(_3893 * _3893, exp2((-9.27999973297119140625) * ndv)) * _3893) + _3890.y)) + _3890.zw;\n}\n\nvec2 fa_oct_encode(vec3 d)\n{\n    vec3 _3326 = d / vec3(max((abs(d.x) + abs(d.y)) + abs(d.z), 9.9999999600419720025001879548654e-13));\n    float _3329 = _3326.x;\n    float _3331 = _3326.z;\n    vec2 e = vec2(_3329, _3331);\n    if (_3326.y < 0.0)\n    {\n        e = vec2((1.0 - abs(_3331)) * ((_3329 < 0.0) ? (-1.0) : 1.0), (1.0 - abs(_3329)) * ((_3331 < 0.0) ? (-1.0) : 1.0));\n    }\n    return e;\n}\n\nvec2 fa_atlas_size()\n{\n    return vec2(textureSize(fa_probe_atlas_fa_env_smp, 0));\n}\n\nvec3 fa_probe_level(vec2 origin, float res, int lv, vec2 e)\n{\n    float _3378;\n    if (lv == 0)\n    {\n        _3378 = 0.0;\n    }\n    else\n    {\n        _3378 = res + 2.0;\n    }\n    float _3388;\n    if (lv == 0)\n    {\n        _3388 = 0.0;\n    }\n    else\n    {\n        _3388 = (res - (res / float(1 << max((lv - 1), 0)))) + (2.0 * float(lv - 1));\n    }\n    return textureLod(fa_probe_atlas_fa_env_smp, (((origin + vec2(_3378, _3388)) + vec2(1.0)) + (((e * 0.5) + vec2(0.5)) * (res / float(1 << lv)))) / fa_atlas_size(), 0.0).xyz;\n}\n\nvec3 fa_probe_radiance(vec2 origin, float res, vec3 d, float rough)\n{\n    float _3434;\n    if (res > 64.5)\n    {\n        _3434 = 5.0;\n    }\n    else\n    {\n        _3434 = (res > 32.5) ? 4.0 : 3.0;\n    }\n    float _3449 = clamp(rough, 0.0, 1.0) * (_3434 - 1.0);\n    int _3456 = int(min(floor(_3449), _3434 - 2.0));\n    float _3461 = _3449 - float(_3456);\n    vec3 param = d;\n    vec2 _3465 = fa_oct_encode(param);\n    vec2 param_1 = origin;\n    float param_2 = res;\n    int param_3 = _3456;\n    vec2 param_4 = _3465;\n    vec3 _3475 = fa_probe_level(param_1, param_2, param_3, param_4);\n    if (_3461 < 0.00200000009499490261077880859375)\n    {\n        return _3475;\n    }\n    vec2 param_5 = origin;\n    float param_6 = res;\n    int param_7 = _3456 + 1;\n    vec2 param_8 = _3465;\n    return mix(_3475, fa_probe_level(param_5, param_6, param_7, param_8), vec3(_3461));\n}\n\nvec3 fa_probe_box_dir(vec3 d, vec4 posw, vec4 bx, vec4 by, vec4 bz)\n{\n    if (posw.w < 0.5)\n    {\n        return d;\n    }\n    float _3512 = dot(bx.xyz, fa_world_pos) + bx.w;\n    float _3519 = dot(by.xyz, fa_world_pos) + by.w;\n    float _3526 = dot(bz.xyz, fa_world_pos) + bz.w;\n    float _3532 = dot(bx.xyz, d);\n    float _3536 = dot(by.xyz, d);\n    float _3540 = dot(bz.xyz, d);\n    float _3546;\n    if (_3532 > 9.9999999747524270787835121154785e-07)\n    {\n        _3546 = (1.0 - _3512) / _3532;\n    }\n    else\n    {\n        float _3560;\n        if (_3532 < (-9.9999999747524270787835121154785e-07))\n        {\n            _3560 = ((-1.0) - _3512) / _3532;\n        }\n        else\n        {\n            _3560 = 1000000015047466219876688855040.0;\n        }\n        _3546 = _3560;\n    }\n    float tx = _3546;\n    float _3577;\n    if (_3536 > 9.9999999747524270787835121154785e-07)\n    {\n        _3577 = (1.0 - _3519) / _3536;\n    }\n    else\n    {\n        float _3590;\n        if (_3536 < (-9.9999999747524270787835121154785e-07))\n        {\n            _3590 = ((-1.0) - _3519) / _3536;\n        }\n        else\n        {\n            _3590 = 1000000015047466219876688855040.0;\n        }\n        _3577 = _3590;\n    }\n    float ty = _3577;\n    float _3606;\n    if (_3540 > 9.9999999747524270787835121154785e-07)\n    {\n        _3606 = (1.0 - _3526) / _3540;\n    }\n    else\n    {\n        float _3619;\n        if (_3540 < (-9.9999999747524270787835121154785e-07))\n        {\n            _3619 = ((-1.0) - _3526) / _3540;\n        }\n        else\n        {\n            _3619 = 1000000015047466219876688855040.0;\n        }\n        _3606 = _3619;\n    }\n    float _3631 = tx;\n    float _3634 = (_3631 > 0.0) ? _3631 : 1000000015047466219876688855040.0;\n    tx = _3634;\n    float _3635 = ty;\n    float _3638 = (_3635 > 0.0) ? _3635 : 1000000015047466219876688855040.0;\n    ty = _3638;\n    float _3648 = min(_3634, min(_3638, (_3606 > 0.0) ? _3606 : 1000000015047466219876688855040.0));\n    if (_3648 > 100000001504746621987668885504.0)\n    {\n        return d;\n    }\n    vec3 _3664 = (fa_world_pos + (d * _3648)) - posw.xyz;\n    vec3 _3669;\n    if (dot(_3664, _3664) > 1.0000000133514319600180897396058e-10)\n    {\n        _3669 = normalize(_3664);\n    }\n    else\n    {\n        _3669 = d;\n    }\n    return _3669;\n}\n\nvec3 fa_probe_environment(vec4 tile, vec4 posw, vec4 bx, vec4 by, vec4 bz, inout vec3 d, float rough)\n{\n    vec3 param = d;\n    vec4 param_1 = posw;\n    vec4 param_2 = bx;\n    vec4 param_3 = by;\n    vec4 param_4 = bz;\n    d = fa_probe_box_dir(param, param_1, param_2, param_3, param_4);\n    vec2 param_5 = tile.xy;\n    float param_6 = tile.z;\n    vec3 param_7 = d;\n    float param_8 = rough;\n    return fa_probe_radiance(param_5, param_6, param_7, param_8);\n}\n\nvec3 fa_environment(vec3 d, float rough)\n{\n    float _3715 = (1.0 - fa_mesh_fs_params[42].w) - fa_mesh_fs_params[47].w;\n    vec3 outc = vec3(0.0);\n    if (_3715 > 0.0005000000237487256526947021484375)\n    {\n        vec3 base;\n        if (fa_mesh_fs_params[11].w > 0.5)\n        {\n            vec2 param = fa_mesh_fs_params[41].zw;\n            float param_1 = 128.0;\n            vec3 param_2 = d;\n            float param_3 = rough;\n            base = fa_probe_radiance(param, param_1, param_2, param_3);\n        }\n        else\n        {\n            float _3745 = rough * rough;\n            float _3776 = 0.60000002384185791015625 * _3745;\n            base = mix(mix(fa_mesh_fs_params[12].xyz * 0.550000011920928955078125, mix(fa_mesh_fs_params[12].xyz, fa_mesh_fs_params[11].xyz, vec3(pow(clamp(d.y * (1.0 - (0.699999988079071044921875 * _3745)), 0.0, 1.0), 0.550000011920928955078125))), vec3(smoothstep((-0.0500000007450580596923828125) - _3776, 0.0500000007450580596923828125 + _3776, d.y))), ((fa_mesh_fs_params[11].xyz + fa_mesh_fs_params[12].xyz) * 0.5) * 0.800000011920928955078125, vec3(_3745 * 0.60000002384185791015625));\n        }\n        outc = base * _3715;\n    }\n    if (fa_mesh_fs_params[42].w > 0.0)\n    {\n        vec4 param_4 = fa_mesh_fs_params[42];\n        vec4 param_5 = fa_mesh_fs_params[43];\n        vec4 param_6 = fa_mesh_fs_params[44];\n        vec4 param_7 = fa_mesh_fs_params[45];\n        vec4 param_8 = fa_mesh_fs_params[46];\n        vec3 param_9 = d;\n        float param_10 = rough;\n        vec3 _3835 = fa_probe_environment(param_4, param_5, param_6, param_7, param_8, param_9, param_10);\n        outc += (_3835 * fa_mesh_fs_params[42].w);\n    }\n    if (fa_mesh_fs_params[47].w > 0.0)\n    {\n        vec4 param_11 = fa_mesh_fs_params[47];\n        vec4 param_12 = fa_mesh_fs_params[48];\n        vec4 param_13 = fa_mesh_fs_params[49];\n        vec4 param_14 = fa_mesh_fs_params[50];\n        vec4 param_15 = fa_mesh_fs_params[51];\n        vec3 param_16 = d;\n        float param_17 = rough;\n        vec3 _3867 = fa_probe_environment(param_11, param_12, param_13, param_14, param_15, param_16, param_17);\n        outc += (_3867 * fa_mesh_fs_params[47].w);\n    }\n    return outc;\n}\n\nvec3 fa_layers_ibl(FaLayers L, vec3 n, vec3 v, vec3 f0, float roughness, float occlusion)\n{\n    vec3 rn = n;\n    if (L.aniso != 0.0)\n    {\n        vec3 _4369;\n        if (L.aniso >= 0.0)\n        {\n            _4369 = L.b;\n        }\n        else\n        {\n            _4369 = L.t;\n        }\n        rn = normalize(mix(n, cross(cross(_4369, v), _4369), vec3(abs(L.aniso) * smoothstep(0.0, 0.25, roughness))));\n    }\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05);\n    vec2 _4405 = fa_env_brdf(param, param_1);\n    vec3 param_2 = reflect(-v, rn);\n    float param_3 = roughness;\n    vec3 result = (fa_environment(param_2, param_3) * ((f0 * _4405.x) + (vec3(L.f90) * _4405.y))) * L.base_scale;\n    if (L.sheen_on)\n    {\n        vec3 param_4 = n;\n        float param_5 = L.sheen_rough;\n        result += ((L.sheen * (L.sheen_e * L.keep)) * fa_environment(param_4, param_5));\n    }\n    result *= occlusion;\n    if (L.coat > 0.0)\n    {\n        float param_6 = L.coat_rough;\n        float param_7 = L.coat_ndv;\n        vec2 _4463 = fa_env_brdf(param_6, param_7);\n        vec3 param_8 = reflect(-v, L.nc);\n        float param_9 = L.coat_rough;\n        result += (fa_environment(param_8, param_9) * (L.coat * ((0.039999999105930328369140625 * _4463.x) + _4463.y)));\n    }\n    return result;\n}\n\nvec3 fa_sky_reflection(vec3 n, vec3 v, vec3 f0, float roughness)\n{\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05);\n    vec2 _3932 = fa_env_brdf(param, param_1);\n    vec3 param_2 = reflect(-v, n);\n    float param_3 = roughness;\n    return fa_environment(param_2, param_3) * ((f0 * _3932.x) + vec3(_3932.y));\n}\n\nvec3 fa_sky_light(SurfaceInput i, Surface s)\n{\n    float _4502 = clamp(s.metallic, 0.0, 1.0);\n    float _4506 = clamp(s.roughness, 0.0500000007450580596923828125, 1.0);\n    vec3 _4513 = mix(vec3(0.039999999105930328369140625), s.albedo, vec3(_4502));\n    vec3 f0 = _4513;\n    vec3 _4517 = normalize(s.normal);\n    SurfaceInput param = i;\n    Surface param_1 = s;\n    vec3 param_2 = _4517;\n    vec3 param_3 = i.view_dir;\n    float param_4 = _4502;\n    float param_5 = _4506;\n    vec3 param_6 = _4513;\n    FaLayers _4534 = fa_layers_setup(param, param_1, param_2, param_3, param_4, param_5, param_6);\n    f0 = param_6;\n    if (_4534.on)\n    {\n        FaLayers param_7 = _4534;\n        vec3 param_8 = _4517;\n        vec3 param_9 = i.view_dir;\n        vec3 param_10 = f0;\n        float param_11 = _4506;\n        float param_12 = s.occlusion;\n        return fa_layers_ibl(param_7, param_8, param_9, param_10, param_11, param_12);\n    }\n    vec3 param_13 = _4517;\n    vec3 param_14 = i.view_dir;\n    vec3 param_15 = f0;\n    float param_16 = _4506;\n    return fa_sky_reflection(param_13, param_14, param_15, param_16) * s.occlusion;\n}\n\nvec3 lighting(SurfaceInput i, Surface s)\n{\n    int best = -1;\n    float bestPower = 0.0;\n    for (int n = 0; n < fa_light_count(); n++)\n    {\n        int param = n;\n        SurfaceInput param_1 = i;\n        LightSample _5124 = fa_light_unshadowed(param, param_1);\n        float _5132 = dot(_5124.color, vec3(0.2989999949932098388671875, 0.58700001239776611328125, 0.114000000059604644775390625));\n        if (_5132 > bestPower)\n        {\n            bestPower = _5132;\n            best = n;\n        }\n    }\n    vec3 lit = (fa_mesh_fs_params[1].xyz * s.albedo) * s.occlusion;\n    if (best >= 0)\n    {\n        int param_2 = best;\n        SurfaceInput param_3 = i;\n        LightSample _5161 = fa_light(param_2, param_3);\n        float _5169;\n        if (dot(s.normal, _5161.direction) > 0.5)\n        {\n            _5169 = 1.0;\n        }\n        else\n        {\n            _5169 = fa_material[0].x;\n        }\n        lit += ((s.albedo * _5161.color) * _5169);\n    }\n    SurfaceInput param_4 = i;\n    Surface param_5 = s;\n    return lit + (fa_sky_light(param_4, param_5) * fa_material[1].x);\n}\n\nvec3 fa_shadow_debug(vec3 color, vec3 world)\n{\n    if (fa_shadows[27].w < 0.5)\n    {\n        return color;\n    }\n    int _3080 = int(fa_shadows[25].x + 0.5);\n    float _3090 = dot(world - fa_shadows[27].xyz, fa_shadows[28].xyz);\n    vec3 tint = vec3(0.3499999940395355224609375);\n    bool _3095 = _3080 > 0;\n    bool _3104;\n    if (_3095)\n    {\n        int param = _3080 - 1;\n        _3104 = _3090 <= fa_shadow_split_at(param);\n    }\n    else\n    {\n        _3104 = _3095;\n    }\n    if (_3104)\n    {\n        tint = vec3(1.0, 0.1500000059604644775390625, 0.100000001490116119384765625);\n        bool _3110 = _3080 > 1;\n        bool _3117;\n        if (_3110)\n        {\n            _3117 = _3090 > fa_shadows[24].x;\n        }\n        else\n        {\n            _3117 = _3110;\n        }\n        if (_3117)\n        {\n            tint = vec3(0.100000001490116119384765625, 0.89999997615814208984375, 0.20000000298023223876953125);\n        }\n        bool _3123 = _3080 > 2;\n        bool _3130;\n        if (_3123)\n        {\n            _3130 = _3090 > fa_shadows[24].y;\n        }\n        else\n        {\n            _3130 = _3123;\n        }\n        if (_3130)\n        {\n            tint = vec3(0.1500000059604644775390625, 0.300000011920928955078125, 1.0);\n        }\n        bool _3136 = _3080 > 3;\n        bool _3143;\n        if (_3136)\n        {\n            _3143 = _3090 > fa_shadows[24].z;\n        }\n        else\n        {\n            _3143 = _3136;\n        }\n        if (_3143)\n        {\n            tint = vec3(1.0, 0.89999997615814208984375, 0.100000001490116119384765625);\n        }\n    }\n    return mix(color, tint, vec3(0.550000011920928955078125));\n}\n\nvoid main()\n{\n    fa_inst_load();\n    vec3 _5901 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _5901 = -_5901;\n    }\n    vec3 _5571 = normalize(fa_mesh_fs_params[0].xyz - fa_world_pos);\n    vec3 param = fa_world_pos;\n    fa_cluster_begin(param);\n    SurfaceInput param_1 = SurfaceInput(fa_world_pos, _5901, fa_world_tangent, fa_uv, fa_vertex_color, _5571, gl_FrontFacing);\n    Surface _5579 = fa_standard_surface(param_1);\n    vec3 _5932 = _5579.albedo;\n    float _5933 = _5579.alpha;\n    vec3 _5934 = _5579.normal;\n    float _5935 = _5579.metallic;\n    float _5936 = _5579.roughness;\n    float _5937 = _5579.occlusion;\n    vec3 _5938 = _5579.emission;\n    float _5939 = _5579.clearcoat;\n    float _5940 = _5579.clearcoat_roughness;\n    vec3 _5941 = _5579.sheen_color;\n    float _5942 = _5579.sheen_roughness;\n    float _5943 = _5579.anisotropy;\n    float _5944 = _5579.anisotropy_rotation;\n    float _5945 = _5579.specular;\n    float _5946 = _5579.ior;\n    vec3 _5947 = _5579.specular_color;\n    float _5948 = _5579.transmission;\n    float _5949 = _5579.thickness;\n    vec3 _5950 = _5579.attenuation_color;\n    float _5951 = _5579.attenuation_distance;\n    SurfaceInput param_2 = SurfaceInput(fa_world_pos, _5901, fa_world_tangent, fa_uv, fa_vertex_color, _5571, gl_FrontFacing);\n    Surface param_3 = _5579;\n    surface(param_2, param_3);\n    _5932 = param_3.albedo;\n    _5933 = param_3.alpha;\n    _5934 = param_3.normal;\n    _5935 = param_3.metallic;\n    _5936 = param_3.roughness;\n    _5937 = param_3.occlusion;\n    _5938 = param_3.emission;\n    _5939 = param_3.clearcoat;\n    _5940 = param_3.clearcoat_roughness;\n    _5941 = param_3.sheen_color;\n    _5942 = param_3.sheen_roughness;\n    _5943 = param_3.anisotropy;\n    _5944 = param_3.anisotropy_rotation;\n    _5945 = param_3.specular;\n    _5946 = param_3.ior;\n    _5947 = param_3.specular_color;\n    _5948 = param_3.transmission;\n    _5949 = param_3.thickness;\n    _5950 = param_3.attenuation_color;\n    _5951 = param_3.attenuation_distance;\n    vec3 param_4 = fa_world_pos;\n    vec3 param_5 = _5901;\n    vec3 param_6 = param_3.albedo;\n    vec3 param_7 = param_3.normal;\n    fa_apply_decals(param_4, param_5, param_6, param_7);\n    _5932 = param_6;\n    _5934 = param_7;\n    vec3 result;\n    if (fa_mesh_fs_params[3].w > 0.5)\n    {\n        result = _5932;\n    }\n    else\n    {\n        vec3 _5618 = _5934;\n        vec3 _5619 = normalize(_5618);\n        _5934 = _5619;\n        SurfaceInput param_8 = SurfaceInput(fa_world_pos, _5901, fa_world_tangent, fa_uv, fa_vertex_color, _5571, gl_FrontFacing);\n        Surface param_9 = Surface(_5932, _5933, _5619, _5935, _5936, _5937, _5938, _5939, _5940, _5941, _5942, _5943, _5944, _5945, _5946, _5947, _5948, _5949, _5950, _5951);\n        vec3 _5630 = lighting(param_8, param_9);\n        result = _5630;\n    }\n    vec3 _5634 = result;\n    vec3 _5635 = _5634 + _5938;\n    result = _5635;\n    vec3 param_10 = _5635;\n    vec3 param_11 = fa_world_pos;\n    result = fa_shadow_debug(param_10, param_11);\n    bool _5644 = fa_mesh_fs_params[7].w > 0.0;\n    bool _5651;\n    if (!_5644)\n    {\n        _5651 = fa_mesh_fs_params[8].y > 0.0;\n    }\n    else\n    {\n        _5651 = _5644;\n    }\n    if (_5651)\n    {\n        vec3 _5660 = fa_world_pos - fa_mesh_fs_params[0].xyz;\n        float _5666 = dot(_5660, fa_mesh_fs_params[9].xyz);\n        bool _5670 = fa_mesh_fs_params[9].w > 0.5;\n        float _5671;\n        if (_5670)\n        {\n            _5671 = _5666;\n        }\n        else\n        {\n            _5671 = length(_5660);\n        }\n        float _5683 = _5671 - fa_mesh_fs_params[8].x;\n        if (_5683 > 0.0)\n        {\n            float _5692 = fa_mesh_fs_params[7].w * _5683;\n            float tau = _5692 * _5692;\n            if (fa_mesh_fs_params[8].y > 0.0)\n            {\n                float _5708;\n                if (_5670)\n                {\n                    _5708 = fa_world_pos.y - (fa_mesh_fs_params[9].y * _5666);\n                }\n                else\n                {\n                    _5708 = fa_mesh_fs_params[0].y;\n                }\n                float _5729 = mix(_5708, fa_world_pos.y, clamp(fa_mesh_fs_params[8].x / _5671, 0.0, 1.0));\n                float _5733 = fa_world_pos.y - _5729;\n                float _5738 = _5729 - fa_mesh_fs_params[8].z;\n                float _5743 = fa_world_pos.y - fa_mesh_fs_params[8].z;\n                bool _5746 = _5738 <= 0.0;\n                bool _5747 = !_5746;\n                bool _5753;\n                if (_5747)\n                {\n                    _5753 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _5753 = _5746;\n                }\n                float _5754;\n                if (_5753)\n                {\n                    _5754 = fa_mesh_fs_params[8].y;\n                }\n                else\n                {\n                    _5754 = fa_mesh_fs_params[8].y * exp(-min(fa_mesh_fs_params[8].w * _5738, 80.0));\n                }\n                bool _5781;\n                if (_5747)\n                {\n                    _5781 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _5781 = _5746;\n                }\n                float _5782;\n                if (_5781)\n                {\n                    _5782 = fa_mesh_fs_params[8].y * _5738;\n                }\n                else\n                {\n                    _5782 = (fa_mesh_fs_params[8].y * (1.0 - exp(-min(fa_mesh_fs_params[8].w * _5738, 80.0)))) / fa_mesh_fs_params[8].w;\n                }\n                bool _5807 = _5743 <= 0.0;\n                bool _5814;\n                if (!_5807)\n                {\n                    _5814 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _5814 = _5807;\n                }\n                float _5815;\n                if (_5814)\n                {\n                    _5815 = fa_mesh_fs_params[8].y * _5743;\n                }\n                else\n                {\n                    _5815 = (fa_mesh_fs_params[8].y * (1.0 - exp(-min(fa_mesh_fs_params[8].w * _5743, 80.0)))) / fa_mesh_fs_params[8].w;\n                }\n                float _5842;\n                if (abs(_5733) < 0.001000000047497451305389404296875)\n                {\n                    _5842 = _5754;\n                }\n                else\n                {\n                    _5842 = (_5815 - _5782) / _5733;\n                }\n                tau += (_5683 * max(_5842, 0.0));\n            }\n            result = mix(result, fa_mesh_fs_params[7].xyz, vec3(clamp(1.0 - exp(-clamp(tau, 0.0, 80.0)), 0.0, 1.0)));\n        }\n    }\n    fa_frag_color = vec4(result, _5933);\n}\n\n",
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
            "inst_name": "_5175",
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
      "vs": "#version 430\n\nstruct VertexData\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 color;\n    vec3 object_pos;\n};\n\nuniform vec4 fa_mesh_vs_params[11];\nuniform vec4 fa_vel_params[9];\nlayout(location = 0) out vec3 fa_world_pos;\nlayout(location = 1) out vec3 fa_world_normal;\nlayout(location = 2) out vec4 fa_world_tangent;\nlayout(location = 3) out vec2 fa_uv;\nlayout(location = 4) out vec4 fa_vertex_color;\nlayout(location = 5) out float fa_pre_depth;\nlayout(location = 6) out vec3 fa_pre_r0;\nlayout(location = 7) out vec3 fa_pre_r1;\nlayout(location = 8) out vec3 fa_pre_r2;\nlayout(location = 9) out vec3 fa_vel_cur;\nlayout(location = 10) out vec3 fa_vel_prev;\nlayout(location = 9) in vec4 fa_prev_r0;\nlayout(location = 10) in vec4 fa_prev_r1;\nlayout(location = 11) in vec4 fa_prev_r2;\nlayout(location = 5) in vec4 fa_inst_m0;\nlayout(location = 6) in vec4 fa_inst_m1;\nlayout(location = 7) in vec4 fa_inst_m2;\nlayout(location = 8) in vec4 fa_inst_m3;\nlayout(location = 0) in vec3 fa_position;\nlayout(location = 1) in vec3 fa_normal;\nlayout(location = 3) in vec4 fa_tangent;\nlayout(location = 2) in vec2 fa_texcoord0;\nlayout(location = 4) in vec4 fa_color;\nvec4 fa_vtime;\n\nvoid fa_inst_begin()\n{\n}\n\nvec4 fa_time_now()\n{\n    return fa_mesh_vs_params[9];\n}\n\nVertexData fa_vertex_data(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    vec3 _97 = cross(model[1].xyz, model[2].xyz);\n    float _101 = (dot(model[0].xyz, _97) < 0.0) ? (-1.0) : 1.0;\n    return VertexData((model * vec4(position, 1.0)).xyz, (((_97 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _101, vec4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _101), texcoord0 * fa_mesh_vs_params[8].xy, color, position);\n}\n\nmat4 fa_rows_to_mat4(vec4 r0, vec4 r1, vec4 r2)\n{\n    return mat4(vec4(r0.x, r1.x, r2.x, 0.0), vec4(r0.y, r1.y, r2.y, 0.0), vec4(r0.z, r1.z, r2.z, 0.0), vec4(r0.w, r1.w, r2.w, 1.0));\n}\n\nmat4 fa_prev_model()\n{\n    vec4 param = fa_prev_r0;\n    vec4 param_1 = fa_prev_r1;\n    vec4 param_2 = fa_prev_r2;\n    return fa_rows_to_mat4(param, param_1, param_2);\n}\n\nvoid fa_prepass_vertex(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color, bool has_prev)\n{\n    bool _231;\n    if (has_prev)\n    {\n        _231 = fa_vel_params[8].x > 0.5;\n    }\n    else\n    {\n        _231 = has_prev;\n    }\n    fa_vtime = fa_time_now();\n    mat4 param = model;\n    vec3 param_1 = position;\n    vec3 param_2 = normal;\n    vec4 param_3 = tangent;\n    vec2 param_4 = texcoord0;\n    vec4 param_5 = color;\n    VertexData _246 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    vec3 _458 = _246.world_pos;\n    mat4 _250 = mat4(fa_mesh_vs_params[4], fa_mesh_vs_params[5], fa_mesh_vs_params[6], fa_mesh_vs_params[7]);\n    vec4 _257 = vec4(_458, 1.0);\n    fa_world_pos = _458;\n    fa_world_normal = _246.world_normal;\n    fa_world_tangent = _246.world_tangent;\n    fa_uv = _246.uv;\n    fa_vertex_color = _246.color;\n    fa_pre_depth = -(_250 * _257).z;\n    fa_pre_r0 = vec3(_250[0].x, _250[1].x, _250[2].x);\n    fa_pre_r1 = vec3(_250[0].y, _250[1].y, _250[2].y);\n    fa_pre_r2 = vec3(_250[0].z, _250[1].z, _250[2].z);\n    gl_Position = mat4(fa_mesh_vs_params[0], fa_mesh_vs_params[1], fa_mesh_vs_params[2], fa_mesh_vs_params[3]) * _257;\n    fa_vel_cur = vec3(0.0, 0.0, 1.0);\n    fa_vel_prev = vec3(0.0);\n    if (_231)\n    {\n        vec4 _330 = vec4(position, 1.0);\n        fa_vel_cur = vec3((mat4(fa_vel_params[0], fa_vel_params[1], fa_vel_params[2], fa_vel_params[3]) * _257).xyw);\n        fa_vel_prev = vec3((mat4(fa_vel_params[4], fa_vel_params[5], fa_vel_params[6], fa_vel_params[7]) * vec4((_458 + (fa_prev_model() * _330).xyz) - (model * _330).xyz, 1.0)).xyw);\n    }\n}\n\nvoid main()\n{\n    fa_vtime = vec4(0.0);\n    fa_inst_begin();\n    mat4 param = mat4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3);\n    vec3 param_1 = fa_position;\n    vec3 param_2 = fa_normal;\n    vec4 param_3 = fa_tangent;\n    vec2 param_4 = fa_texcoord0;\n    vec4 param_5 = fa_color;\n    bool param_6 = true;\n    fa_prepass_vertex(param, param_1, param_2, param_3, param_4, param_5, param_6);\n}\n\n",
      "fs": "#version 430\n\nstruct SurfaceInput\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 vertex_color;\n    vec3 view_dir;\n    bool front_facing;\n};\n\nstruct Surface\n{\n    vec3 albedo;\n    float alpha;\n    vec3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    vec3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    vec3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    vec3 specular_color;\n    float transmission;\n    float thickness;\n    vec3 attenuation_color;\n    float attenuation_distance;\n};\n\nuniform vec4 fa_mesh_fs_params[53];\nlayout(binding = 0) uniform sampler2D fa_tex_fa_smp;\nlayout(binding = 1) uniform sampler2D fa_normal_tex_fa_smp;\nlayout(binding = 2) uniform sampler2D fa_mr_tex_fa_smp;\nlayout(binding = 3) uniform sampler2D fa_occlusion_tex_fa_smp;\nlayout(binding = 4) uniform sampler2D fa_emissive_tex_fa_smp;\n\nlayout(location = 0) in vec3 fa_world_pos;\nlayout(location = 1) in vec3 fa_world_normal;\nlayout(location = 2) in vec4 fa_world_tangent;\nlayout(location = 3) in vec2 fa_uv;\nlayout(location = 4) in vec4 fa_vertex_color;\nlayout(location = 6) in vec3 fa_pre_r0;\nlayout(location = 7) in vec3 fa_pre_r1;\nlayout(location = 8) in vec3 fa_pre_r2;\nlayout(location = 0) out vec4 fa_frag_color;\nlayout(location = 5) in float fa_pre_depth;\nlayout(location = 9) in vec3 fa_vel_cur;\nlayout(location = 10) in vec3 fa_vel_prev;\nlayout(location = 1) out vec2 fa_frag_velocity;\n\nvoid fa_inst_load()\n{\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nvec3 fa_linear_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_tex_fix(inout vec3 c, float mode)\n{\n    if (mode > 1.5)\n    {\n        vec3 param = c;\n        vec3 _172 = fa_linear_to_srgb(param);\n        c = _172;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            vec3 param_1 = c;\n            vec3 _181 = fa_srgb_to_linear(param_1);\n            c = _181;\n        }\n    }\n    return c;\n}\n\nvec3 fa_tangent_normal(SurfaceInput i, vec3 m)\n{\n    vec3 _56;\n    if (i.front_facing)\n    {\n        _56 = i.world_normal;\n    }\n    else\n    {\n        _56 = -i.world_normal;\n    }\n    vec3 _81 = normalize(i.world_tangent.xyz - (_56 * dot(_56, i.world_tangent.xyz)));\n    vec3 _109 = normalize(((_81 * m.x) + ((cross(_56, _81) * i.world_tangent.w) * m.y)) + (_56 * m.z));\n    vec3 _112;\n    if (i.front_facing)\n    {\n        _112 = _109;\n    }\n    else\n    {\n        _112 = -_109;\n    }\n    return _112;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    vec4 base_t = texture(fa_tex_fa_smp, i.uv, fa_mesh_fs_params[12].w);\n    float param = fa_mesh_fs_params[6].w;\n    float param_1 = 1.0;\n    vec3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    vec3 _230 = fa_tex_fix(param_2, param_3);\n    vec4 _892 = base_t;\n    _892.x = _230.x;\n    _892.y = _230.y;\n    _892.z = _230.z;\n    base_t = _892;\n    vec4 _246 = (_892 * fa_mesh_fs_params[2]) * i.vertex_color;\n    vec3 _847 = i.world_normal;\n    if (fa_mesh_fs_params[6].z > 0.5)\n    {\n        float param_4 = fa_mesh_fs_params[6].w;\n        float param_5 = 16.0;\n        vec3 param_6 = texture(fa_normal_tex_fa_smp, i.uv, fa_mesh_fs_params[12].w).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        vec3 _282 = fa_tex_fix(param_6, param_7);\n        vec3 _286 = (_282 * 2.0) - vec3(1.0);\n        vec2 _291 = _286.xy * fa_mesh_fs_params[6].x;\n        vec3 _900 = _286;\n        _900.x = _291.x;\n        _900.y = _291.y;\n        SurfaceInput param_8 = i;\n        vec3 param_9 = _900;\n        _847 = fa_tangent_normal(param_8, param_9);\n    }\n    vec4 mrt = texture(fa_mr_tex_fa_smp, i.uv, fa_mesh_fs_params[12].w);\n    float param_10 = fa_mesh_fs_params[6].w;\n    float param_11 = 64.0;\n    vec3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    vec3 _322 = fa_tex_fix(param_12, param_13);\n    vec4 _903 = mrt;\n    _903.x = _322.x;\n    _903.y = _322.y;\n    _903.z = _322.z;\n    mrt = _903;\n    vec4 _354 = texture(fa_occlusion_tex_fa_smp, i.uv, fa_mesh_fs_params[12].w);\n    float param_14 = fa_mesh_fs_params[6].w;\n    float param_15 = 256.0;\n    vec3 param_16 = _354.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    vec3 _366 = fa_tex_fix(param_16, param_17);\n    float param_18 = fa_mesh_fs_params[6].w;\n    float param_19 = 4.0;\n    vec3 param_20 = texture(fa_emissive_tex_fa_smp, i.uv, fa_mesh_fs_params[12].w).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    vec3 _398 = fa_tex_fix(param_20, param_21);\n    float _852 = fa_mesh_fs_params[20].x;\n    float _853 = fa_mesh_fs_params[20].y;\n    float _856 = fa_mesh_fs_params[20].z;\n    float _855 = fa_mesh_fs_params[21].w;\n    float _858 = fa_mesh_fs_params[22].x;\n    if (fa_mesh_fs_params[22].z > 0.5)\n    {\n        if (mod(fa_mesh_fs_params[22].z, 2.0) > 0.5)\n        {\n            _852 *= _366.y;\n            _853 *= _366.z;\n            _855 *= _354.w;\n        }\n        if (fa_mesh_fs_params[22].z > 1.5)\n        {\n            _856 *= mrt.x;\n            _858 *= mrt.w;\n        }\n    }\n    return Surface(_246.xyz, _246.w, _847, clamp(fa_mesh_fs_params[5].x * _322.z, 0.0, 1.0), clamp(fa_mesh_fs_params[5].y * _322.y, 0.0500000007450580596923828125, 1.0), 1.0 + (fa_mesh_fs_params[6].y * (_366.x - 1.0)), fa_mesh_fs_params[3].xyz + (fa_mesh_fs_params[4].xyz * _398), _852, _853, fa_mesh_fs_params[21].xyz, _855, _856, fa_mesh_fs_params[20].w, _858, fa_mesh_fs_params[22].y, fa_mesh_fs_params[23].xyz, fa_mesh_fs_params[30].x, fa_mesh_fs_params[30].y, fa_mesh_fs_params[31].xyz, fa_mesh_fs_params[30].z);\n}\n\nvoid surface(SurfaceInput i, Surface s)\n{\n}\n\nvoid main()\n{\n    fa_inst_load();\n    vec3 _742 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _742 = -_742;\n    }\n    vec3 _550 = normalize(fa_mesh_fs_params[0].xyz - fa_world_pos);\n    SurfaceInput param = SurfaceInput(fa_world_pos, _742, fa_world_tangent, fa_uv, fa_vertex_color, _550, gl_FrontFacing);\n    SurfaceInput param_1 = SurfaceInput(fa_world_pos, _742, fa_world_tangent, fa_uv, fa_vertex_color, _550, gl_FrontFacing);\n    Surface param_2 = fa_standard_surface(param);\n    surface(param_1, param_2);\n    vec3 _565 = normalize(param_2.normal);\n    vec3 _580 = normalize(vec3(dot(fa_pre_r0, _565), dot(fa_pre_r1, _565), dot(fa_pre_r2, _565)));\n    float _592 = _580.z;\n    vec2 e = _580.xy / vec2((abs(_580.x) + abs(_580.y)) + abs(_592));\n    if (_592 < 0.0)\n    {\n        e = (vec2(1.0) - abs(e.yx)) * vec2((e.x >= 0.0) ? 1.0 : (-1.0), (e.y >= 0.0) ? 1.0 : (-1.0));\n    }\n    fa_frag_color = vec4(min(fa_pre_depth, 60000.0), e, 1.0);\n    vec2 motion = vec2(1024.0);\n    bool _636 = fa_vel_cur.z > 9.9999997473787516355514526367188e-06;\n    bool _643;\n    if (_636)\n    {\n        _643 = fa_vel_prev.z > 9.9999997473787516355514526367188e-06;\n    }\n    else\n    {\n        _643 = _636;\n    }\n    if (_643)\n    {\n        motion = clamp(((vec2(fa_vel_prev.x, -fa_vel_prev.y) / vec2(fa_vel_prev.z)) * 0.5) - ((vec2(fa_vel_cur.x, -fa_vel_cur.y) / vec2(fa_vel_cur.z)) * 0.5), vec2(-4.0), vec2(4.0));\n    }\n    fa_frag_velocity = motion;\n}\n\n",
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
            "inst_name": "_214",
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
      "vs": "#version 430\n\nstruct VertexData\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 color;\n    vec3 object_pos;\n};\n\nuniform vec4 fa_mesh_vs_params[11];\nuniform vec4 fa_skin[192];\nuniform vec4 fa_vel_params[9];\nlayout(binding = 0) uniform sampler2D fa_prev_pal_tex_fa_prev_pal_smp;\n\nlayout(location = 0) out vec3 fa_world_pos;\nlayout(location = 1) out vec3 fa_world_normal;\nlayout(location = 2) out vec4 fa_world_tangent;\nlayout(location = 3) out vec2 fa_uv;\nlayout(location = 4) out vec4 fa_vertex_color;\nlayout(location = 5) out float fa_pre_depth;\nlayout(location = 6) out vec3 fa_pre_r0;\nlayout(location = 7) out vec3 fa_pre_r1;\nlayout(location = 8) out vec3 fa_pre_r2;\nlayout(location = 9) out vec3 fa_vel_cur;\nlayout(location = 10) out vec3 fa_vel_prev;\nlayout(location = 11) in vec4 fa_prev_r0;\nlayout(location = 12) in vec4 fa_prev_r1;\nlayout(location = 13) in vec4 fa_prev_r2;\nlayout(location = 9) in vec4 fa_joints;\nlayout(location = 10) in vec4 fa_weights;\nlayout(location = 5) in vec4 fa_inst_m0;\nlayout(location = 6) in vec4 fa_inst_m1;\nlayout(location = 7) in vec4 fa_inst_m2;\nlayout(location = 8) in vec4 fa_inst_m3;\nlayout(location = 0) in vec3 fa_position;\nlayout(location = 1) in vec3 fa_normal;\nlayout(location = 3) in vec4 fa_tangent;\nlayout(location = 2) in vec2 fa_texcoord0;\nlayout(location = 4) in vec4 fa_color;\nvec4 fa_vtime;\n\nvoid fa_inst_begin()\n{\n}\n\nmat4 fa_skin_matrix(vec4 joints, vec4 weights)\n{\n    vec4 r0 = vec4(0.0);\n    vec4 r1 = vec4(0.0);\n    vec4 r2 = vec4(0.0);\n    for (int i = 0; i < 4; i++)\n    {\n        int _204 = int((joints[i] * 255.0) + 0.5) * 3;\n        r0 += (fa_skin[_204 * 1 + 0] * weights[i]);\n        r1 += (fa_skin[(_204 + 1) * 1 + 0] * weights[i]);\n        r2 += (fa_skin[(_204 + 2) * 1 + 0] * weights[i]);\n    }\n    return mat4(vec4(r0.x, r1.x, r2.x, 0.0), vec4(r0.y, r1.y, r2.y, 0.0), vec4(r0.z, r1.z, r2.z, 0.0), vec4(r0.w, r1.w, r2.w, 1.0));\n}\n\nvec4 fa_time_now()\n{\n    return fa_mesh_vs_params[9];\n}\n\nVertexData fa_vertex_data(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    vec3 _113 = cross(model[1].xyz, model[2].xyz);\n    float _117 = (dot(model[0].xyz, _113) < 0.0) ? (-1.0) : 1.0;\n    return VertexData((model * vec4(position, 1.0)).xyz, (((_113 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _117, vec4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _117), texcoord0 * fa_mesh_vs_params[8].xy, color, position);\n}\n\nmat4 fa_rows_to_mat4(vec4 r0, vec4 r1, vec4 r2)\n{\n    return mat4(vec4(r0.x, r1.x, r2.x, 0.0), vec4(r0.y, r1.y, r2.y, 0.0), vec4(r0.z, r1.z, r2.z, 0.0), vec4(r0.w, r1.w, r2.w, 1.0));\n}\n\nvec4 fa_prev_pal_texel(int t)\n{\n    return texelFetch(fa_prev_pal_tex_fa_prev_pal_smp, ivec2(t & 1023, t >> 10), 0);\n}\n\nmat4 fa_prev_skin_matrix(vec4 joints, vec4 weights, int base)\n{\n    vec4 r0 = vec4(0.0);\n    vec4 r1 = vec4(0.0);\n    vec4 r2 = vec4(0.0);\n    for (int i = 0; i < 4; i++)\n    {\n        int _332 = base + (int((joints[i] * 255.0) + 0.5) * 3);\n        int param = _332;\n        r0 += (fa_prev_pal_texel(param) * weights[i]);\n        int param_1 = _332 + 1;\n        r1 += (fa_prev_pal_texel(param_1) * weights[i]);\n        int param_2 = _332 + 2;\n        r2 += (fa_prev_pal_texel(param_2) * weights[i]);\n    }\n    return mat4(vec4(r0.x, r1.x, r2.x, 0.0), vec4(r0.y, r1.y, r2.y, 0.0), vec4(r0.z, r1.z, r2.z, 0.0), vec4(r0.w, r1.w, r2.w, 1.0));\n}\n\nmat4 fa_prev_model()\n{\n    vec4 param = fa_prev_r0;\n    vec4 param_1 = fa_prev_r1;\n    vec4 param_2 = fa_prev_r2;\n    vec4 param_3 = fa_joints;\n    vec4 param_4 = fa_weights;\n    int param_5 = int(fa_vel_params[8].w + 0.5);\n    return fa_rows_to_mat4(param, param_1, param_2) * fa_prev_skin_matrix(param_3, param_4, param_5);\n}\n\nvoid fa_prepass_vertex(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color, bool has_prev)\n{\n    bool _475;\n    if (has_prev)\n    {\n        _475 = fa_vel_params[8].x > 0.5;\n    }\n    else\n    {\n        _475 = has_prev;\n    }\n    fa_vtime = fa_time_now();\n    mat4 param = model;\n    vec3 param_1 = position;\n    vec3 param_2 = normal;\n    vec4 param_3 = tangent;\n    vec2 param_4 = texcoord0;\n    vec4 param_5 = color;\n    VertexData _490 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    vec3 _723 = _490.world_pos;\n    mat4 _494 = mat4(fa_mesh_vs_params[4], fa_mesh_vs_params[5], fa_mesh_vs_params[6], fa_mesh_vs_params[7]);\n    vec4 _501 = vec4(_723, 1.0);\n    fa_world_pos = _723;\n    fa_world_normal = _490.world_normal;\n    fa_world_tangent = _490.world_tangent;\n    fa_uv = _490.uv;\n    fa_vertex_color = _490.color;\n    fa_pre_depth = -(_494 * _501).z;\n    fa_pre_r0 = vec3(_494[0].x, _494[1].x, _494[2].x);\n    fa_pre_r1 = vec3(_494[0].y, _494[1].y, _494[2].y);\n    fa_pre_r2 = vec3(_494[0].z, _494[1].z, _494[2].z);\n    gl_Position = mat4(fa_mesh_vs_params[0], fa_mesh_vs_params[1], fa_mesh_vs_params[2], fa_mesh_vs_params[3]) * _501;\n    fa_vel_cur = vec3(0.0, 0.0, 1.0);\n    fa_vel_prev = vec3(0.0);\n    if (_475)\n    {\n        vec4 _574 = vec4(position, 1.0);\n        fa_vel_cur = vec3((mat4(fa_vel_params[0], fa_vel_params[1], fa_vel_params[2], fa_vel_params[3]) * _501).xyw);\n        fa_vel_prev = vec3((mat4(fa_vel_params[4], fa_vel_params[5], fa_vel_params[6], fa_vel_params[7]) * vec4((_723 + (fa_prev_model() * _574).xyz) - (model * _574).xyz, 1.0)).xyw);\n    }\n}\n\nvoid main()\n{\n    fa_vtime = vec4(0.0);\n    fa_inst_begin();\n    vec4 param = fa_joints;\n    vec4 param_1 = fa_weights;\n    mat4 param_2 = mat4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3) * fa_skin_matrix(param, param_1);\n    vec3 param_3 = fa_position;\n    vec3 param_4 = fa_normal;\n    vec4 param_5 = fa_tangent;\n    vec2 param_6 = fa_texcoord0;\n    vec4 param_7 = fa_color;\n    bool param_8 = fa_vel_params[8].z > 0.5;\n    fa_prepass_vertex(param_2, param_3, param_4, param_5, param_6, param_7, param_8);\n}\n\n",
      "fs": "#version 430\n\nstruct SurfaceInput\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 vertex_color;\n    vec3 view_dir;\n    bool front_facing;\n};\n\nstruct Surface\n{\n    vec3 albedo;\n    float alpha;\n    vec3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    vec3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    vec3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    vec3 specular_color;\n    float transmission;\n    float thickness;\n    vec3 attenuation_color;\n    float attenuation_distance;\n};\n\nuniform vec4 fa_mesh_fs_params[53];\nlayout(binding = 0) uniform sampler2D fa_tex_fa_smp;\nlayout(binding = 1) uniform sampler2D fa_normal_tex_fa_smp;\nlayout(binding = 2) uniform sampler2D fa_mr_tex_fa_smp;\nlayout(binding = 3) uniform sampler2D fa_occlusion_tex_fa_smp;\nlayout(binding = 4) uniform sampler2D fa_emissive_tex_fa_smp;\n\nlayout(location = 0) in vec3 fa_world_pos;\nlayout(location = 1) in vec3 fa_world_normal;\nlayout(location = 2) in vec4 fa_world_tangent;\nlayout(location = 3) in vec2 fa_uv;\nlayout(location = 4) in vec4 fa_vertex_color;\nlayout(location = 6) in vec3 fa_pre_r0;\nlayout(location = 7) in vec3 fa_pre_r1;\nlayout(location = 8) in vec3 fa_pre_r2;\nlayout(location = 0) out vec4 fa_frag_color;\nlayout(location = 5) in float fa_pre_depth;\nlayout(location = 9) in vec3 fa_vel_cur;\nlayout(location = 10) in vec3 fa_vel_prev;\nlayout(location = 1) out vec2 fa_frag_velocity;\n\nvoid fa_inst_load()\n{\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nvec3 fa_linear_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_tex_fix(inout vec3 c, float mode)\n{\n    if (mode > 1.5)\n    {\n        vec3 param = c;\n        vec3 _172 = fa_linear_to_srgb(param);\n        c = _172;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            vec3 param_1 = c;\n            vec3 _181 = fa_srgb_to_linear(param_1);\n            c = _181;\n        }\n    }\n    return c;\n}\n\nvec3 fa_tangent_normal(SurfaceInput i, vec3 m)\n{\n    vec3 _56;\n    if (i.front_facing)\n    {\n        _56 = i.world_normal;\n    }\n    else\n    {\n        _56 = -i.world_normal;\n    }\n    vec3 _81 = normalize(i.world_tangent.xyz - (_56 * dot(_56, i.world_tangent.xyz)));\n    vec3 _109 = normalize(((_81 * m.x) + ((cross(_56, _81) * i.world_tangent.w) * m.y)) + (_56 * m.z));\n    vec3 _112;\n    if (i.front_facing)\n    {\n        _112 = _109;\n    }\n    else\n    {\n        _112 = -_109;\n    }\n    return _112;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    vec4 base_t = texture(fa_tex_fa_smp, i.uv, fa_mesh_fs_params[12].w);\n    float param = fa_mesh_fs_params[6].w;\n    float param_1 = 1.0;\n    vec3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    vec3 _230 = fa_tex_fix(param_2, param_3);\n    vec4 _892 = base_t;\n    _892.x = _230.x;\n    _892.y = _230.y;\n    _892.z = _230.z;\n    base_t = _892;\n    vec4 _246 = (_892 * fa_mesh_fs_params[2]) * i.vertex_color;\n    vec3 _847 = i.world_normal;\n    if (fa_mesh_fs_params[6].z > 0.5)\n    {\n        float param_4 = fa_mesh_fs_params[6].w;\n        float param_5 = 16.0;\n        vec3 param_6 = texture(fa_normal_tex_fa_smp, i.uv, fa_mesh_fs_params[12].w).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        vec3 _282 = fa_tex_fix(param_6, param_7);\n        vec3 _286 = (_282 * 2.0) - vec3(1.0);\n        vec2 _291 = _286.xy * fa_mesh_fs_params[6].x;\n        vec3 _900 = _286;\n        _900.x = _291.x;\n        _900.y = _291.y;\n        SurfaceInput param_8 = i;\n        vec3 param_9 = _900;\n        _847 = fa_tangent_normal(param_8, param_9);\n    }\n    vec4 mrt = texture(fa_mr_tex_fa_smp, i.uv, fa_mesh_fs_params[12].w);\n    float param_10 = fa_mesh_fs_params[6].w;\n    float param_11 = 64.0;\n    vec3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    vec3 _322 = fa_tex_fix(param_12, param_13);\n    vec4 _903 = mrt;\n    _903.x = _322.x;\n    _903.y = _322.y;\n    _903.z = _322.z;\n    mrt = _903;\n    vec4 _354 = texture(fa_occlusion_tex_fa_smp, i.uv, fa_mesh_fs_params[12].w);\n    float param_14 = fa_mesh_fs_params[6].w;\n    float param_15 = 256.0;\n    vec3 param_16 = _354.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    vec3 _366 = fa_tex_fix(param_16, param_17);\n    float param_18 = fa_mesh_fs_params[6].w;\n    float param_19 = 4.0;\n    vec3 param_20 = texture(fa_emissive_tex_fa_smp, i.uv, fa_mesh_fs_params[12].w).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    vec3 _398 = fa_tex_fix(param_20, param_21);\n    float _852 = fa_mesh_fs_params[20].x;\n    float _853 = fa_mesh_fs_params[20].y;\n    float _856 = fa_mesh_fs_params[20].z;\n    float _855 = fa_mesh_fs_params[21].w;\n    float _858 = fa_mesh_fs_params[22].x;\n    if (fa_mesh_fs_params[22].z > 0.5)\n    {\n        if (mod(fa_mesh_fs_params[22].z, 2.0) > 0.5)\n        {\n            _852 *= _366.y;\n            _853 *= _366.z;\n            _855 *= _354.w;\n        }\n        if (fa_mesh_fs_params[22].z > 1.5)\n        {\n            _856 *= mrt.x;\n            _858 *= mrt.w;\n        }\n    }\n    return Surface(_246.xyz, _246.w, _847, clamp(fa_mesh_fs_params[5].x * _322.z, 0.0, 1.0), clamp(fa_mesh_fs_params[5].y * _322.y, 0.0500000007450580596923828125, 1.0), 1.0 + (fa_mesh_fs_params[6].y * (_366.x - 1.0)), fa_mesh_fs_params[3].xyz + (fa_mesh_fs_params[4].xyz * _398), _852, _853, fa_mesh_fs_params[21].xyz, _855, _856, fa_mesh_fs_params[20].w, _858, fa_mesh_fs_params[22].y, fa_mesh_fs_params[23].xyz, fa_mesh_fs_params[30].x, fa_mesh_fs_params[30].y, fa_mesh_fs_params[31].xyz, fa_mesh_fs_params[30].z);\n}\n\nvoid surface(SurfaceInput i, Surface s)\n{\n}\n\nvoid main()\n{\n    fa_inst_load();\n    vec3 _742 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _742 = -_742;\n    }\n    vec3 _550 = normalize(fa_mesh_fs_params[0].xyz - fa_world_pos);\n    SurfaceInput param = SurfaceInput(fa_world_pos, _742, fa_world_tangent, fa_uv, fa_vertex_color, _550, gl_FrontFacing);\n    SurfaceInput param_1 = SurfaceInput(fa_world_pos, _742, fa_world_tangent, fa_uv, fa_vertex_color, _550, gl_FrontFacing);\n    Surface param_2 = fa_standard_surface(param);\n    surface(param_1, param_2);\n    vec3 _565 = normalize(param_2.normal);\n    vec3 _580 = normalize(vec3(dot(fa_pre_r0, _565), dot(fa_pre_r1, _565), dot(fa_pre_r2, _565)));\n    float _592 = _580.z;\n    vec2 e = _580.xy / vec2((abs(_580.x) + abs(_580.y)) + abs(_592));\n    if (_592 < 0.0)\n    {\n        e = (vec2(1.0) - abs(e.yx)) * vec2((e.x >= 0.0) ? 1.0 : (-1.0), (e.y >= 0.0) ? 1.0 : (-1.0));\n    }\n    fa_frag_color = vec4(min(fa_pre_depth, 60000.0), e, 1.0);\n    vec2 motion = vec2(1024.0);\n    bool _636 = fa_vel_cur.z > 9.9999997473787516355514526367188e-06;\n    bool _643;\n    if (_636)\n    {\n        _643 = fa_vel_prev.z > 9.9999997473787516355514526367188e-06;\n    }\n    else\n    {\n        _643 = _636;\n    }\n    if (_643)\n    {\n        motion = clamp(((vec2(fa_vel_prev.x, -fa_vel_prev.y) / vec2(fa_vel_prev.z)) * 0.5) - ((vec2(fa_vel_cur.x, -fa_vel_cur.y) / vec2(fa_vel_cur.z)) * 0.5), vec2(-4.0), vec2(4.0));\n    }\n    fa_frag_velocity = motion;\n}\n\n",
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
            "inst_name": "_214",
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
