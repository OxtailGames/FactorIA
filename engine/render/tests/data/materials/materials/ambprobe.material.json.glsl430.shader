{
  "format": "factoria.shader/1",
  "engine": "0.32.0",
  "template": "5f457c7d0bc8edbcdea422ba00c093c613745eefd8db6d8c8f93fc5e235db1e8",
  "slang": "glsl430",
  "params": [],
  "textures": [],
  "programs": {
    "mesh": {
      "vs": "#version 430\n\nstruct VertexData\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 color;\n    vec3 object_pos;\n};\n\nuniform vec4 fa_mesh_vs_params[11];\nlayout(location = 0) out vec3 fa_world_pos;\nlayout(location = 1) out vec3 fa_world_normal;\nlayout(location = 2) out vec4 fa_world_tangent;\nlayout(location = 3) out vec2 fa_uv;\nlayout(location = 4) out vec4 fa_vertex_color;\nlayout(location = 5) in vec4 fa_inst_m0;\nlayout(location = 6) in vec4 fa_inst_m1;\nlayout(location = 7) in vec4 fa_inst_m2;\nlayout(location = 8) in vec4 fa_inst_m3;\nlayout(location = 0) in vec3 fa_position;\nlayout(location = 1) in vec3 fa_normal;\nlayout(location = 3) in vec4 fa_tangent;\nlayout(location = 2) in vec2 fa_texcoord0;\nlayout(location = 4) in vec4 fa_color;\nlayout(location = 5) out vec3 fa_lm;\n\nvoid fa_inst_begin()\n{\n}\n\nVertexData fa_vertex_data(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    vec3 _69 = cross(model[1].xyz, model[2].xyz);\n    float _75 = (dot(model[0].xyz, _69) < 0.0) ? (-1.0) : 1.0;\n    return VertexData((model * vec4(position, 1.0)).xyz, (((_69 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _75, vec4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _75), texcoord0 * fa_mesh_vs_params[8].xy, color, position);\n}\n\nvoid fa_shade_vertex(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    mat4 param = model;\n    vec3 param_1 = position;\n    vec3 param_2 = normal;\n    vec4 param_3 = tangent;\n    vec2 param_4 = texcoord0;\n    vec4 param_5 = color;\n    VertexData _160 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    vec3 _267 = _160.world_pos;\n    fa_world_pos = _267;\n    fa_world_normal = _160.world_normal;\n    fa_world_tangent = _160.world_tangent;\n    fa_uv = _160.uv;\n    fa_vertex_color = _160.color;\n    gl_Position = mat4(fa_mesh_vs_params[0], fa_mesh_vs_params[1], fa_mesh_vs_params[2], fa_mesh_vs_params[3]) * vec4(_267, 1.0);\n}\n\nvoid main()\n{\n    fa_inst_begin();\n    mat4 param = mat4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3);\n    vec3 param_1 = fa_position;\n    vec3 param_2 = fa_normal;\n    vec4 param_3 = fa_tangent;\n    vec2 param_4 = fa_texcoord0;\n    vec4 param_5 = fa_color;\n    fa_shade_vertex(param, param_1, param_2, param_3, param_4, param_5);\n    fa_lm = vec3(0.0);\n}\n\n",
      "fs": "#version 430\n\nstruct SurfaceInput\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 vertex_color;\n    vec3 view_dir;\n    bool front_facing;\n};\n\nstruct LightSample\n{\n    vec3 direction;\n    vec3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct Surface\n{\n    vec3 albedo;\n    float alpha;\n    vec3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    vec3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    vec3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    vec3 specular_color;\n};\n\nuniform vec4 fa_mesh_fs_params[24];\nuniform vec4 fa_shadows[30];\nlayout(binding = 0) uniform sampler2D fa_light_tex_fa_shadow_smp;\nlayout(binding = 1) uniform sampler2D fa_tex_fa_smp;\nlayout(binding = 2) uniform sampler2D fa_normal_tex_fa_smp;\nlayout(binding = 3) uniform sampler2D fa_mr_tex_fa_smp;\nlayout(binding = 4) uniform sampler2D fa_occlusion_tex_fa_smp;\nlayout(binding = 5) uniform sampler2D fa_emissive_tex_fa_smp;\nlayout(binding = 6) uniform sampler2D fa_decal_tex_fa_env_smp;\nlayout(binding = 7) uniform sampler2D fa_lightmap_fa_env_smp;\nlayout(binding = 8) uniform samplerCube fa_env_tex_fa_env_smp;\nlayout(binding = 9) uniform sampler2D fa_light_atlas_fa_env_smp;\nlayout(binding = 10) uniform sampler2D fa_shadow_tex_fa_shadow_smp;\n\nlayout(location = 0) in vec3 fa_world_pos;\nlayout(location = 5) in vec3 fa_lm;\nlayout(location = 1) in vec3 fa_world_normal;\nlayout(location = 2) in vec4 fa_world_tangent;\nlayout(location = 3) in vec2 fa_uv;\nlayout(location = 4) in vec4 fa_vertex_color;\nlayout(location = 0) out vec4 fa_frag_color;\nvec3 fa_light_tint;\nbool fa_light_is_area;\nint fa_cl_ndir;\nint fa_cl_slot;\nint fa_cl_local;\n\nvoid fa_inst_load()\n{\n}\n\nvec4 fa_light_texel(int t)\n{\n    return texelFetch(fa_light_tex_fa_shadow_smp, ivec2(t & 1023, t >> 10), 0);\n}\n\nvec4 fa_cluster_texel(vec3 world_pos)\n{\n    bool _1312 = fa_mesh_fs_params[19].x < 0.0;\n    bool _1319;\n    if (!_1312)\n    {\n        _1319 = fa_mesh_fs_params[19].w < 1.0;\n    }\n    else\n    {\n        _1319 = _1312;\n    }\n    bool _1327;\n    if (!_1319)\n    {\n        _1327 = fa_mesh_fs_params[18].x < 1.0;\n    }\n    else\n    {\n        _1327 = _1319;\n    }\n    bool _1334;\n    if (!_1327)\n    {\n        _1334 = fa_mesh_fs_params[18].y < 1.0;\n    }\n    else\n    {\n        _1334 = _1327;\n    }\n    bool _1341;\n    if (!_1334)\n    {\n        _1341 = fa_mesh_fs_params[19].y < 1.0;\n    }\n    else\n    {\n        _1341 = _1334;\n    }\n    if (_1341)\n    {\n        return vec4(0.0);\n    }\n    vec4 _1351 = vec4(world_pos, 1.0);\n    float _1357 = dot(fa_mesh_fs_params[16], _1351);\n    if (!(_1357 > 9.9999999747524270787835121154785e-07))\n    {\n        return vec4(0.0);\n    }\n    vec2 _1379 = vec2(dot(fa_mesh_fs_params[14], _1351), dot(fa_mesh_fs_params[15], _1351)) / vec2(_1357);\n    int _1383 = int(fa_mesh_fs_params[18].x);\n    int _1387 = int(fa_mesh_fs_params[18].y);\n    int param = (int(fa_mesh_fs_params[19].x) + (((clamp(int(floor(log2(max(dot(fa_mesh_fs_params[17].xyz, world_pos) + fa_mesh_fs_params[17].w, fa_mesh_fs_params[18].w) / fa_mesh_fs_params[18].w) * fa_mesh_fs_params[18].z)), 0, int(fa_mesh_fs_params[19].y) - 1) * _1387) + clamp(int(floor(((_1379.y * 0.5) + 0.5) * fa_mesh_fs_params[18].y)), 0, _1387 - 1)) * _1383)) + clamp(int(floor(((_1379.x * 0.5) + 0.5) * fa_mesh_fs_params[18].x)), 0, _1383 - 1);\n    return fa_light_texel(param);\n}\n\nivec2 fa_cluster_lookup(vec3 world_pos)\n{\n    vec3 param = world_pos;\n    vec4 _1463 = fa_cluster_texel(param);\n    return ivec2(int(_1463.x), int(_1463.y));\n}\n\nvoid fa_cluster_begin(vec3 world_pos)\n{\n    fa_cl_ndir = int(fa_mesh_fs_params[19].z);\n    vec3 param = world_pos;\n    ivec2 _3241 = fa_cluster_lookup(param);\n    fa_cl_slot = _3241.x;\n    fa_cl_local = _3241.y;\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nvec3 fa_linear_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_tex_fix(inout vec3 c, float mode)\n{\n    if (mode > 1.5)\n    {\n        vec3 param = c;\n        vec3 _3400 = fa_linear_to_srgb(param);\n        c = _3400;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            vec3 param_1 = c;\n            vec3 _3408 = fa_srgb_to_linear(param_1);\n            c = _3408;\n        }\n    }\n    return c;\n}\n\nvec3 fa_tangent_normal(SurfaceInput i, vec3 m)\n{\n    vec3 _267;\n    if (i.front_facing)\n    {\n        _267 = i.world_normal;\n    }\n    else\n    {\n        _267 = -i.world_normal;\n    }\n    vec3 _291 = normalize(i.world_tangent.xyz - (_267 * dot(_267, i.world_tangent.xyz)));\n    vec3 _318 = normalize(((_291 * m.x) + ((cross(_267, _291) * i.world_tangent.w) * m.y)) + (_267 * m.z));\n    vec3 _321;\n    if (i.front_facing)\n    {\n        _321 = _318;\n    }\n    else\n    {\n        _321 = -_318;\n    }\n    return _321;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    vec4 base_t = texture(fa_tex_fa_smp, i.uv);\n    float param = fa_mesh_fs_params[6].w;\n    float param_1 = 1.0;\n    vec3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    vec3 _3439 = fa_tex_fix(param_2, param_3);\n    vec4 _4487 = base_t;\n    _4487.x = _3439.x;\n    _4487.y = _3439.y;\n    _4487.z = _3439.z;\n    base_t = _4487;\n    vec4 _3453 = (_4487 * fa_mesh_fs_params[2]) * i.vertex_color;\n    vec3 _4352 = i.world_normal;\n    if (fa_mesh_fs_params[6].z > 0.5)\n    {\n        float param_4 = fa_mesh_fs_params[6].w;\n        float param_5 = 16.0;\n        vec3 param_6 = texture(fa_normal_tex_fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        vec3 _3485 = fa_tex_fix(param_6, param_7);\n        vec3 _3488 = (_3485 * 2.0) - vec3(1.0);\n        vec2 _3493 = _3488.xy * fa_mesh_fs_params[6].x;\n        vec3 _4495 = _3488;\n        _4495.x = _3493.x;\n        _4495.y = _3493.y;\n        SurfaceInput param_8 = i;\n        vec3 param_9 = _4495;\n        _4352 = fa_tangent_normal(param_8, param_9);\n    }\n    vec4 mrt = texture(fa_mr_tex_fa_smp, i.uv);\n    float param_10 = fa_mesh_fs_params[6].w;\n    float param_11 = 64.0;\n    vec3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    vec3 _3521 = fa_tex_fix(param_12, param_13);\n    vec4 _4498 = mrt;\n    _4498.x = _3521.x;\n    _4498.y = _3521.y;\n    _4498.z = _3521.z;\n    mrt = _4498;\n    vec4 _3549 = texture(fa_occlusion_tex_fa_smp, i.uv);\n    float param_14 = fa_mesh_fs_params[6].w;\n    float param_15 = 256.0;\n    vec3 param_16 = _3549.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    vec3 _3560 = fa_tex_fix(param_16, param_17);\n    float param_18 = fa_mesh_fs_params[6].w;\n    float param_19 = 4.0;\n    vec3 param_20 = texture(fa_emissive_tex_fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    vec3 _3590 = fa_tex_fix(param_20, param_21);\n    float _4357 = fa_mesh_fs_params[20].x;\n    float _4358 = fa_mesh_fs_params[20].y;\n    float _4361 = fa_mesh_fs_params[20].z;\n    float _4360 = fa_mesh_fs_params[21].w;\n    float _4363 = fa_mesh_fs_params[22].x;\n    if (fa_mesh_fs_params[22].z > 0.5)\n    {\n        if (mod(fa_mesh_fs_params[22].z, 2.0) > 0.5)\n        {\n            _4357 *= _3560.y;\n            _4358 *= _3560.z;\n            _4360 *= _3549.w;\n        }\n        if (fa_mesh_fs_params[22].z > 1.5)\n        {\n            _4361 *= mrt.x;\n            _4363 *= mrt.w;\n        }\n    }\n    return Surface(_3453.xyz, _3453.w, _4352, clamp(fa_mesh_fs_params[5].x * _3521.z, 0.0, 1.0), clamp(fa_mesh_fs_params[5].y * _3521.y, 0.0500000007450580596923828125, 1.0), 1.0 + (fa_mesh_fs_params[6].y * (_3560.x - 1.0)), fa_mesh_fs_params[3].xyz + (fa_mesh_fs_params[4].xyz * _3590), _4357, _4358, fa_mesh_fs_params[21].xyz, _4360, _4361, fa_mesh_fs_params[20].w, _4363, fa_mesh_fs_params[22].y, fa_mesh_fs_params[23].xyz);\n}\n\nvoid surface(SurfaceInput i, Surface s)\n{\n}\n\nvec4 fa_decal_tile(vec4 rect, vec2 uv, vec2 atlas, vec2 ddx, vec2 ddy)\n{\n    vec2 _1543 = rect.zw - rect.xy;\n    vec2 _1547 = _1543 * atlas;\n    vec2 _1551 = ddx * _1547;\n    vec2 _1555 = ddy * _1547;\n    return textureLod(fa_decal_tex_fa_env_smp, rect.xy + (clamp(uv, vec2(0.0), vec2(1.0)) * _1543), clamp(0.5 * log2(max(max(dot(_1551, _1551), dot(_1555, _1555)), 9.9999999392252902907785028219223e-09)), 0.0, 4.0));\n}\n\nvec3 fa_dc_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_dc_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvoid fa_apply_decals(vec3 world_pos, vec3 geo_normal, inout vec3 albedo, inout vec3 normal)\n{\n    bool _1588 = fa_mesh_fs_params[10].y < 0.5;\n    bool _1595;\n    if (!_1588)\n    {\n        _1595 = fa_mesh_fs_params[10].w < 0.5;\n    }\n    else\n    {\n        _1595 = _1588;\n    }\n    if (_1595)\n    {\n        return;\n    }\n    vec3 _1601 = dFdx(world_pos);\n    vec3 _1604 = dFdy(world_pos);\n    vec3 param = world_pos;\n    vec4 _1608 = fa_cluster_texel(param);\n    int _1612 = int(_1608.w);\n    if (_1612 < 1)\n    {\n        return;\n    }\n    int _1622 = int(fa_mesh_fs_params[10].y + 0.5);\n    int param_1 = _1622;\n    vec4 _1626 = fa_light_texel(param_1);\n    vec2 _1629 = _1626.yz;\n    int _1633 = int(_1626.w);\n    int param_2 = _1622 + 1;\n    vec4 _1638 = fa_light_texel(param_2);\n    float _1639 = _1638.x;\n    int _1645 = int(fa_mesh_fs_params[10].w + 0.5) - 1;\n    int _1649 = int(_1608.z);\n    vec3 _1914;\n    for (int k = 0; k < _1612; k++)\n    {\n        int _1662 = _1649 + k;\n        int param_3 = _1633 + (_1662 >> 2);\n        int _1679 = (_1622 + 2) + (int(fa_light_texel(param_3)[_1662 & 3]) * 7);\n        int param_4 = _1679 + 6;\n        vec4 _1684 = fa_light_texel(param_4);\n        if (((int(_1684.w + 0.5) >> _1645) & 1) == 0)\n        {\n            continue;\n        }\n        int param_5 = _1679;\n        vec4 _1699 = fa_light_texel(param_5);\n        int param_6 = _1679 + 1;\n        vec4 _1704 = fa_light_texel(param_6);\n        int param_7 = _1679 + 2;\n        vec4 _1709 = fa_light_texel(param_7);\n        vec3 _1712 = _1699.xyz;\n        float _1717 = dot(_1712, world_pos) + _1699.w;\n        vec3 _1719 = _1704.xyz;\n        float _1724 = dot(_1719, world_pos) + _1704.w;\n        vec3 _1726 = _1709.xyz;\n        float _1731 = dot(_1726, world_pos) + _1709.w;\n        bool _1736 = abs(_1717) > 0.5;\n        bool _1744;\n        if (!_1736)\n        {\n            _1744 = abs(_1724) > 0.5;\n        }\n        else\n        {\n            _1744 = _1736;\n        }\n        bool _1752;\n        if (!_1744)\n        {\n            _1752 = abs(_1731) > 0.5;\n        }\n        else\n        {\n            _1752 = _1744;\n        }\n        if (_1752)\n        {\n            continue;\n        }\n        float _1767 = clamp(dot(geo_normal, normalize(_1726)) * _1684.z, 0.0, 1.0);\n        if (_1767 <= 0.0)\n        {\n            continue;\n        }\n        float _1787 = (clamp((0.5 - abs(_1731)) * 10.0, 0.0, 1.0) * _1767) * _1684.x;\n        vec2 _1795 = vec2(_1717 + 0.5, 0.5 - _1724);\n        vec2 _1805 = vec2(dot(_1712, _1601), dot(_1719, _1601));\n        vec2 _1815 = vec2(dot(_1712, _1604), dot(_1719, _1604));\n        int param_8 = _1679 + 5;\n        vec4 _1820 = fa_light_texel(param_8);\n        int param_9 = _1679 + 3;\n        vec4 _1825 = fa_light_texel(param_9);\n        int param_10 = _1679 + 4;\n        vec4 _1830 = fa_light_texel(param_10);\n        float tex_a = 1.0;\n        vec3 col = _1820.xyz;\n        bool _1840 = _1825.z > _1825.x;\n        if (_1840)\n        {\n            vec4 param_11 = _1825;\n            vec2 param_12 = _1795;\n            vec2 param_13 = _1629;\n            vec2 param_14 = _1805;\n            vec2 param_15 = _1815;\n            vec4 tx = fa_decal_tile(param_11, param_12, param_13, param_14, param_15);\n            if ((_1639 > 0.5) && (_1639 < 1.5))\n            {\n                vec3 param_16 = tx.xyz;\n                vec3 _1866 = fa_dc_to_linear(param_16);\n                vec4 _4432 = tx;\n                _4432.x = _1866.x;\n                _4432.y = _1866.y;\n                _4432.z = _1866.z;\n                tx = _4432;\n            }\n            col *= tx.xyz;\n            tex_a = tx.w;\n        }\n        albedo = mix(albedo, col, vec3(clamp((_1787 * tex_a) * _1820.w, 0.0, 1.0)));\n        if (_1830.z > _1830.x)\n        {\n            vec4 param_17 = _1830;\n            vec2 param_18 = _1795;\n            vec2 param_19 = _1629;\n            vec2 param_20 = _1805;\n            vec2 param_21 = _1815;\n            vec4 _1910 = fa_decal_tile(param_17, param_18, param_19, param_20, param_21);\n            if (_1639 > 1.5)\n            {\n                vec3 param_22 = _1910.xyz;\n                vec3 _1920 = fa_dc_to_srgb(param_22);\n                _1914 = _1920;\n            }\n            else\n            {\n                _1914 = _1910.xyz;\n            }\n            vec3 _1929 = (_1914 * 2.0) - vec3(1.0);\n            vec2 _1934 = _1929.xy * _1684.y;\n            vec3 _1956 = (normalize(_1712) * _1934.x) + (normalize(_1719) * _1934.y);\n            vec3 _1959 = normalize(normal);\n            normal = normalize(mix(_1959, normalize((_1959 * max(_1929.z, 0.0500000007450580596923828125)) + (_1956 - (_1959 * dot(_1959, _1956)))), vec3(clamp(_1787 * (_1840 ? tex_a : 1.0), 0.0, 1.0))));\n        }\n    }\n}\n\nvec3 fa_sky_sh_coef(int k)\n{\n    vec3 v = textureLod(fa_env_tex_fa_env_smp, vec3(1.0, 1.0 - (float((2 * (k >> 2)) + 1) * 0.25), 1.0 - (float((2 * (k & 3)) + 1) * 0.25)), 5.0).xyz;\n    if (fa_mesh_fs_params[11].w > 1.5)\n    {\n        v = (v - vec3(0.5)) * 8.0;\n    }\n    return v;\n}\n\nvec3 fa_sh_eval(vec3 c[9], vec3 n)\n{\n    vec3 _3154 = max((((c[0] * 0.2820948064327239990234375) + (((c[1] * (0.3257350027561187744140625 * n.y)) + (c[2] * (0.3257350027561187744140625 * n.z))) + (c[3] * (0.3257350027561187744140625 * n.x)))) + (((c[4] * ((0.2731371223926544189453125 * n.x) * n.y)) + (c[5] * ((0.2731371223926544189453125 * n.y) * n.z))) + (c[6] * (0.078847892582416534423828125 * (((3.0 * n.z) * n.z) - 1.0))))) + ((c[7] * ((0.2731371223926544189453125 * n.x) * n.z)) + (c[8] * (0.13656856119632720947265625 * ((n.x * n.x) - (n.y * n.y))))), vec3(0.0));\n    return _3154;\n}\n\nvec3 fa_ambient_light(vec3 n)\n{\n    if (fa_mesh_fs_params[11].w > 0.5)\n    {\n        vec3 c[9];\n        for (int k = 0; k < 9; k++)\n        {\n            int param = k;\n            c[k] = fa_sky_sh_coef(param);\n        }\n        vec3 param_1[9] = c;\n        vec3 param_2 = n;\n        return fa_sh_eval(param_1, param_2);\n    }\n    return fa_mesh_fs_params[1].xyz;\n}\n\nvec3 fa_indirect_diffuse(vec3 n)\n{\n    if (fa_lm.z > 0.5)\n    {\n        return textureLod(fa_lightmap_fa_env_smp, fa_lm.xy, 0.0).xyz;\n    }\n    vec3 param = n;\n    return fa_ambient_light(param);\n}\n\nvec3 ambient(SurfaceInput i, Surface s, vec3 ambientColor)\n{\n    return ambientColor;\n}\n\nint fa_cluster_index(int slot, int n)\n{\n    int param = (int(fa_mesh_fs_params[19].x) + int(fa_mesh_fs_params[19].w)) + ((slot + n) >> 2);\n    vec4 t = fa_light_texel(param);\n    return int(t[(slot + n) & 3]);\n}\n\nint fa_cl_light(int n)\n{\n    if (n < fa_cl_ndir)\n    {\n        return n;\n    }\n    int param = fa_cl_slot;\n    int param_1 = n - fa_cl_ndir;\n    return fa_cluster_index(param, param_1);\n}\n\nint fa_light_base(int li)\n{\n    return li * ((fa_mesh_fs_params[1].w > 4.5) ? 8 : 4);\n}\n\nbool fa_light_baked(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 3;\n    return fa_light_texel(param_1).w > 0.5;\n}\n\nfloat fa_light_type(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 1;\n    return fa_light_texel(param_1).w;\n}\n\nvec4 fa_atlas_fetch(vec2 texel)\n{\n    return textureLod(fa_light_atlas_fa_env_smp, texel / vec2(textureSize(fa_light_atlas_fa_env_smp, 0)), 0.0);\n}\n\nvec3 fa_cookie_sample(vec2 tile_origin, vec2 uv)\n{\n    vec2 param = (tile_origin + vec2(1.0)) + (clamp(uv, vec2(0.0), vec2(1.0)) * 254.0);\n    return fa_atlas_fetch(param).xyz;\n}\n\nvec3 fa_area_point(vec3 c, vec3 axis, vec3 ru, vec3 uu, float hx, float hy, float shape, vec3 p, vec3 r)\n{\n    bool _562 = dot(r, r) > 0.5;\n    if (shape > 1.5)\n    {\n        vec3 _575 = (c - (ru * hx)) - p;\n        vec3 _581 = ru * (2.0 * hx);\n        float _587 = max(dot(_581, _581), 9.9999999392252902907785028219223e-09);\n        float _591 = dot(_575, _581);\n        float t = clamp((-_591) / _587, 0.0, 1.0);\n        if (_562)\n        {\n            float _606 = dot(r, _581);\n            float _612 = _587 - (_606 * _606);\n            if (abs(_612) > (9.9999997473787516355514526367188e-06 * _587))\n            {\n                t = clamp(((dot(r, _575) * _606) - _591) / _612, 0.0, 1.0);\n            }\n        }\n        return (p + _575) + (_581 * t);\n    }\n    vec3 q = p;\n    float _644 = dot(r, axis);\n    bool _652;\n    if (_562)\n    {\n        _652 = abs(_644) > 9.9999997473787516355514526367188e-05;\n    }\n    else\n    {\n        _652 = _562;\n    }\n    if (_652)\n    {\n        float _662 = dot(c - p, axis) / _644;\n        if (_662 > 0.0)\n        {\n            q = p + (r * _662);\n        }\n    }\n    vec3 _675 = q - c;\n    vec2 xy = vec2(dot(_675, ru), dot(_675, uu));\n    if (shape > 0.5)\n    {\n        float _690 = length(xy);\n        if (_690 > hx)\n        {\n            xy *= (hx / _690);\n        }\n    }\n    else\n    {\n        xy = clamp(xy, vec2(-hx, -hy), vec2(hx, hy));\n    }\n    return (c + (ru * xy.x)) + (uu * xy.y);\n}\n\nint fa_cube_face(vec3 d)\n{\n    vec3 _333 = abs(d);\n    float _335 = _333.x;\n    float _337 = _333.y;\n    bool _338 = _335 >= _337;\n    bool _346;\n    if (_338)\n    {\n        _346 = _335 >= _333.z;\n    }\n    else\n    {\n        _346 = _338;\n    }\n    int _347;\n    if (_346)\n    {\n        _347 = (d.x > 0.0) ? 0 : 1;\n    }\n    else\n    {\n        int _362;\n        if (_337 >= _333.z)\n        {\n            _362 = (d.y > 0.0) ? 2 : 3;\n        }\n        else\n        {\n            _362 = (d.z > 0.0) ? 4 : 5;\n        }\n        _347 = _362;\n    }\n    return _347;\n}\n\nvoid fa_cube_face_basis(int f, out vec3 fwd, out vec3 up)\n{\n    if (f == 0)\n    {\n        fwd = vec3(1.0, 0.0, 0.0);\n        up = vec3(0.0, 1.0, 0.0);\n    }\n    else\n    {\n        if (f == 1)\n        {\n            fwd = vec3(-1.0, 0.0, 0.0);\n            up = vec3(0.0, 1.0, 0.0);\n        }\n        else\n        {\n            if (f == 2)\n            {\n                fwd = vec3(0.0, 1.0, 0.0);\n                up = vec3(0.0, 0.0, 1.0);\n            }\n            else\n            {\n                if (f == 3)\n                {\n                    fwd = vec3(0.0, -1.0, 0.0);\n                    up = vec3(0.0, 0.0, -1.0);\n                }\n                else\n                {\n                    if (f == 4)\n                    {\n                        fwd = vec3(0.0, 0.0, 1.0);\n                        up = vec3(0.0, 1.0, 0.0);\n                    }\n                    else\n                    {\n                        fwd = vec3(0.0, 0.0, -1.0);\n                        up = vec3(0.0, 1.0, 0.0);\n                    }\n                }\n            }\n        }\n    }\n}\n\nfloat fa_ies_sample(vec2 tile_origin, vec3 d, vec3 axis, vec3 right, vec3 up)\n{\n    float _482 = dot(d, right);\n    float _486 = dot(d, up);\n    float _497;\n    if (((_482 * _482) + (_486 * _486)) > 1.0000000133514319600180897396058e-10)\n    {\n        _497 = atan(_486, _482) * 0.15915493667125701904296875;\n    }\n    else\n    {\n        _497 = 0.0;\n    }\n    vec2 param = tile_origin + vec2(1.0 + ((_497 - floor(_497)) * 64.0), 1.0 + (acos(clamp(dot(d, axis), -1.0, 1.0)) * 10.18591594696044921875));\n    return fa_atlas_fetch(param).x;\n}\n\nLightSample fa_light_sample_n(int li, vec3 world_pos, vec3 n)\n{\n    int param = li;\n    int _728 = fa_light_base(param);\n    bool _732 = fa_mesh_fs_params[1].w > 4.5;\n    int param_1 = _728;\n    vec4 _736 = fa_light_texel(param_1);\n    int param_2 = _728 + 1;\n    vec4 _741 = fa_light_texel(param_2);\n    float _744 = _741.w;\n    float atten = 1.0;\n    float dist = 0.0;\n    fa_light_tint = vec3(1.0);\n    bool _756 = _732 && (_744 > 2.5);\n    fa_light_is_area = _756;\n    bool _758 = _744 < 0.5;\n    vec3 l;\n    if (_758)\n    {\n        l = normalize(_736.xyz);\n        if (_732)\n        {\n            int param_3 = _728 + 6;\n            vec4 _772 = fa_light_texel(param_3);\n            if (_772.z > 0.5)\n            {\n                int param_4 = _728 + 4;\n                vec4 _782 = fa_light_texel(param_4);\n                int param_5 = _728 + 5;\n                vec4 _787 = fa_light_texel(param_5);\n                vec2 param_6 = _772.xy;\n                vec2 param_7 = fract(vec2(dot(world_pos, _782.xyz) * _782.w, (-dot(world_pos, _787.xyz)) * _787.w) + vec2(0.5));\n                fa_light_tint = fa_cookie_sample(param_6, param_7);\n            }\n        }\n    }\n    else\n    {\n        vec3 _817 = _736.xyz;\n        vec3 _819 = _817 - world_pos;\n        vec3 to_light = _819;\n        float _822 = length(_819);\n        float reach = _822;\n        bool front = true;\n        if (_756)\n        {\n            int param_8 = _728 + 7;\n            reach = max(_822 - fa_light_texel(param_8).w, 0.0);\n            int param_9 = _728 + 4;\n            vec4 _846 = fa_light_texel(param_9);\n            int param_10 = _728 + 5;\n            vec4 _851 = fa_light_texel(param_10);\n            int param_11 = _728 + 6;\n            vec4 _856 = fa_light_texel(param_11);\n            float _857 = _856.w;\n            int param_12 = _728 + 2;\n            vec3 _864 = normalize(fa_light_texel(param_12).xyz);\n            bool _866 = _857 > 1.5;\n            bool _874;\n            if (!_866)\n            {\n                _874 = dot(_864, to_light) < 0.0;\n            }\n            else\n            {\n                _874 = _866;\n            }\n            front = _874;\n            vec3 r = vec3(0.0);\n            vec3 _883 = fa_mesh_fs_params[0].xyz - world_pos;\n            bool _887 = dot(n, n) > 0.5;\n            bool _895;\n            if (_887)\n            {\n                _895 = dot(_883, _883) > 9.9999999600419720025001879548654e-13;\n            }\n            else\n            {\n                _895 = _887;\n            }\n            if (_895)\n            {\n                r = reflect(-normalize(_883), normalize(n));\n            }\n            vec3 param_13 = _817;\n            vec3 param_14 = _864;\n            vec3 param_15 = _846.xyz;\n            vec3 param_16 = _851.xyz;\n            float param_17 = _846.w;\n            float param_18 = _851.w;\n            float param_19 = _857;\n            vec3 param_20 = world_pos;\n            vec3 param_21 = r;\n            to_light = fa_area_point(param_13, param_14, param_15, param_16, param_17, param_18, param_19, param_20, param_21) - world_pos;\n        }\n        float _931 = length(to_light);\n        dist = _931;\n        l = to_light / vec3(max(_931, 9.9999997473787516355514526367188e-05));\n        float _945 = reach / max(_736.w, 0.001000000047497451305389404296875);\n        float _951 = clamp(1.0 - (_945 * _945), 0.0, 1.0);\n        float _953;\n        if (front)\n        {\n            _953 = _951 * _951;\n        }\n        else\n        {\n            _953 = 0.0;\n        }\n        atten = _953;\n        bool _964 = _744 < 2.5;\n        if ((_744 > 1.5) && _964)\n        {\n            int param_22 = _728 + 2;\n            vec4 _972 = fa_light_texel(param_22);\n            float _982 = _972.w;\n            int param_23 = _728 + 3;\n            vec4 _987 = fa_light_texel(param_23);\n            float _988 = _987.x;\n            float cos_inner = _988;\n            if (_988 > 1.5)\n            {\n                cos_inner = mix(_982, 1.0, 0.25);\n            }\n            atten *= smoothstep(_982, cos_inner, dot(-l, normalize(_972.xyz)));\n        }\n        if (_732 && (_744 < 1.5))\n        {\n            int param_24 = _728 + 6;\n            vec4 _1012 = fa_light_texel(param_24);\n            if (_1012.z > 0.5)\n            {\n                vec3 _1020 = -to_light;\n                int param_25 = _728 + 4;\n                int param_26 = _728 + 5;\n                vec3 _1034 = fa_light_texel(param_25).xyz;\n                vec3 _1038 = fa_light_texel(param_26).xyz;\n                vec3 _1047 = vec3(dot(_1020, _1034), dot(_1020, _1038), dot(_1020, cross(_1034, _1038)));\n                vec3 param_27 = _1047;\n                int _1051 = fa_cube_face(param_27);\n                int param_28 = _1051;\n                vec3 param_29;\n                vec3 param_30;\n                fa_cube_face_basis(param_28, param_29, param_30);\n                vec2 _1078 = vec2(dot(_1047, cross(param_29, param_30)), dot(_1047, param_30)) / vec2(max(dot(_1047, param_29), 9.9999997473787516355514526367188e-05));\n                int _1082 = _1051 / 3;\n                vec2 param_31 = _1012.xy + (vec2(float(_1051 - (_1082 * 3)), float(_1082)) * 256.0);\n                vec2 param_32 = vec2(0.5 + (0.5 * _1078.x), 0.5 - (0.5 * _1078.y));\n                fa_light_tint = fa_cookie_sample(param_31, param_32);\n            }\n            int param_33 = _728 + 7;\n            vec4 _1112 = fa_light_texel(param_33);\n            if (_1112.z > 0.5)\n            {\n                int param_34 = _728 + 2;\n                int param_35 = _728 + 4;\n                int param_36 = _728 + 5;\n                vec2 param_37 = _1112.xy;\n                vec3 param_38 = -l;\n                vec3 param_39 = normalize(fa_light_texel(param_34).xyz);\n                vec3 param_40 = fa_light_texel(param_35).xyz;\n                vec3 param_41 = fa_light_texel(param_36).xyz;\n                atten *= fa_ies_sample(param_37, param_38, param_39, param_40, param_41);\n            }\n        }\n        else\n        {\n            if (_732 && _964)\n            {\n                int param_42 = _728 + 6;\n                vec4 _1159 = fa_light_texel(param_42);\n                int param_43 = _728 + 7;\n                vec4 _1164 = fa_light_texel(param_43);\n                bool _1167 = _1159.z > 0.5;\n                bool _1174;\n                if (!_1167)\n                {\n                    _1174 = _1164.z > 0.5;\n                }\n                else\n                {\n                    _1174 = _1167;\n                }\n                if (_1174)\n                {\n                    int param_44 = _728 + 2;\n                    vec4 _1181 = fa_light_texel(param_44);\n                    vec3 _1185 = normalize(_1181.xyz);\n                    int param_45 = _728 + 4;\n                    vec4 _1190 = fa_light_texel(param_45);\n                    int param_46 = _728 + 5;\n                    vec4 _1195 = fa_light_texel(param_46);\n                    if (_1167)\n                    {\n                        vec3 _1203 = -to_light;\n                        float _1210 = _1181.w;\n                        float _1226 = 0.5 / max(dot(_1203, _1185) * (sqrt(max(1.0 - (_1210 * _1210), 0.0)) / max(_1210, 0.001000000047497451305389404296875)), 9.9999997473787516355514526367188e-05);\n                        vec2 param_47 = _1159.xy;\n                        vec2 param_48 = vec2(0.5 + (dot(_1203, _1190.xyz) * _1226), 0.5 - (dot(_1203, _1195.xyz) * _1226));\n                        fa_light_tint = fa_cookie_sample(param_47, param_48);\n                    }\n                    if (_1164.z > 0.5)\n                    {\n                        vec2 param_49 = _1164.xy;\n                        vec3 param_50 = -l;\n                        vec3 param_51 = _1185;\n                        vec3 param_52 = _1190.xyz;\n                        vec3 param_53 = _1195.xyz;\n                        atten *= fa_ies_sample(param_49, param_50, param_51, param_52, param_53);\n                    }\n                }\n            }\n        }\n    }\n    vec3 _4306 = _741.xyz * atten;\n    if (_732)\n    {\n        _4306 *= fa_light_tint;\n    }\n    int _1294;\n    if (_758)\n    {\n        _1294 = 0;\n    }\n    else\n    {\n        _1294 = ((_744 > 1.5) && (_744 < 2.5)) ? 2 : 1;\n    }\n    return LightSample(l, _4306, atten, 1.0, dist, _1294);\n}\n\nfloat fa_shadow_split_at(int i)\n{\n    float _2031;\n    if (i == 0)\n    {\n        _2031 = fa_shadows[24].x;\n    }\n    else\n    {\n        float _2047;\n        if (i == 1)\n        {\n            _2047 = fa_shadows[24].y;\n        }\n        else\n        {\n            float _2055;\n            if (i == 2)\n            {\n                _2055 = fa_shadows[24].z;\n            }\n            else\n            {\n                _2055 = fa_shadows[24].w;\n            }\n            _2047 = _2055;\n        }\n        _2031 = _2047;\n    }\n    return _2031;\n}\n\nfloat fa_shadow_depth(inout vec2 uv, vec4 rect)\n{\n    uv = clamp(uv, rect.xy, rect.zw);\n    return textureLod(fa_shadow_tex_fa_shadow_smp, uv, 0.0).x;\n}\n\nfloat fa_shadow_fetch(vec2 uv, vec4 rect, vec3 conv)\n{\n    vec2 param = uv;\n    vec4 param_1 = rect;\n    float _2088 = fa_shadow_depth(param, param_1);\n    float _2092;\n    if (conv.x < 0.5)\n    {\n        _2092 = _2088;\n    }\n    else\n    {\n        _2092 = (conv.y * conv.z) / (conv.z - (_2088 * (conv.z - conv.y)));\n    }\n    return _2092;\n}\n\nfloat fa_shadow_noise()\n{\n    return fract(52.98291778564453125 * fract(dot(gl_FragCoord.xy, vec2(0.067110560834407806396484375, 0.005837149918079376220703125))));\n}\n\nvec2 fa_shadow_vogel(int k, int n, float phi)\n{\n    float _2019 = (float(k) * 2.3999631404876708984375) + phi;\n    return vec2(cos(_2019), sin(_2019)) * sqrt((float(k) + 0.5) / float(n));\n}\n\nfloat fa_shadow_filter(vec2 uv, vec4 rect, float zr, float texel_m, float unit, float reach, float plane, vec3 conv, int mode, float k)\n{\n    if (mode == 1)\n    {\n        vec2 param = uv;\n        vec4 param_1 = rect;\n        vec3 param_2 = conv;\n        return float(zr <= fa_shadow_fetch(param, param_1, param_2));\n    }\n    float _2138 = fa_shadow_noise() * 6.283185482025146484375;\n    float radius = 1.5;\n    if (mode == 2)\n    {\n        float _2147;\n        if (k < 0.0)\n        {\n            _2147 = (-k) / max(zr, 0.100000001490116119384765625);\n        }\n        else\n        {\n            _2147 = k;\n        }\n        float _2167 = clamp((_2147 * reach) / texel_m, 3.0, 12.0);\n        float sum = 0.0;\n        float cnt = 0.0;\n        for (int i = 0; i < 16; i++)\n        {\n            int param_3 = i;\n            int param_4 = 16;\n            float param_5 = _2138;\n            vec2 _2186 = fa_shadow_vogel(param_3, param_4, param_5) * _2167;\n            vec2 param_6 = uv + (_2186 * fa_shadows[26].zw);\n            vec4 param_7 = rect;\n            vec3 param_8 = conv;\n            float _2198 = fa_shadow_fetch(param_6, param_7, param_8);\n            if (_2198 < (zr - (length(_2186) * plane)))\n            {\n                sum += _2198;\n                cnt += 1.0;\n            }\n        }\n        if (cnt < 0.5)\n        {\n            return 1.0;\n        }\n        float _2224 = sum / cnt;\n        float _2234;\n        if (k < 0.0)\n        {\n            _2234 = (-k) / max(_2224, 0.0500000007450580596923828125);\n        }\n        else\n        {\n            _2234 = k;\n        }\n        radius = clamp(((max(zr - _2224, 0.0) * unit) * _2234) / texel_m, 1.5, 16.0);\n    }\n    float lit = 0.0;\n    int _2256 = (mode == 2) ? 24 : 16;\n    for (int i_1 = 0; i_1 < _2256; i_1++)\n    {\n        int param_9 = i_1;\n        int param_10 = _2256;\n        float param_11 = _2138;\n        vec2 _2275 = fa_shadow_vogel(param_9, param_10, param_11) * radius;\n        vec2 param_12 = uv + (_2275 * fa_shadows[26].zw);\n        vec4 param_13 = rect;\n        vec3 param_14 = conv;\n        lit += float((zr - (length(_2275) * plane)) <= fa_shadow_fetch(param_12, param_13, param_14));\n    }\n    return lit / float(_2256);\n}\n\nfloat fa_shadow_cascade(int ci, vec3 world, vec3 n, vec3 l)\n{\n    float _2317 = max(fa_shadows[ci * 1 + 20].y, 0.001000000047497451305389404296875);\n    float _2322 = clamp(dot(n, l), 0.0, 1.0);\n    float _2328 = sqrt(1.0 - (_2322 * _2322));\n    float _2335 = min(_2328 / max(_2322, 0.20000000298023223876953125), 4.0);\n    float _2340;\n    if (fa_shadows[26].y > 0.0)\n    {\n        _2340 = fa_shadows[26].y;\n    }\n    else\n    {\n        _2340 = 1.5 * fa_shadows[ci * 1 + 20].x;\n    }\n    vec4 _2365 = mat4(fa_shadows[ci * 4 + 0], fa_shadows[ci * 4 + 1], fa_shadows[ci * 4 + 2], fa_shadows[ci * 4 + 3]) * vec4(world + (n * (_2340 * _2328)), 1.0);\n    float _2372 = _2365.x;\n    bool _2375 = _2372 < fa_shadows[ci * 1 + 16].x;\n    bool _2384;\n    if (!_2375)\n    {\n        _2384 = _2372 > fa_shadows[ci * 1 + 16].z;\n    }\n    else\n    {\n        _2384 = _2375;\n    }\n    bool _2393;\n    if (!_2384)\n    {\n        _2393 = _2365.y < fa_shadows[ci * 1 + 16].y;\n    }\n    else\n    {\n        _2393 = _2384;\n    }\n    bool _2402;\n    if (!_2393)\n    {\n        _2402 = _2365.y > fa_shadows[ci * 1 + 16].w;\n    }\n    else\n    {\n        _2402 = _2393;\n    }\n    bool _2409;\n    if (!_2402)\n    {\n        _2409 = _2365.z > 1.0;\n    }\n    else\n    {\n        _2409 = _2402;\n    }\n    if (_2409)\n    {\n        return -1.0;\n    }\n    float _2417;\n    if (fa_shadows[26].x > 0.0)\n    {\n        _2417 = fa_shadows[26].x;\n    }\n    else\n    {\n        _2417 = 1.5 * fa_shadows[ci * 1 + 20].x;\n    }\n    vec2 param = _2365.xy;\n    vec4 param_1 = fa_shadows[ci * 1 + 16];\n    float param_2 = _2365.z - ((_2417 * (1.0 + (0.5 * _2335))) / _2317);\n    float param_3 = fa_shadows[ci * 1 + 20].x;\n    float param_4 = _2317;\n    float param_5 = _2317 * 0.25;\n    float param_6 = ((fa_shadows[ci * 1 + 20].x * min(_2335, 3.0)) * 0.5) / _2317;\n    vec3 param_7 = vec3(0.0);\n    int param_8 = int(fa_shadows[25].z + 0.5);\n    float param_9 = fa_shadows[25].w;\n    return fa_shadow_filter(param, param_1, param_2, param_3, param_4, param_5, param_6, param_7, param_8, param_9);\n}\n\nfloat fa_shadow_sun(vec3 world, vec3 n, vec3 l)\n{\n    if (fa_mesh_fs_params[5].z < 0.5)\n    {\n        return 1.0;\n    }\n    int _2795 = int(fa_shadows[25].x + 0.5);\n    if (_2795 < 1)\n    {\n        return 1.0;\n    }\n    float _2810 = dot(world - fa_shadows[27].xyz, fa_shadows[28].xyz);\n    int param = _2795 - 1;\n    if (_2810 > fa_shadow_split_at(param))\n    {\n        return 1.0;\n    }\n    int ci = 0;\n    bool _2822 = _2795 > 1;\n    bool _2829;\n    if (_2822)\n    {\n        _2829 = _2810 > fa_shadows[24].x;\n    }\n    else\n    {\n        _2829 = _2822;\n    }\n    if (_2829)\n    {\n        ci = 1;\n    }\n    bool _2833 = _2795 > 2;\n    bool _2840;\n    if (_2833)\n    {\n        _2840 = _2810 > fa_shadows[24].y;\n    }\n    else\n    {\n        _2840 = _2833;\n    }\n    if (_2840)\n    {\n        ci = 2;\n    }\n    bool _2844 = _2795 > 3;\n    bool _2851;\n    if (_2844)\n    {\n        _2851 = _2810 > fa_shadows[24].z;\n    }\n    else\n    {\n        _2851 = _2844;\n    }\n    if (_2851)\n    {\n        ci = 3;\n    }\n    float s = -1.0;\n    for (int k = 0; k < 4; k++)\n    {\n        if (ci >= _2795)\n        {\n            break;\n        }\n        int param_1 = ci;\n        vec3 param_2 = world;\n        vec3 param_3 = n;\n        vec3 param_4 = l;\n        float _2877 = fa_shadow_cascade(param_1, param_2, param_3, param_4);\n        s = _2877;\n        if (_2877 >= 0.0)\n        {\n            break;\n        }\n        ci++;\n    }\n    if (s < 0.0)\n    {\n        return 1.0;\n    }\n    if (fa_shadows[25].y > 0.0)\n    {\n        float _2902;\n        if (ci > 0)\n        {\n            int param_5 = ci - 1;\n            _2902 = fa_shadow_split_at(param_5);\n        }\n        else\n        {\n            _2902 = fa_shadows[28].w;\n        }\n        int param_6 = ci;\n        float _2921 = fa_shadows[25].y * max(fa_shadow_split_at(param_6) - _2902, 9.9999997473787516355514526367188e-05);\n        int param_7 = ci;\n        float _2932 = clamp((_2810 - (fa_shadow_split_at(param_7) - _2921)) / _2921, 0.0, 1.0);\n        if (_2932 > 0.0)\n        {\n            float s2 = 1.0;\n            if ((ci + 1) < _2795)\n            {\n                int param_8 = ci + 1;\n                vec3 param_9 = world;\n                vec3 param_10 = n;\n                vec3 param_11 = l;\n                float _2953 = fa_shadow_cascade(param_8, param_9, param_10, param_11);\n                s2 = _2953;\n                if (_2953 < 0.0)\n                {\n                    s2 = s;\n                }\n            }\n            s = mix(s, s2, _2932);\n        }\n    }\n    return s;\n}\n\nfloat fa_shadow_factor(vec3 n, vec3 l)\n{\n    vec3 param = fa_world_pos;\n    vec3 param_1 = n;\n    vec3 param_2 = l;\n    return fa_shadow_sun(param, param_1, param_2);\n}\n\nfloat fa_shadow_local(int li, vec3 lpos, vec3 world, vec3 n, vec3 l)\n{\n    bool _2475 = fa_mesh_fs_params[5].z < 0.5;\n    bool _2482;\n    if (!_2475)\n    {\n        _2482 = fa_shadows[29].x < 0.5;\n    }\n    else\n    {\n        _2482 = _2475;\n    }\n    if (_2482)\n    {\n        return 1.0;\n    }\n    int param = (int(fa_shadows[29].x + 0.5) - 1) + li;\n    vec4 _2495 = fa_light_texel(param);\n    float _2496 = _2495.x;\n    if (_2496 < 0.0)\n    {\n        return 1.0;\n    }\n    int _2505 = int(_2496 + 0.5);\n    int param_1 = _2505;\n    vec4 _2509 = fa_light_texel(param_1);\n    int param_2 = _2505 + 1;\n    vec4 _2514 = fa_light_texel(param_2);\n    float fade = 1.0;\n    float _2517 = _2509.y;\n    if (_2517 > 0.0)\n    {\n        float _2534 = 1.0 - smoothstep(0.75 * _2517, _2517, length(world - fa_shadows[27].xyz));\n        fade = _2534;\n        if (_2534 <= 0.0)\n        {\n            return 1.0;\n        }\n    }\n    int face = 0;\n    if (_2509.x > 1.5)\n    {\n        vec3 param_3 = world - lpos;\n        face = fa_cube_face(param_3);\n    }\n    int _2558 = (_2505 + 2) + (face * 6);\n    int param_4 = _2558;\n    int param_5 = _2558 + 1;\n    int param_6 = _2558 + 3;\n    vec4 _2572 = fa_light_texel(param_6);\n    int param_7 = _2558 + 4;\n    vec4 _2577 = fa_light_texel(param_7);\n    int param_8 = _2558 + 5;\n    vec4 _2582 = fa_light_texel(param_8);\n    float _2594 = _2582.x * max(dot(_2572, vec4(world, 1.0)), 0.001000000047497451305389404296875);\n    float _2599 = clamp(dot(n, l), 0.0, 1.0);\n    float _2622 = clamp(dot(n, _2572.xyz), -1.0, 1.0);\n    float _2641 = min(sqrt(1.0 - (_2622 * _2622)) / max(abs(dot(n, world - lpos)) / max(dot(_2572, vec4(world, 1.0)), 0.001000000047497451305389404296875), 0.20000000298023223876953125), 4.0);\n    float _2644 = _2514.y;\n    float _2646;\n    if (_2644 > 0.0)\n    {\n        _2646 = _2644;\n    }\n    else\n    {\n        _2646 = 1.5 * _2594;\n    }\n    vec4 _2666 = vec4(world + (n * (_2646 * sqrt(1.0 - (_2599 * _2599)))), 1.0);\n    float _2670 = dot(_2572, _2666);\n    float _2673 = _2582.y;\n    if (_2670 < _2673)\n    {\n        return 1.0;\n    }\n    vec2 _2688 = vec2(dot(fa_light_texel(param_4), _2666), dot(fa_light_texel(param_5), _2666)) / vec2(_2670);\n    float _2690 = _2688.x;\n    bool _2693 = _2690 < _2577.x;\n    bool _2702;\n    if (!_2693)\n    {\n        _2702 = _2690 > _2577.z;\n    }\n    else\n    {\n        _2702 = _2693;\n    }\n    bool _2711;\n    if (!_2702)\n    {\n        _2711 = _2688.y < _2577.y;\n    }\n    else\n    {\n        _2711 = _2702;\n    }\n    bool _2720;\n    if (!_2711)\n    {\n        _2720 = _2688.y > _2577.w;\n    }\n    else\n    {\n        _2720 = _2711;\n    }\n    if (_2720)\n    {\n        return 1.0;\n    }\n    float _2726 = _2514.x;\n    float _2728;\n    if (_2726 > 0.0)\n    {\n        _2728 = _2726;\n    }\n    else\n    {\n        _2728 = 1.5 * _2594;\n    }\n    vec2 param_9 = _2688;\n    vec4 param_10 = _2577;\n    float param_11 = _2670 - (_2728 * (1.0 + (0.5 * _2641)));\n    float param_12 = _2594;\n    float param_13 = 1.0;\n    float param_14 = _2582.z * 0.25;\n    float param_15 = (_2594 * min(_2641, 3.0)) * 0.5;\n    vec3 param_16 = vec3(1.0, _2673, _2582.z);\n    int param_17 = int(_2509.z + 0.5);\n    float param_18 = _2509.w;\n    return mix(1.0, fa_shadow_filter(param_9, param_10, param_11, param_12, param_13, param_14, param_15, param_16, param_17, param_18), fade);\n}\n\nLightSample fa_light_shadowed(int li, vec3 world_pos, vec3 gn)\n{\n    bool _3268 = fa_lm.z > 0.5;\n    bool _3274;\n    if (_3268)\n    {\n        int param = li;\n        _3274 = fa_light_baked(param);\n    }\n    else\n    {\n        _3274 = _3268;\n    }\n    if (_3274)\n    {\n        int param_1 = li;\n        return LightSample(vec3(0.0, 1.0, 0.0), vec3(0.0), 0.0, 1.0, 0.0, int(fa_light_type(param_1) + 0.5));\n    }\n    int param_2 = li;\n    vec3 param_3 = world_pos;\n    vec3 param_4 = gn;\n    LightSample _3298 = fa_light_sample_n(param_2, param_3, param_4);\n    vec3 _4332 = _3298.color;\n    float _4334 = _3298.shadow;\n    if ((_3298.type == 0) && (li == 0))\n    {\n        vec3 param_5 = gn;\n        vec3 param_6 = _3298.direction;\n        float _3312 = fa_shadow_factor(param_5, param_6);\n        _4334 = _3312;\n        _4332 *= _3312;\n    }\n    else\n    {\n        bool _3323 = _3298.type != 0;\n        bool _3329;\n        if (_3323)\n        {\n            _3329 = _3298.attenuation > 0.0;\n        }\n        else\n        {\n            _3329 = _3323;\n        }\n        if (_3329)\n        {\n            int param_7 = li;\n            int param_8 = fa_light_base(param_7);\n            int param_9 = li;\n            vec3 param_10 = fa_light_texel(param_8).xyz;\n            vec3 param_11 = world_pos;\n            vec3 param_12 = gn;\n            vec3 param_13 = _3298.direction;\n            float _3348 = fa_shadow_local(param_9, param_10, param_11, param_12, param_13);\n            _4334 = _3348;\n            _4332 *= _3348;\n        }\n    }\n    return LightSample(_3298.direction, _4332, _3298.attenuation, _4334, _3298._distance, _3298.type);\n}\n\nvec3 light(SurfaceInput i, Surface s, LightSample l)\n{\n    return vec3(0.0);\n}\n\nvec3 fa_shadow_debug(vec3 color, vec3 world)\n{\n    if (fa_shadows[27].w < 0.5)\n    {\n        return color;\n    }\n    int _2977 = int(fa_shadows[25].x + 0.5);\n    float _2987 = dot(world - fa_shadows[27].xyz, fa_shadows[28].xyz);\n    vec3 tint = vec3(0.3499999940395355224609375);\n    bool _2992 = _2977 > 0;\n    bool _3001;\n    if (_2992)\n    {\n        int param = _2977 - 1;\n        _3001 = _2987 <= fa_shadow_split_at(param);\n    }\n    else\n    {\n        _3001 = _2992;\n    }\n    if (_3001)\n    {\n        tint = vec3(1.0, 0.1500000059604644775390625, 0.100000001490116119384765625);\n        bool _3007 = _2977 > 1;\n        bool _3014;\n        if (_3007)\n        {\n            _3014 = _2987 > fa_shadows[24].x;\n        }\n        else\n        {\n            _3014 = _3007;\n        }\n        if (_3014)\n        {\n            tint = vec3(0.100000001490116119384765625, 0.89999997615814208984375, 0.20000000298023223876953125);\n        }\n        bool _3020 = _2977 > 2;\n        bool _3027;\n        if (_3020)\n        {\n            _3027 = _2987 > fa_shadows[24].y;\n        }\n        else\n        {\n            _3027 = _3020;\n        }\n        if (_3027)\n        {\n            tint = vec3(0.1500000059604644775390625, 0.300000011920928955078125, 1.0);\n        }\n        bool _3033 = _2977 > 3;\n        bool _3040;\n        if (_3033)\n        {\n            _3040 = _2987 > fa_shadows[24].z;\n        }\n        else\n        {\n            _3040 = _3033;\n        }\n        if (_3040)\n        {\n            tint = vec3(1.0, 0.89999997615814208984375, 0.100000001490116119384765625);\n        }\n    }\n    return mix(color, tint, vec3(0.550000011920928955078125));\n}\n\nvoid main()\n{\n    fa_inst_load();\n    vec3 _4148 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _4148 = -_4148;\n    }\n    vec3 _3733 = normalize(fa_mesh_fs_params[0].xyz - fa_world_pos);\n    vec3 param = fa_world_pos;\n    fa_cluster_begin(param);\n    SurfaceInput param_1 = SurfaceInput(fa_world_pos, _4148, fa_world_tangent, fa_uv, fa_vertex_color, _3733, gl_FrontFacing);\n    Surface _3741 = fa_standard_surface(param_1);\n    vec3 _4187 = _3741.albedo;\n    float _4188 = _3741.alpha;\n    vec3 _4189 = _3741.normal;\n    float _4190 = _3741.metallic;\n    float _4191 = _3741.roughness;\n    float _4192 = _3741.occlusion;\n    vec3 _4193 = _3741.emission;\n    float _4194 = _3741.clearcoat;\n    float _4195 = _3741.clearcoat_roughness;\n    vec3 _4196 = _3741.sheen_color;\n    float _4197 = _3741.sheen_roughness;\n    float _4198 = _3741.anisotropy;\n    float _4199 = _3741.anisotropy_rotation;\n    float _4200 = _3741.specular;\n    float _4201 = _3741.ior;\n    vec3 _4202 = _3741.specular_color;\n    SurfaceInput param_2 = SurfaceInput(fa_world_pos, _4148, fa_world_tangent, fa_uv, fa_vertex_color, _3733, gl_FrontFacing);\n    Surface param_3 = _3741;\n    surface(param_2, param_3);\n    _4187 = param_3.albedo;\n    _4188 = param_3.alpha;\n    _4189 = param_3.normal;\n    _4190 = param_3.metallic;\n    _4191 = param_3.roughness;\n    _4192 = param_3.occlusion;\n    _4193 = param_3.emission;\n    _4194 = param_3.clearcoat;\n    _4195 = param_3.clearcoat_roughness;\n    _4196 = param_3.sheen_color;\n    _4197 = param_3.sheen_roughness;\n    _4198 = param_3.anisotropy;\n    _4199 = param_3.anisotropy_rotation;\n    _4200 = param_3.specular;\n    _4201 = param_3.ior;\n    _4202 = param_3.specular_color;\n    vec3 param_4 = fa_world_pos;\n    vec3 param_5 = _4148;\n    vec3 param_6 = param_3.albedo;\n    vec3 param_7 = param_3.normal;\n    fa_apply_decals(param_4, param_5, param_6, param_7);\n    _4187 = param_6;\n    _4189 = param_7;\n    vec3 result;\n    if (fa_mesh_fs_params[3].w > 0.5)\n    {\n        result = _4187;\n    }\n    else\n    {\n        vec3 _3779 = _4189;\n        vec3 _3780 = normalize(_3779);\n        _4189 = _3780;\n        vec3 param_8 = _3780;\n        SurfaceInput param_9 = SurfaceInput(fa_world_pos, _4148, fa_world_tangent, fa_uv, fa_vertex_color, _3733, gl_FrontFacing);\n        Surface param_10 = Surface(_4187, _4188, _4189, _4190, _4191, _4192, _4193, _4194, _4195, _4196, _4197, _4198, _4199, _4200, _4201, _4202);\n        vec3 param_11 = fa_indirect_diffuse(param_8);\n        vec3 lit = ambient(param_9, param_10, param_11);\n        int _3799 = fa_cl_ndir + fa_cl_local;\n        for (int ln = 0; ln < _3799; ln++)\n        {\n            int param_12 = ln;\n            int _3812 = fa_cl_light(param_12);\n            bool _3815 = fa_lm.z > 0.5;\n            bool _3821;\n            if (_3815)\n            {\n                int param_13 = _3812;\n                _3821 = fa_light_baked(param_13);\n            }\n            else\n            {\n                _3821 = _3815;\n            }\n            if (_3821)\n            {\n                continue;\n            }\n            int param_14 = _3812;\n            vec3 param_15 = fa_world_pos;\n            vec3 param_16 = _4148;\n            LightSample _3833 = fa_light_shadowed(param_14, param_15, param_16);\n            SurfaceInput param_17 = SurfaceInput(fa_world_pos, _4148, fa_world_tangent, fa_uv, fa_vertex_color, _3733, gl_FrontFacing);\n            Surface param_18 = Surface(_4187, _4188, _4189, _4190, _4191, _4192, _4193, _4194, _4195, _4196, _4197, _4198, _4199, _4200, _4201, _4202);\n            LightSample param_19 = _3833;\n            lit += light(param_17, param_18, param_19);\n        }\n        result = lit;\n    }\n    vec3 _3848 = result;\n    vec3 _3849 = _3848 + _4193;\n    result = _3849;\n    vec3 param_20 = _3849;\n    vec3 param_21 = fa_world_pos;\n    result = fa_shadow_debug(param_20, param_21);\n    bool _3858 = fa_mesh_fs_params[7].w > 0.0;\n    bool _3865;\n    if (!_3858)\n    {\n        _3865 = fa_mesh_fs_params[8].y > 0.0;\n    }\n    else\n    {\n        _3865 = _3858;\n    }\n    if (_3865)\n    {\n        vec3 _3874 = fa_world_pos - fa_mesh_fs_params[0].xyz;\n        float _3880 = dot(_3874, fa_mesh_fs_params[9].xyz);\n        bool _3884 = fa_mesh_fs_params[9].w > 0.5;\n        float _3885;\n        if (_3884)\n        {\n            _3885 = _3880;\n        }\n        else\n        {\n            _3885 = length(_3874);\n        }\n        float _3897 = _3885 - fa_mesh_fs_params[8].x;\n        if (_3897 > 0.0)\n        {\n            float _3906 = fa_mesh_fs_params[7].w * _3897;\n            float tau = _3906 * _3906;\n            if (fa_mesh_fs_params[8].y > 0.0)\n            {\n                float _3922;\n                if (_3884)\n                {\n                    _3922 = fa_world_pos.y - (fa_mesh_fs_params[9].y * _3880);\n                }\n                else\n                {\n                    _3922 = fa_mesh_fs_params[0].y;\n                }\n                float _3943 = mix(_3922, fa_world_pos.y, clamp(fa_mesh_fs_params[8].x / _3885, 0.0, 1.0));\n                float _3947 = fa_world_pos.y - _3943;\n                float _3952 = _3943 - fa_mesh_fs_params[8].z;\n                float _3957 = fa_world_pos.y - fa_mesh_fs_params[8].z;\n                bool _3960 = _3952 <= 0.0;\n                bool _3961 = !_3960;\n                bool _3967;\n                if (_3961)\n                {\n                    _3967 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _3967 = _3960;\n                }\n                float _3968;\n                if (_3967)\n                {\n                    _3968 = fa_mesh_fs_params[8].y;\n                }\n                else\n                {\n                    _3968 = fa_mesh_fs_params[8].y * exp(-min(fa_mesh_fs_params[8].w * _3952, 80.0));\n                }\n                bool _3995;\n                if (_3961)\n                {\n                    _3995 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _3995 = _3960;\n                }\n                float _3996;\n                if (_3995)\n                {\n                    _3996 = fa_mesh_fs_params[8].y * _3952;\n                }\n                else\n                {\n                    _3996 = (fa_mesh_fs_params[8].y * (1.0 - exp(-min(fa_mesh_fs_params[8].w * _3952, 80.0)))) / fa_mesh_fs_params[8].w;\n                }\n                bool _4021 = _3957 <= 0.0;\n                bool _4028;\n                if (!_4021)\n                {\n                    _4028 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _4028 = _4021;\n                }\n                float _4029;\n                if (_4028)\n                {\n                    _4029 = fa_mesh_fs_params[8].y * _3957;\n                }\n                else\n                {\n                    _4029 = (fa_mesh_fs_params[8].y * (1.0 - exp(-min(fa_mesh_fs_params[8].w * _3957, 80.0)))) / fa_mesh_fs_params[8].w;\n                }\n                float _4056;\n                if (abs(_3947) < 0.001000000047497451305389404296875)\n                {\n                    _4056 = _3968;\n                }\n                else\n                {\n                    _4056 = (_4029 - _3996) / _3947;\n                }\n                tau += (_3897 * max(_4056, 0.0));\n            }\n            result = mix(result, fa_mesh_fs_params[7].xyz, vec3(clamp(1.0 - exp(-clamp(tau, 0.0, 80.0)), 0.0, 1.0)));\n        }\n    }\n    fa_frag_color = vec4(result, _4188);\n}\n\n",
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
            "inst_name": "_384",
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
            "inst_name": "_2041",
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
      "vs": "#version 430\n\nstruct VertexData\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 color;\n    vec3 object_pos;\n};\n\nuniform vec4 fa_mesh_vs_params[11];\nuniform vec4 fa_skin[192];\nlayout(location = 0) out vec3 fa_world_pos;\nlayout(location = 1) out vec3 fa_world_normal;\nlayout(location = 2) out vec4 fa_world_tangent;\nlayout(location = 3) out vec2 fa_uv;\nlayout(location = 4) out vec4 fa_vertex_color;\nlayout(location = 5) in vec4 fa_inst_m0;\nlayout(location = 6) in vec4 fa_inst_m1;\nlayout(location = 7) in vec4 fa_inst_m2;\nlayout(location = 8) in vec4 fa_inst_m3;\nlayout(location = 9) in vec4 fa_joints;\nlayout(location = 10) in vec4 fa_weights;\nlayout(location = 0) in vec3 fa_position;\nlayout(location = 1) in vec3 fa_normal;\nlayout(location = 3) in vec4 fa_tangent;\nlayout(location = 2) in vec2 fa_texcoord0;\nlayout(location = 4) in vec4 fa_color;\nlayout(location = 5) out vec3 fa_lm;\n\nvoid fa_inst_begin()\n{\n}\n\nmat4 fa_skin_matrix(vec4 joints, vec4 weights)\n{\n    vec4 r0 = vec4(0.0);\n    vec4 r1 = vec4(0.0);\n    vec4 r2 = vec4(0.0);\n    for (int i = 0; i < 4; i++)\n    {\n        int _174 = int((joints[i] * 255.0) + 0.5) * 3;\n        r0 += (fa_skin[_174 * 1 + 0] * weights[i]);\n        r1 += (fa_skin[(_174 + 1) * 1 + 0] * weights[i]);\n        r2 += (fa_skin[(_174 + 2) * 1 + 0] * weights[i]);\n    }\n    return mat4(vec4(r0.x, r1.x, r2.x, 0.0), vec4(r0.y, r1.y, r2.y, 0.0), vec4(r0.z, r1.z, r2.z, 0.0), vec4(r0.w, r1.w, r2.w, 1.0));\n}\n\nVertexData fa_vertex_data(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    vec3 _74 = cross(model[1].xyz, model[2].xyz);\n    float _80 = (dot(model[0].xyz, _74) < 0.0) ? (-1.0) : 1.0;\n    return VertexData((model * vec4(position, 1.0)).xyz, (((_74 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _80, vec4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _80), texcoord0 * fa_mesh_vs_params[8].xy, color, position);\n}\n\nvoid fa_shade_vertex(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    mat4 param = model;\n    vec3 param_1 = position;\n    vec3 param_2 = normal;\n    vec4 param_3 = tangent;\n    vec2 param_4 = texcoord0;\n    vec4 param_5 = color;\n    VertexData _273 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    vec3 _388 = _273.world_pos;\n    fa_world_pos = _388;\n    fa_world_normal = _273.world_normal;\n    fa_world_tangent = _273.world_tangent;\n    fa_uv = _273.uv;\n    fa_vertex_color = _273.color;\n    gl_Position = mat4(fa_mesh_vs_params[0], fa_mesh_vs_params[1], fa_mesh_vs_params[2], fa_mesh_vs_params[3]) * vec4(_388, 1.0);\n}\n\nvoid main()\n{\n    fa_inst_begin();\n    vec4 param = fa_joints;\n    vec4 param_1 = fa_weights;\n    mat4 param_2 = mat4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3) * fa_skin_matrix(param, param_1);\n    vec3 param_3 = fa_position;\n    vec3 param_4 = fa_normal;\n    vec4 param_5 = fa_tangent;\n    vec2 param_6 = fa_texcoord0;\n    vec4 param_7 = fa_color;\n    fa_shade_vertex(param_2, param_3, param_4, param_5, param_6, param_7);\n    fa_lm = vec3(0.0);\n}\n\n",
      "fs": "#version 430\n\nstruct SurfaceInput\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 vertex_color;\n    vec3 view_dir;\n    bool front_facing;\n};\n\nstruct LightSample\n{\n    vec3 direction;\n    vec3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct Surface\n{\n    vec3 albedo;\n    float alpha;\n    vec3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    vec3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    vec3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    vec3 specular_color;\n};\n\nuniform vec4 fa_mesh_fs_params[24];\nuniform vec4 fa_shadows[30];\nlayout(binding = 0) uniform sampler2D fa_light_tex_fa_shadow_smp;\nlayout(binding = 1) uniform sampler2D fa_tex_fa_smp;\nlayout(binding = 2) uniform sampler2D fa_normal_tex_fa_smp;\nlayout(binding = 3) uniform sampler2D fa_mr_tex_fa_smp;\nlayout(binding = 4) uniform sampler2D fa_occlusion_tex_fa_smp;\nlayout(binding = 5) uniform sampler2D fa_emissive_tex_fa_smp;\nlayout(binding = 6) uniform sampler2D fa_decal_tex_fa_env_smp;\nlayout(binding = 7) uniform sampler2D fa_lightmap_fa_env_smp;\nlayout(binding = 8) uniform samplerCube fa_env_tex_fa_env_smp;\nlayout(binding = 9) uniform sampler2D fa_light_atlas_fa_env_smp;\nlayout(binding = 10) uniform sampler2D fa_shadow_tex_fa_shadow_smp;\n\nlayout(location = 0) in vec3 fa_world_pos;\nlayout(location = 5) in vec3 fa_lm;\nlayout(location = 1) in vec3 fa_world_normal;\nlayout(location = 2) in vec4 fa_world_tangent;\nlayout(location = 3) in vec2 fa_uv;\nlayout(location = 4) in vec4 fa_vertex_color;\nlayout(location = 0) out vec4 fa_frag_color;\nvec3 fa_light_tint;\nbool fa_light_is_area;\nint fa_cl_ndir;\nint fa_cl_slot;\nint fa_cl_local;\n\nvoid fa_inst_load()\n{\n}\n\nvec4 fa_light_texel(int t)\n{\n    return texelFetch(fa_light_tex_fa_shadow_smp, ivec2(t & 1023, t >> 10), 0);\n}\n\nvec4 fa_cluster_texel(vec3 world_pos)\n{\n    bool _1312 = fa_mesh_fs_params[19].x < 0.0;\n    bool _1319;\n    if (!_1312)\n    {\n        _1319 = fa_mesh_fs_params[19].w < 1.0;\n    }\n    else\n    {\n        _1319 = _1312;\n    }\n    bool _1327;\n    if (!_1319)\n    {\n        _1327 = fa_mesh_fs_params[18].x < 1.0;\n    }\n    else\n    {\n        _1327 = _1319;\n    }\n    bool _1334;\n    if (!_1327)\n    {\n        _1334 = fa_mesh_fs_params[18].y < 1.0;\n    }\n    else\n    {\n        _1334 = _1327;\n    }\n    bool _1341;\n    if (!_1334)\n    {\n        _1341 = fa_mesh_fs_params[19].y < 1.0;\n    }\n    else\n    {\n        _1341 = _1334;\n    }\n    if (_1341)\n    {\n        return vec4(0.0);\n    }\n    vec4 _1351 = vec4(world_pos, 1.0);\n    float _1357 = dot(fa_mesh_fs_params[16], _1351);\n    if (!(_1357 > 9.9999999747524270787835121154785e-07))\n    {\n        return vec4(0.0);\n    }\n    vec2 _1379 = vec2(dot(fa_mesh_fs_params[14], _1351), dot(fa_mesh_fs_params[15], _1351)) / vec2(_1357);\n    int _1383 = int(fa_mesh_fs_params[18].x);\n    int _1387 = int(fa_mesh_fs_params[18].y);\n    int param = (int(fa_mesh_fs_params[19].x) + (((clamp(int(floor(log2(max(dot(fa_mesh_fs_params[17].xyz, world_pos) + fa_mesh_fs_params[17].w, fa_mesh_fs_params[18].w) / fa_mesh_fs_params[18].w) * fa_mesh_fs_params[18].z)), 0, int(fa_mesh_fs_params[19].y) - 1) * _1387) + clamp(int(floor(((_1379.y * 0.5) + 0.5) * fa_mesh_fs_params[18].y)), 0, _1387 - 1)) * _1383)) + clamp(int(floor(((_1379.x * 0.5) + 0.5) * fa_mesh_fs_params[18].x)), 0, _1383 - 1);\n    return fa_light_texel(param);\n}\n\nivec2 fa_cluster_lookup(vec3 world_pos)\n{\n    vec3 param = world_pos;\n    vec4 _1463 = fa_cluster_texel(param);\n    return ivec2(int(_1463.x), int(_1463.y));\n}\n\nvoid fa_cluster_begin(vec3 world_pos)\n{\n    fa_cl_ndir = int(fa_mesh_fs_params[19].z);\n    vec3 param = world_pos;\n    ivec2 _3241 = fa_cluster_lookup(param);\n    fa_cl_slot = _3241.x;\n    fa_cl_local = _3241.y;\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nvec3 fa_linear_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_tex_fix(inout vec3 c, float mode)\n{\n    if (mode > 1.5)\n    {\n        vec3 param = c;\n        vec3 _3400 = fa_linear_to_srgb(param);\n        c = _3400;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            vec3 param_1 = c;\n            vec3 _3408 = fa_srgb_to_linear(param_1);\n            c = _3408;\n        }\n    }\n    return c;\n}\n\nvec3 fa_tangent_normal(SurfaceInput i, vec3 m)\n{\n    vec3 _267;\n    if (i.front_facing)\n    {\n        _267 = i.world_normal;\n    }\n    else\n    {\n        _267 = -i.world_normal;\n    }\n    vec3 _291 = normalize(i.world_tangent.xyz - (_267 * dot(_267, i.world_tangent.xyz)));\n    vec3 _318 = normalize(((_291 * m.x) + ((cross(_267, _291) * i.world_tangent.w) * m.y)) + (_267 * m.z));\n    vec3 _321;\n    if (i.front_facing)\n    {\n        _321 = _318;\n    }\n    else\n    {\n        _321 = -_318;\n    }\n    return _321;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    vec4 base_t = texture(fa_tex_fa_smp, i.uv);\n    float param = fa_mesh_fs_params[6].w;\n    float param_1 = 1.0;\n    vec3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    vec3 _3439 = fa_tex_fix(param_2, param_3);\n    vec4 _4487 = base_t;\n    _4487.x = _3439.x;\n    _4487.y = _3439.y;\n    _4487.z = _3439.z;\n    base_t = _4487;\n    vec4 _3453 = (_4487 * fa_mesh_fs_params[2]) * i.vertex_color;\n    vec3 _4352 = i.world_normal;\n    if (fa_mesh_fs_params[6].z > 0.5)\n    {\n        float param_4 = fa_mesh_fs_params[6].w;\n        float param_5 = 16.0;\n        vec3 param_6 = texture(fa_normal_tex_fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        vec3 _3485 = fa_tex_fix(param_6, param_7);\n        vec3 _3488 = (_3485 * 2.0) - vec3(1.0);\n        vec2 _3493 = _3488.xy * fa_mesh_fs_params[6].x;\n        vec3 _4495 = _3488;\n        _4495.x = _3493.x;\n        _4495.y = _3493.y;\n        SurfaceInput param_8 = i;\n        vec3 param_9 = _4495;\n        _4352 = fa_tangent_normal(param_8, param_9);\n    }\n    vec4 mrt = texture(fa_mr_tex_fa_smp, i.uv);\n    float param_10 = fa_mesh_fs_params[6].w;\n    float param_11 = 64.0;\n    vec3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    vec3 _3521 = fa_tex_fix(param_12, param_13);\n    vec4 _4498 = mrt;\n    _4498.x = _3521.x;\n    _4498.y = _3521.y;\n    _4498.z = _3521.z;\n    mrt = _4498;\n    vec4 _3549 = texture(fa_occlusion_tex_fa_smp, i.uv);\n    float param_14 = fa_mesh_fs_params[6].w;\n    float param_15 = 256.0;\n    vec3 param_16 = _3549.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    vec3 _3560 = fa_tex_fix(param_16, param_17);\n    float param_18 = fa_mesh_fs_params[6].w;\n    float param_19 = 4.0;\n    vec3 param_20 = texture(fa_emissive_tex_fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    vec3 _3590 = fa_tex_fix(param_20, param_21);\n    float _4357 = fa_mesh_fs_params[20].x;\n    float _4358 = fa_mesh_fs_params[20].y;\n    float _4361 = fa_mesh_fs_params[20].z;\n    float _4360 = fa_mesh_fs_params[21].w;\n    float _4363 = fa_mesh_fs_params[22].x;\n    if (fa_mesh_fs_params[22].z > 0.5)\n    {\n        if (mod(fa_mesh_fs_params[22].z, 2.0) > 0.5)\n        {\n            _4357 *= _3560.y;\n            _4358 *= _3560.z;\n            _4360 *= _3549.w;\n        }\n        if (fa_mesh_fs_params[22].z > 1.5)\n        {\n            _4361 *= mrt.x;\n            _4363 *= mrt.w;\n        }\n    }\n    return Surface(_3453.xyz, _3453.w, _4352, clamp(fa_mesh_fs_params[5].x * _3521.z, 0.0, 1.0), clamp(fa_mesh_fs_params[5].y * _3521.y, 0.0500000007450580596923828125, 1.0), 1.0 + (fa_mesh_fs_params[6].y * (_3560.x - 1.0)), fa_mesh_fs_params[3].xyz + (fa_mesh_fs_params[4].xyz * _3590), _4357, _4358, fa_mesh_fs_params[21].xyz, _4360, _4361, fa_mesh_fs_params[20].w, _4363, fa_mesh_fs_params[22].y, fa_mesh_fs_params[23].xyz);\n}\n\nvoid surface(SurfaceInput i, Surface s)\n{\n}\n\nvec4 fa_decal_tile(vec4 rect, vec2 uv, vec2 atlas, vec2 ddx, vec2 ddy)\n{\n    vec2 _1543 = rect.zw - rect.xy;\n    vec2 _1547 = _1543 * atlas;\n    vec2 _1551 = ddx * _1547;\n    vec2 _1555 = ddy * _1547;\n    return textureLod(fa_decal_tex_fa_env_smp, rect.xy + (clamp(uv, vec2(0.0), vec2(1.0)) * _1543), clamp(0.5 * log2(max(max(dot(_1551, _1551), dot(_1555, _1555)), 9.9999999392252902907785028219223e-09)), 0.0, 4.0));\n}\n\nvec3 fa_dc_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_dc_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvoid fa_apply_decals(vec3 world_pos, vec3 geo_normal, inout vec3 albedo, inout vec3 normal)\n{\n    bool _1588 = fa_mesh_fs_params[10].y < 0.5;\n    bool _1595;\n    if (!_1588)\n    {\n        _1595 = fa_mesh_fs_params[10].w < 0.5;\n    }\n    else\n    {\n        _1595 = _1588;\n    }\n    if (_1595)\n    {\n        return;\n    }\n    vec3 _1601 = dFdx(world_pos);\n    vec3 _1604 = dFdy(world_pos);\n    vec3 param = world_pos;\n    vec4 _1608 = fa_cluster_texel(param);\n    int _1612 = int(_1608.w);\n    if (_1612 < 1)\n    {\n        return;\n    }\n    int _1622 = int(fa_mesh_fs_params[10].y + 0.5);\n    int param_1 = _1622;\n    vec4 _1626 = fa_light_texel(param_1);\n    vec2 _1629 = _1626.yz;\n    int _1633 = int(_1626.w);\n    int param_2 = _1622 + 1;\n    vec4 _1638 = fa_light_texel(param_2);\n    float _1639 = _1638.x;\n    int _1645 = int(fa_mesh_fs_params[10].w + 0.5) - 1;\n    int _1649 = int(_1608.z);\n    vec3 _1914;\n    for (int k = 0; k < _1612; k++)\n    {\n        int _1662 = _1649 + k;\n        int param_3 = _1633 + (_1662 >> 2);\n        int _1679 = (_1622 + 2) + (int(fa_light_texel(param_3)[_1662 & 3]) * 7);\n        int param_4 = _1679 + 6;\n        vec4 _1684 = fa_light_texel(param_4);\n        if (((int(_1684.w + 0.5) >> _1645) & 1) == 0)\n        {\n            continue;\n        }\n        int param_5 = _1679;\n        vec4 _1699 = fa_light_texel(param_5);\n        int param_6 = _1679 + 1;\n        vec4 _1704 = fa_light_texel(param_6);\n        int param_7 = _1679 + 2;\n        vec4 _1709 = fa_light_texel(param_7);\n        vec3 _1712 = _1699.xyz;\n        float _1717 = dot(_1712, world_pos) + _1699.w;\n        vec3 _1719 = _1704.xyz;\n        float _1724 = dot(_1719, world_pos) + _1704.w;\n        vec3 _1726 = _1709.xyz;\n        float _1731 = dot(_1726, world_pos) + _1709.w;\n        bool _1736 = abs(_1717) > 0.5;\n        bool _1744;\n        if (!_1736)\n        {\n            _1744 = abs(_1724) > 0.5;\n        }\n        else\n        {\n            _1744 = _1736;\n        }\n        bool _1752;\n        if (!_1744)\n        {\n            _1752 = abs(_1731) > 0.5;\n        }\n        else\n        {\n            _1752 = _1744;\n        }\n        if (_1752)\n        {\n            continue;\n        }\n        float _1767 = clamp(dot(geo_normal, normalize(_1726)) * _1684.z, 0.0, 1.0);\n        if (_1767 <= 0.0)\n        {\n            continue;\n        }\n        float _1787 = (clamp((0.5 - abs(_1731)) * 10.0, 0.0, 1.0) * _1767) * _1684.x;\n        vec2 _1795 = vec2(_1717 + 0.5, 0.5 - _1724);\n        vec2 _1805 = vec2(dot(_1712, _1601), dot(_1719, _1601));\n        vec2 _1815 = vec2(dot(_1712, _1604), dot(_1719, _1604));\n        int param_8 = _1679 + 5;\n        vec4 _1820 = fa_light_texel(param_8);\n        int param_9 = _1679 + 3;\n        vec4 _1825 = fa_light_texel(param_9);\n        int param_10 = _1679 + 4;\n        vec4 _1830 = fa_light_texel(param_10);\n        float tex_a = 1.0;\n        vec3 col = _1820.xyz;\n        bool _1840 = _1825.z > _1825.x;\n        if (_1840)\n        {\n            vec4 param_11 = _1825;\n            vec2 param_12 = _1795;\n            vec2 param_13 = _1629;\n            vec2 param_14 = _1805;\n            vec2 param_15 = _1815;\n            vec4 tx = fa_decal_tile(param_11, param_12, param_13, param_14, param_15);\n            if ((_1639 > 0.5) && (_1639 < 1.5))\n            {\n                vec3 param_16 = tx.xyz;\n                vec3 _1866 = fa_dc_to_linear(param_16);\n                vec4 _4432 = tx;\n                _4432.x = _1866.x;\n                _4432.y = _1866.y;\n                _4432.z = _1866.z;\n                tx = _4432;\n            }\n            col *= tx.xyz;\n            tex_a = tx.w;\n        }\n        albedo = mix(albedo, col, vec3(clamp((_1787 * tex_a) * _1820.w, 0.0, 1.0)));\n        if (_1830.z > _1830.x)\n        {\n            vec4 param_17 = _1830;\n            vec2 param_18 = _1795;\n            vec2 param_19 = _1629;\n            vec2 param_20 = _1805;\n            vec2 param_21 = _1815;\n            vec4 _1910 = fa_decal_tile(param_17, param_18, param_19, param_20, param_21);\n            if (_1639 > 1.5)\n            {\n                vec3 param_22 = _1910.xyz;\n                vec3 _1920 = fa_dc_to_srgb(param_22);\n                _1914 = _1920;\n            }\n            else\n            {\n                _1914 = _1910.xyz;\n            }\n            vec3 _1929 = (_1914 * 2.0) - vec3(1.0);\n            vec2 _1934 = _1929.xy * _1684.y;\n            vec3 _1956 = (normalize(_1712) * _1934.x) + (normalize(_1719) * _1934.y);\n            vec3 _1959 = normalize(normal);\n            normal = normalize(mix(_1959, normalize((_1959 * max(_1929.z, 0.0500000007450580596923828125)) + (_1956 - (_1959 * dot(_1959, _1956)))), vec3(clamp(_1787 * (_1840 ? tex_a : 1.0), 0.0, 1.0))));\n        }\n    }\n}\n\nvec3 fa_sky_sh_coef(int k)\n{\n    vec3 v = textureLod(fa_env_tex_fa_env_smp, vec3(1.0, 1.0 - (float((2 * (k >> 2)) + 1) * 0.25), 1.0 - (float((2 * (k & 3)) + 1) * 0.25)), 5.0).xyz;\n    if (fa_mesh_fs_params[11].w > 1.5)\n    {\n        v = (v - vec3(0.5)) * 8.0;\n    }\n    return v;\n}\n\nvec3 fa_sh_eval(vec3 c[9], vec3 n)\n{\n    vec3 _3154 = max((((c[0] * 0.2820948064327239990234375) + (((c[1] * (0.3257350027561187744140625 * n.y)) + (c[2] * (0.3257350027561187744140625 * n.z))) + (c[3] * (0.3257350027561187744140625 * n.x)))) + (((c[4] * ((0.2731371223926544189453125 * n.x) * n.y)) + (c[5] * ((0.2731371223926544189453125 * n.y) * n.z))) + (c[6] * (0.078847892582416534423828125 * (((3.0 * n.z) * n.z) - 1.0))))) + ((c[7] * ((0.2731371223926544189453125 * n.x) * n.z)) + (c[8] * (0.13656856119632720947265625 * ((n.x * n.x) - (n.y * n.y))))), vec3(0.0));\n    return _3154;\n}\n\nvec3 fa_ambient_light(vec3 n)\n{\n    if (fa_mesh_fs_params[11].w > 0.5)\n    {\n        vec3 c[9];\n        for (int k = 0; k < 9; k++)\n        {\n            int param = k;\n            c[k] = fa_sky_sh_coef(param);\n        }\n        vec3 param_1[9] = c;\n        vec3 param_2 = n;\n        return fa_sh_eval(param_1, param_2);\n    }\n    return fa_mesh_fs_params[1].xyz;\n}\n\nvec3 fa_indirect_diffuse(vec3 n)\n{\n    if (fa_lm.z > 0.5)\n    {\n        return textureLod(fa_lightmap_fa_env_smp, fa_lm.xy, 0.0).xyz;\n    }\n    vec3 param = n;\n    return fa_ambient_light(param);\n}\n\nvec3 ambient(SurfaceInput i, Surface s, vec3 ambientColor)\n{\n    return ambientColor;\n}\n\nint fa_cluster_index(int slot, int n)\n{\n    int param = (int(fa_mesh_fs_params[19].x) + int(fa_mesh_fs_params[19].w)) + ((slot + n) >> 2);\n    vec4 t = fa_light_texel(param);\n    return int(t[(slot + n) & 3]);\n}\n\nint fa_cl_light(int n)\n{\n    if (n < fa_cl_ndir)\n    {\n        return n;\n    }\n    int param = fa_cl_slot;\n    int param_1 = n - fa_cl_ndir;\n    return fa_cluster_index(param, param_1);\n}\n\nint fa_light_base(int li)\n{\n    return li * ((fa_mesh_fs_params[1].w > 4.5) ? 8 : 4);\n}\n\nbool fa_light_baked(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 3;\n    return fa_light_texel(param_1).w > 0.5;\n}\n\nfloat fa_light_type(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 1;\n    return fa_light_texel(param_1).w;\n}\n\nvec4 fa_atlas_fetch(vec2 texel)\n{\n    return textureLod(fa_light_atlas_fa_env_smp, texel / vec2(textureSize(fa_light_atlas_fa_env_smp, 0)), 0.0);\n}\n\nvec3 fa_cookie_sample(vec2 tile_origin, vec2 uv)\n{\n    vec2 param = (tile_origin + vec2(1.0)) + (clamp(uv, vec2(0.0), vec2(1.0)) * 254.0);\n    return fa_atlas_fetch(param).xyz;\n}\n\nvec3 fa_area_point(vec3 c, vec3 axis, vec3 ru, vec3 uu, float hx, float hy, float shape, vec3 p, vec3 r)\n{\n    bool _562 = dot(r, r) > 0.5;\n    if (shape > 1.5)\n    {\n        vec3 _575 = (c - (ru * hx)) - p;\n        vec3 _581 = ru * (2.0 * hx);\n        float _587 = max(dot(_581, _581), 9.9999999392252902907785028219223e-09);\n        float _591 = dot(_575, _581);\n        float t = clamp((-_591) / _587, 0.0, 1.0);\n        if (_562)\n        {\n            float _606 = dot(r, _581);\n            float _612 = _587 - (_606 * _606);\n            if (abs(_612) > (9.9999997473787516355514526367188e-06 * _587))\n            {\n                t = clamp(((dot(r, _575) * _606) - _591) / _612, 0.0, 1.0);\n            }\n        }\n        return (p + _575) + (_581 * t);\n    }\n    vec3 q = p;\n    float _644 = dot(r, axis);\n    bool _652;\n    if (_562)\n    {\n        _652 = abs(_644) > 9.9999997473787516355514526367188e-05;\n    }\n    else\n    {\n        _652 = _562;\n    }\n    if (_652)\n    {\n        float _662 = dot(c - p, axis) / _644;\n        if (_662 > 0.0)\n        {\n            q = p + (r * _662);\n        }\n    }\n    vec3 _675 = q - c;\n    vec2 xy = vec2(dot(_675, ru), dot(_675, uu));\n    if (shape > 0.5)\n    {\n        float _690 = length(xy);\n        if (_690 > hx)\n        {\n            xy *= (hx / _690);\n        }\n    }\n    else\n    {\n        xy = clamp(xy, vec2(-hx, -hy), vec2(hx, hy));\n    }\n    return (c + (ru * xy.x)) + (uu * xy.y);\n}\n\nint fa_cube_face(vec3 d)\n{\n    vec3 _333 = abs(d);\n    float _335 = _333.x;\n    float _337 = _333.y;\n    bool _338 = _335 >= _337;\n    bool _346;\n    if (_338)\n    {\n        _346 = _335 >= _333.z;\n    }\n    else\n    {\n        _346 = _338;\n    }\n    int _347;\n    if (_346)\n    {\n        _347 = (d.x > 0.0) ? 0 : 1;\n    }\n    else\n    {\n        int _362;\n        if (_337 >= _333.z)\n        {\n            _362 = (d.y > 0.0) ? 2 : 3;\n        }\n        else\n        {\n            _362 = (d.z > 0.0) ? 4 : 5;\n        }\n        _347 = _362;\n    }\n    return _347;\n}\n\nvoid fa_cube_face_basis(int f, out vec3 fwd, out vec3 up)\n{\n    if (f == 0)\n    {\n        fwd = vec3(1.0, 0.0, 0.0);\n        up = vec3(0.0, 1.0, 0.0);\n    }\n    else\n    {\n        if (f == 1)\n        {\n            fwd = vec3(-1.0, 0.0, 0.0);\n            up = vec3(0.0, 1.0, 0.0);\n        }\n        else\n        {\n            if (f == 2)\n            {\n                fwd = vec3(0.0, 1.0, 0.0);\n                up = vec3(0.0, 0.0, 1.0);\n            }\n            else\n            {\n                if (f == 3)\n                {\n                    fwd = vec3(0.0, -1.0, 0.0);\n                    up = vec3(0.0, 0.0, -1.0);\n                }\n                else\n                {\n                    if (f == 4)\n                    {\n                        fwd = vec3(0.0, 0.0, 1.0);\n                        up = vec3(0.0, 1.0, 0.0);\n                    }\n                    else\n                    {\n                        fwd = vec3(0.0, 0.0, -1.0);\n                        up = vec3(0.0, 1.0, 0.0);\n                    }\n                }\n            }\n        }\n    }\n}\n\nfloat fa_ies_sample(vec2 tile_origin, vec3 d, vec3 axis, vec3 right, vec3 up)\n{\n    float _482 = dot(d, right);\n    float _486 = dot(d, up);\n    float _497;\n    if (((_482 * _482) + (_486 * _486)) > 1.0000000133514319600180897396058e-10)\n    {\n        _497 = atan(_486, _482) * 0.15915493667125701904296875;\n    }\n    else\n    {\n        _497 = 0.0;\n    }\n    vec2 param = tile_origin + vec2(1.0 + ((_497 - floor(_497)) * 64.0), 1.0 + (acos(clamp(dot(d, axis), -1.0, 1.0)) * 10.18591594696044921875));\n    return fa_atlas_fetch(param).x;\n}\n\nLightSample fa_light_sample_n(int li, vec3 world_pos, vec3 n)\n{\n    int param = li;\n    int _728 = fa_light_base(param);\n    bool _732 = fa_mesh_fs_params[1].w > 4.5;\n    int param_1 = _728;\n    vec4 _736 = fa_light_texel(param_1);\n    int param_2 = _728 + 1;\n    vec4 _741 = fa_light_texel(param_2);\n    float _744 = _741.w;\n    float atten = 1.0;\n    float dist = 0.0;\n    fa_light_tint = vec3(1.0);\n    bool _756 = _732 && (_744 > 2.5);\n    fa_light_is_area = _756;\n    bool _758 = _744 < 0.5;\n    vec3 l;\n    if (_758)\n    {\n        l = normalize(_736.xyz);\n        if (_732)\n        {\n            int param_3 = _728 + 6;\n            vec4 _772 = fa_light_texel(param_3);\n            if (_772.z > 0.5)\n            {\n                int param_4 = _728 + 4;\n                vec4 _782 = fa_light_texel(param_4);\n                int param_5 = _728 + 5;\n                vec4 _787 = fa_light_texel(param_5);\n                vec2 param_6 = _772.xy;\n                vec2 param_7 = fract(vec2(dot(world_pos, _782.xyz) * _782.w, (-dot(world_pos, _787.xyz)) * _787.w) + vec2(0.5));\n                fa_light_tint = fa_cookie_sample(param_6, param_7);\n            }\n        }\n    }\n    else\n    {\n        vec3 _817 = _736.xyz;\n        vec3 _819 = _817 - world_pos;\n        vec3 to_light = _819;\n        float _822 = length(_819);\n        float reach = _822;\n        bool front = true;\n        if (_756)\n        {\n            int param_8 = _728 + 7;\n            reach = max(_822 - fa_light_texel(param_8).w, 0.0);\n            int param_9 = _728 + 4;\n            vec4 _846 = fa_light_texel(param_9);\n            int param_10 = _728 + 5;\n            vec4 _851 = fa_light_texel(param_10);\n            int param_11 = _728 + 6;\n            vec4 _856 = fa_light_texel(param_11);\n            float _857 = _856.w;\n            int param_12 = _728 + 2;\n            vec3 _864 = normalize(fa_light_texel(param_12).xyz);\n            bool _866 = _857 > 1.5;\n            bool _874;\n            if (!_866)\n            {\n                _874 = dot(_864, to_light) < 0.0;\n            }\n            else\n            {\n                _874 = _866;\n            }\n            front = _874;\n            vec3 r = vec3(0.0);\n            vec3 _883 = fa_mesh_fs_params[0].xyz - world_pos;\n            bool _887 = dot(n, n) > 0.5;\n            bool _895;\n            if (_887)\n            {\n                _895 = dot(_883, _883) > 9.9999999600419720025001879548654e-13;\n            }\n            else\n            {\n                _895 = _887;\n            }\n            if (_895)\n            {\n                r = reflect(-normalize(_883), normalize(n));\n            }\n            vec3 param_13 = _817;\n            vec3 param_14 = _864;\n            vec3 param_15 = _846.xyz;\n            vec3 param_16 = _851.xyz;\n            float param_17 = _846.w;\n            float param_18 = _851.w;\n            float param_19 = _857;\n            vec3 param_20 = world_pos;\n            vec3 param_21 = r;\n            to_light = fa_area_point(param_13, param_14, param_15, param_16, param_17, param_18, param_19, param_20, param_21) - world_pos;\n        }\n        float _931 = length(to_light);\n        dist = _931;\n        l = to_light / vec3(max(_931, 9.9999997473787516355514526367188e-05));\n        float _945 = reach / max(_736.w, 0.001000000047497451305389404296875);\n        float _951 = clamp(1.0 - (_945 * _945), 0.0, 1.0);\n        float _953;\n        if (front)\n        {\n            _953 = _951 * _951;\n        }\n        else\n        {\n            _953 = 0.0;\n        }\n        atten = _953;\n        bool _964 = _744 < 2.5;\n        if ((_744 > 1.5) && _964)\n        {\n            int param_22 = _728 + 2;\n            vec4 _972 = fa_light_texel(param_22);\n            float _982 = _972.w;\n            int param_23 = _728 + 3;\n            vec4 _987 = fa_light_texel(param_23);\n            float _988 = _987.x;\n            float cos_inner = _988;\n            if (_988 > 1.5)\n            {\n                cos_inner = mix(_982, 1.0, 0.25);\n            }\n            atten *= smoothstep(_982, cos_inner, dot(-l, normalize(_972.xyz)));\n        }\n        if (_732 && (_744 < 1.5))\n        {\n            int param_24 = _728 + 6;\n            vec4 _1012 = fa_light_texel(param_24);\n            if (_1012.z > 0.5)\n            {\n                vec3 _1020 = -to_light;\n                int param_25 = _728 + 4;\n                int param_26 = _728 + 5;\n                vec3 _1034 = fa_light_texel(param_25).xyz;\n                vec3 _1038 = fa_light_texel(param_26).xyz;\n                vec3 _1047 = vec3(dot(_1020, _1034), dot(_1020, _1038), dot(_1020, cross(_1034, _1038)));\n                vec3 param_27 = _1047;\n                int _1051 = fa_cube_face(param_27);\n                int param_28 = _1051;\n                vec3 param_29;\n                vec3 param_30;\n                fa_cube_face_basis(param_28, param_29, param_30);\n                vec2 _1078 = vec2(dot(_1047, cross(param_29, param_30)), dot(_1047, param_30)) / vec2(max(dot(_1047, param_29), 9.9999997473787516355514526367188e-05));\n                int _1082 = _1051 / 3;\n                vec2 param_31 = _1012.xy + (vec2(float(_1051 - (_1082 * 3)), float(_1082)) * 256.0);\n                vec2 param_32 = vec2(0.5 + (0.5 * _1078.x), 0.5 - (0.5 * _1078.y));\n                fa_light_tint = fa_cookie_sample(param_31, param_32);\n            }\n            int param_33 = _728 + 7;\n            vec4 _1112 = fa_light_texel(param_33);\n            if (_1112.z > 0.5)\n            {\n                int param_34 = _728 + 2;\n                int param_35 = _728 + 4;\n                int param_36 = _728 + 5;\n                vec2 param_37 = _1112.xy;\n                vec3 param_38 = -l;\n                vec3 param_39 = normalize(fa_light_texel(param_34).xyz);\n                vec3 param_40 = fa_light_texel(param_35).xyz;\n                vec3 param_41 = fa_light_texel(param_36).xyz;\n                atten *= fa_ies_sample(param_37, param_38, param_39, param_40, param_41);\n            }\n        }\n        else\n        {\n            if (_732 && _964)\n            {\n                int param_42 = _728 + 6;\n                vec4 _1159 = fa_light_texel(param_42);\n                int param_43 = _728 + 7;\n                vec4 _1164 = fa_light_texel(param_43);\n                bool _1167 = _1159.z > 0.5;\n                bool _1174;\n                if (!_1167)\n                {\n                    _1174 = _1164.z > 0.5;\n                }\n                else\n                {\n                    _1174 = _1167;\n                }\n                if (_1174)\n                {\n                    int param_44 = _728 + 2;\n                    vec4 _1181 = fa_light_texel(param_44);\n                    vec3 _1185 = normalize(_1181.xyz);\n                    int param_45 = _728 + 4;\n                    vec4 _1190 = fa_light_texel(param_45);\n                    int param_46 = _728 + 5;\n                    vec4 _1195 = fa_light_texel(param_46);\n                    if (_1167)\n                    {\n                        vec3 _1203 = -to_light;\n                        float _1210 = _1181.w;\n                        float _1226 = 0.5 / max(dot(_1203, _1185) * (sqrt(max(1.0 - (_1210 * _1210), 0.0)) / max(_1210, 0.001000000047497451305389404296875)), 9.9999997473787516355514526367188e-05);\n                        vec2 param_47 = _1159.xy;\n                        vec2 param_48 = vec2(0.5 + (dot(_1203, _1190.xyz) * _1226), 0.5 - (dot(_1203, _1195.xyz) * _1226));\n                        fa_light_tint = fa_cookie_sample(param_47, param_48);\n                    }\n                    if (_1164.z > 0.5)\n                    {\n                        vec2 param_49 = _1164.xy;\n                        vec3 param_50 = -l;\n                        vec3 param_51 = _1185;\n                        vec3 param_52 = _1190.xyz;\n                        vec3 param_53 = _1195.xyz;\n                        atten *= fa_ies_sample(param_49, param_50, param_51, param_52, param_53);\n                    }\n                }\n            }\n        }\n    }\n    vec3 _4306 = _741.xyz * atten;\n    if (_732)\n    {\n        _4306 *= fa_light_tint;\n    }\n    int _1294;\n    if (_758)\n    {\n        _1294 = 0;\n    }\n    else\n    {\n        _1294 = ((_744 > 1.5) && (_744 < 2.5)) ? 2 : 1;\n    }\n    return LightSample(l, _4306, atten, 1.0, dist, _1294);\n}\n\nfloat fa_shadow_split_at(int i)\n{\n    float _2031;\n    if (i == 0)\n    {\n        _2031 = fa_shadows[24].x;\n    }\n    else\n    {\n        float _2047;\n        if (i == 1)\n        {\n            _2047 = fa_shadows[24].y;\n        }\n        else\n        {\n            float _2055;\n            if (i == 2)\n            {\n                _2055 = fa_shadows[24].z;\n            }\n            else\n            {\n                _2055 = fa_shadows[24].w;\n            }\n            _2047 = _2055;\n        }\n        _2031 = _2047;\n    }\n    return _2031;\n}\n\nfloat fa_shadow_depth(inout vec2 uv, vec4 rect)\n{\n    uv = clamp(uv, rect.xy, rect.zw);\n    return textureLod(fa_shadow_tex_fa_shadow_smp, uv, 0.0).x;\n}\n\nfloat fa_shadow_fetch(vec2 uv, vec4 rect, vec3 conv)\n{\n    vec2 param = uv;\n    vec4 param_1 = rect;\n    float _2088 = fa_shadow_depth(param, param_1);\n    float _2092;\n    if (conv.x < 0.5)\n    {\n        _2092 = _2088;\n    }\n    else\n    {\n        _2092 = (conv.y * conv.z) / (conv.z - (_2088 * (conv.z - conv.y)));\n    }\n    return _2092;\n}\n\nfloat fa_shadow_noise()\n{\n    return fract(52.98291778564453125 * fract(dot(gl_FragCoord.xy, vec2(0.067110560834407806396484375, 0.005837149918079376220703125))));\n}\n\nvec2 fa_shadow_vogel(int k, int n, float phi)\n{\n    float _2019 = (float(k) * 2.3999631404876708984375) + phi;\n    return vec2(cos(_2019), sin(_2019)) * sqrt((float(k) + 0.5) / float(n));\n}\n\nfloat fa_shadow_filter(vec2 uv, vec4 rect, float zr, float texel_m, float unit, float reach, float plane, vec3 conv, int mode, float k)\n{\n    if (mode == 1)\n    {\n        vec2 param = uv;\n        vec4 param_1 = rect;\n        vec3 param_2 = conv;\n        return float(zr <= fa_shadow_fetch(param, param_1, param_2));\n    }\n    float _2138 = fa_shadow_noise() * 6.283185482025146484375;\n    float radius = 1.5;\n    if (mode == 2)\n    {\n        float _2147;\n        if (k < 0.0)\n        {\n            _2147 = (-k) / max(zr, 0.100000001490116119384765625);\n        }\n        else\n        {\n            _2147 = k;\n        }\n        float _2167 = clamp((_2147 * reach) / texel_m, 3.0, 12.0);\n        float sum = 0.0;\n        float cnt = 0.0;\n        for (int i = 0; i < 16; i++)\n        {\n            int param_3 = i;\n            int param_4 = 16;\n            float param_5 = _2138;\n            vec2 _2186 = fa_shadow_vogel(param_3, param_4, param_5) * _2167;\n            vec2 param_6 = uv + (_2186 * fa_shadows[26].zw);\n            vec4 param_7 = rect;\n            vec3 param_8 = conv;\n            float _2198 = fa_shadow_fetch(param_6, param_7, param_8);\n            if (_2198 < (zr - (length(_2186) * plane)))\n            {\n                sum += _2198;\n                cnt += 1.0;\n            }\n        }\n        if (cnt < 0.5)\n        {\n            return 1.0;\n        }\n        float _2224 = sum / cnt;\n        float _2234;\n        if (k < 0.0)\n        {\n            _2234 = (-k) / max(_2224, 0.0500000007450580596923828125);\n        }\n        else\n        {\n            _2234 = k;\n        }\n        radius = clamp(((max(zr - _2224, 0.0) * unit) * _2234) / texel_m, 1.5, 16.0);\n    }\n    float lit = 0.0;\n    int _2256 = (mode == 2) ? 24 : 16;\n    for (int i_1 = 0; i_1 < _2256; i_1++)\n    {\n        int param_9 = i_1;\n        int param_10 = _2256;\n        float param_11 = _2138;\n        vec2 _2275 = fa_shadow_vogel(param_9, param_10, param_11) * radius;\n        vec2 param_12 = uv + (_2275 * fa_shadows[26].zw);\n        vec4 param_13 = rect;\n        vec3 param_14 = conv;\n        lit += float((zr - (length(_2275) * plane)) <= fa_shadow_fetch(param_12, param_13, param_14));\n    }\n    return lit / float(_2256);\n}\n\nfloat fa_shadow_cascade(int ci, vec3 world, vec3 n, vec3 l)\n{\n    float _2317 = max(fa_shadows[ci * 1 + 20].y, 0.001000000047497451305389404296875);\n    float _2322 = clamp(dot(n, l), 0.0, 1.0);\n    float _2328 = sqrt(1.0 - (_2322 * _2322));\n    float _2335 = min(_2328 / max(_2322, 0.20000000298023223876953125), 4.0);\n    float _2340;\n    if (fa_shadows[26].y > 0.0)\n    {\n        _2340 = fa_shadows[26].y;\n    }\n    else\n    {\n        _2340 = 1.5 * fa_shadows[ci * 1 + 20].x;\n    }\n    vec4 _2365 = mat4(fa_shadows[ci * 4 + 0], fa_shadows[ci * 4 + 1], fa_shadows[ci * 4 + 2], fa_shadows[ci * 4 + 3]) * vec4(world + (n * (_2340 * _2328)), 1.0);\n    float _2372 = _2365.x;\n    bool _2375 = _2372 < fa_shadows[ci * 1 + 16].x;\n    bool _2384;\n    if (!_2375)\n    {\n        _2384 = _2372 > fa_shadows[ci * 1 + 16].z;\n    }\n    else\n    {\n        _2384 = _2375;\n    }\n    bool _2393;\n    if (!_2384)\n    {\n        _2393 = _2365.y < fa_shadows[ci * 1 + 16].y;\n    }\n    else\n    {\n        _2393 = _2384;\n    }\n    bool _2402;\n    if (!_2393)\n    {\n        _2402 = _2365.y > fa_shadows[ci * 1 + 16].w;\n    }\n    else\n    {\n        _2402 = _2393;\n    }\n    bool _2409;\n    if (!_2402)\n    {\n        _2409 = _2365.z > 1.0;\n    }\n    else\n    {\n        _2409 = _2402;\n    }\n    if (_2409)\n    {\n        return -1.0;\n    }\n    float _2417;\n    if (fa_shadows[26].x > 0.0)\n    {\n        _2417 = fa_shadows[26].x;\n    }\n    else\n    {\n        _2417 = 1.5 * fa_shadows[ci * 1 + 20].x;\n    }\n    vec2 param = _2365.xy;\n    vec4 param_1 = fa_shadows[ci * 1 + 16];\n    float param_2 = _2365.z - ((_2417 * (1.0 + (0.5 * _2335))) / _2317);\n    float param_3 = fa_shadows[ci * 1 + 20].x;\n    float param_4 = _2317;\n    float param_5 = _2317 * 0.25;\n    float param_6 = ((fa_shadows[ci * 1 + 20].x * min(_2335, 3.0)) * 0.5) / _2317;\n    vec3 param_7 = vec3(0.0);\n    int param_8 = int(fa_shadows[25].z + 0.5);\n    float param_9 = fa_shadows[25].w;\n    return fa_shadow_filter(param, param_1, param_2, param_3, param_4, param_5, param_6, param_7, param_8, param_9);\n}\n\nfloat fa_shadow_sun(vec3 world, vec3 n, vec3 l)\n{\n    if (fa_mesh_fs_params[5].z < 0.5)\n    {\n        return 1.0;\n    }\n    int _2795 = int(fa_shadows[25].x + 0.5);\n    if (_2795 < 1)\n    {\n        return 1.0;\n    }\n    float _2810 = dot(world - fa_shadows[27].xyz, fa_shadows[28].xyz);\n    int param = _2795 - 1;\n    if (_2810 > fa_shadow_split_at(param))\n    {\n        return 1.0;\n    }\n    int ci = 0;\n    bool _2822 = _2795 > 1;\n    bool _2829;\n    if (_2822)\n    {\n        _2829 = _2810 > fa_shadows[24].x;\n    }\n    else\n    {\n        _2829 = _2822;\n    }\n    if (_2829)\n    {\n        ci = 1;\n    }\n    bool _2833 = _2795 > 2;\n    bool _2840;\n    if (_2833)\n    {\n        _2840 = _2810 > fa_shadows[24].y;\n    }\n    else\n    {\n        _2840 = _2833;\n    }\n    if (_2840)\n    {\n        ci = 2;\n    }\n    bool _2844 = _2795 > 3;\n    bool _2851;\n    if (_2844)\n    {\n        _2851 = _2810 > fa_shadows[24].z;\n    }\n    else\n    {\n        _2851 = _2844;\n    }\n    if (_2851)\n    {\n        ci = 3;\n    }\n    float s = -1.0;\n    for (int k = 0; k < 4; k++)\n    {\n        if (ci >= _2795)\n        {\n            break;\n        }\n        int param_1 = ci;\n        vec3 param_2 = world;\n        vec3 param_3 = n;\n        vec3 param_4 = l;\n        float _2877 = fa_shadow_cascade(param_1, param_2, param_3, param_4);\n        s = _2877;\n        if (_2877 >= 0.0)\n        {\n            break;\n        }\n        ci++;\n    }\n    if (s < 0.0)\n    {\n        return 1.0;\n    }\n    if (fa_shadows[25].y > 0.0)\n    {\n        float _2902;\n        if (ci > 0)\n        {\n            int param_5 = ci - 1;\n            _2902 = fa_shadow_split_at(param_5);\n        }\n        else\n        {\n            _2902 = fa_shadows[28].w;\n        }\n        int param_6 = ci;\n        float _2921 = fa_shadows[25].y * max(fa_shadow_split_at(param_6) - _2902, 9.9999997473787516355514526367188e-05);\n        int param_7 = ci;\n        float _2932 = clamp((_2810 - (fa_shadow_split_at(param_7) - _2921)) / _2921, 0.0, 1.0);\n        if (_2932 > 0.0)\n        {\n            float s2 = 1.0;\n            if ((ci + 1) < _2795)\n            {\n                int param_8 = ci + 1;\n                vec3 param_9 = world;\n                vec3 param_10 = n;\n                vec3 param_11 = l;\n                float _2953 = fa_shadow_cascade(param_8, param_9, param_10, param_11);\n                s2 = _2953;\n                if (_2953 < 0.0)\n                {\n                    s2 = s;\n                }\n            }\n            s = mix(s, s2, _2932);\n        }\n    }\n    return s;\n}\n\nfloat fa_shadow_factor(vec3 n, vec3 l)\n{\n    vec3 param = fa_world_pos;\n    vec3 param_1 = n;\n    vec3 param_2 = l;\n    return fa_shadow_sun(param, param_1, param_2);\n}\n\nfloat fa_shadow_local(int li, vec3 lpos, vec3 world, vec3 n, vec3 l)\n{\n    bool _2475 = fa_mesh_fs_params[5].z < 0.5;\n    bool _2482;\n    if (!_2475)\n    {\n        _2482 = fa_shadows[29].x < 0.5;\n    }\n    else\n    {\n        _2482 = _2475;\n    }\n    if (_2482)\n    {\n        return 1.0;\n    }\n    int param = (int(fa_shadows[29].x + 0.5) - 1) + li;\n    vec4 _2495 = fa_light_texel(param);\n    float _2496 = _2495.x;\n    if (_2496 < 0.0)\n    {\n        return 1.0;\n    }\n    int _2505 = int(_2496 + 0.5);\n    int param_1 = _2505;\n    vec4 _2509 = fa_light_texel(param_1);\n    int param_2 = _2505 + 1;\n    vec4 _2514 = fa_light_texel(param_2);\n    float fade = 1.0;\n    float _2517 = _2509.y;\n    if (_2517 > 0.0)\n    {\n        float _2534 = 1.0 - smoothstep(0.75 * _2517, _2517, length(world - fa_shadows[27].xyz));\n        fade = _2534;\n        if (_2534 <= 0.0)\n        {\n            return 1.0;\n        }\n    }\n    int face = 0;\n    if (_2509.x > 1.5)\n    {\n        vec3 param_3 = world - lpos;\n        face = fa_cube_face(param_3);\n    }\n    int _2558 = (_2505 + 2) + (face * 6);\n    int param_4 = _2558;\n    int param_5 = _2558 + 1;\n    int param_6 = _2558 + 3;\n    vec4 _2572 = fa_light_texel(param_6);\n    int param_7 = _2558 + 4;\n    vec4 _2577 = fa_light_texel(param_7);\n    int param_8 = _2558 + 5;\n    vec4 _2582 = fa_light_texel(param_8);\n    float _2594 = _2582.x * max(dot(_2572, vec4(world, 1.0)), 0.001000000047497451305389404296875);\n    float _2599 = clamp(dot(n, l), 0.0, 1.0);\n    float _2622 = clamp(dot(n, _2572.xyz), -1.0, 1.0);\n    float _2641 = min(sqrt(1.0 - (_2622 * _2622)) / max(abs(dot(n, world - lpos)) / max(dot(_2572, vec4(world, 1.0)), 0.001000000047497451305389404296875), 0.20000000298023223876953125), 4.0);\n    float _2644 = _2514.y;\n    float _2646;\n    if (_2644 > 0.0)\n    {\n        _2646 = _2644;\n    }\n    else\n    {\n        _2646 = 1.5 * _2594;\n    }\n    vec4 _2666 = vec4(world + (n * (_2646 * sqrt(1.0 - (_2599 * _2599)))), 1.0);\n    float _2670 = dot(_2572, _2666);\n    float _2673 = _2582.y;\n    if (_2670 < _2673)\n    {\n        return 1.0;\n    }\n    vec2 _2688 = vec2(dot(fa_light_texel(param_4), _2666), dot(fa_light_texel(param_5), _2666)) / vec2(_2670);\n    float _2690 = _2688.x;\n    bool _2693 = _2690 < _2577.x;\n    bool _2702;\n    if (!_2693)\n    {\n        _2702 = _2690 > _2577.z;\n    }\n    else\n    {\n        _2702 = _2693;\n    }\n    bool _2711;\n    if (!_2702)\n    {\n        _2711 = _2688.y < _2577.y;\n    }\n    else\n    {\n        _2711 = _2702;\n    }\n    bool _2720;\n    if (!_2711)\n    {\n        _2720 = _2688.y > _2577.w;\n    }\n    else\n    {\n        _2720 = _2711;\n    }\n    if (_2720)\n    {\n        return 1.0;\n    }\n    float _2726 = _2514.x;\n    float _2728;\n    if (_2726 > 0.0)\n    {\n        _2728 = _2726;\n    }\n    else\n    {\n        _2728 = 1.5 * _2594;\n    }\n    vec2 param_9 = _2688;\n    vec4 param_10 = _2577;\n    float param_11 = _2670 - (_2728 * (1.0 + (0.5 * _2641)));\n    float param_12 = _2594;\n    float param_13 = 1.0;\n    float param_14 = _2582.z * 0.25;\n    float param_15 = (_2594 * min(_2641, 3.0)) * 0.5;\n    vec3 param_16 = vec3(1.0, _2673, _2582.z);\n    int param_17 = int(_2509.z + 0.5);\n    float param_18 = _2509.w;\n    return mix(1.0, fa_shadow_filter(param_9, param_10, param_11, param_12, param_13, param_14, param_15, param_16, param_17, param_18), fade);\n}\n\nLightSample fa_light_shadowed(int li, vec3 world_pos, vec3 gn)\n{\n    bool _3268 = fa_lm.z > 0.5;\n    bool _3274;\n    if (_3268)\n    {\n        int param = li;\n        _3274 = fa_light_baked(param);\n    }\n    else\n    {\n        _3274 = _3268;\n    }\n    if (_3274)\n    {\n        int param_1 = li;\n        return LightSample(vec3(0.0, 1.0, 0.0), vec3(0.0), 0.0, 1.0, 0.0, int(fa_light_type(param_1) + 0.5));\n    }\n    int param_2 = li;\n    vec3 param_3 = world_pos;\n    vec3 param_4 = gn;\n    LightSample _3298 = fa_light_sample_n(param_2, param_3, param_4);\n    vec3 _4332 = _3298.color;\n    float _4334 = _3298.shadow;\n    if ((_3298.type == 0) && (li == 0))\n    {\n        vec3 param_5 = gn;\n        vec3 param_6 = _3298.direction;\n        float _3312 = fa_shadow_factor(param_5, param_6);\n        _4334 = _3312;\n        _4332 *= _3312;\n    }\n    else\n    {\n        bool _3323 = _3298.type != 0;\n        bool _3329;\n        if (_3323)\n        {\n            _3329 = _3298.attenuation > 0.0;\n        }\n        else\n        {\n            _3329 = _3323;\n        }\n        if (_3329)\n        {\n            int param_7 = li;\n            int param_8 = fa_light_base(param_7);\n            int param_9 = li;\n            vec3 param_10 = fa_light_texel(param_8).xyz;\n            vec3 param_11 = world_pos;\n            vec3 param_12 = gn;\n            vec3 param_13 = _3298.direction;\n            float _3348 = fa_shadow_local(param_9, param_10, param_11, param_12, param_13);\n            _4334 = _3348;\n            _4332 *= _3348;\n        }\n    }\n    return LightSample(_3298.direction, _4332, _3298.attenuation, _4334, _3298._distance, _3298.type);\n}\n\nvec3 light(SurfaceInput i, Surface s, LightSample l)\n{\n    return vec3(0.0);\n}\n\nvec3 fa_shadow_debug(vec3 color, vec3 world)\n{\n    if (fa_shadows[27].w < 0.5)\n    {\n        return color;\n    }\n    int _2977 = int(fa_shadows[25].x + 0.5);\n    float _2987 = dot(world - fa_shadows[27].xyz, fa_shadows[28].xyz);\n    vec3 tint = vec3(0.3499999940395355224609375);\n    bool _2992 = _2977 > 0;\n    bool _3001;\n    if (_2992)\n    {\n        int param = _2977 - 1;\n        _3001 = _2987 <= fa_shadow_split_at(param);\n    }\n    else\n    {\n        _3001 = _2992;\n    }\n    if (_3001)\n    {\n        tint = vec3(1.0, 0.1500000059604644775390625, 0.100000001490116119384765625);\n        bool _3007 = _2977 > 1;\n        bool _3014;\n        if (_3007)\n        {\n            _3014 = _2987 > fa_shadows[24].x;\n        }\n        else\n        {\n            _3014 = _3007;\n        }\n        if (_3014)\n        {\n            tint = vec3(0.100000001490116119384765625, 0.89999997615814208984375, 0.20000000298023223876953125);\n        }\n        bool _3020 = _2977 > 2;\n        bool _3027;\n        if (_3020)\n        {\n            _3027 = _2987 > fa_shadows[24].y;\n        }\n        else\n        {\n            _3027 = _3020;\n        }\n        if (_3027)\n        {\n            tint = vec3(0.1500000059604644775390625, 0.300000011920928955078125, 1.0);\n        }\n        bool _3033 = _2977 > 3;\n        bool _3040;\n        if (_3033)\n        {\n            _3040 = _2987 > fa_shadows[24].z;\n        }\n        else\n        {\n            _3040 = _3033;\n        }\n        if (_3040)\n        {\n            tint = vec3(1.0, 0.89999997615814208984375, 0.100000001490116119384765625);\n        }\n    }\n    return mix(color, tint, vec3(0.550000011920928955078125));\n}\n\nvoid main()\n{\n    fa_inst_load();\n    vec3 _4148 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _4148 = -_4148;\n    }\n    vec3 _3733 = normalize(fa_mesh_fs_params[0].xyz - fa_world_pos);\n    vec3 param = fa_world_pos;\n    fa_cluster_begin(param);\n    SurfaceInput param_1 = SurfaceInput(fa_world_pos, _4148, fa_world_tangent, fa_uv, fa_vertex_color, _3733, gl_FrontFacing);\n    Surface _3741 = fa_standard_surface(param_1);\n    vec3 _4187 = _3741.albedo;\n    float _4188 = _3741.alpha;\n    vec3 _4189 = _3741.normal;\n    float _4190 = _3741.metallic;\n    float _4191 = _3741.roughness;\n    float _4192 = _3741.occlusion;\n    vec3 _4193 = _3741.emission;\n    float _4194 = _3741.clearcoat;\n    float _4195 = _3741.clearcoat_roughness;\n    vec3 _4196 = _3741.sheen_color;\n    float _4197 = _3741.sheen_roughness;\n    float _4198 = _3741.anisotropy;\n    float _4199 = _3741.anisotropy_rotation;\n    float _4200 = _3741.specular;\n    float _4201 = _3741.ior;\n    vec3 _4202 = _3741.specular_color;\n    SurfaceInput param_2 = SurfaceInput(fa_world_pos, _4148, fa_world_tangent, fa_uv, fa_vertex_color, _3733, gl_FrontFacing);\n    Surface param_3 = _3741;\n    surface(param_2, param_3);\n    _4187 = param_3.albedo;\n    _4188 = param_3.alpha;\n    _4189 = param_3.normal;\n    _4190 = param_3.metallic;\n    _4191 = param_3.roughness;\n    _4192 = param_3.occlusion;\n    _4193 = param_3.emission;\n    _4194 = param_3.clearcoat;\n    _4195 = param_3.clearcoat_roughness;\n    _4196 = param_3.sheen_color;\n    _4197 = param_3.sheen_roughness;\n    _4198 = param_3.anisotropy;\n    _4199 = param_3.anisotropy_rotation;\n    _4200 = param_3.specular;\n    _4201 = param_3.ior;\n    _4202 = param_3.specular_color;\n    vec3 param_4 = fa_world_pos;\n    vec3 param_5 = _4148;\n    vec3 param_6 = param_3.albedo;\n    vec3 param_7 = param_3.normal;\n    fa_apply_decals(param_4, param_5, param_6, param_7);\n    _4187 = param_6;\n    _4189 = param_7;\n    vec3 result;\n    if (fa_mesh_fs_params[3].w > 0.5)\n    {\n        result = _4187;\n    }\n    else\n    {\n        vec3 _3779 = _4189;\n        vec3 _3780 = normalize(_3779);\n        _4189 = _3780;\n        vec3 param_8 = _3780;\n        SurfaceInput param_9 = SurfaceInput(fa_world_pos, _4148, fa_world_tangent, fa_uv, fa_vertex_color, _3733, gl_FrontFacing);\n        Surface param_10 = Surface(_4187, _4188, _4189, _4190, _4191, _4192, _4193, _4194, _4195, _4196, _4197, _4198, _4199, _4200, _4201, _4202);\n        vec3 param_11 = fa_indirect_diffuse(param_8);\n        vec3 lit = ambient(param_9, param_10, param_11);\n        int _3799 = fa_cl_ndir + fa_cl_local;\n        for (int ln = 0; ln < _3799; ln++)\n        {\n            int param_12 = ln;\n            int _3812 = fa_cl_light(param_12);\n            bool _3815 = fa_lm.z > 0.5;\n            bool _3821;\n            if (_3815)\n            {\n                int param_13 = _3812;\n                _3821 = fa_light_baked(param_13);\n            }\n            else\n            {\n                _3821 = _3815;\n            }\n            if (_3821)\n            {\n                continue;\n            }\n            int param_14 = _3812;\n            vec3 param_15 = fa_world_pos;\n            vec3 param_16 = _4148;\n            LightSample _3833 = fa_light_shadowed(param_14, param_15, param_16);\n            SurfaceInput param_17 = SurfaceInput(fa_world_pos, _4148, fa_world_tangent, fa_uv, fa_vertex_color, _3733, gl_FrontFacing);\n            Surface param_18 = Surface(_4187, _4188, _4189, _4190, _4191, _4192, _4193, _4194, _4195, _4196, _4197, _4198, _4199, _4200, _4201, _4202);\n            LightSample param_19 = _3833;\n            lit += light(param_17, param_18, param_19);\n        }\n        result = lit;\n    }\n    vec3 _3848 = result;\n    vec3 _3849 = _3848 + _4193;\n    result = _3849;\n    vec3 param_20 = _3849;\n    vec3 param_21 = fa_world_pos;\n    result = fa_shadow_debug(param_20, param_21);\n    bool _3858 = fa_mesh_fs_params[7].w > 0.0;\n    bool _3865;\n    if (!_3858)\n    {\n        _3865 = fa_mesh_fs_params[8].y > 0.0;\n    }\n    else\n    {\n        _3865 = _3858;\n    }\n    if (_3865)\n    {\n        vec3 _3874 = fa_world_pos - fa_mesh_fs_params[0].xyz;\n        float _3880 = dot(_3874, fa_mesh_fs_params[9].xyz);\n        bool _3884 = fa_mesh_fs_params[9].w > 0.5;\n        float _3885;\n        if (_3884)\n        {\n            _3885 = _3880;\n        }\n        else\n        {\n            _3885 = length(_3874);\n        }\n        float _3897 = _3885 - fa_mesh_fs_params[8].x;\n        if (_3897 > 0.0)\n        {\n            float _3906 = fa_mesh_fs_params[7].w * _3897;\n            float tau = _3906 * _3906;\n            if (fa_mesh_fs_params[8].y > 0.0)\n            {\n                float _3922;\n                if (_3884)\n                {\n                    _3922 = fa_world_pos.y - (fa_mesh_fs_params[9].y * _3880);\n                }\n                else\n                {\n                    _3922 = fa_mesh_fs_params[0].y;\n                }\n                float _3943 = mix(_3922, fa_world_pos.y, clamp(fa_mesh_fs_params[8].x / _3885, 0.0, 1.0));\n                float _3947 = fa_world_pos.y - _3943;\n                float _3952 = _3943 - fa_mesh_fs_params[8].z;\n                float _3957 = fa_world_pos.y - fa_mesh_fs_params[8].z;\n                bool _3960 = _3952 <= 0.0;\n                bool _3961 = !_3960;\n                bool _3967;\n                if (_3961)\n                {\n                    _3967 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _3967 = _3960;\n                }\n                float _3968;\n                if (_3967)\n                {\n                    _3968 = fa_mesh_fs_params[8].y;\n                }\n                else\n                {\n                    _3968 = fa_mesh_fs_params[8].y * exp(-min(fa_mesh_fs_params[8].w * _3952, 80.0));\n                }\n                bool _3995;\n                if (_3961)\n                {\n                    _3995 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _3995 = _3960;\n                }\n                float _3996;\n                if (_3995)\n                {\n                    _3996 = fa_mesh_fs_params[8].y * _3952;\n                }\n                else\n                {\n                    _3996 = (fa_mesh_fs_params[8].y * (1.0 - exp(-min(fa_mesh_fs_params[8].w * _3952, 80.0)))) / fa_mesh_fs_params[8].w;\n                }\n                bool _4021 = _3957 <= 0.0;\n                bool _4028;\n                if (!_4021)\n                {\n                    _4028 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _4028 = _4021;\n                }\n                float _4029;\n                if (_4028)\n                {\n                    _4029 = fa_mesh_fs_params[8].y * _3957;\n                }\n                else\n                {\n                    _4029 = (fa_mesh_fs_params[8].y * (1.0 - exp(-min(fa_mesh_fs_params[8].w * _3957, 80.0)))) / fa_mesh_fs_params[8].w;\n                }\n                float _4056;\n                if (abs(_3947) < 0.001000000047497451305389404296875)\n                {\n                    _4056 = _3968;\n                }\n                else\n                {\n                    _4056 = (_4029 - _3996) / _3947;\n                }\n                tau += (_3897 * max(_4056, 0.0));\n            }\n            result = mix(result, fa_mesh_fs_params[7].xyz, vec3(clamp(1.0 - exp(-clamp(tau, 0.0, 80.0)), 0.0, 1.0)));\n        }\n    }\n    fa_frag_color = vec4(result, _4188);\n}\n\n",
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
            "inst_name": "_384",
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
            "inst_name": "_2041",
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
      "vs": "#version 430\n\nstruct VertexData\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 color;\n    vec3 object_pos;\n};\n\nuniform vec4 fa_mesh_vs_params[11];\nlayout(location = 0) out vec3 fa_world_pos;\nlayout(location = 1) out vec3 fa_world_normal;\nlayout(location = 2) out vec4 fa_world_tangent;\nlayout(location = 3) out vec2 fa_uv;\nlayout(location = 4) out vec4 fa_vertex_color;\nlayout(location = 5) out float fa_pre_depth;\nlayout(location = 6) out vec3 fa_pre_r0;\nlayout(location = 7) out vec3 fa_pre_r1;\nlayout(location = 8) out vec3 fa_pre_r2;\nlayout(location = 5) in vec4 fa_inst_m0;\nlayout(location = 6) in vec4 fa_inst_m1;\nlayout(location = 7) in vec4 fa_inst_m2;\nlayout(location = 8) in vec4 fa_inst_m3;\nlayout(location = 0) in vec3 fa_position;\nlayout(location = 1) in vec3 fa_normal;\nlayout(location = 3) in vec4 fa_tangent;\nlayout(location = 2) in vec2 fa_texcoord0;\nlayout(location = 4) in vec4 fa_color;\n\nvoid fa_inst_begin()\n{\n}\n\nVertexData fa_vertex_data(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    vec3 _69 = cross(model[1].xyz, model[2].xyz);\n    float _75 = (dot(model[0].xyz, _69) < 0.0) ? (-1.0) : 1.0;\n    return VertexData((model * vec4(position, 1.0)).xyz, (((_69 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _75, vec4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _75), texcoord0 * fa_mesh_vs_params[8].xy, color, position);\n}\n\nvoid fa_prepass_vertex(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    mat4 param = model;\n    vec3 param_1 = position;\n    vec3 param_2 = normal;\n    vec4 param_3 = tangent;\n    vec2 param_4 = texcoord0;\n    vec4 param_5 = color;\n    VertexData _160 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    vec3 _299 = _160.world_pos;\n    mat4 _164 = mat4(fa_mesh_vs_params[4], fa_mesh_vs_params[5], fa_mesh_vs_params[6], fa_mesh_vs_params[7]);\n    vec4 _171 = vec4(_299, 1.0);\n    fa_world_pos = _299;\n    fa_world_normal = _160.world_normal;\n    fa_world_tangent = _160.world_tangent;\n    fa_uv = _160.uv;\n    fa_vertex_color = _160.color;\n    fa_pre_depth = -(_164 * _171).z;\n    fa_pre_r0 = vec3(_164[0].x, _164[1].x, _164[2].x);\n    fa_pre_r1 = vec3(_164[0].y, _164[1].y, _164[2].y);\n    fa_pre_r2 = vec3(_164[0].z, _164[1].z, _164[2].z);\n    gl_Position = mat4(fa_mesh_vs_params[0], fa_mesh_vs_params[1], fa_mesh_vs_params[2], fa_mesh_vs_params[3]) * _171;\n}\n\nvoid main()\n{\n    fa_inst_begin();\n    mat4 param = mat4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3);\n    vec3 param_1 = fa_position;\n    vec3 param_2 = fa_normal;\n    vec4 param_3 = fa_tangent;\n    vec2 param_4 = fa_texcoord0;\n    vec4 param_5 = fa_color;\n    fa_prepass_vertex(param, param_1, param_2, param_3, param_4, param_5);\n}\n\n",
      "fs": "#version 430\n\nstruct SurfaceInput\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 vertex_color;\n    vec3 view_dir;\n    bool front_facing;\n};\n\nstruct Surface\n{\n    vec3 albedo;\n    float alpha;\n    vec3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    vec3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    vec3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    vec3 specular_color;\n};\n\nuniform vec4 fa_mesh_fs_params[24];\nlayout(binding = 0) uniform sampler2D fa_tex_fa_smp;\nlayout(binding = 1) uniform sampler2D fa_normal_tex_fa_smp;\nlayout(binding = 2) uniform sampler2D fa_mr_tex_fa_smp;\nlayout(binding = 3) uniform sampler2D fa_occlusion_tex_fa_smp;\nlayout(binding = 4) uniform sampler2D fa_emissive_tex_fa_smp;\n\nlayout(location = 0) in vec3 fa_world_pos;\nlayout(location = 1) in vec3 fa_world_normal;\nlayout(location = 2) in vec4 fa_world_tangent;\nlayout(location = 3) in vec2 fa_uv;\nlayout(location = 4) in vec4 fa_vertex_color;\nlayout(location = 6) in vec3 fa_pre_r0;\nlayout(location = 7) in vec3 fa_pre_r1;\nlayout(location = 8) in vec3 fa_pre_r2;\nlayout(location = 0) out vec4 fa_frag_color;\nlayout(location = 5) in float fa_pre_depth;\n\nvoid fa_inst_load()\n{\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nvec3 fa_linear_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_tex_fix(inout vec3 c, float mode)\n{\n    if (mode > 1.5)\n    {\n        vec3 param = c;\n        vec3 _172 = fa_linear_to_srgb(param);\n        c = _172;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            vec3 param_1 = c;\n            vec3 _181 = fa_srgb_to_linear(param_1);\n            c = _181;\n        }\n    }\n    return c;\n}\n\nvec3 fa_tangent_normal(SurfaceInput i, vec3 m)\n{\n    vec3 _56;\n    if (i.front_facing)\n    {\n        _56 = i.world_normal;\n    }\n    else\n    {\n        _56 = -i.world_normal;\n    }\n    vec3 _81 = normalize(i.world_tangent.xyz - (_56 * dot(_56, i.world_tangent.xyz)));\n    vec3 _109 = normalize(((_81 * m.x) + ((cross(_56, _81) * i.world_tangent.w) * m.y)) + (_56 * m.z));\n    vec3 _112;\n    if (i.front_facing)\n    {\n        _112 = _109;\n    }\n    else\n    {\n        _112 = -_109;\n    }\n    return _112;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    vec4 base_t = texture(fa_tex_fa_smp, i.uv);\n    float param = fa_mesh_fs_params[6].w;\n    float param_1 = 1.0;\n    vec3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    vec3 _225 = fa_tex_fix(param_2, param_3);\n    vec4 _784 = base_t;\n    _784.x = _225.x;\n    _784.y = _225.y;\n    _784.z = _225.z;\n    base_t = _784;\n    vec4 _241 = (_784 * fa_mesh_fs_params[2]) * i.vertex_color;\n    vec3 _747 = i.world_normal;\n    if (fa_mesh_fs_params[6].z > 0.5)\n    {\n        float param_4 = fa_mesh_fs_params[6].w;\n        float param_5 = 16.0;\n        vec3 param_6 = texture(fa_normal_tex_fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        vec3 _275 = fa_tex_fix(param_6, param_7);\n        vec3 _279 = (_275 * 2.0) - vec3(1.0);\n        vec2 _284 = _279.xy * fa_mesh_fs_params[6].x;\n        vec3 _792 = _279;\n        _792.x = _284.x;\n        _792.y = _284.y;\n        SurfaceInput param_8 = i;\n        vec3 param_9 = _792;\n        _747 = fa_tangent_normal(param_8, param_9);\n    }\n    vec4 mrt = texture(fa_mr_tex_fa_smp, i.uv);\n    float param_10 = fa_mesh_fs_params[6].w;\n    float param_11 = 64.0;\n    vec3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    vec3 _313 = fa_tex_fix(param_12, param_13);\n    vec4 _795 = mrt;\n    _795.x = _313.x;\n    _795.y = _313.y;\n    _795.z = _313.z;\n    mrt = _795;\n    vec4 _343 = texture(fa_occlusion_tex_fa_smp, i.uv);\n    float param_14 = fa_mesh_fs_params[6].w;\n    float param_15 = 256.0;\n    vec3 param_16 = _343.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    vec3 _355 = fa_tex_fix(param_16, param_17);\n    float param_18 = fa_mesh_fs_params[6].w;\n    float param_19 = 4.0;\n    vec3 param_20 = texture(fa_emissive_tex_fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    vec3 _385 = fa_tex_fix(param_20, param_21);\n    float _752 = fa_mesh_fs_params[20].x;\n    float _753 = fa_mesh_fs_params[20].y;\n    float _756 = fa_mesh_fs_params[20].z;\n    float _755 = fa_mesh_fs_params[21].w;\n    float _758 = fa_mesh_fs_params[22].x;\n    if (fa_mesh_fs_params[22].z > 0.5)\n    {\n        if (mod(fa_mesh_fs_params[22].z, 2.0) > 0.5)\n        {\n            _752 *= _355.y;\n            _753 *= _355.z;\n            _755 *= _343.w;\n        }\n        if (fa_mesh_fs_params[22].z > 1.5)\n        {\n            _756 *= mrt.x;\n            _758 *= mrt.w;\n        }\n    }\n    return Surface(_241.xyz, _241.w, _747, clamp(fa_mesh_fs_params[5].x * _313.z, 0.0, 1.0), clamp(fa_mesh_fs_params[5].y * _313.y, 0.0500000007450580596923828125, 1.0), 1.0 + (fa_mesh_fs_params[6].y * (_355.x - 1.0)), fa_mesh_fs_params[3].xyz + (fa_mesh_fs_params[4].xyz * _385), _752, _753, fa_mesh_fs_params[21].xyz, _755, _756, fa_mesh_fs_params[20].w, _758, fa_mesh_fs_params[22].y, fa_mesh_fs_params[23].xyz);\n}\n\nvoid surface(SurfaceInput i, Surface s)\n{\n}\n\nvoid main()\n{\n    fa_inst_load();\n    vec3 _658 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _658 = -_658;\n    }\n    vec3 _519 = normalize(fa_mesh_fs_params[0].xyz - fa_world_pos);\n    SurfaceInput param = SurfaceInput(fa_world_pos, _658, fa_world_tangent, fa_uv, fa_vertex_color, _519, gl_FrontFacing);\n    SurfaceInput param_1 = SurfaceInput(fa_world_pos, _658, fa_world_tangent, fa_uv, fa_vertex_color, _519, gl_FrontFacing);\n    Surface param_2 = fa_standard_surface(param);\n    surface(param_1, param_2);\n    vec3 _534 = normalize(param_2.normal);\n    vec3 _549 = normalize(vec3(dot(fa_pre_r0, _534), dot(fa_pre_r1, _534), dot(fa_pre_r2, _534)));\n    float _561 = _549.z;\n    vec2 e = _549.xy / vec2((abs(_549.x) + abs(_549.y)) + abs(_561));\n    if (_561 < 0.0)\n    {\n        e = (vec2(1.0) - abs(e.yx)) * vec2((e.x >= 0.0) ? 1.0 : (-1.0), (e.y >= 0.0) ? 1.0 : (-1.0));\n    }\n    fa_frag_color = vec4(min(fa_pre_depth, 60000.0), e, 1.0);\n}\n\n",
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
      "vs": "#version 430\n\nstruct VertexData\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 color;\n    vec3 object_pos;\n};\n\nuniform vec4 fa_mesh_vs_params[11];\nuniform vec4 fa_skin[192];\nlayout(location = 0) out vec3 fa_world_pos;\nlayout(location = 1) out vec3 fa_world_normal;\nlayout(location = 2) out vec4 fa_world_tangent;\nlayout(location = 3) out vec2 fa_uv;\nlayout(location = 4) out vec4 fa_vertex_color;\nlayout(location = 5) out float fa_pre_depth;\nlayout(location = 6) out vec3 fa_pre_r0;\nlayout(location = 7) out vec3 fa_pre_r1;\nlayout(location = 8) out vec3 fa_pre_r2;\nlayout(location = 5) in vec4 fa_inst_m0;\nlayout(location = 6) in vec4 fa_inst_m1;\nlayout(location = 7) in vec4 fa_inst_m2;\nlayout(location = 8) in vec4 fa_inst_m3;\nlayout(location = 9) in vec4 fa_joints;\nlayout(location = 10) in vec4 fa_weights;\nlayout(location = 0) in vec3 fa_position;\nlayout(location = 1) in vec3 fa_normal;\nlayout(location = 3) in vec4 fa_tangent;\nlayout(location = 2) in vec2 fa_texcoord0;\nlayout(location = 4) in vec4 fa_color;\n\nvoid fa_inst_begin()\n{\n}\n\nmat4 fa_skin_matrix(vec4 joints, vec4 weights)\n{\n    vec4 r0 = vec4(0.0);\n    vec4 r1 = vec4(0.0);\n    vec4 r2 = vec4(0.0);\n    for (int i = 0; i < 4; i++)\n    {\n        int _174 = int((joints[i] * 255.0) + 0.5) * 3;\n        r0 += (fa_skin[_174 * 1 + 0] * weights[i]);\n        r1 += (fa_skin[(_174 + 1) * 1 + 0] * weights[i]);\n        r2 += (fa_skin[(_174 + 2) * 1 + 0] * weights[i]);\n    }\n    return mat4(vec4(r0.x, r1.x, r2.x, 0.0), vec4(r0.y, r1.y, r2.y, 0.0), vec4(r0.z, r1.z, r2.z, 0.0), vec4(r0.w, r1.w, r2.w, 1.0));\n}\n\nVertexData fa_vertex_data(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    vec3 _74 = cross(model[1].xyz, model[2].xyz);\n    float _80 = (dot(model[0].xyz, _74) < 0.0) ? (-1.0) : 1.0;\n    return VertexData((model * vec4(position, 1.0)).xyz, (((_74 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _80, vec4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _80), texcoord0 * fa_mesh_vs_params[8].xy, color, position);\n}\n\nvoid fa_prepass_vertex(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    mat4 param = model;\n    vec3 param_1 = position;\n    vec3 param_2 = normal;\n    vec4 param_3 = tangent;\n    vec2 param_4 = texcoord0;\n    vec4 param_5 = color;\n    VertexData _273 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    vec3 _420 = _273.world_pos;\n    mat4 _277 = mat4(fa_mesh_vs_params[4], fa_mesh_vs_params[5], fa_mesh_vs_params[6], fa_mesh_vs_params[7]);\n    vec4 _284 = vec4(_420, 1.0);\n    fa_world_pos = _420;\n    fa_world_normal = _273.world_normal;\n    fa_world_tangent = _273.world_tangent;\n    fa_uv = _273.uv;\n    fa_vertex_color = _273.color;\n    fa_pre_depth = -(_277 * _284).z;\n    fa_pre_r0 = vec3(_277[0].x, _277[1].x, _277[2].x);\n    fa_pre_r1 = vec3(_277[0].y, _277[1].y, _277[2].y);\n    fa_pre_r2 = vec3(_277[0].z, _277[1].z, _277[2].z);\n    gl_Position = mat4(fa_mesh_vs_params[0], fa_mesh_vs_params[1], fa_mesh_vs_params[2], fa_mesh_vs_params[3]) * _284;\n}\n\nvoid main()\n{\n    fa_inst_begin();\n    vec4 param = fa_joints;\n    vec4 param_1 = fa_weights;\n    mat4 param_2 = mat4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3) * fa_skin_matrix(param, param_1);\n    vec3 param_3 = fa_position;\n    vec3 param_4 = fa_normal;\n    vec4 param_5 = fa_tangent;\n    vec2 param_6 = fa_texcoord0;\n    vec4 param_7 = fa_color;\n    fa_prepass_vertex(param_2, param_3, param_4, param_5, param_6, param_7);\n}\n\n",
      "fs": "#version 430\n\nstruct SurfaceInput\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 vertex_color;\n    vec3 view_dir;\n    bool front_facing;\n};\n\nstruct Surface\n{\n    vec3 albedo;\n    float alpha;\n    vec3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    vec3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    vec3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    vec3 specular_color;\n};\n\nuniform vec4 fa_mesh_fs_params[24];\nlayout(binding = 0) uniform sampler2D fa_tex_fa_smp;\nlayout(binding = 1) uniform sampler2D fa_normal_tex_fa_smp;\nlayout(binding = 2) uniform sampler2D fa_mr_tex_fa_smp;\nlayout(binding = 3) uniform sampler2D fa_occlusion_tex_fa_smp;\nlayout(binding = 4) uniform sampler2D fa_emissive_tex_fa_smp;\n\nlayout(location = 0) in vec3 fa_world_pos;\nlayout(location = 1) in vec3 fa_world_normal;\nlayout(location = 2) in vec4 fa_world_tangent;\nlayout(location = 3) in vec2 fa_uv;\nlayout(location = 4) in vec4 fa_vertex_color;\nlayout(location = 6) in vec3 fa_pre_r0;\nlayout(location = 7) in vec3 fa_pre_r1;\nlayout(location = 8) in vec3 fa_pre_r2;\nlayout(location = 0) out vec4 fa_frag_color;\nlayout(location = 5) in float fa_pre_depth;\n\nvoid fa_inst_load()\n{\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nvec3 fa_linear_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_tex_fix(inout vec3 c, float mode)\n{\n    if (mode > 1.5)\n    {\n        vec3 param = c;\n        vec3 _172 = fa_linear_to_srgb(param);\n        c = _172;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            vec3 param_1 = c;\n            vec3 _181 = fa_srgb_to_linear(param_1);\n            c = _181;\n        }\n    }\n    return c;\n}\n\nvec3 fa_tangent_normal(SurfaceInput i, vec3 m)\n{\n    vec3 _56;\n    if (i.front_facing)\n    {\n        _56 = i.world_normal;\n    }\n    else\n    {\n        _56 = -i.world_normal;\n    }\n    vec3 _81 = normalize(i.world_tangent.xyz - (_56 * dot(_56, i.world_tangent.xyz)));\n    vec3 _109 = normalize(((_81 * m.x) + ((cross(_56, _81) * i.world_tangent.w) * m.y)) + (_56 * m.z));\n    vec3 _112;\n    if (i.front_facing)\n    {\n        _112 = _109;\n    }\n    else\n    {\n        _112 = -_109;\n    }\n    return _112;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    vec4 base_t = texture(fa_tex_fa_smp, i.uv);\n    float param = fa_mesh_fs_params[6].w;\n    float param_1 = 1.0;\n    vec3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    vec3 _225 = fa_tex_fix(param_2, param_3);\n    vec4 _784 = base_t;\n    _784.x = _225.x;\n    _784.y = _225.y;\n    _784.z = _225.z;\n    base_t = _784;\n    vec4 _241 = (_784 * fa_mesh_fs_params[2]) * i.vertex_color;\n    vec3 _747 = i.world_normal;\n    if (fa_mesh_fs_params[6].z > 0.5)\n    {\n        float param_4 = fa_mesh_fs_params[6].w;\n        float param_5 = 16.0;\n        vec3 param_6 = texture(fa_normal_tex_fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        vec3 _275 = fa_tex_fix(param_6, param_7);\n        vec3 _279 = (_275 * 2.0) - vec3(1.0);\n        vec2 _284 = _279.xy * fa_mesh_fs_params[6].x;\n        vec3 _792 = _279;\n        _792.x = _284.x;\n        _792.y = _284.y;\n        SurfaceInput param_8 = i;\n        vec3 param_9 = _792;\n        _747 = fa_tangent_normal(param_8, param_9);\n    }\n    vec4 mrt = texture(fa_mr_tex_fa_smp, i.uv);\n    float param_10 = fa_mesh_fs_params[6].w;\n    float param_11 = 64.0;\n    vec3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    vec3 _313 = fa_tex_fix(param_12, param_13);\n    vec4 _795 = mrt;\n    _795.x = _313.x;\n    _795.y = _313.y;\n    _795.z = _313.z;\n    mrt = _795;\n    vec4 _343 = texture(fa_occlusion_tex_fa_smp, i.uv);\n    float param_14 = fa_mesh_fs_params[6].w;\n    float param_15 = 256.0;\n    vec3 param_16 = _343.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    vec3 _355 = fa_tex_fix(param_16, param_17);\n    float param_18 = fa_mesh_fs_params[6].w;\n    float param_19 = 4.0;\n    vec3 param_20 = texture(fa_emissive_tex_fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    vec3 _385 = fa_tex_fix(param_20, param_21);\n    float _752 = fa_mesh_fs_params[20].x;\n    float _753 = fa_mesh_fs_params[20].y;\n    float _756 = fa_mesh_fs_params[20].z;\n    float _755 = fa_mesh_fs_params[21].w;\n    float _758 = fa_mesh_fs_params[22].x;\n    if (fa_mesh_fs_params[22].z > 0.5)\n    {\n        if (mod(fa_mesh_fs_params[22].z, 2.0) > 0.5)\n        {\n            _752 *= _355.y;\n            _753 *= _355.z;\n            _755 *= _343.w;\n        }\n        if (fa_mesh_fs_params[22].z > 1.5)\n        {\n            _756 *= mrt.x;\n            _758 *= mrt.w;\n        }\n    }\n    return Surface(_241.xyz, _241.w, _747, clamp(fa_mesh_fs_params[5].x * _313.z, 0.0, 1.0), clamp(fa_mesh_fs_params[5].y * _313.y, 0.0500000007450580596923828125, 1.0), 1.0 + (fa_mesh_fs_params[6].y * (_355.x - 1.0)), fa_mesh_fs_params[3].xyz + (fa_mesh_fs_params[4].xyz * _385), _752, _753, fa_mesh_fs_params[21].xyz, _755, _756, fa_mesh_fs_params[20].w, _758, fa_mesh_fs_params[22].y, fa_mesh_fs_params[23].xyz);\n}\n\nvoid surface(SurfaceInput i, Surface s)\n{\n}\n\nvoid main()\n{\n    fa_inst_load();\n    vec3 _658 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _658 = -_658;\n    }\n    vec3 _519 = normalize(fa_mesh_fs_params[0].xyz - fa_world_pos);\n    SurfaceInput param = SurfaceInput(fa_world_pos, _658, fa_world_tangent, fa_uv, fa_vertex_color, _519, gl_FrontFacing);\n    SurfaceInput param_1 = SurfaceInput(fa_world_pos, _658, fa_world_tangent, fa_uv, fa_vertex_color, _519, gl_FrontFacing);\n    Surface param_2 = fa_standard_surface(param);\n    surface(param_1, param_2);\n    vec3 _534 = normalize(param_2.normal);\n    vec3 _549 = normalize(vec3(dot(fa_pre_r0, _534), dot(fa_pre_r1, _534), dot(fa_pre_r2, _534)));\n    float _561 = _549.z;\n    vec2 e = _549.xy / vec2((abs(_549.x) + abs(_549.y)) + abs(_561));\n    if (_561 < 0.0)\n    {\n        e = (vec2(1.0) - abs(e.yx)) * vec2((e.x >= 0.0) ? 1.0 : (-1.0), (e.y >= 0.0) ? 1.0 : (-1.0));\n    }\n    fa_frag_color = vec4(min(fa_pre_depth, 60000.0), e, 1.0);\n}\n\n",
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
