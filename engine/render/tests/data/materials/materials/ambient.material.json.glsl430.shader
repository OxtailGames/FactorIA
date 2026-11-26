{
  "format": "factoria.shader/1",
  "engine": "0.38.0",
  "template": "f75e5e0880dc820037ae0c93c059e5f4f012f6ae7d85cbb082650e666c2ae84b",
  "slang": "glsl430",
  "params": [],
  "textures": [],
  "programs": {
    "mesh": {
      "vs": "#version 430\n\nstruct VertexData\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 color;\n    vec3 object_pos;\n};\n\nuniform vec4 fa_mesh_vs_params[11];\nlayout(location = 0) out vec3 fa_world_pos;\nlayout(location = 1) out vec3 fa_world_normal;\nlayout(location = 2) out vec4 fa_world_tangent;\nlayout(location = 3) out vec2 fa_uv;\nlayout(location = 4) out vec4 fa_vertex_color;\nlayout(location = 5) in vec4 fa_inst_m0;\nlayout(location = 6) in vec4 fa_inst_m1;\nlayout(location = 7) in vec4 fa_inst_m2;\nlayout(location = 8) in vec4 fa_inst_m3;\nlayout(location = 0) in vec3 fa_position;\nlayout(location = 1) in vec3 fa_normal;\nlayout(location = 3) in vec4 fa_tangent;\nlayout(location = 2) in vec2 fa_texcoord0;\nlayout(location = 4) in vec4 fa_color;\nlayout(location = 5) out vec3 fa_lm;\n\nvoid fa_inst_begin()\n{\n}\n\nVertexData fa_vertex_data(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    vec3 _69 = cross(model[1].xyz, model[2].xyz);\n    float _75 = (dot(model[0].xyz, _69) < 0.0) ? (-1.0) : 1.0;\n    return VertexData((model * vec4(position, 1.0)).xyz, (((_69 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _75, vec4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _75), texcoord0 * fa_mesh_vs_params[8].xy, color, position);\n}\n\nvoid fa_shade_vertex(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    mat4 param = model;\n    vec3 param_1 = position;\n    vec3 param_2 = normal;\n    vec4 param_3 = tangent;\n    vec2 param_4 = texcoord0;\n    vec4 param_5 = color;\n    VertexData _160 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    vec3 _267 = _160.world_pos;\n    fa_world_pos = _267;\n    fa_world_normal = _160.world_normal;\n    fa_world_tangent = _160.world_tangent;\n    fa_uv = _160.uv;\n    fa_vertex_color = _160.color;\n    gl_Position = mat4(fa_mesh_vs_params[0], fa_mesh_vs_params[1], fa_mesh_vs_params[2], fa_mesh_vs_params[3]) * vec4(_267, 1.0);\n}\n\nvoid main()\n{\n    fa_inst_begin();\n    mat4 param = mat4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3);\n    vec3 param_1 = fa_position;\n    vec3 param_2 = fa_normal;\n    vec4 param_3 = fa_tangent;\n    vec2 param_4 = fa_texcoord0;\n    vec4 param_5 = fa_color;\n    fa_shade_vertex(param, param_1, param_2, param_3, param_4, param_5);\n    fa_lm = vec3(0.0);\n}\n\n",
      "fs": "#version 430\n\nstruct SurfaceInput\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 vertex_color;\n    vec3 view_dir;\n    bool front_facing;\n};\n\nstruct LightSample\n{\n    vec3 direction;\n    vec3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct Surface\n{\n    vec3 albedo;\n    float alpha;\n    vec3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    vec3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    vec3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    vec3 specular_color;\n    float transmission;\n    float thickness;\n    vec3 attenuation_color;\n    float attenuation_distance;\n};\n\nuniform vec4 fa_mesh_fs_params[53];\nuniform vec4 fa_shadows[30];\nlayout(binding = 0) uniform sampler2D fa_light_tex_fa_shadow_smp;\nlayout(binding = 1) uniform sampler2D fa_tex_fa_smp;\nlayout(binding = 2) uniform sampler2D fa_normal_tex_fa_smp;\nlayout(binding = 3) uniform sampler2D fa_mr_tex_fa_smp;\nlayout(binding = 4) uniform sampler2D fa_occlusion_tex_fa_smp;\nlayout(binding = 5) uniform sampler2D fa_emissive_tex_fa_smp;\nlayout(binding = 6) uniform sampler2D fa_decal_tex_fa_env_smp;\nlayout(binding = 7) uniform sampler2D fa_lightmap_fa_env_smp;\nlayout(binding = 8) uniform sampler2D fa_probe_atlas_fa_env_smp;\nlayout(binding = 9) uniform sampler2D fa_light_atlas_fa_env_smp;\nlayout(binding = 10) uniform sampler2D fa_screen_tex_fa_shadow_smp;\nlayout(binding = 11) uniform sampler2D fa_shadow_tex_fa_shadow_smp;\n\nlayout(location = 0) in vec3 fa_world_pos;\nlayout(location = 5) in vec3 fa_lm;\nlayout(location = 1) in vec3 fa_world_normal;\nlayout(location = 2) in vec4 fa_world_tangent;\nlayout(location = 3) in vec2 fa_uv;\nlayout(location = 4) in vec4 fa_vertex_color;\nlayout(location = 0) out vec4 fa_frag_color;\nvec3 fa_light_tint;\nbool fa_light_is_area;\nint fa_cl_ndir;\nint fa_cl_slot;\nint fa_cl_local;\n\nvoid fa_inst_load()\n{\n}\n\nvec4 fa_light_texel(int t)\n{\n    return texelFetch(fa_light_tex_fa_shadow_smp, ivec2(t & 1023, t >> 10), 0);\n}\n\nvec4 fa_cluster_texel(vec3 world_pos)\n{\n    bool _1355 = fa_mesh_fs_params[19].x < 0.0;\n    bool _1362;\n    if (!_1355)\n    {\n        _1362 = fa_mesh_fs_params[19].w < 1.0;\n    }\n    else\n    {\n        _1362 = _1355;\n    }\n    bool _1370;\n    if (!_1362)\n    {\n        _1370 = fa_mesh_fs_params[18].x < 1.0;\n    }\n    else\n    {\n        _1370 = _1362;\n    }\n    bool _1377;\n    if (!_1370)\n    {\n        _1377 = fa_mesh_fs_params[18].y < 1.0;\n    }\n    else\n    {\n        _1377 = _1370;\n    }\n    bool _1384;\n    if (!_1377)\n    {\n        _1384 = fa_mesh_fs_params[19].y < 1.0;\n    }\n    else\n    {\n        _1384 = _1377;\n    }\n    if (_1384)\n    {\n        return vec4(0.0);\n    }\n    vec4 _1394 = vec4(world_pos, 1.0);\n    float _1400 = dot(fa_mesh_fs_params[16], _1394);\n    if (!(_1400 > 9.9999999747524270787835121154785e-07))\n    {\n        return vec4(0.0);\n    }\n    vec2 _1422 = vec2(dot(fa_mesh_fs_params[14], _1394), dot(fa_mesh_fs_params[15], _1394)) / vec2(_1400);\n    int _1426 = int(fa_mesh_fs_params[18].x);\n    int _1430 = int(fa_mesh_fs_params[18].y);\n    int param = (int(fa_mesh_fs_params[19].x) + (((clamp(int(floor(log2(max(dot(fa_mesh_fs_params[17].xyz, world_pos) + fa_mesh_fs_params[17].w, fa_mesh_fs_params[18].w) / fa_mesh_fs_params[18].w) * fa_mesh_fs_params[18].z)), 0, int(fa_mesh_fs_params[19].y) - 1) * _1430) + clamp(int(floor(((_1422.y * 0.5) + 0.5) * fa_mesh_fs_params[18].y)), 0, _1430 - 1)) * _1426)) + clamp(int(floor(((_1422.x * 0.5) + 0.5) * fa_mesh_fs_params[18].x)), 0, _1426 - 1);\n    return fa_light_texel(param);\n}\n\nivec2 fa_cluster_lookup(vec3 world_pos)\n{\n    vec3 param = world_pos;\n    vec4 _1506 = fa_cluster_texel(param);\n    return ivec2(int(_1506.x), int(_1506.y));\n}\n\nvoid fa_cluster_begin(vec3 world_pos)\n{\n    fa_cl_ndir = int(fa_mesh_fs_params[19].z);\n    vec3 param = world_pos;\n    ivec2 _4211 = fa_cluster_lookup(param);\n    fa_cl_slot = _4211.x;\n    fa_cl_local = _4211.y;\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_linear_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvec3 fa_tex_fix(inout vec3 c, float mode)\n{\n    if (mode > 1.5)\n    {\n        vec3 param = c;\n        vec3 _4421 = fa_linear_to_srgb(param);\n        c = _4421;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            vec3 param_1 = c;\n            vec3 _4429 = fa_srgb_to_linear(param_1);\n            c = _4429;\n        }\n    }\n    return c;\n}\n\nvec3 fa_tangent_normal(SurfaceInput i, vec3 m)\n{\n    vec3 _309;\n    if (i.front_facing)\n    {\n        _309 = i.world_normal;\n    }\n    else\n    {\n        _309 = -i.world_normal;\n    }\n    vec3 _333 = normalize(i.world_tangent.xyz - (_309 * dot(_309, i.world_tangent.xyz)));\n    vec3 _360 = normalize(((_333 * m.x) + ((cross(_309, _333) * i.world_tangent.w) * m.y)) + (_309 * m.z));\n    vec3 _363;\n    if (i.front_facing)\n    {\n        _363 = _360;\n    }\n    else\n    {\n        _363 = -_360;\n    }\n    return _363;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    vec4 base_t = texture(fa_tex_fa_smp, i.uv, fa_mesh_fs_params[12].w);\n    float param = fa_mesh_fs_params[6].w;\n    float param_1 = 1.0;\n    vec3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    vec3 _4461 = fa_tex_fix(param_2, param_3);\n    vec4 _6291 = base_t;\n    _6291.x = _4461.x;\n    _6291.y = _4461.y;\n    _6291.z = _4461.z;\n    base_t = _6291;\n    vec4 _4475 = (_6291 * fa_mesh_fs_params[2]) * i.vertex_color;\n    vec3 _6107 = i.world_normal;\n    if (fa_mesh_fs_params[6].z > 0.5)\n    {\n        float param_4 = fa_mesh_fs_params[6].w;\n        float param_5 = 16.0;\n        vec3 param_6 = texture(fa_normal_tex_fa_smp, i.uv, fa_mesh_fs_params[12].w).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        vec3 _4509 = fa_tex_fix(param_6, param_7);\n        vec3 _4512 = (_4509 * 2.0) - vec3(1.0);\n        vec2 _4517 = _4512.xy * fa_mesh_fs_params[6].x;\n        vec3 _6299 = _4512;\n        _6299.x = _4517.x;\n        _6299.y = _4517.y;\n        SurfaceInput param_8 = i;\n        vec3 param_9 = _6299;\n        _6107 = fa_tangent_normal(param_8, param_9);\n    }\n    vec4 mrt = texture(fa_mr_tex_fa_smp, i.uv, fa_mesh_fs_params[12].w);\n    float param_10 = fa_mesh_fs_params[6].w;\n    float param_11 = 64.0;\n    vec3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    vec3 _4547 = fa_tex_fix(param_12, param_13);\n    vec4 _6302 = mrt;\n    _6302.x = _4547.x;\n    _6302.y = _4547.y;\n    _6302.z = _4547.z;\n    mrt = _6302;\n    vec4 _4577 = texture(fa_occlusion_tex_fa_smp, i.uv, fa_mesh_fs_params[12].w);\n    float param_14 = fa_mesh_fs_params[6].w;\n    float param_15 = 256.0;\n    vec3 param_16 = _4577.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    vec3 _4588 = fa_tex_fix(param_16, param_17);\n    float param_18 = fa_mesh_fs_params[6].w;\n    float param_19 = 4.0;\n    vec3 param_20 = texture(fa_emissive_tex_fa_smp, i.uv, fa_mesh_fs_params[12].w).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    vec3 _4620 = fa_tex_fix(param_20, param_21);\n    float _6112 = fa_mesh_fs_params[20].x;\n    float _6113 = fa_mesh_fs_params[20].y;\n    float _6116 = fa_mesh_fs_params[20].z;\n    float _6115 = fa_mesh_fs_params[21].w;\n    float _6118 = fa_mesh_fs_params[22].x;\n    if (fa_mesh_fs_params[22].z > 0.5)\n    {\n        if (mod(fa_mesh_fs_params[22].z, 2.0) > 0.5)\n        {\n            _6112 *= _4588.y;\n            _6113 *= _4588.z;\n            _6115 *= _4577.w;\n        }\n        if (fa_mesh_fs_params[22].z > 1.5)\n        {\n            _6116 *= mrt.x;\n            _6118 *= mrt.w;\n        }\n    }\n    return Surface(_4475.xyz, _4475.w, _6107, clamp(fa_mesh_fs_params[5].x * _4547.z, 0.0, 1.0), clamp(fa_mesh_fs_params[5].y * _4547.y, 0.0500000007450580596923828125, 1.0), 1.0 + (fa_mesh_fs_params[6].y * (_4588.x - 1.0)), fa_mesh_fs_params[3].xyz + (fa_mesh_fs_params[4].xyz * _4620), _6112, _6113, fa_mesh_fs_params[21].xyz, _6115, _6116, fa_mesh_fs_params[20].w, _6118, fa_mesh_fs_params[22].y, fa_mesh_fs_params[23].xyz, fa_mesh_fs_params[30].x, fa_mesh_fs_params[30].y, fa_mesh_fs_params[31].xyz, fa_mesh_fs_params[30].z);\n}\n\nvoid surface(SurfaceInput i, Surface s)\n{\n}\n\nvec4 fa_decal_tile(vec4 rect, vec2 uv, vec2 atlas, vec2 ddx, vec2 ddy)\n{\n    vec2 _1586 = rect.zw - rect.xy;\n    vec2 _1590 = _1586 * atlas;\n    vec2 _1594 = ddx * _1590;\n    vec2 _1598 = ddy * _1590;\n    return textureLod(fa_decal_tex_fa_env_smp, rect.xy + (clamp(uv, vec2(0.0), vec2(1.0)) * _1586), clamp(0.5 * log2(max(max(dot(_1594, _1594), dot(_1598, _1598)), 9.9999999392252902907785028219223e-09)), 0.0, 3.0));\n}\n\nvec3 fa_dc_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_dc_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvoid fa_apply_decals(vec3 world_pos, vec3 geo_normal, inout vec3 albedo, inout vec3 normal)\n{\n    bool _1631 = fa_mesh_fs_params[10].y < 0.5;\n    bool _1638;\n    if (!_1631)\n    {\n        _1638 = fa_mesh_fs_params[10].w < 0.5;\n    }\n    else\n    {\n        _1638 = _1631;\n    }\n    if (_1638)\n    {\n        return;\n    }\n    vec3 _1644 = dFdx(world_pos);\n    vec3 _1647 = dFdy(world_pos);\n    vec3 param = world_pos;\n    vec4 _1651 = fa_cluster_texel(param);\n    int _1655 = int(_1651.w);\n    if (_1655 < 1)\n    {\n        return;\n    }\n    int _1665 = int(fa_mesh_fs_params[10].y + 0.5);\n    int param_1 = _1665;\n    vec4 _1669 = fa_light_texel(param_1);\n    vec2 _1672 = _1669.yz;\n    int _1676 = int(_1669.w);\n    int param_2 = _1665 + 1;\n    vec4 _1681 = fa_light_texel(param_2);\n    float _1682 = _1681.x;\n    int _1688 = int(fa_mesh_fs_params[10].w + 0.5) - 1;\n    int _1692 = int(_1651.z);\n    vec3 _1957;\n    for (int k = 0; k < _1655; k++)\n    {\n        int _1705 = _1692 + k;\n        int param_3 = _1676 + (_1705 >> 2);\n        int _1722 = (_1665 + 2) + (int(fa_light_texel(param_3)[_1705 & 3]) * 7);\n        int param_4 = _1722 + 6;\n        vec4 _1727 = fa_light_texel(param_4);\n        if (((int(_1727.w + 0.5) >> _1688) & 1) == 0)\n        {\n            continue;\n        }\n        int param_5 = _1722;\n        vec4 _1742 = fa_light_texel(param_5);\n        int param_6 = _1722 + 1;\n        vec4 _1747 = fa_light_texel(param_6);\n        int param_7 = _1722 + 2;\n        vec4 _1752 = fa_light_texel(param_7);\n        vec3 _1755 = _1742.xyz;\n        float _1760 = dot(_1755, world_pos) + _1742.w;\n        vec3 _1762 = _1747.xyz;\n        float _1767 = dot(_1762, world_pos) + _1747.w;\n        vec3 _1769 = _1752.xyz;\n        float _1774 = dot(_1769, world_pos) + _1752.w;\n        bool _1779 = abs(_1760) > 0.5;\n        bool _1787;\n        if (!_1779)\n        {\n            _1787 = abs(_1767) > 0.5;\n        }\n        else\n        {\n            _1787 = _1779;\n        }\n        bool _1795;\n        if (!_1787)\n        {\n            _1795 = abs(_1774) > 0.5;\n        }\n        else\n        {\n            _1795 = _1787;\n        }\n        if (_1795)\n        {\n            continue;\n        }\n        float _1810 = clamp(dot(geo_normal, normalize(_1769)) * _1727.z, 0.0, 1.0);\n        if (_1810 <= 0.0)\n        {\n            continue;\n        }\n        float _1830 = (clamp((0.5 - abs(_1774)) * 10.0, 0.0, 1.0) * _1810) * _1727.x;\n        vec2 _1838 = vec2(_1760 + 0.5, 0.5 - _1767);\n        vec2 _1848 = vec2(dot(_1755, _1644), dot(_1762, _1644));\n        vec2 _1858 = vec2(dot(_1755, _1647), dot(_1762, _1647));\n        int param_8 = _1722 + 5;\n        vec4 _1863 = fa_light_texel(param_8);\n        int param_9 = _1722 + 3;\n        vec4 _1868 = fa_light_texel(param_9);\n        int param_10 = _1722 + 4;\n        vec4 _1873 = fa_light_texel(param_10);\n        float tex_a = 1.0;\n        vec3 col = _1863.xyz;\n        bool _1883 = _1868.z > _1868.x;\n        if (_1883)\n        {\n            vec4 param_11 = _1868;\n            vec2 param_12 = _1838;\n            vec2 param_13 = _1672;\n            vec2 param_14 = _1848;\n            vec2 param_15 = _1858;\n            vec4 tx = fa_decal_tile(param_11, param_12, param_13, param_14, param_15);\n            if ((_1682 > 0.5) && (_1682 < 1.5))\n            {\n                vec3 param_16 = tx.xyz;\n                vec3 _1909 = fa_dc_to_linear(param_16);\n                vec4 _6195 = tx;\n                _6195.x = _1909.x;\n                _6195.y = _1909.y;\n                _6195.z = _1909.z;\n                tx = _6195;\n            }\n            col *= tx.xyz;\n            tex_a = tx.w;\n        }\n        albedo = mix(albedo, col, vec3(clamp((_1830 * tex_a) * _1863.w, 0.0, 1.0)));\n        if (_1873.z > _1873.x)\n        {\n            vec4 param_17 = _1873;\n            vec2 param_18 = _1838;\n            vec2 param_19 = _1672;\n            vec2 param_20 = _1848;\n            vec2 param_21 = _1858;\n            vec4 _1953 = fa_decal_tile(param_17, param_18, param_19, param_20, param_21);\n            if (_1682 > 1.5)\n            {\n                vec3 param_22 = _1953.xyz;\n                vec3 _1963 = fa_dc_to_srgb(param_22);\n                _1957 = _1963;\n            }\n            else\n            {\n                _1957 = _1953.xyz;\n            }\n            vec3 _1972 = (_1957 * 2.0) - vec3(1.0);\n            vec2 _1977 = _1972.xy * _1727.y;\n            vec3 _1999 = (normalize(_1755) * _1977.x) + (normalize(_1762) * _1977.y);\n            vec3 _2002 = normalize(normal);\n            normal = normalize(mix(_2002, normalize((_2002 * max(_1972.z, 0.0500000007450580596923828125)) + (_1999 - (_2002 * dot(_2002, _1999)))), vec3(clamp(_1830 * (_1883 ? tex_a : 1.0), 0.0, 1.0))));\n        }\n    }\n}\n\nvec2 fa_atlas_size()\n{\n    return vec2(textureSize(fa_probe_atlas_fa_env_smp, 0));\n}\n\nvec3 fa_probe_sh_coef(vec2 origin, float res, int k)\n{\n    vec3 v = textureLod(fa_probe_atlas_fa_env_smp, (origin + vec2(float(k) + 0.5, res + 2.5)) / fa_atlas_size(), 0.0).xyz;\n    if (fa_mesh_fs_params[41].y > 0.5)\n    {\n        v = ((v * 255.0) - vec3(128.0)) * 0.03149606287479400634765625;\n    }\n    return v;\n}\n\nvec3 fa_sh_eval(vec3 c[9], vec3 n)\n{\n    vec3 _3674 = max((((c[0] * 0.2820948064327239990234375) + (((c[1] * (0.3257350027561187744140625 * n.y)) + (c[2] * (0.3257350027561187744140625 * n.z))) + (c[3] * (0.3257350027561187744140625 * n.x)))) + (((c[4] * ((0.2731371223926544189453125 * n.x) * n.y)) + (c[5] * ((0.2731371223926544189453125 * n.y) * n.z))) + (c[6] * (0.078847892582416534423828125 * (((3.0 * n.z) * n.z) - 1.0))))) + ((c[7] * ((0.2731371223926544189453125 * n.x) * n.z)) + (c[8] * (0.13656856119632720947265625 * ((n.x * n.x) - (n.y * n.y))))), vec3(0.0));\n    return _3674;\n}\n\nvec3 fa_ambient_light(vec3 n)\n{\n    float _3783 = (1.0 - fa_mesh_fs_params[42].w) - fa_mesh_fs_params[47].w;\n    vec3 amb = vec3(0.0);\n    bool _3789 = fa_mesh_fs_params[11].w > 0.5;\n    vec3 c[9];\n    for (int k = 0; k < 9; k++)\n    {\n        c[k] = vec3(0.0);\n    }\n    if (_3783 > 0.0005000000237487256526947021484375)\n    {\n        if (_3789)\n        {\n            for (int k_1 = 0; k_1 < 9; k_1++)\n            {\n                vec2 param = fa_mesh_fs_params[41].zw;\n                float param_1 = 128.0;\n                int param_2 = k_1;\n                c[k_1] = fa_probe_sh_coef(param, param_1, param_2) * _3783;\n            }\n        }\n        else\n        {\n            amb = fa_mesh_fs_params[1].xyz * _3783;\n        }\n    }\n    bool _3841 = fa_mesh_fs_params[42].w > 0.0;\n    if (_3841)\n    {\n        for (int k_2 = 0; k_2 < 9; k_2++)\n        {\n            vec2 param_3 = fa_mesh_fs_params[42].xy;\n            float param_4 = fa_mesh_fs_params[42].z;\n            int param_5 = k_2;\n            c[k_2] += (fa_probe_sh_coef(param_3, param_4, param_5) * fa_mesh_fs_params[42].w);\n        }\n    }\n    bool _3872 = fa_mesh_fs_params[47].w > 0.0;\n    if (_3872)\n    {\n        for (int k_3 = 0; k_3 < 9; k_3++)\n        {\n            vec2 param_6 = fa_mesh_fs_params[47].xy;\n            float param_7 = fa_mesh_fs_params[47].z;\n            int param_8 = k_3;\n            c[k_3] += (fa_probe_sh_coef(param_6, param_7, param_8) * fa_mesh_fs_params[47].w);\n        }\n    }\n    if ((_3789 || _3841) || _3872)\n    {\n        vec3 param_9[9] = c;\n        vec3 param_10 = n;\n        amb += fa_sh_eval(param_9, param_10);\n    }\n    return amb;\n}\n\nvec4 fa_gi_fetch(vec2 texel)\n{\n    return textureLod(fa_probe_atlas_fa_env_smp, texel / fa_atlas_size(), 0.0);\n}\n\nvec2 fa_oct_encode(vec3 d)\n{\n    vec3 _3694 = d / vec3(max((abs(d.x) + abs(d.y)) + abs(d.z), 9.9999999600419720025001879548654e-13));\n    float _3697 = _3694.x;\n    float _3699 = _3694.z;\n    vec2 e = vec2(_3697, _3699);\n    if (_3694.y < 0.0)\n    {\n        e = vec2((1.0 - abs(_3699)) * ((_3697 < 0.0) ? (-1.0) : 1.0), (1.0 - abs(_3697)) * ((_3699 < 0.0) ? (-1.0) : 1.0));\n    }\n    return e;\n}\n\nvec3 fa_gi_grid(int rec, vec3 n, vec3 v, out float cover)\n{\n    cover = 0.0;\n    int param = rec;\n    vec4 _4734 = fa_light_texel(param);\n    int param_1 = rec + 1;\n    vec4 _4739 = fa_light_texel(param_1);\n    int param_2 = rec + 2;\n    vec4 _4744 = fa_light_texel(param_2);\n    int param_3 = rec + 3;\n    vec4 _4749 = fa_light_texel(param_3);\n    bool _4752 = _4749.z < 0.5;\n    bool _4760;\n    if (!_4752)\n    {\n        _4760 = fa_atlas_size().y < 1155.0;\n    }\n    else\n    {\n        _4760 = _4752;\n    }\n    if (_4760)\n    {\n        return vec3(0.0);\n    }\n    float _4767 = max(_4734.w, 9.9999997473787516355514526367188e-05);\n    vec3 _4770 = _4739.xyz;\n    vec3 _4774 = _4734.xyz;\n    vec3 _4778 = (fa_world_pos - _4774) / vec3(_4767);\n    vec3 _4787 = min(_4778 + vec3(0.5), (_4770 - vec3(0.5)) - _4778);\n    float _4796 = min(_4787.x, min(_4787.y, _4787.z));\n    if (!(_4796 > 0.0))\n    {\n        return vec3(0.0);\n    }\n    vec3 _4811 = _4770 - vec3(1.0);\n    vec3 _4812 = clamp(_4778, vec3(0.0), _4811);\n    vec3 _4820 = min(floor(_4812), max(_4770 - vec3(2.0), vec3(0.0)));\n    vec3 _4824 = _4812 - _4820;\n    vec3 _4836 = fa_world_pos + (((n * 0.800000011920928955078125) + (v * 0.20000000298023223876953125)) * (0.20000000298023223876953125 * _4767));\n    int _4841 = int(_4744.y + 0.5);\n    float _4846 = 0.3257350027561187744140625 * n.y;\n    float _4850 = 0.3257350027561187744140625 * n.z;\n    float _4854 = 0.3257350027561187744140625 * n.x;\n    float _4861 = (0.2731371223926544189453125 * n.x) * n.y;\n    float _4868 = (0.2731371223926544189453125 * n.y) * n.z;\n    float _4877 = 0.078847892582416534423828125 * (((3.0 * n.z) * n.z) - 1.0);\n    float _4884 = (0.2731371223926544189453125 * n.x) * n.z;\n    float _4897 = 0.13656856119632720947265625 * ((n.x * n.x) - (n.y * n.y));\n    vec3 acc = vec3(0.0);\n    float wsum = 0.0;\n    int _4904 = 8 + int(_4749.w);\n    float _4931;\n    float _4944;\n    float _4958;\n    for (int k = 0; k < _4904; k++)\n    {\n        float _4917 = float(k & 1);\n        float _4921 = float((k >> 1) & 1);\n        float _4925 = float((k >> 2) & 1);\n        if (_4917 > 0.5)\n        {\n            _4931 = _4824.x;\n        }\n        else\n        {\n            _4931 = 1.0 - _4824.x;\n        }\n        if (_4921 > 0.5)\n        {\n            _4944 = _4824.y;\n        }\n        else\n        {\n            _4944 = 1.0 - _4824.y;\n        }\n        if (_4925 > 0.5)\n        {\n            _4958 = _4824.z;\n        }\n        else\n        {\n            _4958 = 1.0 - _4824.z;\n        }\n        float _4968 = (_4931 * _4944) * _4958;\n        if (!(_4968 > 0.0))\n        {\n            continue;\n        }\n        vec3 _4981 = min(_4820 + vec3(_4917, _4921, _4925), _4811);\n        int _5001 = int(((_4744.x + _4981.x) + (_4739.x * (_4981.y + (_4739.y * _4981.z)))) + 0.5);\n        vec2 _5016 = vec2(float(_5001 % _4841) * 10.0, 1024.0 + (float(_5001 / _4841) * 11.0));\n        vec2 param_4 = _5016 + vec2(9.5, 10.5);\n        vec4 _5024 = fa_gi_fetch(param_4);\n        bool _5027 = _5024.y < 0.5;\n        bool _5036;\n        if (!_5027)\n        {\n            _5036 = _5024.x > _4749.y;\n        }\n        else\n        {\n            _5036 = _5027;\n        }\n        if (_5036)\n        {\n            continue;\n        }\n        vec3 _5048 = _4836 - (_4774 + (_4981 * _4767));\n        float _5051 = length(_5048);\n        vec3 _5057 = _5048 / vec3(max(_5051, 9.9999997473787516355514526367188e-05));\n        float _5067 = max(9.9999997473787516355514526367188e-05, (dot(-_5057, n) + 1.0) * 0.5);\n        float w = _4968 * (_5067 * _5067);\n        vec3 param_5 = _5057;\n        vec2 param_6 = (_5016 + vec2(1.0)) + (((fa_oct_encode(param_5) * 0.5) + vec2(0.5)) * 8.0);\n        vec4 _5087 = fa_gi_fetch(param_6);\n        float _5094 = _5051 / max(_4744.z, 9.9999997473787516355514526367188e-05);\n        float _5097 = _5087.x;\n        if (_5094 > _5097)\n        {\n            float _5110 = max(_5087.y - (_5097 * _5097), 0.0);\n            float _5115 = _5094 - _5097;\n            float _5124 = _5110 / max(_5110 + (_5115 * _5115), 9.9999999600419720025001879548654e-13);\n            w *= ((_5124 * _5124) * _5124);\n        }\n        if (!(w > 0.0))\n        {\n            continue;\n        }\n        vec2 param_7 = _5016 + vec2(0.5, 10.5);\n        vec2 param_8 = _5016 + vec2(1.5, 10.5);\n        vec2 param_9 = _5016 + vec2(2.5, 10.5);\n        vec2 param_10 = _5016 + vec2(3.5, 10.5);\n        vec2 param_11 = _5016 + vec2(4.5, 10.5);\n        vec2 param_12 = _5016 + vec2(5.5, 10.5);\n        vec2 param_13 = _5016 + vec2(6.5, 10.5);\n        vec2 param_14 = _5016 + vec2(7.5, 10.5);\n        vec2 param_15 = _5016 + vec2(8.5, 10.5);\n        acc += ((((((((((fa_gi_fetch(param_7).xyz * 0.2820948064327239990234375) + (fa_gi_fetch(param_8).xyz * _4846)) + (fa_gi_fetch(param_9).xyz * _4850)) + (fa_gi_fetch(param_10).xyz * _4854)) + (fa_gi_fetch(param_11).xyz * _4861)) + (fa_gi_fetch(param_12).xyz * _4868)) + (fa_gi_fetch(param_13).xyz * _4877)) + (fa_gi_fetch(param_14).xyz * _4884)) + (fa_gi_fetch(param_15).xyz * _4897)) * w);\n        wsum += w;\n    }\n    if (!(wsum > 9.9999997473787516355514526367188e-06))\n    {\n        return vec3(0.0);\n    }\n    cover = smoothstep(0.0, 1.0, clamp(_4796 * 2.0, 0.0, 1.0)) * smoothstep(0.0, 0.0199999995529651641845703125, wsum);\n    float _5252;\n    if (fa_mesh_fs_params[52].z > 0.5)\n    {\n        _5252 = _4749.x;\n    }\n    else\n    {\n        _5252 = 1.0;\n    }\n    return max(acc / vec3(wsum), vec3(0.0)) * (_4744.w * _5252);\n}\n\nvec3 fa_gi_light(vec3 n, inout float left)\n{\n    left = 1.0;\n    vec3 acc = vec3(0.0);\n    vec3 _5276 = normalize(fa_mesh_fs_params[0].xyz - fa_world_pos);\n    int _5281 = int(fa_mesh_fs_params[52].x + 0.5);\n    int _5286 = int(fa_mesh_fs_params[52].y + 0.5);\n    float param_3;\n    for (int k = 0; (k < _5286) && (k < 8); k++)\n    {\n        int param = _5281 + (4 * k);\n        vec3 param_1 = n;\n        vec3 param_2 = _5276;\n        vec3 _5311 = fa_gi_grid(param, param_1, param_2, param_3);\n        float _5316 = param_3 * left;\n        acc += (_5311 * _5316);\n        left -= _5316;\n        if (left < 0.001000000047497451305389404296875)\n        {\n            left = 0.0;\n            break;\n        }\n    }\n    return acc;\n}\n\nvec3 fa_realtime_or_ambient(vec3 n)\n{\n    vec3 gi = vec3(0.0);\n    float left = 1.0;\n    if (fa_mesh_fs_params[52].y > 0.5)\n    {\n        vec3 param = n;\n        float param_1;\n        vec3 _5345 = fa_gi_light(param, param_1);\n        left = param_1;\n        gi = _5345;\n    }\n    if (left <= 0.0)\n    {\n        return gi;\n    }\n    vec3 param_2 = n;\n    return gi + (fa_ambient_light(param_2) * left);\n}\n\nvec3 fa_indirect_diffuse(vec3 n)\n{\n    if (fa_lm.z > 0.5)\n    {\n        return textureLod(fa_lightmap_fa_env_smp, fa_lm.xy, 0.0).xyz;\n    }\n    if (fa_mesh_fs_params[32].w > 0.0)\n    {\n        vec3 c[9];\n        for (int k = 0; k < 9; k++)\n        {\n            c[k] = fa_mesh_fs_params[k * 1 + 32].xyz;\n        }\n        vec3 param = n;\n        vec3 param_1[9] = c;\n        vec3 param_2 = n;\n        return mix(fa_ambient_light(param), fa_sh_eval(param_1, param_2), vec3(clamp(fa_mesh_fs_params[32].w, 0.0, 1.0)));\n    }\n    vec3 param_3 = n;\n    return fa_realtime_or_ambient(param_3);\n}\n\nvec3 ambient(SurfaceInput i, Surface s, vec3 ambientColor)\n{\n    return vec3(0.0, ambientColor.y, 0.0);\n}\n\nint fa_cluster_index(int slot, int n)\n{\n    int param = (int(fa_mesh_fs_params[19].x) + int(fa_mesh_fs_params[19].w)) + ((slot + n) >> 2);\n    vec4 t = fa_light_texel(param);\n    return int(t[(slot + n) & 3]);\n}\n\nint fa_cl_light(int n)\n{\n    if (n < fa_cl_ndir)\n    {\n        return n;\n    }\n    int param = fa_cl_slot;\n    int param_1 = n - fa_cl_ndir;\n    return fa_cluster_index(param, param_1);\n}\n\nint fa_light_base(int li)\n{\n    return li * ((fa_mesh_fs_params[1].w > 4.5) ? 8 : 4);\n}\n\nbool fa_light_baked(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 3;\n    return fa_light_texel(param_1).w > 0.5;\n}\n\nfloat fa_baked_keep(int li)\n{\n    float _4181;\n    if (fa_lm.z > 0.5)\n    {\n        _4181 = 0.0;\n    }\n    else\n    {\n        _4181 = 1.0 - clamp(fa_mesh_fs_params[32].w, 0.0, 1.0);\n    }\n    bool _4192 = _4181 < 1.0;\n    bool _4198;\n    if (_4192)\n    {\n        int param = li;\n        _4198 = fa_light_baked(param);\n    }\n    else\n    {\n        _4198 = _4192;\n    }\n    return _4198 ? _4181 : 1.0;\n}\n\nfloat fa_light_type(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 1;\n    return fa_light_texel(param_1).w;\n}\n\nvec3 fa_area_point(vec3 c, vec3 axis, vec3 ru, vec3 uu, float hx, float hy, float shape, vec3 p, vec3 r)\n{\n    bool _605 = dot(r, r) > 0.5;\n    if (shape > 1.5)\n    {\n        vec3 _618 = (c - (ru * hx)) - p;\n        vec3 _624 = ru * (2.0 * hx);\n        float _630 = max(dot(_624, _624), 9.9999999392252902907785028219223e-09);\n        float _634 = dot(_618, _624);\n        float t = clamp((-_634) / _630, 0.0, 1.0);\n        if (_605)\n        {\n            float _649 = dot(r, _624);\n            float _655 = _630 - (_649 * _649);\n            if (abs(_655) > (9.9999997473787516355514526367188e-06 * _630))\n            {\n                t = clamp(((dot(r, _618) * _649) - _634) / _655, 0.0, 1.0);\n            }\n        }\n        return (p + _618) + (_624 * t);\n    }\n    vec3 q = p;\n    float _687 = dot(r, axis);\n    bool _695;\n    if (_605)\n    {\n        _695 = abs(_687) > 9.9999997473787516355514526367188e-05;\n    }\n    else\n    {\n        _695 = _605;\n    }\n    if (_695)\n    {\n        float _705 = dot(c - p, axis) / _687;\n        if (_705 > 0.0)\n        {\n            q = p + (r * _705);\n        }\n    }\n    vec3 _718 = q - c;\n    vec2 xy = vec2(dot(_718, ru), dot(_718, uu));\n    if (shape > 0.5)\n    {\n        float _733 = length(xy);\n        if (_733 > hx)\n        {\n            xy *= (hx / _733);\n        }\n    }\n    else\n    {\n        xy = clamp(xy, vec2(-hx, -hy), vec2(hx, hy));\n    }\n    return (c + (ru * xy.x)) + (uu * xy.y);\n}\n\nvec4 fa_atlas_fetch(vec2 texel)\n{\n    return textureLod(fa_light_atlas_fa_env_smp, texel / vec2(textureSize(fa_light_atlas_fa_env_smp, 0)), 0.0);\n}\n\nvec3 fa_cookie_sample(vec2 tile_origin, vec2 uv)\n{\n    vec2 param = (tile_origin + vec2(1.0)) + (clamp(uv, vec2(0.0), vec2(1.0)) * 254.0);\n    return fa_atlas_fetch(param).xyz;\n}\n\nfloat fa_ies_sample(vec2 tile_origin, vec3 d, vec3 axis, vec3 right, vec3 up)\n{\n    float _525 = dot(d, right);\n    float _529 = dot(d, up);\n    float _540;\n    if (((_525 * _525) + (_529 * _529)) > 1.0000000133514319600180897396058e-10)\n    {\n        _540 = atan(_529, _525) * 0.15915493667125701904296875;\n    }\n    else\n    {\n        _540 = 0.0;\n    }\n    vec2 param = tile_origin + vec2(1.0 + ((_540 - floor(_540)) * 64.0), 1.0 + (acos(clamp(dot(d, axis), -1.0, 1.0)) * 10.18591594696044921875));\n    return fa_atlas_fetch(param).x;\n}\n\nint fa_cube_face(vec3 d)\n{\n    vec3 _375 = abs(d);\n    float _377 = _375.x;\n    float _379 = _375.y;\n    bool _380 = _377 >= _379;\n    bool _388;\n    if (_380)\n    {\n        _388 = _377 >= _375.z;\n    }\n    else\n    {\n        _388 = _380;\n    }\n    int _389;\n    if (_388)\n    {\n        _389 = (d.x > 0.0) ? 0 : 1;\n    }\n    else\n    {\n        int _404;\n        if (_379 >= _375.z)\n        {\n            _404 = (d.y > 0.0) ? 2 : 3;\n        }\n        else\n        {\n            _404 = (d.z > 0.0) ? 4 : 5;\n        }\n        _389 = _404;\n    }\n    return _389;\n}\n\nvoid fa_cube_face_basis(int f, out vec3 fwd, out vec3 up)\n{\n    if (f == 0)\n    {\n        fwd = vec3(1.0, 0.0, 0.0);\n        up = vec3(0.0, 1.0, 0.0);\n    }\n    else\n    {\n        if (f == 1)\n        {\n            fwd = vec3(-1.0, 0.0, 0.0);\n            up = vec3(0.0, 1.0, 0.0);\n        }\n        else\n        {\n            if (f == 2)\n            {\n                fwd = vec3(0.0, 1.0, 0.0);\n                up = vec3(0.0, 0.0, 1.0);\n            }\n            else\n            {\n                if (f == 3)\n                {\n                    fwd = vec3(0.0, -1.0, 0.0);\n                    up = vec3(0.0, 0.0, -1.0);\n                }\n                else\n                {\n                    if (f == 4)\n                    {\n                        fwd = vec3(0.0, 0.0, 1.0);\n                        up = vec3(0.0, 1.0, 0.0);\n                    }\n                    else\n                    {\n                        fwd = vec3(0.0, 0.0, -1.0);\n                        up = vec3(0.0, 1.0, 0.0);\n                    }\n                }\n            }\n        }\n    }\n}\n\nLightSample fa_light_sample_n(int li, vec3 world_pos, vec3 n)\n{\n    int param = li;\n    int _771 = fa_light_base(param);\n    bool _775 = fa_mesh_fs_params[1].w > 4.5;\n    int param_1 = _771;\n    vec4 _779 = fa_light_texel(param_1);\n    int param_2 = _771 + 1;\n    vec4 _784 = fa_light_texel(param_2);\n    float _787 = _784.w;\n    float atten = 1.0;\n    float dist = 0.0;\n    fa_light_tint = vec3(1.0);\n    bool _799 = _775 && (_787 > 2.5);\n    fa_light_is_area = _799;\n    bool _801 = _787 < 0.5;\n    vec3 l;\n    if (_801)\n    {\n        l = normalize(_779.xyz);\n        if (_775)\n        {\n            int param_3 = _771 + 6;\n            vec4 _815 = fa_light_texel(param_3);\n            if (_815.z > 0.5)\n            {\n                int param_4 = _771 + 4;\n                vec4 _825 = fa_light_texel(param_4);\n                int param_5 = _771 + 5;\n                vec4 _830 = fa_light_texel(param_5);\n                vec2 param_6 = _815.xy;\n                vec2 param_7 = fract(vec2(dot(world_pos, _825.xyz) * _825.w, (-dot(world_pos, _830.xyz)) * _830.w) + vec2(0.5));\n                fa_light_tint = fa_cookie_sample(param_6, param_7);\n            }\n        }\n    }\n    else\n    {\n        vec3 _860 = _779.xyz;\n        vec3 _862 = _860 - world_pos;\n        vec3 to_light = _862;\n        float _865 = length(_862);\n        float reach = _865;\n        bool front = true;\n        if (_799)\n        {\n            int param_8 = _771 + 7;\n            reach = max(_865 - fa_light_texel(param_8).w, 0.0);\n            int param_9 = _771 + 4;\n            vec4 _889 = fa_light_texel(param_9);\n            int param_10 = _771 + 5;\n            vec4 _894 = fa_light_texel(param_10);\n            int param_11 = _771 + 6;\n            vec4 _899 = fa_light_texel(param_11);\n            float _900 = _899.w;\n            int param_12 = _771 + 2;\n            vec3 _907 = normalize(fa_light_texel(param_12).xyz);\n            bool _909 = _900 > 1.5;\n            bool _917;\n            if (!_909)\n            {\n                _917 = dot(_907, to_light) < 0.0;\n            }\n            else\n            {\n                _917 = _909;\n            }\n            front = _917;\n            vec3 r = vec3(0.0);\n            vec3 _926 = fa_mesh_fs_params[0].xyz - world_pos;\n            bool _930 = dot(n, n) > 0.5;\n            bool _938;\n            if (_930)\n            {\n                _938 = dot(_926, _926) > 9.9999999600419720025001879548654e-13;\n            }\n            else\n            {\n                _938 = _930;\n            }\n            if (_938)\n            {\n                r = reflect(-normalize(_926), normalize(n));\n            }\n            vec3 param_13 = _860;\n            vec3 param_14 = _907;\n            vec3 param_15 = _889.xyz;\n            vec3 param_16 = _894.xyz;\n            float param_17 = _889.w;\n            float param_18 = _894.w;\n            float param_19 = _900;\n            vec3 param_20 = world_pos;\n            vec3 param_21 = r;\n            to_light = fa_area_point(param_13, param_14, param_15, param_16, param_17, param_18, param_19, param_20, param_21) - world_pos;\n        }\n        float _974 = length(to_light);\n        dist = _974;\n        l = to_light / vec3(max(_974, 9.9999997473787516355514526367188e-05));\n        float _988 = reach / max(_779.w, 0.001000000047497451305389404296875);\n        float _994 = clamp(1.0 - (_988 * _988), 0.0, 1.0);\n        float _996;\n        if (front)\n        {\n            _996 = _994 * _994;\n        }\n        else\n        {\n            _996 = 0.0;\n        }\n        atten = _996;\n        bool _1007 = _787 < 2.5;\n        if ((_787 > 1.5) && _1007)\n        {\n            int param_22 = _771 + 2;\n            vec4 _1015 = fa_light_texel(param_22);\n            float _1025 = _1015.w;\n            int param_23 = _771 + 3;\n            vec4 _1030 = fa_light_texel(param_23);\n            float _1031 = _1030.x;\n            float cos_inner = _1031;\n            if (_1031 > 1.5)\n            {\n                cos_inner = mix(_1025, 1.0, 0.25);\n            }\n            atten *= smoothstep(_1025, cos_inner, dot(-l, normalize(_1015.xyz)));\n        }\n        if (_775 && (_787 < 1.5))\n        {\n            int param_24 = _771 + 6;\n            vec4 _1055 = fa_light_texel(param_24);\n            if (_1055.z > 0.5)\n            {\n                vec3 _1063 = -to_light;\n                int param_25 = _771 + 4;\n                int param_26 = _771 + 5;\n                vec3 _1077 = fa_light_texel(param_25).xyz;\n                vec3 _1081 = fa_light_texel(param_26).xyz;\n                vec3 _1090 = vec3(dot(_1063, _1077), dot(_1063, _1081), dot(_1063, cross(_1077, _1081)));\n                vec3 param_27 = _1090;\n                int _1094 = fa_cube_face(param_27);\n                int param_28 = _1094;\n                vec3 param_29;\n                vec3 param_30;\n                fa_cube_face_basis(param_28, param_29, param_30);\n                vec2 _1121 = vec2(dot(_1090, cross(param_29, param_30)), dot(_1090, param_30)) / vec2(max(dot(_1090, param_29), 9.9999997473787516355514526367188e-05));\n                int _1125 = _1094 / 3;\n                vec2 param_31 = _1055.xy + (vec2(float(_1094 - (_1125 * 3)), float(_1125)) * 256.0);\n                vec2 param_32 = vec2(0.5 + (0.5 * _1121.x), 0.5 - (0.5 * _1121.y));\n                fa_light_tint = fa_cookie_sample(param_31, param_32);\n            }\n            int param_33 = _771 + 7;\n            vec4 _1155 = fa_light_texel(param_33);\n            if (_1155.z > 0.5)\n            {\n                int param_34 = _771 + 2;\n                int param_35 = _771 + 4;\n                int param_36 = _771 + 5;\n                vec2 param_37 = _1155.xy;\n                vec3 param_38 = -l;\n                vec3 param_39 = normalize(fa_light_texel(param_34).xyz);\n                vec3 param_40 = fa_light_texel(param_35).xyz;\n                vec3 param_41 = fa_light_texel(param_36).xyz;\n                atten *= fa_ies_sample(param_37, param_38, param_39, param_40, param_41);\n            }\n        }\n        else\n        {\n            if (_775 && _1007)\n            {\n                int param_42 = _771 + 6;\n                vec4 _1202 = fa_light_texel(param_42);\n                int param_43 = _771 + 7;\n                vec4 _1207 = fa_light_texel(param_43);\n                bool _1210 = _1202.z > 0.5;\n                bool _1217;\n                if (!_1210)\n                {\n                    _1217 = _1207.z > 0.5;\n                }\n                else\n                {\n                    _1217 = _1210;\n                }\n                if (_1217)\n                {\n                    int param_44 = _771 + 2;\n                    vec4 _1224 = fa_light_texel(param_44);\n                    vec3 _1228 = normalize(_1224.xyz);\n                    int param_45 = _771 + 4;\n                    vec4 _1233 = fa_light_texel(param_45);\n                    int param_46 = _771 + 5;\n                    vec4 _1238 = fa_light_texel(param_46);\n                    if (_1210)\n                    {\n                        vec3 _1246 = -to_light;\n                        float _1253 = _1224.w;\n                        float _1269 = 0.5 / max(dot(_1246, _1228) * (sqrt(max(1.0 - (_1253 * _1253), 0.0)) / max(_1253, 0.001000000047497451305389404296875)), 9.9999997473787516355514526367188e-05);\n                        vec2 param_47 = _1202.xy;\n                        vec2 param_48 = vec2(0.5 + (dot(_1246, _1233.xyz) * _1269), 0.5 - (dot(_1246, _1238.xyz) * _1269));\n                        fa_light_tint = fa_cookie_sample(param_47, param_48);\n                    }\n                    if (_1207.z > 0.5)\n                    {\n                        vec2 param_49 = _1207.xy;\n                        vec3 param_50 = -l;\n                        vec3 param_51 = _1228;\n                        vec3 param_52 = _1233.xyz;\n                        vec3 param_53 = _1238.xyz;\n                        atten *= fa_ies_sample(param_49, param_50, param_51, param_52, param_53);\n                    }\n                }\n            }\n        }\n    }\n    vec3 _6061 = _784.xyz * atten;\n    if (_775)\n    {\n        _6061 *= fa_light_tint;\n    }\n    int _1337;\n    if (_801)\n    {\n        _1337 = 0;\n    }\n    else\n    {\n        _1337 = ((_787 > 1.5) && (_787 < 2.5)) ? 2 : 1;\n    }\n    return LightSample(l, _6061, atten, 1.0, dist, _1337);\n}\n\nfloat fa_shadow_depth(inout vec2 uv, vec4 rect)\n{\n    uv = clamp(uv, rect.xy, rect.zw);\n    return textureLod(fa_shadow_tex_fa_shadow_smp, uv, 0.0).x;\n}\n\nfloat fa_shadow_fetch(vec2 uv, vec4 rect, vec3 conv)\n{\n    vec2 param = uv;\n    vec4 param_1 = rect;\n    float _2126 = fa_shadow_depth(param, param_1);\n    float _2130;\n    if (conv.x < 0.5)\n    {\n        _2130 = _2126;\n    }\n    else\n    {\n        _2130 = (conv.y * conv.z) / (conv.z - (_2126 * (conv.z - conv.y)));\n    }\n    return _2130;\n}\n\nfloat fa_shadow_noise()\n{\n    return fract(52.98291778564453125 * fract(dot(gl_FragCoord.xy, vec2(0.067110560834407806396484375, 0.005837149918079376220703125))));\n}\n\nvec2 fa_shadow_vogel_turn(vec2 d)\n{\n    return vec2((d.x * (-0.737368881702423095703125)) - (d.y * 0.675490319728851318359375), (d.y * (-0.737368881702423095703125)) + (d.x * 0.675490319728851318359375));\n}\n\nfloat fa_shadow_filter(vec2 uv, vec4 rect, float zr, float texel_m, float unit, float reach, float plane, vec3 conv, int mode, float k)\n{\n    if (mode == 1)\n    {\n        vec2 param = uv;\n        vec4 param_1 = rect;\n        vec3 param_2 = conv;\n        return float(zr <= fa_shadow_fetch(param, param_1, param_2));\n    }\n    float _2176 = fa_shadow_noise() * 6.283185482025146484375;\n    vec2 _2182 = vec2(cos(_2176), sin(_2176));\n    vec2 dir = _2182;\n    float radius = 1.5;\n    if (mode == 2)\n    {\n        float _2191;\n        if (k < 0.0)\n        {\n            _2191 = (-k) / max(zr, 0.100000001490116119384765625);\n        }\n        else\n        {\n            _2191 = k;\n        }\n        float _2210 = clamp((_2191 * reach) / texel_m, 3.0, 12.0);\n        float sum = 0.0;\n        float cnt = 0.0;\n        for (int i = 0; i < 16; i++)\n        {\n            float _2229 = sqrt((float(i) + 0.5) * 0.0625) * _2210;\n            vec2 param_3 = uv + (dir * (fa_shadows[26].zw * _2229));\n            vec4 param_4 = rect;\n            vec3 param_5 = conv;\n            float _2243 = fa_shadow_fetch(param_3, param_4, param_5);\n            if (_2243 < (zr - (_2229 * plane)))\n            {\n                sum += _2243;\n                cnt += 1.0;\n            }\n            vec2 param_6 = dir;\n            dir = fa_shadow_vogel_turn(param_6);\n        }\n        if (cnt < 0.5)\n        {\n            return 1.0;\n        }\n        float _2271 = sum / cnt;\n        float _2281;\n        if (k < 0.0)\n        {\n            _2281 = (-k) / max(_2271, 0.0500000007450580596923828125);\n        }\n        else\n        {\n            _2281 = k;\n        }\n        radius = clamp(((max(zr - _2271, 0.0) * unit) * _2281) / texel_m, 1.5, 16.0);\n        dir = _2182;\n    }\n    float lit = 0.0;\n    int _2307 = (mode == 2) ? 24 : 16;\n    for (int i_1 = 0; i_1 < _2307; i_1++)\n    {\n        float _2326 = sqrt((float(i_1) + 0.5) / float(_2307)) * radius;\n        vec2 param_7 = uv + (dir * (fa_shadows[26].zw * _2326));\n        vec4 param_8 = rect;\n        vec3 param_9 = conv;\n        lit += float((zr - (_2326 * plane)) <= fa_shadow_fetch(param_7, param_8, param_9));\n        vec2 param_10 = dir;\n        dir = fa_shadow_vogel_turn(param_10);\n    }\n    return lit / float(_2307);\n}\n\nfloat fa_shadow_local(int li, vec3 lpos, vec3 world, vec3 n, vec3 l)\n{\n    bool _2531 = fa_mesh_fs_params[5].z < 0.5;\n    bool _2538;\n    if (!_2531)\n    {\n        _2538 = fa_shadows[29].x < 0.5;\n    }\n    else\n    {\n        _2538 = _2531;\n    }\n    if (_2538)\n    {\n        return 1.0;\n    }\n    int param = (int(fa_shadows[29].x + 0.5) - 1) + li;\n    vec4 _2551 = fa_light_texel(param);\n    float _2552 = _2551.x;\n    if (_2552 < 0.0)\n    {\n        return 1.0;\n    }\n    int _2561 = int(_2552 + 0.5);\n    int param_1 = _2561;\n    vec4 _2565 = fa_light_texel(param_1);\n    int param_2 = _2561 + 1;\n    vec4 _2570 = fa_light_texel(param_2);\n    float fade = 1.0;\n    float _2573 = _2565.y;\n    if (_2573 > 0.0)\n    {\n        float _2590 = 1.0 - smoothstep(0.75 * _2573, _2573, length(world - fa_shadows[27].xyz));\n        fade = _2590;\n        if (_2590 <= 0.0)\n        {\n            return 1.0;\n        }\n    }\n    int face = 0;\n    if (_2565.x > 1.5)\n    {\n        vec3 param_3 = world - lpos;\n        face = fa_cube_face(param_3);\n    }\n    int _2614 = (_2561 + 2) + (face * 6);\n    int param_4 = _2614;\n    int param_5 = _2614 + 1;\n    int param_6 = _2614 + 3;\n    vec4 _2628 = fa_light_texel(param_6);\n    int param_7 = _2614 + 4;\n    vec4 _2633 = fa_light_texel(param_7);\n    int param_8 = _2614 + 5;\n    vec4 _2638 = fa_light_texel(param_8);\n    float _2650 = _2638.x * max(dot(_2628, vec4(world, 1.0)), 0.001000000047497451305389404296875);\n    float _2655 = clamp(dot(n, l), 0.0, 1.0);\n    float _2678 = clamp(dot(n, _2628.xyz), -1.0, 1.0);\n    float _2697 = min(sqrt(1.0 - (_2678 * _2678)) / max(abs(dot(n, world - lpos)) / max(dot(_2628, vec4(world, 1.0)), 0.001000000047497451305389404296875), 0.20000000298023223876953125), 4.0);\n    float _2700 = _2570.y;\n    float _2702;\n    if (_2700 > 0.0)\n    {\n        _2702 = _2700;\n    }\n    else\n    {\n        _2702 = 1.5 * _2650;\n    }\n    vec4 _2722 = vec4(world + (n * (_2702 * sqrt(1.0 - (_2655 * _2655)))), 1.0);\n    float _2726 = dot(_2628, _2722);\n    float _2729 = _2638.y;\n    if (_2726 < _2729)\n    {\n        return 1.0;\n    }\n    vec2 _2744 = vec2(dot(fa_light_texel(param_4), _2722), dot(fa_light_texel(param_5), _2722)) / vec2(_2726);\n    float _2746 = _2744.x;\n    bool _2749 = _2746 < _2633.x;\n    bool _2758;\n    if (!_2749)\n    {\n        _2758 = _2746 > _2633.z;\n    }\n    else\n    {\n        _2758 = _2749;\n    }\n    bool _2767;\n    if (!_2758)\n    {\n        _2767 = _2744.y < _2633.y;\n    }\n    else\n    {\n        _2767 = _2758;\n    }\n    bool _2776;\n    if (!_2767)\n    {\n        _2776 = _2744.y > _2633.w;\n    }\n    else\n    {\n        _2776 = _2767;\n    }\n    if (_2776)\n    {\n        return 1.0;\n    }\n    float _2782 = _2570.x;\n    float _2784;\n    if (_2782 > 0.0)\n    {\n        _2784 = _2782;\n    }\n    else\n    {\n        _2784 = 1.5 * _2650;\n    }\n    vec2 param_9 = _2744;\n    vec4 param_10 = _2633;\n    float param_11 = _2726 - (_2784 * (1.0 + (0.5 * _2697)));\n    float param_12 = _2650;\n    float param_13 = 1.0;\n    float param_14 = _2638.z * 0.25;\n    float param_15 = (_2650 * min(_2697, 3.0)) * 0.5;\n    vec3 param_16 = vec3(1.0, _2729, _2638.z);\n    int param_17 = int(_2565.z + 0.5);\n    float param_18 = _2565.w;\n    return mix(1.0, fa_shadow_filter(param_9, param_10, param_11, param_12, param_13, param_14, param_15, param_16, param_17, param_18), fade);\n}\n\nfloat fa_shadow_local_rt(int li, vec3 lpos, vec3 world, vec3 n, vec3 l)\n{\n    bool _3296 = fa_mesh_fs_params[25].w > 0.5;\n    bool _3302;\n    if (_3296)\n    {\n        _3302 = fa_mesh_fs_params[5].z > 0.5;\n    }\n    else\n    {\n        _3302 = _3296;\n    }\n    bool _3308;\n    if (_3302)\n    {\n        _3308 = fa_shadows[29].x > 0.5;\n    }\n    else\n    {\n        _3308 = _3302;\n    }\n    if (_3308)\n    {\n        int param = (int(fa_shadows[29].x + 0.5) - 1) + li;\n        vec4 _3320 = fa_light_texel(param);\n        float _3321 = _3320.z;\n        if (_3321 > 0.5)\n        {\n            float _3334 = dot(fa_mesh_fs_params[29].xyz, world) + fa_mesh_fs_params[29].w;\n            float _3337 = fwidth(_3334);\n            float _3341 = min(1.5 * _3337, 0.100000001490116119384765625 * _3334);\n            vec4 _3347 = vec4(world, 1.0);\n            float _3352 = dot(fa_mesh_fs_params[28], _3347);\n            if (_3352 > 9.9999997473787516355514526367188e-05)\n            {\n                vec2 _3369 = vec2(dot(fa_mesh_fs_params[26], _3347), dot(fa_mesh_fs_params[27], _3347)) / vec2(_3352);\n                float _3374 = (_3369.x * 0.5) + 0.5;\n                float _3378;\n                if (fa_mesh_fs_params[24].y > 0.5)\n                {\n                    _3378 = (_3369.y * 0.5) + 0.5;\n                }\n                else\n                {\n                    _3378 = 0.5 - (_3369.y * 0.5);\n                }\n                bool _3394 = _3374 >= 0.0;\n                bool _3400;\n                if (_3394)\n                {\n                    _3400 = _3374 < 1.0;\n                }\n                else\n                {\n                    _3400 = _3394;\n                }\n                bool _3406;\n                if (_3400)\n                {\n                    _3406 = _3378 >= 0.0;\n                }\n                else\n                {\n                    _3406 = _3400;\n                }\n                bool _3412;\n                if (_3406)\n                {\n                    _3412 = _3378 < 1.0;\n                }\n                else\n                {\n                    _3412 = _3406;\n                }\n                if (_3412)\n                {\n                    ivec2 _3429 = ivec2(fa_mesh_fs_params[24].zw) - ivec2(1);\n                    ivec2 _3430 = clamp(ivec2(vec2(_3374, _3378) * fa_mesh_fs_params[24].zw), ivec2(0), _3429);\n                    ivec2 _3442;\n                    ivec2 _3448;\n                    ivec2 _3455;\n                    float _3506;\n                    float _3527;\n                    for (int k = 0; k < 5; k++)\n                    {\n                        if (k == 0)\n                        {\n                            _3442 = ivec2(0);\n                        }\n                        else\n                        {\n                            if (k == 1)\n                            {\n                                _3448 = ivec2(1, 0);\n                            }\n                            else\n                            {\n                                if (k == 2)\n                                {\n                                    _3455 = ivec2(-1, 0);\n                                }\n                                else\n                                {\n                                    bvec2 _3466 = bvec2(k == 3);\n                                    _3455 = ivec2(_3466.x ? ivec2(0, 1).x : ivec2(0, -1).x, _3466.y ? ivec2(0, 1).y : ivec2(0, -1).y);\n                                }\n                                _3448 = _3455;\n                            }\n                            _3442 = _3448;\n                        }\n                        vec4 _3483 = texelFetch(fa_screen_tex_fa_shadow_smp, clamp(_3430 + _3442, ivec2(0), _3429), 0);\n                        bool _3486 = _3483.w > 0.5;\n                        bool _3500;\n                        if (_3486)\n                        {\n                            _3500 = abs(_3334 - _3483.x) <= (((0.00200000009499490261077880859375 * _3334) + 0.00999999977648258209228515625) + _3341);\n                        }\n                        else\n                        {\n                            _3500 = _3486;\n                        }\n                        if (_3500)\n                        {\n                            if (_3321 < 1.5)\n                            {\n                                _3506 = 1.0;\n                            }\n                            else\n                            {\n                                _3506 = (_3321 < 2.5) ? 256.0 : 65536.0;\n                            }\n                            float _3523 = mod(floor(_3483.z / _3506), 256.0) * 0.0039215688593685626983642578125;\n                            if (fa_mesh_fs_params[25].z > 0.5)\n                            {\n                                int param_1 = li;\n                                vec3 param_2 = lpos;\n                                vec3 param_3 = world;\n                                vec3 param_4 = n;\n                                vec3 param_5 = l;\n                                _3527 = min(_3523, fa_shadow_local(param_1, param_2, param_3, param_4, param_5));\n                            }\n                            else\n                            {\n                                _3527 = _3523;\n                            }\n                            return _3527;\n                        }\n                    }\n                }\n            }\n            float _3552;\n            if (fa_mesh_fs_params[25].z > 0.5)\n            {\n                int param_6 = li;\n                vec3 param_7 = lpos;\n                vec3 param_8 = world;\n                vec3 param_9 = n;\n                vec3 param_10 = l;\n                _3552 = fa_shadow_local(param_6, param_7, param_8, param_9, param_10);\n            }\n            else\n            {\n                _3552 = 1.0;\n            }\n            return _3552;\n        }\n    }\n    int param_11 = li;\n    vec3 param_12 = lpos;\n    vec3 param_13 = world;\n    vec3 param_14 = n;\n    vec3 param_15 = l;\n    return fa_shadow_local(param_11, param_12, param_13, param_14, param_15);\n}\n\nfloat fa_shadow_split_at(int i)\n{\n    float _2069;\n    if (i == 0)\n    {\n        _2069 = fa_shadows[24].x;\n    }\n    else\n    {\n        float _2085;\n        if (i == 1)\n        {\n            _2085 = fa_shadows[24].y;\n        }\n        else\n        {\n            float _2093;\n            if (i == 2)\n            {\n                _2093 = fa_shadows[24].z;\n            }\n            else\n            {\n                _2093 = fa_shadows[24].w;\n            }\n            _2085 = _2093;\n        }\n        _2069 = _2085;\n    }\n    return _2069;\n}\n\nfloat fa_shadow_cascade(int ci, vec3 world, vec3 n, vec3 l)\n{\n    float _2372 = max(fa_shadows[ci * 1 + 20].y, 0.001000000047497451305389404296875);\n    float _2377 = clamp(dot(n, l), 0.0, 1.0);\n    float _2383 = sqrt(1.0 - (_2377 * _2377));\n    float _2391 = min(_2383 / max(_2377, 0.20000000298023223876953125), 4.0);\n    float _2396;\n    if (fa_shadows[26].y > 0.0)\n    {\n        _2396 = fa_shadows[26].y;\n    }\n    else\n    {\n        _2396 = 1.5 * fa_shadows[ci * 1 + 20].x;\n    }\n    vec4 _2421 = mat4(fa_shadows[ci * 4 + 0], fa_shadows[ci * 4 + 1], fa_shadows[ci * 4 + 2], fa_shadows[ci * 4 + 3]) * vec4(world + (n * (_2396 * _2383)), 1.0);\n    float _2428 = _2421.x;\n    bool _2431 = _2428 < fa_shadows[ci * 1 + 16].x;\n    bool _2440;\n    if (!_2431)\n    {\n        _2440 = _2428 > fa_shadows[ci * 1 + 16].z;\n    }\n    else\n    {\n        _2440 = _2431;\n    }\n    bool _2449;\n    if (!_2440)\n    {\n        _2449 = _2421.y < fa_shadows[ci * 1 + 16].y;\n    }\n    else\n    {\n        _2449 = _2440;\n    }\n    bool _2458;\n    if (!_2449)\n    {\n        _2458 = _2421.y > fa_shadows[ci * 1 + 16].w;\n    }\n    else\n    {\n        _2458 = _2449;\n    }\n    bool _2465;\n    if (!_2458)\n    {\n        _2465 = _2421.z > 1.0;\n    }\n    else\n    {\n        _2465 = _2458;\n    }\n    if (_2465)\n    {\n        return -1.0;\n    }\n    float _2473;\n    if (fa_shadows[26].x > 0.0)\n    {\n        _2473 = fa_shadows[26].x;\n    }\n    else\n    {\n        _2473 = 1.5 * fa_shadows[ci * 1 + 20].x;\n    }\n    vec2 param = _2421.xy;\n    vec4 param_1 = fa_shadows[ci * 1 + 16];\n    float param_2 = _2421.z - ((_2473 * (1.0 + (0.5 * _2391))) / _2372);\n    float param_3 = fa_shadows[ci * 1 + 20].x;\n    float param_4 = _2372;\n    float param_5 = _2372 * 0.25;\n    float param_6 = ((fa_shadows[ci * 1 + 20].x * min(_2391, 3.0)) * 0.5) / _2372;\n    vec3 param_7 = vec3(0.0);\n    int param_8 = int(fa_shadows[25].z + 0.5);\n    float param_9 = fa_shadows[25].w;\n    return fa_shadow_filter(param, param_1, param_2, param_3, param_4, param_5, param_6, param_7, param_8, param_9);\n}\n\nfloat fa_shadow_sun(vec3 world, vec3 n, vec3 l)\n{\n    if (fa_mesh_fs_params[5].z < 0.5)\n    {\n        return 1.0;\n    }\n    int _2851 = int(fa_shadows[25].x + 0.5);\n    if (_2851 < 1)\n    {\n        return 1.0;\n    }\n    float _2866 = dot(world - fa_shadows[27].xyz, fa_shadows[28].xyz);\n    int param = _2851 - 1;\n    if (_2866 > fa_shadow_split_at(param))\n    {\n        return 1.0;\n    }\n    int ci = 0;\n    bool _2878 = _2851 > 1;\n    bool _2885;\n    if (_2878)\n    {\n        _2885 = _2866 > fa_shadows[24].x;\n    }\n    else\n    {\n        _2885 = _2878;\n    }\n    if (_2885)\n    {\n        ci = 1;\n    }\n    bool _2889 = _2851 > 2;\n    bool _2896;\n    if (_2889)\n    {\n        _2896 = _2866 > fa_shadows[24].y;\n    }\n    else\n    {\n        _2896 = _2889;\n    }\n    if (_2896)\n    {\n        ci = 2;\n    }\n    bool _2900 = _2851 > 3;\n    bool _2907;\n    if (_2900)\n    {\n        _2907 = _2866 > fa_shadows[24].z;\n    }\n    else\n    {\n        _2907 = _2900;\n    }\n    if (_2907)\n    {\n        ci = 3;\n    }\n    float s = -1.0;\n    float s2 = -1.0;\n    float t = 0.0;\n    int _2918 = min(_2851, 4);\n    float _2959;\n    for (int c = ci; c < _2918; c++)\n    {\n        int param_1 = c;\n        vec3 param_2 = world;\n        vec3 param_3 = n;\n        vec3 param_4 = l;\n        float _2938 = fa_shadow_cascade(param_1, param_2, param_3, param_4);\n        if (s >= 0.0)\n        {\n            s2 = _2938;\n            break;\n        }\n        if (_2938 < 0.0)\n        {\n            continue;\n        }\n        s = _2938;\n        ci = c;\n        if (fa_shadows[25].y > 0.0)\n        {\n            if (ci > 0)\n            {\n                int param_5 = ci - 1;\n                _2959 = fa_shadow_split_at(param_5);\n            }\n            else\n            {\n                _2959 = fa_shadows[28].w;\n            }\n            int param_6 = ci;\n            float _2978 = fa_shadows[25].y * max(fa_shadow_split_at(param_6) - _2959, 9.9999997473787516355514526367188e-05);\n            int param_7 = ci;\n            t = clamp((_2866 - (fa_shadow_split_at(param_7) - _2978)) / _2978, 0.0, 1.0);\n        }\n        if (t <= 0.0)\n        {\n            break;\n        }\n    }\n    if (s < 0.0)\n    {\n        return 1.0;\n    }\n    if (t > 0.0)\n    {\n        float _3010;\n        if ((ci + 1) < _2851)\n        {\n            _3010 = (s2 < 0.0) ? s : s2;\n        }\n        else\n        {\n            _3010 = 1.0;\n        }\n        s = mix(s, _3010, t);\n    }\n    return s;\n}\n\nfloat fa_shadow_factor(vec3 n, vec3 l)\n{\n    bool _3115 = fa_mesh_fs_params[25].y > 0.5;\n    bool _3121;\n    if (_3115)\n    {\n        _3121 = fa_mesh_fs_params[5].z > 0.5;\n    }\n    else\n    {\n        _3121 = _3115;\n    }\n    if (_3121)\n    {\n        float _3135 = dot(fa_mesh_fs_params[29].xyz, fa_world_pos) + fa_mesh_fs_params[29].w;\n        float _3138 = fwidth(_3135);\n        vec4 _3148 = vec4(fa_world_pos, 1.0);\n        float _3154 = dot(fa_mesh_fs_params[28], _3148);\n        if (_3154 > 9.9999997473787516355514526367188e-05)\n        {\n            vec2 _3173 = vec2(dot(fa_mesh_fs_params[26], _3148), dot(fa_mesh_fs_params[27], _3148)) / vec2(_3154);\n            float _3178 = (_3173.x * 0.5) + 0.5;\n            float _3182;\n            if (fa_mesh_fs_params[24].y > 0.5)\n            {\n                _3182 = (_3173.y * 0.5) + 0.5;\n            }\n            else\n            {\n                _3182 = 0.5 - (_3173.y * 0.5);\n            }\n            bool _3198 = _3178 >= 0.0;\n            bool _3204;\n            if (_3198)\n            {\n                _3204 = _3178 < 1.0;\n            }\n            else\n            {\n                _3204 = _3198;\n            }\n            bool _3210;\n            if (_3204)\n            {\n                _3210 = _3182 >= 0.0;\n            }\n            else\n            {\n                _3210 = _3204;\n            }\n            bool _3216;\n            if (_3210)\n            {\n                _3216 = _3182 < 1.0;\n            }\n            else\n            {\n                _3216 = _3210;\n            }\n            if (_3216)\n            {\n                vec4 _3242 = texelFetch(fa_screen_tex_fa_shadow_smp, clamp(ivec2(vec2(_3178, _3182) * fa_mesh_fs_params[24].zw), ivec2(0), ivec2(fa_mesh_fs_params[24].zw) - ivec2(1)), 0);\n                bool _3245 = _3242.w > 0.5;\n                bool _3261;\n                if (_3245)\n                {\n                    _3261 = abs(_3135 - _3242.x) <= (((0.00200000009499490261077880859375 * _3135) + 0.00999999977648258209228515625) + min(1.5 * _3138, 0.100000001490116119384765625 * _3135));\n                }\n                else\n                {\n                    _3261 = _3245;\n                }\n                if (_3261)\n                {\n                    float _3267;\n                    if (fa_mesh_fs_params[25].z > 0.5)\n                    {\n                        vec3 param = fa_world_pos;\n                        vec3 param_1 = n;\n                        vec3 param_2 = l;\n                        _3267 = min(_3242.y, fa_shadow_sun(param, param_1, param_2));\n                    }\n                    else\n                    {\n                        _3267 = _3242.y;\n                    }\n                    return _3267;\n                }\n            }\n        }\n    }\n    vec3 param_3 = fa_world_pos;\n    vec3 param_4 = n;\n    vec3 param_5 = l;\n    return fa_shadow_sun(param_3, param_4, param_5);\n}\n\nfloat fa_contact_shadow(int li, vec3 world, vec3 gn, vec3 l, float dist)\n{\n    bool _3923 = fa_mesh_fs_params[24].x < 0.5;\n    bool _3930;\n    if (!_3923)\n    {\n        _3930 = fa_shadows[29].x < 0.5;\n    }\n    else\n    {\n        _3930 = _3923;\n    }\n    if (_3930)\n    {\n        return 1.0;\n    }\n    int param = (int(fa_shadows[29].x + 0.5) - 1) + li;\n    vec4 _3943 = fa_light_texel(param);\n    float _3944 = _3943.y;\n    float len = _3944;\n    if (_3944 <= 0.0)\n    {\n        return 1.0;\n    }\n    float _3956 = length(world - fa_mesh_fs_params[0].xyz);\n    float _3965 = 1.0 - smoothstep(0.5 * fa_mesh_fs_params[25].x, fa_mesh_fs_params[25].x, _3956);\n    if (_3965 <= 0.0)\n    {\n        return 1.0;\n    }\n    float _3971 = len;\n    float _3974 = min(_3971, 0.89999997615814208984375 * dist);\n    len = _3974;\n    float _3980 = 0.004999999888241291046142578125 + (0.0030000000260770320892333984375 * _3956);\n    float _3985 = _3980 + (0.5 * _3974);\n    vec3 _3991 = world + (gn * _3980);\n    float _3993 = fa_shadow_noise();\n    float occ = 0.0;\n    float _4055;\n    for (int k = 0; k < 12; k++)\n    {\n        float _4009 = (float(k) + _3993) * 0.083333335816860198974609375;\n        vec3 _4017 = _3991 + (l * (_4009 * len));\n        vec4 _4023 = vec4(_4017, 1.0);\n        float _4028 = dot(fa_mesh_fs_params[28], _4023);\n        if (_4028 < 9.9999997473787516355514526367188e-05)\n        {\n            break;\n        }\n        vec2 _4046 = vec2(dot(fa_mesh_fs_params[26], _4023), dot(fa_mesh_fs_params[27], _4023)) / vec2(_4028);\n        float _4050 = _4046.x * 0.5;\n        float _4051 = _4050 + 0.5;\n        if (fa_mesh_fs_params[24].y > 0.5)\n        {\n            _4055 = (_4046.y * 0.5) + 0.5;\n        }\n        else\n        {\n            _4055 = 0.5 - (_4046.y * 0.5);\n        }\n        bool _4071 = _4051 < 0.0;\n        bool _4078;\n        if (!_4071)\n        {\n            _4078 = _4051 >= 1.0;\n        }\n        else\n        {\n            _4078 = _4071;\n        }\n        bool _4085;\n        if (!_4078)\n        {\n            _4085 = _4055 < 0.0;\n        }\n        else\n        {\n            _4085 = _4078;\n        }\n        bool _4092;\n        if (!_4085)\n        {\n            _4092 = _4055 >= 1.0;\n        }\n        else\n        {\n            _4092 = _4085;\n        }\n        if (_4092)\n        {\n            break;\n        }\n        vec4 _4116 = texelFetch(fa_screen_tex_fa_shadow_smp, clamp(ivec2(vec2(_4051, _4055) * fa_mesh_fs_params[24].zw), ivec2(0), ivec2(fa_mesh_fs_params[24].zw) - ivec2(1)), 0);\n        if (_4116.w < 0.5)\n        {\n            continue;\n        }\n        float _4134 = (dot(fa_mesh_fs_params[29].xyz, _4017) + fa_mesh_fs_params[29].w) - _4116.x;\n        if ((_4134 > _3980) && (_4134 < _3985))\n        {\n            occ = max(occ, (1.0 - (_4009 * _4009)) * smoothstep(0.0, 0.0500000007450580596923828125, min(min(_4051, 0.5 - _4050), min(_4055, 1.0 - _4055))));\n        }\n    }\n    return 1.0 - (occ * _3965);\n}\n\nLightSample fa_light_shadowed(int li, vec3 world_pos, vec3 gn)\n{\n    int param = li;\n    float _4237 = fa_baked_keep(param);\n    if (_4237 <= 0.0)\n    {\n        int param_1 = li;\n        return LightSample(vec3(0.0, 1.0, 0.0), vec3(0.0), 0.0, 1.0, 0.0, int(fa_light_type(param_1) + 0.5));\n    }\n    int param_2 = li;\n    vec3 param_3 = world_pos;\n    vec3 param_4 = gn;\n    LightSample _4263 = fa_light_sample_n(param_2, param_3, param_4);\n    vec3 _6087 = _4263.color;\n    float _6088 = _4263.attenuation;\n    float _6089 = _4263.shadow;\n    bool _4266 = _4263.type == 0;\n    if (_4266 && (li == 0))\n    {\n        vec3 param_5 = gn;\n        vec3 param_6 = _4263.direction;\n        float _4277 = fa_shadow_factor(param_5, param_6);\n        _6089 = _4277;\n        _6087 *= _4277;\n    }\n    else\n    {\n        bool _4288 = _4263.type != 0;\n        bool _4294;\n        if (_4288)\n        {\n            _4294 = _6088 > 0.0;\n        }\n        else\n        {\n            _4294 = _4288;\n        }\n        if (_4294)\n        {\n            int param_7 = li;\n            int param_8 = fa_light_base(param_7);\n            int param_9 = li;\n            vec3 param_10 = fa_light_texel(param_8).xyz;\n            vec3 param_11 = world_pos;\n            vec3 param_12 = gn;\n            vec3 param_13 = _4263.direction;\n            float _4313 = fa_shadow_local_rt(param_9, param_10, param_11, param_12, param_13);\n            _6089 = _4313;\n            _6087 *= _4313;\n        }\n    }\n    bool _4323 = fa_mesh_fs_params[24].x > 0.5;\n    bool _4329;\n    if (_4323)\n    {\n        _4329 = _6088 > 0.0;\n    }\n    else\n    {\n        _4329 = _4323;\n    }\n    if (_4329)\n    {\n        float _4336;\n        if (_4266)\n        {\n            _4336 = 1000000000.0;\n        }\n        else\n        {\n            _4336 = _4263._distance;\n        }\n        int param_14 = li;\n        vec3 param_15 = world_pos;\n        vec3 param_16 = gn;\n        vec3 param_17 = _4263.direction;\n        float param_18 = _4336;\n        float _4354 = fa_contact_shadow(param_14, param_15, param_16, param_17, param_18);\n        _6089 *= _4354;\n        _6087 *= _4354;\n    }\n    float _4367 = _6088;\n    float _4368 = _4367 * _4237;\n    _6088 = _4368;\n    vec3 _4372 = _6087;\n    vec3 _4373 = _4372 * _4237;\n    _6087 = _4373;\n    return LightSample(_4263.direction, _4373, _4368, _6089, _4263._distance, _4263.type);\n}\n\nvec3 light(SurfaceInput i, Surface s, LightSample l)\n{\n    return vec3(0.0);\n}\n\nvec3 fa_shadow_debug(vec3 color, vec3 world)\n{\n    if (fa_shadows[27].w < 0.5)\n    {\n        return color;\n    }\n    int _3038 = int(fa_shadows[25].x + 0.5);\n    float _3048 = dot(world - fa_shadows[27].xyz, fa_shadows[28].xyz);\n    vec3 tint = vec3(0.3499999940395355224609375);\n    bool _3053 = _3038 > 0;\n    bool _3062;\n    if (_3053)\n    {\n        int param = _3038 - 1;\n        _3062 = _3048 <= fa_shadow_split_at(param);\n    }\n    else\n    {\n        _3062 = _3053;\n    }\n    if (_3062)\n    {\n        tint = vec3(1.0, 0.1500000059604644775390625, 0.100000001490116119384765625);\n        bool _3068 = _3038 > 1;\n        bool _3075;\n        if (_3068)\n        {\n            _3075 = _3048 > fa_shadows[24].x;\n        }\n        else\n        {\n            _3075 = _3068;\n        }\n        if (_3075)\n        {\n            tint = vec3(0.100000001490116119384765625, 0.89999997615814208984375, 0.20000000298023223876953125);\n        }\n        bool _3081 = _3038 > 2;\n        bool _3088;\n        if (_3081)\n        {\n            _3088 = _3048 > fa_shadows[24].y;\n        }\n        else\n        {\n            _3088 = _3081;\n        }\n        if (_3088)\n        {\n            tint = vec3(0.1500000059604644775390625, 0.300000011920928955078125, 1.0);\n        }\n        bool _3094 = _3038 > 3;\n        bool _3101;\n        if (_3094)\n        {\n            _3101 = _3048 > fa_shadows[24].z;\n        }\n        else\n        {\n            _3101 = _3094;\n        }\n        if (_3101)\n        {\n            tint = vec3(1.0, 0.89999997615814208984375, 0.100000001490116119384765625);\n        }\n    }\n    return mix(color, tint, vec3(0.550000011920928955078125));\n}\n\nvoid main()\n{\n    fa_inst_load();\n    vec3 _5879 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _5879 = -_5879;\n    }\n    vec3 _5453 = normalize(fa_mesh_fs_params[0].xyz - fa_world_pos);\n    vec3 param = fa_world_pos;\n    fa_cluster_begin(param);\n    SurfaceInput param_1 = SurfaceInput(fa_world_pos, _5879, fa_world_tangent, fa_uv, fa_vertex_color, _5453, gl_FrontFacing);\n    Surface _5461 = fa_standard_surface(param_1);\n    vec3 _5918 = _5461.albedo;\n    float _5919 = _5461.alpha;\n    vec3 _5920 = _5461.normal;\n    float _5921 = _5461.metallic;\n    float _5922 = _5461.roughness;\n    float _5923 = _5461.occlusion;\n    vec3 _5924 = _5461.emission;\n    float _5925 = _5461.clearcoat;\n    float _5926 = _5461.clearcoat_roughness;\n    vec3 _5927 = _5461.sheen_color;\n    float _5928 = _5461.sheen_roughness;\n    float _5929 = _5461.anisotropy;\n    float _5930 = _5461.anisotropy_rotation;\n    float _5931 = _5461.specular;\n    float _5932 = _5461.ior;\n    vec3 _5933 = _5461.specular_color;\n    float _5934 = _5461.transmission;\n    float _5935 = _5461.thickness;\n    vec3 _5936 = _5461.attenuation_color;\n    float _5937 = _5461.attenuation_distance;\n    SurfaceInput param_2 = SurfaceInput(fa_world_pos, _5879, fa_world_tangent, fa_uv, fa_vertex_color, _5453, gl_FrontFacing);\n    Surface param_3 = _5461;\n    surface(param_2, param_3);\n    _5918 = param_3.albedo;\n    _5919 = param_3.alpha;\n    _5920 = param_3.normal;\n    _5921 = param_3.metallic;\n    _5922 = param_3.roughness;\n    _5923 = param_3.occlusion;\n    _5924 = param_3.emission;\n    _5925 = param_3.clearcoat;\n    _5926 = param_3.clearcoat_roughness;\n    _5927 = param_3.sheen_color;\n    _5928 = param_3.sheen_roughness;\n    _5929 = param_3.anisotropy;\n    _5930 = param_3.anisotropy_rotation;\n    _5931 = param_3.specular;\n    _5932 = param_3.ior;\n    _5933 = param_3.specular_color;\n    _5934 = param_3.transmission;\n    _5935 = param_3.thickness;\n    _5936 = param_3.attenuation_color;\n    _5937 = param_3.attenuation_distance;\n    vec3 param_4 = fa_world_pos;\n    vec3 param_5 = _5879;\n    vec3 param_6 = param_3.albedo;\n    vec3 param_7 = param_3.normal;\n    fa_apply_decals(param_4, param_5, param_6, param_7);\n    _5918 = param_6;\n    _5920 = param_7;\n    vec3 result;\n    if (fa_mesh_fs_params[3].w > 0.5)\n    {\n        result = _5918;\n    }\n    else\n    {\n        vec3 _5500 = _5920;\n        vec3 _5501 = normalize(_5500);\n        _5920 = _5501;\n        vec3 param_8 = _5501;\n        SurfaceInput param_9 = SurfaceInput(fa_world_pos, _5879, fa_world_tangent, fa_uv, fa_vertex_color, _5453, gl_FrontFacing);\n        Surface param_10 = Surface(_5918, _5919, _5920, _5921, _5922, _5923, _5924, _5925, _5926, _5927, _5928, _5929, _5930, _5931, _5932, _5933, _5934, _5935, _5936, _5937);\n        vec3 param_11 = fa_indirect_diffuse(param_8);\n        vec3 lit = ambient(param_9, param_10, param_11);\n        int _5520 = fa_cl_ndir + fa_cl_local;\n        for (int ln = 0; ln < _5520; ln++)\n        {\n            int param_12 = ln;\n            int _5533 = fa_cl_light(param_12);\n            int param_13 = _5533;\n            if (fa_baked_keep(param_13) <= 0.0)\n            {\n                continue;\n            }\n            int param_14 = _5533;\n            vec3 param_15 = fa_world_pos;\n            vec3 param_16 = _5879;\n            LightSample _5549 = fa_light_shadowed(param_14, param_15, param_16);\n            SurfaceInput param_17 = SurfaceInput(fa_world_pos, _5879, fa_world_tangent, fa_uv, fa_vertex_color, _5453, gl_FrontFacing);\n            Surface param_18 = Surface(_5918, _5919, _5920, _5921, _5922, _5923, _5924, _5925, _5926, _5927, _5928, _5929, _5930, _5931, _5932, _5933, _5934, _5935, _5936, _5937);\n            LightSample param_19 = _5549;\n            lit += light(param_17, param_18, param_19);\n        }\n        result = lit;\n    }\n    vec3 _5564 = result;\n    vec3 _5565 = _5564 + _5924;\n    result = _5565;\n    vec3 param_20 = _5565;\n    vec3 param_21 = fa_world_pos;\n    result = fa_shadow_debug(param_20, param_21);\n    bool _5574 = fa_mesh_fs_params[7].w > 0.0;\n    bool _5581;\n    if (!_5574)\n    {\n        _5581 = fa_mesh_fs_params[8].y > 0.0;\n    }\n    else\n    {\n        _5581 = _5574;\n    }\n    if (_5581)\n    {\n        vec3 _5590 = fa_world_pos - fa_mesh_fs_params[0].xyz;\n        float _5596 = dot(_5590, fa_mesh_fs_params[9].xyz);\n        bool _5600 = fa_mesh_fs_params[9].w > 0.5;\n        float _5601;\n        if (_5600)\n        {\n            _5601 = _5596;\n        }\n        else\n        {\n            _5601 = length(_5590);\n        }\n        float _5613 = _5601 - fa_mesh_fs_params[8].x;\n        if (_5613 > 0.0)\n        {\n            float _5622 = fa_mesh_fs_params[7].w * _5613;\n            float tau = _5622 * _5622;\n            if (fa_mesh_fs_params[8].y > 0.0)\n            {\n                float _5638;\n                if (_5600)\n                {\n                    _5638 = fa_world_pos.y - (fa_mesh_fs_params[9].y * _5596);\n                }\n                else\n                {\n                    _5638 = fa_mesh_fs_params[0].y;\n                }\n                float _5659 = mix(_5638, fa_world_pos.y, clamp(fa_mesh_fs_params[8].x / _5601, 0.0, 1.0));\n                float _5663 = fa_world_pos.y - _5659;\n                float _5668 = _5659 - fa_mesh_fs_params[8].z;\n                float _5673 = fa_world_pos.y - fa_mesh_fs_params[8].z;\n                bool _5676 = _5668 <= 0.0;\n                bool _5677 = !_5676;\n                bool _5683;\n                if (_5677)\n                {\n                    _5683 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _5683 = _5676;\n                }\n                float _5684;\n                if (_5683)\n                {\n                    _5684 = fa_mesh_fs_params[8].y;\n                }\n                else\n                {\n                    _5684 = fa_mesh_fs_params[8].y * exp(-min(fa_mesh_fs_params[8].w * _5668, 80.0));\n                }\n                bool _5711;\n                if (_5677)\n                {\n                    _5711 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _5711 = _5676;\n                }\n                float _5712;\n                if (_5711)\n                {\n                    _5712 = fa_mesh_fs_params[8].y * _5668;\n                }\n                else\n                {\n                    _5712 = (fa_mesh_fs_params[8].y * (1.0 - exp(-min(fa_mesh_fs_params[8].w * _5668, 80.0)))) / fa_mesh_fs_params[8].w;\n                }\n                bool _5737 = _5673 <= 0.0;\n                bool _5744;\n                if (!_5737)\n                {\n                    _5744 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _5744 = _5737;\n                }\n                float _5745;\n                if (_5744)\n                {\n                    _5745 = fa_mesh_fs_params[8].y * _5673;\n                }\n                else\n                {\n                    _5745 = (fa_mesh_fs_params[8].y * (1.0 - exp(-min(fa_mesh_fs_params[8].w * _5673, 80.0)))) / fa_mesh_fs_params[8].w;\n                }\n                float _5772;\n                if (abs(_5663) < 0.001000000047497451305389404296875)\n                {\n                    _5772 = _5684;\n                }\n                else\n                {\n                    _5772 = (_5745 - _5712) / _5663;\n                }\n                tau += (_5613 * max(_5772, 0.0));\n            }\n            result = mix(result, fa_mesh_fs_params[7].xyz, vec3(clamp(1.0 - exp(-clamp(tau, 0.0, 80.0)), 0.0, 1.0)));\n        }\n    }\n    fa_frag_color = vec4(result, _5919);\n}\n\n",
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
            "inst_name": "_427",
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
            "inst_name": "_2079",
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
      "fs": "#version 430\n\nstruct SurfaceInput\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 vertex_color;\n    vec3 view_dir;\n    bool front_facing;\n};\n\nstruct LightSample\n{\n    vec3 direction;\n    vec3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct Surface\n{\n    vec3 albedo;\n    float alpha;\n    vec3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    vec3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    vec3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    vec3 specular_color;\n    float transmission;\n    float thickness;\n    vec3 attenuation_color;\n    float attenuation_distance;\n};\n\nuniform vec4 fa_mesh_fs_params[53];\nuniform vec4 fa_shadows[30];\nlayout(binding = 0) uniform sampler2D fa_light_tex_fa_shadow_smp;\nlayout(binding = 1) uniform sampler2D fa_tex_fa_smp;\nlayout(binding = 2) uniform sampler2D fa_normal_tex_fa_smp;\nlayout(binding = 3) uniform sampler2D fa_mr_tex_fa_smp;\nlayout(binding = 4) uniform sampler2D fa_occlusion_tex_fa_smp;\nlayout(binding = 5) uniform sampler2D fa_emissive_tex_fa_smp;\nlayout(binding = 6) uniform sampler2D fa_decal_tex_fa_env_smp;\nlayout(binding = 7) uniform sampler2D fa_lightmap_fa_env_smp;\nlayout(binding = 8) uniform sampler2D fa_probe_atlas_fa_env_smp;\nlayout(binding = 9) uniform sampler2D fa_light_atlas_fa_env_smp;\nlayout(binding = 10) uniform sampler2D fa_screen_tex_fa_shadow_smp;\nlayout(binding = 11) uniform sampler2D fa_shadow_tex_fa_shadow_smp;\n\nlayout(location = 0) in vec3 fa_world_pos;\nlayout(location = 5) in vec3 fa_lm;\nlayout(location = 1) in vec3 fa_world_normal;\nlayout(location = 2) in vec4 fa_world_tangent;\nlayout(location = 3) in vec2 fa_uv;\nlayout(location = 4) in vec4 fa_vertex_color;\nlayout(location = 0) out vec4 fa_frag_color;\nvec3 fa_light_tint;\nbool fa_light_is_area;\nint fa_cl_ndir;\nint fa_cl_slot;\nint fa_cl_local;\n\nvoid fa_inst_load()\n{\n}\n\nvec4 fa_light_texel(int t)\n{\n    return texelFetch(fa_light_tex_fa_shadow_smp, ivec2(t & 1023, t >> 10), 0);\n}\n\nvec4 fa_cluster_texel(vec3 world_pos)\n{\n    bool _1355 = fa_mesh_fs_params[19].x < 0.0;\n    bool _1362;\n    if (!_1355)\n    {\n        _1362 = fa_mesh_fs_params[19].w < 1.0;\n    }\n    else\n    {\n        _1362 = _1355;\n    }\n    bool _1370;\n    if (!_1362)\n    {\n        _1370 = fa_mesh_fs_params[18].x < 1.0;\n    }\n    else\n    {\n        _1370 = _1362;\n    }\n    bool _1377;\n    if (!_1370)\n    {\n        _1377 = fa_mesh_fs_params[18].y < 1.0;\n    }\n    else\n    {\n        _1377 = _1370;\n    }\n    bool _1384;\n    if (!_1377)\n    {\n        _1384 = fa_mesh_fs_params[19].y < 1.0;\n    }\n    else\n    {\n        _1384 = _1377;\n    }\n    if (_1384)\n    {\n        return vec4(0.0);\n    }\n    vec4 _1394 = vec4(world_pos, 1.0);\n    float _1400 = dot(fa_mesh_fs_params[16], _1394);\n    if (!(_1400 > 9.9999999747524270787835121154785e-07))\n    {\n        return vec4(0.0);\n    }\n    vec2 _1422 = vec2(dot(fa_mesh_fs_params[14], _1394), dot(fa_mesh_fs_params[15], _1394)) / vec2(_1400);\n    int _1426 = int(fa_mesh_fs_params[18].x);\n    int _1430 = int(fa_mesh_fs_params[18].y);\n    int param = (int(fa_mesh_fs_params[19].x) + (((clamp(int(floor(log2(max(dot(fa_mesh_fs_params[17].xyz, world_pos) + fa_mesh_fs_params[17].w, fa_mesh_fs_params[18].w) / fa_mesh_fs_params[18].w) * fa_mesh_fs_params[18].z)), 0, int(fa_mesh_fs_params[19].y) - 1) * _1430) + clamp(int(floor(((_1422.y * 0.5) + 0.5) * fa_mesh_fs_params[18].y)), 0, _1430 - 1)) * _1426)) + clamp(int(floor(((_1422.x * 0.5) + 0.5) * fa_mesh_fs_params[18].x)), 0, _1426 - 1);\n    return fa_light_texel(param);\n}\n\nivec2 fa_cluster_lookup(vec3 world_pos)\n{\n    vec3 param = world_pos;\n    vec4 _1506 = fa_cluster_texel(param);\n    return ivec2(int(_1506.x), int(_1506.y));\n}\n\nvoid fa_cluster_begin(vec3 world_pos)\n{\n    fa_cl_ndir = int(fa_mesh_fs_params[19].z);\n    vec3 param = world_pos;\n    ivec2 _4211 = fa_cluster_lookup(param);\n    fa_cl_slot = _4211.x;\n    fa_cl_local = _4211.y;\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_linear_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvec3 fa_tex_fix(inout vec3 c, float mode)\n{\n    if (mode > 1.5)\n    {\n        vec3 param = c;\n        vec3 _4421 = fa_linear_to_srgb(param);\n        c = _4421;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            vec3 param_1 = c;\n            vec3 _4429 = fa_srgb_to_linear(param_1);\n            c = _4429;\n        }\n    }\n    return c;\n}\n\nvec3 fa_tangent_normal(SurfaceInput i, vec3 m)\n{\n    vec3 _309;\n    if (i.front_facing)\n    {\n        _309 = i.world_normal;\n    }\n    else\n    {\n        _309 = -i.world_normal;\n    }\n    vec3 _333 = normalize(i.world_tangent.xyz - (_309 * dot(_309, i.world_tangent.xyz)));\n    vec3 _360 = normalize(((_333 * m.x) + ((cross(_309, _333) * i.world_tangent.w) * m.y)) + (_309 * m.z));\n    vec3 _363;\n    if (i.front_facing)\n    {\n        _363 = _360;\n    }\n    else\n    {\n        _363 = -_360;\n    }\n    return _363;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    vec4 base_t = texture(fa_tex_fa_smp, i.uv, fa_mesh_fs_params[12].w);\n    float param = fa_mesh_fs_params[6].w;\n    float param_1 = 1.0;\n    vec3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    vec3 _4461 = fa_tex_fix(param_2, param_3);\n    vec4 _6291 = base_t;\n    _6291.x = _4461.x;\n    _6291.y = _4461.y;\n    _6291.z = _4461.z;\n    base_t = _6291;\n    vec4 _4475 = (_6291 * fa_mesh_fs_params[2]) * i.vertex_color;\n    vec3 _6107 = i.world_normal;\n    if (fa_mesh_fs_params[6].z > 0.5)\n    {\n        float param_4 = fa_mesh_fs_params[6].w;\n        float param_5 = 16.0;\n        vec3 param_6 = texture(fa_normal_tex_fa_smp, i.uv, fa_mesh_fs_params[12].w).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        vec3 _4509 = fa_tex_fix(param_6, param_7);\n        vec3 _4512 = (_4509 * 2.0) - vec3(1.0);\n        vec2 _4517 = _4512.xy * fa_mesh_fs_params[6].x;\n        vec3 _6299 = _4512;\n        _6299.x = _4517.x;\n        _6299.y = _4517.y;\n        SurfaceInput param_8 = i;\n        vec3 param_9 = _6299;\n        _6107 = fa_tangent_normal(param_8, param_9);\n    }\n    vec4 mrt = texture(fa_mr_tex_fa_smp, i.uv, fa_mesh_fs_params[12].w);\n    float param_10 = fa_mesh_fs_params[6].w;\n    float param_11 = 64.0;\n    vec3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    vec3 _4547 = fa_tex_fix(param_12, param_13);\n    vec4 _6302 = mrt;\n    _6302.x = _4547.x;\n    _6302.y = _4547.y;\n    _6302.z = _4547.z;\n    mrt = _6302;\n    vec4 _4577 = texture(fa_occlusion_tex_fa_smp, i.uv, fa_mesh_fs_params[12].w);\n    float param_14 = fa_mesh_fs_params[6].w;\n    float param_15 = 256.0;\n    vec3 param_16 = _4577.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    vec3 _4588 = fa_tex_fix(param_16, param_17);\n    float param_18 = fa_mesh_fs_params[6].w;\n    float param_19 = 4.0;\n    vec3 param_20 = texture(fa_emissive_tex_fa_smp, i.uv, fa_mesh_fs_params[12].w).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    vec3 _4620 = fa_tex_fix(param_20, param_21);\n    float _6112 = fa_mesh_fs_params[20].x;\n    float _6113 = fa_mesh_fs_params[20].y;\n    float _6116 = fa_mesh_fs_params[20].z;\n    float _6115 = fa_mesh_fs_params[21].w;\n    float _6118 = fa_mesh_fs_params[22].x;\n    if (fa_mesh_fs_params[22].z > 0.5)\n    {\n        if (mod(fa_mesh_fs_params[22].z, 2.0) > 0.5)\n        {\n            _6112 *= _4588.y;\n            _6113 *= _4588.z;\n            _6115 *= _4577.w;\n        }\n        if (fa_mesh_fs_params[22].z > 1.5)\n        {\n            _6116 *= mrt.x;\n            _6118 *= mrt.w;\n        }\n    }\n    return Surface(_4475.xyz, _4475.w, _6107, clamp(fa_mesh_fs_params[5].x * _4547.z, 0.0, 1.0), clamp(fa_mesh_fs_params[5].y * _4547.y, 0.0500000007450580596923828125, 1.0), 1.0 + (fa_mesh_fs_params[6].y * (_4588.x - 1.0)), fa_mesh_fs_params[3].xyz + (fa_mesh_fs_params[4].xyz * _4620), _6112, _6113, fa_mesh_fs_params[21].xyz, _6115, _6116, fa_mesh_fs_params[20].w, _6118, fa_mesh_fs_params[22].y, fa_mesh_fs_params[23].xyz, fa_mesh_fs_params[30].x, fa_mesh_fs_params[30].y, fa_mesh_fs_params[31].xyz, fa_mesh_fs_params[30].z);\n}\n\nvoid surface(SurfaceInput i, Surface s)\n{\n}\n\nvec4 fa_decal_tile(vec4 rect, vec2 uv, vec2 atlas, vec2 ddx, vec2 ddy)\n{\n    vec2 _1586 = rect.zw - rect.xy;\n    vec2 _1590 = _1586 * atlas;\n    vec2 _1594 = ddx * _1590;\n    vec2 _1598 = ddy * _1590;\n    return textureLod(fa_decal_tex_fa_env_smp, rect.xy + (clamp(uv, vec2(0.0), vec2(1.0)) * _1586), clamp(0.5 * log2(max(max(dot(_1594, _1594), dot(_1598, _1598)), 9.9999999392252902907785028219223e-09)), 0.0, 3.0));\n}\n\nvec3 fa_dc_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_dc_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvoid fa_apply_decals(vec3 world_pos, vec3 geo_normal, inout vec3 albedo, inout vec3 normal)\n{\n    bool _1631 = fa_mesh_fs_params[10].y < 0.5;\n    bool _1638;\n    if (!_1631)\n    {\n        _1638 = fa_mesh_fs_params[10].w < 0.5;\n    }\n    else\n    {\n        _1638 = _1631;\n    }\n    if (_1638)\n    {\n        return;\n    }\n    vec3 _1644 = dFdx(world_pos);\n    vec3 _1647 = dFdy(world_pos);\n    vec3 param = world_pos;\n    vec4 _1651 = fa_cluster_texel(param);\n    int _1655 = int(_1651.w);\n    if (_1655 < 1)\n    {\n        return;\n    }\n    int _1665 = int(fa_mesh_fs_params[10].y + 0.5);\n    int param_1 = _1665;\n    vec4 _1669 = fa_light_texel(param_1);\n    vec2 _1672 = _1669.yz;\n    int _1676 = int(_1669.w);\n    int param_2 = _1665 + 1;\n    vec4 _1681 = fa_light_texel(param_2);\n    float _1682 = _1681.x;\n    int _1688 = int(fa_mesh_fs_params[10].w + 0.5) - 1;\n    int _1692 = int(_1651.z);\n    vec3 _1957;\n    for (int k = 0; k < _1655; k++)\n    {\n        int _1705 = _1692 + k;\n        int param_3 = _1676 + (_1705 >> 2);\n        int _1722 = (_1665 + 2) + (int(fa_light_texel(param_3)[_1705 & 3]) * 7);\n        int param_4 = _1722 + 6;\n        vec4 _1727 = fa_light_texel(param_4);\n        if (((int(_1727.w + 0.5) >> _1688) & 1) == 0)\n        {\n            continue;\n        }\n        int param_5 = _1722;\n        vec4 _1742 = fa_light_texel(param_5);\n        int param_6 = _1722 + 1;\n        vec4 _1747 = fa_light_texel(param_6);\n        int param_7 = _1722 + 2;\n        vec4 _1752 = fa_light_texel(param_7);\n        vec3 _1755 = _1742.xyz;\n        float _1760 = dot(_1755, world_pos) + _1742.w;\n        vec3 _1762 = _1747.xyz;\n        float _1767 = dot(_1762, world_pos) + _1747.w;\n        vec3 _1769 = _1752.xyz;\n        float _1774 = dot(_1769, world_pos) + _1752.w;\n        bool _1779 = abs(_1760) > 0.5;\n        bool _1787;\n        if (!_1779)\n        {\n            _1787 = abs(_1767) > 0.5;\n        }\n        else\n        {\n            _1787 = _1779;\n        }\n        bool _1795;\n        if (!_1787)\n        {\n            _1795 = abs(_1774) > 0.5;\n        }\n        else\n        {\n            _1795 = _1787;\n        }\n        if (_1795)\n        {\n            continue;\n        }\n        float _1810 = clamp(dot(geo_normal, normalize(_1769)) * _1727.z, 0.0, 1.0);\n        if (_1810 <= 0.0)\n        {\n            continue;\n        }\n        float _1830 = (clamp((0.5 - abs(_1774)) * 10.0, 0.0, 1.0) * _1810) * _1727.x;\n        vec2 _1838 = vec2(_1760 + 0.5, 0.5 - _1767);\n        vec2 _1848 = vec2(dot(_1755, _1644), dot(_1762, _1644));\n        vec2 _1858 = vec2(dot(_1755, _1647), dot(_1762, _1647));\n        int param_8 = _1722 + 5;\n        vec4 _1863 = fa_light_texel(param_8);\n        int param_9 = _1722 + 3;\n        vec4 _1868 = fa_light_texel(param_9);\n        int param_10 = _1722 + 4;\n        vec4 _1873 = fa_light_texel(param_10);\n        float tex_a = 1.0;\n        vec3 col = _1863.xyz;\n        bool _1883 = _1868.z > _1868.x;\n        if (_1883)\n        {\n            vec4 param_11 = _1868;\n            vec2 param_12 = _1838;\n            vec2 param_13 = _1672;\n            vec2 param_14 = _1848;\n            vec2 param_15 = _1858;\n            vec4 tx = fa_decal_tile(param_11, param_12, param_13, param_14, param_15);\n            if ((_1682 > 0.5) && (_1682 < 1.5))\n            {\n                vec3 param_16 = tx.xyz;\n                vec3 _1909 = fa_dc_to_linear(param_16);\n                vec4 _6195 = tx;\n                _6195.x = _1909.x;\n                _6195.y = _1909.y;\n                _6195.z = _1909.z;\n                tx = _6195;\n            }\n            col *= tx.xyz;\n            tex_a = tx.w;\n        }\n        albedo = mix(albedo, col, vec3(clamp((_1830 * tex_a) * _1863.w, 0.0, 1.0)));\n        if (_1873.z > _1873.x)\n        {\n            vec4 param_17 = _1873;\n            vec2 param_18 = _1838;\n            vec2 param_19 = _1672;\n            vec2 param_20 = _1848;\n            vec2 param_21 = _1858;\n            vec4 _1953 = fa_decal_tile(param_17, param_18, param_19, param_20, param_21);\n            if (_1682 > 1.5)\n            {\n                vec3 param_22 = _1953.xyz;\n                vec3 _1963 = fa_dc_to_srgb(param_22);\n                _1957 = _1963;\n            }\n            else\n            {\n                _1957 = _1953.xyz;\n            }\n            vec3 _1972 = (_1957 * 2.0) - vec3(1.0);\n            vec2 _1977 = _1972.xy * _1727.y;\n            vec3 _1999 = (normalize(_1755) * _1977.x) + (normalize(_1762) * _1977.y);\n            vec3 _2002 = normalize(normal);\n            normal = normalize(mix(_2002, normalize((_2002 * max(_1972.z, 0.0500000007450580596923828125)) + (_1999 - (_2002 * dot(_2002, _1999)))), vec3(clamp(_1830 * (_1883 ? tex_a : 1.0), 0.0, 1.0))));\n        }\n    }\n}\n\nvec2 fa_atlas_size()\n{\n    return vec2(textureSize(fa_probe_atlas_fa_env_smp, 0));\n}\n\nvec3 fa_probe_sh_coef(vec2 origin, float res, int k)\n{\n    vec3 v = textureLod(fa_probe_atlas_fa_env_smp, (origin + vec2(float(k) + 0.5, res + 2.5)) / fa_atlas_size(), 0.0).xyz;\n    if (fa_mesh_fs_params[41].y > 0.5)\n    {\n        v = ((v * 255.0) - vec3(128.0)) * 0.03149606287479400634765625;\n    }\n    return v;\n}\n\nvec3 fa_sh_eval(vec3 c[9], vec3 n)\n{\n    vec3 _3674 = max((((c[0] * 0.2820948064327239990234375) + (((c[1] * (0.3257350027561187744140625 * n.y)) + (c[2] * (0.3257350027561187744140625 * n.z))) + (c[3] * (0.3257350027561187744140625 * n.x)))) + (((c[4] * ((0.2731371223926544189453125 * n.x) * n.y)) + (c[5] * ((0.2731371223926544189453125 * n.y) * n.z))) + (c[6] * (0.078847892582416534423828125 * (((3.0 * n.z) * n.z) - 1.0))))) + ((c[7] * ((0.2731371223926544189453125 * n.x) * n.z)) + (c[8] * (0.13656856119632720947265625 * ((n.x * n.x) - (n.y * n.y))))), vec3(0.0));\n    return _3674;\n}\n\nvec3 fa_ambient_light(vec3 n)\n{\n    float _3783 = (1.0 - fa_mesh_fs_params[42].w) - fa_mesh_fs_params[47].w;\n    vec3 amb = vec3(0.0);\n    bool _3789 = fa_mesh_fs_params[11].w > 0.5;\n    vec3 c[9];\n    for (int k = 0; k < 9; k++)\n    {\n        c[k] = vec3(0.0);\n    }\n    if (_3783 > 0.0005000000237487256526947021484375)\n    {\n        if (_3789)\n        {\n            for (int k_1 = 0; k_1 < 9; k_1++)\n            {\n                vec2 param = fa_mesh_fs_params[41].zw;\n                float param_1 = 128.0;\n                int param_2 = k_1;\n                c[k_1] = fa_probe_sh_coef(param, param_1, param_2) * _3783;\n            }\n        }\n        else\n        {\n            amb = fa_mesh_fs_params[1].xyz * _3783;\n        }\n    }\n    bool _3841 = fa_mesh_fs_params[42].w > 0.0;\n    if (_3841)\n    {\n        for (int k_2 = 0; k_2 < 9; k_2++)\n        {\n            vec2 param_3 = fa_mesh_fs_params[42].xy;\n            float param_4 = fa_mesh_fs_params[42].z;\n            int param_5 = k_2;\n            c[k_2] += (fa_probe_sh_coef(param_3, param_4, param_5) * fa_mesh_fs_params[42].w);\n        }\n    }\n    bool _3872 = fa_mesh_fs_params[47].w > 0.0;\n    if (_3872)\n    {\n        for (int k_3 = 0; k_3 < 9; k_3++)\n        {\n            vec2 param_6 = fa_mesh_fs_params[47].xy;\n            float param_7 = fa_mesh_fs_params[47].z;\n            int param_8 = k_3;\n            c[k_3] += (fa_probe_sh_coef(param_6, param_7, param_8) * fa_mesh_fs_params[47].w);\n        }\n    }\n    if ((_3789 || _3841) || _3872)\n    {\n        vec3 param_9[9] = c;\n        vec3 param_10 = n;\n        amb += fa_sh_eval(param_9, param_10);\n    }\n    return amb;\n}\n\nvec4 fa_gi_fetch(vec2 texel)\n{\n    return textureLod(fa_probe_atlas_fa_env_smp, texel / fa_atlas_size(), 0.0);\n}\n\nvec2 fa_oct_encode(vec3 d)\n{\n    vec3 _3694 = d / vec3(max((abs(d.x) + abs(d.y)) + abs(d.z), 9.9999999600419720025001879548654e-13));\n    float _3697 = _3694.x;\n    float _3699 = _3694.z;\n    vec2 e = vec2(_3697, _3699);\n    if (_3694.y < 0.0)\n    {\n        e = vec2((1.0 - abs(_3699)) * ((_3697 < 0.0) ? (-1.0) : 1.0), (1.0 - abs(_3697)) * ((_3699 < 0.0) ? (-1.0) : 1.0));\n    }\n    return e;\n}\n\nvec3 fa_gi_grid(int rec, vec3 n, vec3 v, out float cover)\n{\n    cover = 0.0;\n    int param = rec;\n    vec4 _4734 = fa_light_texel(param);\n    int param_1 = rec + 1;\n    vec4 _4739 = fa_light_texel(param_1);\n    int param_2 = rec + 2;\n    vec4 _4744 = fa_light_texel(param_2);\n    int param_3 = rec + 3;\n    vec4 _4749 = fa_light_texel(param_3);\n    bool _4752 = _4749.z < 0.5;\n    bool _4760;\n    if (!_4752)\n    {\n        _4760 = fa_atlas_size().y < 1155.0;\n    }\n    else\n    {\n        _4760 = _4752;\n    }\n    if (_4760)\n    {\n        return vec3(0.0);\n    }\n    float _4767 = max(_4734.w, 9.9999997473787516355514526367188e-05);\n    vec3 _4770 = _4739.xyz;\n    vec3 _4774 = _4734.xyz;\n    vec3 _4778 = (fa_world_pos - _4774) / vec3(_4767);\n    vec3 _4787 = min(_4778 + vec3(0.5), (_4770 - vec3(0.5)) - _4778);\n    float _4796 = min(_4787.x, min(_4787.y, _4787.z));\n    if (!(_4796 > 0.0))\n    {\n        return vec3(0.0);\n    }\n    vec3 _4811 = _4770 - vec3(1.0);\n    vec3 _4812 = clamp(_4778, vec3(0.0), _4811);\n    vec3 _4820 = min(floor(_4812), max(_4770 - vec3(2.0), vec3(0.0)));\n    vec3 _4824 = _4812 - _4820;\n    vec3 _4836 = fa_world_pos + (((n * 0.800000011920928955078125) + (v * 0.20000000298023223876953125)) * (0.20000000298023223876953125 * _4767));\n    int _4841 = int(_4744.y + 0.5);\n    float _4846 = 0.3257350027561187744140625 * n.y;\n    float _4850 = 0.3257350027561187744140625 * n.z;\n    float _4854 = 0.3257350027561187744140625 * n.x;\n    float _4861 = (0.2731371223926544189453125 * n.x) * n.y;\n    float _4868 = (0.2731371223926544189453125 * n.y) * n.z;\n    float _4877 = 0.078847892582416534423828125 * (((3.0 * n.z) * n.z) - 1.0);\n    float _4884 = (0.2731371223926544189453125 * n.x) * n.z;\n    float _4897 = 0.13656856119632720947265625 * ((n.x * n.x) - (n.y * n.y));\n    vec3 acc = vec3(0.0);\n    float wsum = 0.0;\n    int _4904 = 8 + int(_4749.w);\n    float _4931;\n    float _4944;\n    float _4958;\n    for (int k = 0; k < _4904; k++)\n    {\n        float _4917 = float(k & 1);\n        float _4921 = float((k >> 1) & 1);\n        float _4925 = float((k >> 2) & 1);\n        if (_4917 > 0.5)\n        {\n            _4931 = _4824.x;\n        }\n        else\n        {\n            _4931 = 1.0 - _4824.x;\n        }\n        if (_4921 > 0.5)\n        {\n            _4944 = _4824.y;\n        }\n        else\n        {\n            _4944 = 1.0 - _4824.y;\n        }\n        if (_4925 > 0.5)\n        {\n            _4958 = _4824.z;\n        }\n        else\n        {\n            _4958 = 1.0 - _4824.z;\n        }\n        float _4968 = (_4931 * _4944) * _4958;\n        if (!(_4968 > 0.0))\n        {\n            continue;\n        }\n        vec3 _4981 = min(_4820 + vec3(_4917, _4921, _4925), _4811);\n        int _5001 = int(((_4744.x + _4981.x) + (_4739.x * (_4981.y + (_4739.y * _4981.z)))) + 0.5);\n        vec2 _5016 = vec2(float(_5001 % _4841) * 10.0, 1024.0 + (float(_5001 / _4841) * 11.0));\n        vec2 param_4 = _5016 + vec2(9.5, 10.5);\n        vec4 _5024 = fa_gi_fetch(param_4);\n        bool _5027 = _5024.y < 0.5;\n        bool _5036;\n        if (!_5027)\n        {\n            _5036 = _5024.x > _4749.y;\n        }\n        else\n        {\n            _5036 = _5027;\n        }\n        if (_5036)\n        {\n            continue;\n        }\n        vec3 _5048 = _4836 - (_4774 + (_4981 * _4767));\n        float _5051 = length(_5048);\n        vec3 _5057 = _5048 / vec3(max(_5051, 9.9999997473787516355514526367188e-05));\n        float _5067 = max(9.9999997473787516355514526367188e-05, (dot(-_5057, n) + 1.0) * 0.5);\n        float w = _4968 * (_5067 * _5067);\n        vec3 param_5 = _5057;\n        vec2 param_6 = (_5016 + vec2(1.0)) + (((fa_oct_encode(param_5) * 0.5) + vec2(0.5)) * 8.0);\n        vec4 _5087 = fa_gi_fetch(param_6);\n        float _5094 = _5051 / max(_4744.z, 9.9999997473787516355514526367188e-05);\n        float _5097 = _5087.x;\n        if (_5094 > _5097)\n        {\n            float _5110 = max(_5087.y - (_5097 * _5097), 0.0);\n            float _5115 = _5094 - _5097;\n            float _5124 = _5110 / max(_5110 + (_5115 * _5115), 9.9999999600419720025001879548654e-13);\n            w *= ((_5124 * _5124) * _5124);\n        }\n        if (!(w > 0.0))\n        {\n            continue;\n        }\n        vec2 param_7 = _5016 + vec2(0.5, 10.5);\n        vec2 param_8 = _5016 + vec2(1.5, 10.5);\n        vec2 param_9 = _5016 + vec2(2.5, 10.5);\n        vec2 param_10 = _5016 + vec2(3.5, 10.5);\n        vec2 param_11 = _5016 + vec2(4.5, 10.5);\n        vec2 param_12 = _5016 + vec2(5.5, 10.5);\n        vec2 param_13 = _5016 + vec2(6.5, 10.5);\n        vec2 param_14 = _5016 + vec2(7.5, 10.5);\n        vec2 param_15 = _5016 + vec2(8.5, 10.5);\n        acc += ((((((((((fa_gi_fetch(param_7).xyz * 0.2820948064327239990234375) + (fa_gi_fetch(param_8).xyz * _4846)) + (fa_gi_fetch(param_9).xyz * _4850)) + (fa_gi_fetch(param_10).xyz * _4854)) + (fa_gi_fetch(param_11).xyz * _4861)) + (fa_gi_fetch(param_12).xyz * _4868)) + (fa_gi_fetch(param_13).xyz * _4877)) + (fa_gi_fetch(param_14).xyz * _4884)) + (fa_gi_fetch(param_15).xyz * _4897)) * w);\n        wsum += w;\n    }\n    if (!(wsum > 9.9999997473787516355514526367188e-06))\n    {\n        return vec3(0.0);\n    }\n    cover = smoothstep(0.0, 1.0, clamp(_4796 * 2.0, 0.0, 1.0)) * smoothstep(0.0, 0.0199999995529651641845703125, wsum);\n    float _5252;\n    if (fa_mesh_fs_params[52].z > 0.5)\n    {\n        _5252 = _4749.x;\n    }\n    else\n    {\n        _5252 = 1.0;\n    }\n    return max(acc / vec3(wsum), vec3(0.0)) * (_4744.w * _5252);\n}\n\nvec3 fa_gi_light(vec3 n, inout float left)\n{\n    left = 1.0;\n    vec3 acc = vec3(0.0);\n    vec3 _5276 = normalize(fa_mesh_fs_params[0].xyz - fa_world_pos);\n    int _5281 = int(fa_mesh_fs_params[52].x + 0.5);\n    int _5286 = int(fa_mesh_fs_params[52].y + 0.5);\n    float param_3;\n    for (int k = 0; (k < _5286) && (k < 8); k++)\n    {\n        int param = _5281 + (4 * k);\n        vec3 param_1 = n;\n        vec3 param_2 = _5276;\n        vec3 _5311 = fa_gi_grid(param, param_1, param_2, param_3);\n        float _5316 = param_3 * left;\n        acc += (_5311 * _5316);\n        left -= _5316;\n        if (left < 0.001000000047497451305389404296875)\n        {\n            left = 0.0;\n            break;\n        }\n    }\n    return acc;\n}\n\nvec3 fa_realtime_or_ambient(vec3 n)\n{\n    vec3 gi = vec3(0.0);\n    float left = 1.0;\n    if (fa_mesh_fs_params[52].y > 0.5)\n    {\n        vec3 param = n;\n        float param_1;\n        vec3 _5345 = fa_gi_light(param, param_1);\n        left = param_1;\n        gi = _5345;\n    }\n    if (left <= 0.0)\n    {\n        return gi;\n    }\n    vec3 param_2 = n;\n    return gi + (fa_ambient_light(param_2) * left);\n}\n\nvec3 fa_indirect_diffuse(vec3 n)\n{\n    if (fa_lm.z > 0.5)\n    {\n        return textureLod(fa_lightmap_fa_env_smp, fa_lm.xy, 0.0).xyz;\n    }\n    if (fa_mesh_fs_params[32].w > 0.0)\n    {\n        vec3 c[9];\n        for (int k = 0; k < 9; k++)\n        {\n            c[k] = fa_mesh_fs_params[k * 1 + 32].xyz;\n        }\n        vec3 param = n;\n        vec3 param_1[9] = c;\n        vec3 param_2 = n;\n        return mix(fa_ambient_light(param), fa_sh_eval(param_1, param_2), vec3(clamp(fa_mesh_fs_params[32].w, 0.0, 1.0)));\n    }\n    vec3 param_3 = n;\n    return fa_realtime_or_ambient(param_3);\n}\n\nvec3 ambient(SurfaceInput i, Surface s, vec3 ambientColor)\n{\n    return vec3(0.0, ambientColor.y, 0.0);\n}\n\nint fa_cluster_index(int slot, int n)\n{\n    int param = (int(fa_mesh_fs_params[19].x) + int(fa_mesh_fs_params[19].w)) + ((slot + n) >> 2);\n    vec4 t = fa_light_texel(param);\n    return int(t[(slot + n) & 3]);\n}\n\nint fa_cl_light(int n)\n{\n    if (n < fa_cl_ndir)\n    {\n        return n;\n    }\n    int param = fa_cl_slot;\n    int param_1 = n - fa_cl_ndir;\n    return fa_cluster_index(param, param_1);\n}\n\nint fa_light_base(int li)\n{\n    return li * ((fa_mesh_fs_params[1].w > 4.5) ? 8 : 4);\n}\n\nbool fa_light_baked(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 3;\n    return fa_light_texel(param_1).w > 0.5;\n}\n\nfloat fa_baked_keep(int li)\n{\n    float _4181;\n    if (fa_lm.z > 0.5)\n    {\n        _4181 = 0.0;\n    }\n    else\n    {\n        _4181 = 1.0 - clamp(fa_mesh_fs_params[32].w, 0.0, 1.0);\n    }\n    bool _4192 = _4181 < 1.0;\n    bool _4198;\n    if (_4192)\n    {\n        int param = li;\n        _4198 = fa_light_baked(param);\n    }\n    else\n    {\n        _4198 = _4192;\n    }\n    return _4198 ? _4181 : 1.0;\n}\n\nfloat fa_light_type(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 1;\n    return fa_light_texel(param_1).w;\n}\n\nvec3 fa_area_point(vec3 c, vec3 axis, vec3 ru, vec3 uu, float hx, float hy, float shape, vec3 p, vec3 r)\n{\n    bool _605 = dot(r, r) > 0.5;\n    if (shape > 1.5)\n    {\n        vec3 _618 = (c - (ru * hx)) - p;\n        vec3 _624 = ru * (2.0 * hx);\n        float _630 = max(dot(_624, _624), 9.9999999392252902907785028219223e-09);\n        float _634 = dot(_618, _624);\n        float t = clamp((-_634) / _630, 0.0, 1.0);\n        if (_605)\n        {\n            float _649 = dot(r, _624);\n            float _655 = _630 - (_649 * _649);\n            if (abs(_655) > (9.9999997473787516355514526367188e-06 * _630))\n            {\n                t = clamp(((dot(r, _618) * _649) - _634) / _655, 0.0, 1.0);\n            }\n        }\n        return (p + _618) + (_624 * t);\n    }\n    vec3 q = p;\n    float _687 = dot(r, axis);\n    bool _695;\n    if (_605)\n    {\n        _695 = abs(_687) > 9.9999997473787516355514526367188e-05;\n    }\n    else\n    {\n        _695 = _605;\n    }\n    if (_695)\n    {\n        float _705 = dot(c - p, axis) / _687;\n        if (_705 > 0.0)\n        {\n            q = p + (r * _705);\n        }\n    }\n    vec3 _718 = q - c;\n    vec2 xy = vec2(dot(_718, ru), dot(_718, uu));\n    if (shape > 0.5)\n    {\n        float _733 = length(xy);\n        if (_733 > hx)\n        {\n            xy *= (hx / _733);\n        }\n    }\n    else\n    {\n        xy = clamp(xy, vec2(-hx, -hy), vec2(hx, hy));\n    }\n    return (c + (ru * xy.x)) + (uu * xy.y);\n}\n\nvec4 fa_atlas_fetch(vec2 texel)\n{\n    return textureLod(fa_light_atlas_fa_env_smp, texel / vec2(textureSize(fa_light_atlas_fa_env_smp, 0)), 0.0);\n}\n\nvec3 fa_cookie_sample(vec2 tile_origin, vec2 uv)\n{\n    vec2 param = (tile_origin + vec2(1.0)) + (clamp(uv, vec2(0.0), vec2(1.0)) * 254.0);\n    return fa_atlas_fetch(param).xyz;\n}\n\nfloat fa_ies_sample(vec2 tile_origin, vec3 d, vec3 axis, vec3 right, vec3 up)\n{\n    float _525 = dot(d, right);\n    float _529 = dot(d, up);\n    float _540;\n    if (((_525 * _525) + (_529 * _529)) > 1.0000000133514319600180897396058e-10)\n    {\n        _540 = atan(_529, _525) * 0.15915493667125701904296875;\n    }\n    else\n    {\n        _540 = 0.0;\n    }\n    vec2 param = tile_origin + vec2(1.0 + ((_540 - floor(_540)) * 64.0), 1.0 + (acos(clamp(dot(d, axis), -1.0, 1.0)) * 10.18591594696044921875));\n    return fa_atlas_fetch(param).x;\n}\n\nint fa_cube_face(vec3 d)\n{\n    vec3 _375 = abs(d);\n    float _377 = _375.x;\n    float _379 = _375.y;\n    bool _380 = _377 >= _379;\n    bool _388;\n    if (_380)\n    {\n        _388 = _377 >= _375.z;\n    }\n    else\n    {\n        _388 = _380;\n    }\n    int _389;\n    if (_388)\n    {\n        _389 = (d.x > 0.0) ? 0 : 1;\n    }\n    else\n    {\n        int _404;\n        if (_379 >= _375.z)\n        {\n            _404 = (d.y > 0.0) ? 2 : 3;\n        }\n        else\n        {\n            _404 = (d.z > 0.0) ? 4 : 5;\n        }\n        _389 = _404;\n    }\n    return _389;\n}\n\nvoid fa_cube_face_basis(int f, out vec3 fwd, out vec3 up)\n{\n    if (f == 0)\n    {\n        fwd = vec3(1.0, 0.0, 0.0);\n        up = vec3(0.0, 1.0, 0.0);\n    }\n    else\n    {\n        if (f == 1)\n        {\n            fwd = vec3(-1.0, 0.0, 0.0);\n            up = vec3(0.0, 1.0, 0.0);\n        }\n        else\n        {\n            if (f == 2)\n            {\n                fwd = vec3(0.0, 1.0, 0.0);\n                up = vec3(0.0, 0.0, 1.0);\n            }\n            else\n            {\n                if (f == 3)\n                {\n                    fwd = vec3(0.0, -1.0, 0.0);\n                    up = vec3(0.0, 0.0, -1.0);\n                }\n                else\n                {\n                    if (f == 4)\n                    {\n                        fwd = vec3(0.0, 0.0, 1.0);\n                        up = vec3(0.0, 1.0, 0.0);\n                    }\n                    else\n                    {\n                        fwd = vec3(0.0, 0.0, -1.0);\n                        up = vec3(0.0, 1.0, 0.0);\n                    }\n                }\n            }\n        }\n    }\n}\n\nLightSample fa_light_sample_n(int li, vec3 world_pos, vec3 n)\n{\n    int param = li;\n    int _771 = fa_light_base(param);\n    bool _775 = fa_mesh_fs_params[1].w > 4.5;\n    int param_1 = _771;\n    vec4 _779 = fa_light_texel(param_1);\n    int param_2 = _771 + 1;\n    vec4 _784 = fa_light_texel(param_2);\n    float _787 = _784.w;\n    float atten = 1.0;\n    float dist = 0.0;\n    fa_light_tint = vec3(1.0);\n    bool _799 = _775 && (_787 > 2.5);\n    fa_light_is_area = _799;\n    bool _801 = _787 < 0.5;\n    vec3 l;\n    if (_801)\n    {\n        l = normalize(_779.xyz);\n        if (_775)\n        {\n            int param_3 = _771 + 6;\n            vec4 _815 = fa_light_texel(param_3);\n            if (_815.z > 0.5)\n            {\n                int param_4 = _771 + 4;\n                vec4 _825 = fa_light_texel(param_4);\n                int param_5 = _771 + 5;\n                vec4 _830 = fa_light_texel(param_5);\n                vec2 param_6 = _815.xy;\n                vec2 param_7 = fract(vec2(dot(world_pos, _825.xyz) * _825.w, (-dot(world_pos, _830.xyz)) * _830.w) + vec2(0.5));\n                fa_light_tint = fa_cookie_sample(param_6, param_7);\n            }\n        }\n    }\n    else\n    {\n        vec3 _860 = _779.xyz;\n        vec3 _862 = _860 - world_pos;\n        vec3 to_light = _862;\n        float _865 = length(_862);\n        float reach = _865;\n        bool front = true;\n        if (_799)\n        {\n            int param_8 = _771 + 7;\n            reach = max(_865 - fa_light_texel(param_8).w, 0.0);\n            int param_9 = _771 + 4;\n            vec4 _889 = fa_light_texel(param_9);\n            int param_10 = _771 + 5;\n            vec4 _894 = fa_light_texel(param_10);\n            int param_11 = _771 + 6;\n            vec4 _899 = fa_light_texel(param_11);\n            float _900 = _899.w;\n            int param_12 = _771 + 2;\n            vec3 _907 = normalize(fa_light_texel(param_12).xyz);\n            bool _909 = _900 > 1.5;\n            bool _917;\n            if (!_909)\n            {\n                _917 = dot(_907, to_light) < 0.0;\n            }\n            else\n            {\n                _917 = _909;\n            }\n            front = _917;\n            vec3 r = vec3(0.0);\n            vec3 _926 = fa_mesh_fs_params[0].xyz - world_pos;\n            bool _930 = dot(n, n) > 0.5;\n            bool _938;\n            if (_930)\n            {\n                _938 = dot(_926, _926) > 9.9999999600419720025001879548654e-13;\n            }\n            else\n            {\n                _938 = _930;\n            }\n            if (_938)\n            {\n                r = reflect(-normalize(_926), normalize(n));\n            }\n            vec3 param_13 = _860;\n            vec3 param_14 = _907;\n            vec3 param_15 = _889.xyz;\n            vec3 param_16 = _894.xyz;\n            float param_17 = _889.w;\n            float param_18 = _894.w;\n            float param_19 = _900;\n            vec3 param_20 = world_pos;\n            vec3 param_21 = r;\n            to_light = fa_area_point(param_13, param_14, param_15, param_16, param_17, param_18, param_19, param_20, param_21) - world_pos;\n        }\n        float _974 = length(to_light);\n        dist = _974;\n        l = to_light / vec3(max(_974, 9.9999997473787516355514526367188e-05));\n        float _988 = reach / max(_779.w, 0.001000000047497451305389404296875);\n        float _994 = clamp(1.0 - (_988 * _988), 0.0, 1.0);\n        float _996;\n        if (front)\n        {\n            _996 = _994 * _994;\n        }\n        else\n        {\n            _996 = 0.0;\n        }\n        atten = _996;\n        bool _1007 = _787 < 2.5;\n        if ((_787 > 1.5) && _1007)\n        {\n            int param_22 = _771 + 2;\n            vec4 _1015 = fa_light_texel(param_22);\n            float _1025 = _1015.w;\n            int param_23 = _771 + 3;\n            vec4 _1030 = fa_light_texel(param_23);\n            float _1031 = _1030.x;\n            float cos_inner = _1031;\n            if (_1031 > 1.5)\n            {\n                cos_inner = mix(_1025, 1.0, 0.25);\n            }\n            atten *= smoothstep(_1025, cos_inner, dot(-l, normalize(_1015.xyz)));\n        }\n        if (_775 && (_787 < 1.5))\n        {\n            int param_24 = _771 + 6;\n            vec4 _1055 = fa_light_texel(param_24);\n            if (_1055.z > 0.5)\n            {\n                vec3 _1063 = -to_light;\n                int param_25 = _771 + 4;\n                int param_26 = _771 + 5;\n                vec3 _1077 = fa_light_texel(param_25).xyz;\n                vec3 _1081 = fa_light_texel(param_26).xyz;\n                vec3 _1090 = vec3(dot(_1063, _1077), dot(_1063, _1081), dot(_1063, cross(_1077, _1081)));\n                vec3 param_27 = _1090;\n                int _1094 = fa_cube_face(param_27);\n                int param_28 = _1094;\n                vec3 param_29;\n                vec3 param_30;\n                fa_cube_face_basis(param_28, param_29, param_30);\n                vec2 _1121 = vec2(dot(_1090, cross(param_29, param_30)), dot(_1090, param_30)) / vec2(max(dot(_1090, param_29), 9.9999997473787516355514526367188e-05));\n                int _1125 = _1094 / 3;\n                vec2 param_31 = _1055.xy + (vec2(float(_1094 - (_1125 * 3)), float(_1125)) * 256.0);\n                vec2 param_32 = vec2(0.5 + (0.5 * _1121.x), 0.5 - (0.5 * _1121.y));\n                fa_light_tint = fa_cookie_sample(param_31, param_32);\n            }\n            int param_33 = _771 + 7;\n            vec4 _1155 = fa_light_texel(param_33);\n            if (_1155.z > 0.5)\n            {\n                int param_34 = _771 + 2;\n                int param_35 = _771 + 4;\n                int param_36 = _771 + 5;\n                vec2 param_37 = _1155.xy;\n                vec3 param_38 = -l;\n                vec3 param_39 = normalize(fa_light_texel(param_34).xyz);\n                vec3 param_40 = fa_light_texel(param_35).xyz;\n                vec3 param_41 = fa_light_texel(param_36).xyz;\n                atten *= fa_ies_sample(param_37, param_38, param_39, param_40, param_41);\n            }\n        }\n        else\n        {\n            if (_775 && _1007)\n            {\n                int param_42 = _771 + 6;\n                vec4 _1202 = fa_light_texel(param_42);\n                int param_43 = _771 + 7;\n                vec4 _1207 = fa_light_texel(param_43);\n                bool _1210 = _1202.z > 0.5;\n                bool _1217;\n                if (!_1210)\n                {\n                    _1217 = _1207.z > 0.5;\n                }\n                else\n                {\n                    _1217 = _1210;\n                }\n                if (_1217)\n                {\n                    int param_44 = _771 + 2;\n                    vec4 _1224 = fa_light_texel(param_44);\n                    vec3 _1228 = normalize(_1224.xyz);\n                    int param_45 = _771 + 4;\n                    vec4 _1233 = fa_light_texel(param_45);\n                    int param_46 = _771 + 5;\n                    vec4 _1238 = fa_light_texel(param_46);\n                    if (_1210)\n                    {\n                        vec3 _1246 = -to_light;\n                        float _1253 = _1224.w;\n                        float _1269 = 0.5 / max(dot(_1246, _1228) * (sqrt(max(1.0 - (_1253 * _1253), 0.0)) / max(_1253, 0.001000000047497451305389404296875)), 9.9999997473787516355514526367188e-05);\n                        vec2 param_47 = _1202.xy;\n                        vec2 param_48 = vec2(0.5 + (dot(_1246, _1233.xyz) * _1269), 0.5 - (dot(_1246, _1238.xyz) * _1269));\n                        fa_light_tint = fa_cookie_sample(param_47, param_48);\n                    }\n                    if (_1207.z > 0.5)\n                    {\n                        vec2 param_49 = _1207.xy;\n                        vec3 param_50 = -l;\n                        vec3 param_51 = _1228;\n                        vec3 param_52 = _1233.xyz;\n                        vec3 param_53 = _1238.xyz;\n                        atten *= fa_ies_sample(param_49, param_50, param_51, param_52, param_53);\n                    }\n                }\n            }\n        }\n    }\n    vec3 _6061 = _784.xyz * atten;\n    if (_775)\n    {\n        _6061 *= fa_light_tint;\n    }\n    int _1337;\n    if (_801)\n    {\n        _1337 = 0;\n    }\n    else\n    {\n        _1337 = ((_787 > 1.5) && (_787 < 2.5)) ? 2 : 1;\n    }\n    return LightSample(l, _6061, atten, 1.0, dist, _1337);\n}\n\nfloat fa_shadow_depth(inout vec2 uv, vec4 rect)\n{\n    uv = clamp(uv, rect.xy, rect.zw);\n    return textureLod(fa_shadow_tex_fa_shadow_smp, uv, 0.0).x;\n}\n\nfloat fa_shadow_fetch(vec2 uv, vec4 rect, vec3 conv)\n{\n    vec2 param = uv;\n    vec4 param_1 = rect;\n    float _2126 = fa_shadow_depth(param, param_1);\n    float _2130;\n    if (conv.x < 0.5)\n    {\n        _2130 = _2126;\n    }\n    else\n    {\n        _2130 = (conv.y * conv.z) / (conv.z - (_2126 * (conv.z - conv.y)));\n    }\n    return _2130;\n}\n\nfloat fa_shadow_noise()\n{\n    return fract(52.98291778564453125 * fract(dot(gl_FragCoord.xy, vec2(0.067110560834407806396484375, 0.005837149918079376220703125))));\n}\n\nvec2 fa_shadow_vogel_turn(vec2 d)\n{\n    return vec2((d.x * (-0.737368881702423095703125)) - (d.y * 0.675490319728851318359375), (d.y * (-0.737368881702423095703125)) + (d.x * 0.675490319728851318359375));\n}\n\nfloat fa_shadow_filter(vec2 uv, vec4 rect, float zr, float texel_m, float unit, float reach, float plane, vec3 conv, int mode, float k)\n{\n    if (mode == 1)\n    {\n        vec2 param = uv;\n        vec4 param_1 = rect;\n        vec3 param_2 = conv;\n        return float(zr <= fa_shadow_fetch(param, param_1, param_2));\n    }\n    float _2176 = fa_shadow_noise() * 6.283185482025146484375;\n    vec2 _2182 = vec2(cos(_2176), sin(_2176));\n    vec2 dir = _2182;\n    float radius = 1.5;\n    if (mode == 2)\n    {\n        float _2191;\n        if (k < 0.0)\n        {\n            _2191 = (-k) / max(zr, 0.100000001490116119384765625);\n        }\n        else\n        {\n            _2191 = k;\n        }\n        float _2210 = clamp((_2191 * reach) / texel_m, 3.0, 12.0);\n        float sum = 0.0;\n        float cnt = 0.0;\n        for (int i = 0; i < 16; i++)\n        {\n            float _2229 = sqrt((float(i) + 0.5) * 0.0625) * _2210;\n            vec2 param_3 = uv + (dir * (fa_shadows[26].zw * _2229));\n            vec4 param_4 = rect;\n            vec3 param_5 = conv;\n            float _2243 = fa_shadow_fetch(param_3, param_4, param_5);\n            if (_2243 < (zr - (_2229 * plane)))\n            {\n                sum += _2243;\n                cnt += 1.0;\n            }\n            vec2 param_6 = dir;\n            dir = fa_shadow_vogel_turn(param_6);\n        }\n        if (cnt < 0.5)\n        {\n            return 1.0;\n        }\n        float _2271 = sum / cnt;\n        float _2281;\n        if (k < 0.0)\n        {\n            _2281 = (-k) / max(_2271, 0.0500000007450580596923828125);\n        }\n        else\n        {\n            _2281 = k;\n        }\n        radius = clamp(((max(zr - _2271, 0.0) * unit) * _2281) / texel_m, 1.5, 16.0);\n        dir = _2182;\n    }\n    float lit = 0.0;\n    int _2307 = (mode == 2) ? 24 : 16;\n    for (int i_1 = 0; i_1 < _2307; i_1++)\n    {\n        float _2326 = sqrt((float(i_1) + 0.5) / float(_2307)) * radius;\n        vec2 param_7 = uv + (dir * (fa_shadows[26].zw * _2326));\n        vec4 param_8 = rect;\n        vec3 param_9 = conv;\n        lit += float((zr - (_2326 * plane)) <= fa_shadow_fetch(param_7, param_8, param_9));\n        vec2 param_10 = dir;\n        dir = fa_shadow_vogel_turn(param_10);\n    }\n    return lit / float(_2307);\n}\n\nfloat fa_shadow_local(int li, vec3 lpos, vec3 world, vec3 n, vec3 l)\n{\n    bool _2531 = fa_mesh_fs_params[5].z < 0.5;\n    bool _2538;\n    if (!_2531)\n    {\n        _2538 = fa_shadows[29].x < 0.5;\n    }\n    else\n    {\n        _2538 = _2531;\n    }\n    if (_2538)\n    {\n        return 1.0;\n    }\n    int param = (int(fa_shadows[29].x + 0.5) - 1) + li;\n    vec4 _2551 = fa_light_texel(param);\n    float _2552 = _2551.x;\n    if (_2552 < 0.0)\n    {\n        return 1.0;\n    }\n    int _2561 = int(_2552 + 0.5);\n    int param_1 = _2561;\n    vec4 _2565 = fa_light_texel(param_1);\n    int param_2 = _2561 + 1;\n    vec4 _2570 = fa_light_texel(param_2);\n    float fade = 1.0;\n    float _2573 = _2565.y;\n    if (_2573 > 0.0)\n    {\n        float _2590 = 1.0 - smoothstep(0.75 * _2573, _2573, length(world - fa_shadows[27].xyz));\n        fade = _2590;\n        if (_2590 <= 0.0)\n        {\n            return 1.0;\n        }\n    }\n    int face = 0;\n    if (_2565.x > 1.5)\n    {\n        vec3 param_3 = world - lpos;\n        face = fa_cube_face(param_3);\n    }\n    int _2614 = (_2561 + 2) + (face * 6);\n    int param_4 = _2614;\n    int param_5 = _2614 + 1;\n    int param_6 = _2614 + 3;\n    vec4 _2628 = fa_light_texel(param_6);\n    int param_7 = _2614 + 4;\n    vec4 _2633 = fa_light_texel(param_7);\n    int param_8 = _2614 + 5;\n    vec4 _2638 = fa_light_texel(param_8);\n    float _2650 = _2638.x * max(dot(_2628, vec4(world, 1.0)), 0.001000000047497451305389404296875);\n    float _2655 = clamp(dot(n, l), 0.0, 1.0);\n    float _2678 = clamp(dot(n, _2628.xyz), -1.0, 1.0);\n    float _2697 = min(sqrt(1.0 - (_2678 * _2678)) / max(abs(dot(n, world - lpos)) / max(dot(_2628, vec4(world, 1.0)), 0.001000000047497451305389404296875), 0.20000000298023223876953125), 4.0);\n    float _2700 = _2570.y;\n    float _2702;\n    if (_2700 > 0.0)\n    {\n        _2702 = _2700;\n    }\n    else\n    {\n        _2702 = 1.5 * _2650;\n    }\n    vec4 _2722 = vec4(world + (n * (_2702 * sqrt(1.0 - (_2655 * _2655)))), 1.0);\n    float _2726 = dot(_2628, _2722);\n    float _2729 = _2638.y;\n    if (_2726 < _2729)\n    {\n        return 1.0;\n    }\n    vec2 _2744 = vec2(dot(fa_light_texel(param_4), _2722), dot(fa_light_texel(param_5), _2722)) / vec2(_2726);\n    float _2746 = _2744.x;\n    bool _2749 = _2746 < _2633.x;\n    bool _2758;\n    if (!_2749)\n    {\n        _2758 = _2746 > _2633.z;\n    }\n    else\n    {\n        _2758 = _2749;\n    }\n    bool _2767;\n    if (!_2758)\n    {\n        _2767 = _2744.y < _2633.y;\n    }\n    else\n    {\n        _2767 = _2758;\n    }\n    bool _2776;\n    if (!_2767)\n    {\n        _2776 = _2744.y > _2633.w;\n    }\n    else\n    {\n        _2776 = _2767;\n    }\n    if (_2776)\n    {\n        return 1.0;\n    }\n    float _2782 = _2570.x;\n    float _2784;\n    if (_2782 > 0.0)\n    {\n        _2784 = _2782;\n    }\n    else\n    {\n        _2784 = 1.5 * _2650;\n    }\n    vec2 param_9 = _2744;\n    vec4 param_10 = _2633;\n    float param_11 = _2726 - (_2784 * (1.0 + (0.5 * _2697)));\n    float param_12 = _2650;\n    float param_13 = 1.0;\n    float param_14 = _2638.z * 0.25;\n    float param_15 = (_2650 * min(_2697, 3.0)) * 0.5;\n    vec3 param_16 = vec3(1.0, _2729, _2638.z);\n    int param_17 = int(_2565.z + 0.5);\n    float param_18 = _2565.w;\n    return mix(1.0, fa_shadow_filter(param_9, param_10, param_11, param_12, param_13, param_14, param_15, param_16, param_17, param_18), fade);\n}\n\nfloat fa_shadow_local_rt(int li, vec3 lpos, vec3 world, vec3 n, vec3 l)\n{\n    bool _3296 = fa_mesh_fs_params[25].w > 0.5;\n    bool _3302;\n    if (_3296)\n    {\n        _3302 = fa_mesh_fs_params[5].z > 0.5;\n    }\n    else\n    {\n        _3302 = _3296;\n    }\n    bool _3308;\n    if (_3302)\n    {\n        _3308 = fa_shadows[29].x > 0.5;\n    }\n    else\n    {\n        _3308 = _3302;\n    }\n    if (_3308)\n    {\n        int param = (int(fa_shadows[29].x + 0.5) - 1) + li;\n        vec4 _3320 = fa_light_texel(param);\n        float _3321 = _3320.z;\n        if (_3321 > 0.5)\n        {\n            float _3334 = dot(fa_mesh_fs_params[29].xyz, world) + fa_mesh_fs_params[29].w;\n            float _3337 = fwidth(_3334);\n            float _3341 = min(1.5 * _3337, 0.100000001490116119384765625 * _3334);\n            vec4 _3347 = vec4(world, 1.0);\n            float _3352 = dot(fa_mesh_fs_params[28], _3347);\n            if (_3352 > 9.9999997473787516355514526367188e-05)\n            {\n                vec2 _3369 = vec2(dot(fa_mesh_fs_params[26], _3347), dot(fa_mesh_fs_params[27], _3347)) / vec2(_3352);\n                float _3374 = (_3369.x * 0.5) + 0.5;\n                float _3378;\n                if (fa_mesh_fs_params[24].y > 0.5)\n                {\n                    _3378 = (_3369.y * 0.5) + 0.5;\n                }\n                else\n                {\n                    _3378 = 0.5 - (_3369.y * 0.5);\n                }\n                bool _3394 = _3374 >= 0.0;\n                bool _3400;\n                if (_3394)\n                {\n                    _3400 = _3374 < 1.0;\n                }\n                else\n                {\n                    _3400 = _3394;\n                }\n                bool _3406;\n                if (_3400)\n                {\n                    _3406 = _3378 >= 0.0;\n                }\n                else\n                {\n                    _3406 = _3400;\n                }\n                bool _3412;\n                if (_3406)\n                {\n                    _3412 = _3378 < 1.0;\n                }\n                else\n                {\n                    _3412 = _3406;\n                }\n                if (_3412)\n                {\n                    ivec2 _3429 = ivec2(fa_mesh_fs_params[24].zw) - ivec2(1);\n                    ivec2 _3430 = clamp(ivec2(vec2(_3374, _3378) * fa_mesh_fs_params[24].zw), ivec2(0), _3429);\n                    ivec2 _3442;\n                    ivec2 _3448;\n                    ivec2 _3455;\n                    float _3506;\n                    float _3527;\n                    for (int k = 0; k < 5; k++)\n                    {\n                        if (k == 0)\n                        {\n                            _3442 = ivec2(0);\n                        }\n                        else\n                        {\n                            if (k == 1)\n                            {\n                                _3448 = ivec2(1, 0);\n                            }\n                            else\n                            {\n                                if (k == 2)\n                                {\n                                    _3455 = ivec2(-1, 0);\n                                }\n                                else\n                                {\n                                    bvec2 _3466 = bvec2(k == 3);\n                                    _3455 = ivec2(_3466.x ? ivec2(0, 1).x : ivec2(0, -1).x, _3466.y ? ivec2(0, 1).y : ivec2(0, -1).y);\n                                }\n                                _3448 = _3455;\n                            }\n                            _3442 = _3448;\n                        }\n                        vec4 _3483 = texelFetch(fa_screen_tex_fa_shadow_smp, clamp(_3430 + _3442, ivec2(0), _3429), 0);\n                        bool _3486 = _3483.w > 0.5;\n                        bool _3500;\n                        if (_3486)\n                        {\n                            _3500 = abs(_3334 - _3483.x) <= (((0.00200000009499490261077880859375 * _3334) + 0.00999999977648258209228515625) + _3341);\n                        }\n                        else\n                        {\n                            _3500 = _3486;\n                        }\n                        if (_3500)\n                        {\n                            if (_3321 < 1.5)\n                            {\n                                _3506 = 1.0;\n                            }\n                            else\n                            {\n                                _3506 = (_3321 < 2.5) ? 256.0 : 65536.0;\n                            }\n                            float _3523 = mod(floor(_3483.z / _3506), 256.0) * 0.0039215688593685626983642578125;\n                            if (fa_mesh_fs_params[25].z > 0.5)\n                            {\n                                int param_1 = li;\n                                vec3 param_2 = lpos;\n                                vec3 param_3 = world;\n                                vec3 param_4 = n;\n                                vec3 param_5 = l;\n                                _3527 = min(_3523, fa_shadow_local(param_1, param_2, param_3, param_4, param_5));\n                            }\n                            else\n                            {\n                                _3527 = _3523;\n                            }\n                            return _3527;\n                        }\n                    }\n                }\n            }\n            float _3552;\n            if (fa_mesh_fs_params[25].z > 0.5)\n            {\n                int param_6 = li;\n                vec3 param_7 = lpos;\n                vec3 param_8 = world;\n                vec3 param_9 = n;\n                vec3 param_10 = l;\n                _3552 = fa_shadow_local(param_6, param_7, param_8, param_9, param_10);\n            }\n            else\n            {\n                _3552 = 1.0;\n            }\n            return _3552;\n        }\n    }\n    int param_11 = li;\n    vec3 param_12 = lpos;\n    vec3 param_13 = world;\n    vec3 param_14 = n;\n    vec3 param_15 = l;\n    return fa_shadow_local(param_11, param_12, param_13, param_14, param_15);\n}\n\nfloat fa_shadow_split_at(int i)\n{\n    float _2069;\n    if (i == 0)\n    {\n        _2069 = fa_shadows[24].x;\n    }\n    else\n    {\n        float _2085;\n        if (i == 1)\n        {\n            _2085 = fa_shadows[24].y;\n        }\n        else\n        {\n            float _2093;\n            if (i == 2)\n            {\n                _2093 = fa_shadows[24].z;\n            }\n            else\n            {\n                _2093 = fa_shadows[24].w;\n            }\n            _2085 = _2093;\n        }\n        _2069 = _2085;\n    }\n    return _2069;\n}\n\nfloat fa_shadow_cascade(int ci, vec3 world, vec3 n, vec3 l)\n{\n    float _2372 = max(fa_shadows[ci * 1 + 20].y, 0.001000000047497451305389404296875);\n    float _2377 = clamp(dot(n, l), 0.0, 1.0);\n    float _2383 = sqrt(1.0 - (_2377 * _2377));\n    float _2391 = min(_2383 / max(_2377, 0.20000000298023223876953125), 4.0);\n    float _2396;\n    if (fa_shadows[26].y > 0.0)\n    {\n        _2396 = fa_shadows[26].y;\n    }\n    else\n    {\n        _2396 = 1.5 * fa_shadows[ci * 1 + 20].x;\n    }\n    vec4 _2421 = mat4(fa_shadows[ci * 4 + 0], fa_shadows[ci * 4 + 1], fa_shadows[ci * 4 + 2], fa_shadows[ci * 4 + 3]) * vec4(world + (n * (_2396 * _2383)), 1.0);\n    float _2428 = _2421.x;\n    bool _2431 = _2428 < fa_shadows[ci * 1 + 16].x;\n    bool _2440;\n    if (!_2431)\n    {\n        _2440 = _2428 > fa_shadows[ci * 1 + 16].z;\n    }\n    else\n    {\n        _2440 = _2431;\n    }\n    bool _2449;\n    if (!_2440)\n    {\n        _2449 = _2421.y < fa_shadows[ci * 1 + 16].y;\n    }\n    else\n    {\n        _2449 = _2440;\n    }\n    bool _2458;\n    if (!_2449)\n    {\n        _2458 = _2421.y > fa_shadows[ci * 1 + 16].w;\n    }\n    else\n    {\n        _2458 = _2449;\n    }\n    bool _2465;\n    if (!_2458)\n    {\n        _2465 = _2421.z > 1.0;\n    }\n    else\n    {\n        _2465 = _2458;\n    }\n    if (_2465)\n    {\n        return -1.0;\n    }\n    float _2473;\n    if (fa_shadows[26].x > 0.0)\n    {\n        _2473 = fa_shadows[26].x;\n    }\n    else\n    {\n        _2473 = 1.5 * fa_shadows[ci * 1 + 20].x;\n    }\n    vec2 param = _2421.xy;\n    vec4 param_1 = fa_shadows[ci * 1 + 16];\n    float param_2 = _2421.z - ((_2473 * (1.0 + (0.5 * _2391))) / _2372);\n    float param_3 = fa_shadows[ci * 1 + 20].x;\n    float param_4 = _2372;\n    float param_5 = _2372 * 0.25;\n    float param_6 = ((fa_shadows[ci * 1 + 20].x * min(_2391, 3.0)) * 0.5) / _2372;\n    vec3 param_7 = vec3(0.0);\n    int param_8 = int(fa_shadows[25].z + 0.5);\n    float param_9 = fa_shadows[25].w;\n    return fa_shadow_filter(param, param_1, param_2, param_3, param_4, param_5, param_6, param_7, param_8, param_9);\n}\n\nfloat fa_shadow_sun(vec3 world, vec3 n, vec3 l)\n{\n    if (fa_mesh_fs_params[5].z < 0.5)\n    {\n        return 1.0;\n    }\n    int _2851 = int(fa_shadows[25].x + 0.5);\n    if (_2851 < 1)\n    {\n        return 1.0;\n    }\n    float _2866 = dot(world - fa_shadows[27].xyz, fa_shadows[28].xyz);\n    int param = _2851 - 1;\n    if (_2866 > fa_shadow_split_at(param))\n    {\n        return 1.0;\n    }\n    int ci = 0;\n    bool _2878 = _2851 > 1;\n    bool _2885;\n    if (_2878)\n    {\n        _2885 = _2866 > fa_shadows[24].x;\n    }\n    else\n    {\n        _2885 = _2878;\n    }\n    if (_2885)\n    {\n        ci = 1;\n    }\n    bool _2889 = _2851 > 2;\n    bool _2896;\n    if (_2889)\n    {\n        _2896 = _2866 > fa_shadows[24].y;\n    }\n    else\n    {\n        _2896 = _2889;\n    }\n    if (_2896)\n    {\n        ci = 2;\n    }\n    bool _2900 = _2851 > 3;\n    bool _2907;\n    if (_2900)\n    {\n        _2907 = _2866 > fa_shadows[24].z;\n    }\n    else\n    {\n        _2907 = _2900;\n    }\n    if (_2907)\n    {\n        ci = 3;\n    }\n    float s = -1.0;\n    float s2 = -1.0;\n    float t = 0.0;\n    int _2918 = min(_2851, 4);\n    float _2959;\n    for (int c = ci; c < _2918; c++)\n    {\n        int param_1 = c;\n        vec3 param_2 = world;\n        vec3 param_3 = n;\n        vec3 param_4 = l;\n        float _2938 = fa_shadow_cascade(param_1, param_2, param_3, param_4);\n        if (s >= 0.0)\n        {\n            s2 = _2938;\n            break;\n        }\n        if (_2938 < 0.0)\n        {\n            continue;\n        }\n        s = _2938;\n        ci = c;\n        if (fa_shadows[25].y > 0.0)\n        {\n            if (ci > 0)\n            {\n                int param_5 = ci - 1;\n                _2959 = fa_shadow_split_at(param_5);\n            }\n            else\n            {\n                _2959 = fa_shadows[28].w;\n            }\n            int param_6 = ci;\n            float _2978 = fa_shadows[25].y * max(fa_shadow_split_at(param_6) - _2959, 9.9999997473787516355514526367188e-05);\n            int param_7 = ci;\n            t = clamp((_2866 - (fa_shadow_split_at(param_7) - _2978)) / _2978, 0.0, 1.0);\n        }\n        if (t <= 0.0)\n        {\n            break;\n        }\n    }\n    if (s < 0.0)\n    {\n        return 1.0;\n    }\n    if (t > 0.0)\n    {\n        float _3010;\n        if ((ci + 1) < _2851)\n        {\n            _3010 = (s2 < 0.0) ? s : s2;\n        }\n        else\n        {\n            _3010 = 1.0;\n        }\n        s = mix(s, _3010, t);\n    }\n    return s;\n}\n\nfloat fa_shadow_factor(vec3 n, vec3 l)\n{\n    bool _3115 = fa_mesh_fs_params[25].y > 0.5;\n    bool _3121;\n    if (_3115)\n    {\n        _3121 = fa_mesh_fs_params[5].z > 0.5;\n    }\n    else\n    {\n        _3121 = _3115;\n    }\n    if (_3121)\n    {\n        float _3135 = dot(fa_mesh_fs_params[29].xyz, fa_world_pos) + fa_mesh_fs_params[29].w;\n        float _3138 = fwidth(_3135);\n        vec4 _3148 = vec4(fa_world_pos, 1.0);\n        float _3154 = dot(fa_mesh_fs_params[28], _3148);\n        if (_3154 > 9.9999997473787516355514526367188e-05)\n        {\n            vec2 _3173 = vec2(dot(fa_mesh_fs_params[26], _3148), dot(fa_mesh_fs_params[27], _3148)) / vec2(_3154);\n            float _3178 = (_3173.x * 0.5) + 0.5;\n            float _3182;\n            if (fa_mesh_fs_params[24].y > 0.5)\n            {\n                _3182 = (_3173.y * 0.5) + 0.5;\n            }\n            else\n            {\n                _3182 = 0.5 - (_3173.y * 0.5);\n            }\n            bool _3198 = _3178 >= 0.0;\n            bool _3204;\n            if (_3198)\n            {\n                _3204 = _3178 < 1.0;\n            }\n            else\n            {\n                _3204 = _3198;\n            }\n            bool _3210;\n            if (_3204)\n            {\n                _3210 = _3182 >= 0.0;\n            }\n            else\n            {\n                _3210 = _3204;\n            }\n            bool _3216;\n            if (_3210)\n            {\n                _3216 = _3182 < 1.0;\n            }\n            else\n            {\n                _3216 = _3210;\n            }\n            if (_3216)\n            {\n                vec4 _3242 = texelFetch(fa_screen_tex_fa_shadow_smp, clamp(ivec2(vec2(_3178, _3182) * fa_mesh_fs_params[24].zw), ivec2(0), ivec2(fa_mesh_fs_params[24].zw) - ivec2(1)), 0);\n                bool _3245 = _3242.w > 0.5;\n                bool _3261;\n                if (_3245)\n                {\n                    _3261 = abs(_3135 - _3242.x) <= (((0.00200000009499490261077880859375 * _3135) + 0.00999999977648258209228515625) + min(1.5 * _3138, 0.100000001490116119384765625 * _3135));\n                }\n                else\n                {\n                    _3261 = _3245;\n                }\n                if (_3261)\n                {\n                    float _3267;\n                    if (fa_mesh_fs_params[25].z > 0.5)\n                    {\n                        vec3 param = fa_world_pos;\n                        vec3 param_1 = n;\n                        vec3 param_2 = l;\n                        _3267 = min(_3242.y, fa_shadow_sun(param, param_1, param_2));\n                    }\n                    else\n                    {\n                        _3267 = _3242.y;\n                    }\n                    return _3267;\n                }\n            }\n        }\n    }\n    vec3 param_3 = fa_world_pos;\n    vec3 param_4 = n;\n    vec3 param_5 = l;\n    return fa_shadow_sun(param_3, param_4, param_5);\n}\n\nfloat fa_contact_shadow(int li, vec3 world, vec3 gn, vec3 l, float dist)\n{\n    bool _3923 = fa_mesh_fs_params[24].x < 0.5;\n    bool _3930;\n    if (!_3923)\n    {\n        _3930 = fa_shadows[29].x < 0.5;\n    }\n    else\n    {\n        _3930 = _3923;\n    }\n    if (_3930)\n    {\n        return 1.0;\n    }\n    int param = (int(fa_shadows[29].x + 0.5) - 1) + li;\n    vec4 _3943 = fa_light_texel(param);\n    float _3944 = _3943.y;\n    float len = _3944;\n    if (_3944 <= 0.0)\n    {\n        return 1.0;\n    }\n    float _3956 = length(world - fa_mesh_fs_params[0].xyz);\n    float _3965 = 1.0 - smoothstep(0.5 * fa_mesh_fs_params[25].x, fa_mesh_fs_params[25].x, _3956);\n    if (_3965 <= 0.0)\n    {\n        return 1.0;\n    }\n    float _3971 = len;\n    float _3974 = min(_3971, 0.89999997615814208984375 * dist);\n    len = _3974;\n    float _3980 = 0.004999999888241291046142578125 + (0.0030000000260770320892333984375 * _3956);\n    float _3985 = _3980 + (0.5 * _3974);\n    vec3 _3991 = world + (gn * _3980);\n    float _3993 = fa_shadow_noise();\n    float occ = 0.0;\n    float _4055;\n    for (int k = 0; k < 12; k++)\n    {\n        float _4009 = (float(k) + _3993) * 0.083333335816860198974609375;\n        vec3 _4017 = _3991 + (l * (_4009 * len));\n        vec4 _4023 = vec4(_4017, 1.0);\n        float _4028 = dot(fa_mesh_fs_params[28], _4023);\n        if (_4028 < 9.9999997473787516355514526367188e-05)\n        {\n            break;\n        }\n        vec2 _4046 = vec2(dot(fa_mesh_fs_params[26], _4023), dot(fa_mesh_fs_params[27], _4023)) / vec2(_4028);\n        float _4050 = _4046.x * 0.5;\n        float _4051 = _4050 + 0.5;\n        if (fa_mesh_fs_params[24].y > 0.5)\n        {\n            _4055 = (_4046.y * 0.5) + 0.5;\n        }\n        else\n        {\n            _4055 = 0.5 - (_4046.y * 0.5);\n        }\n        bool _4071 = _4051 < 0.0;\n        bool _4078;\n        if (!_4071)\n        {\n            _4078 = _4051 >= 1.0;\n        }\n        else\n        {\n            _4078 = _4071;\n        }\n        bool _4085;\n        if (!_4078)\n        {\n            _4085 = _4055 < 0.0;\n        }\n        else\n        {\n            _4085 = _4078;\n        }\n        bool _4092;\n        if (!_4085)\n        {\n            _4092 = _4055 >= 1.0;\n        }\n        else\n        {\n            _4092 = _4085;\n        }\n        if (_4092)\n        {\n            break;\n        }\n        vec4 _4116 = texelFetch(fa_screen_tex_fa_shadow_smp, clamp(ivec2(vec2(_4051, _4055) * fa_mesh_fs_params[24].zw), ivec2(0), ivec2(fa_mesh_fs_params[24].zw) - ivec2(1)), 0);\n        if (_4116.w < 0.5)\n        {\n            continue;\n        }\n        float _4134 = (dot(fa_mesh_fs_params[29].xyz, _4017) + fa_mesh_fs_params[29].w) - _4116.x;\n        if ((_4134 > _3980) && (_4134 < _3985))\n        {\n            occ = max(occ, (1.0 - (_4009 * _4009)) * smoothstep(0.0, 0.0500000007450580596923828125, min(min(_4051, 0.5 - _4050), min(_4055, 1.0 - _4055))));\n        }\n    }\n    return 1.0 - (occ * _3965);\n}\n\nLightSample fa_light_shadowed(int li, vec3 world_pos, vec3 gn)\n{\n    int param = li;\n    float _4237 = fa_baked_keep(param);\n    if (_4237 <= 0.0)\n    {\n        int param_1 = li;\n        return LightSample(vec3(0.0, 1.0, 0.0), vec3(0.0), 0.0, 1.0, 0.0, int(fa_light_type(param_1) + 0.5));\n    }\n    int param_2 = li;\n    vec3 param_3 = world_pos;\n    vec3 param_4 = gn;\n    LightSample _4263 = fa_light_sample_n(param_2, param_3, param_4);\n    vec3 _6087 = _4263.color;\n    float _6088 = _4263.attenuation;\n    float _6089 = _4263.shadow;\n    bool _4266 = _4263.type == 0;\n    if (_4266 && (li == 0))\n    {\n        vec3 param_5 = gn;\n        vec3 param_6 = _4263.direction;\n        float _4277 = fa_shadow_factor(param_5, param_6);\n        _6089 = _4277;\n        _6087 *= _4277;\n    }\n    else\n    {\n        bool _4288 = _4263.type != 0;\n        bool _4294;\n        if (_4288)\n        {\n            _4294 = _6088 > 0.0;\n        }\n        else\n        {\n            _4294 = _4288;\n        }\n        if (_4294)\n        {\n            int param_7 = li;\n            int param_8 = fa_light_base(param_7);\n            int param_9 = li;\n            vec3 param_10 = fa_light_texel(param_8).xyz;\n            vec3 param_11 = world_pos;\n            vec3 param_12 = gn;\n            vec3 param_13 = _4263.direction;\n            float _4313 = fa_shadow_local_rt(param_9, param_10, param_11, param_12, param_13);\n            _6089 = _4313;\n            _6087 *= _4313;\n        }\n    }\n    bool _4323 = fa_mesh_fs_params[24].x > 0.5;\n    bool _4329;\n    if (_4323)\n    {\n        _4329 = _6088 > 0.0;\n    }\n    else\n    {\n        _4329 = _4323;\n    }\n    if (_4329)\n    {\n        float _4336;\n        if (_4266)\n        {\n            _4336 = 1000000000.0;\n        }\n        else\n        {\n            _4336 = _4263._distance;\n        }\n        int param_14 = li;\n        vec3 param_15 = world_pos;\n        vec3 param_16 = gn;\n        vec3 param_17 = _4263.direction;\n        float param_18 = _4336;\n        float _4354 = fa_contact_shadow(param_14, param_15, param_16, param_17, param_18);\n        _6089 *= _4354;\n        _6087 *= _4354;\n    }\n    float _4367 = _6088;\n    float _4368 = _4367 * _4237;\n    _6088 = _4368;\n    vec3 _4372 = _6087;\n    vec3 _4373 = _4372 * _4237;\n    _6087 = _4373;\n    return LightSample(_4263.direction, _4373, _4368, _6089, _4263._distance, _4263.type);\n}\n\nvec3 light(SurfaceInput i, Surface s, LightSample l)\n{\n    return vec3(0.0);\n}\n\nvec3 fa_shadow_debug(vec3 color, vec3 world)\n{\n    if (fa_shadows[27].w < 0.5)\n    {\n        return color;\n    }\n    int _3038 = int(fa_shadows[25].x + 0.5);\n    float _3048 = dot(world - fa_shadows[27].xyz, fa_shadows[28].xyz);\n    vec3 tint = vec3(0.3499999940395355224609375);\n    bool _3053 = _3038 > 0;\n    bool _3062;\n    if (_3053)\n    {\n        int param = _3038 - 1;\n        _3062 = _3048 <= fa_shadow_split_at(param);\n    }\n    else\n    {\n        _3062 = _3053;\n    }\n    if (_3062)\n    {\n        tint = vec3(1.0, 0.1500000059604644775390625, 0.100000001490116119384765625);\n        bool _3068 = _3038 > 1;\n        bool _3075;\n        if (_3068)\n        {\n            _3075 = _3048 > fa_shadows[24].x;\n        }\n        else\n        {\n            _3075 = _3068;\n        }\n        if (_3075)\n        {\n            tint = vec3(0.100000001490116119384765625, 0.89999997615814208984375, 0.20000000298023223876953125);\n        }\n        bool _3081 = _3038 > 2;\n        bool _3088;\n        if (_3081)\n        {\n            _3088 = _3048 > fa_shadows[24].y;\n        }\n        else\n        {\n            _3088 = _3081;\n        }\n        if (_3088)\n        {\n            tint = vec3(0.1500000059604644775390625, 0.300000011920928955078125, 1.0);\n        }\n        bool _3094 = _3038 > 3;\n        bool _3101;\n        if (_3094)\n        {\n            _3101 = _3048 > fa_shadows[24].z;\n        }\n        else\n        {\n            _3101 = _3094;\n        }\n        if (_3101)\n        {\n            tint = vec3(1.0, 0.89999997615814208984375, 0.100000001490116119384765625);\n        }\n    }\n    return mix(color, tint, vec3(0.550000011920928955078125));\n}\n\nvoid main()\n{\n    fa_inst_load();\n    vec3 _5879 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _5879 = -_5879;\n    }\n    vec3 _5453 = normalize(fa_mesh_fs_params[0].xyz - fa_world_pos);\n    vec3 param = fa_world_pos;\n    fa_cluster_begin(param);\n    SurfaceInput param_1 = SurfaceInput(fa_world_pos, _5879, fa_world_tangent, fa_uv, fa_vertex_color, _5453, gl_FrontFacing);\n    Surface _5461 = fa_standard_surface(param_1);\n    vec3 _5918 = _5461.albedo;\n    float _5919 = _5461.alpha;\n    vec3 _5920 = _5461.normal;\n    float _5921 = _5461.metallic;\n    float _5922 = _5461.roughness;\n    float _5923 = _5461.occlusion;\n    vec3 _5924 = _5461.emission;\n    float _5925 = _5461.clearcoat;\n    float _5926 = _5461.clearcoat_roughness;\n    vec3 _5927 = _5461.sheen_color;\n    float _5928 = _5461.sheen_roughness;\n    float _5929 = _5461.anisotropy;\n    float _5930 = _5461.anisotropy_rotation;\n    float _5931 = _5461.specular;\n    float _5932 = _5461.ior;\n    vec3 _5933 = _5461.specular_color;\n    float _5934 = _5461.transmission;\n    float _5935 = _5461.thickness;\n    vec3 _5936 = _5461.attenuation_color;\n    float _5937 = _5461.attenuation_distance;\n    SurfaceInput param_2 = SurfaceInput(fa_world_pos, _5879, fa_world_tangent, fa_uv, fa_vertex_color, _5453, gl_FrontFacing);\n    Surface param_3 = _5461;\n    surface(param_2, param_3);\n    _5918 = param_3.albedo;\n    _5919 = param_3.alpha;\n    _5920 = param_3.normal;\n    _5921 = param_3.metallic;\n    _5922 = param_3.roughness;\n    _5923 = param_3.occlusion;\n    _5924 = param_3.emission;\n    _5925 = param_3.clearcoat;\n    _5926 = param_3.clearcoat_roughness;\n    _5927 = param_3.sheen_color;\n    _5928 = param_3.sheen_roughness;\n    _5929 = param_3.anisotropy;\n    _5930 = param_3.anisotropy_rotation;\n    _5931 = param_3.specular;\n    _5932 = param_3.ior;\n    _5933 = param_3.specular_color;\n    _5934 = param_3.transmission;\n    _5935 = param_3.thickness;\n    _5936 = param_3.attenuation_color;\n    _5937 = param_3.attenuation_distance;\n    vec3 param_4 = fa_world_pos;\n    vec3 param_5 = _5879;\n    vec3 param_6 = param_3.albedo;\n    vec3 param_7 = param_3.normal;\n    fa_apply_decals(param_4, param_5, param_6, param_7);\n    _5918 = param_6;\n    _5920 = param_7;\n    vec3 result;\n    if (fa_mesh_fs_params[3].w > 0.5)\n    {\n        result = _5918;\n    }\n    else\n    {\n        vec3 _5500 = _5920;\n        vec3 _5501 = normalize(_5500);\n        _5920 = _5501;\n        vec3 param_8 = _5501;\n        SurfaceInput param_9 = SurfaceInput(fa_world_pos, _5879, fa_world_tangent, fa_uv, fa_vertex_color, _5453, gl_FrontFacing);\n        Surface param_10 = Surface(_5918, _5919, _5920, _5921, _5922, _5923, _5924, _5925, _5926, _5927, _5928, _5929, _5930, _5931, _5932, _5933, _5934, _5935, _5936, _5937);\n        vec3 param_11 = fa_indirect_diffuse(param_8);\n        vec3 lit = ambient(param_9, param_10, param_11);\n        int _5520 = fa_cl_ndir + fa_cl_local;\n        for (int ln = 0; ln < _5520; ln++)\n        {\n            int param_12 = ln;\n            int _5533 = fa_cl_light(param_12);\n            int param_13 = _5533;\n            if (fa_baked_keep(param_13) <= 0.0)\n            {\n                continue;\n            }\n            int param_14 = _5533;\n            vec3 param_15 = fa_world_pos;\n            vec3 param_16 = _5879;\n            LightSample _5549 = fa_light_shadowed(param_14, param_15, param_16);\n            SurfaceInput param_17 = SurfaceInput(fa_world_pos, _5879, fa_world_tangent, fa_uv, fa_vertex_color, _5453, gl_FrontFacing);\n            Surface param_18 = Surface(_5918, _5919, _5920, _5921, _5922, _5923, _5924, _5925, _5926, _5927, _5928, _5929, _5930, _5931, _5932, _5933, _5934, _5935, _5936, _5937);\n            LightSample param_19 = _5549;\n            lit += light(param_17, param_18, param_19);\n        }\n        result = lit;\n    }\n    vec3 _5564 = result;\n    vec3 _5565 = _5564 + _5924;\n    result = _5565;\n    vec3 param_20 = _5565;\n    vec3 param_21 = fa_world_pos;\n    result = fa_shadow_debug(param_20, param_21);\n    bool _5574 = fa_mesh_fs_params[7].w > 0.0;\n    bool _5581;\n    if (!_5574)\n    {\n        _5581 = fa_mesh_fs_params[8].y > 0.0;\n    }\n    else\n    {\n        _5581 = _5574;\n    }\n    if (_5581)\n    {\n        vec3 _5590 = fa_world_pos - fa_mesh_fs_params[0].xyz;\n        float _5596 = dot(_5590, fa_mesh_fs_params[9].xyz);\n        bool _5600 = fa_mesh_fs_params[9].w > 0.5;\n        float _5601;\n        if (_5600)\n        {\n            _5601 = _5596;\n        }\n        else\n        {\n            _5601 = length(_5590);\n        }\n        float _5613 = _5601 - fa_mesh_fs_params[8].x;\n        if (_5613 > 0.0)\n        {\n            float _5622 = fa_mesh_fs_params[7].w * _5613;\n            float tau = _5622 * _5622;\n            if (fa_mesh_fs_params[8].y > 0.0)\n            {\n                float _5638;\n                if (_5600)\n                {\n                    _5638 = fa_world_pos.y - (fa_mesh_fs_params[9].y * _5596);\n                }\n                else\n                {\n                    _5638 = fa_mesh_fs_params[0].y;\n                }\n                float _5659 = mix(_5638, fa_world_pos.y, clamp(fa_mesh_fs_params[8].x / _5601, 0.0, 1.0));\n                float _5663 = fa_world_pos.y - _5659;\n                float _5668 = _5659 - fa_mesh_fs_params[8].z;\n                float _5673 = fa_world_pos.y - fa_mesh_fs_params[8].z;\n                bool _5676 = _5668 <= 0.0;\n                bool _5677 = !_5676;\n                bool _5683;\n                if (_5677)\n                {\n                    _5683 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _5683 = _5676;\n                }\n                float _5684;\n                if (_5683)\n                {\n                    _5684 = fa_mesh_fs_params[8].y;\n                }\n                else\n                {\n                    _5684 = fa_mesh_fs_params[8].y * exp(-min(fa_mesh_fs_params[8].w * _5668, 80.0));\n                }\n                bool _5711;\n                if (_5677)\n                {\n                    _5711 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _5711 = _5676;\n                }\n                float _5712;\n                if (_5711)\n                {\n                    _5712 = fa_mesh_fs_params[8].y * _5668;\n                }\n                else\n                {\n                    _5712 = (fa_mesh_fs_params[8].y * (1.0 - exp(-min(fa_mesh_fs_params[8].w * _5668, 80.0)))) / fa_mesh_fs_params[8].w;\n                }\n                bool _5737 = _5673 <= 0.0;\n                bool _5744;\n                if (!_5737)\n                {\n                    _5744 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _5744 = _5737;\n                }\n                float _5745;\n                if (_5744)\n                {\n                    _5745 = fa_mesh_fs_params[8].y * _5673;\n                }\n                else\n                {\n                    _5745 = (fa_mesh_fs_params[8].y * (1.0 - exp(-min(fa_mesh_fs_params[8].w * _5673, 80.0)))) / fa_mesh_fs_params[8].w;\n                }\n                float _5772;\n                if (abs(_5663) < 0.001000000047497451305389404296875)\n                {\n                    _5772 = _5684;\n                }\n                else\n                {\n                    _5772 = (_5745 - _5712) / _5663;\n                }\n                tau += (_5613 * max(_5772, 0.0));\n            }\n            result = mix(result, fa_mesh_fs_params[7].xyz, vec3(clamp(1.0 - exp(-clamp(tau, 0.0, 80.0)), 0.0, 1.0)));\n        }\n    }\n    fa_frag_color = vec4(result, _5919);\n}\n\n",
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
            "inst_name": "_427",
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
            "inst_name": "_2079",
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
      "fs": "#version 430\n\nstruct SurfaceInput\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 vertex_color;\n    vec3 view_dir;\n    bool front_facing;\n};\n\nstruct Surface\n{\n    vec3 albedo;\n    float alpha;\n    vec3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    vec3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    vec3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    vec3 specular_color;\n    float transmission;\n    float thickness;\n    vec3 attenuation_color;\n    float attenuation_distance;\n};\n\nuniform vec4 fa_mesh_fs_params[53];\nlayout(binding = 0) uniform sampler2D fa_tex_fa_smp;\nlayout(binding = 1) uniform sampler2D fa_normal_tex_fa_smp;\nlayout(binding = 2) uniform sampler2D fa_mr_tex_fa_smp;\nlayout(binding = 3) uniform sampler2D fa_occlusion_tex_fa_smp;\nlayout(binding = 4) uniform sampler2D fa_emissive_tex_fa_smp;\n\nlayout(location = 0) in vec3 fa_world_pos;\nlayout(location = 1) in vec3 fa_world_normal;\nlayout(location = 2) in vec4 fa_world_tangent;\nlayout(location = 3) in vec2 fa_uv;\nlayout(location = 4) in vec4 fa_vertex_color;\nlayout(location = 6) in vec3 fa_pre_r0;\nlayout(location = 7) in vec3 fa_pre_r1;\nlayout(location = 8) in vec3 fa_pre_r2;\nlayout(location = 0) out vec4 fa_frag_color;\nlayout(location = 5) in float fa_pre_depth;\nlayout(location = 9) in vec3 fa_vel_cur;\nlayout(location = 10) in vec3 fa_vel_prev;\nlayout(location = 1) out vec2 fa_frag_velocity;\n\nvoid fa_inst_load()\n{\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nvec3 fa_linear_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_tex_fix(inout vec3 c, float mode)\n{\n    if (mode > 1.5)\n    {\n        vec3 param = c;\n        vec3 _172 = fa_linear_to_srgb(param);\n        c = _172;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            vec3 param_1 = c;\n            vec3 _181 = fa_srgb_to_linear(param_1);\n            c = _181;\n        }\n    }\n    return c;\n}\n\nvec3 fa_tangent_normal(SurfaceInput i, vec3 m)\n{\n    vec3 _56;\n    if (i.front_facing)\n    {\n        _56 = i.world_normal;\n    }\n    else\n    {\n        _56 = -i.world_normal;\n    }\n    vec3 _81 = normalize(i.world_tangent.xyz - (_56 * dot(_56, i.world_tangent.xyz)));\n    vec3 _109 = normalize(((_81 * m.x) + ((cross(_56, _81) * i.world_tangent.w) * m.y)) + (_56 * m.z));\n    vec3 _112;\n    if (i.front_facing)\n    {\n        _112 = _109;\n    }\n    else\n    {\n        _112 = -_109;\n    }\n    return _112;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    vec4 base_t = texture(fa_tex_fa_smp, i.uv, fa_mesh_fs_params[12].w);\n    float param = fa_mesh_fs_params[6].w;\n    float param_1 = 1.0;\n    vec3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    vec3 _230 = fa_tex_fix(param_2, param_3);\n    vec4 _889 = base_t;\n    _889.x = _230.x;\n    _889.y = _230.y;\n    _889.z = _230.z;\n    base_t = _889;\n    vec4 _246 = (_889 * fa_mesh_fs_params[2]) * i.vertex_color;\n    vec3 _844 = i.world_normal;\n    if (fa_mesh_fs_params[6].z > 0.5)\n    {\n        float param_4 = fa_mesh_fs_params[6].w;\n        float param_5 = 16.0;\n        vec3 param_6 = texture(fa_normal_tex_fa_smp, i.uv, fa_mesh_fs_params[12].w).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        vec3 _282 = fa_tex_fix(param_6, param_7);\n        vec3 _286 = (_282 * 2.0) - vec3(1.0);\n        vec2 _291 = _286.xy * fa_mesh_fs_params[6].x;\n        vec3 _897 = _286;\n        _897.x = _291.x;\n        _897.y = _291.y;\n        SurfaceInput param_8 = i;\n        vec3 param_9 = _897;\n        _844 = fa_tangent_normal(param_8, param_9);\n    }\n    vec4 mrt = texture(fa_mr_tex_fa_smp, i.uv, fa_mesh_fs_params[12].w);\n    float param_10 = fa_mesh_fs_params[6].w;\n    float param_11 = 64.0;\n    vec3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    vec3 _322 = fa_tex_fix(param_12, param_13);\n    vec4 _900 = mrt;\n    _900.x = _322.x;\n    _900.y = _322.y;\n    _900.z = _322.z;\n    mrt = _900;\n    vec4 _354 = texture(fa_occlusion_tex_fa_smp, i.uv, fa_mesh_fs_params[12].w);\n    float param_14 = fa_mesh_fs_params[6].w;\n    float param_15 = 256.0;\n    vec3 param_16 = _354.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    vec3 _366 = fa_tex_fix(param_16, param_17);\n    float param_18 = fa_mesh_fs_params[6].w;\n    float param_19 = 4.0;\n    vec3 param_20 = texture(fa_emissive_tex_fa_smp, i.uv, fa_mesh_fs_params[12].w).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    vec3 _398 = fa_tex_fix(param_20, param_21);\n    float _849 = fa_mesh_fs_params[20].x;\n    float _850 = fa_mesh_fs_params[20].y;\n    float _853 = fa_mesh_fs_params[20].z;\n    float _852 = fa_mesh_fs_params[21].w;\n    float _855 = fa_mesh_fs_params[22].x;\n    if (fa_mesh_fs_params[22].z > 0.5)\n    {\n        if (mod(fa_mesh_fs_params[22].z, 2.0) > 0.5)\n        {\n            _849 *= _366.y;\n            _850 *= _366.z;\n            _852 *= _354.w;\n        }\n        if (fa_mesh_fs_params[22].z > 1.5)\n        {\n            _853 *= mrt.x;\n            _855 *= mrt.w;\n        }\n    }\n    return Surface(_246.xyz, _246.w, _844, clamp(fa_mesh_fs_params[5].x * _322.z, 0.0, 1.0), clamp(fa_mesh_fs_params[5].y * _322.y, 0.0500000007450580596923828125, 1.0), 1.0 + (fa_mesh_fs_params[6].y * (_366.x - 1.0)), fa_mesh_fs_params[3].xyz + (fa_mesh_fs_params[4].xyz * _398), _849, _850, fa_mesh_fs_params[21].xyz, _852, _853, fa_mesh_fs_params[20].w, _855, fa_mesh_fs_params[22].y, fa_mesh_fs_params[23].xyz, fa_mesh_fs_params[30].x, fa_mesh_fs_params[30].y, fa_mesh_fs_params[31].xyz, fa_mesh_fs_params[30].z);\n}\n\nvoid surface(SurfaceInput i, Surface s)\n{\n}\n\nvoid main()\n{\n    fa_inst_load();\n    vec3 _739 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _739 = -_739;\n    }\n    vec3 _550 = normalize(fa_mesh_fs_params[0].xyz - fa_world_pos);\n    SurfaceInput param = SurfaceInput(fa_world_pos, _739, fa_world_tangent, fa_uv, fa_vertex_color, _550, gl_FrontFacing);\n    SurfaceInput param_1 = SurfaceInput(fa_world_pos, _739, fa_world_tangent, fa_uv, fa_vertex_color, _550, gl_FrontFacing);\n    Surface param_2 = fa_standard_surface(param);\n    surface(param_1, param_2);\n    vec3 _565 = normalize(param_2.normal);\n    vec3 _580 = normalize(vec3(dot(fa_pre_r0, _565), dot(fa_pre_r1, _565), dot(fa_pre_r2, _565)));\n    float _592 = _580.z;\n    vec2 e = _580.xy / vec2((abs(_580.x) + abs(_580.y)) + abs(_592));\n    if (_592 < 0.0)\n    {\n        e = (vec2(1.0) - abs(e.yx)) * vec2((e.x >= 0.0) ? 1.0 : (-1.0), (e.y >= 0.0) ? 1.0 : (-1.0));\n    }\n    fa_frag_color = vec4(min(fa_pre_depth, 60000.0), e, 1.0);\n    vec2 motion = vec2(1024.0);\n    bool _636 = fa_vel_cur.z > 9.9999997473787516355514526367188e-06;\n    bool _643;\n    if (_636)\n    {\n        _643 = fa_vel_prev.z > 9.9999997473787516355514526367188e-06;\n    }\n    else\n    {\n        _643 = _636;\n    }\n    if (_643)\n    {\n        motion = clamp(((vec2(fa_vel_prev.x, -fa_vel_prev.y) / vec2(fa_vel_prev.z)) * 0.5) - ((vec2(fa_vel_cur.x, -fa_vel_cur.y) / vec2(fa_vel_cur.z)) * 0.5), vec2(-4.0), vec2(4.0));\n    }\n    fa_frag_velocity = motion;\n}\n\n",
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
      "vs": "#version 430\n\nstruct VertexData\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 color;\n    vec3 object_pos;\n};\n\nuniform vec4 fa_mesh_vs_params[11];\nuniform vec4 fa_skin[192];\nuniform vec4 fa_vel_params[9];\nlayout(binding = 0) uniform sampler2D fa_prev_pal_tex_fa_prev_pal_smp;\n\nlayout(location = 0) out vec3 fa_world_pos;\nlayout(location = 1) out vec3 fa_world_normal;\nlayout(location = 2) out vec4 fa_world_tangent;\nlayout(location = 3) out vec2 fa_uv;\nlayout(location = 4) out vec4 fa_vertex_color;\nlayout(location = 5) out float fa_pre_depth;\nlayout(location = 6) out vec3 fa_pre_r0;\nlayout(location = 7) out vec3 fa_pre_r1;\nlayout(location = 8) out vec3 fa_pre_r2;\nlayout(location = 9) out vec3 fa_vel_cur;\nlayout(location = 10) out vec3 fa_vel_prev;\nlayout(location = 11) in vec4 fa_prev_r0;\nlayout(location = 12) in vec4 fa_prev_r1;\nlayout(location = 13) in vec4 fa_prev_r2;\nlayout(location = 9) in vec4 fa_joints;\nlayout(location = 10) in vec4 fa_weights;\nlayout(location = 5) in vec4 fa_inst_m0;\nlayout(location = 6) in vec4 fa_inst_m1;\nlayout(location = 7) in vec4 fa_inst_m2;\nlayout(location = 8) in vec4 fa_inst_m3;\nlayout(location = 0) in vec3 fa_position;\nlayout(location = 1) in vec3 fa_normal;\nlayout(location = 3) in vec4 fa_tangent;\nlayout(location = 2) in vec2 fa_texcoord0;\nlayout(location = 4) in vec4 fa_color;\nvec4 fa_vtime;\n\nvoid fa_inst_begin()\n{\n}\n\nmat4 fa_skin_matrix(vec4 joints, vec4 weights)\n{\n    vec4 r0 = vec4(0.0);\n    vec4 r1 = vec4(0.0);\n    vec4 r2 = vec4(0.0);\n    for (int i = 0; i < 4; i++)\n    {\n        int _204 = int((joints[i] * 255.0) + 0.5) * 3;\n        r0 += (fa_skin[_204 * 1 + 0] * weights[i]);\n        r1 += (fa_skin[(_204 + 1) * 1 + 0] * weights[i]);\n        r2 += (fa_skin[(_204 + 2) * 1 + 0] * weights[i]);\n    }\n    return mat4(vec4(r0.x, r1.x, r2.x, 0.0), vec4(r0.y, r1.y, r2.y, 0.0), vec4(r0.z, r1.z, r2.z, 0.0), vec4(r0.w, r1.w, r2.w, 1.0));\n}\n\nvec4 fa_time_now()\n{\n    return fa_mesh_vs_params[9];\n}\n\nVertexData fa_vertex_data(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    vec3 _113 = cross(model[1].xyz, model[2].xyz);\n    float _117 = (dot(model[0].xyz, _113) < 0.0) ? (-1.0) : 1.0;\n    return VertexData((model * vec4(position, 1.0)).xyz, (((_113 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _117, vec4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _117), texcoord0 * fa_mesh_vs_params[8].xy, color, position);\n}\n\nmat4 fa_rows_to_mat4(vec4 r0, vec4 r1, vec4 r2)\n{\n    return mat4(vec4(r0.x, r1.x, r2.x, 0.0), vec4(r0.y, r1.y, r2.y, 0.0), vec4(r0.z, r1.z, r2.z, 0.0), vec4(r0.w, r1.w, r2.w, 1.0));\n}\n\nvec4 fa_prev_pal_texel(int t)\n{\n    return texelFetch(fa_prev_pal_tex_fa_prev_pal_smp, ivec2(t & 1023, t >> 10), 0);\n}\n\nmat4 fa_prev_skin_matrix(vec4 joints, vec4 weights, int base)\n{\n    vec4 r0 = vec4(0.0);\n    vec4 r1 = vec4(0.0);\n    vec4 r2 = vec4(0.0);\n    for (int i = 0; i < 4; i++)\n    {\n        int _332 = base + (int((joints[i] * 255.0) + 0.5) * 3);\n        int param = _332;\n        r0 += (fa_prev_pal_texel(param) * weights[i]);\n        int param_1 = _332 + 1;\n        r1 += (fa_prev_pal_texel(param_1) * weights[i]);\n        int param_2 = _332 + 2;\n        r2 += (fa_prev_pal_texel(param_2) * weights[i]);\n    }\n    return mat4(vec4(r0.x, r1.x, r2.x, 0.0), vec4(r0.y, r1.y, r2.y, 0.0), vec4(r0.z, r1.z, r2.z, 0.0), vec4(r0.w, r1.w, r2.w, 1.0));\n}\n\nmat4 fa_prev_model()\n{\n    vec4 param = fa_prev_r0;\n    vec4 param_1 = fa_prev_r1;\n    vec4 param_2 = fa_prev_r2;\n    vec4 param_3 = fa_joints;\n    vec4 param_4 = fa_weights;\n    int param_5 = int(fa_vel_params[8].w + 0.5);\n    return fa_rows_to_mat4(param, param_1, param_2) * fa_prev_skin_matrix(param_3, param_4, param_5);\n}\n\nvoid fa_prepass_vertex(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color, bool has_prev)\n{\n    bool _475;\n    if (has_prev)\n    {\n        _475 = fa_vel_params[8].x > 0.5;\n    }\n    else\n    {\n        _475 = has_prev;\n    }\n    fa_vtime = fa_time_now();\n    mat4 param = model;\n    vec3 param_1 = position;\n    vec3 param_2 = normal;\n    vec4 param_3 = tangent;\n    vec2 param_4 = texcoord0;\n    vec4 param_5 = color;\n    VertexData _490 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    vec3 _720 = _490.world_pos;\n    mat4 _494 = mat4(fa_mesh_vs_params[4], fa_mesh_vs_params[5], fa_mesh_vs_params[6], fa_mesh_vs_params[7]);\n    vec4 _501 = vec4(_720, 1.0);\n    fa_world_pos = _720;\n    fa_world_normal = _490.world_normal;\n    fa_world_tangent = _490.world_tangent;\n    fa_uv = _490.uv;\n    fa_vertex_color = _490.color;\n    fa_pre_depth = -(_494 * _501).z;\n    fa_pre_r0 = vec3(_494[0].x, _494[1].x, _494[2].x);\n    fa_pre_r1 = vec3(_494[0].y, _494[1].y, _494[2].y);\n    fa_pre_r2 = vec3(_494[0].z, _494[1].z, _494[2].z);\n    gl_Position = mat4(fa_mesh_vs_params[0], fa_mesh_vs_params[1], fa_mesh_vs_params[2], fa_mesh_vs_params[3]) * _501;\n    fa_vel_cur = vec3(0.0, 0.0, 1.0);\n    fa_vel_prev = vec3(0.0);\n    if (_475)\n    {\n        vec4 _574 = vec4(position, 1.0);\n        fa_vel_cur = vec3((mat4(fa_vel_params[0], fa_vel_params[1], fa_vel_params[2], fa_vel_params[3]) * _501).xyw);\n        fa_vel_prev = vec3((mat4(fa_vel_params[4], fa_vel_params[5], fa_vel_params[6], fa_vel_params[7]) * vec4((_720 + (fa_prev_model() * _574).xyz) - (model * _574).xyz, 1.0)).xyw);\n    }\n}\n\nvoid main()\n{\n    fa_vtime = vec4(0.0);\n    fa_inst_begin();\n    vec4 param = fa_joints;\n    vec4 param_1 = fa_weights;\n    mat4 param_2 = mat4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3) * fa_skin_matrix(param, param_1);\n    vec3 param_3 = fa_position;\n    vec3 param_4 = fa_normal;\n    vec4 param_5 = fa_tangent;\n    vec2 param_6 = fa_texcoord0;\n    vec4 param_7 = fa_color;\n    bool param_8 = fa_vel_params[8].z > 0.5;\n    fa_prepass_vertex(param_2, param_3, param_4, param_5, param_6, param_7, param_8);\n}\n\n",
      "fs": "#version 430\n\nstruct SurfaceInput\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 vertex_color;\n    vec3 view_dir;\n    bool front_facing;\n};\n\nstruct Surface\n{\n    vec3 albedo;\n    float alpha;\n    vec3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    vec3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    vec3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    vec3 specular_color;\n    float transmission;\n    float thickness;\n    vec3 attenuation_color;\n    float attenuation_distance;\n};\n\nuniform vec4 fa_mesh_fs_params[53];\nlayout(binding = 0) uniform sampler2D fa_tex_fa_smp;\nlayout(binding = 1) uniform sampler2D fa_normal_tex_fa_smp;\nlayout(binding = 2) uniform sampler2D fa_mr_tex_fa_smp;\nlayout(binding = 3) uniform sampler2D fa_occlusion_tex_fa_smp;\nlayout(binding = 4) uniform sampler2D fa_emissive_tex_fa_smp;\n\nlayout(location = 0) in vec3 fa_world_pos;\nlayout(location = 1) in vec3 fa_world_normal;\nlayout(location = 2) in vec4 fa_world_tangent;\nlayout(location = 3) in vec2 fa_uv;\nlayout(location = 4) in vec4 fa_vertex_color;\nlayout(location = 6) in vec3 fa_pre_r0;\nlayout(location = 7) in vec3 fa_pre_r1;\nlayout(location = 8) in vec3 fa_pre_r2;\nlayout(location = 0) out vec4 fa_frag_color;\nlayout(location = 5) in float fa_pre_depth;\nlayout(location = 9) in vec3 fa_vel_cur;\nlayout(location = 10) in vec3 fa_vel_prev;\nlayout(location = 1) out vec2 fa_frag_velocity;\n\nvoid fa_inst_load()\n{\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nvec3 fa_linear_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_tex_fix(inout vec3 c, float mode)\n{\n    if (mode > 1.5)\n    {\n        vec3 param = c;\n        vec3 _172 = fa_linear_to_srgb(param);\n        c = _172;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            vec3 param_1 = c;\n            vec3 _181 = fa_srgb_to_linear(param_1);\n            c = _181;\n        }\n    }\n    return c;\n}\n\nvec3 fa_tangent_normal(SurfaceInput i, vec3 m)\n{\n    vec3 _56;\n    if (i.front_facing)\n    {\n        _56 = i.world_normal;\n    }\n    else\n    {\n        _56 = -i.world_normal;\n    }\n    vec3 _81 = normalize(i.world_tangent.xyz - (_56 * dot(_56, i.world_tangent.xyz)));\n    vec3 _109 = normalize(((_81 * m.x) + ((cross(_56, _81) * i.world_tangent.w) * m.y)) + (_56 * m.z));\n    vec3 _112;\n    if (i.front_facing)\n    {\n        _112 = _109;\n    }\n    else\n    {\n        _112 = -_109;\n    }\n    return _112;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    vec4 base_t = texture(fa_tex_fa_smp, i.uv, fa_mesh_fs_params[12].w);\n    float param = fa_mesh_fs_params[6].w;\n    float param_1 = 1.0;\n    vec3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    vec3 _230 = fa_tex_fix(param_2, param_3);\n    vec4 _889 = base_t;\n    _889.x = _230.x;\n    _889.y = _230.y;\n    _889.z = _230.z;\n    base_t = _889;\n    vec4 _246 = (_889 * fa_mesh_fs_params[2]) * i.vertex_color;\n    vec3 _844 = i.world_normal;\n    if (fa_mesh_fs_params[6].z > 0.5)\n    {\n        float param_4 = fa_mesh_fs_params[6].w;\n        float param_5 = 16.0;\n        vec3 param_6 = texture(fa_normal_tex_fa_smp, i.uv, fa_mesh_fs_params[12].w).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        vec3 _282 = fa_tex_fix(param_6, param_7);\n        vec3 _286 = (_282 * 2.0) - vec3(1.0);\n        vec2 _291 = _286.xy * fa_mesh_fs_params[6].x;\n        vec3 _897 = _286;\n        _897.x = _291.x;\n        _897.y = _291.y;\n        SurfaceInput param_8 = i;\n        vec3 param_9 = _897;\n        _844 = fa_tangent_normal(param_8, param_9);\n    }\n    vec4 mrt = texture(fa_mr_tex_fa_smp, i.uv, fa_mesh_fs_params[12].w);\n    float param_10 = fa_mesh_fs_params[6].w;\n    float param_11 = 64.0;\n    vec3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    vec3 _322 = fa_tex_fix(param_12, param_13);\n    vec4 _900 = mrt;\n    _900.x = _322.x;\n    _900.y = _322.y;\n    _900.z = _322.z;\n    mrt = _900;\n    vec4 _354 = texture(fa_occlusion_tex_fa_smp, i.uv, fa_mesh_fs_params[12].w);\n    float param_14 = fa_mesh_fs_params[6].w;\n    float param_15 = 256.0;\n    vec3 param_16 = _354.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    vec3 _366 = fa_tex_fix(param_16, param_17);\n    float param_18 = fa_mesh_fs_params[6].w;\n    float param_19 = 4.0;\n    vec3 param_20 = texture(fa_emissive_tex_fa_smp, i.uv, fa_mesh_fs_params[12].w).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    vec3 _398 = fa_tex_fix(param_20, param_21);\n    float _849 = fa_mesh_fs_params[20].x;\n    float _850 = fa_mesh_fs_params[20].y;\n    float _853 = fa_mesh_fs_params[20].z;\n    float _852 = fa_mesh_fs_params[21].w;\n    float _855 = fa_mesh_fs_params[22].x;\n    if (fa_mesh_fs_params[22].z > 0.5)\n    {\n        if (mod(fa_mesh_fs_params[22].z, 2.0) > 0.5)\n        {\n            _849 *= _366.y;\n            _850 *= _366.z;\n            _852 *= _354.w;\n        }\n        if (fa_mesh_fs_params[22].z > 1.5)\n        {\n            _853 *= mrt.x;\n            _855 *= mrt.w;\n        }\n    }\n    return Surface(_246.xyz, _246.w, _844, clamp(fa_mesh_fs_params[5].x * _322.z, 0.0, 1.0), clamp(fa_mesh_fs_params[5].y * _322.y, 0.0500000007450580596923828125, 1.0), 1.0 + (fa_mesh_fs_params[6].y * (_366.x - 1.0)), fa_mesh_fs_params[3].xyz + (fa_mesh_fs_params[4].xyz * _398), _849, _850, fa_mesh_fs_params[21].xyz, _852, _853, fa_mesh_fs_params[20].w, _855, fa_mesh_fs_params[22].y, fa_mesh_fs_params[23].xyz, fa_mesh_fs_params[30].x, fa_mesh_fs_params[30].y, fa_mesh_fs_params[31].xyz, fa_mesh_fs_params[30].z);\n}\n\nvoid surface(SurfaceInput i, Surface s)\n{\n}\n\nvoid main()\n{\n    fa_inst_load();\n    vec3 _739 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _739 = -_739;\n    }\n    vec3 _550 = normalize(fa_mesh_fs_params[0].xyz - fa_world_pos);\n    SurfaceInput param = SurfaceInput(fa_world_pos, _739, fa_world_tangent, fa_uv, fa_vertex_color, _550, gl_FrontFacing);\n    SurfaceInput param_1 = SurfaceInput(fa_world_pos, _739, fa_world_tangent, fa_uv, fa_vertex_color, _550, gl_FrontFacing);\n    Surface param_2 = fa_standard_surface(param);\n    surface(param_1, param_2);\n    vec3 _565 = normalize(param_2.normal);\n    vec3 _580 = normalize(vec3(dot(fa_pre_r0, _565), dot(fa_pre_r1, _565), dot(fa_pre_r2, _565)));\n    float _592 = _580.z;\n    vec2 e = _580.xy / vec2((abs(_580.x) + abs(_580.y)) + abs(_592));\n    if (_592 < 0.0)\n    {\n        e = (vec2(1.0) - abs(e.yx)) * vec2((e.x >= 0.0) ? 1.0 : (-1.0), (e.y >= 0.0) ? 1.0 : (-1.0));\n    }\n    fa_frag_color = vec4(min(fa_pre_depth, 60000.0), e, 1.0);\n    vec2 motion = vec2(1024.0);\n    bool _636 = fa_vel_cur.z > 9.9999997473787516355514526367188e-06;\n    bool _643;\n    if (_636)\n    {\n        _643 = fa_vel_prev.z > 9.9999997473787516355514526367188e-06;\n    }\n    else\n    {\n        _643 = _636;\n    }\n    if (_643)\n    {\n        motion = clamp(((vec2(fa_vel_prev.x, -fa_vel_prev.y) / vec2(fa_vel_prev.z)) * 0.5) - ((vec2(fa_vel_cur.x, -fa_vel_cur.y) / vec2(fa_vel_cur.z)) * 0.5), vec2(-4.0), vec2(4.0));\n    }\n    fa_frag_velocity = motion;\n}\n\n",
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
