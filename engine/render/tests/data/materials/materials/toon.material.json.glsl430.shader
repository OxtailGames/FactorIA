{
  "format": "factoria.shader/1",
  "engine": "0.32.0",
  "template": "5f457c7d0bc8edbcdea422ba00c093c613745eefd8db6d8c8f93fc5e235db1e8",
  "slang": "glsl430",
  "params": [
    "dark"
  ],
  "textures": [],
  "programs": {
    "mesh": {
      "vs": "#version 430\n\nstruct VertexData\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 color;\n    vec3 object_pos;\n};\n\nuniform vec4 fa_mesh_vs_params[11];\nlayout(location = 0) out vec3 fa_world_pos;\nlayout(location = 1) out vec3 fa_world_normal;\nlayout(location = 2) out vec4 fa_world_tangent;\nlayout(location = 3) out vec2 fa_uv;\nlayout(location = 4) out vec4 fa_vertex_color;\nlayout(location = 5) in vec4 fa_inst_m0;\nlayout(location = 6) in vec4 fa_inst_m1;\nlayout(location = 7) in vec4 fa_inst_m2;\nlayout(location = 8) in vec4 fa_inst_m3;\nlayout(location = 0) in vec3 fa_position;\nlayout(location = 1) in vec3 fa_normal;\nlayout(location = 3) in vec4 fa_tangent;\nlayout(location = 2) in vec2 fa_texcoord0;\nlayout(location = 4) in vec4 fa_color;\nlayout(location = 5) out vec3 fa_lm;\n\nvoid fa_inst_begin()\n{\n}\n\nVertexData fa_vertex_data(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    vec3 _69 = cross(model[1].xyz, model[2].xyz);\n    float _75 = (dot(model[0].xyz, _69) < 0.0) ? (-1.0) : 1.0;\n    return VertexData((model * vec4(position, 1.0)).xyz, (((_69 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _75, vec4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _75), texcoord0 * fa_mesh_vs_params[8].xy, color, position);\n}\n\nvoid fa_shade_vertex(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    mat4 param = model;\n    vec3 param_1 = position;\n    vec3 param_2 = normal;\n    vec4 param_3 = tangent;\n    vec2 param_4 = texcoord0;\n    vec4 param_5 = color;\n    VertexData _160 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    vec3 _270 = _160.world_pos;\n    fa_world_pos = _270;\n    fa_world_normal = _160.world_normal;\n    fa_world_tangent = _160.world_tangent;\n    fa_uv = _160.uv;\n    fa_vertex_color = _160.color;\n    gl_Position = mat4(fa_mesh_vs_params[0], fa_mesh_vs_params[1], fa_mesh_vs_params[2], fa_mesh_vs_params[3]) * vec4(_270, 1.0);\n}\n\nvoid main()\n{\n    fa_inst_begin();\n    mat4 param = mat4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3);\n    vec3 param_1 = fa_position;\n    vec3 param_2 = fa_normal;\n    vec4 param_3 = fa_tangent;\n    vec2 param_4 = fa_texcoord0;\n    vec4 param_5 = fa_color;\n    fa_shade_vertex(param, param_1, param_2, param_3, param_4, param_5);\n    fa_lm = vec3(0.0);\n}\n\n",
      "fs": "#version 430\n\nstruct SurfaceInput\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 vertex_color;\n    vec3 view_dir;\n    bool front_facing;\n};\n\nstruct LightSample\n{\n    vec3 direction;\n    vec3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct Surface\n{\n    vec3 albedo;\n    float alpha;\n    vec3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    vec3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    vec3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    vec3 specular_color;\n};\n\nuniform vec4 fa_mesh_fs_params[24];\nuniform vec4 fa_shadows[30];\nuniform vec4 fa_material[1];\nlayout(binding = 0) uniform sampler2D fa_light_tex_fa_shadow_smp;\nlayout(binding = 1) uniform sampler2D fa_tex_fa_smp;\nlayout(binding = 2) uniform sampler2D fa_normal_tex_fa_smp;\nlayout(binding = 3) uniform sampler2D fa_mr_tex_fa_smp;\nlayout(binding = 4) uniform sampler2D fa_occlusion_tex_fa_smp;\nlayout(binding = 5) uniform sampler2D fa_emissive_tex_fa_smp;\nlayout(binding = 6) uniform sampler2D fa_decal_tex_fa_env_smp;\nlayout(binding = 7) uniform sampler2D fa_lightmap_fa_env_smp;\nlayout(binding = 8) uniform samplerCube fa_env_tex_fa_env_smp;\nlayout(binding = 9) uniform sampler2D fa_light_atlas_fa_env_smp;\nlayout(binding = 10) uniform sampler2D fa_shadow_tex_fa_shadow_smp;\n\nlayout(location = 0) in vec3 fa_world_pos;\nlayout(location = 5) in vec3 fa_lm;\nlayout(location = 1) in vec3 fa_world_normal;\nlayout(location = 2) in vec4 fa_world_tangent;\nlayout(location = 3) in vec2 fa_uv;\nlayout(location = 4) in vec4 fa_vertex_color;\nlayout(location = 0) out vec4 fa_frag_color;\nvec3 fa_light_tint;\nbool fa_light_is_area;\nint fa_cl_ndir;\nint fa_cl_slot;\nint fa_cl_local;\n\nvoid fa_inst_load()\n{\n}\n\nvec4 fa_light_texel(int t)\n{\n    return texelFetch(fa_light_tex_fa_shadow_smp, ivec2(t & 1023, t >> 10), 0);\n}\n\nvec4 fa_cluster_texel(vec3 world_pos)\n{\n    bool _1306 = fa_mesh_fs_params[19].x < 0.0;\n    bool _1313;\n    if (!_1306)\n    {\n        _1313 = fa_mesh_fs_params[19].w < 1.0;\n    }\n    else\n    {\n        _1313 = _1306;\n    }\n    bool _1321;\n    if (!_1313)\n    {\n        _1321 = fa_mesh_fs_params[18].x < 1.0;\n    }\n    else\n    {\n        _1321 = _1313;\n    }\n    bool _1328;\n    if (!_1321)\n    {\n        _1328 = fa_mesh_fs_params[18].y < 1.0;\n    }\n    else\n    {\n        _1328 = _1321;\n    }\n    bool _1335;\n    if (!_1328)\n    {\n        _1335 = fa_mesh_fs_params[19].y < 1.0;\n    }\n    else\n    {\n        _1335 = _1328;\n    }\n    if (_1335)\n    {\n        return vec4(0.0);\n    }\n    vec4 _1345 = vec4(world_pos, 1.0);\n    float _1351 = dot(fa_mesh_fs_params[16], _1345);\n    if (!(_1351 > 9.9999999747524270787835121154785e-07))\n    {\n        return vec4(0.0);\n    }\n    vec2 _1373 = vec2(dot(fa_mesh_fs_params[14], _1345), dot(fa_mesh_fs_params[15], _1345)) / vec2(_1351);\n    int _1377 = int(fa_mesh_fs_params[18].x);\n    int _1381 = int(fa_mesh_fs_params[18].y);\n    int param = (int(fa_mesh_fs_params[19].x) + (((clamp(int(floor(log2(max(dot(fa_mesh_fs_params[17].xyz, world_pos) + fa_mesh_fs_params[17].w, fa_mesh_fs_params[18].w) / fa_mesh_fs_params[18].w) * fa_mesh_fs_params[18].z)), 0, int(fa_mesh_fs_params[19].y) - 1) * _1381) + clamp(int(floor(((_1373.y * 0.5) + 0.5) * fa_mesh_fs_params[18].y)), 0, _1381 - 1)) * _1377)) + clamp(int(floor(((_1373.x * 0.5) + 0.5) * fa_mesh_fs_params[18].x)), 0, _1377 - 1);\n    return fa_light_texel(param);\n}\n\nivec2 fa_cluster_lookup(vec3 world_pos)\n{\n    vec3 param = world_pos;\n    vec4 _1457 = fa_cluster_texel(param);\n    return ivec2(int(_1457.x), int(_1457.y));\n}\n\nvoid fa_cluster_begin(vec3 world_pos)\n{\n    fa_cl_ndir = int(fa_mesh_fs_params[19].z);\n    vec3 param = world_pos;\n    ivec2 _3235 = fa_cluster_lookup(param);\n    fa_cl_slot = _3235.x;\n    fa_cl_local = _3235.y;\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nvec3 fa_linear_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_tex_fix(inout vec3 c, float mode)\n{\n    if (mode > 1.5)\n    {\n        vec3 param = c;\n        vec3 _3417 = fa_linear_to_srgb(param);\n        c = _3417;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            vec3 param_1 = c;\n            vec3 _3425 = fa_srgb_to_linear(param_1);\n            c = _3425;\n        }\n    }\n    return c;\n}\n\nvec3 fa_tangent_normal(SurfaceInput i, vec3 m)\n{\n    vec3 _261;\n    if (i.front_facing)\n    {\n        _261 = i.world_normal;\n    }\n    else\n    {\n        _261 = -i.world_normal;\n    }\n    vec3 _285 = normalize(i.world_tangent.xyz - (_261 * dot(_261, i.world_tangent.xyz)));\n    vec3 _312 = normalize(((_285 * m.x) + ((cross(_261, _285) * i.world_tangent.w) * m.y)) + (_261 * m.z));\n    vec3 _315;\n    if (i.front_facing)\n    {\n        _315 = _312;\n    }\n    else\n    {\n        _315 = -_312;\n    }\n    return _315;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    vec4 base_t = texture(fa_tex_fa_smp, i.uv);\n    float param = fa_mesh_fs_params[6].w;\n    float param_1 = 1.0;\n    vec3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    vec3 _3456 = fa_tex_fix(param_2, param_3);\n    vec4 _4479 = base_t;\n    _4479.x = _3456.x;\n    _4479.y = _3456.y;\n    _4479.z = _3456.z;\n    base_t = _4479;\n    vec4 _3470 = (_4479 * fa_mesh_fs_params[2]) * i.vertex_color;\n    vec3 _4344 = i.world_normal;\n    if (fa_mesh_fs_params[6].z > 0.5)\n    {\n        float param_4 = fa_mesh_fs_params[6].w;\n        float param_5 = 16.0;\n        vec3 param_6 = texture(fa_normal_tex_fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        vec3 _3502 = fa_tex_fix(param_6, param_7);\n        vec3 _3505 = (_3502 * 2.0) - vec3(1.0);\n        vec2 _3510 = _3505.xy * fa_mesh_fs_params[6].x;\n        vec3 _4487 = _3505;\n        _4487.x = _3510.x;\n        _4487.y = _3510.y;\n        SurfaceInput param_8 = i;\n        vec3 param_9 = _4487;\n        _4344 = fa_tangent_normal(param_8, param_9);\n    }\n    vec4 mrt = texture(fa_mr_tex_fa_smp, i.uv);\n    float param_10 = fa_mesh_fs_params[6].w;\n    float param_11 = 64.0;\n    vec3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    vec3 _3538 = fa_tex_fix(param_12, param_13);\n    vec4 _4490 = mrt;\n    _4490.x = _3538.x;\n    _4490.y = _3538.y;\n    _4490.z = _3538.z;\n    mrt = _4490;\n    vec4 _3566 = texture(fa_occlusion_tex_fa_smp, i.uv);\n    float param_14 = fa_mesh_fs_params[6].w;\n    float param_15 = 256.0;\n    vec3 param_16 = _3566.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    vec3 _3577 = fa_tex_fix(param_16, param_17);\n    float param_18 = fa_mesh_fs_params[6].w;\n    float param_19 = 4.0;\n    vec3 param_20 = texture(fa_emissive_tex_fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    vec3 _3607 = fa_tex_fix(param_20, param_21);\n    float _4349 = fa_mesh_fs_params[20].x;\n    float _4350 = fa_mesh_fs_params[20].y;\n    float _4353 = fa_mesh_fs_params[20].z;\n    float _4352 = fa_mesh_fs_params[21].w;\n    float _4355 = fa_mesh_fs_params[22].x;\n    if (fa_mesh_fs_params[22].z > 0.5)\n    {\n        if (mod(fa_mesh_fs_params[22].z, 2.0) > 0.5)\n        {\n            _4349 *= _3577.y;\n            _4350 *= _3577.z;\n            _4352 *= _3566.w;\n        }\n        if (fa_mesh_fs_params[22].z > 1.5)\n        {\n            _4353 *= mrt.x;\n            _4355 *= mrt.w;\n        }\n    }\n    return Surface(_3470.xyz, _3470.w, _4344, clamp(fa_mesh_fs_params[5].x * _3538.z, 0.0, 1.0), clamp(fa_mesh_fs_params[5].y * _3538.y, 0.0500000007450580596923828125, 1.0), 1.0 + (fa_mesh_fs_params[6].y * (_3577.x - 1.0)), fa_mesh_fs_params[3].xyz + (fa_mesh_fs_params[4].xyz * _3607), _4349, _4350, fa_mesh_fs_params[21].xyz, _4352, _4353, fa_mesh_fs_params[20].w, _4355, fa_mesh_fs_params[22].y, fa_mesh_fs_params[23].xyz);\n}\n\nvoid surface(SurfaceInput i, Surface s)\n{\n}\n\nvec4 fa_decal_tile(vec4 rect, vec2 uv, vec2 atlas, vec2 ddx, vec2 ddy)\n{\n    vec2 _1537 = rect.zw - rect.xy;\n    vec2 _1541 = _1537 * atlas;\n    vec2 _1545 = ddx * _1541;\n    vec2 _1549 = ddy * _1541;\n    return textureLod(fa_decal_tex_fa_env_smp, rect.xy + (clamp(uv, vec2(0.0), vec2(1.0)) * _1537), clamp(0.5 * log2(max(max(dot(_1545, _1545), dot(_1549, _1549)), 9.9999999392252902907785028219223e-09)), 0.0, 4.0));\n}\n\nvec3 fa_dc_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_dc_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvoid fa_apply_decals(vec3 world_pos, vec3 geo_normal, inout vec3 albedo, inout vec3 normal)\n{\n    bool _1582 = fa_mesh_fs_params[10].y < 0.5;\n    bool _1589;\n    if (!_1582)\n    {\n        _1589 = fa_mesh_fs_params[10].w < 0.5;\n    }\n    else\n    {\n        _1589 = _1582;\n    }\n    if (_1589)\n    {\n        return;\n    }\n    vec3 _1595 = dFdx(world_pos);\n    vec3 _1598 = dFdy(world_pos);\n    vec3 param = world_pos;\n    vec4 _1602 = fa_cluster_texel(param);\n    int _1606 = int(_1602.w);\n    if (_1606 < 1)\n    {\n        return;\n    }\n    int _1616 = int(fa_mesh_fs_params[10].y + 0.5);\n    int param_1 = _1616;\n    vec4 _1620 = fa_light_texel(param_1);\n    vec2 _1623 = _1620.yz;\n    int _1627 = int(_1620.w);\n    int param_2 = _1616 + 1;\n    vec4 _1632 = fa_light_texel(param_2);\n    float _1633 = _1632.x;\n    int _1639 = int(fa_mesh_fs_params[10].w + 0.5) - 1;\n    int _1643 = int(_1602.z);\n    vec3 _1908;\n    for (int k = 0; k < _1606; k++)\n    {\n        int _1656 = _1643 + k;\n        int param_3 = _1627 + (_1656 >> 2);\n        int _1673 = (_1616 + 2) + (int(fa_light_texel(param_3)[_1656 & 3]) * 7);\n        int param_4 = _1673 + 6;\n        vec4 _1678 = fa_light_texel(param_4);\n        if (((int(_1678.w + 0.5) >> _1639) & 1) == 0)\n        {\n            continue;\n        }\n        int param_5 = _1673;\n        vec4 _1693 = fa_light_texel(param_5);\n        int param_6 = _1673 + 1;\n        vec4 _1698 = fa_light_texel(param_6);\n        int param_7 = _1673 + 2;\n        vec4 _1703 = fa_light_texel(param_7);\n        vec3 _1706 = _1693.xyz;\n        float _1711 = dot(_1706, world_pos) + _1693.w;\n        vec3 _1713 = _1698.xyz;\n        float _1718 = dot(_1713, world_pos) + _1698.w;\n        vec3 _1720 = _1703.xyz;\n        float _1725 = dot(_1720, world_pos) + _1703.w;\n        bool _1730 = abs(_1711) > 0.5;\n        bool _1738;\n        if (!_1730)\n        {\n            _1738 = abs(_1718) > 0.5;\n        }\n        else\n        {\n            _1738 = _1730;\n        }\n        bool _1746;\n        if (!_1738)\n        {\n            _1746 = abs(_1725) > 0.5;\n        }\n        else\n        {\n            _1746 = _1738;\n        }\n        if (_1746)\n        {\n            continue;\n        }\n        float _1761 = clamp(dot(geo_normal, normalize(_1720)) * _1678.z, 0.0, 1.0);\n        if (_1761 <= 0.0)\n        {\n            continue;\n        }\n        float _1781 = (clamp((0.5 - abs(_1725)) * 10.0, 0.0, 1.0) * _1761) * _1678.x;\n        vec2 _1789 = vec2(_1711 + 0.5, 0.5 - _1718);\n        vec2 _1799 = vec2(dot(_1706, _1595), dot(_1713, _1595));\n        vec2 _1809 = vec2(dot(_1706, _1598), dot(_1713, _1598));\n        int param_8 = _1673 + 5;\n        vec4 _1814 = fa_light_texel(param_8);\n        int param_9 = _1673 + 3;\n        vec4 _1819 = fa_light_texel(param_9);\n        int param_10 = _1673 + 4;\n        vec4 _1824 = fa_light_texel(param_10);\n        float tex_a = 1.0;\n        vec3 col = _1814.xyz;\n        bool _1834 = _1819.z > _1819.x;\n        if (_1834)\n        {\n            vec4 param_11 = _1819;\n            vec2 param_12 = _1789;\n            vec2 param_13 = _1623;\n            vec2 param_14 = _1799;\n            vec2 param_15 = _1809;\n            vec4 tx = fa_decal_tile(param_11, param_12, param_13, param_14, param_15);\n            if ((_1633 > 0.5) && (_1633 < 1.5))\n            {\n                vec3 param_16 = tx.xyz;\n                vec3 _1860 = fa_dc_to_linear(param_16);\n                vec4 _4424 = tx;\n                _4424.x = _1860.x;\n                _4424.y = _1860.y;\n                _4424.z = _1860.z;\n                tx = _4424;\n            }\n            col *= tx.xyz;\n            tex_a = tx.w;\n        }\n        albedo = mix(albedo, col, vec3(clamp((_1781 * tex_a) * _1814.w, 0.0, 1.0)));\n        if (_1824.z > _1824.x)\n        {\n            vec4 param_17 = _1824;\n            vec2 param_18 = _1789;\n            vec2 param_19 = _1623;\n            vec2 param_20 = _1799;\n            vec2 param_21 = _1809;\n            vec4 _1904 = fa_decal_tile(param_17, param_18, param_19, param_20, param_21);\n            if (_1633 > 1.5)\n            {\n                vec3 param_22 = _1904.xyz;\n                vec3 _1914 = fa_dc_to_srgb(param_22);\n                _1908 = _1914;\n            }\n            else\n            {\n                _1908 = _1904.xyz;\n            }\n            vec3 _1923 = (_1908 * 2.0) - vec3(1.0);\n            vec2 _1928 = _1923.xy * _1678.y;\n            vec3 _1950 = (normalize(_1706) * _1928.x) + (normalize(_1713) * _1928.y);\n            vec3 _1953 = normalize(normal);\n            normal = normalize(mix(_1953, normalize((_1953 * max(_1923.z, 0.0500000007450580596923828125)) + (_1950 - (_1953 * dot(_1953, _1950)))), vec3(clamp(_1781 * (_1834 ? tex_a : 1.0), 0.0, 1.0))));\n        }\n    }\n}\n\nvec3 fa_sky_sh_coef(int k)\n{\n    vec3 v = textureLod(fa_env_tex_fa_env_smp, vec3(1.0, 1.0 - (float((2 * (k >> 2)) + 1) * 0.25), 1.0 - (float((2 * (k & 3)) + 1) * 0.25)), 5.0).xyz;\n    if (fa_mesh_fs_params[11].w > 1.5)\n    {\n        v = (v - vec3(0.5)) * 8.0;\n    }\n    return v;\n}\n\nvec3 fa_sh_eval(vec3 c[9], vec3 n)\n{\n    vec3 _3148 = max((((c[0] * 0.2820948064327239990234375) + (((c[1] * (0.3257350027561187744140625 * n.y)) + (c[2] * (0.3257350027561187744140625 * n.z))) + (c[3] * (0.3257350027561187744140625 * n.x)))) + (((c[4] * ((0.2731371223926544189453125 * n.x) * n.y)) + (c[5] * ((0.2731371223926544189453125 * n.y) * n.z))) + (c[6] * (0.078847892582416534423828125 * (((3.0 * n.z) * n.z) - 1.0))))) + ((c[7] * ((0.2731371223926544189453125 * n.x) * n.z)) + (c[8] * (0.13656856119632720947265625 * ((n.x * n.x) - (n.y * n.y))))), vec3(0.0));\n    return _3148;\n}\n\nvec3 fa_ambient_light(vec3 n)\n{\n    if (fa_mesh_fs_params[11].w > 0.5)\n    {\n        vec3 c[9];\n        for (int k = 0; k < 9; k++)\n        {\n            int param = k;\n            c[k] = fa_sky_sh_coef(param);\n        }\n        vec3 param_1[9] = c;\n        vec3 param_2 = n;\n        return fa_sh_eval(param_1, param_2);\n    }\n    return fa_mesh_fs_params[1].xyz;\n}\n\nvec3 fa_indirect_diffuse(vec3 n)\n{\n    if (fa_lm.z > 0.5)\n    {\n        return textureLod(fa_lightmap_fa_env_smp, fa_lm.xy, 0.0).xyz;\n    }\n    vec3 param = n;\n    return fa_ambient_light(param);\n}\n\nint fa_cluster_index(int slot, int n)\n{\n    int param = (int(fa_mesh_fs_params[19].x) + int(fa_mesh_fs_params[19].w)) + ((slot + n) >> 2);\n    vec4 t = fa_light_texel(param);\n    return int(t[(slot + n) & 3]);\n}\n\nint fa_cl_light(int n)\n{\n    if (n < fa_cl_ndir)\n    {\n        return n;\n    }\n    int param = fa_cl_slot;\n    int param_1 = n - fa_cl_ndir;\n    return fa_cluster_index(param, param_1);\n}\n\nint fa_light_base(int li)\n{\n    return li * ((fa_mesh_fs_params[1].w > 4.5) ? 8 : 4);\n}\n\nbool fa_light_baked(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 3;\n    return fa_light_texel(param_1).w > 0.5;\n}\n\nfloat fa_light_type(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 1;\n    return fa_light_texel(param_1).w;\n}\n\nvec4 fa_atlas_fetch(vec2 texel)\n{\n    return textureLod(fa_light_atlas_fa_env_smp, texel / vec2(textureSize(fa_light_atlas_fa_env_smp, 0)), 0.0);\n}\n\nvec3 fa_cookie_sample(vec2 tile_origin, vec2 uv)\n{\n    vec2 param = (tile_origin + vec2(1.0)) + (clamp(uv, vec2(0.0), vec2(1.0)) * 254.0);\n    return fa_atlas_fetch(param).xyz;\n}\n\nvec3 fa_area_point(vec3 c, vec3 axis, vec3 ru, vec3 uu, float hx, float hy, float shape, vec3 p, vec3 r)\n{\n    bool _556 = dot(r, r) > 0.5;\n    if (shape > 1.5)\n    {\n        vec3 _569 = (c - (ru * hx)) - p;\n        vec3 _575 = ru * (2.0 * hx);\n        float _581 = max(dot(_575, _575), 9.9999999392252902907785028219223e-09);\n        float _585 = dot(_569, _575);\n        float t = clamp((-_585) / _581, 0.0, 1.0);\n        if (_556)\n        {\n            float _600 = dot(r, _575);\n            float _606 = _581 - (_600 * _600);\n            if (abs(_606) > (9.9999997473787516355514526367188e-06 * _581))\n            {\n                t = clamp(((dot(r, _569) * _600) - _585) / _606, 0.0, 1.0);\n            }\n        }\n        return (p + _569) + (_575 * t);\n    }\n    vec3 q = p;\n    float _638 = dot(r, axis);\n    bool _646;\n    if (_556)\n    {\n        _646 = abs(_638) > 9.9999997473787516355514526367188e-05;\n    }\n    else\n    {\n        _646 = _556;\n    }\n    if (_646)\n    {\n        float _656 = dot(c - p, axis) / _638;\n        if (_656 > 0.0)\n        {\n            q = p + (r * _656);\n        }\n    }\n    vec3 _669 = q - c;\n    vec2 xy = vec2(dot(_669, ru), dot(_669, uu));\n    if (shape > 0.5)\n    {\n        float _684 = length(xy);\n        if (_684 > hx)\n        {\n            xy *= (hx / _684);\n        }\n    }\n    else\n    {\n        xy = clamp(xy, vec2(-hx, -hy), vec2(hx, hy));\n    }\n    return (c + (ru * xy.x)) + (uu * xy.y);\n}\n\nint fa_cube_face(vec3 d)\n{\n    vec3 _327 = abs(d);\n    float _329 = _327.x;\n    float _331 = _327.y;\n    bool _332 = _329 >= _331;\n    bool _340;\n    if (_332)\n    {\n        _340 = _329 >= _327.z;\n    }\n    else\n    {\n        _340 = _332;\n    }\n    int _341;\n    if (_340)\n    {\n        _341 = (d.x > 0.0) ? 0 : 1;\n    }\n    else\n    {\n        int _356;\n        if (_331 >= _327.z)\n        {\n            _356 = (d.y > 0.0) ? 2 : 3;\n        }\n        else\n        {\n            _356 = (d.z > 0.0) ? 4 : 5;\n        }\n        _341 = _356;\n    }\n    return _341;\n}\n\nvoid fa_cube_face_basis(int f, out vec3 fwd, out vec3 up)\n{\n    if (f == 0)\n    {\n        fwd = vec3(1.0, 0.0, 0.0);\n        up = vec3(0.0, 1.0, 0.0);\n    }\n    else\n    {\n        if (f == 1)\n        {\n            fwd = vec3(-1.0, 0.0, 0.0);\n            up = vec3(0.0, 1.0, 0.0);\n        }\n        else\n        {\n            if (f == 2)\n            {\n                fwd = vec3(0.0, 1.0, 0.0);\n                up = vec3(0.0, 0.0, 1.0);\n            }\n            else\n            {\n                if (f == 3)\n                {\n                    fwd = vec3(0.0, -1.0, 0.0);\n                    up = vec3(0.0, 0.0, -1.0);\n                }\n                else\n                {\n                    if (f == 4)\n                    {\n                        fwd = vec3(0.0, 0.0, 1.0);\n                        up = vec3(0.0, 1.0, 0.0);\n                    }\n                    else\n                    {\n                        fwd = vec3(0.0, 0.0, -1.0);\n                        up = vec3(0.0, 1.0, 0.0);\n                    }\n                }\n            }\n        }\n    }\n}\n\nfloat fa_ies_sample(vec2 tile_origin, vec3 d, vec3 axis, vec3 right, vec3 up)\n{\n    float _476 = dot(d, right);\n    float _480 = dot(d, up);\n    float _491;\n    if (((_476 * _476) + (_480 * _480)) > 1.0000000133514319600180897396058e-10)\n    {\n        _491 = atan(_480, _476) * 0.15915493667125701904296875;\n    }\n    else\n    {\n        _491 = 0.0;\n    }\n    vec2 param = tile_origin + vec2(1.0 + ((_491 - floor(_491)) * 64.0), 1.0 + (acos(clamp(dot(d, axis), -1.0, 1.0)) * 10.18591594696044921875));\n    return fa_atlas_fetch(param).x;\n}\n\nLightSample fa_light_sample_n(int li, vec3 world_pos, vec3 n)\n{\n    int param = li;\n    int _722 = fa_light_base(param);\n    bool _726 = fa_mesh_fs_params[1].w > 4.5;\n    int param_1 = _722;\n    vec4 _730 = fa_light_texel(param_1);\n    int param_2 = _722 + 1;\n    vec4 _735 = fa_light_texel(param_2);\n    float _738 = _735.w;\n    float atten = 1.0;\n    float dist = 0.0;\n    fa_light_tint = vec3(1.0);\n    bool _750 = _726 && (_738 > 2.5);\n    fa_light_is_area = _750;\n    bool _752 = _738 < 0.5;\n    vec3 l;\n    if (_752)\n    {\n        l = normalize(_730.xyz);\n        if (_726)\n        {\n            int param_3 = _722 + 6;\n            vec4 _766 = fa_light_texel(param_3);\n            if (_766.z > 0.5)\n            {\n                int param_4 = _722 + 4;\n                vec4 _776 = fa_light_texel(param_4);\n                int param_5 = _722 + 5;\n                vec4 _781 = fa_light_texel(param_5);\n                vec2 param_6 = _766.xy;\n                vec2 param_7 = fract(vec2(dot(world_pos, _776.xyz) * _776.w, (-dot(world_pos, _781.xyz)) * _781.w) + vec2(0.5));\n                fa_light_tint = fa_cookie_sample(param_6, param_7);\n            }\n        }\n    }\n    else\n    {\n        vec3 _811 = _730.xyz;\n        vec3 _813 = _811 - world_pos;\n        vec3 to_light = _813;\n        float _816 = length(_813);\n        float reach = _816;\n        bool front = true;\n        if (_750)\n        {\n            int param_8 = _722 + 7;\n            reach = max(_816 - fa_light_texel(param_8).w, 0.0);\n            int param_9 = _722 + 4;\n            vec4 _840 = fa_light_texel(param_9);\n            int param_10 = _722 + 5;\n            vec4 _845 = fa_light_texel(param_10);\n            int param_11 = _722 + 6;\n            vec4 _850 = fa_light_texel(param_11);\n            float _851 = _850.w;\n            int param_12 = _722 + 2;\n            vec3 _858 = normalize(fa_light_texel(param_12).xyz);\n            bool _860 = _851 > 1.5;\n            bool _868;\n            if (!_860)\n            {\n                _868 = dot(_858, to_light) < 0.0;\n            }\n            else\n            {\n                _868 = _860;\n            }\n            front = _868;\n            vec3 r = vec3(0.0);\n            vec3 _877 = fa_mesh_fs_params[0].xyz - world_pos;\n            bool _881 = dot(n, n) > 0.5;\n            bool _889;\n            if (_881)\n            {\n                _889 = dot(_877, _877) > 9.9999999600419720025001879548654e-13;\n            }\n            else\n            {\n                _889 = _881;\n            }\n            if (_889)\n            {\n                r = reflect(-normalize(_877), normalize(n));\n            }\n            vec3 param_13 = _811;\n            vec3 param_14 = _858;\n            vec3 param_15 = _840.xyz;\n            vec3 param_16 = _845.xyz;\n            float param_17 = _840.w;\n            float param_18 = _845.w;\n            float param_19 = _851;\n            vec3 param_20 = world_pos;\n            vec3 param_21 = r;\n            to_light = fa_area_point(param_13, param_14, param_15, param_16, param_17, param_18, param_19, param_20, param_21) - world_pos;\n        }\n        float _925 = length(to_light);\n        dist = _925;\n        l = to_light / vec3(max(_925, 9.9999997473787516355514526367188e-05));\n        float _939 = reach / max(_730.w, 0.001000000047497451305389404296875);\n        float _945 = clamp(1.0 - (_939 * _939), 0.0, 1.0);\n        float _947;\n        if (front)\n        {\n            _947 = _945 * _945;\n        }\n        else\n        {\n            _947 = 0.0;\n        }\n        atten = _947;\n        bool _958 = _738 < 2.5;\n        if ((_738 > 1.5) && _958)\n        {\n            int param_22 = _722 + 2;\n            vec4 _966 = fa_light_texel(param_22);\n            float _976 = _966.w;\n            int param_23 = _722 + 3;\n            vec4 _981 = fa_light_texel(param_23);\n            float _982 = _981.x;\n            float cos_inner = _982;\n            if (_982 > 1.5)\n            {\n                cos_inner = mix(_976, 1.0, 0.25);\n            }\n            atten *= smoothstep(_976, cos_inner, dot(-l, normalize(_966.xyz)));\n        }\n        if (_726 && (_738 < 1.5))\n        {\n            int param_24 = _722 + 6;\n            vec4 _1006 = fa_light_texel(param_24);\n            if (_1006.z > 0.5)\n            {\n                vec3 _1014 = -to_light;\n                int param_25 = _722 + 4;\n                int param_26 = _722 + 5;\n                vec3 _1028 = fa_light_texel(param_25).xyz;\n                vec3 _1032 = fa_light_texel(param_26).xyz;\n                vec3 _1041 = vec3(dot(_1014, _1028), dot(_1014, _1032), dot(_1014, cross(_1028, _1032)));\n                vec3 param_27 = _1041;\n                int _1045 = fa_cube_face(param_27);\n                int param_28 = _1045;\n                vec3 param_29;\n                vec3 param_30;\n                fa_cube_face_basis(param_28, param_29, param_30);\n                vec2 _1072 = vec2(dot(_1041, cross(param_29, param_30)), dot(_1041, param_30)) / vec2(max(dot(_1041, param_29), 9.9999997473787516355514526367188e-05));\n                int _1076 = _1045 / 3;\n                vec2 param_31 = _1006.xy + (vec2(float(_1045 - (_1076 * 3)), float(_1076)) * 256.0);\n                vec2 param_32 = vec2(0.5 + (0.5 * _1072.x), 0.5 - (0.5 * _1072.y));\n                fa_light_tint = fa_cookie_sample(param_31, param_32);\n            }\n            int param_33 = _722 + 7;\n            vec4 _1106 = fa_light_texel(param_33);\n            if (_1106.z > 0.5)\n            {\n                int param_34 = _722 + 2;\n                int param_35 = _722 + 4;\n                int param_36 = _722 + 5;\n                vec2 param_37 = _1106.xy;\n                vec3 param_38 = -l;\n                vec3 param_39 = normalize(fa_light_texel(param_34).xyz);\n                vec3 param_40 = fa_light_texel(param_35).xyz;\n                vec3 param_41 = fa_light_texel(param_36).xyz;\n                atten *= fa_ies_sample(param_37, param_38, param_39, param_40, param_41);\n            }\n        }\n        else\n        {\n            if (_726 && _958)\n            {\n                int param_42 = _722 + 6;\n                vec4 _1153 = fa_light_texel(param_42);\n                int param_43 = _722 + 7;\n                vec4 _1158 = fa_light_texel(param_43);\n                bool _1161 = _1153.z > 0.5;\n                bool _1168;\n                if (!_1161)\n                {\n                    _1168 = _1158.z > 0.5;\n                }\n                else\n                {\n                    _1168 = _1161;\n                }\n                if (_1168)\n                {\n                    int param_44 = _722 + 2;\n                    vec4 _1175 = fa_light_texel(param_44);\n                    vec3 _1179 = normalize(_1175.xyz);\n                    int param_45 = _722 + 4;\n                    vec4 _1184 = fa_light_texel(param_45);\n                    int param_46 = _722 + 5;\n                    vec4 _1189 = fa_light_texel(param_46);\n                    if (_1161)\n                    {\n                        vec3 _1197 = -to_light;\n                        float _1204 = _1175.w;\n                        float _1220 = 0.5 / max(dot(_1197, _1179) * (sqrt(max(1.0 - (_1204 * _1204), 0.0)) / max(_1204, 0.001000000047497451305389404296875)), 9.9999997473787516355514526367188e-05);\n                        vec2 param_47 = _1153.xy;\n                        vec2 param_48 = vec2(0.5 + (dot(_1197, _1184.xyz) * _1220), 0.5 - (dot(_1197, _1189.xyz) * _1220));\n                        fa_light_tint = fa_cookie_sample(param_47, param_48);\n                    }\n                    if (_1158.z > 0.5)\n                    {\n                        vec2 param_49 = _1158.xy;\n                        vec3 param_50 = -l;\n                        vec3 param_51 = _1179;\n                        vec3 param_52 = _1184.xyz;\n                        vec3 param_53 = _1189.xyz;\n                        atten *= fa_ies_sample(param_49, param_50, param_51, param_52, param_53);\n                    }\n                }\n            }\n        }\n    }\n    vec3 _4298 = _735.xyz * atten;\n    if (_726)\n    {\n        _4298 *= fa_light_tint;\n    }\n    int _1288;\n    if (_752)\n    {\n        _1288 = 0;\n    }\n    else\n    {\n        _1288 = ((_738 > 1.5) && (_738 < 2.5)) ? 2 : 1;\n    }\n    return LightSample(l, _4298, atten, 1.0, dist, _1288);\n}\n\nfloat fa_shadow_split_at(int i)\n{\n    float _2025;\n    if (i == 0)\n    {\n        _2025 = fa_shadows[24].x;\n    }\n    else\n    {\n        float _2041;\n        if (i == 1)\n        {\n            _2041 = fa_shadows[24].y;\n        }\n        else\n        {\n            float _2049;\n            if (i == 2)\n            {\n                _2049 = fa_shadows[24].z;\n            }\n            else\n            {\n                _2049 = fa_shadows[24].w;\n            }\n            _2041 = _2049;\n        }\n        _2025 = _2041;\n    }\n    return _2025;\n}\n\nfloat fa_shadow_depth(inout vec2 uv, vec4 rect)\n{\n    uv = clamp(uv, rect.xy, rect.zw);\n    return textureLod(fa_shadow_tex_fa_shadow_smp, uv, 0.0).x;\n}\n\nfloat fa_shadow_fetch(vec2 uv, vec4 rect, vec3 conv)\n{\n    vec2 param = uv;\n    vec4 param_1 = rect;\n    float _2082 = fa_shadow_depth(param, param_1);\n    float _2086;\n    if (conv.x < 0.5)\n    {\n        _2086 = _2082;\n    }\n    else\n    {\n        _2086 = (conv.y * conv.z) / (conv.z - (_2082 * (conv.z - conv.y)));\n    }\n    return _2086;\n}\n\nfloat fa_shadow_noise()\n{\n    return fract(52.98291778564453125 * fract(dot(gl_FragCoord.xy, vec2(0.067110560834407806396484375, 0.005837149918079376220703125))));\n}\n\nvec2 fa_shadow_vogel(int k, int n, float phi)\n{\n    float _2013 = (float(k) * 2.3999631404876708984375) + phi;\n    return vec2(cos(_2013), sin(_2013)) * sqrt((float(k) + 0.5) / float(n));\n}\n\nfloat fa_shadow_filter(vec2 uv, vec4 rect, float zr, float texel_m, float unit, float reach, float plane, vec3 conv, int mode, float k)\n{\n    if (mode == 1)\n    {\n        vec2 param = uv;\n        vec4 param_1 = rect;\n        vec3 param_2 = conv;\n        return float(zr <= fa_shadow_fetch(param, param_1, param_2));\n    }\n    float _2132 = fa_shadow_noise() * 6.283185482025146484375;\n    float radius = 1.5;\n    if (mode == 2)\n    {\n        float _2141;\n        if (k < 0.0)\n        {\n            _2141 = (-k) / max(zr, 0.100000001490116119384765625);\n        }\n        else\n        {\n            _2141 = k;\n        }\n        float _2161 = clamp((_2141 * reach) / texel_m, 3.0, 12.0);\n        float sum = 0.0;\n        float cnt = 0.0;\n        for (int i = 0; i < 16; i++)\n        {\n            int param_3 = i;\n            int param_4 = 16;\n            float param_5 = _2132;\n            vec2 _2180 = fa_shadow_vogel(param_3, param_4, param_5) * _2161;\n            vec2 param_6 = uv + (_2180 * fa_shadows[26].zw);\n            vec4 param_7 = rect;\n            vec3 param_8 = conv;\n            float _2192 = fa_shadow_fetch(param_6, param_7, param_8);\n            if (_2192 < (zr - (length(_2180) * plane)))\n            {\n                sum += _2192;\n                cnt += 1.0;\n            }\n        }\n        if (cnt < 0.5)\n        {\n            return 1.0;\n        }\n        float _2218 = sum / cnt;\n        float _2228;\n        if (k < 0.0)\n        {\n            _2228 = (-k) / max(_2218, 0.0500000007450580596923828125);\n        }\n        else\n        {\n            _2228 = k;\n        }\n        radius = clamp(((max(zr - _2218, 0.0) * unit) * _2228) / texel_m, 1.5, 16.0);\n    }\n    float lit = 0.0;\n    int _2250 = (mode == 2) ? 24 : 16;\n    for (int i_1 = 0; i_1 < _2250; i_1++)\n    {\n        int param_9 = i_1;\n        int param_10 = _2250;\n        float param_11 = _2132;\n        vec2 _2269 = fa_shadow_vogel(param_9, param_10, param_11) * radius;\n        vec2 param_12 = uv + (_2269 * fa_shadows[26].zw);\n        vec4 param_13 = rect;\n        vec3 param_14 = conv;\n        lit += float((zr - (length(_2269) * plane)) <= fa_shadow_fetch(param_12, param_13, param_14));\n    }\n    return lit / float(_2250);\n}\n\nfloat fa_shadow_cascade(int ci, vec3 world, vec3 n, vec3 l)\n{\n    float _2311 = max(fa_shadows[ci * 1 + 20].y, 0.001000000047497451305389404296875);\n    float _2316 = clamp(dot(n, l), 0.0, 1.0);\n    float _2322 = sqrt(1.0 - (_2316 * _2316));\n    float _2329 = min(_2322 / max(_2316, 0.20000000298023223876953125), 4.0);\n    float _2334;\n    if (fa_shadows[26].y > 0.0)\n    {\n        _2334 = fa_shadows[26].y;\n    }\n    else\n    {\n        _2334 = 1.5 * fa_shadows[ci * 1 + 20].x;\n    }\n    vec4 _2359 = mat4(fa_shadows[ci * 4 + 0], fa_shadows[ci * 4 + 1], fa_shadows[ci * 4 + 2], fa_shadows[ci * 4 + 3]) * vec4(world + (n * (_2334 * _2322)), 1.0);\n    float _2366 = _2359.x;\n    bool _2369 = _2366 < fa_shadows[ci * 1 + 16].x;\n    bool _2378;\n    if (!_2369)\n    {\n        _2378 = _2366 > fa_shadows[ci * 1 + 16].z;\n    }\n    else\n    {\n        _2378 = _2369;\n    }\n    bool _2387;\n    if (!_2378)\n    {\n        _2387 = _2359.y < fa_shadows[ci * 1 + 16].y;\n    }\n    else\n    {\n        _2387 = _2378;\n    }\n    bool _2396;\n    if (!_2387)\n    {\n        _2396 = _2359.y > fa_shadows[ci * 1 + 16].w;\n    }\n    else\n    {\n        _2396 = _2387;\n    }\n    bool _2403;\n    if (!_2396)\n    {\n        _2403 = _2359.z > 1.0;\n    }\n    else\n    {\n        _2403 = _2396;\n    }\n    if (_2403)\n    {\n        return -1.0;\n    }\n    float _2411;\n    if (fa_shadows[26].x > 0.0)\n    {\n        _2411 = fa_shadows[26].x;\n    }\n    else\n    {\n        _2411 = 1.5 * fa_shadows[ci * 1 + 20].x;\n    }\n    vec2 param = _2359.xy;\n    vec4 param_1 = fa_shadows[ci * 1 + 16];\n    float param_2 = _2359.z - ((_2411 * (1.0 + (0.5 * _2329))) / _2311);\n    float param_3 = fa_shadows[ci * 1 + 20].x;\n    float param_4 = _2311;\n    float param_5 = _2311 * 0.25;\n    float param_6 = ((fa_shadows[ci * 1 + 20].x * min(_2329, 3.0)) * 0.5) / _2311;\n    vec3 param_7 = vec3(0.0);\n    int param_8 = int(fa_shadows[25].z + 0.5);\n    float param_9 = fa_shadows[25].w;\n    return fa_shadow_filter(param, param_1, param_2, param_3, param_4, param_5, param_6, param_7, param_8, param_9);\n}\n\nfloat fa_shadow_sun(vec3 world, vec3 n, vec3 l)\n{\n    if (fa_mesh_fs_params[5].z < 0.5)\n    {\n        return 1.0;\n    }\n    int _2789 = int(fa_shadows[25].x + 0.5);\n    if (_2789 < 1)\n    {\n        return 1.0;\n    }\n    float _2804 = dot(world - fa_shadows[27].xyz, fa_shadows[28].xyz);\n    int param = _2789 - 1;\n    if (_2804 > fa_shadow_split_at(param))\n    {\n        return 1.0;\n    }\n    int ci = 0;\n    bool _2816 = _2789 > 1;\n    bool _2823;\n    if (_2816)\n    {\n        _2823 = _2804 > fa_shadows[24].x;\n    }\n    else\n    {\n        _2823 = _2816;\n    }\n    if (_2823)\n    {\n        ci = 1;\n    }\n    bool _2827 = _2789 > 2;\n    bool _2834;\n    if (_2827)\n    {\n        _2834 = _2804 > fa_shadows[24].y;\n    }\n    else\n    {\n        _2834 = _2827;\n    }\n    if (_2834)\n    {\n        ci = 2;\n    }\n    bool _2838 = _2789 > 3;\n    bool _2845;\n    if (_2838)\n    {\n        _2845 = _2804 > fa_shadows[24].z;\n    }\n    else\n    {\n        _2845 = _2838;\n    }\n    if (_2845)\n    {\n        ci = 3;\n    }\n    float s = -1.0;\n    for (int k = 0; k < 4; k++)\n    {\n        if (ci >= _2789)\n        {\n            break;\n        }\n        int param_1 = ci;\n        vec3 param_2 = world;\n        vec3 param_3 = n;\n        vec3 param_4 = l;\n        float _2871 = fa_shadow_cascade(param_1, param_2, param_3, param_4);\n        s = _2871;\n        if (_2871 >= 0.0)\n        {\n            break;\n        }\n        ci++;\n    }\n    if (s < 0.0)\n    {\n        return 1.0;\n    }\n    if (fa_shadows[25].y > 0.0)\n    {\n        float _2896;\n        if (ci > 0)\n        {\n            int param_5 = ci - 1;\n            _2896 = fa_shadow_split_at(param_5);\n        }\n        else\n        {\n            _2896 = fa_shadows[28].w;\n        }\n        int param_6 = ci;\n        float _2915 = fa_shadows[25].y * max(fa_shadow_split_at(param_6) - _2896, 9.9999997473787516355514526367188e-05);\n        int param_7 = ci;\n        float _2926 = clamp((_2804 - (fa_shadow_split_at(param_7) - _2915)) / _2915, 0.0, 1.0);\n        if (_2926 > 0.0)\n        {\n            float s2 = 1.0;\n            if ((ci + 1) < _2789)\n            {\n                int param_8 = ci + 1;\n                vec3 param_9 = world;\n                vec3 param_10 = n;\n                vec3 param_11 = l;\n                float _2947 = fa_shadow_cascade(param_8, param_9, param_10, param_11);\n                s2 = _2947;\n                if (_2947 < 0.0)\n                {\n                    s2 = s;\n                }\n            }\n            s = mix(s, s2, _2926);\n        }\n    }\n    return s;\n}\n\nfloat fa_shadow_factor(vec3 n, vec3 l)\n{\n    vec3 param = fa_world_pos;\n    vec3 param_1 = n;\n    vec3 param_2 = l;\n    return fa_shadow_sun(param, param_1, param_2);\n}\n\nfloat fa_shadow_local(int li, vec3 lpos, vec3 world, vec3 n, vec3 l)\n{\n    bool _2469 = fa_mesh_fs_params[5].z < 0.5;\n    bool _2476;\n    if (!_2469)\n    {\n        _2476 = fa_shadows[29].x < 0.5;\n    }\n    else\n    {\n        _2476 = _2469;\n    }\n    if (_2476)\n    {\n        return 1.0;\n    }\n    int param = (int(fa_shadows[29].x + 0.5) - 1) + li;\n    vec4 _2489 = fa_light_texel(param);\n    float _2490 = _2489.x;\n    if (_2490 < 0.0)\n    {\n        return 1.0;\n    }\n    int _2499 = int(_2490 + 0.5);\n    int param_1 = _2499;\n    vec4 _2503 = fa_light_texel(param_1);\n    int param_2 = _2499 + 1;\n    vec4 _2508 = fa_light_texel(param_2);\n    float fade = 1.0;\n    float _2511 = _2503.y;\n    if (_2511 > 0.0)\n    {\n        float _2528 = 1.0 - smoothstep(0.75 * _2511, _2511, length(world - fa_shadows[27].xyz));\n        fade = _2528;\n        if (_2528 <= 0.0)\n        {\n            return 1.0;\n        }\n    }\n    int face = 0;\n    if (_2503.x > 1.5)\n    {\n        vec3 param_3 = world - lpos;\n        face = fa_cube_face(param_3);\n    }\n    int _2552 = (_2499 + 2) + (face * 6);\n    int param_4 = _2552;\n    int param_5 = _2552 + 1;\n    int param_6 = _2552 + 3;\n    vec4 _2566 = fa_light_texel(param_6);\n    int param_7 = _2552 + 4;\n    vec4 _2571 = fa_light_texel(param_7);\n    int param_8 = _2552 + 5;\n    vec4 _2576 = fa_light_texel(param_8);\n    float _2588 = _2576.x * max(dot(_2566, vec4(world, 1.0)), 0.001000000047497451305389404296875);\n    float _2593 = clamp(dot(n, l), 0.0, 1.0);\n    float _2616 = clamp(dot(n, _2566.xyz), -1.0, 1.0);\n    float _2635 = min(sqrt(1.0 - (_2616 * _2616)) / max(abs(dot(n, world - lpos)) / max(dot(_2566, vec4(world, 1.0)), 0.001000000047497451305389404296875), 0.20000000298023223876953125), 4.0);\n    float _2638 = _2508.y;\n    float _2640;\n    if (_2638 > 0.0)\n    {\n        _2640 = _2638;\n    }\n    else\n    {\n        _2640 = 1.5 * _2588;\n    }\n    vec4 _2660 = vec4(world + (n * (_2640 * sqrt(1.0 - (_2593 * _2593)))), 1.0);\n    float _2664 = dot(_2566, _2660);\n    float _2667 = _2576.y;\n    if (_2664 < _2667)\n    {\n        return 1.0;\n    }\n    vec2 _2682 = vec2(dot(fa_light_texel(param_4), _2660), dot(fa_light_texel(param_5), _2660)) / vec2(_2664);\n    float _2684 = _2682.x;\n    bool _2687 = _2684 < _2571.x;\n    bool _2696;\n    if (!_2687)\n    {\n        _2696 = _2684 > _2571.z;\n    }\n    else\n    {\n        _2696 = _2687;\n    }\n    bool _2705;\n    if (!_2696)\n    {\n        _2705 = _2682.y < _2571.y;\n    }\n    else\n    {\n        _2705 = _2696;\n    }\n    bool _2714;\n    if (!_2705)\n    {\n        _2714 = _2682.y > _2571.w;\n    }\n    else\n    {\n        _2714 = _2705;\n    }\n    if (_2714)\n    {\n        return 1.0;\n    }\n    float _2720 = _2508.x;\n    float _2722;\n    if (_2720 > 0.0)\n    {\n        _2722 = _2720;\n    }\n    else\n    {\n        _2722 = 1.5 * _2588;\n    }\n    vec2 param_9 = _2682;\n    vec4 param_10 = _2571;\n    float param_11 = _2664 - (_2722 * (1.0 + (0.5 * _2635)));\n    float param_12 = _2588;\n    float param_13 = 1.0;\n    float param_14 = _2576.z * 0.25;\n    float param_15 = (_2588 * min(_2635, 3.0)) * 0.5;\n    vec3 param_16 = vec3(1.0, _2667, _2576.z);\n    int param_17 = int(_2503.z + 0.5);\n    float param_18 = _2503.w;\n    return mix(1.0, fa_shadow_filter(param_9, param_10, param_11, param_12, param_13, param_14, param_15, param_16, param_17, param_18), fade);\n}\n\nLightSample fa_light_shadowed(int li, vec3 world_pos, vec3 gn)\n{\n    bool _3262 = fa_lm.z > 0.5;\n    bool _3268;\n    if (_3262)\n    {\n        int param = li;\n        _3268 = fa_light_baked(param);\n    }\n    else\n    {\n        _3268 = _3262;\n    }\n    if (_3268)\n    {\n        int param_1 = li;\n        return LightSample(vec3(0.0, 1.0, 0.0), vec3(0.0), 0.0, 1.0, 0.0, int(fa_light_type(param_1) + 0.5));\n    }\n    int param_2 = li;\n    vec3 param_3 = world_pos;\n    vec3 param_4 = gn;\n    LightSample _3292 = fa_light_sample_n(param_2, param_3, param_4);\n    vec3 _4324 = _3292.color;\n    float _4326 = _3292.shadow;\n    if ((_3292.type == 0) && (li == 0))\n    {\n        vec3 param_5 = gn;\n        vec3 param_6 = _3292.direction;\n        float _3306 = fa_shadow_factor(param_5, param_6);\n        _4326 = _3306;\n        _4324 *= _3306;\n    }\n    else\n    {\n        bool _3317 = _3292.type != 0;\n        bool _3323;\n        if (_3317)\n        {\n            _3323 = _3292.attenuation > 0.0;\n        }\n        else\n        {\n            _3323 = _3317;\n        }\n        if (_3323)\n        {\n            int param_7 = li;\n            int param_8 = fa_light_base(param_7);\n            int param_9 = li;\n            vec3 param_10 = fa_light_texel(param_8).xyz;\n            vec3 param_11 = world_pos;\n            vec3 param_12 = gn;\n            vec3 param_13 = _3292.direction;\n            float _3342 = fa_shadow_local(param_9, param_10, param_11, param_12, param_13);\n            _4326 = _3342;\n            _4324 *= _3342;\n        }\n    }\n    return LightSample(_3292.direction, _4324, _3292.attenuation, _4326, _3292._distance, _3292.type);\n}\n\nvec3 light(SurfaceInput i, Surface s, LightSample l)\n{\n    float _3362;\n    if (dot(s.normal, l.direction) > 0.5)\n    {\n        _3362 = 1.0;\n    }\n    else\n    {\n        _3362 = fa_material[0].x;\n    }\n    return (s.albedo * l.color) * _3362;\n}\n\nvec3 fa_shadow_debug(vec3 color, vec3 world)\n{\n    if (fa_shadows[27].w < 0.5)\n    {\n        return color;\n    }\n    int _2971 = int(fa_shadows[25].x + 0.5);\n    float _2981 = dot(world - fa_shadows[27].xyz, fa_shadows[28].xyz);\n    vec3 tint = vec3(0.3499999940395355224609375);\n    bool _2986 = _2971 > 0;\n    bool _2995;\n    if (_2986)\n    {\n        int param = _2971 - 1;\n        _2995 = _2981 <= fa_shadow_split_at(param);\n    }\n    else\n    {\n        _2995 = _2986;\n    }\n    if (_2995)\n    {\n        tint = vec3(1.0, 0.1500000059604644775390625, 0.100000001490116119384765625);\n        bool _3001 = _2971 > 1;\n        bool _3008;\n        if (_3001)\n        {\n            _3008 = _2981 > fa_shadows[24].x;\n        }\n        else\n        {\n            _3008 = _3001;\n        }\n        if (_3008)\n        {\n            tint = vec3(0.100000001490116119384765625, 0.89999997615814208984375, 0.20000000298023223876953125);\n        }\n        bool _3014 = _2971 > 2;\n        bool _3021;\n        if (_3014)\n        {\n            _3021 = _2981 > fa_shadows[24].y;\n        }\n        else\n        {\n            _3021 = _3014;\n        }\n        if (_3021)\n        {\n            tint = vec3(0.1500000059604644775390625, 0.300000011920928955078125, 1.0);\n        }\n        bool _3027 = _2971 > 3;\n        bool _3034;\n        if (_3027)\n        {\n            _3034 = _2981 > fa_shadows[24].z;\n        }\n        else\n        {\n            _3034 = _3027;\n        }\n        if (_3034)\n        {\n            tint = vec3(1.0, 0.89999997615814208984375, 0.100000001490116119384765625);\n        }\n    }\n    return mix(color, tint, vec3(0.550000011920928955078125));\n}\n\nvoid main()\n{\n    fa_inst_load();\n    vec3 _4165 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _4165 = -_4165;\n    }\n    vec3 _3750 = normalize(fa_mesh_fs_params[0].xyz - fa_world_pos);\n    vec3 param = fa_world_pos;\n    fa_cluster_begin(param);\n    SurfaceInput param_1 = SurfaceInput(fa_world_pos, _4165, fa_world_tangent, fa_uv, fa_vertex_color, _3750, gl_FrontFacing);\n    Surface _3758 = fa_standard_surface(param_1);\n    vec3 _4196 = _3758.albedo;\n    float _4197 = _3758.alpha;\n    vec3 _4198 = _3758.normal;\n    float _4199 = _3758.metallic;\n    float _4200 = _3758.roughness;\n    float _4201 = _3758.occlusion;\n    vec3 _4202 = _3758.emission;\n    float _4203 = _3758.clearcoat;\n    float _4204 = _3758.clearcoat_roughness;\n    vec3 _4205 = _3758.sheen_color;\n    float _4206 = _3758.sheen_roughness;\n    float _4207 = _3758.anisotropy;\n    float _4208 = _3758.anisotropy_rotation;\n    float _4209 = _3758.specular;\n    float _4210 = _3758.ior;\n    vec3 _4211 = _3758.specular_color;\n    SurfaceInput param_2 = SurfaceInput(fa_world_pos, _4165, fa_world_tangent, fa_uv, fa_vertex_color, _3750, gl_FrontFacing);\n    Surface param_3 = _3758;\n    surface(param_2, param_3);\n    _4196 = param_3.albedo;\n    _4197 = param_3.alpha;\n    _4198 = param_3.normal;\n    _4199 = param_3.metallic;\n    _4200 = param_3.roughness;\n    _4201 = param_3.occlusion;\n    _4202 = param_3.emission;\n    _4203 = param_3.clearcoat;\n    _4204 = param_3.clearcoat_roughness;\n    _4205 = param_3.sheen_color;\n    _4206 = param_3.sheen_roughness;\n    _4207 = param_3.anisotropy;\n    _4208 = param_3.anisotropy_rotation;\n    _4209 = param_3.specular;\n    _4210 = param_3.ior;\n    _4211 = param_3.specular_color;\n    vec3 param_4 = fa_world_pos;\n    vec3 param_5 = _4165;\n    vec3 param_6 = param_3.albedo;\n    vec3 param_7 = param_3.normal;\n    fa_apply_decals(param_4, param_5, param_6, param_7);\n    _4196 = param_6;\n    _4198 = param_7;\n    vec3 result;\n    if (fa_mesh_fs_params[3].w > 0.5)\n    {\n        result = _4196;\n    }\n    else\n    {\n        vec3 _3796 = _4198;\n        vec3 _3797 = normalize(_3796);\n        _4198 = _3797;\n        vec3 param_8 = _3797;\n        vec3 lit = (fa_indirect_diffuse(param_8) * _4196) * _4201;\n        int _3816 = fa_cl_ndir + fa_cl_local;\n        for (int ln = 0; ln < _3816; ln++)\n        {\n            int param_9 = ln;\n            int _3829 = fa_cl_light(param_9);\n            bool _3832 = fa_lm.z > 0.5;\n            bool _3838;\n            if (_3832)\n            {\n                int param_10 = _3829;\n                _3838 = fa_light_baked(param_10);\n            }\n            else\n            {\n                _3838 = _3832;\n            }\n            if (_3838)\n            {\n                continue;\n            }\n            int param_11 = _3829;\n            vec3 param_12 = fa_world_pos;\n            vec3 param_13 = _4165;\n            LightSample _3850 = fa_light_shadowed(param_11, param_12, param_13);\n            SurfaceInput param_14 = SurfaceInput(fa_world_pos, _4165, fa_world_tangent, fa_uv, fa_vertex_color, _3750, gl_FrontFacing);\n            Surface param_15 = Surface(_4196, _4197, _4198, _4199, _4200, _4201, _4202, _4203, _4204, _4205, _4206, _4207, _4208, _4209, _4210, _4211);\n            LightSample param_16 = _3850;\n            lit += light(param_14, param_15, param_16);\n        }\n        result = lit;\n    }\n    vec3 _3865 = result;\n    vec3 _3866 = _3865 + _4202;\n    result = _3866;\n    vec3 param_17 = _3866;\n    vec3 param_18 = fa_world_pos;\n    result = fa_shadow_debug(param_17, param_18);\n    bool _3875 = fa_mesh_fs_params[7].w > 0.0;\n    bool _3882;\n    if (!_3875)\n    {\n        _3882 = fa_mesh_fs_params[8].y > 0.0;\n    }\n    else\n    {\n        _3882 = _3875;\n    }\n    if (_3882)\n    {\n        vec3 _3891 = fa_world_pos - fa_mesh_fs_params[0].xyz;\n        float _3897 = dot(_3891, fa_mesh_fs_params[9].xyz);\n        bool _3901 = fa_mesh_fs_params[9].w > 0.5;\n        float _3902;\n        if (_3901)\n        {\n            _3902 = _3897;\n        }\n        else\n        {\n            _3902 = length(_3891);\n        }\n        float _3914 = _3902 - fa_mesh_fs_params[8].x;\n        if (_3914 > 0.0)\n        {\n            float _3923 = fa_mesh_fs_params[7].w * _3914;\n            float tau = _3923 * _3923;\n            if (fa_mesh_fs_params[8].y > 0.0)\n            {\n                float _3939;\n                if (_3901)\n                {\n                    _3939 = fa_world_pos.y - (fa_mesh_fs_params[9].y * _3897);\n                }\n                else\n                {\n                    _3939 = fa_mesh_fs_params[0].y;\n                }\n                float _3960 = mix(_3939, fa_world_pos.y, clamp(fa_mesh_fs_params[8].x / _3902, 0.0, 1.0));\n                float _3964 = fa_world_pos.y - _3960;\n                float _3969 = _3960 - fa_mesh_fs_params[8].z;\n                float _3974 = fa_world_pos.y - fa_mesh_fs_params[8].z;\n                bool _3977 = _3969 <= 0.0;\n                bool _3978 = !_3977;\n                bool _3984;\n                if (_3978)\n                {\n                    _3984 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _3984 = _3977;\n                }\n                float _3985;\n                if (_3984)\n                {\n                    _3985 = fa_mesh_fs_params[8].y;\n                }\n                else\n                {\n                    _3985 = fa_mesh_fs_params[8].y * exp(-min(fa_mesh_fs_params[8].w * _3969, 80.0));\n                }\n                bool _4012;\n                if (_3978)\n                {\n                    _4012 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _4012 = _3977;\n                }\n                float _4013;\n                if (_4012)\n                {\n                    _4013 = fa_mesh_fs_params[8].y * _3969;\n                }\n                else\n                {\n                    _4013 = (fa_mesh_fs_params[8].y * (1.0 - exp(-min(fa_mesh_fs_params[8].w * _3969, 80.0)))) / fa_mesh_fs_params[8].w;\n                }\n                bool _4038 = _3974 <= 0.0;\n                bool _4045;\n                if (!_4038)\n                {\n                    _4045 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _4045 = _4038;\n                }\n                float _4046;\n                if (_4045)\n                {\n                    _4046 = fa_mesh_fs_params[8].y * _3974;\n                }\n                else\n                {\n                    _4046 = (fa_mesh_fs_params[8].y * (1.0 - exp(-min(fa_mesh_fs_params[8].w * _3974, 80.0)))) / fa_mesh_fs_params[8].w;\n                }\n                float _4073;\n                if (abs(_3964) < 0.001000000047497451305389404296875)\n                {\n                    _4073 = _3985;\n                }\n                else\n                {\n                    _4073 = (_4046 - _4013) / _3964;\n                }\n                tau += (_3914 * max(_4073, 0.0));\n            }\n            result = mix(result, fa_mesh_fs_params[7].xyz, vec3(clamp(1.0 - exp(-clamp(tau, 0.0, 80.0)), 0.0, 1.0)));\n        }\n    }\n    fa_frag_color = vec4(result, _4197);\n}\n\n",
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
            "size": 384,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_378",
            "glsl_uniforms": [
              {
                "type": "vec4",
                "array_count": 24,
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
            "inst_name": "_2035",
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
            "inst_name": "_3368",
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
              "name": "fa_env_tex",
              "multisampled": false,
              "type": "cube",
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
            "name": "fa_env_tex_fa_env_smp",
            "view_name": "fa_env_tex",
            "sampler_name": "fa_env_smp",
            "view_slot": 14,
            "sampler_slot": 10,
            "glsl_name": "fa_env_tex_fa_env_smp"
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
          }
        ]
      }
    },
    "mesh_skin": {
      "vs": "#version 430\n\nstruct VertexData\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 color;\n    vec3 object_pos;\n};\n\nuniform vec4 fa_mesh_vs_params[11];\nuniform vec4 fa_skin[192];\nlayout(location = 0) out vec3 fa_world_pos;\nlayout(location = 1) out vec3 fa_world_normal;\nlayout(location = 2) out vec4 fa_world_tangent;\nlayout(location = 3) out vec2 fa_uv;\nlayout(location = 4) out vec4 fa_vertex_color;\nlayout(location = 5) in vec4 fa_inst_m0;\nlayout(location = 6) in vec4 fa_inst_m1;\nlayout(location = 7) in vec4 fa_inst_m2;\nlayout(location = 8) in vec4 fa_inst_m3;\nlayout(location = 9) in vec4 fa_joints;\nlayout(location = 10) in vec4 fa_weights;\nlayout(location = 0) in vec3 fa_position;\nlayout(location = 1) in vec3 fa_normal;\nlayout(location = 3) in vec4 fa_tangent;\nlayout(location = 2) in vec2 fa_texcoord0;\nlayout(location = 4) in vec4 fa_color;\nlayout(location = 5) out vec3 fa_lm;\n\nvoid fa_inst_begin()\n{\n}\n\nmat4 fa_skin_matrix(vec4 joints, vec4 weights)\n{\n    vec4 r0 = vec4(0.0);\n    vec4 r1 = vec4(0.0);\n    vec4 r2 = vec4(0.0);\n    for (int i = 0; i < 4; i++)\n    {\n        int _174 = int((joints[i] * 255.0) + 0.5) * 3;\n        r0 += (fa_skin[_174 * 1 + 0] * weights[i]);\n        r1 += (fa_skin[(_174 + 1) * 1 + 0] * weights[i]);\n        r2 += (fa_skin[(_174 + 2) * 1 + 0] * weights[i]);\n    }\n    return mat4(vec4(r0.x, r1.x, r2.x, 0.0), vec4(r0.y, r1.y, r2.y, 0.0), vec4(r0.z, r1.z, r2.z, 0.0), vec4(r0.w, r1.w, r2.w, 1.0));\n}\n\nVertexData fa_vertex_data(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    vec3 _74 = cross(model[1].xyz, model[2].xyz);\n    float _80 = (dot(model[0].xyz, _74) < 0.0) ? (-1.0) : 1.0;\n    return VertexData((model * vec4(position, 1.0)).xyz, (((_74 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _80, vec4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _80), texcoord0 * fa_mesh_vs_params[8].xy, color, position);\n}\n\nvoid fa_shade_vertex(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    mat4 param = model;\n    vec3 param_1 = position;\n    vec3 param_2 = normal;\n    vec4 param_3 = tangent;\n    vec2 param_4 = texcoord0;\n    vec4 param_5 = color;\n    VertexData _273 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    vec3 _391 = _273.world_pos;\n    fa_world_pos = _391;\n    fa_world_normal = _273.world_normal;\n    fa_world_tangent = _273.world_tangent;\n    fa_uv = _273.uv;\n    fa_vertex_color = _273.color;\n    gl_Position = mat4(fa_mesh_vs_params[0], fa_mesh_vs_params[1], fa_mesh_vs_params[2], fa_mesh_vs_params[3]) * vec4(_391, 1.0);\n}\n\nvoid main()\n{\n    fa_inst_begin();\n    vec4 param = fa_joints;\n    vec4 param_1 = fa_weights;\n    mat4 param_2 = mat4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3) * fa_skin_matrix(param, param_1);\n    vec3 param_3 = fa_position;\n    vec3 param_4 = fa_normal;\n    vec4 param_5 = fa_tangent;\n    vec2 param_6 = fa_texcoord0;\n    vec4 param_7 = fa_color;\n    fa_shade_vertex(param_2, param_3, param_4, param_5, param_6, param_7);\n    fa_lm = vec3(0.0);\n}\n\n",
      "fs": "#version 430\n\nstruct SurfaceInput\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 vertex_color;\n    vec3 view_dir;\n    bool front_facing;\n};\n\nstruct LightSample\n{\n    vec3 direction;\n    vec3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct Surface\n{\n    vec3 albedo;\n    float alpha;\n    vec3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    vec3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    vec3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    vec3 specular_color;\n};\n\nuniform vec4 fa_mesh_fs_params[24];\nuniform vec4 fa_shadows[30];\nuniform vec4 fa_material[1];\nlayout(binding = 0) uniform sampler2D fa_light_tex_fa_shadow_smp;\nlayout(binding = 1) uniform sampler2D fa_tex_fa_smp;\nlayout(binding = 2) uniform sampler2D fa_normal_tex_fa_smp;\nlayout(binding = 3) uniform sampler2D fa_mr_tex_fa_smp;\nlayout(binding = 4) uniform sampler2D fa_occlusion_tex_fa_smp;\nlayout(binding = 5) uniform sampler2D fa_emissive_tex_fa_smp;\nlayout(binding = 6) uniform sampler2D fa_decal_tex_fa_env_smp;\nlayout(binding = 7) uniform sampler2D fa_lightmap_fa_env_smp;\nlayout(binding = 8) uniform samplerCube fa_env_tex_fa_env_smp;\nlayout(binding = 9) uniform sampler2D fa_light_atlas_fa_env_smp;\nlayout(binding = 10) uniform sampler2D fa_shadow_tex_fa_shadow_smp;\n\nlayout(location = 0) in vec3 fa_world_pos;\nlayout(location = 5) in vec3 fa_lm;\nlayout(location = 1) in vec3 fa_world_normal;\nlayout(location = 2) in vec4 fa_world_tangent;\nlayout(location = 3) in vec2 fa_uv;\nlayout(location = 4) in vec4 fa_vertex_color;\nlayout(location = 0) out vec4 fa_frag_color;\nvec3 fa_light_tint;\nbool fa_light_is_area;\nint fa_cl_ndir;\nint fa_cl_slot;\nint fa_cl_local;\n\nvoid fa_inst_load()\n{\n}\n\nvec4 fa_light_texel(int t)\n{\n    return texelFetch(fa_light_tex_fa_shadow_smp, ivec2(t & 1023, t >> 10), 0);\n}\n\nvec4 fa_cluster_texel(vec3 world_pos)\n{\n    bool _1306 = fa_mesh_fs_params[19].x < 0.0;\n    bool _1313;\n    if (!_1306)\n    {\n        _1313 = fa_mesh_fs_params[19].w < 1.0;\n    }\n    else\n    {\n        _1313 = _1306;\n    }\n    bool _1321;\n    if (!_1313)\n    {\n        _1321 = fa_mesh_fs_params[18].x < 1.0;\n    }\n    else\n    {\n        _1321 = _1313;\n    }\n    bool _1328;\n    if (!_1321)\n    {\n        _1328 = fa_mesh_fs_params[18].y < 1.0;\n    }\n    else\n    {\n        _1328 = _1321;\n    }\n    bool _1335;\n    if (!_1328)\n    {\n        _1335 = fa_mesh_fs_params[19].y < 1.0;\n    }\n    else\n    {\n        _1335 = _1328;\n    }\n    if (_1335)\n    {\n        return vec4(0.0);\n    }\n    vec4 _1345 = vec4(world_pos, 1.0);\n    float _1351 = dot(fa_mesh_fs_params[16], _1345);\n    if (!(_1351 > 9.9999999747524270787835121154785e-07))\n    {\n        return vec4(0.0);\n    }\n    vec2 _1373 = vec2(dot(fa_mesh_fs_params[14], _1345), dot(fa_mesh_fs_params[15], _1345)) / vec2(_1351);\n    int _1377 = int(fa_mesh_fs_params[18].x);\n    int _1381 = int(fa_mesh_fs_params[18].y);\n    int param = (int(fa_mesh_fs_params[19].x) + (((clamp(int(floor(log2(max(dot(fa_mesh_fs_params[17].xyz, world_pos) + fa_mesh_fs_params[17].w, fa_mesh_fs_params[18].w) / fa_mesh_fs_params[18].w) * fa_mesh_fs_params[18].z)), 0, int(fa_mesh_fs_params[19].y) - 1) * _1381) + clamp(int(floor(((_1373.y * 0.5) + 0.5) * fa_mesh_fs_params[18].y)), 0, _1381 - 1)) * _1377)) + clamp(int(floor(((_1373.x * 0.5) + 0.5) * fa_mesh_fs_params[18].x)), 0, _1377 - 1);\n    return fa_light_texel(param);\n}\n\nivec2 fa_cluster_lookup(vec3 world_pos)\n{\n    vec3 param = world_pos;\n    vec4 _1457 = fa_cluster_texel(param);\n    return ivec2(int(_1457.x), int(_1457.y));\n}\n\nvoid fa_cluster_begin(vec3 world_pos)\n{\n    fa_cl_ndir = int(fa_mesh_fs_params[19].z);\n    vec3 param = world_pos;\n    ivec2 _3235 = fa_cluster_lookup(param);\n    fa_cl_slot = _3235.x;\n    fa_cl_local = _3235.y;\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nvec3 fa_linear_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_tex_fix(inout vec3 c, float mode)\n{\n    if (mode > 1.5)\n    {\n        vec3 param = c;\n        vec3 _3417 = fa_linear_to_srgb(param);\n        c = _3417;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            vec3 param_1 = c;\n            vec3 _3425 = fa_srgb_to_linear(param_1);\n            c = _3425;\n        }\n    }\n    return c;\n}\n\nvec3 fa_tangent_normal(SurfaceInput i, vec3 m)\n{\n    vec3 _261;\n    if (i.front_facing)\n    {\n        _261 = i.world_normal;\n    }\n    else\n    {\n        _261 = -i.world_normal;\n    }\n    vec3 _285 = normalize(i.world_tangent.xyz - (_261 * dot(_261, i.world_tangent.xyz)));\n    vec3 _312 = normalize(((_285 * m.x) + ((cross(_261, _285) * i.world_tangent.w) * m.y)) + (_261 * m.z));\n    vec3 _315;\n    if (i.front_facing)\n    {\n        _315 = _312;\n    }\n    else\n    {\n        _315 = -_312;\n    }\n    return _315;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    vec4 base_t = texture(fa_tex_fa_smp, i.uv);\n    float param = fa_mesh_fs_params[6].w;\n    float param_1 = 1.0;\n    vec3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    vec3 _3456 = fa_tex_fix(param_2, param_3);\n    vec4 _4479 = base_t;\n    _4479.x = _3456.x;\n    _4479.y = _3456.y;\n    _4479.z = _3456.z;\n    base_t = _4479;\n    vec4 _3470 = (_4479 * fa_mesh_fs_params[2]) * i.vertex_color;\n    vec3 _4344 = i.world_normal;\n    if (fa_mesh_fs_params[6].z > 0.5)\n    {\n        float param_4 = fa_mesh_fs_params[6].w;\n        float param_5 = 16.0;\n        vec3 param_6 = texture(fa_normal_tex_fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        vec3 _3502 = fa_tex_fix(param_6, param_7);\n        vec3 _3505 = (_3502 * 2.0) - vec3(1.0);\n        vec2 _3510 = _3505.xy * fa_mesh_fs_params[6].x;\n        vec3 _4487 = _3505;\n        _4487.x = _3510.x;\n        _4487.y = _3510.y;\n        SurfaceInput param_8 = i;\n        vec3 param_9 = _4487;\n        _4344 = fa_tangent_normal(param_8, param_9);\n    }\n    vec4 mrt = texture(fa_mr_tex_fa_smp, i.uv);\n    float param_10 = fa_mesh_fs_params[6].w;\n    float param_11 = 64.0;\n    vec3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    vec3 _3538 = fa_tex_fix(param_12, param_13);\n    vec4 _4490 = mrt;\n    _4490.x = _3538.x;\n    _4490.y = _3538.y;\n    _4490.z = _3538.z;\n    mrt = _4490;\n    vec4 _3566 = texture(fa_occlusion_tex_fa_smp, i.uv);\n    float param_14 = fa_mesh_fs_params[6].w;\n    float param_15 = 256.0;\n    vec3 param_16 = _3566.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    vec3 _3577 = fa_tex_fix(param_16, param_17);\n    float param_18 = fa_mesh_fs_params[6].w;\n    float param_19 = 4.0;\n    vec3 param_20 = texture(fa_emissive_tex_fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    vec3 _3607 = fa_tex_fix(param_20, param_21);\n    float _4349 = fa_mesh_fs_params[20].x;\n    float _4350 = fa_mesh_fs_params[20].y;\n    float _4353 = fa_mesh_fs_params[20].z;\n    float _4352 = fa_mesh_fs_params[21].w;\n    float _4355 = fa_mesh_fs_params[22].x;\n    if (fa_mesh_fs_params[22].z > 0.5)\n    {\n        if (mod(fa_mesh_fs_params[22].z, 2.0) > 0.5)\n        {\n            _4349 *= _3577.y;\n            _4350 *= _3577.z;\n            _4352 *= _3566.w;\n        }\n        if (fa_mesh_fs_params[22].z > 1.5)\n        {\n            _4353 *= mrt.x;\n            _4355 *= mrt.w;\n        }\n    }\n    return Surface(_3470.xyz, _3470.w, _4344, clamp(fa_mesh_fs_params[5].x * _3538.z, 0.0, 1.0), clamp(fa_mesh_fs_params[5].y * _3538.y, 0.0500000007450580596923828125, 1.0), 1.0 + (fa_mesh_fs_params[6].y * (_3577.x - 1.0)), fa_mesh_fs_params[3].xyz + (fa_mesh_fs_params[4].xyz * _3607), _4349, _4350, fa_mesh_fs_params[21].xyz, _4352, _4353, fa_mesh_fs_params[20].w, _4355, fa_mesh_fs_params[22].y, fa_mesh_fs_params[23].xyz);\n}\n\nvoid surface(SurfaceInput i, Surface s)\n{\n}\n\nvec4 fa_decal_tile(vec4 rect, vec2 uv, vec2 atlas, vec2 ddx, vec2 ddy)\n{\n    vec2 _1537 = rect.zw - rect.xy;\n    vec2 _1541 = _1537 * atlas;\n    vec2 _1545 = ddx * _1541;\n    vec2 _1549 = ddy * _1541;\n    return textureLod(fa_decal_tex_fa_env_smp, rect.xy + (clamp(uv, vec2(0.0), vec2(1.0)) * _1537), clamp(0.5 * log2(max(max(dot(_1545, _1545), dot(_1549, _1549)), 9.9999999392252902907785028219223e-09)), 0.0, 4.0));\n}\n\nvec3 fa_dc_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_dc_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvoid fa_apply_decals(vec3 world_pos, vec3 geo_normal, inout vec3 albedo, inout vec3 normal)\n{\n    bool _1582 = fa_mesh_fs_params[10].y < 0.5;\n    bool _1589;\n    if (!_1582)\n    {\n        _1589 = fa_mesh_fs_params[10].w < 0.5;\n    }\n    else\n    {\n        _1589 = _1582;\n    }\n    if (_1589)\n    {\n        return;\n    }\n    vec3 _1595 = dFdx(world_pos);\n    vec3 _1598 = dFdy(world_pos);\n    vec3 param = world_pos;\n    vec4 _1602 = fa_cluster_texel(param);\n    int _1606 = int(_1602.w);\n    if (_1606 < 1)\n    {\n        return;\n    }\n    int _1616 = int(fa_mesh_fs_params[10].y + 0.5);\n    int param_1 = _1616;\n    vec4 _1620 = fa_light_texel(param_1);\n    vec2 _1623 = _1620.yz;\n    int _1627 = int(_1620.w);\n    int param_2 = _1616 + 1;\n    vec4 _1632 = fa_light_texel(param_2);\n    float _1633 = _1632.x;\n    int _1639 = int(fa_mesh_fs_params[10].w + 0.5) - 1;\n    int _1643 = int(_1602.z);\n    vec3 _1908;\n    for (int k = 0; k < _1606; k++)\n    {\n        int _1656 = _1643 + k;\n        int param_3 = _1627 + (_1656 >> 2);\n        int _1673 = (_1616 + 2) + (int(fa_light_texel(param_3)[_1656 & 3]) * 7);\n        int param_4 = _1673 + 6;\n        vec4 _1678 = fa_light_texel(param_4);\n        if (((int(_1678.w + 0.5) >> _1639) & 1) == 0)\n        {\n            continue;\n        }\n        int param_5 = _1673;\n        vec4 _1693 = fa_light_texel(param_5);\n        int param_6 = _1673 + 1;\n        vec4 _1698 = fa_light_texel(param_6);\n        int param_7 = _1673 + 2;\n        vec4 _1703 = fa_light_texel(param_7);\n        vec3 _1706 = _1693.xyz;\n        float _1711 = dot(_1706, world_pos) + _1693.w;\n        vec3 _1713 = _1698.xyz;\n        float _1718 = dot(_1713, world_pos) + _1698.w;\n        vec3 _1720 = _1703.xyz;\n        float _1725 = dot(_1720, world_pos) + _1703.w;\n        bool _1730 = abs(_1711) > 0.5;\n        bool _1738;\n        if (!_1730)\n        {\n            _1738 = abs(_1718) > 0.5;\n        }\n        else\n        {\n            _1738 = _1730;\n        }\n        bool _1746;\n        if (!_1738)\n        {\n            _1746 = abs(_1725) > 0.5;\n        }\n        else\n        {\n            _1746 = _1738;\n        }\n        if (_1746)\n        {\n            continue;\n        }\n        float _1761 = clamp(dot(geo_normal, normalize(_1720)) * _1678.z, 0.0, 1.0);\n        if (_1761 <= 0.0)\n        {\n            continue;\n        }\n        float _1781 = (clamp((0.5 - abs(_1725)) * 10.0, 0.0, 1.0) * _1761) * _1678.x;\n        vec2 _1789 = vec2(_1711 + 0.5, 0.5 - _1718);\n        vec2 _1799 = vec2(dot(_1706, _1595), dot(_1713, _1595));\n        vec2 _1809 = vec2(dot(_1706, _1598), dot(_1713, _1598));\n        int param_8 = _1673 + 5;\n        vec4 _1814 = fa_light_texel(param_8);\n        int param_9 = _1673 + 3;\n        vec4 _1819 = fa_light_texel(param_9);\n        int param_10 = _1673 + 4;\n        vec4 _1824 = fa_light_texel(param_10);\n        float tex_a = 1.0;\n        vec3 col = _1814.xyz;\n        bool _1834 = _1819.z > _1819.x;\n        if (_1834)\n        {\n            vec4 param_11 = _1819;\n            vec2 param_12 = _1789;\n            vec2 param_13 = _1623;\n            vec2 param_14 = _1799;\n            vec2 param_15 = _1809;\n            vec4 tx = fa_decal_tile(param_11, param_12, param_13, param_14, param_15);\n            if ((_1633 > 0.5) && (_1633 < 1.5))\n            {\n                vec3 param_16 = tx.xyz;\n                vec3 _1860 = fa_dc_to_linear(param_16);\n                vec4 _4424 = tx;\n                _4424.x = _1860.x;\n                _4424.y = _1860.y;\n                _4424.z = _1860.z;\n                tx = _4424;\n            }\n            col *= tx.xyz;\n            tex_a = tx.w;\n        }\n        albedo = mix(albedo, col, vec3(clamp((_1781 * tex_a) * _1814.w, 0.0, 1.0)));\n        if (_1824.z > _1824.x)\n        {\n            vec4 param_17 = _1824;\n            vec2 param_18 = _1789;\n            vec2 param_19 = _1623;\n            vec2 param_20 = _1799;\n            vec2 param_21 = _1809;\n            vec4 _1904 = fa_decal_tile(param_17, param_18, param_19, param_20, param_21);\n            if (_1633 > 1.5)\n            {\n                vec3 param_22 = _1904.xyz;\n                vec3 _1914 = fa_dc_to_srgb(param_22);\n                _1908 = _1914;\n            }\n            else\n            {\n                _1908 = _1904.xyz;\n            }\n            vec3 _1923 = (_1908 * 2.0) - vec3(1.0);\n            vec2 _1928 = _1923.xy * _1678.y;\n            vec3 _1950 = (normalize(_1706) * _1928.x) + (normalize(_1713) * _1928.y);\n            vec3 _1953 = normalize(normal);\n            normal = normalize(mix(_1953, normalize((_1953 * max(_1923.z, 0.0500000007450580596923828125)) + (_1950 - (_1953 * dot(_1953, _1950)))), vec3(clamp(_1781 * (_1834 ? tex_a : 1.0), 0.0, 1.0))));\n        }\n    }\n}\n\nvec3 fa_sky_sh_coef(int k)\n{\n    vec3 v = textureLod(fa_env_tex_fa_env_smp, vec3(1.0, 1.0 - (float((2 * (k >> 2)) + 1) * 0.25), 1.0 - (float((2 * (k & 3)) + 1) * 0.25)), 5.0).xyz;\n    if (fa_mesh_fs_params[11].w > 1.5)\n    {\n        v = (v - vec3(0.5)) * 8.0;\n    }\n    return v;\n}\n\nvec3 fa_sh_eval(vec3 c[9], vec3 n)\n{\n    vec3 _3148 = max((((c[0] * 0.2820948064327239990234375) + (((c[1] * (0.3257350027561187744140625 * n.y)) + (c[2] * (0.3257350027561187744140625 * n.z))) + (c[3] * (0.3257350027561187744140625 * n.x)))) + (((c[4] * ((0.2731371223926544189453125 * n.x) * n.y)) + (c[5] * ((0.2731371223926544189453125 * n.y) * n.z))) + (c[6] * (0.078847892582416534423828125 * (((3.0 * n.z) * n.z) - 1.0))))) + ((c[7] * ((0.2731371223926544189453125 * n.x) * n.z)) + (c[8] * (0.13656856119632720947265625 * ((n.x * n.x) - (n.y * n.y))))), vec3(0.0));\n    return _3148;\n}\n\nvec3 fa_ambient_light(vec3 n)\n{\n    if (fa_mesh_fs_params[11].w > 0.5)\n    {\n        vec3 c[9];\n        for (int k = 0; k < 9; k++)\n        {\n            int param = k;\n            c[k] = fa_sky_sh_coef(param);\n        }\n        vec3 param_1[9] = c;\n        vec3 param_2 = n;\n        return fa_sh_eval(param_1, param_2);\n    }\n    return fa_mesh_fs_params[1].xyz;\n}\n\nvec3 fa_indirect_diffuse(vec3 n)\n{\n    if (fa_lm.z > 0.5)\n    {\n        return textureLod(fa_lightmap_fa_env_smp, fa_lm.xy, 0.0).xyz;\n    }\n    vec3 param = n;\n    return fa_ambient_light(param);\n}\n\nint fa_cluster_index(int slot, int n)\n{\n    int param = (int(fa_mesh_fs_params[19].x) + int(fa_mesh_fs_params[19].w)) + ((slot + n) >> 2);\n    vec4 t = fa_light_texel(param);\n    return int(t[(slot + n) & 3]);\n}\n\nint fa_cl_light(int n)\n{\n    if (n < fa_cl_ndir)\n    {\n        return n;\n    }\n    int param = fa_cl_slot;\n    int param_1 = n - fa_cl_ndir;\n    return fa_cluster_index(param, param_1);\n}\n\nint fa_light_base(int li)\n{\n    return li * ((fa_mesh_fs_params[1].w > 4.5) ? 8 : 4);\n}\n\nbool fa_light_baked(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 3;\n    return fa_light_texel(param_1).w > 0.5;\n}\n\nfloat fa_light_type(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 1;\n    return fa_light_texel(param_1).w;\n}\n\nvec4 fa_atlas_fetch(vec2 texel)\n{\n    return textureLod(fa_light_atlas_fa_env_smp, texel / vec2(textureSize(fa_light_atlas_fa_env_smp, 0)), 0.0);\n}\n\nvec3 fa_cookie_sample(vec2 tile_origin, vec2 uv)\n{\n    vec2 param = (tile_origin + vec2(1.0)) + (clamp(uv, vec2(0.0), vec2(1.0)) * 254.0);\n    return fa_atlas_fetch(param).xyz;\n}\n\nvec3 fa_area_point(vec3 c, vec3 axis, vec3 ru, vec3 uu, float hx, float hy, float shape, vec3 p, vec3 r)\n{\n    bool _556 = dot(r, r) > 0.5;\n    if (shape > 1.5)\n    {\n        vec3 _569 = (c - (ru * hx)) - p;\n        vec3 _575 = ru * (2.0 * hx);\n        float _581 = max(dot(_575, _575), 9.9999999392252902907785028219223e-09);\n        float _585 = dot(_569, _575);\n        float t = clamp((-_585) / _581, 0.0, 1.0);\n        if (_556)\n        {\n            float _600 = dot(r, _575);\n            float _606 = _581 - (_600 * _600);\n            if (abs(_606) > (9.9999997473787516355514526367188e-06 * _581))\n            {\n                t = clamp(((dot(r, _569) * _600) - _585) / _606, 0.0, 1.0);\n            }\n        }\n        return (p + _569) + (_575 * t);\n    }\n    vec3 q = p;\n    float _638 = dot(r, axis);\n    bool _646;\n    if (_556)\n    {\n        _646 = abs(_638) > 9.9999997473787516355514526367188e-05;\n    }\n    else\n    {\n        _646 = _556;\n    }\n    if (_646)\n    {\n        float _656 = dot(c - p, axis) / _638;\n        if (_656 > 0.0)\n        {\n            q = p + (r * _656);\n        }\n    }\n    vec3 _669 = q - c;\n    vec2 xy = vec2(dot(_669, ru), dot(_669, uu));\n    if (shape > 0.5)\n    {\n        float _684 = length(xy);\n        if (_684 > hx)\n        {\n            xy *= (hx / _684);\n        }\n    }\n    else\n    {\n        xy = clamp(xy, vec2(-hx, -hy), vec2(hx, hy));\n    }\n    return (c + (ru * xy.x)) + (uu * xy.y);\n}\n\nint fa_cube_face(vec3 d)\n{\n    vec3 _327 = abs(d);\n    float _329 = _327.x;\n    float _331 = _327.y;\n    bool _332 = _329 >= _331;\n    bool _340;\n    if (_332)\n    {\n        _340 = _329 >= _327.z;\n    }\n    else\n    {\n        _340 = _332;\n    }\n    int _341;\n    if (_340)\n    {\n        _341 = (d.x > 0.0) ? 0 : 1;\n    }\n    else\n    {\n        int _356;\n        if (_331 >= _327.z)\n        {\n            _356 = (d.y > 0.0) ? 2 : 3;\n        }\n        else\n        {\n            _356 = (d.z > 0.0) ? 4 : 5;\n        }\n        _341 = _356;\n    }\n    return _341;\n}\n\nvoid fa_cube_face_basis(int f, out vec3 fwd, out vec3 up)\n{\n    if (f == 0)\n    {\n        fwd = vec3(1.0, 0.0, 0.0);\n        up = vec3(0.0, 1.0, 0.0);\n    }\n    else\n    {\n        if (f == 1)\n        {\n            fwd = vec3(-1.0, 0.0, 0.0);\n            up = vec3(0.0, 1.0, 0.0);\n        }\n        else\n        {\n            if (f == 2)\n            {\n                fwd = vec3(0.0, 1.0, 0.0);\n                up = vec3(0.0, 0.0, 1.0);\n            }\n            else\n            {\n                if (f == 3)\n                {\n                    fwd = vec3(0.0, -1.0, 0.0);\n                    up = vec3(0.0, 0.0, -1.0);\n                }\n                else\n                {\n                    if (f == 4)\n                    {\n                        fwd = vec3(0.0, 0.0, 1.0);\n                        up = vec3(0.0, 1.0, 0.0);\n                    }\n                    else\n                    {\n                        fwd = vec3(0.0, 0.0, -1.0);\n                        up = vec3(0.0, 1.0, 0.0);\n                    }\n                }\n            }\n        }\n    }\n}\n\nfloat fa_ies_sample(vec2 tile_origin, vec3 d, vec3 axis, vec3 right, vec3 up)\n{\n    float _476 = dot(d, right);\n    float _480 = dot(d, up);\n    float _491;\n    if (((_476 * _476) + (_480 * _480)) > 1.0000000133514319600180897396058e-10)\n    {\n        _491 = atan(_480, _476) * 0.15915493667125701904296875;\n    }\n    else\n    {\n        _491 = 0.0;\n    }\n    vec2 param = tile_origin + vec2(1.0 + ((_491 - floor(_491)) * 64.0), 1.0 + (acos(clamp(dot(d, axis), -1.0, 1.0)) * 10.18591594696044921875));\n    return fa_atlas_fetch(param).x;\n}\n\nLightSample fa_light_sample_n(int li, vec3 world_pos, vec3 n)\n{\n    int param = li;\n    int _722 = fa_light_base(param);\n    bool _726 = fa_mesh_fs_params[1].w > 4.5;\n    int param_1 = _722;\n    vec4 _730 = fa_light_texel(param_1);\n    int param_2 = _722 + 1;\n    vec4 _735 = fa_light_texel(param_2);\n    float _738 = _735.w;\n    float atten = 1.0;\n    float dist = 0.0;\n    fa_light_tint = vec3(1.0);\n    bool _750 = _726 && (_738 > 2.5);\n    fa_light_is_area = _750;\n    bool _752 = _738 < 0.5;\n    vec3 l;\n    if (_752)\n    {\n        l = normalize(_730.xyz);\n        if (_726)\n        {\n            int param_3 = _722 + 6;\n            vec4 _766 = fa_light_texel(param_3);\n            if (_766.z > 0.5)\n            {\n                int param_4 = _722 + 4;\n                vec4 _776 = fa_light_texel(param_4);\n                int param_5 = _722 + 5;\n                vec4 _781 = fa_light_texel(param_5);\n                vec2 param_6 = _766.xy;\n                vec2 param_7 = fract(vec2(dot(world_pos, _776.xyz) * _776.w, (-dot(world_pos, _781.xyz)) * _781.w) + vec2(0.5));\n                fa_light_tint = fa_cookie_sample(param_6, param_7);\n            }\n        }\n    }\n    else\n    {\n        vec3 _811 = _730.xyz;\n        vec3 _813 = _811 - world_pos;\n        vec3 to_light = _813;\n        float _816 = length(_813);\n        float reach = _816;\n        bool front = true;\n        if (_750)\n        {\n            int param_8 = _722 + 7;\n            reach = max(_816 - fa_light_texel(param_8).w, 0.0);\n            int param_9 = _722 + 4;\n            vec4 _840 = fa_light_texel(param_9);\n            int param_10 = _722 + 5;\n            vec4 _845 = fa_light_texel(param_10);\n            int param_11 = _722 + 6;\n            vec4 _850 = fa_light_texel(param_11);\n            float _851 = _850.w;\n            int param_12 = _722 + 2;\n            vec3 _858 = normalize(fa_light_texel(param_12).xyz);\n            bool _860 = _851 > 1.5;\n            bool _868;\n            if (!_860)\n            {\n                _868 = dot(_858, to_light) < 0.0;\n            }\n            else\n            {\n                _868 = _860;\n            }\n            front = _868;\n            vec3 r = vec3(0.0);\n            vec3 _877 = fa_mesh_fs_params[0].xyz - world_pos;\n            bool _881 = dot(n, n) > 0.5;\n            bool _889;\n            if (_881)\n            {\n                _889 = dot(_877, _877) > 9.9999999600419720025001879548654e-13;\n            }\n            else\n            {\n                _889 = _881;\n            }\n            if (_889)\n            {\n                r = reflect(-normalize(_877), normalize(n));\n            }\n            vec3 param_13 = _811;\n            vec3 param_14 = _858;\n            vec3 param_15 = _840.xyz;\n            vec3 param_16 = _845.xyz;\n            float param_17 = _840.w;\n            float param_18 = _845.w;\n            float param_19 = _851;\n            vec3 param_20 = world_pos;\n            vec3 param_21 = r;\n            to_light = fa_area_point(param_13, param_14, param_15, param_16, param_17, param_18, param_19, param_20, param_21) - world_pos;\n        }\n        float _925 = length(to_light);\n        dist = _925;\n        l = to_light / vec3(max(_925, 9.9999997473787516355514526367188e-05));\n        float _939 = reach / max(_730.w, 0.001000000047497451305389404296875);\n        float _945 = clamp(1.0 - (_939 * _939), 0.0, 1.0);\n        float _947;\n        if (front)\n        {\n            _947 = _945 * _945;\n        }\n        else\n        {\n            _947 = 0.0;\n        }\n        atten = _947;\n        bool _958 = _738 < 2.5;\n        if ((_738 > 1.5) && _958)\n        {\n            int param_22 = _722 + 2;\n            vec4 _966 = fa_light_texel(param_22);\n            float _976 = _966.w;\n            int param_23 = _722 + 3;\n            vec4 _981 = fa_light_texel(param_23);\n            float _982 = _981.x;\n            float cos_inner = _982;\n            if (_982 > 1.5)\n            {\n                cos_inner = mix(_976, 1.0, 0.25);\n            }\n            atten *= smoothstep(_976, cos_inner, dot(-l, normalize(_966.xyz)));\n        }\n        if (_726 && (_738 < 1.5))\n        {\n            int param_24 = _722 + 6;\n            vec4 _1006 = fa_light_texel(param_24);\n            if (_1006.z > 0.5)\n            {\n                vec3 _1014 = -to_light;\n                int param_25 = _722 + 4;\n                int param_26 = _722 + 5;\n                vec3 _1028 = fa_light_texel(param_25).xyz;\n                vec3 _1032 = fa_light_texel(param_26).xyz;\n                vec3 _1041 = vec3(dot(_1014, _1028), dot(_1014, _1032), dot(_1014, cross(_1028, _1032)));\n                vec3 param_27 = _1041;\n                int _1045 = fa_cube_face(param_27);\n                int param_28 = _1045;\n                vec3 param_29;\n                vec3 param_30;\n                fa_cube_face_basis(param_28, param_29, param_30);\n                vec2 _1072 = vec2(dot(_1041, cross(param_29, param_30)), dot(_1041, param_30)) / vec2(max(dot(_1041, param_29), 9.9999997473787516355514526367188e-05));\n                int _1076 = _1045 / 3;\n                vec2 param_31 = _1006.xy + (vec2(float(_1045 - (_1076 * 3)), float(_1076)) * 256.0);\n                vec2 param_32 = vec2(0.5 + (0.5 * _1072.x), 0.5 - (0.5 * _1072.y));\n                fa_light_tint = fa_cookie_sample(param_31, param_32);\n            }\n            int param_33 = _722 + 7;\n            vec4 _1106 = fa_light_texel(param_33);\n            if (_1106.z > 0.5)\n            {\n                int param_34 = _722 + 2;\n                int param_35 = _722 + 4;\n                int param_36 = _722 + 5;\n                vec2 param_37 = _1106.xy;\n                vec3 param_38 = -l;\n                vec3 param_39 = normalize(fa_light_texel(param_34).xyz);\n                vec3 param_40 = fa_light_texel(param_35).xyz;\n                vec3 param_41 = fa_light_texel(param_36).xyz;\n                atten *= fa_ies_sample(param_37, param_38, param_39, param_40, param_41);\n            }\n        }\n        else\n        {\n            if (_726 && _958)\n            {\n                int param_42 = _722 + 6;\n                vec4 _1153 = fa_light_texel(param_42);\n                int param_43 = _722 + 7;\n                vec4 _1158 = fa_light_texel(param_43);\n                bool _1161 = _1153.z > 0.5;\n                bool _1168;\n                if (!_1161)\n                {\n                    _1168 = _1158.z > 0.5;\n                }\n                else\n                {\n                    _1168 = _1161;\n                }\n                if (_1168)\n                {\n                    int param_44 = _722 + 2;\n                    vec4 _1175 = fa_light_texel(param_44);\n                    vec3 _1179 = normalize(_1175.xyz);\n                    int param_45 = _722 + 4;\n                    vec4 _1184 = fa_light_texel(param_45);\n                    int param_46 = _722 + 5;\n                    vec4 _1189 = fa_light_texel(param_46);\n                    if (_1161)\n                    {\n                        vec3 _1197 = -to_light;\n                        float _1204 = _1175.w;\n                        float _1220 = 0.5 / max(dot(_1197, _1179) * (sqrt(max(1.0 - (_1204 * _1204), 0.0)) / max(_1204, 0.001000000047497451305389404296875)), 9.9999997473787516355514526367188e-05);\n                        vec2 param_47 = _1153.xy;\n                        vec2 param_48 = vec2(0.5 + (dot(_1197, _1184.xyz) * _1220), 0.5 - (dot(_1197, _1189.xyz) * _1220));\n                        fa_light_tint = fa_cookie_sample(param_47, param_48);\n                    }\n                    if (_1158.z > 0.5)\n                    {\n                        vec2 param_49 = _1158.xy;\n                        vec3 param_50 = -l;\n                        vec3 param_51 = _1179;\n                        vec3 param_52 = _1184.xyz;\n                        vec3 param_53 = _1189.xyz;\n                        atten *= fa_ies_sample(param_49, param_50, param_51, param_52, param_53);\n                    }\n                }\n            }\n        }\n    }\n    vec3 _4298 = _735.xyz * atten;\n    if (_726)\n    {\n        _4298 *= fa_light_tint;\n    }\n    int _1288;\n    if (_752)\n    {\n        _1288 = 0;\n    }\n    else\n    {\n        _1288 = ((_738 > 1.5) && (_738 < 2.5)) ? 2 : 1;\n    }\n    return LightSample(l, _4298, atten, 1.0, dist, _1288);\n}\n\nfloat fa_shadow_split_at(int i)\n{\n    float _2025;\n    if (i == 0)\n    {\n        _2025 = fa_shadows[24].x;\n    }\n    else\n    {\n        float _2041;\n        if (i == 1)\n        {\n            _2041 = fa_shadows[24].y;\n        }\n        else\n        {\n            float _2049;\n            if (i == 2)\n            {\n                _2049 = fa_shadows[24].z;\n            }\n            else\n            {\n                _2049 = fa_shadows[24].w;\n            }\n            _2041 = _2049;\n        }\n        _2025 = _2041;\n    }\n    return _2025;\n}\n\nfloat fa_shadow_depth(inout vec2 uv, vec4 rect)\n{\n    uv = clamp(uv, rect.xy, rect.zw);\n    return textureLod(fa_shadow_tex_fa_shadow_smp, uv, 0.0).x;\n}\n\nfloat fa_shadow_fetch(vec2 uv, vec4 rect, vec3 conv)\n{\n    vec2 param = uv;\n    vec4 param_1 = rect;\n    float _2082 = fa_shadow_depth(param, param_1);\n    float _2086;\n    if (conv.x < 0.5)\n    {\n        _2086 = _2082;\n    }\n    else\n    {\n        _2086 = (conv.y * conv.z) / (conv.z - (_2082 * (conv.z - conv.y)));\n    }\n    return _2086;\n}\n\nfloat fa_shadow_noise()\n{\n    return fract(52.98291778564453125 * fract(dot(gl_FragCoord.xy, vec2(0.067110560834407806396484375, 0.005837149918079376220703125))));\n}\n\nvec2 fa_shadow_vogel(int k, int n, float phi)\n{\n    float _2013 = (float(k) * 2.3999631404876708984375) + phi;\n    return vec2(cos(_2013), sin(_2013)) * sqrt((float(k) + 0.5) / float(n));\n}\n\nfloat fa_shadow_filter(vec2 uv, vec4 rect, float zr, float texel_m, float unit, float reach, float plane, vec3 conv, int mode, float k)\n{\n    if (mode == 1)\n    {\n        vec2 param = uv;\n        vec4 param_1 = rect;\n        vec3 param_2 = conv;\n        return float(zr <= fa_shadow_fetch(param, param_1, param_2));\n    }\n    float _2132 = fa_shadow_noise() * 6.283185482025146484375;\n    float radius = 1.5;\n    if (mode == 2)\n    {\n        float _2141;\n        if (k < 0.0)\n        {\n            _2141 = (-k) / max(zr, 0.100000001490116119384765625);\n        }\n        else\n        {\n            _2141 = k;\n        }\n        float _2161 = clamp((_2141 * reach) / texel_m, 3.0, 12.0);\n        float sum = 0.0;\n        float cnt = 0.0;\n        for (int i = 0; i < 16; i++)\n        {\n            int param_3 = i;\n            int param_4 = 16;\n            float param_5 = _2132;\n            vec2 _2180 = fa_shadow_vogel(param_3, param_4, param_5) * _2161;\n            vec2 param_6 = uv + (_2180 * fa_shadows[26].zw);\n            vec4 param_7 = rect;\n            vec3 param_8 = conv;\n            float _2192 = fa_shadow_fetch(param_6, param_7, param_8);\n            if (_2192 < (zr - (length(_2180) * plane)))\n            {\n                sum += _2192;\n                cnt += 1.0;\n            }\n        }\n        if (cnt < 0.5)\n        {\n            return 1.0;\n        }\n        float _2218 = sum / cnt;\n        float _2228;\n        if (k < 0.0)\n        {\n            _2228 = (-k) / max(_2218, 0.0500000007450580596923828125);\n        }\n        else\n        {\n            _2228 = k;\n        }\n        radius = clamp(((max(zr - _2218, 0.0) * unit) * _2228) / texel_m, 1.5, 16.0);\n    }\n    float lit = 0.0;\n    int _2250 = (mode == 2) ? 24 : 16;\n    for (int i_1 = 0; i_1 < _2250; i_1++)\n    {\n        int param_9 = i_1;\n        int param_10 = _2250;\n        float param_11 = _2132;\n        vec2 _2269 = fa_shadow_vogel(param_9, param_10, param_11) * radius;\n        vec2 param_12 = uv + (_2269 * fa_shadows[26].zw);\n        vec4 param_13 = rect;\n        vec3 param_14 = conv;\n        lit += float((zr - (length(_2269) * plane)) <= fa_shadow_fetch(param_12, param_13, param_14));\n    }\n    return lit / float(_2250);\n}\n\nfloat fa_shadow_cascade(int ci, vec3 world, vec3 n, vec3 l)\n{\n    float _2311 = max(fa_shadows[ci * 1 + 20].y, 0.001000000047497451305389404296875);\n    float _2316 = clamp(dot(n, l), 0.0, 1.0);\n    float _2322 = sqrt(1.0 - (_2316 * _2316));\n    float _2329 = min(_2322 / max(_2316, 0.20000000298023223876953125), 4.0);\n    float _2334;\n    if (fa_shadows[26].y > 0.0)\n    {\n        _2334 = fa_shadows[26].y;\n    }\n    else\n    {\n        _2334 = 1.5 * fa_shadows[ci * 1 + 20].x;\n    }\n    vec4 _2359 = mat4(fa_shadows[ci * 4 + 0], fa_shadows[ci * 4 + 1], fa_shadows[ci * 4 + 2], fa_shadows[ci * 4 + 3]) * vec4(world + (n * (_2334 * _2322)), 1.0);\n    float _2366 = _2359.x;\n    bool _2369 = _2366 < fa_shadows[ci * 1 + 16].x;\n    bool _2378;\n    if (!_2369)\n    {\n        _2378 = _2366 > fa_shadows[ci * 1 + 16].z;\n    }\n    else\n    {\n        _2378 = _2369;\n    }\n    bool _2387;\n    if (!_2378)\n    {\n        _2387 = _2359.y < fa_shadows[ci * 1 + 16].y;\n    }\n    else\n    {\n        _2387 = _2378;\n    }\n    bool _2396;\n    if (!_2387)\n    {\n        _2396 = _2359.y > fa_shadows[ci * 1 + 16].w;\n    }\n    else\n    {\n        _2396 = _2387;\n    }\n    bool _2403;\n    if (!_2396)\n    {\n        _2403 = _2359.z > 1.0;\n    }\n    else\n    {\n        _2403 = _2396;\n    }\n    if (_2403)\n    {\n        return -1.0;\n    }\n    float _2411;\n    if (fa_shadows[26].x > 0.0)\n    {\n        _2411 = fa_shadows[26].x;\n    }\n    else\n    {\n        _2411 = 1.5 * fa_shadows[ci * 1 + 20].x;\n    }\n    vec2 param = _2359.xy;\n    vec4 param_1 = fa_shadows[ci * 1 + 16];\n    float param_2 = _2359.z - ((_2411 * (1.0 + (0.5 * _2329))) / _2311);\n    float param_3 = fa_shadows[ci * 1 + 20].x;\n    float param_4 = _2311;\n    float param_5 = _2311 * 0.25;\n    float param_6 = ((fa_shadows[ci * 1 + 20].x * min(_2329, 3.0)) * 0.5) / _2311;\n    vec3 param_7 = vec3(0.0);\n    int param_8 = int(fa_shadows[25].z + 0.5);\n    float param_9 = fa_shadows[25].w;\n    return fa_shadow_filter(param, param_1, param_2, param_3, param_4, param_5, param_6, param_7, param_8, param_9);\n}\n\nfloat fa_shadow_sun(vec3 world, vec3 n, vec3 l)\n{\n    if (fa_mesh_fs_params[5].z < 0.5)\n    {\n        return 1.0;\n    }\n    int _2789 = int(fa_shadows[25].x + 0.5);\n    if (_2789 < 1)\n    {\n        return 1.0;\n    }\n    float _2804 = dot(world - fa_shadows[27].xyz, fa_shadows[28].xyz);\n    int param = _2789 - 1;\n    if (_2804 > fa_shadow_split_at(param))\n    {\n        return 1.0;\n    }\n    int ci = 0;\n    bool _2816 = _2789 > 1;\n    bool _2823;\n    if (_2816)\n    {\n        _2823 = _2804 > fa_shadows[24].x;\n    }\n    else\n    {\n        _2823 = _2816;\n    }\n    if (_2823)\n    {\n        ci = 1;\n    }\n    bool _2827 = _2789 > 2;\n    bool _2834;\n    if (_2827)\n    {\n        _2834 = _2804 > fa_shadows[24].y;\n    }\n    else\n    {\n        _2834 = _2827;\n    }\n    if (_2834)\n    {\n        ci = 2;\n    }\n    bool _2838 = _2789 > 3;\n    bool _2845;\n    if (_2838)\n    {\n        _2845 = _2804 > fa_shadows[24].z;\n    }\n    else\n    {\n        _2845 = _2838;\n    }\n    if (_2845)\n    {\n        ci = 3;\n    }\n    float s = -1.0;\n    for (int k = 0; k < 4; k++)\n    {\n        if (ci >= _2789)\n        {\n            break;\n        }\n        int param_1 = ci;\n        vec3 param_2 = world;\n        vec3 param_3 = n;\n        vec3 param_4 = l;\n        float _2871 = fa_shadow_cascade(param_1, param_2, param_3, param_4);\n        s = _2871;\n        if (_2871 >= 0.0)\n        {\n            break;\n        }\n        ci++;\n    }\n    if (s < 0.0)\n    {\n        return 1.0;\n    }\n    if (fa_shadows[25].y > 0.0)\n    {\n        float _2896;\n        if (ci > 0)\n        {\n            int param_5 = ci - 1;\n            _2896 = fa_shadow_split_at(param_5);\n        }\n        else\n        {\n            _2896 = fa_shadows[28].w;\n        }\n        int param_6 = ci;\n        float _2915 = fa_shadows[25].y * max(fa_shadow_split_at(param_6) - _2896, 9.9999997473787516355514526367188e-05);\n        int param_7 = ci;\n        float _2926 = clamp((_2804 - (fa_shadow_split_at(param_7) - _2915)) / _2915, 0.0, 1.0);\n        if (_2926 > 0.0)\n        {\n            float s2 = 1.0;\n            if ((ci + 1) < _2789)\n            {\n                int param_8 = ci + 1;\n                vec3 param_9 = world;\n                vec3 param_10 = n;\n                vec3 param_11 = l;\n                float _2947 = fa_shadow_cascade(param_8, param_9, param_10, param_11);\n                s2 = _2947;\n                if (_2947 < 0.0)\n                {\n                    s2 = s;\n                }\n            }\n            s = mix(s, s2, _2926);\n        }\n    }\n    return s;\n}\n\nfloat fa_shadow_factor(vec3 n, vec3 l)\n{\n    vec3 param = fa_world_pos;\n    vec3 param_1 = n;\n    vec3 param_2 = l;\n    return fa_shadow_sun(param, param_1, param_2);\n}\n\nfloat fa_shadow_local(int li, vec3 lpos, vec3 world, vec3 n, vec3 l)\n{\n    bool _2469 = fa_mesh_fs_params[5].z < 0.5;\n    bool _2476;\n    if (!_2469)\n    {\n        _2476 = fa_shadows[29].x < 0.5;\n    }\n    else\n    {\n        _2476 = _2469;\n    }\n    if (_2476)\n    {\n        return 1.0;\n    }\n    int param = (int(fa_shadows[29].x + 0.5) - 1) + li;\n    vec4 _2489 = fa_light_texel(param);\n    float _2490 = _2489.x;\n    if (_2490 < 0.0)\n    {\n        return 1.0;\n    }\n    int _2499 = int(_2490 + 0.5);\n    int param_1 = _2499;\n    vec4 _2503 = fa_light_texel(param_1);\n    int param_2 = _2499 + 1;\n    vec4 _2508 = fa_light_texel(param_2);\n    float fade = 1.0;\n    float _2511 = _2503.y;\n    if (_2511 > 0.0)\n    {\n        float _2528 = 1.0 - smoothstep(0.75 * _2511, _2511, length(world - fa_shadows[27].xyz));\n        fade = _2528;\n        if (_2528 <= 0.0)\n        {\n            return 1.0;\n        }\n    }\n    int face = 0;\n    if (_2503.x > 1.5)\n    {\n        vec3 param_3 = world - lpos;\n        face = fa_cube_face(param_3);\n    }\n    int _2552 = (_2499 + 2) + (face * 6);\n    int param_4 = _2552;\n    int param_5 = _2552 + 1;\n    int param_6 = _2552 + 3;\n    vec4 _2566 = fa_light_texel(param_6);\n    int param_7 = _2552 + 4;\n    vec4 _2571 = fa_light_texel(param_7);\n    int param_8 = _2552 + 5;\n    vec4 _2576 = fa_light_texel(param_8);\n    float _2588 = _2576.x * max(dot(_2566, vec4(world, 1.0)), 0.001000000047497451305389404296875);\n    float _2593 = clamp(dot(n, l), 0.0, 1.0);\n    float _2616 = clamp(dot(n, _2566.xyz), -1.0, 1.0);\n    float _2635 = min(sqrt(1.0 - (_2616 * _2616)) / max(abs(dot(n, world - lpos)) / max(dot(_2566, vec4(world, 1.0)), 0.001000000047497451305389404296875), 0.20000000298023223876953125), 4.0);\n    float _2638 = _2508.y;\n    float _2640;\n    if (_2638 > 0.0)\n    {\n        _2640 = _2638;\n    }\n    else\n    {\n        _2640 = 1.5 * _2588;\n    }\n    vec4 _2660 = vec4(world + (n * (_2640 * sqrt(1.0 - (_2593 * _2593)))), 1.0);\n    float _2664 = dot(_2566, _2660);\n    float _2667 = _2576.y;\n    if (_2664 < _2667)\n    {\n        return 1.0;\n    }\n    vec2 _2682 = vec2(dot(fa_light_texel(param_4), _2660), dot(fa_light_texel(param_5), _2660)) / vec2(_2664);\n    float _2684 = _2682.x;\n    bool _2687 = _2684 < _2571.x;\n    bool _2696;\n    if (!_2687)\n    {\n        _2696 = _2684 > _2571.z;\n    }\n    else\n    {\n        _2696 = _2687;\n    }\n    bool _2705;\n    if (!_2696)\n    {\n        _2705 = _2682.y < _2571.y;\n    }\n    else\n    {\n        _2705 = _2696;\n    }\n    bool _2714;\n    if (!_2705)\n    {\n        _2714 = _2682.y > _2571.w;\n    }\n    else\n    {\n        _2714 = _2705;\n    }\n    if (_2714)\n    {\n        return 1.0;\n    }\n    float _2720 = _2508.x;\n    float _2722;\n    if (_2720 > 0.0)\n    {\n        _2722 = _2720;\n    }\n    else\n    {\n        _2722 = 1.5 * _2588;\n    }\n    vec2 param_9 = _2682;\n    vec4 param_10 = _2571;\n    float param_11 = _2664 - (_2722 * (1.0 + (0.5 * _2635)));\n    float param_12 = _2588;\n    float param_13 = 1.0;\n    float param_14 = _2576.z * 0.25;\n    float param_15 = (_2588 * min(_2635, 3.0)) * 0.5;\n    vec3 param_16 = vec3(1.0, _2667, _2576.z);\n    int param_17 = int(_2503.z + 0.5);\n    float param_18 = _2503.w;\n    return mix(1.0, fa_shadow_filter(param_9, param_10, param_11, param_12, param_13, param_14, param_15, param_16, param_17, param_18), fade);\n}\n\nLightSample fa_light_shadowed(int li, vec3 world_pos, vec3 gn)\n{\n    bool _3262 = fa_lm.z > 0.5;\n    bool _3268;\n    if (_3262)\n    {\n        int param = li;\n        _3268 = fa_light_baked(param);\n    }\n    else\n    {\n        _3268 = _3262;\n    }\n    if (_3268)\n    {\n        int param_1 = li;\n        return LightSample(vec3(0.0, 1.0, 0.0), vec3(0.0), 0.0, 1.0, 0.0, int(fa_light_type(param_1) + 0.5));\n    }\n    int param_2 = li;\n    vec3 param_3 = world_pos;\n    vec3 param_4 = gn;\n    LightSample _3292 = fa_light_sample_n(param_2, param_3, param_4);\n    vec3 _4324 = _3292.color;\n    float _4326 = _3292.shadow;\n    if ((_3292.type == 0) && (li == 0))\n    {\n        vec3 param_5 = gn;\n        vec3 param_6 = _3292.direction;\n        float _3306 = fa_shadow_factor(param_5, param_6);\n        _4326 = _3306;\n        _4324 *= _3306;\n    }\n    else\n    {\n        bool _3317 = _3292.type != 0;\n        bool _3323;\n        if (_3317)\n        {\n            _3323 = _3292.attenuation > 0.0;\n        }\n        else\n        {\n            _3323 = _3317;\n        }\n        if (_3323)\n        {\n            int param_7 = li;\n            int param_8 = fa_light_base(param_7);\n            int param_9 = li;\n            vec3 param_10 = fa_light_texel(param_8).xyz;\n            vec3 param_11 = world_pos;\n            vec3 param_12 = gn;\n            vec3 param_13 = _3292.direction;\n            float _3342 = fa_shadow_local(param_9, param_10, param_11, param_12, param_13);\n            _4326 = _3342;\n            _4324 *= _3342;\n        }\n    }\n    return LightSample(_3292.direction, _4324, _3292.attenuation, _4326, _3292._distance, _3292.type);\n}\n\nvec3 light(SurfaceInput i, Surface s, LightSample l)\n{\n    float _3362;\n    if (dot(s.normal, l.direction) > 0.5)\n    {\n        _3362 = 1.0;\n    }\n    else\n    {\n        _3362 = fa_material[0].x;\n    }\n    return (s.albedo * l.color) * _3362;\n}\n\nvec3 fa_shadow_debug(vec3 color, vec3 world)\n{\n    if (fa_shadows[27].w < 0.5)\n    {\n        return color;\n    }\n    int _2971 = int(fa_shadows[25].x + 0.5);\n    float _2981 = dot(world - fa_shadows[27].xyz, fa_shadows[28].xyz);\n    vec3 tint = vec3(0.3499999940395355224609375);\n    bool _2986 = _2971 > 0;\n    bool _2995;\n    if (_2986)\n    {\n        int param = _2971 - 1;\n        _2995 = _2981 <= fa_shadow_split_at(param);\n    }\n    else\n    {\n        _2995 = _2986;\n    }\n    if (_2995)\n    {\n        tint = vec3(1.0, 0.1500000059604644775390625, 0.100000001490116119384765625);\n        bool _3001 = _2971 > 1;\n        bool _3008;\n        if (_3001)\n        {\n            _3008 = _2981 > fa_shadows[24].x;\n        }\n        else\n        {\n            _3008 = _3001;\n        }\n        if (_3008)\n        {\n            tint = vec3(0.100000001490116119384765625, 0.89999997615814208984375, 0.20000000298023223876953125);\n        }\n        bool _3014 = _2971 > 2;\n        bool _3021;\n        if (_3014)\n        {\n            _3021 = _2981 > fa_shadows[24].y;\n        }\n        else\n        {\n            _3021 = _3014;\n        }\n        if (_3021)\n        {\n            tint = vec3(0.1500000059604644775390625, 0.300000011920928955078125, 1.0);\n        }\n        bool _3027 = _2971 > 3;\n        bool _3034;\n        if (_3027)\n        {\n            _3034 = _2981 > fa_shadows[24].z;\n        }\n        else\n        {\n            _3034 = _3027;\n        }\n        if (_3034)\n        {\n            tint = vec3(1.0, 0.89999997615814208984375, 0.100000001490116119384765625);\n        }\n    }\n    return mix(color, tint, vec3(0.550000011920928955078125));\n}\n\nvoid main()\n{\n    fa_inst_load();\n    vec3 _4165 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _4165 = -_4165;\n    }\n    vec3 _3750 = normalize(fa_mesh_fs_params[0].xyz - fa_world_pos);\n    vec3 param = fa_world_pos;\n    fa_cluster_begin(param);\n    SurfaceInput param_1 = SurfaceInput(fa_world_pos, _4165, fa_world_tangent, fa_uv, fa_vertex_color, _3750, gl_FrontFacing);\n    Surface _3758 = fa_standard_surface(param_1);\n    vec3 _4196 = _3758.albedo;\n    float _4197 = _3758.alpha;\n    vec3 _4198 = _3758.normal;\n    float _4199 = _3758.metallic;\n    float _4200 = _3758.roughness;\n    float _4201 = _3758.occlusion;\n    vec3 _4202 = _3758.emission;\n    float _4203 = _3758.clearcoat;\n    float _4204 = _3758.clearcoat_roughness;\n    vec3 _4205 = _3758.sheen_color;\n    float _4206 = _3758.sheen_roughness;\n    float _4207 = _3758.anisotropy;\n    float _4208 = _3758.anisotropy_rotation;\n    float _4209 = _3758.specular;\n    float _4210 = _3758.ior;\n    vec3 _4211 = _3758.specular_color;\n    SurfaceInput param_2 = SurfaceInput(fa_world_pos, _4165, fa_world_tangent, fa_uv, fa_vertex_color, _3750, gl_FrontFacing);\n    Surface param_3 = _3758;\n    surface(param_2, param_3);\n    _4196 = param_3.albedo;\n    _4197 = param_3.alpha;\n    _4198 = param_3.normal;\n    _4199 = param_3.metallic;\n    _4200 = param_3.roughness;\n    _4201 = param_3.occlusion;\n    _4202 = param_3.emission;\n    _4203 = param_3.clearcoat;\n    _4204 = param_3.clearcoat_roughness;\n    _4205 = param_3.sheen_color;\n    _4206 = param_3.sheen_roughness;\n    _4207 = param_3.anisotropy;\n    _4208 = param_3.anisotropy_rotation;\n    _4209 = param_3.specular;\n    _4210 = param_3.ior;\n    _4211 = param_3.specular_color;\n    vec3 param_4 = fa_world_pos;\n    vec3 param_5 = _4165;\n    vec3 param_6 = param_3.albedo;\n    vec3 param_7 = param_3.normal;\n    fa_apply_decals(param_4, param_5, param_6, param_7);\n    _4196 = param_6;\n    _4198 = param_7;\n    vec3 result;\n    if (fa_mesh_fs_params[3].w > 0.5)\n    {\n        result = _4196;\n    }\n    else\n    {\n        vec3 _3796 = _4198;\n        vec3 _3797 = normalize(_3796);\n        _4198 = _3797;\n        vec3 param_8 = _3797;\n        vec3 lit = (fa_indirect_diffuse(param_8) * _4196) * _4201;\n        int _3816 = fa_cl_ndir + fa_cl_local;\n        for (int ln = 0; ln < _3816; ln++)\n        {\n            int param_9 = ln;\n            int _3829 = fa_cl_light(param_9);\n            bool _3832 = fa_lm.z > 0.5;\n            bool _3838;\n            if (_3832)\n            {\n                int param_10 = _3829;\n                _3838 = fa_light_baked(param_10);\n            }\n            else\n            {\n                _3838 = _3832;\n            }\n            if (_3838)\n            {\n                continue;\n            }\n            int param_11 = _3829;\n            vec3 param_12 = fa_world_pos;\n            vec3 param_13 = _4165;\n            LightSample _3850 = fa_light_shadowed(param_11, param_12, param_13);\n            SurfaceInput param_14 = SurfaceInput(fa_world_pos, _4165, fa_world_tangent, fa_uv, fa_vertex_color, _3750, gl_FrontFacing);\n            Surface param_15 = Surface(_4196, _4197, _4198, _4199, _4200, _4201, _4202, _4203, _4204, _4205, _4206, _4207, _4208, _4209, _4210, _4211);\n            LightSample param_16 = _3850;\n            lit += light(param_14, param_15, param_16);\n        }\n        result = lit;\n    }\n    vec3 _3865 = result;\n    vec3 _3866 = _3865 + _4202;\n    result = _3866;\n    vec3 param_17 = _3866;\n    vec3 param_18 = fa_world_pos;\n    result = fa_shadow_debug(param_17, param_18);\n    bool _3875 = fa_mesh_fs_params[7].w > 0.0;\n    bool _3882;\n    if (!_3875)\n    {\n        _3882 = fa_mesh_fs_params[8].y > 0.0;\n    }\n    else\n    {\n        _3882 = _3875;\n    }\n    if (_3882)\n    {\n        vec3 _3891 = fa_world_pos - fa_mesh_fs_params[0].xyz;\n        float _3897 = dot(_3891, fa_mesh_fs_params[9].xyz);\n        bool _3901 = fa_mesh_fs_params[9].w > 0.5;\n        float _3902;\n        if (_3901)\n        {\n            _3902 = _3897;\n        }\n        else\n        {\n            _3902 = length(_3891);\n        }\n        float _3914 = _3902 - fa_mesh_fs_params[8].x;\n        if (_3914 > 0.0)\n        {\n            float _3923 = fa_mesh_fs_params[7].w * _3914;\n            float tau = _3923 * _3923;\n            if (fa_mesh_fs_params[8].y > 0.0)\n            {\n                float _3939;\n                if (_3901)\n                {\n                    _3939 = fa_world_pos.y - (fa_mesh_fs_params[9].y * _3897);\n                }\n                else\n                {\n                    _3939 = fa_mesh_fs_params[0].y;\n                }\n                float _3960 = mix(_3939, fa_world_pos.y, clamp(fa_mesh_fs_params[8].x / _3902, 0.0, 1.0));\n                float _3964 = fa_world_pos.y - _3960;\n                float _3969 = _3960 - fa_mesh_fs_params[8].z;\n                float _3974 = fa_world_pos.y - fa_mesh_fs_params[8].z;\n                bool _3977 = _3969 <= 0.0;\n                bool _3978 = !_3977;\n                bool _3984;\n                if (_3978)\n                {\n                    _3984 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _3984 = _3977;\n                }\n                float _3985;\n                if (_3984)\n                {\n                    _3985 = fa_mesh_fs_params[8].y;\n                }\n                else\n                {\n                    _3985 = fa_mesh_fs_params[8].y * exp(-min(fa_mesh_fs_params[8].w * _3969, 80.0));\n                }\n                bool _4012;\n                if (_3978)\n                {\n                    _4012 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _4012 = _3977;\n                }\n                float _4013;\n                if (_4012)\n                {\n                    _4013 = fa_mesh_fs_params[8].y * _3969;\n                }\n                else\n                {\n                    _4013 = (fa_mesh_fs_params[8].y * (1.0 - exp(-min(fa_mesh_fs_params[8].w * _3969, 80.0)))) / fa_mesh_fs_params[8].w;\n                }\n                bool _4038 = _3974 <= 0.0;\n                bool _4045;\n                if (!_4038)\n                {\n                    _4045 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _4045 = _4038;\n                }\n                float _4046;\n                if (_4045)\n                {\n                    _4046 = fa_mesh_fs_params[8].y * _3974;\n                }\n                else\n                {\n                    _4046 = (fa_mesh_fs_params[8].y * (1.0 - exp(-min(fa_mesh_fs_params[8].w * _3974, 80.0)))) / fa_mesh_fs_params[8].w;\n                }\n                float _4073;\n                if (abs(_3964) < 0.001000000047497451305389404296875)\n                {\n                    _4073 = _3985;\n                }\n                else\n                {\n                    _4073 = (_4046 - _4013) / _3964;\n                }\n                tau += (_3914 * max(_4073, 0.0));\n            }\n            result = mix(result, fa_mesh_fs_params[7].xyz, vec3(clamp(1.0 - exp(-clamp(tau, 0.0, 80.0)), 0.0, 1.0)));\n        }\n    }\n    fa_frag_color = vec4(result, _4197);\n}\n\n",
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
            "size": 384,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_378",
            "glsl_uniforms": [
              {
                "type": "vec4",
                "array_count": 24,
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
            "inst_name": "_2035",
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
            "inst_name": "_3368",
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
              "name": "fa_env_tex",
              "multisampled": false,
              "type": "cube",
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
            "name": "fa_env_tex_fa_env_smp",
            "view_name": "fa_env_tex",
            "sampler_name": "fa_env_smp",
            "view_slot": 14,
            "sampler_slot": 10,
            "glsl_name": "fa_env_tex_fa_env_smp"
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
          }
        ]
      }
    },
    "prepass": {
      "vs": "#version 430\n\nstruct VertexData\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 color;\n    vec3 object_pos;\n};\n\nuniform vec4 fa_mesh_vs_params[11];\nlayout(location = 0) out vec3 fa_world_pos;\nlayout(location = 1) out vec3 fa_world_normal;\nlayout(location = 2) out vec4 fa_world_tangent;\nlayout(location = 3) out vec2 fa_uv;\nlayout(location = 4) out vec4 fa_vertex_color;\nlayout(location = 5) out float fa_pre_depth;\nlayout(location = 6) out vec3 fa_pre_r0;\nlayout(location = 7) out vec3 fa_pre_r1;\nlayout(location = 8) out vec3 fa_pre_r2;\nlayout(location = 5) in vec4 fa_inst_m0;\nlayout(location = 6) in vec4 fa_inst_m1;\nlayout(location = 7) in vec4 fa_inst_m2;\nlayout(location = 8) in vec4 fa_inst_m3;\nlayout(location = 0) in vec3 fa_position;\nlayout(location = 1) in vec3 fa_normal;\nlayout(location = 3) in vec4 fa_tangent;\nlayout(location = 2) in vec2 fa_texcoord0;\nlayout(location = 4) in vec4 fa_color;\n\nvoid fa_inst_begin()\n{\n}\n\nVertexData fa_vertex_data(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    vec3 _69 = cross(model[1].xyz, model[2].xyz);\n    float _75 = (dot(model[0].xyz, _69) < 0.0) ? (-1.0) : 1.0;\n    return VertexData((model * vec4(position, 1.0)).xyz, (((_69 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _75, vec4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _75), texcoord0 * fa_mesh_vs_params[8].xy, color, position);\n}\n\nvoid fa_prepass_vertex(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    mat4 param = model;\n    vec3 param_1 = position;\n    vec3 param_2 = normal;\n    vec4 param_3 = tangent;\n    vec2 param_4 = texcoord0;\n    vec4 param_5 = color;\n    VertexData _160 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    vec3 _302 = _160.world_pos;\n    mat4 _164 = mat4(fa_mesh_vs_params[4], fa_mesh_vs_params[5], fa_mesh_vs_params[6], fa_mesh_vs_params[7]);\n    vec4 _171 = vec4(_302, 1.0);\n    fa_world_pos = _302;\n    fa_world_normal = _160.world_normal;\n    fa_world_tangent = _160.world_tangent;\n    fa_uv = _160.uv;\n    fa_vertex_color = _160.color;\n    fa_pre_depth = -(_164 * _171).z;\n    fa_pre_r0 = vec3(_164[0].x, _164[1].x, _164[2].x);\n    fa_pre_r1 = vec3(_164[0].y, _164[1].y, _164[2].y);\n    fa_pre_r2 = vec3(_164[0].z, _164[1].z, _164[2].z);\n    gl_Position = mat4(fa_mesh_vs_params[0], fa_mesh_vs_params[1], fa_mesh_vs_params[2], fa_mesh_vs_params[3]) * _171;\n}\n\nvoid main()\n{\n    fa_inst_begin();\n    mat4 param = mat4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3);\n    vec3 param_1 = fa_position;\n    vec3 param_2 = fa_normal;\n    vec4 param_3 = fa_tangent;\n    vec2 param_4 = fa_texcoord0;\n    vec4 param_5 = fa_color;\n    fa_prepass_vertex(param, param_1, param_2, param_3, param_4, param_5);\n}\n\n",
      "fs": "#version 430\n\nstruct SurfaceInput\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 vertex_color;\n    vec3 view_dir;\n    bool front_facing;\n};\n\nstruct Surface\n{\n    vec3 albedo;\n    float alpha;\n    vec3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    vec3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    vec3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    vec3 specular_color;\n};\n\nuniform vec4 fa_mesh_fs_params[24];\nlayout(binding = 0) uniform sampler2D fa_tex_fa_smp;\nlayout(binding = 1) uniform sampler2D fa_normal_tex_fa_smp;\nlayout(binding = 2) uniform sampler2D fa_mr_tex_fa_smp;\nlayout(binding = 3) uniform sampler2D fa_occlusion_tex_fa_smp;\nlayout(binding = 4) uniform sampler2D fa_emissive_tex_fa_smp;\n\nlayout(location = 0) in vec3 fa_world_pos;\nlayout(location = 1) in vec3 fa_world_normal;\nlayout(location = 2) in vec4 fa_world_tangent;\nlayout(location = 3) in vec2 fa_uv;\nlayout(location = 4) in vec4 fa_vertex_color;\nlayout(location = 6) in vec3 fa_pre_r0;\nlayout(location = 7) in vec3 fa_pre_r1;\nlayout(location = 8) in vec3 fa_pre_r2;\nlayout(location = 0) out vec4 fa_frag_color;\nlayout(location = 5) in float fa_pre_depth;\n\nvoid fa_inst_load()\n{\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nvec3 fa_linear_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_tex_fix(inout vec3 c, float mode)\n{\n    if (mode > 1.5)\n    {\n        vec3 param = c;\n        vec3 _172 = fa_linear_to_srgb(param);\n        c = _172;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            vec3 param_1 = c;\n            vec3 _181 = fa_srgb_to_linear(param_1);\n            c = _181;\n        }\n    }\n    return c;\n}\n\nvec3 fa_tangent_normal(SurfaceInput i, vec3 m)\n{\n    vec3 _56;\n    if (i.front_facing)\n    {\n        _56 = i.world_normal;\n    }\n    else\n    {\n        _56 = -i.world_normal;\n    }\n    vec3 _81 = normalize(i.world_tangent.xyz - (_56 * dot(_56, i.world_tangent.xyz)));\n    vec3 _109 = normalize(((_81 * m.x) + ((cross(_56, _81) * i.world_tangent.w) * m.y)) + (_56 * m.z));\n    vec3 _112;\n    if (i.front_facing)\n    {\n        _112 = _109;\n    }\n    else\n    {\n        _112 = -_109;\n    }\n    return _112;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    vec4 base_t = texture(fa_tex_fa_smp, i.uv);\n    float param = fa_mesh_fs_params[6].w;\n    float param_1 = 1.0;\n    vec3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    vec3 _225 = fa_tex_fix(param_2, param_3);\n    vec4 _787 = base_t;\n    _787.x = _225.x;\n    _787.y = _225.y;\n    _787.z = _225.z;\n    base_t = _787;\n    vec4 _241 = (_787 * fa_mesh_fs_params[2]) * i.vertex_color;\n    vec3 _750 = i.world_normal;\n    if (fa_mesh_fs_params[6].z > 0.5)\n    {\n        float param_4 = fa_mesh_fs_params[6].w;\n        float param_5 = 16.0;\n        vec3 param_6 = texture(fa_normal_tex_fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        vec3 _275 = fa_tex_fix(param_6, param_7);\n        vec3 _279 = (_275 * 2.0) - vec3(1.0);\n        vec2 _284 = _279.xy * fa_mesh_fs_params[6].x;\n        vec3 _795 = _279;\n        _795.x = _284.x;\n        _795.y = _284.y;\n        SurfaceInput param_8 = i;\n        vec3 param_9 = _795;\n        _750 = fa_tangent_normal(param_8, param_9);\n    }\n    vec4 mrt = texture(fa_mr_tex_fa_smp, i.uv);\n    float param_10 = fa_mesh_fs_params[6].w;\n    float param_11 = 64.0;\n    vec3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    vec3 _313 = fa_tex_fix(param_12, param_13);\n    vec4 _798 = mrt;\n    _798.x = _313.x;\n    _798.y = _313.y;\n    _798.z = _313.z;\n    mrt = _798;\n    vec4 _343 = texture(fa_occlusion_tex_fa_smp, i.uv);\n    float param_14 = fa_mesh_fs_params[6].w;\n    float param_15 = 256.0;\n    vec3 param_16 = _343.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    vec3 _355 = fa_tex_fix(param_16, param_17);\n    float param_18 = fa_mesh_fs_params[6].w;\n    float param_19 = 4.0;\n    vec3 param_20 = texture(fa_emissive_tex_fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    vec3 _385 = fa_tex_fix(param_20, param_21);\n    float _755 = fa_mesh_fs_params[20].x;\n    float _756 = fa_mesh_fs_params[20].y;\n    float _759 = fa_mesh_fs_params[20].z;\n    float _758 = fa_mesh_fs_params[21].w;\n    float _761 = fa_mesh_fs_params[22].x;\n    if (fa_mesh_fs_params[22].z > 0.5)\n    {\n        if (mod(fa_mesh_fs_params[22].z, 2.0) > 0.5)\n        {\n            _755 *= _355.y;\n            _756 *= _355.z;\n            _758 *= _343.w;\n        }\n        if (fa_mesh_fs_params[22].z > 1.5)\n        {\n            _759 *= mrt.x;\n            _761 *= mrt.w;\n        }\n    }\n    return Surface(_241.xyz, _241.w, _750, clamp(fa_mesh_fs_params[5].x * _313.z, 0.0, 1.0), clamp(fa_mesh_fs_params[5].y * _313.y, 0.0500000007450580596923828125, 1.0), 1.0 + (fa_mesh_fs_params[6].y * (_355.x - 1.0)), fa_mesh_fs_params[3].xyz + (fa_mesh_fs_params[4].xyz * _385), _755, _756, fa_mesh_fs_params[21].xyz, _758, _759, fa_mesh_fs_params[20].w, _761, fa_mesh_fs_params[22].y, fa_mesh_fs_params[23].xyz);\n}\n\nvoid surface(SurfaceInput i, Surface s)\n{\n}\n\nvoid main()\n{\n    fa_inst_load();\n    vec3 _661 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _661 = -_661;\n    }\n    vec3 _519 = normalize(fa_mesh_fs_params[0].xyz - fa_world_pos);\n    SurfaceInput param = SurfaceInput(fa_world_pos, _661, fa_world_tangent, fa_uv, fa_vertex_color, _519, gl_FrontFacing);\n    SurfaceInput param_1 = SurfaceInput(fa_world_pos, _661, fa_world_tangent, fa_uv, fa_vertex_color, _519, gl_FrontFacing);\n    Surface param_2 = fa_standard_surface(param);\n    surface(param_1, param_2);\n    vec3 _534 = normalize(param_2.normal);\n    vec3 _549 = normalize(vec3(dot(fa_pre_r0, _534), dot(fa_pre_r1, _534), dot(fa_pre_r2, _534)));\n    float _561 = _549.z;\n    vec2 e = _549.xy / vec2((abs(_549.x) + abs(_549.y)) + abs(_561));\n    if (_561 < 0.0)\n    {\n        e = (vec2(1.0) - abs(e.yx)) * vec2((e.x >= 0.0) ? 1.0 : (-1.0), (e.y >= 0.0) ? 1.0 : (-1.0));\n    }\n    fa_frag_color = vec4(min(fa_pre_depth, 60000.0), e, 1.0);\n}\n\n",
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
            "size": 384,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_213",
            "glsl_uniforms": [
              {
                "type": "vec4",
                "array_count": 24,
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
      "vs": "#version 430\n\nstruct VertexData\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 color;\n    vec3 object_pos;\n};\n\nuniform vec4 fa_mesh_vs_params[11];\nuniform vec4 fa_skin[192];\nlayout(location = 0) out vec3 fa_world_pos;\nlayout(location = 1) out vec3 fa_world_normal;\nlayout(location = 2) out vec4 fa_world_tangent;\nlayout(location = 3) out vec2 fa_uv;\nlayout(location = 4) out vec4 fa_vertex_color;\nlayout(location = 5) out float fa_pre_depth;\nlayout(location = 6) out vec3 fa_pre_r0;\nlayout(location = 7) out vec3 fa_pre_r1;\nlayout(location = 8) out vec3 fa_pre_r2;\nlayout(location = 5) in vec4 fa_inst_m0;\nlayout(location = 6) in vec4 fa_inst_m1;\nlayout(location = 7) in vec4 fa_inst_m2;\nlayout(location = 8) in vec4 fa_inst_m3;\nlayout(location = 9) in vec4 fa_joints;\nlayout(location = 10) in vec4 fa_weights;\nlayout(location = 0) in vec3 fa_position;\nlayout(location = 1) in vec3 fa_normal;\nlayout(location = 3) in vec4 fa_tangent;\nlayout(location = 2) in vec2 fa_texcoord0;\nlayout(location = 4) in vec4 fa_color;\n\nvoid fa_inst_begin()\n{\n}\n\nmat4 fa_skin_matrix(vec4 joints, vec4 weights)\n{\n    vec4 r0 = vec4(0.0);\n    vec4 r1 = vec4(0.0);\n    vec4 r2 = vec4(0.0);\n    for (int i = 0; i < 4; i++)\n    {\n        int _174 = int((joints[i] * 255.0) + 0.5) * 3;\n        r0 += (fa_skin[_174 * 1 + 0] * weights[i]);\n        r1 += (fa_skin[(_174 + 1) * 1 + 0] * weights[i]);\n        r2 += (fa_skin[(_174 + 2) * 1 + 0] * weights[i]);\n    }\n    return mat4(vec4(r0.x, r1.x, r2.x, 0.0), vec4(r0.y, r1.y, r2.y, 0.0), vec4(r0.z, r1.z, r2.z, 0.0), vec4(r0.w, r1.w, r2.w, 1.0));\n}\n\nVertexData fa_vertex_data(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    vec3 _74 = cross(model[1].xyz, model[2].xyz);\n    float _80 = (dot(model[0].xyz, _74) < 0.0) ? (-1.0) : 1.0;\n    return VertexData((model * vec4(position, 1.0)).xyz, (((_74 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _80, vec4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _80), texcoord0 * fa_mesh_vs_params[8].xy, color, position);\n}\n\nvoid fa_prepass_vertex(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    mat4 param = model;\n    vec3 param_1 = position;\n    vec3 param_2 = normal;\n    vec4 param_3 = tangent;\n    vec2 param_4 = texcoord0;\n    vec4 param_5 = color;\n    VertexData _273 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    vec3 _423 = _273.world_pos;\n    mat4 _277 = mat4(fa_mesh_vs_params[4], fa_mesh_vs_params[5], fa_mesh_vs_params[6], fa_mesh_vs_params[7]);\n    vec4 _284 = vec4(_423, 1.0);\n    fa_world_pos = _423;\n    fa_world_normal = _273.world_normal;\n    fa_world_tangent = _273.world_tangent;\n    fa_uv = _273.uv;\n    fa_vertex_color = _273.color;\n    fa_pre_depth = -(_277 * _284).z;\n    fa_pre_r0 = vec3(_277[0].x, _277[1].x, _277[2].x);\n    fa_pre_r1 = vec3(_277[0].y, _277[1].y, _277[2].y);\n    fa_pre_r2 = vec3(_277[0].z, _277[1].z, _277[2].z);\n    gl_Position = mat4(fa_mesh_vs_params[0], fa_mesh_vs_params[1], fa_mesh_vs_params[2], fa_mesh_vs_params[3]) * _284;\n}\n\nvoid main()\n{\n    fa_inst_begin();\n    vec4 param = fa_joints;\n    vec4 param_1 = fa_weights;\n    mat4 param_2 = mat4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3) * fa_skin_matrix(param, param_1);\n    vec3 param_3 = fa_position;\n    vec3 param_4 = fa_normal;\n    vec4 param_5 = fa_tangent;\n    vec2 param_6 = fa_texcoord0;\n    vec4 param_7 = fa_color;\n    fa_prepass_vertex(param_2, param_3, param_4, param_5, param_6, param_7);\n}\n\n",
      "fs": "#version 430\n\nstruct SurfaceInput\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 vertex_color;\n    vec3 view_dir;\n    bool front_facing;\n};\n\nstruct Surface\n{\n    vec3 albedo;\n    float alpha;\n    vec3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    vec3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    vec3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    vec3 specular_color;\n};\n\nuniform vec4 fa_mesh_fs_params[24];\nlayout(binding = 0) uniform sampler2D fa_tex_fa_smp;\nlayout(binding = 1) uniform sampler2D fa_normal_tex_fa_smp;\nlayout(binding = 2) uniform sampler2D fa_mr_tex_fa_smp;\nlayout(binding = 3) uniform sampler2D fa_occlusion_tex_fa_smp;\nlayout(binding = 4) uniform sampler2D fa_emissive_tex_fa_smp;\n\nlayout(location = 0) in vec3 fa_world_pos;\nlayout(location = 1) in vec3 fa_world_normal;\nlayout(location = 2) in vec4 fa_world_tangent;\nlayout(location = 3) in vec2 fa_uv;\nlayout(location = 4) in vec4 fa_vertex_color;\nlayout(location = 6) in vec3 fa_pre_r0;\nlayout(location = 7) in vec3 fa_pre_r1;\nlayout(location = 8) in vec3 fa_pre_r2;\nlayout(location = 0) out vec4 fa_frag_color;\nlayout(location = 5) in float fa_pre_depth;\n\nvoid fa_inst_load()\n{\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nvec3 fa_linear_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_tex_fix(inout vec3 c, float mode)\n{\n    if (mode > 1.5)\n    {\n        vec3 param = c;\n        vec3 _172 = fa_linear_to_srgb(param);\n        c = _172;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            vec3 param_1 = c;\n            vec3 _181 = fa_srgb_to_linear(param_1);\n            c = _181;\n        }\n    }\n    return c;\n}\n\nvec3 fa_tangent_normal(SurfaceInput i, vec3 m)\n{\n    vec3 _56;\n    if (i.front_facing)\n    {\n        _56 = i.world_normal;\n    }\n    else\n    {\n        _56 = -i.world_normal;\n    }\n    vec3 _81 = normalize(i.world_tangent.xyz - (_56 * dot(_56, i.world_tangent.xyz)));\n    vec3 _109 = normalize(((_81 * m.x) + ((cross(_56, _81) * i.world_tangent.w) * m.y)) + (_56 * m.z));\n    vec3 _112;\n    if (i.front_facing)\n    {\n        _112 = _109;\n    }\n    else\n    {\n        _112 = -_109;\n    }\n    return _112;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    vec4 base_t = texture(fa_tex_fa_smp, i.uv);\n    float param = fa_mesh_fs_params[6].w;\n    float param_1 = 1.0;\n    vec3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    vec3 _225 = fa_tex_fix(param_2, param_3);\n    vec4 _787 = base_t;\n    _787.x = _225.x;\n    _787.y = _225.y;\n    _787.z = _225.z;\n    base_t = _787;\n    vec4 _241 = (_787 * fa_mesh_fs_params[2]) * i.vertex_color;\n    vec3 _750 = i.world_normal;\n    if (fa_mesh_fs_params[6].z > 0.5)\n    {\n        float param_4 = fa_mesh_fs_params[6].w;\n        float param_5 = 16.0;\n        vec3 param_6 = texture(fa_normal_tex_fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        vec3 _275 = fa_tex_fix(param_6, param_7);\n        vec3 _279 = (_275 * 2.0) - vec3(1.0);\n        vec2 _284 = _279.xy * fa_mesh_fs_params[6].x;\n        vec3 _795 = _279;\n        _795.x = _284.x;\n        _795.y = _284.y;\n        SurfaceInput param_8 = i;\n        vec3 param_9 = _795;\n        _750 = fa_tangent_normal(param_8, param_9);\n    }\n    vec4 mrt = texture(fa_mr_tex_fa_smp, i.uv);\n    float param_10 = fa_mesh_fs_params[6].w;\n    float param_11 = 64.0;\n    vec3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    vec3 _313 = fa_tex_fix(param_12, param_13);\n    vec4 _798 = mrt;\n    _798.x = _313.x;\n    _798.y = _313.y;\n    _798.z = _313.z;\n    mrt = _798;\n    vec4 _343 = texture(fa_occlusion_tex_fa_smp, i.uv);\n    float param_14 = fa_mesh_fs_params[6].w;\n    float param_15 = 256.0;\n    vec3 param_16 = _343.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    vec3 _355 = fa_tex_fix(param_16, param_17);\n    float param_18 = fa_mesh_fs_params[6].w;\n    float param_19 = 4.0;\n    vec3 param_20 = texture(fa_emissive_tex_fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    vec3 _385 = fa_tex_fix(param_20, param_21);\n    float _755 = fa_mesh_fs_params[20].x;\n    float _756 = fa_mesh_fs_params[20].y;\n    float _759 = fa_mesh_fs_params[20].z;\n    float _758 = fa_mesh_fs_params[21].w;\n    float _761 = fa_mesh_fs_params[22].x;\n    if (fa_mesh_fs_params[22].z > 0.5)\n    {\n        if (mod(fa_mesh_fs_params[22].z, 2.0) > 0.5)\n        {\n            _755 *= _355.y;\n            _756 *= _355.z;\n            _758 *= _343.w;\n        }\n        if (fa_mesh_fs_params[22].z > 1.5)\n        {\n            _759 *= mrt.x;\n            _761 *= mrt.w;\n        }\n    }\n    return Surface(_241.xyz, _241.w, _750, clamp(fa_mesh_fs_params[5].x * _313.z, 0.0, 1.0), clamp(fa_mesh_fs_params[5].y * _313.y, 0.0500000007450580596923828125, 1.0), 1.0 + (fa_mesh_fs_params[6].y * (_355.x - 1.0)), fa_mesh_fs_params[3].xyz + (fa_mesh_fs_params[4].xyz * _385), _755, _756, fa_mesh_fs_params[21].xyz, _758, _759, fa_mesh_fs_params[20].w, _761, fa_mesh_fs_params[22].y, fa_mesh_fs_params[23].xyz);\n}\n\nvoid surface(SurfaceInput i, Surface s)\n{\n}\n\nvoid main()\n{\n    fa_inst_load();\n    vec3 _661 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _661 = -_661;\n    }\n    vec3 _519 = normalize(fa_mesh_fs_params[0].xyz - fa_world_pos);\n    SurfaceInput param = SurfaceInput(fa_world_pos, _661, fa_world_tangent, fa_uv, fa_vertex_color, _519, gl_FrontFacing);\n    SurfaceInput param_1 = SurfaceInput(fa_world_pos, _661, fa_world_tangent, fa_uv, fa_vertex_color, _519, gl_FrontFacing);\n    Surface param_2 = fa_standard_surface(param);\n    surface(param_1, param_2);\n    vec3 _534 = normalize(param_2.normal);\n    vec3 _549 = normalize(vec3(dot(fa_pre_r0, _534), dot(fa_pre_r1, _534), dot(fa_pre_r2, _534)));\n    float _561 = _549.z;\n    vec2 e = _549.xy / vec2((abs(_549.x) + abs(_549.y)) + abs(_561));\n    if (_561 < 0.0)\n    {\n        e = (vec2(1.0) - abs(e.yx)) * vec2((e.x >= 0.0) ? 1.0 : (-1.0), (e.y >= 0.0) ? 1.0 : (-1.0));\n    }\n    fa_frag_color = vec4(min(fa_pre_depth, 60000.0), e, 1.0);\n}\n\n",
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
            "size": 384,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_213",
            "glsl_uniforms": [
              {
                "type": "vec4",
                "array_count": 24,
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
