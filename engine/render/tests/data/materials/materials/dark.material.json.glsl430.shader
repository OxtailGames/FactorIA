{
  "format": "factoria.shader/1",
  "engine": "0.39.0",
  "template": "4694fb4be9bed2a7c5475af904870ae4995eb283e1c27e15e0192dfe0c2b2256",
  "slang": "glsl430",
  "params": [],
  "textures": [],
  "programs": {
    "mesh": {
      "vs": "#version 430\n\nstruct VertexData\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 color;\n    vec3 object_pos;\n};\n\nuniform vec4 fa_mesh_vs_params[11];\nlayout(location = 0) out vec3 fa_world_pos;\nlayout(location = 1) out vec3 fa_world_normal;\nlayout(location = 2) out vec4 fa_world_tangent;\nlayout(location = 3) out vec2 fa_uv;\nlayout(location = 4) out vec4 fa_vertex_color;\nlayout(location = 5) in vec4 fa_inst_m0;\nlayout(location = 6) in vec4 fa_inst_m1;\nlayout(location = 7) in vec4 fa_inst_m2;\nlayout(location = 8) in vec4 fa_inst_m3;\nlayout(location = 0) in vec3 fa_position;\nlayout(location = 1) in vec3 fa_normal;\nlayout(location = 3) in vec4 fa_tangent;\nlayout(location = 2) in vec2 fa_texcoord0;\nlayout(location = 4) in vec4 fa_color;\nlayout(location = 5) out vec3 fa_lm;\n\nvoid fa_inst_begin()\n{\n}\n\nVertexData fa_vertex_data(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    vec3 _69 = cross(model[1].xyz, model[2].xyz);\n    float _75 = (dot(model[0].xyz, _69) < 0.0) ? (-1.0) : 1.0;\n    return VertexData((model * vec4(position, 1.0)).xyz, (((_69 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _75, vec4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _75), texcoord0 * fa_mesh_vs_params[8].xy, color, position);\n}\n\nvoid fa_shade_vertex(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    mat4 param = model;\n    vec3 param_1 = position;\n    vec3 param_2 = normal;\n    vec4 param_3 = tangent;\n    vec2 param_4 = texcoord0;\n    vec4 param_5 = color;\n    VertexData _160 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    vec3 _267 = _160.world_pos;\n    fa_world_pos = _267;\n    fa_world_normal = _160.world_normal;\n    fa_world_tangent = _160.world_tangent;\n    fa_uv = _160.uv;\n    fa_vertex_color = _160.color;\n    gl_Position = mat4(fa_mesh_vs_params[0], fa_mesh_vs_params[1], fa_mesh_vs_params[2], fa_mesh_vs_params[3]) * vec4(_267, 1.0);\n}\n\nvoid main()\n{\n    fa_inst_begin();\n    mat4 param = mat4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3);\n    vec3 param_1 = fa_position;\n    vec3 param_2 = fa_normal;\n    vec4 param_3 = fa_tangent;\n    vec2 param_4 = fa_texcoord0;\n    vec4 param_5 = fa_color;\n    fa_shade_vertex(param, param_1, param_2, param_3, param_4, param_5);\n    fa_lm = vec3(0.0);\n}\n\n",
      "fs": "#version 430\n\nstruct SurfaceInput\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 vertex_color;\n    vec3 view_dir;\n    bool front_facing;\n};\n\nstruct LightSample\n{\n    vec3 direction;\n    vec3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct Surface\n{\n    vec3 albedo;\n    float alpha;\n    vec3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    vec3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    vec3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    vec3 specular_color;\n    float transmission;\n    float thickness;\n    vec3 attenuation_color;\n    float attenuation_distance;\n};\n\nuniform vec4 fa_mesh_fs_params[54];\nuniform vec4 fa_shadows[30];\nlayout(binding = 0) uniform sampler2D fa_light_tex_fa_shadow_smp;\nlayout(binding = 1) uniform sampler2D fa_tex_fa_smp;\nlayout(binding = 2) uniform sampler2D fa_normal_tex_fa_smp;\nlayout(binding = 3) uniform sampler2D fa_mr_tex_fa_smp;\nlayout(binding = 4) uniform sampler2D fa_occlusion_tex_fa_smp;\nlayout(binding = 5) uniform sampler2D fa_emissive_tex_fa_smp;\nlayout(binding = 6) uniform sampler2D fa_decal_tex_fa_env_smp;\nlayout(binding = 7) uniform sampler2D fa_lightmap_fa_env_smp;\nlayout(binding = 8) uniform sampler2D fa_probe_atlas_fa_env_smp;\nlayout(binding = 9) uniform sampler2D fa_light_atlas_fa_env_smp;\nlayout(binding = 10) uniform sampler2D fa_screen_tex_fa_shadow_smp;\nlayout(binding = 11) uniform sampler2D fa_shadow_tex_fa_shadow_smp;\n\nlayout(location = 0) in vec3 fa_world_pos;\nlayout(location = 5) in vec3 fa_lm;\nlayout(location = 1) in vec3 fa_world_normal;\nlayout(location = 2) in vec4 fa_world_tangent;\nlayout(location = 3) in vec2 fa_uv;\nlayout(location = 4) in vec4 fa_vertex_color;\nlayout(location = 0) out vec4 fa_frag_color;\nfloat fa_rt_slope;\nvec3 fa_light_tint;\nbool fa_light_is_area;\nint fa_cl_ndir;\nint fa_cl_slot;\nint fa_cl_local;\n\nvoid fa_inst_load()\n{\n}\n\nvec4 fa_light_texel(int t)\n{\n    return texelFetch(fa_light_tex_fa_shadow_smp, ivec2(t & 1023, t >> 10), 0);\n}\n\nvec4 fa_cluster_texel(vec3 world_pos)\n{\n    bool _1361 = fa_mesh_fs_params[19].x < 0.0;\n    bool _1368;\n    if (!_1361)\n    {\n        _1368 = fa_mesh_fs_params[19].w < 1.0;\n    }\n    else\n    {\n        _1368 = _1361;\n    }\n    bool _1376;\n    if (!_1368)\n    {\n        _1376 = fa_mesh_fs_params[18].x < 1.0;\n    }\n    else\n    {\n        _1376 = _1368;\n    }\n    bool _1383;\n    if (!_1376)\n    {\n        _1383 = fa_mesh_fs_params[18].y < 1.0;\n    }\n    else\n    {\n        _1383 = _1376;\n    }\n    bool _1390;\n    if (!_1383)\n    {\n        _1390 = fa_mesh_fs_params[19].y < 1.0;\n    }\n    else\n    {\n        _1390 = _1383;\n    }\n    if (_1390)\n    {\n        return vec4(0.0);\n    }\n    vec4 _1400 = vec4(world_pos, 1.0);\n    float _1406 = dot(fa_mesh_fs_params[16], _1400);\n    if (!(_1406 > 9.9999999747524270787835121154785e-07))\n    {\n        return vec4(0.0);\n    }\n    vec2 _1428 = vec2(dot(fa_mesh_fs_params[14], _1400), dot(fa_mesh_fs_params[15], _1400)) / vec2(_1406);\n    int _1432 = int(fa_mesh_fs_params[18].x);\n    int _1436 = int(fa_mesh_fs_params[18].y);\n    int param = (int(fa_mesh_fs_params[19].x) + (((clamp(int(floor(log2(max(dot(fa_mesh_fs_params[17].xyz, world_pos) + fa_mesh_fs_params[17].w, fa_mesh_fs_params[18].w) / fa_mesh_fs_params[18].w) * fa_mesh_fs_params[18].z)), 0, int(fa_mesh_fs_params[19].y) - 1) * _1436) + clamp(int(floor(((_1428.y * 0.5) + 0.5) * fa_mesh_fs_params[18].y)), 0, _1436 - 1)) * _1432)) + clamp(int(floor(((_1428.x * 0.5) + 0.5) * fa_mesh_fs_params[18].x)), 0, _1432 - 1);\n    return fa_light_texel(param);\n}\n\nivec2 fa_cluster_lookup(vec3 world_pos)\n{\n    vec3 param = world_pos;\n    vec4 _1512 = fa_cluster_texel(param);\n    return ivec2(int(_1512.x), int(_1512.y));\n}\n\nvoid fa_cluster_begin(vec3 world_pos)\n{\n    float _4322 = dot(fa_mesh_fs_params[29].xyz, world_pos) + fa_mesh_fs_params[29].w;\n    float _4325 = fwidth(_4322);\n    bool _4328 = fa_mesh_fs_params[25].y > 0.5;\n    bool _4335;\n    if (!_4328)\n    {\n        _4335 = fa_mesh_fs_params[25].w > 0.5;\n    }\n    else\n    {\n        _4335 = _4328;\n    }\n    if (_4335)\n    {\n        fa_rt_slope = min(1.5 * _4325, 0.100000001490116119384765625 * _4322);\n    }\n    fa_cl_ndir = int(fa_mesh_fs_params[19].z);\n    vec3 param = world_pos;\n    ivec2 _4351 = fa_cluster_lookup(param);\n    fa_cl_slot = _4351.x;\n    fa_cl_local = _4351.y;\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_linear_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvec3 fa_tex_fix(inout vec3 c, float mode)\n{\n    if (mode > 1.5)\n    {\n        vec3 param = c;\n        vec3 _4556 = fa_linear_to_srgb(param);\n        c = _4556;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            vec3 param_1 = c;\n            vec3 _4564 = fa_srgb_to_linear(param_1);\n            c = _4564;\n        }\n    }\n    return c;\n}\n\nvec3 fa_tangent_normal(SurfaceInput i, vec3 m)\n{\n    vec3 _316;\n    if (i.front_facing)\n    {\n        _316 = i.world_normal;\n    }\n    else\n    {\n        _316 = -i.world_normal;\n    }\n    vec3 _340 = normalize(i.world_tangent.xyz - (_316 * dot(_316, i.world_tangent.xyz)));\n    vec3 _367 = normalize(((_340 * m.x) + ((cross(_316, _340) * i.world_tangent.w) * m.y)) + (_316 * m.z));\n    vec3 _370;\n    if (i.front_facing)\n    {\n        _370 = _367;\n    }\n    else\n    {\n        _370 = -_367;\n    }\n    return _370;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    vec4 base_t = texture(fa_tex_fa_smp, i.uv, fa_mesh_fs_params[12].w);\n    float param = fa_mesh_fs_params[6].w;\n    float param_1 = 1.0;\n    vec3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    vec3 _4596 = fa_tex_fix(param_2, param_3);\n    vec4 _6475 = base_t;\n    _6475.x = _4596.x;\n    _6475.y = _4596.y;\n    _6475.z = _4596.z;\n    base_t = _6475;\n    vec4 _4610 = (_6475 * fa_mesh_fs_params[2]) * i.vertex_color;\n    vec3 _6288 = i.world_normal;\n    if (fa_mesh_fs_params[6].z > 0.5)\n    {\n        float param_4 = fa_mesh_fs_params[6].w;\n        float param_5 = 16.0;\n        vec3 param_6 = texture(fa_normal_tex_fa_smp, i.uv, fa_mesh_fs_params[12].w).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        vec3 _4644 = fa_tex_fix(param_6, param_7);\n        vec3 _4647 = (_4644 * 2.0) - vec3(1.0);\n        vec2 _4652 = _4647.xy * fa_mesh_fs_params[6].x;\n        vec3 _6483 = _4647;\n        _6483.x = _4652.x;\n        _6483.y = _4652.y;\n        SurfaceInput param_8 = i;\n        vec3 param_9 = _6483;\n        _6288 = fa_tangent_normal(param_8, param_9);\n    }\n    vec4 mrt = texture(fa_mr_tex_fa_smp, i.uv, fa_mesh_fs_params[12].w);\n    float param_10 = fa_mesh_fs_params[6].w;\n    float param_11 = 64.0;\n    vec3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    vec3 _4682 = fa_tex_fix(param_12, param_13);\n    vec4 _6486 = mrt;\n    _6486.x = _4682.x;\n    _6486.y = _4682.y;\n    _6486.z = _4682.z;\n    mrt = _6486;\n    vec4 _4712 = texture(fa_occlusion_tex_fa_smp, i.uv, fa_mesh_fs_params[12].w);\n    float param_14 = fa_mesh_fs_params[6].w;\n    float param_15 = 256.0;\n    vec3 param_16 = _4712.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    vec3 _4723 = fa_tex_fix(param_16, param_17);\n    float param_18 = fa_mesh_fs_params[6].w;\n    float param_19 = 4.0;\n    vec3 param_20 = texture(fa_emissive_tex_fa_smp, i.uv, fa_mesh_fs_params[12].w).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    vec3 _4755 = fa_tex_fix(param_20, param_21);\n    float _6293 = fa_mesh_fs_params[20].x;\n    float _6294 = fa_mesh_fs_params[20].y;\n    float _6297 = fa_mesh_fs_params[20].z;\n    float _6296 = fa_mesh_fs_params[21].w;\n    float _6299 = fa_mesh_fs_params[22].x;\n    if (fa_mesh_fs_params[22].z > 0.5)\n    {\n        if (mod(fa_mesh_fs_params[22].z, 2.0) > 0.5)\n        {\n            _6293 *= _4723.y;\n            _6294 *= _4723.z;\n            _6296 *= _4712.w;\n        }\n        if (fa_mesh_fs_params[22].z > 1.5)\n        {\n            _6297 *= mrt.x;\n            _6299 *= mrt.w;\n        }\n    }\n    return Surface(_4610.xyz, _4610.w, _6288, clamp(fa_mesh_fs_params[5].x * _4682.z, 0.0, 1.0), clamp(fa_mesh_fs_params[5].y * _4682.y, 0.0500000007450580596923828125, 1.0), 1.0 + (fa_mesh_fs_params[6].y * (_4723.x - 1.0)), fa_mesh_fs_params[3].xyz + (fa_mesh_fs_params[4].xyz * _4755), _6293, _6294, fa_mesh_fs_params[21].xyz, _6296, _6297, fa_mesh_fs_params[20].w, _6299, fa_mesh_fs_params[22].y, fa_mesh_fs_params[23].xyz, fa_mesh_fs_params[30].x, fa_mesh_fs_params[30].y, fa_mesh_fs_params[31].xyz, fa_mesh_fs_params[30].z);\n}\n\nvoid surface(SurfaceInput i, Surface s)\n{\n}\n\nvec4 fa_decal_tile(vec4 rect, vec2 uv, vec2 atlas, vec2 ddx, vec2 ddy)\n{\n    vec2 _1592 = rect.zw - rect.xy;\n    vec2 _1596 = _1592 * atlas;\n    vec2 _1600 = ddx * _1596;\n    vec2 _1604 = ddy * _1596;\n    return textureLod(fa_decal_tex_fa_env_smp, rect.xy + (clamp(uv, vec2(0.0), vec2(1.0)) * _1592), clamp(0.5 * log2(max(max(dot(_1600, _1600), dot(_1604, _1604)), 9.9999999392252902907785028219223e-09)), 0.0, 3.0));\n}\n\nvec3 fa_dc_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_dc_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvoid fa_apply_decals(vec3 world_pos, vec3 geo_normal, inout vec3 albedo, inout vec3 normal)\n{\n    bool _1637 = fa_mesh_fs_params[10].y < 0.5;\n    bool _1644;\n    if (!_1637)\n    {\n        _1644 = fa_mesh_fs_params[10].w < 0.5;\n    }\n    else\n    {\n        _1644 = _1637;\n    }\n    if (_1644)\n    {\n        return;\n    }\n    vec3 _1650 = dFdx(world_pos);\n    vec3 _1653 = dFdy(world_pos);\n    vec3 param = world_pos;\n    vec4 _1657 = fa_cluster_texel(param);\n    int _1661 = int(_1657.w);\n    if (_1661 < 1)\n    {\n        return;\n    }\n    int _1671 = int(fa_mesh_fs_params[10].y + 0.5);\n    int param_1 = _1671;\n    vec4 _1675 = fa_light_texel(param_1);\n    vec2 _1678 = _1675.yz;\n    int _1682 = int(_1675.w);\n    int param_2 = _1671 + 1;\n    vec4 _1687 = fa_light_texel(param_2);\n    float _1688 = _1687.x;\n    int _1694 = int(fa_mesh_fs_params[10].w + 0.5) - 1;\n    int _1698 = int(_1657.z);\n    vec3 _1963;\n    for (int k = 0; k < _1661; k++)\n    {\n        int _1711 = _1698 + k;\n        int param_3 = _1682 + (_1711 >> 2);\n        int _1728 = (_1671 + 2) + (int(fa_light_texel(param_3)[_1711 & 3]) * 7);\n        int param_4 = _1728 + 6;\n        vec4 _1733 = fa_light_texel(param_4);\n        if (((int(_1733.w + 0.5) >> _1694) & 1) == 0)\n        {\n            continue;\n        }\n        int param_5 = _1728;\n        vec4 _1748 = fa_light_texel(param_5);\n        int param_6 = _1728 + 1;\n        vec4 _1753 = fa_light_texel(param_6);\n        int param_7 = _1728 + 2;\n        vec4 _1758 = fa_light_texel(param_7);\n        vec3 _1761 = _1748.xyz;\n        float _1766 = dot(_1761, world_pos) + _1748.w;\n        vec3 _1768 = _1753.xyz;\n        float _1773 = dot(_1768, world_pos) + _1753.w;\n        vec3 _1775 = _1758.xyz;\n        float _1780 = dot(_1775, world_pos) + _1758.w;\n        bool _1785 = abs(_1766) > 0.5;\n        bool _1793;\n        if (!_1785)\n        {\n            _1793 = abs(_1773) > 0.5;\n        }\n        else\n        {\n            _1793 = _1785;\n        }\n        bool _1801;\n        if (!_1793)\n        {\n            _1801 = abs(_1780) > 0.5;\n        }\n        else\n        {\n            _1801 = _1793;\n        }\n        if (_1801)\n        {\n            continue;\n        }\n        float _1816 = clamp(dot(geo_normal, normalize(_1775)) * _1733.z, 0.0, 1.0);\n        if (_1816 <= 0.0)\n        {\n            continue;\n        }\n        float _1836 = (clamp((0.5 - abs(_1780)) * 10.0, 0.0, 1.0) * _1816) * _1733.x;\n        vec2 _1844 = vec2(_1766 + 0.5, 0.5 - _1773);\n        vec2 _1854 = vec2(dot(_1761, _1650), dot(_1768, _1650));\n        vec2 _1864 = vec2(dot(_1761, _1653), dot(_1768, _1653));\n        int param_8 = _1728 + 5;\n        vec4 _1869 = fa_light_texel(param_8);\n        int param_9 = _1728 + 3;\n        vec4 _1874 = fa_light_texel(param_9);\n        int param_10 = _1728 + 4;\n        vec4 _1879 = fa_light_texel(param_10);\n        float tex_a = 1.0;\n        vec3 col = _1869.xyz;\n        bool _1889 = _1874.z > _1874.x;\n        if (_1889)\n        {\n            vec4 param_11 = _1874;\n            vec2 param_12 = _1844;\n            vec2 param_13 = _1678;\n            vec2 param_14 = _1854;\n            vec2 param_15 = _1864;\n            vec4 tx = fa_decal_tile(param_11, param_12, param_13, param_14, param_15);\n            if ((_1688 > 0.5) && (_1688 < 1.5))\n            {\n                vec3 param_16 = tx.xyz;\n                vec3 _1915 = fa_dc_to_linear(param_16);\n                vec4 _6376 = tx;\n                _6376.x = _1915.x;\n                _6376.y = _1915.y;\n                _6376.z = _1915.z;\n                tx = _6376;\n            }\n            col *= tx.xyz;\n            tex_a = tx.w;\n        }\n        albedo = mix(albedo, col, vec3(clamp((_1836 * tex_a) * _1869.w, 0.0, 1.0)));\n        if (_1879.z > _1879.x)\n        {\n            vec4 param_17 = _1879;\n            vec2 param_18 = _1844;\n            vec2 param_19 = _1678;\n            vec2 param_20 = _1854;\n            vec2 param_21 = _1864;\n            vec4 _1959 = fa_decal_tile(param_17, param_18, param_19, param_20, param_21);\n            if (_1688 > 1.5)\n            {\n                vec3 param_22 = _1959.xyz;\n                vec3 _1969 = fa_dc_to_srgb(param_22);\n                _1963 = _1969;\n            }\n            else\n            {\n                _1963 = _1959.xyz;\n            }\n            vec3 _1978 = (_1963 * 2.0) - vec3(1.0);\n            vec2 _1983 = _1978.xy * _1733.y;\n            vec3 _2005 = (normalize(_1761) * _1983.x) + (normalize(_1768) * _1983.y);\n            vec3 _2008 = normalize(normal);\n            normal = normalize(mix(_2008, normalize((_2008 * max(_1978.z, 0.0500000007450580596923828125)) + (_2005 - (_2008 * dot(_2008, _2005)))), vec3(clamp(_1836 * (_1889 ? tex_a : 1.0), 0.0, 1.0))));\n        }\n    }\n}\n\nvec2 fa_atlas_size()\n{\n    return vec2(textureSize(fa_probe_atlas_fa_env_smp, 0));\n}\n\nvec3 fa_probe_sh_coef(vec2 origin, float res, int k)\n{\n    vec3 v = textureLod(fa_probe_atlas_fa_env_smp, (origin + vec2(float(k) + 0.5, res + 2.5)) / fa_atlas_size(), 0.0).xyz;\n    if (fa_mesh_fs_params[41].y > 0.5)\n    {\n        v = ((v * 255.0) - vec3(128.0)) * 0.03149606287479400634765625;\n    }\n    return v;\n}\n\nvec3 fa_sh_eval(vec3 c[9], vec3 n)\n{\n    vec3 _3785 = max((((c[0] * 0.2820948064327239990234375) + (((c[1] * (0.3257350027561187744140625 * n.y)) + (c[2] * (0.3257350027561187744140625 * n.z))) + (c[3] * (0.3257350027561187744140625 * n.x)))) + (((c[4] * ((0.2731371223926544189453125 * n.x) * n.y)) + (c[5] * ((0.2731371223926544189453125 * n.y) * n.z))) + (c[6] * (0.078847892582416534423828125 * (((3.0 * n.z) * n.z) - 1.0))))) + ((c[7] * ((0.2731371223926544189453125 * n.x) * n.z)) + (c[8] * (0.13656856119632720947265625 * ((n.x * n.x) - (n.y * n.y))))), vec3(0.0));\n    return _3785;\n}\n\nvec3 fa_ambient_light(vec3 n)\n{\n    float _3894 = (1.0 - fa_mesh_fs_params[42].w) - fa_mesh_fs_params[47].w;\n    vec3 amb = vec3(0.0);\n    bool _3900 = fa_mesh_fs_params[11].w > 0.5;\n    vec3 c[9];\n    for (int k = 0; k < 9; k++)\n    {\n        c[k] = vec3(0.0);\n    }\n    if (_3894 > 0.0005000000237487256526947021484375)\n    {\n        if (_3900)\n        {\n            for (int k_1 = 0; k_1 < 9; k_1++)\n            {\n                vec2 param = fa_mesh_fs_params[41].zw;\n                float param_1 = 128.0;\n                int param_2 = k_1;\n                c[k_1] = fa_probe_sh_coef(param, param_1, param_2) * _3894;\n            }\n        }\n        else\n        {\n            amb = fa_mesh_fs_params[1].xyz * _3894;\n        }\n    }\n    bool _3952 = fa_mesh_fs_params[42].w > 0.0;\n    if (_3952)\n    {\n        for (int k_2 = 0; k_2 < 9; k_2++)\n        {\n            vec2 param_3 = fa_mesh_fs_params[42].xy;\n            float param_4 = fa_mesh_fs_params[42].z;\n            int param_5 = k_2;\n            c[k_2] += (fa_probe_sh_coef(param_3, param_4, param_5) * fa_mesh_fs_params[42].w);\n        }\n    }\n    bool _3983 = fa_mesh_fs_params[47].w > 0.0;\n    if (_3983)\n    {\n        for (int k_3 = 0; k_3 < 9; k_3++)\n        {\n            vec2 param_6 = fa_mesh_fs_params[47].xy;\n            float param_7 = fa_mesh_fs_params[47].z;\n            int param_8 = k_3;\n            c[k_3] += (fa_probe_sh_coef(param_6, param_7, param_8) * fa_mesh_fs_params[47].w);\n        }\n    }\n    if ((_3900 || _3952) || _3983)\n    {\n        vec3 param_9[9] = c;\n        vec3 param_10 = n;\n        amb += fa_sh_eval(param_9, param_10);\n    }\n    return amb;\n}\n\nvec4 fa_gi_fetch(vec2 texel)\n{\n    return textureLod(fa_probe_atlas_fa_env_smp, texel / fa_atlas_size(), 0.0);\n}\n\nvec2 fa_oct_encode(vec3 d)\n{\n    vec3 _3805 = d / vec3(max((abs(d.x) + abs(d.y)) + abs(d.z), 9.9999999600419720025001879548654e-13));\n    float _3808 = _3805.x;\n    float _3810 = _3805.z;\n    vec2 e = vec2(_3808, _3810);\n    if (_3805.y < 0.0)\n    {\n        e = vec2((1.0 - abs(_3810)) * ((_3808 < 0.0) ? (-1.0) : 1.0), (1.0 - abs(_3808)) * ((_3810 < 0.0) ? (-1.0) : 1.0));\n    }\n    return e;\n}\n\nvec3 fa_gi_grid(int rec, vec3 n, vec3 v, out float cover)\n{\n    cover = 0.0;\n    int param = rec;\n    vec4 _4869 = fa_light_texel(param);\n    int param_1 = rec + 1;\n    vec4 _4874 = fa_light_texel(param_1);\n    int param_2 = rec + 2;\n    vec4 _4879 = fa_light_texel(param_2);\n    int param_3 = rec + 3;\n    vec4 _4884 = fa_light_texel(param_3);\n    bool _4887 = _4884.z < 0.5;\n    bool _4895;\n    if (!_4887)\n    {\n        _4895 = fa_atlas_size().y < 1155.0;\n    }\n    else\n    {\n        _4895 = _4887;\n    }\n    if (_4895)\n    {\n        return vec3(0.0);\n    }\n    float _4902 = max(_4869.w, 9.9999997473787516355514526367188e-05);\n    vec3 _4905 = _4874.xyz;\n    vec3 _4909 = _4869.xyz;\n    vec3 _4913 = (fa_world_pos - _4909) / vec3(_4902);\n    vec3 _4922 = min(_4913 + vec3(0.5), (_4905 - vec3(0.5)) - _4913);\n    float _4931 = min(_4922.x, min(_4922.y, _4922.z));\n    if (!(_4931 > 0.0))\n    {\n        return vec3(0.0);\n    }\n    vec3 _4946 = _4905 - vec3(1.0);\n    vec3 _4947 = clamp(_4913, vec3(0.0), _4946);\n    vec3 _4955 = min(floor(_4947), max(_4905 - vec3(2.0), vec3(0.0)));\n    vec3 _4959 = _4947 - _4955;\n    vec3 _4971 = fa_world_pos + (((n * 0.800000011920928955078125) + (v * 0.20000000298023223876953125)) * (0.20000000298023223876953125 * _4902));\n    int _4976 = int(_4879.y + 0.5);\n    float _4981 = 0.3257350027561187744140625 * n.y;\n    float _4985 = 0.3257350027561187744140625 * n.z;\n    float _4989 = 0.3257350027561187744140625 * n.x;\n    float _4996 = (0.2731371223926544189453125 * n.x) * n.y;\n    float _5003 = (0.2731371223926544189453125 * n.y) * n.z;\n    float _5012 = 0.078847892582416534423828125 * (((3.0 * n.z) * n.z) - 1.0);\n    float _5019 = (0.2731371223926544189453125 * n.x) * n.z;\n    float _5032 = 0.13656856119632720947265625 * ((n.x * n.x) - (n.y * n.y));\n    vec3 acc = vec3(0.0);\n    float wsum = 0.0;\n    int _5039 = 8 + int(_4884.w);\n    float _5066;\n    float _5079;\n    float _5093;\n    for (int k = 0; k < _5039; k++)\n    {\n        float _5052 = float(k & 1);\n        float _5056 = float((k >> 1) & 1);\n        float _5060 = float((k >> 2) & 1);\n        if (_5052 > 0.5)\n        {\n            _5066 = _4959.x;\n        }\n        else\n        {\n            _5066 = 1.0 - _4959.x;\n        }\n        if (_5056 > 0.5)\n        {\n            _5079 = _4959.y;\n        }\n        else\n        {\n            _5079 = 1.0 - _4959.y;\n        }\n        if (_5060 > 0.5)\n        {\n            _5093 = _4959.z;\n        }\n        else\n        {\n            _5093 = 1.0 - _4959.z;\n        }\n        float _5103 = (_5066 * _5079) * _5093;\n        if (!(_5103 > 0.0))\n        {\n            continue;\n        }\n        vec3 _5116 = min(_4955 + vec3(_5052, _5056, _5060), _4946);\n        int _5136 = int(((_4879.x + _5116.x) + (_4874.x * (_5116.y + (_4874.y * _5116.z)))) + 0.5);\n        vec2 _5151 = vec2(float(_5136 % _4976) * 10.0, 1024.0 + (float(_5136 / _4976) * 11.0));\n        vec2 param_4 = _5151 + vec2(9.5, 10.5);\n        vec4 _5159 = fa_gi_fetch(param_4);\n        bool _5162 = _5159.y < 0.5;\n        bool _5171;\n        if (!_5162)\n        {\n            _5171 = _5159.x > _4884.y;\n        }\n        else\n        {\n            _5171 = _5162;\n        }\n        if (_5171)\n        {\n            continue;\n        }\n        vec3 _5183 = _4971 - (_4909 + (_5116 * _4902));\n        float _5186 = length(_5183);\n        vec3 _5192 = _5183 / vec3(max(_5186, 9.9999997473787516355514526367188e-05));\n        float _5202 = max(9.9999997473787516355514526367188e-05, (dot(-_5192, n) + 1.0) * 0.5);\n        float w = _5103 * (_5202 * _5202);\n        vec3 param_5 = _5192;\n        vec2 param_6 = (_5151 + vec2(1.0)) + (((fa_oct_encode(param_5) * 0.5) + vec2(0.5)) * 8.0);\n        vec4 _5222 = fa_gi_fetch(param_6);\n        float _5229 = _5186 / max(_4879.z, 9.9999997473787516355514526367188e-05);\n        float _5232 = _5222.x;\n        if (_5229 > _5232)\n        {\n            float _5245 = max(_5222.y - (_5232 * _5232), 0.0);\n            float _5250 = _5229 - _5232;\n            float _5259 = _5245 / max(_5245 + (_5250 * _5250), 9.9999999600419720025001879548654e-13);\n            w *= ((_5259 * _5259) * _5259);\n        }\n        if (!(w > 0.0))\n        {\n            continue;\n        }\n        vec2 param_7 = _5151 + vec2(0.5, 10.5);\n        vec2 param_8 = _5151 + vec2(1.5, 10.5);\n        vec2 param_9 = _5151 + vec2(2.5, 10.5);\n        vec2 param_10 = _5151 + vec2(3.5, 10.5);\n        vec2 param_11 = _5151 + vec2(4.5, 10.5);\n        vec2 param_12 = _5151 + vec2(5.5, 10.5);\n        vec2 param_13 = _5151 + vec2(6.5, 10.5);\n        vec2 param_14 = _5151 + vec2(7.5, 10.5);\n        vec2 param_15 = _5151 + vec2(8.5, 10.5);\n        acc += ((((((((((fa_gi_fetch(param_7).xyz * 0.2820948064327239990234375) + (fa_gi_fetch(param_8).xyz * _4981)) + (fa_gi_fetch(param_9).xyz * _4985)) + (fa_gi_fetch(param_10).xyz * _4989)) + (fa_gi_fetch(param_11).xyz * _4996)) + (fa_gi_fetch(param_12).xyz * _5003)) + (fa_gi_fetch(param_13).xyz * _5012)) + (fa_gi_fetch(param_14).xyz * _5019)) + (fa_gi_fetch(param_15).xyz * _5032)) * w);\n        wsum += w;\n    }\n    if (!(wsum > 9.9999997473787516355514526367188e-06))\n    {\n        return vec3(0.0);\n    }\n    cover = smoothstep(0.0, 1.0, clamp(_4931 * 2.0, 0.0, 1.0)) * smoothstep(0.0, 0.0199999995529651641845703125, wsum);\n    float _5387;\n    if (fa_mesh_fs_params[52].z > 0.5)\n    {\n        _5387 = _4884.x;\n    }\n    else\n    {\n        _5387 = 1.0;\n    }\n    return max(acc / vec3(wsum), vec3(0.0)) * (_4879.w * _5387);\n}\n\nvec3 fa_gi_light(vec3 n, inout float left)\n{\n    left = 1.0;\n    vec3 acc = vec3(0.0);\n    vec3 _5411 = normalize(fa_mesh_fs_params[0].xyz - fa_world_pos);\n    int _5416 = int(fa_mesh_fs_params[52].x + 0.5);\n    int _5421 = int(fa_mesh_fs_params[52].y + 0.5);\n    float param_3;\n    for (int k = 0; (k < _5421) && (k < 8); k++)\n    {\n        int param = _5416 + (4 * k);\n        vec3 param_1 = n;\n        vec3 param_2 = _5411;\n        vec3 _5446 = fa_gi_grid(param, param_1, param_2, param_3);\n        float _5451 = param_3 * left;\n        acc += (_5446 * _5451);\n        left -= _5451;\n        if (left < 0.001000000047497451305389404296875)\n        {\n            left = 0.0;\n            break;\n        }\n    }\n    return acc;\n}\n\nvec3 fa_realtime_or_ambient(vec3 n)\n{\n    vec3 gi = vec3(0.0);\n    float left = 1.0;\n    if (fa_mesh_fs_params[52].y > 0.5)\n    {\n        vec3 param = n;\n        float param_1;\n        vec3 _5480 = fa_gi_light(param, param_1);\n        left = param_1;\n        gi = _5480;\n    }\n    if (left <= 0.0)\n    {\n        return gi;\n    }\n    vec3 param_2 = n;\n    return gi + (fa_ambient_light(param_2) * left);\n}\n\nvec3 fa_indirect_diffuse(vec3 n)\n{\n    if (fa_lm.z > 0.5)\n    {\n        return textureLod(fa_lightmap_fa_env_smp, fa_lm.xy, 0.0).xyz;\n    }\n    if (fa_mesh_fs_params[53].x > 0.5)\n    {\n        vec4 _5522 = vec4(fa_world_pos, 1.0);\n        vec2 _5541 = vec2(dot(fa_mesh_fs_params[26], _5522), dot(fa_mesh_fs_params[27], _5522)) / vec2(max(dot(fa_mesh_fs_params[28], _5522), 9.9999997473787516355514526367188e-05));\n        float _5550;\n        if (fa_mesh_fs_params[24].y > 0.5)\n        {\n            _5550 = (_5541.y * 0.5) + 0.5;\n        }\n        else\n        {\n            _5550 = 0.5 - (_5541.y * 0.5);\n        }\n        return texelFetch(fa_lightmap_fa_env_smp, clamp(ivec2(vec2((_5541.x * 0.5) + 0.5, _5550) * fa_mesh_fs_params[24].zw), ivec2(0), ivec2(fa_mesh_fs_params[24].zw) - ivec2(1)), 0).xyz;\n    }\n    if (fa_mesh_fs_params[32].w > 0.0)\n    {\n        vec3 c[9];\n        for (int k = 0; k < 9; k++)\n        {\n            c[k] = fa_mesh_fs_params[k * 1 + 32].xyz;\n        }\n        vec3 param = n;\n        vec3 param_1[9] = c;\n        vec3 param_2 = n;\n        return mix(fa_ambient_light(param), fa_sh_eval(param_1, param_2), vec3(clamp(fa_mesh_fs_params[32].w, 0.0, 1.0)));\n    }\n    vec3 param_3 = n;\n    return fa_realtime_or_ambient(param_3);\n}\n\nint fa_cluster_index(int slot, int n)\n{\n    int param = (int(fa_mesh_fs_params[19].x) + int(fa_mesh_fs_params[19].w)) + ((slot + n) >> 2);\n    vec4 t = fa_light_texel(param);\n    return int(t[(slot + n) & 3]);\n}\n\nint fa_cl_light(int n)\n{\n    if (n < fa_cl_ndir)\n    {\n        return n;\n    }\n    int param = fa_cl_slot;\n    int param_1 = n - fa_cl_ndir;\n    return fa_cluster_index(param, param_1);\n}\n\nint fa_light_base(int li)\n{\n    return li * ((fa_mesh_fs_params[1].w > 4.5) ? 8 : 4);\n}\n\nbool fa_light_baked(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 3;\n    return fa_light_texel(param_1).w > 0.5;\n}\n\nfloat fa_baked_keep(int li)\n{\n    float _4292;\n    if (fa_lm.z > 0.5)\n    {\n        _4292 = 0.0;\n    }\n    else\n    {\n        _4292 = 1.0 - clamp(fa_mesh_fs_params[32].w, 0.0, 1.0);\n    }\n    bool _4303 = _4292 < 1.0;\n    bool _4309;\n    if (_4303)\n    {\n        int param = li;\n        _4309 = fa_light_baked(param);\n    }\n    else\n    {\n        _4309 = _4303;\n    }\n    return _4309 ? _4292 : 1.0;\n}\n\nfloat fa_light_type(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 1;\n    return fa_light_texel(param_1).w;\n}\n\nvec3 fa_area_point(vec3 c, vec3 axis, vec3 ru, vec3 uu, float hx, float hy, float shape, vec3 p, vec3 r)\n{\n    bool _611 = dot(r, r) > 0.5;\n    if (shape > 1.5)\n    {\n        vec3 _624 = (c - (ru * hx)) - p;\n        vec3 _630 = ru * (2.0 * hx);\n        float _636 = max(dot(_630, _630), 9.9999999392252902907785028219223e-09);\n        float _640 = dot(_624, _630);\n        float t = clamp((-_640) / _636, 0.0, 1.0);\n        if (_611)\n        {\n            float _655 = dot(r, _630);\n            float _661 = _636 - (_655 * _655);\n            if (abs(_661) > (9.9999997473787516355514526367188e-06 * _636))\n            {\n                t = clamp(((dot(r, _624) * _655) - _640) / _661, 0.0, 1.0);\n            }\n        }\n        return (p + _624) + (_630 * t);\n    }\n    vec3 q = p;\n    float _693 = dot(r, axis);\n    bool _701;\n    if (_611)\n    {\n        _701 = abs(_693) > 9.9999997473787516355514526367188e-05;\n    }\n    else\n    {\n        _701 = _611;\n    }\n    if (_701)\n    {\n        float _711 = dot(c - p, axis) / _693;\n        if (_711 > 0.0)\n        {\n            q = p + (r * _711);\n        }\n    }\n    vec3 _724 = q - c;\n    vec2 xy = vec2(dot(_724, ru), dot(_724, uu));\n    if (shape > 0.5)\n    {\n        float _739 = length(xy);\n        if (_739 > hx)\n        {\n            xy *= (hx / _739);\n        }\n    }\n    else\n    {\n        xy = clamp(xy, vec2(-hx, -hy), vec2(hx, hy));\n    }\n    return (c + (ru * xy.x)) + (uu * xy.y);\n}\n\nvec4 fa_atlas_fetch(vec2 texel)\n{\n    return textureLod(fa_light_atlas_fa_env_smp, texel / vec2(textureSize(fa_light_atlas_fa_env_smp, 0)), 0.0);\n}\n\nvec3 fa_cookie_sample(vec2 tile_origin, vec2 uv)\n{\n    vec2 param = (tile_origin + vec2(1.0)) + (clamp(uv, vec2(0.0), vec2(1.0)) * 254.0);\n    return fa_atlas_fetch(param).xyz;\n}\n\nfloat fa_ies_sample(vec2 tile_origin, vec3 d, vec3 axis, vec3 right, vec3 up)\n{\n    float _531 = dot(d, right);\n    float _535 = dot(d, up);\n    float _546;\n    if (((_531 * _531) + (_535 * _535)) > 1.0000000133514319600180897396058e-10)\n    {\n        _546 = atan(_535, _531) * 0.15915493667125701904296875;\n    }\n    else\n    {\n        _546 = 0.0;\n    }\n    vec2 param = tile_origin + vec2(1.0 + ((_546 - floor(_546)) * 64.0), 1.0 + (acos(clamp(dot(d, axis), -1.0, 1.0)) * 10.18591594696044921875));\n    return fa_atlas_fetch(param).x;\n}\n\nint fa_cube_face(vec3 d)\n{\n    vec3 _382 = abs(d);\n    float _384 = _382.x;\n    float _386 = _382.y;\n    bool _387 = _384 >= _386;\n    bool _395;\n    if (_387)\n    {\n        _395 = _384 >= _382.z;\n    }\n    else\n    {\n        _395 = _387;\n    }\n    int _396;\n    if (_395)\n    {\n        _396 = (d.x > 0.0) ? 0 : 1;\n    }\n    else\n    {\n        int _410;\n        if (_386 >= _382.z)\n        {\n            _410 = (d.y > 0.0) ? 2 : 3;\n        }\n        else\n        {\n            _410 = (d.z > 0.0) ? 4 : 5;\n        }\n        _396 = _410;\n    }\n    return _396;\n}\n\nvoid fa_cube_face_basis(int f, out vec3 fwd, out vec3 up)\n{\n    if (f == 0)\n    {\n        fwd = vec3(1.0, 0.0, 0.0);\n        up = vec3(0.0, 1.0, 0.0);\n    }\n    else\n    {\n        if (f == 1)\n        {\n            fwd = vec3(-1.0, 0.0, 0.0);\n            up = vec3(0.0, 1.0, 0.0);\n        }\n        else\n        {\n            if (f == 2)\n            {\n                fwd = vec3(0.0, 1.0, 0.0);\n                up = vec3(0.0, 0.0, 1.0);\n            }\n            else\n            {\n                if (f == 3)\n                {\n                    fwd = vec3(0.0, -1.0, 0.0);\n                    up = vec3(0.0, 0.0, -1.0);\n                }\n                else\n                {\n                    if (f == 4)\n                    {\n                        fwd = vec3(0.0, 0.0, 1.0);\n                        up = vec3(0.0, 1.0, 0.0);\n                    }\n                    else\n                    {\n                        fwd = vec3(0.0, 0.0, -1.0);\n                        up = vec3(0.0, 1.0, 0.0);\n                    }\n                }\n            }\n        }\n    }\n}\n\nLightSample fa_light_sample_n(int li, vec3 world_pos, vec3 n)\n{\n    int param = li;\n    int _777 = fa_light_base(param);\n    bool _781 = fa_mesh_fs_params[1].w > 4.5;\n    int param_1 = _777;\n    vec4 _785 = fa_light_texel(param_1);\n    int param_2 = _777 + 1;\n    vec4 _790 = fa_light_texel(param_2);\n    float _793 = _790.w;\n    float atten = 1.0;\n    float dist = 0.0;\n    fa_light_tint = vec3(1.0);\n    bool _805 = _781 && (_793 > 2.5);\n    fa_light_is_area = _805;\n    bool _807 = _793 < 0.5;\n    vec3 l;\n    if (_807)\n    {\n        l = normalize(_785.xyz);\n        if (_781)\n        {\n            int param_3 = _777 + 6;\n            vec4 _821 = fa_light_texel(param_3);\n            if (_821.z > 0.5)\n            {\n                int param_4 = _777 + 4;\n                vec4 _831 = fa_light_texel(param_4);\n                int param_5 = _777 + 5;\n                vec4 _836 = fa_light_texel(param_5);\n                vec2 param_6 = _821.xy;\n                vec2 param_7 = fract(vec2(dot(world_pos, _831.xyz) * _831.w, (-dot(world_pos, _836.xyz)) * _836.w) + vec2(0.5));\n                fa_light_tint = fa_cookie_sample(param_6, param_7);\n            }\n        }\n    }\n    else\n    {\n        vec3 _866 = _785.xyz;\n        vec3 _868 = _866 - world_pos;\n        vec3 to_light = _868;\n        float _871 = length(_868);\n        float reach = _871;\n        bool front = true;\n        if (_805)\n        {\n            int param_8 = _777 + 7;\n            reach = max(_871 - fa_light_texel(param_8).w, 0.0);\n            int param_9 = _777 + 4;\n            vec4 _895 = fa_light_texel(param_9);\n            int param_10 = _777 + 5;\n            vec4 _900 = fa_light_texel(param_10);\n            int param_11 = _777 + 6;\n            vec4 _905 = fa_light_texel(param_11);\n            float _906 = _905.w;\n            int param_12 = _777 + 2;\n            vec3 _913 = normalize(fa_light_texel(param_12).xyz);\n            bool _915 = _906 > 1.5;\n            bool _923;\n            if (!_915)\n            {\n                _923 = dot(_913, to_light) < 0.0;\n            }\n            else\n            {\n                _923 = _915;\n            }\n            front = _923;\n            vec3 r = vec3(0.0);\n            vec3 _932 = fa_mesh_fs_params[0].xyz - world_pos;\n            bool _936 = dot(n, n) > 0.5;\n            bool _944;\n            if (_936)\n            {\n                _944 = dot(_932, _932) > 9.9999999600419720025001879548654e-13;\n            }\n            else\n            {\n                _944 = _936;\n            }\n            if (_944)\n            {\n                r = reflect(-normalize(_932), normalize(n));\n            }\n            vec3 param_13 = _866;\n            vec3 param_14 = _913;\n            vec3 param_15 = _895.xyz;\n            vec3 param_16 = _900.xyz;\n            float param_17 = _895.w;\n            float param_18 = _900.w;\n            float param_19 = _906;\n            vec3 param_20 = world_pos;\n            vec3 param_21 = r;\n            to_light = fa_area_point(param_13, param_14, param_15, param_16, param_17, param_18, param_19, param_20, param_21) - world_pos;\n        }\n        float _980 = length(to_light);\n        dist = _980;\n        l = to_light / vec3(max(_980, 9.9999997473787516355514526367188e-05));\n        float _994 = reach / max(_785.w, 0.001000000047497451305389404296875);\n        float _1000 = clamp(1.0 - (_994 * _994), 0.0, 1.0);\n        float _1002;\n        if (front)\n        {\n            _1002 = _1000 * _1000;\n        }\n        else\n        {\n            _1002 = 0.0;\n        }\n        atten = _1002;\n        bool _1013 = _793 < 2.5;\n        if ((_793 > 1.5) && _1013)\n        {\n            int param_22 = _777 + 2;\n            vec4 _1021 = fa_light_texel(param_22);\n            float _1031 = _1021.w;\n            int param_23 = _777 + 3;\n            vec4 _1036 = fa_light_texel(param_23);\n            float _1037 = _1036.x;\n            float cos_inner = _1037;\n            if (_1037 > 1.5)\n            {\n                cos_inner = mix(_1031, 1.0, 0.25);\n            }\n            atten *= smoothstep(_1031, cos_inner, dot(-l, normalize(_1021.xyz)));\n        }\n        if (_781 && (_793 < 1.5))\n        {\n            int param_24 = _777 + 6;\n            vec4 _1061 = fa_light_texel(param_24);\n            if (_1061.z > 0.5)\n            {\n                vec3 _1069 = -to_light;\n                int param_25 = _777 + 4;\n                int param_26 = _777 + 5;\n                vec3 _1083 = fa_light_texel(param_25).xyz;\n                vec3 _1087 = fa_light_texel(param_26).xyz;\n                vec3 _1096 = vec3(dot(_1069, _1083), dot(_1069, _1087), dot(_1069, cross(_1083, _1087)));\n                vec3 param_27 = _1096;\n                int _1100 = fa_cube_face(param_27);\n                int param_28 = _1100;\n                vec3 param_29;\n                vec3 param_30;\n                fa_cube_face_basis(param_28, param_29, param_30);\n                vec2 _1127 = vec2(dot(_1096, cross(param_29, param_30)), dot(_1096, param_30)) / vec2(max(dot(_1096, param_29), 9.9999997473787516355514526367188e-05));\n                int _1131 = _1100 / 3;\n                vec2 param_31 = _1061.xy + (vec2(float(_1100 - (_1131 * 3)), float(_1131)) * 256.0);\n                vec2 param_32 = vec2(0.5 + (0.5 * _1127.x), 0.5 - (0.5 * _1127.y));\n                fa_light_tint = fa_cookie_sample(param_31, param_32);\n            }\n            int param_33 = _777 + 7;\n            vec4 _1161 = fa_light_texel(param_33);\n            if (_1161.z > 0.5)\n            {\n                int param_34 = _777 + 2;\n                int param_35 = _777 + 4;\n                int param_36 = _777 + 5;\n                vec2 param_37 = _1161.xy;\n                vec3 param_38 = -l;\n                vec3 param_39 = normalize(fa_light_texel(param_34).xyz);\n                vec3 param_40 = fa_light_texel(param_35).xyz;\n                vec3 param_41 = fa_light_texel(param_36).xyz;\n                atten *= fa_ies_sample(param_37, param_38, param_39, param_40, param_41);\n            }\n        }\n        else\n        {\n            if (_781 && _1013)\n            {\n                int param_42 = _777 + 6;\n                vec4 _1208 = fa_light_texel(param_42);\n                int param_43 = _777 + 7;\n                vec4 _1213 = fa_light_texel(param_43);\n                bool _1216 = _1208.z > 0.5;\n                bool _1223;\n                if (!_1216)\n                {\n                    _1223 = _1213.z > 0.5;\n                }\n                else\n                {\n                    _1223 = _1216;\n                }\n                if (_1223)\n                {\n                    int param_44 = _777 + 2;\n                    vec4 _1230 = fa_light_texel(param_44);\n                    vec3 _1234 = normalize(_1230.xyz);\n                    int param_45 = _777 + 4;\n                    vec4 _1239 = fa_light_texel(param_45);\n                    int param_46 = _777 + 5;\n                    vec4 _1244 = fa_light_texel(param_46);\n                    if (_1216)\n                    {\n                        vec3 _1252 = -to_light;\n                        float _1259 = _1230.w;\n                        float _1275 = 0.5 / max(dot(_1252, _1234) * (sqrt(max(1.0 - (_1259 * _1259), 0.0)) / max(_1259, 0.001000000047497451305389404296875)), 9.9999997473787516355514526367188e-05);\n                        vec2 param_47 = _1208.xy;\n                        vec2 param_48 = vec2(0.5 + (dot(_1252, _1239.xyz) * _1275), 0.5 - (dot(_1252, _1244.xyz) * _1275));\n                        fa_light_tint = fa_cookie_sample(param_47, param_48);\n                    }\n                    if (_1213.z > 0.5)\n                    {\n                        vec2 param_49 = _1213.xy;\n                        vec3 param_50 = -l;\n                        vec3 param_51 = _1234;\n                        vec3 param_52 = _1239.xyz;\n                        vec3 param_53 = _1244.xyz;\n                        atten *= fa_ies_sample(param_49, param_50, param_51, param_52, param_53);\n                    }\n                }\n            }\n        }\n    }\n    vec3 _6242 = _790.xyz * atten;\n    if (_781)\n    {\n        _6242 *= fa_light_tint;\n    }\n    int _1343;\n    if (_807)\n    {\n        _1343 = 0;\n    }\n    else\n    {\n        _1343 = ((_793 > 1.5) && (_793 < 2.5)) ? 2 : 1;\n    }\n    return LightSample(l, _6242, atten, 1.0, dist, _1343);\n}\n\nfloat fa_rt_local_tap(ivec2 p, ivec2 size, float d, float tol, float div, inout float best)\n{\n    vec4 _3304 = texelFetch(fa_screen_tex_fa_shadow_smp, clamp(p, ivec2(0), size - ivec2(1)), 0);\n    bool _3307 = _3304.w > 0.5;\n    bool _3317;\n    if (_3307)\n    {\n        _3317 = abs(d - _3304.x) <= tol;\n    }\n    else\n    {\n        _3317 = _3307;\n    }\n    if (_3317)\n    {\n        best = min(best, mod(floor(_3304.z / div), 256.0) * 0.0039215688593685626983642578125);\n    }\n    return best;\n}\n\nfloat fa_shadow_depth(inout vec2 uv, vec4 rect)\n{\n    uv = clamp(uv, rect.xy, rect.zw);\n    return textureLod(fa_shadow_tex_fa_shadow_smp, uv, 0.0).x;\n}\n\nfloat fa_shadow_fetch(vec2 uv, vec4 rect, vec3 conv)\n{\n    vec2 param = uv;\n    vec4 param_1 = rect;\n    float _2132 = fa_shadow_depth(param, param_1);\n    float _2136;\n    if (conv.x < 0.5)\n    {\n        _2136 = _2132;\n    }\n    else\n    {\n        _2136 = (conv.y * conv.z) / (conv.z - (_2132 * (conv.z - conv.y)));\n    }\n    return _2136;\n}\n\nfloat fa_shadow_noise()\n{\n    return fract(52.98291778564453125 * fract(dot(gl_FragCoord.xy, vec2(0.067110560834407806396484375, 0.005837149918079376220703125))));\n}\n\nvec2 fa_shadow_vogel_turn(vec2 d)\n{\n    return vec2((d.x * (-0.737368881702423095703125)) - (d.y * 0.675490319728851318359375), (d.y * (-0.737368881702423095703125)) + (d.x * 0.675490319728851318359375));\n}\n\nfloat fa_shadow_filter(vec2 uv, vec4 rect, float zr, float texel_m, float unit, float reach, float plane, vec3 conv, int mode, float k)\n{\n    if (mode == 1)\n    {\n        vec2 param = uv;\n        vec4 param_1 = rect;\n        vec3 param_2 = conv;\n        return float(zr <= fa_shadow_fetch(param, param_1, param_2));\n    }\n    float _2182 = fa_shadow_noise() * 6.283185482025146484375;\n    vec2 _2188 = vec2(cos(_2182), sin(_2182));\n    vec2 dir = _2188;\n    float radius = 1.5;\n    if (mode == 2)\n    {\n        float _2197;\n        if (k < 0.0)\n        {\n            _2197 = (-k) / max(zr, 0.100000001490116119384765625);\n        }\n        else\n        {\n            _2197 = k;\n        }\n        float _2216 = clamp((_2197 * reach) / texel_m, 3.0, 12.0);\n        float sum = 0.0;\n        float cnt = 0.0;\n        for (int i = 0; i < 16; i++)\n        {\n            float _2235 = sqrt((float(i) + 0.5) * 0.0625) * _2216;\n            vec2 param_3 = uv + (dir * (fa_shadows[26].zw * _2235));\n            vec4 param_4 = rect;\n            vec3 param_5 = conv;\n            float _2249 = fa_shadow_fetch(param_3, param_4, param_5);\n            if (_2249 < (zr - (_2235 * plane)))\n            {\n                sum += _2249;\n                cnt += 1.0;\n            }\n            vec2 param_6 = dir;\n            dir = fa_shadow_vogel_turn(param_6);\n        }\n        if (cnt < 0.5)\n        {\n            return 1.0;\n        }\n        float _2277 = sum / cnt;\n        float _2287;\n        if (k < 0.0)\n        {\n            _2287 = (-k) / max(_2277, 0.0500000007450580596923828125);\n        }\n        else\n        {\n            _2287 = k;\n        }\n        radius = clamp(((max(zr - _2277, 0.0) * unit) * _2287) / texel_m, 1.5, 16.0);\n        dir = _2188;\n    }\n    float lit = 0.0;\n    int _2313 = (mode == 2) ? 24 : 16;\n    for (int i_1 = 0; i_1 < _2313; i_1++)\n    {\n        float _2332 = sqrt((float(i_1) + 0.5) / float(_2313)) * radius;\n        vec2 param_7 = uv + (dir * (fa_shadows[26].zw * _2332));\n        vec4 param_8 = rect;\n        vec3 param_9 = conv;\n        lit += float((zr - (_2332 * plane)) <= fa_shadow_fetch(param_7, param_8, param_9));\n        vec2 param_10 = dir;\n        dir = fa_shadow_vogel_turn(param_10);\n    }\n    return lit / float(_2313);\n}\n\nfloat fa_shadow_local(int li, vec3 lpos, vec3 world, vec3 n, vec3 l)\n{\n    bool _2537 = fa_mesh_fs_params[5].z < 0.5;\n    bool _2544;\n    if (!_2537)\n    {\n        _2544 = fa_shadows[29].x < 0.5;\n    }\n    else\n    {\n        _2544 = _2537;\n    }\n    if (_2544)\n    {\n        return 1.0;\n    }\n    int param = (int(fa_shadows[29].x + 0.5) - 1) + li;\n    vec4 _2557 = fa_light_texel(param);\n    float _2558 = _2557.x;\n    if (_2558 < 0.0)\n    {\n        return 1.0;\n    }\n    int _2567 = int(_2558 + 0.5);\n    int param_1 = _2567;\n    vec4 _2571 = fa_light_texel(param_1);\n    int param_2 = _2567 + 1;\n    vec4 _2576 = fa_light_texel(param_2);\n    float fade = 1.0;\n    float _2579 = _2571.y;\n    if (_2579 > 0.0)\n    {\n        float _2596 = 1.0 - smoothstep(0.75 * _2579, _2579, length(world - fa_shadows[27].xyz));\n        fade = _2596;\n        if (_2596 <= 0.0)\n        {\n            return 1.0;\n        }\n    }\n    int face = 0;\n    if (_2571.x > 1.5)\n    {\n        vec3 param_3 = world - lpos;\n        face = fa_cube_face(param_3);\n    }\n    int _2620 = (_2567 + 2) + (face * 6);\n    int param_4 = _2620;\n    int param_5 = _2620 + 1;\n    int param_6 = _2620 + 3;\n    vec4 _2634 = fa_light_texel(param_6);\n    int param_7 = _2620 + 4;\n    vec4 _2639 = fa_light_texel(param_7);\n    int param_8 = _2620 + 5;\n    vec4 _2644 = fa_light_texel(param_8);\n    float _2656 = _2644.x * max(dot(_2634, vec4(world, 1.0)), 0.001000000047497451305389404296875);\n    float _2661 = clamp(dot(n, l), 0.0, 1.0);\n    float _2684 = clamp(dot(n, _2634.xyz), -1.0, 1.0);\n    float _2703 = min(sqrt(1.0 - (_2684 * _2684)) / max(abs(dot(n, world - lpos)) / max(dot(_2634, vec4(world, 1.0)), 0.001000000047497451305389404296875), 0.20000000298023223876953125), 4.0);\n    float _2706 = _2576.y;\n    float _2708;\n    if (_2706 > 0.0)\n    {\n        _2708 = _2706;\n    }\n    else\n    {\n        _2708 = 1.5 * _2656;\n    }\n    vec4 _2728 = vec4(world + (n * (_2708 * sqrt(1.0 - (_2661 * _2661)))), 1.0);\n    float _2732 = dot(_2634, _2728);\n    float _2735 = _2644.y;\n    if (_2732 < _2735)\n    {\n        return 1.0;\n    }\n    vec2 _2750 = vec2(dot(fa_light_texel(param_4), _2728), dot(fa_light_texel(param_5), _2728)) / vec2(_2732);\n    float _2752 = _2750.x;\n    bool _2755 = _2752 < _2639.x;\n    bool _2764;\n    if (!_2755)\n    {\n        _2764 = _2752 > _2639.z;\n    }\n    else\n    {\n        _2764 = _2755;\n    }\n    bool _2773;\n    if (!_2764)\n    {\n        _2773 = _2750.y < _2639.y;\n    }\n    else\n    {\n        _2773 = _2764;\n    }\n    bool _2782;\n    if (!_2773)\n    {\n        _2782 = _2750.y > _2639.w;\n    }\n    else\n    {\n        _2782 = _2773;\n    }\n    if (_2782)\n    {\n        return 1.0;\n    }\n    float _2788 = _2576.x;\n    float _2790;\n    if (_2788 > 0.0)\n    {\n        _2790 = _2788;\n    }\n    else\n    {\n        _2790 = 1.5 * _2656;\n    }\n    vec2 param_9 = _2750;\n    vec4 param_10 = _2639;\n    float param_11 = _2732 - (_2790 * (1.0 + (0.5 * _2703)));\n    float param_12 = _2656;\n    float param_13 = 1.0;\n    float param_14 = _2644.z * 0.25;\n    float param_15 = (_2656 * min(_2703, 3.0)) * 0.5;\n    vec3 param_16 = vec3(1.0, _2735, _2644.z);\n    int param_17 = int(_2571.z + 0.5);\n    float param_18 = _2571.w;\n    return mix(1.0, fa_shadow_filter(param_9, param_10, param_11, param_12, param_13, param_14, param_15, param_16, param_17, param_18), fade);\n}\n\nfloat fa_shadow_local_rt(int li, vec3 lpos, vec3 world, vec3 n, vec3 l)\n{\n    bool _3335 = fa_mesh_fs_params[25].w > 0.5;\n    bool _3341;\n    if (_3335)\n    {\n        _3341 = fa_mesh_fs_params[5].z > 0.5;\n    }\n    else\n    {\n        _3341 = _3335;\n    }\n    bool _3347;\n    if (_3341)\n    {\n        _3347 = fa_shadows[29].x > 0.5;\n    }\n    else\n    {\n        _3347 = _3341;\n    }\n    if (_3347)\n    {\n        int param = (int(fa_shadows[29].x + 0.5) - 1) + li;\n        vec4 _3359 = fa_light_texel(param);\n        float _3360 = _3359.z;\n        if (_3360 > 0.5)\n        {\n            float _3373 = dot(fa_mesh_fs_params[29].xyz, world) + fa_mesh_fs_params[29].w;\n            float _3379 = ((0.00200000009499490261077880859375 * _3373) + 0.00999999977648258209228515625) + fa_rt_slope;\n            vec4 _3385 = vec4(world, 1.0);\n            float _3390 = dot(fa_mesh_fs_params[28], _3385);\n            if (_3390 > 9.9999997473787516355514526367188e-05)\n            {\n                vec2 _3407 = vec2(dot(fa_mesh_fs_params[26], _3385), dot(fa_mesh_fs_params[27], _3385)) / vec2(_3390);\n                float _3412 = (_3407.x * 0.5) + 0.5;\n                float _3416;\n                if (fa_mesh_fs_params[24].y > 0.5)\n                {\n                    _3416 = (_3407.y * 0.5) + 0.5;\n                }\n                else\n                {\n                    _3416 = 0.5 - (_3407.y * 0.5);\n                }\n                bool _3432 = _3412 >= 0.0;\n                bool _3438;\n                if (_3432)\n                {\n                    _3438 = _3412 < 1.0;\n                }\n                else\n                {\n                    _3438 = _3432;\n                }\n                bool _3444;\n                if (_3438)\n                {\n                    _3444 = _3416 >= 0.0;\n                }\n                else\n                {\n                    _3444 = _3438;\n                }\n                bool _3450;\n                if (_3444)\n                {\n                    _3450 = _3416 < 1.0;\n                }\n                else\n                {\n                    _3450 = _3444;\n                }\n                if (_3450)\n                {\n                    ivec2 _3457 = ivec2(fa_mesh_fs_params[24].zw);\n                    ivec2 _3468 = clamp(ivec2(vec2(_3412, _3416) * fa_mesh_fs_params[24].zw), ivec2(0), _3457 - ivec2(1));\n                    float _3472;\n                    if (_3360 < 1.5)\n                    {\n                        _3472 = 1.0;\n                    }\n                    else\n                    {\n                        _3472 = (_3360 < 2.5) ? 256.0 : 65536.0;\n                    }\n                    float best = 2.0;\n                    vec4 _3488 = texelFetch(fa_screen_tex_fa_shadow_smp, _3468, 0);\n                    bool _3491 = _3488.w > 0.5;\n                    bool _3501;\n                    if (_3491)\n                    {\n                        _3501 = abs(_3373 - _3488.x) <= _3379;\n                    }\n                    else\n                    {\n                        _3501 = _3491;\n                    }\n                    if (_3501)\n                    {\n                        best = mod(floor(_3488.z / _3472), 256.0) * 0.0039215688593685626983642578125;\n                    }\n                    else\n                    {\n                        ivec2 param_1 = _3468 + ivec2(-1);\n                        ivec2 param_2 = _3457;\n                        float param_3 = _3373;\n                        float param_4 = _3379;\n                        float param_5 = _3472;\n                        float param_6 = best;\n                        float _3527 = fa_rt_local_tap(param_1, param_2, param_3, param_4, param_5, param_6);\n                        best = _3527;\n                        ivec2 param_7 = _3468 + ivec2(0, -1);\n                        ivec2 param_8 = _3457;\n                        float param_9 = _3373;\n                        float param_10 = _3379;\n                        float param_11 = _3472;\n                        float param_12 = _3527;\n                        float _3542 = fa_rt_local_tap(param_7, param_8, param_9, param_10, param_11, param_12);\n                        best = _3542;\n                        ivec2 param_13 = _3468 + ivec2(1, -1);\n                        ivec2 param_14 = _3457;\n                        float param_15 = _3373;\n                        float param_16 = _3379;\n                        float param_17 = _3472;\n                        float param_18 = _3542;\n                        float _3557 = fa_rt_local_tap(param_13, param_14, param_15, param_16, param_17, param_18);\n                        best = _3557;\n                        ivec2 param_19 = _3468 + ivec2(-1, 0);\n                        ivec2 param_20 = _3457;\n                        float param_21 = _3373;\n                        float param_22 = _3379;\n                        float param_23 = _3472;\n                        float param_24 = _3557;\n                        float _3572 = fa_rt_local_tap(param_19, param_20, param_21, param_22, param_23, param_24);\n                        best = _3572;\n                        ivec2 param_25 = _3468 + ivec2(1, 0);\n                        ivec2 param_26 = _3457;\n                        float param_27 = _3373;\n                        float param_28 = _3379;\n                        float param_29 = _3472;\n                        float param_30 = _3572;\n                        float _3587 = fa_rt_local_tap(param_25, param_26, param_27, param_28, param_29, param_30);\n                        best = _3587;\n                        ivec2 param_31 = _3468 + ivec2(-1, 1);\n                        ivec2 param_32 = _3457;\n                        float param_33 = _3373;\n                        float param_34 = _3379;\n                        float param_35 = _3472;\n                        float param_36 = _3587;\n                        float _3602 = fa_rt_local_tap(param_31, param_32, param_33, param_34, param_35, param_36);\n                        best = _3602;\n                        ivec2 param_37 = _3468 + ivec2(0, 1);\n                        ivec2 param_38 = _3457;\n                        float param_39 = _3373;\n                        float param_40 = _3379;\n                        float param_41 = _3472;\n                        float param_42 = _3602;\n                        float _3617 = fa_rt_local_tap(param_37, param_38, param_39, param_40, param_41, param_42);\n                        best = _3617;\n                        ivec2 param_43 = _3468 + ivec2(1);\n                        ivec2 param_44 = _3457;\n                        float param_45 = _3373;\n                        float param_46 = _3379;\n                        float param_47 = _3472;\n                        float param_48 = _3617;\n                        float _3632 = fa_rt_local_tap(param_43, param_44, param_45, param_46, param_47, param_48);\n                        best = _3632;\n                    }\n                    if (best <= 1.0)\n                    {\n                        float _3640;\n                        if (fa_mesh_fs_params[25].z > 0.5)\n                        {\n                            int param_49 = li;\n                            vec3 param_50 = lpos;\n                            vec3 param_51 = world;\n                            vec3 param_52 = n;\n                            vec3 param_53 = l;\n                            _3640 = min(best, fa_shadow_local(param_49, param_50, param_51, param_52, param_53));\n                        }\n                        else\n                        {\n                            _3640 = best;\n                        }\n                        return _3640;\n                    }\n                }\n            }\n            float _3663;\n            if (fa_mesh_fs_params[25].z > 0.5)\n            {\n                int param_54 = li;\n                vec3 param_55 = lpos;\n                vec3 param_56 = world;\n                vec3 param_57 = n;\n                vec3 param_58 = l;\n                _3663 = fa_shadow_local(param_54, param_55, param_56, param_57, param_58);\n            }\n            else\n            {\n                _3663 = 1.0;\n            }\n            return _3663;\n        }\n    }\n    int param_59 = li;\n    vec3 param_60 = lpos;\n    vec3 param_61 = world;\n    vec3 param_62 = n;\n    vec3 param_63 = l;\n    return fa_shadow_local(param_59, param_60, param_61, param_62, param_63);\n}\n\nfloat fa_shadow_split_at(int i)\n{\n    float _2075;\n    if (i == 0)\n    {\n        _2075 = fa_shadows[24].x;\n    }\n    else\n    {\n        float _2091;\n        if (i == 1)\n        {\n            _2091 = fa_shadows[24].y;\n        }\n        else\n        {\n            float _2099;\n            if (i == 2)\n            {\n                _2099 = fa_shadows[24].z;\n            }\n            else\n            {\n                _2099 = fa_shadows[24].w;\n            }\n            _2091 = _2099;\n        }\n        _2075 = _2091;\n    }\n    return _2075;\n}\n\nfloat fa_shadow_cascade(int ci, vec3 world, vec3 n, vec3 l)\n{\n    float _2378 = max(fa_shadows[ci * 1 + 20].y, 0.001000000047497451305389404296875);\n    float _2383 = clamp(dot(n, l), 0.0, 1.0);\n    float _2389 = sqrt(1.0 - (_2383 * _2383));\n    float _2397 = min(_2389 / max(_2383, 0.20000000298023223876953125), 4.0);\n    float _2402;\n    if (fa_shadows[26].y > 0.0)\n    {\n        _2402 = fa_shadows[26].y;\n    }\n    else\n    {\n        _2402 = 1.5 * fa_shadows[ci * 1 + 20].x;\n    }\n    vec4 _2427 = mat4(fa_shadows[ci * 4 + 0], fa_shadows[ci * 4 + 1], fa_shadows[ci * 4 + 2], fa_shadows[ci * 4 + 3]) * vec4(world + (n * (_2402 * _2389)), 1.0);\n    float _2434 = _2427.x;\n    bool _2437 = _2434 < fa_shadows[ci * 1 + 16].x;\n    bool _2446;\n    if (!_2437)\n    {\n        _2446 = _2434 > fa_shadows[ci * 1 + 16].z;\n    }\n    else\n    {\n        _2446 = _2437;\n    }\n    bool _2455;\n    if (!_2446)\n    {\n        _2455 = _2427.y < fa_shadows[ci * 1 + 16].y;\n    }\n    else\n    {\n        _2455 = _2446;\n    }\n    bool _2464;\n    if (!_2455)\n    {\n        _2464 = _2427.y > fa_shadows[ci * 1 + 16].w;\n    }\n    else\n    {\n        _2464 = _2455;\n    }\n    bool _2471;\n    if (!_2464)\n    {\n        _2471 = _2427.z > 1.0;\n    }\n    else\n    {\n        _2471 = _2464;\n    }\n    if (_2471)\n    {\n        return -1.0;\n    }\n    float _2479;\n    if (fa_shadows[26].x > 0.0)\n    {\n        _2479 = fa_shadows[26].x;\n    }\n    else\n    {\n        _2479 = 1.5 * fa_shadows[ci * 1 + 20].x;\n    }\n    vec2 param = _2427.xy;\n    vec4 param_1 = fa_shadows[ci * 1 + 16];\n    float param_2 = _2427.z - ((_2479 * (1.0 + (0.5 * _2397))) / _2378);\n    float param_3 = fa_shadows[ci * 1 + 20].x;\n    float param_4 = _2378;\n    float param_5 = _2378 * 0.25;\n    float param_6 = ((fa_shadows[ci * 1 + 20].x * min(_2397, 3.0)) * 0.5) / _2378;\n    vec3 param_7 = vec3(0.0);\n    int param_8 = int(fa_shadows[25].z + 0.5);\n    float param_9 = fa_shadows[25].w;\n    return fa_shadow_filter(param, param_1, param_2, param_3, param_4, param_5, param_6, param_7, param_8, param_9);\n}\n\nfloat fa_shadow_sun(vec3 world, vec3 n, vec3 l)\n{\n    if (fa_mesh_fs_params[5].z < 0.5)\n    {\n        return 1.0;\n    }\n    int _2857 = int(fa_shadows[25].x + 0.5);\n    if (_2857 < 1)\n    {\n        return 1.0;\n    }\n    float _2872 = dot(world - fa_shadows[27].xyz, fa_shadows[28].xyz);\n    int param = _2857 - 1;\n    if (_2872 > fa_shadow_split_at(param))\n    {\n        return 1.0;\n    }\n    int ci = 0;\n    bool _2884 = _2857 > 1;\n    bool _2891;\n    if (_2884)\n    {\n        _2891 = _2872 > fa_shadows[24].x;\n    }\n    else\n    {\n        _2891 = _2884;\n    }\n    if (_2891)\n    {\n        ci = 1;\n    }\n    bool _2895 = _2857 > 2;\n    bool _2902;\n    if (_2895)\n    {\n        _2902 = _2872 > fa_shadows[24].y;\n    }\n    else\n    {\n        _2902 = _2895;\n    }\n    if (_2902)\n    {\n        ci = 2;\n    }\n    bool _2906 = _2857 > 3;\n    bool _2913;\n    if (_2906)\n    {\n        _2913 = _2872 > fa_shadows[24].z;\n    }\n    else\n    {\n        _2913 = _2906;\n    }\n    if (_2913)\n    {\n        ci = 3;\n    }\n    float s = -1.0;\n    float s2 = -1.0;\n    float t = 0.0;\n    int _2924 = min(_2857, 4);\n    float _2965;\n    for (int c = ci; c < _2924; c++)\n    {\n        int param_1 = c;\n        vec3 param_2 = world;\n        vec3 param_3 = n;\n        vec3 param_4 = l;\n        float _2944 = fa_shadow_cascade(param_1, param_2, param_3, param_4);\n        if (s >= 0.0)\n        {\n            s2 = _2944;\n            break;\n        }\n        if (_2944 < 0.0)\n        {\n            continue;\n        }\n        s = _2944;\n        ci = c;\n        if (fa_shadows[25].y > 0.0)\n        {\n            if (ci > 0)\n            {\n                int param_5 = ci - 1;\n                _2965 = fa_shadow_split_at(param_5);\n            }\n            else\n            {\n                _2965 = fa_shadows[28].w;\n            }\n            int param_6 = ci;\n            float _2984 = fa_shadows[25].y * max(fa_shadow_split_at(param_6) - _2965, 9.9999997473787516355514526367188e-05);\n            int param_7 = ci;\n            t = clamp((_2872 - (fa_shadow_split_at(param_7) - _2984)) / _2984, 0.0, 1.0);\n        }\n        if (t <= 0.0)\n        {\n            break;\n        }\n    }\n    if (s < 0.0)\n    {\n        return 1.0;\n    }\n    if (t > 0.0)\n    {\n        float _3016;\n        if ((ci + 1) < _2857)\n        {\n            _3016 = (s2 < 0.0) ? s : s2;\n        }\n        else\n        {\n            _3016 = 1.0;\n        }\n        s = mix(s, _3016, t);\n    }\n    return s;\n}\n\nfloat fa_shadow_factor(vec3 n, vec3 l)\n{\n    bool _3121 = fa_mesh_fs_params[25].y > 0.5;\n    bool _3127;\n    if (_3121)\n    {\n        _3127 = fa_mesh_fs_params[5].z > 0.5;\n    }\n    else\n    {\n        _3127 = _3121;\n    }\n    if (_3127)\n    {\n        float _3141 = dot(fa_mesh_fs_params[29].xyz, fa_world_pos) + fa_mesh_fs_params[29].w;\n        vec4 _3149 = vec4(fa_world_pos, 1.0);\n        float _3155 = dot(fa_mesh_fs_params[28], _3149);\n        if (_3155 > 9.9999997473787516355514526367188e-05)\n        {\n            vec2 _3174 = vec2(dot(fa_mesh_fs_params[26], _3149), dot(fa_mesh_fs_params[27], _3149)) / vec2(_3155);\n            float _3179 = (_3174.x * 0.5) + 0.5;\n            float _3183;\n            if (fa_mesh_fs_params[24].y > 0.5)\n            {\n                _3183 = (_3174.y * 0.5) + 0.5;\n            }\n            else\n            {\n                _3183 = 0.5 - (_3174.y * 0.5);\n            }\n            bool _3199 = _3179 >= 0.0;\n            bool _3205;\n            if (_3199)\n            {\n                _3205 = _3179 < 1.0;\n            }\n            else\n            {\n                _3205 = _3199;\n            }\n            bool _3211;\n            if (_3205)\n            {\n                _3211 = _3183 >= 0.0;\n            }\n            else\n            {\n                _3211 = _3205;\n            }\n            bool _3217;\n            if (_3211)\n            {\n                _3217 = _3183 < 1.0;\n            }\n            else\n            {\n                _3217 = _3211;\n            }\n            if (_3217)\n            {\n                vec4 _3242 = texelFetch(fa_screen_tex_fa_shadow_smp, clamp(ivec2(vec2(_3179, _3183) * fa_mesh_fs_params[24].zw), ivec2(0), ivec2(fa_mesh_fs_params[24].zw) - ivec2(1)), 0);\n                bool _3245 = _3242.w > 0.5;\n                bool _3261;\n                if (_3245)\n                {\n                    _3261 = abs(_3141 - _3242.x) <= (((0.00200000009499490261077880859375 * _3141) + 0.00999999977648258209228515625) + fa_rt_slope);\n                }\n                else\n                {\n                    _3261 = _3245;\n                }\n                if (_3261)\n                {\n                    float _3267;\n                    if (fa_mesh_fs_params[25].z > 0.5)\n                    {\n                        vec3 param = fa_world_pos;\n                        vec3 param_1 = n;\n                        vec3 param_2 = l;\n                        _3267 = min(_3242.y, fa_shadow_sun(param, param_1, param_2));\n                    }\n                    else\n                    {\n                        _3267 = _3242.y;\n                    }\n                    return _3267;\n                }\n            }\n        }\n    }\n    vec3 param_3 = fa_world_pos;\n    vec3 param_4 = n;\n    vec3 param_5 = l;\n    return fa_shadow_sun(param_3, param_4, param_5);\n}\n\nfloat fa_contact_shadow(int li, vec3 world, vec3 gn, vec3 l, float dist)\n{\n    bool _4034 = fa_mesh_fs_params[24].x < 0.5;\n    bool _4041;\n    if (!_4034)\n    {\n        _4041 = fa_shadows[29].x < 0.5;\n    }\n    else\n    {\n        _4041 = _4034;\n    }\n    if (_4041)\n    {\n        return 1.0;\n    }\n    int param = (int(fa_shadows[29].x + 0.5) - 1) + li;\n    vec4 _4054 = fa_light_texel(param);\n    float _4055 = _4054.y;\n    float len = _4055;\n    if (_4055 <= 0.0)\n    {\n        return 1.0;\n    }\n    float _4067 = length(world - fa_mesh_fs_params[0].xyz);\n    float _4076 = 1.0 - smoothstep(0.5 * fa_mesh_fs_params[25].x, fa_mesh_fs_params[25].x, _4067);\n    if (_4076 <= 0.0)\n    {\n        return 1.0;\n    }\n    float _4082 = len;\n    float _4085 = min(_4082, 0.89999997615814208984375 * dist);\n    len = _4085;\n    float _4091 = 0.004999999888241291046142578125 + (0.0030000000260770320892333984375 * _4067);\n    float _4096 = _4091 + (0.5 * _4085);\n    vec3 _4102 = world + (gn * _4091);\n    float _4104 = fa_shadow_noise();\n    float occ = 0.0;\n    float _4166;\n    for (int k = 0; k < 12; k++)\n    {\n        float _4120 = (float(k) + _4104) * 0.083333335816860198974609375;\n        vec3 _4128 = _4102 + (l * (_4120 * len));\n        vec4 _4134 = vec4(_4128, 1.0);\n        float _4139 = dot(fa_mesh_fs_params[28], _4134);\n        if (_4139 < 9.9999997473787516355514526367188e-05)\n        {\n            break;\n        }\n        vec2 _4157 = vec2(dot(fa_mesh_fs_params[26], _4134), dot(fa_mesh_fs_params[27], _4134)) / vec2(_4139);\n        float _4161 = _4157.x * 0.5;\n        float _4162 = _4161 + 0.5;\n        if (fa_mesh_fs_params[24].y > 0.5)\n        {\n            _4166 = (_4157.y * 0.5) + 0.5;\n        }\n        else\n        {\n            _4166 = 0.5 - (_4157.y * 0.5);\n        }\n        bool _4182 = _4162 < 0.0;\n        bool _4189;\n        if (!_4182)\n        {\n            _4189 = _4162 >= 1.0;\n        }\n        else\n        {\n            _4189 = _4182;\n        }\n        bool _4196;\n        if (!_4189)\n        {\n            _4196 = _4166 < 0.0;\n        }\n        else\n        {\n            _4196 = _4189;\n        }\n        bool _4203;\n        if (!_4196)\n        {\n            _4203 = _4166 >= 1.0;\n        }\n        else\n        {\n            _4203 = _4196;\n        }\n        if (_4203)\n        {\n            break;\n        }\n        vec4 _4227 = texelFetch(fa_screen_tex_fa_shadow_smp, clamp(ivec2(vec2(_4162, _4166) * fa_mesh_fs_params[24].zw), ivec2(0), ivec2(fa_mesh_fs_params[24].zw) - ivec2(1)), 0);\n        if (_4227.w < 0.5)\n        {\n            continue;\n        }\n        float _4245 = (dot(fa_mesh_fs_params[29].xyz, _4128) + fa_mesh_fs_params[29].w) - _4227.x;\n        if ((_4245 > _4091) && (_4245 < _4096))\n        {\n            occ = max(occ, (1.0 - (_4120 * _4120)) * smoothstep(0.0, 0.0500000007450580596923828125, min(min(_4162, 0.5 - _4161), min(_4166, 1.0 - _4166))));\n        }\n    }\n    return 1.0 - (occ * _4076);\n}\n\nLightSample fa_light_shadowed(int li, vec3 world_pos, vec3 gn)\n{\n    int param = li;\n    float _4377 = fa_baked_keep(param);\n    if (_4377 <= 0.0)\n    {\n        int param_1 = li;\n        return LightSample(vec3(0.0, 1.0, 0.0), vec3(0.0), 0.0, 1.0, 0.0, int(fa_light_type(param_1) + 0.5));\n    }\n    int param_2 = li;\n    vec3 param_3 = world_pos;\n    vec3 param_4 = gn;\n    LightSample _4403 = fa_light_sample_n(param_2, param_3, param_4);\n    vec3 _6268 = _4403.color;\n    float _6269 = _4403.attenuation;\n    float _6270 = _4403.shadow;\n    bool _4406 = _4403.type == 0;\n    if (_4406 && (li == 0))\n    {\n        vec3 param_5 = gn;\n        vec3 param_6 = _4403.direction;\n        float _4417 = fa_shadow_factor(param_5, param_6);\n        _6270 = _4417;\n        _6268 *= _4417;\n    }\n    else\n    {\n        bool _4428 = _4403.type != 0;\n        bool _4434;\n        if (_4428)\n        {\n            _4434 = _6269 > 0.0;\n        }\n        else\n        {\n            _4434 = _4428;\n        }\n        if (_4434)\n        {\n            int param_7 = li;\n            int param_8 = fa_light_base(param_7);\n            int param_9 = li;\n            vec3 param_10 = fa_light_texel(param_8).xyz;\n            vec3 param_11 = world_pos;\n            vec3 param_12 = gn;\n            vec3 param_13 = _4403.direction;\n            float _4453 = fa_shadow_local_rt(param_9, param_10, param_11, param_12, param_13);\n            _6270 = _4453;\n            _6268 *= _4453;\n        }\n    }\n    bool _4463 = fa_mesh_fs_params[24].x > 0.5;\n    bool _4469;\n    if (_4463)\n    {\n        _4469 = _6269 > 0.0;\n    }\n    else\n    {\n        _4469 = _4463;\n    }\n    if (_4469)\n    {\n        float _4476;\n        if (_4406)\n        {\n            _4476 = 1000000000.0;\n        }\n        else\n        {\n            _4476 = _4403._distance;\n        }\n        int param_14 = li;\n        vec3 param_15 = world_pos;\n        vec3 param_16 = gn;\n        vec3 param_17 = _4403.direction;\n        float param_18 = _4476;\n        float _4494 = fa_contact_shadow(param_14, param_15, param_16, param_17, param_18);\n        _6270 *= _4494;\n        _6268 *= _4494;\n    }\n    float _4507 = _6269;\n    float _4508 = _4507 * _4377;\n    _6269 = _4508;\n    vec3 _4512 = _6268;\n    vec3 _4513 = _4512 * _4377;\n    _6268 = _4513;\n    return LightSample(_4403.direction, _4513, _4508, _6270, _4403._distance, _4403.type);\n}\n\nvec3 light(SurfaceInput i, Surface s, LightSample l)\n{\n    return vec3(0.0);\n}\n\nvec3 fa_shadow_debug(vec3 color, vec3 world)\n{\n    if (fa_shadows[27].w < 0.5)\n    {\n        return color;\n    }\n    int _3044 = int(fa_shadows[25].x + 0.5);\n    float _3054 = dot(world - fa_shadows[27].xyz, fa_shadows[28].xyz);\n    vec3 tint = vec3(0.3499999940395355224609375);\n    bool _3059 = _3044 > 0;\n    bool _3068;\n    if (_3059)\n    {\n        int param = _3044 - 1;\n        _3068 = _3054 <= fa_shadow_split_at(param);\n    }\n    else\n    {\n        _3068 = _3059;\n    }\n    if (_3068)\n    {\n        tint = vec3(1.0, 0.1500000059604644775390625, 0.100000001490116119384765625);\n        bool _3074 = _3044 > 1;\n        bool _3081;\n        if (_3074)\n        {\n            _3081 = _3054 > fa_shadows[24].x;\n        }\n        else\n        {\n            _3081 = _3074;\n        }\n        if (_3081)\n        {\n            tint = vec3(0.100000001490116119384765625, 0.89999997615814208984375, 0.20000000298023223876953125);\n        }\n        bool _3087 = _3044 > 2;\n        bool _3094;\n        if (_3087)\n        {\n            _3094 = _3054 > fa_shadows[24].y;\n        }\n        else\n        {\n            _3094 = _3087;\n        }\n        if (_3094)\n        {\n            tint = vec3(0.1500000059604644775390625, 0.300000011920928955078125, 1.0);\n        }\n        bool _3100 = _3044 > 3;\n        bool _3107;\n        if (_3100)\n        {\n            _3107 = _3054 > fa_shadows[24].z;\n        }\n        else\n        {\n            _3107 = _3100;\n        }\n        if (_3107)\n        {\n            tint = vec3(1.0, 0.89999997615814208984375, 0.100000001490116119384765625);\n        }\n    }\n    return mix(color, tint, vec3(0.550000011920928955078125));\n}\n\nvoid main()\n{\n    fa_rt_slope = 0.0;\n    fa_inst_load();\n    vec3 _6089 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _6089 = -_6089;\n    }\n    vec3 _5663 = normalize(fa_mesh_fs_params[0].xyz - fa_world_pos);\n    vec3 param = fa_world_pos;\n    fa_cluster_begin(param);\n    SurfaceInput param_1 = SurfaceInput(fa_world_pos, _6089, fa_world_tangent, fa_uv, fa_vertex_color, _5663, gl_FrontFacing);\n    Surface _5671 = fa_standard_surface(param_1);\n    vec3 _6120 = _5671.albedo;\n    float _6121 = _5671.alpha;\n    vec3 _6122 = _5671.normal;\n    float _6123 = _5671.metallic;\n    float _6124 = _5671.roughness;\n    float _6125 = _5671.occlusion;\n    vec3 _6126 = _5671.emission;\n    float _6127 = _5671.clearcoat;\n    float _6128 = _5671.clearcoat_roughness;\n    vec3 _6129 = _5671.sheen_color;\n    float _6130 = _5671.sheen_roughness;\n    float _6131 = _5671.anisotropy;\n    float _6132 = _5671.anisotropy_rotation;\n    float _6133 = _5671.specular;\n    float _6134 = _5671.ior;\n    vec3 _6135 = _5671.specular_color;\n    float _6136 = _5671.transmission;\n    float _6137 = _5671.thickness;\n    vec3 _6138 = _5671.attenuation_color;\n    float _6139 = _5671.attenuation_distance;\n    SurfaceInput param_2 = SurfaceInput(fa_world_pos, _6089, fa_world_tangent, fa_uv, fa_vertex_color, _5663, gl_FrontFacing);\n    Surface param_3 = _5671;\n    surface(param_2, param_3);\n    _6120 = param_3.albedo;\n    _6121 = param_3.alpha;\n    _6122 = param_3.normal;\n    _6123 = param_3.metallic;\n    _6124 = param_3.roughness;\n    _6125 = param_3.occlusion;\n    _6126 = param_3.emission;\n    _6127 = param_3.clearcoat;\n    _6128 = param_3.clearcoat_roughness;\n    _6129 = param_3.sheen_color;\n    _6130 = param_3.sheen_roughness;\n    _6131 = param_3.anisotropy;\n    _6132 = param_3.anisotropy_rotation;\n    _6133 = param_3.specular;\n    _6134 = param_3.ior;\n    _6135 = param_3.specular_color;\n    _6136 = param_3.transmission;\n    _6137 = param_3.thickness;\n    _6138 = param_3.attenuation_color;\n    _6139 = param_3.attenuation_distance;\n    vec3 param_4 = fa_world_pos;\n    vec3 param_5 = _6089;\n    vec3 param_6 = param_3.albedo;\n    vec3 param_7 = param_3.normal;\n    fa_apply_decals(param_4, param_5, param_6, param_7);\n    _6120 = param_6;\n    _6122 = param_7;\n    vec3 result;\n    if (fa_mesh_fs_params[3].w > 0.5)\n    {\n        result = _6120;\n    }\n    else\n    {\n        vec3 _5710 = _6122;\n        vec3 _5711 = normalize(_5710);\n        _6122 = _5711;\n        vec3 param_8 = _5711;\n        vec3 lit = (fa_indirect_diffuse(param_8) * _6120) * _6125;\n        int _5730 = fa_cl_ndir + fa_cl_local;\n        for (int ln = 0; ln < _5730; ln++)\n        {\n            int param_9 = ln;\n            int _5743 = fa_cl_light(param_9);\n            int param_10 = _5743;\n            if (fa_baked_keep(param_10) <= 0.0)\n            {\n                continue;\n            }\n            int param_11 = _5743;\n            vec3 param_12 = fa_world_pos;\n            vec3 param_13 = _6089;\n            LightSample _5759 = fa_light_shadowed(param_11, param_12, param_13);\n            SurfaceInput param_14 = SurfaceInput(fa_world_pos, _6089, fa_world_tangent, fa_uv, fa_vertex_color, _5663, gl_FrontFacing);\n            Surface param_15 = Surface(_6120, _6121, _6122, _6123, _6124, _6125, _6126, _6127, _6128, _6129, _6130, _6131, _6132, _6133, _6134, _6135, _6136, _6137, _6138, _6139);\n            LightSample param_16 = _5759;\n            lit += light(param_14, param_15, param_16);\n        }\n        result = lit;\n    }\n    vec3 _5774 = result;\n    vec3 _5775 = _5774 + _6126;\n    result = _5775;\n    vec3 param_17 = _5775;\n    vec3 param_18 = fa_world_pos;\n    result = fa_shadow_debug(param_17, param_18);\n    bool _5784 = fa_mesh_fs_params[7].w > 0.0;\n    bool _5791;\n    if (!_5784)\n    {\n        _5791 = fa_mesh_fs_params[8].y > 0.0;\n    }\n    else\n    {\n        _5791 = _5784;\n    }\n    if (_5791)\n    {\n        vec3 _5800 = fa_world_pos - fa_mesh_fs_params[0].xyz;\n        float _5806 = dot(_5800, fa_mesh_fs_params[9].xyz);\n        bool _5810 = fa_mesh_fs_params[9].w > 0.5;\n        float _5811;\n        if (_5810)\n        {\n            _5811 = _5806;\n        }\n        else\n        {\n            _5811 = length(_5800);\n        }\n        float _5823 = _5811 - fa_mesh_fs_params[8].x;\n        if (_5823 > 0.0)\n        {\n            float _5832 = fa_mesh_fs_params[7].w * _5823;\n            float tau = _5832 * _5832;\n            if (fa_mesh_fs_params[8].y > 0.0)\n            {\n                float _5848;\n                if (_5810)\n                {\n                    _5848 = fa_world_pos.y - (fa_mesh_fs_params[9].y * _5806);\n                }\n                else\n                {\n                    _5848 = fa_mesh_fs_params[0].y;\n                }\n                float _5869 = mix(_5848, fa_world_pos.y, clamp(fa_mesh_fs_params[8].x / _5811, 0.0, 1.0));\n                float _5873 = fa_world_pos.y - _5869;\n                float _5878 = _5869 - fa_mesh_fs_params[8].z;\n                float _5883 = fa_world_pos.y - fa_mesh_fs_params[8].z;\n                bool _5886 = _5878 <= 0.0;\n                bool _5887 = !_5886;\n                bool _5893;\n                if (_5887)\n                {\n                    _5893 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _5893 = _5886;\n                }\n                float _5894;\n                if (_5893)\n                {\n                    _5894 = fa_mesh_fs_params[8].y;\n                }\n                else\n                {\n                    _5894 = fa_mesh_fs_params[8].y * exp(-min(fa_mesh_fs_params[8].w * _5878, 80.0));\n                }\n                bool _5921;\n                if (_5887)\n                {\n                    _5921 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _5921 = _5886;\n                }\n                float _5922;\n                if (_5921)\n                {\n                    _5922 = fa_mesh_fs_params[8].y * _5878;\n                }\n                else\n                {\n                    _5922 = (fa_mesh_fs_params[8].y * (1.0 - exp(-min(fa_mesh_fs_params[8].w * _5878, 80.0)))) / fa_mesh_fs_params[8].w;\n                }\n                bool _5947 = _5883 <= 0.0;\n                bool _5954;\n                if (!_5947)\n                {\n                    _5954 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _5954 = _5947;\n                }\n                float _5955;\n                if (_5954)\n                {\n                    _5955 = fa_mesh_fs_params[8].y * _5883;\n                }\n                else\n                {\n                    _5955 = (fa_mesh_fs_params[8].y * (1.0 - exp(-min(fa_mesh_fs_params[8].w * _5883, 80.0)))) / fa_mesh_fs_params[8].w;\n                }\n                float _5982;\n                if (abs(_5873) < 0.001000000047497451305389404296875)\n                {\n                    _5982 = _5894;\n                }\n                else\n                {\n                    _5982 = (_5955 - _5922) / _5873;\n                }\n                tau += (_5823 * max(_5982, 0.0));\n            }\n            result = mix(result, fa_mesh_fs_params[7].xyz, vec3(clamp(1.0 - exp(-clamp(tau, 0.0, 80.0)), 0.0, 1.0)));\n        }\n    }\n    fa_frag_color = vec4(result, _6121);\n}\n\n",
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
            "inst_name": "_433",
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
            "inst_name": "_2085",
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
      "fs": "#version 430\n\nstruct SurfaceInput\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 vertex_color;\n    vec3 view_dir;\n    bool front_facing;\n};\n\nstruct LightSample\n{\n    vec3 direction;\n    vec3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct Surface\n{\n    vec3 albedo;\n    float alpha;\n    vec3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    vec3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    vec3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    vec3 specular_color;\n    float transmission;\n    float thickness;\n    vec3 attenuation_color;\n    float attenuation_distance;\n};\n\nuniform vec4 fa_mesh_fs_params[54];\nuniform vec4 fa_shadows[30];\nlayout(binding = 0) uniform sampler2D fa_light_tex_fa_shadow_smp;\nlayout(binding = 1) uniform sampler2D fa_tex_fa_smp;\nlayout(binding = 2) uniform sampler2D fa_normal_tex_fa_smp;\nlayout(binding = 3) uniform sampler2D fa_mr_tex_fa_smp;\nlayout(binding = 4) uniform sampler2D fa_occlusion_tex_fa_smp;\nlayout(binding = 5) uniform sampler2D fa_emissive_tex_fa_smp;\nlayout(binding = 6) uniform sampler2D fa_decal_tex_fa_env_smp;\nlayout(binding = 7) uniform sampler2D fa_lightmap_fa_env_smp;\nlayout(binding = 8) uniform sampler2D fa_probe_atlas_fa_env_smp;\nlayout(binding = 9) uniform sampler2D fa_light_atlas_fa_env_smp;\nlayout(binding = 10) uniform sampler2D fa_screen_tex_fa_shadow_smp;\nlayout(binding = 11) uniform sampler2D fa_shadow_tex_fa_shadow_smp;\n\nlayout(location = 0) in vec3 fa_world_pos;\nlayout(location = 5) in vec3 fa_lm;\nlayout(location = 1) in vec3 fa_world_normal;\nlayout(location = 2) in vec4 fa_world_tangent;\nlayout(location = 3) in vec2 fa_uv;\nlayout(location = 4) in vec4 fa_vertex_color;\nlayout(location = 0) out vec4 fa_frag_color;\nfloat fa_rt_slope;\nvec3 fa_light_tint;\nbool fa_light_is_area;\nint fa_cl_ndir;\nint fa_cl_slot;\nint fa_cl_local;\n\nvoid fa_inst_load()\n{\n}\n\nvec4 fa_light_texel(int t)\n{\n    return texelFetch(fa_light_tex_fa_shadow_smp, ivec2(t & 1023, t >> 10), 0);\n}\n\nvec4 fa_cluster_texel(vec3 world_pos)\n{\n    bool _1361 = fa_mesh_fs_params[19].x < 0.0;\n    bool _1368;\n    if (!_1361)\n    {\n        _1368 = fa_mesh_fs_params[19].w < 1.0;\n    }\n    else\n    {\n        _1368 = _1361;\n    }\n    bool _1376;\n    if (!_1368)\n    {\n        _1376 = fa_mesh_fs_params[18].x < 1.0;\n    }\n    else\n    {\n        _1376 = _1368;\n    }\n    bool _1383;\n    if (!_1376)\n    {\n        _1383 = fa_mesh_fs_params[18].y < 1.0;\n    }\n    else\n    {\n        _1383 = _1376;\n    }\n    bool _1390;\n    if (!_1383)\n    {\n        _1390 = fa_mesh_fs_params[19].y < 1.0;\n    }\n    else\n    {\n        _1390 = _1383;\n    }\n    if (_1390)\n    {\n        return vec4(0.0);\n    }\n    vec4 _1400 = vec4(world_pos, 1.0);\n    float _1406 = dot(fa_mesh_fs_params[16], _1400);\n    if (!(_1406 > 9.9999999747524270787835121154785e-07))\n    {\n        return vec4(0.0);\n    }\n    vec2 _1428 = vec2(dot(fa_mesh_fs_params[14], _1400), dot(fa_mesh_fs_params[15], _1400)) / vec2(_1406);\n    int _1432 = int(fa_mesh_fs_params[18].x);\n    int _1436 = int(fa_mesh_fs_params[18].y);\n    int param = (int(fa_mesh_fs_params[19].x) + (((clamp(int(floor(log2(max(dot(fa_mesh_fs_params[17].xyz, world_pos) + fa_mesh_fs_params[17].w, fa_mesh_fs_params[18].w) / fa_mesh_fs_params[18].w) * fa_mesh_fs_params[18].z)), 0, int(fa_mesh_fs_params[19].y) - 1) * _1436) + clamp(int(floor(((_1428.y * 0.5) + 0.5) * fa_mesh_fs_params[18].y)), 0, _1436 - 1)) * _1432)) + clamp(int(floor(((_1428.x * 0.5) + 0.5) * fa_mesh_fs_params[18].x)), 0, _1432 - 1);\n    return fa_light_texel(param);\n}\n\nivec2 fa_cluster_lookup(vec3 world_pos)\n{\n    vec3 param = world_pos;\n    vec4 _1512 = fa_cluster_texel(param);\n    return ivec2(int(_1512.x), int(_1512.y));\n}\n\nvoid fa_cluster_begin(vec3 world_pos)\n{\n    float _4322 = dot(fa_mesh_fs_params[29].xyz, world_pos) + fa_mesh_fs_params[29].w;\n    float _4325 = fwidth(_4322);\n    bool _4328 = fa_mesh_fs_params[25].y > 0.5;\n    bool _4335;\n    if (!_4328)\n    {\n        _4335 = fa_mesh_fs_params[25].w > 0.5;\n    }\n    else\n    {\n        _4335 = _4328;\n    }\n    if (_4335)\n    {\n        fa_rt_slope = min(1.5 * _4325, 0.100000001490116119384765625 * _4322);\n    }\n    fa_cl_ndir = int(fa_mesh_fs_params[19].z);\n    vec3 param = world_pos;\n    ivec2 _4351 = fa_cluster_lookup(param);\n    fa_cl_slot = _4351.x;\n    fa_cl_local = _4351.y;\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_linear_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvec3 fa_tex_fix(inout vec3 c, float mode)\n{\n    if (mode > 1.5)\n    {\n        vec3 param = c;\n        vec3 _4556 = fa_linear_to_srgb(param);\n        c = _4556;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            vec3 param_1 = c;\n            vec3 _4564 = fa_srgb_to_linear(param_1);\n            c = _4564;\n        }\n    }\n    return c;\n}\n\nvec3 fa_tangent_normal(SurfaceInput i, vec3 m)\n{\n    vec3 _316;\n    if (i.front_facing)\n    {\n        _316 = i.world_normal;\n    }\n    else\n    {\n        _316 = -i.world_normal;\n    }\n    vec3 _340 = normalize(i.world_tangent.xyz - (_316 * dot(_316, i.world_tangent.xyz)));\n    vec3 _367 = normalize(((_340 * m.x) + ((cross(_316, _340) * i.world_tangent.w) * m.y)) + (_316 * m.z));\n    vec3 _370;\n    if (i.front_facing)\n    {\n        _370 = _367;\n    }\n    else\n    {\n        _370 = -_367;\n    }\n    return _370;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    vec4 base_t = texture(fa_tex_fa_smp, i.uv, fa_mesh_fs_params[12].w);\n    float param = fa_mesh_fs_params[6].w;\n    float param_1 = 1.0;\n    vec3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    vec3 _4596 = fa_tex_fix(param_2, param_3);\n    vec4 _6475 = base_t;\n    _6475.x = _4596.x;\n    _6475.y = _4596.y;\n    _6475.z = _4596.z;\n    base_t = _6475;\n    vec4 _4610 = (_6475 * fa_mesh_fs_params[2]) * i.vertex_color;\n    vec3 _6288 = i.world_normal;\n    if (fa_mesh_fs_params[6].z > 0.5)\n    {\n        float param_4 = fa_mesh_fs_params[6].w;\n        float param_5 = 16.0;\n        vec3 param_6 = texture(fa_normal_tex_fa_smp, i.uv, fa_mesh_fs_params[12].w).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        vec3 _4644 = fa_tex_fix(param_6, param_7);\n        vec3 _4647 = (_4644 * 2.0) - vec3(1.0);\n        vec2 _4652 = _4647.xy * fa_mesh_fs_params[6].x;\n        vec3 _6483 = _4647;\n        _6483.x = _4652.x;\n        _6483.y = _4652.y;\n        SurfaceInput param_8 = i;\n        vec3 param_9 = _6483;\n        _6288 = fa_tangent_normal(param_8, param_9);\n    }\n    vec4 mrt = texture(fa_mr_tex_fa_smp, i.uv, fa_mesh_fs_params[12].w);\n    float param_10 = fa_mesh_fs_params[6].w;\n    float param_11 = 64.0;\n    vec3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    vec3 _4682 = fa_tex_fix(param_12, param_13);\n    vec4 _6486 = mrt;\n    _6486.x = _4682.x;\n    _6486.y = _4682.y;\n    _6486.z = _4682.z;\n    mrt = _6486;\n    vec4 _4712 = texture(fa_occlusion_tex_fa_smp, i.uv, fa_mesh_fs_params[12].w);\n    float param_14 = fa_mesh_fs_params[6].w;\n    float param_15 = 256.0;\n    vec3 param_16 = _4712.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    vec3 _4723 = fa_tex_fix(param_16, param_17);\n    float param_18 = fa_mesh_fs_params[6].w;\n    float param_19 = 4.0;\n    vec3 param_20 = texture(fa_emissive_tex_fa_smp, i.uv, fa_mesh_fs_params[12].w).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    vec3 _4755 = fa_tex_fix(param_20, param_21);\n    float _6293 = fa_mesh_fs_params[20].x;\n    float _6294 = fa_mesh_fs_params[20].y;\n    float _6297 = fa_mesh_fs_params[20].z;\n    float _6296 = fa_mesh_fs_params[21].w;\n    float _6299 = fa_mesh_fs_params[22].x;\n    if (fa_mesh_fs_params[22].z > 0.5)\n    {\n        if (mod(fa_mesh_fs_params[22].z, 2.0) > 0.5)\n        {\n            _6293 *= _4723.y;\n            _6294 *= _4723.z;\n            _6296 *= _4712.w;\n        }\n        if (fa_mesh_fs_params[22].z > 1.5)\n        {\n            _6297 *= mrt.x;\n            _6299 *= mrt.w;\n        }\n    }\n    return Surface(_4610.xyz, _4610.w, _6288, clamp(fa_mesh_fs_params[5].x * _4682.z, 0.0, 1.0), clamp(fa_mesh_fs_params[5].y * _4682.y, 0.0500000007450580596923828125, 1.0), 1.0 + (fa_mesh_fs_params[6].y * (_4723.x - 1.0)), fa_mesh_fs_params[3].xyz + (fa_mesh_fs_params[4].xyz * _4755), _6293, _6294, fa_mesh_fs_params[21].xyz, _6296, _6297, fa_mesh_fs_params[20].w, _6299, fa_mesh_fs_params[22].y, fa_mesh_fs_params[23].xyz, fa_mesh_fs_params[30].x, fa_mesh_fs_params[30].y, fa_mesh_fs_params[31].xyz, fa_mesh_fs_params[30].z);\n}\n\nvoid surface(SurfaceInput i, Surface s)\n{\n}\n\nvec4 fa_decal_tile(vec4 rect, vec2 uv, vec2 atlas, vec2 ddx, vec2 ddy)\n{\n    vec2 _1592 = rect.zw - rect.xy;\n    vec2 _1596 = _1592 * atlas;\n    vec2 _1600 = ddx * _1596;\n    vec2 _1604 = ddy * _1596;\n    return textureLod(fa_decal_tex_fa_env_smp, rect.xy + (clamp(uv, vec2(0.0), vec2(1.0)) * _1592), clamp(0.5 * log2(max(max(dot(_1600, _1600), dot(_1604, _1604)), 9.9999999392252902907785028219223e-09)), 0.0, 3.0));\n}\n\nvec3 fa_dc_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_dc_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvoid fa_apply_decals(vec3 world_pos, vec3 geo_normal, inout vec3 albedo, inout vec3 normal)\n{\n    bool _1637 = fa_mesh_fs_params[10].y < 0.5;\n    bool _1644;\n    if (!_1637)\n    {\n        _1644 = fa_mesh_fs_params[10].w < 0.5;\n    }\n    else\n    {\n        _1644 = _1637;\n    }\n    if (_1644)\n    {\n        return;\n    }\n    vec3 _1650 = dFdx(world_pos);\n    vec3 _1653 = dFdy(world_pos);\n    vec3 param = world_pos;\n    vec4 _1657 = fa_cluster_texel(param);\n    int _1661 = int(_1657.w);\n    if (_1661 < 1)\n    {\n        return;\n    }\n    int _1671 = int(fa_mesh_fs_params[10].y + 0.5);\n    int param_1 = _1671;\n    vec4 _1675 = fa_light_texel(param_1);\n    vec2 _1678 = _1675.yz;\n    int _1682 = int(_1675.w);\n    int param_2 = _1671 + 1;\n    vec4 _1687 = fa_light_texel(param_2);\n    float _1688 = _1687.x;\n    int _1694 = int(fa_mesh_fs_params[10].w + 0.5) - 1;\n    int _1698 = int(_1657.z);\n    vec3 _1963;\n    for (int k = 0; k < _1661; k++)\n    {\n        int _1711 = _1698 + k;\n        int param_3 = _1682 + (_1711 >> 2);\n        int _1728 = (_1671 + 2) + (int(fa_light_texel(param_3)[_1711 & 3]) * 7);\n        int param_4 = _1728 + 6;\n        vec4 _1733 = fa_light_texel(param_4);\n        if (((int(_1733.w + 0.5) >> _1694) & 1) == 0)\n        {\n            continue;\n        }\n        int param_5 = _1728;\n        vec4 _1748 = fa_light_texel(param_5);\n        int param_6 = _1728 + 1;\n        vec4 _1753 = fa_light_texel(param_6);\n        int param_7 = _1728 + 2;\n        vec4 _1758 = fa_light_texel(param_7);\n        vec3 _1761 = _1748.xyz;\n        float _1766 = dot(_1761, world_pos) + _1748.w;\n        vec3 _1768 = _1753.xyz;\n        float _1773 = dot(_1768, world_pos) + _1753.w;\n        vec3 _1775 = _1758.xyz;\n        float _1780 = dot(_1775, world_pos) + _1758.w;\n        bool _1785 = abs(_1766) > 0.5;\n        bool _1793;\n        if (!_1785)\n        {\n            _1793 = abs(_1773) > 0.5;\n        }\n        else\n        {\n            _1793 = _1785;\n        }\n        bool _1801;\n        if (!_1793)\n        {\n            _1801 = abs(_1780) > 0.5;\n        }\n        else\n        {\n            _1801 = _1793;\n        }\n        if (_1801)\n        {\n            continue;\n        }\n        float _1816 = clamp(dot(geo_normal, normalize(_1775)) * _1733.z, 0.0, 1.0);\n        if (_1816 <= 0.0)\n        {\n            continue;\n        }\n        float _1836 = (clamp((0.5 - abs(_1780)) * 10.0, 0.0, 1.0) * _1816) * _1733.x;\n        vec2 _1844 = vec2(_1766 + 0.5, 0.5 - _1773);\n        vec2 _1854 = vec2(dot(_1761, _1650), dot(_1768, _1650));\n        vec2 _1864 = vec2(dot(_1761, _1653), dot(_1768, _1653));\n        int param_8 = _1728 + 5;\n        vec4 _1869 = fa_light_texel(param_8);\n        int param_9 = _1728 + 3;\n        vec4 _1874 = fa_light_texel(param_9);\n        int param_10 = _1728 + 4;\n        vec4 _1879 = fa_light_texel(param_10);\n        float tex_a = 1.0;\n        vec3 col = _1869.xyz;\n        bool _1889 = _1874.z > _1874.x;\n        if (_1889)\n        {\n            vec4 param_11 = _1874;\n            vec2 param_12 = _1844;\n            vec2 param_13 = _1678;\n            vec2 param_14 = _1854;\n            vec2 param_15 = _1864;\n            vec4 tx = fa_decal_tile(param_11, param_12, param_13, param_14, param_15);\n            if ((_1688 > 0.5) && (_1688 < 1.5))\n            {\n                vec3 param_16 = tx.xyz;\n                vec3 _1915 = fa_dc_to_linear(param_16);\n                vec4 _6376 = tx;\n                _6376.x = _1915.x;\n                _6376.y = _1915.y;\n                _6376.z = _1915.z;\n                tx = _6376;\n            }\n            col *= tx.xyz;\n            tex_a = tx.w;\n        }\n        albedo = mix(albedo, col, vec3(clamp((_1836 * tex_a) * _1869.w, 0.0, 1.0)));\n        if (_1879.z > _1879.x)\n        {\n            vec4 param_17 = _1879;\n            vec2 param_18 = _1844;\n            vec2 param_19 = _1678;\n            vec2 param_20 = _1854;\n            vec2 param_21 = _1864;\n            vec4 _1959 = fa_decal_tile(param_17, param_18, param_19, param_20, param_21);\n            if (_1688 > 1.5)\n            {\n                vec3 param_22 = _1959.xyz;\n                vec3 _1969 = fa_dc_to_srgb(param_22);\n                _1963 = _1969;\n            }\n            else\n            {\n                _1963 = _1959.xyz;\n            }\n            vec3 _1978 = (_1963 * 2.0) - vec3(1.0);\n            vec2 _1983 = _1978.xy * _1733.y;\n            vec3 _2005 = (normalize(_1761) * _1983.x) + (normalize(_1768) * _1983.y);\n            vec3 _2008 = normalize(normal);\n            normal = normalize(mix(_2008, normalize((_2008 * max(_1978.z, 0.0500000007450580596923828125)) + (_2005 - (_2008 * dot(_2008, _2005)))), vec3(clamp(_1836 * (_1889 ? tex_a : 1.0), 0.0, 1.0))));\n        }\n    }\n}\n\nvec2 fa_atlas_size()\n{\n    return vec2(textureSize(fa_probe_atlas_fa_env_smp, 0));\n}\n\nvec3 fa_probe_sh_coef(vec2 origin, float res, int k)\n{\n    vec3 v = textureLod(fa_probe_atlas_fa_env_smp, (origin + vec2(float(k) + 0.5, res + 2.5)) / fa_atlas_size(), 0.0).xyz;\n    if (fa_mesh_fs_params[41].y > 0.5)\n    {\n        v = ((v * 255.0) - vec3(128.0)) * 0.03149606287479400634765625;\n    }\n    return v;\n}\n\nvec3 fa_sh_eval(vec3 c[9], vec3 n)\n{\n    vec3 _3785 = max((((c[0] * 0.2820948064327239990234375) + (((c[1] * (0.3257350027561187744140625 * n.y)) + (c[2] * (0.3257350027561187744140625 * n.z))) + (c[3] * (0.3257350027561187744140625 * n.x)))) + (((c[4] * ((0.2731371223926544189453125 * n.x) * n.y)) + (c[5] * ((0.2731371223926544189453125 * n.y) * n.z))) + (c[6] * (0.078847892582416534423828125 * (((3.0 * n.z) * n.z) - 1.0))))) + ((c[7] * ((0.2731371223926544189453125 * n.x) * n.z)) + (c[8] * (0.13656856119632720947265625 * ((n.x * n.x) - (n.y * n.y))))), vec3(0.0));\n    return _3785;\n}\n\nvec3 fa_ambient_light(vec3 n)\n{\n    float _3894 = (1.0 - fa_mesh_fs_params[42].w) - fa_mesh_fs_params[47].w;\n    vec3 amb = vec3(0.0);\n    bool _3900 = fa_mesh_fs_params[11].w > 0.5;\n    vec3 c[9];\n    for (int k = 0; k < 9; k++)\n    {\n        c[k] = vec3(0.0);\n    }\n    if (_3894 > 0.0005000000237487256526947021484375)\n    {\n        if (_3900)\n        {\n            for (int k_1 = 0; k_1 < 9; k_1++)\n            {\n                vec2 param = fa_mesh_fs_params[41].zw;\n                float param_1 = 128.0;\n                int param_2 = k_1;\n                c[k_1] = fa_probe_sh_coef(param, param_1, param_2) * _3894;\n            }\n        }\n        else\n        {\n            amb = fa_mesh_fs_params[1].xyz * _3894;\n        }\n    }\n    bool _3952 = fa_mesh_fs_params[42].w > 0.0;\n    if (_3952)\n    {\n        for (int k_2 = 0; k_2 < 9; k_2++)\n        {\n            vec2 param_3 = fa_mesh_fs_params[42].xy;\n            float param_4 = fa_mesh_fs_params[42].z;\n            int param_5 = k_2;\n            c[k_2] += (fa_probe_sh_coef(param_3, param_4, param_5) * fa_mesh_fs_params[42].w);\n        }\n    }\n    bool _3983 = fa_mesh_fs_params[47].w > 0.0;\n    if (_3983)\n    {\n        for (int k_3 = 0; k_3 < 9; k_3++)\n        {\n            vec2 param_6 = fa_mesh_fs_params[47].xy;\n            float param_7 = fa_mesh_fs_params[47].z;\n            int param_8 = k_3;\n            c[k_3] += (fa_probe_sh_coef(param_6, param_7, param_8) * fa_mesh_fs_params[47].w);\n        }\n    }\n    if ((_3900 || _3952) || _3983)\n    {\n        vec3 param_9[9] = c;\n        vec3 param_10 = n;\n        amb += fa_sh_eval(param_9, param_10);\n    }\n    return amb;\n}\n\nvec4 fa_gi_fetch(vec2 texel)\n{\n    return textureLod(fa_probe_atlas_fa_env_smp, texel / fa_atlas_size(), 0.0);\n}\n\nvec2 fa_oct_encode(vec3 d)\n{\n    vec3 _3805 = d / vec3(max((abs(d.x) + abs(d.y)) + abs(d.z), 9.9999999600419720025001879548654e-13));\n    float _3808 = _3805.x;\n    float _3810 = _3805.z;\n    vec2 e = vec2(_3808, _3810);\n    if (_3805.y < 0.0)\n    {\n        e = vec2((1.0 - abs(_3810)) * ((_3808 < 0.0) ? (-1.0) : 1.0), (1.0 - abs(_3808)) * ((_3810 < 0.0) ? (-1.0) : 1.0));\n    }\n    return e;\n}\n\nvec3 fa_gi_grid(int rec, vec3 n, vec3 v, out float cover)\n{\n    cover = 0.0;\n    int param = rec;\n    vec4 _4869 = fa_light_texel(param);\n    int param_1 = rec + 1;\n    vec4 _4874 = fa_light_texel(param_1);\n    int param_2 = rec + 2;\n    vec4 _4879 = fa_light_texel(param_2);\n    int param_3 = rec + 3;\n    vec4 _4884 = fa_light_texel(param_3);\n    bool _4887 = _4884.z < 0.5;\n    bool _4895;\n    if (!_4887)\n    {\n        _4895 = fa_atlas_size().y < 1155.0;\n    }\n    else\n    {\n        _4895 = _4887;\n    }\n    if (_4895)\n    {\n        return vec3(0.0);\n    }\n    float _4902 = max(_4869.w, 9.9999997473787516355514526367188e-05);\n    vec3 _4905 = _4874.xyz;\n    vec3 _4909 = _4869.xyz;\n    vec3 _4913 = (fa_world_pos - _4909) / vec3(_4902);\n    vec3 _4922 = min(_4913 + vec3(0.5), (_4905 - vec3(0.5)) - _4913);\n    float _4931 = min(_4922.x, min(_4922.y, _4922.z));\n    if (!(_4931 > 0.0))\n    {\n        return vec3(0.0);\n    }\n    vec3 _4946 = _4905 - vec3(1.0);\n    vec3 _4947 = clamp(_4913, vec3(0.0), _4946);\n    vec3 _4955 = min(floor(_4947), max(_4905 - vec3(2.0), vec3(0.0)));\n    vec3 _4959 = _4947 - _4955;\n    vec3 _4971 = fa_world_pos + (((n * 0.800000011920928955078125) + (v * 0.20000000298023223876953125)) * (0.20000000298023223876953125 * _4902));\n    int _4976 = int(_4879.y + 0.5);\n    float _4981 = 0.3257350027561187744140625 * n.y;\n    float _4985 = 0.3257350027561187744140625 * n.z;\n    float _4989 = 0.3257350027561187744140625 * n.x;\n    float _4996 = (0.2731371223926544189453125 * n.x) * n.y;\n    float _5003 = (0.2731371223926544189453125 * n.y) * n.z;\n    float _5012 = 0.078847892582416534423828125 * (((3.0 * n.z) * n.z) - 1.0);\n    float _5019 = (0.2731371223926544189453125 * n.x) * n.z;\n    float _5032 = 0.13656856119632720947265625 * ((n.x * n.x) - (n.y * n.y));\n    vec3 acc = vec3(0.0);\n    float wsum = 0.0;\n    int _5039 = 8 + int(_4884.w);\n    float _5066;\n    float _5079;\n    float _5093;\n    for (int k = 0; k < _5039; k++)\n    {\n        float _5052 = float(k & 1);\n        float _5056 = float((k >> 1) & 1);\n        float _5060 = float((k >> 2) & 1);\n        if (_5052 > 0.5)\n        {\n            _5066 = _4959.x;\n        }\n        else\n        {\n            _5066 = 1.0 - _4959.x;\n        }\n        if (_5056 > 0.5)\n        {\n            _5079 = _4959.y;\n        }\n        else\n        {\n            _5079 = 1.0 - _4959.y;\n        }\n        if (_5060 > 0.5)\n        {\n            _5093 = _4959.z;\n        }\n        else\n        {\n            _5093 = 1.0 - _4959.z;\n        }\n        float _5103 = (_5066 * _5079) * _5093;\n        if (!(_5103 > 0.0))\n        {\n            continue;\n        }\n        vec3 _5116 = min(_4955 + vec3(_5052, _5056, _5060), _4946);\n        int _5136 = int(((_4879.x + _5116.x) + (_4874.x * (_5116.y + (_4874.y * _5116.z)))) + 0.5);\n        vec2 _5151 = vec2(float(_5136 % _4976) * 10.0, 1024.0 + (float(_5136 / _4976) * 11.0));\n        vec2 param_4 = _5151 + vec2(9.5, 10.5);\n        vec4 _5159 = fa_gi_fetch(param_4);\n        bool _5162 = _5159.y < 0.5;\n        bool _5171;\n        if (!_5162)\n        {\n            _5171 = _5159.x > _4884.y;\n        }\n        else\n        {\n            _5171 = _5162;\n        }\n        if (_5171)\n        {\n            continue;\n        }\n        vec3 _5183 = _4971 - (_4909 + (_5116 * _4902));\n        float _5186 = length(_5183);\n        vec3 _5192 = _5183 / vec3(max(_5186, 9.9999997473787516355514526367188e-05));\n        float _5202 = max(9.9999997473787516355514526367188e-05, (dot(-_5192, n) + 1.0) * 0.5);\n        float w = _5103 * (_5202 * _5202);\n        vec3 param_5 = _5192;\n        vec2 param_6 = (_5151 + vec2(1.0)) + (((fa_oct_encode(param_5) * 0.5) + vec2(0.5)) * 8.0);\n        vec4 _5222 = fa_gi_fetch(param_6);\n        float _5229 = _5186 / max(_4879.z, 9.9999997473787516355514526367188e-05);\n        float _5232 = _5222.x;\n        if (_5229 > _5232)\n        {\n            float _5245 = max(_5222.y - (_5232 * _5232), 0.0);\n            float _5250 = _5229 - _5232;\n            float _5259 = _5245 / max(_5245 + (_5250 * _5250), 9.9999999600419720025001879548654e-13);\n            w *= ((_5259 * _5259) * _5259);\n        }\n        if (!(w > 0.0))\n        {\n            continue;\n        }\n        vec2 param_7 = _5151 + vec2(0.5, 10.5);\n        vec2 param_8 = _5151 + vec2(1.5, 10.5);\n        vec2 param_9 = _5151 + vec2(2.5, 10.5);\n        vec2 param_10 = _5151 + vec2(3.5, 10.5);\n        vec2 param_11 = _5151 + vec2(4.5, 10.5);\n        vec2 param_12 = _5151 + vec2(5.5, 10.5);\n        vec2 param_13 = _5151 + vec2(6.5, 10.5);\n        vec2 param_14 = _5151 + vec2(7.5, 10.5);\n        vec2 param_15 = _5151 + vec2(8.5, 10.5);\n        acc += ((((((((((fa_gi_fetch(param_7).xyz * 0.2820948064327239990234375) + (fa_gi_fetch(param_8).xyz * _4981)) + (fa_gi_fetch(param_9).xyz * _4985)) + (fa_gi_fetch(param_10).xyz * _4989)) + (fa_gi_fetch(param_11).xyz * _4996)) + (fa_gi_fetch(param_12).xyz * _5003)) + (fa_gi_fetch(param_13).xyz * _5012)) + (fa_gi_fetch(param_14).xyz * _5019)) + (fa_gi_fetch(param_15).xyz * _5032)) * w);\n        wsum += w;\n    }\n    if (!(wsum > 9.9999997473787516355514526367188e-06))\n    {\n        return vec3(0.0);\n    }\n    cover = smoothstep(0.0, 1.0, clamp(_4931 * 2.0, 0.0, 1.0)) * smoothstep(0.0, 0.0199999995529651641845703125, wsum);\n    float _5387;\n    if (fa_mesh_fs_params[52].z > 0.5)\n    {\n        _5387 = _4884.x;\n    }\n    else\n    {\n        _5387 = 1.0;\n    }\n    return max(acc / vec3(wsum), vec3(0.0)) * (_4879.w * _5387);\n}\n\nvec3 fa_gi_light(vec3 n, inout float left)\n{\n    left = 1.0;\n    vec3 acc = vec3(0.0);\n    vec3 _5411 = normalize(fa_mesh_fs_params[0].xyz - fa_world_pos);\n    int _5416 = int(fa_mesh_fs_params[52].x + 0.5);\n    int _5421 = int(fa_mesh_fs_params[52].y + 0.5);\n    float param_3;\n    for (int k = 0; (k < _5421) && (k < 8); k++)\n    {\n        int param = _5416 + (4 * k);\n        vec3 param_1 = n;\n        vec3 param_2 = _5411;\n        vec3 _5446 = fa_gi_grid(param, param_1, param_2, param_3);\n        float _5451 = param_3 * left;\n        acc += (_5446 * _5451);\n        left -= _5451;\n        if (left < 0.001000000047497451305389404296875)\n        {\n            left = 0.0;\n            break;\n        }\n    }\n    return acc;\n}\n\nvec3 fa_realtime_or_ambient(vec3 n)\n{\n    vec3 gi = vec3(0.0);\n    float left = 1.0;\n    if (fa_mesh_fs_params[52].y > 0.5)\n    {\n        vec3 param = n;\n        float param_1;\n        vec3 _5480 = fa_gi_light(param, param_1);\n        left = param_1;\n        gi = _5480;\n    }\n    if (left <= 0.0)\n    {\n        return gi;\n    }\n    vec3 param_2 = n;\n    return gi + (fa_ambient_light(param_2) * left);\n}\n\nvec3 fa_indirect_diffuse(vec3 n)\n{\n    if (fa_lm.z > 0.5)\n    {\n        return textureLod(fa_lightmap_fa_env_smp, fa_lm.xy, 0.0).xyz;\n    }\n    if (fa_mesh_fs_params[53].x > 0.5)\n    {\n        vec4 _5522 = vec4(fa_world_pos, 1.0);\n        vec2 _5541 = vec2(dot(fa_mesh_fs_params[26], _5522), dot(fa_mesh_fs_params[27], _5522)) / vec2(max(dot(fa_mesh_fs_params[28], _5522), 9.9999997473787516355514526367188e-05));\n        float _5550;\n        if (fa_mesh_fs_params[24].y > 0.5)\n        {\n            _5550 = (_5541.y * 0.5) + 0.5;\n        }\n        else\n        {\n            _5550 = 0.5 - (_5541.y * 0.5);\n        }\n        return texelFetch(fa_lightmap_fa_env_smp, clamp(ivec2(vec2((_5541.x * 0.5) + 0.5, _5550) * fa_mesh_fs_params[24].zw), ivec2(0), ivec2(fa_mesh_fs_params[24].zw) - ivec2(1)), 0).xyz;\n    }\n    if (fa_mesh_fs_params[32].w > 0.0)\n    {\n        vec3 c[9];\n        for (int k = 0; k < 9; k++)\n        {\n            c[k] = fa_mesh_fs_params[k * 1 + 32].xyz;\n        }\n        vec3 param = n;\n        vec3 param_1[9] = c;\n        vec3 param_2 = n;\n        return mix(fa_ambient_light(param), fa_sh_eval(param_1, param_2), vec3(clamp(fa_mesh_fs_params[32].w, 0.0, 1.0)));\n    }\n    vec3 param_3 = n;\n    return fa_realtime_or_ambient(param_3);\n}\n\nint fa_cluster_index(int slot, int n)\n{\n    int param = (int(fa_mesh_fs_params[19].x) + int(fa_mesh_fs_params[19].w)) + ((slot + n) >> 2);\n    vec4 t = fa_light_texel(param);\n    return int(t[(slot + n) & 3]);\n}\n\nint fa_cl_light(int n)\n{\n    if (n < fa_cl_ndir)\n    {\n        return n;\n    }\n    int param = fa_cl_slot;\n    int param_1 = n - fa_cl_ndir;\n    return fa_cluster_index(param, param_1);\n}\n\nint fa_light_base(int li)\n{\n    return li * ((fa_mesh_fs_params[1].w > 4.5) ? 8 : 4);\n}\n\nbool fa_light_baked(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 3;\n    return fa_light_texel(param_1).w > 0.5;\n}\n\nfloat fa_baked_keep(int li)\n{\n    float _4292;\n    if (fa_lm.z > 0.5)\n    {\n        _4292 = 0.0;\n    }\n    else\n    {\n        _4292 = 1.0 - clamp(fa_mesh_fs_params[32].w, 0.0, 1.0);\n    }\n    bool _4303 = _4292 < 1.0;\n    bool _4309;\n    if (_4303)\n    {\n        int param = li;\n        _4309 = fa_light_baked(param);\n    }\n    else\n    {\n        _4309 = _4303;\n    }\n    return _4309 ? _4292 : 1.0;\n}\n\nfloat fa_light_type(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 1;\n    return fa_light_texel(param_1).w;\n}\n\nvec3 fa_area_point(vec3 c, vec3 axis, vec3 ru, vec3 uu, float hx, float hy, float shape, vec3 p, vec3 r)\n{\n    bool _611 = dot(r, r) > 0.5;\n    if (shape > 1.5)\n    {\n        vec3 _624 = (c - (ru * hx)) - p;\n        vec3 _630 = ru * (2.0 * hx);\n        float _636 = max(dot(_630, _630), 9.9999999392252902907785028219223e-09);\n        float _640 = dot(_624, _630);\n        float t = clamp((-_640) / _636, 0.0, 1.0);\n        if (_611)\n        {\n            float _655 = dot(r, _630);\n            float _661 = _636 - (_655 * _655);\n            if (abs(_661) > (9.9999997473787516355514526367188e-06 * _636))\n            {\n                t = clamp(((dot(r, _624) * _655) - _640) / _661, 0.0, 1.0);\n            }\n        }\n        return (p + _624) + (_630 * t);\n    }\n    vec3 q = p;\n    float _693 = dot(r, axis);\n    bool _701;\n    if (_611)\n    {\n        _701 = abs(_693) > 9.9999997473787516355514526367188e-05;\n    }\n    else\n    {\n        _701 = _611;\n    }\n    if (_701)\n    {\n        float _711 = dot(c - p, axis) / _693;\n        if (_711 > 0.0)\n        {\n            q = p + (r * _711);\n        }\n    }\n    vec3 _724 = q - c;\n    vec2 xy = vec2(dot(_724, ru), dot(_724, uu));\n    if (shape > 0.5)\n    {\n        float _739 = length(xy);\n        if (_739 > hx)\n        {\n            xy *= (hx / _739);\n        }\n    }\n    else\n    {\n        xy = clamp(xy, vec2(-hx, -hy), vec2(hx, hy));\n    }\n    return (c + (ru * xy.x)) + (uu * xy.y);\n}\n\nvec4 fa_atlas_fetch(vec2 texel)\n{\n    return textureLod(fa_light_atlas_fa_env_smp, texel / vec2(textureSize(fa_light_atlas_fa_env_smp, 0)), 0.0);\n}\n\nvec3 fa_cookie_sample(vec2 tile_origin, vec2 uv)\n{\n    vec2 param = (tile_origin + vec2(1.0)) + (clamp(uv, vec2(0.0), vec2(1.0)) * 254.0);\n    return fa_atlas_fetch(param).xyz;\n}\n\nfloat fa_ies_sample(vec2 tile_origin, vec3 d, vec3 axis, vec3 right, vec3 up)\n{\n    float _531 = dot(d, right);\n    float _535 = dot(d, up);\n    float _546;\n    if (((_531 * _531) + (_535 * _535)) > 1.0000000133514319600180897396058e-10)\n    {\n        _546 = atan(_535, _531) * 0.15915493667125701904296875;\n    }\n    else\n    {\n        _546 = 0.0;\n    }\n    vec2 param = tile_origin + vec2(1.0 + ((_546 - floor(_546)) * 64.0), 1.0 + (acos(clamp(dot(d, axis), -1.0, 1.0)) * 10.18591594696044921875));\n    return fa_atlas_fetch(param).x;\n}\n\nint fa_cube_face(vec3 d)\n{\n    vec3 _382 = abs(d);\n    float _384 = _382.x;\n    float _386 = _382.y;\n    bool _387 = _384 >= _386;\n    bool _395;\n    if (_387)\n    {\n        _395 = _384 >= _382.z;\n    }\n    else\n    {\n        _395 = _387;\n    }\n    int _396;\n    if (_395)\n    {\n        _396 = (d.x > 0.0) ? 0 : 1;\n    }\n    else\n    {\n        int _410;\n        if (_386 >= _382.z)\n        {\n            _410 = (d.y > 0.0) ? 2 : 3;\n        }\n        else\n        {\n            _410 = (d.z > 0.0) ? 4 : 5;\n        }\n        _396 = _410;\n    }\n    return _396;\n}\n\nvoid fa_cube_face_basis(int f, out vec3 fwd, out vec3 up)\n{\n    if (f == 0)\n    {\n        fwd = vec3(1.0, 0.0, 0.0);\n        up = vec3(0.0, 1.0, 0.0);\n    }\n    else\n    {\n        if (f == 1)\n        {\n            fwd = vec3(-1.0, 0.0, 0.0);\n            up = vec3(0.0, 1.0, 0.0);\n        }\n        else\n        {\n            if (f == 2)\n            {\n                fwd = vec3(0.0, 1.0, 0.0);\n                up = vec3(0.0, 0.0, 1.0);\n            }\n            else\n            {\n                if (f == 3)\n                {\n                    fwd = vec3(0.0, -1.0, 0.0);\n                    up = vec3(0.0, 0.0, -1.0);\n                }\n                else\n                {\n                    if (f == 4)\n                    {\n                        fwd = vec3(0.0, 0.0, 1.0);\n                        up = vec3(0.0, 1.0, 0.0);\n                    }\n                    else\n                    {\n                        fwd = vec3(0.0, 0.0, -1.0);\n                        up = vec3(0.0, 1.0, 0.0);\n                    }\n                }\n            }\n        }\n    }\n}\n\nLightSample fa_light_sample_n(int li, vec3 world_pos, vec3 n)\n{\n    int param = li;\n    int _777 = fa_light_base(param);\n    bool _781 = fa_mesh_fs_params[1].w > 4.5;\n    int param_1 = _777;\n    vec4 _785 = fa_light_texel(param_1);\n    int param_2 = _777 + 1;\n    vec4 _790 = fa_light_texel(param_2);\n    float _793 = _790.w;\n    float atten = 1.0;\n    float dist = 0.0;\n    fa_light_tint = vec3(1.0);\n    bool _805 = _781 && (_793 > 2.5);\n    fa_light_is_area = _805;\n    bool _807 = _793 < 0.5;\n    vec3 l;\n    if (_807)\n    {\n        l = normalize(_785.xyz);\n        if (_781)\n        {\n            int param_3 = _777 + 6;\n            vec4 _821 = fa_light_texel(param_3);\n            if (_821.z > 0.5)\n            {\n                int param_4 = _777 + 4;\n                vec4 _831 = fa_light_texel(param_4);\n                int param_5 = _777 + 5;\n                vec4 _836 = fa_light_texel(param_5);\n                vec2 param_6 = _821.xy;\n                vec2 param_7 = fract(vec2(dot(world_pos, _831.xyz) * _831.w, (-dot(world_pos, _836.xyz)) * _836.w) + vec2(0.5));\n                fa_light_tint = fa_cookie_sample(param_6, param_7);\n            }\n        }\n    }\n    else\n    {\n        vec3 _866 = _785.xyz;\n        vec3 _868 = _866 - world_pos;\n        vec3 to_light = _868;\n        float _871 = length(_868);\n        float reach = _871;\n        bool front = true;\n        if (_805)\n        {\n            int param_8 = _777 + 7;\n            reach = max(_871 - fa_light_texel(param_8).w, 0.0);\n            int param_9 = _777 + 4;\n            vec4 _895 = fa_light_texel(param_9);\n            int param_10 = _777 + 5;\n            vec4 _900 = fa_light_texel(param_10);\n            int param_11 = _777 + 6;\n            vec4 _905 = fa_light_texel(param_11);\n            float _906 = _905.w;\n            int param_12 = _777 + 2;\n            vec3 _913 = normalize(fa_light_texel(param_12).xyz);\n            bool _915 = _906 > 1.5;\n            bool _923;\n            if (!_915)\n            {\n                _923 = dot(_913, to_light) < 0.0;\n            }\n            else\n            {\n                _923 = _915;\n            }\n            front = _923;\n            vec3 r = vec3(0.0);\n            vec3 _932 = fa_mesh_fs_params[0].xyz - world_pos;\n            bool _936 = dot(n, n) > 0.5;\n            bool _944;\n            if (_936)\n            {\n                _944 = dot(_932, _932) > 9.9999999600419720025001879548654e-13;\n            }\n            else\n            {\n                _944 = _936;\n            }\n            if (_944)\n            {\n                r = reflect(-normalize(_932), normalize(n));\n            }\n            vec3 param_13 = _866;\n            vec3 param_14 = _913;\n            vec3 param_15 = _895.xyz;\n            vec3 param_16 = _900.xyz;\n            float param_17 = _895.w;\n            float param_18 = _900.w;\n            float param_19 = _906;\n            vec3 param_20 = world_pos;\n            vec3 param_21 = r;\n            to_light = fa_area_point(param_13, param_14, param_15, param_16, param_17, param_18, param_19, param_20, param_21) - world_pos;\n        }\n        float _980 = length(to_light);\n        dist = _980;\n        l = to_light / vec3(max(_980, 9.9999997473787516355514526367188e-05));\n        float _994 = reach / max(_785.w, 0.001000000047497451305389404296875);\n        float _1000 = clamp(1.0 - (_994 * _994), 0.0, 1.0);\n        float _1002;\n        if (front)\n        {\n            _1002 = _1000 * _1000;\n        }\n        else\n        {\n            _1002 = 0.0;\n        }\n        atten = _1002;\n        bool _1013 = _793 < 2.5;\n        if ((_793 > 1.5) && _1013)\n        {\n            int param_22 = _777 + 2;\n            vec4 _1021 = fa_light_texel(param_22);\n            float _1031 = _1021.w;\n            int param_23 = _777 + 3;\n            vec4 _1036 = fa_light_texel(param_23);\n            float _1037 = _1036.x;\n            float cos_inner = _1037;\n            if (_1037 > 1.5)\n            {\n                cos_inner = mix(_1031, 1.0, 0.25);\n            }\n            atten *= smoothstep(_1031, cos_inner, dot(-l, normalize(_1021.xyz)));\n        }\n        if (_781 && (_793 < 1.5))\n        {\n            int param_24 = _777 + 6;\n            vec4 _1061 = fa_light_texel(param_24);\n            if (_1061.z > 0.5)\n            {\n                vec3 _1069 = -to_light;\n                int param_25 = _777 + 4;\n                int param_26 = _777 + 5;\n                vec3 _1083 = fa_light_texel(param_25).xyz;\n                vec3 _1087 = fa_light_texel(param_26).xyz;\n                vec3 _1096 = vec3(dot(_1069, _1083), dot(_1069, _1087), dot(_1069, cross(_1083, _1087)));\n                vec3 param_27 = _1096;\n                int _1100 = fa_cube_face(param_27);\n                int param_28 = _1100;\n                vec3 param_29;\n                vec3 param_30;\n                fa_cube_face_basis(param_28, param_29, param_30);\n                vec2 _1127 = vec2(dot(_1096, cross(param_29, param_30)), dot(_1096, param_30)) / vec2(max(dot(_1096, param_29), 9.9999997473787516355514526367188e-05));\n                int _1131 = _1100 / 3;\n                vec2 param_31 = _1061.xy + (vec2(float(_1100 - (_1131 * 3)), float(_1131)) * 256.0);\n                vec2 param_32 = vec2(0.5 + (0.5 * _1127.x), 0.5 - (0.5 * _1127.y));\n                fa_light_tint = fa_cookie_sample(param_31, param_32);\n            }\n            int param_33 = _777 + 7;\n            vec4 _1161 = fa_light_texel(param_33);\n            if (_1161.z > 0.5)\n            {\n                int param_34 = _777 + 2;\n                int param_35 = _777 + 4;\n                int param_36 = _777 + 5;\n                vec2 param_37 = _1161.xy;\n                vec3 param_38 = -l;\n                vec3 param_39 = normalize(fa_light_texel(param_34).xyz);\n                vec3 param_40 = fa_light_texel(param_35).xyz;\n                vec3 param_41 = fa_light_texel(param_36).xyz;\n                atten *= fa_ies_sample(param_37, param_38, param_39, param_40, param_41);\n            }\n        }\n        else\n        {\n            if (_781 && _1013)\n            {\n                int param_42 = _777 + 6;\n                vec4 _1208 = fa_light_texel(param_42);\n                int param_43 = _777 + 7;\n                vec4 _1213 = fa_light_texel(param_43);\n                bool _1216 = _1208.z > 0.5;\n                bool _1223;\n                if (!_1216)\n                {\n                    _1223 = _1213.z > 0.5;\n                }\n                else\n                {\n                    _1223 = _1216;\n                }\n                if (_1223)\n                {\n                    int param_44 = _777 + 2;\n                    vec4 _1230 = fa_light_texel(param_44);\n                    vec3 _1234 = normalize(_1230.xyz);\n                    int param_45 = _777 + 4;\n                    vec4 _1239 = fa_light_texel(param_45);\n                    int param_46 = _777 + 5;\n                    vec4 _1244 = fa_light_texel(param_46);\n                    if (_1216)\n                    {\n                        vec3 _1252 = -to_light;\n                        float _1259 = _1230.w;\n                        float _1275 = 0.5 / max(dot(_1252, _1234) * (sqrt(max(1.0 - (_1259 * _1259), 0.0)) / max(_1259, 0.001000000047497451305389404296875)), 9.9999997473787516355514526367188e-05);\n                        vec2 param_47 = _1208.xy;\n                        vec2 param_48 = vec2(0.5 + (dot(_1252, _1239.xyz) * _1275), 0.5 - (dot(_1252, _1244.xyz) * _1275));\n                        fa_light_tint = fa_cookie_sample(param_47, param_48);\n                    }\n                    if (_1213.z > 0.5)\n                    {\n                        vec2 param_49 = _1213.xy;\n                        vec3 param_50 = -l;\n                        vec3 param_51 = _1234;\n                        vec3 param_52 = _1239.xyz;\n                        vec3 param_53 = _1244.xyz;\n                        atten *= fa_ies_sample(param_49, param_50, param_51, param_52, param_53);\n                    }\n                }\n            }\n        }\n    }\n    vec3 _6242 = _790.xyz * atten;\n    if (_781)\n    {\n        _6242 *= fa_light_tint;\n    }\n    int _1343;\n    if (_807)\n    {\n        _1343 = 0;\n    }\n    else\n    {\n        _1343 = ((_793 > 1.5) && (_793 < 2.5)) ? 2 : 1;\n    }\n    return LightSample(l, _6242, atten, 1.0, dist, _1343);\n}\n\nfloat fa_rt_local_tap(ivec2 p, ivec2 size, float d, float tol, float div, inout float best)\n{\n    vec4 _3304 = texelFetch(fa_screen_tex_fa_shadow_smp, clamp(p, ivec2(0), size - ivec2(1)), 0);\n    bool _3307 = _3304.w > 0.5;\n    bool _3317;\n    if (_3307)\n    {\n        _3317 = abs(d - _3304.x) <= tol;\n    }\n    else\n    {\n        _3317 = _3307;\n    }\n    if (_3317)\n    {\n        best = min(best, mod(floor(_3304.z / div), 256.0) * 0.0039215688593685626983642578125);\n    }\n    return best;\n}\n\nfloat fa_shadow_depth(inout vec2 uv, vec4 rect)\n{\n    uv = clamp(uv, rect.xy, rect.zw);\n    return textureLod(fa_shadow_tex_fa_shadow_smp, uv, 0.0).x;\n}\n\nfloat fa_shadow_fetch(vec2 uv, vec4 rect, vec3 conv)\n{\n    vec2 param = uv;\n    vec4 param_1 = rect;\n    float _2132 = fa_shadow_depth(param, param_1);\n    float _2136;\n    if (conv.x < 0.5)\n    {\n        _2136 = _2132;\n    }\n    else\n    {\n        _2136 = (conv.y * conv.z) / (conv.z - (_2132 * (conv.z - conv.y)));\n    }\n    return _2136;\n}\n\nfloat fa_shadow_noise()\n{\n    return fract(52.98291778564453125 * fract(dot(gl_FragCoord.xy, vec2(0.067110560834407806396484375, 0.005837149918079376220703125))));\n}\n\nvec2 fa_shadow_vogel_turn(vec2 d)\n{\n    return vec2((d.x * (-0.737368881702423095703125)) - (d.y * 0.675490319728851318359375), (d.y * (-0.737368881702423095703125)) + (d.x * 0.675490319728851318359375));\n}\n\nfloat fa_shadow_filter(vec2 uv, vec4 rect, float zr, float texel_m, float unit, float reach, float plane, vec3 conv, int mode, float k)\n{\n    if (mode == 1)\n    {\n        vec2 param = uv;\n        vec4 param_1 = rect;\n        vec3 param_2 = conv;\n        return float(zr <= fa_shadow_fetch(param, param_1, param_2));\n    }\n    float _2182 = fa_shadow_noise() * 6.283185482025146484375;\n    vec2 _2188 = vec2(cos(_2182), sin(_2182));\n    vec2 dir = _2188;\n    float radius = 1.5;\n    if (mode == 2)\n    {\n        float _2197;\n        if (k < 0.0)\n        {\n            _2197 = (-k) / max(zr, 0.100000001490116119384765625);\n        }\n        else\n        {\n            _2197 = k;\n        }\n        float _2216 = clamp((_2197 * reach) / texel_m, 3.0, 12.0);\n        float sum = 0.0;\n        float cnt = 0.0;\n        for (int i = 0; i < 16; i++)\n        {\n            float _2235 = sqrt((float(i) + 0.5) * 0.0625) * _2216;\n            vec2 param_3 = uv + (dir * (fa_shadows[26].zw * _2235));\n            vec4 param_4 = rect;\n            vec3 param_5 = conv;\n            float _2249 = fa_shadow_fetch(param_3, param_4, param_5);\n            if (_2249 < (zr - (_2235 * plane)))\n            {\n                sum += _2249;\n                cnt += 1.0;\n            }\n            vec2 param_6 = dir;\n            dir = fa_shadow_vogel_turn(param_6);\n        }\n        if (cnt < 0.5)\n        {\n            return 1.0;\n        }\n        float _2277 = sum / cnt;\n        float _2287;\n        if (k < 0.0)\n        {\n            _2287 = (-k) / max(_2277, 0.0500000007450580596923828125);\n        }\n        else\n        {\n            _2287 = k;\n        }\n        radius = clamp(((max(zr - _2277, 0.0) * unit) * _2287) / texel_m, 1.5, 16.0);\n        dir = _2188;\n    }\n    float lit = 0.0;\n    int _2313 = (mode == 2) ? 24 : 16;\n    for (int i_1 = 0; i_1 < _2313; i_1++)\n    {\n        float _2332 = sqrt((float(i_1) + 0.5) / float(_2313)) * radius;\n        vec2 param_7 = uv + (dir * (fa_shadows[26].zw * _2332));\n        vec4 param_8 = rect;\n        vec3 param_9 = conv;\n        lit += float((zr - (_2332 * plane)) <= fa_shadow_fetch(param_7, param_8, param_9));\n        vec2 param_10 = dir;\n        dir = fa_shadow_vogel_turn(param_10);\n    }\n    return lit / float(_2313);\n}\n\nfloat fa_shadow_local(int li, vec3 lpos, vec3 world, vec3 n, vec3 l)\n{\n    bool _2537 = fa_mesh_fs_params[5].z < 0.5;\n    bool _2544;\n    if (!_2537)\n    {\n        _2544 = fa_shadows[29].x < 0.5;\n    }\n    else\n    {\n        _2544 = _2537;\n    }\n    if (_2544)\n    {\n        return 1.0;\n    }\n    int param = (int(fa_shadows[29].x + 0.5) - 1) + li;\n    vec4 _2557 = fa_light_texel(param);\n    float _2558 = _2557.x;\n    if (_2558 < 0.0)\n    {\n        return 1.0;\n    }\n    int _2567 = int(_2558 + 0.5);\n    int param_1 = _2567;\n    vec4 _2571 = fa_light_texel(param_1);\n    int param_2 = _2567 + 1;\n    vec4 _2576 = fa_light_texel(param_2);\n    float fade = 1.0;\n    float _2579 = _2571.y;\n    if (_2579 > 0.0)\n    {\n        float _2596 = 1.0 - smoothstep(0.75 * _2579, _2579, length(world - fa_shadows[27].xyz));\n        fade = _2596;\n        if (_2596 <= 0.0)\n        {\n            return 1.0;\n        }\n    }\n    int face = 0;\n    if (_2571.x > 1.5)\n    {\n        vec3 param_3 = world - lpos;\n        face = fa_cube_face(param_3);\n    }\n    int _2620 = (_2567 + 2) + (face * 6);\n    int param_4 = _2620;\n    int param_5 = _2620 + 1;\n    int param_6 = _2620 + 3;\n    vec4 _2634 = fa_light_texel(param_6);\n    int param_7 = _2620 + 4;\n    vec4 _2639 = fa_light_texel(param_7);\n    int param_8 = _2620 + 5;\n    vec4 _2644 = fa_light_texel(param_8);\n    float _2656 = _2644.x * max(dot(_2634, vec4(world, 1.0)), 0.001000000047497451305389404296875);\n    float _2661 = clamp(dot(n, l), 0.0, 1.0);\n    float _2684 = clamp(dot(n, _2634.xyz), -1.0, 1.0);\n    float _2703 = min(sqrt(1.0 - (_2684 * _2684)) / max(abs(dot(n, world - lpos)) / max(dot(_2634, vec4(world, 1.0)), 0.001000000047497451305389404296875), 0.20000000298023223876953125), 4.0);\n    float _2706 = _2576.y;\n    float _2708;\n    if (_2706 > 0.0)\n    {\n        _2708 = _2706;\n    }\n    else\n    {\n        _2708 = 1.5 * _2656;\n    }\n    vec4 _2728 = vec4(world + (n * (_2708 * sqrt(1.0 - (_2661 * _2661)))), 1.0);\n    float _2732 = dot(_2634, _2728);\n    float _2735 = _2644.y;\n    if (_2732 < _2735)\n    {\n        return 1.0;\n    }\n    vec2 _2750 = vec2(dot(fa_light_texel(param_4), _2728), dot(fa_light_texel(param_5), _2728)) / vec2(_2732);\n    float _2752 = _2750.x;\n    bool _2755 = _2752 < _2639.x;\n    bool _2764;\n    if (!_2755)\n    {\n        _2764 = _2752 > _2639.z;\n    }\n    else\n    {\n        _2764 = _2755;\n    }\n    bool _2773;\n    if (!_2764)\n    {\n        _2773 = _2750.y < _2639.y;\n    }\n    else\n    {\n        _2773 = _2764;\n    }\n    bool _2782;\n    if (!_2773)\n    {\n        _2782 = _2750.y > _2639.w;\n    }\n    else\n    {\n        _2782 = _2773;\n    }\n    if (_2782)\n    {\n        return 1.0;\n    }\n    float _2788 = _2576.x;\n    float _2790;\n    if (_2788 > 0.0)\n    {\n        _2790 = _2788;\n    }\n    else\n    {\n        _2790 = 1.5 * _2656;\n    }\n    vec2 param_9 = _2750;\n    vec4 param_10 = _2639;\n    float param_11 = _2732 - (_2790 * (1.0 + (0.5 * _2703)));\n    float param_12 = _2656;\n    float param_13 = 1.0;\n    float param_14 = _2644.z * 0.25;\n    float param_15 = (_2656 * min(_2703, 3.0)) * 0.5;\n    vec3 param_16 = vec3(1.0, _2735, _2644.z);\n    int param_17 = int(_2571.z + 0.5);\n    float param_18 = _2571.w;\n    return mix(1.0, fa_shadow_filter(param_9, param_10, param_11, param_12, param_13, param_14, param_15, param_16, param_17, param_18), fade);\n}\n\nfloat fa_shadow_local_rt(int li, vec3 lpos, vec3 world, vec3 n, vec3 l)\n{\n    bool _3335 = fa_mesh_fs_params[25].w > 0.5;\n    bool _3341;\n    if (_3335)\n    {\n        _3341 = fa_mesh_fs_params[5].z > 0.5;\n    }\n    else\n    {\n        _3341 = _3335;\n    }\n    bool _3347;\n    if (_3341)\n    {\n        _3347 = fa_shadows[29].x > 0.5;\n    }\n    else\n    {\n        _3347 = _3341;\n    }\n    if (_3347)\n    {\n        int param = (int(fa_shadows[29].x + 0.5) - 1) + li;\n        vec4 _3359 = fa_light_texel(param);\n        float _3360 = _3359.z;\n        if (_3360 > 0.5)\n        {\n            float _3373 = dot(fa_mesh_fs_params[29].xyz, world) + fa_mesh_fs_params[29].w;\n            float _3379 = ((0.00200000009499490261077880859375 * _3373) + 0.00999999977648258209228515625) + fa_rt_slope;\n            vec4 _3385 = vec4(world, 1.0);\n            float _3390 = dot(fa_mesh_fs_params[28], _3385);\n            if (_3390 > 9.9999997473787516355514526367188e-05)\n            {\n                vec2 _3407 = vec2(dot(fa_mesh_fs_params[26], _3385), dot(fa_mesh_fs_params[27], _3385)) / vec2(_3390);\n                float _3412 = (_3407.x * 0.5) + 0.5;\n                float _3416;\n                if (fa_mesh_fs_params[24].y > 0.5)\n                {\n                    _3416 = (_3407.y * 0.5) + 0.5;\n                }\n                else\n                {\n                    _3416 = 0.5 - (_3407.y * 0.5);\n                }\n                bool _3432 = _3412 >= 0.0;\n                bool _3438;\n                if (_3432)\n                {\n                    _3438 = _3412 < 1.0;\n                }\n                else\n                {\n                    _3438 = _3432;\n                }\n                bool _3444;\n                if (_3438)\n                {\n                    _3444 = _3416 >= 0.0;\n                }\n                else\n                {\n                    _3444 = _3438;\n                }\n                bool _3450;\n                if (_3444)\n                {\n                    _3450 = _3416 < 1.0;\n                }\n                else\n                {\n                    _3450 = _3444;\n                }\n                if (_3450)\n                {\n                    ivec2 _3457 = ivec2(fa_mesh_fs_params[24].zw);\n                    ivec2 _3468 = clamp(ivec2(vec2(_3412, _3416) * fa_mesh_fs_params[24].zw), ivec2(0), _3457 - ivec2(1));\n                    float _3472;\n                    if (_3360 < 1.5)\n                    {\n                        _3472 = 1.0;\n                    }\n                    else\n                    {\n                        _3472 = (_3360 < 2.5) ? 256.0 : 65536.0;\n                    }\n                    float best = 2.0;\n                    vec4 _3488 = texelFetch(fa_screen_tex_fa_shadow_smp, _3468, 0);\n                    bool _3491 = _3488.w > 0.5;\n                    bool _3501;\n                    if (_3491)\n                    {\n                        _3501 = abs(_3373 - _3488.x) <= _3379;\n                    }\n                    else\n                    {\n                        _3501 = _3491;\n                    }\n                    if (_3501)\n                    {\n                        best = mod(floor(_3488.z / _3472), 256.0) * 0.0039215688593685626983642578125;\n                    }\n                    else\n                    {\n                        ivec2 param_1 = _3468 + ivec2(-1);\n                        ivec2 param_2 = _3457;\n                        float param_3 = _3373;\n                        float param_4 = _3379;\n                        float param_5 = _3472;\n                        float param_6 = best;\n                        float _3527 = fa_rt_local_tap(param_1, param_2, param_3, param_4, param_5, param_6);\n                        best = _3527;\n                        ivec2 param_7 = _3468 + ivec2(0, -1);\n                        ivec2 param_8 = _3457;\n                        float param_9 = _3373;\n                        float param_10 = _3379;\n                        float param_11 = _3472;\n                        float param_12 = _3527;\n                        float _3542 = fa_rt_local_tap(param_7, param_8, param_9, param_10, param_11, param_12);\n                        best = _3542;\n                        ivec2 param_13 = _3468 + ivec2(1, -1);\n                        ivec2 param_14 = _3457;\n                        float param_15 = _3373;\n                        float param_16 = _3379;\n                        float param_17 = _3472;\n                        float param_18 = _3542;\n                        float _3557 = fa_rt_local_tap(param_13, param_14, param_15, param_16, param_17, param_18);\n                        best = _3557;\n                        ivec2 param_19 = _3468 + ivec2(-1, 0);\n                        ivec2 param_20 = _3457;\n                        float param_21 = _3373;\n                        float param_22 = _3379;\n                        float param_23 = _3472;\n                        float param_24 = _3557;\n                        float _3572 = fa_rt_local_tap(param_19, param_20, param_21, param_22, param_23, param_24);\n                        best = _3572;\n                        ivec2 param_25 = _3468 + ivec2(1, 0);\n                        ivec2 param_26 = _3457;\n                        float param_27 = _3373;\n                        float param_28 = _3379;\n                        float param_29 = _3472;\n                        float param_30 = _3572;\n                        float _3587 = fa_rt_local_tap(param_25, param_26, param_27, param_28, param_29, param_30);\n                        best = _3587;\n                        ivec2 param_31 = _3468 + ivec2(-1, 1);\n                        ivec2 param_32 = _3457;\n                        float param_33 = _3373;\n                        float param_34 = _3379;\n                        float param_35 = _3472;\n                        float param_36 = _3587;\n                        float _3602 = fa_rt_local_tap(param_31, param_32, param_33, param_34, param_35, param_36);\n                        best = _3602;\n                        ivec2 param_37 = _3468 + ivec2(0, 1);\n                        ivec2 param_38 = _3457;\n                        float param_39 = _3373;\n                        float param_40 = _3379;\n                        float param_41 = _3472;\n                        float param_42 = _3602;\n                        float _3617 = fa_rt_local_tap(param_37, param_38, param_39, param_40, param_41, param_42);\n                        best = _3617;\n                        ivec2 param_43 = _3468 + ivec2(1);\n                        ivec2 param_44 = _3457;\n                        float param_45 = _3373;\n                        float param_46 = _3379;\n                        float param_47 = _3472;\n                        float param_48 = _3617;\n                        float _3632 = fa_rt_local_tap(param_43, param_44, param_45, param_46, param_47, param_48);\n                        best = _3632;\n                    }\n                    if (best <= 1.0)\n                    {\n                        float _3640;\n                        if (fa_mesh_fs_params[25].z > 0.5)\n                        {\n                            int param_49 = li;\n                            vec3 param_50 = lpos;\n                            vec3 param_51 = world;\n                            vec3 param_52 = n;\n                            vec3 param_53 = l;\n                            _3640 = min(best, fa_shadow_local(param_49, param_50, param_51, param_52, param_53));\n                        }\n                        else\n                        {\n                            _3640 = best;\n                        }\n                        return _3640;\n                    }\n                }\n            }\n            float _3663;\n            if (fa_mesh_fs_params[25].z > 0.5)\n            {\n                int param_54 = li;\n                vec3 param_55 = lpos;\n                vec3 param_56 = world;\n                vec3 param_57 = n;\n                vec3 param_58 = l;\n                _3663 = fa_shadow_local(param_54, param_55, param_56, param_57, param_58);\n            }\n            else\n            {\n                _3663 = 1.0;\n            }\n            return _3663;\n        }\n    }\n    int param_59 = li;\n    vec3 param_60 = lpos;\n    vec3 param_61 = world;\n    vec3 param_62 = n;\n    vec3 param_63 = l;\n    return fa_shadow_local(param_59, param_60, param_61, param_62, param_63);\n}\n\nfloat fa_shadow_split_at(int i)\n{\n    float _2075;\n    if (i == 0)\n    {\n        _2075 = fa_shadows[24].x;\n    }\n    else\n    {\n        float _2091;\n        if (i == 1)\n        {\n            _2091 = fa_shadows[24].y;\n        }\n        else\n        {\n            float _2099;\n            if (i == 2)\n            {\n                _2099 = fa_shadows[24].z;\n            }\n            else\n            {\n                _2099 = fa_shadows[24].w;\n            }\n            _2091 = _2099;\n        }\n        _2075 = _2091;\n    }\n    return _2075;\n}\n\nfloat fa_shadow_cascade(int ci, vec3 world, vec3 n, vec3 l)\n{\n    float _2378 = max(fa_shadows[ci * 1 + 20].y, 0.001000000047497451305389404296875);\n    float _2383 = clamp(dot(n, l), 0.0, 1.0);\n    float _2389 = sqrt(1.0 - (_2383 * _2383));\n    float _2397 = min(_2389 / max(_2383, 0.20000000298023223876953125), 4.0);\n    float _2402;\n    if (fa_shadows[26].y > 0.0)\n    {\n        _2402 = fa_shadows[26].y;\n    }\n    else\n    {\n        _2402 = 1.5 * fa_shadows[ci * 1 + 20].x;\n    }\n    vec4 _2427 = mat4(fa_shadows[ci * 4 + 0], fa_shadows[ci * 4 + 1], fa_shadows[ci * 4 + 2], fa_shadows[ci * 4 + 3]) * vec4(world + (n * (_2402 * _2389)), 1.0);\n    float _2434 = _2427.x;\n    bool _2437 = _2434 < fa_shadows[ci * 1 + 16].x;\n    bool _2446;\n    if (!_2437)\n    {\n        _2446 = _2434 > fa_shadows[ci * 1 + 16].z;\n    }\n    else\n    {\n        _2446 = _2437;\n    }\n    bool _2455;\n    if (!_2446)\n    {\n        _2455 = _2427.y < fa_shadows[ci * 1 + 16].y;\n    }\n    else\n    {\n        _2455 = _2446;\n    }\n    bool _2464;\n    if (!_2455)\n    {\n        _2464 = _2427.y > fa_shadows[ci * 1 + 16].w;\n    }\n    else\n    {\n        _2464 = _2455;\n    }\n    bool _2471;\n    if (!_2464)\n    {\n        _2471 = _2427.z > 1.0;\n    }\n    else\n    {\n        _2471 = _2464;\n    }\n    if (_2471)\n    {\n        return -1.0;\n    }\n    float _2479;\n    if (fa_shadows[26].x > 0.0)\n    {\n        _2479 = fa_shadows[26].x;\n    }\n    else\n    {\n        _2479 = 1.5 * fa_shadows[ci * 1 + 20].x;\n    }\n    vec2 param = _2427.xy;\n    vec4 param_1 = fa_shadows[ci * 1 + 16];\n    float param_2 = _2427.z - ((_2479 * (1.0 + (0.5 * _2397))) / _2378);\n    float param_3 = fa_shadows[ci * 1 + 20].x;\n    float param_4 = _2378;\n    float param_5 = _2378 * 0.25;\n    float param_6 = ((fa_shadows[ci * 1 + 20].x * min(_2397, 3.0)) * 0.5) / _2378;\n    vec3 param_7 = vec3(0.0);\n    int param_8 = int(fa_shadows[25].z + 0.5);\n    float param_9 = fa_shadows[25].w;\n    return fa_shadow_filter(param, param_1, param_2, param_3, param_4, param_5, param_6, param_7, param_8, param_9);\n}\n\nfloat fa_shadow_sun(vec3 world, vec3 n, vec3 l)\n{\n    if (fa_mesh_fs_params[5].z < 0.5)\n    {\n        return 1.0;\n    }\n    int _2857 = int(fa_shadows[25].x + 0.5);\n    if (_2857 < 1)\n    {\n        return 1.0;\n    }\n    float _2872 = dot(world - fa_shadows[27].xyz, fa_shadows[28].xyz);\n    int param = _2857 - 1;\n    if (_2872 > fa_shadow_split_at(param))\n    {\n        return 1.0;\n    }\n    int ci = 0;\n    bool _2884 = _2857 > 1;\n    bool _2891;\n    if (_2884)\n    {\n        _2891 = _2872 > fa_shadows[24].x;\n    }\n    else\n    {\n        _2891 = _2884;\n    }\n    if (_2891)\n    {\n        ci = 1;\n    }\n    bool _2895 = _2857 > 2;\n    bool _2902;\n    if (_2895)\n    {\n        _2902 = _2872 > fa_shadows[24].y;\n    }\n    else\n    {\n        _2902 = _2895;\n    }\n    if (_2902)\n    {\n        ci = 2;\n    }\n    bool _2906 = _2857 > 3;\n    bool _2913;\n    if (_2906)\n    {\n        _2913 = _2872 > fa_shadows[24].z;\n    }\n    else\n    {\n        _2913 = _2906;\n    }\n    if (_2913)\n    {\n        ci = 3;\n    }\n    float s = -1.0;\n    float s2 = -1.0;\n    float t = 0.0;\n    int _2924 = min(_2857, 4);\n    float _2965;\n    for (int c = ci; c < _2924; c++)\n    {\n        int param_1 = c;\n        vec3 param_2 = world;\n        vec3 param_3 = n;\n        vec3 param_4 = l;\n        float _2944 = fa_shadow_cascade(param_1, param_2, param_3, param_4);\n        if (s >= 0.0)\n        {\n            s2 = _2944;\n            break;\n        }\n        if (_2944 < 0.0)\n        {\n            continue;\n        }\n        s = _2944;\n        ci = c;\n        if (fa_shadows[25].y > 0.0)\n        {\n            if (ci > 0)\n            {\n                int param_5 = ci - 1;\n                _2965 = fa_shadow_split_at(param_5);\n            }\n            else\n            {\n                _2965 = fa_shadows[28].w;\n            }\n            int param_6 = ci;\n            float _2984 = fa_shadows[25].y * max(fa_shadow_split_at(param_6) - _2965, 9.9999997473787516355514526367188e-05);\n            int param_7 = ci;\n            t = clamp((_2872 - (fa_shadow_split_at(param_7) - _2984)) / _2984, 0.0, 1.0);\n        }\n        if (t <= 0.0)\n        {\n            break;\n        }\n    }\n    if (s < 0.0)\n    {\n        return 1.0;\n    }\n    if (t > 0.0)\n    {\n        float _3016;\n        if ((ci + 1) < _2857)\n        {\n            _3016 = (s2 < 0.0) ? s : s2;\n        }\n        else\n        {\n            _3016 = 1.0;\n        }\n        s = mix(s, _3016, t);\n    }\n    return s;\n}\n\nfloat fa_shadow_factor(vec3 n, vec3 l)\n{\n    bool _3121 = fa_mesh_fs_params[25].y > 0.5;\n    bool _3127;\n    if (_3121)\n    {\n        _3127 = fa_mesh_fs_params[5].z > 0.5;\n    }\n    else\n    {\n        _3127 = _3121;\n    }\n    if (_3127)\n    {\n        float _3141 = dot(fa_mesh_fs_params[29].xyz, fa_world_pos) + fa_mesh_fs_params[29].w;\n        vec4 _3149 = vec4(fa_world_pos, 1.0);\n        float _3155 = dot(fa_mesh_fs_params[28], _3149);\n        if (_3155 > 9.9999997473787516355514526367188e-05)\n        {\n            vec2 _3174 = vec2(dot(fa_mesh_fs_params[26], _3149), dot(fa_mesh_fs_params[27], _3149)) / vec2(_3155);\n            float _3179 = (_3174.x * 0.5) + 0.5;\n            float _3183;\n            if (fa_mesh_fs_params[24].y > 0.5)\n            {\n                _3183 = (_3174.y * 0.5) + 0.5;\n            }\n            else\n            {\n                _3183 = 0.5 - (_3174.y * 0.5);\n            }\n            bool _3199 = _3179 >= 0.0;\n            bool _3205;\n            if (_3199)\n            {\n                _3205 = _3179 < 1.0;\n            }\n            else\n            {\n                _3205 = _3199;\n            }\n            bool _3211;\n            if (_3205)\n            {\n                _3211 = _3183 >= 0.0;\n            }\n            else\n            {\n                _3211 = _3205;\n            }\n            bool _3217;\n            if (_3211)\n            {\n                _3217 = _3183 < 1.0;\n            }\n            else\n            {\n                _3217 = _3211;\n            }\n            if (_3217)\n            {\n                vec4 _3242 = texelFetch(fa_screen_tex_fa_shadow_smp, clamp(ivec2(vec2(_3179, _3183) * fa_mesh_fs_params[24].zw), ivec2(0), ivec2(fa_mesh_fs_params[24].zw) - ivec2(1)), 0);\n                bool _3245 = _3242.w > 0.5;\n                bool _3261;\n                if (_3245)\n                {\n                    _3261 = abs(_3141 - _3242.x) <= (((0.00200000009499490261077880859375 * _3141) + 0.00999999977648258209228515625) + fa_rt_slope);\n                }\n                else\n                {\n                    _3261 = _3245;\n                }\n                if (_3261)\n                {\n                    float _3267;\n                    if (fa_mesh_fs_params[25].z > 0.5)\n                    {\n                        vec3 param = fa_world_pos;\n                        vec3 param_1 = n;\n                        vec3 param_2 = l;\n                        _3267 = min(_3242.y, fa_shadow_sun(param, param_1, param_2));\n                    }\n                    else\n                    {\n                        _3267 = _3242.y;\n                    }\n                    return _3267;\n                }\n            }\n        }\n    }\n    vec3 param_3 = fa_world_pos;\n    vec3 param_4 = n;\n    vec3 param_5 = l;\n    return fa_shadow_sun(param_3, param_4, param_5);\n}\n\nfloat fa_contact_shadow(int li, vec3 world, vec3 gn, vec3 l, float dist)\n{\n    bool _4034 = fa_mesh_fs_params[24].x < 0.5;\n    bool _4041;\n    if (!_4034)\n    {\n        _4041 = fa_shadows[29].x < 0.5;\n    }\n    else\n    {\n        _4041 = _4034;\n    }\n    if (_4041)\n    {\n        return 1.0;\n    }\n    int param = (int(fa_shadows[29].x + 0.5) - 1) + li;\n    vec4 _4054 = fa_light_texel(param);\n    float _4055 = _4054.y;\n    float len = _4055;\n    if (_4055 <= 0.0)\n    {\n        return 1.0;\n    }\n    float _4067 = length(world - fa_mesh_fs_params[0].xyz);\n    float _4076 = 1.0 - smoothstep(0.5 * fa_mesh_fs_params[25].x, fa_mesh_fs_params[25].x, _4067);\n    if (_4076 <= 0.0)\n    {\n        return 1.0;\n    }\n    float _4082 = len;\n    float _4085 = min(_4082, 0.89999997615814208984375 * dist);\n    len = _4085;\n    float _4091 = 0.004999999888241291046142578125 + (0.0030000000260770320892333984375 * _4067);\n    float _4096 = _4091 + (0.5 * _4085);\n    vec3 _4102 = world + (gn * _4091);\n    float _4104 = fa_shadow_noise();\n    float occ = 0.0;\n    float _4166;\n    for (int k = 0; k < 12; k++)\n    {\n        float _4120 = (float(k) + _4104) * 0.083333335816860198974609375;\n        vec3 _4128 = _4102 + (l * (_4120 * len));\n        vec4 _4134 = vec4(_4128, 1.0);\n        float _4139 = dot(fa_mesh_fs_params[28], _4134);\n        if (_4139 < 9.9999997473787516355514526367188e-05)\n        {\n            break;\n        }\n        vec2 _4157 = vec2(dot(fa_mesh_fs_params[26], _4134), dot(fa_mesh_fs_params[27], _4134)) / vec2(_4139);\n        float _4161 = _4157.x * 0.5;\n        float _4162 = _4161 + 0.5;\n        if (fa_mesh_fs_params[24].y > 0.5)\n        {\n            _4166 = (_4157.y * 0.5) + 0.5;\n        }\n        else\n        {\n            _4166 = 0.5 - (_4157.y * 0.5);\n        }\n        bool _4182 = _4162 < 0.0;\n        bool _4189;\n        if (!_4182)\n        {\n            _4189 = _4162 >= 1.0;\n        }\n        else\n        {\n            _4189 = _4182;\n        }\n        bool _4196;\n        if (!_4189)\n        {\n            _4196 = _4166 < 0.0;\n        }\n        else\n        {\n            _4196 = _4189;\n        }\n        bool _4203;\n        if (!_4196)\n        {\n            _4203 = _4166 >= 1.0;\n        }\n        else\n        {\n            _4203 = _4196;\n        }\n        if (_4203)\n        {\n            break;\n        }\n        vec4 _4227 = texelFetch(fa_screen_tex_fa_shadow_smp, clamp(ivec2(vec2(_4162, _4166) * fa_mesh_fs_params[24].zw), ivec2(0), ivec2(fa_mesh_fs_params[24].zw) - ivec2(1)), 0);\n        if (_4227.w < 0.5)\n        {\n            continue;\n        }\n        float _4245 = (dot(fa_mesh_fs_params[29].xyz, _4128) + fa_mesh_fs_params[29].w) - _4227.x;\n        if ((_4245 > _4091) && (_4245 < _4096))\n        {\n            occ = max(occ, (1.0 - (_4120 * _4120)) * smoothstep(0.0, 0.0500000007450580596923828125, min(min(_4162, 0.5 - _4161), min(_4166, 1.0 - _4166))));\n        }\n    }\n    return 1.0 - (occ * _4076);\n}\n\nLightSample fa_light_shadowed(int li, vec3 world_pos, vec3 gn)\n{\n    int param = li;\n    float _4377 = fa_baked_keep(param);\n    if (_4377 <= 0.0)\n    {\n        int param_1 = li;\n        return LightSample(vec3(0.0, 1.0, 0.0), vec3(0.0), 0.0, 1.0, 0.0, int(fa_light_type(param_1) + 0.5));\n    }\n    int param_2 = li;\n    vec3 param_3 = world_pos;\n    vec3 param_4 = gn;\n    LightSample _4403 = fa_light_sample_n(param_2, param_3, param_4);\n    vec3 _6268 = _4403.color;\n    float _6269 = _4403.attenuation;\n    float _6270 = _4403.shadow;\n    bool _4406 = _4403.type == 0;\n    if (_4406 && (li == 0))\n    {\n        vec3 param_5 = gn;\n        vec3 param_6 = _4403.direction;\n        float _4417 = fa_shadow_factor(param_5, param_6);\n        _6270 = _4417;\n        _6268 *= _4417;\n    }\n    else\n    {\n        bool _4428 = _4403.type != 0;\n        bool _4434;\n        if (_4428)\n        {\n            _4434 = _6269 > 0.0;\n        }\n        else\n        {\n            _4434 = _4428;\n        }\n        if (_4434)\n        {\n            int param_7 = li;\n            int param_8 = fa_light_base(param_7);\n            int param_9 = li;\n            vec3 param_10 = fa_light_texel(param_8).xyz;\n            vec3 param_11 = world_pos;\n            vec3 param_12 = gn;\n            vec3 param_13 = _4403.direction;\n            float _4453 = fa_shadow_local_rt(param_9, param_10, param_11, param_12, param_13);\n            _6270 = _4453;\n            _6268 *= _4453;\n        }\n    }\n    bool _4463 = fa_mesh_fs_params[24].x > 0.5;\n    bool _4469;\n    if (_4463)\n    {\n        _4469 = _6269 > 0.0;\n    }\n    else\n    {\n        _4469 = _4463;\n    }\n    if (_4469)\n    {\n        float _4476;\n        if (_4406)\n        {\n            _4476 = 1000000000.0;\n        }\n        else\n        {\n            _4476 = _4403._distance;\n        }\n        int param_14 = li;\n        vec3 param_15 = world_pos;\n        vec3 param_16 = gn;\n        vec3 param_17 = _4403.direction;\n        float param_18 = _4476;\n        float _4494 = fa_contact_shadow(param_14, param_15, param_16, param_17, param_18);\n        _6270 *= _4494;\n        _6268 *= _4494;\n    }\n    float _4507 = _6269;\n    float _4508 = _4507 * _4377;\n    _6269 = _4508;\n    vec3 _4512 = _6268;\n    vec3 _4513 = _4512 * _4377;\n    _6268 = _4513;\n    return LightSample(_4403.direction, _4513, _4508, _6270, _4403._distance, _4403.type);\n}\n\nvec3 light(SurfaceInput i, Surface s, LightSample l)\n{\n    return vec3(0.0);\n}\n\nvec3 fa_shadow_debug(vec3 color, vec3 world)\n{\n    if (fa_shadows[27].w < 0.5)\n    {\n        return color;\n    }\n    int _3044 = int(fa_shadows[25].x + 0.5);\n    float _3054 = dot(world - fa_shadows[27].xyz, fa_shadows[28].xyz);\n    vec3 tint = vec3(0.3499999940395355224609375);\n    bool _3059 = _3044 > 0;\n    bool _3068;\n    if (_3059)\n    {\n        int param = _3044 - 1;\n        _3068 = _3054 <= fa_shadow_split_at(param);\n    }\n    else\n    {\n        _3068 = _3059;\n    }\n    if (_3068)\n    {\n        tint = vec3(1.0, 0.1500000059604644775390625, 0.100000001490116119384765625);\n        bool _3074 = _3044 > 1;\n        bool _3081;\n        if (_3074)\n        {\n            _3081 = _3054 > fa_shadows[24].x;\n        }\n        else\n        {\n            _3081 = _3074;\n        }\n        if (_3081)\n        {\n            tint = vec3(0.100000001490116119384765625, 0.89999997615814208984375, 0.20000000298023223876953125);\n        }\n        bool _3087 = _3044 > 2;\n        bool _3094;\n        if (_3087)\n        {\n            _3094 = _3054 > fa_shadows[24].y;\n        }\n        else\n        {\n            _3094 = _3087;\n        }\n        if (_3094)\n        {\n            tint = vec3(0.1500000059604644775390625, 0.300000011920928955078125, 1.0);\n        }\n        bool _3100 = _3044 > 3;\n        bool _3107;\n        if (_3100)\n        {\n            _3107 = _3054 > fa_shadows[24].z;\n        }\n        else\n        {\n            _3107 = _3100;\n        }\n        if (_3107)\n        {\n            tint = vec3(1.0, 0.89999997615814208984375, 0.100000001490116119384765625);\n        }\n    }\n    return mix(color, tint, vec3(0.550000011920928955078125));\n}\n\nvoid main()\n{\n    fa_rt_slope = 0.0;\n    fa_inst_load();\n    vec3 _6089 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _6089 = -_6089;\n    }\n    vec3 _5663 = normalize(fa_mesh_fs_params[0].xyz - fa_world_pos);\n    vec3 param = fa_world_pos;\n    fa_cluster_begin(param);\n    SurfaceInput param_1 = SurfaceInput(fa_world_pos, _6089, fa_world_tangent, fa_uv, fa_vertex_color, _5663, gl_FrontFacing);\n    Surface _5671 = fa_standard_surface(param_1);\n    vec3 _6120 = _5671.albedo;\n    float _6121 = _5671.alpha;\n    vec3 _6122 = _5671.normal;\n    float _6123 = _5671.metallic;\n    float _6124 = _5671.roughness;\n    float _6125 = _5671.occlusion;\n    vec3 _6126 = _5671.emission;\n    float _6127 = _5671.clearcoat;\n    float _6128 = _5671.clearcoat_roughness;\n    vec3 _6129 = _5671.sheen_color;\n    float _6130 = _5671.sheen_roughness;\n    float _6131 = _5671.anisotropy;\n    float _6132 = _5671.anisotropy_rotation;\n    float _6133 = _5671.specular;\n    float _6134 = _5671.ior;\n    vec3 _6135 = _5671.specular_color;\n    float _6136 = _5671.transmission;\n    float _6137 = _5671.thickness;\n    vec3 _6138 = _5671.attenuation_color;\n    float _6139 = _5671.attenuation_distance;\n    SurfaceInput param_2 = SurfaceInput(fa_world_pos, _6089, fa_world_tangent, fa_uv, fa_vertex_color, _5663, gl_FrontFacing);\n    Surface param_3 = _5671;\n    surface(param_2, param_3);\n    _6120 = param_3.albedo;\n    _6121 = param_3.alpha;\n    _6122 = param_3.normal;\n    _6123 = param_3.metallic;\n    _6124 = param_3.roughness;\n    _6125 = param_3.occlusion;\n    _6126 = param_3.emission;\n    _6127 = param_3.clearcoat;\n    _6128 = param_3.clearcoat_roughness;\n    _6129 = param_3.sheen_color;\n    _6130 = param_3.sheen_roughness;\n    _6131 = param_3.anisotropy;\n    _6132 = param_3.anisotropy_rotation;\n    _6133 = param_3.specular;\n    _6134 = param_3.ior;\n    _6135 = param_3.specular_color;\n    _6136 = param_3.transmission;\n    _6137 = param_3.thickness;\n    _6138 = param_3.attenuation_color;\n    _6139 = param_3.attenuation_distance;\n    vec3 param_4 = fa_world_pos;\n    vec3 param_5 = _6089;\n    vec3 param_6 = param_3.albedo;\n    vec3 param_7 = param_3.normal;\n    fa_apply_decals(param_4, param_5, param_6, param_7);\n    _6120 = param_6;\n    _6122 = param_7;\n    vec3 result;\n    if (fa_mesh_fs_params[3].w > 0.5)\n    {\n        result = _6120;\n    }\n    else\n    {\n        vec3 _5710 = _6122;\n        vec3 _5711 = normalize(_5710);\n        _6122 = _5711;\n        vec3 param_8 = _5711;\n        vec3 lit = (fa_indirect_diffuse(param_8) * _6120) * _6125;\n        int _5730 = fa_cl_ndir + fa_cl_local;\n        for (int ln = 0; ln < _5730; ln++)\n        {\n            int param_9 = ln;\n            int _5743 = fa_cl_light(param_9);\n            int param_10 = _5743;\n            if (fa_baked_keep(param_10) <= 0.0)\n            {\n                continue;\n            }\n            int param_11 = _5743;\n            vec3 param_12 = fa_world_pos;\n            vec3 param_13 = _6089;\n            LightSample _5759 = fa_light_shadowed(param_11, param_12, param_13);\n            SurfaceInput param_14 = SurfaceInput(fa_world_pos, _6089, fa_world_tangent, fa_uv, fa_vertex_color, _5663, gl_FrontFacing);\n            Surface param_15 = Surface(_6120, _6121, _6122, _6123, _6124, _6125, _6126, _6127, _6128, _6129, _6130, _6131, _6132, _6133, _6134, _6135, _6136, _6137, _6138, _6139);\n            LightSample param_16 = _5759;\n            lit += light(param_14, param_15, param_16);\n        }\n        result = lit;\n    }\n    vec3 _5774 = result;\n    vec3 _5775 = _5774 + _6126;\n    result = _5775;\n    vec3 param_17 = _5775;\n    vec3 param_18 = fa_world_pos;\n    result = fa_shadow_debug(param_17, param_18);\n    bool _5784 = fa_mesh_fs_params[7].w > 0.0;\n    bool _5791;\n    if (!_5784)\n    {\n        _5791 = fa_mesh_fs_params[8].y > 0.0;\n    }\n    else\n    {\n        _5791 = _5784;\n    }\n    if (_5791)\n    {\n        vec3 _5800 = fa_world_pos - fa_mesh_fs_params[0].xyz;\n        float _5806 = dot(_5800, fa_mesh_fs_params[9].xyz);\n        bool _5810 = fa_mesh_fs_params[9].w > 0.5;\n        float _5811;\n        if (_5810)\n        {\n            _5811 = _5806;\n        }\n        else\n        {\n            _5811 = length(_5800);\n        }\n        float _5823 = _5811 - fa_mesh_fs_params[8].x;\n        if (_5823 > 0.0)\n        {\n            float _5832 = fa_mesh_fs_params[7].w * _5823;\n            float tau = _5832 * _5832;\n            if (fa_mesh_fs_params[8].y > 0.0)\n            {\n                float _5848;\n                if (_5810)\n                {\n                    _5848 = fa_world_pos.y - (fa_mesh_fs_params[9].y * _5806);\n                }\n                else\n                {\n                    _5848 = fa_mesh_fs_params[0].y;\n                }\n                float _5869 = mix(_5848, fa_world_pos.y, clamp(fa_mesh_fs_params[8].x / _5811, 0.0, 1.0));\n                float _5873 = fa_world_pos.y - _5869;\n                float _5878 = _5869 - fa_mesh_fs_params[8].z;\n                float _5883 = fa_world_pos.y - fa_mesh_fs_params[8].z;\n                bool _5886 = _5878 <= 0.0;\n                bool _5887 = !_5886;\n                bool _5893;\n                if (_5887)\n                {\n                    _5893 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _5893 = _5886;\n                }\n                float _5894;\n                if (_5893)\n                {\n                    _5894 = fa_mesh_fs_params[8].y;\n                }\n                else\n                {\n                    _5894 = fa_mesh_fs_params[8].y * exp(-min(fa_mesh_fs_params[8].w * _5878, 80.0));\n                }\n                bool _5921;\n                if (_5887)\n                {\n                    _5921 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _5921 = _5886;\n                }\n                float _5922;\n                if (_5921)\n                {\n                    _5922 = fa_mesh_fs_params[8].y * _5878;\n                }\n                else\n                {\n                    _5922 = (fa_mesh_fs_params[8].y * (1.0 - exp(-min(fa_mesh_fs_params[8].w * _5878, 80.0)))) / fa_mesh_fs_params[8].w;\n                }\n                bool _5947 = _5883 <= 0.0;\n                bool _5954;\n                if (!_5947)\n                {\n                    _5954 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _5954 = _5947;\n                }\n                float _5955;\n                if (_5954)\n                {\n                    _5955 = fa_mesh_fs_params[8].y * _5883;\n                }\n                else\n                {\n                    _5955 = (fa_mesh_fs_params[8].y * (1.0 - exp(-min(fa_mesh_fs_params[8].w * _5883, 80.0)))) / fa_mesh_fs_params[8].w;\n                }\n                float _5982;\n                if (abs(_5873) < 0.001000000047497451305389404296875)\n                {\n                    _5982 = _5894;\n                }\n                else\n                {\n                    _5982 = (_5955 - _5922) / _5873;\n                }\n                tau += (_5823 * max(_5982, 0.0));\n            }\n            result = mix(result, fa_mesh_fs_params[7].xyz, vec3(clamp(1.0 - exp(-clamp(tau, 0.0, 80.0)), 0.0, 1.0)));\n        }\n    }\n    fa_frag_color = vec4(result, _6121);\n}\n\n",
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
            "inst_name": "_433",
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
            "inst_name": "_2085",
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
