{
  "format": "factoria.shader/1",
  "engine": "0.38.0",
  "template": "4f7d190a643df7eea422f9bce37d2bb8920145f92f7e586baf62c54f579868ea",
  "slang": "glsl430",
  "params": [],
  "textures": [],
  "programs": {
    "mesh": {
      "vs": "#version 430\n\nstruct VertexData\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 color;\n    vec3 object_pos;\n};\n\nuniform vec4 fa_mesh_vs_params[11];\nlayout(location = 0) out vec3 fa_world_pos;\nlayout(location = 1) out vec3 fa_world_normal;\nlayout(location = 2) out vec4 fa_world_tangent;\nlayout(location = 3) out vec2 fa_uv;\nlayout(location = 4) out vec4 fa_vertex_color;\nlayout(location = 5) in vec4 fa_inst_m0;\nlayout(location = 6) in vec4 fa_inst_m1;\nlayout(location = 7) in vec4 fa_inst_m2;\nlayout(location = 8) in vec4 fa_inst_m3;\nlayout(location = 0) in vec3 fa_position;\nlayout(location = 1) in vec3 fa_normal;\nlayout(location = 3) in vec4 fa_tangent;\nlayout(location = 2) in vec2 fa_texcoord0;\nlayout(location = 4) in vec4 fa_color;\nlayout(location = 5) out vec3 fa_lm;\n\nvoid fa_inst_begin()\n{\n}\n\nVertexData fa_vertex_data(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    vec3 _69 = cross(model[1].xyz, model[2].xyz);\n    float _75 = (dot(model[0].xyz, _69) < 0.0) ? (-1.0) : 1.0;\n    return VertexData((model * vec4(position, 1.0)).xyz, (((_69 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _75, vec4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _75), texcoord0 * fa_mesh_vs_params[8].xy, color, position);\n}\n\nvoid fa_shade_vertex(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    mat4 param = model;\n    vec3 param_1 = position;\n    vec3 param_2 = normal;\n    vec4 param_3 = tangent;\n    vec2 param_4 = texcoord0;\n    vec4 param_5 = color;\n    VertexData _160 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    vec3 _267 = _160.world_pos;\n    fa_world_pos = _267;\n    fa_world_normal = _160.world_normal;\n    fa_world_tangent = _160.world_tangent;\n    fa_uv = _160.uv;\n    fa_vertex_color = _160.color;\n    gl_Position = mat4(fa_mesh_vs_params[0], fa_mesh_vs_params[1], fa_mesh_vs_params[2], fa_mesh_vs_params[3]) * vec4(_267, 1.0);\n}\n\nvoid main()\n{\n    fa_inst_begin();\n    mat4 param = mat4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3);\n    vec3 param_1 = fa_position;\n    vec3 param_2 = fa_normal;\n    vec4 param_3 = fa_tangent;\n    vec2 param_4 = fa_texcoord0;\n    vec4 param_5 = fa_color;\n    fa_shade_vertex(param, param_1, param_2, param_3, param_4, param_5);\n    fa_lm = vec3(0.0);\n}\n\n",
      "fs": "#version 430\n\nstruct SurfaceInput\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 vertex_color;\n    vec3 view_dir;\n    bool front_facing;\n};\n\nstruct LightSample\n{\n    vec3 direction;\n    vec3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct Surface\n{\n    vec3 albedo;\n    float alpha;\n    vec3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    vec3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    vec3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    vec3 specular_color;\n    float transmission;\n    float thickness;\n    vec3 attenuation_color;\n    float attenuation_distance;\n};\n\nuniform vec4 fa_mesh_fs_params[54];\nuniform vec4 fa_shadows[30];\nlayout(binding = 0) uniform sampler2D fa_light_tex_fa_shadow_smp;\nlayout(binding = 1) uniform sampler2D fa_tex_fa_smp;\nlayout(binding = 2) uniform sampler2D fa_normal_tex_fa_smp;\nlayout(binding = 3) uniform sampler2D fa_mr_tex_fa_smp;\nlayout(binding = 4) uniform sampler2D fa_occlusion_tex_fa_smp;\nlayout(binding = 5) uniform sampler2D fa_emissive_tex_fa_smp;\nlayout(binding = 6) uniform sampler2D fa_decal_tex_fa_env_smp;\nlayout(binding = 7) uniform sampler2D fa_lightmap_fa_env_smp;\nlayout(binding = 8) uniform sampler2D fa_probe_atlas_fa_env_smp;\nlayout(binding = 9) uniform sampler2D fa_light_atlas_fa_env_smp;\nlayout(binding = 10) uniform sampler2D fa_screen_tex_fa_shadow_smp;\nlayout(binding = 11) uniform sampler2D fa_shadow_tex_fa_shadow_smp;\n\nlayout(location = 0) in vec3 fa_world_pos;\nlayout(location = 5) in vec3 fa_lm;\nlayout(location = 1) in vec3 fa_world_normal;\nlayout(location = 2) in vec4 fa_world_tangent;\nlayout(location = 3) in vec2 fa_uv;\nlayout(location = 4) in vec4 fa_vertex_color;\nlayout(location = 0) out vec4 fa_frag_color;\nfloat fa_rt_slope;\nvec3 fa_light_tint;\nbool fa_light_is_area;\nint fa_cl_ndir;\nint fa_cl_slot;\nint fa_cl_local;\n\nvoid fa_inst_load()\n{\n}\n\nvec4 fa_light_texel(int t)\n{\n    return texelFetch(fa_light_tex_fa_shadow_smp, ivec2(t & 1023, t >> 10), 0);\n}\n\nvec4 fa_cluster_texel(vec3 world_pos)\n{\n    bool _1351 = fa_mesh_fs_params[19].x < 0.0;\n    bool _1358;\n    if (!_1351)\n    {\n        _1358 = fa_mesh_fs_params[19].w < 1.0;\n    }\n    else\n    {\n        _1358 = _1351;\n    }\n    bool _1366;\n    if (!_1358)\n    {\n        _1366 = fa_mesh_fs_params[18].x < 1.0;\n    }\n    else\n    {\n        _1366 = _1358;\n    }\n    bool _1373;\n    if (!_1366)\n    {\n        _1373 = fa_mesh_fs_params[18].y < 1.0;\n    }\n    else\n    {\n        _1373 = _1366;\n    }\n    bool _1380;\n    if (!_1373)\n    {\n        _1380 = fa_mesh_fs_params[19].y < 1.0;\n    }\n    else\n    {\n        _1380 = _1373;\n    }\n    if (_1380)\n    {\n        return vec4(0.0);\n    }\n    vec4 _1390 = vec4(world_pos, 1.0);\n    float _1396 = dot(fa_mesh_fs_params[16], _1390);\n    if (!(_1396 > 9.9999999747524270787835121154785e-07))\n    {\n        return vec4(0.0);\n    }\n    vec2 _1418 = vec2(dot(fa_mesh_fs_params[14], _1390), dot(fa_mesh_fs_params[15], _1390)) / vec2(_1396);\n    int _1422 = int(fa_mesh_fs_params[18].x);\n    int _1426 = int(fa_mesh_fs_params[18].y);\n    int param = (int(fa_mesh_fs_params[19].x) + (((clamp(int(floor(log2(max(dot(fa_mesh_fs_params[17].xyz, world_pos) + fa_mesh_fs_params[17].w, fa_mesh_fs_params[18].w) / fa_mesh_fs_params[18].w) * fa_mesh_fs_params[18].z)), 0, int(fa_mesh_fs_params[19].y) - 1) * _1426) + clamp(int(floor(((_1418.y * 0.5) + 0.5) * fa_mesh_fs_params[18].y)), 0, _1426 - 1)) * _1422)) + clamp(int(floor(((_1418.x * 0.5) + 0.5) * fa_mesh_fs_params[18].x)), 0, _1422 - 1);\n    return fa_light_texel(param);\n}\n\nivec2 fa_cluster_lookup(vec3 world_pos)\n{\n    vec3 param = world_pos;\n    vec4 _1502 = fa_cluster_texel(param);\n    return ivec2(int(_1502.x), int(_1502.y));\n}\n\nvoid fa_cluster_begin(vec3 world_pos)\n{\n    float _4202 = dot(fa_mesh_fs_params[29].xyz, world_pos) + fa_mesh_fs_params[29].w;\n    float _4205 = fwidth(_4202);\n    bool _4208 = fa_mesh_fs_params[25].y > 0.5;\n    bool _4215;\n    if (!_4208)\n    {\n        _4215 = fa_mesh_fs_params[25].w > 0.5;\n    }\n    else\n    {\n        _4215 = _4208;\n    }\n    if (_4215)\n    {\n        fa_rt_slope = min(1.5 * _4205, 0.100000001490116119384765625 * _4202);\n    }\n    fa_cl_ndir = int(fa_mesh_fs_params[19].z);\n    vec3 param = world_pos;\n    ivec2 _4231 = fa_cluster_lookup(param);\n    fa_cl_slot = _4231.x;\n    fa_cl_local = _4231.y;\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_linear_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvec3 fa_tex_fix(inout vec3 c, float mode)\n{\n    if (mode > 1.5)\n    {\n        vec3 param = c;\n        vec3 _4436 = fa_linear_to_srgb(param);\n        c = _4436;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            vec3 param_1 = c;\n            vec3 _4444 = fa_srgb_to_linear(param_1);\n            c = _4444;\n        }\n    }\n    return c;\n}\n\nvec3 fa_tangent_normal(SurfaceInput i, vec3 m)\n{\n    vec3 _306;\n    if (i.front_facing)\n    {\n        _306 = i.world_normal;\n    }\n    else\n    {\n        _306 = -i.world_normal;\n    }\n    vec3 _330 = normalize(i.world_tangent.xyz - (_306 * dot(_306, i.world_tangent.xyz)));\n    vec3 _357 = normalize(((_330 * m.x) + ((cross(_306, _330) * i.world_tangent.w) * m.y)) + (_306 * m.z));\n    vec3 _360;\n    if (i.front_facing)\n    {\n        _360 = _357;\n    }\n    else\n    {\n        _360 = -_357;\n    }\n    return _360;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    vec4 base_t = texture(fa_tex_fa_smp, i.uv, fa_mesh_fs_params[12].w);\n    float param = fa_mesh_fs_params[6].w;\n    float param_1 = 1.0;\n    vec3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    vec3 _4476 = fa_tex_fix(param_2, param_3);\n    vec4 _6352 = base_t;\n    _6352.x = _4476.x;\n    _6352.y = _4476.y;\n    _6352.z = _4476.z;\n    base_t = _6352;\n    vec4 _4490 = (_6352 * fa_mesh_fs_params[2]) * i.vertex_color;\n    vec3 _6168 = i.world_normal;\n    if (fa_mesh_fs_params[6].z > 0.5)\n    {\n        float param_4 = fa_mesh_fs_params[6].w;\n        float param_5 = 16.0;\n        vec3 param_6 = texture(fa_normal_tex_fa_smp, i.uv, fa_mesh_fs_params[12].w).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        vec3 _4524 = fa_tex_fix(param_6, param_7);\n        vec3 _4527 = (_4524 * 2.0) - vec3(1.0);\n        vec2 _4532 = _4527.xy * fa_mesh_fs_params[6].x;\n        vec3 _6360 = _4527;\n        _6360.x = _4532.x;\n        _6360.y = _4532.y;\n        SurfaceInput param_8 = i;\n        vec3 param_9 = _6360;\n        _6168 = fa_tangent_normal(param_8, param_9);\n    }\n    vec4 mrt = texture(fa_mr_tex_fa_smp, i.uv, fa_mesh_fs_params[12].w);\n    float param_10 = fa_mesh_fs_params[6].w;\n    float param_11 = 64.0;\n    vec3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    vec3 _4562 = fa_tex_fix(param_12, param_13);\n    vec4 _6363 = mrt;\n    _6363.x = _4562.x;\n    _6363.y = _4562.y;\n    _6363.z = _4562.z;\n    mrt = _6363;\n    vec4 _4592 = texture(fa_occlusion_tex_fa_smp, i.uv, fa_mesh_fs_params[12].w);\n    float param_14 = fa_mesh_fs_params[6].w;\n    float param_15 = 256.0;\n    vec3 param_16 = _4592.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    vec3 _4603 = fa_tex_fix(param_16, param_17);\n    float param_18 = fa_mesh_fs_params[6].w;\n    float param_19 = 4.0;\n    vec3 param_20 = texture(fa_emissive_tex_fa_smp, i.uv, fa_mesh_fs_params[12].w).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    vec3 _4635 = fa_tex_fix(param_20, param_21);\n    float _6173 = fa_mesh_fs_params[20].x;\n    float _6174 = fa_mesh_fs_params[20].y;\n    float _6177 = fa_mesh_fs_params[20].z;\n    float _6176 = fa_mesh_fs_params[21].w;\n    float _6179 = fa_mesh_fs_params[22].x;\n    if (fa_mesh_fs_params[22].z > 0.5)\n    {\n        if (mod(fa_mesh_fs_params[22].z, 2.0) > 0.5)\n        {\n            _6173 *= _4603.y;\n            _6174 *= _4603.z;\n            _6176 *= _4592.w;\n        }\n        if (fa_mesh_fs_params[22].z > 1.5)\n        {\n            _6177 *= mrt.x;\n            _6179 *= mrt.w;\n        }\n    }\n    return Surface(_4490.xyz, _4490.w, _6168, clamp(fa_mesh_fs_params[5].x * _4562.z, 0.0, 1.0), clamp(fa_mesh_fs_params[5].y * _4562.y, 0.0500000007450580596923828125, 1.0), 1.0 + (fa_mesh_fs_params[6].y * (_4603.x - 1.0)), fa_mesh_fs_params[3].xyz + (fa_mesh_fs_params[4].xyz * _4635), _6173, _6174, fa_mesh_fs_params[21].xyz, _6176, _6177, fa_mesh_fs_params[20].w, _6179, fa_mesh_fs_params[22].y, fa_mesh_fs_params[23].xyz, fa_mesh_fs_params[30].x, fa_mesh_fs_params[30].y, fa_mesh_fs_params[31].xyz, fa_mesh_fs_params[30].z);\n}\n\nvoid surface(SurfaceInput i, Surface s)\n{\n}\n\nvec4 fa_decal_tile(vec4 rect, vec2 uv, vec2 atlas, vec2 ddx, vec2 ddy)\n{\n    vec2 _1582 = rect.zw - rect.xy;\n    vec2 _1586 = _1582 * atlas;\n    vec2 _1590 = ddx * _1586;\n    vec2 _1594 = ddy * _1586;\n    return textureLod(fa_decal_tex_fa_env_smp, rect.xy + (clamp(uv, vec2(0.0), vec2(1.0)) * _1582), clamp(0.5 * log2(max(max(dot(_1590, _1590), dot(_1594, _1594)), 9.9999999392252902907785028219223e-09)), 0.0, 3.0));\n}\n\nvec3 fa_dc_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_dc_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvoid fa_apply_decals(vec3 world_pos, vec3 geo_normal, inout vec3 albedo, inout vec3 normal)\n{\n    bool _1627 = fa_mesh_fs_params[10].y < 0.5;\n    bool _1634;\n    if (!_1627)\n    {\n        _1634 = fa_mesh_fs_params[10].w < 0.5;\n    }\n    else\n    {\n        _1634 = _1627;\n    }\n    if (_1634)\n    {\n        return;\n    }\n    vec3 _1640 = dFdx(world_pos);\n    vec3 _1643 = dFdy(world_pos);\n    vec3 param = world_pos;\n    vec4 _1647 = fa_cluster_texel(param);\n    int _1651 = int(_1647.w);\n    if (_1651 < 1)\n    {\n        return;\n    }\n    int _1661 = int(fa_mesh_fs_params[10].y + 0.5);\n    int param_1 = _1661;\n    vec4 _1665 = fa_light_texel(param_1);\n    vec2 _1668 = _1665.yz;\n    int _1672 = int(_1665.w);\n    int param_2 = _1661 + 1;\n    vec4 _1677 = fa_light_texel(param_2);\n    float _1678 = _1677.x;\n    int _1684 = int(fa_mesh_fs_params[10].w + 0.5) - 1;\n    int _1688 = int(_1647.z);\n    vec3 _1953;\n    for (int k = 0; k < _1651; k++)\n    {\n        int _1701 = _1688 + k;\n        int param_3 = _1672 + (_1701 >> 2);\n        int _1718 = (_1661 + 2) + (int(fa_light_texel(param_3)[_1701 & 3]) * 7);\n        int param_4 = _1718 + 6;\n        vec4 _1723 = fa_light_texel(param_4);\n        if (((int(_1723.w + 0.5) >> _1684) & 1) == 0)\n        {\n            continue;\n        }\n        int param_5 = _1718;\n        vec4 _1738 = fa_light_texel(param_5);\n        int param_6 = _1718 + 1;\n        vec4 _1743 = fa_light_texel(param_6);\n        int param_7 = _1718 + 2;\n        vec4 _1748 = fa_light_texel(param_7);\n        vec3 _1751 = _1738.xyz;\n        float _1756 = dot(_1751, world_pos) + _1738.w;\n        vec3 _1758 = _1743.xyz;\n        float _1763 = dot(_1758, world_pos) + _1743.w;\n        vec3 _1765 = _1748.xyz;\n        float _1770 = dot(_1765, world_pos) + _1748.w;\n        bool _1775 = abs(_1756) > 0.5;\n        bool _1783;\n        if (!_1775)\n        {\n            _1783 = abs(_1763) > 0.5;\n        }\n        else\n        {\n            _1783 = _1775;\n        }\n        bool _1791;\n        if (!_1783)\n        {\n            _1791 = abs(_1770) > 0.5;\n        }\n        else\n        {\n            _1791 = _1783;\n        }\n        if (_1791)\n        {\n            continue;\n        }\n        float _1806 = clamp(dot(geo_normal, normalize(_1765)) * _1723.z, 0.0, 1.0);\n        if (_1806 <= 0.0)\n        {\n            continue;\n        }\n        float _1826 = (clamp((0.5 - abs(_1770)) * 10.0, 0.0, 1.0) * _1806) * _1723.x;\n        vec2 _1834 = vec2(_1756 + 0.5, 0.5 - _1763);\n        vec2 _1844 = vec2(dot(_1751, _1640), dot(_1758, _1640));\n        vec2 _1854 = vec2(dot(_1751, _1643), dot(_1758, _1643));\n        int param_8 = _1718 + 5;\n        vec4 _1859 = fa_light_texel(param_8);\n        int param_9 = _1718 + 3;\n        vec4 _1864 = fa_light_texel(param_9);\n        int param_10 = _1718 + 4;\n        vec4 _1869 = fa_light_texel(param_10);\n        float tex_a = 1.0;\n        vec3 col = _1859.xyz;\n        bool _1879 = _1864.z > _1864.x;\n        if (_1879)\n        {\n            vec4 param_11 = _1864;\n            vec2 param_12 = _1834;\n            vec2 param_13 = _1668;\n            vec2 param_14 = _1844;\n            vec2 param_15 = _1854;\n            vec4 tx = fa_decal_tile(param_11, param_12, param_13, param_14, param_15);\n            if ((_1678 > 0.5) && (_1678 < 1.5))\n            {\n                vec3 param_16 = tx.xyz;\n                vec3 _1905 = fa_dc_to_linear(param_16);\n                vec4 _6256 = tx;\n                _6256.x = _1905.x;\n                _6256.y = _1905.y;\n                _6256.z = _1905.z;\n                tx = _6256;\n            }\n            col *= tx.xyz;\n            tex_a = tx.w;\n        }\n        albedo = mix(albedo, col, vec3(clamp((_1826 * tex_a) * _1859.w, 0.0, 1.0)));\n        if (_1869.z > _1869.x)\n        {\n            vec4 param_17 = _1869;\n            vec2 param_18 = _1834;\n            vec2 param_19 = _1668;\n            vec2 param_20 = _1844;\n            vec2 param_21 = _1854;\n            vec4 _1949 = fa_decal_tile(param_17, param_18, param_19, param_20, param_21);\n            if (_1678 > 1.5)\n            {\n                vec3 param_22 = _1949.xyz;\n                vec3 _1959 = fa_dc_to_srgb(param_22);\n                _1953 = _1959;\n            }\n            else\n            {\n                _1953 = _1949.xyz;\n            }\n            vec3 _1968 = (_1953 * 2.0) - vec3(1.0);\n            vec2 _1973 = _1968.xy * _1723.y;\n            vec3 _1995 = (normalize(_1751) * _1973.x) + (normalize(_1758) * _1973.y);\n            vec3 _1998 = normalize(normal);\n            normal = normalize(mix(_1998, normalize((_1998 * max(_1968.z, 0.0500000007450580596923828125)) + (_1995 - (_1998 * dot(_1998, _1995)))), vec3(clamp(_1826 * (_1879 ? tex_a : 1.0), 0.0, 1.0))));\n        }\n    }\n}\n\nvec2 fa_atlas_size()\n{\n    return vec2(textureSize(fa_probe_atlas_fa_env_smp, 0));\n}\n\nvec3 fa_probe_sh_coef(vec2 origin, float res, int k)\n{\n    vec3 v = textureLod(fa_probe_atlas_fa_env_smp, (origin + vec2(float(k) + 0.5, res + 2.5)) / fa_atlas_size(), 0.0).xyz;\n    if (fa_mesh_fs_params[41].y > 0.5)\n    {\n        v = ((v * 255.0) - vec3(128.0)) * 0.03149606287479400634765625;\n    }\n    return v;\n}\n\nvec3 fa_sh_eval(vec3 c[9], vec3 n)\n{\n    vec3 _3666 = max((((c[0] * 0.2820948064327239990234375) + (((c[1] * (0.3257350027561187744140625 * n.y)) + (c[2] * (0.3257350027561187744140625 * n.z))) + (c[3] * (0.3257350027561187744140625 * n.x)))) + (((c[4] * ((0.2731371223926544189453125 * n.x) * n.y)) + (c[5] * ((0.2731371223926544189453125 * n.y) * n.z))) + (c[6] * (0.078847892582416534423828125 * (((3.0 * n.z) * n.z) - 1.0))))) + ((c[7] * ((0.2731371223926544189453125 * n.x) * n.z)) + (c[8] * (0.13656856119632720947265625 * ((n.x * n.x) - (n.y * n.y))))), vec3(0.0));\n    return _3666;\n}\n\nvec3 fa_ambient_light(vec3 n)\n{\n    float _3775 = (1.0 - fa_mesh_fs_params[42].w) - fa_mesh_fs_params[47].w;\n    vec3 amb = vec3(0.0);\n    bool _3781 = fa_mesh_fs_params[11].w > 0.5;\n    vec3 c[9];\n    for (int k = 0; k < 9; k++)\n    {\n        c[k] = vec3(0.0);\n    }\n    if (_3775 > 0.0005000000237487256526947021484375)\n    {\n        if (_3781)\n        {\n            for (int k_1 = 0; k_1 < 9; k_1++)\n            {\n                vec2 param = fa_mesh_fs_params[41].zw;\n                float param_1 = 128.0;\n                int param_2 = k_1;\n                c[k_1] = fa_probe_sh_coef(param, param_1, param_2) * _3775;\n            }\n        }\n        else\n        {\n            amb = fa_mesh_fs_params[1].xyz * _3775;\n        }\n    }\n    bool _3832 = fa_mesh_fs_params[42].w > 0.0;\n    if (_3832)\n    {\n        for (int k_2 = 0; k_2 < 9; k_2++)\n        {\n            vec2 param_3 = fa_mesh_fs_params[42].xy;\n            float param_4 = fa_mesh_fs_params[42].z;\n            int param_5 = k_2;\n            c[k_2] += (fa_probe_sh_coef(param_3, param_4, param_5) * fa_mesh_fs_params[42].w);\n        }\n    }\n    bool _3863 = fa_mesh_fs_params[47].w > 0.0;\n    if (_3863)\n    {\n        for (int k_3 = 0; k_3 < 9; k_3++)\n        {\n            vec2 param_6 = fa_mesh_fs_params[47].xy;\n            float param_7 = fa_mesh_fs_params[47].z;\n            int param_8 = k_3;\n            c[k_3] += (fa_probe_sh_coef(param_6, param_7, param_8) * fa_mesh_fs_params[47].w);\n        }\n    }\n    if ((_3781 || _3832) || _3863)\n    {\n        vec3 param_9[9] = c;\n        vec3 param_10 = n;\n        amb += fa_sh_eval(param_9, param_10);\n    }\n    return amb;\n}\n\nvec4 fa_gi_fetch(vec2 texel)\n{\n    return textureLod(fa_probe_atlas_fa_env_smp, texel / fa_atlas_size(), 0.0);\n}\n\nvec2 fa_oct_encode(vec3 d)\n{\n    vec3 _3686 = d / vec3(max((abs(d.x) + abs(d.y)) + abs(d.z), 9.9999999600419720025001879548654e-13));\n    float _3689 = _3686.x;\n    float _3691 = _3686.z;\n    vec2 e = vec2(_3689, _3691);\n    if (_3686.y < 0.0)\n    {\n        e = vec2((1.0 - abs(_3691)) * ((_3689 < 0.0) ? (-1.0) : 1.0), (1.0 - abs(_3689)) * ((_3691 < 0.0) ? (-1.0) : 1.0));\n    }\n    return e;\n}\n\nvec3 fa_gi_grid(int rec, vec3 n, vec3 v, out float cover)\n{\n    cover = 0.0;\n    int param = rec;\n    vec4 _4749 = fa_light_texel(param);\n    int param_1 = rec + 1;\n    vec4 _4754 = fa_light_texel(param_1);\n    int param_2 = rec + 2;\n    vec4 _4759 = fa_light_texel(param_2);\n    int param_3 = rec + 3;\n    vec4 _4764 = fa_light_texel(param_3);\n    bool _4767 = _4764.z < 0.5;\n    bool _4775;\n    if (!_4767)\n    {\n        _4775 = fa_atlas_size().y < 1155.0;\n    }\n    else\n    {\n        _4775 = _4767;\n    }\n    if (_4775)\n    {\n        return vec3(0.0);\n    }\n    float _4782 = max(_4749.w, 9.9999997473787516355514526367188e-05);\n    vec3 _4785 = _4754.xyz;\n    vec3 _4789 = _4749.xyz;\n    vec3 _4793 = (fa_world_pos - _4789) / vec3(_4782);\n    vec3 _4802 = min(_4793 + vec3(0.5), (_4785 - vec3(0.5)) - _4793);\n    float _4811 = min(_4802.x, min(_4802.y, _4802.z));\n    if (!(_4811 > 0.0))\n    {\n        return vec3(0.0);\n    }\n    vec3 _4826 = _4785 - vec3(1.0);\n    vec3 _4827 = clamp(_4793, vec3(0.0), _4826);\n    vec3 _4835 = min(floor(_4827), max(_4785 - vec3(2.0), vec3(0.0)));\n    vec3 _4839 = _4827 - _4835;\n    vec3 _4851 = fa_world_pos + (((n * 0.800000011920928955078125) + (v * 0.20000000298023223876953125)) * (0.20000000298023223876953125 * _4782));\n    int _4856 = int(_4759.y + 0.5);\n    float _4861 = 0.3257350027561187744140625 * n.y;\n    float _4865 = 0.3257350027561187744140625 * n.z;\n    float _4869 = 0.3257350027561187744140625 * n.x;\n    float _4876 = (0.2731371223926544189453125 * n.x) * n.y;\n    float _4883 = (0.2731371223926544189453125 * n.y) * n.z;\n    float _4892 = 0.078847892582416534423828125 * (((3.0 * n.z) * n.z) - 1.0);\n    float _4899 = (0.2731371223926544189453125 * n.x) * n.z;\n    float _4912 = 0.13656856119632720947265625 * ((n.x * n.x) - (n.y * n.y));\n    vec3 acc = vec3(0.0);\n    float wsum = 0.0;\n    int _4919 = 8 + int(_4764.w);\n    float _4946;\n    float _4959;\n    float _4973;\n    for (int k = 0; k < _4919; k++)\n    {\n        float _4932 = float(k & 1);\n        float _4936 = float((k >> 1) & 1);\n        float _4940 = float((k >> 2) & 1);\n        if (_4932 > 0.5)\n        {\n            _4946 = _4839.x;\n        }\n        else\n        {\n            _4946 = 1.0 - _4839.x;\n        }\n        if (_4936 > 0.5)\n        {\n            _4959 = _4839.y;\n        }\n        else\n        {\n            _4959 = 1.0 - _4839.y;\n        }\n        if (_4940 > 0.5)\n        {\n            _4973 = _4839.z;\n        }\n        else\n        {\n            _4973 = 1.0 - _4839.z;\n        }\n        float _4983 = (_4946 * _4959) * _4973;\n        if (!(_4983 > 0.0))\n        {\n            continue;\n        }\n        vec3 _4996 = min(_4835 + vec3(_4932, _4936, _4940), _4826);\n        int _5016 = int(((_4759.x + _4996.x) + (_4754.x * (_4996.y + (_4754.y * _4996.z)))) + 0.5);\n        vec2 _5031 = vec2(float(_5016 % _4856) * 10.0, 1024.0 + (float(_5016 / _4856) * 11.0));\n        vec2 param_4 = _5031 + vec2(9.5, 10.5);\n        vec4 _5039 = fa_gi_fetch(param_4);\n        bool _5042 = _5039.y < 0.5;\n        bool _5051;\n        if (!_5042)\n        {\n            _5051 = _5039.x > _4764.y;\n        }\n        else\n        {\n            _5051 = _5042;\n        }\n        if (_5051)\n        {\n            continue;\n        }\n        vec3 _5063 = _4851 - (_4789 + (_4996 * _4782));\n        float _5066 = length(_5063);\n        vec3 _5072 = _5063 / vec3(max(_5066, 9.9999997473787516355514526367188e-05));\n        float _5082 = max(9.9999997473787516355514526367188e-05, (dot(-_5072, n) + 1.0) * 0.5);\n        float w = _4983 * (_5082 * _5082);\n        vec3 param_5 = _5072;\n        vec2 param_6 = (_5031 + vec2(1.0)) + (((fa_oct_encode(param_5) * 0.5) + vec2(0.5)) * 8.0);\n        vec4 _5102 = fa_gi_fetch(param_6);\n        float _5109 = _5066 / max(_4759.z, 9.9999997473787516355514526367188e-05);\n        float _5112 = _5102.x;\n        if (_5109 > _5112)\n        {\n            float _5125 = max(_5102.y - (_5112 * _5112), 0.0);\n            float _5130 = _5109 - _5112;\n            float _5139 = _5125 / max(_5125 + (_5130 * _5130), 9.9999999600419720025001879548654e-13);\n            w *= ((_5139 * _5139) * _5139);\n        }\n        if (!(w > 0.0))\n        {\n            continue;\n        }\n        vec2 param_7 = _5031 + vec2(0.5, 10.5);\n        vec2 param_8 = _5031 + vec2(1.5, 10.5);\n        vec2 param_9 = _5031 + vec2(2.5, 10.5);\n        vec2 param_10 = _5031 + vec2(3.5, 10.5);\n        vec2 param_11 = _5031 + vec2(4.5, 10.5);\n        vec2 param_12 = _5031 + vec2(5.5, 10.5);\n        vec2 param_13 = _5031 + vec2(6.5, 10.5);\n        vec2 param_14 = _5031 + vec2(7.5, 10.5);\n        vec2 param_15 = _5031 + vec2(8.5, 10.5);\n        acc += ((((((((((fa_gi_fetch(param_7).xyz * 0.2820948064327239990234375) + (fa_gi_fetch(param_8).xyz * _4861)) + (fa_gi_fetch(param_9).xyz * _4865)) + (fa_gi_fetch(param_10).xyz * _4869)) + (fa_gi_fetch(param_11).xyz * _4876)) + (fa_gi_fetch(param_12).xyz * _4883)) + (fa_gi_fetch(param_13).xyz * _4892)) + (fa_gi_fetch(param_14).xyz * _4899)) + (fa_gi_fetch(param_15).xyz * _4912)) * w);\n        wsum += w;\n    }\n    if (!(wsum > 9.9999997473787516355514526367188e-06))\n    {\n        return vec3(0.0);\n    }\n    cover = smoothstep(0.0, 1.0, clamp(_4811 * 2.0, 0.0, 1.0)) * smoothstep(0.0, 0.0199999995529651641845703125, wsum);\n    float _5267;\n    if (fa_mesh_fs_params[52].z > 0.5)\n    {\n        _5267 = _4764.x;\n    }\n    else\n    {\n        _5267 = 1.0;\n    }\n    return max(acc / vec3(wsum), vec3(0.0)) * (_4759.w * _5267);\n}\n\nvec3 fa_gi_light(vec3 n, inout float left)\n{\n    left = 1.0;\n    vec3 acc = vec3(0.0);\n    vec3 _5291 = normalize(fa_mesh_fs_params[0].xyz - fa_world_pos);\n    int _5296 = int(fa_mesh_fs_params[52].x + 0.5);\n    int _5301 = int(fa_mesh_fs_params[52].y + 0.5);\n    float param_3;\n    for (int k = 0; (k < _5301) && (k < 8); k++)\n    {\n        int param = _5296 + (4 * k);\n        vec3 param_1 = n;\n        vec3 param_2 = _5291;\n        vec3 _5326 = fa_gi_grid(param, param_1, param_2, param_3);\n        float _5331 = param_3 * left;\n        acc += (_5326 * _5331);\n        left -= _5331;\n        if (left < 0.001000000047497451305389404296875)\n        {\n            left = 0.0;\n            break;\n        }\n    }\n    return acc;\n}\n\nvec3 fa_realtime_or_ambient(vec3 n)\n{\n    vec3 gi = vec3(0.0);\n    float left = 1.0;\n    if (fa_mesh_fs_params[52].y > 0.5)\n    {\n        vec3 param = n;\n        float param_1;\n        vec3 _5360 = fa_gi_light(param, param_1);\n        left = param_1;\n        gi = _5360;\n    }\n    if (left <= 0.0)\n    {\n        return gi;\n    }\n    vec3 param_2 = n;\n    return gi + (fa_ambient_light(param_2) * left);\n}\n\nvec3 fa_indirect_diffuse(vec3 n)\n{\n    if (fa_lm.z > 0.5)\n    {\n        return textureLod(fa_lightmap_fa_env_smp, fa_lm.xy, 0.0).xyz;\n    }\n    if (fa_mesh_fs_params[53].x > 0.5)\n    {\n        vec4 _5402 = vec4(fa_world_pos, 1.0);\n        vec2 _5421 = vec2(dot(fa_mesh_fs_params[26], _5402), dot(fa_mesh_fs_params[27], _5402)) / vec2(max(dot(fa_mesh_fs_params[28], _5402), 9.9999997473787516355514526367188e-05));\n        float _5430;\n        if (fa_mesh_fs_params[24].y > 0.5)\n        {\n            _5430 = (_5421.y * 0.5) + 0.5;\n        }\n        else\n        {\n            _5430 = 0.5 - (_5421.y * 0.5);\n        }\n        return texelFetch(fa_lightmap_fa_env_smp, clamp(ivec2(vec2((_5421.x * 0.5) + 0.5, _5430) * fa_mesh_fs_params[24].zw), ivec2(0), ivec2(fa_mesh_fs_params[24].zw) - ivec2(1)), 0).xyz;\n    }\n    if (fa_mesh_fs_params[32].w > 0.0)\n    {\n        vec3 c[9];\n        for (int k = 0; k < 9; k++)\n        {\n            c[k] = fa_mesh_fs_params[k * 1 + 32].xyz;\n        }\n        vec3 param = n;\n        vec3 param_1[9] = c;\n        vec3 param_2 = n;\n        return mix(fa_ambient_light(param), fa_sh_eval(param_1, param_2), vec3(clamp(fa_mesh_fs_params[32].w, 0.0, 1.0)));\n    }\n    vec3 param_3 = n;\n    return fa_realtime_or_ambient(param_3);\n}\n\nint fa_cluster_index(int slot, int n)\n{\n    int param = (int(fa_mesh_fs_params[19].x) + int(fa_mesh_fs_params[19].w)) + ((slot + n) >> 2);\n    vec4 t = fa_light_texel(param);\n    return int(t[(slot + n) & 3]);\n}\n\nint fa_cl_light(int n)\n{\n    if (n < fa_cl_ndir)\n    {\n        return n;\n    }\n    int param = fa_cl_slot;\n    int param_1 = n - fa_cl_ndir;\n    return fa_cluster_index(param, param_1);\n}\n\nint fa_light_base(int li)\n{\n    return li * ((fa_mesh_fs_params[1].w > 4.5) ? 8 : 4);\n}\n\nbool fa_light_baked(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 3;\n    return fa_light_texel(param_1).w > 0.5;\n}\n\nfloat fa_baked_keep(int li)\n{\n    float _4172;\n    if (fa_lm.z > 0.5)\n    {\n        _4172 = 0.0;\n    }\n    else\n    {\n        _4172 = 1.0 - clamp(fa_mesh_fs_params[32].w, 0.0, 1.0);\n    }\n    bool _4183 = _4172 < 1.0;\n    bool _4189;\n    if (_4183)\n    {\n        int param = li;\n        _4189 = fa_light_baked(param);\n    }\n    else\n    {\n        _4189 = _4183;\n    }\n    return _4189 ? _4172 : 1.0;\n}\n\nfloat fa_light_type(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 1;\n    return fa_light_texel(param_1).w;\n}\n\nvec3 fa_area_point(vec3 c, vec3 axis, vec3 ru, vec3 uu, float hx, float hy, float shape, vec3 p, vec3 r)\n{\n    bool _601 = dot(r, r) > 0.5;\n    if (shape > 1.5)\n    {\n        vec3 _614 = (c - (ru * hx)) - p;\n        vec3 _620 = ru * (2.0 * hx);\n        float _626 = max(dot(_620, _620), 9.9999999392252902907785028219223e-09);\n        float _630 = dot(_614, _620);\n        float t = clamp((-_630) / _626, 0.0, 1.0);\n        if (_601)\n        {\n            float _645 = dot(r, _620);\n            float _651 = _626 - (_645 * _645);\n            if (abs(_651) > (9.9999997473787516355514526367188e-06 * _626))\n            {\n                t = clamp(((dot(r, _614) * _645) - _630) / _651, 0.0, 1.0);\n            }\n        }\n        return (p + _614) + (_620 * t);\n    }\n    vec3 q = p;\n    float _683 = dot(r, axis);\n    bool _691;\n    if (_601)\n    {\n        _691 = abs(_683) > 9.9999997473787516355514526367188e-05;\n    }\n    else\n    {\n        _691 = _601;\n    }\n    if (_691)\n    {\n        float _701 = dot(c - p, axis) / _683;\n        if (_701 > 0.0)\n        {\n            q = p + (r * _701);\n        }\n    }\n    vec3 _714 = q - c;\n    vec2 xy = vec2(dot(_714, ru), dot(_714, uu));\n    if (shape > 0.5)\n    {\n        float _729 = length(xy);\n        if (_729 > hx)\n        {\n            xy *= (hx / _729);\n        }\n    }\n    else\n    {\n        xy = clamp(xy, vec2(-hx, -hy), vec2(hx, hy));\n    }\n    return (c + (ru * xy.x)) + (uu * xy.y);\n}\n\nvec4 fa_atlas_fetch(vec2 texel)\n{\n    return textureLod(fa_light_atlas_fa_env_smp, texel / vec2(textureSize(fa_light_atlas_fa_env_smp, 0)), 0.0);\n}\n\nvec3 fa_cookie_sample(vec2 tile_origin, vec2 uv)\n{\n    vec2 param = (tile_origin + vec2(1.0)) + (clamp(uv, vec2(0.0), vec2(1.0)) * 254.0);\n    return fa_atlas_fetch(param).xyz;\n}\n\nfloat fa_ies_sample(vec2 tile_origin, vec3 d, vec3 axis, vec3 right, vec3 up)\n{\n    float _521 = dot(d, right);\n    float _525 = dot(d, up);\n    float _536;\n    if (((_521 * _521) + (_525 * _525)) > 1.0000000133514319600180897396058e-10)\n    {\n        _536 = atan(_525, _521) * 0.15915493667125701904296875;\n    }\n    else\n    {\n        _536 = 0.0;\n    }\n    vec2 param = tile_origin + vec2(1.0 + ((_536 - floor(_536)) * 64.0), 1.0 + (acos(clamp(dot(d, axis), -1.0, 1.0)) * 10.18591594696044921875));\n    return fa_atlas_fetch(param).x;\n}\n\nint fa_cube_face(vec3 d)\n{\n    vec3 _372 = abs(d);\n    float _374 = _372.x;\n    float _376 = _372.y;\n    bool _377 = _374 >= _376;\n    bool _385;\n    if (_377)\n    {\n        _385 = _374 >= _372.z;\n    }\n    else\n    {\n        _385 = _377;\n    }\n    int _386;\n    if (_385)\n    {\n        _386 = (d.x > 0.0) ? 0 : 1;\n    }\n    else\n    {\n        int _400;\n        if (_376 >= _372.z)\n        {\n            _400 = (d.y > 0.0) ? 2 : 3;\n        }\n        else\n        {\n            _400 = (d.z > 0.0) ? 4 : 5;\n        }\n        _386 = _400;\n    }\n    return _386;\n}\n\nvoid fa_cube_face_basis(int f, out vec3 fwd, out vec3 up)\n{\n    if (f == 0)\n    {\n        fwd = vec3(1.0, 0.0, 0.0);\n        up = vec3(0.0, 1.0, 0.0);\n    }\n    else\n    {\n        if (f == 1)\n        {\n            fwd = vec3(-1.0, 0.0, 0.0);\n            up = vec3(0.0, 1.0, 0.0);\n        }\n        else\n        {\n            if (f == 2)\n            {\n                fwd = vec3(0.0, 1.0, 0.0);\n                up = vec3(0.0, 0.0, 1.0);\n            }\n            else\n            {\n                if (f == 3)\n                {\n                    fwd = vec3(0.0, -1.0, 0.0);\n                    up = vec3(0.0, 0.0, -1.0);\n                }\n                else\n                {\n                    if (f == 4)\n                    {\n                        fwd = vec3(0.0, 0.0, 1.0);\n                        up = vec3(0.0, 1.0, 0.0);\n                    }\n                    else\n                    {\n                        fwd = vec3(0.0, 0.0, -1.0);\n                        up = vec3(0.0, 1.0, 0.0);\n                    }\n                }\n            }\n        }\n    }\n}\n\nLightSample fa_light_sample_n(int li, vec3 world_pos, vec3 n)\n{\n    int param = li;\n    int _767 = fa_light_base(param);\n    bool _771 = fa_mesh_fs_params[1].w > 4.5;\n    int param_1 = _767;\n    vec4 _775 = fa_light_texel(param_1);\n    int param_2 = _767 + 1;\n    vec4 _780 = fa_light_texel(param_2);\n    float _783 = _780.w;\n    float atten = 1.0;\n    float dist = 0.0;\n    fa_light_tint = vec3(1.0);\n    bool _795 = _771 && (_783 > 2.5);\n    fa_light_is_area = _795;\n    bool _797 = _783 < 0.5;\n    vec3 l;\n    if (_797)\n    {\n        l = normalize(_775.xyz);\n        if (_771)\n        {\n            int param_3 = _767 + 6;\n            vec4 _811 = fa_light_texel(param_3);\n            if (_811.z > 0.5)\n            {\n                int param_4 = _767 + 4;\n                vec4 _821 = fa_light_texel(param_4);\n                int param_5 = _767 + 5;\n                vec4 _826 = fa_light_texel(param_5);\n                vec2 param_6 = _811.xy;\n                vec2 param_7 = fract(vec2(dot(world_pos, _821.xyz) * _821.w, (-dot(world_pos, _826.xyz)) * _826.w) + vec2(0.5));\n                fa_light_tint = fa_cookie_sample(param_6, param_7);\n            }\n        }\n    }\n    else\n    {\n        vec3 _856 = _775.xyz;\n        vec3 _858 = _856 - world_pos;\n        vec3 to_light = _858;\n        float _861 = length(_858);\n        float reach = _861;\n        bool front = true;\n        if (_795)\n        {\n            int param_8 = _767 + 7;\n            reach = max(_861 - fa_light_texel(param_8).w, 0.0);\n            int param_9 = _767 + 4;\n            vec4 _885 = fa_light_texel(param_9);\n            int param_10 = _767 + 5;\n            vec4 _890 = fa_light_texel(param_10);\n            int param_11 = _767 + 6;\n            vec4 _895 = fa_light_texel(param_11);\n            float _896 = _895.w;\n            int param_12 = _767 + 2;\n            vec3 _903 = normalize(fa_light_texel(param_12).xyz);\n            bool _905 = _896 > 1.5;\n            bool _913;\n            if (!_905)\n            {\n                _913 = dot(_903, to_light) < 0.0;\n            }\n            else\n            {\n                _913 = _905;\n            }\n            front = _913;\n            vec3 r = vec3(0.0);\n            vec3 _922 = fa_mesh_fs_params[0].xyz - world_pos;\n            bool _926 = dot(n, n) > 0.5;\n            bool _934;\n            if (_926)\n            {\n                _934 = dot(_922, _922) > 9.9999999600419720025001879548654e-13;\n            }\n            else\n            {\n                _934 = _926;\n            }\n            if (_934)\n            {\n                r = reflect(-normalize(_922), normalize(n));\n            }\n            vec3 param_13 = _856;\n            vec3 param_14 = _903;\n            vec3 param_15 = _885.xyz;\n            vec3 param_16 = _890.xyz;\n            float param_17 = _885.w;\n            float param_18 = _890.w;\n            float param_19 = _896;\n            vec3 param_20 = world_pos;\n            vec3 param_21 = r;\n            to_light = fa_area_point(param_13, param_14, param_15, param_16, param_17, param_18, param_19, param_20, param_21) - world_pos;\n        }\n        float _970 = length(to_light);\n        dist = _970;\n        l = to_light / vec3(max(_970, 9.9999997473787516355514526367188e-05));\n        float _984 = reach / max(_775.w, 0.001000000047497451305389404296875);\n        float _990 = clamp(1.0 - (_984 * _984), 0.0, 1.0);\n        float _992;\n        if (front)\n        {\n            _992 = _990 * _990;\n        }\n        else\n        {\n            _992 = 0.0;\n        }\n        atten = _992;\n        bool _1003 = _783 < 2.5;\n        if ((_783 > 1.5) && _1003)\n        {\n            int param_22 = _767 + 2;\n            vec4 _1011 = fa_light_texel(param_22);\n            float _1021 = _1011.w;\n            int param_23 = _767 + 3;\n            vec4 _1026 = fa_light_texel(param_23);\n            float _1027 = _1026.x;\n            float cos_inner = _1027;\n            if (_1027 > 1.5)\n            {\n                cos_inner = mix(_1021, 1.0, 0.25);\n            }\n            atten *= smoothstep(_1021, cos_inner, dot(-l, normalize(_1011.xyz)));\n        }\n        if (_771 && (_783 < 1.5))\n        {\n            int param_24 = _767 + 6;\n            vec4 _1051 = fa_light_texel(param_24);\n            if (_1051.z > 0.5)\n            {\n                vec3 _1059 = -to_light;\n                int param_25 = _767 + 4;\n                int param_26 = _767 + 5;\n                vec3 _1073 = fa_light_texel(param_25).xyz;\n                vec3 _1077 = fa_light_texel(param_26).xyz;\n                vec3 _1086 = vec3(dot(_1059, _1073), dot(_1059, _1077), dot(_1059, cross(_1073, _1077)));\n                vec3 param_27 = _1086;\n                int _1090 = fa_cube_face(param_27);\n                int param_28 = _1090;\n                vec3 param_29;\n                vec3 param_30;\n                fa_cube_face_basis(param_28, param_29, param_30);\n                vec2 _1117 = vec2(dot(_1086, cross(param_29, param_30)), dot(_1086, param_30)) / vec2(max(dot(_1086, param_29), 9.9999997473787516355514526367188e-05));\n                int _1121 = _1090 / 3;\n                vec2 param_31 = _1051.xy + (vec2(float(_1090 - (_1121 * 3)), float(_1121)) * 256.0);\n                vec2 param_32 = vec2(0.5 + (0.5 * _1117.x), 0.5 - (0.5 * _1117.y));\n                fa_light_tint = fa_cookie_sample(param_31, param_32);\n            }\n            int param_33 = _767 + 7;\n            vec4 _1151 = fa_light_texel(param_33);\n            if (_1151.z > 0.5)\n            {\n                int param_34 = _767 + 2;\n                int param_35 = _767 + 4;\n                int param_36 = _767 + 5;\n                vec2 param_37 = _1151.xy;\n                vec3 param_38 = -l;\n                vec3 param_39 = normalize(fa_light_texel(param_34).xyz);\n                vec3 param_40 = fa_light_texel(param_35).xyz;\n                vec3 param_41 = fa_light_texel(param_36).xyz;\n                atten *= fa_ies_sample(param_37, param_38, param_39, param_40, param_41);\n            }\n        }\n        else\n        {\n            if (_771 && _1003)\n            {\n                int param_42 = _767 + 6;\n                vec4 _1198 = fa_light_texel(param_42);\n                int param_43 = _767 + 7;\n                vec4 _1203 = fa_light_texel(param_43);\n                bool _1206 = _1198.z > 0.5;\n                bool _1213;\n                if (!_1206)\n                {\n                    _1213 = _1203.z > 0.5;\n                }\n                else\n                {\n                    _1213 = _1206;\n                }\n                if (_1213)\n                {\n                    int param_44 = _767 + 2;\n                    vec4 _1220 = fa_light_texel(param_44);\n                    vec3 _1224 = normalize(_1220.xyz);\n                    int param_45 = _767 + 4;\n                    vec4 _1229 = fa_light_texel(param_45);\n                    int param_46 = _767 + 5;\n                    vec4 _1234 = fa_light_texel(param_46);\n                    if (_1206)\n                    {\n                        vec3 _1242 = -to_light;\n                        float _1249 = _1220.w;\n                        float _1265 = 0.5 / max(dot(_1242, _1224) * (sqrt(max(1.0 - (_1249 * _1249), 0.0)) / max(_1249, 0.001000000047497451305389404296875)), 9.9999997473787516355514526367188e-05);\n                        vec2 param_47 = _1198.xy;\n                        vec2 param_48 = vec2(0.5 + (dot(_1242, _1229.xyz) * _1265), 0.5 - (dot(_1242, _1234.xyz) * _1265));\n                        fa_light_tint = fa_cookie_sample(param_47, param_48);\n                    }\n                    if (_1203.z > 0.5)\n                    {\n                        vec2 param_49 = _1203.xy;\n                        vec3 param_50 = -l;\n                        vec3 param_51 = _1224;\n                        vec3 param_52 = _1229.xyz;\n                        vec3 param_53 = _1234.xyz;\n                        atten *= fa_ies_sample(param_49, param_50, param_51, param_52, param_53);\n                    }\n                }\n            }\n        }\n    }\n    vec3 _6122 = _780.xyz * atten;\n    if (_771)\n    {\n        _6122 *= fa_light_tint;\n    }\n    int _1333;\n    if (_797)\n    {\n        _1333 = 0;\n    }\n    else\n    {\n        _1333 = ((_783 > 1.5) && (_783 < 2.5)) ? 2 : 1;\n    }\n    return LightSample(l, _6122, atten, 1.0, dist, _1333);\n}\n\nfloat fa_shadow_depth(inout vec2 uv, vec4 rect)\n{\n    uv = clamp(uv, rect.xy, rect.zw);\n    return textureLod(fa_shadow_tex_fa_shadow_smp, uv, 0.0).x;\n}\n\nfloat fa_shadow_fetch(vec2 uv, vec4 rect, vec3 conv)\n{\n    vec2 param = uv;\n    vec4 param_1 = rect;\n    float _2122 = fa_shadow_depth(param, param_1);\n    float _2126;\n    if (conv.x < 0.5)\n    {\n        _2126 = _2122;\n    }\n    else\n    {\n        _2126 = (conv.y * conv.z) / (conv.z - (_2122 * (conv.z - conv.y)));\n    }\n    return _2126;\n}\n\nfloat fa_shadow_noise()\n{\n    return fract(52.98291778564453125 * fract(dot(gl_FragCoord.xy, vec2(0.067110560834407806396484375, 0.005837149918079376220703125))));\n}\n\nvec2 fa_shadow_vogel_turn(vec2 d)\n{\n    return vec2((d.x * (-0.737368881702423095703125)) - (d.y * 0.675490319728851318359375), (d.y * (-0.737368881702423095703125)) + (d.x * 0.675490319728851318359375));\n}\n\nfloat fa_shadow_filter(vec2 uv, vec4 rect, float zr, float texel_m, float unit, float reach, float plane, vec3 conv, int mode, float k)\n{\n    if (mode == 1)\n    {\n        vec2 param = uv;\n        vec4 param_1 = rect;\n        vec3 param_2 = conv;\n        return float(zr <= fa_shadow_fetch(param, param_1, param_2));\n    }\n    float _2172 = fa_shadow_noise() * 6.283185482025146484375;\n    vec2 _2178 = vec2(cos(_2172), sin(_2172));\n    vec2 dir = _2178;\n    float radius = 1.5;\n    if (mode == 2)\n    {\n        float _2187;\n        if (k < 0.0)\n        {\n            _2187 = (-k) / max(zr, 0.100000001490116119384765625);\n        }\n        else\n        {\n            _2187 = k;\n        }\n        float _2206 = clamp((_2187 * reach) / texel_m, 3.0, 12.0);\n        float sum = 0.0;\n        float cnt = 0.0;\n        for (int i = 0; i < 16; i++)\n        {\n            float _2225 = sqrt((float(i) + 0.5) * 0.0625) * _2206;\n            vec2 param_3 = uv + (dir * (fa_shadows[26].zw * _2225));\n            vec4 param_4 = rect;\n            vec3 param_5 = conv;\n            float _2239 = fa_shadow_fetch(param_3, param_4, param_5);\n            if (_2239 < (zr - (_2225 * plane)))\n            {\n                sum += _2239;\n                cnt += 1.0;\n            }\n            vec2 param_6 = dir;\n            dir = fa_shadow_vogel_turn(param_6);\n        }\n        if (cnt < 0.5)\n        {\n            return 1.0;\n        }\n        float _2267 = sum / cnt;\n        float _2277;\n        if (k < 0.0)\n        {\n            _2277 = (-k) / max(_2267, 0.0500000007450580596923828125);\n        }\n        else\n        {\n            _2277 = k;\n        }\n        radius = clamp(((max(zr - _2267, 0.0) * unit) * _2277) / texel_m, 1.5, 16.0);\n        dir = _2178;\n    }\n    float lit = 0.0;\n    int _2303 = (mode == 2) ? 24 : 16;\n    for (int i_1 = 0; i_1 < _2303; i_1++)\n    {\n        float _2322 = sqrt((float(i_1) + 0.5) / float(_2303)) * radius;\n        vec2 param_7 = uv + (dir * (fa_shadows[26].zw * _2322));\n        vec4 param_8 = rect;\n        vec3 param_9 = conv;\n        lit += float((zr - (_2322 * plane)) <= fa_shadow_fetch(param_7, param_8, param_9));\n        vec2 param_10 = dir;\n        dir = fa_shadow_vogel_turn(param_10);\n    }\n    return lit / float(_2303);\n}\n\nfloat fa_shadow_local(int li, vec3 lpos, vec3 world, vec3 n, vec3 l)\n{\n    bool _2527 = fa_mesh_fs_params[5].z < 0.5;\n    bool _2534;\n    if (!_2527)\n    {\n        _2534 = fa_shadows[29].x < 0.5;\n    }\n    else\n    {\n        _2534 = _2527;\n    }\n    if (_2534)\n    {\n        return 1.0;\n    }\n    int param = (int(fa_shadows[29].x + 0.5) - 1) + li;\n    vec4 _2547 = fa_light_texel(param);\n    float _2548 = _2547.x;\n    if (_2548 < 0.0)\n    {\n        return 1.0;\n    }\n    int _2557 = int(_2548 + 0.5);\n    int param_1 = _2557;\n    vec4 _2561 = fa_light_texel(param_1);\n    int param_2 = _2557 + 1;\n    vec4 _2566 = fa_light_texel(param_2);\n    float fade = 1.0;\n    float _2569 = _2561.y;\n    if (_2569 > 0.0)\n    {\n        float _2586 = 1.0 - smoothstep(0.75 * _2569, _2569, length(world - fa_shadows[27].xyz));\n        fade = _2586;\n        if (_2586 <= 0.0)\n        {\n            return 1.0;\n        }\n    }\n    int face = 0;\n    if (_2561.x > 1.5)\n    {\n        vec3 param_3 = world - lpos;\n        face = fa_cube_face(param_3);\n    }\n    int _2610 = (_2557 + 2) + (face * 6);\n    int param_4 = _2610;\n    int param_5 = _2610 + 1;\n    int param_6 = _2610 + 3;\n    vec4 _2624 = fa_light_texel(param_6);\n    int param_7 = _2610 + 4;\n    vec4 _2629 = fa_light_texel(param_7);\n    int param_8 = _2610 + 5;\n    vec4 _2634 = fa_light_texel(param_8);\n    float _2646 = _2634.x * max(dot(_2624, vec4(world, 1.0)), 0.001000000047497451305389404296875);\n    float _2651 = clamp(dot(n, l), 0.0, 1.0);\n    float _2674 = clamp(dot(n, _2624.xyz), -1.0, 1.0);\n    float _2693 = min(sqrt(1.0 - (_2674 * _2674)) / max(abs(dot(n, world - lpos)) / max(dot(_2624, vec4(world, 1.0)), 0.001000000047497451305389404296875), 0.20000000298023223876953125), 4.0);\n    float _2696 = _2566.y;\n    float _2698;\n    if (_2696 > 0.0)\n    {\n        _2698 = _2696;\n    }\n    else\n    {\n        _2698 = 1.5 * _2646;\n    }\n    vec4 _2718 = vec4(world + (n * (_2698 * sqrt(1.0 - (_2651 * _2651)))), 1.0);\n    float _2722 = dot(_2624, _2718);\n    float _2725 = _2634.y;\n    if (_2722 < _2725)\n    {\n        return 1.0;\n    }\n    vec2 _2740 = vec2(dot(fa_light_texel(param_4), _2718), dot(fa_light_texel(param_5), _2718)) / vec2(_2722);\n    float _2742 = _2740.x;\n    bool _2745 = _2742 < _2629.x;\n    bool _2754;\n    if (!_2745)\n    {\n        _2754 = _2742 > _2629.z;\n    }\n    else\n    {\n        _2754 = _2745;\n    }\n    bool _2763;\n    if (!_2754)\n    {\n        _2763 = _2740.y < _2629.y;\n    }\n    else\n    {\n        _2763 = _2754;\n    }\n    bool _2772;\n    if (!_2763)\n    {\n        _2772 = _2740.y > _2629.w;\n    }\n    else\n    {\n        _2772 = _2763;\n    }\n    if (_2772)\n    {\n        return 1.0;\n    }\n    float _2778 = _2566.x;\n    float _2780;\n    if (_2778 > 0.0)\n    {\n        _2780 = _2778;\n    }\n    else\n    {\n        _2780 = 1.5 * _2646;\n    }\n    vec2 param_9 = _2740;\n    vec4 param_10 = _2629;\n    float param_11 = _2722 - (_2780 * (1.0 + (0.5 * _2693)));\n    float param_12 = _2646;\n    float param_13 = 1.0;\n    float param_14 = _2634.z * 0.25;\n    float param_15 = (_2646 * min(_2693, 3.0)) * 0.5;\n    vec3 param_16 = vec3(1.0, _2725, _2634.z);\n    int param_17 = int(_2561.z + 0.5);\n    float param_18 = _2561.w;\n    return mix(1.0, fa_shadow_filter(param_9, param_10, param_11, param_12, param_13, param_14, param_15, param_16, param_17, param_18), fade);\n}\n\nfloat fa_shadow_local_rt(int li, vec3 lpos, vec3 world, vec3 n, vec3 l)\n{\n    bool _3287 = fa_mesh_fs_params[25].w > 0.5;\n    bool _3293;\n    if (_3287)\n    {\n        _3293 = fa_mesh_fs_params[5].z > 0.5;\n    }\n    else\n    {\n        _3293 = _3287;\n    }\n    bool _3299;\n    if (_3293)\n    {\n        _3299 = fa_shadows[29].x > 0.5;\n    }\n    else\n    {\n        _3299 = _3293;\n    }\n    if (_3299)\n    {\n        int param = (int(fa_shadows[29].x + 0.5) - 1) + li;\n        vec4 _3311 = fa_light_texel(param);\n        float _3312 = _3311.z;\n        if (_3312 > 0.5)\n        {\n            float _3325 = dot(fa_mesh_fs_params[29].xyz, world) + fa_mesh_fs_params[29].w;\n            float _3331 = ((0.00200000009499490261077880859375 * _3325) + 0.00999999977648258209228515625) + fa_rt_slope;\n            vec4 _3337 = vec4(world, 1.0);\n            float _3342 = dot(fa_mesh_fs_params[28], _3337);\n            if (_3342 > 9.9999997473787516355514526367188e-05)\n            {\n                vec2 _3359 = vec2(dot(fa_mesh_fs_params[26], _3337), dot(fa_mesh_fs_params[27], _3337)) / vec2(_3342);\n                float _3364 = (_3359.x * 0.5) + 0.5;\n                float _3368;\n                if (fa_mesh_fs_params[24].y > 0.5)\n                {\n                    _3368 = (_3359.y * 0.5) + 0.5;\n                }\n                else\n                {\n                    _3368 = 0.5 - (_3359.y * 0.5);\n                }\n                bool _3384 = _3364 >= 0.0;\n                bool _3390;\n                if (_3384)\n                {\n                    _3390 = _3364 < 1.0;\n                }\n                else\n                {\n                    _3390 = _3384;\n                }\n                bool _3396;\n                if (_3390)\n                {\n                    _3396 = _3368 >= 0.0;\n                }\n                else\n                {\n                    _3396 = _3390;\n                }\n                bool _3402;\n                if (_3396)\n                {\n                    _3402 = _3368 < 1.0;\n                }\n                else\n                {\n                    _3402 = _3396;\n                }\n                if (_3402)\n                {\n                    ivec2 _3419 = ivec2(fa_mesh_fs_params[24].zw) - ivec2(1);\n                    ivec2 _3420 = clamp(ivec2(vec2(_3364, _3368) * fa_mesh_fs_params[24].zw), ivec2(0), _3419);\n                    float _3424;\n                    if (_3312 < 1.5)\n                    {\n                        _3424 = 1.0;\n                    }\n                    else\n                    {\n                        _3424 = (_3312 < 2.5) ? 256.0 : 65536.0;\n                    }\n                    float best = 2.0;\n                    int _3446;\n                    int _3452;\n                    for (int k = 0; k < 9; k++)\n                    {\n                        if (k == 0)\n                        {\n                            _3446 = 4;\n                        }\n                        else\n                        {\n                            if (k <= 4)\n                            {\n                                _3452 = k - 1;\n                            }\n                            else\n                            {\n                                _3452 = k;\n                            }\n                            _3446 = _3452;\n                        }\n                        vec4 _3481 = texelFetch(fa_screen_tex_fa_shadow_smp, clamp(_3420 + ivec2((_3446 % 3) - 1, (_3446 / 3) - 1), ivec2(0), _3419), 0);\n                        bool _3484 = _3481.w > 0.5;\n                        bool _3494;\n                        if (_3484)\n                        {\n                            _3494 = abs(_3325 - _3481.x) <= _3331;\n                        }\n                        else\n                        {\n                            _3494 = _3484;\n                        }\n                        if (_3494)\n                        {\n                            best = min(best, mod(floor(_3481.z / _3424), 256.0) * 0.0039215688593685626983642578125);\n                            if (k == 0)\n                            {\n                                break;\n                            }\n                        }\n                    }\n                    if (best <= 1.0)\n                    {\n                        float _3521;\n                        if (fa_mesh_fs_params[25].z > 0.5)\n                        {\n                            int param_1 = li;\n                            vec3 param_2 = lpos;\n                            vec3 param_3 = world;\n                            vec3 param_4 = n;\n                            vec3 param_5 = l;\n                            _3521 = min(best, fa_shadow_local(param_1, param_2, param_3, param_4, param_5));\n                        }\n                        else\n                        {\n                            _3521 = best;\n                        }\n                        return _3521;\n                    }\n                }\n            }\n            float _3544;\n            if (fa_mesh_fs_params[25].z > 0.5)\n            {\n                int param_6 = li;\n                vec3 param_7 = lpos;\n                vec3 param_8 = world;\n                vec3 param_9 = n;\n                vec3 param_10 = l;\n                _3544 = fa_shadow_local(param_6, param_7, param_8, param_9, param_10);\n            }\n            else\n            {\n                _3544 = 1.0;\n            }\n            return _3544;\n        }\n    }\n    int param_11 = li;\n    vec3 param_12 = lpos;\n    vec3 param_13 = world;\n    vec3 param_14 = n;\n    vec3 param_15 = l;\n    return fa_shadow_local(param_11, param_12, param_13, param_14, param_15);\n}\n\nfloat fa_shadow_split_at(int i)\n{\n    float _2065;\n    if (i == 0)\n    {\n        _2065 = fa_shadows[24].x;\n    }\n    else\n    {\n        float _2081;\n        if (i == 1)\n        {\n            _2081 = fa_shadows[24].y;\n        }\n        else\n        {\n            float _2089;\n            if (i == 2)\n            {\n                _2089 = fa_shadows[24].z;\n            }\n            else\n            {\n                _2089 = fa_shadows[24].w;\n            }\n            _2081 = _2089;\n        }\n        _2065 = _2081;\n    }\n    return _2065;\n}\n\nfloat fa_shadow_cascade(int ci, vec3 world, vec3 n, vec3 l)\n{\n    float _2368 = max(fa_shadows[ci * 1 + 20].y, 0.001000000047497451305389404296875);\n    float _2373 = clamp(dot(n, l), 0.0, 1.0);\n    float _2379 = sqrt(1.0 - (_2373 * _2373));\n    float _2387 = min(_2379 / max(_2373, 0.20000000298023223876953125), 4.0);\n    float _2392;\n    if (fa_shadows[26].y > 0.0)\n    {\n        _2392 = fa_shadows[26].y;\n    }\n    else\n    {\n        _2392 = 1.5 * fa_shadows[ci * 1 + 20].x;\n    }\n    vec4 _2417 = mat4(fa_shadows[ci * 4 + 0], fa_shadows[ci * 4 + 1], fa_shadows[ci * 4 + 2], fa_shadows[ci * 4 + 3]) * vec4(world + (n * (_2392 * _2379)), 1.0);\n    float _2424 = _2417.x;\n    bool _2427 = _2424 < fa_shadows[ci * 1 + 16].x;\n    bool _2436;\n    if (!_2427)\n    {\n        _2436 = _2424 > fa_shadows[ci * 1 + 16].z;\n    }\n    else\n    {\n        _2436 = _2427;\n    }\n    bool _2445;\n    if (!_2436)\n    {\n        _2445 = _2417.y < fa_shadows[ci * 1 + 16].y;\n    }\n    else\n    {\n        _2445 = _2436;\n    }\n    bool _2454;\n    if (!_2445)\n    {\n        _2454 = _2417.y > fa_shadows[ci * 1 + 16].w;\n    }\n    else\n    {\n        _2454 = _2445;\n    }\n    bool _2461;\n    if (!_2454)\n    {\n        _2461 = _2417.z > 1.0;\n    }\n    else\n    {\n        _2461 = _2454;\n    }\n    if (_2461)\n    {\n        return -1.0;\n    }\n    float _2469;\n    if (fa_shadows[26].x > 0.0)\n    {\n        _2469 = fa_shadows[26].x;\n    }\n    else\n    {\n        _2469 = 1.5 * fa_shadows[ci * 1 + 20].x;\n    }\n    vec2 param = _2417.xy;\n    vec4 param_1 = fa_shadows[ci * 1 + 16];\n    float param_2 = _2417.z - ((_2469 * (1.0 + (0.5 * _2387))) / _2368);\n    float param_3 = fa_shadows[ci * 1 + 20].x;\n    float param_4 = _2368;\n    float param_5 = _2368 * 0.25;\n    float param_6 = ((fa_shadows[ci * 1 + 20].x * min(_2387, 3.0)) * 0.5) / _2368;\n    vec3 param_7 = vec3(0.0);\n    int param_8 = int(fa_shadows[25].z + 0.5);\n    float param_9 = fa_shadows[25].w;\n    return fa_shadow_filter(param, param_1, param_2, param_3, param_4, param_5, param_6, param_7, param_8, param_9);\n}\n\nfloat fa_shadow_sun(vec3 world, vec3 n, vec3 l)\n{\n    if (fa_mesh_fs_params[5].z < 0.5)\n    {\n        return 1.0;\n    }\n    int _2847 = int(fa_shadows[25].x + 0.5);\n    if (_2847 < 1)\n    {\n        return 1.0;\n    }\n    float _2862 = dot(world - fa_shadows[27].xyz, fa_shadows[28].xyz);\n    int param = _2847 - 1;\n    if (_2862 > fa_shadow_split_at(param))\n    {\n        return 1.0;\n    }\n    int ci = 0;\n    bool _2874 = _2847 > 1;\n    bool _2881;\n    if (_2874)\n    {\n        _2881 = _2862 > fa_shadows[24].x;\n    }\n    else\n    {\n        _2881 = _2874;\n    }\n    if (_2881)\n    {\n        ci = 1;\n    }\n    bool _2885 = _2847 > 2;\n    bool _2892;\n    if (_2885)\n    {\n        _2892 = _2862 > fa_shadows[24].y;\n    }\n    else\n    {\n        _2892 = _2885;\n    }\n    if (_2892)\n    {\n        ci = 2;\n    }\n    bool _2896 = _2847 > 3;\n    bool _2903;\n    if (_2896)\n    {\n        _2903 = _2862 > fa_shadows[24].z;\n    }\n    else\n    {\n        _2903 = _2896;\n    }\n    if (_2903)\n    {\n        ci = 3;\n    }\n    float s = -1.0;\n    float s2 = -1.0;\n    float t = 0.0;\n    int _2914 = min(_2847, 4);\n    float _2955;\n    for (int c = ci; c < _2914; c++)\n    {\n        int param_1 = c;\n        vec3 param_2 = world;\n        vec3 param_3 = n;\n        vec3 param_4 = l;\n        float _2934 = fa_shadow_cascade(param_1, param_2, param_3, param_4);\n        if (s >= 0.0)\n        {\n            s2 = _2934;\n            break;\n        }\n        if (_2934 < 0.0)\n        {\n            continue;\n        }\n        s = _2934;\n        ci = c;\n        if (fa_shadows[25].y > 0.0)\n        {\n            if (ci > 0)\n            {\n                int param_5 = ci - 1;\n                _2955 = fa_shadow_split_at(param_5);\n            }\n            else\n            {\n                _2955 = fa_shadows[28].w;\n            }\n            int param_6 = ci;\n            float _2974 = fa_shadows[25].y * max(fa_shadow_split_at(param_6) - _2955, 9.9999997473787516355514526367188e-05);\n            int param_7 = ci;\n            t = clamp((_2862 - (fa_shadow_split_at(param_7) - _2974)) / _2974, 0.0, 1.0);\n        }\n        if (t <= 0.0)\n        {\n            break;\n        }\n    }\n    if (s < 0.0)\n    {\n        return 1.0;\n    }\n    if (t > 0.0)\n    {\n        float _3006;\n        if ((ci + 1) < _2847)\n        {\n            _3006 = (s2 < 0.0) ? s : s2;\n        }\n        else\n        {\n            _3006 = 1.0;\n        }\n        s = mix(s, _3006, t);\n    }\n    return s;\n}\n\nfloat fa_shadow_factor(vec3 n, vec3 l)\n{\n    bool _3111 = fa_mesh_fs_params[25].y > 0.5;\n    bool _3117;\n    if (_3111)\n    {\n        _3117 = fa_mesh_fs_params[5].z > 0.5;\n    }\n    else\n    {\n        _3117 = _3111;\n    }\n    if (_3117)\n    {\n        float _3131 = dot(fa_mesh_fs_params[29].xyz, fa_world_pos) + fa_mesh_fs_params[29].w;\n        vec4 _3139 = vec4(fa_world_pos, 1.0);\n        float _3145 = dot(fa_mesh_fs_params[28], _3139);\n        if (_3145 > 9.9999997473787516355514526367188e-05)\n        {\n            vec2 _3164 = vec2(dot(fa_mesh_fs_params[26], _3139), dot(fa_mesh_fs_params[27], _3139)) / vec2(_3145);\n            float _3169 = (_3164.x * 0.5) + 0.5;\n            float _3173;\n            if (fa_mesh_fs_params[24].y > 0.5)\n            {\n                _3173 = (_3164.y * 0.5) + 0.5;\n            }\n            else\n            {\n                _3173 = 0.5 - (_3164.y * 0.5);\n            }\n            bool _3189 = _3169 >= 0.0;\n            bool _3195;\n            if (_3189)\n            {\n                _3195 = _3169 < 1.0;\n            }\n            else\n            {\n                _3195 = _3189;\n            }\n            bool _3201;\n            if (_3195)\n            {\n                _3201 = _3173 >= 0.0;\n            }\n            else\n            {\n                _3201 = _3195;\n            }\n            bool _3207;\n            if (_3201)\n            {\n                _3207 = _3173 < 1.0;\n            }\n            else\n            {\n                _3207 = _3201;\n            }\n            if (_3207)\n            {\n                vec4 _3233 = texelFetch(fa_screen_tex_fa_shadow_smp, clamp(ivec2(vec2(_3169, _3173) * fa_mesh_fs_params[24].zw), ivec2(0), ivec2(fa_mesh_fs_params[24].zw) - ivec2(1)), 0);\n                bool _3236 = _3233.w > 0.5;\n                bool _3252;\n                if (_3236)\n                {\n                    _3252 = abs(_3131 - _3233.x) <= (((0.00200000009499490261077880859375 * _3131) + 0.00999999977648258209228515625) + fa_rt_slope);\n                }\n                else\n                {\n                    _3252 = _3236;\n                }\n                if (_3252)\n                {\n                    float _3258;\n                    if (fa_mesh_fs_params[25].z > 0.5)\n                    {\n                        vec3 param = fa_world_pos;\n                        vec3 param_1 = n;\n                        vec3 param_2 = l;\n                        _3258 = min(_3233.y, fa_shadow_sun(param, param_1, param_2));\n                    }\n                    else\n                    {\n                        _3258 = _3233.y;\n                    }\n                    return _3258;\n                }\n            }\n        }\n    }\n    vec3 param_3 = fa_world_pos;\n    vec3 param_4 = n;\n    vec3 param_5 = l;\n    return fa_shadow_sun(param_3, param_4, param_5);\n}\n\nfloat fa_contact_shadow(int li, vec3 world, vec3 gn, vec3 l, float dist)\n{\n    bool _3914 = fa_mesh_fs_params[24].x < 0.5;\n    bool _3921;\n    if (!_3914)\n    {\n        _3921 = fa_shadows[29].x < 0.5;\n    }\n    else\n    {\n        _3921 = _3914;\n    }\n    if (_3921)\n    {\n        return 1.0;\n    }\n    int param = (int(fa_shadows[29].x + 0.5) - 1) + li;\n    vec4 _3934 = fa_light_texel(param);\n    float _3935 = _3934.y;\n    float len = _3935;\n    if (_3935 <= 0.0)\n    {\n        return 1.0;\n    }\n    float _3947 = length(world - fa_mesh_fs_params[0].xyz);\n    float _3956 = 1.0 - smoothstep(0.5 * fa_mesh_fs_params[25].x, fa_mesh_fs_params[25].x, _3947);\n    if (_3956 <= 0.0)\n    {\n        return 1.0;\n    }\n    float _3962 = len;\n    float _3965 = min(_3962, 0.89999997615814208984375 * dist);\n    len = _3965;\n    float _3971 = 0.004999999888241291046142578125 + (0.0030000000260770320892333984375 * _3947);\n    float _3976 = _3971 + (0.5 * _3965);\n    vec3 _3982 = world + (gn * _3971);\n    float _3984 = fa_shadow_noise();\n    float occ = 0.0;\n    float _4046;\n    for (int k = 0; k < 12; k++)\n    {\n        float _4000 = (float(k) + _3984) * 0.083333335816860198974609375;\n        vec3 _4008 = _3982 + (l * (_4000 * len));\n        vec4 _4014 = vec4(_4008, 1.0);\n        float _4019 = dot(fa_mesh_fs_params[28], _4014);\n        if (_4019 < 9.9999997473787516355514526367188e-05)\n        {\n            break;\n        }\n        vec2 _4037 = vec2(dot(fa_mesh_fs_params[26], _4014), dot(fa_mesh_fs_params[27], _4014)) / vec2(_4019);\n        float _4041 = _4037.x * 0.5;\n        float _4042 = _4041 + 0.5;\n        if (fa_mesh_fs_params[24].y > 0.5)\n        {\n            _4046 = (_4037.y * 0.5) + 0.5;\n        }\n        else\n        {\n            _4046 = 0.5 - (_4037.y * 0.5);\n        }\n        bool _4062 = _4042 < 0.0;\n        bool _4069;\n        if (!_4062)\n        {\n            _4069 = _4042 >= 1.0;\n        }\n        else\n        {\n            _4069 = _4062;\n        }\n        bool _4076;\n        if (!_4069)\n        {\n            _4076 = _4046 < 0.0;\n        }\n        else\n        {\n            _4076 = _4069;\n        }\n        bool _4083;\n        if (!_4076)\n        {\n            _4083 = _4046 >= 1.0;\n        }\n        else\n        {\n            _4083 = _4076;\n        }\n        if (_4083)\n        {\n            break;\n        }\n        vec4 _4107 = texelFetch(fa_screen_tex_fa_shadow_smp, clamp(ivec2(vec2(_4042, _4046) * fa_mesh_fs_params[24].zw), ivec2(0), ivec2(fa_mesh_fs_params[24].zw) - ivec2(1)), 0);\n        if (_4107.w < 0.5)\n        {\n            continue;\n        }\n        float _4125 = (dot(fa_mesh_fs_params[29].xyz, _4008) + fa_mesh_fs_params[29].w) - _4107.x;\n        if ((_4125 > _3971) && (_4125 < _3976))\n        {\n            occ = max(occ, (1.0 - (_4000 * _4000)) * smoothstep(0.0, 0.0500000007450580596923828125, min(min(_4042, 0.5 - _4041), min(_4046, 1.0 - _4046))));\n        }\n    }\n    return 1.0 - (occ * _3956);\n}\n\nLightSample fa_light_shadowed(int li, vec3 world_pos, vec3 gn)\n{\n    int param = li;\n    float _4257 = fa_baked_keep(param);\n    if (_4257 <= 0.0)\n    {\n        int param_1 = li;\n        return LightSample(vec3(0.0, 1.0, 0.0), vec3(0.0), 0.0, 1.0, 0.0, int(fa_light_type(param_1) + 0.5));\n    }\n    int param_2 = li;\n    vec3 param_3 = world_pos;\n    vec3 param_4 = gn;\n    LightSample _4283 = fa_light_sample_n(param_2, param_3, param_4);\n    vec3 _6148 = _4283.color;\n    float _6149 = _4283.attenuation;\n    float _6150 = _4283.shadow;\n    bool _4286 = _4283.type == 0;\n    if (_4286 && (li == 0))\n    {\n        vec3 param_5 = gn;\n        vec3 param_6 = _4283.direction;\n        float _4297 = fa_shadow_factor(param_5, param_6);\n        _6150 = _4297;\n        _6148 *= _4297;\n    }\n    else\n    {\n        bool _4308 = _4283.type != 0;\n        bool _4314;\n        if (_4308)\n        {\n            _4314 = _6149 > 0.0;\n        }\n        else\n        {\n            _4314 = _4308;\n        }\n        if (_4314)\n        {\n            int param_7 = li;\n            int param_8 = fa_light_base(param_7);\n            int param_9 = li;\n            vec3 param_10 = fa_light_texel(param_8).xyz;\n            vec3 param_11 = world_pos;\n            vec3 param_12 = gn;\n            vec3 param_13 = _4283.direction;\n            float _4333 = fa_shadow_local_rt(param_9, param_10, param_11, param_12, param_13);\n            _6150 = _4333;\n            _6148 *= _4333;\n        }\n    }\n    bool _4343 = fa_mesh_fs_params[24].x > 0.5;\n    bool _4349;\n    if (_4343)\n    {\n        _4349 = _6149 > 0.0;\n    }\n    else\n    {\n        _4349 = _4343;\n    }\n    if (_4349)\n    {\n        float _4356;\n        if (_4286)\n        {\n            _4356 = 1000000000.0;\n        }\n        else\n        {\n            _4356 = _4283._distance;\n        }\n        int param_14 = li;\n        vec3 param_15 = world_pos;\n        vec3 param_16 = gn;\n        vec3 param_17 = _4283.direction;\n        float param_18 = _4356;\n        float _4374 = fa_contact_shadow(param_14, param_15, param_16, param_17, param_18);\n        _6150 *= _4374;\n        _6148 *= _4374;\n    }\n    float _4387 = _6149;\n    float _4388 = _4387 * _4257;\n    _6149 = _4388;\n    vec3 _4392 = _6148;\n    vec3 _4393 = _4392 * _4257;\n    _6148 = _4393;\n    return LightSample(_4283.direction, _4393, _4388, _6150, _4283._distance, _4283.type);\n}\n\nvec3 light(SurfaceInput i, Surface s, LightSample l)\n{\n    return vec3(0.0);\n}\n\nvec3 fa_shadow_debug(vec3 color, vec3 world)\n{\n    if (fa_shadows[27].w < 0.5)\n    {\n        return color;\n    }\n    int _3034 = int(fa_shadows[25].x + 0.5);\n    float _3044 = dot(world - fa_shadows[27].xyz, fa_shadows[28].xyz);\n    vec3 tint = vec3(0.3499999940395355224609375);\n    bool _3049 = _3034 > 0;\n    bool _3058;\n    if (_3049)\n    {\n        int param = _3034 - 1;\n        _3058 = _3044 <= fa_shadow_split_at(param);\n    }\n    else\n    {\n        _3058 = _3049;\n    }\n    if (_3058)\n    {\n        tint = vec3(1.0, 0.1500000059604644775390625, 0.100000001490116119384765625);\n        bool _3064 = _3034 > 1;\n        bool _3071;\n        if (_3064)\n        {\n            _3071 = _3044 > fa_shadows[24].x;\n        }\n        else\n        {\n            _3071 = _3064;\n        }\n        if (_3071)\n        {\n            tint = vec3(0.100000001490116119384765625, 0.89999997615814208984375, 0.20000000298023223876953125);\n        }\n        bool _3077 = _3034 > 2;\n        bool _3084;\n        if (_3077)\n        {\n            _3084 = _3044 > fa_shadows[24].y;\n        }\n        else\n        {\n            _3084 = _3077;\n        }\n        if (_3084)\n        {\n            tint = vec3(0.1500000059604644775390625, 0.300000011920928955078125, 1.0);\n        }\n        bool _3090 = _3034 > 3;\n        bool _3097;\n        if (_3090)\n        {\n            _3097 = _3044 > fa_shadows[24].z;\n        }\n        else\n        {\n            _3097 = _3090;\n        }\n        if (_3097)\n        {\n            tint = vec3(1.0, 0.89999997615814208984375, 0.100000001490116119384765625);\n        }\n    }\n    return mix(color, tint, vec3(0.550000011920928955078125));\n}\n\nvoid main()\n{\n    fa_rt_slope = 0.0;\n    fa_inst_load();\n    vec3 _5969 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _5969 = -_5969;\n    }\n    vec3 _5543 = normalize(fa_mesh_fs_params[0].xyz - fa_world_pos);\n    vec3 param = fa_world_pos;\n    fa_cluster_begin(param);\n    SurfaceInput param_1 = SurfaceInput(fa_world_pos, _5969, fa_world_tangent, fa_uv, fa_vertex_color, _5543, gl_FrontFacing);\n    Surface _5551 = fa_standard_surface(param_1);\n    vec3 _6000 = _5551.albedo;\n    float _6001 = _5551.alpha;\n    vec3 _6002 = _5551.normal;\n    float _6003 = _5551.metallic;\n    float _6004 = _5551.roughness;\n    float _6005 = _5551.occlusion;\n    vec3 _6006 = _5551.emission;\n    float _6007 = _5551.clearcoat;\n    float _6008 = _5551.clearcoat_roughness;\n    vec3 _6009 = _5551.sheen_color;\n    float _6010 = _5551.sheen_roughness;\n    float _6011 = _5551.anisotropy;\n    float _6012 = _5551.anisotropy_rotation;\n    float _6013 = _5551.specular;\n    float _6014 = _5551.ior;\n    vec3 _6015 = _5551.specular_color;\n    float _6016 = _5551.transmission;\n    float _6017 = _5551.thickness;\n    vec3 _6018 = _5551.attenuation_color;\n    float _6019 = _5551.attenuation_distance;\n    SurfaceInput param_2 = SurfaceInput(fa_world_pos, _5969, fa_world_tangent, fa_uv, fa_vertex_color, _5543, gl_FrontFacing);\n    Surface param_3 = _5551;\n    surface(param_2, param_3);\n    _6000 = param_3.albedo;\n    _6001 = param_3.alpha;\n    _6002 = param_3.normal;\n    _6003 = param_3.metallic;\n    _6004 = param_3.roughness;\n    _6005 = param_3.occlusion;\n    _6006 = param_3.emission;\n    _6007 = param_3.clearcoat;\n    _6008 = param_3.clearcoat_roughness;\n    _6009 = param_3.sheen_color;\n    _6010 = param_3.sheen_roughness;\n    _6011 = param_3.anisotropy;\n    _6012 = param_3.anisotropy_rotation;\n    _6013 = param_3.specular;\n    _6014 = param_3.ior;\n    _6015 = param_3.specular_color;\n    _6016 = param_3.transmission;\n    _6017 = param_3.thickness;\n    _6018 = param_3.attenuation_color;\n    _6019 = param_3.attenuation_distance;\n    vec3 param_4 = fa_world_pos;\n    vec3 param_5 = _5969;\n    vec3 param_6 = param_3.albedo;\n    vec3 param_7 = param_3.normal;\n    fa_apply_decals(param_4, param_5, param_6, param_7);\n    _6000 = param_6;\n    _6002 = param_7;\n    vec3 result;\n    if (fa_mesh_fs_params[3].w > 0.5)\n    {\n        result = _6000;\n    }\n    else\n    {\n        vec3 _5590 = _6002;\n        vec3 _5591 = normalize(_5590);\n        _6002 = _5591;\n        vec3 param_8 = _5591;\n        vec3 lit = (fa_indirect_diffuse(param_8) * _6000) * _6005;\n        int _5610 = fa_cl_ndir + fa_cl_local;\n        for (int ln = 0; ln < _5610; ln++)\n        {\n            int param_9 = ln;\n            int _5623 = fa_cl_light(param_9);\n            int param_10 = _5623;\n            if (fa_baked_keep(param_10) <= 0.0)\n            {\n                continue;\n            }\n            int param_11 = _5623;\n            vec3 param_12 = fa_world_pos;\n            vec3 param_13 = _5969;\n            LightSample _5639 = fa_light_shadowed(param_11, param_12, param_13);\n            SurfaceInput param_14 = SurfaceInput(fa_world_pos, _5969, fa_world_tangent, fa_uv, fa_vertex_color, _5543, gl_FrontFacing);\n            Surface param_15 = Surface(_6000, _6001, _6002, _6003, _6004, _6005, _6006, _6007, _6008, _6009, _6010, _6011, _6012, _6013, _6014, _6015, _6016, _6017, _6018, _6019);\n            LightSample param_16 = _5639;\n            lit += light(param_14, param_15, param_16);\n        }\n        result = lit;\n    }\n    vec3 _5654 = result;\n    vec3 _5655 = _5654 + _6006;\n    result = _5655;\n    vec3 param_17 = _5655;\n    vec3 param_18 = fa_world_pos;\n    result = fa_shadow_debug(param_17, param_18);\n    bool _5664 = fa_mesh_fs_params[7].w > 0.0;\n    bool _5671;\n    if (!_5664)\n    {\n        _5671 = fa_mesh_fs_params[8].y > 0.0;\n    }\n    else\n    {\n        _5671 = _5664;\n    }\n    if (_5671)\n    {\n        vec3 _5680 = fa_world_pos - fa_mesh_fs_params[0].xyz;\n        float _5686 = dot(_5680, fa_mesh_fs_params[9].xyz);\n        bool _5690 = fa_mesh_fs_params[9].w > 0.5;\n        float _5691;\n        if (_5690)\n        {\n            _5691 = _5686;\n        }\n        else\n        {\n            _5691 = length(_5680);\n        }\n        float _5703 = _5691 - fa_mesh_fs_params[8].x;\n        if (_5703 > 0.0)\n        {\n            float _5712 = fa_mesh_fs_params[7].w * _5703;\n            float tau = _5712 * _5712;\n            if (fa_mesh_fs_params[8].y > 0.0)\n            {\n                float _5728;\n                if (_5690)\n                {\n                    _5728 = fa_world_pos.y - (fa_mesh_fs_params[9].y * _5686);\n                }\n                else\n                {\n                    _5728 = fa_mesh_fs_params[0].y;\n                }\n                float _5749 = mix(_5728, fa_world_pos.y, clamp(fa_mesh_fs_params[8].x / _5691, 0.0, 1.0));\n                float _5753 = fa_world_pos.y - _5749;\n                float _5758 = _5749 - fa_mesh_fs_params[8].z;\n                float _5763 = fa_world_pos.y - fa_mesh_fs_params[8].z;\n                bool _5766 = _5758 <= 0.0;\n                bool _5767 = !_5766;\n                bool _5773;\n                if (_5767)\n                {\n                    _5773 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _5773 = _5766;\n                }\n                float _5774;\n                if (_5773)\n                {\n                    _5774 = fa_mesh_fs_params[8].y;\n                }\n                else\n                {\n                    _5774 = fa_mesh_fs_params[8].y * exp(-min(fa_mesh_fs_params[8].w * _5758, 80.0));\n                }\n                bool _5801;\n                if (_5767)\n                {\n                    _5801 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _5801 = _5766;\n                }\n                float _5802;\n                if (_5801)\n                {\n                    _5802 = fa_mesh_fs_params[8].y * _5758;\n                }\n                else\n                {\n                    _5802 = (fa_mesh_fs_params[8].y * (1.0 - exp(-min(fa_mesh_fs_params[8].w * _5758, 80.0)))) / fa_mesh_fs_params[8].w;\n                }\n                bool _5827 = _5763 <= 0.0;\n                bool _5834;\n                if (!_5827)\n                {\n                    _5834 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _5834 = _5827;\n                }\n                float _5835;\n                if (_5834)\n                {\n                    _5835 = fa_mesh_fs_params[8].y * _5763;\n                }\n                else\n                {\n                    _5835 = (fa_mesh_fs_params[8].y * (1.0 - exp(-min(fa_mesh_fs_params[8].w * _5763, 80.0)))) / fa_mesh_fs_params[8].w;\n                }\n                float _5862;\n                if (abs(_5753) < 0.001000000047497451305389404296875)\n                {\n                    _5862 = _5774;\n                }\n                else\n                {\n                    _5862 = (_5835 - _5802) / _5753;\n                }\n                tau += (_5703 * max(_5862, 0.0));\n            }\n            result = mix(result, fa_mesh_fs_params[7].xyz, vec3(clamp(1.0 - exp(-clamp(tau, 0.0, 80.0)), 0.0, 1.0)));\n        }\n    }\n    fa_frag_color = vec4(result, _6001);\n}\n\n",
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
            "inst_name": "_423",
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
            "inst_name": "_2075",
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
      "vs": "#version 430\n\nstruct VertexData\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 color;\n    vec3 object_pos;\n};\n\nuniform vec4 fa_mesh_vs_params[11];\nuniform vec4 fa_skin[192];\nlayout(location = 0) out vec3 fa_world_pos;\nlayout(location = 1) out vec3 fa_world_normal;\nlayout(location = 2) out vec4 fa_world_tangent;\nlayout(location = 3) out vec2 fa_uv;\nlayout(location = 4) out vec4 fa_vertex_color;\nlayout(location = 5) in vec4 fa_inst_m0;\nlayout(location = 6) in vec4 fa_inst_m1;\nlayout(location = 7) in vec4 fa_inst_m2;\nlayout(location = 8) in vec4 fa_inst_m3;\nlayout(location = 9) in vec4 fa_joints;\nlayout(location = 10) in vec4 fa_weights;\nlayout(location = 0) in vec3 fa_position;\nlayout(location = 1) in vec3 fa_normal;\nlayout(location = 3) in vec4 fa_tangent;\nlayout(location = 2) in vec2 fa_texcoord0;\nlayout(location = 4) in vec4 fa_color;\nlayout(location = 5) out vec3 fa_lm;\n\nvoid fa_inst_begin()\n{\n}\n\nmat4 fa_skin_matrix(vec4 joints, vec4 weights)\n{\n    vec4 r0 = vec4(0.0);\n    vec4 r1 = vec4(0.0);\n    vec4 r2 = vec4(0.0);\n    for (int i = 0; i < 4; i++)\n    {\n        int _174 = int((joints[i] * 255.0) + 0.5) * 3;\n        r0 += (fa_skin[_174 * 1 + 0] * weights[i]);\n        r1 += (fa_skin[(_174 + 1) * 1 + 0] * weights[i]);\n        r2 += (fa_skin[(_174 + 2) * 1 + 0] * weights[i]);\n    }\n    return mat4(vec4(r0.x, r1.x, r2.x, 0.0), vec4(r0.y, r1.y, r2.y, 0.0), vec4(r0.z, r1.z, r2.z, 0.0), vec4(r0.w, r1.w, r2.w, 1.0));\n}\n\nVertexData fa_vertex_data(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    vec3 _74 = cross(model[1].xyz, model[2].xyz);\n    float _80 = (dot(model[0].xyz, _74) < 0.0) ? (-1.0) : 1.0;\n    return VertexData((model * vec4(position, 1.0)).xyz, (((_74 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _80, vec4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _80), texcoord0 * fa_mesh_vs_params[8].xy, color, position);\n}\n\nvoid fa_shade_vertex(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    mat4 param = model;\n    vec3 param_1 = position;\n    vec3 param_2 = normal;\n    vec4 param_3 = tangent;\n    vec2 param_4 = texcoord0;\n    vec4 param_5 = color;\n    VertexData _273 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    vec3 _388 = _273.world_pos;\n    fa_world_pos = _388;\n    fa_world_normal = _273.world_normal;\n    fa_world_tangent = _273.world_tangent;\n    fa_uv = _273.uv;\n    fa_vertex_color = _273.color;\n    gl_Position = mat4(fa_mesh_vs_params[0], fa_mesh_vs_params[1], fa_mesh_vs_params[2], fa_mesh_vs_params[3]) * vec4(_388, 1.0);\n}\n\nvoid main()\n{\n    fa_inst_begin();\n    vec4 param = fa_joints;\n    vec4 param_1 = fa_weights;\n    mat4 param_2 = mat4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3) * fa_skin_matrix(param, param_1);\n    vec3 param_3 = fa_position;\n    vec3 param_4 = fa_normal;\n    vec4 param_5 = fa_tangent;\n    vec2 param_6 = fa_texcoord0;\n    vec4 param_7 = fa_color;\n    fa_shade_vertex(param_2, param_3, param_4, param_5, param_6, param_7);\n    fa_lm = vec3(0.0);\n}\n\n",
      "fs": "#version 430\n\nstruct SurfaceInput\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 vertex_color;\n    vec3 view_dir;\n    bool front_facing;\n};\n\nstruct LightSample\n{\n    vec3 direction;\n    vec3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct Surface\n{\n    vec3 albedo;\n    float alpha;\n    vec3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    vec3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    vec3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    vec3 specular_color;\n    float transmission;\n    float thickness;\n    vec3 attenuation_color;\n    float attenuation_distance;\n};\n\nuniform vec4 fa_mesh_fs_params[54];\nuniform vec4 fa_shadows[30];\nlayout(binding = 0) uniform sampler2D fa_light_tex_fa_shadow_smp;\nlayout(binding = 1) uniform sampler2D fa_tex_fa_smp;\nlayout(binding = 2) uniform sampler2D fa_normal_tex_fa_smp;\nlayout(binding = 3) uniform sampler2D fa_mr_tex_fa_smp;\nlayout(binding = 4) uniform sampler2D fa_occlusion_tex_fa_smp;\nlayout(binding = 5) uniform sampler2D fa_emissive_tex_fa_smp;\nlayout(binding = 6) uniform sampler2D fa_decal_tex_fa_env_smp;\nlayout(binding = 7) uniform sampler2D fa_lightmap_fa_env_smp;\nlayout(binding = 8) uniform sampler2D fa_probe_atlas_fa_env_smp;\nlayout(binding = 9) uniform sampler2D fa_light_atlas_fa_env_smp;\nlayout(binding = 10) uniform sampler2D fa_screen_tex_fa_shadow_smp;\nlayout(binding = 11) uniform sampler2D fa_shadow_tex_fa_shadow_smp;\n\nlayout(location = 0) in vec3 fa_world_pos;\nlayout(location = 5) in vec3 fa_lm;\nlayout(location = 1) in vec3 fa_world_normal;\nlayout(location = 2) in vec4 fa_world_tangent;\nlayout(location = 3) in vec2 fa_uv;\nlayout(location = 4) in vec4 fa_vertex_color;\nlayout(location = 0) out vec4 fa_frag_color;\nfloat fa_rt_slope;\nvec3 fa_light_tint;\nbool fa_light_is_area;\nint fa_cl_ndir;\nint fa_cl_slot;\nint fa_cl_local;\n\nvoid fa_inst_load()\n{\n}\n\nvec4 fa_light_texel(int t)\n{\n    return texelFetch(fa_light_tex_fa_shadow_smp, ivec2(t & 1023, t >> 10), 0);\n}\n\nvec4 fa_cluster_texel(vec3 world_pos)\n{\n    bool _1351 = fa_mesh_fs_params[19].x < 0.0;\n    bool _1358;\n    if (!_1351)\n    {\n        _1358 = fa_mesh_fs_params[19].w < 1.0;\n    }\n    else\n    {\n        _1358 = _1351;\n    }\n    bool _1366;\n    if (!_1358)\n    {\n        _1366 = fa_mesh_fs_params[18].x < 1.0;\n    }\n    else\n    {\n        _1366 = _1358;\n    }\n    bool _1373;\n    if (!_1366)\n    {\n        _1373 = fa_mesh_fs_params[18].y < 1.0;\n    }\n    else\n    {\n        _1373 = _1366;\n    }\n    bool _1380;\n    if (!_1373)\n    {\n        _1380 = fa_mesh_fs_params[19].y < 1.0;\n    }\n    else\n    {\n        _1380 = _1373;\n    }\n    if (_1380)\n    {\n        return vec4(0.0);\n    }\n    vec4 _1390 = vec4(world_pos, 1.0);\n    float _1396 = dot(fa_mesh_fs_params[16], _1390);\n    if (!(_1396 > 9.9999999747524270787835121154785e-07))\n    {\n        return vec4(0.0);\n    }\n    vec2 _1418 = vec2(dot(fa_mesh_fs_params[14], _1390), dot(fa_mesh_fs_params[15], _1390)) / vec2(_1396);\n    int _1422 = int(fa_mesh_fs_params[18].x);\n    int _1426 = int(fa_mesh_fs_params[18].y);\n    int param = (int(fa_mesh_fs_params[19].x) + (((clamp(int(floor(log2(max(dot(fa_mesh_fs_params[17].xyz, world_pos) + fa_mesh_fs_params[17].w, fa_mesh_fs_params[18].w) / fa_mesh_fs_params[18].w) * fa_mesh_fs_params[18].z)), 0, int(fa_mesh_fs_params[19].y) - 1) * _1426) + clamp(int(floor(((_1418.y * 0.5) + 0.5) * fa_mesh_fs_params[18].y)), 0, _1426 - 1)) * _1422)) + clamp(int(floor(((_1418.x * 0.5) + 0.5) * fa_mesh_fs_params[18].x)), 0, _1422 - 1);\n    return fa_light_texel(param);\n}\n\nivec2 fa_cluster_lookup(vec3 world_pos)\n{\n    vec3 param = world_pos;\n    vec4 _1502 = fa_cluster_texel(param);\n    return ivec2(int(_1502.x), int(_1502.y));\n}\n\nvoid fa_cluster_begin(vec3 world_pos)\n{\n    float _4202 = dot(fa_mesh_fs_params[29].xyz, world_pos) + fa_mesh_fs_params[29].w;\n    float _4205 = fwidth(_4202);\n    bool _4208 = fa_mesh_fs_params[25].y > 0.5;\n    bool _4215;\n    if (!_4208)\n    {\n        _4215 = fa_mesh_fs_params[25].w > 0.5;\n    }\n    else\n    {\n        _4215 = _4208;\n    }\n    if (_4215)\n    {\n        fa_rt_slope = min(1.5 * _4205, 0.100000001490116119384765625 * _4202);\n    }\n    fa_cl_ndir = int(fa_mesh_fs_params[19].z);\n    vec3 param = world_pos;\n    ivec2 _4231 = fa_cluster_lookup(param);\n    fa_cl_slot = _4231.x;\n    fa_cl_local = _4231.y;\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_linear_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvec3 fa_tex_fix(inout vec3 c, float mode)\n{\n    if (mode > 1.5)\n    {\n        vec3 param = c;\n        vec3 _4436 = fa_linear_to_srgb(param);\n        c = _4436;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            vec3 param_1 = c;\n            vec3 _4444 = fa_srgb_to_linear(param_1);\n            c = _4444;\n        }\n    }\n    return c;\n}\n\nvec3 fa_tangent_normal(SurfaceInput i, vec3 m)\n{\n    vec3 _306;\n    if (i.front_facing)\n    {\n        _306 = i.world_normal;\n    }\n    else\n    {\n        _306 = -i.world_normal;\n    }\n    vec3 _330 = normalize(i.world_tangent.xyz - (_306 * dot(_306, i.world_tangent.xyz)));\n    vec3 _357 = normalize(((_330 * m.x) + ((cross(_306, _330) * i.world_tangent.w) * m.y)) + (_306 * m.z));\n    vec3 _360;\n    if (i.front_facing)\n    {\n        _360 = _357;\n    }\n    else\n    {\n        _360 = -_357;\n    }\n    return _360;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    vec4 base_t = texture(fa_tex_fa_smp, i.uv, fa_mesh_fs_params[12].w);\n    float param = fa_mesh_fs_params[6].w;\n    float param_1 = 1.0;\n    vec3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    vec3 _4476 = fa_tex_fix(param_2, param_3);\n    vec4 _6352 = base_t;\n    _6352.x = _4476.x;\n    _6352.y = _4476.y;\n    _6352.z = _4476.z;\n    base_t = _6352;\n    vec4 _4490 = (_6352 * fa_mesh_fs_params[2]) * i.vertex_color;\n    vec3 _6168 = i.world_normal;\n    if (fa_mesh_fs_params[6].z > 0.5)\n    {\n        float param_4 = fa_mesh_fs_params[6].w;\n        float param_5 = 16.0;\n        vec3 param_6 = texture(fa_normal_tex_fa_smp, i.uv, fa_mesh_fs_params[12].w).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        vec3 _4524 = fa_tex_fix(param_6, param_7);\n        vec3 _4527 = (_4524 * 2.0) - vec3(1.0);\n        vec2 _4532 = _4527.xy * fa_mesh_fs_params[6].x;\n        vec3 _6360 = _4527;\n        _6360.x = _4532.x;\n        _6360.y = _4532.y;\n        SurfaceInput param_8 = i;\n        vec3 param_9 = _6360;\n        _6168 = fa_tangent_normal(param_8, param_9);\n    }\n    vec4 mrt = texture(fa_mr_tex_fa_smp, i.uv, fa_mesh_fs_params[12].w);\n    float param_10 = fa_mesh_fs_params[6].w;\n    float param_11 = 64.0;\n    vec3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    vec3 _4562 = fa_tex_fix(param_12, param_13);\n    vec4 _6363 = mrt;\n    _6363.x = _4562.x;\n    _6363.y = _4562.y;\n    _6363.z = _4562.z;\n    mrt = _6363;\n    vec4 _4592 = texture(fa_occlusion_tex_fa_smp, i.uv, fa_mesh_fs_params[12].w);\n    float param_14 = fa_mesh_fs_params[6].w;\n    float param_15 = 256.0;\n    vec3 param_16 = _4592.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    vec3 _4603 = fa_tex_fix(param_16, param_17);\n    float param_18 = fa_mesh_fs_params[6].w;\n    float param_19 = 4.0;\n    vec3 param_20 = texture(fa_emissive_tex_fa_smp, i.uv, fa_mesh_fs_params[12].w).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    vec3 _4635 = fa_tex_fix(param_20, param_21);\n    float _6173 = fa_mesh_fs_params[20].x;\n    float _6174 = fa_mesh_fs_params[20].y;\n    float _6177 = fa_mesh_fs_params[20].z;\n    float _6176 = fa_mesh_fs_params[21].w;\n    float _6179 = fa_mesh_fs_params[22].x;\n    if (fa_mesh_fs_params[22].z > 0.5)\n    {\n        if (mod(fa_mesh_fs_params[22].z, 2.0) > 0.5)\n        {\n            _6173 *= _4603.y;\n            _6174 *= _4603.z;\n            _6176 *= _4592.w;\n        }\n        if (fa_mesh_fs_params[22].z > 1.5)\n        {\n            _6177 *= mrt.x;\n            _6179 *= mrt.w;\n        }\n    }\n    return Surface(_4490.xyz, _4490.w, _6168, clamp(fa_mesh_fs_params[5].x * _4562.z, 0.0, 1.0), clamp(fa_mesh_fs_params[5].y * _4562.y, 0.0500000007450580596923828125, 1.0), 1.0 + (fa_mesh_fs_params[6].y * (_4603.x - 1.0)), fa_mesh_fs_params[3].xyz + (fa_mesh_fs_params[4].xyz * _4635), _6173, _6174, fa_mesh_fs_params[21].xyz, _6176, _6177, fa_mesh_fs_params[20].w, _6179, fa_mesh_fs_params[22].y, fa_mesh_fs_params[23].xyz, fa_mesh_fs_params[30].x, fa_mesh_fs_params[30].y, fa_mesh_fs_params[31].xyz, fa_mesh_fs_params[30].z);\n}\n\nvoid surface(SurfaceInput i, Surface s)\n{\n}\n\nvec4 fa_decal_tile(vec4 rect, vec2 uv, vec2 atlas, vec2 ddx, vec2 ddy)\n{\n    vec2 _1582 = rect.zw - rect.xy;\n    vec2 _1586 = _1582 * atlas;\n    vec2 _1590 = ddx * _1586;\n    vec2 _1594 = ddy * _1586;\n    return textureLod(fa_decal_tex_fa_env_smp, rect.xy + (clamp(uv, vec2(0.0), vec2(1.0)) * _1582), clamp(0.5 * log2(max(max(dot(_1590, _1590), dot(_1594, _1594)), 9.9999999392252902907785028219223e-09)), 0.0, 3.0));\n}\n\nvec3 fa_dc_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_dc_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvoid fa_apply_decals(vec3 world_pos, vec3 geo_normal, inout vec3 albedo, inout vec3 normal)\n{\n    bool _1627 = fa_mesh_fs_params[10].y < 0.5;\n    bool _1634;\n    if (!_1627)\n    {\n        _1634 = fa_mesh_fs_params[10].w < 0.5;\n    }\n    else\n    {\n        _1634 = _1627;\n    }\n    if (_1634)\n    {\n        return;\n    }\n    vec3 _1640 = dFdx(world_pos);\n    vec3 _1643 = dFdy(world_pos);\n    vec3 param = world_pos;\n    vec4 _1647 = fa_cluster_texel(param);\n    int _1651 = int(_1647.w);\n    if (_1651 < 1)\n    {\n        return;\n    }\n    int _1661 = int(fa_mesh_fs_params[10].y + 0.5);\n    int param_1 = _1661;\n    vec4 _1665 = fa_light_texel(param_1);\n    vec2 _1668 = _1665.yz;\n    int _1672 = int(_1665.w);\n    int param_2 = _1661 + 1;\n    vec4 _1677 = fa_light_texel(param_2);\n    float _1678 = _1677.x;\n    int _1684 = int(fa_mesh_fs_params[10].w + 0.5) - 1;\n    int _1688 = int(_1647.z);\n    vec3 _1953;\n    for (int k = 0; k < _1651; k++)\n    {\n        int _1701 = _1688 + k;\n        int param_3 = _1672 + (_1701 >> 2);\n        int _1718 = (_1661 + 2) + (int(fa_light_texel(param_3)[_1701 & 3]) * 7);\n        int param_4 = _1718 + 6;\n        vec4 _1723 = fa_light_texel(param_4);\n        if (((int(_1723.w + 0.5) >> _1684) & 1) == 0)\n        {\n            continue;\n        }\n        int param_5 = _1718;\n        vec4 _1738 = fa_light_texel(param_5);\n        int param_6 = _1718 + 1;\n        vec4 _1743 = fa_light_texel(param_6);\n        int param_7 = _1718 + 2;\n        vec4 _1748 = fa_light_texel(param_7);\n        vec3 _1751 = _1738.xyz;\n        float _1756 = dot(_1751, world_pos) + _1738.w;\n        vec3 _1758 = _1743.xyz;\n        float _1763 = dot(_1758, world_pos) + _1743.w;\n        vec3 _1765 = _1748.xyz;\n        float _1770 = dot(_1765, world_pos) + _1748.w;\n        bool _1775 = abs(_1756) > 0.5;\n        bool _1783;\n        if (!_1775)\n        {\n            _1783 = abs(_1763) > 0.5;\n        }\n        else\n        {\n            _1783 = _1775;\n        }\n        bool _1791;\n        if (!_1783)\n        {\n            _1791 = abs(_1770) > 0.5;\n        }\n        else\n        {\n            _1791 = _1783;\n        }\n        if (_1791)\n        {\n            continue;\n        }\n        float _1806 = clamp(dot(geo_normal, normalize(_1765)) * _1723.z, 0.0, 1.0);\n        if (_1806 <= 0.0)\n        {\n            continue;\n        }\n        float _1826 = (clamp((0.5 - abs(_1770)) * 10.0, 0.0, 1.0) * _1806) * _1723.x;\n        vec2 _1834 = vec2(_1756 + 0.5, 0.5 - _1763);\n        vec2 _1844 = vec2(dot(_1751, _1640), dot(_1758, _1640));\n        vec2 _1854 = vec2(dot(_1751, _1643), dot(_1758, _1643));\n        int param_8 = _1718 + 5;\n        vec4 _1859 = fa_light_texel(param_8);\n        int param_9 = _1718 + 3;\n        vec4 _1864 = fa_light_texel(param_9);\n        int param_10 = _1718 + 4;\n        vec4 _1869 = fa_light_texel(param_10);\n        float tex_a = 1.0;\n        vec3 col = _1859.xyz;\n        bool _1879 = _1864.z > _1864.x;\n        if (_1879)\n        {\n            vec4 param_11 = _1864;\n            vec2 param_12 = _1834;\n            vec2 param_13 = _1668;\n            vec2 param_14 = _1844;\n            vec2 param_15 = _1854;\n            vec4 tx = fa_decal_tile(param_11, param_12, param_13, param_14, param_15);\n            if ((_1678 > 0.5) && (_1678 < 1.5))\n            {\n                vec3 param_16 = tx.xyz;\n                vec3 _1905 = fa_dc_to_linear(param_16);\n                vec4 _6256 = tx;\n                _6256.x = _1905.x;\n                _6256.y = _1905.y;\n                _6256.z = _1905.z;\n                tx = _6256;\n            }\n            col *= tx.xyz;\n            tex_a = tx.w;\n        }\n        albedo = mix(albedo, col, vec3(clamp((_1826 * tex_a) * _1859.w, 0.0, 1.0)));\n        if (_1869.z > _1869.x)\n        {\n            vec4 param_17 = _1869;\n            vec2 param_18 = _1834;\n            vec2 param_19 = _1668;\n            vec2 param_20 = _1844;\n            vec2 param_21 = _1854;\n            vec4 _1949 = fa_decal_tile(param_17, param_18, param_19, param_20, param_21);\n            if (_1678 > 1.5)\n            {\n                vec3 param_22 = _1949.xyz;\n                vec3 _1959 = fa_dc_to_srgb(param_22);\n                _1953 = _1959;\n            }\n            else\n            {\n                _1953 = _1949.xyz;\n            }\n            vec3 _1968 = (_1953 * 2.0) - vec3(1.0);\n            vec2 _1973 = _1968.xy * _1723.y;\n            vec3 _1995 = (normalize(_1751) * _1973.x) + (normalize(_1758) * _1973.y);\n            vec3 _1998 = normalize(normal);\n            normal = normalize(mix(_1998, normalize((_1998 * max(_1968.z, 0.0500000007450580596923828125)) + (_1995 - (_1998 * dot(_1998, _1995)))), vec3(clamp(_1826 * (_1879 ? tex_a : 1.0), 0.0, 1.0))));\n        }\n    }\n}\n\nvec2 fa_atlas_size()\n{\n    return vec2(textureSize(fa_probe_atlas_fa_env_smp, 0));\n}\n\nvec3 fa_probe_sh_coef(vec2 origin, float res, int k)\n{\n    vec3 v = textureLod(fa_probe_atlas_fa_env_smp, (origin + vec2(float(k) + 0.5, res + 2.5)) / fa_atlas_size(), 0.0).xyz;\n    if (fa_mesh_fs_params[41].y > 0.5)\n    {\n        v = ((v * 255.0) - vec3(128.0)) * 0.03149606287479400634765625;\n    }\n    return v;\n}\n\nvec3 fa_sh_eval(vec3 c[9], vec3 n)\n{\n    vec3 _3666 = max((((c[0] * 0.2820948064327239990234375) + (((c[1] * (0.3257350027561187744140625 * n.y)) + (c[2] * (0.3257350027561187744140625 * n.z))) + (c[3] * (0.3257350027561187744140625 * n.x)))) + (((c[4] * ((0.2731371223926544189453125 * n.x) * n.y)) + (c[5] * ((0.2731371223926544189453125 * n.y) * n.z))) + (c[6] * (0.078847892582416534423828125 * (((3.0 * n.z) * n.z) - 1.0))))) + ((c[7] * ((0.2731371223926544189453125 * n.x) * n.z)) + (c[8] * (0.13656856119632720947265625 * ((n.x * n.x) - (n.y * n.y))))), vec3(0.0));\n    return _3666;\n}\n\nvec3 fa_ambient_light(vec3 n)\n{\n    float _3775 = (1.0 - fa_mesh_fs_params[42].w) - fa_mesh_fs_params[47].w;\n    vec3 amb = vec3(0.0);\n    bool _3781 = fa_mesh_fs_params[11].w > 0.5;\n    vec3 c[9];\n    for (int k = 0; k < 9; k++)\n    {\n        c[k] = vec3(0.0);\n    }\n    if (_3775 > 0.0005000000237487256526947021484375)\n    {\n        if (_3781)\n        {\n            for (int k_1 = 0; k_1 < 9; k_1++)\n            {\n                vec2 param = fa_mesh_fs_params[41].zw;\n                float param_1 = 128.0;\n                int param_2 = k_1;\n                c[k_1] = fa_probe_sh_coef(param, param_1, param_2) * _3775;\n            }\n        }\n        else\n        {\n            amb = fa_mesh_fs_params[1].xyz * _3775;\n        }\n    }\n    bool _3832 = fa_mesh_fs_params[42].w > 0.0;\n    if (_3832)\n    {\n        for (int k_2 = 0; k_2 < 9; k_2++)\n        {\n            vec2 param_3 = fa_mesh_fs_params[42].xy;\n            float param_4 = fa_mesh_fs_params[42].z;\n            int param_5 = k_2;\n            c[k_2] += (fa_probe_sh_coef(param_3, param_4, param_5) * fa_mesh_fs_params[42].w);\n        }\n    }\n    bool _3863 = fa_mesh_fs_params[47].w > 0.0;\n    if (_3863)\n    {\n        for (int k_3 = 0; k_3 < 9; k_3++)\n        {\n            vec2 param_6 = fa_mesh_fs_params[47].xy;\n            float param_7 = fa_mesh_fs_params[47].z;\n            int param_8 = k_3;\n            c[k_3] += (fa_probe_sh_coef(param_6, param_7, param_8) * fa_mesh_fs_params[47].w);\n        }\n    }\n    if ((_3781 || _3832) || _3863)\n    {\n        vec3 param_9[9] = c;\n        vec3 param_10 = n;\n        amb += fa_sh_eval(param_9, param_10);\n    }\n    return amb;\n}\n\nvec4 fa_gi_fetch(vec2 texel)\n{\n    return textureLod(fa_probe_atlas_fa_env_smp, texel / fa_atlas_size(), 0.0);\n}\n\nvec2 fa_oct_encode(vec3 d)\n{\n    vec3 _3686 = d / vec3(max((abs(d.x) + abs(d.y)) + abs(d.z), 9.9999999600419720025001879548654e-13));\n    float _3689 = _3686.x;\n    float _3691 = _3686.z;\n    vec2 e = vec2(_3689, _3691);\n    if (_3686.y < 0.0)\n    {\n        e = vec2((1.0 - abs(_3691)) * ((_3689 < 0.0) ? (-1.0) : 1.0), (1.0 - abs(_3689)) * ((_3691 < 0.0) ? (-1.0) : 1.0));\n    }\n    return e;\n}\n\nvec3 fa_gi_grid(int rec, vec3 n, vec3 v, out float cover)\n{\n    cover = 0.0;\n    int param = rec;\n    vec4 _4749 = fa_light_texel(param);\n    int param_1 = rec + 1;\n    vec4 _4754 = fa_light_texel(param_1);\n    int param_2 = rec + 2;\n    vec4 _4759 = fa_light_texel(param_2);\n    int param_3 = rec + 3;\n    vec4 _4764 = fa_light_texel(param_3);\n    bool _4767 = _4764.z < 0.5;\n    bool _4775;\n    if (!_4767)\n    {\n        _4775 = fa_atlas_size().y < 1155.0;\n    }\n    else\n    {\n        _4775 = _4767;\n    }\n    if (_4775)\n    {\n        return vec3(0.0);\n    }\n    float _4782 = max(_4749.w, 9.9999997473787516355514526367188e-05);\n    vec3 _4785 = _4754.xyz;\n    vec3 _4789 = _4749.xyz;\n    vec3 _4793 = (fa_world_pos - _4789) / vec3(_4782);\n    vec3 _4802 = min(_4793 + vec3(0.5), (_4785 - vec3(0.5)) - _4793);\n    float _4811 = min(_4802.x, min(_4802.y, _4802.z));\n    if (!(_4811 > 0.0))\n    {\n        return vec3(0.0);\n    }\n    vec3 _4826 = _4785 - vec3(1.0);\n    vec3 _4827 = clamp(_4793, vec3(0.0), _4826);\n    vec3 _4835 = min(floor(_4827), max(_4785 - vec3(2.0), vec3(0.0)));\n    vec3 _4839 = _4827 - _4835;\n    vec3 _4851 = fa_world_pos + (((n * 0.800000011920928955078125) + (v * 0.20000000298023223876953125)) * (0.20000000298023223876953125 * _4782));\n    int _4856 = int(_4759.y + 0.5);\n    float _4861 = 0.3257350027561187744140625 * n.y;\n    float _4865 = 0.3257350027561187744140625 * n.z;\n    float _4869 = 0.3257350027561187744140625 * n.x;\n    float _4876 = (0.2731371223926544189453125 * n.x) * n.y;\n    float _4883 = (0.2731371223926544189453125 * n.y) * n.z;\n    float _4892 = 0.078847892582416534423828125 * (((3.0 * n.z) * n.z) - 1.0);\n    float _4899 = (0.2731371223926544189453125 * n.x) * n.z;\n    float _4912 = 0.13656856119632720947265625 * ((n.x * n.x) - (n.y * n.y));\n    vec3 acc = vec3(0.0);\n    float wsum = 0.0;\n    int _4919 = 8 + int(_4764.w);\n    float _4946;\n    float _4959;\n    float _4973;\n    for (int k = 0; k < _4919; k++)\n    {\n        float _4932 = float(k & 1);\n        float _4936 = float((k >> 1) & 1);\n        float _4940 = float((k >> 2) & 1);\n        if (_4932 > 0.5)\n        {\n            _4946 = _4839.x;\n        }\n        else\n        {\n            _4946 = 1.0 - _4839.x;\n        }\n        if (_4936 > 0.5)\n        {\n            _4959 = _4839.y;\n        }\n        else\n        {\n            _4959 = 1.0 - _4839.y;\n        }\n        if (_4940 > 0.5)\n        {\n            _4973 = _4839.z;\n        }\n        else\n        {\n            _4973 = 1.0 - _4839.z;\n        }\n        float _4983 = (_4946 * _4959) * _4973;\n        if (!(_4983 > 0.0))\n        {\n            continue;\n        }\n        vec3 _4996 = min(_4835 + vec3(_4932, _4936, _4940), _4826);\n        int _5016 = int(((_4759.x + _4996.x) + (_4754.x * (_4996.y + (_4754.y * _4996.z)))) + 0.5);\n        vec2 _5031 = vec2(float(_5016 % _4856) * 10.0, 1024.0 + (float(_5016 / _4856) * 11.0));\n        vec2 param_4 = _5031 + vec2(9.5, 10.5);\n        vec4 _5039 = fa_gi_fetch(param_4);\n        bool _5042 = _5039.y < 0.5;\n        bool _5051;\n        if (!_5042)\n        {\n            _5051 = _5039.x > _4764.y;\n        }\n        else\n        {\n            _5051 = _5042;\n        }\n        if (_5051)\n        {\n            continue;\n        }\n        vec3 _5063 = _4851 - (_4789 + (_4996 * _4782));\n        float _5066 = length(_5063);\n        vec3 _5072 = _5063 / vec3(max(_5066, 9.9999997473787516355514526367188e-05));\n        float _5082 = max(9.9999997473787516355514526367188e-05, (dot(-_5072, n) + 1.0) * 0.5);\n        float w = _4983 * (_5082 * _5082);\n        vec3 param_5 = _5072;\n        vec2 param_6 = (_5031 + vec2(1.0)) + (((fa_oct_encode(param_5) * 0.5) + vec2(0.5)) * 8.0);\n        vec4 _5102 = fa_gi_fetch(param_6);\n        float _5109 = _5066 / max(_4759.z, 9.9999997473787516355514526367188e-05);\n        float _5112 = _5102.x;\n        if (_5109 > _5112)\n        {\n            float _5125 = max(_5102.y - (_5112 * _5112), 0.0);\n            float _5130 = _5109 - _5112;\n            float _5139 = _5125 / max(_5125 + (_5130 * _5130), 9.9999999600419720025001879548654e-13);\n            w *= ((_5139 * _5139) * _5139);\n        }\n        if (!(w > 0.0))\n        {\n            continue;\n        }\n        vec2 param_7 = _5031 + vec2(0.5, 10.5);\n        vec2 param_8 = _5031 + vec2(1.5, 10.5);\n        vec2 param_9 = _5031 + vec2(2.5, 10.5);\n        vec2 param_10 = _5031 + vec2(3.5, 10.5);\n        vec2 param_11 = _5031 + vec2(4.5, 10.5);\n        vec2 param_12 = _5031 + vec2(5.5, 10.5);\n        vec2 param_13 = _5031 + vec2(6.5, 10.5);\n        vec2 param_14 = _5031 + vec2(7.5, 10.5);\n        vec2 param_15 = _5031 + vec2(8.5, 10.5);\n        acc += ((((((((((fa_gi_fetch(param_7).xyz * 0.2820948064327239990234375) + (fa_gi_fetch(param_8).xyz * _4861)) + (fa_gi_fetch(param_9).xyz * _4865)) + (fa_gi_fetch(param_10).xyz * _4869)) + (fa_gi_fetch(param_11).xyz * _4876)) + (fa_gi_fetch(param_12).xyz * _4883)) + (fa_gi_fetch(param_13).xyz * _4892)) + (fa_gi_fetch(param_14).xyz * _4899)) + (fa_gi_fetch(param_15).xyz * _4912)) * w);\n        wsum += w;\n    }\n    if (!(wsum > 9.9999997473787516355514526367188e-06))\n    {\n        return vec3(0.0);\n    }\n    cover = smoothstep(0.0, 1.0, clamp(_4811 * 2.0, 0.0, 1.0)) * smoothstep(0.0, 0.0199999995529651641845703125, wsum);\n    float _5267;\n    if (fa_mesh_fs_params[52].z > 0.5)\n    {\n        _5267 = _4764.x;\n    }\n    else\n    {\n        _5267 = 1.0;\n    }\n    return max(acc / vec3(wsum), vec3(0.0)) * (_4759.w * _5267);\n}\n\nvec3 fa_gi_light(vec3 n, inout float left)\n{\n    left = 1.0;\n    vec3 acc = vec3(0.0);\n    vec3 _5291 = normalize(fa_mesh_fs_params[0].xyz - fa_world_pos);\n    int _5296 = int(fa_mesh_fs_params[52].x + 0.5);\n    int _5301 = int(fa_mesh_fs_params[52].y + 0.5);\n    float param_3;\n    for (int k = 0; (k < _5301) && (k < 8); k++)\n    {\n        int param = _5296 + (4 * k);\n        vec3 param_1 = n;\n        vec3 param_2 = _5291;\n        vec3 _5326 = fa_gi_grid(param, param_1, param_2, param_3);\n        float _5331 = param_3 * left;\n        acc += (_5326 * _5331);\n        left -= _5331;\n        if (left < 0.001000000047497451305389404296875)\n        {\n            left = 0.0;\n            break;\n        }\n    }\n    return acc;\n}\n\nvec3 fa_realtime_or_ambient(vec3 n)\n{\n    vec3 gi = vec3(0.0);\n    float left = 1.0;\n    if (fa_mesh_fs_params[52].y > 0.5)\n    {\n        vec3 param = n;\n        float param_1;\n        vec3 _5360 = fa_gi_light(param, param_1);\n        left = param_1;\n        gi = _5360;\n    }\n    if (left <= 0.0)\n    {\n        return gi;\n    }\n    vec3 param_2 = n;\n    return gi + (fa_ambient_light(param_2) * left);\n}\n\nvec3 fa_indirect_diffuse(vec3 n)\n{\n    if (fa_lm.z > 0.5)\n    {\n        return textureLod(fa_lightmap_fa_env_smp, fa_lm.xy, 0.0).xyz;\n    }\n    if (fa_mesh_fs_params[53].x > 0.5)\n    {\n        vec4 _5402 = vec4(fa_world_pos, 1.0);\n        vec2 _5421 = vec2(dot(fa_mesh_fs_params[26], _5402), dot(fa_mesh_fs_params[27], _5402)) / vec2(max(dot(fa_mesh_fs_params[28], _5402), 9.9999997473787516355514526367188e-05));\n        float _5430;\n        if (fa_mesh_fs_params[24].y > 0.5)\n        {\n            _5430 = (_5421.y * 0.5) + 0.5;\n        }\n        else\n        {\n            _5430 = 0.5 - (_5421.y * 0.5);\n        }\n        return texelFetch(fa_lightmap_fa_env_smp, clamp(ivec2(vec2((_5421.x * 0.5) + 0.5, _5430) * fa_mesh_fs_params[24].zw), ivec2(0), ivec2(fa_mesh_fs_params[24].zw) - ivec2(1)), 0).xyz;\n    }\n    if (fa_mesh_fs_params[32].w > 0.0)\n    {\n        vec3 c[9];\n        for (int k = 0; k < 9; k++)\n        {\n            c[k] = fa_mesh_fs_params[k * 1 + 32].xyz;\n        }\n        vec3 param = n;\n        vec3 param_1[9] = c;\n        vec3 param_2 = n;\n        return mix(fa_ambient_light(param), fa_sh_eval(param_1, param_2), vec3(clamp(fa_mesh_fs_params[32].w, 0.0, 1.0)));\n    }\n    vec3 param_3 = n;\n    return fa_realtime_or_ambient(param_3);\n}\n\nint fa_cluster_index(int slot, int n)\n{\n    int param = (int(fa_mesh_fs_params[19].x) + int(fa_mesh_fs_params[19].w)) + ((slot + n) >> 2);\n    vec4 t = fa_light_texel(param);\n    return int(t[(slot + n) & 3]);\n}\n\nint fa_cl_light(int n)\n{\n    if (n < fa_cl_ndir)\n    {\n        return n;\n    }\n    int param = fa_cl_slot;\n    int param_1 = n - fa_cl_ndir;\n    return fa_cluster_index(param, param_1);\n}\n\nint fa_light_base(int li)\n{\n    return li * ((fa_mesh_fs_params[1].w > 4.5) ? 8 : 4);\n}\n\nbool fa_light_baked(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 3;\n    return fa_light_texel(param_1).w > 0.5;\n}\n\nfloat fa_baked_keep(int li)\n{\n    float _4172;\n    if (fa_lm.z > 0.5)\n    {\n        _4172 = 0.0;\n    }\n    else\n    {\n        _4172 = 1.0 - clamp(fa_mesh_fs_params[32].w, 0.0, 1.0);\n    }\n    bool _4183 = _4172 < 1.0;\n    bool _4189;\n    if (_4183)\n    {\n        int param = li;\n        _4189 = fa_light_baked(param);\n    }\n    else\n    {\n        _4189 = _4183;\n    }\n    return _4189 ? _4172 : 1.0;\n}\n\nfloat fa_light_type(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 1;\n    return fa_light_texel(param_1).w;\n}\n\nvec3 fa_area_point(vec3 c, vec3 axis, vec3 ru, vec3 uu, float hx, float hy, float shape, vec3 p, vec3 r)\n{\n    bool _601 = dot(r, r) > 0.5;\n    if (shape > 1.5)\n    {\n        vec3 _614 = (c - (ru * hx)) - p;\n        vec3 _620 = ru * (2.0 * hx);\n        float _626 = max(dot(_620, _620), 9.9999999392252902907785028219223e-09);\n        float _630 = dot(_614, _620);\n        float t = clamp((-_630) / _626, 0.0, 1.0);\n        if (_601)\n        {\n            float _645 = dot(r, _620);\n            float _651 = _626 - (_645 * _645);\n            if (abs(_651) > (9.9999997473787516355514526367188e-06 * _626))\n            {\n                t = clamp(((dot(r, _614) * _645) - _630) / _651, 0.0, 1.0);\n            }\n        }\n        return (p + _614) + (_620 * t);\n    }\n    vec3 q = p;\n    float _683 = dot(r, axis);\n    bool _691;\n    if (_601)\n    {\n        _691 = abs(_683) > 9.9999997473787516355514526367188e-05;\n    }\n    else\n    {\n        _691 = _601;\n    }\n    if (_691)\n    {\n        float _701 = dot(c - p, axis) / _683;\n        if (_701 > 0.0)\n        {\n            q = p + (r * _701);\n        }\n    }\n    vec3 _714 = q - c;\n    vec2 xy = vec2(dot(_714, ru), dot(_714, uu));\n    if (shape > 0.5)\n    {\n        float _729 = length(xy);\n        if (_729 > hx)\n        {\n            xy *= (hx / _729);\n        }\n    }\n    else\n    {\n        xy = clamp(xy, vec2(-hx, -hy), vec2(hx, hy));\n    }\n    return (c + (ru * xy.x)) + (uu * xy.y);\n}\n\nvec4 fa_atlas_fetch(vec2 texel)\n{\n    return textureLod(fa_light_atlas_fa_env_smp, texel / vec2(textureSize(fa_light_atlas_fa_env_smp, 0)), 0.0);\n}\n\nvec3 fa_cookie_sample(vec2 tile_origin, vec2 uv)\n{\n    vec2 param = (tile_origin + vec2(1.0)) + (clamp(uv, vec2(0.0), vec2(1.0)) * 254.0);\n    return fa_atlas_fetch(param).xyz;\n}\n\nfloat fa_ies_sample(vec2 tile_origin, vec3 d, vec3 axis, vec3 right, vec3 up)\n{\n    float _521 = dot(d, right);\n    float _525 = dot(d, up);\n    float _536;\n    if (((_521 * _521) + (_525 * _525)) > 1.0000000133514319600180897396058e-10)\n    {\n        _536 = atan(_525, _521) * 0.15915493667125701904296875;\n    }\n    else\n    {\n        _536 = 0.0;\n    }\n    vec2 param = tile_origin + vec2(1.0 + ((_536 - floor(_536)) * 64.0), 1.0 + (acos(clamp(dot(d, axis), -1.0, 1.0)) * 10.18591594696044921875));\n    return fa_atlas_fetch(param).x;\n}\n\nint fa_cube_face(vec3 d)\n{\n    vec3 _372 = abs(d);\n    float _374 = _372.x;\n    float _376 = _372.y;\n    bool _377 = _374 >= _376;\n    bool _385;\n    if (_377)\n    {\n        _385 = _374 >= _372.z;\n    }\n    else\n    {\n        _385 = _377;\n    }\n    int _386;\n    if (_385)\n    {\n        _386 = (d.x > 0.0) ? 0 : 1;\n    }\n    else\n    {\n        int _400;\n        if (_376 >= _372.z)\n        {\n            _400 = (d.y > 0.0) ? 2 : 3;\n        }\n        else\n        {\n            _400 = (d.z > 0.0) ? 4 : 5;\n        }\n        _386 = _400;\n    }\n    return _386;\n}\n\nvoid fa_cube_face_basis(int f, out vec3 fwd, out vec3 up)\n{\n    if (f == 0)\n    {\n        fwd = vec3(1.0, 0.0, 0.0);\n        up = vec3(0.0, 1.0, 0.0);\n    }\n    else\n    {\n        if (f == 1)\n        {\n            fwd = vec3(-1.0, 0.0, 0.0);\n            up = vec3(0.0, 1.0, 0.0);\n        }\n        else\n        {\n            if (f == 2)\n            {\n                fwd = vec3(0.0, 1.0, 0.0);\n                up = vec3(0.0, 0.0, 1.0);\n            }\n            else\n            {\n                if (f == 3)\n                {\n                    fwd = vec3(0.0, -1.0, 0.0);\n                    up = vec3(0.0, 0.0, -1.0);\n                }\n                else\n                {\n                    if (f == 4)\n                    {\n                        fwd = vec3(0.0, 0.0, 1.0);\n                        up = vec3(0.0, 1.0, 0.0);\n                    }\n                    else\n                    {\n                        fwd = vec3(0.0, 0.0, -1.0);\n                        up = vec3(0.0, 1.0, 0.0);\n                    }\n                }\n            }\n        }\n    }\n}\n\nLightSample fa_light_sample_n(int li, vec3 world_pos, vec3 n)\n{\n    int param = li;\n    int _767 = fa_light_base(param);\n    bool _771 = fa_mesh_fs_params[1].w > 4.5;\n    int param_1 = _767;\n    vec4 _775 = fa_light_texel(param_1);\n    int param_2 = _767 + 1;\n    vec4 _780 = fa_light_texel(param_2);\n    float _783 = _780.w;\n    float atten = 1.0;\n    float dist = 0.0;\n    fa_light_tint = vec3(1.0);\n    bool _795 = _771 && (_783 > 2.5);\n    fa_light_is_area = _795;\n    bool _797 = _783 < 0.5;\n    vec3 l;\n    if (_797)\n    {\n        l = normalize(_775.xyz);\n        if (_771)\n        {\n            int param_3 = _767 + 6;\n            vec4 _811 = fa_light_texel(param_3);\n            if (_811.z > 0.5)\n            {\n                int param_4 = _767 + 4;\n                vec4 _821 = fa_light_texel(param_4);\n                int param_5 = _767 + 5;\n                vec4 _826 = fa_light_texel(param_5);\n                vec2 param_6 = _811.xy;\n                vec2 param_7 = fract(vec2(dot(world_pos, _821.xyz) * _821.w, (-dot(world_pos, _826.xyz)) * _826.w) + vec2(0.5));\n                fa_light_tint = fa_cookie_sample(param_6, param_7);\n            }\n        }\n    }\n    else\n    {\n        vec3 _856 = _775.xyz;\n        vec3 _858 = _856 - world_pos;\n        vec3 to_light = _858;\n        float _861 = length(_858);\n        float reach = _861;\n        bool front = true;\n        if (_795)\n        {\n            int param_8 = _767 + 7;\n            reach = max(_861 - fa_light_texel(param_8).w, 0.0);\n            int param_9 = _767 + 4;\n            vec4 _885 = fa_light_texel(param_9);\n            int param_10 = _767 + 5;\n            vec4 _890 = fa_light_texel(param_10);\n            int param_11 = _767 + 6;\n            vec4 _895 = fa_light_texel(param_11);\n            float _896 = _895.w;\n            int param_12 = _767 + 2;\n            vec3 _903 = normalize(fa_light_texel(param_12).xyz);\n            bool _905 = _896 > 1.5;\n            bool _913;\n            if (!_905)\n            {\n                _913 = dot(_903, to_light) < 0.0;\n            }\n            else\n            {\n                _913 = _905;\n            }\n            front = _913;\n            vec3 r = vec3(0.0);\n            vec3 _922 = fa_mesh_fs_params[0].xyz - world_pos;\n            bool _926 = dot(n, n) > 0.5;\n            bool _934;\n            if (_926)\n            {\n                _934 = dot(_922, _922) > 9.9999999600419720025001879548654e-13;\n            }\n            else\n            {\n                _934 = _926;\n            }\n            if (_934)\n            {\n                r = reflect(-normalize(_922), normalize(n));\n            }\n            vec3 param_13 = _856;\n            vec3 param_14 = _903;\n            vec3 param_15 = _885.xyz;\n            vec3 param_16 = _890.xyz;\n            float param_17 = _885.w;\n            float param_18 = _890.w;\n            float param_19 = _896;\n            vec3 param_20 = world_pos;\n            vec3 param_21 = r;\n            to_light = fa_area_point(param_13, param_14, param_15, param_16, param_17, param_18, param_19, param_20, param_21) - world_pos;\n        }\n        float _970 = length(to_light);\n        dist = _970;\n        l = to_light / vec3(max(_970, 9.9999997473787516355514526367188e-05));\n        float _984 = reach / max(_775.w, 0.001000000047497451305389404296875);\n        float _990 = clamp(1.0 - (_984 * _984), 0.0, 1.0);\n        float _992;\n        if (front)\n        {\n            _992 = _990 * _990;\n        }\n        else\n        {\n            _992 = 0.0;\n        }\n        atten = _992;\n        bool _1003 = _783 < 2.5;\n        if ((_783 > 1.5) && _1003)\n        {\n            int param_22 = _767 + 2;\n            vec4 _1011 = fa_light_texel(param_22);\n            float _1021 = _1011.w;\n            int param_23 = _767 + 3;\n            vec4 _1026 = fa_light_texel(param_23);\n            float _1027 = _1026.x;\n            float cos_inner = _1027;\n            if (_1027 > 1.5)\n            {\n                cos_inner = mix(_1021, 1.0, 0.25);\n            }\n            atten *= smoothstep(_1021, cos_inner, dot(-l, normalize(_1011.xyz)));\n        }\n        if (_771 && (_783 < 1.5))\n        {\n            int param_24 = _767 + 6;\n            vec4 _1051 = fa_light_texel(param_24);\n            if (_1051.z > 0.5)\n            {\n                vec3 _1059 = -to_light;\n                int param_25 = _767 + 4;\n                int param_26 = _767 + 5;\n                vec3 _1073 = fa_light_texel(param_25).xyz;\n                vec3 _1077 = fa_light_texel(param_26).xyz;\n                vec3 _1086 = vec3(dot(_1059, _1073), dot(_1059, _1077), dot(_1059, cross(_1073, _1077)));\n                vec3 param_27 = _1086;\n                int _1090 = fa_cube_face(param_27);\n                int param_28 = _1090;\n                vec3 param_29;\n                vec3 param_30;\n                fa_cube_face_basis(param_28, param_29, param_30);\n                vec2 _1117 = vec2(dot(_1086, cross(param_29, param_30)), dot(_1086, param_30)) / vec2(max(dot(_1086, param_29), 9.9999997473787516355514526367188e-05));\n                int _1121 = _1090 / 3;\n                vec2 param_31 = _1051.xy + (vec2(float(_1090 - (_1121 * 3)), float(_1121)) * 256.0);\n                vec2 param_32 = vec2(0.5 + (0.5 * _1117.x), 0.5 - (0.5 * _1117.y));\n                fa_light_tint = fa_cookie_sample(param_31, param_32);\n            }\n            int param_33 = _767 + 7;\n            vec4 _1151 = fa_light_texel(param_33);\n            if (_1151.z > 0.5)\n            {\n                int param_34 = _767 + 2;\n                int param_35 = _767 + 4;\n                int param_36 = _767 + 5;\n                vec2 param_37 = _1151.xy;\n                vec3 param_38 = -l;\n                vec3 param_39 = normalize(fa_light_texel(param_34).xyz);\n                vec3 param_40 = fa_light_texel(param_35).xyz;\n                vec3 param_41 = fa_light_texel(param_36).xyz;\n                atten *= fa_ies_sample(param_37, param_38, param_39, param_40, param_41);\n            }\n        }\n        else\n        {\n            if (_771 && _1003)\n            {\n                int param_42 = _767 + 6;\n                vec4 _1198 = fa_light_texel(param_42);\n                int param_43 = _767 + 7;\n                vec4 _1203 = fa_light_texel(param_43);\n                bool _1206 = _1198.z > 0.5;\n                bool _1213;\n                if (!_1206)\n                {\n                    _1213 = _1203.z > 0.5;\n                }\n                else\n                {\n                    _1213 = _1206;\n                }\n                if (_1213)\n                {\n                    int param_44 = _767 + 2;\n                    vec4 _1220 = fa_light_texel(param_44);\n                    vec3 _1224 = normalize(_1220.xyz);\n                    int param_45 = _767 + 4;\n                    vec4 _1229 = fa_light_texel(param_45);\n                    int param_46 = _767 + 5;\n                    vec4 _1234 = fa_light_texel(param_46);\n                    if (_1206)\n                    {\n                        vec3 _1242 = -to_light;\n                        float _1249 = _1220.w;\n                        float _1265 = 0.5 / max(dot(_1242, _1224) * (sqrt(max(1.0 - (_1249 * _1249), 0.0)) / max(_1249, 0.001000000047497451305389404296875)), 9.9999997473787516355514526367188e-05);\n                        vec2 param_47 = _1198.xy;\n                        vec2 param_48 = vec2(0.5 + (dot(_1242, _1229.xyz) * _1265), 0.5 - (dot(_1242, _1234.xyz) * _1265));\n                        fa_light_tint = fa_cookie_sample(param_47, param_48);\n                    }\n                    if (_1203.z > 0.5)\n                    {\n                        vec2 param_49 = _1203.xy;\n                        vec3 param_50 = -l;\n                        vec3 param_51 = _1224;\n                        vec3 param_52 = _1229.xyz;\n                        vec3 param_53 = _1234.xyz;\n                        atten *= fa_ies_sample(param_49, param_50, param_51, param_52, param_53);\n                    }\n                }\n            }\n        }\n    }\n    vec3 _6122 = _780.xyz * atten;\n    if (_771)\n    {\n        _6122 *= fa_light_tint;\n    }\n    int _1333;\n    if (_797)\n    {\n        _1333 = 0;\n    }\n    else\n    {\n        _1333 = ((_783 > 1.5) && (_783 < 2.5)) ? 2 : 1;\n    }\n    return LightSample(l, _6122, atten, 1.0, dist, _1333);\n}\n\nfloat fa_shadow_depth(inout vec2 uv, vec4 rect)\n{\n    uv = clamp(uv, rect.xy, rect.zw);\n    return textureLod(fa_shadow_tex_fa_shadow_smp, uv, 0.0).x;\n}\n\nfloat fa_shadow_fetch(vec2 uv, vec4 rect, vec3 conv)\n{\n    vec2 param = uv;\n    vec4 param_1 = rect;\n    float _2122 = fa_shadow_depth(param, param_1);\n    float _2126;\n    if (conv.x < 0.5)\n    {\n        _2126 = _2122;\n    }\n    else\n    {\n        _2126 = (conv.y * conv.z) / (conv.z - (_2122 * (conv.z - conv.y)));\n    }\n    return _2126;\n}\n\nfloat fa_shadow_noise()\n{\n    return fract(52.98291778564453125 * fract(dot(gl_FragCoord.xy, vec2(0.067110560834407806396484375, 0.005837149918079376220703125))));\n}\n\nvec2 fa_shadow_vogel_turn(vec2 d)\n{\n    return vec2((d.x * (-0.737368881702423095703125)) - (d.y * 0.675490319728851318359375), (d.y * (-0.737368881702423095703125)) + (d.x * 0.675490319728851318359375));\n}\n\nfloat fa_shadow_filter(vec2 uv, vec4 rect, float zr, float texel_m, float unit, float reach, float plane, vec3 conv, int mode, float k)\n{\n    if (mode == 1)\n    {\n        vec2 param = uv;\n        vec4 param_1 = rect;\n        vec3 param_2 = conv;\n        return float(zr <= fa_shadow_fetch(param, param_1, param_2));\n    }\n    float _2172 = fa_shadow_noise() * 6.283185482025146484375;\n    vec2 _2178 = vec2(cos(_2172), sin(_2172));\n    vec2 dir = _2178;\n    float radius = 1.5;\n    if (mode == 2)\n    {\n        float _2187;\n        if (k < 0.0)\n        {\n            _2187 = (-k) / max(zr, 0.100000001490116119384765625);\n        }\n        else\n        {\n            _2187 = k;\n        }\n        float _2206 = clamp((_2187 * reach) / texel_m, 3.0, 12.0);\n        float sum = 0.0;\n        float cnt = 0.0;\n        for (int i = 0; i < 16; i++)\n        {\n            float _2225 = sqrt((float(i) + 0.5) * 0.0625) * _2206;\n            vec2 param_3 = uv + (dir * (fa_shadows[26].zw * _2225));\n            vec4 param_4 = rect;\n            vec3 param_5 = conv;\n            float _2239 = fa_shadow_fetch(param_3, param_4, param_5);\n            if (_2239 < (zr - (_2225 * plane)))\n            {\n                sum += _2239;\n                cnt += 1.0;\n            }\n            vec2 param_6 = dir;\n            dir = fa_shadow_vogel_turn(param_6);\n        }\n        if (cnt < 0.5)\n        {\n            return 1.0;\n        }\n        float _2267 = sum / cnt;\n        float _2277;\n        if (k < 0.0)\n        {\n            _2277 = (-k) / max(_2267, 0.0500000007450580596923828125);\n        }\n        else\n        {\n            _2277 = k;\n        }\n        radius = clamp(((max(zr - _2267, 0.0) * unit) * _2277) / texel_m, 1.5, 16.0);\n        dir = _2178;\n    }\n    float lit = 0.0;\n    int _2303 = (mode == 2) ? 24 : 16;\n    for (int i_1 = 0; i_1 < _2303; i_1++)\n    {\n        float _2322 = sqrt((float(i_1) + 0.5) / float(_2303)) * radius;\n        vec2 param_7 = uv + (dir * (fa_shadows[26].zw * _2322));\n        vec4 param_8 = rect;\n        vec3 param_9 = conv;\n        lit += float((zr - (_2322 * plane)) <= fa_shadow_fetch(param_7, param_8, param_9));\n        vec2 param_10 = dir;\n        dir = fa_shadow_vogel_turn(param_10);\n    }\n    return lit / float(_2303);\n}\n\nfloat fa_shadow_local(int li, vec3 lpos, vec3 world, vec3 n, vec3 l)\n{\n    bool _2527 = fa_mesh_fs_params[5].z < 0.5;\n    bool _2534;\n    if (!_2527)\n    {\n        _2534 = fa_shadows[29].x < 0.5;\n    }\n    else\n    {\n        _2534 = _2527;\n    }\n    if (_2534)\n    {\n        return 1.0;\n    }\n    int param = (int(fa_shadows[29].x + 0.5) - 1) + li;\n    vec4 _2547 = fa_light_texel(param);\n    float _2548 = _2547.x;\n    if (_2548 < 0.0)\n    {\n        return 1.0;\n    }\n    int _2557 = int(_2548 + 0.5);\n    int param_1 = _2557;\n    vec4 _2561 = fa_light_texel(param_1);\n    int param_2 = _2557 + 1;\n    vec4 _2566 = fa_light_texel(param_2);\n    float fade = 1.0;\n    float _2569 = _2561.y;\n    if (_2569 > 0.0)\n    {\n        float _2586 = 1.0 - smoothstep(0.75 * _2569, _2569, length(world - fa_shadows[27].xyz));\n        fade = _2586;\n        if (_2586 <= 0.0)\n        {\n            return 1.0;\n        }\n    }\n    int face = 0;\n    if (_2561.x > 1.5)\n    {\n        vec3 param_3 = world - lpos;\n        face = fa_cube_face(param_3);\n    }\n    int _2610 = (_2557 + 2) + (face * 6);\n    int param_4 = _2610;\n    int param_5 = _2610 + 1;\n    int param_6 = _2610 + 3;\n    vec4 _2624 = fa_light_texel(param_6);\n    int param_7 = _2610 + 4;\n    vec4 _2629 = fa_light_texel(param_7);\n    int param_8 = _2610 + 5;\n    vec4 _2634 = fa_light_texel(param_8);\n    float _2646 = _2634.x * max(dot(_2624, vec4(world, 1.0)), 0.001000000047497451305389404296875);\n    float _2651 = clamp(dot(n, l), 0.0, 1.0);\n    float _2674 = clamp(dot(n, _2624.xyz), -1.0, 1.0);\n    float _2693 = min(sqrt(1.0 - (_2674 * _2674)) / max(abs(dot(n, world - lpos)) / max(dot(_2624, vec4(world, 1.0)), 0.001000000047497451305389404296875), 0.20000000298023223876953125), 4.0);\n    float _2696 = _2566.y;\n    float _2698;\n    if (_2696 > 0.0)\n    {\n        _2698 = _2696;\n    }\n    else\n    {\n        _2698 = 1.5 * _2646;\n    }\n    vec4 _2718 = vec4(world + (n * (_2698 * sqrt(1.0 - (_2651 * _2651)))), 1.0);\n    float _2722 = dot(_2624, _2718);\n    float _2725 = _2634.y;\n    if (_2722 < _2725)\n    {\n        return 1.0;\n    }\n    vec2 _2740 = vec2(dot(fa_light_texel(param_4), _2718), dot(fa_light_texel(param_5), _2718)) / vec2(_2722);\n    float _2742 = _2740.x;\n    bool _2745 = _2742 < _2629.x;\n    bool _2754;\n    if (!_2745)\n    {\n        _2754 = _2742 > _2629.z;\n    }\n    else\n    {\n        _2754 = _2745;\n    }\n    bool _2763;\n    if (!_2754)\n    {\n        _2763 = _2740.y < _2629.y;\n    }\n    else\n    {\n        _2763 = _2754;\n    }\n    bool _2772;\n    if (!_2763)\n    {\n        _2772 = _2740.y > _2629.w;\n    }\n    else\n    {\n        _2772 = _2763;\n    }\n    if (_2772)\n    {\n        return 1.0;\n    }\n    float _2778 = _2566.x;\n    float _2780;\n    if (_2778 > 0.0)\n    {\n        _2780 = _2778;\n    }\n    else\n    {\n        _2780 = 1.5 * _2646;\n    }\n    vec2 param_9 = _2740;\n    vec4 param_10 = _2629;\n    float param_11 = _2722 - (_2780 * (1.0 + (0.5 * _2693)));\n    float param_12 = _2646;\n    float param_13 = 1.0;\n    float param_14 = _2634.z * 0.25;\n    float param_15 = (_2646 * min(_2693, 3.0)) * 0.5;\n    vec3 param_16 = vec3(1.0, _2725, _2634.z);\n    int param_17 = int(_2561.z + 0.5);\n    float param_18 = _2561.w;\n    return mix(1.0, fa_shadow_filter(param_9, param_10, param_11, param_12, param_13, param_14, param_15, param_16, param_17, param_18), fade);\n}\n\nfloat fa_shadow_local_rt(int li, vec3 lpos, vec3 world, vec3 n, vec3 l)\n{\n    bool _3287 = fa_mesh_fs_params[25].w > 0.5;\n    bool _3293;\n    if (_3287)\n    {\n        _3293 = fa_mesh_fs_params[5].z > 0.5;\n    }\n    else\n    {\n        _3293 = _3287;\n    }\n    bool _3299;\n    if (_3293)\n    {\n        _3299 = fa_shadows[29].x > 0.5;\n    }\n    else\n    {\n        _3299 = _3293;\n    }\n    if (_3299)\n    {\n        int param = (int(fa_shadows[29].x + 0.5) - 1) + li;\n        vec4 _3311 = fa_light_texel(param);\n        float _3312 = _3311.z;\n        if (_3312 > 0.5)\n        {\n            float _3325 = dot(fa_mesh_fs_params[29].xyz, world) + fa_mesh_fs_params[29].w;\n            float _3331 = ((0.00200000009499490261077880859375 * _3325) + 0.00999999977648258209228515625) + fa_rt_slope;\n            vec4 _3337 = vec4(world, 1.0);\n            float _3342 = dot(fa_mesh_fs_params[28], _3337);\n            if (_3342 > 9.9999997473787516355514526367188e-05)\n            {\n                vec2 _3359 = vec2(dot(fa_mesh_fs_params[26], _3337), dot(fa_mesh_fs_params[27], _3337)) / vec2(_3342);\n                float _3364 = (_3359.x * 0.5) + 0.5;\n                float _3368;\n                if (fa_mesh_fs_params[24].y > 0.5)\n                {\n                    _3368 = (_3359.y * 0.5) + 0.5;\n                }\n                else\n                {\n                    _3368 = 0.5 - (_3359.y * 0.5);\n                }\n                bool _3384 = _3364 >= 0.0;\n                bool _3390;\n                if (_3384)\n                {\n                    _3390 = _3364 < 1.0;\n                }\n                else\n                {\n                    _3390 = _3384;\n                }\n                bool _3396;\n                if (_3390)\n                {\n                    _3396 = _3368 >= 0.0;\n                }\n                else\n                {\n                    _3396 = _3390;\n                }\n                bool _3402;\n                if (_3396)\n                {\n                    _3402 = _3368 < 1.0;\n                }\n                else\n                {\n                    _3402 = _3396;\n                }\n                if (_3402)\n                {\n                    ivec2 _3419 = ivec2(fa_mesh_fs_params[24].zw) - ivec2(1);\n                    ivec2 _3420 = clamp(ivec2(vec2(_3364, _3368) * fa_mesh_fs_params[24].zw), ivec2(0), _3419);\n                    float _3424;\n                    if (_3312 < 1.5)\n                    {\n                        _3424 = 1.0;\n                    }\n                    else\n                    {\n                        _3424 = (_3312 < 2.5) ? 256.0 : 65536.0;\n                    }\n                    float best = 2.0;\n                    int _3446;\n                    int _3452;\n                    for (int k = 0; k < 9; k++)\n                    {\n                        if (k == 0)\n                        {\n                            _3446 = 4;\n                        }\n                        else\n                        {\n                            if (k <= 4)\n                            {\n                                _3452 = k - 1;\n                            }\n                            else\n                            {\n                                _3452 = k;\n                            }\n                            _3446 = _3452;\n                        }\n                        vec4 _3481 = texelFetch(fa_screen_tex_fa_shadow_smp, clamp(_3420 + ivec2((_3446 % 3) - 1, (_3446 / 3) - 1), ivec2(0), _3419), 0);\n                        bool _3484 = _3481.w > 0.5;\n                        bool _3494;\n                        if (_3484)\n                        {\n                            _3494 = abs(_3325 - _3481.x) <= _3331;\n                        }\n                        else\n                        {\n                            _3494 = _3484;\n                        }\n                        if (_3494)\n                        {\n                            best = min(best, mod(floor(_3481.z / _3424), 256.0) * 0.0039215688593685626983642578125);\n                            if (k == 0)\n                            {\n                                break;\n                            }\n                        }\n                    }\n                    if (best <= 1.0)\n                    {\n                        float _3521;\n                        if (fa_mesh_fs_params[25].z > 0.5)\n                        {\n                            int param_1 = li;\n                            vec3 param_2 = lpos;\n                            vec3 param_3 = world;\n                            vec3 param_4 = n;\n                            vec3 param_5 = l;\n                            _3521 = min(best, fa_shadow_local(param_1, param_2, param_3, param_4, param_5));\n                        }\n                        else\n                        {\n                            _3521 = best;\n                        }\n                        return _3521;\n                    }\n                }\n            }\n            float _3544;\n            if (fa_mesh_fs_params[25].z > 0.5)\n            {\n                int param_6 = li;\n                vec3 param_7 = lpos;\n                vec3 param_8 = world;\n                vec3 param_9 = n;\n                vec3 param_10 = l;\n                _3544 = fa_shadow_local(param_6, param_7, param_8, param_9, param_10);\n            }\n            else\n            {\n                _3544 = 1.0;\n            }\n            return _3544;\n        }\n    }\n    int param_11 = li;\n    vec3 param_12 = lpos;\n    vec3 param_13 = world;\n    vec3 param_14 = n;\n    vec3 param_15 = l;\n    return fa_shadow_local(param_11, param_12, param_13, param_14, param_15);\n}\n\nfloat fa_shadow_split_at(int i)\n{\n    float _2065;\n    if (i == 0)\n    {\n        _2065 = fa_shadows[24].x;\n    }\n    else\n    {\n        float _2081;\n        if (i == 1)\n        {\n            _2081 = fa_shadows[24].y;\n        }\n        else\n        {\n            float _2089;\n            if (i == 2)\n            {\n                _2089 = fa_shadows[24].z;\n            }\n            else\n            {\n                _2089 = fa_shadows[24].w;\n            }\n            _2081 = _2089;\n        }\n        _2065 = _2081;\n    }\n    return _2065;\n}\n\nfloat fa_shadow_cascade(int ci, vec3 world, vec3 n, vec3 l)\n{\n    float _2368 = max(fa_shadows[ci * 1 + 20].y, 0.001000000047497451305389404296875);\n    float _2373 = clamp(dot(n, l), 0.0, 1.0);\n    float _2379 = sqrt(1.0 - (_2373 * _2373));\n    float _2387 = min(_2379 / max(_2373, 0.20000000298023223876953125), 4.0);\n    float _2392;\n    if (fa_shadows[26].y > 0.0)\n    {\n        _2392 = fa_shadows[26].y;\n    }\n    else\n    {\n        _2392 = 1.5 * fa_shadows[ci * 1 + 20].x;\n    }\n    vec4 _2417 = mat4(fa_shadows[ci * 4 + 0], fa_shadows[ci * 4 + 1], fa_shadows[ci * 4 + 2], fa_shadows[ci * 4 + 3]) * vec4(world + (n * (_2392 * _2379)), 1.0);\n    float _2424 = _2417.x;\n    bool _2427 = _2424 < fa_shadows[ci * 1 + 16].x;\n    bool _2436;\n    if (!_2427)\n    {\n        _2436 = _2424 > fa_shadows[ci * 1 + 16].z;\n    }\n    else\n    {\n        _2436 = _2427;\n    }\n    bool _2445;\n    if (!_2436)\n    {\n        _2445 = _2417.y < fa_shadows[ci * 1 + 16].y;\n    }\n    else\n    {\n        _2445 = _2436;\n    }\n    bool _2454;\n    if (!_2445)\n    {\n        _2454 = _2417.y > fa_shadows[ci * 1 + 16].w;\n    }\n    else\n    {\n        _2454 = _2445;\n    }\n    bool _2461;\n    if (!_2454)\n    {\n        _2461 = _2417.z > 1.0;\n    }\n    else\n    {\n        _2461 = _2454;\n    }\n    if (_2461)\n    {\n        return -1.0;\n    }\n    float _2469;\n    if (fa_shadows[26].x > 0.0)\n    {\n        _2469 = fa_shadows[26].x;\n    }\n    else\n    {\n        _2469 = 1.5 * fa_shadows[ci * 1 + 20].x;\n    }\n    vec2 param = _2417.xy;\n    vec4 param_1 = fa_shadows[ci * 1 + 16];\n    float param_2 = _2417.z - ((_2469 * (1.0 + (0.5 * _2387))) / _2368);\n    float param_3 = fa_shadows[ci * 1 + 20].x;\n    float param_4 = _2368;\n    float param_5 = _2368 * 0.25;\n    float param_6 = ((fa_shadows[ci * 1 + 20].x * min(_2387, 3.0)) * 0.5) / _2368;\n    vec3 param_7 = vec3(0.0);\n    int param_8 = int(fa_shadows[25].z + 0.5);\n    float param_9 = fa_shadows[25].w;\n    return fa_shadow_filter(param, param_1, param_2, param_3, param_4, param_5, param_6, param_7, param_8, param_9);\n}\n\nfloat fa_shadow_sun(vec3 world, vec3 n, vec3 l)\n{\n    if (fa_mesh_fs_params[5].z < 0.5)\n    {\n        return 1.0;\n    }\n    int _2847 = int(fa_shadows[25].x + 0.5);\n    if (_2847 < 1)\n    {\n        return 1.0;\n    }\n    float _2862 = dot(world - fa_shadows[27].xyz, fa_shadows[28].xyz);\n    int param = _2847 - 1;\n    if (_2862 > fa_shadow_split_at(param))\n    {\n        return 1.0;\n    }\n    int ci = 0;\n    bool _2874 = _2847 > 1;\n    bool _2881;\n    if (_2874)\n    {\n        _2881 = _2862 > fa_shadows[24].x;\n    }\n    else\n    {\n        _2881 = _2874;\n    }\n    if (_2881)\n    {\n        ci = 1;\n    }\n    bool _2885 = _2847 > 2;\n    bool _2892;\n    if (_2885)\n    {\n        _2892 = _2862 > fa_shadows[24].y;\n    }\n    else\n    {\n        _2892 = _2885;\n    }\n    if (_2892)\n    {\n        ci = 2;\n    }\n    bool _2896 = _2847 > 3;\n    bool _2903;\n    if (_2896)\n    {\n        _2903 = _2862 > fa_shadows[24].z;\n    }\n    else\n    {\n        _2903 = _2896;\n    }\n    if (_2903)\n    {\n        ci = 3;\n    }\n    float s = -1.0;\n    float s2 = -1.0;\n    float t = 0.0;\n    int _2914 = min(_2847, 4);\n    float _2955;\n    for (int c = ci; c < _2914; c++)\n    {\n        int param_1 = c;\n        vec3 param_2 = world;\n        vec3 param_3 = n;\n        vec3 param_4 = l;\n        float _2934 = fa_shadow_cascade(param_1, param_2, param_3, param_4);\n        if (s >= 0.0)\n        {\n            s2 = _2934;\n            break;\n        }\n        if (_2934 < 0.0)\n        {\n            continue;\n        }\n        s = _2934;\n        ci = c;\n        if (fa_shadows[25].y > 0.0)\n        {\n            if (ci > 0)\n            {\n                int param_5 = ci - 1;\n                _2955 = fa_shadow_split_at(param_5);\n            }\n            else\n            {\n                _2955 = fa_shadows[28].w;\n            }\n            int param_6 = ci;\n            float _2974 = fa_shadows[25].y * max(fa_shadow_split_at(param_6) - _2955, 9.9999997473787516355514526367188e-05);\n            int param_7 = ci;\n            t = clamp((_2862 - (fa_shadow_split_at(param_7) - _2974)) / _2974, 0.0, 1.0);\n        }\n        if (t <= 0.0)\n        {\n            break;\n        }\n    }\n    if (s < 0.0)\n    {\n        return 1.0;\n    }\n    if (t > 0.0)\n    {\n        float _3006;\n        if ((ci + 1) < _2847)\n        {\n            _3006 = (s2 < 0.0) ? s : s2;\n        }\n        else\n        {\n            _3006 = 1.0;\n        }\n        s = mix(s, _3006, t);\n    }\n    return s;\n}\n\nfloat fa_shadow_factor(vec3 n, vec3 l)\n{\n    bool _3111 = fa_mesh_fs_params[25].y > 0.5;\n    bool _3117;\n    if (_3111)\n    {\n        _3117 = fa_mesh_fs_params[5].z > 0.5;\n    }\n    else\n    {\n        _3117 = _3111;\n    }\n    if (_3117)\n    {\n        float _3131 = dot(fa_mesh_fs_params[29].xyz, fa_world_pos) + fa_mesh_fs_params[29].w;\n        vec4 _3139 = vec4(fa_world_pos, 1.0);\n        float _3145 = dot(fa_mesh_fs_params[28], _3139);\n        if (_3145 > 9.9999997473787516355514526367188e-05)\n        {\n            vec2 _3164 = vec2(dot(fa_mesh_fs_params[26], _3139), dot(fa_mesh_fs_params[27], _3139)) / vec2(_3145);\n            float _3169 = (_3164.x * 0.5) + 0.5;\n            float _3173;\n            if (fa_mesh_fs_params[24].y > 0.5)\n            {\n                _3173 = (_3164.y * 0.5) + 0.5;\n            }\n            else\n            {\n                _3173 = 0.5 - (_3164.y * 0.5);\n            }\n            bool _3189 = _3169 >= 0.0;\n            bool _3195;\n            if (_3189)\n            {\n                _3195 = _3169 < 1.0;\n            }\n            else\n            {\n                _3195 = _3189;\n            }\n            bool _3201;\n            if (_3195)\n            {\n                _3201 = _3173 >= 0.0;\n            }\n            else\n            {\n                _3201 = _3195;\n            }\n            bool _3207;\n            if (_3201)\n            {\n                _3207 = _3173 < 1.0;\n            }\n            else\n            {\n                _3207 = _3201;\n            }\n            if (_3207)\n            {\n                vec4 _3233 = texelFetch(fa_screen_tex_fa_shadow_smp, clamp(ivec2(vec2(_3169, _3173) * fa_mesh_fs_params[24].zw), ivec2(0), ivec2(fa_mesh_fs_params[24].zw) - ivec2(1)), 0);\n                bool _3236 = _3233.w > 0.5;\n                bool _3252;\n                if (_3236)\n                {\n                    _3252 = abs(_3131 - _3233.x) <= (((0.00200000009499490261077880859375 * _3131) + 0.00999999977648258209228515625) + fa_rt_slope);\n                }\n                else\n                {\n                    _3252 = _3236;\n                }\n                if (_3252)\n                {\n                    float _3258;\n                    if (fa_mesh_fs_params[25].z > 0.5)\n                    {\n                        vec3 param = fa_world_pos;\n                        vec3 param_1 = n;\n                        vec3 param_2 = l;\n                        _3258 = min(_3233.y, fa_shadow_sun(param, param_1, param_2));\n                    }\n                    else\n                    {\n                        _3258 = _3233.y;\n                    }\n                    return _3258;\n                }\n            }\n        }\n    }\n    vec3 param_3 = fa_world_pos;\n    vec3 param_4 = n;\n    vec3 param_5 = l;\n    return fa_shadow_sun(param_3, param_4, param_5);\n}\n\nfloat fa_contact_shadow(int li, vec3 world, vec3 gn, vec3 l, float dist)\n{\n    bool _3914 = fa_mesh_fs_params[24].x < 0.5;\n    bool _3921;\n    if (!_3914)\n    {\n        _3921 = fa_shadows[29].x < 0.5;\n    }\n    else\n    {\n        _3921 = _3914;\n    }\n    if (_3921)\n    {\n        return 1.0;\n    }\n    int param = (int(fa_shadows[29].x + 0.5) - 1) + li;\n    vec4 _3934 = fa_light_texel(param);\n    float _3935 = _3934.y;\n    float len = _3935;\n    if (_3935 <= 0.0)\n    {\n        return 1.0;\n    }\n    float _3947 = length(world - fa_mesh_fs_params[0].xyz);\n    float _3956 = 1.0 - smoothstep(0.5 * fa_mesh_fs_params[25].x, fa_mesh_fs_params[25].x, _3947);\n    if (_3956 <= 0.0)\n    {\n        return 1.0;\n    }\n    float _3962 = len;\n    float _3965 = min(_3962, 0.89999997615814208984375 * dist);\n    len = _3965;\n    float _3971 = 0.004999999888241291046142578125 + (0.0030000000260770320892333984375 * _3947);\n    float _3976 = _3971 + (0.5 * _3965);\n    vec3 _3982 = world + (gn * _3971);\n    float _3984 = fa_shadow_noise();\n    float occ = 0.0;\n    float _4046;\n    for (int k = 0; k < 12; k++)\n    {\n        float _4000 = (float(k) + _3984) * 0.083333335816860198974609375;\n        vec3 _4008 = _3982 + (l * (_4000 * len));\n        vec4 _4014 = vec4(_4008, 1.0);\n        float _4019 = dot(fa_mesh_fs_params[28], _4014);\n        if (_4019 < 9.9999997473787516355514526367188e-05)\n        {\n            break;\n        }\n        vec2 _4037 = vec2(dot(fa_mesh_fs_params[26], _4014), dot(fa_mesh_fs_params[27], _4014)) / vec2(_4019);\n        float _4041 = _4037.x * 0.5;\n        float _4042 = _4041 + 0.5;\n        if (fa_mesh_fs_params[24].y > 0.5)\n        {\n            _4046 = (_4037.y * 0.5) + 0.5;\n        }\n        else\n        {\n            _4046 = 0.5 - (_4037.y * 0.5);\n        }\n        bool _4062 = _4042 < 0.0;\n        bool _4069;\n        if (!_4062)\n        {\n            _4069 = _4042 >= 1.0;\n        }\n        else\n        {\n            _4069 = _4062;\n        }\n        bool _4076;\n        if (!_4069)\n        {\n            _4076 = _4046 < 0.0;\n        }\n        else\n        {\n            _4076 = _4069;\n        }\n        bool _4083;\n        if (!_4076)\n        {\n            _4083 = _4046 >= 1.0;\n        }\n        else\n        {\n            _4083 = _4076;\n        }\n        if (_4083)\n        {\n            break;\n        }\n        vec4 _4107 = texelFetch(fa_screen_tex_fa_shadow_smp, clamp(ivec2(vec2(_4042, _4046) * fa_mesh_fs_params[24].zw), ivec2(0), ivec2(fa_mesh_fs_params[24].zw) - ivec2(1)), 0);\n        if (_4107.w < 0.5)\n        {\n            continue;\n        }\n        float _4125 = (dot(fa_mesh_fs_params[29].xyz, _4008) + fa_mesh_fs_params[29].w) - _4107.x;\n        if ((_4125 > _3971) && (_4125 < _3976))\n        {\n            occ = max(occ, (1.0 - (_4000 * _4000)) * smoothstep(0.0, 0.0500000007450580596923828125, min(min(_4042, 0.5 - _4041), min(_4046, 1.0 - _4046))));\n        }\n    }\n    return 1.0 - (occ * _3956);\n}\n\nLightSample fa_light_shadowed(int li, vec3 world_pos, vec3 gn)\n{\n    int param = li;\n    float _4257 = fa_baked_keep(param);\n    if (_4257 <= 0.0)\n    {\n        int param_1 = li;\n        return LightSample(vec3(0.0, 1.0, 0.0), vec3(0.0), 0.0, 1.0, 0.0, int(fa_light_type(param_1) + 0.5));\n    }\n    int param_2 = li;\n    vec3 param_3 = world_pos;\n    vec3 param_4 = gn;\n    LightSample _4283 = fa_light_sample_n(param_2, param_3, param_4);\n    vec3 _6148 = _4283.color;\n    float _6149 = _4283.attenuation;\n    float _6150 = _4283.shadow;\n    bool _4286 = _4283.type == 0;\n    if (_4286 && (li == 0))\n    {\n        vec3 param_5 = gn;\n        vec3 param_6 = _4283.direction;\n        float _4297 = fa_shadow_factor(param_5, param_6);\n        _6150 = _4297;\n        _6148 *= _4297;\n    }\n    else\n    {\n        bool _4308 = _4283.type != 0;\n        bool _4314;\n        if (_4308)\n        {\n            _4314 = _6149 > 0.0;\n        }\n        else\n        {\n            _4314 = _4308;\n        }\n        if (_4314)\n        {\n            int param_7 = li;\n            int param_8 = fa_light_base(param_7);\n            int param_9 = li;\n            vec3 param_10 = fa_light_texel(param_8).xyz;\n            vec3 param_11 = world_pos;\n            vec3 param_12 = gn;\n            vec3 param_13 = _4283.direction;\n            float _4333 = fa_shadow_local_rt(param_9, param_10, param_11, param_12, param_13);\n            _6150 = _4333;\n            _6148 *= _4333;\n        }\n    }\n    bool _4343 = fa_mesh_fs_params[24].x > 0.5;\n    bool _4349;\n    if (_4343)\n    {\n        _4349 = _6149 > 0.0;\n    }\n    else\n    {\n        _4349 = _4343;\n    }\n    if (_4349)\n    {\n        float _4356;\n        if (_4286)\n        {\n            _4356 = 1000000000.0;\n        }\n        else\n        {\n            _4356 = _4283._distance;\n        }\n        int param_14 = li;\n        vec3 param_15 = world_pos;\n        vec3 param_16 = gn;\n        vec3 param_17 = _4283.direction;\n        float param_18 = _4356;\n        float _4374 = fa_contact_shadow(param_14, param_15, param_16, param_17, param_18);\n        _6150 *= _4374;\n        _6148 *= _4374;\n    }\n    float _4387 = _6149;\n    float _4388 = _4387 * _4257;\n    _6149 = _4388;\n    vec3 _4392 = _6148;\n    vec3 _4393 = _4392 * _4257;\n    _6148 = _4393;\n    return LightSample(_4283.direction, _4393, _4388, _6150, _4283._distance, _4283.type);\n}\n\nvec3 light(SurfaceInput i, Surface s, LightSample l)\n{\n    return vec3(0.0);\n}\n\nvec3 fa_shadow_debug(vec3 color, vec3 world)\n{\n    if (fa_shadows[27].w < 0.5)\n    {\n        return color;\n    }\n    int _3034 = int(fa_shadows[25].x + 0.5);\n    float _3044 = dot(world - fa_shadows[27].xyz, fa_shadows[28].xyz);\n    vec3 tint = vec3(0.3499999940395355224609375);\n    bool _3049 = _3034 > 0;\n    bool _3058;\n    if (_3049)\n    {\n        int param = _3034 - 1;\n        _3058 = _3044 <= fa_shadow_split_at(param);\n    }\n    else\n    {\n        _3058 = _3049;\n    }\n    if (_3058)\n    {\n        tint = vec3(1.0, 0.1500000059604644775390625, 0.100000001490116119384765625);\n        bool _3064 = _3034 > 1;\n        bool _3071;\n        if (_3064)\n        {\n            _3071 = _3044 > fa_shadows[24].x;\n        }\n        else\n        {\n            _3071 = _3064;\n        }\n        if (_3071)\n        {\n            tint = vec3(0.100000001490116119384765625, 0.89999997615814208984375, 0.20000000298023223876953125);\n        }\n        bool _3077 = _3034 > 2;\n        bool _3084;\n        if (_3077)\n        {\n            _3084 = _3044 > fa_shadows[24].y;\n        }\n        else\n        {\n            _3084 = _3077;\n        }\n        if (_3084)\n        {\n            tint = vec3(0.1500000059604644775390625, 0.300000011920928955078125, 1.0);\n        }\n        bool _3090 = _3034 > 3;\n        bool _3097;\n        if (_3090)\n        {\n            _3097 = _3044 > fa_shadows[24].z;\n        }\n        else\n        {\n            _3097 = _3090;\n        }\n        if (_3097)\n        {\n            tint = vec3(1.0, 0.89999997615814208984375, 0.100000001490116119384765625);\n        }\n    }\n    return mix(color, tint, vec3(0.550000011920928955078125));\n}\n\nvoid main()\n{\n    fa_rt_slope = 0.0;\n    fa_inst_load();\n    vec3 _5969 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _5969 = -_5969;\n    }\n    vec3 _5543 = normalize(fa_mesh_fs_params[0].xyz - fa_world_pos);\n    vec3 param = fa_world_pos;\n    fa_cluster_begin(param);\n    SurfaceInput param_1 = SurfaceInput(fa_world_pos, _5969, fa_world_tangent, fa_uv, fa_vertex_color, _5543, gl_FrontFacing);\n    Surface _5551 = fa_standard_surface(param_1);\n    vec3 _6000 = _5551.albedo;\n    float _6001 = _5551.alpha;\n    vec3 _6002 = _5551.normal;\n    float _6003 = _5551.metallic;\n    float _6004 = _5551.roughness;\n    float _6005 = _5551.occlusion;\n    vec3 _6006 = _5551.emission;\n    float _6007 = _5551.clearcoat;\n    float _6008 = _5551.clearcoat_roughness;\n    vec3 _6009 = _5551.sheen_color;\n    float _6010 = _5551.sheen_roughness;\n    float _6011 = _5551.anisotropy;\n    float _6012 = _5551.anisotropy_rotation;\n    float _6013 = _5551.specular;\n    float _6014 = _5551.ior;\n    vec3 _6015 = _5551.specular_color;\n    float _6016 = _5551.transmission;\n    float _6017 = _5551.thickness;\n    vec3 _6018 = _5551.attenuation_color;\n    float _6019 = _5551.attenuation_distance;\n    SurfaceInput param_2 = SurfaceInput(fa_world_pos, _5969, fa_world_tangent, fa_uv, fa_vertex_color, _5543, gl_FrontFacing);\n    Surface param_3 = _5551;\n    surface(param_2, param_3);\n    _6000 = param_3.albedo;\n    _6001 = param_3.alpha;\n    _6002 = param_3.normal;\n    _6003 = param_3.metallic;\n    _6004 = param_3.roughness;\n    _6005 = param_3.occlusion;\n    _6006 = param_3.emission;\n    _6007 = param_3.clearcoat;\n    _6008 = param_3.clearcoat_roughness;\n    _6009 = param_3.sheen_color;\n    _6010 = param_3.sheen_roughness;\n    _6011 = param_3.anisotropy;\n    _6012 = param_3.anisotropy_rotation;\n    _6013 = param_3.specular;\n    _6014 = param_3.ior;\n    _6015 = param_3.specular_color;\n    _6016 = param_3.transmission;\n    _6017 = param_3.thickness;\n    _6018 = param_3.attenuation_color;\n    _6019 = param_3.attenuation_distance;\n    vec3 param_4 = fa_world_pos;\n    vec3 param_5 = _5969;\n    vec3 param_6 = param_3.albedo;\n    vec3 param_7 = param_3.normal;\n    fa_apply_decals(param_4, param_5, param_6, param_7);\n    _6000 = param_6;\n    _6002 = param_7;\n    vec3 result;\n    if (fa_mesh_fs_params[3].w > 0.5)\n    {\n        result = _6000;\n    }\n    else\n    {\n        vec3 _5590 = _6002;\n        vec3 _5591 = normalize(_5590);\n        _6002 = _5591;\n        vec3 param_8 = _5591;\n        vec3 lit = (fa_indirect_diffuse(param_8) * _6000) * _6005;\n        int _5610 = fa_cl_ndir + fa_cl_local;\n        for (int ln = 0; ln < _5610; ln++)\n        {\n            int param_9 = ln;\n            int _5623 = fa_cl_light(param_9);\n            int param_10 = _5623;\n            if (fa_baked_keep(param_10) <= 0.0)\n            {\n                continue;\n            }\n            int param_11 = _5623;\n            vec3 param_12 = fa_world_pos;\n            vec3 param_13 = _5969;\n            LightSample _5639 = fa_light_shadowed(param_11, param_12, param_13);\n            SurfaceInput param_14 = SurfaceInput(fa_world_pos, _5969, fa_world_tangent, fa_uv, fa_vertex_color, _5543, gl_FrontFacing);\n            Surface param_15 = Surface(_6000, _6001, _6002, _6003, _6004, _6005, _6006, _6007, _6008, _6009, _6010, _6011, _6012, _6013, _6014, _6015, _6016, _6017, _6018, _6019);\n            LightSample param_16 = _5639;\n            lit += light(param_14, param_15, param_16);\n        }\n        result = lit;\n    }\n    vec3 _5654 = result;\n    vec3 _5655 = _5654 + _6006;\n    result = _5655;\n    vec3 param_17 = _5655;\n    vec3 param_18 = fa_world_pos;\n    result = fa_shadow_debug(param_17, param_18);\n    bool _5664 = fa_mesh_fs_params[7].w > 0.0;\n    bool _5671;\n    if (!_5664)\n    {\n        _5671 = fa_mesh_fs_params[8].y > 0.0;\n    }\n    else\n    {\n        _5671 = _5664;\n    }\n    if (_5671)\n    {\n        vec3 _5680 = fa_world_pos - fa_mesh_fs_params[0].xyz;\n        float _5686 = dot(_5680, fa_mesh_fs_params[9].xyz);\n        bool _5690 = fa_mesh_fs_params[9].w > 0.5;\n        float _5691;\n        if (_5690)\n        {\n            _5691 = _5686;\n        }\n        else\n        {\n            _5691 = length(_5680);\n        }\n        float _5703 = _5691 - fa_mesh_fs_params[8].x;\n        if (_5703 > 0.0)\n        {\n            float _5712 = fa_mesh_fs_params[7].w * _5703;\n            float tau = _5712 * _5712;\n            if (fa_mesh_fs_params[8].y > 0.0)\n            {\n                float _5728;\n                if (_5690)\n                {\n                    _5728 = fa_world_pos.y - (fa_mesh_fs_params[9].y * _5686);\n                }\n                else\n                {\n                    _5728 = fa_mesh_fs_params[0].y;\n                }\n                float _5749 = mix(_5728, fa_world_pos.y, clamp(fa_mesh_fs_params[8].x / _5691, 0.0, 1.0));\n                float _5753 = fa_world_pos.y - _5749;\n                float _5758 = _5749 - fa_mesh_fs_params[8].z;\n                float _5763 = fa_world_pos.y - fa_mesh_fs_params[8].z;\n                bool _5766 = _5758 <= 0.0;\n                bool _5767 = !_5766;\n                bool _5773;\n                if (_5767)\n                {\n                    _5773 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _5773 = _5766;\n                }\n                float _5774;\n                if (_5773)\n                {\n                    _5774 = fa_mesh_fs_params[8].y;\n                }\n                else\n                {\n                    _5774 = fa_mesh_fs_params[8].y * exp(-min(fa_mesh_fs_params[8].w * _5758, 80.0));\n                }\n                bool _5801;\n                if (_5767)\n                {\n                    _5801 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _5801 = _5766;\n                }\n                float _5802;\n                if (_5801)\n                {\n                    _5802 = fa_mesh_fs_params[8].y * _5758;\n                }\n                else\n                {\n                    _5802 = (fa_mesh_fs_params[8].y * (1.0 - exp(-min(fa_mesh_fs_params[8].w * _5758, 80.0)))) / fa_mesh_fs_params[8].w;\n                }\n                bool _5827 = _5763 <= 0.0;\n                bool _5834;\n                if (!_5827)\n                {\n                    _5834 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _5834 = _5827;\n                }\n                float _5835;\n                if (_5834)\n                {\n                    _5835 = fa_mesh_fs_params[8].y * _5763;\n                }\n                else\n                {\n                    _5835 = (fa_mesh_fs_params[8].y * (1.0 - exp(-min(fa_mesh_fs_params[8].w * _5763, 80.0)))) / fa_mesh_fs_params[8].w;\n                }\n                float _5862;\n                if (abs(_5753) < 0.001000000047497451305389404296875)\n                {\n                    _5862 = _5774;\n                }\n                else\n                {\n                    _5862 = (_5835 - _5802) / _5753;\n                }\n                tau += (_5703 * max(_5862, 0.0));\n            }\n            result = mix(result, fa_mesh_fs_params[7].xyz, vec3(clamp(1.0 - exp(-clamp(tau, 0.0, 80.0)), 0.0, 1.0)));\n        }\n    }\n    fa_frag_color = vec4(result, _6001);\n}\n\n",
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
            "inst_name": "_423",
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
            "inst_name": "_2075",
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
      "vs": "#version 430\n\nstruct VertexData\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 color;\n    vec3 object_pos;\n};\n\nuniform vec4 fa_mesh_vs_params[11];\nuniform vec4 fa_vel_params[9];\nlayout(location = 0) out vec3 fa_world_pos;\nlayout(location = 1) out vec3 fa_world_normal;\nlayout(location = 2) out vec4 fa_world_tangent;\nlayout(location = 3) out vec2 fa_uv;\nlayout(location = 4) out vec4 fa_vertex_color;\nlayout(location = 5) out float fa_pre_depth;\nlayout(location = 6) out vec3 fa_pre_r0;\nlayout(location = 7) out vec3 fa_pre_r1;\nlayout(location = 8) out vec3 fa_pre_r2;\nlayout(location = 9) out vec3 fa_vel_cur;\nlayout(location = 10) out vec3 fa_vel_prev;\nlayout(location = 9) in vec4 fa_prev_r0;\nlayout(location = 10) in vec4 fa_prev_r1;\nlayout(location = 11) in vec4 fa_prev_r2;\nlayout(location = 5) in vec4 fa_inst_m0;\nlayout(location = 6) in vec4 fa_inst_m1;\nlayout(location = 7) in vec4 fa_inst_m2;\nlayout(location = 8) in vec4 fa_inst_m3;\nlayout(location = 0) in vec3 fa_position;\nlayout(location = 1) in vec3 fa_normal;\nlayout(location = 3) in vec4 fa_tangent;\nlayout(location = 2) in vec2 fa_texcoord0;\nlayout(location = 4) in vec4 fa_color;\nvec4 fa_vtime;\n\nvoid fa_inst_begin()\n{\n}\n\nvec4 fa_time_now()\n{\n    return fa_mesh_vs_params[9];\n}\n\nVertexData fa_vertex_data(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    vec3 _97 = cross(model[1].xyz, model[2].xyz);\n    float _101 = (dot(model[0].xyz, _97) < 0.0) ? (-1.0) : 1.0;\n    return VertexData((model * vec4(position, 1.0)).xyz, (((_97 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _101, vec4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _101), texcoord0 * fa_mesh_vs_params[8].xy, color, position);\n}\n\nmat4 fa_rows_to_mat4(vec4 r0, vec4 r1, vec4 r2)\n{\n    return mat4(vec4(r0.x, r1.x, r2.x, 0.0), vec4(r0.y, r1.y, r2.y, 0.0), vec4(r0.z, r1.z, r2.z, 0.0), vec4(r0.w, r1.w, r2.w, 1.0));\n}\n\nmat4 fa_prev_model()\n{\n    vec4 param = fa_prev_r0;\n    vec4 param_1 = fa_prev_r1;\n    vec4 param_2 = fa_prev_r2;\n    return fa_rows_to_mat4(param, param_1, param_2);\n}\n\nvoid fa_prepass_vertex(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color, bool has_prev)\n{\n    bool _231;\n    if (has_prev)\n    {\n        _231 = fa_vel_params[8].x > 0.5;\n    }\n    else\n    {\n        _231 = has_prev;\n    }\n    fa_vtime = fa_time_now();\n    mat4 param = model;\n    vec3 param_1 = position;\n    vec3 param_2 = normal;\n    vec4 param_3 = tangent;\n    vec2 param_4 = texcoord0;\n    vec4 param_5 = color;\n    VertexData _246 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    vec3 _455 = _246.world_pos;\n    mat4 _250 = mat4(fa_mesh_vs_params[4], fa_mesh_vs_params[5], fa_mesh_vs_params[6], fa_mesh_vs_params[7]);\n    vec4 _257 = vec4(_455, 1.0);\n    fa_world_pos = _455;\n    fa_world_normal = _246.world_normal;\n    fa_world_tangent = _246.world_tangent;\n    fa_uv = _246.uv;\n    fa_vertex_color = _246.color;\n    fa_pre_depth = -(_250 * _257).z;\n    fa_pre_r0 = vec3(_250[0].x, _250[1].x, _250[2].x);\n    fa_pre_r1 = vec3(_250[0].y, _250[1].y, _250[2].y);\n    fa_pre_r2 = vec3(_250[0].z, _250[1].z, _250[2].z);\n    gl_Position = mat4(fa_mesh_vs_params[0], fa_mesh_vs_params[1], fa_mesh_vs_params[2], fa_mesh_vs_params[3]) * _257;\n    fa_vel_cur = vec3(0.0, 0.0, 1.0);\n    fa_vel_prev = vec3(0.0);\n    if (_231)\n    {\n        vec4 _330 = vec4(position, 1.0);\n        fa_vel_cur = vec3((mat4(fa_vel_params[0], fa_vel_params[1], fa_vel_params[2], fa_vel_params[3]) * _257).xyw);\n        fa_vel_prev = vec3((mat4(fa_vel_params[4], fa_vel_params[5], fa_vel_params[6], fa_vel_params[7]) * vec4((_455 + (fa_prev_model() * _330).xyz) - (model * _330).xyz, 1.0)).xyw);\n    }\n}\n\nvoid main()\n{\n    fa_vtime = vec4(0.0);\n    fa_inst_begin();\n    mat4 param = mat4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3);\n    vec3 param_1 = fa_position;\n    vec3 param_2 = fa_normal;\n    vec4 param_3 = fa_tangent;\n    vec2 param_4 = fa_texcoord0;\n    vec4 param_5 = fa_color;\n    bool param_6 = true;\n    fa_prepass_vertex(param, param_1, param_2, param_3, param_4, param_5, param_6);\n}\n\n",
      "fs": "#version 430\n\nstruct SurfaceInput\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 vertex_color;\n    vec3 view_dir;\n    bool front_facing;\n};\n\nstruct Surface\n{\n    vec3 albedo;\n    float alpha;\n    vec3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    vec3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    vec3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    vec3 specular_color;\n    float transmission;\n    float thickness;\n    vec3 attenuation_color;\n    float attenuation_distance;\n};\n\nuniform vec4 fa_mesh_fs_params[54];\nlayout(binding = 0) uniform sampler2D fa_tex_fa_smp;\nlayout(binding = 1) uniform sampler2D fa_normal_tex_fa_smp;\nlayout(binding = 2) uniform sampler2D fa_mr_tex_fa_smp;\nlayout(binding = 3) uniform sampler2D fa_occlusion_tex_fa_smp;\nlayout(binding = 4) uniform sampler2D fa_emissive_tex_fa_smp;\n\nlayout(location = 0) in vec3 fa_world_pos;\nlayout(location = 1) in vec3 fa_world_normal;\nlayout(location = 2) in vec4 fa_world_tangent;\nlayout(location = 3) in vec2 fa_uv;\nlayout(location = 4) in vec4 fa_vertex_color;\nlayout(location = 6) in vec3 fa_pre_r0;\nlayout(location = 7) in vec3 fa_pre_r1;\nlayout(location = 8) in vec3 fa_pre_r2;\nlayout(location = 0) out vec4 fa_frag_color;\nlayout(location = 5) in float fa_pre_depth;\nlayout(location = 9) in vec3 fa_vel_cur;\nlayout(location = 10) in vec3 fa_vel_prev;\nlayout(location = 1) out vec2 fa_frag_velocity;\n\nvoid fa_inst_load()\n{\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nvec3 fa_linear_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_tex_fix(inout vec3 c, float mode)\n{\n    if (mode > 1.5)\n    {\n        vec3 param = c;\n        vec3 _172 = fa_linear_to_srgb(param);\n        c = _172;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            vec3 param_1 = c;\n            vec3 _181 = fa_srgb_to_linear(param_1);\n            c = _181;\n        }\n    }\n    return c;\n}\n\nvec3 fa_tangent_normal(SurfaceInput i, vec3 m)\n{\n    vec3 _56;\n    if (i.front_facing)\n    {\n        _56 = i.world_normal;\n    }\n    else\n    {\n        _56 = -i.world_normal;\n    }\n    vec3 _81 = normalize(i.world_tangent.xyz - (_56 * dot(_56, i.world_tangent.xyz)));\n    vec3 _109 = normalize(((_81 * m.x) + ((cross(_56, _81) * i.world_tangent.w) * m.y)) + (_56 * m.z));\n    vec3 _112;\n    if (i.front_facing)\n    {\n        _112 = _109;\n    }\n    else\n    {\n        _112 = -_109;\n    }\n    return _112;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    vec4 base_t = texture(fa_tex_fa_smp, i.uv, fa_mesh_fs_params[12].w);\n    float param = fa_mesh_fs_params[6].w;\n    float param_1 = 1.0;\n    vec3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    vec3 _230 = fa_tex_fix(param_2, param_3);\n    vec4 _889 = base_t;\n    _889.x = _230.x;\n    _889.y = _230.y;\n    _889.z = _230.z;\n    base_t = _889;\n    vec4 _246 = (_889 * fa_mesh_fs_params[2]) * i.vertex_color;\n    vec3 _844 = i.world_normal;\n    if (fa_mesh_fs_params[6].z > 0.5)\n    {\n        float param_4 = fa_mesh_fs_params[6].w;\n        float param_5 = 16.0;\n        vec3 param_6 = texture(fa_normal_tex_fa_smp, i.uv, fa_mesh_fs_params[12].w).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        vec3 _282 = fa_tex_fix(param_6, param_7);\n        vec3 _286 = (_282 * 2.0) - vec3(1.0);\n        vec2 _291 = _286.xy * fa_mesh_fs_params[6].x;\n        vec3 _897 = _286;\n        _897.x = _291.x;\n        _897.y = _291.y;\n        SurfaceInput param_8 = i;\n        vec3 param_9 = _897;\n        _844 = fa_tangent_normal(param_8, param_9);\n    }\n    vec4 mrt = texture(fa_mr_tex_fa_smp, i.uv, fa_mesh_fs_params[12].w);\n    float param_10 = fa_mesh_fs_params[6].w;\n    float param_11 = 64.0;\n    vec3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    vec3 _322 = fa_tex_fix(param_12, param_13);\n    vec4 _900 = mrt;\n    _900.x = _322.x;\n    _900.y = _322.y;\n    _900.z = _322.z;\n    mrt = _900;\n    vec4 _354 = texture(fa_occlusion_tex_fa_smp, i.uv, fa_mesh_fs_params[12].w);\n    float param_14 = fa_mesh_fs_params[6].w;\n    float param_15 = 256.0;\n    vec3 param_16 = _354.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    vec3 _366 = fa_tex_fix(param_16, param_17);\n    float param_18 = fa_mesh_fs_params[6].w;\n    float param_19 = 4.0;\n    vec3 param_20 = texture(fa_emissive_tex_fa_smp, i.uv, fa_mesh_fs_params[12].w).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    vec3 _398 = fa_tex_fix(param_20, param_21);\n    float _849 = fa_mesh_fs_params[20].x;\n    float _850 = fa_mesh_fs_params[20].y;\n    float _853 = fa_mesh_fs_params[20].z;\n    float _852 = fa_mesh_fs_params[21].w;\n    float _855 = fa_mesh_fs_params[22].x;\n    if (fa_mesh_fs_params[22].z > 0.5)\n    {\n        if (mod(fa_mesh_fs_params[22].z, 2.0) > 0.5)\n        {\n            _849 *= _366.y;\n            _850 *= _366.z;\n            _852 *= _354.w;\n        }\n        if (fa_mesh_fs_params[22].z > 1.5)\n        {\n            _853 *= mrt.x;\n            _855 *= mrt.w;\n        }\n    }\n    return Surface(_246.xyz, _246.w, _844, clamp(fa_mesh_fs_params[5].x * _322.z, 0.0, 1.0), clamp(fa_mesh_fs_params[5].y * _322.y, 0.0500000007450580596923828125, 1.0), 1.0 + (fa_mesh_fs_params[6].y * (_366.x - 1.0)), fa_mesh_fs_params[3].xyz + (fa_mesh_fs_params[4].xyz * _398), _849, _850, fa_mesh_fs_params[21].xyz, _852, _853, fa_mesh_fs_params[20].w, _855, fa_mesh_fs_params[22].y, fa_mesh_fs_params[23].xyz, fa_mesh_fs_params[30].x, fa_mesh_fs_params[30].y, fa_mesh_fs_params[31].xyz, fa_mesh_fs_params[30].z);\n}\n\nvoid surface(SurfaceInput i, Surface s)\n{\n}\n\nvoid main()\n{\n    fa_inst_load();\n    vec3 _739 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _739 = -_739;\n    }\n    vec3 _550 = normalize(fa_mesh_fs_params[0].xyz - fa_world_pos);\n    SurfaceInput param = SurfaceInput(fa_world_pos, _739, fa_world_tangent, fa_uv, fa_vertex_color, _550, gl_FrontFacing);\n    SurfaceInput param_1 = SurfaceInput(fa_world_pos, _739, fa_world_tangent, fa_uv, fa_vertex_color, _550, gl_FrontFacing);\n    Surface param_2 = fa_standard_surface(param);\n    surface(param_1, param_2);\n    vec3 _565 = normalize(param_2.normal);\n    vec3 _580 = normalize(vec3(dot(fa_pre_r0, _565), dot(fa_pre_r1, _565), dot(fa_pre_r2, _565)));\n    float _592 = _580.z;\n    vec2 e = _580.xy / vec2((abs(_580.x) + abs(_580.y)) + abs(_592));\n    if (_592 < 0.0)\n    {\n        e = (vec2(1.0) - abs(e.yx)) * vec2((e.x >= 0.0) ? 1.0 : (-1.0), (e.y >= 0.0) ? 1.0 : (-1.0));\n    }\n    fa_frag_color = vec4(min(fa_pre_depth, 60000.0), e, 1.0);\n    vec2 motion = vec2(1024.0);\n    bool _636 = fa_vel_cur.z > 9.9999997473787516355514526367188e-06;\n    bool _643;\n    if (_636)\n    {\n        _643 = fa_vel_prev.z > 9.9999997473787516355514526367188e-06;\n    }\n    else\n    {\n        _643 = _636;\n    }\n    if (_643)\n    {\n        motion = clamp(((vec2(fa_vel_prev.x, -fa_vel_prev.y) / vec2(fa_vel_prev.z)) * 0.5) - ((vec2(fa_vel_cur.x, -fa_vel_cur.y) / vec2(fa_vel_cur.z)) * 0.5), vec2(-4.0), vec2(4.0));\n    }\n    fa_frag_velocity = motion;\n}\n\n",
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
            "inst_name": "_214",
            "glsl_uniforms": [
              {
                "type": "vec4",
                "array_count": 54,
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
      "vs": "#version 430\n\nstruct VertexData\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 color;\n    vec3 object_pos;\n};\n\nuniform vec4 fa_mesh_vs_params[11];\nuniform vec4 fa_skin[192];\nuniform vec4 fa_vel_params[9];\nlayout(binding = 0) uniform sampler2D fa_prev_pal_tex_fa_prev_pal_smp;\n\nlayout(location = 0) out vec3 fa_world_pos;\nlayout(location = 1) out vec3 fa_world_normal;\nlayout(location = 2) out vec4 fa_world_tangent;\nlayout(location = 3) out vec2 fa_uv;\nlayout(location = 4) out vec4 fa_vertex_color;\nlayout(location = 5) out float fa_pre_depth;\nlayout(location = 6) out vec3 fa_pre_r0;\nlayout(location = 7) out vec3 fa_pre_r1;\nlayout(location = 8) out vec3 fa_pre_r2;\nlayout(location = 9) out vec3 fa_vel_cur;\nlayout(location = 10) out vec3 fa_vel_prev;\nlayout(location = 11) in vec4 fa_prev_r0;\nlayout(location = 12) in vec4 fa_prev_r1;\nlayout(location = 13) in vec4 fa_prev_r2;\nlayout(location = 9) in vec4 fa_joints;\nlayout(location = 10) in vec4 fa_weights;\nlayout(location = 5) in vec4 fa_inst_m0;\nlayout(location = 6) in vec4 fa_inst_m1;\nlayout(location = 7) in vec4 fa_inst_m2;\nlayout(location = 8) in vec4 fa_inst_m3;\nlayout(location = 0) in vec3 fa_position;\nlayout(location = 1) in vec3 fa_normal;\nlayout(location = 3) in vec4 fa_tangent;\nlayout(location = 2) in vec2 fa_texcoord0;\nlayout(location = 4) in vec4 fa_color;\nvec4 fa_vtime;\n\nvoid fa_inst_begin()\n{\n}\n\nmat4 fa_skin_matrix(vec4 joints, vec4 weights)\n{\n    vec4 r0 = vec4(0.0);\n    vec4 r1 = vec4(0.0);\n    vec4 r2 = vec4(0.0);\n    for (int i = 0; i < 4; i++)\n    {\n        int _204 = int((joints[i] * 255.0) + 0.5) * 3;\n        r0 += (fa_skin[_204 * 1 + 0] * weights[i]);\n        r1 += (fa_skin[(_204 + 1) * 1 + 0] * weights[i]);\n        r2 += (fa_skin[(_204 + 2) * 1 + 0] * weights[i]);\n    }\n    return mat4(vec4(r0.x, r1.x, r2.x, 0.0), vec4(r0.y, r1.y, r2.y, 0.0), vec4(r0.z, r1.z, r2.z, 0.0), vec4(r0.w, r1.w, r2.w, 1.0));\n}\n\nvec4 fa_time_now()\n{\n    return fa_mesh_vs_params[9];\n}\n\nVertexData fa_vertex_data(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    vec3 _113 = cross(model[1].xyz, model[2].xyz);\n    float _117 = (dot(model[0].xyz, _113) < 0.0) ? (-1.0) : 1.0;\n    return VertexData((model * vec4(position, 1.0)).xyz, (((_113 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _117, vec4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _117), texcoord0 * fa_mesh_vs_params[8].xy, color, position);\n}\n\nmat4 fa_rows_to_mat4(vec4 r0, vec4 r1, vec4 r2)\n{\n    return mat4(vec4(r0.x, r1.x, r2.x, 0.0), vec4(r0.y, r1.y, r2.y, 0.0), vec4(r0.z, r1.z, r2.z, 0.0), vec4(r0.w, r1.w, r2.w, 1.0));\n}\n\nvec4 fa_prev_pal_texel(int t)\n{\n    return texelFetch(fa_prev_pal_tex_fa_prev_pal_smp, ivec2(t & 1023, t >> 10), 0);\n}\n\nmat4 fa_prev_skin_matrix(vec4 joints, vec4 weights, int base)\n{\n    vec4 r0 = vec4(0.0);\n    vec4 r1 = vec4(0.0);\n    vec4 r2 = vec4(0.0);\n    for (int i = 0; i < 4; i++)\n    {\n        int _332 = base + (int((joints[i] * 255.0) + 0.5) * 3);\n        int param = _332;\n        r0 += (fa_prev_pal_texel(param) * weights[i]);\n        int param_1 = _332 + 1;\n        r1 += (fa_prev_pal_texel(param_1) * weights[i]);\n        int param_2 = _332 + 2;\n        r2 += (fa_prev_pal_texel(param_2) * weights[i]);\n    }\n    return mat4(vec4(r0.x, r1.x, r2.x, 0.0), vec4(r0.y, r1.y, r2.y, 0.0), vec4(r0.z, r1.z, r2.z, 0.0), vec4(r0.w, r1.w, r2.w, 1.0));\n}\n\nmat4 fa_prev_model()\n{\n    vec4 param = fa_prev_r0;\n    vec4 param_1 = fa_prev_r1;\n    vec4 param_2 = fa_prev_r2;\n    vec4 param_3 = fa_joints;\n    vec4 param_4 = fa_weights;\n    int param_5 = int(fa_vel_params[8].w + 0.5);\n    return fa_rows_to_mat4(param, param_1, param_2) * fa_prev_skin_matrix(param_3, param_4, param_5);\n}\n\nvoid fa_prepass_vertex(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color, bool has_prev)\n{\n    bool _475;\n    if (has_prev)\n    {\n        _475 = fa_vel_params[8].x > 0.5;\n    }\n    else\n    {\n        _475 = has_prev;\n    }\n    fa_vtime = fa_time_now();\n    mat4 param = model;\n    vec3 param_1 = position;\n    vec3 param_2 = normal;\n    vec4 param_3 = tangent;\n    vec2 param_4 = texcoord0;\n    vec4 param_5 = color;\n    VertexData _490 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    vec3 _720 = _490.world_pos;\n    mat4 _494 = mat4(fa_mesh_vs_params[4], fa_mesh_vs_params[5], fa_mesh_vs_params[6], fa_mesh_vs_params[7]);\n    vec4 _501 = vec4(_720, 1.0);\n    fa_world_pos = _720;\n    fa_world_normal = _490.world_normal;\n    fa_world_tangent = _490.world_tangent;\n    fa_uv = _490.uv;\n    fa_vertex_color = _490.color;\n    fa_pre_depth = -(_494 * _501).z;\n    fa_pre_r0 = vec3(_494[0].x, _494[1].x, _494[2].x);\n    fa_pre_r1 = vec3(_494[0].y, _494[1].y, _494[2].y);\n    fa_pre_r2 = vec3(_494[0].z, _494[1].z, _494[2].z);\n    gl_Position = mat4(fa_mesh_vs_params[0], fa_mesh_vs_params[1], fa_mesh_vs_params[2], fa_mesh_vs_params[3]) * _501;\n    fa_vel_cur = vec3(0.0, 0.0, 1.0);\n    fa_vel_prev = vec3(0.0);\n    if (_475)\n    {\n        vec4 _574 = vec4(position, 1.0);\n        fa_vel_cur = vec3((mat4(fa_vel_params[0], fa_vel_params[1], fa_vel_params[2], fa_vel_params[3]) * _501).xyw);\n        fa_vel_prev = vec3((mat4(fa_vel_params[4], fa_vel_params[5], fa_vel_params[6], fa_vel_params[7]) * vec4((_720 + (fa_prev_model() * _574).xyz) - (model * _574).xyz, 1.0)).xyw);\n    }\n}\n\nvoid main()\n{\n    fa_vtime = vec4(0.0);\n    fa_inst_begin();\n    vec4 param = fa_joints;\n    vec4 param_1 = fa_weights;\n    mat4 param_2 = mat4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3) * fa_skin_matrix(param, param_1);\n    vec3 param_3 = fa_position;\n    vec3 param_4 = fa_normal;\n    vec4 param_5 = fa_tangent;\n    vec2 param_6 = fa_texcoord0;\n    vec4 param_7 = fa_color;\n    bool param_8 = fa_vel_params[8].z > 0.5;\n    fa_prepass_vertex(param_2, param_3, param_4, param_5, param_6, param_7, param_8);\n}\n\n",
      "fs": "#version 430\n\nstruct SurfaceInput\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 vertex_color;\n    vec3 view_dir;\n    bool front_facing;\n};\n\nstruct Surface\n{\n    vec3 albedo;\n    float alpha;\n    vec3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    vec3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    vec3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    vec3 specular_color;\n    float transmission;\n    float thickness;\n    vec3 attenuation_color;\n    float attenuation_distance;\n};\n\nuniform vec4 fa_mesh_fs_params[54];\nlayout(binding = 0) uniform sampler2D fa_tex_fa_smp;\nlayout(binding = 1) uniform sampler2D fa_normal_tex_fa_smp;\nlayout(binding = 2) uniform sampler2D fa_mr_tex_fa_smp;\nlayout(binding = 3) uniform sampler2D fa_occlusion_tex_fa_smp;\nlayout(binding = 4) uniform sampler2D fa_emissive_tex_fa_smp;\n\nlayout(location = 0) in vec3 fa_world_pos;\nlayout(location = 1) in vec3 fa_world_normal;\nlayout(location = 2) in vec4 fa_world_tangent;\nlayout(location = 3) in vec2 fa_uv;\nlayout(location = 4) in vec4 fa_vertex_color;\nlayout(location = 6) in vec3 fa_pre_r0;\nlayout(location = 7) in vec3 fa_pre_r1;\nlayout(location = 8) in vec3 fa_pre_r2;\nlayout(location = 0) out vec4 fa_frag_color;\nlayout(location = 5) in float fa_pre_depth;\nlayout(location = 9) in vec3 fa_vel_cur;\nlayout(location = 10) in vec3 fa_vel_prev;\nlayout(location = 1) out vec2 fa_frag_velocity;\n\nvoid fa_inst_load()\n{\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nvec3 fa_linear_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_tex_fix(inout vec3 c, float mode)\n{\n    if (mode > 1.5)\n    {\n        vec3 param = c;\n        vec3 _172 = fa_linear_to_srgb(param);\n        c = _172;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            vec3 param_1 = c;\n            vec3 _181 = fa_srgb_to_linear(param_1);\n            c = _181;\n        }\n    }\n    return c;\n}\n\nvec3 fa_tangent_normal(SurfaceInput i, vec3 m)\n{\n    vec3 _56;\n    if (i.front_facing)\n    {\n        _56 = i.world_normal;\n    }\n    else\n    {\n        _56 = -i.world_normal;\n    }\n    vec3 _81 = normalize(i.world_tangent.xyz - (_56 * dot(_56, i.world_tangent.xyz)));\n    vec3 _109 = normalize(((_81 * m.x) + ((cross(_56, _81) * i.world_tangent.w) * m.y)) + (_56 * m.z));\n    vec3 _112;\n    if (i.front_facing)\n    {\n        _112 = _109;\n    }\n    else\n    {\n        _112 = -_109;\n    }\n    return _112;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    vec4 base_t = texture(fa_tex_fa_smp, i.uv, fa_mesh_fs_params[12].w);\n    float param = fa_mesh_fs_params[6].w;\n    float param_1 = 1.0;\n    vec3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    vec3 _230 = fa_tex_fix(param_2, param_3);\n    vec4 _889 = base_t;\n    _889.x = _230.x;\n    _889.y = _230.y;\n    _889.z = _230.z;\n    base_t = _889;\n    vec4 _246 = (_889 * fa_mesh_fs_params[2]) * i.vertex_color;\n    vec3 _844 = i.world_normal;\n    if (fa_mesh_fs_params[6].z > 0.5)\n    {\n        float param_4 = fa_mesh_fs_params[6].w;\n        float param_5 = 16.0;\n        vec3 param_6 = texture(fa_normal_tex_fa_smp, i.uv, fa_mesh_fs_params[12].w).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        vec3 _282 = fa_tex_fix(param_6, param_7);\n        vec3 _286 = (_282 * 2.0) - vec3(1.0);\n        vec2 _291 = _286.xy * fa_mesh_fs_params[6].x;\n        vec3 _897 = _286;\n        _897.x = _291.x;\n        _897.y = _291.y;\n        SurfaceInput param_8 = i;\n        vec3 param_9 = _897;\n        _844 = fa_tangent_normal(param_8, param_9);\n    }\n    vec4 mrt = texture(fa_mr_tex_fa_smp, i.uv, fa_mesh_fs_params[12].w);\n    float param_10 = fa_mesh_fs_params[6].w;\n    float param_11 = 64.0;\n    vec3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    vec3 _322 = fa_tex_fix(param_12, param_13);\n    vec4 _900 = mrt;\n    _900.x = _322.x;\n    _900.y = _322.y;\n    _900.z = _322.z;\n    mrt = _900;\n    vec4 _354 = texture(fa_occlusion_tex_fa_smp, i.uv, fa_mesh_fs_params[12].w);\n    float param_14 = fa_mesh_fs_params[6].w;\n    float param_15 = 256.0;\n    vec3 param_16 = _354.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    vec3 _366 = fa_tex_fix(param_16, param_17);\n    float param_18 = fa_mesh_fs_params[6].w;\n    float param_19 = 4.0;\n    vec3 param_20 = texture(fa_emissive_tex_fa_smp, i.uv, fa_mesh_fs_params[12].w).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    vec3 _398 = fa_tex_fix(param_20, param_21);\n    float _849 = fa_mesh_fs_params[20].x;\n    float _850 = fa_mesh_fs_params[20].y;\n    float _853 = fa_mesh_fs_params[20].z;\n    float _852 = fa_mesh_fs_params[21].w;\n    float _855 = fa_mesh_fs_params[22].x;\n    if (fa_mesh_fs_params[22].z > 0.5)\n    {\n        if (mod(fa_mesh_fs_params[22].z, 2.0) > 0.5)\n        {\n            _849 *= _366.y;\n            _850 *= _366.z;\n            _852 *= _354.w;\n        }\n        if (fa_mesh_fs_params[22].z > 1.5)\n        {\n            _853 *= mrt.x;\n            _855 *= mrt.w;\n        }\n    }\n    return Surface(_246.xyz, _246.w, _844, clamp(fa_mesh_fs_params[5].x * _322.z, 0.0, 1.0), clamp(fa_mesh_fs_params[5].y * _322.y, 0.0500000007450580596923828125, 1.0), 1.0 + (fa_mesh_fs_params[6].y * (_366.x - 1.0)), fa_mesh_fs_params[3].xyz + (fa_mesh_fs_params[4].xyz * _398), _849, _850, fa_mesh_fs_params[21].xyz, _852, _853, fa_mesh_fs_params[20].w, _855, fa_mesh_fs_params[22].y, fa_mesh_fs_params[23].xyz, fa_mesh_fs_params[30].x, fa_mesh_fs_params[30].y, fa_mesh_fs_params[31].xyz, fa_mesh_fs_params[30].z);\n}\n\nvoid surface(SurfaceInput i, Surface s)\n{\n}\n\nvoid main()\n{\n    fa_inst_load();\n    vec3 _739 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _739 = -_739;\n    }\n    vec3 _550 = normalize(fa_mesh_fs_params[0].xyz - fa_world_pos);\n    SurfaceInput param = SurfaceInput(fa_world_pos, _739, fa_world_tangent, fa_uv, fa_vertex_color, _550, gl_FrontFacing);\n    SurfaceInput param_1 = SurfaceInput(fa_world_pos, _739, fa_world_tangent, fa_uv, fa_vertex_color, _550, gl_FrontFacing);\n    Surface param_2 = fa_standard_surface(param);\n    surface(param_1, param_2);\n    vec3 _565 = normalize(param_2.normal);\n    vec3 _580 = normalize(vec3(dot(fa_pre_r0, _565), dot(fa_pre_r1, _565), dot(fa_pre_r2, _565)));\n    float _592 = _580.z;\n    vec2 e = _580.xy / vec2((abs(_580.x) + abs(_580.y)) + abs(_592));\n    if (_592 < 0.0)\n    {\n        e = (vec2(1.0) - abs(e.yx)) * vec2((e.x >= 0.0) ? 1.0 : (-1.0), (e.y >= 0.0) ? 1.0 : (-1.0));\n    }\n    fa_frag_color = vec4(min(fa_pre_depth, 60000.0), e, 1.0);\n    vec2 motion = vec2(1024.0);\n    bool _636 = fa_vel_cur.z > 9.9999997473787516355514526367188e-06;\n    bool _643;\n    if (_636)\n    {\n        _643 = fa_vel_prev.z > 9.9999997473787516355514526367188e-06;\n    }\n    else\n    {\n        _643 = _636;\n    }\n    if (_643)\n    {\n        motion = clamp(((vec2(fa_vel_prev.x, -fa_vel_prev.y) / vec2(fa_vel_prev.z)) * 0.5) - ((vec2(fa_vel_cur.x, -fa_vel_cur.y) / vec2(fa_vel_cur.z)) * 0.5), vec2(-4.0), vec2(4.0));\n    }\n    fa_frag_velocity = motion;\n}\n\n",
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
            "inst_name": "_214",
            "glsl_uniforms": [
              {
                "type": "vec4",
                "array_count": 54,
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
