{
  "format": "factoria.shader/1",
  "engine": "0.32.0",
  "template": "4a8331d4c52f4add9385ad09f3cee754aeec6a52a5c8c810972e182590f5426b",
  "slang": "glsl430",
  "params": [],
  "textures": [],
  "programs": {
    "mesh": {
      "vs": "#version 430\n\nstruct VertexData\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 color;\n    vec3 object_pos;\n};\n\nuniform vec4 fa_mesh_vs_params[11];\nlayout(location = 0) out vec3 fa_world_pos;\nlayout(location = 1) out vec3 fa_world_normal;\nlayout(location = 2) out vec4 fa_world_tangent;\nlayout(location = 3) out vec2 fa_uv;\nlayout(location = 4) out vec4 fa_vertex_color;\nlayout(location = 5) in vec4 fa_inst_m0;\nlayout(location = 6) in vec4 fa_inst_m1;\nlayout(location = 7) in vec4 fa_inst_m2;\nlayout(location = 8) in vec4 fa_inst_m3;\nlayout(location = 0) in vec3 fa_position;\nlayout(location = 1) in vec3 fa_normal;\nlayout(location = 3) in vec4 fa_tangent;\nlayout(location = 2) in vec2 fa_texcoord0;\nlayout(location = 4) in vec4 fa_color;\nlayout(location = 5) out vec3 fa_lm;\n\nvoid fa_inst_begin()\n{\n}\n\nVertexData fa_vertex_data(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    vec3 _69 = cross(model[1].xyz, model[2].xyz);\n    float _75 = (dot(model[0].xyz, _69) < 0.0) ? (-1.0) : 1.0;\n    return VertexData((model * vec4(position, 1.0)).xyz, (((_69 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _75, vec4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _75), texcoord0 * fa_mesh_vs_params[8].xy, color, position);\n}\n\nvoid fa_shade_vertex(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    mat4 param = model;\n    vec3 param_1 = position;\n    vec3 param_2 = normal;\n    vec4 param_3 = tangent;\n    vec2 param_4 = texcoord0;\n    vec4 param_5 = color;\n    VertexData _160 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    vec3 _267 = _160.world_pos;\n    fa_world_pos = _267;\n    fa_world_normal = _160.world_normal;\n    fa_world_tangent = _160.world_tangent;\n    fa_uv = _160.uv;\n    fa_vertex_color = _160.color;\n    gl_Position = mat4(fa_mesh_vs_params[0], fa_mesh_vs_params[1], fa_mesh_vs_params[2], fa_mesh_vs_params[3]) * vec4(_267, 1.0);\n}\n\nvoid main()\n{\n    fa_inst_begin();\n    mat4 param = mat4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3);\n    vec3 param_1 = fa_position;\n    vec3 param_2 = fa_normal;\n    vec4 param_3 = fa_tangent;\n    vec2 param_4 = fa_texcoord0;\n    vec4 param_5 = fa_color;\n    fa_shade_vertex(param, param_1, param_2, param_3, param_4, param_5);\n    fa_lm = vec3(0.0);\n}\n\n",
      "fs": "#version 430\n\nstruct SurfaceInput\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 vertex_color;\n    vec3 view_dir;\n    bool front_facing;\n};\n\nstruct LightSample\n{\n    vec3 direction;\n    vec3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct Surface\n{\n    vec3 albedo;\n    float alpha;\n    vec3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    vec3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    vec3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    vec3 specular_color;\n    float transmission;\n    float thickness;\n    vec3 attenuation_color;\n    float attenuation_distance;\n};\n\nuniform vec4 fa_mesh_fs_params[53];\nuniform vec4 fa_shadows[30];\nlayout(binding = 0) uniform sampler2D fa_light_tex_fa_shadow_smp;\nlayout(binding = 1) uniform sampler2D fa_tex_fa_smp;\nlayout(binding = 2) uniform sampler2D fa_normal_tex_fa_smp;\nlayout(binding = 3) uniform sampler2D fa_mr_tex_fa_smp;\nlayout(binding = 4) uniform sampler2D fa_occlusion_tex_fa_smp;\nlayout(binding = 5) uniform sampler2D fa_emissive_tex_fa_smp;\nlayout(binding = 6) uniform sampler2D fa_decal_tex_fa_env_smp;\nlayout(binding = 7) uniform sampler2D fa_lightmap_fa_env_smp;\nlayout(binding = 8) uniform sampler2D fa_probe_atlas_fa_env_smp;\nlayout(binding = 9) uniform sampler2D fa_light_atlas_fa_env_smp;\nlayout(binding = 10) uniform sampler2D fa_shadow_tex_fa_shadow_smp;\nlayout(binding = 11) uniform sampler2D fa_screen_tex_fa_shadow_smp;\n\nlayout(location = 0) in vec3 fa_world_pos;\nlayout(location = 5) in vec3 fa_lm;\nlayout(location = 1) in vec3 fa_world_normal;\nlayout(location = 2) in vec4 fa_world_tangent;\nlayout(location = 3) in vec2 fa_uv;\nlayout(location = 4) in vec4 fa_vertex_color;\nlayout(location = 0) out vec4 fa_frag_color;\nvec3 fa_light_tint;\nbool fa_light_is_area;\nint fa_cl_ndir;\nint fa_cl_slot;\nint fa_cl_local;\n\nvoid fa_inst_load()\n{\n}\n\nvec4 fa_light_texel(int t)\n{\n    return texelFetch(fa_light_tex_fa_shadow_smp, ivec2(t & 1023, t >> 10), 0);\n}\n\nvec4 fa_cluster_texel(vec3 world_pos)\n{\n    bool _1350 = fa_mesh_fs_params[19].x < 0.0;\n    bool _1357;\n    if (!_1350)\n    {\n        _1357 = fa_mesh_fs_params[19].w < 1.0;\n    }\n    else\n    {\n        _1357 = _1350;\n    }\n    bool _1365;\n    if (!_1357)\n    {\n        _1365 = fa_mesh_fs_params[18].x < 1.0;\n    }\n    else\n    {\n        _1365 = _1357;\n    }\n    bool _1372;\n    if (!_1365)\n    {\n        _1372 = fa_mesh_fs_params[18].y < 1.0;\n    }\n    else\n    {\n        _1372 = _1365;\n    }\n    bool _1379;\n    if (!_1372)\n    {\n        _1379 = fa_mesh_fs_params[19].y < 1.0;\n    }\n    else\n    {\n        _1379 = _1372;\n    }\n    if (_1379)\n    {\n        return vec4(0.0);\n    }\n    vec4 _1389 = vec4(world_pos, 1.0);\n    float _1395 = dot(fa_mesh_fs_params[16], _1389);\n    if (!(_1395 > 9.9999999747524270787835121154785e-07))\n    {\n        return vec4(0.0);\n    }\n    vec2 _1417 = vec2(dot(fa_mesh_fs_params[14], _1389), dot(fa_mesh_fs_params[15], _1389)) / vec2(_1395);\n    int _1421 = int(fa_mesh_fs_params[18].x);\n    int _1425 = int(fa_mesh_fs_params[18].y);\n    int param = (int(fa_mesh_fs_params[19].x) + (((clamp(int(floor(log2(max(dot(fa_mesh_fs_params[17].xyz, world_pos) + fa_mesh_fs_params[17].w, fa_mesh_fs_params[18].w) / fa_mesh_fs_params[18].w) * fa_mesh_fs_params[18].z)), 0, int(fa_mesh_fs_params[19].y) - 1) * _1425) + clamp(int(floor(((_1417.y * 0.5) + 0.5) * fa_mesh_fs_params[18].y)), 0, _1425 - 1)) * _1421)) + clamp(int(floor(((_1417.x * 0.5) + 0.5) * fa_mesh_fs_params[18].x)), 0, _1421 - 1);\n    return fa_light_texel(param);\n}\n\nivec2 fa_cluster_lookup(vec3 world_pos)\n{\n    vec3 param = world_pos;\n    vec4 _1501 = fa_cluster_texel(param);\n    return ivec2(int(_1501.x), int(_1501.y));\n}\n\nvoid fa_cluster_begin(vec3 world_pos)\n{\n    fa_cl_ndir = int(fa_mesh_fs_params[19].z);\n    vec3 param = world_pos;\n    ivec2 _3728 = fa_cluster_lookup(param);\n    fa_cl_slot = _3728.x;\n    fa_cl_local = _3728.y;\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_linear_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvec3 fa_tex_fix(inout vec3 c, float mode)\n{\n    if (mode > 1.5)\n    {\n        vec3 param = c;\n        vec3 _3936 = fa_linear_to_srgb(param);\n        c = _3936;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            vec3 param_1 = c;\n            vec3 _3944 = fa_srgb_to_linear(param_1);\n            c = _3944;\n        }\n    }\n    return c;\n}\n\nvec3 fa_tangent_normal(SurfaceInput i, vec3 m)\n{\n    vec3 _304;\n    if (i.front_facing)\n    {\n        _304 = i.world_normal;\n    }\n    else\n    {\n        _304 = -i.world_normal;\n    }\n    vec3 _328 = normalize(i.world_tangent.xyz - (_304 * dot(_304, i.world_tangent.xyz)));\n    vec3 _355 = normalize(((_328 * m.x) + ((cross(_304, _328) * i.world_tangent.w) * m.y)) + (_304 * m.z));\n    vec3 _358;\n    if (i.front_facing)\n    {\n        _358 = _355;\n    }\n    else\n    {\n        _358 = -_355;\n    }\n    return _358;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    vec4 base_t = texture(fa_tex_fa_smp, i.uv);\n    float param = fa_mesh_fs_params[6].w;\n    float param_1 = 1.0;\n    vec3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    vec3 _3975 = fa_tex_fix(param_2, param_3);\n    vec4 _5708 = base_t;\n    _5708.x = _3975.x;\n    _5708.y = _3975.y;\n    _5708.z = _3975.z;\n    base_t = _5708;\n    vec4 _3989 = (_5708 * fa_mesh_fs_params[2]) * i.vertex_color;\n    vec3 _5545 = i.world_normal;\n    if (fa_mesh_fs_params[6].z > 0.5)\n    {\n        float param_4 = fa_mesh_fs_params[6].w;\n        float param_5 = 16.0;\n        vec3 param_6 = texture(fa_normal_tex_fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        vec3 _4021 = fa_tex_fix(param_6, param_7);\n        vec3 _4024 = (_4021 * 2.0) - vec3(1.0);\n        vec2 _4029 = _4024.xy * fa_mesh_fs_params[6].x;\n        vec3 _5716 = _4024;\n        _5716.x = _4029.x;\n        _5716.y = _4029.y;\n        SurfaceInput param_8 = i;\n        vec3 param_9 = _5716;\n        _5545 = fa_tangent_normal(param_8, param_9);\n    }\n    vec4 mrt = texture(fa_mr_tex_fa_smp, i.uv);\n    float param_10 = fa_mesh_fs_params[6].w;\n    float param_11 = 64.0;\n    vec3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    vec3 _4057 = fa_tex_fix(param_12, param_13);\n    vec4 _5719 = mrt;\n    _5719.x = _4057.x;\n    _5719.y = _4057.y;\n    _5719.z = _4057.z;\n    mrt = _5719;\n    vec4 _4085 = texture(fa_occlusion_tex_fa_smp, i.uv);\n    float param_14 = fa_mesh_fs_params[6].w;\n    float param_15 = 256.0;\n    vec3 param_16 = _4085.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    vec3 _4096 = fa_tex_fix(param_16, param_17);\n    float param_18 = fa_mesh_fs_params[6].w;\n    float param_19 = 4.0;\n    vec3 param_20 = texture(fa_emissive_tex_fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    vec3 _4126 = fa_tex_fix(param_20, param_21);\n    float _5550 = fa_mesh_fs_params[20].x;\n    float _5551 = fa_mesh_fs_params[20].y;\n    float _5554 = fa_mesh_fs_params[20].z;\n    float _5553 = fa_mesh_fs_params[21].w;\n    float _5556 = fa_mesh_fs_params[22].x;\n    if (fa_mesh_fs_params[22].z > 0.5)\n    {\n        if (mod(fa_mesh_fs_params[22].z, 2.0) > 0.5)\n        {\n            _5550 *= _4096.y;\n            _5551 *= _4096.z;\n            _5553 *= _4085.w;\n        }\n        if (fa_mesh_fs_params[22].z > 1.5)\n        {\n            _5554 *= mrt.x;\n            _5556 *= mrt.w;\n        }\n    }\n    return Surface(_3989.xyz, _3989.w, _5545, clamp(fa_mesh_fs_params[5].x * _4057.z, 0.0, 1.0), clamp(fa_mesh_fs_params[5].y * _4057.y, 0.0500000007450580596923828125, 1.0), 1.0 + (fa_mesh_fs_params[6].y * (_4096.x - 1.0)), fa_mesh_fs_params[3].xyz + (fa_mesh_fs_params[4].xyz * _4126), _5550, _5551, fa_mesh_fs_params[21].xyz, _5553, _5554, fa_mesh_fs_params[20].w, _5556, fa_mesh_fs_params[22].y, fa_mesh_fs_params[23].xyz, fa_mesh_fs_params[30].x, fa_mesh_fs_params[30].y, fa_mesh_fs_params[31].xyz, fa_mesh_fs_params[30].z);\n}\n\nvoid surface(SurfaceInput i, Surface s)\n{\n}\n\nvec4 fa_decal_tile(vec4 rect, vec2 uv, vec2 atlas, vec2 ddx, vec2 ddy)\n{\n    vec2 _1581 = rect.zw - rect.xy;\n    vec2 _1585 = _1581 * atlas;\n    vec2 _1589 = ddx * _1585;\n    vec2 _1593 = ddy * _1585;\n    return textureLod(fa_decal_tex_fa_env_smp, rect.xy + (clamp(uv, vec2(0.0), vec2(1.0)) * _1581), clamp(0.5 * log2(max(max(dot(_1589, _1589), dot(_1593, _1593)), 9.9999999392252902907785028219223e-09)), 0.0, 4.0));\n}\n\nvec3 fa_dc_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_dc_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvoid fa_apply_decals(vec3 world_pos, vec3 geo_normal, inout vec3 albedo, inout vec3 normal)\n{\n    bool _1626 = fa_mesh_fs_params[10].y < 0.5;\n    bool _1633;\n    if (!_1626)\n    {\n        _1633 = fa_mesh_fs_params[10].w < 0.5;\n    }\n    else\n    {\n        _1633 = _1626;\n    }\n    if (_1633)\n    {\n        return;\n    }\n    vec3 _1639 = dFdx(world_pos);\n    vec3 _1642 = dFdy(world_pos);\n    vec3 param = world_pos;\n    vec4 _1646 = fa_cluster_texel(param);\n    int _1650 = int(_1646.w);\n    if (_1650 < 1)\n    {\n        return;\n    }\n    int _1660 = int(fa_mesh_fs_params[10].y + 0.5);\n    int param_1 = _1660;\n    vec4 _1664 = fa_light_texel(param_1);\n    vec2 _1667 = _1664.yz;\n    int _1671 = int(_1664.w);\n    int param_2 = _1660 + 1;\n    vec4 _1676 = fa_light_texel(param_2);\n    float _1677 = _1676.x;\n    int _1683 = int(fa_mesh_fs_params[10].w + 0.5) - 1;\n    int _1687 = int(_1646.z);\n    vec3 _1952;\n    for (int k = 0; k < _1650; k++)\n    {\n        int _1700 = _1687 + k;\n        int param_3 = _1671 + (_1700 >> 2);\n        int _1717 = (_1660 + 2) + (int(fa_light_texel(param_3)[_1700 & 3]) * 7);\n        int param_4 = _1717 + 6;\n        vec4 _1722 = fa_light_texel(param_4);\n        if (((int(_1722.w + 0.5) >> _1683) & 1) == 0)\n        {\n            continue;\n        }\n        int param_5 = _1717;\n        vec4 _1737 = fa_light_texel(param_5);\n        int param_6 = _1717 + 1;\n        vec4 _1742 = fa_light_texel(param_6);\n        int param_7 = _1717 + 2;\n        vec4 _1747 = fa_light_texel(param_7);\n        vec3 _1750 = _1737.xyz;\n        float _1755 = dot(_1750, world_pos) + _1737.w;\n        vec3 _1757 = _1742.xyz;\n        float _1762 = dot(_1757, world_pos) + _1742.w;\n        vec3 _1764 = _1747.xyz;\n        float _1769 = dot(_1764, world_pos) + _1747.w;\n        bool _1774 = abs(_1755) > 0.5;\n        bool _1782;\n        if (!_1774)\n        {\n            _1782 = abs(_1762) > 0.5;\n        }\n        else\n        {\n            _1782 = _1774;\n        }\n        bool _1790;\n        if (!_1782)\n        {\n            _1790 = abs(_1769) > 0.5;\n        }\n        else\n        {\n            _1790 = _1782;\n        }\n        if (_1790)\n        {\n            continue;\n        }\n        float _1805 = clamp(dot(geo_normal, normalize(_1764)) * _1722.z, 0.0, 1.0);\n        if (_1805 <= 0.0)\n        {\n            continue;\n        }\n        float _1825 = (clamp((0.5 - abs(_1769)) * 10.0, 0.0, 1.0) * _1805) * _1722.x;\n        vec2 _1833 = vec2(_1755 + 0.5, 0.5 - _1762);\n        vec2 _1843 = vec2(dot(_1750, _1639), dot(_1757, _1639));\n        vec2 _1853 = vec2(dot(_1750, _1642), dot(_1757, _1642));\n        int param_8 = _1717 + 5;\n        vec4 _1858 = fa_light_texel(param_8);\n        int param_9 = _1717 + 3;\n        vec4 _1863 = fa_light_texel(param_9);\n        int param_10 = _1717 + 4;\n        vec4 _1868 = fa_light_texel(param_10);\n        float tex_a = 1.0;\n        vec3 col = _1858.xyz;\n        bool _1878 = _1863.z > _1863.x;\n        if (_1878)\n        {\n            vec4 param_11 = _1863;\n            vec2 param_12 = _1833;\n            vec2 param_13 = _1667;\n            vec2 param_14 = _1843;\n            vec2 param_15 = _1853;\n            vec4 tx = fa_decal_tile(param_11, param_12, param_13, param_14, param_15);\n            if ((_1677 > 0.5) && (_1677 < 1.5))\n            {\n                vec3 param_16 = tx.xyz;\n                vec3 _1904 = fa_dc_to_linear(param_16);\n                vec4 _5633 = tx;\n                _5633.x = _1904.x;\n                _5633.y = _1904.y;\n                _5633.z = _1904.z;\n                tx = _5633;\n            }\n            col *= tx.xyz;\n            tex_a = tx.w;\n        }\n        albedo = mix(albedo, col, vec3(clamp((_1825 * tex_a) * _1858.w, 0.0, 1.0)));\n        if (_1868.z > _1868.x)\n        {\n            vec4 param_17 = _1868;\n            vec2 param_18 = _1833;\n            vec2 param_19 = _1667;\n            vec2 param_20 = _1843;\n            vec2 param_21 = _1853;\n            vec4 _1948 = fa_decal_tile(param_17, param_18, param_19, param_20, param_21);\n            if (_1677 > 1.5)\n            {\n                vec3 param_22 = _1948.xyz;\n                vec3 _1958 = fa_dc_to_srgb(param_22);\n                _1952 = _1958;\n            }\n            else\n            {\n                _1952 = _1948.xyz;\n            }\n            vec3 _1967 = (_1952 * 2.0) - vec3(1.0);\n            vec2 _1972 = _1967.xy * _1722.y;\n            vec3 _1994 = (normalize(_1750) * _1972.x) + (normalize(_1757) * _1972.y);\n            vec3 _1997 = normalize(normal);\n            normal = normalize(mix(_1997, normalize((_1997 * max(_1967.z, 0.0500000007450580596923828125)) + (_1994 - (_1997 * dot(_1997, _1994)))), vec3(clamp(_1825 * (_1878 ? tex_a : 1.0), 0.0, 1.0))));\n        }\n    }\n}\n\nvec3 fa_sh_eval(vec3 c[9], vec3 n)\n{\n    vec3 _3192 = max((((c[0] * 0.2820948064327239990234375) + (((c[1] * (0.3257350027561187744140625 * n.y)) + (c[2] * (0.3257350027561187744140625 * n.z))) + (c[3] * (0.3257350027561187744140625 * n.x)))) + (((c[4] * ((0.2731371223926544189453125 * n.x) * n.y)) + (c[5] * ((0.2731371223926544189453125 * n.y) * n.z))) + (c[6] * (0.078847892582416534423828125 * (((3.0 * n.z) * n.z) - 1.0))))) + ((c[7] * ((0.2731371223926544189453125 * n.x) * n.z)) + (c[8] * (0.13656856119632720947265625 * ((n.x * n.x) - (n.y * n.y))))), vec3(0.0));\n    return _3192;\n}\n\nvec2 fa_atlas_size()\n{\n    return vec2(textureSize(fa_probe_atlas_fa_env_smp, 0));\n}\n\nvec4 fa_gi_fetch(vec2 texel)\n{\n    return textureLod(fa_probe_atlas_fa_env_smp, texel / fa_atlas_size(), 0.0);\n}\n\nvec2 fa_oct_encode(vec3 d)\n{\n    vec3 _3212 = d / vec3(max((abs(d.x) + abs(d.y)) + abs(d.z), 9.9999999600419720025001879548654e-13));\n    float _3215 = _3212.x;\n    float _3217 = _3212.z;\n    vec2 e = vec2(_3215, _3217);\n    if (_3212.y < 0.0)\n    {\n        e = vec2((1.0 - abs(_3217)) * ((_3215 < 0.0) ? (-1.0) : 1.0), (1.0 - abs(_3215)) * ((_3217 < 0.0) ? (-1.0) : 1.0));\n    }\n    return e;\n}\n\nvec3 fa_gi_grid(int rec, vec3 n, vec3 v, out float cover)\n{\n    cover = 0.0;\n    int param = rec;\n    vec4 _4240 = fa_light_texel(param);\n    int param_1 = rec + 1;\n    vec4 _4245 = fa_light_texel(param_1);\n    int param_2 = rec + 2;\n    vec4 _4250 = fa_light_texel(param_2);\n    int param_3 = rec + 3;\n    vec4 _4255 = fa_light_texel(param_3);\n    bool _4258 = _4255.z < 0.5;\n    bool _4266;\n    if (!_4258)\n    {\n        _4266 = fa_atlas_size().y < 1155.0;\n    }\n    else\n    {\n        _4266 = _4258;\n    }\n    if (_4266)\n    {\n        return vec3(0.0);\n    }\n    float _4273 = max(_4240.w, 9.9999997473787516355514526367188e-05);\n    vec3 _4276 = _4245.xyz;\n    vec3 _4280 = _4240.xyz;\n    vec3 _4284 = (fa_world_pos - _4280) / vec3(_4273);\n    vec3 _4293 = min(_4284 + vec3(0.5), (_4276 - vec3(0.5)) - _4284);\n    float _4302 = min(_4293.x, min(_4293.y, _4293.z));\n    if (!(_4302 > 0.0))\n    {\n        return vec3(0.0);\n    }\n    vec3 _4317 = _4276 - vec3(1.0);\n    vec3 _4318 = clamp(_4284, vec3(0.0), _4317);\n    vec3 _4326 = min(floor(_4318), max(_4276 - vec3(2.0), vec3(0.0)));\n    vec3 _4330 = _4318 - _4326;\n    vec3 _4342 = fa_world_pos + (((n * 0.800000011920928955078125) + (v * 0.20000000298023223876953125)) * (0.20000000298023223876953125 * _4273));\n    int _4347 = int(_4250.y + 0.5);\n    vec3 sh[9];\n    for (int k = 0; k < 9; k++)\n    {\n        sh[k] = vec3(0.0);\n    }\n    float wsum = 0.0;\n    int _4365 = int(_4255.w);\n    int _4366 = 8 + _4365;\n    int _4371 = 9 + _4365;\n    float _4398;\n    float _4411;\n    float _4425;\n    for (int k_1 = 0; k_1 < _4366; k_1++)\n    {\n        float _4384 = float(k_1 & 1);\n        float _4388 = float((k_1 >> 1) & 1);\n        float _4392 = float((k_1 >> 2) & 1);\n        if (_4384 > 0.5)\n        {\n            _4398 = _4330.x;\n        }\n        else\n        {\n            _4398 = 1.0 - _4330.x;\n        }\n        if (_4388 > 0.5)\n        {\n            _4411 = _4330.y;\n        }\n        else\n        {\n            _4411 = 1.0 - _4330.y;\n        }\n        if (_4392 > 0.5)\n        {\n            _4425 = _4330.z;\n        }\n        else\n        {\n            _4425 = 1.0 - _4330.z;\n        }\n        float _4435 = (_4398 * _4411) * _4425;\n        if (!(_4435 > 0.0))\n        {\n            continue;\n        }\n        vec3 _4448 = min(_4326 + vec3(_4384, _4388, _4392), _4317);\n        int _4468 = int(((_4250.x + _4448.x) + (_4245.x * (_4448.y + (_4245.y * _4448.z)))) + 0.5);\n        vec2 _4483 = vec2(float(_4468 % _4347) * 10.0, 1024.0 + (float(_4468 / _4347) * 11.0));\n        vec2 param_4 = _4483 + vec2(9.5, 10.5);\n        vec4 _4491 = fa_gi_fetch(param_4);\n        bool _4494 = _4491.y < 0.5;\n        bool _4503;\n        if (!_4494)\n        {\n            _4503 = _4491.x > _4255.y;\n        }\n        else\n        {\n            _4503 = _4494;\n        }\n        if (_4503)\n        {\n            continue;\n        }\n        vec3 _4515 = _4342 - (_4280 + (_4448 * _4273));\n        float _4518 = length(_4515);\n        vec3 _4524 = _4515 / vec3(max(_4518, 9.9999997473787516355514526367188e-05));\n        float _4534 = max(9.9999997473787516355514526367188e-05, (dot(-_4524, n) + 1.0) * 0.5);\n        float w = _4435 * (_4534 * _4534);\n        vec3 param_5 = _4524;\n        vec2 param_6 = (_4483 + vec2(1.0)) + (((fa_oct_encode(param_5) * 0.5) + vec2(0.5)) * 8.0);\n        vec4 _4553 = fa_gi_fetch(param_6);\n        float _4560 = _4518 / max(_4250.z, 9.9999997473787516355514526367188e-05);\n        float _4563 = _4553.x;\n        if (_4560 > _4563)\n        {\n            float _4576 = max(_4553.y - (_4563 * _4563), 0.0);\n            float _4581 = _4560 - _4563;\n            float _4590 = _4576 / max(_4576 + (_4581 * _4581), 9.9999999600419720025001879548654e-13);\n            w *= ((_4590 * _4590) * _4590);\n        }\n        if (!(w > 0.0))\n        {\n            continue;\n        }\n        for (int c = 0; c < _4371; c++)\n        {\n            vec2 param_7 = _4483 + vec2(float(c) + 0.5, 10.5);\n            sh[c] += (fa_gi_fetch(param_7).xyz * w);\n        }\n        wsum += w;\n    }\n    if (!(wsum > 9.9999997473787516355514526367188e-06))\n    {\n        return vec3(0.0);\n    }\n    for (int c_1 = 0; c_1 < 9; c_1++)\n    {\n        sh[c_1] /= vec3(wsum);\n    }\n    cover = smoothstep(0.0, 1.0, clamp(_4302 * 2.0, 0.0, 1.0)) * smoothstep(0.0, 0.0199999995529651641845703125, wsum);\n    float _4671;\n    if (fa_mesh_fs_params[52].z > 0.5)\n    {\n        _4671 = _4255.x;\n    }\n    else\n    {\n        _4671 = 1.0;\n    }\n    vec3 param_8[9] = sh;\n    vec3 param_9 = n;\n    return fa_sh_eval(param_8, param_9) * (_4250.w * _4671);\n}\n\nvec3 fa_gi_light(vec3 n, inout float left)\n{\n    left = 1.0;\n    vec3 acc = vec3(0.0);\n    vec3 _4695 = normalize(fa_mesh_fs_params[0].xyz - fa_world_pos);\n    int _4700 = int(fa_mesh_fs_params[52].x + 0.5);\n    int _4705 = int(fa_mesh_fs_params[52].y + 0.5);\n    float param_3;\n    for (int k = 0; (k < _4705) && (k < 8); k++)\n    {\n        int param = _4700 + (4 * k);\n        vec3 param_1 = n;\n        vec3 param_2 = _4695;\n        vec3 _4730 = fa_gi_grid(param, param_1, param_2, param_3);\n        float _4735 = param_3 * left;\n        acc += (_4730 * _4735);\n        left -= _4735;\n        if (left < 0.001000000047497451305389404296875)\n        {\n            left = 0.0;\n            break;\n        }\n    }\n    return acc;\n}\n\nvec3 fa_probe_sh_coef(vec2 origin, float res, int k)\n{\n    vec3 v = textureLod(fa_probe_atlas_fa_env_smp, (origin + vec2(float(k) + 0.5, res + 2.5)) / fa_atlas_size(), 0.0).xyz;\n    if (fa_mesh_fs_params[41].y > 0.5)\n    {\n        v = (v - vec3(0.5)) * 8.0;\n    }\n    return v;\n}\n\nvec3 fa_ambient_light(vec3 n)\n{\n    float _3299 = (1.0 - fa_mesh_fs_params[42].w) - fa_mesh_fs_params[47].w;\n    vec3 amb = vec3(0.0);\n    bool _3305 = fa_mesh_fs_params[11].w > 0.5;\n    vec3 c[9];\n    for (int k = 0; k < 9; k++)\n    {\n        c[k] = vec3(0.0);\n    }\n    if (_3299 > 0.0005000000237487256526947021484375)\n    {\n        if (_3305)\n        {\n            for (int k_1 = 0; k_1 < 9; k_1++)\n            {\n                vec2 param = fa_mesh_fs_params[41].zw;\n                float param_1 = 128.0;\n                int param_2 = k_1;\n                c[k_1] = fa_probe_sh_coef(param, param_1, param_2) * _3299;\n            }\n        }\n        else\n        {\n            amb = fa_mesh_fs_params[1].xyz * _3299;\n        }\n    }\n    bool _3358 = fa_mesh_fs_params[42].w > 0.0;\n    if (_3358)\n    {\n        for (int k_2 = 0; k_2 < 9; k_2++)\n        {\n            vec2 param_3 = fa_mesh_fs_params[42].xy;\n            float param_4 = fa_mesh_fs_params[42].z;\n            int param_5 = k_2;\n            c[k_2] += (fa_probe_sh_coef(param_3, param_4, param_5) * fa_mesh_fs_params[42].w);\n        }\n    }\n    bool _3389 = fa_mesh_fs_params[47].w > 0.0;\n    if (_3389)\n    {\n        for (int k_3 = 0; k_3 < 9; k_3++)\n        {\n            vec2 param_6 = fa_mesh_fs_params[47].xy;\n            float param_7 = fa_mesh_fs_params[47].z;\n            int param_8 = k_3;\n            c[k_3] += (fa_probe_sh_coef(param_6, param_7, param_8) * fa_mesh_fs_params[47].w);\n        }\n    }\n    if ((_3305 || _3358) || _3389)\n    {\n        vec3 param_9[9] = c;\n        vec3 param_10 = n;\n        amb += fa_sh_eval(param_9, param_10);\n    }\n    return amb;\n}\n\nvec3 fa_realtime_or_ambient(vec3 n)\n{\n    if (fa_mesh_fs_params[52].y > 0.5)\n    {\n        vec3 param = n;\n        float param_1;\n        vec3 _4764 = fa_gi_light(param, param_1);\n        if (param_1 < 0.999000012874603271484375)\n        {\n            vec3 _4773;\n            if (param_1 > 0.0)\n            {\n                vec3 param_2 = n;\n                _4773 = _4764 + (fa_ambient_light(param_2) * param_1);\n            }\n            else\n            {\n                _4773 = _4764;\n            }\n            return _4773;\n        }\n    }\n    vec3 param_3 = n;\n    return fa_ambient_light(param_3);\n}\n\nvec3 fa_indirect_diffuse(vec3 n)\n{\n    if (fa_lm.z > 0.5)\n    {\n        return textureLod(fa_lightmap_fa_env_smp, fa_lm.xy, 0.0).xyz;\n    }\n    if (fa_mesh_fs_params[32].w > 0.0)\n    {\n        vec3 c[9];\n        for (int k = 0; k < 9; k++)\n        {\n            c[k] = fa_mesh_fs_params[k * 1 + 32].xyz;\n        }\n        vec3 param[9] = c;\n        vec3 param_1 = n;\n        vec3 _4835 = fa_sh_eval(param, param_1);\n        if (fa_mesh_fs_params[32].w >= 1.0)\n        {\n            return _4835;\n        }\n        vec3 param_2 = n;\n        return mix(fa_realtime_or_ambient(param_2), _4835, vec3(clamp(fa_mesh_fs_params[32].w, 0.0, 1.0)));\n    }\n    vec3 param_3 = n;\n    return fa_realtime_or_ambient(param_3);\n}\n\nvec3 ambient(SurfaceInput i, Surface s, vec3 ambientColor)\n{\n    return ambientColor;\n}\n\nint fa_cluster_index(int slot, int n)\n{\n    int param = (int(fa_mesh_fs_params[19].x) + int(fa_mesh_fs_params[19].w)) + ((slot + n) >> 2);\n    vec4 t = fa_light_texel(param);\n    return int(t[(slot + n) & 3]);\n}\n\nint fa_cl_light(int n)\n{\n    if (n < fa_cl_ndir)\n    {\n        return n;\n    }\n    int param = fa_cl_slot;\n    int param_1 = n - fa_cl_ndir;\n    return fa_cluster_index(param, param_1);\n}\n\nint fa_light_base(int li)\n{\n    return li * ((fa_mesh_fs_params[1].w > 4.5) ? 8 : 4);\n}\n\nbool fa_light_baked(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 3;\n    return fa_light_texel(param_1).w > 0.5;\n}\n\nfloat fa_baked_keep(int li)\n{\n    float _3698;\n    if (fa_lm.z > 0.5)\n    {\n        _3698 = 0.0;\n    }\n    else\n    {\n        _3698 = 1.0 - clamp(fa_mesh_fs_params[32].w, 0.0, 1.0);\n    }\n    bool _3709 = _3698 < 1.0;\n    bool _3715;\n    if (_3709)\n    {\n        int param = li;\n        _3715 = fa_light_baked(param);\n    }\n    else\n    {\n        _3715 = _3709;\n    }\n    return _3715 ? _3698 : 1.0;\n}\n\nfloat fa_light_type(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 1;\n    return fa_light_texel(param_1).w;\n}\n\nvec3 fa_area_point(vec3 c, vec3 axis, vec3 ru, vec3 uu, float hx, float hy, float shape, vec3 p, vec3 r)\n{\n    bool _600 = dot(r, r) > 0.5;\n    if (shape > 1.5)\n    {\n        vec3 _613 = (c - (ru * hx)) - p;\n        vec3 _619 = ru * (2.0 * hx);\n        float _625 = max(dot(_619, _619), 9.9999999392252902907785028219223e-09);\n        float _629 = dot(_613, _619);\n        float t = clamp((-_629) / _625, 0.0, 1.0);\n        if (_600)\n        {\n            float _644 = dot(r, _619);\n            float _650 = _625 - (_644 * _644);\n            if (abs(_650) > (9.9999997473787516355514526367188e-06 * _625))\n            {\n                t = clamp(((dot(r, _613) * _644) - _629) / _650, 0.0, 1.0);\n            }\n        }\n        return (p + _613) + (_619 * t);\n    }\n    vec3 q = p;\n    float _682 = dot(r, axis);\n    bool _690;\n    if (_600)\n    {\n        _690 = abs(_682) > 9.9999997473787516355514526367188e-05;\n    }\n    else\n    {\n        _690 = _600;\n    }\n    if (_690)\n    {\n        float _700 = dot(c - p, axis) / _682;\n        if (_700 > 0.0)\n        {\n            q = p + (r * _700);\n        }\n    }\n    vec3 _713 = q - c;\n    vec2 xy = vec2(dot(_713, ru), dot(_713, uu));\n    if (shape > 0.5)\n    {\n        float _728 = length(xy);\n        if (_728 > hx)\n        {\n            xy *= (hx / _728);\n        }\n    }\n    else\n    {\n        xy = clamp(xy, vec2(-hx, -hy), vec2(hx, hy));\n    }\n    return (c + (ru * xy.x)) + (uu * xy.y);\n}\n\nvec4 fa_atlas_fetch(vec2 texel)\n{\n    return textureLod(fa_light_atlas_fa_env_smp, texel / vec2(textureSize(fa_light_atlas_fa_env_smp, 0)), 0.0);\n}\n\nvec3 fa_cookie_sample(vec2 tile_origin, vec2 uv)\n{\n    vec2 param = (tile_origin + vec2(1.0)) + (clamp(uv, vec2(0.0), vec2(1.0)) * 254.0);\n    return fa_atlas_fetch(param).xyz;\n}\n\nfloat fa_ies_sample(vec2 tile_origin, vec3 d, vec3 axis, vec3 right, vec3 up)\n{\n    float _520 = dot(d, right);\n    float _524 = dot(d, up);\n    float _535;\n    if (((_520 * _520) + (_524 * _524)) > 1.0000000133514319600180897396058e-10)\n    {\n        _535 = atan(_524, _520) * 0.15915493667125701904296875;\n    }\n    else\n    {\n        _535 = 0.0;\n    }\n    vec2 param = tile_origin + vec2(1.0 + ((_535 - floor(_535)) * 64.0), 1.0 + (acos(clamp(dot(d, axis), -1.0, 1.0)) * 10.18591594696044921875));\n    return fa_atlas_fetch(param).x;\n}\n\nint fa_cube_face(vec3 d)\n{\n    vec3 _370 = abs(d);\n    float _372 = _370.x;\n    float _374 = _370.y;\n    bool _375 = _372 >= _374;\n    bool _383;\n    if (_375)\n    {\n        _383 = _372 >= _370.z;\n    }\n    else\n    {\n        _383 = _375;\n    }\n    int _384;\n    if (_383)\n    {\n        _384 = (d.x > 0.0) ? 0 : 1;\n    }\n    else\n    {\n        int _399;\n        if (_374 >= _370.z)\n        {\n            _399 = (d.y > 0.0) ? 2 : 3;\n        }\n        else\n        {\n            _399 = (d.z > 0.0) ? 4 : 5;\n        }\n        _384 = _399;\n    }\n    return _384;\n}\n\nvoid fa_cube_face_basis(int f, out vec3 fwd, out vec3 up)\n{\n    if (f == 0)\n    {\n        fwd = vec3(1.0, 0.0, 0.0);\n        up = vec3(0.0, 1.0, 0.0);\n    }\n    else\n    {\n        if (f == 1)\n        {\n            fwd = vec3(-1.0, 0.0, 0.0);\n            up = vec3(0.0, 1.0, 0.0);\n        }\n        else\n        {\n            if (f == 2)\n            {\n                fwd = vec3(0.0, 1.0, 0.0);\n                up = vec3(0.0, 0.0, 1.0);\n            }\n            else\n            {\n                if (f == 3)\n                {\n                    fwd = vec3(0.0, -1.0, 0.0);\n                    up = vec3(0.0, 0.0, -1.0);\n                }\n                else\n                {\n                    if (f == 4)\n                    {\n                        fwd = vec3(0.0, 0.0, 1.0);\n                        up = vec3(0.0, 1.0, 0.0);\n                    }\n                    else\n                    {\n                        fwd = vec3(0.0, 0.0, -1.0);\n                        up = vec3(0.0, 1.0, 0.0);\n                    }\n                }\n            }\n        }\n    }\n}\n\nLightSample fa_light_sample_n(int li, vec3 world_pos, vec3 n)\n{\n    int param = li;\n    int _766 = fa_light_base(param);\n    bool _770 = fa_mesh_fs_params[1].w > 4.5;\n    int param_1 = _766;\n    vec4 _774 = fa_light_texel(param_1);\n    int param_2 = _766 + 1;\n    vec4 _779 = fa_light_texel(param_2);\n    float _782 = _779.w;\n    float atten = 1.0;\n    float dist = 0.0;\n    fa_light_tint = vec3(1.0);\n    bool _794 = _770 && (_782 > 2.5);\n    fa_light_is_area = _794;\n    bool _796 = _782 < 0.5;\n    vec3 l;\n    if (_796)\n    {\n        l = normalize(_774.xyz);\n        if (_770)\n        {\n            int param_3 = _766 + 6;\n            vec4 _810 = fa_light_texel(param_3);\n            if (_810.z > 0.5)\n            {\n                int param_4 = _766 + 4;\n                vec4 _820 = fa_light_texel(param_4);\n                int param_5 = _766 + 5;\n                vec4 _825 = fa_light_texel(param_5);\n                vec2 param_6 = _810.xy;\n                vec2 param_7 = fract(vec2(dot(world_pos, _820.xyz) * _820.w, (-dot(world_pos, _825.xyz)) * _825.w) + vec2(0.5));\n                fa_light_tint = fa_cookie_sample(param_6, param_7);\n            }\n        }\n    }\n    else\n    {\n        vec3 _855 = _774.xyz;\n        vec3 _857 = _855 - world_pos;\n        vec3 to_light = _857;\n        float _860 = length(_857);\n        float reach = _860;\n        bool front = true;\n        if (_794)\n        {\n            int param_8 = _766 + 7;\n            reach = max(_860 - fa_light_texel(param_8).w, 0.0);\n            int param_9 = _766 + 4;\n            vec4 _884 = fa_light_texel(param_9);\n            int param_10 = _766 + 5;\n            vec4 _889 = fa_light_texel(param_10);\n            int param_11 = _766 + 6;\n            vec4 _894 = fa_light_texel(param_11);\n            float _895 = _894.w;\n            int param_12 = _766 + 2;\n            vec3 _902 = normalize(fa_light_texel(param_12).xyz);\n            bool _904 = _895 > 1.5;\n            bool _912;\n            if (!_904)\n            {\n                _912 = dot(_902, to_light) < 0.0;\n            }\n            else\n            {\n                _912 = _904;\n            }\n            front = _912;\n            vec3 r = vec3(0.0);\n            vec3 _921 = fa_mesh_fs_params[0].xyz - world_pos;\n            bool _925 = dot(n, n) > 0.5;\n            bool _933;\n            if (_925)\n            {\n                _933 = dot(_921, _921) > 9.9999999600419720025001879548654e-13;\n            }\n            else\n            {\n                _933 = _925;\n            }\n            if (_933)\n            {\n                r = reflect(-normalize(_921), normalize(n));\n            }\n            vec3 param_13 = _855;\n            vec3 param_14 = _902;\n            vec3 param_15 = _884.xyz;\n            vec3 param_16 = _889.xyz;\n            float param_17 = _884.w;\n            float param_18 = _889.w;\n            float param_19 = _895;\n            vec3 param_20 = world_pos;\n            vec3 param_21 = r;\n            to_light = fa_area_point(param_13, param_14, param_15, param_16, param_17, param_18, param_19, param_20, param_21) - world_pos;\n        }\n        float _969 = length(to_light);\n        dist = _969;\n        l = to_light / vec3(max(_969, 9.9999997473787516355514526367188e-05));\n        float _983 = reach / max(_774.w, 0.001000000047497451305389404296875);\n        float _989 = clamp(1.0 - (_983 * _983), 0.0, 1.0);\n        float _991;\n        if (front)\n        {\n            _991 = _989 * _989;\n        }\n        else\n        {\n            _991 = 0.0;\n        }\n        atten = _991;\n        bool _1002 = _782 < 2.5;\n        if ((_782 > 1.5) && _1002)\n        {\n            int param_22 = _766 + 2;\n            vec4 _1010 = fa_light_texel(param_22);\n            float _1020 = _1010.w;\n            int param_23 = _766 + 3;\n            vec4 _1025 = fa_light_texel(param_23);\n            float _1026 = _1025.x;\n            float cos_inner = _1026;\n            if (_1026 > 1.5)\n            {\n                cos_inner = mix(_1020, 1.0, 0.25);\n            }\n            atten *= smoothstep(_1020, cos_inner, dot(-l, normalize(_1010.xyz)));\n        }\n        if (_770 && (_782 < 1.5))\n        {\n            int param_24 = _766 + 6;\n            vec4 _1050 = fa_light_texel(param_24);\n            if (_1050.z > 0.5)\n            {\n                vec3 _1058 = -to_light;\n                int param_25 = _766 + 4;\n                int param_26 = _766 + 5;\n                vec3 _1072 = fa_light_texel(param_25).xyz;\n                vec3 _1076 = fa_light_texel(param_26).xyz;\n                vec3 _1085 = vec3(dot(_1058, _1072), dot(_1058, _1076), dot(_1058, cross(_1072, _1076)));\n                vec3 param_27 = _1085;\n                int _1089 = fa_cube_face(param_27);\n                int param_28 = _1089;\n                vec3 param_29;\n                vec3 param_30;\n                fa_cube_face_basis(param_28, param_29, param_30);\n                vec2 _1116 = vec2(dot(_1085, cross(param_29, param_30)), dot(_1085, param_30)) / vec2(max(dot(_1085, param_29), 9.9999997473787516355514526367188e-05));\n                int _1120 = _1089 / 3;\n                vec2 param_31 = _1050.xy + (vec2(float(_1089 - (_1120 * 3)), float(_1120)) * 256.0);\n                vec2 param_32 = vec2(0.5 + (0.5 * _1116.x), 0.5 - (0.5 * _1116.y));\n                fa_light_tint = fa_cookie_sample(param_31, param_32);\n            }\n            int param_33 = _766 + 7;\n            vec4 _1150 = fa_light_texel(param_33);\n            if (_1150.z > 0.5)\n            {\n                int param_34 = _766 + 2;\n                int param_35 = _766 + 4;\n                int param_36 = _766 + 5;\n                vec2 param_37 = _1150.xy;\n                vec3 param_38 = -l;\n                vec3 param_39 = normalize(fa_light_texel(param_34).xyz);\n                vec3 param_40 = fa_light_texel(param_35).xyz;\n                vec3 param_41 = fa_light_texel(param_36).xyz;\n                atten *= fa_ies_sample(param_37, param_38, param_39, param_40, param_41);\n            }\n        }\n        else\n        {\n            if (_770 && _1002)\n            {\n                int param_42 = _766 + 6;\n                vec4 _1197 = fa_light_texel(param_42);\n                int param_43 = _766 + 7;\n                vec4 _1202 = fa_light_texel(param_43);\n                bool _1205 = _1197.z > 0.5;\n                bool _1212;\n                if (!_1205)\n                {\n                    _1212 = _1202.z > 0.5;\n                }\n                else\n                {\n                    _1212 = _1205;\n                }\n                if (_1212)\n                {\n                    int param_44 = _766 + 2;\n                    vec4 _1219 = fa_light_texel(param_44);\n                    vec3 _1223 = normalize(_1219.xyz);\n                    int param_45 = _766 + 4;\n                    vec4 _1228 = fa_light_texel(param_45);\n                    int param_46 = _766 + 5;\n                    vec4 _1233 = fa_light_texel(param_46);\n                    if (_1205)\n                    {\n                        vec3 _1241 = -to_light;\n                        float _1248 = _1219.w;\n                        float _1264 = 0.5 / max(dot(_1241, _1223) * (sqrt(max(1.0 - (_1248 * _1248), 0.0)) / max(_1248, 0.001000000047497451305389404296875)), 9.9999997473787516355514526367188e-05);\n                        vec2 param_47 = _1197.xy;\n                        vec2 param_48 = vec2(0.5 + (dot(_1241, _1228.xyz) * _1264), 0.5 - (dot(_1241, _1233.xyz) * _1264));\n                        fa_light_tint = fa_cookie_sample(param_47, param_48);\n                    }\n                    if (_1202.z > 0.5)\n                    {\n                        vec2 param_49 = _1202.xy;\n                        vec3 param_50 = -l;\n                        vec3 param_51 = _1223;\n                        vec3 param_52 = _1228.xyz;\n                        vec3 param_53 = _1233.xyz;\n                        atten *= fa_ies_sample(param_49, param_50, param_51, param_52, param_53);\n                    }\n                }\n            }\n        }\n    }\n    vec3 _5499 = _779.xyz * atten;\n    if (_770)\n    {\n        _5499 *= fa_light_tint;\n    }\n    int _1332;\n    if (_796)\n    {\n        _1332 = 0;\n    }\n    else\n    {\n        _1332 = ((_782 > 1.5) && (_782 < 2.5)) ? 2 : 1;\n    }\n    return LightSample(l, _5499, atten, 1.0, dist, _1332);\n}\n\nfloat fa_shadow_depth(inout vec2 uv, vec4 rect)\n{\n    uv = clamp(uv, rect.xy, rect.zw);\n    return textureLod(fa_shadow_tex_fa_shadow_smp, uv, 0.0).x;\n}\n\nfloat fa_shadow_fetch(vec2 uv, vec4 rect, vec3 conv)\n{\n    vec2 param = uv;\n    vec4 param_1 = rect;\n    float _2126 = fa_shadow_depth(param, param_1);\n    float _2130;\n    if (conv.x < 0.5)\n    {\n        _2130 = _2126;\n    }\n    else\n    {\n        _2130 = (conv.y * conv.z) / (conv.z - (_2126 * (conv.z - conv.y)));\n    }\n    return _2130;\n}\n\nfloat fa_shadow_noise()\n{\n    return fract(52.98291778564453125 * fract(dot(gl_FragCoord.xy, vec2(0.067110560834407806396484375, 0.005837149918079376220703125))));\n}\n\nvec2 fa_shadow_vogel(int k, int n, float phi)\n{\n    float _2057 = (float(k) * 2.3999631404876708984375) + phi;\n    return vec2(cos(_2057), sin(_2057)) * sqrt((float(k) + 0.5) / float(n));\n}\n\nfloat fa_shadow_filter(vec2 uv, vec4 rect, float zr, float texel_m, float unit, float reach, float plane, vec3 conv, int mode, float k)\n{\n    if (mode == 1)\n    {\n        vec2 param = uv;\n        vec4 param_1 = rect;\n        vec3 param_2 = conv;\n        return float(zr <= fa_shadow_fetch(param, param_1, param_2));\n    }\n    float _2176 = fa_shadow_noise() * 6.283185482025146484375;\n    float radius = 1.5;\n    if (mode == 2)\n    {\n        float _2185;\n        if (k < 0.0)\n        {\n            _2185 = (-k) / max(zr, 0.100000001490116119384765625);\n        }\n        else\n        {\n            _2185 = k;\n        }\n        float _2205 = clamp((_2185 * reach) / texel_m, 3.0, 12.0);\n        float sum = 0.0;\n        float cnt = 0.0;\n        for (int i = 0; i < 16; i++)\n        {\n            int param_3 = i;\n            int param_4 = 16;\n            float param_5 = _2176;\n            vec2 _2224 = fa_shadow_vogel(param_3, param_4, param_5) * _2205;\n            vec2 param_6 = uv + (_2224 * fa_shadows[26].zw);\n            vec4 param_7 = rect;\n            vec3 param_8 = conv;\n            float _2236 = fa_shadow_fetch(param_6, param_7, param_8);\n            if (_2236 < (zr - (length(_2224) * plane)))\n            {\n                sum += _2236;\n                cnt += 1.0;\n            }\n        }\n        if (cnt < 0.5)\n        {\n            return 1.0;\n        }\n        float _2262 = sum / cnt;\n        float _2272;\n        if (k < 0.0)\n        {\n            _2272 = (-k) / max(_2262, 0.0500000007450580596923828125);\n        }\n        else\n        {\n            _2272 = k;\n        }\n        radius = clamp(((max(zr - _2262, 0.0) * unit) * _2272) / texel_m, 1.5, 16.0);\n    }\n    float lit = 0.0;\n    int _2294 = (mode == 2) ? 24 : 16;\n    for (int i_1 = 0; i_1 < _2294; i_1++)\n    {\n        int param_9 = i_1;\n        int param_10 = _2294;\n        float param_11 = _2176;\n        vec2 _2313 = fa_shadow_vogel(param_9, param_10, param_11) * radius;\n        vec2 param_12 = uv + (_2313 * fa_shadows[26].zw);\n        vec4 param_13 = rect;\n        vec3 param_14 = conv;\n        lit += float((zr - (length(_2313) * plane)) <= fa_shadow_fetch(param_12, param_13, param_14));\n    }\n    return lit / float(_2294);\n}\n\nfloat fa_shadow_local(int li, vec3 lpos, vec3 world, vec3 n, vec3 l)\n{\n    bool _2513 = fa_mesh_fs_params[5].z < 0.5;\n    bool _2520;\n    if (!_2513)\n    {\n        _2520 = fa_shadows[29].x < 0.5;\n    }\n    else\n    {\n        _2520 = _2513;\n    }\n    if (_2520)\n    {\n        return 1.0;\n    }\n    int param = (int(fa_shadows[29].x + 0.5) - 1) + li;\n    vec4 _2533 = fa_light_texel(param);\n    float _2534 = _2533.x;\n    if (_2534 < 0.0)\n    {\n        return 1.0;\n    }\n    int _2543 = int(_2534 + 0.5);\n    int param_1 = _2543;\n    vec4 _2547 = fa_light_texel(param_1);\n    int param_2 = _2543 + 1;\n    vec4 _2552 = fa_light_texel(param_2);\n    float fade = 1.0;\n    float _2555 = _2547.y;\n    if (_2555 > 0.0)\n    {\n        float _2572 = 1.0 - smoothstep(0.75 * _2555, _2555, length(world - fa_shadows[27].xyz));\n        fade = _2572;\n        if (_2572 <= 0.0)\n        {\n            return 1.0;\n        }\n    }\n    int face = 0;\n    if (_2547.x > 1.5)\n    {\n        vec3 param_3 = world - lpos;\n        face = fa_cube_face(param_3);\n    }\n    int _2596 = (_2543 + 2) + (face * 6);\n    int param_4 = _2596;\n    int param_5 = _2596 + 1;\n    int param_6 = _2596 + 3;\n    vec4 _2610 = fa_light_texel(param_6);\n    int param_7 = _2596 + 4;\n    vec4 _2615 = fa_light_texel(param_7);\n    int param_8 = _2596 + 5;\n    vec4 _2620 = fa_light_texel(param_8);\n    float _2632 = _2620.x * max(dot(_2610, vec4(world, 1.0)), 0.001000000047497451305389404296875);\n    float _2637 = clamp(dot(n, l), 0.0, 1.0);\n    float _2660 = clamp(dot(n, _2610.xyz), -1.0, 1.0);\n    float _2679 = min(sqrt(1.0 - (_2660 * _2660)) / max(abs(dot(n, world - lpos)) / max(dot(_2610, vec4(world, 1.0)), 0.001000000047497451305389404296875), 0.20000000298023223876953125), 4.0);\n    float _2682 = _2552.y;\n    float _2684;\n    if (_2682 > 0.0)\n    {\n        _2684 = _2682;\n    }\n    else\n    {\n        _2684 = 1.5 * _2632;\n    }\n    vec4 _2704 = vec4(world + (n * (_2684 * sqrt(1.0 - (_2637 * _2637)))), 1.0);\n    float _2708 = dot(_2610, _2704);\n    float _2711 = _2620.y;\n    if (_2708 < _2711)\n    {\n        return 1.0;\n    }\n    vec2 _2726 = vec2(dot(fa_light_texel(param_4), _2704), dot(fa_light_texel(param_5), _2704)) / vec2(_2708);\n    float _2728 = _2726.x;\n    bool _2731 = _2728 < _2615.x;\n    bool _2740;\n    if (!_2731)\n    {\n        _2740 = _2728 > _2615.z;\n    }\n    else\n    {\n        _2740 = _2731;\n    }\n    bool _2749;\n    if (!_2740)\n    {\n        _2749 = _2726.y < _2615.y;\n    }\n    else\n    {\n        _2749 = _2740;\n    }\n    bool _2758;\n    if (!_2749)\n    {\n        _2758 = _2726.y > _2615.w;\n    }\n    else\n    {\n        _2758 = _2749;\n    }\n    if (_2758)\n    {\n        return 1.0;\n    }\n    float _2764 = _2552.x;\n    float _2766;\n    if (_2764 > 0.0)\n    {\n        _2766 = _2764;\n    }\n    else\n    {\n        _2766 = 1.5 * _2632;\n    }\n    vec2 param_9 = _2726;\n    vec4 param_10 = _2615;\n    float param_11 = _2708 - (_2766 * (1.0 + (0.5 * _2679)));\n    float param_12 = _2632;\n    float param_13 = 1.0;\n    float param_14 = _2620.z * 0.25;\n    float param_15 = (_2632 * min(_2679, 3.0)) * 0.5;\n    vec3 param_16 = vec3(1.0, _2711, _2620.z);\n    int param_17 = int(_2547.z + 0.5);\n    float param_18 = _2547.w;\n    return mix(1.0, fa_shadow_filter(param_9, param_10, param_11, param_12, param_13, param_14, param_15, param_16, param_17, param_18), fade);\n}\n\nfloat fa_shadow_split_at(int i)\n{\n    float _2069;\n    if (i == 0)\n    {\n        _2069 = fa_shadows[24].x;\n    }\n    else\n    {\n        float _2085;\n        if (i == 1)\n        {\n            _2085 = fa_shadows[24].y;\n        }\n        else\n        {\n            float _2093;\n            if (i == 2)\n            {\n                _2093 = fa_shadows[24].z;\n            }\n            else\n            {\n                _2093 = fa_shadows[24].w;\n            }\n            _2085 = _2093;\n        }\n        _2069 = _2085;\n    }\n    return _2069;\n}\n\nfloat fa_shadow_cascade(int ci, vec3 world, vec3 n, vec3 l)\n{\n    float _2355 = max(fa_shadows[ci * 1 + 20].y, 0.001000000047497451305389404296875);\n    float _2360 = clamp(dot(n, l), 0.0, 1.0);\n    float _2366 = sqrt(1.0 - (_2360 * _2360));\n    float _2373 = min(_2366 / max(_2360, 0.20000000298023223876953125), 4.0);\n    float _2378;\n    if (fa_shadows[26].y > 0.0)\n    {\n        _2378 = fa_shadows[26].y;\n    }\n    else\n    {\n        _2378 = 1.5 * fa_shadows[ci * 1 + 20].x;\n    }\n    vec4 _2403 = mat4(fa_shadows[ci * 4 + 0], fa_shadows[ci * 4 + 1], fa_shadows[ci * 4 + 2], fa_shadows[ci * 4 + 3]) * vec4(world + (n * (_2378 * _2366)), 1.0);\n    float _2410 = _2403.x;\n    bool _2413 = _2410 < fa_shadows[ci * 1 + 16].x;\n    bool _2422;\n    if (!_2413)\n    {\n        _2422 = _2410 > fa_shadows[ci * 1 + 16].z;\n    }\n    else\n    {\n        _2422 = _2413;\n    }\n    bool _2431;\n    if (!_2422)\n    {\n        _2431 = _2403.y < fa_shadows[ci * 1 + 16].y;\n    }\n    else\n    {\n        _2431 = _2422;\n    }\n    bool _2440;\n    if (!_2431)\n    {\n        _2440 = _2403.y > fa_shadows[ci * 1 + 16].w;\n    }\n    else\n    {\n        _2440 = _2431;\n    }\n    bool _2447;\n    if (!_2440)\n    {\n        _2447 = _2403.z > 1.0;\n    }\n    else\n    {\n        _2447 = _2440;\n    }\n    if (_2447)\n    {\n        return -1.0;\n    }\n    float _2455;\n    if (fa_shadows[26].x > 0.0)\n    {\n        _2455 = fa_shadows[26].x;\n    }\n    else\n    {\n        _2455 = 1.5 * fa_shadows[ci * 1 + 20].x;\n    }\n    vec2 param = _2403.xy;\n    vec4 param_1 = fa_shadows[ci * 1 + 16];\n    float param_2 = _2403.z - ((_2455 * (1.0 + (0.5 * _2373))) / _2355);\n    float param_3 = fa_shadows[ci * 1 + 20].x;\n    float param_4 = _2355;\n    float param_5 = _2355 * 0.25;\n    float param_6 = ((fa_shadows[ci * 1 + 20].x * min(_2373, 3.0)) * 0.5) / _2355;\n    vec3 param_7 = vec3(0.0);\n    int param_8 = int(fa_shadows[25].z + 0.5);\n    float param_9 = fa_shadows[25].w;\n    return fa_shadow_filter(param, param_1, param_2, param_3, param_4, param_5, param_6, param_7, param_8, param_9);\n}\n\nfloat fa_shadow_sun(vec3 world, vec3 n, vec3 l)\n{\n    if (fa_mesh_fs_params[5].z < 0.5)\n    {\n        return 1.0;\n    }\n    int _2833 = int(fa_shadows[25].x + 0.5);\n    if (_2833 < 1)\n    {\n        return 1.0;\n    }\n    float _2848 = dot(world - fa_shadows[27].xyz, fa_shadows[28].xyz);\n    int param = _2833 - 1;\n    if (_2848 > fa_shadow_split_at(param))\n    {\n        return 1.0;\n    }\n    int ci = 0;\n    bool _2860 = _2833 > 1;\n    bool _2867;\n    if (_2860)\n    {\n        _2867 = _2848 > fa_shadows[24].x;\n    }\n    else\n    {\n        _2867 = _2860;\n    }\n    if (_2867)\n    {\n        ci = 1;\n    }\n    bool _2871 = _2833 > 2;\n    bool _2878;\n    if (_2871)\n    {\n        _2878 = _2848 > fa_shadows[24].y;\n    }\n    else\n    {\n        _2878 = _2871;\n    }\n    if (_2878)\n    {\n        ci = 2;\n    }\n    bool _2882 = _2833 > 3;\n    bool _2889;\n    if (_2882)\n    {\n        _2889 = _2848 > fa_shadows[24].z;\n    }\n    else\n    {\n        _2889 = _2882;\n    }\n    if (_2889)\n    {\n        ci = 3;\n    }\n    float s = -1.0;\n    for (int k = 0; k < 4; k++)\n    {\n        if (ci >= _2833)\n        {\n            break;\n        }\n        int param_1 = ci;\n        vec3 param_2 = world;\n        vec3 param_3 = n;\n        vec3 param_4 = l;\n        float _2915 = fa_shadow_cascade(param_1, param_2, param_3, param_4);\n        s = _2915;\n        if (_2915 >= 0.0)\n        {\n            break;\n        }\n        ci++;\n    }\n    if (s < 0.0)\n    {\n        return 1.0;\n    }\n    if (fa_shadows[25].y > 0.0)\n    {\n        float _2940;\n        if (ci > 0)\n        {\n            int param_5 = ci - 1;\n            _2940 = fa_shadow_split_at(param_5);\n        }\n        else\n        {\n            _2940 = fa_shadows[28].w;\n        }\n        int param_6 = ci;\n        float _2959 = fa_shadows[25].y * max(fa_shadow_split_at(param_6) - _2940, 9.9999997473787516355514526367188e-05);\n        int param_7 = ci;\n        float _2970 = clamp((_2848 - (fa_shadow_split_at(param_7) - _2959)) / _2959, 0.0, 1.0);\n        if (_2970 > 0.0)\n        {\n            float s2 = 1.0;\n            if ((ci + 1) < _2833)\n            {\n                int param_8 = ci + 1;\n                vec3 param_9 = world;\n                vec3 param_10 = n;\n                vec3 param_11 = l;\n                float _2991 = fa_shadow_cascade(param_8, param_9, param_10, param_11);\n                s2 = _2991;\n                if (_2991 < 0.0)\n                {\n                    s2 = s;\n                }\n            }\n            s = mix(s, s2, _2970);\n        }\n    }\n    return s;\n}\n\nfloat fa_shadow_factor(vec3 n, vec3 l)\n{\n    vec3 param = fa_world_pos;\n    vec3 param_1 = n;\n    vec3 param_2 = l;\n    return fa_shadow_sun(param, param_1, param_2);\n}\n\nfloat fa_contact_shadow(int li, vec3 world, vec3 gn, vec3 l, float dist)\n{\n    bool _3440 = fa_mesh_fs_params[24].x < 0.5;\n    bool _3447;\n    if (!_3440)\n    {\n        _3447 = fa_shadows[29].x < 0.5;\n    }\n    else\n    {\n        _3447 = _3440;\n    }\n    if (_3447)\n    {\n        return 1.0;\n    }\n    int param = (int(fa_shadows[29].x + 0.5) - 1) + li;\n    vec4 _3460 = fa_light_texel(param);\n    float _3461 = _3460.y;\n    float len = _3461;\n    if (_3461 <= 0.0)\n    {\n        return 1.0;\n    }\n    float _3473 = length(world - fa_mesh_fs_params[0].xyz);\n    float _3483 = 1.0 - smoothstep(0.5 * fa_mesh_fs_params[25].x, fa_mesh_fs_params[25].x, _3473);\n    if (_3483 <= 0.0)\n    {\n        return 1.0;\n    }\n    float _3489 = len;\n    float _3492 = min(_3489, 0.89999997615814208984375 * dist);\n    len = _3492;\n    float _3498 = 0.004999999888241291046142578125 + (0.0030000000260770320892333984375 * _3473);\n    float _3503 = _3498 + (0.5 * _3492);\n    vec3 _3509 = world + (gn * _3498);\n    float _3511 = fa_shadow_noise();\n    float occ = 0.0;\n    float _3576;\n    for (int k = 0; k < 12; k++)\n    {\n        float _3527 = (float(k) + _3511) * 0.083333335816860198974609375;\n        vec3 _3535 = _3509 + (l * (_3527 * len));\n        vec4 _3541 = vec4(_3535, 1.0);\n        float _3547 = dot(fa_mesh_fs_params[28], _3541);\n        if (_3547 < 9.9999997473787516355514526367188e-05)\n        {\n            break;\n        }\n        vec2 _3567 = vec2(dot(fa_mesh_fs_params[26], _3541), dot(fa_mesh_fs_params[27], _3541)) / vec2(_3547);\n        float _3571 = _3567.x * 0.5;\n        float _3572 = _3571 + 0.5;\n        if (fa_mesh_fs_params[24].y > 0.5)\n        {\n            _3576 = (_3567.y * 0.5) + 0.5;\n        }\n        else\n        {\n            _3576 = 0.5 - (_3567.y * 0.5);\n        }\n        bool _3592 = _3572 < 0.0;\n        bool _3599;\n        if (!_3592)\n        {\n            _3599 = _3572 >= 1.0;\n        }\n        else\n        {\n            _3599 = _3592;\n        }\n        bool _3606;\n        if (!_3599)\n        {\n            _3606 = _3576 < 0.0;\n        }\n        else\n        {\n            _3606 = _3599;\n        }\n        bool _3613;\n        if (!_3606)\n        {\n            _3613 = _3576 >= 1.0;\n        }\n        else\n        {\n            _3613 = _3606;\n        }\n        if (_3613)\n        {\n            break;\n        }\n        vec4 _3632 = texelFetch(fa_screen_tex_fa_shadow_smp, ivec2(vec2(_3572, _3576) * fa_mesh_fs_params[24].zw), 0);\n        if (_3632.w < 0.5)\n        {\n            continue;\n        }\n        float _3651 = (dot(fa_mesh_fs_params[29].xyz, _3535) + fa_mesh_fs_params[29].w) - _3632.x;\n        if ((_3651 > _3498) && (_3651 < _3503))\n        {\n            occ = max(occ, (1.0 - (_3527 * _3527)) * smoothstep(0.0, 0.0500000007450580596923828125, min(min(_3572, 0.5 - _3571), min(_3576, 1.0 - _3576))));\n        }\n    }\n    return 1.0 - (occ * _3483);\n}\n\nLightSample fa_light_shadowed(int li, vec3 world_pos, vec3 gn)\n{\n    int param = li;\n    float _3754 = fa_baked_keep(param);\n    if (_3754 <= 0.0)\n    {\n        int param_1 = li;\n        return LightSample(vec3(0.0, 1.0, 0.0), vec3(0.0), 0.0, 1.0, 0.0, int(fa_light_type(param_1) + 0.5));\n    }\n    int param_2 = li;\n    vec3 param_3 = world_pos;\n    vec3 param_4 = gn;\n    LightSample _3780 = fa_light_sample_n(param_2, param_3, param_4);\n    vec3 _5525 = _3780.color;\n    float _5526 = _3780.attenuation;\n    float _5527 = _3780.shadow;\n    bool _3783 = _3780.type == 0;\n    if (_3783 && (li == 0))\n    {\n        vec3 param_5 = gn;\n        vec3 param_6 = _3780.direction;\n        float _3794 = fa_shadow_factor(param_5, param_6);\n        _5527 = _3794;\n        _5525 *= _3794;\n    }\n    else\n    {\n        bool _3805 = _3780.type != 0;\n        bool _3811;\n        if (_3805)\n        {\n            _3811 = _5526 > 0.0;\n        }\n        else\n        {\n            _3811 = _3805;\n        }\n        if (_3811)\n        {\n            int param_7 = li;\n            int param_8 = fa_light_base(param_7);\n            int param_9 = li;\n            vec3 param_10 = fa_light_texel(param_8).xyz;\n            vec3 param_11 = world_pos;\n            vec3 param_12 = gn;\n            vec3 param_13 = _3780.direction;\n            float _3830 = fa_shadow_local(param_9, param_10, param_11, param_12, param_13);\n            _5527 = _3830;\n            _5525 *= _3830;\n        }\n    }\n    bool _3840 = fa_mesh_fs_params[24].x > 0.5;\n    bool _3846;\n    if (_3840)\n    {\n        _3846 = _5526 > 0.0;\n    }\n    else\n    {\n        _3846 = _3840;\n    }\n    if (_3846)\n    {\n        float _3853;\n        if (_3783)\n        {\n            _3853 = 1000000000.0;\n        }\n        else\n        {\n            _3853 = _3780._distance;\n        }\n        int param_14 = li;\n        vec3 param_15 = world_pos;\n        vec3 param_16 = gn;\n        vec3 param_17 = _3780.direction;\n        float param_18 = _3853;\n        float _3871 = fa_contact_shadow(param_14, param_15, param_16, param_17, param_18);\n        _5527 *= _3871;\n        _5525 *= _3871;\n    }\n    float _3884 = _5526;\n    float _3885 = _3884 * _3754;\n    _5526 = _3885;\n    vec3 _3889 = _5525;\n    vec3 _3890 = _3889 * _3754;\n    _5525 = _3890;\n    return LightSample(_3780.direction, _3890, _3885, _5527, _3780._distance, _3780.type);\n}\n\nvec3 light(SurfaceInput i, Surface s, LightSample l)\n{\n    return vec3(0.0);\n}\n\nvec3 fa_shadow_debug(vec3 color, vec3 world)\n{\n    if (fa_shadows[27].w < 0.5)\n    {\n        return color;\n    }\n    int _3015 = int(fa_shadows[25].x + 0.5);\n    float _3025 = dot(world - fa_shadows[27].xyz, fa_shadows[28].xyz);\n    vec3 tint = vec3(0.3499999940395355224609375);\n    bool _3030 = _3015 > 0;\n    bool _3039;\n    if (_3030)\n    {\n        int param = _3015 - 1;\n        _3039 = _3025 <= fa_shadow_split_at(param);\n    }\n    else\n    {\n        _3039 = _3030;\n    }\n    if (_3039)\n    {\n        tint = vec3(1.0, 0.1500000059604644775390625, 0.100000001490116119384765625);\n        bool _3045 = _3015 > 1;\n        bool _3052;\n        if (_3045)\n        {\n            _3052 = _3025 > fa_shadows[24].x;\n        }\n        else\n        {\n            _3052 = _3045;\n        }\n        if (_3052)\n        {\n            tint = vec3(0.100000001490116119384765625, 0.89999997615814208984375, 0.20000000298023223876953125);\n        }\n        bool _3058 = _3015 > 2;\n        bool _3065;\n        if (_3058)\n        {\n            _3065 = _3025 > fa_shadows[24].y;\n        }\n        else\n        {\n            _3065 = _3058;\n        }\n        if (_3065)\n        {\n            tint = vec3(0.1500000059604644775390625, 0.300000011920928955078125, 1.0);\n        }\n        bool _3071 = _3015 > 3;\n        bool _3078;\n        if (_3071)\n        {\n            _3078 = _3025 > fa_shadows[24].z;\n        }\n        else\n        {\n            _3078 = _3071;\n        }\n        if (_3078)\n        {\n            tint = vec3(1.0, 0.89999997615814208984375, 0.100000001490116119384765625);\n        }\n    }\n    return mix(color, tint, vec3(0.550000011920928955078125));\n}\n\nvoid main()\n{\n    fa_inst_load();\n    vec3 _5317 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _5317 = -_5317;\n    }\n    vec3 _4892 = normalize(fa_mesh_fs_params[0].xyz - fa_world_pos);\n    vec3 param = fa_world_pos;\n    fa_cluster_begin(param);\n    SurfaceInput param_1 = SurfaceInput(fa_world_pos, _5317, fa_world_tangent, fa_uv, fa_vertex_color, _4892, gl_FrontFacing);\n    Surface _4900 = fa_standard_surface(param_1);\n    vec3 _5356 = _4900.albedo;\n    float _5357 = _4900.alpha;\n    vec3 _5358 = _4900.normal;\n    float _5359 = _4900.metallic;\n    float _5360 = _4900.roughness;\n    float _5361 = _4900.occlusion;\n    vec3 _5362 = _4900.emission;\n    float _5363 = _4900.clearcoat;\n    float _5364 = _4900.clearcoat_roughness;\n    vec3 _5365 = _4900.sheen_color;\n    float _5366 = _4900.sheen_roughness;\n    float _5367 = _4900.anisotropy;\n    float _5368 = _4900.anisotropy_rotation;\n    float _5369 = _4900.specular;\n    float _5370 = _4900.ior;\n    vec3 _5371 = _4900.specular_color;\n    float _5372 = _4900.transmission;\n    float _5373 = _4900.thickness;\n    vec3 _5374 = _4900.attenuation_color;\n    float _5375 = _4900.attenuation_distance;\n    SurfaceInput param_2 = SurfaceInput(fa_world_pos, _5317, fa_world_tangent, fa_uv, fa_vertex_color, _4892, gl_FrontFacing);\n    Surface param_3 = _4900;\n    surface(param_2, param_3);\n    _5356 = param_3.albedo;\n    _5357 = param_3.alpha;\n    _5358 = param_3.normal;\n    _5359 = param_3.metallic;\n    _5360 = param_3.roughness;\n    _5361 = param_3.occlusion;\n    _5362 = param_3.emission;\n    _5363 = param_3.clearcoat;\n    _5364 = param_3.clearcoat_roughness;\n    _5365 = param_3.sheen_color;\n    _5366 = param_3.sheen_roughness;\n    _5367 = param_3.anisotropy;\n    _5368 = param_3.anisotropy_rotation;\n    _5369 = param_3.specular;\n    _5370 = param_3.ior;\n    _5371 = param_3.specular_color;\n    _5372 = param_3.transmission;\n    _5373 = param_3.thickness;\n    _5374 = param_3.attenuation_color;\n    _5375 = param_3.attenuation_distance;\n    vec3 param_4 = fa_world_pos;\n    vec3 param_5 = _5317;\n    vec3 param_6 = param_3.albedo;\n    vec3 param_7 = param_3.normal;\n    fa_apply_decals(param_4, param_5, param_6, param_7);\n    _5356 = param_6;\n    _5358 = param_7;\n    vec3 result;\n    if (fa_mesh_fs_params[3].w > 0.5)\n    {\n        result = _5356;\n    }\n    else\n    {\n        vec3 _4939 = _5358;\n        vec3 _4940 = normalize(_4939);\n        _5358 = _4940;\n        vec3 param_8 = _4940;\n        SurfaceInput param_9 = SurfaceInput(fa_world_pos, _5317, fa_world_tangent, fa_uv, fa_vertex_color, _4892, gl_FrontFacing);\n        Surface param_10 = Surface(_5356, _5357, _5358, _5359, _5360, _5361, _5362, _5363, _5364, _5365, _5366, _5367, _5368, _5369, _5370, _5371, _5372, _5373, _5374, _5375);\n        vec3 param_11 = fa_indirect_diffuse(param_8);\n        vec3 lit = ambient(param_9, param_10, param_11);\n        int _4959 = fa_cl_ndir + fa_cl_local;\n        for (int ln = 0; ln < _4959; ln++)\n        {\n            int param_12 = ln;\n            int _4972 = fa_cl_light(param_12);\n            int param_13 = _4972;\n            if (fa_baked_keep(param_13) <= 0.0)\n            {\n                continue;\n            }\n            int param_14 = _4972;\n            vec3 param_15 = fa_world_pos;\n            vec3 param_16 = _5317;\n            LightSample _4988 = fa_light_shadowed(param_14, param_15, param_16);\n            SurfaceInput param_17 = SurfaceInput(fa_world_pos, _5317, fa_world_tangent, fa_uv, fa_vertex_color, _4892, gl_FrontFacing);\n            Surface param_18 = Surface(_5356, _5357, _5358, _5359, _5360, _5361, _5362, _5363, _5364, _5365, _5366, _5367, _5368, _5369, _5370, _5371, _5372, _5373, _5374, _5375);\n            LightSample param_19 = _4988;\n            lit += light(param_17, param_18, param_19);\n        }\n        result = lit;\n    }\n    vec3 _5003 = result;\n    vec3 _5004 = _5003 + _5362;\n    result = _5004;\n    vec3 param_20 = _5004;\n    vec3 param_21 = fa_world_pos;\n    result = fa_shadow_debug(param_20, param_21);\n    bool _5013 = fa_mesh_fs_params[7].w > 0.0;\n    bool _5020;\n    if (!_5013)\n    {\n        _5020 = fa_mesh_fs_params[8].y > 0.0;\n    }\n    else\n    {\n        _5020 = _5013;\n    }\n    if (_5020)\n    {\n        vec3 _5029 = fa_world_pos - fa_mesh_fs_params[0].xyz;\n        float _5035 = dot(_5029, fa_mesh_fs_params[9].xyz);\n        bool _5039 = fa_mesh_fs_params[9].w > 0.5;\n        float _5040;\n        if (_5039)\n        {\n            _5040 = _5035;\n        }\n        else\n        {\n            _5040 = length(_5029);\n        }\n        float _5052 = _5040 - fa_mesh_fs_params[8].x;\n        if (_5052 > 0.0)\n        {\n            float _5061 = fa_mesh_fs_params[7].w * _5052;\n            float tau = _5061 * _5061;\n            if (fa_mesh_fs_params[8].y > 0.0)\n            {\n                float _5077;\n                if (_5039)\n                {\n                    _5077 = fa_world_pos.y - (fa_mesh_fs_params[9].y * _5035);\n                }\n                else\n                {\n                    _5077 = fa_mesh_fs_params[0].y;\n                }\n                float _5098 = mix(_5077, fa_world_pos.y, clamp(fa_mesh_fs_params[8].x / _5040, 0.0, 1.0));\n                float _5102 = fa_world_pos.y - _5098;\n                float _5107 = _5098 - fa_mesh_fs_params[8].z;\n                float _5112 = fa_world_pos.y - fa_mesh_fs_params[8].z;\n                bool _5115 = _5107 <= 0.0;\n                bool _5116 = !_5115;\n                bool _5122;\n                if (_5116)\n                {\n                    _5122 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _5122 = _5115;\n                }\n                float _5123;\n                if (_5122)\n                {\n                    _5123 = fa_mesh_fs_params[8].y;\n                }\n                else\n                {\n                    _5123 = fa_mesh_fs_params[8].y * exp(-min(fa_mesh_fs_params[8].w * _5107, 80.0));\n                }\n                bool _5150;\n                if (_5116)\n                {\n                    _5150 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _5150 = _5115;\n                }\n                float _5151;\n                if (_5150)\n                {\n                    _5151 = fa_mesh_fs_params[8].y * _5107;\n                }\n                else\n                {\n                    _5151 = (fa_mesh_fs_params[8].y * (1.0 - exp(-min(fa_mesh_fs_params[8].w * _5107, 80.0)))) / fa_mesh_fs_params[8].w;\n                }\n                bool _5176 = _5112 <= 0.0;\n                bool _5183;\n                if (!_5176)\n                {\n                    _5183 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _5183 = _5176;\n                }\n                float _5184;\n                if (_5183)\n                {\n                    _5184 = fa_mesh_fs_params[8].y * _5112;\n                }\n                else\n                {\n                    _5184 = (fa_mesh_fs_params[8].y * (1.0 - exp(-min(fa_mesh_fs_params[8].w * _5112, 80.0)))) / fa_mesh_fs_params[8].w;\n                }\n                float _5211;\n                if (abs(_5102) < 0.001000000047497451305389404296875)\n                {\n                    _5211 = _5123;\n                }\n                else\n                {\n                    _5211 = (_5184 - _5151) / _5102;\n                }\n                tau += (_5052 * max(_5211, 0.0));\n            }\n            result = mix(result, fa_mesh_fs_params[7].xyz, vec3(clamp(1.0 - exp(-clamp(tau, 0.0, 80.0)), 0.0, 1.0)));\n        }\n    }\n    fa_frag_color = vec4(result, _5357);\n}\n\n",
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
            "inst_name": "_422",
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
            "name": "fa_shadow_tex_fa_shadow_smp",
            "view_name": "fa_shadow_tex",
            "sampler_name": "fa_shadow_smp",
            "view_slot": 1,
            "sampler_slot": 1,
            "glsl_name": "fa_shadow_tex_fa_shadow_smp"
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
          }
        ]
      }
    },
    "mesh_skin": {
      "vs": "#version 430\n\nstruct VertexData\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 color;\n    vec3 object_pos;\n};\n\nuniform vec4 fa_mesh_vs_params[11];\nuniform vec4 fa_skin[192];\nlayout(location = 0) out vec3 fa_world_pos;\nlayout(location = 1) out vec3 fa_world_normal;\nlayout(location = 2) out vec4 fa_world_tangent;\nlayout(location = 3) out vec2 fa_uv;\nlayout(location = 4) out vec4 fa_vertex_color;\nlayout(location = 5) in vec4 fa_inst_m0;\nlayout(location = 6) in vec4 fa_inst_m1;\nlayout(location = 7) in vec4 fa_inst_m2;\nlayout(location = 8) in vec4 fa_inst_m3;\nlayout(location = 9) in vec4 fa_joints;\nlayout(location = 10) in vec4 fa_weights;\nlayout(location = 0) in vec3 fa_position;\nlayout(location = 1) in vec3 fa_normal;\nlayout(location = 3) in vec4 fa_tangent;\nlayout(location = 2) in vec2 fa_texcoord0;\nlayout(location = 4) in vec4 fa_color;\nlayout(location = 5) out vec3 fa_lm;\n\nvoid fa_inst_begin()\n{\n}\n\nmat4 fa_skin_matrix(vec4 joints, vec4 weights)\n{\n    vec4 r0 = vec4(0.0);\n    vec4 r1 = vec4(0.0);\n    vec4 r2 = vec4(0.0);\n    for (int i = 0; i < 4; i++)\n    {\n        int _174 = int((joints[i] * 255.0) + 0.5) * 3;\n        r0 += (fa_skin[_174 * 1 + 0] * weights[i]);\n        r1 += (fa_skin[(_174 + 1) * 1 + 0] * weights[i]);\n        r2 += (fa_skin[(_174 + 2) * 1 + 0] * weights[i]);\n    }\n    return mat4(vec4(r0.x, r1.x, r2.x, 0.0), vec4(r0.y, r1.y, r2.y, 0.0), vec4(r0.z, r1.z, r2.z, 0.0), vec4(r0.w, r1.w, r2.w, 1.0));\n}\n\nVertexData fa_vertex_data(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    vec3 _74 = cross(model[1].xyz, model[2].xyz);\n    float _80 = (dot(model[0].xyz, _74) < 0.0) ? (-1.0) : 1.0;\n    return VertexData((model * vec4(position, 1.0)).xyz, (((_74 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _80, vec4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _80), texcoord0 * fa_mesh_vs_params[8].xy, color, position);\n}\n\nvoid fa_shade_vertex(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    mat4 param = model;\n    vec3 param_1 = position;\n    vec3 param_2 = normal;\n    vec4 param_3 = tangent;\n    vec2 param_4 = texcoord0;\n    vec4 param_5 = color;\n    VertexData _273 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    vec3 _388 = _273.world_pos;\n    fa_world_pos = _388;\n    fa_world_normal = _273.world_normal;\n    fa_world_tangent = _273.world_tangent;\n    fa_uv = _273.uv;\n    fa_vertex_color = _273.color;\n    gl_Position = mat4(fa_mesh_vs_params[0], fa_mesh_vs_params[1], fa_mesh_vs_params[2], fa_mesh_vs_params[3]) * vec4(_388, 1.0);\n}\n\nvoid main()\n{\n    fa_inst_begin();\n    vec4 param = fa_joints;\n    vec4 param_1 = fa_weights;\n    mat4 param_2 = mat4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3) * fa_skin_matrix(param, param_1);\n    vec3 param_3 = fa_position;\n    vec3 param_4 = fa_normal;\n    vec4 param_5 = fa_tangent;\n    vec2 param_6 = fa_texcoord0;\n    vec4 param_7 = fa_color;\n    fa_shade_vertex(param_2, param_3, param_4, param_5, param_6, param_7);\n    fa_lm = vec3(0.0);\n}\n\n",
      "fs": "#version 430\n\nstruct SurfaceInput\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 vertex_color;\n    vec3 view_dir;\n    bool front_facing;\n};\n\nstruct LightSample\n{\n    vec3 direction;\n    vec3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct Surface\n{\n    vec3 albedo;\n    float alpha;\n    vec3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    vec3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    vec3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    vec3 specular_color;\n    float transmission;\n    float thickness;\n    vec3 attenuation_color;\n    float attenuation_distance;\n};\n\nuniform vec4 fa_mesh_fs_params[53];\nuniform vec4 fa_shadows[30];\nlayout(binding = 0) uniform sampler2D fa_light_tex_fa_shadow_smp;\nlayout(binding = 1) uniform sampler2D fa_tex_fa_smp;\nlayout(binding = 2) uniform sampler2D fa_normal_tex_fa_smp;\nlayout(binding = 3) uniform sampler2D fa_mr_tex_fa_smp;\nlayout(binding = 4) uniform sampler2D fa_occlusion_tex_fa_smp;\nlayout(binding = 5) uniform sampler2D fa_emissive_tex_fa_smp;\nlayout(binding = 6) uniform sampler2D fa_decal_tex_fa_env_smp;\nlayout(binding = 7) uniform sampler2D fa_lightmap_fa_env_smp;\nlayout(binding = 8) uniform sampler2D fa_probe_atlas_fa_env_smp;\nlayout(binding = 9) uniform sampler2D fa_light_atlas_fa_env_smp;\nlayout(binding = 10) uniform sampler2D fa_shadow_tex_fa_shadow_smp;\nlayout(binding = 11) uniform sampler2D fa_screen_tex_fa_shadow_smp;\n\nlayout(location = 0) in vec3 fa_world_pos;\nlayout(location = 5) in vec3 fa_lm;\nlayout(location = 1) in vec3 fa_world_normal;\nlayout(location = 2) in vec4 fa_world_tangent;\nlayout(location = 3) in vec2 fa_uv;\nlayout(location = 4) in vec4 fa_vertex_color;\nlayout(location = 0) out vec4 fa_frag_color;\nvec3 fa_light_tint;\nbool fa_light_is_area;\nint fa_cl_ndir;\nint fa_cl_slot;\nint fa_cl_local;\n\nvoid fa_inst_load()\n{\n}\n\nvec4 fa_light_texel(int t)\n{\n    return texelFetch(fa_light_tex_fa_shadow_smp, ivec2(t & 1023, t >> 10), 0);\n}\n\nvec4 fa_cluster_texel(vec3 world_pos)\n{\n    bool _1350 = fa_mesh_fs_params[19].x < 0.0;\n    bool _1357;\n    if (!_1350)\n    {\n        _1357 = fa_mesh_fs_params[19].w < 1.0;\n    }\n    else\n    {\n        _1357 = _1350;\n    }\n    bool _1365;\n    if (!_1357)\n    {\n        _1365 = fa_mesh_fs_params[18].x < 1.0;\n    }\n    else\n    {\n        _1365 = _1357;\n    }\n    bool _1372;\n    if (!_1365)\n    {\n        _1372 = fa_mesh_fs_params[18].y < 1.0;\n    }\n    else\n    {\n        _1372 = _1365;\n    }\n    bool _1379;\n    if (!_1372)\n    {\n        _1379 = fa_mesh_fs_params[19].y < 1.0;\n    }\n    else\n    {\n        _1379 = _1372;\n    }\n    if (_1379)\n    {\n        return vec4(0.0);\n    }\n    vec4 _1389 = vec4(world_pos, 1.0);\n    float _1395 = dot(fa_mesh_fs_params[16], _1389);\n    if (!(_1395 > 9.9999999747524270787835121154785e-07))\n    {\n        return vec4(0.0);\n    }\n    vec2 _1417 = vec2(dot(fa_mesh_fs_params[14], _1389), dot(fa_mesh_fs_params[15], _1389)) / vec2(_1395);\n    int _1421 = int(fa_mesh_fs_params[18].x);\n    int _1425 = int(fa_mesh_fs_params[18].y);\n    int param = (int(fa_mesh_fs_params[19].x) + (((clamp(int(floor(log2(max(dot(fa_mesh_fs_params[17].xyz, world_pos) + fa_mesh_fs_params[17].w, fa_mesh_fs_params[18].w) / fa_mesh_fs_params[18].w) * fa_mesh_fs_params[18].z)), 0, int(fa_mesh_fs_params[19].y) - 1) * _1425) + clamp(int(floor(((_1417.y * 0.5) + 0.5) * fa_mesh_fs_params[18].y)), 0, _1425 - 1)) * _1421)) + clamp(int(floor(((_1417.x * 0.5) + 0.5) * fa_mesh_fs_params[18].x)), 0, _1421 - 1);\n    return fa_light_texel(param);\n}\n\nivec2 fa_cluster_lookup(vec3 world_pos)\n{\n    vec3 param = world_pos;\n    vec4 _1501 = fa_cluster_texel(param);\n    return ivec2(int(_1501.x), int(_1501.y));\n}\n\nvoid fa_cluster_begin(vec3 world_pos)\n{\n    fa_cl_ndir = int(fa_mesh_fs_params[19].z);\n    vec3 param = world_pos;\n    ivec2 _3728 = fa_cluster_lookup(param);\n    fa_cl_slot = _3728.x;\n    fa_cl_local = _3728.y;\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_linear_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvec3 fa_tex_fix(inout vec3 c, float mode)\n{\n    if (mode > 1.5)\n    {\n        vec3 param = c;\n        vec3 _3936 = fa_linear_to_srgb(param);\n        c = _3936;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            vec3 param_1 = c;\n            vec3 _3944 = fa_srgb_to_linear(param_1);\n            c = _3944;\n        }\n    }\n    return c;\n}\n\nvec3 fa_tangent_normal(SurfaceInput i, vec3 m)\n{\n    vec3 _304;\n    if (i.front_facing)\n    {\n        _304 = i.world_normal;\n    }\n    else\n    {\n        _304 = -i.world_normal;\n    }\n    vec3 _328 = normalize(i.world_tangent.xyz - (_304 * dot(_304, i.world_tangent.xyz)));\n    vec3 _355 = normalize(((_328 * m.x) + ((cross(_304, _328) * i.world_tangent.w) * m.y)) + (_304 * m.z));\n    vec3 _358;\n    if (i.front_facing)\n    {\n        _358 = _355;\n    }\n    else\n    {\n        _358 = -_355;\n    }\n    return _358;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    vec4 base_t = texture(fa_tex_fa_smp, i.uv);\n    float param = fa_mesh_fs_params[6].w;\n    float param_1 = 1.0;\n    vec3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    vec3 _3975 = fa_tex_fix(param_2, param_3);\n    vec4 _5708 = base_t;\n    _5708.x = _3975.x;\n    _5708.y = _3975.y;\n    _5708.z = _3975.z;\n    base_t = _5708;\n    vec4 _3989 = (_5708 * fa_mesh_fs_params[2]) * i.vertex_color;\n    vec3 _5545 = i.world_normal;\n    if (fa_mesh_fs_params[6].z > 0.5)\n    {\n        float param_4 = fa_mesh_fs_params[6].w;\n        float param_5 = 16.0;\n        vec3 param_6 = texture(fa_normal_tex_fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        vec3 _4021 = fa_tex_fix(param_6, param_7);\n        vec3 _4024 = (_4021 * 2.0) - vec3(1.0);\n        vec2 _4029 = _4024.xy * fa_mesh_fs_params[6].x;\n        vec3 _5716 = _4024;\n        _5716.x = _4029.x;\n        _5716.y = _4029.y;\n        SurfaceInput param_8 = i;\n        vec3 param_9 = _5716;\n        _5545 = fa_tangent_normal(param_8, param_9);\n    }\n    vec4 mrt = texture(fa_mr_tex_fa_smp, i.uv);\n    float param_10 = fa_mesh_fs_params[6].w;\n    float param_11 = 64.0;\n    vec3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    vec3 _4057 = fa_tex_fix(param_12, param_13);\n    vec4 _5719 = mrt;\n    _5719.x = _4057.x;\n    _5719.y = _4057.y;\n    _5719.z = _4057.z;\n    mrt = _5719;\n    vec4 _4085 = texture(fa_occlusion_tex_fa_smp, i.uv);\n    float param_14 = fa_mesh_fs_params[6].w;\n    float param_15 = 256.0;\n    vec3 param_16 = _4085.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    vec3 _4096 = fa_tex_fix(param_16, param_17);\n    float param_18 = fa_mesh_fs_params[6].w;\n    float param_19 = 4.0;\n    vec3 param_20 = texture(fa_emissive_tex_fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    vec3 _4126 = fa_tex_fix(param_20, param_21);\n    float _5550 = fa_mesh_fs_params[20].x;\n    float _5551 = fa_mesh_fs_params[20].y;\n    float _5554 = fa_mesh_fs_params[20].z;\n    float _5553 = fa_mesh_fs_params[21].w;\n    float _5556 = fa_mesh_fs_params[22].x;\n    if (fa_mesh_fs_params[22].z > 0.5)\n    {\n        if (mod(fa_mesh_fs_params[22].z, 2.0) > 0.5)\n        {\n            _5550 *= _4096.y;\n            _5551 *= _4096.z;\n            _5553 *= _4085.w;\n        }\n        if (fa_mesh_fs_params[22].z > 1.5)\n        {\n            _5554 *= mrt.x;\n            _5556 *= mrt.w;\n        }\n    }\n    return Surface(_3989.xyz, _3989.w, _5545, clamp(fa_mesh_fs_params[5].x * _4057.z, 0.0, 1.0), clamp(fa_mesh_fs_params[5].y * _4057.y, 0.0500000007450580596923828125, 1.0), 1.0 + (fa_mesh_fs_params[6].y * (_4096.x - 1.0)), fa_mesh_fs_params[3].xyz + (fa_mesh_fs_params[4].xyz * _4126), _5550, _5551, fa_mesh_fs_params[21].xyz, _5553, _5554, fa_mesh_fs_params[20].w, _5556, fa_mesh_fs_params[22].y, fa_mesh_fs_params[23].xyz, fa_mesh_fs_params[30].x, fa_mesh_fs_params[30].y, fa_mesh_fs_params[31].xyz, fa_mesh_fs_params[30].z);\n}\n\nvoid surface(SurfaceInput i, Surface s)\n{\n}\n\nvec4 fa_decal_tile(vec4 rect, vec2 uv, vec2 atlas, vec2 ddx, vec2 ddy)\n{\n    vec2 _1581 = rect.zw - rect.xy;\n    vec2 _1585 = _1581 * atlas;\n    vec2 _1589 = ddx * _1585;\n    vec2 _1593 = ddy * _1585;\n    return textureLod(fa_decal_tex_fa_env_smp, rect.xy + (clamp(uv, vec2(0.0), vec2(1.0)) * _1581), clamp(0.5 * log2(max(max(dot(_1589, _1589), dot(_1593, _1593)), 9.9999999392252902907785028219223e-09)), 0.0, 4.0));\n}\n\nvec3 fa_dc_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_dc_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvoid fa_apply_decals(vec3 world_pos, vec3 geo_normal, inout vec3 albedo, inout vec3 normal)\n{\n    bool _1626 = fa_mesh_fs_params[10].y < 0.5;\n    bool _1633;\n    if (!_1626)\n    {\n        _1633 = fa_mesh_fs_params[10].w < 0.5;\n    }\n    else\n    {\n        _1633 = _1626;\n    }\n    if (_1633)\n    {\n        return;\n    }\n    vec3 _1639 = dFdx(world_pos);\n    vec3 _1642 = dFdy(world_pos);\n    vec3 param = world_pos;\n    vec4 _1646 = fa_cluster_texel(param);\n    int _1650 = int(_1646.w);\n    if (_1650 < 1)\n    {\n        return;\n    }\n    int _1660 = int(fa_mesh_fs_params[10].y + 0.5);\n    int param_1 = _1660;\n    vec4 _1664 = fa_light_texel(param_1);\n    vec2 _1667 = _1664.yz;\n    int _1671 = int(_1664.w);\n    int param_2 = _1660 + 1;\n    vec4 _1676 = fa_light_texel(param_2);\n    float _1677 = _1676.x;\n    int _1683 = int(fa_mesh_fs_params[10].w + 0.5) - 1;\n    int _1687 = int(_1646.z);\n    vec3 _1952;\n    for (int k = 0; k < _1650; k++)\n    {\n        int _1700 = _1687 + k;\n        int param_3 = _1671 + (_1700 >> 2);\n        int _1717 = (_1660 + 2) + (int(fa_light_texel(param_3)[_1700 & 3]) * 7);\n        int param_4 = _1717 + 6;\n        vec4 _1722 = fa_light_texel(param_4);\n        if (((int(_1722.w + 0.5) >> _1683) & 1) == 0)\n        {\n            continue;\n        }\n        int param_5 = _1717;\n        vec4 _1737 = fa_light_texel(param_5);\n        int param_6 = _1717 + 1;\n        vec4 _1742 = fa_light_texel(param_6);\n        int param_7 = _1717 + 2;\n        vec4 _1747 = fa_light_texel(param_7);\n        vec3 _1750 = _1737.xyz;\n        float _1755 = dot(_1750, world_pos) + _1737.w;\n        vec3 _1757 = _1742.xyz;\n        float _1762 = dot(_1757, world_pos) + _1742.w;\n        vec3 _1764 = _1747.xyz;\n        float _1769 = dot(_1764, world_pos) + _1747.w;\n        bool _1774 = abs(_1755) > 0.5;\n        bool _1782;\n        if (!_1774)\n        {\n            _1782 = abs(_1762) > 0.5;\n        }\n        else\n        {\n            _1782 = _1774;\n        }\n        bool _1790;\n        if (!_1782)\n        {\n            _1790 = abs(_1769) > 0.5;\n        }\n        else\n        {\n            _1790 = _1782;\n        }\n        if (_1790)\n        {\n            continue;\n        }\n        float _1805 = clamp(dot(geo_normal, normalize(_1764)) * _1722.z, 0.0, 1.0);\n        if (_1805 <= 0.0)\n        {\n            continue;\n        }\n        float _1825 = (clamp((0.5 - abs(_1769)) * 10.0, 0.0, 1.0) * _1805) * _1722.x;\n        vec2 _1833 = vec2(_1755 + 0.5, 0.5 - _1762);\n        vec2 _1843 = vec2(dot(_1750, _1639), dot(_1757, _1639));\n        vec2 _1853 = vec2(dot(_1750, _1642), dot(_1757, _1642));\n        int param_8 = _1717 + 5;\n        vec4 _1858 = fa_light_texel(param_8);\n        int param_9 = _1717 + 3;\n        vec4 _1863 = fa_light_texel(param_9);\n        int param_10 = _1717 + 4;\n        vec4 _1868 = fa_light_texel(param_10);\n        float tex_a = 1.0;\n        vec3 col = _1858.xyz;\n        bool _1878 = _1863.z > _1863.x;\n        if (_1878)\n        {\n            vec4 param_11 = _1863;\n            vec2 param_12 = _1833;\n            vec2 param_13 = _1667;\n            vec2 param_14 = _1843;\n            vec2 param_15 = _1853;\n            vec4 tx = fa_decal_tile(param_11, param_12, param_13, param_14, param_15);\n            if ((_1677 > 0.5) && (_1677 < 1.5))\n            {\n                vec3 param_16 = tx.xyz;\n                vec3 _1904 = fa_dc_to_linear(param_16);\n                vec4 _5633 = tx;\n                _5633.x = _1904.x;\n                _5633.y = _1904.y;\n                _5633.z = _1904.z;\n                tx = _5633;\n            }\n            col *= tx.xyz;\n            tex_a = tx.w;\n        }\n        albedo = mix(albedo, col, vec3(clamp((_1825 * tex_a) * _1858.w, 0.0, 1.0)));\n        if (_1868.z > _1868.x)\n        {\n            vec4 param_17 = _1868;\n            vec2 param_18 = _1833;\n            vec2 param_19 = _1667;\n            vec2 param_20 = _1843;\n            vec2 param_21 = _1853;\n            vec4 _1948 = fa_decal_tile(param_17, param_18, param_19, param_20, param_21);\n            if (_1677 > 1.5)\n            {\n                vec3 param_22 = _1948.xyz;\n                vec3 _1958 = fa_dc_to_srgb(param_22);\n                _1952 = _1958;\n            }\n            else\n            {\n                _1952 = _1948.xyz;\n            }\n            vec3 _1967 = (_1952 * 2.0) - vec3(1.0);\n            vec2 _1972 = _1967.xy * _1722.y;\n            vec3 _1994 = (normalize(_1750) * _1972.x) + (normalize(_1757) * _1972.y);\n            vec3 _1997 = normalize(normal);\n            normal = normalize(mix(_1997, normalize((_1997 * max(_1967.z, 0.0500000007450580596923828125)) + (_1994 - (_1997 * dot(_1997, _1994)))), vec3(clamp(_1825 * (_1878 ? tex_a : 1.0), 0.0, 1.0))));\n        }\n    }\n}\n\nvec3 fa_sh_eval(vec3 c[9], vec3 n)\n{\n    vec3 _3192 = max((((c[0] * 0.2820948064327239990234375) + (((c[1] * (0.3257350027561187744140625 * n.y)) + (c[2] * (0.3257350027561187744140625 * n.z))) + (c[3] * (0.3257350027561187744140625 * n.x)))) + (((c[4] * ((0.2731371223926544189453125 * n.x) * n.y)) + (c[5] * ((0.2731371223926544189453125 * n.y) * n.z))) + (c[6] * (0.078847892582416534423828125 * (((3.0 * n.z) * n.z) - 1.0))))) + ((c[7] * ((0.2731371223926544189453125 * n.x) * n.z)) + (c[8] * (0.13656856119632720947265625 * ((n.x * n.x) - (n.y * n.y))))), vec3(0.0));\n    return _3192;\n}\n\nvec2 fa_atlas_size()\n{\n    return vec2(textureSize(fa_probe_atlas_fa_env_smp, 0));\n}\n\nvec4 fa_gi_fetch(vec2 texel)\n{\n    return textureLod(fa_probe_atlas_fa_env_smp, texel / fa_atlas_size(), 0.0);\n}\n\nvec2 fa_oct_encode(vec3 d)\n{\n    vec3 _3212 = d / vec3(max((abs(d.x) + abs(d.y)) + abs(d.z), 9.9999999600419720025001879548654e-13));\n    float _3215 = _3212.x;\n    float _3217 = _3212.z;\n    vec2 e = vec2(_3215, _3217);\n    if (_3212.y < 0.0)\n    {\n        e = vec2((1.0 - abs(_3217)) * ((_3215 < 0.0) ? (-1.0) : 1.0), (1.0 - abs(_3215)) * ((_3217 < 0.0) ? (-1.0) : 1.0));\n    }\n    return e;\n}\n\nvec3 fa_gi_grid(int rec, vec3 n, vec3 v, out float cover)\n{\n    cover = 0.0;\n    int param = rec;\n    vec4 _4240 = fa_light_texel(param);\n    int param_1 = rec + 1;\n    vec4 _4245 = fa_light_texel(param_1);\n    int param_2 = rec + 2;\n    vec4 _4250 = fa_light_texel(param_2);\n    int param_3 = rec + 3;\n    vec4 _4255 = fa_light_texel(param_3);\n    bool _4258 = _4255.z < 0.5;\n    bool _4266;\n    if (!_4258)\n    {\n        _4266 = fa_atlas_size().y < 1155.0;\n    }\n    else\n    {\n        _4266 = _4258;\n    }\n    if (_4266)\n    {\n        return vec3(0.0);\n    }\n    float _4273 = max(_4240.w, 9.9999997473787516355514526367188e-05);\n    vec3 _4276 = _4245.xyz;\n    vec3 _4280 = _4240.xyz;\n    vec3 _4284 = (fa_world_pos - _4280) / vec3(_4273);\n    vec3 _4293 = min(_4284 + vec3(0.5), (_4276 - vec3(0.5)) - _4284);\n    float _4302 = min(_4293.x, min(_4293.y, _4293.z));\n    if (!(_4302 > 0.0))\n    {\n        return vec3(0.0);\n    }\n    vec3 _4317 = _4276 - vec3(1.0);\n    vec3 _4318 = clamp(_4284, vec3(0.0), _4317);\n    vec3 _4326 = min(floor(_4318), max(_4276 - vec3(2.0), vec3(0.0)));\n    vec3 _4330 = _4318 - _4326;\n    vec3 _4342 = fa_world_pos + (((n * 0.800000011920928955078125) + (v * 0.20000000298023223876953125)) * (0.20000000298023223876953125 * _4273));\n    int _4347 = int(_4250.y + 0.5);\n    vec3 sh[9];\n    for (int k = 0; k < 9; k++)\n    {\n        sh[k] = vec3(0.0);\n    }\n    float wsum = 0.0;\n    int _4365 = int(_4255.w);\n    int _4366 = 8 + _4365;\n    int _4371 = 9 + _4365;\n    float _4398;\n    float _4411;\n    float _4425;\n    for (int k_1 = 0; k_1 < _4366; k_1++)\n    {\n        float _4384 = float(k_1 & 1);\n        float _4388 = float((k_1 >> 1) & 1);\n        float _4392 = float((k_1 >> 2) & 1);\n        if (_4384 > 0.5)\n        {\n            _4398 = _4330.x;\n        }\n        else\n        {\n            _4398 = 1.0 - _4330.x;\n        }\n        if (_4388 > 0.5)\n        {\n            _4411 = _4330.y;\n        }\n        else\n        {\n            _4411 = 1.0 - _4330.y;\n        }\n        if (_4392 > 0.5)\n        {\n            _4425 = _4330.z;\n        }\n        else\n        {\n            _4425 = 1.0 - _4330.z;\n        }\n        float _4435 = (_4398 * _4411) * _4425;\n        if (!(_4435 > 0.0))\n        {\n            continue;\n        }\n        vec3 _4448 = min(_4326 + vec3(_4384, _4388, _4392), _4317);\n        int _4468 = int(((_4250.x + _4448.x) + (_4245.x * (_4448.y + (_4245.y * _4448.z)))) + 0.5);\n        vec2 _4483 = vec2(float(_4468 % _4347) * 10.0, 1024.0 + (float(_4468 / _4347) * 11.0));\n        vec2 param_4 = _4483 + vec2(9.5, 10.5);\n        vec4 _4491 = fa_gi_fetch(param_4);\n        bool _4494 = _4491.y < 0.5;\n        bool _4503;\n        if (!_4494)\n        {\n            _4503 = _4491.x > _4255.y;\n        }\n        else\n        {\n            _4503 = _4494;\n        }\n        if (_4503)\n        {\n            continue;\n        }\n        vec3 _4515 = _4342 - (_4280 + (_4448 * _4273));\n        float _4518 = length(_4515);\n        vec3 _4524 = _4515 / vec3(max(_4518, 9.9999997473787516355514526367188e-05));\n        float _4534 = max(9.9999997473787516355514526367188e-05, (dot(-_4524, n) + 1.0) * 0.5);\n        float w = _4435 * (_4534 * _4534);\n        vec3 param_5 = _4524;\n        vec2 param_6 = (_4483 + vec2(1.0)) + (((fa_oct_encode(param_5) * 0.5) + vec2(0.5)) * 8.0);\n        vec4 _4553 = fa_gi_fetch(param_6);\n        float _4560 = _4518 / max(_4250.z, 9.9999997473787516355514526367188e-05);\n        float _4563 = _4553.x;\n        if (_4560 > _4563)\n        {\n            float _4576 = max(_4553.y - (_4563 * _4563), 0.0);\n            float _4581 = _4560 - _4563;\n            float _4590 = _4576 / max(_4576 + (_4581 * _4581), 9.9999999600419720025001879548654e-13);\n            w *= ((_4590 * _4590) * _4590);\n        }\n        if (!(w > 0.0))\n        {\n            continue;\n        }\n        for (int c = 0; c < _4371; c++)\n        {\n            vec2 param_7 = _4483 + vec2(float(c) + 0.5, 10.5);\n            sh[c] += (fa_gi_fetch(param_7).xyz * w);\n        }\n        wsum += w;\n    }\n    if (!(wsum > 9.9999997473787516355514526367188e-06))\n    {\n        return vec3(0.0);\n    }\n    for (int c_1 = 0; c_1 < 9; c_1++)\n    {\n        sh[c_1] /= vec3(wsum);\n    }\n    cover = smoothstep(0.0, 1.0, clamp(_4302 * 2.0, 0.0, 1.0)) * smoothstep(0.0, 0.0199999995529651641845703125, wsum);\n    float _4671;\n    if (fa_mesh_fs_params[52].z > 0.5)\n    {\n        _4671 = _4255.x;\n    }\n    else\n    {\n        _4671 = 1.0;\n    }\n    vec3 param_8[9] = sh;\n    vec3 param_9 = n;\n    return fa_sh_eval(param_8, param_9) * (_4250.w * _4671);\n}\n\nvec3 fa_gi_light(vec3 n, inout float left)\n{\n    left = 1.0;\n    vec3 acc = vec3(0.0);\n    vec3 _4695 = normalize(fa_mesh_fs_params[0].xyz - fa_world_pos);\n    int _4700 = int(fa_mesh_fs_params[52].x + 0.5);\n    int _4705 = int(fa_mesh_fs_params[52].y + 0.5);\n    float param_3;\n    for (int k = 0; (k < _4705) && (k < 8); k++)\n    {\n        int param = _4700 + (4 * k);\n        vec3 param_1 = n;\n        vec3 param_2 = _4695;\n        vec3 _4730 = fa_gi_grid(param, param_1, param_2, param_3);\n        float _4735 = param_3 * left;\n        acc += (_4730 * _4735);\n        left -= _4735;\n        if (left < 0.001000000047497451305389404296875)\n        {\n            left = 0.0;\n            break;\n        }\n    }\n    return acc;\n}\n\nvec3 fa_probe_sh_coef(vec2 origin, float res, int k)\n{\n    vec3 v = textureLod(fa_probe_atlas_fa_env_smp, (origin + vec2(float(k) + 0.5, res + 2.5)) / fa_atlas_size(), 0.0).xyz;\n    if (fa_mesh_fs_params[41].y > 0.5)\n    {\n        v = (v - vec3(0.5)) * 8.0;\n    }\n    return v;\n}\n\nvec3 fa_ambient_light(vec3 n)\n{\n    float _3299 = (1.0 - fa_mesh_fs_params[42].w) - fa_mesh_fs_params[47].w;\n    vec3 amb = vec3(0.0);\n    bool _3305 = fa_mesh_fs_params[11].w > 0.5;\n    vec3 c[9];\n    for (int k = 0; k < 9; k++)\n    {\n        c[k] = vec3(0.0);\n    }\n    if (_3299 > 0.0005000000237487256526947021484375)\n    {\n        if (_3305)\n        {\n            for (int k_1 = 0; k_1 < 9; k_1++)\n            {\n                vec2 param = fa_mesh_fs_params[41].zw;\n                float param_1 = 128.0;\n                int param_2 = k_1;\n                c[k_1] = fa_probe_sh_coef(param, param_1, param_2) * _3299;\n            }\n        }\n        else\n        {\n            amb = fa_mesh_fs_params[1].xyz * _3299;\n        }\n    }\n    bool _3358 = fa_mesh_fs_params[42].w > 0.0;\n    if (_3358)\n    {\n        for (int k_2 = 0; k_2 < 9; k_2++)\n        {\n            vec2 param_3 = fa_mesh_fs_params[42].xy;\n            float param_4 = fa_mesh_fs_params[42].z;\n            int param_5 = k_2;\n            c[k_2] += (fa_probe_sh_coef(param_3, param_4, param_5) * fa_mesh_fs_params[42].w);\n        }\n    }\n    bool _3389 = fa_mesh_fs_params[47].w > 0.0;\n    if (_3389)\n    {\n        for (int k_3 = 0; k_3 < 9; k_3++)\n        {\n            vec2 param_6 = fa_mesh_fs_params[47].xy;\n            float param_7 = fa_mesh_fs_params[47].z;\n            int param_8 = k_3;\n            c[k_3] += (fa_probe_sh_coef(param_6, param_7, param_8) * fa_mesh_fs_params[47].w);\n        }\n    }\n    if ((_3305 || _3358) || _3389)\n    {\n        vec3 param_9[9] = c;\n        vec3 param_10 = n;\n        amb += fa_sh_eval(param_9, param_10);\n    }\n    return amb;\n}\n\nvec3 fa_realtime_or_ambient(vec3 n)\n{\n    if (fa_mesh_fs_params[52].y > 0.5)\n    {\n        vec3 param = n;\n        float param_1;\n        vec3 _4764 = fa_gi_light(param, param_1);\n        if (param_1 < 0.999000012874603271484375)\n        {\n            vec3 _4773;\n            if (param_1 > 0.0)\n            {\n                vec3 param_2 = n;\n                _4773 = _4764 + (fa_ambient_light(param_2) * param_1);\n            }\n            else\n            {\n                _4773 = _4764;\n            }\n            return _4773;\n        }\n    }\n    vec3 param_3 = n;\n    return fa_ambient_light(param_3);\n}\n\nvec3 fa_indirect_diffuse(vec3 n)\n{\n    if (fa_lm.z > 0.5)\n    {\n        return textureLod(fa_lightmap_fa_env_smp, fa_lm.xy, 0.0).xyz;\n    }\n    if (fa_mesh_fs_params[32].w > 0.0)\n    {\n        vec3 c[9];\n        for (int k = 0; k < 9; k++)\n        {\n            c[k] = fa_mesh_fs_params[k * 1 + 32].xyz;\n        }\n        vec3 param[9] = c;\n        vec3 param_1 = n;\n        vec3 _4835 = fa_sh_eval(param, param_1);\n        if (fa_mesh_fs_params[32].w >= 1.0)\n        {\n            return _4835;\n        }\n        vec3 param_2 = n;\n        return mix(fa_realtime_or_ambient(param_2), _4835, vec3(clamp(fa_mesh_fs_params[32].w, 0.0, 1.0)));\n    }\n    vec3 param_3 = n;\n    return fa_realtime_or_ambient(param_3);\n}\n\nvec3 ambient(SurfaceInput i, Surface s, vec3 ambientColor)\n{\n    return ambientColor;\n}\n\nint fa_cluster_index(int slot, int n)\n{\n    int param = (int(fa_mesh_fs_params[19].x) + int(fa_mesh_fs_params[19].w)) + ((slot + n) >> 2);\n    vec4 t = fa_light_texel(param);\n    return int(t[(slot + n) & 3]);\n}\n\nint fa_cl_light(int n)\n{\n    if (n < fa_cl_ndir)\n    {\n        return n;\n    }\n    int param = fa_cl_slot;\n    int param_1 = n - fa_cl_ndir;\n    return fa_cluster_index(param, param_1);\n}\n\nint fa_light_base(int li)\n{\n    return li * ((fa_mesh_fs_params[1].w > 4.5) ? 8 : 4);\n}\n\nbool fa_light_baked(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 3;\n    return fa_light_texel(param_1).w > 0.5;\n}\n\nfloat fa_baked_keep(int li)\n{\n    float _3698;\n    if (fa_lm.z > 0.5)\n    {\n        _3698 = 0.0;\n    }\n    else\n    {\n        _3698 = 1.0 - clamp(fa_mesh_fs_params[32].w, 0.0, 1.0);\n    }\n    bool _3709 = _3698 < 1.0;\n    bool _3715;\n    if (_3709)\n    {\n        int param = li;\n        _3715 = fa_light_baked(param);\n    }\n    else\n    {\n        _3715 = _3709;\n    }\n    return _3715 ? _3698 : 1.0;\n}\n\nfloat fa_light_type(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 1;\n    return fa_light_texel(param_1).w;\n}\n\nvec3 fa_area_point(vec3 c, vec3 axis, vec3 ru, vec3 uu, float hx, float hy, float shape, vec3 p, vec3 r)\n{\n    bool _600 = dot(r, r) > 0.5;\n    if (shape > 1.5)\n    {\n        vec3 _613 = (c - (ru * hx)) - p;\n        vec3 _619 = ru * (2.0 * hx);\n        float _625 = max(dot(_619, _619), 9.9999999392252902907785028219223e-09);\n        float _629 = dot(_613, _619);\n        float t = clamp((-_629) / _625, 0.0, 1.0);\n        if (_600)\n        {\n            float _644 = dot(r, _619);\n            float _650 = _625 - (_644 * _644);\n            if (abs(_650) > (9.9999997473787516355514526367188e-06 * _625))\n            {\n                t = clamp(((dot(r, _613) * _644) - _629) / _650, 0.0, 1.0);\n            }\n        }\n        return (p + _613) + (_619 * t);\n    }\n    vec3 q = p;\n    float _682 = dot(r, axis);\n    bool _690;\n    if (_600)\n    {\n        _690 = abs(_682) > 9.9999997473787516355514526367188e-05;\n    }\n    else\n    {\n        _690 = _600;\n    }\n    if (_690)\n    {\n        float _700 = dot(c - p, axis) / _682;\n        if (_700 > 0.0)\n        {\n            q = p + (r * _700);\n        }\n    }\n    vec3 _713 = q - c;\n    vec2 xy = vec2(dot(_713, ru), dot(_713, uu));\n    if (shape > 0.5)\n    {\n        float _728 = length(xy);\n        if (_728 > hx)\n        {\n            xy *= (hx / _728);\n        }\n    }\n    else\n    {\n        xy = clamp(xy, vec2(-hx, -hy), vec2(hx, hy));\n    }\n    return (c + (ru * xy.x)) + (uu * xy.y);\n}\n\nvec4 fa_atlas_fetch(vec2 texel)\n{\n    return textureLod(fa_light_atlas_fa_env_smp, texel / vec2(textureSize(fa_light_atlas_fa_env_smp, 0)), 0.0);\n}\n\nvec3 fa_cookie_sample(vec2 tile_origin, vec2 uv)\n{\n    vec2 param = (tile_origin + vec2(1.0)) + (clamp(uv, vec2(0.0), vec2(1.0)) * 254.0);\n    return fa_atlas_fetch(param).xyz;\n}\n\nfloat fa_ies_sample(vec2 tile_origin, vec3 d, vec3 axis, vec3 right, vec3 up)\n{\n    float _520 = dot(d, right);\n    float _524 = dot(d, up);\n    float _535;\n    if (((_520 * _520) + (_524 * _524)) > 1.0000000133514319600180897396058e-10)\n    {\n        _535 = atan(_524, _520) * 0.15915493667125701904296875;\n    }\n    else\n    {\n        _535 = 0.0;\n    }\n    vec2 param = tile_origin + vec2(1.0 + ((_535 - floor(_535)) * 64.0), 1.0 + (acos(clamp(dot(d, axis), -1.0, 1.0)) * 10.18591594696044921875));\n    return fa_atlas_fetch(param).x;\n}\n\nint fa_cube_face(vec3 d)\n{\n    vec3 _370 = abs(d);\n    float _372 = _370.x;\n    float _374 = _370.y;\n    bool _375 = _372 >= _374;\n    bool _383;\n    if (_375)\n    {\n        _383 = _372 >= _370.z;\n    }\n    else\n    {\n        _383 = _375;\n    }\n    int _384;\n    if (_383)\n    {\n        _384 = (d.x > 0.0) ? 0 : 1;\n    }\n    else\n    {\n        int _399;\n        if (_374 >= _370.z)\n        {\n            _399 = (d.y > 0.0) ? 2 : 3;\n        }\n        else\n        {\n            _399 = (d.z > 0.0) ? 4 : 5;\n        }\n        _384 = _399;\n    }\n    return _384;\n}\n\nvoid fa_cube_face_basis(int f, out vec3 fwd, out vec3 up)\n{\n    if (f == 0)\n    {\n        fwd = vec3(1.0, 0.0, 0.0);\n        up = vec3(0.0, 1.0, 0.0);\n    }\n    else\n    {\n        if (f == 1)\n        {\n            fwd = vec3(-1.0, 0.0, 0.0);\n            up = vec3(0.0, 1.0, 0.0);\n        }\n        else\n        {\n            if (f == 2)\n            {\n                fwd = vec3(0.0, 1.0, 0.0);\n                up = vec3(0.0, 0.0, 1.0);\n            }\n            else\n            {\n                if (f == 3)\n                {\n                    fwd = vec3(0.0, -1.0, 0.0);\n                    up = vec3(0.0, 0.0, -1.0);\n                }\n                else\n                {\n                    if (f == 4)\n                    {\n                        fwd = vec3(0.0, 0.0, 1.0);\n                        up = vec3(0.0, 1.0, 0.0);\n                    }\n                    else\n                    {\n                        fwd = vec3(0.0, 0.0, -1.0);\n                        up = vec3(0.0, 1.0, 0.0);\n                    }\n                }\n            }\n        }\n    }\n}\n\nLightSample fa_light_sample_n(int li, vec3 world_pos, vec3 n)\n{\n    int param = li;\n    int _766 = fa_light_base(param);\n    bool _770 = fa_mesh_fs_params[1].w > 4.5;\n    int param_1 = _766;\n    vec4 _774 = fa_light_texel(param_1);\n    int param_2 = _766 + 1;\n    vec4 _779 = fa_light_texel(param_2);\n    float _782 = _779.w;\n    float atten = 1.0;\n    float dist = 0.0;\n    fa_light_tint = vec3(1.0);\n    bool _794 = _770 && (_782 > 2.5);\n    fa_light_is_area = _794;\n    bool _796 = _782 < 0.5;\n    vec3 l;\n    if (_796)\n    {\n        l = normalize(_774.xyz);\n        if (_770)\n        {\n            int param_3 = _766 + 6;\n            vec4 _810 = fa_light_texel(param_3);\n            if (_810.z > 0.5)\n            {\n                int param_4 = _766 + 4;\n                vec4 _820 = fa_light_texel(param_4);\n                int param_5 = _766 + 5;\n                vec4 _825 = fa_light_texel(param_5);\n                vec2 param_6 = _810.xy;\n                vec2 param_7 = fract(vec2(dot(world_pos, _820.xyz) * _820.w, (-dot(world_pos, _825.xyz)) * _825.w) + vec2(0.5));\n                fa_light_tint = fa_cookie_sample(param_6, param_7);\n            }\n        }\n    }\n    else\n    {\n        vec3 _855 = _774.xyz;\n        vec3 _857 = _855 - world_pos;\n        vec3 to_light = _857;\n        float _860 = length(_857);\n        float reach = _860;\n        bool front = true;\n        if (_794)\n        {\n            int param_8 = _766 + 7;\n            reach = max(_860 - fa_light_texel(param_8).w, 0.0);\n            int param_9 = _766 + 4;\n            vec4 _884 = fa_light_texel(param_9);\n            int param_10 = _766 + 5;\n            vec4 _889 = fa_light_texel(param_10);\n            int param_11 = _766 + 6;\n            vec4 _894 = fa_light_texel(param_11);\n            float _895 = _894.w;\n            int param_12 = _766 + 2;\n            vec3 _902 = normalize(fa_light_texel(param_12).xyz);\n            bool _904 = _895 > 1.5;\n            bool _912;\n            if (!_904)\n            {\n                _912 = dot(_902, to_light) < 0.0;\n            }\n            else\n            {\n                _912 = _904;\n            }\n            front = _912;\n            vec3 r = vec3(0.0);\n            vec3 _921 = fa_mesh_fs_params[0].xyz - world_pos;\n            bool _925 = dot(n, n) > 0.5;\n            bool _933;\n            if (_925)\n            {\n                _933 = dot(_921, _921) > 9.9999999600419720025001879548654e-13;\n            }\n            else\n            {\n                _933 = _925;\n            }\n            if (_933)\n            {\n                r = reflect(-normalize(_921), normalize(n));\n            }\n            vec3 param_13 = _855;\n            vec3 param_14 = _902;\n            vec3 param_15 = _884.xyz;\n            vec3 param_16 = _889.xyz;\n            float param_17 = _884.w;\n            float param_18 = _889.w;\n            float param_19 = _895;\n            vec3 param_20 = world_pos;\n            vec3 param_21 = r;\n            to_light = fa_area_point(param_13, param_14, param_15, param_16, param_17, param_18, param_19, param_20, param_21) - world_pos;\n        }\n        float _969 = length(to_light);\n        dist = _969;\n        l = to_light / vec3(max(_969, 9.9999997473787516355514526367188e-05));\n        float _983 = reach / max(_774.w, 0.001000000047497451305389404296875);\n        float _989 = clamp(1.0 - (_983 * _983), 0.0, 1.0);\n        float _991;\n        if (front)\n        {\n            _991 = _989 * _989;\n        }\n        else\n        {\n            _991 = 0.0;\n        }\n        atten = _991;\n        bool _1002 = _782 < 2.5;\n        if ((_782 > 1.5) && _1002)\n        {\n            int param_22 = _766 + 2;\n            vec4 _1010 = fa_light_texel(param_22);\n            float _1020 = _1010.w;\n            int param_23 = _766 + 3;\n            vec4 _1025 = fa_light_texel(param_23);\n            float _1026 = _1025.x;\n            float cos_inner = _1026;\n            if (_1026 > 1.5)\n            {\n                cos_inner = mix(_1020, 1.0, 0.25);\n            }\n            atten *= smoothstep(_1020, cos_inner, dot(-l, normalize(_1010.xyz)));\n        }\n        if (_770 && (_782 < 1.5))\n        {\n            int param_24 = _766 + 6;\n            vec4 _1050 = fa_light_texel(param_24);\n            if (_1050.z > 0.5)\n            {\n                vec3 _1058 = -to_light;\n                int param_25 = _766 + 4;\n                int param_26 = _766 + 5;\n                vec3 _1072 = fa_light_texel(param_25).xyz;\n                vec3 _1076 = fa_light_texel(param_26).xyz;\n                vec3 _1085 = vec3(dot(_1058, _1072), dot(_1058, _1076), dot(_1058, cross(_1072, _1076)));\n                vec3 param_27 = _1085;\n                int _1089 = fa_cube_face(param_27);\n                int param_28 = _1089;\n                vec3 param_29;\n                vec3 param_30;\n                fa_cube_face_basis(param_28, param_29, param_30);\n                vec2 _1116 = vec2(dot(_1085, cross(param_29, param_30)), dot(_1085, param_30)) / vec2(max(dot(_1085, param_29), 9.9999997473787516355514526367188e-05));\n                int _1120 = _1089 / 3;\n                vec2 param_31 = _1050.xy + (vec2(float(_1089 - (_1120 * 3)), float(_1120)) * 256.0);\n                vec2 param_32 = vec2(0.5 + (0.5 * _1116.x), 0.5 - (0.5 * _1116.y));\n                fa_light_tint = fa_cookie_sample(param_31, param_32);\n            }\n            int param_33 = _766 + 7;\n            vec4 _1150 = fa_light_texel(param_33);\n            if (_1150.z > 0.5)\n            {\n                int param_34 = _766 + 2;\n                int param_35 = _766 + 4;\n                int param_36 = _766 + 5;\n                vec2 param_37 = _1150.xy;\n                vec3 param_38 = -l;\n                vec3 param_39 = normalize(fa_light_texel(param_34).xyz);\n                vec3 param_40 = fa_light_texel(param_35).xyz;\n                vec3 param_41 = fa_light_texel(param_36).xyz;\n                atten *= fa_ies_sample(param_37, param_38, param_39, param_40, param_41);\n            }\n        }\n        else\n        {\n            if (_770 && _1002)\n            {\n                int param_42 = _766 + 6;\n                vec4 _1197 = fa_light_texel(param_42);\n                int param_43 = _766 + 7;\n                vec4 _1202 = fa_light_texel(param_43);\n                bool _1205 = _1197.z > 0.5;\n                bool _1212;\n                if (!_1205)\n                {\n                    _1212 = _1202.z > 0.5;\n                }\n                else\n                {\n                    _1212 = _1205;\n                }\n                if (_1212)\n                {\n                    int param_44 = _766 + 2;\n                    vec4 _1219 = fa_light_texel(param_44);\n                    vec3 _1223 = normalize(_1219.xyz);\n                    int param_45 = _766 + 4;\n                    vec4 _1228 = fa_light_texel(param_45);\n                    int param_46 = _766 + 5;\n                    vec4 _1233 = fa_light_texel(param_46);\n                    if (_1205)\n                    {\n                        vec3 _1241 = -to_light;\n                        float _1248 = _1219.w;\n                        float _1264 = 0.5 / max(dot(_1241, _1223) * (sqrt(max(1.0 - (_1248 * _1248), 0.0)) / max(_1248, 0.001000000047497451305389404296875)), 9.9999997473787516355514526367188e-05);\n                        vec2 param_47 = _1197.xy;\n                        vec2 param_48 = vec2(0.5 + (dot(_1241, _1228.xyz) * _1264), 0.5 - (dot(_1241, _1233.xyz) * _1264));\n                        fa_light_tint = fa_cookie_sample(param_47, param_48);\n                    }\n                    if (_1202.z > 0.5)\n                    {\n                        vec2 param_49 = _1202.xy;\n                        vec3 param_50 = -l;\n                        vec3 param_51 = _1223;\n                        vec3 param_52 = _1228.xyz;\n                        vec3 param_53 = _1233.xyz;\n                        atten *= fa_ies_sample(param_49, param_50, param_51, param_52, param_53);\n                    }\n                }\n            }\n        }\n    }\n    vec3 _5499 = _779.xyz * atten;\n    if (_770)\n    {\n        _5499 *= fa_light_tint;\n    }\n    int _1332;\n    if (_796)\n    {\n        _1332 = 0;\n    }\n    else\n    {\n        _1332 = ((_782 > 1.5) && (_782 < 2.5)) ? 2 : 1;\n    }\n    return LightSample(l, _5499, atten, 1.0, dist, _1332);\n}\n\nfloat fa_shadow_depth(inout vec2 uv, vec4 rect)\n{\n    uv = clamp(uv, rect.xy, rect.zw);\n    return textureLod(fa_shadow_tex_fa_shadow_smp, uv, 0.0).x;\n}\n\nfloat fa_shadow_fetch(vec2 uv, vec4 rect, vec3 conv)\n{\n    vec2 param = uv;\n    vec4 param_1 = rect;\n    float _2126 = fa_shadow_depth(param, param_1);\n    float _2130;\n    if (conv.x < 0.5)\n    {\n        _2130 = _2126;\n    }\n    else\n    {\n        _2130 = (conv.y * conv.z) / (conv.z - (_2126 * (conv.z - conv.y)));\n    }\n    return _2130;\n}\n\nfloat fa_shadow_noise()\n{\n    return fract(52.98291778564453125 * fract(dot(gl_FragCoord.xy, vec2(0.067110560834407806396484375, 0.005837149918079376220703125))));\n}\n\nvec2 fa_shadow_vogel(int k, int n, float phi)\n{\n    float _2057 = (float(k) * 2.3999631404876708984375) + phi;\n    return vec2(cos(_2057), sin(_2057)) * sqrt((float(k) + 0.5) / float(n));\n}\n\nfloat fa_shadow_filter(vec2 uv, vec4 rect, float zr, float texel_m, float unit, float reach, float plane, vec3 conv, int mode, float k)\n{\n    if (mode == 1)\n    {\n        vec2 param = uv;\n        vec4 param_1 = rect;\n        vec3 param_2 = conv;\n        return float(zr <= fa_shadow_fetch(param, param_1, param_2));\n    }\n    float _2176 = fa_shadow_noise() * 6.283185482025146484375;\n    float radius = 1.5;\n    if (mode == 2)\n    {\n        float _2185;\n        if (k < 0.0)\n        {\n            _2185 = (-k) / max(zr, 0.100000001490116119384765625);\n        }\n        else\n        {\n            _2185 = k;\n        }\n        float _2205 = clamp((_2185 * reach) / texel_m, 3.0, 12.0);\n        float sum = 0.0;\n        float cnt = 0.0;\n        for (int i = 0; i < 16; i++)\n        {\n            int param_3 = i;\n            int param_4 = 16;\n            float param_5 = _2176;\n            vec2 _2224 = fa_shadow_vogel(param_3, param_4, param_5) * _2205;\n            vec2 param_6 = uv + (_2224 * fa_shadows[26].zw);\n            vec4 param_7 = rect;\n            vec3 param_8 = conv;\n            float _2236 = fa_shadow_fetch(param_6, param_7, param_8);\n            if (_2236 < (zr - (length(_2224) * plane)))\n            {\n                sum += _2236;\n                cnt += 1.0;\n            }\n        }\n        if (cnt < 0.5)\n        {\n            return 1.0;\n        }\n        float _2262 = sum / cnt;\n        float _2272;\n        if (k < 0.0)\n        {\n            _2272 = (-k) / max(_2262, 0.0500000007450580596923828125);\n        }\n        else\n        {\n            _2272 = k;\n        }\n        radius = clamp(((max(zr - _2262, 0.0) * unit) * _2272) / texel_m, 1.5, 16.0);\n    }\n    float lit = 0.0;\n    int _2294 = (mode == 2) ? 24 : 16;\n    for (int i_1 = 0; i_1 < _2294; i_1++)\n    {\n        int param_9 = i_1;\n        int param_10 = _2294;\n        float param_11 = _2176;\n        vec2 _2313 = fa_shadow_vogel(param_9, param_10, param_11) * radius;\n        vec2 param_12 = uv + (_2313 * fa_shadows[26].zw);\n        vec4 param_13 = rect;\n        vec3 param_14 = conv;\n        lit += float((zr - (length(_2313) * plane)) <= fa_shadow_fetch(param_12, param_13, param_14));\n    }\n    return lit / float(_2294);\n}\n\nfloat fa_shadow_local(int li, vec3 lpos, vec3 world, vec3 n, vec3 l)\n{\n    bool _2513 = fa_mesh_fs_params[5].z < 0.5;\n    bool _2520;\n    if (!_2513)\n    {\n        _2520 = fa_shadows[29].x < 0.5;\n    }\n    else\n    {\n        _2520 = _2513;\n    }\n    if (_2520)\n    {\n        return 1.0;\n    }\n    int param = (int(fa_shadows[29].x + 0.5) - 1) + li;\n    vec4 _2533 = fa_light_texel(param);\n    float _2534 = _2533.x;\n    if (_2534 < 0.0)\n    {\n        return 1.0;\n    }\n    int _2543 = int(_2534 + 0.5);\n    int param_1 = _2543;\n    vec4 _2547 = fa_light_texel(param_1);\n    int param_2 = _2543 + 1;\n    vec4 _2552 = fa_light_texel(param_2);\n    float fade = 1.0;\n    float _2555 = _2547.y;\n    if (_2555 > 0.0)\n    {\n        float _2572 = 1.0 - smoothstep(0.75 * _2555, _2555, length(world - fa_shadows[27].xyz));\n        fade = _2572;\n        if (_2572 <= 0.0)\n        {\n            return 1.0;\n        }\n    }\n    int face = 0;\n    if (_2547.x > 1.5)\n    {\n        vec3 param_3 = world - lpos;\n        face = fa_cube_face(param_3);\n    }\n    int _2596 = (_2543 + 2) + (face * 6);\n    int param_4 = _2596;\n    int param_5 = _2596 + 1;\n    int param_6 = _2596 + 3;\n    vec4 _2610 = fa_light_texel(param_6);\n    int param_7 = _2596 + 4;\n    vec4 _2615 = fa_light_texel(param_7);\n    int param_8 = _2596 + 5;\n    vec4 _2620 = fa_light_texel(param_8);\n    float _2632 = _2620.x * max(dot(_2610, vec4(world, 1.0)), 0.001000000047497451305389404296875);\n    float _2637 = clamp(dot(n, l), 0.0, 1.0);\n    float _2660 = clamp(dot(n, _2610.xyz), -1.0, 1.0);\n    float _2679 = min(sqrt(1.0 - (_2660 * _2660)) / max(abs(dot(n, world - lpos)) / max(dot(_2610, vec4(world, 1.0)), 0.001000000047497451305389404296875), 0.20000000298023223876953125), 4.0);\n    float _2682 = _2552.y;\n    float _2684;\n    if (_2682 > 0.0)\n    {\n        _2684 = _2682;\n    }\n    else\n    {\n        _2684 = 1.5 * _2632;\n    }\n    vec4 _2704 = vec4(world + (n * (_2684 * sqrt(1.0 - (_2637 * _2637)))), 1.0);\n    float _2708 = dot(_2610, _2704);\n    float _2711 = _2620.y;\n    if (_2708 < _2711)\n    {\n        return 1.0;\n    }\n    vec2 _2726 = vec2(dot(fa_light_texel(param_4), _2704), dot(fa_light_texel(param_5), _2704)) / vec2(_2708);\n    float _2728 = _2726.x;\n    bool _2731 = _2728 < _2615.x;\n    bool _2740;\n    if (!_2731)\n    {\n        _2740 = _2728 > _2615.z;\n    }\n    else\n    {\n        _2740 = _2731;\n    }\n    bool _2749;\n    if (!_2740)\n    {\n        _2749 = _2726.y < _2615.y;\n    }\n    else\n    {\n        _2749 = _2740;\n    }\n    bool _2758;\n    if (!_2749)\n    {\n        _2758 = _2726.y > _2615.w;\n    }\n    else\n    {\n        _2758 = _2749;\n    }\n    if (_2758)\n    {\n        return 1.0;\n    }\n    float _2764 = _2552.x;\n    float _2766;\n    if (_2764 > 0.0)\n    {\n        _2766 = _2764;\n    }\n    else\n    {\n        _2766 = 1.5 * _2632;\n    }\n    vec2 param_9 = _2726;\n    vec4 param_10 = _2615;\n    float param_11 = _2708 - (_2766 * (1.0 + (0.5 * _2679)));\n    float param_12 = _2632;\n    float param_13 = 1.0;\n    float param_14 = _2620.z * 0.25;\n    float param_15 = (_2632 * min(_2679, 3.0)) * 0.5;\n    vec3 param_16 = vec3(1.0, _2711, _2620.z);\n    int param_17 = int(_2547.z + 0.5);\n    float param_18 = _2547.w;\n    return mix(1.0, fa_shadow_filter(param_9, param_10, param_11, param_12, param_13, param_14, param_15, param_16, param_17, param_18), fade);\n}\n\nfloat fa_shadow_split_at(int i)\n{\n    float _2069;\n    if (i == 0)\n    {\n        _2069 = fa_shadows[24].x;\n    }\n    else\n    {\n        float _2085;\n        if (i == 1)\n        {\n            _2085 = fa_shadows[24].y;\n        }\n        else\n        {\n            float _2093;\n            if (i == 2)\n            {\n                _2093 = fa_shadows[24].z;\n            }\n            else\n            {\n                _2093 = fa_shadows[24].w;\n            }\n            _2085 = _2093;\n        }\n        _2069 = _2085;\n    }\n    return _2069;\n}\n\nfloat fa_shadow_cascade(int ci, vec3 world, vec3 n, vec3 l)\n{\n    float _2355 = max(fa_shadows[ci * 1 + 20].y, 0.001000000047497451305389404296875);\n    float _2360 = clamp(dot(n, l), 0.0, 1.0);\n    float _2366 = sqrt(1.0 - (_2360 * _2360));\n    float _2373 = min(_2366 / max(_2360, 0.20000000298023223876953125), 4.0);\n    float _2378;\n    if (fa_shadows[26].y > 0.0)\n    {\n        _2378 = fa_shadows[26].y;\n    }\n    else\n    {\n        _2378 = 1.5 * fa_shadows[ci * 1 + 20].x;\n    }\n    vec4 _2403 = mat4(fa_shadows[ci * 4 + 0], fa_shadows[ci * 4 + 1], fa_shadows[ci * 4 + 2], fa_shadows[ci * 4 + 3]) * vec4(world + (n * (_2378 * _2366)), 1.0);\n    float _2410 = _2403.x;\n    bool _2413 = _2410 < fa_shadows[ci * 1 + 16].x;\n    bool _2422;\n    if (!_2413)\n    {\n        _2422 = _2410 > fa_shadows[ci * 1 + 16].z;\n    }\n    else\n    {\n        _2422 = _2413;\n    }\n    bool _2431;\n    if (!_2422)\n    {\n        _2431 = _2403.y < fa_shadows[ci * 1 + 16].y;\n    }\n    else\n    {\n        _2431 = _2422;\n    }\n    bool _2440;\n    if (!_2431)\n    {\n        _2440 = _2403.y > fa_shadows[ci * 1 + 16].w;\n    }\n    else\n    {\n        _2440 = _2431;\n    }\n    bool _2447;\n    if (!_2440)\n    {\n        _2447 = _2403.z > 1.0;\n    }\n    else\n    {\n        _2447 = _2440;\n    }\n    if (_2447)\n    {\n        return -1.0;\n    }\n    float _2455;\n    if (fa_shadows[26].x > 0.0)\n    {\n        _2455 = fa_shadows[26].x;\n    }\n    else\n    {\n        _2455 = 1.5 * fa_shadows[ci * 1 + 20].x;\n    }\n    vec2 param = _2403.xy;\n    vec4 param_1 = fa_shadows[ci * 1 + 16];\n    float param_2 = _2403.z - ((_2455 * (1.0 + (0.5 * _2373))) / _2355);\n    float param_3 = fa_shadows[ci * 1 + 20].x;\n    float param_4 = _2355;\n    float param_5 = _2355 * 0.25;\n    float param_6 = ((fa_shadows[ci * 1 + 20].x * min(_2373, 3.0)) * 0.5) / _2355;\n    vec3 param_7 = vec3(0.0);\n    int param_8 = int(fa_shadows[25].z + 0.5);\n    float param_9 = fa_shadows[25].w;\n    return fa_shadow_filter(param, param_1, param_2, param_3, param_4, param_5, param_6, param_7, param_8, param_9);\n}\n\nfloat fa_shadow_sun(vec3 world, vec3 n, vec3 l)\n{\n    if (fa_mesh_fs_params[5].z < 0.5)\n    {\n        return 1.0;\n    }\n    int _2833 = int(fa_shadows[25].x + 0.5);\n    if (_2833 < 1)\n    {\n        return 1.0;\n    }\n    float _2848 = dot(world - fa_shadows[27].xyz, fa_shadows[28].xyz);\n    int param = _2833 - 1;\n    if (_2848 > fa_shadow_split_at(param))\n    {\n        return 1.0;\n    }\n    int ci = 0;\n    bool _2860 = _2833 > 1;\n    bool _2867;\n    if (_2860)\n    {\n        _2867 = _2848 > fa_shadows[24].x;\n    }\n    else\n    {\n        _2867 = _2860;\n    }\n    if (_2867)\n    {\n        ci = 1;\n    }\n    bool _2871 = _2833 > 2;\n    bool _2878;\n    if (_2871)\n    {\n        _2878 = _2848 > fa_shadows[24].y;\n    }\n    else\n    {\n        _2878 = _2871;\n    }\n    if (_2878)\n    {\n        ci = 2;\n    }\n    bool _2882 = _2833 > 3;\n    bool _2889;\n    if (_2882)\n    {\n        _2889 = _2848 > fa_shadows[24].z;\n    }\n    else\n    {\n        _2889 = _2882;\n    }\n    if (_2889)\n    {\n        ci = 3;\n    }\n    float s = -1.0;\n    for (int k = 0; k < 4; k++)\n    {\n        if (ci >= _2833)\n        {\n            break;\n        }\n        int param_1 = ci;\n        vec3 param_2 = world;\n        vec3 param_3 = n;\n        vec3 param_4 = l;\n        float _2915 = fa_shadow_cascade(param_1, param_2, param_3, param_4);\n        s = _2915;\n        if (_2915 >= 0.0)\n        {\n            break;\n        }\n        ci++;\n    }\n    if (s < 0.0)\n    {\n        return 1.0;\n    }\n    if (fa_shadows[25].y > 0.0)\n    {\n        float _2940;\n        if (ci > 0)\n        {\n            int param_5 = ci - 1;\n            _2940 = fa_shadow_split_at(param_5);\n        }\n        else\n        {\n            _2940 = fa_shadows[28].w;\n        }\n        int param_6 = ci;\n        float _2959 = fa_shadows[25].y * max(fa_shadow_split_at(param_6) - _2940, 9.9999997473787516355514526367188e-05);\n        int param_7 = ci;\n        float _2970 = clamp((_2848 - (fa_shadow_split_at(param_7) - _2959)) / _2959, 0.0, 1.0);\n        if (_2970 > 0.0)\n        {\n            float s2 = 1.0;\n            if ((ci + 1) < _2833)\n            {\n                int param_8 = ci + 1;\n                vec3 param_9 = world;\n                vec3 param_10 = n;\n                vec3 param_11 = l;\n                float _2991 = fa_shadow_cascade(param_8, param_9, param_10, param_11);\n                s2 = _2991;\n                if (_2991 < 0.0)\n                {\n                    s2 = s;\n                }\n            }\n            s = mix(s, s2, _2970);\n        }\n    }\n    return s;\n}\n\nfloat fa_shadow_factor(vec3 n, vec3 l)\n{\n    vec3 param = fa_world_pos;\n    vec3 param_1 = n;\n    vec3 param_2 = l;\n    return fa_shadow_sun(param, param_1, param_2);\n}\n\nfloat fa_contact_shadow(int li, vec3 world, vec3 gn, vec3 l, float dist)\n{\n    bool _3440 = fa_mesh_fs_params[24].x < 0.5;\n    bool _3447;\n    if (!_3440)\n    {\n        _3447 = fa_shadows[29].x < 0.5;\n    }\n    else\n    {\n        _3447 = _3440;\n    }\n    if (_3447)\n    {\n        return 1.0;\n    }\n    int param = (int(fa_shadows[29].x + 0.5) - 1) + li;\n    vec4 _3460 = fa_light_texel(param);\n    float _3461 = _3460.y;\n    float len = _3461;\n    if (_3461 <= 0.0)\n    {\n        return 1.0;\n    }\n    float _3473 = length(world - fa_mesh_fs_params[0].xyz);\n    float _3483 = 1.0 - smoothstep(0.5 * fa_mesh_fs_params[25].x, fa_mesh_fs_params[25].x, _3473);\n    if (_3483 <= 0.0)\n    {\n        return 1.0;\n    }\n    float _3489 = len;\n    float _3492 = min(_3489, 0.89999997615814208984375 * dist);\n    len = _3492;\n    float _3498 = 0.004999999888241291046142578125 + (0.0030000000260770320892333984375 * _3473);\n    float _3503 = _3498 + (0.5 * _3492);\n    vec3 _3509 = world + (gn * _3498);\n    float _3511 = fa_shadow_noise();\n    float occ = 0.0;\n    float _3576;\n    for (int k = 0; k < 12; k++)\n    {\n        float _3527 = (float(k) + _3511) * 0.083333335816860198974609375;\n        vec3 _3535 = _3509 + (l * (_3527 * len));\n        vec4 _3541 = vec4(_3535, 1.0);\n        float _3547 = dot(fa_mesh_fs_params[28], _3541);\n        if (_3547 < 9.9999997473787516355514526367188e-05)\n        {\n            break;\n        }\n        vec2 _3567 = vec2(dot(fa_mesh_fs_params[26], _3541), dot(fa_mesh_fs_params[27], _3541)) / vec2(_3547);\n        float _3571 = _3567.x * 0.5;\n        float _3572 = _3571 + 0.5;\n        if (fa_mesh_fs_params[24].y > 0.5)\n        {\n            _3576 = (_3567.y * 0.5) + 0.5;\n        }\n        else\n        {\n            _3576 = 0.5 - (_3567.y * 0.5);\n        }\n        bool _3592 = _3572 < 0.0;\n        bool _3599;\n        if (!_3592)\n        {\n            _3599 = _3572 >= 1.0;\n        }\n        else\n        {\n            _3599 = _3592;\n        }\n        bool _3606;\n        if (!_3599)\n        {\n            _3606 = _3576 < 0.0;\n        }\n        else\n        {\n            _3606 = _3599;\n        }\n        bool _3613;\n        if (!_3606)\n        {\n            _3613 = _3576 >= 1.0;\n        }\n        else\n        {\n            _3613 = _3606;\n        }\n        if (_3613)\n        {\n            break;\n        }\n        vec4 _3632 = texelFetch(fa_screen_tex_fa_shadow_smp, ivec2(vec2(_3572, _3576) * fa_mesh_fs_params[24].zw), 0);\n        if (_3632.w < 0.5)\n        {\n            continue;\n        }\n        float _3651 = (dot(fa_mesh_fs_params[29].xyz, _3535) + fa_mesh_fs_params[29].w) - _3632.x;\n        if ((_3651 > _3498) && (_3651 < _3503))\n        {\n            occ = max(occ, (1.0 - (_3527 * _3527)) * smoothstep(0.0, 0.0500000007450580596923828125, min(min(_3572, 0.5 - _3571), min(_3576, 1.0 - _3576))));\n        }\n    }\n    return 1.0 - (occ * _3483);\n}\n\nLightSample fa_light_shadowed(int li, vec3 world_pos, vec3 gn)\n{\n    int param = li;\n    float _3754 = fa_baked_keep(param);\n    if (_3754 <= 0.0)\n    {\n        int param_1 = li;\n        return LightSample(vec3(0.0, 1.0, 0.0), vec3(0.0), 0.0, 1.0, 0.0, int(fa_light_type(param_1) + 0.5));\n    }\n    int param_2 = li;\n    vec3 param_3 = world_pos;\n    vec3 param_4 = gn;\n    LightSample _3780 = fa_light_sample_n(param_2, param_3, param_4);\n    vec3 _5525 = _3780.color;\n    float _5526 = _3780.attenuation;\n    float _5527 = _3780.shadow;\n    bool _3783 = _3780.type == 0;\n    if (_3783 && (li == 0))\n    {\n        vec3 param_5 = gn;\n        vec3 param_6 = _3780.direction;\n        float _3794 = fa_shadow_factor(param_5, param_6);\n        _5527 = _3794;\n        _5525 *= _3794;\n    }\n    else\n    {\n        bool _3805 = _3780.type != 0;\n        bool _3811;\n        if (_3805)\n        {\n            _3811 = _5526 > 0.0;\n        }\n        else\n        {\n            _3811 = _3805;\n        }\n        if (_3811)\n        {\n            int param_7 = li;\n            int param_8 = fa_light_base(param_7);\n            int param_9 = li;\n            vec3 param_10 = fa_light_texel(param_8).xyz;\n            vec3 param_11 = world_pos;\n            vec3 param_12 = gn;\n            vec3 param_13 = _3780.direction;\n            float _3830 = fa_shadow_local(param_9, param_10, param_11, param_12, param_13);\n            _5527 = _3830;\n            _5525 *= _3830;\n        }\n    }\n    bool _3840 = fa_mesh_fs_params[24].x > 0.5;\n    bool _3846;\n    if (_3840)\n    {\n        _3846 = _5526 > 0.0;\n    }\n    else\n    {\n        _3846 = _3840;\n    }\n    if (_3846)\n    {\n        float _3853;\n        if (_3783)\n        {\n            _3853 = 1000000000.0;\n        }\n        else\n        {\n            _3853 = _3780._distance;\n        }\n        int param_14 = li;\n        vec3 param_15 = world_pos;\n        vec3 param_16 = gn;\n        vec3 param_17 = _3780.direction;\n        float param_18 = _3853;\n        float _3871 = fa_contact_shadow(param_14, param_15, param_16, param_17, param_18);\n        _5527 *= _3871;\n        _5525 *= _3871;\n    }\n    float _3884 = _5526;\n    float _3885 = _3884 * _3754;\n    _5526 = _3885;\n    vec3 _3889 = _5525;\n    vec3 _3890 = _3889 * _3754;\n    _5525 = _3890;\n    return LightSample(_3780.direction, _3890, _3885, _5527, _3780._distance, _3780.type);\n}\n\nvec3 light(SurfaceInput i, Surface s, LightSample l)\n{\n    return vec3(0.0);\n}\n\nvec3 fa_shadow_debug(vec3 color, vec3 world)\n{\n    if (fa_shadows[27].w < 0.5)\n    {\n        return color;\n    }\n    int _3015 = int(fa_shadows[25].x + 0.5);\n    float _3025 = dot(world - fa_shadows[27].xyz, fa_shadows[28].xyz);\n    vec3 tint = vec3(0.3499999940395355224609375);\n    bool _3030 = _3015 > 0;\n    bool _3039;\n    if (_3030)\n    {\n        int param = _3015 - 1;\n        _3039 = _3025 <= fa_shadow_split_at(param);\n    }\n    else\n    {\n        _3039 = _3030;\n    }\n    if (_3039)\n    {\n        tint = vec3(1.0, 0.1500000059604644775390625, 0.100000001490116119384765625);\n        bool _3045 = _3015 > 1;\n        bool _3052;\n        if (_3045)\n        {\n            _3052 = _3025 > fa_shadows[24].x;\n        }\n        else\n        {\n            _3052 = _3045;\n        }\n        if (_3052)\n        {\n            tint = vec3(0.100000001490116119384765625, 0.89999997615814208984375, 0.20000000298023223876953125);\n        }\n        bool _3058 = _3015 > 2;\n        bool _3065;\n        if (_3058)\n        {\n            _3065 = _3025 > fa_shadows[24].y;\n        }\n        else\n        {\n            _3065 = _3058;\n        }\n        if (_3065)\n        {\n            tint = vec3(0.1500000059604644775390625, 0.300000011920928955078125, 1.0);\n        }\n        bool _3071 = _3015 > 3;\n        bool _3078;\n        if (_3071)\n        {\n            _3078 = _3025 > fa_shadows[24].z;\n        }\n        else\n        {\n            _3078 = _3071;\n        }\n        if (_3078)\n        {\n            tint = vec3(1.0, 0.89999997615814208984375, 0.100000001490116119384765625);\n        }\n    }\n    return mix(color, tint, vec3(0.550000011920928955078125));\n}\n\nvoid main()\n{\n    fa_inst_load();\n    vec3 _5317 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _5317 = -_5317;\n    }\n    vec3 _4892 = normalize(fa_mesh_fs_params[0].xyz - fa_world_pos);\n    vec3 param = fa_world_pos;\n    fa_cluster_begin(param);\n    SurfaceInput param_1 = SurfaceInput(fa_world_pos, _5317, fa_world_tangent, fa_uv, fa_vertex_color, _4892, gl_FrontFacing);\n    Surface _4900 = fa_standard_surface(param_1);\n    vec3 _5356 = _4900.albedo;\n    float _5357 = _4900.alpha;\n    vec3 _5358 = _4900.normal;\n    float _5359 = _4900.metallic;\n    float _5360 = _4900.roughness;\n    float _5361 = _4900.occlusion;\n    vec3 _5362 = _4900.emission;\n    float _5363 = _4900.clearcoat;\n    float _5364 = _4900.clearcoat_roughness;\n    vec3 _5365 = _4900.sheen_color;\n    float _5366 = _4900.sheen_roughness;\n    float _5367 = _4900.anisotropy;\n    float _5368 = _4900.anisotropy_rotation;\n    float _5369 = _4900.specular;\n    float _5370 = _4900.ior;\n    vec3 _5371 = _4900.specular_color;\n    float _5372 = _4900.transmission;\n    float _5373 = _4900.thickness;\n    vec3 _5374 = _4900.attenuation_color;\n    float _5375 = _4900.attenuation_distance;\n    SurfaceInput param_2 = SurfaceInput(fa_world_pos, _5317, fa_world_tangent, fa_uv, fa_vertex_color, _4892, gl_FrontFacing);\n    Surface param_3 = _4900;\n    surface(param_2, param_3);\n    _5356 = param_3.albedo;\n    _5357 = param_3.alpha;\n    _5358 = param_3.normal;\n    _5359 = param_3.metallic;\n    _5360 = param_3.roughness;\n    _5361 = param_3.occlusion;\n    _5362 = param_3.emission;\n    _5363 = param_3.clearcoat;\n    _5364 = param_3.clearcoat_roughness;\n    _5365 = param_3.sheen_color;\n    _5366 = param_3.sheen_roughness;\n    _5367 = param_3.anisotropy;\n    _5368 = param_3.anisotropy_rotation;\n    _5369 = param_3.specular;\n    _5370 = param_3.ior;\n    _5371 = param_3.specular_color;\n    _5372 = param_3.transmission;\n    _5373 = param_3.thickness;\n    _5374 = param_3.attenuation_color;\n    _5375 = param_3.attenuation_distance;\n    vec3 param_4 = fa_world_pos;\n    vec3 param_5 = _5317;\n    vec3 param_6 = param_3.albedo;\n    vec3 param_7 = param_3.normal;\n    fa_apply_decals(param_4, param_5, param_6, param_7);\n    _5356 = param_6;\n    _5358 = param_7;\n    vec3 result;\n    if (fa_mesh_fs_params[3].w > 0.5)\n    {\n        result = _5356;\n    }\n    else\n    {\n        vec3 _4939 = _5358;\n        vec3 _4940 = normalize(_4939);\n        _5358 = _4940;\n        vec3 param_8 = _4940;\n        SurfaceInput param_9 = SurfaceInput(fa_world_pos, _5317, fa_world_tangent, fa_uv, fa_vertex_color, _4892, gl_FrontFacing);\n        Surface param_10 = Surface(_5356, _5357, _5358, _5359, _5360, _5361, _5362, _5363, _5364, _5365, _5366, _5367, _5368, _5369, _5370, _5371, _5372, _5373, _5374, _5375);\n        vec3 param_11 = fa_indirect_diffuse(param_8);\n        vec3 lit = ambient(param_9, param_10, param_11);\n        int _4959 = fa_cl_ndir + fa_cl_local;\n        for (int ln = 0; ln < _4959; ln++)\n        {\n            int param_12 = ln;\n            int _4972 = fa_cl_light(param_12);\n            int param_13 = _4972;\n            if (fa_baked_keep(param_13) <= 0.0)\n            {\n                continue;\n            }\n            int param_14 = _4972;\n            vec3 param_15 = fa_world_pos;\n            vec3 param_16 = _5317;\n            LightSample _4988 = fa_light_shadowed(param_14, param_15, param_16);\n            SurfaceInput param_17 = SurfaceInput(fa_world_pos, _5317, fa_world_tangent, fa_uv, fa_vertex_color, _4892, gl_FrontFacing);\n            Surface param_18 = Surface(_5356, _5357, _5358, _5359, _5360, _5361, _5362, _5363, _5364, _5365, _5366, _5367, _5368, _5369, _5370, _5371, _5372, _5373, _5374, _5375);\n            LightSample param_19 = _4988;\n            lit += light(param_17, param_18, param_19);\n        }\n        result = lit;\n    }\n    vec3 _5003 = result;\n    vec3 _5004 = _5003 + _5362;\n    result = _5004;\n    vec3 param_20 = _5004;\n    vec3 param_21 = fa_world_pos;\n    result = fa_shadow_debug(param_20, param_21);\n    bool _5013 = fa_mesh_fs_params[7].w > 0.0;\n    bool _5020;\n    if (!_5013)\n    {\n        _5020 = fa_mesh_fs_params[8].y > 0.0;\n    }\n    else\n    {\n        _5020 = _5013;\n    }\n    if (_5020)\n    {\n        vec3 _5029 = fa_world_pos - fa_mesh_fs_params[0].xyz;\n        float _5035 = dot(_5029, fa_mesh_fs_params[9].xyz);\n        bool _5039 = fa_mesh_fs_params[9].w > 0.5;\n        float _5040;\n        if (_5039)\n        {\n            _5040 = _5035;\n        }\n        else\n        {\n            _5040 = length(_5029);\n        }\n        float _5052 = _5040 - fa_mesh_fs_params[8].x;\n        if (_5052 > 0.0)\n        {\n            float _5061 = fa_mesh_fs_params[7].w * _5052;\n            float tau = _5061 * _5061;\n            if (fa_mesh_fs_params[8].y > 0.0)\n            {\n                float _5077;\n                if (_5039)\n                {\n                    _5077 = fa_world_pos.y - (fa_mesh_fs_params[9].y * _5035);\n                }\n                else\n                {\n                    _5077 = fa_mesh_fs_params[0].y;\n                }\n                float _5098 = mix(_5077, fa_world_pos.y, clamp(fa_mesh_fs_params[8].x / _5040, 0.0, 1.0));\n                float _5102 = fa_world_pos.y - _5098;\n                float _5107 = _5098 - fa_mesh_fs_params[8].z;\n                float _5112 = fa_world_pos.y - fa_mesh_fs_params[8].z;\n                bool _5115 = _5107 <= 0.0;\n                bool _5116 = !_5115;\n                bool _5122;\n                if (_5116)\n                {\n                    _5122 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _5122 = _5115;\n                }\n                float _5123;\n                if (_5122)\n                {\n                    _5123 = fa_mesh_fs_params[8].y;\n                }\n                else\n                {\n                    _5123 = fa_mesh_fs_params[8].y * exp(-min(fa_mesh_fs_params[8].w * _5107, 80.0));\n                }\n                bool _5150;\n                if (_5116)\n                {\n                    _5150 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _5150 = _5115;\n                }\n                float _5151;\n                if (_5150)\n                {\n                    _5151 = fa_mesh_fs_params[8].y * _5107;\n                }\n                else\n                {\n                    _5151 = (fa_mesh_fs_params[8].y * (1.0 - exp(-min(fa_mesh_fs_params[8].w * _5107, 80.0)))) / fa_mesh_fs_params[8].w;\n                }\n                bool _5176 = _5112 <= 0.0;\n                bool _5183;\n                if (!_5176)\n                {\n                    _5183 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _5183 = _5176;\n                }\n                float _5184;\n                if (_5183)\n                {\n                    _5184 = fa_mesh_fs_params[8].y * _5112;\n                }\n                else\n                {\n                    _5184 = (fa_mesh_fs_params[8].y * (1.0 - exp(-min(fa_mesh_fs_params[8].w * _5112, 80.0)))) / fa_mesh_fs_params[8].w;\n                }\n                float _5211;\n                if (abs(_5102) < 0.001000000047497451305389404296875)\n                {\n                    _5211 = _5123;\n                }\n                else\n                {\n                    _5211 = (_5184 - _5151) / _5102;\n                }\n                tau += (_5052 * max(_5211, 0.0));\n            }\n            result = mix(result, fa_mesh_fs_params[7].xyz, vec3(clamp(1.0 - exp(-clamp(tau, 0.0, 80.0)), 0.0, 1.0)));\n        }\n    }\n    fa_frag_color = vec4(result, _5357);\n}\n\n",
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
            "inst_name": "_422",
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
            "name": "fa_shadow_tex_fa_shadow_smp",
            "view_name": "fa_shadow_tex",
            "sampler_name": "fa_shadow_smp",
            "view_slot": 1,
            "sampler_slot": 1,
            "glsl_name": "fa_shadow_tex_fa_shadow_smp"
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
          }
        ]
      }
    },
    "prepass": {
      "vs": "#version 430\n\nstruct VertexData\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 color;\n    vec3 object_pos;\n};\n\nuniform vec4 fa_mesh_vs_params[11];\nlayout(location = 0) out vec3 fa_world_pos;\nlayout(location = 1) out vec3 fa_world_normal;\nlayout(location = 2) out vec4 fa_world_tangent;\nlayout(location = 3) out vec2 fa_uv;\nlayout(location = 4) out vec4 fa_vertex_color;\nlayout(location = 5) out float fa_pre_depth;\nlayout(location = 6) out vec3 fa_pre_r0;\nlayout(location = 7) out vec3 fa_pre_r1;\nlayout(location = 8) out vec3 fa_pre_r2;\nlayout(location = 5) in vec4 fa_inst_m0;\nlayout(location = 6) in vec4 fa_inst_m1;\nlayout(location = 7) in vec4 fa_inst_m2;\nlayout(location = 8) in vec4 fa_inst_m3;\nlayout(location = 0) in vec3 fa_position;\nlayout(location = 1) in vec3 fa_normal;\nlayout(location = 3) in vec4 fa_tangent;\nlayout(location = 2) in vec2 fa_texcoord0;\nlayout(location = 4) in vec4 fa_color;\n\nvoid fa_inst_begin()\n{\n}\n\nVertexData fa_vertex_data(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    vec3 _69 = cross(model[1].xyz, model[2].xyz);\n    float _75 = (dot(model[0].xyz, _69) < 0.0) ? (-1.0) : 1.0;\n    return VertexData((model * vec4(position, 1.0)).xyz, (((_69 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _75, vec4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _75), texcoord0 * fa_mesh_vs_params[8].xy, color, position);\n}\n\nvoid fa_prepass_vertex(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    mat4 param = model;\n    vec3 param_1 = position;\n    vec3 param_2 = normal;\n    vec4 param_3 = tangent;\n    vec2 param_4 = texcoord0;\n    vec4 param_5 = color;\n    VertexData _160 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    vec3 _299 = _160.world_pos;\n    mat4 _164 = mat4(fa_mesh_vs_params[4], fa_mesh_vs_params[5], fa_mesh_vs_params[6], fa_mesh_vs_params[7]);\n    vec4 _171 = vec4(_299, 1.0);\n    fa_world_pos = _299;\n    fa_world_normal = _160.world_normal;\n    fa_world_tangent = _160.world_tangent;\n    fa_uv = _160.uv;\n    fa_vertex_color = _160.color;\n    fa_pre_depth = -(_164 * _171).z;\n    fa_pre_r0 = vec3(_164[0].x, _164[1].x, _164[2].x);\n    fa_pre_r1 = vec3(_164[0].y, _164[1].y, _164[2].y);\n    fa_pre_r2 = vec3(_164[0].z, _164[1].z, _164[2].z);\n    gl_Position = mat4(fa_mesh_vs_params[0], fa_mesh_vs_params[1], fa_mesh_vs_params[2], fa_mesh_vs_params[3]) * _171;\n}\n\nvoid main()\n{\n    fa_inst_begin();\n    mat4 param = mat4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3);\n    vec3 param_1 = fa_position;\n    vec3 param_2 = fa_normal;\n    vec4 param_3 = fa_tangent;\n    vec2 param_4 = fa_texcoord0;\n    vec4 param_5 = fa_color;\n    fa_prepass_vertex(param, param_1, param_2, param_3, param_4, param_5);\n}\n\n",
      "fs": "#version 430\n\nstruct SurfaceInput\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 vertex_color;\n    vec3 view_dir;\n    bool front_facing;\n};\n\nstruct Surface\n{\n    vec3 albedo;\n    float alpha;\n    vec3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    vec3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    vec3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    vec3 specular_color;\n    float transmission;\n    float thickness;\n    vec3 attenuation_color;\n    float attenuation_distance;\n};\n\nuniform vec4 fa_mesh_fs_params[53];\nlayout(binding = 0) uniform sampler2D fa_tex_fa_smp;\nlayout(binding = 1) uniform sampler2D fa_normal_tex_fa_smp;\nlayout(binding = 2) uniform sampler2D fa_mr_tex_fa_smp;\nlayout(binding = 3) uniform sampler2D fa_occlusion_tex_fa_smp;\nlayout(binding = 4) uniform sampler2D fa_emissive_tex_fa_smp;\n\nlayout(location = 0) in vec3 fa_world_pos;\nlayout(location = 1) in vec3 fa_world_normal;\nlayout(location = 2) in vec4 fa_world_tangent;\nlayout(location = 3) in vec2 fa_uv;\nlayout(location = 4) in vec4 fa_vertex_color;\nlayout(location = 6) in vec3 fa_pre_r0;\nlayout(location = 7) in vec3 fa_pre_r1;\nlayout(location = 8) in vec3 fa_pre_r2;\nlayout(location = 0) out vec4 fa_frag_color;\nlayout(location = 5) in float fa_pre_depth;\n\nvoid fa_inst_load()\n{\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nvec3 fa_linear_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_tex_fix(inout vec3 c, float mode)\n{\n    if (mode > 1.5)\n    {\n        vec3 param = c;\n        vec3 _172 = fa_linear_to_srgb(param);\n        c = _172;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            vec3 param_1 = c;\n            vec3 _181 = fa_srgb_to_linear(param_1);\n            c = _181;\n        }\n    }\n    return c;\n}\n\nvec3 fa_tangent_normal(SurfaceInput i, vec3 m)\n{\n    vec3 _56;\n    if (i.front_facing)\n    {\n        _56 = i.world_normal;\n    }\n    else\n    {\n        _56 = -i.world_normal;\n    }\n    vec3 _81 = normalize(i.world_tangent.xyz - (_56 * dot(_56, i.world_tangent.xyz)));\n    vec3 _109 = normalize(((_81 * m.x) + ((cross(_56, _81) * i.world_tangent.w) * m.y)) + (_56 * m.z));\n    vec3 _112;\n    if (i.front_facing)\n    {\n        _112 = _109;\n    }\n    else\n    {\n        _112 = -_109;\n    }\n    return _112;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    vec4 base_t = texture(fa_tex_fa_smp, i.uv);\n    float param = fa_mesh_fs_params[6].w;\n    float param_1 = 1.0;\n    vec3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    vec3 _227 = fa_tex_fix(param_2, param_3);\n    vec4 _828 = base_t;\n    _828.x = _227.x;\n    _828.y = _227.y;\n    _828.z = _227.z;\n    base_t = _828;\n    vec4 _243 = (_828 * fa_mesh_fs_params[2]) * i.vertex_color;\n    vec3 _783 = i.world_normal;\n    if (fa_mesh_fs_params[6].z > 0.5)\n    {\n        float param_4 = fa_mesh_fs_params[6].w;\n        float param_5 = 16.0;\n        vec3 param_6 = texture(fa_normal_tex_fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        vec3 _277 = fa_tex_fix(param_6, param_7);\n        vec3 _281 = (_277 * 2.0) - vec3(1.0);\n        vec2 _286 = _281.xy * fa_mesh_fs_params[6].x;\n        vec3 _836 = _281;\n        _836.x = _286.x;\n        _836.y = _286.y;\n        SurfaceInput param_8 = i;\n        vec3 param_9 = _836;\n        _783 = fa_tangent_normal(param_8, param_9);\n    }\n    vec4 mrt = texture(fa_mr_tex_fa_smp, i.uv);\n    float param_10 = fa_mesh_fs_params[6].w;\n    float param_11 = 64.0;\n    vec3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    vec3 _315 = fa_tex_fix(param_12, param_13);\n    vec4 _839 = mrt;\n    _839.x = _315.x;\n    _839.y = _315.y;\n    _839.z = _315.z;\n    mrt = _839;\n    vec4 _345 = texture(fa_occlusion_tex_fa_smp, i.uv);\n    float param_14 = fa_mesh_fs_params[6].w;\n    float param_15 = 256.0;\n    vec3 param_16 = _345.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    vec3 _357 = fa_tex_fix(param_16, param_17);\n    float param_18 = fa_mesh_fs_params[6].w;\n    float param_19 = 4.0;\n    vec3 param_20 = texture(fa_emissive_tex_fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    vec3 _387 = fa_tex_fix(param_20, param_21);\n    float _788 = fa_mesh_fs_params[20].x;\n    float _789 = fa_mesh_fs_params[20].y;\n    float _792 = fa_mesh_fs_params[20].z;\n    float _791 = fa_mesh_fs_params[21].w;\n    float _794 = fa_mesh_fs_params[22].x;\n    if (fa_mesh_fs_params[22].z > 0.5)\n    {\n        if (mod(fa_mesh_fs_params[22].z, 2.0) > 0.5)\n        {\n            _788 *= _357.y;\n            _789 *= _357.z;\n            _791 *= _345.w;\n        }\n        if (fa_mesh_fs_params[22].z > 1.5)\n        {\n            _792 *= mrt.x;\n            _794 *= mrt.w;\n        }\n    }\n    return Surface(_243.xyz, _243.w, _783, clamp(fa_mesh_fs_params[5].x * _315.z, 0.0, 1.0), clamp(fa_mesh_fs_params[5].y * _315.y, 0.0500000007450580596923828125, 1.0), 1.0 + (fa_mesh_fs_params[6].y * (_357.x - 1.0)), fa_mesh_fs_params[3].xyz + (fa_mesh_fs_params[4].xyz * _387), _788, _789, fa_mesh_fs_params[21].xyz, _791, _792, fa_mesh_fs_params[20].w, _794, fa_mesh_fs_params[22].y, fa_mesh_fs_params[23].xyz, fa_mesh_fs_params[30].x, fa_mesh_fs_params[30].y, fa_mesh_fs_params[31].xyz, fa_mesh_fs_params[30].z);\n}\n\nvoid surface(SurfaceInput i, Surface s)\n{\n}\n\nvoid main()\n{\n    fa_inst_load();\n    vec3 _678 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _678 = -_678;\n    }\n    vec3 _540 = normalize(fa_mesh_fs_params[0].xyz - fa_world_pos);\n    SurfaceInput param = SurfaceInput(fa_world_pos, _678, fa_world_tangent, fa_uv, fa_vertex_color, _540, gl_FrontFacing);\n    SurfaceInput param_1 = SurfaceInput(fa_world_pos, _678, fa_world_tangent, fa_uv, fa_vertex_color, _540, gl_FrontFacing);\n    Surface param_2 = fa_standard_surface(param);\n    surface(param_1, param_2);\n    vec3 _555 = normalize(param_2.normal);\n    vec3 _570 = normalize(vec3(dot(fa_pre_r0, _555), dot(fa_pre_r1, _555), dot(fa_pre_r2, _555)));\n    float _582 = _570.z;\n    vec2 e = _570.xy / vec2((abs(_570.x) + abs(_570.y)) + abs(_582));\n    if (_582 < 0.0)\n    {\n        e = (vec2(1.0) - abs(e.yx)) * vec2((e.x >= 0.0) ? 1.0 : (-1.0), (e.y >= 0.0) ? 1.0 : (-1.0));\n    }\n    fa_frag_color = vec4(min(fa_pre_depth, 60000.0), e, 1.0);\n}\n\n",
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
      "vs": "#version 430\n\nstruct VertexData\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 color;\n    vec3 object_pos;\n};\n\nuniform vec4 fa_mesh_vs_params[11];\nuniform vec4 fa_skin[192];\nlayout(location = 0) out vec3 fa_world_pos;\nlayout(location = 1) out vec3 fa_world_normal;\nlayout(location = 2) out vec4 fa_world_tangent;\nlayout(location = 3) out vec2 fa_uv;\nlayout(location = 4) out vec4 fa_vertex_color;\nlayout(location = 5) out float fa_pre_depth;\nlayout(location = 6) out vec3 fa_pre_r0;\nlayout(location = 7) out vec3 fa_pre_r1;\nlayout(location = 8) out vec3 fa_pre_r2;\nlayout(location = 5) in vec4 fa_inst_m0;\nlayout(location = 6) in vec4 fa_inst_m1;\nlayout(location = 7) in vec4 fa_inst_m2;\nlayout(location = 8) in vec4 fa_inst_m3;\nlayout(location = 9) in vec4 fa_joints;\nlayout(location = 10) in vec4 fa_weights;\nlayout(location = 0) in vec3 fa_position;\nlayout(location = 1) in vec3 fa_normal;\nlayout(location = 3) in vec4 fa_tangent;\nlayout(location = 2) in vec2 fa_texcoord0;\nlayout(location = 4) in vec4 fa_color;\n\nvoid fa_inst_begin()\n{\n}\n\nmat4 fa_skin_matrix(vec4 joints, vec4 weights)\n{\n    vec4 r0 = vec4(0.0);\n    vec4 r1 = vec4(0.0);\n    vec4 r2 = vec4(0.0);\n    for (int i = 0; i < 4; i++)\n    {\n        int _174 = int((joints[i] * 255.0) + 0.5) * 3;\n        r0 += (fa_skin[_174 * 1 + 0] * weights[i]);\n        r1 += (fa_skin[(_174 + 1) * 1 + 0] * weights[i]);\n        r2 += (fa_skin[(_174 + 2) * 1 + 0] * weights[i]);\n    }\n    return mat4(vec4(r0.x, r1.x, r2.x, 0.0), vec4(r0.y, r1.y, r2.y, 0.0), vec4(r0.z, r1.z, r2.z, 0.0), vec4(r0.w, r1.w, r2.w, 1.0));\n}\n\nVertexData fa_vertex_data(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    vec3 _74 = cross(model[1].xyz, model[2].xyz);\n    float _80 = (dot(model[0].xyz, _74) < 0.0) ? (-1.0) : 1.0;\n    return VertexData((model * vec4(position, 1.0)).xyz, (((_74 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _80, vec4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _80), texcoord0 * fa_mesh_vs_params[8].xy, color, position);\n}\n\nvoid fa_prepass_vertex(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    mat4 param = model;\n    vec3 param_1 = position;\n    vec3 param_2 = normal;\n    vec4 param_3 = tangent;\n    vec2 param_4 = texcoord0;\n    vec4 param_5 = color;\n    VertexData _273 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    vec3 _420 = _273.world_pos;\n    mat4 _277 = mat4(fa_mesh_vs_params[4], fa_mesh_vs_params[5], fa_mesh_vs_params[6], fa_mesh_vs_params[7]);\n    vec4 _284 = vec4(_420, 1.0);\n    fa_world_pos = _420;\n    fa_world_normal = _273.world_normal;\n    fa_world_tangent = _273.world_tangent;\n    fa_uv = _273.uv;\n    fa_vertex_color = _273.color;\n    fa_pre_depth = -(_277 * _284).z;\n    fa_pre_r0 = vec3(_277[0].x, _277[1].x, _277[2].x);\n    fa_pre_r1 = vec3(_277[0].y, _277[1].y, _277[2].y);\n    fa_pre_r2 = vec3(_277[0].z, _277[1].z, _277[2].z);\n    gl_Position = mat4(fa_mesh_vs_params[0], fa_mesh_vs_params[1], fa_mesh_vs_params[2], fa_mesh_vs_params[3]) * _284;\n}\n\nvoid main()\n{\n    fa_inst_begin();\n    vec4 param = fa_joints;\n    vec4 param_1 = fa_weights;\n    mat4 param_2 = mat4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3) * fa_skin_matrix(param, param_1);\n    vec3 param_3 = fa_position;\n    vec3 param_4 = fa_normal;\n    vec4 param_5 = fa_tangent;\n    vec2 param_6 = fa_texcoord0;\n    vec4 param_7 = fa_color;\n    fa_prepass_vertex(param_2, param_3, param_4, param_5, param_6, param_7);\n}\n\n",
      "fs": "#version 430\n\nstruct SurfaceInput\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 vertex_color;\n    vec3 view_dir;\n    bool front_facing;\n};\n\nstruct Surface\n{\n    vec3 albedo;\n    float alpha;\n    vec3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    vec3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    vec3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    vec3 specular_color;\n    float transmission;\n    float thickness;\n    vec3 attenuation_color;\n    float attenuation_distance;\n};\n\nuniform vec4 fa_mesh_fs_params[53];\nlayout(binding = 0) uniform sampler2D fa_tex_fa_smp;\nlayout(binding = 1) uniform sampler2D fa_normal_tex_fa_smp;\nlayout(binding = 2) uniform sampler2D fa_mr_tex_fa_smp;\nlayout(binding = 3) uniform sampler2D fa_occlusion_tex_fa_smp;\nlayout(binding = 4) uniform sampler2D fa_emissive_tex_fa_smp;\n\nlayout(location = 0) in vec3 fa_world_pos;\nlayout(location = 1) in vec3 fa_world_normal;\nlayout(location = 2) in vec4 fa_world_tangent;\nlayout(location = 3) in vec2 fa_uv;\nlayout(location = 4) in vec4 fa_vertex_color;\nlayout(location = 6) in vec3 fa_pre_r0;\nlayout(location = 7) in vec3 fa_pre_r1;\nlayout(location = 8) in vec3 fa_pre_r2;\nlayout(location = 0) out vec4 fa_frag_color;\nlayout(location = 5) in float fa_pre_depth;\n\nvoid fa_inst_load()\n{\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nvec3 fa_linear_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_tex_fix(inout vec3 c, float mode)\n{\n    if (mode > 1.5)\n    {\n        vec3 param = c;\n        vec3 _172 = fa_linear_to_srgb(param);\n        c = _172;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            vec3 param_1 = c;\n            vec3 _181 = fa_srgb_to_linear(param_1);\n            c = _181;\n        }\n    }\n    return c;\n}\n\nvec3 fa_tangent_normal(SurfaceInput i, vec3 m)\n{\n    vec3 _56;\n    if (i.front_facing)\n    {\n        _56 = i.world_normal;\n    }\n    else\n    {\n        _56 = -i.world_normal;\n    }\n    vec3 _81 = normalize(i.world_tangent.xyz - (_56 * dot(_56, i.world_tangent.xyz)));\n    vec3 _109 = normalize(((_81 * m.x) + ((cross(_56, _81) * i.world_tangent.w) * m.y)) + (_56 * m.z));\n    vec3 _112;\n    if (i.front_facing)\n    {\n        _112 = _109;\n    }\n    else\n    {\n        _112 = -_109;\n    }\n    return _112;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    vec4 base_t = texture(fa_tex_fa_smp, i.uv);\n    float param = fa_mesh_fs_params[6].w;\n    float param_1 = 1.0;\n    vec3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    vec3 _227 = fa_tex_fix(param_2, param_3);\n    vec4 _828 = base_t;\n    _828.x = _227.x;\n    _828.y = _227.y;\n    _828.z = _227.z;\n    base_t = _828;\n    vec4 _243 = (_828 * fa_mesh_fs_params[2]) * i.vertex_color;\n    vec3 _783 = i.world_normal;\n    if (fa_mesh_fs_params[6].z > 0.5)\n    {\n        float param_4 = fa_mesh_fs_params[6].w;\n        float param_5 = 16.0;\n        vec3 param_6 = texture(fa_normal_tex_fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        vec3 _277 = fa_tex_fix(param_6, param_7);\n        vec3 _281 = (_277 * 2.0) - vec3(1.0);\n        vec2 _286 = _281.xy * fa_mesh_fs_params[6].x;\n        vec3 _836 = _281;\n        _836.x = _286.x;\n        _836.y = _286.y;\n        SurfaceInput param_8 = i;\n        vec3 param_9 = _836;\n        _783 = fa_tangent_normal(param_8, param_9);\n    }\n    vec4 mrt = texture(fa_mr_tex_fa_smp, i.uv);\n    float param_10 = fa_mesh_fs_params[6].w;\n    float param_11 = 64.0;\n    vec3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    vec3 _315 = fa_tex_fix(param_12, param_13);\n    vec4 _839 = mrt;\n    _839.x = _315.x;\n    _839.y = _315.y;\n    _839.z = _315.z;\n    mrt = _839;\n    vec4 _345 = texture(fa_occlusion_tex_fa_smp, i.uv);\n    float param_14 = fa_mesh_fs_params[6].w;\n    float param_15 = 256.0;\n    vec3 param_16 = _345.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    vec3 _357 = fa_tex_fix(param_16, param_17);\n    float param_18 = fa_mesh_fs_params[6].w;\n    float param_19 = 4.0;\n    vec3 param_20 = texture(fa_emissive_tex_fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    vec3 _387 = fa_tex_fix(param_20, param_21);\n    float _788 = fa_mesh_fs_params[20].x;\n    float _789 = fa_mesh_fs_params[20].y;\n    float _792 = fa_mesh_fs_params[20].z;\n    float _791 = fa_mesh_fs_params[21].w;\n    float _794 = fa_mesh_fs_params[22].x;\n    if (fa_mesh_fs_params[22].z > 0.5)\n    {\n        if (mod(fa_mesh_fs_params[22].z, 2.0) > 0.5)\n        {\n            _788 *= _357.y;\n            _789 *= _357.z;\n            _791 *= _345.w;\n        }\n        if (fa_mesh_fs_params[22].z > 1.5)\n        {\n            _792 *= mrt.x;\n            _794 *= mrt.w;\n        }\n    }\n    return Surface(_243.xyz, _243.w, _783, clamp(fa_mesh_fs_params[5].x * _315.z, 0.0, 1.0), clamp(fa_mesh_fs_params[5].y * _315.y, 0.0500000007450580596923828125, 1.0), 1.0 + (fa_mesh_fs_params[6].y * (_357.x - 1.0)), fa_mesh_fs_params[3].xyz + (fa_mesh_fs_params[4].xyz * _387), _788, _789, fa_mesh_fs_params[21].xyz, _791, _792, fa_mesh_fs_params[20].w, _794, fa_mesh_fs_params[22].y, fa_mesh_fs_params[23].xyz, fa_mesh_fs_params[30].x, fa_mesh_fs_params[30].y, fa_mesh_fs_params[31].xyz, fa_mesh_fs_params[30].z);\n}\n\nvoid surface(SurfaceInput i, Surface s)\n{\n}\n\nvoid main()\n{\n    fa_inst_load();\n    vec3 _678 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _678 = -_678;\n    }\n    vec3 _540 = normalize(fa_mesh_fs_params[0].xyz - fa_world_pos);\n    SurfaceInput param = SurfaceInput(fa_world_pos, _678, fa_world_tangent, fa_uv, fa_vertex_color, _540, gl_FrontFacing);\n    SurfaceInput param_1 = SurfaceInput(fa_world_pos, _678, fa_world_tangent, fa_uv, fa_vertex_color, _540, gl_FrontFacing);\n    Surface param_2 = fa_standard_surface(param);\n    surface(param_1, param_2);\n    vec3 _555 = normalize(param_2.normal);\n    vec3 _570 = normalize(vec3(dot(fa_pre_r0, _555), dot(fa_pre_r1, _555), dot(fa_pre_r2, _555)));\n    float _582 = _570.z;\n    vec2 e = _570.xy / vec2((abs(_570.x) + abs(_570.y)) + abs(_582));\n    if (_582 < 0.0)\n    {\n        e = (vec2(1.0) - abs(e.yx)) * vec2((e.x >= 0.0) ? 1.0 : (-1.0), (e.y >= 0.0) ? 1.0 : (-1.0));\n    }\n    fa_frag_color = vec4(min(fa_pre_depth, 60000.0), e, 1.0);\n}\n\n",
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
